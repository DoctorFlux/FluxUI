--[[
    Restock/Core/Tiers/FluxRestockTiers.lua

    Public facade + legacy globals for Options / Vendor / Junk.
]]

local Tiers = FluxRestockTiers
local P = Tiers._Private

local lastBagGen = -1
local lastBankGen = -1
local lastUniqueItemIDs = {}

local function SoftRefreshOpenTierCells()
    -- Options panel: refresh count text without full rebuild.
    local widget = _G.FluxRestockPanelWidget or _G.AceGUIWidgetFluxRestockPanel
    -- Hook used by AceGUI widget via global callback if registered.
    if Tiers._onCountsOnly then
        pcall(Tiers._onCountsOnly)
    end
    local FV = _G.FluxVendorAuto
    if FV and FV.InvalidateRestockOptionsPanelCache then
        -- Do NOT invalidate options cache on counts-only (avoids rebuild).
    end
end

function Tiers.NotifyTierCountsOnly()
    SoftRefreshOpenTierCells()
end

function Tiers.RegisterCountsOnlyHandler(fn)
    Tiers._onCountsOnly = fn
end

local function DiffUniqueItemIDs(unique)
    local added, removed = {}, {}
    local hasAdded, hasRemoved = false, false
    unique = unique or {}
    for itemID in pairs(unique) do
        itemID = tonumber(itemID)
        if itemID and not lastUniqueItemIDs[itemID] then
            added[itemID] = true
            hasAdded = true
        end
    end
    for itemID in pairs(lastUniqueItemIDs) do
        itemID = tonumber(itemID)
        if itemID and not unique[itemID] and not unique[tostring(itemID)] then
            removed[itemID] = true
            hasRemoved = true
        end
    end
    wipe(lastUniqueItemIDs)
    for itemID in pairs(unique) do
        itemID = tonumber(itemID)
        if itemID then
            lastUniqueItemIDs[itemID] = true
        end
    end
    return hasAdded and added or nil, hasRemoved and removed or nil
end

function Tiers.Init()
    if Tiers._initialized then
        return
    end
    Tiers._initialized = true
    Tiers.EnsureStores()

    local Best = P.Best()
    if Best and Best.RegisterListener then
        Best.RegisterListener("FluxRestockTiers", function()
            -- Owned/vendor best may have ratcheted; refresh counts + inferior marks.
            Tiers.RequestRecompute({ scope = "inferior", notify = true })
        end)
    end

    -- Bag/bank identity changes: instant mark added weaker consumables, then
    -- full inferior pass (V9 loot/buy behavior).
    local inv = P.Inv()
    local pendingInferiorSettle = false
    local pendingInferiorBagsOnly = false
    local pendingStormAdded = {}
    local pendingStormRemoved = {}
    local function mergeIdSet(dst, src)
        if not src then
            return
        end
        for itemID in pairs(src) do
            dst[itemID] = true
        end
    end
    local function SettleDeferredInferior()
        if not pendingInferiorSettle then
            return
        end
        pendingInferiorSettle = false
        local bagsOnly = pendingInferiorBagsOnly
        pendingInferiorBagsOnly = false
        local added = next(pendingStormAdded) and pendingStormAdded or nil
        local removed = next(pendingStormRemoved) and pendingStormRemoved or nil
        pendingStormAdded = {}
        pendingStormRemoved = {}
        if removed and Tiers.TryUnmarkRemovedItems then
            pcall(Tiers.TryUnmarkRemovedItems, removed)
        end
        local markResult = false
        if added and Tiers.TryMarkAddedItems then
            local ok, result = pcall(Tiers.TryMarkAddedItems, added)
            if ok then
                markResult = result
            end
        end
        Tiers.RequestRecompute({
            scope = "inferior",
            notify = markResult == true or added ~= nil,
            bagsOnly = bagsOnly == true,
        })
    end
    if inv and inv.Bank and inv.Bank.RegisterBankClose then
        inv.Bank.RegisterBankClose("FluxRestockTiers", function()
            if not pendingInferiorSettle then
                return
            end
            pendingInferiorBagsOnly = true
            SettleDeferredInferior()
        end)
    end
    if inv and inv.RegisterStormSettled then
        inv.RegisterStormSettled("FluxRestockTiers", function()
            SettleDeferredInferior()
        end)
    end
    if inv and inv.RegisterListener then
        inv.RegisterListener("FluxRestockTiers", function(ctx)
            local regions = ctx and ctx.regions
            if regions and not regions.bags and (regions.bank or regions.warband) then
                local open = (inv.IsBankOpen and inv.IsBankOpen())
                    or (inv.Bank and inv.Bank.IsOpen and inv.Bank.IsOpen())
                if not open then
                    return
                end
            end
            -- Stack-size-only: soft count refresh, no inferior mark/pass.
            if ctx and ctx.changeKind == "countOnly" then
                local bagGen = P.GetBagCacheGen()
                lastBagGen = bagGen
                Tiers.NotifyTierCountsOnly()
                return
            end
            local bagGen = P.GetBagCacheGen()
            if bagGen == lastBagGen then
                return
            end
            lastBagGen = bagGen
            Tiers.InvalidateTierQueryCache()

            local unique = inv.Bags and inv.Bags.GetUniqueItems and inv.Bags.GetUniqueItems() or {}
            local added, removed = DiffUniqueItemIDs(unique)

            -- Counts-only (same unique ID set): soft refresh panels; skip full inferior pass.
            if not added and not removed then
                Tiers.NotifyTierCountsOnly()
                return
            end

            -- Defer mark + inferior while bank/merchant open, automation quiet, or bag storm.
            local defer = (inv.ShouldDeferHeavyWork and inv.ShouldDeferHeavyWork())
                or (inv.IsAutomationQuiet and inv.IsAutomationQuiet())
            if defer then
                mergeIdSet(pendingStormAdded, added)
                mergeIdSet(pendingStormRemoved, removed)
                Tiers.NotifyTierCountsOnly()
                pendingInferiorSettle = true
                -- Bank-open defer → settle bags-only on close (bank maps not live after close).
                pendingInferiorBagsOnly = inv.IsBankOpen and inv.IsBankOpen() or false
                if inv.IsAutomationQuiet and inv.IsAutomationQuiet() and inv.OnQuietSettled then
                    inv.OnQuietSettled(SettleDeferredInferior)
                end
                if inv.IsBagStorm and inv.IsBagStorm() and inv.OnStormSettled then
                    inv.OnStormSettled(SettleDeferredInferior)
                end
                return
            end

            if removed and Tiers.TryUnmarkRemovedItems then
                pcall(Tiers.TryUnmarkRemovedItems, removed)
            end

            local markResult = false
            if added and Tiers.TryMarkAddedItems then
                local ok, result = pcall(Tiers.TryMarkAddedItems, added)
                if ok then
                    markResult = result
                end
            end

            if Tiers.ClearVendorInferiorSnapshot then
                pcall(Tiers.ClearVendorInferiorSnapshot)
            end

            Tiers.RequestRecompute({
                scope = "inferior",
                force = false,
                notify = markResult == true or added ~= nil,
            })
        end, { tier = "scan", regions = { "bags", "bank", "warband" }, deferHeavy = true })
    end

    P.After(1.5, function()
        -- Seed unique snapshot so the first real loot/buy diffs correctly.
        local invNow = P.Inv()
        if invNow and invNow.Bags and invNow.Bags.GetUniqueItems then
            DiffUniqueItemIDs(invNow.Bags.GetUniqueItems())
        end
        Tiers.RequestRecompute({ force = true, scope = "inferior", notify = true })
    end)
end

-- ---------------------------------------------------------------------------
-- Legacy facades (Options + Vendor panel still call these)
-- ---------------------------------------------------------------------------

local Combat = {}
function Combat.GetTarget(kind)
    return Tiers.GetTarget(kind)
end
function Combat.SetTarget(kind, quantity, skipNotify)
    return Tiers.SetTarget(kind, quantity, skipNotify)
end
function Combat.GetCurrentCount(kind)
    return Tiers.GetTierCount(kind)
end
function Combat.GetBankCountForKind(kind)
    return Tiers.GetBankCountForKind(kind)
end
function Combat.IsTierEligible(kind)
    return Tiers.IsTierEligible(kind)
end
function Combat.RememberOwnedTiers()
    return Tiers.RememberOwnedTiers()
end
function Combat.ApplyVendorTierStatusToEntry(entry, kind)
    if not entry or not kind then
        return
    end
    local status = Tiers.GetVendorTierStatus(kind)
    entry.merchantChecked = true
    entry.vendorHasStock = status.hasStock
    entry.vendorLowerTierOnly = status.lowerTierOnly
    entry.vendorNotSold = not status.hasStock and not status.lowerTierOnly
    -- Never attach purchase targets for lower-tier-only vendors.
    if status.hasStock then
        entry.merchantSlot = status.bestSlot
        entry.merchantItemID = status.bestItemID
        entry.unitPrice = status.bestPrice
    else
        entry.merchantSlot = nil
        entry.merchantItemID = nil
        entry.unitPrice = nil
    end
end
function Combat.PrepareInferiorForRestock()
    return Tiers.RecomputeInferior()
end
function Combat.GetRestockState(kind)
    return {
        target = Tiers.GetTarget(kind),
        count = Tiers.GetTierCount(kind),
        reference = Tiers.GetEffectiveReferenceTier(kind),
    }
end
function Combat.ToggleEditBox(btn, kind)
    if Tiers.ToggleEditBox then
        return Tiers.ToggleEditBox(btn, kind)
    end
end
function Combat.WireRestockClick(kind, btn, canCraft)
    if Tiers.WireRestockClick then
        return Tiers.WireRestockClick(kind, btn, canCraft)
    end
end
function Combat.AppendRestockTooltipLines(tip, kind, setClickHint, labelOverride, skipLeadingBlank)
    if Tiers.AppendRestockTooltipLines then
        return Tiers.AppendRestockTooltipLines(tip, kind, setClickHint, labelOverride, skipLeadingBlank)
    end
end

local FFWR = {}
function FFWR.GetTierCount(kind, merchantAware)
    return Tiers.GetTierCount(kind, merchantAware and true or nil)
end
function FFWR.CountBankForRestockKind(kind)
    return Tiers.GetBankCountForKind(kind)
end
function FFWR.GetTargets()
    return {
        food = Tiers.GetTarget("food"),
        water = Tiers.GetTarget("water"),
    }
end
function FFWR.IsEligible()
    return Tiers.IsTierEligible("food")
end
function FFWR.IsWaterEligible()
    return Tiers.IsTierEligible("water")
end
function FFWR.ToggleEditBox(btn, kind)
    if Tiers.ToggleEditBox then
        return Tiers.ToggleEditBox(btn, kind)
    end
end
function FFWR.ApplyVendorTierStatusToEntry(entry, kind)
    return Combat.ApplyVendorTierStatusToEntry(entry, kind)
end
function FFWR.VendorHasTierFoodWater()
    local f = Tiers.GetVendorTierStatus("food")
    local w = Tiers.GetVendorTierStatus("water")
    return (f and f.hasStock) or (w and w.hasStock)
end
function FFWR.GetVendorTierInfo(kind)
    return Tiers.GetVendorTierStatus(kind)
end

-- Thin shim so FluxMacroClickProxies Food/Water restock toggles keep working.
FluxNCFoodWaterRestockUI = FluxNCFoodWaterRestockUI or {}
function FluxNCFoodWaterRestockUI.ToggleEditBox(btn, kind)
    if Tiers.ToggleEditBox then
        Tiers.ToggleEditBox(btn, kind)
    end
end
function FluxNCFoodWaterRestockUI.SuppressCheckedVisual(btn)
    local Bridge = _G.FluxEBSConsumableBridge
    if Bridge and Bridge.SuppressCheckedVisual then
        Bridge.SuppressCheckedVisual(btn)
    end
end
_G.FluxNCFoodWaterRestockUI = FluxNCFoodWaterRestockUI

local JunkSync = {}
function JunkSync.Schedule()
    Tiers.RequestRecompute({ scope = "inferior" })
end
function JunkSync.RunNow()
    Tiers.RecomputeInferior(nil, { forceVendorSeen = true })
end
function JunkSync.GetInferiorTierReferences()
    local out = {}
    for _, kind in ipairs(P.KINDS) do
        out[kind] = Tiers.GetInferiorReferenceTier(kind)
    end
    return out
end

_G.FluxCombatItemRestock = Combat
_G.FluxVendorFoodWaterRestock = FFWR
_G.FluxConsumableJunkSync = JunkSync
_G.FluxRestockTiers = Tiers

P.After(0, function()
    Tiers.Init()
end)

return Tiers
