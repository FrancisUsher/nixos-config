#include "ImgUtils.hpp"
#include <GLES3/gl32.h>
#include <cairo/cairo.h>
#include <drm_fourcc.h>
#include <filesystem>
#include <format>
#include <helpers/Format.hpp>
#include <hyprland/src/debug/log/Logger.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Texture.hpp>
#include <render/Renderer.hpp>

SP<ITexture> createInvalidImageTexture() {
  SP<ITexture> tex = g_pHyprRenderer->createTexture(true);
  tex->allocate({512, 512});

  const auto CAIROSURFACE =
      cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 512, 512);
  const auto CAIRO = cairo_create(CAIROSURFACE);

  cairo_set_antialias(CAIRO, CAIRO_ANTIALIAS_NONE);
  cairo_save(CAIRO);
  cairo_set_source_rgba(CAIRO, 0, 0, 0, 1);
  cairo_set_operator(CAIRO, CAIRO_OPERATOR_SOURCE);
  cairo_paint(CAIRO);
  cairo_set_source_rgba(CAIRO, 1, 0, 1, 1);
  cairo_rectangle(CAIRO, 256, 0, 256, 256);
  cairo_fill(CAIRO);
  cairo_rectangle(CAIRO, 0, 256, 256, 256);
  cairo_fill(CAIRO);
  cairo_restore(CAIRO);

  cairo_surface_flush(CAIROSURFACE);

  // Copy the data to an OpenGL texture we have
  const GLint glFormat = GL_RGBA;
  const GLint glType = GL_UNSIGNED_BYTE;

  const auto DATA = cairo_image_surface_get_data(CAIROSURFACE);
  glBindTexture(GL_TEXTURE_2D, tex->m_texID);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_R, GL_BLUE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_B, GL_RED);
  glTexImage2D(GL_TEXTURE_2D, 0, glFormat, tex->m_size.x, tex->m_size.y, 0,
               glFormat, glType, DATA);

  cairo_surface_destroy(CAIROSURFACE);
  cairo_destroy(CAIRO);

  return tex;
}

SP<ITexture> ImgUtils::load(const std::string &fullPath) {
  if (!std::filesystem::exists(fullPath)) {
    Log::logger->log(Log::ERR,
                     "ImgUtils failed to load {} (image doesn't exist. typo?)",
                     fullPath);
    return createInvalidImageTexture();
  }

  const auto CAIROSURFACE =
      cairo_image_surface_create_from_png(fullPath.c_str());
  if (!CAIROSURFACE ||
      cairo_surface_status(CAIROSURFACE) != CAIRO_STATUS_SUCCESS) {
    cairo_surface_destroy(CAIROSURFACE);
    Log::logger->log(
        Log::ERR,
        "ImgUtils failed to load {} (corrupt / inaccessible / not png)",
        fullPath);
    return createInvalidImageTexture();
  }

  const auto CAIROFORMAT = cairo_image_surface_get_format(CAIROSURFACE);
  auto tex = g_pHyprRenderer->createTexture();

  tex->allocate({cairo_image_surface_get_width(CAIROSURFACE),
                 cairo_image_surface_get_height(CAIROSURFACE)});

  const GLint glIFormat =
      CAIROFORMAT == CAIRO_FORMAT_RGB96F ? GL_RGB32F : GL_RGBA;
  const GLint glFormat = CAIROFORMAT == CAIRO_FORMAT_RGB96F ? GL_RGB : GL_RGBA;
  const GLint glType =
      CAIROFORMAT == CAIRO_FORMAT_RGB96F ? GL_FLOAT : GL_UNSIGNED_BYTE;

  const auto DATA = cairo_image_surface_get_data(CAIROSURFACE);
  glBindTexture(GL_TEXTURE_2D, tex->m_texID);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

  if (CAIROFORMAT != CAIRO_FORMAT_RGB96F) {
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_R, GL_BLUE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_B, GL_RED);
  }

  glTexImage2D(GL_TEXTURE_2D, 0, glIFormat, tex->m_size.x, tex->m_size.y, 0,
               glFormat, glType, DATA);

  cairo_surface_destroy(CAIROSURFACE);

  return tex;
}

SP<ITexture> ImgUtils::sliceTexture(SP<ITexture> src, CBox box) {
  box.width = std::max(1., box.width);
  box.height = std::max(1., box.height);

  // Initialize the dst texture
  // ------------

  SP<ITexture> tex = g_pHyprRenderer->createTexture();
  tex->allocate(box.size());

  const GLint glIFormat = GL_RGBA;
  const GLint glFormat = GL_RGBA;
  const GLint glType = GL_UNSIGNED_BYTE;
  const int DATA_SIZE = box.width * box.height * 4;
  const auto DATA = new unsigned char[DATA_SIZE]{0};
  glBindTexture(GL_TEXTURE_2D, tex->m_texID);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_R, GL_BLUE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_B, GL_RED);
  glTexImage2D(GL_TEXTURE_2D, 0, glIFormat, tex->m_size.x, tex->m_size.y, 0,
               glFormat, glType, DATA);
  delete[] DATA;

  // Copy the region from src to dst
  // ------------

  glCopyImageSubData(src->m_texID, GL_TEXTURE_2D, 0, box.x, box.y, 0,
                     tex->m_texID, GL_TEXTURE_2D, 0, 0, 0, 0, tex->m_size.x,
                     tex->m_size.y, 1);

  return tex;
}

SP<ITexture> ImgUtils::fromRGBA(const uint8_t *data, int width, int height) {
  SP<ITexture> tex = g_pHyprRenderer->createTexture();
  tex->allocate({width, height});

  glBindTexture(GL_TEXTURE_2D, tex->m_texID);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, data);

  return tex;
}
