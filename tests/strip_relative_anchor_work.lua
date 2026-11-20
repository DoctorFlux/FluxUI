-- Compare the actual cursor layout and envelope code with a dated checkpoint.
-- The modeled slices share the existing host and panel fixtures.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local source=file:read("*a")
    file:close()
    return (source:gsub("\r\n","\n"))
end
local prior=arg[1]
local function Fixture(path, endMarker, sourceTransform, args)
    local source=Read(path)
    source=source:sub(1,assert(source:find(endMarker,1,true))-1)
    if sourceTransform then source=sourceTransform(source) end
    local env=setmetatable({arg=args or {}},{__index=_G})
    return assert(load(source.."\nreturn fixture","@"..path,"t",env))()
end
local paths=prior and {prior.."/Bars-Layout.lua",prior.."/Bars-Strip.lua"} or {}
local layout=Fixture("tests/bars_strip_layout_work.lua","local candidate=true;local checks=0",nil,paths)

local function PrepareFaces(candidate,bottom,dense)
    local f=layout(candidate)
    f.bottom=bottom
    if dense then for slot=15,19 do f.occupied[slot]=100+slot end end
    -- Single, double, and promoted minis beside empty faces.
    f.occupied[38],f.occupied[66],f.occupied[41],f.occupied[53]=138,166,141,153
    f.B.Layout.Request("slot")
    f.drain()
    local writes=0
    f.B.ForEachHost(function(host)
        local frame=host.widget
        for _,name in ipairs({"SetPoint","ClearAllPoints"}) do
            local call=frame[name]
            frame[name]=function(self,...)writes=writes+1;return call(self,...)end
        end
    end)
    f.cursor="spell"
    return f,function()return writes end
end
local function Cross(f,entering)
    f.hover=entering
    f.B.Layout.OnDragHover()
    f.drain()
end
for _,bottom in ipairs({false,true}) do for _,dense in ipairs({false,true}) do
    local old,a=PrepareFaces(not prior,bottom,dense)
    local new,b=PrepareFaces(true,bottom,dense)
    for i=1,6 do
        Cross(old,i%2==1)
        Cross(new,i%2==1)
        assert(old.signature()==new.signature(),"same faces, secure slot mapping and final points")
    end
    if prior then assert(b()<a(),"relative placement avoids duplicate native writes") end
    print(("STRIP_POINTS bottom=%s dense=%s crossings=6 writes=%d/%d"):format(tostring(bottom),tostring(dense),a(),b()))

    -- Geometry may have been moved by another layout owner. Only exact
    -- current public points are eligible for reuse.
    local widget=new.B.hosts[1].main.widget
    local count=widget.GetNumPoints
    local point=widget.GetPoint
    widget:ClearAllPoints()
    widget:SetPoint("CENTER",new.env.UIParent,"CENTER",13,15)
    Cross(new,true)
    Cross(old,true)
    assert(old.signature()==new.signature(),"external point drift repaired on enter")
    widget.GetNumPoints=function()error("denied test getter")end
    Cross(new,false)
    Cross(old,false)
    widget.GetNumPoints=count
    assert(old.signature()==new.signature(),"denied getter retains native placement")
    local secret=setmetatable({}, {__eq=function()error("private point compared")end})
    new.env.issecretvalue=function(v)return rawequal(v,secret)end
    widget.GetPoint=function()return secret,secret,secret,secret,secret end
    Cross(new,true)
    Cross(old,true)
    widget.GetPoint=point
    assert(old.signature()==new.signature(),"private geometry keeps the ordinary write")
end end

local panels=Fixture("tests/strip_panel_settle.lua","local checkpoint = arg[1]",function(source)
    -- Both R95 and current code already contain the gap match helper.
    source=source:gsub('local firstGap = before and "local function UpdateGapBackdrop%(%)" or',
        "local firstGap =",1)
    return (source:gsub("s.trinket, s.trinketGap = trinket, trinketGap",
        "s.trinket, s.trinketGap, s.noncombat = trinket, trinketGap, noncombat",1))
end)
local function Points(frame)
    local out={}
    for _,p in ipairs(frame.points) do
        out[#out+1]=table.concat({p[1],p[2].name,p[3],p[4],p[5]},":")
    end
    return table.concat(out,",")
end
for _,placement in ipairs({"actionStrip","screenTopLeft","minimapTop","statusIntegrated"}) do
    local old,new=panels(placement,prior),panels(placement)
    local a,b=0,0
    for i=1,8 do
        local left=i%2==1 and 37 or 21
        old.noncombat.left,new.noncombat.left=left,left
        local grid=i%2==1 and 342 or 304
        local before,after=old:cross(grid),new:cross(grid)
        a,b=a+(before.EnvelopePoint or 0),b+(after.EnvelopePoint or 0)
        assert(Points(old.envelope)==Points(new.envelope) and new.envelope.points[1][2]:GetLeft()==left)
        assert(Points(old.gap)==Points(new.gap) and Points(old.trinketGap)==Points(new.trinketGap))
        assert(old.gap.shown==new.gap.shown and old.info.shown==new.info.shown)
    end
    assert(b==0,"geometry follows the same attached frames without rewriting points")
    if prior then assert(a==32,"existing envelope rebound on every movement") end
    print(("ENVELOPE_POINTS placement=%s crossings=8 writes=%d/%d"):format(placement,a,b))

    new.envelope.points[1][4]=7
    assert(new:cross(304).EnvelopePoint==4 and new.envelope.points[1][4]==0,
        "changed offset repaired even with a matching layout hash")
    assert(new:replaceRight().EnvelopePoint==4 and new.envelope.points[2][2].name=="Replacement",
        "a peer replacement at the same coordinates must bind")
    new.locked=true
    assert(not new:cross(342).EnvelopePoint,"combat guard precedes point reads and writes")
end
print("Relative anchor replay passes face mapping, mini promotion and parking, panel ownership, drift repair and lockdown.")
