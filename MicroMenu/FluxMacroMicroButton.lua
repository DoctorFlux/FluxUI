-- FluxMacroMicroButton.lua
if not FluxMicroMenu or not FluxMicroMenu.CreateMicroButton then return end

local function ForeverGamepadUI()
    local Flux = _G.Flux
    local cap = Flux and (Flux.Cap or Flux.Capabilities)
    return cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() == true
end

local clickHandler = {
    OnClick = function(self)
        if ForeverGamepadUI() then
            return
        end
        if SlashCmdList and SlashCmdList["MACRO"] then
            SlashCmdList["MACRO"]("")
        else
             -- Fallback logic
             if LoadAddOn then LoadAddOn("Blizzard_MacroUI") end
             if MacroFrame then
                 if MacroFrame:IsShown() then
                     if HideUIPanel then HideUIPanel(MacroFrame) else MacroFrame:Hide() end
                 else
                     if ShowMacroFrame then ShowMacroFrame() else MacroFrame:Show() end
                 end
             end
        end
    end,
    OnTooltip = function(tooltip)
        tooltip:AddLine(" ")
        tooltip:AddLine("<Left Click> Toggle Macros", 0.6, 0.6, 0.6)
    end
}

FluxMicroMenu:CreateMicroButton(
    "FluxMacroMicroButton", 
    "Interface\\ICONS\\INV_MISC_Note_03", 
    "Macros", 
    nil,
    clickHandler
)

local macroButton = _G.FluxMacroMicroButton
local Flux = _G.Flux
if macroButton and Flux and Flux.SecureClickProxy and ForeverGamepadUI() then
    Flux.SecureClickProxy.Attach(macroButton, {
        macrotext = "/macro",
        enabled = ForeverGamepadUI,
    })
end
