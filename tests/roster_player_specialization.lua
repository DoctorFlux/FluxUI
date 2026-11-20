-- Actual event consumers plus shared public-identity gate. No native timing claim.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local function path(p)return arg[1]and(arg[1]..'/'..p)or p end
local core=read('Core/Engine/Events.lua');local a=assert(core:find('function Events.IsPlayerUnitEvent',1,true));local b=assert(core:find('local dispatchDepth',a,true))
local opaque=setmetatable({},{__eq=function()error('private compare')end,__tostring=function()error('private format')end})
local gateEnv=setmetatable({Events={},issecretvalue=function(v)return rawequal(v,opaque)end},{__index=_G})
gateEnv.UnitIsUnit=function(u)if u=='raid9'then return true elseif u=='unknown'then return nil elseif u=='privateResult'then return opaque end;return false end
assert(load(core:sub(a,b-1),'@actual-player-unit-gate','t',gateEnv))();local gate=gateEnv.Events.IsPlayerUnitEvent
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
for _,u in ipairs{'party1','party4','raid1','target','focus'}do check(not gate(u),'confirmed other unit ignored')end
for _,u in ipairs{'player','raid9','unknown','privateResult',opaque,false}do check(gate(u),'own/alias/unknown/private identity retains refresh')end
check(gate(nil),'missing legacy payload preserves refresh')
-- Load the complete rank module using its current production fixture.
local rankTest=read('tests/spell_rank_cost.lua');local prefix=rankTest:sub(1,assert(rankTest:find('for _,modern in ipairs{true,false}do',1,true))-1)
prefix=prefix:gsub("read%(arg%[1%]or'Bars/SpellRank.lua'%)",function()return 'read('..string.format('%q',path('Bars/SpellRank.lua'))..')'end,1)
local rankFixture=assert(load(prefix..'\nreturn fixture','@rank-roster-fixture','t',_G))()
for _,modern in ipairs{false,true}do
 local f=rankFixture(modern);f.flux.Events.IsPlayerUnitEvent=gate;f.exports.build();f.trace={}
 for i=1,40 do f.events.PLAYER_SPECIALIZATION_CHANGED('PLAYER_SPECIALIZATION_CHANGED','party'..i)end
 local _,dirty=f.exports.state();check(not dirty and #f.trace==0,'forty foreign spec events cannot invalidate the own spell-rank cache')
 f.events.PLAYER_SPECIALIZATION_CHANGED('PLAYER_SPECIALIZATION_CHANGED','player');local _,ownDirty=f.exports.state();check(ownDirty,'own spec still invalidates ranks')
end
local function callback(p,marker,ending)
 local s=read(path(p));local x=assert(s:find(marker,1,true),p);local y=assert(s:find(ending,x+#marker,true),p)
 local f=s:sub(x,y+#ending-2);local first=assert(f:find('function(',1,true));f=f:sub(first)
 return f
end
local function exercise(fn,env,work,label,direct)
 env=setmetatable(env,{__index=gateEnv});local ev={IsPlayerUnitEvent=gate};env.Ev=ev;env.Flux={Events=ev};env._G=env;env.ns=env.ns or{};env.ns.Flux=env.Flux
 local run=assert(load('return '..fn,'@'..label,'t',env))()
 for _,u in ipairs{'party1','raid1','target','focus'}do local n=work();if direct then run(nil,'PLAYER_SPECIALIZATION_CHANGED',u)else run('PLAYER_SPECIALIZATION_CHANGED',u)end;check(work()==n,label..' ignores known other units')end
 for _,u in ipairs{'player','raid9','unknown','privateResult',opaque}do local n=work();if direct then run(nil,'PLAYER_SPECIALIZATION_CHANGED',u)else run('PLAYER_SPECIALIZATION_CHANGED',u)end;check(work()>n,label..' preserves own/unknown/private refresh')end
 local n=work();if direct then run(nil,'PLAYER_SPECIALIZATION_CHANGED')else run('PLAYER_SPECIALIZATION_CHANGED')end;check(work()>n,label..' preserves missing legacy payload')
end
-- Whole stance watcher and actual registered specialization callback.
do
 local count,callbacks=0,{};local events={IsPlayerUnitEvent=gate,Register=function(k,f)callbacks[k]=f end}
 local stance={RequestDiscover=function()count=count+1 end};local env=setmetatable({},{__index=gateEnv});local flux={Events=events,Bars={Stance=stance}}
 assert(load(read(path('Bars/Stance/Watch.lua')),'@stance-watch-roster','t',env))('_FluxUI',{Flux=flux});stance.Watch.Start()
 callbacks.PLAYER_SPECIALIZATION_CHANGED('PLAYER_SPECIALIZATION_CHANGED','party1');check(count==0,'foreign spec cannot rediscover stance/layout')
 callbacks.PLAYER_SPECIALIZATION_CHANGED('PLAYER_SPECIALIZATION_CHANGED','player');check(count==1,'own spec still rediscovers stance')
end
local n=0
exercise(callback('ExtraButtonSystem/Engine/Watch.lua','Ev.Register("PLAYER_SPECIALIZATION_CHANGED", function(event, unit)','\n    end)'),{OnMacroConditional=function()n=n+1 end},function()return n end,'EBS conditionals')
n=0
exercise(callback('UnitFrames/FluxClassPower.lua','eventFrame:SetScript("OnEvent", function(self, event, ...)','\n        end)'),{ResolveClassPowerParent=function()n=n+1;return{}end,SchedulePosition=function()n=n+1 end,ns={ClassPower={UpdatePosition=function()n=n+1 end}}},function()return n end,'class power retries',true)
n=0
exercise(callback('UnitFrames/FluxUnitFrames_PlayerSpecClick.lua','evt:SetScript("OnEvent", function(_, event, unit)','\n        end)'),{OnTalentOrSpecChanged=function()n=n+1 end,OnCombatEvent=function()n=n+1 end},function()return n end,'spec controls',true)
n=0
exercise(callback('UnitFrames/FluxCastBarThemes.lua','events:SetScript("OnEvent", function(_, event, spellID)','\n        end)'),{refreshSpellMetadata=function()n=n+1 end},function()return n end,'cast metadata',true)
n=0
exercise(callback('Binding/Core/Conditions.lua','gateEvents:SetScript("OnEvent", function(_, event, unit)','\nend)'),{FluxBinding={NotifyLoadGatesChanged=function()n=n+1 end}},function()return n end,'binding load gates',true)
for _,case in ipairs{{'Core/Engine/MouseoverCast.lua','QueueClassify'},{'Core/Engine/Range.lua','Refresh'}}do
 n=0;local env={[case[2]]=function()n=n+1 end}
 exercise(callback(case[1],'Ev.Register("PLAYER_SPECIALIZATION_CHANGED", function(event, unit)','\n\tend)'),env,function()return n end,case[2])
end
n=0
exercise(callback('Core/FluxAPI/Actions.lua','spellCacheInvalidator:SetScript("OnEvent", function(self, event, unit, ...)','\n    end)'),{_FluxAPICompat_ClearSpellCache=function()n=n+1 end},function()return n end,'spell API cache',true)
n=0
exercise(callback('Core/FluxAPI/UI.lua','manaCacheFrame:SetScript("OnEvent", function(_self, event, loadedAddon)','\nend)'),{FluxAPICompat={ResetManaCache=function()n=n+1 end},ScheduleManaCacheWarm=function()n=n+1 end},function()return n end,'mana cache/grid notifications',true)
n=0
exercise(callback('Inventory/FluxConsumableBest/FluxConsumableBest.lua','f:SetScript("OnEvent", function(_, event, arg1, arg2)','\n    end)'),{OnPlayerLevelUp=function()n=n+1 end},function()return n end,'consumable selector',true)
n=0
exercise(callback('Inventory/FluxEquipSlotCandidates.lua','Flux.Events.Register("PLAYER_SPECIALIZATION_CHANGED", function(_, unit)','\n    end)'),{Candidates={Invalidate=function()n=n+1 end}},function()return n end,'equipment candidates')
n=0
exercise(callback('Other/FluxCooldownDefaults.lua','Flux.Events.Register(event, function(name, unit, ...)','\n        end)'),{Defaults={Request=function()n=n+1 end}},function()return n end,'cooldown layout defaults')
n=0
exercise(callback('Respec/FluxRespec_Core.lua','specIconRefreshFrame:SetScript("OnEvent", function(_, event, changedSlotID)','\n    end)'),{InvalidateSpecDecorCache=function()n=n+1 end,SchedulePlayerSpecIconRefreshDebounced=function()n=n+1 end},function()return n end,'respec icon cache',true)
n=0
exercise(callback('Respec/FluxRespec_UI.lua','UI._liveFrame:SetScript("OnEvent", function(self, event, unit, ...)','\n        end)'),{scheduleRefresh=function()n=n+1 end},function()return n end,'respec window refresh',true)
n=0
exercise(callback('Salvage/FluxSalvage.lua','loginFrame:SetScript("OnEvent", function(_, event, arg1)','\nend)'),{InvalidateCaches=function()n=n+1 end},function()return n end,'salvage caches',true)
print('Roster player-specialization: '..checks..' checks PASS; complete rank/stance modules and17 actual player-only callbacks;foreign notifications produce no rebuild requests/retries;aliases/private/missing cases preserve refresh. Native pending.')
