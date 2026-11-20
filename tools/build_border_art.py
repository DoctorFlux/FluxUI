"""Normalize extracted Forever chrome into FluxBorder's established eight-piece canvas.

Requires Pillow for this offline build only. Source PNGs must come from the local
Forever build, using the file IDs/rectangles in docs/validation/border-types-2026-11-15.json.
No complete native window, portrait, title strip or background is packaged.
"""
from pathlib import Path
import argparse
import hashlib
import json

from PIL import Image, ImageOps, ImageDraw, ImageChops


SLOTS = {
    "TL": (211, 1, 227, 18), "TR": (229, 1, 245, 18),
    "BL": (211, 20, 227, 36), "BR": (229, 20, 245, 36),
    "Top": (1, 1, 209, 18), "Bottom": (1, 20, 209, 36),
    "Left": (1, 38, 17, 172), "Right": (19, 38, 35, 172),
}


def build(source):
    corners = Image.open(source / "Forever-8069116.png").convert("RGBA")
    horizontal = Image.open(source / "Forever-8069118.png").convert("RGBA")
    vertical = Image.open(source / "Forever-8069114.png").convert("RGBA")
    # DB2 UiTextureAtlasMember 38773/38774/38780/38771/38772, c60-2x.
    bl = corners.crop((1, 1, 191, 201))
    br = corners.crop((1, 203, 191, 403))
    bottom = horizontal.crop((0, 1, 256, 201))
    left = vertical.crop((1, 0, 191, 256))
    right = vertical.crop((193, 0, 383, 256))
    # One uniform 2x -> 1x reduction across caps and perpendicular edge axes.
    # Source padding is discarded; the visible stroke is aligned to type 1's
    # left/right/top/bottom tracks (8.5/9.5/8.5/7.5 in their respective cells).
    resample = Image.Resampling.LANCZOS
    pieces = {
        "BL": bl.crop((14, 166, 46, 198)).resize((16, 16), resample),
        "BR": br.crop((160, 166, 192, 198)).resize((16, 16), resample),
        "Bottom": bottom.crop((0, 166, 256, 198)).resize((208, 16), resample),
        "Left": left.crop((14, 0, 46, 256)).resize((16, 134), resample),
        "Right": right.crop((160, 0, 192, 256)).resize((16, 134), resample),
    }
    # A bare bevel around small HUD panels: mirror the native bottom caps/edge
    # instead of shrinking the native title band into a tiny top border.
    for top, lower in (("TL", "BL"), ("TR", "BR"), ("Top", "Bottom")):
        im = ImageOps.flip(pieces[lower])
        pieces[top] = Image.new("RGBA", (im.width, 17))
        pieces[top].paste(im, (0, 1))
    # Shared joins must sample identical edge profiles, including alpha/shadow.
    for corner, vertical_key, horizontal_key, row, col in (
        ("TL", "Left", "Top", 16, 15), ("TR", "Right", "Top", 16, 0),
        ("BL", "Left", "Bottom", 0, 15), ("BR", "Right", "Bottom", 0, 0),
    ):
        im = pieces[corner]
        vp = pieces[vertical_key]
        hp = pieces[horizontal_key]
        edge_x = hp.width - 1 if corner.endswith("R") else 0
        edge_y = vp.height - 1 if corner.startswith("B") else 0
        for x in range(im.width):
            im.putpixel((x, row), vp.getpixel((x, edge_y)))
        for y in range(im.height):
            im.putpixel((col, y), hp.getpixel((edge_x, y)))
    sheet = Image.new("RGBA", (256, 256))
    for name, rect in SLOTS.items():
        assert pieces[name].size == (rect[2] - rect[0], rect[3] - rect[1])
        sheet.paste(pieces[name], rect[:2])
    return sheet, pieces


def normalize_thickness(sheet, factor):
    """Change distance from the stroke center, keeping every cap/edge track fixed."""
    pieces = {}
    paths = {
        "TL": ((8.5,17), (8.5,10.5), (11.5,7.5), (16,7.5)),
        "TR": ((0,7.5), (6,7.5), (9,10.5), (9,17)),
        "BL": ((8.5,0), (8.5,4.5), (11.5,7.5), (16,7.5)),
        "BR": ((0,7.5), (6,7.5), (9,4.5), (9,0)),
    }
    for key, rect in SLOTS.items():
        source = sheet.crop(rect)
        if key in ("Top", "Bottom"):
            pivot = 7.5
            matrix = (1, 0, 0, 0, 1/factor, pivot-pivot/factor)
            pieces[key] = source.transform(source.size, Image.Transform.AFFINE, matrix, Image.Resampling.BICUBIC)
        elif key in ("Left", "Right"):
            pivot = 8.5 if key == "Left" else 9
            matrix = (1/factor, 0, pivot-pivot/factor, 0, 1, 0)
            pieces[key] = source.transform(source.size, Image.Transform.AFFINE, matrix, Image.Resampling.BICUBIC)
        else:
            # Project onto the fixed chamfer centerline, then resample only the
            # normal distance. Scaling the whole cap would move its edge joins.
            src = source.convert("RGBa")
            out = Image.new("RGBA", source.size)
            segments = tuple(zip(paths[key], paths[key][1:]))
            for y in range(out.height):
                for x in range(out.width):
                    nearest = None
                    for (ax,ay),(bx,by) in segments:
                        dx,dy = bx-ax,by-ay
                        t = max(0,min(1,((x-ax)*dx+(y-ay)*dy)/(dx*dx+dy*dy)))
                        px,py = ax+t*dx,ay+t*dy
                        distance = (x-px)**2+(y-py)**2
                        if nearest is None or distance < nearest[0]: nearest = (distance,px,py)
                    _,px,py = nearest
                    sx,sy = px+(x-px)/factor,py+(y-py)/factor
                    ix,iy = int(sx//1),int(sy//1)
                    fx,fy = sx-ix,sy-iy
                    values = [0.,0.,0.,0.]
                    for ox,oy,w in ((0,0,(1-fx)*(1-fy)),(1,0,fx*(1-fy)),(0,1,(1-fx)*fy),(1,1,fx*fy)):
                        if 0 <= ix+ox < src.width and 0 <= iy+oy < src.height:
                            for c,v in enumerate(src.getpixel((ix+ox,iy+oy))): values[c] += v*w
                    alpha = round(values[3])
                    rgb = tuple(min(255,round(v*255/values[3])) if values[3] else 0 for v in values[:3])
                    out.putpixel((x,y),rgb+(alpha,))
            pieces[key] = out
    # Outer padding samples must stay transparent even at 200%; otherwise a
    # stretched shadow can touch a neighbouring atlas cell or disagree at the
    # single pixel where a cap meets both straight-edge profiles.
    for key in ("Top", "Bottom"):
        im = pieces[key]
        for x in range(im.width):
            im.putpixel((x,0),(0,0,0,0)); im.putpixel((x,im.height-1),(0,0,0,0))
    for key in ("Left", "Right"):
        im = pieces[key]
        for y in range(im.height):
            im.putpixel((0,y),(0,0,0,0)); im.putpixel((im.width-1,y),(0,0,0,0))
    for cap,vertical,horizontal,row,col in (
        ("TL","Left","Top",16,15),("TR","Right","Top",16,0),
        ("BL","Left","Bottom",0,15),("BR","Right","Bottom",0,0),
    ):
        im,vp,hp = pieces[cap],pieces[vertical],pieces[horizontal]
        ey = vp.height-1 if cap.startswith("B") else 0
        ex = hp.width-1 if cap.endswith("R") else 0
        for x in range(im.width): im.putpixel((x,row),vp.getpixel((x,ey)))
        for y in range(im.height): im.putpixel((col,y),hp.getpixel((ex,y)))
    result = Image.new("RGBA",sheet.size)
    for key,rect in SLOTS.items(): result.paste(pieces[key],rect[:2])
    return result


def align_gold_padding(sheet):
    # Match the actual visible type-1 stroke tracks, not merely its cell bounds.
    # Measured bright core centers from the original packed battlefield pixels:
    # Top/Bottom 7.5, Left 8.5; right outer core ends at pixel 10.
    # Preserve each side's outward padding even where type 1 has a wider highlight.
    result = Image.new("RGBA", sheet.size)
    shifts = {"TL":(1,-2), "TR":(.5,-2), "BL":(1,1), "BR":(.5,1),
              "Top":(0,-2), "Bottom":(0,1), "Left":(1,0), "Right":(.5,0)}
    for key,rect in SLOTS.items():
        dx,dy = shifts[key]
        part = sheet.crop(rect).convert("RGBa")
        part = part.transform(part.size, Image.Transform.AFFINE, (1,0,-dx,0,1,-dy), Image.Resampling.BICUBIC).convert("RGBA")
        result.paste(part,rect[:2])
    return result


def panel(sheet, width, height, tint=(255, 255, 255)):
    """Software composition of the production padding/anchor contract, for QA."""
    im = Image.new("RGBA", (width + 32, height + 32), (20, 20, 20, 255))
    x, y = 16, 16
    rects = {"TL": (x-11, y-6, 16, 17), "TR": (x+width+7-16, y-6, 16, 17),
             "BL": (x-11, y+height+7-16, 16, 16), "BR": (x+width+7-16, y+height+7-16, 16, 16)}
    rects.update(Top=(x+5, y-6, width-14, 17), Bottom=(x+5, y+height-9, width-14, 16),
                 Left=(x-11, y+11, 16, height-20), Right=(x+width-9, y+11, 16, height-20))
    for key, (px, py, w, h) in rects.items():
        part = sheet.crop(SLOTS[key]).resize((w, h), Image.Resampling.BILINEAR)
        if tint != (255, 255, 255):
            channels = part.split()
            part = Image.merge("RGBA", tuple(channels[i].point(lambda v, i=i: v*tint[i]//255) for i in range(3)) + (channels[3],))
        im.alpha_composite(part, (px, py))
    return im


def fit_outer_padding(sheet, reference):
    shifts = {}
    for key in ("Top","Bottom","Left","Right"):
        profiles = []
        for canvas in (reference,sheet):
            part = canvas.crop(SLOTS[key]); horizontal = key in ("Top","Bottom")
            profiles.append([i for i in range(part.height if horizontal else part.width)
                if (lambda c:c[3]>150 and max(c[:3])>20)(part.getpixel((100,i) if horizontal else(i,60)))])
        boundary = min if key in ("Top","Left") else max
        shifts[key] = boundary(profiles[0])-boundary(profiles[1])
    result = Image.new("RGBA",sheet.size)
    for key,rect in SLOTS.items():
        dx = shifts.get(key,0) if key in ("Left","Right") else 0
        dy = shifts.get(key,0) if key in ("Top","Bottom") else 0
        if len(key)==2:
            dx = shifts["Left" if key.endswith("L") else "Right"]
            dy = shifts["Top" if key.startswith("T") else "Bottom"]
        part = sheet.crop(rect)
        part = part.transform(part.size,Image.Transform.AFFINE,(1,0,-dx,0,1,-dy),Image.Resampling.NEAREST)
        result.paste(part,rect[:2])
    # Reestablish exact seam profiles after moving thickness inward.
    for cap,v,h,row,col in (("TL","Left","Top",16,15),("TR","Right","Top",16,0),
                          ("BL","Left","Bottom",0,15),("BR","Right","Bottom",0,0)):
        c,vp,hp=(result.crop(SLOTS[k]) for k in (cap,v,h))
        ey=vp.height-1 if cap.startswith("B") else 0;ex=hp.width-1 if cap.endswith("R") else 0
        for x in range(c.width):c.putpixel((x,row),vp.getpixel((x,ey)))
        for y in range(c.height):c.putpixel((col,y),hp.getpixel((ex,y)))
        result.paste(c,SLOTS[cap][:2])
    return result


def junction_art(sheet):
    """Twenty T/X variants: two horizontal and two vertical bevel directions."""
    atlas = Image.new("RGBA",(512,256))
    tracks = {}
    profiles = {}
    for key in ("Top","Bottom","Left","Right"):
        part=sheet.crop(SLOTS[key]);horizontal=key in ("Top","Bottom")
        profile=[part.getpixel((100,i) if horizontal else(i,60)) for i in range(part.height if horizontal else part.width)]
        core=[i for i,c in enumerate(profile) if c[3]>150 and max(c[:3])>20]
        track=(min(core)+max(core)+1)/2
        tracks[key]=track
        strip=Image.new("RGBA",(1,len(profile)))
        for i,c in enumerate(profile):strip.putpixel((0,i),c)
        strip=strip.convert("RGBa").transform((1,32),Image.Transform.AFFINE,(1,0,0,0,1,track-16),Image.Resampling.BICUBIC).convert("RGBA")
        profiles[key]=[strip.getpixel((0,i)) for i in range(32)]
    for vi,vkey in enumerate(("Left","Right")):
        for hi,hkey in enumerate(("Top","Bottom")):
            for shape,bits in enumerate((7,11,13,14,15)):
                patch=Image.new("RGBA",(32,32))
                for y in range(32):
                    for x in range(32):
                        candidates=[]
                        if (x<16 and bits&1) or (x>=16 and bits&2):candidates.append(profiles[hkey][y])
                        if (y<16 and bits&4) or (y>=16 and bits&8):candidates.append(profiles[vkey][x])
                        if candidates:
                            # Union the bevels once; alpha never stacks at a junction.
                            rgb=max(candidates,key=lambda c:max(c[:3])*c[3])[:3]
                            patch.putpixel((x,y),rgb+(max(c[3] for c in candidates),))
                idx=shape+hi*5+vi*10;x0=(idx%5)*64+16;y0=(idx//5)*64+16
                atlas.paste(patch,(x0,y0))
                # Longitudinal guards for straight branch ends.
                atlas.paste(patch.crop((0,0,1,32)),(x0-1,y0))
                atlas.paste(patch.crop((31,0,32,32)),(x0+32,y0))
                atlas.paste(patch.crop((0,0,32,1)),(x0,y0-1))
                atlas.paste(patch.crop((0,31,32,32)),(x0,y0+32))
    return atlas,tracks


def extrude_seams(sheet):
    """Guard texels prevent bilinear sampling from fading at cap/edge joins."""
    result = sheet.copy()
    for key, (x0,y0,x1,y1) in SLOTS.items():
        horizontal = key in ("Top", "Bottom")
        vertical = key in ("Left", "Right")
        if horizontal or key.endswith("L"):
            for y in range(y0,y1): result.putpixel((x1,y),sheet.getpixel((x1-1,y)))
        if horizontal or key.endswith("R"):
            for y in range(y0,y1): result.putpixel((x0-1,y),sheet.getpixel((x0,y)))
        if vertical or key.startswith("T") and not horizontal:
            for x in range(x0,x1): result.putpixel((x,y1),sheet.getpixel((x,y1-1)))
        if vertical or key.startswith("B") and not horizontal:
            for x in range(x0,x1): result.putpixel((x,y0-1),sheet.getpixel((x,y0)))
    return result


def neutral(sheet):
    r,g,b,alpha = sheet.split()
    value = ImageChops.lighter(ImageChops.lighter(r,g),b)
    return Image.merge("RGBA",(value,value,value,alpha))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    native, _ = build(args.source_dir)
    sheet = normalize_thickness(align_gold_padding(native), .6)
    original = Image.open(Path(__file__).resolve().parent.parent / "Texture/BattlefieldMinimap.tga").convert("RGBA")
    sheet = extrude_seams(fit_outer_padding(sheet,original))
    accent = neutral(sheet)
    folder = args.output.parent
    folder.mkdir(parents=True, exist_ok=True)
    sheet.save(folder / "ForeverMetal150.tga", compression=None)
    accent.save(folder / "ForeverMetal150Tint.tga", compression=None)
    original = Image.open(Path(__file__).resolve().parent.parent / "Texture/BattlefieldMinimap.tga").convert("RGBA")
    extrude_seams(original).save(folder / "Battlefield100.tga",compression=None)
    for number,current in ((1,original),(2,sheet)):
        joins,tracks=junction_art(current)
        joins.save(folder / ("JunctionWide%d.tga"%number),compression=None)
        if number==2:neutral(joins).save(folder / "JunctionWide2Tint.tga",compression=None)
        print("tracks",number,tracks)
    # Complete, readable silhouettes in both the dropdown and its large tooltip.
    for name,current in (("Preview1",original),("Preview2",sheet),("Preview2Tint",accent)):
        preview = panel(current,224,32)
        preview.save(folder / (name+".tga"),compression=None)
    if args.preview:
        preview = Image.new("RGBA", (800, 380), (28,28,28,255))
        draw = ImageDraw.Draw(preview)
        draw.text((12,8), "Type 1: 100% / Type 2: Forever bevel at 150%", fill="white")
        for row,current in enumerate((original,sheet)):
            for col,tint in enumerate(((255,255,255),(70,190,240))):
                preview.alpha_composite(panel(accent if row==1 and col==1 else current,340,110,tint),(col*400+8,row*170+30))
        preview.convert("RGB").save(args.preview)
    print(json.dumps({"fixedWeights":{"1":100,"2":150}, "canvas":sheet.size, "slots":SLOTS},indent=2))


if __name__ == "__main__":
    main()
