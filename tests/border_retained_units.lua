-- Hidden unit chrome is prepared once. Native source ownership handles unit
-- visibility/fades; only actual geometry/material changes can rebuild it.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@retained-unit-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs({1,2})do for _,unit in ipairs({'target','focus','party1','pet','targettarget'})do for _,scale in ipairs({.75,1,1.25})do
 local j,new,piece,flush,objects,locked,choose,queued,e=fixture();choose(style,'class')
 local strip=new(e.UIParent);strip.scale=scale;e.FluxActionStrip=strip
 local root=new(e.UIParent);root.scale=scale;root.unit=unit;root._FluxBorderStatic=true;root:Hide()
 local top=style==1 and 8 or 9;local side=style==1 and 9 or 9.5
 local internal=unit=='pet'or unit=='targettarget'or unit=='party1'
 local h=piece(internal and root or strip,'Top',{0,top-17,200,17})
 local v,record=piece(root,'Left',{100-side,0,16,40})
 record.art='Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150Tint.tga'
 flush();check(j.stats.fallback==nil and j.stats.triangles>0,'hidden unit geometry is prepared during initial layout')
 local unitPaint,stripPaint=0,0
 for _,t in ipairs(objects)do if t._junctionOwnerOp then
  if t._junctionSource==v then
   unitPaint=unitPaint+1;check(not t:IsVisible(),'prepared unit stem inherits hidden watched-unit owner')
   check(t:GetParent():GetParent()==root,'relocated unit source keeps its own native visibility/fade ancestor')
  elseif t._junctionSource==h then
   stripPaint=stripPaint+1
   check(internal and not t:IsVisible()or not internal and t:IsVisible(),'crossbar inherits its correct unit or persistent-strip visibility owner')
  end
 end end
 check(unitPaint>0 and stripPaint>0,'both prepared unit and persistent crossbar resources are observed')
 local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 for _,combat in ipairs({false,true})do
  locked(combat)
  for _=1,20 do
   root:Show();root:SetAlpha(.4)
   local main,backup=0,0
   for _,t in ipairs(objects)do if t._junctionSource==v then
    if t._fallbackBlockers then
     backup=backup+1;check(t:GetAlpha()==0,'prepared perpendicular backup stays disabled while its crossbar is available')
    else main=main+1;check(t:IsVisible()and math.abs(t:GetEffectiveAlpha()-.4)<1e-8,'native visibility/alpha reveals existing unit paint immediately')end
   end end
   check(main>0 and backup>0,'both normal and conditional unit paint are prepared')
   if internal then
    h:Hide()
    for _,t in ipairs(objects)do if t._junctionSource==v and t._fallbackBlockers then check(math.abs(t:GetEffectiveAlpha()-.4)<1e-8,'hidden crossbar reveals the prepared perpendicular continuation at the unit opacity')end end
    h:Show()
    for _,t in ipairs(objects)do if t._junctionSource==v and t._fallbackBlockers then check(t:GetAlpha()==0,'restoring the crossbar disables its backup without rebuilding')end end
   end
   root:SetAlpha(0);root:Hide();j:CommitLayout();flush()
  end
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count and queued()==0,'target/focus clear and return perform no geometry reads/solves/allocations, including combat')
 locked(false);root:Show();root:SetAlpha(1)
 v:SetTexture('Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150.tga');flush()
 check(j.stats.solves==solves and j.stats.geometryReads==reads,'canonical unit material change paints in the same call without topology work')
 for _,t in ipairs(objects)do if t._junctionSource==v then check(t.path:find('ForeverMetal150.tga',1,true)and #t._junctionUV==8,'live material paint retains the prepared UV field')end end
 v.rect[1]=v.rect[1]+8;v:SetPoint('LEFT',root,'LEFT',8,0);j:CommitLayout()
 check(j.stats.solves==solves+1,'an actual unit-layout move still recomputes its attachment')
end end end
print('Retained unit borders: '..checks..' checks PASS; initial hidden prebuild; target/focus/party/pet/ToT show/hide/fade; zero reads/solves/allocations; combat native inheritance; immediate material; real layout invalidation; native pixels pending')
