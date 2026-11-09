-- FluxSalvage_Tooltip.lua
-- Tooltip hooks for bag-item salvage detection (ported from Molinari utils.lua)

FluxSalvage = FluxSalvage or {}
local S = FluxSalvage

local function TooltipPassesScope(tooltip)
    if not S.IsEnabled() then
        return false
    end
    if not (tooltip and not tooltip:IsForbidden() and tooltip:GetOwner()) then
        return false
    end
    return tooltip == GameTooltip
end

function S.ResolveBagSlotFromOwner(owner)
    if not owner then
        return
    end

    local bagID, slotID
    if owner.GetSlotAndBagID then
        local ok, slot, bag = pcall(owner.GetSlotAndBagID, owner)
        if ok then
            slotID = slot
            bagID = bag
        end
    end
    if not slotID and owner.GetID then
        local ok, id = pcall(owner.GetID, owner)
        if ok then
            slotID = id
        end
    end
    if not bagID then
        if owner.GetBagID then
            local ok, id = pcall(owner.GetBagID, owner)
            if ok then
                bagID = id
            end
        end
        bagID = bagID or owner.bagID
    end
    if not bagID and owner.GetParent then
        local parent = owner:GetParent()
        if parent then
            if parent.GetBagID then
                local ok, id = pcall(parent.GetBagID, parent)
                if ok then
                    bagID = id
                end
            end
            if not bagID and parent.GetID then
                local ok, id = pcall(parent.GetID, parent)
                if ok then
                    bagID = id
                end
            end
        end
    end

    if (not bagID or not slotID) and owner.BGR and owner.BGR.itemLocation then
        local location = owner.BGR.itemLocation
        if location.bagID and location.slotIndex then
            bagID = location.bagID
            slotID = location.slotIndex
        end
    end

    bagID = tonumber(bagID)
    slotID = tonumber(slotID)
    if not bagID or not slotID then
        return
    end

    return bagID, slotID
end

function S.ResolveBagItem(bagID, slotID)
    bagID = tonumber(bagID)
    slotID = tonumber(slotID)
    if not bagID or not slotID or not Item then
        return nil
    end

    if ItemLocation and ItemLocation.CreateFromBagAndSlot then
        local okLoc, location = pcall(ItemLocation.CreateFromBagAndSlot, ItemLocation, bagID, slotID)
        if okLoc and location then
            local valid = true
            if location.IsValid then
                local okValid, isValid = pcall(location.IsValid, location)
                valid = okValid and isValid
            end
            if valid and Item.CreateFromItemLocation then
                local okItem, bagItem = pcall(Item.CreateFromItemLocation, Item, location)
                if okItem and bagItem then
                    return bagItem
                end
            end
        end
    end

    if Item.CreateFromBagAndSlot then
        local ok, bagItem = pcall(Item.CreateFromBagAndSlot, Item, bagID, slotID)
        if ok then
            return bagItem
        end
    end
end

function S.ResolveItemID(item, bagID, slotID)
    local itemID
    if item and item.GetItemID then
        local ok, id = pcall(item.GetItemID, item)
        if ok then
            itemID = tonumber(id)
        end
    end
    if itemID and itemID > 0 then
        return itemID
    end

    bagID = tonumber(bagID)
    slotID = tonumber(slotID)
    if bagID and slotID then
        local id = S.GetContainerItemID and S.GetContainerItemID(bagID, slotID)
        id = tonumber(id)
        if id and id > 0 then
            return id
        end
    end

    if item and item.GetItemLink then
        local ok, link = pcall(item.GetItemLink, item)
        if ok and type(link) == "string" then
            if C_Item and C_Item.GetItemInfoInstant then
                local okID, id = pcall(C_Item.GetItemInfoInstant, link)
                if okID then
                    id = tonumber(id)
                    if id and id > 0 then
                        return id
                    end
                end
            end
            local fromLink = tonumber(link:match("item:(%d+)"))
            if fromLink and fromLink > 0 then
                return fromLink
            end
        end
    end
end

function S.HandleBagButton(button)
    if not S.IsEnabled() or not button or InCombatLockdown() then
        return
    end
    if not S.ModifierActive() then
        return
    end
    local bagID, slotID = S.ResolveBagSlotFromOwner(button)
    if not bagID or not slotID or not S.IsCarriedBag(bagID) then
        return
    end
    local tooltip = GameTooltip
    if not tooltip or tooltip:IsForbidden() then
        return
    end
    local bagItem = S.ResolveBagItem(bagID, slotID)
    S.HandleTooltip(tooltip, bagItem, bagID, slotID, button)
end

local function TryOwnerBagSlot(tooltip)
    local owner = tooltip:GetOwner()
    if not owner then
        return
    end

    local bagID, slotIndex = S.ResolveBagSlotFromOwner(owner)
    if not bagID or not slotIndex or not S.IsCarriedBag(bagID) then
        return
    end

    local bagItem = S.ResolveBagItem(bagID, slotIndex)
    S.HandleTooltip(tooltip, bagItem, bagID, slotIndex, owner)
    return true
end

local function OnItemTooltip(tooltip, data)
    if not TooltipPassesScope(tooltip) then
        return
    end

    if data and data.guid and C_Item and C_Item.GetItemLocation then
        local ok, location = pcall(C_Item.GetItemLocation, data.guid)
        if ok and location and location.IsBagAndSlot and location:IsBagAndSlot() then
            local bagID, slotID = location:GetBagAndSlot()
            if S.IsCarriedBag(bagID) then
                local bagItem = Item and Item.CreateFromItemLocation and Item:CreateFromItemLocation(location)
                S.HandleTooltip(tooltip, bagItem, bagID, slotID)
                return
            end
        end
    end

    if TryOwnerBagSlot(tooltip) then
        return
    end

    local owner = tooltip:GetOwner()
    if owner and owner.GetName and owner:GetName() == "TradeRecipientItem7ItemButton" then
        local _, itemLink = tooltip:GetItem()
        if itemLink then
            S.HandleTooltip(tooltip, Item:CreateFromItemLink(itemLink))
        end
    end
end

local function OnSetBagItem(tooltip, bagID, slotID)
    if not TooltipPassesScope(tooltip) then
        return
    end

    bagID = tonumber(bagID)
    slotID = tonumber(slotID)
    if not bagID or not slotID or not S.IsCarriedBag(bagID) then
        return
    end

    local bagItem = S.ResolveBagItem(bagID, slotID)
    S.HandleTooltip(tooltip, bagItem, bagID, slotID, tooltip:GetOwner())
end

local function OnSetTradeTargetItem(tooltip)
    if not TooltipPassesScope(tooltip) then
        return
    end

    local _, itemLink = tooltip:GetItem()
    local owner = tooltip:GetOwner()
    if itemLink and owner and owner.GetName and owner:GetName() == "TradeRecipientItem7ItemButton" then
        S.HandleTooltip(tooltip, Item:CreateFromItemLink(itemLink))
    end
end

local function OnBagButtonEnter(arg1, arg2)
    local button = arg1
    if type(button) ~= "table" or not (button.GetBagID or button.GetSlotAndBagID or button.bagID) then
        button = arg2
    end
    if type(button) == "table" then
        S.HandleBagButton(button)
    end
end

function S.HookBagButtons()
    if S._bagHooksInstalled then
        return
    end

    local hooked = false
    local mixin = _G.ContainerFrameItemButtonMixin
    if mixin and mixin.OnEnter then
        hooksecurefunc(mixin, "OnEnter", OnBagButtonEnter)
        hooked = true
    end
    if _G.ContainerFrameItemButton_OnEnter then
        hooksecurefunc("ContainerFrameItemButton_OnEnter", OnBagButtonEnter)
        hooked = true
    end
    if EventRegistry and EventRegistry.RegisterCallback then
        local ok = pcall(function()
            EventRegistry:RegisterCallback("ContainerFrameItemButton.EnterButton", OnBagButtonEnter)
        end)
        hooked = hooked or ok
    end
    if hooked then
        S._bagHooksInstalled = true
    end
end

function S.HookTooltip()
    if S._tooltipHooksInstalled then
        return
    end
    S._tooltipHooksInstalled = true

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
    end

    if GameTooltip and GameTooltip.SetBagItem then
        hooksecurefunc(GameTooltip, "SetBagItem", OnSetBagItem)
    end

    if GameTooltip and GameTooltip.SetTradeTargetItem then
        hooksecurefunc(GameTooltip, "SetTradeTargetItem", OnSetTradeTargetItem)
    end

    S.HookBagButtons()
end
