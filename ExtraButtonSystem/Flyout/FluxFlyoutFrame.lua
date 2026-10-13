-- FluxFlyoutFrame.lua
-- Flyout UI frame and buttons for custom flyout system
-- Supports all WoW clients: Retail, Classic, Legacy
local addonName, ns = ...

local FluxFlyoutFrame = {}
_G.FluxFlyoutFrame = FluxFlyoutFrame

-- ---------------------------------------------------------------------------
-- CONSTANTS
-- ---------------------------------------------------------------------------

local BUTTON_SIZE = 32
local BUTTON_SPACING = 4
local BORDER_PADDING = 6
local MAX_BUTTONS = 30

-- Inter-button offset (same anchor chain as LayoutFlyoutButtons). Negative = tighter stack / slight overlap.
local FLYOUT_INTER_BUTTON_GAP = -2
-- Inset from flyout inner edge on the side nearest the parent trigger (first button).
local FLYOUT_INITIAL_SPACING = 2
local FLYOUT_INITIAL_SPACING_MAX = 8
-- Inset from inner edge at the far end (padding between last button and flyout border / chrome).
local FLYOUT_FINAL_SPACING = 4
-- Gap between the trigger button and the flyout panel (pixels).
local FLYOUT_PARENT_GAP = 1

local function ScaledFlyoutInterButtonGap(scale)
    scale = scale or 1
    return math.floor(FLYOUT_INTER_BUTTON_GAP * scale + 0.5)
end

local function ScaledFlyoutInitialSpacing(scale)
    return math.min(
        FLYOUT_INITIAL_SPACING_MAX,
        math.max(0, math.floor(FLYOUT_INITIAL_SPACING * scale + 0.0001))
    )
end

-- Animation durations
local OPEN_DURATION = 0.15
local CLOSE_DURATION = 0.1

-- Arrow texture coordinates
local ARROW_TEX_COORDS = { 0.62500000, 0.98437500, 0.74218750, 0.82812500 }
local ARROW_SIZE_W = 23
local ARROW_SIZE_H = 11

local function CommitReagentRestockTarget(itemId, value)
    itemId = tonumber(itemId)
    if not itemId then
        return
    end
    value = math.max(0, math.min(999, tonumber(value) or 0))
    local Cons = _G.FluxNCConsumables
    if Cons and Cons.IsChronoboonItem and Cons.IsChronoboonItem(itemId) then
        if Cons.SetPresetRestockTarget then
            Cons.SetPresetRestockTarget(itemId, value)
        elseif Cons.SetChronoboonRestockTarget then
            Cons.SetChronoboonRestockTarget(value)
        end
        return
    end
    if not FluxVendorAuto then
        return
    end
    if value > 0 then
        FluxVendorAuto.AddRestockItem(itemId, value)
    else
        FluxVendorAuto.RemoveRestockItem(itemId)
    end
end

local function GetReagentRestockTarget(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return 0
    end
    local Cons = _G.FluxNCConsumables
    if Cons and Cons.IsChronoboonItem and Cons.IsChronoboonItem(itemId) then
        if Cons.GetPresetRestockTarget then
            return Cons.GetPresetRestockTarget(itemId) or 0
        end
        if Cons.GetChronoboonRestockTarget then
            return Cons.GetChronoboonRestockTarget() or 0
        end
        return 0
    end
    if FluxVendorAuto and FluxVendorAuto.GetSettings then
        local settings = FluxVendorAuto.GetSettings()
        if settings and settings.restockItems and settings.restockItems[itemId] then
            return settings.restockItems[itemId].targetQuantity or 0
        end
    end
    return 0
end


-- ---------------------------------------------------------------------------
-- FRAME POOL
-- ---------------------------------------------------------------------------

local flyoutPool = {}
local buttonPool = {}
local activeFlyout = nil
local activeFlyouts = {}  -- Map of parentButton -> flyoutFrame

-- ---------------------------------------------------------------------------
-- SCROLL CONTENT MANAGEMENT
-- Track extra height added to scroll content for open flyouts
-- ---------------------------------------------------------------------------

FluxFlyoutFrame.scrollContentExtraHeight = 0
FluxFlyoutFrame.scrollContentFrame = nil

--- Notify scroll content to expand when flyout opens
-- @param flyout The flyout frame
-- @param parentButton The parent button
-- @param direction The flyout direction
-- @param flyoutHeight The height of the flyout
function FluxFlyoutFrame.NotifyScrollContentExpand(flyout, parentButton, direction, flyoutHeight)
    -- Find the scroll content frame (ExtraButtons content)
    local contentFrame = nil
    
    -- Try to get from FluxExtraButtons
    if FluxExtraButtons and FluxExtraButtons.UI and FluxExtraButtons.UI.contentFrame then
        contentFrame = FluxExtraButtons.UI.contentFrame
    end
    
    -- Fallback: try to find by global name
    if not contentFrame then
        contentFrame = _G.FluxExtraButtonsContentFrame
    end
    
    if not contentFrame then return end
    
    -- Only add extra height for DOWN direction flyouts (extends below scroll area)
    if direction == "DOWN" then
        local currentHeight = contentFrame:GetHeight()
        FluxFlyoutFrame.scrollContentExtraHeight = flyoutHeight + 20  -- Extra padding
        contentFrame:SetHeight(currentHeight + FluxFlyoutFrame.scrollContentExtraHeight)
        FluxFlyoutFrame.scrollContentFrame = contentFrame
        flyout.addedScrollHeight = FluxFlyoutFrame.scrollContentExtraHeight
    end
end

--- Restore scroll content height when flyout closes
-- @param flyout The flyout frame being closed
function FluxFlyoutFrame.NotifyScrollContentRestore(flyout)
    if not flyout or not flyout.addedScrollHeight then return end
    
    local contentFrame = FluxFlyoutFrame.scrollContentFrame
    if contentFrame then
        local currentHeight = contentFrame:GetHeight()
        local newHeight = math.max(100, currentHeight - flyout.addedScrollHeight)
        contentFrame:SetHeight(newHeight)
    end
    
    flyout.addedScrollHeight = nil
    FluxFlyoutFrame.scrollContentExtraHeight = 0
end

-- ---------------------------------------------------------------------------
-- CROSS-VERSION HELPERS
-- ---------------------------------------------------------------------------

--- Horizontal squeeze factor for dependents (matches grids/trinket at min UI scale).
function FluxFlyoutFrame.GetDependentsHorizontalSqueezeFactor()
    if FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactor then
        local f = FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactor()
        if type(f) == "number" and f == f and f > 0 then
            return f
        end
    end
    return 1
end

--- True if widget is under ExtraButtons scroll, Flux*Grid, etc. (ancestor walk; matches FluxFlyoutCore.IsExtraButton + FluxCombatGrid).
function FluxFlyoutFrame.IsButtonInGridOrExtraButtonsContext(widget)
    if not widget then return false end
    if widget.FluxButton and widget.FluxButton._isExtraButton then
        return true
    end
    if widget._isExtraButton then
        return true
    end
    local parentFrame = widget:GetParent()
    while parentFrame do
        local parentName = parentFrame:GetName() or ""
        if parentName:match("ExtraButtons") or
           parentName:match("ExtraButtonsMainFrame") or
           parentName:match("ExtraButtonsContent") or
           parentName:match("ExtraButtonsScroll") or
           parentName:match("FluxButtonGrid") or
           parentName:match("FluxUtility") or
           parentName:match("FluxMage") or
           parentName:match("FluxNonCombatGrid") or
           parentName:match("NonCombatGrid") or
           parentName:match("FluxCombatGrid") then
            return true
        end
        parentFrame = parentFrame:GetParent()
    end
    return false
end

--- True only for scrollable Extra Buttons (not static NonCombat/Combat grids).
--- Static grids clip SlotFrame children; flyouts must float on UIParent on those clients.
function FluxFlyoutFrame.IsScrollableExtraButtonsContext(widget)
    if not widget then return false end
    -- Preset grid flyouts (Teleport, Mount items, Hearth items) are never scrollable.
    if widget.FluxGridFlyoutOwner then return false end
    if widget.FluxButton and widget.FluxButton.FluxGridFlyoutOwner then return false end
    local parentFrame = widget:GetParent()
    while parentFrame do
        local parentName = parentFrame:GetName() or ""
        if parentName:match("ExtraButtonsScroll") or
           parentName:match("ExtraButtonsContent") or
           parentName:match("ExtraButtonsMainFrame") then
            return true
        end
        if parentName:match("FluxNonCombatGrid") or
           parentName:match("NonCombatGrid") or
           parentName:match("FluxCombatGrid") or
           parentName:match("FluxButtonGrid") then
            return false
        end
        parentFrame = parentFrame:GetParent()
    end
    return false
end

--- Cell size matches the main trigger button: width (X squeeze) × height (unchanged vs unsqueezed icon row).
--- config.squareFlyoutCells: force cw == ch so UpdateFlyoutBackground wRatio stays 1 (e.g. unit-frame spec flyout on wide proxies).
local function ResolveFlyoutCellDimensions(parentButton, config)
    local cw, ch = BUTTON_SIZE, BUTTON_SIZE
    if parentButton then
        cw = math.max(1, parentButton:GetWidth() or BUTTON_SIZE)
        ch = math.max(1, parentButton:GetHeight() or BUTTON_SIZE)
    end
    if config and type(config.buttonSize) == "number" and config.buttonSize > 0 then
        local cap = math.floor(config.buttonSize)
        cw = math.min(cw, cap)
        ch = math.min(ch, cap)
    end
    if config and config.squareFlyoutCells then
        local side
        if type(config.buttonSize) == "number" and config.buttonSize > 0 then
            side = math.floor(config.buttonSize)
        else
            side = math.min(cw, ch)
        end
        side = math.max(1, side)
        cw, ch = side, side
    end
    return cw, ch
end

local function ComputeFlyoutPanelDimensions(direction, numButtons, cellW, cellH, spacing, initialSpacing, scale)
    local rowH = cellH + spacing
    local totalPadding = initialSpacing + FLYOUT_FINAL_SPACING * scale
    local width, height
    if direction == "UP" or direction == "DOWN" then
        width = cellW
        height = (numButtons * rowH) - spacing + totalPadding
    else
        width = (numButtons * cellW) - spacing + totalPadding
        height = cellH
    end
    return width, height
end

local function CreateBackdrop(frame)
    -- Try BackdropTemplate (9.0+)
    if BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
    end
    
    local backdrop = {
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    }
    
    if frame.SetBackdrop then
        frame:SetBackdrop(backdrop)
        frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end
end

local function SafeGetSpellInfo(spellIdOrName)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellIdOrName)
        if info then
            return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
        end
        return nil
    elseif GetSpellInfo then
        return GetSpellInfo(spellIdOrName)
    end
    return nil
end

--- Check if a button is inside a scroll frame
-- @param button The button to check
-- @return boolean, scrollFrame - true if inside scroll frame, and the scroll frame if found
local function IsInsideScrollFrame(button)
    if not button then return false, nil end
    
    local parent = button:GetParent()
    while parent do
        local name = parent:GetName() or ""
        local objType = parent:GetObjectType()
        
        -- Check for scroll frame types
        if objType == "ScrollFrame" or 
           name:match("ScrollFrame") or
           name:match("ScrollChild") or
           parent.GetVerticalScroll then
            return true, parent
        end
        
        parent = parent:GetParent()
    end
    return false, nil
end

--- Get button's screen position in UIParent coordinates
-- @param button The button to get position for
-- @return x, y center coordinates in UIParent scale, or nil if invalid
local function GetButtonScreenPosition(button)
    if not button then return nil, nil end
    
    local x, y = button:GetCenter()
    if not x or not y then return nil, nil end
    
    -- Get button's effective scale relative to UIParent
    local buttonScale = button:GetEffectiveScale()
    local uiParentScale = UIParent:GetEffectiveScale()
    
    -- Convert to UIParent coordinates
    local screenX = (x * buttonScale) / uiParentScale
    local screenY = (y * buttonScale) / uiParentScale
    
    return screenX, screenY
end

--- Get button dimensions in UIParent scale
-- @param button The button
-- @return width, height in UIParent scale
local function GetButtonScreenSize(button)
    if not button then return 36, 36 end
    
    local width = button:GetWidth() or 36
    local height = button:GetHeight() or 36
    
    local buttonScale = button:GetEffectiveScale()
    local uiParentScale = UIParent:GetEffectiveScale()
    
    local scaleFactor = buttonScale / uiParentScale
    
    return width * scaleFactor, height * scaleFactor
end

local function SafeGetItemInfo(itemIdOrName)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemIdOrName)
    elseif GetItemInfo then
        return GetItemInfo(itemIdOrName)
    end
    return nil
end

local function SafeGetSpellCooldown(spellId)
    local start, duration, enable = 0, 0, 1
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellId)
        if info then
            start = info.startTime or 0
            duration = info.duration or 0
            enable = info.isEnabled
            if info.isActive == false then
                start, duration = 0, 0
            end
        end
    elseif GetSpellCooldown then
        start, duration, enable = GetSpellCooldown(spellId)
    end
    -- Prefer charge recharge timer when charges are not full (matches FluxButton / ButtonForge).
    if C_Spell and C_Spell.GetSpellCharges then
        local chargesInfo = C_Spell.GetSpellCharges(spellId)
        if chargesInfo then
            local useCharge = false
            if chargesInfo.isActive ~= nil then
                useCharge = chargesInfo.isActive and true or false
            elseif chargesInfo.maxCharges and chargesInfo.currentCharges
                and chargesInfo.maxCharges > 1
                and chargesInfo.currentCharges < chargesInfo.maxCharges then
                useCharge = true
            end
            if useCharge then
                start = chargesInfo.cooldownStartTime or start
                duration = chargesInfo.cooldownDuration or duration
            end
        end
    elseif GetSpellCharges then
        local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellId)
        if charges and maxCharges and maxCharges > 1 and charges < maxCharges then
            start = chargeStart or start
            duration = chargeDuration or duration
        end
    end
    return start, duration, enable
end

--- Cooldown APIs require a numeric item ID. Action data may store plain names (e.g. "Simple Wood") or links.
local function ResolveNumericItemId(itemIdOrName)
    if itemIdOrName == nil then
        return nil
    end
    if type(itemIdOrName) == "number" then
        local n = math.floor(itemIdOrName)
        if n > 0 and n <= 2147483647 then
            return n
        end
        return nil
    end
    if type(itemIdOrName) ~= "string" then
        return nil
    end
    local s = itemIdOrName:match("^%s*(.-)%s*$") or itemIdOrName
    local asNum = tonumber(s)
    if asNum and asNum > 0 then
        return math.floor(asNum)
    end
    local fromLink = s:match("item:(%d+)")
    if fromLink then
        return tonumber(fromLink)
    end
    -- Plain name or uncached ID: C_Item.GetItemCooldown needs a number; resolve via item info.
    local info = SafeGetItemInfo(s)
    if type(info) == "table" and type(info.itemID) == "number" and info.itemID > 0 then
        return info.itemID
    end
    if GetItemInfo then
        local link = select(2, GetItemInfo(s))
        if type(link) == "string" then
            local lid = link:match("item:(%d+)")
            if lid then
                return tonumber(lid)
            end
        end
    end
    return nil
end

local function SafeGetItemCooldown(itemIdOrName)
    local itemId = ResolveNumericItemId(itemIdOrName)
    if not itemId then
        return 0, 0, 1
    end
    -- Retail: C_Item.GetItemCooldown returns ItemCooldownInfo (table), not multiple values
    if C_Item and C_Item.GetItemCooldown then
        local a, b, c = C_Item.GetItemCooldown(itemId)
        if a == nil then
            return 0, 0, 1
        elseif type(a) == "table" then
            return a.startTime or 0, a.duration or 0, a.isEnabled
        end
        return a or 0, b or 0, c or 1
    elseif C_Container and C_Container.GetItemCooldown then
        local a, b, c = C_Container.GetItemCooldown(itemId)
        if a and type(a) == "table" then
            return a.startTime or 0, a.duration or 0, a.isEnabled
        end
        return a or 0, b or 0, c or 1
    elseif GetItemCooldown then
        return GetItemCooldown(itemId)
    end
    return 0, 0, 1
end

-- ---------------------------------------------------------------------------
-- FLYOUT BUTTON
-- ---------------------------------------------------------------------------

local function UpdateFlyoutButtonVisuals(btn)
    if not btn then
        return
    end

    local w = btn:GetWidth() or BUTTON_SIZE
    local h = btn:GetHeight() or BUTTON_SIZE
    local minDim = math.min(w, h)
    local insetFrac = (FluxButtonUtil and FluxButtonUtil.FLYOUT_ICON_INSET_FRAC) or 0.1125
    local iconInset = math.max(1, minDim * insetFrac)

    if btn.icon then
        btn.icon:ClearAllPoints()
        btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", iconInset, -iconInset)
        btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -iconInset, iconInset)
    end

    if FluxButtonUtil and FluxButtonUtil.SyncFlyoutButtonLayerSizes then
        FluxButtonUtil:SyncFlyoutButtonLayerSizes(btn)
    end
end

local function CreateFlyoutButton(parent, frameIndex, buttonIndex)
    local buttonName = "FluxFlyoutFrame" .. frameIndex .. "Button" .. buttonIndex
    
    -- Use secure template for in-combat safety
    local btn = CreateFrame("Button", buttonName, parent, "SecureActionButtonTemplate")
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:EnableMouse(true)
    -- Must register both: SecureActionButton_OnClick uses ActionButtonUseKeyDown — when true only DOWN
    -- performs the action; when false only UP does. AnyUp alone never receives DOWN, so casts never fire on retail.
    btn:RegisterForClicks("AnyDown", "AnyUp")
    if not (InCombatLockdown and InCombatLockdown()) then
        btn:RegisterForDrag("LeftButton")
    end
    
    -- Disable checked texture completely (prevents unwanted golden highlight on mouseover)
    -- SecureActionButtonTemplate may include a checked texture that interferes
    if btn.SetCheckedTexture then
        btn:SetCheckedTexture(nil)
    end
    local checkedTex = btn.GetCheckedTexture and btn:GetCheckedTexture()
    if checkedTex then
        checkedTex:SetAlpha(0)
        checkedTex:Hide()
    end
    
    -- Override SetChecked to prevent checked state from ever being set
    local originalSetChecked = btn.SetChecked
    if originalSetChecked then
        btn.SetChecked = function(self, checked)
            -- Always force unchecked - never allow checked state
            if originalSetChecked then
                originalSetChecked(self, false)
            end
            -- Ensure checked texture stays hidden
            local tex = self.GetCheckedTexture and self:GetCheckedTexture()
            if tex then
                tex:Hide()
                tex:SetAlpha(0)
            end
        end
    end
    
    -- Force unchecked state initially
    if btn.SetChecked then
        btn:SetChecked(false)
    end
    
    -- Icon texture
    btn.icon = btn:CreateTexture(buttonName .. "Icon", "ARTWORK")
    btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Highlight texture (auto-shown on mouseover by WoW - this is the blue highlight)
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    -- Points/sizing applied in UpdateFlyoutButtonVisuals / FluxButtonUtil:SyncFlyoutButtonLayerSizes

    -- Quality/Rarity Border (initially hidden); size synced with equip border in UpdateFlyoutButtonVisuals
    btn.QualityBorder = btn:CreateTexture(nil, "OVERLAY")
    btn.QualityBorder:SetPoint("CENTER", btn, "CENTER")
    btn.QualityBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    btn.QualityBorder:SetBlendMode("ADD")
    btn.QualityBorder:SetAlpha(0.6)
    btn.QualityBorder:Hide()

    -- Equipped item border (same visual language as FluxButton WBorder)
    btn.EquippedBorder = btn:CreateTexture(nil, "OVERLAY")
    btn.EquippedBorder:SetPoint("CENTER", btn, "CENTER")
    btn.EquippedBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    btn.EquippedBorder:SetBlendMode("ADD")
    btn.EquippedBorder:SetVertexColor(0, 1.0, 0, 0.35)
    btn.EquippedBorder:Hide()

    -- FluxRespec profile row: missing / bank-only gear (driven by $respecGearIssue on actionData)
    btn.RespecGearBorder = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    btn.RespecGearBorder:SetPoint("CENTER", btn, "CENTER")
    btn.RespecGearBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    btn.RespecGearBorder:SetBlendMode("ADD")
    btn.RespecGearBorder:SetVertexColor(1, 0.25, 0.25, 0.9)
    btn.RespecGearBorder:Hide()

    -- Cooldown frame: match icon rect (inset inside ring), not full button — swipe aligns with artwork on all clients.
    btn.cooldown = CreateFrame("Cooldown", buttonName .. "Cooldown", btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints(btn.icon)
    btn.cooldown:SetDrawBling(false)
    btn.cooldown:SetDrawEdge(true)
    if btn.cooldown.EnableMouse then
        btn.cooldown:EnableMouse(false)
    end
    
    -- Count text (for items with stacks)
    btn.count = btn:CreateFontString(buttonName .. "Count", "OVERLAY", "NumberFontNormal")
    btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    btn.count:SetJustifyH("RIGHT")
    btn.count:SetText("")

    -- Edit box for reagent restock settings (initially hidden)
    local editBox = CreateFrame("EditBox", nil, btn, "InputBoxTemplate")
    editBox:SetSize(20, 14)
    editBox:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    editBox:SetFontObject("GameFontNormalSmall")
    editBox:SetJustifyH("RIGHT")
    editBox:SetJustifyV("BOTTOM")
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(3)
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:Hide()

    -- Handle edit box events
    editBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 0
        local itemId = btn._reagentItemId
        if itemId then
            CommitReagentRestockTarget(itemId, value)
            if btn.actionData then
                 btn.actionData["$restockTarget"] = value
                 btn.actionData["$targetCount"] = value
            end
        end
        self:Hide()
        -- Show count text again
        btn.count:Show()
        -- Update count display
        FluxFlyoutFrame.UpdateButtonCount(btn)
        
        -- Refresh tooltip if currently hovering
        if btn:IsMouseOver() then
            FluxFlyoutFrame.ShowButtonTooltip(btn)
        end
        self._fluxRestockEnterCommit = true
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self._fluxRestockEscapeCancel = true
        self:ClearFocus()
        -- Reset to current target value
        local itemId = btn._reagentItemId
        if itemId then
            self:SetText(tostring(GetReagentRestockTarget(itemId)))
        end
        self:Hide()
        -- Show count text again
        btn.count:Show()
        self._fluxRestockEscapeCancel = nil
    end)

    editBox:SetScript("OnEditFocusLost", function(self)
        if self._fluxRestockEnterCommit then
            self._fluxRestockEnterCommit = nil
            return
        end
        if self._fluxRestockEscapeCancel then
            return
        end
        local value = tonumber(self:GetText()) or 0
        local itemId = btn._reagentItemId
        if itemId then
            CommitReagentRestockTarget(itemId, value)
            if btn.actionData then
                 btn.actionData["$restockTarget"] = value
                 btn.actionData["$targetCount"] = value
            end
        end
        self:Hide()
        -- Show count text again
        btn.count:Show()
        -- Update count display
        FluxFlyoutFrame.UpdateButtonCount(btn)
    end)



    btn.editBox = editBox
    
    -- Normal texture (for button state)
    btn:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    
    -- Pushed texture
    btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    UpdateFlyoutButtonVisuals(btn)
    
    -- Scripts (highlight handled automatically by SetHighlightTexture)
    btn:SetScript("OnEnter", function(self)
        FluxFlyoutFrame.ShowButtonTooltip(self)
    end)
    
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    btn:SetScript("OnDragStart", function(self)
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        local spellId = tonumber(self._actionSpellID)
        local itemId = tonumber(self._actionItemID)
        local ActionAPI = (ns.Flux and ns.Flux.EBS and ns.Flux.EBS.Action)
            or (_G.Flux and _G.Flux.EBS and _G.Flux.EBS.Action)
        if spellId and spellId > 0 then
            if ActionAPI and ActionAPI.NoteFlyoutPopupSpell then
                ActionAPI.NoteFlyoutPopupSpell(spellId)
            end
            if C_Spell and C_Spell.PickupSpell then
                pcall(C_Spell.PickupSpell, spellId)
            elseif PickupSpell then
                pcall(PickupSpell, spellId)
            end
        elseif itemId and itemId > 0 then
            if ActionAPI and ActionAPI.NoteFlyoutPopupItem then
                ActionAPI.NoteFlyoutPopupItem(itemId)
            end
            if C_Item and C_Item.PickupItem then
                pcall(C_Item.PickupItem, itemId)
            elseif PickupItem then
                pcall(PickupItem, itemId)
            end
        end
    end)
    
    btn:SetScript("PostClick", function(self, button, down)
        if down then return end

        local actionData = self.actionData or self._actionData

        -- Reagent items: left- or right-click toggles restock target edit box (no secure use/cast).
        if actionData and actionData["$isReagent"] then
            if button == "LeftButton" or button == "RightButton" or button == nil then
                if self.editBox then
                    if self.editBox:IsShown() then
                        self.editBox:ClearFocus()
                        self.editBox:Hide()
                        if self.count then self.count:Show() end
                    else
                        self.editBox:Show()
                        self.editBox._fluxRestockEnterCommit = nil
                        self.editBox._fluxRestockEscapeCancel = nil
                        self.editBox:SetText(tostring(actionData["$targetCount"] or 0))
                        self.editBox:HighlightText(0, 0)
                        self.editBox:SetFocus()
                        if self.count then self.count:Hide() end
                    end
                end
            end
            return
        end

        -- Don't close on right-click if this is a favorites-enabled flyout
        -- (Right-click is reserved for setting/clearing favorites)
        if button == "RightButton" then
            local parentFrame = self:GetParent()
            if parentFrame and parentFrame.parentButton and parentFrame.parentButton.FluxGridFlyoutOwner then
                -- This is a grid-owned flyout with favorites - don't close on right-click
                return
            end
        end

        -- Notify parent (main button) which action was used — always on left-click,
        -- so mount/hearthstone buttons update even when modifiers keep the flyout open.
        local flyout = self.flyoutParent
        if (button == "LeftButton" or button == nil) and flyout and flyout.config and flyout.config.onActionUse and actionData then
            pcall(flyout.config.onActionUse, actionData)
        end

        -- Close flyout after left-click (unless holding modifier)
        if not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
            FluxFlyoutFrame.CloseFlyout()
        end
    end)
    
    -- Store index
    btn.index = buttonIndex
    btn.actionData = nil

    -- Store parent reference directly (SetFrameRef only available on secure handlers)
    btn.flyoutParent = parent
    
    return btn
end

-- ---------------------------------------------------------------------------
-- BUTTON CONFIGURATION
-- ---------------------------------------------------------------------------

--- Configure a flyout button with action data
-- @param btn The button to configure
-- @param actionData Action data from generators
-- @param parentButton Optional parent button for favorites context
function FluxFlyoutFrame.ConfigureButton(btn, actionData, parentButton)
    if not btn or not actionData then return end
    
    -- Reset per-feature overlays from reused pooled buttons.
    if btn._fluxTransmogActiveBorder then
        btn._fluxTransmogActiveBorder:Hide()
    end

    -- Store action data for reference
    btn.actionData = actionData
    btn._actionData = actionData
    
    -- Store item/spell IDs directly on button (expected by FluxFlyoutFavorites)
    -- Support both $itemId (lowercase) and $itemID (uppercase) for compatibility
    btn._actionItemID = actionData["$itemId"] or actionData["$itemID"]
    btn._actionSpellID = actionData["$spellId"] or actionData["$spellID"]
    if not (InCombatLockdown and InCombatLockdown()) and btn.RegisterForDrag then
        btn:RegisterForDrag("LeftButton")
    end
    
    -- Reset button visual state
    if btn.icon then
        btn.icon:SetDesaturated(false)
    end
    
    -- Clear previous attributes (matching old FluxCustomFlyout.SetButtonAction)
    btn:SetAttribute("type", nil)
    btn:SetAttribute("spell", nil)
    btn:SetAttribute("item", nil)
    btn:SetAttribute("macro", nil)
    btn:SetAttribute("macrotext", nil)
    btn:SetAttribute("*type1", nil)
    btn:SetAttribute("*type2", nil)
    btn:SetAttribute("*type3", nil)
    btn:SetAttribute("*macrotext1", nil)
    btn:SetAttribute("spell2", nil)
    btn:SetAttribute("FluxFlyoutCategory", nil)
    
    -- Clear button state
    btn._fluxFavCategory = nil
    btn._fluxHideCount = nil
    btn._fluxSkipFavorites = nil

    local isReagent = actionData["$isReagent"]
    if isReagent then
        btn._fluxSkipFavorites = true
        btn._reagentItemId = actionData["$reagentItemId"] or actionData["$itemId"] or actionData["$itemID"]
    end
    
    -- Detect category from parent button (matching old pattern)
    local category = nil
    local detectedParent = parentButton or (btn.flyoutParent and btn.flyoutParent.parentButton) or (btn:GetParent() and btn:GetParent().parentButton)
    if detectedParent and detectedParent.FluxFlyoutCategory then
        category = detectedParent.FluxFlyoutCategory
    end
    
    -- Track if this is a flyout category button (needs favorites support)
    local isFlyoutCategoryButton = false
    
    if category then
        isFlyoutCategoryButton = true
        btn:SetAttribute("FluxFlyoutCategory", category)
        btn._fluxFavCategory = category
        
        -- Grid-owned flyouts (mount spells, etc.): hide numeric count — not meaningful on spell rows.
        -- TeleportItem flyout uses real items; show stack count only for stackable items (UpdateButtonCount).
        if detectedParent and detectedParent.FluxGridFlyoutOwner and not actionData["$isReagent"] then
            if category ~= "TeleportItem" then
                btn._fluxHideCount = true
            end
        end
        
        -- Reagent rows: no secure cast/use; PostClick opens restock edit box.
        if not isReagent then
            -- For flyout category buttons, set up conditional attributes
            -- Left-click: cast spell/use item, Right-click: do nothing (handled by Lua favorites system)
            btn:SetAttribute("type", nil)  -- Clear default type
            btn:SetAttribute("*type1", actionData["type"] or "item")  -- Left-click casts/uses
            btn:SetAttribute("*type2", nil)  -- Right-click does nothing (favorites system handles it)
            btn:SetAttribute("*type3", nil)  -- Middle-click does nothing
            
            -- Set spell/item attribute directly (retail: spell ID string is more reliable than localized name)
            if actionData["spell"] then
                local spellAttr = actionData["spell"]
                if FLUX_API and FLUX_API.isPostDF and FLUX_API.isRetail then
                    local sid = actionData["$spellID"] or actionData["$spellId"]
                    if type(sid) == "number" and sid > 0 then
                        spellAttr = tostring(sid)
                    end
                end
                btn:SetAttribute("spell", spellAttr)
            elseif actionData["item"] then
                local itemVal = actionData["item"]
                if type(itemVal) == "number" then
                    itemVal = "item:" .. tostring(itemVal)
                elseif type(itemVal) == "string" and not itemVal:match("^item:") and itemVal:match("^%d+$") then
                    itemVal = "item:" .. itemVal
                end
                btn:SetAttribute("item", itemVal)
            end
        end
        
        -- Note: HookFlyoutButton is called later by OnFlyoutOpened with a slight delay
        -- to ensure all button data is properly configured before hooking
    end
    
    -- Set new attributes from actionData (skip type/item/spell for category buttons — set above with retail spell ID fix)
    for key, value in pairs(actionData) do
        if not key:match("^%$") and not ((isFlyoutCategoryButton or isReagent) and (key == "type" or key == "item" or key == "spell")) then
            local setVal = value
            if key == "item" and setVal then
                if type(setVal) == "number" then
                    setVal = "item:" .. tostring(setVal)
                elseif type(setVal) == "string" and not setVal:match("^item:") and setVal:match("^%d+$") then
                    setVal = "item:" .. setVal
                end
            end
            btn:SetAttribute(key, setVal)
        end
    end
    
    -- Ensure reagentItemId property is set for the EditBox scripts
    btn._reagentItemId = actionData["$reagentItemId"]
    
    -- Set icon
    local icon = actionData["$iconTexture"] or actionData["$icon"]
    if icon then
        -- Handle different icon formats
        if type(icon) == "string" and icon:find(":") then
            local iconType, iconId = strsplit(":", icon, 2)
            if iconType == "spell" then
                local spellID = tonumber(iconId)
                if spellID then
                    if C_Spell and C_Spell.GetSpellTexture then
                        icon = C_Spell.GetSpellTexture(spellID)
                    elseif GetSpellTexture then
                        icon = GetSpellTexture(spellID)
                    end
                end
            elseif iconType == "item" then
                local itemID = tonumber(iconId)
                if itemID then
                    icon = GetItemIcon(itemID)
                end
            elseif iconType == "texture" then
                icon = tonumber(iconId) or iconId
            end
        end
        
        if btn.icon and icon then
            btn.icon:SetTexture(icon)
            btn.icon:Show()
        end
    elseif btn.icon then
        btn.icon:Hide()
    end
    
    -- Update item count text
    FluxFlyoutFrame.UpdateButtonCount(btn)
    
    -- Update cooldown
    FluxFlyoutFrame.UpdateButtonCooldown(btn)
    
    FluxFlyoutFrame.UpdateButtonEquipped(btn)
    FluxFlyoutFrame.UpdateButtonUsability(btn)
    FluxFlyoutFrame.UpdateRespecProfileGearBorder(btn)
    
    btn:Show()
end

--- Respec profile flyout: red (missing) or amber (bank / unknown) border from actionData["$respecGearIssue"].
function FluxFlyoutFrame.UpdateRespecProfileGearBorder(btn)
    if not btn or not btn.RespecGearBorder then
        return
    end
    local ad = btn.actionData
    if not ad or not ad["$profileName"] then
        btn.RespecGearBorder:Hide()
        return
    end
    local issue = ad["$respecGearIssue"]
    if not issue then
        btn.RespecGearBorder:Hide()
        return
    end
    if issue == "missing" then
        btn.RespecGearBorder:SetVertexColor(1, 0.2, 0.2, 0.9)
    else
        btn.RespecGearBorder:SetVertexColor(1, 0.55, 0.1, 0.85)
    end
    btn.RespecGearBorder:Show()
end

--- Max stack size for an item (1 = not stackable for UI purposes)
function FluxFlyoutFrame.GetItemMaxStackSize(itemId)
    if not itemId then return 1 end
    if C_Item and C_Item.GetItemMaxStackSizeByID then
        local max = C_Item.GetItemMaxStackSizeByID(itemId)
        if max and max > 0 then
            return max
        end
    end
    if C_Item and C_Item.GetItemInfo then
        local info = C_Item.GetItemInfo(itemId)
        if info and type(info) == "table" and info.stackCount then
            return info.stackCount
        end
    end
    local _, _, _, _, _, _, _, stackCount = GetItemInfo(itemId)
    return stackCount or 1
end

--- Apply mount / spell usability tint for flyout rows (indoor, combat, zone).
function FluxFlyoutFrame.UpdateButtonUsability(btn)
    if not btn or not btn.icon or not btn.actionData then
        return
    end

    local category = btn._fluxFavCategory
    if not category and btn.GetAttribute then
        category = btn:GetAttribute("FluxFlyoutCategory")
    end
    if not category and btn.flyoutParent and btn.flyoutParent.parentButton then
        category = btn.flyoutParent.parentButton.FluxFlyoutCategory
    end

    local itemId = btn._actionItemID or btn.actionData["$itemId"] or btn.actionData["$itemID"]
    local spellId = btn._actionSpellID or btn.actionData["$spellId"] or btn.actionData["$spellID"]
    local isReagent = btn.actionData["$isReagent"]

    local state, notEnoughMana
    if FluxButtonUsability then
        if category == "Mount" and itemId then
            state, notEnoughMana = FluxButtonUsability:CheckMountItemUsability(itemId)
        elseif (category == "Teleport" or category == "Portal") and spellId then
            state, notEnoughMana = FluxButtonUsability:CheckSpellUsability(spellId)
        elseif spellId and not isReagent then
            state, notEnoughMana = FluxButtonUsability:CheckSpellUsability(spellId)
        elseif itemId and (
            (_G.FluxInv and _G.FluxInv.Spells and _G.FluxInv.Spells.IsItemAMount and _G.FluxInv.Spells.IsItemAMount(itemId))
            or (FluxItemDetection and FluxItemDetection.IsItemAMount and FluxItemDetection.IsItemAMount(itemId))
        ) then
            state, notEnoughMana = FluxButtonUsability:CheckMountItemUsability(itemId)
        elseif spellId and C_MountJournal and C_MountJournal.GetMountFromSpell then
            local mountId = C_MountJournal.GetMountFromSpell(spellId)
            if mountId then
                state, notEnoughMana = FluxButtonUsability:CheckMountUsability(mountId)
            end
        end
    end

    if not state or not FluxButtonUsability then
        btn.icon:SetVertexColor(1, 1, 1)
        return
    end

    if state == FluxButtonUsability.STATE_USABLE then
        btn.icon:SetVertexColor(1, 1, 1)
    elseif state == FluxButtonUsability.STATE_NOT_ENOUGH_MANA or notEnoughMana then
        btn.icon:SetVertexColor(0.5, 0.5, 1.0)
    else
        btn.icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end

--- Equipped border + desaturated icon for unequipped gear (matches main grid button)
function FluxFlyoutFrame.UpdateButtonEquipped(btn)
    if not btn or not btn.actionData then return end
    local actionData = btn.actionData
    local itemId = actionData["$itemId"] or actionData["$itemID"]
    
    if not itemId then
        if btn.EquippedBorder then btn.EquippedBorder:Hide() end
        if btn.icon then btn.icon:SetDesaturated(false) end
        return
    end
    
    local equipped = false
    if C_Item and C_Item.IsEquippedItem then
        equipped = C_Item.IsEquippedItem(itemId)
    elseif IsEquippedItem then
        equipped = IsEquippedItem(itemId)
    end
    
    if btn.EquippedBorder then
        if equipped then
            btn.EquippedBorder:Show()
        else
            btn.EquippedBorder:Hide()
        end
    end
    
    if btn.icon then
        local isEquip = actionData["$isEquipment"]
        -- Reagent rows (e.g. teleport runes) are never armor/weapon-style equipment for this UI
        if isEquip == nil and actionData["$isReagent"] then
            isEquip = false
        end
        -- Prefer IsEquippableItem: equipLoc alone is wrong for mount items and other non-armor items
        -- that still report a non-empty inventory type string.
        if isEquip == nil then
            if C_Item and C_Item.IsEquippableItem then
                isEquip = C_Item.IsEquippableItem(itemId) and true or false
            elseif IsEquippableItem then
                isEquip = IsEquippableItem(itemId) and true or false
            elseif GetItemInfo then
                local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemId)
                isEquip = type(equipLoc) == "string" and equipLoc ~= ""
            end
        end
        if isEquip == nil then
            isEquip = false
        end
        if isEquip and not equipped then
            btn.icon:SetDesaturated(true)
        else
            btn.icon:SetDesaturated(false)
        end
    end
end

--- Update button item count display
-- @param btn The button to update
function FluxFlyoutFrame.UpdateButtonCount(btn)
    if not btn or not btn.count then return end
    
    -- Hide count by default
    btn.count:SetText("")
    
    -- Skip if count should be hidden (for category buttons that manage their own display)
    if btn._fluxHideCount then return end
    
    local actionData = btn.actionData
    if not actionData then return end
    
    -- Only show count for items
    local itemId = actionData["$itemId"] or actionData["$itemID"]
    if not itemId then return end
    
    -- Get item count
    local count = actionData["$currentCount"] or 0
    if count == 0 then
        if C_Item and C_Item.GetItemCount then
            count = C_Item.GetItemCount(itemId, nil, true) or 0
        elseif GetItemCount then
            count = GetItemCount(itemId, nil, true) or 0
        end
    end
    
    -- Check for restock target (reagent items)
    local restockTarget = actionData["$restockTarget"] or actionData["$targetCount"] or 0
    local isReagent = actionData["$isReagent"]
    
    if isReagent then
        -- Always show X / Y format for reagents (like the old system)
        local countColor = "|cffffffff"  -- white
        local slashColor = "|cff888888"  -- gray
        local targetColor = "|cff888888" -- gray
        
        if restockTarget > 0 then
            -- Color the count based on stock level
            if count == 0 then
                countColor = "|cffff4444"  -- red
            elseif count < restockTarget then
                countColor = "|cffffff00"  -- yellow if below target
            else
                countColor = "|cff00ff00"  -- green if at or above target
            end
        end
        
        btn.count:SetText(countColor .. count .. slashColor .. "/" .. targetColor .. restockTarget .. "|r")
    elseif count and count > 0 then
        -- Only show stack count when the item can stack (hearthstones etc. stay clean)
        local maxStack = FluxFlyoutFrame.GetItemMaxStackSize(itemId)
        if maxStack > 1 then
            btn.count:SetText(tostring(count))
        end
    end
end

--- Update button cooldown display
-- @param btn The button to update
function FluxFlyoutFrame.UpdateButtonCooldown(btn)
    if not btn or not btn.actionData or not btn.cooldown then return end

    local actionData = btn.actionData
    local start, duration, enable = 0, 0, 1

    -- Get cooldown based on action type ($spellID used by some generators)
    local spellId = actionData["$spellId"] or actionData["$spellID"]
    local itemId = actionData["$itemId"] or actionData["$itemID"]
    if spellId then
        -- Midnight: prefer duration objects (secret-safe), matching FluxButton / ButtonForge.
        if C_Spell and C_Spell.GetSpellCooldownDuration and btn.cooldown.SetCooldownFromDurationObject
            and FLUX_API and (FLUX_API.hasCanAccessValue or FLUX_API.isMidnight
                or (FLUX_API.isRetail and (FLUX_API.buildNumber or 0) >= 66562)) then
            local chargeInfo = C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(spellId)
            local useCharge = false
            if chargeInfo then
                if chargeInfo.isActive ~= nil then
                    useCharge = chargeInfo.isActive and true or false
                elseif chargeInfo.maxCharges and chargeInfo.currentCharges
                    and chargeInfo.maxCharges > 1
                    and chargeInfo.currentCharges < chargeInfo.maxCharges then
                    useCharge = true
                end
            end
            local durObj
            if useCharge and C_Spell.GetSpellChargeDuration then
                durObj = C_Spell.GetSpellChargeDuration(spellId)
            else
                local info = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellId)
                if info and info.isActive == false and not useCharge then
                    durObj = nil
                else
                    durObj = C_Spell.GetSpellCooldownDuration(spellId)
                end
            end
            if durObj then
                pcall(btn.cooldown.SetCooldownFromDurationObject, btn.cooldown, durObj)
                btn.cooldown:Show()
                if FluxButtonUtil and FluxButtonUtil.ApplyCooldownCountdownHorizontalScale then
                    local lw, lh = btn._fluxFlyoutCooldownLogicalW, btn._fluxFlyoutCooldownLogicalH
                    if (not lw or not lh) and btn.icon then
                        lw = btn.icon:GetWidth()
                        lh = btn.icon:GetHeight()
                    end
                    FluxButtonUtil:ApplyCooldownCountdownHorizontalScale(btn.cooldown, btn, lw, lh)
                end
                return
            end
            if btn.cooldown.Clear then
                pcall(btn.cooldown.Clear, btn.cooldown)
            end
            btn.cooldown:Hide()
            return
        end
        start, duration, enable = SafeGetSpellCooldown(spellId)
    elseif itemId then
        start, duration, enable = SafeGetItemCooldown(itemId)
    end

    -- Apply to cooldown frame
    if duration and duration > 0 then
        btn.cooldown:SetCooldown(start or 0, duration)
        btn.cooldown:Show()
        if FluxButtonUtil and FluxButtonUtil.ApplyCooldownCountdownHorizontalScale then
            local lw, lh = btn._fluxFlyoutCooldownLogicalW, btn._fluxFlyoutCooldownLogicalH
            if (not lw or not lh) and btn.icon then
                lw = btn.icon:GetWidth()
                lh = btn.icon:GetHeight()
            end
            FluxButtonUtil:ApplyCooldownCountdownHorizontalScale(btn.cooldown, btn, lw, lh)
        end
    else
        btn.cooldown:Hide()
    end
end

--- Show tooltip for a flyout button
-- @param btn The button being hovered
function FluxFlyoutFrame.ShowButtonTooltip(btn)
    if not btn or not btn.actionData then return end
    
    local actionData = btn.actionData
    
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT", 4, 4)
    
    -- Show appropriate tooltip based on action type
    -- Use pcall to safely handle any secret value access on v12+ clients
    -- Transmog outfits: $name is the outfit title; $spellId is only for shared equip cooldown display.
    if actionData["$outfitIndex"] or actionData["$outfitID"] then
        local name = actionData["$name"]
        if name then
            GameTooltip:SetText(name, 1, 1, 1)
        else
            GameTooltip:SetText("Transmog Outfit", 1, 1, 1)
        end
        if actionData["$isActive"] then
            GameTooltip:AddLine("Currently active.", 0.5, 1, 0.5, true)
        else
            GameTooltip:AddLine("Click to activate this outfit.", 0.78, 0.78, 0.78, true)
        end
    elseif actionData["$spellId"] then
        local success = false
        local spellId = actionData["$spellId"]
        
        -- Check if spell ID is accessible (not secret) before calling SetSpellByID
        local canAccess = true
        if FluxAPICompat and FluxAPICompat.API and FluxAPICompat.API.CanAccessValue then
            canAccess = FluxAPICompat.API.CanAccessValue(spellId)
        end
        
        if canAccess and GameTooltip.SetSpellByID then
            success = pcall(GameTooltip.SetSpellByID, GameTooltip, spellId)
        end
        
        if not success and actionData["$name"] then
            GameTooltip:SetText(actionData["$name"])
        end
    elseif actionData["$itemId"] then
        local success = false
        if GameTooltip.SetItemByID then
            success = pcall(GameTooltip.SetItemByID, GameTooltip, actionData["$itemId"])
        end
        if not success and actionData["$name"] then
            GameTooltip:SetText(actionData["$name"])
        end
        
        -- Add restock info for reagent items
        if actionData["$isReagent"] then
            local currentCount = actionData["$currentCount"] or 0
            local restockTarget = actionData["$restockTarget"] or actionData["$targetCount"] or 0
            local itemPrice = actionData["$itemPrice"] or 0
            
            -- Update current count in case it changed
            if C_Item and C_Item.GetItemCount then
                currentCount = C_Item.GetItemCount(actionData["$itemId"], nil, true) or 0
            elseif GetItemCount then
                currentCount = GetItemCount(actionData["$itemId"], nil, true) or 0
            end
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Restock Settings", 1, 0.82, 0)
            
            -- Show Unit Price explicitly
            if itemPrice > 0 then
                local priceStr = GetMoneyString and GetMoneyString(itemPrice) or (itemPrice .. "c")
                GameTooltip:AddLine("Unit Price: " .. priceStr, 1, 1, 1)
            else
                GameTooltip:AddLine("Unit Price: Unknown (Visit Vendor)", 0.6, 0.6, 0.6)
            end
            
            GameTooltip:AddLine("Current: " .. currentCount .. " | Target: " .. restockTarget, 1, 1, 1)

            local itemIdTip = actionData["$itemId"] or actionData["$itemID"]
            if itemIdTip and FluxRestock and FluxRestock.AppendSpellsUsingReagentToTooltip then
                FluxRestock.AppendSpellsUsingReagentToTooltip(GameTooltip, itemIdTip)
            end
            
            if restockTarget > 0 then
                local needed = math.max(0, restockTarget - currentCount)
                if needed > 0 then
                    GameTooltip:AddLine("Will restock " .. needed .. " at vendor", 0, 1, 0)
                    if itemPrice > 0 then
                        local restockCost = needed * itemPrice
                        local moneyString = GetMoneyString and GetMoneyString(restockCost) or (restockCost .. "c")
                        GameTooltip:AddLine("Total Cost: " .. moneyString, 1, 0.82, 0)
                    end
                else
                    GameTooltip:AddLine("Stock sufficient", 0, 0.5, 0)
                end
            else
                GameTooltip:AddLine("Restock disabled (target = 0)", 0.5, 0.5, 0.5)
            end
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Left- or right-click: set restock target", 0.8, 0.8, 0.8)
        end
    elseif actionData["$macroIndex"] then
        local name = GetMacroInfo(actionData["$macroIndex"])
        if name then
            GameTooltip:SetText(name)
        end
    elseif actionData["$profileName"] then
        local pname = actionData["$profileName"]
        GameTooltip:SetText(actionData["$name"] or pname, 1, 1, 1)
        GameTooltip:AddLine("Click: set active profile and run first load step.", 0.78, 0.78, 0.78, true)
        local fr = _G.FluxRespec
        if fr and fr.GetProfile and fr.Equipment and fr.Equipment.GetProfileGearAvailability then
            local prof = fr.GetProfile(pname)
            local rows = prof and fr.Equipment.GetProfileGearAvailability(prof) or {}
            local any = false
            for _, r in ipairs(rows) do
                if r.status ~= "equipped" and r.status ~= "bags" then
                    any = true
                    break
                end
            end
            if any then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Gear for this profile:", 1, 0.82, 0)
                for _, r in ipairs(rows) do
                    if r.status == "missing" then
                        GameTooltip:AddLine(
                            (r.label or "?") .. ": " .. (r.itemName or "?") .. " — |cffff3333not found|r",
                            1, 1, 1, true
                        )
                    elseif r.status == "bank" then
                        GameTooltip:AddLine(
                            (r.label or "?") .. ": " .. (r.itemName or "?") .. " — |cffffaa33in bank|r",
                            1, 1, 1, true
                        )
                    elseif r.status == "unknown" then
                        GameTooltip:AddLine(
                            (r.label or "?") .. ": " .. (r.itemName or "?") .. " — |cffaaaaaanot in bags (open bank to check)|r",
                            1, 1, 1, true
                        )
                    end
                end
            end
        end
    elseif actionData["$name"] then
        GameTooltip:SetText(actionData["$name"])
    end
    
    GameTooltip:Show()
end

-- ---------------------------------------------------------------------------
-- FLYOUT CONTAINER
-- ---------------------------------------------------------------------------

--- Retail DF+ and pre-DF retail: no secure mixins on the shell — child SecureActionButton slots still work.
local function GetFlyoutContainerFrameTemplate()
    if FLUX_API and FLUX_API.isRetail and (FLUX_API.isPostDF or FLUX_API.isPreDF) then
        return nil
    end
    return "SecureFrameTemplate,SecureHandlerStateTemplate"
end

--- Create a flyout container frame with Blizzard-style background
-- @return frame The flyout container
local function CreateFlyoutContainer()
    local index = #flyoutPool + 1
    local tmpl = GetFlyoutContainerFrameTemplate()
    local frame
    if tmpl then
        frame = CreateFrame("Frame", "FluxFlyoutContainer" .. index, UIParent, tmpl)
    else
        frame = CreateFrame("Frame", "FluxFlyoutContainer" .. index, UIParent)
    end
    
    frame.index = index
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(5500)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    
    -- Background textures (using Blizzard's flyout assets)
    frame.BgEnd = frame:CreateTexture(nil, "BACKGROUND")
    frame.BgEnd:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
    frame.BgEnd:SetSize(37, 22)
    frame.BgEnd:SetTexCoord(0.01562500, 0.59375000, 0.74218750, 0.91406250)
    
    frame.HorizBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.HorizBg:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton-FlyoutMidLeft")
    frame.HorizBg:SetHorizTile(true)
    frame.HorizBg:SetSize(32, 37)
    frame.HorizBg:SetTexCoord(0, 1, 0, 0.578125)
    
    frame.VertBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.VertBg:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton-FlyoutMid")
    frame.VertBg:SetVertTile(true)
    frame.VertBg:SetSize(37, 32)
    frame.VertBg:SetTexCoord(0, 0.578125, 0, 1)
    
    -- Store original background sizes for scaling
    frame.origBgEndW, frame.origBgEndH = frame.BgEnd:GetSize()
    frame.origHorizBgW, frame.origHorizBgH = frame.HorizBg:GetSize()
    frame.origVertBgW, frame.origVertBgH = frame.VertBg:GetSize()
    
    -- Create buttons
    frame.buttons = {}
    for i = 1, MAX_BUTTONS do
        local btn = CreateFlyoutButton(frame, index, i)
        btn:Hide()
        frame.buttons[i] = btn
    end
    
    -- Track state
    frame.direction = "UP"
    frame.parentButton = nil
    frame.actions = {}
    frame.config = nil
    
    -- Close proxy frame (for escape key handling)
    frame.closeProxy = CreateFrame("Frame", "FluxFlyoutContainer" .. index .. "CloseProxy")
    frame.closeProxy:HookScript("OnHide", function()
        if not InCombatLockdown() then
            FluxFlyoutFrame.CloseFlyout()
        end
    end)
    frame.closeProxy:Hide()
    table.insert(UISpecialFrames, frame.closeProxy:GetName())
    
    -- Mouse leave handler (with delay)
    frame.leaveTimer = nil
    frame:SetScript("OnEnter", function(self)
        if self.leaveTimer then
            self.leaveTimer:Cancel()
            self.leaveTimer = nil
        end
    end)
    
    frame:SetScript("OnLeave", function(self)
        -- Check if mouse is over any child button
        local isOverButton = false
        for _, btn in ipairs(self.buttons) do
            if btn:IsShown() and btn:IsMouseOver() then
                isOverButton = true
                break
            end
        end
        
        if not isOverButton and not self:IsMouseOver() then
            -- Start close timer
            if not self.leaveTimer then
                self.leaveTimer = C_Timer.NewTimer(0.3, function()
                    FluxFlyoutFrame.CloseFlyout()
                end)
            end
        end
    end)
    
    -- Show/Hide handlers
    frame:SetScript("OnShow", function(self)
        FluxFlyoutFrame.UpdateFlyoutBackground(self)
        self.closeProxy:Show()
    end)
    
    frame:SetScript("OnHide", function(self)
        self.closeProxy:Hide()
    end)
    
    -- Store animation state
    frame.isAnimating = false
    
    table.insert(flyoutPool, frame)
    return frame
end

--- Get or create a flyout container
-- @return frame An available flyout container
local function GetFlyoutContainer()
    -- Find an idle frame
    for _, frame in ipairs(flyoutPool) do
        if not frame:IsShown() then
            return frame
        end
    end
    -- Create new one if needed
    return CreateFlyoutContainer()
end

-- ---------------------------------------------------------------------------
-- FLYOUT BACKGROUND UPDATE
-- ---------------------------------------------------------------------------

--- Update the flyout background based on direction
-- @param frame The flyout frame
function FluxFlyoutFrame.UpdateFlyoutBackground(frame)
    local direction = frame.direction or "UP"
    local distance = frame.distance or 0
    local scale = frame.bgScale or 1.0
    local cellW = frame.cellW or BUTTON_SIZE
    local cellH = frame.cellH or BUTTON_SIZE
    -- X-only vs square reference: unsqueezed slot is ~cellH wide; squeezed main button is cellW × cellH.
    local wRatio = (cellH > 0) and (cellW / cellH) or 1
    
    frame.BgEnd:ClearAllPoints()
    
    -- Scale chrome in X by wRatio; Y uses bg scale only (matches row height / main button height).
    frame.BgEnd:SetSize(frame.origBgEndW * scale * wRatio, frame.origBgEndH * scale)
    frame.HorizBg:SetSize(frame.origHorizBgW * scale * wRatio, frame.origHorizBgH * scale)
    frame.VertBg:SetSize(frame.origVertBgW * scale * wRatio, frame.origVertBgH * scale)
    
    local dH = distance * wRatio
    
    if direction == "UP" then
        frame.BgEnd:SetPoint("TOP")
        SetClampedTextureRotation(frame.BgEnd, 0)
        frame.HorizBg:Hide()
        frame.VertBg:Show()
        frame.VertBg:ClearAllPoints()
        frame.VertBg:SetPoint("TOP", frame.BgEnd, "BOTTOM")
        frame.VertBg:SetPoint("BOTTOM", 0, distance)
    elseif direction == "DOWN" then
        frame.BgEnd:SetPoint("BOTTOM")
        SetClampedTextureRotation(frame.BgEnd, 180)
        frame.HorizBg:Hide()
        frame.VertBg:Show()
        frame.VertBg:ClearAllPoints()
        frame.VertBg:SetPoint("BOTTOM", frame.BgEnd, "TOP")
        frame.VertBg:SetPoint("TOP", 0, -distance)
    elseif direction == "LEFT" then
        frame.BgEnd:SetPoint("LEFT")
        SetClampedTextureRotation(frame.BgEnd, 270)
        frame.VertBg:Hide()
        frame.HorizBg:Show()
        frame.HorizBg:ClearAllPoints()
        frame.HorizBg:SetPoint("LEFT", frame.BgEnd, "RIGHT")
        frame.HorizBg:SetPoint("RIGHT", -dH, 0)
    elseif direction == "RIGHT" then
        frame.BgEnd:SetPoint("RIGHT")
        SetClampedTextureRotation(frame.BgEnd, 90)
        frame.VertBg:Hide()
        frame.HorizBg:Show()
        frame.HorizBg:ClearAllPoints()
        frame.HorizBg:SetPoint("RIGHT", frame.BgEnd, "LEFT")
        frame.HorizBg:SetPoint("LEFT", dH, 0)
    end
    
    -- Apply vertex color (slightly gray)
    local r, g, b = 0.7, 0.7, 0.7
    frame.HorizBg:SetVertexColor(r, g, b)
    frame.VertBg:SetVertexColor(r, g, b)
    frame.BgEnd:SetVertexColor(r, g, b)
end

-- ---------------------------------------------------------------------------
-- POSITIONING
-- ---------------------------------------------------------------------------

--- Calculate position for flyout based on parent button and direction
-- @param parentButton The button that triggered the flyout
-- @param direction "UP", "DOWN", "LEFT", "RIGHT"
-- @param numButtons Number of buttons to show
-- @return anchor, relPoint, x, y
local function CalculateFlyoutPosition(parentButton, direction, numButtons)
    if not parentButton then
        return "CENTER", UIParent, "CENTER", 0, 0
    end
    
    direction = direction or "UP"
    
    local buttonWidth = BUTTON_SIZE + BUTTON_SPACING
    local buttonHeight = BUTTON_SIZE + BUTTON_SPACING
    local totalPadding = BORDER_PADDING * 2
    
    local width, height
    
    if direction == "UP" or direction == "DOWN" then
        -- Vertical layout
        width = BUTTON_SIZE + totalPadding
        height = (numButtons * buttonHeight) - BUTTON_SPACING + totalPadding
    else
        -- Horizontal layout
        width = (numButtons * buttonWidth) - BUTTON_SPACING + totalPadding
        height = BUTTON_SIZE + totalPadding
    end
    
    local anchor, relPoint, offsetX, offsetY
    
    local g = FLYOUT_PARENT_GAP
    if direction == "UP" then
        anchor = "BOTTOM"
        relPoint = "TOP"
        offsetX = 0
        offsetY = g
    elseif direction == "DOWN" then
        anchor = "TOP"
        relPoint = "BOTTOM"
        offsetX = 0
        offsetY = -g
    elseif direction == "LEFT" then
        anchor = "RIGHT"
        relPoint = "LEFT"
        offsetX = -g
        offsetY = 0
    elseif direction == "RIGHT" then
        anchor = "LEFT"
        relPoint = "RIGHT"
        offsetX = g
        offsetY = 0
    end
    
    return anchor, relPoint, offsetX, offsetY, width, height
end

--- Helper function to identify if a button is a minimap button
-- @param button The button frame or widget
-- @return boolean
local function IsMinimapButton(button)
    if not button then return false end
    
    -- Check if button widget has the minimap flag
    if button.Widget and button.Widget._isMinimapButton then
        return true
    end
    
    -- Check if button's parent is the minimap buttons container
    local widget = button.Widget or button
    if widget then
        local parent = widget:GetParent()
        if parent and parent:GetName() == "FluxMinimapButtonsContainer" then
            return true
        end
    end
    
    return false
end

--- Determine best direction based on parent button screen position
-- @param parentButton The button that triggered the flyout
-- @return string direction - "UP", "DOWN", "LEFT", or "RIGHT"
local function DetermineBestDirection(parentButton)
    if not parentButton then return "UP" end
    
    -- Minimap buttons should always flyout UP
    if IsMinimapButton(parentButton) then
        return "UP"
    end
    
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local scale = parentButton:GetEffectiveScale() or 1
    
    local rawLeft = parentButton:GetLeft()
    local rawRight = parentButton:GetRight()
    local rawTop = parentButton:GetTop()
    local rawBottom = parentButton:GetBottom()
    if not rawLeft or not rawRight or not rawTop or not rawBottom then
        return "UP"
    end
    
    local left = rawLeft * scale
    local right = rawRight * scale
    local top = rawTop * scale
    local bottom = rawBottom * scale
    
    local centerX = (left + right) / 2
    local centerY = (top + bottom) / 2
    
    -- Prefer vertical directions
    local spaceAbove = screenHeight - top
    local spaceBelow = bottom
    
    if spaceAbove > spaceBelow and spaceAbove > 200 then
        return "UP"
    elseif spaceBelow > 200 then
        return "DOWN"
    end
    
    -- Fallback to horizontal
    local spaceLeft = left
    local spaceRight = screenWidth - right
    
    if spaceRight > spaceLeft then
        return "RIGHT"
    else
        return "LEFT"
    end
end

-- ---------------------------------------------------------------------------
-- FLYOUT LAYOUT
-- ---------------------------------------------------------------------------

--- Layout buttons in the flyout based on direction
-- @param flyout The flyout container
-- @param direction "UP", "DOWN", "LEFT", "RIGHT"
-- @param numButtons Number of visible buttons
local function LayoutFlyoutButtons(flyout, direction, numButtons)
    local scale = (flyout.cellH or flyout.buttonSize or BUTTON_SIZE) / BUTTON_SIZE
    local spacing = flyout.spacing
    if spacing == nil then
        spacing = ScaledFlyoutInterButtonGap(scale)
    end
    local initialSpacing = flyout.initialSpacing
    if initialSpacing == nil then
        initialSpacing = ScaledFlyoutInitialSpacing(scale)
    end
    local cellW = flyout.cellW or flyout.buttonSize or BUTTON_SIZE
    local cellH = flyout.cellH or flyout.buttonSize or BUTTON_SIZE
    
    local prevButton = nil
    
    for i, btn in ipairs(flyout.buttons) do
        if i <= numButtons then
            btn:ClearAllPoints()
            btn:SetSize(cellW, cellH)
            btn._fluxFlyoutCellW = cellW
            btn._fluxFlyoutCellH = cellH
            UpdateFlyoutButtonVisuals(btn)
            
            -- Position based on direction
            if direction == "UP" then
                if prevButton then
                    btn:SetPoint("BOTTOM", prevButton, "TOP", 0, spacing)
                else
                    btn:SetPoint("BOTTOM", flyout, "BOTTOM", 0, initialSpacing)
                end
            elseif direction == "DOWN" then
                if prevButton then
                    btn:SetPoint("TOP", prevButton, "BOTTOM", 0, -spacing)
                else
                    btn:SetPoint("TOP", flyout, "TOP", 0, -initialSpacing)
                end
            elseif direction == "LEFT" then
                if prevButton then
                    btn:SetPoint("RIGHT", prevButton, "LEFT", -spacing, 0)
                else
                    btn:SetPoint("RIGHT", flyout, "RIGHT", -initialSpacing, 0)
                end
            elseif direction == "RIGHT" then
                if prevButton then
                    btn:SetPoint("LEFT", prevButton, "RIGHT", spacing, 0)
                else
                    btn:SetPoint("LEFT", flyout, "LEFT", initialSpacing, 0)
                end
            end
            
            prevButton = btn
        end
    end
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

--- Show a flyout for a button
-- @param parentButton The button that triggered the flyout
-- @param actions Array of action data from generators
-- @param config Parsed flyout configuration (optional)
function FluxFlyoutFrame.ShowFlyout(parentButton, actions, config)
    if not actions or #actions == 0 then
        return
    end
    
    -- Don't modify UI in combat
    if InCombatLockdown() then
        return
    end
    
    -- Close if already open on same button (toggle behavior)
    if parentButton and activeFlyouts[parentButton] then
        FluxFlyoutFrame.CloseFlyoutFor(parentButton)
        return
    end
    
    -- Close any existing flyout
    FluxFlyoutFrame.CloseFlyout()
    
    -- Get flyout container
    local flyout = GetFlyoutContainer()
    
    -- Determine direction
    local direction
    -- Force UP direction for minimap buttons regardless of config
    if IsMinimapButton(parentButton) then
        direction = "UP"
    elseif config and config.direction then
        direction = config.direction
    else
        direction = DetermineBestDirection(parentButton)
    end
    
    flyout.direction = direction
    flyout.parentButton = parentButton
    flyout.actions = actions
    flyout.config = config
    
    local xF = FluxFlyoutFrame.GetDependentsHorizontalSqueezeFactor()
    flyout.squeezeXFactor = xF
    
    -- Cell matches main button: squeezed width × full height (same X factor as action bar / grid).
    local cellW, cellH = ResolveFlyoutCellDimensions(parentButton, config)
    flyout.cellW = cellW
    flyout.cellH = cellH
    flyout.buttonSize = cellH -- legacy single dimension (row height / icon size)
    local scale = cellH / BUTTON_SIZE
    local spacing = ScaledFlyoutInterButtonGap(scale)
    local initialSpacing = ScaledFlyoutInitialSpacing(scale)
    
    flyout.spacing = spacing
    flyout.initialSpacing = initialSpacing
    flyout.bgScale = scale
    flyout.distance = FLYOUT_FINAL_SPACING * scale
    
    -- Calculate size and position
    local numButtons = math.min(#actions, MAX_BUTTONS)
    local anchor, relPoint, offsetX, offsetY, width, height = 
        CalculateFlyoutPosition(parentButton, direction, numButtons)
    
    width, height = ComputeFlyoutPanelDimensions(direction, numButtons, cellW, cellH, spacing, initialSpacing, scale)
    
    flyout:SetSize(width, height)
    flyout:ClearAllPoints()
    
    if parentButton then
        -- Positioning Logic (matching old FluxCustomFlyout behavior):
        -- 1. For ExtraButtons (scrollable): Parent to the button so it moves with scroll
        --    and gets clipped by the scroll frame. Users can scroll to see the flyout.
        -- 2. For ActionBars (static): Parent to UIParent to float above everything.
        
        -- Parent to button only for scrollable Extra Buttons. Static NonCombat/Combat grids use
        -- SetClipsChildren on SlotFrame — parented flyouts are clipped invisible on all clients.
        -- When horizontal squeeze is on, float on UIParent. Retail DF+ ExtraButtons: float for hit-testing.
        local isScrollableExtra = FluxFlyoutFrame.IsScrollableExtraButtonsContext(parentButton)
        local squeezeActive = (xF < 0.999)
        local floatRetailDfExtra = (FLUX_API and FLUX_API.isPostDF and FLUX_API.isRetail and isScrollableExtra)
        local useParentedToButton = isScrollableExtra and not squeezeActive and not floatRetailDfExtra
        
        if useParentedToButton then
            -- SCROLLABLE CONTEXT: Parent to button so flyout is part of scroll content
            -- This allows:
            -- 1. Flyout to be clipped by scroll frame (stays inside)
            -- 2. User can scroll down to see the full flyout
            -- 3. Flyout moves with scroll content
            flyout:SetParent(parentButton)
            flyout:ClearAllPoints()  -- Clear points AFTER SetParent for clean anchoring
            flyout:SetScale(1.0)  -- Scale is inherited from parent
            
            -- CRITICAL: Disable clamping so flyout follows parent when scrolling off-screen
            flyout:SetClampedToScreen(false)
            
            -- Use HIGH strata (not FULLSCREEN_DIALOG) so scroll frame can clip it
            flyout:SetFrameStrata("HIGH")
            flyout:SetFrameLevel(parentButton:GetFrameLevel() + 100)
            
            -- Anchor flyout directly to button - this ensures flyout follows button when scrolling
            local g = FLYOUT_PARENT_GAP
            if direction == "UP" then
                flyout:SetPoint("BOTTOM", parentButton, "TOP", 0, g)
            elseif direction == "DOWN" then
                flyout:SetPoint("TOP", parentButton, "BOTTOM", 0, -g)
            elseif direction == "LEFT" then
                flyout:SetPoint("RIGHT", parentButton, "LEFT", -g, 0)
            elseif direction == "RIGHT" then
                flyout:SetPoint("LEFT", parentButton, "RIGHT", g, 0)
            end
            
            flyout.isExtraButtonFlyout = true
            
            -- Notify scroll content to expand for flyout height
            FluxFlyoutFrame.NotifyScrollContentExpand(flyout, parentButton, direction, height)
        else
            -- STATIC CONTEXT (ActionBars): Parent to UIParent to float above everything
            flyout:SetParent(UIParent)
            flyout:ClearAllPoints()  -- Clear points AFTER SetParent for clean anchoring
            flyout:SetScale(parentButton:GetEffectiveScale() / UIParent:GetEffectiveScale())
            
            -- Enable clamping for ActionBars to keep flyout on screen
            flyout:SetClampedToScreen(true)
            
            flyout:SetPoint(anchor, parentButton, relPoint, offsetX, offsetY)
            flyout.isExtraButtonFlyout = false
            
            -- ActionBars: Use FULLSCREEN_DIALOG to float above everything
            flyout:SetFrameStrata("FULLSCREEN_DIALOG")
            flyout:SetFrameLevel(5500)
        end
    else
        flyout:SetParent(UIParent)
        flyout:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    -- Layout and configure buttons
    LayoutFlyoutButtons(flyout, direction, numButtons)
    
    for i, btn in ipairs(flyout.buttons) do
        if i <= numButtons then
            -- Sizes set in LayoutFlyoutButtons (cellW × cellH from main button)
            -- Set flyoutParent so button can access flyout.parentButton
            btn.flyoutParent = flyout
            FluxFlyoutFrame.ConfigureButton(btn, actions[i], parentButton)
            btn:Show()
        else
            btn:Hide()
        end
    end
    
    -- Show flyout
    flyout:Show()
    activeFlyout = flyout
    
    -- Notify favorites system that flyout opened (for hooking)
    if FluxFlyoutFavorites and FluxFlyoutFavorites.OnFlyoutOpened then
        FluxFlyoutFavorites.OnFlyoutOpened(parentButton, flyout)
    end
    
    -- Track in map
    if parentButton then
        activeFlyouts[parentButton] = flyout
    end
    
    -- Update arrow on parent button to show "open" state
    if parentButton and parentButton.FluxFlyoutArrow then
        FluxFlyoutFrame.UpdateArrow(parentButton, direction, true)
    end
    
    -- Set checked state on parent button to show flyout is open
    if parentButton then
        if parentButton.SetChecked then
            parentButton:SetChecked(true)
        end
        -- Also show checked texture if it exists
        local checkedTexture = parentButton.GetCheckedTexture and parentButton:GetCheckedTexture()
        if checkedTexture then
            checkedTexture:Show()
        end
    end

    -- Optional: caller hook after buttons are visible (e.g. unit-frame spec flyout → profile submenus).
    if config and config.onAfterShow then
        pcall(config.onAfterShow, flyout, parentButton, actions, config)
    end
    
    -- Play sound
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
end

--- Close the currently open flyout
function FluxFlyoutFrame.CloseFlyout()
    -- Store local reference to prevent race conditions
    local flyout = activeFlyout
    if not flyout then return end
    
    -- Don't modify in combat
    if InCombatLockdown() then
        return
    end
    
    local parentButton = flyout.parentButton
    local direction = flyout.direction
    
    -- Restore scroll content height if this was an ExtraButton flyout
    if flyout.isExtraButtonFlyout then
        FluxFlyoutFrame.NotifyScrollContentRestore(flyout)
    end
    
    -- Cancel leave timer
    if flyout.leaveTimer then
        flyout.leaveTimer:Cancel()
        flyout.leaveTimer = nil
    end
    
    -- Hide all buttons
    if flyout.buttons then
        for _, btn in ipairs(flyout.buttons) do
            -- Hide any open edit boxes on reagent buttons
            if btn.editBox and btn.editBox:IsShown() then
                btn.editBox:ClearFocus()
                btn.editBox:Hide()
                if btn.count then btn.count:Show() end
            end
            btn:Hide()
            btn.actionData = nil
        end
    end
    
    -- Remove from tracking map
    if parentButton then
        activeFlyouts[parentButton] = nil
    end
    
    -- Clear global reference first
    activeFlyout = nil
    
    -- Hide flyout and reset parent to UIParent for reuse
    flyout:Hide()
    flyout:SetParent(UIParent)  -- Reset parent for next use
    flyout.parentButton = nil
    flyout.actions = {}
    flyout.config = nil
    flyout.isExtraButtonFlyout = nil
    
    -- Update arrow on parent button to show "closed" state
    if parentButton and parentButton.FluxFlyoutArrow then
        FluxFlyoutFrame.UpdateArrow(parentButton, direction or "UP", false)
    end
    
    -- Remove checked state from parent button when flyout closes
    if parentButton then
        if parentButton.SetChecked then
            parentButton:SetChecked(false)
        end
        -- Also hide checked texture if it exists
        local checkedTexture = parentButton.GetCheckedTexture and parentButton:GetCheckedTexture()
        if checkedTexture then
            checkedTexture:Hide()
        end
    end
end

--- Close the flyout for a specific button
-- @param parentButton The button whose flyout to close
function FluxFlyoutFrame.CloseFlyoutFor(parentButton)
    if not parentButton then return end
    
    local flyout = activeFlyouts[parentButton]
    if not flyout then return end
    
    -- Don't modify in combat
    if InCombatLockdown() then
        return
    end
    
    local direction = flyout.direction
    
    -- Restore scroll content height if this was an ExtraButton flyout
    if flyout.isExtraButtonFlyout then
        FluxFlyoutFrame.NotifyScrollContentRestore(flyout)
    end
    
    -- Cancel leave timer
    if flyout.leaveTimer then
        flyout.leaveTimer:Cancel()
        flyout.leaveTimer = nil
    end
    
    -- Hide all buttons
    for _, btn in ipairs(flyout.buttons) do
        -- Hide any open edit boxes on reagent buttons
        if btn.editBox and btn.editBox:IsShown() then
            btn.editBox:ClearFocus()
            btn.editBox:Hide()
            if btn.count then btn.count:Show() end
        end
        btn:Hide()
        btn.actionData = nil
    end
    
    -- Remove from tracking map
    activeFlyouts[parentButton] = nil
    
    -- Clear active if this was it
    if activeFlyout == flyout then
        activeFlyout = nil
    end
    
    -- Hide flyout and reset parent to UIParent for reuse
    flyout:Hide()
    flyout:SetParent(UIParent)  -- Reset parent for next use
    flyout.parentButton = nil
    flyout.actions = {}
    flyout.config = nil
    flyout.isExtraButtonFlyout = nil
    
    -- Update arrow on parent button to show "closed" state
    if parentButton.FluxFlyoutArrow then
        FluxFlyoutFrame.UpdateArrow(parentButton, direction or "UP", false)
    end
    
    -- Remove checked state from parent button when flyout closes
    if parentButton then
        if parentButton.SetChecked then
            parentButton:SetChecked(false)
        end
        -- Also hide checked texture if it exists
        local checkedTexture = parentButton.GetCheckedTexture and parentButton:GetCheckedTexture()
        if checkedTexture then
            checkedTexture:Hide()
        end
    end
end

--- Close all open flyouts
function FluxFlyoutFrame.CloseAllFlyouts()
    for parentButton, flyout in pairs(activeFlyouts) do
        FluxFlyoutFrame.CloseFlyoutFor(parentButton)
    end
    
    -- Also close the single active flyout if not in map
    if activeFlyout then
        FluxFlyoutFrame.CloseFlyout()
    end
end

--- Check if a flyout is currently open
-- @return boolean
function FluxFlyoutFrame.IsOpen()
    return activeFlyout ~= nil and activeFlyout:IsShown()
end

--- Get the currently active flyout
-- @return frame or nil
function FluxFlyoutFrame.GetActiveFlyout()
    return activeFlyout
end

--- Toggle flyout for a button
-- @param parentButton The button that triggered the flyout
-- @param actions Array of action data
-- @param config Parsed configuration
function FluxFlyoutFrame.ToggleFlyout(parentButton, actions, config)
    -- Check both tracking mechanisms
    local isOpenForButton = (activeFlyout and activeFlyout.parentButton == parentButton) or
                            (parentButton and activeFlyouts[parentButton])
    
    if isOpenForButton then
        -- Close using the appropriate method
        if parentButton and activeFlyouts[parentButton] then
            FluxFlyoutFrame.CloseFlyoutFor(parentButton)
        elseif activeFlyout then
            FluxFlyoutFrame.CloseFlyout()
        end
    else
        FluxFlyoutFrame.ShowFlyout(parentButton, actions, config)
    end
end

--- Update cooldowns, counts, and equipped state for all visible buttons
function FluxFlyoutFrame.UpdateCooldowns()
    if not activeFlyout or not activeFlyout:IsShown() then
        return
    end
    
    for _, btn in ipairs(activeFlyout.buttons) do
        if btn:IsShown() then
            FluxFlyoutFrame.UpdateButtonCooldown(btn)
            FluxFlyoutFrame.UpdateButtonCount(btn)
            FluxFlyoutFrame.UpdateButtonUsability(btn)
            FluxFlyoutFrame.UpdateButtonEquipped(btn)
        end
    end
end

--- Refresh the flyout with new actions (for dynamic content)
-- @param actions New array of action data
function FluxFlyoutFrame.RefreshActions(actions)
    if not activeFlyout or not activeFlyout:IsShown() then
        return
    end
    
    if InCombatLockdown() then
        return
    end
    
    activeFlyout.actions = actions
    local numButtons = math.min(#actions, MAX_BUTTONS)
    local parentButton = activeFlyout.parentButton
    local dir = activeFlyout.direction or "UP"
    local cfg = activeFlyout.config
    local xF = FluxFlyoutFrame.GetDependentsHorizontalSqueezeFactor()
    activeFlyout.squeezeXFactor = xF
    
    local cw, ch = ResolveFlyoutCellDimensions(parentButton, cfg)
    activeFlyout.cellW = cw
    activeFlyout.cellH = ch
    activeFlyout.buttonSize = ch
    local scale = ch / BUTTON_SIZE
    activeFlyout.bgScale = scale
    activeFlyout.spacing = ScaledFlyoutInterButtonGap(scale)
    activeFlyout.initialSpacing = ScaledFlyoutInitialSpacing(scale)
    activeFlyout.distance = FLYOUT_FINAL_SPACING * scale
    
    local spacing = activeFlyout.spacing
    
    -- Reconfigure buttons (pass parentButton for favorites context)
    for i, btn in ipairs(activeFlyout.buttons) do
        if i <= numButtons then
            FluxFlyoutFrame.ConfigureButton(btn, actions[i], parentButton)
            btn:Show()
        else
            btn:Hide()
        end
    end
    
    local width, height = ComputeFlyoutPanelDimensions(dir, numButtons, cw, ch, spacing, activeFlyout.initialSpacing, scale)
    activeFlyout:SetSize(width, height)
    FluxFlyoutFrame.UpdateFlyoutBackground(activeFlyout)
    LayoutFlyoutButtons(activeFlyout, dir, numButtons)
end

--- Called when action bar / grids re-layout horizontal squeeze (min UI scale). Repositions open flyout.
function FluxFlyoutFrame.OnDependentsLayoutChanged()
    if InCombatLockdown() then return end
    local fo = activeFlyout
    if not fo or not fo:IsShown() or not fo.parentButton then return end
    local actions = fo.actions
    if not actions or #actions == 0 then return end
    
    local p = fo.parentButton
    local cfg = fo.config
    local cw, ch = ResolveFlyoutCellDimensions(p, cfg)
    fo.cellW = cw
    fo.cellH = ch
    fo.buttonSize = ch
    local scale = ch / BUTTON_SIZE
    fo.bgScale = scale
    fo.spacing = ScaledFlyoutInterButtonGap(scale)
    fo.initialSpacing = ScaledFlyoutInitialSpacing(scale)
    fo.distance = FLYOUT_FINAL_SPACING * scale
    fo.squeezeXFactor = FluxFlyoutFrame.GetDependentsHorizontalSqueezeFactor()
    
    local dir = fo.direction or "UP"
    local numButtons = math.min(#actions, MAX_BUTTONS)
    local spacing = fo.spacing
    local width, height = ComputeFlyoutPanelDimensions(dir, numButtons, cw, ch, spacing, fo.initialSpacing, scale)
    fo:SetSize(width, height)
    FluxFlyoutFrame.UpdateFlyoutBackground(fo)
    LayoutFlyoutButtons(fo, dir, numButtons)
    for i, btn in ipairs(fo.buttons) do
        if i <= numButtons and actions[i] then
            FluxFlyoutFrame.ConfigureButton(btn, actions[i], p)
            btn:Show()
        else
            btn:Hide()
        end
    end
    if p.FluxFlyoutArrow then
        FluxFlyoutFrame.UpdateArrow(p, dir, true)
    end
end

-- ---------------------------------------------------------------------------
-- CLEANUP
-- ---------------------------------------------------------------------------

--- Destroy all flyout frames (for reload/logout)
function FluxFlyoutFrame.Cleanup()
    FluxFlyoutFrame.CloseFlyout()

    for _, flyout in ipairs(flyoutPool) do
        for _, btn in ipairs(flyout.buttons) do
            btn:Hide()
        end
        flyout:Hide()
    end
end

-- ---------------------------------------------------------------------------
-- DEBUG
-- ---------------------------------------------------------------------------

function FluxFlyoutFrame.Test()
    print("|cff00ffff[FluxFlyoutFrame]|r Testing flyout display...")
    
    -- Create some test actions
    local testActions = {
        {
            ["$iconTexture"] = "Interface\\Icons\\INV_Misc_Rune_01",
            ["$name"] = "Test Spell 1",
            ["type"] = "macro",
            ["macrotext"] = "/say Test 1",
        },
        {
            ["$iconTexture"] = "Interface\\Icons\\INV_Misc_Rune_02",
            ["$name"] = "Test Spell 2",
            ["type"] = "macro",
            ["macrotext"] = "/say Test 2",
        },
        {
            ["$iconTexture"] = "Interface\\Icons\\INV_Misc_Rune_03",
            ["$name"] = "Test Spell 3",
            ["type"] = "macro",
            ["macrotext"] = "/say Test 3",
        },
    }
    
    -- Show flyout at screen center
    FluxFlyoutFrame.ShowFlyout(nil, testActions, { direction = "UP" })
end

-- ---------------------------------------------------------------------------
-- FLYOUT ARROW SYSTEM
-- ---------------------------------------------------------------------------
-- FluxUnifiedBorderFrame is MEDIUM ~8; FluxBorder atlas lives in FluxBorderFrame at parentLevel+10 (sibling order inside UB).
-- Parent the arrow to UB above FluxBorderFrame so it draws on top of the atlas; UIParent fallback when UB is absent/hidden.
local FLUX_FLYOUT_ARROW_STRATA = "MEDIUM"
local FLUX_FLYOUT_ARROW_FRAME_LEVEL = 9 -- UIParent fallback only; below FluxWindowFrame (10) on UIParent
local FLUX_FLYOUT_ARROW_ABOVE_BORDER_ART = 5 -- arrow level = FluxBorderFrame:GetFrameLevel() + this

-- Widgets with a visible Flux flyout arrow (refresh layering when unified border appears/updates)
local flyoutArrowAnchorWidgets = {}

--- Parent/strata/level/scale so the arrow draws above the unified atlas border without FULLSCREEN_DIALOG.
-- @param arrowFrame Arrow frame (FluxFlyoutArrow or TrinketMenu arrow)
-- @param anchorWidget Button widget to match effective scale and anchor against
function FluxFlyoutFrame.ConfigureArrowLayer(arrowFrame, anchorWidget)
    if not arrowFrame or not anchorWidget then return end
    local ub = _G["FluxUnifiedBorderFrame"]
    local borderArt = ub and ub.FluxBorderFrame
    if ub and ub:IsShown() and borderArt then
        arrowFrame:SetParent(ub)
        arrowFrame:SetFrameStrata(ub:GetFrameStrata())
        local bLevel = borderArt:GetFrameLevel() or 0
        arrowFrame:SetFrameLevel(math.min(bLevel + FLUX_FLYOUT_ARROW_ABOVE_BORDER_ART, 65535))
    else
        arrowFrame:SetParent(UIParent)
        arrowFrame:SetFrameStrata(FLUX_FLYOUT_ARROW_STRATA)
        arrowFrame:SetFrameLevel(FLUX_FLYOUT_ARROW_FRAME_LEVEL)
    end
    arrowFrame:SetScale(anchorWidget:GetEffectiveScale() / UIParent:GetEffectiveScale())
end

--- Called when FluxUnifiedBorderFrame shows or after UpdateBorder; reparents arrows onto the border above atlas art.
function FluxFlyoutFrame.OnUnifiedBorderFrameShow()
    for widget in pairs(flyoutArrowAnchorWidgets) do
        if widget and widget.FluxFlyoutArrow and widget.FluxFlyoutArrow:IsShown() then
            local d = widget._fluxArrowLastDirection or "UP"
            local isOpen = FluxFlyoutFrame.IsFlyoutOpenFor(widget)
            FluxFlyoutFrame.UpdateArrow(widget, d, isOpen)
        end
    end
end

--- Create a flyout arrow for a button widget
-- @param widget The button widget to attach arrow to
-- @return arrowFrame The arrow frame
function FluxFlyoutFrame.CreateArrow(widget)
    if not widget then return nil end
    if widget.FluxFlyoutArrow then return widget.FluxFlyoutArrow end
    
    local arrowFrame = CreateFrame("Frame", nil, widget)
    local xF0 = FluxFlyoutFrame.GetDependentsHorizontalSqueezeFactor()
    arrowFrame:SetSize(math.max(10, ARROW_SIZE_W * xF0), ARROW_SIZE_H)
    
    local arrowTex = arrowFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    arrowTex:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
    arrowTex:SetAllPoints()
    arrowTex:SetTexCoord(unpack(ARROW_TEX_COORDS))
    
    arrowFrame.texture = arrowTex
    widget.FluxFlyoutArrow = arrowFrame
    
    -- Don't hide by default - let ShowArrow/HideArrow control visibility
    -- This matches the old working FluxCustomFlyout behavior
    -- Hide will be called by UpdateFluxButtonArrow if button has no flyout
    
    return arrowFrame
end

--- Update the flyout arrow position and rotation
-- @param widget The button widget
-- @param direction "UP", "DOWN", "LEFT", "RIGHT"
-- @param isOpen Whether the flyout is currently open
function FluxFlyoutFrame.UpdateArrow(widget, direction, isOpen)
    if not widget then return end
    widget._fluxArrowLastDirection = direction
    
    local arrow = widget.FluxFlyoutArrow
    if not arrow then
        arrow = FluxFlyoutFrame.CreateArrow(widget)
    end
    if not arrow then return end
    
    local tex = arrow.texture or arrow
    local baseOffset = 6
    local xF = FluxFlyoutFrame.GetDependentsHorizontalSqueezeFactor()
    -- Match squeezed button width in screen space without shrinking the glyph to a 1px sliver
    local aw = math.max(10, ARROW_SIZE_W * xF)
    arrow:SetSize(aw, ARROW_SIZE_H)
    
    -- Layering handled in ConfigureArrowLayer (above FluxBorder art when unified border is shown).
    FluxFlyoutFrame.ConfigureArrowLayer(arrow, widget)
    
    arrow:ClearAllPoints()
    
    -- Position and rotate based on direction
    if direction == "LEFT" then
        arrow:SetPoint("LEFT", widget, "LEFT", -baseOffset, 0)
        SetClampedTextureRotation(tex, isOpen and 90 or 270)
    elseif direction == "RIGHT" then
        arrow:SetPoint("RIGHT", widget, "RIGHT", baseOffset, 0)
        SetClampedTextureRotation(tex, isOpen and 270 or 90)
    elseif direction == "DOWN" then
        arrow:SetPoint("BOTTOM", widget, "BOTTOM", 0, -baseOffset)
        SetClampedTextureRotation(tex, isOpen and 0 or 180)
    else  -- UP (default)
        arrow:SetPoint("TOP", widget, "TOP", 0, baseOffset)
        SetClampedTextureRotation(tex, isOpen and 180 or 0)
    end
end

--- Show the flyout arrow on a button
-- @param widget The button widget
-- @param direction The direction to show
function FluxFlyoutFrame.ShowArrow(widget, direction)
    if not widget then return end
    
    local arrow = widget.FluxFlyoutArrow
    if not arrow then
        arrow = FluxFlyoutFrame.CreateArrow(widget)
    end
    if not arrow then return end
    
    -- Check both tracking mechanisms for open state
    local isOpen = FluxFlyoutFrame.IsFlyoutOpenFor(widget)
    
    -- Update arrow position and rotation
    FluxFlyoutFrame.UpdateArrow(widget, direction, isOpen)
    
    -- Ensure arrow is visible - critical for pre-DF clients where arrow may have been hidden
    arrow:Show()
    
    -- Ensure arrow texture is also visible
    if arrow.texture then
        arrow.texture:Show()
    end
    
    flyoutArrowAnchorWidgets[widget] = true
end

--- Hide the flyout arrow on a button
-- @param widget The button widget
function FluxFlyoutFrame.HideArrow(widget)
    if not widget then return end
    
    flyoutArrowAnchorWidgets[widget] = nil
    
    local arrow = widget.FluxFlyoutArrow
    if arrow then
        arrow:Hide()
    end
end

--- Clear the flyout arrow from a button
-- @param widget The button widget
function FluxFlyoutFrame.ClearArrow(widget)
    if not widget then return end
    
    flyoutArrowAnchorWidgets[widget] = nil
    
    if widget.FluxFlyoutArrow then
        widget.FluxFlyoutArrow:Hide()
        -- Don't destroy, just hide for reuse
    end
end

-- ---------------------------------------------------------------------------
-- ACTIVE FLYOUT TRACKING
-- ---------------------------------------------------------------------------

--- Get the flyout for a specific parent button
-- @param parentButton The button to check
-- @return flyoutFrame or nil
function FluxFlyoutFrame.GetFlyoutForButton(parentButton)
    -- Check both tracking mechanisms
    if activeFlyouts[parentButton] then
        return activeFlyouts[parentButton]
    end
    if activeFlyout and activeFlyout.parentButton == parentButton then
        return activeFlyout
    end
    return nil
end

--- Check if a button has an open flyout
-- @param parentButton The button to check
-- @return boolean
function FluxFlyoutFrame.IsFlyoutOpenFor(parentButton)
    -- Check both tracking mechanisms
    if activeFlyouts[parentButton] and activeFlyouts[parentButton]:IsShown() then
        return true
    end
    if activeFlyout and activeFlyout.parentButton == parentButton and activeFlyout:IsShown() then
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- DEBUG / TEST
-- ---------------------------------------------------------------------------

SLASH_FLYOUTFRAME1 = "/flyoutframe"
SlashCmdList["FLYOUTFRAME"] = function(msg)
    if msg == "close" then
        FluxFlyoutFrame.CloseFlyout()
    else
        FluxFlyoutFrame.Test()
    end
end

