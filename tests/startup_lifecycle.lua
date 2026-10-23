-- Run from the addon root: lua tests/startup_lifecycle.lua
-- Executes production lifecycle/queue code. Models lockdown, not WoW's taint VM.
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end

local function harness(branch, locked, loggedIn)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.FluxUI_DB = { startupDiagnostics = true }
    env.SlashCmdList = {}
    local frames, timers, variableCallbacks, errors = {}, {}, {}, {}
    local time = 0
    local ns = {}
    env.InCombatLockdown = function() return locked end
    env.IsLoggedIn = function() return loggedIn end
    env.GetTime = function() return time / 1000 end
    env.debugprofilestop = function() return time end
    env.geterrorhandler = function() return function(err) errors[#errors + 1] = err end end
    env.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    env.CreateFrame = function(_, name, _, template)
        assert(not (locked and template and template:find("Secure")), "protected frame creation during lockdown")
        local f = { events = {}, scripts = {}, shown = true }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:UnregisterAllEvents() self.events = {} end
        function f:SetScript(script, fn) self.scripts[script] = fn end
        function f:GetScript(script) return self.scripts[script] end
        function f:Hide() self.shown = false end
        function f:Show() self.shown = true end
        function f:IsShown() return self.shown end
        frames[#frames + 1] = f
        if name then env[name] = f end
        return f
    end
    local varsReady = false
    env.EventUtil = { ContinueOnVariablesLoaded = function(fn)
        if varsReady then fn() else variableCallbacks[#variableCallbacks + 1] = fn end
    end }
    local function load(path) assert(loadfile(path, "t", env))("_FluxUI", ns) end
    load("Core/Flux.lua")
    local flux = ns.Flux
    flux.Client = { branch = branch, isCamelot = branch == "forever", Matches = function() return true end }
    flux.AddOn = { IsLoaded = function(name) return env[name .. "_loaded"] end }
    load("Core/Engine/Events.lua")
    load("Core/Engine/Timer.lua")
    load("Core/Engine/Combat.lua")
    load("Core/Engine/Scheduler.lua")
    load("Core/DB.lua")
    load("Core/Module.lua")
    load("Core/Startup.lua")
    local h = { flux = flux, env = env, ns = ns, errors = errors }
    function h.event(event, ...)
        local n = #frames
        for i = 1, n do
            local f = frames[i]
            if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
        end
    end
    function h.variables()
        varsReady = true
        for i = 1, #variableCallbacks do variableCallbacks[i]() end
        h.event("VARIABLES_LOADED")
    end
    function h.frame()
        time = time + 16
        local pending = timers
        timers = {}
        for i = 1, #pending do pending[i]() end
    end
    function h.combat(value) locked = value; h.event(value and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED") end
    function h.login() loggedIn = true; h.event("PLAYER_LOGIN") end
    function h.loaded() h.event("ADDON_LOADED", "_FluxUI") end
    function h.timerCount() return #timers end
    return h
end

for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    for _, combat in ipairs({ false, true }) do
        local h = harness(branch, combat, false)
        local f, order = h.flux, {}
        local nativeControls = true
        f.AfterLoad(function() order[#order + 1] = "saved" end)
        f.Module.Register("Inventory", { phase = "deferred", OnEnable = function() order[#order + 1] = "inventory" end })
        f.Module.Register("secure2", { phase = "secure", priority = 20, protected = true, OnEnable = function()
            check(not h.env.InCombatLockdown(), branch .. " secure2 combat")
            check(order[#order] == "secure1", "priority order")
            order[#order + 1] = "secure2"
            nativeControls = false
        end })
        f.Module.Register("secure1", { phase = "secure", priority = 10, protected = true, OnEnable = function()
            check(not h.env.InCombatLockdown(), branch .. " secure1 combat")
            order[#order + 1] = "secure1"
        end })
        f.Module.Register("visual", { OnEnable = function() order[#order + 1] = "visual" end })
        h.loaded()
        if branch == "forever" then
            check(not f.Module.IsEnabled("secure1"), "Forever waits VARIABLES_LOADED")
            h.variables()
            check(not f.Module.IsEnabled("secure1"), "Forever leaves native callback stack")
            h.frame()
        end
        check(order[1] == "saved", "saved config precedes secure startup")
        check(f.Module.IsEnabled("secure1") == not combat, branch .. " early secure stage")
        check(not f.Module.IsEnabled("Inventory"), "inventory cannot block secure initialization")
        h.login()
        check(f.Module.IsEnabled("visual"), branch .. " visual available even in combat")
        h.frame()
        check(f.Module.IsEnabled("Inventory"), "deferred nonprotected work runs in combat")
        if combat then
            check(nativeControls and f.Combat.PendingCount() == 2, "native fallback until replacements functional")
            for _ = 1, 3 do h.event("PLAYER_ENTERING_WORLD") end
            check(f.Combat.PendingCount() == 2, "deferred startup deduplicated")
            h.combat(false)
        end
        check(not nativeControls and f.Module.IsEnabled("secure2"), "secure work resumes at regen")
        local count = #order
        h.combat(false)
        h.event("PLAYER_ENTERING_WORLD")
        check(#order == count, "completed controls reused across transitions")
        check(#h.errors == 0, "no hidden initialization errors")
        local snapshot = f.Startup.Snapshot()
        check(snapshot.enabled and snapshot.marks["module.secure1"] ~= nil, "opt-in diagnostics capture readiness")
    end

    -- /reload/reconnect late addon load: PLAYER_LOGIN need not repeat.
    local h = harness(branch, true, true)
    h.variables()
    h.flux.Module.Register("late", { phase = "secure", protected = true, OnEnable = function() return true end })
    h.loaded()
    if branch == "forever" then h.frame() end
    check(h.flux.loggedIn, branch .. " already logged in")
    check(not h.flux.Module.IsEnabled("late"), "late combat load queued")
    h.combat(false)
    check(h.flux.Module.IsEnabled("late"), "late secure setup resumes")

    local config = harness(branch, false, false)
    local recovered, calls = false, 0
    config.env.FluxOptions = { EnsureSavedConfiguration = function()
        if recovered then config.flux.optionsBootstrapComplete = true end
    end }
    config.flux.Module.Register("configured", { phase = "secure", OnEnable = function() calls = calls + 1 end })
    config.loaded()
    config.variables()
    config.frame()
    config.login()
    check(calls == 0, branch .. " failed configuration must not initialize controls with defaults")
    check(config.flux.Startup.Snapshot().marks.saved_configuration_ready == nil, "failed config not reported ready")
    recovered = true
    config.event("PLAYER_ENTERING_WORLD")
    check(calls == 1 and config.flux.loggedIn, branch .. " recovered configuration resumes pipeline")
end

do
    local h = harness("live", false, false)
    local attempts = 0
    h.flux.Module.Register("retry", { phase = "secure", OnEnable = function()
        attempts = attempts + 1
        if attempts == 1 then error("controlled initialization failure") end
        if attempts == 2 then return false end
        return true
    end })
    h.loaded()
    check(not h.flux.Module.IsEnabled("retry"), "exception is not success")
    h.login()
    h.event("PLAYER_ENTERING_WORLD")
    check(not h.flux.Module.IsEnabled("retry"), "false is not success")
    h.event("PLAYER_ENTERING_WORLD")
    check(h.flux.Module.IsEnabled("retry") and attempts == 3, "safe retry after failures")
    local loads = 0
    h.flux.Module.Register("integration", { requiredAddons = { "LateAddon" }, OnEnable = function() loads = loads + 1 end })
    check(loads == 0, "required addon pending")
    h.env.LateAddon_loaded = true
    h.event("ADDON_LOADED", "LateAddon")
    h.event("ADDON_LOADED", "LateAddon")
    check(loads == 0, "provider event handlers complete before integration")
    h.frame()
    check(loads == 1, "late integration runs once")
end

do
    local h = harness("live", false, false)
    h.loaded()
    h.login()
    h.frame()
    h.flux.Startup.Layout("test_layouts")
    h.flux.Startup.Layout("test_layouts")
    for _ = 1, 4 do h.frame() end
    local snapshot = h.flux.Startup.Snapshot()
    check(snapshot.finished and snapshot.marks.bottom_hud_initially_stable ~= nil, "bursty layouts rearm stability sampling")
    check(snapshot.counters.test_layouts == 2, "settle sampling does not invent layout passes")
    local h2 = harness("live", false, false)
    local runs = 0
    h2.flux.Module.Register("barrier", { phase = "secure", OnEnable = function() runs = runs + 1 end })
    check(not h2.flux.Module.Enable("barrier") and runs == 0, "public Enable cannot bypass startup barriers")
end

do
    local h = harness("live", true, false)
    local ran = {}
    h.flux.Combat.Defer("first", function() ran[#ran + 1] = "first"; h.combat(true) end)
    h.flux.Combat.Defer("second", function() ran[#ran + 1] = "second" end)
    h.combat(false)
    check(#ran == 1 and h.flux.Combat.PendingCount() == 1, "combat beginning mid-flush retains remainder")
    h.combat(false)
    check(#ran == 2 and not h.flux.Combat.HasPending(), "remainder runs once")
    h.flux.Combat.RegenDefer(function() ran[#ran + 1] = "light"; h.combat(true) end)
    h.flux.Combat.RegenDefer(function() ran[#ran + 1] = "heavy" end, true)
    h.frame()
    check(ran[#ran] == "light", "heavy work stops at lockdown edge")
    h.combat(false)
    h.frame()
    check(ran[#ran] == "heavy", "heavy work retained for next regen")
end

do
    local h = harness("live", true, false)
    local f, ran = h.flux, {}
    f.Scheduler.Request("structural", "first", function(tokens)
        check(tokens.first and tokens.second, "all deferred structural tokens retained")
        ran[#ran + 1] = "first"
        h.combat(true)
    end)
    f.Scheduler.Request("structural", "second", function() ran[#ran + 1] = "second" end)
    check(f.Combat.PendingCount() == 1 and f.Scheduler.HasPending("structural"), "structural callers share a wakeup without dropping work")
    h.combat(false)
    check(#ran == 1, "structural callbacks pause when combat begins mid-bucket")
    h.combat(false)
    check(#ran == 2 and ran[2] == "second", "remaining structural callback resumes exactly once")
    h.combat(false)
    check(#ran == 2, "completed callbacks not repeated")
end

do
    local h = harness("live", false, false)
    h.env.FluxUI_DB = "recover account"
    h.env.FluxSpellBindingProfilesDB = "recover bindings"
    h.loaded()
    local roots = h.env.FluxUI_DB.__fluxRootRecoveryV1.roots
    check(roots.FluxUI_DB == "recover account", "malformed account preserved")
    check(roots.FluxSpellBindingProfilesDB == "recover bindings", "malformed character root preserved")
    h.flux.DB.EnsureAll()
    check(roots.FluxSpellBindingProfilesDB == "recover bindings", "recovery idempotent")
end

print("startup lifecycle: " .. checks .. " checks passed (five client fixtures; no native taint/render simulation)")
