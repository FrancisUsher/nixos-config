import random
import sys

from PIL import Image

random.seed(7)

# Panel is 2160x1350 (source: `cat /sys/class/drm/card*/card*-eDP-1/modes` on
# red-sun-whorl). BIOS_LOGO.TXT caps custom logos at 40% per dimension ->
# 864x540, which is also exactly the panel's own 16:10 aspect ratio.
GRID_W, GRID_H = 72, 45
SCALE = 12
W, H = GRID_W * SCALE, GRID_H * SCALE
assert (W, H) == (864, 540)

# Dim, ruddy, embers-going-out palette. Low contrast is deliberate: a world
# barely lit by a dying sun should be hard to make out, not brightened for
# legibility.
BG      = (13, 10, 9)      # near-black, warm undertone
BG_ALT  = (17, 12, 10)     # subtle band variation in the sky
GLOW_1  = (28, 14, 10)     # faintest halo
GLOW_2  = (40, 18, 12)
GLOW_3  = (54, 23, 15)
CORE    = (70, 29, 19)     # dimmest possible "lit" point - a lamp turned all the way down
RUIN    = (6, 5, 4)        # near-black silhouette - the skyline

grid = [[BG for _ in range(GRID_W)] for _ in range(GRID_H)]

# Sun center: low in the frame, as if setting/dying.
cx, cy = GRID_W / 2, GRID_H * 0.58
max_r = GRID_H * 0.34

for y in range(GRID_H):
    for x in range(GRID_W):
        dx, dy = x - cx, (y - cy) * 1.15  # slightly flatten vertically
        r = (dx * dx + dy * dy) ** 0.5
        if r < max_r * 0.32:
            grid[y][x] = CORE
        elif r < max_r * 0.55:
            grid[y][x] = GLOW_3
        elif r < max_r * 0.8:
            grid[y][x] = GLOW_2
        elif r < max_r:
            grid[y][x] = GLOW_1
        else:
            grid[y][x] = BG_ALT if (y % 7 == 0 and random.random() < 0.3) else BG

# ---- crumbling ancient city skyline (silhouette mask: True = solid ruin) ----
GROUND = GRID_H - 3
mask = [[False] * GRID_W for _ in range(GRID_H)]


def fill_rect(x0, x1, top, bottom=GROUND):
    for x in range(max(x0, 0), min(x1, GRID_W)):
        for y in range(max(top, 0), min(bottom, GRID_H)):
            mask[y][x] = True


def crenellated_tower(x0, x1, top, tooth=2, period=4):
    for x in range(x0, x1):
        local = (x - x0) % period
        t = top if local < period // 2 else top + tooth
        fill_rect(x, x + 1, t)


def crumbling_tower(x0, x1, base_top, wobble=2, bite=None):
    t = base_top
    for x in range(x0, x1):
        t = max(base_top - wobble, min(base_top + wobble * 2, t + random.choice([-1, 0, 0, 1])))
        fill_rect(x, x + 1, t)
    if bite:
        bx0, bx1, by0, by1 = bite
        for x in range(bx0, bx1):
            for y in range(by0, by1):
                if 0 <= x < GRID_W and 0 <= y < GRID_H:
                    mask[y][x] = False


def arch_block(x0, x1, top, r):
    fill_rect(x0, x1, top)
    center = (x0 + x1) / 2
    for x in range(x0, x1):
        dx = x - center
        if abs(dx) < r:
            hole_h = int(round((r * r - dx * dx) ** 0.5))
            for y in range(GROUND - hole_h, GROUND):
                if 0 <= y < GRID_H:
                    mask[y][x] = False


def colonnade(x0, x1, spacing=3, heights=None):
    i = 0
    x = x0
    while x < x1:
        h = heights[i % len(heights)] if heights else random.randint(6, 14)
        top = GROUND - h
        # occasional snapped/broken column: jagged shorter top
        if random.random() < 0.3:
            top += random.randint(2, 4)
        fill_rect(x, x + 1, top)
        x += spacing
        i += 1


def ziggurat(x0, x1, top, steps=4):
    width = x1 - x0
    step_h = (GROUND - top) / steps
    step_w = width / (2 * steps)
    for s in range(steps):
        inset = int(step_w * s)
        y0 = int(top + step_h * s)
        fill_rect(x0 + inset, x1 - inset, y0)


def rubble(x0, x1, height=3):
    for x in range(x0, x1):
        h = random.randint(1, height)
        fill_rect(x, x + 1, GROUND - h)


rubble(0, 6, height=2)
crenellated_tower(6, 16, GROUND - 24, tooth=2, period=4)
rubble(16, 18, height=2)
crumbling_tower(18, 28, GROUND - 17, wobble=3, bite=(22, 25, GROUND - 12, GROUND - 8))
arch_block(28, 40, GROUND - 12, r=5)
rubble(40, 42, height=2)
colonnade(42, 54, spacing=3, heights=[14, 8, 12, 6, 15])
rubble(54, 56, height=2)
ziggurat(56, 68, GROUND - 18, steps=4)
crumbling_tower(68, 72, GROUND - 12, wobble=2)

for y in range(GRID_H):
    for x in range(GRID_W):
        if mask[y][x]:
            grid[y][x] = RUIN

img = Image.new("RGB", (GRID_W, GRID_H))
for y in range(GRID_H):
    for x in range(GRID_W):
        img.putpixel((x, y), grid[y][x])

img = img.resize((W, H), Image.NEAREST)

# Smooth fade-to-black vignette on the upscaled image, deliberately not
# pixelated like the rest of the scene.
px = img.load()
margin = 0.16  # fraction of min(W, H) over which the fade happens


def smoothstep(t):
    if t <= 0:
        return 0.0
    if t >= 1:
        return 1.0
    return t * t * (3 - 2 * t)


fade_px = margin * min(W, H)
for y in range(H):
    dy = min(y, H - 1 - y)
    for x in range(W):
        dx = min(x, W - 1 - x)
        edge_dist = min(dx, dy)
        factor = smoothstep(edge_dist / fade_px)
        if factor < 1.0:
            r, g, b = px[x, y]
            px[x, y] = (round(r * factor), round(g * factor), round(b * factor))

# BIOS_LOGO.TXT caps custom logos at 60KB; a small adaptive palette keeps
# this GIF well under that with room to spare.
img_p = img.convert("P", palette=Image.ADAPTIVE, colors=64)
img_p.save(sys.argv[1], format="GIF")
