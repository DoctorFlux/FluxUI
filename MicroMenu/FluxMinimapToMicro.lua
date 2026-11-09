-- FluxMinimapToMicro.lua
-- Converts addon minimap buttons into micro menu buttons
-- Supports account-wide and character-specific configurations
if not FluxMicroMenu or not FluxMicroMenu.CreateMicroButton then return end

-- ---------------------------------------------------------------------------
-- Module Setup
-- ---------------------------------------------------------------------------
FluxMinimapToMicro = FluxMinimapToMicro or {}
local M = FluxMinimapToMicro

-- Constants
local BUTTON_SIZE = 32
local BUTTON_SPACING = 2
local PADDING = 6
local BUTTONS_PER_ROW = 4

-- Tint colors for modes
local TINT_COLORS = {
    off = nil, -- No tint
    character = { r = 1, g = 0.82, b = 0, a = 0.4 },    -- Yellow
    account = { r = 0, g = 1, b = 0.4, a = 0.4 },       -- Green
}

-- State
M.scannedButtons = {}       -- All discovered minimap buttons
M.buttonNameMap = {}        -- Quick lookup: button -> true
M.configPopupFrame = nil    -- The right-click config popup
M.isConfigShown = false     -- Config popup visibility state
M.createdMicroButtons = {}  -- Dynamically created micro buttons
M.isUpdating = false        -- Prevent infinite loops
M.isDragging = false        -- Prevent popup from closing during drag

-- Capture original frame methods (MBB style)
local SetPoint = UIParent.SetPoint
local ClearAllPoints = UIParent.ClearAllPoints

-- ---------------------------------------------------------------------------
-- SavedVariables Handling
-- ---------------------------------------------------------------------------

local function EnsureSavedVars()
    -- Account-wide
    if not FluxUI_DB then
        FluxUI_DB = {}
    end
    if not FluxUI_DB.MinimapToMicro then
        FluxUI_DB.MinimapToMicro = {
            buttons = {},       -- { [buttonName] = { order = N } }
            orderList = {},     -- Ordered list of button names
        }
    end
    
    -- Character-specific
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    if not _FluxUI_CharSavedVars.MinimapToMicro then
        _FluxUI_CharSavedVars.MinimapToMicro = {
            buttons = {},       -- { [buttonName] = { order = N } }
        }
    end
end

--- Clear account + character minimap-to-micro toggles and order (used by MicroMenu factory reset).
function M:WipeAllButtonSavedState()
    EnsureSavedVars()
    wipe(FluxUI_DB.MinimapToMicro.buttons)
    wipe(_FluxUI_CharSavedVars.MinimapToMicro.buttons)
    FluxUI_DB.MinimapToMicro.orderList = {}
end

-- Check if button is enabled for account
function M:IsAccountEnabled(buttonName)
    EnsureSavedVars()
    return FluxUI_DB.MinimapToMicro.buttons[buttonName] ~= nil
end

-- Check if button is enabled for character
function M:IsCharacterEnabled(buttonName)
    EnsureSavedVars()
    return _FluxUI_CharSavedVars.MinimapToMicro.buttons[buttonName] ~= nil
end

-- Check if button is enabled (either mode)
function M:IsEnabled(buttonName)
    return self:IsAccountEnabled(buttonName) or self:IsCharacterEnabled(buttonName)
end

-- Get the mode for a button: "off", "character", or "account"
function M:GetMode(buttonName)
    if self:IsCharacterEnabled(buttonName) then
        return "character"
    elseif self:IsAccountEnabled(buttonName) then
        return "account"
    end
    return "off"
end

-- Enable button for account
function M:EnableForAccount(buttonName)
    EnsureSavedVars()
    
    -- Ensure buttons are scanned
    if #self.scannedButtons == 0 then
        self:ScanButtons(true)
    end
    
    -- Get natural position in full list
    local naturalPos = self:GetNaturalPosition(buttonName)
    
    -- Count how many enabled buttons come before this position
    local enabledBefore = 0
    for i = 1, naturalPos - 1 do
        if self.scannedButtons[i] then
            local otherName = self.scannedButtons[i].name
            if self:IsEnabled(otherName) then
                enabledBefore = enabledBefore + 1
            end
        end
    end
    
    local newOrder = enabledBefore + 1
    
    -- Reassign orders for enabled buttons after this position
    for i = naturalPos + 1, #self.scannedButtons do
        if self.scannedButtons[i] then
            local otherName = self.scannedButtons[i].name
            if self:IsEnabled(otherName) then
                local currentOrder = self:GetButtonOrder(otherName)
                if currentOrder >= newOrder then
                    self:SetButtonOrder(otherName, currentOrder + 1)
                end
            end
        end
    end
    
    FluxUI_DB.MinimapToMicro.buttons[buttonName] = { order = newOrder }
    self:UpdateOrderList()
end

-- Disable button for account
function M:DisableForAccount(buttonName)
    EnsureSavedVars()
    FluxUI_DB.MinimapToMicro.buttons[buttonName] = nil
    self:UpdateOrderList()
end

-- Enable button for character
function M:EnableForCharacter(buttonName)
    EnsureSavedVars()
    
    -- Ensure buttons are scanned
    if #self.scannedButtons == 0 then
        self:ScanButtons(true)
    end
    
    -- Get natural position in full list
    local naturalPos = self:GetNaturalPosition(buttonName)
    
    -- Count how many enabled buttons come before this position
    local enabledBefore = 0
    for i = 1, naturalPos - 1 do
        if self.scannedButtons[i] then
            local otherName = self.scannedButtons[i].name
            if self:IsEnabled(otherName) then
                enabledBefore = enabledBefore + 1
            end
        end
    end
    
    local newOrder = enabledBefore + 1
    
    -- Reassign orders for enabled buttons after this position
    for i = naturalPos + 1, #self.scannedButtons do
        if self.scannedButtons[i] then
            local otherName = self.scannedButtons[i].name
            if self:IsEnabled(otherName) then
                local currentOrder = self:GetButtonOrder(otherName)
                if currentOrder >= newOrder then
                    self:SetButtonOrder(otherName, currentOrder + 1)
                end
            end
        end
    end
    
    _FluxUI_CharSavedVars.MinimapToMicro.buttons[buttonName] = { order = newOrder }
    self:UpdateOrderList()
end

-- Disable button for character
function M:DisableForCharacter(buttonName)
    EnsureSavedVars()
    _FluxUI_CharSavedVars.MinimapToMicro.buttons[buttonName] = nil
    self:UpdateOrderList()
end

-- Get next available order number (legacy, kept for compatibility)
function M:GetNextOrder()
    EnsureSavedVars()
    local maxOrder = 0
    
    for _, data in pairs(FluxUI_DB.MinimapToMicro.buttons) do
        if data.order and data.order > maxOrder then
            maxOrder = data.order
        end
    end
    for _, data in pairs(_FluxUI_CharSavedVars.MinimapToMicro.buttons) do
        if data.order and data.order > maxOrder then
            maxOrder = data.order
        end
    end
    
    return maxOrder + 1
end

-- Get natural position of button in the full scanned list
function M:GetNaturalPosition(buttonName)
    -- Ensure buttons are scanned
    if #self.scannedButtons == 0 then
        self:ScanButtons(true)
    end
    
    -- Find position in scanned buttons (sorted list)
    for i, data in ipairs(self.scannedButtons) do
        if data.name == buttonName then
            return i
        end
    end
    
    -- Not found, return position after all scanned buttons
    return #self.scannedButtons + 1
end

-- Update the unified order list
function M:UpdateOrderList()
    EnsureSavedVars()
    
    local allButtons = {}
    
    -- Collect all enabled buttons with their orders
    for name, data in pairs(FluxUI_DB.MinimapToMicro.buttons) do
        table.insert(allButtons, { name = name, order = data.order or 999 })
    end
    for name, data in pairs(_FluxUI_CharSavedVars.MinimapToMicro.buttons) do
        -- Don't duplicate if already in account (shouldn't happen but safety)
        local found = false
        for _, btn in ipairs(allButtons) do
            if btn.name == name then found = true break end
        end
        if not found then
            table.insert(allButtons, { name = name, order = data.order or 999 })
        end
    end
    
    -- Sort by order
    table.sort(allButtons, function(a, b) return a.order < b.order end)
    
    -- Update order list
    local orderList = {}
    for _, btn in ipairs(allButtons) do
        table.insert(orderList, btn.name)
    end
    
    FluxUI_DB.MinimapToMicro.orderList = orderList
end

-- Get ordered list of enabled buttons
function M:GetEnabledButtonsOrdered()
    EnsureSavedVars()
    self:UpdateOrderList()
    return FluxUI_DB.MinimapToMicro.orderList or {}
end

-- Set order for a button
function M:SetButtonOrder(buttonName, newOrder)
    EnsureSavedVars()
    
    if FluxUI_DB.MinimapToMicro.buttons[buttonName] then
        FluxUI_DB.MinimapToMicro.buttons[buttonName].order = newOrder
    elseif _FluxUI_CharSavedVars.MinimapToMicro.buttons[buttonName] then
        _FluxUI_CharSavedVars.MinimapToMicro.buttons[buttonName].order = newOrder
    end
    
    self:UpdateOrderList()
end

-- Get the current order value for a button
function M:GetButtonOrder(buttonName)
    EnsureSavedVars()
    if FluxUI_DB.MinimapToMicro.buttons[buttonName] then
        return FluxUI_DB.MinimapToMicro.buttons[buttonName].order or 999
    elseif _FluxUI_CharSavedVars.MinimapToMicro.buttons[buttonName] then
        return _FluxUI_CharSavedVars.MinimapToMicro.buttons[buttonName].order or 999
    end
    return 999
end

-- Cycle mode: off -> account -> character -> off
function M:CycleMode(buttonName)
    local mode = self:GetMode(buttonName)
    
    if mode == "off" then
        self:EnableForAccount(buttonName)
    elseif mode == "account" then
        local currentOrder = self:GetButtonOrder(buttonName)
        self:DisableForAccount(buttonName)
        EnsureSavedVars()
        _FluxUI_CharSavedVars.MinimapToMicro.buttons[buttonName] = { order = currentOrder }
        self:UpdateOrderList()
    elseif mode == "character" then
        self:DisableForCharacter(buttonName)
        local safeName = buttonName:gsub("[^%w]", "_")
        local globalName = "FluxMinimap2Micro_" .. safeName .. "MicroButton"
        if _G[globalName] then
            _G[globalName]:Hide()
            if _G.BUTTON_PRIORITIES then
                _G.BUTTON_PRIORITIES[globalName] = nil
            end
        end
    end
    
    -- Rebuild micro buttons (will recreate enabled ones, remove disabled ones)
    self:RebuildMicroButtons()
    
    -- Update config popup if shown
    if self.isConfigShown then
        self:UpdateConfigPopupTints()
    end
    
    -- Update left-click popup filter
    if FluxAddonSystem and FluxAddonSystem.isShown then
        FluxAddonSystem:UpdateLayout()
    end
end

-- ---------------------------------------------------------------------------
-- Button Scanner (reuses validator from FluxAddonMicroButton when present)
-- ---------------------------------------------------------------------------

local MINIMAP_BUTTON_PATTERNS = {
    "^LibDBIcon10_",
    "MinimapButton",
    "MinimapFrame",
    "MinimapIcon",
    "[-_]Minimap[-_]",
    "Minimap$"
}

local EXCLUDED_BUTTONS = {
    "Minimap",
    "MinimapCluster",
    "MinimapBackdrop",
    "MinimapContainer",
    "LFG_MinimapEye",
    "QueueStatusMinimapButton",
    "MiniMapTracking",
    "MiniMapTrackingButton",
    "MiniMapVoiceChatFrame",
    "TimeManagerClockButton",
    "GameTimeFrame",
    "GarrisonLandingPageMinimapButton",
    "ExpansionLandingPageMinimapButton",
    "MiniMapMailFrame",
    "MiniMapBattlefieldFrame",
    "FeedbackUIButton",
    "HelpOpenTicketButton",
    "COHCMinimapButton",
    "MinimapZoomIn",
    "MinimapZoomOut",
}

local function IsForeverClient()
    return (FLUX_API and (FLUX_API.isCamelot or FLUX_API.isForever)) == true
end

local function IsExcluded(name)
    if not name then return false end
    for _, excluded in ipairs(EXCLUDED_BUTTONS) do
        if name == excluded or string.match(name, "^LFG") then return true end
    end
    return false
end

local function NameLooksLikeMinimapButton(name)
    if FluxAddonSystem and FluxAddonSystem.NameLooksLikeMinimapButton then
        return FluxAddonSystem.NameLooksLikeMinimapButton(name)
    end
    if type(name) ~= "string" or name == "" then return false end
    if IsExcluded(name) then return false end
    for _, pattern in ipairs(MINIMAP_BUTTON_PATTERNS) do
        if string.match(name, pattern) then return true end
    end
    if string.match(name, "^TomCats%-") then return true end
    return false
end

--- Human-readable label for a minimap button key (matches live micro bar tooltip title).
function M:GetFriendlyMinimapButtonName(buttonName)
    if not buttonName then return "" end
    return tostring(buttonName):gsub("^LibDBIcon10_", ""):gsub("MinimapButton$", ""):gsub("Minimap$", "")
end

local function IsValidMinimapButton(frame)
    if FluxAddonSystem and FluxAddonSystem.IsValidMinimapButton then
        return FluxAddonSystem.IsValidMinimapButton(frame)
    end
    if not frame then return false end
    local t = type(frame)
    if t ~= "table" and t ~= "userdata" then return false end
    if frame.IsForbidden then
        local okForbidden, forbidden = pcall(frame.IsForbidden, frame)
        if okForbidden and forbidden then return false end
    end
    if not frame.IsObjectType then return false end
    local okFrame, isFrame = pcall(frame.IsObjectType, frame, "Frame")
    if not (okFrame and isFrame) then
        local okBtn, isBtn = pcall(frame.IsObjectType, frame, "Button")
        if not (okBtn and isBtn) then return false end
    end
    if not frame.GetName then return false end
    local ok, name = pcall(frame.GetName, frame)
    if not ok or not name then return false end
    return NameLooksLikeMinimapButton(name)
end

-- Packing Minimap:GetChildren() onto the Lua stack overflows when the child
-- list is huge or ScanButtons is already nested (SetParent / layout hooks).
local GETCHILDREN_PACK_CAP = 250

local function CollectDirectMinimapChildren(parent)
    if not parent or not parent.GetChildren then
        return {}
    end
    local n = parent.GetNumChildren and parent:GetNumChildren() or nil
    local tooMany = type(n) == "number" and n > GETCHILDREN_PACK_CAP
    if not tooMany then
        local ok, pack = pcall(function()
            return { parent:GetChildren() }
        end)
        if ok and type(pack) == "table" then
            return pack
        end
    end
    -- Do not EnumerateFrames here: Forever's cluster can exceed the pack cap, and
    -- walking 20k UI frames per scan hitchs. Fall through to LibDBIcon / harvest.
    local ok, pack = pcall(function()
        return { parent:GetChildren() }
    end)
    if ok and type(pack) == "table" then
        return pack
    end
    return {}
end

local function GetMinimapScanRoots()
    if FluxAddonSystem and FluxAddonSystem.GetMinimapScanRoots then
        return FluxAddonSystem.GetMinimapScanRoots()
    end
    return { _G.Minimap, _G.MinimapCluster, _G.MinimapBackdrop }
end

local function RememberScannedButton(self, button, fallbackName)
    if not button then return end
    local name
    if button.GetName then
        local ok, n = pcall(button.GetName, button)
        if ok then name = n end
    end
    name = name or fallbackName
    if type(name) ~= "string" or name == "" then return end
    if self.buttonNameMap[name] then return end
    self.buttonNameMap[name] = button
    table.insert(self.scannedButtons, { name = name, button = button })
end

-- Rare pairs(_G) harvest. Cheap scans only look up cached names.
M._harvestedNames = M._harvestedNames or {}

local function NameMayBeMinimapButton(name)
    if type(name) ~= "string" or name == "" then return false end
    if name:find("LibDBIcon", 1, true) then return true end
    if name:find("Minimap", 1, true) then return true end
    if name:sub(1, 8) == "TomCats-" then return true end
    return false
end

local function ApplyHarvestedNames(self)
    for name in pairs(self._harvestedNames) do
        local obj = _G[name]
        if obj and IsValidMinimapButton(obj) then
            RememberScannedButton(self, obj, name)
        end
    end
end

--- One-shot (or forced) Forever _G name harvest. Never call from the cheap scan path.
function M:HarvestNamedMinimapButtons(force)
    if not IsForeverClient() then return false end
    if self._harvestInProgress then return false end
    if self._namedHarvestDone and not force then return false end
    self._harvestInProgress = true
    local found = 0
    local ok, err = pcall(function()
        for name, obj in pairs(_G) do
            if NameMayBeMinimapButton(name) and NameLooksLikeMinimapButton(name) then
                if IsValidMinimapButton(obj) then
                    self._harvestedNames[name] = true
                    found = found + 1
                end
            end
        end
    end)
    self._harvestInProgress = false
    if not ok then
        local handler = geterrorhandler and geterrorhandler()
        if handler then
            pcall(handler, err)
        end
        return false
    end
    self._namedHarvestDone = true
    return found >= 0
end

local function ScanButtonsUnlocked(self)
    wipe(self.scannedButtons)
    wipe(self.buttonNameMap)

    local roots = GetMinimapScanRoots()
    for r = 1, #roots do
        local children = CollectDirectMinimapChildren(roots[r])
        for i = 1, #children do
            local child = children[i]
            if IsValidMinimapButton(child) then
                RememberScannedButton(self, child)
            end
        end
    end

    -- Scan LibDBIcon
    local LibDBIcon = _G.LibStub and _G.LibStub:GetLibrary("LibDBIcon-1.0", true)
    if LibDBIcon and LibDBIcon.GetButtonList then
        for _, name in ipairs(LibDBIcon:GetButtonList()) do
            local button = LibDBIcon:GetMinimapButton(name)
            if button then
                local btnName = button:GetName() or ("LibDBIcon10_" .. name)
                RememberScannedButton(self, button, btnName)
            end
        end
    end

    local LibMapButton = _G.LibStub and _G.LibStub:GetLibrary("LibMapButton-1.1", true)
    if LibMapButton and LibMapButton.buttons then
        for _, button in pairs(LibMapButton.buttons) do
            RememberScannedButton(self, button)
        end
    end

    -- Buttons already scooped into the Addon (+) popup (reparented off Minimap).
    if FluxAddonSystem and FluxAddonSystem.collectedButtons then
        for _, button in ipairs(FluxAddonSystem.collectedButtons) do
            RememberScannedButton(self, button)
        end
    end

    ApplyHarvestedNames(self)

    table.sort(self.scannedButtons, function(a, b) return a.name < b.name end)
end

local SCAN_THROTTLE = 0.5

function M:ScanButtons(force)
    if self._scanInProgress then
        return
    end
    if not force then
        local now = (GetTime and GetTime()) or 0
        if self._lastScanTime and (now - self._lastScanTime) < SCAN_THROTTLE then
            return
        end
        self._lastScanTime = now
    else
        self._lastScanTime = (GetTime and GetTime()) or 0
    end
    self._scanInProgress = true
    local ok, err = pcall(ScanButtonsUnlocked, self)
    self._scanInProgress = false
    if not ok then
        local handler = geterrorhandler and geterrorhandler()
        if handler then
            pcall(handler, err)
        end
    end
end

--- True if a minimap frame with this name was found by the last ScanButtons (addon loaded / button exists).
function M:IsMinimapButtonPresent(buttonName)
    if type(buttonName) ~= "string" or buttonName == "" then
        return false
    end
    if #self.scannedButtons == 0 then
        self:ScanButtons(true)
    end
    return self.buttonNameMap[buttonName] ~= nil
end

local function SafeGetRegions(button)
    if not button or not button.GetRegions then
        return nil
    end
    local ok, packed = pcall(function()
        return { button:GetRegions() }
    end)
    if ok and type(packed) == "table" then
        return packed
    end
    return nil
end

local function RegionIsTexture(region)
    if not region then return false end
    if region.IsObjectType then
        local ok, isTex = pcall(region.IsObjectType, region, "Texture")
        return ok and isTex == true
    end
    return false
end

-- Get the icon texture from a minimap button
function M:GetButtonIcon(button)
    if not button then return nil end
    
    -- Try common icon locations
    local icon = button.icon or button.Icon or button.texture or button.Texture
    
    if icon and icon.GetTexture then
        local ok, texture = pcall(icon.GetTexture, icon)
        if ok and texture then
            return texture
        end
    end
    
    local regions = SafeGetRegions(button)
    if regions then
        for _, child in ipairs(regions) do
            if RegionIsTexture(child) and child.GetTexture then
                local ok, texture = pcall(child.GetTexture, child)
                if ok and texture and not string.match(tostring(texture), "Highlight") and
                   not string.match(tostring(texture), "Border") then
                    return texture
                end
            end
        end
    end
    
    -- Fallback icon
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Get the texture object used as the minimap button's icon (for hooking SetTexture/SetAtlas)
function M:GetButtonIconTexture(button)
    if not button then return nil end
    
    local icon = button.icon or button.Icon or button.texture or button.Texture
    if icon and icon.GetTexture and RegionIsTexture(icon) then
        return icon
    end
    
    local regions = SafeGetRegions(button)
    if not regions then
        return nil
    end
    for _, child in ipairs(regions) do
        if RegionIsTexture(child) and child.GetTexture then
            local ok, texture = pcall(child.GetTexture, child)
            local texStr = (ok and texture and tostring(texture)) or ""
            if ok and texture and not string.match(texStr, "Highlight") and not string.match(texStr, "Border") then
                return child
            end
        end
    end
    return nil
end

-- Sync micro button icon from its minimap button (path and optional atlas)
function M:UpdateMicroButtonIconFromMinimap(microBtn)
    if not microBtn or not microBtn.originalMinimapButton or not microBtn.icon then return end
    local orig = microBtn.originalMinimapButton
    local iconTex = self:GetButtonIconTexture(orig)
    if iconTex and iconTex.GetAtlas then
        local atlas = iconTex:GetAtlas()
        if atlas and microBtn.icon.SetAtlas then
            microBtn.icon:SetAtlas(atlas)
            return
        end
    end
    local path = self:GetButtonIcon(orig)
    if path and microBtn.icon.SetTexture then
        microBtn.icon:SetTexture(path)
    end
end

-- ---------------------------------------------------------------------------
-- Config Popup (Right-Click)
-- ---------------------------------------------------------------------------

function M:CreateConfigPopup()
    if self.configPopupFrame then return self.configPopupFrame end
    
    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
    
    -- Main container
    local popup = CreateFrame("Frame", "FluxMinimapToMicroConfigPopup", UIParent, backdropTemplate)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(100)
    popup:SetSize(100, 100)
    popup:Hide()
    popup:EnableMouse(true)
    
    -- Background
    if popup.SetBackdrop then
        popup:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        local r, g, b = 1, 1, 1
        if FluxBorder and FluxBorder.GetThemedVertexRGB then
            r, g, b = FluxBorder:GetThemedVertexRGB()
        elseif FluxMicroMenu and FluxMicroMenu.GetClassColor then
            r, g, b = FluxMicroMenu:GetClassColor()
        elseif C_ClassColor and C_ClassColor.GetClassColor then
            local _, class = UnitClass("player")
            local color = C_ClassColor.GetClassColor(class)
            if color then r, g, b = color.r, color.g, color.b end
        end

        local br, bg, bb = r * 0.2, g * 0.2, b * 0.2
        if FluxBorder and FluxBorder.GetThemedBackdropFillRGB then
            br, bg, bb = FluxBorder:GetThemedBackdropFillRGB()
        end
        popup:SetBackdropColor(br, bg, bb, 0.95)
        popup:SetBackdropBorderColor(r, g, b, 1)
    end
    
    -- Auto-close on movement (but not during drag)
    popup:RegisterEvent("PLAYER_STARTED_MOVING")
    popup:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_STARTED_MOVING" then
            -- Don't close if we're dragging a button
            if not M.isDragging then
                M:HideConfigPopup()
            end
        end
    end)
    
    -- Container for buttons
    popup.buttonContainer = CreateFrame("Frame", nil, popup)
    popup.buttonContainer:SetAllPoints()
    popup.buttonContainer:SetFrameLevel(popup:GetFrameLevel() + 1)
    
    popup.configButtons = {}
    
    self.configPopupFrame = popup
    return popup
end

function M:ShowConfigPopup(anchorButton)
    if self.isUpdating then return end
    self.isUpdating = true

    if FluxAddonSystem and FluxAddonSystem.isShown then
        FluxAddonSystem.containerFrame:Hide()
        FluxAddonSystem.isShown = false
    end

    self.isConfigShown = true
    if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.ShowStandalone then
        FluxMicroMenuConfigUI:ShowStandalone(anchorButton)
    end

    self.isUpdating = false
end

function M:HideConfigPopup()
    if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.HideStandalone then
        FluxMicroMenuConfigUI:HideStandalone()
    else
        self.isConfigShown = false
    end
    if self.configPopupFrame then
        self.configPopupFrame:Hide()
    end
end

function M:CreateConfigButton(parent, data, index)
    local btn = CreateFrame("Button", nil, parent.buttonContainer)
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    
    -- Position in grid
    local row = math.floor((index - 1) / BUTTONS_PER_ROW)
    local col = (index - 1) % BUTTONS_PER_ROW
    
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT",
        PADDING + (col * (BUTTON_SIZE + BUTTON_SPACING)),
        -(PADDING + (row * (BUTTON_SIZE + BUTTON_SPACING)))
    )
    
    -- Store reference
    btn.buttonName = data.name
    btn.originalButton = data.button
    
    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    local iconTexture = self:GetButtonIcon(data.button)
    icon:SetTexture(iconTexture)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon
    
    -- Tint overlay
    local tint = btn:CreateTexture(nil, "OVERLAY")
    tint:SetAllPoints()
    tint:SetColorTexture(1, 1, 1, 0.4)
    tint:Hide()
    btn.tintOverlay = tint
    
    -- Border
    local border = btn:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    btn.border = border
    
    -- Highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.2)
    btn:SetHighlightTexture(highlight)
    
    -- Apply current mode tint
    self:ApplyModeTint(btn)
    
    -- Click handler - cycle mode
    btn:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            M:CycleMode(self.buttonName)
        end
    end)
    
    -- Drag functionality
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    btn.dragIndex = index
    
    btn:SetScript("OnDragStart", function(self)
        if M.isConfigShown then
            M.isDragging = true
            M.draggedButton = self
            M.dragStartIndex = self.dragIndex
            self:StartMoving()
            self:SetFrameStrata("TOOLTIP")
        end
    end)
    
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetFrameStrata("DIALOG")
        
        if M.draggedButton then
            M:HandleDragDrop(self)
            M.draggedButton = nil
            M.dragStartIndex = nil
        end
        
        M.isDragging = false
    end)
    
    -- Configuration popup buttons omit tooltips.
    btn:SetScript("OnEnter", nil)
    btn:SetScript("OnLeave", nil)
    
    btn:Show()
    return btn
end

function M:ApplyModeTint(btn)
    if not btn or not btn.buttonName then return end
    
    local mode = self:GetMode(btn.buttonName)
    local tintColor = TINT_COLORS[mode]
    
    if tintColor then
        btn.tintOverlay:SetColorTexture(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
        btn.tintOverlay:Show()
    else
        btn.tintOverlay:Hide()
    end
end

function M:UpdateConfigPopupTints()
    if not self.configPopupFrame or not self.configPopupFrame.configButtons then return end
    
    for _, btn in ipairs(self.configPopupFrame.configButtons) do
        self:ApplyModeTint(btn)
    end
end

-- ---------------------------------------------------------------------------
-- Drag and Drop Reordering
-- ---------------------------------------------------------------------------

function M:HandleDragDrop(droppedButton)
    if not self.configPopupFrame or not self.configPopupFrame.configButtons then return end
    if not self.dragStartIndex then return end
    
    -- Get the center position of the dropped button (after it was moved)
    local dropCenterX, dropCenterY = droppedButton:GetCenter()
    if not dropCenterX or not dropCenterY then
        -- Fallback: just refresh layout to snap back
        self:RefreshConfigPopupLayout()
        return
    end
    
    local newIndex = nil
    local closestDistance = math.huge
    
    -- Find which button the dropped button is overlapping or closest to
    for i, btn in ipairs(self.configPopupFrame.configButtons) do
        if btn ~= droppedButton and btn:IsVisible() then
            local btnCenterX, btnCenterY = btn:GetCenter()
            if btnCenterX and btnCenterY then
                -- Calculate distance from dropped button center to this button center
                local dx = dropCenterX - btnCenterX
                local dy = dropCenterY - btnCenterY
                local distance = math.sqrt(dx * dx + dy * dy)
                
                -- Check if overlapping (within button size)
                local btnLeft = btn:GetLeft()
                local btnRight = btn:GetRight()
                local btnTop = btn:GetTop()
                local btnBottom = btn:GetBottom()
                
                if btnLeft and btnRight and btnTop and btnBottom then
                    -- Check if drop center is within this button's bounds
                    if dropCenterX >= btnLeft and dropCenterX <= btnRight and
                       dropCenterY >= btnBottom and dropCenterY <= btnTop then
                        newIndex = i
                        break
                    end
                    
                    -- Track closest button if not overlapping
                    if distance < closestDistance and distance < (BUTTON_SIZE * 1.5) then
                        closestDistance = distance
                        newIndex = i
                    end
                end
            end
        end
    end
    
    -- If dropped on another button, swap them
    if newIndex and newIndex ~= self.dragStartIndex then
        self:ReorderButtons(self.dragStartIndex, newIndex)
    else
        -- Just refresh layout to snap back to original position
        self:RefreshConfigPopupLayout()
    end
end

function M:ReorderButtons(fromIndex, toIndex)
    if fromIndex == toIndex then return end
    if not self.configPopupFrame or not self.configPopupFrame.configButtons then return end
    
    local buttons = self.configPopupFrame.configButtons
    local draggedBtn = buttons[fromIndex]
    local targetBtn = buttons[toIndex]
    
    if not draggedBtn or not targetBtn then return end
    
    local draggedName = draggedBtn.buttonName
    local targetName = targetBtn.buttonName
    
    local draggedEnabled = self:IsEnabled(draggedName)
    local targetEnabled = self:IsEnabled(targetName)
    
    -- Swap visual positions in popup immediately
    buttons[fromIndex] = targetBtn
    buttons[toIndex] = draggedBtn
    targetBtn.dragIndex = fromIndex
    draggedBtn.dragIndex = toIndex
    
    -- Refresh visual layout immediately
    self:RefreshConfigPopupLayout()
    
    -- If both are enabled, reassign ALL enabled button orders based on their popup positions
    if draggedEnabled and targetEnabled then
        -- Get all enabled buttons in their NEW popup order
        local enabledInPopupOrder = {}
        for i, btn in ipairs(buttons) do
            if btn and btn.buttonName and self:IsEnabled(btn.buttonName) then
                table.insert(enabledInPopupOrder, { index = i, name = btn.buttonName })
            end
        end
        
        -- Sort by popup index to get the order
        table.sort(enabledInPopupOrder, function(a, b) return a.index < b.index end)
        
        -- Reassign orders: first enabled button in popup = order 1, second = order 2, etc.
        for i, data in ipairs(enabledInPopupOrder) do
            self:SetButtonOrder(data.name, i)
        end
        
        -- Rebuild micro buttons with new order
        self:RebuildMicroButtons()
        
        -- Refresh config popup to reflect new order (will re-sort enabled buttons)
        if self.isConfigShown then
            -- Store anchor button
            local anchorBtn = FluxAddonSystem and FluxAddonSystem.microButton
            self:HideConfigPopup()
            -- Show immediately (no delay needed)
            self:ShowConfigPopup(anchorBtn)
        end
    elseif draggedEnabled then
        -- Dragged is enabled, target is not - just refresh
        if self.isConfigShown then
            local anchorBtn = FluxAddonSystem and FluxAddonSystem.microButton
            self:HideConfigPopup()
            -- Show immediately (no delay needed)
            self:ShowConfigPopup(anchorBtn)
        end
    else
        -- Neither enabled or only target enabled - just refresh popup
        if self.isConfigShown then
            local anchorBtn = FluxAddonSystem and FluxAddonSystem.microButton
            self:HideConfigPopup()
            -- Show immediately (no delay needed)
            self:ShowConfigPopup(anchorBtn)
        end
    end
end

function M:RefreshConfigPopupLayout()
    if not self.configPopupFrame then return end
    
    -- Reposition all buttons to their grid positions
    for i, btn in ipairs(self.configPopupFrame.configButtons) do
        local row = math.floor((i - 1) / BUTTONS_PER_ROW)
        local col = (i - 1) % BUTTONS_PER_ROW
        
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", self.configPopupFrame, "TOPLEFT",
            PADDING + (col * (BUTTON_SIZE + BUTTON_SPACING)),
            -(PADDING + (row * (BUTTON_SIZE + BUTTON_SPACING)))
        )
        btn.dragIndex = i
    end
end

-- ---------------------------------------------------------------------------
-- Dynamic MicroButton Creation
-- ---------------------------------------------------------------------------

local proxyButtons = {}
local iconHooks = setmetatable({}, {__mode = "k"})
local tooltipOperation, tooltipButton, tooltipDriver
local rebuildDriver, rebuildPending

local function TooltipOwnedBy(button, original)
    if not GameTooltip then return false end
    if GameTooltip.GetOwner then
        local owner = GameTooltip:GetOwner()
        return owner == button or owner == original
    end
    if GameTooltip.IsOwned then return GameTooltip:IsOwned(button) or GameTooltip:IsOwned(original) end
    return true -- Old tooltip APIs still have the explicit hover operation.
end

local function CancelProxyTooltip(button)
    if not button then return end
    button._fluxProxyHovered = false
    if tooltipOperation and tooltipOperation.button == button then
        tooltipOperation = nil
        if tooltipDriver then tooltipDriver:SetScript("OnUpdate", nil); tooltipDriver:Hide() end
    end
    if tooltipButton == button then
        tooltipButton = nil
        if TooltipOwnedBy(button, button.originalMinimapButton) then GameTooltip:Hide() end
    end
end

local function ProxyTooltipCurrent(operation)
    local button = operation.button
    return tooltipButton == button and button._fluxProxyHovered
        and button._fluxProxyEnabled and button.originalMinimapButton == operation.original
        and (not button.IsShown or button:IsShown())
end

local function PositionProxyTooltip(button)
    if not GameTooltip then return end
    -- Keep the original native owner/data processor for standard handlers.
    -- Moving the same tooltip retains async data, widgets, colors and lines.
    if GameTooltip.SetAnchorType then GameTooltip:SetAnchorType("ANCHOR_NONE") end
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("LEFT", button, "RIGHT", 5, 0)
end

local function QueueProxyTooltip(operation)
    tooltipOperation = operation
    if not tooltipDriver then tooltipDriver = CreateFrame("Frame"); tooltipDriver:Hide() end
    tooltipDriver:SetScript("OnUpdate", function(self)
        local current = tooltipOperation
        if not current or not ProxyTooltipCurrent(current) then
            tooltipOperation = nil; self:SetScript("OnUpdate", nil); self:Hide(); return
        end
        current.attempts = (current.attempts or 0) + 1
        local button = current.button
        if button:GetLeft() and button:GetRight() then
            -- Clear first: callbacks may start a newer tooltip operation.
            tooltipOperation = nil; self:SetScript("OnUpdate", nil); self:Hide()
            current.run()
        elseif current.attempts >= 10 then
            tooltipOperation = nil; self:SetScript("OnUpdate", nil); self:Hide()
        end
    end)
    tooltipDriver:Show()
end

local function ProxyTooltipEnter(button)
    if tooltipButton then CancelProxyTooltip(tooltipButton) end
    button._fluxProxyHovered = true
    tooltipButton = button
    local original = button.originalMinimapButton
    if not original or not GameTooltip then return end
    local operation = {button=button, original=original}
    operation.run = function()
        if not ProxyTooltipCurrent(operation) then return end
        local data = original.dataObject
        if data and data.OnTooltipShow then
            GameTooltip:SetOwner(button, "ANCHOR_NONE")
            PositionProxyTooltip(button); GameTooltip:ClearLines()
            data.OnTooltipShow(GameTooltip)
            if ProxyTooltipCurrent(operation) and TooltipOwnedBy(button, original) then GameTooltip:Show() end
        elseif data and data.OnEnter then
            data.OnEnter(button)
        else
            local onEnter = original:GetScript("OnEnter")
            if onEnter then
                GameTooltip:SetOwner(original, "ANCHOR_NONE")
                GameTooltip:ClearLines()
                pcall(onEnter, original)
                if ProxyTooltipCurrent(operation) and TooltipOwnedBy(button, original) then
                    PositionProxyTooltip(button)
                    -- A handler may finish layout next frame. Reanchor only
                    -- while this same owner/hover still owns the tooltip.
                    QueueProxyTooltip({button=button, original=original, run=function()
                        if ProxyTooltipCurrent(operation) and TooltipOwnedBy(button, original) then PositionProxyTooltip(button) end
                    end})
                end
            else
                GameTooltip:SetOwner(button, "ANCHOR_NONE")
                PositionProxyTooltip(button)
                GameTooltip:SetText(M:GetFriendlyMinimapButtonName(button.minimapButtonName))
                GameTooltip:Show()
            end
        end
    end
    if button:GetLeft() and button:GetRight() then operation.run()
    else QueueProxyTooltip(operation) end
end

local function ProxyTooltipLeave(button)
    local original = button.originalMinimapButton
    -- A stale leave/hide must not clear another button's active tooltip.
    local owns = tooltipButton == button
    CancelProxyTooltip(button)
    if owns and original then
        local data = original.dataObject
        if data and data.OnLeave then pcall(data.OnLeave, button)
        else
            local onLeave = original:GetScript("OnLeave")
            if onLeave then pcall(onLeave, original) end
        end
    end
end

local function BindProxyOriginal(button, name, original)
    local previous = button.originalMinimapButton
    if previous and previous ~= original then
        CancelProxyTooltip(button)
        if previous._fluxMicroBtn == button then previous._fluxMicroBtn = nil end
    end
    button.originalMinimapButton, button.minimapButtonName = original, name
    button._fluxProxyEnabled = true
    original._fluxMicroBtn = button
    local icon = M:GetButtonIconTexture(original)
    if icon and not iconHooks[icon] then
        iconHooks[icon] = true
        local function changed()
            -- The hook stays on this native icon; dispatch to its current
            -- enabled proxy, never retain a disabled/replaced proxy closure.
            local owner = icon:GetParent()
            local proxy = owner and owner._fluxMicroBtn
            if proxy and proxy._fluxProxyEnabled then M:UpdateMicroButtonIconFromMinimap(proxy) end
        end
        if icon.SetTexture then hooksecurefunc(icon, "SetTexture", changed) end
        if icon.SetAtlas then hooksecurefunc(icon, "SetAtlas", changed) end
    end
    M:UpdateMicroButtonIconFromMinimap(button)
end

local function QueueMicroMenuRebuild()
    if rebuildPending or not (FluxMicroMenu and FluxMicroMenu.Rebuild) then return end
    rebuildPending = true
    if not rebuildDriver then rebuildDriver = CreateFrame("Frame"); rebuildDriver:Hide() end
    rebuildDriver:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil); self:Hide(); rebuildPending = false
        if FluxMicroMenu and FluxMicroMenu.Rebuild then FluxMicroMenu:Rebuild() end
        if _G.FluxStatusBarUpdateLayout then _G.FluxStatusBarUpdateLayout() end
    end)
    rebuildDriver:Show()
end

function M:RebuildMicroButtons()
    if self.isUpdating then return end
    self.isUpdating = true
    local enabledList = self:GetEnabledButtonsOrdered()
    local enabledSet = {}
    for _, name in ipairs(enabledList) do enabledSet[name] = true end
    for _, button in ipairs(self.createdMicroButtons) do
        if button and button.minimapButtonName and not enabledSet[button.minimapButtonName] then
            button._fluxProxyEnabled = false
            CancelProxyTooltip(button)
            if button.originalMinimapButton and button.originalMinimapButton._fluxMicroBtn == button then button.originalMinimapButton._fluxMicroBtn = nil end
            local name = button:GetName()
            button:Hide(); button:SetParent(nil)
            if name and _G[name] == button then _G[name] = nil end
            if name and _G.BUTTON_PRIORITIES then _G.BUTTON_PRIORITIES[name] = nil end
        end
    end
    wipe(self.createdMicroButtons)
    if #self.scannedButtons == 0 then self:ScanButtons(true) end
    for i, name in ipairs(enabledList) do
        local original = self.buttonNameMap[name]
        if original then
            local button = self:CreateMicroButtonForMinimap(name, original, i)
            if button then self.createdMicroButtons[#self.createdMicroButtons+1] = button end
        end
    end
    QueueMicroMenuRebuild()
    self.isUpdating = false
end

function M:CreateMicroButtonForMinimap(buttonName, originalButton, orderIndex)
    if not originalButton then return nil end
    local globalName = "FluxMinimap2Micro_" .. buttonName:gsub("[^%w]", "_") .. "MicroButton"
    local priority = 104 + orderIndex
    if _G.BUTTON_PRIORITIES then _G.BUTTON_PRIORITIES[globalName] = priority end
    local button = proxyButtons[buttonName] or _G[globalName]
    if not button then
        local clickHandler = {OnTooltip=function() end, OnClick=function(self, mouseButton, down)
            local original = self.originalMinimapButton
            if not original then return end
            local data = original.dataObject
            if data and data.OnClick then data.OnClick(self, mouseButton)
            else
                local onClick = original:GetScript("OnClick")
                if onClick then onClick(original, mouseButton, down) end
                if mouseButton == "LeftButton" or mouseButton == "RightButton" then
                    local onMouseUp = original:GetScript("OnMouseUp")
                    if onMouseUp then onMouseUp(original, mouseButton) end
                end
            end
        end}
        button = FluxMicroMenu:CreateMicroButton(globalName, self:GetButtonIcon(originalButton),
            self:GetFriendlyMinimapButtonName(buttonName), nil, clickHandler)
        if not button then return nil end
    end
    proxyButtons[buttonName] = button
    if not button._fluxProxyHooks then
        button._fluxProxyHooks = true
        button:SetScript("OnEnter", ProxyTooltipEnter)
        button:SetScript("OnLeave", ProxyTooltipLeave)
        button:HookScript("OnHide", function(self) CancelProxyTooltip(self) end)
        button:RegisterForClicks("AnyUp")
    end
    BindProxyOriginal(button, buttonName, originalButton)
    _G[globalName] = button
    button:SetParent(UIParent); button:Show()
    return button
end

-- ---------------------------------------------------------------------------
-- Integration with FluxAddonMicroButton (Left-Click Popup Filter)
-- ---------------------------------------------------------------------------

-- Check if a button should be hidden from left-click popup
function M:ShouldHideFromLeftPopup(buttonName)
    return self:IsEnabled(buttonName)
end

-- Get list of enabled button names (for filtering)
function M:GetEnabledButtonNames()
    local names = {}
    EnsureSavedVars()
    
    for name, _ in pairs(FluxUI_DB.MinimapToMicro.buttons) do
        names[name] = true
    end
    for name, _ in pairs(_FluxUI_CharSavedVars.MinimapToMicro.buttons) do
        names[name] = true
    end
    
    return names
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event, ...)
    local function scanAndRebuild()
        M:ScanButtons(true)
        M:RebuildMicroButtons()
    end

    local function harvestScanMerge()
        if M.HarvestNamedMinimapButtons then
            M:HarvestNamedMinimapButtons(true)
        end
        M:ScanButtons(true)
        M:RebuildMicroButtons()
        if FluxMicroMenuConfig and FluxMicroMenuConfig.MergeNewDiscoveriesIntoUnifiedOrder then
            FluxMicroMenuConfig:MergeNewDiscoveriesIntoUnifiedOrder()
        end
    end

    if event == "PLAYER_LOGIN" then
        EnsureSavedVars()

        -- Cheap ticks: scan/rebuild only. One Forever _G harvest at 2s and 8s.
        if not M._loginWatcher then
            M._loginWatcher = CreateFrame("Frame")
            M._loginWatcher:SetScript("OnUpdate", function(watcher)
                M._loginFrameCount = (M._loginFrameCount or 0) + 1
                local ready = FluxMicroMenu and FluxMicroMenu.CreateMicroButton
                if M._loginPhase == "immediate" then
                    if ready or M._loginFrameCount >= 20 then
                        scanAndRebuild()
                        M._loginPhase = "late"
                        M._loginFrameCount = 0
                    end
                elseif M._loginPhase == "late" then
                    if M._loginFrameCount >= 60 then
                        scanAndRebuild()
                        M._loginPhase = "done"
                        watcher:SetScript("OnUpdate", nil)
                        watcher:Hide()
                    end
                end
            end)
        end
        M._loginPhase = "immediate"
        M._loginFrameCount = 0
        M._loginWatcher:Show()

        if C_Timer and C_Timer.After then
            C_Timer.After(2, harvestScanMerge)
            C_Timer.After(8, harvestScanMerge)
        end

        local LibDBIcon = _G.LibStub and _G.LibStub:GetLibrary("LibDBIcon-1.0", true)
        if LibDBIcon and LibDBIcon.RegisterCallback and not M._libDBIconHooked then
            M._libDBIconHooked = true
            LibDBIcon.RegisterCallback("FluxMinimapToMicro", "LibDBIcon_IconCreated", function()
                if M._libDBIconScanPending then
                    return
                end
                M._libDBIconScanPending = true
                local function run()
                    M._libDBIconScanPending = false
                    scanAndRebuild()
                end
                if C_Timer and C_Timer.After then
                    C_Timer.After(0.25, run)
                else
                    run()
                end
            end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        if isInitialLogin == true or isReloadingUi == true or M._pewDidLoginScan ~= true then
            M._pewDidLoginScan = true
            if FluxMicroMenu and FluxMicroMenu.CreateMicroButton then
                scanAndRebuild()
            elseif C_Timer and C_Timer.After then
                C_Timer.After(0.1, scanAndRebuild)
            end
        else
            M:ScanButtons()
        end
    end
end)

function FluxMinimapToMicro_RefreshPopupAccent()
    local pop = M.configPopupFrame
    if not pop or not pop.SetBackdropColor then return end
    local r, g, b = 1, 1, 1
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        r, g, b = FluxBorder:GetThemedVertexRGB()
    end
    local br, bg, bb = r * 0.2, g * 0.2, b * 0.2
    if FluxBorder and FluxBorder.GetThemedBackdropFillRGB then
        br, bg, bb = FluxBorder:GetThemedBackdropFillRGB()
    end
    pop:SetBackdropColor(br, bg, bb, 0.95)
    pop:SetBackdropBorderColor(r, g, b, 1)
end

-- Expose globally
_G.FluxMinimapToMicro = M


