-- Match the renderer before and after local material collection on the same
-- populated HUD. Count modeled original texture reads during each reflow.
local file=assert(io.open("tests/regional_layout_index.lua","rb"))
local text=file:read("*a"):gsub("\r\n","\n")
file:close()
text=text:sub(1,assert(text:find('local core="Core/BorderJunctions.lua"',1,true))-1)
local Renderer,Scene,Change=assert(load(text.."\nreturn Renderer,Scene,Change","@regional-material-fixture","t",_G))()
local prior=arg[1]
local core="Core/BorderJunctions.lua"

local function CountMaterials(model)
    local native=getmetatable(model.e.UIParent).__index
    local getMasks=native.GetNumMaskTextures
    local work={reads=0,sources={}}
    function native:GetNumMaskTextures()
        work.reads=work.reads+1
        work.sources[self]=(work.sources[self] or 0)+1
        return getMasks(self)
    end
    return work
end

local function Replay(a,b,style,trigger)
    local old,new=Scene(a,style),Scene(b,style)
    local x,y=CountMaterials(old),CountMaterials(new)
    local oldCold,newCold,oldWarm,newWarm=0,0,0,0
    local points=trigger=="hover" and {{0,0},{326,0},{920,0},{1040,-85},{-180,-85}}
        or {{130,380},{147,380},{245,380},{262,380},{360,380}}
    for step=1,6 do
        x.reads,y.reads=0,0
        Change(old,trigger,step)
        Change(new,trigger,step)
        b.compare(new,old,points,1)
        assert(new.j.stats.localMode and old.j.stats.localMode)
        assert(new.j.stats.solves==old.j.stats.solves)
        if step<=2 then
            oldCold,newCold=oldCold+x.reads,newCold+y.reads
        else
            oldWarm,newWarm=oldWarm+x.reads,newWarm+y.reads
        end
    end
    if trigger=="hover" then
        assert(new.j.stats.stripPlanHits==4 and old.j.stats.stripPlanHits==4,
            "four normal paints from the two prepared poses")
    end
    if prior then
        assert(newCold<oldCold and newWarm<oldWarm,"fewer material reads across actual border commits")
    end
    print(("TILE_MATERIALS style=%d trigger=%s initial=%d/%d repeat=%d/%d")
        :format(style,trigger,oldCold,newCold,oldWarm,newWarm))
    return old,new,x,y
end

for _,style in ipairs({1,2}) do
    local a,b=Renderer(prior or core),Renderer(core)
    local old,new,x,y=Replay(a,b,style,"hover")
    Replay(a,b,style,"roster")

    if prior then
        local clipped=new.e.spatial.inspect()
        local cap
        for _,index in ipairs({3,4,7,8,9}) do
            for corner=1,4 do
                local saved,current=old.sources[index][corner],new.sources[index][corner]
                local entry=clipped[current]
                if x.sources[saved] and not y.sources[current] and not (entry and entry.active) then
                    cap=current
                    break
                end
            end
            if cap then break end
        end
        assert(cap,"exercise a native cap sampled by the old whole-neighbour validation")
        cap.maskCountOverride=1
        Change(new,"hover",7)
        assert(new.j.stats.localMode and new.j.stats.stripPlanHits==5 and cap:IsShown(),
            "an unused cap stays native and does not invalidate the prepared join")
        cap.maskCountOverride=nil
        Change(new,"hover",8)
    end

    -- A true branch source is still required. The masked source must fall
    -- through the existing safe path before any regional sprite commit.
    local active=new.sources[4][5]
    local previous=old.sources[4][5]
    local hits=new.j.stats.stripPlanHits
    active.maskCountOverride=1
    previous.maskCountOverride=1
    Change(new,"hover",9)
    Change(old,"hover",9)
    assert(not new.j.stats.localMode and new.j.stats.stripPlanHits==hits,
        "unavailable participating art invalidates prepared paint and selects the safe fallback")
    assert(active:GetAlpha()>0,"unavailable branch keeps its native source")
    active.maskCountOverride=nil
    previous.maskCountOverride=nil
    Change(new,"hover",10)
    Change(old,"hover",10)
    assert(new.j.stats.localMode and active:GetAlpha()==0,"regional paint recovers when the source is available")
    b.compare(new,old,{{0,0},{326,0},{920,0}},1)
end
print("Regional material collection preserves sampled joins and validates actual paint dependencies.")
