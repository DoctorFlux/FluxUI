-- FluxRespec_UI_Gear.lua
-- Gear-strip slot include checks.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.UI = R.UI or {}
local UI = R.UI
UI.Gear = UI.Gear or {}
local Gear = UI.Gear

local function Inc()
    return R.Includes
end

function Gear.AttachSlotChecks(section)
    if not section or not section.gearSlotButtons then
        return
    end
    for slotID, btn in pairs(section.gearSlotButtons) do
        local chk = UI.AttachSlotIncludeCheck(btn)
        chk:SetScript("OnClick", function(self)
            local name = R.GetActiveName and R.GetActiveName()
            local profile = name and R.GetProfile and R.GetProfile(name) or nil
            local I = Inc()
            if not I or not I.SetGearStripSlot then
                return
            end
            local owner = I.GearStripOwner and select(1, I.GearStripOwner(profile))
            if not owner then
                return
            end
            I.SetGearStripSlot(profile, btn.slotID, self:GetChecked() == true)
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
                if not I or not I.GearStripSlotEnabled or not I.SetGearStripSlot then
                    return
                end
                local on = I.GearStripSlotEnabled(profile, self.slotID)
                I.SetGearStripSlot(profile, self.slotID, not on)
                if UI.Refresh then
                    UI.Refresh()
                end
            end)
        end
    end
end

function Gear.RefreshSlotChecks(section, profile)
    if not section or not section.gearSlotButtons then
        return
    end
    local I = Inc()
    local sectionOn = true
    if I and I.SectionEnabled then
        sectionOn = I.SectionEnabled(profile, "equipment") ~= false
    end
    -- Named equipment preset slot mask is independent of the profile gear section.
    local preset = I and I.ActiveEquipmentPreset and select(1, I.ActiveEquipmentPreset())
    if preset then
        sectionOn = true
    end
    for slotID, btn in pairs(section.gearSlotButtons) do
        local included = true
        if I and I.GearStripSlotEnabled then
            included = I.GearStripSlotEnabled(profile, slotID) ~= false
        end
        if btn.includeCheck then
            local owner = I and I.GearStripOwner and select(1, I.GearStripOwner(profile))
            btn.includeCheck:SetEnabled(owner ~= nil and sectionOn)
        end
        UI.SetSlotIncludeVisual(btn, included, sectionOn)
        if (not included or not sectionOn) and btn.iconTex and btn.iconTex:IsShown() then
            btn.iconTex:SetDesaturated(true)
            btn.iconTex:SetAlpha(0.45)
        end
    end
    if section.slotStrip then
        local dim = I and I.SectionEnabled
            and not I.SectionEnabled(profile, "equipment") and not preset
        section.slotStrip:SetAlpha(dim and 0.45 or 1)
    end
end

R.UI.Gear = Gear
