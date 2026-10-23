-- lua Core/_tmp_buffdebuffsmoke.lua (from the addon root; no WoW required)
-- Guard the native player unit, content visibility and overlay events across toggles.
local dir = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local wanted, combat, vehicle = true, false, false
local scheduled, created = {}, 0
local nativeCalls, alpha = 0, 1
local contentShown = true
local content = {
    IsShown = function() return contentShown end,
    Hide = function() contentShown = false end,
    Show = function() contentShown = true end,
}
local healthUpdates, manaUpdates = 0, 0
local healthUpdate = function() healthUpdates = healthUpdates + 1; error("secret health compare") end
local manaUpdate = function() manaUpdates = manaUpdates + 1; error("secret power compare") end
local nativeScripts = { health = healthUpdate, mana = manaUpdate }
local function tickNativeBars()
    -- WoW dispatches OnUpdate only when the bar and its ancestors are shown.
    if contentShown then nativeScripts.health(); nativeScripts.mana() end
end
local nativeEvents = {
    UNIT_SPELLCAST_START = { "player" },
    UNIT_SPELLCAST_STOP = { "player" },
    UNIT_HEAL_PREDICTION = { "player", "vehicle" },
    UNIT_ENTERED_VEHICLE = {},
}
local function forbidden()
    nativeCalls = nativeCalls + 1
    error("Flux touched native aura/player state", 2)
end
local nativeState = { unit = "player" }
local nativePlayer = setmetatable({}, {
    __index = function(_, key)
        if key == "SetAlpha" then
            return function(_, value) alpha = value end
        end
        if key == "unit" then return nativeState.unit end
        if key == "PlayerFrameContent" then return content end
        if key == "IsEventRegistered" then
            return function(_, event)
                local units = nativeEvents[event]
                if units then return true, table.unpack(units) end
                return false
            end
        end
        if key == "UnregisterEvent" then
            return function(_, event) nativeEvents[event] = nil end
        end
        if key == "RegisterUnitEvent" then
            return function(_, event, ...) nativeEvents[event] = { ... } end
        end
        if key == "RegisterEvent" then
            return function(_, event) nativeEvents[event] = {} end
        end
        return forbidden
    end,
    __newindex = forbidden,
})
local aura = setmetatable({}, { __index = forbidden, __newindex = forbidden })
local fluxPlayer = {
    Show = function() end,
    Hide = function() end,
}
local ns = {
    UnitFrames = {}, PlayerFrame = fluxPlayer,
    Flux = {},
}
-- This fixture starts with an already completed Flux player frame. Constructor
-- and secure-phase behavior are covered by tests/unitframes_lifecycle_spec.lua.
-- Retain the actual runtime/buff/debuff assertions below while modeling that
-- lifecycle boundary instead of invoking a full visual constructor here.
ns.UnitFrames.RegisterInitializer = function(unit, initialize, isComplete)
    assert(unit == "player" and type(initialize) == "function" and type(isComplete) == "function",
        "player must register its secure initializer")
end
ns.UnitFrames.IsInitialized = function(unit) return unit == "player" and ns.PlayerFrame == fluxPlayer end
ns.UnitFrames.DeferProtected = function(_, callback) scheduled[#scheduled + 1] = callback end
local env = setmetatable({
    PlayerFrame = nativePlayer,
    BuffFrame = aura,
    DebuffFrame = aura,
    FluxMinimap = {},
    Minimap = {},
    InCombatLockdown = function() return combat end,
    UnitClass = function() return "Rogue", "ROGUE" end,
    UnitHasVehicleUI = function() return vehicle end,
    FluxUnitFrames_ShouldUseFlux = function(unit) return unit == "player" and wanted end,
    C_Timer = { After = function(_, fn) scheduled[#scheduled + 1] = fn end },
    hooksecurefunc = forbidden,
    PlayerFrame_OnLoad = forbidden,
    PlayerFrame_Update = forbidden,
    unpack = table.unpack or unpack,
    CreateFrame = function()
        created = created + 1
        return {
            RegisterEvent = function() end,
            SetScript = function() end,
        }
    end,
}, { __index = _G })
env._G = env
local function loadAddon(path)
    local chunk
    if setfenv then
        chunk = assert(loadfile(dir .. path))
        setfenv(chunk, env)
    else
        chunk = assert(loadfile(dir .. path, "t", env))
    end
    chunk("_FluxUI", ns)
end
local function flush()
    local passes = 0
    while #scheduled > 0 do
        passes = passes + 1
        assert(passes < 20, "runtime refresh failed to settle")
        local batch = scheduled
        scheduled = {}
        for _, fn in ipairs(batch) do fn() end
    end
end

loadAddon("UnitFrames/FluxUnitFrames_Player.lua")
-- The fallback also preserves native events before the coordinator is loaded.
env.FluxUnitFrames_ApplyRuntimePlayer(true)
assert(alpha == 0, "fallback did not suppress native artwork")
env.FluxUnitFrames_ApplyRuntimePlayer(false)
assert(alpha == 1 and nativeCalls == 0, "fallback reinitialized the native player frame")
loadAddon("UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua")
for _, unit in ipairs({ "player", "vehicle", "player" }) do
    -- Simulate Blizzard switching the unit, then changing Flux settings.
    nativeState.unit = unit
    wanted = true
    env.FluxUnitFrames_ApplyFluxVsBlizzardRuntime()
    flush()
    assert(alpha == 0, "Flux player frame did not suppress native artwork")
    assert(not contentShown, "alpha alone leaves health/mana OnUpdate running")
    tickNativeBars()
    assert(healthUpdates == 0 and manaUpdates == 0, "hidden native bars still ran their secret comparisons")
    assert(nativeScripts.health == healthUpdate and nativeScripts.mana == manaUpdate, "native bar scripts were replaced")
    assert(not nativeEvents.UNIT_SPELLCAST_START and not nativeEvents.UNIT_HEAL_PREDICTION,
        "hidden Blizzard overlays must not receive cast/health updates")
    assert(nativeEvents.UNIT_ENTERED_VEHICLE, "native vehicle events were removed")
    assert(nativePlayer.unit == unit, "suppression changed Blizzard's unit")
    combat = true
    env.FluxUnitFrames_SuppressBlizzardUnitFrame("player")
    assert(nativePlayer.unit == unit, "combat suppression changed Blizzard's unit")
    combat = false
    wanted = false
    env.FluxUnitFrames_ApplyFluxVsBlizzardRuntime()
    flush()
    assert(alpha == 1, "native player artwork was not restored")
    assert(contentShown, "native player content was not restored")
    assert(nativeScripts.health == healthUpdate and nativeScripts.mana == manaUpdate, "original native scripts did not survive the toggle")
    assert(nativeEvents.UNIT_SPELLCAST_START[1] == "player", "cast filter was not restored")
    assert(nativeEvents.UNIT_HEAL_PREDICTION[2] == "vehicle", "multiple unit filters were not preserved")
    assert(not nativeEvents.UNIT_SPELLCAST_FAILED, "restoration added an event that was not originally registered")
    assert(nativePlayer.unit == unit, "restoring Blizzard changed its unit")
end
assert(nativeCalls == 0, "player toggles modified native events, scripts or unit")
-- A native vehicle transition can re-register an overlay while it is muted.
wanted = true
env.FluxUnitFrames_SuppressBlizzardUnitFrame("player")
nativeEvents.UNIT_HEAL_PREDICTION = { "vehicle" }
env.FluxUnitFrames_SetBlizzardPlayerPredictionMuted(true)
env.FluxUnitFrames_SetBlizzardPlayerPredictionMuted(false)
assert(nativeEvents.UNIT_HEAL_PREDICTION[1] == "vehicle" and #nativeEvents.UNIT_HEAL_PREDICTION == 1,
    "restoration discarded a native vehicle registration change")

-- Legacy player combos no longer drive the native target combo row or its unit.
ns.API = { ShouldUseLegacyComboFrameUI = function() return true end }
env.ComboFrame = {}
loadAddon("UnitFrames/FluxLegacyComboPoints.lua")
for _, inVehicle in ipairs({ false, true, false }) do
    vehicle = inVehicle
    ns.LegacyComboPoints.RefreshAll()
    assert(env.ComboFrame.unit == nil, "legacy combo updates rewrote native target combo state")
end
assert(nativeCalls == 0, "legacy combo updates touched native player state")
print("player runtime smoke OK (hidden bar updates, original scripts, overlay filters, vehicles, legacy combos)")
