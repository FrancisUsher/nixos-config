---
id: hyprland-imgborders-bug
aliases: []
tags: []
---

`Render::IHyprRenderer::m_renderData` is no longer supported as of hyprland 0.57

This means our imgborders plugin needs to be fixed. I disabled it for now.

Since this is always likely to be a little flaky, should find a way to easily disable it
or fallback to failing gracefully during a build.
