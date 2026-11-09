-- Actual shared owners: reentry/mutation, bounded FIFO drain and hover freshness.
local prefix=arg[1] and (arg[1]:gsub('\\','/'):gsub('/$','')..'/') or ''
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local function boot(names)
 local h={frames={},timers={},errors={},now=100,locked=false}
 local e=setmetatable({},{__index=_G});e._G=e
 e.GetTime=function()return h.now end;e.InCombatLockdown=function()return h.locked end
 e.geterrorhandler=function()return function(err)h.errors[#h.errors+1]=err end end
 e.C_EventUtils={IsEventValid=function()return true end}
 e.wipe=function(t)for k in pairs(t)do t[k]=nil end;return t end
 e.CreateFrame=function()
  local f={shown=true,scripts={},events={}}
  function f:SetScript(k,v)self.scripts[k]=v end
  function f:Show()self.shown=true end;function f:Hide()self.shown=false end
  function f:IsShown()return self.shown end
  function f:RegisterEvent(k)self.events[k]=true end
  function f:UnregisterEvent(k)self.events[k]=nil end
  function f:RegisterUnitEvent(k,u)self.events[k]=u end
  h.frames[#h.frames+1]=f;return f
 end
 local flux={Client={},Timer={After=function(_,fn)h.timers[#h.timers+1]=fn end}}
 flux.Safecall=function(fn,...)local ok,v=pcall(fn,...);if not ok then h.errors[#h.errors+1]=v end;return ok,v end
 e.UnitExists=function()return true end;e.UnitCanAttack=function()return true end
 e.UnitCanAssist=function()return false end;e.UnitIsDead=function()return false end
 flux.Spell={IsInRange=function()return true end}
 function h.event(name,...)
  for _,f in ipairs(h.frames)do if f.events[name]and f.scripts.OnEvent then f.scripts.OnEvent(f,name,...)end end
 end
 function h.frame(dt)
  h.now=h.now+(dt or .016)
  local q=h.timers;h.timers={};for _,fn in ipairs(q)do fn()end
  for _,f in ipairs(h.frames)do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f,dt or .016)end end
 end
 function h.drain(limit)
  local n=0;while#h.timers>0 do n=n+1;check(n<(limit or 10000),'queue eventually sleeps');h.frame()end;return n
 end
 local ns={Flux=flux}
 for _,name in ipairs(names)do assert(loadfile(prefix..'Core/Engine/'..name..'.lua','t',e))('_FluxUI',ns)end
 h.flux=flux;return h
end

for _,n in ipairs({1,8,9,16,17,1000,10000})do
 local h=boot({'Scheduler'});local s=h.flux.Scheduler
 local order,seen={},false
 s.Register('inventory',function(tokens)seen=seen or tokens.nested==true end)
 for i=1,n do
  local index=i
  s.Request('inventory','old',function()
   order[#order+1]=index
   if index==1 then
    s.Request('inventory','nested',function()order[#order+1]=n+1 end)
    s.Flush() -- Reentry cannot run newer work before the remaining older jobs.
   end
  end)
 end
 while#h.timers>0 do
  local before=#order;h.frame();check(#order-before<=8,'inventory per-frame callback budget')
 end
 check(#order==n+1 and seen and not s.HasPending(),'every callback/token survives partial reentrant drain')
 for i=1,n+1 do check(order[i]==i,'old-before-new FIFO ordering')end
end

do
 local h=boot({'Scheduler'});local s=h.flux.Scheduler;local calls=0
 s.Register('display',function()calls=calls+1 end)
 for i=1,10000 do s.Request('display','same')end
 h.drain();check(calls==1,'token-only requests still coalesce')
end

for _,kind in ipairs({'self','later','all-readd','add','nested','error','duplicate'})do
 local h=boot({'Events'});local ev=h.flux.Events;local calls={};local nested=false;local added=false
 local first,second,third
 second=function()calls[#calls+1]='B'end
 third=function()calls[#calls+1]='C'end
 first=function()
  calls[#calls+1]='A'
  if kind=='self'or kind=='duplicate'or kind=='error'then ev.Unregister('X',first)
  elseif kind=='later'then ev.Unregister('X',second)
  elseif kind=='all-readd'then ev.Unregister('X');ev.Register('X',third)
  elseif kind=='add'and not added then added=true;ev.Register('X',function()calls[#calls+1]='D'end)
  elseif kind=='nested'and not nested then nested=true;h.event('X')end
  if kind=='error'then error('injected handled listener failure')end
 end
 ev.Register('X',first);if kind=='duplicate'then ev.Register('X',first)end
 ev.Register('X',second);ev.Register('X',third)
 h.event('X')
 local expected=({self='ABC',later='AC',['all-readd']='A',add='ABC',nested='AABCBC',error='ABC',duplicate='ABC'})[kind]
 check(table.concat(calls)==expected,'listener mutation semantics '..kind)
 calls={};h.event('X')
 local nextExpected=({self='BC',later='AC',['all-readd']='C',add='ABCD',nested='ABC',error='BC',duplicate='BC'})[kind]
 check(table.concat(calls)==nextExpected,'listener compaction/next dispatch '..kind)
 check(#h.errors==(kind=='error'and 1 or 0),'callback errors remain isolated '..kind)
end

-- A regen wake may run before an already scheduled timer gets its turn.
do
 local h=boot({'Scheduler','Combat'});local s=h.flux.Scheduler;local count=0
 h.locked=true;s.Request('structural','wake',function()end)
 for i=1,20 do s.Request('inventory',i,function()count=count+1 end)end
 h.locked=false;h.event('PLAYER_REGEN_ENABLED')
 check(count==8,'direct regen wake consumes only one inventory batch')
 while#h.timers>0 do
  local before=count;h.frame();check(count-before<=8,'obsolete scheduled wake cannot drain a second batch')
 end
 check(count==20 and not s.HasPending(),'regen/timer interleaving retains all inventory jobs')
end

-- Work submitted during combat reentry must follow the detached old batch.
for _,pauseAt in ipairs({'callback','listener'})do
 local h=boot({'Scheduler','Combat'});local s=h.flux.Scheduler;local order={};local paused=false
 local function enter()
  if paused then return end;paused=true;h.locked=true
  s.Request('structural','new',function()order[#order+1]='new'end)
 end
 s.Request('structural','old1',function()order[#order+1]='old1';if pauseAt=='callback'then enter()end end)
 s.Request('structural','old2',function()order[#order+1]='old2'end)
 if pauseAt=='listener'then
  s.Register('structural',function()order[#order+1]='L1';enter()end)
  s.Register('structural',function()order[#order+1]='L2'end)
 end
 h.frame();check(s.HasPending('structural'),'paused structural bucket remains visible')
 h.locked=false;h.event('PLAYER_REGEN_ENABLED');h.drain()
 local expected=pauseAt=='callback'and'old1,old2,new'or'old1,old2,L1,L2,new,L1,L2'
 check(table.concat(order,',')==expected,'older callbacks/listeners precede new work after '..pauseAt..' pause')
 check(not s.HasPending()and#h.errors==0,'structural resume completes exactly once')
end

-- The final callback/listener can lock down after its old bucket is complete.
for _,pauseAt in ipairs({'callback','listener'})do
 local h=boot({'Scheduler','Combat'});local s,c=h.flux.Scheduler,h.flux.Combat
 local order={};local firstPause,secondPause=false,false
 local function enterFirst()
  if firstPause then return end;firstPause=true;h.locked=true
  s.Request('structural','new',function()order[#order+1]='new'end)
 end
 local function enterLast()
  if secondPause then return end;secondPause=true;h.locked=true
 end
 s.Request('structural','old1',function()order[#order+1]='old1';if pauseAt=='callback'then enterFirst()end end)
 s.Request('structural','old2',function()order[#order+1]='old2';if pauseAt=='callback'then enterLast()end end)
 if pauseAt=='listener'then
  s.Register('structural',function()order[#order+1]='L1';enterFirst()end)
  s.Register('structural',function()order[#order+1]='L2';enterLast()end)
 end
 h.frame();h.locked=false;h.event('PLAYER_REGEN_ENABLED')
 check(h.locked and s.HasPending('structural')and c.HasPending(),'last old '..pauseAt..' retains a regen wake for newer work')
 h.frame();h.locked=false;h.event('PLAYER_REGEN_ENABLED');h.drain()
 local expected=pauseAt=='callback'and'old1,old2,new'or'old1,old2,L1,L2,new,L1,L2'
 check(table.concat(order,',')==expected,'last old '..pauseAt..' cannot strand the next bucket')
 check(not s.HasPending()and not c.HasPending(),'last-member combat reentry sleeps after completion')
end

do
 local h=boot({'Combat'});local c=h.flux.Combat;h.locked=true
 local order={}
 for i=1,100 do
  local index=i
  c.RegenDefer(function()
   order[#order+1]=index
   if index==1 then
    c.RegenDefer(function()order[#order+1]=101 end)
    c.RegenDefer(function()order[#order+1]=102 end,true)
   end
   if index==12 then h.locked=true end
  end,i>80)
 end
 check(#h.timers==0,'regen queue sleeps in combat')
 h.locked=false;h.event('PLAYER_REGEN_ENABLED');h.frame()
 check(#order==12,'regen stops on synchronous combat reentry')
 h.frame();check(#order==12,'no protected work while still locked')
 h.locked=false;h.event('PLAYER_REGEN_ENABLED')
 while#h.timers>0 do
  local n=#order;h.frame();check(#order-n<=16,'regen callbacks bounded per frame')
 end
 check(#order==102,'regen distinct jobs retained')
 for i=1,102 do check(order[i]==i,'regen snapshot FIFO and nested jobs')end
end

do
 local h=boot({'Events','Ticker','Range'});local r=h.flux.Range;local calls,needed=0,true
 r.RegisterSweep('bars',function()return needed end,function()calls=calls+1 end)
 r.Start();r.Invalidate();local before=calls
 for i=1,1000 do h.event('UPDATE_MOUSEOVER_UNIT');h.frame(.001)end
 check(calls>before and calls-before<=3,'sustained hover stays fresh without unbounded sweeps')
 h.frame(.3);check(calls>before+1,'normal cadence resumes after quiet')
 needed=false;h.frame(.5);check(not r.IsArmed(),'disabled range owner disarms')
end

do
 local h=boot({'Combat'});local c=h.flux.Combat;local count=0
 h.locked=true
 for i=1,10000 do
  local index=i;c.RegenDefer(function()count=count+1;check(count==index,'ten-thousand-job FIFO')end,i>8000)
 end
 h.locked=false;h.event('PLAYER_REGEN_ENABLED');local frames=0
 while#h.timers>0 do
  local before=count;h.frame();frames=frames+1;check(count-before<=16,'ten-thousand-job per-frame budget')
 end
 check(count==10000 and frames==625,'ten-thousand distinct jobs retire in625 bounded batches')
end
print('Shared service integrity: '..checks..' checks; actual production modules; native taint/FPS pending')
