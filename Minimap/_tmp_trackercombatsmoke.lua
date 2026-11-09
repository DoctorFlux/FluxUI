-- lua Minimap/_tmp_trackercombatsmoke.lua
-- Replays the native dirty callback / Frame.Update / Container.Update chain
-- from the supplied Forever UI source, including a callback captured BEFORE
-- Flux installs its hooks. This checks dispatch, not WoW's taint engine.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local unpack = table.unpack or unpack
local function Read(path)
    local f = assert(io.open(root .. path, "r")); local s = f:read("*a"); f:close(); return s
end
local function Compile(s, env)
    if setfenv then local f = assert(loadstring(s)); setfenv(f, env); return f end
    return assert(load(s, "tracker combat fixture", "t", env))
end
local native = "../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/"
local mixinSource = Read(native .. "Blizzard_SharedXML/MixinUtil.lua")
local dirtyStart = assert(mixinSource:find("DirtiableMixin = {};", 1, true))
local dirtyEnd = assert(mixinSource:find("DirtyPhaseMixin = {};", dirtyStart, true))

local function Boot(withGuard, gamepad, questie)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local locked, queue, frames, layouts, renders = false, {}, {}, 0, 0
    env.InCombatLockdown = function() return locked end
    env.InputUtil = { IsGamepadUIEnabled = function() return gamepad end }
    env.FLUX_API = { isForever = true, isCamelot = true }
    if questie then
        env.Questie, env.QuestieLoader = { db = { profile = { trackerEnabled = true } } }, {}
    end
    env.C_Timer = { After = function(_, f) queue[#queue + 1] = f end }
    env.RunNextFrame = function(f) queue[#queue + 1] = f end
    env.CreateFromMixins = function(...)
        local result = {}; for i = 1, select("#", ...) do for k, v in pairs(select(i, ...)) do result[k] = v end end
        return result
    end
    env.GenerateClosure = function(method, self, arg)
        return function() return method(self, arg) end
    end
    env.hooksecurefunc = function(object, name, hook)
        local original = assert(object[name], name)
        object[name] = function(...)
            local result = { original(...) }; hook(...); return unpack(result)
        end
    end
    env.CreateFrame = function()
        local f = { events = {}, scripts = {} }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        frames[#frames + 1] = f; return f
    end
    env.EditModeManagerFrame = { IsEditModeActive = function() return false end }
    env.ManagedFrameMixin = { OnShow = function() end }
    env.EventRegistry = { RegisterCallback = function() end }
    env.C_GameRules = { IsGameRuleActive = function() return false end }
    env.Enum = { GameRule = { ObjectiveTrackerDisabled = 1 } }
    env.ManageFramePositions = function()
        assert(not locked, "RightManagedFrameContainer:SetSize() from captured native dirty callback")
        layouts = layouts + 1
    end
    Compile(mixinSource:sub(dirtyStart, dirtyEnd - 1), env)()
    Compile(Read(native .. "Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerContainer.lua"), env)()
    Compile(Read(native .. "Blizzard_ObjectiveTracker/Blizzard_ObjectiveTracker.lua"), env)()
    local tracker = env.CreateFromMixins(env.ObjectiveTrackerContainerMixin, env.ObjectiveTrackerFrameMixin)
    tracker.Header = { Show = function() end, Hide = function() end, SetPoint = function() end,
        GetParent = function() return tracker end }
    tracker.NineSlice = { SetPoint = function() end, Show = function() end }
    tracker.GetHeight = function() return 400 end
    tracker.IsInDefaultPosition = function() return true end
    tracker.Show, tracker.Hide = function() end, function() end
    tracker.UpdateHeight = function() end
    tracker.topModulePadding, tracker.bottomModulePadding, tracker.moduleSpacing = 0, 10, 10
    tracker.modules = { {
        leftMargin = 0,
        Update = function() renders = renders + 1 end,
        GetContentsHeight = function() return 20 end,
        IsTruncated = function() return false end,
        ClearAllPoints = function() end, SetPoint = function() end,
    } }
    env.ObjectiveTrackerContainerMixin.OnLoad(tracker)
    -- This is the exact kind of closure shown at MixinUtil.lua:341. It has
    -- already captured the original Frame.Update, not Flux's later hook.
    local captured = tracker.dirtyCallback
    env.ObjectiveTrackerFrame = tracker
    local source = Read("Minimap/FluxObjectiveTrackerScroll.lua")
    if not withGuard then
        local n; source, n = source:gsub("    installContainerCombatGuard%(%)\n", "")
        assert(n == 2, "could not disable both guard entry points in the failing comparison")
    end
    Compile(source, env)("_FluxUI", { _isCamelotGameType = true })
    local function Tick()
        local callbacks = queue; queue = {}; for _, f in ipairs(callbacks) do f() end
    end
    local function Emit(event)
        for _, frame in ipairs(frames) do
            if frame.events[event] then frame.scripts.OnEvent(frame, event) end
        end
    end
    return { tracker = tracker, captured = captured, env = env, Tick = Tick, Emit = Emit,
        Lock = function(v) locked = v end,
        Counts = function() return layouts, renders, #queue end }
end

local before = Boot(false, false)
before.Lock(true)
local ok, err = pcall(before.captured)
assert(not ok and tostring(err):find("RightManagedFrameContainer:SetSize()", 1, true), "failing comparison did not reproduce the resize")

local fixed = Boot(true, false)
fixed.Lock(true)
for _ = 1, 20 do fixed.captured() end
assert(select(1, fixed.Counts()) == 0 and select(2, fixed.Counts()) == 0,
    "captured callback still entered layout during combat")
fixed.tracker:MarkDirty(); fixed.Tick()
assert(select(1, fixed.Counts()) == 0, "new dirty callback entered combat layout")
-- Native/manager calls bypass dirtyCallback too; they must share the guard.
fixed.tracker:Update(true); fixed.Tick()
assert(select(1, fixed.Counts()) == 0, "direct update entered combat layout")
-- Fire regen while still locked; release the flag before the deferred tick.
fixed.Emit("PLAYER_REGEN_ENABLED")
assert(select(1, fixed.Counts()) == 0)
fixed.Lock(false); fixed.Tick()
assert(select(1, fixed.Counts()) == 1 and select(2, fixed.Counts()) == 1,
    "pending dirty updates did not coalesce to one native layout after combat")
assert(fixed.tracker.dirty == nil, "native dirty callback did not clear dirty")
fixed.tracker:MarkDirty(); fixed.Tick()
assert(select(1, fixed.Counts()) == 2, "ordinary updates stopped after combat")

-- An explicit SetDirtyMethod later must still install the safe dirty wrapper.
local changed = 0
fixed.tracker:SetDirtyMethod(function() changed = changed + 1 end)
fixed.Lock(true); fixed.tracker:MarkDirty(); fixed.Tick()
assert(changed == 0)
fixed.Emit("PLAYER_REGEN_ENABLED"); fixed.Lock(false); fixed.Tick()
assert(changed == 1)

-- Questie owns the visible tracker, but Blizzard can still invoke the saved
-- callback. It must receive the guard even though scroll installation skips.
local hidden = Boot(true, false, true)
hidden.Lock(true); hidden.captured(); hidden.tracker:MarkDirty(); hidden.Tick()
assert(select(1, hidden.Counts()) == 0 and select(2, hidden.Counts()) == 0)
hidden.Emit("PLAYER_REGEN_ENABLED"); hidden.Lock(false); hidden.Tick()
assert(select(1, hidden.Counts()) == 1)

-- Gamepad's protected navigation follows Container.Update; leave that entry
-- native instead of returning into it from an addon pre-guard.
local pad = Boot(true, true)
local container = pad.env.ObjectiveTrackerContainerMixin.Update
pad.Lock(true)
local padOK, padErr = pcall(container, pad.tracker, true)
assert(not padOK and tostring(padErr):find("RightManagedFrameContainer:SetSize()", 1, true),
    "gamepad container unexpectedly entered the addon pre-guard")
print("tracker combat smoke passed: original closure bypass reproduced; captured/direct/dirty updates defer, regen coalesces, callbacks recover, gamepad entry stays native")
