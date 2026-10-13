#include "ImgBorder.hpp"
#include "ImgBorderPassElement.hpp"
#include "ImgUtils.hpp"
#include "globals.hpp"
#include <algorithm>
#include <filesystem>
#include <random>
#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/SharedDefs.hpp>
#include <hyprland/src/debug/log/Logger.hpp>
#include <hyprland/src/desktop/DesktopTypes.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/helpers/MiscFunctions.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/Texture.hpp>
#include <hyprland/src/render/decorations/DecorationPositioner.hpp>
#include <hyprutils/math/Box.hpp>
#include <hyprutils/math/Vector2D.hpp>
#include <wordexp.h>

using namespace GL;

CImgBorder::CImgBorder(PHLWINDOW pWindow) : IHyprWindowDecoration(pWindow) {
  m_pWindow = pWindow;
  std::random_device rd;
  m_windowSeed = ((uint64_t)rd() << 32) | rd();
  updateConfig();
}

CImgBorder::~CImgBorder() { std::erase(g_pGlobalState->borders, m_self); }

SDecorationPositioningInfo CImgBorder::getPositioningInfo() {
  SDecorationPositioningInfo info;
  info.policy = DECORATION_POSITION_STICKY;
  info.edges = DECORATION_EDGE_LEFT | DECORATION_EDGE_RIGHT |
               DECORATION_EDGE_TOP | DECORATION_EDGE_BOTTOM;
  info.priority = 4999; // Must be lower than hyprbars
  if (m_isEnabled && !m_isHidden) {
    info.desiredExtents = {
        .topLeft = {(m_sizes[0] - m_insets[0]) * m_scale,
                    (m_sizes[2] - m_insets[2]) * m_scale},
        .bottomRight = {(m_sizes[1] - m_insets[1]) * m_scale,
                        (m_sizes[3] - m_insets[3]) * m_scale},
    };
  }
  info.reserved = true;
  return info;
}

void CImgBorder::onPositioningReply(const SDecorationPositioningReply &reply) {
  m_assignedBox = reply.assignedGeometry;
}

void CImgBorder::draw(PHLMONITOR pMonitor, const float &a) {
  if (!m_isEnabled || m_isHidden || //
      !validMapped(m_pWindow) ||    //
      !m_pWindow->m_ruleApplicator->decorate().valueOrDefault())
    return;

  CImgBorderPassElement::SData data = {.deco = this, .a = a};
  g_pHyprRenderer->m_renderPass.add(makeUnique<CImgBorderPassElement>(data));
}

eDecorationType CImgBorder::getDecorationType() { return DECORATION_CUSTOM; }

void CImgBorder::updateWindow(PHLWINDOW pWindow) { damageEntire(); }

void CImgBorder::damageEntire() { g_pHyprRenderer->damageBox(getDamageBox()); }

eDecorationLayer CImgBorder::getDecorationLayer() {
  return DECORATION_LAYER_OVER;
}

uint64_t CImgBorder::getDecorationFlags() {
  return DECORATION_PART_OF_MAIN_WINDOW;
}

std::string CImgBorder::getDisplayName() { return DISPLAY_NAME; }

PHLWINDOWREF CImgBorder::getWindow() { return m_pWindow; }

bool CImgBorder::shouldBlur() { return m_shouldBlur; }

CBox CImgBorder::getGlobalBoundingBox() {
  const auto PWINDOW = m_pWindow.lock();

  CBox box = m_assignedBox;
  box.translate(g_pDecorationPositioner->getEdgeDefinedPoint(
      DECORATION_EDGE_TOP | DECORATION_EDGE_LEFT, PWINDOW));

  const auto PWORKSPACE = PWINDOW->m_workspace;
  const auto WORKSPACEOFFSET = PWORKSPACE && !PWINDOW->m_pinned
                                   ? PWORKSPACE->m_renderOffset->value()
                                   : Vector2D();

  return box.translate(WORKSPACEOFFSET);
}

CBox CImgBorder::getDamageBox() {
  const auto box = getGlobalBoundingBox();
  if (!m_wallBox)
    return box;
  const auto &wall = *m_wallBox;
  const double x0 = std::min(box.x, wall.x);
  const double y0 = std::min(box.y, wall.y);
  const double x1 = std::max(box.x + box.width, wall.x + wall.width);
  const double y1 = std::max(box.y + box.height, wall.y + wall.height);
  return {x0, y0, x1 - x0, y1 - y0};
}

bool CImgBorder::participatesInWall() {
  if (!m_isProcedural || !m_isEnabled || m_isHidden ||
      !g_pGlobalState->config.merge->value() ||
      g_pGlobalState->config.mergeDistance->value() <= 0 ||
      !validMapped(m_pWindow))
    return false;
  const auto PWINDOW = m_pWindow.lock();
  return !PWINDOW->isHidden() && !PWINDOW->m_isFloating &&
         PWINDOW->m_workspace &&
         PWINDOW->m_ruleApplicator->decorate().valueOrDefault() &&
         !Fullscreen::controller()->isFullscreen(PWINDOW);
}

CBox CImgBorder::goalFrame() {
  const auto content = m_pWindow.lock()->geometricBox(
      Desktop::View::IGeometric::GEOMETRIC_GOAL);
  const double left = (m_sizes[0] - m_insets[0]) * m_scale;
  const double right = (m_sizes[1] - m_insets[1]) * m_scale;
  const double top = (m_sizes[2] - m_insets[2]) * m_scale;
  const double bottom = (m_sizes[3] - m_insets[3]) * m_scale;
  return {content.x - left, content.y - top, content.width + left + right,
          content.height + top + bottom};
}

uint64_t CImgBorder::stoneSeed() { return m_stoneParams.seed; }

bool CImgBorder::drawWall(const CBox &box, const float &a) {
  const auto PWORKSPACE = m_pWindow.lock()->m_workspace;
  const double cell = m_scale;
  const double mergeDistance = g_pGlobalState->config.mergeDistance->value();
  const auto goal = goalFrame();
  if (goal.width <= 0 || goal.height <= 0 || cell <= 0)
    return false;

  std::vector<WallField::SWindow> windows;
  std::vector<CImgBorder *> members;
  uint64_t key = StoneGen::mix(g_pGlobalState->configGeneration,
                               (uint64_t)PWORKSPACE->m_id);
  for (const auto &wb : g_pGlobalState->borders) {
    auto *b = wb.get();
    if (b == nullptr || !b->participatesInWall())
      continue;
    const auto window = b->getWindow().lock();
    if (window->m_workspace != PWORKSPACE)
      continue;
    const auto frame = b->goalFrame();
    const auto content =
        window->geometricBox(Desktop::View::IGeometric::GEOMETRIC_GOAL);
    windows.push_back({b->stoneSeed(),
                       {frame.x, frame.y, frame.width, frame.height},
                       {content.x, content.y, content.width, content.height}});
    members.push_back(b);
    key = StoneGen::mix(key, b->stoneSeed());
    for (const double v : {frame.x, frame.y, frame.width, frame.height,
                           content.x, content.y, content.width, content.height})
      key = StoneGen::mix(key, (uint64_t)std::llround(v * 8));
  }
  if (windows.empty())
    return false;

  auto &cache = g_pGlobalState->walls[PWORKSPACE->m_id];
  if (cache.version == 0 || cache.key != key) {
    cache.field = WallField::build(windows, m_stoneParams, cell, mergeDistance);
    cache.key = key;
    cache.version++;
    for (auto *b : members)
      if (b != this)
        b->damageEntire();
  }

  const double reach = mergeDistance / 2.0 + cell;
  const int crop[4] = {
      (int)std::floor((goal.x - reach) / cell),
      (int)std::floor((goal.y - reach) / cell),
      (int)std::ceil((goal.x + goal.width + reach) / cell),
      (int)std::ceil((goal.y + goal.height + reach) / cell),
  };
  if (m_tex_wall == nullptr || m_wallVersion != cache.version ||
      !std::equal(std::begin(crop), std::end(crop), std::begin(m_wallCrop))) {
    const auto img = WallField::crop(cache.field, crop[0], crop[1],
                                     crop[2] - crop[0], crop[3] - crop[1]);
    m_tex_wall = ImgUtils::fromRGBA(img.rgba.data(), img.w, img.h);
    m_wallVersion = cache.version;
    std::copy(std::begin(crop), std::end(crop), std::begin(m_wallCrop));
  }

  const auto mapTo = [&](const CBox &frame) {
    const double sx = frame.width / goal.width;
    const double sy = frame.height / goal.height;
    return CBox{frame.x + (crop[0] * cell - goal.x) * sx,
                frame.y + (crop[1] * cell - goal.y) * sy,
                (crop[2] - crop[0]) * cell * sx,
                (crop[3] - crop[1]) * cell * sy};
  };
  const auto drawBox = mapTo(box);
  m_wallBox = mapTo(getGlobalBoundingBox());

  const auto wasUsingNearestNeighbour =
      g_pHyprRenderer->m_renderData.useNearestNeighbor;
  g_pHyprRenderer->m_renderData.useNearestNeighbor = !m_shouldSmooth;
  g_pHyprRenderer->draw({.tex = m_tex_wall,
                         .box = drawBox,
                         .a = a,
                         .damage = drawBox,
                         .blur = shouldBlur(),
                         .discardMode = DISCARD_ALPHA});
  g_pHyprRenderer->m_renderData.useNearestNeighbor = wasUsingNearestNeighbour;
  return true;
}

void CImgBorder::drawPass(PHLMONITOR pMonitor, const float &a) {
  auto box = getGlobalBoundingBox()
                 .translate(m_pWindow->m_floatingOffset - pMonitor->m_position)
                 .scale(pMonitor->m_scale);

  // For debugging
  // g_pHyprOpenGL->renderRect(box, CHyprColor{1.0, 0.0, 0.0, 0.5});
  // return;

  // Render the textures
  // ------------

  const auto scale = m_scale * pMonitor->m_scale;

  if (m_isProcedural) {
    drawProcedural(box, scale, a);
    return;
  }

  const auto BORDER_LEFT = (float)m_sizes[0] * scale;
  const auto BORDER_RIGHT = (float)m_sizes[1] * scale;
  const auto BORDER_TOP = (float)m_sizes[2] * scale;
  const auto BORDER_BOTTOM = (float)m_sizes[3] * scale;

  const auto HEIGHT_MID = box.height - BORDER_TOP - BORDER_BOTTOM;
  const auto WIDTH_MID = box.width - BORDER_LEFT - BORDER_RIGHT;

  // Save previous values

  const auto wasUsingNearestNeighbour =
      g_pHyprRenderer->m_renderData.useNearestNeighbor;
  const auto prevUVTL = g_pHyprRenderer->m_renderData.primarySurfaceUVTopLeft;
  const auto prevUVBR =
      g_pHyprRenderer->m_renderData.primarySurfaceUVBottomRight;

  g_pHyprRenderer->m_renderData.useNearestNeighbor = !m_shouldSmooth;

  // Corners

  if (m_tex_tl != nullptr) {
    const CBox box_tl = {box.pos(), {BORDER_LEFT, BORDER_TOP}};
    g_pHyprRenderer->draw({.tex = m_tex_tl,
                           .box = box_tl,
                           .a = a,
                           .damage = box_tl,
                           .blur = shouldBlur(),
                           .discardMode = DISCARD_ALPHA});
  }

  if (m_tex_tr != nullptr) {
    const CBox box_tr = {{box.x + box.width - BORDER_RIGHT, box.y},
                         {BORDER_RIGHT, BORDER_TOP}};
    g_pHyprRenderer->draw({.tex = m_tex_tr,
                           .box = box_tr,
                           .a = a,
                           .damage = box_tr,
                           .blur = shouldBlur(),
                           .discardMode = DISCARD_ALPHA});
  }

  if (m_tex_br != nullptr) {
    const CBox box_br = {
        {box.x + box.width - BORDER_RIGHT, box.y + box.height - BORDER_BOTTOM},
        {BORDER_RIGHT, BORDER_BOTTOM}};
    g_pHyprRenderer->draw({.tex = m_tex_br,
                           .box = box_br,
                           .a = a,
                           .damage = box_br,
                           .blur = shouldBlur(),
                           .discardMode = DISCARD_ALPHA});
  }

  if (m_tex_bl != nullptr) {
    const CBox box_bl = {{box.x, box.y + box.height - BORDER_BOTTOM},
                         {BORDER_LEFT, BORDER_BOTTOM}};
    g_pHyprRenderer->draw({.tex = m_tex_bl,
                           .box = box_bl,
                           .a = a,
                           .damage = box_bl,
                           .blur = shouldBlur(),
                           .discardMode = DISCARD_ALPHA});
  }

  // Edges

  g_pHyprRenderer->m_renderData.primarySurfaceUVTopLeft = {0, 0};

  g_pHyprRenderer->m_renderData.primarySurfaceUVBottomRight = {1., 1.};
  if (m_tex_t != nullptr && m_tex_t->m_size.x != 0 && scale != 0) {
    g_pHyprRenderer->m_renderData.primarySurfaceUVBottomRight.x =
        WIDTH_MID / (m_tex_t->m_size.x * scale);
  }

  if (m_tex_t != nullptr) {
    const CBox box_t = {{box.x + BORDER_LEFT, box.y}, {WIDTH_MID, BORDER_TOP}};
    g_pHyprRenderer->draw({.tex = m_tex_t,
                           .box = box_t,
                           .a = a,
                           .damage = box_t,
                           .blur = shouldBlur(),
                           .allowCustomUV = true,
                           .wrapX = WRAP_REPEAT,
                           .wrapY = WRAP_REPEAT,
                           .discardMode = DISCARD_ALPHA});
  }

  if (m_tex_b != nullptr) {
    const CBox box_b = {
        {box.x + BORDER_LEFT, box.y + box.height - BORDER_BOTTOM},
        {WIDTH_MID, BORDER_BOTTOM}};
    g_pHyprRenderer->draw({.tex = m_tex_b,
                           .box = box_b,
                           .a = a,
                           .damage = box_b,
                           .blur = shouldBlur(),
                           .allowCustomUV = true,
                           .wrapX = WRAP_REPEAT,
                           .wrapY = WRAP_REPEAT,
                           .discardMode = DISCARD_ALPHA});
  }

  g_pHyprRenderer->m_renderData.primarySurfaceUVBottomRight = {1., 1.};
  if (m_tex_l != nullptr && m_tex_l->m_size.y != 0 && scale != 0) {
    g_pHyprRenderer->m_renderData.primarySurfaceUVBottomRight.y =
        HEIGHT_MID / (m_tex_l->m_size.y * scale);
  }

  if (m_tex_l != nullptr) {
    const CBox box_l = {{box.x, box.y + BORDER_TOP}, {BORDER_LEFT, HEIGHT_MID}};
    g_pHyprRenderer->draw({.tex = m_tex_l,
                           .box = box_l,
                           .a = a,
                           .damage = box_l,
                           .blur = shouldBlur(),
                           .allowCustomUV = true,
                           .wrapX = WRAP_REPEAT,
                           .wrapY = WRAP_REPEAT,
                           .discardMode = DISCARD_ALPHA});
  }

  if (m_tex_r != nullptr) {
    const CBox box_r = {{box.x + box.width - BORDER_RIGHT, box.y + BORDER_TOP},
                        {BORDER_RIGHT, HEIGHT_MID}};
    g_pHyprRenderer->draw({.tex = m_tex_r,
                           .box = box_r,
                           .a = a,
                           .damage = box_r,
                           .blur = shouldBlur(),
                           .allowCustomUV = true,
                           .wrapX = WRAP_REPEAT,
                           .wrapY = WRAP_REPEAT,
                           .discardMode = DISCARD_ALPHA});
  }

  // Restore previous values

  g_pHyprRenderer->m_renderData.useNearestNeighbor = wasUsingNearestNeighbour;

  g_pHyprRenderer->m_renderData.primarySurfaceUVTopLeft = prevUVTL;
  g_pHyprRenderer->m_renderData.primarySurfaceUVBottomRight = prevUVBR;
}

void CImgBorder::drawProcedural(const CBox &box, float scale,
                                const float &a) {
  if (participatesInWall() && drawWall(box, a))
    return;
  m_wallBox.reset();

  const int b = m_stoneParams.thickness;
  const int w = std::max(2 * b + 1, (int)std::lround(box.width / scale));
  const int h = std::max(2 * b + 1, (int)std::lround(box.height / scale));

  if (w != m_genWidth || h != m_genHeight) {
    m_genWidth = w;
    m_genHeight = h;
    const auto gen = [&](StoneGen::eEdge edge) -> SP<ITexture> {
      const auto img = StoneGen::renderEdge(m_stoneParams, edge, w, h);
      if (img.w <= 0 || img.h <= 0)
        return nullptr;
      return ImgUtils::fromRGBA(img.rgba.data(), img.w, img.h);
    };
    m_tex_t = gen(StoneGen::EDGE_TOP);
    m_tex_r = gen(StoneGen::EDGE_RIGHT);
    m_tex_b = gen(StoneGen::EDGE_BOTTOM);
    m_tex_l = gen(StoneGen::EDGE_LEFT);
  }

  const double bs = b * scale;
  const std::pair<SP<ITexture>, CBox> edges[] = {
      {m_tex_t, {box.x, box.y, box.width, bs}},
      {m_tex_r, {box.x + box.width - bs, box.y + bs, bs, box.height - 2 * bs}},
      {m_tex_b, {box.x, box.y + box.height - bs, box.width, bs}},
      {m_tex_l, {box.x, box.y + bs, bs, box.height - 2 * bs}},
  };

  const auto wasUsingNearestNeighbour =
      g_pHyprRenderer->m_renderData.useNearestNeighbor;
  g_pHyprRenderer->m_renderData.useNearestNeighbor = !m_shouldSmooth;

  for (const auto &[tex, edgeBox] : edges) {
    if (tex == nullptr || edgeBox.width <= 0 || edgeBox.height <= 0)
      continue;
    g_pHyprRenderer->draw({.tex = tex,
                           .box = edgeBox,
                           .a = a,
                           .damage = edgeBox,
                           .blur = shouldBlur(),
                           .discardMode = DISCARD_ALPHA});
  }

  g_pHyprRenderer->m_renderData.useNearestNeighbor = wasUsingNearestNeighbour;
}

void CImgBorder::updateConfig() {
  // Read config
  // ------------

  m_isEnabled = true;

  // sizes
  const auto sizes = g_pGlobalState->config.sizes->value();
  if (sizes.m_top < 0 || sizes.m_right < 0 || sizes.m_bottom < 0 ||
      sizes.m_left < 0) {
    HyprlandAPI::addNotification(PHANDLE,
                                 "[imgborders] invalid sizes in config",
                                 CHyprColor{1.0, 0.1, 0.1, 1.0}, 5000);
    m_isEnabled = false;
    return;
  }
  m_sizes[0] = sizes.m_left;
  m_sizes[1] = sizes.m_right;
  m_sizes[2] = sizes.m_top;
  m_sizes[3] = sizes.m_bottom;

  // insets
  const auto insets = g_pGlobalState->config.insets->value();
  m_insets[0] = insets.m_left;
  m_insets[1] = insets.m_right;
  m_insets[2] = insets.m_top;
  m_insets[3] = insets.m_bottom;

  // scale
  m_scale = g_pGlobalState->config.scale->value();

  // smooth
  m_shouldSmooth = g_pGlobalState->config.smooth->value();

  // blur
  m_shouldBlur = g_pGlobalState->config.blur->value();

  // Delete old textures
  m_tex_tl = nullptr;
  m_tex_tr = nullptr;
  m_tex_br = nullptr;
  m_tex_bl = nullptr;
  m_tex_l = nullptr;
  m_tex_t = nullptr;
  m_tex_b = nullptr;
  m_tex_r = nullptr;

  m_isProcedural = g_pGlobalState->config.mode->value() == "procedural";
  if (m_isProcedural) {
    auto &sp = m_stoneParams;
    sp.seed = StoneGen::mix(
        (uint64_t)g_pGlobalState->config.seed->value(), m_windowSeed);
    sp.thickness = std::max(5, m_sizes[2]);
    sp.roughness = g_pGlobalState->config.roughness->value();
    sp.chipping = g_pGlobalState->config.chipping->value();
    sp.moss = g_pGlobalState->config.moss->value();
    sp.stoneBlend = g_pGlobalState->config.stoneBlend->value();
    sp.highlightBlend = g_pGlobalState->config.highlightBlend->value();
    if (!StoneGen::parseHex(g_pGlobalState->config.colorMortar->value(),
                            sp.mortar) ||
        !StoneGen::parseHex(g_pGlobalState->config.colorAccent->value(),
                            sp.accent) ||
        !StoneGen::parseHex(g_pGlobalState->config.colorMoss->value(),
                            sp.mossColor)) {
      HyprlandAPI::addNotification(
          PHANDLE, "[imgborders] invalid procedural color in config",
          CHyprColor{1.0, 0.1, 0.1, 1.0}, 5000);
      m_isEnabled = false;
      return;
    }
    m_genWidth = 0;
    m_genHeight = 0;
    g_pDecorationPositioner->repositionDeco(this);
    return;
  }

  // image
  const auto texSrc = g_pGlobalState->config.image->value();
  if (texSrc.empty()) {
    m_isEnabled = false;
    return;
  }
  wordexp_t p;
  wordexp(texSrc.c_str(), &p, 0);
  std::string texSrcExpanded = "";
  for (size_t i = 0; i < p.we_wordc; i++)
    texSrcExpanded.append(p.we_wordv[i]);
  wordfree(&p);
  if (!std::filesystem::exists(texSrcExpanded)) {
    HyprlandAPI::addNotification(
        PHANDLE,
        std::format("[imgborders] image at \"{}\" doesn't exist",
                    texSrcExpanded),
        CHyprColor{1.0, 0.1, 0.1, 1.0}, 5000);
    m_isEnabled = false;
    return;
  }

  // Create textures
  // ------------

  auto tex = ImgUtils::load(texSrcExpanded);

  const auto BORDER_LEFT = (float)m_sizes[0];
  const auto BORDER_RIGHT = (float)m_sizes[1];
  const auto BORDER_TOP = (float)m_sizes[2];
  const auto BORDER_BOTTOM = (float)m_sizes[3];

  const auto WIDTH_MID = tex->m_size.x - BORDER_LEFT - BORDER_RIGHT;
  const auto HEIGHT_MID = tex->m_size.y - BORDER_TOP - BORDER_BOTTOM;

  m_tex_tl = ImgUtils::sliceTexture(tex, {{0., 0.}, {BORDER_LEFT, BORDER_TOP}});

  m_tex_t =
      ImgUtils::sliceTexture(tex, {{BORDER_LEFT, 0.}, {WIDTH_MID, BORDER_TOP}});

  m_tex_tr = ImgUtils::sliceTexture(
      tex, {{tex->m_size.x - BORDER_RIGHT, 0.}, {BORDER_RIGHT, BORDER_TOP}});

  m_tex_r =
      ImgUtils::sliceTexture(tex, {{tex->m_size.x - BORDER_RIGHT, BORDER_TOP},
                                   {BORDER_RIGHT, HEIGHT_MID}});

  m_tex_br = ImgUtils::sliceTexture(
      tex, {{tex->m_size.x - BORDER_RIGHT, tex->m_size.y - BORDER_BOTTOM},
            {BORDER_RIGHT, BORDER_BOTTOM}});

  m_tex_b =
      ImgUtils::sliceTexture(tex, {{BORDER_LEFT, tex->m_size.y - BORDER_BOTTOM},
                                   {WIDTH_MID, BORDER_BOTTOM}});

  m_tex_bl = ImgUtils::sliceTexture(
      tex, {{0., tex->m_size.y - BORDER_BOTTOM}, {BORDER_LEFT, BORDER_BOTTOM}});

  m_tex_l = ImgUtils::sliceTexture(
      tex, {{0., BORDER_TOP}, {BORDER_LEFT, HEIGHT_MID}});

  g_pDecorationPositioner->repositionDeco(this);
}

void CImgBorder::updateRules() {
  const auto PWINDOW = m_pWindow.lock();
  auto &rules = PWINDOW->m_ruleApplicator->m_otherProps.props;

  auto prevIsHidden = m_isHidden;

  m_isHidden = false;

  if (rules.contains(g_pGlobalState->noImgBordersRuleIdx))
    m_isHidden = truthy(rules.at(g_pGlobalState->noImgBordersRuleIdx)->effect);

  if (prevIsHidden != m_isHidden)
    g_pDecorationPositioner->repositionDeco(this);
}
