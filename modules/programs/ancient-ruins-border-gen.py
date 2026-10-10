import argparse
import json
import os
import random

from PIL import Image

N = 32
B = 8  # border thickness in source pixels


def hex_to_rgb(h):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def blend(c1, c2, t):
    return tuple(round(a + (b - a) * t) for a, b in zip(c1, c2))


def brick_module(mortar, stone, highlight):
    """8x8 RGBA pixel block: a single stone brick, barely lit from black."""
    px = [[mortar for _ in range(8)] for _ in range(8)]
    for y in range(1, 7):
        for x in range(1, 7):
            px[y][x] = stone
    # faint bevel: a single highlighted pixel-line on the top/left edge,
    # nothing on the bottom/right (fades back to mortar/black)
    for x in range(1, 7):
        px[1][x] = highlight
    for y in range(2, 7):
        px[y][1] = highlight
    return px


PROC_L = 240
PROC_N = 2 * B + PROC_L


def strip_rects(rng, along0, length):
    rects = []
    pos = 0
    while pos < length:
        w = rng.randint(5, 16)
        if length - pos - w < 5:
            w = length - pos
        if rng.random() < 0.3 and w <= 10:
            split = rng.choice((2, 3))
            rects.append((along0 + pos + 1, 1, w - 1, split))
            rects.append((along0 + pos + 1, split + 2, w - 1, B - 3 - split))
        else:
            rects.append((along0 + pos + 1, 1, w - 1, B - 2))
        pos += w
    return rects


def procedural_rects(rng):
    n = PROC_N
    rects = [
        (1, 1, B - 1, B - 1),
        (n - B + 1, 1, B - 2, B - 1),
        (1, n - B + 1, B - 1, B - 2),
        (n - B + 1, n - B + 1, B - 2, B - 2),
    ]
    for x, y, w, h in strip_rects(rng, B, PROC_L):
        rects.append((x, y, w, h))
    for x, y, w, h in strip_rects(rng, B, PROC_L):
        rects.append((x, n - B + y, w, h))
    for a, c, w, h in strip_rects(rng, B, PROC_L):
        rects.append((c, a, h, w))
    for a, c, w, h in strip_rects(rng, B, PROC_L):
        rects.append((n - B + c, a, h, w))
    return rects


def shade_stone(img, rng, rect, mortar, ember, args):
    x0, y0, w, h = rect
    r = args.roughness
    k = 1 + rng.uniform(-0.6, 0.6) * r
    base_t = args.stone_blend * k
    hi_t = args.highlight_blend * k
    lo_t = base_t * 0.55
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if y == y0 or x == x0:
                t = hi_t
            elif y == y0 + h - 1 or x == x0 + w - 1:
                t = lo_t
            else:
                t = base_t
            if rng.random() < r * 0.35:
                t += rng.choice((-1, 1)) * 0.05
            img.putpixel((x, y), (*blend(mortar, ember, max(0.0, t)), 255))

    c = args.chipping
    corners = [(x0, y0, 1, 1), (x0 + w - 1, y0, -1, 1),
               (x0, y0 + h - 1, 1, -1), (x0 + w - 1, y0 + h - 1, -1, -1)]
    for cx, cy, dx, dy in corners:
        if rng.random() < c:
            img.putpixel((cx, cy), (*mortar, 255))
            if rng.random() < c and w > 3 and h > 3:
                img.putpixel((cx + dx, cy), (*mortar, 255))
                img.putpixel((cx, cy + dy), (*mortar, 255))
    if w > 5 and h > 4 and rng.random() < c * 0.5:
        crack = blend(mortar, ember, lo_t * 0.5)
        cx = rng.randint(x0 + 2, x0 + w - 3)
        step = rng.choice((-1, 1))
        for i in range(rng.randint(2, h - 2)):
            px = cx + (i // 2) * step
            if x0 < px < x0 + w - 1:
                img.putpixel((px, y0 + 1 + i), (*crack, 255))


def grow_moss(img, rng, rects, mortar, moss_rgb, args):
    if args.moss <= 0:
        return
    allowed = set()
    for x0, y0, w, h in rects:
        for y in range(y0 - 1, y0 + min(h, 3)):
            for x in range(x0, x0 + w):
                allowed.add((x, y))
    tops = [(x, y0) for x0, y0, w, h in rects for x in range(x0, x0 + w)]
    light = blend(mortar, moss_rgb, args.highlight_blend)
    dark = blend(mortar, moss_rgb, args.stone_blend * 1.4)
    for _ in range(int(len(tops) * args.moss * 0.08)):
        frontier = [rng.choice(tops)]
        for _ in range(rng.randint(2, 7)):
            if not frontier:
                break
            x, y = frontier.pop(rng.randrange(len(frontier)))
            img.putpixel((x, y), (*(light if rng.random() < 0.4 else dark), 255))
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if (nx, ny) in allowed:
                    frontier.append((nx, ny))


def procedural(args, palette):
    mortar = hex_to_rgb(palette[args.mortar])
    ember = hex_to_rgb(palette[args.accent])
    moss_rgb = hex_to_rgb(palette[args.moss_slot])
    rng = random.Random(args.seed)
    img = Image.new("RGBA", (PROC_N, PROC_N), (*mortar, 255))
    rects = procedural_rects(rng)
    for rect in rects:
        shade_stone(img, rng, rect, mortar, ember, args)
    grow_moss(img, rng, rects, mortar, moss_rgb, args)
    return img


def paste(canvas, block, ox, oy):
    for y in range(8):
        for x in range(8):
            canvas.putpixel((ox + x, oy + y), (*block[y][x], 255))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--palette", required=True, help="path to palette.json")
    parser.add_argument("--accent", default="base09", help="palette slot for the brick hue")
    parser.add_argument("--mortar", default="base00", help="palette slot for background/mortar")
    parser.add_argument("--stone-blend", type=float, default=0.20)
    parser.add_argument("--highlight-blend", type=float, default=0.45)
    parser.add_argument("--algorithm", choices=("sprite", "procedural"), default="sprite")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--roughness", type=float, default=0.5)
    parser.add_argument("--chipping", type=float, default=0.4)
    parser.add_argument("--moss", type=float, default=0.2)
    parser.add_argument("--moss-slot", default="base0B")
    parser.add_argument("--out", required=True)
    parser.add_argument(
        "--write-selection",
        help="also write the applied accent/blend params as JSON to this path, "
        "if its parent directory exists",
    )
    args = parser.parse_args()

    with open(args.palette) as f:
        palette = json.load(f)

    if args.algorithm == "procedural":
        procedural(args, palette).save(args.out)
    else:
        sprite(args, palette).save(args.out)

    if args.write_selection and os.path.isdir(os.path.dirname(args.write_selection)):
        with open(args.write_selection, "w") as f:
            json.dump(
                {
                    "algorithm": args.algorithm,
                    "accent": args.accent,
                    "stone_blend": args.stone_blend,
                    "highlight_blend": args.highlight_blend,
                    "seed": args.seed,
                    "roughness": args.roughness,
                    "chipping": args.chipping,
                    "moss": args.moss,
                },
                f,
                indent=2,
            )
            f.write("\n")


def sprite(args, palette):
    mortar = hex_to_rgb(palette[args.mortar])
    ember = hex_to_rgb(palette[args.accent])
    stone = blend(mortar, ember, args.stone_blend)
    highlight = blend(mortar, ember, args.highlight_blend)

    img = Image.new("RGBA", (N, N), (*mortar, 255))

    brick = brick_module(mortar, stone, highlight)

    paste(img, brick, 0, 0)
    paste(img, brick, N - B, 0)
    paste(img, brick, 0, N - B)
    paste(img, brick, N - B, N - B)

    paste(img, brick, B, 0)
    paste(img, brick, B + 8, 0)

    paste(img, brick, B, N - B)
    paste(img, brick, B + 8, N - B)

    paste(img, brick, 0, B)
    paste(img, brick, 0, B + 8)

    paste(img, brick, N - B, B)
    paste(img, brick, N - B, B + 8)

    # unused middle - fill with mortar so nothing looks broken if ever sampled
    for y in range(B, N - B):
        for x in range(B, N - B):
            img.putpixel((x, y), (*mortar, 255))

    return img


if __name__ == "__main__":
    main()
