-- FluxRespec_UI_Shared.lua
-- Shared Respec tab widgets: section checkboxes and per-slot include checks.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.UI = R.UI or {}
local UI = R.UI

local function Inc()
    return R.Includes
end

--- Tiny include checkbox (Save/Load mask). Does not recapture on toggle.
function UI.MakeIncludeCheck(parent, size)
    local chk = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    chk:SetSize(size or 16, size or 16)
    chk:SetHitRectInsets(0, 0, 0, 0)
    if chk.Text then
        chk.Text:SetText("")
    end
    local fs = chk:GetFontString()
    if fs then
        fs:SetText("")
        fs:Hide()
    end
    return chk
end

function UI.WireIncludeTooltip(chk, title, body)
    chk:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title or "Include on Save and Load")
        GameTooltip:AddLine(body or "When checked, Save records this part and Load applies it. Unchecked keeps the last saved data and leaves your current setup unchanged. With No profile selected, these checks still apply to the next Save.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    chk:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

--- Section checkbox on a summary or header row. `sectionKey` is an Includes.SECTIONS value.
--- Pass `topAlign` for tall frames (gear section) so the check sits on the header line.
function UI.AttachSectionCheck(row, sectionKey, extraTooltip, topAlign)
    if not row or row.includeCheck then
        return row and row.includeCheck
    end
    local chk = UI.MakeIncludeCheck(row, 16)
    if topAlign then
        chk:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)
    else
        chk:SetPoint("LEFT", row, "LEFT", 0, 0)
    end
    chk._includeSection = sectionKey
    row.includeCheck = chk

    if row.iconBg then
        row.iconBg:ClearAllPoints()
        row.iconBg:SetPoint("LEFT", chk, "RIGHT", 2, 0)
    end

    local body = extraTooltip
        or "When checked, Save records this part and Load applies it. Unchecked keeps the last saved data and leaves your current setup unchanged."
    body = body .. " With No profile selected, these checks still apply to the next Save."
    UI.WireIncludeTooltip(chk, "Include on Save and Load", body)

    chk:SetScript("OnClick", function(self)
        local name = R.GetActiveName and R.GetActiveName()
        local profile = name and R.GetProfile and R.GetProfile(name)
        local I = Inc()
        if not I or not I.SetSection then
            return
        end
        I.SetSection(profile, sectionKey, self:GetChecked() == true)
        if UI.Refresh then
            UI.Refresh()
        end
    end)
    return chk
end

function UI.RefreshSectionCheck(row, profile, sectionKey)
    local chk = row and row.includeCheck
    if not chk then
        return
    end
    local I = Inc()
    chk:SetEnabled(true)
    if I and I.SectionEnabled then
        chk:SetChecked(I.SectionEnabled(profile, sectionKey) ~= false)
        chk:SetAlpha(1)
    else
        chk:SetChecked(true)
        chk:SetAlpha(1)
    end
end

--- Corner include check on a 26px paperdoll / rune slot button.
function UI.AttachSlotIncludeCheck(btn)
    if not btn or btn.includeCheck then
        return btn and btn.includeCheck
    end
    local chk = UI.MakeIncludeCheck(btn, 12)
    chk:SetPoint("TOPLEFT", btn, "TOPLEFT", -5, 5)
    chk:SetFrameLevel((btn:GetFrameLevel() or 0) + 6)
    btn.includeCheck = chk
    UI.WireIncludeTooltip(chk, "Include this slot", "Save and Load change this slot only when checked. Right-click the slot to toggle. With No profile selected, this still applies to the next Save.")
    return chk
end

function UI.SetSlotIncludeVisual(btn, included, sectionOn)
    if not btn then
        return
    end
    local on = included ~= false and sectionOn ~= false
    if btn.includeCheck then
        btn.includeCheck:SetChecked(included ~= false)
        btn.includeCheck:SetAlpha(sectionOn == false and 0.35 or 1)
        btn.includeCheck:SetEnabled(sectionOn ~= false)
    end
    if btn.iconTex then
        if on then
            -- Leave saturation to the strip painter for empty/match states.
        else
            btn.iconTex:SetDesaturated(true)
            btn.iconTex:SetAlpha(0.45)
        end
    end
    if not on then
        if btn.equippedBorder then
            btn.equippedBorder:Hide()
        end
        if btn.gearStatusBorder then
            btn.gearStatusBorder:Hide()
        end
    end
end
