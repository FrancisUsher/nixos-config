#include "ImgBorderPassElement.hpp"
#include "ImgBorder.hpp"
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/pass/PassElement.hpp>
#include <render/Renderer.hpp>

using namespace Render::GL;

CImgBorderPassElement::CImgBorderPassElement(
    const CImgBorderPassElement::SData &data_) {
  data = data_;
}
CImgBorderPassElement::~CImgBorderPassElement() {}

std::vector<UP<IPassElement>> CImgBorderPassElement::draw() {
  data.deco->drawPass(g_pHyprRenderer->m_renderData.pMonitor.lock(), data.a);
  return {};
}

bool CImgBorderPassElement::needsLiveBlur() { return data.deco->shouldBlur(); }

bool CImgBorderPassElement::needsPrecomputeBlur() {
  return data.deco->shouldBlur();
}

const char *CImgBorderPassElement::passName() { return PASS_NAME; }

ePassElementType CImgBorderPassElement::type() { return EK_CUSTOM; }

// void CImgBorderPassElement::discard() {}

// bool CImgBorderPassElement::undiscardable() {}

std::optional<CBox> CImgBorderPassElement::boundingBox() {
  return data.deco->getDamageBox().translate(
      -g_pHyprRenderer->m_renderData.pMonitor->m_position);
}

// CRegion CImgBorderPassElement::opaqueRegion() {}

// bool CImgBorderPassElement::disableSimplification() {}
