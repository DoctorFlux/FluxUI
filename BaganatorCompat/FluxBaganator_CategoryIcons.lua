-- FluxBaganator_CategoryIcons.lua
-- Respec profile / preset icons on Baganator equipment-set category headers only.
-- Parent section "Equipment Set" is created by FluxBaganator_EquipmentSetSection.lua.

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local EQUIPMENT_SETS_SOURCE = "default_auto_equipment_sets"
local ICON_SIZE = 20
local ICON_PADDING = 5

local categoryButtonMixinHooked = false

local function StripCategoryLabel(text)
    if not text or text == "" then
        return nil
    end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("%s*%(%d+%)%s*$", "")
    return text:match("^%s*(.-)%s*$")
end

local function GetIconExtraWidth(label)
    local icon = label and label.FluxCategoryIcon
    if icon and icon:IsShown() then
        return ICON_SIZE + ICON_PADDING
    end
    return 0
end

local function EnsureCategoryIconTexture(label)
    if label.FluxCategoryIcon then
        return label.FluxCategoryIcon
    end
    local icon = label:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:Hide()
    label.FluxCategoryIcon = icon
    return icon
end

--- Raw text width only (excludes Flux icon). Used for layout math.
local function GetRawTextWidth(fontString)
    if not fontString then
        return 0
    end
    local orig = fontString._fluxOrigGetUnboundedStringWidth
    if orig then
        return orig(fontString) or 0
    end
    return fontString:GetUnboundedStringWidth() or 0
end

--- Baganator packing sizes labels from GetUnboundedStringWidth(). Include the
--- icon so long set names get a dynamic width budget and do not steal space
--- from (or bleed into) neighboring equipment-set labels.
local function WrapFontStringWidth(label)
    local fontString = label and label.GetFontString and label:GetFontString()
    if not fontString or fontString._fluxWidthWrapped then
        return
    end
    fontString._fluxWidthWrapped = true
    local orig = fontString.GetUnboundedStringWidth
    fontString._fluxOrigGetUnboundedStringWidth = orig
    fontString.GetUnboundedStringWidth = function(self)
        return (orig(self) or 0) + GetIconExtraWidth(label)
    end
end

local function ResetCategoryLabelLayout(label)
    local icon = label.FluxCategoryIcon
    if icon then
        icon:Hide()
    end
    local fontString = label:GetFontString()
    if not fontString then
        return
    end
    fontString:ClearAllPoints()
    fontString:SetPoint("LEFT")
    fontString:SetPoint("RIGHT")
end

--- Desired natural size (icon + text). Packing may clamp width afterward.
local function SyncCategoryLabelMetrics(label)
    local fontString = label and label.GetFontString and label:GetFontString()
    if not fontString then
        return
    end
    local extra = GetIconExtraWidth(label)
    local textWidth = GetRawTextWidth(fontString)
    local totalWidth = textWidth + extra
    local lineHeight = fontString:GetLineHeight() or 0
    local height = lineHeight
    if extra > 0 then
        height = math.max(lineHeight, ICON_SIZE)
    end
    if totalWidth > 0 and height > 0 then
        label:SetSize(totalWidth, height)
    end
end

--- Keep icon + text inside the packing-assigned width.
--- Full name when the budget fits; truncate only when packing clamps for space.
local function ReflowCategoryLabelIcon(label)
    local icon = label.FluxCategoryIcon
    local fontString = label:GetFontString()
    if not icon or not icon:IsShown() or not fontString then
        return
    end
    local labelWidth = label:GetWidth() or 0
    local textMax = math.max(0, labelWidth - ICON_SIZE - ICON_PADDING)
    icon:ClearAllPoints()
    icon:SetPoint("LEFT", label, "LEFT", 0, 0)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    fontString:ClearAllPoints()
    fontString:SetPoint("LEFT", icon, "RIGHT", ICON_PADDING, 0)
    fontString:SetPoint("RIGHT", label, "RIGHT", 0, 0)
    if fontString.SetWidth then
        fontString:SetWidth(textMax)
    end
    local lineHeight = fontString:GetLineHeight() or 0
    local height = math.max(lineHeight, ICON_SIZE)
    if (label:GetHeight() or 0) < height then
        label:SetHeight(height)
    end
end

function Compat.ApplyCategoryLabelIcon(label)
    if not label or not label.GetFontString then
        return
    end

    WrapFontStringWidth(label)

    if label.source ~= EQUIPMENT_SETS_SOURCE then
        ResetCategoryLabelLayout(label)
        return
    end

    local setName = StripCategoryLabel(label.GetText and label:GetText())
    local texture = setName and Compat.GetCategoryIcon and Compat.GetCategoryIcon(setName)
    if not texture or texture == "" then
        ResetCategoryLabelLayout(label)
        SyncCategoryLabelMetrics(label)
        return
    end

    local icon = EnsureCategoryIconTexture(label)
    local fontString = label:GetFontString()
    icon:SetTexture(texture)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:Show()
    icon:ClearAllPoints()
    icon:SetPoint("LEFT", label, "LEFT", 0, 0)
    fontString:ClearAllPoints()
    fontString:SetPoint("LEFT", icon, "RIGHT", ICON_PADDING, 0)
    fontString:SetPoint("RIGHT", label, "RIGHT", 0, 0)
    fontString:Show()
    SyncCategoryLabelMetrics(label)
    ReflowCategoryLabelIcon(label)
end

local function WrapCategoryLabelWidth(label)
    if label._fluxCategoryWidthWrapped then
        return
    end
    label._fluxCategoryWidthWrapped = true

    -- Packing SetWidth(W) already uses icon-aware unbounded width, so W is the
    -- hard max (layout / remaining space). Reflow icon + text inside it.
    -- Instance wrap only — never hooksecurefunc Frame.SetWidth (nameplate Layout).
    local origSetWidth = label.SetWidth
    label.SetWidth = function(self, width)
        origSetWidth(self, width)
        if self._fluxCategoryWidthAdjusting then
            return
        end
        if GetIconExtraWidth(self) <= 0 or not width then
            return
        end
        self._fluxCategoryWidthAdjusting = true
        local height = math.max(self:GetFontString() and self:GetFontString():GetLineHeight() or 0, ICON_SIZE)
        if (self:GetHeight() or 0) < height then
            self:SetHeight(height)
        end
        ReflowCategoryLabelIcon(self)
        self._fluxCategoryWidthAdjusting = false
    end
end

local function WrapCategoryLabel(self)
    if self._fluxCategoryIconWrapped then
        return
    end
    self._fluxCategoryIconWrapped = true

    EnsureCategoryIconTexture(self)
    WrapFontStringWidth(self)
    WrapCategoryLabelWidth(self)

    hooksecurefunc(self, "SetText", function(button)
        Compat.ApplyCategoryLabelIcon(button)
    end)
end

local function HookCategoryButtonMixin()
    local mixin = _G.BaganatorCategoryViewsCategoryButtonMixin
    if not mixin or categoryButtonMixinHooked then
        return mixin ~= nil
    end
    categoryButtonMixinHooked = true

    hooksecurefunc(mixin, "OnLoad", WrapCategoryLabel)
    hooksecurefunc(mixin, "Resize", function(label)
        Compat.ApplyCategoryLabelIcon(label)
    end)
    return true
end

function Compat.InitCategoryIcons()
    if Compat._categoryIconsInitialized then
        return
    end

    if HookCategoryButtonMixin() then
        Compat._categoryIconsInitialized = true
        if Compat.RequestBaganatorRefresh then
            Compat.RequestBaganatorRefresh(true)
        end
        return
    end

    if Compat._categoryIconsRetryScheduled or not C_Timer or not C_Timer.After then
        return
    end
    Compat._categoryIconsRetryScheduled = true
    C_Timer.After(0, function()
        Compat._categoryIconsRetryScheduled = false
        Compat.InitCategoryIcons()
    end)
end
