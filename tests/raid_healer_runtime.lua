-- Complete production Compat/Unit modules with narrow widget/API contracts.
-- Native rendering, event delivery, secure input and taint need client checks.
local function read(path)
    local file=assert(io.open(path,"rb"));local value=file:read("*a"):gsub("\r\n","\n");file:close();return value
end
local compatSource,unitSource=read("RaidFrame/FluxRaidCompat.lua"),read("RaidFrame/FluxRaidUnit.lua")
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function fixture(client,body,compat)
    local e=setmetatable({},{__index=_G});e._G=e
    e.combat,e.enabled,e.time=false,true,0
    e.secret=setmetatable({},{__lt=function()error("secret comparison")end,__div=function()error("secret arithmetic")end})
    local ns={Flux={Client={key=client},Secrets={IsSecretValue=function(value)return value==e.secret end}}}
    local options={fadeOutOfRange=true,useClassColors=true,healthText="perc",showRoleIcon=true}
    local facts={
        party1={name="First",health=75,maximum=100,power=40,powerMax=100,connected=true,dead=false,range=true,role="HEALER"},
        party2={name="Second",health=25,maximum=100,power=70,powerMax=100,connected=true,dead=false,range=false,role="TANK"},
        raid1={name="Tank",health=50,maximum=100,power=10,powerMax=100,connected=true,dead=false,range=true,role="TANK"},
        raid1target={name="TankTarget",health=80,maximum=100,power=0,powerMax=0,connected=true,dead=false,range=true,role="NONE"},
    }
    local queries={health=0,power=0,range=0,name=0,loot=0,children=0}
    local function fact(unit)return facts[unit]or{}end
    e.InCombatLockdown=function()return e.combat end
    e.FluxRaid_IsFluxRaidEnabled=function()return e.enabled end
    e.UnitExists=function(unit)return facts[unit]~=nil end
    e.UnitHealth=function(unit)queries.health=queries.health+1;return fact(unit).health end
    e.UnitHealthMax=function(unit)return fact(unit).maximum end
    e.UnitPower=function(unit)queries.power=queries.power+1;return fact(unit).power end
    e.UnitPowerMax=function(unit)return fact(unit).powerMax end
    e.UnitPowerType=function()return 0,"MANA"end
    e.UnitIsConnected=function(unit)return fact(unit).connected end
    e.UnitIsDeadOrGhost=function(unit)return fact(unit).dead end
    e.UnitInRange=function(unit)queries.range=queries.range+1;return fact(unit).range,true end
    e.UnitClass=function()return "Priest","PRIEST"end
    e.RAID_CLASS_COLORS={PRIEST={r=1,g=1,b=1}}
    e.UnitGroupRolesAssigned=function(unit)return fact(unit).role end
    e.UnitIsUnit=function(a,b)return a==b end
    e.C_PartyInfo={GetLootMethod=function()queries.loot=queries.loot+1;return 2,e.lootPartyID,e.lootRaidID end}
    e.UnitIsGroupLeader=function(unit)return fact(unit).leader or false end
    e.UnitIsGroupAssistant=function(unit)return fact(unit).assistant or false end
    e.UnitHasIncomingResurrection=function(unit)return fact(unit).rez or false end
    e.GetRaidTargetIndex=function(unit)return fact(unit).raidMark end
    e.SetRaidTargetIconTexture=function(icon,index)icon.raidIndex=index end
    e.GetReadyCheckStatus=function(unit)return fact(unit).ready end
    e.GetUnitName=function(unit)queries.name=queries.name+1;return fact(unit).name end
    e.UnitThreatSituation=function(unit)return fact(unit).threat or 0 end
    if client=="live"or client=="forever"then
        e.CurveConstants={ScaleTo100={}}
        e.UnitHealthPercent=function(unit)queries.health=queries.health+1;return fact(unit).percent or fact(unit).health end
        e.UnitPowerPercent=function(unit)queries.power=queries.power+1;return fact(unit).power end
        e.C_IncomingSummon={HasIncomingSummon=function(unit)return fact(unit).summon~=nil end,
            IncomingSummonStatus=function(unit)return fact(unit).summon end}
    end
    e.GetTime=function()return e.time end
    e.ClickCastFrames={}
    local methods,widgets,registered={},{},{}
    local function widget(kind,name,parent,protected)
        local f=setmetatable({kind=kind,nameID=name,parent=parent,protected=protected,shown=true,alpha=1,events={},scripts={},hooks={},attrs={},points={},values=0,protectedWrites=0},{__index=methods})
        widgets[#widgets+1]=f;if name then e[name]=f end;return f
    end
    local function protectedWrite(f)
        if f.protected then check(not e.combat,"no insecure structural write in combat");f.protectedWrites=f.protectedWrites+1 end
    end
    function methods:GetName()return self.nameID end
    function methods:GetParent()return self.parent end
    function methods:GetAttribute(key)
        if key:match("^child%d+$") then queries.children=queries.children+1 end
        return self.attrs[key]
    end
    function methods:SetAttribute(key,value)
        protectedWrite(self);self.attrs[key]=value
        for _,hook in ipairs(self.hooks.OnAttributeChanged or{})do hook(self,key,value)end
    end
    function methods:UnregisterAllEvents()self.events={}end
    function methods:RegisterEvent(event)self.events[event]=true end
    function methods:UnregisterEvent(event)self.events[event]=nil end
    function methods:RegisterUnitEvent(event,unit)self.events[event]=unit end
    function methods:RegisterForClicks(...)protectedWrite(self);self.clicks={...}end
    function methods:SetScript(event,fn)self.scripts[event]=fn end
    function methods:HookScript(event,fn)self.hooks[event]=self.hooks[event]or{};table.insert(self.hooks[event],fn)end
    function methods:SetSize(w,h)protectedWrite(self);self.width,self.height=w,h end
    function methods:SetPoint(...)protectedWrite(self);self.points[#self.points+1]={...}end
    function methods:SetAllPoints(relative)protectedWrite(self);self.allPoints=relative end
    function methods:ClearAllPoints()protectedWrite(self);self.points={}end
    function methods:SetAlpha(alpha)self.alpha=alpha;if self.protected then self.alphaWrites=(self.alphaWrites or 0)+1 end end
    function methods:GetAlpha()return self.alpha end
    function methods:SetAlphaFromBoolean(value,yes,no)
        self.booleanAlpha={value,yes,no}
        if value~=e.secret then self.alpha=value and yes or no end
    end
    function methods:EnableMouse(value)protectedWrite(self);self.mouse=value end
    function methods:SetPropagateMouseClicks(value)self.propagate=value end
    function methods:SetShown(value)self.shown=value end
    function methods:Show()self.shown=true end
    function methods:Hide()self.shown=false end
    function methods:IsShown()return self.shown end
    function methods:IsVisible()return self.shown end
    function methods:IsForbidden()return false end
    function methods:SetValue(value)self.value=value;self.values=self.values+1 end
    function methods:GetMinMaxValues()return self.minimum,self.maximum end
    function methods:SetMinMaxValues(a,b)self.minimum,self.maximum=a,b end
    function methods:SetStatusBarColor(...)self.color={...}end
    function methods:SetVertexColor(...)self.vertex={...}end
    function methods:SetText(text)self.text=text end
    function methods:SetFormattedText(format,...)
        self.format,self.arguments=format,{...}
        local safe=true;for _,value in ipairs(self.arguments)do if value==e.secret then safe=false end end
        self.text=safe and string.format(format,...)or nil
    end
    function methods:SetTextColor(...)self.color={...}end
    function methods:SetTexture(value)self.texture=value end
    function methods:SetAtlas(value)self.atlas=value end
    e.CreateFrame=function(kind,name,parent,template)
        local f=widget(kind,name,parent,template~=nil)
        if template=="FluxRaidMiniUnitTemplate" then
            for _,key in ipairs({"healthBar","powerBar","name","statusText","roleIcon","leaderIcon","masterLooterIcon","raidTargetIcon","aggroHighlight","selectionHighlight","mouseOverHighlight","centerStatusIcon","readyCheckIcon"})do
                f[key]=widget(key,nil,f,false)
            end
            f.centerStatusIcon.texture=widget("Texture",nil,f.centerStatusIcon,false)
            f.readyCheckIcon.texture=widget("Texture",nil,f.readyCheckIcon,false)
        end
        return f
    end
    local tickers={}
    e.C_Timer={After=function(_,fn)fn()end,NewTicker=function(interval,fn)
        local t={interval=interval,fn=fn,Cancel=function(self)self.cancelled=true end};tickers[#tickers+1]=t;return t
    end}
    local calls={prediction=0,powerCost=0,aura=0,extras=0,hots=0,dispel=0,big=0}
    local function adjunct(name)
        return {Setup=function(frame)frame[name.."Setup"]=true end,
            Update=function(frame)calls[name]=calls[name]+1;frame[name.."Active"]=true end,
            Clear=function(frame)frame[name.."Active"]=false;frame[name.."Clears"]=(frame[name.."Clears"]or 0)+1 end}
    end
    e.FluxRaidPrediction=adjunct("prediction")
    e.FluxRaidPrediction.UpdatePowerCost=function(frame)calls.powerCost=calls.powerCost+1;frame.costActive=true end
    e.FluxRaidAuras=adjunct("aura")
    e.FluxRaidAuras.UpdateDispel=function()calls.dispel=calls.dispel+1 end
    e.FluxRaidHealerExtras=adjunct("extras")
    e.FluxRaidHoTs=adjunct("hots")
    e.FluxRaidFrame_BigDebuffs_TryUpdate=function()calls.big=calls.big+1 end
    ns.FluxMouseoverKeybind={RegisterFrame=function(_,frame)registered[frame]=(registered[frame]or 0)+1 end}
    e.FluxRaidVisuals={FRAME_WIDTH=72,FRAME_HEIGHT=43,POWER_BAR_HEIGHT=6,FRAME_BASE_ALPHA=0.8,RANGE_ALPHA_IN_RANGE=0.9,RANGE_ALPHA_OUT_OF_RANGE=0.44,
        GetFluxRaidOptionTable=function()return options end,UseOwnRaidSettings=function()return true end,
        ApplyCellChrome=function(frame,chrome)
            frame.healthBar=frame.healthBar or widget("StatusBar",nil,frame,false)
            frame._fluxContent=frame._fluxContent or widget("Frame",nil,frame,false)
            local show=chrome and chrome.showPower
            if show==nil then show=options.displayPowerBar~=false end
            frame.powerBarUsedHeight=show and 6 or 0
            frame.chromeHeight=chrome and chrome.height
        end,
        ConfigurePrivateAuras=function(frame)frame.aurasConfigured=true end,
        SetUnitName=function(frame,name,role)frame.name:SetText(name);frame.roleName=role end,
        PushAuraDisplayToFrame=function()end,SyncPrivateAuraSettings=function()end}
    assert(load(compat or compatSource,"@FluxRaidCompat","t",e))("_FluxUI",ns)
    assert(load(body or unitSource,"@FluxRaidUnit","t",e))("_FluxUI",ns)
    local function cell(name,parent)
        local f=widget("Button",name,parent,true)
        for _,key in ipairs({"healthBar","powerBar","name","statusText","roleIcon","leaderIcon","masterLooterIcon","raidTargetIcon","aggroHighlight","selectionHighlight","mouseOverHighlight","centerStatusIcon","readyCheckIcon"})do
            f[key]=widget(key,nil,f,false)
        end
        f.centerStatusIcon.texture=widget("Texture",nil,f.centerStatusIcon,false)
        f.readyCheckIcon.texture=widget("Texture",nil,f.readyCheckIcon,false)
        e.FluxRaidUnit_OnLoad(f);return f
    end
    local function fire(f,event,unit)
        if f.events[event]and f.scripts.OnEvent then f.scripts.OnEvent(f,event,unit)end
    end
    local function flush()
        local current={};for _,f in ipairs(widgets)do if f.scripts.OnUpdate then current[#current+1]=f end end
        for _,f in ipairs(current)do f.scripts.OnUpdate(f,0.016)end
        return #current
    end
    local function pending()local count=0;for _,f in ipairs(widgets)do if f.scripts.OnUpdate then count=count+1 end end;return count end
    return e,cell,fire,flush,pending,facts,calls,queries,options,registered,tickers,ns
end

local function exercise(client,body)
    local e,cell,fire,flush,pending,facts,calls,queries,options,registered,tickers=fixture(client,body)
    local frame=cell("FluxRaidGrp1Unit1")
    e.FluxRaid_BindUnit(frame,"party1")
    check(frame.events.UNIT_HEALTH=="party1"and frame.events.UNIT_AURA=="party1",client..": actual binding installs unit-filtered events")
    check(registered[frame]and e.ClickCastFrames[frame],client..": real cells join Flux and optional click-cast registration")
    check(frame.name.text=="First"and frame.roleName=="HEALER"and frame.statusText.text=="75%",client..": role/name and percent status remain separate")
    local healthWrites,powerWrites,prediction,aura,extras,hots,dispel,big,cost=frame.healthBar.values,frame.powerBar.values,calls.prediction,calls.aura,calls.extras,calls.hots,calls.dispel,calls.big,calls.powerCost
    for i=1,100 do
        for _,event in ipairs({"UNIT_HEALTH","UNIT_POWER_UPDATE","UNIT_HEAL_PREDICTION","UNIT_ABSORB_AMOUNT_CHANGED","UNIT_AURA","UNIT_THREAT_SITUATION_UPDATE","UNIT_IN_RANGE_UPDATE"})do fire(frame,event,"party1")end
    end
    check(frame.healthBar.values==healthWrites and calls.aura==aura and pending()==1,client..": event burst does no synchronous painting and arms one next-frame dispatcher")
    check(flush()==1 and pending()==0,client..": dispatcher disarms after one frame")
    check(frame.healthBar.values==healthWrites+1 and frame.powerBar.values==powerWrites+1,client..": repeated health/power events paint each category once")
    check(calls.prediction==prediction+1 and calls.aura==aura+1 and calls.extras==extras+1 and calls.hots==hots+1,
        client..": prediction, aura and adjunct callbacks coalesce once")
    check(calls.dispel==dispel+1 and calls.big==big+1 and calls.powerCost==cost+1,client..": optional integrations run once per relevant burst")
    healthWrites,prediction,aura=frame.healthBar.values,calls.prediction,calls.aura
    fire(frame,"UNIT_HEALTH","party1");fire(frame,"UNIT_AURA","party1");fire(frame,"UNIT_NAME_UPDATE","party1")
    flush()
    check(frame.healthBar.values==healthWrites+1 and calls.prediction==prediction+1 and calls.aura==aura+1,client..": full refresh absorbs pending category work without duplicate paint")

    fire(frame,"UNIT_HEALTH","party1");fire(frame,"UNIT_AURA","party1")
    e.FluxRaid_BindUnit(frame,"party2")
    healthWrites,aura=frame.healthBar.values,calls.aura
    flush()
    check(frame.name.text=="Second"and frame.statusText.text=="25%"and frame.events.UNIT_AURA=="party2",client..": rebind replaces old unit and event filters")
    check(frame.healthBar.values==healthWrites and calls.aura==aura,client..": queued old-unit paint is cancelled by rebind")
    fire(frame,"UNIT_HEALTH","party1");check(pending()==0,client..": stale old-unit delivery is ignored")

    local structural=frame.protectedWrites
    local alphaWrites=frame.alphaWrites or 0
    e.combat=true;e.FluxRaid_UpdateRange(frame)
    check(math.abs(frame._fluxContent.alpha-0.8*0.44)<1e-8 and frame.alpha==1,client..": out-of-range fades content while secure click surface stays fully opaque")
    check(frame.protectedWrites==structural and (frame.alphaWrites or 0)==alphaWrites,client..": range fade makes no structural or secure-parent alpha write")
    facts.party2.connected=false;e.FluxRaid_PaintUnit(frame)
    check(frame._fluxContent.alpha==0.8 and frame.statusText.text=="Offline"and frame.name.color[1]==0.55 and frame.healthBar.color[1]==0.22,
        client..": offline content intentionally restores base opacity with gray bar/name and label")
    facts.party2.connected=true;facts.party2.dead=true;options.healthText="none";e.FluxRaid_UpdateStatusText(frame)
    check(frame.statusText.shown and frame.statusText.text=="Dead",client..": death remains visible with health numbers hidden")
    facts.party2.dead=false;e.FluxRaid_UpdateStatusText(frame)
    check(not frame.statusText.shown,client..": alive member respects hidden health numbers")
    options.healthText="perc";options.fadeOutOfRange=false;e.FluxRaid_UpdateRange(frame)
    check(frame._fluxContent.alpha==0.8,client..": disabling range fade resets content to base opacity")
    options.fadeOutOfRange=true;facts.party2.range=e.secret;e.FluxRaid_UpdateRange(frame)
    check(frame._fluxContent.booleanAlpha[1]==e.secret and frame.alpha==1,client..": opaque range result goes directly to the native boolean-alpha sink")
    facts.party2.range=true
    if client=="live"or client=="forever"then
        facts.party2.percent=e.secret;e.FluxRaid_UpdateHealth(frame);e.FluxRaid_UpdateStatusText(frame)
        check(frame.healthBar.value==e.secret and frame.statusText.arguments[1]==e.secret,client..": secret health percent only reaches native display sinks")
        facts.party2.percent=nil
    end
    e.combat=false

    facts.party2.leader,facts.party2.raidMark=true,8;e.FluxRaid_UpdateCenterStatus(frame)
    check(frame.leaderIcon.shown and frame.raidTargetIcon.shown and frame.raidTargetIcon.raidIndex==8 and not frame.centerStatusIcon.shown,
        client..": leader/raid markers do not occupy the center status icon")
    e.lootPartyID=2;e.FluxRaid_UpdateCenterStatus(frame)
    check(frame.masterLooterIcon.shown and frame.leaderIcon.shown and not frame.centerStatusIcon.shown,
        client..": current three-result party-loot contract paints master loot independently")
    e.lootPartyID=nil;e.lootRaidID=1;e.FluxRaid_UpdateCenterStatus(frame)
    check(not frame.masterLooterIcon.shown,client..": a different master looter clears the marker")
    e.lootRaidID=nil
    facts.party2.rez=true;e.FluxRaid_UpdateCenterStatus(frame)
    check(frame.centerStatusIcon.shown and frame.centerStatusIcon.texture.atlas=="Raid-Icon-Rez"and frame.leaderIcon.shown,
        client..": resurrection center icon coexists with leader marker")
    if e.C_IncomingSummon then
        for status,atlas in ipairs({"RaidFrame-Icon-SummonPending","RaidFrame-Icon-SummonAccepted","RaidFrame-Icon-SummonDeclined"})do
            facts.party2.summon=status;e.FluxRaid_UpdateCenterStatus(frame)
            check(frame.centerStatusIcon.texture.atlas==atlas,client..": actual IncomingSummonStatus enum selects state "..status)
        end
        facts.party2.summon=nil
    end
    facts.party2.rez,facts.party2.leader,facts.party2.raidMark=false,false,nil;e.FluxRaid_UpdateCenterStatus(frame)
    check(not frame.centerStatusIcon.shown and not frame.leaderIcon.shown and not frame.raidTargetIcon.shown,client..": ended center/corner states clear independently")

    fire(frame,"UNIT_AURA","party2");fire(frame,"UNIT_HEALTH","party2")
    frame.shown=false;e.FluxRaidUnit_OnHide(frame)
    local queried=queries.health+queries.power+queries.range+queries.name
    flush();fire(frame,"UNIT_HEALTH","party2")
    check(not next(frame.events)and not frame.auraActive and not frame.predictionActive and not frame.extrasActive and not frame.hotsActive,
        client..": hide unregisters unit events and clears every adjunct")
    check(queries.health+queries.power+queries.range+queries.name==queried and pending()==0,client..": hidden cell ignores stale work and performs no queries")
    frame.shown=true;frame.attrs.unit="party2";e.FluxRaidUnit_OnShow(frame)
    check(frame.events.UNIT_HEALTH=="party2"and frame.auraActive and frame.predictionActive,client..": reveal restores event delivery and feedback")
    local reveal=cell("FluxRaidReveal",nil)
    local register=reveal.RegisterUnitEvent
    local writes=0
    function reveal:RegisterUnitEvent(...)
        writes=writes+1
        register(self,...)
    end
    reveal.shown=false
    local auraBeforeReveal=calls.aura
    reveal:SetAttribute("unit","party1")
    check(calls.aura==auraBeforeReveal and reveal.events.UNIT_HEALTH=="party1",
        client..": a hidden native bind only updates the prepared event routes")
    local routeCount=writes
    reveal.shown=true;e.FluxRaidUnit_OnShow(reveal)
    check(routeCount>0 and writes==routeCount and calls.aura==auraBeforeReveal+1 and reveal.events.UNIT_HEALTH=="party1",
        client..": native bind followed by reveal does not register the unit routes twice")
    reveal.shown=false;e.FluxRaidUnit_OnHide(reveal)
    reveal.attrs.unit="party2";reveal.shown=true;e.FluxRaidUnit_OnShow(reveal)
    check(writes==routeCount*2 and reveal.events.UNIT_HEALTH=="party2"and reveal.auraActive,
        client..": reveal with a different token performs one full binding and paints the new unit")
    auraBeforeReveal=calls.aura
    local isVisible=reveal.IsVisible
    reveal.IsVisible=function()return e.secret end
    reveal:SetAttribute("unit","party1")
    check(calls.aura==auraBeforeReveal+1 and reveal.name.text=="First",
        client..": unknown native visibility retains eager paint on the changed unit")
    reveal.IsVisible=isVisible
    e.FluxRaid_BindUnit(frame,nil)
    check(not next(frame.events)and frame.name.text==""and not frame.statusText.shown and not frame.auraActive and not frame.predictionActive and not frame.extrasActive and not frame.hotsActive,
        client..": clearing unit removes labels/events and all feedback owners")

    e.FluxRaid_BindUnit(frame,"party1");facts.party1=nil;e.FluxRaid_PaintUnit(frame)
    check(frame.name.text==""and not frame.statusText.shown and not frame.auraActive and not frame.predictionActive and not frame.extrasActive and not frame.hotsActive,
        client..": disappeared unit cannot retain prior labels or adjunct feedback")

    local header=e.CreateFrame("Frame","FluxRaidMTMA",nil)
    e.FluxRaidState.mtmaHeader=header
    e.FluxRaidVisuals.FRAME_HEIGHT=56
    local tank=cell("FluxRaidMTMA1",header)
    e.FluxRaid_BindUnit(tank,"raid1");e.FluxRaid_AttachOrUpdateMTMATarget(tank,"raid1")
    local mini=tank._fluxMTMATarget
    check(mini and mini.unit=="raid1target"and registered[mini]and e.ClickCastFrames[mini],client..": actual MTMA target creation directly registers Flux casting")
    check(mini._fluxRaidMini and mini.predictionSetup and mini.scripts.OnHide,client..": target mini retains lifecycle/prediction ownership")
    check(not e.FluxRaid_ShouldShowPowerBar(mini) and not mini.powerBar.shown,client..": MT target cannot inherit the global resource-bar setting")
    local powerQueries=queries.power
    e.FluxRaid_UpdatePower(mini)
    check(queries.power==powerQueries and not mini.powerBar.shown,client..": target power events perform no resource queries or resource painting")
    check(mini.powerBarUsedHeight==0,client..": target HP reclaims the full resource-bar area")
    mini.optionTable.healthText="healthandpercent"
    e.FluxRaid_UpdateStatusText(mini)
    check(mini.statusText.format=="%.0f%%",client..": MT target always shows plain health percent instead of the parent health mode")
    e.FluxRaid_UpdateRange(mini)
    check(mini._fluxContent.alpha==.8,client..": in-range target keeps the configured base opacity without member dimming")
    local normalRange=e.UnitInRange
    for _,checked in ipairs({false,e.secret})do
        e.UnitInRange=function()return false,checked end
        e.FluxRaid_UpdateRange(mini)
        check(mini._fluxContent.alpha==.8 and mini.outOfRange==false,client..": unsupported or opaque target range does not fade its HP strip")
    end
    e.UnitInRange=function()return false,true end;e.FluxRaid_UpdateRange(mini)
    check(math.abs(mini._fluxContent.alpha-.8*.44)<1e-8,client..": a genuinely checked out-of-range target still follows the configured far opacity")
    e.UnitInRange=normalRange
    check(mini.height==18 and mini.height==mini._fluxWrap.height and mini.chromeHeight==18,
        client..": taller 56px members keep the mini inside its reserved 18px target strip")
    e.FluxRaidVisuals.FRAME_WIDTH=90;e.FluxRaidVisuals.FRAME_HEIGHT=72
    e.FluxCompactMiniFrameSetup(mini)
    check(mini.width==90 and mini.height==18 and mini.chromeHeight==18,
        client..": member resizing updates mini width without overflowing the reserved target strip")
    e.FluxRaidVisuals.FRAME_WIDTH=98;e.FluxRaidVisuals.FRAME_HEIGHT=44
    e.FluxRaidVisuals.MINI_FRAME_HEIGHT=22;e.FluxRaidVisuals.CELL_JOIN_OVERLAP=1
    e.FluxCompactMiniFrameSetup(mini)
    check(mini.width==98 and mini.height==22 and mini._fluxWrap.width==98 and mini._fluxWrap.height==22,
        client..": native main and mini dimensions update their existing target wrapper together")
    check(mini._fluxWrap.points[1][2]==tank and mini._fluxWrap.points[1][4]==0 and mini._fluxWrap.points[1][5]==1,
        client..": native one-pixel joined spacing also anchors the target wrapper")
    mini._fluxSecureTargetAttached=true;mini._fluxWrap.alpha=0
    e.FluxRaidUnit_OnShow(mini)
    check(mini._fluxWrap.alpha==1 and mini.unit=="raid1target",client..": secure target reappearance cannot retain an invisible alpha-zero wrapper")
    queried=queries.health+queries.power+queries.range+queries.name
    e.enabled=false;fire(tank,"UNIT_HEALTH","raid1");flush()
    check(queries.health+queries.power+queries.range+queries.name==queried,client..": disabled module dispatcher does no unit queries")
    for _,ticker in ipairs(tickers)do check(ticker.cancelled,"supported unit range events need no continuing fallback poll")end
end

local function EventRetirementReplay(client, body, members, hideFirst)
    local e,cell,_,flush,_,facts=fixture(client,body)
    local frames,tokens,trace={},{},{}
    local clears,registers=0,0
    for i=1,members do
        local party=members==5
        local unit=party and (i==1 and "player" or "party"..(i-1)) or "raid"..i
        facts[unit]=facts.raid1
        local frame=cell("EventMember"..i,nil)
        frame._fluxPartyMember=party
        local clear,register=frame.UnregisterAllEvents,frame.RegisterUnitEvent
        function frame:UnregisterAllEvents()
            clears=clears+1
            return clear(self)
        end
        function frame:RegisterUnitEvent(...)
            registers=registers+1
            return register(self,...)
        end
        frames[i],tokens[i]=frame,unit
    end
    local function Snapshot(frame,unit)
        check(frame.unit==unit and frame.events.UNIT_HEALTH==unit and frame.events.UNIT_AURA==unit,
            "the current unit owns every expected active subscription")
        local events={}
        for name,value in pairs(frame.events) do events[#events+1]=name..":"..tostring(value) end
        table.sort(events)
        trace[#trace+1]=table.concat(events,",")
    end
    local function Join(rotated)
        for i,frame in ipairs(frames) do
            local unit=tokens[rotated and i%members+1 or i]
            frame.attrs.unit=unit
            e.FluxRaid_OnUnitAttributeChanged(frame,"unit",unit)
            frame.shown=true
            e.FluxRaidUnit_OnShow(frame)
            Snapshot(frame,unit)
        end
        flush()
    end
    local function Unbind(frame)
        frame.attrs.unit=nil
        e.FluxRaid_OnUnitAttributeChanged(frame,"unit",nil)
    end
    local function Hide(frame)
        frame.shown=false
        e.FluxRaidUnit_OnHide(frame)
    end
    Join(false)
    local initialClears,initialRegisters=clears,registers
    e.combat=true
    for _,frame in ipairs(frames) do
        if hideFirst then Hide(frame);Unbind(frame) else Unbind(frame);Hide(frame) end
        check(not next(frame.events) and not frame.auraActive and not frame.predictionActive,
            "leave clears native routes and existing presentation")
        Snapshot(frame,nil)
    end
    local afterLeave=clears
    e.combat=false
    Join(true)
    return {initial=initialClears,leave=afterLeave-initialClears,rejoin=clears-afterLeave,
        initialRegisters=initialRegisters,rejoinRegisters=registers-initialRegisters,trace=table.concat(trace,"|")}
end

local function CheckEventRetirementRepair()
    local e,cell=fixture("forever")
    local frame=cell("EventRepair",nil)
    frame.attrs.unit="party1"
    e.FluxRaid_BindUnit(frame,"party1")
    local reset=frame.UnregisterAllEvents
    local caught,token=0,{}
    frame.UnregisterAllEvents=function() caught=caught+1;error(token,0) end
    local ok,reason=pcall(e.FluxRaidUnit_OnHide,frame)
    check(not ok and reason==token and caught==1,"retirement error remains observable")
    ok,reason=pcall(e.FluxRaidUnit_OnHide,frame)
    check(not ok and reason==token and caught==2,"failed clear is retried with the same native writer")

    local reenter=true
    frame.UnregisterAllEvents=function(self)
        reset(self)
        if reenter then reenter=false;e.FluxRaidUnit_OnShow(self) end
    end
    e.FluxRaidUnit_OnHide(frame)
    check(frame.events.UNIT_HEALTH=="party1","a registration during clear stays live")
    e.FluxRaidUnit_OnHide(frame)
    check(not next(frame.events),"the reentrant registration keeps the next clear armed")
    frame.UnregisterAllEvents=reset
    frame:RegisterEvent("PLAYER_LOGIN")
    e.FluxRaidUnit_OnHide(frame)
    check(not next(frame.events),"a replacement reset writer clears even after completed retirement")

    frame._fluxRaidMini=true
    frame.powerBarUsedHeight=6
    e.combat=true
    e.FluxRaid_UpdatePower(frame)
    check(frame.events.PLAYER_REGEN_ENABLED and frame._fluxPowerLayoutPending,"a deferred power change owns a fresh event")
    e.FluxRaidUnit_OnHide(frame)
    check(not next(frame.events),"the pending power event arms retirement on an otherwise cleared cell")

    local unowned=e.CreateFrame("Button")
    e.FluxRaidUnit_OnHide(unowned)
    unowned:RegisterEvent("PLAYER_LOGIN")
    e.FluxRaidUnit_OnHide(unowned)
    check(not next(unowned.events),"an unowned frame always uses its current reset writer")
end

local eventRetirementBefore=arg and arg[2]=="--event-retirement" and read(arg[1].."/RaidFrame-FluxRaidUnit.lua")
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"}) do
    for _,members in ipairs({5,40}) do
        for _,hideFirst in ipairs({false,true}) do
            local current=EventRetirementReplay(client,nil,members,hideFirst)
            check(current.initial==members and current.leave==members and current.rejoin==0,
                "each live group event set clears once on departure")
            if eventRetirementBefore then
                local before=EventRetirementReplay(client,eventRetirementBefore,members,hideFirst)
                check(before.initial==members and before.leave==2*members and before.rejoin==members,
                    "the archive clears for both leave callbacks and again before rejoin")
                check(current.trace==before.trace and current.initialRegisters==before.initialRegisters
                    and current.rejoinRegisters==before.rejoinRegisters,"native event bindings and registration cadence match the archive")
                print(("RAID_EVENT_RETIRE|%s|%d|%s|%d|%d|%d|%d"):format(
                    client,members,tostring(hideFirst),before.leave,current.leave,before.rejoin,current.rejoin))
            end
        end
    end
end
CheckEventRetirementRepair()
if eventRetirementBefore then
    print("Raid event retirement: "..checks.." matched desktop checks")
    return
end

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do exercise(client)end

local function rosterReplay(client, body, members)
    local e, cell, _, flush, _, facts, calls, queries = fixture(client, body)
    local state = e.FluxRaidState
    local frames = {}
    for i = 1, members do
        local index = math.floor((i - 1) / 5) + 1
        local header = state.raidHeaders[index]
        if not header then
            header = e.CreateFrame("Frame", "Header" .. index)
            state.raidHeaders[index] = header
        end
        local unit = "raid" .. i
        facts[unit] = {name = unit, connected = true, health = 90, maximum = 100, power = 60, powerMax = 100, range = true}
        local frame = cell("Member" .. i, header)
        frame.attrs.unit = unit
        header.attrs["child" .. ((i - 1) % 5 + 1)] = frame
        e.FluxRaid_BindUnit(frame, unit)
        frames[i] = frame
    end
    local header = e.CreateFrame("Frame", "FluxRaidMTMA")
    state.mtmaHeader = header
    local tank = cell("FluxRaidMTMA1", header)
    header.attrs.child1 = tank
    tank.attrs.unit = "raid1"
    e.FluxRaid_BindUnit(tank, "raid1")
    e.FluxRaid_RefreshMTMATargetAttachments()
    local mini = assert(tank._fluxMTMATarget)
    mini._fluxSecureTargetAttached = true
    mini.attrs.unit = "raid1target"
    local wrap = mini._fluxWrap
    wrap.alpha = 1
    local nativeAlpha = wrap.SetAlpha
    local alphaWrites = 0
    function wrap:SetAlpha(value) alphaWrites = alphaWrites + 1;nativeAlpha(self, value) end
    queries.children = 0
    e.FluxRaid_RefreshMTMATargetAttachments()
    local children, writes = queries.children, alphaWrites

    queries.loot = 0
    local priorAura = calls.aura
    e.lootRaidID = members
    e.FluxRaid_SyncHeaderChildUnits()
    flush()
    local groupLoot, auraPaints = queries.loot, calls.aura - priorAura
    check(auraPaints == members + 1, client .. ": all original full raid paints remain")
    for i, frame in ipairs(frames) do
        check(frame.masterLooterIcon.shown == (i == members), client .. ": roster paint uses current master looter")
    end
    queries.loot = 0
    e.lootRaidID = nil
    e.FluxRaid_RefreshVisibleUnits("raidtarget")
    local refreshLoot = queries.loot
    check(not frames[members].masterLooterIcon.shown, client .. ": group scan clears the previous looter")
    e.lootRaidID = 1
    e.FluxRaid_UpdateCenterStatus(frames[1])
    check(frames[1].masterLooterIcon.shown and queries.loot == refreshLoot + 1,
        client .. ": separate requests read the live assignment")
    e.lootRaidID = e.secret
    e.FluxRaid_RefreshVisibleUnits("raidtarget")
    check(not frames[1].masterLooterIcon.shown, client .. ": the secret assignment is never inspected")

    wrap.alpha = 0
    e.FluxRaid_RefreshMTMATargetAttachments()
    check(wrap.alpha == 1, client .. ": attachment refresh restores a transparent target wrapper")
    wrap.GetAlpha = function()return e.secret end
    e.FluxRaid_RefreshMTMATargetAttachments()
    check(wrap.alpha == 1, client .. ": private alpha uses the normal restore")
    return children, writes, groupLoot, refreshLoot, auraPaints
end

local comparePaintReads = arg and arg[2] == "--paint-reads"
local comparePaintBatch = arg and arg[2] == "--paint-batch"
local compareReassignment = arg and arg[2] == "--roster-reassignment"
local compareStablePaint = arg and arg[2] == "--stable-paint"
local compareActiveHeaders = arg and arg[2] == "--active-headers"
local prior = arg and arg[1] and not comparePaintReads and not comparePaintBatch and not compareReassignment and not compareStablePaint
    and not compareActiveHeaders
    and read(arg[1] .. "/RaidFrame-FluxRaidUnit.lua")
for _, client in ipairs({"live","forever","classic","classic_era","classic_anniversary"}) do
    for _, members in ipairs({5, 40}) do
        local children, writes, groupLoot, refreshLoot, auras = rosterReplay(client, nil, members)
        check(children == 2 and writes == 0, client .. ": MT/MA work touches only its prepared header")
        check(groupLoot == 1 and refreshLoot == 1, client .. ": loot is sampled once in each batch")
        if prior then
            local oldChildren, oldWrites, oldGroupLoot, oldRefreshLoot, oldAuras = rosterReplay(client, prior, members)
            check(oldChildren > children and oldWrites == 1 and oldAuras == auras, client .. ": source replay preserves aura paint")
            check(oldGroupLoot > 1 and oldRefreshLoot > 1, client .. ": archived module reads loot per cell")
            print(("RAID_ROSTER_BATCH %s members=%d childReads=%d/%d wrapWrites=%d/%d loot=%d/%d indicatorLoot=%d/%d aura=%d/%d")
                :format(client, members, oldChildren, children, oldWrites, writes, oldGroupLoot, groupLoot,
                    oldRefreshLoot, refreshLoot, oldAuras, auras))
        end
    end
end

local visualSource=read("RaidFrame/FluxRaidVisuals.lua")
local visualStart=assert(visualSource:find("function FluxRaidVisuals.SetHealthStatus(",1,true))
local visualEnd=assert(visualSource:find("-- Role markup",visualStart,true))
local healthStatus=visualSource:sub(visualStart,visualEnd-1)

local function healthRepaint(client, body, compat)
    local e,cell,fire,flush,_,facts,calls,_,options=fixture(client,body,compat)
    e.issecretvalue=function(value)return value==e.secret end
    e.FluxRaidVisuals.SetUnitStatus=function(frame,format,...)
        frame.statusText:SetFormattedText(format,...)
    end
    assert(load(healthStatus,"@actual-raid-health-status","t",e))()
    local reads={}
    local readers={"UnitHealthPercent","UnitHealth","UnitHealthMax","UnitIsConnected","UnitIsDeadOrGhost","UnitExists"}
    for _,key in ipairs(readers) do
        local reader=e[key]
        if reader then
            e[key]=function(...)
                reads[key]=(reads[key] or 0)+1
                return reader(...)
            end
        end
    end
    local frames={}
    for i=1,40 do
        local column=math.floor((i-1)/5)+1
        local headers=e.FluxRaidState.raidHeaders
        headers[column]=headers[column] or e.CreateFrame("Frame","HealthRoster"..column)
        local unit="raid"..i
        facts[unit]={name=unit,connected=true,dead=false,health=80,maximum=100,power=35,powerMax=100,range=true}
        if i==2 then
            facts[unit].health, facts[unit].connected = 20, false
        end
        local frame=cell("HealthMember"..i,headers[column])
        frame.attrs.unit=unit
        headers[column].attrs["child"..((i-1)%5+1)]=frame
        e.FluxRaid_BindUnit(frame,unit)
        frames[i]=frame
    end
    reads={}
    local startAuras=calls.aura
    e.FluxRaid_SyncHeaderChildUnits()
    flush()
    local roster=reads
    check(calls.aura-startAuras==40,client..": roster preserves aura refresh for every cell")
    for i,frame in ipairs(frames) do
        local value,text=80,"80%"
        if i==2 then value,text=20,"Offline" end
        check(frame.healthBar.value==value and frame.statusText.text==text,client..": roster shows each member's live health")
    end

    local frame=frames[1]
    facts.raid1.health=65
    reads={}
    fire(frame,"UNIT_HEALTH","raid1");flush()
    local changed=reads
    reads={}
    check(frame.healthBar.value==65 and frame.statusText.text=="65%",client..": health event reads a fresh value")
    for _,mode in ipairs({"health","healthandpercent","losthealth","none"}) do
        options.healthText=mode
        e.FluxRaid_PaintUnit(frame)
        local wanted=({health=65,healthandpercent="65 / 65%",losthealth="-35"})[mode]
        check(not wanted and not frame.statusText.shown or frame.statusText.shown and frame.statusText.text==wanted,
            client..": native status preserves "..mode)
    end
    options.healthText="perc"
    facts.raid1.connected=false;e.FluxRaid_PaintUnit(frame)
    check(frame.statusText.text=="Offline" and frame.name.color[1]==.55 and frame.powerBar.color[1]==.4,
        client..": offline sample reaches the bar and label")
    facts.raid1.connected=true;facts.raid1.dead=true;e.FluxRaid_PaintUnit(frame)
    check(frame.statusText.text=="Dead" and frame.healthBar.color[1]==.22,client..": dead sample reaches both health sinks")
    if e.UnitHealthPercent then
        facts.raid1.dead=e.secret;facts.raid1.connected=e.secret;facts.raid1.percent=e.secret
        e.combat=true;e.FluxRaid_PaintUnit(frame)
        check(frame.healthBar.value==e.secret and frame.statusText.arguments[1]==e.secret,
            client..": opaque health stays in both native sinks")
    end
    return readers,roster,changed
end

local paintBaseline=comparePaintReads and read(arg[1] .. "/RaidFrame-FluxRaidUnit.lua")
local compatBaseline=comparePaintReads and read(arg[1] .. "/RaidFrame-FluxRaidCompat.lua")
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"}) do
    local readers,roster,changed=healthRepaint(client)
    local legacy=client~="live" and client~="forever"
    local percent=legacy and "UnitHealth" or "UnitHealthPercent"
    check(roster[percent]==40 and roster.UnitIsConnected==40 and roster.UnitIsDeadOrGhost==40 and roster.UnitExists==40,
        client..": each full cell samples common health and unit state once")
    check(changed[percent]==1 and changed.UnitIsConnected==1 and changed.UnitIsDeadOrGhost==1,
        client..": dirty health and status share one read")
    if paintBaseline then
        local _,oldRoster,oldChanged=healthRepaint(client,paintBaseline,compatBaseline)
        for _,reader in ipairs(readers) do
            print(("RAID_PAINT_READ %s %s full=%d/%d event=%d/%d"):format(client,reader,
                oldRoster[reader] or 0,roster[reader] or 0,oldChanged[reader] or 0,changed[reader] or 0))
        end
    end
end

local function paintBatchModel(client, body, oldDispelResult, members)
    local e,cell,fire,flush,_,facts,calls,_,options=fixture(client,body)
    local reads={enabled=0,name=0,cvar=0,class=0,shown=0,range=0}
    local native=client=="live" or client=="forever"
    local colorNames,healthMode=true,"perc"
    e.FluxRaid_IsFluxRaidEnabled=function() reads.enabled=reads.enabled+1; return e.enabled end
    e.FluxRaid_ShouldClassColorNames=function() reads.name=reads.name+1; return colorNames end
    e.FluxRaidVisuals.UseOwnRaidSettings=function() return native end
    e.C_CVar={GetCVar=function() reads.cvar=reads.cvar+1; return healthMode end}
    e.RAID_CLASS_COLORS.MAGE={r=.25,g=.5,b=.75}
    e.UnitClass=function(unit)
        reads.class=reads.class+1
        return "Class",facts[unit].class
    end
    local setName=e.FluxRaidVisuals.SetUnitName
    e.FluxRaidVisuals.SetUnitName=function(frame,name,role)
        setName(frame,name,role)
        if frame.roleIcon then frame.roleIcon:Hide() end
    end
    if not native then
        local update=e.FluxRaidAuras.Update
        e.FluxRaidAuras.Update=function(frame)
            update(frame)
            e.FluxRaidAuras.UpdateDispel(frame)
            if not oldDispelResult then return true end
        end
    end
    local frames={}
    local header=e.CreateFrame("Frame","BatchHeader")
    e.FluxRaidState.raidHeaders={header}
    for i=1,members do
        local unit="raid"..i
        facts[unit]={name=unit,connected=true,dead=false,health=80,maximum=100,power=35,powerMax=100,range=true,
            class=i%2==0 and "PRIEST" or "MAGE"}
        local frame=cell("BatchMember"..i,header)
        frame.attrs.unit=unit
        header.attrs["child"..i]=frame
        e.FluxRaid_BindUnit(frame,unit)
        frames[i]=frame
        for _,bar in ipairs({frame.healthBar,frame.powerBar}) do
            local writer=bar.SetMinMaxValues
            function bar:SetMinMaxValues(...)
                reads.range=reads.range+1
                return writer(self,...)
            end
        end
        for _,key in ipairs({"powerBar","roleIcon","selectionHighlight","aggroHighlight","leaderIcon",
            "raidTargetIcon","masterLooterIcon","centerStatusIcon","readyCheckIcon"}) do
            local region=frame[key]
            for _,writer in ipairs({"SetShown","Hide","Show"}) do
                local method=region[writer]
                region[writer]=function(self,...)
                    reads.shown=reads.shown+1
                    return method(self,...)
                end
            end
        end
    end
    local function Repaint()
        for _,frame in ipairs(frames) do fire(frame,"UNIT_NAME_UPDATE",frame.unit) end
        flush()
    end
    local function Sample(useRosterEvent)
        for k in pairs(reads) do reads[k]=0 end
        local start=calls.dispel
        if useRosterEvent then e.FluxRaid_SyncHeaderChildUnits();flush()
        else Repaint() end
        return {enabled=reads.enabled,name=reads.name,cvar=reads.cvar,class=reads.class,
            shown=reads.shown,range=reads.range,dispel=calls.dispel-start}
    end
    local function CheckWidgetRepair()
        local first=frames[1]
        local savedPower=first.powerBar
        first.healthBar.minimum,first.healthBar.maximum=5,80
        local expectedPower=savedPower.GetMinMaxValues
        savedPower.GetMinMaxValues=function() return e.secret,e.secret end
        first.leaderIcon.shown=true
        first.aggroHighlight.IsShown=function() error("visibility getter denied") end
        first.selectionHighlight.IsShown=function() return e.secret end
        local repairs=Sample(true)
        check(first.healthBar.minimum==0 and first.healthBar.maximum==100 and savedPower.minimum==0
            and savedPower.maximum==100 and repairs.range==2,
            client..": drifted and opaque ranges keep the protected range repair")
        check(not first.leaderIcon.shown and not first.aggroHighlight.shown and not first.selectionHighlight.shown
            and repairs.shown==members+3,
            client..": drifted and unreadable visibility still reaches the original writer")
        savedPower.GetMinMaxValues=expectedPower
        first.aggroHighlight.IsShown,first.selectionHighlight.IsShown=nil,nil
        facts.raid1.leader=true
        Sample(true)
        check(first.leaderIcon.shown,client..": an actual roster leader change updates the indicator")
        check(first.healthBar.value==80 and savedPower.value==35,client..": roster still paints current health and power")
    end
    local function CheckTransitions()
        local first,second=frames[1],frames[2]
        check(first.name.color[1]==.25 and first.healthBar.color[1]==.25*.72
            and second.name.color[1]==1 and second.healthBar.color[1]==.72,
            client..": each cell gets its own class")
        facts.raid1.class=e.secret
        facts.raid2.class="MAGE"
        colorNames=false
        healthMode="health"
        facts.raid1.threat=2
        Repaint()
        check(first.name.color[1]==1 and first.healthBar.color[1]==.2
            and second.name.color[1]==1 and second.healthBar.color[1]==.25*.72,
            client..": next batch uses fresh options and rejects opaque class tokens")
        check(first.aggroHighlight.shown and first.statusText.text==(native and "80%" or 80),
            client..": changed visibility and native health preference repaint")
        local savedName=first.name
        first.name=nil
        first.roleIcon.shown=true
        e.FluxRaid_UpdateRoleIcon(first)
        check(not first.roleIcon.shown,client..": missing name region retains direct role icon cleanup")
        first.name=savedName
        local dispels=calls.dispel
        fire(first,"UNIT_AURA",first.unit);flush()
        check(calls.dispel-dispels==((native or not oldDispelResult) and 1 or 2),
            client..": the isolated aura lane paints dispel with the same owner")
        local start=calls.aura
        e.enabled=false
        Repaint()
        check(calls.aura==start,client..": next batch honors disabled module")
    end
    return Repaint,Sample,CheckTransitions,CheckWidgetRepair
end

local batchBefore=comparePaintBatch and read(arg[1] .. "/RaidFrame-FluxRaidUnit.lua")
local stableBefore=compareStablePaint and read(arg[1] .. "/RaidFrame-FluxRaidUnit.lua")
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"}) do
    for _,members in ipairs({5,40}) do
        local _,sample,checkTransitions,checkWidgetRepair=paintBatchModel(client,nil,false,members)
        local work=sample()
        local native=client=="live" or client=="forever"
        check(work.enabled==1 and work.name==1 and work.cvar==(native and 0 or 1) and work.class==members,
            client..": synchronous roster paint shares safe settings and per-unit class samples")
        check(work.dispel==members and work.shown==members and work.range==0,
            client..": settled bars and indicators retain their native presentation")
        local roster=sample(true)
        check(roster.shown==members and roster.range==0 and roster.dispel==members,
            client..": full roster paint retains settled range and visibility")
        if stableBefore then
            local _,oldSample=paintBatchModel(client,stableBefore,false,members)
            local oldRoster=oldSample(true)
            print(("RAID_STABLE_PAINT|%s|%d|%d|%d|%d|%d"):format(
                client,members,oldRoster.shown,roster.shown,oldRoster.range,roster.range))
        end
        checkWidgetRepair()
        checkTransitions()
        if batchBefore then
            local _,oldSample,oldTransitions=paintBatchModel(client,batchBefore,true,members)
            local old=oldSample()
            check(old.enabled==members and old.name==members and old.cvar==(native and 0 or members)
                and old.class==members*2 and old.dispel==members*(native and 1 or 2) and old.shown==members*10,
                client..": exact pre-change paint does the measured extra work")
            oldTransitions()
            print(("RAID_BATCH %s members=%d enabled=%d/%d name=%d/%d cvar=%d/%d class=%d/%d shown=%d/%d dispel=%d/%d"):format(
                client,members,old.enabled,work.enabled,old.name,work.name,old.cvar,work.cvar,old.class,work.class,
                old.shown,work.shown,old.dispel,work.dispel))
        end
    end
end

local function reassignmentModel(client, body, members, combat)
    local e,cell,fire,flush,pending,facts,calls,_,_,_,_,ns=fixture(client,body)
    local header=e.CreateFrame("Frame","ReassignmentHeader")
    e.FluxRaidState.raidHeaders={header}
    local frames,tokens={},{}
    for i=1,members do
        local unit="raid"..i
        tokens[i]=unit
        facts[unit]={name=unit,connected=true,health=20+i,maximum=100,power=55,powerMax=100,range=true}
        local frame=cell("ReassignedMember"..i,header)
        frame.attrs.unit=unit
        header.attrs["child"..i]=frame
        e.FluxRaid_BindUnit(frame,unit)
        frames[i]=frame
    end
    e.combat=combat
    local function NativeUnit(frame,unit)
        frame.attrs.unit=unit
        e.FluxRaid_OnUnitAttributeChanged(frame,"unit",unit)
    end
    local rotation=0
    local function Burst()
        for _=1,3 do
            rotation=(rotation+1)%members
            for i,frame in ipairs(frames) do NativeUnit(frame,tokens[(i+rotation-1)%members+1]) end
            e.FluxRaid_SyncHeaderChildUnits()
        end
    end
    local function Work()
        local initial=calls.aura
        Burst()
        local synchronous=calls.aura-initial
        local queued=pending()
        for i,frame in ipairs(frames) do
            local unit=tokens[(i+rotation-1)%members+1]
            check(frame.unit==unit and frame.unitExists and frame.events.UNIT_AURA==unit,
                client..": roster binding is effective before visual commit")
        end
        flush()
        for i,frame in ipairs(frames) do
            local unit=tokens[(i+rotation-1)%members+1]
            check(frame.name.text==unit and type(frame.healthBar.value)=="number"
                and math.abs(frame.healthBar.value-facts[unit].health)<1e-8,
                client..": one commit paints the final unit")
        end
        local total=calls.aura-initial
        local first=frames[1]
        local newUnit=first.unit==tokens[1] and tokens[2] or tokens[1]
        initial=calls.aura
        NativeUnit(first,newUnit)
        e.FluxRaidUnit_OnShow(first)
        check(first.name.text==newUnit,client..": reveal paints before a dispatch")
        flush()
        local reveal=calls.aura-initial
        initial=calls.aura
        fire(first,"UNIT_AURA",newUnit);NativeUnit(first,nil);flush()
        check(calls.aura==initial and first.name.text=="" and not first.auraActive,
            client..": leaving retires pending paint and presentation")
        if ns.FluxRaidQueueRosterPaint then
            first=frames[2]
            initial=calls.aura
            for _=1,4 do ns.FluxRaidQueueRosterPaint(first) end
            fire(first,"UNIT_AURA",first.unit)
            check(calls.aura==initial and pending()==1,client..": companion requests share the same driver")
            flush()
            check(calls.aura==initial+1,client..": companion full paint absorbs pending aura work")
        end
        return synchronous,total,queued,reveal
    end
    return Burst,flush,Work
end

local reassignmentBefore=compareReassignment and read(arg[1] .. "/RaidFrame-FluxRaidUnit.lua")
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"}) do
    for _,count in ipairs({5,40}) do
        for _,combat in ipairs({false,true}) do
            local _,_,work=reassignmentModel(client,nil,count,combat)
            local sync,total,wake,reveal=work()
            check(sync==0 and total==count and wake==1 and reveal==1,
                client..": roster burst and reveal each paint the current unit once")
            if reassignmentBefore then
                local _,_,oldWork=reassignmentModel(client,reassignmentBefore,count,combat)
                local beforeSync,beforeTotal,beforeWake,beforeReveal=oldWork()
                check(beforeSync==count*3 and beforeTotal==count*4 and beforeWake==1 and beforeReveal==2,
                    client..": exact pre-change module repaints within native callbacks")
                print(("RAID_REASSIGN %s count=%d combat=%s sync=%d/%d total=%d/%d reveal=%d/%d"):format(
                    client,count,tostring(combat),beforeSync,sync,beforeTotal,total,beforeReveal,reveal))
            end
        end
    end
end

local function rosterRangeModel(client, body, members, fallback, combat)
    local e,cell,_,flush,pending,facts,calls,_,_,_,tickers=fixture(client,body)
    e.FluxRaidVisuals.SetJoinedEdges=function() end
    local frames={}
    local requiredWrites,rangeWrites=0,0
    for index=1,members do
        local unit="raid"..index
        facts[unit]={name=unit,connected=true,health=50,maximum=100,power=40,powerMax=100,range=true}
        local frame=cell("RosterRange"..index)
        frame.shown=false
        local register=frame.RegisterUnitEvent
        function frame:RegisterUnitEvent(event, ...)
            if event=="UNIT_IN_RANGE_UPDATE" then
                rangeWrites=rangeWrites+1
                if fallback then error("range event unavailable") end
            else requiredWrites=requiredWrites+1 end
            return register(self,event,...)
        end
        frames[index]=frame
    end
    local poolReads=0
    local unbound=setmetatable({},{__index=function(_,key)
        if key=="unit" then poolReads=poolReads+1 end
    end})
    e.FluxRaidState.frameArray[unbound]=true
    e.combat=combat
    local function cycle(verify)
        local seen,required,optional,aura=poolReads,requiredWrites,rangeWrites,calls.aura
        local function SetUnit(frame,unit)
            frame.attrs.unit=unit
            e.FluxRaid_OnUnitAttributeChanged(frame,"unit",unit)
        end
        for index,frame in ipairs(frames) do
            local unit="raid"..index
            SetUnit(frame,unit)
            frame.shown=true
            e.FluxRaidUnit_OnShow(frame)
            if verify then check(frame.name.text==unit and frame.events.UNIT_HEALTH==unit,
                "first reveal paints and installs required routes immediately") end
        end
        local immediate=poolReads-seen
        if verify then
            check(pending()==1 and calls.aura-aura==members,"reveals share the existing border callback")
            if fallback then
                check(tickers[#tickers] and not tickers[#tickers].cancelled,"the first visible fallback owner starts immediately")
            else check(immediate==0 and #tickers==0,"native range reveals defer the pool scan and create no ticker") end
        end
        flush()
        local joined=poolReads-seen
        seen=poolReads
        for _,frame in ipairs(frames) do
            frame.shown=false
            e.FluxRaidUnit_OnHide(frame)
            SetUnit(frame,nil)
            if verify then check(not next(frame.events) and not frame.auraActive,"leave clears native routes and paint immediately") end
        end
        if verify then check(poolReads==seen and pending()==1,"leave shares the existing border callback") end
        flush()
        if verify then
            check(poolReads-seen==2 and pending()==0,"one border pass and one range discovery settle the leave")
            if fallback then check(tickers[#tickers].cancelled,"the last fallback leaves and its ticker stops in the same dispatch")
            else check(joined==2,"one border pass and one range discovery settle the native join") end
            check(rangeWrites-optional==members*(fallback and 2 or 1),"optional range registration retains its reveal retry")
        end
        return joined,poolReads-seen,requiredWrites-required,rangeWrites-optional
    end
    return cycle
end

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"}) do
    local _,_,required=rosterRangeModel(client,nil,5,false,false)(true)
    local _,_,fallbackRequired=rosterRangeModel(client,nil,5,true,true)(true)
    check(required>0 and fallbackRequired==required,"a range-only failure preserves the other unit routes")
end

for _,requiredFailure in ipairs({false,true}) do
    local e,cell,_,flush,_,_,_,_,_,_,tickers=fixture("forever")
    e.FluxRaidVisuals.SetJoinedEdges=function() end
    local frame=cell("DelayedRangeSupport")
    frame.shown=false
    local register=frame.RegisterUnitEvent
    local unavailable=true
    local requiredWrites=0
    function frame:RegisterUnitEvent(event,...)
        if event~="UNIT_IN_RANGE_UPDATE" then requiredWrites=requiredWrites+1 end
        if unavailable and (event=="UNIT_IN_RANGE_UPDATE" or requiredFailure and event=="UNIT_AURA") then
            error("route unavailable")
        end
        return register(self,event,...)
    end
    frame.attrs.unit="party1"
    e.FluxRaid_OnUnitAttributeChanged(frame,"unit","party1")
    local initial=requiredWrites
    unavailable=false
    frame.shown=true
    e.FluxRaidUnit_OnShow(frame)
    flush()
    check(frame.events.UNIT_AURA=="party1" and frame.events.UNIT_IN_RANGE_UPDATE=="party1" and #tickers==0,
        "reveal still repairs a failed required route and recovers native range support")
    check(requiredWrites==initial*(requiredFailure and 2 or 1),
        "optional recovery leaves established routes alone while required failures retain a full retry")
end

local function ActiveHeaderReplay(client, body, mode)
    local e, cell, _, flush, _, facts, calls, queries = fixture(client, body)
    local state = e.FluxRaidState
    local active = mode == "raid" and 8 or mode == "party" and 1 or 0
    local watched, parked
    for group = 1, 8 do
        local header = e.CreateFrame("Frame", "PreparedGroup" .. group)
        header.shown = group <= active
        state.raidHeaders[group] = header
        for index = 1, 5 do
            local position = (group - 1) * 5 + index
            local frame = cell("PreparedMember" .. position, header)
            frame.shown = header.shown
            header.attrs["child" .. index] = frame
            if frame.shown then
                local unit = "raid" .. position
                facts[unit] = {name = unit, health = 70, maximum = 100, power = 40, powerMax = 100, connected = true, range = true}
                frame:SetAttribute("unit", unit)
                watched = frame
            elseif not parked then parked = frame end
        end
    end
    local tanks = e.CreateFrame("Frame", "PreparedMTMA")
    tanks.shown = false
    state.mtmaHeader = tanks
    for i = 1, 40 do
        local frame = cell("PreparedTank" .. i, tanks)
        frame.shown = false
        tanks.attrs["child" .. i] = frame
    end
    flush()
    local attachments, borderRequests = 0, 0
    e.FluxRaid_AttachOrUpdateMTMATarget = function() attachments = attachments + 1 end
    e.FluxRaid_RequestJoinedBorderRefresh = function() borderRequests = borderRequests + 1 end
    queries.children, calls.aura = 0, 0
    for _ = 1, 8 do
        e.FluxRaid_SyncHeaderChildUnits(nil, true)
        e.FluxRaid_RefreshMTMATargetAttachments(true)
        flush()
    end
    local result = {reads=queries.children, attaches=attachments, paints=calls.aura}
    check(calls.aura == active * 5 * 8 and borderRequests == 8,
        "prepared roster preserves visible paint and border dispatch")
    if watched then check(watched.name.text == watched.unit, "visible header still binds and paints its units") end
    if body then return result end

    check(result.reads == active * 6 * 8 and result.attaches == 0, "hidden header pools perform no child enumeration")
    local function RepairRead(getter)
        tanks.IsShown = getter
        attachments, queries.children = 0, 0
        e.FluxRaid_RefreshMTMATargetAttachments(true)
        check(attachments == 40 and queries.children == 40, "unknown visibility retains the attachment recovery scan")
    end
    RepairRead(function() return e.secret end)
    RepairRead(function() error("unavailable") end)
    RepairRead(false)
    tanks.IsShown = nil
    tanks.shown = true
    tanks.alpha = 0
    attachments, queries.children = 0, 0
    e.FluxRaid_RefreshMTMATargetAttachments(true)
    check(attachments == 40 and queries.children == 40, "a shown alpha-zero header remains in the prepared scan")
    tanks.shown = false
    attachments, queries.children = 0, 0
    e.FluxRaid_RefreshMTMATargetAttachments()
    check(attachments == 40 and queries.children == 40, "explicit attachment recovery includes hidden slots")

    parked = parked or tanks.attrs.child1
    local parent = parked:GetParent()
    local before = calls.aura
    e.combat = true
    parked.attrs.unit = "party2"
    e.FluxRaid_OnUnitAttributeChanged(parked, "unit", "party2")
    e.FluxRaid_SyncHeaderChildUnits(nil, true)
    flush()
    check(parked.events.UNIT_HEALTH == "party2" and calls.aura == before + active * 5,
        "hidden assignment registers its current unit independently of the roster scan")
    parent.shown, parked.shown = true, true
    e.FluxRaidUnit_OnShow(parked)
    check(parked.name.text == "Second" and parked.auraActive and parked.healthBar.value == 25,
        "native reveal immediately paints the newly assigned unit")
    return result
end

local activeHeadersBefore = compareActiveHeaders and read(arg[1] .. "/RaidFrame-FluxRaidUnit.lua")
for _, client in ipairs({"live", "forever", "classic", "classic_era", "classic_anniversary"}) do
    for _, mode in ipairs({"raid", "party", "solo"}) do
        local after = ActiveHeaderReplay(client, nil, mode)
        if activeHeadersBefore then
            local before = ActiveHeaderReplay(client, activeHeadersBefore, mode)
            check(before.reads == 1024 and before.attaches == 320 and after.paints == before.paints,
                "archived full scan covers the same visible paint and does extra hidden work")
            print(("RAID_ACTIVE_HEADERS|%s|%s|%d|%d|%d|%d|%d"):format(client, mode, before.reads, after.reads,
                before.attaches, after.attaches, after.paints))
        end
    end
end

-- Rebind now both removes the map entry and clears/recycles its dirty flags.
-- Retaining the entry alone is harmless when those flags were already cleared.
local stale,changed=unitSource:gsub('    ClearPendingPaint%(frame%)\n    ClearUnitEvents%(frame%)',
    '    -- stale work and its old-unit flags intentionally retained\n    ClearUnitEvents(frame)')
check(changed==1,"negative control mutates the current rebind cleanup")
check(not pcall(exercise,"live",stale),"negative control rejects retained old-unit work on rebind")
local noHide=unitSource:gsub('if FluxRaidAuras then FluxRaidAuras.Clear%(self%) end','-- missing hide cleanup')
check(not pcall(exercise,"live",noHide),"negative control rejects missing hide cleanup")
local overflowingMini=unitSource:gsub('local miniH = FluxRaidVisuals%.MINI_FRAME_HEIGHT or Compat%.MTMA_TARGET_HEIGHT or 18',
    'local miniH = math.floor(FluxRaidVisuals.FRAME_HEIGHT * 0.5 + 0.5)')
check(not pcall(exercise,"live",overflowingMini),"negative control rejects a mini that overflows its fixed target reservation")
local staleRetirement,replacements=unitSource:gsub('        frame%._fluxClearedUnitEvents = nil\n        local registered = true',
    '        local registered = true')
check(replacements==1 and not pcall(EventRetirementReplay,"live",staleRetirement,5,false),
    "negative control rejects a registration that leaves the clear hint active")
print("Raid healer runtime: "..checks.." checks; complete Compat/Unit modules; four rejected negative controls")
