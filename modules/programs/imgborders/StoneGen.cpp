#include "StoneGen.hpp"

#include <algorithm>
#include <cmath>

namespace StoneGen {
uint64_t SRng::next() {
  uint64_t z = (s += 0x9E3779B97F4A7C15ULL);
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
  z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
  return z ^ (z >> 31);
}

double SRng::unit() { return (double)(next() >> 11) * 0x1.0p-53; }

int SRng::range(int lo, int hi) {
  return lo + (int)(next() % (uint64_t)(hi - lo + 1));
}

double SRng::uniform(double lo, double hi) { return lo + (hi - lo) * unit(); }

bool SRng::chance(double p) { return unit() < p; }

void SCanvas::set(int x, int y, SRGB c) {
  if (x < 0 || y < 0 || x >= w || y >= h)
    return;
  const auto i = (size_t)(y * w + x) * 4;
  px[i] = (uint8_t)std::lround(std::clamp(c.r, 0.F, 255.F));
  px[i + 1] = (uint8_t)std::lround(std::clamp(c.g, 0.F, 255.F));
  px[i + 2] = (uint8_t)std::lround(std::clamp(c.b, 0.F, 255.F));
  px[i + 3] = 255;
}

namespace {
SRGB blend(SRGB a, SRGB b, double t) {
  return {(float)(a.r + (b.r - a.r) * t), (float)(a.g + (b.g - a.g) * t),
          (float)(a.b + (b.b - a.b) * t)};
}

std::vector<SRect> stripRects(SRng &rng, int along0, int length, int thickness) {
  std::vector<SRect> rects;
  const int inner = thickness - 2;
  int pos = 0;
  while (pos < length) {
    int w = rng.range(5, 16);
    if (length - pos - w < 5)
      w = length - pos;
    if (w >= 2) {
      if (inner >= 5 && w <= 10 && rng.chance(0.3)) {
        const int split = rng.range(2, inner - 3);
        rects.push_back({along0 + pos + 1, 1, w - 1, split});
        rects.push_back({along0 + pos + 1, split + 2, w - 1, inner - 1 - split});
      } else {
        rects.push_back({along0 + pos + 1, 1, w - 1, inner});
      }
    }
    pos += w;
  }
  return rects;
}

} // namespace

void shadeStone(SCanvas &canvas, SRng &rng, const SRect &r, const SParams &p) {
  const double k = 1 + rng.uniform(-0.6, 0.6) * p.roughness;
  const double baseT = p.stoneBlend * k;
  const double hiT = p.highlightBlend * k;
  const double loT = baseT * 0.55;

  for (int y = r.y; y < r.y + r.h; y++) {
    for (int x = r.x; x < r.x + r.w; x++) {
      double t = baseT;
      if (y == r.y || x == r.x)
        t = hiT;
      else if (y == r.y + r.h - 1 || x == r.x + r.w - 1)
        t = loT;
      if (rng.chance(p.roughness * 0.35))
        t += rng.chance(0.5) ? 0.05 : -0.05;
      canvas.set(x, y, blend(p.mortar, p.accent, std::max(0.0, t)));
    }
  }

  const struct {
    int x, y, dx, dy;
  } corners[] = {{r.x, r.y, 1, 1},
                 {r.x + r.w - 1, r.y, -1, 1},
                 {r.x, r.y + r.h - 1, 1, -1},
                 {r.x + r.w - 1, r.y + r.h - 1, -1, -1}};
  for (const auto &c : corners) {
    if (!rng.chance(p.chipping))
      continue;
    canvas.set(c.x, c.y, p.mortar);
    if (rng.chance(p.chipping) && r.w > 3 && r.h > 3) {
      canvas.set(c.x + c.dx, c.y, p.mortar);
      canvas.set(c.x, c.y + c.dy, p.mortar);
    }
  }

  if (r.w > 5 && r.h > 4 && rng.chance(p.chipping * 0.5)) {
    const auto crack = blend(p.mortar, p.accent, loT * 0.5);
    const int cx = rng.range(r.x + 2, r.x + r.w - 3);
    const int step = rng.chance(0.5) ? 1 : -1;
    const int len = rng.range(2, r.h - 2);
    for (int i = 0; i < len; i++) {
      const int px = cx + (i / 2) * step;
      if (px > r.x && px < r.x + r.w - 1)
        canvas.set(px, r.y + 1 + i, crack);
    }
  }
}

void growMoss(SCanvas &canvas, SRng &rng, const SRect &r, const SParams &p) {
  if (p.moss <= 0)
    return;
  const auto light = blend(p.mortar, p.mossColor, p.highlightBlend);
  const auto dark = blend(p.mortar, p.mossColor, p.stoneBlend * 1.4);
  const int yMin = r.y - 1;
  const int yMax = r.y + std::min(r.h, 3);
  for (int x0 = r.x; x0 < r.x + r.w; x0++) {
    if (!rng.chance(p.moss * 0.08))
      continue;
    std::vector<std::pair<int, int>> frontier{{x0, r.y}};
    const int steps = rng.range(2, 7);
    for (int s = 0; s < steps && !frontier.empty(); s++) {
      const auto idx = (size_t)rng.range(0, (int)frontier.size() - 1);
      const auto [x, y] = frontier[idx];
      frontier.erase(frontier.begin() + (long)idx);
      canvas.set(x, y, rng.chance(0.4) ? light : dark);
      const std::pair<int, int> next[] = {
          {x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}};
      for (const auto &[nx, ny] : next) {
        if (nx >= r.x && nx < r.x + r.w && ny >= yMin && ny < yMax)
          frontier.emplace_back(nx, ny);
      }
    }
  }
}
uint64_t mix(uint64_t a, uint64_t b) {
  SRng rng(a ^ (b * 0x9E3779B97F4A7C15ULL));
  return rng.next();
}

SImage renderEdge(const SParams &p, eEdge edge, int width, int height) {
  const int b = p.thickness;
  const bool horizontal = edge == EDGE_TOP || edge == EDGE_BOTTOM;

  SImage img;
  img.w = horizontal ? width : b;
  img.h = horizontal ? b : std::max(0, height - 2 * b);
  img.rgba.assign((size_t)img.w * img.h * 4, 0);
  if (img.w <= 0 || img.h <= 0)
    return img;

  SCanvas canvas{img.w, img.h, img.rgba};
  for (int y = 0; y < img.h; y++)
    for (int x = 0; x < img.w; x++)
      canvas.set(x, y, p.mortar);

  const uint64_t edgeSeed = mix(p.seed, (uint64_t)edge);
  SRng layout(edgeSeed);

  std::vector<SRect> rects;
  if (horizontal) {
    if (edge == EDGE_TOP) {
      rects.push_back({1, 1, b - 1, b - 1});
      rects.push_back({width - b + 1, 1, b - 2, b - 1});
    } else {
      rects.push_back({1, 1, b - 1, b - 2});
      rects.push_back({width - b + 1, 1, b - 2, b - 2});
    }
    for (const auto &r : stripRects(layout, b, width - 2 * b, b))
      rects.push_back(r);
  } else {
    for (const auto &r : stripRects(layout, 0, img.h, b))
      rects.push_back({r.y, r.x, r.h, r.w});
  }

  for (size_t i = 0; i < rects.size(); i++) {
    SRng rng(mix(edgeSeed, 1000 + i));
    shadeStone(canvas, rng, rects[i], p);
    growMoss(canvas, rng, rects[i], p);
  }

  return img;
}

bool parseHex(const std::string &hex, SRGB &out) {
  const auto h = hex.starts_with('#') ? hex.substr(1) : hex;
  if (h.size() != 6)
    return false;
  try {
    const auto v = std::stoul(h, nullptr, 16);
    out = {(float)((v >> 16) & 0xFF), (float)((v >> 8) & 0xFF),
           (float)(v & 0xFF)};
    return true;
  } catch (...) {
    return false;
  }
}
} // namespace StoneGen
