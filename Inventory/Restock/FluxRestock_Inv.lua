-- Inventory/Restock/FluxRestock_Inv.lua
-- Restock/junk/vendor/bank facts and live slot mutations over Flux.Inventory.
local addonName, ns = ...
local Flux = ns.Flux

FluxRestock = FluxRestock or {}
_G.FluxRestock = FluxRestock
local RI = {}
FluxRestock.Inv = RI

local KEYRING = _G.KEYRING_CONTAINER
local function ReagentBankID()
    local Cap = Flux and Flux.Cap
    if Cap and Cap.GetReagentBankContainerID then
        return Cap.GetReagentBankContainerID()
    end
    if Cap and Cap.HasReagentBankContainer and not Cap.HasReagentBankContainer() then
        return nil
    end
    local id = rawget(_G, "REAGENTBANK_CONTAINER")
    if type(id) == "number" and not (Cap and Cap.IsBankTabSentinel and Cap.IsBankTabSentinel(id)) then
        return id
    end
    return nil
end

local bankWatch = false
local lastBankOpen = nil
local lastFireOpenAt = 0
local openScanGen = 0
local restockListeners = {}
local bankOpenCallbacks = {}
local bankCloseCallbacks = {}
local EnsureBankWatch

local merchantOpen = false
local automationQuietUntil = 0
local quietSettleCallbacks = {}
local quietSettleTimer = nil
local bagStormUntil = 0
local STORM_HOLD = 0.25
local stormSettleOneShots = {}
local stormSettlePermanent = {}
local stormSettleTimer = nil

local function After(delay, fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

local function API()
    return Flux and Flux.Inventory
end

local function Containers()
    local api = API()
    return api and api.Containers
end

local function Container()
    return Flux and Flux.Container
end

-- Vendor junk sells from carried bags, including the reagent bag. Skip only
-- containers that cannot be sold from (keyring / reagent bank).
local function SkipSellBag(bag)
    local C = Containers()
    if not C then
        return false
    end
    if C.IsKeyringBag and C.IsKeyringBag(bag) then
        return true
    end
    if C.IsReagentBank and C.IsReagentBank(bag) then
        return true
    end
    return false
end

local function SkipBankWalkBag(bag)
    local C = Containers()
    if C and C.IsKeyringBag and C.IsKeyringBag(bag) then
        return true
    end
    return false
end

function RI.API()
    return API()
end

function RI.IsReady()
    local api = API()
    return api and api.IsReady and api.IsReady() or false
end

function RI.IsReliable()
    local api = API()
    if api and api.IsReliable then
        return api.IsReliable()
    end
    return RI.IsReady()
end

function RI.IsBankOpen()
    local api = API()
    if api and api.IsBankOpen and api.IsBankOpen() then
        return true
    end
    -- Backup FluxInv.Bank.IsOpen: BankFrame shown is enough (no slot probe).
    if _G.BankFrame and _G.BankFrame.IsShown and _G.BankFrame:IsShown() then
        return true
    end
    if api and api.IsBaganatorBankViewShown and api.IsBaganatorBankViewShown() then
        return true
    end
    local C = Containers()
    return C and C.IsBankReadable and C.IsBankReadable() or false
end

--- Live banker only. Cached Baganator alt views are "open" for display, not for moves.
function RI.IsBankLive()
    local api = API()
    if api and api.IsBankLive then
        return api.IsBankLive() and true or false
    end
    if api and api.IsBaganatorBankLiveShown and api.IsBaganatorBankLiveShown() then
        return true
    end
    if api and api.IsBaganatorBankViewShown and api.IsBaganatorBankViewShown() then
        return false
    end
    return RI.IsBankOpen()
end

function RI.HasWarband()
    local api = API()
    return api and api.HasWarband and api.HasWarband() or false
end
RI.HasWarbandBank = RI.HasWarband

function RI.GetCarriedBagIDs()
    local C = Containers()
    if C and C.GetCarriedBagIDs then
        return C.GetCarriedBagIDs()
    end
    return { 0, 1, 2, 3, 4 }
end

function RI.GetBagContainerIDs()
    local ids, out = RI.GetCarriedBagIDs(), {}
    for i = 1, #ids do
        local bag = ids[i]
        if not SkipSellBag(bag) then
            out[#out + 1] = bag
        end
    end
    return out
end

function RI.GetPlayerRestockBagIDs()
    local C = Containers()
    if C and C.GetPlayerRestockBagIDs then
        return C.GetPlayerRestockBagIDs()
    end
    return { 0, 1, 2, 3, 4 }
end

function RI.GetCharacterBankIDs()
    local C = Containers()
    if C and C.GetCharacterBankIDs then
        return C.GetCharacterBankIDs()
    end
    return {}
end

function RI.GetWarbandBankIDs()
    local C = Containers()
    if C and C.GetWarbandBankIDs then
        return C.GetWarbandBankIDs()
    end
    return {}
end

local function Snap(region)
    local api = API()
    return api and api.snapshots and api.snapshots[region]
end

local function SnapCounts(region)
    local snap = Snap(region)
    return snap and snap.counts or {}
end

local function SnapByBag(region)
    local snap = Snap(region)
    return snap and snap.byBag
end

function RI.GetCount(itemID, opts)
    local api = API()
    itemID = tonumber(itemID)
    if not itemID or not api then
        return 0
    end
    if opts and opts.includeBank == true then
        opts = {
            bags = opts.bags ~= false,
            bank = true,
            warband = opts.warband ~= false and RI.HasWarband() or false,
            equipped = opts.equipped == true,
            charges = opts.charges,
        }
    end
    if opts == nil then
        if api.GetCount then
            return api.GetCount(itemID, { bags = true, bank = false, warband = false }) or 0
        end
        return 0
    end
    if opts.charges and api.GetLiveCount then
        return api.GetLiveCount(itemID, opts) or 0
    end
    if api.GetCount then
        return api.GetCount(itemID, opts) or 0
    end
    return 0
end
RI.GetItemCount = RI.GetCount

function RI.GetLiveCount(itemID, opts)
    local api = API()
    if api and api.GetLiveCount then
        return api.GetLiveCount(itemID, opts) or 0
    end
    return RI.GetCount(itemID, opts)
end

function RI.GetUniqueItems(opts)
    local api = API()
    if api and api.GetUniqueItems then
        return api.GetUniqueItems(opts or { bags = true, bank = false, warband = false })
    end
    return {}
end

-- Backup FluxInv.Bags.GetUniqueItems. Tiers/restock still look here.
RI.Bags = RI.Bags or {}
function RI.Bags.GetUniqueItems()
    return RI.GetUniqueItems({ bags = true, bank = false, warband = false })
end

function RI.ForEachLocation(fn, opts)
    local api = API()
    if api and api.ForEachLocation then
        api.ForEachLocation(fn, opts)
    end
end

function RI.Find(itemID, opts)
    local api = API()
    if api and api.Find then
        return api.Find(itemID, opts)
    end
    return {}
end

function RI.GetFirst(itemID, opts)
    local api = API()
    if api and api.GetFirst then
        return api.GetFirst(itemID, opts)
    end
    return nil
end

function RI.GetBagSnapshotGeneration()
    local api = API()
    if api and api.GetBagGeneration then
        return api.GetBagGeneration()
    end
    if api and api.GetSnapshotGeneration then
        return api.GetSnapshotGeneration("bags")
    end
    return 0
end

function RI.GetFirstFreeBagSlot()
    local api = API()
    if api and api.GetFirstFreeBagSlot then
        return api.GetFirstFreeBagSlot()
    end
    local C = Container()
    for _, bag in ipairs(RI.GetBagContainerIDs()) do
        local n = C and C.GetNumSlots and C.GetNumSlots(bag) or 0
        for slot = 1, n do
            if not RI.GetContainerItemID(bag, slot) then
                return bag, slot
            end
        end
    end
    return nil, nil
end

function RI.FindFirstBagSlot(itemID)
    local loc = RI.GetFirst(itemID, { bags = true, bank = false, warband = false, equipped = false })
    if loc and loc.bag and loc.slot and not SkipSellBag(loc.bag) then
        return loc.bag, loc.slot
    end
    return nil, nil
end

function RI.FindBagStacks(itemID)
    itemID = tonumber(itemID)
    local out = {}
    if not itemID then
        return out
    end
    -- Live C_Container walk (backup FluxInv.Bags.FindStacks). Snapshot Find
    -- missed stacks during restock, so splits had no merge dest.
    for _, bag in ipairs(RI.GetBagContainerIDs()) do
        if not SkipSellBag(bag) then
            local n = RI.GetContainerNumSlots(bag) or 0
            for slot = 1, n do
                local info = RI.GetContainerItemInfo(bag, slot)
                if info and tonumber(info.itemID) == itemID and (tonumber(info.count) or 0) > 0 then
                    out[#out + 1] = {
                        bag = bag,
                        slot = slot,
                        count = info.count or 0,
                        region = "bags",
                        itemID = itemID,
                        locked = info.locked,
                    }
                end
            end
        end
    end
    return out
end

function RI.ForEachBagSlot(fn)
    if type(fn) ~= "function" then
        return
    end
    local byBag = SnapByBag("bags")
    if not byBag then
        return
    end
    for _, bag in ipairs(RI.GetBagContainerIDs()) do
        local slots = byBag[bag]
        if slots then
            for slot, rec in pairs(slots) do
                if rec and rec.itemID then
                    fn(bag, slot, rec.itemID, rec.count)
                end
            end
        end
    end
end

function RI.GetContainerNumSlots(bag)
    local C = Container()
    if C and C.GetNumSlots then
        return C.GetNumSlots(bag) or 0
    end
    return 0
end

function RI.GetContainerNumFreeSlots(bag)
    local C = Container()
    if C and C.GetNumFreeSlots then
        return C.GetNumFreeSlots(bag) or 0
    end
    return 0
end

function RI.CountFreeSlotsInBag(bag)
    bag = tonumber(bag)
    if not bag then
        return 0, 0
    end
    local n = RI.GetContainerNumSlots(bag)
    if n <= 0 then
        return 0, 0
    end
    local C = Container()
    local free, family = 0, 0
    if C and C.GetNumFreeSlots then
        free = C.GetNumFreeSlots(bag) or 0
    end
    if free > 0 then
        return free, family
    end
    local empty = 0
    for slot = 1, n do
        if not RI.GetContainerItemInfo(bag, slot) then
            empty = empty + 1
        end
    end
    return empty, family
end

function RI.GetTotalFreeBagSlots(opts)
    opts = opts or {}
    local includeReagent = opts.includeReagent ~= false
    local includeKeyring = opts.includeKeyring == true
    local C = Containers()
    local reagentID = C and C.GetReagentBagID and C.GetReagentBagID()
    local total = 0
    for _, bag in ipairs(RI.GetCarriedBagIDs()) do
        local isKeyring = (C and C.IsKeyringBag and C.IsKeyringBag(bag))
            or (KEYRING and bag == KEYRING)
        if isKeyring and not includeKeyring then
            -- skip
        elseif reagentID and bag == reagentID and not includeReagent then
            -- skip
        else
            total = total + (RI.CountFreeSlotsInBag(bag) or 0)
        end
    end
    return total
end

local function NormalizeItemInfo(info)
    if not info then
        return nil
    end
    local Secrets = Flux and Flux.Secrets
    local itemID = info.itemID ~= nil and tonumber(info.itemID) or nil
    if (not itemID or itemID <= 0) and Secrets and Secrets.SafeGetNumber then
        local n = Secrets.SafeGetNumber(info.itemID, 0)
        if n and n > 0 then
            itemID = n
        end
    end
    if not itemID then
        local link = info.hyperlink or info.link
        if type(link) == "string" then
            itemID = tonumber(string.match(link, "item:(%d+)"))
        end
    end
    if not itemID then
        itemID = info.itemID
    end
    if not itemID then
        return nil
    end
    local count = tonumber(info.stackCount) or tonumber(info.count)
    if (not count or count <= 0) and Secrets and Secrets.SafeGetNumber then
        count = Secrets.SafeGetNumber(info.stackCount, 0)
        if not count or count <= 0 then
            count = Secrets.SafeGetNumber(info.count, 0)
        end
    end
    if not count or count <= 0 then
        count = 1
    end
    local hyperlink = info.hyperlink or info.link
    local locked = false
    if Secrets and Secrets.SafeBooleanTest then
        locked = Secrets.SafeBooleanTest(info.isLocked, false) == true
            or Secrets.SafeBooleanTest(info.locked, false) == true
    elseif info.isLocked == true or info.locked == true then
        locked = true
    end
    local noValue = false
    if Secrets and Secrets.SafeBooleanTest then
        noValue = Secrets.SafeBooleanTest(info.hasNoValue, false) == true
            or Secrets.SafeBooleanTest(info.noValue, false) == true
    elseif info.hasNoValue == true or info.noValue == true then
        noValue = true
    end
    return {
        itemID = itemID,
        count = count,
        locked = locked,
        quality = info.quality,
        hyperlink = hyperlink,
        link = hyperlink,
        noValue = noValue,
    }
end

function RI.GetContainerItemInfo(bag, slot)
    local C = Container()
    if C and C.GetItemInfo then
        return NormalizeItemInfo(C.GetItemInfo(bag, slot))
    end
    return nil
end

function RI.GetContainerItemID(bag, slot)
    local C = Container()
    if C and C.GetItemID then
        local raw = C.GetItemID(bag, slot)
        if raw ~= nil then
            local id = tonumber(raw)
            if id and id > 0 then
                return id
            end
        end
    end
    local info = RI.GetContainerItemInfo(bag, slot)
    if info and info.itemID ~= nil then
        return tonumber(info.itemID) or info.itemID
    end
    return nil
end

function RI.GetContainerItemLink(bag, slot)
    local info = RI.GetContainerItemInfo(bag, slot)
    if info and (info.hyperlink or info.link) then
        return info.hyperlink or info.link
    end
    local C = Container()
    if C and C.GetItemLink then
        return C.GetItemLink(bag, slot)
    end
    return nil
end

function RI.ItemExistsInInventory(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    if RI.GetCount(itemID) > 0 then
        return true
    end
    if RI.Bank and RI.Bank.GetCount and RI.Bank.GetCount(itemID) > 0 then
        return true
    end
    if C_Item and C_Item.GetItemCount then
        return (C_Item.GetItemCount(itemID, false, false, true) or 0) > 0
    end
    return false
end

function RI.IsBankContainer(bag)
    local C = Containers()
    return C and C.IsBankContainer and C.IsBankContainer(bag) or false
end

local function GearSetLock()
    return _G.FluxRespec and _G.FluxRespec.GearSetLock
end

function RI.PickupContainerItem(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    local lock = GearSetLock()
    if bag and slot and lock and lock.ShouldBlockContainerPickup and lock.ShouldBlockContainerPickup(bag, slot) then
        if lock.NotifyBlocked then
            lock.NotifyBlocked()
        end
        return
    end
    local C = Container()
    if C and C.PickupItem then
        C.PickupItem(bag, slot)
    end
end

local lastBankUse = {}

local function SlotStackCount(bag, slot)
    local info = RI.GetContainerItemInfo(bag, slot)
    if info then
        return tonumber(info.count) or 0, tonumber(info.itemID)
    end
    local id = RI.GetContainerItemID and RI.GetContainerItemID(bag, slot)
    id = tonumber(id)
    if id then
        return 1, id
    end
    return 0, nil
end

function RI.GetLastBankUse()
    return lastBankUse
end

function RI.NoteBankUseAfter(bag, slot)
    bag, slot = tonumber(bag), tonumber(slot)
    if lastBankUse.bag ~= bag or lastBankUse.slot ~= slot then
        return
    end
    lastBankUse.after = SlotStackCount(bag, slot)
    lastBankUse.afterAt = (GetTime and GetTime()) or 0
end

function RI.UseContainerItem(bag, slot, _bankType)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return
    end
    local lock = GearSetLock()
    if lock and lock.ShouldBlockContainerUse and lock.ShouldBlockContainerUse(bag, slot) then
        if lock.NotifyBlocked then
            lock.NotifyBlocked()
        end
        return
    end
    local before, itemID = SlotStackCount(bag, slot)
    lastBankUse.bag = bag
    lastBankUse.slot = slot
    lastBankUse.itemID = itemID
    lastBankUse.before = before
    lastBankUse.after = before
    lastBankUse.ok = nil
    lastBankUse.err = nil
    lastBankUse.api = nil
    lastBankUse.at = (GetTime and GetTime()) or 0

    local function run(apiName, fn, ...)
        lastBankUse.api = apiName
        local ok, err = pcall(fn, ...)
        lastBankUse.ok = ok
        if not ok then
            lastBankUse.err = tostring(err)
        end
    end

    -- Character/warband bank uses bankType so UseContainerItem takes the stack
    -- out. Reagent bank (not Forever Accountbanktab -3) uses the 5th arg.
    local reagentBank = ReagentBankID()
    if reagentBank and bag == reagentBank then
        local use = Container() and Container().UseItem
        if C_Container and C_Container.UseContainerItem then
            run("C_Container.UseContainerItem", C_Container.UseContainerItem, bag, slot, nil, nil, true)
        elseif use then
            run("Flux.Container.UseItem", use, bag, slot, nil, nil, true)
        elseif UseContainerItem then
            run("UseContainerItem", UseContainerItem, bag, slot)
        end
        lastBankUse.after = SlotStackCount(bag, slot)
        return
    end
    local bankType = _bankType
    if not bankType and RI.IsBankContainer(bag) then
        local C = Containers()
        if C and C.GetBankTypeForContainer then
            bankType = C.GetBankTypeForContainer(bag)
        end
    end
    if bankType then
        if C_Container and C_Container.UseContainerItem then
            run("C_Container.UseContainerItem", C_Container.UseContainerItem, bag, slot, nil, bankType, false)
        elseif UseContainerItem then
            run("UseContainerItem", UseContainerItem, bag, slot)
        end
        lastBankUse.after = SlotStackCount(bag, slot)
        return
    end
    if C_Container and C_Container.UseContainerItem then
        local ok = pcall(C_Container.UseContainerItem, bag, slot, nil, nil)
        lastBankUse.api = "C_Container.UseContainerItem"
        lastBankUse.ok = ok
        if not ok then
            ok = pcall(C_Container.UseContainerItem, bag, slot)
            lastBankUse.ok = ok
        end
        if not ok and UseContainerItem then
            run("UseContainerItem", UseContainerItem, bag, slot)
        end
    elseif UseContainerItem then
        run("UseContainerItem", UseContainerItem, bag, slot)
    else
        local use = Container() and Container().UseItem
        if use then
            run("Flux.Container.UseItem", use, bag, slot, nil, nil)
        end
    end
    lastBankUse.after = SlotStackCount(bag, slot)
end

function RI.SplitContainerItemPending(bag, slot, countBefore, splitAmount)
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
    local afterInfo = RI.GetContainerItemInfo(bag, slot)
    local afterCount = afterInfo and (afterInfo.count or 0) or countBefore
    if afterCount <= 0 then
        return false
    end
    if splitAmount and splitAmount > 0 and afterCount == countBefore - splitAmount then
        return false
    end
    return afterCount > 0 and afterCount < countBefore
end

function RI.SplitContainerItem(bag, slot, amount)
    bag = tonumber(bag)
    slot = tonumber(slot)
    amount = math.floor(tonumber(amount) or 0)
    if not bag or not slot or amount <= 0 then
        return false
    end
    local info = RI.GetContainerItemInfo(bag, slot)
    if not info or not info.itemID then
        return false
    end
    local countBefore = info.count or 0
    if amount >= countBefore then
        RI.PickupContainerItem(bag, slot)
        return true
    end
    local C = Container()
    if C and C.SplitItem then
        pcall(C.SplitItem, bag, slot, amount)
    elseif C_Container and C_Container.SplitContainerItem then
        pcall(C_Container.SplitContainerItem, bag, slot, amount)
    elseif SplitContainerItem then
        pcall(SplitContainerItem, bag, slot, amount)
    end
    if _G.CursorHasItem and _G.CursorHasItem() then
        return true
    end
    if GetCursorInfo then
        local cursorType = GetCursorInfo()
        if cursorType == "item" then
            return true
        end
    end
    return RI.SplitContainerItemPending(bag, slot, countBefore, amount)
end

function RI.SetMerchantOpen(isOpen)
    merchantOpen = not not isOpen
end

function RI.IsMerchantOpen()
    if merchantOpen then
        return true
    end
    local mf = rawget(_G, "MerchantFrame")
    return mf and mf.IsShown and mf:IsShown() and true or false
end

local function isMoverRunning()
    local mover = _G.FluxItemMover
    return mover and mover.IsRunning and mover.IsRunning() or false
end

function RI.IsAutomationQuiet()
    return GetTime() < automationQuietUntil or isMoverRunning()
end

local function fireQuietSettled()
    quietSettleTimer = nil
    if RI.IsAutomationQuiet() then
        quietSettleTimer = true
        After(0.25, fireQuietSettled)
        return
    end
    local cbs = quietSettleCallbacks
    quietSettleCallbacks = {}
    for i = 1, #cbs do
        pcall(cbs[i])
    end
end

function RI.NotifyAutomationPulse(seconds)
    local untilTime = GetTime() + (tonumber(seconds) or 0.35)
    if untilTime > automationQuietUntil then
        automationQuietUntil = untilTime
    end
    if not quietSettleTimer and #quietSettleCallbacks > 0 then
        quietSettleTimer = true
        After(0.3, fireQuietSettled)
    end
end

function RI.OnQuietSettled(fn)
    if type(fn) ~= "function" then
        return
    end
    if not RI.IsAutomationQuiet() then
        fn()
        return
    end
    quietSettleCallbacks[#quietSettleCallbacks + 1] = fn
    if not quietSettleTimer then
        quietSettleTimer = true
        After(0.3, fireQuietSettled)
    end
end

function RI.IsBagStorm()
    return GetTime() < bagStormUntil
end

local function fireStormSettled()
    stormSettleTimer = nil
    if RI.IsBagStorm() then
        stormSettleTimer = true
        After(0.2, fireStormSettled)
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

function RI.NotifyBagStorm(seconds)
    local untilTime = GetTime() + (tonumber(seconds) or STORM_HOLD)
    if untilTime > bagStormUntil then
        bagStormUntil = untilTime
    end
    if not stormSettleTimer then
        stormSettleTimer = true
        After((tonumber(seconds) or STORM_HOLD) + 0.05, fireStormSettled)
    end
end

function RI.OnStormSettled(fn)
    if type(fn) ~= "function" then
        return
    end
    if not RI.IsBagStorm() then
        fn()
        return
    end
    stormSettleOneShots[#stormSettleOneShots + 1] = fn
    if not stormSettleTimer then
        stormSettleTimer = true
        After(0.3, fireStormSettled)
    end
end

function RI.RegisterStormSettled(key, fn)
    if type(key) ~= "string" or type(fn) ~= "function" then
        return
    end
    stormSettlePermanent[key] = fn
end

function RI.UnregisterStormSettled(key)
    stormSettlePermanent[key] = nil
end

function RI.ShouldDeferHeavyWork()
    return RI.IsAutomationQuiet()
        or RI.IsBankOpen()
        or RI.IsMerchantOpen()
        or RI.IsBagStorm()
end

function RI.NotifyItemsRemoved(_idSet)
end

function RI.ForceRefreshBagCounts()
end

function RI.FlushExtraButtonIdentityRefresh()
    local EB = _G.FluxExtraButtons
    if EB and EB.FlushIdentityRefresh then
        pcall(EB.FlushIdentityRefresh)
    end
end

RI.Containers = {
    Invalidate = function()
        local C = Containers()
        if C and C.Invalidate then
            C.Invalidate()
        end
    end,
}

RI.Bags = {
    GetCount = function(itemID)
        return RI.GetCount(itemID)
    end,
    IsReady = function()
        return RI.IsReady()
    end,
    IsReliable = function()
        return RI.IsReliable()
    end,
    GetGeneration = function()
        return RI.GetBagSnapshotGeneration()
    end,
    GetUniqueItems = function(opts)
        return RI.GetUniqueItems(opts or { bags = true, bank = false, warband = false })
    end,
    FindStacks = function(itemID)
        return RI.FindBagStacks(itemID)
    end,
    FindFirst = function(itemID)
        return RI.FindFirstBagSlot(itemID)
    end,
}

local Bank = {}
RI.Bank = Bank

local restockRefreshGen = 0
local liveCountGen
local liveCountBank = {}
local liveCountWar = {}

function Bank.IsOpen()
    if RI.IsBankOpen() then
        return true
    end
    if _G.BankFrame and _G.BankFrame.IsShown and _G.BankFrame:IsShown() then
        return true
    end
    local api = API()
    if api and api.IsBaganatorBankViewShown and api.IsBaganatorBankViewShown() then
        return true
    end
    return false
end

function Bank.IsLive()
    return RI.IsBankLive() and true or false
end

function Bank.GetContainerIDs()
    if not Bank.IsOpen() and not Bank.IsLive() then
        return {}
    end
    local ids, seen = {}, {}
    local function append(list)
        if type(list) ~= "table" then
            return
        end
        for i = 1, #list do
            local bag = list[i]
            if bag ~= nil and not seen[bag] and not SkipBankWalkBag(bag) then
                seen[bag] = true
                ids[#ids + 1] = bag
            end
        end
    end
    local C = Containers()
    local charIDs = C and C.GetCharacterBankIDs and C.GetCharacterBankIDs() or RI.GetCharacterBankIDs()
    if (not charIDs or #charIDs == 0) and Bank.IsLive() and C and C.Invalidate then
        C.Invalidate()
        charIDs = C.GetCharacterBankIDs and C.GetCharacterBankIDs() or RI.GetCharacterBankIDs()
    end
    append(charIDs)
    if RI.HasWarband() then
        append(RI.GetWarbandBankIDs())
    end
    return ids
end

function Bank.GetScanDebug()
    local C = Containers()
    local ids = Bank.GetContainerIDs()
    if #ids == 0 then
        ids = RI.GetCharacterBankIDs() or {}
    end
    local slots = {}
    for i = 1, #ids do
        local bag = ids[i]
        local n = RI.GetContainerNumSlots(bag) or 0
        local fb = C and C.GetOpenBankScanNumSlots and C.GetOpenBankScanNumSlots(bag) or n
        slots[#slots + 1] = string.format("%s:%s/%s", tostring(bag), tostring(n), tostring(fb))
    end
    local first
    if Bank.IsLive() then
        Bank.ForEachLiveStack(function(bag, slot, rec)
            if not first then
                first = {
                    bag = bag,
                    slot = slot,
                    itemID = rec.itemID,
                    count = rec.count,
                }
            end
        end, { bank = true, warband = true })
    end
    return {
        live = Bank.IsLive(),
        open = Bank.IsOpen(),
        ids = ids,
        slots = slots,
        firstStack = first,
        lastUse = RI.GetLastBankUse and RI.GetLastBankUse() or nil,
    }
end

function Bank.IsModernBank()
    return C_Bank ~= nil and type(C_Bank.FetchPurchasedBankTabIDs) == "function"
end

function Bank.HasLegacyBankBags()
    if Bank.IsModernBank() then
        return false
    end
    local api = _G.FLUX_API
    if api and api.HasUnifiedBankUI and api.HasUnifiedBankUI() then
        return false
    end
    if type(_G.GetNumBankSlots) ~= "function" then
        return false
    end
    local purchased = _G.GetNumBankSlots()
    return type(purchased) == "number" and purchased > 0
end

function Bank.HasReagentBag()
    return (_G.NUM_REAGENTBAG_SLOTS or 0) > 0
end

function Bank.IsBankContainer(bag)
    return RI.IsBankContainer(bag)
end

function Bank.GetBankTypeForContainer(bag)
    local C = Containers()
    if C and C.GetBankTypeForContainer then
        return C.GetBankTypeForContainer(bag)
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

local lastCharCounts = {}
local lastWarCounts = {}
local lastChargeCounts = {}
local charCounts = {}
local warCounts = {}
local charSlots = {}
local warSlots = {}
local persistedLoaded = false

local function CopyCountMap(src, dst)
    if type(dst) ~= "table" then
        return
    end
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
    CopyCountMap(src, out)
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
    if not next(lastCharCounts) then
        CopyCountMap(sv.charCounts, lastCharCounts)
    end
    if not next(lastWarCounts) then
        CopyCountMap(sv.warCounts, lastWarCounts)
    end
    if not next(lastChargeCounts) then
        CopyCountMap(sv.chargeCounts, lastChargeCounts)
    end
    if not next(charCounts) then
        CopyCountMap(lastCharCounts, charCounts)
    end
    if not next(warCounts) then
        CopyCountMap(lastWarCounts, warCounts)
    end
end

function Bank.Persist()
    LoadPersistedCounts()
    if next(charCounts) then
        CopyCountMap(charCounts, lastCharCounts)
    end
    if next(warCounts) then
        CopyCountMap(warCounts, lastWarCounts)
    end
    local sv = GetBankSV()
    sv.charCounts = SnapshotCountMap(lastCharCounts)
    sv.warCounts = SnapshotCountMap(lastWarCounts)
    sv.chargeCounts = SnapshotCountMap(lastChargeCounts)
end

-- Backup FluxInv_Bank: 5-arg GetItemCount, then (bags+bank) - bags.
-- Classic includeBank is this form. 3-arg C_Item can ignore bank.
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
        ok, n = pcall(GetItemCount, itemID, includeBank, includeCharges)
        if ok and type(n) == "number" then
            return n
        end
    end
    return nil
end

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

local function CachedStackCount(itemID, includeChar, includeWar)
    local n = 0
    if includeChar then
        n = n + (lastCharCounts[itemID] or charCounts[itemID] or 0)
    end
    if includeWar then
        n = n + (lastWarCounts[itemID] or warCounts[itemID] or 0)
    end
    return n
end

local function OverlaySnapshot(region, counts)
    local api = API()
    local snap = api and api.snapshots and api.snapshots[region]
    if type(snap) ~= "table" or type(counts) ~= "table" or not next(counts) then
        return
    end
    snap.counts = snap.counts or {}
    CopyCountMap(counts, snap.counts)
    snap.generation = (snap.generation or 0) + 1
end

local function IsChargeBankItem(itemID)
    local reg = _G.FluxRestockItemRegistry
    if reg and reg.IsChargeItem and reg.IsChargeItem(itemID) then
        return true
    end
    local Cons = _G.FluxNCConsumables
    return Cons and Cons.IsWeaponEnchantItem and Cons.IsWeaponEnchantItem(itemID) or false
end

local function GetChargeAwareBankCount(itemID, opts)
    local includeChar = opts.bank ~= false
    local includeWar = opts.warband ~= false and RI.HasWarband() or false
    local allowCached = opts.allowCached ~= false

    if Bank.IsLive() then
        Bank.Refresh(opts)
        local sum = 0
        local stacks = Bank.FindStacks(itemID, { bank = includeChar, warband = includeWar })
        local reg = _G.FluxRestockItemRegistry
        local getCharges = reg and reg.GetSlotCharges
        for i = 1, #(stacks or {}) do
            local st = stacks[i]
            local charges = getCharges and getCharges(st.bag, st.slot) or nil
            if charges and charges > 0 then
                sum = sum + charges
            else
                sum = sum + (tonumber(st.count) or 1)
            end
        end
        if includeChar and includeWar then
            lastChargeCounts[itemID] = sum
        end
        return sum
    end

    local apiCharges = ApiBankOnlyCount(itemID, includeChar, includeWar, true)
    if apiCharges and apiCharges > 0 then
        return apiCharges
    end
    local stackN = ApiBankOnlyCount(itemID, includeChar, includeWar, false)
    if stackN == nil and allowCached then
        stackN = CachedStackCount(itemID, includeChar, includeWar)
    end
    stackN = stackN or 0
    if allowCached and lastChargeCounts[itemID] ~= nil then
        if stackN <= 0 then
            lastChargeCounts[itemID] = nil
            return 0
        end
        return lastChargeCounts[itemID]
    end
    return stackN
end

local function NumSlotsForBankWalk(bag)
    local n = RI.GetContainerNumSlots(bag) or 0
    if n > 0 then
        return n
    end
    -- Only the classic main bank (-1) can report 0 slots on the open tick
    -- while items are still readable. Do not invent 36 slots on unpurchased
    -- bank bags — that walk froze the client on every bank open.
    local C = Containers()
    if not C then
        return 0
    end
    local main = C.GetBankMainContainerID and C.GetBankMainContainerID()
    if main and tonumber(bag) == tonumber(main) and C.GetOpenBankScanNumSlots then
        return C.GetOpenBankScanNumSlots(bag) or 0
    end
    return 0
end

function Bank.ForEachLiveStack(fn, opts)
    if type(fn) ~= "function" then
        return
    end
    if not Bank.IsLive() then
        return
    end
    opts = opts or {}
    local function walk(ids, region)
        if type(ids) ~= "table" then
            return
        end
        for i = 1, #ids do
            local bag = ids[i]
            if not SkipBankWalkBag(bag) then
                local numSlots = NumSlotsForBankWalk(bag)
                if numSlots > 0 then
                    Bank._bagsWalked = (Bank._bagsWalked or 0) + 1
                end
                for slot = 1, numSlots do
                    local info = RI.GetContainerItemInfo(bag, slot)
                    if (not info or not info.itemID) and RI.GetContainerItemID then
                        local id = RI.GetContainerItemID(bag, slot)
                        if id then
                            info = info or {}
                            info.itemID = id
                            info.count = info.count or 1
                        end
                    end
                    local itemID = info and (tonumber(info.itemID) or info.itemID)
                    local count = info and (tonumber(info.count) or 0) or 0
                    if itemID and count > 0 then
                        fn(bag, slot, {
                            itemID = itemID,
                            count = count,
                            link = info.hyperlink or info.link,
                            locked = info.locked,
                        }, region)
                    end
                end
            end
        end
    end
    if opts.bank ~= false then
        local C = Containers()
        local ids = RI.GetCharacterBankIDs()
        if (not ids or #ids == 0) and C then
            if C.Invalidate then
                C.Invalidate()
            end
            ids = RI.GetCharacterBankIDs()
        end
        walk(ids, "bank")
    end
    if opts.warband ~= false and RI.HasWarband() then
        walk(RI.GetWarbandBankIDs(), "warband")
    end
end

function Bank.Refresh(opts)
    opts = opts or {}
    if not Bank.IsLive() and not opts.force then
        return Bank.IsOpen()
    end
    LoadPersistedCounts()
    local now = (GetTime and GetTime()) or 0
    -- Throttle even when the first walk is empty. Requiring next(charSlots)
    -- re-scanned the whole bank once per GetCount/FindStacks on open and froze.
    if not opts.force and Bank._lastRefreshAt and (now - Bank._lastRefreshAt) < 0.2 then
        return true
    end
    Bank._lastRefreshAt = now
    local newChar, newWar = {}, {}
    local newCharSlots, newWarSlots = {}, {}
    Bank._bagsWalked = 0
    Bank.ForEachLiveStack(function(bag, slot, rec, region)
        local id = tonumber(rec.itemID)
        local n = tonumber(rec.count) or 0
        if not id or n <= 0 then
            return
        end
        -- Keep `locked`: Bank.FindStacks reports it to the restock planner, which
        -- must not plan moves out of slots the client is still resolving.
        if region == "warband" then
            newWar[id] = (newWar[id] or 0) + n
            newWarSlots[bag] = newWarSlots[bag] or {}
            newWarSlots[bag][slot] = { itemID = id, count = n, link = rec.link, locked = rec.locked }
        else
            newChar[id] = (newChar[id] or 0) + n
            newCharSlots[bag] = newCharSlots[bag] or {}
            newCharSlots[bag][slot] = { itemID = id, count = n, link = rec.link, locked = rec.locked }
        end
    end, { bank = true, warband = true })
    -- Commit when containers were readable. Empty + unreadable open tick keeps
    -- last-visit counts; do not invent bag:slot from GetItemCount.
    local walked = (Bank._bagsWalked or 0) > 0
    Bank._liveWalked = walked
    if next(newChar) or walked then
        charCounts = newChar
        charSlots = newCharSlots
        if next(newChar) then
            lastCharCounts = SnapshotCountMap(charCounts)
            OverlaySnapshot("bank", charCounts)
        end
    end
    if next(newWar) or walked then
        warCounts = newWar
        warSlots = newWarSlots
        if next(newWar) then
            lastWarCounts = SnapshotCountMap(warCounts)
            OverlaySnapshot("warband", warCounts)
        end
    end
    restockRefreshGen = restockRefreshGen + 1
    liveCountGen = nil
    return true
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
    local includeWar = opts.warband ~= false and RI.HasWarband() or false
    local allowCached = opts.allowCached ~= false

    if Bank.IsLive() then
        Bank.Refresh(opts)
        local n = 0
        if includeChar then
            n = n + (charCounts[itemID] or 0)
        end
        if includeWar then
            n = n + (warCounts[itemID] or 0)
        end
        return n
    end

    if allowCached then
        local api = ApiBankOnlyCount(itemID, includeChar, includeWar, false)
        if api and api > 0 then
            return api
        end
        return CachedStackCount(itemID, includeChar, includeWar)
    end
    return 0
end

function Bank.GetCharacterCounts(opts)
    LoadPersistedCounts()
    opts = opts or {}
    if Bank.IsLive() then
        Bank.Refresh(opts)
        return charCounts
    end
    if opts.allowCached ~= false then
        if next(lastCharCounts) then
            return lastCharCounts
        end
        return SnapCounts("bank") or {}
    end
    return {}
end

function Bank.GetWarbandCounts(opts)
    if not RI.HasWarband() then
        return {}
    end
    LoadPersistedCounts()
    opts = opts or {}
    if Bank.IsLive() then
        Bank.Refresh(opts)
        return warCounts
    end
    if opts.allowCached ~= false then
        if next(lastWarCounts) then
            return lastWarCounts
        end
        return SnapCounts("warband") or {}
    end
    return {}
end

function Bank.GetGeneration()
    local api = API()
    local bank = api and api.GetSnapshotGeneration and api.GetSnapshotGeneration("bank") or 0
    local war = api and api.GetSnapshotGeneration and api.GetSnapshotGeneration("warband") or 0
    return tostring(bank) .. ":" .. tostring(war) .. ":" .. tostring(restockRefreshGen)
end

function Bank.FindStacks(itemID, opts)
    itemID = tonumber(itemID)
    local out = {}
    if not itemID then
        return out
    end
    opts = opts or {}
    if not Bank.IsLive() and not opts.force then
        return out
    end
    Bank.Refresh(opts)
    local wantBank = opts.bank ~= false
    local wantWar = opts.warband ~= false and RI.HasWarband()
    local function collect(slotsStore, ids, region)
        if type(ids) ~= "table" then
            return
        end
        for i = 1, #ids do
            local bag = ids[i]
            local slots = slotsStore[bag]
            if slots then
                for slot, rec in pairs(slots) do
                    if tonumber(rec.itemID) == itemID then
                        out[#out + 1] = {
                            bag = bag,
                            slot = slot,
                            count = rec.count,
                            region = region,
                            itemID = itemID,
                            locked = rec.locked,
                        }
                    end
                end
            end
        end
    end
    if wantBank then
        collect(charSlots, Bank.GetContainerIDs(), "bank")
        collect(charSlots, RI.GetCharacterBankIDs(), "bank")
    end
    if wantWar then
        collect(warSlots, RI.GetWarbandBankIDs(), "warband")
    end
    return out
end

function Bank.ForEachOpenStack(opts, fn)
    if type(fn) ~= "function" then
        return
    end
    opts = opts or {}
    if Bank.IsLive() then
        Bank.ForEachLiveStack(fn, opts)
        return
    end
    if not Bank.IsOpen() and not opts.force then
        return
    end
    local api = API()
    if not api or not api.ForEachLocation then
        return
    end
    api.ForEachLocation(function(loc)
        if loc and loc.itemID and not SkipBankWalkBag(loc.bag) then
            fn(loc.bag, loc.slot, {
                itemID = loc.itemID,
                count = loc.count,
                link = loc.link,
            }, loc.region)
        end
    end, {
        bags = false,
        bank = opts.bank ~= false,
        warband = opts.warband ~= false and RI.HasWarband() or false,
        equipped = false,
    })
end

function Bank.GetItemLink(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    local stacks = Bank.FindStacks(itemID, { force = true })
    local stack = stacks and stacks[1]
    if stack and stack.bag and stack.slot then
        return RI.GetContainerItemLink(stack.bag, stack.slot)
    end
    local u = RI.GetUniqueItems({ bags = true, bank = true, warband = true })[itemID]
    return u and u.link or nil
end

function Bank.RegisterBankOpen(key, fn)
    if type(key) == "string" and type(fn) == "function" then
        bankOpenCallbacks[key] = fn
    end
    EnsureBankWatch()
end

function Bank.RegisterBankClose(key, fn)
    if type(key) == "string" and type(fn) == "function" then
        bankCloseCallbacks[key] = fn
    end
    EnsureBankWatch()
end

function Bank.RefreshIfOpen()
    if not Bank.IsOpen() then
        return
    end
    -- One live C_Container walk. Do not rebuild Syndicator / persist / wipe
    -- target caches here: GetPendingSummary used to call this on every
    -- CanRunNow and freeze the client on bank open.
    Bank.Refresh()
end

function Bank.RequestLiveRefresh()
    Bank.RefreshIfOpen()
end

function Bank.SchedulePersist()
    Bank.Persist()
    local api = API()
    if api and api.PersistBankCounts then
        api.PersistBankCounts()
    end
end

--- Every restock listener is registered on the shared facts layer as well, so a
--- local loop here would run each of them a second time. Ask the facts layer for
--- a forced pulse instead and let it do the one fan-out.
local function FireRestock(ctx)
    local sched = Flux and Flux.Scheduler
    if not sched or not sched.Request then
        for _, fn in pairs(restockListeners) do
            if Flux and Flux.Safecall then
                Flux.Safecall(fn, ctx)
            else
                pcall(fn, ctx)
            end
        end
        return
    end
    local regions = (ctx and ctx.regions) or { bags = true }
    for _, token in ipairs({ "bags", "bank", "warband", "equip" }) do
        if regions[token] then
            sched.Request("inventory", token)
        end
    end
    if ctx == nil or ctx.force then
        sched.Request("inventory", "force")
    end
end

function RI.Notify(ctx)
    FireRestock(ctx or { regions = { bags = true }, force = true })
end

EnsureBankWatch = function()
    if bankWatch then
        return
    end
    bankWatch = true
    lastBankOpen = RI.IsBankOpen()

    local function IsBankerKind(kind)
        local PIM = Enum and Enum.PlayerInteractionType
        if not PIM then
            return false
        end
        if kind == PIM.Banker then
            return true
        end
        if PIM.AccountBanker and kind == PIM.AccountBanker then
            return true
        end
        if PIM.CharacterBanker and kind == PIM.CharacterBanker then
            return true
        end
        return false
    end

    local function scheduleOpenScan()
        openScanGen = openScanGen + 1
        local gen = openScanGen
        After(0.15, function()
            if gen ~= openScanGen then
                return
            end
            if not Bank.IsLive() then
                return
            end
            Bank.Refresh({ force = true })
            if Bank.Persist then
                Bank.Persist()
            end
        end)
    end

    -- Backup FluxInv.NotifyBankOpenChanged: fire once when closed → open.
    -- BANKFRAME_OPENED + PIM SHOW used to double-scan and freeze the client.
    local function fireOpen()
        local now = (GetTime and GetTime()) or 0
        local duplicate = lastBankOpen == true and lastFireOpenAt > 0 and (now - lastFireOpenAt) < 1.0
        lastBankOpen = true
        lastFireOpenAt = now
        local api = API()
        if api and api.SetBankOpenLatch then
            api.SetBankOpenLatch(true)
        end
        if duplicate then
            return
        end
        local C = Containers()
        if C and C.Invalidate then
            C.Invalidate()
        end
        local reg = _G.FluxRestockItemRegistry
        if reg and reg.InvalidateBankTargetsCache then
            reg.InvalidateBankTargetsCache()
        end
        Bank._lastRefreshAt = nil
        Bank.Refresh({ force = true })
        scheduleOpenScan()
        for _, fn in pairs(bankOpenCallbacks) do
            pcall(fn)
        end
        FireRestock({
            regions = { bank = true, warband = true },
            force = true,
        })
    end

    local function fireCloseIfGone()
        if Bank.IsOpen() then
            lastBankOpen = true
            Bank.Persist()
            return
        end
        Bank.Persist()
        if not lastBankOpen then
            return
        end
        lastBankOpen = false
        lastFireOpenAt = 0
        openScanGen = openScanGen + 1
        for _, fn in pairs(bankCloseCallbacks) do
            pcall(fn)
        end
        FireRestock({
            regions = { bank = true, warband = true },
            force = true,
        })
    end

    local function ping()
        local open = RI.IsBankOpen()
        if open == lastBankOpen then
            return
        end
        if open then
            fireOpen()
        else
            fireCloseIfGone()
        end
    end

    if Flux and Flux.Events and Flux.Events.Register then
        Flux.Events.Register("BANKFRAME_OPENED", function()
            fireOpen()
        end)
        Flux.Events.Register("BANKFRAME_CLOSED", function()
            fireCloseIfGone()
        end)
        Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
            if IsBankerKind(kind) then
                fireOpen()
            else
                ping()
            end
        end)
        Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
            if IsBankerKind(kind) then
                fireCloseIfGone()
            else
                ping()
            end
        end)
    end
    local api = API()
    if api and api.RegisterBankStateListener then
        api.RegisterBankStateListener("FluxRestock", ping)
    end
end

--- opts (tier / regions / deferHeavy / sync) passes straight through to the
--- facts layer, which is what keeps a bags-only listener off bank pulses.
function RI.Register(key, fn, opts)
    if type(key) ~= "string" or type(fn) ~= "function" then
        return
    end
    restockListeners[key] = fn
    local api = API()
    if api and api.Register then
        api.Register("FluxRestock_" .. key, fn, opts)
    end
    EnsureBankWatch()
end

function RI.Unregister(key)
    if type(key) ~= "string" then
        return
    end
    restockListeners[key] = nil
    local api = API()
    if api and api.Unregister then
        api.Unregister("FluxRestock_" .. key)
    end
end

RI.RegisterListener = RI.Register
RI.UnregisterListener = RI.Unregister

RI.Spells = (_G.FluxInv and _G.FluxInv.Spells)
    or (API() and API().CreateSpells)

EnsureBankWatch()
