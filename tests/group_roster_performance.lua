-- Actual roster/layout/binding/adjunct owners under controlled desktop events.
-- These operation counts do not certify native frame time, secure VM or taint.
local function read(path) local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local root=os.getenv("FLUX_ROSTER_SOURCE_ROOT") or "."
local measuring=os.getenv("FLUX_ROSTER_MEASURE")=="1"
local checks=0
local function check(v,m) assert(v,m);checks=checks+1 end
local function improved(v,m) if not measuring then check(v,m) end end
local function definition(path,marker,returned,env)
 local s=read(path);s=s:sub(1,assert(s:find(marker,1,true))-1)
 return assert(load(s.."\nreturn "..returned,"@fixture-"..path,"t",env or _G))()
end
local function metric(client,area,values)
 local out={"ROSTER",client,area};for k,v in pairs(values) do out[#out+1]=k.."="..v end
 print(table.concat(out,"|"))
end
local layoutText=read("tests/raid_header_precreation.lua")
layoutText=layoutText:sub(1,assert(layoutText:find('for _, client in ipairs({ "retail"',1,true))-1)
layoutText=layoutText:gsub('function methods:CreateFontString%(%) return frame%(nil, self%) end',[[function methods:CreateFontString()
 local f=frame(nil,self)
 f.Show=function(self)self.shown=true end
 f.Hide=function(self)self.shown=false end
 return f
end]],1)
layoutText=layoutText:gsub('return e, s\nend',[[s.nativeRoster=function()
 for _,h in ipairs(s.headers) do if h:IsVisible() then nativeUpdate(h) end end
end
return e,s,ns
end]],1)
local layoutEnv=setmetatable({arg={[1]=root}},{__index=_G})
local layoutFixture=assert(load(layoutText.."\nreturn fixture","@roster-layout-fixture","t",layoutEnv))()
local extraFixture=definition("tests/raid_healer_extras.lua","local function exercise(client,body)","fixture")
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"}) do
 do
  local e,s=layoutFixture(client,false,true,true,false,true)
  local function drain()for _=1,12 do if #s.timers==0 then return end;s:flush()end;error("unbounded readiness timers")end
  e.FluxRaid_OnRosterOrPartyChanged();drain()
  check(e.FluxRaidState.secureConfigured and s.children==80,"first roster event retains full startup/capacity preparation")
  e.FluxRaidState.secureRosterPrepared=false;s.secureSupported=false
  e.FluxRaid_OnRosterOrPartyChanged();drain()
  check(not e.FluxRaidState.secureConfigured and not s.nativeHidden,"lost preparation/capability keeps native fallback")
 end
 for _,raid in ipairs({false,true}) do
  local e,s,ns=layoutFixture(client,raid,true,true,false,true)
  local party,extras,syncs=0,0,0
  ns.PartyFrames={ApplyOptions=function()party=party+1 end}
  e.FluxRaidHealerExtras={RefreshLayout=function()extras=extras+1 end}
  e.FluxRaid_SyncHeaderChildUnits=function()syncs=syncs+1 end
  local function drain() for _=1,12 do if #s.timers==0 then return end;s:flush() end;error("unbounded layout timer chain") end
  s:configure();drain();check(e.FluxRaidState.secureConfigured and e.FluxRaidState.secureRosterPrepared,"initial universal roster ready")
  local capacity=s.children;local writes,shows,timers=s.writes,s.headerShows,s.timersCreated
  party,extras,syncs=0,0,0
  for _=1,20 do s.roster=5;s.nativeRoster();e.FluxRaid_OnRosterOrPartyChanged() end
  drain()
  metric(client,raid and "raid" or "party",{attributes=s.writes-writes,headerShows=s.headerShows-shows,
    partyLayouts=party,extraLayouts=extras,unitSyncs=syncs,timers=s.timersCreated-timers,allocations=s.children-capacity})
  improved(s.writes==writes and s.headerShows==shows,"invite burst does not reset prepared header attributes/visibility")
  improved(party==0 and extras==0 and syncs==1,"one roster reconciliation, no party/extra layout rebuild")
  check(s.children==capacity,"roster change reuses preallocated capacity")
  writes=s.writes;s.combat=true
  for _=1,20 do e.FluxRaid_OnRosterOrPartyChanged() end
  drain();check(s.writes==writes and s.children==capacity and s.blocked==0,"combat roster path performs no ordinary protected writes or allocations")
  s.combat=false;e.FluxRaid_RunPendingCombatWork();drain()
  check(e.FluxRaidState.secureConfigured,"postcombat reconciliation remains ready")
  party=0;s:configure();drain();check(party>0,"explicit option changes still apply full party configuration")
  e.FluxOptions.GetRaidFrameDB=function()return {useFluxRaidFrames=true,partyAsRaid=false}end
  ns.PartyFrames.ready=false
  ns.PartyFrames.ApplyOptions=function()party=party+1;ns.PartyFrames.ready=true end
  party=0;e.FluxRaid_OnRosterOrPartyChanged();drain()
  check(party>0 and ns.PartyFrames.ready,"incomplete player-style party setup retries despite prepared raid headers")
 end
 -- Real binding module, with timer queue and actual secure cast programs.
 local bindSource=read(root.."/Binding/Input/FluxMouseoverKeybind.lua")
 local prefix=read("tests/raid_binding_cast.lua")
 prefix=prefix:sub(1,assert(prefix:find("local function exercise(client, body)",1,true))-1)
 prefix=prefix:gsub('e.C_Timer = { After = function%(%) end }',[[e.rosterTimers={}
 e.C_Timer={After=function(_,fn)e.rosterTimers[#e.rosterTimers+1]=fn end}]],1)
 prefix=prefix:gsub('return e, module, cell, fire, route, event','return e, module, cell, fire, route, event, ns',1)
 local fixture=assert(load(prefix.."\nreturn fixture","@roster-binding-fixture","t",_G))()
 local e,module,cell,fire,route,event,ns=fixture(client,bindSource)
 local function drain()for _=1,12 do if #e.rosterTimers==0 then return end;local q=e.rosterTimers;e.rosterTimers={};for _,f in ipairs(q)do f()end end;error("unbounded binding timers")end
 drain();local members={}
 for i=1,40 do local f=cell("FluxRaidGrp1Unit"..i,true);members[i]=f;module:RegisterFrame(f) end
 route({"Q"},{"/cast [@mouseover,help,nodead] Heal"});drain()
 local discover,keys=0,0
 ns.FluxRaidRegisterAllMouseoverKeybindFrames=function()discover=discover+1;for _,f in ipairs(members)do module:RegisterFrame(f)end end
 local getter=e.GetBindingKey;e.GetBindingKey=function(...)keys=keys+1;return getter(...)end
 local writes=e.writes
 for _=1,20 do event("GROUP_ROSTER_UPDATE") end
 local timerCount=#e.rosterTimers;drain()
 metric(client,"binding",{discoveries=discover,keyQueries=keys,timers=timerCount,protectedWrites=e.writes-writes})
 improved(discover==1 and keys==0 and timerCount==1,"roster discovery is single/coalesced and does not rebuild stable binding data")
 local oldKeys=keys;event("EDIT_MODE_LAYOUTS_UPDATED");drain()
 check(keys>oldKeys,"Edit Mode still refreshes secure routing when its layout changes")
 local fresh=cell("FluxRaidGrp2Unit1",true);members[#members+1]=fresh
 event("GROUP_ROSTER_UPDATE");drain()
 local late=cell("FluxRaidGrp2Unit2",true);members[#members+1]=late
 e.combat=true;writes=e.writes
 fire(fresh,"OnEnter");check(fresh.binds.Q~=nil,"newly discovered frame retains prepared hover cast in combat")
 fire(fresh,"OnHide");check(not next(fresh.binds),"hide clears hover route")
 for _=1,20 do event("GROUP_ROSTER_UPDATE")end;drain()
 check(e.writes==writes,"combat registration postpones all ordinary protected writes")
 e.combat=false;event("PLAYER_REGEN_ENABLED");drain()
 e.combat=true;fire(late,"OnEnter");check(late.binds.Q~=nil,"frames discovered during combat register on the deferred flush")
 fire(late,"OnHide");e.combat=false
 -- Actual optional 45-pet/target adjunct module; native visibility is prepared.
 local e,db,extras,make,shown,units,ns=extraFixture(client,read(root.."/RaidFrame/FluxRaidHealerExtras.lua"))
 local q={};e.C_Timer={After=function(_,f)q[#q+1]=f end}
 local function drain() local batch=q;q={};for _,f in ipairs(batch)do f()end end
 db.showPets,db.showFriendlyTarget,db.showMissingClassBuffs=true,true,false
 extras.RefreshLayout();local pets,target=extras.GetExtraCells();check(#pets==45 and target,"all future optional slots prepared")
 local binds=0;e.FluxRaid_BindUnit=function(f,unit)f.unit=unit;binds=binds+1;if unit then e.FluxRaid_PaintUnit(f)end end
 local mutations,allocations,paints=e.mutations,e.cellCount,e.paintCount
 for _=1,20 do extras.OnEvent("GROUP_ROSTER_UPDATE")end;local timerCount=#q;drain()
 metric(client,"extras",{protectedWrites=e.mutations-mutations,rebinds=binds,allocations=e.cellCount-allocations,paints=e.paintCount-paints,timers=timerCount})
 improved(e.mutations==mutations and binds==0 and timerCount==1,"extra slots retain drivers/geometry/bindings during roster bursts")
 check(e.cellCount==allocations,"no adjunct allocations on invites")
 e.combat=true;mutations=e.mutations;extras.OnEvent("GROUP_ROSTER_UPDATE");drain();check(e.mutations==mutations,"combat adjunct roster event is paint-only")
 db.showPets=false;extras.RefreshLayout();check(e.mutations==mutations,"combat option change remains deferred")
 e.combat=false;extras.OnEvent("PLAYER_REGEN_ENABLED");check(not pets[1].driver,"pending option disable still retires driver after combat")
 db.showPets=true;e.support=false;extras.RefreshLayout();check(extras.extraStatus~=nil,"unavailable adjunct driver records recovery state")
 e.support=true;extras.OnEvent("GROUP_ROSTER_UPDATE");drain()
 check(extras.extraStatus==nil and pets[1].driver,"roster event retries a previously unavailable optional driver")
end
-- Use the actual cell batching path: repeated header syncs paint once per frame.
local unit=read(root.."/RaidFrame/FluxRaidUnit.lua")
local first=assert(unit:find("local pendingPaint, paintDriver, paintArmed",1,true))
local last=assert(unit:find("local function OnUnitEvent",first,true))
local a=assert(unit:find("function FluxRaid_SyncHeaderChildUnits()",1,true));local b=assert(unit:find("function FluxRaid_ApplyChromeToChildren",a,true))
local frames={};for i=1,40 do local f={unit="raid"..i};function f:GetAttribute()return self.unit end;function f:IsVisible()return true end;frames[i]=f end
local paint,scripts=0,{}
local e=setmetatable({CreateFrame=function()return{SetScript=function(_,k,v)scripts[k]=v end}end,
 FluxRaid_ForEachHeaderChild=function(fn)for _,f in ipairs(frames)do fn(f)end end,
 FluxRaid_PaintUnit=function()paint=paint+1 end,FluxRaid_RequestJoinedBorderRefresh=function()end,
 FluxRaid_IsFluxRaidEnabled=function()return true end},{__index=_G});e._G=e
assert(load(unit:sub(first,last-1)..unit:sub(a,b-1),"@real-cell-paint-batching","t",e))()
for _=1,20 do e.FluxRaid_SyncHeaderChildUnits()end
local syncPaints=paint;if scripts.OnUpdate then scripts.OnUpdate()end
metric("all","paint",{synchronous=syncPaints,total=paint})
improved(syncPaints==0 and paint==40,"forty active cells paint once after repeated syncs")
-- Actual party show/roster handlers share the paint batch, including pet slots.
local party=read(root.."/UnitFrames/FluxUnitFrames_Party.lua")
local partyPaints,resets,refreshes,ranges,ready=0,0,0,0,0
local timers={}
local e=setmetatable({C_Timer={After=function(_,fn)timers[#timers+1]=fn end},
 Paint=function()partyPaints=partyPaints+1 end,
 FluxRaid_EnsureRangePoll=function()ranges=ranges+1 end,
 Party={UpdateIndicators=function()ready=ready+1 end,ApplyTextModes=function()end,SyncCastCover=function()end},
 ns={CastBar={ResetCastForUnit=function()resets=resets+1 end,RefreshCastForUnit=function()refreshes=refreshes+1 end}},
 INDICATOR_EVENTS={READY_CHECK=true}},{__index=_G});e._G=e
local a=party:find("local rosterPaintPending",1,true)
if a then local b=assert(party:find("local function Build(unit",a,true))
 e.QueueRosterPaint=assert(load(party:sub(a,b-1).."\nreturn QueueRosterPaint","@actual-party-roster-batch","t",e))() end
local a=assert(party:find('local sharedEvent = frame:GetScript("OnEvent")',1,true))
local b=assert(party:find('frame:HookScript("OnHide"',a,true))
local setup=assert(load(party:sub(a,b-1),"@actual-party-roster-event-handlers","t",e))
local members={}
for i=1,8 do
 local f={unit=i<=4 and "party"..i or "partypet"..(i-4),_fluxPartyPet=i>4,hooks={},scripts={}}
 if i<=4 then f.CastBar={} end
 function f:IsVisible()return true end
 function f:GetScript(key)return self.scripts[key]end
 function f:SetScript(key,value)self.scripts[key]=value end
 function f:HookScript(key,value)self.hooks[key]=value end
 members[i]=f;e.frame=f;setup();f.hooks.OnShow(f)
end
for _=1,20 do for _,f in ipairs(members)do f.scripts.OnEvent(f,"GROUP_ROSTER_UPDATE")end end
members[1].scripts.OnEvent(members[1],"READY_CHECK");check(ready==1,"ready-check notification stays immediate")
local queued=#timers;local batch=timers;timers={};for _,fn in ipairs(batch)do fn()end
metric("all","partyPaint",{paints=partyPaints,castResets=resets,castRefreshes=refreshes,rangeChecks=ranges,timers=queued})
improved(partyPaints==8 and resets==4 and refreshes==4 and ranges==1 and queued==1,"party/pet show and roster paints coalesce with cast reset and range wake")
print("Group roster performance: "..checks.." checks PASS; operation counts only; native performance/taint pending")
