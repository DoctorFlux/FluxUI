-- Run the actual regional renderer with sector-local fixtures. Optionally
-- compare the verified source from a dated before directory.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local source=file:read("*a")
    file:close()
    return (source:gsub("\r\n","\n"))
end
local prior=arg[1]
local compareJunctionReads=arg[2]=="junctions"
local compareListenerIndices=arg[2]=="listener-indices"
local compareFragmentIndices=arg[2]=="fragment-indices"
local text=Read("tests/border_locality.lua")
text=text:sub(1,assert(text:find("if arg[1]=='--work' then",1,true))-1)
text=text:gsub("local corePath='Core/BorderJunctions.lua'","local corePath=...",1)
text=text:gsub("parents%[i%]=parent;","parents[i]=parent;if g.name=='strip' then e.FluxActionStrip=parent end;",1)
local make=assert(load(text.."\nreturn {model=model,scenes=scenes,box=box,compare=compare}","@fragment-render-fixture","t",_G))
local old=make(prior and prior.."/Core-BorderJunctions.lua" or "Core/BorderJunctions.lua")
local new=make("Core/BorderJunctions.lua")

local function Fixture(renderer,style,strip)
    local groups=renderer.scenes(style)[strip and 3 or 1].groups
    if strip then
        groups[#groups+1]=renderer.box(920,-85,120,85,"combat",nil,5)
        groups[#groups+1]=renderer.box(1040,-85,70,85,"trinket",nil,5)
        groups[#groups+1]=renderer.box(-280,-85,100,85,"info",nil,5)
    end
    local model=renderer.model(groups,style,1)
    local count={parents=0,layers=0,alpha=0,commits=0,pushes=0,pops=0}
    local active
    local native=getmetatable(model.e.UIParent).__index
    local getParent,getAlpha=native.GetParent,native.GetAlpha
    local function Source(texture) return texture.objectType=="Texture" and not texture.decorative end
    function native:GetParent()
        if active and Source(self) then count.parents=count.parents+1 end
        return getParent(self)
    end
    function native:GetDrawLayer()
        if active and Source(self) then count.layers=count.layers+1 end
        return self.layer or "ARTWORK",self.sublevel or 0
    end
    function native:GetAlpha()
        if active and Source(self) then count.alpha=count.alpha+1 end
        return getAlpha(self)
    end
    local rendererState=model.e.spatial.spatial
    if compareFragmentIndices then
        local push,pop=rendererState.Push,rendererState.Pop
        function rendererState.Push(...)
            count.pushes=count.pushes+1
            return push(...)
        end
        function rendererState.Pop(list,field,index)
            if list and list[field[index]]==field then count.pops=count.pops+1 end
            return pop(list,field,index)
        end
    end
    local commit=rendererState.Commit
    function rendererState.Commit(...)
        active=true
        count.commits=count.commits+1
        commit(...)
        active=false
    end
    return model,count
end

local function Move(model,strip,dx,expanded)
    if strip then
        for _,i in ipairs({2,4,5,6,8}) do
            local region=model.sources[4][i]
            local axis=(i==5 or i==6) and 3 or 1
            region.rect[axis]=region.rect[axis]+dx
            model.j:Invalidate(nil,region)
        end
        for _,peer in ipairs({7,8}) do
            for _,region in ipairs(model.sources[peer]) do
                region.rect[1]=region.rect[1]+dx
                model.j:Invalidate(nil,region)
            end
        end
        model.j:CommitLayout(expanded or false)
    else
        for i=7,11 do
            local region=model.sources[i][1]
            region.rect[1]=region.rect[1]+dx
            model.j:Invalidate(nil,region)
        end
        model.j:CommitLayout()
    end
end

local function ListenerIndices(model)
    local _,colors,visibility,sprites=model.e.spatial.inspect()
    return {colors,sprites,visibility}
end

local function RecordListenerIndices(model,counts)
    local before={}
    for i,index in ipairs(ListenerIndices(model)) do
        before[i]={}
        for source,bucket in pairs(index) do before[i][source]=bucket end
    end
    return function()
        for i,index in ipairs(ListenerIndices(model)) do
            for source,bucket in pairs(index) do
                local old=before[i][source]
                if old and not rawequal(old,bucket) then counts[i]=counts[i]+1 end
            end
        end
    end
end

for _,style in ipairs({1,2}) do for _,scene in ipairs({"strip-width","held-crossing","local-join"}) do
    local strip=scene~="local-join"
    local crossing=scene=="held-crossing"
    local a,x=Fixture(old,style,strip)
    local b,y=Fixture(new,style,strip)
    local points=strip and {{-180,-85},{0,0},{326,0},{930,0},{1050,-85}} or {{90,0},{630,0},{645,0},{900,0},{1440,0}}
    local width=0
    local oldBuckets,newBuckets={0,0,0},{0,0,0}
    for i=1,8 do
        local expanded=i%2==1
        local nextWidth=expanded and 6 or 11
        local oldIndex=RecordListenerIndices(a,oldBuckets)
        local newIndex=RecordListenerIndices(b,newBuckets)
        Move(a,strip,nextWidth-width,crossing and expanded)
        Move(b,strip,nextWidth-width,crossing and expanded)
        oldIndex()
        newIndex()
        width=nextWidth
        new.compare(b,a,points,1)
    end
    assert(x.commits==8 and y.commits==8,"identical synchronous regional commits")
    if strip then assert(b.j.stats.stripPlanHits==6,"covers warm and cold strip preparation") end
    if prior and not compareListenerIndices and not compareFragmentIndices then
        assert(y.parents<x.parents,"regional commits read fewer source parents")
        if compareJunctionReads then
            assert(y.layers==x.layers and y.alpha==x.alpha,"junction draw retains layer and opacity reads")
        else
            assert(y.layers<x.layers and y.alpha<x.alpha,"fragment sharing reduces the other source getter families")
        end
    end
    assert(newBuckets[1]==0 and newBuckets[2]==0 and newBuckets[3]==0,
        "sources still observed after the same commit retain their listener index buckets")
    if compareListenerIndices then
        assert(oldBuckets[1]>0 and oldBuckets[2]>0 and oldBuckets[3]>0,
            "archived renderer replaces all three index families")
        print(("LISTENER_INDEX_WORK|%d|%s|%d|%d|%d|%d|%d|%d"):format(style,scene,
            oldBuckets[1],newBuckets[1],oldBuckets[2],newBuckets[2],oldBuckets[3],newBuckets[3]))
    end
    if compareFragmentIndices then
        assert(x.pushes>y.pushes and x.pops>y.pops,"regional redraw retains live source pool membership")
        assert(x.pushes-x.pops==y.pushes-y.pops,"redraw retains the same net source membership")
        print(("FRAGMENT_INDEX_WORK|%d|%s|%d|%d|%d|%d"):format(style,scene,
            x.pushes,y.pushes,x.pops,y.pops))
    end
    print(("FRAGMENT_READS style=%d scene=%s commits=8 parents=%d/%d layers=%d/%d alpha=%d/%d")
        :format(style,scene,x.parents,y.parents,x.layers,y.layers,x.alpha,y.alpha))

    -- The memo belongs to the active commit. A source changing layer, public
    -- opacity or color during another layout still uses those live values.
    local index=strip and 4 or 1
    for _,m in ipairs({a,b}) do
        local t=m.sources[index][5] or m.sources[index][1]
        t:SetDrawLayer("OVERLAY",2)
        t:SetVertexColor(.15,.4,.9,.72)
        m.j:Invalidate(nil,t)
        Move(m,strip,-5)
        local clipped=m.e.spatial.inspect()
        local matched=false
        for _,field in ipairs(clipped[t].pool) do
            if field:IsShown() and field.layer=="OVERLAY" and field.sublevel==2 then matched=true;break end
        end
        assert(matched,"new source layer applies to its clipped artwork")
    end
    new.compare(b,a,points,1)
    for _,m in ipairs({a,b}) do
        local t=m.sources[strip and 7 or 8][1]
        t:Hide()
    end
    new.compare(b,a,points,1)
end end
print("Regional fragment reads preserve sampled joins, live layer and paint, and tile listener ownership.")
