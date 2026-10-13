--[[
    Restock/Bank/FluxBankRestockInventory.lua

    Restocker-style inventory snapshots for bank restock: per-itemID (or tier
    key) totals plus slot lists sorted smallest-stack-first. FindBestFit picks
    the tightest merge destination for a cursor placement.
]]

FluxBankRestockInventory = FluxBankRestockInventory or {}
local Inventory = FluxBankRestockInventory

local function Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

local function tierStackMatches(kind, itemID)
    kind = kind and tostring(kind) or nil
    itemID = tonumber(itemID)
    if not kind or not itemID then
        return false
    end
    local T = _G.FluxRestockTiers
    if T and T.StackMatchesBankRestockKind then
        return T.StackMatchesBankRestockKind(kind, itemID)
    end
    if T and T.GetItemTierValue then
        return (T.GetItemTierValue(kind, itemID) or 0) > 0
    end
    return false
end

local function slotKey(bag, slot)
    return tostring(bag) .. ":" .. tostring(slot)
end

local function newSlot(bag, slot, count, itemID)
    return {
        bag = bag,
        slot = slot,
        count = tonumber(count) or 0,
        itemID = tonumber(itemID),
    }
end

local function sortSlotsAsc(slots)
    table.sort(slots, function(a, b)
        local ca, cb = tonumber(a.count) or 0, tonumber(b.count) or 0
        if ca ~= cb then
            return ca < cb
        end
        if (a.itemID or 0) ~= (b.itemID or 0) then
            return (a.itemID or 0) < (b.itemID or 0)
        end
        return (a.slot or 0) < (b.slot or 0)
    end)
end

--- Build a snapshot keyed by itemID string.
--- matchFn(itemID) -> true when this slot should be included.
function Inventory.SnapshotContainers(containerIDs, matchFn, resolveMaxStack)
    local inv = Inv()
    local summary = {}
    local slots = {}
    if not inv or not containerIDs or type(matchFn) ~= "function" then
        return { summary = summary, slots = slots }
    end
    for _, bag in ipairs(containerIDs) do
        local numSlots = inv.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = inv.GetContainerItemInfo(bag, slot)
            if info and info.itemID and (info.count or 0) > 0 then
                local itemID = info.itemID
                if matchFn(itemID) then
                    local key = tostring(itemID)
                    summary[key] = (summary[key] or 0) + (info.count or 0)
                    slots[key] = slots[key] or {}
                    slots[key][#slots[key] + 1] = newSlot(bag, slot, info.count, itemID)
                end
            end
        end
    end
    for _, list in pairs(slots) do
        sortSlotsAsc(list)
    end
    return { summary = summary, slots = slots, resolveMaxStack = resolveMaxStack }
end

function Inventory.SnapshotPlayerBags(bagIDs, matchFn, resolveMaxStack)
    return Inventory.SnapshotContainers(bagIDs, matchFn, resolveMaxStack)
end

function Inventory.SnapshotBank(bankBagIDs, matchFn, resolveMaxStack)
    return Inventory.SnapshotContainers(bankBagIDs, matchFn, resolveMaxStack)
end

--- Match predicate for a single itemID task.
function Inventory.MatchItemID(itemID)
    itemID = tonumber(itemID)
    return function(candidateID)
        return candidateID == itemID
    end
end

--- Match predicate for a tier-kind task.
function Inventory.MatchTierKind(tierKind)
    return function(candidateID)
        return tierStackMatches(tierKind, candidateID)
    end
end

--- Restocker FindBestFit: pick partial stack with room for `amount`, prefer
--- tightest fit (smallest leftover space after merge).
function Inventory.FindBestFit(playerSnap, itemID, amount, maxStack)
    itemID = tonumber(itemID)
    amount = tonumber(amount) or 0
    maxStack = tonumber(maxStack) or 20
    if not playerSnap or not itemID or amount <= 0 or maxStack <= 1 then
        return nil, nil, 0
    end
    local key = tostring(itemID)
    local list = playerSnap.slots and playerSnap.slots[key]
    if not list or #list == 0 then
        return nil, nil, 0
    end
    local bestBag, bestSlot, bestRemainder
    for _, st in ipairs(list) do
        local stackMax = maxStack
        if playerSnap.resolveMaxStack then
            stackMax = tonumber(playerSnap.resolveMaxStack(st.itemID)) or maxStack
        end
        local room = stackMax - (st.count or 0)
        if room >= amount then
            local remainder = stackMax - ((st.count or 0) + amount)
            if not bestRemainder or remainder < bestRemainder then
                bestRemainder = remainder
                bestBag = st.bag
                bestSlot = st.slot
            end
        end
    end
    if bestBag and bestSlot then
        local stackMax = maxStack
        if playerSnap.resolveMaxStack then
            stackMax = tonumber(playerSnap.resolveMaxStack(itemID)) or maxStack
        end
        local st
        for _, candidate in ipairs(list) do
            if candidate.bag == bestBag and candidate.slot == bestSlot then
                st = candidate
                break
            end
        end
        local room = stackMax - ((st and st.count) or 0)
        return bestBag, bestSlot, room
    end
    return nil, nil, 0
end

--- True when at least one completely empty player bag slot exists.
function Inventory.HasEmptyBagSlot(bagIDs)
    local inv = Inv()
    if not inv or not bagIDs then
        return false
    end
    for _, bag in ipairs(bagIDs) do
        if inv.GetContainerNumFreeSlots(bag) > 0 then
            return true
        end
    end
    for _, bag in ipairs(bagIDs) do
        local slots = inv.GetContainerNumSlots(bag)
        for slot = 1, slots do
            if not inv.GetContainerItemInfo(bag, slot) then
                return true
            end
        end
    end
    return false
end

function Inventory.SlotKey(bag, slot)
    return slotKey(bag, slot)
end

_G.FluxBankRestockInventory = Inventory
return Inventory
