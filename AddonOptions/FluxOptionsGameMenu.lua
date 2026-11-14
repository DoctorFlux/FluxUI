-- One settings entry per native menu rebuild. Never register an Escape handler
-- or replace native scripts/globals: the shell owns only its override binding.
local _, ns = ...
local installed
local function OpenOptions()
    if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION) end
    if HideUIPanel then HideUIPanel(GameMenuFrame) end
    if FluxOptions and FluxOptions.ShowConfig then FluxOptions:ShowConfig() end
end

local function AddSettings(menu)
    -- The actual menu's AddButton also owns Forever's gamepad navigation array.
    local button = menu:AddButton("FluxUI Settings", OpenOptions)
    if not button then return end
    local gamepad = InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled()
    if not gamepad then
        for _, child in ipairs({ menu:GetChildren() }) do
            if child ~= button and child.layoutIndex and child.GetText
                and child:GetText() == GAMEMENU_OPTIONS then
                button.layoutIndex = child.layoutIndex + 0.01
                button.topPadding = nil
                break
            end
        end
    end
    -- Keep visual and navigation-array order identical in gamepad mode. Clear
    -- the previous last-button wrap before the native owner installs the new one.
    if gamepad and menu.ResetGamepadButtons then menu:ResetGamepadButtons() end
    if gamepad and menu.SetupGamepadButtons then menu:SetupGamepadButtons() end
    menu:MarkDirty()
end

local boot = CreateFrame("Frame")
local function Install()
    if installed or not (GameMenuFrame and GameMenuFrame.InitButtons and GameMenuFrame.AddButton and hooksecurefunc) then return end
    installed = true
    boot:UnregisterAllEvents()
    hooksecurefunc(GameMenuFrame, "InitButtons", AddSettings)
end
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", Install)
Install()
