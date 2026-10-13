-- FluxQuestie.lua
-- Questie Integration for FluxUI
-- Smart Layout Engine: Final Polish V4
-- Fixes: Highlight/Transparency, Logic Forwarding, Anchoring

local addonName, addonTable = ...
local FluxQuestie = CreateFrame("Frame")
FluxQuestie:RegisterEvent("PLAYER_LOGIN")
FluxQuestie:RegisterEvent("PLAYER_ENTERING_WORLD")

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
FluxQuestie:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1.0, function() self:Initialize() end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2.0, function() self:UpdateLayout() end)
    end
end)

function FluxQuestie:Initialize()
    if not Questie or not QuestieLoader then return end
    
    -- Import Questie Modules
    self.QuestieTracker = QuestieLoader:ImportModule("QuestieTracker")
    self.TrackerLinePool = QuestieLoader:ImportModule("TrackerLinePool")
    self.TrackerBaseFrame = QuestieLoader:ImportModule("TrackerBaseFrame")
    self.QuestieCombatQueue = QuestieLoader:ImportModule("QuestieCombatQueue")
    self.TrackerFadeTicker = QuestieLoader:ImportModule("TrackerFadeTicker")
    self.TrackerQuestFrame = QuestieLoader:ImportModule("TrackerQuestFrame")
    
    if not self.QuestieTracker then return end

    -- Hook Questie's Update to apply our layout POST-UPDATE
    hooksecurefunc(self.QuestieTracker, "Update", function()
        self:UpdateLayout()
    end)
    
    -- Hook TrackerHeaderFrame's expand/collapse button to update layout when minimized/maximized
    -- Use delayed initialization in case headerFrame isn't ready yet
    C_Timer.After(0.5, function()
        local TrackerHeaderFrame = QuestieLoader:ImportModule("TrackerHeaderFrame")
        if TrackerHeaderFrame and TrackerHeaderFrame.headerFrame and TrackerHeaderFrame.headerFrame.trackedQuests then
            local trackedQuests = TrackerHeaderFrame.headerFrame.trackedQuests
            local originalOnClick = trackedQuests:GetScript("OnClick")
            if originalOnClick then
                trackedQuests:SetScript("OnClick", function(button, ...)
                    originalOnClick(button, ...)
                    -- Update layout after expand state changes
                    C_Timer.After(0.1, function()
                        FluxQuestie:UpdateLayout()
                    end)
                end)
            end
        end
    end)
    
    -- Flux perf T2.9: removed the 0.5s polling ticker that watched
    -- Questie.db.char.isTrackerExpanded. Any real state transition (expand /
    -- collapse button click, quest add/remove, quest completion) already
    -- funnels through QuestieTracker:Update, which is hooked above. The
    -- trackedQuests button also wraps OnClick to re-layout after manual
    -- expand/collapse. The ticker added no coverage beyond those hooks but
    -- fired 2x/sec forever, even while the tracker was hidden.
    
    -- Sync with FluxMinimap
    if FluxMinimap then
        local function SafeHook(obj, method, func)
            if obj and obj[method] then hooksecurefunc(obj, method, func) end
        end
        SafeHook(FluxMinimap, "EnforcePosition", function() 
            C_Timer.After(0.1, function() self:UpdateLayout() end)
        end)
        SafeHook(FluxMinimap, "EmbedInFrame", function() 
            -- Use multiple delays to match FluxMinimap's UpdateQuestTrackerPosition timing
            -- This ensures Questie updates after frames are ready (especially on reload)
            C_Timer.After(0.15, function() self:UpdateLayout() end)
            C_Timer.After(0.3, function() self:UpdateLayout() end)
            C_Timer.After(0.5, function() self:UpdateLayout() end)
        end)
        SafeHook(FluxMinimap, "RestoreToNormal", function() 
            -- Use delays to match FluxMinimap's UpdateQuestTrackerPosition timing
            C_Timer.After(0.1, function() self:UpdateLayout() end)
            C_Timer.After(0.2, function() self:UpdateLayout() end)
        end)
        
        if FluxMinimap.RegisterCallback then
            FluxMinimap:RegisterCallback("OnEmbeddingChanged", function() self:UpdateLayout() end)
        end
    end
    
    self:UpdateLayout()
end

-- ----------------------------------------------------------------------------
-- LAYOUT ENGINE
-- ----------------------------------------------------------------------------
function FluxQuestie:UpdateLayout()
    if InCombatLockdown() then return end
    if not self.TrackerBaseFrame or not self.TrackerLinePool then return end
    
    local baseFrame = self.TrackerBaseFrame.baseFrame
    if not baseFrame then return end
    
    -- 1. Enforce Base Frame Size & Position
    local trackerWidth = self:StyleBaseFrame(baseFrame)
    
    -- 2. Size questFrame (and its ScrollFrame) to match baseFrame height
    self:SizeQuestFrame(baseFrame)
    
    -- 3. Style Lines based on Mode
    self:StyleLines(trackerWidth)
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
                local minimapBottom = Minimap:GetBottom() or 0
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

function FluxQuestie:SizeQuestFrame(baseFrame)
    if InCombatLockdown() then return end
    if not self.TrackerQuestFrame then return end
    
    local questFrame = self.TrackerQuestFrame.questFrame
    if not questFrame or not questFrame:IsShown() then return end
    
    -- Only size questFrame when tracker is expanded
    local isMinimized = Questie and Questie.db and Questie.db.char and (not Questie.db.char.isTrackerExpanded)
    if isMinimized then return end
    
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
    local availableHeight = math.max(0, baseHeight - headerHeight - headerSpacing - extraPadding)
    
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
    -- But we should also update ScrollChildFrame width to match
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

