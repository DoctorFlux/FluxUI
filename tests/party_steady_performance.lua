-- Steady party traffic through the actual party wrapper and shared dispatcher.
-- Counters cover addon calls only, not native CPU, secure VM, taint or rendering.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local root=os.getenv("FLUX_PARTY_STEADY_ROOT") or "."
local measure=os.getenv("FLUX_PARTY_STEADY_MEASURE")=="1"
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function improved(v,m)if not measure then check(v,m)end end
local fixtureSource=read("tests/raid_party_frames.lua")
local start=assert(fixtureSource:find('for _,client in ipairs({"live"',1,true))
local finish=assert(fixtureSource:find('    local opaque=setmetatable',start,true))
fixtureSource=fixtureSource:sub(1,finish-1)
fixtureSource=fixtureSource:gsub('for _,client in ipairs%({"live","forever","classic","classic_era","classic_anniversary"}%)do',
    'local function partyFixture(client)',1)
fixtureSource=fixtureSource:gsub('loadfile%("UnitFrames/FluxUnitFrames_Party.lua","t",e%)',
    'loadfile('..string.format('%q',root..'/UnitFrames/FluxUnitFrames_Party.lua')..',"t",e)',1)
local fixture=assert(load(fixtureSource.."\nreturn e,ns,db,calls,flushTimers,refresh\nend\nreturn partyFixture","@party-steady-fixture","t",_G))()
local shared=read(root.."/UnitFrames/FluxUnitFrames_Shared.lua")
local a=assert(shared:find("local OUTER_BORDER_POWER_HEALTH_THROTTLE",1,true))
local b=assert(shared:find("-- Emulated horizontal squeeze",a,true))
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    -- Execute the client's actual narrow dispatch contracts as well. The
    -- optional cache is Git-blob-verified by the retained comparison runner.
    local cache=os.getenv("FLUX_PARTY_STEADY_UPSTREAM")
    local nativeRoot=cache and cache.."/"..client or "../__AddonsForRef/wow-ui-source-"..client
    local family=(client=="live"or client=="forever")and"Mainline"or"Classic"
    local native=read(nativeRoot.."/Interface/AddOns/Blizzard_UnitFrame/"..family.."/UnitFrame.lua")
    local first=assert(native:find("function UnitFrame_OnEvent",1,true))
    local last=assert(native:find("\nend",first,true))+3
    local prediction,portrait,pets=0,0,0
    local model={unit="party1",GetUnit=function()return"party1"end,UpdatePet=function()pets=pets+1 end}
    local env={PartyMemberFrameMixin={},UnitHasVehicleUI=function()return false end,
        UnitFramePortrait_Update=function()portrait=portrait+1 end,
        UnitFrameHealPredictionBars_Update=function()prediction=prediction+1 end}
    assert(load(native:sub(first,last),"@native-party-unit-events","t",env))()
    for _,event in ipairs({"UNIT_HEALTH","UNIT_HEAL_PREDICTION","UNIT_ABSORB_AMOUNT_CHANGED","UNIT_HEAL_ABSORB_AMOUNT_CHANGED"})do env.UnitFrame_OnEvent(model,event,"party1")end
    check(prediction==3 and portrait==0,"pinned native dispatch separates prediction events from portraits")
    native=read(nativeRoot.."/Interface/AddOns/Blizzard_UnitFrame/"..family.."/PartyMemberFrame.lua")
    first=assert(native:find("function PartyMemberFrameMixin:OnEvent",1,true));last=assert(native:find("\nend",first,true))+3
    assert(load(native:sub(first,last),"@native-party-pet-owner-events","t",env))()
    env.PartyMemberFrameMixin.OnEvent(model,"UNIT_PET","party2");check(pets==0,"native unrelated pet owner does not update this pet")
    env.PartyMemberFrameMixin.OnEvent(model,"UNIT_PET","party1");check(pets==1,"native matching pet owner updates its pet")
    local e,ns,db,calls,drain,refresh=fixture(client)
    local UF,P=ns.UnitFrames,ns.PartyFrames
    local n={};local function inc(k)n[k]=(n[k]or 0)+1 end
    local methods=getmetatable(e.UIParent).__index
    function methods:RegisterUnitEvent(event,unit)
        self.unitEvents=self.unitEvents or {};self.unitEvents[event]=unit
    end
    function methods:RegisterEvent(event)self.events=self.events or {};self.events[event]=true end
    e.GetTime=function()return e.now or 0 end
    UF.UpdateHealPrediction=function()inc("prediction")end
    UF.UpdatePortraitCombatTint=function()inc("combatTint")end
    e.SyncRelatedWatchedFrames=function()end
    local sharedEvent=assert(load(shared:sub(a,b-1).."\nreturn OnEvent","@steady-shared-dispatcher","t",e))()
    local base=UF.CreateBaseFrame
    UF.CreateBaseFrame=function(...)
        local f=base(...);f:SetScript("OnEvent",sharedEvent)
        function f:IsEventRegistered()return true end
        local outer=f.UpdateOuterBorder
        f.UpdateOuterBorder=function(self)inc("chrome");return outer(self)end
        return f
    end
    UF.UpdateHealth=function(f)
        inc("health");f.lastHealth=e.health
        if f._fluxPartyMember then f._fluxPartyStatusText=P.GetStatusText(f.unit) end
    end
    UF.UpdatePower=function(f)inc("power");f.lastPower=e.power;f.spentEvent=f._fluxPowerSpentEvent end
    UF.UpdatePortrait=function()inc("portrait")end
    e.FluxRaidAuras.Update=function()inc("auras")end
    local style=P.StyleText;P.StyleText=function(...)inc("style");return style(...)end
    local indicators=P.UpdateIndicators;P.UpdateIndicators=function(...)inc("indicators");return indicators(...)end
    local modes=P.ApplyTextModes;P.ApplyTextModes=function(...)inc("modes");return modes(...)end
    local cover=P.SyncCastCover;P.SyncCastCover=function(...)inc("cover");return cover(...)end
    db.partyAsRaid=false;e.mode="party";e.partyCount=4
    for i=1,4 do e.pets[i]=true;e.targets[i]=true end
    check(P.ApplyOptions(),"party setup succeeds");refresh();drain()
    for _,list in ipairs({P.members,P.pets})do
        for _,f in ipairs(list)do local p=f;while p do p:Show();p=p:GetParent()end end
    end
    drain()
    for _,f in ipairs(P.members)do
        for _,label in ipairs({f.Power.Value,f.Power.Percent})do
            local clear,point=label.ClearAllPoints,label.SetPoint
            label.ClearAllPoints=function(...)inc("powerAnchors");return clear(...)end
            label.SetPoint=function(...)inc("powerAnchors");return point(...)end
        end
    end
    n={}
    local function fire(f,event,unit)f:GetScript("OnEvent")(f,event,unit)end
    -- Ten seconds' modeled traffic. Every value changes: no value-cache shortcut.
    for tick=1,100 do
        e.now=tick/10;e.health=100-tick;e.power=tick
        for i=1,4 do
            local f,pet=P.members[i],P.pets[i]
            fire(f,"UNIT_HEALTH",f.unit);fire(f,"UNIT_POWER_UPDATE",f.unit)
            fire(f,"UNIT_HEAL_PREDICTION",f.unit);fire(f,"UNIT_ABSORB_AMOUNT_CHANGED",f.unit)
            fire(pet,"UNIT_HEALTH",pet.unit);fire(pet,"UNIT_HEAL_PREDICTION",pet.unit)
            if tick%10==0 then fire(f,"UNIT_AURA",f.unit)end
        end
    end
    local out={"PARTY_STEADY",client}
    for _,key in ipairs({"health","power","prediction","chrome","portrait","style","indicators","auras","modes","cover","powerAnchors"})do
        out[#out+1]=key.."="..(n[key]or 0)
    end
    print(table.concat(out,"|"))
    check(n.health>=800 and n.power>=400,"all member/pet health and member power changes still paint")
    for i=1,4 do check(P.members[i].lastHealth==0 and P.pets[i].lastHealth==0 and P.members[i].lastPower==100,"last health/power sample reaches every visible frame")end
    improved(n.health==800 and n.power==400 and n.prediction==1200,"one existing painter per relevant event; pet prediction does not repaint health")
    improved((n.chrome or 0)==0 and (n.portrait or 0)==0 and (n.style or 0)==0 and (n.indicators or 0)==0,"bar traffic does not rebuild chrome, portraits, fonts or indicators")
    improved(n.auras==40 and (n.cover or 0)==0,"aura traffic keeps aura update without recalc of cast cover")
    improved((n.powerAnchors or 0)==0,"settled power text modes reuse the prepared anchor")
    check(P.members[1].spentEvent==true,"power events preserve resource spend/pulse semantics")
    n={};fire(P.members[1],"UNIT_MAXHEALTH","party1");fire(P.members[1],"UNIT_MAXPOWER","party1");fire(P.members[1],"UNIT_DISPLAYPOWER","party1")
    check(n.health>=1 and n.power>=2,"maximums and resource type changes retain shared painters")
    local f=P.members[1]
    improved(f.unitEvents.UNIT_LEVEL==f.unit and f.unitEvents.UNIT_FACTION==f.unit
        and f.unitEvents.UNIT_CLASSIFICATION_CHANGED==f.unit and f.unitEvents.UNIT_SPECIALIZATION_CHANGED==f.unit
        and f.events.INSPECT_READY and f.events.PLAYER_LEVEL_UP,"cold appearance invalidations are actually registered")
    for _,state in ipairs({"offline","dead","ghost","afk","normal"})do
        e.UnitIsConnected=function()return state~="offline"end;e.UnitIsDead=function()return state=="dead"end
        e.UnitIsGhost=function()return state=="ghost"end;e.UnitIsAFK=function()return state=="afk"end
        n={};fire(f,"UNIT_FLAGS",f.unit)
        check(n.health and n.power,"flags refresh both status-colored bars")
        check(f._fluxPartyStatusText==({offline="Offline",dead="Dead",ghost="Ghost",afk="AFK"})[state],"status transitions remain immediate")
        improved((n.portrait or 0)==0,"status flags do not reload the unit model")
        improved((n.style or 0)==0 and (n.chrome or 0)==0 and (n.auras or 0)==0,"combat/status flags do not rebuild unrelated art or aura owners")
    end
    for _,event in ipairs({"UNIT_CONNECTION","UNIT_NAME_UPDATE","UNIT_PORTRAIT_UPDATE","UNIT_MODEL_CHANGED"})do
        n={};fire(f,event,f.unit);check(n.portrait and n.chrome,"identity/availability events still refresh portrait and chrome")
    end
    n={};fire(f,"PARTY_LEADER_CHANGED");check(n.indicators,"leader changes still update compact indicators")
    improved(n.chrome~=nil,"leader changes refresh the shared leader/loot art without waiting for a health tick")
    n={};fire(f,"INSPECT_READY");improved(n.chrome~=nil,"completed inspection refreshes spec art without a health tick")
    n={};fire(f,"UNIT_LEVEL",f.unit);improved(n.chrome~=nil and n.indicators~=nil,"level changes retain fitted compact metadata")
    for _,mode in ipairs({"both","values","percent","both","none","percent"})do
        db.partyPowerText=mode;P.ApplyTextModes(f)
        check(f.Power.Value.shown==(mode=="values"or mode=="both")and f.Power.Percent.shown==(mode=="percent"or mode=="both"),"power mode changes keep values/percent visibility")
        if mode=="percent"then check(f.Power.Percent.points[1][1]=="CENTER","percentage re-centers after a mode change")
        elseif mode=="values"then check(f.Power.Value.points[1][1]=="CENTER","values re-center after a mode change")end
    end
    n={};for _,list in ipairs({P.members,P.pets})do for _,item in ipairs(list)do fire(item,"UNIT_PET","party1")end end
    improved(n.health==2,"one pet owner change refreshes only that member and pet")
    local opaque={};e.issecretvalue=function(v)return rawequal(v,opaque)end
    n={};fire(f,"UNIT_PET",opaque);improved(next(n)==nil,"opaque owner is rejected before token comparisons")
    n={};fire(f,"READY_CHECK");check(f._fluxPartyReadyActive and n.indicators==1,"ready-check display stays immediate")
    fire(f,"READY_CHECK_FINISHED");check(f._fluxPartyReadyActive==false,"ready-check completion still clears state")
    f.CastBar:Show();check(f.nameText.alpha==0 and f.levelText.alpha==0,"cast visibility hooks cover name and level")
    f.CastBar:Hide();check(f.nameText.alpha==1 and f.levelText.alpha==1,"cast hide restores name/level")
    e.combat=true;n={};fire(f,"UNIT_HEALTH",f.unit);fire(f,"UNIT_POWER_UPDATE",f.unit)
    check(n.health==1 and n.power==1,"combat values still paint with no protected layout operation")
    e.combat=false;f:Hide();n={};fire(f,"UNIT_HEALTH",f.unit);check(next(n)==nil,"hidden member ignores data work")
end
print("Party steady performance: "..checks.." checks PASS; modeled operation counts, native performance pending")
