-- Optional estimate lifecycle. No mock result certifies live aura access or pixels.
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local function Fixture(options)
    options=options or{}
    local e=setmetatable({},{__index=_G});e._G=e
    local ns={Flux={Client={isForever=options.client~="retail"}}}
    e.now,e.combat=0,false
    e.GetTime=function()return e.now end
    e.InCombatLockdown=function()return e.combat end
    e.GetLocale=function()return options.locale or"enUS"end
    local db={showEstimatedHoTs=options.enabled~=false}
    e.FluxOptions={GetRaidFrameDB=function()return db end}
    e.issecretvalue=function(value)return type(value)=="table"and value.secret==true end
    e.canaccesstable=function(value)return not value.secret end
    local descriptions={
        [139]="Heals the target for 300 over 15 sec.",
        [774]="Heals the target for 240 health over 12 sec.",
        [8936]="Heals a friendly target for 100 to 130 and another 210 over 21 sec.",
    }
    local descriptionReads,auraReads=0,0
    e.C_Spell={GetSpellDescription=function(id)
        check(not e.combat,"spell descriptions are learned only out of combat")
        descriptionReads=descriptionReads+1
        return descriptions[id]
    end}
    local units={party1={guid="GUID-1",name="Friend",realm="Realm"},party2={guid="GUID-2",name="Other",realm="Realm"}}
    e.UnitGUID=function(unit)return units[unit]and units[unit].guid end
    e.UnitFullName=function(unit)
        local data=units[unit]
        return data and data.name,data and data.realm
    end
    e.UnitHealthMax=function(unit)return units[unit]and(units[unit].maximum or 1000)end
    e.UnitIsDeadOrGhost=function(unit)return units[unit]and units[unit].dead or false end
    e.C_UnitAuras={GetAuraDataByIndex=function()
        auraReads=auraReads+1
        return nil
    end}
    local frames,tickers={},{}
    local methods={}
    local function layout()check(not e.combat,"combat does not change estimate geometry")end
    function methods:SetAllPoints(value)layout();self.allpoints=value end
    function methods:SetClipsChildren(value)layout();self.clips=value end
    function methods:EnableMouse(value)layout();self.mouse=value end
    function methods:GetFrameLevel()return 2 end
    function methods:SetFrameLevel(value)layout();self.level=value end
    function methods:SetStatusBarTexture(value)layout();self.texture=value end
    function methods:SetStatusBarColor(...)layout();self.color={...}end
    function methods:SetPoint(...)layout();self.point={...}end
    function methods:SetWidth(value)layout();self.width=value end
    function methods:SetHeight(value)layout();self.height=value end
    function methods:GetWidth()layout();return 66 end
    function methods:GetStatusBarTexture()return self end
    function methods:SetMinMaxValues(low,high)self.low,self.high=low,high end
    function methods:SetValue(value)self.value=value end
    function methods:Show()self.shown=true end
    function methods:Hide()self.shown=false end
    function methods:IsVisible()return self.shown end
    function methods:SetScript(event,callback)self.scripts[event]=callback end
    function methods:GetScript(event)return self.scripts[event]end
    function methods:HookScript(event,callback)self.hooks[event]=callback end
    function methods:RegisterEvent(event)self.events[event]=true end
    function methods:RegisterUnitEvent(event,unit)self.events[event]=unit end
    function methods:UnregisterEvent(event)self.events[event]=nil end
    function methods:UnregisterAllEvents()self.events={}end
    e.CreateFrame=function(kind)
        layout()
        local frame=setmetatable({kind=kind,scripts={},hooks={},events={},shown=true},{__index=methods})
        frames[#frames+1]=frame;return frame
    end
    e.C_Timer={NewTicker=function(interval,callback)
        local ticker={interval=interval,callback=callback,Cancel=function(self)self.cancelled=true end}
        tickers[#tickers+1]=ticker;return ticker
    end}
    local fn,message
    if _VERSION=="Lua 5.1"then fn,message=loadfile("RaidFrame/FluxRaidHoTs.lua");if fn then setfenv(fn,e)end
    else fn,message=loadfile("RaidFrame/FluxRaidHoTs.lua","t",e)end
    assert(fn,message)("_FluxUI",ns)
    local module=e.FluxRaidHoTs
    local function cell(unit)
        local frame=e.CreateFrame("Button");frame.healthBar=e.CreateFrame("StatusBar")
        frame.unit,frame.unitExists=unit,true
        return frame
    end
    local function cast(id,guid,target)
        module.OnEvent("UNIT_SPELLCAST_SENT","player",target or"Friend-Realm",guid,id)
        module.OnEvent("UNIT_SPELLCAST_SUCCEEDED","player",guid,id)
    end
    return e,module,cell,cast,frames,tickers,db,units,descriptions,function()return descriptionReads,auraReads end
end

for _,options in ipairs({{enabled=false},{client="retail"},{locale="deDE"}})do
    local e,hots,cell,cast,frames,tickers=Fixture(options)
    local frame=cell("party1");local count=#frames
    check(not hots.Setup(frame),"disabled or unsupported estimate refuses setup")
    check(#frames==count and#tickers==0,"unavailable estimate creates no widget, driver or ticker")
    hots.Update(frame)
    check(not frame._fluxHoTs,"unavailable update does not allocate")
end

do
    local e,hots,cell,cast,frames,tickers,db,units,descriptions,metrics=Fixture()
    local frame=cell("party1")
    check(hots.Setup(frame),"optional supported Forever estimate setup")
    check(frame._fluxHoTs.host.clips and frame._fluxHoTs.bar.height==3,"estimate is a separate clipped narrow segment")
    local count=#frames
    hots.Setup(frame)
    check(#frames==count,"repeated setup reuses widgets and driver")
    check(#tickers==0,"no countdown ticker before a successful known HoT")
    local before=metrics()
    e.combat=true
    hots.OnEvent("UNIT_SPELLCAST_SENT","player","Friend-Realm","cast-1",139)
    check(#tickers==0,"sent without success cannot create healing")
    hots.OnEvent("UNIT_SPELLCAST_SUCCEEDED","player","cast-1",139)
    check(frame._fluxHoTs.bar.value==300 and frame._fluxHoTs.status=="estimated","own successful cast uses learned total and labels estimate")
    check(#tickers==1 and tickers[1].interval==0.2,"visible nonzero estimate starts one bounded countdown")
    check(metrics()==before,"combat casts never read descriptions")
    e.now=0.1;tickers[1].callback()
    check(frame._fluxHoTs.bar.value==300,"time before first fixed tick retains every remaining tick")
    e.now=3;tickers[1].callback()
    check(frame._fluxHoTs.bar.value==240,"estimate decreases at three-second boundaries")
    cast(139,"cast-2")
    check(frame._fluxHoTs.bar.value==300,"reapplication replaces one family rather than double-counting")
    cast(774,"cast-3")
    check(frame._fluxHoTs.bar.value==540,"different supported HoT families sum")
    local _,beforeAura=metrics()
    hots.OnEvent("UNIT_AURA","party1")
    local _,afterAura=metrics()
    check(beforeAura==afterAura,"restricted combat never scans aura presence to infer removal")
    local maximum={secret=true};units.party1.maximum=maximum
    hots.Update(frame)
    check(rawequal(frame._fluxHoTs.bar.high,maximum),"secret maximum only reaches native display sink")
    units.party1.maximum=1000
    local guid=units.party1.guid;units.party1.guid={secret=true}
    hots.Update(frame)
    check(not frame._fluxHoTs.bar.shown and hots.GetStatus(frame)=="unit identity unavailable","secret identity cannot be matched or classified")
    units.party1.guid=guid
    hots.Update(frame)
    check(frame._fluxHoTs.bar.shown,"readable identity restores existing estimate")
    frame.shown=false;hots.Clear(frame)
    check(not frame._fluxHoTs.bar.shown and tickers[#tickers].cancelled,"hidden final cell stops countdown")
    frame.shown=true;hots.Update(frame)
    check(frame._fluxHoTs.bar.shown and not tickers[#tickers].cancelled,"revealing cell resumes a still-valid estimate")
    hots.Clear(frame)
    check(not frame._fluxHoTs.bar.shown,"explicit clear never repaints its visible retired cell")
    hots.Update(frame)
    db.showEstimatedHoTs=false
    hots.Update(frame)
    check(not frame._fluxHoTs.bar.shown and tickers[#tickers].cancelled,"disabling estimate clears display and timers")
    local driver=frames[#frames]
    check(next(driver.events)==nil,"disabled estimate releases source subscriptions")
    db.showEstimatedHoTs=true;e.combat=false
    hots.Update(frame)
    check(driver.events.UNIT_SPELLCAST_SENT=="player","reenabling reuses driver and subscribes to player casts")
    e.combat=true;cast(139,"cast-4")
    e.now=30;tickers[#tickers].callback()
    check(not frame._fluxHoTs.bar.shown and tickers[#tickers].cancelled,"expiry retires all countdown work")
end

do
    local e,hots,cell,cast,frames,tickers,db,units,descriptions=Fixture()
    local frame=cell("party1");local duplicate=cell("party1")
    hots.Setup(frame);hots.Setup(duplicate)
    cast(8936,"cast-regrowth")
    check(frame._fluxHoTs.bar.value==210 and duplicate._fluxHoTs.bar.value==210,"two views of one identity share a cast record")
    local other=cell("party2");units.party2.name="Friend";units.party2.realm="OtherRealm";hots.Setup(other)
    cast(774,"cast-ambiguous","Friend")
    check(not other._fluxHoTs.bar.shown,"ambiguous unqualified cross-realm target is unavailable")
    check(frame._fluxHoTs.bar.value==210,"ambiguous cast cannot be assigned to an existing name match")
    e.now=1;hots.OnEvent("UNIT_AURA","party1")
    check(not frame._fluxHoTs.bar.shown and not duplicate._fluxHoTs.bar.shown,"readable OOC removal clears both views")
    descriptions[139]="Heals for 300 damage; 15 sec cooldown."
    hots.Learn();cast(139,"cast-unrecognized")
    check(not frame._fluxHoTs.bar.shown,"unrecognized numeric description never becomes healing")
    descriptions[139]="Heals target for 300 over 14 sec."
    hots.Learn();cast(139,"cast-not-three")
    check(not frame._fluxHoTs.bar.shown,"unsupported tick schedule cannot be presented as estimate")
    descriptions[139]="Heals target for 300 over 15 sec."
    hots.Learn();cast(139,"cast-death")
    units.party1.dead=true;hots.Update(frame)
    check(not frame._fluxHoTs.bar.shown,"readable death invalidates tracked effects")
end

print("Raid healer HoT estimates: "..checks.." checks; optional Forever own casts, strict descriptions, secret guards, expiry and inactive cleanup")
