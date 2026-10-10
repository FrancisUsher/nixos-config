#include "WallField.hpp"

#include <algorithm>
#include <cmath>
#include <limits>

using namespace StoneGen;

namespace WallField {
namespace {
struct SGrid {
  int w, h;
  std::vector<uint8_t> v;

  SGrid(int w_, int h_) : w(w_), h(h_), v((size_t)w_ * h_, 0) {}

  uint8_t &at(int i, int j) { return v[(size_t)j * w + i]; }
  uint8_t get(int i, int j) const {
    if (i < 0 || j < 0 || i >= w || j >= h)
      return 0;
    return v[(size_t)j * w + i];
  }
};

void rasterize(SGrid &grid, const SBox &b, double cell, int x0, int y0,
               bool covering) {
  const auto lo = [&](double v) {
    return (int)(covering ? std::floor(v / cell) : std::ceil(v / cell));
  };
  const auto hi = [&](double v) {
    return (int)(covering ? std::ceil(v / cell) : std::floor(v / cell));
  };
  const int i0 = std::max(0, lo(b.x) - x0);
  const int i1 = std::min(grid.w, hi(b.x + b.w) - x0);
  const int j0 = std::max(0, lo(b.y) - y0);
  const int j1 = std::min(grid.h, hi(b.y + b.h) - y0);
  for (int j = j0; j < j1; j++)
    for (int i = i0; i < i1; i++)
      grid.at(i, j) = 1;
}

SGrid boxFilter(const SGrid &src, int r, bool erode) {
  const int w = src.w, h = src.h;
  std::vector<int> sum((size_t)(w + 1) * (h + 1), 0);
  for (int j = 0; j < h; j++)
    for (int i = 0; i < w; i++)
      sum[(size_t)(j + 1) * (w + 1) + i + 1] = src.get(i, j) +
                                               sum[(size_t)j * (w + 1) + i + 1] +
                                               sum[(size_t)(j + 1) * (w + 1) + i] -
                                               sum[(size_t)j * (w + 1) + i];
  const auto area = [&](int i0, int j0, int i1, int j1) {
    i0 = std::clamp(i0, 0, w);
    i1 = std::clamp(i1, 0, w);
    j0 = std::clamp(j0, 0, h);
    j1 = std::clamp(j1, 0, h);
    return sum[(size_t)j1 * (w + 1) + i1] - sum[(size_t)j0 * (w + 1) + i1] -
           sum[(size_t)j1 * (w + 1) + i0] + sum[(size_t)j0 * (w + 1) + i0];
  };
  const int full = (2 * r + 1) * (2 * r + 1);
  SGrid out(w, h);
  for (int j = 0; j < h; j++)
    for (int i = 0; i < w; i++) {
      const int n = area(i - r, j - r, i + r + 1, j + r + 1);
      out.at(i, j) = erode ? n == full : n > 0;
    }
  return out;
}

const SWindow *ownerOf(const std::vector<SWindow> &windows, double px, double py) {
  const SWindow *best = nullptr;
  double bestDist = std::numeric_limits<double>::max();
  for (const auto &win : windows) {
    const auto &f = win.frame;
    const double dx = std::max({f.x - px, 0.0, px - (f.x + f.w)});
    const double dy = std::max({f.y - py, 0.0, py - (f.y + f.h)});
    const double d = dx * dx + dy * dy;
    if (d < bestDist) {
      bestDist = d;
      best = &win;
    }
  }
  return best;
}

int pickThickness(SRng &rng, int t) {
  if (t <= 7) {
    if (t >= 5 && rng.chance(0.3))
      return rng.range(2, t - 3);
    return t;
  }
  const int th = rng.range(3, 6);
  return t - th - 1 < 3 ? t : th;
}
} // namespace

SField build(const std::vector<SWindow> &windows, const SParams &style,
             double cell, double mergeDistance) {
  SField field;
  if (windows.empty() || cell <= 0)
    return field;

  const int r = mergeDistance > 0 ? (int)std::ceil(mergeDistance / cell / 2.0) : 0;
  double minX = std::numeric_limits<double>::max(), minY = minX;
  double maxX = std::numeric_limits<double>::lowest(), maxY = maxX;
  for (const auto &win : windows) {
    minX = std::min(minX, win.frame.x);
    minY = std::min(minY, win.frame.y);
    maxX = std::max(maxX, win.frame.x + win.frame.w);
    maxY = std::max(maxY, win.frame.y + win.frame.h);
  }
  const int pad = r + 2;
  field.x0 = (int)std::floor(minX / cell) - pad;
  field.y0 = (int)std::floor(minY / cell) - pad;
  field.w = (int)std::ceil(maxX / cell) + pad - field.x0;
  field.h = (int)std::ceil(maxY / cell) + pad - field.y0;

  SGrid frames(field.w, field.h), contents(field.w, field.h);
  for (const auto &win : windows) {
    rasterize(frames, win.frame, cell, field.x0, field.y0, true);
    rasterize(contents, win.content, cell, field.x0, field.y0, false);
  }

  SGrid wall = r > 0 ? boxFilter(boxFilter(frames, r, false), r, true) : frames;
  for (size_t k = 0; k < wall.v.size(); k++)
    wall.v[k] = wall.v[k] && !contents.v[k];

  SGrid interior(field.w, field.h);
  for (int j = 0; j < field.h; j++)
    for (int i = 0; i < field.w; i++) {
      bool all = true;
      for (int dj = -1; dj <= 1 && all; dj++)
        for (int di = -1; di <= 1 && all; di++)
          all = wall.get(i + di, j + dj);
      interior.at(i, j) = all;
    }

  field.rgba.assign((size_t)field.w * field.h * 4, 0);
  SCanvas canvas{field.w, field.h, field.rgba};
  for (int j = 0; j < field.h; j++)
    for (int i = 0; i < field.w; i++)
      if (wall.get(i, j))
        canvas.set(i, j, style.mortar);

  SGrid used(field.w, field.h);
  const auto isFree = [&](int i, int j) {
    return interior.get(i, j) && !used.get(i, j);
  };
  const auto run = [&](int i, int j, int di, int dj, bool freeOnly) {
    int n = 0;
    while (n < 64 && (freeOnly ? isFree(i + di * n, j + dj * n)
                               : interior.get(i + di * n, j + dj * n)))
      n++;
    return n;
  };

  for (int j = 0; j < field.h; j++) {
    for (int i = 0; i < field.w; i++) {
      if (!isFree(i, j))
        continue;

      const double px = (field.x0 + i + 0.5) * cell;
      const double py = (field.y0 + j + 0.5) * cell;
      const auto *owner = ownerOf(windows, px, py);
      const int relX = i + field.x0 - (int)std::floor(owner->frame.x / cell);
      const int relY = j + field.y0 - (int)std::floor(owner->frame.y / cell);
      SRng rng(mix(mix(owner->seed, (uint64_t)(int64_t)relX), (uint64_t)(int64_t)relY));

      const bool horizontal = run(i, j, 1, 0, false) >= run(i, j, 0, 1, false);
      const int di = horizontal ? 1 : 0, dj = horizontal ? 0 : 1;
      const int alongFree = run(i, j, di, dj, true);
      const int acrossFree = run(i, j, dj, di, true);

      int len = rng.range(4, 15);
      if (alongFree - len < 4)
        len = alongFree;
      len = std::min(len, alongFree);

      int th = pickThickness(rng, acrossFree);
      for (int k = 1; k < th; k++) {
        bool rowFree = true;
        for (int a = 0; a < len && rowFree; a++)
          rowFree = isFree(i + di * a + dj * k, j + dj * a + di * k);
        if (!rowFree) {
          th = k;
          break;
        }
      }

      const SRect rect = horizontal ? SRect{i, j, len, th} : SRect{i, j, th, len};
      for (int y = rect.y - 1; y <= rect.y + rect.h; y++)
        for (int x = rect.x - 1; x <= rect.x + rect.w; x++)
          if (x >= 0 && y >= 0 && x < field.w && y < field.h)
            used.at(x, y) = 1;

      shadeStone(canvas, rng, rect, style);
      growMoss(canvas, rng, rect, style);
    }
  }

  return field;
}

SImage crop(const SField &field, int x0, int y0, int w, int h) {
  SImage img;
  img.w = std::max(0, w);
  img.h = std::max(0, h);
  img.rgba.assign((size_t)img.w * img.h * 4, 0);
  for (int j = 0; j < img.h; j++) {
    const int fy = y0 + j - field.y0;
    if (fy < 0 || fy >= field.h)
      continue;
    for (int i = 0; i < img.w; i++) {
      const int fx = x0 + i - field.x0;
      if (fx < 0 || fx >= field.w)
        continue;
      const auto src = ((size_t)fy * field.w + fx) * 4;
      const auto dst = ((size_t)j * img.w + i) * 4;
      std::copy_n(field.rgba.begin() + (long)src, 4, img.rgba.begin() + (long)dst);
    }
  }
  return img;
}
} // namespace WallField
