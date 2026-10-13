--[[
    ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua
    Configuration window for the Consumables button
    
    Features:
    - FluxBorder styling (class-colored border and backdrop)
    - Preset management (create, delete, switch)
    - Drag/drop items anywhere in window to add
    - Drag-reorder icons to change priority
    - Right-click to remove items
    - Cooldown overlay with correct math
    - Stable tooltips (single-pass building)
    
    Compatible with all WoW versions via FluxAPICompat.lua
]]

-- Create namespace
FluxConsumablesConfig = FluxConsumablesConfig or {}
local Config = FluxConsumablesConfig

local function IsChronoboonEnabled()
    local Cons = _G.FluxNCConsumables
    return Cons and Cons.IsChronoboonFeatureEnabled and Cons.IsChronoboonFeatureEnabled()
end

local GridUI = _G.FluxConsumablesGridUI

-- Layout constants
local PADDING = 16
local SECTION_SPACING = 12
local TITLE_HEIGHT = 24
local CONTROL_HEIGHT = 24
local MIN_WIDTH = 340
local BUTTON_HEIGHT = 22
local DROPDOWN_WIDTH = 150
local EDITBOX_WIDTH = 40
local CONTENT_W = 420
local SCROLL_MAX_H = 520
local TOOLBAR_H = CONTROL_HEIGHT * 2 + SECTION_SPACING + 8

-- State
Config._frame = nil
Config._anchorButton = nil
Config._isDragging = false
Config._updateTicker = nil
Config._gridHost = nil
Config._configEventHooked = false
Config._dragGhost = nil

local function EnsureDragGhost()
    if Config._dragGhost then
        return Config._dragGhost
    end
    local ghost = CreateFrame("Frame", nil, UIParent)
    ghost:SetSize(GridUI and GridUI.CELL or 40, GridUI and GridUI.CELL or 40)
    ghost:SetFrameStrata("TOOLTIP")
    ghost:SetFrameLevel(1000)
    ghost:EnableMouse(false)
    ghost:Hide()
    local bg = ghost:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.45)
    local tex = ghost:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 2, -2)
    tex:SetPoint("BOTTOMRIGHT", -2, 2)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    ghost.texture = tex
    Config._dragGhost = ghost
    return ghost
end

function Config.ShowDragGhost(itemID)
    if not itemID then
        return
    end
    local ghost = EnsureDragGhost()
    local icon = (GetItemIcon and GetItemIcon(itemID))
        or (select(10, GetItemInfo(itemID)))
        or "Interface\\Icons\\INV_Misc_QuestionMark"
    ghost.texture:SetTexture(icon)
    ghost.texture:SetVertexColor(1, 1, 1, 0.92)
    ghost:SetScript("OnUpdate", function(self)
        if not Config._isDragging then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            return
        end
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    end)
    ghost:Show()
end

function Config.HideDragGhost()
    local ghost = Config._dragGhost
    if ghost then
        ghost:SetScript("OnUpdate", nil)
        ghost:Hide()
    end
end

-- Timer shim for legacy clients
local Timer = C_Timer or {}
if not Timer.After then
    function Timer.After(delay, cb)
        local f = CreateFrame("Frame")
        local t = 0
        f:SetScript("OnUpdate", function(self, dt)
            t = t + dt
            if t >= (tonumber(delay) or 0) then
                self:SetScript("OnUpdate", nil)
                pcall(cb)
                self:Hide()
            end
        end)
        f:Show()
        return f
    end
end

local function NotifyRestockPanel()
    if _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive()
        and _G.FluxRestockPanel_RequestRefresh then
        pcall(_G.FluxRestockPanel_RequestRefresh)
    end
end

local function EnsureConfigEventHook()
    if Config._configEventHooked then
        return
    end
    Config._configEventHooked = true
    local Respec = _G.FluxRespec
    if Respec and Respec.On then
        Respec.On("CONSUMABLES_CONFIG_CHANGED", function()
            if Config._frame and Config._frame:IsShown() and not Config._isDragging then
                Config.RefreshUI()
            end
        end)
    end
end

local function BuildGridHost(frame)
    if not GridUI then
        return nil
    end
    local host = {
        content = frame.scrollContent,
        width = CONTENT_W,
        dragState = Config,
        allCells = {},
        chronoEnabled = IsChronoboonEnabled,
        showTooltip = Config.ShowIconTooltip,
        onChronoboonEdit = Config.ShowChronoboonRestockEdit,
        onChronoboonFlyout = Config.ShowChronoboonRestockFlyout,
        isDragging = function()
            return Config._isDragging
        end,
    }
    host.onStructureChanged = function()
        Config._isDragging = false
        Config.HideDragGhost()
        Config.RefreshUI()
        if FluxNCConsumables and FluxNCConsumables.ForceUpdate then
            FluxNCConsumables.ForceUpdate()
        end
        NotifyRestockPanel()
    end
    host.onDataChanged = function()
        GridUI.RefreshAllCells(host.allCells)
        if FluxNCConsumables and FluxNCConsumables.ForceUpdate then
            FluxNCConsumables.ForceUpdate()
        end
        NotifyRestockPanel()
    end
    host.consumablesSection = GridUI.CreateSection(
        frame.scrollContent,
        "Consumables",
        "Drop consumables here. Drag to reorder.",
        "consumable",
        {
            dragState = Config,
            onStructureChanged = host.onStructureChanged,
            onAcceptConsumable = function()
                local itemID = GridUI.GetCursorItemID()
                if not itemID then
                    return false
                end
                local Cons = FluxNCConsumables
                if Cons and Cons.IsChronoboonItem and Cons.IsChronoboonItem(itemID) then
                    return false
                end
                ClearCursor()
                Config.AddItem(itemID)
                return true
            end,
        }
    )
    frame._gridHost = host
    Config._gridHost = host
    return host
end

-- ============================================================================
-- FRAME CREATION
-- ============================================================================

local function CreateConfigFrame()
    if Config._frame then return Config._frame end
    
    local frame = CreateFrame("Frame", "FluxConsumablesConfigFrame", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(MIN_WIDTH, 200)  -- Will be resized dynamically
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:Hide()
    
    -- Add to UISpecialFrames so ESC key closes it without blocking other keybinds
    tinsert(UISpecialFrames, frame:GetName())
    
    -- Apply FluxBorder styling
    if FluxBorder and FluxBorder.ApplyTo then
        FluxBorder:ApplyTo(frame, 0, 0, 0, 0)  -- No padding, border covers entire frame
        FluxBorder:SetClassColor(frame, 1, true)
        
        -- Adjust backdrop frame to be same FrameStrata as frame but 1 level lower
        if frame.FluxBorderFrame and frame.FluxBorderFrame.BackgroundFrame then
            local bgFrame = frame.FluxBorderFrame.BackgroundFrame
            bgFrame:SetFrameStrata(frame:GetFrameStrata())
            bgFrame:SetFrameLevel(frame:GetFrameLevel() - 1)
        end
    else
        -- Fallback backdrop - create separate backdrop frame
        local backdropFrame = CreateFrame("Frame", nil, frame)
        backdropFrame:SetFrameStrata(frame:GetFrameStrata())
        backdropFrame:SetFrameLevel(frame:GetFrameLevel() - 1)
        backdropFrame:SetAllPoints(frame)
        backdropFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            tileSize = 0,
            edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        backdropFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        backdropFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        backdropFrame:EnableMouse(false)  -- Don't block mouse events
        frame.backdropFrame = backdropFrame
    end
    
    -- ============================================================================
    -- CLOSE BUTTON (created first so title bar can exclude it)
    -- ============================================================================
    
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        Config.Hide()
    end)
    frame.closeBtn = closeBtn
    
    -- ============================================================================
    -- TITLE BAR (only this region moves the frame - does not overlap close button)
    -- ============================================================================
    
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -4, 0)
    titleBar:SetHeight(PADDING + TITLE_HEIGHT + SECTION_SPACING)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartMoving()
        end
    end)
    titleBar:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            frame:StopMovingOrSizing()
        end
    end)
    frame.titleBar = titleBar
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
    title:SetText("Consumables Configuration")
    frame.title = title

    local toolbarTop = -(PADDING + TITLE_HEIGHT + SECTION_SPACING)

    -- Preset row
    local presetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    presetLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, toolbarTop)
    presetLabel:SetText("Preset:")
    frame.presetLabel = presetLabel

    local presetDropdown = _G.FluxBlizzardDropdown.Create(frame, "FluxConsumablesPresetDropdown", DROPDOWN_WIDTH + 40)
    presetDropdown:SetPoint("LEFT", presetLabel, "RIGHT", 8, 0)
    presetDropdown:FluxSetText("default")
    presetDropdown:FluxSetMenu(function()
        local presetNames = (FluxNCConsumables and FluxNCConsumables.GetPresetNames and FluxNCConsumables.GetPresetNames()) or { "default" }
        local activePreset = (FluxNCConsumables and FluxNCConsumables.GetActivePreset and FluxNCConsumables.GetActivePreset()) or "default"
        local entries = {}
        for _, name in ipairs(presetNames) do
            entries[#entries + 1] = {
                text = name,
                checked = (name == activePreset),
                func = function()
                    if FluxNCConsumables and FluxNCConsumables.SetActivePreset and FluxNCConsumables.SetActivePreset(name) then
                        presetDropdown:FluxSetText(name)
                        Config.RefreshUI()
                        if FluxNCConsumables.ForceUpdate then
                            FluxNCConsumables.ForceUpdate()
                        end
                        NotifyRestockPanel()
                    end
                end,
            }
        end
        return entries
    end)
    frame.presetDropdown = presetDropdown

    local newBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newBtn:SetSize(50, BUTTON_HEIGHT)
    newBtn:SetPoint("LEFT", presetDropdown, "RIGHT", 8, 0)
    newBtn:SetText("New")
    newBtn:SetScript("OnClick", function()
        Config.PromptNewPreset()
    end)
    frame.newBtn = newBtn

    local delBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    delBtn:SetSize(50, BUTTON_HEIGHT)
    delBtn:SetPoint("LEFT", newBtn, "RIGHT", 4, 0)
    delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function()
        Config.ConfirmDeletePreset()
    end)
    frame.delBtn = delBtn

    -- Threshold row
    local thresholdRowY = toolbarTop - (CONTROL_HEIGHT + 6)
    local thresholdLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    thresholdLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, thresholdRowY)
    thresholdLabel:SetText("Refresh threshold:")
    frame.thresholdLabel = thresholdLabel

    local thresholdMinutesBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    thresholdMinutesBox:SetSize(EDITBOX_WIDTH, 20)
    thresholdMinutesBox:SetPoint("LEFT", thresholdLabel, "RIGHT", 8, 0)
    thresholdMinutesBox:SetAutoFocus(false)
    thresholdMinutesBox:SetNumeric(true)
    thresholdMinutesBox:SetMaxLetters(2)
    thresholdMinutesBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        Config.ApplyThresholdChange()
    end)
    thresholdMinutesBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        Config.UpdateThresholdDisplay()
    end)
    thresholdMinutesBox:SetScript("OnTextChanged", function(self)
        local num = tonumber(self:GetText())
        if num and (num < 0 or num > 59) then
            Timer.After(0.01, function()
                Config.UpdateThresholdDisplay()
            end)
        end
    end)
    frame.thresholdMinutesBox = thresholdMinutesBox

    local thresholdMinutesLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    thresholdMinutesLabel:SetPoint("LEFT", thresholdMinutesBox, "RIGHT", 4, 0)
    thresholdMinutesLabel:SetText("min")
    frame.thresholdMinutesLabel = thresholdMinutesLabel

    local thresholdSeparator = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    thresholdSeparator:SetPoint("LEFT", thresholdMinutesLabel, "RIGHT", 4, 0)
    thresholdSeparator:SetText(":")
    frame.thresholdSeparator = thresholdSeparator

    local thresholdSecondsBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    thresholdSecondsBox:SetSize(EDITBOX_WIDTH, 20)
    thresholdSecondsBox:SetPoint("LEFT", thresholdSeparator, "RIGHT", 4, 0)
    thresholdSecondsBox:SetAutoFocus(false)
    thresholdSecondsBox:SetNumeric(true)
    thresholdSecondsBox:SetMaxLetters(2)
    thresholdSecondsBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        Config.ApplyThresholdChange()
    end)
    thresholdSecondsBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        Config.UpdateThresholdDisplay()
    end)
    thresholdSecondsBox:SetScript("OnTextChanged", function(self)
        local num = tonumber(self:GetText())
        if num and (num < 0 or num > 59) then
            Timer.After(0.01, function()
                Config.UpdateThresholdDisplay()
            end)
        end
    end)
    frame.thresholdSecondsBox = thresholdSecondsBox

    local thresholdSecondsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    thresholdSecondsLabel:SetPoint("LEFT", thresholdSecondsBox, "RIGHT", 4, 0)
    thresholdSecondsLabel:SetText("sec")
    frame.thresholdSecondsLabel = thresholdSecondsLabel

    -- Scrollable content (Chronoboon + Consumables sections)
    local scrollTop = thresholdRowY - (CONTROL_HEIGHT + SECTION_SPACING)
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, scrollTop)
    scroll:SetSize(CONTENT_W, SCROLL_MAX_H)
    frame.scroll = scroll

    local scrollContent = CreateFrame("Frame", nil, scroll)
    scrollContent:SetSize(CONTENT_W, SCROLL_MAX_H)
    scroll:SetScrollChild(scrollContent)
    frame.scrollContent = scrollContent

    BuildGridHost(frame)
    EnsureConfigEventHook()

    local function ResizeFrame()
        local host = frame._gridHost
        local contentH = host and host._lastHeight or GridUI.MIN_DROP_H
        local viewportH = math.min(math.max(contentH, GridUI.MIN_DROP_H), SCROLL_MAX_H)
        scroll:SetHeight(viewportH)
        scrollContent:SetHeight(math.max(contentH, viewportH))

        local toolbarWidth = PADDING + 50 + 8 + DROPDOWN_WIDTH + 8 + 50 + 4 + 50 + 8
        local thresholdWidth = PADDING + 120 + 8 + EDITBOX_WIDTH + 4 + 24 + 4 + 8 + 4 + EDITBOX_WIDTH + 4 + 24
        local windowWidth = math.max(MIN_WIDTH, CONTENT_W + PADDING * 2, toolbarWidth, thresholdWidth)
        local titleBarH = PADDING + TITLE_HEIGHT + SECTION_SPACING
        local windowHeight = titleBarH + TOOLBAR_H + viewportH + PADDING
        frame:SetSize(windowWidth, windowHeight)
    end
    frame.ResizeFrame = ResizeFrame

    Config._frame = frame
    return frame
end

-- Chronoboon floating edit (optional overlay; cells also support inline edit)
function Config.ShowChronoboonRestockEdit(btn)
    if not btn or not btn.itemID then return end
    local edit = Config._chronoRestockEdit
    if not edit then
        edit = CreateFrame("EditBox", nil, UIParent, "InputBoxTemplate")
        edit:SetSize(44, 22)
        edit:SetAutoFocus(false)
        edit:SetNumeric(true)
        edit:SetMaxLetters(3)
        edit:SetFontObject("GameFontHighlightSmall")
        edit:Hide()
        local function commit(self)
            local target = math.max(0, math.min(999, math.floor(tonumber(self:GetText()) or 0)))
            if FluxNCConsumables and FluxNCConsumables.SetChronoboonRestockTarget then
                local Cons = FluxNCConsumables
                if Cons.EnsureChronoboonPresetEntry and Cons.GetDefaultChronoboonItemID then
                    local chronoID = (Cons.GetCanonicalChronoboonID and Cons.GetCanonicalChronoboonID())
                        or Cons.GetDefaultChronoboonItemID()
                    if chronoID then
                        Cons.EnsureChronoboonPresetEntry(chronoID)
                    end
                end
                Cons.SetChronoboonRestockTarget(target)
            end
            if _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive()
                and _G.FluxRestockPanel_RequestRefresh then
                pcall(_G.FluxRestockPanel_RequestRefresh)
            end
        end
        edit:SetScript("OnEnterPressed", function(self)
            commit(self)
            self._commit = true
            self:ClearFocus()
            self:Hide()
            Config.UpdateAllItemCounts()
        end)
        edit:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            self:Hide()
        end)
        edit:SetScript("OnEditFocusLost", function(self)
            if not self._commit and self:IsShown() then
                commit(self)
            end
            self._commit = nil
            self:Hide()
            Config.UpdateAllItemCounts()
        end)
        Config._chronoRestockEdit = edit
    end
    edit._commit = nil
    edit:SetParent(btn)
    edit:SetFrameStrata("FULLSCREEN_DIALOG")
    edit:SetFrameLevel(btn:GetFrameLevel() + 30)
    edit:ClearAllPoints()
    edit:SetPoint("BOTTOM", btn, "TOP", 0, 2)
    local target = 0
    if FluxNCConsumables and FluxNCConsumables.GetChronoboonRestockTarget then
        target = FluxNCConsumables.GetChronoboonRestockTarget() or 0
    end
    edit:SetText(tostring(target))
    edit:Show()
    edit:HighlightText()
    edit:SetFocus()
end


-- ============================================================================
-- TOOLTIP
-- ============================================================================

function Config.ShowIconTooltip(btn, itemID)
    if not btn or not itemID then return end
    
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    -- Get item link to show standard item tooltip
    local itemName, itemLink = GetItemInfo(itemID)
    if not itemLink then
        -- Try to construct item link
        itemLink = "item:" .. itemID
    end
    
    -- Show standard WoW item tooltip
    if itemLink then
        GameTooltip:SetHyperlink(itemLink)
    else
        -- Fallback if item link doesn't work
        if itemName then
            GameTooltip:AddLine(itemName, 1, 1, 1)
        else
            GameTooltip:AddLine("Item #" .. itemID, 1, 1, 1)
        end
    end
    
    -- Add separator before our custom info
    GameTooltip:AddLine(" ")
    
    -- Check if this is a Chronoboon item
    local isChronoboon = false
    local isSupercharged = false
    if FluxNCConsumables and FluxNCConsumables.IsChronoboonItem then
        isChronoboon = FluxNCConsumables.IsChronoboonItem(itemID)
        if isChronoboon and FluxNCConsumables.IsSuperchargedChronoboonItem then
            isSupercharged = FluxNCConsumables.IsSuperchargedChronoboonItem(itemID)
        end
    end
    
    if isChronoboon and not isSupercharged then
        -- Regular Chronoboon items: show restock target info
        local count = 0
        if FluxNCConsumables and FluxNCConsumables.GetChronoboonBagCount then
            count = FluxNCConsumables.GetChronoboonBagCount()
        elseif FluxNCConsumables and FluxNCConsumables.GetItemCount then
            count = FluxNCConsumables.GetItemCount(itemID)
        end
        
        local targetCount = 0
        if FluxNCConsumables and FluxNCConsumables.GetChronoboonRestockTarget then
            targetCount = FluxNCConsumables.GetChronoboonRestockTarget()
        end
        
        -- Stock display with color coding
        local stockColor = "|cffffffff"
        if targetCount > 0 then
            if count == 0 then
                stockColor = "|cffff4444"  -- red
            elseif count < targetCount then
                stockColor = "|cffffff00"  -- yellow
            else
                stockColor = "|cff00ff00"  -- green
            end
        end
        GameTooltip:AddLine(stockColor .. "Stock: " .. count .. " / " .. targetCount .. "|r", 1, 1, 1)
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Drag to reorder; drop on left/right half to insert between", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click to set restock target", 0.7, 0.7, 0.7)
    elseif isChronoboon and isSupercharged then
        -- SuperCharged Chronoboon: show count only (no restock target)
        local count = 0
        if FluxNCConsumables and FluxNCConsumables.GetItemCount then
            count = FluxNCConsumables.GetItemCount(itemID)
        end
        
        if count > 0 then
            GameTooltip:AddLine(string.format("In bags: %d", count), 0.5, 1, 0.5)
        else
            GameTooltip:AddLine("In bags: 0", 1, 0.3, 0.3)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Drag to reorder; drop on left/right half to insert between", 0.7, 0.7, 0.7)
    else
        -- Regular items: show buff status and count
        if FluxNCConsumables and FluxNCConsumables.FindBuffForItem then
            local buff = FluxNCConsumables.FindBuffForItem(itemID)
            if buff and buff.expirationTime > 0 then
                local remaining = buff.expirationTime - GetTime()
                if remaining > 0 then
                    local mins = math.floor(remaining / 60)
                    local secs = math.floor(remaining % 60)
                    GameTooltip:AddLine(string.format("Buff remaining: %d:%02d", mins, secs), 0.5, 0.8, 1)
                end
            else
                GameTooltip:AddLine("Buff: Not active", 0.7, 0.7, 0.7)
            end
        end

        -- Ground-placed aura learning status (feasts, cauldrons, etc.)
        local Cons = FluxNCConsumables
        if Cons then
            local binding = Cons.GetGroundAuraBinding and Cons.GetGroundAuraBinding(itemID)
            if binding and binding.spellID then
                local auraName = binding.name
                if not auraName and GetSpellInfo then
                    auraName = GetSpellInfo(binding.spellID)
                end
                if not auraName and C_Spell and C_Spell.GetSpellInfo then
                    local info = C_Spell.GetSpellInfo(binding.spellID)
                    auraName = info and info.name
                end
                GameTooltip:AddLine(
                    string.format("Ground aura: %s", auraName or ("#" .. tostring(binding.spellID))),
                    0.5, 1, 0.8
                )
                GameTooltip:AddLine("Shift-right-click to clear learned aura", 0.7, 0.7, 0.7)
            elseif Cons.IsGroundAuraLearnerArmed and Cons.IsGroundAuraLearnerArmed(itemID) then
                GameTooltip:AddLine("Listening for aura…", 1, 0.85, 0.4)
                GameTooltip:AddLine("Click the placed object to learn its buff", 0.7, 0.7, 0.7)
            elseif Cons.IsGroundPlaceableItem and Cons.IsGroundPlaceableItem(itemID) then
                GameTooltip:AddLine("Place, then click the object to learn its aura", 0.7, 0.85, 1)
            end
        end
        
        -- Count
        local count = 0
        if FluxNCConsumables and FluxNCConsumables.GetItemCount then
            count = FluxNCConsumables.GetItemCount(itemID)
        end
        
        local isWeaponEnchant = FluxNCConsumables and FluxNCConsumables.IsWeaponEnchantItem
            and FluxNCConsumables.IsWeaponEnchantItem(itemID)
        local unitLabel = isWeaponEnchant and "charges" or "in bags"
        if count > 0 then
            GameTooltip:AddLine(string.format("%s: %d", isWeaponEnchant and "Charges" or "In bags", count), 0.5, 1, 0.5)
        else
            GameTooltip:AddLine((isWeaponEnchant and "Charges: 0" or "In bags: 0"), 1, 0.3, 0.3)
        end

        local target = 0
        if FluxNCConsumables and FluxNCConsumables.GetPresetRestockTarget then
            target = FluxNCConsumables.GetPresetRestockTarget(itemID) or 0
        end
        if target > 0 then
            GameTooltip:AddLine(string.format("Restock target: %d %s", target, unitLabel), 0.6, 0.8, 1)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click to set restock target", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag to reorder; drop on left/right half to insert between", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click to remove", 0.7, 0.7, 0.7)
    end
    
    GameTooltip:Show()
end

-- ============================================================================
-- UI REFRESH
-- ============================================================================


function Config.RefreshUI()
    if Config._isDragging then return end
    local frame = Config._frame
    if not frame or not GridUI then return end

    if FluxNCConsumables and FluxNCConsumables.ForceUpdate then
        FluxNCConsumables.ForceUpdate()
    end

    Config.UpdateThresholdDisplay()

    if FluxNCConsumables and FluxNCConsumables.GetActivePreset and frame.presetDropdown then
        local presetName = FluxNCConsumables.GetActivePreset()
        if frame.presetDropdown.FluxSetText then
            frame.presetDropdown:FluxSetText(presetName or "default")
        end
    end

    local host = frame._gridHost
    if host then
        GridUI.RebuildConfigHost(host)
        Config._gridHost = host
    end

    if frame.ResizeFrame then
        frame.ResizeFrame()
    end
end

function Config.UpdateIconCooldown(cell, itemID)
    if GridUI then
        GridUI.UpdateCellCooldown(cell, itemID)
    end
end

function Config.UpdateAllCooldowns()
    local host = Config._gridHost
    if host and GridUI then
        GridUI.UpdateAllCooldowns(host.allCells)
    end
end

function Config.UpdateThresholdDisplay()
    local frame = Config._frame
    if not frame or not frame.thresholdMinutesBox or not frame.thresholdSecondsBox then return end
    
    -- Don't overwrite while user is editing (causes "cannot edit" when RefreshUI fires on BAG_UPDATE etc.)
    if frame.thresholdMinutesBox:HasFocus() or frame.thresholdSecondsBox:HasFocus() then
        return
    end
    
    local totalSeconds = 300  -- Default 5 minutes
    if FluxNCConsumables and FluxNCConsumables.GetRefreshThreshold then
        totalSeconds = FluxNCConsumables.GetRefreshThreshold()
    end
    
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    
    frame.thresholdMinutesBox:SetText(tostring(minutes))
    frame.thresholdSecondsBox:SetText(string.format("%02d", seconds))
end

function Config.ApplyThresholdChange()
    local frame = Config._frame
    if not frame or not frame.thresholdMinutesBox or not frame.thresholdSecondsBox then return end
    
    local minutesText = frame.thresholdMinutesBox:GetText()
    local secondsText = frame.thresholdSecondsBox:GetText()
    
    local minutes = tonumber(minutesText) or 0
    local seconds = tonumber(secondsText) or 0
    
    -- Validate range
    minutes = math.max(0, math.min(59, math.floor(minutes)))
    seconds = math.max(0, math.min(59, math.floor(seconds)))
    
    -- Ensure at least one is > 0 (can't be 0:00)
    if minutes == 0 and seconds == 0 then
        seconds = 1  -- Minimum 1 second
    end
    
    local totalSeconds = minutes * 60 + seconds
    
    if FluxNCConsumables and FluxNCConsumables.SetRefreshThreshold then
        FluxNCConsumables.SetRefreshThreshold(totalSeconds)
        Config.UpdateThresholdDisplay()
        NotifyRestockPanel()
    end
end

function Config.UpdateAllItemCounts()
    local host = Config._gridHost
    if host and GridUI then
        GridUI.RefreshAllCells(host.allCells)
    end
end

-- ============================================================================
-- ITEM HANDLING
-- ============================================================================

function Config.HandleItemDrop()
    if not GetCursorInfo then return end
    
    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" and itemID then
        Config.AddItem(itemID)
        ClearCursor()
    end
end

function Config.AddItem(itemID)
    if not itemID then return end
    
    if FluxNCConsumables and FluxNCConsumables.IsChronoboonItem
        and FluxNCConsumables.IsChronoboonItem(itemID) then
        return
    end
    
    -- Validate it's an actual item
    local itemName = GetItemInfo(itemID)
    if not itemName then
        -- Request item info and try again
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end
        Timer.After(0.5, function()
            if GetItemInfo(itemID) then
                Config.AddItem(itemID)
            end
        end)
        return
    end
    
    -- Add to consumables list
    if FluxNCConsumables and FluxNCConsumables.AddItem then
        local added = FluxNCConsumables.AddItem(itemID)
        if added then
            Config.RefreshUI()
            FluxNCConsumables.ForceUpdate()
            NotifyRestockPanel()
        end
    end
end

-- ============================================================================
-- PRESET MANAGEMENT
-- ============================================================================

-- ShowPresetMenu is no longer needed - using UIDropDownMenu directly

function Config.PromptNewPreset()
    -- Use StaticPopup for name input
    StaticPopupDialogs["FLUX_CONSUMABLES_NEW_PRESET"] = {
        text = "Enter new preset name:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        maxLetters = 32,
        OnAccept = function(self)
            -- self is the popup frame, EditBox is a child frame
            local editBox = self.EditBox
            if editBox then
                local name = editBox:GetText()
                if name and name ~= "" then
                    if FluxNCConsumables and FluxNCConsumables.CreatePreset then
                        local created = FluxNCConsumables.CreatePreset(name)
                        if created then
                            Config.RefreshUI()
                            FluxNCConsumables.ForceUpdate()
                            NotifyRestockPanel()
                        end
                    end
                end
            end
        end,
        OnShow = function(self)
            -- self is the popup frame, EditBox is a child frame
            local editBox = self.EditBox
            if editBox then
                editBox:SetText("")
                editBox:SetFocus()
            end
        end,
        EditBoxOnEnterPressed = function(self)
            -- self is the EditBox itself in this callback
            local name = self:GetText()
            if name and name ~= "" then
                if FluxNCConsumables and FluxNCConsumables.CreatePreset then
                    local created = FluxNCConsumables.CreatePreset(name)
                    if created then
                        Config.RefreshUI()
                        FluxNCConsumables.ForceUpdate()
                        NotifyRestockPanel()
                    end
                end
            end
            local parent = self:GetParent()
            if parent then
                parent:Hide()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
    StaticPopup_Show("FLUX_CONSUMABLES_NEW_PRESET")
end

function Config.ConfirmDeletePreset()
    local activePreset = "default"
    if FluxNCConsumables and FluxNCConsumables.GetActivePreset then
        activePreset = FluxNCConsumables.GetActivePreset()
    end
    
    if activePreset == "default" then
        -- Can't delete default
        StaticPopupDialogs["FLUX_CONSUMABLES_CANT_DELETE"] = {
            text = "Cannot delete the 'default' preset.",
            button1 = "OK",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("FLUX_CONSUMABLES_CANT_DELETE")
        return
    end
    
    StaticPopupDialogs["FLUX_CONSUMABLES_DELETE_PRESET"] = {
        text = "Delete preset '" .. activePreset .. "'?",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function()
            if FluxNCConsumables and FluxNCConsumables.DeletePreset then
                FluxNCConsumables.DeletePreset(activePreset)
                Config.RefreshUI()
                FluxNCConsumables.ForceUpdate()
                NotifyRestockPanel()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
    StaticPopup_Show("FLUX_CONSUMABLES_DELETE_PRESET")
end

-- ============================================================================
-- SHOW/HIDE/TOGGLE
-- ============================================================================

function Config.Show(anchorButton)
    if InCombatLockdown() then
        return
    end
    
    local frame = CreateConfigFrame()
    Config._anchorButton = anchorButton
    
    -- Set button checked state when config opens
    local button = anchorButton or (FluxNCConsumables and FluxNCConsumables._button)
    if button and button.Widget then
        button.Widget:SetChecked(true)
        -- Also update checked state via FluxButton's method if available
        if button.UpdateChecked then
            button:UpdateChecked()
        end
    end
    
    -- Update threshold display when showing
    Config.UpdateThresholdDisplay()
    
    -- Position near anchor button if provided
    if anchorButton and anchorButton.Widget then
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", anchorButton.Widget, "TOPLEFT", 0, 10)
    end
    
    -- Initialize dropdown with current preset
    if frame.presetDropdown then
        local presetName = "default"
        if FluxNCConsumables and FluxNCConsumables.GetActivePreset then
            presetName = FluxNCConsumables.GetActivePreset()
        end
        if frame.presetDropdown.FluxSetText then
            frame.presetDropdown:FluxSetText(presetName)
        end
    end
    
    Config.RefreshUI()
    frame:Show()
    
    -- Initialize SuperCharged buff state tracking for live updates
    if FluxNCConsumables and FluxNCConsumables.HasSuperchargedChronoboonBuff then
        lastSuperchargedBuffState = FluxNCConsumables.HasSuperchargedChronoboonBuff()
    end
    
    -- Start cooldown update ticker
    Config.StartUpdateTicker()
end

-- Show flyout for Chronoboon restock target setting
function Config.ShowChronoboonRestockFlyout(button)
    if not IsChronoboonEnabled() then return end
    if not button or not button.itemID then return end
    if not FluxFlyoutFrame or not FluxFlyoutFrame.ShowFlyout then return end
    
    local itemID = button.itemID
    local itemName = GetItemInfo(itemID) or "Chronoboon Displacer"
    
    local count = 0
    if FluxNCConsumables and FluxNCConsumables.GetItemCount then
        count = FluxNCConsumables.GetItemCount(itemID)
    end
    
    local target = 0
    if FluxNCConsumables and FluxNCConsumables.GetChronoboonRestockTarget then
        target = FluxNCConsumables.GetChronoboonRestockTarget()
    end
    
    local unitPrice = 0
    if FluxRestock and FluxRestock.GetItemUnitPrice then
        local numericID = tonumber(itemID)
        if numericID then
            unitPrice = FluxRestock.GetItemUnitPrice(numericID)
        end
    end
    
    local actions = {
        {
            ["type"] = nil, -- Disable default item usage
            ["item"] = itemName,
            ["$itemId"] = itemID,
            ["$name"] = itemName .. " (" .. (count or 0) .. " / " .. (target or 0) .. ")",
            ["$iconTexture"] = GetItemIcon(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark",
            ["$isReagent"] = true, -- Mark as reagent for special handling
            ["$reagentItemId"] = itemID,
            ["$currentCount"] = count,
            ["$targetCount"] = target,
            ["$itemPrice"] = unitPrice,
        }
    }
    
    FluxFlyoutFrame.ShowFlyout(button, actions, { direction = "UP" })
end

function Config.Hide()
    Config._isDragging = false
    Config._consumableDragFrom = nil
    Config.HideDragGhost()
    if Config._frame then
        Config._frame:Hide()
    end
    
    -- Clear button checked state when config closes
    local button = Config._anchorButton or (FluxNCConsumables and FluxNCConsumables._button)
    if button and button.Widget then
        button.Widget:SetChecked(false)
        -- Also update checked state via FluxButton's method if available
        if button.UpdateChecked then
            button:UpdateChecked()
        end
    end
    
    -- Refresh button when config closes (e.g. after removing weapon enchant from list)
    if FluxNCConsumables and FluxNCConsumables.ForceUpdate then
        FluxNCConsumables.ForceUpdate()
    end
    
    Config.StopUpdateTicker()
end

function Config.Toggle(anchorButton)
    if InCombatLockdown() then
        return
    end
    
    if Config._frame and Config._frame:IsShown() then
        Config.Hide()
    else
        Config.Show(anchorButton)
    end
end

function Config.IsShown()
    return Config._frame and Config._frame:IsShown()
end

-- ============================================================================
-- UPDATE TICKER (for cooldown display while window is open)
-- ============================================================================

-- EVENT-BASED: Updates triggered by events instead of OnUpdate timer
function Config.StartUpdateTicker()
    if Config._updateTicker then return end
    
    -- Create event frame for event-based updates
    local tickerFrame = CreateFrame("Frame")
    Config._updateTicker = tickerFrame
    
    -- Register events for cooldown and item count updates
    tickerFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    tickerFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    
    tickerFrame:SetScript("OnEvent", function(self, event)
        -- Only update if window is shown
        if not Config._frame or not Config._frame:IsShown() then
            Config.StopUpdateTicker()
            return
        end
        
        -- Don't update in combat
        if InCombatLockdown() then return end
        
        -- Update based on event type
        if event == "SPELL_UPDATE_COOLDOWN" then
            if not Config._isDragging then Config.UpdateAllCooldowns() end
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            if not Config._isDragging then Config.UpdateAllCooldowns() end
        end
    end)
end

function Config.StopUpdateTicker()
    if Config._updateTicker then
        Config._updateTicker:UnregisterAllEvents()
        Config._updateTicker:SetScript("OnEvent", nil)
        Config._updateTicker = nil
    end
end

-- ============================================================================
-- COMBAT HANDLING
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
pcall(function() eventFrame:RegisterUnitEvent("UNIT_AURA", "player") end)
-- Track last SuperCharged buff state for live updates
local lastSuperchargedBuffState = nil

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Close config window on combat start
        if Config._frame and Config._frame:IsShown() then
            Config.Hide()
        end
    elseif event == "UNIT_AURA" then
        if arg1 == "player" then
            local S = _G.Flux and _G.Flux.Secrets
            if S and S.AuraUpdateInfoIsNoop and S.AuraUpdateInfoIsNoop(arg2) then
                return
            end
            -- Check if SuperCharged Chronoboon buff state changed
            local currentSuperchargedState = false
            if FluxNCConsumables and FluxNCConsumables.HasSuperchargedChronoboonBuff then
                currentSuperchargedState = FluxNCConsumables.HasSuperchargedChronoboonBuff()
            end
            
            if lastSuperchargedBuffState ~= nil and lastSuperchargedBuffState ~= currentSuperchargedState then
                -- SuperCharged buff state changed - refresh config window if open
                if Config._frame and Config._frame:IsShown() then
                    Config.RefreshUI()
                end
            end
            lastSuperchargedBuffState = currentSuperchargedState
            
            -- Instant update of cooldowns when auras change
            if not Config._isDragging and Config._frame and Config._frame:IsShown() and not InCombatLockdown() then
                Config.UpdateAllCooldowns()
            end
        end
    end
end)

if FluxBagChangeDispatcher and FluxBagChangeDispatcher.RegisterCountListener then
    FluxBagChangeDispatcher.RegisterCountListener("NCConsumablesConfig", function()
        if not Config._frame or not Config._frame:IsShown() or InCombatLockdown() then return end
        if Config._bagUpdateTimer then return end
        Config._bagUpdateTimer = true
        Timer.After(0.25, function()
            Config._bagUpdateTimer = nil
            if Config._isDragging then return end
            if Config._frame and Config._frame:IsShown() and not InCombatLockdown() then
                Config.UpdateAllItemCounts()
                Config.UpdateAllCooldowns()
            end
        end)
    end)
end

-- FluxInv bag updates when BagChangeDispatcher is not loaded
if _G.FluxInv and _G.FluxInv.RegisterListener then
    _G.FluxInv.RegisterListener("FluxConsumablesConfig", function()
        if not Config._frame or not Config._frame:IsShown() or InCombatLockdown() then return end
        if Config._bagUpdateTimer then return end
        Config._bagUpdateTimer = true
        Timer.After(0.25, function()
            Config._bagUpdateTimer = nil
            if Config._isDragging then return end
            if Config._frame and Config._frame:IsShown() and not InCombatLockdown() then
                Config.UpdateAllItemCounts()
                Config.UpdateAllCooldowns()
            end
        end)
    end, { tier = "scan", regions = { "bags" }, deferHeavy = true })
end

-- Export
_G.FluxConsumablesConfig = Config



