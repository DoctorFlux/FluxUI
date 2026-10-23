-- Real suppression service and caller paths; native Edit Mode/taint need WoW.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local function slice(s, first, last)
    local a = assert(s:find(first, 1, true)); return s:sub(a, assert(s:find(last, a + #first, true)) - 1)
end
local hideSource = read("Blizzard/Hide.lua")
local runtimeSource = read("UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua")
local playerSource = read("UnitFrames/FluxUnitFrames_Player.lua")
local writeSource = read("BlizzardSettings/Write.lua")
local uiSource = read("Core/FluxAPI/UI.lua")
local editSource = slice(uiSource, "-- Edit Mode reads Blizzard frame state", "-- Flux owns these HUD systems.")
    .. slice(uiSource, "local editModeCallbacksInstalled = false", "local function WatchEditModeSpecLayoutSilence")
    .. "\nInstallEditModeCallbacks()"
local statusSource = slice(read("StatusBars/FluxStatusBar.lua"), "local function HideBlizzardBars()",
    "-------------------------------------------------------------------------------\n-- UPDATE FUNCTIONS")
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function exercise(branch, source)
    local sources = type(source) == "table" and source or { hide = source }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local s = { combat = false, ready = false, wanted = true, writes = 0, hooks = 0, frames = {}, timers = {}, deferred = {} }
    local methods = {}
    local function frame(name, owned, editMode, split, click, motion, wheel)
        local f = { name = name, owned = owned, editMode = editMode, children = {}, scripts = {}, events = {},
            shown = true, alpha = 1, click = click == true, motion = motion == true, wheel = wheel == true }
        local ownMethods = {}
        for k, v in pairs(methods) do ownMethods[k] = v end
        if not split then
            ownMethods.IsMouseClickEnabled, ownMethods.SetMouseClickEnabled = nil, nil
            ownMethods.IsMouseMotionEnabled, ownMethods.SetMouseMotionEnabled = nil, nil
        end
        setmetatable(f, { __index = ownMethods }); s.frames[#s.frames + 1] = f
        return f
    end
    local function write()
        if s.combat or s.editing then s.illegal = (s.illegal or 0) + 1 end
        check(not s.combat and not s.editing, "no native structural/input writes during combat/Edit Mode"); s.writes = s.writes + 1
    end
    function methods:GetName() return self.name end
    function methods:IsProtected() return not self.owned end
    function methods:GetParent() return self.parent end
    function methods:SetParent(parent) write(); check(not self.editMode, "native Edit Mode root never reparented"); self.parent = parent end
    function methods:GetChildren() return table.unpack(self.children) end
    function methods:SetAllPoints() end
    function methods:IsShown() return self.shown end
    function methods:Hide() write(); check(not self.editMode, "native Edit Mode root never hidden"); self.shown = false end
    function methods:Show() write(); self.shown = true end
    function methods:SetAlpha(value) write(); self.alpha = value end
    function methods:GetAlpha() return self.alpha end
    function methods:IsMouseClickEnabled() return self.click end
    function methods:IsMouseMotionEnabled() return self.motion end
    function methods:IsMouseWheelEnabled() return self.wheel end
    function methods:IsMouseEnabled() return self.click or self.motion end
    function methods:SetMouseClickEnabled(v) write(); self.click = v end
    function methods:SetMouseMotionEnabled(v) write(); self.motion = v end
    function methods:EnableMouseWheel(v) write(); self.wheel = v end
    function methods:EnableMouse(v) write(); self.click, self.motion = v, v end
    function methods:SetScript(event, fn)
        check(self.owned, "native scripts are never replaced")
        check(event ~= "OnUpdate", "suppression adds no permanent OnUpdate")
        self.scripts[event] = fn
    end
    function methods:HookScript() s.hooks = s.hooks + 1 end
    function methods:RegisterEvent(event) self.events[event] = {} end
    function methods:RegisterUnitEvent(event, ...) self.events[event] = { ... } end
    function methods:UnregisterEvent(event)
        if not self.owned then check(not s.editing, "native unit event changes wait for Edit Mode exit") end
        self.events[event] = nil
    end
    function methods:UnregisterAllEvents()
        if not self.owned then check(not s.editing, "native event changes wait for Edit Mode exit") end
        self.events = {}
    end
    function methods:IsEventRegistered(event)
        local units = self.events[event]; if units then return true, table.unpack(units) end
        return false
    end
    env.InCombatLockdown = function() return s.combat end
    env.CreateFrame = function() return frame(nil, true, false, true) end
    env.C_Timer = { After = function(_, callback) s.timers[#s.timers + 1] = callback end }
    env.FluxUnitFrames_ShouldUseFlux = function(unit) return unit == "player" and s.wanted end
    env.unpack = table.unpack
    env.UIParent = frame("UIParent", true, false, true)
    local ns = { Flux = { Client = { branch = branch } }, UnitFrames = {
        IsInitialized = function() return s.ready end,
        RegisterInitializer = function() end,
        DeferProtected = function(key, callback) s.deferred[key] = callback end,
    } }
    env.Flux = ns.Flux
    local function run(body) return assert(load(body, "@native-mouse-production", "t", env))("_FluxUI", ns) end
    run(sources.hide or hideSource)
    local blizz = ns.Flux.Blizz
    local grid = frame("CompactPartyFrame", false, true, true, true, true)
    local member = frame("CompactPartyFrameMember1", false, false, true, true, true)
    grid.children = { member }; grid.parent = env.UIParent; grid.alpha = 0.7
    local originalScript = function() end
    grid.scripts.OnShow = originalScript; grid.events.GROUP_ROSTER_UPDATE = {}
    local hooks = s.hooks
    blizz.Hide(grid, { keepEvents = true, keepParent = true })
    check(grid.parent == env.UIParent and grid.shown and grid.alpha == 0,
        branch .. ": native grid keeps secure parent/shown state while artwork is hidden")
    check(not grid.click and not member.click and grid.scripts.OnShow == originalScript and s.hooks == hooks,
        "native grid suppresses input without hooking native OnShow")
    check(grid.events.GROUP_ROSTER_UPDATE, "native roster events retained")
    blizz.Hide(grid, { keepEvents = true, keepParent = true })
    blizz.Unhide(grid)
    check(grid.alpha == 0.7 and grid.click and member.click and grid.parent == env.UIParent,
        "native grid restoration preserves original alpha/input/parent after repeated suppression")
    s.combat = true; local before = s.writes
    blizz.Hide(grid, { keepEvents = true, keepParent = true })
    blizz.Unhide(grid)
    check(s.writes == before, "native grid toggle during combat performs no forbidden writes")
    s.combat = false
    for _, f in ipairs(s.frames) do
        if f.events.PLAYER_REGEN_ENABLED and f.scripts.OnEvent then f.scripts.OnEvent(f, "PLAYER_REGEN_ENABLED") end
    end
    check(grid.alpha == 0.7 and grid.click, "latest deferred grid toggle restores the original state")
    blizz.Hide(grid, { keepEvents = true, keepParent = true })
    s.combat = true; blizz.Unhide(grid); blizz.Hide(grid, { keepEvents = true, keepParent = true })
    s.combat = false
    for _, f in ipairs(s.frames) do
        if f.events.PLAYER_REGEN_ENABLED and f.scripts.OnEvent then f.scripts.OnEvent(f, "PLAYER_REGEN_ENABLED") end
    end
    blizz.Unhide(grid)
    check(grid.alpha == 0.7 and grid.click, "cancelled deferred restoration cannot overwrite the original alpha snapshot")
    local player = frame("PlayerFrame", false, true, true, true, true, true)
    player.unit = "player"; env.PlayerFrame = player
    player.events.UNIT_ENTERED_VEHICLE = {}; player.events.UNIT_HEAL_PREDICTION = { "player", "vehicle" }
    player.PlayerFrameContent = frame("PlayerFrameContent", false, false, true, false, true)
    player.PlayerFrameContainer = frame("PlayerFrameContainer", false, false, true, true, true)
    local health = frame("PlayerFrameHealthBar", false, false, true, false, true)
    local legacy = frame("PlayerFrameManaBar", false, false, false, true, true)
    local pet = frame("PetFrame", false, false, true, true, true)
    local resources = frame("PlayerBottomManagedFrameContainer", false, false, true, true, true)
    local totem = frame("TotemFrame", false, false, true, true, true)
    env.PlayerBottomManagedFrameContainer, env.TotemFrame = resources, totem
    player.children = { player.PlayerFrameContent, player.PlayerFrameContainer, health, legacy, pet, resources, totem }
    local originalCast = function() end
    player.scripts.OnEvent, health.scripts.OnEnter = originalCast, originalCast
    run(sources.runtime or runtimeSource)
    -- Already-in-combat startup must retain the usable native fallback.
    s.combat = true
    env.FluxUnitFrames_SuppressBlizzardUnitFrame("player")
    check(player.click and health.motion and legacy.click, branch .. ": no replacement preserves fallback input")
    s.ready = true; env.FluxUnitFrames_SuppressBlizzardUnitFrame("player")
    check(player.click and s.deferred["suppress.player"], "combat suppression deferred until replacement is legal")
    s.combat = false; s.deferred["suppress.player"]()
    check(not player.click and not player.motion and not player.wheel, "transparent native player root is mouse-transparent")
    check(not health.motion and not legacy.click and not legacy.motion, "nested modern/legacy status bars stop catching input")
    check(pet.click and resources.click and totem.click, "independent pet/class-resource/totem controls keep input")
    check(player.unit == "player" and player.events.UNIT_ENTERED_VEHICLE and player.scripts.OnEvent == originalCast,
        "native player/vehicle/aura ownership is preserved")
    check(health.scripts.OnEnter == originalCast and player.shown, "native handlers and Edit Mode root visibility are preserved")
    check(not player.PlayerFrameContainer.shown and not player.PlayerFrameContainer.click
        and not player.PlayerFrameContent.shown, "unused player artwork containers are hidden and mouse-transparent")
    local writes = s.writes
    env.FluxUnitFrames_SuppressBlizzardUnitFrame("player")
    -- Content/alpha can be reasserted by the existing coordinator; no input setter repeats.
    check(not player.click and not health.motion, "repeated player suppression remains effective")
    s.wanted = false; env.FluxUnitFrames_RefreshBothSidesAfterToggle()
    check(player.click and player.motion and player.wheel and not health.click and health.motion,
        "Blizzard selection restores exact split input states")
    check(legacy.click and legacy.motion, "legacy combined mouse input restored")
    check(player.PlayerFrameContainer.shown and player.PlayerFrameContainer.click and player.PlayerFrameContent.shown,
        "native selection restores original player artwork container visibility/input")
    player.PlayerFrameContainer.shown = false
    env.FluxUnitFrames_SetBlizzardPlayerPredictionMuted(true)
    player.PlayerFrameContainer.shown = true -- a later native/external refresh
    env.FluxUnitFrames_SetBlizzardPlayerPredictionMuted(true)
    env.FluxUnitFrames_SetBlizzardPlayerPredictionMuted(false)
    check(not player.PlayerFrameContainer.shown, "repeated suppression preserves an originally hidden artwork container")
    check(player.events.UNIT_HEAL_PREDICTION[2] == "vehicle", "native overlay unit filters restored")
    -- Generic helper: overlapping owners, late children, reparented children and
    -- latest-request-wins combat deferral without extra hooks/timers.
    local root = frame("mouseRoot", false, true, true, true, false)
    local child = frame("mouseChild", false, false, true, false, true, true)
    root.children = { child }
    blizz.SetMouseSuppressed(root, true); blizz.SetMouseSuppressed(child, true)
    writes = s.writes; local hooks, timers = s.hooks, #s.timers
    for _ = 1, 20 do blizz.SetMouseSuppressed(root, true) end
    check(s.writes == writes and s.hooks == hooks and #s.timers == timers, "unchanged suppression adds no writes/hooks/timers")
    blizz.SetMouseSuppressed(root, false)
    check(root.click and not root.motion and not child.motion, "one owner cannot prematurely restore another owner's child")
    blizz.SetMouseSuppressed(child, false)
    check(not child.click and child.motion and child.wheel, "last owner restores original child input")
    blizz.SetMouseSuppressed(root, true)
    local late = frame("lateChild", false, false, true, true, true); root.children[2] = late
    blizz.SetMouseSuppressed(root, true); check(not late.click, "late native children join suppression")
    root.children = { late }; blizz.SetMouseSuppressed(root, true)
    check(child.motion and child.wheel, "child moved to another owner regains original input")
    s.combat = true; writes = s.writes
    blizz.SetMouseSuppressed(root, false); blizz.SetMouseSuppressed(root, true); blizz.SetMouseSuppressed(root, false)
    check(s.writes == writes and not root.click, "combat helper requests do not change input")
    s.combat = false
    for _, f in ipairs(s.frames) do
        if f.events.PLAYER_REGEN_ENABLED and f.scripts.OnEvent then f.scripts.OnEvent(f, "PLAYER_REGEN_ENABLED") end
    end
    check(root.click and late.click, "latest combat request reconciles once")
    writes = s.writes; blizz.SetMouseSuppressed(root, false); check(s.writes == writes, "restoration is idempotent")
    -- Execute the actual status-HUD readiness/combat gate and native topology.
    local modern = branch == "live" or branch == "forever" or branch == "classic"
    local manager = frame("StatusTrackingBarManager", false, modern, true, true, true)
    local container = frame("MainStatusTrackingBarContainer", false, modern, true, false, false)
    local bar = frame("ExperienceBarChild", false, false, true, true, true)
    container.children = { bar }; manager.children = { container }
    if modern then
        env.StatusTrackingBarManager, env.MainStatusTrackingBarContainer = manager, container
    else env.MainMenuExpBar = manager end
    env.statusHUDReady = false
    local hideStatus = run((sources.status or statusSource) .. "\nreturn HideBlizzardBars")
    hideStatus(); check(manager.click and bar.click, "status fallback stays clickable before HUD readiness")
    env.statusHUDReady = true; s.combat = true; hideStatus()
    check(manager.click and bar.click and env.nativeHidePending, "status fallback remains untouched in combat startup")
    s.combat = false; hideStatus()
    check(not manager.click and not bar.click and not bar.motion, "native status root and nested bars stop blocking the HUD")
    check(player.scripts.OnEvent == originalCast, "status suppression does not alter native player scripts")
    -- Execute the actual busy latch, keyed queue and Enter/Exit callbacks. The
    -- independent chrome painter is outside this fixture; all changed callers
    -- must stay idle even after the manager hides and before native reset ends.
    local callbacks = {}
    env.FLUX_API = { hasEditMode = true }
    env.EventRegistry = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end }
    env.SuppressOwnedEditModeChrome = function() end
    env.EditModeManagerFrame = { shown = false, IsShown = function(self) return self.shown end }
    run(editSource)
    run(sources.player or playerSource)
    run(sources.write or writeSource)
    local writeSettings = ns.Flux.BlizzardSettings.Write
    local modeRoot = frame("modeRoot", false, true, true, true, true)
    ns.PlayerFrame = frame("FluxPlayer", true, false, true)
    s.wanted = true
    env.EditModeManagerFrame.shown = true; callbacks["EditMode.Enter"](); s.editing = true
    writes = s.writes
    local applied = 0
    local function duringEditMode()
        blizz.SetMouseSuppressed(modeRoot, true)
        blizz.SetMouseSuppressed(modeRoot, false)
        blizz.SetMouseSuppressed(modeRoot, true)
        env.FluxUnitFrames_SuppressBlizzardUnitFrame("player")
        env.FluxUnitFrames_SetBlizzardPlayerPredictionMuted(true)
        env.FluxUnitFrames_RefreshBothSidesAfterToggle()
        env.FluxUnitFrames_ApplyFluxVsBlizzardRuntime()
        env.FluxUnitFrames_ApplyRuntimePlayer(false)
        hideStatus()
        writeSettings.Run("raid", function() check(not s.editing and not s.combat, "settings cannot reenter a native reset pass"); applied = applied + 1 end)
    end
    duringEditMode(); duringEditMode()
    check(s.writes == writes and modeRoot.click and applied == 0, "no mouse/unit/status/settings mutation during Edit Mode")
    env.EditModeManagerFrame.shown = false
    check(env.FluxEditModeBusy(), "busy latch spans native OnHide/ResetPartyFrames after IsShown becomes false")
    duringEditMode()
    check(s.writes == writes and applied == 0, "native close/reset pass remains untouched")
    s.editing = false; callbacks["EditMode.Exit"]()
    check(s.writes == writes and applied == 0, "Exit callback only schedules; never mutates on the native exit stack")
    -- A newer post-exit setting supersedes queued input before it drains.
    blizz.SetMouseSuppressed(modeRoot, false)
    local function flushTimers()
        local batch = s.timers; s.timers = {}
        for _, callback in ipairs(batch) do callback() end
    end
    flushTimers(); flushTimers()
    check(modeRoot.click and applied == 1, "newer input request wins and settings replay once on a later frame")
    writes = s.writes; flushTimers()
    check(s.writes == writes and applied == 1, "deferred Edit Mode work settles without polling or repeat mutation")
    -- Combat beginning during Edit Mode must keep deferred changes legal.
    env.EditModeManagerFrame.shown = true; callbacks["EditMode.Enter"](); s.editing = true
    blizz.SetMouseSuppressed(modeRoot, true)
    writeSettings.Run("raid", function() check(not s.combat, "combat settings replay"); applied = applied + 1 end)
    env.EditModeManagerFrame.shown = false; s.editing = false; s.combat = true
    callbacks["EditMode.Exit"](); writes = s.writes; flushTimers()
    check(modeRoot.click and s.writes == writes and applied == 1, "combat beginning before deferred exit work blocks all mutations")
    s.combat = false
    for _, f in ipairs(s.frames) do
        if f.events.PLAYER_REGEN_ENABLED and f.scripts.OnEvent then f.scripts.OnEvent(f, "PLAYER_REGEN_ENABLED") end
    end
    check(not modeRoot.click and applied == 2, "combat recovery completes deferred input and settings once")
    check(not s.illegal, "no illegal input mutation was attempted or swallowed by pcall")
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do exercise(branch) end
local mouseStart = assert(hideSource:find("function Blizz.SetMouseSuppressed", 1, true))
local unguardedMouse = hideSource:sub(1, mouseStart - 1)
    .. hideSource:sub(mouseStart):gsub('if EditModeBusy%(%) then', 'if false then', 1)
local mutants = {
    hideSource:gsub('SetMouseValue%(widget, getter, setting%[1%], false%)', 'SetMouseValue(widget, getter, setting[1], true)', 1),
    hideSource:gsub('SetMouseValue%(frame, getter, setting%[1%], setting%[2%]%)', 'SetMouseValue(frame, getter, setting[1], false)', 1),
    hideSource:gsub('if InCombat%(%) then', 'if false then', 1),
    hideSource:gsub('if keepParent%[frame%] then', 'if false then', 1),
    hideSource:gsub(' and not keepParent%[frame%] then', ' then', 1),
    { runtime = runtimeSource:gsub('if FluxEditModeBusy and FluxEditModeBusy%(%) then', 'if false then') },
    { player = playerSource:gsub('if FluxEditModeBusy and FluxEditModeBusy%(%) then', 'if false then', 1) },
    { status = statusSource:gsub('if FluxEditModeBusy and FluxEditModeBusy%(%) then', 'if false then', 1) },
    { write = writeSource:gsub('and not %(FluxEditModeBusy and FluxEditModeBusy%(%)%)', '', 1) },
    unguardedMouse,
    { runtime = runtimeSource:gsub('"PlayerFrameContent", "PlayerFrameContainer"', '"PlayerFrameContent"', 1) },
    { runtime = runtimeSource:gsub('savedPlayerVisuals%[content%] == nil', 'not savedPlayerVisuals[content]', 1) },
}
for i, mutant in ipairs(mutants) do check(not pcall(exercise, "forever", mutant), "negative control " .. i .. " rejected") end
print(("Native mouse suppression/Edit Mode: %d checks; five branches; %d negative controls passed"):format(checks, #mutants))
