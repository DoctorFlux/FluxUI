-- lua tests/binding_respec_regression.lua (standalone; no WoW installation required)
-- Exercises production entry points with deterministic client/event/timer mocks.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
local function read(path)
    local file = assert(io.open(root .. path, "r"))
    local source = file:read("*a")
    file:close()
    return source
end
local function environment(values)
    local env = setmetatable(values or {}, { __index = _G })
    env._G = env
    return env
end
local function loadModule(path, env, ns)
    return assert(loadfile(root .. path, "t", env))("_FluxUI", ns or {})
end
local function mockFrame()
    return {
        events = {},
        RegisterEvent = function(self, event) self.events[event] = true end,
        UnregisterEvent = function(self, event) self.events[event] = nil end,
        UnregisterAllEvents = function(self) self.events = {} end,
        SetScript = function(self, script, fn) self[script] = fn end,
    }
end
local function drain(queue)
    while #queue > 0 do
        local callback = table.remove(queue, 1)
        callback()
    end
end

-- Compile the actual defaults functions in their documented local scope. Loading
-- the entire defaults module would require unrelated Settings/UI mocks.
do
    local source = read("FluxDefaultSettings.lua")
    local function fragment(first, following)
        local start = assert(source:find(first, 1, true))
        local finish = assert(source:find(following, start, true))
        return source:sub(start, finish - 1)
    end
    local verify = fragment("function FluxDefaultSettings.VerifyPostLoginDefaults()", "-- Apply the defaults")
    local reset = fragment("local FLUX_BINDING_SEED_VERSION = 6", "--- Re-apply softTargetEnemy")
    for _, customF5 in ipairs({ "JUMP", "", "CLICK MyCustomButton:LeftButton" }) do
        local bindings = { F5 = customF5, ["CTRL-9"] = "CUSTOM_ACTION" }
        local savedBindings = { F5 = customF5, ["CTRL-9"] = "CUSTOM_ACTION" }
        local writes, cvarWrites, queue, saves = 0, 0, {}, 0
        local env = environment({
            FluxUI_DB = { accountDefaultsApplied = true },
            FluxDefaultSettings = { _resetDetection = {} },
            print = function() end,
            InCombatLockdown = function() return false end,
            GetBindingAction = function(key) return bindings[key] or "" end,
            GetNumBindings = function() return 3 end,
            GetBinding = function(i)
                if i == 1 then return "JUMP", "F5" end
                if i == 2 then return "CUSTOM_ACTION", "CTRL-9" end
                return "FLUXRELOADUI"
            end,
            SetBinding = function(key, action) writes = writes + 1; bindings[key] = action; return true end,
            SaveBindings = function()
                saves = saves + 1
                savedBindings = {}
                for key, action in pairs(bindings) do savedBindings[key] = action end
                return true
            end,
            LoadBindings = function()
                bindings = {}
                for key, action in pairs(savedBindings) do bindings[key] = action end
                return true
            end,
            GetCurrentBindingSet = function() return 2 end,
            C_Timer = { After = function(_, fn) queue[#queue + 1] = fn end },
        })
        env.FluxDefaultSettings.ApplyCVarsOnly = function() cvarWrites = cvarWrites + 1 end
        env.FluxDefaultSettings.FlushBindingRefreshAfterBulk = function() end
        local scope = [[
local FLUX_DEFAULTS = { showTutorials = "0", autoLootDefault = "1", deselectOnClick = "0" }
local DefaultKeyTemplate = { F5 = "FLUXRELOADUI" }
local KEYBIND_REPAIR_PASSES = 3
local FluxGetCVarDefault = function() return "1" end
local FluxGetCVar = function() return "1" end
local FluxArmPendingCombatFlush = function() end
]]
        assert(load(scope .. verify .. reset, "defaults binding regression", "t", env))()
        env.FluxDefaultSettings.VerifyPostLoginDefaults()
        check(writes == 0 and saves == 0, "automatic verification must not write customized bindings")
        check(cvarWrites == 0, "custom F5 must not authorize a CVar reset")
        check(bindings.F5 == customF5 and bindings["CTRL-9"] == "CUSTOM_ACTION", "custom keys must survive verification")
        env.FluxDefaultSettings.ApplyKeybinds()
        drain(queue)
        check(bindings.F5 == "FLUXRELOADUI" and bindings["CTRL-9"] == nil and saves == 1,
            "explicit reset must retain its full Flux-default behavior")
    end
end

local function respecHarness(behavior, options)
    options = options or {}
    local profile = { spellBindings = options.snapshot or { version = 3, doc = {} } }
    local events, warnings, saved, clearCount, callbacks = {}, {}, {}, 0, {}
    local R = {
        Compat = { IsSoD = function() return false end, HasTalentLoadouts = function() return false end },
        GetProfile = function() return profile end,
        GetStore = function() return saved end,
        ApplyInfoFrameForProfile = function() end,
        LinkProfilePresets = function() end,
        Fire = function(...) events[#events + 1] = { ... } end,
        On = function() end,
        Print = function() end,
        Warn = function(message) warnings[#warnings + 1] = message end,
        SetLoadCheckpoint = function(name, step) saved.checkpoint = { name, step } end,
        ClearLoadCheckpoint = function() saved.checkpoint = nil; clearCount = clearCount + 1 end,
    }
    if options.disabled then
        R.Includes = { SectionEnabled = function(_, section) return section ~= "spellBindings" end }
    end
    if options.uncaptured then profile.spellBindings = nil end
    local env = environment({
        FluxRespec = R,
        time = function() return 1 end,
        FluxSpellBindings_MatchesSnapshot = function() return false end,
        FluxSpellBindings_IsLegacySnapshot = function(snap) return snap.version == 2 end,
        FluxSpellBindings_IsV3Snapshot = function(snap) return snap.version == 3 end,
    })
    if not options.noAPI then
        env.FluxSpellBindings_ApplySnapshot = function(snapshot, done)
            callbacks[#callbacks + 1] = done
            return behavior(snapshot, done)
        end
    end
    loadModule("Respec/FluxRespec_Apply.lua", env)
    local function doneEvents()
        local done = {}
        for _, event in ipairs(events) do
            if event[1] == "APPLY_DONE" then done[#done + 1] = event end
        end
        return done
    end
    return R, saved, doneEvents, function() return clearCount end, callbacks, env
end

-- These entry points use no client-specific APIs. Run their acceptance cases
-- under every supported client identity so mocks do not depend on Retail globals.
for _, client in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    for _, behavior in ipairs({
        function() return false, "RESTORE_FAILED" end,
        function(_, done) done(false, "RESTORE_FAILED"); return false, "RESTORE_FAILED" end,
        function() error("RESTORE_FAILED") end,
    }) do
        local R, saved, events, clears = respecHarness(behavior)
        check(R.Apply.Run("Combat") == true, client .. ": load request accepted")
        local done = events()
        check(#done == 1 and done[1][2] == false, client .. ": restore failure must emit one failure")
        check(not R.Apply.IsRunning(), client .. ": restore failure must exit running state")
        check(saved.checkpoint and saved.checkpoint[2] == "bindings" and clears() == 0,
            client .. ": failed restore must retain recovery checkpoint")
    end
    do
        local R, saved, events, clears, callbacks = respecHarness(function() return false, "IN_COMBAT" end)
        R.Apply.Run("Combat")
        check(R.Apply.IsRunning() and #events() == 0, client .. ": combat-deferred binding restore remains pending")
        callbacks[1](false, "RESTORE_FAILED")
        callbacks[1](true)
        check(#events() == 1 and events()[1][2] == false and clears() == 0 and saved.checkpoint,
            client .. ": delayed failure and duplicate callback must not report success")
    end
end

for _, options in ipairs({ { snapshot = { version = 2, doc = {} } }, { snapshot = { version = 99 } }, { noAPI = true } }) do
    local R, saved, events, clears = respecHarness(function() error("must not apply invalid data") end, options)
    check(not R.Apply.IsProfileFullyApplied("Broken"), "unrestorable section must not match the complete-profile fast path")
    R.Apply.Run("Broken")
    check(#events() == 1 and not events()[1][2] and saved.checkpoint and clears() == 0,
        "unrestorable captured section must fail and preserve checkpoint")
end
for _, options in ipairs({ { disabled = true }, { uncaptured = true } }) do
    local R, _, events = respecHarness(function() error("disabled/uncaptured bindings must not be restored") end, options)
    R.Apply.Run("Unchanged")
    check(#events() == 1 and events()[1][2], "disabled or uncaptured bindings preserve existing skip behavior")
end
do
    local R, saved, events, clears, callbacks = respecHarness(function() return true end)
    R.Apply.Run("Success")
    check(R.Apply.IsRunning() and #events() == 0, "accepted asynchronous restore waits for completion")
    callbacks[1](true)
    callbacks[1](false, "stale")
    check(#events() == 1 and events()[1][2] and not saved.checkpoint and clears() == 1,
        "successful restore finishes and clears its checkpoint exactly once")
end
do
    local R, saved, events, clears, callbacks, env = respecHarness(function() return false, "IN_COMBAT" end)
    local cancelled
    env.FluxSpellBindings_CancelPendingApply = function(callback) cancelled = callback; callback(false, "CANCELLED") end
    R.Apply.Run("Cancelled")
    R.Apply.Cancel()
    callbacks[1](true)
    check(cancelled == callbacks[1], "profile cancellation cancels only its pending binding restore")
    check(#events() == 1 and events()[1][2] == false and events()[1][3] == "CANCELLED"
        and not saved.checkpoint and clears() == 1, "explicit cancellation clears its checkpoint once and ignores stale callbacks")
end

do
    local store = { nextUid = 2, bindings = { [1] = { uid = 1, action = { type = "spell", id = 10 }, key = "Q" } },
        chordStackOrder = {}, badgeCornerOrder = {}, formPageEnabled = {}, rankSyncNames = {} }
    local combat, failRequest, requests, frames, timers = false, false, 0, {}, {}
    local ns = {
        FluxBindingDB3 = { EnsureLive = function() return store end },
        FluxBindingConditions = { InvalidateAvailability = function() end },
    }
    local env = environment({
        InCombatLockdown = function() return combat end,
        CreateFrame = function() local frame = mockFrame(); frames[#frames + 1] = frame; return frame end,
        C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end },
        FluxBinding = { RequestApplyAll = function() requests = requests + 1; if failRequest then error("request failed") end end },
    })
    loadModule("Binding/Respec.lua", env, ns)
    local snapshot = { version = 3, doc = { bindings = {
        [4] = { uid = 4, action = { type = "spell", id = 20 }, key = "E" },
        [5] = { uid = 5, action = { type = "spell", id = 30 } }, -- pristine, omitted by compacting
    } } }
    local originalBindings, originalNext = store.bindings, store.nextUid
    failRequest = true
    local callbacks = {}
    local ok = env.FluxSpellBindings_ApplySnapshot(snapshot, function(...) callbacks[#callbacks + 1] = { ... } end)
    check(not ok and #callbacks == 1 and callbacks[1][1] == false, "snapshot API reports request exceptions as failure")
    check(store.bindings == originalBindings and store.nextUid == originalNext, "failed snapshot transaction restores original SavedVariables")
    failRequest, combat = false, true
    local callsBefore = requests
    ok = env.FluxSpellBindings_ApplySnapshot(snapshot, function(...) callbacks[#callbacks + 1] = { ... } end)
    check(not ok and requests == callsBefore and store.bindings == originalBindings, "combat restore only queues work")
    snapshot.doc.bindings[4].key = "CHANGED_AFTER_QUEUE"
    combat = false
    frames[1].OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
    drain(timers)
    check(store.bindings[4].key == "E" and store.bindings[5] == nil, "combat restore is detached and normalized like an immediate restore")
    check(#callbacks == 2 and callbacks[2][1] == true and not frames[1].events.PLAYER_REGEN_ENABLED,
        "deferred restore completes once and disarms its event")
    local requestsAfter = requests
    frames[1].OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
    check(requests == requestsAfter, "duplicate regen cannot restore twice")
    combat = true
    env.FluxSpellBindings_ApplySnapshot(snapshot, function(...) callbacks[#callbacks + 1] = { ... } end)
    env.FluxSpellBindings_ApplySnapshot(snapshot, function(...) callbacks[#callbacks + 1] = { ... } end)
    check(#frames == 1 and callbacks[#callbacks][1] == false and callbacks[#callbacks][2] == "SUPERSEDED",
        "replacement deferred restore reuses watcher and settles superseded owner")
    failRequest, combat = true, false
    frames[1].OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
    check(callbacks[#callbacks][1] == false and not frames[1].events.PLAYER_REGEN_ENABLED,
        "deferred restore exception reports failure and disarms watcher")
    combat, failRequest = true, false
    local cancelled
    local owner = function(ok, reason) cancelled = { ok, reason } end
    local beforeCancel, requestsBeforeCancel = store.bindings, requests
    env.FluxSpellBindings_ApplySnapshot(snapshot, owner)
    check(not env.FluxSpellBindings_CancelPendingApply(function() end), "another callback cannot cancel a pending restore")
    check(env.FluxSpellBindings_CancelPendingApply(owner) and not cancelled[1] and cancelled[2] == "CANCELLED",
        "pending restore cancellation settles its owner")
    combat = false
    frames[1].OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
    check(store.bindings == beforeCancel and requests == requestsBeforeCancel,
        "cancelled deferred restore never overwrites bindings after combat")
end

do
    local frames, login, timers, applied, attempts, failOnce = {}, nil, 0, 0, 0, true
    local flux = { loggedIn = false, AfterLogin = function(fn) login = fn end }
    local ns = {
        Flux = flux,
        FluxBindingDB3 = { Ensure = function()
            attempts = attempts + 1
            if failOnce then failOnce = false; error("transient DB failure") end
        end },
    }
    local env = environment({
        CreateFrame = function() local frame = mockFrame(); frames[#frames + 1] = frame; return frame end,
        C_Timer = { After = function() timers = timers + 1 end },
        FluxBinding = { RequestApplyAll = function() applied = applied + 1 end },
    })
    loadModule("Binding/Boot.lua", env, ns)
    frames[1].OnEvent(frames[1], "PLAYER_ENTERING_WORLD")
    check(attempts == 0, "binding boot respects the kernel login/Forever gamepad barrier")
    flux.loggedIn = true
    check(not pcall(login) and applied == 0, "failed binding boot does not mark itself complete")
    frames[1].OnEvent(frames[1], "PLAYER_REGEN_ENABLED")
    check(attempts == 2 and applied == 1 and timers == 0, "binding boot retries and immediately requests coalesced apply without a one-second timer")
    check(next(frames[1].events) == nil and frames[1].OnEvent == nil, "successful binding boot removes retry subscriptions")
    login()
    check(applied == 1, "completed binding boot is idempotent")
end

print(("binding/respec regression: %d checks passed"):format(checks))
