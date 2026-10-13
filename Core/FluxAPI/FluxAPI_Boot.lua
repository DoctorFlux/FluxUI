-- FluxAPI_Boot.lua — finalize exports (loads last; modern clients only)
local addonName, ns = ...
local H = ns._FluxAPICompat

FluxAPICompat.API = ns.API
FluxAPICompat.FLUX_API = FLUX_API
ns.API.FLUX_API = FLUX_API

FLUX_API.hasPlayerMana = FluxAPICompat.GetPlayerHasMana

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        -- Re-probe after load; Classic stubs can appear after SharedXML finishes.
        if ns.API and ns.API.FluxInstallSpecializationRoleCompat then
            ns.API.FluxInstallSpecializationRoleCompat()
        end
        if H and H.RefreshUnifiedBankUIFlags then
            H.RefreshUnifiedBankUIFlags()
        elseif ns._FluxAPICompat and ns._FluxAPICompat.RefreshUnifiedBankUIFlags then
            ns._FluxAPICompat.RefreshUnifiedBankUIFlags()
        end
        if FLUX_API.RefreshFocusUnitCapability then
            FLUX_API.RefreshFocusUnitCapability()
        end
        if FLUX_API.RefreshKeyringContainerState then
            FLUX_API.RefreshKeyringContainerState()
        end
        if FLUX_API.ApplyAssistedCombatCustomActionBarCompat then
            FLUX_API.ApplyAssistedCombatCustomActionBarCompat()
        end
    end
end)
-- /fluxapi stays on Core\Slash.lua (includes inventory). Do not overwrite it here.

