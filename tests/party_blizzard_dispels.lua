-- Actual option helper, aura painters, preview settings and event dispatch.
-- Native HARMFUL|RAID membership, restrictions, pixels and taint remain untested.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local function part(source,first,last)
    local a=assert(source:find(first,1,true));local b=assert(source:find(last,a+#first,true));return source:sub(a,b-1)
end
local root=os.getenv("FLUX_BLIZZARD_DISPEL_ROOT") or "."
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local clients={"live","forever","classic","classic_era","classic_anniversary"}
local source=read("tests/raid_healer_auras.lua")
local prefix=assert(source:match("^(.-)\nfor _,client in ipairs"))
prefix=prefix:gsub('"RaidFrame/FluxRaidVisuals.lua"',string.format("%q",root.."/RaidFrame/FluxRaidVisuals.lua"))
prefix=prefix:gsub('"RaidFrame/FluxRaidAuras.lua"',string.format("%q",root.."/RaidFrame/FluxRaidAuras.lua"))
local Fixture=assert(load(prefix.."\nreturn Fixture","@blizzard-dispel-aura-fixture","t",_G))()
local nativeSource=read(root.."/RaidFrame/FluxRaidFrame.lua")
local cvarGetter=part(nativeSource,"function FluxRaid_GetCVarBool(","function FluxRaid_ShouldClassColorNames()")
local function installCVar(e)
    e.C_CVar={GetCVar=function(name)
        if name=="raidFramesDisplayOnlyDispellableDebuffs"then return e.blizzardDispel end
        check(name=="raidFramesDisplayInOtherPhase","only the existing shared options query accompanies the dispel preference")
    end,SetCVar=function()error("filtering must never rewrite Blizzard preferences")end}
    assert(load(cvarGetter,"@actual-raid-cvar-reader","t",e))()
end
local function aura(id,extra)
    local result={name="Aura"..id,spellId=id,auraInstanceID=id,icon=1000+id,sourceUnit="player",canApplyAura=true,
        isHelpful=false,isHarmful=true,isRaid=false,isBossAura=false,isPriorityAura=false,
        isTankRoleAura=false,isHealerRoleAura=false,isDPSRoleAura=false,isNameplateOnly=false,
        canActivePlayerDispel=false,dispelName="Magic",duration=30,expirationTime=100,applications=1}
    for k,v in pairs(extra or {})do result[k]=v end
    return result
end
local function shownIds(frame)
    local ids={}
    for _,button in ipairs(frame._fluxAuraCorners.debuffs)do
        if button.shown then ids[button.Icon.texture-1000]=true end
    end
    return ids
end
for _,client in ipairs(clients)do
    local native=client=="live"or client=="forever"
    local e,A,frame,frames,boxes,data=Fixture(native,nil,nil,client)
    installCVar(e)
    local helper=assert(e.FluxRaidVisuals.ShouldDisplayOnlyDispellableDebuffs,"missing party Blizzard dispel-setting helper")
    for _,token in ipairs({"party1","party2","party4","player"})do
        frame.unit=token
        for _,value in ipairs({"1",1,true})do
            e.blizzardDispel=value;check(helper(frame),client.." party follows enabled Blizzard setting: "..token)
        end
        for _,value in ipairs({"0",0,false,""})do
            e.blizzardDispel=value;check(not helper(frame),client.." disabled Blizzard setting keeps ordinary party debuffs")
        end
        e.blizzardDispel=nil;check(not helper(frame),"missing native CVar retains the existing default")
    end
    e.blizzardDispel="1"
    for _,token in ipairs({"raid1","focus","target","partypet1","party1target","party10"})do
        frame.unit=token;check(not helper(frame),"native party preference does not alter unrelated unit: "..token)
    end
    frame.unit="raid1";frame._fluxPartyMember=true
    check(helper(frame),"explicit party-preview identity follows native party preference")
    frame._fluxPartyMember=nil;frame.optionTable.displayOnlyDispellableDebuffs=true
    e.blizzardDispel="0";check(helper(frame),"existing Flux strict preference remains effective")
    frame.optionTable={};frame.unit="party1";e.blizzardDispel="0"
    data.HELPFUL={}
    local ordinary,boss,priority=aura(201),aura(202,{isBossAura=true}),aura(203,{isPriorityAura=true})
    local dispellable=aura(204,{isRaid=true,canActivePlayerDispel=true})
    local dispellableBoss=aura(205,{isRaid=true,isBossAura=true,canActivePlayerDispel=true})
    data.HARMFUL={ordinary,boss,priority,dispellable,dispellableBoss}
    data["HARMFUL|RAID"]={dispellable,dispellableBoss}
    check(A.Setup(frame),"aura widgets prepare before combat")
    A.Update(frame)
    local allocated=#frames
    if native then
        local groups=frame._fluxAuraContainers
        check(groups.dispel.groups.debuffs.enabled and groups.dispel.groups.priorityDebuffs.enabled,"normal native categories initially enabled")
        e.blizzardDispel="1";e.combat=true;e.restricted=true;A.Update(frame)
        for _,key in ipairs({"dispel","dispelPlain"})do
            local box=groups[key]
            check(box.groups.bossDebuffs.filter=="HARMFUL|RAID","strict native boss category cannot bypass the dispellable filter")
            check(not box.groups.bossBuffs.enabled and not box.groups.priorityDebuffs.enabled and not box.groups.debuffs.enabled,
                "native strict mode removes helpful boss, priority and ordinary exceptions")
            check(box.groups.dispel.options.candidateFilters.processedAuraType==nil,
                "strict native RAID membership admits eligible auras without ordinary classification exceptions")
        end
        e.blizzardDispel="0";A.Update(frame)
        check(groups.dispel.groups.bossDebuffs.filter=="HARMFUL"and groups.dispel.groups.debuffs.enabled
            and groups.dispel.groups.priorityDebuffs.enabled,"native toggle-off immediately restores prior categories")
        frame.optionTable.displayOnlyDispellableDebuffs=true;A.Update(frame)
        check(not groups.dispel.groups.debuffs.enabled,"Flux strict preference still filters with native preference off")
        frame.optionTable.displayOnlyDispellableDebuffs=false;e.blizzardDispel="1";frame.unit="raid1";A.Update(frame)
        check(groups.dispel.groups.debuffs.enabled,"party-to-raid conversion restores independent raid preference")
    else
        local initial=shownIds(frame)
        check(initial[201]and initial[202]and initial[204]and initial[205],"normal readable party row retains ordinary/own/boss and dispellable auras")
        e.blizzardDispel="1";e.combat=true;A.Update(frame)
        local strict=shownIds(frame)
        check(strict[204]and strict[205]and not strict[201]and not strict[202]and not strict[203],
            "native preference removes nondispellable own/boss/priority auras from readable party row")
        e.blizzardDispel="0";A.Update(frame)
        local restored=shownIds(frame)
        check(restored[201]and restored[202]and restored[204],"readable toggle-off immediately restores prior row")
        frame.optionTable.displayOnlyDispellableDebuffs=true;A.Update(frame)
        check(not shownIds(frame)[201],"Flux strict preference remains effective on readable client")
        frame.optionTable.displayOnlyDispellableDebuffs=false;e.blizzardDispel="1";frame.unit="raid1";A.Update(frame)
        check(shownIds(frame)[201],"party-to-raid conversion restores readable raid preference")
    end
    check(#frames==allocated,"setting changes in combat allocate no aura widgets")
    check(next(e.raidDB)==nil,"display preferences do not mutate persisted Flux raid options")
    local previewSource=read(root.."/RaidFrame/FluxRaidPreview.lua")
    local getPreview=part(previewSource,"local function GetPreviewAuraSettings(","local function PreviewRaidSetting(")
    e.max,e.min=math.max,math.min
    local preview=assert(load(getPreview.."\nreturn GetPreviewAuraSettings","@actual-blizzard-dispel-preview","t",e))()
    frame.unit="party1";e.blizzardDispel="1"
    check(preview(frame).onlyDispellable,"party preview uses the native dispellable-only setting")
    frame.unit="raid1";check(not preview(frame).onlyDispellable,"raid preview retains its independent Flux preference")
    e.raidDB.previewRosterSize=5
    check(preview().onlyDispellable,"synthetic five-member preview follows Blizzard's preference without a unit token")
    e.raidDB.previewRosterSize=10
    check(not preview().onlyDispellable,"switching to raid preview restores its own preference")
end

-- The raid-style party controller shares its header traversal with actual raids.
-- A native preference event must update only full party cells, even in combat.
local refreshSource="local State=FluxRaidState\n"
    ..part(nativeSource,"local CVAR_REFRESH = {","function FluxRaid_ApplyOptionsFromDB()")
    ..part(nativeSource,"local function RefreshFromCVar(","local EventHandlers = {}")
    .."\nreturn RefreshFromCVar"
for _,client in ipairs(clients)do
    local state={isInitialized=true}
    local children={{unit="player"},{unit="party1"},{unit="raid2",displayedUnit="party4"},
        {unit="party2",_fluxRaidMini=true},{unit="raid1"},{unit="focus"},{unit="party1target"},
        {unit="party3",displayedUnit="raid3"},{unit="party2",hidden=true}}
    for _,f in ipairs(children)do f.IsVisible=function(self)return not self.hidden end end
    local updates,enabled={},true
    local e=setmetatable({FluxRaidState=state},{__index=_G})
    e.FluxRaid_IsFluxRaidEnabled=function()return enabled end
    e.FluxRaid_ForEachHeaderChild=function(fn)for _,f in ipairs(children)do fn(f)end end
    e.FluxRaidAuras={Update=function(f)updates[#updates+1]=f end}
    e.InCombatLockdown=function()return e.combat end
    e.FluxRaid_ApplyChromeToChildren=function()error("dispellable-only event must not relayout headers/chrome")end
    e.FluxRaid_SyncAllFluxUnitAuraSettings=function()error("dispellable-only event must not mutate unrelated raid cells")end
    e.C_Timer={After=function()error("dispellable-only event requires no scheduled layout")end}
    local refresh=assert(load(refreshSource,"@actual-blizzard-dispel-header-event","t",e))()
    for _,combat in ipairs({false,true})do
        e.combat=combat
        for _,name in ipairs({"raidFramesDisplayOnlyDispellableDebuffs","RAIDFRAMESDISPLAYONLYDISPELLABLEDEBUFFS"})do
            updates={};refresh(name)
            check(#updates==3 and updates[1]==children[1]and updates[2]==children[2]and updates[3]==children[3],
                client.." header event refreshes only actual full party cells, including combat")
        end
    end
    children[1].hidden=true;children[2].hidden=true;children[3].hidden=true
    updates={};refresh("raidFramesDisplayOnlyDispellableDebuffs")
    check(#updates==0,"hidden party cells retain their cleared aura owners")
    children[1].hidden=nil;children[2].hidden=nil;children[3].hidden=nil
    updates={};refresh("showDispelDebuffs");refresh("raidFramesDisplayOnlyDispellableDebuffsOther")
    check(#updates==0,"unrelated native preference events do not refresh header aura cells")
    enabled=false;refresh("raidFramesDisplayOnlyDispellableDebuffs")
    check(#updates==0,"disabled Flux raid-style party owns no event work")
    enabled=true;state.isInitialized=false;refresh("raidFramesDisplayOnlyDispellableDebuffs")
    check(#updates==0,"uninitialized raid headers own no event work")
end

-- Execute the existing party wrapper with a lightweight painter that records
-- dispatch. The full real aura painters were exercised above.
local partySource=read("tests/raid_party_frames.lua")
local last=assert(partySource:find("    local opaque=setmetatable",1,true))
partySource=partySource:sub(1,last-1):gsub('for _,client in ipairs%({"live","forever","classic","classic_era","classic_anniversary"}%)do',
    'local function partyFixture(client)',1)
partySource=partySource:gsub('loadfile%("UnitFrames/FluxUnitFrames_Party.lua","t",e%)',
    'loadfile('..string.format("%q",root.."/UnitFrames/FluxUnitFrames_Party.lua")..',"t",e)',1)
local partyFixture=assert(load(partySource.."\nreturn e,ns,db,calls,flushTimers,refresh\nend\nreturn partyFixture","@blizzard-dispel-party-events","t",_G))()
for _,client in ipairs(clients)do
    local e,ns,db,calls,drain,refresh=partyFixture(client)
    local P=ns.PartyFrames
    db.partyAsRaid=false;e.mode="party";e.partyCount=4
    check(P.ApplyOptions(),"player-style party prepares existing member widgets")
    refresh();drain()
    local member=P.members[1]
    local p=member;while p do p:Show();p=p:GetParent()end;drain()
    local updates,chrome,threat=0,0,0
    e.FluxRaidAuras.Update=function(f)check(f==member,"setting event refreshes the actual receiving party member");updates=updates+1 end
    e.FluxRaidAuras.Refresh=function()error("setting event must not relayout party auras")end
    member.UpdateOuterBorder=function()chrome=chrome+1 end
    P.UpdateThreat=function()threat=threat+1 end
    for _,combat in ipairs({false,true})do
        e.combat=combat
        for _,name in ipairs({"raidFramesDisplayOnlyDispellableDebuffs","RAIDFRAMESDISPLAYONLYDISPELLABLEDEBUFFS"})do
            local before=updates
            member:GetScript("OnEvent")(member,"CVAR_UPDATE",name)
            check(updates==before+1,"Blizzard preference event refreshes player-style party immediately, including combat")
        end
        local before=updates
        member:GetScript("OnEvent")(member,"CVAR_UPDATE","showDispelDebuffs")
        member:GetScript("OnEvent")(member,"CVAR_UPDATE","raidFramesDisplayOnlyDispellableDebuffsOther")
        check(updates==before,"unrelated CVar updates do not repaint party aura contents")
    end
    check(chrome==0,"dispellable-only preference changes never rebuild party chrome")
    check(threat>0,"preexisting CVar threat refresh remains available")
end

local previewSource=read(root.."/RaidFrame/FluxRaidPreview.lua")
local listenerSource=part(previewSource,"local previewCvarListener = CreateFrame(","local previewSessionListener = CreateFrame(")
local queued,paints={},0
local pe=setmetatable({container={shown=true}},{__index=_G})
pe.container.IsShown=function(self)return self.shown end
pe.CreateFrame=function()
    return {RegisterEvent=function(self,event)check(event=="CVAR_UPDATE","preview retains its existing event owner")end,
        SetScript=function(self,kind,fn)self[kind]=fn end}
end
pe.C_Timer={After=function(delay,fn)check(delay==0,"preview preserves its existing next-dispatch refresh cadence");queued[#queued+1]=fn end}
pe.FluxRaidPreview_RefreshLayout=function()paints=paints+1 end
local listener,visible=assert(load("local previewSessionVisible=true;local previewContainer=container\n"..listenerSource
    .."\nreturn previewCvarListener,function(v)previewSessionVisible=v end","@actual-dispel-preview-listener","t",pe))()
for _,name in ipairs({"raidFramesDisplayOnlyDispellableDebuffs","RAIDFRAMESDISPLAYONLYDISPELLABLEDEBUFFS"})do
    local before=paints;listener.OnEvent(listener,"CVAR_UPDATE",name)
    check(#queued==1 and paints==before,"visible preview schedules both native CVar casing forms")
    queued[1]();queued={};check(paints==before+1,"scheduled native setting change refreshes visible preview")
end
listener.OnEvent(listener,"CVAR_UPDATE","showDispelDebuffs");listener.OnEvent(listener,"CVAR_UPDATE",nil)
check(#queued==0,"unrelated or absent CVar names do not repaint preview")
visible(false);listener.OnEvent(listener,"CVAR_UPDATE","RAIDFRAMESDISPLAYONLYDISPELLABLEDEBUFFS")
check(#queued==0,"closed preview owns no native setting refresh")
visible(true);pe.container.shown=false;listener.OnEvent(listener,"CVAR_UPDATE","RAIDFRAMESDISPLAYONLYDISPELLABLEDEBUFFS")
local before=paints;queued[1]();queued={}
check(paints==before+1,"active player-style preview refreshes while compact preview container is hidden")
listener.OnEvent(listener,"CVAR_UPDATE","RAIDFRAMESDISPLAYONLYDISPELLABLEDEBUFFS")
visible(false);before=paints;queued[1]()
check(paints==before,"closing preview before deferred refresh cancels its paint")
print("Party Blizzard dispellable-only setting: "..checks.." checks PASS; five client models; native filtering/pixels/taint pending")
