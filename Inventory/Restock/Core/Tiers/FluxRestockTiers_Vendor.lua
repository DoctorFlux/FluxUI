--[[
    Restock/Core/Tiers/FluxRestockTiers_Vendor.lua
]]

local Tiers = FluxRestockTiers
local P = Tiers._Private

local function ResolveMerchantIndex(merchantIndex)
    if type(merchantIndex) == "table" then
        return merchantIndex
    end
    local FV = _G.FluxVendorBuy or _G.FluxVendorAuto
    if FV and FV.GetMerchantItemIndex then
        return FV.GetMerchantItemIndex(false)
    end
    return nil
end
P.ResolveMerchantIndex = ResolveMerchantIndex

local function ComputeVendorTierStatus(kind, merchantIndex)
    local status = { hasStock = false, lowerTierOnly = false }
    merchantIndex = ResolveMerchantIndex(merchantIndex)
    if not merchantIndex then
        return status
    end
    local purchaseThreshold = P.GetTierRestockThreshold(kind, merchantIndex)
    local sawAny = false
    local bestValue, bestSlot, bestItemID, bestPrice = 0, nil, nil, nil
    local bestAnyValue = 0
    for itemID, meta in pairs(merchantIndex) do
        itemID = tonumber(itemID) or (type(meta) == "table" and tonumber(meta.itemID))
        if itemID and type(meta) == "table" and meta.isPurchasable ~= false then
            local cls = P.ClassifyMerchantItem(kind, itemID, meta)
            if cls then
                local v = P.TierAxisValue(kind, cls)
                local usableAxis = v > 0 and not (kind == "food" and cls.wellFed)
                if usableAxis and P.IsTierItemUsable(kind, itemID, { vendor = true }) then
                    sawAny = true
                    local unitPrice = meta.unitPrice or meta.price
                    if v > bestAnyValue then
                        bestAnyValue = v
                    end
                    if purchaseThreshold <= 0 or P.RoundTier(v) >= purchaseThreshold then
                        if v > bestValue or (v == bestValue and unitPrice and bestPrice and unitPrice < bestPrice) then
                            bestValue = v
                            bestSlot = meta.slot
                            bestItemID = itemID
                            bestPrice = unitPrice
                        end
                    end
                end
            end
        end
    end
    if bestSlot then
        status.hasStock = true
        status.bestSlot = bestSlot
        status.bestItemID = bestItemID
        status.bestValue = bestValue
        status.bestPrice = bestPrice
    elseif sawAny then
        -- Vendor has matching items, but all are below the restock threshold.
        -- Do not expose purchase slots — never restock lower tiers.
        status.lowerTierOnly = true
        status.bestValue = bestAnyValue
    end
    return status
end

function Tiers.GetVendorTierStatus(kind, merchantIndex)
    local bagGen = P.GetBagCacheGen()
    local merchantGen = P.GetMerchantCacheGen()
    local cacheKey = tostring(kind)
    if P.vendorStatusCache.bagGen == bagGen and P.vendorStatusCache.merchantGen == merchantGen then
        local cached = P.vendorStatusCache.kinds[cacheKey]
        if cached then
            return cached
        end
    else
        P.vendorStatusCache.bagGen = bagGen
        P.vendorStatusCache.merchantGen = merchantGen
        wipe(P.vendorStatusCache.kinds)
    end
    local status = ComputeVendorTierStatus(kind, merchantIndex)
    P.vendorStatusCache.kinds[cacheKey] = status
    return status
end

function Tiers.AppendTierReferenceLines(tooltip, kind)
    if not tooltip or not P.KIND_FIELDS[kind] then
        return
    end
    local ref = Tiers.GetCachedTooltipReferenceTier(kind)
    if ref > 0 then
        local axis = (kind == "water" or kind == "manaPotion") and "mana" or "health"
        tooltip:AddLine(
            string.format("Current tier: restores ~%d %s.", P.RoundTier(ref), axis),
            0.6, 0.8, 1, true
        )
    end
    local target = Tiers.GetTarget and Tiers.GetTarget(kind) or 0
    if target and target > 0 then
        local owned = select(1, Tiers.GetBagOwnedTier(kind)) or 0
        tooltip:AddLine(
            string.format("Restock target: %d (owned best ~%d).", target, P.RoundTier(owned)),
            0.5, 0.7, 0.5, true
        )
    end
end

function Tiers.SeedReferenceFromVendor(merchantIndex)
    merchantIndex = ResolveMerchantIndex(merchantIndex)
    if not merchantIndex then
        return false
    end
    if Tiers.BumpVendorSeenGeneration then
        Tiers.BumpVendorSeenGeneration()
    end
    local changed = false
    for _, kind in ipairs(P.KINDS) do
        if Tiers.IsTierEligible(kind) then
            -- Bootstrap only when both saved and bag-owned best are empty.
            local saved = P.GetSavedTier(kind) or 0
            local owned = select(1, Tiers.GetBagOwnedTier(kind)) or 0
            if saved <= 0 and owned <= 0 then
                local vendorBest, vendorItemID, meta = P.ScanVendorBestPurchasable(kind, merchantIndex)
                local v = P.RoundTier(vendorBest)
                if vendorItemID and v > 0 then
                    P.SetSavedTier(kind, v)
                    local Best = P.Best()
                    if Best and Best.Persist and Best.Persist.MaybeUpdateRef then
                        Best.Persist.MaybeUpdateRef(kind, {
                            itemID = vendorItemID,
                            effective = v,
                            isConjured = false,
                            source = "vendor",
                            price = meta and (meta.unitPrice or meta.price),
                        })
                    end
                    changed = true
                end
            end
        end
    end
    if changed then
        Tiers.InvalidateTierQueryCache()
    end
    return changed
end

function Tiers.ApplyVendorTierUpgrades(merchantIndex)
    merchantIndex = ResolveMerchantIndex(merchantIndex)
    local result = { any = false, kinds = {}, deferred = false }
    if not merchantIndex then
        return result
    end
    local s = P.Settings()
    s.pendingVendorTierSell = s.pendingVendorTierSell or { kinds = {} }
    s.pendingVendorTierSell.kinds = s.pendingVendorTierSell.kinds or {}
    for _, kind in ipairs(P.KINDS) do
        if Tiers.IsTierEligible(kind) and Tiers.IsMarkInferiorEnabled(kind) then
            local saved = P.GetSavedTier(kind) or 0
            -- Bag-only owned: Best.GetBest may already be the vendor item (count 0).
            local bagOwned = select(1, Tiers.GetBagOwnedTier(kind)) or 0
            local prevRef = P.RoundTier(math.max(saved, bagOwned))
            local vendorBest, vendorItemID, meta = P.ScanVendorBestPurchasable(kind, merchantIndex)
            local v = P.RoundTier(vendorBest)
            local function ArmPending(prev)
                result.kinds[kind] = {
                    value = v,
                    itemID = vendorItemID,
                    prevRef = prev,
                }
                result.any = true
                s.pendingVendorTierSell.kinds[kind] = {
                    value = v,
                    itemID = vendorItemID,
                    prevRef = prev,
                }
            end
            if v > prevRef and vendorItemID then
                P.SetSavedTier(kind, v)
                local Best = P.Best()
                if Best and Best.Persist and Best.Persist.MaybeUpdateRef then
                    Best.Persist.MaybeUpdateRef(kind, {
                        itemID = vendorItemID,
                        effective = v,
                        isConjured = false,
                        source = "vendor",
                        price = meta and (meta.unitPrice or meta.price),
                    })
                end
                ArmPending(prevRef)
            elseif vendorItemID and bagOwned > 0 and v > bagOwned then
                -- Saved already ratcheted, but bags still hold weaker stock — re-arm sell.
                ArmPending(bagOwned)
            elseif v <= 0 and Tiers.HasPendingMerchantTierClassification
                and Tiers.HasPendingMerchantTierClassification() then
                result.deferred = true
            end
        end
    end
    if result.any then
        result.deferred = false
        Tiers.InvalidateTierQueryCache()
        Tiers.ClearVendorInferiorSnapshot()
    end
    return result
end

function Tiers.RefreshTierReferences(merchantIndex)
    local seeded = Tiers.SeedReferenceFromVendor(merchantIndex)
    Tiers.RememberOwnedTiers()
    -- Skip a second EnsureInferior when RunVendorTierAndInferiorPass already
    -- stamped a fresh vendor inferior snapshot for this bag/merchant gen.
    local bagGen = P.GetBagCacheGen()
    local merchantGen = P.GetMerchantCacheGen()
    local snap = P.vendorInferiorSnapshot
    local needsInferior = not (snap and snap.bagGen == bagGen and snap.merchantGen == merchantGen)
    return seeded, needsInferior
end

function Tiers.GetVendorUpgradeKinds()
    local s = P.Settings()
    local pending = s.pendingVendorTierSell and s.pendingVendorTierSell.kinds
    return pending or {}
end

function Tiers.PeekVendorUpgradeSession()
    local kinds = Tiers.GetVendorUpgradeKinds()
    if not next(kinds) then
        return nil
    end
    return {
        any = true,
        kinds = kinds,
    }
end

function Tiers.HasPendingVendorUpgradeRestock()
    return next(Tiers.GetVendorUpgradeKinds()) ~= nil
end

function Tiers.ClearPendingVendorUpgradeKinds(kinds)
    local s = P.Settings()
    if not s.pendingVendorTierSell or not s.pendingVendorTierSell.kinds then
        return
    end
    if kinds then
        for kind in pairs(kinds) do
            s.pendingVendorTierSell.kinds[kind] = nil
        end
    else
        wipe(s.pendingVendorTierSell.kinds)
    end
    Tiers.ClearVendorInferiorSnapshot()
end

local function ItemNeedsMerchantClassification(itemID, link)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local IC = P.IC()
    if not IC then
        return true
    end
    local static = IC.GetStatic and IC.GetStatic(itemID)
    if static and static.classID ~= nil and static.classID ~= 0 then
        return false
    end
    if IC.RequestLoad and not (IC.IsLoaded and IC.IsLoaded(itemID)) then
        IC.RequestLoad(itemID)
        return true
    end
    if IC.ClassifyConsumable then
        local cls = IC.ClassifyConsumable(itemID, link)
        if cls and cls.stable == false then
            return true
        end
        if cls then
            return false
        end
        -- Cached non-consumable / no axes yet: wait for restore only while unloadable.
        if static and static.classID == 0 and IC.GetRestore then
            local restore = IC.GetRestore(itemID, link)
            if not restore or not restore.ready then
                return true
            end
        end
        return false
    end
    if IC.GetRestore then
        local restore = IC.GetRestore(itemID, link)
        if not restore or not restore.ready then
            return true
        end
    end
    return false
end

function Tiers.HasPendingMerchantTierClassification()
    if not next(P.merchantWarmItemIDs) then
        return false
    end
    local index = P.merchantWarmIndex or ResolveMerchantIndex(true)
    if not index then
        return true
    end
    for itemID in pairs(P.merchantWarmItemIDs) do
        local meta = index[itemID]
        if meta and meta.isPurchasable ~= false then
            if ItemNeedsMerchantClassification(itemID, P.MerchantItemLink(meta)) then
                return true
            end
        end
    end
    return false
end

function Tiers.ScheduleVendorTierRefresh(itemID)
    if not P.IsMerchantFrameOpen or not P.IsMerchantFrameOpen() then
        return
    end
    itemID = tonumber(itemID)
    if itemID and P.merchantWarmItemIDs[itemID] ~= true then
        return
    end
    if P.vendorTierRefresh.pending then
        return
    end
    P.vendorTierRefresh.pending = true
    P.vendorTierRefresh.gen = P.vendorTierRefresh.gen + 1
    local gen = P.vendorTierRefresh.gen
    P.After(0.05, function()
        if gen ~= P.vendorTierRefresh.gen then
            return
        end
        P.vendorTierRefresh.pending = false
        if not P.IsMerchantFrameOpen() then
            return
        end
        if Tiers.HasPendingMerchantTierClassification() then
            P.vendorTierRefresh.attempts = P.vendorTierRefresh.attempts + 1
            if P.vendorTierRefresh.attempts < P.VENDOR_TIER_REFRESH_MAX then
                Tiers.ScheduleVendorTierRefresh(itemID)
            else
                P.vendorTierRefresh.attempts = 0
                Tiers.RunVendorTierAndInferiorPass(true)
            end
            return
        end
        P.vendorTierRefresh.attempts = 0
        local changed, upgrade = Tiers.RunVendorTierAndInferiorPass(true)
        if upgrade and upgrade.any then
            local Buy = _G.FluxVendorBuy or _G.FluxVendorAuto
            if Buy and Buy.FlushVendorTierUI then
                pcall(Buy.FlushVendorTierUI, { afterQuiet = true })
            elseif Tiers.NotifyTierReferenceUIRefresh then
                Tiers.NotifyTierReferenceUIRefresh()
            end
            -- Late classification found an upgrade after the first open pass.
            local s = P.Settings()
            if Buy and Buy.RunAutoVendorBatch and (s.autoRestock or s.autoSellGray) then
                pcall(Buy.RunAutoVendorBatch)
            end
        elseif changed and Tiers.NotifyTierReferenceUIRefresh then
            Tiers.NotifyTierReferenceUIRefresh()
        end
    end)
end

function Tiers.WarmMerchantTierItems(merchantIndex, opts)
    opts = type(opts) == "table" and opts or {}
    merchantIndex = ResolveMerchantIndex(merchantIndex)
    if not merchantIndex then
        Tiers.ClearMerchantWarmSet()
        if opts.onComplete then
            pcall(opts.onComplete)
        end
        return
    end
    local indexGen = P.GetMerchantCacheGen()
    if P.merchantWarmSnapshotGen == indexGen and P.merchantWarmIndex and next(P.merchantWarmItemIDs) then
        if opts.onComplete then
            pcall(opts.onComplete)
        end
        return
    end
    P.merchantWarmSnapshotGen = indexGen
    wipe(P.merchantWarmItemIDs)
    P.merchantWarmIndex = merchantIndex
    local IC = P.IC()
    if not IC then
        if opts.onComplete then
            pcall(opts.onComplete)
        end
        return
    end

    local list = {}
    for itemID, meta in pairs(merchantIndex) do
        itemID = tonumber(itemID) or (type(meta) == "table" and tonumber(meta.itemID))
        if itemID and type(meta) == "table" and meta.isPurchasable ~= false then
            P.merchantWarmItemIDs[itemID] = true
            list[#list + 1] = { itemID = itemID, meta = meta }
        end
    end

    local function warmOne(entry)
        local itemID, meta = entry.itemID, entry.meta
        if IC.RequestLoad then
            IC.RequestLoad(itemID)
        end
        local link = P.MerchantItemLink(meta)
        local static = IC.GetStatic and IC.GetStatic(itemID)
        if static and static.classID == 0 then
            if link and IC.GetRestore then
                pcall(IC.GetRestore, itemID, link)
            end
            if link and IC.ClassifyConsumable then
                pcall(IC.ClassifyConsumable, itemID, link)
            end
        elseif link and IC.GetRestore then
            pcall(IC.GetRestore, itemID, link)
        end
    end

    local function finish()
        if P.IsMerchantFrameOpen() then
            P.After(0, function()
                if P.IsMerchantFrameOpen() then
                    Tiers.ScheduleVendorTierRefresh()
                end
            end)
        end
        if opts.onComplete then
            pcall(opts.onComplete)
        end
    end

    local WARM_CHUNK = 8
    local sync = opts.sync == true or #list <= WARM_CHUNK
    if sync then
        for i = 1, #list do
            warmOne(list[i])
        end
        finish()
        return
    end

    P.merchantWarmChunkGen = (P.merchantWarmChunkGen or 0) + 1
    local myGen = P.merchantWarmChunkGen
    local i = 1
    local function step()
        if myGen ~= P.merchantWarmChunkGen or not P.IsMerchantFrameOpen() then
            return
        end
        local limit = math.min(i + WARM_CHUNK - 1, #list)
        while i <= limit do
            warmOne(list[i])
            i = i + 1
        end
        if i <= #list then
            P.After(0, step)
            return
        end
        finish()
    end
    P.After(0, step)
end

function Tiers.ClearMerchantWarmSet()
    P.vendorTierRefresh.attempts = 0
    P.merchantWarmSnapshotGen = nil
    P.merchantWarmChunkGen = (P.merchantWarmChunkGen or 0) + 1
    wipe(P.merchantWarmItemIDs)
    P.merchantWarmIndex = nil
end

function Tiers.ClearVendorInferiorSnapshot()
    if P.vendorInferiorSnapshot then
        P.vendorInferiorSnapshot.bagGen = nil
        P.vendorInferiorSnapshot.merchantGen = nil
    end
end

function Tiers.NotifyTierReferenceUIRefresh()
    -- Structure / inferior-set change: invalidate caches and soft-refresh open UIs.
    if Tiers.InvalidateTierQueryCache then
        Tiers.InvalidateTierQueryCache()
    end
    if Tiers.InvalidateTooltipDisplayCache then
        Tiers.InvalidateTooltipDisplayCache()
    end
    if FluxVendorAuto and FluxVendorAuto.InvalidateRestockOptionsPanelCache then
        FluxVendorAuto.InvalidateRestockOptionsPanelCache()
    end
    if Tiers.NotifyTierCountsOnly then
        Tiers.NotifyTierCountsOnly()
    end
    local panel = _G.FluxVendorRestockPanel
    if panel and panel.RefreshCountsOnly then
        pcall(panel.RefreshCountsOnly)
    end
    if _G.FluxRestockPanel_RefreshMerchantAvailability then
        pcall(_G.FluxRestockPanel_RefreshMerchantAvailability)
    end
    local ui = _G.FluxVendorAutoMerchantUI
    local merchantOpen = P.IsMerchantFrameOpen and P.IsMerchantFrameOpen()
    if ui and merchantOpen then
        -- Restock need + Sell Junk enable in one light merchant data pass.
        if ui.MarkRestockSettingsDirty then
            pcall(ui.MarkRestockSettingsDirty)
        end
        if ui.MarkJunkStatsDirty then
            pcall(ui.MarkJunkStatsDirty)
        end
        if ui.ScheduleJunkUIRefresh then
            pcall(ui.ScheduleJunkUIRefresh, true)
        end
        if ui.ScheduleMerchantUpdateImmediate then
            pcall(ui.ScheduleMerchantUpdateImmediate, "data")
        elseif ui.ScheduleMerchantUpdate then
            pcall(ui.ScheduleMerchantUpdate, "data")
        end
    elseif ui and ui.MarkRestockSettingsDirty then
        pcall(ui.MarkRestockSettingsDirty)
    end
end

_G.FluxRestockTiers = Tiers
return Tiers
