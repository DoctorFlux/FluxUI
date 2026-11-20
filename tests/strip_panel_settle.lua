-- Run the Info placement and unified border transaction against modeled peers.
local function read(path, checkpoint)
    local file = assert(io.open(checkpoint and checkpoint .. "/" .. path:gsub("/", "-") or path, "rb"))
    local text = file:read("*a")
    file:close()
    return (text:gsub("\r\n", "\n"))
end
local function section(source, first, last)
    local start = assert(source:find(first, 1, true))
    return source:sub(start, assert(source:find(last, start + #first, true)) - 1)
end

local function fixture(placement, before)
    local s = {placement = placement, timer = {}, time = 1, counts = {}}
    local function hit(key)
        s.counts[key] = (s.counts[key] or 0) + 1
    end
    local function frame(name, left, width, height)
        local o = {name = name, left = left, width = width, height = height, shown = true, points = {}}
        function o:IsShown() return self.shown end
        function o:GetLeft() hit(self.name .. "Left"); return self.left end
        function o:GetRight() return self.left + self.width end
        function o:GetBottom() hit(self.name .. "Bottom"); return 0 end
        function o:GetWidth() return self.width end
        function o:GetHeight() hit(self.name .. "Height"); return self.height end
        function o:SetHeight(h) self.height = h end
        function o:SetWidth(w) self.width = w end
        function o:GetParent() return self.parent end
        function o:SetParent(parent) self.parent = parent end
        function o:ClearAllPoints() self.points = {} end
        function o:SetPoint(...) self.points[#self.points + 1] = {...};hit(self.name .. "Point") end
        function o:GetNumPoints() return #self.points end
        function o:GetPoint(index) return table.unpack(self.points[index]) end
        function o:Show() self.shown = true end
        function o:Hide() self.shown = false end
        return o
    end
    local env = setmetatable({}, {__index = _G})
    env._G = env
    env.UIParent = frame("Parent", 0, 1920, 1080)
    env.FluxMainActionBar = frame("Strip", 420, 1000, 55)
    local combat = frame("Combat", 325, 95, 55)
    local noncombat = frame("NonCombat", 0, 200, 60)
    local right = frame("Window", 1540, 380, 320)
    local trinket = frame("Trinket", 1415, 40, 55)
    local info = frame("Info", 0, 110, 55)
    local envelope = frame("Envelope", 0, 100, 55)
    local gap = frame("InfoGap", 0, 110, 55)
    local trinketGap = frame("TrinketGap", 1455, 85, 55)
    env.FluxCombatManager = {Grid = {Frame = combat}}
    env.FluxNonCombatAPI = {DefaultGrid = {Frame = noncombat}}
    env.FluxInfoFrame = {SetAnchoredByStatusBarColumn = function() end}
    env.FluxOptions = {GetInfoFramePlacement = function() return s.placement end}
    env.FluxPVPObjectiveMover = {UpdatePositions = function() hit("pvp") end}
    env.InCombatLockdown = function() return s.locked end
    env.GetPlacement = function() return s.placement end
    env.GetTime = function() return s.time end
    env.GetDynamicVerticalHeight = function() hit("defaultHeight"); return 55 end
    env.CalculateMinimalWidth = function() return 100 end
    env.UpdateStats = function() hit("stats") end
    env.SyncStripVisualWithPlacement = function() hit("chrome") end
    env.CreateInfoFrame = function() end
    env.EnsureStatusBarContainerHooks = function() end
    env.EnsureMinimapHooks = function() end
    env._SyncPositionWatcher = function() end
    env.LayoutMinimapTop = function() hit("minimap") end
    env.FluxInfoFrame._LayoutScreenTopLeft = function() hit("screen") end
    env.C_Timer = {After = function(_, task) s.timer[#s.timer + 1] = task end}
    env.GetBorderAnchors = function()
        hit("anchorSelection")
        return {leftAnchor = noncombat, rightAnchor = right, rightPoint = "LEFT",
            rightOffsetX = -6, bottomAnchor = noncombat, topAnchor = noncombat}
    end
    env.GamepadHudOn = function() return false end
    env.GetComponents = function()
        return {trinketMenuFrame = trinket, windowFrame = right, nonCombatGridFrame = noncombat,
            combatGridFrame = combat, actionBar = env.FluxMainActionBar}
    end
    local infoSource = read("StatusBars/FluxInfoFrame.lua", before)
    local infoCode = "local InfoFrame, frame = ...\nlocal initialized = true\n"
        .. section(infoSource, "local ACTION_STRIP_GAP_BACKDROP_BLEED", "--- FPS/dur/ping strip")
        .. section(infoSource, "local function LayoutIntegrated()", "local minimapHooksDone")
        .. section(infoSource, "local function RefreshPlacementChromeAndDependents()", "-- EVENT-BASED: Stats")
        .. section(infoSource, "InfoFrame.UpdatePosition = UpdatePosition", "--- Immediate full layout")
    assert(load(infoCode, "@actual-info-position", "t", env))(env.FluxInfoFrame, info)
    local borderSource = read("Layout/UnifiedBorder.lua", before)
    local infoGapSource = "local function UpdateActionStripInfoGapBackdrop"
    local nextFunction = borderSource:find("local function GapPointMatches(", 1, true)
        and "local function GapPointMatches(" or "local function UpdateGapBackdrop()"
    local arrowCode = borderSource:find("local function RefreshBorderArrows()", 1, true)
        and section(borderSource, "local function RefreshBorderArrows()", "local function CreateBorderFrame()") or ""
    local borderCode = "local borderFrame, gapBackdropFrame, actionStripInfoGapBackdropFrame, onGap = ...\nlocal UnifiedBorder = {}\n"
        .. arrowCode
        .. section(borderSource, infoGapSource, nextFunction)
        .. "\nlocal ApplyInfoGap=UpdateActionStripInfoGapBackdrop\nUpdateActionStripInfoGapBackdrop=function(...) onGap('infoGap'); return ApplyInfoGap(...) end\n"
        .. section(borderSource, nextFunction, "local lastBorderLayoutHash")
        .. "\nlocal ApplyGap=UpdateGapBackdrop\nUpdateGapBackdrop=function(...) onGap('trinketGap'); return ApplyGap(...) end\n"
        .. section(borderSource, "local lastBorderLayoutHash", "--- Unified micro+status chrome")
        .. "\nUnifiedBorder.UpdateBorder = UpdateBorder; return UnifiedBorder"
    env.FluxUnifiedBorder = assert(load(borderCode, "@actual-unified-border", "t", env))(envelope, trinketGap, gap, hit)
    env.FluxInfoFrame.UpdatePosition()
    env.FluxUnifiedBorder.UpdateBorder()

    function s:cross(left)
        self.counts = {}
        self.time = self.time + 1
        combat.left, trinket.left = left, left + 470
        env.FluxUnifiedBorder.RequestGridLayoutUpdate()
        env.FluxUnifiedBorder.UpdateAfterGridLayout(true)
        local queued = self.timer
        self.timer = {}
        for _, task in ipairs(queued) do task() end
        return self.counts
    end
    function s:replaceRight()
        right = frame("Replacement", right.left, right.width, right.height)
        self.counts = {}
        env.FluxUnifiedBorder.UpdateBorder()
        return self.counts
    end
    s.env, s.info, s.gap, s.envelope, s.combat = env, info, gap, envelope, combat
    s.nonCombat = noncombat
    s.trinket, s.trinketGap = trinket, trinketGap
    return s
end

local checkpoint = arg[1]
for _, placement in ipairs({"actionStrip", "minimapTop", "screenTopLeft", "statusIntegrated"}) do
    local after = fixture(placement)
    local before = checkpoint and fixture(placement, checkpoint)
    for i = 1, 8 do
        local left = i % 2 == 1 and 342 or 304
        local counts = after:cross(left)
        assert(counts.anchorSelection == 1 and not counts.EnvelopePoint)
        assert(not counts.chrome and not counts.pvp and not counts.minimap and not counts.screen)
        assert(counts.infoGap == 1 and counts.trinketGap == 1 and not counts.TrinketGapPoint)
        assert(after.trinketGap.points[1][2]:GetRight() == left + 510)
        assert(after.info.shown == (placement ~= "statusIntegrated" and (placement ~= "actionStrip" or i % 2 == 1)))
        assert(after.gap.shown == (placement ~= "actionStrip" and i % 2 == 1), "gap follows the current available strip width")
        if placement == "actionStrip" and after.info.shown then
            assert(after.info.points[2][2] == after.combat, "Info remains anchored to the correct grid")
        end
        if before then
            local old = before:cross(left)
            assert(old.chrome == 1 and before.info.shown == after.info.shown)
            print(("STRIP_INFO placement=%s crossing=%d fullChrome=%d/0 stats=%d/%d gap=%d/%d")
                :format(placement, i, old.chrome, old.stats or 0, counts.stats or 0, old.trinketGap or 0, counts.trinketGap))
        end
    end
end

local control = fixture("screenTopLeft")
control.placement = "actionStrip"
local changed = control:cross(350)
assert(changed.chrome == 1 and changed.pvp == 1 and control.info.shown, "new placement uses full setup")
control.trinket:Hide()
local detached = control:cross(340)
assert(detached.TrinketGapPoint == 4 and control.trinketGap.points[1][2] == control.env.FluxMainActionBar,
    "the gap reconnects to the strip when the trinket owner hides")
control.trinket:Show()
local reattached = control:cross(350)
assert(reattached.TrinketGapPoint == 4 and control.trinketGap.points[1][2] == control.trinket,
    "the gap reconnects to the current trinket owner")
assert(control:replaceRight().EnvelopePoint == 4 and control.envelope.points[2][2].name == "Replacement",
    "same coordinates with a new right-hand frame require a new anchor")
if checkpoint then
    local before = fixture("screenTopLeft", checkpoint)
    assert(not before:replaceRight().EnvelopePoint and before.envelope.points[2][2].name == "Window",
        "archived geometry-only hash incorrectly retains the old frame")
end

control.counts = {}
control.env.FluxInfoFrame.UpdatePosition()
assert(control.counts.chrome == 1, "ordinary refresh keeps its full update")
control.counts = {}
control.locked = true
control.env.FluxInfoFrame.UpdateAfterStripLayout()
control.env.FluxUnifiedBorder.UpdateBorder(true)
assert(next(control.counts) == nil, "layout remains outside combat")

for _, placement in ipairs({"actionStrip", "screenTopLeft", "minimapTop", "statusIntegrated"}) do
    local stable = fixture(placement)
    local slot = placement == "actionStrip" and stable.info or stable.gap
    local key = slot.name .. "Point"
    assert(#slot.points == 3, "initial sufficiently wide slot binds")
    assert(not stable:cross(342)[key], "first crossing preserves the existing native anchors")
    local reads = stable:cross(366)
    assert(not reads[key] and slot.shown, "native slot follows its existing peers")
    assert(reads.NonCombatLeft == 1 and reads.NonCombatBottom == 1, "envelope samples each role owner once")
    assert(slot.points[2][2] == stable.combat and slot.points[2][2]:GetLeft() == 366)
    stable:cross(304)
    assert(not slot.shown, "narrow slots still hide")
    assert(not stable:cross(366)[key] and slot.shown, "a wide slot reuses the points after hiding")

    slot.points[2][4] = 12
    assert(stable:cross(360)[key] == 3 and slot.points[2][4] == (slot == stable.info and -4 or 0),
        "drifted points are restored")
    local getPoint = slot.GetPoint
    local private = {}
    stable.env.issecretvalue = function(value) return rawequal(value, private) end
    slot.GetPoint = function() return private, private, private, private, private end
    assert(stable:cross(362)[key] == 3, "private points take the normal write path")
    slot.GetPoint = function() error("denied point") end
    assert(stable:cross(366)[key] == 3, "unreadable points take the normal write path")
    slot.GetPoint = getPoint

    stable.combat:Hide()
    assert(stable:cross(342)[key] == 3 and slot.points[2][2] == stable.env.FluxMainActionBar)
    stable.env.FluxMainActionBar:Hide()
    stable.env.FluxTrinketMenu = { Frame = stable.trinket }
    assert(stable:cross(366)[key] == 3 and slot.points[2][2] == stable.trinket)
    assert(not stable:cross(342)[key], "the slot reuses the current trinket attachment")
    stable.trinket:Hide()
    assert(stable:cross(366)[key] == 2 and slot.points[2][1] == "TOP")
    assert(not stable:cross(342)[key], "fixed-width slots keep their two points")
    stable.nonCombat:Hide()
    stable:cross(366)
    assert(not slot.shown, "no noncombat grid hides the slot")
end

local infoCheckpoint = os.getenv("FLUX_INFO_MEASURE_CHECKPOINT")
if infoCheckpoint then
    for _, placement in ipairs({"actionStrip", "minimapTop", "screenTopLeft", "statusIntegrated"}) do
        local old, current = fixture(placement, infoCheckpoint), fixture(placement)
        local totals = {{heightDefaults=0, combatReads=0, nonCombatReads=0}, {heightDefaults=0, combatReads=0, nonCombatReads=0}}
        for i = 1, 60 do
            local left = i % 2 == 1 and 342 or 304
            local before, after = old:cross(left), current:cross(left)
            assert(old.info.shown == current.info.shown and old.info.height == current.info.height)
            assert(old.gap.shown == current.gap.shown and (before.stats or 0) == (after.stats or 0))
            for index, counts in ipairs({before, after}) do
                local sample = totals[index]
                sample.heightDefaults = sample.heightDefaults + (counts.defaultHeight or 0)
                sample.combatReads = sample.combatReads + (counts.CombatHeight or 0)
                sample.nonCombatReads = sample.nonCombatReads + (counts.NonCombatHeight or 0)
            end
        end
        local before, after = table.unpack(totals)
        assert(before.heightDefaults == 60 and before.combatReads == 60)
        local expected = placement == "actionStrip" and 60 or 0
        assert(after.heightDefaults == expected and after.combatReads == expected)
        assert(before.nonCombatReads - after.nonCombatReads == 60 - expected)
        print(("INFO_GAP placement=%s changes=60 defaults=%d/%d combatHeight=%d/%d nonCombatHeight=%d/%d"):format(
            placement, before.heightDefaults, after.heightDefaults, before.combatReads, after.combatReads,
            before.nonCombatReads, after.nonCombatReads))
    end
end
print("Strip panel settlement passes all Info placements, narrow slots, changing ownership and combat guards.")
