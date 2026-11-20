-- A nearby divider must not replace an unrelated outer L with straight-edge
-- artwork. Exercise the production renderer using the shared factory's caps.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local prefix=assert(read("tests/border_junctions.lua"):match("^(.-)local J=fixture%(%)"))
local fixture=assert(load(prefix.."\nreturn fixture","@cap-junction-fixture","t",_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function clip(poly,axis,bound,above)
 local out={};local old=poly[#poly]
 for _,p in ipairs(poly)do
  local a=above and old[axis]>=bound or not above and old[axis]<=bound
  local b=above and p[axis]>=bound or not above and p[axis]<=bound
  if a~=b then local t=(bound-old[axis])/(p[axis]-old[axis]);out[#out+1]={old[1]+t*(p[1]-old[1]),old[2]+t*(p[2]-old[2])}end
  if b then out[#out+1]=p end;old=p
 end
 return out
end
local function overlapArea(t,op,r)
 local poly={}
 for _,v in ipairs({t.a,t.b,t.c})do poly[#poly+1]={op.rect[1]+v[1]*(op.rect[3]-op.rect[1]),op.rect[4]-v[2]*(op.rect[4]-op.rect[2])}end
 for _,cut in ipairs({{1,r[1],true},{1,r[3],false},{2,r[2],true},{2,r[4],false}})do
  if #poly==0 then return 0 end;poly=clip(poly,table.unpack(cut))
 end
 local area=0
 for i=2,#poly-1 do area=area+math.abs((poly[i][1]-poly[1][1])*(poly[i+1][2]-poly[1][2])-(poly[i][2]-poly[1][2])*(poly[i+1][1]-poly[1][1]))/2 end
 return area
end
for _,style in ipairs({1,2})do for _,scale in ipairs({.75,1,1.25})do
 for _,height in ipairs({45,124})do for _,axis in ipairs({"H","V"})do for _,split in ipairs(axis=="H" and {15,21,25}or{15,21,25,80})do
  local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,"atlas")
  local root=new(e.UIParent);root.scale=scale;root.unit=height==45 and "targettarget" or "target"
  local host=new(root);host.scale=scale
  local rects={TL={-9,height-13,16,17},TR={77,height-13,16,17},BL={-9,-5,16,16},BR={77,-5,16,16},
   Top={7,height-13,70,17},Bottom={7,-5,70,16},Left={-9,11,16,height-24},Right={77,11,16,height-24}}
  local sources={}
  for _,key in ipairs({"TL","TR","BL","BR","Top","Bottom","Left","Right"})do sources[key]=piece(host,key,rects[key])end
  local divider=new(root);divider.scale=scale
  if axis=="H"then piece(divider,"Top",{.5,split-(style==1 and 9 or 8),85.5,17})
  else piece(divider,"Left",{split-(style==1 and 9 or 9.5),4,16,height-9})end
  flush()
  check(j.stats.fallback==nil and j.stats.operations>0,"compact split commits a real junction or shared-edge removal")
  if split~=80 then check(j.stats.triangles>0,"separate split endpoints retain real committed junction paint")end
  for _,o in ipairs(objects)do if o._junctionOp then
   local op=o._junctionOp
   for _,triangle in ipairs(op.triangles)do for _,v in ipairs({triangle.a,triangle.b,triangle.c})do
    local x=op.rect[1]+v[1]*(op.rect[3]-op.rect[1]);local y=op.rect[4]-v[2]*(op.rect[4]-op.rect[2])
    check(x>=-9*scale-1e-7 and x<=93*scale+1e-7 and y>=-5*scale-1e-7 and y<=(height+4)*scale+1e-7,
     "a short junction arm cannot leave a floating border beyond the complete outside caps")
   end end
  end end
  for _,key in ipairs({"TL","TR","BL","BR"})do
   check(sources[key]:GetAlpha()==1,"a close internal divider preserves each unrelated outside cap")
   local cap=rects[key];local r={cap[1]*scale,cap[2]*scale,(cap[1]+cap[3])*scale,(cap[2]+cap[4])*scale}
   for _,o in ipairs(objects)do if o._junctionOp then
    for _,triangle in ipairs(o._junctionOp.triangles)do
     check(overlapArea(triangle,o._junctionOp,r)<1e-7,"junction paint cannot stack a straight-edge field over a preserved outside cap")
    end
   end end
  end
  local solves,count=j.stats.solves,#objects
  for _=1,20 do sources.Left:SetVertexColor(.2,.6,1,1)end
  flush();check(j.stats.solves==solves and #objects==count,"recolor keeps the cap-safe topology static")
 end end end
end end
print("Cap-safe junctions: "..checks.." checks PASS; real compact outline/divider rendering; both styles and fractional scales; preserved outer shapes; no stacked cap/mesh area; native pixels pending")
