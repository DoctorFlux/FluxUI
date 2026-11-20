-- Exercise the real taxi owner and cast bar with explicit client event ordering.
local file = assert(io.open("tests/castbar_school_themes.lua", "rb"))
local fixtureSource = file:read("*a")
file:close()
fixtureSource = fixtureSource:sub(1, assert(fixtureSource:find("-- Profession artwork", 1, true)) - 1)
local fixture, loadAddon = assert((loadstring or load)(fixtureSource .. "\nreturn fixture, loadAddon"))()
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end

local function Point(x, y)
    return { GetXY = function() return x, y end }
end

local function Client(branch, saved, account, login, reload, clock, airborne)
    local state, env, ns = fixture(branch)
    local bar = state.NewBar("player")
    bar.Time.GetText = function(self) return self.text end
    state.clock, state.airborne = clock or 100, airborne or false
    state.taxiReads, state.mapReads, state.routeReads = 0, 0, 0
    state.options = {}
    state.origin = 1
    state.hops = { [2] = {2}, [3] = {2, 3}, [4] = {4}, [5] = {5} }
    state.nodes = {
        {nodeID=100, name="Origin", slotIndex=1, position=Point(1, 2)},
        {nodeID=200, name="Stop", slotIndex=2, position=Point(4, 2)},
        {nodeID=300, name="Destination", slotIndex=3, position=Point(9, 8)},
        {nodeID=400, name="Unmeasured", slotIndex=4, position=Point(4, 8)},
        {nodeID=500, name="Other stop", slotIndex=5, position=Point(7, 8)},
    }
    env.Enum.FlightPathState = {Current=1, Reachable=2}
    env._FluxUI_CharSavedVars = saved
    env.FluxUI_DB = account
    env.FluxUnitFrames_IsFeatureEnabled = function() return state.options.enableFlightPathTimers ~= false end
    env.FluxUnitFrames_ShouldShowCastBar = function() return state.options.showCastBar ~= false end
    env.FluxOptions = {GetUnitFrameDB=function() return state.options end}
    env.SlashCmdList = {}
    env.table = setmetatable({wipe=function(values)
        for key in pairs(values) do values[key] = nil end
    end}, {__index=table})
    env.DEFAULT_CHAT_FRAME = {AddMessage=function(_, line) state.message = line end}
    env.GetTaxiMapID = function() return 42 end
    env.C_Map = {
        GetBestMapForUnit = function() return 999 end,
        GetWorldPosFromMapPos = function(map, position)
            assert(map == 42)
            local x, y = position:GetXY()
            return 42, Point(x * 1000, y * 1000)
        end,
        GetPlayerMapPosition = function() return state.position end,
    }
    env.C_TaxiMap = {GetAllTaxiNodes=function(map)
        check(map == 42, "use the taxi map, even when the player is on another UI map")
        state.mapReads = state.mapReads + 1
        for slot, node in ipairs(state.nodes) do node.state = slot == state.origin and 1 or 2 end
        return state.nodes
    end}
    env.NumTaxiNodes = function() return #state.nodes end
    env.TaxiNodeGetType = function(index) return index == state.origin and "CURRENT" or "REACHABLE" end
    env.TaxiNodeName = function(index) return state.nodes[index].name end
    env.UnitFactionGroup = function() return "Alliance" end
    env.UnitOnTaxi = function()
        state.taxiReads = state.taxiReads + 1
        if branch == "classic_era" and not state.airborne then return nil end
        return state.airborne
    end
    env.GetNumRoutes = function(index)
        state.routeReads = state.routeReads + 1
        return state.hops[index] and #state.hops[index] or 0
    end
    local function TaxiPosition(slot)
        local x, y = state.nodes[slot].position:GetXY()
        return x / 10, y / 10
    end
    env.TaxiNodePosition = TaxiPosition
    env.TaxiGetDestX = function(index, leg) return TaxiPosition(state.hops[index][leg]) end
    env.TaxiGetDestY = function(index, leg) return select(2, TaxiPosition(state.hops[index][leg])) end
    if branch == "live" or branch == "forever" then
        env.TaxiGetNodeSlot = function(index, leg) return state.hops[index][leg] end
    end
    env.TakeTaxiNode = function() end
    env.TaxiRequestEarlyLanding = function() end
    env.TaxiNodeOnButtonEnter = function() end
    env.hooksecurefunc = function(owner, name, hook)
        if type(owner) == "string" then owner, name, hook = env, owner, name end
        local original = assert(owner[name])
        owner[name] = function(...)
            original(...)
            hook(...)
        end
    end
    env.GameTooltip = {
        AddLine=function(_, line) state.tooltip = line end,
        Show=function() end,
    }
    ns.FlightPathData = {FPDB={Alliance={[100]={[200]=10, [300]=100}, [200]={[300]=12}}}}

    local function Event(name, ...)
        for _, frame in ipairs(state.frames) do
            if frame.events[name] then frame.scripts.OnEvent(frame, name, ...) end
        end
    end
    local function Step(seconds)
        state.clock = state.clock + seconds
        state.Tick(seconds)
    end
    local function Hover(index)
        state.tooltip = nil
        env.TaxiNodeOnButtonEnter({GetID=function() return index end})
        return state.tooltip
    end
    local function Board(index, delay)
        env.TakeTaxiNode(index)
        if delay then Step(delay) end
        state.airborne = true
        Event("PLAYER_CONTROL_LOST")
        Step(0.2)
    end
    local function Land(index)
        state.position = state.nodes[index].position
        state.airborne = false
        Event("PLAYER_CONTROL_GAINED")
        Step(0.5)
    end

    loadAddon(arg[1] or "UnitFrames/FluxFlightPath.lua", env, ns)
    Event("PLAYER_ENTERING_WORLD", login ~= false, reload or false)
    return state, env, ns.FlightPath, bar, Event, Step, Hover, Board, Land
end

for _, branch in ipairs({"live", "forever", "classic", "classic_era", "classic_anniversary"}) do
    local state, env, fp, bar, event, step, hover, board, land = Client(branch)
    local idle = state.taxiReads
    step(1)
    check(state.taxiReads == idle, "grounded client performs no timer polling")
    event("TAXIMAP_OPENED")
    check(hover(3) == "~0:22", "sum the directed legs selected by the client")
    check(hover(3) == "~0:22" and state.mapReads == 1 and state.routeReads == 1, "repeated hover reuses route")
    check(hover(4) == "Time unknown", "unknown route has no fabricated estimate")
    board(3, 2)
    check(bar.customDuration == 22 and bar.customToName == "Destination", "hover does not choose the active destination")
    check(math.abs(bar.customStartTime - (state.clock - 0.2)) < 0.001, "timer starts at boarding")
    step(25)
    check(bar.customTimerKind == "flight" and bar.Time.text == "...", "estimated expiry waits for real landing")
    land(3)
    local learned = assert(env._FluxUI_CharSavedVars.flightPathTimes["100>300"]["200"])
    check(learned == 25.2 and not bar.customTimer and not env._FluxUI_CharSavedVars.flightPathActive,
        "landing automatically saves actual flight time and clears the active record")
    check(hover(3) == "0:25", "learned time replaces the estimate")
    env.SlashCmdList.FLUXFLIGHTPATH("measure")
    local measurement = state.message
    step(7)
    env.SlashCmdList.FLUXFLIGHTPATH("measure")
    check(state.message == measurement, "completed measurement stops changing")
    check(not fp.GetFlightTimeForNodes(200, 100), "reverse route does not reuse a forward duration")

    state.hops[3] = {5, 3}
    event("TAXIMAP_OPENED")
    check(hover(3) == "Time unknown", "different intermediate stop does not inherit a measurement")
    fp.SetOverride(100, 300, 33)
    check(hover(3) == "0:33", "explicit directed override is honored")
    fp.SetOverride(300, 100, 40)
    fp.ClearOverride(100, 300)
    check(fp.GetFlightTimeForNodes(300, 100) == 40 and hover(3) == "Time unknown", "clearing does not affect the reverse override")
    board(4)
    step(9)
    check(bar.customTimer and not bar.customDuration and bar.Time.text == "9.2" and bar.TimerBar.value == 0,
        "unknown routes display elapsed time without invented progress")
    land(4)
    check(hover(4) == "0:09", "learn a route with no estimate")
    board(4)
    step(10)
    land(4)
    check(hover(4) == "0:10", "a new completed ride automatically updates a learned time")
end

do
    local state, env, _, bar, event, step, hover, board, land = Client("live")
    local pin = env.CreateFrame("Frame")
    local map = {}
    function map:OnMapChanged() end
    function map:RefreshAllDataProviders() end
    function map:GetMapID() return 42 end
    -- The native iterator yields a pin as its first return value.
    function map:EnumeratePinsByTemplate()
        local first = true
        return function()
            if first then first = false; return pin end
        end
    end
    pin.taxiNodeData = state.nodes[2]
    env.FlightMapFrame = map
    event("ADDON_LOADED", "Blizzard_FlightMap")
    event("TAXIMAP_OPENED")
    map:RefreshAllDataProviders()
    check(#pin.hooks.OnEnter == 1, "a recycled modern pin has one tooltip hook")
    pin.hooks.OnEnter[1](pin)
    check(state.tooltip == "~0:10", "modern tooltip applies to the active pin")
    state.options.enableFlightPathTooltips = false
    check(hover(2) == nil, "tooltip option is independent")
    state.options.enableFlightPathCastBar = false
    board(2)
    step(2)
    check(not bar.customTimer, "display option does not stop measurement")
    local reads = state.taxiReads
    for _ = 1, 120 do step(1 / 60) end
    check(state.taxiReads - reads >= 9 and state.taxiReads - reads <= 10, "in-flight polling is capped near five reads per second")
    state.options.enableFlightPathCastBar = true
    step(0.2)
    check(bar.customTimer, "enabling the bar resumes the active measurement")
    event("PLAYER_LEAVING_WORLD")
    state.airborne = false
    step(2)
    state.airborne = true
    event("PLAYER_ENTERING_WORLD", false, false)
    check(bar.customTimer, "a world transition cannot finalize an active route")
    land(2)
end

do
    local state, env, _, _, event, step, _, board = Client("forever")
    event("TAXIMAP_OPENED")
    board(3)
    step(10)
    event("PLAYER_LOGOUT")
    local saved = env._FluxUI_CharSavedVars.flightPathActive
    check(math.abs(saved.elapsed - 10.2) < 0.001, "logout captures actual elapsed flight time")

    local re, reEnv, _, reBar, reEvent, reStep, _, _, reLand =
        Client("forever", env._FluxUI_CharSavedVars, nil, false, true, state.clock + 2, false)
    check(not reBar.customTimer, "reload waits for the native taxi state")
    re.airborne = true
    reStep(0.2)
    check(reBar.customDuration == 22 and reBar.Time.text == "~9.6", "reload adds elapsed loading time")
    reStep(1)
    reEvent("PLAYER_LOGOUT")
    local elapsed = reEnv._FluxUI_CharSavedVars.flightPathActive.elapsed
    local login, loginEnv, _, loginBar, _, loginStep, _, _, loginLand =
        Client("forever", reEnv._FluxUI_CharSavedVars, nil, true, false, 6, true)
    check(loginBar.customToName == "Destination" and math.abs(loginBar.customStartTime - (6 - elapsed)) < 0.001,
        "fresh login restores saved progress even with a different runtime clock")
    loginStep(10)
    loginLand(3)
    check(not loginEnv._FluxUI_CharSavedVars.flightPathTimes,
        "a logout-resumed ride cannot overwrite route measurements")
    check(not loginBar.customTimer and not login.airborne, "logout-resumed timer ends at landing")

    reLand(3)
    check(reEnv._FluxUI_CharSavedVars.flightPathTimes["100>300"]["200"], "UI reload can still yield a completed measurement")
end

do
    local state, env, _, bar, event, step, hover, board, land = Client("classic")
    event("TAXIMAP_OPENED")
    env.TakeTaxiNode(2)
    step(11)
    check(not bar.customTimer and not env._FluxUI_CharSavedVars.flightPathActive, "failed boarding times out")
    board(3)
    step(6)
    env.TaxiRequestEarlyLanding()
    check(bar.customTimer and bar.customDuration == nil, "requesting an early landing switches to elapsed time")
    land(2)
    check(not env._FluxUI_CharSavedVars.flightPathTimes, "early landing cannot teach the requested endpoint")
    board(3)
    step(6)
    land(2)
    check(not env._FluxUI_CharSavedVars.flightPathTimes, "an observed wrong destination cannot teach the requested endpoint")
    board(2)
    step(4)
    event("PLAYER_DEAD")
    check(not bar.customTimer and not env._FluxUI_CharSavedVars.flightPathTimes, "death discards the ride")
    state.airborne = false
    check(hover(2) == "~0:10", "aborted flights leave estimates intact")
end

do
    local saved = {flightPathActive={version=1, elapsed=4, savedAt=20, duration=20, variant="direct"}}
    local state, env, _, bar, _, step = Client("live", saved)
    step(6)
    check(not env._FluxUI_CharSavedVars.flightPathActive and not bar.customTimer, "grounded login clears stale flight state")
    local idle = state.taxiReads
    step(6)
    check(state.taxiReads == idle, "stale history does not leave a running driver")
end
print(string.format("Flight timer checks: %d passed", checks))
