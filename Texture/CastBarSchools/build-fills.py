"""Bake school-only color compositions offline: one draw per hybrid fill."""
import importlib.util
import math
from pathlib import Path
import struct
import subprocess
import sys

sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[2]
ART = Path(__file__).resolve().parent
WIDTH, HEIGHT = 128, 32

EXPORT = r'''
local ns={}
assert(loadfile("UnitFrames/FluxCastBarSchools.lua"))("_FluxUI",ns)
assert(loadfile("UnitFrames/FluxCastBarThemes.lua"))("_FluxUI",ns)
local seen={}
local profiles={"school","lightning","chaos","volcanic"}
for mask=2,127 do for _,profile in ipairs(profiles) do
    local theme=ns.CastBarThemes.ThemeForMask(mask,profile~="school" and profile or nil)
    if #theme.components>1 then
        local names,colors={},{}
        for _,component in ipairs(theme.components) do
            names[#names+1]=component.school
            colors[#colors+1]=table.concat(component.dark,",")..";"..table.concat(component.bright,",")
        end
        local key=table.concat(names,"_")
        if not seen[key] then print(key.."|"..table.concat(colors,"|"));seen[key]=true end
    end
end end
'''


def main():
    export = subprocess.run(["lua", "-"], input=EXPORT, cwd=ROOT, text=True, capture_output=True, check=True)
    spec = importlib.util.spec_from_file_location("school_art", ART / "build-procedural.py")
    art = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(art)
    output = ART / "Fills"
    output.mkdir(exist_ok=True)
    count = 0
    # Cache normalized geometry once per component count, shared by palettes.
    weights = {}
    for line in export.stdout.splitlines():
        name, *colors = line.split("|")
        colors = [tuple(tuple(map(float, endpoint.split(","))) for endpoint in color.split(";")) for color in colors]
        size = len(colors)
        if size not in weights:
            weights[size] = [art.hybrid_weights((x + .5) * art.SIZE / WIDTH, (y + .5) * art.SIZE / HEIGHT, size)
                             for y in range(HEIGHT) for x in range(WIDTH)]
        header = bytearray(18)
        header[2] = 2
        struct.pack_into("<HH", header, 12, WIDTH, HEIGHT)
        header[16:18] = bytes((32, 40))
        for flat in (False, True):
            pixels = bytearray()
            for index, contributions in enumerate(weights[size]):
                shade = .82 + .18 * math.sin(math.pi * (index // WIDTH + .5) / HEIGHT)
                progress = 1 if flat else (index % WIDTH + .5) / WIDTH
                rgb = [round(255 * shade * sum(weight * (dark[channel] + (bright[channel] - dark[channel]) * progress)
                                               for weight, (dark, bright) in zip(contributions, colors)))
                       for channel in range(3)]
                pixels.extend((rgb[2], rgb[1], rgb[0], 255))
            suffix = "_flat" if flat else ""
            (output / ("fill_base_" + name + suffix + ".tga")).write_bytes(header + pixels)
        count += 1
    print(f"Baked {count} base-school compositions with original gradient/flat palettes ({count*2} textures).")


if __name__ == "__main__":
    main()
