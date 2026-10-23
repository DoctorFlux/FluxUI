-- Protected unit infrastructure joins Core's early secure phase. In particular,
-- Forever keeps Core's VARIABLES_LOADED/gamepad barrier before creating buttons.
local addonName, ns = ...
local UF = ns.UnitFrames
local Flux = ns.Flux or _G.Flux
local entries = {}
local fields = {
    player = "PlayerFrame", target = "TargetFrame", focus = "FocusFrame",
    focustarget = "FocusTargetFrame", targettarget = "TargetOfTargetFrame",
    pet = "PetFrame", pettarget = "PetTargetFrame",
}

local function MarkVisibility()
    local startup = Flux.Startup
    if not startup or (startup.IsRecording and not startup.IsRecording()) then return end
    local player = ns.PlayerFrame
    if not UF.IsInitialized("player") or not player:IsShown() then return end
    startup.Mark("unit.player.visible")
    for unit, entry in pairs(entries) do
        local supported = not ((unit == "focus" or unit == "focustarget")
            and Flux.Cap and Flux.Cap.hasFocusUnit == false)
        local enabled = not FluxUnitFrames_ShouldUseFlux or FluxUnitFrames_ShouldUseFlux(unit)
        if supported and enabled and not entry.complete then return end
    end
    startup.Mark("essential_unit_frames_visible")
end

function UF.DeferProtected(key, callback)
    Flux.Combat.Defer("unitframes." .. key, callback)
end

function UF.IsInitialized(unit)
    local entry = entries[unit]
    return entry and entry.complete and ns[fields[unit]] ~= nil or false
end

function UF.RunInitializer(unit)
    local entry = entries[unit]
    if not entry then return false end
    if not Flux.securePhaseReady then return false end
    if InCombatLockdown() then
        UF.DeferProtected("init." .. unit, function() UF.RunInitializer(unit) end)
        return false
    end
    if not entry.complete or not ns[fields[unit]] then
        entry.complete = nil
        -- Exceptions propagate to Core.Safecall; incomplete modules remain retryable.
        entry.initialize()
        if not entry.isComplete() then return false end
        entry.complete = true
    end
    local frame = ns[fields[unit]]
    if frame then
        if FluxUnitFrames_SuppressBlizzardUnitFrame then
            FluxUnitFrames_SuppressBlizzardUnitFrame(unit)
        end
        if Flux.Startup then
            Flux.Startup.Mark("unit." .. unit .. ".secure_ready")
            MarkVisibility()
        end
    end
    return true
end

function UF.RegisterInitializer(unit, initialize, isComplete, priority)
    entries[unit] = { initialize = initialize, isComplete = isComplete }
    Flux.Module.Register("UnitFrame." .. unit, {
        phase = "secure", protected = true, priority = priority,
        capabilities = (unit == "focus" or unit == "focustarget") and { "hasFocusUnit" } or nil,
        OnEnable = function() return UF.RunInitializer(unit) end,
    })
end
