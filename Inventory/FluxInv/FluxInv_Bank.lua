--[[
    Inventory/FluxInv/FluxInv_Bank.lua

    Character bank + Warband/Account bank snapshots for FluxInv.

    When the bank UI is closed, stack counts come from C_Item.GetItemCount
    (no visit required). Charge totals prefer an open-bank slot scan, then the
    Blizzard uses-count API, then the last persisted open-bank charge snapshot.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Bank = Inv.Bank or {}
local Bank = Inv.Bank

local wipe = table.wipe or wipe

local bankOpen = false
local charSlots = {} -- [bag] = { [slot] = { itemID, count } }
local charData = {} -- [bag] = { [itemID] = { count, link, bag, slot } }
local warSlots = {}
local warData = {}
local dirtyChar = {}
local dirtyWar = {}
local allCharDirty = true
local allWarDirty = true
local charCounts = nil
local warCounts = nil
local charAvailable = false
local warAvailable = false
local lastCharCounts = {} -- retained when bank closes / loaded from SV
local lastWarCounts = {}
local lastChargeCounts = {} -- [itemID] = open-bank charge total (char+warband)
local lastCharLinks = {}
local lastWarLinks = {}
local generation = 0
local lastRefreshedDirty = {} -- bags refreshed on last Refresh() (for dispatch ctx)
local persistedLoaded = false

-- Last Refresh() change classification for listener fan-out (mirrors Bags).
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

local function CopyCountMap(src, dst)
    wipe(dst)
    if type(src) ~= "table" then
        return
    end
    for k, v in pairs(src) do
        local id = tonumber(k)
        local n = tonumber(v)
        if id and n and n > 0 then
            dst[id] = n
        end
    end
end

local function SnapshotCountMap(src)
    local out = {}
    if type(src) ~= "table" then
        return out
    end
    for id, n in pairs(src) do
        id = tonumber(id)
        n = tonumber(n)
        if id and n and n > 0 then
            out[id] = n
        end
    end
    return out
end

local function GetBankSV()
    _G._FluxUI_CharSavedVars = _G._FluxUI_CharSavedVars or {}
    local root = _G._FluxUI_CharSavedVars
    if type(root.Bank) ~= "table" then
        root.Bank = {}
    end
    return root.Bank
end

local function LoadPersistedCounts()
    if persistedLoaded then
        return
    end
    persistedLoaded = true
    local sv = _G._FluxUI_CharSavedVars and _G._FluxUI_CharSavedVars.Bank
    if type(sv) ~= "table" then
        return
    end
    if next(lastCharCounts) == nil then
        CopyCountMap(sv.charCounts, lastCharCounts)
    end
    if next(lastWarCounts) == nil then
        CopyCountMap(sv.warCounts, lastWarCounts)
    end
    if next(lastChargeCounts) == nil then
        CopyCountMap(sv.chargeCounts, lastChargeCounts)
    end
end

function Bank.Persist()
    local sv = GetBankSV()
    sv.charCounts = SnapshotCountMap(lastCharCounts)
    sv.warCounts = SnapshotCountMap(lastWarCounts)
    sv.chargeCounts = SnapshotCountMap(lastChargeCounts)
end

local function ApiItemCount(itemID, includeBank, includeCharges, includeReagent, includeAccount)
    includeBank = includeBank and true or false
    includeCharges = includeCharges and true or false
    includeReagent = includeReagent and true or false
    includeAccount = includeAccount and true or false
    if C_Item and C_Item.GetItemCount then
        local ok, n = pcall(C_Item.GetItemCount, itemID, includeBank, includeCharges, includeReagent, includeAccount)
        if ok and type(n) == "number" then
            return n
        end
    end
    if GetItemCount then
        local ok, n = pcall(GetItemCount, itemID, includeBank, includeCharges, includeReagent)
        if ok and type(n) == "number" then
            return n
        end
    end
    return nil
end

--- Bank/warband-only count via Blizzard API (works with bank UI closed).
local function ApiBankOnlyCount(itemID, includeChar, includeWar, includeCharges)
    local bags = ApiItemCount(itemID, false, includeCharges, false, false)
    if bags == nil then
        return nil
    end
    if includeChar and includeWar then
        local all = ApiItemCount(itemID, true, includeCharges, true, true)
        if all == nil then
            return nil
        end
        return math.max(0, all - bags)
    end
    if includeChar then
        local n = ApiItemCount(itemID, true, includeCharges, true, false)
        if n == nil then
            return nil
        end
        return math.max(0, n - bags)
    end
    if includeWar then
        local n = ApiItemCount(itemID, false, includeCharges, false, true)
        if n == nil then
            return nil
        end
        return math.max(0, n - bags)
    end
    return 0
end

local function IsChargeBankItem(itemID)
    local reg = _G.FluxRestockItemRegistry
    if reg and reg.IsChargeItem and reg.IsChargeItem(itemID) then
        return true
    end
    local Cons = _G.FluxNCConsumables
    return Cons and Cons.IsWeaponEnchantItem and Cons.IsWeaponEnchantItem(itemID) or false
end

local function SumOpenBankSlotCharges(itemID, includeChar, includeWar)
    local stacks = Bank.FindStacks(itemID, {
        bank = includeChar,
        warband = includeWar,
    })
    if not stacks or #stacks == 0 then
        return 0
    end
    local reg = _G.FluxRestockItemRegistry
    local getCharges = reg and reg.GetSlotCharges
    local total = 0
    for i = 1, #stacks do
        local st = stacks[i]
        local charges = getCharges and getCharges(st.bag, st.slot) or nil
        if charges and charges > 0 then
            total = total + charges
        else
            total = total + (tonumber(st.count) or 1)
        end
    end
    return total
end

local function SnapshotChargeCountsWhileOpen()
    local reg = _G.FluxRestockItemRegistry
    local getCharges = reg and reg.GetSlotCharges
    if not getCharges or not Bank.ForEachOpenStack then
        return
    end
    local totals = {}
    Bank.ForEachOpenStack({ force = true }, function(bag, slot, rec)
        local id = rec and tonumber(rec.itemID)
        if not id or not IsChargeBankItem(id) then
            return
        end
        local charges = getCharges(bag, slot)
        local add = (charges and charges > 0) and charges or (tonumber(rec.count) or 1)
        totals[id] = (totals[id] or 0) + add
    end)
    wipe(lastChargeCounts)
    for id, n in pairs(totals) do
        lastChargeCounts[id] = n
    end
end

local function CachedStackCount(itemID, includeChar, includeWar)
    local n = 0
    if includeChar then
        n = n + (lastCharCounts[itemID] or 0)
    end
    if includeWar then
        n = n + (lastWarCounts[itemID] or 0)
    end
    return n
end

local function GetChargeAwareBankCount(itemID, opts)
    local includeChar = opts.bank ~= false
    local includeWar = opts.warband ~= false
    local allowCached = opts.allowCached ~= false

    if Bank.IsOpen() then
        Bank.Refresh(opts)
        local sum = SumOpenBankSlotCharges(itemID, includeChar, includeWar)
        if includeChar and includeWar then
            lastChargeCounts[itemID] = sum
        end
        return sum
    end

    -- Closed bank: API uses-count often works without visiting; else persisted charges.
    local apiCharges = ApiBankOnlyCount(itemID, includeChar, includeWar, true)
    if apiCharges and apiCharges > 0 then
        return apiCharges
    end

    local stackN = ApiBankOnlyCount(itemID, includeChar, includeWar, false)
    if stackN == nil and allowCached then
        stackN = CachedStackCount(itemID, includeChar, includeWar)
    end
    stackN = stackN or 0

    if allowCached and includeChar and includeWar and lastChargeCounts[itemID] ~= nil then
        if stackN <= 0 then
            lastChargeCounts[itemID] = nil
            return 0
        end
        return lastChargeCounts[itemID]
    end

    if apiCharges ~= nil and apiCharges > 0 then
        return apiCharges
    end

    -- At least report stack presence when charge data is unavailable.
    return stackN
end

--- Unique itemIDs currently present in character bank + warband aggregates.
local function snapshotUniqueKeys()
    local keys = {}
    if charCounts then
        for itemID in pairs(charCounts) do
            keys[itemID] = true
        end
    end
    if warCounts then
        for itemID in pairs(warCounts) do
            keys[itemID] = true
        end
    end
    return keys
end

local function classifyChange(beforeKeys)
    local added, removed = {}, {}
    local hasAdd, hasRem = false, false
    if charCounts then
        for itemID in pairs(charCounts) do
            if not beforeKeys[itemID] then
                added[itemID] = true
                hasAdd = true
            end
        end
    end
    if warCounts then
        for itemID in pairs(warCounts) do
            if not beforeKeys[itemID] then
                added[itemID] = true
                hasAdd = true
            end
        end
    end
    for itemID in pairs(beforeKeys) do
        local stillThere = (charCounts and charCounts[itemID]) or (warCounts and warCounts[itemID])
        if not stillThere then
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

local function IsBaganatorBankViewShown()
    for i = 1, 2 do
        local views = {
            _G["Baganator_SingleViewBankViewFrame" .. i],
            _G["Baganator_CategoryViewBankViewFrame" .. i],
        }
        for v = 1, #views do
            local view = views[v]
            if view and view.IsShown and view:IsShown() then
                return true
            end
        end
    end
    return false
end

function Bank.IsOpen()
    if bankOpen then
        return true
    end
    if _G.BankFrame and _G.BankFrame.IsShown and _G.BankFrame:IsShown() then
        return true
    end
    return IsBaganatorBankViewShown()
end

function Bank.SetOpen(isOpen)
    local wantOpen = not not isOpen
    if wantOpen and not bankOpen then
        bankOpen = true
        Containers().Invalidate()
        allCharDirty = true
        allWarDirty = true
        wipe(dirtyChar)
        wipe(dirtyWar)
        charAvailable = true
        warAvailable = Compat().HasWarbandBank and Compat().HasWarbandBank() or false
        if Inv.NotifyBankOpenChanged then
            Inv.NotifyBankOpenChanged(true)
        end
    elseif not wantOpen and bankOpen then
        -- Snapshot while containers are still readable (bankOpen still true).
        Bank.Refresh()
        SnapshotChargeCountsWhileOpen()
        if charCounts then
            CopyCountMap(charCounts, lastCharCounts)
        end
        if warCounts then
            CopyCountMap(warCounts, lastWarCounts)
        end
        Bank.Persist()
        bankOpen = false
        charAvailable = false
        warAvailable = false
        if Inv.NotifyBankOpenChanged then
            Inv.NotifyBankOpenChanged(false)
        end
    end
end

local function scanBagInto(bag, slotsStore, dataStore)
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
    slotsStore[bag] = slots
    dataStore[bag] = data
end

local function rebuild(region)
    local containers = Containers()
    local ids = region == "warband" and containers.GetWarbandBankIDs() or containers.GetCharacterBankIDs()
    local dataStore = region == "warband" and warData or charData
    local newCounts, links = {}, {}
    for _, bag in ipairs(ids) do
        local data = dataStore[bag]
        if data then
            for itemID, rec in pairs(data) do
                newCounts[itemID] = (newCounts[itemID] or 0) + rec.count
                if rec.link and not links[itemID] then
                    links[itemID] = rec.link
                end
            end
        end
    end
    if region == "warband" then
        warCounts = newCounts
        lastWarLinks = links
    else
        charCounts = newCounts
        lastCharLinks = links
    end
    generation = generation + 1
end

--- Single-bag delta into character or warband aggregates (avoids full rebuild).
local function applyBankAggregateDelta(region, bag, oldData, newData)
    local counts = region == "warband" and warCounts or charCounts
    local links = region == "warband" and lastWarLinks or lastCharLinks
    if not counts then
        rebuild(region)
        return
    end
    links = links or {}
    if oldData then
        for itemID, rec in pairs(oldData) do
            local nextCount = (counts[itemID] or 0) - (rec.count or 0)
            if nextCount <= 0 then
                counts[itemID] = nil
                links[itemID] = nil
            else
                counts[itemID] = nextCount
            end
        end
    end
    if newData then
        for itemID, rec in pairs(newData) do
            counts[itemID] = (counts[itemID] or 0) + (rec.count or 0)
            if rec.link then
                links[itemID] = rec.link
            end
        end
    end
    if region == "warband" then
        warCounts = counts
        lastWarLinks = links
    else
        charCounts = counts
        lastCharLinks = links
    end
    generation = generation + 1
end

local function refreshRegionDirty(region)
    local containers = Containers()
    local dirtyMap = region == "warband" and dirtyWar or dirtyChar
    local slotsStore = region == "warband" and warSlots or charSlots
    local dataStore = region == "warband" and warData or charData
    local isContainer = region == "warband" and containers.IsWarbandBankContainer
        or containers.IsCharacterBankContainer

    local dirtyList, dirtyCount = {}, 0
    for bag in pairs(dirtyMap) do
        if isContainer(bag) then
            dirtyCount = dirtyCount + 1
            dirtyList[dirtyCount] = bag
            lastRefreshedDirty[bag] = true
        end
    end
    wipe(dirtyMap)

    if dirtyCount == 1 then
        local bag = dirtyList[1]
        local oldData = dataStore[bag]
        scanBagInto(bag, slotsStore, dataStore)
        applyBankAggregateDelta(region, bag, oldData, dataStore[bag])
        return
    end
    for i = 1, dirtyCount do
        scanBagInto(dirtyList[i], slotsStore, dataStore)
    end
    rebuild(region)
end

function Bank.MarkDirty(bag)
    if bag == nil then
        allCharDirty = true
        allWarDirty = true
        wipe(dirtyChar)
        wipe(dirtyWar)
        return
    end
    bag = tonumber(bag)
    if not bag then
        return
    end
    local containers = Containers()
    if containers.IsWarbandBankContainer(bag) then
        dirtyWar[bag] = true
    elseif containers.IsCharacterBankContainer(bag) then
        dirtyChar[bag] = true
    end
end

function Bank.MarkAllDirty()
    Bank.MarkDirty()
end

function Bank.Invalidate()
    Bank.MarkDirty()
end

function Bank.Refresh(opts)
    opts = opts or {}
    wipe(lastRefreshedDirty)
    if not Bank.IsOpen() and not opts.force then
        return false
    end
    LoadPersistedCounts()
    local beforeKeys = snapshotUniqueKeys()
    local containers = Containers()

    if allCharDirty then
        wipe(charSlots)
        wipe(charData)
        for _, bag in ipairs(containers.GetCharacterBankIDs()) do
            scanBagInto(bag, charSlots, charData)
            lastRefreshedDirty[bag] = true
        end
        allCharDirty = false
        wipe(dirtyChar)
        rebuild("bank")
        charAvailable = true
    elseif next(dirtyChar) then
        refreshRegionDirty("bank")
    end

    local hasWar = Compat().HasWarbandBank and Compat().HasWarbandBank()
    if hasWar then
        if allWarDirty then
            wipe(warSlots)
            wipe(warData)
            for _, bag in ipairs(containers.GetWarbandBankIDs()) do
                scanBagInto(bag, warSlots, warData)
                lastRefreshedDirty[bag] = true
            end
            allWarDirty = false
            wipe(dirtyWar)
            rebuild("warband")
            warAvailable = true
        elseif next(dirtyWar) then
            refreshRegionDirty("warband")
        end
    else
        warAvailable = false
        warCounts = warCounts or {}
    end
    classifyChange(beforeKeys)
    return true
end

--- Bank bags touched by the last Refresh() (for overlay dirty paints).
function Bank.GetLastRefreshedDirtyBags()
    return lastRefreshedDirty
end

--- "none" | "countOnly" | "identityChanged" | "unknown"
function Bank.GetLastChangeKind()
    return lastChangeKind
end

function Bank.GetLastAddedItemIDs()
    return lastAddedItemIDs
end

function Bank.GetLastRemovedItemIDs()
    return lastRemovedItemIDs
end

function Bank.GetCount(itemID, opts)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    LoadPersistedCounts()
    opts = opts or {}
    if opts.charges then
        return GetChargeAwareBankCount(itemID, opts)
    end

    local includeChar = opts.bank ~= false
    local includeWar = opts.warband ~= false
    local allowCached = opts.allowCached ~= false
    local live = Bank.IsOpen() or charAvailable or warAvailable

    if live then
        local n = 0
        if includeChar then
            if charAvailable or Bank.IsOpen() then
                Bank.Refresh()
                n = n + (charCounts and charCounts[itemID] or 0)
            elseif allowCached then
                n = n + (lastCharCounts[itemID] or 0)
            end
        end
        if includeWar then
            if warAvailable or (Bank.IsOpen() and Compat().HasWarbandBank()) then
                Bank.Refresh()
                n = n + (warCounts and warCounts[itemID] or 0)
            elseif allowCached then
                n = n + (lastWarCounts[itemID] or 0)
            end
        end
        return n
    end

    -- Bank closed: Blizzard API returns bank stacks without requiring a visit.
    if allowCached then
        local api = ApiBankOnlyCount(itemID, includeChar, includeWar, false)
        if api ~= nil then
            return api
        end
        return CachedStackCount(itemID, includeChar, includeWar)
    end
    return 0
end

function Bank.GetCharacterCounts(opts)
    LoadPersistedCounts()
    opts = opts or {}
    if charAvailable or Bank.IsOpen() then
        Bank.Refresh()
        return charCounts or {}
    end
    if opts.allowCached ~= false then
        return lastCharCounts
    end
    return {}
end

function Bank.GetWarbandCounts(opts)
    LoadPersistedCounts()
    opts = opts or {}
    if warAvailable or (Bank.IsOpen() and Compat().HasWarbandBank()) then
        Bank.Refresh()
        return warCounts or {}
    end
    if opts.allowCached ~= false then
        return lastWarCounts
    end
    return {}
end

function Bank.FindStacks(itemID, opts)
    itemID = tonumber(itemID)
    local out = {}
    if not itemID then
        return out
    end
    opts = opts or {}
    if not Bank.IsOpen() and not opts.force then
        return out
    end
    Bank.Refresh(opts)
    local containers = Containers()
    if opts.bank ~= false then
        for _, bag in ipairs(containers.GetCharacterBankIDs()) do
            local slots = charSlots[bag]
            if slots then
                for slot, rec in pairs(slots) do
                    if rec.itemID == itemID then
                        out[#out + 1] = { bag = bag, slot = slot, count = rec.count, region = "bank" }
                    end
                end
            end
        end
    end
    if opts.warband ~= false then
        for _, bag in ipairs(containers.GetWarbandBankIDs()) do
            local slots = warSlots[bag]
            if slots then
                for slot, rec in pairs(slots) do
                    if rec.itemID == itemID then
                        out[#out + 1] = { bag = bag, slot = slot, count = rec.count, region = "warband" }
                    end
                end
            end
        end
    end
    return out
end

--- Single pass over open bank/warband slots. Prefer this over FindStacks-per-ID.
function Bank.ForEachOpenStack(opts, fn)
    if type(fn) ~= "function" then
        return
    end
    opts = opts or {}
    if not Bank.IsOpen() and not opts.force then
        return
    end
    Bank.Refresh(opts)
    local containers = Containers()
    if opts.bank ~= false then
        for _, bag in ipairs(containers.GetCharacterBankIDs()) do
            local slots = charSlots[bag]
            if slots then
                for slot, rec in pairs(slots) do
                    if rec and rec.itemID then
                        fn(bag, slot, rec, "bank")
                    end
                end
            end
        end
    end
    if opts.warband ~= false then
        for _, bag in ipairs(containers.GetWarbandBankIDs()) do
            local slots = warSlots[bag]
            if slots then
                for slot, rec in pairs(slots) do
                    if rec and rec.itemID then
                        fn(bag, slot, rec, "warband")
                    end
                end
            end
        end
    end
end

function Bank.GetGeneration()
    return generation
end

function Bank.IsCharacterAvailable()
    return charAvailable or Bank.IsOpen()
end

function Bank.IsWarbandAvailable()
    return warAvailable or (Bank.IsOpen() and Compat().HasWarbandBank())
end

function Bank.HasWarband()
    return Compat().HasWarbandBank and Compat().HasWarbandBank() or false
end

function Bank.GetSnapshot(region)
    LoadPersistedCounts()
    region = region or "bank"
    if region == "warband" then
        if Bank.IsOpen() then
            Bank.Refresh()
        end
        return {
            counts = (warAvailable and warCounts) or lastWarCounts,
            available = warAvailable or Bank.IsOpen(),
            region = "warband",
        }
    end
    if Bank.IsOpen() then
        Bank.Refresh()
    end
    return {
        counts = (charAvailable and charCounts) or lastCharCounts,
        available = charAvailable or Bank.IsOpen(),
        region = "bank",
    }
end

_G.FluxInv = Inv
