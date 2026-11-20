-- Execute the Details threat display and listener against a modeled group.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local contents = file:read("*a")
    file:close()
    return (contents:gsub("\r\n", "\n"))
end

local function fixture(source, timer)
    local pending, count, members, scans, time = {}, 0, 0, 0, 10
    local target, nowShown = "targettarget", nil
    local threat = {Active = true, pluginGloballyEnabled = true,
        options = {updatespeed = .2}, saveddata = {event_led_threat_updates = true}}
    function threat:GetPluginInstance() return true end
    function threat:HideBars() end
    local frame = {IsVisible = function() return true end}
    function frame:SetScript(script, callback) self[script] = callback end
    local env = setmetatable({
        Threat = threat, ThreatFrame = frame,
        GetTime = function() return time end,
        GetThreatTarget = function() return target end,
        _UnitExists = function() return true end,
        _UnitAffectingCombat = function() return true end,
        IsForeverThreatClient = function() return false end,
        GatherAllThreat = function(unit)
            scans = scans + 1
            count = count + members
            nowShown = {unit = unit, members = members}
            threat.threatData = {}
        end,
    }, {__index = _G})
    if timer then
        env.C_Timer = {After = function(delay, callback)
            assert(delay == 0, "one next-update callback")
            pending[#pending + 1] = callback
        end}
    end
    local start = assert(source:find("    local function UpdateDisplay()", 1, true))
    local finish = assert(source:find("    syncThreatPollingScript()\nend", start, true))
    local code = "local lastThreatPollTime, threatPollDeferred = 0, false\n"
        .. "local rosterRefreshPending, rosterRefreshQueued\n"
        .. source:sub(start, finish - 1)
    assert(load(code, "@actual-details-threat-display", "t", env))()
    threat:SyncThreatPollingScript()
    return {
        roster = function(n)
            members = n
            threat:OnThreatListOrRosterEvent("GROUP_ROSTER_UPDATE")
        end,
        list = function(unit) threat:OnThreatListOrRosterEvent("UNIT_THREAT_LIST_UPDATE", unit) end,
        target = function(unit) target = unit; threat:TargetChanged() end,
        update = function()
            time = time + .25
            if frame.OnUpdate then frame.OnUpdate() end
        end,
        flush = function()
            local queued = pending
            pending = {}
            for _, callback in ipairs(queued) do callback() end
        end,
        queued = function() return #pending end,
        observed = function() return scans, count, nowShown and nowShown.members, nowShown and nowShown.unit end,
        leaveCombat = function()
            threat:Stop()
            threat.Active = false
            threat:SyncThreatPollingScript()
        end,
        disable = function()
            threat.pluginGloballyEnabled = false
            threat:SyncThreatPollingScript()
        end,
        cancel = function() threat:Cancel() end,
        start = function()
            threat.Active = true
            threat:Start()
            threat:SyncThreatPollingScript()
        end,
    }
end

local current = read("Battlezonemap/FluxThreat.lua")
local baseline = arg[1] and read(arg[1])
for _, mode in ipairs({"party", "raid"}) do
    local maximum = mode == "party" and 5 or 40
    for _, joining in ipairs({true, false}) do
        local function replay(model)
            for i = 1, 20 do model.roster(i < 20 and maximum or joining and maximum or 1) end
            model.flush()
            return model.observed()
        end
        local scans, units, final = replay(fixture(current, true))
        assert(scans == 1 and units == final and final == (joining and maximum or 1),
            "only the final party/raid state is presented")
        local before, oldUnits, oldFinal
        if baseline then
            before, oldUnits, oldFinal = replay(fixture(baseline, true))
            assert(before == 20 and final == oldFinal, "matched immediate baseline")
        end
        print(("DETAILS_THREAT_ROSTER %s %s scans=%s/%d visits=%s/%d final=%d"):format(
            mode, joining and "join" or "leave", tostring(before), scans, tostring(oldUnits), units, final))
    end
end

for _, consume in ipairs({"list", "target", "poll", "leaveCombat", "disable", "cancel"}) do
    local model = fixture(current, true)
    model.roster(40)
    model.roster(5)
    model.list("focus")
    assert(model.queued() == 1 and model.observed() == 0)
    if consume == "list" then model.list("targettarget")
    elseif consume == "target" then model.target("target")
    elseif consume == "poll" then model.update()
    else model[consume]() end
    local beforeFlush = model.observed()
    model.flush()
    assert(beforeFlush == model.observed(), consume .. " consumes or cancels pending roster work")
    local activeUpdate = consume == "list" or consume == "target" or consume == "poll"
    assert(beforeFlush == (activeUpdate and 1 or 0), consume .. " retains the existing update behavior")
end

local timerless = fixture(current, false)
timerless.roster(5)
assert(timerless.observed() == 1 and timerless.queued() == 0, "timerless clients retain synchronous display")

local restarted = fixture(current, true)
restarted.roster(5)
restarted.leaveCombat()
restarted.start()
restarted.roster(40)
assert(restarted.queued() == 1)
restarted.flush()
local scans, visits = restarted.observed()
assert(scans == 1 and visits == 40, "only the new roster survives combat restart")
print("Details threat roster timer, direct updates, polling, cancellation and re-entry pass.")
