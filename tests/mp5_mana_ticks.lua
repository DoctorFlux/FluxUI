-- Production MP5 timing and mana feedback. Desktop fixtures cannot emulate
-- WoW's secure VM; fail explicitly on secure-parent mutations in combat.
local checks=0
local function check(ok,message) assert(ok,message);checks=checks+1 end
local function loadAddon(path,env,ns)
    local fn,err
    if _VERSION=="Lua 5.1" then fn,err=loadfile(path);if fn then setfenv(fn,env) end
    else fn,err=loadfile(path,"t",env) end
    assert(fn,err)("_FluxUI",ns)
end
local function fixture(branch,initial)
    local s={now=10,mana=initial or 100,maximum=100,powerType=0,enabled=true,frames={},partitionHooks={},timers={}}
    local e=setmetatable({},{__index=_G});e._G=e
    local methods={}
    local function object(kind,parent)
        return setmetatable({kind=kind,parent=parent,shown=true,scripts={},hooks={},events={},width=200,height=16,
            level=10,low=0,high=100,value=0,color={0,0,1,1}},{__index=methods})
    end
    function methods:SetScript(key,fn)self.scripts[key]=fn end
    function methods:GetScript(key)return self.scripts[key] end
    function methods:HookScript(key,fn)self.hooks[key]=self.hooks[key] or {};table.insert(self.hooks[key],fn)end
    function methods:Hide()local was=self.shown;self.shown=false;if was then for _,fn in ipairs(self.hooks.OnHide or {})do fn(self)end end end
    function methods:Show()local was=self.shown;self.shown=true;if not was then for _,fn in ipairs(self.hooks.OnShow or {})do fn(self)end end end
    function methods:IsShown()return self.shown end
    function methods:SetParent(parent)assert(not s.combat,"combat reparent");self.parent=parent end
    function methods:GetParent()return self.parent end
    function methods:ClearAllPoints()assert(not(s.combat and self.parent==s.player),"combat secure-child layout");self.points={}end
    function methods:SetPoint(...)self.point={...}end
    function methods:SetAllPoints(target)self.allPoints=target end
    function methods:GetWidth()return self.width end
    function methods:GetHeight()return self.height end
    function methods:SetWidth(v)self.width=v end
    function methods:SetHeight(v)self.height=v end
    function methods:GetFrameLevel()return self.level end
    function methods:SetFrameLevel(v)self.level=v end
    function methods:GetFrameStrata()return "MEDIUM"end
    function methods:SetFrameStrata()end
    function methods:EnableMouse()end
    function methods:SetTexture(v)self.path=v end
    function methods:SetAlpha(v)self.alpha=v end
    function methods:SetBlendMode()end
    function methods:SetVertexColor()end
    function methods:SetTexCoord()end
    function methods:SetHorizTile()end
    function methods:SetVertTile()end
    function methods:CreateTexture()return object("Texture",self)end
    function methods:SetStatusBarTexture(v)self.fill=self.fill or self:CreateTexture();self.fill:SetTexture(v)end
    function methods:GetStatusBarTexture()return self.fill end
    function methods:SetMinMaxValues(a,b)self.low,self.high=a,b end
    function methods:SetValue(v)self.value=v end
    function methods:SetStatusBarColor(...)self.color={...}end
    function methods:GetStatusBarColor()return (unpack or table.unpack)(self.color)end
    function methods:RegisterEvent(event)self.events[event]=true end
    function methods:RegisterUnitEvent(event,unit)self.events[event]=unit end
    function methods:UnregisterAllEvents()self.events={}end
    e.CreateFrame=function(kind,_,parent)local f=object(kind,parent);s.frames[#s.frames+1]=f;return f end
    e.GetTime=function()return s.now end
    e.UnitPower=function()return s.mana end
    e.UnitPowerMax=function()return s.maximum end
    e.UnitPowerType=function()return s.powerType end
    e.UnitIsDead=function()return s.dead or false end
    e.UnitGUID=function(unit)return "guid-"..unit end
    e.FluxUnitFrames_IsFeatureEnabled=function()return s.enabled end
    e.C_Timer={After=function(_,fn)s.timers[#s.timers+1]=fn end}
    e.hooksecurefunc=function(frame,key,fn)check(key=="UpdatePartition","only hook layout");table.insert(s.partitionHooks,fn)end
    e.UIParent=object("Frame")
    local client={isEra=branch=="era",isAnniversary=branch=="anniversary",isTBC=branch=="tbc",isForever=branch=="forever"}
    e.FLUX_API=client
    local api={SafeUnitPower=e.UnitPower,SafeUnitPowerMax=e.UnitPowerMax,
        IsSecretValue=function(v)return type(v)=="table" and v.secret end,
        CanAccessValue=function(v)return not(type(v)=="table" and v.secret)end}
    api.SafeGetNumber=function(v,fallback)if not api.CanAccessValue(v)then return fallback end;return tonumber(v) or fallback end
    local ns={API=api,Flux={Client=client},UnitFrames={UsesHudUnitBars=function()return branch=="live" or branch=="forever"end}}
    s.player=object("Frame",e.UIParent);s.player.unit="player"
    s.player.Power=object("StatusBar",s.player);s.player.Power:SetStatusBarTexture("mana")
    s.player.AdditionalPower=object("StatusBar",s.player);s.player.AdditionalPower:SetStatusBarTexture("mana")
    s.originalPartition=function()s.partitions=(s.partitions or 0)+1 end
    s.player.UpdatePartition=s.originalPartition
    loadAddon("UnitFrames/FluxMP5Overlay.lua",e,ns)
    loadAddon("UnitFrames/FluxPowerCostOverlay.lua",e,ns)
    function s.Initialize()
        ns.MP5Overlay.Initialize(s.player)
        for _,f in ipairs(s.frames)do
            if f.events.UNIT_POWER_UPDATE then s.driver=f end
            if f.kind=="StatusBar" and f.high==5 then s.fsr=f end
            if f.kind=="StatusBar" and f.high==2 then s.tick=f end
        end
    end
    function s.Event(event,unit,token)if s.driver and s.driver.events[event]then s.driver.scripts.OnEvent(s.driver,event,unit or "player",token)end end
    function s.Advance(seconds)s.now=s.now+seconds;if s.driver and s.driver.scripts.OnUpdate then s.driver.scripts.OnUpdate(s.driver,seconds)end end
    function s.Partition()s.player:UpdatePartition();for _,fn in ipairs(s.partitionHooks)do fn(s.player)end end
    function s.Flush()local callbacks=s.timers;s.timers={};for _,fn in ipairs(callbacks)do fn()end end
    return s,e,ns
end

for _,branch in ipairs({"era","anniversary","tbc","forever"})do
    local s,e,ns=fixture(branch,50);s.Initialize()
    check(s.tick and s.tick:IsShown() and e.FluxPerfMP5Armed,branch.." initial low mana shows tick immediately")
    s.Advance(0.75);check(s.tick.value>0,branch.." tick sweeps")
    s.mana=60;s.Event("UNIT_POWER_UPDATE","player","MANA")
    check(s.tick.value==0,branch.." observed regen resynchronizes tick")
    s.combat=true;s.mana=40;s.Event("UNIT_POWER_UPDATE","player","MANA")
    s.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast")
    check(s.fsr:IsShown() and not s.tick:IsShown(),branch.." power-before-success starts FSR in combat")
    s.Advance(1);local remaining=s.fsr.value
    s.Initialize();s.Flush()
    check(s.fsr.value==remaining,branch.." options preserve FSR phase")
    check(s.player.UpdatePartition==s.originalPartition and #s.partitionHooks==1,branch.." options preserve layout hook ownership")
    s.Partition();check(s.fsr.parent==e.UIParent and s.tick.parent==e.UIParent,branch.." overlays stay outside secure frame in combat")
    s.Advance(4.1);check(s.tick:IsShown() and not s.fsr:IsShown(),branch.." regen tick returns after FSR")
    s.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast");s.mana=20;s.Event("UNIT_POWER_UPDATE","player","MANA")
    check(s.fsr:IsShown(),branch.." success-before-power starts FSR")
    s.Advance(5.1);s.mana=100;s.Event("UNIT_POWER_UPDATE","player","MANA")
    check(not s.tick:IsShown() and not e.FluxPerfMP5Armed,branch.." full mana parks animation")
    s.mana=80;s.Event("UNIT_POWER_UPDATE","player","MANA");s.Advance(0.6)
    check(not s.fsr:IsShown(),branch.." mana drop without cast does not start FSR")
    s.powerType=3;s.player.isAdditionalPowerShown=true;s.Event("UNIT_DISPLAYPOWER")
    check(s.tick.point[2]==s.player.AdditionalPower,branch.." shapeshift uses secondary mana")
    s.player.AdditionalPower:Hide();s.player.isAdditionalPowerShown=false;s.Event("UNIT_DISPLAYPOWER")
    check(not s.tick:IsShown() and not e.FluxPerfMP5Armed,branch.." energy-only form hides mana tick")
    s.powerType=0;s.Event("UNIT_DISPLAYPOWER")
    s.mana=60;s.Advance(0.1);s.Event("UNIT_SPELLCAST_SUCCEEDED","player","cast")
    check(s.fsr:IsShown(),branch.." rendering between power change and success preserves spending snapshot")
    s.Advance(5.1)
    s.player:Hide();check(not s.tick:IsShown() and not e.FluxPerfMP5Armed,branch.." hidden player hides UIParent overlays")
    s.player:Show();check(s.tick:IsShown(),branch.." showing player restores tick")
    s.dead=true;s.Advance(0.1);check(not e.FluxPerfMP5Armed,branch.." death stops tick")
    s.dead=false;s.Event("PLAYER_ALIVE");check(s.tick:IsShown(),branch.." resurrection restarts tick")
    local count=#s.frames;s.enabled=false;s.Initialize();s.enabled=true;s.Initialize();s.Flush()
    check(#s.frames==count and #s.partitionHooks==1,branch.." disable/re-enable reuses frames and hooks")
    s.mana={secret=true};s.Event("UNIT_POWER_UPDATE","player","MANA")
    check(not e.FluxPerfMP5Armed and not s.tick:IsShown(),branch.." inaccessible mana safely pauses")
end

for _,branch in ipairs({"live","mists","wrath","cata"})do
    local s,e,ns=fixture(branch,50);s.Initialize()
    check(not s.driver and not ns.MP5Overlay.SupportsClient(),branch.." no synthetic mana-tick timer")
end

-- Large mana increases are the path that previously produced the white flash.
for _,branch in ipairs({"era","anniversary","forever","live","mists"})do
    for _,kind in ipairs({"mana","secondary mana","energy","spend"})do
        local s,e,ns=fixture(branch,40)
        s.powerType=(kind=="secondary mana" or kind=="energy") and 3 or 0
        local bar=kind=="secondary mana" and s.player.AdditionalPower or s.player.Power
        bar._fluxGhostPrimed=true;bar._fluxFeedbackGUID="guid-player";bar._fluxPrevFillW=100
        bar.fill.width=kind=="spend" and 60 or 140
        ns.PowerCostOverlay.RefreshPrediction=function()end
        ns.PowerCostOverlay.AfterPowerApplied(bar,"player",70,100)
        local shouldSuppress=ns.MP5Overlay.SupportsClient() and (kind=="mana" or kind=="secondary mana")
        check((bar.FeedbackFrame==nil)==shouldSuppress,branch.." "..kind.." gain suppression scope")
        if bar.FeedbackFrame then
            if kind=="spend" then check(bar.FeedbackFrame.updatingLoss,branch.." spending feedback retained")
            else check(bar.FeedbackFrame.updatingGain,branch.." non-tick gain feedback retained")end
        end
    end
end

do
    local s,e,ns=fixture("forever",50)
    s.maximum={secret=true}
    e.FluxAPICompat={GetPlayerHasMana=function()error("unsafe legacy mana comparison")end}
    s.Initialize()
    check(s.driver and not e.FluxPerfMP5Armed,"inaccessible maximum installs event listener without unsafe mana cache")
    s.maximum=100;s.Event("UNIT_MAXPOWER")
    check(s.tick:IsShown(),"readable maximum restores tick after secret pause")
end

do
    local s,e,ns=fixture("era",50)
    local bar=s.player.Power
    s.powerType=3
    bar._fluxGhostPrimed=true;bar._fluxFeedbackGUID="guid-player";bar._fluxPrevFillW=60;bar.fill.width=100
    ns.PowerCostOverlay.RefreshPrediction=function()end
    ns.PowerCostOverlay.AfterPowerApplied(bar,"player",50,100)
    check(bar.FeedbackFrame.updatingGain,"energy gain can start feedback")
    s.powerType=0;bar.fill.width=150
    ns.PowerCostOverlay.AfterPowerApplied(bar,"player",75,100)
    check(not bar.FeedbackFrame.updatingGain and not bar.FeedbackFrame:IsShown(),"mana recovery clears a lingering gain flash")
end
print("PASS MP5 mana ticks: "..checks.." checks (native rendering and taint unverified)")
