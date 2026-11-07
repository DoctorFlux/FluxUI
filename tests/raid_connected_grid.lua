-- Complete unit module, public cell geometry, and shared-edge topology. The
-- separate visual suite resolves actual texture anchors and draw ownership.
local file=assert(io.open("RaidFrame/FluxRaidUnit.lua","rb"))
local source=file:read("*a"):gsub("\r\n","\n");file:close()
local checks=0
local function check(ok,message)checks=checks+1;assert(ok,message)end
local function scenario(body,native)
    local e=setmetatable({},{__index=_G});e._G=e
    local secret={}
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
        function f:IsVisible()return self.visible end
        function f:GetLeft()return self.x end
        function f:GetRight()return self.x+width end
        function f:GetTop()return self.y end
        function f:GetBottom()return self.y-self.height end
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
end
scenario()
scenario(nil,true)
local mutant,count=source:gsub("bottom=not below,right=not right","bottom=true,right=true",1)
check(count==1,"negative control matches the production shared-edge decision")
check(not pcall(scenario,mutant),"negative control rejects separately boxed cells")
local overlapMutant,overlapCount=source:gsub('FluxRaidVisuals%.CELL_JOIN_OVERLAP or Compat%.HEADER_UNIT_YOFFSET or 4','4',1)
check(overlapCount==1,"negative control targets native row-overlap selection")
check(not pcall(scenario,overlapMutant,true),"native power-bar space cannot use the old four-pixel overlap")
print("Raid connected grid: "..checks.." checks; native one-pixel joins, partial groups, minis, opacity guards and two rejected controls")
