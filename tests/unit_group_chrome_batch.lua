-- Execute the production group event branch and subgroup display closure.
-- An optional previous source path records matched baseline work.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local text=file:read("*a")
    file:close()
    return (text:gsub("\r\n","\n"))
end

local function Section(source,first,last)
    local start=assert(source:find(first,1,true),first)
    return source:sub(start,assert(source:find(last,start+#first,true),last)-1)
end

local current=Read("UnitFrames/FluxUnitFrames_Shared.lua")
local baseline=arg[1] and Read(arg[1])
local rosterEvents={"GROUP_ROSTER_UPDATE","RAID_ROSTER_UPDATE","PARTY_LEADER_CHANGED","PARTY_LOOT_METHOD_CHANGED"}
local unitTokens={"player","target","focus","targettarget","focustarget","pet"}

local function Model(source,timer)
    local m={frames={},callbacks={},errors={},trace={},roster="solo",writes=0,scheduled=0}
    local UF={}
    local env=setmetatable({
        UF=UF,
        ns={Flux={Safecall=function(fn,frame)
            local ok,message=pcall(fn,frame)
            if not ok then m.errors[#m.errors+1]=message end
        end}},
    },{__index=_G})
    if timer then
        env.C_Timer={After=function(delay,fn)
            assert(delay==0)
            m.callbacks[#m.callbacks+1]=fn
            m.scheduled=m.scheduled+1
        end}
    end
    UF.LayoutThreatBar=function(frame,rosterOnly)
        assert(rosterOnly and (frame.unit=="target" or frame.unit=="focus"))
        frame.threat=m.roster
        m.trace[#m.trace+1]=frame.unit..":threat"
        m.writes=m.writes+1
    end
    local queue=source:find("    local function RefreshRosterChrome(frame)",1,true)
        and Section(source,"do\n    local queuedFrames, queuedSet","local function OnEvent") or ""
    local branch=Section(source,'    elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE"',
        '    elseif event == "PLAYER_UPDATE_RESTING"')
    local dispatch=assert(load(queue.."return function(self,event)\nif false then\n"..branch.."end\nend",
        "@actual-group-chrome-branch","t",env))()
    for _,unit in ipairs(unitTokens) do
        local frame={unit=unit}
        function frame:UpdateGroupText()
            self.group=m.roster
            m.trace[#m.trace+1]=unit..":group"
            m.writes=m.writes+1
            if self.fail then error("group-chrome-failed",0) end
        end
        function frame:UpdateOuterBorder()
            self.outer=m.roster
            m.trace[#m.trace+1]=unit..":outer"
            m.writes=m.writes+1
            if self.reenter then
                self.reenter=false
                dispatch(self,rosterEvents[1])
            end
        end
        m.frames[#m.frames+1]=frame
    end
    function m.event(event,one)
        if one then dispatch(one,event);return end
        for _,frame in ipairs(m.frames) do dispatch(frame,event) end
    end
    function m.drain()
        local callbacks=m.callbacks
        m.callbacks={}
        for _,fn in ipairs(callbacks) do fn() end
    end
    function m.signature()
        local values={}
        for _,f in ipairs(m.frames) do
            values[#values+1]=table.concat({f.unit,f.group or "",f.outer or "",f.threat or ""},":")
        end
        return table.concat(values,"|")
    end
    return m
end

for _,transition in ipairs({{"solo","party"},{"party","raid"},{"raid","party"},{"party","solo"},{"raid","solo"}}) do
    local before=baseline and Model(baseline,true)
    local after=Model(current,true)
    for _,m in ipairs(before and {before,after} or {after}) do
        m.roster=transition[1]
        for step=1,20 do
            if step==20 then m.roster=transition[2] end
            m.event(rosterEvents[(step-1)%#rosterEvents+1])
        end
    end
    assert(after.scheduled==1 and after.writes==0,"one callback for all six frames before the batch")
    after.drain()
    assert(after.writes==14 and #after.callbacks==0,"each frame settles once and only target/focus update threat")
    for _,frame in ipairs(after.frames) do
        assert(frame.group==transition[2] and frame.outer==transition[2])
    end
    if before then
        assert(before.writes==280 and before.signature()==after.signature(),"exact branch matches final paint")
        print(("GROUP_CHROME %s>%s callbacks=%d/%d refreshCalls=%d/%d"):format(
            transition[1],transition[2],before.scheduled,after.scheduled,before.writes,after.writes))
    end
end

do
    local m=Model(current,true)
    m.frames[1].reenter=true
    m.frames[2].fail=true
    m.event(rosterEvents[1])
    m.drain()
    assert(m.errors[1]=="group-chrome-failed" and m.frames[3].outer=="solo","one failed frame leaves other frames serviced")
    assert(#m.callbacks==1 and m.scheduled==2,"reentrant update schedules a new batch")
    m.drain()
    assert(#m.callbacks==0 and m.writes==14,"new work runs once without reviving the old batch")

    local immediate=Model(current,false)
    immediate.roster="raid"
    immediate.event(rosterEvents[2])
    assert(immediate.writes==14 and immediate.scheduled==0,"timerless adapter retains synchronous behavior")

    local roles=Model(current,true)
    roles.event("PARTY_LEADER_CHANGED",roles.frames[1])
    roles.frames[6]._fluxPartyMember=true
    roles.event("RAID_ROSTER_UPDATE",roles.frames[6])
    assert(roles.writes==4 and roles.scheduled==0,"standalone role paint and compact party delegation stay immediate")
end

local function GroupLabel(source)
    local m={slot=40,subgroup=8,reads=0,identity=0,countReads=0,writes=0}
    local private={}
    local groupText={shown=false,text=""}
    function groupText:GetText() return self.text end
    function groupText:SetText(text) self.text=text;m.writes=m.writes+1 end
    function groupText:IsShown() return self.shown end
    function groupText:Show() self.shown=true end
    function groupText:Hide() self.shown=false end
    local ns={Flux={PlayerName={IsUnitPlayer=function(token)
        m.identity=m.identity+1
        return token=="raid40"
    end}}}
    local env=setmetatable({
        UnitInRaid=function() return m.slot end,
        GetNumGroupMembers=function() m.countReads=m.countReads+1;return 40 end,
        GetRaidRosterInfo=function(index)
            m.reads=m.reads+1
            return "slot"..index,0,index==40 and m.subgroup or 1
        end,
        ValueIsSecret=function(value) return rawequal(value,private) end,
        PublicGeometryNumber=function(value) return type(value)=="number" and value or nil end,
    },{__index=_G})
    local code=Section(source,"    local function UpdateGroupText()","    -- Store the update function")
    m.paint=assert(load("local frame,ns=...\n"..code.."return UpdateGroupText",
        "@actual-raid-subgroup-display","t",env))({groupText=groupText},ns)
    m.label,m.private=groupText,private
    return m
end

do
    local m=GroupLabel(current)
    m.paint()
    assert(m.label.shown and m.label.text=="Grp: 8" and m.reads==1 and m.identity==0 and m.countReads==0)
    if baseline then
        local before=GroupLabel(baseline)
        before.paint()
        assert(before.label.text==m.label.text and before.reads==40 and before.identity==40)
        print(("GROUP_SUBGROUP rosterRows=%d/%d identityChecks=%d/%d"):format(before.reads,m.reads,before.identity,m.identity))
    end
    m.slot=nil
    m.paint()
    assert(not m.label.shown and m.reads==1)
    m.slot=40
    m.paint()
    assert(m.label.shown and m.writes==1,"rejoining the same subgroup restores the existing label")
    m.slot=m.private
    m.paint()
    assert(m.label.shown and m.reads==2,"private index leaves settled label in place")
    m.slot=true
    m.subgroup=4
    m.paint()
    assert(m.label.text=="Grp: 4" and m.reads==42 and m.identity==40,"unknown numeric index takes the identity scan")
    m.slot=40
    m.subgroup=m.private
    m.paint()
    assert(m.label.text=="Grp: 1" and m.reads==83,"unreadable subgroup retains fallback without formatting private data")
end
print("Group chrome replay: join, leave, conversion, raid subgroup, error and reentrant recovery pass.")
