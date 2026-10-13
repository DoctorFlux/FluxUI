-- FluxRespec_UI_Runes.lua
-- SoD rune-strip per-slot include checks.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.UI = R.UI or {}
local UI = R.UI
UI.RunesUI = UI.RunesUI or {}
local RunesUI = UI.RunesUI

local function Inc()
    return R.Includes
end

function RunesUI.AttachSlotChecks(section)
    if not section or not section.runeSlotButtons then
        return
    end
    for slotID, btn in pairs(section.runeSlotButtons) do
        local chk = UI.AttachSlotIncludeCheck(btn)
        chk:SetScript("OnClick", function(self)
            local name = R.GetActiveName and R.GetActiveName()
            local profile = name and R.GetProfile and R.GetProfile(name) or nil
            local I = Inc()
            if not I or not I.SetRuneStripSlot then
                return
            end
            local owner = I.RuneStripOwner and select(1, I.RuneStripOwner(profile))
            if not owner then
                return
            end
            I.SetRuneStripSlot(profile, btn.slotID, self:GetChecked() == true)
            if UI.Refresh then
                UI.Refresh()
            end
        end)
        if not btn._includeRightClickWired then
            btn._includeRightClickWired = true
            btn:HookScript("OnMouseUp", function(self, button)
                if button ~= "RightButton" then
                    return
                end
                local name = R.GetActiveName and R.GetActiveName()
                local profile = name and R.GetProfile and R.GetProfile(name) or nil
                local I = Inc()
                if not I or not I.RuneStripSlotEnabled or not I.SetRuneStripSlot then
                    return
                end
                local on = I.RuneStripSlotEnabled(profile, self.slotID)
                I.SetRuneStripSlot(profile, self.slotID, not on)
                if UI.Refresh then
                    UI.Refresh()
                end
            end)
        end
    end
end

function RunesUI.RefreshSlotChecks(section, profile)
    if not section or not section.runeSlotButtons then
        return
    end
    local I = Inc()
    local sectionOn = true
    if I and I.SectionEnabled then
        sectionOn = I.SectionEnabled(profile, "runes") ~= false
    end
    local preset = I and I.ActiveRunePreset and select(1, I.ActiveRunePreset())
    if preset then
        sectionOn = true
    end
    for slotID, btn in pairs(section.runeSlotButtons) do
        local included = true
        if I and I.RuneStripSlotEnabled then
            included = I.RuneStripSlotEnabled(profile, slotID) ~= false
        end
        if btn.includeCheck then
            local owner = I and I.RuneStripOwner and select(1, I.RuneStripOwner(profile))
            btn.includeCheck:SetEnabled(owner ~= nil and sectionOn)
        end
        UI.SetSlotIncludeVisual(btn, included, sectionOn)
        if (not included or not sectionOn) and btn.iconTex and btn.iconTex:IsShown() then
            btn.iconTex:SetDesaturated(true)
            btn.iconTex:SetAlpha(0.45)
        elseif btn.iconTex then
            btn.iconTex:SetDesaturated(false)
            btn.iconTex:SetAlpha(1)
        end
    end
    if section.runeStrip then
        if I and I.SectionEnabled and not I.SectionEnabled(profile, "runes") and not preset then
            section.runeStrip:SetAlpha(0.45)
        else
            section.runeStrip:SetAlpha(1)
        end
    end
end

R.UI.RunesUI = RunesUI
