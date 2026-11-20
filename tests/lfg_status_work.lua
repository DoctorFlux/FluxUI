-- Load the actual fallback LFG microbutton. Native LFG/timer/frame endpoints
-- are modeled; this establishes bounded callback work, not native latency.
local path='MicroMenu/FluxLFGMicroButton.lua'
if arg and arg[1]=='--source'then path=assert(arg[2])end
local function read(p)local f=assert(io.open(p,'rb'));local b=f:read('*a');f:close();return b end
local function loadenv(b,p,e)
 if _VERSION=='Lua 5.1'then local f,err=loadstring(b,p);if f then setfenv(f,e)end;return f,err end
 return load(b,p,'t',e)
end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local function fixture(nativeTimer)
 local s={now=0,frames={},timers={},queries=0,entryQueries=0,queueQueries=0,paints=0,apps={},listed=false}
 local e=setmetatable({}, {__index=_G});e._G=e;e.LFGMinimapFrame={};e.GetTime=function()return s.now end
 e.CreateFrame=function()
  local f={scripts={},events={},shown=true}
  function f:RegisterEvent(v)self.events[v]=true end
  function f:SetScript(k,v)self.scripts[k]=v end
  function f:HookScript(k,v)self.scripts[k]=v end
  function f:IsVisible()return self.shown end
  function f:RegisterForClicks()end
  function f:CreateTexture()return self end
  function f:SetPoint()end;function f:SetTexture()end
  function f:SetTexCoord()s.paints=s.paints+1 end
  s.frames[#s.frames+1]=f;return f
 end
 e.FluxMicroMenu={Rebuild=function()end,CreateMicroButton=function(_,name)
  local b=e.CreateFrame();e[name]=b;s.btn=b;return b
 end}
 e.C_LFGList={GetApplications=function()
  s.queries=s.queries+1
  if s.fail then s.fail=false;error(s.marker,0)end
  if s.reenter then s.reenter=false;s:event('GROUP_ROSTER_UPDATE')end
  return s.apps
 end,GetApplicationInfo=function(id)return id,s.status end,
 HasActiveEntryInfo=function()s.entryQueries=s.entryQueries+1;return s.listed end}
 e.GetLFGQueueStats=function()s.queueQueries=s.queueQueries+1;return false,s.queued,nil,nil,nil,s.queueCount end
 if nativeTimer then e.C_Timer={After=function(delay,fn)s.timers[#s.timers+1]={at=s.now+delay,delay=delay,fn=fn}end}end
 assert(loadenv(read(path),'@LFGMicroButton',e))()
 for _,f in ipairs(s.frames)do if f.events.GROUP_ROSTER_UPDATE then s.eventFrame=f end end
 check(s.btn and s.eventFrame,'actual fallback button and status owner loaded')
 function s:event(name)self.eventFrame.scripts.OnEvent(self.eventFrame,name)end
 function s:advance(delta)
  self.now=self.now+delta
  local q=self.timers;self.timers={}
  for _,t in ipairs(q)do if t.at<=self.now then t.fn()else self.timers[#self.timers+1]=t end end
 end
 if nativeTimer then s:advance(.1)end -- Existing startup retries only recheck creation.
 return s
end
do
 local s=fixture(true);local q=s.queries
 local events={'GROUP_ROSTER_UPDATE','LFG_LIST_ACTIVE_ENTRY_UPDATE','LFG_LIST_APPLICANT_UPDATED','LFG_UPDATE','LFG_QUEUE_STATUS_UPDATE','PLAYER_ENTERING_WORLD'}
 for _=1,20 do for _,name in ipairs(events)do s:event(name)end end
 check(#s.timers==1 and s.timers[1].delay==.1,'120-event join/leave burst retains one original first-event deadline')
 s:advance(.099);check(s.queries==q,'status query still waits original 0.1s delay')
 s.apps={123};s.status='invited';s:advance(.0011)
 check(s.queries==q+1 and s.btn.isAnimating,'single delayed pass sees final application state')
 local paint=s.paints;check(type(s.btn.scripts.OnUpdate)=='function','existing fallback animation owns OnUpdate')
 s.btn.scripts.OnUpdate(s.btn,.1);check(s.paints==paint+1 and s.btn.currentFrame==1,'animation retains ten-Hz frame advance')
 s.apps={};s:event('GROUP_ROSTER_UPDATE');s:advance(.1)
 check(not s.btn.isAnimating and not s.btn.scripts.OnUpdate and s.btn.currentFrame==0,'leaving final queue stops and resets eye')
 q=s.queries;s.reenter=true;s:event('GROUP_ROSTER_UPDATE');s:advance(.1)
 check(s.queries==q+1 and #s.timers==1,'event raised during query schedules another pass')
 s.listed=true;s:advance(.1);check(s.queries==q+2 and s.btn.isAnimating,'reentrant pass reads current listed state')
 s.marker={};s.fail=true;s:event('GROUP_ROSTER_UPDATE')
 local ok,err=pcall(function()s:advance(.1)end)
 check(not ok and err==s.marker,'exact query failure remains visible')
 q=s.queries;s.listed=false;s.queued=true;s.queueCount=1;s:event('GROUP_ROSTER_UPDATE');s:advance(.1)
 check(s.queries==q+1 and s.btn.isAnimating,'query error releases pending state; queue status still updates')
 s.queued=false;s:event('LFG_QUEUE_STATUS_UPDATE');s:advance(.1)
 check(not s.btn.isAnimating,'queue completion clears animation after prior error')
 check(s.entryQueries==s.queueQueries,'successful passes preserve active-entry and queue queries')
end
do
 local s=fixture(false);local q=s.queries
 for _=1,5 do s:event('GROUP_ROSTER_UPDATE')end
 check(s.queries==q+5 and #s.timers==0,'no-native-timer fallback remains immediate on every event')
end
print('LFG status work: '..checks..' checks PASS; native callback latency pending')
