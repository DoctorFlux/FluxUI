-- Capture source identity once at subscription, never on a gameplay callback.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/perf_callback_observer.lua'):match('^(.-)local branches ='))
local fixture=assert(load(prefix..'\nreturn fixture','@regen-origin-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
 local s=fixture(client);local service=s.flux.Events;local stacks,runs=0,0
 local secret=setmetatable({}, {__index=function()error('inspected private stack')end,__tostring=function()error('formatted private stack')end})
 local priorType,priorSecret=s.env.type,s.env.issecretvalue
 s.env.type=function(v)if rawequal(v,secret)then return 'string'end;return priorType(v)end
 s.env.issecretvalue=function(v)return rawequal(v,secret)or priorSecret(v)end
 s.env.debugstack=function(start,lines,tail)
  stacks=stacks+1
  check(start==2 and lines==5 and tail==0,'stack lookup is bounded at registration')
  return '[C]: in function pcall\nInterface/AddOns/_FluxUI/Core/Engine/Events.lua:200\nInterface/AddOns/_FluxUI/Core/ButtonFX/Glow.lua:2001: in function Start\n'
 end
 local fn=function(event,arg)check(event=='PLAYER_REGEN_ENABLED'and arg==s,'callback arguments remain native');runs=runs+1 end
 service.Register('PLAYER_REGEN_ENABLED',fn)
 check(service.GetCallbackOrigin(fn):find('Glow.lua:2001',1,true),'anonymous regen subscriber resolves to its real registration source')
 service.Register('PLAYER_REGEN_ENABLED',fn)
 check(stacks==1,'same function registration does not repeat stack collection')
 local normal=function()end;service.Register('EXAMPLE',normal)
 check(stacks==1 and service.GetCallbackOrigin(normal)==nil,'other event subscriptions have no provenance work')
 local rows={};local stop=assert(service.ObserveTiming(function(...)rows[#rows+1]={...}end))
 for _=1,20 do s:fire('PLAYER_REGEN_ENABLED',s)end
 check(runs==40 and #rows==40 and stacks==1,'observed gameplay dispatch reuses source metadata without stack calls')
 stop();service.Unregister('PLAYER_REGEN_ENABLED',fn)
 check(service.GetCallbackOrigin(fn):find('Glow.lua:2001',1,true),'source provenance remains usable by retained spike records')
 local enter=function()end;service.Register('PLAYER_REGEN_DISABLED',enter)
 check(service.GetCallbackOrigin(enter):find('Glow.lua:2001',1,true),'combat entry has the same bounded registration provenance')
 local scheduler=s.flux.Scheduler
 s.env.debugstack=function()stacks=stacks+1;return 'Interface/AddOns/_FluxUI/Core/Engine/Scheduler.lua:160\nInterface/AddOns/_FluxUI/Bars/Watch.lua:505' end
 local listener=function()end;scheduler.Register('eval',listener)
 check(scheduler.GetCallbackOrigin(listener):find('Bars/Watch.lua:505',1,true),'anonymous tier listeners resolve to registration file')
 local prior=stacks;scheduler.Register('display',listener)
 check(stacks==prior,'shared tier callback keeps one bounded source lookup')
 for _=1,20 do scheduler.Request('eval','origin');s:nextFrame()end
 check(stacks==prior,'scheduler dispatch never collects a stack')
 for _,mode in ipairs{'missing','error','secret','malformed'}do
  local f=function()end
  s.env.debugstack=mode=='missing'and false or function()
   stacks=stacks+1
   if mode=='error'then error('metadata unavailable')end
   if mode=='secret'then return secret end
   return 3
  end
  check(service.Register('PLAYER_REGEN_ENABLED',f),'optional missing or restricted metadata cannot reject a native subscriber')
  check(service.GetCallbackOrigin(f)==nil,'unavailable source metadata remains explicitly unknown')
  local before=stacks;service.Register('PLAYER_REGEN_ENABLED',f)
  check(stacks==before,'failed optional source lookup is not repeatedly retried')
 end
end
print('Regen callback origin: '..checks..' checks PASS; one bounded registration lookup; no dispatch stacks/payload reads; five client models; native attribution pending')
