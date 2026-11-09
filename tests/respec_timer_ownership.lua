-- Actual picker modules and talent timer owners; native After deliberately returns nil.
local root = arg[1] or "."
if not root:match("[/\\]$") then root = root .. "/" end
local selected=arg[2]
local checks = 0
local function check(v, why) checks = checks + 1; assert(v, why) end
local function read(path) local f=assert(io.open(root..path,"rb"));local s=f:read("*a");f:close();return(s:gsub("\r\n","\n"))end
local function part(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(i,assert(s:find(b,i+#a,true),b)-1)end
local function fixture(native)
    local s={now=0,timers={},frames={}}
    local e=setmetatable({},{__index=_G});e._G=e;s.e=e
    e.GetTime=function()return s.now end
    local function timer(delay,fn)
        local t={at=s.now+delay,fn=fn};function t:Cancel()self.cancelled=true end
        s.timers[#s.timers+1]=t;return t
    end
    e.C_Timer={After=function(delay,fn)timer(delay,fn)end}
    if native then e.C_Timer.NewTimer=timer end
    e.CreateFrame=function()
        local f={events={},scripts={}}
        function f:RegisterEvent(event)self.events[event]=true end
        function f:UnregisterAllEvents()self.events={}end
        function f:SetScript(key,fn)self.scripts[key]=fn end
        function f:Show()self.shown=true end
        function f:Hide()self.shown=false end
        s.frames[#s.frames+1]=f;return f
    end
    function s:advance(now)
        self.now=now;local q=self.timers;self.timers={}
        for _,t in ipairs(q)do if not t.cancelled then if t.at<=now then t.fn()else self.timers[#self.timers+1]=t end end end
    end
    function s:pending()local n=0;for _,t in ipairs(self.timers)do if not t.cancelled then n=n+1 end end;return n end
    return s,e
end
for _,native in ipairs({false,true})do
    if not selected or selected=="picker" then
    for _,which in ipairs({"Gear","Rune"})do
        local s,e=fixture(native)
        local R={Compat={IsSoD=function()return true end},GetActiveName=function()return nil end}
        e.FluxRespec=R
        assert(loadfile(root.."Respec/FluxRespec_"..which.."Picker.lua","t",e))()
        local p=R[which.."Picker"];local shown={};local alternatives=true
        p.HasAlternatives=function()return alternatives end
        p.Show=function(anchor,slot)shown[#shown+1]={anchor,slot}end -- presentation boundary only
        local anchor={IsMouseOver=function()return false end}
        p.NotifyStripEnter(anchor,13);p.NotifyStripLeave();s:advance(.06)
        check(#shown==0,which.." leave must reject stale show")
        p.NotifyStripEnter(anchor,13);p.Hide();s:advance(.12)
        check(#shown==0,which.." Hide must reject stale show")
        p.NotifyStripEnter(anchor,13);s.now=.15;p.NotifyStripEnter(anchor,14)
        s:advance(.18);check(#shown==0,"replaced hover retains 60ms deadline")
        s:advance(.211);check(#shown==1 and shown[1][2]==14,"new hover opens exactly once after 60ms")
        p.NotifyStripEnter(anchor,13);alternatives=false;p.NotifyStripEnter(anchor,14);s:advance(.3)
        check(#shown==1,"invalid replacement cannot leave previous hover queued")
        alternatives=true
        local fly={shown=true,over=false};function fly:IsShown()return self.shown end
        function fly:IsMouseOver()return self.over end;function fly:Hide()self.shown=false end
        p._flyout=fly;p._anchorRef=anchor;p.ScheduleHideSoon();s:advance(.77)
        check(fly.shown,"hide preserves 480ms grace")
        s:advance(.781);check(not fly.shown,"hide runs after grace when no hover remains")
        fly.shown=true;p.ScheduleHideSoon();p.CancelHideTimer();s:advance(1.3)
        check(fly.shown,"re-enter cancellation cannot hide reused flyout")
        fly.over=true;p.ScheduleHideSoon();s:advance(1.8)
        check(fly.shown,"mouse over flyout preserves visibility")
        fly.over=false;p._anchorRef={IsMouseOver=function()return true end};p.ScheduleHideSoon();s:advance(2.3)
        check(fly.shown,"mouse over anchor preserves visibility")
        p._anchorRef=anchor;e.FluxBlizzardDropdown={IsMouseOver=function()return true end};p.ScheduleHideSoon();s:advance(2.8)
        check(fly.shown,"dropdown hover preserves flyout")
        e.FluxBlizzardDropdown=nil;p.ScheduleHideSoon();p.Hide();s:advance(3.3)
        check(p._anchorRef==nil and p._openSlotID==nil and not fly.shown,"Hide clears state and delayed work")
    end
    end
    local text=read("Respec/FluxRespec_Talents.lua")
    local clear=part(text,"local function ClearSpecSwitchAwait()","local function ClearSpecSwitchSettleDefer()")
    local await=part(text,"local function AwaitSpecSwitch(onDone)","--- Inactive talent group")
    local s,e=fixture(native);local completions={}
    if not selected or selected=="spec" then
    local start,abort=assert(load("local specSwitchAwaitTimer,specSwitchAwaitFrame\n"..clear..await.."\nreturn AwaitSpecSwitch,ClearSpecSwitchAwait","@talent-spec-owner","t",e))()
    start(function(ok,why)completions[#completions+1]={ok,why,"A"}end)
    s.now=4.9;abort();start(function(ok,why)completions[#completions+1]={ok,why,"B"}end)
    local newest=s.frames[#s.frames];s:advance(5)
    check(newest.scripts.OnEvent~=nil and #completions==0,"old spec timeout cannot detach newer watcher or complete stale owner")
    newest.scripts.OnEvent(newest,"ACTIVE_TALENT_GROUP_CHANGED");s:advance(10)
    check(#completions==1 and completions[1][1] and completions[1][3]=="B","replacement spec event completes exactly its owner")
    start(function(ok,why)completions[#completions+1]={ok,why,"C"}end);s:advance(15)
    check(#completions==2 and not completions[2][1] and completions[2][2]=="SPEC_SWITCH_TIMEOUT","ordinary five-second timeout remains")
    end
    local cancel=part(text,"local function CancelLearnWatchdog(state)","local function ClearLearnLoopState()")
    local schedule=part(text,"local function ScheduleLearnContinue(state)","--- Sync optimistic state")
    if not selected or selected=="learn" then
    s,e=fixture(native);e.Talents={};e.calls=0
    local request,stop=assert(load("local learnDeferFrame\nlocal LEARN_DEFER_SECONDS=.06\nlocal TryLearnNextPoint=function()calls=calls+1 end\n"..cancel..schedule.."\nreturn ScheduleLearnContinue,CancelLearnWatchdog","@talent-learn-owner","t",e))()
    local state={};e.Talents._state=state
    for i=1,1000 do request(state)end
    check(s:pending()==(native and 1 or 1000),"native timer cancellation bounds pending learn callbacks")
    s:advance(.059);check(e.calls==0,"learn cadence keeps 60ms delay")
    s:advance(.06);check(e.calls==1,"same-state obsolete callbacks cannot burst LearnTalent")
    request(state);s.now=.09;request(state);s:advance(.12)
    check(e.calls==1,"replacement preserves latest learn deadline")
    s:advance(.151);check(e.calls==2,"latest learn callback completes once")
    request(state);stop(state);s:advance(.22);check(e.calls==2,"cancelled learn callback cannot run")
    request(state);e.Talents._state={};s:advance(.3);check(e.calls==2,"replaced talent state rejects old callback")
    end
end
print(("Respec timer ownership: %d checks; native NewTimer and void-After fallback; picker/spec/learn cadence PASS"):format(checks))
