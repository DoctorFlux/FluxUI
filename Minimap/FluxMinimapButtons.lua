--[[
    Minimap/FluxMinimapButtons.lua

    Character-scoped actions shared by the embedded and optional screen-side strip.
    Extra Button widgets (EBS) — item counts come from Flux.Inventory via the engine.
]]

FluxMinimapButtons = FluxMinimapButtons or {}
local M = FluxMinimapButtons

local CONFIG = {
    NumButtons = 15,
    ButtonSize = 45,
    NativeSize = 44,
    ButtonSpacing = 0,
    ContainerPadding = 0,
    Scale = 1.13,
}

local containerFrame = nil
local buttonWidgets = {}
local isInitialized = false
local visibilityFrame
local sideBorderHost
local embeddedHost
local embeddedVisible = false
local layoutMode
local driverInstalled = false
local refreshPending = false
local refreshQueued = false
local hoverTicker
local boot
local SIDE_SCALE_BASIS = 0.85
local SIDE_SCALE_VERSION = 2
local defaults = {
    count = 15,
    sideEnabled = false, sideScale = 100,
    sideStart = "below", hideInCombat = false,
    sideHideEmpty = false, autoGrow = false,
    sideVisibility = "always",
}
local ranges = {
    count = { 1, 120 },
    sideScale = { 10, 200 },
}

local function InCombat()
    return InCombatLockdown and InCombatLockdown() or false
end

local function Normalize(key, value)
    local range = ranges[key]
    if range then
        value = tonumber(value)
        if not value or value ~= value or value == math.huge or value == -math.huge then
            return defaults[key]
        end
        value = math.max(range[1], math.min(range[2], value))
        -- Legacy percentages need fractional new units to retain their size.
        return key == "sideScale" and value or math.floor(value + 0.5)
    end
    if key == "sideStart" then return value == "top" and "top" or "below" end
    if key == "sideVisibility" then return value == "mouseover" and "mouseover" or "always" end
    if type(defaults[key]) == "boolean" then
        if type(value) == "boolean" then return value end
        return defaults[key]
    end
    return defaults[key]
end

function M:GetSetting(key)
    local saved = _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.minimapExtraLayout
    local value
    if type(saved) == "table" then value = saved[key] end
    if key == "sideScale" and value ~= nil and saved.sideScaleVersion ~= SIDE_SCALE_VERSION then
        value = tonumber(value)
        if value and value == value and value ~= math.huge and value ~= -math.huge then
            value = math.max(25, math.min(200, value)) / SIDE_SCALE_BASIS
        else
            value = nil
        end
    end
    return Normalize(key, value)
end

function M:SetSetting(key, value)
    if defaults[key] == nil then return end
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    _FluxUI_CharSavedVars.minimapExtraLayout = _FluxUI_CharSavedVars.minimapExtraLayout or {}
    _FluxUI_CharSavedVars.minimapExtraLayout[key] = Normalize(key, value)
    if key == "sideScale" then
        _FluxUI_CharSavedVars.minimapExtraLayout.sideScaleVersion = SIDE_SCALE_VERSION
    end
    self:RequestRefresh()
end

function M:CanHideInCombat()
    local restricted = _G.Flux and Flux.Restricted
    return restricted and restricted.PagingWorks and restricted.PagingWorks()
        and type(restricted.RegisterPagingDriver) == "function"
        and type(restricted.UnregisterPagingDriver) == "function" or false
end

-- All geometry is expressed in UIParent points, including scaled windows/maps.
local function UIUnits(frame, method)
    if not (frame and frame[method]) then return nil end
    local value = frame[method](frame)
    if type(value) ~= "number" then return nil end
    local scale = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    local uiScale = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    return value * scale / uiScale
end

local function IsEmbedded()
    return FluxMinimap and FluxMinimap.IsEmbedded and FluxMinimap:IsEmbedded() or false
end

local function GetWindow()
    -- Do not force creation while the disabled side strip is idle.
    if not FluxWindowFrame then return nil end
    return FluxWindowFrame.frame or (FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame())
        or (FluxWindowFrame.GetTop and FluxWindowFrame)
end

local function LoadSavedVars()
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    if not _FluxUI_CharSavedVars.minimapExtraButtons then
        _FluxUI_CharSavedVars.minimapExtraButtons = {}
    end
    for i = 1, CONFIG.NumButtons do
        if not _FluxUI_CharSavedVars.minimapExtraButtons[i] then
            _FluxUI_CharSavedVars.minimapExtraButtons[i] = {
                dataType = nil,
                data = nil,
            }
        end
    end
end

local function GetButtonData(slotIndex)
    LoadSavedVars()
    if not _FluxUI_CharSavedVars.minimapExtraButtons[slotIndex] then
        _FluxUI_CharSavedVars.minimapExtraButtons[slotIndex] = {}
    end
    return _FluxUI_CharSavedVars.minimapExtraButtons[slotIndex]
end

local function SaveButtonData(slotIndex, actionType, actionValue, btn)
    LoadSavedVars()
    if actionType == "macro" and actionValue and type(actionValue) == "string" then
        local maxAccount = MAX_ACCOUNT_MACROS or 120
        local maxChar = MAX_CHARACTER_MACROS or 18
        for i = 1, maxAccount + maxChar do
            local name = GetMacroInfo(i)
            if name and name == actionValue then
                actionValue = i
                break
            end
        end
    end
    if actionType == "macro" and btn then
        actionValue = btn.MacroIndex or actionValue
    end
    local rec = {
        dataType = actionType,
        data = actionValue,
        actionType = actionType,
        actionValue = actionValue,
    }
    if actionType == "macro" then
        rec.macroName = btn and btn.MacroName or nil
        rec.macroBody = btn and btn.MacroBody or nil
    end
    _FluxUI_CharSavedVars.minimapExtraButtons[slotIndex] = rec
end

local function ClearButtonData(slotIndex)
    LoadSavedVars()
    _FluxUI_CharSavedVars.minimapExtraButtons[slotIndex] = {
        dataType = nil,
        data = nil,
        actionType = nil,
        actionValue = nil,
        macroName = nil,
        macroBody = nil,
    }
end

local function Engine()
    return _G.Flux and _G.Flux.EBS
end

local function NativeSize()
    return CONFIG.NativeSize or 44
end

local function ApplySavedAction(btn, saved)
    local ebs = Engine()
    if not btn or not btn.Widget or not (ebs and ebs.Action and ebs.Action.SetAction) then
        return false
    end
    local aType = saved and (saved.dataType or saved.actionType)
    local aVal = saved and (saved.data or saved.actionValue)
    if not aType or aVal == nil then
        return false
    end
    if aType == "macro" then
        ebs.Action.SetAction(btn, "macro", {
            index = tonumber(aVal) or aVal,
            name = saved.macroName,
            body = saved.macroBody,
        })
        return true
    end
    ebs.Action.SetAction(btn, aType, aVal)
    return true
end

local function ApplyStyle(btn)
    local ebs = Engine()
    if ebs and ebs.Style and ebs.Style.Apply then
        ebs.Style.Apply(btn, "character")
    elseif FluxBtn and FluxBtn.ApplyStyle then
        FluxBtn.ApplyStyle(btn, "character")
    end
end

local function HasAssignment(index)
    local records = _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.minimapExtraButtons
    local saved = records and records[index]
    return saved and (saved.dataType or saved.actionType)
        and (saved.data or saved.actionValue) ~= nil or false
end

-- The configured count is a floor in dynamic mode, never a growth counter.
-- Keep all assigned indices, fill to the floor, and offer one temporary spare
-- only while carrying an action and no existing empty slot can accept it.
-- Selection/packing never renumbers or deletes saved action records.
local function LayoutIndices()
    local indices = {}
    local collapse = not IsEmbedded() and M:GetSetting("sideHideEmpty")
    local dynamic = M:GetSetting("autoGrow")
    local dragging = (dynamic or collapse) and GetCursorInfo and GetCursorInfo() ~= nil
    local minimum = M:GetSetting("count")
    local maximum = dynamic and ranges.count[2] or minimum
    local selected, total = {}, 0
    if dynamic then
        for i = 1, maximum do
            if HasAssignment(i) then selected[i] = true; total = total + 1 end
        end
        local target = math.max(minimum, total)
        if dragging and total == target and target < maximum then target = target + 1 end
        for i = 1, maximum do
            if total >= target then break end
            if not selected[i] then selected[i] = true; total = total + 1 end
        end
    else
        for i = 1, minimum do selected[i] = true end
    end
    local spare = collapse and dragging
    for i = 1, maximum do
        if selected[i] then
            if not collapse or HasAssignment(i) then
                indices[#indices + 1] = i
            elseif spare then
                indices[#indices + 1] = i
                spare = false
            end
        end
    end
    return indices
end

function M:QueueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    local timer = _G.Flux and Flux.Timer or C_Timer
    local function refresh()
        refreshQueued = false
        M:RequestRefresh()
    end
    if timer and timer.After then timer.After(0, refresh) else refresh() end
end

function M:OnAssignmentChanged()
    if self:GetSetting("autoGrow") or (not IsEmbedded() and self:GetSetting("sideHideEmpty")) then
        self:QueueRefresh()
    end
end

local function SetFlyoutUp(btn)
    if not btn or not btn.Widget or InCombatLockdown() then
        return
    end
    btn.Widget._isMinimapButton = true
    btn.Widget:SetAttribute("flyoutDirection", "UP")
    local ebs = Engine()
    if ebs and ebs.Flyout and ebs.Flyout.BindHost then
        ebs.Flyout.BindHost(btn.Widget, { direction = "UP", visibilityParent = btn.SlotFrame })
    end
end

local function CreateButton(parent, slotIndex)
    local ebs = Engine()
    if not (ebs and ebs.Widget and ebs.Widget.Create) then
        return nil
    end

    local native = NativeSize()
    local visual = CONFIG.ButtonSize
    local slotFrame = CreateFrame("Frame", nil, parent)
    slotFrame:SetSize(visual, visual)
    slotFrame:EnableMouse(false)

    local btn = ebs.Widget.Create(slotFrame, {
        name = "FluxMinimapExtraButton" .. slotIndex,
        size = native,
        kind = "extra",
        clickBehavior = "AnyUp",
        showBorder = true,
        tooltip = true,
        macroText = true,
    })
    if not btn or not btn.Widget then
        return nil
    end
    btn.SlotFrame = slotFrame
    btn.Widget:ClearAllPoints()
    btn.Widget:SetPoint("CENTER", slotFrame, "CENTER", 0, 0)
    btn.Widget:SetSize(native, native)
    btn.Widget:SetScale(visual / native)

    ApplyStyle(btn)
    SetFlyoutUp(btn)

    btn.OnReceiveDragCallback = function(actionType, actionValue)
        SaveButtonData(slotIndex, actionType, actionValue, btn)
        ApplyStyle(btn)
        SetFlyoutUp(btn)
        M:OnAssignmentChanged()
    end

    btn.OnMacroRebound = function()
        SaveButtonData(slotIndex, "macro", btn.MacroIndex, btn)
    end

    btn.OnDelete = function()
        ClearButtonData(slotIndex)
        M:OnAssignmentChanged()
    end

    local saved = GetButtonData(slotIndex)
    if saved and ApplySavedAction(btn, saved) then
        SetFlyoutUp(btn)
    end

    return btn
end

-- A layout root and separate secure visibility gate keep geometry changes out of
-- the combat path. Popups/openers opt into the same gate through BindHost.
function M:CreateContainer()
    if containerFrame then return containerFrame end
    if InCombat() then return nil end
    containerFrame = CreateFrame("Frame", "FluxMinimapButtonsContainer", UIParent)
    containerFrame:SetFrameStrata("MEDIUM")
    containerFrame:SetFrameLevel(25)
    containerFrame:SetSize(1, 1)
    containerFrame:Hide()
    visibilityFrame = CreateFrame("Frame", "FluxMinimapButtonsVisibility", containerFrame, "SecureHandlerStateTemplate")
    visibilityFrame:SetAllPoints(containerFrame)
    return containerFrame
end

function M:CreateButtons()
    if InCombat() then self:RequestRefresh(); return end
    if not visibilityFrame then return end
    -- Allocate up to the last selected saved index; holes stay hidden and retain
    -- their widget identities for later drops. Shrinking never destroys actions.
    local indices = LayoutIndices()
    for i = 1, (indices[#indices] or 0) do
        if not buttonWidgets[i] then
            buttonWidgets[i] = CreateButton(visibilityFrame, i)
        end
    end
end

function M:RefreshButtons()
    if InCombat() then self:RequestRefresh(); return end
    local ebs = Engine()
    for i, btn in ipairs(buttonWidgets) do
        local saved = GetButtonData(i)
        if saved and ApplySavedAction(btn, saved) then
            -- restored
        elseif ebs and ebs.Action and ebs.Action.Clear then
            ebs.Action.Clear(btn)
        elseif btn.ClearAction then
            btn:ClearAction()
        end
        ApplyStyle(btn)
        SetFlyoutUp(btn)
    end
end

-- Choose the largest bounded square that fits every numbered slot. Ties keep
-- fewer columns; the callers retain their embedded/vertical assignment order.
local function FitGrid(count, width, height, maximumSize)
    width, height = math.max(0, width), math.max(0, height)
    local columns, rows, size = 1, count, 0
    for candidateColumns = 1, count do
        local candidateRows = math.ceil(count / candidateColumns)
        local candidateSize = math.min(maximumSize,
            width / candidateColumns, height / candidateRows)
        if candidateSize > size then
            columns, rows, size = candidateColumns, candidateRows, candidateSize
        end
    end
    return columns, rows, size
end

local function SideGeometry(count)
    local top
    if M:GetSetting("sideStart") == "below" then
        top = UIUnits(Minimap, "GetBottom")
    else
        top = UIUnits(UIParent, "GetTop") or UIParent:GetHeight()
    end
    top = top or UIParent:GetHeight()
    local window = GetWindow()
    local bottom = UIUnits(window, "GetTop") or 270
    local height = math.max(0, top - bottom)
    count = count or #LayoutIndices()
    local pad = CONFIG.ContainerPadding
    local scale = M:GetSetting("sideScale") * SIDE_SCALE_BASIS / 100
    if count == 0 then return 0, 0, 0, top, height, scale end
    -- Refit at every grid scale so a completed column can use the full height.
    local fitHeight = height / scale
    -- Add columns as needed; dense grids share two standard buttons of width.
    local columns, _, size = FitGrid(count, NativeSize() * 2, fitHeight - pad * 2, NativeSize())
    -- Remove fractional-row slack by fitting completed columns exactly between
    -- their starting edge and the window. Short lists retain standard sizing.
    local rows = size > 0 and math.max(1, math.floor((fitHeight - pad * 2) / size + 0.00001)) or 1
    if size > 0 and count * size >= fitHeight - pad * 2 then
        rows = math.max(1, math.ceil((fitHeight - pad * 2) / size - 0.00001))
        size = (fitHeight - pad * 2) / rows
        columns = math.ceil(count / rows)
    end
    rows = math.min(count, rows)
    return columns, rows, size, top, height, scale
end

function M:GetSideWidth()
    if IsEmbedded() or not self:GetSetting("sideEnabled") then return 0 end
    local columns, rows, size, top, height, scale = SideGeometry()
    if size <= 0 then return 0 end
    return (columns * size + CONFIG.ContainerPadding * 2) * scale
end

function M:GetMinimapOffset()
    if self:GetSetting("sideVisibility") == "mouseover" then return 0 end
    if self:GetSetting("sideStart") == "top" then return -self:GetSideWidth() end
    return 0
end

function M:GetTrackerOffset()
    if self:GetSetting("sideVisibility") == "mouseover" then return 0 end
    if self:GetSetting("sideStart") == "below" then return -self:GetSideWidth() end
    return 0
end

-- Leave room for the strip when a square or tall host would otherwise let the
-- map consume its full width. Ordinary wide-window map sizing is unchanged.
function M:GetEmbeddedWidthReserve(width, inset)
    return math.min(width * 0.4, CONFIG.ButtonSize * CONFIG.Scale)
end

function M:LayoutSlots()
    if InCombat() then self:RequestRefresh(); return end
    if not containerFrame or not layoutMode then return end
    local indices = LayoutIndices()
    local count = #indices
    local positions = {}
    for position, index in ipairs(indices) do positions[index] = position end
    local pad = CONFIG.ContainerPadding
    local ebs = Engine()
    local flyout = ebs and ebs.Flyout
    -- The clock hit region is above the map's ordinary MEDIUM chrome. Side
    -- buttons must win both drawing and mouse hits, including template widgets
    -- with their own explicit strata. Embedded buttons retain their HUD layer.
    local strata = layoutMode == "side" and "HIGH" or "MEDIUM"
    containerFrame:SetFrameStrata(strata)
    visibilityFrame:SetFrameStrata(strata)
    visibilityFrame:SetFrameLevel(containerFrame:GetFrameLevel() + 1)
    local columns, rows, size, top, sideHeight, scale
    if layoutMode == "embedded" then
        local width = embeddedHost:GetWidth()
        local height = embeddedHost:GetHeight()
        local mapWidth = (Minimap and Minimap:GetWidth()) or 0
        local availableWidth = math.max(0, width - mapWidth)
        local innerWidth = math.max(0, availableWidth - pad * 2)
        local innerHeight = math.max(0, height - pad * 2)
        columns, rows, size = FitGrid(count, innerWidth, innerHeight, CONFIG.ButtonSize * CONFIG.Scale)
        containerFrame:SetParent(embeddedHost)
        containerFrame:SetScale(1)
        containerFrame:ClearAllPoints()
        containerFrame:SetPoint("TOPRIGHT", embeddedHost, "TOPLEFT", availableWidth, 0)
    else
        columns, rows, size, top, sideHeight, scale = SideGeometry(count)
        containerFrame:SetParent(UIParent)
        containerFrame:SetScale(scale)
        containerFrame:ClearAllPoints()
        local screenTop = UIUnits(UIParent, "GetTop") or UIParent:GetHeight()
        containerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, (top - screenTop) / scale)
    end
    containerFrame:SetSize(columns * size + pad * 2, rows * size + pad * 2)
    for i, btn in ipairs(buttonWidgets) do
        local widget, slot = btn.Widget, btn.SlotFrame
        local position = positions[i]
        if position and size > 0 then
            slot:SetFrameStrata(strata)
            slot:SetFrameLevel(visibilityFrame:GetFrameLevel() + 1)
            widget:SetFrameStrata(strata)
            widget:SetFrameLevel(slot:GetFrameLevel() + 1)
            local col, row
            if layoutMode == "embedded" then
                col, row = (position - 1) % columns, math.floor((position - 1) / columns)
            else
                col, row = columns - 1 - math.floor((position - 1) / rows), (position - 1) % rows
            end
            slot:SetSize(size, size)
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", visibilityFrame, "TOPLEFT", pad + col * size, -pad - row * size)
            widget:SetScale(size / NativeSize())
            slot:Show()
            widget:Show()
            if flyout and flyout.Arrow and flyout.Arrow.Update then
                local open = flyout.IsOpen and flyout.IsOpen(widget) or false
                flyout.Arrow.Update(widget, "UP", open)
            end
            -- A closed popup may next open securely during combat; prepare its
            -- scale now, while ordinary placement is still permitted.
            if flyout and flyout.PlacePopup then flyout.PlacePopup(widget) end
        else
            -- Do not discard the secure action or saved record for a hidden index.
            slot:Hide()
        end
    end
end

-- Decorative siblings of the slots: the secure gate hides border/background
-- together with every button, while the outer owner handles mouseover. Never
-- parent this chrome to UIParent or add an independent combat visibility path.
function M:UpdateSideBorder()
    if InCombat() then self:RequestRefresh(); return end
    local active = layoutMode == "side" and containerFrame:GetWidth() > 0
        and containerFrame:GetHeight() > 0
    if not active or not FluxBorder then
        if sideBorderHost then sideBorderHost:Hide() end
        return
    end
    if not sideBorderHost then
        sideBorderHost = CreateFrame("Frame", "FluxMinimapButtonsSideBorder", visibilityFrame)
        sideBorderHost:SetAllPoints(visibilityFrame)
        sideBorderHost:EnableMouse(false)
        sideBorderHost:SetFrameStrata("HIGH")
        sideBorderHost:SetFrameLevel(visibilityFrame:GetFrameLevel())
        local border = FluxBorder:ApplyTo(sideBorderHost)
        border:EnableMouse(false)
        border:SetFrameStrata("HIGH")
        -- Above button art, below the existing flyout arrows (widget + 6).
        border:SetFrameLevel(visibilityFrame:GetFrameLevel() + 4)
        if border.BackgroundFrame then
            -- FluxBorder's usual BACKGROUND tier would fall behind the map.
            local background = border.BackgroundFrame
            background:EnableMouse(false)
            background:SetFrameStrata("HIGH")
            background:SetFrameLevel(visibilityFrame:GetFrameLevel())
        end
    end
    FluxBorder:SetClassColor(sideBorderHost, 1, true)
    sideBorderHost:Show()
end

function M:RefreshAppearanceAccent()
    for _, btn in ipairs(buttonWidgets) do ApplyStyle(btn) end
    if sideBorderHost and FluxBorder then
        if InCombat() then self:RequestRefresh()
        else FluxBorder:SetClassColor(sideBorderHost, 1, true) end
    end
end

local function StopHoverTicker()
    if hoverTicker then hoverTicker:Cancel(); hoverTicker = nil end
end

local function UsesMouseover()
    return layoutMode == "side" and not IsEmbedded()
        and M:GetSetting("sideVisibility") == "mouseover"
end

local function PointerInside(frame, x, y)
    local left, right = UIUnits(frame, "GetLeft"), UIUnits(frame, "GetRight")
    local bottom, top = UIUnits(frame, "GetBottom"), UIUnits(frame, "GetTop")
    return left and right and bottom and top and right > left and top > bottom
        and x >= left and x <= right and y >= bottom and y <= top
end

local function UpdateMouseover()
    -- The outer layout root is the hover gate. The inner gate belongs to the
    -- secure combat driver, which must never undo the hover decision each tick.
    -- No transparent clickable buttons: hidden roots also close their flyouts.
    if InCombat() or not containerFrame or not UsesMouseover() then return end
    local shown = true
    if GetCursorPosition then
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        x, y = x / scale, y / scale
        shown = PointerInside(containerFrame, x, y) and true or false
        local ebs = Engine()
        local flyout = ebs and ebs.Flyout
        if not shown and flyout and flyout.GetPopup then
            for _, btn in ipairs(buttonWidgets) do
                local popup = flyout.GetPopup(btn.Widget)
                local arrow = flyout.GetArrow and flyout.GetArrow(btn.Widget)
                if (popup and popup:IsVisible() and PointerInside(popup, x, y))
                    or (arrow and arrow:IsVisible() and PointerInside(arrow, x, y)) then
                    shown = true
                    break
                end
            end
        end
    end
    if containerFrame:IsShown() ~= shown then containerFrame:SetShown(shown) end
end

local function ApplyVisibility()
    local restricted = _G.Flux and Flux.Restricted
    local wantDriver = not IsEmbedded() and layoutMode == "side"
        and M:GetSetting("hideInCombat") and M:CanHideInCombat()
    if wantDriver and not driverInstalled then
        driverInstalled = restricted.RegisterPagingDriver(visibilityFrame, "visibility", "[combat] hide; show") and true or false
    elseif not wantDriver and driverInstalled then
        if restricted.UnregisterPagingDriver(visibilityFrame, "visibility") then driverInstalled = false end
    end
    if not driverInstalled then visibilityFrame:Show() end
    if UsesMouseover() then
        UpdateMouseover()
        local timer = _G.Flux and Flux.Timer or C_Timer
        if not hoverTicker and timer and timer.NewTicker then
            hoverTicker = timer.NewTicker(0.1, UpdateMouseover)
        end
    else
        StopHoverTicker()
        containerFrame:Show()
    end
end

function M:Show()
    if InCombat() then self:RequestRefresh(); return end
    if containerFrame then
        ApplyVisibility()
    end
end

function M:Hide()
    if InCombat() then self:RequestRefresh(); return end
    StopHoverTicker()
    if boot then boot:UnregisterEvent("CURSOR_CHANGED") end
    if containerFrame then containerFrame:Hide() end
    if driverInstalled then
        local restricted = _G.Flux and Flux.Restricted
        if restricted and restricted.UnregisterPagingDriver(visibilityFrame, "visibility") then
            driverInstalled = false
        end
    end
end

function M:IsShown()
    return containerFrame and containerFrame:IsShown() or false
end

function M:PositionInWindow(parentFrame)
    if type(parentFrame) == "table" and parentFrame.frame then parentFrame = parentFrame.frame end
    if not parentFrame or not parentFrame.SetPoint then return end
    embeddedHost, embeddedVisible = parentFrame, true
    self:RefreshLayout()
end

function M:OnEmbedStateChanged(shown)
    embeddedVisible = shown and true or false
    self:RefreshLayout()
end

function M:RefreshLayout()
    if InCombat() then self:RequestRefresh(); return end
    refreshPending = false
    if IsEmbedded() then
        layoutMode = embeddedHost and embeddedVisible and "embedded" or nil
    else
        layoutMode = self:GetSetting("sideEnabled") and "side" or nil
    end
    -- Auras have independent screen anchors; keep their reserved space in sync
    -- even when disabling the strip or returning to an embedded minimap.
    if FluxMinimap and FluxMinimap.PositionBuffFrames then FluxMinimap:PositionBuffFrames() end
    if not layoutMode then
        self:Hide()
        return
    end
    if self:GetSetting("autoGrow") or (layoutMode == "side" and self:GetSetting("sideHideEmpty")) then
        boot:RegisterEvent("CURSOR_CHANGED")
    else
        boot:UnregisterEvent("CURSOR_CHANGED")
    end
    self:CreateContainer()
    self:CreateButtons()
    self:LayoutSlots()
    self:UpdateSideBorder()
    ApplyVisibility()
end

function M:RequestRefresh()
    if InCombat() then
        refreshPending = true
        local combat = _G.Flux and Flux.Combat
        if combat and combat.Defer then
            combat.Defer("minimap.extra.layout", function() M:RequestRefresh() end)
        end
        return
    end
    refreshPending = false
    if FluxMinimap and FluxMinimap.RefreshEmbeddedLayout and IsEmbedded() then
        FluxMinimap:RefreshEmbeddedLayout()
    else
        self:RefreshLayout()
    end
    if FluxMinimap and FluxMinimap.EnforcePosition then FluxMinimap:EnforcePosition() end
    -- Map movement changes the below-map boundary; settle once with current geometry.
    if not IsEmbedded() and self:GetSetting("sideEnabled") then self:RefreshLayout() end
    if FluxMinimap and FluxMinimap.UpdateQuestTrackerPosition then FluxMinimap:UpdateQuestTrackerPosition() end
    if FluxMinimap and FluxMinimap.NotifyInfoFrameLayoutChanged then FluxMinimap.NotifyInfoFrameLayoutChanged() end
end

function M:Initialize()
    if isInitialized then return end
    isInitialized = true
    LoadSavedVars()
    self:RequestRefresh()
end

boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_REGEN_DISABLED")
boot:RegisterEvent("PLAYER_REGEN_ENABLED")
boot:RegisterEvent("DISPLAY_SIZE_CHANGED")
boot:RegisterEvent("UI_SCALE_CHANGED")
boot:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        M:Initialize()
        M:RefreshButtons()
    elseif event == "PLAYER_REGEN_DISABLED" then
        StopHoverTicker()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if refreshPending then M:RequestRefresh()
        elseif containerFrame and layoutMode then ApplyVisibility() end
    elseif event == "CURSOR_CHANGED" then
        -- ClearCursor can fire synchronously before EBS saves the accepted drop.
        -- Coalesce until the callback finishes, then reconcile the spare slot.
        M:QueueRefresh()
    elseif isInitialized then
        M:RequestRefresh()
    end
end)
if _G.Flux and Flux.AfterLogin then Flux.AfterLogin(function() M:Initialize() end) end
_G.FluxMinimapButtons = M
