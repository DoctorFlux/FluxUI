-- Flight path tooltips and the player cast-bar timer.
-- Optional fallback durations are from RestedXP Guides (CC BY-NC-SA 4.0).
local _, ns = ...
local FP = ns.FlightPath or {}
ns.FlightPath = FP

local TICK, BOARD_WINDOW, RESUME_WINDOW, LAND_GRACE = 0.2, 10, 5, 0.4
local MAX_FLIGHT, LAND_RADIUS, SNAPSHOT_VERSION = 3600, 300, 1
local isSecret = issecretvalue or IsSecretValue
local floor, max = math.floor, math.max
local mapID, current, slots, nodeHash, routes
local pending, active, resume, lastFlight, displayedBar
local inWorld, enteredWorld
local events = CreateFrame("Frame")

local function Readable(value)
    if not isSecret or not isSecret(value) then return value end
end

local function ValidTime(value)
    return type(value) == "number" and value > 0 and value <= MAX_FLIGHT
end

local function Child(parent, key)
    if type(parent[key]) ~= "table" then parent[key] = {} end
    return parent[key]
end

local function Character()
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    return _FluxUI_CharSavedVars
end

local function Faction()
    return UnitFactionGroup and UnitFactionGroup("player") == "Horde" and "Horde" or "Alliance"
end

local function Account()
    FluxUI_DB = FluxUI_DB or {}
    return Child(FluxUI_DB, "flightPath")
end

local function Directed(rows, from, to)
    local row = rows and from and rows[from]
    local seconds = type(row) == "table" and to and row[to]
    return ValidTime(seconds) and seconds or nil
end

local function IsEnabled(setting)
    if FluxUnitFrames_IsFeatureEnabled and not FluxUnitFrames_IsFeatureEnabled("flightPathTimers") then
        return false
    end
    if not setting then return true end
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    return not db or db[setting] ~= false
end

local function StaticData(faction)
    local db = ns.FlightPathData and ns.FlightPathData.FPDB
    return db and db[faction]
end

local function LearnedTimes()
    local char = _FluxUI_CharSavedVars
    return char and char.flightPathTimes
end

local function PairKey(from, to)
    if from and to and from ~= to then return from .. ">" .. to end
end

local function GetDuration(route)
    local faction = Faction()
    local account = FluxUI_DB and FluxUI_DB.flightPath
    local overrides = account and account.overrides and account.overrides[faction]
    local manual = account and account.manual and account.manual[faction]
    local seconds = Directed(overrides, route.from, route.to)
    if seconds and Directed(manual, route.from, route.to) then return seconds, "manual" end

    local learned = LearnedTimes()
    local variants = route.key and learned and learned[route.key]
    local measured = type(variants) == "table" and variants[route.variant]
    if ValidTime(measured) then return measured, "learned" end

    local static = StaticData(faction)
    if not route.legs or #route.legs == 1 then
        local estimate = seconds or Directed(static, route.from, route.to)
        if estimate then return estimate, "estimate" end
        return
    end

    local total, from = 0, route.from
    for _, to in ipairs(route.legs) do
        local leg = Directed(overrides, from, to) or Directed(static, from, to)
        if not leg then
            if seconds then return seconds, "estimate" end
            return
        end
        total, from = total + leg, to
    end
    if ValidTime(total) then return total, "estimate" end
end

function FP.GetNodeName(id)
    if not id then return end
    local names = _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.flightPathNodes
    local static = StaticData(Faction())
    return names and names[id] or static and static[id] and static[id].name
end

function FP.GetFlightTimeForNodes(from, to)
    return GetDuration({ from = from, to = to, key = PairKey(from, to), variant = "direct" })
end

function FP.SetOverride(from, to, seconds)
    from, to, seconds = tonumber(from), tonumber(to), tonumber(seconds)
    if not from or not to or not ValidTime(seconds) then return false end
    local account, faction = Account(), Faction()
    Child(Child(Child(account, "overrides"), faction), from)[to] = max(1, floor(seconds + 0.5))
    Child(Child(Child(account, "manual"), faction), from)[to] = 1
    return true
end

function FP.ClearOverride(from, to)
    from, to = tonumber(from), tonumber(to)
    if not from or not to then return false end
    local account, faction = Account(), Faction()
    local overrides = Child(Child(account, "overrides"), faction)
    local manual = Child(Child(account, "manual"), faction)
    if type(overrides[from]) == "table" then overrides[from][to] = nil end
    if type(manual[from]) == "table" then manual[from][to] = nil end
    return true
end

local function FormatDuration(seconds)
    seconds = max(0, floor(tonumber(seconds) or 0))
    return string.format("%d:%02d", floor(seconds / 60), seconds % 60)
end
FP.FormatDuration = FormatDuration

local function HashPosition(x, y)
    x, y = Readable(x), Readable(y)
    if type(x) == "number" and type(y) == "number" then
        return floor(x * 4096) + floor(y * 4096) * 4096
    end
end

function FP.GetFlightHash(index, leg)
    if leg then
        if TaxiGetDestX and TaxiGetDestY then
            return HashPosition(TaxiGetDestX(index, leg), TaxiGetDestY(index, leg))
        end
    elseif TaxiNodePosition then
        return HashPosition(TaxiNodePosition(index))
    end
end

local function AddNode(info, uiMapID)
    local slot = Readable(info.slotIndex)
    if not slot or slot < 1 or Readable(info.isMapLayerTransition) then return end
    local id, name = Readable(info.nodeID), Readable(info.name)
    local node = slots[slot]
    if not node or node.id ~= id or node.name ~= name or node.map ~= uiMapID then
        slots[slot] = { id = id, name = name, position = Readable(info.position), map = uiMapID }
        routes[slot] = nil
    end
    if id and id > 0 and name then
        local names = Child(Character(), "flightPathNodes")
        if names[id] ~= name then names[id] = name end
    end
    local states = Enum and Enum.FlightPathState
    if states and Readable(info.state) == states.Current then current = slot end
end

local function CaptureMap()
    slots, nodeHash, routes, current = {}, {}, {}, nil
    mapID = Readable(GetTaxiMapID and GetTaxiMapID())
    if not mapID or mapID <= 0 then
        mapID = Readable(C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    end
    if mapID and C_TaxiMap and C_TaxiMap.GetAllTaxiNodes then
        local nodes = Readable(C_TaxiMap.GetAllTaxiNodes(mapID))
        for _, info in ipairs(nodes or {}) do AddNode(info, mapID) end
    end
    local count = Readable(NumTaxiNodes and NumTaxiNodes()) or 0
    for slot = 1, count do
        local name = Readable(TaxiNodeName and TaxiNodeName(slot))
        if not slots[slot] and name and name ~= "" then slots[slot] = { name = name, map = mapID } end
        if Readable(TaxiNodeGetType and TaxiNodeGetType(slot)) == "CURRENT" then current = slot end
        local hash = FP.GetFlightHash(slot)
        if hash and slots[slot] then nodeHash[hash] = slot end
    end
end

local function NodeKey(node)
    if node.id and node.id > 0 then return tostring(node.id) end
    if node.name and node.name ~= "" and node.map then
        return string.format("%d:%q", node.map, node.name)
    end
end

local function GetRoute(index)
    if not slots or not current then CaptureMap() end
    if not index or index == current then return end
    if routes[index] and routes[index].sourceSlot == current then return routes[index] end
    local origin, dest = slots[current], slots[index]
    if not origin or not dest then return end

    local route = {
        from = origin.id, to = dest.id, sourceSlot = current,
        fromName = origin.name, toName = dest.name,
        key = PairKey(NodeKey(origin), NodeKey(dest)),
        variant = "unresolved",
    }
    local count = Readable(GetNumRoutes and GetNumRoutes(index))
    if count == 1 then
        route.variant = "direct"
    elseif count and count > 1 then
        local legs, stops = {}, {}
        for leg = 1, count - 1 do
            local slot = Readable(TaxiGetNodeSlot and TaxiGetNodeSlot(index, leg, false))
            local stop = slots[slot]
            if not stop then
                local hash = FP.GetFlightHash(index, leg)
                stop = slots[hash and nodeHash[hash]]
                stops[leg] = stop and NodeKey(stop) or hash and (tostring(mapID) .. "#" .. hash)
            else
                stops[leg] = NodeKey(stop)
            end
            legs[leg] = stop and stop.id or false
            if not stops[leg] then break end
        end
        if #stops == count - 1 then
            legs[count] = dest.id or false
            route.legs = legs
            route.variant = table.concat(stops, "/")
        end
    end
    if count and count > 1 and not route.legs then
        -- A multi-stop route with unknown waypoints cannot borrow a direct ETA.
        route.legs = { false, false }
        route.variant = "unresolved:" .. count
    end
    routes[index] = route
    return route
end

function FP.GetFlightTime(index)
    local route = GetRoute(index)
    if route then return GetDuration(route) end
end

local function IsOnTaxi()
    if not UnitOnTaxi then return end
    local airborne = UnitOnTaxi("player")
    if not isSecret or not isSecret(airborne) then return not not airborne end
end

local function WorldPosition(uiMapID, position)
    if not (uiMapID and position and C_Map and C_Map.GetWorldPosFromMapPos) then return end
    local continent, world = C_Map.GetWorldPosFromMapPos(uiMapID, position)
    continent, world = Readable(continent), Readable(world)
    if not (continent and world) then return end
    local x, y = world:GetXY()
    x, y = Readable(x), Readable(y)
    if x and y then return continent, x, y end
end

local function ReachedDestination(flight)
    if not (flight.destContinent and C_Map and C_Map.GetPlayerMapPosition) then return true end
    local pos = Readable(C_Map.GetPlayerMapPosition(flight.destMap, "player"))
    local continent, x, y = WorldPosition(flight.destMap, pos)
    if not continent then return true end
    local dx, dy = x - flight.destX, y - flight.destY
    return continent == flight.destContinent and dx * dx + dy * dy <= LAND_RADIUS * LAND_RADIUS
end

local function StopBar(fade)
    local bar = displayedBar
    displayedBar = nil
    if bar and bar.customTimerKind == "flight" then
        ns.CastBar.StopCustomTimer(bar, fade and { fade = true } or nil)
    end
end

local function PaintBar()
    local bar = ns.PlayerFrame and ns.PlayerFrame.CastBar
    local cb = ns.CastBar
    if not (bar and cb and IsEnabled("enableFlightPathCastBar"))
        or (FluxUnitFrames_ShouldShowCastBar and not FluxUnitFrames_ShouldShowCastBar("player")) then
        StopBar()
        return
    end
    if displayedBar ~= bar then StopBar() end
    if bar.customTimerKind == "flight" or bar.casting or bar.channeling or bar.customTimer then return end

    cb.StartCustomTimer(bar, {
        kind = "flight", fromName = active.fromName, toName = active.toName,
        name = active.toName, duration = active.duration, startTime = active.start,
        waitForStop = true, approximate = active.approximate,
    })
    displayedBar = bar
end

local function Finish(now, aborted)
    local flight = active
    local seconds = now - flight.start
    active = nil
    Character().flightPathActive = nil
    StopBar(true)
    lastFlight = { route = flight, elapsed = seconds }
    if not (aborted or flight.interrupted or flight.noLearning)
        and flight.key and seconds >= 1 and ValidTime(seconds) and ReachedDestination(flight) then
        local variants = Child(Child(Character(), "flightPathTimes"), flight.key)
        variants[flight.variant] = floor(seconds * 10 + 0.5) / 10
    end
end

-- The snapshot lives in the existing per-character SavedVariables root. Only
-- reloads extend the saved elapsed time across the client-side loading screen.
local function SaveActive(now)
    if not active then return end
    local snapshot = {}
    for key, value in pairs(active) do snapshot[key] = value end
    snapshot.elapsed = max(0, now - active.start)
    snapshot.savedAt = now
    snapshot.version = SNAPSHOT_VERSION
    snapshot.start, snapshot.groundAt = nil, nil
    Character().flightPathActive = snapshot
end

local function RestoreActive(now)
    local saved = resume.saved
    if resume.reloading then
        saved.elapsed = saved.elapsed + max(0, now - saved.savedAt)
    else
        saved.approximate, saved.noLearning = true, true
    end
    saved.start = now - saved.elapsed
    saved.elapsed, saved.savedAt, saved.version = nil, nil, nil
    active = saved
    resume = nil
    SaveActive(now)
end

local function CheckFlight(allowUnknown)
    if not inWorld then return end
    local now, airborne = GetTime(), IsOnTaxi()
    if pending and now > pending.deadline then pending = nil end
    if resume and now > resume.deadline then
        Character().flightPathActive, resume = nil, nil
    end

    if active then
        if airborne then
            active.groundAt = nil
            PaintBar()
        elseif airborne == false then
            active.groundAt = active.groundAt or now
            if now - active.groundAt >= LAND_GRACE then Finish(active.groundAt) end
        end
    elseif airborne then
        if resume then
            RestoreActive(now)
        elseif pending then
            active = pending.flight
            active.start = now
            pending = nil
            SaveActive(now)
        elseif allowUnknown then
            active = { start = now, noLearning = true }
        end
        if active then PaintBar() end
    end
end

local accum = 0
local function OnUpdate(self, elapsed)
    accum = accum + elapsed
    if accum < TICK then return end
    accum = accum % TICK
    CheckFlight()
    if not (active or pending or resume) then self:SetScript("OnUpdate", nil) end
end

local function Wake(allowUnknown)
    CheckFlight(allowUnknown)
    if active or pending or resume then events:SetScript("OnUpdate", OnUpdate) end
end

local function TakeNode(index)
    index = Readable(index)
    if not index or active or not IsEnabled() then return end
    local route = GetRoute(index)
    if resume then
        -- Choosing a new route proves the saved taxi is no longer active.
        Character().flightPathActive, resume = nil, nil
    end
    if not route then
        pending = { flight = {}, deadline = GetTime() + BOARD_WINDOW }
        Wake()
        return
    end
    local flight = {}
    for key, value in pairs(route) do
        if key ~= "legs" and key ~= "sourceSlot" then flight[key] = value end
    end
    local duration, source = GetDuration(route)
    flight.duration = duration
    flight.approximate = source == "estimate"
    local dest = slots[index]
    flight.destMap = dest.map
    flight.destContinent, flight.destX, flight.destY = WorldPosition(dest.map, dest.position)
    pending = { flight = flight, deadline = GetTime() + BOARD_WINDOW }
    Wake()
end

local function AddTooltipTime(index)
    if not IsEnabled("enableFlightPathTooltips") then return end
    local tooltip = GameTooltip
    if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
    local seconds, source = FP.GetFlightTime(index)
    if seconds then
        tooltip:AddLine((source == "estimate" and "~" or "") .. FormatDuration(seconds), 1, 1, 1)
    else
        tooltip:AddLine("Time unknown", 0.5, 0.5, 0.5)
    end
    tooltip:Show()
end

local function OnFlightPinEnter(pin)
    local data = pin.taxiNodeData
    if not (data and Enum and Enum.FlightPathState)
        or Readable(data.isMapLayerTransition)
        or Readable(data.state) ~= Enum.FlightPathState.Reachable then return end
    local index = Readable(data.slotIndex)
    if index then AddTooltipTime(index) end
end

local pinTemplate = "FlightMap_FlightPointPinTemplate"
local hookedPins = setmetatable({}, { __mode = "k" })
local function HookFlightPins(map)
    local uiMapID = map:GetMapID()
    for pin in map:EnumeratePinsByTemplate(pinTemplate) do
        if slots and pin.taxiNodeData then AddNode(pin.taxiNodeData, uiMapID) end
        if not hookedPins[pin] then
            hookedPins[pin] = true
            pin:HookScript("OnEnter", OnFlightPinEnter)
        end
    end
end

local mapHooked, legacyHooked
local function HookMaps()
    if not hooksecurefunc then return end
    if not legacyHooked and TaxiNodeOnButtonEnter then
        legacyHooked = true
        hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
            local index = button and button:GetID()
            if index and (not TaxiNodeGetType or Readable(TaxiNodeGetType(index)) == "REACHABLE") then
                AddTooltipTime(index)
            end
        end)
    end
    local map = FlightMapFrame
    if not mapHooked and map and map.EnumeratePinsByTemplate
        and map.OnMapChanged and map.RefreshAllDataProviders then
        mapHooked = true
        hooksecurefunc(map, "OnMapChanged", HookFlightPins)
        hooksecurefunc(map, "RefreshAllDataProviders", HookFlightPins)
        HookFlightPins(map)
    end
end

local function Print(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffFluxUI|r Flight: " .. msg) end
end

local function HandleSlash(msg)
    local cmd, args = msg:lower():match("^%s*(%S+)%s*(.-)%s*$")
    if cmd == "save" then
        local from, to, seconds = args:match("^(%d+)%s+(%d+)%s+(%d+)$")
        if FP.SetOverride(from, to, seconds) then
            Print(string.format("Saved override %s to %s = %ss", from, to, seconds))
        else
            Print("Usage: /fluxfp save <srcNodeID> <destNodeID> <seconds>")
        end
    elseif cmd == "clear" then
        local from, to = args:match("^(%d+)%s+(%d+)$")
        if FP.ClearOverride(from, to) then
            Print(string.format("Cleared override %s to %s", from, to))
        else
            Print("Usage: /fluxfp clear <srcNodeID> <destNodeID>")
        end
    elseif cmd == "list" then
        local faction = Faction()
        local overrides = Child(Child(Account(), "overrides"), faction)
        local count = 0
        for from, row in pairs(overrides) do
            if type(row) == "table" then
                for to, seconds in pairs(row) do
                    if type(to) == "number" and ValidTime(seconds) then
                        count = count + 1
                        Print(string.format("[%s] %s to %s = %s (%ss)", faction,
                            FP.GetNodeName(from) or from, FP.GetNodeName(to) or to, FormatDuration(seconds), seconds))
                    end
                end
            end
        end
        if count == 0 then Print("No overrides saved.") end
    elseif cmd == "measure" then
        local flight = active or lastFlight and lastFlight.route
        if flight then
            local seconds = active and GetTime() - active.start or lastFlight.elapsed
            Print(string.format("Last route %s to %s: measured ~%ss, expected %s",
                flight.fromName or flight.from or "?", flight.toName or flight.to or "?",
                floor(seconds + 0.5), flight.duration and (FormatDuration(flight.duration)) or "unknown"))
        else
            Print("No recent flight recorded.")
        end
    elseif not cmd or cmd == "help" then
        Print("/fluxfp save <src> <dest> <seconds> | clear <src> <dest> | list | measure")
    else
        Print("Unknown command. /fluxfp help")
    end
end

SLASH_FLUXFLIGHTPATH1 = "/fluxfp"
SlashCmdList.FLUXFLIGHTPATH = HandleSlash

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("TAXIMAP_OPENED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_CONTROL_LOST")
events:RegisterEvent("PLAYER_CONTROL_GAINED")
events:RegisterEvent("PLAYER_DEAD")
events:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_FlightMap" or arg1 == "Blizzard_TaxiUI" then HookMaps() end
    elseif event == "TAXIMAP_OPENED" then
        HookMaps()
        if IsEnabled() then
            CaptureMap()
            if mapHooked then HookFlightPins(FlightMapFrame) end
        else
            slots, current = nil, nil
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        inWorld = true
        if not enteredWorld then
            enteredWorld = true
            local saved = _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.flightPathActive
            if type(saved) == "table" and saved.version == SNAPSHOT_VERSION and type(saved.elapsed) == "number"
                and saved.elapsed >= 0 and saved.elapsed < MAX_FLIGHT and type(saved.savedAt) == "number" then
                resume = { saved = saved, reloading = arg2, deadline = GetTime() + RESUME_WINDOW }
            elseif saved ~= nil then
                Character().flightPathActive = nil
            end
        end
        Wake(IsEnabled())
    elseif event == "PLAYER_LEAVING_WORLD" then
        inWorld = nil
        slots, nodeHash, routes, current = nil, nil, nil, nil
        if active then active.groundAt = nil end
        self:SetScript("OnUpdate", nil)
    elseif event == "PLAYER_LOGOUT" then
        if active and active.groundAt then
            Finish(active.groundAt)
        elseif active then
            SaveActive(GetTime())
        end
    elseif event == "PLAYER_DEAD" then
        if active then Finish(GetTime(), true) end
        pending = nil
    elseif active or pending or resume then
        Wake()
    end
end)

HookMaps()
if hooksecurefunc and TakeTaxiNode then hooksecurefunc("TakeTaxiNode", TakeNode) end
if hooksecurefunc and TaxiRequestEarlyLanding then
    hooksecurefunc("TaxiRequestEarlyLanding", function()
        if not active then return end
        active.interrupted, active.duration = true, nil
        StopBar()
        Wake()
    end)
end
