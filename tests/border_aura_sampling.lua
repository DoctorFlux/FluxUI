-- Canonical aura endpoint extensions must retain a nonzero UV area. Repeating
-- exactly one column/row degenerates the native triangle's texture mapping.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@aura-sampling-fixture','t',_G))()
local coords=assert(load(assert(read('FluxBorder.lua'):match('(local NORMALIZED_COORDS = {.-\n})'))..'\nreturn NORMALIZED_COORDS','@native-border-uv','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs({1,2})do for _,scale in ipairs({.75,1,1.25})do for _,nativeID in ipairs({false,true})do
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'class')
 local root=new(e.UIParent);root.unit='target';root.scale=scale
 local path='Interface\\AddOns\\_FluxUI\\Texture\\borders\\'..(style==1 and 'Battlefield100.tga'or'ForeverMetal150Tint.tga')
 local function box(x)
  local y,top,w=230.84004211426,293.84005737305,144.79716491699
  local p=new(root);p.scale=scale;p.strata='BACKGROUND';p._FluxBorderAuraPanel=true
  local rects={TL={x,top,16,17},TR={x+16+w,top,16,17},BL={x,y-16,16,16},BR={x+16+w,y-16,16,16},Top={x+16,top,w,17},Bottom={x+16,y-16,w,16},Left={x,y,16,top-y},Right={x+16+w,y,16,top-y}}
  for _,key in ipairs({'TL','TR','BL','BR','Top','Bottom','Left','Right'})do
   local t,r=piece(p,key,rects[key]);r.art=path
   t:SetTexture(nativeID and -9619 or path);t:SetTexCoord(table.unpack(coords[key]));t:SetVertexColor(.2,.6,1,.4)
  end
 end
 box(968.50158691406);box(1131.2987060547);flush()
 check(j.stats.fallback==nil,'canonical aura pair commits without fallback')
 local seen,quads,rightCrest=0,0,0
 for _,o in ipairs(objects)do if o._junctionOp and o._junctionOp.bits==11 then
  for _,t in ipairs(o._junctionOp.triangles)do
   local a,b,c=t.a,t.b,t.c
   local uvArea=(b[3]-a[3])*(c[4]-a[4])-(b[4]-a[4])*(c[3]-a[3])
   check(math.abs(uvArea)>1e-12,'every visible aura T triangle has a non-degenerate texture mapping, including repeated endpoint fields')
   seen=seen+1
  end
 end end
 check(seen>0,'actual native-coordinate middle T was sampled')
 for _,o in ipairs(objects)do if o._junctionOwnerOp and o._junctionOwnerOp.bits==11 and o._junctionQuad then
  quads=quads+1
  for _,offset in pairs(o.vertices)do check(offset[1]==0 and offset[2]==0,'rectangular aura spans use an ordinary quad without displaced/degenerate vertices')end
  local op=o._junctionOwnerOp;local p=o:GetParent();local z=p:GetEffectiveScale()
  local x,y=(p:GetLeft()+o.point[4])*z,(p:GetBottom()+o.point[5])*z
  local px,py=op.x+3*scale,op.y-.2*scale
  if px>x and px<x+o.size[1]*z and py>y and py<y+o.size[2]*z then rightCrest=rightCrest+1 end
 end end
 check(quads>0,'exposed aura top has actual native rectangle primitives, not only a model triangle plan')
 check(rightCrest==1,'the reported missing span right of the middle divider has exactly one ordinary rectangle primitive')
 local solves,count=j.stats.solves,#objects
 for _=1,50 do root:SetAlpha(1)end;flush()
 check(j.stats.solves==solves and #objects==count,'finite sampling adds no idle layout work or resources')
end end end
print('Aura UV sampling: '..checks..' checks PASS; real canonical UVs/native rectangles; paths and negative client IDs; both styles/scales; nonsingular endpoint fields; static reuse; native GPU acceptance pending')
