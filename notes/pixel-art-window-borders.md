---
id: pixel-art-window-borders
aliases: []
tags: []
---
# Pixel-art brick/stone window borders

Goal: window borders on red-sun-whorl rendered as pixel-art rock/stone/brick
walls, ideally with vine/leaf overlays. The actual deliverable is landing on
a good border design through iteration - not the tooling. A **border test
harness** (settings menu to switch render approaches at runtime and tweak
each one's parameters live) is scaffolding in service of that iteration, so
approaches can be compared side by side instead of round-tripping through
config edits and compositor restarts for every tweak. Worth keeping around
afterward once it exists, but it's a means to the design work, not the goal
itself.

## Rendering vehicle on Hyprland

Two existing plugins cover the mechanics of getting arbitrary pixels onto a
window border without writing a compositor from scratch:

- [hyprdecor](https://github.com/CapsAdmin/hyprdecor) - draws decorations
  from Android-style 9-patch bitmaps (1px metadata border marking
  stretch-vs-fixed regions). Handles simple tiled/stretched textures per
  window at any size. Good enough for the harness's simplest mode.
- [Hypr-DarkWindow](https://github.com/micha4w/Hypr-DarkWindow) - injects a
  custom GLSL `windowShader(inout vec4 color)` into Hyprland's per-window
  fragment shader, configured via Lua window rules, with `x_PixelPos`,
  `x_WindowSize`, `x_TexCoord`, `x_Texture()`, `x_Time`, `x_CursorPos`
  available. This is the vehicle for the procedural-shader mode - no baked
  texture needed, computed live per pixel.

Long-term, full control (window's absolute screen position, neighboring
windows) requires a custom decoration plugin against Hyprland's
`IHyprWindowDecoration` interface - every border/shadow/tab bar is already a
subclass of this
([decoration internals](https://deepwiki.com/hyprwm/Hyprland/6.7-window-decorations),
[plugin decoration docs](https://deepwiki.com/hyprwm/hyprland-plugins/5-window-decoration-plugins)).
That's the natural place for the harness to live once it needs to know
screen-absolute position or adjacent windows, rather than staying inside
someone else's plugin's config surface.

## Render approaches to expose as harness modes

### Mode 1: static repeating texture
One hand-drawn seamless stone/brick sprite, tiled via hyprdecor's 9-patch
system. No neighbor- or position-awareness. Baseline / control for the
harness.

### Mode 2: neighbor-aware tile selection from a sprite sheet
This is the game-dev "autotiling" problem - pick a tile from a larger sheet
based on which of the 8 neighboring border segments/corners are present.
Good overview: [Autotiling - Interactive Guide (Red Blob Games)](https://www.redblobgames.com/articles/autotile/claude/).

- **4-bit cardinal bitmask** - N/E/S/W neighbors each contribute a bit, sum
  indexes a 16-tile table. Cheap, ugly corners.
- **Blob/bitmask "47-tile" autotiling** - all 8 neighbors contribute a bit
  (256 states), but a diagonal only matters if both adjacent cardinals are
  also set, collapsing to 47 visually distinct tiles with clean inner/outer
  corners. Background:
  [Classification of Tilesets - BorisTheBrave](https://www.boristhebrave.com/2021/11/14/classification-of-tilesets/).
  Tooling exists to generate the sheet from source art:
  [itsjavi/autotiler](https://github.com/itsjavi/autotiler).
- **Dual-grid tiling** (current best practice, probably the harness default
  for this mode) - offset second grid, tiles placed at corners of the
  logical grid, picked via marching-squares over 4 neighbor cells. Needs
  only ~15-16 tiles instead of 47 for equal or better corner quality.
  [Quarter-Tile Autotiling - BorisTheBrave](https://www.boristhebrave.com/2023/05/31/quarter-tile-autotiling/),
  [Dual-grid tilesets, explained - SpriteCook](https://www.spritecook.ai/blog/dual-grid-tilesets-explained),
  reference implementation to read (not Godot-dependent to study):
  [pablogila/TileMapDual](https://github.com/pablogila/TileMapDual).
- **Wang tiles for stochastic variation** - assign tile edge colors so any
  edge-matching tiles are interchangeable, then pick randomly among matches.
  Gives irregular hand-laid stone look instead of obvious repetition.
  [Procedural Wang Tile Algorithm for Stochastic Wall Patterns (arXiv)](https://arxiv.org/pdf/1706.03950)
  is directly about generating this kind of wall.

For "where on screen it appears" as a harness parameter: key the sheet
lookup off a hash of absolute desktop position (not window-local 0,0) so the
wall reads as one continuous surface windows sit in front of, tunable as an
origin-offset param in the harness.

### Mode 3: fully procedural (runtime-generated, no sprite sheet)
Several distinct families, each plausible as its own harness mode with its
own parameter set:

- **Fragment-shader procedural texturing** (Inigo Quilez school) - Voronoi/
  Worley noise for stone-cell shapes, layered Perlin/fBm for surface
  roughness, distance-to-cell-edge for mortar lines. All per-pixel math, no
  texture at all. Plugs straight into Hypr-DarkWindow's `windowShader()`
  today. [iquilezles.org articles](https://iquilezles.org/articles/),
  [Book of Shaders - noise](https://thebookofshaders.com/12/), worked
  example: [ShaderToy procedural brick texture](https://www.shadertoy.com/view/WtdfD8).
  Natural tunable params: cell size, mortar width, roughness octaves/gain,
  color palette.
- **Cellular automata** - kernel rule where a cell's next state depends on a
  neighbor count (e.g. "wall if >=5 of surrounding 3x3 are wall"), iterated
  from noise until organic rock-blob shapes emerge.
  [Cellular Automaton Method for Cave Generation - Jeremy Kun](https://www.jeremykun.com/2012/07/29/the-cellular-automaton-method-for-cave-generation/),
  foundational paper:
  [Cellular automata for real-time generation of infinite cave levels (Johnson et al., PCG 2010)](https://dl.acm.org/doi/10.1145/1814256.1814266).
  Cheap; good for irregular worn-stone edges. Tunable params: birth/death
  neighbor thresholds, iteration count, seed.
- **Wave Function Collapse** - the closest prior art to "a kernel that lays
  out patterns based on what's nearby." Feed it a small hand-authored brick/
  stone sample; it synthesizes larger output by collapsing lowest-entropy
  cells and propagating edge-adjacency constraints outward, so every placed
  tile is locally consistent with already-placed neighbors. Generalizes
  naturally to staying consistent across multiple windows, since new
  regions only need to satisfy the constraint at their border with whatever
  is already generated. [gridbugs.org WFC writeup](https://www.gridbugs.org/wave-function-collapse/),
  [BorisTheBrave's WFC series](https://www.boristhebrave.com/tag/wfc/).
- **Image quilting** (Efros & Freeman) - patch-based synthesis from a real
  reference photo of a stone wall, stitching patches along minimum-error
  boundary cuts instead of hand-authoring tiles.
  [Original paper](https://people.eecs.berkeley.edu/~efros/research/quilting/quilting.pdf),
  reference implementation: [IPOL article + code](https://www.ipol.im/pub/art/2017/171/).
  Lower priority for the harness - more useful once there's a real
  reference photo to draw from than as an early comparison mode.

### Overlay: vines/leaves on top of any mode
- **L-systems** (Lindenmayer systems) - string-rewriting grammar (axiom +
  production rules) interpreted as branching turtle-graphics growth, the
  standard tool for procedural vines/ivy.
  [jrwhitemore's L-Systems & Vine Growth](http://jrwhitemore.blogspot.com/2012/02/l-systems-vine-growth.html),
  survey: [Rule-based Procedural Tree Modeling (arXiv)](https://arxiv.org/pdf/2204.03237).
  Weakness: pure L-systems don't react to environment, so vines look uniform
  unless growth is biased using something external - e.g. steer toward
  mortar gaps/cracks the wall-generation pass already knows about.
- **Space colonization algorithm** - environment-aware alternative to
  L-systems, grows toward attractor points and avoids obstacles. Worth a
  look if L-system uniformity is a problem once vines are actually being
  compared in the harness.

## Harness shape (supporting tooling, not the deliverable)

- Needs to be a real settings surface, not just config file edits - a menu
  (fuzzel-style picker, or a small GTK/web panel, TBD) that lets you: pick
  the active render mode, tweak that mode's exposed params live, and see
  the result on an actual window border without a compositor restart.
- Implies each mode's parameters need to be hot-reloadable at the shader/
  plugin level, not baked at Hyprland startup - this is the main open
  design question, since Hypr-DarkWindow's shader-per-window-rule model and
  hyprdecor's static 9-patch config aren't obviously built for live
  parameter tweaking. May end up wanting a small custom decoration plugin
  from the start (see "Rendering vehicle" above) that owns its own IPC
  socket or config-file-watch for live param updates, rather than fighting
  two other plugins' config reload models.
- Comparison harness suggests starting with Mode 1 and Mode 3's shader
  approach in parallel (both are usable today via existing plugins with no
  new compositor code), then adding Mode 2's sprite-sheet autotiling once
  there's a real sprite sheet worth autotiling from.

This needs real research/iteration (new territory: no existing Hyprland
decoration plugin work in this repo, non-trivial design question on live
param reload) - per repo convention, open a GitHub issue and move this
content there before starting implementation, rather than doing throwaway
work off this note.
