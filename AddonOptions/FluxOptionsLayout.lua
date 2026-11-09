local addonName, ns = ...

local function NotifyFluxUIConfig()
    local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if ACR then
        ACR:NotifyChange("FluxUI")
    end
end

local function BuildLayoutOptions()
    return {
    name = "Layout",
    type = "group",
    order = 2,
    args = {
        intro = {
            type = "description",
            name = "Click a colored box to move it. Faded tiles are other spots. Gray boxes are reference only.\n",
            order = 0,
            fontSize = "medium",
            width = "full",
        },
        layoutScopeHeader = {
            type = "header",
            name = "Scope",
            order = 4,
        },
        layoutSettingsScope = {
            type = "select",
            name = "Layout scope",
            desc = "Account-wide or per character. Layout tab only - not Micro Menu size or button order.",
            order = 5,
            width = "full",
            values = {
                account = "Account-wide",
                character = "Character-specific",
            },
            sorting = { "account", "character" },
            get = function()
                return FluxOptions:IsLayoutCharacterSpecific() and "character" or "account"
            end,
            set = function(_, val)
                FluxOptions:SetLayoutCharacterSpecific(val == "character")
                NotifyFluxUIConfig()
                if FluxLayoutPreviewUI and FluxLayoutPreviewUI.DrawPreview then
                    FluxLayoutPreviewUI:DrawPreview()
                end
            end,
        },
        resetLayout = {
            type = "execute",
            name = "Reset layout to defaults",
            desc = "Reset all layout positions on this tab for the current scope.",
            order = 6,
            width = "full",
            confirm = true,
            confirmText = "Reset layout to defaults?",
            func = function()
                if FluxOptions and FluxOptions.ResetLayoutToDefaults then
                    FluxOptions:ResetLayoutToDefaults()
                end
            end,
        },
        preview = {
            type = "description",
            name = " ",
            dialogControl = "FluxLayoutPreview",
            width = "full",
            order = 10,
        },
    },
}
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    if FluxOptions and FluxOptions.RegisterModuleOptions then
        FluxOptions:RegisterModuleOptions("layout", BuildLayoutOptions)
    end
end)

