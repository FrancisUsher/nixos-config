import sys

from PIL import Image

# Urth under a dying sun: stone should read as barely-lit shapes emerging
# from black, not sunlit brick. STONE/HIGHLIGHT are heavy blends of the
# background black toward a single warm ember hue (base09 terracotta from
# ancient-ruins.nix) - color, but very low-key. A second hue is deliberately
# left unused, reserved for a future vine tone.
MORTAR = (0x1c, 0x1b, 0x1a)  # base00 - background/mortar
EMBER = (0x9d, 0x5d, 0x40)   # base09 terracotta - reference hue, not used directly


def blend(c1, c2, t):
    return tuple(round(a + (b - a) * t) for a, b in zip(c1, c2))


STONE = blend(MORTAR, EMBER, 0.20)      # dark warm brown-black
HIGHLIGHT = blend(MORTAR, EMBER, 0.45)  # faint ember edge, still dark

N = 32
B = 8  # border thickness in source pixels


def brick_module():
    """8x8 RGBA pixel block: a single stone brick, barely lit from black."""
    px = [[MORTAR for _ in range(8)] for _ in range(8)]
    for y in range(1, 7):
        for x in range(1, 7):
            px[y][x] = STONE
    # faint bevel: a single highlighted pixel-line on the top/left edge,
    # nothing on the bottom/right (fades back to mortar/black)
    for x in range(1, 7):
        px[1][x] = HIGHLIGHT
    for y in range(2, 7):
        px[y][1] = HIGHLIGHT
    return px


def paste(canvas, block, ox, oy):
    for y in range(8):
        for x in range(8):
            canvas.putpixel((ox + x, oy + y), (*block[y][x], 255))


def main(out_path):
    img = Image.new("RGBA", (N, N), (*MORTAR, 255))

    brick = brick_module()

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
            img.putpixel((x, y), (*MORTAR, 255))

    img.save(out_path)


if __name__ == "__main__":
    main(sys.argv[1])
