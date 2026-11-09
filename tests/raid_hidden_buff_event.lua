-- The live dispatcher refreshes aura policy without touching protected layout.
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end
local function exercise(supported)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local state = { isInitialized = true }
    local invalidations, paints = 0, {}
    local cells = { { unit = "party1" }, { unit = "party2" }, {}, { unit = "raid1target", _fluxRaidMini = true } }
    e.FluxRaidState = state
    e.FluxOptions = { GetRaidFrameDB = function() return { useFluxRaidFrames = e.enabled } end }
    e.enabled = true
    e.FluxRaidCompat = { CanUsePetBattleStateDriver = function() return false end }
    e.C_UnitAuras = supported and { GetHiddenGroupBuffs = function() return {} end } or {}
    e.FluxRaidAuras = { OnHiddenGroupBuffsChanged = function() invalidations = invalidations + 1 end }
    e.FluxRaid_ForEachHeaderChild = function(callback) for _, cell in ipairs(cells) do callback(cell) end end
    e.FluxRaid_UpdateAuras = function(cell) paints[#paints + 1] = cell end
    -- Registering a protected module must not eagerly initialize it in this test.
    local ns = { Flux = { Module = { Register = function() end } } }
    assert(loadfile("RaidFrame/FluxRaidFrame.lua", "t", e))("_FluxUI", ns)
    local events = {}
    local frame = { RegisterEvent = function(_, event) events[event] = true end }
    e.FluxRaid_OnLoad(frame)
    check(not not events.HIDDEN_GROUP_BUFFS_CHANGED == supported, "only clients exposing the hidden-buff API register its event")
    if not supported then return end
    -- A live combat event takes the aura-only route; layout APIs are absent.
    e.InCombatLockdown = function() return true end
    e.FluxRaid_OnEvent(frame, "HIDDEN_GROUP_BUFFS_CHANGED", { 1243 })
    check(invalidations == 1 and #paints == 2 and paints[1] == cells[1] and paints[2] == cells[2],
        "one cache invalidation refreshes bound full cells in combat, skipping empty and mini cells")
    e.enabled = false
    e.FluxRaid_OnEvent(frame, "HIDDEN_GROUP_BUFFS_CHANGED", {})
    check(invalidations == 2 and #paints == 2, "disabled frames invalidate policy without repainting units")
    e.enabled, state.isInitialized = true, false
    e.FluxRaid_OnEvent(frame, "HIDDEN_GROUP_BUFFS_CHANGED", {})
    check(invalidations == 3 and #paints == 2, "uninitialized frames cache the change without unit work")
end
exercise(true)
exercise(false)
print("Raid hidden-buff event: " .. checks .. " checks; actual dispatcher, combat aura-only refresh and inactive guards")
