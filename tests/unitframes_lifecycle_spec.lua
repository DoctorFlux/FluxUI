-- Desktop fixture for the real lifecycle helper and per-unit registrations.
-- Client names are distinct policy inputs, not a simulation of WoW's taint VM.
local checks = 0
local function check(ok, message) checks = checks + 1; assert(ok, message) end
local units = {
    { "Player", "player", "PlayerFrame" }, { "Target", "target", "TargetFrame" },
    { "Focus", "focus", "FocusFrame" }, { "FocusTarget", "focustarget", "FocusTargetFrame" },
    { "TargetOfTarget", "targettarget", "TargetOfTargetFrame" }, { "Pet", "pet", "PetFrame" },
    { "PetTarget", "pettarget", "PetTargetFrame" },
}
local function load(path, env, ns)
    local fn, err
    if _VERSION == "Lua 5.1" then fn, err = loadfile(path); if fn then setfenv(fn, env) end
    else fn, err = loadfile(path, "t", env) end
    assert(fn, err)("_FluxUI", ns)
end
local function fixture(client)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local ns = { UnitFrames = {} }
    local specs, pending, marks = {}, {}, {}
    local creates, suppressions = 0, 0
    e.combat = false
    e.InCombatLockdown = function() return e.combat end
    e.Flux = {
        securePhaseReady = true,
        Client = { key = client },
        Module = { Register = function(name, spec) specs[name] = spec end },
        Combat = { Defer = function(key, callback) pending[key] = callback end },
        Startup = { Mark = function(name) marks[name] = true end },
    }
    ns.Flux = e.Flux
    e.FluxUnitFrames_SuppressBlizzardUnitFrame = function(unit)
        check(ns.UnitFrames.IsInitialized(unit), "native fallback cannot be suppressed before replacement is complete")
        check(not e.combat, "native suppression must run outside combat")
        suppressions = suppressions + 1
    end
    function e.Drain()
        local work = pending; pending = {}
        for _, callback in pairs(work) do callback() end
    end
    function e.PendingCount() local n = 0; for _ in pairs(pending) do n = n + 1 end; return n end
    function e.MakeFrame()
        check(not e.combat, "protected frame creation must not run in combat")
        creates = creates + 1
        return { IsShown = function() return true end }
    end
    function e.Counts() return creates, suppressions end
    e.specs, e.marks = specs, marks
    load("UnitFrames/FluxUnitFrames_Lifecycle.lua", e, ns)
    return e, ns
end

for _, client in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    local e, ns = fixture(client)
    -- Load the actual unit modules: their file scope must only register initializers.
    for _, row in ipairs(units) do load("UnitFrames/FluxUnitFrames_" .. row[1] .. ".lua", e, ns) end
    for _, row in ipairs(units) do
        local spec = e.specs["UnitFrame." .. row[2]]
        check(spec and spec.phase == "secure" and spec.protected, client .. " " .. row[2] .. " joins protected secure phase")
        if row[2] == "focus" or row[2] == "focustarget" then
            check(spec.capabilities[1] == "hasFocusUnit", "focus uses capability gate")
        end
    end
    e.combat = true
    for _, spec in pairs(e.specs) do check(spec.OnEnable() == false, "combat startup returns incomplete") end
    check(e.PendingCount() == 7, "seven pending unit initializers, no polling timers")
    check(e.Counts() == 0, "actual unit loader attempts never create protected frames in combat")

    -- The real helper is also tested with small completed/incomplete constructors.
    for i, row in ipairs(units) do
        local complete = false
        ns.UnitFrames.RegisterInitializer(row[2], function()
            ns[row[3]] = ns[row[3]] or e.MakeFrame()
            complete = true
        end, function() return complete end, 60 + i)
    end
    e.combat = false
    e.Drain(); e.Drain()
    check(e.Counts() == 7, "deferred init creates every fixture unit once")
    for _, row in ipairs(units) do check(ns.UnitFrames.IsInitialized(row[2]), "completed fixture is reusable") end
    for _, spec in pairs(e.specs) do check(spec.OnEnable() == true, "repeated phase enable succeeds without recreation") end
    check(e.Counts() == 7, "repeated lifecycle reconciliation does not rebuild completed frames")
    check(e.marks.essential_unit_frames_visible, "visibility diagnostic observes a shown player frame")

    local latest = 0
    e.combat = true
    for i = 1, 100 do
        local value = i
        ns.UnitFrames.DeferProtected("runtime.player", function() latest = value end)
    end
    check(e.PendingCount() == 1, "repeated setting changes coalesce under one combat key")
    e.combat = false; e.Drain()
    check(latest == 100, "latest requested configuration wins after combat")
end

local e, ns = fixture("live")
local attempts, complete = 0, false
ns.UnitFrames.RegisterInitializer("player", function()
    attempts = attempts + 1
    if attempts == 1 then error("fixture dependency unavailable") end
    ns.PlayerFrame = e.MakeFrame(); complete = true
end, function() return complete end, 60)
e.Flux.securePhaseReady = false
check(e.specs["UnitFrame.player"].OnEnable() == false and attempts == 0, "direct calls respect the secure phase/gamepad barrier")
e.Flux.securePhaseReady = true
check(not pcall(e.specs["UnitFrame.player"].OnEnable), "initialization failure propagates to Core.Safecall")
check(not ns.UnitFrames.IsInitialized("player"), "failed initialization leaves native fallback usable")
check(e.specs["UnitFrame.player"].OnEnable(), "failed initialization can retry successfully")

local enabled = false
complete = false
ns.UnitFrames.RegisterInitializer("pet", function()
    if enabled then ns.PetFrame = e.MakeFrame() end
    complete = true
end, function() return complete end, 65)
check(e.specs["UnitFrame.pet"].OnEnable(), "disabled configuration is a completed skip")
check(not ns.UnitFrames.IsInitialized("pet"), "disabled skip does not claim secure replacement readiness")
enabled = true; complete = false
check(ns.UnitFrames.RunInitializer("pet") and ns.PetFrame, "later enabling a skipped unit creates its replacement")

print("Unit frame lifecycle checks: " .. checks .. " passed across 5 client policy fixtures")
