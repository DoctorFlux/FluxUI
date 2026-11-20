-- Approved native unit RGB is paint-only; generic private colors keep the old
-- retirement policy. Model opaque values fail if compared, formatted or mixed.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
if arg[1] then prefix=prefix:gsub('read%("Core/BorderJunctions.lua"%)','read('..string.format('%q',arg[1])..')',1) end
local fixture=assert(load(prefix..'\nreturn fixture','@native-unit-rgb-model','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,managed in ipairs{false,true}do for _,style in ipairs{1,2}do for _,cold in ipairs{false,true}do
 local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
 local root=new(e.UIParent);root.unit='targettarget';root._FluxBorderStatic=true
 local h,hr=piece(root,'Top',{0,-9,100,17});local v,vr=piece(root,'Left',{41,-40,16,80})
 if managed then for t,r in pairs{[h]=hr,[v]=vr}do
  local path='Interface\\AddOns\\_FluxUI\\Texture\\borders\\'..(style==1 and'Battlefield100.tga'or'ForeverMetal150Tint.tga')
  r.art=path;r.artHandle=path;t:SetTexture(path)
 end end
 local opaque={};local function secret()
  local v=setmetatable({},{__eq=function()error('opaque RGB compared')end,__lt=function()error('opaque RGB ordered')end,
   __le=function()error('opaque RGB ordered')end,__tostring=function()error('opaque RGB formatted')end,
   __add=function()error('opaque RGB arithmetic')end,__mul=function()error('opaque RGB arithmetic')end})
  opaque[v]=true;return v
 end
 local r,g,b=secret(),secret(),secret();e.issecretvalue=function(v)return opaque[v]or false end
 h._FluxBorderNativeUnitRGB=true
 local reads=0;local getter=h.GetVertexColor
 function h:GetVertexColor()reads=reads+1;return getter(self)end
 if cold then h:SetVertexColor(r,g,b,1)end
 flush();check(j.stats.fallback==nil and j.stats.triangles>0,'approved class RGB allows initial public geometry preparation')
 if not cold then h:SetVertexColor(r,g,b,1);flush()end
 local function colored()
  local visible,backups=0,0
  for _,t in ipairs(objects)do if t._junctionSource==h then
   check(rawequal(t.color[1],r)and rawequal(t.color[2],g)and rawequal(t.color[3],b),'native unit channels reach every prepared field without conversion')
   if t._fallbackBlockers then backups=backups+1 else visible=visible+1 end
  end end
  check(visible>0 and backups>0 and h:GetAlpha()==0,'prepared sources stay suppressed; gated and main native sinks both exist')
 end
 colored()
 local solves,geo,full,n=j.stats.solves,j.stats.geometryReads,j.stats.fullInvalidations,#objects
 local beforeReads=reads
 for _,combat in ipairs{false,true,false}do
  lock(combat)
  for _=1,40 do h:SetVertexColor(r,g,b,1);flush();root:Hide();root:Show()end
 end
 check(j.stats.solves==solves and j.stats.geometryReads==geo and j.stats.fullInvalidations==full and #objects==n,'opaque paint/reveal/combat performs no topology reads, solves or allocations')
 check(reads==beforeReads,'warm opaque paint forwards caller RGB without native readback')
 v:Hide();flush();colored();v:Show();flush();colored()
 check(j.stats.solves==solves and j.stats.geometryReads==geo,'opaque fallback visibility stays on prepared geometry')
 -- Genuine layout changes can rebuild using public geometry and the existing
 -- source only as a native color sink. One transient read per private source.
 beforeReads=reads;h.rect[3]=110;j:Invalidate(nil,h);flush();colored()
 check(reads-beforeReads<=1,'real reflow memoizes native RGB once per source for commit only')
 solves,geo=j.stats.solves,j.stats.geometryReads
 h:SetVertexColor(1,1,1,1);flush()
 for _,t in ipairs(objects)do if t._junctionSource==h then check(t.color[1]==1 and t.color[2]==1 and t.color[3]==1,'public recovery repaints private sinks even when equal to public proxy')end end
 check(j.stats.solves==solves and j.stats.geometryReads==geo,'private/public RGB recovery is paint-only')
end end end
print('Native unit RGB: '..checks..' checks PASS; cold/warm, combat, fallbacks, real reflow, native-only opaque channels; no native taint/FPS claim')
