-- Retail: paper doll tweaks — item level X.Y, unified "Crit"/"Haste" labels (no melee/spell/ranged wording).
local _, ns = ...
local module = ns.CharacterStats
if not (module and module.isRetail) then return end

local ilvlHookDone = false
local critHasteLabelHookDone = false

local function InstallPaperDollItemLevelDecimalHook()
    if ilvlHookDone or type(hooksecurefunc) ~= "function" then return end
    if type(_G.PaperDollFrame_SetItemLevel) ~= "function" then return end
    ilvlHookDone = true

    hooksecurefunc("PaperDollFrame_SetItemLevel", function(statFrame, unit)
        -- Pin hooks must run even when ilvl data is missing (GetRetailStatKey is nil on this frame).
        if unit == "player" and statFrame and statFrame.Value then
            local info = rawget(_G, "FluxInfoFrame")
            if info and info.HookRetailPaperDollStatFrame then
                info.HookRetailPaperDollStatFrame(statFrame)
            end
        end
        if unit ~= "player" or not statFrame or not statFrame.Value then return end
        local _, avgEquipped = GetAverageItemLevel()
        if type(avgEquipped) ~= "number" then return end
        local minIlvl = 0
        if C_PaperDollInfo and C_PaperDollInfo.GetMinItemLevel then
            local ok, m = pcall(C_PaperDollInfo.GetMinItemLevel)
            if ok and type(m) == "number" then
                minIlvl = m
            end
        end
        local display = math.max(minIlvl, avgEquipped)
        statFrame.Value:SetFormattedText("%.1f", display)
        statFrame.numericValue = display
    end)
end

--- Dragonflight+ uses one crit and one haste rating; keep the stats list labels short.
local function InstallPaperDollCritHasteShortLabels()
    if critHasteLabelHookDone or type(hooksecurefunc) ~= "function" then return end
    if type(_G.PaperDollFrame_SetCritChance) ~= "function" or type(_G.PaperDollFrame_SetHaste) ~= "function" then
        return
    end
    critHasteLabelHookDone = true

    local function applyShortLabel(statFrame)
        if not statFrame or not statFrame.Label or not statFrame.Label.SetText then return end
        local fmt = type(_G.STAT_FORMAT) == "string" and _G.STAT_FORMAT or "%s"
        return fmt
    end

    hooksecurefunc("PaperDollFrame_SetCritChance", function(statFrame, unit)
        if unit ~= "player" then return end
        local fmt = applyShortLabel(statFrame)
        if fmt then statFrame.Label:SetText(format(fmt, "Crit")) end
        local info = rawget(_G, "FluxInfoFrame")
        if info and info.HookRetailPaperDollPoolStatFrame and statFrame then
            info.HookRetailPaperDollPoolStatFrame(statFrame, "crit")
        end
    end)

    hooksecurefunc("PaperDollFrame_SetHaste", function(statFrame, unit)
        if unit ~= "player" then return end
        local fmt = applyShortLabel(statFrame)
        if fmt then statFrame.Label:SetText(format(fmt, "Haste")) end
        local info = rawget(_G, "FluxInfoFrame")
        if info and info.HookRetailPaperDollPoolStatFrame and statFrame then
            info.HookRetailPaperDollPoolStatFrame(statFrame, "haste")
        end
    end)
end

local function InstallRetailPaperDollHooks()
    InstallPaperDollItemLevelDecimalHook()
    InstallPaperDollCritHasteShortLabels()
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_UIPanels_Game" or arg1 == "Blizzard_CharacterUI" then
            InstallRetailPaperDollHooks()
        end
    elseif event == "PLAYER_LOGIN" then
        InstallRetailPaperDollHooks()
    end
end)


