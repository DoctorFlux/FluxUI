--[[
    Inventory/FluxConsumableBest/Scan.lua

    Debounced scan of FluxInv unique items + bank/warband counts.
    Caps classification work per pulse; resumes on item data load.
]]

local _, ns = ...

FluxConsumableBest = FluxConsumableBest or {}
local Best = FluxConsumableBest
Best.Scan = Best.Scan or {}
local Scan = Best.Scan

-- The bag walk consumes keys only. Index.lua establishes this private owner
-- pair; its helper retains public GetUniqueItems overrides and fresh results.
local snapshotItemIDQuery = type(ns) == "table" and rawget(ns, "InventoryUniqueItemIDQuery")
local snapshotItemIDOwner, snapshotItemIDs
if type(snapshotItemIDQuery) == "table" then
    snapshotItemIDOwner = rawget(snapshotItemIDQuery, "owner")
    snapshotItemIDs = rawget(snapshotItemIDQuery, "query")
end

local carriedSnapshot = type(ns) == "table" and rawget(ns, "InventoryCarriedSnapshotQuery")
local carriedOwner, carriedFacade, carriedCount
if type(carriedSnapshot) == "table" then
    local query = rawget(carriedSnapshot, "query")
    if type(query) == "function" then
        carriedOwner = rawget(carriedSnapshot, "owner")
        carriedFacade = rawget(carriedSnapshot, "facade")
        carriedCount = query
    end
end

local rejectedCache = type(ns) == "table" and rawget(ns, "ConsumableRejectedCacheQuery")
local rejectedOwner, rejectedClassify, rejectedPending, queryRejectedCache
if type(rejectedCache) == "table" then
    rejectedOwner = rawget(rejectedCache, "owner")
    rejectedClassify = rawget(rejectedCache, "classify")
    rejectedPending = rawget(rejectedCache, "pending")
    queryRejectedCache = rawget(rejectedCache, "query")
end

local function IsCachedRejection(classify, itemID)
    return type(classify) == "table" and classify == rejectedOwner
        and getmetatable(classify) == nil and type(queryRejectedCache) == "function"
        and rawget(classify, "Classify") == rejectedClassify
        and rawget(classify, "IsPending") == rejectedPending
        and queryRejectedCache(itemID)
end

local CLASSIFY_CAP = 24
local LOAD_CAP = 8
local PENDING_CAP = 40
local MAX_CLASSIFY_FOLLOWUPS = 3
-- Stop re-queuing a single stuck ID; do NOT permanently reject (cold-load tooltips).
local MAX_ITEM_PENDING_ATTEMPTS = 8
-- Private lookup order only; classification membership and owned counts stay live.
local MANA_GEM_ORDER = { 36799, 33312, 22044, 8008, 8007, 5513, 5514 }
local pendingQueue = {}
local pendingSet = {}
local pendingAttempts = {} -- [itemID] = attempts while still pending/classify-deferred
local loadsThisPulse = 0
local lastBankScanGen = -1
local classifyFollowups = 0
local stableScan
local scanSerial = 0
local recordingCounts, recordingKinds, recordingBlocked, recordingRefs
local resolvedThisPulse = 0

-- Follow-up drain pulses may skip the full unique walk. Real bag/bank/login
-- pulses must always walk so counts and new items update CombatGrid.
local PENDING_ONLY_REASONS = {
    classifyPendingRead = true,
    classifyPendingOnly = true,
    classifyPending = true,
    classifyResume = true,
    itemData = true,
    orphanLoad = true,
}
Scan.PENDING_ONLY_REASONS = PENDING_ONLY_REASONS

local function InvAPI()
    local Flux = _G.Flux
    return Flux and Flux.Inventory
end

local function Inv()
    return InvAPI() or _G.FluxInv
end

-- Only the defining inventory/classification owners may reuse a completed walk.
-- Public replacements keep the full query path, including their side effects.
local ownedInv = InvAPI()
local ownedIndex = ownedInv and ownedInv.Index
local ownedClassify = _G.FluxConsumableClassify
local ownedScore = Best.Score
local ownedGetCount = ownedInv and ownedInv.GetCount
local ownedGetUnique = ownedInv and ownedInv.GetUniqueItems
local ownedGetGeneration = ownedInv and ownedInv.GetBagGeneration
local ownedReady = ownedInv and ownedInv.IsReady
local ownedIndexCount = ownedIndex and ownedIndex.GetCount
local ownedIndexUnique = ownedIndex and ownedIndex.GetUniqueItems
local ownedIndexGeneration = ownedIndex and ownedIndex.GetSnapshotGeneration
local ownedClassifyItem = ownedClassify and ownedClassify.Classify
local ownedInvalidate = ownedClassify and ownedClassify.InvalidateCache
local ownedRevision = ownedClassify and ownedClassify.GetInvalidationRevision
local ownedPools = ownedScore and ownedScore.GetPools
local ownedBlocked = ownedScore and ownedScore.IsBlockedForBest
local ownedBetter = ownedScore and ownedScore.IsBetter
local ownedUsable = ownedScore and ownedScore.IsUsable
local ownedEffective = ownedScore and ownedScore.EffectiveFromClassify
local ownedMaxStack = ownedScore and ownedScore.GetMaxStack
local ownedRank = ownedScore and ownedScore.HealthstoneRank
local ownedFoodTier = ownedScore and ownedScore.FoodTier
local ownedWaterTier = ownedScore and ownedScore.WaterDrinkTier
local ownedManaRelevant = Best.IsManaKindRelevant
local ownedPersist = Best.Persist
local ownedUpdateRef = ownedPersist and ownedPersist.MaybeUpdateRef
local validatedPersist = type(ns) == "table" and rawget(ns, "InventoryValidatedPersistQuery")
local updateValidatedRef
if type(validatedPersist) == "table" and rawget(validatedPersist, "owner") == ownedPersist
    and rawget(validatedPersist, "publicQuery") == ownedUpdateRef then
    updateValidatedRef = rawget(validatedPersist, "query")
end
local ownedVendor = Best.VendorMemory
local ownedVendorCandidates = ownedVendor and ownedVendor.GetVendorCandidates

local function SameOwners(api, classify, score)
    return api == ownedInv and api and api.Index == ownedIndex and ownedIndex
        and type(ownedGetCount) == "function" and api.GetCount == ownedGetCount
        and type(ownedGetUnique) == "function" and api.GetUniqueItems == ownedGetUnique
        and type(ownedGetGeneration) == "function" and api.GetBagGeneration == ownedGetGeneration
        and type(ownedReady) == "function" and api.IsReady == ownedReady
        and ownedIndex.GetCount == ownedIndexCount and ownedIndex.GetUniqueItems == ownedIndexUnique
        and ownedIndex.GetSnapshotGeneration == ownedIndexGeneration
        and classify == ownedClassify and classify and classify.Classify == ownedClassifyItem
        and classify.InvalidateCache == ownedInvalidate and type(ownedRevision) == "function"
        and classify.GetInvalidationRevision == ownedRevision
        and score == ownedScore and score and score.GetPools == ownedPools
        and score.IsBlockedForBest == ownedBlocked and score.IsBetter == ownedBetter
        and score.IsUsable == ownedUsable
        and score.EffectiveFromClassify == ownedEffective and score.GetMaxStack == ownedMaxStack
        and score.HealthstoneRank == ownedRank and score.FoodTier == ownedFoodTier
        and score.WaterDrinkTier == ownedWaterTier and Best.IsManaKindRelevant == ownedManaRelevant
        and Best.Persist == ownedPersist and ownedPersist and ownedPersist.MaybeUpdateRef == ownedUpdateRef
        and Best.VendorMemory == ownedVendor and ownedVendor and ownedVendor.GetVendorCandidates == ownedVendorCandidates
end

-- Pass this publication's traversal state explicitly; nested scans must never
-- share its seen set or the fresh value snapshots retained for reuse checks.
local function VisitPublishedState(t, depth, states, seen)
    if type(t) ~= "table" or getmetatable(t) ~= nil or depth > 3 then return false end
    if seen[t] then return true end
    seen[t] = true
    if #states >= 128 then return false end
    local values, count = {}, 0
    local row = { owner = t, values = values }
    states[#states + 1] = row
    for k, v in pairs(t) do
        if issecretvalue and (issecretvalue(k) or issecretvalue(v)) then return false end
        local valueType = type(v)
        if valueType ~= "table" and valueType ~= "number" and valueType ~= "string" and valueType ~= "boolean" then return false end
        values[k] = v
        count = count + 1
        if type(v) == "table" and not VisitPublishedState(v, depth + 1, states, seen) then return false end
    end
    row.size = count
    return true
end

local function PublishedState(runtime, ladders, combo)
    local states, seen = {}, {}
    if not VisitPublishedState(runtime, 1, states, seen)
        or not VisitPublishedState(ladders, 1, states, seen)
        or not VisitPublishedState(combo, 1, states, seen) then return nil end
    return states
end

local function PublishedUnchangedFull(states)
    if not states then return false end
    for i = 1, #states do
        local row = states[i]
        if getmetatable(row.owner) ~= nil then return false end
        for k, v in pairs(row.owner) do
            if issecretvalue and (issecretvalue(k) or issecretvalue(v)) then return false end
            if type(v) == "table" and getmetatable(v) ~= nil then return false end
            if row.values[k] ~= v then return false end
        end
        for k, v in pairs(row.values) do
            local current = rawget(row.owner, k)
            if issecretvalue and issecretvalue(current) then return false end
            if current ~= v then return false end
        end
    end
    return true
end

local canonicalSecretValueCheck = issecretvalue

local function PublishedUnchanged(states)
    if issecretvalue ~= canonicalSecretValueCheck then return PublishedUnchangedFull(states) end
    if not states then return false end
    for i = 1, #states do
        local row = states[i]
        if getmetatable(row.owner) ~= nil then return false end
        local count = 0
        for k, v in pairs(row.owner) do
            if issecretvalue and (issecretvalue(k) or issecretvalue(v)) then return false end
            if type(v) == "table" and getmetatable(v) ~= nil then return false end
            if row.values[k] ~= v then return false end
            count = count + 1
        end
        -- Matching values exclude new/changed keys; cardinality also detects
        -- removals, without walking every saved key a second time.
        if count ~= row.size then return false end
    end
    return true
end

local function RememberCount(itemID, count)
    if recordingCounts then recordingCounts[itemID] = count end
    return count
end

local function RegionsWantBank(regions)
    if type(regions) ~= "table" then
        return true
    end
    -- Mail/currency/guild pulses must not walk bank.
    if not regions.bags and not regions.bank and not regions.warband then
        return false
    end
    -- Explicit bags-only pulse: skip bank walk when bank gen unchanged.
    if regions.bags and not regions.bank and not regions.warband then
        return false
    end
    if regions.bank or regions.warband then
        return true
    end
    -- No region hint → include bank.
    return true
end

local function BankIsOpen()
    local api = InvAPI()
    if api and api.IsBankOpen then
        return api.IsBankOpen()
    end
    local inv = Inv()
    if inv and inv.IsBankOpen then
        return inv.IsBankOpen()
    end
    if inv and inv.Bank and inv.Bank.IsOpen then
        return inv.Bank.IsOpen()
    end
    return false
end

local function KnownNonConsumable(itemID)
    local IC = _G.FluxItemClass
    local static = IC and IC.GetStatic and IC.GetStatic(itemID)
    return static and static.classID ~= nil and static.classID ~= 0
end

local function QueuePending(itemID, allowLoad)
    itemID = tonumber(itemID)
    if not itemID or pendingSet[itemID] or KnownNonConsumable(itemID) then
        return
    end
    if #pendingQueue >= PENDING_CAP then
        return
    end
    pendingSet[itemID] = true
    pendingQueue[#pendingQueue + 1] = itemID

    local IC = _G.FluxItemClass
    local loaded = not IC or not IC.IsLoaded or IC.IsLoaded(itemID)
    if loaded then
        -- Classify-budget backlog only — never treat as item-data wait.
        Best._pendingLoad[itemID] = nil
        return
    end

    Best._pendingLoad[itemID] = true
    if allowLoad == false or loadsThisPulse >= LOAD_CAP then
        return
    end
    loadsThisPulse = loadsThisPulse + 1
    if IC and IC.RequestLoad then
        IC.RequestLoad(itemID)
    elseif C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
end

local function ClearPendingLoad(itemID)
    itemID = tonumber(itemID)
    if itemID then
        Best._pendingLoad[itemID] = nil
    end
end

local function CountOwned(itemID)
    local api = InvAPI()
    if api and api.GetCount then
        local getCount = api.GetCount
        if api == carriedOwner and getCount == carriedFacade and carriedCount then
            local count = carriedCount(itemID)
            if count ~= nil then return RememberCount(itemID, count) end
        end
        return RememberCount(itemID, getCount(itemID, {
            bags = true,
            bank = false,
            warband = false,
            equipped = false,
        }) or 0)
    end
    local inv = Inv()
    if not inv then
        return 0
    end
    if inv.GetCount then
        return RememberCount(itemID, inv.GetCount(itemID, { bags = true, bank = false, warband = false }) or 0)
    end
    if inv.Bags and inv.Bags.GetCount then
        return RememberCount(itemID, inv.Bags.GetCount(itemID) or 0)
    end
    return 0
end

local function BuildCandidate(itemID, cls, maxHP, maxMana, source)
    local Score = Best.Score
    local effective = Score.EffectiveFromClassify(cls, maxHP, maxMana)
    local hsRank = tonumber(cls.hsRank)
    if cls.kind == "healthstone" and Score.HealthstoneRank then
        hsRank = Score.HealthstoneRank(itemID)
        if (not effective or effective <= 0) and hsRank > 0 then
            effective = hsRank * 100
        elseif (not effective or effective <= 0) and (tonumber(cls.effective) or 0) > 0 then
            effective = tonumber(cls.effective) or 0
        end
    end
    if effective <= 0 then
        return nil
    end
    -- Unloaded item data must still compete (login / conjure). Drop only
    -- known-unusable (level / skill) — never situational IsUsableItem
    -- (false for food/water in combat).
    local blocked
    if Score.IsBlockedForBest then
        blocked = Score.IsBlockedForBest(itemID, cls.kind)
    elseif Score.IsKnownUnusable then
        blocked = Score.IsKnownUnusable(itemID, cls.kind)
    end
    if recordingKinds then
        recordingKinds[itemID] = cls.kind
        recordingBlocked[itemID] = blocked and true or false
    end
    if blocked then return nil end
    local count = CountOwned(itemID)
    if count <= 0 then
        return nil
    end
    local maxStack = (Score.GetMaxStack and Score.GetMaxStack(itemID)) or 0
    local health = tonumber(cls.health) or 0
    local mana = tonumber(cls.mana) or 0
    local isCombo = cls.isCombo
    if isCombo == nil then
        isCombo = (health > 0 and mana > 0) or nil
    end
    return {
        itemID = itemID,
        kind = cls.kind,
        effective = effective,
        health = health,
        mana = mana,
        isCombo = isCombo and true or nil,
        hsRank = (hsRank and hsRank > 0) and hsRank or nil,
        isPercent = cls.isPercent and true or false,
        restoreRaw = cls.restoreRaw or cls.effective or effective,
        restorePct = tonumber(cls.restorePct) or tonumber(cls.restoreHealthPct) or tonumber(cls.restoreManaPct) or nil,
        restoreHealthPct = tonumber(cls.restoreHealthPct),
        restoreManaPct = tonumber(cls.restoreManaPct),
        isConjured = cls.isConjured and true or false,
        count = count,
        maxStack = maxStack,
        source = source or "owned",
        locations = nil, -- filled lazily by FindStacks consumers
    }
end

local function CopyCand(src)
    local out = {}
    for k, v in pairs(src) do
        out[k] = v
    end
    return out
end

local function AppendLadder(kind, cand)
    if not kind or not cand then
        return
    end
    Best._scanLists = Best._scanLists or {}
    local list = Best._scanLists[kind]
    if not list then
        list = {}
        Best._scanLists[kind] = list
    end
    list[#list + 1] = cand
end

local function SortLadder(list, kind, allowComboDrinks)
    if type(list) ~= "table" or #list < 2 then
        return list or {}
    end
    local Score = Best.Score
    local opts = true
    if kind == "water" and allowComboDrinks then
        opts = { preferConjured = true, allowComboDrinks = true }
    end
    table.sort(list, function(a, b)
        if Score and Score.IsBetter then
            return Score.IsBetter(a, b, opts)
        end
        return (a.effective or 0) > (b.effective or 0)
    end)
    return list
end

local function ConsiderItem(itemID, bestByKind, maxHP, maxMana, classifyBudget, resolvedItems)
    local Classify = _G.FluxConsumableClassify
    local IC = _G.FluxItemClass
    if not Classify or not Classify.Classify then
        return classifyBudget
    end
    itemID = tonumber(itemID)
    if not itemID then
        return classifyBudget
    end
    -- Pending, added, conjure-priority and bank walks can revisit the same ID.
    -- A ready owned candidate is already complete for this synchronous pass.
    if resolvedItems and resolvedItems[itemID] then
        return classifyBudget
    end
    -- Match Classify's static class rejection before spending a load/classify
    -- slot. Gear and crafting materials must not fill the pending queue.
    if KnownNonConsumable(itemID) then
        ClearPendingLoad(itemID)
        return classifyBudget
    end
    if IC and IC.IsLoaded and not IC.IsLoaded(itemID) then
        local attempts = (pendingAttempts[itemID] or 0) + 1
        pendingAttempts[itemID] = attempts
        if attempts > MAX_ITEM_PENDING_ATTEMPTS then
            -- Give up re-queue this cycle; next bag/inv pulse may retry (do not ForceReject).
            return classifyBudget
        end
        QueuePending(itemID, true)
        return classifyBudget
    end
    -- Loaded (or no loader): drop item-data wait even if classify is deferred.
    ClearPendingLoad(itemID)
    if classifyBudget <= 0 then
        -- Cap pending refill so one megawalk cannot re-fill PENDING_CAP forever.
        if #pendingQueue < CLASSIFY_CAP then
            QueuePending(itemID, false)
        end
        return classifyBudget
    end
    -- Keep the ordinary call (and its hooks), but do not spend candidate/parse
    -- budget on a defining classifier's already-settled negative cache hit.
    -- Missing contracts or public replacements retain the original budgeting.
    if not IsCachedRejection(Classify, itemID) then
        classifyBudget = classifyBudget - 1
    end
    local cls = Classify.Classify(itemID)
    if not cls or not Best.IsValidKind(cls.kind) then
        -- Partial tooltip / pending classify: keep retrying (mage-table loot).
        if Classify.IsPending and Classify.IsPending(itemID) then
            local attempts = (pendingAttempts[itemID] or 0) + 1
            pendingAttempts[itemID] = attempts
            if attempts > MAX_ITEM_PENDING_ATTEMPTS then
                -- Stop queue churn; leave classify cache alone so a later pulse can succeed.
                pendingAttempts[itemID] = nil
                return classifyBudget
            end
            QueuePending(itemID, false)
        else
            pendingAttempts[itemID] = nil
        end
        return classifyBudget
    end
    pendingAttempts[itemID] = nil
    if not Best.IsManaKindRelevant(cls.kind) then
        return classifyBudget
    end
    local cand = BuildCandidate(itemID, cls, maxHP, maxMana, "owned")
    if not cand then
        return classifyBudget
    end
    resolvedThisPulse = resolvedThisPulse + 1
    local Score = Best.Score
    local cur = bestByKind[cls.kind]
    if Score.IsBetter(cand, cur, true) then
        bestByKind[cls.kind] = cand
    end
    AppendLadder(cls.kind, cand)
    -- Combo (HP+mana, including % combo): score the mana axis for water as well.
    if cand.isCombo then
        local manaEff = tonumber(cand.mana) or 0
        if cand.isPercent and (tonumber(cls.restoreManaPct) or 0) > 0 and maxMana > 0 then
            manaEff = (tonumber(cls.restoreManaPct) / 100) * maxMana
        end
        if manaEff <= 0 then
            manaEff = tonumber(cand.mana) or 0
        end
        if manaEff > 0 then
            local waterCand = CopyCand(cand)
            waterCand.kind = "food"
            waterCand.effective = manaEff
            waterCand.source = "owned"
            AppendLadder("waterCombo", waterCand)
            local curWater = bestByKind.waterCombo
            if Score.IsBetter(waterCand, curWater, { preferConjured = true, allowComboDrinks = true }) then
                bestByKind.waterCombo = waterCand
            end
        end
    end
    if not cls.isConjured then
        if recordingRefs then
            recordingRefs[#recordingRefs + 1] = { kind = cls.kind, candidate = cand }
        end
        Best.Persist.MaybeUpdateRef(cls.kind, cand)
    end
    if resolvedItems then
        resolvedItems[itemID] = true
    end
    return classifyBudget
end

-- The ticker reads current module state on every invocation; it captures no
-- individual scan. Reuse its body without retaining a completed scan's locals.
local function ResumeClassifyQueue()
    if #pendingQueue <= 0 then
        if Best._classifyResumeTicker then
            Best._classifyResumeTicker:Cancel()
            Best._classifyResumeTicker = nil
        end
        classifyFollowups = 0
        return
    end
    classifyFollowups = 0
    if Best.RequestRecompute then
        Best.RequestRecompute({ reason = "classifyResume", delay = 0 })
    end
end

function Scan.Recompute(opts)
    opts = opts or {}
    local inv = Inv()
    if inv and inv.ShouldDeferHeavyWork and inv.ShouldDeferHeavyWork() and not opts.force then
        Best._dirty = true
        return false
    end
    if inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() then
        Best._dirty = true
        return false
    end

    scanSerial = scanSerial + 1
    local serial = scanSerial
    local previous = stableScan
    stableScan = nil
    recordingCounts, recordingKinds, recordingBlocked, recordingRefs = nil, nil, nil, nil
    resolvedThisPulse = 0
    local readPending = opts.reason == "classifyPendingRead"
    local readAPI = InvAPI()
    local readClassify = _G.FluxConsumableClassify
    local readScore = Best.Score
    local ownersMatch = SameOwners(readAPI, readClassify, readScore)
    local reuse = readPending and previous and not opts.force and not opts.forceBank
        and not opts.regions and ownersMatch
        and readAPI.IsReady and readAPI.IsReady() and not BankIsOpen()
        and not (MerchantFrame and MerchantFrame:IsShown())
        and not (Best.IsLoginScanActive and Best.IsLoginScanActive())
        and not (Best.ShouldSoftHoldOwned and Best.ShouldSoftHoldOwned())
        and not (Best.IsConjureArmActive and Best.IsConjureArmActive())
        and not next(Best._pendingAdded or {}) and not next(Best._pendingLoad or {})
        and readAPI.source == previous.source and readAPI.GetBagGeneration() == previous.bagGeneration
        and readClassify.GetInvalidationRevision() == previous.revision
        and Best._generation == previous.generation and Best._runtime == previous.runtime
        and Best._ladders == previous.ladders
        and Best._laddersComboWater == previous.combo and PublishedUnchanged(previous.published)
    if reuse then
        for id in pairs(pendingAttempts) do
            if not pendingSet[id] then reuse = false; break end
        end
    end

    -- Real bag/login/zone pulses reset the classify-followup budget so pending
    -- work can resume; itemData/classifyPending chains stay capped.
    local reason = opts.reason
    if reason ~= "classifyPending" and reason ~= "itemData" and reason ~= "orphanLoad"
        and reason ~= "classifyPendingOnly" and reason ~= "classifyResume" then
        classifyFollowups = 0
        -- Allow previously attempt-capped IDs to retry after real inventory changes.
        -- Also clear soft-pending cache entries so cold-load ForceReject cannot stick.
        local ClassifyInv = _G.FluxConsumableClassify
        if ClassifyInv and ClassifyInv.InvalidateCache then
            for id in pairs(pendingAttempts) do
                pcall(ClassifyInv.InvalidateCache, id)
            end
        end
        wipe(pendingAttempts)
    end
    local revisionAfterReset = reuse and readClassify.GetInvalidationRevision()

    loadsThisPulse = 0
    Best._scanLists = {}
    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.ResetParseBudget then
        Classify.ResetParseBudget()
    end

    local Score = Best.Score
    local maxHP, maxMana = Score.GetPools()
    reuse = reuse and previous.maxHP == maxHP and previous.maxMana == maxMana
    local countsThisPulse, kindsThisPulse, blockedThisPulse = {}, {}, {}
    local refsThisPulse = {}
    recordingCounts, recordingKinds, recordingBlocked = countsThisPulse, kindsThisPulse, blockedThisPulse
    recordingRefs = refsThisPulse
    local bestByKind = {}
    -- Keep this pass-local across reentrant scans. Public owner replacements
    -- retain their original repeated queries and callback behavior.
    local resolvedItems = ownersMatch and {}
    local budget = CLASSIFY_CAP
    local hadPending = #pendingQueue > 0

    -- Drain pending loads first (resume path).
    if hadPending then
        local q = pendingQueue
        pendingQueue = {}
        pendingSet = {}
        for i = 1, #q do
            budget = ConsiderItem(q[i], bestByKind, maxHP, maxMana, budget, resolvedItems)
        end
        -- Read demand keeps polling unresolved IDs at the existing 0.4s cadence.
        -- A newly usable result or any invalidation/count/eligibility change must
        -- take the full path so lower ladder entries and late winners stay fresh.
        if reuse and resolvedThisPulse == 0 and #q == #pendingQueue then
            for i = 1, #q do
                if q[i] ~= pendingQueue[i] then reuse = false; break end
            end
            recordingCounts, recordingKinds, recordingBlocked, recordingRefs = nil, nil, nil, nil
            if reuse then
                for id, count in pairs(previous.counts) do
                    if CountOwned(id) ~= count then reuse = false; break end
                end
            end
            local approvedRefs = updateValidatedRef and {}
            if reuse and Score.IsBlockedForBest then
                for id, kind in pairs(previous.kinds) do
                    local blocked = Score.IsBlockedForBest(id, kind) and true or false
                    if blocked ~= previous.blocked[id] then reuse = false; break end
                    if approvedRefs and not blocked then approvedRefs[id] = kind end
                end
            end
            if reuse then
                local approval
                if approvedRefs and type(updateValidatedRef) == "function" and type(GetTime) == "function" then
                    local clock, frame = GetTime, GetTime()
                    approval = {
                        ids = approvedRefs,
                        current = function(id)
                            if Score.IsExcludedFromBest(id) then return false end
                            return GetTime == clock and clock() == frame and scanSerial == serial
                                and SameOwners(readAPI, readClassify, Score)
                                and readClassify.GetInvalidationRevision() == revisionAfterReset
                                and readAPI.GetBagGeneration() == previous.bagGeneration
                                and Best._generation == previous.generation
                                and Best._runtime == previous.runtime and Best._ladders == previous.ladders
                                and Best._laddersComboWater == previous.combo
                        end,
                    }
                end
                -- Persist still receives its ordinary updates, even when a user
                -- reset the remembered reference while metadata was pending.
                for i = 1, #previous.refs do
                    local ref = previous.refs[i]
                    if approval then
                        updateValidatedRef(ref.kind, ref.candidate, approval)
                    else
                        ownedUpdateRef(ref.kind, ref.candidate)
                    end
                end
            end
            if reuse and scanSerial == serial and Best._generation == previous.generation
                and readClassify.GetInvalidationRevision() == revisionAfterReset
                and readAPI.GetBagGeneration() == previous.bagGeneration
                and Best._runtime == previous.runtime and Best._ladders == previous.ladders
                and Best._laddersComboWater == previous.combo and PublishedUnchanged(previous.published)
                and SameOwners(readAPI, readClassify, Score) and not BankIsOpen() then
                Best._scanLists = previous.scanLists
                Best._dirty = false
                Best._generation = (Best._generation or 0) + 1
                previous.generation = Best._generation
                previous.revision = readClassify.GetInvalidationRevision()
                stableScan = previous
                if Best._notifyListeners then Best._notifyListeners() end
                if Best.RequestRecompute then
                    Best.RequestRecompute({ reason = "classifyPending", delay = 0.4 })
                end
                return true
            end
            recordingCounts, recordingKinds, recordingBlocked = countsThisPulse, kindsThisPulse, blockedThisPulse
            recordingRefs = refsThisPulse
        end
        -- Pending-only early-return ONLY for classify follow-up pulses.
        -- inv/bag/bank/login/zone must always full-walk or CombatGrid goes stale
        -- (0-count, new loot, bank items never detected while classifyQ>0).
        -- Cold login: never skip the unique walk while the login-scan window is open.
        local loginScan = Best.IsLoginScanActive and Best.IsLoginScanActive()
        if #pendingQueue > 0 and reason ~= "classifyPendingRead" and reason and PENDING_ONLY_REASONS[reason] and not loginScan then
            -- Keep prior runtime kinds that were not refreshed this pulse,
            -- but never keep a consumed (count 0) identity as best.
            local kindsChanged = false
            if Best._runtime then
                local softHold = Best.ShouldSoftHoldOwned and Best.ShouldSoftHoldOwned()
                for kind, cand in pairs(Best._runtime) do
                    if bestByKind[kind] == nil then
                        local n = cand and cand.itemID and CountOwned(cand.itemID) or 0
                        if n > 0 then
                            local blocked = Score.IsBlockedForBest and Score.IsBlockedForBest(cand.itemID, kind)
                            if not blocked then
                                cand.count = n
                                bestByKind[kind] = cand
                            else
                                kindsChanged = true
                            end
                        elseif softHold then
                            local blocked = cand.itemID and Score.IsBlockedForBest
                                and Score.IsBlockedForBest(cand.itemID, kind)
                            if not blocked then
                                bestByKind[kind] = cand
                            else
                                kindsChanged = true
                            end
                        else
                            kindsChanged = true
                        end
                    end
                end
            end
            -- Always refresh owned counts so 0-stack buttons update during drain.
            -- Drop empty owned picks so the next item of that kind can win.
            local drop = {}
            for kind, cand in pairs(bestByKind) do
                if cand and cand.itemID and (cand.source == "owned" or not cand.source) then
                    local n = CountOwned(cand.itemID)
                    if n <= 0 and not (Best.ShouldSoftHoldOwned and Best.ShouldSoftHoldOwned()) then
                        drop[#drop + 1] = kind
                        kindsChanged = true
                    elseif Score.IsBlockedForBest and Score.IsBlockedForBest(cand.itemID, kind) then
                        drop[#drop + 1] = kind
                        kindsChanged = true
                    elseif (tonumber(cand.count) or 0) ~= n then
                        cand.count = n
                        kindsChanged = true
                    end
                end
                local prev = Best._runtime and Best._runtime[kind]
                if not prev or prev.itemID ~= cand.itemID or prev.effective ~= cand.effective then
                    kindsChanged = true
                end
            end
            for i = 1, #drop do
                bestByKind[drop[i]] = nil
            end
            Best._runtime = bestByKind
            recordingCounts, recordingKinds, recordingBlocked, recordingRefs = nil, nil, nil, nil
            if kindsChanged then
                Best._generation = (Best._generation or 0) + 1
                if Best._notifyListeners then
                    Best._notifyListeners()
                end
            end
            Best._dirty = false
            if Best.RequestRecompute then
                Best.RequestRecompute({ reason = "classifyPendingOnly", delay = 0.35 })
            end
            return true
        end
        -- Real inventory pulse with leftover pending: merge prior kinds then full-walk.
        -- Do not keep a consumed (count 0) identity as best — unique walk must
        -- be free to pick the next owned item of that kind.
        if Best._runtime then
            local softHold = Best.ShouldSoftHoldOwned and Best.ShouldSoftHoldOwned()
            for kind, cand in pairs(Best._runtime) do
                if bestByKind[kind] == nil then
                    local n = cand and cand.itemID and CountOwned(cand.itemID) or 0
                    if n > 0 then
                        cand.count = n
                        bestByKind[kind] = cand
                    elseif softHold then
                        bestByKind[kind] = cand
                    end
                end
            end
        end
    end

    -- Prefer newly added bag IDs so conjure/loot promotes before the classify cap.
    -- Consume Best._pendingAdded captured on the pulse (must not re-read a later refresh).
    local api = InvAPI()
    local pendingAdded = Best._pendingAdded
    Best._pendingAdded = {}
    local added = pendingAdded
    if type(added) ~= "table" or not next(added) then
        if api and api.GetLastAddedItemIDs then
            added = api.GetLastAddedItemIDs()
        elseif inv and inv.GetLastAddedItemIDs then
            added = inv.GetLastAddedItemIDs()
        elseif inv and inv.Bags and inv.Bags.GetLastAddedItemIDs then
            added = inv.Bags.GetLastAddedItemIDs()
        end
    end
    if type(added) == "table" then
        for itemID in pairs(added) do
            budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget, resolvedItems)
        end
    end

    local unique
    if api and api.GetUniqueItems then
        if api == snapshotItemIDOwner and type(snapshotItemIDs) == "function"
            and rawget(api, "GetUniqueItemIDs") == snapshotItemIDs then
            unique = snapshotItemIDs({ bags = true, bank = false, warband = false, equipped = false })
        else
            unique = api.GetUniqueItems({ bags = true, bank = false, warband = false, equipped = false })
        end
    elseif inv and inv.Bags and inv.Bags.GetUniqueItems then
        unique = inv.Bags.GetUniqueItems()
    end
    -- Conjure arm: prefer owned items whose name says conjured so a restack of
    -- unclassified mage food (countOnly, no added-ID set) still wins the cap.
    if Best.IsConjureArmActive and Best.IsConjureArmActive() and type(unique) == "table" then
        for itemID in pairs(unique) do
            if budget <= 0 then
                break
            end
            local name
            if C_Item and C_Item.GetItemNameByID then
                local ok, n = pcall(C_Item.GetItemNameByID, itemID)
                if ok then
                    name = n
                end
            end
            if (not name or name == "") and GetItemInfo then
                name = GetItemInfo(itemID)
            end
            if type(name) == "string" and name:lower():find("conjured", 1, true) then
                budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget, resolvedItems)
            end
        end
    end
    if type(unique) == "table" then
        for itemID in pairs(unique) do
            if budget <= 0 then
                if not (resolvedItems and resolvedItems[tonumber(itemID)]) then
                    QueuePending(itemID, false)
                end
            else
                budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget, resolvedItems)
            end
        end
    end

    -- Bank / warband: skip when bagsOnly, bank closed, or bags-only pulse.
    local bankGen = 0
    if api and api.snapshots and api.snapshots.bank then
        bankGen = tonumber(api.snapshots.bank.generation) or 0
    elseif inv and inv.Bank and inv.Bank.GetGeneration then
        bankGen = inv.Bank.GetGeneration() or 0
    end
    local wantBank = false
    if not opts.bagsOnly then
        if opts.forceBank then
            wantBank = true
        elseif BankIsOpen() and (opts.force or RegionsWantBank(opts.regions)) then
            wantBank = true
        end
    end
    if not wantBank and bankGen == lastBankScanGen and Best._runtime then
        -- Keep prior bank-sourced candidates; owned bags already refreshed.
    elseif wantBank then
        lastBankScanGen = bankGen
        local bankUnique
        if api and api.GetUniqueItems then
            bankUnique = api.GetUniqueItems({
                bags = false,
                bank = true,
                warband = api.HasWarband and api.HasWarband() or false,
                equipped = false,
            })
        end
        if type(bankUnique) == "table" then
            for itemID, rec in pairs(bankUnique) do
                if budget <= 0 then break end
                if (tonumber(rec and rec.count) or 0) > 0 then
                    budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget, resolvedItems)
                end
            end
        elseif inv and inv.Bank then
            if inv.Bank.GetCharacterCounts then
                local counts = inv.Bank.GetCharacterCounts({ allowCached = true })
                if type(counts) == "table" then
                    for itemID, n in pairs(counts) do
                        if budget <= 0 then break end
                        if (tonumber(n) or 0) > 0 then
                            budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget, resolvedItems)
                        end
                    end
                end
            end
            if inv.Bank.GetWarbandCounts then
                local war = inv.Bank.GetWarbandCounts({ allowCached = true })
                if type(war) == "table" then
                    for itemID, n in pairs(war) do
                        if budget <= 0 then break end
                        if (tonumber(n) or 0) > 0 then
                            budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget, resolvedItems)
                        end
                    end
                end
            end
        end
    end

    -- Merge vendor memory candidates when they beat owned (or fill empty).
    -- Owned count > 0 always wins over vendor stubs for button/restock use.
    local VM = Best.VendorMemory
    for _, kind in ipairs(Best.KINDS) do
        if Best.IsManaKindRelevant(kind) then
            local owned = bestByKind[kind]
            local ownedCount = owned and (tonumber(owned.count) or 0) or 0
            if ownedCount <= 0 then
                local vendors = VM.GetVendorCandidates(kind)
                for i = 1, #vendors do
                    local cand = vendors[i]
                    if Score.IsBetter(cand, bestByKind[kind], true) then
                        bestByKind[kind] = cand
                    end
                end
            end
            -- Capability for HS / mana gem without owned stacks.
            if kind == "healthstone" or kind == "managem" then
                local Spells = (api and api.CreateSpells) or (inv and inv.Spells) or (_G.FluxInv and _G.FluxInv.Spells)
                if Spells and Spells.HasCreateKind and Spells.HasCreateKind(kind) then
                    local cur = bestByKind[kind]
                    if not cur or (cur.count or 0) <= 0 then
                        if not cur then
                            bestByKind[kind] = {
                                itemID = nil,
                                kind = kind,
                                effective = 0,
                                isConjured = true,
                                count = 0,
                                source = "create",
                                canCreate = true,
                            }
                        else
                            cur.canCreate = true
                        end
                    else
                        cur.canCreate = true
                    end
                end
            end
        end
    end

    -- Clear mana kinds when not relevant.
    for kind in pairs(Best.MANA_KINDS) do
        if not Best.IsManaKindRelevant(kind) then
            bestByKind[kind] = nil
        end
    end

    -- Healthstone: hard-coded create-rank overrides heal/itemID mis-picks from classify.
    do
        local tier = Score.HEALTHSTONE_TIER
        if tier then
            for i = 1, #tier do
                local id = tier[i] and tonumber(tier[i].id)
                if id then
                    local n = CountOwned(id)
                    if n > 0 then
                        local rank = Score.HealthstoneRank and Score.HealthstoneRank(id) or (#tier - i + 1)
                        bestByKind.healthstone = {
                            itemID = id,
                            kind = "healthstone",
                            effective = 1000 - i,
                            hsRank = rank,
                            health = 1000 - i,
                            mana = 0,
                            isConjured = true,
                            count = n,
                            source = "owned",
                        }
                        break
                    end
                end
            end
        end
    end

    -- Mana gem: hard-coded IDs so charge/tooltip flicker cannot drop the button.
    do
        local Classify = _G.FluxConsumableClassify
        local ids = Classify and Classify.MANA_GEM_IDS
        if ids then
            for i = 1, #MANA_GEM_ORDER do
                local id = MANA_GEM_ORDER[i]
                if ids[id] then
                    local n = CountOwned(id)
                    if n > 0 then
                        bestByKind.managem = {
                            itemID = id,
                            kind = "managem",
                            effective = 1000 - i,
                            health = 0,
                            mana = 1000 - i,
                            isConjured = true,
                            count = n,
                            source = "owned",
                        }
                        break
                    end
                end
            end
        end
    end

    -- Sticky while classify/load incomplete:
    -- 1) Never demote an existing owned best to a weaker partial result.
    -- 2) Never publish a *first* owned best for combat/food kinds until pending
    --    clears — first pulse often sees only the worst bandage and would stick.
    -- Item-data waits (_pendingLoad) block publish; classify-budget queue alone
    -- only sticks when we have not yet produced any runtime for that kind.
    local hasItemDataPending = next(Best._pendingLoad) ~= nil
    local hasClassifyBacklog = #pendingQueue > 0
    local hasPending = hasItemDataPending or hasClassifyBacklog
    local softHold = Best.ShouldSoftHoldOwned and Best.ShouldSoftHoldOwned()
    if hasPending or softHold then
        local prevRuntime = Best._runtime or {}
        local stickyKinds = {
            bandage = true,
            healPotion = true,
            manaPotion = true,
            food = true,
            water = true,
            healthstone = true,
            managem = true,
        }
        for kind in pairs(stickyKinds) do
            local prev = prevRuntime[kind]
            local cur = bestByKind[kind]
            if prev and prev.itemID and (prev.source == "owned" or not prev.source) then
                -- Never sticky-keep an item this character cannot use yet.
                local prevBlocked = Score.IsBlockedForBest and Score.IsBlockedForBest(prev.itemID, kind)
                local prevCount = CountOwned(prev.itemID)
                if not prevBlocked and prevCount > 0 then
                    local prevEff = tonumber(prev.effective) or 0
                    local curEff = cur and (tonumber(cur.effective) or 0) or 0
                    local curCount = cur and (tonumber(cur.count) or 0) or 0
                    local keepPrev = not cur or curCount <= 0
                    if not keepPrev then
                        -- Never block a strictly better owned candidate (combo/conjured).
                        if Score.IsBetter and Score.IsBetter(cur, prev, true) then
                            keepPrev = false
                        elseif Score.IsBetter then
                            keepPrev = Score.IsBetter(prev, cur, true)
                        else
                            keepPrev = curEff < prevEff
                        end
                    end
                    if keepPrev then
                        local sticky = {}
                        for k, v in pairs(prev) do
                            sticky[k] = v
                        end
                        sticky.count = prevCount
                        sticky.source = "owned"
                        bestByKind[kind] = sticky
                    end
                else
                    -- Bags mid-refresh / portal: keep prior *identity* only.
                    -- Never invent count >= 1 — buttons latch display counts.
                    local bagsReady = true
                    local readyApi = InvAPI()
                    if readyApi and readyApi.IsReady then
                        bagsReady = readyApi.IsReady()
                    elseif Inv() and Inv().Bags and Inv().Bags.IsReady then
                        bagsReady = Inv().Bags.IsReady()
                    end
                    if (not prevBlocked) and (softHold or not bagsReady) and (not cur or (tonumber(cur.count) or 0) <= 0) then
                        local sticky = {}
                        for k, v in pairs(prev) do
                            sticky[k] = v
                        end
                        sticky.count = 0
                        sticky.source = "owned"
                        sticky.uncertain = true
                        bestByKind[kind] = sticky
                    end
                end
            elseif cur and cur.itemID and (cur.source == "owned" or not cur.source) then
                -- Only withhold first publish while item data is still loading.
                -- Classify backlog alone must not blank buttons for tens of seconds.
                if hasItemDataPending and not softHold then
                    bestByKind[kind] = nil
                end
            end
        end
    end

    -- Drop orphaned item-data waits (loaded without ITEM_DATA event).
    local orphanRequeued = false
    do
        local IC = _G.FluxItemClass
        if IC and IC.IsLoaded then
            local drop = {}
            for id in pairs(Best._pendingLoad) do
                if IC.IsLoaded(id) then
                    drop[#drop + 1] = id
                end
            end
            for i = 1, #drop do
                ClearPendingLoad(drop[i])
                if not pendingSet[drop[i]] then
                    QueuePending(drop[i], false)
                    orphanRequeued = true
                end
            end
        end
    end

    Best._runtime = bestByKind
    do
        local lists = Best._scanLists or {}
        local ladders = {}
        for _, kind in ipairs(Best.KINDS) do
            ladders[kind] = SortLadder(lists[kind] or {}, kind, false)
        end
        Best._ladders = ladders
        Best._laddersComboWater = SortLadder(lists.waterCombo or {}, "water", true)
    end
    Best._generation = (Best._generation or 0) + 1
    Best._dirty = false
    do
        local readyApi = InvAPI()
        if readyApi and readyApi.GetBagGeneration then
            Best._bagGenAtScan = readyApi.GetBagGeneration()
        elseif inv and inv.Bags and inv.Bags.GetGeneration then
            Best._bagGenAtScan = inv.Bags.GetGeneration() or 0
        end
    end
    recordingCounts, recordingKinds, recordingBlocked, recordingRefs = nil, nil, nil, nil
    if #pendingQueue > 0 and scanSerial == serial and SameOwners(InvAPI(), _G.FluxConsumableClassify, Score) then
        stableScan = {
            revision = ownedRevision(), generation = Best._generation,
            bagGeneration = Best._bagGenAtScan, source = readAPI and readAPI.source,
            maxHP = maxHP, maxMana = maxMana, runtime = Best._runtime,
            ladders = Best._ladders, scanLists = Best._scanLists,
            combo = Best._laddersComboWater,
            published = PublishedState(Best._runtime, Best._ladders, Best._laddersComboWater),
            counts = countsThisPulse, kinds = kindsThisPulse, blocked = blockedThisPulse,
            refs = refsThisPulse,
        }
    end
    if Best._notifyListeners then
        Best._notifyListeners()
    end
    if #pendingQueue > 0 and Best.RequestRecompute then
        if classifyFollowups < MAX_CLASSIFY_FOLLOWUPS then
            classifyFollowups = classifyFollowups + 1
            Best.RequestRecompute({
                reason = orphanRequeued and "orphanLoad" or "classifyPending",
                delay = 0.4,
            })
        else
            -- Cap hit with backlog remaining: slow resume until drained (don't drop work).
            if not Best._classifyResumeTicker and C_Timer and C_Timer.NewTicker then
                Best._classifyResumeTicker = C_Timer.NewTicker(1.5, ResumeClassifyQueue)
            end
        end
    else
        classifyFollowups = 0
        if Best._classifyResumeTicker then
            Best._classifyResumeTicker:Cancel()
            Best._classifyResumeTicker = nil
        end
    end
    return true
end

function Scan.OnItemDataLoaded(itemID, success, wasClassifyPending)
    itemID = tonumber(itemID)
    if not itemID then
        return
    end
    if Best.Score and Best.Score.InvalidateUsableCache then
        Best.Score.InvalidateUsableCache(itemID)
    end
    local wasWaiting = Best._pendingLoad[itemID] and true or false
    Best._pendingLoad[itemID] = nil
    if success == false then
        return
    end
    local Classify = _G.FluxConsumableClassify
    local wasPending = wasClassifyPending or (Classify and Classify.IsPending and Classify.IsPending(itemID))
    local chaseAdded = Best._pendingAdded and Best._pendingAdded[itemID]
    local chaseConjure = Best.IsConjureArmActive and Best.IsConjureArmActive()
    local chaseLogin = false
    do
        local Flux = _G.Flux
        local api = Flux and Flux.Inventory
        chaseLogin = (api and api.IsLoginHold and api.IsLoginHold())
            or (Best.IsLoginScanActive and Best.IsLoginScanActive())
            or false
    end
    if not wasWaiting and not wasPending then
        -- Portal ITEM_DATA storms: only chase items already selected as Best,
        -- newly added IDs, login hold/scan (owned), or a conjure arm window.
        if chaseAdded then
            -- keep going
        elseif chaseConjure and CountOwned(itemID) > 0 then
            -- keep going
        elseif chaseLogin and CountOwned(itemID) > 0 then
            local IC = _G.FluxItemClass
            local st = IC and IC.GetStatic and IC.GetStatic(itemID)
            if st and st.classID ~= nil and st.classID ~= 0 then
                return
            end
            -- keep going (owned consumable / unknown class during login)
        else
            local rt = Best._runtime
            local inRuntime = rt and (
                (rt.food and rt.food.itemID == itemID)
                or (rt.water and rt.water.itemID == itemID)
                or (rt.bandage and rt.bandage.itemID == itemID)
                or (rt.healPotion and rt.healPotion.itemID == itemID)
                or (rt.manaPotion and rt.manaPotion.itemID == itemID)
                or (rt.healthstone and rt.healthstone.itemID == itemID)
                or (rt.managem and rt.managem.itemID == itemID)
            )
            if not inRuntime then
                return
            end
        end
    end
    QueuePending(itemID, false)
    Best.RequestRecompute({ reason = "itemData", delay = 0.3 })
end

--- True when no items are waiting on C_Item data AND classify backlog is drained.
function Best.IsSettled()
    if Best._pendingLoad and next(Best._pendingLoad) ~= nil then
        return false
    end
    if #pendingQueue > 0 then
        return false
    end
    return true
end

function Best.GetPendingLoadCount()
    local n = 0
    if Best._pendingLoad then
        for _ in pairs(Best._pendingLoad) do
            n = n + 1
        end
    end
    return n
end

function Best.GetClassifyQueueCount()
    return #pendingQueue
end

_G.FluxConsumableBest = Best
return Scan
