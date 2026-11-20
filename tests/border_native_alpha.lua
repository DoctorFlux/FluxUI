-- Pinned SimpleRegion.SetAlpha is AllowedWhenTainted for secret arguments.
-- Keep opaque opacity only in that native sink; never use it for topology/RGB.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@native-unit-alpha-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,managed in ipairs{false,true}do for _,style in ipairs({1,2})do for _,initialPrivate in ipairs({false,true})do
 local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
 local root=new(e.UIParent);root.unit='focus';root._FluxBorderStatic=true
 local h,hr=piece(root,'Top',{0,-9,100,17});local v,vr=piece(root,'Left',{41,-40,16,80})
 if managed then for t,r in pairs{[h]=hr,[v]=vr}do
  local path='Interface\\AddOns\\_FluxUI\\Texture\\borders\\'..(style==1 and'Battlefield100.tga'or'ForeverMetal150Tint.tga')
  r.art=path;r.artHandle=path;t:SetTexture(path)
 end end
 local secret=setmetatable({}, {__eq=function()error('opaque alpha compared')end,__lt=function()error('opaque alpha ordered')end,__le=function()error('opaque alpha ordered')end,__tostring=function()error('opaque alpha formatted')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 -- Model the Alpha aspect making all native GetVertexColor returns restricted.
 local get=h.GetVertexColor
 function h:GetVertexColor()if rawequal(self.alpha,secret)then return secret,secret,secret,secret end;return get(self)end
 if initialPrivate then h:SetAlpha(secret)end
 flush();check(j.stats.fallback==nil and j.stats.triangles>0,'unit geometry prebuilds even when initial native opacity is restricted')
 for _,t in ipairs(objects)do if t._junctionSource==h then
  local original=t.SetVertexColor
  function t:SetVertexColor(r,g,b,a)
   check(not e.issecretvalue(r)and not e.issecretvalue(g)and not e.issecretvalue(b)and not e.issecretvalue(a),'restricted opacity is never supplied as RGB/vertex color')
   return original(self,r,g,b,a)
  end
 end end
 local solves,reads,full,count=j.stats.solves,j.stats.geometryReads,j.stats.fullInvalidations,#objects
 for _,combat in ipairs({false,true})do
  lock(combat)
  for _=1,100 do
   h:SetVertexColor(.2,.6,.9,1);flush()
   h:SetAlpha(secret);flush()
   root:Hide();root:Show()
  end
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and j.stats.fullInvalidations==full and #objects==count,
  'repeated public recolor/private opacity causes zero reads/solves/full requests/allocations, including combat')
 local sinks,backups=0,0
 for _,t in ipairs(objects)do if t._junctionSource==h then
  if t._fallbackBlockers then backups=backups+1;check(t.alpha==0,'unneeded fallback stays gated while the perpendicular source is available')
  else sinks=sinks+1;check(rawequal(t.alpha,secret),'opaque scalar is passed directly to the approved native SetAlpha sink')end
  for i=1,3 do check(not rawequal(t.color[i],secret),'RGB remains public; opacity is not inspected or converted')end
 end end
 check(sinks>0 and backups>0 and h:GetAlpha()==0,'normal and gated native sinks are prebuilt while the duplicate source stays suppressed')
 v:Hide();flush()
 for _,t in ipairs(objects)do if t._junctionSource==h and t._fallbackBlockers then check(rawequal(t.alpha,secret),'needed fallback forwards the same opaque scalar only to native SetAlpha')end end
 v:Show();flush()
 for _,t in ipairs(objects)do if t._junctionSource==h and t._fallbackBlockers then check(t.alpha==0,'returning perpendicular source gates private-opacity fallback again')end end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'private fallback visibility also reuses existing geometry and regions')
 lock(false);h:SetAlpha(1);flush()
 check(j.stats.solves==solves and j.stats.geometryReads==reads,'public/private opacity transitions are paint-only')
end end end
print('Native unit alpha: '..checks..' checks PASS; initial private alpha; public recolor/opaque alpha; zero topology work/resources; native SetAlpha sink only; public RGB; combat paint; actual native taint/performance pending')
