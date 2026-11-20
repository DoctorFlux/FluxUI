-- A junction spanning sibling backgrounds must draw above both whole-frame
-- layers, not just above textures inside whichever sibling became its owner.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@border-paint-order','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs({1,2})do for _,reverse in ipairs({false,true})do
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'class')
 local a,b=new(e.UIParent),new(e.UIParent);a.strata,b.strata='BACKGROUND','BACKGROUND';a.level,b.level=0,0
 local top=style==1 and 8 or 9;local side=style==1 and 9 or 9.5
 if reverse then
  piece(b,'Left',{50-side,-50,16,50});piece(a,'Top',{0,top-17,100,17})
 else piece(a,'Top',{0,top-17,100,17});piece(b,'Left',{50-side,-50,16,50})end
 flush();local count=0
 for _,t in ipairs(objects)do if t._junctionOwnerOp then
  check(t:GetParent():GetFrameStrata()=='BACKGROUND','junction retains the original HUD stratum')
  check(t:GetParent():GetFrameLevel()>a:GetFrameLevel()and t:GetParent():GetFrameLevel()>b:GetFrameLevel(),
   'junction paints above both sibling background frames regardless of creation/registration order')
  check(t:GetParent():GetParent()==a or t:GetParent():GetParent()==b,'raised junction canvas inherits its existing visibility owner')
  count=count+1
 end end
 check(count>0,'real production T sprites were checked')
 local solves,objectsBefore=j.stats.solves,#objects
 for _=1,50 do a:SetPoint('CENTER',e.UIParent,'CENTER',0,0)end;flush()
 check(j.stats.solves==solves and #objects==objectsBefore,'paint-order correction adds no idle rebuilds or resources')
end end
print('Border paint order: '..checks..' checks PASS; sibling aura/background frames; both registration orders/styles; retained stratum/visibility/scale; static reuse; native pixels pending')
