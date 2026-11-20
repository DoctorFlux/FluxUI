-- One source participates in both HIGH and MEDIUM HUD junctions. A later low
-- peer must not demote its shared canvas or own another source's visibility.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@canvas-layer-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
do
 local core=read("Core/BorderJunctions.lua").."\nreturn Spatial.Levels"
 local code,n=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return string.format("%q",core)end)
 assert(n==1)
 code,n=code:gsub('    assert%(load%(', '    e.levels=assert(load(',1)
 assert(n==1)
 local j,new,_,_,_,_,_,_,e=assert(load(code..'\nreturn fixture','@regional-layer-fixture','t',_G))()()
 local strip,unit=new(e.UIParent),new(e.UIParent)
 strip.level,unit.level=4,30
 local function Join(a,b)
  return {members={[a]=true,[b]=true},cut={}}
 end
 local bar={parent=strip,actionStrip=true,stripRoot=strip,pieces={}}
 local player={parent=unit,unitOwner="player",pieces={}}
 local joins={Join(bar,player),Join(bar,player),Join(bar,player)}
 local reads=0
 local getLevel=unit.GetFrameLevel
 function unit:GetFrameLevel()reads=reads+1;return getLevel(self)end
 j:_PreparePlan({},joins,nil,{}, {})
 check(reads==1 and joins[1].renderLevel==31 and joins[3].renderLevel==31,
  "three strip joins share one public raised-layer sample")
 unit.level=44
 j:_PreparePlan({},joins,nil,{}, {})
 check(reads==2 and joins[1].renderLevel==45 and joins[3].renderLevel==45,
  "a new plan samples the current level")
 local secret={}
 e.issecretvalue=function(value)return rawequal(value,secret)end
 function unit:GetFrameLevel()
  reads=reads+1
  return reads==3 and secret or getLevel(self)
 end
 j:_PreparePlan({},joins,nil,{}, {})
 check(reads==4 and joins[1].renderLevel==5 and joins[2].renderLevel==45 and joins[3].renderLevel==45,
  "an unavailable level is retried without putting private data into the plan")
 local peer=new(e.UIParent)
 peer.strata,peer.level="HIGH",58
 local dialog=new(e.UIParent)
 dialog.strata,dialog.level="DIALOG",20
 local tooltip=new(e.UIParent)
 tooltip.strata,tooltip.level="TOOLTIP",73
 local layers=e.levels({
  Join(bar,player),
  Join(bar,{parent=peer}),
  Join(bar,{parent=dialog}),
  Join(bar,{parent=tooltip}),
  Join(bar,player),
 })
 check(layers.junctions[strip].strata=="DIALOG" and layers.junctions[strip].rank==4
  and layers.junctions[strip].level==73,"canvas aggregation keeps the first highest stratum and latest highest level")
 check(layers.native[strip].strata=="MEDIUM" and layers.native[strip].level==4
  and layers.junctions[peer].level==58,"merging one canvas does not modify native samples or another canvas")
end
for _,style in ipairs{1,2}do for _,scale in ipairs{.75,1,1.25}do for _,reverse in ipairs{false,true}do
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'class')
 local source=new(e.UIParent);source.scale=scale;source.level=3
 local high=new(e.UIParent);high.scale=scale;high.level=30;high._FluxBorderHUD=true;high:SetFrameStrata('HIGH')
 local low=new(e.UIParent);low.scale=scale;low.level=10
 local track=style==1 and 8 or 9;local side=style==1 and 9 or 9.5
 local h=piece(source,'Top',{0,track-17,200,17})
 local function add(p,x)return piece(p,'Left',{x-side,-40,16,80})end
 if reverse then add(low,140);add(high,60)else add(high,60);add(low,140)end
 flush();check(j.stats.fallback==nil and j.stats.triangles>0,'both peer junctions prepare')
 local count=0
 for _,t in ipairs(objects)do if t._junctionSource==h then
  count=count+1
  check(t:GetParent():GetParent()==source,'each shared field keeps its real source visibility owner')
  check(t:GetParent():GetFrameStrata()=='HIGH'and t:GetParent():GetFrameLevel()>30,'shared source canvas keeps highest peer requirement across all nodes')
 end end
 check(count>1,'both source junctions are observed')
 high:Hide()
 for _,t in ipairs(objects)do if t._junctionSource==h then check(t:IsVisible(),'hiding one peer cannot hide the still-visible source fields')end end
end end end
-- A retained watched unit can disappear privately while the adjoining HUD
-- stays visible. The persistent stroke must not be painted under that unit.
for _,style in ipairs{1,2}do for _,unit in ipairs{'target','focus'}do
 local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
 local hud=new(e.UIParent);hud.level=1
 local root=new(e.UIParent);root.unit=unit;root._FluxBorderStatic=true;root.level=90
 local h=piece(hud,'Top',{0,-9,200,17});h:SetTexture('persistent-hud')
 local u=piece(root,'Top',{40,-9,80,17});u:SetTexture('watched-unit')
 flush();local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 local function visible()
  local found=0
  for _,t in ipairs(objects)do if t:GetTexture()=='persistent-hud'and t:IsVisible()and t:GetAlpha()>0 then
   local x,y,w,h
   if t.decorative and t.point then
    x=t:GetParent():GetLeft()+t.point[4];y=t:GetParent():GetBottom()+t.point[5];w,h=table.unpack(t.size)
   else x,y,w,h=t:GetRect()end
   if x<80 and x+w>80 and y< -1 and y+h> -1 then found=found+1 end
  end end
  check(found==1,'a higher-level watched unit cannot own or duplicate the persistent HUD stroke')
 end
 for _,combat in ipairs{false,true}do lock(combat)
  for _=1,20 do visible();root:Hide();flush();visible();root:Show();flush()end
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and#objects==count,'watched-unit existence never rebuilds or hides the persistent stroke')
end end
print('Border canvas layers: '..checks..' checks PASS; shared source with multiple peer strata/levels/orders; retained source visibility; no later canvas demotion; both styles/scales; native pixels pending')
