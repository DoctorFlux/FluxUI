--[[
    Restock/Vendor/BuyEmAll/FluxBuyEmAll_Compat.lua
    Cross-client bag-space calculation for bulk vendor purchases.
]]

FluxBuyEmAllCompat = FluxBuyEmAllCompat or {}
local Compat = FluxBuyEmAllCompat

local function Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end
local strfind = string.find
local BACKPACK = _G.BACKPACK_CONTAINER or 0

local function GetItemStackSize(itemID)
    if GetItemInfoInstant then
        local _, _, _, _, _, _, _, stackCount = GetItemInfoInstant(itemID)
        if stackCount and stackCount > 0 then
            return stackCount
        end
    end
    if GetItemInfo then
        local stackCount = select(8, GetItemInfo(itemID))
        if stackCount and stackCount > 0 then
            return stackCount
        end
    end
    return 20
end

local function GetBagInventorySlot(bag)
    if C_Container and C_Container.ContainerIDToInventoryID then
        local ok, invID = pcall(C_Container.ContainerIDToInventoryID, bag)
        if ok and invID then
            return invID
        end
    end
    if bag > 0 and bag <= 4 then
        return 19 + bag
    end
    return nil
end

local function BagAcceptsItemFamily(bag, itemSubType)
    if bag == BACKPACK or bag == 0 then
        return true
    end

    local invSlot = GetBagInventorySlot(bag)
    if not invSlot then
        return false
    end

    local bagLink = GetInventoryItemLink("player", invSlot)
    if not bagLink then
        return false
    end

    local bagSubType = GetItemFamily(bagLink)
    if bagSubType == itemSubType then
        return true
    elseif bagSubType == 0 then
        return true
    elseif bit.band(itemSubType, bagSubType) == bagSubType then
        return true
    end
    return false
end

function Compat.GetPurchasableBagSpace(itemID)
    itemID = tonumber(itemID)
    local inv = Inv()
    if not itemID or not inv or not inv.GetBagContainerIDs then
        return 0, 20
    end

    local freeSpace = 0
    local itemSubType = GetItemFamily(itemID)
    local stackSize = GetItemStackSize(itemID)

    for _, theBag in ipairs(inv.GetBagContainerIDs()) do
        if BagAcceptsItemFamily(theBag, itemSubType) then
            local numSlot = inv.GetContainerNumSlots(theBag)
            for theSlot = 1, numSlot do
                local itemLink = inv.GetContainerItemLink(theBag, theSlot)
                if not itemLink then
                    freeSpace = freeSpace + stackSize
                else
                    local info = inv.GetContainerItemInfo(theBag, theSlot)
                    if info and info.itemID == itemID then
                        freeSpace = freeSpace + stackSize - info.count
                    elseif strfind(itemLink, "item:" .. itemID .. ":", 1, true) then
                        local count = info and info.count or 0
                        freeSpace = freeSpace + stackSize - count
                    end
                end
            end
        end
    end

    return freeSpace, stackSize
end
