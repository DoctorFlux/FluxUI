--[[
    Restock/Bank/FluxBankRestockMoves.lua

    Low-level bank → bag move primitives for FluxBankRestockExecutor.
    Cursor placement lives in FluxItemMover (via Executor).
]]

FluxBankRestockMoves = FluxBankRestockMoves or {}
local Moves = FluxBankRestockMoves
local Inventory = FluxBankRestockInventory

local function Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

local function CursorHasItem()
    if GetCursorInfo then
        local t = GetCursorInfo()
        return t == "item"
    end
    return false
end

local function ClearCursorSafe()
    if ClearCursor then
        pcall(ClearCursor)
    end
end

local function UseWholeStack(bag, slot)
    if C_Container and C_Container.UseContainerItem then
        C_Container.UseContainerItem(bag, slot, nil, nil, true)
        return true
    end
    if UseContainerItem then
        UseContainerItem(bag, slot)
        return true
    end
    return false
end

--- Issue UseContainerItem and verify how many items left the bank slot.
--- Returns movedCount, verifyReason (nil on success, else locked/async/cursor).
function Moves.UseWholeStackWithVerify(bag, slot)
    local inv = Inv()
    if not inv then
        return 0, "no_ctx"
    end
    if CursorHasItem() then
        return 0, "cursor"
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    if not info or (info.count or 0) <= 0 then
        return 0, "no_stack"
    end
    if info.locked then
        return 0, "locked"
    end
    local beforeCount = info.count or 0
    local itemID = info.itemID
    UseWholeStack(bag, slot)
    if CursorHasItem() then
        return 0, "split_pending"
    end
    local afterInfo = inv.GetContainerItemInfo(bag, slot)
    if not afterInfo or not afterInfo.itemID then
        return beforeCount, nil
    end
    if afterInfo.locked then
        return 0, "async"
    end
    if afterInfo.itemID == itemID and (afterInfo.count or 0) < beforeCount then
        return beforeCount - (afterInfo.count or 0), nil
    end
    return 0, "async"
end

function Moves.ExecuteSlotMove(fromBag, fromSlot, toBag, toSlot, amount)
    local inv = Inv()
    fromBag = tonumber(fromBag)
    fromSlot = tonumber(fromSlot)
    toBag = tonumber(toBag)
    toSlot = tonumber(toSlot)
    amount = math.floor(tonumber(amount) or 0)
    if not inv or not fromBag or not fromSlot or not toBag or not toSlot or amount <= 0 then
        return false, "bad_args"
    end
    if CursorHasItem() then
        return false, "cursor"
    end
    local info = inv.GetContainerItemInfo(fromBag, fromSlot)
    if not info or info.locked or (info.count or 0) <= 0 then
        return false, "no_stack"
    end
    local count = info.count or 0
    local moveAmt = math.min(amount, count)
    if moveAmt <= 0 then
        return false, "zero_amount"
    end

    local splitFn = inv.SplitContainerItem
        or (C_Container and C_Container.SplitContainerItem)
        or _G.SplitContainerItem
    local pickupFn = inv.PickupContainerItem
        or (C_Container and C_Container.PickupContainerItem)
        or _G.PickupContainerItem

    local needsSplit = moveAmt < count
    if needsSplit and splitFn then
        local splitOk = true
        if inv.SplitContainerItem then
            splitOk = inv.SplitContainerItem(fromBag, fromSlot, moveAmt) == true
        else
            pcall(splitFn, fromBag, fromSlot, moveAmt)
            splitOk = CursorHasItem()
        end
        if not splitOk and not CursorHasItem() then
            if inv.SplitContainerItemPending
                and inv.SplitContainerItemPending(fromBag, fromSlot, count, moveAmt) then
                return false, "async"
            end
            return false, "split_failed"
        end
    elseif pickupFn then
        pcall(pickupFn, fromBag, fromSlot)
        moveAmt = count
    elseif splitFn then
        pcall(splitFn, fromBag, fromSlot, moveAmt)
    end

    if not CursorHasItem() then
        if needsSplit and inv.SplitContainerItemPending
            and inv.SplitContainerItemPending(fromBag, fromSlot, count, moveAmt) then
            return false, "async"
        end
        if needsSplit then
            return false, "split_failed"
        end
        return false, "no_cursor"
    end

    if pickupFn then
        pcall(pickupFn, toBag, toSlot)
    end

    if CursorHasItem() then
        return false, "async"
    end
    ClearCursorSafe()
    return true
end

--- Full-stack pickup from source and place into a specific target slot (no split).
function Moves.ExecuteWholeStackToSlot(fromBag, fromSlot, toBag, toSlot)
    local inv = Inv()
    fromBag = tonumber(fromBag)
    fromSlot = tonumber(fromSlot)
    toBag = tonumber(toBag)
    toSlot = tonumber(toSlot)
    if not inv or not fromBag or not fromSlot or not toBag or not toSlot then
        return false, "bad_args"
    end
    if CursorHasItem() then
        return false, "cursor"
    end
    local info = inv.GetContainerItemInfo(fromBag, fromSlot)
    if not info or info.locked or (info.count or 0) <= 0 then
        return false, "no_stack"
    end
    local count = info.count or 0
    local pickupFn = inv.PickupContainerItem
        or (C_Container and C_Container.PickupContainerItem)
        or _G.PickupContainerItem
    if not pickupFn then
        return false, "no_pickup"
    end
    pcall(pickupFn, fromBag, fromSlot)
    if not CursorHasItem() then
        return false, "no_cursor"
    end
    pcall(pickupFn, toBag, toSlot)
    ClearCursorSafe()
    return true, count
end

function Moves.GetSlotCount(bag, slot)
    local inv = Inv()
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not inv or not bag or not slot then
        return 0
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    if not info then
        return 0
    end
    return tonumber(info.count) or 0
end

function Moves.CursorHasItem()
    return CursorHasItem()
end

function Moves.CanContinueBurst()
    return not CursorHasItem()
end

function Moves.ClearCursor()
    ClearCursorSafe()
end

function Moves.IssueSplit(bag, slot, amount)
    local inv = Inv()
    if inv and inv.SplitContainerItem then
        return inv.SplitContainerItem(bag, slot, amount)
    end
    local splitFn = (C_Container and C_Container.SplitContainerItem) or _G.SplitContainerItem
    if splitFn then
        pcall(splitFn, bag, slot, amount)
        return true
    end
    return false
end

--- Scan bank containers for stacks matching predicate. Returns nil if any
--- locked slot seen (try again next tick).
function Moves.ScanBankFor(bankBagIDs, predicate)
    local inv = Inv()
    if not inv or not bankBagIDs or type(predicate) ~= "function" then
        return {}
    end
    local out = {}
    for _, bag in ipairs(bankBagIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = inv.GetContainerItemInfo(bag, slot)
            if info then
                if info.locked then
                    return nil
                end
                if (info.count or 0) > 0 and info.itemID and predicate(info) then
                    out[#out + 1] = {
                        bag = bag,
                        slot = slot,
                        count = info.count or 0,
                        itemID = info.itemID,
                        locked = info.locked,
                    }
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.count ~= b.count then
            return a.count < b.count
        end
        return (a.slot or 0) < (b.slot or 0)
    end)
    return out
end

--- Pre-flight: need at least one free bag slot to split safely.
function Moves.CheckBagSpace(bagIDs)
    if Inventory.HasEmptyBagSlot(bagIDs) then
        return "ok"
    end
    return "bag"
end

_G.FluxBankRestockMoves = Moves
return Moves
