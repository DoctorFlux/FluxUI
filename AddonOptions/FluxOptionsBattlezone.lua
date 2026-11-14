local addonName, ns = ...

-- English fallback for the minimap layout controls; saved keys stay stable
-- when a locale supplies alternate labels through this existing catalog.
ns.FluxOptionsLocale = ns.FluxOptionsLocale or {}
local L = ns.FluxOptionsLocale
local minimapStrings = {
    MINIMAP_BUTTONS_HEADER = "Minimap extra buttons",
    MINIMAP_BUTTONS_HELP = "These layouts use the same character-specific button slots and assignments. Both layouts automatically choose button columns and size from the button count and available space. Reducing the button count keeps the hidden slots saved. Layout changes made in combat apply after combat ends.\n",
    MINIMAP_BUTTON_COUNT = "Button count",
    MINIMAP_BUTTON_COUNT_DESC = "Number of extra buttons in both layouts, or the minimum when dynamic buttons are enabled. Empty screen-side buttons can still be hidden separately. Existing assignments stay saved in their numbered slots.",
    MINIMAP_BUTTON_AUTO_GROW = "Dynamic button count",
    MINIMAP_BUTTON_AUTO_GROW_DESC = "Use Button count as the minimum in both layouts. When all slots are filled, carrying an action reveals one temporary drop slot, up to 120. Drop onto it to keep the new button; cancel or drop elsewhere and the unused slot disappears. Removing assignments shrinks the grid back toward the minimum. Saved assignments are preserved and the minimum never changes automatically.",
    MINIMAP_SIDE_HEADER = "Screen-side buttons",
    MINIMAP_SIDE_ENABLED = "Show buttons when minimap is not embedded",
    MINIMAP_SIDE_ENABLED_DESC = "Optional screen-side layout for the same saved buttons. Off by default. Buttons fill downward above the Flux Window, completing the rightmost column before starting the next column to its left.",
    MINIMAP_SIDE_SCALE = "Screen-side grid scale (%)",
    MINIMAP_SIDE_SCALE_DESC = "Scale the whole automatic screen-side grid from 10% to 200%. The default 100% uses the previous 85% size. Columns refit to the available height at every scale, with no layout padding at the minimap, screen or Flux Window.",
    MINIMAP_SIDE_START = "Start screen-side columns",
    MINIMAP_SIDE_START_DESC = "Start below the minimap, or from the top-right of the screen beside it. Always shown mode automatically moves the map, trackers and aura frames as needed to make room. Mouseover mode leaves them at their normal positions and overlays the buttons.",
    MINIMAP_SIDE_BELOW = "Below minimap",
    MINIMAP_SIDE_TOP = "Beside minimap, from screen top",
    MINIMAP_SIDE_HIDE_EMPTY = "Hide empty screen-side buttons",
    MINIMAP_SIDE_HIDE_EMPTY_DESC = "Show only assigned slots and pack them together. Assigned items remain visible even when you have none left. Carrying an action on the cursor reveals one empty slot for dropping. Embedded buttons are unaffected.",
    MINIMAP_SIDE_VISIBILITY = "Screen-side visibility",
    MINIMAP_SIDE_VISIBILITY_DESC = "Always shown automatically makes room beside the minimap and trackers. Mouseover leaves the minimap, Questie, objective tracker and aura frames in place and shows buttons over that area while the pointer is over the grid or an open flyout. Mouseover show/hide pauses during combat. The combat-hide option below can additionally hide the grid securely. Embedded buttons stay shown. For controller use, choose Always shown.",
    MINIMAP_SIDE_ALWAYS = "Always shown",
    MINIMAP_SIDE_MOUSEOVER = "Show on mouseover (freeze during combat)",
    MINIMAP_HIDE_COMBAT = "Hide screen-side buttons in combat",
    MINIMAP_HIDE_COMBAT_DESC = "Hide only the screen-side buttons during combat. Embedded minimap buttons stay visible in combat. This setting remains available while embedded and applies again when the minimap returns to its normal position. Changes made in combat apply after combat ends.",
    MINIMAP_HIDE_COMBAT_UNAVAILABLE = "Secure combat hiding of screen-side buttons is unavailable on this client. Embedded minimap buttons remain visible in combat.",
}
for key, value in pairs(minimapStrings) do L[key] = L[key] or value end

local minimapDefaults = {
    count = 15,
    sideEnabled = false, sideScale = 100,
    sideStart = "below", hideInCombat = false,
    sideHideEmpty = false, autoGrow = false,
    sideVisibility = "always",
}

local function GetMinimapSetting(key)
    local buttons = _G.FluxMinimapButtons
    if buttons and buttons.GetSetting then
        local value = buttons:GetSetting(key)
        if value ~= nil then return value end
    end
    return minimapDefaults[key]
end

local function SetMinimapSetting(key, value)
    local buttons = _G.FluxMinimapButtons
    if buttons and buttons.SetSetting then buttons:SetSetting(key, value) end
end

local function MinimapSettingsUnavailable()
    local buttons = _G.FluxMinimapButtons
    return not (buttons and buttons.GetSetting and buttons.SetSetting)
end

local function SideSettingsDisabled()
    return MinimapSettingsUnavailable() or not GetMinimapSetting("sideEnabled")
end

local function CanHideMinimapButtonsInCombat()
    local buttons = _G.FluxMinimapButtons
    return buttons and buttons.CanHideInCombat and buttons:CanHideInCombat() or false
end

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
        minimapButtonsHeader = {
            type = "header", name = L.MINIMAP_BUTTONS_HEADER, order = 30,
        },
        minimapButtonsHelp = {
            type = "description", name = L.MINIMAP_BUTTONS_HELP, order = 31,
            width = "full",
        },
        minimapButtonCount = {
            type = "range", name = L.MINIMAP_BUTTON_COUNT,
            desc = L.MINIMAP_BUTTON_COUNT_DESC, order = 32,
            min = 1, max = 120, step = 1, width = "full",
            disabled = MinimapSettingsUnavailable,
            get = function() return GetMinimapSetting("count") end,
            set = function(_, value) SetMinimapSetting("count", value) end,
        },
        minimapSideHeader = {
            type = "header", name = L.MINIMAP_SIDE_HEADER, order = 40,
        },
        minimapButtonAutoGrow = {
            type = "toggle", name = L.MINIMAP_BUTTON_AUTO_GROW,
            desc = L.MINIMAP_BUTTON_AUTO_GROW_DESC, order = 33, width = "full",
            disabled = MinimapSettingsUnavailable,
            get = function() return GetMinimapSetting("autoGrow") end,
            set = function(_, value) SetMinimapSetting("autoGrow", value) end,
        },
        minimapSideEnabled = {
            type = "toggle", name = L.MINIMAP_SIDE_ENABLED,
            desc = L.MINIMAP_SIDE_ENABLED_DESC, order = 41, width = "full",
            disabled = MinimapSettingsUnavailable,
            get = function() return GetMinimapSetting("sideEnabled") end,
            set = function(_, value) SetMinimapSetting("sideEnabled", value) end,
        },
        minimapSideScale = {
            type = "range", name = L.MINIMAP_SIDE_SCALE,
            desc = L.MINIMAP_SIDE_SCALE_DESC, order = 43,
            min = 10, max = 200, step = 1, width = "full",
            disabled = SideSettingsDisabled,
            get = function() return GetMinimapSetting("sideScale") end,
            set = function(_, value) SetMinimapSetting("sideScale", value) end,
        },
        minimapSideStart = {
            type = "select", name = L.MINIMAP_SIDE_START,
            desc = L.MINIMAP_SIDE_START_DESC, order = 44, width = "full",
            values = { below = L.MINIMAP_SIDE_BELOW, top = L.MINIMAP_SIDE_TOP },
            sorting = { "below", "top" }, disabled = SideSettingsDisabled,
            get = function() return GetMinimapSetting("sideStart") end,
            set = function(_, value) SetMinimapSetting("sideStart", value) end,
        },
        minimapHideInCombat = {
            type = "toggle", name = L.MINIMAP_HIDE_COMBAT, order = 45,
            desc = function()
                if CanHideMinimapButtonsInCombat() then return L.MINIMAP_HIDE_COMBAT_DESC end
                return L.MINIMAP_HIDE_COMBAT_UNAVAILABLE
            end,
            width = "full",
            disabled = function()
                return MinimapSettingsUnavailable() or not CanHideMinimapButtonsInCombat()
            end,
            get = function() return GetMinimapSetting("hideInCombat") end,
            set = function(_, value) SetMinimapSetting("hideInCombat", value) end,
        },
        minimapSideHideEmpty = {
            type = "toggle", name = L.MINIMAP_SIDE_HIDE_EMPTY,
            desc = L.MINIMAP_SIDE_HIDE_EMPTY_DESC, order = 42, width = "full",
            disabled = SideSettingsDisabled,
            get = function() return GetMinimapSetting("sideHideEmpty") end,
            set = function(_, value) SetMinimapSetting("sideHideEmpty", value) end,
        },
        minimapSideVisibility = {
            type = "select", name = L.MINIMAP_SIDE_VISIBILITY,
            desc = L.MINIMAP_SIDE_VISIBILITY_DESC, order = 44.2, width = "full",
            values = { always = L.MINIMAP_SIDE_ALWAYS, mouseover = L.MINIMAP_SIDE_MOUSEOVER },
            sorting = { "always", "mouseover" }, disabled = SideSettingsDisabled,
            get = function() return GetMinimapSetting("sideVisibility") end,
            set = function(_, value) SetMinimapSetting("sideVisibility", value) end,
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

