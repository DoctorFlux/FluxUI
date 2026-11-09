-- Production timer/retry owners with native no-return After and cancellable
-- NewTimer. Stale cancelled callbacks are deliberately callable by the fixture.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local function cut(s,a,b)local p=assert(s:find(a,1,true),a);return s:sub(p,assert(s:find(b,p+#a,true),b)-1)end
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function clock(handles)
    local s={now=0,queue={},calls=0,placement="statusIntegrated",combat=false}
    local e=setmetatable({},{__index=_G});e._G=e
    e.GetTime=function()return s.now end;e.InCombatLockdown=function()return s.combat end
    local function add(delay,fn,handle)local q={at=s.now+delay,fn=fn,handle=handle};s.queue[#s.queue+1]=q;return q end
    e.C_Timer={After=function(delay,fn)add(delay,fn)end}
    if handles then e.C_Timer.NewTimer=function(delay,fn)
        local h={};function h:Cancel()self.cancelled=true end;add(delay,fn,h);return h
    end end
    function s.active()local n=0;for _,q in ipairs(s.queue)do if not(q.handle and q.handle.cancelled)then n=n+1 end end;return n end
    function s.to(t)
        local guard=0
        while true do
            local which,at
            for i,q in ipairs(s.queue)do if q.at<=t and(not at or q.at<at)then which,at=i,q.at end end
            if not which then break end
            guard=guard+1;assert(guard<10000,"timer queue must quiesce")
            local q=table.remove(s.queue,which);s.now=q.at
            if not(q.handle and q.handle.cancelled)then q.fn()end
        end
        s.now=t
    end
    s.env=e;return s,e
end
for _,handles in ipairs({false,true})do
    for _,kind in ipairs({"status","info"})do
        local s,e=clock(handles);local function sink()s.calls=s.calls+1 end
        e.FluxOptions={GetInfoFramePlacement=function()return s.placement end}
        e.FluxUnifiedBorder={UpdateBorder=sink,UpdateStatusBarBorder=sink};e.FluxPVPObjectiveMover={UpdatePositions=sink}
        local code
        if kind=="status"then code=cut(read("StatusBars/FluxStatusBar.lua"),"local function InfoPlacementIsStatusIntegrated()","local function NotifyStatusBarLayoutDependentsBody()").."\nreturn NotifyUnifiedUIAndPVPThrottled,CancelNotifyUnifiedUICoalescer"
        else
            e.fixturePlacement=function()return s.placement end;e.fixtureRun=sink
            code="local GetPlacement=fixturePlacement;local RunIntegratedLayoutPass=fixtureRun;local UpdatePositionImmediate=function()end\n"
                ..cut(read("StatusBars/FluxInfoFrame.lua"),"local INTEGRATED_LAYOUT_COOLDOWN =","-- EVENT-BASED: Stats updates").."\nreturn UpdatePosition,CancelIntegratedCooldownTimer"
        end
        local notify,cancel=assert(load(code,"@production-layout-owner","t",e))()
        if kind=="info"then notify();check(s.calls==1,"Info retains immediate first layout")end
        local before=s.calls
        for i=1,1000 do notify()end
        check(s.active()==1,"layout storm owns one pending timer with either native API")
        local stale=s.queue[1].fn;cancel();notify();local active=s.active();stale()
        check(s.calls==before and s.active()==active,"cancelled callback neither paints nor clears replacement")
        s.to(1);check(s.calls==before+(kind=="status"and 3 or 1),"one original cadence flush calls each dependency once")
        s.now=1.01;notify();cancel();local count=s.calls;s.to(2);check(s.calls==count,"explicit cancellation suppresses pending layout")
    end
    do
        local s,e=clock(handles);local parent={hooks={}};function parent:HookScript(k,f)self.hooks[k]=f end
        e.parent=parent;e.grid=function()s.calls=s.calls+1 end
        local code="local isEmbedded=true;local embeddedParentFrame=parent;local currentLayoutConfig={};local embedOperationGeneration=1;local LayoutMeterGrid=grid;local ReapplyConfigureEmbeddedInstances=function()end\n"
            ..cut(read("Battlezonemap/FluxDetails.lua"),"local GRID_LAYOUT_ON_SIZE_DEBOUNCE =","function FluxDetails:Embed(parentFrame, layoutConfigOrMode)")
            .."\nreturn EnsureMeterGridSizeHook,function()embedOperationGeneration=embedOperationGeneration+1 end"
        local ensure,reembed=assert(load(code,"@production-details-debounce","t",e))();ensure(parent,{})
        for i=1,1000 do parent.hooks.OnSizeChanged(parent)end
        check(s.active()==1,"Details resize burst retains one timer even with After fallback")
        s.to(.03);parent.hooks.OnSizeChanged(parent);s.to(.05)
        check(s.calls==0 and s.active()==1,"Details preserves trailing50ms quiet deadline")
        s.to(.081);check(s.calls==1,"Details paints one grid after resize quiet")
        parent.hooks.OnSizeChanged(parent);local old=s.queue[1].fn;reembed();parent.hooks.OnSizeChanged(parent);old()
        s.to(.2);check(s.calls==2,"old embed callback cannot clear the new owner's timer")
    end
    do
        local s,e=clock(handles);local shown={};local fly={Show=function(anchor)shown[#shown+1]=anchor end,Hide=function()end}
        local source=read("Other/FluxEquipSlotFlyout.lua")
        local code="local Flyout,Candidates=...\n"..cut(source,"local function CancelTimer(t)","function Flyout.IsOpenFor(slotID, anchor)")
            ..cut(source,"function Flyout.ScheduleHideSoon(extraFrames)","local function CreateMenuButton(f, idx)")
            ..cut(source,"function Flyout.NotifyEnter(anchor, slotID, opts)","function Flyout.SetOnEquipped(fn)")
        assert(load(code,"@production-flyout-timers","t",e))(fly,{HasAlternatives=function()return true end})
        local a,b={},{};fly.NotifyEnter(a,1,{});local old=s.queue[1].fn;s.to(.02);fly.NotifyLeave({});fly.NotifyEnter(b,2,{});old()
        s.to(.079);check(#shown==0,"cancel/replace retains exact60ms show delay")
        s.to(.081);check(#shown==1 and shown[1]==b,"only latest hover owner can show")
        fly.NotifyEnter(a,1,{});fly.CancelShowTimer();s.to(.2);check(#shown==1,"cancelled hover cannot resurrect flyout")
        for i=1,1000 do fly.NotifyEnter({id=i},i%19+1,{})end
        s.to(.3);check(#shown==2 and shown[2].id==1000,"rapid hover coalesces to current final owner")
    end
    for _,kind in ipairs({"junk","restock"})do
        local s,e=clock(handles);s.shown=true;s.loaded=false;s.requests=0;s.refreshes=0;s.item=12345
        e.C_Item={GetItemInfo=function()return s.loaded and"Item"or nil end,IsItemDataCachedByID=function()return s.loaded end,
            RequestLoadItemDataByID=function(id)s.requests=s.requests+1;s.lastRequest=id end}
        local panel={RefreshList=function()s.refreshes=s.refreshes+1 end,InvalidateListCache=function()end}
        local frame={scripts={}};function frame:IsShown()return s.shown end;function frame:SetScript(k,f)self.scripts[k]=f end
        e.fixtureJunk={GetUsefulList=function()return{s.item}end,GetJunkTabList=function()return{s.item}end}
        e.fixtureRestock=function()return{{itemID=s.item}}end
        local path=kind=="junk"and"Inventory/Restock/Junk/FluxVendorJunkPanel.lua"or"Inventory/Restock/Vendor/FluxVendorRestockPanel.lua"
        local source=read(path);local code="local Panel,panelFrame=...;local selectedSubTab=2;local FJ=fixtureJunk;local FV;local listButtons={};local UpdateScrollChildWidth=function()end;local GetRestockList=fixtureRestock\n"
            ..cut(source,"local QueryItems","local ROW_HEIGHT")
        if kind=="junk"then
            code=code..cut(source,"local function GetItemInfoCompat(id)","local function GetAllListedIds()")
                ..cut(source,"function Panel:SetSubTab(tabIndex, keepSelection)","local function ScrollListToItem(itemID)")
                ..cut(source,'    panelFrame:SetScript("OnHide", function()','    if not panelFrame.fluxItemDataHooked then')
                .."\nreturn function()Panel:SetSubTab(1)end"
        else
            code=code..cut(source,"local function GetItemInfoCompat(id)","local function GetItemIdFromCursor()")
                ..cut(source,"QueryItems = function()","local function OnItemDrop()")
                ..cut(source,'    panelFrame:SetScript("OnHide", function()','    return panelFrame\nend')
                .."\nreturn function()Panel:OnTabSelected()end"
        end
        local query=assert(load(code,"@production-vendor-retry","t",e))(panel,frame)
        for i=1,250 do query()end;s.to(0)
        check(s.active()==1,"250 tab/query entries retain one metadata retry")
        local requests=s.requests;s.to(.199);check(s.requests==requests,"metadata retry retains200ms cadence")
        s.item=54321;s.to(.201);check(s.requests==requests+1 and s.lastRequest==54321,"single retry reads the current list instead of captured rows")
        local stale=s.queue[#s.queue].fn;s.shown=false;frame.scripts.OnHide();s.shown=true;query();s.to(.201);local before=s.requests;stale()
        check(s.requests==before,"hidden owner's stale callback cannot query reopened panel")
        s.loaded=true;s.to(1);check(s.active()==0,"metadata completion ends the one retry chain")
    end
end
print("Native timer ownership: "..checks.." checks; After/NewTimer cancel/replace, exact cadence, resize/embed/hover/current-list/hide reuse")
