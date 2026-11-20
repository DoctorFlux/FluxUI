-- Complete unit module, public cell geometry, and shared-edge topology. The
-- separate visual suite resolves actual texture anchors and draw ownership.
local file=assert(io.open(arg[1] or "RaidFrame/FluxRaidUnit.lua","rb"))
local source=file:read("*a"):gsub("\r\n","\n");file:close()
local checks=0
local function check(ok,message)checks=checks+1;assert(ok,message)end
local function scenario(body,native)
    local e=setmetatable({},{__index=_G});e._G=e
    local secret={}
    local comparisons,visibilityReads,sorts=0,0,0
    local rectReads,edgeReads=0,0
    e.math=setmetatable({abs=function(n)comparisons=comparisons+1;return math.abs(n)end},{__index=math})
    e.table=setmetatable({sort=function(...)sorts=sorts+1;return table.sort(...)end},{__index=table})
    e.FluxRaidCompat={IsSecret=function(value)return value==secret end}
    e.FluxRaidState={frameArray={}}
    local drivers={}
    e.CreateFrame=function()
        local frame={scripts={},writes=0}
        function frame:SetScript(key,value)self.scripts[key]=value;self.writes=self.writes+1 end
        drivers[#drivers+1]=frame;return frame
    end
    e.FluxRaidVisuals={SetJoinedEdges=function(frame,edges)frame.edges=edges end,CELL_JOIN_OVERLAP=native and 1 or nil}
    local width,height,step=native and 98 or 72,native and 44 or 43,native and 43 or 39
    assert(load(body or source,"@connected unit module","t",e))("_FluxUI",{Flux={}})
    local function cell(x,y,height)
        local f={unit="party1",unitExists=true,visible=true,x=x,y=y,height=height or (native and 44 or 43)}
        function f:IsVisible()visibilityReads=visibilityReads+1;return self.visible end
        function f:GetRect()
            rectReads=rectReads+1
            return self.x,self.y-self.height,width,self.height
        end
        function f:GetLeft()edgeReads=edgeReads+1;return self.x end
        function f:GetRight()edgeReads=edgeReads+1;return self.x+width end
        function f:GetTop()edgeReads=edgeReads+1;return self.y end
        function f:GetBottom()edgeReads=edgeReads+1;return self.y-self.height end
        function f:SetPoint()error("connected border refresh mutated a protected cell")end
        e.FluxRaidState.frameArray[f]=f;return f
    end
    local a,b,c,d=cell(0,200),cell(width,200),cell(0,200-step),cell(width,200-step)
    e.FluxRaid_RefreshJoinedBorders()
    check(a.edges.bottom==false and a.edges.right==false,"upper left shares both internal seams")
    check(b.edges.bottom==false and b.edges.right==true,"upper right closes only exterior right")
    check(c.edges.bottom==true and c.edges.right==false,"lower left closes only exterior bottom")
    check(d.edges.bottom==true and d.edges.right==true,"lower right closes both exterior edges")
    check(a.edges.exteriorTop and a.edges.exteriorLeft and b.edges.exteriorTop and not b.edges.exteriorLeft,
        "outer top corners follow actual neighbors")
    check(not c.edges.exteriorTop and c.edges.exteriorLeft and not d.edges.exteriorTop and not d.edges.exteriorLeft,
        "interior joins cannot draw repeated rounded corner caps")
    local edges=0
    for _,f in ipairs({a,b,c,d})do edges=edges+2+(f.edges.bottom and 1 or 0)+(f.edges.right and 1 or 0)end
    check(edges==12,"two-by-two grid draws twelve unique segments, not sixteen doubled segments")
    c.visible=false;e.FluxRaid_RefreshJoinedBorders()
    check(a.edges.bottom==true,"leaving roster closes newly exposed bottom immediately")
    c.visible=true;d.unitExists=false;e.FluxRaid_RefreshJoinedBorders()
    check(c.edges.right==true and b.edges.bottom==true,"retired unit cannot suppress exterior borders")
    d.unitExists=true;b.x=2*width;d.x=2*width;e.FluxRaid_RefreshJoinedBorders()
    check(a.edges.right and c.edges.right,"separate columns retain their exterior borders")
    local mini=cell(0,110,18);e.FluxRaid_RefreshJoinedBorders()
    check(mini.edges.bottom and mini.edges.right,"isolated mini keeps its own outer edges")
    local opaque=cell(300,100)
    function opaque:GetLeft()return secret end
    local ok=pcall(e.FluxRaid_RefreshJoinedBorders)
    check(ok and not opaque.edges,"opaque geometry is never compared or used to erase an edge")
    for i=1,50 do e.FluxRaid_RequestJoinedBorderRefresh()end
    check(#drivers==1 and drivers[1].writes==1,"roster bursts queue one shared topology refresh")
    drivers[1].scripts.OnUpdate(drivers[1])
    check(not drivers[1].scripts.OnUpdate and not e.FluxRaidState.joinedBorderPending,"shared topology work disarms after one frame")
    e.FluxRaidState.frameArray={}
    local raid={}
    for row=0,4 do for col=0,7 do raid[#raid+1]=cell(col*width,200-row*step) end end
    for i=1,45 do
        local dormant=cell(0,0)
        dormant.unit=nil
    end
    comparisons,rectReads,edgeReads,sorts=0,0,0,0
    e.FluxRaid_RefreshJoinedBorders()
    local cold=comparisons
    local coldSorts=sorts
    local coldRects,coldEdges=rectReads,edgeReads
    local middle=raid[10]
    check(not middle.edges.bottom and not middle.edges.right and not middle.edges.exteriorTop
        and not middle.edges.exteriorLeft,"wide raid grid keeps internal seams")
    comparisons,rectReads,edgeReads,sorts=0,0,0,0
    local prepared=middle.edges
    for i=1,20 do middle.unit="raid"..i;e.FluxRaid_RefreshJoinedBorders() end
    if arg[2]~="--measure" then
        check(comparisons==0,"unmoved unit rebindings reuse the current public topology")
        check(middle.edges==prepared,"same geometry retains its prepared edge input")
        check(cold==0 and coldSorts==0,"an aligned grid finds neighbors directly without sorting or tolerance scans")
        check(coldRects==0 and coldEdges==160,"new cells read their exact edges without a rectangle check")
        check(rectReads==800 and edgeReads==0,"retained cells confirm bounds with one public rectangle")
    end
    check(not middle.edges.bottom and not middle.edges.right,"rebound cell keeps the same edges")
    print("RAID_CONNECTED_WORK|"..(native and "native" or "legacy").."|"..cold.."|"..comparisons.."|"..coldSorts)
    local farEdge=raid[40].edges
    local warmRects,warmEdges=rectReads,edgeReads
    comparisons,visibilityReads,rectReads,edgeReads=0,0,0,0
    raid[18].visible=false;e.FluxRaid_RefreshJoinedBorders()
    check(comparisons>0 and middle.edges.bottom,"a real occupancy change recalculates exposed edges")
    local leaveWork,leaveVisibility=comparisons,visibilityReads
    local leaveRects,leaveEdges=rectReads,edgeReads
    comparisons,rectReads,edgeReads=0,0,0
    raid[18].visible=true;e.FluxRaid_RefreshJoinedBorders()
    check(not middle.edges.bottom,"joining restores the original seam")
    local joinWork=comparisons
    local joinRects,joinEdges=rectReads,edgeReads
    comparisons,rectReads,edgeReads=0,0,0
    raid[18].x=raid[18].x+2;e.FluxRaid_RefreshJoinedBorders()
    check(middle.edges.bottom,"movement of the only neighbor exposes the seam")
    local moveWork=comparisons
    local movedRects,movedEdges=rectReads,edgeReads
    raid[18].x=raid[18].x-2;e.FluxRaid_RefreshJoinedBorders()
    if arg[2]~="--measure" then
        check(raid[40].edges==farEdge,"single-cell changes retain distant paint flags")
        check(sorts==0 and math.max(leaveWork,joinWork,moveWork)<=6*#raid,
            "single-cell changes still use bounded incremental comparisons")
        check(leaveVisibility==40,"unbound precreated cells skip native visibility reads")
        check(leaveRects==39 and leaveEdges==0 and joinRects==39 and joinEdges==4,
            "only the entering cell needs new exact edges")
        check(movedRects==40 and movedEdges==4,"only the moved cell needs an exact reread")
    end
    print("RAID_JOIN_DELTA|"..(native and "native" or "legacy").."|"..leaveWork.."|"..joinWork.."|"..moveWork.."|"..leaveVisibility)
    print(("RAID_JOIN_READS|%s|%d/%d|%d/%d|%d/%d|%d/%d|%d/%d"):format(native and "native" or "legacy",
        coldRects,coldEdges,warmRects,warmEdges,leaveRects,leaveEdges,joinRects,joinEdges,movedRects,movedEdges))
    e.FluxRaidVisuals.CELL_JOIN_OVERLAP=native and 4 or 1
    comparisons=0;e.FluxRaid_RefreshJoinedBorders()
    check(middle.edges.exteriorTop,"changed native overlap invalidates the cached layout")

    -- Common fractional origins remain aligned. Distinct fractions, even
    -- if a modulo operation would round them together, keep tolerance checks.
    if arg[2]~="--measure" then
        e.FluxRaidState.frameArray={}
        e.FluxRaidVisuals.CELL_JOIN_OVERLAP=native and 1 or 4
        local first=cell(.25,30.125)
        cell(.25,30.125-step)
        cell(width+.25,30.125)
        comparisons,sorts=0,0
        e.FluxRaid_RefreshJoinedBorders()
        check(comparisons==0 and sorts==0 and not first.edges.right and not first.edges.bottom,
            "a common fractional origin keeps the exact same direct joins")

        local duplicate=cell(.25,30.125-step)
        cell(width*3+.25,30.125)
        sorts=0
        e.FluxRaid_RefreshJoinedBorders()
        check(sorts==2 and not first.edges.bottom,"duplicate top-left origins retain the tolerance path")
        duplicate.visible=false
        e.FluxRaid_RefreshJoinedBorders()
        check(not first.edges.bottom,"removing an exact duplicate leaves the other neighbor connected")

        e.FluxRaidState.frameArray={}
        local corner=cell(0,200)
        cell(width,200,height-1)
        local narrower=cell(0,200-step)
        function narrower:GetRight() return width-1 end
        sorts=0
        e.FluxRaid_RefreshJoinedBorders()
        check(sorts==0 and corner.edges.right and corner.edges.bottom,
            "aligned contacts still require equal row heights and column widths")

        e.FluxRaidState.frameArray={}
        local a=cell(-2e-17,200)
        local b=cell(-1e-17,200)
        function a:GetRight() return -1.5e-17 end
        function b:GetRight() return -0.5e-17 end
        sorts=0
        e.FluxRaid_RefreshJoinedBorders()
        check(sorts==2 and not a.edges.right and not b.edges.right,
            "tiny negative fractions do not bypass tolerance checks")
    end

    -- Two neighbors may qualify while optional cells are appearing or
    -- settling. The shared side must stay closed until the last one leaves.
    e.FluxRaidState.frameArray={}
    e.FluxRaidVisuals.CELL_JOIN_OVERLAP=native and 1 or 4
    local upper=cell(0,200)
    local lower=cell(0,200-step)
    local duplicateLower=cell(.125,200-step)
    local neighbor=cell(width,200)
    local duplicateRight=cell(width,200+.125)
    e.FluxRaid_RefreshJoinedBorders()
    check(not upper.edges.bottom and not upper.edges.right,"either qualifying neighbor closes the seam")
    lower.visible=false;e.FluxRaid_RefreshJoinedBorders()
    neighbor.visible=false;e.FluxRaid_RefreshJoinedBorders()
    check(not upper.edges.bottom and not upper.edges.right,"partial loss leaves remaining neighbor seams connected")
    duplicateLower.visible=false;e.FluxRaid_RefreshJoinedBorders()
    duplicateRight.visible=false;e.FluxRaid_RefreshJoinedBorders()
    check(upper.edges.bottom and upper.edges.right,"last neighbors leaving expose both sides")
    duplicateLower.visible=true;e.FluxRaid_RefreshJoinedBorders()
    duplicateRight.visible=true;e.FluxRaid_RefreshJoinedBorders()
    check(not upper.edges.bottom and not upper.edges.right,"last replacement neighbors restore both sides")
    local paint=e.FluxRaidVisuals.SetJoinedEdges
    e.FluxRaidVisuals.SetJoinedEdges=function()error("simulated paint failure")end
    duplicateLower.visible=false
    check(not pcall(e.FluxRaid_RefreshJoinedBorders),"paint failure reaches the caller")
    e.FluxRaidVisuals.SetJoinedEdges=paint
    e.FluxRaid_RefreshJoinedBorders()
    check(upper.edges.bottom and not upper.edges.right,"redoing paint applies the membership change only once")

    -- Compare every edge with the original all-pairs rule, including cells
    -- whose corners fall either side of a strict fractional tolerance.
    e.FluxRaidState.frameArray={}
    local overlap=native and 1 or 4
    e.FluxRaidVisuals.CELL_JOIN_OVERLAP=overlap
    local samples={}
    for row=1,5 do
        for col=1,8 do
            local dx=({-.51,-.5,-.49,0,.49,.5,.51})[1+(row+col)%7]
            local dy=({-.76,-.75,-.74,0,.74,.75,.76})[1+(2*row+col)%7]
            local h=col%5==1 and height-2 or height
            samples[#samples+1]=cell((col-4)*width+dx,(2-row)*step+dy,h)
        end
    end
    local function matchesReference()
        e.FluxRaid_RefreshJoinedBorders()
        local function present(f) return f.visible and f.unit and f.unitExists end
        for _,f in ipairs(samples) do if present(f) then
            local bottom,right,top,left=true,true,true,true
            for _,g in ipairs(samples) do if g~=f and present(g) then
                if math.abs(f.x-g.x)<0.5 and math.abs((f.x+width)-(g.x+width))<0.5 then
                    if math.abs(f.y-f.height+overlap-g.y)<0.75 then bottom=false end
                    if math.abs(g.y-g.height+overlap-f.y)<0.75 then top=false end
                end
                if math.abs(f.y-g.y)<0.75 and math.abs((f.y-f.height)-(g.y-g.height))<0.75 then
                    if math.abs(f.x+width-g.x)<0.75 then right=false end
                    if math.abs(g.x+width-f.x)<0.75 then left=false end
                end
            end end
            local edges=f.edges
            check(edges.bottom==bottom and edges.right==right and edges.exteriorTop==top and edges.exteriorLeft==left,
                "all-pairs and indexed edge flags match")
        end end
    end
    for i=1,23 do
        local old=samples[1+(i*17)%#samples]
        old.visible=not old.visible
        local moved=samples[1+(i*13)%#samples]
        moved.x=moved.x+(i%2==1 and 0.75 or -0.5)
        matchesReference()
    end
    if arg[2]~="--measure" then
        local invalid=cell(0,100)
        function invalid:GetTop()return 0/0 end
        e.FluxRaid_RefreshJoinedBorders()
        check(not invalid.edges,"non-finite geometry is excluded from sorted contacts")

        e.FluxRaidState.frameArray={}
        local left,right=cell(0,0),cell(width+.75,0)
        e.FluxRaid_RefreshJoinedBorders()
        function left:GetRect() return self.x,self.y-self.height,width+.25,self.height end
        rectReads,edgeReads=0,0
        e.FluxRaid_RefreshJoinedBorders()
        check(edgeReads==4 and left.edges.right,"a mismatching rectangle keeps the native edge at the exact join limit")
        function left:GetRect() return self.x,self.y-self.height,secret,self.height end
        right.x=width
        e.FluxRaid_RefreshJoinedBorders()
        check(not left.edges.right,"public edge getters still handle an unreadable rectangle")
        left.GetRect=nil
        function left:GetRight() return secret end
        e.FluxRaid_RefreshJoinedBorders()
        check(right.edges.exteriorLeft,"unreadable edge geometry retires the old contact")
    end
end
scenario()
scenario(nil,true)
local mutant,count=source:gsub("bottom=not cell%.below,right=not cell%.rightNeighbor","bottom=true,right=true",1)
if count==0 then
    mutant,count=source:gsub("cell.below == 0, cell.rightNeighbor == 0","true, true",1)
end
check(count==1,"negative control matches the production shared-edge decision")
check(not pcall(scenario,mutant),"negative control rejects separately boxed cells")
local overlapMutant,overlapCount=source:gsub('FluxRaidVisuals%.CELL_JOIN_OVERLAP or Compat%.HEADER_UNIT_YOFFSET or 4','4',1)
check(overlapCount==1,"negative control targets native row-overlap selection")
check(not pcall(scenario,overlapMutant,true),"native power-bar space cannot use the old four-pixel overlap")
print("Raid connected grid: "..checks.." checks; native one-pixel joins, partial groups, redundant neighbors, minis, opacity guards and two rejected controls")
