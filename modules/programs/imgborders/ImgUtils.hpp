#pragma once

#include <hyprland/src/render/Texture.hpp>

using namespace Render;

namespace ImgUtils {
SP<ITexture> load(const std::string &filename);

SP<ITexture> sliceTexture(SP<ITexture> tex, CBox box);

SP<ITexture> fromRGBA(const uint8_t *data, int width, int height);
} // namespace ImgUtils
