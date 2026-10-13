--[[
    Restock/Junk/FluxSellJunk.lua

    Junk selling + repair at the merchant (Scrap sell-loop model).

    * Sells at most SELL_BATCH_SIZE unlocked junk stacks per pass via
      UseContainerItem. Continues on BAG_UPDATE_DELAYED and a self-driving
      timer so merchant "object is busy" stalls still drain remaining junk.
    * filters.safe=false sells everything in one pass instead.
    * filters.destroy deletes ONE unsellable junk item per pass (engine limit).
    * Repair: personal/guild priority, same rules as before.

    Attaches its public surface to the FluxVendorAuto facade table.
]]

FluxSellJunk = FluxSellJunk or {}
local SJ = FluxSellJunk
local FV = FluxVendorAuto

local SELL_BATCH_SIZE = 6
local CLICK_BURST_SIZE = 40
local CONTINUE_DELAY = 0.15
local BUSY_BACKOFF = 0.4
local STALE_PENDING_PASSES = 8

local sellState = {
    active = false,
    mode = nil,          -- "all" | "inferiorOnly"
    kindFilter = nil,    -- upgraded tier kinds to sell (inferiorOnly)
    saleTotal = 0,       -- copper accumulated this sell session
    passes = 0,
    stallPasses = 0,
    removedItemIDs = {},
    pendingSells = {},   -- [bag_slot] = { bag, slot, itemID, price, count }
    busyUntil = 0,
    continueGen = 0,
    moneyAtStart = nil,
    allowClickBurst = false,
}

local function Session() return _G.FluxRestockSession end

local function Inv() return _G.FluxRestock and _G.FluxRestock.Inv end
local function IC() return _G.FluxItemClass end
local function FJ() return _G.FluxVendorJunk end
local function Settings() return FluxRestockSettings.Get() end

local function After(delay, fn)
    if _G.FluxAPICompat and _G.FluxAPICompat.After then
        _G.FluxAPICompat.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

local function FilterActuallyRemoved(idSet)
    local inv = Inv()
    local out = {}
    if type(idSet) ~= "table" then
        return out
    end
    for itemID in pairs(idSet) do
        itemID = tonumber(itemID)
        if not itemID then
            -- skip
        elseif not inv or not inv.ItemExistsInInventory then
            out[itemID] = true
        elseif not inv.ItemExistsInInventory(itemID) then
            out[itemID] = true
        end
    end
    return out
end

local function IsMerchantOpen()
    local inv = Inv()
    return inv and inv.IsMerchantOpen() or (MerchantFrame and MerchantFrame:IsShown()) or false
end

local function NativeJunkCount()
    local fj = FJ()
    if fj and fj.NativeJunkCount then
        return fj.NativeJunkCount()
    end
    if C_MerchantFrame and C_MerchantFrame.GetNumJunkItems then
        local Secrets = _G.Flux and _G.Flux.Secrets
        if Secrets and Secrets.SafeGetNumber then
            return Secrets.SafeGetNumber(C_MerchantFrame.GetNumJunkItems(), 0)
        end
        return tonumber(C_MerchantFrame.GetNumJunkItems()) or 0
    end
    return 0
end

local function TryNativeSellAllJunk()
    if not (C_MerchantFrame and C_MerchantFrame.SellAllJunkItems) then
        return false
    end
    if C_MerchantFrame.IsSellAllJunkEnabled and not C_MerchantFrame.IsSellAllJunkEnabled() then
        return false
    end
    if NativeJunkCount() <= 0 then
        return false
    end
    local ok = pcall(C_MerchantFrame.SellAllJunkItems)
    return ok == true
end

local function SameItemID(a, b)
    a, b = tonumber(a), tonumber(b)
    return a ~= nil and a == b
end

-- If UseContainerItem no-ops (DF+ extra nils, Midnight secret args), drop the
-- stack on merchant slot 0 — the same sell as putting a bag item on the vendor.
local function SellSlotViaMerchantCursor(inv, bag, slot)
    if not inv or not PickupMerchantItem then
        return
    end
    if CursorHasItem and CursorHasItem() then
        return
    end
    local live = inv.GetContainerItemInfo(bag, slot)
    if not live or not live.itemID then
        return
    end
    inv.PickupContainerItem(bag, slot)
    pcall(PickupMerchantItem, 0)
    if CursorHasItem and CursorHasItem() and ClearCursor then
        pcall(ClearCursor)
    end
end

local function SellContainerSlot(inv, bag, slot)
    inv.UseContainerItem(bag, slot)
    -- Direct C API in case the facade still no-ops on DF+.
    if C_Container and C_Container.UseContainerItem then
        pcall(C_Container.UseContainerItem, bag, slot)
    end
    local live = inv.GetContainerItemInfo(bag, slot)
    if live and live.itemID then
        SellSlotViaMerchantCursor(inv, bag, slot)
    end
end

-- ---------------------------------------------------------------------------
-- SELL LOOP
-- ---------------------------------------------------------------------------

local function CancelContinue()
    sellState.continueGen = sellState.continueGen + 1
end

local function ScheduleContinue(delay)
    if not sellState.active then
        return
    end
    sellState.continueGen = sellState.continueGen + 1
    local gen = sellState.continueGen
    After(delay or CONTINUE_DELAY, function()
        if gen ~= sellState.continueGen or not sellState.active then
            return
        end
        SJ.ContinueIfNeeded()
    end)
end

local function ClearPendingStillPresent()
    local inv = Inv()
    if not inv then
        wipe(sellState.pendingSells)
        return
    end
    for key, pending in pairs(sellState.pendingSells) do
        local live = inv.GetContainerItemInfo(pending.bag, pending.slot)
        if live and SameItemID(live.itemID, pending.itemID) then
            sellState.pendingSells[key] = nil
        end
    end
end

function SJ.RunBatch(mode)
    local inv = Inv()
    local ic = IC()
    local filters = Settings().junkFilters
    if not inv or not IsMerchantOpen() then
        return 0, 0, 0
    end
    if GetTime() < (sellState.busyUntil or 0) then
        local remaining = 0
        if next(sellState.pendingSells) then
            remaining = remaining + 1
        end
        local fj = FJ()
        if fj and fj.HasJunkWorklistRemaining and fj.HasJunkWorklistRemaining(mode) then
            remaining = remaining + 1
        end
        return 0, 0, remaining
    end

    local batchLimit = SELL_BATCH_SIZE
    if filters.safe == false then
        batchLimit = math.huge
    elseif sellState.allowClickBurst then
        batchLimit = CLICK_BURST_SIZE
    end
    sellState.allowClickBurst = false
    local sold, destroyed, remaining = 0, 0, 0
    local fj = FJ()

    for key, pending in pairs(sellState.pendingSells) do
        local live = inv.GetContainerItemInfo(pending.bag, pending.slot)
        if not live or not SameItemID(live.itemID, pending.itemID) then
            sellState.removedItemIDs[pending.itemID] = true
            sellState.saleTotal = sellState.saleTotal + (pending.price or 0) * (pending.count or 1)
            sold = sold + 1
            sellState.pendingSells[key] = nil
            if fj and fj.RemoveJunkSlotFromWorklist then
                fj.RemoveJunkSlotFromWorklist(pending.bag, pending.slot, mode)
            end
        end
    end

    local prof = _G.FluxBagLagProf
    local iterFn = fj and fj.IterateJunkWorklist
    if not iterFn then
        return sold, destroyed, remaining
    end

    local attempted = 0
    for bag, slot, itemID in iterFn(mode) do
        local live = inv.GetContainerItemInfo(bag, slot)
        if not live or not SameItemID(live.itemID, itemID) then
            if fj and fj.RemoveJunkSlotFromWorklist then
                fj.RemoveJunkSlotFromWorklist(bag, slot, mode)
            end
        elseif not live.locked then
            if fj and fj.IsSlotProtectedFromSell and fj.IsSlotProtectedFromSell(bag, slot) then
                remaining = remaining + 1
            else
                local price = ic and ic.GetSellPrice(itemID) or 0
                -- Cached sellPrice can be 0 before item info lands; still sell
                -- unless the slot is flagged as having no vendor value.
                if price > 0 or live.noValue ~= true then
                    local slotKey = bag .. "_" .. slot
                    if sellState.pendingSells[slotKey] then
                        remaining = remaining + 1
                    elseif attempted < batchLimit then
                        SellContainerSlot(inv, bag, slot)
                        sellState.pendingSells[slotKey] = {
                            bag = bag,
                            slot = slot,
                            itemID = itemID,
                            price = price,
                            count = live.count or 1,
                        }
                        attempted = attempted + 1
                        inv.NotifyAutomationPulse(0.4)
                    else
                        remaining = remaining + 1
                    end
                elseif filters.destroy ~= false and destroyed == 0 and mode ~= "inferiorOnly" then
                    inv.PickupContainerItem(bag, slot)
                    if DeleteCursorItem then
                        DeleteCursorItem()
                    end
                    sellState.removedItemIDs[itemID] = true
                    destroyed = destroyed + 1
                    if fj and fj.RemoveJunkSlotFromWorklist then
                        fj.RemoveJunkSlotFromWorklist(bag, slot, mode)
                    end
                    inv.NotifyAutomationPulse(0.4)
                else
                    remaining = remaining + 1
                end
            end
        else
            remaining = remaining + 1
        end
    end

    if prof and prof.Inc then
        prof.Inc("sell:batch", 1)
    end
    return sold, destroyed, remaining
end

function SJ.HasRemaining(mode)
    mode = mode or "all"
    if sellState.active and sellState.mode == mode then
        if next(sellState.pendingSells) then
            return true
        end
        local fj = FJ()
        if fj and fj.HasJunkWorklistRemaining then
            return fj.HasJunkWorklistRemaining(mode)
        end
    end
    local fj = FJ()
    if not fj then
        return false
    end
    if mode == "inferiorOnly" then
        local fj = FJ()
        if fj and fj.HasUpgradeInferiorForKinds then
            return fj.HasUpgradeInferiorForKinds(sellState.kindFilter)
        end
        return fj and fj.GetUpgradeInferiorSlotCount() > 0
    end
    return fj.GetJunkSlotCountFast() > 0
end

local function FinishSellSession(announce, skipUI)
    CancelContinue()
    local total = sellState.saleTotal
    if sellState.moneyAtStart then
        local delta = GetMoney() - sellState.moneyAtStart
        if delta > total then
            total = delta
        end
        sellState.moneyAtStart = nil
    end
    local removed = FilterActuallyRemoved(sellState.removedItemIDs)
    local wasInferiorOnly = sellState.mode == "inferiorOnly"
    local clearedKinds = sellState.kindFilter
    sellState.active = false
    sellState.mode = nil
    sellState.kindFilter = nil
    sellState.saleTotal = 0
    sellState.passes = 0
    sellState.stallPasses = 0
    sellState.busyUntil = 0
    sellState.rebuildWorklist = nil
    sellState.allowClickBurst = false
    wipe(sellState.removedItemIDs)
    wipe(sellState.pendingSells)
    local fj = FJ()
    if fj and fj.ClearUpgradeInferiorKindFilter then
        fj.ClearUpgradeInferiorKindFilter()
    end
    if wasInferiorOnly and clearedKinds and next(clearedKinds) then
        local Tiers = _G.FluxRestockTiers
        -- Keep pending if bags still hold inferior for those kinds (failed/partial sell).
        local stillHave = Tiers and Tiers.BagsHaveInferiorForPendingKinds
            and Tiers.BagsHaveInferiorForPendingKinds(clearedKinds)
        if not stillHave and Tiers and Tiers.ClearPendingVendorUpgradeKinds then
            pcall(Tiers.ClearPendingVendorUpgradeKinds, clearedKinds)
        end
    end
    local session = Session()
    if session and session.NotifyItemsRemoved and next(removed) then
        session.NotifyItemsRemoved(removed)
    end
    if next(removed) then
        local fj = FJ()
        if fj and fj.InvalidateJunkSlotCount then
            fj.InvalidateJunkSlotCount()
        elseif fj and fj.InvalidateJunkWorklist then
            fj.InvalidateJunkWorklist()
        end
        if fj and fj.NotifyVisualRefresh then
            fj.NotifyVisualRefresh()
        end
    end
    if announce and total > 0 then
        if FV.AddBatchCopper then
            FV.AddBatchCopper(total)
        else
            local text = GetCoinTextureString and GetCoinTextureString(total) or (tostring(total) .. "c")
            print("|cff00ffff[FluxUI]|r Sold junk for " .. text .. ".")
        end
    end
    if not skipUI then
        local ui = _G.FluxVendorAutoMerchantUI
        if ui then
            if ui.MarkJunkStatsDirty then ui.MarkJunkStatsDirty() end
            if ui.ScheduleJunkUIRefresh then ui.ScheduleJunkUIRefresh(true) end
        end
    end
end

--- Start (or restart) a sell session. mode: "all" (default) | "inferiorOnly".
--- opts.kinds: when inferiorOnly, sell only items inferior for these tier kinds.
--- Re-clicking while already selling forces another pass (stuck-session resume).
function SJ.Start(mode, opts)
    if not IsMerchantOpen() then
        return false
    end
    opts = type(opts) == "table" and opts or {}
    mode = mode or "all"
    local fj = FJ()
    if mode == "inferiorOnly" and fj and fj.SetUpgradeInferiorKindFilter then
        fj.SetUpgradeInferiorKindFilter(opts.kinds)
    elseif fj and fj.ClearUpgradeInferiorKindFilter then
        fj.ClearUpgradeInferiorKindFilter()
    end
    sellState.kindFilter = mode == "inferiorOnly" and opts.kinds or nil
    if sellState.active and sellState.mode == mode and mode ~= "inferiorOnly" then
        -- Resume a stuck session: clear failed pendings and force another pass.
        ClearPendingStillPresent()
        sellState.busyUntil = 0
        sellState.stallPasses = 0
        sellState.allowClickBurst = true
        local still = SJ.ContinueIfNeeded()
        if still then
            ScheduleContinue(CONTINUE_DELAY)
        end
        return still
    end
    if sellState.active and sellState.mode ~= mode then
        CancelContinue()
        sellState.active = false
    end
    sellState.active = true
    sellState.mode = mode
    sellState.saleTotal = 0
    sellState.passes = 0
    sellState.stallPasses = 0
    sellState.busyUntil = 0
    wipe(sellState.removedItemIDs)
    wipe(sellState.pendingSells)
    sellState.moneyAtStart = GetMoney()
    sellState.rebuildWorklist = nil
    -- Sell Flux-classified junk (explicit marks, inferior, unusable, greys)
    -- on this click. Post-DF UseContainerItem / cursor pickup need the
    -- hardware event; deferring behind SellAllJunkItems left marked
    -- (non-grey) stacks unsold. Native greys are a same-click mop-up.
    sellState.allowClickBurst = true
    if fj and fj.InvalidateJunkWorklist then
        fj.InvalidateJunkWorklist(true)
    end
    if fj and fj.EnsureJunkWorklist then
        fj.EnsureJunkWorklist(mode)
    end
    local ui = _G.FluxVendorAutoMerchantUI
    if ui and ui.MarkJunkStatsDirty then
        ui.MarkJunkStatsDirty()
    end
    local still = SJ.ContinueIfNeeded()
    if mode == "all" then
        TryNativeSellAllJunk()
    end
    if still then
        ScheduleContinue(CONTINUE_DELAY)
    end
    return still
end

--- Run the next pass if a session is active. Called from the merchant bag
--- pulse (BAG_UPDATE_DELAYED) and from the self-driving continue timer.
function SJ.ContinueIfNeeded()
    if not sellState.active then
        return false
    end
    if not IsMerchantOpen() then
        FinishSellSession(false, true)
        return false
    end
    if GetTime() < (sellState.busyUntil or 0) then
        ScheduleContinue(math.max(0.05, sellState.busyUntil - GetTime()))
        return true
    end
    if sellState.rebuildWorklist then
        sellState.rebuildWorklist = nil
        local fj = FJ()
        if fj and fj.InvalidateJunkWorklist then
            fj.InvalidateJunkWorklist()
        end
        if fj and fj.EnsureJunkWorklist then
            fj.EnsureJunkWorklist(sellState.mode)
        end
    end
    sellState.passes = sellState.passes + 1
    if sellState.passes > 120 then
        FinishSellSession(true)
        return false
    end
    local inv = Inv()
    for key, pending in pairs(sellState.pendingSells) do
        local live = inv and inv.GetContainerItemInfo(pending.bag, pending.slot)
        if live and SameItemID(live.itemID, pending.itemID) then
            pending.stalePasses = (pending.stalePasses or 0) + 1
            if pending.stalePasses >= STALE_PENDING_PASSES then
                sellState.pendingSells[key] = nil
            end
        end
    end
    local sold, destroyed, remaining = SJ.RunBatch(sellState.mode)
    if remaining == 0 and not next(sellState.pendingSells) and not SJ.HasRemaining(sellState.mode) then
        FinishSellSession(true)
        return false
    end
    if sold == 0 and destroyed == 0 and not next(sellState.pendingSells) then
        sellState.stallPasses = sellState.stallPasses + 1
        if sellState.stallPasses >= 20 then
            FinishSellSession(true)
            return false
        end
        ScheduleContinue(CONTINUE_DELAY)
        return true
    end
    sellState.stallPasses = 0
    ScheduleContinue(CONTINUE_DELAY)
    return true
end

function SJ.IsSelling()
    return sellState.active
end

--- Merchant returned ERR_OBJECT_IS_BUSY (or similar). Drop failed pendings and
--- retry after a short backoff so the loop does not wait forever for bag events.
function SJ.OnMerchantBusy()
    if not sellState.active then
        return
    end
    ClearPendingStillPresent()
    sellState.busyUntil = GetTime() + BUSY_BACKOFF
    sellState.stallPasses = 0
    ScheduleContinue(BUSY_BACKOFF)
end

function SJ.OnMerchantClosed()
    CancelContinue()
    if sellState.active then
        FinishSellSession(false, true)
    elseif next(sellState.removedItemIDs) or next(sellState.pendingSells) then
        local session = Session()
        local removed = FilterActuallyRemoved(sellState.removedItemIDs)
        if session and session.NotifyItemsRemoved and next(removed) then
            session.NotifyItemsRemoved(removed)
        end
        wipe(sellState.removedItemIDs)
        wipe(sellState.pendingSells)
    end
end

-- ---------------------------------------------------------------------------
-- REPAIR
-- ---------------------------------------------------------------------------

local function ClientHasGuildBankFeature()
    return type(CanGuildBankRepair) == "function"
        and type(GetGuildBankWithdrawMoney) == "function"
end

function SJ.TryRepair(personalOnly)
    if not CanMerchantRepair or not CanMerchantRepair() then
        return false
    end
    local repairCost, canRepair = GetRepairAllCost()
    if not canRepair or repairCost == 0 then
        return false
    end

    local settings = Settings()
    local playerMoney = GetMoney()
    local canGuildRepair = CanGuildBankRepair and CanGuildBankRepair()
    local guildAffordable = false
    if canGuildRepair then
        local guildBankMoney = GetGuildBankWithdrawMoney and GetGuildBankWithdrawMoney() or 0
        local guildBankLimit = GetGuildBankMoney and GetGuildBankMoney() or 0
        guildAffordable = guildBankMoney >= repairCost or guildBankLimit == -1
    end
    local personalAffordable = playerMoney >= repairCost

    local priority = settings.repairPriority or "personal"
    local useGuildBank
    if priority == "personal" then
        if personalAffordable then
            useGuildBank = false
        elseif guildAffordable then
            useGuildBank = true
        else
            return false
        end
    else
        if guildAffordable then
            useGuildBank = true
        elseif personalAffordable then
            useGuildBank = false
        else
            return false
        end
    end

    if personalOnly and useGuildBank then
        return false
    end

    RepairAllItems(useGuildBank)
    return true, useGuildBank, repairCost
end

-- ---------------------------------------------------------------------------
-- FluxVendorAuto FACADE
-- ---------------------------------------------------------------------------

function FV.IsJunkSellActive()
    return sellState.active
end

function FV.TrySellJunkItems()
    return SJ.Start("all")
end

function FV.TrySellUpgradeInferiorItems(force, kindFilter)
    local settings = Settings()
    if not force and not settings.autoSellGray then
        return false
    end
    local fj = FJ()
    if fj and fj.InvalidateJunkWorklist then
        fj.InvalidateJunkWorklist()
    end
    return SJ.Start("inferiorOnly", { kinds = kindFilter })
end

function FV.ContinueJunkSellIfNeeded()
    return SJ.ContinueIfNeeded()
end

function FV.OnJunkSellBusy()
    return SJ.OnMerchantBusy()
end

function FV.SellGrayManual()
    if not IsMerchantOpen() then return end
    SJ.Start("all")
end

function FV.TriggerAutoSellGray()
    if not IsMerchantOpen() then return end
    local settings = Settings()
    if settings.autoSellGray then
        SJ.Start("all")
    end
end

function FV.CountSellableJunkItems()
    local fj = FJ()
    return fj and fj.GetJunkSlotCountFast and fj.GetJunkSlotCountFast() or 0
end

FV.CountSellableGrayItems = FV.CountSellableJunkItems

function FV.ShouldShowGuildRepairPriorityOption()
    return ClientHasGuildBankFeature()
end

function FV.RepairManual()
    local moneyBefore = GetMoney()
    local repaired, usedGuild, repairCost = SJ.TryRepair(true)
    if repaired and not usedGuild and repairCost and repairCost > 0 then
        FV.ReportManualRepairDelta(moneyBefore)
    end
    return repaired
end

function FV.TriggerAutoRepair()
    if not IsMerchantOpen() then return end
    local settings = Settings()
    if not settings.autoRepair then return end
    local repaired, usedGuild, repairCost = SJ.TryRepair(false)
    if repaired and not usedGuild and repairCost and repairCost > 0 and FV.AddBatchCopper then
        FV.AddBatchCopper(-repairCost)
    end
    return repaired
end

function FV.ReportManualRepairDelta(moneyBefore)
    moneyBefore = tonumber(moneyBefore)
    if not moneyBefore then return end
    local run = function()
        local delta = GetMoney() - moneyBefore
        if delta < 0 then
            local text = GetCoinTextureString and GetCoinTextureString(-delta) or (tostring(-delta) .. "c")
            print("|cff00ffff[FluxUI]|r Repaired for " .. text .. ".")
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.1, run)
    else
        run()
    end
end

_G.FluxSellJunk = SJ
return SJ
