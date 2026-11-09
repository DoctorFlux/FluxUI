local addonName, ns = ...

local function RefreshAppearance()
    if FluxBorder and FluxBorder.RefreshAppearanceDependents then
        FluxBorder:RefreshAppearanceDependents()
    elseif FluxBorder and FluxBorder.RefreshAllAccentedFrames then
        FluxBorder:RefreshAllAccentedFrames()
    end
end

local function BuildGeneralOptions()
    return {
    name = "General",
    type = "group",
    order = 1,
    args = {
        header = {
            type = "header",
            name = "FluxUI",
            order = 1,
        },
        settingsScope = {
            type = "select",
            name = "Settings scope",
            desc = "Account-wide shares these settings across all characters. Character-specific lets this character use its own independent settings.",
            order = 1.5,
            width = "full",
            values = {
                account = "Account-wide",
                character = "Character-specific",
            },
            sorting = { "account", "character" },
            get = function()
                return FluxOptions:IsCharacterSpecific() and "character" or "account"
            end,
            set = function(_, val)
                FluxOptions:SetCharacterSpecific(val == "character")
            end,
        },
        scopeDesc = {
            type = "description",
            name = "Account-wide shares settings across all characters. Character-specific lets this character override with its own settings (copied from account on first switch). Action bar layout has its own Settings scope on the Action Bars tab.\n",
            order = 1.6,
            fontSize = "small",
        },
        appearanceHeader = {
            type = "header",
            name = "Appearance",
            order = 10,
        },
        appearanceDesc = {
            type = "description",
            name = "Accent for FluxUI chrome: unit frames, bars, and borders. This options window uses it for the selected page, the active tab, toggles, and sliders. Extra button slots follow their category scope.\n",
            order = 11,
            fontSize = "medium",
        },
        borderAccent = {
            type = "select",
            name = "Accent",
            desc = "Class color matches your class. Default atlas leaves atlas-based art untinted (neutral grays), except on WoW Forever where it uses Blizzard's status bar gold. Custom uses the color below. Applies to borders, backdrops, and the on-state of this options window.",
            order = 12,
            width = "full",
            values = {
                class = "Class color",
                atlas = "Default atlas (no tint)",
                custom = "Custom color",
            },
            get = function()
                return FluxOptions.db.profile.appearance.borderAccent or "class"
            end,
            set = function(_, val)
                FluxOptions.db.profile.appearance.borderAccent = val
                RefreshAppearance()
            end,
        },
        customAccent = {
            type = "color",
            name = "Custom accent color",
            desc = "Used when Border accent is set to Custom.",
            order = 13,
            hasAlpha = false,
            get = function()
                local c = FluxOptions.db.profile.appearance.customAccent or { r = 1, g = 1, b = 1 }
                return c.r or 1, c.g or 1, c.b or 1
            end,
            set = function(_, r, g, b)
                local c = FluxOptions.db.profile.appearance.customAccent
                if not c then
                    c = {}
                    FluxOptions.db.profile.appearance.customAccent = c
                end
                c.r, c.g, c.b = r, g, b
                RefreshAppearance()
            end,
            hidden = function()
                return (FluxOptions.db.profile.appearance.borderAccent or "class") ~= "custom"
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
        FluxOptions:RegisterModuleOptions("general", BuildGeneralOptions)
    end
end)

