--[[
    ExtraButtonSystem/ExtraButtons/UI.lua
    Main UI frame and FluxWindowFrame integration
    Based on ExtraButtons.lua from old FluxExtraButtonSystem
]]

local addonName, ns = ...
local Flux = ns and ns.Flux
local E = FluxExtraButtons
if not E.UI then E.UI = {} end
local UI = E.UI

-- Counter-scale function to maintain element size when parent is scaled
-- This is exposed on E for use by Categories.lua
function E.ApplyCategoryUIScale(frame)
    if frame and frame.SetScale then
        frame:SetScale(1 / E.EXTRA_BUTTONS_SCALE)
    end
end
local ApplyCategoryUIScale = E.ApplyCategoryUIScale

-- Initialize UI system
function UI:Initialize()
	if not self.mainFrame then
        self:CreateMainFrame()
	end
end

-- Create the main frame structure
function UI:CreateMainFrame()
    -- Main container frame (parented to UIParent, not tab.content - prevents destruction)
		self.mainFrame = CreateFrame("Frame", "FluxExtraButtonsMainFrame", UIParent)
    self.mainFrame:SetFrameStrata("MEDIUM")
    self.mainFrame:SetFrameLevel(5000)
    self.mainFrame:SetClampedToScreen(true)
    self.mainFrame:Hide()
    
    -- Apply scale like old version
    self.mainFrame:SetScale(E.EXTRA_BUTTONS_SCALE)
    
    -- Create scroll frame - will be positioned in AttachTo after we know tab content size
        self.scrollFrame = CreateFrame("ScrollFrame", "FluxExtraButtonsScrollFrame", self.mainFrame, "UIPanelScrollFrameTemplate")
    
    -- 12.0.0+ Secret Value Fix: Prevent scroll updates when values are secret
    local Secrets = Flux and Flux.Secrets
    if Secrets and Secrets.CanAccessValue then
        local function canAccessValue(value)
            if Secrets.IsSecretValue and Secrets.IsSecretValue(value) then
                return false
            end
            local ok, accessible = pcall(Secrets.CanAccessValue, value)
            if ok and accessible == false then
                return false
            end
            return true
        end
        
        -- Cache for last known good scroll values (used when real values are secret)
        local lastKnownScrollRange = 0
        local lastKnownScrollOffset = 0
        
        -- Helper to check if scroll bar min/max values are accessible
        local function canAccessScrollValues(scrollBar)
            if not scrollBar or not scrollBar.GetMinMaxValues then return true end
            local min, max = scrollBar:GetMinMaxValues()
            return canAccessValue(min) and canAccessValue(max)
        end
        
        -- Hook GetVerticalScrollRange to return safe values
        local originalGetVerticalScrollRange = self.scrollFrame.GetVerticalScrollRange
        if originalGetVerticalScrollRange then
            self.scrollFrame.GetVerticalScrollRange = function(scrollFrame)
                local range = originalGetVerticalScrollRange(scrollFrame)
                if not canAccessValue(range) then
                    return lastKnownScrollRange -- Return cached value if secret
                end
                lastKnownScrollRange = range -- Cache good value
                return range
            end
        end
        
        -- Hook GetVerticalScroll to return safe values
        local originalGetVerticalScroll = self.scrollFrame.GetVerticalScroll
        if originalGetVerticalScroll then
            self.scrollFrame.GetVerticalScroll = function(scrollFrame)
                local offset = originalGetVerticalScroll(scrollFrame)
                if not canAccessValue(offset) then
                    return lastKnownScrollOffset -- Return cached value if secret
                end
                lastKnownScrollOffset = offset -- Cache good value
                return offset
            end
        end
        
        -- Hook SetVerticalScroll to prevent updates when values are secret
        local originalSetVerticalScroll = self.scrollFrame.SetVerticalScroll
        self.scrollFrame.SetVerticalScroll = function(scrollFrame, offset)
            -- Check if offset is a secret value
            if not canAccessValue(offset) then
                return -- Offset is secret, skip
            end
            
            -- Check if scroll bar min/max are secret
            if scrollFrame.ScrollBar and not canAccessScrollValues(scrollFrame.ScrollBar) then
                return -- Min/max are secret, skip
            end
            
            -- Also skip during combat lockdown as an extra safety
            if InCombatLockdown() then
                return
            end
            
            lastKnownScrollOffset = offset -- Cache good value
            return originalSetVerticalScroll(scrollFrame, offset)
        end
        
        -- Override OnScrollRangeChanged script to handle secret values
        -- This is called when content size changes and triggers the yrange comparison error
        self.scrollFrame:SetScript("OnScrollRangeChanged", function(scrollFrame, xrange, yrange)
            -- Check if yrange is accessible
            if not canAccessValue(yrange) then
                return -- yrange is secret, skip entirely
            end
            if not canAccessValue(xrange) then
                return -- xrange is secret, skip entirely
            end
            
            -- Cache good values
            lastKnownScrollRange = yrange or 0
            
            -- Only proceed if scroll bar values are accessible
            local scrollBar = scrollFrame.ScrollBar
            if scrollBar and not canAccessScrollValues(scrollBar) then
                return
            end
            
            -- Manually handle scroll range change (simplified version of Blizzard's code)
            if scrollBar then
                local value = scrollBar:GetValue()
                if canAccessValue(value) then
                    -- Safe to update
                    local minVal, maxVal = scrollBar:GetMinMaxValues()
                    if canAccessValue(minVal) and canAccessValue(maxVal) then
                        if yrange > 0 then
                            scrollBar:Show()
                            scrollBar:SetMinMaxValues(0, yrange)
                            if value > yrange then
                                scrollBar:SetValue(yrange)
                            end
                        else
                            scrollBar:Hide()
                            scrollBar:SetMinMaxValues(0, 0)
                            scrollBar:SetValue(0)
                        end
                    end
                end
            end
        end)
        
        -- Hook ScrollBar:SetValue to prevent arithmetic on secret values
        if self.scrollFrame.ScrollBar and self.scrollFrame.ScrollBar.SetValue then
            local scrollBar = self.scrollFrame.ScrollBar
            local originalSetValue = scrollBar.SetValue
            scrollBar.SetValue = function(bar, value)
                if not canAccessValue(value) then
                    return -- Value is secret, skip
                end
                if not canAccessScrollValues(bar) then
                    return -- Min/max are secret, skip
                end
                return originalSetValue(bar, value)
            end
        end
        
        -- Hook scroll bar SetEnabled to filter secret values
        if self.scrollFrame.ScrollBar then
            local scrollBar = self.scrollFrame.ScrollBar
            local originalSetEnabled = scrollBar.SetEnabled
            if originalSetEnabled then
                scrollBar.SetEnabled = function(bar, enabled)
                    if not canAccessValue(enabled) then
                        return -- Value is secret, skip
                    end
                    return originalSetEnabled(bar, enabled)
                end
            end
            
            -- Hook up/down buttons too
            if scrollBar.ScrollUpButton and scrollBar.ScrollUpButton.SetEnabled then
                local originalUpSetEnabled = scrollBar.ScrollUpButton.SetEnabled
                scrollBar.ScrollUpButton.SetEnabled = function(btn, enabled)
                    if not canAccessValue(enabled) then
                        return
                    end
                    return originalUpSetEnabled(btn, enabled)
                end
            end
            if scrollBar.ScrollDownButton and scrollBar.ScrollDownButton.SetEnabled then
                local originalDownSetEnabled = scrollBar.ScrollDownButton.SetEnabled
                scrollBar.ScrollDownButton.SetEnabled = function(btn, enabled)
                    if not canAccessValue(enabled) then
                        return
                    end
                    return originalDownSetEnabled(btn, enabled)
                end
	end
end

        -- Override OnMouseWheel to prevent scroll when values are secret
        self.scrollFrame:SetScript("OnMouseWheel", function(scrollFrame, delta)
            -- Check if we can access scroll values
            local scrollBar = scrollFrame.ScrollBar
            if scrollBar and not canAccessScrollValues(scrollBar) then
                return -- Values are secret, skip scroll
            end
            
            -- Get current scroll position safely
            local currentScroll = scrollFrame:GetVerticalScroll()
            if not canAccessValue(currentScroll) then
                return -- Current scroll is secret, skip
            end
            
            -- Get scroll range safely
            local scrollRange = scrollFrame:GetVerticalScrollRange()
            if not canAccessValue(scrollRange) then
                return -- Range is secret, skip
            end
            
            -- Calculate new scroll position
            local scrollStep = scrollFrame:GetHeight() / 2  -- Half page scroll
            local newScroll
            if delta > 0 then
                newScroll = math.max(0, currentScroll - scrollStep)
            else
                newScroll = math.min(scrollRange, currentScroll + scrollStep)
            end
            
            -- Apply new scroll position
            scrollFrame:SetVerticalScroll(newScroll)
        end)
    end
        
    -- Create content frame
        self.contentFrame = CreateFrame("Frame", "FluxExtraButtonsContentFrame", self.scrollFrame)
    self.contentFrame:SetSize(300, 100)
        self.scrollFrame:SetScrollChild(self.contentFrame)
    
    -- Create control buttons
    self:CreateControlButtons()
    
    -- Create "Add New Category" button
    self:CreateAddCategoryButton()
end

-- Create control buttons (minimize/maximize all)
function UI:CreateControlButtons()
    -- Toggle all button
    self.minAllBtn = CreateFrame("Button", nil, self.mainFrame)
    self.minAllBtn:SetSize(E.CONTROL_BUTTON_WIDTH, E.CONTROL_BUTTON_WIDTH)
    self.minAllBtn:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 4, -4)
    self.minAllBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    self.minAllBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    self.minAllBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end  -- Block during combat
        if E.Categories then
            E.Categories:ToggleAll()
            self:UpdateToggleButtonIcon()
        end
    end)
    self.minAllBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Toggle All Categories")
        GameTooltip:Show()
    end)
    self.minAllBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Apply counter-scaling to maintain button size
    ApplyCategoryUIScale(self.minAllBtn)
end

-- Create "Add New Category" button
-- Note: This button is created here but positioned in RenderCategories 
-- to appear at the bottom of the content, below all categories
function UI:CreateAddCategoryButton()
    self.addCategoryBtn = CreateFrame("Button", nil, self.contentFrame, "UIPanelButtonTemplate")
    self.addCategoryBtn:SetSize(180, 28)  -- Bigger button
    -- Position will be set dynamically in UpdateAddCategoryButtonPosition
    self.addCategoryBtn:SetText("Add New Category")
    self.addCategoryBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end  -- Block during combat
        self:ShowNewCategoryDialog()
    end)
    
    -- Apply counter-scaling to maintain button size
    ApplyCategoryUIScale(self.addCategoryBtn)
end

-- Update Add Category button position (called after RenderCategories)
-- lastCategoryFrame: The frame of the last category (nil if no categories)
function UI:UpdateAddCategoryButtonPosition(yOffset, lastCategoryFrame)
    if not self.addCategoryBtn then return end
    
    self.addCategoryBtn:ClearAllPoints()
    
    if lastCategoryFrame then
        -- Position directly below last category with minimal spacing
        self.addCategoryBtn:SetPoint("TOPLEFT", lastCategoryFrame, "BOTTOMLEFT", 0, -4)
    else
        -- No categories yet, position at top
        self.addCategoryBtn:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", 10, -E.WINDOW_PADDING_VERTICAL)
    end
end

-- Update toggle button icon based on category states
function UI:UpdateToggleButtonIcon()
    if not self.minAllBtn then return end
    
    local allCats = E:GetAllCategoriesInOrder()
    local anyExpanded = false
    
    for _, cat in ipairs(allCats) do
        if not cat.isCollapsed then
            anyExpanded = true
            break
        end
    end
    
    if anyExpanded then
        self.minAllBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    else
        self.minAllBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    end
end

-- Show new category dialog
function UI:ShowNewCategoryDialog()
    if not self.newCategoryDialog then
        self:CreateNewCategoryDialog()
    end
    
    -- Position dialog relative to Add Category button
    if self.addCategoryBtn then
        local dialog = self.newCategoryDialog
        local dialogWidth = dialog:GetWidth() or 240
        local dialogHeight = dialog:GetHeight() or 160
        
        -- Get button position
        local buttonLeft = self.addCategoryBtn:GetLeft()
        local buttonRight = self.addCategoryBtn:GetRight()
        local buttonBottom = self.addCategoryBtn:GetBottom()
        local buttonTop = self.addCategoryBtn:GetTop()
        
        -- Get screen dimensions
        local screenWidth = UIParent:GetWidth()
        local screenHeight = UIParent:GetHeight()
        
        dialog:ClearAllPoints()
        
        -- Try positioning below button first (TOPLEFT of dialog to BOTTOMLEFT of button)
        local preferredX = buttonLeft or 0
        local preferredY = (buttonBottom or 0) - 2
        
        -- Check if dialog would go off right edge
        if preferredX + dialogWidth > screenWidth then
            -- Align to button's right edge instead
            preferredX = (buttonRight or 0) - dialogWidth
            -- If still off screen, align to right edge of screen
            if preferredX < 0 then
                preferredX = screenWidth - dialogWidth - 10
            end
        end
        
        -- Check if dialog would go off bottom edge
        if preferredY - dialogHeight < 0 then
            -- Show above button instead (BOTTOMLEFT of dialog to TOPLEFT of button)
            preferredY = (buttonTop or 0) + 2
            dialog:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", preferredX, preferredY)
        else
            -- Show below button
            dialog:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", preferredX, preferredY)
        end
        
        -- Check if dialog would go off left edge
        if preferredX < 0 then
            preferredX = 10
            dialog:ClearAllPoints()
            if preferredY - dialogHeight < 0 then
                dialog:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", preferredX, preferredY)
            else
                dialog:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", preferredX, preferredY)
            end
        end
    end
    
    self.newCategoryDialog:Show()
    self.newCategoryNameEditBox:SetText("")
    self.newCategoryNameEditBox:SetFocus()
    self.selectedScope = "character"
end

-- Create new category dialog
function UI:CreateNewCategoryDialog()
    local dialog = CreateFrame("Frame", "FluxExtraButtonsNewCategoryDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(200, 130)  -- Narrower, increased height to fit buttons
    -- Position will be set dynamically in ShowNewCategoryDialog
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetToplevel(true)
    dialog:SetClampedToScreen(true)
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    dialog:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    dialog:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    dialog:Hide()
    
    -- Title
    local title = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -12)
    title:SetText("Add New Category")
    
    -- Name label (compact spacing from title)
    local nameLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, -38)
    nameLabel:SetText("Category Name:")
    
    -- Name edit box (compact spacing from label)
    local nameEditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    nameEditBox:SetSize(160, 20)  -- Narrower to match dialog width
    nameEditBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -4)
    nameEditBox:SetMaxLetters(64)
    nameEditBox:SetAutoFocus(false)
    self.newCategoryNameEditBox = nameEditBox
    
    -- Scope label (moved up, compact spacing from edit box, on same line as dropdown)
    local scopeLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    scopeLabel:SetPoint("TOPLEFT", nameEditBox, "BOTTOMLEFT", 0, -6)  -- Moved up (was -8)
    scopeLabel:SetText("Scope:")
    
    -- Scope dropdown (on same line as label, closer to label, resized)
    local ui = self
    local scopeLabels = { character = "Character", class = "Class", realm = "Realm", account = "Account" }
    local scopeDropdown = _G.FluxBlizzardDropdown.Create(dialog, nil, 140)
    scopeDropdown:SetPoint("LEFT", scopeLabel, "RIGHT", 8, 0)
    ui.selectedScope = "character"
    scopeDropdown:FluxSetMenu(function()
        local scopes = { "character", "class", "realm", "account" }
        local entries = {}
        for _, scope in ipairs(scopes) do
            entries[#entries + 1] = {
                text = scopeLabels[scope],
                checked = (scope == ui.selectedScope),
                func = function()
                    ui.selectedScope = scope
                    scopeDropdown:FluxSetText(scopeLabels[scope])
                end,
            }
        end
        return entries
    end)
    scopeDropdown:FluxSetText(scopeLabels.character)
    self.scopeDropdown = scopeDropdown
    
    -- OK button (positioned below scope dropdown, inside dialog bounds)
    local okBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    okBtn:SetSize(70, 22)
    okBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -15, 15)  -- Inside dialog, right-aligned
    okBtn:SetText("OK")
    okBtn:SetScript("OnClick", function()
        local name = nameEditBox:GetText():gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then name = "New Category" end
        local scope = self.selectedScope or "character"
        if E.Categories then
            E.Categories:CreateCategory(name, scope)
        end
        dialog:Hide()
    end)
    
    -- Cancel button (positioned next to OK button)
    local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelBtn:SetSize(70, 22)
    cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -8, 0)  -- Compact spacing between buttons
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    -- Enter key handler
    nameEditBox:SetScript("OnEnterPressed", function()
        okBtn:Click()
    end)
    nameEditBox:SetScript("OnEscapePressed", function()
        dialog:Hide()
    end)
    
    -- OnShow handler
    dialog:SetScript("OnShow", function()
        nameEditBox:SetText("New Category")
        nameEditBox:HighlightText()
        nameEditBox:SetFocus()
        self.selectedScope = "character"
        if scopeDropdown.FluxSetText then
            scopeDropdown:FluxSetText("Character")
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
    
    -- OnHide handler
    dialog:SetScript("OnHide", function()
        nameEditBox:SetText("")
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end)
    
    self.newCategoryDialog = dialog
    
    -- Apply counter-scaling to dialog
    ApplyCategoryUIScale(dialog)
end


-- Attach UI to a parent frame (for FluxWindowFrame integration)
-- Like old ExtraButtons.lua: dock to the border frame (FluxWindowFrame), 
-- bind visibility to the buttons tab container (parentFrame/tab.content)
function UI:AttachTo(parentFrame)
    -- Store tab content reference for visibility binding
    self.tabContentRef = parentFrame
    
    -- Create mainFrame if not exists (safe in combat)
    if not self.mainFrame then
        self:Initialize()
    end
    
    -- Get hierarchy: tab.content -> windowFrame.Content -> FluxWindowFrame (border)
    local windowContent = parentFrame:GetParent()  -- windowFrame.Content
    local windowFrame = windowContent and windowContent:GetParent()  -- FluxWindowFrame (the border)
    
    -- Store references
    self.windowContentRef = windowContent
    self.windowFrameRef = windowFrame
    
    -- Parent to UIParent (prevents CleanupTabContent from destroying it) - safe in combat
    self.mainFrame:SetParent(UIParent)
    
    -- Position mainFrame to fill FluxWindowFrame (the border), like old version
    -- Old version: SetPoint("TOPLEFT", border, "TOPLEFT", -2, 0)
    -- Old version: SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -4, 4)
    -- Check for combat before positioning operations
    local inCombat = InCombatLockdown()
    
    if not inCombat then
        -- Not in combat, do positioning immediately
        self.mainFrame:ClearAllPoints()
        if windowFrame then
            -- Dock to the border frame (FluxWindowFrame) like old version
            self.mainFrame:SetPoint("TOPLEFT", windowFrame, "TOPLEFT", -2, 0)
            self.mainFrame:SetPoint("BOTTOMRIGHT", windowFrame, "BOTTOMRIGHT", -4, 4)
        elseif windowContent then
            -- Fallback to windowContent if windowFrame not found
            self.mainFrame:SetAllPoints(windowContent)
        else
            -- Last fallback to parentFrame
            self.mainFrame:SetAllPoints(parentFrame)
        end
    else
        -- In combat, queue positioning for after combat
        if not self._positionQueue then
            self._positionQueue = {}
            -- Register for combat end
            local combatFrame = CreateFrame("Frame")
            combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            combatFrame:SetScript("OnEvent", function(self, event)
                if event == "PLAYER_REGEN_ENABLED" then
                    -- Process queued positioning
                    if UI._positionQueue and #UI._positionQueue > 0 then
                        for _, queuedOp in ipairs(UI._positionQueue) do
                            if queuedOp.type == "attach" and UI.mainFrame then
                                UI.mainFrame:ClearAllPoints()
                                if queuedOp.windowFrame then
                                    UI.mainFrame:SetPoint("TOPLEFT", queuedOp.windowFrame, "TOPLEFT", -2, 0)
                                    UI.mainFrame:SetPoint("BOTTOMRIGHT", queuedOp.windowFrame, "BOTTOMRIGHT", -4, 4)
                                elseif queuedOp.windowContent then
                                    UI.mainFrame:SetAllPoints(queuedOp.windowContent)
                                elseif queuedOp.parentFrame then
                                    UI.mainFrame:SetAllPoints(queuedOp.parentFrame)
                                end
                            end
                        end
                        table.wipe(UI._positionQueue)
                    end
                    self:UnregisterAllEvents()
                end
            end)
        end
        
        -- Queue positioning operation
        table.insert(self._positionQueue, {
            type = "attach",
            windowFrame = windowFrame,
            windowContent = windowContent,
            parentFrame = parentFrame
        })
    end
    
    -- Apply scale like old version
    self.mainFrame:SetScale(E.EXTRA_BUTTONS_SCALE)
    
    -- Position minimize button at top-left of mainFrame (like old version)
    -- Old version: SetPoint("TOPLEFT", mainFrame_ref, "TOPLEFT", CONTROL_AREA_PADDING_X + CATEGORIES_HORIZONTAL_OFFSET + 10, -CONTROL_AREA_PADDING_Y - 2)
    if self.minAllBtn then
        self.minAllBtn:ClearAllPoints()
        self.minAllBtn:SetParent(self.mainFrame)  -- Parent to mainFrame
        self.minAllBtn:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 5, -2)
    end
    
    -- Position scroll frame relative to minAllBtn (like old version)
    -- Old version: SetPoint("TOPLEFT", minAllBtn_ref, "TOPRIGHT", CONTROL_AREA_PADDING_X - 12, 0)
    -- Old version: SetPoint("BOTTOMRIGHT", mainFrame_ref, "BOTTOMRIGHT", -(CONTROL_AREA_PADDING_X + 20), CONTROL_AREA_PADDING_Y)
    self.scrollFrame:ClearAllPoints()
    if self.minAllBtn then
        self.scrollFrame:SetPoint("TOPLEFT", self.minAllBtn, "TOPRIGHT", -12, 0)
    else
        self.scrollFrame:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 0, 0)
    end
    self.scrollFrame:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", -20, 0)
    
    -- Update content frame width immediately (no delay)
    if self.scrollFrame and self.contentFrame then
        local width = self.scrollFrame:GetWidth() or 300
        self.contentFrame:SetWidth(width)
        self.contentFrame:SetPoint("TOPLEFT")
        
        -- Use watcher if width is not ready yet (rare case)
        if width <= 0 then
            local widthWatcher = CreateFrame("Frame")
            local widthCheckCount = 0
            local scrollFrameRef = self.scrollFrame
            local contentFrameRef = self.contentFrame
            widthWatcher:SetScript("OnUpdate", function(watcher, elapsed)
                widthCheckCount = widthCheckCount + 1
                if scrollFrameRef and contentFrameRef then
                    local newWidth = scrollFrameRef:GetWidth() or 300
                    if newWidth > 0 then
                        contentFrameRef:SetWidth(newWidth)
                        contentFrameRef:SetPoint("TOPLEFT")
                        watcher:SetScript("OnUpdate", nil)
                    end
                end
                if widthCheckCount >= 5 then
                    watcher:SetScript("OnUpdate", nil)
                end
            end)
        end
    end
    
    -- Visibility is now controlled by FluxWindowFrame.lua's tab onShow/onHide callbacks
    -- (HookScript was unreliable because CleanupTabContent clears scripts)
    -- Set initial visibility based on tab.content state
    if parentFrame:IsShown() then
        self.mainFrame:Show()
        if self.minAllBtn then self.minAllBtn:Show() end
    else
        self.mainFrame:Hide()
    end
    
    -- Refresh categories
    if E.Categories then
        E.Categories:RefreshCategories()
    end
    
    -- Update toggle button icon
    self:UpdateToggleButtonIcon()
end

-- Update mainFrame position (called when window resizes, etc.)
function UI:UpdatePosition()
    if not self.tabContentRef or not self.mainFrame then return end
    
    -- Get hierarchy references
    local windowContent = self.tabContentRef:GetParent()
    local windowFrame = windowContent and windowContent:GetParent()
    
    -- Reposition mainFrame to fill FluxWindowFrame
    self.mainFrame:ClearAllPoints()
    if windowFrame then
        self.mainFrame:SetPoint("TOPLEFT", windowFrame, "TOPLEFT", -2, 0)
        self.mainFrame:SetPoint("BOTTOMRIGHT", windowFrame, "BOTTOMRIGHT", -4, 4)
    elseif windowContent then
        self.mainFrame:SetAllPoints(windowContent)
    else
        self.mainFrame:SetAllPoints(self.tabContentRef)
    end
end

-- SetupInTab alias for backwards compatibility
function UI:SetupInTab(tabContentFrame)
    self:AttachTo(tabContentFrame)
end

-- Show the UI
function UI:Show()
    if self.mainFrame then
        self.mainFrame:Show()
        -- Also show minAllBtn
        if self.minAllBtn then self.minAllBtn:Show() end
        -- Refresh layout after showing
        C_Timer.After(0.1, function()
    if E.Categories then
                E.Categories:RefreshCategories()
            end
        end)
    end
end

-- Hide the UI
function UI:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

-- Export
E.UI = UI

-- Event frame for initialization (instant setup)
local eventFrame = CreateFrame("Frame")
local initialized = false
local watcherFrame = CreateFrame("Frame")
local checkCount = 0
local MAX_CHECKS = 30

local function TryInitialize(force)
    if initialized then return true end
    
    -- Check if dependencies are ready
    local isReady = true -- Can initialize without delays
    
    -- If forcing or ready, initialize immediately
    if force or isReady then
        if FluxExtraButtons and FluxExtraButtons.Initialize then
            FluxExtraButtons:Initialize()
            initialized = true
            return true
        end
    end
    
    return false
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "_FluxUI" then
        -- Try immediately first (will initialize if ready)
        if TryInitialize(false) then
            return
        end
        
        -- If not initialized, watch every frame until ready
        checkCount = 0
        watcherFrame:SetScript("OnUpdate", function(self, elapsed)
            checkCount = checkCount + 1
            if TryInitialize(false) or checkCount >= MAX_CHECKS then
                -- If we hit the limit, force initialization
                if checkCount >= MAX_CHECKS and not initialized then
                    TryInitialize(true)
                end
                self:SetScript("OnUpdate", nil)
            end
        end)
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Try to initialize if not already done
        if not initialized then
            if TryInitialize(false) then
                return
            end
            
            -- If not initialized, watch every frame until ready
            checkCount = 0
            watcherFrame:SetScript("OnUpdate", function(self, elapsed)
                checkCount = checkCount + 1
                if TryInitialize(false) or checkCount >= MAX_CHECKS then
                    -- If we hit the limit, force initialization
                    if checkCount >= MAX_CHECKS and not initialized then
                        TryInitialize(true)
                    end
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end
        
        -- Refresh categories immediately (no delay)
        if initialized and FluxExtraButtons and FluxExtraButtons.Categories then
            FluxExtraButtons.Categories:RefreshCategories()
        end
    end
end)


