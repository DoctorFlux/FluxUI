-- Production Edit Mode queue: missing Exit recovery must wait for a later
-- frame, and must not mistake a temporary locked dialog hide for an exit.
local f = assert(io.open("Core/FluxAPI/UI.lua", "rb")); local full = f:read("*a"):gsub("\r\n", "\n"); f:close()
local function slice(first, last)
    local a = assert(full:find(first, 1, true)); return full:sub(a, assert(full:find(last, a, true)) - 1)
end
local source = slice("-- Edit Mode reads Blizzard frame state", "-- Flux owns these HUD systems.")
    .. slice("local editModeCallbacksInstalled = false", "local function WatchEditModeSpecLayoutSilence")
    .. "\nInstallEditModeCallbacks()"
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function exercise(branch, code)
    local timers, callbacks, jobs = {}, {}, 0
    local closing, shown, active, locked = false, false, false, false
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.EditModeManagerFrame = { IsShown = function() return shown end,
        IsEditModeActive = function() return active end, IsEditModeLocked = function() return locked end }
    env.FLUX_API = { hasEditMode = true }
    env.EventRegistry = { RegisterCallback = function(_, key, fn) callbacks[key] = fn end }
    env.C_Timer = { After = function(_, fn) check(type(fn) == "function", "scheduled callback exists"); timers[#timers + 1] = fn end }
    env.SuppressOwnedEditModeChrome = function() end
    assert(load(code or source, "@production-edit-recovery", "t", env))()
    local function frame()
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
    end
    local function work() check(not closing and not shown and not active and not locked, "work never enters native close/dialog pass"); jobs = jobs + 1 end
    shown, active = true, true; callbacks["EditMode.Enter"](); frame()
    env.FluxAfterEditMode(work, "layout"); env.FluxAfterEditMode(work, "layout")
    shown, active, closing = false, false, true
    for _ = 1, 10 do check(env.FluxEditModeBusy(), "native close remains busy synchronously") end
    check(jobs == 0 and #timers == 1, "failed native exit schedules one recovery, never inline")
    closing = false; frame()
    check(jobs == 1 and not env.FluxEditModeBusy(), branch .. ": missing Exit callback recovers and flushes once")
    frame(); check(jobs == 1 and #timers == 0, "recovery adds no recurring timer")
    shown, active = true, true; callbacks["EditMode.Enter"](); frame()
    env.FluxAfterEditMode(work, "layout")
    shown, active = false, false; check(env.FluxEditModeBusy(), "recovery queued")
    shown, active = true, true; frame()
    check(jobs == 1 and env.FluxEditModeBusy(), "reopening before recovery preserves editor ownership")
    shown, locked = false, true
    for _ = 1, 5 do check(env.FluxEditModeBusy(), "temporary dialog hide remains busy") end
    frame(); check(jobs == 1 and #timers == 0, "dialog hide neither drains nor polls")
    active, locked = false, false; callbacks["EditMode.Exit"]()
    check(jobs == 1, "normal Exit remains deferred")
    frame(); check(jobs == 2 and not env.FluxEditModeBusy(), "normal Exit still flushes exactly once")
end
for _, branch in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do exercise(branch) end
-- Execute the actual branch-specific native Enter/Exit/getter implementations.
-- The injected native reset error models an exception boundary, not secret VM behavior.
local function nativeExitCase(branch)
    local file = assert(io.open("../__AddonsForRef/wow-ui-source-" .. branch .. "/Interface/AddOns/Blizzard_EditMode/Shared/EditModeManager.lua", "rb"))
    local native = file:read("*a"):gsub("\r\n", "\n"); file:close()
    local timers, callbacks, jobs, exits = {}, {}, 0, 0
    local resetting, failReset = false, true
    local noop = function() end
    local env = setmetatable({ EditModeManagerFrameMixin = {}, FLUX_API = { hasEditMode = true },
        C_UnitAuras = { SwitchAuraDataProvider = noop, ResetAuraDataProvider = noop },
        C_EditMode = { OnEditModeExit = noop }, PlaySound = noop, SOUNDKIT = {},
        SuppressOwnedEditModeChrome = noop }, { __index = _G }); env._G = env
    env.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    env.EventRegistry = { RegisterCallback = function(_, key, fn) callbacks[key] = fn end,
        TriggerEvent = function(_, key)
            if key == "EditMode.Exit" then exits = exits + 1 end
            if callbacks[key] then callbacks[key]() end
        end }
    for _, method in ipairs({ "EnterEditMode", "ExitEditMode", "IsEditModeActive", "IsEditModeLocked" }) do
        local body = assert(native:match("function EditModeManagerFrameMixin:" .. method .. "%([^)]*%)\n.-\nend"), method)
        assert(load(body, "@native-" .. branch .. "-" .. method, "t", env))()
    end
    local manager = setmetatable({ shown = false, IsShown = function(self) return self.shown end },
        { __index = env.EditModeManagerFrameMixin })
    env.EditModeManagerFrame = manager
    for _, method in ipairs({ "ClearActiveChangesFlags", "UpdateDropdownOptions", "ShowSystemSelections",
        "RevertAllChanges", "HideSystemSelections", "InvokeOnAnyEditModeSystemAnchorChanged" }) do manager[method] = noop end
    manager.AccountSettings = { OnEditModeEnter = noop, OnEditModeExit = function()
        resetting = true
        check(env.FluxEditModeBusy(), "native account reset remains busy before Exit event")
        if failReset then error("injected native account reset failure") end
        resetting = false
    end }
    assert(load(source, "@production-edit-recovery", "t", env))()
    local function frame()
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
    end
    manager.shown = true; manager:EnterEditMode(); frame()
    env.FluxAfterEditMode(function() check(not resetting, "recovery never runs on native reset stack"); jobs = jobs + 1 end)
    manager.shown = false
    local ok, err = pcall(manager.ExitEditMode, manager)
    check(not ok and tostring(err):find("injected native account reset failure", 1, true), "actual native exit fails at injected boundary")
    check(exits == 0 and manager:IsEditModeActive() == false and env.FluxEditModeBusy(),
        "actual native exit clears active before failing and omits Exit notification")
    resetting = false; frame()
    check(jobs == 1 and not env.FluxEditModeBusy(), branch .. ": actual native failed-exit path recovers")
    manager.shown = true; manager:EnterEditMode(); frame()
    env.FluxAfterEditMode(function() jobs = jobs + 1 end)
    manager.shown = false; manager.editModeLockState = "hideSelections"
    check(env.FluxEditModeBusy(), "actual native active/lock getters preserve dialog hide")
    frame(); check(jobs == 1, "native dialog hide does not release work")
    manager.editModeLockState = nil; failReset = false; manager:ExitEditMode()
    check(exits == 1 and jobs == 1, "ordinary native exit dispatches without inline work")
    frame(); check(jobs == 2, "ordinary native exit still drains once")
end
for _, branch in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do nativeExitCase(branch) end
local mutant, n = source:gsub('if editModeOpen and NativeEditModeClosed%(%) then editModeOpen = false end', '', 1)
check(n == 1 and not pcall(exercise, "live", mutant), "negative control rejects lost Exit deadlock")
print("Edit Mode recovery: " .. checks .. " checks; five client models and native source methods; negative control passed")
