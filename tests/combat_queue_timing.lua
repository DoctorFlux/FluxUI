-- Actual queue execution, order and callback ownership; no native FPS claim.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local source=read('Core/Engine/Combat.lua')
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function fixture(branch)
 local s={clock=0,reads=0,frames={},timers={},errors={},locked=false}
 local e=setmetatable({}, {__index=_G});e._G=e
 local private=setmetatable({}, {__lt=function()error('private clock compared')end,__le=function()error('private clock compared')end,__sub=function()error('private clock subtracted')end})
 e.issecretvalue=function(v)return rawequal(v,private)end
 e.type=function(v)if rawequal(v,private)then return 'number'end;return type(v)end
 e.InCombatLockdown=function()return s.locked end
 e.debugprofilestop=function()
  s.reads=s.reads+1
  if s.bad=='error'then error('clock unavailable')end
  if s.bad=='private'then return private end
  if s.bad=='infinite'then return math.huge end
  if s.bad=='nan'then return 0/0 end
  if s.bad=='malformed'then return 'bad'end
  return s.clock
 end
 e.geterrorhandler=function()return function(err)s.errors[#s.errors+1]=err;s.clock=s.clock+7 end end
 e.CreateFrame=function()
  local f={events={},scripts={}}
  function f:RegisterEvent(event)self.events[event]=true end
  function f:SetScript(k,fn)self.scripts[k]=fn end
  s.frames[#s.frames+1]=f;return f
 end
 local flux={Client={expansion=branch},Timer={After=function(delay,fn)check(delay==0,'queue keeps next-frame cadence');s.timers[#s.timers+1]=fn end}}
 flux.Safecall=function(fn,...)local ok,v=pcall(fn,...);if not ok then e.geterrorhandler()(v)end;return ok,v end
 assert(load(source,'@Core/Engine/Combat.lua','t',e))('_FluxUI',{Flux=flux})
 s.env,s.flux,s.combat=e,flux,flux.Combat
 function s:frame()local q=self.timers;self.timers={};for _,fn in ipairs(q)do fn()end end
 function s:regen()self.locked=false;self.frames[1].scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED')end
 return s
end
for _,branch in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
 local s=fixture(branch);local c=s.combat;local order,rows={},{}
 local function job(label,cost)return function()order[#order+1]=label;s.clock=s.clock+cost end end
 c.Defer('direct',job('direct',1));c.RegenDefer(job('light',2));c.RegenDefer(job('heavy',3),true);s:frame()
 check(table.concat(order,',')=='direct,light,heavy'and s.reads==0,'unobserved paths retain order with zero clock reads: '..branch)
 local stop=assert(c.ObserveTiming(function(...)rows[#rows+1]={...}end))
 check(not c.ObserveTiming(function()end),'second timing owner cannot replace first')
 s.locked=true
 c.Defer('named',job('stale',9));local fn=job('named',4);c.Defer('named',fn)
 c.RegenDefer(job('light2',5));c.RegenDefer(job('heavy2',6),true)
 check(#rows==0 and c.PendingCount()==1,'deferred calls are not reported as executed')
 s:regen();s:frame()
 check(#rows==3 and rows[1][1]=='named'and rows[1][2]==fn and rows[1][3]==4 and rows[1][4]==false,'named replacement reports actual executed callback')
 check(rows[2][1]=='regen.light'and rows[2][3]==5 and rows[3][1]=='regen.heavy'and rows[3][3]==6,'light/heavy ownership labels follow queue selected before index advances')
 local before=#rows;local n=0
 s.locked=true;for _=1,20 do c.RegenDefer(function()n=n+1;s.clock=s.clock+1 end)end
 s:regen();s:frame();check(n==16 and #rows==before+16,'original sixteen-per-frame queue budget retained')
 s:frame();check(n==20 and #rows==before+20,'remaining work stays on following frame')
 c.Defer('fail',function()s.clock=s.clock+2;error('original callback failure')end)
 check(#s.errors==1 and rows[#rows][4]==true and rows[#rows][3]==9,'existing callback error handler remains visible and inside measured interval')
 stop();local reads=s.reads;c.Defer('after',job('after',2));check(s.reads==reads,'cleanup removes all clock reads')
 local old=assert(c.ObserveTiming(function()end));old();local new=assert(c.ObserveTiming(function()end));old()
 check(not c.ObserveTiming(function()end),'stale cleanup cannot release new owner');new();new()
end
for _,bad in ipairs{'private','infinite','nan','malformed','backward','error','missing'}do
 local s=fixture('forever');local rows,runs=0,0
 s.combat.ObserveTiming(function()rows=rows+1 end)
 s.bad=bad=='backward'and nil or bad
 if bad=='missing'then s.env.debugprofilestop=false end
 s.combat.Defer('clock',function()runs=runs+1;s.clock=s.clock-1 end)
 check(rows==0 and runs==1 and #s.errors==0,'unavailable/restricted clock never disrupts actual work: '..bad)
end
do
 local s=fixture('forever');local c=s.combat;local rows=0;local observe=function()rows=rows+1 end
 local stop=assert(c.ObserveTiming(observe));local new
 c.Defer('swap',function()stop();new=assert(c.ObserveTiming(observe));s.clock=s.clock+2 end)
 check(rows==0,'observer replaced during callback receives no partial interval')
 stop();c.Defer('next',function()s.clock=s.clock+2 end);check(rows==1,'replacement survives stale cleanup');new()
 c.ObserveTiming(function()error('observer failure')end)
 c.Defer('observe-fail',function()s.clock=s.clock+1 end)
 local reads=s.reads;c.Defer('still-runs',function()s.clock=s.clock+1 end)
 check(#s.errors==1 and s.reads==reads,'failed observer detaches without poisoning callback work')
end
do
 local s=fixture('forever');local c=s.combat;local order,rows={},{}
 c.ObserveTiming(function(key)rows[#rows+1]=key end)
 s.locked=true;c.Defer('first',function()order[#order+1]='first';s.locked=true;s.clock=s.clock+1 end)
 c.Defer('second',function()order[#order+1]='second';s.clock=s.clock+1 end)
 s:regen();check(table.concat(order,',')=='first'and c.PendingCount()==1 and #rows==1,'reentered lockdown keeps unexecuted work intact')
 s:regen();check(table.concat(order,',')=='first,second'and #rows==2,'next safe transition executes only remaining job')
end
print('Combat queue timing: '..checks..' checks PASS; native frame gaps/taint remain untested')
