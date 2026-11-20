-- Actual Action/Combat owners; native binding APIs are modeled, not taint proof.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local path='ExtraButtonSystem/Engine/Action.lua'
if arg and arg[1]=='--source' then path=assert(arg[2]) end
local function loadenv(body,label,env)
 if _VERSION=='Lua 5.1' then local f,err=loadstring(body,label);if f then setfenv(f,env)end;return f,err end
 return load(body,label,'t',env)
end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function fixture(supported)
 local s={supported=supported,locked=false,creates=0,clears=0,binds={},frames={},timers={}}
 local e=setmetatable({}, {__index=_G});e._G=e;e.FluxButton={};e.UIParent={}
 e.InCombatLockdown=function()return s.locked end
 e.CreateFrame=function(_,name)
  local f={scripts={},events={}};function f:RegisterEvent(v)self.events[v]=true end
  function f:SetScript(k,v)self.scripts[k]=v end
  if name then check(not s.locked,'binding owner only created outside lockdown');s.creates=s.creates+1 end
  s.frames[#s.frames+1]=f;return f
 end
 e.ClearOverrideBindings=function()check(not s.locked,'binding clear outside lockdown');s.clears=s.clears+1;s.binds={}end
 e.GetBindingKey=function()return s.key1,s.key2 end
 e.SetOverrideBindingClick=function(_,priority,key,name,button)
  check(not s.locked and priority==false and button=='KeyBind','native binding arguments preserved');s.binds[key]=name
 end
 local flux={EBS={buttons={}},Cap={ClientSupportsSingleButtonAssistant=function()return s.supported end},
  Timer={After=function(_,fn)s.timers[#s.timers+1]=fn end},Safecall=function(fn)return pcall(fn)end}
 assert(loadenv(read('Core/Engine/Combat.lua'),'@Combat',e))('_FluxUI',{Flux=flux})
 assert(loadenv(read(path),'@Action',e))('_FluxUI',{Flux=flux})
 s.action,s.combat=flux.EBS.Action,flux.Combat;s.flux=flux
 function s:regen()self.locked=false;self.combat.Flush()end
 return s
end
for _,label in ipairs{'shared source'}do
 local s=fixture(false)
 for _=1,100 do s.locked=true;s.action.RebindAssistant();s:regen();s.action.RebindAssistant()end
 check(s.creates==0 and s.clears==0 and s.combat.PendingCount()==0,label..': unsupported transitions own no empty binding work')
 s.supported=true;s.key1,s.key2='F','SHIFT-F'
 local btn={IsAssistedCombat=true,Widget={GetName=function()return 'AssistantOne'end}}
 s.flux.EBS.buttons={btn};s.action.RebindAssistant()
 check(s.creates==1 and s.binds.F=='AssistantOne'and s.binds['SHIFT-F']=='AssistantOne',label..': enabling binds both keys')
 s.locked=true;s.key1,s.key2='R',nil;s.action.RebindAssistant();s.action.RebindAssistant()
 check(s.combat.PendingCount()==1 and s.binds.F=='AssistantOne',label..': supported lockdown coalesces without touching keys')
 s:regen();check(s.binds.F==nil and s.binds.R=='AssistantOne',label..': regen uses current keys')
 s.flux.EBS.buttons={};s.action.RebindAssistant()
 check(next(s.binds)==nil,label..': removing last assistant clears old keys')
 s.flux.EBS.buttons={btn};s.action.RebindAssistant();s.supported=false;s.locked=true;s.action.RebindAssistant()
 check(s.combat.PendingCount()==1 and s.binds.R=='AssistantOne',label..': capability loss retains existing-owner cleanup in combat')
 s:regen();check(next(s.binds)==nil and s.creates==1,label..': capability loss clears existing owner after combat')
 local u=fixture(true);u.locked=true;u.action.RebindAssistant();u.supported=false
 check(u.combat.PendingCount()==1,label..': pending supported request retained')
 u:regen();check(u.creates==0 and u.clears==0,label..': capability rechecked when deferred callback runs')
end
print('assistant binding lifecycle: '..checks..' checks PASS; native input/taint pending')
