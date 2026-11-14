-- Actual Party.lua roster/event wrappers + Shared.lua power/partition/regen.
-- Native setters are permission modeled; this is not a WoW taint/FPS emulator.
-- Optional source root selects an exact external baseline; --measure records
-- its unsafe attempts without requiring the new safety/continuity assertions.
local root = (arg[1] or "."):gsub("\\", "/"):gsub("/$", "")
local measure = arg[2] == "--measure"
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function corrected(ok, why) if not measure then check(ok, why) end end
local function read(path)
    local f = assert(io.open(path,"rb"),path);local body=f:read("*a");f:close();return body:gsub("\r\n","\n")
end
local function section(body, first, last)
    local a=assert(body:find(first,1,true),first);local b=assert(body:find(last,a+#first,true),last)
    return body:sub(a,b-1)
end
local shared=read(root.."/UnitFrames/FluxUnitFrames_Shared.lua")
local fixtureText=read("tests/raid_party_frames.lua")
local first=assert(fixtureText:find('for _,client in ipairs({"live"',1,true))
local last=assert(fixtureText:find('    local opaque=setmetatable',first,true))
fixtureText=fixtureText:sub(1,last-1)
fixtureText=fixtureText:gsub('for _,client in ipairs%({"live","forever","classic","classic_era","classic_anniversary"}%)do',
    'local function partyFixture(client)',1)
fixtureText=fixtureText:gsub('read%("UnitFrames/FluxUnitFrames_Shared.lua"%)',
    'read('..string.format('%q',root..'/UnitFrames/FluxUnitFrames_Shared.lua')..')')
fixtureText=fixtureText:gsub('loadfile%("UnitFrames/FluxUnitFrames_Party.lua","t",e%)',
    'loadfile('..string.format('%q',root..'/UnitFrames/FluxUnitFrames_Party.lua')..',"t",e)',1)
local partyFixture=assert(load(fixtureText.."\nreturn e,ns,db,calls,flushTimers,refresh,deferred,secure\nend\nreturn partyFixture",
    "@reused-power-combat-party-fixture","t",_G))()

local function opaque()
    return setmetatable({opaque=true},{__lt=function()error("secret comparison")end,
        __le=function()error("secret comparison")end,__add=function()error("secret arithmetic")end,
        __sub=function()error("secret arithmetic")end,__mul=function()error("secret arithmetic")end,
        __div=function()error("secret arithmetic")end,__tostring=function()error("secret formatting")end})
end

local function build(client,permission)
    local e,ns,db,calls,drain,refresh,deferred,secure=partyFixture(client)
    local UF,P=ns.UnitFrames,ns.PartyFrames
    local facts,metrics={}, {attempts=0,blocked=0,errors=0,sinks=0,regen=0,partition=0,defers=0,first="none",firstBlocked="none"}
    local nativeDefer=ns.Flux.Combat.Defer
    ns.Flux.Combat.Defer=function(key,fn)
        if key:find("unitframes.partition.",1,true)==1 then metrics.defers=metrics.defers+1 end
        return nativeDefer(key,fn)
    end
    local methods=getmetatable(e.UIParent).__index
    local function permissionCheck(self,method)
        if e.combat and e.depth==0 and self._partitionProtected then
            metrics.attempts=metrics.attempts+1
            metrics.first=metrics.first=="none" and (method..":"..(self._partitionRole or "frame")) or metrics.first
            if permission=="strict" or method=="Show" then
                if metrics.firstBlocked=="none"then metrics.firstBlocked=method..":"..(self._partitionRole or"frame")end
                metrics.blocked=metrics.blocked+1;error("ADDON_ACTION_BLOCKED "..method..":"..(self._partitionRole or "frame"))
            end
        end
    end
    -- The reused secure fixture marks every graphical mock protected. Here only
    -- actual unit-button descendants receive partition permission ownership;
    -- UIParent chrome and FontStrings retain their native decorative freedoms.
    for _,key in ipairs({"SetHeight","SetWidth","SetSize","SetPoint","ClearAllPoints","SetFrameLevel","SetFrameStrata","SetParent","SetScale","SetAllPoints"})do
        local old=methods[key]
        methods[key]=function(self,...)
            permissionCheck(self,key)
            if key=="SetHeight"then self.height=...
            elseif key=="SetWidth"then self.width=...
            elseif key=="SetSize"then self.width,self.height=...
            elseif key=="SetPoint"then self.points=self.points or{};self.point={...};self.points[#self.points+1]=self.point
            elseif key=="ClearAllPoints"then self.point=nil;self.points={}
            elseif key=="SetFrameLevel"then self.level=...
            elseif key=="SetFrameStrata"then self.strata=...
            elseif key=="SetParent"then self.parent=...
            elseif key=="SetScale"then self.scale=...
            elseif key=="SetAllPoints"then self.allpoints=...
            elseif old then return old(self,...)end
        end
    end
    function methods:Show()
        permissionCheck(self,"Show");local was=self.shown;self.shown=true
        if not was and self.scripts.OnShow then self.scripts.OnShow(self)end
    end
    function methods:Hide()
        permissionCheck(self,"Hide");local was=self.shown;self.shown=false
        if was and self.scripts.OnHide then self.scripts.OnHide(self)end
    end
    function methods:SetShown(value)if value then self:Show()else self:Hide()end end
    function methods:SetAlpha(value)self.alpha=value end -- Native value sink accepts opaque values.
    function methods:GetNumPoints()return self.points and #self.points or self.point and 1 or 0 end
    function methods:RegisterEvent(event)self.events=self.events or{};self.events[event]=true end
    function methods:UnregisterEvent(event)if self.events then self.events[event]=nil end end
    function methods:IsEventRegistered(event)return self.events and self.events[event]or false end
    function methods:GetFrameStrata()return self.strata or"MEDIUM"end
    function methods:GetFrameLevel()return self.level or 40 end
    e.now=100;e.GetTime=function()return e.now end
    e.issecretvalue=function(value)return type(value)=="table"and rawget(value,"opaque")==true end
    e.canaccessvalue=function(value)return not e.issecretvalue(value)end
    local function fact(unit)return facts[unit]or{maximum=0,current=0,powerType=0,token="MANA",exists=false}end
    e.UnitPowerType=function(unit)local f=fact(unit);return f.powerType,f.token end
    e.UnitExists=function(unit)return fact(unit).exists~=false end
    e.API.SafeUnitPower=function(unit)return fact(unit).current end
    e.API.SafeUnitPowerMax=function(unit)return fact(unit).maximum end
    e.API.IsSecretValue=e.issecretvalue;e.API.CanAccessValue=e.canaccessvalue
    e.API.GetPowerPercent100=function(unit)return fact(unit).percent or 42 end
    e.ns=ns;ns.API=e.API;e.UF=UF
    e.IsFluxUnitFrame=function()return true end
    e.GetChromeSeparatorRGB=function()return 1,1,1 end
    e.FluxUnitFrames_GetHealthPartitionPct=function()return .6 end
    e.TargetUnitUsesSideBySideTotTextLayout=function()return false end
    e.PlayerUnitUsesFluxPetLayout=function()return false end
    e.FormatValue=function(value)return e.issecretvalue(value)and"native"or tostring(value)end
    e.SetCurMaxLabel=function(label,current,maximum)label.current,label.maximum=current,maximum end
    e.SetPercentLabel=function(label,value)label.text=value end
    e.PlaceBarText=function(label,_,point,relative,relativePoint,x,y)
        if label then label:SetPoint(point,relative,relativePoint,x,y)end
    end
    e.StatusBarSetMinMaxAndValueImmediate=function(bar,minimum,maximum,value)
        bar.minimum,bar.maximum,bar.value=minimum,maximum,value;metrics.sinks=metrics.sinks+1
    end
    e.SetStatusBarFillGray=function()end
    UF.UnitIsAFKDisplay=function()return false end
    UF.UsesHudUnitBars=function()return client=="live"or client=="forever"end
    UF.PowerValueForDisplay=function(_,value)return value end
    UF.ApplyResourceBarStyle=function()end;UF.RefreshResourceConnection=function()end
    UF.UpdateResourceSpark=function()end;UF.UpdateFullResourcePulse=function()end
    UF.FrameUsesPortraitLayout=function()return false end
    UF.UpdateAtlasBorder=function()end;UF.UpdateOuterBorder=function()end
    UF.LayoutThreatBar=function()end;UF.SyncPortraitModelGeometry=function()end
    UF.UpdatePortraitCombatTint=function()end;UF.UpdateThreatBar=function()end
    UF.UpdateHealPrediction=function()end
    UF.UpdateAdditionalPower=function()end
    e.SyncRelatedWatchedFrames=function()end
    -- Exact public geometry, partition and power bodies execute together. Their
    -- unrelated visual/native value helpers are isolated at the fixture boundary.
    assert(load(section(shared,"local function ValueIsSecret(value)","local function PlayerDeadOrGhost(unit)"),
        "@power-combat-public-geometry","t",e))()
    assert(loadfile("UnitFrames/FluxUnitFrames_Lifecycle.lua","t",e))("_FluxUI",ns)
    assert(load(section(shared,"function UF.UpdatePower(self, unit)","function UF.CreatePowerBar(frame)"),
        "@power-combat-production-power","t",e))()
    assert(load(section(shared,"-- Dynamic Partitioning (Sizing)","-- Event Handling"),
        "@power-combat-production-partition","t",e))()
    local firstEvent=assert(shared:find("local OUTER_BORDER_POWER_HEALTH_THROTTLE",1,true))
    local lastEvent=assert(shared:find("-- Emulated horizontal squeeze",firstEvent,true))
    local event=assert(load(shared:sub(firstEvent,lastEvent-1).."\nreturn OnEvent",
        "@power-combat-production-shared-event","t",e))()
    local partition=UF.UpdateFramePartition
    UF.UpdateFramePartition=function(frame)
        metrics.partition=metrics.partition+1
        if not e.combat then metrics.regen=metrics.regen+1 end
        return partition(frame)
    end
    local base=UF.CreateBaseFrame
    UF.CreateBaseFrame=function(...)
        local frame=base(...)
        frame._partitionProtected=true;frame._partitionRole=frame.unit
        frame.UpdatePartition=UF.UpdateFramePartition
        frame:SetScript("OnEvent",event)
        return frame
    end
    local health=UF.CreateHealthBar
    UF.CreateHealthBar=function(frame)
        health(frame);frame.Health._partitionProtected=true;frame.Health._partitionRole=frame.unit..".Health"
    end
    local power=UF.CreatePowerBar
    UF.CreatePowerBar=function(frame)
        power(frame);frame.Power._partitionProtected=true;frame.Power._partitionRole=frame.unit..".Power"
    end
    db.partyAsRaid=false;e.mode="party";e.partyCount=0
    check(P.ApplyOptions(),client.." prepares the live party before combat")
    refresh();drain()
    local function fire(frame,name,unit)
        local fn=frame:GetScript("OnEvent");check(type(fn)=="function","production event handler exists")
        local ok,err=pcall(fn,frame,name,unit)
        if not ok then metrics.errors=metrics.errors+1;metrics.lastError=tostring(err)end
        corrected(ok,client.." "..permission.." "..name..": "..tostring(err))
        return ok
    end
    local function flush()
        local ok,err=pcall(drain)
        if not ok then metrics.errors=metrics.errors+1;metrics.lastError=tostring(err)end
        corrected(ok,client.." queued roster paint: "..tostring(err))
        return ok
    end
    return{e=e,UF=UF,P=P,facts=facts,metrics=metrics,fire=fire,flush=flush,refresh=refresh,secure=secure,event=event,deferred=deferred}
end

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
for _,permission in ipairs({"strict","show-only"})do
    local h=build(client,permission);local e,UF,P=h.e,h.UF,h.P
    local frame=P.members[1]
    -- Prepare zero-capacity/absent members OOC, then let only the actual native
    -- state owner reveal the invited unit. The ordinary queued paint is tainted.
    UF.UpdatePower(frame,frame.unit)
    frame:UpdatePartition()
    corrected(frame._fluxHasMainPower==nil and frame.Power.shown,
        "absent zero-capacity member retains unknown capacity and prepared visible resource host")
    local height,powerHeight,powerShown=frame.Health.height,frame.Power.height,frame.Power.shown
    local prepared=e.created
    e.combat=true;e.partyCount=1
    h.facts.party1={maximum=100,current=37,powerType=0,token="MANA",exists=true}
    h.refresh();h.fire(frame,"GROUP_ROSTER_UPDATE");h.flush()
    corrected(e.created==prepared,"combat join never constructs replacement frames")
    corrected(h.metrics.attempts==0,client.." combat join attempts no protected partition mutation")
    corrected(frame.Health.height==height and frame.Power.height==powerHeight and frame.Power.shown==powerShown,
        "combat join preserves prepared protected geometry/visibility")
    corrected(frame.Power.maximum==100 and frame.Power.value==37,"combat join still publishes immediate native power values")
    corrected(frame.needsPartitionRelayout and frame:IsEventRegistered("PLAYER_REGEN_ENABLED"),
        "combat join retains existing regen ownership")
    -- Repeated maximum/type changes must still update values and cannot hide
    -- errors behind pcall. Zero, present-empty, changed power type and opaque
    -- engine values are separate transitions rather than one warm steady state.
    for _,state in ipairs({{maximum=0,current=0},{maximum=100,current=0},{maximum=150,current=42,powerType=3,token="ENERGY"},
        {maximum=opaque(),current=opaque(),powerType=0,token="MANA"}})do
        state.exists=true;h.facts.party1=state
        h.fire(frame,"UNIT_MAXPOWER","party1")
        corrected(rawequal(frame.Power.maximum,state.maximum)and rawequal(frame.Power.value,state.current),
            "safe native value sinks remain current through combat partition invalidation")
        corrected(frame.Health.height==height and frame.Power.height==powerHeight and frame.Power.shown==powerShown,
            "real zero/empty/opaque maximum keeps protected prepared layout until regen")
    end
    corrected(h.metrics.attempts==0,"all late member power transitions avoid protected writes")
    -- Fresh player/focus paths use the same production partition updater and
    -- shared event dispatcher. Frames/bars already exist before entering combat.
    e.combat=false
    local extras={}
    for _,unit in ipairs({"player","focus","focustarget"})do
        local f=e.CreateFrame("Button","FluxPowerJoin_"..unit,e.UIParent)
        f.unit=unit;f._partitionProtected=true;f._partitionRole=unit;f.width,f.height=325,100
        f.UpdatePartition=UF.UpdateFramePartition;f.UpdateOuterBorder=function()end
        UF.CreateHealthBar(f);UF.CreatePowerBar(f)
        f.Health._fluxTextAnchor=e.CreateFrame("Frame",nil,f.Health)
        f.Health._fluxTextAnchor._partitionProtected=true;f.Health._fluxTextAnchor._partitionRole=unit..".HealthTextAnchor"
        if unit=="player"then
            f.AdditionalPower=e.CreateFrame("StatusBar",nil,f)
            f.AdditionalPower._partitionProtected=true;f.AdditionalPower._partitionRole="player.AdditionalPower"
        end
        if unit=="focustarget"then f._fluxHealthBarOnly=true end
        f._fluxHasMainPower=false;h.facts[unit]={maximum=0,current=0,powerType=0,token="MANA"}
        f:UpdatePartition();f:SetScript("OnEvent",h.event)
        extras[#extras+1]=f
    end
    e.combat=true
    for _,f in ipairs(extras)do
        h.facts[f.unit]={maximum=120,current=45,powerType=0,token="MANA"}
        h.fire(f,"UNIT_MAXPOWER",f.unit)
        corrected(f.Power.maximum==120 and f.Power.value==45,"shared player/focus late unit still updates native values")
        corrected(f.needsPartitionRelayout,"shared late unit retains deferred partition")
    end
    extras[1].isAdditionalPowerShown=true
    local extraOK,extraErr=pcall(extras[1].UpdatePartition,extras[1])
    if not extraOK then h.metrics.errors=h.metrics.errors+1 end
    corrected(extraOK,"additional resource transition defers protected partition: "..tostring(extraErr))
    local pending=0;for _ in pairs(h.deferred)do pending=pending+1 end
    corrected(pending==4,"one existing combat-queue key owns each affected member/player/focus frame")
    corrected(h.metrics.defers==4,"repeated combat power transitions allocate one deferred callback per frame")
    corrected(h.metrics.attempts==0,"player/focus/health-only paths attempt no protected combat mutation")
    h.facts.party1={maximum=150,current=55,powerType=0,token="MANA"}
    h.fire(frame,"UNIT_MAXPOWER","party1")
    e.combat=false
    local function deferredDrain()
        local batch={};for key,fn in pairs(h.deferred)do batch[#batch+1]=fn;h.deferred[key]=nil end
        for _,fn in ipairs(batch)do fn()end
    end
    if permission=="strict"then
        deferredDrain()
        corrected(not frame.needsPartitionRelayout,"combat-queue callback independently applies pending member partition")
        for _,f in ipairs(extras)do corrected(not f.needsPartitionRelayout,"combat-queue callback independently applies pending shared partition")end
    end
    h.fire(frame,"PLAYER_REGEN_ENABLED");h.flush()
    for _,f in ipairs(extras)do h.fire(f,"PLAYER_REGEN_ENABLED")end
    if permission=="show-only"then deferredDrain()end
    corrected(not frame.needsPartitionRelayout and frame.Power.shown,"regen applies latest resource partition and visibility")
    corrected(frame:IsEventRegistered("PLAYER_REGEN_ENABLED"),"party controller retains its permanent regen event ownership")
    corrected(frame.Power.maximum==150 and frame.Power.value==55,"regen keeps latest native values")
    for _,f in ipairs(extras)do corrected(not f.needsPartitionRelayout,"regen clears shared pending partition exactly after application")end
    corrected(h.metrics.attempts==0 and h.metrics.blocked==0 and h.metrics.errors==0,"no rejected or swallowed protected operations")
    print(string.format("POWER_COMBAT_JOIN|client=%s|permission=%s|attempts=%d|blocked=%d|errors=%d|first=%s|firstBlocked=%s|nativeSinks=%d|partitions=%d|regen=%d|defers=%d",
        client,permission,h.metrics.attempts,h.metrics.blocked,h.metrics.errors,h.metrics.first,h.metrics.firstBlocked,h.metrics.sinks,h.metrics.partition,h.metrics.regen,h.metrics.defers))
end

-- Partial external/test adapters can omit the shared combat queue. The existing
-- native regen subscription remains an independent, observable fallback owner.
local h=build(client,"strict");local e,frame=h.e,h.P.members[1]
h.UF.DeferProtected=nil
frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
e.combat=true;e.partyCount=1
h.facts.party1={maximum=100,current=23,powerType=0,token="MANA",exists=true}
h.refresh();h.fire(frame,"UNIT_MAXPOWER","party1");h.flush()
corrected(frame.needsPartitionRelayout and frame:IsEventRegistered("PLAYER_REGEN_ENABLED"),
    "missing combat helper retains a real regen event registration")
corrected(frame.Power.maximum==100 and frame.Power.value==23 and h.metrics.attempts==0,
    "regen-only fallback retains live value paints without protected writes")
e.combat=false
if frame:IsEventRegistered("PLAYER_REGEN_ENABLED")then h.fire(frame,"PLAYER_REGEN_ENABLED")end
corrected(not frame.needsPartitionRelayout and frame.Power.shown,"registered regen-only fallback applies prepared partition")
print(string.format("POWER_COMBAT_JOIN|client=%s|permission=regen-only|attempts=%d|blocked=%d|errors=%d|first=%s|firstBlocked=%s|nativeSinks=%d|partitions=%d|regen=%d|defers=%d",
    client,h.metrics.attempts,h.metrics.blocked,h.metrics.errors,h.metrics.first,h.metrics.firstBlocked,h.metrics.sinks,h.metrics.partition,h.metrics.regen,h.metrics.defers))
end
print("power partition combat join: "..checks.." checks PASS; production paths, modeled permissions; native client acceptance pending")
