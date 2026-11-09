-- FluxConfigMicroButton.lua
-- MicroMenu button that opens the FluxUI Options window.
-- Off by default in the MicroMenu tab. The chat column has the same gear.
if not FluxMicroMenu or not FluxMicroMenu.CreateMicroButton then return end

local clickHandler = {
    OnClick = function(self, button)
        if not FluxOptions then return end
        if button == "RightButton" then
            FluxOptions:OpenBlizzardOptions()
        else
            FluxOptions:ToggleConfig()
        end
    end,
}

local btn = FluxMicroMenu:CreateMicroButton(
    "FluxConfigMicroButton",
    "Interface\\Icons\\INV_Misc_Gear_01",
    "FluxUI Options",
    nil,
    clickHandler
)

if btn then
    btn:RegisterForClicks("AnyUp")

    if btn.icon then
        btn.icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    end

    btn:HookScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffffffffLeft-Click|r Open FluxUI Options", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("|cffffffffRight-Click|r Open Blizzard Settings", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end
    end)

    if FluxMicroMenu.Rebuild then
        FluxMicroMenu:Rebuild()
    end
end
