-- Replay both held-action border poses with native widget mocks and compare
-- identical transitions through the existing uncached regional path.
local file=assert(io.open("tests/border_locality.lua","rb"))
local source=file:read("*a"):gsub("\r\n","\n")
file:close()
source=source:sub(1,assert(source:find("if arg[1]=='--work' then",1,true))-1)
source=source:gsub("local corePath='Core/BorderJunctions.lua'","local corePath=...",1)
source=source:gsub("parents%[i%]=parent;",
    "parents[i]=parent;if g.name=='strip' then e.FluxActionStrip=parent end;",1)
source=source:gsub("cells=Spatial.cells,inspect=",
    "cells=Spatial.cells,poses=function()return Spatial.stripPoses end,operations=function()return Spatial.ops end,"
    .."matchPose=Spatial.MatchLayoutPose,remember=Spatial.RememberLayoutPose,raw=function()return Spatial.raw end,inspect=",1)
local Fixtures=assert(load(source.."\nreturn {model=model,scenes=scenes,compare=compare,box=box}",
    "@strip-border-fixture","t",_G))
local fixture=Fixtures("Core/BorderJunctions.lua")

local function scene(style)
    local groups=fixture.scenes(style)[3].groups
    groups[#groups+1]=fixture.box(920,-85,120,85,"combat",nil,5)
    groups[#groups+1]=fixture.box(1040,-85,70,85,"trinket",nil,5)
    groups[#groups+1]=fixture.box(-280,-85,100,85,"info",nil,5)
    return groups
end

local function CountBuilds(m)
    local counts={solve=0,plan=0}
    local solve,plan=m.j.Solve,m.j._PreparePlan
    m.j.Solve=function(self,...)
        counts.solve=counts.solve+1
        return solve(self,...)
    end
    m.j._PreparePlan=function(self,...)
        counts.plan=counts.plan+1
        return plan(self,...)
    end
    return counts
end

local function Move(m,expanded,cache)
    local offset=expanded and 8 or -8
    for _,index in ipairs({4,7,8,9}) do
        for _,texture in ipairs(m.sources[index]) do
            local axis=index==4 and 2 or 1
            texture.rect[axis]=texture.rect[axis]+offset
            m.j:Invalidate(nil,texture)
        end
    end
    if cache then m.j:CommitLayout(expanded) else m.j:CommitLayout() end
end

local points={{0,0},{320,0},{326,0},{920,-85},{1040,-85},{-180,-85}}

local function ReplayDifferentFootprints(renderer,style,modern)
    local groups=scene(style)
    groups[#groups+1]=fixture.box(1312,-55,30,50,"side panel",nil,6)
    local m=renderer.model(groups,style,1)
    local reference=fixture.model(groups,style,1)
    local work=CountBuilds(m)
    local width=0
    local function Resize(model,delta,pose)
        for _,index in ipairs({2,4,5,6,8}) do
            local texture=model.sources[4][index]
            local axis=(index==5 or index==6) and 3 or 1
            texture.rect[axis]=texture.rect[axis]+delta
            model.j:Invalidate(nil,texture)
        end
        for _,peer in ipairs({7,8}) do
            for _,texture in ipairs(model.sources[peer]) do
                texture.rect[1]=texture.rect[1]+delta
                model.j:Invalidate(nil,texture)
            end
        end
        model.j:CommitLayout(pose)
    end
    local broadPlan
    for step,nextWidth in ipairs({1,136,1,42,1,136,1,40,1}) do
        local epochs={}
        for key,cell in pairs(m.cells) do epochs[key]=cell.epoch end
        local delta=nextWidth-width
        width=nextWidth
        Resize(m,delta,false)
        Resize(reference,delta,nil)
        local samples={{920+width,0},{1040+width,-85},{1110+width,-85},{1312,-55}}
        for _,point in ipairs(points) do samples[#samples+1]=point end
        fixture.compare(m,reference,samples,1)
        assert(m.j.stats.localMode and not m.j.stats.fallback,"changed-width replay remains regional")
        local plan=assert(m.e.spatial.poses()[false].plan)
        if step==3 then broadPlan=plan end
        if modern and (step==5 or step==9) then
            assert(plan==broadPlan,"replaying a smaller footprint preserves the wider prepared plan")
            local retained,owners=0,{}
            for _,op in ipairs(m.e.spatial.operations()) do owners[op]=true end
            for key in pairs(plan.cells) do
                local active=m.cells[key]
                if active and active.enabled and active.epoch==epochs[key] then retained=retained+1 end
                if active and active.enabled then
                    for _,op in ipairs(active.active) do
                        if active.epoch~=epochs[key] then
                            assert(owners[op._logicalOp],"each reused draw links to a current operation")
                        end
                    end
                end
            end
            assert(retained>0,"a smaller footprint keeps live cells inside the saved wider plan")
        end
    end
    local hits=m.j.stats.stripPlanHits or 0
    if modern then assert(work.plan==5 and hits==4 and work.solve==4,"exact same destination uses the covering plan") end
    return work.plan,work.solve,hits
end

local function RegisterEdge(m,parent,rect)
    local seed=m.sources[4][5]
    local t,record=m.piece(parent,"Top",rect)
    local path=seed:GetTexture()
    record.art,record.artHandle=path,path
    t:SetTexture(path)
    t:SetTexCoord(seed:GetTexCoord())
    t:SetVertexColor(.4,.6,.8,.85)
    return t
end

local function ReplayRegistrations(style)
    local m=fixture.model(scene(style),style,1)
    local reference=fixture.model(scene(style),style,1)
    local counts=CountBuilds(m)
    local function Cross(expanded)
        Move(m,expanded,true)
        Move(reference,expanded,false)
        fixture.compare(m,reference,points,1)
        assert(m.j.stats.localMode and not m.j.stats.fallback,"canonical registration stays regional")
    end
    Cross(true)
    Cross(false)
    local poses=m.e.spatial.poses()
    local expanded,collapsed=assert(poses[true]),assert(poses[false])
    local detached={}
    for _,model in ipairs({m,reference}) do
        local parent=model.new(model.e.UIParent,{3800,900,140,80})
        parent._FluxBorderStatic=true
        detached[model]=RegisterEdge(model,parent,{3820,980,100,17})
    end
    Cross(true)
    assert(m.e.spatial.poses()==poses and poses[true]==expanded and poses[false]==collapsed,
        "distant adoption retains both strip layouts")
    local before=counts.plan
    Cross(false)
    Cross(true)
    assert(counts.plan==before,"no strip compilation after unrelated adoption")

    for _,model in ipairs({m,reference}) do
        local texture=detached[model]
        -- Forget must retire the last registered frame even after a reparent.
        texture:SetParent(model.parents[4])
        model.j:Forget(texture)
        texture:Hide()
    end
    Cross(false)
    assert(m.e.spatial.poses()==poses and poses[true]==expanded and poses[false]==collapsed,
        "distant removal retains both strip layouts")
    before=counts.plan
    Cross(true)
    Cross(false)
    assert(counts.plan==before,"no strip compilation after unrelated removal")

    -- Register against a participating panel, including a separate run in
    -- the same frame. Its old prepared layouts must be released.
    for _,model in ipairs({m,reference}) do
        RegisterEdge(model,model.parents[4],{921,20,30,17})
    end
    Cross(true)
    assert(not poses[true] and not poses[false],"registration on a strip source retires its saved layouts")
    before=counts.plan
    Cross(false)
    assert(counts.plan==before+1,"changed strip source recompiles its layout")
    print(("STRIP_REGISTRATION style=%d warmCompiles=0+0 affectedCompiles=1"):format(style))
end

for _,style in ipairs({1,2}) do
    local m=fixture.model(scene(style),style,1)
    local reference=fixture.model(scene(style),style,1)
    local work,full=CountBuilds(m),CountBuilds(reference)
    for step=1,6 do
        local expanded=step%2==1
        Move(m,expanded,true)
        Move(reference,expanded,false)
        fixture.compare(m,reference,points,1)
        assert(work.solve==math.min(2,step) and work.plan==math.min(2,step),"each pose solves once")
    end
    print(("STRIP_POSE style=%d solve=%d/%d plan=%d/%d preparedHits=%d"):format(
        style,full.solve,work.solve,full.plan,work.plan,m.j.stats.stripPlanHits))

    local poses=m.e.spatial.poses()
    assert(poses[false] and poses[true],"keep both expanded and collapsed poses")
    local pose=poses[false]
    local spatial=m.e.spatial
    local selected,retained={},nil
    for _,segment in ipairs(spatial.raw()) do
        assert(segment.rect==segment.item.rect and not segment.group._items,
            "raw snapshots share their source bounds and drop the temporary copy map")
        local left,bottom,width,height=segment.texture:GetRect()
        local bounds=segment.rect
        assert(bounds[1]==left and bounds[2]==bottom and bounds[3]==left+width and bounds[4]==bottom+height,
            "solving nearby joins leaves the sampled source rectangle intact")
        local old=pose.byTexture[segment.texture]
        if old then
            selected[#selected+1]=segment
            if segment.group._layoutStamps and segment.group._layoutStamps==old.group._layoutStamps then
                assert(old.rect==segment.rect and old.item.rect==segment.item.rect and old.item~=segment.item,
                    "the solver and snapshot share source bounds while keeping independent mutable piece records")
                retained=segment
            end
        end
    end
    assert(retained and spatial.matchPose(pose,selected),"an unchanged native group shares the pose's public sample")
    local parent=retained.group.parent
    local rounded=parent._FluxBorderRoundCorners
    parent._FluxBorderRoundCorners=not rounded
    assert(not spatial.matchPose(pose,selected),"a shared geometry sample still validates current corner flags")
    parent._FluxBorderRoundCorners=rounded
    local record=retained.item.record
    local key=record.key
    record.key=key=="Top" and "Bottom" or "Top"
    assert(not spatial.matchPose(pose,selected),"a shared geometry sample still validates registration metadata")
    record.key=key
    assert(spatial.matchPose(pose,selected),"restoring current flags and metadata recovers the pose")
    for _,pose in pairs(poses) do
        local n,descriptorVisits=0,0
        local fallbackPlans,noFallbackPlans=0,0
        for _,segment in ipairs(pose.segments) do assert(not segment.source,"no retained per-pass branch paint") end
        for _,material in pairs(pose.plan.materials) do
            assert(material.path and material.uv and not material.alpha and not material.color,"public material only")
        end
        for _,cell in pairs(pose.plan.cells) do
            local nextFallback=1
            local fallbacks=cell.fallbacks or {}
            for index,plan in ipairs(cell.plans) do
                assert(plan.source==pose.plan.materials[plan.item.texture],"cell uses the paint-free material record")
                assert(#(plan.fragmentUVs or {})==#plan.rects,"prepared normal fragments retain their texture coordinates")
                assert(#(plan.fallbackUVs or {})==#plan.fallbackRects,"prepared fallback fragments retain their texture coordinates")
                if #plan.fallbackRects>0 then
                    assert(fallbacks[nextFallback]==index,"keep the original draw order of nonempty fallbacks")
                    nextFallback=nextFallback+1
                    fallbackPlans=fallbackPlans+1
                else noFallbackPlans=noFallbackPlans+1 end
            end
            assert(nextFallback==#fallbacks+1,"no empty plan reaches fallback paint")
            for _,op in ipairs(cell.operations) do
                -- One ordered entry for each new source or blocker group.
                -- Repeat the uncached descriptor's order independently.
                local visits,seen=0,{}
                for _,fields in ipairs({op.triangles,op.fallbackTriangles}) do
                    for _,field in ipairs(fields) do
                        if not field.quadTail then
                            local gates=seen[field.texture]
                            local blockers=field.fallbackBlockers
                            if not gates or blockers and not gates[blockers] then
                                visits=visits+1
                                assert(op._preparedDrawInputs[visits]==field,"preserve descriptor order")
                            end
                            if not gates then gates={};seen[field.texture]=gates end
                            if blockers then gates[blockers]=true end
                        end
                    end
                end
                assert(#op._preparedDrawInputs==visits,"deduplicate prepared descriptor inputs")
                descriptorVisits=descriptorVisits+visits
                for _,fields in ipairs({op.triangles,op.fallbackTriangles}) do
                    for _,field in ipairs(fields) do
                        assert(field.source==pose.plan.materials[field.texture],"junction contains paint-free material only")
                        if field.drawUV then
                            local q=field.quad
                            local a,b,c,d
                            if q then a,b,c,d=q[1],q[2],q[3],q[4]
                            else a,b,c,d=field.a,field.b,field.c,field.c end
                            local expected={a[3],a[4],b[3],b[4],c[3],c[4],d[3],d[4]}
                            for i=1,8 do assert(field.drawUV[i]==expected[i],"prepared mesh uses exact vertex samples") end
                            n=n+1
                        end
                    end
                end
            end
        end
        assert(n>descriptorVisits and descriptorVisits>0,"warm pose avoids repeated descriptor geometry visits")
        assert(fallbackPlans>0 and noFallbackPlans>0,"warm pose exercises both fallback and empty plans")
        print(("STRIP_DRAW_INPUTS style=%d fields=%d inputs=%d"):format(style,n,descriptorVisits))
    end

    local current,previous,linked={},{},0
    for _,op in ipairs(m.e.spatial.operations()) do current[op]=true end
    local compiled=poses[false].plan
    for key,cell in pairs(compiled.cells) do
        for index,recipe in ipairs(cell.operations) do
            local actual=m.cells[key].active[index]
            local logical=compiled.operations[recipe._logicalIndex]
            assert(logical and not recipe._logicalOp and not recipe.sprite and not recipe.sprites,
                "prepared draw records retain an index and no native ownership")
            assert(actual~=recipe and actual.triangles==recipe.triangles and current[actual._logicalOp],
                "restore draws from shared mesh into a tile-owned operation with a current owner")
            assert(actual._logicalOp~=logical and actual._logicalOp.rect==logical.rect,
                "each active draw resolves the current logical operation")
            previous[key]=m.cells[key].active
            linked=linked+1
        end
    end
    assert(linked>0,"exercise prepared operation ownership on a warm crossing")

    -- Tint may change while the other pose is visible. The cached geometry
    -- must draw the latest color and source opacity with no rebuild.
    local function StripBounds()
        for _,segment in ipairs(spatial.raw()) do
            if segment.texture==m.sources[4][5] then return segment.rect end
        end
    end
    local priorBounds=assert(StripBounds())
    local priorBottom=priorBounds[2]
    for _,model in ipairs({m,reference}) do model.sources[4][5]:SetVertexColor(.9,.1,.45,.56) end
    Move(m,true,true)
    Move(reference,true,false)
    local movedBounds=assert(StripBounds())
    assert(movedBounds~=priorBounds and movedBounds[2]~=priorBottom and priorBounds[2]==priorBottom,
        "moving the source creates fresh public bounds without changing the previous pose")
    fixture.compare(m,reference,points,1)
    assert(work.plan==2 and m.j.stats.stripPlanHits==5)
    local reused=0
    for key in pairs(poses[true].plan.cells) do
        local cell=m.cells[key]
        if cell and cell.enabled and previous[key]==cell.active and #cell.active>0 then reused=reused+1 end
    end
    assert(reused>0,"prepared crossings reuse the draw records of tiles that stay active")

    -- A new material mapping (even without a paint notification), and a
    -- raised participant's live level, must discard the saved plan.
    for _,model in ipairs({m,reference}) do model.sources[4][5].uv={.02,.81,.01,.072} end
    Move(m,false,true)
    Move(reference,false,false)
    fixture.compare(m,reference,points,1)
    assert(work.plan==3 and m.j.stats.stripPlanHits==5,"fresh UV rejects the old prepared fields")
    for _,model in ipairs({m,reference}) do model.parents[1]:SetFrameLevel(29) end
    Move(m,true,true)
    Move(reference,true,false)
    fixture.compare(m,reference,points,1)
    assert(work.plan==4 and m.j.stats.stripPlanHits==5,"live level/material refresh takes the normal planner")

    -- A different adjacent panel pose must refresh only the affected region.
    for _,model in ipairs({m,reference}) do
        for _,t in ipairs(model.sources[8]) do t.rect[1]=t.rect[1]+13;model.j:Invalidate(nil,t) end
    end
    local oldSolves=work.solve
    Move(m,false,true)
    Move(reference,false,false)
    fixture.compare(m,reference,points,1)
    assert(work.solve==oldSolves+1,"neighbor movement rejects the old topology")

    local before=work.solve
    m.lock(true)
    Move(m,true,true)
    assert(work.solve==before,"lockdown leaves the currently committed geometry alone")
    m.lock(false)
    m.j:CommitLayout(true)
    Move(reference,true,false)
    fixture.compare(m,reference,points,1)
    m.j:ReleaseAll()
    assert(not m.e.spatial.poses(),"renderer retirement releases both prepared poses")
    ReplayRegistrations(style)
end
local baseline=arg[1] and Fixtures(arg[1])
for _,style in ipairs({1,2}) do
    local plan,solve,hits=ReplayDifferentFootprints(fixture,style,true)
    print(("STRIP_PLAN_COVERAGE|candidate|%d|%d|%d|%d"):format(style,plan,solve,hits))
    if baseline then
        local oldPlan,oldSolve,oldHits=ReplayDifferentFootprints(baseline,style,false)
        print(("STRIP_PLAN_COVERAGE|baseline|%d|%d|%d|%d"):format(style,oldPlan,oldSolve,oldHits))
    end
end

local function ReplayRecentWidths(style,oldRenderer)
    local groups=scene(style)
    groups[10]=fixture.box(-403,-85,123,85,"noncombat",nil,5)
    local m,oracle=fixture.model(groups,style,1),fixture.model(groups,style,1)
    local archived=oldRenderer and oldRenderer.model(groups,style,1)
    local work=CountBuilds(m)
    local oldWork=archived and CountBuilds(archived)
    local widths={6,11,15,19}
    local width=0
    local function Resize(model,delta,cached)
        for _,index in ipairs({2,4,5,6,8}) do
            local texture=model.sources[4][index]
            local axis=(index==5 or index==6) and 3 or 1
            texture.rect[axis]=texture.rect[axis]+delta
            model.j:Invalidate(nil,texture)
        end
        for _,index in ipairs({7,8,9,10}) do
            for _,texture in ipairs(model.sources[index]) do
                texture.rect[1]=texture.rect[1]+(index<=8 and delta or -delta)
                model.j:Invalidate(nil,texture)
            end
        end
        if cached then model.j:CommitLayout(false) else model.j:CommitLayout() end
    end
    local elapsed={candidate=0,baseline=0}
    local function Step(nextWidth)
        local delta=nextWidth-width
        width=nextWidth
        local start=os.clock()
        Resize(m,delta,true)
        elapsed.candidate=elapsed.candidate+os.clock()-start
        Resize(oracle,delta,false)
        local samples={{-280-width,-40},{-180-width,-40},{0,0},{320,0},{326,0},{920+width,0},{1040+width,-85}}
        fixture.compare(m,oracle,samples,1)
        assert(m.j.stats.localMode and not m.j.stats.fallback,"new and recalled widths stay regional")
        if archived then
            start=os.clock()
            Resize(archived,delta,true)
            elapsed.baseline=elapsed.baseline+os.clock()-start
            fixture.compare(archived,oracle,samples,1)
        end
    end
    for _=1,3 do for _,nextWidth in ipairs(widths) do Step(nextWidth) end end
    assert(work.solve==4 and work.plan==4 and m.j.stats.stripPlanHits==8,"four warmed widths reuse their exact plans")
    local count,segments,operations,fields=0,0,0,0
    local pose=m.e.spatial.poses()[false]
    while pose do
        count=count+1
        assert(count<=4 and pose.plan)
        segments=segments+#pose.segments
        operations=operations+#pose.operations
        fields=fields+pose.plan.total
        pose=pose.alternate
    end
    assert(count==4 and segments<=2048 and operations<=768 and fields<=8192)
    local function Budget(strip,planFields)
        local third={segments={},operations={},plan={total=planFields}}
        local second={segments={},operations={},plan={total=planFields},alternate=third}
        local head={segments={},operations={},plan={total=planFields}}
        m.e.spatial.remember(head,second,nil,strip)
        assert(head.alternate==second and not second.alternate,"large plans keep the bounded two-plan window")
    end
    Budget(true,4096)
    Budget(false,2048)
    print(("STRIP_RECENT_LAYOUTS|candidate|%d|%d|%d|%d|%d|%.6f"):format(
        style,work.solve,work.plan,m.j.stats.stripPlanHits,fields,elapsed.candidate))
    if archived then
        assert(oldWork.solve==12 and oldWork.plan==12)
        print(("STRIP_RECENT_LAYOUTS|baseline|%d|%d|%d|%d|%d|%.6f"):format(
            style,oldWork.solve,oldWork.plan,archived.j.stats.stripPlanHits or 0,0,elapsed.baseline))
    end
end
for _,style in ipairs({1,2}) do
    ReplayRecentWidths(style,arg[2]=="--recent-layouts" and baseline or nil)
end
print("Strip pose replay: warm cache, active tint, changed materials, neighbor geometry, changing footprints and lockdown pass.")
