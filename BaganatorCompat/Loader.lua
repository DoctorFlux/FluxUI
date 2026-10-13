-- Loader.lua
-- Initializes Baganator integration when Baganator is present.

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat
_G.FluxBaganatorCompat = Compat

local function IsBaganatorReady()
    return _G.Baganator and _G.Baganator.API ~= nil
end

-- Baganator asks DoesItemExist and GetItemGUID for every occupied slot of a
-- view on every move. Remember the answer per slot until that bag changes, so
-- a move re-reads the bags that changed and reuses the rest.
local identityCacheInstalled = false

local function InstallItemIdentityCache()
    if identityCacheInstalled or not (C_Item and C_Item.GetItemGUID and C_Item.DoesItemExist) then
        return
    end
    identityCacheInstalled = true
    local guidByBag, existByBag = {}, {}
    local origGUID = C_Item.GetItemGUID
    local origExist = C_Item.DoesItemExist

    local function SlotOf(loc)
        if type(loc) ~= "table" then
            return nil, nil
        end
        local bag, slot = tonumber(loc.bagID), tonumber(loc.slotIndex)
        if not bag or not slot then
            return nil, nil
        end
        return bag, slot
    end

    local function WipeBag(bag)
        bag = tonumber(bag)
        if not bag then
            return
        end
        guidByBag[bag] = nil
        existByBag[bag] = nil
    end

    local function EquippableClass(classID)
        if not classID then
            return false
        end
        local itemClass = Enum and Enum.ItemClass
        local armor = (itemClass and itemClass.Armor) or LE_ITEM_CLASS_ARMOR
        local weapon = (itemClass and itemClass.Weapon) or LE_ITEM_CLASS_WEAPON
        return classID == armor or classID == weapon
    end

    function C_Item.GetItemGUID(loc)
        local bag, slot = SlotOf(loc)
        if not bag then
            return origGUID(loc)
        end
        local bySlot = guidByBag[bag]
        if bySlot and bySlot[slot] ~= nil then
            local guid = bySlot[slot]
            return guid or nil
        end
        bySlot = bySlot or {}
        guidByBag[bag] = bySlot
        -- Only gear can belong to an equipment set. Trade goods and
        -- consumables skip the guid lookup entirely.
        local itemID = C_Container and C_Container.GetContainerItemID and C_Container.GetContainerItemID(bag, slot)
        if itemID and GetItemInfoInstant and not EquippableClass(select(6, GetItemInfoInstant(itemID))) then
            bySlot[slot] = false
            return nil
        end
        local guid = origGUID(loc)
        bySlot[slot] = guid or false
        return guid
    end

    function C_Item.DoesItemExist(loc)
        local bag, slot = SlotOf(loc)
        if not bag then
            return origExist(loc)
        end
        local bySlot = existByBag[bag]
        if bySlot and bySlot[slot] ~= nil then
            return bySlot[slot]
        end
        local exists = origExist(loc) and true or false
        bySlot = bySlot or {}
        existByBag[bag] = bySlot
        bySlot[slot] = exists
        return exists
    end

    local Flux = _G.Flux
    if Flux and Flux.Events and Flux.Events.Register then
        Flux.Events.Register("BAG_UPDATE", function(_, bag)
            WipeBag(bag)
        end)
        Flux.Events.Register("PLAYERBANKSLOTS_CHANGED", function()
            WipeBag(_G.BANK_CONTAINER or -1)
            local bank = Enum and Enum.BagIndex and Enum.BagIndex.Bank
            if bank then
                WipeBag(bank)
            end
        end)
    end
end

function Compat.Init()
    if not IsBaganatorReady() then
        return
    end
    InstallItemIdentityCache()
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
        Compat._initialized = true
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
    end

    local function DependenciesReady()
        local R = _G.FluxRespec
        local Flux = _G.Flux
        return R and R.GearSetLock and R.GearSetIndex and R.Inv
            and Flux and Flux.Inventory
    end

    if DependenciesReady() then
        RunInit()
        return
    end

    local boot = CreateFrame("Frame")
    boot:RegisterEvent("PLAYER_LOGIN")
    boot:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
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


