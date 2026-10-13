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

struct SRng {
  uint64_t s;

  explicit SRng(uint64_t seed) : s(seed) {}

  uint64_t next();
  double unit();
  int range(int lo, int hi);
  double uniform(double lo, double hi);
  bool chance(double p);
};

struct SRect {
  int x, y, w, h;
};

struct SCanvas {
  int w, h;
  std::vector<uint8_t> &px;

  void set(int x, int y, SRGB c);
};

void shadeStone(SCanvas &canvas, SRng &rng, const SRect &r, const SParams &p);

void growMoss(SCanvas &canvas, SRng &rng, const SRect &r, const SParams &p);

SImage renderEdge(const SParams &params, eEdge edge, int width, int height);

bool parseHex(const std::string &hex, SRGB &out);

uint64_t mix(uint64_t a, uint64_t b);
} // namespace StoneGen
