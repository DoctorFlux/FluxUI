-- lua Minimap/_tmp_questiesmoke.lua
-- Runs the actual integration and Blizzard viewport with strict frame mocks.
-- Verifies ownership, async frames, Classic/Forever parity and combat deferral;
-- WoW's protected execution/taint still requires an in-client check.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local unpack = table.unpack or unpack

local function NewRuntime(forever)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.unpack = unpack
    local ns = { _isCamelotGameType = forever }
    local timers, frames, now, combat, embedded = {}, {}, 0, false, false
    local mutations, sorts, imports = 0, 0, 0
    local function Write() assert(not combat, "frame changed in combat"); mutations = mutations + 1 end
    local function Frame(parent)
        local f = { parent = parent, width = 260, height = 400, scale = 1,
            shown = true, scripts = {}, events = {}, points = {}, level = 0 }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:GetScript(event) return self.scripts[event] end
        function f:HasScript(event) return self.scripts[event] ~= nil end
        function f:HookScript(event, fn)
            local old = self.scripts[event]
            self.scripts[event] = function(...) if old then old(...) end; fn(...) end
        end
        function f:Show()
            Write()
            local old = self.shown; self.shown = true
            if not old and self.scripts.OnShow then self.scripts.OnShow(self) end
        end
        function f:Hide()
            Write()
            local old = self.shown; self.shown = false
            if old and self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        function f:SetShown(shown) if shown then self:Show() else self:Hide() end end
        function f:IsShown() return self.shown end
        function f:IsProtected() return false end
        function f:SetParent(p) Write(); self.parent = p end
        function f:GetParent() return self.parent end
        function f:SetWidth(w) Write(); self.width = w end
        function f:SetHeight(h) Write(); self.height = h end
        function f:SetSize(w, h) self:SetWidth(w); self:SetHeight(h) end
        function f:GetWidth() return self.allPoints and self.allPoints:GetWidth() or self.width end
        function f:GetHeight() return self.allPoints and self.allPoints:GetHeight() or self.height end
        function f:GetTop() return self.top or self:GetHeight() end
        function f:GetBottom() return self.bottom or 0 end
        function f:SetScale(s) Write(); self.scale = s end
        function f:GetScale() return self.scale end
        function f:SetPoint(...) Write(); self.points[#self.points + 1] = { ... } end
        function f:ClearAllPoints() Write(); self.points = {} end
        function f:GetPoint(i) return unpack(self.points[i or 1] or {}) end
        function f:GetNumPoints() return #self.points end
        function f:SetAllPoints(other) Write(); self.allPoints = other end
        function f:SetScrollChild(child) Write(); self.child = child end
        function f:GetScrollChild() return self.child end
        function f:SetVerticalScroll(v) Write(); self.offset = v end
        function f:GetVerticalScroll() return self.offset or 0 end
        function f:GetVerticalScrollRange() return math.max(0, (self.child and self.child:GetHeight() or 0) - self:GetHeight()) end
        function f:UpdateScrollChildRect() Write() end
        function f:GetFrameLevel() return self.level end
        function f:SetFrameLevel(level) Write(); self.level = level end
        function f:GetFrameStrata() return "LOW" end
        for _, method in ipairs({ "SetClampedToScreen", "SetClipsChildren", "EnableMouse", "EnableMouseWheel",
            "SetMovable", "SetUserPlaced", "SetFrameStrata", "RegisterForClicks" }) do f[method] = Write end
        frames[#frames + 1] = f
        return f
    end
    env.CreateFrame = function(kind, name, parent, template)
        local f = Frame(parent)
        if template == "ScrollFrameTemplate" then f.ScrollBar = Frame(f) end
        if name then env[name] = f end
        return f
    end
    env.C_Timer = { After = function(delay, fn) timers[#timers + 1] = { at = now + delay, fn = fn } end }
    env.InCombatLockdown = function() return combat end
    env.C_QuestLog = { GetNumQuestWatches = function() return 3 end,
        SortQuestWatches = function() sorts = sorts + 1 end }
    env.hooksecurefunc = function(obj, key, fn)
        assert(type(obj[key]) == "function", "invalid hook: " .. key)
        local old = obj[key]
        obj[key] = function(...) local result = { old(...) }; fn(...); return unpack(result) end
    end
    local function Load(path, source)
        if not source then
            local f = assert(io.open(root .. path, "r")); source = f:read("*a"); f:close()
        end
        local chunk
        if setfenv then chunk = assert(loadstring(source, path)); setfenv(chunk, env)
        else chunk = assert(load(source, path, "t", env)) end
        chunk("_FluxUI", ns)
    end
    local function Drain()
        local ticks = 0
        while #timers > 0 do
            ticks = ticks + 1; assert(ticks < 300, "unbounded timer loop")
            table.sort(timers, function(a, b) return a.at < b.at end)
            local t = table.remove(timers, 1); now = t.at; t.fn()
        end
    end
    local function Event(event, ...)
        for _, f in ipairs(frames) do
            if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
        end
    end
    env.UIParent = Frame(); env.UIParent:SetSize(1920, 1080)
    env.Minimap = Frame(env.UIParent); env.Minimap:SetSize(190, 190); env.Minimap.bottom = 850
    env.FLUX_API = { isForever = forever, isCamelot = forever, hasEditMode = forever,
        hasBlizzardObjectiveTrackerScroll = true }
    env.FluxMinimap = Frame()
    env.FluxMinimap.IsEmbedded = function() return embedded end
    env.FluxMinimap.EnforcePosition = function() end
    env.FluxMinimap.HookQuestWatchFramePositioning = function() end
    env.FluxWindowFrame = { frame = Frame() }; env.FluxWindowFrame.frame.top = 500
    env.FluxWindowFrame.GetFrame = function(self) return self.frame end
    Load("Minimap/FluxObjectiveTrackerScroll.lua")
    Load("Minimap/FluxQuestie.lua")

    local function NativeTracker()
        local t = Frame(env.UIParent); t.init = true
        t.Header = Frame(t); t.Header:SetHeight(32)
        t.Update, t.UpdateHeight = function() end, function() end
        if forever then t.UpdateHeaderPosition = function() end end
        env.ObjectiveTrackerFrame = t
        return t
    end
    local function Questie(enabled, lateFrames)
        env.Questie = { db = { profile = { trackerEnabled = enabled },
            char = { isTrackerExpanded = true, collapsedZones = {} } } }
        local lines, modules = {}, { QuestieTracker = {}, TrackerLinePool = {},
            TrackerBaseFrame = {}, TrackerHeaderFrame = {}, TrackerQuestFrame = {},
            QuestieCombatQueue = {}, TrackerFadeTicker = {}, QuestieCompat = {
                HideWatchFrame = function() if env.ObjectiveTrackerFrame then env.ObjectiveTrackerFrame:Hide() end end,
                ShowWatchFrame = function() if env.ObjectiveTrackerFrame then env.ObjectiveTrackerFrame:Show() end end,
            } }
        modules.QuestieTracker.Update = function()
            local q = modules.TrackerQuestFrame.questFrame
            if q then q:SetShown(env.Questie.db.char.isTrackerExpanded) end
        end
        modules.TrackerLinePool.GetLine = function(i) return lines[i] end
        modules.TrackerLinePool.GetHighestIndex = function() return #lines end
        env.QuestieLoader = { ImportModule = function(_, name) imports = imports + 1; return modules[name] end }
        local function MakeFrames()
            local base = Frame(env.UIParent)
            local header = Frame(base); header:SetHeight(24)
            header.trackedQuests = Frame(header)
            header.trackedQuests:SetScript("OnClick", function()
                env.Questie.db.char.isTrackerExpanded = not env.Questie.db.char.isTrackerExpanded
                modules.QuestieTracker:Update()
            end)
            local q = Frame(base); q.ScrollFrame = Frame(q); q.ScrollFrame:SetAllPoints(q)
            q.ScrollChildFrame = Frame(q.ScrollFrame); q.ScrollFrame:SetScrollChild(q.ScrollChildFrame)
            modules.TrackerBaseFrame.baseFrame = base
            modules.TrackerHeaderFrame.headerFrame = header
            modules.TrackerQuestFrame.questFrame = q
            modules.TrackerQuestFrame.PositionTrackedQuestsFrame = function()
                if env.Questie.db.profile.moveHeaderToBottom then q:SetPoint("BOTTOMLEFT", header, "TOPLEFT", 0, 4)
                else q:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0) end
            end
            modules.TrackerQuestFrame.PositionTrackedQuestsFrame()
            for i, mode in ipairs({ "zone", "quest", "objective", "objective" }) do
                local line = Frame(q.ScrollChildFrame); line.mode = mode
                line.label = Frame(line)
                line.label.text = string.rep("A long objective ", i * 6)
                function line.label:GetStringHeight() return math.ceil(#self.text * 6 / self:GetWidth()) * 12 end
                for _, key in ipairs({ "SetJustifyH", "SetWordWrap", "SetNonSpaceWrap", "SetMaxLines" }) do line.label[key] = Write end
                if mode == "zone" then line.expandZone = Frame(line); line.expandZone.zoneId = "Elwynn Forest" end
                if mode == "quest" then line.expandQuest = Frame(line) end
                lines[i] = line
            end
            return base, q, header, lines
        end
        if not lateFrames then MakeFrames() end
        return modules, MakeFrames
    end
    -- Execute the complete real minimap docking function; other minimap UI is unrelated.
    local f = assert(io.open(root .. "Minimap/FluxMinimap.lua", "r")); local source = f:read("*a"); f:close()
    local first = assert(source:find("function FluxMinimap:UpdateQuestTrackerPosition()", 1, true))
    local last = assert(source:find("-- Forever: PLAYER_LOGIN does not fire", first, true))
    Load("minimap tracker routing", "local addonName, addonTable = ...\n"
        .. "local embeddedState, CONFIG = {}, { Size = 190 }\n" .. source:sub(first, last - 1))
    return { env = env, ns = ns, Frame = Frame, Event = Event, Drain = Drain,
        NativeTracker = NativeTracker, Questie = Questie, Load = Load,
        SetEmbedded = function(value) embedded = value end,
        SetCombat = function(value) combat = value end,
        Counts = function() return mutations, sorts, imports end }
end

local function CheckParity(forever)
    local r = NewRuntime(forever); local env = r.env
    local modules, makeFrames = r.Questie(true, true)
    local native = r.NativeTracker(); native:Hide()
    local scroll = env.FluxObjectiveTrackerScroll
    local nativeUpdate = native.Update
    scroll:InstallForeverCompat()
    assert(native.Update == nativeUpdate, "unused Blizzard tracker was patched while Questie owned the dock")
    r.Event("PLAYER_LOGIN"); r.Drain()
    assert(not env.FluxObjectiveTrackerViewport, "Questie startup created a Blizzard viewport")
    local base, q, header, lines = makeFrames()
    modules.QuestieTracker:Update(); r.Drain()
    assert(base:GetWidth() == 175 and base.points[1][2] == env.Minimap)
    assert(base:GetHeight() == 350 and q:GetHeight() == 302)
    assert(lines[2].label.width < 175 and lines[2].height > 14, "long titles did not wrap")
    local height = 3
    for _, line in ipairs(lines) do height = height + line:GetHeight() end
    assert(q.ScrollChildFrame:GetHeight() == height and height > q:GetHeight(), "wrapped objectives cannot scroll")
    q.ScrollFrame:SetVerticalScroll(50); modules.QuestieTracker:Update()
    assert(q.ScrollFrame:GetVerticalScroll() == 50, "refresh reset scroll position")
    lines[4]:Hide(); q.ScrollFrame:SetVerticalScroll(9999); modules.QuestieTracker:Update()
    assert(q.ScrollFrame:GetVerticalScroll() == math.max(0, q.ScrollChildFrame:GetHeight() - q:GetHeight()))
    -- Pooled zone lines retain the existing toggle action after styling.
    local overlay = lines[1].FluxOverlay
    overlay:GetScript("OnClick")(overlay, "LeftButton")
    assert(env.Questie.db.char.collapsedZones["Elwynn Forest"] == true)
    overlay:GetScript("OnClick")(overlay, "LeftButton")
    assert(env.Questie.db.char.collapsedZones["Elwynn Forest"] == nil)
    r.SetEmbedded(true); env.FluxMinimap:UpdateQuestTrackerPosition()
    assert(base.points[1][2] == env.UIParent and base:GetHeight() == 580)
    local button = header.trackedQuests
    button:GetScript("OnClick")(button, "LeftButton"); r.Drain()
    assert(not env.Questie.db.char.isTrackerExpanded and base.points[1][1] == "BOTTOMRIGHT")
    button:GetScript("OnClick")(button, "LeftButton"); r.Drain()
    assert(env.Questie.db.char.isTrackerExpanded and q:IsShown())
    base:Hide(); env.FluxMinimap:UpdateQuestTrackerPosition()
    assert(not native:IsShown() and not env.FluxObjectiveTrackerViewport, "hidden Questie lost ownership")
    r.SetCombat(true); r.SetEmbedded(false)
    local writes = r.Counts()
    r.ns.FluxQuestie:UpdateLayout(); r.Drain()
    assert(r.Counts() == writes, "combat layout wrote frames")
    r.SetCombat(false); r.Event("PLAYER_REGEN_ENABLED"); r.Drain()
    assert(base.points[1][2] == env.Minimap, "combat-deferred dock was lost")
    assert(not scroll.IsActiveFor(native))
    return { base:GetWidth(), base:GetHeight(), q:GetHeight(), height }
end

local classic, forever = CheckParity(false), CheckParity(true)
for i = 1, #classic do assert(classic[i] == forever[i], "Forever layout differs from Classic") end

-- Late Questie load after the Blizzard header has already left its native parent.
local r = NewRuntime(true); local env = r.env
local native = r.NativeTracker(); local scroll = env.FluxObjectiveTrackerScroll
local viewport = assert(scroll:EnsureViewport(native)); r.Drain()
assert(native.Header:GetParent() == viewport and viewport:IsShown())
scroll:QueueFullLayout(native, 200)
local modules = r.Questie(true)
r.Event("ADDON_LOADED", "Questie")
native:Hide()
local _, sorts = r.Counts()
r.Drain()
assert(not viewport:IsShown(), "detached All Objectives header remained visible")
scroll:EnsureVisibleBody(native); scroll:SyncAfterUpdate(native)
scroll:StartForeverLoginPulse(); scroll:ReassertDock(native); r.Drain()
assert(not native:IsShown(), "Flux resurrected the Questie-suppressed tracker")
local _, laterSorts = r.Counts(); assert(laterSorts == sorts, "native watch sorting ran while Questie owned the dock")
assert(scroll:EnsureViewport(native) == nil)
-- Disabling Questie's tracker yields the same viewport to Blizzard again.
env.Questie.db.profile.trackerEnabled = false
modules.QuestieTracker:Update(); r.Drain()
assert(viewport:IsShown() and scroll:EnsureViewport(native) == viewport)
assert(scroll.IsActiveFor(native))
assert(native:IsShown(), "Questie's native visibility guard was not released")

-- Forever's optional native timer survives hiding ObjectiveTrackerFrame, leaves
-- space for objectives, and returns to its original parent when disabled.
local timed = NewRuntime(true); local tenv = timed.env
local tn = timed.NativeTracker(); local tm = timed.Questie(true)
local timer = timed.Frame(tn); timer:SetPoint("TOP", tn, "TOP", 0, -10)
timer.numTimers = 1; timer.GetFrameHeight = function() return 59 end
tenv.QuestTimerFrame, tn.QuestTimerFrame = timer, timer
tenv.Questie.db.profile.showBlizzardQuestTimer = true
timed.Event("PLAYER_LOGIN"); timed.Drain()
local qb, qf = tm.TrackerBaseFrame.baseFrame, tm.TrackerQuestFrame.questFrame
assert(timer:GetParent() == qb and not tn:IsShown())
assert(qf:GetHeight() == 302 - 63 and qf.points[1][5] == -63)
tenv.FluxMinimap:UpdateQuestTrackerPosition()
assert(qf.points[1][5] == -63, "timer offset accumulated on dock refresh")
tenv.Questie.db.profile.moveHeaderToBottom = true
tm.QuestieTracker:Update(); timed.Drain()
assert(qf.points[1][1] == "BOTTOMLEFT" and qf.points[1][5] == 4)
timer:Hide(); timed.Drain()
assert(qf:GetHeight() == 302, "hidden timer retained blank space")
tenv.Questie.db.profile.showBlizzardQuestTimer = false
tm.QuestieTracker:Update(); timed.Drain()
assert(timer:GetParent() == tn and timer.points[1][5] == -10)
-- Questie present for map pins alone must retain the Blizzard tracker.
local pins = NewRuntime(true); pins.Questie(false); pins.Event("PLAYER_LOGIN"); pins.Drain()
assert(pins.env.FluxObjectiveTrackerScroll:EnsureViewport(pins.NativeTracker()))
print("Questie tracker smoke OK (Classic/Forever parity, async frames, late addon, native header ownership, overflow, collapse/expand, combat, optional native timer and disabled tracker)")
