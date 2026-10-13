-- FluxSalvage.lua
-- Module init and PLAYER_LOGIN registration for Molinari-style salvage overlay.

FluxSalvage = FluxSalvage or {}
local S = FluxSalvage

local function InstallHooks()
    if S.IsEnabled() then
        S.HookTooltip()
        if S.HookBagButtons then
            S.HookBagButtons()
        end
    end
end

local function InvalidateCaches()
    if S.InvalidateSpellCache then
        S.InvalidateSpellCache()
    elseif S.InvalidateClassifyCache then
        S.InvalidateClassifyCache()
    end
    local Flux = _G.Flux
    local P = Flux and Flux.Inventory and Flux.Inventory.Professions
    if P and P.InvalidateSkillCaches then
        P.InvalidateSkillCaches()
    end
end

local function RegisterInvListener()
    if S._invListenerRegistered then
        return
    end
    local inv = _G.FluxInv
    if not (inv and inv.RegisterListener) then
        return
    end
    S._invListenerRegistered = true
    inv.RegisterListener("FluxSalvage_Classify", function()
        if S.InvalidateClassifyCache then
            S.InvalidateClassifyCache()
        end
    end, { tier = "light", regions = { "bags" }, deferHeavy = true })
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:RegisterEvent("SPELLS_CHANGED")
loginFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
loginFrame:RegisterEvent("ADDON_LOADED")
pcall(loginFrame.RegisterEvent, loginFrame, "SKILL_LINES_CHANGED")
loginFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_UIPanels_Game" or arg1 == "Blizzard_Bags" then
            InstallHooks()
        end
        return
    end
    if event == "SPELLS_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "SKILL_LINES_CHANGED" then
        InvalidateCaches()
        return
    end
    RegisterInvListener()
    -- Defer one frame so we register after other addons' tooltip hooks.
    if C_Timer and C_Timer.After then
        C_Timer.After(0, InstallHooks)
    else
        InstallHooks()
    end
end)

if UnitGUID and UnitGUID("player") then
    RegisterInvListener()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, InstallHooks)
    end
end

SLASH_FLUXSALVAGE1 = "/fsalvage"
SLASH_FLUXSALVAGE2 = "/fluxsalvage"
SlashCmdList["FLUXSALVAGE"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if msg == "toggle" or msg == "on" or msg == "off" then
        local enabled = msg ~= "off"
        if msg == "toggle" then
            enabled = not S.IsEnabled()
        end
        S.SetEnabled(enabled)
        if enabled then
            S.HookTooltip()
            if S.HookBagButtons then
                S.HookBagButtons()
            end
            print("|cff00ccffFluxUI|r Salvage overlay enabled.")
        else
            S.HideOverlay()
            print("|cff00ccffFluxUI|r Salvage overlay disabled.")
        end
        return
    end

    if msg == "status" then
        local spellID, spellName
        if S.GetComprehendSpell then
            spellID, spellName = S.GetComprehendSpell()
        end
        local rank = 0
        local Flux = _G.Flux
        local P = Flux and Flux.Inventory and Flux.Inventory.Professions
        if P and P.GetSkillLineRank then
            rank = P.GetSkillLineRank({ "comprehension", "comprehend" }) or 0
        end
        print("|cff00ccffFluxUI|r Salvage:",
            S.IsEnabled() and "enabled" or "disabled",
            "| modifier:", S.GetModifier(),
            "| hooks:", S._tooltipHooksInstalled and "installed" or "missing",
            "| bags:", S._bagHooksInstalled and "installed" or "missing")
        print("|cff00ccffFluxUI|r Comprehend Scroll:",
            (spellID or spellName) and ("known (" .. tostring(spellName or spellID) .. ")") or "not in spellbook",
            "| Comprehension rank:", rank)
        return
    end

    if FluxOptions and FluxOptions.OpenToSalvageTab then
        FluxOptions:OpenToSalvageTab()
        return
    end

    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("FluxUI")
        InterfaceOptionsFrame_OpenToCategory("FluxUI")
    end
end


