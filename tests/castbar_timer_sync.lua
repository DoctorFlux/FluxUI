-- Compare real Flux timer helpers against source-pinned Blizzard countdowns.
-- Opaque sentinels verify addon-side operations, not native taint certification.
local function read(path)local f=assert(io.open(path,"rb"),path);local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local source=read(os.getenv("FLUX_CAST_TIMER_SOURCE")or"UnitFrames/FluxCastBar.lua")
local a=assert(source:find("local function ReadCastBarProgress",1,true) or source:find("local function AccessibleRemainingSeconds",1,true))
local b=assert(source:find("local function SafeCompareGUID",a,true))
local opaque=setmetatable({},{__lt=function()error("opaque comparison")end,__sub=function()error("opaque subtraction")end,__tostring=function()error("opaque formatting in Lua")end})
local E=setmetatable({IsSecretValue=function(v)return rawequal(v,opaque)end,GetTime=function()return 100 end,
    CastBarSpellTextLeftPad=function()return 4 end,CASTBAR_TEXT_RIGHT_PAD=4,CASTBAR_TEXT_TIME_GAP=4},{__index=_G})
local remaining,paint=assert(load(source:sub(a,b-1).."\nreturn AccessibleRemainingSeconds,PaintCastBarRemainingTime","@cast-timer","t",E))()
local nativeCache=os.getenv("FLUX_CAST_TIMING_NATIVE")
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local native
    if nativeCache then native=read(nativeCache.."/native-"..client..".lua")
    else
        local text=read("../__AddonsForRef/wow-ui-source-"..client.."/Interface/AddOns/Blizzard_UIPanels_Game/Shared/CastingBarFrame.lua")
        native=assert(text:match("function CastingBarMixin:UpdateCastTimeText%(%)%s.-\nend"))
    end
    local N=setmetatable({CastingBarMixin={},CAST_BAR_CAST_TIME="%.1f"},{__index=_G})
    assert(load(native,"@native-time-"..client,"t",N))()
    for _,unit in ipairs({"player","party1","party4","target","focus"})do
        local f={unitID=unit,casting=true,value=0,maxValue=999,_fluxCastWallStart=0,_fluxCastWallMax=999}
        local value,max=2,10
        f.GetValue=function()return value end;f.GetMinMaxValues=function()return 0,max end
        f.Time={SetText=function(s,v)s.text=v end,SetFormattedText=function(s,fmt,v) s.text=rawequal(v,opaque)and v or string.format(fmt,v)end,Show=function()end,Hide=function()end}
        f.CastTimeText=f.Time
        for _,channel in ipairs({false,true})do
            f.casting=not channel;f.channeling=channel
            for _,sample in ipairs({{2,10},{8,12},{1,3},{0,4},{4,4}})do
                value,max=sample[1],sample[2]
                N.CastingBarMixin.UpdateCastTimeText(f);local expected=f.Time.text
                paint(f);check(f.Time.text==expected,client.." "..unit.." follows displayed bar across cast/channel/delay/replacement")
            end
        end
        f._fluxUsedTimerDuration=true
        local clock={GetRemainingDuration=function()return 2.25 end}
        f.GetTimerDuration=function()return clock end
        value,max=5,100;paint(f);check(f.Time.text=="2.2","engine countdown takes precedence over stale duration/value caches")
        clock.GetRemainingDuration=function()return opaque end
        f.Text={IsShown=function()return true end,SetWidth=function(s,w)s.width=w end,SetWordWrap=function()end}
        f.GetWidth=function()return 100 end;f.Time.GetStringWidth=function()return opaque end
        paint(f);check(rawequal(f.Time.text,opaque)and f.Text.width==60,"opaque remaining duration forwards to native text sink with safe width reserve")
        f._fluxUsedTimerDuration=false;f.GetValue=function()return opaque end
        paint(f);check(f.Time.text=="","unavailable bar clock clears stale text instead of inventing wall-clock time")
    end
end
-- Replay the full production CastStart/event/OnUpdate lifecycle with the existing
-- five-client school fixture. No duplicate cast implementation is introduced.
local fixtureText=read("tests/castbar_school_themes.lua")
local prefix=fixtureText:sub(1,assert(fixtureText:find("local function checkParticleGeometry",1,true))-1)
prefix=prefix:gsub('pet="PetFrame"','pet="PetFrame",party1="PartyFrame"')
local fixture=assert(load(prefix.."\nreturn fixture","@full-cast-fixture","t",_G))()
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    for _,unit in ipairs({"party1","target","focus"})do
        local s,e,ns=fixture(client)
        local bar=s.NewBar(unit)
        s.casts[unit]={name="Spell",id=133};bar:CastStart(unit,false,"cast-1")
        s.Tick(.2)
        local _,maximum=bar:GetMinMaxValues();local actual=maximum-bar:GetValue()
        check(bar.Time.text==string.format("%.1f",actual),"full cast lifecycle timer matches displayed fill")
        s.Event(bar,"UNIT_SPELLCAST_DELAYED",unit,"cast-1",133);s.Tick(.1)
        _,maximum=bar:GetMinMaxValues();actual=maximum-bar:GetValue()
        check(bar.Time.text==string.format("%.1f",actual),"delayed cast stays synchronized through production event routing")
        if client=="live"or client=="forever"then
            ns.API.isV12=true
            local methods=getmetatable(e.UIParent).__index
            methods.SetTimerDuration=function(self,duration)self.duration=duration;self.low=0;self.high=10;self.value=3 end
            methods.GetTimerDuration=function(self)return self.duration end
            local left=7
            local duration={GetRemainingDuration=function()return left end}
            e.UnitCastingDuration=function()return duration end
            e.UnitCastingInfo=function()return "Spell","Spell",133,s.secret,s.secret,false,"cast-engine",false,133 end
            local engine=s.NewBar(unit)
            engine.Time.SetFormattedText=function(self,fmt,v)self.text=rawequal(v,s.secret)and v or string.format(fmt,v)end
            engine.Time.GetStringWidth=function(self)if rawequal(self.text,s.secret)then return s.secret end;return 28 end
            engine:CastStart(unit,false,"cast-engine")
            check(engine._fluxUsedTimerDuration and engine.Time.text=="7.0","engine-owned cast text ignores guessed total duration")
            left=6.5;s.Tick(.1)
            check(engine.Time.text=="6.5" and engine:GetValue()==3,"native engine owns progress; text follows its duration object")
            left=s.secret;s.Tick(.1)
            check(rawequal(engine.Time.text,s.secret),"full engine path forwards opaque countdown without inspecting it")
            e.FluxUnitFrames_ShouldShowCastTime=function()return false end;s.Tick(.1)
            check(not engine.Time.shown,"timer setting hides engine-driven text")
        end
    end
end
print("Cast timer synchronization: "..checks.." checks across five client source models; native visuals/taint pending")
