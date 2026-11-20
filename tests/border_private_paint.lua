-- Native private paint stays on its original texture. Repeated private sinks
-- must not keep releasing/rebuilding the same already-retired mesh component.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@private-border-paint','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,managed in ipairs{false,true}do for _,style in ipairs({1,2})do for _,channel in ipairs({'alpha','color'})do
 local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
 local p=new(e.UIParent);p.unit='focus';p._FluxBorderStatic=channel=='color'
 local h,hr=piece(p,'Top',{0,-9,100,17});local v,vr=piece(p,'Left',{41,-40,16,80})
 local public,pr=piece(p,'Top',{0,11,100,17})
 if managed then for t,r in pairs{[h]=hr,[v]=vr,[public]=pr}do
  local path='Interface\\AddOns\\_FluxUI\\Texture\\borders\\'..(style==1 and'Battlefield100.tga'or'ForeverMetal150Tint.tga')
  r.art=path;r.artHandle=path;t:SetTexture(path)
 end end
 flush()
 local secret=setmetatable({}, {__eq=function()error('private value compared')end,__lt=function()error('private value ordered')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 local function paint()
  if channel=='alpha'then h:SetAlpha(secret)else h:SetVertexColor(secret,.2,.3,1)end
 end
 paint();flush()
 check(channel=='alpha'and rawequal(h:GetAlpha(),secret)or channel=='color'and h:GetAlpha()==1,'first private paint preserves the native source alpha')
 check(j.stats.triangles>0 and public:GetAlpha()==0,'public aura/unit branches stay connected while only the private source retires')
 local solves,reads,full,resources=j.stats.solves,j.stats.geometryReads,j.stats.fullInvalidations,#objects
 for _=1,100 do paint();flush()end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and j.stats.fullInvalidations==full and #objects==resources,
  'an already-private source cannot repeatedly invalidate/read/rebuild or allocate the connected HUD')
 for _=1,100 do
  -- Normal recolor can reset alpha to public1 before the same update reapplies
  -- its native private maximum. Only the final coalesced paint is authoritative.
  if channel=='alpha'then h:SetAlpha(1)else h:SetVertexColor(.2,.6,.9,1)end
  paint();flush()
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and j.stats.fullInvalidations==full,
  'transient public repaint followed by private paint cannot repeatedly recover/release the mesh')
 lock(true);for _=1,20 do paint();flush()end;lock(false)
 check(j.stats.solves==solves and j.stats.geometryReads==reads and j.stats.fullInvalidations==full,'repeated private paint stays retired during combat too')
 for _,t in ipairs(objects)do if t.decorative then
  check(not rawequal(t.alpha,secret),'opaque alpha is never copied into addon-created fragments or junctions')
  for _,v in ipairs(t.color)do check(not rawequal(v,secret),'opaque color is never copied into addon-created artwork')end
 end end
 h:SetVertexColor(.2,.6,.9,1);h:SetAlpha(1);flush()
 check(h:GetAlpha()==0 and j.stats.fallback==nil,'returning public paint reconnects once through the normal guarded path')
end end end
print('Private border paint: '..checks..' checks PASS; alpha/RGBA retirement once; repeated focus-style sinks0reads/solves/full requests; original opaque source preserved; no opaque value copied; combat deferral; native taint/FPS pending')
