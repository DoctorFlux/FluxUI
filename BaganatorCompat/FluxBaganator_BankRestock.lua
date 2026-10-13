-- FluxBaganator_BankRestock.lua
-- Anchors the Flux bank restock button to the left of Baganator's Transfer button.

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local BANK_VIEW_PREFIXES = {
    "Baganator_SingleViewBankViewFrame",
    "Baganator_CategoryViewBankViewFrame",
}

-- Baganator names bank views as Prefix .. skinKey (e.g. ...Frameblizzard),
-- not Prefix .. "1"/"2". Keep numeric suffixes as a legacy fallback.
local BANK_VIEW_SUFFIXES = {
    "1", "2",
    "blizzard", "blizzard_black", "dark", "elvui", "gw2_ui", "ndui",
}

local function GetRestockButton()
    return _G.FluxBankRestockButton
end

local function TagsIncludeBank(tags)
    if type(tags) ~= "table" then
        return false
    end
    for i = 1, #tags do
        if tags[i] == "bank" then
            return true
        end
    end
    return tags.bank == true
end

local function VisitBankView(view, seen, callback)
    if not view or seen[view] then
        return
    end
    seen[view] = true
    callback(view)
end

--- Enumerate every known Baganator bank ButtonFrame (all skins / view types).
function Compat.ForEachBaganatorBankView(callback)
    if type(callback) ~= "function" then
        return
    end
    local seen = {}

    local api = _G.Baganator and _G.Baganator.API
    local skins = api and api.Skins
    if skins and skins.GetAllFrames then
        local ok, frames = pcall(skins.GetAllFrames, skins)
        if ok and type(frames) == "table" then
            for i = 1, #frames do
                local entry = frames[i]
                if entry and entry.regionType == "ButtonFrame" and entry.region
                    and TagsIncludeBank(entry.tags) then
                    VisitBankView(entry.region, seen, callback)
                end
            end
        end
    end

    local currentSkin
    if skins and skins.GetCurrentSkin then
        local ok, skin = pcall(skins.GetCurrentSkin, skins)
        if ok then
            currentSkin = skin
        end
    end
    if currentSkin then
        for p = 1, #BANK_VIEW_PREFIXES do
            VisitBankView(_G[BANK_VIEW_PREFIXES[p] .. currentSkin], seen, callback)
        end
    end

    for s = 1, #BANK_VIEW_SUFFIXES do
        for p = 1, #BANK_VIEW_PREFIXES do
            VisitBankView(_G[BANK_VIEW_PREFIXES[p] .. BANK_VIEW_SUFFIXES[s]], seen, callback)
        end
    end
end

function Compat.GetActiveBaganatorBankView()
    local button = GetRestockButton()
    if button and button.FindBaganatorBankView then
        local view = button.FindBaganatorBankView()
        if view then
            return view
        end
    end

    local shown
    Compat.ForEachBaganatorBankView(function(view)
        if view.IsShown and view:IsShown() then
            shown = view
        end
    end)
    return shown
end

local function Inventory()
    return _G.Flux and _G.Flux.Inventory
end

function Compat.SyncBaganatorBankLive()
    local Inv = Inventory()
    if not Inv or not Inv.SetBaganatorBankLive then
        return
    end
    local live = false
    Compat.ForEachBaganatorBankView(function(view)
        if not (view.IsShown and view:IsShown()) then
            return
        end
        -- Shown bank chrome is enough: backup FluxInv.Bank.IsOpen used this.
        -- liveBankActive can sit on a parent a tick later than TransferButton.
        local tab = view.currentTab
        if view.liveBankActive
            or (tab and tab.isLive and not tab.isLocked)
            or view.TransferButton then
            live = true
        end
    end)
    if not live and Inv.IsBaganatorBankViewShown and Inv.IsBaganatorBankViewShown() then
        live = true
    end
    Inv.SetBaganatorBankLive(live)
end

function Compat.AttachBankRestockButton(bankView)
    local button = GetRestockButton()
    if not button or not button.AttachToBaganatorBank then
        return
    end
    bankView = bankView or Compat.GetActiveBaganatorBankView()
    if bankView then
        button.AttachToBaganatorBank(bankView)
    end
    Compat.SyncBaganatorBankLive()
end

local function WrapBankView(bankView)
    if not bankView or bankView._fluxBankRestockWrapped then
        return
    end
    bankView._fluxBankRestockWrapped = true

    if bankView.UpdateTransferButton then
        local origUpdateTransferButton = bankView.UpdateTransferButton
        bankView.UpdateTransferButton = function(self, ...)
            if origUpdateTransferButton then
                origUpdateTransferButton(self, ...)
            end
            Compat.AttachBankRestockButton(self)
        end
    end

    if bankView.OnTabFinished then
        local origOnTabFinished = bankView.OnTabFinished
        bankView.OnTabFinished = function(self, ...)
            if origOnTabFinished then
                origOnTabFinished(self, ...)
            end
            Compat.AttachBankRestockButton(self)
        end
    end

    if bankView.HookScript then
        bankView:HookScript("OnShow", function()
            Compat.AttachBankRestockButton(bankView)
        end)
        bankView:HookScript("OnHide", function()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, Compat.SyncBaganatorBankLive)
            else
                Compat.SyncBaganatorBankLive()
            end
        end)
    end
end

local function WrapExistingBankViews()
    Compat.ForEachBaganatorBankView(WrapBankView)
end

local function AttachVisibleBankRestockButton()
    Compat.AttachBankRestockButton(Compat.GetActiveBaganatorBankView())
end

local function InstallBankFrameListeners()
    if Compat._bankFrameListenersInstalled then
        return
    end
    local api = _G.Baganator and _G.Baganator.API
    if not api or not api.Skins or not api.Skins.RegisterListener then
        return
    end
    Compat._bankFrameListenersInstalled = true

    api.Skins.RegisterListener(function(details)
        if not details or details.regionType ~= "ButtonFrame" or not details.region then
            return
        end
        if not TagsIncludeBank(details.tags) then
            return
        end
        WrapBankView(details.region)
        Compat.AttachBankRestockButton(details.region)
    end)

    WrapExistingBankViews()
end

function Compat.FinalizeBankRestock()
    WrapExistingBankViews()
    InstallBankFrameListeners()
    AttachVisibleBankRestockButton()
end

function Compat.InitBankRestock()
    if Compat._bankRestockInitialized then
        return
    end
    Compat._bankRestockInitialized = true

    WrapExistingBankViews()
    InstallBankFrameListeners()

    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if registry and registry.RegisterCallback then
        registry:RegisterCallback("BankViewChanged", AttachVisibleBankRestockButton)
        registry:RegisterCallback("BankShow", AttachVisibleBankRestockButton)
        pcall(function()
            registry:RegisterCallback("BankHide", Compat.SyncBaganatorBankLive)
        end)
        -- Re-anchor when Baganator Alt-hides its top buttons (Transfer/Sort move).
        pcall(function()
            registry:RegisterCallback("SetButtonsShown", AttachVisibleBankRestockButton)
        end)
        -- Skip ViewComplete: fires on every bag transfer and re-anchors needlessly.
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("BANKFRAME_OPENED")
    frame:RegisterEvent("PLAYER_LOGIN")
    if C_PlayerInteractionManager then
        frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    end
    frame:SetScript("OnEvent", function(_, event, kind)
        if event == "PLAYER_LOGIN" then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.5, Compat.FinalizeBankRestock)
            else
                Compat.FinalizeBankRestock()
            end
            return
        end
        if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
            local PIM = Enum and Enum.PlayerInteractionType
            if PIM then
                local banker = kind == PIM.Banker
                    or (PIM.AccountBanker and kind == PIM.AccountBanker)
                    or (PIM.CharacterBanker and kind == PIM.CharacterBanker)
                if not banker then
                    return
                end
            end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0.05, AttachVisibleBankRestockButton)
            C_Timer.After(0.25, AttachVisibleBankRestockButton)
            C_Timer.After(0.6, AttachVisibleBankRestockButton)
        else
            AttachVisibleBankRestockButton()
        end
    end)
end

