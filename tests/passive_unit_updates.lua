-- Production modules under bounded desktop adapters. These work counts do not
-- measure native FPS or certify native protected geometry, pixels, or taint.
local function read(path)
    local f=assert(io.open(path,"rb"),path);local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local checks=0
local baseline=os.getenv("FLUX_PASS2_BASELINE")=="1"
local metrics,traces={},{}
local function check(value,label)checks=checks+1;assert(value,label)end
local function emit(kind,key,value)print(kind.."\t"..key.."\t"..tostring(value))end

local function ClassFixture(fallback)
    local s={now=0,combat=false,show=true,timers={},frames={},queued=0,fired=0,requests=0,layouts=0,hides=0,refreshes=0,points={}}
    local M={}
    local function geometry()assert(not s.combat,"class layout must not paint in combat")end
    function M:GetFrameLevel()return 1 end
    function M:GetParent()return self.parent end
    function M:GetChildren()end
    function M:SetParent(v)geometry();self.parent=v end
    function M:SetFrameStrata()geometry()end
    function M:SetFrameLevel()geometry()end
    function M:SetScale()geometry()end
    function M:ClearAllPoints()geometry()end
    function M:SetPoint(_,anchor)geometry();self.anchor=anchor;s.points[#s.points+1]=anchor.tag or "root" end
    function M:Show()geometry();self.shown=true end
    function M:Hide()geometry();self.shown=false;s.hides=s.hides+1 end
    function M:RegisterEvent(event)self.events[event]=true end
    function M:SetScript(k,v)self[k]=v end
    local function frame(t)t=t or {};t.events={};s.frames[#s.frames+1]=t;return setmetatable(t,{__index=M})end
    s.parent,s.container=frame{unit="player",tag="A"},frame{}
    s.container.Layout=function()geometry();s.layouts=s.layouts+1 end
    local e=setmetatable({},{__index=_G});e._G=e;s.e=e
    e.UIParent=frame{}
    e.PlayerBottomManagedFrameContainer=s.container
    e.InCombatLockdown=function()return s.combat end
    e.UnitClass=function()return "Warrior","WARRIOR" end
    e.FluxUnitFrames_ShouldShowClassPower=function()return s.show end
    e.CreateFrame=function()return frame{}end
    e.C_Timer={After=function(delay,callback)s.queued=s.queued+1;s.timers[#s.timers+1]={at=s.now+delay,fn=callback,id=s.queued}end}
    local ns={UnitFrames={},API={},PlayerFrame=s.parent,Flux={Safecall=function(fn)return fn()end},
        CooldownDefaults={Request=function()s.requests=s.requests+1 end},
        ForeverComboPoints={Initialize=function()end,RefreshAll=function()s.refreshes=s.refreshes+1 end}}
    s.ns=ns
    -- Use the real named combat queue and its real regen event. Only engine
    -- frame/timer primitives are adapted, not the production scheduling logic.
    assert(loadfile("Core/Engine/Combat.lua","t",e))("_FluxUI",ns)
    local lifecycle=read("UnitFrames/FluxUnitFrames_Lifecycle.lua")
    local defer=assert(lifecycle:match("function UF.DeferProtected%(key, callback%).-\nend"))
    if not fallback then assert(load("local UF,Flux=...\n"..defer,"@real-unit-defer","t",e))(ns.UnitFrames,ns.Flux)end
    assert(loadfile(os.getenv("FLUX_CLASSPOWER_SOURCE")or"UnitFrames/FluxClassPower.lua","t",e))("_FluxUI",ns)
    function s.Advance(to)
        while true do
            local index,at,id
            for i,t in ipairs(s.timers)do
                if t.at<=to+1e-8 and(not at or t.at<at or(t.at==at and t.id<id))then index,at,id=i,t.at,t.id end
            end
            if not index then break end
            local timer=table.remove(s.timers,index);s.now=timer.at;s.fired=s.fired+1;timer.fn()
        end
        s.now=to
    end
    function s.Regen()
        s.combat=false
        for _,f in ipairs(s.frames)do if f.events.PLAYER_REGEN_ENABLED and f.OnEvent then f.OnEvent(f,"PLAYER_REGEN_ENABLED")end end
    end
    function s.ResetCounts()s.queued,s.fired,s.requests,s.layouts,s.hides,s.refreshes=0,0,0,0,0,0;s.points={}end
    function s.Event(event,...)local f=ns.ClassPower._eventFrame;f.OnEvent(f,event,...)end
    function s.NewParent(tag)return frame{unit="player",tag=tag}end
    ns.ClassPower.Initialize(s.parent);s.Advance(2);s.ResetCounts()
    return s
end

for _,fallback in ipairs{false,true}do
    local s=ClassFixture(fallback)
    s.Event("UNIT_POWER_UPDATE","target","MANA")
    check(s.layouts==0 and s.queued==0,"other-unit power events do no class layout")
    s.Event("UNIT_POWER_UPDATE","player","MANA")
    check(s.layouts==2 and s.container.anchor==s.parent,"direct player updates retain both native layout passes")
    s.container.anchor=nil;s.Event("UNIT_POWER_UPDATE","player","MANA")
    check(s.container.anchor==s.parent,"the next original event still repairs a native anchor reset")
    s.ResetCounts();s.Event("PLAYER_SPECIALIZATION_CHANGED","player")
    check(s.layouts==2 and #s.timers==3,"specialization keeps immediate and three delayed recoveries")
    s.Advance(2.11);check(s.layouts==4,"100ms class recovery retained")
    s.Advance(2.51);check(s.layouts==6,"500ms class recovery retained")
    s.Advance(3.01);check(s.layouts==8,"one-second class recovery retained")
    traces["class_ooc_"..tostring(fallback)]=table.concat(s.points,",")
end

for _,rate in ipairs{1,10}do
    local s=ClassFixture(false);s.combat=true
    for i=1,rate*60 do s.Advance(2+i/rate);s.Event("UNIT_POWER_UPDATE","player","MANA")end
    check(s.layouts==0,"combat power bursts never repaint protected class geometry")
    metrics["class_"..rate.."hz_timers"]=s.queued
    metrics["class_"..rate.."hz_callbacks"]=s.fired
    metrics["class_"..rate.."hz_requests"]=s.requests
    metrics["class_"..rate.."hz_outstanding"]=#s.timers
    if not baseline then check(s.queued==0 and s.fired==0 and s.ns.Flux.Combat.PendingCount()==1,"combat bursts own one regen request and no timer chains")end
    s.Regen()
    if not baseline then check(s.layouts==2,"shared regen restores class position immediately once")end
    s.Advance(62.50001)
    metrics["class_"..rate.."hz_recovery_layouts"]=s.layouts
    check(s.container.anchor==s.parent and s.container.shown,"class position restored after combat")
    if not baseline then check(s.layouts==2,"combat burst leaves no redundant recovery train")end
end

do
    local s=ClassFixture(false);s.combat=true
    s.ns.ClassPower.UpdatePosition(s.parent)
    local newest=s.NewParent("B");s.ns.PlayerFrame=newest;s.ns.ClassPower.Frame=newest
    s.ns.ClassPower.UpdatePosition(newest);s.Regen();s.Advance(2.50001)
    check(s.container.anchor==newest,"latest combat parent wins after a frame rebind")
    if not baseline then for _,tag in ipairs(s.points)do check(tag=="B","stale parent never repaints on regen")end end
    s.ResetCounts();s.combat=true;s.ns.ClassPower.UpdatePosition(newest);s.show=false
    for i=1,100 do s.ns.ClassPower.ApplyVisibility()end
    check(s.hides==0 and s.refreshes==100,"visibility requests retain immediate combo refresh without illegal combat hides")
    s.Regen();s.Advance(3.00002)
    check(not s.container.shown,"latest disabled option cannot resurrect deferred class bars")
    if not baseline then check(s.layouts==0 and s.queued==0,"disabled combat requests leave no timer train or stale show")end
    s.show=true;s.ns.ClassPower.ApplyVisibility();check(s.container.shown,"reenabling class power restores it immediately")
end

do
    local s=ClassFixture(true);s.combat=true
    for i=1,100 do s.ns.ClassPower.UpdatePosition(s.parent)end
    if not baseline then check(#s.timers==1,"missing shared service retains one bounded timer fallback")end
    s.Advance(3.01);check(s.layouts==0,"fallback never paints during combat")
    if not baseline then check(#s.timers==1,"fallback retry remains single through long combat")end
    s.Regen();s.Advance(3.51);check(s.container.shown and s.container.anchor==s.parent,"fallback restores within original half-second bound")
    if not baseline then check(#s.timers==0 and s.layouts==2,"fallback quiesces after one recovery")end
end
do
    local s=ClassFixture(true);s.combat=true;s.show=false
    for i=1,100 do s.ns.ClassPower.ApplyVisibility()end
    if not baseline then check(#s.timers==1,"disabled visibility also owns one fallback retry")end
    s.Advance(2.51);check(s.hides==0,"fallback visibility never hides protected bars in combat")
    s.show=true;local newest=s.NewParent("C");s.ns.PlayerFrame=newest;s.ns.ClassPower.Frame=newest
    s.Regen();s.Advance(3.01)
    check(s.container.shown and s.container.anchor==newest,"visibility fallback uses latest option and parent rather than a stale hide")
end

local fixtureText=read("tests/castbar_school_themes.lua")
local prefix=fixtureText:sub(1,assert(fixtureText:find("local function checkParticleGeometry",1,true))-1)
prefix=prefix:gsub("local function loadAddon%(path, env, ns%)",function(s)return s.."\n    if path=='UnitFrames/FluxCastBar.lua' then path=os.getenv('FLUX_PASS2_CAST_SOURCE') or path end"end,1)
local castFixture=assert(load(prefix.."\nreturn fixture","@cast-pass2-fixture","t",_G))()
local function CastFixture()
    local s,e,ns=castFixture("forever");ns.API.isV12=true
    local m={reads=0,remaining=0,texts=0,left=7,fail=false};local methods=getmetatable(e.UIParent).__index
    methods.SetTimerDuration=function(self,duration)self.duration=duration;self.low=0;self.high=10;self.value=3 end
    methods.GetTimerDuration=function(self)m.reads=m.reads+1;return self.duration end
    local duration={GetRemainingDuration=function()m.remaining=m.remaining+1;if m.fail then m.fail=false;error("transient clock failure")end;return m.left end,
        GetElapsedPercent=function()return .3 end}
    e.UnitCastingDuration=function()return duration end
    e.UnitCastingInfo=function()return "Spell","Spell",133,s.secret,s.secret,false,"cast-engine",false,133 end
    local bar=s.NewBar("player");s.casts.player={name="Spell",id=133}
    local original=bar.Time.SetFormattedText
    bar.Time.SetFormattedText=function(self,fmt,v)m.texts=m.texts+1;if rawequal(v,s.secret)then self.text=v else original(self,fmt,v)end end
    bar:CastStart("player",false,"cast-engine");m.reads,m.remaining,m.texts=0,0,0
    return s,e,ns,bar,m
end
for _,fps in ipairs{60,144,240}do
    local s,e,ns,bar,m=CastFixture()
    for i=1,fps*60 do s.Tick(1/fps)end
    metrics["cast_"..fps.."fps_duration_reads"]=m.reads
    metrics["cast_"..fps.."fps_remaining_reads"]=m.remaining
    metrics["cast_"..fps.."fps_text_paints"]=m.texts
    check(bar.Time.text=="7.0","engine time text follows the unchanged bound clock")
    if not baseline then check(m.reads==fps*60 and m.remaining==fps*60,"successful synchronous cast sample is read only once per frame")end
end
do
    local s,e,ns,bar,m=CastFixture();local trace={}
    for _,left in ipairs{7,6.5,1.1,0.01}do m.left=left;s.Tick(.05);trace[#trace+1]=bar.Time.text end
    m.left=s.secret;s.Tick(.05);check(rawequal(bar.Time.text,s.secret),"opaque remaining value reaches native text unchanged")
    trace[#trace+1]="secret"
    m.left=4.25;m.fail=true;s.Tick(.05)
    check(bar.Time.text=="4.2","transient first clock failure still retries for the same text paint")
    trace[#trace+1]=bar.Time.text
    m.left=3.75;bar:CastStart("player",false,"replacement");check(bar.Time.text=="3.8","direct replacement start reads fresh clock")
    m.left=3.25;s.Tick(.05);check(bar.Time.text=="3.2","next frame never reuses a prior cast sample")
    s.Event(bar,"UNIT_SPELLCAST_STOP","player","cast-engine",133)
    check(bar.casting and bar.castGUID=="replacement","late old-cast terminal event cannot consume a new sample or cast")
    trace[#trace+1]=bar.Time.text
    e.FluxUnitFrames_ShouldShowCastTime=function()return false end;s.Tick(.05);check(not bar.Time.shown,"hidden time option retains original update gate")
    e.FluxUnitFrames_ShouldShowCastTime=function()return true end;m.left=2.25;s.Tick(.05);check(bar.Time.text=="2.2" and bar.Time.shown,"reenabled time reads current engine clock")
    trace[#trace+1]=bar.Time.text
    traces.cast=table.concat(trace,",")
    bar.TimerBar.duration={GetRemainingDuration=function()return 1.75 end,GetElapsedPercent=function()return .825 end}
    s.Tick(.05);check(bar.Time.text=="1.8","replacement duration object is read on the very next frame")
end

do
    local trace={}
    for _,stage in ipairs{"getter","remaining","predicate","same-guid","minmax","manual-delay","failed-bind","secret-guid","rebind"}do
        local s,e,ns,bar,m=CastFixture()
        local old=bar.TimerBar.duration
        local nextClock={GetRemainingDuration=function()return 3.25 end,GetElapsedPercent=function()return .675 end}
        local once=true
        local function replace()
            once=false
            if stage=="manual-delay"then
                e.UnitCastingInfo=function()return "Spell","Spell",133,0,5000,false,"cast-engine",false,133 end
                s.Event(bar,"UNIT_SPELLCAST_DELAYED","player","cast-engine",133)
            elseif stage=="same-guid"then
                bar:SetTimerDuration(nextClock)
            elseif stage=="minmax"then
                local methods=getmetatable(e.UIParent).__index;local setter=methods.SetMinMaxValues
                methods.SetMinMaxValues=function(self,low,high)self.duration=nil;self.low,self.high,self.value=low,high,4 end
                bar:SetMinMaxValues(0,10)
                methods.SetMinMaxValues=setter
            elseif stage=="failed-bind"then
                local methods=getmetatable(e.UIParent).__index;local setter=methods.SetTimerDuration
                methods.SetTimerDuration=function(self,duration)self.duration=duration;error("partial native bind failure")end
                check(not pcall(bar.SetTimerDuration,bar,nextClock),"failed native timer bind remains observable")
                methods.SetTimerDuration=setter
            else
                e.UnitCastingDuration=function()return nextClock end
                bar:CastStart(stage=="rebind"and"focus"or"player",false,stage=="secret-guid"and s.secret or"replacement")
            end
        end
        if stage=="getter"then
            bar.GetTimerDuration=function(self)
                if once then replace();return old end
                return self.TimerBar.duration
            end
        elseif stage=="predicate"then
            local calls=0
            e.FluxUnitFrames_ShouldShowCastTime=function()
                calls=calls+1
                if calls==2 and once then replace()end
                return true
            end
        else
            old.GetRemainingDuration=function()if once then replace()end;return 7 end
        end
        s.Tick(.05)
        local expected=stage=="manual-delay"and"4.0"or(stage=="minmax"and"6.0"or"3.2")
        check(bar.Time.text==expected,"same-pass "..stage.." replacement cannot reuse an old clock sample")
        if stage=="same-guid"or stage=="minmax"or stage=="manual-delay"or stage=="failed-bind"then
            check(bar.castGUID=="cast-engine","clock replacement need not change cast identity")
        elseif stage=="rebind"then check(bar.unitID=="focus","same-pass rebind owns the new unit clock")end
        trace[#trace+1]=stage..":"..bar.Time.text
        if stage~="manual-delay"then
            local newest={GetRemainingDuration=function()return 2.25 end,GetElapsedPercent=function()return .775 end}
            bar:SetTimerDuration(newest);s.Tick(.05)
            check(bar.Time.text=="2.2","the next production timer bind retries after "..stage)
        end
    end
    traces.cast_reentrant=table.concat(trace,",")
end

local raidText=read("tests/raid_healer_prediction.lua")
local raidPrefix=raidText:sub(1,assert(raidText:find("for _, client in ipairs",1,true))-1)
local raidFixture=assert(load(raidPrefix.."\nreturn Fixture","@raid-pass2-fixture","t",_G))()
for _,native in ipairs{false,true}do
    local e,p,frame,values,opaque=raidFixture(native);assert(p.Setup(frame));local state=frame._fluxPrediction
    local original,index
    for i=1,30 do local name,fn=debug.getupvalue(p.Update,i);if not name then break end
        if name==(native and "NativeValues"or"LegacyValues")then original,index=fn,i;break end end
    assert(original);local rows,unique={},0
    debug.setupvalue(p.Update,index,function(...)
        local a,b,c,d,f,g,h,j,k,l,m,n=original(...)
        if type(k)=="table"then if not rows[k]then rows[k]=true;unique=unique+1 end end
        return a,b,c,d,f,g,h,j,k,l,m,n
    end)
    for i=1,48000 do p.Update(frame)end
    metrics["raid_"..tostring(native).."_severity_arrays"]=unique
    if not baseline then check(unique==0,"prediction values allocate no transient severity rows")end
    local trace={}
    for _,incoming in ipairs{0,50,80,100,150}do
        values.mine,values.total,values.others=incoming,incoming,0
        values.nativeOverheal={incoming>40,incoming>50,incoming>65,incoming>90}
        p.Update(frame)
        local entry={state.mine.value,state.others.value,state.absorb.value,state.healAbsorb.value}
        for i=1,4 do entry[#entry+1]=tostring(state.overhealLevels[i].boolean)end
        for i=1,4 do entry[i]=tostring(entry[i])end
        trace[#trace+1]=table.concat(entry,",")
    end
    traces["raid_"..tostring(native)]=table.concat(trace,";")
    -- Native sinks may run hooks. A nested update must not overwrite the outer
    -- paint's remaining severity values, which rules out one shared scratch row.
    local region=state.overhealLevels[1];local sink=region.SetAlphaFromBoolean;local nested=false
    local outer={true,false,true,false};local inner={false,true,false,true}
    if native then
        values.overheal=false
        values.nativeOverheal=outer
        region.SetAlphaFromBoolean=function(self,value,...)
            sink(self,value,...)
            if not nested then nested=true;values.nativeOverheal=inner;p.Update(frame)end
        end
        p.Update(frame)
        for i=2,4 do check(state.overhealLevels[i].boolean==outer[i],"reentrant prediction preserves outer severity snapshot")end
        region.SetAlphaFromBoolean=sink
        values.nativeOverheal={opaque("one"),opaque("two"),opaque("three"),opaque("four")}
        p.Update(frame)
        for i=1,4 do check(rawequal(state.overhealLevels[i].boolean,values.nativeOverheal[i]),"opaque severity forwards independently without Lua tests")end
        -- A temporarily missing calculator keeps remaining boundaries false.
        state.overhealCalculators={state.overhealCalculators[1]};values.nativeOverheal={true,true,true,true};p.Update(frame)
        check(state.overhealLevels[2].boolean==true and state.overhealLevels[3].boolean==false and state.overhealLevels[4].boolean==false,"missing calculators cannot retain stale severity")
        local query=e.UnitGetDetailedHealPrediction;local queries=0
        frame.unit="party2"
        e.UnitGetDetailedHealPrediction=function(unit,...)queries=queries+1;check(unit=="party2","rebound unit queried immediately");return query(unit,...)end
        p.Update(frame);check(queries==2,"rebinding retains one main plus every available overflow query")
        e.UnitGetDetailedHealPrediction=function()error("transient prediction failure")end
        p.Update(frame);check(not state.mine.shown,"failed native sample hides stale prediction")
        e.UnitGetDetailedHealPrediction=query;p.Update(frame);check(state.mine.shown,"next update retries failed native prediction")
        local alpha=region.SetAlphaFromBoolean;local failed=false
        region.SetAlphaFromBoolean=function(self,...)if not failed then failed=true;error("transient native sink failure")end;return alpha(self,...)end
        check(not pcall(p.Update,frame),"native sink failure remains observable")
        p.Update(frame);check(state.mine.shown,"native sink is retried by the next original update")
        region.SetAlphaFromBoolean=alpha
    end
    frame.unitExists=false;p.Update(frame);check(not state.mine.shown and not state.overheal.shown,"unbound prediction hides all owned feedback")
    frame.unitExists=true;frame.optionTable.displayHealPrediction=false;p.Update(frame);check(not state.mine.shown,"disabled prediction remains hidden")
end
local keys={};for key in pairs(metrics)do keys[#keys+1]=key end;table.sort(keys);for _,key in ipairs(keys)do emit("METRIC",key,metrics[key])end
keys={};for key in pairs(traces)do keys[#keys+1]=key end;table.sort(keys);for _,key in ipairs(keys)do emit("TRACE",key,traces[key])end
print("Passive unit updates: "..checks.." checks PASS; native FPS/taint/pixels pending")
