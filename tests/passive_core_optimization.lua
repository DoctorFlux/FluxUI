-- Actual core/aura production functions; counted widgets, not native FPS/taint.
local sourceRoot = arg[1] or "."
local measure = arg[2] == "--measure"
local checks = 0
local function check(v, why) checks=checks+1; assert(v,why) end
local function read(path)
    local f=io.open(sourceRoot.."/"..path,"rb") or assert(io.open(path,"rb"))
    local s=f:read("*a");f:close();return (s:gsub("\r\n","\n"))
end
local function loadSource(path,e,ns)
    return assert(load(read(path),"@"..path,"t",e))("_FluxUI",ns)
end
local function env() local e=setmetatable({},{__index=_G});e._G=e;return e end
local function hash(h,v)
    local s=tostring(v);for i=1,#s do h=(h*33+s:byte(i))%1000000007 end;return h
end
local function metric(name,values)
    local keys={};for k in pairs(values)do keys[#keys+1]=k end;table.sort(keys)
    local out={"METRIC",name};for _,k in ipairs(keys)do out[#out+1]=k.."="..tostring(values[k])end
    print(table.concat(out,"|"))
end

-- The scheduler delivers the same frame-quantized nominal intervals as the
-- old wait loops; newly created timers start counting on the following frame.
local function clockFixture()
    local s={time=0,step=0,frames={},timers={},updates=0,timerCalls=0}
    function s.newTicker(interval,fn)
        local t={remaining=interval,interval=interval,fn=fn,created=s.step}
        function t:Cancel()self.cancelled=true end
        s.timers[#s.timers+1]=t;return t
    end
    function s.advance(dt)
        s.step=s.step+1;s.time=s.time+dt
        for _,f in ipairs(s.frames)do
            if f.shown~=false and f.scripts.OnUpdate then
                s.updates=s.updates+1;f.scripts.OnUpdate(f,dt)
            end
        end
        local n=#s.timers
        for i=1,n do local t=s.timers[i]
            if not t.cancelled and t.created<s.step then
                t.remaining=t.remaining-dt
                if t.remaining<=0 then
                    t.remaining=t.interval;s.timerCalls=s.timerCalls+1;t.fn()
                end
            end
        end
    end
    function s.frame(_,name,parent)
        local f={name=name,parent=parent,shown=true,scripts={},attributes={}}
        function f:GetName()return self.name end
        function f:SetScript(k,v)self.scripts[k]=v end
        function f:RegisterEvent()end
        function f:RegisterUnitEvent()end
        function f:Hide()self.shown=false end
        function f:Show()self.shown=true end
        function f:IsShown()return self.shown end
        function f:GetAttribute(k)return self.attributes[k]end
        function f:SetAttribute(k,v)self.attributes[k]=v end
        s.frames[#s.frames+1]=f;return f
    end
    return s
end

for _,fps in ipairs({60,144,240})do
    local e,s=env(),clockFixture();local shown,parentShown,nativeStack=false,true,false
    local polls,shows,hides,refreshes,trace=0,0,0,0,0
    e.CreateFrame=s.frame;e.issecretvalue=function()return false end
    local book={IsVisible=function()return shown and parentShown end,
        PagedSpellsFrame={dataProvider={},viewDataList={},PagingControls={currentPage=1}}}
    e.PlayerSpellsFrame={SpellBookFrame=book}
    local flux={Timer={NewTicker=s.newTicker}}
    loadSource("Core/Engine/SpellBookChrome.lua",e,{Flux=flux})
    flux.SpellBookChrome.Observe("owner",function()
        check(not nativeStack,"spellbook observer must stay outside native open stack")
        shows=shows+1;trace=hash(trace,"show"..s.step)
    end,function()hides=hides+1;trace=hash(trace,"hide"..s.step)end,
    function()refreshes=refreshes+1;trace=hash(trace,"page"..s.step)end,
    function()polls=polls+1 end)
    flux.SpellBookChrome.Observe("second",nil,nil,nil)
    for i=1,fps*10 do
        nativeStack=true
        if i==fps then shown=true end
        if i==fps*2 then book.PagedSpellsFrame.PagingControls.currentPage=2 end
        if i==fps*3 then book.PagedSpellsFrame.dataProvider={}end
        if i==fps*4 then parentShown=false end
        if i==fps*5 then parentShown=true end
        if i==fps*6 then shown=false end
        if i==fps*7 then shown=true end
        nativeStack=false;s.advance(1/fps)
    end
    check(shows==3 and hides==2 and refreshes==2,"same spellbook visibility/page lifecycle")
    check(polls>=80 and polls<=100,"unchanged nominal 0.1s observation speed")
    if not measure then check(s.updates==0 and #s.timers==1,"one shared timer; no per-frame deadline callbacks")end
    metric("spellbook"..fps,{onUpdates=s.updates,polls=polls,shows=shows,hides=hides,refreshes=refreshes,trace=trace})
end

-- Real Timer.lua capability/fallback selection, including one throwing
-- observer. The old frame script must keep recovering on later frames.
for _,timerMode in ipairs({"none","after-only","native-ticker"})do
    local e,s=env(),clockFixture();local polls,errors=0,0
    e.CreateFrame=s.frame
    if timerMode=="after-only"then e.C_Timer={After=function()error("unexpected one-shot")end}
    elseif timerMode=="native-ticker"then e.C_Timer={NewTicker=s.newTicker}end
    local flux={};loadSource("Core/Engine/Timer.lua",e,{Flux=flux})
    loadSource("Core/Engine/SpellBookChrome.lua",e,{Flux=flux})
    flux.SpellBookChrome.Observe("throw-once",nil,nil,nil,function()
        polls=polls+1;if polls==1 then error("transient observer failure")end
    end)
    for _=1,2400 do local ok=pcall(s.advance,1/240);if not ok then errors=errors+1 end end
    check(errors==1 and polls>=90,"real "..timerMode.." timer capability retains observer error recovery")
    if not measure then check(flux.Timer.HasNativeTicker==(timerMode=="native-ticker"),"captured ticker capability")end
    metric("timerRecovery-"..timerMode,{polls=polls,errors=errors})
end

do
    local e,s=env(),clockFixture();local parses,errors=0,0
    e.CreateFrame=s.frame;e.UnitExists=function()return true end
    e.geterrorhandler=function()return function()errors=errors+1 end end
    e.SecureCmdOptionParse=function()
        parses=parses+1;if parses==5 then error("transient state-driver parser failure")end
        return "show"
    end
    local flux={Cap={hasRestrictedClosures=false}}
    loadSource("Core/Engine/Timer.lua",e,{Flux=flux})
    loadSource("Core/Engine/Restricted.lua",e,{Flux=flux})
    local f=s.frame("Frame","FluxRealTimerRecovery")
    flux.Restricted.RegisterStateDriver(f,"visibility","show")
    for _=1,2400 do local ok=pcall(s.advance,1/240);if not ok then errors=errors+1 end end
    check(errors==1 and parses>=45 and f.shown,"real timerless state driver recovers after one callback error")
    metric("restrictedTimerRecovery",{parses=parses,errors=errors})
end

do
    local e,s=env(),clockFixture();local combat=false;local state="show";local parses=0
    e.CreateFrame=s.frame;e.InCombatLockdown=function()return combat end
    e.UnitExists=function()return true end
    e.SecureCmdOptionParse=function()parses=parses+1;return state end
    local flux={Cap={hasRestrictedClosures=false},Timer={NewTicker=s.newTicker}}
    loadSource("Core/Engine/Restricted.lua",e,{Flux=flux})
    local f=s.frame("Frame","FluxPassiveCore");f.attributes.unit="target"
    flux.Restricted.RegisterStateDriver(f,"visibility","[exists] show; hide")
    local watcher=s.frames[2];local trace=0
    local function event()watcher.scripts.OnEvent(watcher,"PLAYER_TARGET_CHANGED")end
    for i=1,2400 do
        if i==240 then state="hide";event();check(not f.shown,"event applies immediately")end
        -- A value changes after the event: preserve the old next-frame catch-up.
        if i==480 then state="show";event();state="hide" end
        if i==720 then state="show" end
        if i==960 then combat=true;state="hide";event()end
        if i==1200 then combat=false;event();check(not f.shown,"regen reconciliation remains immediate")end
        if i==1440 then state="show";event()end
        s.advance(1/240)
        if i==480 then check(not f.shown,"next-frame fallback reconciles a value changed after event dispatch")end
        trace=hash(trace,tostring(f.shown))
    end
    if not measure then check(s.updates<20,"fallback only uses OnUpdate for next-frame reconciliation")end
    check(f.shown,"final fallback state")
    flux.Restricted.UnregisterStateDriver(f,"visibility")
    check(not watcher.shown,"empty fallback hides")
    local before=parses;for _=1,100 do s.advance(1/240)end
    check(parses==before,"empty fallback cancels timers and callbacks")
    metric("restricted",{onUpdates=s.updates,parses=parses,trace=trace})
end

do
    local e,s=env(),clockFixture();local reenter=false;local flux,f
    e.CreateFrame=s.frame;e.UnitExists=function()return true end
    e.SecureCmdOptionParse=function()
        if reenter then reenter=false;flux.Restricted.UnregisterStateDriver(f,"visibility")end
        return "show"
    end
    flux={Cap={hasRestrictedClosures=false},Timer={NewTicker=s.newTicker}}
    loadSource("Core/Engine/Restricted.lua",e,{Flux=flux})
    f=s.frame("Frame","FluxReentrant");flux.Restricted.RegisterStateDriver(f,"visibility","show")
    reenter=true;s.advance(1/240)
    check(not s.frames[2].shown,"reentrant removal preserves idle ownership")
    for _,timer in ipairs(s.timers)do check(timer.cancelled,"old fallback pass cannot resurrect an idle ticker")end
end

-- Production native/Classic overlays. Only writable owned geometry is cached;
-- native frame parent/level/parent-level resets must recover on the same frame.
do
    local e=env();local frames={};local tick=0;local now=100;local counts={queries=0,parent=0,level=0,using=0,anchors=0,color=0}
    local methods={}
    local function object(parent)
        return setmetatable({parent=parent,shown=true,level=1,width=44,height=44,points={},alpha=1},{__index=methods})
    end
    function methods:SetScript(k,fn)self.scripts=self.scripts or {};self.scripts[k]=fn end
    function methods:GetParent()return self.parent end
    function methods:SetParent(p)counts.parent=counts.parent+1;self.parent=p end
    function methods:GetFrameLevel()if self.badLevel then return self.badLevel end;return self.level end
    function methods:SetFrameLevel(v)counts.level=counts.level+1;self.level=v end
    function methods:IsUsingParentLevel()return self.using==true end
    function methods:SetUsingParentLevel(v)counts.using=counts.using+1;self.using=v end
    function methods:Show()self.shown=true end
    function methods:Hide()self.shown=false end
    function methods:IsShown()return self.shown end
    function methods:GetWidth()return self.width end
    function methods:GetHeight()return self.height end
    function methods:SetWidth(v)self.width=v end
    function methods:SetHeight(v)self.height=v end
    function methods:SetSize(w,h)self.width,self.height=w,h end
    function methods:ClearAllPoints()counts.anchors=counts.anchors+1;self.points={}end
    function methods:SetPoint(...)self.points[#self.points+1]={...}end
    function methods:SetAllPoints(v)self.points={{"ALL",v}}end
    function methods:SetColorTexture(...)counts.color=counts.color+1;self.color={...}end
    function methods:SetAlpha(v)self.alpha=v end
    function methods:GetAlpha()return self.alpha end
    function methods:SetDrawLayer(a,b)
        if self.failDraw then self.failDraw=nil;error("injected draw-layer denial")end
        self.draw,self.sub=a,b
    end
    function methods:SetBlendMode(v)self.blend=v end
    function methods:AddMaskTexture()end
    function methods:EnableMouse()end
    function methods:SetTexture(v)self.texture=v end
    function methods:SetAtlas(v)self.atlas=v end
    function methods:CreateTexture()return object(self)end
    e.CreateFrame=function(_,_,parent)local f=object(parent);frames[#frames+1]=f;return f end
    e.GetTime=function()return now end
    e.issecretvalue=function(v)return type(v)=="table"and v.opaque end
    e.canaccessvalue=function(v)return not e.issecretvalue(v)end
    local function endTime(unit)return 120000+(unit=="pet"and 1000 or 0)+(tick>=200 and 2000 or 0)end
    e.UnitCastingInfo=function(unit)counts.queries=counts.queries+1;return "Cast",nil,nil,100000,endTime(unit)end
    e.UnitChannelInfo=function(unit)counts.queries=counts.queries+1;return "Channel",nil,nil,100000,endTime(unit)end
    local flux={Client={isAnyClassic=false},ButtonFX={Cast={NoteChannelTimes=function()end}}}
    loadSource("Core/ButtonFX/Overlay.lua",e,{Flux=flux})
    local overlay=flux.ButtonFX.Overlay;local widgets={}
    for i=1,10 do
        local w=object();w.level=10;w.cooldown=object(w);w.cooldown.level=12
        w._fluxVfxMode="native";w.actionButtonCastType=i<=4 and 1 or 2;w._fluxVfxUnit=i>8 and "pet"or"player"
        local cf=object(w);cf.Fill=object(cf);cf.Fill.CastFill=object(cf.Fill);cf.Fill.InnerGlowTexture=object(cf.Fill)
        w.SpellCastAnimFrame=cf;widgets[i]=w;overlay.WatchNativeFill(w)
    end
    local watcher=frames[1];local trace=0
    for i=1,720 do
        tick=i;now=100+i/240
        if i==120 then for _,w in ipairs(widgets)do w.SpellCastAnimFrame.parent=nil;w.SpellCastAnimFrame.level=0;w.SpellCastAnimFrame.using=true end end
        if i==240 then for _,w in ipairs(widgets)do w.width=58;w.cooldown.level=20 end end
        if i==180 then
            local under=widgets[5].SpellCastAnimFrame._fluxChannelUnder
            under._fluxUnderOwner=nil;under.failDraw=true;under.draw="WRONG"
        end
        if i==360 then for _,w in ipairs(widgets)do w.cooldown:Hide()end end
        if i==480 then
            for _,w in ipairs(widgets)do w.SpellCastAnimFrame.badLevel={opaque=true};w.SpellCastAnimFrame.level=0 end
        end
        if i==481 then for _,w in ipairs(widgets)do w.SpellCastAnimFrame.badLevel=nil end end
        watcher.scripts.OnUpdate(watcher)
        for _,w in ipairs(widgets)do
            local cf=w.SpellCastAnimFrame
            check(cf.parent==w and not cf.using,"native parent/using reset repaired on same frame")
            check(cf.level==(w.cooldown.shown and w.cooldown.level or w.level)+1,"native frame level remains current")
            local under=cf._fluxChannelUnder
            if under then
                check(under.points[1][2]==w and under.points[2][2]==w,"underlay remains attached to owning widget")
                local progress=1-(now-100)/((endTime(w._fluxVfxUnit)-100000)/1000)
                check(math.abs(under.width-math.max(1,w.width*progress))<1e-8,"native channel sample is fresh on this frame")
                check(under.color[1]==0.22 and under.color[2]==0.95 and under.color[3]==0.42 and under.alpha==0.38,
                    "native channel owned color/opacity unchanged")
                if not (i==180 and w==widgets[5])then check(under.draw=="ARTWORK"and under.sub==0,"failed style sink retries next frame")end
                trace=hash(trace,string.format("%.9f",under.width));trace=hash(trace,under.alpha)
            end
            trace=hash(trace,string.format("%.9f",cf.Fill.CastFill.points[1][2]));trace=hash(trace,cf.level)
        end
    end
    -- A direct call in the same GetTime frame must see new API data, not a
    -- sample retained by the preceding shared watcher pass.
    local directBefore=counts.queries;overlay._tickNativeFill(widgets[1])
    check(counts.queries==directBefore+1,"direct native refresh reads fresh timing")
    if not measure then
        check(counts.queries<3000,"one cast/channel sample per unit and synchronous watcher pass")
        check(counts.parent<40 and counts.level<100 and counts.using<40,"settled native parent/level setters eliminated")
        check(counts.color<20,"owned channel color and anchors reused")
    end
    metric("overlay",{queries=counts.queries,parent=counts.parent,level=counts.level,using=counts.using,anchors=counts.anchors,color=counts.color,trace=trace})
    local classic=object();classic.level=5;classic.cooldown=object(classic);classic.cooldown.level=8
    overlay.PlayClassicFill(classic,overlay.CHANNEL)
    local beforeAnchors,beforeColor=counts.anchors,counts.color;trace=0
    for i=1,720 do now=104+i/240;overlay._classicOnUpdate(classic);trace=hash(trace,string.format("%.9f",classic._fluxCastFill.width))end
    if not measure then check(counts.anchors==beforeAnchors and counts.color==beforeColor,"Classic progress keeps static owned anchors/color")end
    check(classic._fluxCastFill.points[1][2]==classic._fluxCastDriver,"Classic fill geometry remains attached")
    metric("classicFill",{anchors=counts.anchors-beforeAnchors,color=counts.color-beforeColor,trace=trace})
    classic._fluxCastDriver=object(classic);overlay._classicOnUpdate(classic)
    check(classic._fluxCastFill.points[1][2]==classic._fluxCastDriver,"Classic driver replacement invalidates cached geometry")
    local dest=object();dest.width=61;dest.cooldown=object(dest)
    local movedDriver,movedArt=classic._fluxCastDriver,classic._fluxCastFill
    check(overlay.TransferCast(classic,dest),"actual Classic cast transfer succeeds")
    check(dest._fluxCastDriver==movedDriver and dest._fluxCastFill==movedArt and movedDriver.parent==dest,
        "Classic transfer retains live driver/art identity")
    check(movedArt.points[1][2]==movedDriver,"cached Classic anchor remains tied to transferred driver")
    overlay.ForceClear(dest);check(not dest._fluxVfxMode and not movedArt.shown,"clear transferred Classic cast")
    overlay.PlayClassicFill(dest,overlay.CAST)
    check(dest._fluxCastFill==movedArt and movedArt.shown,"Classic clear/reuse retains geometry and art")
    local nativeDest=object();nativeDest.width=61;nativeDest.cooldown=object(nativeDest)
    local nativeFrom=widgets[5];local movedNative=nativeFrom.SpellCastAnimFrame
    check(overlay.TransferCast(nativeFrom,nativeDest),"actual native channel transfer succeeds")
    check(nativeDest.SpellCastAnimFrame==movedNative and movedNative.parent==nativeDest,"native transfer retains live frame identity")
    check(movedNative._fluxChannelUnder.points[1][2]==nativeDest,"native transferred underlay reanchors immediately")
    overlay.ForceClear(nativeDest);check(not nativeDest._fluxVfxMode,"clear transferred native channel")
end

do
    local e=env();e.UnitExists=function()return true end;e.GetTime=function()return 10 end
    local requests,legacy,native=0,0,0
    local ns={Flux={Secrets={AuraUpdateInfoIsNoop=function(v)return v and v.empty end}},UnitFrames={}}
    loadSource("UnitFrames/FluxUnitFrames_AurasEngine.lua",e,ns)
    local uf=ns.UnitFrames
    local function engine()return{SetUnit=function()end,UpdateAllAuras=function()requests=requests+1 end}end
    local frame={unit="target",BuffContainer={_fluxEngine=engine()},DebuffContainer={_fluxEngine=engine()},auraEventFrame={}}
    function frame.auraEventFrame:SetScript(_,fn)self.handler=fn end
    local source=read("UnitFrames/FluxUnitFrames_Auras.lua")
    local first=assert(source:find('frame.auraEventFrame:SetScript("OnEvent"',1,true))
    local marker="\n            end)";local last=assert(source:find(marker,first,true))+#marker-1
    local helpers={RequestAuraRefreshThrottled=function()legacy=legacy+1 end,CancelAuraDebounce=function()end,
        RefreshFrameAuras=function()end,HAS_UNIT_AURA_DIFF_PAYLOAD=true,UF=uf,frame=frame,ns=ns}
    for k,v in pairs(helpers)do e[k]=v end
    assert(load(source:sub(first,last),"@actual-unit-aura-event-handler","t",e))()
    local payload=setmetatable({},{__index=function()error("restricted payload must not be read by engine path")end})
    for _=1,500 do
        -- Model native delivery in both orders; Flux's handler does not own
        -- native public/private payload processing or registered event order.
        native=native+2;frame.auraEventFrame.handler(nil,"UNIT_AURA","target",payload)
        frame.auraEventFrame.handler(nil,"UNIT_AURA","party1",payload)
    end
    check(native==1000 and legacy==0,"engine event path leaves native delivery and restricted payloads intact")
    local deltaRequests=requests
    frame.auraEventFrame.handler(nil,"PLAYER_TARGET_CHANGED")
    check(requests==deltaRequests+2,"target rebinding still explicitly refreshes both native containers")
    frame.auraEventFrame.handler(nil,"PLAYER_FOCUS_CHANGED")
    check(requests==deltaRequests+4,"focus rebinding refresh path retained")
    frame.BuffContainer._fluxEngine=nil;frame.DebuffContainer._fluxEngine=nil
    frame.auraEventFrame.handler(nil,"UNIT_AURA","target",{empty=false})
    frame.auraEventFrame.handler(nil,"UNIT_AURA","party1",{empty=false})
    frame.auraEventFrame.handler(nil,"UNIT_AURA","target",{empty=true})
    check(legacy==1,"legacy unit filtering, debounce request and no-op payload checks preserved")
    if not measure then check(deltaRequests==0,"incremental events do not force native full rebuilds")end
    metric("auras",{forcedDeltaRebuilds=deltaRequests,lifecycleRebuilds=requests-deltaRequests,nativeDeliveries=native,legacyRequests=legacy})
end
print("Passive core optimization: "..checks.." behavior/work-budget checks PASS; native FPS/pixels/taint NOT RUN")
