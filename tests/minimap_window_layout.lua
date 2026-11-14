-- Real embedded-map, window-size and tracker methods with the strict desktop
-- frame fixture. No native taint VM, pixels, controller input or FPS is tested.
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function near(a, b, why) check(math.abs(a - b) < .001, why .. ": " .. tostring(a) .. " / " .. tostring(b)) end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local function slice(source, first, last)
    local a = assert(source:find(first, 1, true), first)
    local b = assert(source:find(last, a + #first, true), last)
    return source:sub(a, b - 1)
end
-- Reuse the event/scale/protected-write model, without executing its test cases.
local modelSource = read("tests/minimap_extra_layout.lua")
local fixture = modelSource:sub(1, assert(modelSource:find("local function physical(frame)", 1, true)) - 1)
local makeModel = assert(load(fixture .. "\nreturn boot", "@shared strict minimap fixture", "t", _G))()
local mapSource = read(os.getenv("FLUX_MINIMAP_WINDOW_SOURCE") or "Minimap/FluxMinimap.lua")
local windowSource = read("Battlezonemap/FluxWindowFrame.lua")
local questieSource = read("Minimap/FluxQuestie.lua")
local noop = function() end

local function boot(changedMapSource)
    local t = makeModel()
    local e = t.env
    local m = e.FluxMinimap
    m.InfoBar = e.CreateFrame("Frame", "TestMinimapInfoBar", e.UIParent)
    m.InfoBar:SetSize(190, 24)
    m.InfoBar:SetPoint("BOTTOMRIGHT", e.Minimap, "TOPRIGHT", 0, -2)
    m.UpdateStyle, m.PositionIndicators, m.Refresh = noop, noop, noop
    m.NotifyInfoFrameLayoutChanged, m.HookQuestWatchFramePositioning = noop, noop
    m.CleanupBlizzardFrames, m.RegisterEvent = noop, noop
    m.scripts = {}
    m.SetScript = function(self, key, fn) self.scripts[key] = fn end
    m.GetScript = function(self, key) return self.scripts[key] end
    m.RefreshInfoBarZoneFit = function() t.zoneFits = (t.zoneFits or 0) + 1 end
    e.MinimapCluster = e.CreateFrame("Frame", "TestMinimapCluster", e.UIParent)
    e.FLUX_API = {hasEditMode = true, hasBlizzardObjectiveTrackerScroll = true}
    local source = changedMapSource or mapSource
    local code = [[
local embeddedState = {isEmbedded = false}
local minimapPositionQueue = {}
local CONFIG = {Size = 190, Scale = 1}
local Flux = _G.Flux
local addonTable = {}
local FluxMinimap_TryRebuildMicroMenuPos3 = function() end
]] .. slice(source, "local function KeepMinimapClusterHidden()", "--- Restore the Minimap to its normal position")
        .. slice(source, "function FluxMinimap:RestoreToNormal()", "--- Check if the Minimap is currently embedded")
        .. slice(source, "function FluxMinimap:IsEmbedded()", "--- Width of the top-right minimap")
        .. slice(source, "function FluxMinimap:HideEmbedded()", "--- Notify FluxInfoFrame")
        .. slice(source, "function FluxMinimap:UpdateQuestTrackerPosition()", "-- Forever: PLAYER_LOGIN does not fire")
        .. slice(source, 'FluxMinimap:SetScript("OnEvent", function(self, event, ...)', "function FluxMinimap:Initialize()")
        .. "\nreturn embeddedState"
    e.unpack = table.unpack or unpack
    e.table = setmetatable({wipe = e.wipe}, {__index = table})
    t.state = assert(load(code, "@actual embedded map and tracker methods", "t", e))()
    local windowCode = "local windowFrame = FluxWindowFrame.frame\nlocal WINDOW_WIDTH, WINDOW_HEIGHT = 540, 292\n"
        .. slice(windowSource, "function FluxWindowFrame:SetSize(width, height)", "--- Set the window position offset")
    assert(load(windowCode, "@actual Flux Window resize", "t", e))()
    t.map, t.m = e.Minimap, m
    function t:tickWatcher()
        local watcher = self.m._embedSizeWatcher
        local fn = watcher and watcher:GetScript("OnUpdate")
        if fn then fn(watcher, .016) end
    end
    function t:embed()
        check(self.m:EmbedInFrame(self.window), "real map embed succeeds")
        return self
    end
    return t
end

local function mapScenario(source)
    local t = boot(source):embed()
    local e, m = t.env, t.m
    near(t.map:GetWidth(), 270, "default map fits 292px host height minus info bar")
    near(t.map:GetHeight(), t.map:GetWidth(), "embedded map stays square")
    local point, parent, relative, x, y = t.map:GetPoint()
    check(point == "TOPRIGHT" and parent == t.window and relative == "TOPRIGHT" and x == 0 and y == -22,
        "real map retains right alignment and info-bar gap")
    check(#t:visible() == 15, "actual embed creates shared buttons")
    e._FluxUI_CharSavedVars.minimapExtraLayout = {embeddedMapScale = 40, embeddedColumns = 8}
    check(m:EmbedInFrame(t.window), "same-parent embed refresh succeeds")
    near(t.map:GetWidth(), 270, "retired saved map percentage cannot affect automatic size")
    t:tickWatcher()
    near(t.map:GetWidth(), 270, "startup watcher uses automatic fitted size")
    near(m.InfoBar:GetWidth(), 270, "info-bar width follows automatic map size")
    check(e._FluxUI_CharSavedVars.minimapExtraLayout.embeddedMapScale == 40,
        "retired saved map preference preserved without being applied")
    t.window:SetSize(600, 360)
    check(m:EmbedInFrame(t.window), "same-parent embed reapplies changed host geometry")
    near(t.map:GetWidth(), 338, "same-parent automatic map responds to window geometry")
    m:HideEmbedded()
    check(m:IsEmbedded() and not t.map:IsShown() and #t:visible() == 0,
        "inactive Map tab keeps embed ownership but hides buttons")
    t.api:SetSetting("count", 16)
    check(not t.map:IsShown() and #t:visible() == 0, "count refresh does not resurrect inactive tab")
    t:tickWatcher()
    check(not t.map:IsShown() and #t:visible() == 0, "startup watcher does not resurrect inactive buttons")
    e.FluxWindowFrame:SetSize(500, 340)
    near(t.map:GetWidth(), 318, "real window resize updates automatic embedded map")
    check(not t.map:IsShown() and #t:visible() == 0, "window resize keeps inactive map/buttons hidden")
    m:ShowEmbedded()
    check(t.map:IsShown() and #t:visible() == 16, "returning to Map tab restores same strip")
    for _, dimensions in ipairs({{300, 420}, {120, 200}, {900, 270}}) do
        e.FluxWindowFrame:SetSize(dimensions[1], dimensions[2])
        check(t.map:GetWidth() > 0 and t.map:GetWidth() < dimensions[1]-10,
            "automatic map leaves a usable button strip in narrow/tall/wide windows")
        check(#t:visible() == 16, "all buttons remain visible with automatic map fitting")
    end
    local applied, identity = t.map:GetWidth(), t.widgets[1].Widget
    t.combat = true
    t.api:SetSetting("count", 30)
    near(t.map:GetWidth(), applied, "combat count change does not write native geometry")
    check(#t:visible() == 16, "combat count reflow remains deferred")
    t.combat = false; t:flush()
    check(#t:visible() == 30 and t.widgets[1].Widget == identity, "regen applies automatic layout without replacing actions")
    return t
end
mapScenario()

-- The existing native minimap code permits visual sizing during combat and
-- queues parent/anchor changes. Permit only its documented visual calls on
-- these two native frames; secure button/slot geometry keeps the strict guard.
local function allowNativeCombatVisuals(t)
    for frame, methods in pairs({
        [t.map] = {"SetSize", "SetScale", "SetFrameStrata", "SetFrameLevel", "Show", "Hide"},
        [t.m.InfoBar] = {"SetWidth", "SetHeight", "SetFrameStrata", "SetFrameLevel", "Show", "Hide"},
    }) do
        for _, key in ipairs(methods) do
            local original = frame[key]
            frame[key] = function(self, ...)
                local previous = t.secure
                t.secure = true
                local result = original(self, ...)
                t.secure = previous
                return result
            end
        end
    end
end
local function regen(t)
    t.combat = false
    t.m:GetScript("OnEvent")(t.m, "PLAYER_REGEN_ENABLED")
    t:event("PLAYER_REGEN_ENABLED")
    t:flush()
end
local function queuedScenario(source)
    local queued = boot(source)
    allowNativeCombatVisuals(queued)
    queued.combat = true
    check(queued.m:EmbedInFrame(queued.window), "first embed queues native positioning during combat")
    check(queued.map:GetParent() == queued.env.UIParent and queued.creates == 0,
        "combat embed leaves native parent and secure buttons unchanged")
    regen(queued)
    check(queued.map:GetParent() == queued.window and #queued:visible() == 15,
        "queued first embed acquires button host when actual native regen handler drains")
    queued.api:SetSetting("sideEnabled", true)
    queued.combat = true
    queued.m:RestoreToNormal()
    check(not queued.m:IsEmbedded() and queued.map:GetParent() == queued.window,
        "combat restore keeps native parent until regen")
    regen(queued)
    check(queued.map:GetParent() == queued.env.UIParent and #queued:visible() == 15,
        "queued restore activates optional side strip on native regen")
    check(queued.env.FluxMinimapButtonsContainer:GetParent() == queued.env.UIParent,
        "restored side strip leaves embedded host")

    local cancelled = boot(source)
    allowNativeCombatVisuals(cancelled)
    cancelled.api:SetSetting("sideEnabled", true)
    cancelled.combat = true
    check(cancelled.m:EmbedInFrame(cancelled.window), "combat embed before immediate restore queues")
    cancelled.m:RestoreToNormal()
    regen(cancelled)
    check(not cancelled.m:IsEmbedded() and cancelled.map:GetParent() == cancelled.env.UIParent,
        "combat embed then restore reconciles latest native ownership")
    check(#cancelled:visible() == 15 and cancelled.env.FluxMinimapButtonsContainer:GetParent() == cancelled.env.UIParent,
        "combat embed then restore retains optional side strip")
end
queuedScenario()

local function trackerScenario(uiScale, viewportScale)
    local t = boot()
    local e, m = t.env, t.m
    e.UIParent:SetScale(uiScale)
    e.ObjectiveTrackerFrame = e.CreateFrame("Frame", "TestObjectiveTracker", e.UIParent)
    local tracker = e.ObjectiveTrackerFrame
    tracker:SetSize(250, 400); tracker:SetScale(.75); tracker.fluxInitialized = true
    local viewport = e.CreateFrame("Frame", "TestTrackerViewport", e.UIParent)
    viewport:SetScale(viewportScale)
    viewport:SetSize(250, 400)
    tracker.fluxScrollActive = true
    e.FluxObjectiveTrackerScroll = {
        EnsureViewport = function() return viewport end,
        PinLayoutHeight = noop, ApplyViewportSize = function() return false end,
    }
    t.api:SetSetting("sideEnabled", true)
    t.api:SetSetting("count", 60)
    local offset = t.api:GetTrackerOffset()
    check(offset < 0, "below-map strip reserves tracker space")
    m:UpdateQuestTrackerPosition()
    local _, relative, relativePoint, x = viewport:GetPoint()
    check(relative == t.map and relativePoint == "BOTTOMRIGHT", "native viewport stays below minimap")
    near(x * viewport:GetEffectiveScale() / e.UIParent:GetEffectiveScale(), offset,
        "native viewport reservation converts from UIParent to viewport scale")
    near(tracker._fluxDockSnap.dockX, offset, "native snap records UIParent reservation")
    t.api:SetSetting("count", 1)
    local nextOffset = t.api:GetTrackerOffset()
    check(nextOffset > offset, "automatic lower count reduces reservation")
    m:UpdateQuestTrackerPosition()
    local _, _, _, nextX = viewport:GetPoint()
    near(nextX * viewport:GetEffectiveScale() / e.UIParent:GetEffectiveScale(), nextOffset,
        "same-height native snap invalidates when automatic width changes")
    t.api:SetSetting("sideEnabled", false)
    m:UpdateQuestTrackerPosition()
    local _, _, _, restoredX = viewport:GetPoint()
    near(restoredX, 0, "disabling side strip restores tracker reservation")
    return t
end
for _, scale in ipairs({.7, 1, 1.35}) do trackerScenario(scale, .6) end

local questieHelpers = slice(questieSource, "local function SetWidthIfChanged", "-- INITIALIZATION")
local questieMethod = slice(questieSource, "function FluxQuestie:StyleBaseFrame(baseFrame)", "function FluxQuestie:SizeQuestFrame")
for _, uiScale in ipairs({.8, 1.2}) do
    local t = boot()
    local e = t.env
    e.UIParent:SetScale(uiScale)
    e.Questie = {db = {char = {isTrackerExpanded = true}, profile = {}}}
    e.FluxQuestie = {}
    assert(load("local TRACKER_WIDTH=175\n" .. questieHelpers .. questieMethod,
        "@actual Questie dock method", "t", e))()
    local base = e.CreateFrame("Frame", "TestQuestieBase", e.UIParent)
    base:SetSize(175, 400); base:SetScale(.8)
    t.api:SetSetting("sideEnabled", true)
    for _, expanded in ipairs({true, false}) do
        e.Questie.db.char.isTrackerExpanded = expanded
        e.FluxQuestie:StyleBaseFrame(base)
        local _, relative, relativePoint, x = base:GetPoint()
        check(relative == t.map and relativePoint == "BOTTOMRIGHT", "Questie retains minimap dock expanded/collapsed")
        near((x + 15) * base:GetEffectiveScale() / e.UIParent:GetEffectiveScale(), t.api:GetTrackerOffset(),
            "Questie reservation converts from UIParent scale")
    end
    t.api:SetSetting("sideEnabled", false)
    e.FluxQuestie:StyleBaseFrame(base)
    local _, _, _, x = base:GetPoint()
    near(x, -15, "Questie returns to original dock offset when disabled")
end

-- Observable controls reject stale startup/same-parent fitting and losing the
-- strip entirely when a tall host lets the map consume its full width.
local mutants = {
    (mapSource:gsub("local newMapSize = self:CalculateEmbeddedMapSize%(currentParentWidth, currentParentHeight, inset%)",
        "local newMapSize = 1", 1)),
    (mapSource:gsub("self:RefreshEmbeddedLayout%(%)\n        return true", "return true", 1)),
    (mapSource:gsub("width %- reserve, height %- 24 %+ inset", "width, height - 24 + inset", 1)),
}
for i, mutant in ipairs(mutants) do
    check(mutant ~= mapSource and not pcall(mapScenario, mutant), "map regression control " .. i .. " rejected")
end
local missingReconcile = mapSource:gsub("if reconcileButtons and FluxMinimapButtons then", "if false and FluxMinimapButtons then", 1)
check(missingReconcile ~= mapSource and not pcall(queuedScenario, missingReconcile), "missing queued embed/restore reconciliation rejected")
print(("Minimap window integration: %d checks; real map/window/tracker/Questie paths and four harmful controls passed"):format(checks))
