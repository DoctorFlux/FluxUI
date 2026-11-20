-- Exercise the real roster functions with authored frame state. An optional
-- archive and captured FrameXML directory supply paired native setter tests.
local function Read(path)
    local f=assert(io.open(path,"rb"))
    local text=f:read("*a")
    f:close()
    return (text:gsub("\r\n","\n"))
end

local function Slice(text,first,last)
    local from=assert(text:find(first,1,true),first)
    return text:sub(from,assert(text:find(last,from+#first,true),last)-1)
end

local secure="RaidFrame/FluxRaidSecure.lua"
local layout="RaidFrame/FluxRaidLayout.lua"
local prior,pins=arg[1],arg[2]
local oldSecure=prior and prior.."/RaidFrame-FluxRaidSecure.lua" or secure
local oldLayout=prior and prior.."/RaidFrame-FluxRaidLayout.lua" or layout
local opaque={}
local function Secret(v) return rawequal(v,opaque) end

local function References(path,native)
    local state={writes=0,clears=0,executes=0,refs={},groups={},container={},mt={}}
    local hub={}
    local handles={}
    local function Handle(frame)
        if not handles[frame] then handles[frame]={owner=frame} end
        return handles[frame]
    end
    function hub:GetAttribute(key)
        if self.unavailable==key then error("attribute unavailable") end
        if self.opaque==key then return opaque end
        return state.refs[key]
    end
    function hub:SetAttribute(key,value)
        assert(not state.combat)
        if key:sub(1,8)=="frameref" and value==nil then state.clears=state.clears+1 end
        state.refs[key]=value
    end
    local writeRef=function(frame,label,target) frame:SetAttribute("frameref-"..label,Handle(target)) end
    if native then
        local src=Read(native)
        local api,prepare={},{}
        local env=setmetatable({
            LOCAL_API_Frame=api,IsValidFrame=function(frame) return type(frame)=="table" end,
            CheckForbidden=function(frame) return frame.forbidden end,MakeForbidden=function(frame) frame.forbidden=true end,
            GetFrameHandle=Handle,
        },{__index=_G})
        local handler=Slice(src,"local frameid = name:match(","\nend\n\n-- Frame used")
        prepare.run=assert(load("return function(self,name,value)\n"..handler.."\nend","@FrameXML-ref-dispatch","t",env))()
        function api:GetAttribute(key) return self[key] end
        function api:SetAttribute(key,value)
            self[key]=value
            if value~=nil then prepare.run(self,key,value) end
        end
        local setter=Slice(src,"function SecureHandlerSetFrameRef(","\n---")
        writeRef=assert(load(setter.."\nreturn SecureHandlerSetFrameRef","@FrameXML-set-ref","t",env))()
    end
    function hub:SetFrameRef(label,target)
        assert(not state.combat)
        state.writes=state.writes+1
        writeRef(self,label,target)
    end
    for i=1,8 do state.groups[i]={} end
    local capability={ExecutePaging=function(frame,body)
        assert(frame==hub and body:find("_flux-roster-layout",1,true))
        assert(not state.combat)
        state.executes=state.executes+1
        for i=1,8 do
            local g=state.groups[i]
            assert(state.refs["frameref-roster-group"..i]==(g and Handle(g)),"layout sees the current group header")
        end
        assert(state.refs["frameref-roster-container"]==Handle(state.container),"layout sees the current container")
        assert(state.refs["frameref-roster-mt"]==(state.mt and Handle(state.mt)),"layout sees current MT option")
        return true
    end}
    local env=setmetatable({Secure={},ROSTER_LAYOUT="roster body",EnsureHub=function() return hub,capability end,
        InCombat=function() return state.combat end,issecretvalue=Secret},{__index=_G})
    local code=Slice(Read(path),"function Secure.RefreshRosterLayout(","_G.FluxRaidSecure = Secure")
    assert(load(code,"@actual-secure-roster-refresh","t",env))()
    function state:refresh() return env.Secure.RefreshRosterLayout(self.container,self.groups,self.mt,{}) end
    state.hub,state.handle=hub,Handle
    return state
end

local function CheckReferences(a,b)
    assert(a:refresh() and b:refresh() and a.writes==10 and b.writes==10)
    a.writes,b.writes=0,0
    for _=1,6 do assert(a:refresh() and b:refresh()) end
    assert(b.writes==0 and (not prior or a.writes==60))
    local before,after=a.writes,b.writes
    for _,t in ipairs({a,b}) do
        t.writes=0
        t.groups[4]={}
        assert(t:refresh())
        if t==b then assert(t.writes==1,"only the replaced group receives a new ref") end
        t.refs["frameref-roster-group4"]=t.handle(t.groups[1])
        assert(t:refresh())
        t.hub.unavailable="frameref-roster-group3"
        t.hub.opaque="frameref-roster-group8"
        assert(t:refresh())
        if t==b then assert(t.writes==4,"restore drift and rebind unreadable/private refs") end
        t.hub.unavailable,t.hub.opaque=nil,nil
        t.mt=nil
        assert(t:refresh() and t.clears==1 and t.refs["frameref-roster-mt"]==nil)
        t.mt={}
        assert(t:refresh())
        local writes,executes=t.writes,t.executes
        t.combat=true
        assert(t:refresh()==false and t.writes==writes and t.executes==executes)
    end
    assert(a.executes==b.executes,"both paths still run native layout on each eligible call")
    return before,after
end

local targets={"live","forever","classic","classic_era","classic_anniversary"}
for _,target in ipairs(targets) do
    local native=pins and pins.."/"..target.."-Interface_AddOns_Blizzard_RestrictedAddOnEnvironment_SecureHandlers.lua"
    local before,after=CheckReferences(References(oldSecure,native),References(secure,native))
    print(("ROSTER_REFS %s stable=%d/%d"):format(target,before,after))
end

local function Presentation(path)
    local text=Read(path)
    local writes={anchors=0,width=0,labels=0}
    local state={raidHeaders={}}
    local p={enabled=true,inGroup=true,isRaid=false,writes=writes,state=state}
    local methods={}
    function methods:GetNumPoints() return self.point and 1 or 0 end
    function methods:GetPoint() return table.unpack(self.point or {}) end
    function methods:ClearAllPoints() self.point=nil;writes.anchors=writes.anchors+1 end
    function methods:SetPoint(...) self.point={...};writes.anchors=writes.anchors+1 end
    function methods:GetWidth() return self.width end
    function methods:SetWidth(value) self.width=value;writes.width=writes.width+1 end
    function methods:IsShown() return self.shown end
    function methods:Show() self.shown=true;writes.labels=writes.labels+1 end
    function methods:Hide() self.shown=false;writes.labels=writes.labels+1 end
    function methods:GetText() return self.text end
    function methods:SetText(text) self.text=text;writes.labels=writes.labels+1 end
    local function Frame()
        return setmetatable({shown=false},{__index=methods})
    end
    state.containerFrame,state.mtmaHeader=Frame(),Frame()
    for i=1,8 do
        local header=Frame()
        header._fluxGroupLabel=Frame()
        state.raidHeaders[i]=header
    end
    state.mtmaHeader._fluxGroupLabel=Frame()
    local env=setmetatable({
        State=state,GROUP_COUNT=8,GRP_SPACING=3,MTMA_EXTRA_Y_FOR_FOUR_PLUS=60,
        FluxRaidVisuals={FRAME_WIDTH=72},ColumnHeight=function() return 180 end,
        InCombatLockdown=function() return p.combat end,Queue=function() p.queued=true end,
        IsInRaid=function() return p.isRaid end,IsInGroup=function() return p.inGroup end,
        FluxOptions={GetRaidFrameDB=function() return {showGroupLabels=p.enabled} end},
        ReadLegacyHeaderLayout=function() return {1,0,0,0,0,0,0,0},{totalSlots=9,groupX={[1]=600}},0 end,
        Secret=Secret,
    },{__index=_G})
    local start=text:find("local function PlaceRosterHeader(",1,true) and "local function PlaceRosterHeader(" or "LayoutHeaders = function("
    local code=Slice(text,"local function RosterDockNative(","PositionBlizzardRaidManager = function()")
        ..Slice(text,"local function GetGroupColumnLabelText(","local function ApplyMTMAChatOverlapLift(")
        ..Slice(text,start,"local function PrecreateHeaderChildren(")
    p.position,p.labels=assert(load(code.."\nreturn LayoutHeaders,UpdateGroupColumnLabels","@actual-roster-presentation","t",env))()
    return p
end

local a,b=Presentation(oldLayout),Presentation(layout)
for _,t in ipairs({a,b}) do
    assert(t.position())
    t.writes.anchors,t.writes.width=0,0
    for _=1,6 do assert(t.position()) end
    t.labels()
    t.writes.labels=0
    for _=1,6 do t.labels() end
end
assert(b.writes.anchors==0 and b.writes.width==0 and b.writes.labels==0)
if prior then assert(a.writes.anchors==108 and a.writes.width==6 and a.writes.labels==102) end
print(("ROSTER_PRESENTATION stable anchors=%d/%d width=%d/%d labels=%d/%d")
    :format(a.writes.anchors,b.writes.anchors,a.writes.width,b.writes.width,a.writes.labels,b.writes.labels))
for _,t in ipairs({a,b}) do
    local header=t.state.raidHeaders[1]
    assert(header._fluxGroupLabel.text=="Party" and header._fluxGroupLabel.shown)
    t.isRaid=true;t.labels()
    assert(header._fluxGroupLabel.text=="1")
    t.enabled=false;t.labels()
    assert(not header._fluxGroupLabel.shown)
    t.enabled=true
    header._fluxGroupLabel.GetText=function() return opaque end
    header._fluxGroupLabel.text="unknown"
    t.labels()
    assert(header._fluxGroupLabel.text=="1" and header._fluxGroupLabel.shown)
    header.point[2]={}
    t.state.containerFrame.width=1
    t.position()
    assert(header.point[2]==t.state.containerFrame and t.state.containerFrame.width==675)
    t.combat=true
    header.point=nil
    t.position()
    assert(t.queued and header.point==nil)
end
print("Roster writes preserve placement, label repair, reference recovery and combat deferral.")
