-- Actual pickup/place callbacks and layout plus the regional renderer.
-- Pass the before directory to compare archived Lua with the current code.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local value=file:read("*a")
    file:close()
    return (value:gsub("\r\n","\n"))
end
local function Part(source, first, last)
    local start=assert(source:find(first,1,true),first)
    return source:sub(start,assert(source:find(last,start+#first,true),last)-1)
end
local prior=arg[1]
local paths={"Bars/Layout.lua","Bars/Strip.lua","Bars/Init.lua","Bars/Hosts.lua"}
local function Fixture(baseline)
    local source=Read("tests/bars_strip_layout_work.lua")
    source=source:sub(1,assert(source:find("local candidate=true;local checks=0",1,true))-1)
    local env=setmetatable({arg={}},{__index=_G})
    if baseline and prior then
        env.io={open=function(path,...)
            for _,file in ipairs(paths) do
                if path:gsub("\\","/"):sub(-#file)==file then path=prior.."/"..file:gsub("/","-");break end
            end
            return io.open(path,...)
        end}
    end
    local model=assert(load(source.."\nreturn fixture","@rapid-strip-fixture","t",env))()(true)
    local bars,e=model.B,model.env
    local native={}
    local hostSource=Read(baseline and prior and prior.."/Bars-Hosts.lua" or "Bars/Hosts.lua")
    local drag=Part(hostSource,"local function CurrentSlot(widget)","\nlocal hoverWidget")
        ..Part(hostSource,"local function AfterCursorChange(","\n\t-- ButtonForge guard")
    local widget={SetScript=function(_,name,fn) native[name]=fn end}
    assert(load("local Bars,Hosts,Flux,widget=...\n"..drag,"@actual-strip-pickup-place","t",e))(bars,bars.Hosts,model.flux,widget)
    local counts={paints=0,quiet=0,pickups=0,places=0,sweeps=0,writes=0}
    local flush=bars.Paint.Flush
    bars.Paint.Flush=function(tokens) if tokens==nil then counts.paints=counts.paints+1 end;return flush(tokens) end
    bars.Blizzard.QuietGrid=function()counts.quiet=counts.quiet+1 end
    e.PickupAction=function(slot)
        counts.pickups=counts.pickups+1
        model.occupied[slot]=nil
        model.cursor=model.pickupType
        model.emit("ACTIONBAR_SLOT_CHANGED",slot)
        model.emit("CURSOR_CHANGED")
    end
    e.PlaceAction=function(slot)
        counts.places=counts.places+1
        model.occupied[slot]=999
        model.emit("ACTIONBAR_SLOT_CHANGED",slot)
        model.emit("CURSOR_CHANGED")
    end
    local notified
    e.FluxBinding={NotifyOccupancyChanged=function(slots) notified=slots[1] end}
    local function Drag(handler,slot,kind)
        model.pickupType=kind
        native[handler](bars.hosts[slot].main.widget)
        assert(notified==slot,"the edited native slot reaches Binding from the drag handler")
        model.drain()
        counts.writes=counts.writes+(model.counts().mappingWrites or 0)
        counts.sweeps=counts.sweeps+(model.counts().stockSweep or 0)
        model.reset()
    end
    return model,counts,Drag,native
end
do
    local old,a,dragOld=Fixture(true)
    local new,b,dragNew,native=Fixture(false)
    for _,model in ipairs({old,new}) do
        model.hover=true;model.cursor="spell";model.emit("CURSOR_CHANGED");model.drain();model.reset()
    end
    a.paints,b.paints=0,0
    for i,kind in ipairs({"spell","item","macro","spell","item","macro"}) do
        dragOld("OnDragStart",i,kind);dragNew("OnDragStart",i,kind)
        assert(old.signature()==new.signature(),"pickup preserves matching layouts and secure flags")
        dragOld("OnReceiveDrag",i,kind);dragNew("OnReceiveDrag",i,kind)
        assert(old.signature()==new.signature(),"drop preserves matching layouts and secure flags")
    end
    assert(b.pickups==6 and b.places==6 and b.writes==108 and b.sweeps==0 and b.paints==0)
    if prior then assert(a.writes==2052 and a.sweeps==12 and a.paints==12) end
    print(("RAPID_STRIP actions=12 mappingWrites=%d/%d fullStock=%d/%d fullPaint=%d/%d")
        :format(a.writes,b.writes,a.sweeps,b.sweeps,a.paints,b.paints))
    -- Force a second column to share the currently edited slot on a live page.
    for _,state in ipairs({{old,a,dragOld},{new,b,dragNew}}) do
        local model,counts,drag=state[1],state[2],state[3]
        model.B.hosts[14].sec.slot=1
        counts.writes=0
        drag("OnReceiveDrag",1,"item")
    end
    assert(old.signature()==new.signature() and b.writes==18,"each live user of a shared slot keeps secure state")
    -- The actual transition keeps its repaint and the grid event suppresses
    -- stock buttons through the existing quiet path.
    new.hover=false;new.cursor=nil;new.emit("ACTIONBAR_HIDEGRID");new.drain()
    assert(b.quiet==1 and b.paints==1 and not new.counts().stockSweep and new.counts().commit==1)
    local before=b.places
    new.combat=true
    native.OnReceiveDrag(new.B.hosts[1].main.widget)
    assert(b.places==before,"combat never reaches the protected drop")
end

local code=Read("tests/border_locality.lua")
code=code:sub(1,assert(code:find("if arg[1]=='--work' then",1,true))-1)
code=code:gsub("local corePath='Core/BorderJunctions.lua'","local corePath=...",1)
code=code:gsub("parents%[i%]=parent;","parents[i]=parent;if g.name=='strip' then e.FluxActionStrip=parent end;",1)
code=code:gsub("cells=Spatial.cells,inspect=","cells=Spatial.cells,poses=function()return Spatial.stripPoses end,inspect=",1)
local factory=assert(load(code.."\nreturn {model=model,scenes=scenes,box=box,compare=compare}","@rapid-border-fixture","t",_G))
local actual=factory("Core/BorderJunctions.lua")
local reference=factory(prior and prior.."/Core-BorderJunctions.lua" or "Core/BorderJunctions.lua")
local function Border(fixture,style)
    local groups=fixture.scenes(style)[3].groups
    groups[#groups+1]=fixture.box(920,-85,120,85,"combat",nil,5)
    groups[#groups+1]=fixture.box(1040,-85,70,85,"trinket",nil,5)
    groups[#groups+1]=fixture.box(-280,-85,100,85,"info",nil,5)
    local model=fixture.model(groups,style,1)
    local solve,plan=model.j.Solve,model.j._PreparePlan
    local work={solve=0,plan=0,width=0}
    model.j.Solve=function(self,...)
        work.solve=work.solve+1
        return solve(self,...)
    end
    model.j._PreparePlan=function(self,...)
        work.plan=work.plan+1
        return plan(self,...)
    end
    return model,work
end
local function Resize(model,work,width,reuse)
    local dx=width-work.width
    work.width=width
    for _,i in ipairs({2,4,5,6,8}) do
        local t=model.sources[4][i]
        local axis=(i==5 or i==6) and 3 or 1
        t.rect[axis]=t.rect[axis]+dx
        model.j:Invalidate(nil,t)
    end
    for _,peer in ipairs({7,8}) do
        for _,t in ipairs(model.sources[peer]) do t.rect[1]=t.rect[1]+dx;model.j:Invalidate(nil,t) end
    end
    if reuse then model.j:CommitLayout(false) else model.j:CommitLayout() end
end
for _,style in ipairs({1,2}) do
    local old,a=Border(reference,style)
    local new,b=Border(actual,style)
    for i=1,8 do
        local width=i%2==1 and 6 or 11
        Resize(old,a,width,false);Resize(new,b,width,true)
        actual.compare(new,old,{{-180,-85},{0,0},{320,0},{326,0},{920+width,0},{1040+width,-85}},1)
    end
    assert(a.solve==8 and a.plan==8 and b.solve==2 and b.plan==2)
    assert(new.j.stats.stripPlanHits==6)
    print(("RAPID_BORDER style=%d changes=8 solve=%d/%d plan=%d/%d prepared=%d")
        :format(style,a.solve,b.solve,a.plan,b.plan,new.j.stats.stripPlanHits))
    for _,width in ipairs({15,19,23}) do Resize(new,b,width,true) end
    local latest=new.e.spatial.poses()[false]
    local count=0
    while latest do count=count+1;latest=latest.alternate end
    assert(count==4,"keep four small neighboring layouts per hover state")
    Resize(new,b,11,true)
    assert(b.solve==5,"the least-recently used retained layout still matches")
    Resize(new,b,6,true)
    assert(b.solve==6,"an evicted layout recomputes")
    new.j:ReleaseAll()
    assert(not new.e.spatial.poses(),"release clears both shapes")
end
print("Rapid strip replay passes slots, shared mappings, grid transition, lockdown, prepared side joins and bounded reuse.")
