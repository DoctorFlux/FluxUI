--[[
    Inventory/FluxInv/FluxInv_Actions.lua

    Restock-facing container mutations, bag iteration, automation quiet window,
    and bank open/close callbacks — all backed by FluxInv snapshots / Compat.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Bank = Inv.Bank or {}
local Bank = Inv.Bank

local Compat = function()
    return Inv.Compat
end

local C_UseContainerItem = (C_Container and C_Container.UseContainerItem) or _G.UseContainerItem
local C_SplitContainerItem = (C_Container and C_Container.SplitContainerItem) or _G.SplitContainerItem
local C_PickupContainerItem = (C_Container and C_Container.PickupContainerItem) or _G.PickupContainerItem

-- ---------------------------------------------------------------------------
-- Container read aliases (legacy FluxInventory names)
-- ---------------------------------------------------------------------------

function Inv.GetBagContainerIDs()
    return Inv.GetCarriedBagIDs()
end

function Inv.GetContainerNumSlots(bag)
    return Compat().GetContainerNumSlots(bag)
end

function Inv.GetContainerNumFreeSlots(bag)
    return Compat().GetContainerNumFreeSlots(bag)
end

function Inv.GetContainerItemInfo(bag, slot)
    return Compat().GetContainerItemInfo(bag, slot)
end

function Inv.GetContainerItemID(bag, slot)
    return Compat().GetContainerItemID(bag, slot)
end

function Inv.GetContainerItemLink(bag, slot)
    return Compat().GetContainerItemLink(bag, slot)
end

function Inv.FindBagStacks(itemID)
    return Inv.Bags and Inv.Bags.FindStacks(itemID) or {}
end

function Inv.FindFirstBagSlot(itemID)
    if not Inv.Bags or not Inv.Bags.FindFirst then
        return nil
    end
    return Inv.Bags.FindFirst(itemID)
end

function Inv.GetBagSnapshotGeneration()
    return Inv.Bags and Inv.Bags.GetGeneration and Inv.Bags.GetGeneration() or 0
end

function Inv.ForceRefreshBagCounts()
    if Inv.Bags then
        Inv.Bags.Invalidate()
        Inv.Bags.Refresh()
    end
end

--- Legacy FluxInventory.GetCount was bags-only when called with no opts.
--- Calls that pass opts (e.g. { charges = true }) use the Index multi-region path.
local indexGetCount = Inv.GetCount
function Inv.GetCount(itemID, opts)
    if opts == nil then
        return Inv.Bags and Inv.Bags.GetCount(itemID) or 0
    end
    return indexGetCount(itemID, opts)
end

function Inv.ForEachBagSlot(fn)
    if type(fn) ~= "function" or not Inv.Bags then
        return
    end
    Inv.Bags.Refresh()
    for _, bag in ipairs(Inv.GetCarriedBagIDs()) do
        local slots = Inv.Bags.GetSlots(bag)
        if slots then
            for slot, rec in pairs(slots) do
                fn(bag, slot, rec.itemID, rec.count)
            end
        end
    end
end

local KEYRING = _G.KEYRING_CONTAINER or -2

local function GetReagentBagID()
    if not (Inv.HasReagentBag and Inv.HasReagentBag()) then
        return nil
    end
    if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
        return Enum.BagIndex.ReagentBag
    end
    return _G.REAGENTBAG_CONTAINER or 5
end

--- Empty slots in one bag. When the free-slot API reports 0 on a non-empty
--- container, scan slots (combined-bags / backpack-full quirks can under-count).
function Inv.CountFreeSlotsInBag(bag)
    bag = tonumber(bag)
    if not bag then
        return 0, 0
    end
    local numSlots = Inv.GetContainerNumSlots(bag) or 0
    if numSlots <= 0 then
        return 0, 0
    end
    local free, family = Compat().GetContainerNumFreeSlots(bag)
    free = free or 0
    family = family or 0
    if free > 0 then
        return free, family
    end
    local empty = 0
    for slot = 1, numSlots do
        if not Inv.GetContainerItemInfo(bag, slot) then
            empty = empty + 1
        end
    end
    return empty, family
end

--- Total empty slots across player-carried bags.
--- opts.includeReagent (default true), opts.includeKeyring (default false),
--- opts.genericOnly (default false) — only bagFamily == 0 (Blizzard backpack count).
function Inv.GetTotalFreeBagSlots(opts)
    opts = opts or {}
    local includeReagent = opts.includeReagent ~= false
    local includeKeyring = opts.includeKeyring == true
    local genericOnly = opts.genericOnly == true
    local reagentID = GetReagentBagID()
    local total = 0
    for _, bag in ipairs(Inv.GetBagContainerIDs()) do
        if bag == KEYRING and not includeKeyring then
            -- skip keyring
        elseif reagentID and bag == reagentID and not includeReagent then
            -- skip reagent bag
        else
            local free, family = Inv.CountFreeSlotsInBag(bag)
            if not genericOnly or family == 0 then
                total = total + (free or 0)
            end
        end
    end
    return total
end

--- First empty player-bag slot (legacy FluxInventory name).
function Inv.GetFirstFreeBagSlot()
    for _, bag in ipairs(Inv.GetBagContainerIDs()) do
        if (Inv.CountFreeSlotsInBag(bag) or 0) > 0 then
            local numSlots = Inv.GetContainerNumSlots(bag) or 0
            for slot = 1, numSlots do
                if not Inv.GetContainerItemInfo(bag, slot) then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

function Inv.ItemExistsInInventory(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    if Inv.Bags and Inv.Bags.GetCount(itemID) > 0 then
        return true
    end
    if Bank.GetCount and Bank.GetCount(itemID) > 0 then
        return true
    end
    if C_Item and C_Item.GetItemCount then
        return (C_Item.GetItemCount(itemID, false, false, true) or 0) > 0
    end
    return false
end

function Inv.IsBankContainer(bag)
    return Inv.Containers and Inv.Containers.IsBankContainer(bag) or false
end

-- ---------------------------------------------------------------------------
-- Container mutations
-- ---------------------------------------------------------------------------

function Inv.PickupContainerItem(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if bag and slot then
        local lock = _G.FluxRespec and _G.FluxRespec.GearSetLock
        if lock and lock.ShouldBlockContainerPickup and lock.ShouldBlockContainerPickup(bag, slot) then
            if lock.NotifyBlocked then
                lock.NotifyBlocked()
            end
            return
        end
    end
    if C_PickupContainerItem then
        C_PickupContainerItem(bag, slot)
    end
end

function Inv.UseContainerItem(bag, slot, bankType)
    if not C_UseContainerItem then
        return
    end
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return
    end
    local lock = _G.FluxRespec and _G.FluxRespec.GearSetLock
    if lock and lock.ShouldBlockContainerUse and lock.ShouldBlockContainerUse(bag, slot) then
        if lock.NotifyBlocked then
            lock.NotifyBlocked()
        end
        return
    end
    local reagentBank = _G.REAGENTBANK_CONTAINER or -3
    if bag == reagentBank then
        pcall(C_UseContainerItem, bag, slot, nil, nil, true)
        return
    end
    if not bankType and Bank.IsBankContainer and Bank.GetBankTypeForContainer
        and Bank.IsBankContainer(bag) then
        bankType = Bank.GetBankTypeForContainer(bag)
    end
    if bankType then
        pcall(C_UseContainerItem, bag, slot, nil, bankType, false)
        return
    end
    local ok = pcall(C_UseContainerItem, bag, slot, nil, nil)
    if not ok then
        pcall(C_UseContainerItem, bag, slot)
    end
end

function Inv.SplitContainerItemPending(bag, slot, countBefore, splitAmount)
    bag = tonumber(bag)
    slot = tonumber(slot)
    countBefore = tonumber(countBefore) or 0
    splitAmount = tonumber(splitAmount)
    if not bag or not slot or countBefore <= 1 then
        return false
    end
    if _G.CursorHasItem and _G.CursorHasItem() then
        return false
    end
    if GetCursorInfo then
        local cursorType = GetCursorInfo()
        if cursorType == "item" then
            return false
        end
    end
    local afterInfo = Inv.GetContainerItemInfo(bag, slot)
    local afterCount = afterInfo and (afterInfo.count or 0) or countBefore
    if afterCount <= 0 then
        return false
    end
    if splitAmount and splitAmount > 0 and afterCount == countBefore - splitAmount then
        return false
    end
    return afterCount > 0 and afterCount < countBefore
end

function Inv.SplitContainerItem(bag, slot, amount)
    bag = tonumber(bag)
    slot = tonumber(slot)
    amount = math.floor(tonumber(amount) or 0)
    if not bag or not slot or amount <= 0 or not C_SplitContainerItem then
        return false
    end
    local info = Inv.GetContainerItemInfo(bag, slot)
    if not info or not info.itemID then
        return false
    end
    local countBefore = info.count or 0
    if amount >= countBefore then
        Inv.PickupContainerItem(bag, slot)
        return true
    end
    pcall(C_SplitContainerItem, bag, slot, amount)
    if _G.CursorHasItem and _G.CursorHasItem() then
        return true
    end
    if GetCursorInfo then
        local cursorType = GetCursorInfo()
        if cursorType == "item" then
            return true
        end
    end
    return Inv.SplitContainerItemPending(bag, slot, countBefore, amount)
end

-- ---------------------------------------------------------------------------
-- Merchant + automation quiet
-- ---------------------------------------------------------------------------

local merchantOpen = false
local automationQuietUntil = 0
local quietSettleCallbacks = {}
local quietSettleTimer = nil

function Inv.SetMerchantOpen(isOpen)
    merchantOpen = not not isOpen
end

function Inv.IsMerchantOpen()
    return merchantOpen
end

local function isMoverRunning()
    local mover = _G.FluxItemMover
    return mover and mover.IsRunning and mover.IsRunning() or false
end

function Inv.IsAutomationQuiet()
    return GetTime() < automationQuietUntil or isMoverRunning()
end

local function fireQuietSettled()
    quietSettleTimer = nil
    if Inv.IsAutomationQuiet() then
        quietSettleTimer = true
        Compat().After(0.25, fireQuietSettled)
        return
    end
    local cbs = quietSettleCallbacks
    quietSettleCallbacks = {}
    for i = 1, #cbs do
        pcall(cbs[i])
    end
end

function Inv.NotifyAutomationPulse(seconds)
    local untilTime = GetTime() + (tonumber(seconds) or 0.35)
    if untilTime > automationQuietUntil then
        automationQuietUntil = untilTime
    end
    if not quietSettleTimer and #quietSettleCallbacks > 0 then
        quietSettleTimer = true
        Compat().After(0.3, fireQuietSettled)
    end
end

function Inv.OnQuietSettled(fn)
    if type(fn) ~= "function" then
        return
    end
    if not Inv.IsAutomationQuiet() then
        fn()
        return
    end
    quietSettleCallbacks[#quietSettleCallbacks + 1] = fn
    if not quietSettleTimer then
        quietSettleTimer = true
        Compat().After(0.3, fireQuietSettled)
    end
end

-- ---------------------------------------------------------------------------
-- Bag storm (loot / craft / multi-receive coalesce)
-- ---------------------------------------------------------------------------

local bagStormUntil = 0
local STORM_HOLD = 0.25
local stormSettleOneShots = {}
local stormSettlePermanent = {} -- key -> fn
local stormSettleTimer = nil

local function fireStormSettled()
    stormSettleTimer = nil
    if Inv.IsBagStorm() then
        stormSettleTimer = true
        Compat().After(0.2, fireStormSettled)
        return
    end
    local ones = stormSettleOneShots
    stormSettleOneShots = {}
    for i = 1, #ones do
        pcall(ones[i])
    end
    for _, fn in pairs(stormSettlePermanent) do
        pcall(fn)
    end
end

function Inv.NotifyBagStorm(seconds)
    local untilTime = GetTime() + (tonumber(seconds) or STORM_HOLD)
    if untilTime > bagStormUntil then
        bagStormUntil = untilTime
    end
    if not stormSettleTimer then
        stormSettleTimer = true
        Compat().After((tonumber(seconds) or STORM_HOLD) + 0.05, fireStormSettled)
    end
end

function Inv.IsBagStorm()
    return GetTime() < bagStormUntil
end

--- One-shot callback when the current bag storm settles.
function Inv.OnStormSettled(fn)
    if type(fn) ~= "function" then
        return
    end
    if not Inv.IsBagStorm() then
        fn()
        return
    end
    stormSettleOneShots[#stormSettleOneShots + 1] = fn
    if not stormSettleTimer then
        stormSettleTimer = true
        Compat().After(0.3, fireStormSettled)
    end
end

--- Permanent storm-settle listener (key coalesces).
function Inv.RegisterStormSettled(key, fn)
    if type(key) ~= "string" or type(fn) ~= "function" then
        return
    end
    stormSettlePermanent[key] = fn
end

function Inv.UnregisterStormSettled(key)
    stormSettlePermanent[key] = nil
end

function Inv.ShouldDeferHeavyWork()
    return Inv.IsAutomationQuiet()
        or Inv.IsBankOpen()
        or merchantOpen
        or Inv.IsBagStorm()
end

function Inv.NotifyItemsRemoved(idSet)
    if type(idSet) ~= "table" then
        return
    end
    if Inv.Bags then
        Inv.Bags.Invalidate()
        Inv.Bags.Refresh()
    end
    if Inv.Events and Inv.Events.Pulse then
        Inv.Events.Pulse("scan", { "bags" })
    end
end

function Inv.FlushExtraButtonIdentityRefresh()
    local EB = _G.FluxExtraButtons
    if EB and EB.FlushIdentityRefresh then
        pcall(EB.FlushIdentityRefresh)
    end
end

-- ---------------------------------------------------------------------------
-- Bank extensions (legacy FluxBank names used by Restock)
-- ---------------------------------------------------------------------------

local bankOpenCallbacks = {}
local bankCloseCallbacks = {}
local wasBankOpen = false

function Bank.GetContainerIDs()
    local ids = {}
    local seen = {}
    local function append(list)
        if type(list) ~= "table" then
            return
        end
        for _, id in ipairs(list) do
            id = tonumber(id)
            if id and not seen[id] then
                seen[id] = true
                ids[#ids + 1] = id
            end
        end
    end
    append(Inv.GetCharacterBankIDs and Inv.GetCharacterBankIDs())
    if Inv.HasWarbandBank and Inv.HasWarbandBank() then
        append(Inv.GetWarbandBankIDs and Inv.GetWarbandBankIDs())
    end
    return ids
end

function Bank.IsModernBank()
    return Inv.IsModernBank and Inv.IsModernBank() or false
end

function Bank.HasLegacyBankBags()
    return Inv.HasLegacyBankBags and Inv.HasLegacyBankBags() or false
end

function Bank.HasReagentBag()
    return Inv.HasReagentBag and Inv.HasReagentBag() or false
end

function Bank.IsBankContainer(bag)
    return Inv.Containers and Inv.Containers.IsBankContainer(bag) or false
end

function Bank.GetBankTypeForContainer(bag)
    if Inv.Containers and Inv.Containers.GetBankTypeForContainer then
        return Inv.Containers.GetBankTypeForContainer(bag)
    end
    if not (Enum and Enum.BankType and C_Bank and C_Bank.FetchPurchasedBankTabIDs) then
        return nil
    end
    bag = tonumber(bag)
    if not bag or not Bank.IsBankContainer(bag) then
        return nil
    end
    local ok, accountTabs = pcall(C_Bank.FetchPurchasedBankTabIDs, Enum.BankType.Account)
    if ok and type(accountTabs) == "table" then
        for _, id in ipairs(accountTabs) do
            if id == bag then
                return Enum.BankType.Account
            end
        end
    end
    return Enum.BankType.Character
end

function Bank.RegisterBankOpen(key, fn)
    if type(key) == "string" and type(fn) == "function" then
        bankOpenCallbacks[key] = fn
    end
end

function Bank.RegisterBankClose(key, fn)
    if type(key) == "string" and type(fn) == "function" then
        bankCloseCallbacks[key] = fn
    end
end

function Bank.RefreshIfOpen()
    if not Bank.IsOpen() then
        return
    end
    -- Do not Invalidate: BAG_UPDATE already MarkDirty'd changed bags.
    Bank.Refresh()
end

function Bank.RequestLiveRefresh()
    if not Bank.IsOpen() then
        return
    end
    Bank.Refresh()
end

function Bank.SchedulePersist()
    if Bank.Persist then
        Bank.Persist()
    end
end

function Bank.ForEachSlot(fn)
    if type(fn) ~= "function" or not Bank.IsOpen() then
        return
    end
    Bank.Refresh()
    for _, bag in ipairs(Bank.GetContainerIDs()) do
        local numSlots = Inv.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = Inv.GetContainerItemInfo(bag, slot)
            if info then
                fn(bag, slot, info)
            end
        end
    end
end

function Bank.GetItemLink(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    local stacks = Bank.FindStacks(itemID, { force = true })
    local stack = stacks and stacks[1]
    if stack and stack.bag and stack.slot then
        return Inv.GetContainerItemLink(stack.bag, stack.slot)
    end
    if Inv.Bags and Inv.Bags.GetUniqueItems then
        local u = Inv.Bags.GetUniqueItems()[itemID]
        if u and u.link then
            return u.link
        end
    end
    return nil
end

--- Called from Events when bank open state flips.
function Inv.NotifyBankOpenChanged(isOpen)
    isOpen = not not isOpen
    if isOpen and not wasBankOpen then
        wasBankOpen = true
        for _, fn in pairs(bankOpenCallbacks) do
            pcall(fn)
        end
    elseif not isOpen and wasBankOpen then
        wasBankOpen = false
        for _, fn in pairs(bankCloseCallbacks) do
            pcall(fn)
        end
    end
end

_G.FluxInv = Inv

-- Boot events after Actions (merchant/bank callbacks + GetCount wrap) are installed.
if Inv.Events and Inv.Events.Init then
    Inv.Events.Init()
end
