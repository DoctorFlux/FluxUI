-- Replay Blizzard's controller -> stance -> Edit Mode -> right Layout chain.
-- Field ownership and lockdown are modeled; this is not WoW's taint engine.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local function compile(s, env) return assert(load(s, "possession layout fixture", "t", env)) end
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end

local function boot(client, oldPolicy)
    local base = "../__AddonsForRef/wow-ui-source-" .. client .. "/Interface/AddOns/"
    local env = setmetatable({}, { __index = _G }); env._G = env
    local locked, dirtyLayout, layouts, edit, kind = false, false, 0, false, "normal"
    local frames, queue, callbacks = {}, {}, {}
    local function noop() end
    env.InCombatLockdown = function() return locked end
    env.C_Timer = { After = function(_, fn) queue[#queue + 1] = fn end }
    env.EventRegistry = { RegisterCallback = function(_, event, fn)
        callbacks[event] = callbacks[event] or {}; table.insert(callbacks[event], fn)
    end }
    env.CreateFromMixins = function(...)
        local t = {}; for i = 1, select("#", ...) do for k, v in pairs(select(i, ...)) do t[k] = v end end; return t
    end
    env.RoundToNearestMultiple = function(n, m) return math.floor(n / m + 0.5) * m end
    env.Clamp = function(n, lo, hi) return math.max(lo, math.min(n, hi)) end
    compile(read(base .. "Blizzard_SharedXML/LayoutFrame.lua"), env)()
    local methods = env.CreateFromMixins(env.LayoutMixin, env.VerticalLayoutMixin)
    local function frame(name, parent, layout)
        local private = {}
        local f = { name = name, parent = parent, width = 100, height = 40, shown = false, events = {}, scripts = {} }
        setmetatable(f, {
            __index = function(_, key)
                if key == "ignoreInLayout" then
                    if private.written then dirtyLayout = true end
                    return private.ignoreInLayout
                end
                return layout and methods[key] or nil
            end,
            __newindex = function(t, key, value)
                if key == "ignoreInLayout" then private.written, private.ignoreInLayout = true, value
                else rawset(t, key, value) end
            end,
        })
        function f:GetChildren()
            local children = {}; for _, child in ipairs(frames) do if child.parent == self then children[#children + 1] = child end end
            return table.unpack(children)
        end
        function f:GetRegions() end
        function f:GetParent() return self.parent end
        function f:SetParent(p) assert(not locked, "insecure combat reparent"); self.parent = p end
        function f:IsShown() return self.shown end
        function f:GetScale() return 1 end
        function f:GetEffectiveScale() return 1 end
        function f:GetSize() return self.width, self.height end
        function f:GetWidth() return self.width end
        function f:GetHeight() return self.height end
        function f:GetRight() return self.right or 1800 end
        function f:GetTop() return self.top or 1080 end
        function f:GetBottom() return self.bottom or 950 end
        function f:GetLeft() return self.left or 1600 end
        function f:ClearAllPoints() self.point = nil end
        function f:SetPoint(...) self.point = { ... } end
        function f:SetSize(w, h)
            if self == env.RightManagedFrameContainer then
                assert(not (locked and dirtyLayout), "RightManagedFrameContainer:SetSize() [modeled tainted layout field]")
                layouts = layouts + 1
            end
            self.width, self.height = w, h
        end
        function f:SetScript(key, fn) self.scripts[key] = fn end
        function f:RegisterEvent(event) self.events[event] = true end
        frames[#frames + 1] = f; return f
    end
    env.CreateFrame = function(_, name, parent) return frame(name, parent) end
    env.UIParent = frame("UIParent"); env.UIParent.width, env.UIParent.height, env.UIParent.right = 1920, 1080, 1920
    env.MinimapCluster = frame("MinimapCluster")
    local right = frame("RightManagedFrameContainer", env.UIParent, true)
    right.shown, right.BottomManagedLayoutContainer = true, { Layout = noop }
    env.RightManagedFrameContainer = right
    env.GetRightManagedFrameContainer = function() return right end
    local boss = frame("BossTargetFrameContainer", right); boss.layoutIndex = 4
    local arena = frame("CompactArenaFrame", right); arena.layoutIndex = 12
    env.BossTargetFrameContainer, env.CompactArenaFrame = boss, arena
    env.FluxBuffDebuffFrames = { _engineDebuffHost = frame("FluxDebuffs") }
    env.ObjectiveTrackerFrame = frame("ObjectiveTrackerFrame", env.UIParent)
    local function method(path, name)
        local s = read(base .. path); local a = assert(s:find("function " .. name .. "(", 1, true), name)
        local b = assert(s:find("\nend", a, true), name)
        compile(s:sub(a, b + 3), env)()
    end
    env.FramePositionDelegate = {}
    method("Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua", "FramePositionDelegate:ManageRightFrameContainer")
    function env.FramePositionDelegate:SetAttribute() self:ManageRightFrameContainer() end
    method("Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua", "ManageFramePositions")
    env.EditModeUtil = {
        IsBottomAnchoredActionBar = function(_, f) return f == env.StanceBar end,
        GetBottomActionBars = function() return {} end,
        GetRightContainerAnchor = function() return { SetPoint = noop } end,
    }
    env.EditModeManagerFrameMixin = {}
    for _, name in ipairs({ "UpdateActionBarLayout", "UpdateBottomActionBarPositions" }) do
        method("Blizzard_EditMode/Shared/EditModeManager.lua", "EditModeManagerFrameMixin:" .. name)
    end
    env.EditModeManagerFrame = setmetatable({ IsInitialized = function() return true end,
        IsEditModeActive = function() return edit end, GetBottomActionBars = function() return {} end },
        { __index = env.EditModeManagerFrameMixin })
    env.EditModeActionBarMixin = {}
    for _, name in ipairs({ "SetShownOverride", "ShowOverride", "HideOverride", "UpdateVisibility" }) do
        method("Blizzard_ActionBar/Shared/ActionBar.lua", "EditModeActionBarMixin:" .. name)
    end
    env.StanceBarMixin = {}
    method("Blizzard_ActionBar/Shared/StanceBar.lua", "StanceBarMixin:Update")
    method("Blizzard_ActionBar/Shared/StanceBar.lua", "StanceBarMixin:ShouldShow")
    env.GetNumShapeshiftForms = function() return 0 end
    env.ActionBarBusy = function() return false end
    env.ActionBarController_GetCurrentActionBarState = function() return kind == "override" and 2 or 1 end
    env.LE_ACTIONBAR_STATE_MAIN, env.LE_ACTIONBAR_STATE_OVERRIDE = 1, 2
    env.C_ActionBar = {
        IsPossessBarVisible = function() return kind == "possess" end,
        HasVehicleActionBar = function() return kind == "vehicle" end,
        HasOverrideActionBar = function() return kind == "override" end,
        HasBonusActionBar = function() return kind == "possess" end,
        HasTempShapeshiftActionBar = function() return false end,
        GetVehicleBarIndex = function() return 12 end, GetOverrideBarIndex = function() return 14 end,
        GetBonusBarIndex = function() return 11 end, GetActionBarPage = function() return 1 end,
        GetOverrideBarSkin = function() return 0 end,
    }
    env.UnitVehicleSkin = function() return "" end
    env.C_PetBattles = { IsInBattle = function() return false end }
    env.InputUtil = { IsMKBUIEnabled = function() return true end, IsGamepadUIEnabled = function() return false end }
    env.PossessActionBar = { Update = noop }
    env.StanceBar = env.CreateFromMixins(env.StanceBarMixin, env.EditModeActionBarMixin)
    env.StanceBar.SetShown = env.EditModeActionBarMixin.SetShownOverride
    env.StanceBar.SetShownBase = noop
    env.StanceBar.ShouldBreakSnappedFramesOnHide = function() return false end
    env.MainActionBar = { SetAttribute = function(_, key, value) env.nativePage = value end }
    env.ActionBarButtonEventsFrame = { frames = {} }
    env.ValidateActionBarTransition = noop
    method("Blizzard_ActionBarController/ActionBarController.lua", "ActionBarController_ResetToDefault")
    method("Blizzard_ActionBarController/ActionBarController.lua", "ActionBarController_UpdateAll")
    for _, path in ipairs({ "Other/FluxBossFramePosition.lua", "Other/FluxArenaFramePosition.lua" }) do
        local s = read(path)
        if oldPolicy then
            -- Exact former policy: set the addon layout flag and retain parent.
            local target = path:find("Boss", 1, true) and "boss" or "arena"
            local a = assert(s:find("        -- " .. (target == "boss" and "LayoutFrame" or "Keep Flux"), 1, true))
            local b = assert(s:find("\n        end", a, true))
            s = s:sub(1, a - 1) .. "        " .. target .. ".ignoreInLayout = true" .. s:sub(b + #"\n        end")
        end
        compile(s, env)("_FluxUI", {})
    end
    local function tick()
        local list = queue; queue = {}; for _, fn in ipairs(list) do fn() end
    end
    local function emit(event)
        for _, f in ipairs(frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event) end end
    end
    return { env = env, boss = boss, arena = arena, right = right, Tick = tick, Emit = emit,
        Lock = function(v) locked = v end, Edit = function(v) edit = v end,
        Transition = function(v) kind, dirtyLayout = v, false; env.ActionBarController_UpdateAll() end,
        Callback = function(event) for _, fn in ipairs(assert(callbacks[event])) do fn() end; tick() end,
        Layouts = function() return layouts end }
end

for _, client in ipairs({ "live", "forever" }) do
    local before = boot(client, true)
    before.Emit("PLAYER_LOGIN"); before.Tick(); before.Lock(true)
    local ok, err = pcall(before.Transition, "possess")
    check(not ok and tostring(err):find("RightManagedFrameContainer:SetSize()", 1, true),
        client .. ": original hidden-child policy must reproduce the reported resize: " .. tostring(err))
    local f = boot(client)
    f.Emit("PLAYER_LOGIN"); f.Tick()
    for _, frame in ipairs({ f.boss, f.arena }) do
        check(frame:GetParent() == f.env.UIParent and frame.point[2] == f.env.UIParent,
            client .. ": custom boss/arena geometry leaves Blizzard layout children")
    end
    f.Lock(true)
    for _ = 1, 10 do
        for _, state in ipairs({ "possess", "override", "vehicle", "normal" }) do
            f.Transition(state)
            check(f.env.nativePage == ({ possess = 11, override = 14, vehicle = 12, normal = 1 })[state],
                client .. ": native control paging completes after protected right layout")
        end
    end
    check(f.Layouts() == 40, client .. ": protected native layout still executes during combat")
    f.boss:SetPoint("TOPRIGHT", f.env.UIParent, "TOPRIGHT", -40, -30)
    f.Emit("INSTANCE_ENCOUNTER_ENGAGE_UNIT"); f.Tick()
    check(f.boss.point[4] == -40, client .. ": combat positioning waits for regen")
    f.Lock(false); f.Emit("PLAYER_REGEN_ENABLED"); f.Tick()
    check(f.boss.point[4] ~= -40, client .. ": deferred boss placement recovers")
    for _, event in ipairs({ "EditMode.Exit", "UI.TopLevelParentShown" }) do
        f.boss:SetParent(f.right); f.arena:SetParent(f.right)
        f.Callback(event)
        check(f.boss:GetParent() == f.env.UIParent and f.arena:GetParent() == f.env.UIParent,
            client .. ": native UI restoration is followed by deferred detachment")
    end
    f.Edit(true); f.boss:SetParent(f.right); f.Emit("PLAYER_ENTERING_WORLD"); f.Tick()
    check(f.boss:GetParent() == f.right, client .. ": Edit Mode retains its native positioning pass")
    f.Edit(false); f.Callback("EditMode.Exit")
    check(f.boss:GetParent() == f.env.UIParent, client .. ": Edit Mode exit restores Flux positioning")
end
print("possession layout: " .. checks .. " checks passed; Retail/Forever native controller, stance, Edit Mode and LayoutFrame; original policy rejected")
