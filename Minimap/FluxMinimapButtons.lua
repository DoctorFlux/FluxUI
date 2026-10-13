--[[
    Minimap/FluxMinimapButtons.lua

    Character-scoped 3x5 action-button strip left of the embedded minimap.
    Extra Button widgets (EBS) — item counts come from Flux.Inventory via the engine.
]]

FluxMinimapButtons = FluxMinimapButtons or {}
local M = FluxMinimapButtons

local CONFIG = {
    NumButtons = 15,
    NumColumns = 3,
    ButtonSize = 45,
    NativeSize = 44,
    ButtonSpacing = 0,
    ContainerPadding = 4,
    Scale = 1.13,
}

local wipe = table.wipe or wipe

local containerFrame = nil
local buttonWidgets = {}
local isInitialized = false

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

local function SetFlyoutUp(btn)
    if not btn or not btn.Widget or InCombatLockdown() then
        return
    end
    btn.Widget._isMinimapButton = true
    btn.Widget:SetAttribute("flyoutDirection", "UP")
    local ebs = Engine()
    if ebs and ebs.Flyout and ebs.Flyout.BindHost then
        ebs.Flyout.BindHost(btn.Widget, { direction = "UP" })
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
    end

    btn.OnMacroRebound = function()
        SaveButtonData(slotIndex, "macro", btn.MacroIndex, btn)
    end

    btn.OnDelete = function()
        ClearButtonData(slotIndex)
    end

    local saved = GetButtonData(slotIndex)
    if saved and ApplySavedAction(btn, saved) then
        SetFlyoutUp(btn)
    end

    return btn
end

function M:CreateContainer(parentFrame)
    if containerFrame then
        containerFrame:SetParent(parentFrame)
        return containerFrame
    end

    containerFrame = CreateFrame("Frame", "FluxMinimapButtonsContainer", parentFrame)
    containerFrame:SetFrameStrata("MEDIUM")
    containerFrame:SetFrameLevel(25)

    if CONFIG.Scale and CONFIG.Scale ~= 1 then
        containerFrame:SetScale(CONFIG.Scale)
    end

    local numCols = CONFIG.NumColumns or 1
    local numRows = math.ceil(CONFIG.NumButtons / numCols)
    local slot = CONFIG.ButtonSize
    local containerWidth = (slot * numCols)
        + (CONFIG.ButtonSpacing * (numCols - 1))
        + (CONFIG.ContainerPadding * 2)
    local containerHeight = (slot * numRows)
        + (CONFIG.ButtonSpacing * (numRows - 1))
        + (CONFIG.ContainerPadding * 2)

    containerFrame:SetSize(containerWidth, containerHeight)
    containerFrame:Hide()
    return containerFrame
end

function M:CreateButtons()
    if not containerFrame then
        return
    end

    local ebs = Engine()
    for _, btn in ipairs(buttonWidgets) do
        if ebs and ebs.UnregisterButton then
            ebs.UnregisterButton(btn)
        elseif FluxBtn and FluxBtn.Unregister then
            FluxBtn.Unregister(btn)
        end
        if btn and btn.Widget then
            btn.Widget:Hide()
            btn.Widget:SetParent(nil)
        end
    end
    wipe(buttonWidgets)

    local numCols = CONFIG.NumColumns or 1
    for i = 1, CONFIG.NumButtons do
        local btn = CreateButton(containerFrame, i)
        if btn and btn.Widget then
            buttonWidgets[i] = btn
        end
    end
    M:LayoutSlots()
end

function M:RefreshButtons()
    LoadSavedVars()
    local ebs = Engine()
    for i = 1, CONFIG.NumButtons do
        local btn = buttonWidgets[i]
        if btn then
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
end

function M:LayoutSlots()
    if not containerFrame then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local visual = CONFIG.ButtonSize
    local native = NativeSize()
    local pad = CONFIG.ContainerPadding or 0
    local spacing = CONFIG.ButtonSpacing or 0
    local numCols = CONFIG.NumColumns or 1
    local numRows = math.ceil(CONFIG.NumButtons / numCols)
    local scale = visual / native
    for i = 1, CONFIG.NumButtons do
        local btn = buttonWidgets[i]
        local widget = btn and btn.Widget
        if widget then
            local col = (i - 1) % numCols
            local row = math.floor((i - 1) / numCols)
            local slot = btn.SlotFrame
            if not slot then
                slot = CreateFrame("Frame", nil, containerFrame)
                slot:EnableMouse(false)
                btn.SlotFrame = slot
            else
                slot:SetParent(containerFrame)
            end
            slot:SetSize(visual, visual)
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", containerFrame, "TOPLEFT",
                pad + col * (visual + spacing),
                -pad - row * (visual + spacing))
            if slot.SetClipsChildren then
                pcall(slot.SetClipsChildren, slot, false)
            end
            widget:SetParent(slot)
            widget:ClearAllPoints()
            widget:SetPoint("CENTER", slot, "CENTER", 0, 0)
            widget:SetSize(native, native)
            if widget.SetScale then
                widget:SetScale(scale)
            end
            slot:Show()
            widget:Show()
        end
    end
    containerFrame:SetSize(
        (visual * numCols) + (spacing * (numCols - 1)) + (pad * 2),
        (visual * numRows) + (spacing * (numRows - 1)) + (pad * 2)
    )
end

function M:RefreshAppearanceAccent()
    for i = 1, CONFIG.NumButtons do
        local btn = buttonWidgets[i]
        if btn then
            ApplyStyle(btn)
        end
    end
end

function M:Show()
    if containerFrame then
        containerFrame:Show()
    end
end

function M:Hide()
    if containerFrame then
        containerFrame:Hide()
    end
end

function M:IsShown()
    return containerFrame and containerFrame:IsShown() or false
end

--- Position at the very top-left of the embedded Map window.
--- Signature used by FluxMinimap:EmbedInFrame —
---   PositionInWindow(parentFrame, minimapWidth, infoBarHeight, inset)
--- minimapWidth / infoBarHeight are accepted for API compatibility (unused for anchor).
function M:PositionInWindow(parentFrame, minimapWidth, infoBarHeight, inset)
    -- Accept either a real Frame or a wrapper table with `.frame`.
    local anchorParent = parentFrame
    if type(anchorParent) == "table" and anchorParent.frame then
        anchorParent = anchorParent.frame
    end
    if not anchorParent or type(anchorParent) ~= "table" or not anchorParent.SetPoint then
        return
    end

    if not containerFrame then
        self:CreateContainer(anchorParent)
    else
        containerFrame:SetParent(anchorParent)
    end
    inset = tonumber(inset) or 0

    -- Top-left of the main window, offset by border inset (matches prior layout).
    containerFrame:ClearAllPoints()
    containerFrame:SetPoint("TOPLEFT", anchorParent, "TOPLEFT", -inset, -inset)

    if #buttonWidgets == 0 then
        self:CreateButtons()
    else
        self:RefreshButtons()
        self:LayoutSlots()
    end

    self:Show()
end

function M:OnEmbedStateChanged(isEmbedded)
    if isEmbedded then
        if containerFrame then
            if #buttonWidgets == 0 then
                self:CreateButtons()
            end
            self:RefreshButtons()
            self:Show()
        end
    else
        self:Hide()
    end
end

function M:Initialize()
    if isInitialized then
        return
    end
    isInitialized = true
    LoadSavedVars()

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function()
        -- Deferred hydrate: Map tab / embed may create the container later.
        if FluxBtn and FluxBtn.Compat and FluxBtn.Compat.After then
            FluxBtn.Compat.After(0.5, function()
                if containerFrame and #buttonWidgets > 0 then
                    M:RefreshButtons()
                end
            end)
        elseif C_Timer and C_Timer.After then
            C_Timer.After(0.5, function()
                if containerFrame and #buttonWidgets > 0 then
                    M:RefreshButtons()
                end
            end)
        end
    end)
end

-- Boot on login (container is created later by FluxMinimap embed)
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    M:Initialize()
end)

_G.FluxMinimapButtons = M

