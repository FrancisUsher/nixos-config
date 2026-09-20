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
    parser.add_argument("--out", required=True)
    parser.add_argument(
        "--write-selection",
        help="also write the applied accent/blend params as JSON to this path, "
        "if its parent directory exists",
    )
    args = parser.parse_args()

    with open(args.palette) as f:
        palette = json.load(f)

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

    img.save(args.out)

    if args.write_selection and os.path.isdir(os.path.dirname(args.write_selection)):
        with open(args.write_selection, "w") as f:
            json.dump(
                {
                    "accent": args.accent,
                    "stone_blend": args.stone_blend,
                    "highlight_blend": args.highlight_blend,
                },
                f,
                indent=2,
            )
            f.write("\n")


if __name__ == "__main__":
    main()
