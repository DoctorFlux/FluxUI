-- lua tests/default_flux_grid_bindings.lua
-- Production binding pipeline against five native-set/save/load models.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local file = assert(io.open(root .. "FluxDefaultSettings.lua", "r"))
local source = file:read("*a")
file:close()
local function part(first, following)
    local start = assert(source:find(first, 1, true), first)
    local finish = assert(source:find(following, start, true), following)
    return source:sub(start, finish - 1)
end
local template = assert(load(part("local DefaultKeyTemplate = {",
    "-- Comprehensive Default Values") .. "\nreturn DefaultKeyTemplate",
    "binding template"))()
local code = part("local FLUX_BINDING_SEED_VERSION = 6",
    "--- Re-apply softTargetEnemy")
local checks = 0
local function check(ok, why)
    assert(ok, why)
    checks = checks + 1
end
local function copy(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end
local original = {
    W = "MOVEFORWARD", F5 = "USER_ACTION", Y = "TOGGLEACHIEVEMENT",
    ["7"] = "ACTIONBUTTON7", ["8"] = "ACTIONBUTTON8",
    ["6"] = "ACTIONBUTTON6", ["CTRL-9"] = "CUSTOM_ACTION",
}
local clients = { "retail", "forever", "era", "anniversary", "mop" }
local function fixture(client, marker, activeSet, accountKeys)
    local state = {
        client = client, set = activeSet or 2, writes = {}, saves = {},
        loads = {}, timers = {}, flushes = 0, scans = 0, combat = false,
        savedSets = { [1] = copy(accountKeys or original), [2] = copy(original) },
        unsupported = (client == "era" or client == "anniversary"
            or client == "mop") and { TOGGLEPINGLISTENER = true } or {},
    }
    state.keys = copy(state.savedSets[state.set])
    local db = { defaultFluxBindingsChecked = {} }
    if marker ~= nil then db.defaultFluxBindingsChecked.account = marker end
    local defaults = { _resetDetection = {} }
    local modern = client == "retail" or client == "forever"
    local env = {
        FluxUI_DB = db, FluxDefaultSettings = defaults,
        DefaultKeyTemplate = template, KEYBIND_REPAIR_PASSES = 3,
        print = function() end,
        FluxArmPendingCombatFlush = function() state.armed = true end,
        FluxDisarmPendingCombatFlushIfIdle = function() end,
        InCombatLockdown = function() return state.combat end,
        GetCurrentBindingSet = function() return state.set end,
        C_KeyBindings = modern and {
            GetBindingContextForAction = function() return 1 end,
        } or nil,
        GetBindingAction = function(key, _, context)
            if modern and context ~= 1 then return "" end
            return state.keys[key] or ""
        end,
        GetBindingKey = function(command)
            for key, action in pairs(state.keys) do
                if action == command then return key end
            end
        end,
        GetNumBindings = function()
            state.scans = state.scans + 1
            state.snapshot = {}
            local commands = {}
            for _, action in pairs(template) do
                if not state.unsupported[action] then commands[action] = true end
            end
            for _, action in pairs(state.keys) do commands[action] = true end
            for action in pairs(commands) do
                local row = { action }
                for key, bound in pairs(state.keys) do
                    if bound == action then row[#row + 1] = key end
                end
                state.snapshot[#state.snapshot + 1] = row
            end
            return #state.snapshot
        end,
        GetBinding = function(i)
            local row = state.snapshot[i]
            return row[1], row[2], row[3]
        end,
        SetBinding = function(key, action, context)
            state.writes[#state.writes + 1] = { key, action, context }
            if modern and context ~= 1 then return false end
            if state.transientKey == key and action then
                state.transientKey = nil
                return false
            end
            if state.failKey == key and action then return false end
            if state.nilKey == key and action then return nil end
            if state.switchSetOnKey == key and action then state.set = 2 end
            state.keys[key] = action
            if state.nilSuccessKey == key then return nil end
            return true
        end,
        SaveBindings = function(set)
            state.saves[#state.saves + 1] = set
            if state.failSave then return false end
            state.savedSets[set] = copy(state.keys)
            return true
        end,
        LoadBindings = function(set)
            state.loads[#state.loads + 1] = set
            if state.failLoad then return false end
            state.set = set
            state.keys = copy(state.savedSets[set] or {})
            if state.loseRoundtrip and #state.saves > 0 then
                state.loseRoundtrip = false
                state.keys = copy(original)
            end
            return true
        end,
        SetModifiedClick = function() state.modifiedClicks = (state.modifiedClicks or 0) + 1 end,
        C_Timer = { After = function(_, fn) state.timers[#state.timers + 1] = fn end },
    }
    env._G = env
    setmetatable(env, { __index = _G })
    local function loadCode()
        assert(load(code, "native binding pipeline", "t", env))()
        defaults.FlushBindingRefreshAfterBulk = function()
            state.flushes = state.flushes + 1
        end
        defaults.FinishLoginBindingSeed = function() end
    end
    loadCode()
    local function drain()
        local count = 0
        while #state.timers > 0 do
            count = count + 1
            assert(count < 100, "binding timer loop")
            local before = #state.writes
            table.remove(state.timers, 1)()
            state.maxWritesPerTick = math.max(state.maxWritesPerTick or 0,
                #state.writes - before)
        end
    end
    local function reload()
        defaults._resetDetection = {}
        loadCode()
        assert(env.LoadBindings(state.set))
    end
    return state, defaults, db, drain, reload
end

for _, client in ipairs(clients) do
    local state, defaults, db, drain, reload = fixture(client, nil, 2)
    check(defaults.PrepareAccountBindingBootstrap(true)
        and db.defaultFluxBindingsChecked.account == "ready6",
        client .. ": fresh account schedules one keyboard setup")
    check(not defaults.EnsureDefaultFluxBindings("First-Realm"),
        client .. ": first world-entry pass starts on the same login")
    check(state.set == 1 and state.loads[1] == 1,
        client .. ": native account binding set is selected")
    check(db.defaultFluxBindingsChecked.account == "saved6"
        and #state.writes > 8 and #state.saves == 1,
        client .. ": complete keyboard is cleared, assigned and saved in one pass")
    drain()
    check(state.maxWritesPerTick == 0, client .. ": no deferred binding writes")
    check(db.defaultFluxBindingsChecked.account == "saved6"
        and #state.saves == 1 and state.saves[1] == 1,
        client .. ": native round trip awaits one real reload confirmation")
    check(state.loads[#state.loads] == 1 and state.flushes > 0,
        client .. ": native saved set is reloaded and consumers refreshed")
    check(state.scans == 1, client .. ": one native registry scan")
    check(state.savedSets[1]["CTRL-9"] == nil
        and state.savedSets[1].F5 == "FLUXRELOADUI",
        client .. ": custom keys are cleared and template saved")
    for key, command in pairs(template) do
        if not state.unsupported[command] then
            check(state.savedSets[1][key] == command,
                client .. ": persisted supported template key " .. key)
        end
    end
    local writes, saves, scans = #state.writes, #state.saves, state.scans
    reload()
    check(state.keys["7"] == "FLUXGRIDHEARTH"
        and state.keys["8"] == "FLUXCLASS_TELEPORT"
        and state.keys.Y == "FLUXGRIDSMARTMOUNT"
        and state.keys["6"] == "FLUXGRIDVENDORMOUNT",
        client .. ": bridge bindings survive a native reload")
    check(defaults.PrepareAccountBindingBootstrap(false)
        and defaults.EnsureDefaultFluxBindings("Other-Realm")
        and db.defaultFluxBindingsChecked.account == 6
        and #state.writes == writes and #state.saves == saves
        and state.scans == scans,
        client .. ": another login/character performs no second reset")
end

do
    local state, defaults, db, drain, reload = fixture("retail", 5, 1, {})
    check(defaults.PrepareAccountBindingBootstrap(false)
        and db.defaultFluxBindingsChecked.account == "legacy-check6",
        "old version-5 marker is inspected instead of blindly completed")
    check(not defaults.EnsureDefaultFluxBindings("First-Realm"),
        "empty account cache starts one migration repair")
    drain()
    check(db.defaultFluxBindingsChecked.account == "saved6" and #state.saves == 1
        and state.savedSets[1]["7"] == "FLUXGRIDHEARTH",
        "migration repair saves native account keys")
    local writes = #state.writes
    reload()
    check(defaults.PrepareAccountBindingBootstrap(false)
        and defaults.EnsureDefaultFluxBindings("First-Realm")
        and db.defaultFluxBindingsChecked.account == 6
        and #state.writes == writes and state.keys["7"] == "FLUXGRIDHEARTH",
        "repaired cache survives reload without another reset")
end

do
    local keys = copy(original)
    keys["7"], keys["8"], keys.Y, keys["6"] =
        "FLUXGRIDHEARTH", "FLUXCLASS_TELEPORT",
        "FLUXGRIDSMARTMOUNT", "FLUXGRIDVENDORMOUNT"
    local state, defaults, db = fixture("already bound", 5, 1, keys)
    check(defaults.PrepareAccountBindingBootstrap(false)
        and defaults.EnsureDefaultFluxBindings("First-Realm")
        and db.defaultFluxBindingsChecked.account == 6
        and #state.writes == 0 and #state.saves == 0,
        "legacy account with existing bridge keys is not cleared")
end

do
    local state, defaults, db, drain, reload = fixture("old failed6", "failed6", 1)
    check(defaults.PrepareAccountBindingBootstrap(false)
        and db.defaultFluxBindingsChecked.atomicContextRetryRequired,
        "old failed6 account gets one corrected-context automatic attempt")
    check(not defaults.EnsureDefaultFluxBindings("First-Realm"),
        "old failed6 attempt starts immediately even if bridge keys were present")
    drain()
    check(db.defaultFluxBindingsChecked.account == "saved6"
        and db.defaultFluxBindingsChecked.atomicContextRetryUsed
        and state.savedSets[1]["7"] == "FLUXGRIDHEARTH",
        "corrected-context migration saves complete keys")
    local writes = #state.writes
    reload()
    check(defaults.PrepareAccountBindingBootstrap(false)
        and defaults.EnsureDefaultFluxBindings("First-Realm")
        and db.defaultFluxBindingsChecked.account == 6
        and #state.writes == writes,
        "migrated failure confirms once and does not reset again")
end

do
    local state, defaults, db, drain = fixture("old version6 incomplete", 6, 1, {})
    check(defaults.PrepareAccountBindingBootstrap(false)
        and db.defaultFluxBindingsChecked.account == "legacy-check6",
        "old version6 marker receives one read-only native inspection")
    check(not defaults.EnsureDefaultFluxBindings("First-Realm"),
        "old version6 marker with missing bridge keys starts one repair")
    drain()
    check(db.defaultFluxBindingsChecked.account == "saved6"
        and state.savedSets[1]["7"] == "FLUXGRIDHEARTH",
        "incomplete old version6 account is repaired")
end

do
    local state, defaults, db = fixture("existing unmarked", nil, 1, {})
    check(not defaults.PrepareAccountBindingBootstrap(false)
        and db.defaultFluxBindingsChecked.account == 6
        and defaults.EnsureDefaultFluxBindings("Other-Realm")
        and #state.writes == 0,
        "existing account without a prior attempt is not reset")
end

do
    local state, defaults, db, drain, reload = fixture("failed assignment", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    state.failKey = "7"
    check(not defaults.EnsureDefaultFluxBindings("First-Realm"),
        "failing native assignment starts the batch")
    drain()
    check(db.defaultFluxBindingsChecked.account == "failed6"
        and #state.saves == 0 and state.keys.F5 == original.F5,
        "failed assignment restores old saved keys without false completion")
    local writes = #state.writes
    reload()
    check(not defaults.PrepareAccountBindingBootstrap(false)
        and defaults.EnsureDefaultFluxBindings("First-Realm")
        and #state.writes == writes,
        "failed automatic pass is not replayed indefinitely")
    state.failKey = nil
    check(defaults.ApplyKeybinds(), "explicit manual retry remains available")
    drain()
    check(db.defaultFluxBindingsChecked.account == "saved6"
        and state.savedSets[1]["7"] == "FLUXGRIDHEARTH",
        "successful manual repair marks account complete")
end

do
    local state, defaults, db, drain = fixture("failed save", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    state.failSave = true
    defaults.EnsureDefaultFluxBindings("First-Realm")
    drain()
    check(db.defaultFluxBindingsChecked.account == "failed6"
        and state.savedSets[1].F5 == original.F5,
        "SaveBindings failure restores original native set")
end

do
    local state, defaults, db, drain = fixture("nil native result", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    state.nilKey = "7"
    defaults.EnsureDefaultFluxBindings("First-Realm")
    drain()
    check(db.defaultFluxBindingsChecked.account == "failed6"
        and #state.saves == 0 and state.savedSets[1].F5 == original.F5,
        "nil SetBinding result is a failure and cannot mark an empty cache saved")
end

do
    local state, defaults, db, drain = fixture("transient native rejection", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    state.transientKey = "7"
    defaults.EnsureDefaultFluxBindings("First-Realm")
    drain()
    check(db.defaultFluxBindingsChecked.account == "saved6"
        and state.savedSets[1]["7"] == "FLUXGRIDHEARTH",
        "a transient failed native write is retried before saving")
end

do
    local state, defaults, db, drain = fixture("nil successful native result", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    state.nilSuccessKey = "7"
    defaults.EnsureDefaultFluxBindings("First-Realm")
    drain()
    check(db.defaultFluxBindingsChecked.account == "saved6"
        and state.savedSets[1]["7"] == "FLUXGRIDHEARTH",
        "verified native action counts even when SetBinding returns nil")
end

do
    local state, defaults, db, drain = fixture("binding set changed", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    state.switchSetOnKey = "7"
    defaults.EnsureDefaultFluxBindings("First-Realm")
    drain()
    check(db.defaultFluxBindingsChecked.account == "failed6"
        and #state.saves == 0 and state.savedSets[1].F5 == original.F5,
        "a native binding-set change cannot mark a different set saved")
end

do
    local state, defaults, db, drain = fixture("lost roundtrip", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    state.loseRoundtrip = true
    defaults.EnsureDefaultFluxBindings("First-Realm")
    drain()
    check(db.defaultFluxBindingsChecked.account == "failed6"
        and state.savedSets[1].F5 == original.F5,
        "failed native save/load verification rolls back the persisted template")
end

do
    local state, defaults, db, drain = fixture("late registry", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    state.unsupported.FLUXGRIDHEARTH = true
    check(not defaults.EnsureDefaultFluxBindings("First-Realm")
        and #state.writes == 0
        and db.defaultFluxBindingsChecked.account == "ready6",
        "missing Flux command never clears native keys")
    state.unsupported.FLUXGRIDHEARTH = nil
    check(not defaults.EnsureDefaultFluxBindings("First-Realm"),
        "late registration starts on the same login")
    drain()
    check(db.defaultFluxBindingsChecked.account == "saved6",
        "late registration saves the account set pending reload confirmation")
end

do
    local state, defaults, db, drain = fixture("atomic first pass", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    defaults.EnsureDefaultFluxBindings("First-Realm")
    check(db.defaultFluxBindingsChecked.account == "saved6"
        and state.savedSets[1]["7"] == "FLUXGRIDHEARTH",
        "first account pass saves before a later frame or reload")
    drain()
end

do
    local state, defaults, db, drain, reload = fixture("disk write lost", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    defaults.EnsureDefaultFluxBindings("First-Realm")
    drain()
    check(db.defaultFluxBindingsChecked.account == "saved6",
        "same-session native round trip awaits a real reload")
    state.savedSets[1] = copy(original) -- model missing disk persistence
    reload()
    check(defaults.PrepareAccountBindingBootstrap(false)
        and not defaults.EnsureDefaultFluxBindings("First-Realm")
        and db.defaultFluxBindingsChecked.account == "saved6"
        and db.defaultFluxBindingsChecked.accountRepairUsed,
        "lost disk save gets one bounded repair on next login")
    drain()
    check(db.defaultFluxBindingsChecked.account == "saved6",
        "repair waits for a second real reload confirmation")
    state.savedSets[1] = copy(original)
    reload()
    local writes = #state.writes
    check(defaults.PrepareAccountBindingBootstrap(false)
        and defaults.EnsureDefaultFluxBindings("First-Realm")
        and db.defaultFluxBindingsChecked.account == "failed6"
        and #state.writes == writes,
        "a second lost disk save stops automatic resets")
end

do
    local state, defaults, db, drain = fixture("overlap", nil, 1)
    defaults.PrepareAccountBindingBootstrap(true)
    defaults.EnsureDefaultFluxBindings("First-Realm")
    check(not defaults.ApplyKeybinds(), "overlapping reset is ignored")
    drain()
    check(#state.saves == 1 and db.defaultFluxBindingsChecked.account == "saved6",
        "overlap cannot queue a second keyboard pass")
end

local combat = part("function FluxDefaultSettings.ApplyCombatDefaultsPack(force)",
    "--- Action Bars: bars 2")
check(not combat:find("SaveBindings(", 1, true),
    "combat CVar defaults cannot save an unloaded keyboard during PLAYER_LOGIN")
do
    local helper = part("function FluxDefaultSettings.SavePendingModifiedClicks()",
        "-- Use the account binding set")
    local saves, bound, shown = 0, false, false
    local defaults = { _pendingModifiedClickSave = true, _resetDetection = {} }
    local db = { defaultFluxBindingsChecked = { account = 6 } }
    local env = {
        FluxDefaultSettings = defaults, FluxUI_DB = db,
        InCombatLockdown = function() return false end,
        SettingsPanel = { IsShown = function() return shown end },
        GetCurrentBindingSet = function() return 1 end,
        GetNumBindings = function() return 1 end,
        GetBinding = function() return "MOVEFORWARD", bound and "W" or nil end,
        SaveBindings = function() saves = saves + 1; return true end,
        FLUX_BINDING_READY = "ready6", FLUX_BINDING_LEGACY = "legacy-check6",
        FLUX_BINDING_ATTEMPTED = "attempted6",
    }
    setmetatable(env, { __index = _G })
    assert(load(helper, "modified-click persistence guard", "t", env))()
    check(not defaults.SavePendingModifiedClicks() and saves == 0,
        "modified clicks cannot save the keyboard before world entry")
    defaults._worldEntered = true
    check(not defaults.SavePendingModifiedClicks() and saves == 0,
        "an empty native keyboard is never saved")
    bound, shown = true, true
    check(not defaults.SavePendingModifiedClicks() and saves == 0,
        "Blizzard Settings owns its open-panel binding save")
    shown = false
    check(defaults.SavePendingModifiedClicks() and saves == 1
        and not defaults._pendingModifiedClickSave,
        "loaded keyboard can save modified clicks once after world entry")
end
local login = part('if event == "PLAYER_LOGIN" then',
    'elseif event == "PLAYER_ENTERING_WORLD" then')
local world = part('elseif event == "PLAYER_ENTERING_WORLD" then',
    'elseif event == "COMPACT_UNIT_FRAME_PROFILES_LOADED" then')
check(login:find('_pendingInitialAccountDefaults = charKey', 1, true)
    and world:find('FluxDefaultSettings.Apply, false, true', 1, true)
    and login:find('_pendingLoginBindingSeed = charKey', 1, true),
    "first account defers defaults and keyboard work until first world entry")
print("full Flux binding persistence: " .. checks .. " checks passed")
