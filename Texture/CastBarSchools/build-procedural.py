"""Build portable UI particles and hybrid fill masks without external libraries."""
import argparse
import binascii
import math
from pathlib import Path
import struct
import zlib

SIZE = 128


def distance(x, y, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((x - a[0]) * dx + (y - a[1]) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - a[0] - t * dx, y - a[1] - t * dy)


def bolt(x, y):
    points = [(9, 84), (38, 63), (30, 49), (62, 59), (76, 35), (87, 48), (119, 26)]
    branches = [(points[2], (18, 28)), (points[4], (68, 17)), (points[3], (92, 89))]
    dist = min(distance(x, y, a, b) for a, b in list(zip(points, points[1:])) + branches)
    alpha = min(1, math.exp(-dist * dist / 5) + 0.3 * math.exp(-dist * dist / 75))
    return 255, round(255 * alpha)



def volcanic_rock(x, y):
    vertices = [(30, 39), (67, 20), (104, 47), (94, 92), (56, 109), (23, 77)]
    edges = list(zip(vertices, vertices[1:] + vertices[:1]))
    if any((b[0]-a[0])*(y-a[1]) - (b[1]-a[1])*(x-a[0]) < 0 for a, b in edges):
        return 0, 0
    alpha = min(1, min(distance(x, y, a, b) for a, b in edges) / 1.4)
    # Three solid facets, tinted brown by the renderer rather than glowing white.
    shade = .92 if x < 61 and y < 76 else .67 if y < 64 + .35 * (x-64) else .48
    return round(255 * shade), round(255 * alpha)


def hybrid_weights(x, y, count):
    # The entire texture stretches over the CURRENT fill, not the full bar.
    # Every fill length gets the complete palette, with curved soft transitions
    # instead of independently sized rectangular segments or thin stripes.
    x, y = x / SIZE, y / SIZE
    warp = 0.16 * math.sin(2 * math.pi * (y * 0.70 + 0.10))
    x = max(0, min(1, x + warp * math.sin(math.pi * x)))
    position = x * (count - 1)
    stop = min(count - 2, int(position))
    mix = position - stop
    mix = mix * mix * (3 - 2 * mix)
    weights = [0.0] * count
    weights[stop], weights[stop + 1] = 1 - mix, mix
    return weights


def hybrid_mask(count, layer):
    def pixel(x, y):
        weights = hybrid_weights(x, y, count)
        below = sum(weights[:layer + 1])
        # Ordinary alpha compositing must reproduce the intended weights,
        # rather than dimming earlier colors with every additional layer.
        alpha = weights[layer] / below if below > 0 else 0
        shade = 0.82 + 0.18 * math.sin(math.pi * y / SIZE)
        return round(255 * shade), round(255 * alpha)
    return pixel


def hybrid_base(x, y):
    return round(255 * (0.82 + 0.18 * math.sin(math.pi * y / SIZE))), 255


def pixels(fn):
    result = bytearray()
    for y in range(SIZE):
        for x in range(SIZE):
            value, alpha = fn(x + 0.5, y + 0.5)
            result.extend((value, value, value, alpha))
    return result


def write_tga(path, rgba):
    header = bytearray(18)
    header[2] = 2
    struct.pack_into("<HH", header, 12, SIZE, SIZE)
    header[16:18] = bytes((32, 40))
    # Glyphs are grayscale; RGBA and BGRA bytes are identical.
    path.write_bytes(header + rgba)


def preview(path, glyphs):
    width, height = SIZE * len(glyphs), SIZE
    rows = []
    for y in range(height):
        row = bytearray(b"\0")
        for glyph in glyphs:
            for x in range(SIZE):
                i = (y * SIZE + x) * 4
                value, alpha = glyph[i], glyph[i + 3]
                color = (value * alpha + 24 * (255 - alpha)) // 255
                row.extend((color, color, color, 255))
        rows.append(row)
    write_png(path, width, height, rows)


def write_png(path, width, height, rows):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", binascii.crc32(kind + data) & 0xffffffff)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(b"".join(rows))) + chunk(b"IEND", b""))


def hybrid_preview(path):
    # Composite the actual packaged mask pixels at several fill lengths.
    palettes = [[(1, .62, .12), (.55, .86, 1)],
                [(1, .62, .12), (.55, .86, 1), (.56, .95, .30)],
                [(1, .62, .12), (.55, .86, 1), (1, .50, .92), (.42, .20, .55), (1, .95, .66), (.56, .95, .30)]]
    width, height = 400, 354
    canvas = [bytearray((18, 21, 27, 255) * width) for _ in range(height)]
    for group, colors in enumerate(palettes):
        masks = [pixels(hybrid_base)] + [pixels(hybrid_mask(len(colors), i)) for i in range(1, len(colors))]
        for row, fill_width in enumerate((360, 140, 24)):
            for y in range(26):
                for x in range(fill_width):
                    mx, my = min(SIZE - 1, int(x / fill_width * SIZE)), int(y / 26 * SIZE)
                    offset = (my * SIZE + mx) * 4
                    color = [0., 0., 0.]
                    for tint, mask in zip(colors, masks):
                        alpha, shade = mask[offset + 3] / 255, mask[offset] / 255
                        for channel in range(3):
                            color[channel] = color[channel] * (1 - alpha) + tint[channel] * shade * alpha
                    at = (20 + x) * 4
                    canvas[12 + group * 116 + row * 34 + y][at:at + 4] = bytes([round(c * 255) for c in color] + [255])
    write_png(path, width, height, [b"\0" + row for row in canvas])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path)
    parser.add_argument("--hybrid-preview", type=Path)
    args = parser.parse_args()
    glyphs = []
    for name, fn in (("lightning_bolt", bolt), ("volcanic_rock", volcanic_rock)):
        rgba = pixels(fn)
        write_tga(Path(__file__).parent / (name + ".tga"), rgba)
        glyphs.append(rgba)
    if args.preview:
        preview(args.preview, glyphs)
    write_tga(Path(__file__).parent / "hybrid_base.tga", pixels(hybrid_base))
    for count in range(2, 7):
        for layer in range(1, count):
            write_tga(Path(__file__).parent / f"hybrid_{count}_{layer + 1}.tga", pixels(hybrid_mask(count, layer)))
    if args.hybrid_preview:
        hybrid_preview(args.hybrid_preview)
