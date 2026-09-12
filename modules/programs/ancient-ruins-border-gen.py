import sys

from PIL import Image

# Ancient Ruins palette (modules/themes/ancient-ruins.nix)
MORTAR = (0x1c, 0x1b, 0x1a)   # base00
STONE_A = (0x9d, 0x5d, 0x40)  # base09 terracotta
STONE_B = (0xc2, 0xb2, 0x80)  # base0F sand
SHADOW = (0x8c, 0x50, 0x4a)   # base08 redFade
HIGHLIGHT = (0xd4, 0xaf, 0x37)  # base0A paleGold
CREAM = (0xe3, 0xcb, 0xa5)    # base06

N = 32
B = 8  # border thickness in source pixels


def brick_module(alt, sun_fleck):
    """8x8 RGBA pixel block: a single beveled stone brick."""
    px = [[MORTAR for _ in range(8)] for _ in range(8)]
    base = STONE_B if alt else STONE_A
    for y in range(1, 7):
        for x in range(1, 7):
            px[y][x] = base
    # bevel: lighten top/left interior edge, darken bottom/right
    for x in range(1, 7):
        px[1][x] = HIGHLIGHT if x in (1, 2) else CREAM
    for x in range(2, 7):
        px[6][x] = SHADOW
    for y in range(2, 7):
        px[y][1] = CREAM
        px[y][6] = SHADOW
    if sun_fleck:
        px[3][3] = HIGHLIGHT
        px[3][4] = HIGHLIGHT
        px[4][3] = HIGHLIGHT
        px[4][4] = STONE_B if alt else STONE_A
    return px


def paste(canvas, block, ox, oy):
    for y in range(8):
        for x in range(8):
            canvas.putpixel((ox + x, oy + y), (*block[y][x], 255))


def main(out_path):
    img = Image.new("RGBA", (N, N), (*MORTAR, 255))

    corner_tl = brick_module(False, True)
    corner_tr = brick_module(True, True)
    corner_bl = brick_module(True, True)
    corner_br = brick_module(False, True)

    edge_top_a = brick_module(False, False)
    edge_top_b = brick_module(True, False)
    edge_bottom_a = brick_module(True, False)
    edge_bottom_b = brick_module(False, False)
    edge_left_a = brick_module(True, False)
    edge_left_b = brick_module(False, False)
    edge_right_a = brick_module(False, False)
    edge_right_b = brick_module(True, False)

    paste(img, corner_tl, 0, 0)
    paste(img, corner_tr, N - B, 0)
    paste(img, corner_bl, 0, N - B)
    paste(img, corner_br, N - B, N - B)

    paste(img, edge_top_a, B, 0)
    paste(img, edge_top_b, B + 8, 0)

    paste(img, edge_bottom_a, B, N - B)
    paste(img, edge_bottom_b, B + 8, N - B)

    paste(img, edge_left_a, 0, B)
    paste(img, edge_left_b, 0, B + 8)

    paste(img, edge_right_a, N - B, B)
    paste(img, edge_right_b, N - B, B + 8)

    # unused middle - fill with mortar so nothing looks broken if ever sampled
    for y in range(B, N - B):
        for x in range(B, N - B):
            img.putpixel((x, y), (*MORTAR, 255))

    img.save(out_path)


if __name__ == "__main__":
    main(sys.argv[1])
