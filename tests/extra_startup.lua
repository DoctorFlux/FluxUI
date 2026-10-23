-- lua tests/extra_startup.lua (Lua 5.4); no WoW client is launched.
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
local noop = function() end
local function fixture(managed, branch)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.frames, env.timers, env.specs, env.marks = {}, {}, {}, {}
    env.combat = false
    env.InCombatLockdown = function() return env.combat end
    env.GetTime = function() return 0 end
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
    env.SlashCmdList = {}
    env.CreateFrame = function(_, name, parent, template)
        if template and template:find("Secure") then assert(not env.combat, "protected frame created in combat") end
        if name then assert(not env[name], "duplicate named frame: " .. name) end
        local frame = { events = {}, scripts = {}, shown = true, name = name, parent = parent }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(event, fn) self.scripts[event] = fn end
        function frame:IsShown() return self.shown end
        function frame:GetName() return self.name end
        function frame:GetEffectiveScale() return 1 end
        function frame:SetParent(parent) assert(not env.combat); self.parent = parent end
        function frame:SetPoint(...)
            assert(not env.combat, "anchor changed in combat")
            self.point = { ... }
        end
        function frame:ClearAllPoints() assert(not env.combat, "anchor cleared in combat") end
        function frame:Show() assert(not env.combat, "protected HUD shown in combat"); self.shown = true end
        function frame:Hide() assert(not env.combat, "protected HUD hidden in combat"); self.shown = false end
        function frame:SetAttribute() assert(not env.combat, "attribute changed in combat") end
        frame.SetSize, frame.SetScale, frame.SetClampedToScreen, frame.SetFrameStrata = noop, noop, noop, noop
        env.frames[#env.frames + 1] = frame
        if name then env[name] = frame end
        return frame
    end
    env.UIParent = env.CreateFrame("Frame")
    env.C_Timer = {
        After = function(_, fn) env.timers[#env.timers + 1] = fn end,
        NewTimer = function(_, fn)
            env.timers[#env.timers + 1] = fn
            return { Cancel = noop }
        end,
        NewTicker = function() return { Cancel = noop } end,
    }
    env.Flux = {
        securePhaseReady = false,
        Cap = { GamepadHudActive = function() return branch == "forever" end },
        Startup = {
            Mark = function(key) env.marks[key] = (env.marks[key] or 0) + 1 end,
            Count = function(key) env.marks[key] = (env.marks[key] or 0) + 1 end,
        },
    }
    if managed then
        env.Flux.Module = { Register = function(name, spec) env.specs[name] = spec end }
    end
    env.load = function(file)
        return assert(loadfile(file, "t", env))("_FluxUI", { Flux = env.Flux })
    end
    env.fire = function(event, ...)
        for _, frame in ipairs(env.frames) do
            if frame.events[event] then frame.scripts.OnEvent(frame, event, ...) end
        end
    end
    return env
end

local NC_GRID = "ExtraButtonSystem/NonCombatGrid/Grid.lua"
local NC_INIT = "ExtraButtonSystem/NonCombatGrid/GridInit.lua"
local C_GRID = "ExtraButtonSystem/CombatGrid/Grid.lua"
local C_INIT = "ExtraButtonSystem/CombatGrid/GridManager.lua"
local TM_CORE = "ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua"
local TM_INIT = "ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua"

local function setupGrid(env, combat)
    local creations = {}
    local names = combat and {
        "FluxCombatBandage", "FluxCombatHealPotion", "FluxCombatManaPotion",
        "FluxCombatManaGem", "FluxCombatHealthstone", "FluxCombatAmmo",
    } or { "FluxNCHearthstone", "FluxNCMount", "FluxNCTeleportPortal",
        "FluxNCWater", "FluxNCFood", "FluxNCConsumables", "FluxNCUtilitySlotsManager" }
    for _, name in ipairs(names) do
        local function create(grid)
            creations[name] = (creations[name] or 0) + 1
            grid:Relayout()
            grid:ScheduleRelayout()
        end
        env[name] = { Create = create, Register = create, OnNonCombatGridReady = create }
    end
    env.load(combat and C_GRID or NC_GRID)
    env.load(combat and C_INIT or NC_INIT)
    return creations, names
end

for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    for _, combatGrid in ipairs({ false, true }) do
        local env = fixture(true, branch)
        local creations, names = setupGrid(env, combatGrid)
        local key = combatGrid and "CombatGrid" or "NonCombatGrid"
        local readyKey = combatGrid and "combat_grid_infrastructure_ready" or "noncombat_grid_infrastructure_ready"
        local spec = env.specs[key]
        check(spec.phase == "secure" and spec.protected and spec.priority == (combatGrid and 46 or 45),
            branch .. ": secure grid priority")
        env.fire("PLAYER_ENTERING_WORLD")
        check(not next(creations), branch .. ": client barrier respected before phase release")
        env.Flux.securePhaseReady = true
        env.combat = true
        check(spec.OnEnable() == false, branch .. ": combat startup declines protected work")
        env.fire("PLAYER_ENTERING_WORLD")
        check(not next(creations), branch .. ": combat world entry creates no controls")
        env.combat = false
        env.fire("PLAYER_REGEN_ENABLED")
        local grid = combatGrid and env.FluxCombatManager.Grid or env.FluxNonCombatAPI.DefaultGrid
        check(grid and env.marks[readyKey] == 1, branch .. ": first combat exit initializes")
        for _, name in ipairs(names) do check(creations[name] == 1, branch .. ": retained " .. name) end
        check(env.marks.layout_passes == 1, branch .. ": one batched initial layout")
        local timers = #env.timers
        env.fire("PLAYER_REGEN_ENABLED")
        env.fire("PLAYER_ENTERING_WORLD")
        spec.OnEnable()
        check(env.marks.layout_passes == 1 and #env.timers == timers, branch .. ": repeated lifecycle has no startup timers/layout")
        env.combat = true
        if combatGrid then env.FluxCombatManager:FinalizeLayout() else env.FluxNonCombatAPI.UpdateAnchor() end
        check(grid._pendingRegenRelayout == true, branch .. ": combat structural refresh queued")
        env.combat = false
        env.fire("PLAYER_REGEN_ENABLED")
        env.fire("PLAYER_REGEN_ENABLED")
        check(env.marks.layout_passes == 2 and not grid._pendingRegenRelayout, branch .. ": queued relayout applied once")
    end
end

for _, combatGrid in ipairs({ false, true }) do
    local env = fixture(true, "live")
    local creations, names = setupGrid(env, combatGrid)
    env.Flux.securePhaseReady = true
    local key = combatGrid and "CombatGrid" or "NonCombatGrid"
    local broken = env[names[2]]
    local original = broken.Create
    broken.Create, broken.Register = function() error("fixture failure") end, function() error("fixture failure") end
    check(not pcall(env.specs[key].OnEnable), "failed grid startup reported")
    local owner = combatGrid and env.FluxCombatManager or env.FluxNonCombatAPI
    local grid = combatGrid and owner.Grid or owner.DefaultGrid
    check(not owner._startupReady and grid._layoutBatchDepth == 0, "failed startup unwinds layout transaction")
    broken.Create, broken.Register = original, original
    check(env.specs[key].OnEnable() == true, "grid startup retries")
    check(creations[names[1]] == 1 and creations[names[2]] == 1, "retry preserves completed registrations")
    check(grid._layoutBatchDepth == 0 and env.marks.layout_passes == 1, "retry flushes one complete transaction")
end

for _, combatGrid in ipairs({ false, true }) do
    local env = fixture(false, "live")
    local creations = setupGrid(env, combatGrid)
    env.combat = true
    env.fire("PLAYER_ENTERING_WORLD")
    check(not next(creations), "standalone smoke combat world entry safe")
    env.combat = false
    env.fire("PLAYER_REGEN_ENABLED")
    check(next(creations), "standalone smoke combat exit recovers startup")
end

do
    local env = fixture(true, "live")
    local scans, binds, cooldowns, creates = 0, 0, 0, 0
    env.FluxTrinketMenu = {
        CreateGrid = function()
            creates = creates + 1
            env.FluxTrinketMenu.Frame = env.CreateFrame("Frame", "TrinketFixture", nil, "SecureActionButtonTemplate")
        end,
        UpdateTrinketVisibility = function(skipBagScan)
            if env.combat then return end
            if not skipBagScan then scans = scans + 1 end
            binds = binds + 1
        end,
        UpdateAllCooldowns = function() cooldowns = cooldowns + 1 end,
        ProcessCombatQueue = noop,
    }
    env.load(TM_INIT)
    check(env.specs.TrinketMenu.phase == "secure" and env.specs.TrinketMenu.priority == 47,
        "trinkets registered in secure phase")
    env.combat = true
    env.Flux.securePhaseReady = true
    env.fire("PLAYER_LOGIN")
    env.fire("PLAYER_ENTERING_WORLD")
    env.fire("ACTIONBAR_UPDATE_COOLDOWN")
    check(creates == 0 and cooldowns == 1, "combat startup keeps display event path while secure creation waits")
    for _, frame in ipairs(env.frames) do check(frame.scripts.OnUpdate == nil, "no startup watcher in combat") end
    env.combat = false
    env.fire("PLAYER_REGEN_ENABLED")
    check(creates == 1 and binds == 1 and scans == 0, "secure trinkets and bindings ready before bag scan")
    check(#env.timers == 0 and env.marks.trinkets_ready == 1, "trinket startup has no arbitrary delay/retry timer")
    env.specs.TrinketInventory.OnEnable()
    check(scans == 1, "trinket inventory enhancement deferred")
    env.fire("PLAYER_REGEN_ENABLED")
    check(creates == 1, "trinkets not recreated after later combat")
end

do
    local env = fixture(true, "live")
    env.UnitClass = function() return "Warrior", "WARRIOR" end
    env.RAID_CLASS_COLORS = {}
    env.GetInventoryItemLink = function() return nil end
    env.GetInventoryItemTexture = function() return nil end
    env.GetInventorySlotInfo = function() return nil, "slot-icon" end
    env.ClearOverrideBindings = function() assert(not env.combat) end
    env.GetBindingKey = function() return nil end
    env.load(TM_CORE)
    local tm, scans, made = env.FluxTrinketMenu, 0, 0
    tm.ScanBagsForTrinkets = function() scans = scans + 1 end
    tm.SyncKeybindPushWatch, tm.ApplyHorizontalSqueeze, tm.UpdateArrowVisibility = noop, noop, noop
    env.FluxTrinketMenu_ApplyAppearanceAccent = noop
    local failSecond = true
    tm.CreateTrinketButton = function(index)
        if index == 1 and failSecond then error("fixture second trinket failure") end
        local widget = env.CreateFrame("Button", "Trinket" .. index, nil, "SecureActionButtonTemplate")
        tm.Buttons[index] = { Widget = widget, SlotFrame = widget }
        made = made + 1
    end
    check(not pcall(tm.CreateGrid, env.UIParent), "partial trinket creation failure reported")
    local originalFrame, originalButton = tm.Frame, tm.Buttons[0]
    failSecond = false
    tm.CreateGrid(env.UIParent)
    check(tm.Frame == originalFrame and tm.Buttons[0] == originalButton and made == 2,
        "partial trinket retry reuses frame and existing button")
    tm.UpdateTrinketVisibility(true)
    check(scans == 0, "real trinket visibility propagates skip-scan to binding updater")
    tm.UpdateKeybindings()
    check(scans == 1, "ordinary trinket binding update retains scan behavior")
end

for _, combatGrid in ipairs({ false, true }) do
    local env = fixture(true, "live")
    local widget
    env.Flux.EBS = { Widget = {
        Create = function(parent)
            widget = env.CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
            return { Widget = widget }
        end,
        BindLockedExtraHost = function() return false end,
    } }
    env.load(combatGrid and C_GRID or NC_GRID)
    local grid = (combatGrid and env.FluxCombatGrid or env.FluxNonCombatGrid).New(env.UIParent)
    check(not pcall(grid.CreateButton, grid, {}), "grid propagates secure click setup failure")
    check(#grid.Buttons == 0 and not widget.parent.shown, "failed click setup leaves no published grid button")
end

do
    local env = fixture(true, "live")
    env.Flux.EBS = {
        Widget = { Create = function(parent)
            return { Widget = env.CreateFrame("Button", nil, parent, "SecureActionButtonTemplate") }
        end },
        Action = { SetAction = noop },
    }
    env.Flux.ButtonFX = { Click = { Apply = function() return false end } }
    env.load(TM_CORE)
    local tm = env.FluxTrinketMenu
    check(not pcall(tm.CreateGrid, env.UIParent), "trinket propagates secure click setup failure")
    check(tm.Buttons[0] == nil, "trinket input readiness not published after failed secure setup")
end

print(("PASS: %d extra-startup checks (five labelled client fixtures; real clients still require testing)"):format(checks))
