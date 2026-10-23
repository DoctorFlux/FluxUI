-- Loader.lua
-- Initializes Baganator integration when Baganator is present.

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat
_G.FluxBaganatorCompat = Compat

local function IsBaganatorReady()
    return _G.Baganator and _G.Baganator.API ~= nil
end

-- Item APIs belong to Blizzard. Gear-set scans avoid irrelevant GUID queries
-- locally; changing C_Item would also change Baganator and other addons' reads.
local dependencyWaitFrame

function Compat.Init()
    if not IsBaganatorReady() then
        return
    end
    -- Bank restock must not wait on GearSetLock / other respec deps.
    if Compat.InitBankRestock then
        Compat.InitBankRestock()
    end
    if Compat._initialized then
        return
    end

    local function RunInit()
        if Compat._initialized then
            return
        end
        if Compat.InitProtection then
            Compat.InitProtection()
        end
        if Compat.InitJunk then
            Compat.InitJunk()
        end
        if Compat.InitCategoryIcons then
            Compat.InitCategoryIcons()
        end
        if Compat.InitGearSets then
            Compat.InitGearSets()
        end
        if Compat.InitEquipmentSetSection then
            Compat.InitEquipmentSetSection()
        end
        if Compat.InitConsumablesCategories then
            Compat.InitConsumablesCategories()
        end
        if Compat.InitCategoryVendorBlock then
            Compat.InitCategoryVendorBlock()
        end
        if Compat.InitGearSetContext then
            Compat.InitGearSetContext()
        end
        if Compat.InitGearSetShield then
            Compat.InitGearSetShield()
        end
        if Compat.FinalizeBaganatorIntegration then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.25, Compat.FinalizeBaganatorIntegration)
            else
                Compat.FinalizeBaganatorIntegration()
            end
        end
        -- A thrown initializer must leave the bridge eligible for a later retry.
        Compat._initialized = true
        if dependencyWaitFrame then
            dependencyWaitFrame:UnregisterAllEvents()
            dependencyWaitFrame = nil
        end
    end

    local function DependenciesReady()
        local R = _G.FluxRespec
        local Flux = _G.Flux
        return R and R.GearSetLock and R.GearSetIndex and R.Inv
            and Flux and Flux.Inventory
    end

    if DependenciesReady() or (IsLoggedIn and IsLoggedIn()) then
        RunInit()
        return
    end

    if dependencyWaitFrame then
        return
    end
    local boot = CreateFrame("Frame")
    dependencyWaitFrame = boot
    boot:RegisterEvent("PLAYER_LOGIN")
    boot:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        dependencyWaitFrame = nil
        if Compat.InitBankRestock then
            Compat.InitBankRestock()
        end
        RunInit()
    end)
end

local function TryInit()
    if IsBaganatorReady() then
        Compat.Init()
        return true
    end
    return false
end

if _G.Flux and Flux.Module then
    Flux.Module.Register("BaganatorIntegration", {
        phase = "deferred", requiredAddons = { "Baganator" },
        OnEnable = function()
            if not TryInit() then return false end
            if Compat._initialized and Flux.Startup then Flux.Startup.Mark("optional.Baganator.ready_observed") end
            return Compat._initialized == true
        end,
    })
    return
end

TryInit()

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= "Baganator" and addonName ~= "_FluxUI" then
        return
    end
    TryInit()
end)


