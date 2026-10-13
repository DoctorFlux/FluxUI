-- FluxObjectiveTrackerScroll.lua
-- Post–Dragonflight live and Forever: fixed "All Objectives" header; only the tracker body scrolls.
-- Outer frame is positioned/scaled; inner ScrollFrame clips tall content.
-- Wheel over the header, objective rows, and empty tracker space scrolls that body.
-- Never replace GetAvailableHeight / UpdateTopPadding: those run inside Blizzard
-- Update() before ShouldShowMawBuffs, so a Flux function taints GetAuraDataByIndex.
-- Forever (camelot) ships extra header-padding providers and a QuestTimer child that live retail does not;
-- those are pinned/docked here so the dock matches the retail Flux tracker.
-- Forever Frame:Update also runs a gamepad pass after Container:Update; if that throws,
-- DirtiableMixin never clears dirty and later quests never layout. Guards are after-only.
-- Cold login: install those guards as soon as ObjectiveTrackerFrame exists (not only
-- FluxMinimap PLAYER_LOGIN dock). QUEST_LOG_UPDATE / login pulse clear stuck dirty
-- without calling Update() from Flux (MawBuffs / Edit Mode taint).

local addonName, addonTable = ...

local FluxObjectiveTrackerScroll = {}

local LEFT_VISUAL_BLEED = 32
-- Forever NineSlice is TOPLEFT x=-30; POI buttons sit left of HeaderText (~34px).
-- Clip must be wider than the tracker or those draw cut off.
local FOREVER_CLIP_LEFT_BLEED = 40
local HEADER_GAP = 2
-- GetAvailableHeight is GetHeight()-topModulePadding. Forever UpdateTopPadding is 38+
-- (live stays 0), so a viewport-sized tracker skips quests and can Hide() the body
-- while Flux still shows "All Objectives" on the outer header. Keep layout tall;
-- the ScrollFrame is the clip. Never replace GetAvailableHeight (MawBuffs taint).
local LAYOUT_HEIGHT = 100000

local function nearlyEq(a, b)
    return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) < 0.5
end

-- Skip ClearAllPoints when the tracker is already TOPRIGHT on the clip (tab switches).
local function isAnchoredTopRight(frame, relativeTo)
    if not frame or not relativeTo or not frame.GetPoint then
        return false
    end
    if frame.GetNumPoints and frame:GetNumPoints() ~= 1 then
        return false
    end
    local point, rel, relPoint, x, y = frame:GetPoint(1)
    return point == "TOPRIGHT" and rel == relativeTo and relPoint == "TOPRIGHT"
        and nearlyEq(x, 0) and nearlyEq(y, 0)
end

local outerViewport
local scrollBody
local scrollContent -- full-width child of scrollBody; ScrollFrame scrolls this — tracker stays TOPRIGHT inside it (no X drift when scrolling)
local hooksInstalled = false
local foreverCompatInstalled = false
local questTimerWatch
local loginPulseStarted = false
local questLogDirtyWatch
local managerInitHooked = false

local function nop() end

local function isCamelotClient()
    if addonTable and addonTable._isCamelotGameType then
        return true
    end
    local Client = addonTable and addonTable.Flux and addonTable.Flux.Client
    if Client and (Client.isCamelot or Client.isForever) then
        return true
    end
    if FLUX_API and (FLUX_API.isCamelot or FLUX_API.isForever) then
        return true
    end
    return false
end

-- Forever ObjectiveTrackerFrameMixin adds UpdateHeaderPosition / UpdateTopPadding and parents QuestTimerFrame.
local function isForeverObjectiveTracker(tracker)
    tracker = tracker or ObjectiveTrackerFrame
    if not tracker then
        return false
    end
    if isCamelotClient() then
        return true
    end
    return tracker.UpdateHeaderPosition ~= nil
        or tracker.UpdateTopPadding ~= nil
        or tracker.QuestTimerFrame ~= nil
end

local WHEEL_STEP = 30

local function visualBleed(tracker)
    if isForeverObjectiveTracker(tracker) then
        return FOREVER_CLIP_LEFT_BLEED
    end
    return LEFT_VISUAL_BLEED
end

-- Hidden ScrollBar:ScrollStepInDirection stays at pan extent 0 when the range
-- was never refreshed, so the wheel does nothing over the list. Drive
-- SetVerticalScroll directly. The same handler is on the viewport (All
-- Objectives header), the scroll frame, and the tracker (objective rows).
local function contentScrollRange()
    if not scrollBody or not scrollContent then
        return 0
    end
    local viewH = scrollBody:GetHeight() or 0
    local contentH = scrollContent:GetHeight() or 0
    local fromSize = 0
    if contentH > viewH then
        fromSize = contentH - viewH
    end
    local fromApi = 0
    if scrollBody.GetVerticalScrollRange then
        fromApi = scrollBody:GetVerticalScrollRange() or 0
    end
    if fromApi < 0 then
        fromApi = 0
    end
    -- SetVerticalScroll is clamped to the API range. Refresh that range once
    -- when the child is taller than the frame and the API still reports 0.
    -- Not on every notch: UpdateScrollChildRect snaps the offset back to the top.
    if fromSize > 1 and fromApi <= 0 and not scrollBody._fluxRangeReady and scrollBody.UpdateScrollChildRect then
        scrollBody._fluxRangeReady = true
        scrollBody:UpdateScrollChildRect()
        if scrollBody.GetVerticalScrollRange then
            fromApi = scrollBody:GetVerticalScrollRange() or 0
        end
        if fromApi < 0 then
            fromApi = 0
        end
    end
    if fromApi > fromSize then
        return fromApi
    end
    return fromSize
end

local function scrollByWheel(_, delta)
    if not scrollBody or not delta or delta == 0 then
        return
    end
    local range = contentScrollRange()
    if range <= 0 then
        return
    end
    local cur = scrollBody:GetVerticalScroll() or 0
    local nextScroll = cur - (delta * WHEEL_STEP)
    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > range then
        nextScroll = range
    end
    if math.abs(nextScroll - cur) > 0.01 then
        scrollBody:SetVerticalScroll(nextScroll)
    end
end

local function bindScrollWheel(frame)
    if not frame or frame._fluxWheelBound then
        return
    end
    frame._fluxWheelBound = true
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", scrollByWheel)
end

function FluxObjectiveTrackerScroll.IsActiveFor(tracker)
    return tracker and tracker.fluxScrollActive == true
end

function FluxObjectiveTrackerScroll:GetQuestTimer(tracker)
    if tracker and tracker.QuestTimerFrame then
        return tracker.QuestTimerFrame
    end
    return _G.QuestTimerFrame
end

function FluxObjectiveTrackerScroll:PinTopModulePadding(tracker)
    -- Do not write topModulePadding: GetAvailableHeight is GetHeight() - padding, so a
    -- Flux number taints Update() before ShouldShowMawBuffs. CollapseModuleTopGap after.
    if not tracker or not tracker.fluxScrollActive then
        return
    end
    self:CollapseModuleTopGap(tracker)
end

function FluxObjectiveTrackerScroll:PinLayoutHeight(tracker)
    -- Scroll viewport and Forever non-scroll dock both need a tall GetHeight so
    -- Forever UpdateTopPadding (38px + timer) does not skip watches. OnSizeChanged
    -- is noped so this SetHeight does not taint the next Blizzard Update.
    if not tracker then
        return
    end
    -- Only while Flux still owns the parent. Edit Mode ApplySystemAnchor on spec/
    -- level reparents to the right manager; pinning 100000px there blows the tracker.
    local scrollDocked = tracker.fluxScrollActive and scrollContent and tracker:GetParent() == scrollContent
    if not scrollDocked then
        return
    end
    tracker.editModeHeight = LAYOUT_HEIGHT
    -- Do not write systemInfo.isInDefaultPosition. InitSystemAnchors reads it on
    -- spec/level; a Flux boolean taints the range → MainActionBar:SetPointBase.
    -- Pin height here (OnSizeChanged nop) so GetAvailableHeight stays tall.
    local h = tracker:GetHeight() or 0
    if h >= LAYOUT_HEIGHT - 1 then
        return
    end
    -- Skip OnSizeChanged → MarkDirty so this SetHeight does not taint the next Update.
    local orig = tracker.OnSizeChanged
    tracker.OnSizeChanged = nop
    pcall(tracker.SetHeight, tracker, LAYOUT_HEIGHT)
    tracker.OnSizeChanged = orig
end

local dockRegenWatch

local function ensureDockRegenWatch()
    if dockRegenWatch then
        return
    end
    dockRegenWatch = CreateFrame("Frame")
    dockRegenWatch:RegisterEvent("PLAYER_REGEN_ENABLED")
    dockRegenWatch:SetScript("OnEvent", function()
        if FluxObjectiveTrackerScroll._dockReassertPending then
            FluxObjectiveTrackerScroll:ReassertDock(ObjectiveTrackerFrame)
        end
    end)
end

-- Edit Mode UpdateSystems → ApplySystemAnchor reparents the tracker into the
-- right manager on spec/level. Put it back on the scroll child only.
-- Do not SortQuestWatches / RecoverStuckDirty / rebuild geometry (level-up).
function FluxObjectiveTrackerScroll:ReassertDock(tracker)
    tracker = tracker or ObjectiveTrackerFrame
    if not tracker or not tracker.fluxInitialized then
        return
    end
    if InCombatLockdown() then
        self._dockReassertPending = true
        ensureDockRegenWatch()
        return
    end
    self._dockReassertPending = false
    local em = _G.EditModeManagerFrame
    if em and em.layoutApplyInProgress then
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                self:ReassertDock(tracker)
            end)
        end
        return
    end
    tracker.ignoreFramePositionManager = true

    if tracker.fluxScrollActive and scrollContent then
        if tracker:GetParent() ~= scrollContent then
            self:EnsureViewport(tracker)
        else
            self:PinLayoutHeight(tracker)
            if not isAnchoredTopRight(tracker, scrollContent) then
                tracker:ClearAllPoints()
                tracker:SetPoint("TOPRIGHT", scrollContent, "TOPRIGHT", 0, 0)
            end
        end
    end
end

function FluxObjectiveTrackerScroll:RecoverStuckDirty(tracker)
    -- Forever Frame:Update can throw after a successful Container:Update. The dirty
    -- callback then never reaches dirty=nil, so later MarkDirty is a no-op.
    if tracker and tracker.dirty then
        tracker.dirty = nil
        return true
    end
    return false
end

-- Forever positions the first module at y=-topModulePadding *after* UpdateTopPadding.
-- Pinning the number is not enough if that method already ran; pull the first visible
-- module up so "All Objectives" sits on the quest list the way retail Flux does.
function FluxObjectiveTrackerScroll:CollapseModuleTopGap(tracker)
    if not tracker or not tracker.fluxScrollActive then
        return
    end
    local modules = tracker.modules
    if type(modules) ~= "table" then
        return
    end
    for i = 1, #modules do
        local module = modules[i]
        local heightUsed = module and module.GetContentsHeight and module:GetContentsHeight() or 0
        if heightUsed > 0 then
            local point, rel, relPoint, _, y = module:GetPoint(1)
            if point == "TOP" and rel == tracker and relPoint == "TOP" and nearlyEq(y, 0) then
                return
            end
            module:SetPoint("TOP", tracker, "TOP", 0, 0)
            module:SetPoint("LEFT", tracker, "LEFT", module.leftMargin or 0, 0)
            return
        end
    end
end

function FluxObjectiveTrackerScroll:AnchorHeader(tracker)
    if not outerViewport or not tracker or not tracker.Header then
        return
    end
    local header = tracker.Header
    local w = outerViewport:GetWidth()
    if header:GetParent() ~= outerViewport then
        header:SetParent(outerViewport)
        if w and w > 0 then
            header:SetWidth(w)
        end
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", outerViewport, "TOPLEFT", 0, 0)
        header:SetPoint("TOPRIGHT", outerViewport, "TOPRIGHT", 0, 0)
        header:SetFrameLevel((outerViewport:GetFrameLevel() or 0) + 2)
        return
    end
    -- Already on the viewport: only touch width. Re-SetPoint on every tab switch
    -- made the "All Objectives" header hitch.
    if w and w > 0 and not nearlyEq(header:GetWidth(), w) then
        header:SetWidth(w)
    end
end

local function applyLiveBlockHighlight(block)
    local colors = OBJECTIVE_TRACKER_COLOR
    if not colors then
        return
    end
    local headerColor, dashColor
    if block.isHighlighted then
        headerColor = colors["HeaderHighlight"]
        dashColor = colors["NormalHighlight"]
    else
        headerColor = colors["Header"]
        dashColor = colors["Normal"]
    end
    if not headerColor or not dashColor then
        return
    end
    if block.HeaderText then
        block.HeaderText:SetTextColor(headerColor.r, headerColor.g, headerColor.b)
        block.HeaderText.colorStyle = headerColor
    end
    local usedLines = block.usedLines
    if not usedLines then
        return
    end
    for _, line in pairs(usedLines) do
        local text = line.Text
        local colorStyle = text and text.colorStyle and text.colorStyle.reverse
        if colorStyle then
            text:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
            text.colorStyle = colorStyle
            if line.Dash then
                line.Dash:SetTextColor(dashColor.r, dashColor.g, dashColor.b)
            end
        end
    end
end

local function wrapMixinPcall(mixin, methodName, flagName)
    if not mixin or type(mixin[methodName]) ~= "function" or mixin[flagName] then
        return
    end
    mixin[flagName] = true
    local orig = mixin[methodName]
    mixin[methodName] = function(self, ...)
        local ok, a, b, c, d = pcall(orig, self, ...)
        if ok then
            return a, b, c, d
        end
    end
end

local function wrapShouldDisplayQuest(mixin)
    if not mixin or type(mixin.ShouldDisplayQuest) ~= "function" or mixin._fluxSafeDisplay then
        return
    end
    mixin._fluxSafeDisplay = true
    local orig = mixin.ShouldDisplayQuest
    function mixin:ShouldDisplayQuest(quest)
        local ok, result = pcall(orig, self, quest)
        if ok then
            return result
        end
        if not quest then
            return false
        end
        local disabled = quest.IsDisabledForSession and quest:IsDisabledForSession()
        return not quest.isTask and not disabled
    end
end

local function wrapBuildQuestWatchInfos(tracker)
    if not tracker or type(tracker.BuildQuestWatchInfos) ~= "function" or tracker._fluxSafeWatchInfos then
        return
    end
    tracker._fluxSafeWatchInfos = true
    local orig = tracker.BuildQuestWatchInfos
    function tracker:BuildQuestWatchInfos()
        local ok, infos = pcall(orig, self)
        if ok and type(infos) == "table" then
            return infos
        end
        local fallback = {}
        local getNum = C_QuestLog and C_QuestLog.GetNumQuestWatches
        local getID = C_QuestLog and C_QuestLog.GetQuestIDForQuestWatchIndex
        if not getNum or not getID or not QuestCache then
            return fallback
        end
        for i = 1, getNum() do
            local questID = getID(i)
            if questID then
                local quest = QuestCache:Get(questID)
                if quest and not quest.isTask then
                    fallback[#fallback + 1] = { quest = quest, index = i }
                end
            end
        end
        return fallback
    end
end

local function wrapLayoutContents(tracker)
    wrapMixinPcall(tracker, "LayoutContents", "_fluxSafeLayoutContents")
end

-- EnumQuestWatchData stops when the callback is falsy. wrapMixinPcall returns nil
-- on error and would drop every remaining watched quest on a cold login throw.
local function wrapUpdateSingle(tracker)
    if not tracker or type(tracker.UpdateSingle) ~= "function" or tracker._fluxSafeUpdateSingle then
        return
    end
    tracker._fluxSafeUpdateSingle = true
    local orig = tracker.UpdateSingle
    function tracker:UpdateSingle(quest)
        local ok, result = pcall(orig, self, quest)
        if ok then
            return result
        end
        return true
    end
end

local function installForeverQuestLayoutGuards()
    -- These replace Blizzard functions. With the gamepad UI on,
    -- ObjectiveTrackerFrame:Update runs them, then SmartNavigation and
    -- FrameControlsManager:FrameHidden, which reach the protected
    -- SetPreferredGamepadInteractTarget(). A Flux wrapper on that stack is
    -- ADDON_ACTION_FORBIDDEN, so skip them there. Never wrap
    -- InputUtil.IsGamepadUIEnabled either.
    if _G.FluxUI_IsForeverGamepadUI and _G.FluxUI_IsForeverGamepadUI() then
        return
    end

    -- Forever colors titles via C_PlayerInfo difficulty; a nil level throws and
    -- aborts the rest of the quest module (live just uses quest.title).
    if type(_G.SetQuestTitleLevelAndDifficultyColor) == "function" and not _G._fluxSafeQuestTitleColor then
        _G._fluxSafeQuestTitleColor = true
        local origTitle = _G.SetQuestTitleLevelAndDifficultyColor
        _G.SetQuestTitleLevelAndDifficultyColor = function(questID, title)
            local ok, result = pcall(origTitle, questID, title)
            if ok and result then
                return result
            end
            return title
        end
    end

    wrapShouldDisplayQuest(QuestObjectiveTracker)
    wrapShouldDisplayQuest(CampaignQuestObjectiveTracker)
    wrapBuildQuestWatchInfos(QuestObjectiveTracker)
    wrapBuildQuestWatchInfos(CampaignQuestObjectiveTracker)
    wrapLayoutContents(QuestObjectiveTracker)
    wrapLayoutContents(CampaignQuestObjectiveTracker)
    wrapUpdateSingle(QuestObjectiveTracker)
    wrapUpdateSingle(CampaignQuestObjectiveTracker)
end

local function installForeverHighlightPatch()
    if not ObjectiveTrackerBlockMixin or not ObjectiveTrackerBlockMixin.UpdateHighlight then
        return
    end
    -- Gamepad SmartNavigation highlights blocks while it selects them; see
    -- installForeverQuestLayoutGuards.
    if _G.FluxUI_IsForeverGamepadUI and _G.FluxUI_IsForeverGamepadUI() then
        return
    end
    if ObjectiveTrackerBlockMixin._fluxForeverHighlight then
        return
    end
    ObjectiveTrackerBlockMixin._fluxForeverHighlight = true
    local origUpdateHighlight = ObjectiveTrackerBlockMixin.UpdateHighlight
    function ObjectiveTrackerBlockMixin:UpdateHighlight()
        -- Forever returns early when poiQuestID is missing (achievements, scenarios, freed blocks),
        -- so hover color never updates. Keep Forever difficulty colors when they work; otherwise
        -- use the live retail header/dash colors.
        if self.poiQuestID then
            local ok = pcall(origUpdateHighlight, self)
            if ok then
                return
            end
        end
        applyLiveBlockHighlight(self)
    end
end

function FluxObjectiveTrackerScroll:DockQuestTimer(tracker)
    if not outerViewport or not tracker or not tracker.fluxScrollActive then
        return
    end
    if not isForeverObjectiveTracker(tracker) then
        return
    end
    local timer = self:GetQuestTimer(tracker)
    if not timer then
        return
    end

    if timer:GetParent() ~= outerViewport then
        timer:SetParent(outerViewport)
    end
    timer:SetFrameStrata(outerViewport:GetFrameStrata() or "LOW")
    timer:SetFrameLevel((outerViewport:GetFrameLevel() or 0) + 3)
    timer.ignoreFramePositionManager = true

    if not timer._fluxDocked then
        timer._fluxDocked = true
        timer:HookScript("OnShow", function()
            local ot = ObjectiveTrackerFrame
            if ot and ot.fluxScrollActive then
                FluxObjectiveTrackerScroll:LayoutScrollArea(ot)
            end
        end)
        timer:HookScript("OnHide", function()
            local ot = ObjectiveTrackerFrame
            if ot and ot.fluxScrollActive then
                FluxObjectiveTrackerScroll:LayoutScrollArea(ot)
            end
        end)
    end

    local headerH = 0
    if tracker.Header and tracker.Header:IsShown() then
        headerH = (tracker.Header:GetHeight() or 32) + HEADER_GAP
    end
    timer:ClearAllPoints()
    timer:SetPoint("TOP", outerViewport, "TOP", 0, -headerH)
end

local function chromeTopOffset(tracker)
    local offset = 0
    if tracker.Header and tracker.Header:IsShown() then
        -- Forever header art can report a tall GetHeight(); the template row is 32px.
        local headerH = tracker.Header:GetHeight() or 32
        if headerH > 40 then
            headerH = 32
        end
        offset = headerH + HEADER_GAP
    end
    local timer = FluxObjectiveTrackerScroll:GetQuestTimer(tracker)
    local timerActive = timer and timer.IsShown and timer:IsShown() and timer:GetParent() == outerViewport
        and (timer.numTimers or 0) > 0
    if timerActive then
        local th = 0
        if timer.GetFrameHeight then
            th = timer:GetFrameHeight() or 0
        end
        if th <= 0 then
            th = timer:GetHeight() or 0
        end
        if th > 0 then
            offset = offset + th + HEADER_GAP
        end
    end
    return offset
end

local function watchQuestTimerLoad()
    if questTimerWatch or not isCamelotClient() then
        return
    end
    questTimerWatch = CreateFrame("Frame")
    questTimerWatch:RegisterEvent("ADDON_LOADED")
    questTimerWatch:SetScript("OnEvent", function(_, _, name)
        if name ~= "Blizzard_QuestTimer" then
            return
        end
        local ot = ObjectiveTrackerFrame
        if ot and ot.fluxScrollActive then
            FluxObjectiveTrackerScroll:DockQuestTimer(ot)
            FluxObjectiveTrackerScroll:LayoutScrollArea(ot)
        end
    end)
end

local function computeStackedContentHeight(frame)
    local modules = frame.modules
    if not modules or #modules == 0 then
        return nil
    end
    local contentsHeight = 0
    local prevModule = nil
    local spacing = frame.moduleSpacing or 10
    local topPad = 0
    if not frame.fluxScrollActive then
        topPad = frame.topModulePadding or 0
    end
    for _, module in ipairs(modules) do
        local heightUsed = module.GetContentsHeight and module:GetContentsHeight() or 0
        if heightUsed > 0 then
            if prevModule then
                contentsHeight = contentsHeight + heightUsed + spacing
            else
                contentsHeight = contentsHeight + heightUsed
            end
            prevModule = module
        end
    end
    if not prevModule then
        return nil
    end
    return topPad + contentsHeight + (frame.bottomModulePadding or 10)
end

function FluxObjectiveTrackerScroll:MeasureContentHeight(frame)
    -- Stacked module heights are in tracker-local pixels. Do not use NineSlice
    -- GetTop/GetBottom: those are screen pixels and shrink by viewport scale (0.75),
    -- which clips quests that already laid out.
    -- Nil means the stack is not ready. Do not fall back to 32: that zeroes the
    -- scroll range while the tall tracker is clipped to the viewport.
    local stacked = computeStackedContentHeight(frame)
    if stacked and stacked > 0 and stacked < LAYOUT_HEIGHT / 2 then
        return stacked
    end
    return nil
end

--- Right-align tracker inside scrollContent (not scrollBody). ScrollFrame moves scrollContent as one
--- piece vertically; tracker TOPRIGHT/content no longer shifts horizontally when SetVerticalScroll runs.
function FluxObjectiveTrackerScroll:AnchorTrackerRightInScroll(tracker)
    if not scrollContent or not tracker then
        return
    end
    local w = outerViewport and outerViewport:GetWidth() or 0
    if not w or w <= 0 then
        w = tracker:GetWidth() or 260
    end
    if not nearlyEq(tracker:GetWidth(), w) then
        tracker:SetWidth(w)
    end
    if not isAnchoredTopRight(tracker, scrollContent) then
        tracker:ClearAllPoints()
        tracker:SetPoint("TOPRIGHT", scrollContent, "TOPRIGHT", 0, 0)
    end
end

function FluxObjectiveTrackerScroll:SizeScrollContent(tracker, contentHeight, allowTall)
    if not scrollContent or not scrollBody or not tracker then
        return false
    end
    -- Stack not ready. Keep the previous scroll-child size so the range does
    -- not collapse. allowTall is only the one-shot expand before Blizzard
    -- lays every module out; the resting height is the module stack.
    if not contentHeight or contentHeight <= 0 then
        return false
    end
    if not allowTall and contentHeight >= LAYOUT_HEIGHT / 2 then
        return false
    end
    local sbW = scrollBody:GetWidth()
    if not sbW or sbW <= 0 then
        local w = outerViewport and outerViewport:GetWidth() or tracker:GetWidth() or 260
        sbW = w + visualBleed(tracker)
    end
    local targetH = math.max(32, contentHeight)
    if nearlyEq(scrollContent:GetWidth(), sbW) and nearlyEq(scrollContent:GetHeight(), targetH) then
        return false
    end
    local v = scrollBody:GetVerticalScroll() or 0
    -- A tall one-shot layout leaves the offset in the empty tail, so the
    -- All Objectives frame looks blank. Start that pass at the top.
    if allowTall then
        v = 0
    end
    scrollContent:SetWidth(sbW)
    scrollContent:SetHeight(targetH)
    scrollBody._fluxRangeReady = nil
    if scrollBody.UpdateScrollChildRect then
        scrollBody:UpdateScrollChildRect()
    end
    local viewH = scrollBody:GetHeight() or 0
    local maxScroll = 0
    if targetH > viewH then
        maxScroll = targetH - viewH
    end
    if v > maxScroll then
        v = maxScroll
    end
    if v > 0 and math.abs((scrollBody:GetVerticalScroll() or 0) - v) > 0.5 then
        scrollBody:SetVerticalScroll(v)
    end
    return true
end

-- UpdateHeight sets the tracker to its parent's height. The parent is the
-- scroll child, so the two heights must match or every right-side layout
-- changes the tracker, MarkDirty fires, and the whole UI reflows.
function FluxObjectiveTrackerScroll:SettleTrackerHeight(tracker, target)
    if not tracker or not target or target >= LAYOUT_HEIGHT / 2 then
        return
    end
    if tracker:GetParent() ~= scrollContent then
        return
    end
    local h = tracker:GetHeight() or 0
    if math.abs(h - target) < 1 then
        return
    end
    local orig = tracker.OnSizeChanged
    tracker.OnSizeChanged = nop
    pcall(tracker.SetHeight, tracker, target)
    tracker.OnSizeChanged = orig
end

local function listIsTruncated(tracker)
    local modules = tracker and tracker.modules
    if type(modules) ~= "table" then
        return false
    end
    for i = 1, #modules do
        local module = modules[i]
        if module and module.IsTruncated and module:IsTruncated() then
            return true
        end
    end
    return false
end

-- Scroll child height 0 makes UpdateHeight crush the tracker. GetAvailableHeight
-- then goes to 0, Blizzard Hide()s the body, and only the reparented
-- "All Objectives" header remains.
function FluxObjectiveTrackerScroll:EnsureVisibleBody(tracker)
    if not tracker or not scrollBody or not scrollContent then
        return
    end
    if tracker:GetParent() ~= scrollContent then
        return
    end
    local viewH = scrollBody:GetHeight() or 0
    if viewH < 32 then
        viewH = 32
    end
    local contentH = scrollContent:GetHeight() or 0
    if contentH < viewH then
        self:SizeScrollContent(tracker, viewH)
    end
    local th = tracker:GetHeight() or 0
    if th < viewH then
        self:SettleTrackerHeight(tracker, viewH)
    end
    if not tracker:IsShown() then
        pcall(tracker.Show, tracker)
    end
end

-- One tall layout so Blizzard builds every block. Not from UpdateHeight:
-- that runs inside RightManagedFrameContainer:Layout.
function FluxObjectiveTrackerScroll:QueueFullLayout(tracker, seenHeight)
    if not tracker or tracker._fluxExpandQueued then
        return
    end
    seenHeight = seenHeight or 0
    if tracker._fluxExpandSeen and seenHeight <= tracker._fluxExpandSeen + 1 then
        return
    end
    tracker._fluxExpandQueued = true
    local function expand()
        tracker._fluxExpandQueued = false
        if not tracker.fluxScrollActive or not scrollContent or tracker:GetParent() ~= scrollContent then
            return
        end
        tracker._fluxExpandSeen = seenHeight
        self:SizeScrollContent(tracker, LAYOUT_HEIGHT, true)
        self:PinLayoutHeight(tracker)
        if C_QuestLog and C_QuestLog.SortQuestWatches then
            pcall(C_QuestLog.SortQuestWatches)
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, expand)
    else
        expand()
    end
end

--- Size header row, optional Forever quest timer, and scroll area below them.
function FluxObjectiveTrackerScroll:LayoutScrollArea(tracker)
    if not outerViewport or not scrollBody or not tracker then
        return
    end
    self:PinTopModulePadding(tracker)
    self:AnchorHeader(tracker)
    self:DockQuestTimer(tracker)
    self:CollapseModuleTopGap(tracker)

    local w = outerViewport:GetWidth()
    local totalH = outerViewport:GetHeight()

    if tracker.Header then
        tracker.Header:SetWidth(w)
    end

    local topOffset = chromeTopOffset(tracker)
    local scrollH = math.max(32, totalH - topOffset)
    -- Wider than outer by the left bleed only; header width/position unchanged.
    -- Forever NineSlice / POI need 40px; live stays 32.
    -- ClearAllPoints on the scroll frame resets the scroll offset, so only
    -- re-anchor when the dock geometry actually changed.
    local bleed = visualBleed(tracker)
    local anchored = scrollBody._fluxLayoutH and nearlyEq(scrollBody._fluxLayoutH, scrollH)
        and nearlyEq(scrollBody._fluxLayoutBleed or -1, bleed)
        and nearlyEq(scrollBody._fluxLayoutW or -1, w)
        and nearlyEq(scrollBody._fluxLayoutTop or -1, topOffset)
    if not anchored then
        local v = scrollBody:GetVerticalScroll() or 0
        scrollBody:ClearAllPoints()
        scrollBody:SetPoint("TOPRIGHT", outerViewport, "TOPRIGHT", 0, -topOffset)
        scrollBody:SetPoint("BOTTOMLEFT", outerViewport, "BOTTOMLEFT", -bleed, 0)
        scrollBody._fluxLayoutH = scrollH
        scrollBody._fluxLayoutBleed = bleed
        scrollBody._fluxLayoutW = w
        scrollBody._fluxLayoutTop = topOffset
        if v > 0 then
            local contentH = scrollContent and scrollContent:GetHeight() or 0
            local maxScroll = 0
            if contentH > scrollH then
                maxScroll = contentH - scrollH
            end
            if v > maxScroll then
                v = maxScroll
            end
            scrollBody:SetVerticalScroll(v)
        end
    end

    if tracker.Header then
        tracker.Header:SetFrameLevel((outerViewport:GetFrameLevel() or 0) + 2)
    end
    scrollBody:SetFrameLevel((outerViewport:GetFrameLevel() or 0) + 1)

    -- Never leave the scroll child at 0. UpdateHeight copies that height onto
    -- the tracker, and a 0-tall tracker hides every objective.
    self:EnsureVisibleBody(tracker)
    self:AnchorTrackerRightInScroll(tracker)
end

-- Flux perf T2.8: ObjectiveTrackerFrame.Update and UpdateHeight can both fire
-- during a single frame (quest accept, objective complete, module toggle), and
-- each fire used to drive a full MeasureContentHeight + SetHeight + scroll
-- resize pass. We now debounce to at most one real sync per frame and
-- short-circuit if the measured content height is unchanged from the last
-- committed value.
function FluxObjectiveTrackerScroll:_DoSyncAfterUpdate(tracker)
    if not self.IsActiveFor(tracker) then
        return
    end
    if not scrollBody or not scrollContent then
        return
    end
    if tracker:GetParent() ~= scrollContent then
        return
    end

    -- Do not LayoutScrollArea or PinLayoutHeight here. Both ran on every
    -- objective Update, ClearAllPoints reset the scroll offset, and forcing
    -- the tracker back to 100000 from inside a right-side layout reflowed
    -- the whole UI every frame.
    local h = self:MeasureContentHeight(tracker)
    local hidden = not tracker:IsShown() or (tracker:GetHeight() or 0) <= (tracker.topModulePadding or 0)
    if listIsTruncated(tracker) or hidden then
        self:QueueFullLayout(tracker, h)
    else
        tracker._fluxExpandSeen = nil
    end
    if not h then
        self:EnsureVisibleBody(tracker)
        return
    end
    local pad = tracker.topModulePadding or 0
    local viewH = scrollBody:GetHeight() or 0
    local target = h + pad
    if viewH > target then
        target = viewH
    end
    if target >= LAYOUT_HEIGHT / 2 then
        self:EnsureVisibleBody(tracker)
        return
    end
    local prevH = tracker._fluxLastSyncedHeight
    if prevH and math.abs(prevH - target) < 0.5 then
        tracker.fluxMeasuredContentHeight = h
        local viewH = scrollBody:GetHeight() or 0
        local maxScroll = 0
        if target > viewH then
            maxScroll = target - viewH
        end
        local v = scrollBody:GetVerticalScroll() or 0
        if v > maxScroll + 0.5 then
            scrollBody:SetVerticalScroll(maxScroll)
        end
        return
    end

    tracker.fluxMeasuredContentHeight = h
    local v = scrollBody:GetVerticalScroll() or 0
    -- First real list, or the body was hidden: show the top of the objectives
    -- instead of whatever offset the tall layout left behind.
    if hidden or not prevH then
        v = 0
    end
    self:SizeScrollContent(tracker, target)
    self:SettleTrackerHeight(tracker, target)
    if not tracker:IsShown() then
        pcall(tracker.Show, tracker)
    end

    local viewH = scrollBody:GetHeight() or 0
    local maxScroll = 0
    if target > viewH then
        maxScroll = target - viewH
    end
    if v > maxScroll then
        v = maxScroll
    end
    if math.abs((scrollBody:GetVerticalScroll() or 0) - v) > 0.5 then
        scrollBody:SetVerticalScroll(v)
    end

    tracker._fluxLastSyncedHeight = target
    tracker._fluxLastSyncedScrollBodyH = viewH
end

function FluxObjectiveTrackerScroll:SyncAfterUpdate(tracker)
    if not tracker then return end
    if tracker._fluxSyncPending then return end
    tracker._fluxSyncPending = true
    if C_Timer and C_Timer.After then
        local self2 = self
        C_Timer.After(0, function()
            tracker._fluxSyncPending = false
            self2:_DoSyncAfterUpdate(tracker)
        end)
    else
        tracker._fluxSyncPending = false
        self:_DoSyncAfterUpdate(tracker)
    end
end

local function installForeverCompatHooks()
    if foreverCompatInstalled then
        return
    end
    if not ObjectiveTrackerFrame or not isForeverObjectiveTracker(ObjectiveTrackerFrame) then
        return
    end
    foreverCompatInstalled = true
    -- pcall-wrap instance methods before hooksecurefunc so a throw cannot drop Flux hooks.
    installForeverQuestLayoutGuards()

    -- hooksecurefunc on the frame instance (mixin hook never fires). After-only:
    -- replacing UpdateTopPadding taints Container.Update before ShouldShowMawBuffs.
    if ObjectiveTrackerFrame.UpdateTopPadding
        and not ObjectiveTrackerFrame._fluxUpdateTopPaddingHooked then
        ObjectiveTrackerFrame._fluxUpdateTopPaddingHooked = true
        hooksecurefunc(ObjectiveTrackerFrame, "UpdateTopPadding", function(self)
            if self and self.fluxScrollActive then
                FluxObjectiveTrackerScroll:CollapseModuleTopGap(self)
            end
        end)
    end

    if ObjectiveTrackerFrame.UpdateHeaderPosition then
        hooksecurefunc(ObjectiveTrackerFrame, "UpdateHeaderPosition", function(self)
            if self and self.fluxScrollActive then
                FluxObjectiveTrackerScroll:AnchorHeader(self)
            end
        end)
    end

    installForeverHighlightPatch()
    watchQuestTimerLoad()
end

-- Tainted MarkDirty schedules ObjectiveTracker Update on the next frame. In combat
-- that Update calls ManageFramePositions, and RightManagedFrameContainer:SetSize is
-- ADDON_ACTION_BLOCKED. securecallfunction still runs Update on this addon stack,
-- so the SetSize stays blocked. Hold the callback until regen.
-- ADDON_ACTION_BLOCKED is an event, so pcall does not swallow it.
local pendingDirtyTrackers
local dirtyRegenFrame

local function flushPendingDirty(retried)
    if InCombatLockdown and InCombatLockdown() then
        if not retried and C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                flushPendingDirty(true)
            end)
        end
        return
    end
    if not pendingDirtyTrackers then
        return
    end
    local list = pendingDirtyTrackers
    pendingDirtyTrackers = nil
    for tracker, orig in pairs(list) do
        if tracker and type(orig) == "function" and tracker.dirtyCallback ~= orig then
            orig()
        end
    end
end

local function deferDirtyUntilRegen(tracker, orig)
    pendingDirtyTrackers = pendingDirtyTrackers or {}
    pendingDirtyTrackers[tracker] = orig
    if dirtyRegenFrame then
        return
    end
    dirtyRegenFrame = CreateFrame("Frame")
    dirtyRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    dirtyRegenFrame:SetScript("OnEvent", flushPendingDirty)
end

local function wrapTrackerDirtyCallback(tracker)
    if not tracker or type(tracker.dirtyCallback) ~= "function" then
        return
    end
    local current = tracker.dirtyCallback
    if current == tracker._fluxSecureDirtyCb then
        return
    end
    -- SetDirtyMethod may replace the callback. Never treat the Flux wrapper as Blizzard's.
    tracker._fluxOrigDirtyCb = current
    local function wrapped()
        local orig = tracker._fluxOrigDirtyCb
        if type(orig) ~= "function" then
            return
        end
        if InCombatLockdown and InCombatLockdown() then
            -- Leave dirty clear so a later MarkDirty can queue again. The real
            -- Update runs once combat ends, off this addon stack.
            tracker.dirty = nil
            deferDirtyUntilRegen(tracker, orig)
            return
        end
        orig()
    end
    tracker._fluxSecureDirtyCb = wrapped
    tracker.dirtyCallback = wrapped
end

local function installSecureCombatDirtyUpdate()
    local tracker = ObjectiveTrackerFrame
    if not tracker or tracker._fluxSecureDirtyHooked then
        return
    end
    tracker._fluxSecureDirtyHooked = true
    wrapTrackerDirtyCallback(tracker)
    if tracker.SetDirtyMethod and hooksecurefunc then
        hooksecurefunc(tracker, "SetDirtyMethod", function(self)
            wrapTrackerDirtyCallback(self)
        end)
    end
end

local function installHooks()
    if hooksInstalled or not ObjectiveTrackerFrame then
        return
    end
    installSecureCombatDirtyUpdate()
    hooksecurefunc(ObjectiveTrackerFrame, "Update", function(self, ...)
        if self.fluxScrollActive then
            FluxObjectiveTrackerScroll:CollapseModuleTopGap(self)
            FluxObjectiveTrackerScroll:SyncAfterUpdate(self)
        end
    end)

    -- Forever Frame:Update can error in the gamepad pass after Container:Update.
    -- Mixin.Update is called directly from that path, so this hook still runs.
    -- Recover dirty even when the ScrollFrame wrap is off (Forever).
    if isForeverObjectiveTracker(ObjectiveTrackerFrame)
        and ObjectiveTrackerContainerMixin and ObjectiveTrackerContainerMixin.Update then
        hooksecurefunc(ObjectiveTrackerContainerMixin, "Update", function(self)
            if not self then
                return
            end
            if isForeverObjectiveTracker(self) then
                local tracker = self
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, function()
                        FluxObjectiveTrackerScroll:RecoverStuckDirty(tracker)
                    end)
                else
                    FluxObjectiveTrackerScroll:RecoverStuckDirty(self)
                end
            end
            if self.fluxScrollActive then
                FluxObjectiveTrackerScroll:CollapseModuleTopGap(self)
                FluxObjectiveTrackerScroll:SyncAfterUpdate(self)
            end
        end)
    end

    hooksecurefunc(ObjectiveTrackerFrame, "UpdateHeight", function(self, ...)
        if not self.fluxScrollActive then
            return
        end
        -- No SetHeight here. UpdateHeight runs inside RightManagedFrameContainer:Layout
        -- for every right-side frame. Pinning 100000 from this hook re-enters that
        -- layout and hitches the whole UI, and the following sync ClearAllPoints
        -- put the scroll offset back to the top. The tracker height is settled to
        -- the scroll child from Update, so this SetHeight does not change size.
    end)

    -- After Edit Mode InitSystemAnchors (untainted). Deferred so we do not run
    -- inside UpdateSystems → MainActionBar:SetPointBase.
    if ObjectiveTrackerFrame.ApplySystemAnchor
        and not ObjectiveTrackerFrame._fluxApplySystemAnchorDockHooked then
        ObjectiveTrackerFrame._fluxApplySystemAnchorDockHooked = true
        hooksecurefunc(ObjectiveTrackerFrame, "ApplySystemAnchor", function(self)
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    FluxObjectiveTrackerScroll:ReassertDock(self)
                end)
            else
                FluxObjectiveTrackerScroll:ReassertDock(self)
            end
        end)
    end

    hooksInstalled = true
    installForeverCompatHooks()
end

local function recoverForeverDirty()
    local ot = ObjectiveTrackerFrame
    if ot and isForeverObjectiveTracker(ot) then
        FluxObjectiveTrackerScroll:RecoverStuckDirty(ot)
    end
end

-- After a stuck Init, QUEST_LOG_UPDATE may already have been ignored. SortQuestWatches
-- is a C API that makes Blizzard fire watch-list events so MarkDirty runs untainted.
local function kickForeverQuestLayout()
    recoverForeverDirty()
    local getNum = C_QuestLog and C_QuestLog.GetNumQuestWatches
    local n = getNum and getNum() or 0
    if n > 0 and C_QuestLog and C_QuestLog.SortQuestWatches then
        pcall(C_QuestLog.SortQuestWatches)
    end
end

local function hookForeverManagerInit()
    if managerInitHooked then
        return
    end
    if not ObjectiveTrackerManager or type(ObjectiveTrackerManager.Init) ~= "function" then
        return
    end
    managerInitHooked = true
    hooksecurefunc(ObjectiveTrackerManager, "Init", function()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                FluxObjectiveTrackerScroll:StartForeverLoginPulse()
                kickForeverQuestLayout()
                if FluxMinimap and FluxMinimap.UpdateQuestTrackerPosition then
                    FluxMinimap:UpdateQuestTrackerPosition()
                end
            end)
        else
            FluxObjectiveTrackerScroll:StartForeverLoginPulse()
            kickForeverQuestLayout()
        end
    end)
end

-- Cold login: Frame:Update / Container:Update can throw before hooksecurefunc runs,
-- leaving DirtiableMixin.dirty set so later QUEST_LOG_UPDATE MarkDirty is a no-op.
-- Clear dirty only. Never call Update / UpdateAll from Flux (MawBuffs taint).
function FluxObjectiveTrackerScroll:StartForeverLoginPulse()
    if loginPulseStarted then
        return
    end
    if not isCamelotClient() and not (ObjectiveTrackerFrame and isForeverObjectiveTracker(ObjectiveTrackerFrame)) then
        return
    end
    loginPulseStarted = true

    if not questLogDirtyWatch then
        questLogDirtyWatch = CreateFrame("Frame")
        questLogDirtyWatch:RegisterEvent("QUEST_LOG_UPDATE")
        questLogDirtyWatch:SetScript("OnEvent", function()
            kickForeverQuestLayout()
        end)
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, kickForeverQuestLayout)
        C_Timer.After(0.25, kickForeverQuestLayout)
        C_Timer.After(0.75, kickForeverQuestLayout)
        C_Timer.After(1.5, kickForeverQuestLayout)
        C_Timer.After(3, kickForeverQuestLayout)
        C_Timer.After(6, kickForeverQuestLayout)
        C_Timer.After(12, function()
            if questLogDirtyWatch then
                questLogDirtyWatch:UnregisterEvent("QUEST_LOG_UPDATE")
            end
        end)
    else
        kickForeverQuestLayout()
    end
end

function FluxObjectiveTrackerScroll:InstallForeverCompat()
    if not ObjectiveTrackerFrame or not isForeverObjectiveTracker(ObjectiveTrackerFrame) then
        return
    end
    installHooks()
    installForeverCompatHooks()
    hookForeverManagerInit()
end

-- Forever Manager:Init → AddContainer → OnAdded sets tracker.init. Reparenting
-- before that, or while height is 0, makes UpdateAll Hide the quest body.
function FluxObjectiveTrackerScroll:ReadyForScrollDock(tracker)
    if not tracker or not isForeverObjectiveTracker(tracker) then
        return true
    end
    if not tracker.init then
        return false
    end
    if (tracker:GetHeight() or 0) <= 0 then
        return false
    end
    return true
end

-- One Blizzard-owned relayout after the first pin. SortQuestWatches marks the
-- tracker dirty from the client, so Flux does not call Update (MawBuffs taint).
-- Not used from UpdateQuestTrackerPosition (tab-switch flicker).
function FluxObjectiveTrackerScroll:KickScrollLayoutOnce()
    if self._scrollLayoutKicked then
        return
    end
    self._scrollLayoutKicked = true
    local function kick()
        if C_QuestLog and C_QuestLog.SortQuestWatches then
            pcall(C_QuestLog.SortQuestWatches)
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, kick)
    else
        kick()
    end
end

--- Outer frame (positioned by FluxMinimap) + fixed header + inner ScrollFrame for body only.
function FluxObjectiveTrackerScroll:EnsureViewport(tracker)
    if not tracker or tracker ~= ObjectiveTrackerFrame then
        return nil
    end
    if not FLUX_API or not FLUX_API.hasBlizzardObjectiveTrackerScroll then
        return nil
    end
    -- Already scrolling: Edit Mode may have reparented us; put the tracker back
    -- even if a later height read is 0. First dock waits for Forever Init.
    if not tracker.fluxScrollActive and not self:ReadyForScrollDock(tracker) then
        return nil
    end

    installHooks()
    installForeverCompatHooks()

    if not outerViewport then
        local outerName = "FluxObjectiveTrackerViewport"
        outerViewport = _G[outerName] or CreateFrame("Frame", outerName, UIParent)
        outerViewport:SetClipsChildren(false)

        scrollBody = CreateFrame("ScrollFrame", "FluxObjectiveTrackerScrollBody", outerViewport, "ScrollFrameTemplate")
        scrollBody:SetClipsChildren(true)
        scrollBody:EnableMouse(true)
        scrollBody:EnableMouseWheel(true)
        if scrollBody.ScrollBar then
            scrollBody.ScrollBar:Hide()
        end

        scrollContent = CreateFrame("Frame", "FluxObjectiveTrackerScrollContent", scrollBody)
        scrollContent:SetClipsChildren(false)

        outerViewport:SetFrameStrata("LOW")
        outerViewport:SetFrameLevel((ObjectiveTrackerFrame:GetFrameLevel() or 0))
    end

    local alreadyDocked = tracker.fluxScrollActive == true
        and scrollContent
        and tracker:GetParent() == scrollContent

    -- Blizzard ObjectiveTrackerContainerHeaderMixin:OnToggle does self:GetParent():ToggleCollapsed().
    -- Header is parented to this outer frame, not ObjectiveTrackerFrame — forward to the real container.
    if not outerViewport._fluxToggleCollapsedForward then
        outerViewport._fluxToggleCollapsedForward = true
        function outerViewport:ToggleCollapsed()
            local ot = ObjectiveTrackerFrame
            if ot and ot.ToggleCollapsed then
                return ot:ToggleCollapsed()
            end
        end
    end

    tracker.fluxScrollActive = true
    tracker.fluxScrollBody = scrollBody
    self:PinLayoutHeight(tracker)

    if scrollBody and not scrollContent then
        scrollContent = CreateFrame("Frame", "FluxObjectiveTrackerScrollContent", scrollBody)
        scrollContent:SetClipsChildren(false)
    end

    -- Header stays on outer frame; body scrolls inside scrollBody only (Questie-style).
    -- Re-assert after Edit Mode, which reparents Header / tracker back to UIParent.
    if tracker.Header then
        if tracker.fluxOriginalTopModulePadding == nil then
            tracker.fluxOriginalTopModulePadding = tracker.topModulePadding
        end
        self:PinTopModulePadding(tracker)
        self:AnchorHeader(tracker)
    end

    if tracker:GetParent() ~= scrollContent then
        tracker:SetParent(scrollContent)
    end
    -- The scroll frame is the clip. The tracker must not clip NineSlice / POI.
    if tracker.SetClipsChildren then
        tracker:SetClipsChildren(false)
    end
    if scrollBody.GetScrollChild and scrollBody:GetScrollChild() ~= scrollContent then
        scrollBody:SetScrollChild(scrollContent)
    elseif not scrollBody.GetScrollChild then
        scrollBody:SetScrollChild(scrollContent)
    end
    self:PinLayoutHeight(tracker)

    -- Scale lives on the viewport. Edit Mode often resets tracker scale to 1 and unparents it.
    if (tracker:GetScale() or 1) ~= 1 then
        tracker:SetScale(1)
    end
    local vs = outerViewport:GetScale() or 1
    if vs > 0.99 or vs < 0.5 then
        outerViewport:SetScale(0.75)
    end

    -- First dock only. Later tab switches must not LayoutScrollArea (header hitch).
    if not alreadyDocked then
        self:LayoutScrollArea(tracker)
        self:KickScrollLayoutOnce()
    else
        self:PinLayoutHeight(tracker)
    end

    bindScrollWheel(outerViewport)
    bindScrollWheel(scrollBody)
    bindScrollWheel(scrollContent)
    bindScrollWheel(tracker)
    if tracker.Header then
        bindScrollWheel(tracker.Header)
    end

    return outerViewport
end

--- Size outer frame and sync inner scroll height under the header.
function FluxObjectiveTrackerScroll:ApplyViewportSize(viewportFrame, tracker, viewportHeight, viewportWidth)
    if not viewportFrame or not tracker then
        return false
    end
    local w = viewportWidth or tracker:GetWidth() or 260
    local wantH = math.max(32, viewportHeight or 100)
    local changed = not nearlyEq(viewportFrame:GetWidth(), w)
        or not nearlyEq(viewportFrame:GetHeight(), wantH)
        or not nearlyEq(tracker:GetWidth(), w)
    if not changed then
        return false
    end
    viewportFrame:SetWidth(w)
    viewportFrame:SetHeight(wantH)

    tracker:SetWidth(w)

    self:LayoutScrollArea(tracker)
    return true
end

function FluxObjectiveTrackerScroll:RefreshLayout(tracker)
    if not self.IsActiveFor(tracker) then
        return
    end
    self:SyncAfterUpdate(tracker)
end

FluxObjectiveTrackerScroll.LAYOUT_HEIGHT = LAYOUT_HEIGHT
_G.FluxObjectiveTrackerScroll = FluxObjectiveTrackerScroll

local function tryInstallForeverCompat()
    FluxObjectiveTrackerScroll:InstallForeverCompat()
end

tryInstallForeverCompat()

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
    EventUtil.ContinueOnAddOnLoaded("Blizzard_ObjectiveTracker", tryInstallForeverCompat)
elseif C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_ObjectiveTracker") then
    tryInstallForeverCompat()
else
    local trackerLoadWatch = CreateFrame("Frame")
    trackerLoadWatch:RegisterEvent("ADDON_LOADED")
    trackerLoadWatch:SetScript("OnEvent", function(self, _, name)
        if name == "Blizzard_ObjectiveTracker" then
            self:UnregisterEvent("ADDON_LOADED")
            tryInstallForeverCompat()
        end
    end)
end
