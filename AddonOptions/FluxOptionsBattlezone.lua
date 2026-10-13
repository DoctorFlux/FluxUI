local addonName = ...

local function HasMeterLayoutBackend()
    if FluxMeterLayout and FluxMeterLayout.HasMeterBackend then
        return FluxMeterLayout.HasMeterBackend()
    end
    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Details") then
        return true
    end
    if IsAddOnLoaded and IsAddOnLoaded("Details") then
        return true
    end
    if FluxMeterLayout and FluxMeterLayout.HasBlizzardDamageMeterClient
        and FluxMeterLayout.HasBlizzardDamageMeterClient() then
        return true
    end
    return false
end

local function IsBlizzardMeterBackend()
    if FluxMeterLayout and FluxMeterLayout.IsBlizzardBackend then
        return FluxMeterLayout.IsBlizzardBackend()
    end
    return HasMeterLayoutBackend()
        and not ((C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Details"))
            or (IsAddOnLoaded and IsAddOnLoaded("Details")))
end

local function MeterLayoutDescription()
    if IsBlizzardMeterBackend() then
        return "Layout editor for Blizzard’s native damage meter (presets, saved layouts, pane types, drag splits).\n|cffAAAAAAMax 3 panes · no threat meter · data may be unavailable in some content.|r\n"
    end
    return "Full layout editor for the Details! meter grid (presets, saved layouts, pane types, drag splits).\n"
end

local function BuildFluxWindowOptions()
    return {
    name = "FluxWindow",
    type = "group",
    order = 18,
    args = {
        headerTabs = {
            type = "header",
            name = "Tabs",
            order = 1,
        },
        tabsDesc = {
            type = "description",
            name = "Drag chips to reorder. Click a chip to turn that tab on or off (at least one must stay on).\n",
            order = 2,
            fontSize = "medium",
        },
        tabStrip = {
            type = "input",
            name = "",
            dialogControl = "FluxBattlezoneTabStrip",
            order = 3,
            width = "full",
            get = function() return "" end,
            set = function() end,
        },
        resetTabs = {
            type = "execute",
            name = "Reset tabs",
            desc = "Restore Map → Meter → Respec → Buttons, all enabled.",
            order = 4,
            width = "normal",
            confirm = true,
            confirmText = "Reset Flux window tabs to defaults?",
            func = function()
                if FluxWindowFrame and FluxWindowFrame.ResetTabConfigDefaults then
                    FluxWindowFrame:ResetTabConfigDefaults()
                end
                local reg = LibStub("AceConfigRegistry-3.0", true)
                if reg then reg:NotifyChange("FluxUI") end
            end,
        },
        spacer = {
            type = "description",
            name = " ",
            order = 5,
            hidden = function()
                return not HasMeterLayoutBackend()
            end,
        },
        headerMeter = {
            type = "header",
            name = "Meter layout",
            order = 10,
            hidden = function()
                return not HasMeterLayoutBackend()
            end,
        },
        meterDesc = {
            type = "description",
            name = function()
                return MeterLayoutDescription()
            end,
            order = 11,
            fontSize = "medium",
            hidden = function()
                return not HasMeterLayoutBackend()
            end,
        },
        meterEditor = {
            type = "input",
            name = "",
            dialogControl = "FluxMeterLayoutEmbed",
            order = 12,
            width = "full",
            get = function() return "" end,
            set = function() end,
            hidden = function()
                return not HasMeterLayoutBackend()
            end,
        },
        noDetails = {
            type = "description",
            name = "\n|cffAAAAAAMeter layout options appear when Details! is loaded, or when this client ships Blizzard’s damage meter.|r\n",
            order = 20,
            fontSize = "medium",
            hidden = function()
                return HasMeterLayoutBackend()
            end,
        },
    },
}
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    if FluxOptions and FluxOptions.RegisterModuleOptions then
        FluxOptions:RegisterModuleOptions("fluxwindow", BuildFluxWindowOptions)
    end
end)

