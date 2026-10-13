-- Events.lua — safe event registration (modern clients only)
local addonName, ns = ...
local H = ns._FluxAPICompat
local _pcall = H.pcall

local isRetail = FLUX_API.isRetail
local isClassicEra = FLUX_API.isClassicEra
local majorVersion = FLUX_API.majorVersion

local validatedEvents = {}
local eventProbeFrame = CreateFrame("Frame")

local OPTIONAL_EVENT_HINTS = {
    -- Retail 11.0+ removed this (LEARNED_SPELL_IN_SKILL_LINE). Do not
    -- probe-register: unknown events still hit BugSack inside pcall.
    LEARNED_SPELL_IN_TAB = function()
        if isRetail or (majorVersion and majorVersion >= 11) then
            return false
        end
        return nil
    end,
    LEARNED_SPELL_IN_SKILL_LINE = function()
        if isClassicEra and not isRetail then
            return false
        end
        return nil
    end,
}

local function ProbeEventValidity(eventName)
    if C_EventUtils and C_EventUtils.IsEventValid then
        local ok, valid = _pcall(C_EventUtils.IsEventValid, eventName)
        if ok then
            return valid == true
        end
    end
    local ok = _pcall(eventProbeFrame.RegisterEvent, eventProbeFrame, eventName)
    if ok then
        _pcall(eventProbeFrame.UnregisterEvent, eventProbeFrame, eventName)
    end
    return ok
end

local function ResolveEventValidity(eventName)
    if validatedEvents[eventName] ~= nil then
        return validatedEvents[eventName]
    end
    local hintFn = OPTIONAL_EVENT_HINTS[eventName]
    if hintFn then
        local hinted = hintFn()
        if hinted ~= nil then
            validatedEvents[eventName] = hinted
            return hinted
        end
    end
    validatedEvents[eventName] = ProbeEventValidity(eventName)
    return validatedEvents[eventName]
end

function FluxSafeRegisterEvent(frame, eventName)
    if not frame or not eventName then
        return false
    end
    if not ResolveEventValidity(eventName) then
        return false
    end
    local ok = _pcall(frame.RegisterEvent, frame, eventName)
    if not ok then
        validatedEvents[eventName] = false
    end
    return ok
end

function FluxSafeRegisterUnitEvent(frame, eventName, ...)
    if not frame or not eventName or not frame.RegisterUnitEvent then
        return false
    end
    if not ResolveEventValidity(eventName) then
        return false
    end
    local ok = _pcall(frame.RegisterUnitEvent, frame, eventName, ...)
    if not ok then
        validatedEvents[eventName] = false
    end
    return ok
end

function FluxRegisterLearnedSpellEvents(frame)
    if not frame then
        return
    end
    FluxSafeRegisterEvent(frame, "SPELLS_CHANGED")
    FluxSafeRegisterEvent(frame, "LEARNED_SPELL_IN_TAB")
    FluxSafeRegisterEvent(frame, "LEARNED_SPELL_IN_SKILL_LINE")
end

_G.FluxSafeRegisterEvent = FluxSafeRegisterEvent
_G.FluxSafeRegisterUnitEvent = FluxSafeRegisterUnitEvent
_G.FluxRegisterLearnedSpellEvents = FluxRegisterLearnedSpellEvents

H.FluxSafeRegisterEvent = FluxSafeRegisterEvent
