-- Run actual planning and drawing on cold roster and held-cursor layouts,
-- plus long overlapping borders with visibility backups.
local f=assert(io.open("tests/regional_layout_index.lua","rb"))
local text=f:read("*a"):gsub("\r\n","\n")
f:close()
text=text:sub(1,assert(text:find('local core="Core/BorderJunctions.lua"',1,true))-1)
local Renderer,Scene,Change=assert(load(text.."\nreturn Renderer,Scene,Change","@regional-cuts-fixture","t",_G))()
local measureIntervals=arg[2]=="--parallel-intervals"
local measureClip=arg[2]=="--fallback-clip"
local core=(measureIntervals or measureClip) and assert(arg[3]) or "Core/BorderJunctions.lua"
local prior=arg[1]
local before=prior or core

local function Track(j)
    local work={calls=0,arrays=0}
    local subtract=j.Subtract
    function j:Subtract(rectangles,cut)
        local result=subtract(self,rectangles,cut)
        work.calls=work.calls+1
        if result~=rectangles then work.arrays=work.arrays+1 end
        return result
    end
    return work
end

local function Measure(a,b,style,name,change,compare)
    local x,y=Track(a.j),Track(b.j)
    local oldWalks,newWalks=a.j._intervalWalks or 0,b.j._intervalWalks or 0
    local oldSorts,newSorts=a.j._intervalSorts or 0,b.j._intervalSorts or 0
    local oldCaps,newCaps=a.j._intervalCapVisits or 0,b.j._intervalCapVisits or 0
    local oldGuards,newGuards=a.j._fallbackGuardCount or 0,b.j._fallbackGuardCount or 0
    for step=1,2 do
        change(a,step)
        change(b,step)
        compare(b,a)
    end
    if measureIntervals then
        assert(y.calls==x.calls and y.arrays==x.arrays,"interval shortcut keeps exact rectangle subtraction work")
        oldWalks,newWalks=(a.j._intervalWalks or 0)-oldWalks,(b.j._intervalWalks or 0)-newWalks
        oldSorts,newSorts=(a.j._intervalSorts or 0)-oldSorts,(b.j._intervalSorts or 0)-newSorts
        oldCaps,newCaps=(a.j._intervalCapVisits or 0)-oldCaps,(b.j._intervalCapVisits or 0)-newCaps
        assert(newWalks<=oldWalks and newSorts<=oldSorts,"stop rebuilding unpartitioned intervals")
        print(("BORDER_INTERVALS|%d|%s|%d|%d|%d|%d|%d|%d"):format(
            style,name,oldWalks,newWalks,oldSorts,newSorts,oldCaps,newCaps))
    elseif measureClip then
        assert(y.calls==x.calls and y.arrays==x.arrays,"candidate preserves the rectangle subtraction sequence")
        oldGuards,newGuards=(a.j._fallbackGuardCount or 0)-oldGuards,(b.j._fallbackGuardCount or 0)-newGuards
        assert(newGuards<=oldGuards,"skip unused fallback fingerprints")
        print(("REGIONAL_FALLBACK_CLIP|%d|%s|%d|%d"):format(style,name,oldGuards,newGuards))
    elseif prior then assert(y.calls<=x.calls and y.arrays<x.arrays,"matching cuts use less work") end
    print(("BORDER_CUTS style=%d case=%s passes=2 calls=%d/%d arrays=%d/%d")
        :format(style,name,x.calls,y.calls,x.arrays,y.arrays))
end

local function RosterScene(renderer,style)
    local model=renderer.model
    renderer.model=function(groups,...)
        local first=#groups+1
        for i=1,4 do
            local x,y=130+(i-1)*115,380
            local unit="raid"..i
            groups[#groups+1]={name="resource divider",unit=unit,level=5,
                parts={{"Top",{x+1,y+17,81,17}}}}
            groups[#groups+1]={name="resource outline",unit=unit,level=6,
                parts={{"Top",{x+2,y+17,79,17}}}}
            groups[#groups+1]={name="portrait divider",unit=unit,level=6,
                parts={{"Left",{x+18,y+7,16,49}}}}
        end
        local m=model(groups,...)
        m.internalFirst=first
        return m
    end
    local m=Scene(renderer,style)
    renderer.model=model
    return m
end

local function MoveRoster(m,step)
    local delta=step==1 and 17 or -17
    local function Move(index)
        for _,t in ipairs(m.sources[index]) do
            t.rect[1]=t.rect[1]+delta
            m.j:Invalidate(nil,t)
        end
    end
    for i=10,13 do Move(i) end
    for i=m.internalFirst,#m.sources do Move(i) end
    m.j:CommitLayout()
end

for _,style in ipairs({1,2}) do
    local a,b=Renderer(before),Renderer(core)
    for _,name in ipairs({"hover","roster"}) do
        local scene=name=="hover" and Scene or RosterScene
        local change=name=="hover" and function(m,step) Change(m,"hover",step) end or MoveRoster
        local points=name=="hover" and {{0,0},{326,0},{920,0},{1040,-85},{-180,-85}}
            or {{130,380},{147,380},{157,406},{174,406},{272,406},{289,406}}
        Measure(scene(a,style),scene(b,style),style,name,change,
            function(current,old)
                assert(current.j.stats.localMode and old.j.stats.localMode)
                b.compare(current,old,points,1)
            end)
    end
end

local function Overlap(path,style)
    local env=setmetatable({arg={path,"--export"}},{__index=_G})
    env._G=env
    local build=assert(loadfile("tests/border_fallback_plan_cache.lua","t",env))()
    return build(true,style,56,true)
end

for _,style in ipairs({1,2}) do
    local a,b=Overlap(before,style),Overlap(core,style)
    Measure(a,b,style,"parallel-edges",function(m,step)
        if step==2 then
            local divider=m.dividers[7]
            divider.rect[1]=divider.rect[1]+5
            m.j:Invalidate(nil,divider)
        end
        m.flush()
    end,function(current,old)
        assert(current.drawing()==old.drawing(),"exact fallback and foreground drawing agree")
        assert(not current.j.stats.fallback and not old.j.stats.fallback)
    end)
    a.textures[2]:Hide()
    b.textures[2]:Hide()
    a.flush()
    b.flush()
    assert(a.drawing()==b.drawing(),"fallback visibility survives removing the keeper")

    local first,last={0,0,3,4},{14,0,19,4}
    local boxes={first,{5,0,11,4},last}
    local distant={3,0,5,4}
    assert(b.j:Subtract(boxes,distant)==boxes,"touching boundaries need no replacement")
    local cut={7,1,9,3}
    local saved,current=a.j:Subtract(boxes,cut),b.j:Subtract(boxes,cut)
    assert(#current==6 and #boxes==3 and current[1]==first and current[6]==last)
    for i,r in ipairs(saved) do for j,v in ipairs(r) do assert(v==current[i][j]) end end
end
print("Cold border cuts preserve fragment order, sampled seams, and visibility backups.")
