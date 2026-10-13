--[[
    Inventory/FluxInv/FluxInv_Bags.lua

    Incremental carried-bag snapshot for FluxInv.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Bags = Inv.Bags or {}
local Bags = Inv.Bags

local wipe = table.wipe or wipe

local bagSlots = {} -- [bag] = { [slot] = { itemID, count } }
local bagItemData = {} -- [bag] = { [itemID] = { count, link, bag, slot } }
local dirtyBags = {}
local allDirty = true
local counts = nil
local uniqueItems = nil
local generation = 0
local lastRefreshedDirty = {} -- bags refreshed on last Refresh() call (for dispatch ctx)

-- Last Refresh() change classification for listener fan-out.
local lastChangeKind = "none" -- none | countOnly | identityChanged | unknown
local lastAddedItemIDs = nil
local lastRemovedItemIDs = nil

local function Compat()
    return Inv.Compat
end

local function Containers()
    return Inv.Containers
end

local function clearChangeMeta()
    lastChangeKind = "none"
    lastAddedItemIDs = nil
    lastRemovedItemIDs = nil
end

local function snapshotUniqueKeys()
    local keys = {}
    if uniqueItems then
        for itemID in pairs(uniqueItems) do
            keys[itemID] = true
        end
    end
    return keys
end

local function classifyChange(beforeKeys)
    local added, removed = {}, {}
    local hasAdd, hasRem = false, false
    if uniqueItems then
        for itemID in pairs(uniqueItems) do
            if not beforeKeys[itemID] then
                added[itemID] = true
                hasAdd = true
            end
        end
    end
    for itemID in pairs(beforeKeys) do
        if not uniqueItems or not uniqueItems[itemID] then
            removed[itemID] = true
            hasRem = true
        end
    end
    if hasAdd or hasRem then
        lastChangeKind = "identityChanged"
        lastAddedItemIDs = hasAdd and added or nil
        lastRemovedItemIDs = hasRem and removed or nil
    else
        lastChangeKind = "countOnly"
        lastAddedItemIDs = nil
        lastRemovedItemIDs = nil
    end
end

local function scanBag(bag)
    local compat = Compat()
    local slots, data = {}, {}
    local numSlots = compat.GetContainerNumSlots(bag)
    for slot = 1, numSlots do
        local info = compat.GetContainerItemInfo(bag, slot)
        if info and info.itemID then
            slots[slot] = { itemID = info.itemID, count = info.count }
            local rec = data[info.itemID]
            if rec then
                rec.count = rec.count + info.count
            else
                data[info.itemID] = {
                    count = info.count,
                    link = info.hyperlink,
                    bag = bag,
                    slot = slot,
                }
            end
        end
    end
    bagSlots[bag] = slots
    bagItemData[bag] = data
end

local function isCurrent()
    return uniqueItems ~= nil and not allDirty and next(dirtyBags) == nil
end

local function rebuildAggregates()
    local newCounts, newUnique = {}, {}
    local containers = Containers()
    for _, bag in ipairs(containers.GetCarriedBagIDs()) do
        local data = bagItemData[bag]
        if data then
            for itemID, rec in pairs(data) do
                newCounts[itemID] = (newCounts[itemID] or 0) + rec.count
                local u = newUnique[itemID]
                if u then
                    u.count = u.count + rec.count
                else
                    newUnique[itemID] = {
                        count = rec.count,
                        link = rec.link,
                        bag = rec.bag,
                        slot = rec.slot,
                    }
                end
            end
        end
    end
    counts = newCounts
    uniqueItems = newUnique
    generation = generation + 1
end

--- When a unique entry was tied to a dirty bag, re-seed from any remaining bag data.
local function reseatUnique(itemID)
    for _, bag in ipairs(Containers().GetCarriedBagIDs()) do
        local data = bagItemData[bag]
        local rec = data and data[itemID]
        if rec then
            uniqueItems[itemID] = {
                count = counts[itemID] or rec.count,
                link = rec.link,
                bag = rec.bag,
                slot = rec.slot,
            }
            return
        end
    end
    uniqueItems[itemID] = nil
end

--- Apply one bag's old→new item map into live aggregates (avoids full bag walk).
--- Does not bump generation; caller bumps once after all dirty bags.
local function applyBagAggregateDelta(bag, oldData, newData)
    if not counts or not uniqueItems then
        rebuildAggregates()
        return false
    end
    if oldData then
        for itemID, rec in pairs(oldData) do
            local nextCount = (counts[itemID] or 0) - (rec.count or 0)
            if nextCount <= 0 then
                counts[itemID] = nil
                uniqueItems[itemID] = nil
            else
                counts[itemID] = nextCount
                local u = uniqueItems[itemID]
                if u then
                    u.count = nextCount
                    if u.bag == bag then
                        reseatUnique(itemID)
                        if uniqueItems[itemID] then
                            uniqueItems[itemID].count = nextCount
                        end
                    end
                end
            end
        end
    end
    if newData then
        for itemID, rec in pairs(newData) do
            local nextCount = (counts[itemID] or 0) + (rec.count or 0)
            counts[itemID] = nextCount
            local u = uniqueItems[itemID]
            if not u then
                uniqueItems[itemID] = {
                    count = nextCount,
                    link = rec.link,
                    bag = rec.bag,
                    slot = rec.slot,
                }
            else
                u.count = nextCount
                if not u.bag or u.bag == bag then
                    u.link = rec.link
                    u.bag = rec.bag
                    u.slot = rec.slot
                end
            end
        end
    end
    return true
end

function Bags.MarkDirty(bag)
    if bag == nil then
        allDirty = true
        wipe(dirtyBags)
        return
    end
    bag = tonumber(bag)
    if not bag then
        allDirty = true
        return
    end
    if Containers().IsCarriedBag(bag) then
        dirtyBags[bag] = true
    end
end

function Bags.Invalidate()
    allDirty = true
    wipe(dirtyBags)
    Containers().Invalidate()
end

function Bags.Refresh()
    wipe(lastRefreshedDirty)
    if isCurrent() then
        clearChangeMeta()
        Bags.NoteRefreshSettling()
        return true
    end
    local containers = Containers()
    local beforeKeys = snapshotUniqueKeys()

    if allDirty or not counts or not uniqueItems then
        for _, bag in ipairs(containers.GetCarriedBagIDs()) do
            scanBag(bag)
            lastRefreshedDirty[bag] = true
        end
        allDirty = false
        wipe(dirtyBags)
        rebuildAggregates()
        classifyChange(beforeKeys)
        Bags.NoteRefreshSettling()
        return true
    end

    -- Delta path: apply every dirty bag in place (no full rebuildAggregates).
    local dirtyList, dirtyCount = {}, 0
    for bag in pairs(dirtyBags) do
        if containers.IsCarriedBag(bag) then
            dirtyCount = dirtyCount + 1
            dirtyList[dirtyCount] = bag
            lastRefreshedDirty[bag] = true
        end
    end
    wipe(dirtyBags)

    if dirtyCount == 0 then
        clearChangeMeta()
        Bags.NoteRefreshSettling()
        return true
    end

    local ok = true
    for i = 1, dirtyCount do
        local bag = dirtyList[i]
        local oldData = bagItemData[bag]
        scanBag(bag)
        if not applyBagAggregateDelta(bag, oldData, bagItemData[bag]) then
            ok = false
            break
        end
    end
    if not ok then
        -- applyBagAggregateDelta fell back to rebuildAggregates once.
        classifyChange(beforeKeys)
        Bags.NoteRefreshSettling()
        return true
    end
    generation = generation + 1
    classifyChange(beforeKeys)
    Bags.NoteRefreshSettling()
    return true
end

--- Bags touched by the last Refresh() (for overlay / listener dirty paints).
function Bags.GetLastRefreshedDirtyBags()
    return lastRefreshedDirty
end

--- "none" | "countOnly" | "identityChanged" | "unknown"
function Bags.GetLastChangeKind()
    return lastChangeKind
end

function Bags.GetLastAddedItemIDs()
    return lastAddedItemIDs
end

function Bags.GetLastRemovedItemIDs()
    return lastRemovedItemIDs
end

function Bags.GetCount(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    Bags.Refresh()
    return counts and counts[itemID] or 0
end

function Bags.GetCounts()
    Bags.Refresh()
    return counts or {}
end

function Bags.GetUniqueItems()
    Bags.Refresh()
    return uniqueItems or {}
end

function Bags.GetSlots(bag)
    Bags.Refresh()
    return bagSlots[bag]
end

function Bags.GetItemData(bag)
    Bags.Refresh()
    return bagItemData[bag]
end

function Bags.FindFirst(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    Bags.Refresh()
    local u = uniqueItems and uniqueItems[itemID]
    if u then
        return u.bag, u.slot, u.count, u.link
    end
    return nil
end

function Bags.FindStacks(itemID)
    itemID = tonumber(itemID)
    local out = {}
    if not itemID then
        return out
    end
    Bags.Refresh()
    for _, bag in ipairs(Containers().GetCarriedBagIDs()) do
        local slots = bagSlots[bag]
        if slots then
            for slot, rec in pairs(slots) do
                if rec.itemID == itemID then
                    out[#out + 1] = { bag = bag, slot = slot, count = rec.count, region = "bags" }
                end
            end
        end
    end
    return out
end

function Bags.GetGeneration()
    return generation
end

--- False while bags are invalidated/dirty (portal/zone soft refresh).
function Bags.IsReady()
    return isCurrent()
end

-- Portal/zone: snapshot may be "ready" but still empty/wrong for a beat.
-- Buttons freeze identity until IsReliable() rises.
local snapshotUnreliable = false
local unreliableMarkedAt = 0
local uniqueAtUnreliable = 0
local settleGen = nil
local settleAt = 0
local RELIABLE_SETTLE_SEC = 0.25
local UNRELIABLE_MAX_SEC = 3.0
local COLLAPSED_MAX_SEC = 8.0

local function UniqueCount()
    local n = 0
    if uniqueItems then
        for _ in pairs(uniqueItems) do
            n = n + 1
        end
    end
    return n
end

local function SnapshotLooksCollapsed()
    if uniqueAtUnreliable <= 0 then
        return false
    end
    local n = UniqueCount()
    return n == 0 or n < math.max(1, math.floor(uniqueAtUnreliable * 0.25))
end

function Bags.MarkUnreliable(_reason)
    if not snapshotUnreliable then
        uniqueAtUnreliable = UniqueCount()
    end
    snapshotUnreliable = true
    unreliableMarkedAt = (GetTime and GetTime()) or 0
    settleGen = nil
    settleAt = 0
end

local function tryClearUnreliable()
    if not snapshotUnreliable then
        return
    end
    local now = (GetTime and GetTime()) or 0
    local collapsed = SnapshotLooksCollapsed()
    local maxSec = collapsed and COLLAPSED_MAX_SEC or UNRELIABLE_MAX_SEC
    local cleared = false
    if unreliableMarkedAt > 0 and (now - unreliableMarkedAt) >= maxSec then
        snapshotUnreliable = false
        settleGen = nil
        settleAt = 0
        cleared = true
    elseif collapsed then
        return
    elseif isCurrent() and settleAt > 0 and now >= settleAt and settleGen == generation then
        snapshotUnreliable = false
        settleGen = nil
        settleAt = 0
        cleared = true
    end
    if cleared then
        -- Rising edge: buttons commit latched → real bag counts.
        if Inv.Events and Inv.Events.Pulse then
            pcall(Inv.Events.Pulse, "light", { "bags" })
        end
    end
end

--- True when bag counts are trustworthy for promote/clear (not mid-portal flicker).
function Bags.IsReliable()
    tryClearUnreliable()
    if not isCurrent() then
        return false
    end
    return not snapshotUnreliable
end

--- Called after a successful Refresh while unreliable — starts the settle window.
function Bags.NoteRefreshSettling()
    if not snapshotUnreliable then
        return
    end
    if not isCurrent() then
        return
    end
    settleGen = generation
    settleAt = ((GetTime and GetTime()) or 0) + RELIABLE_SETTLE_SEC
    -- One timer so reliability rising edge fires even without another bag event.
    if C_Timer and C_Timer.After then
        local gen = settleGen
        local at = settleAt
        C_Timer.After(RELIABLE_SETTLE_SEC + 0.02, function()
            if settleGen ~= gen or settleAt ~= at then
                return
            end
            tryClearUnreliable()
        end)
    end
end

function Bags.GetSnapshot()
    Bags.Refresh()
    return {
        counts = counts or {},
        uniqueItems = uniqueItems or {},
        generation = generation,
        region = "bags",
    }
end

_G.FluxInv = Inv
