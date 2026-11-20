-- Actual trinket owner + Manager + dependent notification. Native state and
-- callbacks are modeled; work counts do not establish native frame time.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local function loadenv(text,name,mode,env)
    if _VERSION=="Lua 5.1"then
        local fn,err=loadstring(text,name);if fn then setfenv(fn,env)end;return fn,err
    end
    return load(text,name,mode,env)
end
local unpackValues=table.unpack or unpack
local source=read(os.getenv("FLUX_TRINKET_SQUEEZE_SOURCE") or "ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua")
local manager=read("ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua")
local notifier=read("FluxDefaultSettings.lua")
local na=notifier:find("-- Squeeze callback bodies are shared across notifications.",1,true)
    or assert(notifier:find("function FluxUILayoutSqueeze.NotifyLayoutDependents()",1,true))
local nb=assert(notifier:find("local squeezeRefreshScheduled = false",na,true))
notifier=notifier:sub(na,nb-1)
local measure=os.getenv("FLUX_TRINKET_SQUEEZE_MEASURE")=="1"
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function corrected(v,m)if not measure then check(v,m)end end

local function fixture(shape,classic,text,managerCode,notifierCode)
    local s={factor=.8,locked=false,equipped={[13]=true,[14]=true},objects={},calls={},writes={},reads=0,geometry=0,log={}}
    local e=setmetatable({},{__index=_G});e._G=e
    e.SlashCmdList={}
    local secret=setmetatable({}, {__eq=function()error("private equality")end,__lt=function()error("private order")end})
    e.issecretvalue=function(v)return rawequal(v,secret)end
    s.secret=secret
    local function hit(name)s.calls[name]=(s.calls[name]or 0)+1 end
    local function write(o,method,...)
        local key=o.id..":"..method;s.writes[key]=(s.writes[key]or 0)+1;s.log[#s.log+1]=key
        if method~="SetClipsChildren" and not (o.arrow or o.anchor and (method=="ClearAllPoints" or method=="SetPoint")) then
            s.geometry=s.geometry+1
        end
        if s.fail and s.fail.object==o and s.fail.method==method then error(s.fail.marker,0)end
        return ...
    end
    local function widget(id,anchor,arrow)
        local o={id=id,anchor=anchor,arrow=arrow,width=1,height=1,scale=1,points={},shown=true,scripts={},events={}}
        s.objects[id]=o
        function o:GetWidth()s.reads=s.reads+1;return self.width end
        function o:GetHeight()s.reads=s.reads+1;return self.height end
        function o:GetSize()s.reads=s.reads+1;return self.width,self.height end
        function o:GetScale()s.reads=s.reads+1;return self.scale end
        function o:GetNumPoints()s.reads=s.reads+1;return #self.points end
        function o:GetPoint(index)s.reads=s.reads+1;return unpackValues(self.points[index or 1] or {})end
        local function after(self,method)
            if s.reenter and s.reenter.object==self and s.reenter.method==method then
                local callback=s.reenter.callback;s.reenter=nil;callback()
            end
        end
        function o:SetWidth(v)write(self,"SetWidth");self.width=v;after(self,"SetWidth")end
        function o:SetHeight(v)write(self,"SetHeight");self.height=v;after(self,"SetHeight")end
        function o:SetSize(w,h)write(self,"SetSize");self.width,self.height=w,h;after(self,"SetSize")end
        function o:SetScale(v)write(self,"SetScale");self.scale=v;after(self,"SetScale")end
        function o:SetClipsChildren(v)write(self,"SetClipsChildren");self.clips=v end
        function o:ClearAllPoints()write(self,"ClearAllPoints");self.points={}end
        function o:SetPoint(...)write(self,"SetPoint");self.points[#self.points+1]={...};after(self,"SetPoint")end
        function o:IsObjectType(kind)return kind=="Frame"end
        function o:IsShown()return self.shown end
        function o:Show()self.shown=true end
        function o:Hide()self.shown=false end
        function o:RegisterEvent(name)self.events[name]=true end
        function o:SetScript(name,fn)self.scripts[name]=fn end
        function o:GetScript(name)return self.scripts[name]end
        function o:HookScript(name,fn)local old=self.scripts[name];self.scripts[name]=function(...)if old then old(...)end;fn(...)end end
        return o
    end
    s.widget=widget
    e.UIParent=widget("UIParent")
    e.FluxActionStrip=widget("ActionStrip");e.FluxMainActionBar=e.FluxActionStrip
    e.InCombatLockdown=function()return s.locked end
    e.GetInventoryItemLink=function(_,slot)return s.equipped[slot]and("item:"..slot)end
    e.GetBindingKey=function()end
    e.wipe=function(t)for k in pairs(t)do t[k]=nil end end
    e.CreateFrame=function()return widget("event"..tostring(#s.log))end
    e.C_Timer={After=function()end}
    e.UnitClass=function()return "Mage","MAGE"end;e.RAID_CLASS_COLORS={MAGE={r=1,g=1,b=1}}
    e.FLUX_API={isAnyClassic=classic,isPostDF=not classic}
    local flux={Module={Register=function()end},Client={isAnyClassic=classic,isPostDF=not classic},EBS={}}
    e.Flux=flux
    flux.Combat={Defer=function()hit("defer")end}
    flux.EBS.Style={RefreshSqueezeChrome=function()hit("style")end}
    flux.EBS.Flyout={RefreshArrowLayers=function()hit("arrowLayers")end,
        Arrow={ConfigureLayer=function()hit("configureArrow")end},OnDependentsLayoutChanged=function()hit("flyoutLayout")end}
    e.FluxBorder={ApplyTo=function()hit("border")end,SetClassColor=function()hit("borderColor")end}
    e.FluxButtonUtil={ApplyCooldownCountdownHorizontalScale=function()hit("countdown")end}
    e.FluxCombatManager={Grid={Relayout=function()hit("combatGrid")end},UpdateAnchor=function()hit("combatAnchor")end}
    e.FluxNonCombatAPI={DefaultGrid={Relayout=function()hit("noncombatGrid")end}}
    e.FluxNonCombatGrid_ApplyScreenBottomAnchor=function()hit("noncombatAnchor")end
    e.FluxUILayoutSqueeze={InvalidateEmulatedDependentCache=function()hit("invalidate")end,
        GetActionBarHorizontalSqueezeFactor=function()return s.factor end,
        GetEffectiveEmulatedDependentXFactorForUnitFrames=function()return s.factor end}
    assert(loadenv(text or source,"@actual-trinket-squeeze-owner","t",e))("_FluxUI",{Flux=flux})
    local tm=e.FluxTrinketMenu;s.tm=tm;s.env=e
    tm.Frame=widget("Frame");tm.ScaleHost=widget("ScaleHost",true)
    tm._baseSlotWidth,tm._baseFrameHeight,tm.ButtonSize,tm.Spacing=54,108,45,0
    tm.VisibilityState="both_equipped";tm.Buttons={}
    for i=0,1 do
        local slot=widget("Slot"..i)
        local button=widget("Button"..i)
        button.SlotFrame=slot
        if shape=="modern"then button.Widget=widget("Widget"..i)
        else button.NormalTexture=widget("Normal"..i);button.Border=widget("Ring"..i);button.Cooldown={}end
        local owner=button.Widget or button
        owner.FluxFlyoutArrow=widget("Arrow"..i,false,true)
        tm.Buttons[i]=button
    end
    local apply=tm.ApplyHorizontalSqueeze
    tm.ApplyHorizontalSqueeze=function()
        hit("squeeze");apply()
        if s.afterSqueeze then local callback=s.afterSqueeze;s.afterSqueeze=nil;callback()end
    end
    assert(loadenv(managerCode or manager,"@actual-trinket-manager","t",e))("_FluxUI",{Flux=flux})
    e.FluxTrinketMenuManager._startupReady=true
    assert(loadenv(notifierCode or notifier,"@actual-dependents-notifier","t",e))()
    function s:notify(crossing)e.FluxUILayoutSqueeze.NotifyLayoutDependents(nil,crossing)end
    function s:reset()self.calls={};self.writes={};self.reads=0;self.geometry=0;self.log={}end
    function s:direct()tm.ApplyHorizontalSqueeze()end
    s.hit=hit
    return s
end

local function stateChecks(s,label)
    local tm=s.tm
    check(tm.Frame.width==54*s.factor and tm.Frame.height==108,label.." frame dimensions")
    check(tm.ScaleHost.width==tm.Frame.width and tm.ScaleHost.height==108,label.." scale host dimensions")
    for i=0,1 do
        local button=tm.Buttons[i];local slot=button.SlotFrame
        check(slot.width==54*s.factor and slot.height==54,label.." slot dimensions")
        check(slot.points[1][2]==tm.Frame and #slot.points==1,label.." current frame owns exactly one slot anchor")
        local face=button.Widget or button
        check(face.width==45*s.factor and face.height==45 and face.scale==1.2,label.." complete face scaling")
        check(slot.clips==(not s.env.FLUX_API.isAnyClassic and s.factor<1),label.." original clipping policy")
    end
end

local warm
for _,shape in ipairs({"modern","legacy"})do
 for _,classic in ipairs({false,true})do
    local s=fixture(shape,classic);local tm=s.tm
    s:notify();stateChecks(s,"cold "..shape)
    check(s.calls.squeeze==2 and s.calls.border==2 and s.calls.arrowLayers==2 and s.calls.configureArrow==4,
        "both actual notification/Manager squeeze calls and all border/arrow work remain")
    check(s.calls.combatGrid==1 and s.calls.noncombatGrid==1 and s.calls.flyoutLayout==1,"other notification consumers retain cadence")
    check((s.calls.style or 0)==(shape=="modern"and 4 or 0),"all style calls remain")
    check((s.calls.countdown or 0)==(shape=="legacy"and 4 or 0),"all legacy cooldown sizing calls remain")
    s:reset();for _=1,10 do s:notify()end
    corrected(s.geometry==0,"unchanged native squeeze geometry requires no native writes")
    check(s.calls.squeeze==20 and s.calls.border==20 and s.calls.arrowLayers==20 and s.calls.configureArrow==40,
        "warm source invocation, border, arrow and layer cadence unchanged")
    check(s.writes["Slot0:SetClipsChildren"]==20 and s.writes["Slot1:SetClipsChildren"]==20,"clipping setter intentionally remains unconditional")
    if not warm then warm={geometry=s.geometry,reads=s.reads}end
    tm.VisibilityState="one_equipped";s.equipped={[13]=true};s:notify()
    check(tm.Buttons[0].SlotFrame.points[1][5]==27 and tm.Buttons[1].SlotFrame.points[1][5]==0,"only upper trinket centers in both-row frame")
    s.equipped={[14]=true};s:notify()
    check(tm.Buttons[0].SlotFrame.points[1][5]==0 and tm.Buttons[1].SlotFrame.points[1][5]==27,"equipped-slot reassignment is read fresh")
    tm.VisibilityState="bag_only";s:notify()
    check(tm.Buttons[0].SlotFrame.points[1][5]==27 and tm.Buttons[1].SlotFrame.points[1][5]==0,"bag-only slot centers")
    tm.VisibilityState="none";s.factor=1;s:notify();stateChecks(s,"restored "..shape)
    check(tm.Buttons[0].SlotFrame.points[1][5]==54,"none retains original two-slot fallback")
    local slot=tm.Buttons[0].SlotFrame
    slot.width=999;slot.height=998;slot.points={{"CENTER",s.env.UIParent,"CENTER",1,2},{"LEFT",s.env.UIParent,"LEFT",0,0}}
    tm.Frame.width=997;tm.Frame.height=996;tm.ScaleHost.width=995
    local driftFace=tm.Buttons[0].Widget or tm.Buttons[0];driftFace.scale=7
    s:notify();stateChecks(s,"native drift "..shape)
    local old=tm.Frame
    s.afterSqueeze=function()
        tm.Frame=s.widget("ReplacementFrame");tm.ScaleHost=s.widget("ReplacementHost",true)
        tm.Buttons[0].SlotFrame=s.widget("ReplacementSlot")
    end
    s:notify();stateChecks(s,"late native replacement "..shape)
    check(tm.Frame~=old and tm.Buttons[0].SlotFrame.points[1][2]==tm.Frame,"second source call repairs a replacement after first squeeze")
    tm.VisibilityState="one_equipped";s.equipped={[13]=true}
    s.afterSqueeze=function()s.equipped={[14]=true}end;s:notify()
    check(tm.Buttons[1].SlotFrame.points[1][5]==27,"equipped change between notification callbacks is preserved")
    s:reset();s.locked=true;s:notify()
    check(s.geometry==0 and not s.calls.squeeze and s.calls.defer==1,"whole notification remains deferred in combat")
    s:direct();check(s.calls.defer==2,"direct squeeze retains independent combat recovery")
    s.locked=false;s:notify();stateChecks(s,"combat recovery "..shape)
 end
end

local checkpoint=arg and arg[1]
local previousManager,previousNotifier
if checkpoint then
    previousManager=read(checkpoint.."/ExtraButtonSystem-TrinketMenu-FluxTrinketMenuManager.lua")
    local settings=read(checkpoint.."/FluxDefaultSettings.lua")
    local a=assert(settings:find("-- Squeeze callback bodies are shared across notifications.",1,true))
    previousNotifier=settings:sub(a,assert(settings:find("local squeezeRefreshScheduled = false",a,true))-1)
end
for _,shape in ipairs({"modern","legacy"})do
 for _,classic in ipairs({false,true})do
    local s=fixture(shape,classic);s:notify()
    local old=checkpoint and fixture(shape,classic,nil,previousManager,previousNotifier)
    if old then old:notify();old:reset()end
    s:reset()
    for i=1,10 do
        s:notify(true)
        if old then old:notify(true)end
    end
    stateChecks(s,"strip transition "..shape)
    check(s.calls.squeeze==10 and s.calls.border==10 and s.calls.arrowLayers==10,"strip runs one owner pass")
    check(not s.writes["ScaleHost:ClearAllPoints"] and s.geometry==0,"attached host and local geometry are retained")
    if old then
        stateChecks(old,"before strip transition "..shape)
        check(old.calls.squeeze==20 and old.writes["ScaleHost:ClearAllPoints"]==10,"exact before work is repeated")
        print(("STRIP_TRINKET shape=%s classic=%s squeeze=%d/%d anchor=%d/0"):format(
            shape,tostring(classic),old.calls.squeeze,s.calls.squeeze,old.writes["ScaleHost:ClearAllPoints"]))
    end
    local host=s.tm.ScaleHost
    host.points={{"CENTER",s.env.UIParent,"CENTER",0,0}}
    s:reset();s:notify(true)
    check(s.calls.squeeze==1 and s.writes["ScaleHost:ClearAllPoints"]==1 and host.points[1][2]==s.env.FluxActionStrip,
        "bad host anchor uses the existing repair once")
    host.GetPoint=function()return s.secret,s.secret,s.secret,s.secret,s.secret end
    s:reset();s:notify(true)
    check(s.calls.squeeze==1 and s.writes["ScaleHost:ClearAllPoints"]==1,"private host anchor falls back")
    s.factor=.7;s:notify(true);stateChecks(s,"changed strip squeeze "..shape)
    s.locked=true;s:reset();s:notify(true)
    check(s.calls.defer==1 and s.geometry==0 and not s.calls.squeeze,"relatives stay outside combat")
 end
end

-- Unknown getters preserve the original setters, including all anchor writes.
for _,case in ipairs({{"Frame","GetWidth","SetWidth"},{"Frame","GetHeight","SetHeight"},
    {"Slot0","GetSize","SetSize"},{"Widget0","GetSize","SetSize"},{"Widget0","GetScale","SetScale"},
    {"Slot0","GetNumPoints","SetPoint"},{"Slot0","GetPoint","SetPoint"}})do
 for _,kind in ipairs({"missing","throw","private","privateMethod"})do
    local s=fixture("modern",false);s:notify();s.tm.ScaleHost=nil
    local object=s.objects[case[1]]
    object[case[2]]=kind=="missing"and false or kind=="privateMethod"and s.secret or function()
        if kind=="throw"then error("unavailable getter")end;return s.secret,s.secret,s.secret,s.secret,s.secret
    end
    s:reset();check(pcall(s.direct,s),"unknown native getter remains a conservative native write")
    check((s.writes[case[1]..":"..case[3]]or 0)>0,"unknown getter never suppresses correction")
 end
end

-- An unreadable later GetPoint result is also private; checking only point is insufficient.
for index=2,5 do
 local s=fixture("modern",false);s:notify();local slot=s.tm.Buttons[0].SlotFrame
 function slot:GetPoint()local p={"BOTTOMLEFT",s.tm.Frame,"BOTTOMLEFT",0,54};p[index]=s.secret;return unpackValues(p)end
 s:reset();check(pcall(s.direct,s)and(s.writes["Slot0:SetPoint"]or 0)>0,"private anchor tuple field is never compared")
end

for _,case in ipairs({{"Frame","SetWidth","width"},{"Frame","SetHeight","height"},
    {"Slot0","SetSize","width"},{"Widget0","SetScale","scale"},
    {"Slot0","ClearAllPoints","points"},{"Slot0","SetPoint","points"}})do
 local s=fixture("modern",false);s:notify();local object=s.objects[case[1]]
 object[case[3]]=case[3]=="points"and{}or 999
 local marker={};s.fail={object=object,method=case[2],marker=marker}
 local ok,err=pcall(s.direct,s)
 check(not ok and rawequal(err,marker),"native setter error propagates exactly: "..case[2])
 s.fail=nil;s:notify();stateChecks(s,"setter recovery")
end

do
 local s=fixture("modern",false);s:notify();local slot=s.tm.Buttons[0].SlotFrame
 slot.width=999;s.reenter={object=slot,method="SetSize",callback=function()s:direct()end}
 s:direct();stateChecks(s,"native setter reentry")
 check(not s.reenter,"native geometry callbacks can reenter without stale desired-state publication")
 s:reset();s.tm.Frame.width=999;s.tm.Frame.height=999;slot.width=999;slot.points={}
 s:direct()
 check(s.log[1]=="Frame:SetWidth"and s.log[2]=="Frame:SetHeight"and s.log[3]=="Slot0:SetSize"
    and s.log[4]=="Slot0:SetClipsChildren"and s.log[5]=="Slot0:ClearAllPoints"and s.log[6]=="Slot0:SetPoint",
    "required writes preserve width/height/size/clipping/clear/anchor order")
end

-- Reject dropping native drift repair or hiding real native setter failures.
if not measure then
 local stale,n=source:gsub("current ~= width","false",1)
 check(n==1,"drift control targets actual native width guard")
 local s=fixture("modern",false,stale);s:notify();s.tm.Frame.width=999;s:direct()
 check(s.tm.Frame.width==999,"harmful width guard control is exposed by native drift")
 local swallowed,n=source:gsub("frame:SetWidth%(width%)","pcall(frame.SetWidth, frame, width)",1)
 check(n==1,"error control targets actual native width setter")
 local s=fixture("modern",false,swallowed);s:notify();s.tm.Frame.width=999
 s.fail={object=s.tm.Frame,method="SetWidth",marker={}}
 check(pcall(s.direct,s),"harmful setter suppression control is exposed by missing original error")
end
local function envelopeFixture(client, baseline)
    local function exact(path)return read(baseline and baseline.."/"..path:gsub("/","-") or path)end
    local s=fixture(client=="classic" and "legacy" or "modern",client=="classic",
        exact("ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua"))
    local e=s.env
    local engine=e.Flux.EBS.Flyout
    e.FLUX_API.isForever=client=="forever"
    local function layerMethods(o)
        function o:GetParent()return self.parent end
        function o:GetFrameStrata()return self.strata or "MEDIUM"end
        function o:GetFrameLevel()return self.level or 10 end
        function o:GetEffectiveScale()return self.scale end
        function o:SetParent(value)self.parent=value;s.hit("layerWrites")end
        function o:SetFrameStrata(value)self.strata=value;s.hit("layerWrites")end
        function o:SetFrameLevel(value)self.level=value;s.hit("layerWrites")end
        return o
    end
    layerMethods(e.UIParent)
    local frame=layerMethods(s.widget("Envelope"))
    frame.FluxBorderFrame=layerMethods(s.widget("Atlas"))
    local peer=s.widget("EnvelopePeer")
    function peer:GetLeft()return self.x or 0 end
    function peer:GetBottom()return 0 end
    e.FluxUnifiedBorderFrame=frame
    e.GetBorderAnchors=function()
        return {leftAnchor=peer,rightAnchor=peer,topAnchor=peer,bottomAnchor=peer}
    end
    e.UpdateActionStripInfoGapBackdrop=function()end
    e.UpdateGapBackdrop=function()end
    for _,file in ipairs({"Init","Attach","Arrow"})do
        local path="ExtraButtonSystem/FlyoutEngine/"..file..".lua"
        assert(loadenv(exact(path),"@"..path,"t",e))("_FluxUI",{Flux=e.Flux})
    end
    local refresh,update=engine.RefreshArrowLayers,engine.Arrow.Update
    engine.RefreshArrowLayers=function()s.hit("arrowLayers");refresh()end
    engine.Arrow.Update=function(...)s.hit("arrowUpdates");update(...)end
    for i=0,19 do
        local widget=layerMethods(i<2 and s.tm.SlotWidget(i) or s.widget("Host"..i))
        local arrow=layerMethods(widget.FluxFlyoutArrow or s.widget("OtherArrow"..i,false,true))
        engine.attached[widget]={arrow=arrow,opts={direction="UP",anchorFrame=i<2 and s.tm.Frame or nil}}
    end
    local border=exact("Layout/UnifiedBorder.lua")
    local function slice(first,last)
        local a=assert(border:find(first,1,true))
        return border:sub(a,assert(border:find(last,a+#first,true))-1)
    end
    local code=border:find("local function RefreshBorderArrows()",1,true)
        and slice("local function RefreshBorderArrows()","local function CreateBorderFrame()") or ""
    code=code..slice("local function GapPointMatches(","local function GapAnchorsMatch(")
        ..slice("local lastBorderLayoutHash","--- Unified micro+status chrome")
    local updateBorder=assert(loadenv("local borderFrame=FluxUnifiedBorderFrame;local UnifiedBorder={}\n"..code
        .."\nreturn UpdateBorder","@actual-envelope-update","t",e))()
    function s:cross(count)
        for i=1,count do
            peer.x=i%2==0 and 0 or 80
            self.factor=i%2==0 and .8 or .6
            self:notify(true)
            updateBorder(true)
        end
    end
    s:cross(2)
    s:reset()
    return s
end

local arrowCheckpoint=os.getenv("FLUX_STRIP_ARROW_OWNER_CHECKPOINT")
local benchmark=os.getenv("FLUX_STRIP_ARROW_OWNER_MEASURE")=="1"
local function arrowWork(s,client,n)
    local started=os.clock()
    s:cross(n)
    local elapsed=(os.clock()-started)*1000
    local state={}
    for widget,rec in pairs(s.env.Flux.EBS.Flyout.attached)do
        local arrow=rec.arrow
        local point,relative,_,x,y=arrow:GetPoint(1)
        check(point=="TOP" and relative==widget and x==0 and y==6 and #arrow.points==1,client.." arrow follows host")
        check(arrow.parent==s.env.FluxUnifiedBorderFrame and arrow:GetFrameLevel()==15,client.." arrow above the atlas")
        state[widget.id]=table.concat({arrow:GetWidth(),arrow:GetHeight(),arrow:GetScale(),arrow:GetFrameLevel()},",")
    end
    return elapsed,state
end

if not measure then
 for _,client in ipairs({"retail","forever","classic"})do
    for trial=1,benchmark and 5 or 1 do
        local s=envelopeFixture(client)
        local old=arrowCheckpoint and envelopeFixture(client,arrowCheckpoint)
        local n=benchmark and 120 or 60
        local beforeMs,before,afterMs,after
        if old and trial%2==1 then beforeMs,before=arrowWork(old,client,n)end
        afterMs,after=arrowWork(s,client,n)
        if old and trial%2==0 then beforeMs,before=arrowWork(old,client,n)end
        check(s.calls.arrowLayers==n*2 and s.calls.arrowUpdates==n*3*20,client.." two explicit sweeps and one dependents sweep")
        if old then
            for id,values in pairs(after)do check(values==before[id],client.." exact final arrow shape")end
            check(old.calls.arrowLayers==n*3 and old.calls.arrowUpdates==n*4*20,client.." before envelope repeats the trinket engine")
            print(("STRIP_ARROW client=%s trial=%d crossings=%d global=%d/%d updates=%d/%d layers=%d/%d ms=%.3f/%.3f"):format(
                client,trial,n,old.calls.arrowLayers,s.calls.arrowLayers,old.calls.arrowUpdates,s.calls.arrowUpdates,
                old.calls.layerWrites or 0,s.calls.layerWrites or 0,beforeMs,afterMs))
        end
    end
 end
 local s=fixture("modern",false)
 local tm,engine=s.tm,s.env.Flux.EBS.Flyout
 tm.RefreshArrowLayersOnBorder()
 local a=s.objects.Arrow0
 s:reset()
 tm.RefreshArrowLayersOnBorder(engine.RefreshArrowLayers)
 check(not s.calls.arrowLayers and s.calls.configureArrow==2 and not s.writes["Arrow0:SetPoint"],
     "verified shared refresh retains the already correct local point")
 a.points={}
 s:reset()
 tm.RefreshArrowLayersOnBorder(function()end)
 check(s.calls.arrowLayers==1 and a.points[1][2]==tm.SlotWidget(0),"a different callback preserves the whole local refresh")
 a.GetNumPoints=function()return s.secret end
 s:reset()
 tm.RefreshArrowLayersOnBorder(engine.RefreshArrowLayers)
 check(s.writes["Arrow0:SetPoint"]==1,"a private local anchor retains the native writer")
end

print("TRINKET_SQUEEZE_WORK|10notifications|20sourceCalls|geometry="..warm.geometry.."|nativeReads="..warm.reads.."|clipWrites=40|styleCalls=40|arrowLayers=20")
print("Trinket squeeze geometry: "..checks.." checks PASS; original calls/cadence/recovery retained; native timing pending")
