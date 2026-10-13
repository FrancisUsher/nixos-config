#pragma once

#include "StoneGen.hpp"

#include <cstdint>
#include <vector>

namespace WallField {
struct SBox {
  double x, y, w, h;
};

struct SWindow {
  uint64_t seed;
  SBox frame;
  SBox content;
};

struct SField {
  int x0 = 0;
  int y0 = 0;
  int w = 0;
  int h = 0;
  std::vector<uint8_t> rgba;
};

SField build(const std::vector<SWindow> &windows, const StoneGen::SParams &style,
             double cell, double mergeDistance);

StoneGen::SImage crop(const SField &field, int x0, int y0, int w, int h);
} // namespace WallField
