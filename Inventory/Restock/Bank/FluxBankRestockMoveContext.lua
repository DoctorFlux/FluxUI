--[[
    Restock/Bank/FluxBankRestockMoveContext.lua

    Thin WoW container wrappers for bank→bag moves (Restocker-style).

    Partials: SplitContainerItem(bank) + same-tick PickupContainerItem(bag dest).
    Wholes: UseContainerItem. Never withdraw-whole + return-excess.
]]

FluxBankRestockMoveContext = FluxBankRestockMoveContext or {}
local Ctx = FluxBankRestockMoveContext

local function Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

local function Bank()
    local inv = Inv()
    return inv and inv.Bank
end

local function Mover()
    return _G.FluxItemMover
end

local function Dbg(cat, fmt, ...)
    local d = _G.FluxBankRestockDebug
    if d and d.Print then
        d.Print(cat, fmt, ...)
    end
end

local function DbgImportant(cat, fmt, ...)
    local d = _G.FluxBankRestockDebug
    if d and d.PrintImportant then
        d.PrintImportant(cat, fmt, ...)
    else
        Dbg(cat, fmt, ...)
    end
end

function Ctx.GetSlotQuantity(bag, slot)
    local inv = Inv()
    if not inv then
        return 0
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    if not info then
        return 0
    end
    return tonumber(info.count) or 0
end

function Ctx.IsSlotLocked(bag, slot)
    local inv = Inv()
    if not inv then
        return true
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    return info and info.locked == true
end

function Ctx.CursorHasItem()
    if CursorHasItem and CursorHasItem() then
        return true
    end
    if GetCursorInfo then
        return GetCursorInfo() == "item"
    end
    return false
end

function Ctx.GetCursorCount()
    local mover = Mover()
    if mover and mover.GetCursorItemCount then
        return mover.GetCursorItemCount()
    end
    return Ctx.CursorHasItem() and 1 or 0
end

function Ctx.SourceAcked(bag, slot, endQty)
    endQty = tonumber(endQty) or 0
    return Ctx.GetSlotQuantity(bag, slot) <= endQty
end

function Ctx.SplitSucceededBySource(bag, slot, sourceBefore, qty)
    sourceBefore = tonumber(sourceBefore) or 0
    qty = math.floor(tonumber(qty) or 0)
    if sourceBefore <= 0 or qty <= 0 then
        return false
    end
    return Ctx.SourceAcked(bag, slot, sourceBefore - qty)
end

function Ctx.SplitLooksUnchanged(bag, slot, sourceBefore)
    sourceBefore = tonumber(sourceBefore) or 0
    local left = Ctx.GetSlotQuantity(bag, slot)
    return left >= sourceBefore and sourceBefore > 0
end

function Ctx.ClearCursor()
    local mover = Mover()
    if mover and mover.ClearCursor then
        mover.ClearCursor()
        return
    end
    if ClearCursor then
        pcall(ClearCursor)
    end
end

function Ctx.ReturnToSource(bag, slot)
    if not Ctx.CursorHasItem() then
        return true
    end
    local inv = Inv()
    bag, slot = tonumber(bag), tonumber(slot)
    if inv and bag and slot then
        inv.PickupContainerItem(bag, slot)
        if not Ctx.CursorHasItem() then
            Dbg("exec", "cursor returned to %s:%s", bag, slot)
            return true
        end
    end
    Ctx.ClearCursor()
    DbgImportant("exec", "cursor cleared after return failed")
    return not Ctx.CursorHasItem()
end

Ctx.ReturnOrClearCursor = Ctx.ReturnToSource

function Ctx.UseWhole(bag, slot)
    local inv = Inv()
    if not inv then
        return false
    end
    bag, slot = tonumber(bag), tonumber(slot)
    if not bag or not slot then
        return false
    end
    DbgImportant("exec", "UseContainerItem bank=%s:%s", bag, slot)
    inv.UseContainerItem(bag, slot)
    return true
end

--- Bank split via FluxInv (guards + pending detection).
function Ctx.Split(bag, slot, qty)
    local inv = Inv()
    if not inv then
        return false
    end
    bag, slot = tonumber(bag), tonumber(slot)
    qty = math.floor(tonumber(qty) or 0)
    if not bag or not slot or qty <= 0 then
        return false
    end
    if Ctx.CursorHasItem() then
        return false
    end
    DbgImportant("split", "issue bank=%s:%s amt=%s", bag, slot, qty)
    return inv.SplitContainerItem(bag, slot, qty) == true
end

--- Player-bag split (legacy helper; bank restock does not return excess).
function Ctx.SplitBag(bag, slot, qty)
    bag, slot = tonumber(bag), tonumber(slot)
    qty = math.floor(tonumber(qty) or 0)
    if not bag or not slot or qty <= 0 then
        return false
    end
    if Ctx.CursorHasItem() then
        return false
    end
    local info = Inv() and Inv().GetContainerItemInfo(bag, slot)
    if not info or info.locked or (info.count or 0) <= qty then
        return false
    end
    local splitFn = (C_Container and C_Container.SplitContainerItem) or _G.SplitContainerItem
    if not splitFn then
        return false
    end
    DbgImportant("split", "issue bag=%s:%s amt=%s (player)", bag, slot, qty)
    pcall(splitFn, bag, slot, qty)
    return Ctx.CursorHasItem()
end

--- Pickup onto dest only — no ClearCursor.
function Ctx.Place(toBag, toSlot)
    local inv = Inv()
    if not inv then
        return false
    end
    toBag, toSlot = tonumber(toBag), tonumber(toSlot)
    if not toBag or not toSlot then
        return false
    end
    if not Ctx.CursorHasItem() then
        return false
    end
    DbgImportant("exec", "place dest=%s:%s", toBag, toSlot)
    inv.PickupContainerItem(toBag, toSlot)
    return not Ctx.CursorHasItem()
end

function Ctx.PickupWhole(fromBag, fromSlot)
    local inv = Inv()
    if not inv then
        return false
    end
    fromBag, fromSlot = tonumber(fromBag), tonumber(fromSlot)
    if not fromBag or not fromSlot or Ctx.CursorHasItem() then
        return false
    end
    DbgImportant("exec", "PickupContainerItem bank=%s:%s (whole)", fromBag, fromSlot)
    inv.PickupContainerItem(fromBag, fromSlot)
    return Ctx.CursorHasItem()
end

function Ctx.SplitPending(bag, slot, sourceBefore, qty)
    local inv = Inv()
    if not inv or not inv.SplitContainerItemPending then
        return false
    end
    return inv.SplitContainerItemPending(bag, slot, sourceBefore, qty) == true
end

--- Prefer exact unlocked bag stack (== amount → whole pickup), else smallest stack > amount.
function Ctx.FindBagSplitSource(itemID, amount)
    itemID = tonumber(itemID)
    amount = math.floor(tonumber(amount) or 0)
    local inv = Inv()
    if not inv or not itemID or amount <= 0 then
        return nil
    end
    local stacks = inv.FindBagStacks and inv.FindBagStacks(itemID) or {}
    local exact
    local best
    for _, st in ipairs(stacks) do
        local count = tonumber(st.count) or 0
        if count > 0 and not st.locked and not Ctx.IsSlotLocked(st.bag, st.slot) then
            if count == amount then
                if not exact or count < (exact.count or 0) then
                    exact = st
                end
            elseif count > amount then
                if not best or count < (best.count or 0) then
                    best = st
                end
            end
        end
    end
    if exact then
        return exact, true
    end
    return best, false
end

function Ctx.BagStacksLocked(itemID)
    itemID = tonumber(itemID)
    local inv = Inv()
    if not inv or not itemID then
        return false
    end
    local stacks = inv.FindBagStacks and inv.FindBagStacks(itemID) or {}
    for _, st in ipairs(stacks) do
        if st.locked or Ctx.IsSlotLocked(st.bag, st.slot) then
            return true
        end
    end
    return false
end

--- First empty bank slot (legacy helper).
function Ctx.FindEmptyBankSlot(preferBag)
    local inv = Inv()
    local bank = Bank()
    if not inv or not bank or not bank.GetContainerIDs then
        return nil, nil
    end
    preferBag = tonumber(preferBag)
    local ids = bank.GetContainerIDs()
    if preferBag then
        local num = inv.GetContainerNumSlots(preferBag) or 0
        for slot = 1, num do
            local info = inv.GetContainerItemInfo(preferBag, slot)
            if not info or not info.itemID or (info.count or 0) <= 0 then
                return preferBag, slot
            end
        end
    end
    for _, bag in ipairs(ids) do
        local num = inv.GetContainerNumSlots(bag) or 0
        for slot = 1, num do
            local info = inv.GetContainerItemInfo(bag, slot)
            if not info or not info.itemID or (info.count or 0) <= 0 then
                return bag, slot
            end
        end
    end
    return nil, nil
end

--- Restocker-faithful same-tick bank split + place onto bag dest.
--- Do NOT trust GetCursorItemCount (often reports source stack size).
function Ctx.TryBankSplitPlace(fromBag, fromSlot, toBag, toSlot, qty)
    qty = math.floor(tonumber(qty) or 0)
    fromBag, fromSlot = tonumber(fromBag), tonumber(fromSlot)
    toBag, toSlot = tonumber(toBag), tonumber(toSlot)
    if qty <= 0 or not fromBag or not fromSlot or not toBag or not toSlot then
        return false, "bad"
    end
    if Ctx.CursorHasItem() then
        return false, "cursor_busy"
    end
    if Ctx.IsSlotLocked(fromBag, fromSlot) then
        return false, "locked"
    end

    local before = Ctx.GetSlotQuantity(fromBag, fromSlot)
    if before <= 0 then
        return false, "slot_gone"
    end
    if qty >= before then
        if not Ctx.PickupWhole(fromBag, fromSlot) then
            return false, "no_cursor"
        end
        Ctx.Place(toBag, toSlot)
        if Ctx.CursorHasItem() then
            Ctx.ReturnToSource(fromBag, fromSlot)
            return false, "place_failed"
        end
        return true, nil
    end

    local inv = Inv()
    local expectedEnd = before - qty
    DbgImportant("split", "SplitContainerItem bank=%s:%s amt=%s", fromBag, fromSlot, qty)

    local splitOk = false
    if inv and inv.SplitContainerItem then
        splitOk = inv.SplitContainerItem(fromBag, fromSlot, qty) == true
    else
        local splitFn = (C_Container and C_Container.SplitContainerItem) or _G.SplitContainerItem
        if not splitFn then
            return false, "no_api"
        end
        pcall(splitFn, fromBag, fromSlot, qty)
        splitOk = Ctx.CursorHasItem() or Ctx.SplitPending(fromBag, fromSlot, before, qty)
    end

    if Ctx.CursorHasItem() then
        DbgImportant("split", "cursor held — place bag=%s:%s", toBag, toSlot)
        Ctx.Place(toBag, toSlot)
        if Ctx.CursorHasItem() then
            Ctx.ReturnToSource(fromBag, fromSlot)
            return false, "place_failed"
        end
        local left = Ctx.GetSlotQuantity(fromBag, fromSlot)
        if left <= expectedEnd or Ctx.IsSlotLocked(fromBag, fromSlot) then
            return true, nil
        end
        return false, "split_pending"
    end

    if Ctx.SplitPending(fromBag, fromSlot, before, qty) then
        return false, "split_pending"
    end

    if not splitOk then
        return false, "split_failed"
    end

    return false, "split_pending"
end

_G.FluxBankRestockMoveContext = Ctx
return Ctx
