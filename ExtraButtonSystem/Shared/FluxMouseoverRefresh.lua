--[[
  FluxMouseoverRefresh — coalesce UPDATE_MOUSEOVER_UNIT driven usable/macro work.

  API:
    FluxMouseoverRefresh.Request(flushKey, callback)
    FluxMouseoverRefresh.GetInterval()
    FluxMouseoverRefresh.UnitChanged()
    FluxMouseoverRefresh.GetStats()
    FluxMouseoverRefresh.NotifyMouseoverEvent()
    FluxMouseoverRefresh.RefreshGlobalPresence()
    FluxMouseoverRefresh.ShouldSkipBackgroundRangePoll()
    FluxMouseoverRefresh.ReindexAll()
]]

FluxMouseoverRefresh = FluxMouseoverRefresh or {}
local M = FluxMouseoverRefresh

M.stats = M.stats or {
    requests = 0,
    coalesced = 0,
    skippedSameUnit = 0,
    skippedNoMacros = 0,
    flushes = 0,
    lastFlushAt = 0,
}

M.hasMouseoverMacros = M.hasMouseoverMacros or false
M.hasMouseoverCast = M.hasMouseoverCast or false

local pendingCallbacks = {}
local subscribers = {}
local scheduled = false
local lastFlushedGUID = nil
local lastFlushedReaction = nil
local lastMouseoverEventAt = 0

local DEFAULT_INTERVAL = 0.07

local function GetAPI()
    return FluxAPICompat and FluxAPICompat.API
end

local function MouseoverReactionClass()
    local fn = _G.FluxMouseoverReactionClass
    if type(fn) == "function" then
        local ok, cls = pcall(fn)
        if ok and type(cls) == "string" then
            return cls
        end
    end
    if not UnitExists or not UnitExists("mouseover") then
        return "-"
    end
    if UnitIsDead and UnitIsDead("mouseover") then
        return "d"
    end
    if UnitCanAttack and UnitCanAttack("player", "mouseover") then
        return "e"
    end
    if UnitCanAssist and UnitCanAssist("player", "mouseover") then
        return "f"
    end
    return "o"
end

local function GetMouseoverGUID()
    local API = GetAPI()
    if API and API.AccessibleGUIDForUnit then
        return API.AccessibleGUIDForUnit("mouseover")
    end
    if not UnitExists or not UnitExists("mouseover") then
        return nil
    end
    if UnitGUID then
        return UnitGUID("mouseover")
    end
    return UnitExists("mouseover") and "exists" or nil
end

local function MouseoverGUIDChanged(prev, nextGUID)
    local API = GetAPI()
    if API and API.SafeGUIDChangedForRefresh then
        return API.SafeGUIDChangedForRefresh(prev, nextGUID)
    end
    if prev == nil and nextGUID == nil then
        return false
    end
    return prev ~= nextGUID
end

local function SameMouseoverGUID(a, b)
    local API = GetAPI()
    if API and API.SafeGUIDsEqual then
        return API.SafeGUIDsEqual(a, b) == true
    end
    return a ~= nil and a == b
end

function M.GetInterval()
    local g = tonumber(_G.FluxMouseoverUpdateInterval)
    if g and g > 0 then
        return g
    end
    return DEFAULT_INTERVAL
end

function M.UnitChanged()
    local guid = GetMouseoverGUID()
    if guid == nil and lastFlushedGUID == nil then
        return false
    end
    return MouseoverGUIDChanged(lastFlushedGUID, guid)
end

function M.NotifyMouseoverEvent()
    lastMouseoverEventAt = GetTime()
end

function M.GetLastMouseoverEventAt()
    return lastMouseoverEventAt
end

function M.IsRecentMouseoverBurst(withinSec)
    withinSec = tonumber(withinSec) or 0.1
    return (GetTime() - lastMouseoverEventAt) <= withinSec
end

local function MouseoverCastEnabled()
    local MOC = _G.FluxMouseoverCast or _G.FluxMouseoverCastModule
    if MOC then
        if type(MOC.GetEnabled) == "function" then
            local ok, enabled = pcall(MOC.GetEnabled, MOC)
            return ok and enabled and true or false
        end
        if type(MOC.IsEnabled) == "function" then
            local ok, enabled = pcall(MOC.IsEnabled, MOC)
            return ok and enabled and true or false
        end
    end
    -- Fallback: Action Bars DB / char saved vars (same source as FluxMouseoverCast).
    if FluxOptions and FluxOptions.GetActionbarsDB then
        local t = FluxOptions:GetActionbarsDB()
        if t and t.mouseoverCast ~= nil then
            return t.mouseoverCast == true
        end
    end
    if _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.mouseoverCast ~= nil then
        return _FluxUI_CharSavedVars.mouseoverCast == true
    end
    return false
end

--- True when at least one action-bar or extra-button slot has a @mouseover macro,
--- Binding hovercast badge, or global mouseover cast is enabled.
function M.RefreshGlobalPresence()
    local hasAny = false

    local lib = LibStub and LibStub("LibActionButton-1.0", true)
    if lib and lib.fluxMouseoverMacroButtons then
        for _ in next, lib.fluxMouseoverMacroButtons do
            hasAny = true
            break
        end
    end

    if not hasAny and FluxButtonEvents and FluxButtonEvents.mouseoverMacroButtons then
        for _ in next, FluxButtonEvents.mouseoverMacroButtons do
            hasAny = true
            break
        end
    end

    if not hasAny and FluxButtonEvents and FluxButtonEvents.badgeButtons then
        for i = 1, #FluxButtonEvents.badgeButtons do
            local badge = FluxButtonEvents.badgeButtons[i]
            if badge and type(badge._fluxHoverMacroBody) == "string" and badge._fluxHoverMacroBody ~= "" then
                hasAny = true
                break
            end
        end
    end

    M.hasMouseoverCast = MouseoverCastEnabled()
    M.hasMouseoverMacros = hasAny or M.hasMouseoverCast
    _G.FluxHasMouseoverMacroButtons = M.hasMouseoverMacros
    return M.hasMouseoverMacros
end

--- OOC raid-frame hover: coalescer owns @mouseover macro tint; skip full rangeButton polls
--- only when mouseover macros exist AND there is no hard attackable target to keep ranging.
--- With FluxMouseoverCast enabled we still poll (unit attribute drives LAB range).
function M.ShouldSkipBackgroundRangePoll()
    if M.hasMouseoverCast then
        return false
    end
    if not M.hasMouseoverMacros then
        return false
    end
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    if UnitExists("target") and UnitCanAttack and UnitCanAttack("player", "target") then
        return false
    end
    return UnitExists("mouseover") == true
end

function M.ReindexAll()
    local lib = LibStub and LibStub("LibActionButton-1.0", true)
    if lib and lib.ReindexMouseoverMacroButtons then
        lib:ReindexMouseoverMacroButtons()
    end
    if FluxButtonEvents and FluxButtonEvents.ActiveButtons then
        for i = 1, #FluxButtonEvents.ActiveButtons do
            if FluxButtonEvents.RefreshMouseoverMacroMembership then
                FluxButtonEvents.RefreshMouseoverMacroMembership(FluxButtonEvents.ActiveButtons[i])
            end
        end
    end
    M.RefreshGlobalPresence()
end

local function ForceRangeRefresh()
    -- Mirror Binding Apply: don't re-arm LAB/Extra range when nothing can change.
    local hasUnit = UnitExists("target") or UnitExists("mouseover")
    local lib = LibStub and LibStub("LibActionButton-1.0", true)
    local anyOOR = lib and lib._fluxAnyOutOfRange
    if not hasUnit and not anyOOR then
        return
    end
    -- Coalesce range sample on mouseover sweeps (LAB owns trailing sample).
    if lib and lib.UpdateRangeTimerCoalesced then
        pcall(lib.UpdateRangeTimerCoalesced)
    elseif lib and lib.UpdateRangeTimer then
        pcall(lib.UpdateRangeTimer)
    end
    if FluxButtonEvents and FluxButtonEvents.ForceRangeRefresh then
        pcall(FluxButtonEvents.ForceRangeRefresh)
    end
end

local function RunFlush()
    scheduled = false
    local now = GetTime()
    local interval = M.GetInterval()
    local sinceLast = now - (M.stats.lastFlushAt or 0)
    if sinceLast < interval then
        M.stats.coalesced = M.stats.coalesced + 1
        local wait = interval - sinceLast
        if C_Timer and C_Timer.After then
            scheduled = true
            C_Timer.After(wait, RunFlush)
        end
        return
    end

    if not M.hasMouseoverMacros and not M.RefreshGlobalPresence() then
        M.stats.skippedNoMacros = M.stats.skippedNoMacros + 1
        pendingCallbacks = {}
        -- Still clear OOR when mouseover drops even with no macros if cast was on.
        ForceRangeRefresh()
        return
    end

    local guid = GetMouseoverGUID()
    local reaction = MouseoverReactionClass()
    -- Same reaction class (e.g. sweeping friendly players): skip TranslateMacro;
    -- still coalesce a range sample for distance changes.
    if reaction ~= "-" and reaction == lastFlushedReaction then
        M.stats.skippedSameUnit = M.stats.skippedSameUnit + 1
        pendingCallbacks = {}
        lastFlushedGUID = guid
        ForceRangeRefresh()
        return
    end
    if guid ~= nil and SameMouseoverGUID(guid, lastFlushedGUID) then
        M.stats.skippedSameUnit = M.stats.skippedSameUnit + 1
        pendingCallbacks = {}
        return
    end

    M.stats.flushes = M.stats.flushes + 1
    M.stats.lastFlushAt = now
    lastFlushedGUID = guid
    lastFlushedReaction = reaction

    _G.FluxLABMouseoverFlushActive = true
    for _, fn in pairs(pendingCallbacks) do
        if type(fn) == "function" then
            pcall(fn)
        end
    end
    pendingCallbacks = {}
    ForceRangeRefresh()
    _G.FluxLABMouseoverFlushActive = nil
end

function M.Register(key, callback)
    if type(key) == "string" and type(callback) == "function" then
        subscribers[key] = callback
    end
end

function M.Unregister(key)
    subscribers[key] = nil
    pendingCallbacks[key] = nil
end

function M.Request(flushKey, callback)
    if type(callback) ~= "function" then
        return
    end
    M.stats.requests = M.stats.requests + 1
    pendingCallbacks[flushKey or callback] = callback

    if scheduled then
        M.stats.coalesced = M.stats.coalesced + 1
        return
    end

    scheduled = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0, RunFlush)
    else
        RunFlush()
    end
end

function M.GetStats()
    return M.stats
end

function M.ResetStats()
    M.stats.requests = 0
    M.stats.coalesced = 0
    M.stats.skippedSameUnit = 0
    M.stats.skippedNoMacros = 0
    M.stats.flushes = 0
end

local umuFrame = CreateFrame("Frame")
umuFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
umuFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
umuFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        if C_Timer and C_Timer.After then
            C_Timer.After(1, function()
                M.ReindexAll()
            end)
        else
            M.ReindexAll()
        end
        return
    end

    M.NotifyMouseoverEvent()

    -- Mouse left a unit: clear last GUID and force range clear/refresh.
    if not UnitExists("mouseover") then
        lastFlushedGUID = nil
        lastFlushedReaction = nil
        ForceRangeRefresh()
    end

    if not M.RefreshGlobalPresence() then
        M.stats.skippedNoMacros = M.stats.skippedNoMacros + 1
        return
    end

    local guid = GetMouseoverGUID()
    local reaction = MouseoverReactionClass()
    if reaction ~= "-" and reaction == lastFlushedReaction then
        M.stats.skippedSameUnit = M.stats.skippedSameUnit + 1
        ForceRangeRefresh()
        return
    end
    if guid ~= nil and SameMouseoverGUID(guid, lastFlushedGUID) then
        M.stats.skippedSameUnit = M.stats.skippedSameUnit + 1
        return
    end

    for _, cb in pairs(subscribers) do
        M.Request(nil, cb)
    end
end)

_G.FluxMouseoverRefresh = M
