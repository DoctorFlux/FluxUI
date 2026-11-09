-- Hide TacoTip's PaperDoll ilvl / GearScore (Flux CSC rows are the only source on character sheet).
-- TacoTip registers PaperDollFrame OnShow with TT.RefreshCharacterFrame before hooksecurefunc can wrap it,
-- so we also HookScript OnShow here to Hide() after TacoTip runs.
local _, ns = ...
local module = ns.CharacterStats
if not (module and module.useClassicPaperDollChrome) then return end

local hookedRefresh = false
local paperDollGuardInstalled = false

local function HideTacoTipPaperDollIlvlGs()
    local g = _G
    local widgets = {
        g.PersonalGearScore,
        g.PersonalGearScoreText,
        g.PersonalAvgItemLvl,
        g.PersonalAvgItemLvlText,
    }
    for i = 1, #widgets do
        local w = widgets[i]
        if w and w.Hide then
            w:Hide()
        end
    end
    local gsTitle = g.PersonalGearScoreText
    if gsTitle and gsTitle.mover and gsTitle.mover.Hide then
        gsTitle.mover:Hide()
    end
    local ilvlTitle = g.PersonalAvgItemLvlText
    if ilvlTitle and ilvlTitle.mover and ilvlTitle.mover.Hide then
        ilvlTitle.mover:Hide()
    end
end

local function InstallPaperDollOnShowGuard()
    if paperDollGuardInstalled then return end
    local pd = _G.PaperDollFrame
    if not pd or not pd.HookScript then return end
    paperDollGuardInstalled = true
    pd:HookScript("OnShow", function()
        HideTacoTipPaperDollIlvlGs()
    end)
end

local function TryHookTacoTip()
    local TT = _G.TacoTip
    if not TT or type(TT.RefreshCharacterFrame) ~= "function" then return end

    if not hookedRefresh and type(hooksecurefunc) == "function" then
        hookedRefresh = true
        hooksecurefunc(TT, "RefreshCharacterFrame", HideTacoTipPaperDollIlvlGs)
    end

    InstallPaperDollOnShowGuard()
    HideTacoTipPaperDollIlvlGs()
end

function module.InstallTacoTip()
    TryHookTacoTip()
    return hookedRefresh or paperDollGuardInstalled
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "TacoTip" then
        TryHookTacoTip()
        return
    end
    if event == "PLAYER_LOGIN" then
        TryHookTacoTip()
    end
end)


