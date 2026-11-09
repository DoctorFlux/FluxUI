-- FluxQuestie.lua
-- Questie Integration for FluxUI
-- Shared Classic / Forever layout. Questie owns quest data and tracker visibility;
-- Flux owns the dock and yields the Blizzard scroll viewport while Questie is enabled.

local addonName, addonTable = ...
local FluxQuestie = CreateFrame("Frame")
addonTable.FluxQuestie = FluxQuestie
FluxQuestie:RegisterEvent("PLAYER_LOGIN")
FluxQuestie:RegisterEvent("PLAYER_ENTERING_WORLD")
FluxQuestie:RegisterEvent("ADDON_LOADED")
FluxQuestie:RegisterEvent("PLAYER_REGEN_ENABLED")

-- ----------------------------------------------------------------------------
-- CONSTANTS & CONFIG
-- ----------------------------------------------------------------------------
local TRACKER_WIDTH = 175 
local PADDING_EDGE = 4
local PADDING_INTERNAL = 4
local BUTTON_SIZE = 14
local INDENT_STEP = 10 

-- ----------------------------------------------------------------------------
-- INITIALIZATION
-- ----------------------------------------------------------------------------
function FluxQuestie:IsTrackerEnabled()
    -- A hidden/collapsed Questie tracker still owns the dock (combat, instances,
    -- pet battles and empty logs). Never use IsShown() to select the tracker.
    return Questie ~= nil and QuestieLoader ~= nil and Questie.db ~= nil
        and Questie.db.profile ~= nil and Questie.db.profile.trackerEnabled == true
end

function FluxQuestie:RequestLayout(delay)
    if self._layoutQueued then return end
    self._layoutQueued = true
    C_Timer.After(delay or 0, function()
        self._layoutQueued = false
        self:Initialize()
        self:UpdateLayout()
    end)
end

FluxQuestie:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_REGEN_ENABLED" then
        if self._layoutPending then self:RequestLayout() end
    elseif event ~= "ADDON_LOADED" or name == "Questie" or name == "Blizzard_ObjectiveTracker"
        or name == "Blizzard_QuestTimer" then
        self:Initialize()
        self:RequestLayout(event == "PLAYER_LOGIN" and 1 or 0)
    end
end)

function FluxQuestie:HookHeader()
    local header = self.TrackerHeaderFrame and self.TrackerHeaderFrame.headerFrame
    local button = header and header.trackedQuests
    if not button or button._fluxLayoutHooked then return end
    button._fluxLayoutHooked = true
    button:HookScript("OnClick", function() self:RequestLayout(0.1) end)
end

function FluxQuestie:Initialize()
    if self.initialized then return end
    if not Questie or not QuestieLoader or type(QuestieLoader.ImportModule) ~= "function" then return end
    
    -- Import Questie Modules
    self.QuestieTracker = QuestieLoader:ImportModule("QuestieTracker")
    self.TrackerLinePool = QuestieLoader:ImportModule("TrackerLinePool")
    self.TrackerBaseFrame = QuestieLoader:ImportModule("TrackerBaseFrame")
    self.QuestieCombatQueue = QuestieLoader:ImportModule("QuestieCombatQueue")
    self.TrackerFadeTicker = QuestieLoader:ImportModule("TrackerFadeTicker")
    self.TrackerQuestFrame = QuestieLoader:ImportModule("TrackerQuestFrame")
    self.TrackerHeaderFrame = QuestieLoader:ImportModule("TrackerHeaderFrame")
    self.QuestieCompat = QuestieLoader:ImportModule("QuestieCompat")
    
    if not self.QuestieTracker or type(self.QuestieTracker.Update) ~= "function"
        or not self.TrackerLinePool or type(self.TrackerLinePool.GetLine) ~= "function"
        or type(self.TrackerLinePool.GetHighestIndex) ~= "function" then return end
    self.initialized = true

    -- Hook Questie's Update to apply our layout POST-UPDATE
    hooksecurefunc(self.QuestieTracker, "Update", function()
        self:UpdateLayout()
    end)
    
    -- Frames are created asynchronously on Forever. Bind the actual header
    -- when it exists, including after later Questie initialization.
    self:HookHeader()
    
    -- Sync with FluxMinimap
    if FluxMinimap then
        local function SafeHook(obj, method, func)
            if obj and obj[method] then hooksecurefunc(obj, method, func) end
        end
        for _, method in ipairs({ "EnforcePosition", "EmbedInFrame", "RestoreToNormal" }) do
            SafeHook(FluxMinimap, method, function() self:RequestLayout(0.1) end)
        end
        
        if FluxMinimap.RegisterCallback then
            FluxMinimap:RegisterCallback("OnEmbeddingChanged", function() self:RequestLayout() end)
        end
    end
    
end

-- ----------------------------------------------------------------------------
-- LAYOUT ENGINE
-- ----------------------------------------------------------------------------
function FluxQuestie:UpdateLayout()
    if InCombatLockdown() then
        self._layoutPending = true
        return
    end
    self._layoutPending = false
    self:Initialize()
    local active = self:IsTrackerEnabled()
    local wasActive = self._trackerActive
    self._trackerActive = active
    if not active then self:ReleaseQuestTimer() end
    if FLUX_API and (FLUX_API.isForever or FLUX_API.isCamelot) and self.QuestieCompat then
        -- Use Questie's own visibility contract so a late Blizzard addon is
        -- suppressed too, and disabling the tracker releases its OnShow guard.
        local method = active and "HideWatchFrame" or (wasActive and "ShowWatchFrame")
        if method and type(self.QuestieCompat[method]) == "function" then
            self.QuestieCompat[method]()
        end
    end
    if FluxObjectiveTrackerScroll and FluxObjectiveTrackerScroll.UpdateQuestieVisibility then
        FluxObjectiveTrackerScroll:UpdateQuestieVisibility()
    end
    if not active then
        if wasActive and FluxMinimap and FluxMinimap.UpdateQuestTrackerPosition then
            FluxMinimap:UpdateQuestTrackerPosition()
        end
        return
    end
    if not self.initialized then return end
    if not self.TrackerBaseFrame or not self.TrackerLinePool then return end
    
    local baseFrame = self.TrackerBaseFrame.baseFrame
    if not baseFrame then return end
    self:HookHeader()
    
    -- 1. Enforce Base Frame Size & Position
    local trackerWidth = self:StyleBaseFrame(baseFrame)
    
    -- 2. Size questFrame (and its ScrollFrame) to match baseFrame height
    self:SizeQuestFrame(baseFrame, self:DockQuestTimer(baseFrame))
    
    -- 3. Style Lines based on Mode
    self:StyleLines(trackerWidth)
    self:UpdateScrollRange()
end

function FluxQuestie:ReleaseQuestTimer()
    local dock = self._questTimerDock
    if not dock then return end
    self._questTimerDock = nil
    dock.frame:SetParent(dock.parent)
    dock.frame:ClearAllPoints()
    for _, point in ipairs(dock.points) do dock.frame:SetPoint(unpack(point)) end
end

function FluxQuestie:DockQuestTimer(baseFrame)
    -- Forever's timer is a child of the hidden native tracker. Preserve Questie's
    -- "Show Blizzard quest timer" option by putting that same timer in our dock.
    if not (FLUX_API and (FLUX_API.isForever or FLUX_API.isCamelot))
        or not Questie.db.profile.showBlizzardQuestTimer then
        self:ReleaseQuestTimer()
        return 0
    end
    local timer = (ObjectiveTrackerFrame and ObjectiveTrackerFrame.QuestTimerFrame) or _G.QuestTimerFrame
    if not timer then return 0 end
    if not self._questTimerDock then
        local points = {}
        for i = 1, timer:GetNumPoints() do points[i] = { timer:GetPoint(i) } end
        self._questTimerDock = { frame = timer, parent = timer:GetParent(), points = points }
    end
    if not timer._fluxQuestieLayoutHooked then
        timer._fluxQuestieLayoutHooked = true
        for _, event in ipairs({ "OnShow", "OnHide", "OnSizeChanged" }) do
            timer:HookScript(event, function() self:RequestLayout() end)
        end
    end
    if timer:GetParent() ~= baseFrame then timer:SetParent(baseFrame) end
    local header = self.TrackerHeaderFrame and self.TrackerHeaderFrame.headerFrame
    local headerHeight = header and header:IsShown() and not Questie.db.profile.moveHeaderToBottom
        and header:GetHeight() or 0
    timer:ClearAllPoints()
    timer:SetPoint("TOPRIGHT", baseFrame, "TOPRIGHT", 0, -headerHeight)
    if timer:IsShown() and (timer.numTimers or 0) > 0 then
        local height = timer.GetFrameHeight and timer:GetFrameHeight() or timer:GetHeight()
        return math.max(0, height) + 4
    end
    return 0
end

function FluxQuestie:UpdateScrollRange()
    local questFrame = self.TrackerQuestFrame and self.TrackerQuestFrame.questFrame
    if not questFrame or not questFrame:IsShown() then return end
    local scroll = questFrame.ScrollFrame
    local child = questFrame.ScrollChildFrame
    if not scroll or not child then return end

    -- Questie measured the old line heights before Flux wrapped the labels.
    -- Recompute overflow so the last wrapped objective remains reachable.
    local height = 0
    for i = 1, self.TrackerLinePool.GetHighestIndex() do
        local line = self.TrackerLinePool.GetLine(i)
        if line and line:IsShown() then height = height + line:GetHeight() end
    end
    child:SetHeight(height + 3)
    if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
    local offset = scroll:GetVerticalScroll() or 0
    local maxScroll = math.max(0, child:GetHeight() - scroll:GetHeight())
    if offset > maxScroll then scroll:SetVerticalScroll(maxScroll) end
end

function FluxQuestie:StyleBaseFrame(baseFrame)
    local width = TRACKER_WIDTH
    
    local scale = baseFrame:GetScale() or 1
    if scale < 0.1 then scale = 1 end
    
    local finalWidth = width / scale
    baseFrame:SetWidth(finalWidth)
    baseFrame:SetClampedToScreen(true)
    
    -- Force Position (RIGID LOCK)
    baseFrame:ClearAllPoints()
    
    local isEmbedded = FluxMinimap and FluxMinimap.IsEmbedded and FluxMinimap:IsEmbedded()
    local isMinimized = Questie and Questie.db and Questie.db.char and (not Questie.db.char.isTrackerExpanded)
    
    if isEmbedded then
        if isMinimized then
            -- Embedded + Minimized: Header is at bottom of baseFrame, anchor BOTTOMRIGHT to TOPRIGHT
            -- This positions the header (at bottom) near the top of screen
            baseFrame:SetPoint("BOTTOMRIGHT", UIParent, "TOPRIGHT", -15, 20)
            
            -- Don't override height - let Questie manage it (it will be just header height)
            -- But ensure it's visible
            if baseFrame:GetHeight() < 20 then
                baseFrame:SetHeight(30) -- Fallback minimum
            end
        else
            -- Embedded + Expanded: Top of Screen
            baseFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -15, 15)
            
            if FluxWindowFrame and FluxWindowFrame.frame then
                -- Use same calculation as UpdateQuestTrackerPosition for consistency
                local screenTop = UIParent:GetTop() or UIParent:GetHeight()
                local windowTop = FluxWindowFrame.frame:GetTop() or 0
                local availableHeight = (screenTop - windowTop) / scale
                baseFrame:SetHeight(math.max(100, availableHeight))
            end
        end
    else
        if isMinimized then
            -- Not Embedded + Minimized: Header is at bottom of baseFrame
            -- Anchor TOPRIGHT to BOTTOMRIGHT of Minimap so tracker appears below minimap
            -- The header (at bottom of baseFrame) will then be positioned below the minimap
            if Minimap then
                baseFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", -15, 10)
            else
                baseFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -15, -185)
            end
            -- Don't override height - let Questie manage it (it will be just header height)
            if baseFrame:GetHeight() < 20 then
                baseFrame:SetHeight(30) -- Fallback minimum
            end
        else
            -- Not Embedded + Expanded: Under Minimap
            if Minimap then
                baseFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", -15, 10)
            else
                baseFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -15, -185)
            end
            
            if FluxWindowFrame and FluxWindowFrame.frame then
                -- Use same calculation as UpdateQuestTrackerPosition for consistency
                local minimapBottom = Minimap and Minimap:GetBottom() or UIParent:GetHeight()
                local windowTop = FluxWindowFrame.frame:GetTop() or 0
                local availableHeight = (minimapBottom - windowTop) / scale
                baseFrame:SetHeight(math.max(100, availableHeight))
            else
                baseFrame:SetHeight(600) -- Fallback if FluxWindowFrame not available
            end
        end
    end
    
    if Questie.db.profile then
        Questie.db.profile.TrackerWidth = finalWidth
    end
    
    return finalWidth
end

function FluxQuestie:SizeQuestFrame(baseFrame, timerHeight)
    if InCombatLockdown() then return end
    if not self.TrackerQuestFrame then return end
    
    local questFrame = self.TrackerQuestFrame.questFrame
    if not questFrame or not questFrame:IsShown() then return end
    
    -- Only size questFrame when tracker is expanded
    local isMinimized = Questie and Questie.db and Questie.db.char and (not Questie.db.char.isTrackerExpanded)
    if isMinimized then return end
    timerHeight = timerHeight or 0

    if (timerHeight > 0 or self._questFrameTimerOffset)
        and type(self.TrackerQuestFrame.PositionTrackedQuestsFrame) == "function" then
        -- Start with Questie's own header-at-top/bottom/headerless anchor each
        -- time, so repeated dock updates cannot accumulate the timer offset.
        questFrame:ClearAllPoints()
        self.TrackerQuestFrame.PositionTrackedQuestsFrame()
        self._questFrameTimerOffset = timerHeight > 0
        if timerHeight > 0 and not Questie.db.profile.moveHeaderToBottom then
            local point, relative, relativePoint, x, y = questFrame:GetPoint(1)
            if point then
                questFrame:ClearAllPoints()
                questFrame:SetPoint(point, relative, relativePoint, x, (y or 0) - timerHeight)
            end
        end
    end
    
    -- Get headerFrame to calculate its height
    local TrackerHeaderFrame = QuestieLoader:ImportModule("TrackerHeaderFrame")
    local headerFrame = TrackerHeaderFrame and TrackerHeaderFrame.headerFrame
    local headerHeight = 0
    local headerSpacing = 0
    
    if headerFrame and headerFrame:IsShown() then
        headerHeight = headerFrame:GetHeight() or 0
        -- Spacing between header and questFrame (4px when header at bottom, 0px when at top)
        headerSpacing = 4
    else
        -- When no header, there's 10px padding from baseFrame edges
        headerSpacing = 10
    end
    
    -- Calculate available height for questFrame
    -- questFrame fills the space between header and opposite edge of baseFrame
    -- Add extra padding to make it slightly shorter
    local baseHeight = baseFrame:GetHeight() or 0
    local extraPadding = 20 -- Additional padding to make questFrame slightly shorter
    -- Add 10px more padding when minimap is embedded
    local isEmbedded = FluxMinimap and FluxMinimap.IsEmbedded and FluxMinimap:IsEmbedded()
    if isEmbedded then
        extraPadding = extraPadding + 15
    end
    local availableHeight = math.max(0, baseHeight - headerHeight - headerSpacing - extraPadding - timerHeight)
    
    -- Set questFrame height to fill available space
    -- Width should match baseFrame width (accounting for scale)
    -- Add 10px extra width to show minimize button
    local scale = baseFrame:GetScale() or 1
    if scale < 0.1 then scale = 1 end
    
    local baseWidth = baseFrame:GetWidth() or TRACKER_WIDTH
    local questFrameWidth = baseWidth + 10 -- Add 10px to show minimize button
    questFrame:SetWidth(questFrameWidth)
    questFrame:SetHeight(availableHeight)
    
    -- ScrollFrame uses SetAllPoints(questFrame), so it will automatically match questFrame size
    -- Match ScrollChildFrame width as well.
    if questFrame.ScrollFrame and questFrame.ScrollChildFrame then
        questFrame.ScrollChildFrame:SetWidth(questFrame.ScrollFrame:GetWidth())
    end
end

function FluxQuestie:StyleLines(trackerWidth)
    local highestIndex = self.TrackerLinePool.GetHighestIndex()
    
    for i = 1, highestIndex do
        local line = self.TrackerLinePool.GetLine(i)
        if line and line:IsShown() then
            -- Set Line Width
            line:SetWidth(trackerWidth)
            
            -- Identify Active Elements based on Mode
            local mode = line.mode
            local label = line.label
            local expandBtn
            local iconBtn
            
            if mode == "zone" then
                expandBtn = line.expandZone
                
                -- PROXY CLICK OVERLAY
                if not line.FluxOverlay then
                    line.FluxOverlay = CreateFrame("Button", nil, line)
                    line.FluxOverlay:SetFrameLevel(line:GetFrameLevel() + 10) 
                    line.FluxOverlay:RegisterForClicks("AnyUp")
                    
                    -- HIGHLIGHT & FADE LOGIC
                    line.FluxOverlay:SetScript("OnEnter", function(self) 
                        if FluxQuestie.TrackerLinePool and FluxQuestie.TrackerLinePool.OnHighlightEnter and expandBtn then
                            -- Pass expandBtn as 'self' to OnHighlightEnter to satisfy parent/zoneId checks
                            FluxQuestie.TrackerLinePool.OnHighlightEnter(expandBtn)
                        end
                        if FluxQuestie.TrackerFadeTicker and FluxQuestie.TrackerFadeTicker.Unfade then
                            FluxQuestie.TrackerFadeTicker.Unfade()
                        end
                    end)
                    
                    line.FluxOverlay:SetScript("OnLeave", function(self) 
                        if FluxQuestie.TrackerLinePool and FluxQuestie.TrackerLinePool.OnHighlightLeave then
                            FluxQuestie.TrackerLinePool.OnHighlightLeave()
                        end
                        if FluxQuestie.TrackerFadeTicker and FluxQuestie.TrackerFadeTicker.Fade then
                            FluxQuestie.TrackerFadeTicker.Fade()
                        end
                    end)
                    
                    -- DIRECT CLICK LOGIC
                    line.FluxOverlay:SetScript("OnClick", function(button, mouseBtn)
                         local zoneId = expandBtn.zoneId
                         if zoneId then
                             if Questie.db.char.collapsedZones[zoneId] == true then
                                 Questie.db.char.collapsedZones[zoneId] = nil
                             else
                                 Questie.db.char.collapsedZones[zoneId] = true
                             end
                             if FluxQuestie.QuestieTracker then
                                 FluxQuestie.QuestieTracker:Update()
                             end
                         else
                             -- Fallback
                             if expandBtn:IsShown() and expandBtn:HasScript("OnMouseUp") then
                                 expandBtn:GetScript("OnMouseUp")(expandBtn, "LeftButton")
                             end
                         end
                    end)
                end
                
                line.FluxOverlay:Show()
                line.FluxOverlay:ClearAllPoints()
                line.FluxOverlay:SetAllPoints(line) 
                
            else
                if line.FluxOverlay then line.FluxOverlay:Hide() end
                
                if mode == "quest" then
                   expandBtn = line.expandQuest
                end
            end
            
            if line.criteriaMark and line.criteriaMark:IsShown() then
                iconBtn = line.criteriaMark
            elseif line.playButton and line.playButton:IsShown() then
                iconBtn = line.playButton
            end
            
            -- ------------------------------------------------------------------
            -- POSITIONING (Right-to-Left Stack)
            -- ------------------------------------------------------------------
            local rightCursor = 0
            
            -- Indentation for objectives
            if mode == "objective" then
                rightCursor = rightCursor + INDENT_STEP
            end
            
            -- 1. Expand Button
            if expandBtn and expandBtn:IsShown() then
                expandBtn:ClearAllPoints()
                expandBtn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
                expandBtn:SetPoint("TOPRIGHT", line, "TOPRIGHT", -rightCursor, -2)
                rightCursor = rightCursor + BUTTON_SIZE + PADDING_INTERNAL
            end
            
            -- 2. Icon Button
            if iconBtn and iconBtn:IsShown() then
                iconBtn:ClearAllPoints()
                iconBtn:SetPoint("TOPRIGHT", line, "TOPRIGHT", -rightCursor, -2)
                local w = iconBtn:GetWidth() or 14
                if w > 20 then w = 14 end
                rightCursor = rightCursor + w + PADDING_INTERNAL
            end
            
            -- 3. Label
            if label then
                label:ClearAllPoints()
                label:SetPoint("TOPRIGHT", line, "TOPRIGHT", -rightCursor, 0)
                label:SetPoint("TOPLEFT", line, "TOPLEFT", PADDING_EDGE, 0)
                
                local availableWidth = trackerWidth - rightCursor - PADDING_EDGE
                if availableWidth > 0 then
                    label:SetWidth(availableWidth)
                end
                
                if mode == "zone" then
                    label:SetJustifyH("LEFT")
                else
                    label:SetJustifyH("RIGHT")
                end
                
                label:SetWordWrap(true)
                if label.SetNonSpaceWrap then label:SetNonSpaceWrap(true) end
                if label.SetMaxLines then label:SetMaxLines(0) end 
                label:SetHeight(0) 
                 
                -- RECALCULATE HEIGHT
                local stringHeight = label:GetStringHeight()
                local minHeight = 14
                
                if expandBtn and expandBtn:IsShown() then 
                    minHeight = math.max(minHeight, BUTTON_SIZE) 
                end
                
                local finalHeight = math.max(minHeight, stringHeight) + PADDING_INTERNAL
                line:SetHeight(finalHeight)
            end
        end
    end
end

