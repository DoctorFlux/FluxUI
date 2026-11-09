-- Loader.lua
-- Central event orchestration for ConsolePort compatibility suppression.

local addonName, ns = ...

ns.ConsolePortCompat = ns.ConsolePortCompat or {}
local Compat = ns.ConsolePortCompat

local watchedAddons = {
    ConsolePort = true,
    ConsolePort_Bar = true,
    ConsolePort_Menu = true,
}

local function IsConsolePortLoaded()
    for name in pairs(watchedAddons) do
        if IsAddOnLoaded and IsAddOnLoaded(name) then
            return true
        end
    end
    return false
end

function Compat.ApplyAllSuppression()
    if Compat.ApplyStatusBarSuppression then
        Compat.ApplyStatusBarSuppression()
    end
    if Compat.ApplyMicroMenuSuppression then
        Compat.ApplyMicroMenuSuppression()
    end
end

function Compat.ApplyIfReady()
    if not IsConsolePortLoaded() then
        return
    end

    local ok = Compat.RunOrDefer("consoleport-compat-apply", function()
        Compat.ApplyAllSuppression()
    end)

    if not ok then
        Compat.pendingApply = true
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        Compat.ApplyIfReady()
        return
    end

    if event == "ADDON_LOADED" then
        if watchedAddons[arg1] then
            Compat.ApplyIfReady()
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if Compat.pendingApply or (Compat.HasDeferredWork and Compat.HasDeferredWork()) then
            Compat.pendingApply = false
            if Compat.FlushDeferred then
                Compat.FlushDeferred()
            end
            Compat.ApplyIfReady()
        end
    end
end)


