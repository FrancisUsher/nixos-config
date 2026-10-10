#include "ImgBorder.hpp"
#include "ImgBorderPassElement.hpp"
#include "globals.hpp"
#include <config/shared/complex/ComplexDataTypes.hpp>
#include <desktop/state/WindowState.hpp>
#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/config/ConfigManager.hpp>
#include <hyprland/src/config/values/types/BoolValue.hpp>
#include <hyprland/src/config/values/types/CssGapValue.hpp>
#include <hyprland/src/config/values/types/FloatValue.hpp>
#include <hyprland/src/config/values/types/StringValue.hpp>
#include <hyprland/src/desktop/rule/windowRule/WindowRuleEffectContainer.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/state/MonitorState.hpp>
#include <hyprlang.hpp>
#include <hyprutils/memory/UniquePtr.hpp>
#include <string>

// Do NOT change this function.
APICALL EXPORT std::string PLUGIN_API_VERSION() { return HYPRLAND_API_VERSION; }

static void addToWindow(PHLWINDOW PWINDOW) {
  // Create border and apply it
  auto border = makeUnique<CImgBorder>(PWINDOW);
  border->m_self = border;
  g_pGlobalState->borders.emplace_back(border);
  HyprlandAPI::addWindowDecoration(PHANDLE, PWINDOW, std::move(border));
}

static void onWindowOpen(PHLWINDOW window) {
  if (!window->m_X11DoesntWantBorders) {
    // Make sure we haven't added the border already
    if (std::ranges::any_of(window->m_windowDecorations, [](const auto &d) {
          return d->getDisplayName() == DISPLAY_NAME;
        }))
      return;

    addToWindow(window);
  }
}

static void onWindowClose(PHLWINDOW window) {
  const auto BORDER = std::find_if(
      g_pGlobalState->borders.begin(), g_pGlobalState->borders.end(),
      [window](const auto &b) { return b->getWindow() == window; });

  if (BORDER == g_pGlobalState->borders.end())
    return;

  // We could use the API but this is faster + it doesn't matter here that much.
  window->removeWindowDeco(BORDER->get());
}

static void onWindowUpdateRules(PHLWINDOW window) {
  const auto BORDER = std::find_if(
      g_pGlobalState->borders.begin(), g_pGlobalState->borders.end(),
      [window](const auto &b) { return b->getWindow() == window; });

  if (BORDER == g_pGlobalState->borders.end())
    return;

  (*BORDER)->updateRules();
  window->updateWindowDecos();
}

static void onConfigReloaded() {
  for (auto &b : g_pGlobalState->borders) {
    b->updateConfig();
  }
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
  PHANDLE = handle;

  // Make sure we're running against the correct Hyprland version
  // ALWAYS add this to your plugins. It will prevent random crashes coming from
  // mismatched header versions.
  const std::string COMPOSITOR_HASH = __hyprland_api_get_hash();
  const std::string CLIENT_HASH = __hyprland_api_get_client_hash();

  if (COMPOSITOR_HASH != CLIENT_HASH) {
    HyprlandAPI::addNotification(PHANDLE,
                                 "[imgborders] Mismatched headers! Headers ver "
                                 "is not equal to running Hyprland ver.",
                                 CHyprColor{1.0, 0.2, 0.2, 1.0}, 5000);
    throw std::runtime_error("[imgborders] Version mismatch");
  }

  g_pGlobalState = makeUnique<SGlobalState>();

  // Register config values
  g_pGlobalState->config.image = makeShared<Config::Values::CStringValue>(
      "plugin:imgborders:image", "Border image file path.", "");
  g_pGlobalState->config.sizes = makeShared<Config::Values::CCssGapValue>(
      "plugin:imgborders:sizes",
      "The number of pixels to take from each edge of the image.", 0);
  g_pGlobalState->config.insets = makeShared<Config::Values::CCssGapValue>(
      "plugin:imgborders:insets",
      "The amount to inset each side into the window.", 0);
  g_pGlobalState->config.scale = makeShared<Config::Values::CFloatValue>(
      "plugin:imgborders:scale", "Scale the borders by some amount.", 1);
  g_pGlobalState->config.smooth = makeShared<Config::Values::CBoolValue>(
      "plugin:imgborders:smooth",
      "Whether the image should be smoothed pixelated.", true);
  g_pGlobalState->config.blur = makeShared<Config::Values::CBoolValue>(
      "plugin:imgborders:blur", "Whether transparency should have blur or not.",
      false);
  HyprlandAPI::addConfigValueV2(PHANDLE, g_pGlobalState->config.image);
  HyprlandAPI::addConfigValueV2(PHANDLE, g_pGlobalState->config.sizes);
  HyprlandAPI::addConfigValueV2(PHANDLE, g_pGlobalState->config.insets);
  HyprlandAPI::addConfigValueV2(PHANDLE, g_pGlobalState->config.scale);
  HyprlandAPI::addConfigValueV2(PHANDLE, g_pGlobalState->config.smooth);
  HyprlandAPI::addConfigValueV2(PHANDLE, g_pGlobalState->config.blur);

  // Register window rules
  g_pGlobalState->noImgBordersRuleIdx =
      Desktop::Rule::windowEffects()->registerEffect("imgborders:noimgborders");

  // Register callbacks
  static auto windowOpenHook =
      Event::bus()->m_events.window.open.listen(onWindowOpen);
  static auto windowCloseHook =
      Event::bus()->m_events.window.close.listen(onWindowClose);
  static auto windowUpdateRulesHook =
      Event::bus()->m_events.window.updateRules.listen(onWindowUpdateRules);
  static auto configReloadedHook =
      Event::bus()->m_events.config.reloaded.listen(onConfigReloaded);

  // Add to existing windows
  for (auto &w : Desktop::windowState()->windows()) {
    if (w->isHidden() || !w->m_isMapped)
      continue;
    addToWindow(w);
  }

  return {"imgborders", "Add image borders to windows.", "zacoons", VERSION};
}

APICALL EXPORT void PLUGIN_EXIT() {
  for (auto &m : State::monitorState()->monitors())
    m->m_scheduledRecalc = true;

  g_pHyprRenderer->m_renderPass.removeAllOfType(PASS_NAME);

  // Unregister window rules
  Desktop::Rule::windowEffects()->unregisterEffect(
      g_pGlobalState->noImgBordersRuleIdx);
}
