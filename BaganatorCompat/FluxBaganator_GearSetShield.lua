-- FluxBaganator_GearSetShield.lua
-- Gear-set shield on Baganator item buttons (vendor / disenchant only).

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local SHIELD_TEXTURE = "Interface/AddOns/_FluxUI/Assets/equipment-set-shield"
local SHIELD_FALLBACK = "Interface/PaperDollInfoFrame/UI-GearManager-ItemLevel"
local SHIELD_SIZE = 15
local FLUX_SHIELD_ID = "flux_gear_set_shield"

local CORNER_ARRAY_KEYS = {
    "icon_top_left_corner_array",
    "icon_top_right_corner_array",
    "icon_bottom_left_corner_array",
    "icon_bottom_right_corner_array",
}

local function GetGearSetLock()
    local R = _G.FluxRespec
    return R and R.GearSetLock
end

local function IsVendorOrDisenchantContext(lock)
    if not lock then
        return false
    end
    if lock.IsDisenchantContext and lock.IsDisenchantContext() then
        return true
    end
    if lock.IsMerchantSellContext and lock.IsMerchantSellContext() then
        return true
    end
    return false
end

local function ResolveBagSlot(details)
    if not details then
        return
    end

    if details.bagID and details.slotID then
        return details.bagID, details.slotID
    end

    local location = details.itemLocation
    if location then
        if location.GetBagAndSlot then
            local ok, bagID, slotID = pcall(location.GetBagAndSlot, location)
            if ok and bagID and slotID then
                return bagID, slotID
            end
        end
        if location.bagID and location.slotIndex then
            return location.bagID, location.slotIndex
        end
    end
end

local function ShouldShowShield(details)
    local lock = GetGearSetLock()
    if not lock or not lock.ShouldShowShieldVisual then
        return false
    end
    if not IsVendorOrDisenchantContext(lock) then
        return false
    end
    local bagID, slotID = ResolveBagSlot(details)
    if not bagID or not slotID then
        return false
    end
    return lock.ShouldShowShieldVisual(bagID, slotID) == true
end

local function RefreshShieldOnButton(button)
    if not button or not button.cornerPlugins or not button.BGR then
        return
    end
    local widget = button.cornerPlugins[FLUX_SHIELD_ID]
    if not widget then
        return
    end
    widget:SetShown(ShouldShowShield(button.BGR) == true)
end

function Compat.RefreshShieldOnBaganatorButton(button)
    RefreshShieldOnButton(button)
end

function Compat.RefreshVisibleGearSetShields()
    if Compat.ForEachVisibleItemButton then
        Compat.ForEachVisibleItemButton(RefreshShieldOnButton)
        return
    end
    if Compat.ForEachBaganatorItemButton then
        Compat.ForEachBaganatorItemButton(RefreshShieldOnButton)
    end
end

function Compat.RequestGearSetShieldRefresh()
    if Compat.RequestBaganatorProtectionRefresh then
        Compat.RequestBaganatorProtectionRefresh()
        return
    end
    Compat.RefreshVisibleGearSetShields()
end

local function FilterCornerArray(corners)
    if type(corners) ~= "table" then
        return {}
    end
    local filtered = {}
    for i = 1, #corners do
        local id = corners[i]
        if id ~= "equipment_set" and id ~= "equipment_set_icon" then
            filtered[#filtered + 1] = id
        end
    end
    return filtered
end

local function ArrayContains(list, value)
    if type(list) ~= "table" then
        return false
    end
    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end
    return false
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

local function TriggerCornerPluginsUpdated()
    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if registry and registry.TriggerEvent then
        registry:TriggerEvent("PluginsUpdated")
    end
end

-- Baganator's built-in equipment_set corner is always-on whenever setInfo exists.
function Compat.ConfigureBaganatorGearSetCorners()
    local config = GetActiveBaganatorConfig()
    if type(config) ~= "table" then
        return false
    end

    for i = 1, #CORNER_ARRAY_KEYS do
        local key = CORNER_ARRAY_KEYS[i]
        local corners = FilterCornerArray(config[key])
        if key == "icon_bottom_left_corner_array" and not ArrayContains(corners, FLUX_SHIELD_ID) then
            table.insert(corners, 1, FLUX_SHIELD_ID)
        end
        config[key] = corners
    end

    config.icon_equipment_set_border = false
    return true
end

local function ApplyBaganatorGearSetCornerConfig()
    if not Compat.ConfigureBaganatorGearSetCorners() then
        return false
    end
    TriggerCornerPluginsUpdated()
    Compat.RequestBaganatorRefresh(true)
    return true
end

local function ScheduleApplyBaganatorGearSetCornerConfig()
    if ApplyBaganatorGearSetCornerConfig() then
        return
    end
    if Compat._cornerConfigRetryScheduled or not C_Timer or not C_Timer.After then
        return
    end
    Compat._cornerConfigRetryScheduled = true
    C_Timer.After(0, function()
        Compat._cornerConfigRetryScheduled = false
        ApplyBaganatorGearSetCornerConfig()
    end)
end

function Compat.InitGearSetShield()
    local api = _G.Baganator and _G.Baganator.API
    if not api or not api.RegisterCornerWidget or Compat._gearSetShieldInitialized then
        return
    end
    Compat._gearSetShieldInitialized = true

    api.RegisterCornerWidget("Flux Gear Set", FLUX_SHIELD_ID, function(_, details)
        return ShouldShowShield(details)
    end, function(itemButton)
        local shield = itemButton:CreateTexture(nil, "ARTWORK")
        shield:SetTexture(SHIELD_TEXTURE ~= "" and SHIELD_TEXTURE or SHIELD_FALLBACK)
        shield:SetSize(SHIELD_SIZE, SHIELD_SIZE)
        return shield
    end, { corner = "bottom_left", priority = 1 }, true)

    ScheduleApplyBaganatorGearSetCornerConfig()
    if Compat.InitBaganatorViewTracking then
        Compat.InitBaganatorViewTracking()
    end

    local boot = CreateFrame("Frame")
    boot:RegisterEvent("PLAYER_LOGIN")
    boot:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        ApplyBaganatorGearSetCornerConfig()
    end)
end

