-- Replay real UpdatePower against the real border solver. A missing watched
-- unit must not turn its prepared separator off and rebuild it on every return.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local fixture=assert(load(prefix..'\nreturn fixture','@resource-border-fixture','t',_G))()
local power=read('tests/unit_power_visibility.lua');power=power:sub(1,assert(power:find('UF.UpdatePower(frame, "focus")',1,true))-1)
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs({1,2})do for _,unit in ipairs({'target','focus','party1','pet','targettarget'})do
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'class')
 local root=new(e.UIParent);root.unit=unit;root._FluxBorderStatic=true
 local top=style==1 and 8 or 9;local side=style==1 and 9 or 9.5
 piece(root,'Top',{0,top-17,100,17});local separator=piece(root,'Left',{50-side,-40,16,80})
 local uf,f,set=assert(load(power..'\nreturn UF,frame,function(m,exists)modern=true;maximum=m;env.UnitExists=function()return exists end end','@actual-power-with-border','t',_G))()
 f.unit=unit;f.HealthPowerSeparator=separator
 local partitions=0;f.UpdatePartition=function()partitions=partitions+1 end
 set(100,true);uf.UpdatePower(f,unit);flush()
 local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 local partitionCount=partitions
 for _=1,20 do
  set(0,false);uf.UpdatePower(f,unit);flush()
  check(f._fluxMainPowerAlpha==100 and f._fluxHasMainPower==true,'unit loss retains prepared resource alpha and layout fact')
  set(100,true);uf.UpdatePower(f,unit);flush()
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'actual clear-return power updates cause zero border reads/solves/allocations')
 check(partitions==partitionCount,'absent-unit power updates do not request a different partition')
 set(0,true);uf.UpdatePower(f,unit);flush()
 check(f._fluxHasMainPower==false and f._fluxMainPowerAlpha==0,'a present unit with genuinely no resource still applies its zero-capacity state')
end end
print('Resource border hold: '..checks..' checks PASS; real power producer and solver; clear-return target/focus/party/pet/ToT; zero reads/solves; actual no-resource state preserved; native counters pending')
