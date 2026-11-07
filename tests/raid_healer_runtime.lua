-- Complete production Compat/Unit modules with narrow widget/API contracts.
-- Native rendering, event delivery, secure input and taint need client checks.
local function read(path)
    local file=assert(io.open(path,"rb"));local value=file:read("*a"):gsub("\r\n","\n");file:close();return value
end
local compatSource,unitSource=read("RaidFrame/FluxRaidCompat.lua"),read("RaidFrame/FluxRaidUnit.lua")
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function fixture(client,body)
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
    local queries={health=0,power=0,range=0,name=0}
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
    e.C_PartyInfo={GetLootMethod=function()return 2,e.lootPartyID,e.lootRaidID end}
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
    function methods:GetAttribute(key)return self.attrs[key]end
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
    assert(load(compatSource,"@FluxRaidCompat","t",e))("_FluxUI",ns)
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
    return e,cell,fire,flush,pending,facts,calls,queries,options,registered,tickers
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

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do exercise(client)end
local stale=unitSource:gsub('pendingPaint%[frame%]=nil','-- stale work intentionally retained')
check(not pcall(exercise,"live",stale),"negative control rejects retained old-unit work on rebind")
local noHide=unitSource:gsub('if FluxRaidAuras then FluxRaidAuras.Clear%(self%) end','-- missing hide cleanup')
check(not pcall(exercise,"live",noHide),"negative control rejects missing hide cleanup")
local overflowingMini=unitSource:gsub('local miniH = FluxRaidVisuals%.MINI_FRAME_HEIGHT or Compat%.MTMA_TARGET_HEIGHT or 18',
    'local miniH = math.floor(FluxRaidVisuals.FRAME_HEIGHT * 0.5 + 0.5)')
check(not pcall(exercise,"live",overflowingMini),"negative control rejects a mini that overflows its fixed target reservation")
print("Raid healer runtime: "..checks.." checks; complete Compat/Unit modules; three rejected negative controls")
