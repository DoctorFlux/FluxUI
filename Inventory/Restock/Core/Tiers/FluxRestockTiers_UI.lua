--[[
    Restock/Core/Tiers/FluxRestockTiers_UI.lua

    Inline restock-target EditBox for ExtraButtons (Food/Water/pots/bandage).
    Saves via Tiers.SetTarget → _FluxUI_CharSavedVars.Restock (same as Options panel).
]]

local Tiers = FluxRestockTiers
local P = Tiers._Private

local function GetEditParent(btn)
    return (btn and btn.SlotFrame) or (btn and btn.Widget)
end

local function After(delay, fn)
    if P and P.After then
        P.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

local function EnsureEditBox(btn, kind)
    if btn._fluxCombatRestockEdit then
        btn._fluxCombatRestockEdit._kind = kind
        local existing = btn._fluxCombatRestockEdit
        existing:SetSize(52, 28)
        local fontPath, _, fontFlags = existing:GetFont()
        if fontPath then
            existing:SetFont(fontPath, 16, fontFlags)
        end
        return existing
    end
    local parent = GetEditParent(btn)
    if not parent then
        return nil
    end
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(52, 28)
    editBox:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -1, 1)
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetJustifyH("RIGHT")
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(4)
    editBox:SetFrameLevel(parent:GetFrameLevel() + 25)
    editBox:Hide()
    editBox._kind = kind
    editBox._parentBtn = btn

    -- Enlarge the typed digits beyond the default InputBoxTemplate font.
    local fontPath, _, fontFlags = editBox:GetFont()
    if fontPath then
        editBox:SetFont(fontPath, 16, fontFlags)
    end

    editBox:SetScript("OnEnterPressed", function(self)
        Tiers.SetTarget(self._kind, tonumber(self:GetText()) or 0)
        self._commit = true
        self:ClearFocus()
        self:Hide()
        if _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive()
            and _G.FluxRestockPanel_RequestRefresh then
            pcall(_G.FluxRestockPanel_RequestRefresh)
        end
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(Tiers.GetTarget(self._kind)))
        self:ClearFocus()
        self:Hide()
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        if self._commit then
            self._commit = nil
        elseif self:IsShown() then
            Tiers.SetTarget(self._kind, tonumber(self:GetText()) or 0)
            if _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive()
                and _G.FluxRestockPanel_RequestRefresh then
                pcall(_G.FluxRestockPanel_RequestRefresh)
            end
        end
        self:Hide()
    end)
    editBox:SetScript("OnHide", function(self)
        local b = self._parentBtn
        if b then
            b._fluxRestockEditActive = false
            if b.WCount then
                b.WCount:Show()
            end
        end
    end)

    btn._fluxCombatRestockEdit = editBox
    return editBox
end

--- Open/close the inline qty editor (out of combat only).
function Tiers.ToggleEditBox(btn, kind)
    if not btn or not kind or InCombatLockdown() then
        return
    end
    if not P.KIND_FIELDS or not P.KIND_FIELDS[kind] then
        return
    end
    local editBox = EnsureEditBox(btn, kind)
    if not editBox then
        return
    end
    if editBox:IsShown() then
        editBox:ClearFocus()
        editBox:Hide()
        return
    end
    editBox._kind = kind
    editBox:SetText(tostring(Tiers.GetTarget(kind) or 0))
    editBox._commit = nil
    btn._fluxRestockEditActive = true
    if btn.WCount then
        btn.WCount:Hide()
    end
    editBox:Show()
    editBox:HighlightText()
    After(0, function()
        if editBox:IsShown() then
            editBox:SetFocus()
        end
    end)
end

local RESTOCK_PROXY = {
    food = "/click FluxMacroProxy_FoodRestockToggle",
    water = "/click FluxMacroProxy_WaterRestockToggle",
    bandage = "/click FluxMacroProxy_BandageRestockToggle",
    healPotion = "/click FluxMacroProxy_HealPotionRestockToggle",
    manaPotion = "/click FluxMacroProxy_ManaPotionRestockToggle",
}

function Tiers.GetRestockProxyMacro(kind)
    return RESTOCK_PROXY[kind]
end

--- Wire secure click → proxy → ToggleEditBox.
--- canCraftOrConjure: when true, restock is on middle (type3); else right (type2).
function Tiers.WireRestockClick(kind, btn, canCraftOrConjure)
    if not btn or not btn.Widget or not kind then
        return
    end
    btn._fluxRestockKind = kind
    btn._fluxRestockCanCraft = canCraftOrConjure and true or false
    if InCombatLockdown() then
        return
    end
    local widget = btn.Widget
    local proxy = RESTOCK_PROXY[kind]
    if not proxy then
        return
    end
    if canCraftOrConjure then
        widget:SetAttribute("type3", "macro")
        widget:SetAttribute("macrotext3", proxy)
    else
        widget:SetAttribute("type2", "macro")
        widget:SetAttribute("macrotext2", proxy)
    end
end

--- setClickHint: "right" | "middle" | "shift-middle" | "shift-right" | nil
--- skipLeadingBlank: when true (EBS Flux block), do not prepend a blank line.
function Tiers.AppendRestockTooltipLines(tip, kind, setClickHint, labelOverride, skipLeadingBlank)
    if not tip or not kind then
        return
    end
    local current = 0
    if Tiers.GetTierCount then
        current = Tiers.GetTierCount(kind) or 0
    end
    local target = Tiers.GetTarget(kind) or 0
    local label = labelOverride or (P.KIND_LABEL and P.KIND_LABEL[kind]) or "Item"
    if not skipLeadingBlank then
        tip:AddLine(" ")
    end
    -- Restock count + set-target hint on one line.
    if setClickHint == "middle" then
        tip:AddLine(
            string.format("%s restock: %d / %d (middle-click to set)", label, current, target),
            0.8, 0.8, 0.8
        )
    elseif setClickHint == "shift-middle" then
        tip:AddLine(
            string.format("%s restock: %d / %d (shift + middle-click to set)", label, current, target),
            0.8, 0.8, 0.8
        )
    elseif setClickHint == "shift-right" then
        tip:AddLine(
            string.format("%s restock: %d / %d (shift + right-click to set)", label, current, target),
            0.8, 0.8, 0.8
        )
    elseif setClickHint == "right" then
        tip:AddLine(
            string.format("%s restock: %d / %d (right-click to set)", label, current, target),
            0.8, 0.8, 0.8
        )
    else
        tip:AddLine(string.format("%s restock: %d / %d", label, current, target), 0.8, 0.8, 0.8)
    end
end

_G.FluxRestockTiers = Tiers
return Tiers
