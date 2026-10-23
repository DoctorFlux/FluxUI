-- lua Bars/_tmp_stockgridsmoke.lua
-- Replays supplied native grid/layout methods with the real Flux suppression
-- and combat queue. Event delivery/protected writes are modeled, not WoW taint.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Read(path)
    local f = assert(io.open(root .. path, "r"))
    local source = f:read("*a"); f:close()
    return (source:gsub("\r\n", "\n"))
end
local function Compile(source, env, name)
    if setfenv then
        local fn = assert(loadstring(source, name)); setfenv(fn, env); return fn
    end
    return assert(load(source, name, "t", env))
end
local function Load(path, env, ns)
    return Compile(Read(path), env, "@" .. path)("_FluxUI", ns)
end
local function Method(env, path, name)
    local source = Read(path)
    local a = assert(source:find("function " .. name .. "(", 1, true), name)
    local b = assert(source:find("\nend", a, true), name)
    Compile(source:sub(a, b + 3), env, "@" .. path .. ":" .. name)()
end
local GRID = { "ACTIONBAR_SHOWGRID", "ACTIONBAR_HIDEGRID", "PET_BAR_SHOWGRID", "PET_BAR_HIDEGRID" }
local GRID_SET = {}; for _, event in ipairs(GRID) do GRID_SET[event] = true end
local MAIN = { "MainActionBar", "MainMenuBar" }
local MULTI = { "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight", "MultiBar5", "MultiBar6", "MultiBar7" }
local function Boot(client, options)
    options = options or {}
    -- MoP has no supplied snapshot: use Era methods as an explicit compatibility
    -- fixture and expose only Classic-style capabilities/legacy frame aliases.
    local snapshot = client == "mop" and "classic_era" or client
    local base = "../__AddonsForRef/wow-ui-source-" .. snapshot .. "/Interface/AddOns/"
    local classic = client:find("classic", 1, true) or client == "mop"
    local locked, frames, queue, calls, fluxGrid, alphaOrder = false, {}, {}, {}, {}, {}
    local layouts, stockGrid, removals = 0, 0, 0
    local ns = { Flux = { Bars = { NUM_NATIVE = 0 }, Client = {
        isRetail = not classic, isPostDF = not classic, isAnyClassic = not not classic,
        isCamelot = client == "forever", isForever = client == "forever",
    } } }
    local F = ns.Flux
    local env = setmetatable({}, { __index = _G }); env._G = env
    local function Noop() end
    local function Frame(name)
        local frame = { name = name, events = {}, scripts = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:IsEventRegistered(event) return self.events[event] == true end
        function frame:UnregisterEvent(event)
            if GRID_SET[event] then
                assert(not locked, "grid event unregistered during combat")
                removals = removals + 1
                calls[self] = calls[self] or {}
                calls[self][event] = (calls[self][event] or 0) + 1
            end
            self.events[event] = nil
        end
        function frame:SetScript(script, fn) self.scripts[script] = fn end
        frame.Hide, frame.SetSize, frame.SetPoint = Noop, Noop, Noop
        frames[#frames + 1] = frame
        return frame
    end
    env.UIParent = { GetHeight = function() return 1080 end }
    env.MinimapCluster = { GetHeight = function() return 190 end }
    env.CreateFrame = function(_, name) return Frame(name) end
    env.InCombatLockdown = function() return locked end
    env.C_Timer = { After = function(_, fn) queue[#queue + 1] = fn end }
    F.Timer = { After = env.C_Timer.After, Defer = function(fn) queue[#queue + 1] = fn end }
    F.Safecall = function(fn) fn() end
    F.Restricted = { Works = function() return false end, PagingWorks = function() return false end }
    env.EventRegistry = { RegisterCallback = Noop }
    env.InputUtil = { IsGamepadUIEnabled = function() return options.gamepad == true end }
    env.KeybindFrames_InQuickKeybindMode = function() return false end
    env.UnitAffectingCombat = function() return locked end
    env.GetCursorInfo = function() return "item" end
    env.tInvert = function(t) local out = {}; for _, v in pairs(t) do out[v] = true end; return out end
    -- These reason bits are disjoint in the native methods under test.
    env.bit = {
        bor = function(a, b) return math.floor(a / b) % 2 == 1 and a or a + b end,
        band = function(a, complement) local b = -complement - 1; return math.floor(a / b) % 2 == 1 and a - b or a end,
        bnot = function(a) return -a - 1 end,
    }
    env.table = setmetatable({ wipe = function(t) for k in pairs(t) do t[k] = nil end end }, { __index = table })
    env.ACTION_BUTTON_SHOW_GRID_REASON_EVENT, env.ACTION_BUTTON_SHOW_GRID_REASON_SPELLCOLLECTION = 1, 2
    env.MAIN_ACTION_BAR_OFFSET_X, env.MAIN_ACTION_BAR_OFFSET_Y, env.MAIN_ACTION_BAR_DEFAULT_OFFSET_Y = 0, 0, 0
    env.EditModeManagerFrameMixin, env.LayoutMixin = {}, {}
    -- Route to bottom layout without modeling Edit Mode's saved anchor geometry.
    env.EditModeUtil = {
        IsBottomAnchoredActionBar = function() return true end,
        GetBottomActionBars = function() return {} end,
        GetRightContainerAnchor = function() return { SetPoint = Noop } end,
    }
    env.EditModeManagerFrame = setmetatable({
        IsInitialized = function() return true end, IsEditModeActive = function() return false end,
        GetBottomActionBars = function() return {} end,
    }, { __index = env.EditModeManagerFrameMixin })
    local container = setmetatable({
        GetLayoutChildren = function() return {} end,
        LayoutChildren = function() return 0, 0, false end,
        CalculateFrameSize = function() return 1, 1 end,
        SetSize = function()
            assert(not locked, "RightManagedFrameContainer:SetSize() [modeled insecure combat]")
            layouts = layouts + 1
        end,
        MarkClean = Noop, ClearAllPoints = Noop,
        BottomManagedLayoutContainer = { Layout = Noop },
    }, { __index = env.LayoutMixin })
    env.GetRightManagedFrameContainer = function() return container end
    env.UIParentRightManagedFrameContainer = container
    local rightMethod = classic and "UIParentManageRightFrameContainer" or "ManageRightFrameContainer"
    env.FramePositionDelegate = { SetAttribute = function(self) self[rightMethod](self) end }
    local panel = base .. "Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua"
    Method(env, base .. "Blizzard_SharedXML/LayoutFrame.lua", "LayoutMixin:Layout")
    Method(env, panel, "FramePositionDelegate:" .. rightMethod)
    Method(env, panel, classic and "UIParent_ManageFramePositions" or "ManageFramePositions")
    for _, name in ipairs({ "UpdateActionBarLayout", "UpdateBottomActionBarPositions" }) do
        Method(env, base .. "Blizzard_EditMode/Shared/EditModeManager.lua", "EditModeManagerFrameMixin:" .. name)
    end
    Load(base .. "Blizzard_ActionBar/Shared/ActionBar.lua", env, ns)
    Load("Core/Engine/Combat.lua", env, ns)
    local function AddBar(name, show, hide)
        local bar = Frame(name)
        setmetatable(bar, { __index = env.ActionBarMixin })
        bar.showGridEventName, bar.hideGridEventName = show, hide
        bar.actionButtons, bar.shownButtonContainers, bar.numButtonsShowable = {}, {}, 1
        bar.isShownExternal, bar.visibility = true, "Hidden"
        bar.UpdateVisibility = env.EditModeActionBarMixin.UpdateVisibility
        bar.ShowBase, bar.HideBase, bar.SetShownBase = Noop, Noop, Noop
        bar.SetFrameStrata, bar.GetFrameStrata = Noop, function() return "MEDIUM" end
        bar.GetParent = function() return env.UIParent end
        bar.GetAlpha = function() return 0 end
        bar.SetAlpha = function()
            alphaOrder[bar] = alphaOrder[bar] or { show = bar.events[show], hide = bar.events[hide] }
        end
        local button = { index = 1, container = { SetShown = Noop }, GetAttribute = Noop,
            HasAction = function() return false end, SetShown = Noop }
        function button:SetShowGrid(shown) stockGrid = stockGrid + 1; self.grid = shown end
        function button:GetShowGrid() return self.grid end
        bar.actionButtons[1] = button
        bar:SetScript("OnEvent", env.ActionBarMixin.ActionBar_OnEvent)
        if show then bar:RegisterEvent(show) end
        if hide then bar:RegisterEvent(hide) end
        env[name] = bar
        return bar
    end
    local listener = Frame("FluxGridListener")
    for _, event in ipairs(GRID) do listener:RegisterEvent(event) end
    listener:SetScript("OnEvent", function(_, event) fluxGrid[event] = (fluxGrid[event] or 0) + 1 end)
    -- Sentinel subscriptions must survive initialization and later reassertions.
    local override = Frame("OverrideActionBar")
    override.IsShown = function() return false end
    for _, event in ipairs(GRID) do override:RegisterEvent(event) end
    env.OverrideActionBar = override
    local function Emit(event, ...)
        for _, frame in ipairs(frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
        end
    end
    local function Tick()
        local pending = queue; queue = {}; for _, fn in ipairs(pending) do fn() end
    end
    local function Install() Load("Bars/Blizzard.lua", env, ns); return F.Bars.Blizzard end
    local function AssertDetached(bar, events)
        for _, event in ipairs(events or { bar.showGridEventName, bar.hideGridEventName }) do
            assert(not bar.events[event], client .. ": stock grid still registered on " .. bar.name .. ":" .. event)
        end
    end
    local function AssertProtectedRoute(event)
        local ok, err = pcall(Emit, event)
        assert(not ok and tostring(err):find("RightManagedFrameContainer:SetSize()", 1, true),
            client .. ": failing comparison did not reach protected layout: " .. tostring(err))
    end
    return { env = env, F = F, AddBar = AddBar, Install = Install, Emit = Emit, Tick = Tick,
        Lock = function(value) locked = value end, AssertDetached = AssertDetached, AssertProtectedRoute = AssertProtectedRoute,
        Counts = function() return layouts, stockGrid, removals, #queue end,
        calls = calls, fluxGrid = fluxGrid, alphaOrder = alphaOrder, listener = listener, override = override }
end

for _, client in ipairs({ "forever", "live", "classic_anniversary", "classic_era", "mop" }) do
    -- The unmodified native dispatch must reach the reported resize for both
    -- ordinary and pet grid events before the Flux module is installed.
    for _, pet in ipairs({ false, true }) do
        local before = Boot(client)
        before.AddBar(pet and "PetActionBar" or "MainActionBar", GRID[pet and 3 or 1], GRID[pet and 4 or 2])
        before.Emit(GRID[pet and 3 or 1]); assert(select(1, before.Counts()) == 1)
        before.Lock(true)
        before.AssertProtectedRoute(GRID[pet and 3 or 1])
        before.AssertProtectedRoute(GRID[pet and 4 or 2])
    end

    local fixed = Boot(client)
    local bars = {}
    for _, names in ipairs({ MAIN, MULTI }) do
        for _, name in ipairs(names) do bars[#bars + 1] = fixed.AddBar(name, GRID[1], GRID[2]) end
    end
    bars[#bars + 1] = fixed.AddBar("PetActionBar", GRID[3], GRID[4])
    bars[#bars + 1] = fixed.AddBar("PetActionBarFrame", GRID[3], GRID[4])
    bars[3]._fluxUnusedSilenced = true -- existing one-time visibility flag must not bypass the fix
    local main = bars[1]
    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_SHAPESHIFT_FORM", "UPDATE_POSSESS_BAR", "UPDATE_VEHICLE_ACTIONBAR" }) do
        main:RegisterEvent(event)
    end
    local nativeGrid, nativeVisibility = fixed.env.ActionBarMixin.SetShowGrid, main.UpdateVisibility
    local blizzard = fixed.Install(); blizzard.Prepare(); fixed.Tick()
    for _, bar in ipairs(bars) do
        fixed.AssertDetached(bar)
        local order = assert(fixed.alphaOrder[bar], "bar was not neutralized")
        assert(not order.show and not order.hide, "grid suppression happened after neutralization: " .. bar.name)
    end
    assert(main.UpdateVisibility == nativeVisibility and fixed.env.ActionBarMixin.SetShowGrid == nativeGrid,
        "native grid/layout method was replaced")
    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_SHAPESHIFT_FORM", "UPDATE_POSSESS_BAR", "UPDATE_VEHICLE_ACTIONBAR" }) do
        assert(main.events[event], "unrelated native event removed: " .. event)
    end
    local removed = select(3, fixed.Counts())
    for _ = 1, 5 do blizzard.Prepare(); blizzard.Reassert(); blizzard.KillLeftoverMouse(); fixed.Tick() end
    assert(select(3, fixed.Counts()) == removed, "repeat initialization or aliases repeated grid removal")
    fixed.Lock(true)
    for _ = 1, 20 do for _, event in ipairs(GRID) do fixed.Emit(event) end end
    assert(select(1, fixed.Counts()) == 0 and select(2, fixed.Counts()) == 0,
        "suppressed stock event still entered grid/layout")
    for _, event in ipairs(GRID) do
        assert(fixed.fluxGrid[event] == 20 and fixed.listener.events[event], "independent Flux grid listener lost " .. event)
        assert(fixed.override.events[event], "vehicle/override grid subscription changed")
    end
    fixed.Lock(false)
    main:RegisterEvent(GRID[1]); blizzard.Reassert(); fixed.AssertDetached(main)
    assert(select(3, fixed.Counts()) == removed + 1, "native re-registration was not repaired")

    -- All clients must watch a later Blizzard_ActionBar load, even with no
    -- bar globals at startup. Unrelated addon loads must not schedule a pass.
    local late = Boot(client)
    local lateBlizzard = late.Install(); lateBlizzard.Prepare(); late.Tick()
    late.Emit("ADDON_LOADED", "UnrelatedAddon"); assert(select(4, late.Counts()) == 0)
    local lateMain = late.AddBar("MainActionBar", GRID[1], GRID[2])
    late.Emit("ADDON_LOADED", "Blizzard_ActionBar"); late.Tick(); late.AssertDetached(lateMain)
    local replacement = late.AddBar("MainActionBar", GRID[1], GRID[2])
    late.Emit("PLAYER_ENTERING_WORLD"); late.Tick(); late.AssertDetached(replacement)

    -- Repeated requests in lockdown coalesce through the actual Combat queue.
    local combat = Boot(client)
    local combatBar = combat.AddBar("MainActionBar", GRID[1], GRID[2])
    local combatBlizzard = combat.Install(); combat.Lock(true)
    combatBlizzard.Prepare(); combat.Tick()
    local pending = combat.F.Combat.PendingCount(); assert(pending > 0)
    for _ = 1, 20 do combatBlizzard.Prepare(); combatBlizzard.Reassert(); combat.Tick() end
    assert(combat.F.Combat.PendingCount() == pending and select(3, combat.Counts()) == 0,
        "combat initialization failed to coalesce or changed protected subscriptions")
    combat.Lock(false); combat.Emit("PLAYER_REGEN_ENABLED"); combat.Tick()
    combat.AssertDetached(combatBar)
    assert(select(3, combat.Counts()) == 2 and combat.F.Combat.PendingCount() == 0,
        "deferred grid pair was not removed exactly once after combat")

    local combatLate = Boot(client)
    local combatLateBlizzard = combatLate.Install(); combatLateBlizzard.Prepare(); combatLate.Tick()
    combatLate.Lock(true)
    local combatLateBar = combatLate.AddBar("MainActionBar", GRID[1], GRID[2])
    combatLate.Emit("ADDON_LOADED", "Blizzard_ActionBar"); combatLate.Tick()
    assert(combatLateBar.events[GRID[1]] and select(3, combatLate.Counts()) == 0)
    combatLate.Lock(false); combatLate.Emit("PLAYER_REGEN_ENABLED"); combatLate.Tick()
    combatLate.AssertDetached(combatLateBar)

    -- Capability skips, hide-only configuration, aliases and recognized-event
    -- filtering do not depend on Retail flags or fields written onto stock bars.
    local edges = Boot(client)
    local alias = edges.AddBar("MainActionBar", GRID[1], GRID[2])
    edges.env.MainMenuBar = alias
    local hideOnly = edges.AddBar("PetActionBar", nil, GRID[4])
    local unknown = edges.AddBar("ActionBarParent", "CUSTOM_GRID_SHOW", "CUSTOM_GRID_HIDE")
    local missing = edges.AddBar("MultiBar7", GRID[1], GRID[2]); missing.UnregisterEvent = false
    edges.env.MainMenuBarArtFrame = {}
    local edgesBlizzard = edges.Install(); edgesBlizzard.Prepare(); edges.Tick()
    edges.AssertDetached(alias); edges.AssertDetached(hideOnly, { GRID[4] })
    assert(select(3, edges.Counts()) == 3, "aliases, absent methods, or hide-only fields mishandled")
    assert(unknown.events.CUSTOM_GRID_SHOW and unknown.events.CUSTOM_GRID_HIDE and missing.events[GRID[1]])

    if client == "forever" then
        local pad = Boot(client, { gamepad = true })
        local padBar = pad.AddBar("MainActionBar", GRID[1], GRID[2])
        pad.Lock(true); pad.Emit(GRID[1]); assert(select(1, pad.Counts()) == 0, "native gamepad show-grid early return lost")
        pad.Lock(false); local padBlizzard = pad.Install(); padBlizzard.Prepare(); pad.Tick(); pad.AssertDetached(padBar)
        pad.Lock(true); for _, event in ipairs(GRID) do pad.Emit(event) end
        assert(select(1, pad.Counts()) == 0 and pad.fluxGrid[GRID[1]] == 2)
    end
    print(client .. ": native failure route, stock suppression, independent listeners, lifecycle and combat deferral passed")
end
print("stock grid smoke passed (4 native snapshots + MoP compatibility fixture; WoW taint/in-game input not modeled)")
