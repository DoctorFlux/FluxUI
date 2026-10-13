-- UnitFrames/FluxFlightPath.lua
-- Flight path timers: taxi map tooltips + player cast bar progress during flights.
-- Flight times sourced from RestedXP Guides (CC BY-NC-SA 4.0), adapted for FluxUI.
local addonName, ns = ...
ns.FlightPath = ns.FlightPath or {}
local FP = ns.FlightPath
local CB = ns.CastBar

local FLIGHT_ICON = "Interface\\ICONS\\INV_Misc_PocketWatch_02"
local MEASURE_THRESHOLD = 5
local TAKEOFF_WINDOW = 1.5

local flightInfo = {}
local nodeHash = {}
flightInfo.nodeHash = nodeHash

local pendingSave = nil

-- ---------------------------------------------------------------------------
-- Settings / DB
-- ---------------------------------------------------------------------------

local function EnsureFlightPathDB()
    FluxUI_DB = FluxUI_DB or {}
    FluxUI_DB.flightPath = FluxUI_DB.flightPath or {}
    FluxUI_DB.flightPath.overrides = FluxUI_DB.flightPath.overrides or {}
    FluxUI_DB.flightPath.overrides.Horde = FluxUI_DB.flightPath.overrides.Horde or {}
    FluxUI_DB.flightPath.overrides.Alliance = FluxUI_DB.flightPath.overrides.Alliance or {}
    return FluxUI_DB.flightPath
end

local function EnsureCharNodeNames()
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    _FluxUI_CharSavedVars.flightPathNodes = _FluxUI_CharSavedVars.flightPathNodes or {}
    return _FluxUI_CharSavedVars.flightPathNodes
end

local function GetPlayerFactionKey()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Horde" or faction == "Alliance" then
        return faction
    end
    return "Alliance"
end

local function IsFeatureEnabled()
    if FluxUnitFrames_IsFeatureEnabled then
        return FluxUnitFrames_IsFeatureEnabled("flightPathTimers")
    end
    return true
end

local function IsCastBarEnabled()
    if not IsFeatureEnabled() then
        return false
    end
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if db and db.enableFlightPathCastBar == false then
        return false
    end
    return true
end

local function IsTooltipEnabled()
    if not IsFeatureEnabled() then
        return false
    end
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if db and db.enableFlightPathTooltips == false then
        return false
    end
    return true
end

local function GetStaticFPDB()
    return ns.FlightPathData and ns.FlightPathData.FPDB
end

local function GetOverrideTable(faction)
    local db = EnsureFlightPathDB()
    return db.overrides[faction]
end

local function LookupLegTime(faction, src, dest)
    if not src or not dest then
        return nil
    end
    local overrides = GetOverrideTable(faction)
    local time = overrides[src] and overrides[src][dest]
        or overrides[dest] and overrides[dest][src]
    if time then
        return time
    end
    local FPDB = GetStaticFPDB()
    local static = FPDB and FPDB[faction]
    if not static then
        return nil
    end
    return static[src] and static[src][dest]
        or static[dest] and static[dest][src]
end

function FP.GetNodeName(nodeID)
    if not nodeID then
        return nil
    end
    local names = EnsureCharNodeNames()
    if names[nodeID] then
        return names[nodeID]
    end
    local faction = GetPlayerFactionKey()
    local FPDB = GetStaticFPDB()
    local entry = FPDB and FPDB[faction] and FPDB[faction][nodeID]
    if entry and entry.name then
        return entry.name
    end
    return nil
end

function FP.GetFlightTimeForNodes(src, dest)
    return LookupLegTime(GetPlayerFactionKey(), src, dest)
end

function FP.SetOverride(src, dest, seconds)
    src = tonumber(src)
    dest = tonumber(dest)
    seconds = tonumber(seconds)
    if not src or not dest or not seconds or seconds <= 0 then
        return false
    end
    local faction = GetPlayerFactionKey()
    local overrides = GetOverrideTable(faction)
    overrides[src] = overrides[src] or {}
    overrides[src][dest] = math.floor(seconds + 0.5)
    return true
end

function FP.ClearOverride(src, dest)
    src = tonumber(src)
    dest = tonumber(dest)
    if not src or not dest then
        return false
    end
    local faction = GetPlayerFactionKey()
    local overrides = GetOverrideTable(faction)
    if overrides[src] then
        overrides[src][dest] = nil
    end
    if overrides[dest] then
        overrides[dest][src] = nil
    end
    return true
end

local function FormatFlightDuration(seconds)
    seconds = math.floor(tonumber(seconds) or 0)
    if seconds < 0 then seconds = 0 end
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function FormatRouteLabel(srcID, destID)
    local srcName = FP.GetNodeName(srcID) or tostring(srcID or "?")
    local destName = FP.GetNodeName(destID) or tostring(destID or "?")
    return srcName, destName
end

-- ---------------------------------------------------------------------------
-- Taxi map mapping (ported from RXPGuides Timers.lua)
-- ---------------------------------------------------------------------------

function FP.GetFlightHash(index, level)
    local x, y
    if level then
        x, y = TaxiGetDestX(index, level), TaxiGetDestY(index, level)
    else
        x, y = TaxiNodePosition(index)
    end
    if not x or not y then
        return nil
    end
    return math.floor(x * 4096) + math.floor(y * 4096) * 4096
end

local function GetFlightTime(index)
    local faction = GetPlayerFactionKey()
    local hash = FP.GetFlightHash(index)
    local dest = hash and flightInfo.nodeHash[hash]
    local src = flightInfo.currentFP
    flightInfo.dest = dest
    flightInfo.activeIndex = index

    if not src or not dest then
        flightInfo.timer = nil
        return nil
    end

    local time = LookupLegTime(faction, src, dest)
    if time then
        flightInfo.timer = time
        return time
    end

    if not GetNumRoutes then
        flightInfo.timer = nil
        return nil
    end

    local totalTime = 0
    local legSrc = src
    for i = 1, GetNumRoutes(index) do
        local legHash = FP.GetFlightHash(index, i)
        local legDest = legHash and flightInfo.nodeHash[legHash]
        time = LookupLegTime(faction, legSrc, legDest)
        if time then
            totalTime = totalTime + time
        else
            totalTime = 0
            break
        end
        legSrc = legDest
    end

    if totalTime > 0 then
        flightInfo.timer = totalTime
        return totalTime
    end

    flightInfo.timer = nil
    return nil
end

local function OnTaxiMapOpened()
    if not C_TaxiMap or not C_TaxiMap.GetAllTaxiNodes or not C_Map or not C_Map.GetBestMapForUnit then
        return
    end
    local mapID = C_Map.GetBestMapForUnit("player")
    local cTime = GetTime()
    if mapID and cTime - (flightInfo.flightUpdate or 0) > 1 then
        flightInfo.flightUpdate = cTime
        local preservedStart = flightInfo.startFlight
        local preservedWasOnTaxi = flightInfo.wasOnTaxi
        local preservedLastSrc = flightInfo.lastFlightSrc
        local preservedLastDest = flightInfo.lastFlightDest
        table.wipe(nodeHash)
        for k in pairs(flightInfo) do
            if k ~= "nodeHash" and k ~= "flightUpdate" then
                flightInfo[k] = nil
            end
        end
        flightInfo.nodeHash = nodeHash
        flightInfo.startFlight = preservedStart
        flightInfo.wasOnTaxi = preservedWasOnTaxi
        flightInfo.lastFlightSrc = preservedLastSrc
        flightInfo.lastFlightDest = preservedLastDest

        local FPList = C_TaxiMap.GetAllTaxiNodes(mapID)
        local names = EnsureCharNodeNames()
        local unreachable = Enum and Enum.FlightPathState and Enum.FlightPathState.Unreachable
        local currentState = Enum and Enum.FlightPathState and Enum.FlightPathState.Current

        for _, v in pairs(FPList) do
            local id = v.nodeID
            if id and (not unreachable or v.state ~= unreachable) then
                local hash = FP.GetFlightHash(v.slotIndex)
                if hash then
                    flightInfo.nodeHash[hash] = id
                end
                if v.name then
                    names[id] = v.name
                end
                flightInfo[v.slotIndex] = id
                if currentState and v.state == currentState then
                    flightInfo.currentFP = id
                end
            end
        end
    end
    flightInfo.MapID = mapID
end

local function GetPlayerCastBar()
    local frame = ns.PlayerFrame
    return frame and frame.CastBar
end

local function StopFlightCastBar(fade)
    local castBar = GetPlayerCastBar()
    if castBar and CB and CB.StopCustomTimer then
        CB.StopCustomTimer(castBar, fade and { fade = true } or nil)
    end
end

local function StartFlightCastBar()
    if not IsCastBarEnabled() then
        return
    end
    local duration = flightInfo.timer
    if not duration or duration <= 0 then
        return
    end
    local castBar = GetPlayerCastBar()
    if not castBar or not CB or not CB.StartCustomTimer then
        return
    end
    local srcID = flightInfo.lastFlightSrc or flightInfo.currentFP
    local destID = flightInfo.lastFlightDest or flightInfo.dest
    local fromName, toName = FormatRouteLabel(srcID, destID)
    CB.StartCustomTimer(castBar, {
        kind = "flight",
        fromName = fromName,
        toName = toName,
        icon = FLIGHT_ICON,
        duration = duration,
        startTime = flightInfo.startFlight or GetTime(),
    })
end

local function OfferSaveMeasuredTime(src, dest, measured, expected)
    pendingSave = {
        src = src,
        dest = dest,
        measured = measured,
        expected = expected,
    }
    local srcName = FP.GetNodeName(src) or tostring(src)
    local destName = FP.GetNodeName(dest) or tostring(dest)
    local measuredText = FormatFlightDuration(measured)
    local body
    if expected then
        body = string.format(
            "Measured %s for %s to %s.\nDatabase has %s.\nSave measured time as override?",
            measuredText, srcName, destName, FormatFlightDuration(expected)
        )
    else
        body = string.format(
            "Measured %s for %s to %s.\nNo database entry found.\nSave as override?",
            measuredText, srcName, destName
        )
    end
    StaticPopupDialogs["FLUX_FLIGHT_SAVE_TIME"] = StaticPopupDialogs["FLUX_FLIGHT_SAVE_TIME"] or {
        text = "%s",
        button1 = SAVE or "Save",
        button2 = CANCEL or "Skip",
        OnAccept = function()
            if pendingSave then
                FP.SetOverride(pendingSave.src, pendingSave.dest, pendingSave.measured)
                pendingSave = nil
            end
        end,
        OnCancel = function()
            pendingSave = nil
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("FLUX_FLIGHT_SAVE_TIME", body)
end

local function EvaluateMeasuredFlight()
    local src = flightInfo.lastFlightSrc
    local dest = flightInfo.lastFlightDest
    local start = flightInfo.startFlight
    if not src or not dest or not start then
        return
    end
    local measured = GetTime() - start
    if measured < MEASURE_THRESHOLD then
        return
    end
    measured = math.floor(measured + 0.5)
    local expected = FP.GetFlightTimeForNodes(src, dest)
    if not expected or math.abs(measured - expected) >= MEASURE_THRESHOLD then
        OfferSaveMeasuredTime(src, dest, measured, expected)
    end
end

local function OnPlayerControlLost()
    if not flightInfo.startFlight then
        return
    end
    if GetTime() - flightInfo.startFlight > TAKEOFF_WINDOW then
        return
    end
    flightInfo.lastFlightSrc = flightInfo.currentFP
    flightInfo.lastFlightDest = flightInfo.dest
    StartFlightCastBar()
end

local function OnPlayerControlGained()
    StopFlightCastBar(true)
    if flightInfo.wasOnTaxi then
        EvaluateMeasuredFlight()
    end
    flightInfo.wasOnTaxi = nil
end

-- ---------------------------------------------------------------------------
-- Hooks
-- ---------------------------------------------------------------------------

local function HookTaxiNodeTooltip()
    if not _G.hooksecurefunc or not TaxiNodeOnButtonEnter then
        return
    end
    hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
        if not IsTooltipEnabled() then
            return
        end
        if not button or not button.GetID then
            return
        end
        local index = button:GetID()
        if TaxiNodeGetType and TaxiNodeGetType(index) ~= "REACHABLE" then
            return
        end
        local time = GetFlightTime(index)
        local tooltip = _G.GameTooltip
        if not tooltip or tooltip.IsForbidden and tooltip:IsForbidden() then
            return
        end
        if time then
            tooltip:AddLine(FormatFlightDuration(time), 1, 1, 1)
        else
            tooltip:AddLine("Time unknown", 0.5, 0.5, 0.5)
        end
        tooltip:Show()
    end)
end

local function HookTakeTaxiNode()
    if not _G.hooksecurefunc or not TakeTaxiNode then
        return
    end
    flightInfo.startFlight = 0
    hooksecurefunc("TakeTaxiNode", function(index)
        if flightInfo.activeIndex ~= index then
            GetFlightTime(index)
        end
        flightInfo.startFlight = GetTime()
        flightInfo.wasOnTaxi = true
        flightInfo.lastFlightSrc = flightInfo.currentFP
        flightInfo.lastFlightDest = flightInfo.dest
    end)
end

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------

local function PrintFlightMsg(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffFluxUI|r Flight: " .. tostring(msg))
    end
end

local function TrimString(s)
    if strtrim then
        return strtrim(s or "")
    end
    return (s or ""):match("^%s*(.-)%s*$") or ""
end

local function HandleSlashCommand(msg)
    msg = TrimString(msg)
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    cmd = cmd and (strlower and strlower(cmd) or cmd:lower()) or ""

    if cmd == "" or cmd == "help" then
        PrintFlightMsg("/fluxfp save <src> <dest> <seconds> | clear <src> <dest> | list | measure")
        return
    end

    if cmd == "save" then
        local src, dest, seconds = rest:match("^(%d+)%s+(%d+)%s+(%d+)")
        if FP.SetOverride(src, dest, seconds) then
            PrintFlightMsg(string.format("Saved override %s to %s = %ss", src, dest, seconds))
        else
            PrintFlightMsg("Usage: /fluxfp save <srcNodeID> <destNodeID> <seconds>")
        end
        return
    end

    if cmd == "clear" then
        local src, dest = rest:match("^(%d+)%s+(%d+)")
        if FP.ClearOverride(src, dest) then
            PrintFlightMsg(string.format("Cleared override %s to %s", src, dest))
        else
            PrintFlightMsg("Usage: /fluxfp clear <srcNodeID> <destNodeID>")
        end
        return
    end

    if cmd == "list" then
        local faction = GetPlayerFactionKey()
        local overrides = GetOverrideTable(faction)
        local count = 0
        for src, dests in pairs(overrides) do
            if type(dests) == "table" then
                for dest, seconds in pairs(dests) do
                    if type(dest) == "number" and type(seconds) == "number" then
                        count = count + 1
                        PrintFlightMsg(string.format("[%s] %s to %s = %s (%ss)",
                            faction,
                            FP.GetNodeName(src) or src,
                            FP.GetNodeName(dest) or dest,
                            FormatFlightDuration(seconds),
                            seconds))
                    end
                end
            end
        end
        if count == 0 then
            PrintFlightMsg("No overrides saved.")
        end
        return
    end

    if cmd == "measure" then
        local src = flightInfo.lastFlightSrc
        local dest = flightInfo.lastFlightDest
        local start = flightInfo.startFlight
        if not src or not dest or not start then
            PrintFlightMsg("No recent flight recorded.")
            return
        end
        local measured = math.floor(GetTime() - start + 0.5)
        local expected = FP.GetFlightTimeForNodes(src, dest)
        PrintFlightMsg(string.format(
            "Last route %s to %s: measured ~%ss, DB %s",
            FP.GetNodeName(src) or src,
            FP.GetNodeName(dest) or dest,
            measured,
            expected and (tostring(expected) .. "s") or "unknown"
        ))
        return
    end

    PrintFlightMsg("Unknown command. /fluxfp help")
end

SLASH_FLUXFLIGHTPATH1 = "/fluxfp"
SlashCmdList["FLUXFLIGHTPATH"] = HandleSlashCommand

-- ---------------------------------------------------------------------------
-- Event frame
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TAXIMAP_OPENED")
eventFrame:RegisterEvent("PLAYER_CONTROL_LOST")
eventFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "TAXIMAP_OPENED" then
        OnTaxiMapOpened()
    elseif event == "PLAYER_CONTROL_LOST" then
        OnPlayerControlLost()
    elseif event == "PLAYER_CONTROL_GAINED" then
        OnPlayerControlGained()
    end
end)

HookTaxiNodeTooltip()
HookTakeTaxiNode()

FP.flightInfo = flightInfo
FP.GetFlightTime = GetFlightTime
FP.FormatDuration = FormatFlightDuration
