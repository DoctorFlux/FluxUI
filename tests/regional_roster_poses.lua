-- Execute the actual compiler and regional renderer with two recurring group
-- layouts. The optional archived core supplies a matched planning baseline.
local file=assert(io.open("tests/regional_layout_index.lua","rb"))
local text=file:read("*a"):gsub("\r\n","\n")
file:close()
text=text:sub(1,assert(text:find('local core="Core/BorderJunctions.lua"',1,true))-1)
text=text:gsub("local prior=arg%[1%]",[[
fixture=fixture:gsub("cells=Spatial.cells,inspect=",
    "cells=Spatial.cells,rosterPose=function()return Spatial.rosterPose end,inspect=",1)
local prior=arg[1]
]],1)
local Renderer,Scene,Change=assert(load(text.."\nreturn Renderer,Scene,Change","@roster-pose-fixture","t",_G))()
local core="Core/BorderJunctions.lua"
local prior=arg[2]~="--recent-layouts" and arg[1]
local points={{130,380},{147,380},{245,380},{262,380},{360,380},{0,0}}

local function Build(path,style,party)
    local renderer=Renderer(path)
    if party then
        local model=renderer.model
        renderer.model=function(groups,...)
            for i=10,13 do groups[i].unit="party"..(i-9) end
            return model(groups,...)
        end
    end
    local m=Scene(renderer,style)
    local work={plans=0}
    local plan=m.j._PreparePlan
    function m.j:_PreparePlan(...)
        work.plans=work.plans+1
        return plan(self,...)
    end
    return m,work,renderer.compare
end

local function ReplayRegistrations(style,party)
    local m,work=Build(core,style,party)
    Change(m,"roster",1)
    Change(m,"roster",2)
    local pose=assert(m.e.spatial.rosterPose())
    local parent=m.new(m.e.UIParent,{3800,900,140,80})
    parent._FluxBorderStatic=true
    local texture,record=m.piece(parent,"Top",{3820,980,100,17})
    local seed=m.sources[10][5]
    local path=seed:GetTexture()
    record.art,record.artHandle=path,path
    texture:SetTexture(path)
    texture:SetTexCoord(seed:GetTexCoord())
    Change(m,"roster",3)
    assert(m.e.spatial.rosterPose()==pose and pose.alternate,"unrelated adoption keeps both roster layouts")
    local plans=work.plans
    Change(m,"roster",4)
    Change(m,"roster",5)
    assert(work.plans==plans,"no extra roster compilation after unrelated adoption")

    pose=m.e.spatial.rosterPose()
    m.j:Forget(texture)
    texture:Hide()
    Change(m,"roster",6)
    assert(m.e.spatial.rosterPose()==pose and pose.alternate,"unrelated retirement keeps both roster layouts")
    plans=work.plans
    Change(m,"roster",7)
    Change(m,"roster",8)
    assert(work.plans==plans,"no extra roster compilation after unrelated retirement")
    print(("ROSTER_REGISTRATION style=%d mode=%s warmCompiles=0+0"):format(style,party and "party" or "raid"))
end

for _,style in ipairs({1,2}) do
    for _,mode in ipairs({"party","raid"}) do
        local old,x=Build(prior or core,style,mode=="party")
        local new,y,compare=Build(core,style,mode=="party")
        local startOld,startNew=old.j.stats.solves,new.j.stats.solves
        for step=1,8 do
            Change(old,"roster",step)
            Change(new,"roster",step)
            compare(new,old,points,1)
            assert(new.j.stats.localMode and not new.j.stats.fallback)
            assert(y.plans==math.min(step,2),"prepare both actual roster layouts once")
        end
        local a,b=old.j.stats.solves-startOld,new.j.stats.solves-startNew
        assert(b==2 and (not prior or a==8 and x.plans==8))
        print(("ROSTER_POSE style=%d mode=%s solves=%d/%d plans=%d/%d")
            :format(style,mode,a,b,x.plans,y.plans))

        local pose=assert(new.e.spatial.rosterPose())
        assert(pose.plan and pose.alternate and pose.alternate.plan and not pose.alternate.alternate)
        for _,current in ipairs({pose,pose.alternate}) do
            assert(#current.segments<=256 and #current.operations<=128 and current.plan.total<=2048)
            for _,material in pairs(current.plan.materials) do
                assert(material.path and material.uv and not material.alpha and not material.color)
            end
        end

        -- A paint-only mutation still reaches the current drawing and the
        -- restored layout without changing either stored geometry.
        old.sources[10][5]:SetVertexColor(.25,.4,.85,.6)
        new.sources[10][5]:SetVertexColor(.25,.4,.85,.6)
        Change(old,"roster",9)
        Change(new,"roster",9)
        compare(new,old,points,1)
        assert(y.plans==2)

        -- Change native UV without an addon paint notification to exercise
        -- the material contract of the prepared display itself.
        old.sources[10][5].uv={.02,.8,.01,.068}
        new.sources[10][5].uv={.02,.8,.01,.068}
        Change(old,"roster",10)
        Change(new,"roster",10)
        compare(new,old,points,1)
        assert(y.plans==3,"fresh UV rejects the old prepared paint plan")

        local before=new.j.stats.solves
        for _,m in ipairs({old,new}) do
            for _,t in ipairs(m.sources[11]) do
                t.rect[1]=t.rect[1]+29
                m.j:Invalidate(nil,t)
            end
            m.j:CommitLayout()
        end
        assert(new.j.stats.solves==before+1,"unseen positions solve locally")
        compare(new,old,points,1)

        -- Game state can defer the commit without consuming the saved layout.
        local cached=new.e.spatial.rosterPose()
        local plans=y.plans
        new.lock(true)
        Change(new,"roster",11)
        assert(y.plans==plans and new.e.spatial.rosterPose()==cached)
        new.lock(false)
        new.j:CommitLayout()
        Change(old,"roster",11)
        compare(new,old,points,1)
        new.j:ReleaseAll()
        assert(not new.e.spatial.rosterPose(),"global retirement drops the prepared roster layouts")
        ReplayRegistrations(style,mode=="party")
    end
end

local function ReplayRecentLayouts(style,party)
    local new,work,compare=Build(core,style,party)
    local old,oldWork=Build(arg[2]=="--recent-layouts" and arg[1] or core,style,party)
    local previous=0
    local function Apply(model,offset,visible)
        for i=10,13 do
            local parent=model.parents[i]
            if i<=visible then parent:Show() else parent:Hide() end
            model.j:Invalidate(nil,parent)
            for _,texture in ipairs(model.sources[i]) do
                texture.rect[1]=texture.rect[1]+offset
                model.j:Invalidate(nil,texture)
            end
        end
        model.j:CommitLayout()
    end
    for _=1,3 do
        for _,state in ipairs({{8,0},{16,11},{24,13}}) do
            local offset=state[1]-previous
            previous=state[1]
            Apply(old,offset,state[2])
            Apply(new,offset,state[2])
            compare(new,old,points,1)
            assert(new.j.stats.localMode and not new.j.stats.fallback)
        end
    end
    assert(work.plans==3,"three recurring roster layouts are prepared once each")
    local count,fields=0,0
    local pose=new.e.spatial.rosterPose()
    while pose do
        count=count+1;assert(count<=3 and pose.plan)
        fields=fields+pose.plan.total
        pose=pose.alternate
    end
    assert(count==3 and fields<=4096)
    local mode=party and "party" or "raid"
    if arg[2]=="--recent-layouts" then
        assert(oldWork.plans==9,"the archived two-plan roster layout misses the next state")
        print(("ROSTER_RECENT_LAYOUTS|baseline|%d|%s|%d|0"):format(style,mode,oldWork.plans))
    end
    print(("ROSTER_RECENT_LAYOUTS|candidate|%d|%s|%d|%d"):format(style,mode,work.plans,fields))
end
for _,style in ipairs({1,2}) do
    ReplayRecentLayouts(style,true)
    ReplayRecentLayouts(style,false)
end
print("Roster pose replay preserves sampled joins, live paint, material validation and combat deferral.")
