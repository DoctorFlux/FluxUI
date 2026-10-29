--[[
    Restock/Vendor/FluxVendorBuy.lua

    Merchant session owner: the ONLY registrant of merchant events for the
    restock system.

      MERCHANT_SHOW    -> repair + sell junk immediately (no WarmMerchant wait);
                          build item index only when restock/upgrade needs it;
                          then buy restock once index is ready and sell is done.
                          WarmMerchant / inferior overlays run deferred after
                          automation. Holding Shift skips all automation.
      BAG_UPDATE_DELAYED (merchant open) -> continue sell/buy batches, refresh
                          the merchant UI data (debounced by the UI itself).
      MERCHANT_UPDATE  -> debounced index rebuild.
      MERCHANT_CLOSED  -> finish the batch, report one net gold line.

    Purchases: needs come from FluxVendorAuto.GetRestockTargetItems (bag counts
    are O(1) snapshot reads); stack math follows Restocker and caps by gold +
    alt currency so short funds still buy a partial amount; at most
    BUY_CALLS_PER_PASS BuyMerchantItem calls per pass, continued on the next
    bag pulse so large restocks never freeze a frame.
]]

FluxVendorBuy = FluxVendorBuy or {}
local Buy = FluxVendorBuy
local FV = FluxVendorAuto

local BUY_CALLS_PER_PASS = 8
local INDEX_SYNC_LIMIT = 20
local INDEX_CHUNK = 16
local VENDOR_OPEN_STORM_SEC = 0.45
local vendorOpenStormGen = 0
local vendorOpenStormActive = false

local function Inv() return _G.FluxRestock and _G.FluxRestock.Inv end
local function Tiers() return _G.FluxRestockTiers end
local function List() return _G.FluxRestockList end
local function Settings() return FluxRestockSettings.Get() end
local function MUI() return _G.FluxVendorAutoMerchantUI end
local function SellJunk() return _G.FluxSellJunk end

-- Midnight removed GetMerchantItemInfo. Classic/MoP still have the tuple API.
local function GetMerchantSlotInfo(slotIndex)
    slotIndex = tonumber(slotIndex)
    if not slotIndex then
        return nil
    end
    if GetMerchantItemInfo then
        return GetMerchantItemInfo(slotIndex)
    end
    local getInfo = C_MerchantFrame and C_MerchantFrame.GetItemInfo
    if not getInfo then
        return nil
    end
    local info = getInfo(slotIndex)
    if type(info) ~= "table" then
        return nil
    end
    return info.name, info.texture, info.price or 0, info.stackCount or 0,
        info.numAvailable or 0, info.isPurchasable, info.isUsable,
        info.hasExtendedCost, info.currencyID, info.spellID
end
Buy.GetMerchantSlotInfo = GetMerchantSlotInfo

local function After(delay, fn)
    if FluxAPICompat and FluxAPICompat.After then
        FluxAPICompat.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

local function IsMerchantOpen()
    return MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown() or false
end

-- ---------------------------------------------------------------------------
-- BATCH REPORTER (one net gold line per vendor visit)
-- ---------------------------------------------------------------------------

local batchState = {
    active = false,
    copperDelta = 0,
}

local function FormatCopper(copper)
    copper = math.abs(tonumber(copper) or 0)
    if GetCoinTextureString then
        return GetCoinTextureString(copper)
    end
    return tostring(copper) .. "c"
end

function FV.AddBatchCopper(copper)
    copper = tonumber(copper) or 0
    if copper == 0 then return end
    if batchState.active then
        batchState.copperDelta = batchState.copperDelta + copper
        return
    end
    -- No batch running: report immediately.
    if copper > 0 then
        print("|cff00ffff[FluxUI]|r Vendor: +" .. FormatCopper(copper))
    else
        print("|cff00ffff[FluxUI]|r Vendor: -" .. FormatCopper(copper))
    end
end

local function BeginBatch()
    if batchState.active then return end
    batchState.active = true
    batchState.copperDelta = 0
end

local function FinishBatch()
    if not batchState.active then return end
    local delta = batchState.copperDelta
    batchState.active = false
    batchState.copperDelta = 0
    if delta > 0 then
        print("|cff00ffff[FluxUI]|r Vendor: +" .. FormatCopper(delta))
    elseif delta < 0 then
        print("|cff00ffff[FluxUI]|r Vendor: -" .. FormatCopper(delta))
    end
end

-- ---------------------------------------------------------------------------
-- MERCHANT ITEM INDEX (itemID -> { slot, price, batchQty, unitPrice, maxStack })
-- ---------------------------------------------------------------------------

local merchantIndex = nil
local indexBuildPending = false
local indexGeneration = 0
local indexListeners = {}
local merchantAutoBatchPending = false
local merchantAutoBatchShiftSkipped = false
local postBurstUIScheduled = false
local postBurstGen = 0
local tierUpgradeRetryGen = 0
local tierUpgradeRetryCount = 0
local TIER_UPGRADE_RETRY_MAX = 20
local autoBatchInferiorWait = 0
local restockManualRetryGen = 0
local RESTOCK_MANUAL_RETRY_MAX = 12
local restockPendingSellAttempts = 0

local buyState = {
    active = false,
    manual = false,
    queue = nil,
    passes = 0,
    boughtAny = false,
    deferredAutoBuy = nil,
    deferredSellAllJunk = nil,
    pendingStart = nil,
    flushUIAfterBuy = nil,
}

-- True once this merchant open already started auto-sell (skip re-sell in batch).
local fastAutoSellStarted = false
local junkSellWasActive = false

local function RefreshJunkOverlaysAfterInferior()
    local overlay = _G.FluxJunkOverlay
    if overlay and overlay.ScheduleInferiorRepaintBurst then
        pcall(overlay.ScheduleInferiorRepaintBurst)
    elseif overlay and overlay.RepaintInferiorVisuals then
        pcall(overlay.RepaintInferiorVisuals)
    elseif overlay and overlay.FlushDeferredPaint then
        pcall(overlay.FlushDeferredPaint, true)
    end
    local fj = _G.FluxVendorJunk
    if fj and fj.NotifyVisualRefresh then
        pcall(fj.NotifyVisualRefresh)
    end
    local ui = MUI()
    if ui and ui.MarkJunkStatsDirty then
        pcall(ui.MarkJunkStatsDirty)
    end
    if ui and ui.ScheduleJunkUIRefresh then
        pcall(ui.ScheduleJunkUIRefresh, true)
    end
end

local function ScheduleJunkOverlaysAfterInferiorDeferred()
    local burstActive = FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive()
    local inv = Inv()
    if burstActive or (inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet()) then
        if inv and inv.OnQuietSettled then
            inv.OnQuietSettled(RefreshJunkOverlaysAfterInferior)
        else
            After(0.35, RefreshJunkOverlaysAfterInferior)
        end
        return
    end
    RefreshJunkOverlaysAfterInferior()
end

local function RefreshTierUIAfterReferenceChange()
    local TiersMod = Tiers()
    if TiersMod and TiersMod.InvalidateTooltipDisplayCache then
        pcall(TiersMod.InvalidateTooltipDisplayCache)
    elseif TiersMod and TiersMod.InvalidateTierQueryCache then
        pcall(TiersMod.InvalidateTierQueryCache)
    end
    local panel = _G.FluxVendorRestockPanel
    if panel and panel.RefreshCountsOnly then
        pcall(panel.RefreshCountsOnly)
    end
    local ui = MUI()
    if ui and ui.MarkRestockSettingsDirty then
        pcall(ui.MarkRestockSettingsDirty)
    end
end

local function FlushEbsButtonIdentityRefresh()
    local inv = Inv()
    if inv and inv.FlushExtraButtonIdentityRefresh then
        pcall(inv.FlushExtraButtonIdentityRefresh)
        return
    end
    local nc = _G.FluxNCItemDetection
    if nc and nc.ScheduleFoodWaterUpdate then
        pcall(nc.ScheduleFoodWaterUpdate, { changeKind = "identityChanged", force = true })
    end
    local TiersMod = Tiers()
    if TiersMod and TiersMod.FlushTierCountRefresh then
        pcall(TiersMod.FlushTierCountRefresh)
    end
    local combatModules = {
        _G.FluxCombatHealPotion,
        _G.FluxCombatManaPotion,
        _G.FluxCombatBandage,
    }
    for _, mod in ipairs(combatModules) do
        if mod then
            if mod.CheckAndUpdatePlaceholderStates then
                pcall(mod.CheckAndUpdatePlaceholderStates)
            elseif mod.Update then
                pcall(mod.Update)
            end
        end
    end
end

--- One coherent UI refresh: tier caches, Restock button, junk glow, EBS identities.
local flushVendorTierUIGen = 0
local function FlushVendorTierUI(opts)
    opts = opts or {}
    if not IsMerchantOpen() and not opts.force then
        return
    end
    flushVendorTierUIGen = flushVendorTierUIGen + 1
    local myGen = flushVendorTierUIGen

    local TiersMod = Tiers()
    if TiersMod then
        if TiersMod.InvalidateTierQueryCache then
            pcall(TiersMod.InvalidateTierQueryCache)
        end
        if TiersMod.InvalidateTooltipDisplayCache then
            pcall(TiersMod.InvalidateTooltipDisplayCache)
        end
        if TiersMod.NotifyTierReferenceUIRefresh then
            pcall(TiersMod.NotifyTierReferenceUIRefresh)
        else
            RefreshTierUIAfterReferenceChange()
        end
    else
        RefreshTierUIAfterReferenceChange()
    end

    RefreshJunkOverlaysAfterInferior()

    if _G.FluxRestockPanel_RefreshJunkLists then
        pcall(_G.FluxRestockPanel_RefreshJunkLists)
    elseif _G.FluxRestockPanel_RefreshMerchantAvailability then
        pcall(_G.FluxRestockPanel_RefreshMerchantAvailability)
    end

    local ui = MUI()
    if ui and IsMerchantOpen() then
        if ui.MarkRestockSettingsDirty then
            pcall(ui.MarkRestockSettingsDirty)
        end
        if ui.MarkJunkStatsDirty then
            pcall(ui.MarkJunkStatsDirty)
        end
        -- During the open-storm window, debounce instead of Immediate to avoid
        -- stacking merchant UI paints on top of classify/warm work.
        if not vendorOpenStormActive and ui.ScheduleMerchantUpdateImmediate then
            pcall(ui.ScheduleMerchantUpdateImmediate, "data")
        elseif ui.ScheduleMerchantUpdate then
            pcall(ui.ScheduleMerchantUpdate, "data")
        elseif ui.UpdateMerchantUI then
            pcall(ui.UpdateMerchantUI, "data")
        end
    end

    FlushEbsButtonIdentityRefresh()

    -- Coalesce late quiet-settled paints into the same generation.
    if opts.afterQuiet and myGen == flushVendorTierUIGen then
        local inv = Inv()
        if inv and inv.OnQuietSettled then
            inv.OnQuietSettled(function()
                if myGen ~= flushVendorTierUIGen or not IsMerchantOpen() then
                    return
                end
                RefreshJunkOverlaysAfterInferior()
                FlushEbsButtonIdentityRefresh()
            end)
        end
    end
end

Buy.FlushVendorTierUI = FlushVendorTierUI
FV.FlushVendorTierUI = FlushVendorTierUI

local function IsAutomationRunning()
    local sj = SellJunk()
    return (sj and sj.IsSelling and sj.IsSelling())
        or buyState.active
        or buyState.deferredAutoBuy
        or buyState.deferredSellAllJunk
end

local function HasInferiorToSell(kindFilter)
    local fj = _G.FluxVendorJunk
    local sj = SellJunk()
    local TiersMod = Tiers()
    if sj and sj.HasRemaining and sj.HasRemaining("inferiorOnly") then
        return true
    end
    -- Live kind eval first (works even before inferiorSet publish).
    if kindFilter and next(kindFilter) then
        if TiersMod and TiersMod.BagsHaveInferiorForPendingKinds
            and TiersMod.BagsHaveInferiorForPendingKinds(kindFilter) then
            return true
        end
        if fj and fj.HasUpgradeInferiorForKinds and fj.HasUpgradeInferiorForKinds(kindFilter) then
            return true
        end
    end
    if fj and fj.GetUpgradeInferiorSlotCount and fj.GetUpgradeInferiorSlotCount() > 0 then
        return true
    end
    return false
end

local function GetPendingVendorUpgradeKinds()
    local TiersMod = Tiers()
    if not TiersMod or not TiersMod.GetVendorUpgradeKinds then
        return nil
    end
    return TiersMod.GetVendorUpgradeKinds()
end

--- Clear pending only when bags are settled and nothing inferior remains for those kinds.
local function ClearPendingIfNoInferiorLeft(kinds)
    local TiersMod = Tiers()
    if not TiersMod or not kinds or not next(kinds) then
        return
    end
    if TiersMod.IsInferiorPassComplete and not TiersMod.IsInferiorPassComplete() then
        return
    end
    if TiersMod.BagsHaveInferiorForPendingKinds
        and TiersMod.BagsHaveInferiorForPendingKinds(kinds) then
        return
    end
    if TiersMod.ClearPendingVendorUpgradeKinds then
        TiersMod.ClearPendingVendorUpgradeKinds(kinds)
    end
end

local function TrySellVendorUpgradeInferior(force)
    local kinds = GetPendingVendorUpgradeKinds()
    if not kinds or not next(kinds) then
        return false
    end
    local TiersMod = Tiers()
    -- Force sync marks so IterateUpgradeInferiorFast can sell Food_A etc.
    if TiersMod then
        if TiersMod.ClearVendorInferiorSnapshot then
            pcall(TiersMod.ClearVendorInferiorSnapshot)
        end
        if TiersMod.EnsureInferiorMarksForVendor then
            -- Sell path needs marks this frame.
            pcall(TiersMod.EnsureInferiorMarksForVendor, merchantIndex, { sync = true, force = true })
        end
        -- Guarantee pending-kind inferiors are in inferiorSet for the sell worklist.
        if TiersMod.ForcePublishInferiorForKinds then
            pcall(TiersMod.ForcePublishInferiorForKinds, kinds, merchantIndex)
        end
    end
    if not HasInferiorToSell(kinds) then
        -- Do not drop pending while marks/classify are still settling.
        ClearPendingIfNoInferiorLeft(kinds)
        return false
    end
    return FV.TrySellUpgradeInferiorItems(force, kinds)
end

local function CancelPostBurstMerchantUI()
    postBurstGen = postBurstGen + 1
    postBurstUIScheduled = false
end

local function SchedulePostBurstMerchantUI()
    if postBurstUIScheduled then
        return
    end
    postBurstUIScheduled = true
    postBurstGen = postBurstGen + 1
    local myGen = postBurstGen
    local function run()
        if myGen ~= postBurstGen then
            return
        end
        postBurstUIScheduled = false
        if not IsMerchantOpen() then
            return
        end
        local ui = MUI()
        if not ui then
            return
        end
        if ui.MarkJunkStatsDirty then
            ui.MarkJunkStatsDirty()
        end
        if ui.ScheduleJunkUIRefresh then
            ui.ScheduleJunkUIRefresh(true)
        end
        if ui.ScheduleMerchantUpdate then
            ui.ScheduleMerchantUpdate("data")
        end
    end
    local inv = Inv()
    if inv and inv.OnQuietSettled then
        inv.OnQuietSettled(run)
    else
        After(0.35, run)
    end
end

Buy.CancelPostBurstMerchantUI = CancelPostBurstMerchantUI

local TIER_KINDS = { "food", "water", "bandage", "healPotion", "manaPotion" }

local function NeedsVendorAutomation()
    local s = Settings()
    return s.autoRepair or s.autoSellGray or s.autoRestock
end

--- Pending upgrade must warm/inferior before sell-inferior + buy.
local function NeedsBlockingVendorTierPass()
    local TiersMod = Tiers()
    return TiersMod and TiersMod.HasPendingVendorUpgradeRestock
        and TiersMod.HasPendingVendorUpgradeRestock() or false
end

--- Legacy name: only pending upgrade blocks automation now.
local function NeedsFullVendorTierPass()
    return NeedsBlockingVendorTierPass()
end

--- Index is for restock / upgrade detection — not for sell-only or repair-only.
local function NeedsMerchantIndexOnOpen()
    local s = Settings()
    if s.autoRestock then
        return true
    end
    return NeedsBlockingVendorTierPass()
end

--- After sell/buy: warm + inferior for overlays when tier features are configured.
local function ShouldDeferVendorTierPass()
    if NeedsBlockingVendorTierPass() then
        return false
    end
    local TiersMod = Tiers()
    if not TiersMod then
        return false
    end
    for _, kind in ipairs(TIER_KINDS) do
        if TiersMod.IsTierEligible and TiersMod.IsTierEligible(kind) then
            if TiersMod.IsMarkInferiorEnabled and TiersMod.IsMarkInferiorEnabled(kind) then
                return true
            end
            if TiersMod.GetTarget and (TiersMod.GetTarget(kind) or 0) > 0 then
                return true
            end
        end
    end
    return false
end

local function NeedsAutoVendorBatchAfterIndex()
    local s = Settings()
    if s.autoRestock then
        return true
    end
    return NeedsBlockingVendorTierPass()
end

local function ApplyVendorTierReferencesDeferred(TiersMod, inferiorChanged)
    if not TiersMod or not merchantIndex then
        return
    end
    After(0, function()
        if not IsMerchantOpen() or not merchantIndex then
            return
        end
        local refChanged, needsInferiorRecompute = false, false
        if TiersMod.RefreshTierReferences then
            refChanged, needsInferiorRecompute = TiersMod.RefreshTierReferences(merchantIndex)
            refChanged = refChanged or false
            needsInferiorRecompute = needsInferiorRecompute or false
        end
        if refChanged then
            RefreshTierUIAfterReferenceChange()
            if TiersMod.NotifyTierReferenceUIRefresh then
                pcall(TiersMod.NotifyTierReferenceUIRefresh)
            end
        end
        if needsInferiorRecompute and not inferiorChanged and TiersMod.EnsureInferiorMarksForVendor then
            pcall(TiersMod.EnsureInferiorMarksForVendor, merchantIndex)
        end
    end)
end

local function ApplyVendorTierUpgradesOnIndex()
    local TiersMod = Tiers()
    if not TiersMod or not merchantIndex then
        return true
    end
    local function retryLater()
        tierUpgradeRetryCount = tierUpgradeRetryCount + 1
        if tierUpgradeRetryCount > TIER_UPGRADE_RETRY_MAX then
            tierUpgradeRetryCount = 0
            -- Inferior still incomplete: allow auto-batch anyway so buy can proceed.
            Buy.MaybeRunAutoVendorBatch()
            return
        end
        tierUpgradeRetryGen = tierUpgradeRetryGen + 1
        local myGen = tierUpgradeRetryGen
        After(0.15, function()
            if myGen ~= tierUpgradeRetryGen then
                return
            end
            if not IsMerchantOpen() or not merchantIndex then
                tierUpgradeRetryCount = 0
                return
            end
            if ApplyVendorTierUpgradesOnIndex() then
                tierUpgradeRetryCount = 0
                Buy.MaybeRunAutoVendorBatch()
            end
        end)
    end
    -- Blocking upgrade path: sync warm so inferior marks are ready this frame.
    if TiersMod.WarmMerchantTierItems then
        pcall(TiersMod.WarmMerchantTierItems, merchantIndex, { sync = true })
    end
    if TiersMod.InvalidateTierQueryCache then
        pcall(TiersMod.InvalidateTierQueryCache)
    end
    local upgradeResult = nil
    local inferiorChanged = false
    if TiersMod.RunVendorTierAndInferiorPass then
        inferiorChanged, upgradeResult = TiersMod.RunVendorTierAndInferiorPass(merchantIndex)
        if upgradeResult and upgradeResult.deferred then
            retryLater()
            return false
        end
    elseif TiersMod.ApplyVendorTierUpgrades then
        upgradeResult = TiersMod.ApplyVendorTierUpgrades(merchantIndex)
        if upgradeResult and upgradeResult.deferred then
            retryLater()
            return false
        end
        if upgradeResult and upgradeResult.any and TiersMod.EnsureInferiorMarksForVendor then
            inferiorChanged = TiersMod.EnsureInferiorMarksForVendor(merchantIndex) or false
        end
        if TiersMod.IsInferiorPassComplete and not TiersMod.IsInferiorPassComplete() then
            retryLater()
            return false
        end
    end
    if upgradeResult and upgradeResult.any then
        if TiersMod.RequestRecompute then
            TiersMod.RequestRecompute({
                scope = "structure",
                force = true,
                ctx = { vendorTierUpgrade = true },
            })
        end
    end
    ApplyVendorTierReferencesDeferred(TiersMod, inferiorChanged)
    tierUpgradeRetryCount = 0
    -- Always one flush when the vendor tier pass completes (upgrade or not).
    FlushVendorTierUI({ afterQuiet = upgradeResult and upgradeResult.any })
    return true
end

local deferredTierPassGen = 0
local function ScheduleDeferredVendorTierPass()
    if not ShouldDeferVendorTierPass() or not merchantIndex then
        return
    end
    deferredTierPassGen = deferredTierPassGen + 1
    local myGen = deferredTierPassGen
    local function run()
        if myGen ~= deferredTierPassGen or not IsMerchantOpen() or not merchantIndex then
            return
        end
        if IsAutomationRunning() then
            After(0.15, run)
            return
        end
        local inv = Inv()
        if inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() then
            After(0.15, run)
            return
        end
        local TiersMod = Tiers()
        if not TiersMod then
            return
        end
        -- Chunked warm, then inferior marks + UI — never blocks sell/buy.
        local function afterWarm()
            if myGen ~= deferredTierPassGen or not IsMerchantOpen() then
                return
            end
            if TiersMod.EnsureInferiorMarksForVendor then
                pcall(TiersMod.EnsureInferiorMarksForVendor, merchantIndex)
            end
            if TiersMod.RefreshTierReferences then
                pcall(TiersMod.RefreshTierReferences, merchantIndex)
            end
            FlushVendorTierUI({ afterQuiet = true })
        end
        if TiersMod.WarmMerchantTierItems then
            pcall(TiersMod.WarmMerchantTierItems, merchantIndex, {
                sync = false,
                onComplete = afterWarm,
            })
        else
            afterWarm()
        end
    end
    After(0, run)
end

function Buy.MaybeRunAutoVendorBatch()
    if not merchantAutoBatchPending or merchantAutoBatchShiftSkipped then
        return
    end
    if not IsMerchantOpen() or indexBuildPending then
        return
    end
    if IsShiftKeyDown and IsShiftKeyDown() then
        merchantAutoBatchPending = false
        return
    end
    merchantAutoBatchPending = false
    FV.RunAutoVendorBatch()
end

local function ResolveMerchantSlotItemID(slotIndex)
    local itemID
    if GetMerchantItemID then
        itemID = GetMerchantItemID(slotIndex)
    end
    if not itemID and GetMerchantItemLink then
        local link = GetMerchantItemLink(slotIndex)
        if link then
            itemID = tonumber(link:match("item:(%d+)"))
        end
    end
    return tonumber(itemID)
end

local function IndexSlot(index, slotIndex)
    local itemID = ResolveMerchantSlotItemID(slotIndex)
    if not itemID then return end
    local _, _, price, quantity, numAvailable, isPurchasable = GetMerchantSlotInfo(slotIndex)
    quantity = math.max(1, tonumber(quantity) or 1)
    local maxStack = (GetMerchantItemMaxStack and GetMerchantItemMaxStack(slotIndex)) or quantity
    local link = GetMerchantItemLink and GetMerchantItemLink(slotIndex) or nil
    index[itemID] = {
        slot = slotIndex,
        price = price or 0,
        batchQty = quantity,
        unitPrice = (price or 0) / quantity,
        maxStack = math.max(1, tonumber(maxStack) or quantity),
        numAvailable = numAvailable,
        isPurchasable = isPurchasable ~= false,
        link = link,
    }
end

local function RunVendorPostIndexWork()
    if not IsMerchantOpen() or not merchantIndex then
        return
    end

    After(0, function()
        if not IsMerchantOpen() or not merchantIndex then
            return
        end
        if List() and List().RecordMerchantPrices then
            pcall(List().RecordMerchantPrices, merchantIndex)
        end
        local TiersMod = _G.FluxRestockTiers
        -- Bootstrap empty refs only (never raises an existing bar / steals upgrades).
        if TiersMod and TiersMod.SeedReferenceFromVendor then
            pcall(TiersMod.SeedReferenceFromVendor, merchantIndex)
        end

        if NeedsBlockingVendorTierPass() then
            -- Pending upgrade: warm/inferior must finish before sell-inferior + buy.
            if ApplyVendorTierUpgradesOnIndex() then
                Buy.MaybeRunAutoVendorBatch()
            end
        else
            if NeedsAutoVendorBatchAfterIndex() and not merchantAutoBatchShiftSkipped then
                Buy.MaybeRunAutoVendorBatch()
            else
                merchantAutoBatchPending = false
            end
            -- Overlays / mark-inferior: after sell/buy, never on the critical path.
            ScheduleDeferredVendorTierPass()
        end
    end)

    for _, fn in ipairs(indexListeners) do
        pcall(fn, merchantIndex)
    end
    Buy.OnIndexReady(NeedsVendorAutomation() and "data" or "layout")
end

local function NotifyIndexReady()
    After(0, RunVendorPostIndexWork)
end

local function BuildIndexSync()
    local index = {}
    local numItems = GetMerchantNumItems() or 0
    for i = 1, numItems do
        IndexSlot(index, i)
    end
    merchantIndex = index
    indexBuildPending = false
    NotifyIndexReady()
    return index
end

local function BuildIndexChunked()
    indexGeneration = indexGeneration + 1
    local myGen = indexGeneration
    local numItems = GetMerchantNumItems() or 0
    local index = {}
    local i = 1
    indexBuildPending = true
    local function step()
        if myGen ~= indexGeneration or not IsMerchantOpen() then
            if myGen == indexGeneration then
                indexBuildPending = false
            end
            return
        end
        local limit = math.min(i + INDEX_CHUNK - 1, numItems)
        while i <= limit do
            IndexSlot(index, i)
            i = i + 1
        end
        if i <= numItems then
            After(0, step)
            return
        end
        merchantIndex = index
        indexBuildPending = false
        NotifyIndexReady()
    end
    After(0, step)
end

function FV.GetMerchantIndexGeneration()
    return indexGeneration
end

function FV.GetMerchantItemIndex(forceRebuild)
    if not IsMerchantOpen() then
        return merchantIndex or {}
    end
    if merchantIndex and not forceRebuild then
        return merchantIndex
    end
    if indexBuildPending and not forceRebuild then
        return merchantIndex or {}
    end
    local numItems = GetMerchantNumItems() or 0
    if numItems <= INDEX_SYNC_LIMIT then
        return BuildIndexSync()
    end
    BuildIndexChunked()
    return merchantIndex or {}
end

FV.EnsureMerchantIndex = FV.GetMerchantItemIndex

function FV.IsMerchantIndexBuildPending()
    return indexBuildPending
end

function FV.InvalidateMerchantIndex()
    merchantIndex = nil
    indexGeneration = indexGeneration + 1
    indexBuildPending = false
end

function FV.RegisterMerchantIndexListener(fn)
    if type(fn) == "function" then
        indexListeners[#indexListeners + 1] = fn
    end
end

local function ResolveUnitPrice(meta)
    local unitPrice = tonumber(meta and meta.unitPrice) or 0
    if unitPrice <= 0 and meta then
        local batchQty = math.max(1, tonumber(meta.batchQty) or 1)
        local price = tonumber(meta.price) or 0
        if price > 0 then
            unitPrice = price / batchQty
        end
    end
    return unitPrice
end

local function GetCurrencyQuantity(currencyID, link, wallet)
    currencyID = tonumber(currencyID)
    if wallet and currencyID and wallet.currencies[currencyID] ~= nil then
        return wallet.currencies[currencyID]
    end
    local qty = 0
    if currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
        if ok and info then
            qty = tonumber(info.quantity) or 0
        end
    elseif link and GetCurrencyInfo then
        local ok, have = pcall(function()
            return select(2, GetCurrencyInfo(link))
        end)
        if ok then
            qty = tonumber(have) or 0
        end
    end
    if wallet and currencyID then
        wallet.currencies[currencyID] = qty
    end
    return qty
end

local function GetCostItemQuantity(itemID, wallet)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    if wallet and wallet.items[itemID] ~= nil then
        return wallet.items[itemID]
    end
    local qty = 0
    if C_Item and C_Item.GetItemCount then
        local ok, n = pcall(C_Item.GetItemCount, itemID, true)
        if ok then
            qty = tonumber(n) or 0
        end
    elseif GetItemCount then
        local ok, n = pcall(GetItemCount, itemID, true)
        if ok then
            qty = tonumber(n) or 0
        end
    end
    if wallet then
        wallet.items[itemID] = qty
    end
    return qty
end

--- Max item count affordable from GetMerchantItemCostInfo costs (honor, badges,
--- reagent items, etc.). Returns nil when the merchant slot has no alt costs.
local function AffordableFromAltCosts(slot, batchQty, wallet)
    slot = tonumber(slot)
    if not slot or not GetMerchantItemCostInfo then
        return nil
    end
    local numCosts = GetMerchantItemCostInfo(slot) or 0
    if numCosts <= 0 then
        return nil
    end
    batchQty = math.max(1, tonumber(batchQty) or 1)
    local afford = math.huge
    for i = 1, numCosts do
        local _, costAmount, link = GetMerchantItemCostItem(slot, i)
        costAmount = tonumber(costAmount) or 0
        if costAmount > 0 and link then
            local have = 0
            local currencyID = tonumber(link:match("currency:(%d+)"))
            if currencyID or (link:find("currency", 1, true)) then
                have = GetCurrencyQuantity(currencyID, link, wallet)
            else
                local itemID = tonumber(link:match("item:(%d+)"))
                have = GetCostItemQuantity(itemID, wallet)
            end
            -- Cost is per merchant batch (quantity); scale to item count.
            local packs = math.floor(have / costAmount)
            afford = math.min(afford, packs * batchQty)
        end
    end
    if afford == math.huge then
        return nil
    end
    return math.max(0, math.floor(afford))
end

local function CanAffordFullListedPurchase(meta, playerMoney, wallet)
    if not meta then
        return false
    end
    local price = tonumber(meta.price) or 0
    local money = tonumber(playerMoney) or 0
    if price > 0 and money < price then
        return false
    end
    local altAfford = AffordableFromAltCosts(meta.slot, meta.batchQty, wallet)
    if altAfford ~= nil and altAfford < math.max(1, tonumber(meta.batchQty) or 1) then
        return false
    end
    return true
end

local function DeductPurchaseFromWallet(wallet, meta, buyQty)
    if not wallet or not meta or not buyQty or buyQty <= 0 then
        return
    end
    local unitPrice = ResolveUnitPrice(meta)
    if unitPrice > 0 then
        wallet.money = math.max(0, (wallet.money or 0) - unitPrice * buyQty)
    end
    local slot = tonumber(meta.slot)
    local batchQty = math.max(1, tonumber(meta.batchQty) or 1)
    if not slot or not GetMerchantItemCostInfo then
        return
    end
    local numCosts = GetMerchantItemCostInfo(slot) or 0
    if numCosts <= 0 then
        return
    end
    local packs = math.floor(buyQty / batchQty)
    if packs <= 0 then
        return
    end
    for i = 1, numCosts do
        local _, costAmount, link = GetMerchantItemCostItem(slot, i)
        costAmount = tonumber(costAmount) or 0
        if costAmount > 0 and link then
            local pay = costAmount * packs
            local currencyID = tonumber(link:match("currency:(%d+)"))
            if currencyID or (link:find("currency", 1, true)) then
                if currencyID then
                    local have = GetCurrencyQuantity(currencyID, link, wallet)
                    wallet.currencies[currencyID] = math.max(0, have - pay)
                end
            else
                local itemID = tonumber(link:match("item:(%d+)"))
                if itemID then
                    local have = GetCostItemQuantity(itemID, wallet)
                    wallet.items[itemID] = math.max(0, have - pay)
                end
            end
        end
    end
end

--- Purchase math (Restocker model): buy only the items still needed, even when
--- the merchant sells fixed batch sizes (e.g. need 1 from a 5-stack vendor).
--- Caps by gold and alt currency/item costs so short funds still buy a partial.
--- wallet (optional): { money, currencies={}, items={} } for multi-buy tracking.
function FV.ComputeRestockPurchaseQty(needed, meta, playerMoney, itemID, wallet)
    needed = math.floor(tonumber(needed) or 0)
    if needed <= 0 or not meta then
        return 0, 0
    end
    local maxStack = math.max(1, tonumber(meta.maxStack) or 1)
    local buyQty = math.min(needed, maxStack)

    if wallet and wallet.money ~= nil then
        playerMoney = wallet.money
    end

    local unitPrice = ResolveUnitPrice(meta)
    if unitPrice > 0 and playerMoney ~= nil then
        local affordable = math.floor((tonumber(playerMoney) or 0) / unitPrice)
        buyQty = math.min(buyQty, math.max(0, affordable))
    end

    local altAfford = AffordableFromAltCosts(meta.slot, meta.batchQty, wallet)
    if altAfford ~= nil then
        buyQty = math.min(buyQty, altAfford)
        -- Alt costs are priced per merchant batch; request whole packs only.
        local batchQty = math.max(1, tonumber(meta.batchQty) or 1)
        if batchQty > 1 then
            buyQty = math.floor(buyQty / batchQty) * batchQty
        end
    end

    if meta.numAvailable and meta.numAvailable > 0 then
        buyQty = math.min(buyQty, meta.numAvailable)
    end

    buyQty = math.floor(buyQty)
    if buyQty <= 0 then
        return 0, 0
    end
    return buyQty, buyQty
end

--- True when this merchant line should enter the buy queue. Blizzard sets
--- isPurchasable=false when funds are short of a full listed purchase; those
--- still queue when a partial qty is affordable. Reputation/level gates (funds
--- OK for a full purchase but still not purchasable) stay excluded.
local function ShouldQueueRestockBuy(meta, need, wallet)
    if not meta then
        return false
    end
    if meta.isPurchasable then
        return true
    end
    local money = wallet and wallet.money or GetMoney()
    if CanAffordFullListedPurchase(meta, money, wallet) then
        return false
    end
    local qty = FV.ComputeRestockPurchaseQty(need, meta, money, nil, wallet)
    return qty > 0
end

-- ---------------------------------------------------------------------------
-- BUY QUEUE
-- ---------------------------------------------------------------------------

local function BuildBuyQueue()
    local index = FV.GetMerchantItemIndex(false)
    if not index or indexBuildPending then
        return nil
    end
    local entries = FV.GetRestockTargetItems and FV.GetRestockTargetItems({ merchantAware = true }) or {}
    local queue = {}
    local ListMod = List()
    local TiersMod = _G.FluxRestockTiers
    local wallet = { money = GetMoney(), currencies = {}, items = {} }
    for _, entry in ipairs(entries) do
        if entry.isTierRestock and TiersMod then
            entry.bagCount = TiersMod.GetTierCount(entry.tierKind, index) or 0
            if entry.countBank then
                entry.bankCount = TiersMod.GetBankCountForKind(entry.tierKind, index) or 0
            end
        end
        local need = ListMod and ListMod.EntryNeed(entry) or 0
        if need > 0 then
            if entry.isTierRestock then
                -- Skip lower-tier-only vendors: never restock below threshold.
                if entry.vendorHasStock and entry.merchantSlot and entry.merchantItemID then
                    local meta = index[entry.merchantItemID]
                    if ShouldQueueRestockBuy(meta, need, wallet) then
                        queue[#queue + 1] = {
                            itemID = entry.merchantItemID,
                            slot = entry.merchantSlot,
                            need = need,
                            meta = meta,
                            tierKind = entry.tierKind,
                        }
                    end
                end
            elseif entry.vendorSold and entry.itemID then
                local meta = index[entry.itemID]
                if ShouldQueueRestockBuy(meta, need, wallet) then
                    queue[#queue + 1] = {
                        itemID = entry.itemID,
                        slot = meta.slot,
                        need = need,
                        meta = meta,
                    }
                end
            end
        end
    end
    return queue
end

local function FinishBuySession()
    local wasManual = buyState.manual
    local boughtAny = buyState.boughtAny
    local flushAfter = buyState.flushUIAfterBuy
    buyState.active = false
    buyState.manual = false
    buyState.queue = nil
    buyState.passes = 0
    buyState.flushUIAfterBuy = nil
    if boughtAny then
        local TiersMod = Tiers()
        if TiersMod and TiersMod.InvalidateTierQueryCache then
            pcall(TiersMod.InvalidateTierQueryCache)
        end
        local nc = _G.FluxNCItemDetection
        if nc then
            if nc.InvalidateFoodWaterCache then nc.InvalidateFoodWaterCache() end
            if nc.ScheduleFoodWaterUpdate then
                nc.ScheduleFoodWaterUpdate({ changeKind = "identityChanged", force = true })
            end
        end
    end
    if flushAfter or wasManual or boughtAny then
        FlushVendorTierUI()
    else
        local ui = MUI()
        if ui and IsMerchantOpen() then
            if ui.MarkRestockSettingsDirty then ui.MarkRestockSettingsDirty() end
            if ui.ScheduleMerchantUpdate then ui.ScheduleMerchantUpdate("data") end
        end
    end
    if not batchState.active and buyState.boughtAny and wasManual then
        buyState.boughtAny = false
    end
end

local function RunBuyPass()
    if not buyState.active then
        return
    end
    if not IsMerchantOpen() then
        FinishBuySession()
        return
    end
    buyState.passes = buyState.passes + 1
    if buyState.passes > 40 then
        FinishBuySession()
        return
    end
    local queue = buyState.queue
    if not queue or #queue == 0 then
        FinishBuySession()
        return
    end

    local inv = Inv()
    local calls = 0
    local wallet = {
        money = GetMoney(),
        currencies = {},
        items = {},
    }
    local i = 1
    while i <= #queue and calls < BUY_CALLS_PER_PASS do
        local task = queue[i]
        -- Queued slots can change identity even after the index has refreshed.
        if task.need <= 0 or not task.meta
            or ResolveMerchantSlotItemID(task.slot) ~= task.itemID then
            table.remove(queue, i)
        else
            local buyQty, received = FV.ComputeRestockPurchaseQty(
                task.need, task.meta, wallet.money, task.itemID, wallet)
            if buyQty <= 0 then
                table.remove(queue, i)
            else
                BuyMerchantItem(task.slot, buyQty)
                DeductPurchaseFromWallet(wallet, task.meta, received)
                local unitPrice = ResolveUnitPrice(task.meta)
                FV.AddBatchCopper(-math.floor(unitPrice * received + 0.5))
                task.need = task.need - received
                buyState.boughtAny = true
                calls = calls + 1
                if inv then inv.NotifyAutomationPulse(0.5) end
                if task.need <= 0 then
                    table.remove(queue, i)
                end
            end
        end
    end

    if #queue == 0 then
        FinishBuySession()
    end
    -- Otherwise the next merchant bag pulse continues the queue.
end

local function StartBuySession(manual)
    if not IsMerchantOpen() then
        return false
    end
    if buyState.active then
        return true
    end
    -- Index not ready yet: arm pending start and kick a build if needed.
    if indexBuildPending or not merchantIndex then
        buyState.pendingStart = manual and "manual" or "auto"
        if not merchantIndex and not indexBuildPending then
            FV.GetMerchantItemIndex(false)
        end
        return true
    end
    local queue = BuildBuyQueue()
    if not queue or #queue == 0 then
        return false
    end
    buyState.active = true
    buyState.manual = manual == true
    buyState.queue = queue
    buyState.passes = 0
    buyState.boughtAny = false
    RunBuyPass()
    return true
end

function Buy.OnIndexReady(mode)
    local ui = MUI()
    if ui and IsMerchantOpen() then
        if ui.ScheduleMerchantUpdate then
            ui.ScheduleMerchantUpdate(mode or "data")
        elseif ui.UpdateMerchantUI then
            ui.UpdateMerchantUI(mode or "data")
        end
    end
    if _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive()
        and _G.FluxRestockPanel_RefreshMerchantAvailability then
        pcall(_G.FluxRestockPanel_RefreshMerchantAvailability)
    end
    if buyState.pendingStart then
        local mode = buyState.pendingStart
        buyState.pendingStart = nil
        StartBuySession(mode == "manual")
    end
end

function FV.IsRestockBuyActive()
    return buyState.active
end

function FV.IsVendorBurstActive()
    if vendorOpenStormActive then
        return true
    end
    local inv = Inv()
    if inv and inv.IsAutomationQuiet() then
        return true
    end
    return buyState.active or (FV.IsJunkSellActive and FV.IsJunkSellActive()) or false
end

local function NotifyVendorOpenStormSettled()
    local ui = MUI()
    if ui and ui.OnVendorOpenStormSettled then
        pcall(ui.OnVendorOpenStormSettled)
    end
    if MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown() and MerchantFrame_UpdateMerchantInfo then
        After(0, function()
            if IsMerchantOpen() then
                pcall(MerchantFrame_UpdateMerchantInfo)
            end
        end)
    end
end

local function BeginVendorOpenStorm()
    vendorOpenStormGen = vendorOpenStormGen + 1
    vendorOpenStormActive = true
    local gen = vendorOpenStormGen
    After(VENDOR_OPEN_STORM_SEC, function()
        if gen ~= vendorOpenStormGen then
            return
        end
        vendorOpenStormActive = false
        NotifyVendorOpenStormSettled()
    end)
end

local function CancelVendorOpenStorm()
    vendorOpenStormGen = vendorOpenStormGen + 1
    vendorOpenStormActive = false
end

function FV.DoRestockManual()
    if not IsMerchantOpen() then return false end
    local TiersMod = Tiers()
    -- Re-detect vendor tier bumps using bag-owned (not vendor Best) so pending sell arms.
    if TiersMod and TiersMod.ApplyVendorTierUpgrades and merchantIndex then
        if TiersMod.WarmMerchantTierItems then
            pcall(TiersMod.WarmMerchantTierItems, merchantIndex, { sync = true })
        end
        pcall(TiersMod.ApplyVendorTierUpgrades, merchantIndex)
    end
    -- Wait for inferior publish so Food_A is marked before sell/buy.
    if TiersMod and TiersMod.IsInferiorPassComplete and not TiersMod.IsInferiorPassComplete() then
        if TiersMod.EnsureInferiorMarksForVendor then
            pcall(TiersMod.EnsureInferiorMarksForVendor, merchantIndex)
        end
        restockManualRetryGen = restockManualRetryGen + 1
        local myGen = restockManualRetryGen
        local attempt = 0
        local function retry()
            if myGen ~= restockManualRetryGen or not IsMerchantOpen() then
                return
            end
            attempt = attempt + 1
            if TiersMod.IsInferiorPassComplete and not TiersMod.IsInferiorPassComplete()
                and attempt < RESTOCK_MANUAL_RETRY_MAX then
                if TiersMod.EnsureInferiorMarksForVendor then
                    pcall(TiersMod.EnsureInferiorMarksForVendor, merchantIndex)
                end
                After(0.12, retry)
                return
            end
            FV.DoRestockManual()
        end
        After(0.12, retry)
        return true
    end

    BeginBatch()
    buyState.flushUIAfterBuy = true
    local sj = SellJunk()
    local selling = false
    if TrySellVendorUpgradeInferior(true) then
        selling = sj and sj.IsSelling and sj.IsSelling() or false
        if selling then
            restockPendingSellAttempts = 0
            buyState.deferredAutoBuy = true
            return true
        end
        -- Start returned true but finished immediately — treat as not selling.
        if sj and sj.IsSelling and sj.IsSelling() then
            restockPendingSellAttempts = 0
            buyState.deferredAutoBuy = true
            return true
        end
    end
    -- Pending upgrade sell still armed: do not buy until old kind stock is gone or cleared.
    local pending = GetPendingVendorUpgradeKinds()
    if pending and next(pending) then
        ClearPendingIfNoInferiorLeft(pending)
        pending = GetPendingVendorUpgradeKinds()
    end
    if pending and next(pending) then
        restockPendingSellAttempts = restockPendingSellAttempts + 1
        if restockPendingSellAttempts <= RESTOCK_MANUAL_RETRY_MAX then
            buyState.deferredAutoBuy = true
            restockManualRetryGen = restockManualRetryGen + 1
            local myGen = restockManualRetryGen
            After(0.15, function()
                if myGen ~= restockManualRetryGen or not IsMerchantOpen() then
                    return
                end
                buyState.deferredAutoBuy = nil
                FV.DoRestockManual()
            end)
            return true
        end
        if Tiers() and Tiers().ClearPendingVendorUpgradeKinds then
            Tiers().ClearPendingVendorUpgradeKinds(pending)
        end
        restockPendingSellAttempts = 0
    else
        restockPendingSellAttempts = 0
    end
    local started = StartBuySession(true)
    if not started then
        FinishBatch()
        FlushVendorTierUI()
    end
    return started
end

function FV.TriggerAutoRestock()
    if not IsMerchantOpen() then return end
    if not Settings().autoRestock then return end
    StartBuySession(false)
end

--- Repair + sell junk on the first open tick (no index / WarmMerchant wait).
local function StartFastAutoVendorActions()
    if merchantAutoBatchShiftSkipped or not IsMerchantOpen() then
        return
    end
    local settings = Settings()
    if not (settings.autoRepair or settings.autoSellGray or settings.autoRestock) then
        return
    end

    if not batchState.active then
        BeginBatch()
    end

    if settings.autoRepair and FV.TriggerAutoRepair then
        FV.TriggerAutoRepair()
    end

    if settings.autoSellGray and FV.TrySellJunkItems then
        FV.TrySellJunkItems()
        fastAutoSellStarted = true
        local sj = SellJunk()
        local selling = sj and sj.IsSelling and sj.IsSelling() or false
        if selling then
            junkSellWasActive = true
        end
        if settings.autoRestock then
            buyState.deferredAutoBuy = true
            buyState.flushUIAfterBuy = true
        end
        return
    end

    if settings.autoRestock then
        -- Index may not be ready yet; batch / deferred buy starts it after index.
        buyState.deferredAutoBuy = true
        buyState.flushUIAfterBuy = true
    else
        -- Repair-only (sell already returned above when enabled).
        FinishBatch()
    end
end

function FV.RunAutoVendorBatch()
    if not IsMerchantOpen() then return end
    local settings = Settings()
    local TiersMod = Tiers()
    -- Prefer live pending kinds; Peek returns { any, kinds }.
    local upgradeSession = TiersMod and TiersMod.PeekVendorUpgradeSession and TiersMod.PeekVendorUpgradeSession()
    local upgraded = (upgradeSession and upgradeSession.any)
        or (TiersMod and TiersMod.HasPendingVendorUpgradeRestock and TiersMod.HasPendingVendorUpgradeRestock())

    -- Only block on inferior publish when an upgrade sell is pending.
    if upgraded and TiersMod and TiersMod.IsInferiorPassComplete
        and not TiersMod.IsInferiorPassComplete() then
        autoBatchInferiorWait = (autoBatchInferiorWait or 0) + 1
        if autoBatchInferiorWait <= TIER_UPGRADE_RETRY_MAX then
            if TiersMod.EnsureInferiorMarksForVendor then
                pcall(TiersMod.EnsureInferiorMarksForVendor, merchantIndex)
            end
            After(0.15, function()
                if IsMerchantOpen() then
                    FV.RunAutoVendorBatch()
                end
            end)
            return
        end
        autoBatchInferiorWait = 0
    else
        autoBatchInferiorWait = 0
    end

    if not batchState.active then
        BeginBatch()
    end
    -- Repair already handled in StartFastAutoVendorActions when possible.
    if settings.autoRepair and FV.TriggerAutoRepair and not fastAutoSellStarted then
        FV.TriggerAutoRepair()
    end

    local function runSellAndBuy()
        if not IsMerchantOpen() then
            return
        end
        local sj = SellJunk()
        local selling = sj and sj.IsSelling and sj.IsSelling() or false

        if upgraded and settings.autoRestock and TrySellVendorUpgradeInferior(true) then
            selling = sj and sj.IsSelling and sj.IsSelling() or false
            if selling then
                buyState.deferredAutoBuy = true
                buyState.flushUIAfterBuy = true
                if settings.autoSellGray and not fastAutoSellStarted then
                    buyState.deferredSellAllJunk = true
                end
                return
            end
        elseif upgraded and settings.autoSellGray and not settings.autoRestock
            and TrySellVendorUpgradeInferior(true) then
            buyState.flushUIAfterBuy = true
            return
        end

        -- Regular junk sell: only if fast path did not already start it.
        if settings.autoSellGray and FV.TrySellJunkItems and not fastAutoSellStarted then
            if sj and sj.HasRemaining and sj.HasRemaining("all") then
                FV.TrySellJunkItems()
                selling = sj.IsSelling and sj.IsSelling() or false
            end
        elseif fastAutoSellStarted then
            selling = sj and sj.IsSelling and sj.IsSelling() or false
        end

        if settings.autoRestock then
            if selling then
                buyState.deferredAutoBuy = true
                buyState.flushUIAfterBuy = true
            else
                buyState.deferredAutoBuy = nil
                buyState.flushUIAfterBuy = true
                StartBuySession(false)
            end
        end
    end

    if settings.autoSellGray or settings.autoRestock or upgraded then
        After(0, runSellAndBuy)
    else
        FinishBatch()
    end
end

-- ---------------------------------------------------------------------------
-- MERCHANT SESSION EVENTS
-- ---------------------------------------------------------------------------

local merchantUpdateTimer = nil
local merchantUpdateDebounceGen = 0

local function OnMerchantPulse()
    if not IsMerchantOpen() then return end
    local ui = MUI()
    if ui and ui.MarkVendorBagPulseStart then
        ui.MarkVendorBagPulseStart()
    end
    local sj = SellJunk()
    local stillSelling = false
    if sj and sj.ContinueIfNeeded then
        stillSelling = sj.ContinueIfNeeded()
    end
    if junkSellWasActive and not stillSelling then
        FlushEbsButtonIdentityRefresh()
    end
    junkSellWasActive = stillSelling
    if not stillSelling then
        if buyState.deferredSellAllJunk then
            buyState.deferredSellAllJunk = nil
            local settings = Settings()
            if settings.autoSellGray and FV.TrySellJunkItems and sj and sj.HasRemaining
                and sj.HasRemaining("all") then
                FV.TrySellJunkItems()
                if sj.IsSelling and sj.IsSelling() then
                    junkSellWasActive = true
                end
            end
        end
        if not (sj and sj.IsSelling and sj.IsSelling()) and buyState.deferredAutoBuy then
            buyState.deferredAutoBuy = nil
            local manual = buyState.flushUIAfterBuy == true
            buyState.flushUIAfterBuy = true
            local started = StartBuySession(manual)
            if not started then
                -- Nothing to buy after upgrade sell — one flush for the settle.
                FlushVendorTierUI()
                buyState.flushUIAfterBuy = nil
                FinishBatch()
            end
        end
    end
    if buyState.active then
        RunBuyPass()
    end
    if ui and ui.MarkVendorBagPulseDone then
        ui.MarkVendorBagPulseDone()
    end
    if IsAutomationRunning() then
        return
    end
    local inv = Inv()
    if inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() then
        SchedulePostBurstMerchantUI()
        return
    end
    local VSR = _G.FluxVendorSessionRefresh
    if VSR and VSR.RequestVendorRefresh then
        VSR.RequestVendorRefresh({ junk = true, restockData = true })
    elseif ui then
        if ui.ScheduleJunkUIRefresh then ui.ScheduleJunkUIRefresh(false) end
        if ui.ScheduleMerchantUpdate then ui.ScheduleMerchantUpdate("data") end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_UPDATE")
frame:RegisterEvent("MERCHANT_CLOSED")
pcall(function() frame:RegisterEvent("UI_ERROR_MESSAGE") end)

frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "MERCHANT_SHOW" then
        local inv = Inv()
        if inv and inv.SetMerchantOpen then
            inv.SetMerchantOpen(true)
        end
        frame:RegisterEvent("BAG_UPDATE_DELAYED")
        BeginVendorOpenStorm()
        local VSR = _G.FluxVendorSessionRefresh
        if VSR and VSR.BeginVendorSession then
            VSR.BeginVendorSession()
        end
        FV.EnsureSettings()
        fastAutoSellStarted = false
        deferredTierPassGen = deferredTierPassGen + 1
        if NeedsMerchantIndexOnOpen() then
            FV.InvalidateMerchantIndex()
        end
        merchantAutoBatchPending = NeedsAutoVendorBatchAfterIndex()
        merchantAutoBatchShiftSkipped = IsShiftKeyDown and IsShiftKeyDown() or false
        if merchantAutoBatchShiftSkipped then
            merchantAutoBatchPending = false
        end
        After(0, function()
            if not IsMerchantOpen() then
                return
            end
            local ui = MUI()
            local layoutMode = NeedsVendorAutomation() and "full" or "idle"
            if ui and ui.RunPipelineLayout then
                ui.RunPipelineLayout(layoutMode)
            elseif ui and ui.UpdateMerchantUI then
                ui.UpdateMerchantUI("layout")
            end
            -- Sell/repair first tick — do not wait for index or WarmMerchant.
            if not merchantAutoBatchShiftSkipped then
                StartFastAutoVendorActions()
            end
            if NeedsMerchantIndexOnOpen() then
                After(0, function()
                    if IsMerchantOpen() then
                        FV.GetMerchantItemIndex(false)
                    end
                end)
            else
                merchantAutoBatchPending = false
            end
        end)
        return
    end

    if event == "MERCHANT_UPDATE" then
        if not IsMerchantOpen() then return end
        if merchantUpdateTimer then return end
        merchantUpdateTimer = true
        merchantUpdateDebounceGen = merchantUpdateDebounceGen + 1
        local myGen = merchantUpdateDebounceGen
        After(0.25, function()
            if myGen ~= merchantUpdateDebounceGen then
                return
            end
            merchantUpdateTimer = nil
            if IsMerchantOpen() then
                FV.GetMerchantItemIndex(true)
                local ui = MUI()
                if ui and ui.ScheduleMerchantUpdate then
                    ui.ScheduleMerchantUpdate("data")
                end
            end
        end)
        return
    end

    if event == "MERCHANT_CLOSED" then
        local inv = Inv()
        if inv and inv.SetMerchantOpen then
            inv.SetMerchantOpen(false)
        end
        frame:UnregisterEvent("BAG_UPDATE_DELAYED")
        CancelVendorOpenStorm()
        merchantUpdateDebounceGen = merchantUpdateDebounceGen + 1
        merchantUpdateTimer = nil
        indexGeneration = indexGeneration + 1
        indexBuildPending = false
        CancelPostBurstMerchantUI()
        tierUpgradeRetryGen = tierUpgradeRetryGen + 1
        tierUpgradeRetryCount = 0
        local VSR = _G.FluxVendorSessionRefresh
        if VSR and VSR.EndVendorSession then
            VSR.EndVendorSession()
        end
        local TiersMod = Tiers()
        if TiersMod and TiersMod.CancelBackgroundWork then
            pcall(TiersMod.CancelBackgroundWork)
        elseif TiersMod and TiersMod.CancelPendingRecompute then
            pcall(TiersMod.CancelPendingRecompute)
        end
        if TiersMod and TiersMod.ClearMerchantWarmSet then
            pcall(TiersMod.ClearMerchantWarmSet)
        end
        if TiersMod and TiersMod.ClearVendorInferiorSnapshot then
            pcall(TiersMod.ClearVendorInferiorSnapshot)
        end
        merchantAutoBatchPending = false
        merchantAutoBatchShiftSkipped = false
        fastAutoSellStarted = false
        deferredTierPassGen = deferredTierPassGen + 1
        junkSellWasActive = false
        local sj = SellJunk()
        if sj and sj.OnMerchantClosed then
            sj.OnMerchantClosed()
        end
        buyState.active = false
        buyState.queue = nil
        buyState.deferredAutoBuy = nil
        buyState.deferredSellAllJunk = nil
        buyState.pendingStart = nil
        FV.InvalidateMerchantIndex()
        FinishBatch()
        local ui = MUI()
        if ui and ui.OnMerchantClosed then
            ui.OnMerchantClosed()
        end
        FlushEbsButtonIdentityRefresh()
        -- Only repaint junk overlays if bag frames are actually shown.
        local bagsVisible = false
        if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown() then
            bagsVisible = true
        else
            local i = 1
            local frame = _G["ContainerFrame" .. i]
            while frame do
                if frame:IsShown() then
                    bagsVisible = true
                    break
                end
                i = i + 1
                frame = _G["ContainerFrame" .. i]
            end
        end
        local overlay = _G.FluxJunkOverlay
        if overlay and overlay.CancelInferiorRepaintBurst then
            pcall(overlay.CancelInferiorRepaintBurst)
        end
        if bagsVisible then
            RefreshJunkOverlaysAfterInferior()
            if overlay and overlay.FlushDeferredPaint then
                pcall(overlay.FlushDeferredPaint, true)
            end
        end
        return
    end

    if event == "BAG_UPDATE_DELAYED" then
        if IsMerchantOpen() then
            OnMerchantPulse()
        end
        return
    end

    if event == "UI_ERROR_MESSAGE" then
        -- Bag full / too many of item: stop buying.
        local msg = tostring(arg2 or arg1 or "")
        if buyState.active and (msg == ERR_INV_FULL or msg == ERR_ITEM_MAX_COUNT) then
            FinishBuySession()
        end
        -- Merchant sell flood: back off and retry remaining junk.
        local sj = SellJunk()
        local selling = (sj and sj.IsSelling and sj.IsSelling())
            or (FV.IsJunkSellActive and FV.IsJunkSellActive())
        if selling then
            local busy = (ERR_OBJECT_IS_BUSY and msg == ERR_OBJECT_IS_BUSY)
                or (type(msg) == "string" and msg:lower():find("busy", 1, true))
            if busy then
                if sj and sj.OnMerchantBusy then
                    sj.OnMerchantBusy()
                elseif FV.OnJunkSellBusy then
                    FV.OnJunkSellBusy()
                end
            end
        end
        return
    end
end)

-- ---------------------------------------------------------------------------
-- COMPAT: FluxVendorOpenPipeline (kept UI files poke it defensively)
-- ---------------------------------------------------------------------------

FluxVendorOpenPipeline = {
    IsVendorStormSilenceActive = function() return vendorOpenStormActive end,
    IsBusy = function() return vendorOpenStormActive end,
    IsVendorOpenBurstActive = function() return FV.IsVendorBurstActive() end,
    WhenPostOpenSettled = function(fn)
        if type(fn) ~= "function" then
            return
        end
        if not vendorOpenStormActive then
            After(0, fn)
            return
        end
        After(VENDOR_OPEN_STORM_SEC, fn)
    end,
    WhenReady = function(_, fn)
        if type(fn) == "function" then
            After(0, fn)
        end
    end,
    OnMerchantShow = function() end,
    EnqueueOpen = function() end,
    RunPhaseLayout = function()
        local ui = MUI()
        if ui and ui.RunPipelineLayout then
            ui.RunPipelineLayout(NeedsVendorAutomation() and "full" or "idle")
        elseif ui and ui.UpdateMerchantUI then
            ui.UpdateMerchantUI("layout")
        end
    end,
    RequestFullTierScan = function(_, doneCb)
        if type(doneCb) == "function" then doneCb() end
    end,
}

_G.FluxVendorBuy = Buy
_G.FluxVendorOpenPipeline = FluxVendorOpenPipeline
return Buy
