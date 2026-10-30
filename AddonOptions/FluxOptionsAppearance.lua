local addonName, ns = ...

local function RefreshAppearance()
    if FluxBorder and FluxBorder.RefreshAppearanceDependents then
        FluxBorder:RefreshAppearanceDependents()
    end
end

local function BuildAppearanceOptions()
    return {
        name = "Appearance",
        type = "group",
        order = 2,
        args = {
            header = { type = "header", name = "Borders and buttons", order = 1 },
            description = {
                type = "description",
                name = "Minecraft style uses the original inventory bevel, slot and button pixels from your local Minecraft Java 1.20.1 installation. FluxBorder keeps its existing corners, edges and UV coordinates.\n",
                order = 2,
                fontSize = "medium",
            },
            style = {
                type = "select",
                name = "UI style",
                desc = "Changes FluxUI border art and supported button frames. The Minecraft textures are built locally from your installed game and are not included in the public addon.",
                order = 3,
                width = "full",
                values = {
                    default = "FluxUI default",
                    minecraft = "Minecraft",
                },
                sorting = { "default", "minecraft" },
                get = function()
                    return FluxOptions.db.profile.appearance.style or "default"
                end,
                set = function(_, val)
                    FluxOptions.db.profile.appearance.style = val
                    RefreshAppearance()
                end,
            },
            accentHeader = { type = "header", name = "Accent", order = 10 },
            accentDesc = {
                type = "description",
                name = "The default style tints FluxUI chrome with this accent. Minecraft panel borders keep their original gray pixels; selected options and other accent surfaces still use this color.\n",
                order = 11,
                fontSize = "medium",
            },
            borderAccent = {
                type = "select",
                name = "Accent",
                desc = "Class color matches your class. Default atlas leaves atlas-based art untinted, except on WoW Forever where it uses Blizzard's status bar gold. Custom uses the color below.",
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
                desc = "Used when Accent is set to Custom.",
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
        FluxOptions:RegisterModuleOptions("appearance", BuildAppearanceOptions)
    end
end)
