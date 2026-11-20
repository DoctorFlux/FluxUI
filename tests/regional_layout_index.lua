-- Compare the real layout snapshot and region queries on a populated HUD.
-- An optional path supplies the archived renderer for matched work counts.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local text=file:read("*a")
    file:close()
    return (text:gsub("\r\n","\n"))
end

local fixture=Read("tests/border_locality.lua")
fixture=fixture:sub(1,assert(fixture:find("if arg[1]=='--work' then",1,true))-1)
fixture=fixture:gsub("local corePath='Core/BorderJunctions.lua'","local corePath,instrument=...",1)
fixture=fixture:gsub("read%(corePath%)","instrument(read(corePath))",1)
fixture=fixture:gsub("parents%[i%]=parent;",
    "parents[i]=parent;if g.name=='strip' then e.FluxActionStrip=parent end;",1)

local prior=arg[1]
local function Renderer(path)
    local counts={sorts=0,stamps=0,probes=0}
    local env=setmetatable({CountLayoutSort=function(n)
        counts.sorts=counts.sorts+1
        counts.stamps=counts.stamps+n
    end,CountPieceProbe=function() counts.probes=counts.probes+1 end},{__index=_G})
    env._G=env
    local function Instrument(text)
        local n,probes
        text,n=text:gsub("table%.sort%(signature%)","CountLayoutSort(#signature);table.sort(signature)",1)
        if n==0 then
            text,n=text:gsub("if #stamps>1 then table%.sort%(stamps%)",
                "if #stamps>1 then CountLayoutSort(#stamps);table.sort(stamps)",1)
        end
        text,probes=text:gsub("if Spatial.VisitTiles%(index,item.rect,Spatial.TouchesHalo,padding,nil,padding%) then",
            "CountPieceProbe();if Spatial.VisitTiles(index,item.rect,Spatial.TouchesHalo,padding,nil,padding) then",1)
        assert(n==1 and probes==1,"instrument both actual layout phases")
        return text
    end
    local maker=assert(load(fixture.."\nreturn {model=model,scenes=scenes,box=box,compare=compare}",
        "@regional-layout-fixture","t",env))
    return maker(path,Instrument),counts
end

local function Scene(renderer,style)
    local g=renderer.scenes(style)[3].groups
    g[#g+1]=renderer.box(920,-85,120,85,"combat",nil,5)
    g[#g+1]=renderer.box(1040,-85,70,85,"trinket",nil,5)
    g[#g+1]=renderer.box(-280,-85,100,85,"info",nil,5)
    for i=1,40 do
        local x=130+((i-1)%8)*115
        local y=380+math.floor((i-1)/8)*100
        g[#g+1]=renderer.box(x,y,83,68,"raid"..i,"raid"..i,6)
    end
    return renderer.model(g,style,1)
end

local function Change(model,trigger,step)
    local first=step%2==1
    if trigger=="hover" then
        local delta=first and 8 or -8
        for _,index in ipairs({4,7,8,9}) do
            for _,texture in ipairs(model.sources[index]) do
                local axis=index==4 and 2 or 1
                texture.rect[axis]=texture.rect[axis]+delta
                model.j:Invalidate(nil,texture)
            end
        end
        model.j:CommitLayout(first)
    else
        -- A roster layout change repositions reused unit frames.
        local delta=first and 17 or -17
        for i=10,13 do
            for _,texture in ipairs(model.sources[i]) do
                texture.rect[1]=texture.rect[1]+delta
                model.j:Invalidate(nil,texture)
            end
        end
        model.j:CommitLayout()
    end
end

local core="Core/BorderJunctions.lua"
local cases={hover={{0,0},{326,0},{920,0},{1040,-85},{-180,-85},{130,380}},
    roster={{130,380},{147,380},{245,380},{262,380},{360,380},{0,0}}}
for _,style in ipairs({1,2}) do
    for _,trigger in ipairs({"hover","roster"}) do
        local a,x=Renderer(prior or core)
        local b,y=Renderer(core)
        local old,new=Scene(a,style),Scene(b,style)
        x.sorts,x.stamps,x.probes=0,0,0
        y.sorts,y.stamps,y.probes=0,0,0
        local retained={}
        for key,cell in pairs(new.cells) do
            if cell.enabled then retained[key]={cell=cell,epoch=cell.epoch} end
        end
        local sizes=0
        for step=1,6 do
            Change(old,trigger,step)
            Change(new,trigger,step)
            b.compare(new,old,cases[trigger],1)
            assert(new.j.stats.localMode and not new.j.stats.fallback)
            sizes=sizes+new.j.stats.localUpdated
        end
        local same=0
        for key,value in pairs(retained) do
            if new.cells[key]==value.cell and value.cell.epoch==value.epoch then same=same+1 end
        end
        assert(same>0 and sizes>0,"changed and retained cells both exercised")
        assert(new.j.stats.solves==old.j.stats.solves)
        if trigger=="hover" then assert(new.j.stats.stripPlanHits==4,"compare cold and prepared hover geometry") end
        if prior then
            assert(y.stamps<x.stamps/4,"reuse unaffected layout stamps")
            assert(y.probes<x.probes/2,"do not visit distant groups' individual edges")
        end
        print(("REGIONAL_LAYOUT style=%d trigger=%s stamps=%d/%d probes=%d/%d retained=%d updates=%d")
            :format(style,trigger,x.stamps,y.stamps,x.probes,y.probes,same,sizes))
    end
end
print("Regional layout snapshots preserve sampled seams, prepared hover poses and retained roster regions.")
