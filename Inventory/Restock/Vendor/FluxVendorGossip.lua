-- Single-choice bank/vendor automation and an addon-owned native gossip checkbox.
-- Blizzard retains the panels, native shortcuts, confirmations and interaction flow.
local _, ns = ...
local Flux = ns.Flux
local Client, Events = Flux.Client, Flux.Events
local FV = FluxVendorAuto
ns.FluxOptionsLocale = ns.FluxOptionsLocale or {}
local L = ns.FluxOptionsLocale
local settingsKeys = {vendor = "autoOpenVendorGossip", bank = "autoOpenBankGossip"}
local icons = {}
local listening, refreshed, gossipOpen = false, false, false
local selectionPending = false
local toggle

function FV.IsVendorGossipSupported()
    local gossip = C_GossipInfo
    return (Client.isCamelot or Client.isAnyClassic) and gossip ~= nil
        and type(gossip.GetOptions) == "function"
        and type(gossip.GetNumAvailableQuests) == "function"
        and type(gossip.GetNumActiveQuests) == "function"
        and type(gossip.ForceGossip) == "function"
        and type(gossip.SelectOptionByIndex) == "function"
        and type(GetFileIDFromPath) == "function"
        and Enum and Enum.GossipOptionStatus and Enum.GossipOptionStatus.Available ~= nil
        and true or false
end

local function ResolveIcon(service, path)
    if not icons[service] then
        local icon = GetFileIDFromPath(path)
        icons[service] = type(icon) == "number" and icon > 0 and icon or nil
    end
    return icons[service]
end

local function SingleChoice()
    local gossip = C_GossipInfo
    if gossip.GetNumAvailableQuests() ~= 0 or gossip.GetNumActiveQuests() ~= 0 then return end
    local options = gossip.GetOptions()
    if type(options) ~= "table" or #options ~= 1 then return end
    local option = options[1]
    if type(option) ~= "table" or option.status ~= Enum.GossipOptionStatus.Available
        or type(option.orderIndex) ~= "number" then return end
    if icons.vendor and option.icon == icons.vendor then return "vendor", option end
    if icons.bank and option.icon == icons.bank then return "bank", option end
end

local function HideTooltip(self)
    if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

local function HideToggle()
    if toggle then
        toggle.service = nil
        toggle:Hide()
    end
end

local UpdateGossip

function FV.SetGossipAutoOpen(service, enabled)
    local key = settingsKeys[service]
    if not key then return end
    FV.EnsureSettings()[key] = enabled and true or false
    FV.RefreshVendorGossip()
end

local function EnsureToggle()
    if toggle then return toggle end
    local parent = GossipFrame and GossipFrame.GreetingPanel
    if not parent then return end
    toggle = CreateFrame("CheckButton", "FluxGossipAutoOpenToggle", parent, "UICheckButtonTemplate")
    toggle:Hide()
    toggle:SetSize(22, 22)
    toggle:SetPoint("BOTTOMLEFT", GossipFrame, "BOTTOMLEFT", 8, 4)
    toggle:SetFrameLevel(parent:GetFrameLevel() + 2)
    toggle.Text:SetWidth(160)
    toggle.Text:SetJustifyH("LEFT")
    toggle.Text:SetWordWrap(false)
    toggle:SetHitRectInsets(0, -160, 0, 0)
    toggle:SetScript("OnClick", function(self, button)
        if button and button ~= "LeftButton" then UpdateGossip(false); return end
        local service = gossipOpen and GossipFrame:IsShown() and SingleChoice()
        if not service or service ~= self.service then HideToggle(); return end
        FV.SetGossipAutoOpen(service, self:GetChecked())
        UpdateGossip(true)
        -- Submit the interaction before refreshing a simultaneously open options
        -- page. Reuse its coalescer; a closed options window needs no work.
        local shell = ns.FluxOptionsShell
        if shell and shell.IsShown and shell:IsShown() and FluxOptions and FluxOptions.RefreshOpenPage then
            FluxOptions:RefreshOpenPage()
        end
    end)
    toggle:SetScript("OnEnter", function(self)
        if not gossipOpen or SingleChoice() ~= self.service then HideToggle(); return end
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.Text:GetText())
        GameTooltip:AddLine(L.GOSSIP_AUTO_OPEN_HELP, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    toggle:SetScript("OnLeave", HideTooltip)
    toggle:SetScript("OnHide", HideTooltip)
    return toggle
end

UpdateGossip = function(allowSelection)
    if not gossipOpen or selectionPending then HideToggle(); return end
    local service, option = SingleChoice()
    if not service then HideToggle(); return end
    local enabled = FV.EnsureSettings()[settingsKeys[service]] == true
    if allowSelection and enabled and not IsShiftKeyDown() then
        selectionPending = true
        HideToggle()
        -- Avoid duplicating Blizzard's own immediate single-option selection.
        if option.selectOptionWhenOnlyOption and not C_GossipInfo.ForceGossip() then return end
        C_GossipInfo.SelectOptionByIndex(option.orderIndex)
        return
    end
    local control = EnsureToggle()
    if not control then return end
    control.service = service
    control.Text:SetText(service == "bank" and L.AUTO_OPEN_BANK or L.AUTO_OPEN_VENDOR)
    control:SetChecked(enabled)
    control:Show()
end

local function OnGossipShow()
    selectionPending = false
    gossipOpen = true
    UpdateGossip(true)
end

local function OnGossipClosed()
    gossipOpen = false
    selectionPending = false
    HideToggle()
end

local function OnGossipRefreshed()
    if gossipOpen then UpdateGossip(false) end
end

function FV.RefreshVendorGossip()
    if not FV.IsVendorGossipSupported() then
        if listening then
            Events.Unregister("GOSSIP_SHOW", OnGossipShow)
            Events.Unregister("GOSSIP_CLOSED", OnGossipClosed)
            if refreshed then Events.Unregister("GOSSIP_OPTIONS_REFRESHED", OnGossipRefreshed) end
            listening, refreshed = false, false
        end
        OnGossipClosed()
        return
    end
    -- Resolve assets outside the interaction callback, including the first open.
    ResolveIcon("vendor", "Interface\\GossipFrame\\VendorGossipIcon.blp")
    ResolveIcon("bank", "Interface\\GossipFrame\\BankerGossipIcon.blp")
    if not listening then
        listening = Events.Register("GOSSIP_SHOW", OnGossipShow)
        if listening then
            Events.Register("GOSSIP_CLOSED", OnGossipClosed)
            if Events.IsValid and Events.IsValid("GOSSIP_OPTIONS_REFRESHED") then
                refreshed = Events.Register("GOSSIP_OPTIONS_REFRESHED", OnGossipRefreshed)
            end
        end
    end
    UpdateGossip(false)
end

Flux.AfterLogin(FV.RefreshVendorGossip)
