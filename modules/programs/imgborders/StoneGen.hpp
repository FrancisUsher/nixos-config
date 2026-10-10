#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace StoneGen {
struct SRGB {
  float r = 0, g = 0, b = 0;
};

struct SParams {
  uint64_t seed = 1;
  int thickness = 8;
  float roughness = 0.5F;
  float chipping = 0.4F;
  float moss = 0.2F;
  float stoneBlend = 0.2F;
  float highlightBlend = 0.45F;
  SRGB mortar;
  SRGB accent;
  SRGB mossColor;
};

enum eEdge { EDGE_TOP = 0, EDGE_RIGHT, EDGE_BOTTOM, EDGE_LEFT };

struct SImage {
  int w = 0;
  int h = 0;
  std::vector<uint8_t> rgba;
};

SImage renderEdge(const SParams &params, eEdge edge, int width, int height);

bool parseHex(const std::string &hex, SRGB &out);

uint64_t mix(uint64_t a, uint64_t b);
} // namespace StoneGen
