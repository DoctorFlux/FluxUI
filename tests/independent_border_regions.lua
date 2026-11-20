-- Compare the same authored party borders and HUD in both regional layouts.
-- An optional argument is the archived core before isolated paint regions.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local source=file:read("*a"):gsub("\r\n","\n")
    file:close()
    return source
end

local fixture=Read("tests/border_locality.lua")
fixture=fixture:sub(1,assert(fixture:find("if arg[1]=='--work' then",1,true))-1)
fixture=fixture:gsub("local corePath='Core/BorderJunctions.lua'","local corePath=...",1)
fixture=fixture:gsub("local parent=new%(e.UIParent,","local parent=new(parents[g.parent] or e.UIParent,",1)
fixture=fixture:gsub("parents%[i%]=parent;",[[
  parents[i]=parent
  parent._FluxBorderIndependent=g.independent
  if g.name=="strip" then e.FluxActionStrip=parent end;
]],1)
local factory=assert(load(fixture.."\nreturn {model=model,box=box,compare=compare}",
    "@independent-border-region-fixture","t",_G))

local function Scene(f,style,scale)
    local box=f.box
    local groups={
        box(0,-85,640,85,"strip",nil,20),
        box(-82,-85,82,85,"combat",nil,20),
        box(-193,-85,111,85,"info",nil,20),
        box(640,-85,95,85,"noncombat",nil,20),
        box(735,-85,68,85,"trinket",nil,20),
    }
    for i=1,4 do
        local x=24+132*(i-1)
        local unit="party"..i
        local frame=box(x,17,108,64,"member",unit,27)
        frame.independent=true
        groups[#groups+1]=frame
        groups[#groups+1]={name="bar divider",parent=#groups,level=28,
            parts={{"Top",{x-3,38,112,17}}}}
    end
    return f.model(groups,style,scale)
end

local function Move(m,step,kind)
    local direction=step%2==1 and 1 or -1
    local indices=kind=="hover" and {1,2,3,4,5} or {6,7}
    for _,i in ipairs(indices) do
        for _,texture in ipairs(m.sources[i]) do
            local axis=i==1 and 2 or 1
            texture.rect[axis]=texture.rect[axis]+direction*8
            m.j:Invalidate(nil,texture)
        end
    end
    local pose
    if kind=="hover" then pose=step%2==1 end
    m.j:CommitLayout(pose)
end

local core="Core/BorderJunctions.lua"
local prior=arg[1]
local current=factory(core)
local reference=factory(prior or core)
local points={{-83,0},{0,0},{640,-1},{737,-1},{23,81},{24,48},{34,48},{134,47},{156,48},{288,48}}
local function Regions(m,scope)
    local kept={}
    for key,cell in pairs(m.cells) do
        if cell.enabled and (key:sub(1,6)=="scope:")==scope then kept[key]={cell,cell.epoch} end
    end
    return kept
end
local function CheckRetained(m,kept)
    for key,previous in pairs(kept) do
        assert(m.cells[key]==previous[1] and m.cells[key].epoch==previous[2],
            "move preserves native paint in unaffected regions")
    end
end

local function Measure(m)
    local totals={cells=0,segments=0,meshes=0}
    local plan=m.j._PreparePlan
    function m.j:_PreparePlan(segments,operations,cost,signature,meshes)
        totals.segments=totals.segments+#segments
        totals.meshes=totals.meshes+#meshes
        return plan(self,segments,operations,cost,signature,meshes)
    end
    return totals
end

for _,style in ipairs({1,2}) do
    for _,scale in ipairs({.75,1,1.25}) do
        for _,kind in ipairs({"hover","group"}) do
            local old,new=Scene(reference,style,scale),Scene(current,style,scale)
            local a,b=Measure(old),Measure(new)
            local retained=Regions(new,kind=="hover")
            if kind=="hover" then
                local count=0
                for _ in pairs(retained) do count=count+1 end
                assert(count==4,"each party member and its divider share one output region")
            else
                assert(next(retained),"the shared HUD occupies its own tiles")
            end
            for step=1,4 do
                Move(old,step,kind)
                Move(new,step,kind)
                a.cells=a.cells+old.j.stats.localUpdated
                b.cells=b.cells+new.j.stats.localUpdated
                assert(new.j.stats.localMode and not new.j.stats.fallback)
                CheckRetained(new,retained)
                current.compare(new,old,points,scale)
            end
            if kind=="group" then
                assert(b.cells==4,"each member movement replaces exactly its own output region")
            end
            if prior then
                assert(b.segments<a.segments,"exclude unrelated source geometry from planning")
                if kind=="group" then
                    assert(b.cells<a.cells and b.meshes<a.meshes,"keep the HUD's active fields during roster movement")
                end
            end
            local prepared=Regions(new,true)
            for _,m in ipairs({old,new}) do
                m.parents[6]:Hide()
                m.j:CommitLayout()
            end
            CheckRetained(new,prepared)
            current.compare(new,old,points,scale)
            for _,m in ipairs({old,new}) do
                m.parents[6]:Show()
                m.j:CommitLayout()
                m.sources[7][1]:Hide()
                m.sources[8][7]:SetVertexColor(.15,.33,.8,.52)
            end
            CheckRetained(new,prepared)
            current.compare(new,old,points,scale)
            print(("SCOPE style=%d scale=%.2f kind=%s regions=%d/%d segments=%d/%d meshes=%d/%d")
                :format(style,scale,kind,a.cells,b.cells,a.segments,b.segments,a.meshes,b.meshes))
        end
    end
end
print("Independent border regions retain HUD and party paint, sampled output and live color/visibility.")
