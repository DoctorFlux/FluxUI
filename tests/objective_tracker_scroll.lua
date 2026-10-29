-- Replays Blizzard's saved Frame.Update callback, which bypasses instance hooks.
-- Geometry/dispatch checks only; does not emulate the native secure VM or pixels.
local unpack = table.unpack or unpack
local function read(path)
    local file = assert(io.open(path, "r")); local source = file:read("*a"); file:close(); return source
end
local source = read(arg[1] or "Minimap/FluxObjectiveTrackerScroll.lua")
local function compile(text, env)
    if setfenv then local fn = assert(loadstring(text)); setfenv(fn, env); return fn end
    return assert(load(text, "tracker scroll fixture", "t", env))
end
local checks, failures = 0, 0
local function check(value, message)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. message) end
end

local function boot(forever)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local queue, locked, anchorWrites = {}, false, 0
    local function frame(parent)
        local f = { parent = parent, width = 260, height = 400, scale = 1,
            shown = true, points = {}, scripts = {}, level = 0 }
        function f:GetParent() return self.parent end
        function f:SetParent(p) self.parent = p end
        function f:GetWidth() return self.width end
        function f:SetWidth(v) self.width = v end
        function f:GetHeight()
            local top, bottom = self.points.TOPRIGHT, self.points.BOTTOMLEFT
            if top and bottom and top[2] == bottom[2] then return top[2]:GetHeight() + top[5] - bottom[5] end
            return self.height
        end
        function f:SetHeight(v) self.height = v end
        function f:GetScale() return self.scale end
        function f:SetScale(v) self.scale = v end
        function f:SetPoint(point, rel, relPoint, x, y)
            -- Normalize Blizzard's SetPoint("TOP", 0, -padding) overload.
            if type(rel) == "number" then x, y, rel, relPoint = rel, relPoint, self.parent, point end
            self.points[point] = { point, rel, relPoint, x or 0, y or 0 }
            anchorWrites = anchorWrites + 1
        end
        function f:ClearAllPoints() self.points = {} end
        function f:GetPoint() return unpack(self.points.TOP or self.points.TOPRIGHT or {}) end
        function f:GetNumPoints() local n = 0; for _ in pairs(self.points) do n = n + 1 end; return n end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:SetShown(v) self.shown = v end
        function f:IsShown() return self.shown end
        function f:GetFrameLevel() return self.level end
        function f:SetFrameLevel(v) self.level = v end
        function f:GetFrameStrata() return "LOW" end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:HookScript(event, fn) self.scripts[event] = fn end
        function f:SetScrollChild(child) self.child = child end
        function f:GetScrollChild() return self.child end
        function f:GetVerticalScrollRange() return math.max(0, self.child:GetHeight() - self:GetHeight()) end
        function f:GetVerticalScroll() return self.offset or 0 end
        function f:SetVerticalScroll(v) self.offset = math.min(self:GetVerticalScrollRange(), math.max(0, v)) end
        function f:UpdateScrollChildRect()
            self.offset = self.rectOffset or math.min(self.offset or 0, self:GetVerticalScrollRange())
        end
        for _, key in ipairs({ "RegisterEvent", "UnregisterEvent", "SetFrameStrata", "SetClipsChildren",
            "EnableMouse", "EnableMouseWheel" }) do f[key] = function() end end
        return f
    end
    env.CreateFrame = function(_, name, parent, template)
        local f = frame(parent)
        if template == "ScrollFrameTemplate" then f.ScrollBar = frame(f) end
        if name then env[name] = f end
        return f
    end
    env.CreateFromMixins = function(...)
        local result = {}; for i = 1, select("#", ...) do for k, v in pairs(select(i, ...)) do result[k] = v end end
        return result
    end
    env.DirtiableMixin = { SetDirtyMethod = function(self, fn) self.dirtyCallback = fn end }
    env.GenerateClosure = function(fn, self, value) return function() return fn(self, value) end end
    env.hooksecurefunc = function(object, key, hook)
        local original = assert(object[key], key)
        object[key] = function(...) local values = { original(...) }; hook(...); return unpack(values) end
    end
    env.C_Timer = { After = function(_, fn) queue[#queue + 1] = fn end }
    env.InCombatLockdown = function() return locked end
    env.InputUtil = { IsGamepadUIEnabled = function() return false end }
    env.FLUX_API = { isCamelot = forever, isForever = forever, hasBlizzardObjectiveTrackerScroll = true }
    env.EventRegistry = { RegisterCallback = function() end }
    env.EditModeManagerFrame = { IsEditModeActive = function() return false end }
    env.C_GameRules = { IsGameRuleActive = function() return false end }
    env.Enum = { GameRule = { ObjectiveTrackerDisabled = 1 } }
    env.UIParent = frame()
    local native = "../__AddonsForRef/wow-ui-source-" .. (forever and "forever" or "live") .. "/Interface/AddOns/Blizzard_ObjectiveTracker/"
    compile(read(native .. "Blizzard_ObjectiveTrackerContainer.lua"), env)()
    compile(read(native .. "Blizzard_ObjectiveTracker.lua"), env)()
    local tracker = frame(env.UIParent)
    for k, v in pairs(env.ObjectiveTrackerContainerMixin) do tracker[k] = v end
    for k, v in pairs(env.ObjectiveTrackerFrameMixin) do tracker[k] = v end
    tracker.topModulePadding, tracker.bottomModulePadding, tracker.moduleSpacing = 38, 10, 10
    tracker.Header = frame(tracker); tracker.Header:SetHeight(32)
    tracker.NineSlice = frame(tracker)
    tracker.IsInDefaultPosition = function() return false end
    tracker.init = true
    env.ObjectiveTrackerContainerMixin.OnLoad(tracker)
    local captured = tracker.dirtyCallback -- before Flux installs hooks
    local function module(height)
        local m = frame(tracker); m.leftMargin, m.used = 0, height
        function m:Update() return self.used, false end
        function m:GetContentsHeight() return self.used end
        function m:IsTruncated() return false end
        return m
    end
    local empty, campaign, quests = module(0), module(120), module(500)
    tracker.modules = { empty, campaign, quests }
    env.ObjectiveTrackerFrame = tracker
    compile(source, env)("_FluxUI", { _isCamelotGameType = forever })
    local scroll = env.FluxObjectiveTrackerScroll
    local viewport = assert(scroll:EnsureViewport(tracker)); viewport:SetHeight(240)
    scroll:LayoutScrollArea(tracker)
    local function tick()
        local pending = queue; queue = {}; for _, fn in ipairs(pending) do fn() end
    end
    tick()
    return { env = env, tracker = tracker, campaign = campaign, quests = quests, captured = captured,
        scroll = scroll, body = tracker.fluxScrollBody, child = tracker:GetParent(), tick = tick,
        lock = function(v) locked = v end, writes = function() return anchorWrites end }
end

for _, forever in ipairs({ false, true }) do
    local label = forever and "Forever: " or "Retail: "
    local r = boot(forever)
    local function top(m) return select(5, m:GetPoint(1)) end
    r.captured(); r.tick()
    check(top(r.campaign) == 0, label .. "saved native callback leaves Campaign at body top")
    check(r.tracker.topModulePadding == 38, label .. "native padding stays untouched")
    check(r.body:GetVerticalScroll() == 0, label .. "first layout starts at top")
    for _, f in ipairs({ r.body, r.tracker, r.tracker.Header, r.env.FluxObjectiveTrackerViewport }) do
        check(type(f.scripts.OnMouseWheel) == "function", label .. "wheel handler covers body, rows and fixed header")
    end
    local wheel = r.body.scripts.OnMouseWheel
    wheel(r.body, -3)
    local offset = r.body:GetVerticalScroll()
    check(offset == 90, label .. "wheel scrolls rows")
    r.captured(); r.tick()
    check(top(r.campaign) == 0 and r.body:GetVerticalScroll() == offset, label .. "native update preserves top anchor and current scroll")
    wheel(r.body, 100)
    check(r.body:GetVerticalScroll() == 0 and top(r.campaign) == 0, label .. "fully scrolled up reaches Campaign")
    r.tracker:Update(true); r.tick()
    check(top(r.campaign) == 0, label .. "instance update also keeps Campaign at top")
    r.campaign.used, r.quests.used = 0, 630 -- same total height, different first visible module
    r.captured(); r.tick()
    check(top(r.quests) == 0, label .. "same-height section replacement promotes Quests to top")
    -- Simulate an anchor reset before the coalesced sync, including its cached-height path.
    r.quests:SetPoint("TOP", r.tracker, "TOP", 0, -38)
    r.scroll:SyncAfterUpdate(r.tracker); r.tick()
    check(top(r.quests) == 0, label .. "deferred unchanged-height sync repairs overwritten top anchor")
    local writes = r.writes()
    r.scroll:SyncAfterUpdate(r.tracker); r.tick()
    check(r.writes() == writes, label .. "settled sync avoids redundant anchor writes")
    r.campaign.used, r.quests.used = 120, 500
    r.captured(); r.tick()
    check(top(r.campaign) == 0, label .. "Campaign returns to top when tracked again")
    wheel(r.body, -2)
    local expected = r.body:GetVerticalScroll()
    r.scroll:SizeScrollContent(r.tracker, r.child:GetHeight() + 20)
    check(r.body:GetVerticalScroll() == expected, label .. "content resizing preserves a valid nonzero offset")
    local before = r.campaign:GetPoint(1)
    r.env.ObjectiveTrackerContainerMixin.Update(r.tracker, true); r.tick()
    check(top(r.campaign) == 0 and before == "TOP", label .. "direct container update keeps top anchor")
    wheel(r.body, -1000)
    r.campaign.used, r.quests.used = 0, 50
    r.captured(); r.tick()
    check(r.body:GetVerticalScroll() == 0, label .. "shortened list clamps to zero")
    -- The frame API may change the offset while refreshing its child rectangle.
    r.body.rectOffset = 7
    r.scroll:SizeScrollContent(r.tracker, 700, true)
    check(r.body:GetVerticalScroll() == 0, label .. "one-shot resize restores requested zero offset")
    r.body.rectOffset = nil
    r.env.Questie, r.env.QuestieLoader = { db = { profile = { trackerEnabled = true } } }, {}
    r.quests:SetPoint("TOP", r.tracker, "TOP", 0, -38)
    r.scroll:SyncAfterUpdate(r.tracker); r.tick()
    check(top(r.quests) == -38, label .. "Questie ownership skips native dock correction")
end
print(string.format("Objective tracker scroll: %d checks, %d failures", checks, failures))
assert(failures == 0, "objective tracker scroll regression")
