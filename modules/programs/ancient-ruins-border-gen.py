import argparse
import json
import os

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


def write_live_lua(path, args, palette):
    params = {
        "mode": "procedural" if args.algorithm == "procedural" else "image",
        "seed": args.seed,
        "roughness": args.roughness,
        "chipping": args.chipping,
        "moss": args.moss,
        "stone_blend": args.stone_blend,
        "highlight_blend": args.highlight_blend,
        "color_mortar": palette[args.mortar],
        "color_accent": palette[args.accent],
        "color_moss": palette[args.moss_slot],
    }
    body = "".join(f"  {k} = {json.dumps(v)},\n" for k, v in params.items())
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write("return {\n" + body + "}\n")
    os.replace(tmp, path)


def autotile_quadrant_bit(x, y):
    north = y < 4
    west = x < 4
    return {(True, True): 8, (True, False): 4, (False, True): 2, (False, False): 1}[(north, west)]


def autotile_tile(tile, mortar, highlight):
    px = [[None for _ in range(8)] for _ in range(8)]
    holes = [(x, y) for y in range(8) for x in range(8) if not tile & autotile_quadrant_bit(x, y)]
    if not holes:
        return px
    convex = tile in (1, 2, 4, 8)
    for y in range(8):
        for x in range(8):
            if not tile & autotile_quadrant_bit(x, y):
                continue
            d = min(max(abs(x - hx), abs(y - hy)) for hx, hy in holes)
            if convex and x in (3, 4) and y in (3, 4):
                px[y][x] = mortar
            elif d == 1:
                px[y][x] = highlight
            elif d == 2:
                px[y][x] = mortar
    return px


def autotile_sheet(args, palette):
    mortar = hex_to_rgb(palette[args.mortar])
    ember = hex_to_rgb(palette[args.accent])
    stone = blend(mortar, ember, args.stone_blend)
    highlight = blend(mortar, ember, args.highlight_blend)
    brick = brick_module(mortar, stone, highlight)
    sheet = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for tile in range(16):
        ox, oy = (tile % 4) * 8, (tile // 4) * 8
        block = brick if tile == 15 else autotile_tile(tile, mortar, highlight)
        for y in range(8):
            for x in range(8):
                if block[y][x] is not None:
                    sheet.putpixel((ox + x, oy + y), (*block[y][x], 255))
    return sheet


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
    parser.add_argument("--algorithm", choices=("sprite", "procedural", "autotile"), default="sprite")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--roughness", type=float, default=0.5)
    parser.add_argument("--chipping", type=float, default=0.4)
    parser.add_argument("--moss", type=float, default=0.2)
    parser.add_argument("--moss-slot", default="base0B")
    parser.add_argument("--out", required=True)
    parser.add_argument("--sheet-out", help="also write the 16-tile dual-grid autotile sheet here")
    parser.add_argument("--live-lua", help="write plugin params as a Lua table to this path")
    parser.add_argument(
        "--write-selection",
        help="also write the applied accent/blend params as JSON to this path, "
        "if its parent directory exists",
    )
    args = parser.parse_args()

    with open(args.palette) as f:
        palette = json.load(f)

    if args.algorithm == "autotile":
        Image.new("RGBA", (N, N), (0, 0, 0, 0)).save(args.out)
    else:
        sprite(args, palette).save(args.out)

    if args.sheet_out:
        autotile_sheet(args, palette).save(args.sheet_out)

    if args.live_lua:
        write_live_lua(args.live_lua, args, palette)

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
