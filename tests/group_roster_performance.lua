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
  local party,extras,syncs,attachments,adjunctDispatches=0,0,0,0,0
  local syncHeader,shownSync,shownAttachments
  ns.PartyFrames={ApplyOptions=function()party=party+1 end}
  e.FluxRaidHealerExtras={RefreshLayout=function()extras=extras+1 end,
    RefreshRoster=function()adjunctDispatches=adjunctDispatches+1 end}
  e.FluxRaid_SyncHeaderChildUnits=function(header,shownOnly)syncs=syncs+1;syncHeader=header;shownSync=shownOnly end
  e.FluxRaid_RefreshMTMATargetAttachments=function(shownOnly)attachments=attachments+1;shownAttachments=shownOnly end
  local function drain() for _=1,12 do if #s.timers==0 then return end;s:flush() end;error("unbounded layout timer chain") end
  s:configure();drain();check(e.FluxRaidState.secureConfigured and e.FluxRaidState.secureRosterPrepared,"initial universal roster ready")
  check(not shownSync and not shownAttachments,"configuration keeps full header coverage")
  local capacity=s.children;local writes,shows,timers=s.writes,s.headerShows,s.timersCreated
  party,extras,syncs,attachments,adjunctDispatches=0,0,0,0,0
  for _=1,20 do s.roster=5;s.nativeRoster();e.FluxRaid_OnRosterOrPartyChanged() end
  drain()
  metric(client,raid and "raid" or "party",{attributes=s.writes-writes,headerShows=s.headerShows-shows,
    partyLayouts=party,extraLayouts=extras,unitSyncs=syncs,timers=s.timersCreated-timers,allocations=s.children-capacity})
  improved(s.writes==writes and s.headerShows==shows,"invite burst does not reset prepared header attributes/visibility")
  improved(party==0 and extras==0 and syncs==1,"one roster reconciliation, no party/extra layout rebuild")
  improved(adjunctDispatches==1,"the existing layout batch owns adjunct roster dispatch")
  check((raid and syncHeader==nil and attachments==1)
    or (not raid and syncHeader==e.FluxRaidState.raidHeaders[1] and attachments==0),
    "steady compact party visits group one and skips tanks, while raid refresh covers its active groups")
  improved(shownSync and (not raid or shownAttachments),"prepared roster opts into the shown-header scan")
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
 do
  local e,s,ns=layoutFixture(client,false,true,true,false,true)
  s.group=false
  local syncs,attachments=0,0
  ns.PartyFrames={ready=true,ApplyOptions=function()end}
  e.FluxOptions.GetRaidFrameDB=function()return {useFluxRaidFrames=true,partyAsRaid=false}end
  e.FluxRaid_SyncHeaderChildUnits=function()syncs=syncs+1 end
  e.FluxRaid_RefreshMTMATargetAttachments=function()attachments=attachments+1 end
  local function drain()for _=1,12 do if #s.timers==0 then return end;s:flush()end;error("unbounded normal party timers")end
  local function roster(group,raid)
   s.group,s.raid=group,raid
   e.FluxRaid_OnRosterOrPartyChanged();drain()
  end
  s:configure();drain()
  local layout=s.secureLayoutCalls
  syncs,attachments=0,0
  roster(true,false);roster(false,false)
  metric(client,"normalPartyJoinLeave",{layouts=s.secureLayoutCalls-layout,unitSyncs=syncs,mtmaAttachments=attachments})
  check(s.secureLayoutCalls==layout and syncs==0 and attachments==0,"normal party join/leave skips fully hidden known compact pool")
  roster(true,true)
  check(s.secureLayoutCalls==layout+1 and syncs==1 and attachments==1,"conversion to raid still reconciles the compact pool")
  roster(true,false)
  check(s.secureLayoutCalls==layout+2 and syncs==2 and attachments==2,"first return to normal party still reconciles from raid")
  roster(false,false)
  check(s.secureLayoutCalls==layout+2 and syncs==2 and attachments==2,"later leave retains prepared normal party mode")
  local unexpected=e.FluxRaidState.raidHeaders[2]
  unexpected.shown=true
  roster(true,false)
  check(s.secureLayoutCalls==layout+3 and syncs==3 and attachments==3,"unexpected visible compact header takes full roster path")
  unexpected.shown=false
  roster(true,false)
  check(s.secureLayoutCalls==layout+4,"first settled roster after a visible header restores normal-party readiness")
  e.FluxRaidContainer.shown=false
  roster(false,false)
  check(s.secureLayoutCalls==layout+5 and e.FluxRaidContainer:IsShown(),"a hidden unit host still takes the full recovery path")
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
 if extras.RefreshRoster then
  check(#q==0,"prepared adjuncts have no pending timer")
 end
 local function rosterExtras()
  if extras.RefreshRoster then extras.RefreshRoster();return 0 end
  for _=1,20 do extras.OnEvent("GROUP_ROSTER_UPDATE") end
  local queued=#q
  drain()
  return queued
 end
 local binds=0;e.FluxRaid_BindUnit=function(f,unit)f.unit=unit;binds=binds+1;if unit then e.FluxRaid_PaintUnit(f)end end
 local mutations,allocations,paints=e.mutations,e.cellCount,e.paintCount
 local timerCount=rosterExtras()
 metric(client,"extras",{protectedWrites=e.mutations-mutations,rebinds=binds,allocations=e.cellCount-allocations,paints=e.paintCount-paints,timers=timerCount})
 improved(e.mutations==mutations and binds==0 and timerCount==0,"adjunct dispatch retains drivers/geometry/bindings without a separate timer")
 check(e.cellCount==allocations,"no adjunct allocations on invites")
 if extras.RefreshRoster then
  local scheduled={}
  ns.FluxRaidQueueRosterPaint=function(frame)scheduled[frame]=(scheduled[frame] or 0)+1 end
  paints=e.paintCount
  rosterExtras()
  if not measuring then
   check(e.paintCount==paints and scheduled[target]==1,"prepared roster uses the shared companion paint owner")
   local count=0;for _,n in pairs(scheduled)do check(n==1,"one request per companion");count=count+1 end
   check(count==46,"every shown pet and friendly target reaches the shared queue")
  end
  ns.FluxRaidQueueRosterPaint=nil
 end
 e.combat=true;mutations=e.mutations;rosterExtras();check(e.mutations==mutations,"combat adjunct roster event is paint-only")
 db.showPets=false;extras.RefreshLayout();check(e.mutations==mutations,"combat option change remains deferred")
 e.combat=false;extras.OnEvent("PLAYER_REGEN_ENABLED");check(not pets[1].driver,"pending option disable still retires driver after combat")
 db.showPets=true;e.support=false;extras.RefreshLayout();check(extras.extraStatus~=nil,"unavailable adjunct driver records recovery state")
 e.support=true;rosterExtras()
 check(extras.extraStatus==nil and pets[1].driver,"roster event retries a previously unavailable optional driver")
end
-- Use the actual cell batching path: repeated header syncs paint once per frame.
local unit=read(root.."/RaidFrame/FluxRaidUnit.lua")
local first=assert(unit:find("local pendingPaint, paintDriver, paintArmed",1,true))
local last=assert(unit:find("local function OnUnitEvent",first,true))
local a=unit:find("local function IsKnownHiddenHeader(",1,true) or assert(unit:find("function FluxRaid_ForEachHeaderChild(",1,true))
local b=assert(unit:find("function FluxRaid_ApplyChromeToChildren",a,true))
local reads, headers = 0, {}
local function header(size,active)
 local children={}
 for index=1,size do
  local f={unit=active and "raid"..index or nil}
  function f:GetAttribute()reads=reads+1;return self.unit end
  function f:IsVisible()return active end
  children["child"..index]=f
 end
 return {GetAttribute=function(_,key)return children[key] end}
end
for index=1,8 do headers[index]=header(5,true) end
local paint,scripts=0,{}
local e=setmetatable({CreateFrame=function()return{SetScript=function(_,k,v)scripts[k]=v end}end,
 ns={},Compat={},State={raidHeaders=headers,mtmaHeader=header(40,false)},
 FluxRaid_PaintUnit=function()paint=paint+1 end,FluxRaid_RequestJoinedBorderRefresh=function()end,
 FluxRaid_IsFluxRaidEnabled=function()return true end},{__index=_G});e._G=e
assert(load(unit:sub(first,last-1)..unit:sub(a,b-1),"@real-cell-paint-batching","t",e))()
for _=1,20 do e.FluxRaid_SyncHeaderChildUnits()end
local syncPaints=paint;if scripts.OnUpdate then scripts.OnUpdate()end
metric("all","paint",{synchronous=syncPaints,total=paint})
improved(syncPaints==0 and paint==40,"forty active cells paint once after repeated syncs")
reads,paint=0,0
e.FluxRaid_SyncHeaderChildUnits()
if scripts.OnUpdate then scripts.OnUpdate()end
local fullReads=reads
reads,paint=0,0
e.FluxRaid_SyncHeaderChildUnits(headers[1])
if scripts.OnUpdate then scripts.OnUpdate()end
metric("all","compactPartyUnitReads",{full=fullReads,scoped=reads,scopedPaints=paint})
check(fullReads==80 and reads==5 and paint==5,"compact party sync visits the active column and its five unit attributes")
-- Actual party show/roster handlers share the paint batch, including pet slots.
local party=read(root.."/UnitFrames/FluxUnitFrames_Party.lua")
local targetRosterSample=party:find('PaintTarget(member, work == "roster")',1,true)~=nil
local partyPaints,resets,refreshes,ranges,ready=0,0,0,0,0
local targetPaints,targetResets,visibleReads,eventCalls,layoutRequests=0,0,0,0,0
local timers={}
local e=setmetatable({C_Timer={After=function(_,fn)timers[#timers+1]=fn end},
 Secret=function()return false end,
 Paint=function()partyPaints=partyPaints+1 end,
 PaintTarget=function(f, rosterRefresh)
  assert(targetRosterSample and rosterRefresh or not targetRosterSample and f.reset,
   "roster target passes the identity refresh to its owner")
  targetPaints=targetPaints+1
 end,
 UF={ResetVerticalTargetHealth=function(f)targetResets=targetResets+1;f.reset=true end},
 FluxRaid_EnsureRangePoll=function()ranges=ranges+1 end,
 FluxRaid_OnRosterOrPartyChanged=function()layoutRequests=layoutRequests+1 end,
 Party={members={},pets={},targets={},UpdateIndicators=function()ready=ready+1 end,ApplyTextModes=function()end,SyncCastCover=function()end},
 ns={CastBar={ResetCastForUnit=function()resets=resets+1 end,RefreshCastForUnit=function()refreshes=refreshes+1 end}},
 INDICATOR_EVENTS={READY_CHECK=true,PARTY_LEADER_CHANGED=true,PARTY_LOOT_METHOD_CHANGED=true}},{__index=_G});e._G=e
 local batchStart=assert(party:find("local rosterPaintPending",1,true))
 local buildStart=assert(party:find("local function Build(unit",batchStart,true))
local a=assert(party:find('local sharedEvent = frame:GetScript("OnEvent")',1,true))
local b=assert(party:find('frame:HookScript("OnHide"',a,true))
local sharedRoster=party:find("function Party.QueueRosterUpdate()",batchStart,true)~=nil
local setup,enableRoster=assert(load(party:sub(batchStart,buildStart-1).."\nreturn function()\n"..party:sub(a,b-1)
  .."\nend,function(enabled)rosterEnabled=enabled end",
  "@actual-party-roster-event-handlers","t",e))()
local members={}
for i=1,8 do
 local f={unit=i<=4 and "party"..i or "partypet"..(i-4),_fluxPartyPet=i>4,hooks={},scripts={}}
 if i<=4 then f.CastBar={} end
 function f:IsVisible()visibleReads=visibleReads+1;return not self.hidden end
 function f:GetScript(key)return self.scripts[key]end
 function f:SetScript(key,value)self.scripts[key]=value end
 function f:HookScript(key,value)self.hooks[key]=value end
 members[i]=f;e.frame=f;setup();f.hooks.OnShow(f)
 if i<=4 then e.Party.members[i]=f else e.Party.pets[i-4]=f end
end
-- Extract the actual shared native event owner, or deliver the archived
-- per-frame events before measuring the common deferred paint.
local raid=read(root.."/RaidFrame/FluxRaidFrame.lua")
local first=assert(raid:find("function EventHandlers:GROUP_ROSTER_UPDATE()",1,true))
local last=assert(raid:find("function EventHandlers:PARTY_MEMBERS_CHANGED()",first,true))
e.ns.PartyFrames=e.Party
local roster=assert(load("local EventHandlers={}\n"..raid:sub(first,last-1).."\nreturn EventHandlers.GROUP_ROSTER_UPDATE",
 "@actual-raid-roster-event","t",e))()
if sharedRoster then enableRoster(true) end
for _=1,20 do
 eventCalls=eventCalls+1;roster()
 if not sharedRoster then
  for _,f in ipairs(members)do eventCalls=eventCalls+1;f.scripts.OnEvent(f,"GROUP_ROSTER_UPDATE")end
 end
end
local eventVisibleReads=visibleReads
members[1].scripts.OnEvent(members[1],"READY_CHECK");check(ready==1,"ready-check notification stays immediate")
 members[1].scripts.OnEvent(members[1],"PARTY_LEADER_CHANGED")
 members[1].scripts.OnEvent(members[1],"PARTY_LOOT_METHOD_CHANGED")
 check(ready==1,"queued roster paint absorbs redundant leader/loot paint")
local queued=#timers;local batch=timers;timers={};for _,fn in ipairs(batch)do fn()end
 members[1].scripts.OnEvent(members[1],"PARTY_LEADER_CHANGED")
 check(ready==2,"standalone leadership notification stays immediate")
metric("all","partyPaint",{paints=partyPaints,castResets=resets,castRefreshes=refreshes,rangeChecks=ranges,timers=queued})
improved(partyPaints==8 and resets==4 and refreshes==4 and ranges==1 and queued==1,"party/pet show and roster paints coalesce with cast reset and range wake")
metric("all","partyRosterDispatch",{eventCalls=eventCalls,eventVisibleReads=eventVisibleReads,layoutRequests=layoutRequests})
if sharedRoster then
 check(eventCalls==20 and eventVisibleReads==0 and layoutRequests==20,
    "one event owner queues the final roster without synchronously reading slot visibility")
 local shownTarget={_fluxPartyTarget=true,IsVisible=function()return true end}
 local hiddenTarget={_fluxPartyTarget=true,IsVisible=function()return false end}
 e.Party.targets[1],e.Party.targets[2]=shownTarget,hiddenTarget
 for _=1,20 do roster() end
 check(#timers==1 and targetResets==0,"target reset is coalesced before the next paint")
 batch=timers;timers={};batch[1]()
 check(targetPaints==1 and targetResets==(targetRosterSample and 0 or 1),"only the visible target receives one roster update")
 roster()
 enableRoster(false)
 batch=timers;timers={};batch[1]()
 check(targetPaints==1,"disabling the compact party view cancels a queued roster repaint")
 roster()
 check(#timers==0,"inactive party frames do not schedule roster paint")
 enableRoster(true)
 for _,f in ipairs(members)do f.hidden=true end
 shownTarget.IsVisible=function()return false end
 roster()
 members[1].hidden=false -- Native visibility updates before the paint callback.
 batch=timers;timers={};batch[1]()
 check(partyPaints==17 and targetPaints==1,"settled membership paints a newly visible unit without repainting hidden slots")
end

-- Pull the production roster dispatcher and paint queue into one client model.
-- The archived source still has the independent adjunct event registration.
local adjunctRoot=os.getenv("FLUX_ROSTER_ADJUNCTS_ROOT") or root
local adjunctUnit=read(adjunctRoot.."/RaidFrame/FluxRaidUnit.lua")
local adjunctLayout=read(adjunctRoot.."/RaidFrame/FluxRaidLayout.lua")
local queueStart=assert(adjunctUnit:find("local pendingPaint, paintDriver, paintArmed",1,true))
local queueEnd=assert(adjunctUnit:find("local function OnUnitEvent",queueStart,true))
local rosterStart=assert(adjunctLayout:find("function FluxRaid_OnRosterOrPartyChanged()",1,true))
local rosterEnd=assert(adjunctLayout:find("function FluxRaid_InitLayoutFrames()",rosterStart,true))
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"}) do
 local e,db,extras,make,shown,units,ns=extraFixture(client,read(adjunctRoot.."/RaidFrame/FluxRaidHealerExtras.lua"))
 local cells,timers={},{}
 db.showMissingClassBuffs=false
 for i=1,40 do
  local name="raid"..i
  local buffs={}
  for j=1,10 do buffs[j]={name="Other buff "..j} end
  units[name]={auras=buffs,mana=0}
  cells[i]=make(name)
 end
 e.C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
 e.ns,e.State,e.Compat=ns,e.FluxRaidState,e.FluxRaidCompat
 e.IsSecret=e.Compat.IsSecret
 e.ScheduleBlizzardRaidManagerReposition=function()end
 e.FluxRaid_ScheduleBlizzardGridHideCheck=function()end
 e.UpdateGroupColumnLabels=function()end
 local updates=0
 local update=extras.Update
 extras.Update=function(frame)updates=updates+1;return update(frame)end
 e.FluxRaid_PaintUnit=function(frame)e.paintCount=e.paintCount+1;extras.Update(frame)end
 e.FluxRaid_UpdateAuras=extras.Update
 e.FluxRaid_UpdateDispelHighlight=function()end
 local mark=assert(load(adjunctUnit:sub(queueStart,queueEnd-1).."\nreturn MarkPaint","@roster-buff-paint-queue","t",e))()
 assert(load(adjunctLayout:sub(rosterStart,rosterEnd-1),"@roster-buff-layout-owner","t",e))()
 local withFull,withAura
 e.RefreshPreparedRoster=function()
  for _,frame in ipairs(cells) do
   if withFull then mark(frame,"full")
   elseif withAura then mark(frame,"aura") end
  end
 end
 local function fireAndFlush(oldRegistrarFirst)
  local old=not extras.RefreshRoster
  for _=1,20 do
   if old and oldRegistrarFirst then extras.OnEvent("GROUP_ROSTER_UPDATE") end
   e.FluxRaid_OnRosterOrPartyChanged()
   if old and not oldRegistrarFirst then extras.OnEvent("GROUP_ROSTER_UPDATE") end
  end
  local due=timers;timers={}
  for _,fn in ipairs(due) do fn() end
  for _,driver in ipairs(e.allFrames) do if driver.OnUpdate then driver.OnUpdate(driver) end end
  check(#timers==0,"roster and aura paint settle without a follow-up timer")
  return #due
 end
 extras.RefreshLayout();updates=0
 local disabledTimers=fireAndFlush()
 metric(client,"adjunctDisabled",{timers=disabledTimers,updateCalls=updates,auraQueries=e.auraQueries})
 improved(disabledTimers==1 and updates==0 and e.auraQueries==0,"class-buff display alone does not schedule the optional missing-buff scan")
 db.showMissingClassBuffs=true
 extras.RefreshLayout()
 for _,mainFirst in ipairs({true,false}) do
  updates,e.auraQueries,e.paintCount=0,0,0
  withFull=true
  local timersDue=fireAndFlush(not mainFirst)
  check(shown(cells[1])==3,"optional missing buffs are still painted after a full member refresh")
  metric(client,mainFirst and "adjunctFullFirst" or "adjunctFullSecond",
    {timers=timersDue,updateCalls=updates,auraQueries=e.auraQueries,fullPaint=e.paintCount})
  improved(updates==40 and e.auraQueries==440 and e.paintCount==40,"full paints absorb optional scans in the same batch")
 end
 withFull,withAura=false,true
 updates,e.auraQueries=0,0
 units.raid1.auras[1]={name="Fortitude"}
 fireAndFlush()
 check(shown(cells[1])==2,"new aura changes missing-buff icons")
 improved(updates==40 and e.auraQueries==440,"queued aura work absorbs optional scans")
 withAura=false
 updates,e.auraQueries=0,0
 units.raid1.auras[1]={name="Unrelated"}
 fireAndFlush()
 check(updates==40 and e.auraQueries==440 and shown(cells[1])==3,"adjunct-only roster still checks each bound member")
 cells[2].shown=false
 cells[2].IsVisible=function(self) return self.shown end
 extras.Clear(cells[2])
 cells[1].unit="raid41"
 units.raid41={auras={{name="Fortitude"},{name="Spirit"},{name="Shadow Protection"}},mana=0}
 updates,e.auraQueries=0,0
 fireAndFlush()
 check(shown(cells[1])==0 and shown(cells[2])==0 and e.auraQueries==422,
   "roster reads the replacement token and leaves a hidden frame cleared")
 cells[1].unit="raid1"
 cells[2].shown=true
 db.showFriendlyTarget=true
 units.target=units.raid1
 extras.RefreshLayout()
 local _,friendlyTarget=extras.GetExtraCells()
 extras.Setup(friendlyTarget)
 updates,e.auraQueries=0,0
 fireAndFlush()
 check(shown(friendlyTarget)==3,"visible friendly target keeps its missing buff indicators")
 improved(updates==41 and e.auraQueries==451,"the friendly target full paint covers its optional scan")
 e.combat=true
 updates,e.auraQueries=0,0
 withFull=true
 local writes,allocations=e.mutations,e.cellCount
 fireAndFlush()
 check(shown(cells[1])==0 and e.auraQueries==0 and e.mutations==writes and e.cellCount==allocations,
   "roster in combat clears optional icons with zero aura queries or protected mutations")
end
print("Group roster performance: "..checks.." checks PASS; operation counts only; native performance/taint pending")
