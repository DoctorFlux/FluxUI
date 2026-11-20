-- Optional active-watch combat accounting and lifecycle regression.
-- Reuse the complete current module and the existing in-repository fixture.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local sourcePath = root .. "Other/FluxPerfCapture.lua"
for i, value in ipairs(arg or {}) do if value == "--source" then sourcePath = assert(arg[i + 1]) end end
if _VERSION == 'Lua 5.1' then
 local native=load;load=function(s,n,m,e)local f,err;if type(s)=='string'then f,err=loadstring(s,n)else f,err=native(s,n)end;if f and e then setfenv(f,e)end;return f,err end;table.unpack=table.unpack or unpack
end
local function read(path)local f=assert(io.open(path,'rb'));local t=f:read('*a'):gsub('\r\n','\n');f:close();return t end
local fixture=read(root..'tests/perf_spike_watch.lua')
local prefix=assert(fixture:match('^(.-)\ndo\n    local s = harness%('))
local env=setmetatable({arg={[0]=root..'tests/perf_spike_watch.lua','--source',sourcePath}},{__index=_G});env._G=env
local model=assert(load(prefix..'\nreturn {harness=harness,activeState=activeState,plain=plain}','@in-repository-watch-fixture','t',env))()
local checks,scenes=0,0
local function check(v,m)checks=checks+1;assert(v,m)end
local function new(options)scenes=scenes+1;return model.harness(options or {withCombat=true})end
local function start(s)check(s.capture.StartWatch(30,50)==true,'watch starts');return s.capture.GetActiveWatchReport()end
local function event(s,name,...)local f=s.frames[1];assert(f.scripts.OnEvent)(f,name,...)end
local function update(s,elapsed)local f=s.frames[1];assert(f.scripts.OnUpdate)(f,elapsed)end
local function state(s)return model.activeState(s)end
local function counters(s)return assert(s.capture.GetActiveWatchReport()).combatTransitions end
local function stop(s)
 local held=s.capture.GetActiveWatchReport()and state(s)
 if held then s.capture.StopWatch('proof');check(held.pendingEnter==0 and held.pendingExit==0 and held.inflightEnter==0 and held.inflightExit==0,'actual stopped state drains pending and inflight')end
 check(s.detached(),'model resources detached')
end
local function balanced(s,r)
 local a=s.capture.GetActiveWatchReport()and state(s)or{pendingEnter=0,pendingExit=0,inflightEnter=0,inflightExit=0}
 check(r.enters==r.enterSampledEvents+r.enterFirstUnmeasured+r.enterInvalidUnmeasured+r.enterStoppedUnmeasured+a.pendingEnter+a.inflightEnter,'enter accounting reconciles')
 check(r.exits==r.exitSampledEvents+r.exitFirstUnmeasured+r.exitInvalidUnmeasured+r.exitStoppedUnmeasured+a.pendingExit+a.inflightExit,'exit accounting reconciles')
end
-- OFF behavior and the bounded report schema.
do
 local s=new();check(#s.frames==0 and #s.timers==0 and s.clockReads==0 and s.heapReads==0 and s.observerAdds==0,'OFF creates no ongoing resources or queries')
 local r=start(s);check(r.diagnosticVersion==3 and r.combatTransitions.schemaVersion==1,'versioned bounded schema')
 check(not r.combatTransitions.enterWorst.present and not r.combatTransitions.exitWorst.present,'no sample is distinct from valid zero')
 stop(s);local c=s.clockReads;s.tick(10);check(s.clockReads==c,'stopped watch has no ongoing clock')
end
-- Every owned registration refusal/failure, including partial side effects.
for _,wanted in ipairs{'PLAYER_LOGOUT','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED'}do
 for _,mode in ipairs{'false','nil','malformed','private','table-error','false-error'}do
  local prior={status='prior'};local s=new({withCombat=true,saved={spikeWatch=prior}});local create=s.env.CreateFrame;local marker={};local injected=false
  s.env.CreateFrame=function(...)
   local f=create(...);local register=f.RegisterEvent
   f.RegisterEvent=function(self,key)
    if key==wanted and not injected then
     injected=true
     if mode=='table-error'or mode=='false-error'then register(self,key);if mode=='false-error'then error(false,0)else error(marker,0)end end
     if mode=='false'then return false elseif mode=='nil'then return nil elseif mode=='private'then return s.secret else return{}end
    end
    return register(self,key)
   end
   return f
  end
  local ok,result=pcall(s.capture.StartWatch,30,50)
  if mode=='table-error'then check(not ok and rawequal(result,marker),'setup preserves opaque raw error')
  elseif mode=='false-error'then check(not ok and result==false,'setup preserves falsy raw error')
  else check(ok and result==false,'nontrue registration refuses arm')end
  check(not s.capture.GetActiveWatchReport()and s.detached()and s.env.FluxPerfCaptureDB.spikeWatch==prior,'failed arm clears active resources and preserves prior report')
  check(s.observerAdds==s.observerReleases,'failed arm releases every acquired observer')
  start(s);check(#s.frames==1,'failed arm reuses one retained frame');stop(s)
 end
end
for _,method in ipairs{'CreateFrame','SetScript','Show'}do
 local prior={};local s=new({withCombat=true,saved={spikeWatch=prior}});local create=s.env.CreateFrame;local marker={};local fired=false
 s.env.CreateFrame=function(...)
  if method=='CreateFrame'and not fired then fired=true;error(marker,0)end
  local f=create(...)
  if method~='CreateFrame'then local native=f[method];f[method]=function(self,...)
   if not fired then fired=true;native(self,...);error(marker,0)end;return native(self,...)
  end end
  return f
 end
 local ok,result=pcall(s.capture.StartWatch,30,50)
 check(not ok and rawequal(result,marker),'setup '..method..' exact failure')
 check(not s.capture.GetActiveWatchReport()and s.detached()and s.env.FluxPerfCaptureDB.spikeWatch==prior,'setup '..method..' rolls back')
 start(s);check(#s.frames==1,'setup retry reuses available frame');stop(s)
end
do
 local s=new({withCombat=true,conflict='Scheduler'});check(s.capture.StartWatch()==false and s.detached(),'observer refusal fully rolls back')
 local s2=new();local observe=s2.flux.Events.ObserveTiming
 s2.flux.Events.ObserveTiming=function(callback)
  s2.capture.Start(5);check(#s2.timers==0 and s2.scans==0,'arming blocks legacy endpoint stealing capture')
  check(s2.capture.StartWatch()==false,'arming blocks reentrant StartWatch')
  return observe(callback)
 end
 start(s2);stop(s2)
 local s3=new();local create=s3.env.CreateFrame
 s3.env.CreateFrame=function(...)local f=create(...);check(s3.capture.StopWatch('cancel-arming')==true,'setup cancellation accepted');return f end
 check(s3.capture.StartWatch()==false and s3.detached(),'cancelled setup rolls back')
end
-- An original setup error wins over a distinct cleanup error, including falsy values.
do
 local s=new();local create=s.env.CreateFrame;local marker={};local once=false
 s.env.CreateFrame=function(...)local f=create(...);local unregister=f.UnregisterEvent
  f.RegisterEvent=function()error(false,0)end
  f.UnregisterEvent=function(self,key)unregister(self,key);if not once then once=true;error(marker,0)end end
  return f end
 local ok,err=pcall(s.capture.StartWatch,30,50);check(not ok and err==false,'cleanup cannot mask falsy original setup error');check(s.detached(),'remaining cleanup operations still attempted')
end
-- A readable saved root may legitimately reject/reenter an ordinary slot write.
for _,mode in ipairs{'throw-before','throw-after','cancel','foreign-report','foreign-root'}do
 local marker={};local foreign={status='foreign'};local saved={};local s
 setmetatable(saved,{__newindex=function(t,k,v)
  check(k=='spikeWatch','only owned saved slot is published')
  if mode=='throw-before'then error(marker,0)end
  rawset(t,k,v)
  if mode=='throw-after'then error(marker,0)end
  if mode=='foreign-report'then rawset(t,k,foreign)end
  if mode=='foreign-root'then s.env.FluxPerfCaptureDB=foreign end
  check(s.capture.StopWatch('publication-cancel')==true,'publication reentry cancels arming owner')
  check(s.capture.StartWatch()==false,'publication reservation blocks replacement arm')
 end})
 s=new({withCombat=true,saved=saved})
 local ok,err=pcall(s.capture.StartWatch,30,50)
 if mode=='throw-before'or mode=='throw-after'then check(not ok and rawequal(err,marker),'publication raw error identity preserved')
 else check(ok and err==false,'publication cancellation refuses arm')end
 check(not s.capture.GetActiveWatchReport()and s.detached(),'publication failure rolls back active resources')
 if mode=='foreign-root'then check(s.env.FluxPerfCaptureDB==foreign,'foreign saved root survives rollback')
 elseif mode=='foreign-report'then check(saved.spikeWatch==foreign,'foreign saved slot survives rollback')
 else check(rawget(saved,'spikeWatch')==nil and s.env.FluxPerfCaptureDB==saved,'owned publication restores exact prior empty slot/root')end
end
-- Foreign private/unknown roots and slots are never compared for raw identity.
for _,where in ipairs{'root','slot'}do for _,kind in ipairs{'private','inaccessible','secret-table','private-scalar'}do
 local saved={};local s;local foreign
 setmetatable(saved,{__newindex=function(t,k,v)
  rawset(t,k,v)
  if where=='root'then s.env.FluxPerfCaptureDB=foreign
  else rawset(t,k,foreign);s.capture.StopWatch('private-slot-cancel')end
 end})
 s=new({withCombat=true,saved=saved})
 foreign=kind=='private'and s.secret or kind=='inaccessible'and{inaccessible=true}or kind=='secret-table'and{secretTable=true}or 777
 local secret=s.env.issecretvalue;s.env.issecretvalue=function(v)return type(v)=='number'and v==777 or secret(v)end
 local eq=rawequal
 local function opaque(v)return eq(v,s.secret)or(type(v)=='number'and v==777)or(type(v)=='table'and(rawget(v,'inaccessible')or rawget(v,'secretTable')))end
 s.env.rawequal=function(a,b)check(not opaque(a)and not opaque(b),'privacy guard precedes foreign rawequal');return eq(a,b)end
 local ok,result=pcall(s.capture.StartWatch,30,50)
 check(ok and result==false and s.detached(),'private replacement refuses/cancels arm safely')
 check(eq(where=='root'and s.env.FluxPerfCaptureDB or rawget(saved,'spikeWatch'),foreign),'private foreign replacement preserved untouched')
end end
-- A newly-created saved root becomes foreign-owned if hooks add data/metatable.
for _,mode in ipairs{'foreign-slot','other-key','metatable-only'}do
 local s=new();local access=s.env.canaccesstable;local eq=rawequal;local installed=false;local created;local foreign={status='foreign'}
 s.env.canaccesstable=function(value)
  if not installed and eq(value,s.env.FluxPerfCaptureDB)then
   installed=true;created=value
   setmetatable(value,{__newindex=function(t,k,v)
    rawset(t,k,v)
    if mode=='foreign-slot'then rawset(t,k,foreign)elseif mode=='other-key'then rawset(t,'foreign',foreign)end
    s.capture.StopWatch('created-root-cancel')
   end})
  end
  return access(value)
 end
 check(s.capture.StartWatch(30,50)==false and s.detached(),'created-root cancellation cleans watch')
 check(installed and eq(s.env.FluxPerfCaptureDB,created)and type(getmetatable(created))=='table','foreign created-root identity/metatable preserved')
 if mode=='foreign-slot'then check(eq(created.spikeWatch,foreign),'created-root foreign report survives')
 elseif mode=='other-key'then check(eq(created.foreign,foreign)and rawget(created,'spikeWatch')==nil,'created-root other data survives own-slot undo')
 else check(type(next(created))=='nil','empty foreign metatable survives own-slot undo')end
end
-- Old A never publishes over B, even when B also stops in A's release hook.
-- Finite injected permission-read swaps are declined at the fresh boundary.
for _,boundary in ipairs{'final-arm','created-root-rollback'}do
 local saved=boundary=='final-arm'and{}or nil;local s=new({withCombat=true,saved=saved});local access=s.env.canaccesstable;local eq=rawequal;local foreign={status='after-permission-swap'};local swapped=false;local created;local cancelled=false
 s.env.canaccesstable=function(value)
  if boundary=='final-arm'then
   if not swapped and eq(value,saved)and type(rawget(value,'spikeWatch'))=='table'then swapped=true;s.env.FluxPerfCaptureDB=foreign end
  elseif not created and eq(value,s.env.FluxPerfCaptureDB)then
   created=value;cancelled=true;s.capture.StopWatch('permission-cancel');return access(value)
  elseif cancelled and not swapped and eq(value,created)and type(rawget(value,'spikeWatch'))=='nil'then
   swapped=true;s.env.FluxPerfCaptureDB=foreign
  end
  return access(value)
 end
 check(s.capture.StartWatch(30,50)==false and s.detached(),'permission-read '..boundary..' refuses/cleans old arm')
 check(swapped and eq(s.env.FluxPerfCaptureDB,foreign),'permission-read '..boundary..' preserves replacement root')
end
for _,stopB in ipairs{false,true}do
 local s=new();local c=s.capture;local observe=s.flux.Combat.ObserveTiming;local did=false;local b
 s.flux.Combat.ObserveTiming=function(callback)local release,why=observe(callback);if not release then return release,why end
  return function()release();if not did then did=true;check(c.StartWatch(90,50),'B starts in final release');b=c.GetActiveWatchReport();if stopB then c.StopWatch('B-stopped')end end end
 end
 start(s);c.StopWatch('A-stopped');check(s.env.FluxPerfCaptureDB.spikeWatch==b,'newer B publication wins even if stopped')
 check(stopB and not c.GetActiveWatchReport()or not stopB and c.GetActiveWatchReport()==b,'B lifecycle retained');stop(s)
end
-- Reentry after every relevant existing read, including the original two bugs.
for _,seam in ipairs{'GetTime','ending-clock','heap','errors','profiler','tab','frame','combat','origin'}do
 local s=new();local c=s.capture;start(s);s.tick(.01);local oldUpdate=s.frames[1].scripts.OnUpdate;local b;local fired=false
 local function replace()
  if fired then return end;fired=true;c.StopWatch('replaced');check(c.StartWatch(90,50),'B starts at '..seam);b=c.GetActiveWatchReport()
 end
 if seam=='GetTime'then local f=s.env.GetTime;s.env.GetTime=function()s.env.GetTime=f;replace();return f()end
 elseif seam=='ending-clock'then local f=s.env.debugprofilestop;local n=0;s.env.debugprofilestop=function()n=n+1;if n==2 then s.env.debugprofilestop=f;replace()end;return f()end
 elseif seam=='heap'then local f=s.env.collectgarbage;s.env.collectgarbage=function(...)s.env.collectgarbage=f;replace();return f(...)end
 elseif seam=='errors'then local f=s.env.BugTabs.GetSessionCounts;s.env.BugTabs.GetSessionCounts=function(...)s.env.BugTabs.GetSessionCounts=f;replace();return f(...)end
 elseif seam=='profiler'then local f=s.env.C_AddOnProfiler.GetApplicationMetric;s.env.C_AddOnProfiler.GetApplicationMetric=function(...)s.env.C_AddOnProfiler.GetApplicationMetric=f;replace();return f(...)end
 elseif seam=='tab'then s.env.FluxWindowFrame={GetActiveTab=function()replace();return'party'end}
 elseif seam=='frame'then s.env.MailFrame={IsForbidden=function()replace();return false end,IsShown=function()return true end,IsVisible=function()return true end}
 elseif seam=='combat'then s.env.InCombatLockdown=function()replace();return false end
 else s.flux.Events.GetCallbackOrigin=function()replace();return'origin'end;s.emit('Events','callback',.1,false)end
 s.now=31
 local ok,err=pcall(oldUpdate,s.frames[1],.06)
 check(ok,'stale update does not touch cleared state: '..seam..' '..tostring(err))
 check(fired and c.GetActiveWatchReport()==b and b.status=='watching'and s.env.FluxPerfCaptureDB.spikeWatch==b,'stale A cannot clear/expire/publish B: '..seam)
 stop(s)
end
-- Complete event accounting, below threshold, both directions, and ring independence.
do
 local s=new();local report=start(s);local r=report.combatTransitions;local f=s.frames[1];local clock=s.clockReads;local heap=s.heapReads;local reads=0
 for _,key in ipairs{'GetTime','InCombatLockdown','GetFramerate'}do local native=s.env[key];s.env[key]=function(...)reads=reads+1;return native(...)end end
 s.env.FluxWindowFrame={GetActiveTab=function()reads=reads+1;return'party'end}
 s.env.MailFrame={IsForbidden=function()reads=reads+1;return false end,IsShown=function()reads=reads+1;return true end,IsVisible=function()reads=reads+1;return true end}
 event(s,'PLAYER_REGEN_DISABLED',s.payload,s.secret);event(s,'PLAYER_REGEN_ENABLED',s.payload);event(s,'PLAYER_REGEN_DISABLED')
 check(s.clockReads==clock and s.heapReads==heap and reads==0,'actual regen delivery adds no clock/time/unit/combat/framerate/context getter');balanced(s,r)
 update(s,4);check(r.enterFirstUnmeasured==2 and r.exitFirstUnmeasured==1 and not r.enterWorst.present,'first boundary explicitly unmeasured')
 s.now=.01;event(s,'PLAYER_REGEN_DISABLED');event(s,'PLAYER_REGEN_ENABLED');event(s,'PLAYER_REGEN_DISABLED');update(s,.01)
 check(r.enterSampledEvents==2 and r.exitSampledEvents==1 and r.enterSampledFrames==1 and r.exitSampledFrames==1,'multiple delivered events preserve counts, share a frame')
 check(r.enterWorst.present and r.enterWorst.gapMs==10 and r.enterWorst.at==.01 and report.spikeCount==0,'subthreshold worst retained separately')
 s.now=.02;event(s,'PLAYER_REGEN_ENABLED');update(s,0);check(r.exitSampledFrames==2,'valid zero is sampled')
 for i=1,30 do s.now=.02+i*.05;update(s,.05)end
 check(report.spikeCount==30 and #report.spikes==20 and r.enterWorst.gapMs==10,'ring reuse cannot erase event worst')
 event(s,'PLAYER_REGEN_DISABLED');event(s,'PLAYER_REGEN_ENABLED');balanced(s,r);stop(s);balanced(s,r)
 check(r.enterStoppedUnmeasured==1 and r.exitStoppedUnmeasured==1 and model.plain(report),'stop drains pending and primitive report remains bounded')
 check(f.events.PLAYER_REGEN_DISABLED==nil and f.events.PLAYER_REGEN_ENABLED==nil,'stop unregisters both owned regen events')
end
do
 local s=new();local r=start(s).combatTransitions;update(s,.01);event(s,'PLAYER_REGEN_DISABLED');local get=s.env.GetTime;local once=false
 s.env.GetTime=function()if not once then once=true;event(s,'PLAYER_REGEN_ENABLED')end;return get()end
 s.now=.02;update(s,.02);check(r.enterSampledEvents==1 and r.exitSampledEvents==0,'event during existing read stays pending for next frame');balanced(s,r)
 s.env.GetTime=get;s.now=.03;update(s,.03);check(r.exitSampledEvents==1 and r.exitWorst.gapMs==30,'detached batch cannot absorb later delivery');stop(s)
end
do
 local s=new();local report=start(s);local r=report.combatTransitions;update(s,.01);event(s,'PLAYER_REGEN_DISABLED');local get=s.env.GetTime;local held=state(s)
 s.env.GetTime=function()s.env.GetTime=get;event(s,'PLAYER_REGEN_ENABLED');s.capture.StopWatch('during-read');return get()end
 update(s,.02);check(r.enterStoppedUnmeasured==1 and r.exitStoppedUnmeasured==1,'stop drains private inflight and pending exactly once');balanced(s,r);check(s.detached(),'stop during update detaches')
 check(held.pendingEnter==0 and held.pendingExit==0 and held.inflightEnter==0 and held.inflightExit==0,'actual stopped in-read state drains both batches')
end
-- Raw read errors and recursive same-owner Update never leave permanent busy state.
for _,raw in ipairs{'table','false'}do
 local s=new();local r=start(s).combatTransitions;update(s,.01);event(s,'PLAYER_REGEN_DISABLED');local get=s.env.GetTime;local marker={}
 s.env.GetTime=function()s.env.GetTime=get;if raw=='false'then error(false,0)else error(marker,0)end end
 local ok,err=pcall(update,s,.02);check(not ok and(raw=='false'and err==false or raw=='table'and rawequal(err,marker)),'raw update error identity preserved')
 check(state(s).updating==nil and r.enterInvalidUnmeasured==1,'raw update error releases guard and finalizes detached batch')
 event(s,'PLAYER_REGEN_ENABLED');s.now=.03;update(s,.03);check(r.exitFirstUnmeasured==1 and r.exitSampledEvents==0,'watch recovers without inventing a prior boundary after raw read error');stop(s)
end
do
 local s=new();local report=start(s);local r=report.combatTransitions;update(s,.01);event(s,'PLAYER_REGEN_DISABLED');local get=s.env.GetTime;local once=false
 s.env.GetTime=function()if not once then once=true;event(s,'PLAYER_REGEN_ENABLED');update(s,.03)end;return get()end
 s.now=.02;update(s,.02);check(r.enterSampledEvents==1 and r.exitSampledEvents==0 and report.frameCount==2,'recursive update does not replace inflight batch')
 s.env.GetTime=get;update(s,.02);check(r.exitSampledEvents==1,'recursive delivery remains next-frame pending');stop(s)
end
-- Public/foreign frame wrappers observe exactly the original native arity.
do
 local s=new();local create=s.env.CreateFrame;local calls={}
 s.env.CreateFrame=function(...)
  local f=create(...)
  for _,name in ipairs{'SetScript','RegisterEvent','UnregisterEvent','Show','Hide'}do
   local method=name;local native=f[method]
   f[method]=function(self,...)
    local count=select('#',...);calls[method]=(calls[method]or 0)+1
    check(count==(method=='SetScript'and 2 or(method=='Show'or method=='Hide')and 0 or 1),'exact '..method..' argument arity')
    return native(self,...)
   end
  end
  return f
 end
 start(s);stop(s);check(calls.Hide==1 and calls.UnregisterEvent==3,'all3 cleanup registrations and hide observed')
end
-- Stop during a label lookup must leave a stopped report printable on Lua5.1.
do
 local s=new();local report=start(s)
 s.flux.Events.GetCallbackOrigin=function()s.capture.StopWatch('label-stop');return'foreign-origin'end
 local ok,err=pcall(s.emit,'Events','label',20,false)
 check(ok and s.detached(),'stop during label lookup returns safely: '..tostring(err))
 check(report.callbackCount==0 and #report.callbacks==0,'incomplete callback metadata is not published')
 local printed,printError=pcall(s.capture.PrintSpikes);check(printed,'stopped report remains printable: '..tostring(printError))
end
-- A status read cannot combine A's time with replacement B's report/deadline.
do
 local s=new();start(s);local get=s.env.GetTime;local b
 s.env.GetTime=function()s.env.GetTime=get;s.capture.StopWatch('status-replaced');check(s.capture.StartWatch(90,50),'status B starts');b=s.capture.GetActiveWatchReport();return get()-10 end
 local status=s.capture.WatchStatus();check(status.active and status.secondsRemaining==nil and s.capture.GetActiveWatchReport()==b,'status owner change omits stale remaining time');stop(s)
end
-- Malformed/private time values are full-module controls, not helper-only claims.
for _,bad in ipairs{'private','numeric-private','nan','inf','negative','string','overflow','backward','private-previous','private-start','private-elapsed','nan-elapsed','inf-elapsed','negative-elapsed','string-elapsed'}do
 local s=new();local report=start(s);local r=report.combatTransitions;if bad=='backward'then s.now=1 end;update(s,.01);event(s,'PLAYER_REGEN_DISABLED')
 local get=s.env.GetTime;local elapsed=.05
 if bad=='overflow'then elapsed=1e308
 elseif bad=='private-elapsed'then elapsed=s.secret
 elseif bad=='nan-elapsed'then elapsed=0/0
 elseif bad=='inf-elapsed'then elapsed=math.huge
 elseif bad=='negative-elapsed'then elapsed=-1
 elseif bad=='string-elapsed'then elapsed='bad'
 elseif bad=='numeric-private'then local secret=s.env.issecretvalue;s.env.issecretvalue=function(v)return v==777 or secret(v)end;s.env.GetTime=function()return 777 end
 elseif bad=='private-previous'then state(s).previousTime=s.secret
 elseif bad=='private-start'then state(s).started=s.secret
 else local value=bad=='private'and s.secret or bad=='nan'and 0/0 or bad=='inf'and math.huge or bad=='negative'and-1 or bad=='string'and'bad'or .5;s.env.GetTime=function()return value end end
 local ok,err=pcall(update,s,elapsed);check(ok,'malformed full-module timing safe: '..bad..' '..tostring(err))
 check(r.enterInvalidUnmeasured==1 and not r.enterWorst.present and report.spikeCount==0,'invalid interval never invents zero or legacy numeric row: '..bad)
 s.env.GetTime=get;if bad=='private-start'then state(s).started=0 end
 s.now=.2;update(s,.05);check(r.enterSampledEvents==0,'invalid batch never rolls forward');stop(s);balanced(s,r);check(model.plain(report),'invalid value never serialized')
end
for _,mode in ipairs{'private','nan','inf','negative','missing','raw-error'}do
 local s=new();local report=start(s);local r=report.combatTransitions;update(s,.01);event(s,'PLAYER_REGEN_DISABLED');local native=s.env.debugprofilestop;local marker={}
 if mode=='missing'then s.env.debugprofilestop=nil
 else s.env.debugprofilestop=function()if mode=='raw-error'then error(marker,0)elseif mode=='private'then return s.secret elseif mode=='nan'then return 0/0 elseif mode=='inf'then return math.huge else return-1 end end end
 s.now=.02;local ok,err=pcall(update,s,.02)
 if mode=='raw-error'then check(not ok and rawequal(err,marker)and r.enterInvalidUnmeasured==1,'raw diagnostic-clock error preserved as unmeasured')
 else check(ok and r.enterSampledEvents==1 and r.enterWorst.gapMs==20,'unavailable/private diagnostic clock does not invalidate public gap')end
 s.env.debugprofilestop=native;stop(s);balanced(s,r)
end
do
 local s=new();local report=start(s);local r=report.combatTransitions
 for i=1,40 do s.tick(.001)end
 check(r.enters==0 and r.exits==0 and r.enterSampledFrames==0 and r.exitSampledFrames==0 and not r.enterWorst.present and not r.exitWorst.present,'zero deliveries differ from discarded/eligible intervals')
 stop(s);balanced(s,r)
end
do
 local s=new();local r=start(s).combatTransitions;update(s,.01);event(s,'PLAYER_REGEN_DISABLED');s.now=.02;update(s,0)
 check(r.enterWorst.present and r.enterWorst.gapMs==0,'first actual zero has explicit sample presence');stop(s)
end
-- Exercise successful expiry and logout after adding the extra owned events.
for _,reason in ipairs{'expiry','logout'}do local s=new();local report=start(s);event(s,'PLAYER_REGEN_DISABLED')
 if reason=='expiry'then s.now=31;update(s,.01)else event(s,'PLAYER_LOGOUT')end
 check(s.detached()and report.status==(reason=='expiry'and'expired'or'logout'),'normal '..reason..' retained');balanced(s,report.combatTransitions)
end
print('COMBAT_WATCH_FUNCTIONAL '.._VERSION..' scenes='..scenes..' checks='..checks..' actual complete module; no native or CPU benchmark')
