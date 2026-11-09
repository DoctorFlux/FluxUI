-- FluxReloadMicroButton.lua
if not FluxMicroMenu or not FluxMicroMenu.CreateMicroButton then return end

FluxMicroMenu:CreateMicroButton(
    "FluxReloadMicroButton", 
    "Interface\\Buttons\\UI-RefreshButton", 
    "Reload UI", 
    "FLUXRELOADUI", 
    function()
        if ReloadUI then ReloadUI() end
    end
)
