-- Real PCO module, synthetic native values/animations and strict protected
-- frame permissions. Optional exact source path; --measure records baseline.
local path=arg[1]or"UnitFrames/FluxPowerCostOverlay.lua"
local measure=arg[2]=="--measure"
local checks=0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local function corrected(ok,label)if not measure then check(ok,label)end end
local function read(file)local f=assert(io.open(file,"rb"));local s=f:read("*a");f:close();return s:gsub("\r\n","\n")end
local base=read("tests/unit_overlay_secret_identity.lua")
base=base:sub(1,assert(base:find("local function healthCases()",1,true))-1)
local context=setmetatable({arg={"UnitFrames/FluxHealthLossOverlay.lua",path}},{__index=_G})
local make=assert(load(base.."\nreturn fixture","@power-idle-native-boundary","t",context))()

local function fixture(client)
    local s=make(client=="live"or client=="forever")
    local e,pco,uf=s.env,s.pco,s.ns.UnitFrames
    local metrics={attempts=0,errors=0,queued=0,timerCalls=0,ghostValues=0,ghostTextures=0,paths=0,updates=0}
    s.metrics=metrics;s.pending={};s.timers={};s.combat=false
    e.InCombatLockdown=function()return s.combat end
    s.ns.Flux.Client={isForever=client=="forever",isEra=client=="classic_era",isMists=client=="classic",isAnniversary=client=="classic_anniversary"}
    s.player.protected=true;s.player.Power.protected=true;s.player.AdditionalPower.protected=true
    local methods=getmetatable(s.player).__index
    local function protected(object)
        if object.kind=="Texture"then return false end
        local f=object;while f do if f.protected then return true end;f=f.parent end
        return false
    end
    local function permission(object,operation)
        if s.combat and protected(object)then
            metrics.attempts=metrics.attempts+1;error("ADDON_ACTION_BLOCKED "..operation)
        end
    end
    for _,name in ipairs({"Show","Hide","SetPoint","ClearAllPoints","SetAllPoints","SetFrameLevel","SetParent","SetHeight","SetWidth"})do
        local old=methods[name]
        methods[name]=function(object,...)
            permission(object,name)
            if name=="SetAllPoints"then local anchor=...;if anchor and protected(anchor)then object.protected=true end end
            return old(object,...)
        end
    end
    local create=e.CreateFrame
    e.CreateFrame=function(kind,name,parent,...)
        if s.combat and parent and protected(parent)then metrics.attempts=metrics.attempts+1;error("ADDON_ACTION_BLOCKED CreateFrame")end
        return create(kind,name,parent,...)
    end
    local animations=methods.CreateAnimationGroup
    function methods:CreateAnimationGroup()
        permission(self,"CreateAnimationGroup")
        return animations(self)
    end
    local nativeTexture,nativeValue=methods.SetStatusBarTexture,methods.SetValue
    function methods:SetStatusBarTexture(texture)
        local ghost=self==s.player.Power.PowerGhost or self==s.player.AdditionalPower.PowerGhost
        if ghost then
            metrics.ghostTextures=metrics.ghostTextures+1
            if s.failTexture then s.failTexture=false;return false end
            if s.throwTexture then s.throwTexture=false;error("temporary texture write failure")end
        end
        nativeTexture(self,texture);return true
    end
    function methods:SetValue(value)
        local ghost=self==s.player.Power.PowerGhost or self==s.player.AdditionalPower.PowerGhost
        if ghost then
            metrics.ghostValues=metrics.ghostValues+1
            if s.failValue then s.failValue=false;error("temporary value write failure")end
        end
        nativeValue(self,value)
        if self.fill and not s.ns.API.IsSecretValue(value)and not s.ns.API.IsSecretValue(self.high)and self.high>0 then
            self.fill.width=value/self.high*self.width
        end
    end
    local nativeMinMax=methods.SetMinMaxValues
    function methods:SetMinMaxValues(low,high)
        if (self==s.player.Power.PowerGhost or self==s.player.AdditionalPower.PowerGhost)and s.failMaximum then
            s.failMaximum=false;error("temporary maximum write failure")
        end
        return nativeMinMax(self,low,high)
    end
    uf.GetHudBarTexture=function(atlas)
        metrics.paths=metrics.paths+1
        return s.ns.Flux.Client.isForever and("Media/Retail/"..atlas..".tga")or atlas
    end
    uf.DeferProtected=function(key,fn)s.pending[key]=fn end
    e.C_Timer={After=function(delay,fn)
        metrics.queued=metrics.queued+1;s.timers[#s.timers+1]={at=s.now+delay,fn=fn}
    end}
    function s:flush()
        local due=self.timers;self.timers={}
        for _,timer in ipairs(due)do
            if timer.at<=self.now then metrics.timerCalls=metrics.timerCalls+1;timer.fn()
            else self.timers[#self.timers+1]=timer end
        end
    end
    function s:advance(dt)
        self.now=self.now+dt;self:flush()
        for _,frame in ipairs(self.frames)do
            local shown=frame:IsShown();local parent=frame:GetParent()
            while parent and shown do shown=parent:IsShown();parent=parent:GetParent()end
            if shown and frame:GetScript("OnUpdate")then metrics.updates=metrics.updates+1;frame:GetScript("OnUpdate")(frame,dt)end
        end
    end
    function s:paint(value,bar,unit)
        bar=bar or self.player.Power;unit=unit or self.player.unit
        bar:SetMinMaxValues(0,100);bar:SetValue(value)
        pco.AfterPowerApplied(bar,unit,value,100)
    end
    function s:deferred()
        local pending=self.pending;self.pending={};for _,fn in pairs(pending)do fn()end
    end
    function s:try(fn)
        local ok,err=pcall(fn);if not ok then metrics.errors=metrics.errors+1 end
        corrected(ok,"owned PCO operation: "..tostring(err));return ok
    end
    function s:effective(texture)
        if not texture or not texture:IsShown()then return false end
        local parent=texture:GetParent()
        while parent do if not parent:IsShown()then return false end;parent=parent:GetParent()end
        return true
    end
    function s:finish(bar)
        local f=bar.FeedbackFrame
        if not f then return end
        for _,group in ipairs({f.SecretLossAnim,f.SecretBarAnim})do
            if group then group.playing=false;if group.scripts.OnFinished then group.scripts.OnFinished(group)end end
        end
    end
    uf.UpdatePower=function(frame,unit)s:paint(s.current or 50,frame.Power,unit)end
    uf.UpdateAdditionalPower=function(frame,unit)if frame.AdditionalPower then s:paint(s.additional or 50,frame.AdditionalPower,unit)end end
    pco.RefreshPrediction=s.realPrediction
    return s,pco,uf,e
end

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local s,pco,uf,e=fixture(client);local bar=s.player.Power
    local created=#s.frames
    pco.CreateOverlay(bar) -- The actual party factory's mount path, without Initialize.
    local prepared=#s.frames-created
    corrected(prepared==3,"factory prepares exactly three reusable native helper frames per enabled bar")
    corrected(not s.player.PowerCostWatcher,"factory-only preparation never installs a party watcher")
    s:paint(100);s:paint(100);s:flush()
    local ghost=bar.PowerGhost
    bar._fluxBarAtlas="Mana";s:paint(100);s:flush()
    s.metrics.queued,s.metrics.ghostValues,s.metrics.ghostTextures,s.metrics.paths=0,0,0,0
    for _=1,1000 do s:paint(100)end
    local queued=s.metrics.queued;s:flush()
    corrected(queued==1,"1000 unchanged paints share one original next-frame commit")
    corrected(s.metrics.ghostValues==0 and s.metrics.ghostTextures==0 and s.metrics.paths==0,
        "settled public ghost avoids redundant writes and repeated texture path concatenation")
    local steadyWrites=s.metrics.ghostValues
    for _=1,50 do s:paint(100);s:flush()end
    corrected(s.metrics.ghostValues==steadyWrites,"separately settled unchanged samples retain successful public ghost state")
    s:paint(80);s:paint(60);s:paint(40)
    check(ghost.value==100,"latest same-frame values preserve the old ghost until next frame")
    s:flush();check(ghost.value==40,"coalesced callback commits the latest value")
    -- Shared's AFK painter runs after AfterPowerApplied. Keep that late art.
    bar._fluxBarAtlas=nil;bar:SetStatusBarColor(0,0,1);s:paint(40);s:flush()
    s:paint(40);bar:SetStatusBarColor(.5,.5,.5);s:flush()
    check(ghost.color[1]==.5 and ghost.color[2]==.5,"next-frame commit observes late same-frame AFK art")
    bar._fluxBarAtlas="Energy";s:paint(40);s:flush()
    check(ghost.fill.path==uf.GetHudBarTexture("Energy"),"raw atlas mutation replaces ghost art")
    local resolver=uf.GetHudBarTexture
    uf.GetHudBarTexture=function(atlas)return"new-resolver/"..atlas end
    s:paint(40);s:flush();check(ghost.fill.path=="new-resolver/Energy","texture resolver replacement invalidates cached path")
    uf.GetHudBarTexture=resolver
    s.ns.Flux.Client={isForever=not s.ns.Flux.Client.isForever};s:paint(40);s:flush()
    check(ghost.fill.path==uf.GetHudBarTexture("Energy"),"client identity mutation invalidates cached path")
    -- A native false result is not a successful cached art application.
    bar._fluxBarAtlas="Rage";s.failTexture=true;s:paint(35);s:flush()
    s:paint(35);s:flush();check(ghost.fill.path==uf.GetHudBarTexture("Rage"),"false texture sink result retries on next ordinary paint")
    bar._fluxBarAtlas="Focus";s.throwTexture=true;s:paint(30)
    check(not pcall(function()s:flush()end),"temporary art sink exception remains observable")
    s:paint(30);s:flush();check(ghost.fill.path==uf.GetHudBarTexture("Focus"),"pending ownership clears before a failed art sink")
    s.failMaximum=true;s:paint(25);s:flush();s:paint(25);s:flush()
    check(ghost.value==25 and ghost.high==100,"failed maximum sink cannot poison public commit cache")
    -- Keep all engine-owned opaque updates, even the exact same opaque object.
    local opaque=s:secret("number");local writes=s.metrics.ghostValues
    s:paint(opaque);s:flush();s:paint(opaque);s:flush()
    check(s.metrics.ghostValues==writes+2 and s.opaqueOps==0,"opaque values retry native sinks without cached equality or arithmetic")
    -- Existing event ordering: a queued regular update cannot replace the old
    -- ghost before a cast completion has used it; holds end at exactly 0.6s.
    s:paint(100);s:flush();s:paint(100);s:flush();s:paint(80)
    bar._fluxCastFinish=true;bar._fluxCastUnit=s.player.unit;s:paint(60);s:flush()
    if client=="live"or client=="forever"then
        check(ghost.value==100 and bar._fluxGhostHolding,"cast completion invalidates pending ordinary commit and holds old ghost")
        s:advance(.59);check(ghost.value==100,"ghost hold retains original 0.6s cadence")
        s:advance(.011);check(ghost.value==60 and not bar._fluxGhostHolding,"hold completion commits newest values")
    else check(ghost.value==60,"readable fallback retains next-frame completion behavior")end
    -- First real spend/gain/secret feedback occurs in combat, after OOC prep.
    s.powerType=3;s.combat=true;s.metrics.attempts,s.metrics.errors=0,0
    s:try(function()s:paint(100);s:flush();s:paint(100);s:flush();s:paint(50);s:flush()end)
    local f=bar.FeedbackFrame
    corrected(f and f.updatingLoss and s:effective(f.BarTexture),"prepared combat spender retains visible slice")
    s:try(function()s:advance(.7)end)
    corrected(f and not f.updatingLoss and not s:effective(f.BarTexture)and not f:GetScript("OnUpdate"),
        "readable completion hides effect art and detaches its driver without protected frame visibility changes")
    s:try(function()s:paint(50);s:flush();s:paint(100);s:flush()end)
    corrected(f and f.updatingGain and s:effective(f.GainGlowTexture)==false,"gain animation keeps its original first paint boundary")
    s:try(function()s:advance(.1)end)
    corrected(f and s:effective(f.GainGlowTexture),"active gain retains original per-frame slice")
    s:try(function()
        s:paint(opaque);s:flush();bar._fluxCastFinish=true;bar._fluxCastUnit=s.player.unit
        s:paint(opaque);s:flush()
    end)
    if client=="live"or client=="forever"then
        corrected(f.secretPlaying and s:effective(f.BarTexture)and not f:GetScript("OnUpdate"),
            "engine-owned secret animation requires no per-frame Lua driver")
        s:try(function()s:finish(bar)end)
        corrected(not f.secretPlaying and not s:effective(f.BarTexture)and not s:effective(f.GainGlowTexture),
            "secret completion hides all ended effect art in combat")
    end
    s:try(function()pco.DisableForFrame(s.player);s:advance(1)end)
    corrected(not f:GetScript("OnUpdate")and not s:effective(f.BarTexture)and ghost.alpha==0,
        "combat disable parks art and callbacks while native ghost remains invisible")
    corrected(s.metrics.attempts==0 and s.metrics.errors==0,"combat first use/disable/finish attempt no protected mutation")
    print(string.format("PCO_WORK|client=%s|prewarm=%d|burstQueued=%d|burstGhostWrites=%d|protectedAttempts=%d|errors=%d",
        client,prepared,queued,steadyWrites,s.metrics.attempts,s.metrics.errors))
end

do
    local s,pco,uf,e=fixture("forever");local bar=s.player.Power
    -- Secondary bars are UIParent children, so parent identity cannot own prep.
    s.player.AdditionalPower:SetParent(e.UIParent)
    s.combat=true
    s:try(function()s:paint(40);s:paint(45,s.player.AdditionalPower)end)
    local pending=0;for _ in pairs(s.pending)do pending=pending+1 end
    corrected(pending==2 and not bar.PowerGhost,"cold primary and UIParent secondary have independent deferred preparation")
    s:try(function()pco.DisableForFrame(s.player)end)
    s.combat=false;s:deferred()
    corrected(not bar.PowerGhost and not s.player.AdditionalPower.PowerGhost,"disable invalidates cold preparation callbacks")
    s.combat=true
    s:try(function()s:paint(55);s:paint(65,s.player.AdditionalPower)end)
    s.combat=false;s:deferred()
    corrected(bar.PowerGhost and s.player.AdditionalPower.PowerGhost and bar.PowerGhost.value==55
        and s.player.AdditionalPower.PowerGhost.value==65,"per-bar cold preparation restores latest primary/secondary values")
    corrected(not s.player.PowerCostWatcher and not e.UIParent.PowerCostWatcher,"bar-only recovery cannot install party/UIParent watchers")
    corrected(s.metrics.attempts==0,"cold preparation makes zero protected allocation or geometry attempts")
end
do
    local s,pco=fixture("forever")
    s.combat=true
    s:try(function()
        pco.Initialize(s.player)
        s:paint(30)
        s.guid="replacement-guid";s.player.unit="focus";s.ns.FocusFrame=s.player
        s:paint(60)
    end)
    s.current=75;s.combat=false;s:deferred()
    corrected(s.player.PowerCostWatcher and s.player.PowerCostWatcher.unit=="focus"
        and s.player.PowerCostWatcher.events.UNIT_POWER_UPDATE=="focus",
        "cold Initialize intent survives identity/token replacement and registers latest unit")
    corrected(s.player.Power.PowerGhost and s.player.Power.PowerGhost.value==75 and s.metrics.attempts==0,
        "cold Initialize restores the latest native value instead of the old unit snapshot")
    local disabled,dp=fixture("forever");disabled.combat=true
    disabled:try(function()dp.Initialize(disabled.player);disabled:paint(30);dp.DisableForFrame(disabled.player)end)
    disabled.combat=false;disabled:deferred()
    corrected(not disabled.player.PowerCostWatcher and not disabled.player.Power.PowerGhost,
        "explicit disable cancels cold watcher/preparation intent before deferred flush")
end
print("power cost idle work: "..checks.." checks PASS; actual PCO, native secure/FPS/pixels pending")
