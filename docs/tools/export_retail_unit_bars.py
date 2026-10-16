"""Export Flux's standalone Retail HUD fills from Blizzard's uncompressed BLP2.

Usage: python docs/tools/export_retail_unit_bars.py UIUnitFrame2x.blp
Input: FileDataID 4642466, Retail 12.1.0.69299. Rectangles are the matching
UiTextureAtlasMember records, atlas ID 2074. No third-party packages required.
"""

import argparse
import hashlib
import math
from pathlib import Path
import struct


SOURCE_SHA256 = "59ebc8aa04bf77b6ba17778b3135f31fa034355b56755f7cd93ba67968a7cc9f"
# name: (left, top, right, bottom), excluding adjacent sheet sprites/padding.
RECTS = {
    "Health": (1101, 361, 1349, 401),
    "Mana": (637, 501, 885, 521),
    "ManaStatus": (887, 501, 1135, 521),
    "Energy": (1667, 479, 1915, 499),
    "Focus": (387, 501, 635, 521),
    "Rage": (1137, 501, 1385, 521),
    "RunicPower": (1387, 501, 1635, 521),
    "ClassResourceMana": (387, 523, 635, 543),
    "ClassResourceEnergy": (1637, 501, 1885, 521),
}


def export(sheet, width, rect, dest):
    left, top, right, bottom = rect
    sw, sh = right - left, bottom - top
    # Full-image UVs, power-of-two dimensions: the StatusBar engine can freely
    # update its fill coordinates without ever exposing the original sheet.
    dw, dh = 1 << (sw - 1).bit_length(), 1 << (sh - 1).bit_length()
    pixels = bytearray()
    for y in range(dh):
        sy = max(0, min(sh - 1, (y + 0.5) * sh / dh - 0.5))
        y0 = math.floor(sy)
        fy = sy - y0
        for x in range(dw):
            sx = max(0, min(sw - 1, (x + 0.5) * sw / dw - 0.5))
            x0 = math.floor(sx)
            fx = sx - x0
            color = [0.0] * 4
            for dy, wy in ((0, 1 - fy), (1, fy)):
                for dx, wx in ((0, 1 - fx), (1, fx)):
                    offset = ((top + min(sh - 1, y0 + dy)) * width
                              + left + min(sw - 1, x0 + dx)) * 4
                    bgra = sheet[offset:offset + 4]
                    weight = wy * wx
                    alpha = bgra[3]
                    for channel in range(3):
                        color[channel] += bgra[channel] * alpha * weight
                    color[3] += alpha * weight
            alpha = color[3]
            pixels.extend(round(color[i] / alpha) if alpha else 0 for i in range(3))
            pixels.append(round(alpha))
    # Uncompressed BGRA TGA, top-left origin, eight alpha bits.
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, dw, dh, 32, 0x28)
    dest.write_bytes(header + pixels)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sheet", type=Path)
    parser.add_argument("--output", type=Path,
                        default=Path(__file__).resolve().parents[2] / "Media/UnitFrames/Retail")
    args = parser.parse_args()
    data = args.sheet.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_SHA256:
        parser.error("wrong sheet version; use the documented Retail build and FileDataID")
    magic, kind, encoding, alpha_depth, alpha_enc, mips, width, height = struct.unpack_from("<4sI4BII", data)
    assert (magic, kind, encoding, alpha_depth, width, height) == (b"BLP2", 1, 3, 8, 2048, 1024)
    offset = struct.unpack_from("<I", data, 20)[0]
    sheet = data[offset:offset + width * height * 4]
    assert len(sheet) == width * height * 4
    args.output.mkdir(parents=True, exist_ok=True)
    for name, rect in RECTS.items():
        export(sheet, width, rect, args.output / (name + ".tga"))
    print("Exported", len(RECTS), "Retail HUD fills to", args.output)


if __name__ == "__main__":
    main()
