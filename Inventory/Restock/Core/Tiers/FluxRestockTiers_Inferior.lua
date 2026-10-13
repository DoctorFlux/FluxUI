--[[
    Restock/Core/Tiers/FluxRestockTiers_Inferior.lua

    Mark items below reference restore as upgrade-inferior junk.
    Budgeted + scoped recomputes to avoid bag-pulse hitches.

    Critical: never publish a partial inferior set. Chunked evaluation
    accumulates decisions and only calls SetInferiorSet when the pass
    finishes — otherwise bag junk overlays flicker on/off every chunk.
]]

local Tiers = FluxRestockTiers
local P = Tiers._Private

local INFERIOR_CAP = 48
local CLASSIFY_RETRIES = 4

local pendingInferior = {}
local pendingInferiorSet = {}
local classifyRetries = {} -- [itemID] = n
local passAccum = {} -- [itemID] = true|false (decided this pass)
local passActive = false
local passMerchantIndex = nil
local passRefs = nil
local resumeToken = 0
local pendingAfterInferiorPass = false
local lastInferiorFingerprint = nil
local vendorSeenGen = 0
local lastVendorSeenWalkGen = -1

local function ConjureInferiorFilterOn()
    local s = P.Settings()
    local jf = s.junkFilters
    return not jf or jf.conjureInferiorFoodWater ~= false
end

local function SpellAPI()
    local Spells = P.Inv() and P.Inv().Spells
    if Spells then
        return Spells
    end
    return _G.FluxInv and _G.FluxInv.Spells
end

local function KindCanConjure(kind)
    if not P.FOOD_WATER_KINDS[kind] then
        return false
    end
    local Spells = SpellAPI()
    if not Spells then
        return false
    end
    local hasRefreshment = (Spells.HasConjureRefreshment and Spells.HasConjureRefreshment())
        or (Spells.HasCreateKind and Spells.HasCreateKind("refreshment"))
        or false
    if kind == "food" then
        return (Spells.HasConjureFood and Spells.HasConjureFood())
            or (Spells.HasCreateKind and Spells.HasCreateKind("food"))
            or hasRefreshment
            or false
    end
    return (Spells.HasConjureWater and Spells.HasConjureWater())
        or (Spells.HasCreateKind and Spells.HasCreateKind("water"))
        or hasRefreshment
        or false
end

local function BuildInferiorRefs(merchantIndex)
    local refs = { _canConjure = {} }
    for _, kind in ipairs(P.KINDS) do
        if Tiers.IsTierEligible(kind) and Tiers.IsMarkInferiorEnabled(kind) then
            refs[kind] = Tiers.GetInferiorReferenceTier(kind, merchantIndex)
            if P.FOOD_WATER_KINDS[kind] then
                refs._canConjure[kind] = KindCanConjure(kind)
            end
        end
    end
    return refs
end

local function IsConjuredFoodOrWaterItem(itemID, cls)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    if cls and P.FOOD_WATER_KINDS[cls.kind] and cls.isConjured then
        return true
    end
    local fj = P.FJ()
    if fj and fj.IsConjuredConsumable and fj.IsConjuredConsumable(itemID) then
        return true
    end
    if cls and P.FOOD_WATER_KINDS[cls.kind] then
        local ic = P.IC()
        local name = (ic and ic.GetName and ic.GetName(itemID)) or ""
        if type(name) == "string" and name:lower():find("conjured", 1, true) then
            return true
        end
    end
    return false
end

--- Returns true / false / nil (nil = classify not ready yet).
local function EvaluateInferiorItem(itemID, refs)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    -- Fully ignore items the character cannot use yet (level / skill).
    -- Do NOT gate on Score.IsUsable: unloaded / merchant-adjacent IDs return
    -- false there and would permanently skip marking on loot/buy.
    local Score = P.Best() and P.Best().Score
    if Score and Score.IsKnownUnusable and Score.IsKnownUnusable(itemID) then
        return false
    end
    local cls = P.ClassifyItem(itemID)
    if not cls then
        return nil
    end
    -- refs[kind] == 0 is a real "no upgrade bar" value; only skip kinds that
    -- were not included in this inferior pass (nil).
    if refs[cls.kind] == nil then
        return false
    end
    local kind = cls.kind
    local ref = tonumber(refs[kind]) or 0
    -- Never mark conjured food/water as upgrade-inferior junk.
    if IsConjuredFoodOrWaterItem(itemID, cls) then
        return false
    end
    -- Manual restock targets are never auto-junked as inferior.
    local fj = P.FJ()
    if fj and fj.IsManualRestockItem and fj.IsManualRestockItem(itemID) then
        return false
    end
    local v = P.RoundTier(P.TierAxisValue(kind, cls))
    if v > 0 and ref > 0 and v < ref then
        return true
    end
    if ConjureInferiorFilterOn() and P.FOOD_WATER_KINDS[kind] and not cls.isConjured then
        if Tiers.GetTarget(kind) == 0 then
            if refs._canConjure and refs._canConjure[kind] and v > 0 then
                return true
            end
        end
    end
    return false
end

local function FingerprintSet(set)
    local n, sum = 0, 0
    for id in pairs(set) do
        id = tonumber(id) or 0
        n = n + 1
        sum = sum + id
    end
    return n .. ":" .. sum
end

local function QueueInferior(itemID)
    itemID = tonumber(itemID)
    if not itemID or pendingInferiorSet[itemID] or passAccum[itemID] ~= nil then
        return
    end
    pendingInferiorSet[itemID] = true
    pendingInferior[#pendingInferior + 1] = itemID
end

local function CollectUniverse(merchantIndex, opts)
    wipe(pendingInferior)
    wipe(pendingInferiorSet)
    wipe(passAccum)
    wipe(classifyRetries)

    local inv = P.Inv()
    if inv and inv.Bags and inv.Bags.GetUniqueItems then
        for itemID in pairs(inv.Bags.GetUniqueItems()) do
            QueueInferior(itemID)
        end
    end
    -- Merchant-open path: bags (+ vendorSeen warm) only. Bank/warband stay for
    -- bank-open, login settle, and explicit full-universe recomputes.
    local bagsOnly = opts.bagsOnly
    if bagsOnly == nil then
        local invOpen = inv and inv.IsBankOpen and inv.IsBankOpen()
        if invOpen == nil and inv and inv.Bank and inv.Bank.IsOpen then
            invOpen = inv.Bank.IsOpen()
        end
        -- Default: skip bank maps when bank is closed.
        bagsOnly = not invOpen
    end
    if not bagsOnly and inv and inv.Bank then
        local char = inv.Bank.GetCharacterCounts and inv.Bank.GetCharacterCounts({ allowCached = true }) or {}
        for itemID in pairs(char) do
            QueueInferior(itemID)
        end
        if inv.Bank.GetWarbandCounts then
            for itemID in pairs(inv.Bank.GetWarbandCounts({ allowCached = true }) or {}) do
                QueueInferior(itemID)
            end
        end
    end

    local walkVendor = opts.vendor == true or opts.forceVendorSeen == true
        or vendorSeenGen ~= lastVendorSeenWalkGen
    if walkVendor then
        lastVendorSeenWalkGen = vendorSeenGen
        local Best = P.Best()
        if Best and Best.Persist and Best.Persist.GetAllVendorSeen then
            for itemID in pairs(Best.Persist.GetAllVendorSeen()) do
                QueueInferior(itemID)
            end
        end
    end
end

local function PublishInferiorSet(set, opts)
    local fj = P.FJ()
    if not fj or not fj.SetInferiorSet then
        return false
    end
    local fp = FingerprintSet(set)
    local changed = fp ~= lastInferiorFingerprint
    lastInferiorFingerprint = fp
    if not changed then
        return false
    end
    fj.SetInferiorSet(set, { silent = opts.silent == true })
    Tiers.InvalidateTierQueryCache()
    return true
end

local function ScheduleResume(opts)
    resumeToken = resumeToken + 1
    local token = resumeToken
    local merchantIndex = passMerchantIndex
    P.After(0.12, function()
        if token ~= resumeToken or not passActive then
            return
        end
        Tiers.RecomputeInferior(merchantIndex, {
            resume = true,
            skipRemember = true,
            silent = true,
        })
    end)
end

--- Hard-stop chunked inferior resume (merchant close / cancel background).
function Tiers.CancelInferiorPass()
    resumeToken = resumeToken + 1
    passActive = false
    passMerchantIndex = nil
    passRefs = nil
    wipe(passAccum)
    wipe(classifyRetries)
    wipe(pendingInferior)
    wipe(pendingInferiorSet)
end

local function FinishInferiorPass()
    passActive = false
    passRefs = nil
    wipe(passAccum)
    wipe(classifyRetries)
    wipe(pendingInferior)
    wipe(pendingInferiorSet)
    if pendingAfterInferiorPass then
        pendingAfterInferiorPass = false
        Tiers.RequestRecompute({ scope = "inferior", notify = true })
    end
end

function Tiers.RecomputeInferior(merchantIndex, opts)
    opts = opts or {}
    local fj = P.FJ()
    if not fj or not fj.SetInferiorSet then
        return false
    end
    Tiers.EnsureStores()

    local wantSync = opts.sync == true
    local isResume = opts.resume == true and passActive and not wantSync
    if not isResume then
        resumeToken = resumeToken + 1 -- cancel in-flight resumes
        passActive = true
        passMerchantIndex = merchantIndex
        if opts.skipRemember ~= true then
            Tiers.RememberOwnedTiers()
        end
        CollectUniverse(merchantIndex, opts)
        passRefs = BuildInferiorRefs(passMerchantIndex)
    elseif not passRefs then
        passRefs = BuildInferiorRefs(passMerchantIndex)
    end

    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.ResetParseBudget then
        Classify.ResetParseBudget(wantSync and math.max(INFERIOR_CAP, #pendingInferior + 8) or INFERIOR_CAP)
    end

    local refs = passRefs

    -- Vendor/open path: finish the whole universe in this call so sell/buy see marks.
    if wantSync then
        local set = {}
        for i = 1, #pendingInferior do
            local itemID = tonumber(pendingInferior[i])
            if itemID then
                local result = nil
                for _ = 1, CLASSIFY_RETRIES do
                    result = EvaluateInferiorItem(itemID, refs)
                    if result ~= nil then
                        break
                    end
                end
                if result == true or (result == nil and fj.IsUpgradeInferior(itemID)) then
                    set[itemID] = true
                end
            end
        end
        local changed = PublishInferiorSet(set, opts)
        FinishInferiorPass()
        return changed
    end

    local budget = INFERIOR_CAP

    -- Drain current queue into decisions (budgeted).
    local q = pendingInferior
    pendingInferior = {}
    pendingInferiorSet = {}
    for i = 1, #q do
        local itemID = tonumber(q[i])
        if itemID and passAccum[itemID] == nil then
            if budget <= 0 then
                QueueInferior(itemID)
            else
                budget = budget - 1
                local result = EvaluateInferiorItem(itemID, refs)
                if result == nil then
                    local n = (classifyRetries[itemID] or 0) + 1
                    classifyRetries[itemID] = n
                    if n < CLASSIFY_RETRIES then
                        QueueInferior(itemID)
                    else
                        -- Give up this pass: sticky keep previous mark to avoid flicker.
                        passAccum[itemID] = fj.IsUpgradeInferior(itemID) == true
                    end
                else
                    passAccum[itemID] = result == true
                    classifyRetries[itemID] = nil
                end
            end
        end
    end

    -- More work remains: resume later; do NOT publish a partial set.
    if #pendingInferior > 0 then
        ScheduleResume(opts)
        return false
    end

    -- Pass complete — publish once.
    local set = {}
    for itemID, isInf in pairs(passAccum) do
        if isInf then
            set[itemID] = true
        end
    end
    local changed = PublishInferiorSet(set, opts)
    FinishInferiorPass()
    return changed
end

function Tiers.BumpVendorSeenGeneration()
    vendorSeenGen = vendorSeenGen + 1
end

--- True when no chunked inferior recompute is in flight.
function Tiers.IsInferiorPassComplete()
    return not passActive
end

function Tiers.EnsureInferiorMarksForVendor(merchantIndex, opts)
    opts = opts or {}
    local bagGen = P.GetBagCacheGen()
    local merchantGen = P.GetMerchantCacheGen()
    if opts.force ~= true
        and P.vendorInferiorSnapshot.bagGen == bagGen
        and P.vendorInferiorSnapshot.merchantGen == merchantGen then
        return false
    end
    Tiers.BumpVendorSeenGeneration()
    -- Sync only when auto-sell of upgrade-inferior is about to run; otherwise
    -- prefer chunked INFERIOR_CAP resume to avoid merchant-open hitches.
    local wantSync = opts.sync
    if wantSync == nil then
        wantSync = Tiers.HasPendingVendorUpgradeRestock and Tiers.HasPendingVendorUpgradeRestock() or false
    end
    local bagsOnly = opts.bagsOnly
    if bagsOnly == nil then
        bagsOnly = true
    end
    local changed = Tiers.RecomputeInferior(merchantIndex, {
        force = true,
        vendor = true,
        sync = wantSync == true,
        bagsOnly = bagsOnly == true,
    })
    P.vendorInferiorSnapshot.bagGen = bagGen
    P.vendorInferiorSnapshot.merchantGen = merchantGen
    Tiers.InvalidateTierQueryCache()
    Tiers.InvalidateTooltipDisplayCache()
    if Tiers.FlushTierCountRefresh then
        Tiers.FlushTierCountRefresh()
    end
    return changed
end

function Tiers.RunVendorTierAndInferiorPass(merchantIndex)
    if not P.IsMerchantFrameOpen or not P.IsMerchantFrameOpen() then
        return false, nil
    end
    merchantIndex = P.ResolveMerchantIndex and P.ResolveMerchantIndex(merchantIndex) or merchantIndex
    if not merchantIndex then
        return false, nil
    end
    local upgrade = Tiers.ApplyVendorTierUpgrades(merchantIndex)
    if upgrade and upgrade.deferred then
        return false, upgrade
    end
    if upgrade and upgrade.any then
        Tiers.InvalidateTierQueryCache()
        Tiers.InvalidateTooltipDisplayCache()
    end
    -- Bags + vendorSeen warm; sync only when pending upgrade sell needs marks now.
    local changed = Tiers.EnsureInferiorMarksForVendor(merchantIndex) or false
    if (upgrade and upgrade.any) or changed then
        if Tiers.NotifyTierReferenceUIRefresh then
            Tiers.NotifyTierReferenceUIRefresh()
        end
    end
    if not Tiers.IsInferiorPassComplete() then
        upgrade = upgrade or { any = false, kinds = {} }
        upgrade.deferred = true
    end
    return changed or (upgrade and upgrade.any), upgrade
end

--- Instant mark for newly acquired itemIDs (loot / buy / craft).
--- Returns true if any mark changed; false if nothing to do; nil if classify pending.
function Tiers.TryMarkAddedItems(addedItemIDs, merchantIndex)
    if type(addedItemIDs) ~= "table" or not next(addedItemIDs) then
        return false
    end
    local fj = P.FJ()
    if not fj or not fj.MarkUpgradeInferior then
        return false
    end
    Tiers.EnsureStores()
    Tiers.RememberOwnedTiers()
    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.ResetParseBudget then
        local n = 0
        for _ in pairs(addedItemIDs) do
            n = n + 1
        end
        Classify.ResetParseBudget(math.max(16, n + 4))
    end
    if merchantIndex == nil and P.IsMerchantFrameOpen and P.IsMerchantFrameOpen() then
        merchantIndex = true
    end
    local refs = BuildInferiorRefs(merchantIndex)
    local hasKind = false
    for k, v in pairs(refs) do
        if k ~= "_canConjure" and v then
            hasKind = true
            break
        end
    end
    if not hasKind then
        return false
    end
    local changed = false
    local pending = false
    local inv = P.Inv()
    for itemID in pairs(addedItemIDs) do
        itemID = tonumber(itemID)
        if itemID then
            local count = 0
            if inv and inv.Bags and inv.Bags.GetCount then
                count = inv.Bags.GetCount(itemID) or 0
            end
            if count > 0 and not (fj.IsUpgradeInferior and fj.IsUpgradeInferior(itemID)) then
                local result = EvaluateInferiorItem(itemID, refs)
                if result == nil then
                    pending = true
                elseif result == true and fj.MarkUpgradeInferior(itemID) then
                    changed = true
                end
            end
        end
    end
    if changed then
        Tiers.InvalidateTierQueryCache()
        -- Prefer lightweight merchant notify over FireListChanged (options rebuild).
        local Buy = _G.FluxVendorBuy or _G.FluxVendorAuto
        if Buy and Buy.FlushVendorTierUI and P.IsMerchantFrameOpen and P.IsMerchantFrameOpen() then
            pcall(Buy.FlushVendorTierUI)
        else
            if Tiers.NotifyTierReferenceUIRefresh then
                Tiers.NotifyTierReferenceUIRefresh()
            end
            local overlay = _G.FluxJunkOverlay
            if overlay and overlay.ScheduleInferiorRepaintBurst then
                pcall(overlay.ScheduleInferiorRepaintBurst)
            elseif overlay and overlay.RepaintInferiorVisuals then
                pcall(overlay.RepaintInferiorVisuals)
            end
        end
    end
    if pending then
        return nil
    end
    return changed
end

--- Unmark itemIDs that fully left bags+bank.
function Tiers.TryUnmarkRemovedItems(removedItemIDs)
    if type(removedItemIDs) ~= "table" or not next(removedItemIDs) then
        return false
    end
    local fj = P.FJ()
    if not fj or not fj.UnmarkUpgradeInferior then
        return false
    end
    local inv = P.Inv()
    local changed = false
    for itemID in pairs(removedItemIDs) do
        itemID = tonumber(itemID)
        if itemID and fj.IsUpgradeInferior and fj.IsUpgradeInferior(itemID) then
            local stillOwned = false
            if inv and inv.Bags and inv.Bags.GetCount then
                stillOwned = (inv.Bags.GetCount(itemID) or 0) > 0
            end
            if not stillOwned and inv and inv.Bank and inv.Bank.GetCount then
                stillOwned = (inv.Bank.GetCount(itemID) or 0) > 0
            end
            if not stillOwned and inv and inv.GetItemCount then
                stillOwned = (inv.GetItemCount(itemID, { includeBank = true }) or 0) > 0
            end
            if not stillOwned then
                fj.UnmarkUpgradeInferior(itemID)
                changed = true
            end
        end
    end
    return changed
end

function Tiers.ItemIsUpgradeInferiorForKinds(itemID, kindFilter, merchantIndex)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local refs = BuildInferiorRefs(merchantIndex)
    if kindFilter then
        local filtered = {}
        if type(kindFilter) == "table" then
            for k, v in pairs(kindFilter) do
                -- Accept: { food = true }, { food = { value, itemID } }, { [1] = "food" }
                if type(k) == "string" and refs[k] and v then
                    filtered[k] = refs[k]
                elseif type(k) == "number" and type(v) == "string" and refs[v] then
                    filtered[v] = refs[v]
                end
            end
        elseif refs[kindFilter] then
            filtered[kindFilter] = refs[kindFilter]
        end
        filtered._canConjure = refs._canConjure
        refs = filtered
    end
    local result = EvaluateInferiorItem(itemID, refs)
    return result == true
end

function Tiers.HasUpgradeInferiorForKinds(kindFilter, merchantIndex)
    local inv = P.Inv()
    if not inv or not inv.Bags or not inv.Bags.GetUniqueItems then
        return false
    end
    -- Live evaluate (not only inferiorSet) so Restock can sell before marks publish.
    for itemID in pairs(inv.Bags.GetUniqueItems()) do
        itemID = tonumber(itemID)
        if itemID and Tiers.ItemIsUpgradeInferiorForKinds(itemID, kindFilter, merchantIndex) then
            return true
        end
    end
    return false
end

--- True when bags still hold items inferior for pending upgrade kinds (live eval).
function Tiers.BagsHaveInferiorForPendingKinds(kindFilter, merchantIndex)
    if not kindFilter or not next(kindFilter) then
        return false
    end
    local inv = P.Inv()
    if not inv or not inv.Bags or not inv.Bags.GetUniqueItems then
        return false
    end
    local unique = inv.Bags.GetUniqueItems()
    for kind, info in pairs(kindFilter) do
        if type(kind) == "string" and P.KIND_FIELDS[kind] and info then
            local ref = 0
            if type(info) == "table" then
                ref = P.RoundTier(info.value or 0)
            end
            if ref <= 0 then
                ref = P.RoundTier(Tiers.GetInferiorReferenceTier(kind, merchantIndex))
            end
            if ref > 0 then
                for itemID, rec in pairs(unique) do
                    itemID = tonumber(itemID)
                    local n = rec and tonumber(rec.count) or 0
                    if itemID and n > 0 and not IsConjuredFoodOrWaterItem(itemID) then
                        local v = Tiers.GetItemTierValue(kind, itemID)
                        if v > 0 and v < ref then
                            return true
                        end
                    end
                end
            end
        end
    end
    return Tiers.HasUpgradeInferiorForKinds(kindFilter, merchantIndex)
end

--- Publish live-eval inferior matches into FluxJunk so inferiorOnly sell can iterate them.
--- Uses pending kind values when provided so we do not depend on Best/vendor GetOwnedTier.
function Tiers.ForcePublishInferiorForKinds(kindFilter, merchantIndex)
    if not kindFilter or not next(kindFilter) then
        return false
    end
    local fj = P.FJ()
    local inv = P.Inv()
    if not fj or not fj.MarkUpgradeInferior or not inv or not inv.Bags or not inv.Bags.GetUniqueItems then
        return false
    end
    local changed = false
    local unique = inv.Bags.GetUniqueItems()
    for kind, info in pairs(kindFilter) do
        if type(kind) == "string" and P.KIND_FIELDS[kind] and info then
            local ref = 0
            if type(info) == "table" then
                ref = P.RoundTier(info.value or 0)
            end
            if ref <= 0 then
                ref = P.RoundTier(Tiers.GetInferiorReferenceTier(kind, merchantIndex))
            end
            if ref > 0 then
                for itemID, rec in pairs(unique) do
                    itemID = tonumber(itemID)
                    local n = rec and tonumber(rec.count) or 0
                    if itemID and n > 0 and not IsConjuredFoodOrWaterItem(itemID) then
                        local v = Tiers.GetItemTierValue(kind, itemID)
                        if v > 0 and v < ref then
                            if fj.MarkUpgradeInferior(itemID) then
                                changed = true
                            end
                        elseif Tiers.ItemIsUpgradeInferiorForKinds(itemID, { [kind] = info }, merchantIndex) then
                            if fj.MarkUpgradeInferior(itemID) then
                                changed = true
                            end
                        end
                    end
                end
            end
        end
    end
    if changed and fj.InvalidateJunkWorklist then
        pcall(fj.InvalidateJunkWorklist)
    end
    return changed
end

local pendingScope = nil -- "countsOnly" | "structure" | "inferior"
local pendingNotify = false
local pendingBagsOnly = false

function Tiers.RequestRecompute(opts)
    opts = opts or {}
    if passActive and not opts.force then
        pendingAfterInferiorPass = true
        if opts.notify == true then
            pendingNotify = true
        end
        return
    end
    local scope = opts.scope or "inferior"
    -- Escalate pending scope: countsOnly < structure < inferior
    local rank = { countsOnly = 1, structure = 2, inferior = 3 }
    if pendingScope then
        if (rank[scope] or 3) > (rank[pendingScope] or 1) then
            pendingScope = scope
        end
        if opts.notify == true then
            pendingNotify = true
        end
        if opts.bagsOnly == true then
            pendingBagsOnly = true
        end
        if not opts.force then
            return
        end
    else
        pendingScope = scope
        pendingNotify = opts.notify == true or scope == "structure"
        pendingBagsOnly = opts.bagsOnly == true
    end

    if P.recomputePending and not opts.force then
        return
    end
    P.recomputePending = true
    local delay = opts.force and 0.05 or 0.3
    P.After(delay, function()
        P.recomputePending = false
        local inv = P.Inv()
        if inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() and not opts.force then
            local saved = pendingScope
            local savedBagsOnly = pendingBagsOnly
            pendingScope = nil
            pendingBagsOnly = false
            Tiers.RequestRecompute({
                force = true,
                scope = saved or "countsOnly",
                bagsOnly = savedBagsOnly,
            })
            return
        end
        local doScope = pendingScope or scope
        local doNotify = pendingNotify
        local doBagsOnly = pendingBagsOnly or opts.bagsOnly == true
        -- When bank is closed, never walk cached bank/warband for inferior.
        if inv and inv.IsBankOpen and not inv.IsBankOpen() then
            doBagsOnly = true
        elseif inv and inv.Bank and inv.Bank.IsOpen and not inv.Bank.IsOpen() then
            doBagsOnly = true
        end
        if passActive and doScope == "inferior" then
            pendingAfterInferiorPass = true
            pendingScope = nil
            pendingNotify = false
            pendingBagsOnly = false
            return
        end
        pendingScope = nil
        pendingNotify = false
        pendingBagsOnly = false

        if doScope == "countsOnly" then
            Tiers.InvalidateTierQueryCache()
            if Tiers.NotifyTierCountsOnly then
                Tiers.NotifyTierCountsOnly()
            end
            return
        end

        Tiers.RememberOwnedTiers()
        local changed = Tiers.RecomputeInferior(nil, {
            silent = doScope ~= "structure",
            bagsOnly = doBagsOnly,
        })
        if doNotify or (changed and doScope ~= "countsOnly") then
            if changed or doScope == "structure" then
                Tiers.NotifyTierReferenceUIRefresh()
            elseif Tiers.NotifyTierCountsOnly then
                Tiers.NotifyTierCountsOnly()
            end
        end
    end)
end

function Tiers.TryRunDeferredLoginSettle()
    Tiers.RequestRecompute({ force = true, scope = "inferior", notify = true })
end

function Tiers.RunPulseEndLoginSettle(onDone)
    Tiers.RecomputeInferior(nil, { sync = true, forceVendorSeen = true })
    if type(onDone) == "function" then
        onDone()
    end
end

_G.FluxRestockTiers = Tiers
return Tiers
