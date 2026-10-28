-- Native function identity / independent updates, not a simulation of WoW taint.
local checks=0
local function check(value,message) assert(value,message);checks=checks+1 end
local function read(path)
    local f=assert(io.open(path,"r"));local source=f:read("*a");f:close();return source:gsub("\r\n","\n")
end
local function compile(source,env)
    if setfenv then local fn=assert(loadstring(source));setfenv(fn,env);return fn end
    return assert(load(source,"@modern_spellbook_ownership","t",env))
end
for _,client in ipairs({"live","forever"}) do
    local nativeStack,shown,parentShown=false,false,true
    local frames,labels,layouts={},0,0
    local counts={show=0,hide=0,refresh=0}
    local env=setmetatable({},{__index=_G});env._G=env
    env.CreateFrame=function()
        local f={SetScript=function(self,key,fn)self[key]=fn end}
        frames[#frames+1]=f;return f
    end
    env.hooksecurefunc=function()error("must not hook native spellbook/mixin methods")end
    local nativeFilter,nativeVisuals=function()return true end,function()end
    env.SpellBookFrameMixin={ShouldDisplaySpellBookItem=nativeFilter}
    env.SpellBookItemMixin={UpdateVisuals=nativeVisuals}
    local info={spellID=133,subName=""}
    local row={spellBookItemInfo=info,HasValidData=function()return true end,
        SubName={SetText=function(_,text)check(not nativeStack and text=="Rank 1",client.." independent rank font update");labels=labels+1 end},
        UpdateSubName=function()error("must not mutate native spellBookItemInfo")end,
        UpdateTextContainer=function()check(not nativeStack,client.." independent text layout");layouts=layouts+1 end}
    local book={IsShown=function()return shown end,IsVisible=function()return shown and parentShown end,
        ForEachDisplayedSpell=function(_,fn)fn(row)end,
        PagedSpellsFrame={dataProvider={},viewDataList={},PagingControls={currentPage=1}}}
    env.PlayerSpellsFrame={SpellBookFrame=book}
    local flux={Client={isRetail=true,isForever=client=="forever"},Spell={GetSubtext=function()return "Rank 1" end}}
    compile(read("Core/Engine/SpellBookChrome.lua"),env)("_FluxUI",{Flux=flux})
    local source=read("Bars/SpellRank.lua")
    local a=assert(source:find("local function PatchSpellBookRankUI()",1,true))
    local b=assert(source:find("local function OnSpellbookShow()",a,true))
    local decorate=compile("local Flux,RankSupported=...\n"..source:sub(a,b-1).."\nreturn PatchSpellBookRankUI",env)(flux,function()return true end)
    local function onShow()check(not nativeStack,client.." show observer outside native stack");counts.show=counts.show+1;decorate()end
    local function onHide()check(not nativeStack,client.." hide observer outside native stack");counts.hide=counts.hide+1 end
    local function onRefresh()counts.refresh=counts.refresh+1;decorate()end
    flux.SpellBookChrome.Observe("binding",onShow,onHide,onRefresh)
    flux.SpellBookChrome.Observe("mouseover",function()check(not nativeStack,client.." checkbox outside native stack")end)
    check(#frames==1,client.." observers share one driver")
    frames[1].OnUpdate(frames[1],0.1)
    check(counts.show==0 and labels==0,client.." closed book is idle")
    nativeStack=true;shown=true
    check(env.SpellBookFrameMixin.ShouldDisplaySpellBookItem()==true,client.." native filter still usable")
    nativeStack=false
    frames[1].OnUpdate(frames[1],0.04)
    check(counts.show==0,client.." driver is throttled")
    frames[1].OnUpdate(frames[1],0.06)
    check(counts.show==1 and labels==1 and layouts==1,client.." book open decorates once")
    check(env.SpellBookFrameMixin.ShouldDisplaySpellBookItem==nativeFilter
        and env.SpellBookItemMixin.UpdateVisuals==nativeVisuals,client.." native filter/visual methods retain identity")
    check(info.subName=="",client.." native spell data remains untouched")
    for i=1,120 do frames[1].OnUpdate(frames[1],1/60) end
    check(counts.refresh==0 and labels==1,client.." idle visible book has no repeated layout/decoration")
    book.PagedSpellsFrame.PagingControls.currentPage=2
    frames[1].OnUpdate(frames[1],0.1)
    check(counts.refresh==1 and labels==2,client.." page change refreshes supplemental labels")
    book.PagedSpellsFrame.dataProvider={}
    frames[1].OnUpdate(frames[1],0.1)
    check(counts.refresh==2,client.." search/category data replacement refreshes controls")
    shown=false;frames[1].OnUpdate(frames[1],0.1)
    check(counts.hide==1,client.." close hides addon controls independently")
    shown=true;frames[1].OnUpdate(frames[1],0.1)
    check(counts.show==2,client.." reopen reapplies controls")
    parentShown=false;frames[1].OnUpdate(frames[1],0.1)
    check(counts.hide==2,client.." closing parent hides decorations even if child IsShown stays true")
    parentShown=true;frames[1].OnUpdate(frames[1],0.1)
    check(counts.show==3,client.." parent reopen restores decorations")

    -- Mover must never attach to this panel's native open/layout methods.
    local hooks,scripts,pending,watch={},{},{},nil
    local combat,scaleWrites=false,0
    shown=false
    local frame={IsProtected=function()return true end,IsMouseEnabled=function()return true end,
        IsShown=function()return shown end,GetName=function()return "PlayerSpellsFrame"end,SetPoint=function()end,
        SetScale=function()check(not nativeStack,client.." mover scale outside native stack");scaleWrites=scaleWrites+1 end,
        HookScript=function(_,key,fn)scripts[key]=fn end}
    local mover={IsFrame=function(value)return value==frame end,Resolve=function()return frame end,
        ShouldSkip=function()return false end,IsBlacklisted=function()return false end,
        FindDragHandles=function()return{frame}end}
    local mf={WindowMover=mover,Client=flux.Client,Combat={InLockdown=function()return combat end,
        Defer=function(key,fn)pending[key]=fn end}}
    local me=setmetatable({hooksecurefunc=function(_,key,fn)hooks[key]=fn end,
        CreateFrame=function()check(not watch,client.." one mover panel observer");watch={SetScript=function(self,key,fn)self[key]=fn end};return watch end,
        FluxOptions={GetWindowMoverDB=function()return{enabled=true,scaleEnabled=true,frames={PlayerSpellsFrame={scale=1.2}}}end}},
        {__index=_G});me._G=me
    compile(read("WindowMover/Engine.lua"),me)("_FluxUI",{Flux=mf})
    mover.Attach({name="PlayerSpellsFrame"})
    check(not hooks.SetPoint and not hooks.SetScale and not scripts.OnShow and not scripts.OnHide,
        client.." mover leaves PlayerSpells native show/hide/layout callbacks untouched")
    check(scaleWrites==0,client.." hidden panel is not changed during attachment")
    nativeStack=true;shown=true;nativeStack=false
    watch.OnUpdate(watch,0.1)
    check(scaleWrites==1,client.." saved placement restored after open")
    for i=1,20 do watch.OnUpdate(watch,0.1) end
    check(scaleWrites==1,client.." mover has no repeated idle layout")
    shown=false;watch.OnUpdate(watch,0.1);combat=true;shown=true;watch.OnUpdate(watch,0.1)
    check(scaleWrites==1 and pending["windowmover.apply.PlayerSpellsFrame"],client.." protected placement deferred in combat")
    combat=false;pending["windowmover.apply.PlayerSpellsFrame"]()
    check(scaleWrites==2,client.." placement recovers after combat")
end
print("Modern spellbook ownership: "..checks.." checks passed; native taint VM unverified")
