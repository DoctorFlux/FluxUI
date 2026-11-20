"""Offline raster regressions for fixed border weights, sampling guards and joins."""
from pathlib import Path
import math
import sys
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/"tools"))
from build_border_art import SLOTS, junction_art
checks=0
def check(ok, message):
    global checks
    checks+=1
    assert ok,message

def sample(im,x,y):
    """Bilinear GPU-style texel-center sampling in pixel coordinates."""
    ix,iy=math.floor(x),math.floor(y);fx,fy=x-ix,y-iy
    out=[0.,0.,0.,0.]
    for dx,dy,w in ((0,0,(1-fx)*(1-fy)),(1,0,fx*(1-fy)),(0,1,(1-fx)*fy),(1,1,fx*fy)):
        c=im.getpixel((max(0,min(im.width-1,ix+dx)),max(0,min(im.height-1,iy+dy))))
        for i,v in enumerate(c):out[i]+=v*w
    return tuple(round(v,5) for v in out)

sheet=Image.open(ROOT/"Texture/borders/ForeverMetal150.tga").convert("RGBA")
mask=Image.open(ROOT/"Texture/borders/ForeverMetal150Tint.tga").convert("RGBA")
original=Image.open(ROOT/"Texture/BattlefieldMinimap.tga").convert("RGBA")
canonical=Image.open(ROOT/"Texture/borders/Battlefield100.tga").convert("RGBA")
for key,rect in SLOTS.items():check(canonical.crop(rect).tobytes()==original.crop(rect).tobytes(),(key,"type1 keeps every original artwork pixel; only gutters differ"))
check(sheet.size==(256,256),"unchanged canvas footprint")
check(mask.getchannel("A").tobytes()==sheet.getchannel("A").tobytes(),"identical natural/accent alpha")
check(all(r==g==b for r,g,b,a in mask.get_flattened_data()),"neutral tint mask")
for name,rect in SLOTS.items():
    part=sheet.crop(rect)
    check(sum(a>220 and r>g*1.2 and g>b*1.2 for r,g,b,a in part.get_flattened_data())>5,(name,"native gold bevel"))
    check(any(a==0 for r,g,b,a in part.get_flattened_data()),(name,"transparent padding"))
for cap,v,h,row,col in (("TL","Left","Top",16,15),("TR","Right","Top",16,0),("BL","Left","Bottom",0,15),("BR","Right","Bottom",0,0)):
    c,vp,hp=(sheet.crop(SLOTS[k]) for k in (cap,v,h))
    ey=vp.height-1 if cap.startswith("B") else 0;ex=hp.width-1 if cap.endswith("R") else 0
    check([c.getpixel((x,row)) for x in range(c.width)]==[vp.getpixel((x,ey)) for x in range(vp.width)],(cap,"RGBA vertical join"))
    check([c.getpixel((col,y)) for y in range(c.height)]==[hp.getpixel((ex,y)) for y in range(hp.height)],(cap,"RGBA horizontal join"))
    # Native filtering sees gutter texels, not only the cropped last/first rows.
    cx,cy=SLOTS[cap][:2];vx,vy=SLOTS[v][:2];hx,hy=SLOTS[h][:2]
    for phase in (0,.125,.25,.5,.75,1):
        for x in range(1,15):
            a=sample(sheet,cx+x,cy+row+(-phase if cap.startswith("B") else phase))
            b=sample(sheet,vx+x,vy+ey+(phase if cap.startswith("B") else -phase))
            check(a==b,(cap,"bilinear vertical seam",phase,x))
        for y in range(1,min(c.height,hp.height)-1):
            a=sample(sheet,cx+col+(-phase if cap.endswith("R") else phase),cy+y)
            b=sample(sheet,hx+ex+(phase if cap.endswith("R") else -phase),hy+y)
            check(a==b,(cap,"bilinear horizontal seam",phase,y))
for key in ("Top","Bottom","Left","Right"):
    profiles=[]
    for canvas in (original,sheet):
        p=canvas.crop(SLOTS[key]);horizontal=key in ("Top","Bottom")
        profiles.append([i for i in range(p.height if horizontal else p.width) if (lambda c:c[3]>150 and max(c[:3])>20)(p.getpixel((100,i) if horizontal else(i,60)))])
    boundary=min if key in ("Top","Left") else max
    check(boundary(profiles[0])==boundary(profiles[1]),(key,"same outward padding as type 1",profiles))
for name in ("Preview1","Preview2","Preview2Tint"):
    p=Image.open(ROOT/("Texture/borders/"+name+".tga")).convert("RGBA")
    check(p.size==(256,64),(name,"full preview canvas"))
    # A complete rectangle has visible colored stroke on both ends and both rows.
    for box in ((0,8,32,56),(224,8,256,56),(16,0,240,24),(16,40,240,64)):
        check(any(max(r,g,b)>35 for r,g,b,a in p.crop(box).get_flattened_data()),(name,"complete silhouette",box))
for number,canvas in ((1,original),(2,sheet)):
    current=Image.open(ROOT/("Texture/borders/JunctionWide%d.tga"%number)).convert("RGBA")
    expected,tracks=junction_art(canvas)
    check(current.tobytes()==expected.tobytes(),"every T/X uses a single union of the original profiles")
    for index in range(20):
        x,y=(index%5)*64+16,(index//5)*64+16
        patch=current.crop((x,y,x+32,y+32))
        check(any(a>200 for r,g,b,a in patch.get_flattened_data()),(number,index,"junction stroke"))
        for i in range(32):
            check(current.getpixel((x-1,y+i))==current.getpixel((x,y+i)),"left branch sampling guard")
            check(current.getpixel((x+32,y+i))==current.getpixel((x+31,y+i)),"right branch sampling guard")
            check(current.getpixel((x+i,y-1))==current.getpixel((x+i,y)),"top branch sampling guard")
            check(current.getpixel((x+i,y+32))==current.getpixel((x+i,y+31)),"bottom branch sampling guard")
    if number==2:
        tint=Image.open(ROOT/"Texture/borders/JunctionWide2Tint.tga").convert("RGBA")
        check(tint.getchannel("A").tobytes()==current.getchannel("A").tobytes(),"junction tint geometry identical")
# The runtime's finite endpoint fields stay inside these duplicated texels.
# This checks RGBA parity against the former constant sample at every normal
# source row/column, including bilinear phases and both source endpoints.
for name,canvas in (("type1",canonical),("type2",sheet),("type2Tint",mask)):
    for key in ("Top","Bottom","Left","Right"):
        x,y,right,bottom=SLOTS[key];horizontal=key in ("Top","Bottom")
        normal=(bottom-y) if horizontal else (right-x)
        for row in range(normal+1):
            for endpoint,sign in (((x if horizontal else y)-.5,-1),((right if horizontal else bottom)-.5,1)):
                fixed=sample(canvas,endpoint,y-.5+row) if horizontal else sample(canvas,x-.5+row,endpoint)
                for phase in (.125,.25,.5):
                    finite=sample(canvas,endpoint+sign*phase,y-.5+row) if horizontal else sample(canvas,x-.5+row,endpoint+sign*phase)
                    if row in (0,normal):
                        check(all(abs(a-b)<=.25 for a,b in zip(finite,fixed)),(name,key,"finite gutter fringe changes at most a quarter alpha unit",row,phase))
                    else:
                        check(finite==fixed,(name,key,"finite gutter sample preserves exact core RGBA",row,phase))
print(f"Border art: {checks} raster checks PASS; fixed 150% gold, identical outward padding, filtered seams, full previews and 40 T/X variants. Native GPU/UI-scale acceptance pending.")
