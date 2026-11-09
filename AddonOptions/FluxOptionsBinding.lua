-- AddonOptions/FluxOptionsBinding.lua
-- FluxUI Options tab: Binding browser (spellbook schools + embedded editor).
-- Works in both /fluxui and Blizzard Settings → AddOns → FluxUI.

local addonName = ...

local function BuildBindingOptions()
    return {
        name = "Binding",
        type = "group",
        order = 55,
        args = {
            -- Full-pane embed; AceGUIWidget-FluxBindingBrowserEmbed sizes to the host
            -- (FluxUI Options window or Blizzard Settings canvas).
            browser = {
                type = "description",
                name = " ",
                dialogControl = "FluxBindingBrowserEmbed",
                width = "full",
                order = 1,
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
        FluxOptions:RegisterModuleOptions("binding", BuildBindingOptions)
    end
end)

