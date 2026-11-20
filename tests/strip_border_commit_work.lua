-- Replay real held-cursor layout and real regional paint against the archived
-- sources when supplied. Counts refer to modeled widget calls, not native FPS.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local source=file:read("*a")
    file:close()
    return (source:gsub("\r\n","\n"))
end

local resizeOnly=arg[1]=="--shell-resize"
local levelPrior=arg[1]=="--level-samples" and arg[2]
local prior=not resizeOnly and not levelPrior and arg[1]
local resizePrior=resizeOnly and arg[2]
local bars=Read("tests/bars_strip_layout_work.lua")
bars=bars:sub(1,assert(bars:find("local candidate=true;local checks=0",1,true))-1)
local source=prior or resizePrior
local args=source and {source.."/Bars-Layout.lua",source.."/Bars-Strip.lua"} or {}
local makeLayout=assert(load(bars.."\nreturn fixture","@strip-shell-fixture","t",setmetatable({arg=args},{__index=_G})))()

local function ResizeShell(candidate, bottom, editSlot)
    local model=makeLayout(candidate)
    model.bottom=bottom
    model.B.Layout.Invalidate()
    model.B.Layout.Apply()
    local strip=model.B.Strip
    local writes={anchors=0,sizes=0,scale=0,innerAnchors=0}
    for _,frame in ipairs({strip.frame,strip.inner,strip.sensing}) do
        local function Count(method,field)
            local native=frame[method]
            frame[method]=function(self,...)
                writes[field]=writes[field]+1
                return native(self,...)
            end
        end
        local anchorField=frame==strip.inner and "innerAnchors" or "anchors"
        Count("ClearAllPoints",anchorField)
        Count("SetPoint",anchorField)
        Count("SetSize","sizes")
        Count("SetScale","scale")
    end
    local signatures={}
    local collapsedWidth=strip.frame.width
    for _,kind in ipairs({"spell","item","macro"}) do
        for _,inside in ipairs({true,false}) do
            model.reset()
            if editSlot then
                model.occupied[15]=inside and 115 or nil
                model.emit("ACTIONBAR_SLOT_CHANGED",15)
            else
                model.cursor=kind
                model.hover=inside
                model.B.Layout.OnDragHover()
            end
            model.drain()
            assert(inside and strip.frame.width>collapsedWidth or not inside and strip.frame.width==collapsedWidth,
                "the real strip shell grows and shrinks")
            assert(model.counts().commit==1,"each real size change commits the border once")
            signatures[#signatures+1]=model.signature()
        end
    end
    return writes,table.concat(signatures,"\n")
end

if not prior then
    for _,bottom in ipairs({false,true}) do
        for _,editSlot in ipairs({false,true}) do
            local current,signature=ResizeShell(true,bottom,editSlot)
            assert(current.anchors==0 and current.sizes==18 and current.innerAnchors==(editSlot and 0 or 12) and current.scale==0,
                "only changed sizes and anchors are written")
            if resizePrior then
                local previous,oldSignature=ResizeShell(false,bottom,editSlot)
                assert(oldSignature==signature,"all face geometry and action routes match the archived source")
                assert(previous.anchors==24 and previous.sizes==18 and previous.innerAnchors==12 and previous.scale==6,
                    "archived resize rewrites the unchanged exterior anchors and inner scale")
                print(("STRIP_RESIZE change=%s bottom=%s exteriorAnchors=%d/%d innerAnchors=%d/%d innerScale=%d/%d sizes=%d/%d")
                    :format(editSlot and "slot" or "hover",tostring(bottom),previous.anchors,current.anchors,
                        previous.innerAnchors,current.innerAnchors,previous.scale,current.scale,previous.sizes,current.sizes))
            end
        end
    end
    if resizeOnly then return end
end

local function Layout(candidate)
    local model=makeLayout(candidate)
    local shell,sensing=model.B.Strip.frame,model.B.Strip.sensing
    for slot=15,19 do model.occupied[slot]=100+slot end
    model.B.Layout.Request("slot")
    model.drain()
    local writes=0
    for _,frame in ipairs({shell,sensing}) do
        for _,key in ipairs({"ClearAllPoints","SetPoint","SetSize"}) do
            local method=frame[key]
            frame[key]=function(self,...) writes=writes+1;return method(self,...) end
        end
    end
    model.cursor="spell"
    return model,function()return writes end
end
do
    local old,a=Layout(not prior)
    local new,b=Layout(true)
    for i=1,6 do
        for _,model in ipairs({old,new}) do
            model.hover=i%2==1
            model.B.Layout.OnDragHover()
            model.drain()
        end
        assert(old.signature()==new.signature(),"held-spell faces, input mapping, shell and sensing agree")
    end
    assert(b()==0,"constant strip envelope keeps both border and sensing anchors")
    if prior then assert(a()==36,"archived layout stamps six exterior setters each crossing") end
    print(("STRIP_SHELL crossings=6 exteriorWrites=%d/%d"):format(a(),b()))
end

local renderer=Read("tests/border_locality.lua")
renderer=renderer:sub(1,assert(renderer:find("if arg[1]=='--work' then",1,true))-1)
renderer=renderer:gsub("local corePath='Core/BorderJunctions.lua'","local corePath=...",1)
renderer=renderer:gsub("parents%[i%]=parent;",
    "parents[i]=parent;if g.name=='strip' then e.FluxActionStrip=parent end;",1)
local factory=assert(load(renderer.."\nreturn {model=model,scenes=scenes,box=box,compare=compare,fields=fields}",
    "@strip-regional-fixture","t",_G))
local borderPrior=prior or levelPrior
local before=factory(borderPrior and borderPrior.."/Core-BorderJunctions.lua" or "Core/BorderJunctions.lua")
local after=factory("Core/BorderJunctions.lua")

local function Make(fixture,style,scale)
    local scene=fixture.scenes(style)[3].groups
    scene[#scene+1]=fixture.box(920,-85,120,85,"combat",nil,11)
    scene[#scene+1]=fixture.box(1040,-85,70,85,"trinket",nil,18)
    scene[#scene+1]=fixture.box(-280,-85,100,85,"info",nil,5)
    local model=fixture.model(scene,style,scale)
    local native=getmetatable(model.e.UIParent).__index
    local counts={reads=0,writes=0,sourceLevels=0}
    local sourceParents={}
    for _,parent in ipairs(model.parents) do sourceParents[parent]=true end
    for _,name in ipairs({"GetFrameStrata","GetFrameLevel","SetFrameStrata","SetFrameLevel"}) do
        local method=native[name]
        local count=name:sub(1,3)=="Get" and "reads" or "writes"
        native[name]=function(self,...)
            if self.target then counts[count]=counts[count]+1 end
            if name=="GetFrameLevel" and sourceParents[self] then counts.sourceLevels=counts.sourceLevels+1 end
            return method(self,...)
        end
    end
    local function LayerSignature()
        local seen,layers={},{}
        for _,texture in ipairs(model.objects) do
            if texture.decorative and texture:IsVisible() and texture:GetAlpha()>0 then
                local canvas=texture:GetParent()
                if canvas.target and not seen[canvas] then
                    seen[canvas]=true
                    -- Include the stable scene owner, including the raised strip seam.
                    for index,owner in ipairs(model.parents) do
                        if owner==canvas.target then
                            layers[#layers+1]=table.concat({index,canvas:GetFrameStrata(),canvas:GetFrameLevel()},":")
                        end
                    end
                end
            end
        end
        table.sort(layers)
        return table.concat(layers,"/")
    end
    return model,counts,LayerSignature
end
local function Move(model,i)
    local expanded=i%2==1
    local offset=(expanded and 8 or -8)/model.parents[4]:GetEffectiveScale()
    for _,index in ipairs({4,7,8,9}) do
        for _,texture in ipairs(model.sources[index]) do
            local axis=index==4 and 2 or 1
            texture.rect[axis]=texture.rect[axis]+offset
            model.j:Invalidate(nil,texture)
        end
    end
    -- Test a real participant level change too, then return to a known pose.
    if i==7 or i==8 then
        model.parents[5]:SetFrameLevel(i==7 and 29 or 0)
        model.j:Invalidate(nil,model.parents[5])
    end
    model.j:CommitLayout(expanded)
end
for _,style in ipairs({1,2}) do for _,scale in ipairs({.75,1,1.25}) do
    local old,a,oldLayers=Make(before,style,scale)
    local new,b,newLayers=Make(after,style,scale)
    local oldTotal,newTotal={0,0,0},{0,0,0}
    for i=1,8 do
        a.reads,a.writes,b.reads,b.writes=0,0,0,0
        a.sourceLevels,b.sourceLevels=0,0
        Move(old,i)
        Move(new,i)
        if i<=6 then
            oldTotal[1],oldTotal[2]=oldTotal[1]+a.reads,oldTotal[2]+a.writes
            newTotal[1],newTotal[2]=newTotal[1]+b.reads,newTotal[2]+b.writes
            oldTotal[3],newTotal[3]=oldTotal[3]+a.sourceLevels,newTotal[3]+b.sourceLevels
        end
        local oldLayer,newLayer=oldLayers(),newLayers()
        assert(#oldLayer>0 and oldLayer==newLayer,"final regional draw layers agree: "..oldLayer.." / "..newLayer)
        after.compare(new,old,{{0,0},{320,0},{326,0},{920,-85},{1040,-85},{-180,-85}},scale)
    end
    assert(new.j.stats.stripPlanHits and new.j.stats.stripPlanHits>=4,"exercise the prepared drag path")
    if prior then assert(newTotal[1]<oldTotal[1] and newTotal[2]<=oldTotal[2],"draw-layer calls fall") end
    if levelPrior then assert(newTotal[3]<oldTotal[3],"prepared strip level checks reuse the commit sample") end
    print(("STRIP_LAYER style=%d scale=%.2f reads=%d/%d writes=%d/%d"):format(style,scale,oldTotal[1],newTotal[1],oldTotal[2],newTotal[2]))
    if levelPrior then
        print(("STRIP_LEVEL_SAMPLES style=%d scale=%.2f reads=%d/%d"):format(style,scale,oldTotal[3],newTotal[3]))
    end
end end
print("Strip commit replay passes live levels, canonical texture samples and retained regional ownership.")
