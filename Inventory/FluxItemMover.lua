--[[
    Inventory/FluxItemMover.lua

    The ONLY code that moves items between containers (bank <-> bags).

    Rewritten architecture (bank restock engine rewrite):
      * A single in-flight "action" at a time (withdraw / merge / charge).
        Each action is a small state machine (start -> resolve -> done) that
        owns every WoW API call and every tick of polling for it.
      * A single GLOBAL pacing gate sits between actions — not per-slot.
        Every bank action, regardless of which bag/slot/item it targets,
        waits out the same ping-adaptive interval before the next one may
        even be *submitted*. A confirmed split rejection (hard fail) grows
        that interval (backoff); a clean success resets it to the base.
        This replaces the old per-slot cooldown map, which let a rejection
        on one slot be followed almost immediately by an attempt on a
        different slot — the most likely cause of cascading
        "Couldn't split those items" rejections across multiple slots.

    Callers (Restock/Bank/FluxBankRestockExecutor.lua) submit ONE action via
    Mover.SubmitAction(spec) and receive a clean result via spec.onComplete
    once it resolves (success or definitive failure). They never see cursor
    ticks, split-pending polling, or cooldown bookkeeping.
]]

FluxItemMover = FluxItemMover or {}
local Mover = FluxItemMover

local Inv -- FluxInv (resolved lazily; same load group)
local C_Container = _G.C_Container

local function GetInv()
    if _G.FluxRestock and _G.FluxRestock.Inv then
        Inv = _G.FluxRestock.Inv
        return Inv
    end
    Inv = Inv or _G.FluxInv
    return Inv
end

local function Dbg(cat, fmt, ...)
    local d = _G.FluxBankRestockDebug
    if d and d.Print then
        d.Print(cat, fmt, ...)
    end
end

local BACKPACK = _G.BACKPACK_CONTAINER or 0
local NUM_BAGS = _G.NUM_BAG_SLOTS or 4

-- Bank action engine locals are defined in the lower "ACTION ENGINE" section but
-- referenced by move helpers above that section — forward-declare them here.
local action
local bagSlotCount, bagTotalForItem, liveMergeRoom, tryReturnCursorToSlot, tryPartialMergeIntoSlot, isSlotLocked
local FinishAction, PollAction, ProcessAction, stampCursorAmount
local lockContainers
local bankUnlockDepth = 0

-- ---------------------------------------------------------------------------
-- CURSOR / LOCK HELPERS
-- ---------------------------------------------------------------------------

local function CursorHasItem()
    if _G.CursorHasItem then
        return _G.CursorHasItem()
    end
    local cursorType = GetCursorInfo and GetCursorInfo()
    return cursorType == "item"
end
Mover.CursorHasItem = CursorHasItem

function Mover.GetCursorItemCount()
    if C_Cursor and C_Cursor.GetCursorItem and C_Item and C_Item.GetStackCount then
        local ok, itemLoc = pcall(C_Cursor.GetCursorItem)
        if ok and itemLoc then
            local valid = true
            if itemLoc.IsValid then
                valid = itemLoc:IsValid()
            end
            if valid then
                local okCount, count = pcall(C_Item.GetStackCount, itemLoc)
                count = okCount and tonumber(count) or 0
                if count > 0 then
                    return count
                end
            end
        end
    end
    if GetCursorInfo then
        local cursorType = GetCursorInfo()
        if cursorType == "item" then
            return 1
        end
    end
    return CursorHasItem() and 1 or 0
end

function Mover.GetCursorItemID()
    if not GetCursorInfo then
        return nil
    end
    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" then
        return tonumber(itemID)
    end
    return nil
end

function Mover.ClearCursor()
    if CursorHasItem() and ClearCursor then
        pcall(ClearCursor)
    end
end

function Mover.IsAnythingLocked(containerIDs)
    local inv = GetInv()
    if not inv or not containerIDs then
        return false
    end
    -- Always scan live slots; cached lock flags can miss unlock events during
    -- bank automation and block splits indefinitely.
    for _, bag in ipairs(containerIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = inv.GetContainerItemInfo(bag, slot)
            if info and info.locked then
                return true
            end
        end
    end
    return false
end

--- Kept for FluxInv.lua's ITEM_LOCK_CHANGED forwarding contract. The new
--- action engine always live-scans locks rather than trusting a cache, so
--- this only exists to avoid breaking that integration point.
function Mover.OnItemLockChanged(bagID, slotIndex)
    -- Intentionally minimal: no cached lock table to maintain any more.
end

function Mover.ResetLockTracking()
    -- Kept for API compatibility; nothing to reset in the new engine.
end

-- ---------------------------------------------------------------------------
-- PLACEMENT / MERGE QUERY HELPERS (pure reads — not the pacing-sensitive part)
-- ---------------------------------------------------------------------------

local function GetStackMaxForItem(itemID, fallback)
    fallback = tonumber(fallback) or 20
    itemID = tonumber(itemID)
    if not itemID then
        return fallback
    end
    local ic = _G.FluxItemClass
    if ic and ic.GetStackSize then
        local live = ic.GetStackSize(itemID)
        if live and live > 0 then
            return live
        end
    end
    return fallback
end

--- True when cursor/stack items can PHYSICALLY merge. This is deliberately
--- always an exact itemID match, regardless of `tierKind`: a shared tier
--- ("bandage", "manaPotion", ...) is a restocking accounting abstraction —
--- it groups multiple distinct items toward one target count — but the
--- game client can never combine two different itemIDs into one stack.
--- Treating a tier match as mergeable here used to make PickupContainerItem
--- silently SWAP two different items (cursor item in, slot item out onto
--- the cursor) instead of merging whenever a bag/bank held a mix of
--- different items for the same tier, since a swap can still increase the
--- slot's count and look like a successful merge to the caller.
function Mover.ItemsCanMerge(slotItemID, cursorItemID, tierKind)
    slotItemID = tonumber(slotItemID)
    cursorItemID = tonumber(cursorItemID)
    if not slotItemID or not cursorItemID then
        return false
    end
    return slotItemID == cursorItemID
end

--- True when `bag:slot` holds a stack that could physically be merged into.
--- Two modes:
---   * `itemID` known (the normal case — every real caller already knows
---     exactly what's on the cursor or about to be withdrawn): EXACT
---     itemID match only, via Mover.ItemsCanMerge.
---   * `itemID` nil, `tierKind` given: tier-WIDE discovery mode. Used only
---     to answer "does ANY item in this tier have a mergeable partial
---     stack in here, and if so which exact item is it" before a specific
---     bank stack has been picked — the returned `info` (and its exact
---     info.itemID) becomes the authoritative target from that point on.
---     Safe because nothing is actually moved yet in this mode; it's pure
---     discovery, not a merge decision.
local function SlotMatchesMerge(inv, bag, slot, itemID, tierKind)
    local info = inv.GetContainerItemInfo(bag, slot)
    if not info or info.locked or not info.itemID or (info.count or 0) <= 0 then
        return false, nil
    end
    local cursorItemID = tonumber(itemID)
    if cursorItemID then
        if Mover.ItemsCanMerge(info.itemID, cursorItemID, tierKind) then
            return true, info
        end
        return false, nil
    end
    -- Tier-wide discovery: any bag stack matching the restock kind.
    if tierKind then
        local T = _G.FluxRestockTiers
        if T and T.ItemMatchesRestockKind and T.ItemMatchesRestockKind(tierKind, info.itemID) then
            return true, info
        end
    end
    return false, nil
end

local function GetBagInventorySlot(bag)
    bag = tonumber(bag)
    if not bag or bag == BACKPACK then
        return nil
    end
    if C_Container and C_Container.ContainerIDToInventoryID then
        local ok, slot = pcall(C_Container.ContainerIDToInventoryID, bag)
        if ok and slot then
            return slot
        end
    end
    if bag >= 1 and bag <= NUM_BAGS and GetInventorySlotInfo then
        return GetInventorySlotInfo("BAG" .. bag .. "SLOT")
    end
    return nil
end

--- True when a merge bank pull can use overlay pickup (no bank split).
--- Safe only when the whole bank stack fits the need (count <= want).
local function canOverlayMergePull(count, want, mergeRoom)
    count = tonumber(count) or 0
    want = tonumber(want) or 0
    mergeRoom = tonumber(mergeRoom) or 0
    if want <= 0 or count <= 0 or mergeRoom <= 0 then
        return false
    end
    return count <= want
end

local function findMergeStagingSlot(inv, itemID, tierKind)
    if not inv then
        return nil, nil
    end
    local bagIDs = inv.GetBagContainerIDs and inv.GetBagContainerIDs()
    if not bagIDs then
        return nil, nil
    end
    return Mover.FindConsolidatedEmptySlot(bagIDs, itemID, tierKind)
end

local function stagingSlotCount(inv, bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not inv or not bag or not slot then
        return 0
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    return info and (info.count or 0) or 0
end

local function beginMergeStaging(a, stagingBag, stagingSlot)
    if not a then
        return
    end
    a.mergeStaging = true
    a.stagingBag = stagingBag
    a.stagingSlot = stagingSlot
    a.stagingPhase = "deposit"
    a.stagingCredited = 0
    a.splitIssued = false
    a.splitRejected = false
    a.bankUnlocked = false
    a.mergePullDone = false
    a.mergePullStarted = true
    a.mergeOverlay = false
    a.mustSplit = false
    a.microSplitFallback = false
    a.pullWaitTicks = 0
    a.stagingPullWait = 0
end

--- Score merge candidates: prefer exact tail room (room == want), then stacks
--- that can absorb the full pull, then largest per-step absorb, etc.
local function isBetterMergeTarget(count, room, take, stackMax, wantAmount, best)
    count = tonumber(count) or 0
    room = tonumber(room) or 0
    take = tonumber(take) or 0
    wantAmount = tonumber(wantAmount) or 0
    stackMax = tonumber(stackMax) or 20
    if room <= 0 or take <= 0 then
        return false
    end
    local remainder = stackMax - (count + take)
    local fitsFull = take >= wantAmount
    local exactTail = room == wantAmount
    if not best then
        return true
    end
    if exactTail ~= (best.exactTail == true) then
        return exactTail
    end
    if fitsFull ~= best.fitsFull then
        return fitsFull
    end
    if not fitsFull and take ~= (best.take or 0) then
        return take > (best.take or 0)
    end
    if remainder ~= best.remainder then
        return remainder < best.remainder
    end
    return count < best.count
end

local function FindMergeSlot(inv, destContainerIDs, itemID, amount, maxStack, tierKind)
    if not maxStack or maxStack <= 1 or not itemID then
        return nil
    end
    amount = tonumber(amount) or 1
    itemID = tonumber(itemID)
    local mergeAmt = math.min(amount, tonumber(amount) or amount)
    if CursorHasItem() then
        local onCursor = Mover.GetCursorItemCount()
        if onCursor > 0 then
            mergeAmt = math.min(mergeAmt, onCursor, amount)
        end
    end
    local bestBag, bestSlot, bestScore
    for _, bag in ipairs(destContainerIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local matches, info = SlotMatchesMerge(inv, bag, slot, itemID, tierKind)
            if matches and info then
                local stackMax = GetStackMaxForItem(info.itemID, maxStack)
                local count = info.count or 0
                local room = stackMax - count
                local take = math.min(mergeAmt, room)
                if take > 0 and count + take <= stackMax then
                    if isBetterMergeTarget(count, room, take, stackMax, amount, bestScore) then
                        bestScore = {
                            fitsFull = take >= amount,
                            exactTail = room == amount,
                            remainder = stackMax - (count + take),
                            count = count,
                            take = take,
                            room = room,
                        }
                        bestBag, bestSlot = bag, slot
                    end
                end
            end
        end
    end
    return bestBag, bestSlot
end

--- First empty slot scanning bags in backpack-first order (fill bag 1, then 2, …).
function Mover.FindFirstEmptyBagSlot(destContainerIDs)
    local inv = GetInv()
    if not inv or not destContainerIDs then
        return nil, nil
    end
    for _, bag in ipairs(destContainerIDs) do
        local numSlots = inv.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            if not inv.GetContainerItemInfo(bag, slot) then
                return bag, slot
            end
        end
    end
    return nil, nil
end

--- Empty bag slot that keeps stacks of the same item together: prefer
--- adjacent to an existing partial/full stack, then same bag, then any empty.
function Mover.FindConsolidatedEmptySlot(destContainerIDs, itemID, tierKind)
    local inv = GetInv()
    itemID = tonumber(itemID)
    if not inv or not destContainerIDs then
        return nil, nil
    end
    local function slotEmpty(bag, slot)
        return not inv.GetContainerItemInfo(bag, slot)
    end
    local function slotMatches(info)
        if not info or not info.itemID or (info.count or 0) <= 0 then
            return false
        end
        if itemID then
            return Mover.ItemsCanMerge(info.itemID, itemID, tierKind)
        end
        return false
    end

    local afterAdj, beforeAdj, sameBagAfter, firstEmpty
    for _, bag in ipairs(destContainerIDs) do
        local numSlots = inv.GetContainerNumSlots(bag)
        local lastMatchSlot
        for slot = 1, numSlots do
            local info = inv.GetContainerItemInfo(bag, slot)
            if not info then
                if not firstEmpty then
                    firstEmpty = { bag = bag, slot = slot }
                end
            elseif slotMatches(info) then
                lastMatchSlot = slot
                if slot < numSlots and slotEmpty(bag, slot + 1) then
                    afterAdj = { bag = bag, slot = slot + 1 }
                end
                if slot > 1 and slotEmpty(bag, slot - 1) then
                    beforeAdj = beforeAdj or { bag = bag, slot = slot - 1 }
                end
            end
        end
        if lastMatchSlot and not sameBagAfter then
            for slot = lastMatchSlot + 1, numSlots do
                if slotEmpty(bag, slot) then
                    sameBagAfter = { bag = bag, slot = slot }
                    break
                end
            end
        end
    end

    local pick = afterAdj or beforeAdj or sameBagAfter or firstEmpty
    if pick then
        return pick.bag, pick.slot
    end
    return Mover.FindFirstEmptyBagSlot(destContainerIDs)
end

--- Best partial stack to merge into: bag, slot, and room available there.
function Mover.GetBestMergeTarget(destContainerIDs, itemID, wantAmount, maxStack, tierKind)
    local inv = GetInv()
    wantAmount = tonumber(wantAmount) or 0
    maxStack = tonumber(maxStack) or 20
    itemID = tonumber(itemID)
    if not inv or wantAmount <= 0 or maxStack <= 1 or not destContainerIDs then
        return nil, nil, 0, 0
    end
    if not itemID and not tierKind then
        return nil, nil, 0, 0
    end
    local bestBag, bestSlot, bestTakeRoom, bestRoomFull, bestScore
    for _, bag in ipairs(destContainerIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local matches, info = SlotMatchesMerge(inv, bag, slot, itemID, tierKind)
            if matches and info then
                local stackMax = GetStackMaxForItem(info.itemID, maxStack)
                local count = info.count or 0
                local room = stackMax - count
                if room > 0 then
                    local take = math.min(wantAmount, room)
                    if isBetterMergeTarget(count, room, take, stackMax, wantAmount, bestScore) then
                        bestScore = {
                            fitsFull = take >= wantAmount,
                            exactTail = room == wantAmount,
                            remainder = stackMax - (count + take),
                            count = count,
                            take = take,
                            room = room,
                        }
                        bestBag = bag
                        bestSlot = slot
                        bestTakeRoom = math.min(room, wantAmount)
                        bestRoomFull = room
                    end
                end
            end
        end
    end
    return bestBag, bestSlot, bestTakeRoom or 0, bestRoomFull or 0
end

--- Largest room in any partial stack of itemID within the container set.
function Mover.GetMaxMergeRoom(destContainerIDs, itemID, maxStack, tierKind)
    local inv = GetInv()
    maxStack = tonumber(maxStack) or 20
    itemID = tonumber(itemID)
    if not inv or maxStack <= 1 or not destContainerIDs then
        return 0
    end
    if not itemID and not tierKind then
        return 0
    end
    local best = 0
    for _, bag in ipairs(destContainerIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local matches, info = SlotMatchesMerge(inv, bag, slot, itemID, tierKind)
            if matches and info then
                local stackMax = GetStackMaxForItem(info.itemID, maxStack)
                local room = stackMax - (info.count or 0)
                if room > best then
                    best = room
                end
            end
        end
    end
    return best
end

--- Sum of merge room across all partial stacks of itemID in the container set.
function Mover.GetTotalMergeRoom(destContainerIDs, itemID, maxStack, tierKind)
    local inv = GetInv()
    maxStack = tonumber(maxStack) or 20
    itemID = tonumber(itemID)
    if not inv or maxStack <= 1 or not destContainerIDs then
        return 0
    end
    if not itemID and not tierKind then
        return 0
    end
    local total = 0
    for _, bag in ipairs(destContainerIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local matches, info = SlotMatchesMerge(inv, bag, slot, itemID, tierKind)
            if matches and info then
                local stackMax = GetStackMaxForItem(info.itemID, maxStack)
                local room = stackMax - (info.count or 0)
                if room > 0 then
                    total = total + room
                end
            end
        end
    end
    return total
end

--- How many of wantAmount can be placed in the container set this tick
--- (empty slots first, then merge room for the exact itemID).
function Mover.GetMaxPlaceableAmount(destContainerIDs, itemID, wantAmount, maxStack, tierKind)
    local inv = GetInv()
    wantAmount = tonumber(wantAmount) or 0
    if not inv or wantAmount <= 0 then
        return 0
    end
    maxStack = tonumber(maxStack) or 20
    for _, bag in ipairs(destContainerIDs) do
        if inv.GetContainerNumFreeSlots(bag) > 0 then
            return math.min(wantAmount, maxStack)
        end
    end
    for _, bag in ipairs(destContainerIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            if not inv.GetContainerItemInfo(bag, slot) then
                return math.min(wantAmount, maxStack)
            end
        end
    end
    local mergeRoom = Mover.GetMaxMergeRoom(destContainerIDs, itemID, maxStack, tierKind)
    if mergeRoom > 0 then
        return math.min(wantAmount, mergeRoom)
    end
    return 0
end

--- True when at least one completely empty bag slot exists (ignores merge room).
function Mover.HasEmptyBagSlot(destContainerIDs)
    local inv = GetInv()
    if not inv then
        return false
    end
    for _, bag in ipairs(destContainerIDs) do
        if inv.GetContainerNumFreeSlots(bag) > 0 then
            return true
        end
    end
    for _, bag in ipairs(destContainerIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            if not inv.GetContainerItemInfo(bag, slot) then
                return true
            end
        end
    end
    return false
end

--- True when at least one item can be placed (merge room or empty slot).
function Mover.HasDestinationRoom(destContainerIDs, itemID, maxStack, tierKind)
    return Mover.GetMaxPlaceableAmount(destContainerIDs, itemID, 1, maxStack, tierKind) >= 1
end

function Mover.CanPlaceAmount(destContainerIDs, itemID, wantAmount, maxStack, tierKind)
    wantAmount = tonumber(wantAmount) or 0
    if wantAmount <= 0 then
        return false
    end
    return Mover.GetMaxPlaceableAmount(destContainerIDs, itemID, wantAmount, maxStack, tierKind) >= wantAmount
end

local function TryPutInBagWithSpace(inv, destContainerIDs)
    for _, bag in ipairs(destContainerIDs) do
        if inv.GetContainerNumFreeSlots(bag) > 0 then
            if bag == BACKPACK then
                if PutItemInBackpack then
                    PutItemInBackpack()
                    if not CursorHasItem() then
                        return true
                    end
                end
            else
                local invSlot = GetBagInventorySlot(bag)
                if invSlot and PutItemInBag then
                    PutItemInBag(invSlot)
                    if not CursorHasItem() then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function TryEmptySlotPickup(inv, destContainerIDs, preferredBag, preferredSlot)
    preferredBag = tonumber(preferredBag)
    preferredSlot = tonumber(preferredSlot)
    if preferredBag and preferredSlot and not inv.GetContainerItemInfo(preferredBag, preferredSlot) then
        inv.PickupContainerItem(preferredBag, preferredSlot)
        if not CursorHasItem() then
            return true
        end
    end
    for _, bag in ipairs(destContainerIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            if not inv.GetContainerItemInfo(bag, slot) then
                inv.PickupContainerItem(bag, slot)
                if not CursorHasItem() then
                    return true
                end
            end
        end
    end
    return false
end

--- Place the cursor-held stack into the given containers (merge first, then
--- free slots). Returns true when the cursor was emptied.
function Mover.PlaceCursorInContainers(destContainerIDs, itemID, amount, maxStack, preferredBag, preferredSlot, placementMode, tierKind)
    local inv = GetInv()
    if not inv or not CursorHasItem() or not destContainerIDs then
        return false
    end
    amount = tonumber(amount) or 1
    maxStack = tonumber(maxStack) or 20
    itemID = tonumber(itemID)

    local function tryMergeInto(bag, slot)
        if not bag or not slot then
            return false
        end
        return tryPartialMergeIntoSlot(inv, bag, slot, itemID, tierKind) > 0
    end

    local function tryMerge()
        if tryMergeInto(preferredBag, preferredSlot) then
            return true
        end
        local mergeBag, mergeSlot = FindMergeSlot(inv, destContainerIDs, itemID, amount, maxStack, tierKind)
        if mergeBag and mergeSlot and (mergeBag ~= preferredBag or mergeSlot ~= preferredSlot) then
            if tryMergeInto(mergeBag, mergeSlot) then
                return true
            end
        end
        return false
    end

    local function runChain(chain)
        for i = 1, #chain do
            local step = chain[i]
            if step == "merge" then
                if tryMerge() then return true end
            elseif step == "empty" then
                if TryEmptySlotPickup(inv, destContainerIDs, preferredBag, preferredSlot)
                    and not CursorHasItem() then
                    return true
                end
            elseif step == "autodrop" then
                if TryPutInBagWithSpace(inv, destContainerIDs) and not CursorHasItem() then return true end
            elseif step == "backpack" then
                if PutItemInBackpack and CursorHasItem() then
                    PutItemInBackpack()
                    if not CursorHasItem() then return true end
                end
            end
        end
        return false
    end

    if placementMode == "mergeOnly" then
        if tryMerge() then
            return true
        end
        local mergeBag, mergeSlot = FindMergeSlot(inv, destContainerIDs, itemID, amount, maxStack, tierKind)
        if mergeBag and mergeSlot and (mergeBag ~= preferredBag or mergeSlot ~= preferredSlot) then
            if tryMergeInto(mergeBag, mergeSlot) then
                return true
            end
        end
        return false
    end
    if placementMode == "newStackFirst" then
        return runChain({ "empty", "autodrop", "backpack", "merge" }) and not CursorHasItem()
    end
    return runChain({ "merge", "empty", "autodrop", "backpack" }) and not CursorHasItem()
end

function Mover.PlaceCursorInPlayerBags(itemID, amount, maxStack, placementMode, preferredBag, preferredSlot, tierKind)
    local inv = GetInv()
    if not inv then return false end
    return Mover.PlaceCursorInContainers(
        inv.GetBagContainerIDs(), itemID, amount, maxStack, preferredBag, preferredSlot, placementMode, tierKind)
end

-- ---------------------------------------------------------------------------
-- LOW-LEVEL MOVE PRIMITIVES (each returns amount moved; 0 on failure/deferred)
-- ---------------------------------------------------------------------------

local function IsBankBag(bag)
    local inv = GetInv()
    local bank = inv and inv.Bank
    return bank and bank.IsBankContainer and bank.IsBankContainer(bag) or false
end

--- Restocker PutItemInPlayerBag: merge-first FindBestFit, then empty slot,
--- then bag-level drop. Returns true only when the cursor was emptied.
function Mover.PutItemInPlayerBag(itemID, amount, maxStack, tierKind, preferredBag, preferredSlot)
    local inv = GetInv()
    if not inv or not CursorHasItem() then
        return false
    end
    local onCursor = Mover.GetCursorItemCount()
    if onCursor <= 0 then
        onCursor = tonumber(amount) or 1
    end
    amount = onCursor
    itemID = tonumber(itemID)
    if GetCursorInfo then
        local cursorType, id = GetCursorInfo()
        if cursorType == "item" then
            itemID = tonumber(id) or itemID
        end
    end
    if not itemID then
        return false
    end
    maxStack = tonumber(maxStack) or GetStackMaxForItem(itemID, 20)
    local bagIDs = inv.GetBagContainerIDs()
    preferredBag = tonumber(preferredBag)
    preferredSlot = tonumber(preferredSlot)

    local function tryMergeInto(bag, slot)
        return tryPartialMergeIntoSlot(inv, bag, slot, itemID, tierKind) > 0
    end

    if preferredBag and preferredSlot and tryMergeInto(preferredBag, preferredSlot) then
        return not CursorHasItem()
    end

    local mergeBag, mergeSlot = FindMergeSlot(inv, bagIDs, itemID, onCursor, maxStack, tierKind)
    if mergeBag and mergeSlot and tryMergeInto(mergeBag, mergeSlot) then
        return true
    end

    local emptyBag, emptySlot = preferredBag, preferredSlot
    if not emptyBag or inv.GetContainerItemInfo(emptyBag, emptySlot) then
        emptyBag, emptySlot = Mover.FindConsolidatedEmptySlot(bagIDs, itemID, tierKind)
    end
    if emptyBag and emptySlot and not inv.GetContainerItemInfo(emptyBag, emptySlot) then
        inv.PickupContainerItem(emptyBag, emptySlot)
        if not CursorHasItem() then
            return true
        end
    end

    for _, bag in ipairs(bagIDs) do
        local numSlots = inv.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = inv.GetContainerItemInfo(bag, slot)
            if not info then
                inv.PickupContainerItem(bag, slot)
                return not CursorHasItem()
            end
        end
    end

    for _, bag in ipairs(bagIDs) do
        if inv.GetContainerNumFreeSlots(bag) > 0 then
            if bag == BACKPACK then
                if PutItemInBackpack then
                    PutItemInBackpack()
                end
            else
                local invSlot = GetBagInventorySlot(bag)
                if invSlot and PutItemInBag then
                    PutItemInBag(invSlot)
                end
            end
            return not CursorHasItem()
        end
    end

    return false
end

local function IssueBankSplit(bag, slot, amount)
    local inv = GetInv()
    bag = tonumber(bag)
    slot = tonumber(slot)
    amount = math.floor(tonumber(amount) or 0)
    if CursorHasItem() then
        return false
    end
    if action and action.splitRejected and not action.microSplitFallback then
        return false
    end
    if action and action.splitIssued and tonumber(action.bag) == bag and tonumber(action.slot) == slot
        and not action.microSplitFallback then
        if inv and inv.SplitContainerItemPending
            and inv.SplitContainerItemPending(bag, slot, action.splitCountBefore or 0, action.amount) then
            return false
        end
        return false
    end
    if inv and inv.SplitContainerItem then
        return inv.SplitContainerItem(bag, slot, amount)
    end
    local C_Split = (C_Container and C_Container.SplitContainerItem) or _G.SplitContainerItem
    if not C_Split or not bag or not slot or amount <= 0 then
        return false
    end
    pcall(C_Split, bag, slot, amount)
    return CursorHasItem()
end

--- True when this action already issued (or is resolving) a bank split for bag:slot.
local function bankSplitInFlight(a, inv, bag, slot)
    if not a or tonumber(a.bag) ~= tonumber(bag) or tonumber(a.slot) ~= tonumber(slot) then
        return false
    end
    if CursorHasItem() then
        return true
    end
    if not a.splitIssued then
        return false
    end
    if inv and inv.SplitContainerItemPending
        and inv.SplitContainerItemPending(bag, slot, a.splitCountBefore or 0, a.amount) then
        return true
    end
    return true
end

--- Restocker-style: split exact `want` from bank, merge into partial bag stack.
--- Returns status, optional moved count.
local function splitThenMergeFromBank(inv, bag, slot, want, mergeBag, mergeSlot, countBefore)
    want = math.floor(tonumber(want) or 0)
    bag = tonumber(bag)
    slot = tonumber(slot)
    mergeBag = tonumber(mergeBag)
    mergeSlot = tonumber(mergeSlot)
    countBefore = tonumber(countBefore) or 0
    if not inv or not bag or not slot or not mergeBag or not mergeSlot or want <= 0 then
        return "split_failed"
    end
    if action and isSlotLocked(bag, slot) and not action.bankUnlocked then
        return "split_pending"
    end
    if bankSplitInFlight(action, inv, bag, slot) then
        if CursorHasItem() then
            if action and action.stepMode == "merge" then
                action.splitIssued = true
                action.splitCountBefore = countBefore
                action.mergeSplitPull = action.execKind ~= "whole_merge"
                action.mergePullDone = true
            end
            if not isSlotLocked(mergeBag, mergeSlot) then
                local gain = tryPartialMergeIntoSlot(
                    inv, mergeBag, mergeSlot, action and action.itemID, action and action.tierKind)
                if gain > 0 then
                    Dbg("merge", "split in-flight cursor merge gain=%s target=%s:%s", gain, mergeBag, mergeSlot)
                    if not CursorHasItem() then
                        return "done", gain
                    end
                end
            end
            return "merge_pending"
        end
        return "split_pending"
    end
    if action and action.stepMode == "merge" then
        action.splitIssued = true
        action.splitCountBefore = countBefore
        action.mergeSplitPull = action.execKind ~= "whole_merge"
    end
    IssueBankSplit(bag, slot, want)
    if not CursorHasItem() then
        if inv.SplitContainerItemPending
            and inv.SplitContainerItemPending(bag, slot, countBefore, want) then
            return "split_pending"
        end
        return "split_failed"
    end
    local cur = Mover.GetCursorItemCount()
    if cur > want then
        Dbg("merge", "cursor oversize cur=%s want=%s — blocked", cur, want)
        return "oversize_cursor"
    end
    Dbg("merge", "split issued bank=%s:%s want=%s cursor=%s target=%s:%s (merge on unlock)",
        bag, slot, want, cur, mergeBag, mergeSlot)
    if action and action.stepMode == "merge" then
        action.mergePullDone = true
    end
    if not isSlotLocked(mergeBag, mergeSlot) then
        local gain = tryPartialMergeIntoSlot(
            inv, mergeBag, mergeSlot, action and action.itemID, action and action.tierKind)
        if gain > 0 then
            Dbg("merge", "split cursor merge gain=%s target=%s:%s", gain, mergeBag, mergeSlot)
            if not CursorHasItem() then
                return "done", gain
            end
        end
    end
    return "merge_pending"
end

--- TSM fallback when bank split fails: split+place to empty bag slot, then bag-split merge.
--- atomicOnly: skip bank split and move the whole bank stack to staging (split-reject recovery).
local function tryTsmStagingFromBank(inv, bag, slot, want, itemID, tierKind, countBefore, a, atomicOnly)
    a = a or action
    if not a then
        return false
    end
    want = math.floor(tonumber(want) or 0)
    bag = tonumber(bag)
    slot = tonumber(slot)
    countBefore = tonumber(countBefore) or 0
    if not inv or not bag or not slot or want <= 0 or CursorHasItem() then
        return false
    end
    local stagingBag, stagingSlot = findMergeStagingSlot(inv, itemID, tierKind)
    if not stagingBag or not stagingSlot or inv.GetContainerItemInfo(stagingBag, stagingSlot) then
        return false
    end
    local noSplit = a.itemNoSplit or a.execKind == "whole_merge"
    local br = _G.FluxBankRestock
    if not noSplit and br and br.IsNoSplit and itemID then
        noSplit = br.IsNoSplit({ itemID = itemID }) == true
    end
    if noSplit then
        local mergeRoom = 0
        if a.mergeBag and a.mergeSlot then
            mergeRoom = liveMergeRoom(inv, a.mergeBag, a.mergeSlot,
                GetStackMaxForItem(itemID, 20))
        end
        if countBefore > want and (mergeRoom <= 0 or countBefore > mergeRoom) then
            Dbg("merge", "no-split staging blocked bank=%s:%s count=%s want=%s room=%s",
                bag, slot, countBefore, want, mergeRoom)
            return false
        end
        inv.PickupContainerItem(bag, slot)
        if not CursorHasItem() then
            return false
        end
        inv.PickupContainerItem(stagingBag, stagingSlot)
        if a and a.stepMode == "merge" then
            beginMergeStaging(a, stagingBag, stagingSlot)
            if CursorHasItem() then
                a.stagingPhase = "deposit"
                Dbg("merge", "no-split atomic bank->staging deposit bank=%s:%s -> %s:%s",
                    bag, slot, stagingBag, stagingSlot)
            else
                a.stagingPhase = "merge_from_staging"
                Dbg("merge", "no-split atomic bank->staging bank=%s:%s -> %s:%s count=%s",
                    bag, slot, stagingBag, stagingSlot, countBefore)
            end
        end
        return true
    end
    if not atomicOnly and IssueBankSplit(bag, slot, want) and CursorHasItem() then
        local cur = Mover.GetCursorItemCount()
        if cur > want then
            if tryReturnCursorToSlot then
                tryReturnCursorToSlot(inv, bag, slot)
            elseif Mover.ClearCursor then
                Mover.ClearCursor()
            end
            return false
        end
        inv.PickupContainerItem(stagingBag, stagingSlot)
        if CursorHasItem() then
            if a and a.stepMode == "merge" then
                beginMergeStaging(a, stagingBag, stagingSlot)
                a.stagingPhase = "deposit"
            end
            Dbg("merge", "split failed -> TSM staging deposit bank=%s:%s -> %s:%s want=%s",
                bag, slot, stagingBag, stagingSlot, want)
            return true
        end
        if a and a.stepMode == "merge" then
            beginMergeStaging(a, stagingBag, stagingSlot)
            a.stagingPhase = "merge_from_staging"
        end
        Dbg("merge", "split failed -> TSM staging bank=%s:%s -> %s:%s want=%s",
            bag, slot, stagingBag, stagingSlot, want)
        return true
    end
    -- Last resort: atomic whole bank stack -> empty staging slot (same tick).
    if atomicOnly then
        Dbg("merge", "atomic staging only bank=%s:%s want=%s count=%s", bag, slot, want, countBefore)
    end
    inv.PickupContainerItem(bag, slot)
    if not CursorHasItem() then
        return false
    end
    inv.PickupContainerItem(stagingBag, stagingSlot)
    if a and a.stepMode == "merge" then
        beginMergeStaging(a, stagingBag, stagingSlot)
        if CursorHasItem() then
            a.stagingPhase = "deposit"
            Dbg("merge", "atomic bank->staging deposit pending bank=%s:%s", bag, slot)
        else
            a.stagingPhase = "merge_from_staging"
            Dbg("merge", "atomic bank->staging bank=%s:%s -> %s:%s count=%s",
                bag, slot, stagingBag, stagingSlot, countBefore)
        end
        return true
    end
    if CursorHasItem() then
        if tryReturnCursorToSlot and tryReturnCursorToSlot(inv, bag, slot) then
            return false
        end
        if Mover.ClearCursor then
            Mover.ClearCursor()
        end
    end
    return false
end

--- Whole stack or split+place, same tick when possible (optimistic).
--- Returns amount moved this call; 0 means "still resolving" or "failed".
local function MoveFromBankToPlayer(bag, slot, amount, itemID, maxStack, tierKind, preferredBag, preferredSlot)
    local inv = GetInv()
    bag = tonumber(bag)
    slot = tonumber(slot)
    amount = tonumber(amount) or 0
    if not inv or not bag or not slot or amount <= 0 or CursorHasItem() then
        return 0
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    if not info or info.locked or (info.count or 0) <= 0 then
        return 0
    end
    local count = info.count or 0
    itemID = tonumber(itemID) or info.itemID
    maxStack = tonumber(maxStack) or GetStackMaxForItem(itemID, 20)
    amount = math.min(amount, count)
    preferredBag = tonumber(preferredBag)
    preferredSlot = tonumber(preferredSlot)

    if inv.NotifyAutomationPulse then
        inv.NotifyAutomationPulse(0.45)
    end

    local mergeInto = preferredBag and preferredSlot
    local pullAmt = math.min(amount, count)

    -- Whole stack via UseContainerItem when no merge target and stack fits pull.
    if not mergeInto and count <= pullAmt then
        inv.UseContainerItem(bag, slot)
        if CursorHasItem() then
            if not Mover.PutItemInPlayerBag(
                itemID, count, maxStack, tierKind, preferredBag, preferredSlot) then
                return 0
            end
        end
        if CursorHasItem() then
            return 0
        end
        return count
    end

    -- Merge into a partial bag stack. Never UseContainerItem — it withdraws the
    -- whole stack. Partial pulls use split-then-merge (Restocker) with TSM
    -- staging fallback when bank split is rejected.
    if mergeInto then
        local want = math.min(pullAmt, count)
        local mergeRoom = liveMergeRoom(inv, preferredBag, preferredSlot, maxStack)
        local execKind = action and action.execKind
        local br = _G.FluxBankRestock
        local noSplit = action and (action.itemNoSplit == true or execKind == "whole_merge")
        if action and not noSplit and br and br.IsNoSplit and itemID then
            noSplit = br.IsNoSplit({ itemID = itemID }) == true
        end
        local canSplitMerge = execKind == "split_merge" and not noSplit

        if mergeRoom > 0 and count <= mergeRoom then
            inv.PickupContainerItem(bag, slot)
            if not CursorHasItem() then
                return 0
            end
            if action and action.stepMode == "merge" then
                action.mergePullDone = true
                action.mergeSplitPull = false
                action.splitIssued = false
                action.execKind = "whole_merge"
            end
            Dbg("mover", "whole merge pickup bank=%s:%s count=%s room=%s",
                bag, slot, count, mergeRoom)
            return 0
        end

        if count <= want then
            inv.PickupContainerItem(bag, slot)
            if not CursorHasItem() then
                return 0
            end
            Dbg("mover", "defer merge whole cursor bank=%s:%s count=%s want=%s room=%s",
                bag, slot, count, want, mergeRoom)
            return 0
        end

        if noSplit and count > mergeRoom then
            if tryTsmStagingFromBank(inv, bag, slot, want, itemID, tierKind, count, action) then
                return 0
            end
            if action then
                action.mergeNoViable = true
            end
            Dbg("mover", "no-split merge blocked bank=%s:%s count=%s want=%s room=%s",
                bag, slot, count, want, mergeRoom)
            return 0
        end

        if canSplitMerge then
            local status, moved = splitThenMergeFromBank(
                inv, bag, slot, want, preferredBag, preferredSlot, count)
            if status == "done" then
                return moved
            end
            if status == "split_pending" or status == "merge_pending" then
                if action and action.stepMode == "merge" then
                    action.splitIssued = true
                    action.splitCountBefore = count
                    action.mergeSplitPull = true
                end
                return 0
            end
            if status == "oversize_cursor" then
                tryReturnCursorToSlot(inv, bag, slot)
                return 0
            end
            if status == "split_failed" then
                if tryTsmStagingFromBank(inv, bag, slot, want, itemID, tierKind, count, action, true) then
                    return 0
                end
                if tryTsmStagingFromBank(inv, bag, slot, want, itemID, tierKind, count, action) then
                    return 0
                end
            end
        end

        if tryTsmStagingFromBank(inv, bag, slot, want, itemID, tierKind, count, action) then
            return 0
        end
        if action then
            action.mergeNoViable = true
        end
        Dbg("mover", "merge no viable bank=%s:%s count=%s want=%s room=%s exec=%s",
            bag, slot, count, want, mergeRoom, tostring(execKind))
        return 0
    end

    -- Pickup/split then place: partial pull to a new/empty bag slot.
    local moveAmt = pullAmt
    local countBefore = count
    local needsSplit = moveAmt < countBefore

    Dbg("mover", "MoveFromBankToPlayer bag=%s:%s count=%s moveAmt=%s needsSplit=%s merge=%s:%s",
        bag, slot, count, moveAmt, needsSplit and "Y" or "N",
        tostring(preferredBag or "-"), tostring(preferredSlot or "-"))

    local splitIssued = false
    if not needsSplit then
        inv.PickupContainerItem(bag, slot)
        moveAmt = countBefore
    else
        splitIssued = IssueBankSplit(bag, slot, moveAmt)
    end

    if not CursorHasItem() then
        if splitIssued and inv.SplitContainerItemPending
            and inv.SplitContainerItemPending(bag, slot, countBefore) then
            return 0
        end
        return 0
    end

    -- Defer cursor placement to the action-resolve poll (multi-tick safe).
    if needsSplit then
        Dbg("mover", "defer place cursor bag=%s:%s needsSplit=%s",
            bag, slot, needsSplit and "Y" or "N")
        return 0
    end

    if not Mover.PutItemInPlayerBag(
        itemID, moveAmt, maxStack, tierKind, preferredBag, preferredSlot) then
        return 0
    end
    if CursorHasItem() then
        return 0
    end
    return moveAmt
end

--- Pick up from one player-bag slot and merge into another (bag consolidation).
local function MovePlayerBagToMerge(fromBag, fromSlot, toBag, toSlot, amount, itemID, maxStack, tierKind)
    local inv = GetInv()
    fromBag = tonumber(fromBag)
    fromSlot = tonumber(fromSlot)
    toBag = tonumber(toBag)
    toSlot = tonumber(toSlot)
    amount = tonumber(amount) or 0
    if not inv or not fromBag or not fromSlot or not toBag or not toSlot or amount <= 0 or CursorHasItem() then
        return 0
    end
    local fromInfo = inv.GetContainerItemInfo(fromBag, fromSlot)
    if not fromInfo or fromInfo.locked or (fromInfo.count or 0) <= 0 then
        return 0
    end
    local count = fromInfo.count or 0
    itemID = tonumber(itemID) or fromInfo.itemID
    maxStack = tonumber(maxStack) or GetStackMaxForItem(itemID, 20)
    amount = math.min(amount, count)
    local toInfo = inv.GetContainerItemInfo(toBag, toSlot)
    if not toInfo or not toInfo.itemID then
        return 0
    end
    local room = maxStack - (toInfo.count or 0)
    amount = math.min(amount, room)
    if amount <= 0 then
        return 0
    end

    if inv.NotifyAutomationPulse then
        inv.NotifyAutomationPulse(0.45)
    end

    local needsSplit = amount < count
        and not (action and (action.itemNoSplit or action.execKind == "whole_merge"))
    if not needsSplit then
        inv.PickupContainerItem(fromBag, fromSlot)
    else
        IssueBankSplit(fromBag, fromSlot, amount)
    end

    if not CursorHasItem() then
        if needsSplit and inv.SplitContainerItemPending
            and inv.SplitContainerItemPending(fromBag, fromSlot, count, amount) then
            return 0
        end
        return 0
    end

    if Mover.PlaceCursorInPlayerBags(itemID, amount, maxStack, "mergeOnly", toBag, toSlot, tierKind) then
        return amount
    end
    return 0
end

--- Move an entire stack to the opposite side (bank<->bags; both open).
function Mover.MoveWholeStack(bag, slot)
    local inv = GetInv()
    if not inv or CursorHasItem() then
        return 0
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    if not info or info.locked or (info.count or 0) <= 0 then
        return 0
    end
    if IsBankBag(bag) then
        return MoveFromBankToPlayer(bag, slot, info.count, info.itemID, nil, nil) or 0
    end

    local itemID = info.itemID
    local count = info.count or 0
    inv.UseContainerItem(bag, slot)

    if CursorHasItem() then
        return 0
    end

    local afterInfo = inv.GetContainerItemInfo(bag, slot)
    if not afterInfo or not afterInfo.itemID then
        return count
    end
    if afterInfo.itemID == itemID and (afterInfo.count or 0) < count then
        return count - (afterInfo.count or 0)
    end
    return 0
end

-- ---------------------------------------------------------------------------
-- GLOBAL PACING GATE
--
-- One interval gates EVERY bank action submission, regardless of which
-- slot/item it targets. A confirmed split rejection grows the interval
-- (backoff); a clean success resets it. This is the actual fix for
-- cascading "Couldn't split those items" rejections across different slots.
-- ---------------------------------------------------------------------------

local BASE_INTERVAL = 0.14      -- Restocker-style floor for whole-stack/merge actions
local SPLIT_BASE_INTERVAL = 0.20 -- splits settle slower server-side
local TURBO_BASE_INTERVAL = 0.07
local TURBO_SPLIT_BASE_INTERVAL = 0.10
local BACKOFF_MULT = 1.8
local BACKOFF_MAX_STEPS = 6
local BACKOFF_MAX_INTERVAL = 3.0

local turboMode = false
local backoffSteps = 0
local nextActionAt = 0

local function PingScaled(floor, mult)
    if not GetNetStats then
        return floor
    end
    local _, _, pingHome, pingWorld = GetNetStats()
    local maxPing = math.max(pingHome or 0, pingWorld or 0)
    return math.max(floor, (maxPing * mult) / 1000)
end

--- Interval to wait before the NEXT action may be submitted.
function Mover.GetActionInterval(isSplit)
    local wholeBase = turboMode and TURBO_BASE_INTERVAL or BASE_INTERVAL
    local splitBase = turboMode and TURBO_SPLIT_BASE_INTERVAL or SPLIT_BASE_INTERVAL
    local base = isSplit and PingScaled(splitBase, 3.5) or PingScaled(wholeBase, 3)
    if backoffSteps <= 0 then
        return base
    end
    return math.min(base * (BACKOFF_MULT ^ backoffSteps), BACKOFF_MAX_INTERVAL)
end

function Mover.SetTurboMode(on)
    turboMode = on and true or false
end

function Mover.IsTurboMode()
    return turboMode
end

local function NoteActionOutcome(ok, hardFail)
    if ok then
        backoffSteps = 0
        return
    end
    backoffSteps = math.min(BACKOFF_MAX_STEPS, backoffSteps + (hardFail and 2 or 1))
end

local function ArmGate(isSplit)
    nextActionAt = (GetTime and GetTime() or 0) + Mover.GetActionInterval(isSplit)
end

local function GateOpen()
    return (GetTime and GetTime() or 0) >= nextActionAt
end

--- Debug/inspection only.
function Mover.GetBackoffSteps()
    return backoffSteps
end

function Mover.IsGateOpen()
    return GateOpen()
end

function Mover.GetGateWaitRemaining()
    if GateOpen() then
        return 0
    end
    return math.max(0, nextActionAt - (GetTime and GetTime() or 0))
end

-- ---------------------------------------------------------------------------
-- ACTION ENGINE — one in-flight bank action at a time
-- ---------------------------------------------------------------------------

local SPLIT_WAIT_LIMIT = 30
local MERGE_WAIT_LIMIT = 120
local STAGING_WAIT_LIMIT = 90
local SPLIT_ASYNC_WAIT_LIMIT = 12
local SPLIT_SETTLE_TICKS = 5
local CURSOR_STUCK_LIMIT = 40
local MERGE_CURSOR_STUCK_LIMIT = 90
local MERGE_STUCK_FALLBACK_TICKS = 25
local MERGE_PLACE_GAIN_WAIT = 10

function Mover.SetLockContainers(containerIDs)
    lockContainers = containerIDs
end

bagSlotCount = function(inv, bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not inv or not bag or not slot then
        return 0
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    return info and (info.count or 0) or 0
end

isSlotLocked = function(bag, slot)
    local inv = GetInv()
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not inv or not bag or not slot then
        return false
    end
    -- Player-bag "locked" is the user's item lock — it does not block stacking
    -- more of the same item from the cursor. Only bank sources stay gated.
    if not IsBankBag(bag) then
        return false
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    return info and info.locked or false
end

--- Merge as much of the cursor stack as fits onto bag:slot (WoW clips to room).
--- Returns items gained in the target slot; cursor may still hold the remainder.
tryPartialMergeIntoSlot = function(inv, bag, slot, itemID, tierKind)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not inv or not bag or not slot or not CursorHasItem() then
        return 0
    end
    local beforeInfo = inv.GetContainerItemInfo(bag, slot)
    if not beforeInfo or not beforeInfo.itemID then
        return 0
    end
    if IsBankBag(bag) and beforeInfo.locked then
        return 0
    end
    local cursorItemID = tonumber(itemID)
    if GetCursorInfo then
        local cursorType, id = GetCursorInfo()
        if cursorType == "item" then
            cursorItemID = tonumber(id) or cursorItemID
        end
    end
    if cursorItemID and not Mover.ItemsCanMerge(beforeInfo.itemID, cursorItemID, tierKind) then
        return 0
    end
    local beforeCount = beforeInfo.count or 0
    inv.PickupContainerItem(bag, slot)
    local afterInfo = inv.GetContainerItemInfo(bag, slot)
    local afterCount = afterInfo and afterInfo.count or 0
    return math.max(0, afterCount - beforeCount)
end

--- Place any cursor remainder back into a container slot (e.g. bank source).
tryReturnCursorToSlot = function(inv, bag, slot)
    if not CursorHasItem() then
        return true
    end
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not inv or not bag or not slot then
        return false
    end
    inv.PickupContainerItem(bag, slot)
    return not CursorHasItem()
end

bagTotalForItem = function(inv, itemID, tierKind)
    itemID = tonumber(itemID)
    if not inv or not itemID then
        return 0
    end
    local bagIDs = inv.GetBagContainerIDs and inv.GetBagContainerIDs()
    if not bagIDs then
        return 0
    end
    local total = 0
    local T = tierKind and _G.FluxRestockTiers or nil
    for _, bag in ipairs(bagIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = inv.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                if tierKind then
                    -- This is progress/gain ACCOUNTING (how much of the
                    -- whole tier landed in the bag), not a physical merge
                    -- decision — deliberately tier-wide, unlike
                    -- Mover.ItemsCanMerge which only ever answers "can
                    -- these two exact stacks physically combine".
                    if T and T.ItemMatchesRestockKind and T.ItemMatchesRestockKind(tierKind, info.itemID) then
                        total = total + (info.count or 0)
                    end
                elseif info.itemID == itemID then
                    total = total + (info.count or 0)
                end
            end
        end
    end
    return total
end

liveMergeRoom = function(inv, mergeBag, mergeSlot, maxStack)
    mergeBag = tonumber(mergeBag)
    mergeSlot = tonumber(mergeSlot)
    maxStack = tonumber(maxStack) or 20
    if not inv or not mergeBag or not mergeSlot then
        return 0
    end
    local info = inv.GetContainerItemInfo(mergeBag, mergeSlot)
    if not info or info.locked or not info.itemID then
        return 0
    end
    local stackMax = GetStackMaxForItem(info.itemID, maxStack)
    return math.max(0, stackMax - (info.count or 0))
end

--- True when overlay pickup can satisfy this merge action (no bank split).
local function isOverlaySafeMerge(a, inv)
    if not a or a.stepMode ~= "merge" or not a.mergeBag or not a.mergeSlot then
        return false
    end
    local amt = tonumber(a.amount) or 0
    if amt <= 0 then
        return false
    end
    local room = liveMergeRoom(inv, a.mergeBag, a.mergeSlot, a.realMaxStack or 20)
    if room <= 0 then
        return false
    end
    local count = tonumber(a.splitCountBefore)
    if (not count or count <= 0) and inv and a.bag and a.slot then
        count = bagSlotCount(inv, a.bag, a.slot)
    end
    return canOverlayMergePull(count or 0, amt, room)
end

local function resetMergeForOverlayRetry(a)
    a.mergeOverlay = true
    a.splitRejected = false
    a.splitIssued = false
    a.splitCountBefore = nil
    a.bankUnlocked = false
    a.mergePullDone = false
    a.mergePullStarted = false
    a.mustSplit = false
    a.microSplitFallback = false
    a.pullWaitTicks = 0
    a.lockWaitTicks = 0
    a.stuckTicks = 0
    a.cursorAmount = nil
    a.phase = "resolve"
end

local function IsSlotSplittable(bag, slot, amount)
    if CursorHasItem() then
        return false
    end
    local inv = GetInv()
    if not inv then
        return false
    end
    local info = inv.GetContainerItemInfo(bag, slot)
    if not info or info.locked then
        return false
    end
    local count = info.count or 0
    return count > 1 and amount < count
end

local function mergePlaceMode(mode)
    return mode == "merge" or mode == "bag_consolidate"
end

local function stampActionBaselines(a, inv)
    if not a or not inv then
        return
    end
    a.bagTotalBefore = a.bagTotalBefore or bagTotalForItem(inv, a.itemID, a.tierKind)
    if mergePlaceMode(a.stepMode) and a.mergeBag and a.mergeSlot then
        a.mergeSlotBefore = a.mergeSlotBefore or bagSlotCount(inv, a.mergeBag, a.mergeSlot)
    end
end

local function tryCompleteWithoutCursor(a, inv)
    if not a or not inv then
        return nil
    end
    if mergePlaceMode(a.stepMode) and a.mergeBag and a.mergeSlot then
        local beforeM = tonumber(a.mergeSlotBefore)
        if beforeM then
            local gain = bagSlotCount(inv, a.mergeBag, a.mergeSlot) - beforeM
            if gain > 0 then
                local cap = tonumber(a.amount) or gain
                local bagBefore = tonumber(a.bagTotalBefore)
                if bagBefore then
                    local totalGain = bagTotalForItem(inv, a.itemID, a.tierKind) - bagBefore
                    if totalGain > cap + 1 then
                        Dbg("merge", "spillover detected mergeGain=%s totalGain=%s cap=%s",
                            gain, totalGain, cap)
                        return nil
                    end
                end
                return math.min(gain, cap)
            end
        end
        return nil
    end
    local bagBefore = tonumber(a.bagTotalBefore)
    if bagBefore then
        local bagAfter = bagTotalForItem(inv, a.itemID, a.tierKind)
        local bagGain = math.max(0, bagAfter - bagBefore)
        if bagGain > 0 then
            return math.min(bagGain, tonumber(a.amount) or bagGain)
        end
    end
    return nil
end

local function bankSplitVisible(a, inv)
    if not a or not inv then
        return false
    end
    local before = tonumber(a.splitCountBefore) or 0
    local amt = tonumber(a.amount) or 0
    if before <= 0 or amt <= 0 or before <= amt then
        return false
    end
    return bagSlotCount(inv, a.bag, a.slot) == before - amt
end

local function needsBankUnlockAfterSplit(a, liveCount)
    local amt = tonumber(a and a.amount) or 0
    liveCount = tonumber(liveCount) or 0
    return a and a.stepMode == "merge" and amt > 0 and liveCount > amt
end

local function bankSplitReadyForMerge(a, inv)
    if a and a.mergeOverlay then
        return CursorHasItem() or a.bankUnlocked == true
    end
    if a and a.mergeSplitPull and (a.bankUnlocked or CursorHasItem()) then
        return true
    end
    if not a or not needsBankUnlockAfterSplit(a, a.splitCountBefore) then
        return true
    end
    if a.bankUnlocked then
        return true
    end
    if bankSplitVisible(a, inv) then
        a.bankUnlocked = true
        Dbg("mover", "bank split visible bag=%s:%s — ready to merge",
            tostring(a.bag), tostring(a.slot))
        return true
    end
    -- Split stack is on the cursor; the bank source may stay locked until merge finishes.
    if CursorHasItem() then
        return true
    end
    return false
end

--- After bank split+unlock, place the cursor stack onto the merge target.
--- Returns true when the action was finished.
local function tryCompleteMergeSplitPull(a, inv)
    if not a or a.stepMode ~= "merge" or a.tailMerge then
        return false
    end
    if not a.mergeSplitPull and a.execKind ~= "split_merge" and not a.splitIssued then
        return false
    end
    local mb, ms = tonumber(a.mergeBag), tonumber(a.mergeSlot)
    if not mb or not ms or not inv or not CursorHasItem() then
        return false
    end
    if a.splitCountBefore and a.bag and a.slot and not CursorHasItem() then
        local bankCount = bagSlotCount(inv, a.bag, a.slot)
        local before = tonumber(a.splitCountBefore) or 0
        if bankCount >= before then
            if inv and inv.SplitContainerItemPending
                and inv.SplitContainerItemPending(a.bag, a.slot, before, a.amount) then
                return false
            end
            if isSlotLocked(a.bag, a.slot) or not a.bankUnlocked then
                a.lockWaitTicks = (a.lockWaitTicks or 0) + 1
                if a.lockWaitTicks < SPLIT_WAIT_LIMIT then
                    return false
                end
            end
            a.splitReadyWaitTicks = (a.splitReadyWaitTicks or 0) + 1
            if a.splitReadyWaitTicks < SPLIT_WAIT_LIMIT then
                Dbg("merge", "split-pull wait bank shrink bag=%s:%s count=%s before=%s ticks=%d",
                    tostring(a.bag), tostring(a.slot), bankCount, before, a.splitReadyWaitTicks)
                return false
            end
            Dbg("merge", "split-pull bank never shrank bag=%s:%s — split_failed", tostring(a.bag), tostring(a.slot))
            FinishAction({ ok = false, moved = 0, reason = "split_failed", hardFail = false })
            return true
        end
    end
    if isSlotLocked(mb, ms) then
        Dbg("merge", "split-pull wait bag unlock target=%s:%s", mb, ms)
        return false
    end
    local before = bagSlotCount(inv, mb, ms)
    inv.PickupContainerItem(mb, ms)
    if CursorHasItem() then
        return false
    end
    local after = bagSlotCount(inv, mb, ms)
    local gain = math.max(0, after - before)
    local cap = tonumber(a.amount) or 0
    if gain <= 0 then
        a.mergePlaceWaitTicks = (a.mergePlaceWaitTicks or 0) + 1
        if a.mergePlaceWaitTicks < MERGE_PLACE_GAIN_WAIT then
            Dbg("merge", "split-pull wait gain target=%s:%s before=%s after=%s ticks=%d",
                mb, ms, before, after, a.mergePlaceWaitTicks)
            return false
        end
        Dbg("merge", "split-pull no gain target=%s:%s — merge_place_failed", mb, ms)
        FinishAction({ ok = false, moved = 0, reason = "merge_place_failed" })
        return true
    end
    local moved = math.min(gain, cap > 0 and cap or gain)
    local d = _G.FluxBankRestockDebug
    if d and d.PrintImportant then
        d.PrintImportant("merge", "split-pull complete target=%s:%s moved=%s gain=%s",
            mb, ms, moved, gain)
    else
        Dbg("merge", "split-pull complete target=%s:%s moved=%s gain=%s",
            mb, ms, moved, gain)
    end
    FinishAction({ ok = true, moved = moved, wasSplit = true })
    return true
end

--- Called from the ITEM_UNLOCKED handler when a bank slot unlocks.
function Mover.NotePendingBankUnlocked(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not action or not bag or tonumber(action.bag) ~= bag then
        return
    end
    if slot and tonumber(action.slot) ~= slot then
        return
    end
    action.bankUnlocked = true
    if bankUnlockDepth > 0 then
        return
    end
    bankUnlockDepth = bankUnlockDepth + 1
    Dbg("mover", "bank unlocked bag=%s:%s", tostring(bag), tostring(slot or action.slot))
    if action.stepMode == "merge" then
        if action.tailMerge then
            if CursorHasItem() then
                action.tailSettleTicks = 2
            end
            if ProcessAction then
                ProcessAction()
            end
            bankUnlockDepth = math.max(0, bankUnlockDepth - 1)
            return
        end
        if CursorHasItem() then
            action.mergePullDone = true
            if action.splitIssued or action.execKind == "split_merge" then
                action.mergeSplitPull = action.execKind ~= "whole_merge"
            end
            if stampCursorAmount then
                stampCursorAmount(action)
            end
        end
        local inv = GetInv()
        if tryCompleteMergeSplitPull(action, inv) then
            bankUnlockDepth = math.max(0, bankUnlockDepth - 1)
            return
        end
        if bankSplitInFlight(action, GetInv(), bag, slot) and not CursorHasItem() then
            bankUnlockDepth = math.max(0, bankUnlockDepth - 1)
            return
        end
    end
    if ProcessAction then
        ProcessAction()
    end
    bankUnlockDepth = math.max(0, bankUnlockDepth - 1)
end

--- Called from the UI_ERROR handler when the server rejects a split.
function Mover.NoteSplitRejected()
    if not action then
        return
    end
    local a = action
    local cur = Mover.GetCursorItemCount()
    local want = math.floor(tonumber(a.amount) or 0)
    -- Oversize cursor after split rejection: never place — return/clear.
    if CursorHasItem() and want > 0 and cur ~= want then
        Dbg("mover", "split UI_ERROR oversize cursor=%s want=%s — abort", cur, want)
        local inv = GetInv()
        if inv and a.bag and a.slot then
            inv.PickupContainerItem(a.bag, a.slot)
        end
        if CursorHasItem() then
            Mover.ClearCursor()
        end
        FinishAction({ ok = false, moved = 0, reason = "oversize_cursor", hardFail = false })
        return
    end
    if CursorHasItem() then
        Dbg("mover", "split UI_ERROR ignored — cursor already holds stack")
        a.splitRejected = false
        a.mergePullDone = true
        a.splitIssued = true
        a.phase = "resolve"
        if ProcessAction then
            ProcessAction()
        end
        return
    end
    local inv = GetInv()
    if inv and a.bag and a.slot and a.splitCountBefore then
        local count = bagSlotCount(inv, a.bag, a.slot)
        if count < a.splitCountBefore then
            Dbg("mover", "split UI_ERROR ignored — bank stack shrank to %s", count)
            a.splitRejected = false
            a.phase = "resolve"
            if ProcessAction then
                ProcessAction()
            end
            return
        end
    end
    if a.tailMerge then
        a.tailPullAttempted = false
        a.splitRejected = false
        local amt = tonumber(a.amount) or 0
        if not a.tailStagingTried and inv and a.bag and a.slot then
            local countBefore = bagSlotCount(inv, a.bag, a.slot)
            if tryTsmStagingFromBank(
                inv, a.bag, a.slot, amt, a.itemID, a.tierKind, countBefore, a, true) then
                a.tailStagingTried = true
                a.tailMerge = false
                a.phase = "resolve"
                Dbg("mover", "tail merge UI_ERROR — atomic staging amt=%s", tostring(amt))
                if ProcessAction then
                    ProcessAction()
                end
                return
            end
        end
        Dbg("mover", "tail merge UI_ERROR — resume poll amt=%s", tostring(amt))
        a.phase = "resolve"
        if ProcessAction then
            ProcessAction()
        end
        return
    end
    local amt = tonumber(a.amount) or 0
    if a.stepMode == "merge" and not a.mergeStaging then
        local countBefore = bagSlotCount(inv, a.bag, a.slot)
        local tryStaging = true
        if a.itemNoSplit or a.execKind == "whole_merge" then
            local room = liveMergeRoom(inv, a.mergeBag, a.mergeSlot, a.realMaxStack or 20)
            if countBefore > amt and (room <= 0 or countBefore > room) then
                tryStaging = false
            end
        end
        if tryStaging and tryTsmStagingFromBank(
            inv, a.bag, a.slot, amt, a.itemID, a.tierKind, countBefore, a, true) then
            a.splitRejected = false
            a.overlayRetryUsed = true
            a.mergePullStarted = true
            local d = _G.FluxBankRestockDebug
            if d and d.Print then
                d.Print("mover", "split UI_ERROR — atomic staging amt=%s", tostring(amt))
            end
            a.phase = "resolve"
            if ProcessAction then
                ProcessAction()
            end
            return
        end
    end
    if a.stepMode == "merge" and isOverlaySafeMerge(a, inv) and not a.overlayRetryUsed then
        a.overlayRetryUsed = true
        resetMergeForOverlayRetry(a)
        local d = _G.FluxBankRestockDebug
        if d and d.Print then
            d.Print("mover", "split UI_ERROR — retry overlay merge amt=%s", tostring(amt))
        end
        if ProcessAction then
            ProcessAction()
        end
        return
    end
    if a.stepMode == "merge" and not a.mergeStaging then
        local countBefore = bagSlotCount(inv, a.bag, a.slot)
        local tryStaging = true
        if a.itemNoSplit or a.execKind == "whole_merge" then
            local room = liveMergeRoom(inv, a.mergeBag, a.mergeSlot, a.realMaxStack or 20)
            if countBefore > amt and (room <= 0 or countBefore > room) then
                tryStaging = false
            end
        end
        if tryStaging and tryTsmStagingFromBank(inv, a.bag, a.slot, amt, a.itemID, a.tierKind, countBefore, a) then
            a.splitRejected = false
            a.overlayRetryUsed = true
            local d = _G.FluxBankRestockDebug
            if d and d.Print then
                d.Print("mover", "split UI_ERROR — retry TSM staging amt=%s", tostring(amt))
            end
            a.phase = "resolve"
            if ProcessAction then
                ProcessAction()
            end
            return
        end
    end
    if a.stepMode == "merge" and amt > 1 and not a.microSplitFallback then
        local br = _G.FluxBankRestock
        local itemNoSplit = a.itemNoSplit or a.execKind == "whole_merge"
        if not itemNoSplit and br and br.IsNoSplit and a.itemID then
            itemNoSplit = br.IsNoSplit({ itemID = a.itemID }) == true
        end
        if not itemNoSplit then
            a.microSplitFallback = true
            a.amount = 1
            a.mustSplit = true
            a.splitIssued = false
            a.splitRejected = false
            a.splitCountBefore = nil
            a.bankUnlocked = false
            a.mergePullDone = false
            a.mergePullStarted = false
            a.phase = "resolve"
            a.ticks = 0
            a.stuckTicks = 0
            a.asyncWaitTicks = 0
            a.lockWaitTicks = 0
            a.pullWaitTicks = 0
            a.cursorAmount = nil
            local d = _G.FluxBankRestockDebug
            if d and d.Print then
                d.Print("mover", "bulk split rejected — retry micro-split amt=1 (was %s)", tostring(amt))
            end
            if ProcessAction then
                ProcessAction()
            end
            return
        end
    end
    a.splitRejected = true
    local br = _G.FluxBankRestock
    if br and br.MarkSplitFailed and a.bag and a.slot then
        br.MarkSplitFailed({
            bag = a.bag,
            slot = a.slot,
            itemID = a.itemID,
        }, false, true)
    end
    if ProcessAction then
        ProcessAction()
    end
end

function Mover.NudgeTailMerge(bag, slot)
    if not action or not action.tailMerge then
        return
    end
    bag = tonumber(bag)
    slot = tonumber(slot)
    if bag and slot and tonumber(action.mergeBag) == bag and tonumber(action.mergeSlot) == slot then
        action.tailSettleTicks = 2
    end
    if ProcessAction then
        ProcessAction()
    end
end

function Mover.IsActionActive()
    return action ~= nil
end

function Mover.HasInFlightAction()
    return action ~= nil
end

--- Abort the in-flight action without crediting anything (manual cursor / stop).
function Mover.CancelAction()
    local a = action
    if a then
        local inv = GetInv()
        if a.stepMode == "merge" and CursorHasItem() and inv
            and a.mergeBag and a.mergeSlot then
            if a.mergeSplitPull and tryCompleteMergeSplitPull(a, inv) then
                return
            end
            if bankSplitReadyForMerge(a, inv) then
                pcall(PollAction)
            end
        end
        if a.mergeStaging and inv then
            cleanupMergeStagingState(a, inv)
        end
        if mergePlaceMode(a.stepMode) and CursorHasItem() and inv then
            if a.bag and a.slot and IsBankBag(a.bag) then
                tryReturnCursorToSlot(inv, a.bag, a.slot)
            end
            if CursorHasItem() then
                Mover.ClearCursor()
            end
        end
    end
    action = nil
end

--- Run one full action tick (start + resolve). Safe to call from PlanExecutor.
function Mover.ProcessActionTick()
    if action and ProcessAction then
        pcall(ProcessAction)
        return true
    end
    return false
end

--- Run poll ticks for the in-flight action (e.g. before session teardown).
function Mover.FlushAction()
    if not action then
        return
    end
    local inv = GetInv()
    if action.stepMode == "merge" and action.mergeSplitPull and CursorHasItem() then
        if tryCompleteMergeSplitPull(action, inv) then
            return
        end
    end
    for _ = 1, 4 do
        if not action then
            break
        end
        if ProcessAction then
            pcall(ProcessAction)
        elseif PollAction then
            pcall(PollAction)
        end
    end
end

stampCursorAmount = function(a)
    -- Never stamp-cap below live cursor count: oversize after a failed split
    -- must remain visible so callers abort instead of placing a full stack.
    local cur = Mover.GetCursorItemCount()
    if cur <= 0 then
        local cap = tonumber(a.amount) or 0
        cur = cap > 0 and cap or 1
    end
    a.cursorAmount = cur
end

local function effectiveCursorAmount(a)
    local live = Mover.GetCursorItemCount()
    if live > 0 then
        return live
    end
    local stamped = a and tonumber(a.cursorAmount) or 0
    if stamped > 0 then
        return stamped
    end
    local cap = tonumber(a and a.amount) or 0
    return math.max(1, cap)
end

local function resolveCredit(a, placed, mergeGain)
    placed = tonumber(placed) or 0
    mergeGain = tonumber(mergeGain) or 0
    local cap = tonumber(a.amount) or 0
    if mergeGain > 0 then
        return math.min(mergeGain, cap > 0 and cap or mergeGain)
    end
    if placed > 0 then
        local curAmt = tonumber(a.cursorAmount) or placed
        local credit = math.max(placed, curAmt)
        if cap > 0 then
            credit = math.min(credit, cap)
        end
        return credit
    end
    return 0
end

local function refreshMergeTarget(a)
    local inv = GetInv()
    if not inv then
        return
    end
    local maxStack = tonumber(a.realMaxStack) or 20
    local mb = tonumber(a.mergeBag)
    local ms = tonumber(a.mergeSlot)
    if mb and ms then
        local room = liveMergeRoom(inv, mb, ms, maxStack)
        if room > 0 then
            a.mergeBag, a.mergeSlot = mb, ms
            return
        end
    end
    local bagIDs = inv.GetBagContainerIDs and inv.GetBagContainerIDs()
    local mergeBag, mergeSlot, mergeRoom = Mover.GetBestMergeTarget(
        bagIDs, tonumber(a.itemID), tonumber(a.amount) or 0, maxStack, a.tierKind)
    if mergeBag and mergeSlot and mergeRoom > 0 then
        a.mergeBag, a.mergeSlot = mergeBag, mergeSlot
        Dbg("merge", "refresh merge target %s:%s room=%s", mergeBag, mergeSlot, mergeRoom)
    else
        a.mergeBag, a.mergeSlot = nil, nil
        Dbg("merge", "refresh merge target none")
    end
end

local function tryPlaceCursor(a)
    if not CursorHasItem() then
        return 0
    end
    local inv = GetInv()
    local mergeBefore = 0
    if a.mergeBag and a.mergeSlot and inv then
        mergeBefore = bagSlotCount(inv, a.mergeBag, a.mergeSlot)
    end
    local placeAmt = effectiveCursorAmount(a)
    local placed = false

    local mb = tonumber(a.mergeBag)
    local ms = tonumber(a.mergeSlot)
    if mb and ms and inv then
        local room = liveMergeRoom(inv, mb, ms, a.realMaxStack or 20)
        if room > 0 then
            local want = tonumber(a.amount) or placeAmt
            if mergePlaceMode(a.stepMode) and routeOversizeMergeCursor(a, inv, want, room) then
                return 0
            end
            local gain = tryPartialMergeIntoSlot(inv, mb, ms, a.itemID, a.tierKind)
            if gain > 0 then
                local cap = math.min(room, tonumber(a.amount) or gain)
                gain = math.min(gain, cap)
                Dbg("merge", "cursor merge gain=%s room=%s cap=%s target=%s:%s mode=%s",
                    gain, room, cap, mb, ms, tostring(a.stepMode))
                if gain <= 0 then
                    return 0
                end
                if CursorHasItem() and a.bag and a.slot and IsBankBag(a.bag) then
                    tryReturnCursorToSlot(inv, a.bag, a.slot)
                end
                if not CursorHasItem() then
                    return gain
                end
                return gain
            end
            if mergePlaceMode(a.stepMode) then
                Dbg("merge", "overlay merge no gain room=%s target=%s:%s", room, mb, ms)
            end
        elseif mergePlaceMode(a.stepMode) then
            Dbg("merge", "merge target full %s:%s — refresh", mb, ms)
        end
    end

    placed = Mover.PutItemInPlayerBag(
        a.itemID, placeAmt, a.realMaxStack, a.tierKind, a.mergeBag, a.mergeSlot)

    if placed and not CursorHasItem() then
        if a.mergeBag and a.mergeSlot and inv then
            local mergeAfter = bagSlotCount(inv, a.mergeBag, a.mergeSlot)
            local gain = math.max(0, mergeAfter - mergeBefore)
            if gain > 0 then
                Dbg("merge", "tryPlace mergeGain=%s placeAmt=%s", gain, placeAmt)
                return math.min(gain, tonumber(a.amount) or gain)
            end
            if mergePlaceMode(a.stepMode) then
                Dbg("merge", "tryPlace cursor cleared without merge gain=%s placeAmt=%s", gain, placeAmt)
                return 0
            end
        end
        Dbg("mover", "tryPlace onCursor=%s credit=%s", placeAmt, placeAmt)
        return resolveCredit(a, placeAmt, 0)
    end
    return 0
end

--- Restocker-style tail fill: split exactly `want` from bank, merge onto partial bag stack.
--- One bank pull per action; credit from verified merge-target gain only.
local function tailMergeImportant(fmt, ...)
    local d = _G.FluxBankRestockDebug
    if d and d.PrintImportant then
        d.PrintImportant("merge", fmt, ...)
    else
        Dbg("merge", fmt, ...)
    end
end

local TAIL_SPLIT_SETTLE_TICKS = 2

local function runTailBankMerge(a, inv)
    -- Bank restock live path is FluxBankRestockMoveExec (TSM-style split+place).
    -- tail_merge remains only for any legacy SubmitAction callers; prefer retiring.
    if not a or not inv then
        return
    end
    local bag, slot = tonumber(a.bag), tonumber(a.slot)
    local mb, ms = tonumber(a.mergeBag), tonumber(a.mergeSlot)
    local maxStack = tonumber(a.realMaxStack) or 20
    local want = math.floor(tonumber(a.amount) or 0)
    if not bag or not slot or not mb or not ms or want <= 0 then
        FinishAction({ ok = false, moved = 0, reason = "unresolved" })
        return
    end
    if not IsBankBag(bag) then
        tailMergeImportant("tail merge blocked non-bank source %s:%s", bag, slot)
        FinishAction({ ok = false, moved = 0, reason = "aborted" })
        return
    end

    -- Phase 2: cursor held after bank pull — merge onto the partial player-bag stack.
    if CursorHasItem() then
        a.tailPullAttempted = true
        a.tailSettleTicks = (a.tailSettleTicks or 0) + 1
        if a.tailSettleTicks < TAIL_SPLIT_SETTLE_TICKS then
            return
        end
        local before = bagSlotCount(inv, mb, ms)
        local curAmt = Mover.GetCursorItemCount()
        tailMergeImportant("tail merge place cursor=%s onto %s:%s before=%s want=%s",
            curAmt, mb, ms, before, want)
        local gain = tryPartialMergeIntoSlot(inv, mb, ms, a.itemID, a.tierKind)
        if gain <= 0 then
            inv.PickupContainerItem(mb, ms)
            if CursorHasItem() then
                a.stuckTicks = (a.stuckTicks or 0) + 1
                if a.stuckTicks >= MERGE_CURSOR_STUCK_LIMIT then
                    FinishAction({ ok = false, moved = 0, reason = "merge_place_failed" })
                end
                return
            end
            gain = math.max(0, bagSlotCount(inv, mb, ms) - before)
        end
        gain = math.min(gain, want)
        if gain <= 0 then
            a.stuckTicks = (a.stuckTicks or 0) + 1
            if a.stuckTicks >= MERGE_PLACE_GAIN_WAIT then
                FinishAction({ ok = false, moved = 0, reason = "merge_place_failed" })
            end
            return
        end
        if CursorHasItem() and IsBankBag(bag) then
            tryReturnCursorToSlot(inv, bag, slot)
        end
        tailMergeImportant("tail merge done gain=%s target=%s:%s wasSplit=%s",
            gain, mb, ms, a.tailWasSplit and "Y" or "N")
        FinishAction({ ok = true, moved = gain, wasSplit = a.tailWasSplit == true })
        return
    end

    -- Phase 1b: waiting for async bank split to land on cursor.
    if a.tailPullAttempted then
        if inv.SplitContainerItemPending and a.splitCountBefore
            and inv.SplitContainerItemPending(bag, slot, a.splitCountBefore, want) then
            Dbg("merge", "tail merge split pending bank=%s:%s want=%s", bag, slot, want)
            return
        end
        a.pullWaitTicks = (a.pullWaitTicks or 0) + 1
        if a.pullWaitTicks < SPLIT_ASYNC_WAIT_LIMIT then
            return
        end
        local beforeM = tonumber(a.mergeSlotBefore)
        if beforeM and mb and ms then
            local asyncGain = bagSlotCount(inv, mb, ms) - beforeM
            if asyncGain > 0 then
                asyncGain = math.min(asyncGain, want)
                tailMergeImportant("tail merge async gain=%s target=%s:%s", asyncGain, mb, ms)
                FinishAction({ ok = true, moved = asyncGain, wasSplit = a.tailWasSplit == true })
                return
            end
        end
        tailMergeImportant("tail merge split timeout bank=%s:%s want=%s", bag, slot, want)
        FinishAction({ ok = false, moved = 0, reason = "split_failed", hardFail = false })
        return
    end

    -- Phase 1a: issue one bank pull (split or whole pickup).
    local info = inv.GetContainerItemInfo(bag, slot)
    if not info or (info.count or 0) <= 0 then
        FinishAction({ ok = false, moved = 0, reason = "slot_gone" })
        return
    end
    local bankCount = info.count or 0
    local room = liveMergeRoom(inv, mb, ms, maxStack)
    want = math.min(want, room)
    a.amount = want
    if want <= 0 then
        FinishAction({ ok = false, moved = 0, reason = "no_room" })
        return
    end

    if info.locked or isSlotLocked(bag, slot) then
        a.lockWaitTicks = (a.lockWaitTicks or 0) + 1
        if a.lockWaitTicks < SPLIT_WAIT_LIMIT then
            return
        end
        FinishAction({ ok = false, moved = 0, reason = "locked" })
        return
    end

    a.tailPullAttempted = true
    a.splitCountBefore = bankCount
    a.tailWasSplit = bankCount > want
    a.splitIssued = a.tailWasSplit
    a.tailSettleTicks = 0
    a.mergeSlotBefore = bagSlotCount(inv, mb, ms)

    if bankCount <= want then
        tailMergeImportant("tail merge whole pickup bank=%s:%s count=%s want=%s",
            bag, slot, bankCount, want)
        inv.PickupContainerItem(bag, slot)
        return
    end

    tailMergeImportant("tail merge split bank=%s:%s count=%s want=%s -> %s:%s",
        bag, slot, bankCount, want, mb, ms)
    if not inv.SplitContainerItem(bag, slot, want) then
        tailMergeImportant("tail merge split blocked bank=%s:%s want=%s count=%s",
            bag, slot, want, bankCount)
        if not a.tailStagingTried
            and tryTsmStagingFromBank(inv, bag, slot, want, a.itemID, a.tierKind, bankCount, a, true) then
            a.tailStagingTried = true
            a.tailMerge = false
            a.tailPullAttempted = false
            a.phase = "resolve"
            return
        end
        FinishAction({ ok = false, moved = 0, reason = "split_failed", hardFail = false })
        return
    end
end

local function BeginAction(a)
    local inv = GetInv()

    if a.execKind == "charge" or a.stepMode == "charge" then
        local moved = Mover.MoveWholeStack(a.bag, a.slot) or 0
        if moved > 0 then
            local credit = tonumber(a.chargeCredit) or moved
            moved = math.min(moved, credit, tonumber(a.amount) or moved)
            return FinishAction({ ok = true, moved = moved })
        end
        return FinishAction({ ok = false, moved = 0, reason = "execute_failed" })
    end

    if a.execKind == "bag_consolidate" or a.stepMode == "bag_consolidate" then
        local fromBag, fromSlot = tonumber(a.bag), tonumber(a.slot)
        local toBag, toSlot = tonumber(a.mergeBag), tonumber(a.mergeSlot)
        if not fromBag or not fromSlot or not toBag or not toSlot then
            return FinishAction({ ok = false, moved = 0, reason = "unresolved" })
        end
        local fromInfo = inv and inv.GetContainerItemInfo(fromBag, fromSlot)
        local toInfo = inv and inv.GetContainerItemInfo(toBag, toSlot)
        if not fromInfo or not toInfo or fromInfo.locked or toInfo.locked then
            return FinishAction({ ok = false, moved = 0, reason = "locked" })
        end
        if isSlotLocked(fromBag, fromSlot) or isSlotLocked(toBag, toSlot) then
            return FinishAction({ ok = false, moved = 0, reason = "locked" })
        end
        local liveCount = fromInfo.count or 0
        local itemID = tonumber(a.itemID) or fromInfo.itemID
        local maxStack = tonumber(a.realMaxStack) or GetStackMaxForItem(itemID, 20)
        local room = maxStack - (toInfo.count or 0)
        local amount = math.min(tonumber(a.amount) or 0, liveCount, room)
        if amount <= 0 then
            return FinishAction({ ok = false, moved = 0, reason = "no_room" })
        end
        if not Mover.ItemsCanMerge(toInfo.itemID, itemID, a.tierKind) then
            return FinishAction({ ok = false, moved = 0, reason = "aborted" })
        end
        local mustSplit = amount < liveCount
        if mustSplit and not IsSlotSplittable(fromBag, fromSlot, amount) then
            return FinishAction({ ok = false, moved = 0, reason = "locked" })
        end
        a.amount = amount
        a.mustSplit = mustSplit
        a.splitCountBefore = liveCount
        a.itemID = itemID
        stampActionBaselines(a, inv)

        Dbg("exec", "begin bag_consolidate from=%s:%s to=%s:%s amt=%s mustSplit=%s",
            fromBag, fromSlot, toBag, toSlot, amount, mustSplit and "Y" or "N")

        local moved = MovePlayerBagToMerge(
            fromBag, fromSlot, toBag, toSlot, amount, itemID, maxStack, a.tierKind) or 0
        if moved > 0 and not CursorHasItem() then
            return FinishAction({ ok = true, moved = math.min(moved, amount), wasSplit = mustSplit })
        end
        if moved == 0 and not CursorHasItem() and not mustSplit then
            return FinishAction({ ok = false, moved = 0, reason = "execute_failed" })
        end
        a.splitIssued = mustSplit
        a.phase = "resolve"
        PollAction()
        return
    end

    if a.execKind == "split_merge" and a.stepMode == "merge" then
        refreshMergeTarget(a)
        local bag, slot = tonumber(a.bag), tonumber(a.slot)
        if not bag or not slot then
            FinishAction({ ok = false, moved = 0, reason = "unresolved" })
            return
        end
        if not a.mergeBag or not a.mergeSlot then
            FinishAction({ ok = false, moved = 0, reason = "no_room" })
            return
        end
        a.tailMerge = true
        a.tailPullAttempted = false
        a.tailWasSplit = false
        a.tailStagingTried = false
        a.phase = "resolve"
        stampActionBaselines(a, inv)
        tailMergeImportant("tail_merge begin bank=%s:%s want=%s target=%s:%s",
            bag, slot, tostring(a.amount), tostring(a.mergeBag), tostring(a.mergeSlot))
        runTailBankMerge(a, inv)
        return
    end

    local bag, slot = tonumber(a.bag), tonumber(a.slot)
    if not bag or not slot then
        return FinishAction({ ok = false, moved = 0, reason = "unresolved" })
    end
    if CursorHasItem() and a.stepMode == "merge" and a.mergeBag and a.mergeSlot then
        stampActionBaselines(a, inv)
        a.mergePullDone = true
        a.splitIssued = true
        a.phase = "resolve"
        PollAction()
        return
    end
    local info = inv and inv.GetContainerItemInfo(bag, slot)
    if not info or (info.count or 0) <= 0 then
        return FinishAction({ ok = false, moved = 0, reason = "slot_gone" })
    end
    local liveCount = info.count or 0
    local amount = math.min(tonumber(a.amount) or 0, liveCount)
    if amount <= 0 then
        return FinishAction({ ok = false, moved = 0, reason = "slot_gone" })
    end

    if a.stepMode == "merge" or a.execKind == "split_merge" then
        refreshMergeTarget(a)
    end
    local itemID = tonumber(a.itemID) or info.itemID
    local maxStack = tonumber(a.realMaxStack) or 20
    local tierKind = a.tierKind
    local mergeBag, mergeSlot = nil, nil
    if a.stepMode == "merge" and a.mergeBag and a.mergeSlot then
        local room = liveMergeRoom(inv, a.mergeBag, a.mergeSlot, maxStack)
        if room <= 0 then
            return FinishAction({ ok = false, moved = 0, reason = "no_room" })
        end
        amount = math.min(amount, room)
        if amount <= 0 then
            return FinishAction({ ok = false, moved = 0, reason = "no_room" })
        end
        mergeBag, mergeSlot = a.mergeBag, a.mergeSlot
    end

    local mustSplit = amount < liveCount and a.stepMode ~= "merge"
    if a.stepMode == "merge" and mergeBag and mergeSlot then
        a.mergeOverlay = liveCount <= amount
    end
    if mustSplit and not IsSlotSplittable(bag, slot, amount) then
        return FinishAction({ ok = false, moved = 0, reason = "locked" })
    end

    a.amount = amount
    a.mustSplit = mustSplit
    a.splitCountBefore = liveCount
    stampActionBaselines(a, inv)

    if info.locked or isSlotLocked(bag, slot) then
        if a.stepMode == "merge" and mergeBag then
            Dbg("mover", "merge bank locked — wait unlock bag=%s:%s", bag, slot)
            a.phase = "resolve"
            PollAction()
            return
        end
        return FinishAction({ ok = false, moved = 0, reason = "locked" })
    end

    Dbg("exec", "begin action bag=%s:%s liveCount=%s amount=%s mustSplit=%s mode=%s exec=%s merge=%s:%s",
        bag, slot, liveCount, amount, mustSplit and "Y" or "N", a.stepMode,
        tostring(a.execKind), tostring(mergeBag or "-"), tostring(mergeSlot or "-"))

    local moved = MoveFromBankToPlayer(
        bag, slot, amount, itemID, maxStack, tierKind, mergeBag, mergeSlot) or 0
    if a.mergeNoViable then
        return FinishAction({ ok = false, moved = 0, reason = "merge_no_supply", hardFail = false })
    end
    if a.stepMode == "merge" and mergeBag then
        a.mergePullStarted = true
    end

    if moved > 0 and not CursorHasItem() then
        local wasSplit = mustSplit or a.mergeSplitPull or a.splitIssued
        return FinishAction({ ok = true, moved = math.min(moved, amount), wasSplit = wasSplit })
    end

    if moved == 0 and not CursorHasItem() and not mustSplit and not mergeBag then
        -- Whole-stack attempt failed outright (no split issued, nothing pending).
        return FinishAction({ ok = false, moved = 0, reason = "execute_failed" })
    end

    if CursorHasItem() and a.stepMode == "merge" then
        a.mergePullDone = true
        if not a.mergeStaging then
            a.splitIssued = true
            stampCursorAmount(a)
        end
        if a.mergeBag and a.mergeSlot then
            local placed = tryPlaceCursor(a)
            if placed > 0 and not CursorHasItem() then
                local wasSplit = mustSplit or a.mergeSplitPull or a.splitIssued
                return FinishAction({ ok = true, moved = math.min(placed, amount), wasSplit = wasSplit })
            end
        end
    end

    if not a.mergeStaging then
        a.splitIssued = a.splitIssued or mustSplit
    end
    a.phase = "resolve"
    PollAction()
end

--- Pull a partial amount from bank for merge mode (split or overlay). Returns
--- true when the pull phase is done or in progress; false when waiting.
local function tryIssueMergeBankPull(a, inv)
    if not a or a.stepMode ~= "merge" or not a.mergeBag or not a.mergeSlot then
        return false
    end
    if a.mergePullDone or CursorHasItem() then
        return CursorHasItem()
    end
    if a.mergePullStarted then
        return false
    end
    if a.splitRejected then
        return false
    end
    local bag, slot = tonumber(a.bag), tonumber(a.slot)
    if not bag or not slot or not inv then
        return false
    end
    if bankSplitInFlight(a, inv, bag, slot) then
        return false
    end
    if isSlotLocked(bag, slot) then
        return false
    end
    a.mergePullStarted = true
    local moved = MoveFromBankToPlayer(
        bag, slot, a.amount, a.itemID, a.realMaxStack, a.tierKind, a.mergeBag, a.mergeSlot) or 0
    if moved > 0 and not CursorHasItem() then
        a.mergePullDone = true
        FinishAction({ ok = true, moved = math.min(moved, tonumber(a.amount) or moved) })
        return true
    end
    if CursorHasItem() then
        a.mergePullDone = true
        a.splitIssued = true
        stampCursorAmount(a)
        Dbg("mover", "merge bank pull cursor amt=%s", tostring(a.amount))
        return true
    end
    return false
end

local function cleanupMergeStagingState(a, inv)
    if not a or not a.mergeStaging or not inv then
        return
    end
    local bankBag = tonumber(a.bag)
    local bankSlot = tonumber(a.slot)
    local stagingBag = tonumber(a.stagingBag)
    local stagingSlot = tonumber(a.stagingSlot)
    if CursorHasItem() and bankBag and bankSlot and IsBankBag(bankBag) then
        tryReturnCursorToSlot(inv, bankBag, bankSlot)
    end
    if stagingBag and stagingSlot and stagingSlotCount(inv, stagingBag, stagingSlot) > 0 then
        if not CursorHasItem() and not isSlotLocked(stagingBag, stagingSlot) then
            inv.PickupContainerItem(stagingBag, stagingSlot)
        end
        if CursorHasItem() and bankBag and bankSlot then
            tryReturnCursorToSlot(inv, bankBag, bankSlot)
        end
    end
    a.mergeStaging = false
    a.stagingPhase = nil
end

local function finishMergeStaging(a, inv, moved)
    moved = tonumber(moved) or 0
    if a then
        a.mergeStaging = false
        a.stagingPhase = nil
    end
    if moved > 0 then
        return FinishAction({ ok = true, moved = moved, wasSplit = true })
    end
    cleanupMergeStagingState(a, inv)
    return FinishAction({ ok = false, moved = 0, reason = "split_failed", hardFail = true })
end

local function routeOversizeMergeCursor(a, inv, want, room)
    want = tonumber(want) or 0
    room = tonumber(room) or 0
    if want <= 0 or not inv or not CursorHasItem() then
        return false
    end
    local curAmt = Mover.GetCursorItemCount()
    local mergeCap = room > 0 and math.min(want, room) or want
    if curAmt <= mergeCap then
        return false
    end
    if not a.mergeStaging then
        local sb, ss = findMergeStagingSlot(inv, a.itemID, a.tierKind)
        if sb and ss and not inv.GetContainerItemInfo(sb, ss) then
            beginMergeStaging(a, sb, ss)
            a.stagingPhase = "deposit"
            Dbg("merge", "cursor %s > cap %s — route to staging %s:%s",
                curAmt, mergeCap, sb, ss)
            return true
        end
    elseif a.stagingPhase ~= "deposit" and a.stagingPhase ~= "return_bank" then
        a.stagingPhase = "deposit"
        return true
    end
    if a.bag and a.slot and IsBankBag(a.bag) and tryReturnCursorToSlot(inv, a.bag, a.slot) then
        Dbg("merge", "cursor overshoot returned to bank cur=%s want=%s", curAmt, want)
        return true
    end
    return true
end

local function pollMergeStaging(a, inv)
    if not a or not a.mergeStaging or a.stepMode ~= "merge" then
        return false
    end
    local stagingBag = tonumber(a.stagingBag)
    local stagingSlot = tonumber(a.stagingSlot)
    local bankBag = tonumber(a.bag)
    local bankSlot = tonumber(a.slot)
    if not stagingBag or not stagingSlot or not bankBag or not bankSlot or not inv then
        finishMergeStaging(a, inv, 0)
        return true
    end

    local phase = a.stagingPhase or "deposit"
    local want = tonumber(a.amount) or 0

    if phase == "deposit" then
        if CursorHasItem() then
            local cur = Mover.GetCursorItemCount()
            if want > 0 and cur > want then
                if a.bag and a.slot and IsBankBag(a.bag) and tryReturnCursorToSlot(inv, a.bag, a.slot) then
                    a.pullWaitTicks = 0
                    return true
                end
                Dbg("merge", "staging deposit blocked cur=%s want=%s", cur, want)
                return true
            end
            if isSlotLocked(stagingBag, stagingSlot) then
                return true
            end
            inv.PickupContainerItem(stagingBag, stagingSlot)
            if not CursorHasItem() then
                a.stagingPhase = "merge_from_staging"
                refreshMergeTarget(a)
            end
            return true
        end
        if stagingSlotCount(inv, stagingBag, stagingSlot) > 0 then
            a.stagingPhase = "merge_from_staging"
            refreshMergeTarget(a)
            return true
        end
        a.pullWaitTicks = (a.pullWaitTicks or 0) + 1
        if a.pullWaitTicks >= STAGING_WAIT_LIMIT then
            finishMergeStaging(a, inv, 0)
        end
        return true
    end

    if phase == "merge_from_staging" then
        if CursorHasItem() then
            a.stagingPhase = "merge_place"
            stampCursorAmount(a)
            return false
        end
        local staged = stagingSlotCount(inv, stagingBag, stagingSlot)
        if staged <= 0 then
            local credited = tonumber(a.stagingCredited) or 0
            if credited > 0 then
                a.stagingPhase = "return_bank"
            else
                finishMergeStaging(a, inv, 0)
            end
            return true
        end
        refreshMergeTarget(a)
        local mergeBag = tonumber(a.mergeBag)
        local mergeSlot = tonumber(a.mergeSlot)
        if not mergeBag or not mergeSlot then
            finishMergeStaging(a, inv, 0)
            return true
        end
        local room = liveMergeRoom(inv, mergeBag, mergeSlot, a.realMaxStack or 20)
        local mergeAmt = math.min(want, staged, room)
        if (a.itemNoSplit or a.execKind == "whole_merge") and staged > mergeAmt then
            if staged <= room then
                mergeAmt = staged
            else
                finishMergeStaging(a, inv, tonumber(a.stagingCredited) or 0)
                return true
            end
        end
        if mergeAmt <= 0 then
            finishMergeStaging(a, inv, tonumber(a.stagingCredited) or 0)
            return true
        end
        if isSlotLocked(stagingBag, stagingSlot) or isSlotLocked(mergeBag, mergeSlot) then
            return true
        end
        stampActionBaselines(a, inv)
        local beforeMerge = bagSlotCount(inv, mergeBag, mergeSlot)
        local moved = MovePlayerBagToMerge(
            stagingBag, stagingSlot, mergeBag, mergeSlot, mergeAmt,
            a.itemID, a.realMaxStack, a.tierKind) or 0
        if moved > 0 and not CursorHasItem() then
            local gain = bagSlotCount(inv, mergeBag, mergeSlot) - beforeMerge
            gain = math.min(gain > 0 and gain or moved, want)
            a.stagingCredited = (tonumber(a.stagingCredited) or 0) + gain
            if stagingSlotCount(inv, stagingBag, stagingSlot) > 0 then
                a.stagingPhase = "return_bank"
            else
                finishMergeStaging(a, inv, a.stagingCredited)
            end
            return true
        end
        if CursorHasItem() then
            a.stagingPhase = "merge_place"
            a.stagingMergeBefore = beforeMerge
            stampCursorAmount(a)
            return false
        end
        a.stagingPullWait = (a.stagingPullWait or 0) + 1
        if a.stagingPullWait >= SPLIT_ASYNC_WAIT_LIMIT then
            finishMergeStaging(a, inv, tonumber(a.stagingCredited) or 0)
        end
        return true
    end

    if phase == "merge_place" then
        return false
    end

    if phase == "return_bank" then
        if CursorHasItem() then
            if tryReturnCursorToSlot(inv, bankBag, bankSlot) then
                finishMergeStaging(a, inv, tonumber(a.stagingCredited) or 0)
            end
            return true
        end
        if stagingSlotCount(inv, stagingBag, stagingSlot) <= 0 then
            finishMergeStaging(a, inv, tonumber(a.stagingCredited) or 0)
            return true
        end
        if isSlotLocked(stagingBag, stagingSlot) then
            return true
        end
        inv.PickupContainerItem(stagingBag, stagingSlot)
        return true
    end

    return true
end

ProcessAction = function()
    if not action then
        return
    end
    action.ticks = (action.ticks or 0) + 1
    if action.phase == "start" then
        BeginAction(action)
    else
        PollAction()
    end
end

PollAction = function()
    local a = action
    if not a then
        return
    end
    local inv = GetInv()
    local hasCursor = CursorHasItem()
    stampActionBaselines(a, inv)

    if a.tailMerge then
        runTailBankMerge(a, inv)
        return
    end

    if pollMergeStaging(a, inv) then
        return
    end
    hasCursor = CursorHasItem()

    if a.stepMode == "merge" and hasCursor and a.mergeBag and a.mergeSlot then
        if not a.mergePullDone then
            a.mergePullDone = true
            stampCursorAmount(a)
        end
    end

    if a.stepMode == "merge" and a.mergeSplitPull and hasCursor then
        if tryCompleteMergeSplitPull(a, inv) then
            return
        end
    end

    if a.splitRejected then
        if a.stepMode == "merge" and (a.execKind == "whole_merge" or a.itemNoSplit)
            and not a.mergeStaging and inv then
            local countBefore = bagSlotCount(inv, a.bag, a.slot)
            if tryTsmStagingFromBank(inv, a.bag, a.slot, a.amount, a.itemID, a.tierKind, countBefore, a) then
                a.splitRejected = false
                a.overlayRetryUsed = true
                a.phase = "resolve"
                if ProcessAction then
                    ProcessAction()
                end
                return
            end
        end
        if a.stepMode == "merge" and isOverlaySafeMerge(a, inv) and not a.overlayRetryUsed then
            a.overlayRetryUsed = true
            resetMergeForOverlayRetry(a)
            Dbg("mover", "split rejected — retry overlay merge amt=%s", tostring(a.amount))
            return
        end
        local diagInfo = inv and a.bag and a.slot and inv.GetContainerItemInfo(a.bag, a.slot)
        Dbg("mover", "split rejected by client bag=%s:%s link=%s",
            tostring(a.bag), tostring(a.slot), tostring(diagInfo and diagInfo.hyperlink or "?"))
        return FinishAction({
            ok = false,
            moved = 0,
            reason = (a.execKind == "whole_merge" or a.itemNoSplit) and "merge_no_supply" or "split_failed",
            hardFail = false,
            splitRejected = true,
        })
    end

    if a.stepMode == "merge" and a.mergeBag and not a.mergePullDone and not hasCursor then
        if tryIssueMergeBankPull(a, inv) then
            if not action then
                return
            end
            hasCursor = CursorHasItem()
        elseif a.bag and a.slot and isSlotLocked(a.bag, a.slot) then
            a.lockWaitTicks = (a.lockWaitTicks or 0) + 1
            Dbg("mover", "merge wait bank unlock bag=%s:%s ticks=%d",
                tostring(a.bag), tostring(a.slot), a.lockWaitTicks)
            if a.lockWaitTicks < SPLIT_WAIT_LIMIT then
                return
            end
            return FinishAction({ ok = false, moved = 0, reason = "locked", hardFail = false })
        else
            a.pullWaitTicks = (a.pullWaitTicks or 0) + 1
            local pullLimit = a.execKind == "split_merge" and SPLIT_WAIT_LIMIT or SPLIT_ASYNC_WAIT_LIMIT
            if a.pullWaitTicks < pullLimit then
                return
            end
            if not a.microSplitFallback and (tonumber(a.amount) or 0) > 1
                and not a.itemNoSplit and a.execKind ~= "whole_merge" then
                local br = _G.FluxBankRestock
                local itemNoSplit = a.itemNoSplit
                if not itemNoSplit and br and br.IsNoSplit and a.itemID then
                    itemNoSplit = br.IsNoSplit({ itemID = a.itemID }) == true
                end
                if not itemNoSplit then
                a.microSplitFallback = true
                a.amount = 1
                a.pullWaitTicks = 0
                a.mergePullStarted = false
                Dbg("mover", "merge pull stalled — retry micro-split amt=1")
                return
                end
            end
            if isOverlaySafeMerge(a, inv) and not a.overlayRetryUsed then
                a.overlayRetryUsed = true
                resetMergeForOverlayRetry(a)
                Dbg("mover", "merge pull stalled — retry overlay merge amt=%s", tostring(a.amount))
                return
            end
            local failReason = (a.execKind == "whole_merge" or a.itemNoSplit)
                and "merge_no_supply" or "split_failed"
            return FinishAction({ ok = false, moved = 0, reason = failReason, hardFail = false })
        end
    end

    if a.splitIssued then
        local settleLimit = (a.stepMode == "merge") and 0 or SPLIT_SETTLE_TICKS
        if (a.ticks or 0) < settleLimit then
            if a.bag and a.slot and isSlotLocked(a.bag, a.slot) then
                return
            end
            local before = tonumber(a.splitCountBefore) or 0
            local count = bagSlotCount(inv, a.bag, a.slot)
            if before > 1 and count >= before and (a.ticks or 0) >= 2 then
                local stillAsync = inv and inv.SplitContainerItemPending
                    and inv.SplitContainerItemPending(a.bag, a.slot, a.splitCountBefore or 0, a.amount)
                if not stillAsync then
                    if CursorHasItem() and a.stepMode == "merge" then
                        -- split landed on cursor — place merge below
                    elseif isOverlaySafeMerge(a, inv) and not a.overlayRetryUsed then
                        a.overlayRetryUsed = true
                        resetMergeForOverlayRetry(a)
                        Dbg("mover", "async split failed — retry overlay merge amt=%s", tostring(a.amount))
                        return
                    else
                        local failReason = (a.execKind == "whole_merge" or a.itemNoSplit)
                            and "merge_no_supply" or "split_failed"
                        return FinishAction({ ok = false, moved = 0, reason = failReason, hardFail = false })
                    end
                end
            end
            if not (a.stepMode == "merge" and CursorHasItem()) then
                return
            end
        end
    end

    local completed = tryCompleteWithoutCursor(a, inv)
    if completed and completed > 0 and not hasCursor then
        Dbg("mover", "action completed without cursor moved=%s", completed)
        return FinishAction({ ok = true, moved = completed, wasSplit = a.splitIssued or a.mustSplit })
    end

    if not hasCursor then
        local pendingAsync = inv and inv.SplitContainerItemPending
            and a.bag and a.slot
            and inv.SplitContainerItemPending(a.bag, a.slot, a.splitCountBefore or 0, a.amount)
        if pendingAsync then
            a.asyncWaitTicks = (a.asyncWaitTicks or 0) + 1
            Dbg("mover", "async split wait bag=%s:%s ticks=%d/%d",
                tostring(a.bag), tostring(a.slot), a.asyncWaitTicks, SPLIT_ASYNC_WAIT_LIMIT)
            if a.asyncWaitTicks < SPLIT_ASYNC_WAIT_LIMIT then
                return
            end
            completed = tryCompleteWithoutCursor(a, inv)
            if completed and completed > 0 then
                return FinishAction({ ok = true, moved = completed, wasSplit = a.splitIssued or a.mustSplit })
            end
        end
        if a.bag and a.slot and isSlotLocked(a.bag, a.slot) then
            a.lockWaitTicks = (a.lockWaitTicks or 0) + 1
            Dbg("mover", "bank slot locked bag=%s:%s lockW=%d",
                tostring(a.bag), tostring(a.slot), a.lockWaitTicks)
            if a.lockWaitTicks < SPLIT_ASYNC_WAIT_LIMIT then
                return
            end
        end
        if a.splitIssued and a.bag and a.slot then
            local before = tonumber(a.splitCountBefore) or 0
            local count = bagSlotCount(inv, a.bag, a.slot)
            if before > 1 and count >= before and a.ticks >= 2 then
                local stillAsync = inv and inv.SplitContainerItemPending
                    and inv.SplitContainerItemPending(a.bag, a.slot, a.splitCountBefore or 0, a.amount)
                if stillAsync then
                    return
                end
                if isOverlaySafeMerge(a, inv) and not a.overlayRetryUsed then
                    a.overlayRetryUsed = true
                    resetMergeForOverlayRetry(a)
                    Dbg("mover", "split wait failed — retry overlay merge amt=%s", tostring(a.amount))
                    return
                end
                return FinishAction({ ok = false, moved = 0, reason = "split_failed" })
            end
        end
        local waitLimit = a.stepMode == "merge" and MERGE_WAIT_LIMIT or SPLIT_WAIT_LIMIT
        if a.mergeStaging then
            waitLimit = math.max(waitLimit, STAGING_WAIT_LIMIT)
        end
        if a.ticks >= waitLimit then
            if a.mergeStaging then
                cleanupMergeStagingState(a, inv)
            end
            return FinishAction({ ok = false, moved = 0, reason = "timeout" })
        end
        return
    end

    a.asyncWaitTicks = 0
    a.lockWaitTicks = 0

    local cursorID = Mover.GetCursorItemID()
    if a.itemID and cursorID and a.tierKind == nil then
        if not Mover.ItemsCanMerge(a.itemID, cursorID, nil) and cursorID ~= a.itemID then
            return FinishAction({ ok = false, moved = 0, reason = "aborted" })
        end
    end

    stampCursorAmount(a)

    if a.stepMode == "merge" or (CursorHasItem() and a.execKind == "split_merge") then
        refreshMergeTarget(a)
    elseif not mergePlaceMode(a.stepMode) then
        a.mergeBag = nil
        a.mergeSlot = nil
    end

    if mergePlaceMode(a.stepMode) and a.mergeBag and a.mergeSlot
        and IsBankBag(a.mergeBag) and isSlotLocked(a.mergeBag, a.mergeSlot) then
        Dbg("merge", "merge target locked bag=%s:%s", a.mergeBag, a.mergeSlot)
        return
    end

    if a.stepMode == "bag_consolidate" or bankSplitReadyForMerge(a, inv) then
        -- bag_consolidate never waits on bank unlock; fall through
    elseif not bankSplitReadyForMerge(a, inv) then
        Dbg("mover", "wait bank event bag=%s:%s bankUnlocked=%s splitVisible=%s",
            tostring(a.bag), tostring(a.slot), a.bankUnlocked and "Y" or "N",
            bankSplitVisible(a, inv) and "Y" or "N")
        return
    end

    local beforeMerge = 0
    if mergePlaceMode(a.stepMode) and a.mergeBag and a.mergeSlot and inv then
        beforeMerge = bagSlotCount(inv, a.mergeBag, a.mergeSlot)
    end

    local placed = tryPlaceCursor(a)

    local mergeGain = 0
    if mergePlaceMode(a.stepMode) and a.mergeBag and a.mergeSlot and inv then
        local afterMerge = bagSlotCount(inv, a.mergeBag, a.mergeSlot)
        mergeGain = math.max(0, afterMerge - beforeMerge)
    end

    if mergeGain > 0 then
        local cap = tonumber(a.amount) or mergeGain
        mergeGain = math.min(mergeGain, cap)
        if a.stepMode == "merge" then
            local bagBefore = tonumber(a.bagTotalBefore)
            if bagBefore then
                local totalGain = bagTotalForItem(inv, a.itemID, a.tierKind) - bagBefore
                if totalGain > cap + 1 then
                    Dbg("merge", "poll spillover mergeGain=%s totalGain=%s cap=%s",
                        mergeGain, totalGain, cap)
                    return FinishAction({ ok = false, moved = 0, reason = "overshot" })
                end
            end
        end
        Dbg("merge", "mergeGain=%s before=%s slot=%s:%s cap=%s",
            mergeGain, beforeMerge, a.mergeBag, a.mergeSlot, cap)
        a.stuckTicks = 0
        if a.mergeStaging then
            a.stagingCredited = (tonumber(a.stagingCredited) or 0) + mergeGain
            local stagedLeft = stagingSlotCount(inv, a.stagingBag, a.stagingSlot)
            if CursorHasItem() or stagedLeft > 0 then
                a.stagingPhase = "return_bank"
                if CursorHasItem() and a.bag and a.slot and IsBankBag(a.bag) then
                    tryReturnCursorToSlot(inv, a.bag, a.slot)
                end
                return
            end
            finishMergeStaging(a, inv, a.stagingCredited)
            return
        end
        if CursorHasItem() and a.bag and a.slot and IsBankBag(a.bag) then
            tryReturnCursorToSlot(inv, a.bag, a.slot)
        end
        if not CursorHasItem() then
            if mergeGain > cap then
                return FinishAction({ ok = false, moved = 0, reason = "overshot" })
            end
            local credit = resolveCredit(a, 0, mergeGain)
            return FinishAction({ ok = true, moved = credit, wasSplit = false })
        end
        return
    end

    if placed > 0 and not CursorHasItem() then
        Dbg("mover", "placed=%s mode=%s", placed, tostring(a.stepMode))
        local credit = resolveCredit(a, placed, 0)
        return FinishAction({ ok = true, moved = credit })
    end

    if mergePlaceMode(a.stepMode) and CursorHasItem() then
        if a.bag and a.slot and IsBankBag(a.bag) then
            if tryReturnCursorToSlot(inv, a.bag, a.slot) then
                return
            end
            return
        end
        a.stuckTicks = (a.stuckTicks or 0) + 1
        Dbg("merge", "merge place failed — refresh target stuck=%d", a.stuckTicks)
        if a.stepMode == "merge" then
            refreshMergeTarget(a)
        end
        if a.stepMode == "bag_consolidate" and a.stuckTicks >= MERGE_CURSOR_STUCK_LIMIT then
            Mover.ClearCursor()
            return FinishAction({ ok = false, moved = 0, reason = "stuck" })
        end
        return
    end

    if not CursorHasItem() then
        if a.splitIssued then
            return
        end
        local bagAfter = bagTotalForItem(inv, a.itemID, a.tierKind)
        local bagGain = math.max(0, bagAfter - (a.bagTotalBefore or bagAfter))
        if bagGain > 0 and not mergePlaceMode(a.stepMode) then
            local credit = math.min(bagGain, tonumber(a.amount) or bagGain)
            Dbg("mover", "bag total gain credit=%s (fallback)", credit)
            return FinishAction({ ok = true, moved = credit })
        end
    end

    if a.stepMode == "merge" and not a.mergeOverlay
        and (a.stuckTicks or 0) >= MERGE_STUCK_FALLBACK_TICKS then
        Dbg("merge", "stuck %d ticks -> fallback withdraw placement", a.stuckTicks)
        a.stepMode = "withdraw"
        a.mergeBag = nil
        a.mergeSlot = nil
        a.stuckTicks = 0
        return
    end

    a.stuckTicks = (a.stuckTicks or 0) + 1
    local stuckLimit = mergePlaceMode(a.stepMode) and MERGE_CURSOR_STUCK_LIMIT or CURSOR_STUCK_LIMIT
    if a.stuckTicks >= stuckLimit then
        local failReason = "stuck"
        if a.stepMode == "merge" and a.mergeSplitPull then
            failReason = "merge_place_failed"
        end
        Dbg("mover", "cursor stuck limit mode=%s stuck=%d -> %s",
            tostring(a.stepMode), a.stuckTicks, failReason)
        Mover.ClearCursor()
        return FinishAction({
            ok = false,
            moved = 0,
            reason = failReason,
            hardFail = failReason == "stuck",
        })
    end
end

FinishAction = function(result)
    local a = action
    if not a then
        return
    end
    local inv = GetInv()
    local ok = result.ok or (tonumber(result.moved) or 0) > 0
    if not ok and inv and a.stepMode == "merge" then
        if a.mergeStaging then
            cleanupMergeStagingState(a, inv)
        end
        local reason = result.reason or ""
        if CursorHasItem()
            and (reason == "timeout" or reason == "stuck" or reason == "split_failed" or result.hardFail) then
            if a.bag and a.slot and IsBankBag(a.bag) then
                tryReturnCursorToSlot(inv, a.bag, a.slot)
            end
            if CursorHasItem() then
                Mover.ClearCursor()
            end
        end
    end
    action = nil
    local ok = result.ok or (tonumber(result.moved) or 0) > 0
    if result.wasSplit == nil then
        result.wasSplit = a.mustSplit or a.splitIssued or a.mergeSplitPull or false
    end
    if a.splitRejected then
        result.splitRejected = true
    end
    NoteActionOutcome(ok, result.hardFail)
    ArmGate(a.mustSplit or mergePlaceMode(a.stepMode))
    Dbg("mover", "action done ok=%s moved=%s reason=%s hard=%s backoff=%d",
        tostring(result.ok), tostring(result.moved), tostring(result.reason),
        tostring(result.hardFail), backoffSteps)
    local cb = a.onComplete
    if cb then
        pcall(cb, result)
    end
end

--- Submit exactly one bank action. Returns false if one is already in
--- flight, the global pacing gate hasn't opened yet, or any tracked
--- container currently has a locked slot (splitting mid-lock triggers
--- WoW's "Could not split stacks" error).
---
--- spec = {
---   bag, slot, amount, itemID, maxStack, tierKind,
---   mode = "withdraw" | "merge" | "charge" | "bag_consolidate",
---   execKind = "whole_withdraw" | "split_withdraw" | "whole_merge" | "split_merge" | "charge" | "bag_consolidate",
---   mergeBag, mergeSlot,  -- only for mode == "merge"
---   chargeCredit,          -- only for mode == "charge"
---   onComplete = function(result) end,
---     -- result = { ok, moved, reason, hardFail, wasSplit }
--- }
function Mover.SubmitAction(spec)
    if type(spec) ~= "table" then
        return false
    end
    if action ~= nil then
        return false
    end
    if not GateOpen() then
        return false
    end
    if lockContainers and Mover.IsAnythingLocked(lockContainers) then
        return false
    end

    action = {
        itemID = tonumber(spec.itemID),
        amount = tonumber(spec.amount) or 0,
        bag = spec.bag,
        slot = spec.slot,
        mergeBag = spec.mergeBag,
        mergeSlot = spec.mergeSlot,
        stepMode = spec.mode or "withdraw",
        execKind = spec.execKind,
        itemNoSplit = spec.itemNoSplit == true,
        realMaxStack = tonumber(spec.maxStack) or 20,
        tierKind = spec.tierKind,
        chargeCredit = spec.chargeCredit,
        onComplete = spec.onComplete,
        phase = "start",
        ticks = 0,
        stuckTicks = 0,
        asyncWaitTicks = 0,
        lockWaitTicks = 0,
        splitIssued = false,
        bankUnlocked = false,
        mergePullDone = false,
        mergePullStarted = false,
        mergeStaging = false,
        stagingPhase = nil,
        stagingBag = nil,
        stagingSlot = nil,
        stagingCredited = 0,
        stagingPullWait = 0,
        mergeSplitPull = spec.execKind == "split_merge",
        mergeOverlay = false,
        overlayRetryUsed = false,
    }
    if ProcessAction then
        local ok, err = pcall(ProcessAction)
        if not ok then
            Dbg("mover", "ProcessAction error: %s", tostring(err))
            if FinishAction then
                FinishAction({ ok = false, moved = 0, reason = "error", hardFail = false })
            else
                action = nil
            end
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- GENERIC THROTTLED RUN LOOP (orchestrator ticks; independent of the action
-- gate above, which only governs new-action submission)
-- ---------------------------------------------------------------------------

local runner = CreateFrame("Frame")
runner:Hide()
local active = false
local accum = 0
local actionPollAccum = 0
local current = nil

local ACTION_POLL_INTERVAL = 0.05
local MIN_INTERVAL = 0.08

local function StopInternal()
    active = false
    current = nil
    action = nil
    runner:SetScript("OnUpdate", nil)
    runner:Hide()
end

local function OnUpdate(_, elapsed)
    if not active or not current then
        StopInternal()
        return
    end

    local ctx = current

    if ctx.isAlive and not ctx.isAlive() then
        local onDone = ctx.onDone
        StopInternal()
        if onDone then pcall(onDone, "aborted") end
        return
    end

    -- Poll the in-flight action on its own short cadence, independent of the
    -- orchestrator step interval below — split/cursor resolution shouldn't
    -- wait on how often the caller re-evaluates "what next".
    if action then
        actionPollAccum = actionPollAccum + (elapsed or 0)
        if actionPollAccum >= ACTION_POLL_INTERVAL then
            actionPollAccum = 0
            local ok, err = pcall(ProcessAction)
            if not ok and action then
                Dbg("mover", "ProcessAction error: %s", tostring(err))
                if FinishAction then
                    FinishAction({ ok = false, moved = 0, reason = "error", hardFail = false })
                else
                    action = nil
                end
            end
        end
    end

    accum = accum + (elapsed or 0)
    if not ctx.forceImmediate and accum < (ctx.interval or MIN_INTERVAL) then
        return
    end
    ctx.forceImmediate = false
    accum = 0

    local ok, done = pcall(ctx.step)
    if not ok then
        local errMsg = tostring(done)
        print("|cffff4444FluxBankRestock|r SessionStep error: " .. errMsg)
        local onDone = ctx.onDone
        StopInternal()
        if onDone then pcall(onDone, "error") end
        return
    end

    if done then
        local onDone = ctx.onDone
        StopInternal()
        if onDone then
            local reason = (type(done) == "string") and done or "complete"
            pcall(onDone, reason)
        end
        return
    end
end

--- Nudge the orchestrator's own tick to run again immediately (does NOT
--- bypass the action pacing gate — that only governs SubmitAction).
function Mover.RequestStep()
    if not active or not current then
        return false
    end
    current.forceImmediate = true
    accum = current.interval or MIN_INTERVAL
    if runner and not runner:IsShown() then
        runner:Show()
    end
    return true
end

function Mover.AttachRunner(opts)
    if type(opts) ~= "table" or not active or not current then
        return false
    end
    if type(opts.step) == "function" then
        current.step = opts.step
    end
    if opts.isAlive then
        current.isAlive = opts.isAlive
    end
    if opts.onDone then
        current.onDone = opts.onDone
    end
    if opts.interval ~= nil then
        current.interval = tonumber(opts.interval) or current.interval
    end
    if opts.lockContainers then
        Mover.SetLockContainers(opts.lockContainers)
    end
    current.forceImmediate = true
    accum = 0
    return true
end

--- Start the throttled orchestrator loop.
--- opts = { step, isAlive, onDone, interval, lockContainers }
function Mover.Run(opts)
    if type(opts) ~= "table" or type(opts.step) ~= "function" then
        return false
    end
    if active then
        return false
    end
    current = {
        step = opts.step,
        isAlive = opts.isAlive,
        onDone = opts.onDone,
        interval = tonumber(opts.interval) or MIN_INTERVAL,
        forceImmediate = true,
    }
    Mover.SetLockContainers(opts.lockContainers)
    accum = 0
    actionPollAccum = 0
    action = nil
    -- Deliberately do NOT reset backoffSteps/nextActionAt here: they track
    -- an active pacing-gate cooldown that must survive a manual stop and
    -- restart of the restock button. Resetting them would let a fresh
    -- session immediately re-hammer a slot the server just rejected at
    -- full pace instead of respecting the cooldown already in progress;
    -- they decay back to 0 naturally via NoteActionOutcome on success.
    active = true
    runner:Show()
    runner:SetScript("OnUpdate", OnUpdate)
    return true
end

function Mover.IsRunning()
    return active
end

function Mover.Stop(opts)
    opts = type(opts) == "table" and opts or {}
    local onDone = active and current and current.onDone
    if active then
        StopInternal()
    end
    if opts.clearCursor ~= false then
        Mover.ClearCursor()
    end
    if onDone and opts.fireOnDone ~= false then
        pcall(onDone, "stopped")
    end
end

--- TSM-style slot move (split/pickup + place + clear cursor).
function Mover.ExecuteSlotMove(fromBag, fromSlot, toBag, toSlot, amount)
    local moves = _G.FluxBankRestockMoves
    if moves and moves.ExecuteSlotMove then
        return moves.ExecuteSlotMove(fromBag, fromSlot, toBag, toSlot, amount)
    end
    return false, "no_moves"
end

_G.FluxItemMover = Mover
return Mover
