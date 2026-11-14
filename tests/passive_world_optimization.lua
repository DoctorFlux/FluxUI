-- Production-body replays. Optional arg1 is an exact external source checkpoint.
-- Counts/host heap are synthetic work evidence, not WoW FPS, pixels or taint.
local baselineRoot = arg and arg[1]
local checks, results = 0, {}
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local function section(s, first, last)
    local a = assert(s:find(first, 1, true), first)
    local b = assert(s:find(last, a + #first, true), last)
    return s:sub(a, b - 1)
end
local function env()
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.unpack = table.unpack; return e
end
local function prefix(path, last, suffix, extra)
    local e = env(); for k,v in pairs(extra or {}) do e[k] = v end
    local body = read(path); body = body:sub(1, assert(body:find(last, 1, true)) - 1)
    return assert(load(body .. "\n" .. suffix, "@fixture:" .. path, "t", e))()
end
local function body(path, before)
    return read(before and baselineRoot .. "/" .. path or path)
end
local function record(name, value) results[#results + 1] = name .. "=" .. value end

-- A managed timer retains the old active deadline. The timerless path remains
-- byte-for-byte equivalent in phase, overshoot and visibility behavior.
local function hover(text, managed, realFallback)
    local s = { now = 0, frames = {}, timers = {}, callbacks = 0, probes = 0, changes = 0, has = true, peek = false, errors = 0 }
    local e = env()
    local function after(delay, fn) s.timers[#s.timers + 1] = { at = s.now + delay, fn = fn } end
    e.Flux = { Timer = {} }
    if managed then
        e.Flux.Timer.NewTicker = function(delay, fn)
            local t = {}; function t:Cancel() self.cancelled = true end
            local function run()
                if t.cancelled then return end
                s.callbacks = s.callbacks + 1; fn()
                if not t.cancelled then after(delay, run) end
            end
            after(delay, run); return t
        end
        e.C_Timer = { NewTicker = e.Flux.Timer.NewTicker }
    else
        e.C_Timer = {}
    end
    e.Bars = { SlotProgram = { HasHover = function() return s.has end } }
    e.PeekContext = function()
        s.probes = s.probes + 1
        if s.throwOnce then s.throwOnce=false;error("controlled hover context failure")end
        return s.peek
    end
    e.CreateFrame = function()
        local f = { shown = false, scripts = {} }
        function f:Hide() self.shown = false end
        function f:Show() self.shown = true end
        function f:SetScript(k,v) self.scripts[k] = v end
        s.frames[#s.frames + 1] = f; return f
    end
    if realFallback then
        e.C_Timer={};e.geterrorhandler=function()return function()s.errors=s.errors+1 end end
        assert(load(read("Core/Engine/Timer.lua"),"@actual-managed-timer","t",e))("_FluxUI",{Flux=e.Flux})
    end
    local first = text:find("local function StopPeekPoller()", 1, true) and "local function StopPeekPoller()" or "local function ArmPeekPoller()"
    local interval=assert(text:match("local PEEK_POLL = ([%d%.]+)"))
    local pre = "local Bars,Flux,PeekContext=Bars,Flux,PeekContext\nlocal peekPoller,peekTimer,peekPollAccum,lastPeek=nil,nil,0,false\nlocal PEEK_POLL="..interval.."\nlocal ProgramFace={}\nProgramFace.RequestHoverPeek=function() NotePeek();lastPeek=PeekContext() end\n"
    e.NotePeek = function() s.changes = s.changes + 1 end
    s.arm = assert(load(pre .. section(text, first, "local peekPending = false") .. "\nreturn ArmPeekPoller", "@hover-body", "t", e))()
    function s:step(dt)
        self.now = self.now + dt
        for _,f in ipairs(self.frames) do if f.shown and f.scripts.OnUpdate then
            self.callbacks=self.callbacks+1
            local ok,err=pcall(f.scripts.OnUpdate,f,dt)
            if not ok then if not self.expectError then error(err)end;self.errors=self.errors+1 end
        end end
        local due = self.timers; self.timers = {}
        for _,t in ipairs(due) do if t.at <= self.now+1e-9 then t.fn() else self.timers[#self.timers+1] = t end end
    end
    s.arm(); return s
end
local function testHover(text, before)
    local s = hover(text, true)
    for _=1,14400 do s:step(1/240) end
    check(s.changes == 0 and s.probes > 1000, "hover fallback retains active context checks while idle")
    local callbacks = s.callbacks
    if not before then check(callbacks < 1300, "50ms hover timer avoids per-render dispatch") end
    s.peek=true;for _=1,14 do s:step(1/240) end
    check(s.changes == 1,"hover entry detected by unchanged 50ms fallback")
    s.peek=false;for _=1,14 do s:step(1/240) end
    check(s.changes == 2,"hover leave detected by unchanged 50ms fallback")
    s.has=false;s.arm();local stopped=s.probes
    for _=1,100 do s:step(.01) end
    check(s.probes == stopped,"removed hover assignments cancel outstanding timer work")
    return callbacks
end

local trinketFixture = prefix("tests/idle_trinkets.lua", "local function replay(body, branch)", "return fixture")
local function trinketBody(text) return section(text,"local keyPushWatch = CreateFrame","-- /use 13 parses") end
local function testTrinket(text, before)
    local s = trinketFixture(trinketBody(text),"live")
    s.bindings={{},{}};s:event("UPDATE_BINDINGS");local callbacks=0
    for _=1,1000 do if s.watch.shown then callbacks=callbacks+1 end;s:step(.001) end
    if not before then check(callbacks == 0,"unbound trinket watcher sleeps") end
    s.mouse.LeftButton=true;s:input(1,"OnMouseDown","LeftButton");s:step(.01)
    check(s.widgets[1]._fluxTrinketPushShade.shown,"unbound mouse press wakes immediate visual/release tracking")
    s.mouse.LeftButton=false;s:event("GLOBAL_MOUSE_UP");s:step(.01);s:step(.21)
    check(not s.widgets[1]._fluxTrinketPushShade.shown,"unbound release clears on same existing deadline")
    s:input(1,"OnClick","KeyBind",true);s:step(.01)
    check(s.widgets[1]._fluxTrinketPushShade.shown,"wheel-only click wakes its tap flash")
    s:step(.21);check(not s.widgets[1]._fluxTrinketPushShade.shown,"wheel-only tap flash clears without a physical binding")
    s.bindings={{"Q"},{}};s:event("UPDATE_BINDINGS");s.down.Q=true;s:step(.01)
    check(s.widgets[1]._fluxTrinketPushShade.shown,"new binding immediately rearms polling")
    s.hidden=true;s.tm.SyncKeybindPushWatch();check(not s.watch.shown,"hidden grid retires watcher")
    return callbacks
end

local stanceFixture = prefix("tests/stance_aura_text_cache.lua", "local function exercise(body)", "return fixture")
local function testStance(text, before)
    local s = stanceFixture(text);local btn,fs,holder,cd,digits=s:button({legacy=true})
    function holder:IsShown()return self.shown==true end
    local formats=0
    for i=1,20 do local name,e=debug.getupvalue(s.format,i);if not name then break end;if name=="_ENV" then
        e.tostring=function(v)formats=formats+1;return tostring(v)end
    end end
    s.active[btn]=true
    for i=1,1000 do
        s.now=i/1000;digits.alpha,digits.color=1,1;s.tick()
        check(digits.alpha==0 and digits.color==0,"native digit reset still repaired in the same frame")
    end
    check(fs.displayed=="10m" and holder.shown,"public countdown appearance retained")
    check(s.nativeHide==1000 and s.nativeRegions==1000,"native legacy discovery/suppression cadence preserved")
    if not before then check(formats==1 and s.holderShow==1,"settled owned time formatting/holder writes are eliminated") end
    local stableFormats=formats
    holder.shown=false;s.tick();check(holder.shown,"external owned-holder hide repairs immediately")
    btn.StanceBuffExpirationTime=90;s.now=0;s.tick();check(fs.displayed=="2m","ninety-second boundary retained")
    s.now=.001;s.tick();check(fs.displayed=="89","below-ninety boundary retained without delay")
    btn.StanceBuffExpirationTime=s.secret;s.tick();check(not s.active[btn] and fs.displayed=="","opaque expiration is not compared or cached")
    return stableFormats
end

local function loot(text)
    local s={now=0,frames={},writes=0};local e=env()
    e.anchor={shown=false,SetScript=function(self,k,v)self[k]=v end,Show=function(self)self.shown=true end,Hide=function(self)self.shown=false end}
    e.GetTime=function()return s.now end
    e.MakeRow=function()
        local f={shown=false,alpha=1,icon={SetTexture=function()end},text={SetText=function()end,SetTextColor=function()end}}
        function f:Show()self.shown=true end;function f:Hide()self.shown=false end
        function f:SetAlpha(v)s.writes=s.writes+1;self.alpha=v end
        s.frames[#s.frames+1]=f;return f
    end
    local pre="local rows,pool={},{}\nlocal MAX_ROWS=3\nlocal anchor=anchor\nlocal function Settings()return {alerts=true,duration=3,quality=0}end\nlocal function Readable(v)return type(v)=='string'end\nlocal function Reflow()end\nlocal function CursorOrigin()return {x=0,y=0}end\n"
    s.show=assert(load(pre..section(text,"local function Show(textValue", "local function ItemKey").."\nreturn Show","@loot-body","t",e))()
    function s:step(dt)self.now=self.now+dt;if e.anchor.shown then e.anchor.OnUpdate(e.anchor)end end
    function s:snapshot()
        local out={};for i,f in ipairs(self.frames)do out[#out+1]=string.format("%d:%s:%.9f",i,tostring(f.shown),f.alpha)end
        return table.concat(out,"|")
    end
    return s
end
local function testLoot(text,before)
    local s=loot(text);for i=1,3 do s.show("item",nil,nil,true)end
    for _=1,1000 do s:step(.002)end
    if not before then check(s.writes==3,"stable loot rows write full opacity once")end
    local writes=s.writes
    s:step(.75)
    for _,f in ipairs(s.frames)do check(math.abs(f.alpha-.5)<1e-7,"loot retains the exact final-half-second alpha")end
    for _=1,225 do s:step(.002)end
    for _,f in ipairs(s.frames)do check(not f.shown,"loot expires on existing deadline")end
    s.show("pooled",nil,nil,true);s:step(.002)
    check(s.frames[3].shown or s.frames[2].shown or s.frames[1].shown,"expired loot row can be reused")
    for _,f in ipairs(s.frames)do if f.shown then check(f.alpha==1,"pooled fade alpha restores on first frame")end end
    return writes
end

local function lfg(text,managed,realFallback)
    local s={now=0,timers={},writes=0,callbacks=0,active=false,errors=0,timerFrames={}};local e=env()
    local btn={shown=true,scripts={},hooks={}}
    function btn:SetScript(k,v)self.scripts[k]=v end
    function btn:IsVisible()return self.shown end
    function btn:HookScript(k,v)self.hooks[k]=v end
    function btn:hide()self.shown=false;if self.hooks.OnHide then self.hooks.OnHide(self)end end
    function btn:show()self.shown=true;if self.hooks.OnShow then self.hooks.OnShow(self)end end
    e.btn,e.eyeTexture=btn,{SetTexCoord=function(_,...)
        s.writes=s.writes+1
        if s.throwOnce then s.throwOnce=false;error("controlled eye texture failure")end
        s.coords={...}
    end}
    e.GetTime=function()return s.now end
    e.Flux={Timer={}}
    if managed then e.Flux.Timer.After=function(delay,fn)s.timers[#s.timers+1]={at=s.now+delay,fn=fn}end end
    if realFallback then
        e.C_Timer={};e.geterrorhandler=function()return function()s.errors=s.errors+1 end end
        e.CreateFrame=function()
            local f={shown=false,scripts={}}
            function f:Show()self.shown=true end;function f:Hide()self.shown=false end
            function f:SetScript(k,v)self.scripts[k]=v end
            function f:IsShown()return self.shown end
            s.timerFrames[#s.timerFrames+1]=f;return f
        end
        assert(load(read("Core/Engine/Timer.lua"),"@actual-managed-timer","t",e))("_FluxUI",{Flux=e.Flux})
    end
    e.C_LFGList={GetApplications=function()return {}end,HasActiveEntryInfo=function()return s.active end}
    s.update=assert(load("local btn,eyeTexture=btn,eyeTexture\n"..section(text,"        -- Animation Logic","        -- Hook events").."\nreturn UpdateLFGStatus","@lfg-body","t",e))()
    s.btn=btn
    function s:step(dt)
        self.now=self.now+dt
        if btn.shown and btn.scripts.OnUpdate then
            self.callbacks=self.callbacks+1;local ok,err=pcall(btn.scripts.OnUpdate,btn,dt)
            if not ok then if not self.expectError then error(err)end;self.errors=self.errors+1 end
        end
        for _,f in ipairs(self.timerFrames)do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f,dt)end end
        local due=self.timers;self.timers={}
        for _,t in ipairs(due)do if t.at<=self.now+1e-9 then
            self.callbacks=self.callbacks+1;local ok,err=pcall(t.fn)
            if not ok then if not self.expectError then error(err)end;self.errors=self.errors+1 end
        else self.timers[#self.timers+1]=t end end
    end
    return s
end
local function testLfg(text,before)
    local s=lfg(text,true);s.active=true;s.update()
    for _=1,400 do s:step(.025)end
    check(s.writes==100,"LFG eye keeps every nominal ten-Hz update")
    if not before then check(s.callbacks<=100,"LFG eye avoids per-render callback dispatch")end
    local callbacks=s.callbacks
    s:step(.025);s.btn:hide();local frame=s.btn.currentFrame
    for _=1,40 do s:step(.025)end
    check(s.btn.currentFrame==frame,"hidden eye keeps its animation frame")
    s.btn:show();for _=1,4 do s:step(.025)end
    check(s.btn.currentFrame~=frame,"visible eye resumes its carried phase")
    s.active=false;s.update();frame=s.btn.currentFrame
    for _=1,40 do s:step(.025)end
    check(s.btn.currentFrame==0 and frame==0,"stopped eye ignores stale timers and resets frame")
    local phase=lfg(text,true);phase.active=true;phase.update();phase:step(.025);phase.btn:hide()
    phase:step(.2);phase.btn:show();phase:step(.05)
    check(phase.btn.currentFrame==0,"hidden eye does not advance before its carried deadline")
    phase:step(.025);check(phase.btn.currentFrame==1,"hidden eye resumes its carried 25ms phase")
    return callbacks
end

local function testTimerErrors(hoverText,eyeText)
    -- Load the actual Timer.lua with no native timer APIs. Its local polyfills
    -- must not replace recoverable OnUpdate observers/animation fallbacks.
    local h=hover(hoverText,false,true);h.expectError,h.throwOnce,h.peek=true,true,true
    for _=1,100 do h:step(.01)end
    check(h.errors==1 and h.probes>=19 and h.changes==1,"actual timerless hover recovers after one reported probe error")
    check(#h.frames==2 and not h.frames[1].shown,"hover keeps old frame path with no native ticker")
    local fallback=lfg(eyeText,true,true);fallback.expectError,fallback.throwOnce,fallback.active=true,true,true;fallback.update()
    for _=1,40 do fallback:step(.025)end
    check(fallback.errors==1 and fallback.writes==10,"actual timerless eye retains cadence and recovers after a texture error")
    check(type(fallback.btn.scripts.OnUpdate)=="function" and not fallback.timerFrames[1].shown,"eye uses old frame path with no native After")
    local native=lfg(eyeText,true);native.expectError,native.throwOnce,native.active=true,true,true;native.update()
    for _=1,40 do native:step(.025)end
    check(native.errors==1 and native.writes==10,"native After eye rearms before a transient paint error")
end

local function threatPoll(text)
    local s={now=0,target="targettarget",combat=true,probes=0,updates=0};local e=env()
    e.GetTime=function()return s.now end
    e.GetThreatTarget=function()s.probes=s.probes+1;return s.target end
    e._UnitAffectingCombat=function()s.probes=s.probes+1;return s.combat end
    e.Threat={Active=true,options={updatespeed=.2},saveddata={event_led_threat_updates=true},GetPluginInstance=function()s.probes=s.probes+1;return true end}
    e.ThreatFrame={IsVisible=function()return not s.hidden end}
    e.UpdateDisplay=function()s.updates=s.updates+1 end
    local pre="local Threat,ThreatFrame,GetThreatTarget,_UnitAffectingCombat,UpdateDisplay=Threat,ThreatFrame,GetThreatTarget,_UnitAffectingCombat,UpdateDisplay\nlocal lastThreatPollTime,threatPollDeferred=0,false\n"
    s.tick=assert(load(pre..section(text,"    local function ThreatFrame_OnUpdate()","    local function syncThreatPollingScript()").."\nreturn ThreatFrame_OnUpdate","@threat-poll-body","t",e))()
    return s
end
local function testThreat(text,before)
    local s=threatPoll(text)
    for i=1,1000 do s.now=i/1000;s.tick()end
    check(s.updates==4 or s.updates==5,"targettarget threat refresh deadline retained")
    local probes=s.probes
    if not before then check(probes<30,"not-due threat frames avoid target/combat/plugin probes")end
    s.hidden=true;s.now=4;s.tick();check(s.probes==probes,"hidden threat never probes")
    return probes
end

local function questie(text)
    local fixture=read("Minimap/_tmp_questiesmoke.lua")
    fixture=fixture:sub(1,assert(fixture:find("local function CheckParity(forever)",1,true))-1)
    fixture=fixture:gsub('Load%("Minimap/FluxQuestie.lua"%)','Load("Minimap/FluxQuestie.lua",WORLD_SOURCE)')
    local e=env();e.WORLD_SOURCE=text;e.arg={ [0]="Minimap/_tmp_questiesmoke.lua" }
    local factory=assert(load(fixture.."\nreturn NewRuntime","@questie-fixture","t",e))()
    local s=factory(true);s.NativeTracker();local modules=s.Questie(true);s.Event("PLAYER_LOGIN");s.Drain()
    s.module=modules;s.controller=s.ns.FluxQuestie
    return s
end
local function testQuestie(text,before)
    local s=questie(text);local n=s.Counts()
    for _=1,100 do s.module.QuestieTracker:Update()end
    local mutations=s.Counts()-n
    if not before then check(mutations<5000,"Questie skips settled geometry/style setters")end
    local line=s.module.TrackerLinePool.GetLine(2);line.width=1;line.label.points={};line.label.width=1
    s.module.QuestieTracker:Update()
    check(line.width>1 and #line.label.points==2 and line.label.width>1,"Questie recycled/native-overwritten line is repaired immediately")
    local changed=s.Counts();s.SetCombat(true);s.controller:UpdateLayout()
    check(s.Counts()==changed,"Questie combat defers addon geometry")
    s.SetCombat(false);s.Event("PLAYER_REGEN_ENABLED");s.Drain()
    return mutations
end

local function nativeMeter(path,override)
    local fixture=read("tests/standalone_threat_meter.lua")
    fixture=fixture:sub(1,assert(fixture:find("\nlocal s = boot(\"forever\")",1,true))-1)
    local e=env();e.arg={path}
    e.loadfile=function(file,mode,target)
        if file==path then return load((override or read(file)).."\n_G.__worldData=function()return data end", "@"..file,mode,target)end
        return loadfile(file,mode,target)
    end
    local factory=assert(load(fixture.."\nreturn boot","@native-meter-fixture","t",e))()
    return factory("forever",true)
end
local function testNativeMeter(path,before,override)
    local s=nativeMeter(path,override);s.combat=true;s.group=5
    s.sample("player",100,100,true)
    for i=1,4 do s.sample("party"..i,100-i,10-i)end
    local pane=s.meter:Embed(s.host,1);s.tick(0)
    local writes=0
    local function count(object,method)
        local old=object[method];object[method]=function(self,...)writes=writes+1;return old(self,...)end
    end
    for _,row in ipairs(s.visible())do
        count(row,"SetStatusBarColor");count(row,"SetAlpha");count(row.Icon,"SetTexture");count(row.Icon,"SetTexCoord")
        count(row.Name,"SetTextColor");count(row.Value,"SetTextColor")
    end
    local unique,allocated={},0
    for _=1,100 do
        s.tick(.21)
        for _,sample in ipairs(s.env.__worldData())do if not unique[sample]then unique[sample]=true;allocated=allocated+1 end end
    end
    if not before then check(writes==0 and allocated==5,"native threat reuses samples and unchanged public styling: writes="..writes..", samples="..allocated)end
    local settledWrites=writes
    local first=s.visible()[1];s.classes.player="PRIEST";s.names.player="renamed";s.tick(.21)
    check(first.Name.text:find("renamed",1,true),"threat name changes paint on the same collection")
    s.meter:Hide();local queries=s.queries;s.tick(10)
    check(s.queries==queries and pane:GetScript("OnUpdate")==nil,"hidden threat retires sampling")
    return allocated,settledWrites
end

local function replace(text,old,new)
    local a,b=assert(text:find(old,1,true),old)
    return text:sub(1,a-1)..new..text:sub(b+1)
end

local paths={"Bars/ProgramFace.lua","ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua","Bars/Stance/Extras.lua","Other/FluxLoot.lua","MicroMenu/FluxLFGMicroButton.lua","Battlezonemap/FluxThreat.lua","Minimap/FluxQuestie.lua","Battlezonemap/FluxThreatMeter.lua"}
local tests={testHover,testTrinket,testStance,testLoot,testLfg,testThreat,testQuestie}
testTimerErrors(body(paths[1]),body(paths[5]))
for pair=1,3 do
    for i,test in ipairs(tests)do
        local current=test(body(paths[i]),false)
        local old=baselineRoot and test(body(paths[i],true),true)
        record("pair"..pair..":"..paths[i],tostring(old or "none").."->"..current)
    end
    local current,writes=testNativeMeter(paths[8],false)
    local old,oldWrites
    if baselineRoot then old,oldWrites=testNativeMeter(baselineRoot.."/"..paths[8],true)end
    record("pair"..pair..":nativeSamples",tostring(old or "none").."->"..current)
    record("pair"..pair..":nativeStyle",tostring(oldWrites or "none").."->"..writes)
end

-- Exact traces on the unchanged fallback and owned per-frame alpha path.
if baselineRoot then
    local a,b=hover(body(paths[1],true),false),hover(body(paths[1]),false)
    for i=1,1000 do
        if i==151 then a.peek,b.peek=true,true end
        if i==487 then a.peek,b.peek=false,false end
        local dt=i%7==0 and .081 or .007;a:step(dt);b:step(dt)
        check(a.callbacks==b.callbacks and a.changes==b.changes and a.probes==b.probes,"timerless hover phase/overshoot trace retained")
    end
    local la,lb=loot(body(paths[4],true)),loot(body(paths[4]))
    for i=1,1800 do
        if i%210==1 then la.show("item",nil,nil,true);lb.show("item",nil,nil,true)end
        la:step(.002);lb:step(.002);check(la:snapshot()==lb:snapshot(),"loot pooled alpha/expiry trace retained")
    end
    local ea,eb=lfg(body(paths[5],true),false),lfg(body(paths[5]),false)
    ea.active,eb.active=true,true;ea.update();eb.update()
    for i=1,1000 do
        if i==133 then ea.btn:hide();eb.btn:hide()end
        if i==177 then ea.btn:show();eb.btn:show()end
        ea:step(.025);eb:step(.025);check(ea.btn.currentFrame==eb.btn.currentFrame,"timerless eye hidden/phase trace retained")
    end
    local ma,mb=lfg(body(paths[5],true),true),lfg(body(paths[5]),true)
    ma.active,mb.active=true,true;ma.update();mb.update()
    for i=1,1000 do
        if i==133 then ma.btn:hide();mb.btn:hide()end
        if i==177 then ma.btn:show();mb.btn:show()end
        ma:step(.025);mb:step(.025);check(ma.btn.currentFrame==mb.btn.currentFrame,"managed eye keeps visible animation frames and hidden carry")
    end
    for i,test in ipairs(tests)do
        check(not pcall(test,body(paths[i],true),false),"exact original fails optimized work budget "..paths[i])
    end
    check(not pcall(testNativeMeter,baselineRoot.."/"..paths[8],false),"exact native threat original fails optimized sample/style budget")
end
local controls={
    function()testHover(replace(body(paths[1]),"local PEEK_POLL = 0.05","local PEEK_POLL = 0.5"),false)end,
    function()testTrinket(replace(body(paths[2]),"        keyPushWatch:Show()","        -- press wake omitted"),false)end,
    function()testStance(replace(body(paths[3]),"owner._fluxAuraTimeBucket == bucket","true"),false)end,
    function()testLoot(replace(body(paths[4]),"row._fluxLootAlpha ~= alpha","row._fluxLootAlpha == nil"),false)end,
    function()testLfg(replace(body(paths[5]),'btn:HookScript("OnHide", StopEyeTimer)','btn:HookScript("OnHide", function() end)'),false)end,
    function()testQuestie(replace(body(paths[7]),"frame:GetWidth() ~= width","frame:GetWidth() == nil"),false)end,
    function()testNativeMeter(paths[8],false,replace(body(paths[8]),"local row = samplePool[index]","local row = nil"))end,
    function()testTimerErrors(replace(body(paths[1])," and timer.HasNativeTicker ~= false",""),body(paths[5]))end,
    function()testTimerErrors(body(paths[1]),replace(body(paths[5]),"timer.HasNativeAfter ~= false and ",""))end,
    function()testTimerErrors(body(paths[1]),replace(body(paths[5]),"                StartEyeTimer()\n                AdvanceEyeFrame()","                AdvanceEyeFrame()\n                StartEyeTimer()"))end,
}
for i,control in ipairs(controls)do check(not pcall(control),"harmful behavioral/work control rejected "..i)end
for _,row in ipairs(results)do print(row)end
print("passive world optimization: "..checks.." checks; "..(baselineRoot and "three fresh pairs" or "three candidate runs").."; "..#controls.." harmful controls rejected; native FPS/taint/pixels NOT RUN")
