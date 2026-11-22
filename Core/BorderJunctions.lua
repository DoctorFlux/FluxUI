-- Shared mask-free border topology. Decorative containers/UV fragments can
-- align; content geometry, secure attributes and action routing stay untouched.
-- Geometry and guarded decorative paint only; never unit/aura/cast/action data.
local _, ns = ...
local Border = ns.Border
if not Border then return end
local J = { stats = { passes=0, solves=0, candidates=0, unchanged=0 }, limits = {
    segments=4096, candidates=24000, bucketEntries=32768, operations=2048, fragmentsPerPiece=32, fragments=8192, junctionTriangles=8192,
} }
Border.Junctions = J
J.version="side-hover-dock-r193"
local floor, min, max, abs = math.floor, math.min, math.max, math.abs
local PATH = "Interface\\AddOns\\_FluxUI\\Texture\\borders\\"
local EPS, CELL = 1, 64 -- physical screen coordinates; weld only overlapping border bands
local STRATA = {BACKGROUND=0,LOW=1,MEDIUM=2}
local capSides = {TL={Top=true,Left=true},TR={Top=true,Right=true},
    BL={Bottom=true,Left=true},BR={Bottom=true,Right=true}}
local shape = { [7]=0, [11]=1, [13]=2, [14]=3, [15]=4 }
local tracks = { [1]={Top=8,Bottom=8,Left=9,Right=9.5},
    [2]={Top=9,Bottom=7,Left=9.5,Right=9} }
local groups = setmetatable({}, {__mode="k"})
local scopeIDs=setmetatable({}, {__mode="k"})
local stripCanvases=setmetatable({}, {__mode="k"})
local capCanvases=setmetatable({}, {__mode="k"})
local junctionCanvases=setmetatable({}, {__mode="k"})
local nearbyPanels=setmetatable({}, {__mode="k"})
local watched = setmetatable({}, {__mode="k"})
local active, sprites = {}, setmetatable({}, {__mode="k"})
local renderEpoch,rollbackActive=0,nil
local renderBases,renderWork,renderLayers
local sourceReadPlan
local fallbackChains,fallbackAvailability
local ArmSlices,Branches
local ClearDrawCache,PublishDrawCache,PrepareDrawReuse
local committedSegments=setmetatable({}, {__mode="k"})
local clipped = setmetatable({}, {__mode="k"})
local painting = false
local colorListeners=setmetatable({}, {__mode="k"})
do
    local empty={}
    local function SingleList(list,index)
        if not index then return 1,list end
    end
    function J._FieldLists(lists)
        if not lists then return next,empty end
        if J.stats.localMode then return next,lists end
        return SingleList,lists
    end
    function J._ColorLists(source)
        return J._FieldLists(colorListeners[source])
    end
end
local visibilityListeners=setmetatable({}, {__mode="k"})
local availabilityCache=setmetatable({}, {__mode="k"})
local PaintFallbacks
local paintDirty = setmetatable({}, {__mode="k"})
local dirty, queued, nextID, previous = false, false, 0
local nextPieceID=0
local fullDirty=true
local registrationDirty=false
local registrationParents=setmetatable({}, {__mode="k"})
local pendingObjects=setmetatable({}, {__mode="k"})
local observed=setmetatable({}, {__mode="k"})
local readReasons={}
local idleTrace -- only the user's finite /fluxborders idle capture; no persistent monitor
local nextPass=0
local wakeSequence,wakeOwner=0,0
local ready=false
local function PublicNumber(v)
    return not (issecretvalue and issecretvalue(v)) and type(v)=="number" and v==v and abs(v)<10000000
end
local function AlphaPresent(value)
    if issecretvalue and issecretvalue(value) then return true end
    return PublicNumber(value) and value>0
end
local function SameColor(c,r,g,b,a)
    return c and PublicNumber(r) and PublicNumber(g) and PublicNumber(b) and PublicNumber(a)
        and PublicNumber(c[1]) and PublicNumber(c[2]) and PublicNumber(c[3]) and PublicNumber(c[4])
        and c[1]==r and c[2]==g and c[3]==b and c[4]==a
end
local function Locked() return InCombatLockdown and InCombatLockdown() end
local function Tolerance(a,b) return EPS+2*min(a.scale or 1,b.scale or 1) end
local opposite={Top="Bottom",Bottom="Top",Left="Right",Right="Left"}
local function CollinearTolerance(a,b)
    local tolerance=Tolerance(a,b)
    if opposite[a.side]~=b.side or not a.rect or not b.rect then return tolerance end
    local axis=a.axis=="H" and 2 or 1
    -- Opposing panels can have distinct cores while their bevel/shadow fields
    -- already overlap. They still need one paint owner, without moving frames.
    if max(a.rect[axis],b.rect[axis])<min(a.rect[axis+2],b.rect[axis+2]) then
        return max(tolerance,EPS+8*min(a.scale or 1,b.scale or 1))
    end
    return tolerance
end
local function JoinAllowed(a,b)
    local au,bu=a.group.unitOwner,b.group.unitOwner
    return not au or not bu or au==bu
end
local Above
do
local function RimPriority(segment,minimapBorder)
    if segment.axis~="H" then return 0 end
    if segment.side=="Top" and segment.group.actionStrip then return 1000000000 end
    if segment.side=="Bottom" and minimapBorder and segment.group.parent==minimapBorder then
        return 1000000000
    end
    return 0
end
function Above(a,b)
    local af,bf=a.group.fixedBounds and true or false,b.group.fixedBounds and true or false
    if af~=bf then return af end
    local au,bu=a.group.unitOwner~=nil,b.group.unitOwner~=nil
    if au~=bu then return not au end -- persistent HUD strokes outlive watched-unit visibility
    local minimap=_G.Minimap
    local minimapBorder=minimap and minimap.FluxBorderFrame
    local ap=(a.group.priority or 0)+RimPriority(a,minimapBorder)
    local bp=(b.group.priority or 0)+RimPriority(b,minimapBorder)
    if ap~=bp then return ap>bp end
    local aid,bid=a.group.paintID or a.group.id,b.group.paintID or b.group.id
    if aid~=bid then return aid<bid end
    return (a.paintID or 0)<(b.paintID or 0)
end
end
local function FixedPanel(frame)
    local window=_G.FluxWindowFrame
    if window and not window.GetRect then window=window.frame end
    return frame==window or frame._FluxBorderFixedBounds==true
end
local function PaintOwner(segment,probe)
    for _=1,32 do
        local nextOwner
        for _,run in ipairs(segment.paintCuts or {}) do
            if probe>=run.a-.00001 and probe<=run.b+.00001 then nextOwner=run.owner;break end
        end
        if not nextOwner then return segment end
        segment=nextOwner
    end
    return segment
end
local function CollectOwnerBoundaries(segment,low,high,cuts,visited)
    if visited[segment] then return true end
    visited[segment]=true
    for _,run in ipairs(segment.paintCuts or {}) do
        if run.b>low and run.a<high then
            cuts[#cuts+1]=max(low,run.a);cuts[#cuts+1]=min(high,run.b)
            if #cuts>128 or not CollectOwnerBoundaries(run.owner,low,high,cuts,visited) then return false end
        end
    end
    return true
end
local function Intersects(a,b)
    return a[1]<b[3] and a[3]>b[1] and a[2]<b[4] and a[4]>b[2]
end
local function ContinuousSampling(texture)
    -- Match NineSliceUtil.DisableSharpening: independently snapped UV fields
    -- do not agree at a cut, even when the anchors and source UVs match exactly.
    if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
    if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
end
-- These fields belong exclusively to the junction renderer. Retain exact
-- public setter arguments across reflows; unrelated fields need no native write.
local FieldPaint={}
-- Cache scalar texture and layer values directly. Only RGBA needs a tuple.
function FieldPaint.Texture(field,path)
    local cache=field._junctionSetCache
    if not cache then cache={};field._junctionSetCache=cache end
    if renderWork then renderWork.fieldCalls=renderWork.fieldCalls+1 end
    if cache.path==path and path~=nil then
        if renderWork then renderWork.fieldHits=renderWork.fieldHits+1 end
        return
    end
    if renderWork then renderWork.fieldWrites=renderWork.fieldWrites+1 end
    field:SetTexture(path)
    cache.path=path;cache.uv=nil -- SetTexture may reset native sampling.
end
function FieldPaint.Layer(field,layer,sublevel)
    local cache=field._junctionSetCache
    if not cache then cache={};field._junctionSetCache=cache end
    if renderWork then renderWork.fieldCalls=renderWork.fieldCalls+1 end
    if cache.layer==layer and layer~=nil and cache.sublevel==sublevel then
        if renderWork then renderWork.fieldHits=renderWork.fieldHits+1 end
        return
    end
    if renderWork then renderWork.fieldWrites=renderWork.fieldWrites+1 end
    field:SetDrawLayer(layer,sublevel)
    cache.layer,cache.sublevel=layer,sublevel
end
function FieldPaint.Color(field,r,g,b,a)
    local cache=field._junctionSetCache
    if not cache then cache={};field._junctionSetCache=cache end
    if renderWork then renderWork.fieldCalls=renderWork.fieldCalls+1 end
    local old=cache.color
    if old and old[1]==r and old[2]==g and old[3]==b and old[4]==a then
        if renderWork then renderWork.fieldHits=renderWork.fieldHits+1 end
        return
    end
    if renderWork then renderWork.fieldWrites=renderWork.fieldWrites+1 end
    field:SetVertexColor(r,g,b,a)
    cache.color={r,g,b,a}
end
J._FieldGeometry={}
do
local function HasSingleFieldAnchor(field,parent)
    local count=field:GetNumPoints()
    if not PublicNumber(count) or count~=1 then return false end
    local point,relative,relativePoint=field:GetPoint(1)
    if issecretvalue and (issecretvalue(point) or issecretvalue(relative)
        or issecretvalue(relativePoint)) then return false end
    return point=="BOTTOMLEFT" and rawequal(relative,parent) and relativePoint=="BOTTOMLEFT"
end
function J._FieldGeometry.Box(field,parent,x,y,w,h)
    local cache=field._junctionSetCache
    local box=cache.box
    if not box then box={};cache.box=box end
    if renderWork then renderWork.fieldCalls=renderWork.fieldCalls+2 end
    if box.parent==parent and box.x==x and box.y==y then
        if renderWork then renderWork.fieldHits=renderWork.fieldHits+1 end
    else
        -- Replacing the same anchor updates its offset. Clear first when
        -- the owner changes or a pooled field has different native points.
        local ok,reusable
        if box.parent==parent then ok,reusable=pcall(HasSingleFieldAnchor,field,parent) end
        box.parent=nil;cache.leader=nil
        if ok and reusable then
            local moved,err=pcall(field.SetPoint,field,"BOTTOMLEFT",parent,"BOTTOMLEFT",x,y)
            if not moved then
                pcall(field.ClearAllPoints,field)
                error(err,0)
            end
        else
            field:ClearAllPoints()
            field:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",x,y)
        end
        box.parent,box.x,box.y=parent,x,y
        if renderWork then renderWork.fieldWrites=renderWork.fieldWrites+1 end
    end
    if box.w==w and box.h==h then
        if renderWork then renderWork.fieldHits=renderWork.fieldHits+1 end
    else
        box.w=nil
        field:SetSize(w,h)
        box.w,box.h=w,h
        if renderWork then renderWork.fieldWrites=renderWork.fieldWrites+1 end
    end
end

-- Both textures belong to the same operation canvas. Only their geometry
-- follows the first triangle. Each texture keeps its own layer and paint.
function J._FieldGeometry.Follow(field,leader)
    local cache=field._junctionSetCache
    if renderWork then renderWork.fieldCalls=renderWork.fieldCalls+1 end
    if cache.leader==leader then
        if renderWork then renderWork.fieldHits=renderWork.fieldHits+1 end
        return
    end
    local box=cache.box
    if box then box.parent,box.w=nil,nil end
    cache.leader=nil
    field:ClearAllPoints()
    local ok,err=pcall(field.SetAllPoints,field,leader)
    if not ok then
        pcall(field.ClearAllPoints,field)
        error(err,0)
    end
    cache.leader=leader
    if renderWork then renderWork.fieldWrites=renderWork.fieldWrites+1 end
end
end
do
    local function FieldVertex(field,vertices,slot,vertex,x,y)
        if vertices[slot]==vertex and vertices[slot+1]==x and vertices[slot+2]==y then
            if renderWork then renderWork.fieldHits=renderWork.fieldHits+1 end
            return
        end
        vertices[slot]=nil
        field:SetVertexOffset(vertex,x,y)
        vertices[slot],vertices[slot+1],vertices[slot+2]=vertex,x,y
        if renderWork then renderWork.fieldWrites=renderWork.fieldWrites+1 end
    end
    function J._FieldGeometry.Vertices(field,triangle,w,h)
        local cache=field._junctionSetCache
        if renderWork then renderWork.fieldCalls=renderWork.fieldCalls+4 end
        if not triangle and cache.flatVertices then
            if renderWork then renderWork.fieldHits=renderWork.fieldHits+4 end
            return
        end
        local vertices=cache.vertices
        if not vertices then vertices={};cache.vertices=vertices end
        cache.flatVertices=nil
        if triangle then
            local a,b,c=triangle.a,triangle.b,triangle.c
            local cx=(c[1]-1)*w
            FieldVertex(field,vertices,1,UPPER_LEFT_VERTEX or 1,a[1]*w,-a[2]*h)
            FieldVertex(field,vertices,4,LOWER_LEFT_VERTEX or 2,b[1]*w,(1-b[2])*h)
            FieldVertex(field,vertices,7,UPPER_RIGHT_VERTEX or 3,cx,-c[2]*h)
            FieldVertex(field,vertices,10,LOWER_RIGHT_VERTEX or 4,cx,(1-c[2])*h)
        else
            FieldVertex(field,vertices,1,1,0,0)
            FieldVertex(field,vertices,4,2,0,0)
            FieldVertex(field,vertices,7,3,0,0)
            FieldVertex(field,vertices,10,4,0,0)
            cache.flatVertices=true
        end
    end
end
local function FieldUV(field,uv)
    if renderWork then renderWork.fieldCalls=renderWork.fieldCalls+1 end
    field._junctionUV=uv
    local cache=field._junctionSetCache
    local old=cache.uv
    -- Prepared poses can reuse the exact same immutable samples. Other
    -- geometry can still produce equal coordinates in a different array.
    if old==uv or old and old[1]==uv[1] and old[2]==uv[2] and old[3]==uv[3] and old[4]==uv[4]
        and old[5]==uv[5] and old[6]==uv[6] and old[7]==uv[7] and old[8]==uv[8] then
        if renderWork then renderWork.fieldHits=renderWork.fieldHits+1 end
        return
    end
    if renderWork then renderWork.fieldWrites=renderWork.fieldWrites+1 end
    field:SetTexCoord(unpack(uv))
    cache.uv=uv
end
local function FieldAlpha(field,alpha)
    if PublicNumber(alpha) then
        if renderWork then renderWork.alphaReads=renderWork.alphaReads+1 end
        local current=field:GetAlpha()
        if PublicNumber(current) and current==alpha then return true end
    end
    if renderWork then renderWork.alphaWrites=renderWork.alphaWrites+1 end
    field:SetAlpha(alpha)
end
local function FieldColor(field,r,g,b,a)
    if PublicNumber(r) and PublicNumber(g) and PublicNumber(b) and PublicNumber(a) then
        FieldPaint.Color(field,r,g,b,a)
    else
        if field._junctionSetCache then field._junctionSetCache.color=nil end
        field:SetVertexColor(r,g,b,a)
    end
end
-- Native unit RGB is presentation only. The public proxy remains the solver
-- input; opaque channels are neither compared nor included in cache identities.
local function NativeFieldColor(field,texture)
    local cache=renderBases and renderBases._nativeColors
    if renderBases and not cache then cache={};renderBases._nativeColors=cache end
    local color=cache and cache[texture]
    if not color then
        local r,g,b=texture:GetVertexColor()
        color={r,g,b,1}
        if cache then cache[texture]=color end
    end
    FieldColor(field,unpack(color))
end
function J._FieldGeometry.Color(field,texture,entry)
    if entry.nativeRGB then
        NativeFieldColor(field,texture)
    elseif entry.epoch==renderEpoch then
        -- RenderFragments installed this commit's validated public RGBA.
        FieldPaint.Color(field,unpack(entry.color,1,4))
    else
        FieldColor(field,unpack(entry.color))
    end
end

local function FieldShow(field)
    if renderWork then renderWork.showReads=renderWork.showReads+1 end
    local shown=field:IsShown()
    if issecretvalue and issecretvalue(shown) or not shown then
        if renderWork then renderWork.showWrites=renderWork.showWrites+1 end
        field:Show()
    end
end
local function HideRetiredField(field)
    if renderWork then renderWork.hideWrites=renderWork.hideWrites+1 end
    field:Hide()
end
local function FieldHide(field)
    if renderWork then renderWork.hideReads=renderWork.hideReads+1 end
    local shown=field:IsShown()
    if issecretvalue and issecretvalue(shown) or shown~=false then
        HideRetiredField(field)
    end
end

-- Pure interval/bucket solver, also exercised with production-sized layouts.
-- A segment has axis H/V, p (perpendicular), a/b (extent), scale, side and group.
function J:Solve(segments)
    if #segments>self.limits.segments then return nil,"segment budget" end
    local bins, nodes, operations, candidates = {}, {}, {}, 0
    local bucketEntries=0
    local function Add(op)
        operations[#operations+1]=op
        return #operations<=self.limits.operations
    end
    table.sort(segments,function(a,b)
        if a.axis~=b.axis then return a.axis<b.axis end
        if a.group.plane~=b.group.plane then return a.group.plane<b.group.plane end
        if a.p~=b.p then return a.p<b.p end
        if a.a~=b.a then return a.a<b.a end
        return a.group.id<b.group.id
    end)
    -- Build one spatial index for parallel overlap and perpendicular joins.
    for i,s in ipairs(segments) do
        s.id=i;s.rawP=s.p;s.paintCuts={};s.weldOffset=0
    end
    for _,s in ipairs(segments) do
        local low,high=floor((s.a-EPS)/CELL),floor((s.b+EPS)/CELL)
        local c=floor(s.p/CELL)
        if high-low>128 then return nil,"extent budget" end
        for along=low,high do
            for across=c-1,c+1 do
                bucketEntries=bucketEntries+1
                if bucketEntries>self.limits.bucketEntries then return nil,"bucket budget" end
                local key=s.group.plane..":"..(s.axis=="H" and along..":"..across or across..":"..along)
                local bin=bins[key]
                if not bin then bin={H={},V={}};bins[key]=bin end
                local list=bin[s.axis];list[#list+1]=s
            end
        end
    end
    -- Check every local parallel neighbour, rather than partitioning by one
    -- representative line. Interleaved opposing/same-side runs otherwise hide
    -- real contacts (for example Micro Menu versus NonCombat Grid).
    local parallelSeen,pairsToPaint={},{}
    for _,bin in pairs(bins) do
        local bh,bv=bin.H,bin.V
        for axisIndex=1,2 do
            local axis=axisIndex==1 and bh or bv
            for i,a in ipairs(axis) do for k=i+1,#axis do
                local b=axis[k]
                candidates=candidates+1
                if candidates>self.limits.candidates then self.stats.candidates=candidates;return nil,"candidate budget" end
                local seenA=parallelSeen[a]
                if not seenA then seenA={};parallelSeen[a]=seenA end
                if not seenA[b] then
                    seenA[b]=true
                    local low,high=max(a.a,b.a),min(a.b,b.b)
                    if a.group~=b.group and high-low>EPS and abs(a.p-b.p)<=CollinearTolerance(a,b) then
                        local loser,keeper=a,b
                        if Above(a,b) then loser,keeper=b,a end
                        pairsToPaint[#pairsToPaint+1]={loser=loser,keeper=keeper,a=low,b=high}
                    end
                end
            end end
        end
    end
    table.sort(pairsToPaint,function(a,b)
        if a.keeper.group~=b.keeper.group then return Above(a.keeper,b.keeper) end
        if a.loser.group~=b.loser.group then return Above(a.loser,b.loser) end
        return a.loser.id<b.loser.id
    end)
    local function Availability(item,rect,owner)
        if not item then return end
        item.availabilityCuts=item.availabilityCuts or {}
        item.availabilityCuts[#item.availabilityCuts+1]={rect=rect,owner=owner}
    end
    local capIndex,emptyPieces={},{}
    local function CoincidentCaps(lower,higher,corners)
        -- A cap cannot belong to two opposing sides of an outline.
        if opposite[lower.side]==higher.side then return end
        for _,item in ipairs(lower.group.pieces or emptyPieces) do
            local key=item.record.key
            local sides=capSides[key]
            if sides and sides[lower.side] and sides[higher.side] then
                local byKey=capIndex[higher.group]
                if not byKey then
                    byKey={}
                    capIndex[higher.group]=byKey
                    for _,other in ipairs(higher.group.pieces or emptyPieces) do
                        local otherKey=other.record.key
                        if capSides[otherKey] then
                            local list=byKey[otherKey]
                            if not list then list={};byKey[otherKey]=list end
                            list[#list+1]=other
                        end
                    end
                end
                for _,other in ipairs(byKey[key] or emptyPieces) do
                    local same=true
                    for axis=1,4 do if abs(item.rect[axis]-other.rect[axis])>EPS then same=false;break end end
                    if same then
                        if corners then corners[#corners+1]=item
                        else Availability(item,item.rect,other.texture) end
                    end
                end
            end
        end
    end
    local function PaintParallelInterval(a,b,first,finish)
        if a==b or not JoinAllowed(a,b) then return true end
        local lower,higher=a,b
        if Above(a,b) then lower,higher=b,a end
        lower.paintCuts[#lower.paintCuts+1]={a=first,b=finish,owner=higher}
        local offset=abs(lower.rawP-higher.rawP)
        lower.weldOffset=max(lower.weldOffset,offset);higher.weldOffset=max(higher.weldOffset,offset)
        local center,half=higher.rawP,16*max(lower.scale,higher.scale)
        local r=lower.axis=="H" and {first,center-half,finish,center+half}
            or {center-half,first,center+half,finish}
        if lower.rect and higher.rect then
            local axis=lower.axis=="H" and 2 or 1
            r[axis]=min(lower.rect[axis],higher.rect[axis])-EPS
            r[axis+2]=max(lower.rect[axis+2],higher.rect[axis+2])+EPS
        end
        local corners={}
        -- Coincident complete outlines share their caps too.
        -- Edge-only cuts stop at stroke centers and leave doubled shadows.
        CoincidentCaps(lower,higher,corners)
        return Add({rect=r,cut={[lower.group]=true},edges={[lower.group]={[lower.side]=true}},corners=corners,
            members={[lower.group]=true,[higher.group]=true}})
    end
    for _,pair in ipairs(pairsToPaint) do
        local loser,keeper=pair.loser,pair.keeper
        if JoinAllowed(loser,keeper) then
            -- Keep every original higher owner, including intermediary sources
            -- later hidden by a still higher duplicate. Compile paint fallbacks
            -- from these public layout intervals; visibility never re-solves.
            if loser.item and loser.rect then
                local r=loser.axis=="H" and {pair.a,loser.rect[2],pair.b,loser.rect[4]}
                    or {loser.rect[1],pair.a,loser.rect[3],pair.b}
                Availability(loser.item,r,keeper.texture)
                CoincidentCaps(loser,keeper)
            end
            if #loser.paintCuts==0 and #keeper.paintCuts==0 then
                -- Both original edges still own the whole interval.
                if not PaintParallelInterval(loser,keeper,pair.a,pair.b) then return nil,"operation budget" end
            else
                local boundaries,visited={pair.a,pair.b},{}
                if not CollectOwnerBoundaries(loser,pair.a,pair.b,boundaries,visited)
                    or not CollectOwnerBoundaries(keeper,pair.a,pair.b,boundaries,visited) then return nil,"ownership boundary budget" end
                if #boundaries>2 then table.sort(boundaries) end
                local previous=boundaries[1]
                for i=2,#boundaries do
                    local finish=boundaries[i]
                    if finish-previous>.00001 then
                        local probe=(previous+finish)/2
                        if not PaintParallelInterval(PaintOwner(loser,probe),PaintOwner(keeper,probe),previous,finish) then
                            return nil,"operation budget"
                        end
                        previous=finish
                    end
                end
            end
        elseif opposite[loser.side]==keeper.side and loser.rect and keeper.rect then
            local low,high=loser,keeper
            if low.rawP>high.rawP then low,high=high,low end
            local mid=(low.rawP+high.rawP)/2
            local lr=low.axis=="H" and {pair.a,mid,pair.b,max(low.rect[4],high.rect[4])+EPS}
                or {mid,pair.a,max(low.rect[3],high.rect[3])+EPS,pair.b}
            local hr=low.axis=="H" and {pair.a,min(low.rect[2],high.rect[2])-EPS,pair.b,mid}
                or {min(low.rect[1],high.rect[1])-EPS,pair.a,mid,pair.b}
            for _,entry in ipairs({{low,lr},{high,hr}}) do
                local edge,rect=entry[1],entry[2]
                if not Add({rect=rect,cut={[edge.group]=true},edges={[edge.group]={[edge.side]=true}},
                    members={[low.group]=true,[high.group]=true},shadowOnly=true}) then return nil,"operation budget" end
            end
        end
    end
    local seen={}
    local nodeList={}
    for _,bin in pairs(bins) do
        for _,originalH in ipairs(bin.H) do
            for _,originalV in ipairs(bin.V) do
                local h,v=originalH,originalV
                candidates=candidates+1
                if candidates>self.limits.candidates then self.stats.candidates=candidates;return nil,"candidate budget" end
                local seenH=seen[h]
                if not seenH then seenH={};seen[h]=seenH end
                if not seenH[v] then
                    seenH[v]=true
                    local tolerance=Tolerance(h,v)
                    local reach=tolerance+max(h.weldOffset or 0,v.weldOffset or 0)
                    if JoinAllowed(h,v) and v.p>=h.a-reach and v.p<=h.b+reach and h.p>=v.a-reach and h.p<=v.b+reach then
                        h=PaintOwner(h,v.rawP)
                        v=PaintOwner(v,h.rawP)
                        h=PaintOwner(h,v.rawP)
                        if JoinAllowed(h,v) and JoinAllowed(originalH,v) and JoinAllowed(h,originalV) then
                        local x,y=v.rawP,h.rawP
                        local unitOwner=originalH.group.unitOwner or originalV.group.unitOwner or h.group.unitOwner or v.group.unitOwner
                        local bx,by=floor(x/4),floor(y/4)
                        local node
                        for dx=-1,1 do
                            for dy=-1,1 do
                                local bucket=nodes[h.group.plane..":"..(bx+dx)..":"..(by+dy)]
                                if bucket then for _,n in ipairs(bucket) do
                                    if abs(n.x-x)<=tolerance and abs(n.y-y)<=tolerance
                                        and not (n.unitOwner and unitOwner and n.unitOwner~=unitOwner) then node=n;break end
                                end end
                            end
                        end
                        if not node then
                            node={x=x,y=y,members={},segments={},hs=h,vs=v,unitOwner=unitOwner}
                            local nk=h.group.plane..":"..bx..":"..by
                            nodes[nk]=nodes[nk] or {};table.insert(nodes[nk],node)
                            nodeList[#nodeList+1]=node
                        end
                        node.unitOwner=node.unitOwner or unitOwner
                        node.segments[h]=true;node.segments[v]=true
                        node.segments[originalH]=true;node.segments[originalV]=true
                        node.members[h.group]=true;node.members[v.group]=true
                        node.members[originalH.group]=true;node.members[originalV.group]=true
                        if Above(h,node.hs) then node.hs=h end
                        if Above(v,node.vs) then node.vs=v end
                        end
                    end
                end
            end
        end
    end
    for _,node in ipairs(nodeList) do
        local l,r,u,d=false,false,false,false
        local count=0
        for _ in pairs(node.members) do count=count+1 end
        if count>1 then
            node.x,node.y=node.vs.p,node.hs.p
            local tolerance=Tolerance(node.hs,node.vs)
            for s in pairs(node.segments) do
                if s.axis=="H" then l=l or s.a<node.x-tolerance;r=r or s.b>node.x+tolerance
                else d=d or s.a<node.y-tolerance;u=u or s.b>node.y+tolerance end
            end
            local bits=(l and 1 or 0)+(r and 2 or 0)+(u and 4 or 0)+(d and 8 or 0)
            if shape[bits] then
                node.bits=bits
                node.rect={node.x-16*node.vs.scale,node.y-16*node.hs.scale,node.x+16*node.vs.scale,node.y+16*node.hs.scale}
                node.fullRect={unpack(node.rect)}
                node.cut=node.members
                node.edges={}
                for s in pairs(node.segments) do
                    node.edges[s.group]=node.edges[s.group] or {}
                    node.edges[s.group][s.side]=true
                end
                if not Add(node) then return nil,"operation budget" end
            end
        end
    end
    -- Close junction patches must not stack over one another. Partition their
    -- overlap and crop the matching source UVs; the original line fills outside.
    local patches={}
    for _,node in ipairs(nodeList) do
        if node.bits then
            local rect=node.rect
            local x0,x1,y0,y1=floor(rect[1]/CELL),floor(rect[3]/CELL),floor(rect[2]/CELL),floor(rect[4]/CELL)
            if (x1-x0+1)*(y1-y0+1)>64 then return nil,"patch extent budget" end
            local visited={}
            for x=x0,x1 do for y=y0,y1 do
                local key=node.hs.group.plane..":"..x..":"..y
                local patchBucket=patches[key]
                if patchBucket then for _,other in ipairs(patchBucket) do
                    if not visited[other] then
                        visited[other]=true;candidates=candidates+1
                        if candidates>self.limits.candidates then return nil,"candidate budget" end
                        if Intersects(node.rect,other.rect) then
                            local dx,dy=node.x-other.x,node.y-other.y
                            local axis=abs(dx)>=abs(dy) and 1 or 2
                            local mid=axis==1 and (node.x+other.x)/2 or (node.y+other.y)/2
                            local first=(axis==1 and dx or dy)<0
                            local low,high=first and node or other,first and other or node
                            low.rect[axis+2]=min(low.rect[axis+2],mid)
                            high.rect[axis]=max(high.rect[axis],mid)
                        end
                    end
                end
                end
                patches[key]=patches[key] or {};table.insert(patches[key],node)
            end end
        end
    end
    -- Resolve current interval owners once. A remote parallel keeper may be
    -- sampled by this node even though it did not form the intersection. Cut
    -- its native edge too, without changing the node's geometric candidates.
    for _,node in ipairs(nodeList) do if node.bits then
        local best=Branches(node)
        node.branchBest=best;node.branchSlices={}
        local remote={}
        for arm=1,4 do if floor(node.bits/2^(arm-1))%2==1 then
            local slices,reason=ArmSlices(node,arm,best)
            if not slices then node.branchError=reason;break end
            node.branchSlices[arm]=slices
            for _,slice in ipairs(slices) do
                local segment=slice.segment
                if segment.group.plane~=node.hs.group.plane or not JoinAllowed(node.hs,segment) or not JoinAllowed(node.vs,segment) then
                    node.branchError="incompatible interval owner";break
                end
                if not node.segments[segment] then remote[segment]=true end
            end
            if node.branchError then break end
        end end
        if not node.branchError then for segment in pairs(remote) do
            local g=segment.group
            node.members[g]=true
            node.edges[g]=node.edges[g] or {};node.edges[g][segment.side]=true
        end end
    end end
    -- A T near an ordinary outside L must not erase that cap or draw a
    -- clamped straight-edge field across it. Compact unit blocks can put a
    -- resource split inside the 32px junction window of both outer corners.
    for _,node in ipairs(nodeList) do
        if node.bits then
            local tolerance=Tolerance(node.hs,node.vs)
            node.protectedCaps={};node.protectedRects={}
            local hasAura=false
            for g in pairs(node.members) do if g.parent and g.parent._FluxBorderAuraPanel then hasAura=true end end
            node.roundCaps={}
            for g in pairs(node.members) do
                for _,item in ipairs(g.pieces or {}) do
                    local matched=item.cornerX and abs(item.cornerX-node.x)<=tolerance and abs(item.cornerY-node.y)<=tolerance
                    local rounded=matched and hasAura and g.parent and g.parent._FluxBorderRoundCorners
                    local internal=g.parent and g.parent._FluxBorderCastInternalSide
                    local internalCap=internal and capSides[item.record.key] and capSides[item.record.key][internal]
                    if item.cornerX and not internalCap and Intersects(item.rect,node.rect) and (not matched or rounded) then
                        node.protectedCaps[item]=true
                        node.protectedRects[#node.protectedRects+1]=item.rect
                        if #node.protectedRects>64 then return nil,"junction cap budget" end
                        if rounded then
                            local incoming
                            for s in pairs(node.segments) do
                                if s.axis=="V" and s.group.parent and s.group.parent._FluxBorderAuraPanel
                                    and (not incoming or Above(s,incoming)) then incoming=s end
                            end
                            if incoming then node.roundCaps[#node.roundCaps+1]={item=item,segment=incoming} end
                        end
                    end
                end
            end
        end
    end
    self.stats.candidates=candidates
    return operations
end

-- Restore only our opacity suppression. Native visibility, geometry and colors
-- remain owned by their original textures; foreign masks are never touched.
function J:ReleaseAll()
    if self._ResetLocality then self._ResetLocality() end
    sourceReadPlan=nil
    renderBases=nil;renderLayers=nil
    fallbackChains=nil;fallbackAvailability=nil
    if self._ClearBranchCompileCache then self:_ClearBranchCompileCache() end
    if self._ClearFallbackCompileCache then self:_ClearFallbackCompileCache() end
    if self._ClearFallbackPlanCache then self:_ClearFallbackPlanCache() end
    if ClearDrawCache then ClearDrawCache() end
    painting=true
    for texture,entry in pairs(clipped) do
        if entry.active then
            entry.active=false
            texture:SetAlpha(entry.alpha)
        end
        for _,fragment in ipairs(entry.pool) do fragment:Hide() end
    end
    for _,op in ipairs(active) do
        for _,t in ipairs(op.sprites or {}) do t:Hide();t._junctionOp=nil;t._junctionOwnerOp=nil end
    end
    for _,op in ipairs(rollbackActive or {}) do
        for _,t in ipairs(op.sprites or {}) do t:Hide();t._junctionOp=nil;t._junctionOwnerOp=nil end
    end
    rollbackActive=nil
    for _,pool in pairs(sprites) do pool.freeIndex=1 end
    active={};committedSegments=setmetatable({}, {__mode="k"});colorListeners=setmetatable({}, {__mode="k"});visibilityListeners=setmetatable({}, {__mode="k"});availabilityCache=setmetatable({}, {__mode="k"});painting=false
    self._RetireArrowCanvasLevels()
    for _,canvas in pairs(junctionCanvases) do canvas._requiredRank=nil;canvas._requiredLevel=0 end
end

-- Visibility changes release only their connected component. Other HUD joins
-- stay committed, including during combat and repeated native Show() calls.
function J:ReleaseFor(object,preserveAlpha)
    if self._ResetLocality and self.stats.localMode then
        -- Restricted paint retirement preserves the just-written native source.
        local preserved=preserveAlpha and clipped[preserveAlpha]
        if preserved then preserved.active=false end
        self:ReleaseAll();self:Invalidate(nil,nil,"local source ownership changed");return
    end
    local roots={}
    for _,op in ipairs(active) do
        for g in pairs(op.members) do
            local related=false
            for _,item in ipairs(g.pieces) do if item.texture==object then related=true;break end end
            local parent=g.parent
            while not related and parent and parent~=UIParent do
                related=parent==object or parent._FluxBorderOwner==object
                parent=parent.GetParent and parent:GetParent()
            end
            if related then roots[op.root]=true end
        end
    end
    if not next(roots) then return end
    painting=true
    for texture,entry in pairs(clipped) do
        if entry.active and roots[entry.root] then
            entry.active=false;if texture~=preserveAlpha then texture:SetAlpha(entry.alpha) end
            for _,fragment in ipairs(entry.pool) do fragment:Hide() end
        end
    end
    local keep={}
    for _,op in ipairs(active) do
        if roots[op.root] then
            for _,t in ipairs(op.sprites or {}) do
                t:Hide();t._junctionOp=nil;t._junctionOwnerOp=nil
                local pool=sprites[t._junctionPoolOwner]
                if pool then pool.freeIndex=1 end
            end
        else keep[#keep+1]=op end
    end
    active=keep;painting=false;previous=nil
end

local rectReadPhase
local function Role(parent)
    local phase=rectReadPhase
    local memo
    if phase and not phase.admissionInvalidated then
        memo=phase.roles
        if not memo then memo={};phase.roles=memo end
    end
    local p=parent
    local path,role
    while true do
        if issecretvalue and issecretvalue(p) then return "overlay" end
        if not p or p==UIParent then break end
        if memo then
            local known=memo[p]
            if known~=nil then role=known or nil;break end
            path=path or {};path[#path+1]=p
        end
        local junction=p._FluxBorderJunctionRole
        if issecretvalue and issecretvalue(junction) then return "overlay" end
        if junction=="connected" then break end
        local overlay=p._FluxBorderOverlay
        if issecretvalue and issecretvalue(overlay) then return "overlay" end
        if overlay or junction=="overlay" then role="overlay";break end
        local getParent=p.GetParent
        if issecretvalue and issecretvalue(getParent) then return "overlay" end
        p=getParent and getParent(p)
        if memo and phase.admissionInvalidated then memo,path=nil,nil end
    end
    -- Admission and geometry can share public ancestry and its settled role.
    -- Never publish a walk interrupted by an observed layout change.
    if path and not phase.admissionInvalidated then
        for _,frame in ipairs(path) do memo[frame]=role or false end
    end
    return role
end
local function IsMiniUnit(unit)
    return unit=="pet" or unit=="pettarget" or unit:match("targettarget$")
        or unit=="focustarget" or unit:match("^party%dtarget$")
end
local function StaticUnitOwner(object)
    if issecretvalue and issecretvalue(object) or not object then return end
    local query=object
    local memo
    -- After originals settle, the existing availability phase reads source
    -- ownership only. Reuse public owner identities, never native coordinates.
    local phase=rectReadPhase or fallbackChains
    if phase then
        memo=phase.owners
        if not memo then memo={};phase.owners=memo end
        local cached=memo[query]
        if phase==fallbackChains and issecretvalue and issecretvalue(cached) then
            memo[query]=nil;return
        end
        if cached then return cached elseif cached==false then return end
    end
    local complete=false
    for _=1,32 do
        if issecretvalue and issecretvalue(object) then break end
        if not object or object==UIParent then complete=true;break end
        object=object._FluxBorderOwner or object
        if issecretvalue and issecretvalue(object) then break end
        if object._FluxBorderStatic then if memo then memo[query]=object end;return object end
        local unit=object.unit
        if not (issecretvalue and issecretvalue(unit)) and type(unit)=="string" and object==_G["FluxUnitFrame_"..unit] then
            if memo then memo[query]=object end;return object
        end
        if object._fluxPartyMember or object._fluxPartyPet or object._fluxPartyTarget then
            if memo then memo[query]=object end;return object
        end
        local getter=object.GetParent
        if phase==fallbackChains then
            if issecretvalue and issecretvalue(getter) or type(getter)~="function" then return end
            object=getter(object)
        else
            object=getter and object:GetParent()
        end
    end
    -- A private/missing/cyclic or over-budget chain can become available later
    -- in this phase. Only a complete public commit walk can cache a miss.
    if memo and (phase~=fallbackChains or complete) then memo[query]=false end
end
local function StaticUnitFrame(object)
    -- Native unit paint can hide individual edge textures as well as the root.
    -- Their prepared layout must survive both kinds of visibility transition.
    return StaticUnitOwner(object)
end
local anchorFactors={TOPLEFT={0,1},TOP={.5,1},TOPRIGHT={1,1},LEFT={0,.5},CENTER={.5,.5},RIGHT={1,.5},BOTTOMLEFT={0,0},BOTTOM={.5,0},BOTTOMRIGHT={1,0}}
local function NativePublicRect(object)
    local phase=rectReadPhase
    if phase then
        local cached=phase.native[object]
        if cached then return unpack(cached,1,4) end
        if cached==false then return nil,nil,nil,nil,phase.private[object] end
    end
    local x,y,w,h=object:GetRect()
    local restricted=issecretvalue and (issecretvalue(x) or issecretvalue(y) or issecretvalue(w) or issecretvalue(h))
    if not restricted and PublicNumber(x) and PublicNumber(y) and PublicNumber(w) and PublicNumber(h) and w>0 and h>0 then
        if phase then phase.native[object]={x,y,w,h} end
        return x,y,w,h
    end
    if phase then phase.native[object]=false;if restricted then phase.private[object]=true end end
    return nil,nil,nil,nil,restricted
end
local function PublicRect(object)
    local x,y,w,h,restricted=NativePublicRect(object)
    if x then return x,y,w,h end
    if restricted then return end
    if not StaticUnitOwner(object) then return end
    -- Hidden native regions can lack a computed rectangle until first shown.
    -- Resolve only their existing public anchors, without showing or moving a
    -- protected object. Never infer geometry when a native value is restricted.
    local phase=rectReadPhase
    local cache,visiting,budget={},{},64
    local charged=phase and {}
    local function Resolve(region,depth)
        if not region or not region.GetRect or depth>8 or budget<=0 or visiting[region] then return end
        local cached=cache[region]
        if cached then return unpack(cached,1,4) elseif cached==false then return end
        if phase then
            cached=phase.resolved[region]
            if cached==false then return end
            if cached then
                -- Cached anchor walks still consume the original per-root
                -- depth/node allowances; earlier roots cannot relax a guard.
                if depth+cached[5]>8 then return end
                local needed=0
                for _,dependency in ipairs(cached[6]) do
                    if visiting[dependency] then return end
                    if not charged[dependency] then needed=needed+1 end
                end
                if needed>budget then return end
                budget=budget-needed
                for _,dependency in ipairs(cached[6]) do
                    charged[dependency]=true;cache[dependency]=phase.resolved[dependency]
                end
                cache[region]=cached
                return unpack(cached,1,4)
            end
        end
        budget=budget-1;visiting[region]=true
        if charged then charged[region]=true end
        local rx,ry,rw,rh,private
        if region~=object then rx,ry,rw,rh,private=NativePublicRect(region) end
        if private then if phase then phase.resolved[region]=false end;return end
        if rx then
            local result=phase and phase.native[region] or {rx,ry,rw,rh}
            if phase then result[5]=0;result[6]={region};phase.resolved[region]=result end
            cache[region]=result;visiting[region]=nil;return rx,ry,rw,rh
        end
        cache[region]=false
        if not region.GetNumPoints or not region.GetPoint or not region.GetEffectiveScale then
            if phase then phase.resolved[region]=false end;return
        end
        local count,scale=region:GetNumPoints(),region:GetEffectiveScale()
        if not PublicNumber(count) or count<1 or count>32 or not PublicNumber(scale) or scale<=0 then
            if phase then phase.resolved[region]=false end;return
        end
        local width,height
        if region.GetSize then width,height=region:GetSize(true) end
        if issecretvalue and (issecretvalue(width) or issecretvalue(height)) then return end
        local constraints={}
        local dependencies,seen,maxDepth
        if phase then dependencies={region};seen={[region]=true};maxDepth=0 end
        for i=1,count do
            local point,relative,relativePoint,ox,oy=region:GetPoint(i)
            if issecretvalue and (issecretvalue(point) or issecretvalue(relative) or issecretvalue(relativePoint) or issecretvalue(ox) or issecretvalue(oy)) then return end
            if type(relative)=="string" then relative=_G[relative] end
            if relative==nil then relative=region:GetParent() end
            if issecretvalue and issecretvalue(relative) then return end
            local pf=type(point)=="string" and anchorFactors[point]
            local rf=type(relativePoint)=="string" and anchorFactors[relativePoint]
            local kind=type(relative)
            if not pf or not rf or not PublicNumber(ox) or not PublicNumber(oy) or (kind~="table" and kind~="userdata") or not relative.GetEffectiveScale then return end
            local ax,ay,aw,ah=Resolve(relative,depth+1)
            local relativeScale=relative:GetEffectiveScale()
            if not ax or not PublicNumber(relativeScale) or relativeScale<=0 then return end
            if phase then
                local resolved=cache[relative]
                maxDepth=max(maxDepth,resolved[5]+1)
                for _,dependency in ipairs(resolved[6]) do
                    if not seen[dependency] then seen[dependency]=true;dependencies[#dependencies+1]=dependency end
                end
            end
            constraints[#constraints+1]={pf[1],(ax+aw*rf[1])*relativeScale/scale+ox,pf[2],(ay+ah*rf[2])*relativeScale/scale+oy}
        end
        local function Axis(index,size)
            local first=constraints[1]
            for i=2,#constraints do
                local other=constraints[i]
                if other[index]~=first[index] then size=(other[index+1]-first[index+1])/(other[index]-first[index]);break end
            end
            if PublicNumber(size) and size>0 then return first[index+1]-first[index]*size,size end
        end
        rx,rw=Axis(1,width);ry,rh=Axis(3,height)
        if not (PublicNumber(rx) and PublicNumber(ry) and PublicNumber(rw) and PublicNumber(rh)) then return end
        local result={rx,ry,rw,rh}
        if phase then result[5]=maxDepth;result[6]=dependencies;phase.resolved[region]=result end
        cache[region]=result;visiting[region]=nil
        return rx,ry,rw,rh
    end
    return Resolve(object,0)
end
local function PublicOrigin(object)
    local phase=rectReadPhase
    local cached=phase and phase.origin[object]
    if cached then return cached[1],cached[2] elseif cached==false then return end
    local x,y=object:GetLeft(),object:GetBottom()
    if PublicNumber(x) and PublicNumber(y) then
        if phase then phase.origin[object]={x,y} end
        return x,y
    end
    if issecretvalue and (issecretvalue(x) or issecretvalue(y)) then
        if phase then phase.origin[object]=false end;return
    end
    x,y=PublicRect(object)
    if phase then phase.origin[object]=x and {x,y} or false end
    return x,y
end
local function RenderBasis(parent)
    local saved=renderBases and renderBases[parent]
    if saved then return saved[1],saved[2],saved[3] end
    if renderWork then renderWork.basisReads=renderWork.basisReads+1 end
    local scale=parent:GetEffectiveScale()
    local x,y=PublicOrigin(parent)
    if not (PublicNumber(scale) and scale>0 and PublicNumber(x) and PublicNumber(y)) then
        error("Unavailable public junction render basis",0)
    end
    if renderBases then renderBases[parent]={scale,x,y} end
    return scale,x,y
end
local function LayoutScale(parent, sample)
    if sample and sample.scaleParent==parent then return sample.scale end
    local scale=parent:GetEffectiveScale()
    if not PublicNumber(scale) or scale<=0 then return end
    if sample then sample.scaleParent,sample.scale=parent,scale end
    return scale
end
local function Geometry(texture, sample)
    if not texture.GetRect or not texture.IsVisible then return end
    local entry=clipped[texture]
    if entry and (entry.waitingAlpha or entry.waitingColor) then return end
    if issecretvalue and not (entry and (entry.active or entry.nativePaint and entry.rgbPublic)) and texture.GetVertexColor then
        local r,g,b,a=texture:GetVertexColor()
        if issecretvalue(r) or issecretvalue(g) or issecretvalue(b) or issecretvalue(a) then return end
    end
    local visible
    local retained=StaticUnitOwner(texture)
    if retained then visible=true
    elseif entry and entry.active and texture.IsShown then
        visible=texture:IsShown()
        if not (issecretvalue and issecretvalue(visible)) and visible then visible=texture:GetParent():IsVisible() end
    else visible=texture:IsVisible() end
    if issecretvalue and issecretvalue(visible) or not visible then return end
    local x,y,w,h=PublicRect(texture)
    local p=texture:GetParent()
    local alpha
    if entry and (entry.active or entry.nativePaint and entry.rgbPublic) then alpha=entry.alpha else alpha=texture:GetAlpha() end
    if not retained and not AlphaPresent(alpha) then return end
    if p.GetEffectiveAlpha and not retained then
        local parentAlpha=p:GetEffectiveAlpha()
        if not PublicNumber(parentAlpha) or parentAlpha<=0 then return end
    end
    local scale=LayoutScale(p,sample)
    if not scale or not (PublicNumber(x) and PublicNumber(y) and PublicNumber(w) and PublicNumber(h)) or w<=0 or h<=0 then return end
    return {x*scale,y*scale,(x+w)*scale,(y+h)*scale}
end
local function SupportsScript(object,script)
    if not object.HookScript or not object.HasScript or object:GetObjectType()=="Texture" then return false end
    local supported=object:HasScript(script)
    return not (issecretvalue and issecretvalue(supported)) and supported==true
end
local function Shown(object)
    local value
    if object.IsShown then value=object:IsShown() else value=object:IsVisible() end
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
local function AvailabilityChain(texture)
    if not fallbackChains then return end
    if issecretvalue and issecretvalue(texture) then return end
    local chains=fallbackChains.ancestry or fallbackChains
    local saved=chains[texture]
    if saved then return saved end
    local unit=StaticUnitOwner(texture)
    local chain,object={},texture
    for _=1,32 do
        if issecretvalue and issecretvalue(object) then return end
        if not object or object==UIParent or object==unit then break end
        chain[#chain+1]=object
        local owner=object._FluxBorderOwner
        if issecretvalue and issecretvalue(owner) then return end
        if owner==unit and unit then break end
        object=object.GetParent and object:GetParent()
    end
    if not fallbackChains.ancestry or #chain<32 then chains[texture]=chain end
    return chain
end
local function CacheAvailable(availability,texture,value)
    if availability then availability[texture]=value end
    return value
end
function J._PublicAncestorGetters(object)
    if type(object)~="table" then return true end
    local shown,visible,alpha=rawget(object,"IsShown"),rawget(object,"IsVisible"),rawget(object,"GetAlpha")
    if issecretvalue and (issecretvalue(shown) or issecretvalue(visible) or issecretvalue(alpha)) then return false end
    return shown==nil and visible==nil and alpha==nil
end
local function PaintAvailable(texture,availability)
    if issecretvalue and issecretvalue(texture) then return false end
    availability=availability or fallbackAvailability
    local saved=availability and availability[texture]
    if saved~=nil then return saved end
    local entry=clipped[texture]
    local ancestors=fallbackChains and fallbackChains.ancestorVisibility
    local chain,ownVisibility
    if not entry and ancestors and ancestors[texture]~=nil then
        chain=AvailabilityChain(texture)
        -- The same frame can also be registered as a fallback observer.
        -- An independent unit root can have an intentionally empty chain.
        if chain and chain[1]==texture then ownVisibility=ancestors[texture] end
    end
    if ownVisibility==nil then
        local alpha
        if entry then alpha=entry.alpha else alpha=texture:GetAlpha() end
        if not AlphaPresent(alpha) then return CacheAvailable(availability,texture,false) end
    elseif not ownVisibility then return CacheAvailable(availability,texture,false) end
    chain=chain or AvailabilityChain(texture)
    if chain then
        for _,object in ipairs(chain) do
            if object==texture then
                if ownVisibility==nil and Shown(object)==false then return CacheAvailable(availability,texture,false) end
            else
                local visible=ancestors and ancestors[object]
                if visible==nil then
                    local shown=Shown(object)
                    visible=shown~=false
                    local public=shown~=nil
                    if visible and object.GetAlpha then
                        local opacity=object:GetAlpha()
                        local readable=PublicNumber(opacity)
                        visible=not readable or opacity>0
                        public=public and readable
                    end
                    -- Ancestor frames are shared by many tile-local sources.
                    -- Only reuse observed public state while drawing these tiles.
                    if ancestors and public and watched[object]=="visibility" and J._PublicAncestorGetters(object) then
                        ancestors[object]=visible
                    end
                end
                if not visible then return CacheAvailable(availability,texture,false) end
            end
        end
        return CacheAvailable(availability,texture,true)
    elseif fallbackChains then return CacheAvailable(availability,texture,false) end
    local unit=StaticUnitOwner(texture)
    local object=texture
    for _=1,32 do
        -- A native watched-unit root governs all its prepared paint together.
        -- Its private existence/fade is never used to choose a Lua paint owner.
        if not object or object==UIParent or object==unit then break end
        if Shown(object)==false then return CacheAvailable(availability,texture,false) end
        if object~=texture and object.GetAlpha then
            local opacity=object:GetAlpha()
            if PublicNumber(opacity) and opacity<=0 then return CacheAvailable(availability,texture,false) end
        end
        if object._FluxBorderOwner==unit and unit then break end
        object=object.GetParent and object:GetParent()
    end
    return CacheAvailable(availability,texture,true)
end
local function PaintFallbackField(field,availability,enabled)
    local source=field._fallbackSource
    local entry=source and clipped[source]
    if not entry or not entry.active or not field._fallbackBlockers then return end
    if enabled==nil then
        enabled=PaintAvailable(source,availability)
        if enabled then
            for _,owner in ipairs(field._fallbackBlockers) do
                if PaintAvailable(owner,availability) then enabled=false;break end
            end
        end
    end
    field._fallbackEnabled=enabled
    if enabled then FieldAlpha(field,entry.alpha) else FieldAlpha(field,0) end
    return enabled
end
local function ApplyOpacity(field,entry,alpha)
    if field._fallbackBlockers then
        if field._fallbackEnabled then FieldAlpha(field,alpha) else FieldAlpha(field,0) end
    elseif entry.sourceShown==false then FieldAlpha(field,0)
    else FieldAlpha(field,alpha) end
end
local function RegisterFallback(field,source,blockers,keepPaint)
    field._fallbackSource=source;field._fallbackBlockers=blockers
    local regional=renderLayers~=nil and fallbackChains~=nil
    local eligible=fallbackChains and not (issecretvalue and (issecretvalue(source) or issecretvalue(blockers)))
        and not (issecrettable and issecrettable(blockers)) and not (canaccesstable and not canaccesstable(blockers))
    local pairs=eligible and fallbackChains._observerPairs
    local sourcePairs=pairs and pairs[source]
    local cached=sourcePairs and sourcePairs[blockers]
    if cached then
        local count=0
        for i,owner in ipairs(blockers) do
            local previous=cached.blockers[i]
            if (issecretvalue and (issecretvalue(owner) or issecretvalue(previous))) or owner~=previous then cached=nil;break end
            count=i
        end
        if cached and count~=#cached.blockers then cached=nil end
    end
    if cached then
        local preceding=regional and fallbackChains.lastListenerPair==cached and fallbackChains.lastListener
        if preceding then
            -- Keep only run heads in the observer lists. The tile owns and
            -- reuses one map of links shared by all its observing frames.
            local links=fallbackChains.listenerNext
            if not links then links={};fallbackChains.listenerNext=links end
            links[preceding]=field
        else
            for _,observation in ipairs(cached) do
                local object=observation[1]
                local list=visibilityListeners[object]
                if not list then list={};visibilityListeners[object]=list end
                list[#list+1]=field;availabilityCache[object]=observation[2]
            end
        end
        if regional then fallbackChains.lastListenerPair,fallbackChains.lastListener=cached,field end
        if not keepPaint then cached.enabled=PaintFallbackField(field,nil,cached.enabled) end
        return
    end
    if regional then fallbackChains.lastListenerPair,fallbackChains.lastListener=nil,nil end
    local observations=eligible and {}
    local seen={}
    local function Observe(texture)
        local chain=AvailabilityChain(texture)
        if chain then
            if #chain>=32 then observations=nil end
            for _,object in ipairs(chain) do if not seen[object] then
                seen[object]=true
                local list=visibilityListeners[object]
                if not list then list={};visibilityListeners[object]=list end
                list[#list+1]=field;availabilityCache[object]=PaintAvailable(object)
                if observations then
                    if #observations<64 then observations[#observations+1]={object,availabilityCache[object]} else observations=nil end
                end
            end end
            return
        elseif fallbackChains then observations=nil;return end
        local unit=StaticUnitOwner(texture)
        local object=texture
        for _=1,32 do
            if not object or object==UIParent or object==unit then break end
            if not seen[object] then
                seen[object]=true
                local list=visibilityListeners[object]
                if not list then list={};visibilityListeners[object]=list end
                list[#list+1]=field
                availabilityCache[object]=PaintAvailable(object)
            end
            if object._FluxBorderOwner==unit and unit then break end
            object=object.GetParent and object:GetParent()
        end
    end
    Observe(source)
    for _,owner in ipairs(blockers) do Observe(owner) end
    if observations then
        local ordered={}
        for i,owner in ipairs(blockers) do
            if i>64 or (issecretvalue and issecretvalue(owner)) then observations=nil;break end
            ordered[i]=owner
        end
        if observations then observations.blockers=ordered end
    end
    local cost=observations and 3+#observations*2+#observations.blockers
    if cost and (fallbackChains._observerCost or 0)+cost<=J.limits.fragments then
        if not pairs then pairs={};fallbackChains._observerPairs=pairs end
        if not sourcePairs then sourcePairs={};pairs[source]=sourcePairs end
        sourcePairs[blockers]=observations
        fallbackChains._observerCost=(fallbackChains._observerCost or 0)+cost
        if regional then fallbackChains.lastListenerPair,fallbackChains.lastListener=observations,field end
        if not keepPaint then observations.enabled=PaintFallbackField(field) end
    elseif not keepPaint then
        PaintFallbackField(field)
    end
end
do
    local function PaintFallbackList(list,availability,regional)
        if regional then
            for cell,fields in pairs(list) do
                local links=cell.visibilityNext
                for _,head in ipairs(fields) do
                    local enabled=PaintFallbackField(head,availability)
                    local field=links and links[head]
                    while field do
                        -- Consecutive fields share the same source and
                        -- blockers. Each still receives fresh source opacity.
                        PaintFallbackField(field,availability,enabled)
                        field=links[field]
                    end
                end
            end
        else
            for _,field in ipairs(list) do PaintFallbackField(field,availability) end
        end
    end
    PaintFallbacks=function(object)
        if painting then
            local ancestors=fallbackChains and fallbackChains.ancestorVisibility
            if ancestors then ancestors[object]=nil end
            return
        end
        local list=visibilityListeners[object]
        if not list then return end
        local available=PaintAvailable(object)
        if availabilityCache[object]==available then return end
        -- Share current source visibility within this one synchronous update.
        painting=true
        local ok,err=pcall(PaintFallbackList,list,{[object]=available},J.stats.localMode)
        painting=false
        if not ok then error(err,0) end
        availabilityCache[object]=available
    end
end
-- Unit roots already own public dimensions and point constraints. Their native
-- computed rectangle may disappear on roster/private-unit transitions while
-- those constraints stay identical. Observe the authored layout instead; real
-- anchor dependencies, point/size/scale/reparent writes still invalidate it.
local function AuthoredUnitLayout(object,owner)
    if owner~=object or not PublicNumber(object._fluxLayoutWidth)
        or not PublicNumber(object._fluxLayoutHeight) or not object.GetSize
        or not object.GetNumPoints or not object.GetPoint then return end
    if type(object)=="table" then
        for _,method in ipairs({"GetRect","GetSize","GetPoint","GetNumPoints","GetEffectiveScale"}) do
            local getter=rawget(object,method)
            if issecretvalue and issecretvalue(getter) or getter~=nil then return end -- foreign getters keep fresh native validation
        end
    end
    local width,height=object:GetSize(true)
    local count=object:GetNumPoints()
    if not PublicNumber(width) or not PublicNumber(height) or width<0 or height<0
        or not PublicNumber(count) or count<1 or count>32 then return end
    local layout={}
    for i=1,count do
        local point,relative,relativePoint,x,y=object:GetPoint(i)
        if issecretvalue and (issecretvalue(point) or issecretvalue(relative)
            or issecretvalue(relativePoint) or issecretvalue(x) or issecretvalue(y)) then return end
        if type(point)~="string" or not anchorFactors[point] or type(relativePoint)~="string"
            or not anchorFactors[relativePoint] or not PublicNumber(x) or not PublicNumber(y) then return end
        if relative==nil then relative=object:GetParent() end
        if issecretvalue and issecretvalue(relative) then return end
        local kind=type(relative)
        if kind~="table" and kind~="userdata" and kind~="string" then return end
        layout[#layout+1]=point;layout[#layout+1]=relative
        layout[#layout+1]=relativePoint;layout[#layout+1]=x;layout[#layout+1]=y
    end
    return layout,width,height
end
local function Snapshot(object)
    if not object.GetRect then return false end
    local unitOwner=StaticUnitOwner(object)
    local layout,w,h=AuthoredUnitLayout(object,unitOwner)
    local x,y=0,0
    if not layout then x,y,w,h=PublicRect(object) end
    local parent=object.GetParent and object:GetParent()
    local scale=object.GetEffectiveScale and object:GetEffectiveScale()
    local shown=Shown(object)
    local entry=clipped[object]
    local alpha=1
    if entry and (entry.active or entry.nativePaint and entry.rgbPublic) then alpha=entry.alpha
    elseif object.GetAlpha then alpha=object:GetAlpha() end
    if issecretvalue and issecretvalue(alpha) then alpha=1 end -- geometry never depends on restricted opacity
    if unitOwner then shown=true;alpha=1 end
    local layer,sublevel
    if object.GetDrawLayer then layer,sublevel=object:GetDrawLayer() end
    local strata=object.GetFrameStrata and object:GetFrameStrata()
    if issecretvalue then
        if issecretvalue(parent) then return false,"restricted parent"
        elseif issecretvalue(x) then return false,"restricted x"
        elseif issecretvalue(y) then return false,"restricted y"
        elseif issecretvalue(w) then return false,"restricted w"
        elseif issecretvalue(h) then return false,"restricted h"
        elseif issecretvalue(scale) then return false,"restricted scale"
        elseif issecretvalue(shown) then return false,"restricted shown"
        elseif issecretvalue(layer) then return false,"restricted layer"
        elseif issecretvalue(sublevel) then return false,"restricted sublevel"
        elseif issecretvalue(strata) then return false,"restricted strata" end
    end
    if not (PublicNumber(x) and PublicNumber(y) and PublicNumber(w) and PublicNumber(h) and PublicNumber(scale) and PublicNumber(alpha)) then return false end
    return {parent or false,x*scale,y*scale,w*scale,h*scale,scale,shown or false,alpha<=0,layer or false,sublevel or 0,strata or false,layout=layout}
end
local function DiagnosticName(object)
    local record=Border._pieces[object]
    local key=record and record.key
    for _=1,12 do
        if not object or object==UIParent then break end
        local name=object.GetName and object:GetName()
        if not (issecretvalue and issecretvalue(name)) and type(name)=="string" and name~="" then
            return name..(key and "."..key or "")
        end
        object=object._FluxBorderOwner or object.GetParent and object:GetParent()
    end
    return key or "unnamed region"
end
local snapshotNames={"parent","x","y","width","height","scale","shown","opacity-zero","layer","sublevel","stratum"}
local function SnapshotReason(object,old,current,unavailable)
    local name=DiagnosticName(object)
    if not old or not current then return name..":"..(unavailable or "geometry availability changed") end
    for i=1,#current do
        local different=i>=2 and i<=5 and abs(old[i]-current[i])>1/64 or (i<2 or i>5) and old[i]~=current[i]
        if different then
            if PublicNumber(old[i]) and PublicNumber(current[i]) then
                return string.format("%s:%s %.3f->%.3f",name,snapshotNames[i],old[i],current[i])
            elseif type(old[i])=="boolean" and type(current[i])=="boolean" then
                return name..":"..snapshotNames[i].." "..tostring(old[i]).."->"..tostring(current[i])
            end
            return name..":"..snapshotNames[i].." changed"
        end
    end
    return name..(current.layout and ":authored unit anchors changed" or ":snapshot changed")
end
local function SameSnapshot(a,b)
    if a==b then return true end
    if not a or not b then return false end
    if (a.layout~=nil)~=(b.layout~=nil) then return false end
    if a.layout then
        if #a.layout~=#b.layout then return false end
        for i,value in ipairs(a.layout) do if value~=b.layout[i] then return false end end
    end
    for i=1,#a do
        if i>=2 and i<=5 then
            if abs(a[i]-b[i])>1/64 then return false end
        elseif a[i]~=b[i] then return false end
    end
    return true
end
local function AnchorObject(relative)
    if issecretvalue and issecretvalue(relative) then return nil,true end
    if relative==nil then return end
    if type(relative)=="string" then relative=_G[relative] end
    if issecretvalue and issecretvalue(relative) then return nil,true end
    local kind=type(relative)
    if (kind=="table" or kind=="userdata") and relative.GetParent and relative.GetRect then return relative end
    return nil,true
end
-- These links select observer bookkeeping only. Every real ReadLayout still
-- reads all current native source rectangles, including unrelated private or
-- unavailable regions; no public coordinate tuple survives between phases.
local observerLinks=setmetatable({}, {__mode="k"})
local observerDependents=setmetatable({}, {__mode="k"})
local observerUnsafe=setmetatable({}, {__mode="k"})
local observerGraph={revision=0,pending=setmetatable({}, {__mode="k"}),weakKeys={__mode="k"}}
local function RefreshObserverLinks(object,scratch)
    local links=scratch or setmetatable({},observerGraph.weakKeys)
    local unsafe=false
    local function Add(relative)
        local target,unknown=AnchorObject(relative)
        if target then links[target]=true elseif unknown then unsafe=true end
    end
    if object.GetParent then Add(object:GetParent()) end
    if object.GetNumPoints and object.GetPoint then
        local count=object:GetNumPoints()
        if PublicNumber(count) and count>=0 and count<=32 then
            for i=1,count do local _,relative=object:GetPoint(i);Add(relative) end
        else unsafe=true end
    else unsafe=true end
    local old=observerLinks[object]
    unsafe=unsafe or nil
    local changed=not old or observerUnsafe[object]~=unsafe
    if old then
        for relative in pairs(old) do
            if not links[relative] then
                observerDependents[relative][object]=nil
                changed=true
            end
        end
    end
    for relative in pairs(links) do
        if not (old and old[relative]) then
            local dependents=observerDependents[relative]
            if not dependents then dependents=setmetatable({}, {__mode="k"});observerDependents[relative]=dependents end
            dependents[object]=true
            changed=true
        end
    end
    if changed then
        if scratch then
            -- Publish a separate weak set only when the final links differ.
            links=setmetatable({},observerGraph.weakKeys)
            for relative in pairs(scratch) do links[relative]=true end
        end
        observerLinks[object]=links
        observerUnsafe[object]=unsafe
        observerGraph.revision=observerGraph.revision+1
        return links
    end
end
local function RefreshObserverDependents(refresh,object)
    if refresh.all then return end
    -- Many changed anchors share descendants. A completed branch can be
    -- reused within this refresh until an anchor or parent rewires the graph.
    if refresh.revision~=observerGraph.revision then
        refresh.revision=observerGraph.revision
        refresh.completed={}
    end
    local completed=refresh.completed
    if completed[object] then return end
    -- Store work and exit markers in the same flat stack. The frontier limit
    -- still counts nodes, including queued visits to a shared descendant.
    local stack,visiting={object,false},{}
    local top,count,limit=2,0,J.limits.segments*4
    while top>0 do
        local current,leaving=stack[top-1],stack[top]
        stack[top-1],stack[top]=nil,nil
        top=top-2
        if leaving then visiting[current]=nil;completed[current]=true
        elseif completed[current] then -- This branch is already in refresh.items.
        elseif visiting[current] or observerUnsafe[current] then refresh.all=true;return
        else
            count=count+1
            if count>limit or top>limit*2 then refresh.all=true;return end
            visiting[current]=true;refresh.items[current]=true
            stack[top+1],stack[top+2]=current,true
            top=top+2
            local dependents=observerDependents[current]
            if dependents then
                for dependent in pairs(dependents) do
                    stack[top+1],stack[top+2]=dependent,false
                    top=top+2
                end
            end
        end
    end
end
local function Watch(object)
    if not object or object==UIParent or watched[object] then return end
    watched[object]=true
    observed[object]=Snapshot(object)
    local show,hide=SupportsScript(object,"OnShow"),SupportsScript(object,"OnHide")
    if show then object:HookScript("OnShow",function() PaintFallbacks(object);if not StaticUnitFrame(object) then J:Invalidate(nil,object) end end) end
    if hide then
        object:HookScript("OnHide",function() PaintFallbacks(object);if not StaticUnitFrame(object) then J:Invalidate(nil,object) end end)
    end
    if SupportsScript(object,"OnSizeChanged") then
        object:HookScript("OnSizeChanged",function()
            J:Invalidate(nil,object)
        end)
    end
    if hooksecurefunc then
        for _,method in ipairs({"SetPoint","SetAllPoints","ClearAllPoints","SetSize","SetWidth","SetHeight","SetScale","SetParent","SetFrameStrata","SetFrameLevel","SetDrawLayer"}) do
            local reparent=method=="SetParent"
            local anchors=reparent or method=="SetPoint" or method=="SetAllPoints" or method=="ClearAllPoints"
            if object[method] then hooksecurefunc(object,method,function()
                if reparent and Border.RefreshPaintOwners then Border:RefreshPaintOwners(object) end
                if anchors then observerGraph.pending[object]=true end
                J:Invalidate(nil,object)
            end) end
        end
        -- Frame scripts already report real transitions. Textures need a guarded
        -- method observer; repeated Show/Hide must never dismantle valid joins.
        local texture=object:GetObjectType()=="Texture"
        if texture then
            local shown=Shown(object)
            for _,method in ipairs({"Show","Hide","SetShown"}) do
                if object[method] then hooksecurefunc(object,method,function()
                    if painting then return end
                    local current=Shown(object)
                    if current==nil then return end
                    if current==shown then return end
                    shown=current
                    if StaticUnitOwner(object) then
                        local entry=clipped[object]
                        if entry then
                            entry.sourceShown=current
                            local function Paint(t)
                                if current then ApplyOpacity(t,entry,entry.alpha) else t:SetAlpha(0) end
                            end
                            painting=true
                            for _,t in ipairs(entry.pool) do Paint(t) end
                            for _,list in J._ColorLists(object) do
                                for _,t in ipairs(list) do if t._junctionOwnerOp then Paint(t) end end
                            end
                            painting=false
                        end
                        PaintFallbacks(object)
                        return
                    end
                    J:Invalidate(nil,object)
                end) end
            end
        end
        if object.SetAlpha then
            local initial=1
            if object.GetAlpha then initial=object:GetAlpha() end
            local zero=not AlphaPresent(initial)
            hooksecurefunc(object,"SetAlpha",function(_,value)
                if painting then
                    local ancestors=not texture and fallbackChains and fallbackChains.ancestorVisibility
                    if ancestors then ancestors[object]=nil end
                    return
                end
                local managed=Border._pieces[object]
                if not managed or not managed.junctionWatched then PaintFallbacks(object) end
                local current=not AlphaPresent(value)
                local crossing=zero~=current
                zero=current
                if crossing and not StaticUnitFrame(object) then
                    J:Invalidate(nil,object)
                end
            end)
            if show and hide and not texture and object.GetAlpha then watched[object]="visibility" end
        end
    end
    -- Parent and current sibling/slot anchors are dependencies even when a
    -- replacement anchor leaves this object's current rectangle unchanged.
    for reference in pairs(RefreshObserverLinks(object)) do Watch(reference) end
end
-- A clear-and-reanchor burst describes one layout. Read the final links before
-- walking dependencies, including any anchors just changed by panel alignment.
function J._RefreshObserverLinks()
    local pending=observerGraph.pending
    if not next(pending) then return end
    observerGraph.pending=setmetatable({}, {__mode="k"})
    local scratch={}
    for object in pairs(pending) do
        local links=RefreshObserverLinks(object,scratch)
        for relative in pairs(scratch) do scratch[relative]=nil end
        if links then for reference in pairs(links) do Watch(reference) end end
    end
end
function J:PaintChanged(texture)
    local entry=clipped[texture]
    if entry and entry.active then
        local path=texture:GetTexture()
        local record=Border._pieces[texture]
        local art=record and record.art
        local canonical=type(art)=="string" and art:sub(1,#PATH)==PATH and art:match("%.tga$")
            or type(path)=="string" and path:sub(1,#PATH)==PATH and path:match("%.tga$")
        if not (issecretvalue and issecretvalue(path)) and canonical and (type(path)=="string" or type(path)=="number")
            and path~=entry.path then
            -- All registered styles use the same canonical UV canvas. Material
            -- changes must reach visible class-colored pieces in this Lua call,
            -- rather than waiting for a structural rebuild of unchanged geometry.
            painting=true
            for _,fragment in ipairs(entry.pool) do
                fragment:SetTexture(path)
                if fragment._junctionUV then fragment:SetTexCoord(unpack(fragment._junctionUV)) end
            end
            for _,list in J._ColorLists(texture) do
                for _,sprite in ipairs(list) do
                    if sprite._junctionOwnerOp then
                        sprite:SetTexture(path)
                        if sprite._junctionUV then sprite:SetTexCoord(unpack(sprite._junctionUV)) end
                    end
                end
            end
            entry.path=path;painting=false
        end
        paintDirty[texture]=true;self:Invalidate(nil,texture)
    end
end
-- Unit opacity is an approved native sink (SimpleRegion.SetAlpha explicitly
-- allows secret arguments when tainted). Keep geometry/RGB public; pass opaque
-- alpha only to SetAlpha, never compare, format, order or use it as a condition.
local function UnitPaint(texture,entry,r,g,b,a)
    if not entry then entry={pool={}};clipped[texture]=entry end
    if not (issecretvalue and issecretvalue(a)) and a==nil then a=1 end
    local publicAlpha=PublicNumber(a) and a or 1
    local changed=entry.nativeRGB or not SameColor(entry.color,r,g,b,publicAlpha)
    entry.nativeRGB=nil
    -- Only identical public authored RGBA can reuse the committed paint.
    -- Opaque current or previous alpha must still reach every native sink.
    local sameAlpha=PublicNumber(entry.alpha) and PublicNumber(a) and entry.alpha==a
    entry.nativePaint=true;entry.rgbPublic=true
    local color=entry.color
    if not color then color={};entry.color=color end
    color[1],color[2],color[3],color[4]=r,g,b,publicAlpha;entry.alpha=a
    if issecretvalue and issecretvalue(a) then J.stats.privateAlphaWrites=(J.stats.privateAlphaWrites or 0)+1 end
    if entry.active then
        painting=true
        if changed or not sameAlpha then
            for _,fragment in ipairs(entry.pool) do
                if changed then FieldColor(fragment,unpack(color)) end
                ApplyOpacity(fragment,entry,a)
            end
            for _,list in J._ColorLists(texture) do
                for _,sprite in ipairs(list) do
                    if sprite._junctionOwnerOp then
                        if changed then FieldColor(sprite,unpack(color)) end
                        ApplyOpacity(sprite,entry,a)
                    end
                end
            end
        end
        -- Native recolor exposes the original texture even when RGBA matches.
        -- Suppression and fallback ownership therefore remain unconditional.
        texture:SetAlpha(0);painting=false
    end
    if entry.waitingAlpha or entry.waitingColor then J:Invalidate(nil,texture)
    end
    PaintFallbacks(texture)
    return entry
end
-- Opt-in class RGB can be forwarded through prepared unit fields just like
-- native alpha, without retiring a component or reading protected geometry.
local function NativeUnitRGB(texture,entry,r,g,b,a)
    if not entry then entry={pool={},color={1,1,1,1}};clipped[texture]=entry end
    if not (issecretvalue and issecretvalue(a)) and a==nil then a=1 end
    entry.nativePaint=true;entry.rgbPublic=true;entry.nativeRGB=true;entry.alpha=a
    entry.color=entry.color or {1,1,1,1}
    entry.color[4]=PublicNumber(a) and a or 1
    J.stats.privateColorWrites=(J.stats.privateColorWrites or 0)+1
    if entry.active then
        painting=true
        for _,field in ipairs(entry.pool) do FieldColor(field,r,g,b,1);ApplyOpacity(field,entry,a) end
        for _,list in J._ColorLists(texture) do
            for _,field in ipairs(list) do
                if field._junctionOwnerOp then FieldColor(field,r,g,b,1);ApplyOpacity(field,entry,a) end
            end
        end
        texture:SetAlpha(0);painting=false
    end
    PaintFallbacks(texture)
end

function J:Adopt(texture,record)
    if Border.RefreshPaintOwners then Border:RefreshPaintOwners(texture) end
    if not texture.GetParent or not texture.GetAlpha or not texture.SetAlpha then return end
    local parent=texture:GetParent()
    if not parent or not parent.CreateTexture then return end
    local oldParent=record.junctionParent
    if oldParent and oldParent~=parent then registrationParents[oldParent]=true end
    record.junctionParent=parent
    ContinuousSampling(texture)
    local g=groups[parent]
    if not g then nextID=nextID+1;g={parent=parent,id=nextID};groups[parent]=g end
    local already=g[texture]==record
    if not record.junctionID then nextPieceID=nextPieceID+1;record.junctionID=nextPieceID end
    g[texture]=record
    record.staticUnit=StaticUnitOwner(texture)
    if record.staticUnit then
        local r,g,b,a=texture:GetVertexColor()
        if PublicNumber(r) and PublicNumber(g) and PublicNumber(b) and not clipped[texture] then UnitPaint(texture,nil,r,g,b,a) end
    end
    if not record.junctionWatched and hooksecurefunc then
        record.junctionWatched=true
        hooksecurefunc(texture,"SetVertexColor",function(_,r,g,b,a)
            if painting then
                local suppressed=renderBases and renderBases.suppressedSources
                if suppressed and suppressed[texture] then suppressed[texture]=false end
                return
            end
            local entry=clipped[texture]
            if record.staticUnit and PublicNumber(r) and PublicNumber(g) and PublicNumber(b) then
                UnitPaint(texture,entry,r,g,b,a);return
            end
            if record.staticUnit and texture._FluxBorderNativeUnitRGB then
                NativeUnitRGB(texture,entry,r,g,b,a);return
            end
            if issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b) or issecretvalue(a)) then
                if not entry then entry={pool={}};clipped[texture]=entry end
                J.stats.privateColorWrites=(J.stats.privateColorWrites or 0)+1
                entry.rgbPublic=false
                if not entry.waitingColor then
                    entry.rgbPublic=false;entry.waitingColor=true;entry.waitingRetire=true;J:ReleaseFor(texture,texture);J:Invalidate(nil,texture)
                end
                return
            end
            if entry and entry.waitingColor then J:Invalidate(nil,texture) end
            if entry and entry.active then
                if a==nil then a=1 end
                local changed=not SameColor(entry.color,r,g,b,a)
                local crossing=AlphaPresent(entry.alpha)~=AlphaPresent(a)
                entry.alpha=a
                entry.color[1],entry.color[2],entry.color[3],entry.color[4]=r,g,b,a
                -- Native textures share SetAlpha and SetVertexColor's alpha.
                -- Even an identical color write exposes the suppressed source.
                painting=true
                if changed then
                    for _,t in ipairs(entry.pool) do FieldColor(t,r,g,b,a);ApplyOpacity(t,entry,a) end
                    for _,list in J._ColorLists(texture) do
                        for _,t in ipairs(list) do
                            if t._junctionOwnerOp then FieldColor(t,r,g,b,a);ApplyOpacity(t,entry,a) end
                        end
                    end
                end
                texture:SetAlpha(0);painting=false
                if crossing then J:Invalidate(nil,texture) end
            elseif observed[texture] and PublicNumber(a or 1) and observed[texture][8]~=((a or 1)<=0) then
                J:Invalidate(nil,texture)
            end
            PaintFallbacks(texture)
        end)
        hooksecurefunc(texture,"SetAlpha",function(_,alpha)
            if painting then
                local suppressed=renderBases and renderBases.suppressedSources
                if suppressed and suppressed[texture] then suppressed[texture]=false end
                return
            end
            local entry=clipped[texture]
            if record.staticUnit and entry and entry.nativePaint and entry.rgbPublic then
                local sameAlpha=PublicNumber(entry.alpha) and PublicNumber(alpha) and entry.alpha==alpha
                entry.alpha=alpha;entry.color[4]=PublicNumber(alpha) and alpha or 1
                if issecretvalue and issecretvalue(alpha) then J.stats.privateAlphaWrites=(J.stats.privateAlphaWrites or 0)+1 end
                if entry.active then
                    painting=true
                    if not sameAlpha then
                        for _,fragment in ipairs(entry.pool) do
                            ApplyOpacity(fragment,entry,alpha)
                        end
                        for _,list in J._ColorLists(texture) do
                            for _,sprite in ipairs(list) do if sprite._junctionOwnerOp then
                                ApplyOpacity(sprite,entry,alpha)
                            end end
                        end
                    end
                    texture:SetAlpha(0);painting=false
                end
                PaintFallbacks(texture)
                return
            end
            if issecretvalue and issecretvalue(alpha) then
                if not entry then entry={pool={}};clipped[texture]=entry end
                J.stats.privateAlphaWrites=(J.stats.privateAlphaWrites or 0)+1
                if not entry.waitingAlpha then
                    entry.waitingAlpha=true;entry.waitingRetire=true;J:ReleaseFor(texture,texture);J:Invalidate(nil,texture)
                end
                return
            end
            if entry and entry.waitingAlpha then J:Invalidate(nil,texture) end
            if entry and entry.active then
                entry.alpha=alpha;entry.color[4]=alpha;painting=true
                for _,t in ipairs(entry.pool) do ApplyOpacity(t,entry,alpha) end
                for _,list in J._ColorLists(texture) do
                    for _,t in ipairs(list) do
                        if t._junctionOwnerOp then ApplyOpacity(t,entry,alpha) end
                    end
                end
                texture:SetAlpha(0);painting=false
            end
            PaintFallbacks(texture)
        end)
        for _,method in ipairs({"SetTexture","SetAtlas","SetTexCoord","AddMaskTexture","RemoveMaskTexture"}) do
            if texture[method] then hooksecurefunc(texture,method,function()
                if not painting then J:PaintChanged(texture) end
            end) end
        end
    end
    Watch(texture);Watch(parent)
    if already then self:Invalidate(nil,texture)
    else registrationDirty=true;registrationParents[parent]=true;self:Invalidate(nil,texture,idleTrace and "new pieces: "..DiagnosticName(parent)) end
end
function J:Forget(texture)
    if self._ClearAlternatePlans then self:_ClearAlternatePlans() end
    local record=Border._pieces[texture]
    local p=record and record.junctionParent or texture.GetParent and texture:GetParent()
    if record then record.junctionParent=nil end
    local g=p and groups[p]
    if g then g[texture]=nil end
    registrationParents[p or false]=true
    -- Restore original paint before its parent can be detached or recycled.
    if not (self._ForgetLocality and self:_ForgetLocality(texture)) then self:ReleaseFor(texture) end
    registrationDirty=true;previous=nil;self:Invalidate(nil,texture,idleTrace and "removed pieces: "..DiagnosticName(p or texture))
end
function J:SetOverlay(frame,enabled)
    enabled=enabled and true or nil
    if frame._FluxBorderOverlay==enabled then return end
    frame._FluxBorderOverlay=enabled
    if enabled then self:ReleaseFor(frame) end
    previous=nil;self:Invalidate(nil,nil,idleTrace and "overlay changed: "..DiagnosticName(frame))
end

local function Color(g)
    local p=g.parent
    if p._junctionColor then return unpack(p._junctionColor) end
    local r,gc,b=Border:GetAccentColor()
    for _,item in ipairs(g.pieces or {}) do
        local record=item.record
        if record.themed then
            if Border:GetBorderType()==1 then return unpack(record.color) end
            return r,gc,b,record.alpha
        end
    end
    return r,gc,b,1
end
function J:Recolor(parent,r,g,b,a)
    if not (PublicNumber(r) and PublicNumber(g) and PublicNumber(b)) then return end
    local c=parent._junctionColor or {}
    if SameColor(c,r,g,b,a) then return end
    c[1],c[2],c[3],c[4]=r,g,b,a
    parent._junctionColor=c
    for _,pool in J._FieldLists(sprites[parent]) do
        for _,sprite in ipairs(pool) do
            if sprite._junctionOwnerOp and sprite._junctionSource:GetParent()==parent then
                FieldColor(sprite,r,g,b,PublicNumber(a) and a or 1)
                local entry=clipped[sprite._junctionSource]
                if entry then ApplyOpacity(sprite,entry,a) end
            end
        end
    end
end
local function ReadLayout(filter,retained)
    local segments,signature={},{groups={},count=0}
    if filter and retained then for _,segment in ipairs(retained) do
        if not filter[segment.group.parent] then segments[#segments+1]=segment end
    end end
    local currentTracks=Border.GetJoinTracks and Border:GetJoinTracks() or tracks[Border:GetBorderType()] or tracks[1]
    local dividerHalfWidth
    local function KeepStamps(g)
        local stamps=g._layoutStamps
        if stamps and #stamps>0 then
            signature.groups[g.id]=stamps
            signature.count=signature.count+1
        end
    end
    -- The outline and its additional runs are read consecutively. Share
    -- public parent geometry within this read while keeping each run's ID
    -- and retained paint priority independent.
    local sampledParent, parentLayout=nil,{}
    local function ReadParentLayout(parent)
        if sampledParent==parent then return true end
        local castSection
        local ancestor=parent
        for _=1,32 do
            if not ancestor or ancestor==UIParent then break end
            if ancestor._FluxBorderCast or ancestor._FluxBorderCastInternalSide then castSection=true;break end
            ancestor=ancestor.GetParent and ancestor:GetParent()
        end
        local owner=parent
        local unitOwner,stripRoot
        local fixedBounds,actionStrip,hudPanel=false,false,false
        local scope,miniScope
        while owner and owner~=UIParent do
            if FixedPanel(owner) then fixedBounds=true end
            if owner._FluxBorderHUD then hudPanel=true end
            if owner._FluxBorderJunctionRole=="connected" then scope=owner end
            if owner==_G.FluxActionStrip or owner==_G.FluxMainActionBar then actionStrip=true;stripRoot=owner end
            local logical=owner._FluxBorderOwner or owner
            if logical._FluxBorderIndependent then scope=scope or logical end
            local unit=logical.unit
            if not (issecretvalue and issecretvalue(unit)) and type(unit)=="string" then
                if unitOwner and unitOwner~=unit then break end
                unitOwner=unit
                if not IsMiniUnit(unit) then break end
                -- Pet and target-of-target blocks remain independent overlays,
                -- but their own base/atlas/outer outlines still deduplicate.
                -- Detached atlas hosts resolve to the same logical unit root.
                miniScope=logical
            end
            owner=logical.GetParent and logical:GetParent()
        end
        scope=scope or miniScope
        local strata=parent:GetFrameStrata()
        if issecretvalue and issecretvalue(strata) then return end
        local scale=LayoutScale(parent,parentLayout)
        local x,y=PublicOrigin(parent)
        if not scale or not (PublicNumber(x) and PublicNumber(y)) then return end
        local level=parent.GetFrameLevel and parent:GetFrameLevel() or 0
        if not PublicNumber(level) then return end
        parentLayout.scale,parentLayout.x,parentLayout.y=scale,x*scale,y*scale
        parentLayout.unitOwner,parentLayout.castSection=unitOwner,castSection
        parentLayout.fixedBounds,parentLayout.actionStrip,parentLayout.stripRoot,parentLayout.hudPanel=fixedBounds,actionStrip,stripRoot,hudPanel
        parentLayout.scope=scope
        parentLayout.independentScope=scope and scope._FluxBorderIndependent==true or nil
        parentLayout.priority=(STRATA[strata] or 3)*65536+level
        parentLayout.plane=(hudPanel or strata=="BACKGROUND" or strata=="LOW" or strata=="MEDIUM") and "HUD" or strata
        sampledParent=parent
        return true
    end
    local function AddGroup(g,pieces,full)
        local stamps={}
        g._layoutStamps=stamps
        local parent=g.parent
        if not ReadParentLayout(parent) then return end
        local layout=parentLayout
        g.scale,g.x,g.y=layout.scale,layout.x,layout.y
        g.unitOwner,g.castSection=layout.unitOwner,layout.castSection
        g.fixedBounds,g.actionStrip,g.stripRoot,g.hudPanel=layout.fixedBounds,layout.actionStrip,layout.stripRoot,layout.hudPanel
        g.independentScope=layout.independentScope
        -- Temporary combat/highlight frame levels must not change the mesh's
        -- paint owner or weld centers. Settings refresh explicitly resets this.
        g.paintPriority=g.paintPriority or layout.priority
        g.priority=g.paintPriority
        g.plane=layout.plane
        local scope=layout.scope
        if scope then
            if not scopeIDs[scope] then nextID=nextID+1;scopeIDs[scope]=nextID end
            g.plane=g.plane..":overlay"..scopeIDs[scope]
        end
        g.pieces=pieces
        local bounds={}
        for _,item in ipairs(pieces) do
            item.group=g
            local key,r=item.record.key,item.rect
            if key=="Top" or key=="Bottom" then item.position=r[4]-currentTracks[key]/(key=="Top" and 17 or 16)*(r[4]-r[2])
            elseif key=="Left" or key=="Right" then item.position=r[1]+currentTracks[key]/16*(r[3]-r[1]) end
            bounds[key]=item.position
        end
        -- An attached mini has one deliberately open end. Retain its complete
        -- frame identity and outside-cap protection; the horizontal endpoint
        -- supplies the missing vertical track without inventing a new stroke.
        local open=parent._fluxAttachmentSide
        if full and (open=="Left" or open=="Right") then
            for _,item in ipairs(pieces) do
                if item.record.key=="Top" then bounds[open]=item.rect[open=="Left" and 1 or 3];break end
            end
        end
        for _,item in ipairs(pieces) do
            local key,r=item.record.key,item.rect
            item.cornerX=nil;item.cornerY=nil
            if full and capSides[key] then
                item.cornerX=bounds[(key=="TL" or key=="BL") and "Left" or "Right"]
                item.cornerY=bounds[(key=="TL" or key=="TR") and "Top" or "Bottom"]
            end
            if item.position then
                local horizontal=key=="Top" or key=="Bottom"
                local s={group=g,item=item,side=key,texture=item.texture,axis=horizontal and "H" or "V",p=item.position,rect=r,paintID=item.record.junctionID}
                s.a=horizontal and (full and bounds.Left or r[1]) or (full and bounds.Bottom or r[2])
                s.b=horizontal and (full and bounds.Right or r[3]) or (full and bounds.Top or r[4])
                s.scale=horizontal and (r[4]-r[2])/(key=="Top" and 17 or 16) or (r[3]-r[1])/16
                if item.texture._FluxBorderRunCaps then
                    s.a=s.a+(horizontal and currentTracks.Left or 16-currentTracks.Bottom)*s.scale
                    s.b=s.b-(horizontal and 16-currentTracks.Right or currentTracks.Top)*s.scale
                    item.paintRect=horizontal and {s.a,r[2],s.b,r[4]} or {r[1],s.a,r[3],s.b}
                end
                if not horizontal and key==parent._FluxBorderCastInternalSide then
                    if not dividerHalfWidth then
                        local thickness=Border.GetBorderThickness and Border:GetBorderThickness() or 100
                        dividerHalfWidth=thickness/100
                    end
                    -- Preserve the authored shoulder on the icon side while
                    -- keeping the outside bevel off the fill.
                    local iconWidth=(currentTracks.CastDividerIconWidth or dividerHalfWidth)*s.scale
                    local fillWidth=dividerHalfWidth*s.scale
                    local rect=item.paintRect or r
                    item.paintRect={max(rect[1],s.p-iconWidth),rect[2],min(rect[3],s.p+fillWidth),rect[4]}
                end
                if s.b>s.a then segments[#segments+1]=s end
            end
            local layer,sublevel=item.texture:GetDrawLayer()
            item.drawLayer,item.sublevel=layer,sublevel
            stamps[#stamps+1]=key..":"..table.concat(r,",")..":"..g.plane..":"..g.priority..":"..layer..":"..(sublevel or 0)..":"..(g.unitOwner or "-")..":"..tostring(g.actionStrip)
        end
        if #stamps>1 then table.sort(stamps) end
        KeepStamps(g)
    end
    for parent,g in pairs(groups) do
        if filter and not filter[parent] then
            KeepStamps(g)
            for _,child in pairs(g.children or {}) do KeepStamps(child) end
        else
        g._layoutStamps=nil
        for _,child in pairs(g.children or {}) do child._layoutStamps=nil end
        if not Role(parent) then
            local pieces,keys={},{}
            for texture,record in pairs(g) do
                if type(record)=="table" and Border._pieces[texture]==record then
                    if texture:GetParent()~=parent then
                        g[texture]=nil;J:Adopt(texture,record)
                    else
                        local rect=Geometry(texture,parentLayout)
                        if rect then
                            pieces[#pieces+1]={texture=texture,record=record,rect=rect}
                            keys[record.key]=true
                        end
                    end
                end
            end
            local full=keys.TL and keys.TR and keys.BL and keys.BR and keys.Top and keys.Bottom and keys.Left and keys.Right
            local framePieces,used={},{}
            local open=parent._fluxAttachmentSide
            local openFrame=#pieces==5 and keys.Top and keys.Bottom
                and (open=="Left" and keys.TR and keys.BR and keys.Right
                    or open=="Right" and keys.TL and keys.BL and keys.Left)
            if openFrame then
                AddGroup(g,pieces,true)
                for _,item in ipairs(pieces) do used[item]=true end
                full=true
            elseif full then
                local byKey={}
                for _,item in ipairs(pieces) do
                    local key=item.record.key
                    byKey[key]=byKey[key] or {};table.insert(byKey[key],item)
                end
                -- A frame may also own HP/resource or status dividers. Identify
                -- its eight outer pieces without treating the extra edge as a
                -- reason to discard all four corner connections.
                for _,key in ipairs({"TL","TR","BL","BR"}) do
                    if #byKey[key]~=1 then full=false;break end
                    framePieces[#framePieces+1]=byKey[key][1];used[byKey[key][1]]=true
                end
                if full then
                    local targets={Top={byKey.TL[1].rect[4],4},Bottom={byKey.BL[1].rect[2],2},
                        Left={byKey.TL[1].rect[1],1},Right={byKey.TR[1].rect[3],3}}
                    for _,key in ipairs({"Top","Bottom","Left","Right"}) do
                        local target=targets[key];local chosen,distance
                        for _,item in ipairs(byKey[key]) do
                            local d=abs(item.rect[target[2]]-target[1])
                            if not distance or d<distance then chosen,distance=item,d end
                        end
                        framePieces[#framePieces+1]=chosen;used[chosen]=true
                    end
                    AddGroup(g,framePieces,true)
                end
            end
            if not full then used={} end
            do
                -- A shared statusbar/icon parent can own several Left/Top pieces.
                -- They are distinct structural runs, never one overwritten key.
                g.children=g.children or setmetatable({}, {__mode="k"})
                for _,item in ipairs(pieces) do
                    if not used[item] then
                    local child=g.children[item.texture]
                    if not child then nextID=nextID+1;child={parent=parent,id=nextID,paintID=g.id};g.children[item.texture]=child end
                    AddGroup(child,{item},false)
                    end
                end
            end
        end
    end
    end
    return segments,signature
end

local function SameLayout(a,b)
    if not b or a.appearance~=b.appearance or a.count~=b.count then return false end
    for id,stamps in pairs(a.groups) do
        local prior=b.groups[id]
        if stamps~=prior then
            if not prior or #stamps~=#prior then return false end
            for i,stamp in ipairs(stamps) do if stamp~=prior[i] then return false end end
        end
    end
    return true
end

-- Public geometry-only rectangle subtraction. Disjoint fragments preserve the
-- original UV field, so a corner with four joins needs no mask (native limit=3).
function J:Subtract(rectangles,cut)
    local result,last
    local cutLeft,cutBottom,cutRight,cutTop=cut[1],cut[2],cut[3],cut[4]
    for i=1,#rectangles do
        local r=rectangles[i]
        local left,bottom,right,top=r[1],r[2],r[3],r[4]
        if left<cutRight and right>cutLeft and bottom<cutTop and top>cutBottom then
            if not result then
                result={}
                last=i-1
                for j=1,last do result[j]=rectangles[j] end
            end
            local innerLeft=left>cutLeft and left or cutLeft
            local innerRight=right<cutRight and right or cutRight
            local innerBottom=bottom>cutBottom and bottom or cutBottom
            local innerTop=top<cutTop and top or cutTop
            if left<innerLeft then last=last+1;result[last]={left,bottom,innerLeft,top} end
            if innerRight<right then last=last+1;result[last]={innerRight,bottom,right,top} end
            if bottom<innerBottom then last=last+1;result[last]={innerLeft,bottom,innerRight,innerBottom} end
            if innerTop<top then last=last+1;result[last]={innerLeft,innerTop,innerRight,top} end
        elseif result then
            last=last+1
            result[last]=r
        end
    end
    return result or rectangles
end
local function SliceUV(uv,r,f)
    local x1,x2=(f[1]-r[1])/(r[3]-r[1]),(f[3]-r[1])/(r[3]-r[1])
    local y1,y2=(r[4]-f[4])/(r[4]-r[2]),(r[4]-f[2])/(r[4]-r[2])
    if #uv==4 then
        return {uv[1]+(uv[2]-uv[1])*x1,uv[1]+(uv[2]-uv[1])*x2,
            uv[3]+(uv[4]-uv[3])*y1,uv[3]+(uv[4]-uv[3])*y2}
    end
    local function Point(x,y)
        return uv[1]*(1-x)*(1-y)+uv[3]*(1-x)*y+uv[5]*x*(1-y)+uv[7]*x*y,
            uv[2]*(1-x)*(1-y)+uv[4]*(1-x)*y+uv[6]*x*(1-y)+uv[8]*x*y
    end
    local a,b=Point(x1,y1);local c,d=Point(x1,y2);local e,f=Point(x2,y1);local g,h=Point(x2,y2)
    return {a,b,c,d,e,f,g,h}
end
J.SliceUV=SliceUV
-- Only these authored canonical cells have known, exactly zero-alpha margins.
-- Coordinates include the half-texel bilinear fringe. They are not a guessed
-- opacity threshold and never apply to a foreign path, handle or UV field.
local visibleSupport={
    Top={uv={1/256,209/256,1/256,18/256},band={3.5/17,13.5/17}},
    Bottom={uv={1/256,209/256,20/256,36/256},band={2.5/16,12.5/16}},
    Left={uv={1/256,17/256,38/256,172/256},band={6.5/16,14.5/16}},
    Right={uv={19/256,35/256,38/256,172/256},band={5.5/16,12.5/16}},
}
local function SourceSupport(key,uv)
    local profile=visibleSupport[key]
    if not profile then return end
    local c=profile.uv
    if #uv==4 then
        if uv[1]~=c[1] or uv[2]~=c[2] or uv[3]~=c[3] or uv[4]~=c[4] then return end
    elseif uv[1]~=c[1] or uv[2]~=c[3] or uv[3]~=c[1] or uv[4]~=c[4]
        or uv[5]~=c[2] or uv[6]~=c[3] or uv[7]~=c[2] or uv[8]~=c[4] then return end
    return profile.band
end
local Source
do
local sourceStyles={
    [PATH.."Battlefield100.tga"]=1,
    [PATH.."ForeverMetal150.tga"]=2,
    [PATH.."ForeverMetal150Tint.tga"]=2,
}

local function ReadUnmaskedSourcePath(texture)
    local path=texture:GetTexture()
    if issecretvalue and issecretvalue(path) then return end
    if not path and texture.GetTextureFileID then path=texture:GetTextureFileID() end
    if issecretvalue and issecretvalue(path) then return end
    if type(path)~="string" and type(path)~="number" then return end
    if path==0 or path=="" then return end
    if texture.GetNumMaskTextures then
        local masks=texture:GetNumMaskTextures()
        if not PublicNumber(masks) or masks>0 then return end
    end
    return path
end

local function ReadSourcePaint(texture)
    local entry=clipped[texture]
    -- Suppressing a native texture also zeros GetVertexColor's fourth return.
    -- Rebuild from the author's cached RGBA, never the hidden source's alpha.
    local authorized=entry and (entry.active or entry.nativePaint and entry.rgbPublic)
    local color=authorized and {unpack(entry.color)} or {texture:GetVertexColor()}
    for i=1,4 do if not PublicNumber(color[i]) then return end end
    local alpha
    if authorized then alpha=entry.alpha else alpha=texture:GetAlpha() end
    if not PublicNumber(alpha) and not (entry and entry.nativePaint and issecretvalue and issecretvalue(alpha)) then return end
    return color,alpha
end

local function SourceMaterial(texture,path,uv)
    local record=Border._pieces[texture]
    local art=record and record.art
    if issecretvalue and issecretvalue(art) or type(art)~="string" then return end
    local style=sourceStyles[art]
    local gutter
    -- These canonical sheets have duplicated endpoint texels. Negative native
    -- texture IDs still use the registered artwork identity to find that guard.
    if style or art:sub(1,#PATH)==PATH and art:match("%.tga$") then
        if record.key=="Top" or record.key=="Bottom" then gutter=.5/208
        elseif record.key=="Left" or record.key=="Right" then gutter=.5/134 end
    end
    local handle=record.artHandle
    if style==2 and not (issecretvalue and issecretvalue(handle)) and handle==path then
        return gutter,SourceSupport(record.key,uv)
    end
    return gutter
end

local function ReadSource(texture)
    local path=ReadUnmaskedSourcePath(texture)
    if not path then return end
    local uv={texture:GetTexCoord()}
    if #uv~=4 and #uv~=8 then return end
    for _,v in ipairs(uv) do if not PublicNumber(v) then return end end
    local color,alpha=ReadSourcePaint(texture)
    if not color then return end
    local gutter,support=SourceMaterial(texture,path,uv)
    return {path=path,uv=uv,color=color,alpha=alpha,gutter=gutter,support=support}
end

-- Prepared poses already own public, exact UVs. Read the live tuple and
-- verify each value before sharing that array with this paint pass.
local function SameSourceUV(uv,...)
    local count=select("#",...)
    if count~=#uv then return false end
    local a,b,c,d,e,f,g,h=...
    if issecretvalue and (issecretvalue(a) or issecretvalue(b) or issecretvalue(c) or issecretvalue(d)) then return false end
    if a~=uv[1] or b~=uv[2] or c~=uv[3] or d~=uv[4] then return false end
    if count==4 then return true end
    if issecretvalue and (issecretvalue(e) or issecretvalue(f) or issecretvalue(g) or issecretvalue(h)) then return false end
    return e==uv[5] and f==uv[6] and g==uv[7] and h==uv[8]
end

function J._ReadPreparedSource(texture,material)
    if issecretvalue and issecretvalue(texture) or not texture then return end
    local path=ReadUnmaskedSourcePath(texture)
    if path~=material.path or not SameSourceUV(material.uv,texture:GetTexCoord()) then return end
    local color,alpha=ReadSourcePaint(texture)
    if not color then return end
    local gutter,support=SourceMaterial(texture,path,material.uv)
    if gutter~=material.gutter or support~=material.support then return end
    return {path=path,uv=material.uv,color=color,alpha=alpha,gutter=gutter,support=support}
end

Source=function(texture)
    if issecretvalue and issecretvalue(texture) then return end
    if not texture then return end
    local memo=sourceReadPlan and sourceReadPlan.values
    local cached=memo and memo[texture]
    if cached~=nil then sourceReadPlan.hits=sourceReadPlan.hits+1;return cached or nil end
    if sourceReadPlan then sourceReadPlan.reads=sourceReadPlan.reads+1 end
    local value=ReadSource(texture)
    if memo then memo[texture]=value or false end
    return value
end
end

-- HUD panels use different historical border insets. Align only
-- their decorative containers when close; their content/input frames keep all
-- original anchors. Native eight-piece caps then meet at a real shared stroke.
do
local lastPanelInputs,previousPanelInputs
local zeroPanelOffset={0,0,0,0}
local function SamePanelInput(old,frame,state,scale,index,priority,fixed,strip,envelope,left,right,top,bottom,dockY,sideTop)
    if not old or old.frame~=frame or old.state~=state or old.scale~=scale
        or old.index~=index or old.priority~=priority or old.fixed~=fixed
        or old.strip~=strip or old.envelope~=envelope or old.dockY~=dockY or old.sideTop~=sideTop then return false end
    local value=old.value
    return value[1]==left and value[2]==right and value[3]==top and value[4]==bottom
end
local function SamePanelLayout(prior,panels)
    if not prior or #prior~=#panels then return false end
    -- The sampler shares an input record at the same position whenever its
    -- verified values match either retained layout.
    for i,p in ipairs(panels) do if prior[i]~=p then return false end end
    return true
end
local function PlanPanelAlignment(panels)
    local minimap=_G.Minimap
    local nodeLists={}
    for i,p in ipairs(panels) do
        local nodes={}
        nodeLists[i]=nodes
        for edge=1,4 do
            local crest=edge==3 and p.strip
            nodes[edge]={value=p.value[edge],priority=p.priority+(crest and 1000000000 or 0),
                index=p.index,edge=edge,fixed=p.fixed or crest}
        end
    end
    local function Find(node)
        if node.parent then node.parent=Find(node.parent);return node.parent end
        return node
    end
    local function Join(a,b,edge)
        a,b=Find(a),Find(b)
        if a==b then return end
        if a.fixed and b.fixed and abs(a.value-b.value)>1/64 then return end
        local sameEdge=a.edge==b.edge and a.edge or nil
        local floorValue=edge==4 and sameEdge==4 and min(a.value,b.value) or nil
        if b.fixed and not a.fixed or a.fixed==b.fixed and (b.priority>a.priority or b.priority==a.priority and b.index<a.index) then a,b=b,a end
        b.parent=a;a.edge=sameEdge
        -- Keep rings/content enclosed: a common floor can extend outward but
        -- must never move up through the lower panel's existing bottom stroke.
        if floorValue and not a.fixed then a.value=floorValue end
    end
    for i,a in ipairs(panels) do for k=i+1,#panels do
        local b=panels[k]
        local an,bn=nodeLists[i],nodeLists[k]
        local limit=EPS+8*min(a.scale,b.scale)
        local av,bv=a.value,b.value
        local vertical=min(av[3],bv[3])-max(av[4],bv[4])>EPS
        local horizontal=min(av[2],bv[2])-max(av[1],bv[1])>EPS
        local side
        if vertical and abs(av[2]-bv[1])<=limit then Join(an[2],bn[1]);side=true
        elseif vertical and abs(av[1]-bv[2])<=limit then Join(an[1],bn[2]);side=true end
        if side then
            for edge=3,4 do if abs(av[edge]-bv[edge])<=limit then Join(an[edge],bn[edge],edge) end end
        end
        -- The envelope contains the packed strip, so it has no side contact
        -- with it. Share their nearby crest while keeping both roots fixed.
        if horizontal and abs(av[3]-bv[3])<=limit and
            (a.strip and b.envelope or b.strip and a.envelope) then
            Join(an[3],bn[3],3)
        end
        -- The side grid can meet the window below it and the minimap above
        -- it. Use content contact even when the artwork insets differ.
        local aboveWindow=b.sideTop and a.dockY and abs(a.dockY-b.dockY)<=EPS
        local belowMap=a.sideTop and b.frame==minimap and b.dockY and abs(a.sideTop-b.dockY)<=EPS
        local stacked
        if horizontal and (aboveWindow or belowMap or abs(av[3]-bv[4])<=limit) then
            if belowMap then bn[4].fixed=true end -- The minimap rim stays put when hover adds its neighbor.
            Join(an[3],bn[4]);stacked=true
        elseif horizontal and abs(av[4]-bv[3])<=limit then Join(an[4],bn[3]);stacked=true end
        if stacked then
            for edge=1,2 do if abs(av[edge]-bv[edge])<=limit then Join(an[edge],bn[edge]) end end
        end
    end end
    local wanted={}
    for index,p in ipairs(panels) do
        local offset={}
        for i,node in ipairs(nodeLists[index]) do offset[i]=(Find(node).value-p.value[i])/p.scale end
        wanted[p.frame]=offset
    end
    return wanted
end
function J:AlignNearbyPanels()
    if Locked() then return 0 end
    local window=_G.FluxWindowFrame
    if window and not window.GetRect then window=window.frame end
    local info=_G.FluxInfoFrame
    if info and info.GetFrame then info=info.GetFrame() end -- Existing getter; never creates the frame.
    local combat=_G.FluxCombatManager and _G.FluxCombatManager.Grid
    local noncombat=_G.FluxNonCombatAPI and _G.FluxNonCombatAPI.DefaultGrid
    local strip=_G.FluxActionStrip or _G.FluxMainActionBar
    local envelope=_G.FluxUnifiedBorderFrame
    local side=_G.FluxMinimapButtonsSideBorder
    local minimap=_G.Minimap
    local roots={window,strip,_G.FluxTrinketMenuFrame,
        combat and combat.Frame,noncombat and noncombat.Frame,info,envelope,
        side,minimap,_G.FluxMinimapInfoBar,
        _G.FluxStanceBar,_G.FluxPetBar}
    local seen={}
    local prior,alternate=lastPanelInputs,previousPanelInputs
    local panels,count=nil,0
    local joinTracks=Border.GetJoinTracks and Border:GetJoinTracks() or tracks[Border:GetBorderType()]
    for index=1,12 do
        local frame=roots[index]
        local bf=frame and frame.GetRect and frame.IsVisible and frame.FluxBorderFrame
        if bf and bf:GetParent()==frame and not seen[frame] then
            seen[frame]=true
            local state=nearbyPanels[frame]
            if not state or state.border~=bf then state={border=bf,offset=zeroPanelOffset};nearbyPanels[frame]=state end
            local visible=frame:IsVisible()
            local opacity=bf.GetEffectiveAlpha and bf:GetEffectiveAlpha() or 1
            local scale=bf:GetEffectiveScale()
            local strata=bf:GetFrameStrata()
            local hudTier=not (issecretvalue and issecretvalue(strata)) and (STRATA[strata] or frame._FluxBorderHUD and 3)
            if not (issecretvalue and (issecretvalue(visible) or issecretvalue(strata))) and visible
                and PublicNumber(opacity) and opacity>0 and PublicNumber(scale) and scale>0 and hudTier then
                local insets=bf._fluxBorderInsets
                local x,y,w,h=frame:GetRect()
                local left,right,top,bottom
                if insets and PublicNumber(insets[1]) and PublicNumber(insets[2])
                    and PublicNumber(x) and PublicNumber(y) and PublicNumber(w) and PublicNumber(h) and w>0 and h>0 then
                    -- These are the shared factory's nominal stroke positions.
                    -- Reading back adjusted float-sized textures and subtracting
                    -- offsets fed rounding drift into the next alignment pass.
                    local px,py=insets[1],insets[2]
                    left,right=(x+px-11+joinTracks.Left)*scale,(x+w-px-9+joinTracks.Right)*scale
                    top,bottom=(y+h-py+6-joinTracks.Top)*scale,(y+py+9-joinTracks.Bottom)*scale
                end
                local level=bf:GetFrameLevel()
                if left and PublicNumber(level) then
                    local g=groups[bf]
                    local priority=g and g.paintPriority or hudTier*65536+level
                    local fixed,isStrip,isEnvelope=FixedPanel(frame),frame==strip,frame==envelope
                    local sideTop=frame==side and (y+h)*scale or nil
                    local dockY=frame==window and (y+h)*scale or (frame==side or frame==minimap) and y*scale or nil
                    count=count+1
                    local current=prior and prior[count]
                    local sample=current
                    if not SamePanelInput(sample,frame,state,scale,index,priority,fixed,isStrip,isEnvelope,left,right,top,bottom,dockY,sideTop) then
                        sample=alternate and alternate[count]
                        if not SamePanelInput(sample,frame,state,scale,index,priority,fixed,isStrip,isEnvelope,left,right,top,bottom,dockY,sideTop) then
                            sample={frame=frame,state=state,scale=scale,value={left,right,top,bottom},
                                index=index,priority=priority,fixed=fixed,strip=isStrip,envelope=isEnvelope,dockY=dockY,sideTop=sideTop}
                        end
                    end
                    if not panels and sample~=current then
                        panels={}
                        for previous=1,count-1 do panels[previous]=prior[previous] end
                    end
                    if panels then panels[count]=sample end
                end
            end
        end
    end
    -- Current public inputs are still sampled every pass. Stable HUD panels
    -- don't need to build another alignment graph for a unit-only change.
    if not panels then
        if prior and count==#prior then return 0 end
        -- The current layout can be a shorter prefix after a panel hides.
        panels={}
        for index=1,count do panels[index]=prior[index] end
    end
    -- A held action can move between the same two settled layouts. Reuse
    -- their offsets after matching the current owners and public bounds.
    if SamePanelLayout(alternate,panels) then panels=alternate
    else panels.offsets=PlanPanelAlignment(panels) end
    local wanted=panels.offsets
    local changed=0
    lastPanelInputs,previousPanelInputs=nil,nil
    painting=true
    local ok,err=pcall(function() for frame,state in pairs(nearbyPanels) do
        if frame.FluxBorderFrame==state.border then
            local offset=wanted[frame] or zeroPanelOffset
            local same=state.offset~=nil
            local scale=state.border:GetEffectiveScale()
            local tolerance=PublicNumber(scale) and scale>0 and 1/(64*scale) or .00001
            if same then
                for i=1,4 do if abs(offset[i]-state.offset[i])>tolerance then same=false;break end end
            end
            if not same then
                local bf=state.border
                state.offset=nil -- A failed native write can leave partially applied anchors.
                bf:ClearAllPoints()
                if offset[1]==0 and offset[2]==0 and offset[3]==0 and offset[4]==0 then bf:SetAllPoints(frame)
                else
                    bf:SetPoint("TOPLEFT",frame,"TOPLEFT",offset[1],offset[3])
                    bf:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",offset[2],offset[4])
                end
                state.offset=offset;changed=changed+1
            end
        end
    end end)
    painting=false
    if not ok then dirty=true;error(err,0) end
    lastPanelInputs,previousPanelInputs=panels,prior
    self.stats.panelAlignments=(self.stats.panelAlignments or 0)+changed
    return changed
end
end
do
local arrowLayerPanels=setmetatable({}, {__mode="k"})
local function HigherLayer(frame,strata,level)
    if not frame then return level end
    local actualStrata,actualLevel=frame:GetFrameStrata(),frame:GetFrameLevel()
    if not (issecretvalue and issecretvalue(actualStrata)) and actualStrata==strata and PublicNumber(actualLevel) then
        return max(level,actualLevel)
    end
    return level
end
local function ArrowPanelLevel(panel,strata,level)
    local border=panel and panel.FluxBorderFrame
    if not border then return level end
    local visible=panel:IsVisible()
    if (issecretvalue and issecretvalue(visible)) or not visible then return level end
    arrowLayerPanels[border]=true
    level=HigherLayer(border,strata,level)
    local canvas=junctionCanvases[border]
    return HigherLayer(canvas and canvas._requiredRank and canvas,strata,level)
end
function J:GetArrowBorderLevel(widget,strata,level)
    local strip=_G.FluxActionStrip or _G.FluxMainActionBar
    local combat=_G.FluxCombatManager and _G.FluxCombatManager.Grid
    local noncombat=_G.FluxNonCombatAPI and _G.FluxNonCombatAPI.DefaultGrid
    local bottomHUD
    local owner=widget
    for _=1,12 do
        if (issecretvalue and issecretvalue(owner)) or not owner or owner==UIParent then break end
        level=ArrowPanelLevel(owner,strata,level)
        if owner==strip then
            arrowLayerPanels[strip]=true
            local canvas=stripCanvases[strip]
            if canvas and canvas._requiredLevel>0 then level=HigherLayer(canvas,strata,level) end
            bottomHUD=true
        elseif owner==_G.FluxMinimapButtonsVisibility then
            level=ArrowPanelLevel(_G.FluxMinimapButtonsSideBorder,strata,level)
        elseif owner==_G.FluxTrinketMenuFrame or (combat and owner==combat.Frame) or (noncombat and owner==noncombat.Frame) then
            bottomHUD=true
        end
        owner=owner:GetParent()
    end
    if bottomHUD then level=ArrowPanelLevel(_G.FluxUnifiedBorderFrame,strata,level) end
    return level
end
function J._ArrowCanvasChanged(owner)
    if arrowLayerPanels[owner] then J._arrowLayerDirty=true end
end
function J._RetireArrowCanvasLevels(levels)
    for owner in pairs(arrowLayerPanels) do
        local junction,strip=junctionCanvases[owner],stripCanvases[owner]
        if junction and junction._requiredRank and (not levels or not levels.junctions[owner]) then
            junction._requiredRank=nil;junction._requiredLevel=0;J._arrowLayerDirty=true
        end
        if strip and strip._requiredLevel>0 and (not levels or not levels.strips[owner]) then
            strip._requiredLevel=0;J._arrowLayerDirty=true
        end
    end
end
function J._PublishArrowLayers()
    if not J._arrowLayerDirty then return end
    J._arrowLayerDirty=nil
    local flyout=_G.Flux and _G.Flux.Flyout
    local arrows=flyout and flyout.Arrow
    if arrows and arrows.RefreshArtLayers then arrows.RefreshArtLayers() end
end
end
local function SetRenderLayer(canvas,strata,level)
    local actualStrata,actualLevel=canvas:GetFrameStrata(),canvas:GetFrameLevel()
    local strataChanged=(issecretvalue and issecretvalue(actualStrata)) or actualStrata~=strata
    local levelChanged=not PublicNumber(actualLevel) or actualLevel~=level
    if strataChanged then canvas:SetFrameStrata(strata) end
    if levelChanged then canvas:SetFrameLevel(level) end
    if strataChanged or levelChanged then J._ArrowCanvasChanged(canvas:GetParent()) end
end
local function ApplyRegionalLayer(canvas,info,isStrip)
    local strata=info.strata
    if isStrip and STRATA[strata] then strata="MEDIUM" end
    canvas._requiredLevel=info.level
    if not isStrip then canvas._requiredStrata,canvas._requiredRank=strata,info.rank end
    SetRenderLayer(canvas,strata,min(65535,info.level+(isStrip and 0 or 1)))
    renderLayers.applied[canvas]=true
end
local function StripCanvas(strip,level)
    local canvas=stripCanvases[strip]
    if not canvas then
        canvas=CreateFrame("Frame",nil,strip)
        if canvas.EnableMouse then canvas:EnableMouse(false) end
        canvas:SetAllPoints(strip)
        stripCanvases[strip]=canvas
        J._ArrowCanvasChanged(strip)
    end
    local prepared=renderLayers and renderLayers.strips[strip]
    if prepared then
        if not renderLayers.applied[canvas] then ApplyRegionalLayer(canvas,prepared,true) end
        return canvas
    end
    -- Inherit strip visibility/scale/alpha, but draw the decorative seam above
    -- unit portraits. The protected units and model geometry are untouched.
    local info=renderLayers and renderLayers.native[strip]
    local strata=info and info.strata or strip:GetFrameStrata()
    if STRATA[strata] then strata="MEDIUM" end
    canvas._requiredLevel=max(canvas._requiredLevel or 0,level or (info and info.level or strip:GetFrameLevel())+20)
    level=min(65535,canvas._requiredLevel)
    SetRenderLayer(canvas,strata,level)
    return canvas
end
local function CapCanvas(parent)
    local canvas=capCanvases[parent]
    if not canvas then
        canvas=CreateFrame("Frame",nil,parent);canvas:SetAllPoints(parent)
        if canvas.EnableMouse then canvas:EnableMouse(false) end
        capCanvases[parent]=canvas
    end
    if renderLayers and renderLayers.applied[canvas] then return canvas end
    local info=renderLayers and renderLayers.native[parent]
    local strata=info and info.strata or parent:GetFrameStrata()
    local level=min(65535,(info and info.level or parent:GetFrameLevel())+2)
    SetRenderLayer(canvas,strata,level)
    if renderLayers then renderLayers.applied[canvas]=true end
    return canvas
end
local function PreparedJunctionLayer(parent,members)
    local own=renderLayers and renderLayers.native[parent]
    if not own or type(own.strata)~="string" then return end
    local summary=renderLayers.members[members]
    if summary==false then return end
    if not summary then
        summary={rank=-1,levels={}}
        for group in pairs(members) do
            local source=group.parent
            if not source._FluxBorderOwnLayer then
                local info=renderLayers.native[source]
                if not info or type(info.strata)~="string" then
                    renderLayers.members[members]=false
                    return
                end
                if info.rank>summary.rank then summary.rank,summary.strata=info.rank,info.strata end
                summary.levels[info.strata]=max(summary.levels[info.strata] or info.level,info.level)
            end
        end
        renderLayers.members[members]=summary
    end
    -- Equal-rank strata keep the parent's actual stratum. Members contribute
    -- their levels only when they are in that same stratum.
    if summary.rank>own.rank then return summary.strata,summary.rank,max(0,summary.levels[summary.strata]) end
    return own.strata,own.rank,max(own.level,summary.levels[own.strata] or own.level)
end
local function JunctionLayer(parent,members)
    local preparedStrata,preparedRank,preparedLevel=PreparedJunctionLayer(parent,members)
    if preparedStrata then return preparedStrata,preparedRank,preparedLevel end
    local strata=parent:GetFrameStrata()
    local rank=STRATA[strata] or (strata=="HIGH" and 3) or 4
    local level=parent:GetFrameLevel()
    for g in pairs(members) do
        if not g.parent._FluxBorderOwnLayer then
            local other=g.parent:GetFrameStrata()
            local value=STRATA[other] or (other=="HIGH" and 3) or 4
            if value>rank then strata,rank=other,value;level=0 end
        end
    end
    for g in pairs(members) do
        if not g.parent._FluxBorderOwnLayer and g.parent:GetFrameStrata()==strata then
            local value=g.parent:GetFrameLevel()
            if PublicNumber(value) then level=max(level,value) end
        end
    end
    return strata,rank,level
end
local function JunctionCanvas(parent,members)
    -- The partitioned fields can share geometry while each panel's paint
    -- stays with its own border. Input layers on one panel never lift peers.
    if parent._FluxBorderOwnLayer then return parent end
    local canvas=junctionCanvases[parent]
    if not canvas then
        canvas=CreateFrame("Frame",nil,parent);canvas:SetAllPoints(parent)
        if canvas.EnableMouse then canvas:EnableMouse(false) end
        junctionCanvases[parent]=canvas
        J._ArrowCanvasChanged(parent)
    end
    local prepared=renderLayers and renderLayers.junctions[parent]
    if prepared then
        if not renderLayers.applied[canvas] then ApplyRegionalLayer(canvas,prepared,false) end
        return canvas
    end
    local strata,rank,level=JunctionLayer(parent,members)
    if canvas._requiredRank and canvas._requiredRank>rank then
        strata,rank,level=canvas._requiredStrata,canvas._requiredRank,canvas._requiredLevel
    elseif canvas._requiredRank==rank then level=max(level,canvas._requiredLevel) end
    canvas._requiredStrata,canvas._requiredRank,canvas._requiredLevel=strata,rank,level
    level=min(65535,level+1)
    SetRenderLayer(canvas,strata,level)
    return canvas
end
local function FragmentSource(texture)
    local sources=renderBases and renderBases.fragmentSources
    local found=sources and sources[texture]
    if found and found[2] then return found[1],found[2],found[3] end
    local parent=found and found[1] or texture:GetParent()
    local layer,sublevel=texture:GetDrawLayer()
    if sources and not (issecretvalue and (issecretvalue(parent) or issecretvalue(layer) or issecretvalue(sublevel)))
        and parent and type(layer)=="string" and (sublevel==nil or PublicNumber(sublevel)) then
        sources[texture]={parent,layer,sublevel}
    end
    return parent,layer,sublevel
end

local function JunctionSourceParent(texture)
    local sources=renderBases and renderBases.fragmentSources
    local fragment=sources and sources[texture]
    if fragment then return fragment[1] end
    local parent=texture:GetParent()
    -- Junction-only sources may have no normal fragment in this tile.
    if sources and not (issecretvalue and issecretvalue(parent)) and parent then
        sources[texture]={parent}
    end
    return parent
end

local function RenderFragments(item,rectangles,source,root,renderStrip,renderLevel,roundCap,renderMembers,samples,regionalPool)
    local texture=item.texture
    local entry=clipped[texture]
    if not entry then entry={pool={}};clipped[texture]=entry end
    entry.alpha=source.alpha;entry.color=source.color;entry.path=source.path;entry.uv=source.uv;entry.support=source.support;entry.root=root;entry.epoch=renderEpoch
    if StaticUnitOwner(texture) then entry.sourceShown=Shown(texture) end
    entry.normalCount=#rectangles
    -- Regional commits reconcile layers separately. A source that only feeds
    -- a junction or fallback needs its paint entry, but no normal canvas.
    if entry.normalCount>0 or not renderLayers then
        local geometry=J._FieldGeometry
        local sourceParent,layer,sublevel=FragmentSource(texture)
        local parent=renderStrip and StripCanvas(renderStrip,renderLevel) or roundCap and CapCanvas(sourceParent)
            or renderMembers and JunctionCanvas(sourceParent,renderMembers) or sourceParent
        local scale,px,py=RenderBasis(parent)
        for i,r in ipairs(rectangles) do
            local fragment=entry.pool[i]
            if fragment and fragment:GetParent()~=parent then
                if fragment.SetParent then fragment:SetParent(parent)
                else
                    fragment:Hide()
                    if regionalPool then J._RemoveRegionalFragment(regionalPool,fragment) end
                    fragment=nil
                end
            end
            if not fragment then
                fragment=parent:CreateTexture(nil,layer,nil,sublevel);entry.pool[i]=fragment
                ContinuousSampling(fragment)
            end
            fragment._fallbackSource=nil;fragment._fallbackBlockers=nil
            fragment._renderEpoch=renderEpoch
            FieldPaint.Layer(fragment,layer,sublevel)
            FieldPaint.Texture(fragment,source.path)
            local uv=samples and samples[i]
            if not uv then
                uv=SliceUV(source.uv,item.rect,r)
                if samples then samples[i]=uv end
            end
            FieldUV(fragment,uv)
            geometry.Box(fragment,parent,r[1]/scale-px,r[2]/scale-py,(r[3]-r[1])/scale,(r[4]-r[2])/scale)
            geometry.Color(fragment,texture,entry)
            FieldAlpha(fragment,entry.sourceShown==false and 0 or entry.alpha)
            FieldShow(fragment)
        end
    end
    entry.active=true
    local suppressed=renderBases and renderBases.suppressedSources
    if not suppressed or suppressed[texture]==nil then
        local alreadyHidden=FieldAlpha(texture,0)
        if suppressed then
            -- A native opacity write can run additional hooks. Memoize the
            -- read only when no native setter ran and paint is observed.
            suppressed[texture]=renderLayers~=nil and alreadyHidden==true
                and Border._pieces[texture] and Border._pieces[texture].junctionWatched==true or false
        end
    end
end

-- Disjoint triangles tile the junction exactly. Each branch samples the same
-- original bevel UV field but keeps its own tint and natural/tint artwork.
-- No alpha masks, overlapping colored layers or runtime bitmap generation.
function J:Triangles(bits,cx,cy)
    local c={cx,cy};local out={}
    local function Add(arm,a,b,d) out[#out+1]={arm=arm,a=a,b=b,c=d} end
    local l,r,u,d=bits%2==1,floor(bits/2)%2==1,floor(bits/4)%2==1,floor(bits/8)%2==1
    if l then Add(1,{0,0},{0,1},c)
    else Add(3,{0,0},{0,cy},c);Add(4,{0,cy},{0,1},c) end
    if r then Add(2,c,{1,1},{1,0})
    else Add(3,c,{1,cy},{1,0});Add(4,c,{1,1},{1,cy}) end
    if u then Add(3,{0,0},c,{1,0})
    else Add(1,{0,0},c,{cx,0});Add(2,{cx,0},c,{1,0}) end
    if d then Add(4,c,{0,1},{1,1})
    else Add(1,c,{0,1},{cx,1});Add(2,c,{cx,1},{1,1}) end
    return out
end
-- Clip in the source's screen-coordinate field. Outside the perpendicular
-- footprint is transparent; along the run, repeat the exact endpoint profile.
-- Splitting before clamping preserves native longitudinal texture variation.
local function ClipField(poly,axis,limit,keepAbove)
    -- Most branch cuts contain the entire immutable field, or miss it. Avoid
    -- building an identical polygon (and avoid interpolation) in those cases.
    local inside=0
    for _,point in ipairs(poly) do
        if keepAbove and point[axis]>=limit or not keepAbove and point[axis]<=limit then inside=inside+1 end
    end
    if inside==#poly then return poly end
    if inside==0 then return {} end
    local out={};local previous=poly[#poly]
    for _,current in ipairs(poly) do
        local pin=keepAbove and previous[axis]>=limit or not keepAbove and previous[axis]<=limit
        local cin=keepAbove and current[axis]>=limit or not keepAbove and current[axis]<=limit
        if pin~=cin then
            local factor=(limit-previous[axis])/(current[axis]-previous[axis]);local point={}
            for i=1,4 do point[i]=previous[i]+factor*(current[i]-previous[i]) end
            out[#out+1]=point
        end
        if cin then out[#out+1]=current end
        previous=current
    end
    return out
end
local function UVPoint(uv,x,y)
    if #uv==4 then return uv[1]+(uv[2]-uv[1])*x,uv[3]+(uv[4]-uv[3])*y end
    return uv[1]*(1-x)*(1-y)+uv[3]*(1-x)*y+uv[5]*x*(1-y)+uv[7]*x*y,
        uv[2]*(1-x)*(1-y)+uv[4]*(1-x)*y+uv[6]*x*(1-y)+uv[8]*x*y
end
local function EndpointSample(source,span,coordinate,endpoint,low,high)
    if not source.gutter then return endpoint end
    -- Stay within half a duplicated source texel. Unlike a constant row/column,
    -- this affine field has a nonzero UV area and stays in the endpoint gutter.
    -- At the original boundary its UV is unchanged.
    local extent=max(abs(low-endpoint),abs(high-endpoint))
    if extent<=1e-12 then return endpoint end
    return endpoint+(coordinate-endpoint)/extent*span*source.gutter
end
local function ExcludeCaps(poly,rectangles)
    local fields={poly}
    for _,r in ipairs(rectangles or {}) do
        local remaining={}
        for _,field in ipairs(fields) do
            local left,bottom,right,top=math.huge,math.huge,-math.huge,-math.huge
            for _,point in ipairs(field) do
                left=min(left,point[3]);bottom=min(bottom,point[4]);right=max(right,point[3]);top=max(top,point[4])
            end
            -- Strict horizontal separation leaves exactly the original field
            -- in the old four-way partition. Preserve boundary/tangent cuts.
            if right<r[1] or left>r[3] then
                remaining[#remaining+1]=field
            elseif left>r[1] and right<r[3] and bottom>r[2] and top<r[4] then
                -- Fully covered; every outside half-plane would be empty.
            else
            local middle=ClipField(ClipField(field,3,r[1],true),3,r[3],false)
            for _,outside in ipairs({ClipField(field,3,r[1],false),ClipField(field,3,r[3],true),
                ClipField(middle,4,r[2],false),ClipField(middle,4,r[4],true)}) do
                if #outside>=3 then
                    remaining[#remaining+1]=outside
                    if #remaining>256 then return nil,"junction cap fragment budget" end
                end
            end
            end
            if #remaining>256 then return nil,"junction cap fragment budget" end
        end
        fields=remaining
    end
    return fields
end
-- Paired aura panels share one exposed top crest. A diagonal miter lets the
-- side's outer shadow cut a notch through that crest. Partition this T as a
-- continuous crossbar and a butt-ended stem instead, with disjoint source
-- fields. Keep one source pixel of the inner crest before the stem begins.
local function AuraTopTriangles(op,best)
    local r=op.rect
    local left,right=best[1],best[2]
    if op.hs.group and op.hs.group.actionStrip and (op.bits==7 or op.bits==11 or op.bits==15) then
        local retained=false
        for g in pairs(op.members) do retained=retained or StaticUnitOwner(g.parent)~=nil end
        if retained then
            local width,height=r[3]-r[1],r[4]-r[2]
            local cx,cy=(op.x-r[1])/width,(r[4]-op.y)/height
            local top,bottom=max(0,cy-op.hs.scale/height),min(1,cy+op.hs.scale/height)
            local triangles={}
            local function Rect(arm,l,t,rr,b)
                if rr<=l or b<=t then return end
                local a,c,d,e={l,t},{l,b},{rr,t},{rr,b};local field={}
                triangles[#triangles+1]={arm=arm,a=a,b=c,c=d,rectField=field}
                triangles[#triangles+1]={arm=arm,a=d,b=c,c=e,rectField=field}
            end
            local function Horizontal(l,t,rr,b)
                Rect(1,l,t,min(rr,cx),b);Rect(2,max(l,cx),t,rr,b)
            end
            local function End(arm,t,b)
                local stem=best[arm]
                if not stem then Horizontal(0,t,1,b);return end
                local l,rr=max(0,(stem.rect[1]-r[1])/width),min(1,(stem.rect[3]-r[1])/width)
                Horizontal(0,t,l,b);Horizontal(rr,t,1,b);Rect(arm,l,t,rr,b)
            end
            Horizontal(0,top,1,bottom);End(3,0,top);End(4,bottom,1)
            op.auraTopCrest=true
            return triangles
        end
    end
    if op.bits==11 and left and right and left.side=="Top" and right.side=="Top"
        and left.group.parent and right.group.parent
        and left.group.parent._FluxBorderAuraPanel and right.group.parent._FluxBorderAuraPanel
        and abs(left.rawP-right.rawP)<1/64 then
        local width,height=r[3]-r[1],r[4]-r[2]
        local cx=(op.x-r[1])/width
        local seam=(r[4]-op.y+min(left.scale,right.scale))/height
        local stem=best[4] or op.vs
        local x1=max(0,(stem.rect[1]-r[1])/width)
        local x2=min(1,(stem.rect[3]-r[1])/width)
        local triangles={}
        local function Rect(arm,l,t,rr,b)
            if rr<=l or b<=t then return end
            local a,c,d,e={l,t},{l,b},{rr,t},{rr,b}
            local field={}
            triangles[#triangles+1]={arm=arm,a=a,b=c,c=d,rectField=field}
            triangles[#triangles+1]={arm=arm,a=d,b=c,c=e,rectField=field}
        end
        Rect(1,0,0,cx,seam);Rect(2,cx,0,1,seam)
        Rect(1,0,seam,x1,1);Rect(2,x2,seam,1,1)
        Rect(4,x1,seam,x2,1)
        op.auraTopCrest=true
        return triangles
    end
end
-- Select each part of an arm from a source which actually covers it. A short
-- high-priority edge may own the center of a T/X, but cannot erase a longer
-- lower-priority edge beyond that shared interval. Source fields stay affine.
ArmSlices=function(op,arm,best)
    local horizontal=arm<=2
    local axis=horizontal and "H" or "V"
    local center=horizontal and op.x or op.y
    local low,high=op.rect[horizontal and 1 or 2],op.rect[horizontal and 3 or 4]
    local candidates,cuts={}, {low,high}
    local bounded=true
    local reach=Tolerance(op.hs,op.vs)
    for segment in pairs(op.segments or {}) do reach=max(reach,Tolerance(op.hs,op.vs)+(segment.weldOffset or 0)) end
    local function Add(segment)
        if segment.axis~=axis then return end
        local a,b=segment.a,segment.b
        if not (PublicNumber(a) and PublicNumber(b)) then return end
        if a<=center+reach and b>=center-reach then
            a,b=min(a,center),max(b,center)
        end
        a,b=max(a,low),min(b,high)
        if b>a then
            candidates[#candidates+1]={segment=segment,a=a,b=b}
            cuts[#cuts+1]=a;cuts[#cuts+1]=b
            -- A parallel owner farther along this arm need not itself touch
            -- the node. Include its exact boundaries before sampling ownership.
            if not CollectOwnerBoundaries(segment,low,high,cuts,{}) then bounded=false end
        end
    end
    if op.segments then for segment in pairs(op.segments) do Add(segment) end end
    if #candidates==0 then
        local segment=best[arm] or (horizontal and op.hs or op.vs)
        return {{segment=segment,a=low,b=high}}
    end
    if not bounded or #cuts>128 then return nil,"branch ownership budget" end
    table.sort(cuts)
    local slices={}
    for i=1,#cuts-1 do
        local a,b=cuts[i],cuts[i+1]
        if b-a>1e-8 then
            local owner;local probe=(a+b)/2
            for _,entry in ipairs(candidates) do
                if probe>=entry.a and probe<=entry.b then
                    local candidate=PaintOwner(entry.segment,probe)
                    if not owner or Above(candidate,owner) then owner=candidate end
                end
            end
            if owner then
                local last=slices[#slices]
                if last and last.segment==owner and abs(last.b-a)<1e-8 then last.b=b
                else slices[#slices+1]={segment=owner,a=a,b=b} end
            end
        end
    end
    return slices
end
local function RectangleField(points)
    if #points<4 then return end
    local l,t,r,b=math.huge,math.huge,-math.huge,-math.huge
    for _,p in ipairs(points) do l=min(l,p[1]);t=min(t,p[2]);r=max(r,p[1]);b=max(b,p[2]) end
    if r-l<1e-10 or b-t<1e-10 then return end
    local corners={}
    for _,p in ipairs(points) do
        local x=abs(p[1]-l)<1e-9 and 1 or abs(p[1]-r)<1e-9 and 2
        local y=abs(p[2]-t)<1e-9 and 1 or abs(p[2]-b)<1e-9 and 2
        if x and y then corners[(x-1)*2+y]=p end
    end
    if corners[1] and corners[2] and corners[3] and corners[4] then return corners end
end
local function MergeRectangleField(group)
    if #group<2 then return end
    local points,area={},0
    for _,entry in ipairs(group) do
        local a,b,c=entry.a,entry.b,entry.c
        points[#points+1]=a;points[#points+1]=b;points[#points+1]=c
        area=area+abs((b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1]))/2
    end
    local q=RectangleField(points)
    if not q or abs(area-(q[3][1]-q[1][1])*(q[2][2]-q[1][2]))>1e-9 then return end
    local uv={q[1][3],q[1][4],q[2][3],q[2][4],q[3][3],q[3][4],q[4][3],q[4][4]}
    for _,p in ipairs(points) do
        local u,v=UVPoint(uv,(p[1]-q[1][1])/(q[3][1]-q[1][1]),(p[2]-q[1][2])/(q[2][2]-q[1][2]))
        if abs(u-p[3])>1e-8 or abs(v-p[4])>1e-8 then return end
    end
    for i,entry in ipairs(group) do entry.quad=i==1 and q or nil;entry.quadTail=i>1 end
end
local branchCompilePrevious,branchCompileNext,branchCompileAlternate={},nil,{}
function J:_ClearBranchCompileCache()
    branchCompilePrevious={};branchCompileNext=nil;branchCompileAlternate={}
end
function J:_PublishBranchCompileCache()
    local previous={}
    local count,triangles,values=0,0,0
    -- Components can be blocked after base fields compile. Only the operations
    -- in the successfully committed generation may publish reusable geometry.
    for _,op in ipairs(active) do
        local candidate=op._branchCompileCandidate or op._branchCompileCommitted
        if candidate and count<self.limits.operations
            and triangles+#candidate.geometry<=self.limits.junctionTriangles
            and values+#candidate.inputs<=self.limits.junctionTriangles*64 then
            previous[candidate.key]=candidate;op._branchCompileCommitted=candidate
            count=count+1;triangles=triangles+#candidate.geometry;values=values+#candidate.inputs
        else op._branchCompileCommitted=nil end
        op._branchCompileCandidate=nil
    end
    local alternate={}
    local retained=0
    -- Keep at most one displaced numeric branch for a current contact.
    -- Both variants share the original operation, field and scalar limits.
    for key,current in pairs(previous) do
        local prior=branchCompilePrevious[key]
        if prior==current then prior=branchCompileAlternate[key] end
        if not self._discardAlternatePlans and prior and prior~=current and retained<64 and count<self.limits.operations
            and triangles+#prior.geometry<=self.limits.junctionTriangles
            and values+#prior.inputs<=self.limits.junctionTriangles*64 then
            alternate[key]=prior;retained=retained+1
            count=count+1;triangles=triangles+#prior.geometry;values=values+#prior.inputs
        end
    end
    branchCompileAlternate=alternate;branchCompilePrevious=previous;branchCompileNext=nil
end

local function CompactFocusBottomRim(op)
    if op.bits ~= 7 or op.hs.side ~= "Bottom" or not op.segments then return end
    local stem = op.vs
    if stem.group.unitOwner ~= "focus" then return end
    local parent = stem.group.parent
    local owner = StaticUnitOwner(parent)
    if not owner or owner.unit ~= "focus" or not owner._fluxCompactFocus then return end
    local portrait = owner.PortraitFrame and owner.PortraitFrame.FluxBorderFrame
    if not portrait or not ((parent == portrait and stem.side == "Right")
        or (parent == owner.FluxBorderFrame and stem.side == "Left")) then return end
    local outer = owner.outerBorderFrame and owner.outerBorderFrame.FluxBorderFrame
    local bottom = outer and outer.Bottom
    if not bottom then return end
    for group in pairs(op.members) do
        if group.unitOwner ~= "focus" then return end
    end
    for segment in pairs(op.segments) do
        local r = segment.rect
        if segment.texture == bottom and abs(segment.rawP - op.y) < 1 / 64
            and r[1] <= op.rect[1] and r[3] >= op.rect[3] then
            return segment
        end
    end
end

local function PrepareBranchFields(self,op,best,fingerprint)
    if op.branchError then return nil,op.branchError end
    local r=op.rect
    local triangles=AuraTopTriangles(op,best) or self:Triangles(op.bits,(op.x-r[1])/(r[3]-r[1]),(r[4]-op.y)/(r[4]-r[2]))
    local prepared={triangles=triangles,slices={},sources={},cacheable=true}
    prepared.focusBottomRim=CompactFocusBottomRim(op)
    if (op.bits==7 or op.bits==11) and op.hs.group and op.hs.group.castSection then
        local divider=op.vs.group and op.vs.group.parent
        if divider and divider._FluxBorderCastInternalSide==op.vs.side then
            prepared.castRimDepth=op.hs.scale
        end
    end
    local inputs=fingerprint and {}
    local function Values(values)
        if inputs then inputs[#inputs+1]=#values;for _,value in ipairs(values) do inputs[#inputs+1]=value end end
    end
    local function SourceInput(segment)
        local texture=segment.texture
        local identity=texture or segment
        if not texture then prepared.cacheable=false end
        local source=prepared.sources[identity]
        if not source then source=segment.source or texture and Source(texture);prepared.sources[identity]=source end
        if not source or not segment.rect then return nil end
        if inputs then
            inputs[#inputs+1]=texture or false
            Values(segment.rect);Values(source.uv);inputs[#inputs+1]=source.gutter or false
            inputs[#inputs+1]=segment.rawP or segment.p or false
            inputs[#inputs+1]=source.support and source.support[1] or false
            inputs[#inputs+1]=source.support and source.support[2] or false
            local paint=segment.item and segment.item.paintRect
            if paint then Values(paint) end
        end
        return source
    end
    if inputs then
        Values(r);Values(op.fullRect or r);Values({op.bits,op.x,op.y})
        inputs[#inputs+1]=op.auraTopCrest and true or false
        inputs[#inputs+1]=#triangles
    end
    local fieldGroups,fieldCount={},0
    for _,triangle in ipairs(triangles) do
        if inputs then
            inputs[#inputs+1]=triangle.arm;Values(triangle.a);Values(triangle.b);Values(triangle.c)
            local field=triangle.rectField
            if field and not fieldGroups[field] then fieldCount=fieldCount+1;fieldGroups[field]=fieldCount end
            inputs[#inputs+1]=field and fieldGroups[field] or false
        end
        if not prepared.slices[triangle.arm] then
            local slices,reason
            if op.branchSlices then slices=op.branchSlices[triangle.arm] end
            if not slices then slices,reason=ArmSlices(op,triangle.arm,best) end
            if not slices then return nil,reason end
            prepared.slices[triangle.arm]=slices
        end
    end
    for arm=1,4 do
        local slices=prepared.slices[arm] or {}
        if inputs then inputs[#inputs+1]=#slices end
        for _,slice in ipairs(slices) do
            if inputs then Values({slice.a,slice.b}) end
            if not SourceInput(slice.segment) then return nil,"unavailable branch source" end
        end
    end
    if inputs then
        inputs[#inputs+1]=#(op.protectedRects or {})
        for _,rect in ipairs(op.protectedRects or {}) do Values(rect) end
        inputs[#inputs+1]=#(op.roundCaps or {})
    end
    for _,cap in ipairs(op.roundCaps or {}) do
        if inputs then inputs[#inputs+1]=cap.item.texture;Values(cap.item.rect) end
        if not SourceInput(cap.segment) then return nil,"unavailable rounded-cap source" end
    end
    if prepared.focusBottomRim and not SourceInput(prepared.focusBottomRim) then
        return nil,"unavailable focus rim source"
    end
    if inputs and prepared.castRimDepth then inputs[#inputs+1]=prepared.castRimDepth end
    prepared.inputs=inputs
    return prepared
end
function J:BranchTriangles(op,best,prepared)
    if not prepared then
        local reason;prepared,reason=PrepareBranchFields(self,op,best,false)
        if not prepared then return nil,reason end
    end
    local r=op.rect
    local triangles=prepared.triangles
    local result={}
    local rectFields={}
    local crestBand
    local paintingCrest=false
    local focusRim=prepared.focusBottomRim
    if op.auraTopCrest then
        local low,high
        if op.hs.group and op.hs.group.actionStrip then
            low,high=op.y-op.hs.scale,op.y+op.hs.scale
        else
            low,high=op.y-min(best[1].scale,best[2].scale),r[4]
        end
        crestBand={r[1],max(r[2],low),r[3],min(r[4],high)}
    elseif focusRim then
        local bounds=focusRim.rect
        crestBand={r[1],max(r[2],bounds[2]),r[3],min(r[4],bounds[4],op.y+focusRim.scale)}
    end
    local function Point(v)
        return {v[1],v[2],r[1]+v[1]*(r[3]-r[1]),r[4]-v[2]*(r[4]-r[2])}
    end
    local function Emit(arm,segment,poly,rectField,slice)
        if #poly<3 then return true end
        local horizontal=arm<=2
        local along=horizontal and 3 or 4
        local source,bounds=prepared.sources[segment.texture or segment],segment.rect
        if not source or not bounds then return nil,"unavailable branch source" end
        local low,high=horizontal and bounds[1] or bounds[2],horizontal and bounds[3] or bounds[4]
        local regions={poly}
        if crestBand then
            if paintingCrest then
                regions={ClipField(ClipField(poly,4,crestBand[2],true),4,crestBand[4],false)}
            else
                local why;regions,why=ExcludeCaps(poly,{crestBand})
                if not regions then return nil,why end
            end
        end
        for _,poly in ipairs(regions) do
        local fields,reason=ExcludeCaps(poly,op.protectedRects)
        if not fields then return nil,reason end
        for _,poly in ipairs(fields) do
            local fields={ClipField(poly,along,low,false),ClipField(ClipField(poly,along,low,true),along,high,false),ClipField(poly,along,high,true)}
            for part,field in ipairs(fields) do
                local group
                if rectField then
                    local bySource=rectFields[rectField]
                    if not bySource then bySource={};rectFields[rectField]=bySource end
                    local identity=segment.texture or segment
                    local bySlice=bySource[identity]
                    if not bySlice then bySlice={};bySource[identity]=bySlice end
                    local key=slice.a..":"..slice.b..":"..part
                    group=bySlice[key]
                    if not group then group={};bySlice[key]=group end
                end
                local points={}
                local fieldLow,fieldHigh=math.huge,-math.huge
                for _,v in ipairs(field) do fieldLow=min(fieldLow,v[along]);fieldHigh=max(fieldHigh,v[along]) end
                for _,v in ipairs(field) do
                    local sx,sy=v[3],v[4]
                    if part~=2 then
                        local endpoint=part==1 and low or high
                        if horizontal then sx=EndpointSample(source,bounds[3]-bounds[1],sx,endpoint,fieldLow,fieldHigh)
                        else sy=EndpointSample(source,bounds[4]-bounds[2],sy,endpoint,fieldLow,fieldHigh) end
                    end
                    local u,tv=UVPoint(source.uv,(sx-bounds[1])/(bounds[3]-bounds[1]),(bounds[4]-sy)/(bounds[4]-bounds[2]))
                    points[#points+1]={v[1],v[2],u,tv}
                end
                local quad=(op.auraTopCrest or rectField) and RectangleField(points)
                local first=true
                for i=2,#points-1 do
                    local a,b,c=points[1],points[i],points[i+1]
                    local area=(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])
                    if abs(area)>1e-12 then
                        if #result>=self.limits.junctionTriangles then return nil,"junction triangle budget" end
                        result[#result+1]={arm=arm,a=a,b=b,c=c,texture=segment.texture,source=source,
                            quad=first and quad or nil,quadTail=quad and not first}
                        if group then group[#group+1]=result[#result] end
                        first=false
                    end
                end
            end
        end
        end
        return true
    end
    if op.auraTopCrest then
        paintingCrest=true
        -- Preserve the accepted aura/retained-strip crossbar policy exactly.
        for _,triangle in ipairs(triangles) do
            local horizontal=triangle.arm<=2
            local along,normal=horizontal and 3 or 4,horizontal and 4 or 3
            for _,slice in ipairs(prepared.slices[triangle.arm]) do
                local bounds=slice.segment.rect
                local poly={Point(triangle.a),Point(triangle.b),Point(triangle.c)}
                poly=ClipField(ClipField(poly,along,slice.a,true),along,slice.b,false)
                poly=ClipField(ClipField(poly,normal,horizontal and bounds[2] or bounds[1],true),normal,horizontal and bounds[4] or bounds[3],false)
                local ok,reason=Emit(triangle.arm,slice.segment,poly,triangle.rectField,slice)
                if not ok then return nil,reason end
            end
        end
        paintingCrest=false
    elseif focusRim then
        -- Continue the outer bevel beneath the portrait divider. The stem
        -- keeps its own source above this band, including its normal miter.
        local height=r[4]-r[2]
        local top,bottom=(r[4]-crestBand[4])/height,(r[4]-crestBand[2])/height
        paintingCrest=true
        local poly={Point({0,top}),Point({0,bottom}),Point({1,bottom}),Point({1,top})}
        local ok,reason=Emit(1,focusRim,poly,{}, {a=r[1],b=r[3]})
        if not ok then return nil,reason end
        paintingCrest=false
    end
    do
        local horizontal,vertical={},{}
        local function RectPoly(bounds)
            local function P(x,y)return {(x-r[1])/(r[3]-r[1]),(r[4]-y)/(r[4]-r[2]),x,y}end
            return {P(bounds[1],bounds[4]),P(bounds[1],bounds[2]),P(bounds[3],bounds[2]),P(bounds[3],bounds[4])}
        end
        local function Add(arm,slice)
            local segment=slice.segment
            local bounds,source=segment.rect,prepared.sources[segment.texture or segment]
            if not bounds or not source then return nil,"unavailable branch source" end
            local h=arm<=2
            local low,high=h and bounds[2] or bounds[1],h and bounds[4] or bounds[3]
            if source.support then
                if h then low,high=high-(high-low)*source.support[2],high-(high-low)*source.support[1]
                else low,high=low+(high-low)*source.support[1],low+(high-low)*source.support[2] end
            end
            local paint=segment.item and segment.item.paintRect
            if paint then
                local normal=h and 2 or 1
                low,high=max(low,paint[normal]),min(high,paint[normal+2])
            end
            local center=segment.rawP or segment.p
            if not PublicNumber(center) or center<=low or center>=high then return nil,"unsupported branch normal center" end
            local alongLow,alongHigh=slice.a,slice.b
            local node=h and op.x or op.y
            if arm==1 or arm==4 then alongHigh=min(alongHigh,node) else alongLow=max(alongLow,node) end
            local box=h and {max(r[1],alongLow),max(r[2],low),min(r[3],alongHigh),min(r[4],high)}
                or {max(r[1],low),max(r[2],alongLow),min(r[3],high),min(r[4],alongHigh)}
            if box[3]-box[1]>1e-10 and box[4]-box[2]>1e-10 then
                local list=h and horizontal or vertical
                list[#list+1]={arm=arm,slice=slice,segment=segment,rect=box,low=low,high=high,center=center}
                if #list>128 then return nil,"junction support interval budget" end
            end
            return true
        end
        for arm=1,4 do if floor(op.bits/2^(arm-1))%2==1 then
            for _,slice in ipairs(prepared.slices[arm] or {}) do
                local ok,reason=Add(arm,slice);if not ok then return nil,reason end
            end
        end end
        local function Exclusive(list,other)
            local cuts={};for _,entry in ipairs(other)do cuts[#cuts+1]=entry.rect end
            for _,entry in ipairs(list)do
                local fields,reason=ExcludeCaps(RectPoly(entry.rect),cuts)
                if not fields then return nil,reason end
                for _,field in ipairs(fields)do
                    local ok,why=Emit(entry.arm,entry.segment,field,{},entry.slice)
                    if not ok then return nil,why end
                end
            end
            return true
        end
        local ok,reason=Exclusive(horizontal,vertical);if not ok then return nil,reason end
        ok,reason=Exclusive(vertical,horizontal);if not ok then return nil,reason end
        -- Each same-axis run is disjoint. Its actual orthogonal intersection
        -- has one linear miter per own-raw-center quadrant, passing through
        -- the visible-support corner. No bevel coordinate or UV is bent.
        local function HalfPlane(poly,A,B,C,keepPositive)
            local out={};local previous=poly[#poly]
            if not previous then return out end
            local pvalue=A*previous[3]+B*previous[4]+C
            for _,current in ipairs(poly)do
                local value=A*current[3]+B*current[4]+C
                local pin=keepPositive and pvalue>=0 or not keepPositive and pvalue<=0
                local cin=keepPositive and value>=0 or not keepPositive and value<=0
                if pin~=cin then
                    local t=pvalue/(pvalue-value);local p={}
                    for i=1,4 do p[i]=previous[i]+t*(current[i]-previous[i])end
                    out[#out+1]=p
                end
                if cin then out[#out+1]=current end
                previous,pvalue=current,value
            end
            return out
        end
        local pairs=0
        for _,h in ipairs(horizontal)do for _,v in ipairs(vertical)do
            pairs=pairs+1;if pairs>self.limits.candidates then return nil,"junction support pair budget" end
            local hr,vr=h.rect,v.rect
            local overlap={max(hr[1],vr[1]),max(hr[2],vr[2]),min(hr[3],vr[3]),min(hr[4],vr[4])}
            if overlap[3]>overlap[1] and overlap[4]>overlap[2] then
                for _,sx in ipairs({-1,1})do for _,sy in ipairs({-1,1})do
                    local box={overlap[1],overlap[2],overlap[3],overlap[4]}
                    if sx<0 then box[3]=min(box[3],v.center) else box[1]=max(box[1],v.center) end
                    if sy<0 then box[4]=min(box[4],h.center) else box[2]=max(box[2],h.center) end
                    if box[3]-box[1]>1e-10 and box[4]-box[2]>1e-10 then
                        local hd=sy<0 and h.center-h.low or h.high-h.center
                        local vd=sx<0 and v.center-v.low or v.high-v.center
                        if not PublicNumber(hd) or not PublicNumber(vd) or hd<=0 or vd<=0 then return nil,"unsupported branch miter" end
                        local A,B=-sx*hd,sy*vd
                        local C=sx*hd*v.center-sy*vd*h.center
                        -- Keep the cast crossbar's ridge continuous while the
                        -- divider still shares the rest of the miter and shadow.
                        if prepared.castRimDepth then C=C-min(hd,prepared.castRimDepth)*vd end
                        local poly=RectPoly(box)
                        local hp=HalfPlane(poly,A,B,C,false)
                        local vp=HalfPlane(poly,A,B,C,true)
                        local success,why=Emit(h.arm,h.segment,hp,{},h.slice);if not success then return nil,why end
                        success,why=Emit(v.arm,v.segment,vp,{},v.slice);if not success then return nil,why end
                    end
                end end
            end
        end end
    end
    for _,bySource in pairs(rectFields) do for _,bySlice in pairs(bySource) do
        for _,group in pairs(bySlice) do MergeRectangleField(group) end
    end end
    -- Keep the unit's native curved cap above a short continuation of the
    -- incoming aura stem. The cap supplies the curved edge; no straight unit
    -- field replaces it, and the aura stem fills its transparent outside turn.
    for _,cap in ipairs(op.roundCaps or {}) do
        local segment=cap.segment
        local source,bounds=prepared.sources[segment.texture or segment],segment.rect
        if not source or not bounds then return nil,"unavailable rounded-cap source" end
        local c=cap.item.rect
        local x1,y1,x2,y2=max(c[1],r[1],bounds[1]),max(c[2],r[2]),min(c[3],r[3],bounds[3]),min(c[4],r[4])
        if x2>x1 and y2>y1 then
            local function Point(x,y)
                local sampleY=y
                if y<bounds[2] or y>bounds[4] then
                    sampleY=EndpointSample(source,bounds[4]-bounds[2],y,y<bounds[2] and bounds[2] or bounds[4],y1,y2)
                end
                local u,v=UVPoint(source.uv,(x-bounds[1])/(bounds[3]-bounds[1]),
                    (bounds[4]-sampleY)/(bounds[4]-bounds[2]))
                return {(x-r[1])/(r[3]-r[1]),(r[4]-y)/(r[4]-r[2]),u,v}
            end
            local a,b,c,d=Point(x1,y2),Point(x1,y1),Point(x2,y2),Point(x2,y1)
            for _,vs in ipairs({{a,b,c},{c,b,d}}) do
                if #result>=self.limits.junctionTriangles then return nil,"junction triangle budget" end
                result[#result+1]={a=vs[1],b=vs[2],c=vs[3],texture=segment.texture,source=source,roundFill=true}
            end
        end
    end
    return result
end
local function BranchRecordMatches(record,inputs)
    if not record or #record.inputs~=#inputs then return false end
    for i,value in ipairs(inputs) do if value~=record.inputs[i] then return false end end
    return true
end
local function CompileBranchFields(self,op,best)
    local prepared,reason=PrepareBranchFields(self,op,best,true)
    if not prepared then return nil,reason end
    local hid,vid=op.hs.paintID,op.vs.paintID
    local key=prepared.cacheable and hid and vid and hid..":"..vid..":"..op.bits
    local cached=key and branchCompilePrevious[key]
    local same=BranchRecordMatches(cached,prepared.inputs)
    if not same then
        cached=key and branchCompileAlternate[key]
        same=BranchRecordMatches(cached,prepared.inputs)
    end
    local result
    if same then
        self.stats.compileHits=(self.stats.compileHits or 0)+1
        result={}
        for _,geometry in ipairs(cached.geometry) do
            -- Paint descriptors must always come from this pass. Only numeric
            -- vertex/UV arrays and public texture identities are reusable.
            result[#result+1]={arm=geometry.arm,a=geometry.a,b=geometry.b,c=geometry.c,texture=geometry.texture,
                source=prepared.sources[geometry.texture],quad=geometry.quad,quadTail=geometry.quadTail,roundFill=geometry.roundFill}
        end
    else
        self.stats.compileMisses=(self.stats.compileMisses or 0)+1
        result,reason=self:BranchTriangles(op,best,prepared)
        if not result then return nil,reason end
    end
    local nextGeneration=branchCompileNext
    if key and nextGeneration and nextGeneration.operations<self.limits.operations
        and nextGeneration.triangles+#result<=self.limits.junctionTriangles
        and nextGeneration.values+#prepared.inputs<=self.limits.junctionTriangles*64 then
        local candidate=cached
        if not same then
            local geometry={}
            for _,triangle in ipairs(result) do geometry[#geometry+1]={arm=triangle.arm,a=triangle.a,b=triangle.b,c=triangle.c,
                texture=triangle.texture,quad=triangle.quad,quadTail=triangle.quadTail,roundFill=triangle.roundFill} end
            candidate={key=key,inputs=prepared.inputs,geometry=geometry}
        end
        op._branchCompileCandidate=candidate
        nextGeneration.operations=nextGeneration.operations+1
        nextGeneration.triangles=nextGeneration.triangles+#result
        nextGeneration.values=nextGeneration.values+#prepared.inputs
    end
    return result
end
Branches=function(op)
    local best={}
    for segment in pairs(op.segments) do
        local function Arm(arm)
            local distance=Tolerance(op.hs,op.vs)*1.25
            local probe=(segment.axis=="H" and op.x or op.y)+((arm==1 or arm==4) and -distance or distance)
            local candidate=PaintOwner(segment,probe)
            local old=best[arm]
            if not old or Above(candidate,old) then best[arm]=candidate end
        end
        local tolerance=Tolerance(op.hs,op.vs)
        if segment.axis=="H" then
            if segment.a<op.x-tolerance then Arm(1) end
            if segment.b>op.x+tolerance then Arm(2) end
        else
            if segment.b>op.y+tolerance then Arm(3) end
            if segment.a<op.y-tolerance then Arm(4) end
        end
    end
    return best
end
local drawPrevious={}
ClearDrawCache=function() drawPrevious={} end
local function DrawTriangle(op,index)
    local count=#op.triangles
    return index<=count and op.triangles[index] or op.fallbackTriangles[index-count]
end
local function DrawLayer(parent)
    local cached=renderLayers and renderLayers.draw[parent]
    if cached then return cached end
    local scale,x,y=RenderBasis(parent)
    local strata,level=parent:GetFrameStrata(),parent:GetFrameLevel()
    if issecretvalue and issecretvalue(strata) or type(strata)~="string" or not PublicNumber(level) then return end
    local layer={parent=parent,scale=scale,x=x,y=y,strata=strata,level=level}
    if renderLayers and renderLayers.applied[parent] then renderLayers.draw[parent]=layer end
    return layer
end
local function SameDrawGeometry(cached,base,tokens)
    if not cached or cached.base~=base or #cached.tokens~=(tokens and #tokens or 0) then return false end
    for i,value in ipairs(cached.tokens) do if value~=tokens[i] then return false end end
    return true
end
local function DrawDescriptor(op,cached)
    local base=op._branchCompileCandidate
    local tokens=op._fallbackGeometryTokens
    if not base or tokens==false then return end
    if op.fallbackTriangles and #op.fallbackTriangles>0 and type(tokens)~="table" then return end
    local previousInputs=SameDrawGeometry(cached,base,tokens) and cached.inputs or nil
    local values=not previousInputs and {} or nil
    local contexts,gates,canvases={},{},{}
    local stripLayer
    local inputs=op._preparedDrawInputs
    local count=inputs and #inputs or #op.triangles+#(op.fallbackTriangles or {})
    local cursor=0
    local function Add(value)
        if value==nil then return end
        cursor=cursor+1
        if previousInputs then
            if previousInputs[cursor]==value then return end
            -- All earlier values matched. Make a new list only when there is
            -- something different to retain for the next paint.
            values={}
            for i=1,cursor-1 do values[i]=previousInputs[i] end
            previousInputs=nil
        end
        values[cursor]=value
    end
    -- Regional fields can be clipped to a different output rectangle while
    -- sharing the original immutable branch. Include that actual draw box.
    for i=1,4 do if not PublicNumber(op.rect[i]) then return end;Add(op.rect[i]) end
    for index=1,count do
        local triangle=inputs and inputs[index] or DrawTriangle(op,index)
        if not triangle.quadTail then
            local source=triangle.texture
            if issecretvalue and issecretvalue(source) or not source then return end
            if not contexts[source] then
                local entry=clipped[source]
                local color=entry and entry.color
                if not entry or not entry.active or not color then return end
                -- RenderFragments installed this commit's validated paint.
                local currentPaint=entry.epoch==renderEpoch
                if not currentPaint then
                    for i=1,4 do if not PublicNumber(color[i]) then return end end
                end
                local privateAlpha=issecretvalue and issecretvalue(entry.alpha)
                if not currentPaint and not privateAlpha and not PublicNumber(entry.alpha) then return end
                local path=triangle.source and triangle.source.path
                if issecretvalue and issecretvalue(path) or type(path)~="string" and not PublicNumber(path) then return end
                local sourceParent=JunctionSourceParent(source)
                if issecretvalue and issecretvalue(sourceParent) then return end
                local retained=StaticUnitOwner(sourceParent)
                local layer
                if op.renderStrip and not retained and not sourceParent._FluxBorderOwnLayer then
                    stripLayer=stripLayer or DrawLayer(StripCanvas(op.renderStrip,op.renderLevel))
                    layer=stripLayer
                else
                    layer=canvases[sourceParent]
                    if not layer then
                        layer=DrawLayer(JunctionCanvas(sourceParent,op.members))
                        canvases[sourceParent]=layer
                    end
                end
                if not layer then return end
                contexts[source]=layer
                Add(source);Add(sourceParent);Add(layer.parent);Add(layer.scale);Add(layer.x);Add(layer.y);Add(layer.strata);Add(layer.level);Add(path)
                for i=1,4 do Add(color[i]) end
                Add(privateAlpha and "opaque" or "public");Add(privateAlpha and 0 or entry.alpha)
                Add(entry.sourceShown==false);Add(PaintAvailable(source))
            end
            local blockers=triangle.fallbackBlockers
            if blockers then
                local bySource=gates[source]
                if not bySource then bySource={};gates[source]=bySource end
                if bySource[blockers]==nil then
                    local enabled=PaintAvailable(source)
                    Add(source);Add(#blockers)
                    for _,blocker in ipairs(blockers) do
                        if issecretvalue and issecretvalue(blocker) then return end
                        Add(blocker)
                        if enabled and PaintAvailable(blocker) then enabled=false end
                    end
                    bySource[blockers]=enabled;Add(enabled)
                end
            end
        end
    end
    if previousInputs and cursor~=#previousInputs then
        values={}
        for i=1,cursor do values[i]=previousInputs[i] end
        previousInputs=nil
    end
    return {base=base,tokens=tokens or {},inputs=previousInputs or values,contexts=contexts,gates=gates},previousInputs~=nil
end
PrepareDrawReuse=function(op,cache,epoch)
    local base=op._branchCompileCandidate
    local cached=base and (cache or drawPrevious)[base.key]
    local prepared,same=DrawDescriptor(op,cached)
    op._drawPrepared=prepared
    if same then
        for i,field in ipairs(cached.sprites) do
            local triangle=DrawTriangle(op,cached.indices[i])
            local context=triangle and prepared.contexts[triangle.texture]
            local shown=field:IsShown()
            local parent=field:GetParent()
            if not context or not field._junctionOwnerOp or field._renderEpoch~=(epoch or renderEpoch-1)
                or issecretvalue and issecretvalue(parent) or parent~=context.parent or field._junctionSource~=triangle.texture
                or issecretvalue and issecretvalue(shown) or shown~=true then same=false;break end
            if triangle.fallbackBlockers and field._fallbackEnabled~=prepared.gates[triangle.texture][triangle.fallbackBlockers] then same=false;break end
        end
    end
    if same then
        -- Reserve all verified stable fields before any changed op allocates.
        op.sprites=cached.sprites;op._drawCandidate=cached;op._drawReused=true
        for _,field in ipairs(op.sprites) do
            field._renderEpoch=renderEpoch;field._junctionOwnerOp=op;field._junctionOp=nil
        end
        op.sprite=op.sprites[1];if op.sprite then op.sprite._junctionOp=op end
        if renderWork then
            renderWork.drawReuses=(renderWork.drawReuses or 0)+1
            renderWork.drawFields=(renderWork.drawFields or 0)+#op.sprites
        end
    elseif renderWork then renderWork.drawMisses=(renderWork.drawMisses or 0)+1 end
end
PublishDrawCache=function(operations,budget)
    local localCache=operations~=nil
    local nextGeneration={}
    budget=budget or {operations=0,fields=0,values=0}
    local count,fields,values=budget.operations,budget.fields,budget.values
    for _,op in ipairs(operations or active) do
        local candidate=op._drawCandidate
        if candidate and count<J.limits.operations
            and fields+#candidate.sprites<=J.limits.junctionTriangles
            and values+#candidate.inputs<=J.limits.junctionTriangles*64 then
            nextGeneration[candidate.base.key]=candidate
            count=count+1;fields=fields+#candidate.sprites;values=values+#candidate.inputs
        end
        op._drawCandidate=nil;op._drawPrepared=nil
    end
    local usage={operations=count-budget.operations,fields=fields-budget.fields,values=values-budget.values}
    budget.operations,budget.fields,budget.values=count,fields,values
    if not localCache then drawPrevious=nextGeneration end
    return nextGeneration,usage
end

local function DrawCanvas(parent,poolOwner,r)
    local pool=sprites[poolOwner]
    if not pool then pool={};sprites[poolOwner]=pool end
    local scale,px,py=RenderBasis(parent)
    return {parent=parent,poolOwner=poolOwner,pool=pool,
        x=(r[1]-px*scale)/scale,y=(r[2]-py*scale)/scale,w=(r[3]-r[1])/scale,h=(r[4]-r[2])/scale}
end

local function DrawFields(op,indices)
    local geometry=J._FieldGeometry
    local owner=op.hs.group
    for g in pairs(op.members) do
        if g.priority>owner.priority or g.priority==owner.priority and (g.paintID or g.id)<(owner.paintID or owner.id) then owner=g end
    end
    if op.hs.side=="Top" and op.hs.group.actionStrip then owner=op.hs.group end
    local r=op.rect
    op.sprites={}
    local contexts,canvases={},{}
    local stripContext
    local prepared=renderLayers and op._drawPrepared
    local shareBounds=renderLayers and renderLayers.shareBounds
    local bindSharedBounds=shareBounds and renderLayers.bindSharedBounds
    local baseCount=#op.triangles
    for index=1,baseCount+#(op.fallbackTriangles or {}) do
      local triangle=index<=baseCount and op.triangles[index] or op.fallbackTriangles[index-baseCount]
      if not triangle.quadTail then
        local source=triangle.texture
        local context=contexts[source]
        if not context then
            local sourceParent=JunctionSourceParent(source)
            -- Retained branches keep their unit's native fade. The strip
            -- crossbar stays on the strip when that unit clears.
            if op.renderStrip and not sourceParent._FluxBorderOwnLayer and not StaticUnitOwner(sourceParent) then
                if not stripContext then
                    local layer=prepared and prepared.contexts[source]
                    local parent=layer and renderLayers.applied[layer.parent] and layer.parent
                        or StripCanvas(op.renderStrip,op.renderLevel)
                    stripContext=DrawCanvas(parent,parent,r)
                end
                context=stripContext
            else
                context=canvases[sourceParent]
                if not context then
                    local layer=prepared and prepared.contexts[source]
                    local parent=layer and renderLayers.applied[layer.parent] and layer.parent
                        or JunctionCanvas(sourceParent,op.members)
                    context=DrawCanvas(parent,sourceParent,r)
                    canvases[sourceParent]=context
                end
            end
            -- The prepared descriptor and original fragments already resolved
            -- this commit's public source parent and canvas when available.
            contexts[source]=context
        end
        local parent,poolOwner,pool=context.parent,context.poolOwner,context.pool
        local x,y,w,h=context.x,context.y,context.w,context.h
        local free=pool.freeIndex or 1
        local t=pool[free]
        while t and t._junctionOwnerOp and t._renderEpoch==renderEpoch do free=free+1;t=pool[free] end
        if not t then
            t=parent:CreateTexture(nil,"OVERLAY",nil,7);pool[#pool+1]=t
            ContinuousSampling(t)
        end
        pool.freeIndex=free+1;t._junctionPoolOwner=poolOwner;t._renderEpoch=renderEpoch
        local slot=#op.sprites+1
        op.sprites[slot]=t;t._junctionOwnerOp=op;t._junctionOp=nil
        if indices then indices[slot]=index end
        if #op.sprites==1 then t._junctionOp=op;op.sprite=t end
        local entry=clipped[source]
        if t._junctionSource~=source and t._junctionSetCache then
            -- Live paint callbacks update a previous source's material/RGB.
            -- A newly assigned source cannot trust that prior paint descriptor.
            t._junctionSetCache.path=nil;t._junctionSetCache.color=nil
        end
        t._junctionSource=source;FieldPaint.Texture(t,triangle.source.path)
        local quad=triangle.quad
        local uv=triangle.drawUV
        t._junctionQuad=quad and true or nil
        if quad then
            local a,b,c,d=quad[1],quad[2],quad[3],quad[4]
            geometry.Box(t,parent,x+a[1]*w,y+(1-b[2])*h,(c[1]-a[1])*w,(b[2]-a[2])*h)
            if not uv then
                uv={a[3],a[4],b[3],b[4],c[3],c[4],d[3],d[4]}
                if triangle.retainUV then triangle.drawUV=uv end
            end
            FieldUV(t,uv)
            geometry.Vertices(t)
        else
            -- Draw the leader as an independent box before any dependent.
            -- A reserve hit keeps the complete operation, including its leader.
            local leader=shareBounds and context.leader
            if leader and t.SetAllPoints then
                local cache=t._junctionSetCache
                if cache.leader~=leader then
                    -- A new link costs a point clear and an all-points write.
                    -- Bind only when the direct box already needs both writes.
                    local box=cache.box
                    if not bindSharedBounds or box and not cache.leader
                        and not ((box.parent~=parent or box.x~=x or box.y~=y) and (box.w~=w or box.h~=h)) then
                        leader=nil
                    end
                end
            else
                leader=nil
            end
            if leader then
                geometry.Follow(t,leader)
            else
                geometry.Box(t,parent,x,y,w,h)
                if shareBounds then context.leader=t end
            end
            local a,b,c=triangle.a,triangle.b,triangle.c
            if not uv then
                uv={a[3],a[4],b[3],b[4],c[3],c[4],c[3],c[4]}
                if triangle.retainUV then triangle.drawUV=uv end
            end
            FieldUV(t,uv)
            geometry.Vertices(t,triangle,w,h)
        end
        if entry then geometry.Color(t,source,entry) else FieldColor(t,Color(owner)) end
        t._fallbackSource=nil;t._fallbackBlockers=nil
        if triangle.fallbackBlockers then RegisterFallback(t,source,triangle.fallbackBlockers)
        elseif entry then FieldAlpha(t,entry.sourceShown==false and 0 or entry.alpha)
        else FieldAlpha(t,1) end
        colorListeners[source]=colorListeners[source] or {};table.insert(colorListeners[source],t)
        FieldShow(t)
      end
    end
end

local function Draw(op)
    local prepared=op._drawPrepared
    if op._drawReused then
        local indices=op._drawCandidate.indices
        for i,field in ipairs(op.sprites) do
            local triangle=DrawTriangle(op,indices[i])
            local source=triangle.texture
            field._junctionSource=source;field._fallbackSource=nil;field._fallbackBlockers=nil
            if triangle.fallbackBlockers then RegisterFallback(field,source,triangle.fallbackBlockers,true) end
            local listeners=colorListeners[source]
            if not listeners then listeners={};colorListeners[source]=listeners end
            listeners[#listeners+1]=field
        end
    else
        -- Record the index as the sprite is drawn. A quad tail does not own
        -- a sprite, so its index stays out of the retained list.
        local indices=prepared and {}
        DrawFields(op,indices)
        if indices then
            local tokens={};for i,token in ipairs(prepared.tokens) do tokens[i]=token end
            op._drawCandidate={base=prepared.base,tokens=tokens,inputs=prepared.inputs,sprites=op.sprites,indices=indices}
        end
    end
end

local FallbackCells
do
-- Emit the ordered remainders of an intersecting cell into its final list.
-- Each remainder keeps the original visibility owners. The overlap is
-- returned for the caller to tag with the additional owner.
local function AppendFallbackRemainders(out,cell,cut)
    local r,blockers=cell.rect,cell.blockers
    local left,bottom,right,top=r[1],r[2],r[3],r[4]
    local innerLeft,innerBottom=max(left,cut[1]),max(bottom,cut[2])
    local innerRight,innerTop=min(right,cut[3]),min(top,cut[4])
    if left<innerLeft then out[#out+1]={rect={left,bottom,innerLeft,top},blockers=blockers} end
    if innerRight<right then out[#out+1]={rect={innerRight,bottom,right,top},blockers=blockers} end
    if bottom<innerBottom then out[#out+1]={rect={innerLeft,bottom,innerRight,innerBottom},blockers=blockers} end
    if innerTop<top then out[#out+1]={rect={innerLeft,innerTop,innerRight,top},blockers=blockers} end
    return {innerLeft,innerBottom,innerRight,innerTop}
end

-- Lost parallel fields are partitioned once at real owner boundaries. Their
-- pooled paint can change owner locally without reading or solving geometry.
FallbackCells=function(plan)
    local base=plan.item.paintRect or plan.item.rect
    local lost={base}
    for _,r in ipairs(plan.rects) do lost=J:Subtract(lost,r) end
    local cells={}
    for _,r in ipairs(lost) do cells[#cells+1]={rect=r,blockers={}} end
    for _,cut in ipairs(plan.item.availabilityCuts or {}) do
        local nextCells
        for i,cell in ipairs(cells) do
            if Intersects(cell.rect,cut.rect) then
                if not nextCells then
                    nextCells={}
                    for j=1,i-1 do nextCells[j]=cells[j] end
                end
                local overlap=AppendFallbackRemainders(nextCells,cell,cut.rect)
                local owners={unpack(cell.blockers)};local seen=false
                for _,owner in ipairs(owners) do if owner==cut.owner then seen=true;break end end
                if not seen then owners[#owners+1]=cut.owner end
                if #owners>32 then return nil,"visibility owner budget" end
                nextCells[#nextCells+1]={rect=overlap,blockers=owners}
            elseif nextCells then nextCells[#nextCells+1]=cell end
        end
        if nextCells then cells=nextCells end
        if #cells>J.limits.fragmentsPerPiece then return nil,"visibility field budget" end
    end
    local out={}
    for _,cell in ipairs(cells) do if #cell.blockers>0 then cell.plan=plan;out[#out+1]=cell end end
    return out
end
-- Optional retained dividers need a prebuilt perpendicular continuation.
-- Parallel backups keep their existing ownership/availability partitions.
function J:_PrepareUnitBranchFallbacks(operations,plans,blocked,byOwner)
    local staged=0
    local byOperation={}
    local function Axis(plan)
        local key=plan.item.record.key
        return (key=="Top" or key=="Bottom") and 1 or (key=="Left" or key=="Right") and 2
    end
    local function Add(blockers,owner)
        for _,saved in ipairs(blockers) do if saved==owner then return end end
        blockers[#blockers+1]=owner
    end
    local function Split(fields,cut,owner)
        local out={}
        for _,field in ipairs(fields) do
            if Intersects(field.rect,cut) then
                local overlap=AppendFallbackRemainders(out,field,cut)
                local blockers={unpack(field.blockers)};Add(blockers,owner)
                if #blockers>32 then return nil,"unit visibility owner budget" end
                out[#out+1]={rect=overlap,blockers=blockers}
            else out[#out+1]=field end
        end
        if #out>J.limits.fragmentsPerPiece then return nil,"unit visibility field budget" end
        return out
    end
    for _,op in ipairs(operations) do
        op._unitBranchPrepared=nil
        if op.bits and not blocked[op.root] then
        local unit=false
        for member in pairs(op.members) do unit=unit or member.unitOwner~=nil end
        if unit then
            local sources,ambiguous={},false
            for _,triangle in ipairs(op.triangles or {}) do
                -- Rounded-cap underlays have no arm and stay in the base mesh.
                local arm=triangle.arm
                if arm then
                    local axis=arm<=2 and 1 or 2
                    local source=triangle.texture
                    if sources[axis] and sources[axis]~=source then ambiguous=true;break end
                    sources[axis]=source
                end
            end
            if not ambiguous and sources[1] and sources[2] and sources[1]~=sources[2] then
                local choices,generated={},{0,0}
                for axis=1,2 do
                    local texture=sources[axis]
                    local plan=plans[texture]
                    local list={};choices[axis]=list
                    if plan and plan.root==op.root then list[1]={plan=plan,rect=plan.item.paintRect or plan.item.rect,blockers={}} end
                    for _,cell in ipairs(byOwner[texture] or {}) do
                        if cell.plan.root==op.root and Axis(cell.plan)==axis and Intersects(cell.rect,op.rect) then list[#list+1]=cell end
                    end
                end
                local profiles=true
                for axis=1,2 do
                    local primary=plans[sources[axis]]
                    if not primary or primary.root~=op.root then profiles=false end
                    for index=2,#choices[axis] do
                        if not primary or not self:_UnitFallbackProfileMatches(choices[axis][index].plan,primary) then profiles=false;break end
                    end
                end
                if profiles then
                for axis=1,2 do
                    local owner=sources[3-axis]
                    for _,choice in ipairs(choices[axis]) do
                        local r,cut=choice.rect,op.rect
                        if Intersects(r,cut) then
                            local blockers={unpack(choice.blockers)};Add(blockers,owner)
                            local fields={{rect={max(r[1],cut[1]),max(r[2],cut[2]),min(r[3],cut[3]),min(r[4],cut[4])},blockers=blockers}}
                            local why
                            if #blockers>32 then fields=nil;why="unit visibility owner budget" end
                            for index=2,#choices[3-axis] do
                                if not fields then break end
                                local backup=choices[3-axis][index]
                                fields,why=Split(fields,backup.rect,backup.plan.item.texture)
                            end
                            local plan=choice.plan
                            if fields then
                                -- These are junction-mesh contexts, not native
                                -- bitmap fragments on the long shared source.
                                -- Keep local partition and global mesh bounds.
                                if #fields>self.limits.fragmentsPerPiece or staged+#fields>self.limits.junctionTriangles then
                                    fields=nil;why="unit visibility field budget"
                                else staged=staged+#fields end
                            end
                            if not fields then blocked[op.root]=why
                            else
                                -- These continuations belong to this junction.
                                -- A shared edge can feed many other junctions.
                                local localOwners=byOperation[op]
                                if not localOwners then localOwners={};byOperation[op]=localOwners end
                                local cells=localOwners[owner]
                                if not cells then cells={};localOwners[owner]=cells end
                                generated[axis]=generated[axis]+#fields
                                for _,field in ipairs(fields) do field.plan=plan;cells[#cells+1]=field end
                            end
                        end
                    end
                end
                if not blocked[op.root] and generated[1]>0 and generated[2]>0 then op._unitBranchPrepared=true end
                end
            end
        end
    end end
    return byOperation
end
end
function J:_UnitFallbackProfileMatches(plan,keeper)
    local key=plan.item.record.key
    if capSides[key] or keeper.item.record.key~=key or keeper.root~=plan.root then return false end
    local axis=(key=="Top" or key=="Bottom") and 2 or 1
    local r,k=plan.item.rect,keeper.item.rect
    if not (PublicNumber(r[axis]) and PublicNumber(r[axis+2]) and PublicNumber(k[axis]) and PublicNumber(k[axis+2]))
        or abs(r[axis]-k[axis])>1/64 or abs(r[axis+2]-k[axis+2])>1/64 then return false end
    if plan.source.support and keeper.source.support==plan.source.support then return true end
    -- Type1 has no zero-margin optimization. Trust its full canonical profile
    -- separately without changing SourceSupport or accepting foreign nil bands.
    local expected=visibleSupport[key]
    if not expected then return false end
    local c=expected.uv
    for i=1,2 do
        local item=i==1 and plan or keeper
        local record,source=item.item.record,item.source
        if record.art~=PATH.."Battlefield100.tga" or record.artHandle~=source.path then return false end
        local uv=source.uv
        for _,value in ipairs(uv) do if not PublicNumber(value) then return false end end
        if #uv==4 then
            if uv[1]~=c[1] or uv[2]~=c[2] or uv[3]~=c[3] or uv[4]~=c[4] then return false end
        elseif #uv~=8 or uv[1]~=c[1] or uv[2]~=c[3] or uv[3]~=c[1] or uv[4]~=c[4]
            or uv[5]~=c[2] or uv[6]~=c[3] or uv[7]~=c[2] or uv[8]~=c[4] then return false end
    end
    return true
end
-- Only an admitted, complete unit restoration may replace a backup's raw
-- rectangle with its mesh aliases. The keeper already qualified these exact
-- cut rectangles through normal source/cap ownership; original cells stay intact.
function J:_TrimUnitBranchFallbackRects(operations,plans,blocked)
    local prepared={}
    for _,op in ipairs(operations) do
        if op._unitBranchPrepared and not blocked[op.root] then prepared[op.rect]=op.root end
    end
    if not next(prepared) then return end
    for _,plan in pairs(plans) do if not blocked[plan.root] and plan.fallbackRects then
        local fields
        for i,field in ipairs(plan.fallbackRects) do
            local rects
            for _,owner in ipairs(field.blockers) do
                local keeper=plans[owner]
                if keeper and self:_UnitFallbackProfileMatches(plan,keeper) then
                    for _,cut in ipairs(keeper.junctions or {}) do
                        if prepared[cut]==plan.root and Intersects(field.rect,cut) then
                            rects=self:Subtract(rects or {field.rect},cut)
                        end
                    end
                end
            end
            if rects then
                if not fields then
                    fields={}
                    for j=1,i-1 do fields[j]=plan.fallbackRects[j] end
                end
                for _,r in ipairs(rects) do fields[#fields+1]={rect=r,blockers=field.blockers} end
            elseif fields then
                fields[#fields+1]=field
            end
        end
        fields=fields or plan.fallbackRects
        if #plan.rects+#fields>self.limits.fragmentsPerPiece then blocked[plan.root]="unit visibility fragment budget"
        else plan.fallbackRects=fields end
    end end
end
-- Reuse only the numeric clipping/UV result from the last committed generation.
-- Fresh wrappers keep paint, blockers and MergeRectangleField flags pass-local.
local fallbackCompilePrevious,fallbackCompileNext={},nil
function J:_BeginFallbackCompileGeneration()
    fallbackCompileNext={operations=0,records=0,triangles=0,values=0}
    self.stats.fallbackCompileHits=0;self.stats.fallbackCompileMisses=0;self.stats.fallbackProbes=0
end
function J:_ClearFallbackCompileCache()
    fallbackCompilePrevious={};fallbackCompileNext=nil
end
function J:_PublishFallbackCompileCache()
    local previous,seen={},{}
    for _,op in ipairs(active) do
        if type(op._fallbackGeometryTokens)=="table" then
            for _,record in ipairs(op._fallbackGeometryTokens) do if not seen[record] then
                seen[record]=true
                local bucket=previous[record.base]
                if not bucket then bucket={};previous[record.base]=bucket end
                bucket[#bucket+1]=record
            end end
        end
    end
    fallbackCompilePrevious=previous;fallbackCompileNext=nil
end
-- These arrays are immutable only during the existing pure source-read plan.
-- Validate each current array once there; standalone callers always read fresh.
-- Committed records retain copied public numeric chunks, never this phase state.
local function FallbackArray(values,state)
    if type(values)~="table" or issecretvalue and issecretvalue(values)
        or issecrettable and issecrettable(values)
        or canaccesstable and not canaccesstable(values) then return end
    local saved=state and state.valid[values]
    if saved~=nil then return saved or nil end
    local count=#values
    local numbers=state and values or {}
    for i=1,count do
        local value=values[i]
        if not PublicNumber(value) then
            if state then state.valid[values]=false end
            return
        end
        if not state then numbers[i]=value end
    end
    local result={n=count,values=numbers}
    if state then state.valid[values]=result end
    return result
end
local function FallbackInputs(op,triangle,cell)
    local arm=triangle.arm or 0
    if not PublicNumber(arm) then return end
    local state
    if sourceReadPlan then
        state=sourceReadPlan.fallbackGuard
        if not state then state={valid={}};sourceReadPlan.fallbackGuard=state end
    end
    local arrays={triangle.a,triangle.b,triangle.c,op.rect,cell.rect,cell.plan.item.rect,cell.plan.source.uv}
    for i=1,7 do
        local guarded=FallbackArray(arrays[i],state)
        if not guarded then return end
        arrays[i]=guarded
    end
    arrays.arm=arm;arrays.state=state;return arrays
end
local function FallbackChunkMatches(current,old,state)
    if type(old)~="table" or #old~=current.n then return false end
    if state and current.chunk==old then return current.same end
    local matches=state and current.matches
    if matches and matches[old]~=nil then return matches[old] end
    local same=true
    for i=1,current.n do if current.values[i]~=old[i] then same=false;break end end
    if state then
        if not current.chunk then current.chunk=old;current.same=same
        else
            if not matches then matches={[current.chunk]=current.same};current.matches=matches end
            matches[old]=same
        end
        if same and not current.copy then current.copy=old end
    end
    return same
end
local function FallbackMatches(inputs,snapshot)
    if not snapshot or snapshot.arm~=inputs.arm or #snapshot.chunks~=7 then return false end
    for i=1,7 do if not FallbackChunkMatches(inputs[i],snapshot.chunks[i],inputs.state) then return false end end
    return true
end
local function FallbackSnapshot(inputs)
    local chunks,scalars={},0
    for i,current in ipairs(inputs) do
        local copied=inputs.state and current.copy
        if not copied then
            if not inputs.state then copied=current.values
            else
                copied={}
                for n=1,current.n do copied[n]=current.values[n] end
                current.copy=copied
            end
        end
        chunks[i]=copied;scalars=scalars+current.n
    end
    return {arm=inputs.arm,chunks=chunks},scalars
end
local function StageFallback(op,record)
    local generation=fallbackCompileNext
    if not generation or op._fallbackGeometryTokens==false then op._fallbackGeometryTokens=false;return end
    local first=not op._fallbackGeometryTokens
    local values=record.retainedValues
    if generation.operations+(first and 1 or 0)>J.limits.operations
        or generation.records+1>J.limits.junctionTriangles
        or generation.triangles+#record.geometry>J.limits.junctionTriangles
        or generation.values+values>J.limits.junctionTriangles*64 then
        op._fallbackGeometryTokens=false;return
    end
    if first then op._fallbackGeometryTokens={};generation.operations=generation.operations+1 end
    op._fallbackGeometryTokens[#op._fallbackGeometryTokens+1]=record
    generation.records=generation.records+1;generation.triangles=generation.triangles+#record.geometry
    generation.values=generation.values+values
end
function J._FallbackDisjoint(a,b,c,left,right,top,bottom)
    return max(a[1],b[1],c[1])<left or min(a[1],b[1],c[1])>right
        or max(a[2],b[2],c[2])<top or min(a[2],b[2],c[2])>bottom
end
local function FallbackTriangles(op,triangle,cell,publicGeometry)
    local r,bounds=op.rect,cell.rect
    local a,b,c=triangle.a,triangle.b,triangle.c
    local w,h,left,right,top,bottom
    if publicGeometry then
        w,h=r[3]-r[1],r[4]-r[2]
        left,right=(bounds[1]-r[1])/w,(bounds[3]-r[1])/w
        top,bottom=(r[4]-bounds[4])/h,(r[4]-bounds[2])/h
        if J._FallbackDisjoint(a,b,c,left,right,top,bottom) then return 0 end
    end
    local item,source=cell.plan.item,cell.plan.source
    local inputs=FallbackInputs(op,triangle,cell)
    local cacheable=inputs and not (issecretvalue and issecretvalue(item.texture))
    local bucket=cacheable and fallbackCompilePrevious[a]
    -- Ordinary fans are cheaper as flat lists. Build an index only when a
    -- larger committed bucket is actually queried; publication stays flat.
    if bucket and #bucket>4 then
        local index=bucket._tuple
        if not index then
            index={}
            for _,record in ipairs(bucket) do
                local byB=index[record.texture]
                if not byB then byB={};index[record.texture]=byB end
                local byC=byB[record.b]
                if not byC then byC={};byB[record.b]=byC end
                local fields=byC[record.c]
                if not fields then fields={};byC[record.c]=fields end
                fields[#fields+1]=record
            end
            bucket._tuple=index
        end
        local byB=index[item.texture]
        local byC=byB and byB[b]
        bucket=byC and byC[c]
    end
    local cached
    local probes=0
    for _,record in ipairs(bucket or {}) do
        probes=probes+1
        local same=record.texture==item.texture and FallbackMatches(inputs,record.guardSnapshot)
        if same then cached=record;break end
    end
    J.stats.fallbackProbes=(J.stats.fallbackProbes or 0)+probes
    local geometry,aliasesPresent
    if cached then
        J.stats.fallbackCompileHits=(J.stats.fallbackCompileHits or 0)+1
        geometry=cached.geometry;aliasesPresent=cached.aliasesPresent
    else
        J.stats.fallbackCompileMisses=(J.stats.fallbackCompileMisses or 0)+1
        geometry={};aliasesPresent=0
        if not publicGeometry then
            w,h=r[3]-r[1],r[4]-r[2]
            left,right=(bounds[1]-r[1])/w,(bounds[3]-r[1])/w
            top,bottom=(r[4]-bounds[4])/h,(r[4]-bounds[2])/h
        end
        if publicGeometry or not J._FallbackDisjoint(a,b,c,left,right,top,bottom) then
            aliasesPresent=1
            local poly={a,b,c}
            poly=ClipField(poly,1,left,true)
            if #poly>0 then poly=ClipField(poly,1,right,false) end
            if #poly>0 then poly=ClipField(poly,2,top,true) end
            if #poly>0 then poly=ClipField(poly,2,bottom,false) end
            local points={}
            for _,p in ipairs(poly) do
                local x,y=r[1]+p[1]*w,r[4]-p[2]*h
                local u,v=UVPoint(source.uv,(x-item.rect[1])/(item.rect[3]-item.rect[1]),(item.rect[4]-y)/(item.rect[4]-item.rect[2]))
                points[#points+1]={p[1],p[2],u,v}
            end
            for i=2,#points-1 do
                local pa,pb,pc=points[1],points[i],points[i+1]
                if abs((pb[1]-pa[1])*(pc[2]-pa[2])-(pb[2]-pa[2])*(pc[1]-pa[1]))>1e-12 then geometry[#geometry+1]={pa,pb,pc} end
            end
        end
    end
    if cacheable then
        local nextRecord=cached
        if not nextRecord then
            local guardSnapshot,scalars=FallbackSnapshot(inputs)
            -- Keep the conservative charge for guard scalars, their former
            -- flat copy, seven length entries and two arm entries.
            nextRecord={base=a,b=b,c=c,guardSnapshot=guardSnapshot,retainedValues=2*scalars+9+#geometry*12,
                texture=item.texture,geometry=geometry,aliasesPresent=aliasesPresent}
        end
        StageFallback(op,nextRecord)
    else op._fallbackGeometryTokens=false end
    if aliasesPresent==1 then
        cell.aliasGroups=cell.aliasGroups or {}
        local aliases=cell.aliasGroups[op]
        if not aliases then aliases={};cell.aliasGroups[op]=aliases end
        for _,points in ipairs(geometry) do
            local field={arm=triangle.arm,a=points[1],b=points[2],c=points[3],texture=item.texture,source=source,fallbackBlockers=cell.blockers}
            op.fallbackTriangles=op.fallbackTriangles or {}
            op.fallbackTriangles[#op.fallbackTriangles+1]=field;aliases[#aliases+1]=field
        end
    end
    return #geometry
end
-- Numeric output is retained only from the last successful commit. Current
-- native rectangles, masks, UVs and Source paint are still read by the caller.
local fallbackPlanPrevious,fallbackPlanAlternate={},{}
function J:_ClearFallbackPlanCache()
    fallbackPlanPrevious={};fallbackPlanAlternate={};self._discardAlternatePlans=nil
end
function J:_ClearAlternatePlans()
    branchCompileAlternate={};fallbackPlanAlternate={};self._discardAlternatePlans=true
end
function J:_PublishFallbackPlanCache()
    local kept={}
    local count,fields,values=0,0,0
    for _,op in ipairs(active) do
        local candidate=op._fallbackPlanCandidate or op._fallbackPlanCommitted
        if candidate and count<self.limits.operations
            and fields+#candidate.fields<=self.limits.junctionTriangles
            and values+candidate.values<=self.limits.junctionTriangles*64 then
            kept[candidate.key]=candidate;op._fallbackPlanCommitted=candidate
            count=count+1;fields=fields+#candidate.fields;values=values+candidate.values
        else op._fallbackPlanCommitted=nil end
        op._fallbackPlanCandidate=nil
    end
    local alternate={}
    local retained,tokens=0,0
    for key,current in pairs(kept) do
        local prior=fallbackPlanPrevious[key]
        if prior==current then prior=fallbackPlanAlternate[key] end
        if not self._discardAlternatePlans and prior and prior~=current
            and (prior.base==current.base or prior.base==branchCompileAlternate[key])
            and retained<64 and count<self.limits.operations
            and tokens+#prior.tokens<=min(1024,self.limits.junctionTriangles) then
            local charge=prior.values
            for _,token in ipairs(prior.tokens) do
                charge=charge+token.retainedValues
            end
            if fields+#prior.fields<=self.limits.junctionTriangles
                and values+charge<=self.limits.junctionTriangles*64 then
                alternate[key]=prior;retained=retained+1;tokens=tokens+#prior.tokens
                count=count+1;fields=fields+#prior.fields;values=values+charge
            end
        end
    end
    fallbackPlanAlternate=alternate;fallbackPlanPrevious=kept;self._discardAlternatePlans=nil
end
local function FallbackPlanInputs(op,blocked,byOwner,unitOwners,cacheable)
    if not next(byOwner) and not (unitOwners and next(unitOwners)) then return end
    local byTexture={}
    local contexts,byBlockers,inputs
    local function Add(value) inputs[#inputs+1]=value end
    local function Values(values)
        Add(#values)
        for _,value in ipairs(values) do Add(value) end
    end
    local function AppendCells(owner,candidates,cells)
        if not candidates then return cells end
        for _,cell in ipairs(candidates) do
            if cell.plan.root==op.root and not blocked[cell.plan.root] and Intersects(cell.rect,op.rect) then
                if cacheable and not cells then
                    inputs=inputs or {}
                    byBlockers=byBlockers or {}
                    Add(owner)
                end
                cells=cells or {}
                contexts=contexts or {}
                cells[#cells+1]=cell;contexts[#contexts+1]=cell
                if cacheable then
                    local texture=cell.plan.item.texture
                    local bindings=byBlockers[cell.blockers]
                    if not bindings then bindings={};byBlockers[cell.blockers]=bindings end
                    bindings[texture]=#contexts
                    Add(texture)
                    Values(cell.rect);Values(cell.plan.item.rect);Values(cell.plan.source.uv)
                    Add(#cell.blockers)
                    for _,blocker in ipairs(cell.blockers) do Add(blocker) end
                end
            end
        end
        return cells
    end
    -- Base triangles are immutable compiled public numbers. The current cells
    -- were just partitioned from freshly validated native pieces; no native
    -- getter answers or current Source wrappers survive in the copied inputs.
    -- The base already fixes the triangle sources, so only contributing
    -- owners belong in the fallback key.
    for _,triangle in ipairs(op.triangles) do
        local owner=triangle.texture
        if byTexture[owner]==nil then
            local cells=AppendCells(owner,byOwner[owner])
            cells=AppendCells(owner,unitOwners and unitOwners[owner],cells)
            byTexture[owner]=cells or false
            if cells and cacheable then Add(#cells) end
        end
    end
    return contexts,byTexture,byBlockers,inputs
end
local function FallbackPlanMatches(record,base,inputs)
    if not inputs or not record or record.base~=base or #record.inputs~=#inputs then return false end
    for i,value in ipairs(inputs) do if value~=record.inputs[i] then return false end end
    return true
end
function J:_CompileFallbackPlans(operations,blocked,byOwner,total,unitFallbacks)
    local stagedValues,stagedFields,stagedOperations=0,0,0
    self.stats.fallbackPlanHits=0;self.stats.fallbackPlanMisses=0
    for _,op in ipairs(operations) do if op.bits and not blocked[op.root] then
        -- Standalone callers keep the full compiler path. Reuse is admitted
        -- only inside the existing pure, fresh Source-read planning phase.
        local base=sourceReadPlan and op._branchCompileCandidate
        local contexts,byTexture,byBlockers,inputs=FallbackPlanInputs(op,blocked,byOwner,unitFallbacks and unitFallbacks[op],base)
        local record=base and fallbackPlanPrevious[base.key]
        local same=FallbackPlanMatches(record,base,inputs)
        if not same then
            record=base and fallbackPlanAlternate[base.key]
            same=FallbackPlanMatches(record,base,inputs)
        end
        if same then
            self.stats.fallbackPlanHits=self.stats.fallbackPlanHits+1
            -- Preserve the exact existing per-generation scalar/record/triangle
            -- budgets and immutable draw tokens, even when compilation is skipped.
            for _,token in ipairs(record.tokens) do StageFallback(op,token) end
            self.stats.fallbackCompileHits=(self.stats.fallbackCompileHits or 0)+#record.tokens
            if #record.fields>0 then op.fallbackTriangles={} end
            for _,field in ipairs(record.fields) do
                local cell=contexts[field.context]
                op.fallbackTriangles[#op.fallbackTriangles+1]={arm=field.arm,
                    a=field.a,b=field.b,c=field.c,quad=field.quad,quadTail=field.quadTail,
                    texture=cell.plan.item.texture,source=cell.plan.source,
                    fallbackBlockers=cell.blockers}
            end
            total=total+#record.fields
        else
            self.stats.fallbackPlanMisses=self.stats.fallbackPlanMisses+1
            if contexts then
                -- Only compiled base fields may use the early geometric check.
                local publicGeometry=not not base
                for _,triangle in ipairs(op.triangles) do
                    local cells=byTexture[triangle.texture]
                    if cells then
                        for _,cell in ipairs(cells) do
                            total=total+FallbackTriangles(op,triangle,cell,publicGeometry)
                            if total>self.limits.junctionTriangles then return total,"visibility triangle budget" end
                        end
                    end
                end
                -- A cell can occur under several keeper textures. Process each
                -- current group once, preserving the old per-cell merge behavior.
                local merged={}
                for _,cell in ipairs(contexts) do if not merged[cell] then
                    merged[cell]=true
                    local group=cell.aliasGroups and cell.aliasGroups[op]
                    if group then MergeRectangleField(group) end
                end end
            end
            record=nil
            if inputs and type(op._fallbackGeometryTokens)=="table" then
                local fields={};local values=#inputs
                for _,triangle in ipairs(op.fallbackTriangles or {}) do
                    local binding=byBlockers[triangle.fallbackBlockers]
                    local context=binding and binding[triangle.texture]
                    if not context then fields=nil;break end
                    fields[#fields+1]={arm=triangle.arm,a=triangle.a,b=triangle.b,c=triangle.c,
                        quad=triangle.quad,quadTail=triangle.quadTail,context=context}
                    -- Count 12 vertex/UV scalars, arm/context/quadTail and up to16 quad
                    -- scalars. Shared immutable arrays are conservatively charged.
                    values=values+15+(triangle.quad and 16 or 0)
                end
                if fields then record={key=base.key,base=base,inputs=inputs,fields=fields,
                    tokens=op._fallbackGeometryTokens,values=values} end
            end
        end
        -- Compile-token staging may reject caching while the current fresh
        -- drawing remains valid. Never carry those rejected tokens forward.
        if record and type(op._fallbackGeometryTokens)=="table"
            and stagedOperations<self.limits.operations
            and stagedValues+record.values<=self.limits.junctionTriangles*64
            and stagedFields+#record.fields<=self.limits.junctionTriangles then
            stagedValues=stagedValues+record.values
            stagedFields=stagedFields+#record.fields
            stagedOperations=stagedOperations+1
            op._fallbackPlanCandidate=record
        end
        if total>self.limits.junctionTriangles then return total,"visibility triangle budget" end
    end end
    return total
end
local function RenderFallbackRectangles(plan)
    local rectangles=plan.fallbackRects
    if not rectangles or #rectangles==0 then return end
    local texture=plan.item.texture
    local entry=clipped[texture]
    local sourceParent,layer,sublevel=FragmentSource(texture)
    local parent=plan.roundCap and CapCanvas(sourceParent)
        or plan.renderMembers and JunctionCanvas(sourceParent,plan.renderMembers) or sourceParent
    local scale,px,py=RenderBasis(parent)
    local samples=plan.fallbackUVs
    local geometry=J._FieldGeometry
    for i,field in ipairs(rectangles) do
        local index=(entry.normalCount or 0)+i
        local t=entry.pool[index]
        if t and t:GetParent()~=parent then t:SetParent(parent) end
        if not t then t=parent:CreateTexture(nil,layer,nil,sublevel);entry.pool[index]=t;ContinuousSampling(t) end
        local r=field.rect
        t._renderEpoch=renderEpoch
        FieldPaint.Layer(t,layer,sublevel);FieldPaint.Texture(t,plan.source.path)
        local uv=samples and samples[i]
        if not uv then
            uv=SliceUV(plan.source.uv,plan.item.rect,r)
            if samples then samples[i]=uv end
        end
        FieldUV(t,uv)
        geometry.Box(t,parent,r[1]/scale-px,r[2]/scale-py,(r[3]-r[1])/scale,(r[4]-r[2])/scale)
        geometry.Color(t,texture,entry)
        RegisterFallback(t,texture,field.blockers);FieldShow(t)
    end
end

local function Affected(item,g,op)
    if not Intersects(item.rect,op.rect) then return false end
    local sides=op.edges[g]
    local key=item.record.key
    if op.protectedCaps and op.protectedCaps[item] then return false end
    if sides[key] then return true end
    local cap=capSides[key]
    if cap then for side in pairs(cap) do if sides[side] then return true end end end
    return false
end

-- Phase clocks run only while the user has armed the existing finite spike
-- watch. Keep one last and one peak consumed pass; no default profiler/ticker.
local costWatch,lastCost,peakCost
local function CostClock()
    if type(debugprofilestop)~="function" then return end
    local ok,value=pcall(debugprofilestop)
    if not ok then return end
    -- Uptime clocks routinely exceed the coordinate validator's screen bound.
    if not (issecretvalue and issecretvalue(value)) and type(value)=="number"
        and value==value and value>=0 and value<math.huge then return value end
end
local function BeginCost()
    local capture=Flux and Flux.PerfCapture
    local report=capture and capture.GetActiveWatchReport and capture.GetActiveWatchReport()
    if (issecretvalue and issecretvalue(report)) or type(report)~="table" then return end
    if costWatch~=report then costWatch=report;lastCost=nil;peakCost=nil end
    local now=CostClock()
    if not now then return end
    return {started=now,last=now,phases={}}
end
local function MarkCost(cost,name)
    if not cost then return end
    local now=CostClock()
    if not now or now<cost.last then cost.invalid=true;return end
    cost.phases[name]=(cost.phases[name] or 0)+now-cost.last;cost.last=now
end
local function CommitCost(cost,name,meshPrepared)
    if not cost then return end
    local now=CostClock()
    if not now or now<cost.commitLast then cost.invalid=true;return end
    -- Reuse the existing aggregate boundaries. An unavailable/invalid optional
    -- midpoint drops detail only; it must not invalidate a valid legacy span.
    if name=="mesh" and meshPrepared and meshPrepared>=cost.commitLast and meshPrepared<=now then
        cost.meshPhases={prepare=meshPrepared-cost.commitLast,draw=now-meshPrepared}
    end
    cost.commitPhases[name]=now-cost.commitLast;cost.commitLast=now
end
local function PlanCost(cost,name)
    if not cost then return end
    local now=CostClock()
    if not now or now<cost.planLast then cost.invalid=true;return end
    cost.planPhases[name]=now-cost.planLast;cost.planLast=now
end
local function EndCost(cost,kind)
    if not cost then return end
    if cost.invalid then return end
    cost.total=cost.last-cost.started;cost.kind=kind
    cost.borderVersion=J.version
    cost.operations=J.stats.operations or 0;cost.fragments=J.stats.fragments or 0;cost.triangles=J.stats.triangles or 0
    cost.baseHits=J.stats.compileHits or 0;cost.baseMisses=J.stats.compileMisses or 0
    cost.sourceReads=J.stats.sourceReads or 0;cost.sourceHits=J.stats.sourceHits or 0
    cost.fallbackHits=J.stats.fallbackCompileHits or 0;cost.fallbackMisses=J.stats.fallbackCompileMisses or 0
    cost.fallbackProbes=J.stats.fallbackProbes or 0
    cost.fallbackPlanHits=J.stats.fallbackPlanHits or 0;cost.fallbackPlanMisses=J.stats.fallbackPlanMisses or 0
    cost.localCells=J.stats.localCells or 0;cost.localUpdated=J.stats.localUpdated or 0
    lastCost=cost
    if not peakCost or cost.total>peakCost.total then peakCost=cost end
    if costWatch then costWatch.borderPeak=peakCost;costWatch.borderLast=lastCost end
end
-- WoW's Lua 5.1 compiler permits at most 60 captured locals per function.
-- Bundle renderer bookkeeping so the structural transaction stays below it.
local function BeginRenderGeneration()
    rollbackActive=active;active={};renderEpoch=renderEpoch+1
    renderBases={};renderLayers=nil
    fallbackChains=nil;fallbackAvailability=nil
    committedSegments=setmetatable({}, {__mode="k"});colorListeners=setmetatable({}, {__mode="k"})
    visibilityListeners=setmetatable({}, {__mode="k"});availabilityCache=setmetatable({}, {__mode="k"})
    for _,pool in pairs(sprites) do pool.freeIndex=1 end
    J._RetireArrowCanvasLevels()
    for _,canvas in pairs(junctionCanvases) do canvas._requiredRank=nil;canvas._requiredLevel=0 end
    for _,canvas in pairs(stripCanvases) do canvas._requiredLevel=0 end
    painting=true
end
local function EndRenderGeneration()
    renderBases=nil;renderLayers=nil;fallbackChains=nil;fallbackAvailability=nil;painting=false
end
-- A direct eligible commit consumes prior scheduled work. Early returns for
-- combat/readiness retain a useful existing wake; replacement timers retain
-- the same deadline and publish ownership only after successful registration.
local function NewFlushWake(owner)
    if owner==nil then owner=wakeOwner end
    return function() if owner==wakeOwner then J:Flush() end end
end
local function DelayFlush(delay)
    local prior=wakeOwner
    wakeSequence=wakeSequence+1
    local replacement=wakeSequence
    C_Timer.After(delay,NewFlushWake(replacement))
    if wakeOwner==prior then wakeOwner=replacement end
end
local function ConsumeFlushWake()
    wakeSequence=wakeSequence+1;wakeOwner=wakeSequence
end
local function PrepareFragmentOwners(operations,plans,blocked)
    local owners={}
    for _,op in ipairs(operations) do if not blocked[op.root] then
        local hasUnit=false
        for member in pairs(op.members) do if member.unitOwner then hasUnit=true;break end end
        for group in pairs(op.members) do
            local state=owners[group]
            local first=not state
            if first then
                state={members={}}
                owners[group]=state
                for _,item in ipairs(group.pieces) do
                    local plan=plans[item.texture]
                    if plan then plan.renderMembers=state.members else state.unplanned=true end
                end
            end
            if state.unplanned and (group.fixedBounds or hasUnit and not group.unitOwner) then
                -- A newly needed fragment inherits its creation contact and
                -- later contacts. Existing fragments include earlier ones too.
                state.defaults=first and state.members or {}
                for _,item in ipairs(group.pieces) do
                    if not plans[item.texture] then
                        local source=Source(item.texture)
                        if source then
                            plans[item.texture]={root=op.root,item=item,source=source,rects={item.rect},renderMembers=state.defaults}
                        end
                    end
                end
                -- Source caches absence until the current plan pass ends.
                state.unplanned=nil
            end
            local members,defaults=state.members,state.defaults
            if defaults==members then defaults=nil end
            for member in pairs(op.members) do
                members[member]=true
                if defaults then defaults[member]=true end
            end
        end
    end end
end

function J:_PreparePlan(segments,operations,cost,signature,meshOperations)
    local plans,blocked,total
    local planAborted=false
    local regional=meshOperations~=nil
    -- Long shared sources bring distant contacts into the solve closure. Keep
    -- their cuts/ownership, but compile meshes only for output being replaced.
    meshOperations=meshOperations or operations
    local sourcePass={values={},reads=0,hits=0};sourceReadPlan=sourcePass
    local planOK,planError=pcall(function()
    if self._BeginFallbackCompileGeneration then self:_BeginFallbackCompileGeneration() end
    -- A private/masked source falls back only in its connected component; a
    -- separate action strip or unit frame can still receive its complete joins.
    local roots={}
    local function Root(g)
        local r=roots[g]
        if not r then roots[g]=g;return g end
        if r~=g then roots[g]=Root(r) end
        return roots[g]
    end
    for _,op in ipairs(operations) do
        local first
        for g in pairs(op.members) do
            local root=Root(g)
            if first then roots[root]=Root(first) else first=root end
        end
    end
    plans,blocked,total={}, {},0
    -- Internal straight dividers end at another stroke, not at an outer cap.
    -- Their full original texture rectangle includes extra cap/shadow space;
    -- trim that paint even when the endpoint is an ordinary L, not a T/X.
    for _,segment in ipairs(segments) do
        local item=segment.item
        if item.paintRect then
            local root=Root(segment.group)
            local source=Source(item.texture)
            if source then plans[item.texture]={root=root,item=item,source=source,rects={item.paintRect}}
            else blocked[root]="unavailable or masked source" end
        end
    end
    for _,op in ipairs(operations) do
        for g in pairs(op.members) do op.root=Root(g);break end
        for _,cap in ipairs(op.roundCaps or {}) do
            local item=cap.item
            local source=Source(item.texture)
            if source then plans[item.texture]={root=op.root,item=item,source=source,rects={item.rect},roundCap=true}
            else blocked[op.root]="unavailable rounded cap" end
        end
        if not blocked[op.root] then
            for _,item in ipairs(op.corners or {}) do
                local plan=plans[item.texture]
                if not plan then
                    local source=Source(item.texture)
                    if not source then blocked[op.root]="unavailable or masked corner";break end
                    plan={root=op.root,item=item,source=source,rects={}};plans[item.texture]=plan
                else plan.rects={} end
            end
        end
        for g in pairs(op.cut) do
            if not blocked[op.root] then
                for _,item in ipairs(g.pieces) do
                    if Affected(item,g,op) then
                        local plan=plans[item.texture]
                        if not plan then
                            local source=Source(item.texture)
                            if not source then blocked[op.root]="unavailable or masked source";break end
                            plan={root=op.root,item=item,source=source,rects={item.rect}};plans[item.texture]=plan
                        end
                        if op.bits then
                            plan.junctions=plan.junctions or {};plan.junctions[#plan.junctions+1]=op.rect
                        end
                        plan.rects=self:Subtract(plan.rects,op.rect)
                        if #plan.rects>self.limits.fragmentsPerPiece then blocked[op.root]="piece fragment budget";break end
                    end
                end
            end
        end
    end
    -- A strip-owned seam must render above the portraits which terminate at
    -- it. Keep the source's visibility/scale owner, but use a raised child.
    local stripLevels
    for _,op in ipairs(operations) do
        local strip,hasUnit,level=nil,false,0
        for g in pairs(op.members) do
            if g.actionStrip then strip=g.stripRoot end
            hasUnit=hasUnit or g.unitOwner~=nil
            if not regional and not g.parent._FluxBorderOwnLayer then
                local value=g.parent:GetFrameLevel()
                if PublicNumber(value) then level=max(level,value+1) end
            end
        end
        if strip and hasUnit and not blocked[op.root] then
            if regional then
                -- Several joins can depend on the same strip or unit frame.
                -- Keep only public levels within this read-only plan pass.
                stripLevels=stripLevels or {}
                for g in pairs(op.members) do
                    local parent=g.parent
                    if not parent._FluxBorderOwnLayer then
                        local value=stripLevels[parent]
                        if value==nil then
                            value=parent:GetFrameLevel()
                            if PublicNumber(value) then stripLevels[parent]=value else value=nil end
                        end
                        if value then level=max(level,value+1) end
                    end
                end
            end
            op.renderStrip,op.renderLevel=strip,level
            for g in pairs(op.members) do
                if g.actionStrip then
                    for _,item in ipairs(g.pieces) do
                        if item.record.key=="Top" then
                            local plan=plans[item.texture]
                            if not plan then
                                local source=Source(item.texture)
                                if not source then blocked[op.root]="unavailable strip source";break end
                                plan={root=op.root,item=item,source=source,rects={item.rect}};plans[item.texture]=plan
                            end
                            plan.renderStrip=strip;plan.renderLevel=max(plan.renderLevel or 0,level)
                        end
                    end
                end
            end
        end
    end
    PlanCost(cost,"cuts")
    local totalTriangles=0
    branchCompileNext={operations=0,triangles=0,values=0}
    self.stats.compileHits=0;self.stats.compileMisses=0
    for _,op in ipairs(meshOperations) do
        if op.bits and not blocked[op.root] then
            local best=op.branchBest or Branches(op)
            for segment in pairs(op.segments) do
                segment.source=Source(segment.texture)
                if not segment.source then blocked[op.root]="unavailable branch source" end
            end
            for _,cap in ipairs(op.roundCaps or {}) do
                cap.segment.source=Source(cap.segment.texture)
                if not cap.segment.source then blocked[op.root]="unavailable incoming aura source" end
            end
            if not blocked[op.root] then
                local reason
                op.triangles,reason=CompileBranchFields(self,op,best)
                if not op.triangles then blocked[op.root]=reason end
                totalTriangles=totalTriangles+(op.triangles and #op.triangles or 0)
                if totalTriangles>self.limits.junctionTriangles then
                    planAborted=true;self:ReleaseAll();previous=signature;self.stats.fallback="junction triangle budget";MarkCost(cost,"plan");EndCost(cost,"budget");return
                end
            end
        end
    end
    PlanCost(cost,"branches")
    -- Keep raised shared fields under their real source owner. A disappearing
    -- HIGH neighbour must not hide a still-visible window/menu stroke with it.
    PrepareFragmentOwners(operations,plans,blocked)
    PlanCost(cost,"owners")
    local fallbackByOwner={}
    for _,plan in pairs(plans) do if not blocked[plan.root] and plan.item.availabilityCuts then
        local fields,reason=FallbackCells(plan)
        if not fields then blocked[plan.root]=reason
        else
            plan.fallbackRects={}
            for _,cell in ipairs(fields) do
                for _,owner in ipairs(cell.blockers) do
                    fallbackByOwner[owner]=fallbackByOwner[owner] or {}
                    fallbackByOwner[owner][#fallbackByOwner[owner]+1]=cell
                end
                local rects
                if plan.junctions then
                    -- The remaining fragments are subsets of the original
                    -- fallback cell. Distant junctions cannot cut them.
                    for _,cut in ipairs(plan.junctions) do
                        if Intersects(cell.rect,cut) then rects=self:Subtract(rects or {cell.rect},cut) end
                    end
                end
                if rects then
                    for _,r in ipairs(rects) do plan.fallbackRects[#plan.fallbackRects+1]={rect=r,blockers=cell.blockers} end
                else
                    plan.fallbackRects[#plan.fallbackRects+1]={rect=cell.rect,blockers=cell.blockers}
                end
            end
            if #plan.rects+#plan.fallbackRects>self.limits.fragmentsPerPiece then blocked[plan.root]="visibility fragment budget" end
        end
    end end
    local unitFallbacks=self:_PrepareUnitBranchFallbacks(meshOperations,plans,blocked,fallbackByOwner)
    self:_TrimUnitBranchFallbackRects(meshOperations,plans,blocked)
    PlanCost(cost,"fallbackCells")
    local fallbackReason
    totalTriangles,fallbackReason=self:_CompileFallbackPlans(meshOperations,blocked,fallbackByOwner,totalTriangles,unitFallbacks)
    if fallbackReason then
        planAborted=true;self:ReleaseAll();previous=signature;self.stats.fallback=fallbackReason
        MarkCost(cost,"plan");EndCost(cost,"budget");return
    end
    PlanCost(cost,"fallbackMesh")
    for _,plan in pairs(plans) do if not blocked[plan.root] then total=total+#plan.rects+#(plan.fallbackRects or {}) end end
    if total>self.limits.fragments then planAborted=true;self:ReleaseAll();previous=signature;self.stats.fallback="fragment budget";MarkCost(cost,"plan");EndCost(cost,"budget");return end
    self.stats.skippedComponents=0
    for _,why in pairs(blocked) do self.stats.skippedComponents=self.stats.skippedComponents+1;self.stats.fallback=why end
    end)
    sourceReadPlan=nil
    self.stats.sourceReads=sourcePass.reads;self.stats.sourceHits=sourcePass.hits
    if not planOK then self:ReleaseAll();error(planError,0) end
    return plans,blocked,total,planAborted,regional and sourcePass.values
end

-- Private renderer contexts retain unrelated output cells. Existing native
-- renderer, source paint sinks and solver policies remain authoritative.
local Spatial={size=128,halo=40,cells={},contexts=0}
function Spatial.Copy(segments,reuse,indexRuns)
    local out,owners={},{}
    local items,lastOriginal,lastGroup
    local runs=indexRuns and {}
    for index,s in ipairs(segments) do
        local original=s.group
        local g=lastGroup
        if original~=lastOriginal then
            g=owners[original.id]
            if not g then
                if reuse and original._immutable then
                    g=original
                else
                    g={pieces={}}
                    for k,v in pairs(original) do
                        if type(k)=="string" and k~="pieces" and k~="children" then g[k]=v end
                    end
                    items=items or {}
                    g._immutable=true
                    -- Coarse bounds reject distant groups. The exact padded
                    -- pieces still decide which neighbours join.
                    local bounds
                    if not g._pieceBounds and #original.pieces>1 then
                        bounds={unpack(original.pieces[1].rect)}
                        g._pieceBounds=bounds
                    end
                    for _,item in ipairs(original.pieces) do
                        local p={};for k,v in pairs(item) do if k~="group" then p[k]=v end end
                        -- A source rectangle is a new public sample on each
                        -- geometry read. The solver writes cuts to its piece
                        -- record and crops only its own operation rectangles.
                        p.group=g;items[item]=p;g.pieces[#g.pieces+1]=p
                        if bounds then
                            local r=p.rect
                            bounds[1]=min(bounds[1],r[1]);bounds[2]=min(bounds[2],r[2])
                            bounds[3]=max(bounds[3],r[3]);bounds[4]=max(bounds[4],r[4])
                        end
                    end
                end
                owners[original.id]=g
            end
            if runs then runs[#runs+1]=index end
            lastOriginal,lastGroup=original,g
        end
        if g==original then out[index]=s
        else
            out[index]={group=g,item=items[s.item],texture=s.texture,axis=s.axis,side=s.side,
                p=s.p,a=s.a,b=s.b,scale=s.scale,paintID=s.paintID,rect=s.rect}
        end
    end
    return out,owners,runs
end
function Spatial.Eligible(segments,refreshItems)
    if #segments==0 then return false end
    -- Include registered pieces which are currently missing/private. A foreign
    -- getter must retain fresh-read behavior when its native geometry recovers.
    local battlefield,metal,tinted=PATH.."Battlefield100.tga",PATH.."ForeverMetal150.tga",PATH.."ForeverMetal150Tint.tga"
    local filter=refreshItems and {}
    for parent,g in pairs(groups) do
        local authored=not Role(parent)
        local selected=refreshItems and refreshItems[parent]
        if authored or refreshItems and not selected then
            for texture,r in pairs(g) do
                if type(r)=="table" and Border._pieces[texture]==r then
                    if authored then
                        if type(texture)=="table" and (rawget(texture,"GetRect") or rawget(texture,"GetEffectiveScale")) then return false end
                        if r.art~=battlefield and r.art~=metal and r.art~=tinted then return false end
                    end
                    if refreshItems and not selected and refreshItems[texture] then
                        selected=true
                        if not authored then break end
                    end
                end
            end
        end
        if selected then filter[parent]=true end
    end
    return true,filter
end
function Spatial.IsScoped(g)
    return g.independentScope or g.castSection or g.parent._FluxBorderCastInternalSide~=nil
end
function Spatial.MarkGroup(g,out)
    if Spatial.IsScoped(g) then
        -- The solver already separates independent outlines by plane. Give
        -- their paint the same boundary so nearby HUD changes leave it intact.
        local key="scope:"..g.plane
        out[key]=out[key] or {_scopePlane=g.plane}
        return true
    end
    for _,item in ipairs(g.pieces) do
        if not Spatial.RectCells(item.rect,out,Spatial.halo*(g.scale or 1)+1) then return false end
    end
    return true
end
function Spatial.ScopeBounds(regions,owners,oldOwners)
    local scopes
    for _,region in pairs(regions) do
        if region._scopePlane then
            scopes=scopes or {}
            scopes[region._scopePlane]=region
        end
    end
    if not scopes then return end
    for _,snapshot in ipairs({owners,oldOwners}) do
        for _,group in pairs(snapshot) do
            local region=scopes[group.plane]
            if region and Spatial.IsScoped(group) then
                -- All pieces in one snapshot group use the same halo. Its
                -- existing aggregate bounds work for both old and new poses.
                local bounds=group._pieceBounds or group.pieces[1].rect
                local pad=Spatial.halo*(group.scale or 1)+1
                local left,bottom,right,top=bounds[1]-pad,bounds[2]-pad,bounds[3]+pad,bounds[4]+pad
                region[1]=min(region[1] or left,left)
                region[2]=min(region[2] or bottom,bottom)
                region[3]=max(region[3] or right,right)
                region[4]=max(region[4] or top,top)
            end
        end
    end
end
function Spatial.RectCells(rect,out,padding)
    padding=padding or 0
    local firstX,lastX=floor((rect[1]-padding)/Spatial.size),floor((rect[3]+padding-.0000001)/Spatial.size)
    local firstY,lastY=floor((rect[2]-padding)/Spatial.size),floor((rect[4]+padding-.0000001)/Spatial.size)
    if lastX-firstX>128 or lastY-firstY>128 then return false end
    for x=firstX,lastX do for y=firstY,lastY do
        local key=x..":"..y
        out[key]=out[key] or {x*Spatial.size,y*Spatial.size,(x+1)*Spatial.size,(y+1)*Spatial.size}
    end end
    return true
end
function Spatial.Owners(segments)
    local owners={}
    for _,s in ipairs(segments) do owners[s.group.id]=s.group end
    return owners
end
function Spatial.Changed(old,new,dirtyCells)
    local rosterChanged=false
    local function Mark(g)
        if not g then return true end
        local unit=g.unitOwner
        if not rosterChanged and unit then
            rosterChanged=unit:match("^raid%d")~=nil or unit:match("^party%d")~=nil
        end
        return Spatial.MarkGroup(g,dirtyCells)
    end
    local function Same(a,b)
        if rawequal(a,b) then return true end
        if not a or not b or a.parent~=b.parent or a.plane~=b.plane or a.priority~=b.priority
            or a.x~=b.x or a.y~=b.y or a.scale~=b.scale
            or a.unitOwner~=b.unitOwner or a.actionStrip~=b.actionStrip or a.fixedBounds~=b.fixedBounds or a.castSection~=b.castSection
            or a.independentScope~=b.independentScope
            or #a.pieces~=#b.pieces then return false end
        local byTexture={};for _,p in ipairs(a.pieces) do byTexture[p.texture]=p end
        for _,p in ipairs(b.pieces) do
            local q=byTexture[p.texture]
            if not q or q.cornerX~=p.cornerX or q.cornerY~=p.cornerY or q.position~=p.position
                or q.drawLayer~=p.drawLayer or q.sublevel~=p.sublevel then return false end
            for i=1,4 do if p.rect[i]~=q.rect[i] then return false end end
        end
        return true
    end
    for id,g in pairs(old) do if not Same(g,new[id]) then if not Mark(g) or not Mark(new[id]) then return false end end end
    for id,g in pairs(new) do if not old[id] and not Mark(g) then return false end end
    return true,rosterChanged
end
function Spatial.Intersection(a,b)
    local left,bottom,right,top=max(a[1],b[1]),max(a[2],b[2]),min(a[3],b[3]),min(a[4],b[4])
    if right>left and top>bottom then return {left,bottom,right,top} end
end
do
local function TilePoint(p,left,top,width,height)
    return {(p[1]-left)/width,(top-p[2])/height,p[3],p[4]}
end
local function AppendTileField(out,source,a,b,c,quad)
    out[#out+1]={arm=source.arm,a=a,b=b,c=c,quad=quad,texture=source.texture,
        source=source.source,fallbackBlockers=source.fallbackBlockers}
end
function Spatial.ClipTriangle(t,op,cell,out)
    if t.quadTail then return end
    local r=op.rect;local w,h=r[3]-r[1],r[4]-r[2]
    local q=t.quad
    local a,b,c,d=t.a,t.b,t.c
    -- Perimeter order differs from WoW's UL,LL,UR,LR vertex order.
    if q then a,b,c,d=q[1],q[2],q[4],q[3] end
    local left,bottom,right,top=cell[1],cell[2],cell[3],cell[4]
    local ax,bx,cx=r[1]+a[1]*w,r[1]+b[1]*w,r[1]+c[1]*w
    local dx=d and r[1]+d[1]*w or cx
    local minX,maxX=min(ax,bx,cx,dx),max(ax,bx,cx,dx)
    if maxX<left or minX>right then return end
    local ay,by,cy=r[4]-a[2]*h,r[4]-b[2]*h,r[4]-c[2]*h
    local dy=d and r[4]-d[2]*h or cy
    local minY,maxY=min(ay,by,cy,dy),max(ay,by,cy,dy)
    if maxY<bottom or minY>top then return end
    local clipLeft,clipRight=minX<left,maxX>right
    local clipBottom,clipTop=minY<bottom,maxY>top
    local cw,ch=right-left,top-bottom
    -- A field fully inside this tile can write its final vertices directly,
    -- even if other fields in the same junction cross a tile boundary.
    if not (clipLeft or clipRight or clipBottom or clipTop) then
        if not q then
            if abs((bx-ax)*(cy-ay)-(by-ay)*(cx-ax))>1e-12 then
                AppendTileField(out,t,{(ax-left)/cw,(top-ay)/ch,a[3],a[4]},
                    {(bx-left)/cw,(top-by)/ch,b[3],b[4]},{(cx-left)/cw,(top-cy)/ch,c[3],c[4]})
            end
            return
        end
        if ax==bx and by==cy and cx==dx and dy==ay then
            local ul={(ax-left)/cw,(top-ay)/ch,a[3],a[4]}
            local ll={(bx-left)/cw,(top-by)/ch,b[3],b[4]}
            local ur={(dx-left)/cw,(top-dy)/ch,d[3],d[4]}
            local lr={(cx-left)/cw,(top-cy)/ch,c[3],c[4]}
            AppendTileField(out,t,ul,ll,ur,{ul,ll,ur,lr})
            return
        end
    end
    local poly={{ax,ay,a[3],a[4]},{bx,by,b[3],b[4]},{cx,cy,c[3],c[4]}}
    if d then poly[4]={dx,dy,d[3],d[4]} end
    -- A junction can span two tiles even when most of its individual fields stay
    -- inside one. Clip only the crossed planes, in the original order.
    -- Once a plane clips the polygon, use the existing sequence on its new
    -- vertices so interpolated boundary coordinates keep their original result.
    clipRight=clipLeft or clipRight
    clipBottom=clipRight or clipBottom
    if clipLeft then poly=ClipField(poly,1,cell[1],true) end
    if clipRight then poly=ClipField(poly,1,cell[3],false) end
    if clipBottom then poly=ClipField(poly,2,cell[2],true) end
    if clipBottom or clipTop then poly=ClipField(poly,2,cell[4],false) end
    if #poly<3 then return end
    if q and #poly==4 and poly[1][1]==poly[2][1] and poly[2][2]==poly[3][2]
        and poly[3][1]==poly[4][1] and poly[4][2]==poly[1][2] then
        local ul=TilePoint(poly[1],left,top,cw,ch)
        local ll=TilePoint(poly[2],left,top,cw,ch)
        local ur=TilePoint(poly[4],left,top,cw,ch)
        local lr=TilePoint(poly[3],left,top,cw,ch)
        AppendTileField(out,t,ul,ll,ur,{ul,ll,ur,lr})
    else
        for i=2,#poly-1 do
            local a,b,c=poly[1],poly[i],poly[i+1]
            if abs((b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1]))>1e-12 then
                AppendTileField(out,t,TilePoint(a,left,top,cw,ch),TilePoint(b,left,top,cw,ch),TilePoint(c,left,top,cw,ch))
            end
        end
    end
end
end
function Spatial.TileSource(sources,texture)
    local source=sources[texture]
    if source==nil then
        source=Source(texture)
        sources[texture]=source
    end
    return source
end
-- Clipping is finished before a tile is painted. Keep the inputs used by the
-- renderer, visible junction diagnostics and committed compiler caches.
function Spatial.CopyDrawOperation(op,copy)
    copy=copy or {}
    copy.rect,copy.fullRect,copy.x,copy.y,copy.bits=op.rect,op.fullRect,op.x,op.y,op.bits
    copy.hs,copy.vs,copy.members,copy.root=op.hs,op.vs,op.members,op.root
    copy.segments,copy.protectedCaps,copy.protectedRects=op.segments,op.protectedCaps,op.protectedRects
    copy.roundCaps,copy.auraTopCrest,copy.shadowOnly=op.roundCaps,op.auraTopCrest,op.shadowOnly
    copy.renderStrip,copy.renderLevel=op.renderStrip,op.renderLevel
    copy.triangles,copy.fallbackTriangles=op.triangles,op.fallbackTriangles
    copy._branchCompileCandidate,copy._branchCompileCommitted=op._branchCompileCandidate,op._branchCompileCommitted
    copy._fallbackPlanCandidate,copy._fallbackPlanCommitted=op._fallbackPlanCandidate,op._fallbackPlanCommitted
    copy._fallbackGeometryTokens,copy._preparedDrawInputs=op._fallbackGeometryTokens,op._preparedDrawInputs
    return copy
end
function Spatial.PrepareCell(batch,segments,plans,sources,items)
    local rect=batch.rect
    local result={rect=rect,plans={},operations={},count=0,solved=segments}
    local represented={}
    for _,item in ipairs(batch.pieces) do
        -- Untouched rounded caps keep their original native artwork. A cap
        -- is small enough to prepare in full when an actual join first clips it.
        if not capSides[item.record.key] or plans[item.texture] then
            local source=Spatial.TileSource(sources,item.texture)
            if not source then return end
            represented[item.texture]=true
            local original=plans[item.texture]
            local p={item=item,source=source,rects={},fallbackRects={},root=original and original.root}
            if original then for k,v in pairs(original) do if k~="rects" and k~="fallbackRects" then p[k]=v end end end
            for _,r in ipairs(original and original.rects or {item.rect}) do
                local clippedRect=Spatial.Intersection(r,rect);if clippedRect then p.rects[#p.rects+1]=clippedRect end
            end
            for _,f in ipairs(original and original.fallbackRects or {}) do
                local clippedRect=Spatial.Intersection(f.rect,rect)
                if clippedRect then p.fallbackRects[#p.fallbackRects+1]={rect=clippedRect,blockers=f.blockers} end
            end
            result.plans[#result.plans+1]=p;result.count=result.count+#p.rects+#p.fallbackRects
            if #p.fallbackRects>0 then
                local indexes=result.fallbacks or {}
                indexes[#indexes+1]=#result.plans
                result.fallbacks=indexes
            end
        end
    end
    for _,op in ipairs(batch.operations) do
        local copy=Spatial.CopyDrawOperation(op)
        copy._logicalOp=op
        if op.rect[1]>=rect[1] and op.rect[2]>=rect[2] and op.rect[3]<=rect[3] and op.rect[4]<=rect[4] then
            copy.rect=op.rect;copy.triangles=op.triangles;copy.fallbackTriangles=op.fallbackTriangles or {}
        else
            copy.rect=rect
            copy.triangles={};copy.fallbackTriangles={}
            for _,t in ipairs(op.triangles) do Spatial.ClipTriangle(t,op,rect,copy.triangles) end
            for _,t in ipairs(op.fallbackTriangles or {}) do Spatial.ClipTriangle(t,op,rect,copy.fallbackTriangles) end
        end
        result.count=result.count+#copy.triangles+#copy.fallbackTriangles
        if #copy.triangles+#copy.fallbackTriangles>0 then result.operations[#result.operations+1]=copy end
    end
    -- A branch may extend beyond the source rectangle into this cell. It
    -- still needs authoritative native RGB/alpha, even with no normal fragment.
    for _,op in ipairs(result.operations) do
        for _,list in ipairs({op.triangles,op.fallbackTriangles}) do for _,t in ipairs(list) do
            if not represented[t.texture] then
                local source=Spatial.TileSource(sources,t.texture)
                if not source then return end
                represented[t.texture]=true
                local item=items[t.texture];local original=plans[t.texture]
                result.plans[#result.plans+1]={item=item,source=source,rects={},fallbackRects={},root=original and original.root or op.root}
            end
        end end
    end
    return result
end
function Spatial.IndexRegions(regions)
    local batches,tiles,scopes={}, {}, {}
    local bounds
    local tileCount=0
    for key,rect in pairs(regions) do
        local batch={rect=rect,pieces={},operations={}}
        batches[key]=batch
        if rect._scopePlane then scopes[rect._scopePlane]=batch
        else
            local x,y=floor(rect[1]/Spatial.size),floor(rect[2]/Spatial.size)
            local column=tiles[x]
            if not column then column={};tiles[x]=column end
            column[y]=batch;tileCount=tileCount+1
            if not bounds then bounds={unpack(rect)}
            else
                bounds[1]=min(bounds[1],rect[1]);bounds[2]=min(bounds[2],rect[2])
                bounds[3]=max(bounds[3],rect[3]);bounds[4]=max(bounds[4],rect[4])
            end
        end
    end
    return {batches=batches,tiles=tiles,scopes=scopes,tileCount=tileCount,rect=bounds}
end
function Spatial.VisitTiles(index,rect,visit,kind,object,padding)
    if index.tileCount==0 then return end
    local tiles=index.tiles
    local x0,x1,y0,y1
    if padding then
        local size=Spatial.size
        x0,x1=floor((rect[1]-padding)/size),floor((rect[3]+padding)/size)
        y0,y1=floor((rect[2]-padding)/size),floor((rect[4]+padding)/size)
        -- Keep the exact strict halo test at tile boundaries, even when
        -- adding padding on either side rounds to a different coordinate.
        if rect[1]<x0*size+padding then x0=x0-1 end
        if rect[2]<y0*size+padding then y0=y0-1 end
        if rect[3]>(x1+1)*size-padding then x1=x1+1 end
        if rect[4]>(y1+1)*size-padding then y1=y1+1 end
    else
        x0,x1=floor(rect[1]/Spatial.size),floor(rect[3]/Spatial.size)
        y0,y1=floor(rect[2]/Spatial.size),floor(rect[4]/Spatial.size)
    end
    if (x1-x0+1)*(y1-y0+1)>index.tileCount then
        for x,column in pairs(tiles) do if x>=x0 and x<=x1 then
            for y,batch in pairs(column) do
                if y>=y0 and y<=y1 and visit(batch,rect,kind,object) then return true end
            end
        end end
    else
        for x=x0,x1 do
            local column=tiles[x]
            if column then for y=y0,y1 do
                local batch=column[y]
                if batch and visit(batch,rect,kind,object) then return true end
            end end
        end
    end
end
function Spatial.TouchesHalo(batch,rect,padding)
    local tile=batch.rect
    return rect[1]<tile[3]+padding and rect[3]>tile[1]-padding
        and rect[2]<tile[4]+padding and rect[4]>tile[2]-padding
end
function Spatial.Query(raw,regions,owners,index,readOnly,runs)
    owners=owners or Spatial.Owners(raw)
    index=index or Spatial.IndexRegions(regions)
    local selected={}
    for _,g in pairs(owners) do
        if Spatial.IsScoped(g) then selected[g]=index.scopes[g.plane]~=nil
        elseif index.rect then
            local padding=Spatial.halo*(g.scale or 1)+1
            if not g._pieceBounds or Spatial.TouchesHalo(index,g._pieceBounds,padding) then
                for _,item in ipairs(g.pieces) do
                    if Spatial.VisitTiles(index,item.rect,Spatial.TouchesHalo,padding,nil,padding) then
                        selected[g]=true
                        break
                    end
                end
            end
        end
    end
    local out={}
    if runs then
        -- Keep source order even when a group has more than one run. Skip
        -- the complete span of each distant group in the solved layout.
        local count=0
        for i,first in ipairs(runs) do
            if selected[raw[first].group] then
                for j=first,(runs[i+1] or #raw+1)-1 do
                    count=count+1
                    out[count]=raw[j]
                end
            end
        end
    else
        for _,s in ipairs(raw) do if selected[s.group] then out[#out+1]=s end end
    end
    if readOnly then return out end
    return Spatial.Copy(out)
end
function Spatial.TouchesRegion(batch,rect)
    return Intersects(rect,batch.rect)
end
function Spatial.Affects(op,index)
    local g=op.hs and op.hs.group or next(op.members)
    if Spatial.IsScoped(g) then return index.scopes[g.plane]~=nil end
    return Spatial.VisitTiles(index,op.rect,Spatial.TouchesRegion)
end
function Spatial.AddToRegion(batch,rect,kind,object)
    local a=batch.rect
    if min(a[3],rect[3])<=max(a[1],rect[1]) or min(a[4],rect[4])<=max(a[2],rect[2]) then return end
    local list=batch[kind];list[#list+1]=object
end
function Spatial.RouteRegions(regions,owners,operations,index)
    index=index or Spatial.IndexRegions(regions)
    local function Route(group,kind,object)
        if Spatial.IsScoped(group) then
            local batch=index.scopes[group.plane]
            if batch then Spatial.AddToRegion(batch,object.rect,kind,object) end
        else
            Spatial.VisitTiles(index,object.rect,Spatial.AddToRegion,kind,object)
        end
    end
    local items={}
    for _,group in pairs(owners) do
        for _,item in ipairs(group.pieces) do items[item.texture]=item;Route(group,"pieces",item) end
    end
    for _,op in ipairs(operations) do if op.bits then Route(op.hs.group,"operations",op) end end
    return index.batches,items
end
function Spatial.Hide(cell,sources)
    for texture,entry in pairs(cell.clipped) do
        local base=sources[texture]
        for _,field in ipairs(entry.pool) do
            if field._localPoolIndex then J._RemoveRegionalFragment(base and base.pool,field) end
            FieldHide(field)
        end
    end
    for _,pool in pairs(cell.sprites) do for _,field in ipairs(pool) do FieldHide(field);field._junctionOwnerOp=nil;field._junctionOp=nil end end
    cell.active,cell.solved,cell.visibilityNext=nil,nil,nil
end
function Spatial.Pop(list,field,indexName)
    local index=field[indexName]
    if index and list and list[index]==field then
        local last=list[#list];list[#list]=nil
        if last~=field then list[index]=last;last[indexName]=index end
    end
    field[indexName]=nil
end
function Spatial.Push(list,field,indexName)
    list[#list+1]=field;field[indexName]=#list
end
function J._RemoveRegionalFragment(pool,field)
    Spatial.Pop(pool,field,"_localPoolIndex")
end
function Spatial.DetachListener(index,key,cell,emptyIndices)
    local cells=index[key]
    if not cells then return end
    cells[cell]=nil
    if next(cells) then return end
    if emptyIndices then
        local keys=emptyIndices[index]
        if not keys then keys={};emptyIndices[index]=keys end
        keys[key]=true
    else
        index[key]=nil
    end
    return true
end
function Spatial.Detach(cell,dest,touched,emptyIndices)
    if not cell.enabled then return end
    for texture,entry in pairs(cell.clipped) do if entry.epoch==cell.epoch and entry.active then
        local base=dest.clipped[texture]
        if base then base._localClaims=max(0,(base._localClaims or 0)-1) end
        if touched then touched[texture]=true end
    end end
    for source in pairs(cell.colors or {}) do
        Spatial.DetachListener(dest.colors,source,cell,emptyIndices)
    end
    for owner in pairs(cell.sprites) do
        Spatial.DetachListener(dest.sprites,owner,cell,emptyIndices)
    end
    for object in pairs(cell.visibility or {}) do
        if Spatial.DetachListener(dest.visibility,object,cell,emptyIndices) then
            dest.availability[object]=nil
        end
    end
end
function Spatial.PruneListenerIndices(emptyIndices)
    for index,keys in pairs(emptyIndices) do
        for key in pairs(keys) do
            local cells=index[key]
            if cells and not next(cells) then index[key]=nil end
        end
    end
end
function Spatial.Attach(cell,dest,touched)
    local fragments,triangles=0,0
    -- A redraw usually writes to the same native fragment slots. Reconcile
    -- source membership only for fragments added, replaced or retired.
    for texture,entry in pairs(cell.clipped) do
        local base=dest.clipped[texture]
        local current=entry.epoch==cell.epoch and entry.active
        if current then
            base._localClaims=(base._localClaims or 0)+1;base.root=entry.root
            touched[texture]=true
        end
        for _,field in ipairs(entry.pool) do
            local index=field._localPoolIndex
            if current and field._renderEpoch==cell.epoch then
                if not index then Spatial.Push(base.pool,field,"_localPoolIndex") end
                fragments=fragments+1
            elseif index then
                -- The source pool owns the fragments displayed before this
                -- redraw. Free fields already left that pool and were hidden.
                J._RemoveRegionalFragment(base and base.pool,field)
                HideRetiredField(field)
            end
        end
    end
    -- Paint visits the existing source list in each tile. Reflow replaces
    -- that list in one step, regardless of how many fields share the source.
    for source,list in pairs(cell.colors) do
        local cells=dest.colors[source]
        if not cells then cells={};dest.colors[source]=cells end
        cells[cell]=list
    end
    for owner,pool in pairs(cell.sprites) do
        -- The tile clears retired fields before attaching the pool. Recolor
        -- can use the same pool as the renderer and skip its free fields.
        local cells=dest.sprites[owner]
        if not cells then cells={};dest.sprites[owner]=cells end
        cells[cell]=pool
    end
    -- A fallback observer can cover many fields in the same tile. Publish the
    -- tile's listener list once and keep other tiles' lists attached.
    for object,list in pairs(cell.visibility) do
        local cells=dest.visibility[object]
        if not cells then cells={};dest.visibility[object]=cells end
        cells[cell]=list
        dest.availability[object]=cell.availability[object]
    end
    for _,op in ipairs(cell.active) do triangles=triangles+#op.triangles+#op.fallbackTriangles end
    cell.fragmentCount,cell.triangleCount=fragments,triangles
end
function Spatial.Reset()
    local dest={clipped=clipped,sprites=sprites,colors=colorListeners,visibility=visibilityListeners,availability=availabilityCache}
    for _,cell in pairs(Spatial.cells) do
        Spatial.Detach(cell,dest);Spatial.Hide(cell,dest.clipped);cell.enabled=false;cell.drawCache=nil;cell.drawUsage=nil
    end
    Spatial.raw,Spatial.rawOwners=nil,nil
    Spatial.ops=nil;Spatial.stripPoses=nil;Spatial.rosterPose=nil;J.stats.localMode=false
    Spatial.budget=nil
    Spatial.fragmentCount,Spatial.triangleCount,Spatial.cellCount=0,0,0
end
function J:_ForgetLocality(texture)
    if not Spatial.raw then return false end
    local entry=clipped[texture]
    painting=true
    if entry and entry.active then
        entry.active=false;FieldAlpha(texture,entry.alpha)
        for _,field in ipairs(entry.pool) do FieldHide(field) end
    end
    for _,list in J._ColorLists(texture) do
        for _,field in ipairs(list) do FieldHide(field) end
    end
    painting=false
    return true
end
function Spatial.Acquire(key,prepared)
    local cell=Spatial.cells[key]
    if not cell then
        for old,candidate in pairs(Spatial.cells) do
            if not candidate.enabled and not prepared[old] then cell=candidate;Spatial.cells[old]=nil;break end
        end
        if not cell then
            Spatial.contexts=Spatial.contexts+1
            assert(Spatial.contexts<=1024,"border cell context budget")
            cell={clipped={},sprites={}}
        end
        Spatial.cells[key]=cell
    end
    return cell
end
function Spatial.Tick(cost,name,started)
    if not cost then return end
    local now=CostClock()
    if not started or not now or now<started then cost.invalid=true;return end
    cost.commitPhases[name]=(cost.commitPhases[name] or 0)+now-started
    return now
end
-- Contexts own only decoration. The authoritative source paint entries remain
-- shared, so private RGB/alpha continue through the existing native sinks.
-- Shared canvases also serve retained cells. Reconcile their small public
-- level requirements from the logical operations, without walking native fields.
function Spatial.Levels(operations,levelSamples)
    local native,required,strips={},{},{}
    local function Info(parent)
        local value=native[parent]
        if not value then
            local strata=parent:GetFrameStrata()
            local level=levelSamples and levelSamples[parent] or parent:GetFrameLevel()
            if issecretvalue and issecretvalue(strata) or not PublicNumber(level) then return end
            value={strata=strata,level=level,rank=STRATA[strata] or (strata=="HIGH" and 3) or 4};native[parent]=value
        end
        return value
    end
    for _,op in ipairs(operations) do
        local top,topLevel
        for g in pairs(op.members) do
            local parent=g.parent
            if not parent._FluxBorderOwnLayer then
                local info=Info(parent)
                if not info then return end
                if not top or info.rank>top.rank then
                    top,topLevel=info,info.level
                elseif info.rank==top.rank then
                    topLevel=max(topLevel,info.level)
                end
            end
        end
        if top then
            -- Keep one result per canvas. The immutable native sample and
            -- the operation's highest level never need their own copy.
            for g in pairs(op.members) do
                local parent=g.parent
                if not parent._FluxBorderOwnLayer then
                    local entry=required[parent]
                    if not entry then
                        required[parent]={strata=top.strata,rank=top.rank,level=topLevel}
                    elseif top.rank>entry.rank then
                        entry.strata,entry.rank,entry.level=top.strata,top.rank,topLevel
                    elseif top.rank==entry.rank then
                        entry.level=max(entry.level,topLevel)
                    end
                end
            end
        end
        if op.renderStrip then
            local info=Info(op.renderStrip);if not info then return end
            local level=op.renderLevel or info.level+20
            local strip=strips[op.renderStrip]
            if not strip then strips[op.renderStrip]={strata=info.strata,level=level}
            else strip.level=max(strip.level,level) end
        end
    end
    return {junctions=required,strips=strips,native=native}
end
function Spatial.ApplyLevels(levels)
    J._RetireArrowCanvasLevels(levels)
    for parent,info in pairs(levels.junctions) do
        local canvas=junctionCanvases[parent]
        if canvas and not renderLayers.applied[canvas] then ApplyRegionalLayer(canvas,info,false) end
    end
    for strip,info in pairs(levels.strips) do
        local canvas=stripCanvases[strip]
        if canvas and not renderLayers.applied[canvas] then ApplyRegionalLayer(canvas,info,true) end
    end
end
function Spatial.Budget(prepared,total,cold)
    local current=not cold and Spatial.budget
    -- Keep the planned field count. Native drawing may combine triangles
    -- or suppress fragments, so the rendered counts serve different limits.
    local budget={count=total,operations=0,fields=0,values=0}
    if current then
        budget.count=budget.count+current.count
        budget.operations,budget.fields,budget.values=current.operations,current.fields,current.values
    end
    local needed=0
    local free=Spatial.contexts-(cold and 0 or Spatial.cellCount)
    for key,replacement in pairs(prepared) do
        local cell=Spatial.cells[key]
        if not cell then
            if #replacement.plans>0 or #replacement.operations>0 then needed=needed+1 end
        elseif cold or not cell.enabled then
            -- This key already reserves its context for the transaction.
            free=free-1
        else
            local usage=cell.drawUsage
            budget.count=budget.count-cell.count
            budget.operations=budget.operations-usage.operations
            budget.fields=budget.fields-usage.fields
            budget.values=budget.values-usage.values
        end
    end
    if budget.count>J.limits.fragments+J.limits.junctionTriangles
        or Spatial.contexts+max(0,needed-free)>1024 then return end
    return budget
end
function Spatial.Commit(prepared,raw,rawOwners,ops,signature,cold,cost,levels,liveSources,preparedOperations,shareBounds,drawBudget)
    local touched={}
    local saved={clipped=clipped,sprites=sprites,colors=colorListeners,visibility=visibilityListeners,availability=availabilityCache}
    if cold then
        J:ReleaseAll()
        for _,entry in pairs(saved.clipped) do entry.pool={};entry._localClaims=0 end
        saved.sprites,saved.colors,saved.visibility,saved.availability={},{},{},{}
    end
    renderEpoch=renderEpoch+1;renderBases={fragmentSources={},suppressedSources={}};painting=true
    -- The same public inputs will reconcile retained canvases after this
    -- synchronous paint. Never retain them for a later layout transaction.
    renderLayers={native=levels.native,members={},junctions=levels.junctions,strips=levels.strips,applied={},draw={},shareBounds=shareBounds,
        bindSharedBounds=shareBounds and preparedOperations~=nil}
    if cost then cost.commitPhases={} end
    -- A dirty tile can remove the last listener for a source and then add
    -- its replacement in this commit. Keep the empty index only until paint
    -- finishes, with no old listener or availability sample attached.
    local emptyIndices={}
    local ok,err=pcall(function()
        local indexedSegments
        -- Parents and draw layers stay fixed during a commit. Each tile still
        -- owns its own opacity and visibility registrations.
        local ancestry,staticOwners,ancestorVisibility={},{},{}
        for key in pairs(prepared) do
            local cell=Spatial.cells[key]
            if cell and cell.enabled then
                Spatial.Detach(cell,saved,touched,emptyIndices)
                Spatial.fragmentCount=(Spatial.fragmentCount or 0)-(cell.fragmentCount or 0)
                Spatial.triangleCount=(Spatial.triangleCount or 0)-(cell.triangleCount or 0)
                Spatial.cellCount=(Spatial.cellCount or 0)-1
                cell.enabled=false
            end
        end
        for key,p in pairs(prepared) do if #p.plans==0 and #p.operations==0 then
            local cell=Spatial.cells[key];if cell then Spatial.Hide(cell,saved.clipped);cell.enabled=false;cell.drawCache=nil;cell.drawUsage=nil end
        end end
        for key,nextCell in pairs(prepared) do if #nextCell.plans>0 or #nextCell.operations>0 then
            local cell=Spatial.Acquire(key,prepared);cell.enabled=true
            local clock=cost and CostClock()
            clipped=cell.clipped;sprites=cell.sprites;colorListeners={};visibilityListeners={};availabilityCache={}
            -- Old watchers for this tile were detached above. Retained tiles
            -- keep their own links until a later commit replaces them.
            local links=cell.visibilityNext
            if links then for field in pairs(links) do links[field]=nil end end
            fallbackChains={ancestry=ancestry,owners=staticOwners,ancestorVisibility=ancestorVisibility,listenerNext=links}
            fallbackAvailability={}
            for _,pool in pairs(sprites) do pool.freeIndex=1 end
            for _,p in ipairs(nextCell.plans) do
                local texture=p.item.texture;touched[texture]=true;local base=saved.clipped[texture]
                local source=liveSources and liveSources[texture] or p.source
                if not base then base={pool={}};saved.clipped[texture]=base end
                base.active=true
                base.alpha,base.color,base.path,base.uv,base.support=source.alpha,source.color,source.path,source.uv,source.support
                local e=clipped[texture] or {pool={}};clipped[texture]=e
                -- RenderFragments sets the material and normal paint. Carry
                -- only the native paint ownership flags into this cell here.
                e.nativeRGB,e.nativePaint,e.rgbPublic,e.sourceShown=base.nativeRGB,base.nativePaint,base.rgbPublic,base.sourceShown
                RenderFragments(p.item,p.rects,source,p.root,p.renderStrip,p.renderLevel,p.roundCap,p.renderMembers,p.fragmentUVs,base.pool)
                base.sourceShown=e.sourceShown
            end
            clock=Spatial.Tick(cost,"fragments",clock)
            if nextCell.fallbacks then
                for _,index in ipairs(nextCell.fallbacks) do RenderFallbackRectangles(nextCell.plans[index]) end
            end
            clock=Spatial.Tick(cost,"fallbacks",clock)
            local operations=nextCell.operations
            if preparedOperations then
                -- The old tile has released its listeners. Rebind its draw
                -- records to the saved geometry and this commit's owners.
                operations=cell.active or {}
                for index,recipe in ipairs(nextCell.operations) do
                    local op=Spatial.CopyDrawOperation(recipe,operations[index])
                    op._logicalOp=preparedOperations[recipe._logicalIndex]
                    op.sprite,op.sprites=nil,nil
                    op._drawReused,op._drawCandidate,op._drawPrepared=nil,nil,nil
                    operations[index]=op
                end
                for index=#operations,#nextCell.operations+1,-1 do operations[index]=nil end
            end
            local drawCache,epoch=cell.drawCache or {},cell.epoch or 0
            for _,op in ipairs(operations) do PrepareDrawReuse(op,drawCache,epoch) end
            for _,op in ipairs(operations) do
                Draw(op)
                local logical=op._logicalOp
                if not logical.sprite or logical.x>=nextCell.rect[1] and logical.x<nextCell.rect[3]
                    and logical.y>=nextCell.rect[2] and logical.y<nextCell.rect[4] then logical.sprite=op.sprite end
            end
            cell.drawCache,cell.drawUsage=PublishDrawCache(operations,drawBudget)
            clock=Spatial.Tick(cost,"mesh",clock)
            for _,pool in pairs(sprites) do
                for _,field in ipairs(pool) do
                    if field._junctionOwnerOp and field._renderEpoch~=renderEpoch then
                        HideRetiredField(field)
                        field._junctionOwnerOp=nil;field._junctionOp=nil
                    end
                end
            end
            cell.colors,cell.visibility,cell.availability=colorListeners,visibilityListeners,availabilityCache
            cell.visibilityNext=fallbackChains.listenerNext
            cell.active=operations;cell.solved=nextCell.solved;cell.count=nextCell.count;cell.epoch=renderEpoch
            if nextCell.solved~=indexedSegments then
                indexedSegments=nextCell.solved
                for _,segment in ipairs(indexedSegments) do committedSegments[segment.texture]=segment end
            end
            Spatial.Attach(cell,saved,touched)
            Spatial.fragmentCount=(Spatial.fragmentCount or 0)+cell.fragmentCount
            Spatial.triangleCount=(Spatial.triangleCount or 0)+cell.triangleCount
            Spatial.cellCount=(Spatial.cellCount or 0)+1
            Spatial.Tick(cost,"retire",clock)
        end end
    end)
    clipped,sprites,colorListeners,visibilityListeners,availabilityCache=saved.clipped,saved.sprites,saved.colors,saved.visibility,saved.availability
    fallbackChains=nil;fallbackAvailability=nil
    Spatial.PruneListenerIndices(emptyIndices)
    if not ok then renderLayers=nil;renderBases=nil;painting=false;Spatial.Reset();J:ReleaseAll();error(err,0) end
    local publishClock=cost and CostClock()
    local publishOK,publishError=pcall(function()
    Spatial.ApplyLevels(levels)
    -- Publication touches only changed cells. Unrelated listener lists,
    -- source pools and native fields retain their exact identities.
    for texture in pairs(touched) do
        local entry=clipped[texture]
        if (entry._localClaims or 0)>0 then
            entry.active=true
            if not (renderBases and renderBases.suppressedSources[texture]) then FieldAlpha(texture,0) end
        elseif entry.active then entry.active=false;FieldAlpha(texture,entry.alpha) end
    end
    painting=false;active=ops;Spatial.raw=raw;Spatial.rawOwners=rawOwners;Spatial.ops=ops;previous=signature
    Spatial.budget=drawBudget
    if J._PublishBranchCompileCache then J:_PublishBranchCompileCache() end
    if J._PublishFallbackCompileCache then J:_PublishFallbackCompileCache() end
    if J._PublishFallbackPlanCache then J:_PublishFallbackPlanCache() end
    J.stats.operations=#ops;J.stats.fragments=Spatial.fragmentCount;J.stats.triangles=Spatial.triangleCount
    J.stats.localMode=true;J.stats.localCells=Spatial.cellCount;J.stats.localBuilds=(J.stats.localBuilds or 0)+1
    Spatial.Tick(cost,"retire",publishClock)
    end)
    renderLayers=nil
    renderBases=nil
    if not publishOK then painting=false;Spatial.Reset();J:ReleaseAll();error(publishError,0) end
end
-- Hover, actual slot changes, and roster moves can revisit prepared layouts.
-- Retain solved public topology and plan paint from live inputs.
-- Keep the exact selected neighborhood so a different panel, scale, source
-- or art geometry takes the normal regional solve.
do
    local groupKeys={"parent","id","plane","priority","paintID","x","y","scale",
        "unitOwner","fixedBounds","actionStrip","stripRoot","castSection","independentScope"}
    local pieceKeys={"record","position","cornerX","cornerY","drawLayer","sublevel"}
    local segmentKeys={"axis","side","p","a","b","scale","paintID"}
    local topologyFlags={"_FluxBorderAuraPanel","_FluxBorderRoundCorners","_FluxBorderCastInternalSide"}
    local limitKeys={"segments","candidates","bucketEntries","operations","fragmentsPerPiece","fragments","junctionTriangles"}

    local function SameFields(a,b,keys)
        for _,key in ipairs(keys) do if a[key]~=b[key] then return false end end
        return true
    end
    local function SameRect(a,b)
        if not a or not b then return not a and not b end
        return a[1]==b[1] and a[2]==b[2] and a[3]==b[3] and a[4]==b[4]
    end
    function Spatial.MatchLayoutPose(pose,segments)
        if not pose or #pose.segments~=#segments or not SameFields(pose.limits,J.limits,limitKeys) then return false end
        local compared={}
        for _,segment in ipairs(segments) do
            local old=pose.byTexture[segment.texture]
            if not old then return false end
            local group,prior=segment.group,old.group
            -- Raw and solved copies share the stamp table of the same public
            -- geometry sample. A newly sampled group always gets a new table.
            local sameSample=group._layoutStamps and rawequal(group._layoutStamps,prior._layoutStamps)
            if not sameSample and (not SameFields(old,segment,segmentKeys) or not SameRect(old.rect,segment.rect)) then return false end
            if not compared[group] then
                if not sameSample and (not SameFields(group,prior,groupKeys) or #group.pieces~=#prior.pieces) then return false end
                -- These values live on the frame or registration, so they
                -- still need checking when the copied geometry is identical.
                if not SameFields(group.parent,pose.flags[prior],topologyFlags) then return false end
                local known=pose.pieces[prior]
                for _,item in ipairs(group.pieces) do
                    local saved=known[item.texture]
                    if not saved or saved.key~=item.record.key then return false end
                    if not sameSample and (not SameFields(item,saved.item,pieceKeys)
                        or not SameRect(item.rect,saved.item.rect) or not SameRect(item.paintRect,saved.item.paintRect)) then return false end
                end
                compared[group]=prior
            elseif compared[group]~=prior then return false end
        end
        return true
    end

    function Spatial.CopyPoseOperations(operations)
        local copy={}
        for index,op in ipairs(operations) do
            local nextOp={}
            for key,value in pairs(op) do nextOp[key]=value end
            copy[index]=nextOp
        end
        return copy
    end

    function Spatial.SaveLayoutPose(segments,operations,roster)
        -- Independent roster neighborhoods qualify at smaller sizes.
        if #segments>(roster and 256 or 1024) or #operations>(roster and 128 or 384) then return end
        local pose={segments=segments,operations=Spatial.CopyPoseOperations(operations),byTexture={},pieces={},flags={},limits={}}
        for _,key in ipairs(limitKeys) do pose.limits[key]=J.limits[key] end
        for _,segment in ipairs(segments) do
            pose.byTexture[segment.texture]=segment
            local group=segment.group
            if not pose.pieces[group] then
                local known,flags={},{}
                for _,item in ipairs(group.pieces) do known[item.texture]={item=item,key=item.record.key} end
                for _,key in ipairs(topologyFlags) do flags[key]=group.parent[key] end
                pose.pieces[group],pose.flags[group]=known,flags
            end
        end
        return pose
    end

    local function KeepLayoutPose(pose,parents)
        if not pose or parents[false] then return end
        for group in pairs(pose.pieces) do
            if parents[group.parent] then return end
        end
        return pose
    end

    local function PrunePoses(pose,parents)
        local head,tail
        while pose do
            local nextPose=pose.alternate
            pose.alternate=nil
            if KeepLayoutPose(pose,parents) then
                if tail then tail.alternate=pose else head=pose end
                tail=pose
            end
            pose=nextPose
        end
        return head
    end

    function Spatial.PruneLayoutPoses(parents)
        -- A registration still takes the guarded regional path this pass.
        -- Later crossings can reuse layouts whose own sources stayed registered.
        local poses=Spatial.stripPoses
        if poses then
            for expanded,pose in pairs(poses) do poses[expanded]=PrunePoses(pose,parents) end
        end
        Spatial.rosterPose=PrunePoses(Spatial.rosterPose,parents)
    end

    function Spatial.FindLayoutPose(pose,segments)
        local previous
        while pose do
            if Spatial.MatchLayoutPose(pose,segments) then return pose,previous end
            previous,pose=pose,pose.alternate
        end
    end

    function Spatial.RememberLayoutPose(pose,head,previous,strip)
        if pose~=head then
            if previous then previous.alternate=pose.alternate end
            pose.alternate=head
        end
        -- Keep several small neighborhoods under the old two-plan ceiling
        -- for geometry, operations and drawn fields in each layout family.
        local countLimit,segmentLimit,operationLimit,fieldLimit=3,512,256,4096
        if strip then countLimit,segmentLimit,operationLimit,fieldLimit=4,2048,768,8192 end
        local count,segments,operations,fields=0,0,0,0
        local current,last=pose
        while current do
            count=count+1
            segments=segments+#current.segments
            operations=operations+#current.operations
            fields=fields+(current.plan and current.plan.total or 0)
            if count>countLimit or segments>segmentLimit or operations>operationLimit or fields>fieldLimit then
                last.alternate=nil
                break
            end
            last,current=current,current.alternate
        end
    end

    local function PreparedDrawInputs(op)
        local inputs,seen={},{}
        for _,fields in ipairs({op.triangles,op.fallbackTriangles}) do
            for _,field in ipairs(fields) do
                if not field.quadTail then
                    local source,blockers=field.texture,field.fallbackBlockers
                    if issecretvalue and issecretvalue(source) or not source then return end
                    local gates=seen[source]
                    if not gates then
                        gates={};seen[source]=gates
                        inputs[#inputs+1]=field
                    elseif blockers and not gates[blockers] then
                        inputs[#inputs+1]=field
                    end
                    if blockers then gates[blockers]=true end
                end
            end
        end
        return inputs
    end

    function Spatial.SaveLayoutPlan(pose,regions,prepared,operations,sources,levels,total)
        -- The retained cells are geometry only. They carry the public material
        -- identity and still get color and alpha from the current paint pass.
        if total>4096 then return end
        local materials,stripLevels={},{}
        for texture,s in pairs(sources) do materials[texture]={path=s.path,uv=s.uv,support=s.support,gutter=s.gutter} end
        local logical,indices,cells={},{},{}
        local function StripPaint(op)
            for _,field in ipairs(op.triangles or {}) do
                field.source=materials[field.texture];field.retainUV=true
            end
            for _,field in ipairs(op.fallbackTriangles or {}) do
                field.source=materials[field.texture];field.retainUV=true
            end
        end
        for index,op in ipairs(operations) do
            logical[index]=Spatial.CopyDrawOperation(op)
            indices[op]=index
            StripPaint(op)
        end
        for key,cell in pairs(prepared) do
            local plans,draw={},{}
            for index,p in ipairs(cell.plans) do
                -- The first draw fills shared UV arrays. A prepared replay
                -- uses them only after its material was validated again.
                if #p.rects>0 then p.fragmentUVs={} end
                if #p.fallbackRects>0 then p.fallbackUVs={} end
                local geometry={}
                for field,value in pairs(p) do geometry[field]=value end
                geometry.source=materials[p.item.texture]
                plans[index]=geometry
            end
            for index,op in ipairs(cell.operations) do
                local recipe=Spatial.CopyDrawOperation(op)
                recipe._logicalIndex=indices[op._logicalOp]
                StripPaint(recipe)
                recipe._preparedDrawInputs=PreparedDrawInputs(recipe)
                draw[index]=recipe
            end
            cells[key]={rect=cell.rect,plans=plans,fallbacks=cell.fallbacks,operations=draw,count=cell.count,solved=cell.solved}
        end
        for _,op in ipairs(logical) do if op.renderStrip then
            for group in pairs(op.members) do stripLevels[group.parent]=levels.native[group.parent].level end
        end end
        pose.plan={regions=regions,cells=cells,operations=logical,materials=materials,stripLevels=stripLevels,total=total}
    end

    function Spatial.RestoreLayoutPlan(pose,regions,regionIndex)
        local plan=pose.plan
        if not plan then return end
        for key,rect in pairs(regions) do
            local saved=plan.regions[key]
            if not saved or not SameRect(saved,rect) then return end
        end
        local cells,total,logical=plan.cells,plan.total
        for key in pairs(plan.regions) do
            if not regions[key] then
                -- A shorter predecessor can dirty fewer tiles at the same
                -- destination. Each saved cell is already clipped to its
                -- exact tile. Keep other cells and their live listeners.
                cells,total,logical={},0,{}
                for changed in pairs(regions) do
                    local cell=plan.cells[changed]
                    cells[changed]=cell;total=total+cell.count
                end
                break
            end
        end
        local paints={}
        for texture,material in pairs(plan.materials) do
            local source=J._ReadPreparedSource(texture,material)
            if not source then return end
            paints[texture]=source
        end
        -- Reconcile the raised strip with the same live levels used to
        -- admit this prepared plan. Failed admission keeps fresh full reads.
        local levelSamples
        for parent,level in pairs(plan.stripLevels) do
            local current=parent:GetFrameLevel()
            if not PublicNumber(current) or current~=level then return end
            levelSamples=levelSamples or {}
            levelSamples[parent]=current
        end
        local operations={}
        for index,op in ipairs(plan.operations) do
            if not logical or Spatial.Affects(op,regionIndex) then
                local copy=Spatial.CopyDrawOperation(op)
                operations[#operations+1]=copy
                -- Recipes refer to their original indices in the saved plan.
                if logical then logical[index]=copy end
            end
        end
        return cells,operations,paints,total,logical,levelSamples
    end
end

function Spatial.Try(segments,signature,global,cost,stripPose,registrations,admitted)
    if #segments==0 or not admitted and not Spatial.Eligible(segments) then return false end
    local cold=global or not Spatial.raw
    local raw,rawOwners,runs=Spatial.Copy(segments,true,not cold);local changed={}
    local oldOwners=Spatial.rawOwners
    local rosterChanged
    if cold then
        for _,g in pairs(rawOwners) do
            if Spatial.IsScoped(g) then Spatial.MarkGroup(g,changed)
            else for _,item in ipairs(g.pieces) do if not Spatial.RectCells(item.rect,changed) then return false end end end
        end
    else
        local ok
        ok,rosterChanged=Spatial.Changed(oldOwners,rawOwners,changed)
        if not ok then return false end
    end
    if not next(changed) then previous=signature;J.stats.unchanged=J.stats.unchanged+1;return true end
    Spatial.ScopeBounds(changed,rawOwners,oldOwners)
    local count=0;for _ in pairs(changed) do count=count+1;if count>1024 then return false end end
    local regionIndex=Spatial.IndexRegions(changed)
    local stripTransition=type(stripPose)=="boolean" and not cold and not registrations
    local rosterTransition=stripPose==nil and rosterChanged and not registrations
    local cacheLayout=stripTransition or rosterTransition
    local selected=cold and Spatial.Copy(raw) or Spatial.Query(raw,changed,rawOwners,regionIndex,cacheLayout,runs)
    local poses=stripTransition and Spatial.stripPoses
    local last=poses and poses[stripPose]
    if rosterTransition then last=Spatial.rosterPose end
    local stored,priorPose=Spatial.FindLayoutPose(last,selected)
    local reused=stored~=nil
    local prepared,meshOperations,liveSources,total,logicalDrawOperations,levelSamples
    if reused then
        prepared,meshOperations,liveSources,total,logicalDrawOperations,levelSamples=Spatial.RestoreLayoutPlan(stored,changed,regionIndex)
    end
    local newPose,sources
    if not prepared then
        local ops
        if reused then
            selected=stored.segments
            ops=Spatial.CopyPoseOperations(stored.operations)
        else
            if cacheLayout then selected=Spatial.Copy(selected) end
            ops=J:Solve(selected)
            if not ops then return false end
            if cacheLayout then newPose=Spatial.SaveLayoutPose(selected,ops,rosterTransition) end
        end
        MarkCost(cost,"solve")
        if cost then cost.planLast=cost.last;cost.planPhases={} end
        meshOperations={}
        for _,op in ipairs(ops) do
            if cold or Spatial.Affects(op,regionIndex) then meshOperations[#meshOperations+1]=op end
        end
        local plans,blocked,_,aborted,inputs=J:_PreparePlan(selected,ops,cost,signature,meshOperations)
        if reused or newPose then
            for _,segment in ipairs(selected) do segment.source=nil end
        end
        if aborted or next(blocked) then return false end
        -- Retain every source consulted by the planner, even one with no
        -- fragment in these tiles. Its material can affect cached ownership.
        sources=inputs
        for _,source in pairs(sources) do if not source then return false end end
        local batches,items=Spatial.RouteRegions(changed,Spatial.Owners(selected),meshOperations,regionIndex)
        if cold then
            -- Global rebuilds validate all sources in the selected groups.
            for texture in pairs(items) do if not Spatial.TileSource(sources,texture) then return false end end
        end
        prepared={};total=0
        for key,batch in pairs(batches) do
            local cell=Spatial.PrepareCell(batch,selected,plans,sources,items)
            if not cell then return false end
            prepared[key]=cell;total=total+cell.count
        end
    end
    local budget=Spatial.Budget(prepared,total,cold);if not budget then return false end
    local combined={}
    if not cold then for _,op in ipairs(Spatial.ops or {}) do
        if not Spatial.Affects(op,regionIndex) then combined[#combined+1]=op end
    end end
    for _,op in ipairs(meshOperations) do combined[#combined+1]=op end
    local levels=Spatial.Levels(combined,levelSamples);if not levels then return false end
    if sources and (newPose or reused) and (not rosterTransition or total<=2048) then
        Spatial.SaveLayoutPlan(newPose or stored,changed,prepared,meshOperations,sources,levels,total)
    end
    if not reused then J.stats.solves=J.stats.solves+1 end
    J.stats.localUpdated=count
    MarkCost(cost,"plan")
    renderWork=cost and {fieldCalls=0,fieldHits=0,fieldWrites=0,alphaReads=0,alphaWrites=0,showReads=0,showWrites=0,hideReads=0,hideWrites=0,basisReads=0} or nil
    Spatial.Commit(prepared,raw,rawOwners,combined,signature,cold,cost,levels,liveSources,
        liveSources and (logicalDrawOperations or meshOperations),rosterTransition,budget)
    local pose=newPose or stored
    if pose and (stripTransition or pose.plan) then
        Spatial.RememberLayoutPose(pose,last,priorPose,stripTransition)
        if stripTransition then
            Spatial.stripPoses=Spatial.stripPoses or {}
            Spatial.stripPoses[stripPose]=pose
        else Spatial.rosterPose=pose end
    end
    if stripTransition and reused then
        J.stats.stripPoseHits=(J.stats.stripPoseHits or 0)+1
    end
    if stripTransition and liveSources then J.stats.stripPlanHits=(J.stats.stripPlanHits or 0)+1 end
    if cost then cost.work=renderWork;cost.localUpdated=count;cost.localCells=J.stats.localCells;cost.localCold=cold end
    renderWork=nil
    return true
end

function J:_LocalSegment(segment,point)
    if not Spatial.raw then return end
    local key
    if Spatial.IsScoped(segment.group) then
        key="scope:"..segment.group.plane
    else
        local x=segment.axis=="H" and point or segment.p
        local y=segment.axis=="V" and point or segment.p
        key=floor(x/Spatial.size)..":"..floor(y/Spatial.size)
    end
    local cell=Spatial.cells[key]
    if cell and cell.enabled then for _,saved in ipairs(cell.solved or {}) do
        if saved.texture==segment.texture then return saved end
    end end
end
function Spatial.ReadFilter(refresh,global)
    if global or refresh.all or not Spatial.raw then return end
    local _,filter=Spatial.Eligible(Spatial.raw,refresh.items)
    return filter
end
J._ResetLocality=Spatial.Reset

function J:Flush(stripPose)
    queued=false
    if not ready or not dirty or Locked() then return end
    -- Continuous drag/layout animation may invalidate every render frame. Keep
    -- at most one delayed wake and cap geometry reads to 20 Hz during that burst.
    -- When layout stops, no further wake is scheduled.
    if GetTime and C_Timer and C_Timer.After then
        local now=GetTime()
        if now<nextPass then
            queued=true
            DelayFlush(nextPass-now)
            return
        end
        nextPass=now+.05
    end
    local cost=BeginCost()
    ConsumeFlushWake()
    dirty=false;self.stats.passes=self.stats.passes+1
    local globalChange=fullDirty
    local registrations=registrationDirty
    local geometryChanged=fullDirty or registrations
    registrationDirty=false
    local observerRefresh={all=fullDirty,items={}}
    self._RefreshObserverLinks()
    local registeredParents
    if registrations then
        registeredParents=registrationParents
        for parent in pairs(registeredParents) do if parent then RefreshObserverDependents(observerRefresh,parent) end end
        registrationParents=setmetatable({}, {__mode="k"})
    end
    local reasons={}
    if cost then
        -- Reuse the existing bounded reason strings and preflight loops. These
        -- describe changed graphics state, not the upstream event/caller.
        cost.readReasons=reasons
        cost.dirtyState={fullInvalidation=fullDirty,pendingObjects=0,paintObjects=0,
            waitingRetire=0,waitingAlpha=0,waitingColor=0,snapshotChanges=0,materialChanges=0,uvChanges=0}
    end
    if fullDirty then reasons[1]="load/settings/global invalidation" end
    fullDirty=false
    local sampled
    for object in pairs(pendingObjects) do
        local entry=clipped[object]
        if cost then
            local state=cost.dirtyState
            state.pendingObjects=state.pendingObjects+1
            if entry then
                if entry.waitingRetire then state.waitingRetire=state.waitingRetire+1 end
                if entry.waitingAlpha then state.waitingAlpha=state.waitingAlpha+1 end
                if entry.waitingColor then state.waitingColor=state.waitingColor+1 end
            end
        end
        if entry and entry.waitingRetire then
            entry.waitingRetire=nil;geometryChanged=true;previous=nil
            RefreshObserverDependents(observerRefresh,object)
            if #reasons<3 then reasons[#reasons+1]=DiagnosticName(object)..":restricted RGB retirement" end
        end
        if entry and (entry.waitingAlpha or entry.waitingColor) and Source(object) then
            -- Recolor can briefly write public alpha1 before a native private
            -- maximum is reapplied in the same update. Recover only after the
            -- final coalesced source is public, without resetting every owner.
            entry.waitingAlpha=nil;entry.waitingColor=nil
            geometryChanged=true;previous=nil
            RefreshObserverDependents(observerRefresh,object)
            if #reasons<3 then reasons[#reasons+1]=DiagnosticName(object)..":public RGB recovery" end
        end
        if registrations then RefreshObserverDependents(observerRefresh,object) end
        local current,unavailable=Snapshot(object)
        local record=Border._pieces[object]
        if current and record and record.junctionWatched and not globalChange and not registrations then
            sampled=sampled or {}
            sampled[object]=current
        end
        if not SameSnapshot(observed[object],current) then
            if cost then cost.dirtyState.snapshotChanges=cost.dirtyState.snapshotChanges+1 end
            if #reasons<3 then reasons[#reasons+1]=SnapshotReason(object,observed[object],current,unavailable) end
            geometryChanged=true;observed[object]=current
            RefreshObserverDependents(observerRefresh,object)
        end
    end
    pendingObjects=setmetatable({}, {__mode="k"})
    local artChanged=false
    for texture in pairs(paintDirty) do
        if cost then cost.dirtyState.paintObjects=cost.dirtyState.paintObjects+1 end
        local entry=clipped[texture]
        if entry and entry.active then
            local source=Source(texture)
            if not source or source.path~=entry.path or source.support~=entry.support or #source.uv~=#entry.uv then
                artChanged=true
                if cost then cost.dirtyState.materialChanges=cost.dirtyState.materialChanges+1 end
                if #reasons<3 then reasons[#reasons+1]=DiagnosticName(texture)..":source material/availability changed" end
            else for i,v in ipairs(source.uv) do if v~=entry.uv[i] then
                artChanged=true
                if cost then cost.dirtyState.uvChanges=cost.dirtyState.uvChanges+1 end
                if #reasons<3 then reasons[#reasons+1]=string.format("%s:UV%d %.6f->%.6f",DiagnosticName(texture),i,entry.uv[i],v) end
                break
            end end end
        end
    end
    paintDirty=setmetatable({}, {__mode="k"})
    MarkCost(cost,"preflight")
    if not geometryChanged and not artChanged then
        self.stats.fastSkips=(self.stats.fastSkips or 0)+1
        self.stats.unchanged=self.stats.unchanged+1
        EndCost(cost,"unchanged");return
    end
    self.stats.geometryReads=(self.stats.geometryReads or 0)+1
    readReasons[#readReasons+1]="read"..self.stats.geometryReads.." "..table.concat(reasons,"; ")
    if #readReasons>6 then table.remove(readReasons,1) end
    if idleTrace then
        local reads=idleTrace.reads;reads[#reads+1]=readReasons[#readReasons]
        if #reads>3 then table.remove(reads,1) end
    end
    local alignmentChanges=self:AlignNearbyPanels()
    self._RefreshObserverLinks()

    -- Only reuse public snapshots of watched sources through a read-only
    -- layout pass. Alignment or observer changes can move their anchors.
    if sampled and (alignmentChanges~=0 or registrationDirty or next(pendingObjects)) then sampled=nil end
    MarkCost(cost,"align")
    -- Alignment can queue fresh decorative setters after preflight. Owned
    -- canonical output retains public geometry outside this dependency closure;
    -- global/unsafe/foreign changes keep the full guarded read contract.
    if not observerRefresh.all then
        for object in pairs(pendingObjects) do
            local current=Snapshot(object)
            if not SameSnapshot(observed[object],current) then RefreshObserverDependents(observerRefresh,object) end
        end
    end
    -- No setters run between alignment and the completed watched snapshots.
    -- Native query/availability memos remain phase-only. Regional storage keeps
    -- resolved public decorative geometry, never a private/unavailable marker.
    local regionalFilter
    rectReadPhase={native={},private={},resolved={},origin={}}
    local phaseOK,segments,signature=pcall(function()
        regionalFilter=Spatial.ReadFilter(observerRefresh,globalChange or artChanged)
        local values,stamp=ReadLayout(regionalFilter,Spatial.raw)
        stamp.appearance=Border:GetBorderType()..":"..Border:GetAccentMode()
        if not regionalFilter then sampled=nil end
        for object in pairs((observerRefresh.all or fullDirty) and watched or observerRefresh.items) do
            local current=sampled and not rectReadPhase.admissionInvalidated and not fullDirty and sampled[object]
            observed[object]=current or Snapshot(object)
        end
        return values,stamp
    end)
    -- The filter already checked every registered source. An observed change
    -- during this synchronous read, including adoption, requires a new check.
    local admitted=regionalFilter and rectReadPhase and not rectReadPhase.admissionInvalidated
    rectReadPhase=nil
    if not phaseOK then error(segments,0) end
    MarkCost(cost,"geometry")
    if registeredParents then Spatial.PruneLayoutPoses(registeredParents) end
    if registrationDirty then Spatial.PruneLayoutPoses(registrationParents) end
    if not artChanged and SameLayout(signature,previous) then self.stats.unchanged=self.stats.unchanged+1;EndCost(cost,"same-signature");return end
    if Spatial.Try(segments,signature,globalChange or observerRefresh.all or artChanged,cost,stripPose,registrations or registrationDirty,admitted) then
        self._PublishArrowLayers()
        MarkCost(cost,"commit");EndCost(cost,"local-build");return
    end
    if regionalFilter then
        -- Unsupported/foreign sources return to the original fresh-read contract.
        rectReadPhase={native={},private={},resolved={},origin={}}
        local ok,values,stamp=pcall(ReadLayout)
        rectReadPhase=nil
        if not ok then error(values,0) end
        segments=values;signature=stamp
        signature.appearance=Border:GetBorderType()..":"..Border:GetAccentMode()
    end
    if Spatial.raw then self:ReleaseAll() end
    self.stats.solves=self.stats.solves+1
    self.stats.operations=0;self.stats.fragments=0;self.stats.triangles=0
    local operations,reason=self:Solve(segments)
    MarkCost(cost,"solve")
    self.stats.fallback=reason
    if not operations then self:ReleaseAll();self._PublishArrowLayers();previous=signature;MarkCost(cost,"commit");EndCost(cost,"fallback");return end
    if cost then cost.planLast=cost.last;cost.planPhases={} end
    local plans,blocked,total,planAborted=self:_PreparePlan(segments,operations,cost,signature)
    if planAborted then return end
    -- Commit the fully prepared layout in one Lua call; never expose a reset
    -- between asynchronous layout callbacks and the finished replacement.
    PlanCost(cost,"rest")
    MarkCost(cost,"plan")
    if cost then cost.commitLast=cost.last;cost.commitPhases={} end
    renderWork=cost and {fieldCalls=0,fieldHits=0,fieldWrites=0,alphaReads=0,alphaWrites=0,
        showReads=0,showWrites=0,hideReads=0,hideWrites=0,basisReads=0} or nil
    BeginRenderGeneration()
    local ok,err=pcall(function()
        for _,plan in pairs(plans) do if not blocked[plan.root] then RenderFragments(plan.item,plan.rects,plan.source,plan.root,plan.renderStrip,plan.renderLevel,plan.roundCap,plan.renderMembers) end end
        CommitCost(cost,"fragments")
        -- Originals now have authoritative entry alpha/visibility. Only our
        -- replacement fields change until retirement; retain no live-paint memo.
        fallbackChains={};fallbackAvailability={}
        for _,plan in pairs(plans) do if not blocked[plan.root] then RenderFallbackRectangles(plan) end end
        CommitCost(cost,"fallbacks")
        for _,op in ipairs(operations) do if not blocked[op.root] and op.bits then PrepareDrawReuse(op) end end
        local meshPrepared=cost and not cost.invalid and CostClock()
        for _,op in ipairs(operations) do
            if not blocked[op.root] then
                active[#active+1]=op
                if op.bits then Draw(op);self.stats.triangles=self.stats.triangles+#op.triangles+#(op.fallbackTriangles or {}) end
            end
        end
        CommitCost(cost,"mesh",meshPrepared)
        fallbackChains=nil;fallbackAvailability=nil
        -- New fields are complete before old unclaimed paint is retired.
        -- Retain both operation lists until this succeeds, for full rollback.
        for texture,entry in pairs(clipped) do
            if entry.active and entry.epoch~=renderEpoch then entry.active=false;FieldAlpha(texture,entry.alpha) end
            for _,field in ipairs(entry.pool) do if field._renderEpoch~=renderEpoch then FieldHide(field) end end
        end
        for _,op in ipairs(rollbackActive) do for _,field in ipairs(op.sprites or {}) do
            if field._renderEpoch~=renderEpoch then FieldHide(field);field._junctionOp=nil;field._junctionOwnerOp=nil end
        end end
        CommitCost(cost,"retire")
    end)
    if cost then cost.work=renderWork end
    renderWork=nil
    EndRenderGeneration()
    -- Cleanup is transactional; surface the exact native failure after restoring
    -- all original art rather than leaving a partially applied, cached layout.
    if not ok then self:ReleaseAll();MarkCost(cost,"commit");EndCost(cost,"error");error(err,0) end
    rollbackActive=nil
    if self._PublishBranchCompileCache then self:_PublishBranchCompileCache() end
    if self._PublishFallbackCompileCache then self:_PublishFallbackCompileCache() end
    if self._PublishFallbackPlanCache then self:_PublishFallbackPlanCache() end
    if PublishDrawCache then PublishDrawCache() end
    for _,segment in ipairs(segments) do committedSegments[segment.texture]=segment end
    self.stats.operations=#active;self.stats.fragments=total;previous=signature
    self._PublishArrowLayers()
    MarkCost(cost,"commit");EndCost(cost,"build")
end

-- Explicit layout transactions can commit after their dependent anchors have
-- settled. Repeated unchanged transactions still stop at the dirty preflight.
function J:CommitLayout(stripPose)
    if not ready or not dirty or Locked() then return end
    nextPass=0;self:Flush(stripPose)
end
function J:Invalidate(force,object,reason)
    if painting then return end
    if rectReadPhase then
        rectReadPhase.admissionInvalidated=true
        rectReadPhase.roles=nil
    end
    if force then
        previous=nil
        for _,g in pairs(groups) do
            g.paintPriority=nil
            for _,child in pairs(g.children or {}) do child.paintPriority=nil end
        end
    end
    if object and not force then
        pendingObjects[object]=true
        if idleTrace and reason then
            local requests=idleTrace.localRequests
            if not requests then requests={};idleTrace.localRequests=requests;idleTrace.localKinds=0 end
            if requests[reason] or idleTrace.localKinds<12 then
                if not requests[reason] then idleTrace.localKinds=idleTrace.localKinds+1 end
                requests[reason]=(requests[reason] or 0)+1
            else requests.other=(requests.other or 0)+1 end
        end
    else
        fullDirty=true;self.stats.fullInvalidations=(self.stats.fullInvalidations or 0)+1
        if idleTrace then
            reason=reason or (force and "explicit style/settings" or "global request")
            local requests=idleTrace.requests
            if requests[reason] or idleTrace.requestKinds<12 then
                if not requests[reason] then idleTrace.requestKinds=idleTrace.requestKinds+1 end
                requests[reason]=(requests[reason] or 0)+1
            else requests.other=(requests.other or 0)+1 end
        end
    end
    dirty=true
    if not ready or queued or Locked() then return end
    local scheduler=Flux and Flux.Scheduler
    if scheduler then
        queued=true;scheduler.Request("structural","border.junctions",NewFlushWake(),"border layout")
    elseif C_Timer and C_Timer.After then queued=true;C_Timer.After(0,NewFlushWake()) end
end
-- One lifecycle owner, no OnUpdate, ticker, combat polling or global UI hooks.
local events=CreateFrame("Frame")
for _,file in ipairs({"ForeverMetal150.tga","ForeverMetal150Tint.tga","Battlefield100.tga"}) do
    local preload=events:CreateTexture(nil,"BACKGROUND")
    preload:SetTexture(PATH..file);preload:Hide()
end
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_ENTERING_WORLD" then ready=true end
    if event=="PLAYER_REGEN_ENABLED" then
        -- Combat is a permission boundary, not a layout change. Resume only
        -- work already dirtied by a real producer, retaining its local scope.
        if ready and dirty and not queued then
            local scheduler=Flux and Flux.Scheduler
            if scheduler then
                queued=true;scheduler.Request("structural","border.junctions",NewFlushWake(),"border layout")
            elseif C_Timer and C_Timer.After then queued=true;C_Timer.After(0,NewFlushWake()) end
        end
    elseif ready then J:Invalidate(nil,nil,idleTrace and "event: "..event) end
end)
for texture,record in pairs(Border._pieces) do J:Adopt(texture,record) end

-- Read-only loaded-code identity and topology counters, for correlating native
-- screenshots with files that changed after the last client reload.
SLASH_FLUXBORDERS1="/fluxborders"
local function Audit(emit)
    local segments=ReadLayout()
    local handled={}
    for _,op in ipairs(active) do
        if not op.bits then
            for a in pairs(op.members) do
                handled[a]=handled[a] or {}
                for b in pairs(op.members) do handled[a][b]=true end
            end
        end
    end
    local function Name(g)
        local parent=g.parent
        while parent and parent~=UIParent do
            local name=parent.GetName and parent:GetName()
            if not (issecretvalue and issecretvalue(name)) and type(name)=="string" and name~="" then return name end
            parent=parent._FluxBorderOwner or parent.GetParent and parent:GetParent()
        end
        return g.unitOwner or "group"..g.id
    end
    local function PaintAt(segment,point)
        local old=J:_LocalSegment(segment,point) or committedSegments[segment.texture]
        local entry=clipped[segment.texture]
        if old and entry and entry.active and abs(old.rawP-segment.p)<.00001
            and abs(old.a-segment.a)<.00001 and abs(old.b-segment.b)<.00001 then
            return PaintOwner(old,point).texture
        end
        return segment.texture
    end
    local function SamePaint(a,b)
        local low,high=max(a.a,b.a),min(a.b,b.b)
        for _,point in ipairs({low+EPS,(low+high)/2,high-EPS}) do
            if PaintAt(a,point)~=PaintAt(b,point) then return false end
        end
        return true
    end
    local maxScale=1
    for _,s in ipairs(segments) do maxScale=max(maxScale,s.scale) end
    table.sort(segments,function(a,b)
        if a.axis~=b.axis then return a.axis<b.axis end
        if a.group.plane~=b.group.plane then return a.group.plane<b.group.plane end
        return a.p<b.p
    end)
    local candidates,pairsSeen,limited={},0,false
    for i,a in ipairs(segments) do
        for k=i+1,#segments do
            local b=segments[k]
            if b.axis~=a.axis or b.group.plane~=a.group.plane or b.p-a.p>17*maxScale then break end
            pairsSeen=pairsSeen+1
            if pairsSeen>8192 then limited=true;break end
            local axis=a.axis=="H" and 2 or 1
            local length=min(a.b,b.b)-max(a.a,b.a)
            if a.group~=b.group and JoinAllowed(a,b) and length>4
                and not (handled[a.group] and handled[a.group][b.group])
                and not SamePaint(a,b)
                and max(a.rect[axis],b.rect[axis])<min(a.rect[axis+2],b.rect[axis+2]) then
                candidates[#candidates+1]={a=a,b=b,length=length,gap=abs(a.p-b.p),
                    hud=not a.group.unitOwner and not b.group.unitOwner}
            end
        end
        if limited then break end
    end
    table.sort(candidates,function(a,b)
        if a.hud~=b.hud then return a.hud end
        if a.gap~=b.gap then return a.gap<b.gap end
        return a.length>b.length
    end)
    emit("Border audit "..J.version.." type="..Border:GetBorderType().." edges="..#segments.." unmatched="..#candidates.." limited="..tostring(limited))
    for i=1,min(6,#candidates) do
        local c=candidates[i]
        emit(string.format("%s.%s %.2f | %s.%s %.2f gap=%.2f overlap=%.1f",
            Name(c.a.group),c.a.side,c.a.p,Name(c.b.group),c.b.side,c.b.p,c.gap,c.length))
    end
end
local function TargetAudit(emit)
    local frame=ns.TargetFrame
    if not frame then emit("Target chrome not initialized; "..J.version);return end
    local function Pieces(owner)
        local bf=owner and owner.FluxBorderFrame
        local out={}
        for _,key in ipairs({"TL","TR","BL","BR","Top","Bottom","Left","Right"}) do
            if bf and bf[key] and Geometry(bf[key]) then out[#out+1]=key end
        end
        return #out>0 and table.concat(out,",") or "-"
    end
    emit("Target chrome "..J.version.." persistent="..tostring(frame._fluxTargetChrome~=nil))
    emit("base="..Pieces(frame))
    emit("atlas="..Pieces(frame.atlasBorderFrame))
    emit("outer="..Pieces(frame.outerBorderFrame))
    emit("portrait="..Pieces(frame.PortraitFrame).." placeholder="..Pieces(frame.placeholderBorder))
    local tot=ns.TargetOfTargetFrame
    emit("target-of-target base="..Pieces(tot).." atlas="..Pieces(tot and tot.atlasBorderFrame).." outer="..Pieces(tot and tot.outerBorderFrame))
    emit("threat="..Pieces(frame.ThreatBar).." cast="..Pieces(frame.CastBar and frame.CastBar.BorderFrame))
end
local function IdleAudit(emit)
    if not (C_Timer and C_Timer.After) then emit("Border idle check unavailable; compare two status readings.");return end
    local start={}
    local trace={reads={},requests={},requestKinds=0};idleTrace=trace
    for _,key in ipairs({"passes","solves","geometryReads","panelAlignments","fullInvalidations","privateAlphaWrites","privateColorWrites"}) do start[key]=J.stats[key] or 0 end
    emit("Border idle check started; keep the layout unchanged for 10 seconds.")
    C_Timer.After(10,function()
        emit(string.format("Border idle delta %s solves=%d panelAlignments=%d geometryReads=%d checks=%d fullRequests=%d privateAlpha=%d privateColor=%d",
            J.version,(J.stats.solves or 0)-start.solves,(J.stats.panelAlignments or 0)-start.panelAlignments,
            (J.stats.geometryReads or 0)-start.geometryReads,(J.stats.passes or 0)-start.passes,
            (J.stats.fullInvalidations or 0)-start.fullInvalidations,
            (J.stats.privateAlphaWrites or 0)-start.privateAlphaWrites,(J.stats.privateColorWrites or 0)-start.privateColorWrites))
        if idleTrace==trace then idleTrace=nil end
        local requests={}
        for reason,count in pairs(trace.requests) do requests[#requests+1]=count.."x "..reason end
        table.sort(requests)
        if #requests>0 then emit("Border full refresh: "..table.concat(requests,"; ")) end
        local locals={}
        for reason,count in pairs(trace.localRequests or {}) do locals[#locals+1]=count.."x "..reason end
        table.sort(locals)
        if #locals>0 then emit("Border local refresh: "..table.concat(locals,"; ")) end
        for _,reason in ipairs(trace.reads) do emit("Border interval "..reason) end
    end)
end
local function AuraAudit(emit)
    local frame=ns.TargetFrame or ns.FocusFrame
    if not frame then emit("Aura borders not initialized; "..J.version);return end
    emit("Aura borders "..J.version.." unit="..tostring(frame.unit))
    local left,right
    for _,name in ipairs({"BuffContainer","DebuffContainer"}) do
        local bf=frame[name] and frame[name].borderFrame
        local top=bf and committedSegments[bf.Top]
        local side=bf and committedSegments[bf[name=="BuffContainer" and "Right" or "Left"]]
        if top and side then
            emit(string.format("%s top=%.3f span=%.3f..%.3f middle=%.3f",name,top.p,top.a,top.b,side.p))
            if name=="BuffContainer" then left={top=top,side=side} else right={top=top,side=side} end
        else emit(name.." hidden or awaiting geometry") end
    end
    local found=false
    if left and right then
        local x=(left.side.p+right.side.p)/2
        for _,op in ipairs(active) do
            if op.bits and abs(op.x-x)<4*max(left.side.scale,right.side.scale)
                and abs(op.y-left.top.p)<2 then
                local level=op.sprite and op.sprite:GetParent():GetFrameLevel()
                local alpha=op.sprite and op.sprite:GetAlpha()
                emit(string.format("middle bits=%d triangles=%d level=%s alpha=%s",op.bits,#(op.triangles or {}),
                    PublicNumber(level) and tostring(level) or "private",PublicNumber(alpha) and tostring(alpha) or "private"))
                found=true
            end
        end
    end
    if not found then emit("middle junction not committed") end
end
SlashCmdList.FLUXBORDERS=function(message)
    if type(message)=="string" and message:lower():match("^%s*cost") then
        local emit=Flux and Flux.Print or print
        if not peakCost then emit("Border costs: run /fluxperf watch 60 50, reproduce a layout change, then /fluxborders cost");return end
        local p=peakCost.phases
        emit(string.format("Border peak %s %s total=%.2fms preflight=%.2f align=%.2f geometry=%.2f solve=%.2f plan=%.2f commit=%.2f",J.version,peakCost.kind,peakCost.total,p.preflight or 0,p.align or 0,p.geometry or 0,p.solve or 0,p.plan or 0,p.commit or 0))
        emit(string.format("Border peak fields operations=%d fragments=%d triangles=%d baseHits=%d baseMisses=%d sourceReads=%d sourceHits=%d fallbackHits=%d fallbackMisses=%d fallbackProbes=%d fallbackPlanHits=%d fallbackPlanMisses=%d regions=%d changed=%d",peakCost.operations,peakCost.fragments,peakCost.triangles,peakCost.baseHits or 0,peakCost.baseMisses or 0,peakCost.sourceReads or 0,peakCost.sourceHits or 0,peakCost.fallbackHits or 0,peakCost.fallbackMisses or 0,peakCost.fallbackProbes or 0,peakCost.fallbackPlanHits or 0,peakCost.fallbackPlanMisses or 0,peakCost.localCells or 0,peakCost.localUpdated or 0))
        local c,w=peakCost.commitPhases,peakCost.work
        if c then emit(string.format("Border commit fragments=%.2fms fallbacks=%.2f mesh=%.2f retire=%.2f",c.fragments or 0,c.fallbacks or 0,c.mesh or 0,c.retire or 0)) end
        if w then emit(string.format("Border work setters=%d hits=%d writes=%d alphaReads=%d alphaWrites=%d basisReads=%d drawReuse=%d",w.fieldCalls,w.fieldHits,w.fieldWrites,w.alphaReads,w.alphaWrites,w.basisReads,w.drawReuses or 0)) end
        local q=peakCost.planPhases
        if q then emit(string.format("Border plan cuts=%.2fms branches=%.2f owners=%.2f cells=%.2f fallbackMesh=%.2f",q.cuts or 0,q.branches or 0,q.owners or 0,q.fallbackCells or 0,q.fallbackMesh or 0)) end
        return
    end
    if type(message)=="string" and message:lower():match("^%s*why") then
        local emit=Flux and Flux.Print or print
        emit("Border rebuild reasons "..J.version)
        for _,reason in ipairs(readReasons) do emit(reason) end
        return
    end
    if type(message)=="string" and message:lower():match("^%s*aura") then
        AuraAudit(Flux and Flux.Print or print);return
    end
    if type(message)=="string" and message:lower():match("^%s*idle") then
        IdleAudit(Flux and Flux.Print or print);return
    end
    if type(message)=="string" and message:lower():match("^%s*target") then
        TargetAudit(Flux and Flux.Print or print);return
    end
    if type(message)=="string" and message:lower():match("^%s*audit") then
        Audit(Flux and Flux.Print or print);return
    end
    local pieces,atlasPieces=0,0
    for texture in pairs(Border._pieces) do
        pieces=pieces+1
        if texture.GetAtlas then
            local atlas=texture:GetAtlas()
            if not (issecretvalue and issecretvalue(atlas)) and type(atlas)=="string" and atlas~="" then atlasPieces=atlasPieces+1 end
        end
    end
    local emit=Flux and Flux.Print or print
    emit("Flux borders "..J.version.." type="..Border:GetBorderType().." pieces="..pieces.." nativeAtlas="..atlasPieces.." ready="..tostring(ready))
    emit("passes="..J.stats.passes.." solves="..J.stats.solves.." unchanged="..J.stats.unchanged.." operations="..(J.stats.operations or 0).." fragments="..(J.stats.fragments or 0).." triangles="..(J.stats.triangles or 0).." geometryReads="..(J.stats.geometryReads or 0).." fastSkips="..(J.stats.fastSkips or 0).." panelAlignments="..(J.stats.panelAlignments or 0))
    emit("fallback="..tostring(J.stats.fallback).." dirty="..tostring(dirty).." queued="..tostring(queued).." combat="..tostring(Locked()))
end
