-- lua tests/hud_startup.lua (Lua 5.4).
-- Execute actual lifecycle/guard functions with strict mock native controls.
local count = 0
local function check(value, message) assert(value, message); count = count + 1 end
local function read(path)
    local f = assert(io.open(path, "r")); local s = f:read("*a"); f:close(); return s
end
local status = read("StatusBars/FluxStatusBar.lua")
local micro = read("MicroMenu/FluxMicroMenu.lua")
local function slice(source, first, last)
    local a = assert(source:find(first, 1, true), first)
    local b = assert(source:find(last, a + #first, true), last)
    return source:sub(a, b - 1)
end
local noop = function() end
local function fixture()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.frames, env.hooks, env.timers, env.specs, env.marks = {}, {}, {}, {}, {}
    env.combat = false
    env.InCombatLockdown = function() return env.combat end
    env.CreateFrame = function()
        local f = { scripts = {}, events = {}, shown = true, hooks = {} }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:HookScript(event, fn)
            self.hooks[event] = self.hooks[event] or {}
            table.insert(self.hooks[event], fn)
        end
        env.frames[#env.frames + 1] = f
        return f
    end
    env.Flux = {
        loggedIn = false,
        Module = { Register = function(name, spec) env.specs[name] = spec end },
        Startup = {
            Mark = function(key) env.marks[key] = (env.marks[key] or 0) + 1 end,
            Count = noop,
        },
    }
    env.managedStartup = true
    env.C_Timer = { After = function(_, fn) env.timers[#env.timers + 1] = fn end }
    env.hooksecurefunc = function(name, fn) env.hooks[name] = fn end
    env.fire = function(event)
        for _, f in ipairs(env.frames) do
            if f.events[event] then f.scripts.OnEvent(f, event) end
        end
    end
    env.tick = function()
        local current = {}
        for _, f in ipairs(env.frames) do
            if f.shown and f.scripts.OnUpdate then current[#current + 1] = f end
        end
        for _, f in ipairs(current) do f.scripts.OnUpdate(f) end
    end
    env.compile = function(source) return assert(load(source, "HUD fixture", "t", env))() end
    return env
end

do
    local env = fixture()
    env.ClearInfoIntegratedColumnFlag = noop
    env.FluxStatusBarContainer = { IsProtected = function() return false end }
    env.ExpBar, env.RepBar = {}, {}
    env.FluxOptions = { GetStatusBarPosition = function() return 1 end }
    env.compile(slice(status, "function UpdateLayout()", "    -- List of bars to show")
        .. "\nreturn true end")
    check(env.UpdateLayout() == false and env.pendingStatusLayout, "missing menu returns pending without function properties")
    check(#env.timers == 0 and #env.frames == 0, "missing menu never arms an unbounded retry watcher")
    env.FluxMicroMenu = { IsProtected = function() return true end }
    env.combat = true
    check(env.UpdateLayout() == false, "protected menu anchor defers structural status layout")
    env.FluxMicroMenu.IsProtected = function() return false end
    check(env.UpdateLayout() == true and not env.pendingStatusLayout, "unprotected status layout remains available in combat")
end

do
    local env = fixture()
    local writes, hooks = 0, 0
    local native = {}
    for _, method in ipairs({ "SetParent", "Hide", "SetAlpha", "EnableMouse", "UnregisterAllEvents" }) do
        native[method] = function() assert(not env.combat, "native control mutation in combat"); writes = writes + 1 end
    end
    native.HookScript = function(_, _, fn) hooks = hooks + 1; env.onNativeShow = fn end
    env.MainMenuExpBar = native
    local hide = env.compile(slice(status, "local function HideBlizzardBars()", "-------------------------------------------------------------------------------\n-- UPDATE FUNCTIONS")
        .. "\nreturn HideBlizzardBars")
    hide()
    check(writes == 0, "native bars retained before replacement readiness")
    env.statusHUDReady, env.combat = true, true
    hide()
    check(writes == 0 and env.nativeHidePending, "native bars retained during combat startup")
    env.combat = false
    hide(); hide()
    check(writes > 0 and hooks == 1 and not env.nativeHidePending, "native suppression idempotent after custom HUD readiness")
    local before = writes
    env.combat = true
    env.onNativeShow(native)
    check(writes == before, "native OnShow hook declines protected hide in combat")
end

do
    local env = fixture()
    local displays, layouts = 0, 0
    env.EnsureGoldBarBagListener, env.CreateFluxDurabilityFrame = noop, noop
    env.UpdateExpBar, env.UpdateRepBar, env.UpdateGoldBar = function() displays = displays + 1 end,
        function() displays = displays + 1 end, function() displays = displays + 1 end
    env.MaybeUpdateLayoutForComposition = noop
    env.HideBlizzardBars = noop
    env.UpdateLayout = function() layouts = layouts + 1; return true end
    env.compile(slice(status, "local eventFrame = CreateFrame(\"Frame\")",
        "-- Hook into Currency Tracking Changes"))
    check(env.specs.StatusBars.phase == "hud" and env.specs.StatusBars.priority == 50
        and not env.specs.StatusBars.protected, "status display enters immediate HUD phase")
    check(env.specs.StatusBars.OnEnable() == false and displays == 0, "status respects pre-login configuration barrier")
    env.Flux.loggedIn, env.combat = true, true
    check(env.specs.StatusBars.OnEnable() == true and displays == 3, "all nonprotected status displays initialize during combat")
    env.fire("PLAYER_LOGIN"); env.fire("PLAYER_ENTERING_WORLD")
    check(layouts == 1 and env.marks.status_hud_ready == 1, "status lifecycle avoids repeated initial layout")
    check(#env.timers == 0 and #env.frames == 1, "status startup has no sixty-frame watcher")
end

do
    local env = fixture()
    local moved, nativeMuted = 0, 0
    env.FluxMicroMenu = { buttons = {}, ShouldLeaveBlizzardButtonShown = function() return false end }
    env.FluxGameMenuBlocksMicroTaintWork = function() return false end
    env.DiscoverButtons = function() return {} end
    env.BUTTONS_TO_HIDE = {}
    env.FluxRefreshCharacterMicroMouseover, env.ParkLeftoverMicroMenuLayoutChildren = noop, noop
    env.WatchEditModeMicroMenuSanitize = noop
    env.DisableBlizzardLayout = function() nativeMuted = nativeMuted + 1; check(moved > 0, "native controls muted after layout") end
    env.UpdateLayout = function() error("fixture layout failure") end
    local hijack = env.compile(slice(micro, "local function HijackButtons()", "-- Use a flag-based approach")
        .. "\nreturn HijackButtons")
    check(not pcall(hijack) and nativeMuted == 0, "failed layout retains native fallback controls")
    env.UpdateLayout = function() moved = moved + 1 end
    check(hijack() == true and nativeMuted == 1, "successful hijack reports readiness")
    env.combat = true
    check(hijack() == false and nativeMuted == 1 and env.FluxMicroMenu.needsUpdate, "combat hijack remains queued")
end

do
    local env = fixture()
    local rebuilds, layouts, notificationCalls = 0, 0, 0
    env.FluxMicroMenu, env.UIParent, env.ChatFrame1 = env.CreateFrame(), env.CreateFrame(), env.CreateFrame()
    env.FluxGameMenuBlocksMicroTaintWork = function() return false end
    env.InvalidateDiscoverCacheInternal, env.WatchEditModeMicroMenuSanitize = noop, noop
    env.UpdateLayout = function() layouts = layouts + 1 end
    env.HijackButtons = function()
        if env.combat then env.FluxMicroMenu.needsUpdate = true; return false end
        rebuilds = rebuilds + 1
        env.FluxMicroMenu.needsUpdate = false
        return true
    end
    env.FixMicroButtonNotifications = function() notificationCalls = notificationCalls + 1 end
    env.FluxOptions = { GetMicroMenuLayoutPosition = function() return 2 end }
    env.FCF_RestorePositionAndDimensions, env.FCF_DockUpdate = noop, noop
    local restoreOriginal = env.FCF_RestorePositionAndDimensions
    env.compile(slice(micro, "local pendingLayoutUpdate = false", "-- Classic/Anniversary")
        .. slice(micro, "WatchEditModeMicroMenuSanitize()\n\nFluxMicroMenu:RegisterEvent",
            "SLASH_FLUXMICRO1"))
    check(env.specs.MicroMenu.phase == "hud" and env.specs.MicroMenu.priority == 40
        and env.specs.MicroMenu.protected, "native micromenu hijack waits for legal HUD phase")
    check(env.specs.MicroMenu.OnEnable() == false and rebuilds == 0, "micromenu respects configuration barrier")
    env.Flux.loggedIn, env.combat = true, true
    env.fire("PLAYER_LOGIN")
    check(rebuilds == 0, "combat login retains usable native micromenu")
    env.combat = false
    env.fire("PLAYER_REGEN_ENABLED")
    check(rebuilds == 1 and env.marks.micromenu_ready == 1, "micromenu combat exit initializes once")
    env.fire("ADDON_LOADED"); env.fire("ADDON_LOADED"); env.fire("ADDON_LOADED")
    env.tick()
    check(rebuilds == 2, "late addon discovery requests coalesce")
    check(#env.ChatFrame1.hooks.OnSizeChanged == 1 and #env.ChatFrame1.hooks.OnShow == 1,
        "chat settle frame hooks install once")
    env.hooks.FCF_RestorePositionAndDimensions()
    env.hooks.FCF_DockUpdate()
    env.tick()
    check(layouts == 1 and env.FCF_RestorePositionAndDimensions == restoreOriginal,
        "actual chat restores request one layout without replacing native API")
    check(#env.timers == 0, "micromenu initialization has no arbitrary settle timers")
end

print(("PASS: %d HUD-startup checks (extracted actual lifecycle/guard functions; WoW taint still requires live tests)"):format(count))
