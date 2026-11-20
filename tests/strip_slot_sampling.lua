-- Compare the actual visual pass with the archived action-strip layout.
-- Supply the checkpoint directory to count old and current widget/API work.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local source=file:read("*a")
    file:close()
    return (source:gsub("\r\n","\n"))
end
local promotion=arg[1]=="--promotion"
local prior=arg[promotion and 2 or 1]
local source=Read("tests/bars_strip_layout_work.lua")
source=source:sub(1,assert(source:find("local candidate=true;local checks=0",1,true))-1)
local paths=prior and {prior.."/Bars-Layout.lua",prior.."/Bars-Strip.lua"} or {}
local fixture=assert(load(source.."\nreturn fixture","@visual-slot-fixture","t",setmetatable({arg=paths},{__index=_G})))()

local function Configure(candidate,bottom,dense,page)
    local model=fixture(candidate)
    local bars,flux=model.B,model.flux
    model.bottom,model.page=bottom,page
    if dense then for slot=15,19 do model.occupied[slot]=100+slot end end
    model.occupied[1],model.occupied[61]=nil,nil
    model.occupied[73]=173 -- Other form remains the main occupant.
    if promotion then model.occupied[10]=nil end
    local overlay,idle={},{}
    overlay[bars.State.GetSecondarySlot(14)]="/cast Fixture"
    idle[bars.State.GetTertiarySlot(15)]="/click Fixture"
    bars.SlotProgram.Get=function(slot)return overlay[slot] end
    bars.SlotProgram.GetIdle=function(slot)return idle[slot] end
    bars.Layout.Invalidate()
    bars.Layout.Request("slot")
    model.drain()
    local reads={action=0,page=0,calls=0,mapping=0,emptyMain=0,expandedPack=0}
    local apply,hasAction,getPage=bars.Layout.ApplyVisual,flux.Action.HasAction,bars.State.GetCurrentPage
    local applyMappings=bars.Layout.ApplyMappings
    local isEmpty=bars.Layout.IsColumnEmpty
    local seen,mapping,collapsed
    bars.Layout.ApplyMappings=function(...)
        if promotion then collapsed=not bars.Layout.IsExpanding() end
        mapping=true
        applyMappings(...)
        mapping=false
    end
    bars.Layout.ApplyVisual=function(...)
        collapsed=not bars.Layout.IsExpanding()
        reads.calls=reads.calls+1
        seen={}
        local moved,shell,faces=apply(...)
        seen=nil
        return moved,shell,faces
    end
    bars.Layout.IsColumnEmpty=function(...)
        if seen and not collapsed then reads.expandedPack=reads.expandedPack+1 end
        return isEmpty(...)
    end
    flux.Action.HasAction=function(slot)
        if mapping then reads.mapping=reads.mapping+1 end
        if promotion and collapsed and (mapping or seen)
            and (slot==10 or slot==82 or slot==94 or slot==106 or slot==118) then
            reads.emptyMain=reads.emptyMain+1
        end
        if seen then
            reads.action=reads.action+1
            if candidate then assert(not seen[slot],"slot sampled twice within one visual pass") end
            seen[slot]=true
        end
        return hasAction(slot)
    end
    bars.State.GetCurrentPage=function()
        if seen then reads.page=reads.page+1 end
        return getPage()
    end
    return model,reads,overlay,idle
end

local function Cross(model,entering)
    model.cursor="spell"
    model.hover=entering
    model.reset()
    model.B.Layout.OnDragHover()
    model.drain()
end

for _,scene in ipairs({
    {"sparse-top",false,false,1},
    {"sparse-shapeshift",true,false,7},
    {"full-top",false,true,2},
    {"full-possession",true,true,11},
}) do
    local old,a,oldOverlay,oldIdle=Configure(not prior,scene[2],scene[3],scene[4])
    local new,b,newOverlay,newIdle=Configure(true,scene[2],scene[3],scene[4])
    for i=1,8 do
        Cross(old,i%2==1)
        Cross(new,i%2==1)
        assert(old.signature()==new.signature(),"face layout, action mappings and promotion agree")
        for _,key in ipairs({"commit","dependents","envelope","mappingWrites","native.point","native.show"}) do
            assert(old.counts()[key]==new.counts()[key],"same downstream work: "..key)
        end
        assert(old.applies==new.applies,"same secure mapping application")
    end
    assert(a.calls==8 and b.calls==8 and b.page==4,"one current-page read per expanding visual pass")
    assert(b.expandedPack==0,"expanded strip skips collapsed packing checks")
    if promotion then
        assert(b.emptyMain==0,"both passes skip main probes for the empty mini pair")
        if prior then
            assert(b.action<a.action and b.mapping<a.mapping and b.page==a.page and a.emptyMain==40,
                "both collapse passes omit unused occupancy reads without changing active-page sampling")
        end
    elseif prior then
        assert(b.action<a.action and b.page<a.page,"visual slot and page reads fall")
    end
    print(("STRIP_SLOT_READS %s crossings=8 action=%d/%d page=%d/%d")
        :format(scene[1],a.action,b.action,a.page,b.page))
    if promotion then
        print(("STRIP_PROMOTION_READS %s mapping=%d/%d emptyMain=%d/%d")
            :format(scene[1],a.mapping,b.mapping,a.emptyMain,b.emptyMain))
    end

    for _,state in ipairs({{old,oldOverlay,oldIdle},{new,newOverlay,newIdle}}) do
        local model,overlay,idle=state[1],state[2],state[3]
        local bars=model.B
        -- ForceApply runs before layout. A synchronous page change must be
        -- visible to the new pass even when mappings have just been stamped.
        local force=bars.State.ForceApply
        bars.State.ForceApply=function(...)
            model.page=3
            model.occupied[25]=325
            return force(...)
        end
        Cross(model,true)
        assert(model.page==3 and bars.Layout.HasContentOnMain(1))
        bars.State.ForceApply=force
        model.occupied[25]=nil
        overlay[bars.State.GetSecondarySlot(14)]=nil
        idle[bars.State.GetTertiarySlot(15)]=nil
        bars.Layout.Request("slot")
        model.drain()
        assert(not bars.Layout.HasContentOnMain(1),"next pass and direct reads see slot changes")
        assert(bars.hosts[1].sec.widget._fluxParked,"missing current-page action removes its drop placeholder")
    end
    assert(old.signature()==new.signature(),"slot and overlay changes still repack with correct points and attributes")
    if promotion then
        for _,model in ipairs({old,new}) do
            local bars=model.B
            local slot=bars.State.GetSecondarySlot(10)
            model.occupied[slot]=201
            model.occupied[82]=202
            Cross(model,false)
            assert(not bars.Layout.GetPromotedMode(10) and not bars.hosts[10].main._fluxPromoted,
                "a newly occupied mini stays in place while another form owns the main")
            model.occupied[82]=nil
            bars.Layout.Request("slot")
            model.drain()
            assert(bars.Layout.GetPromotedMode(10)=="sec" and bars.hosts[10].main._fluxPromoted==1,
                "removing the other form's action promotes the mini")
        end
        assert(old.signature()==new.signature(),"promotion geometry and action routes agree")
    end
    local reads=b.action
    new.combat=true
    Cross(new,false)
    assert(b.action==reads and not new.counts()["native.point"],"lockdown defers sampling and placement")
end
print("Strip sampling replay passes sparse/full bars, current pages, overlays, synchronous page changes and combat deferral.")
