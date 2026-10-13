-- FluxBaganator_GearSetContext.lua
-- Darken protected gear-set bag items at vendors (same as unsellable items).

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local ItemButtonUtil = _G.ItemButtonUtil

local function GetGearSetLock()
    local R = _G.FluxRespec
    return R and R.GearSetLock
end

local function ResolveBagSlot(button)
    if Compat.ResolveBaganatorItemButtonSlot then
        return Compat.ResolveBaganatorItemButtonSlot(button)
    end
end

local function GetActiveBaganatorConfig()
    local config = _G.BAGANATOR_CONFIG
    if type(config) ~= "table" then
        return nil
    end
    if type(config.Profiles) == "table" then
        local profileName = _G.BAGANATOR_CURRENT_PROFILE or "DEFAULT"
        return config.Profiles[profileName] or config.Profiles.DEFAULT
    end
    return config
end

local function IsBaganatorContextFadingEnabled()
    local config = GetActiveBaganatorConfig()
    if not config then
        return true
    end
    return config.icon_context_fading ~= false
end

function Compat.ShouldFadeProtectedGearSetAtVendor(button)
    if not IsBaganatorContextFadingEnabled() then
        return false
    end
    local lock = GetGearSetLock()
    if not lock or not lock.IsMerchantSellContext or not lock.IsSlotProtected then
        return false
    end
    if not lock.IsMerchantSellContext() then
        return false
    end
    local bagID, slotID = ResolveBagSlot(button)
    if not bagID or not slotID then
        return false
    end
    return lock.IsSlotProtected(bagID, slotID) == true
end

local function GetContextMismatchResult()
    if ItemButtonUtil and ItemButtonUtil.ItemContextMatchResult then
        return ItemButtonUtil.ItemContextMatchResult.Mismatch
    end
    return 1
end

local function StabilizeProtectedVendorOverlay(button)
    if not button or not Compat.ShouldFadeProtectedGearSetAtVendor(button) then
        return
    end
    if button.BGR then
        button.BGR.contextMatch = false
    end
    if button.ItemContextOverlay then
        button.ItemContextOverlay:Show()
    end
end

function Compat.InstallBaganatorItemContextOverride(button)
    if not button or button._fluxContextOverrideInstalled or not button.GetItemContextMatchResult then
        return
    end
    button._fluxContextOverrideInstalled = true

    local origGetItemContextMatchResult = button.GetItemContextMatchResult
    button.GetItemContextMatchResult = function()
        if Compat.ShouldFadeProtectedGearSetAtVendor(button) then
            if button.BGR then
                button.BGR.contextMatch = false
            end
            return GetContextMismatchResult()
        end
        return origGetItemContextMatchResult()
    end

    if button.UpdateItemContextOverlay then
        hooksecurefunc(button, "UpdateItemContextOverlay", function()
            StabilizeProtectedVendorOverlay(button)
        end)
    end
end

function Compat.InitGearSetContext()
    if Compat._gearSetContextInitialized then
        return
    end
    Compat._gearSetContextInitialized = true

    if Compat.InitBaganatorViewTracking then
        Compat.InitBaganatorViewTracking()
    end
end
