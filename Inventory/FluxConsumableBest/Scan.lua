--[[
    Inventory/FluxConsumableBest/Scan.lua

    Debounced scan of FluxInv unique items + bank/warband counts.
    Caps classification work per pulse; resumes on item data load.
]]

FluxConsumableBest = FluxConsumableBest or {}
local Best = FluxConsumableBest
Best.Scan = Best.Scan or {}
local Scan = Best.Scan

local CLASSIFY_CAP = 24
local LOAD_CAP = 8
local PENDING_CAP = 40
local MAX_CLASSIFY_FOLLOWUPS = 3
-- Stop re-queuing a single stuck ID; do NOT permanently reject (cold-load tooltips).
local MAX_ITEM_PENDING_ATTEMPTS = 8
local pendingQueue = {}
local pendingSet = {}
local pendingAttempts = {} -- [itemID] = attempts while still pending/classify-deferred
local loadsThisPulse = 0
local lastBankScanGen = -1
local classifyFollowups = 0

-- Follow-up drain pulses may skip the full unique walk. Real bag/bank/login
-- pulses must always walk so counts and new items update CombatGrid.
local PENDING_ONLY_REASONS = {
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
        return api.GetCount(itemID, {
            bags = true,
            bank = false,
            warband = false,
            equipped = false,
        }) or 0
    end
    local inv = Inv()
    if not inv then
        return 0
    end
    if inv.GetCount then
        return inv.GetCount(itemID, { bags = true, bank = false, warband = false }) or 0
    end
    if inv.Bags and inv.Bags.GetCount then
        return inv.Bags.GetCount(itemID) or 0
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
    if Score.IsBlockedForBest and Score.IsBlockedForBest(itemID, cls.kind) then
        return nil
    elseif not Score.IsBlockedForBest and Score.IsKnownUnusable and Score.IsKnownUnusable(itemID, cls.kind) then
        return nil
    end
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

local function ConsiderItem(itemID, bestByKind, maxHP, maxMana, classifyBudget)
    local Classify = _G.FluxConsumableClassify
    local IC = _G.FluxItemClass
    if not Classify or not Classify.Classify then
        return classifyBudget
    end
    itemID = tonumber(itemID)
    if not itemID then
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
    classifyBudget = classifyBudget - 1
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
        Best.Persist.MaybeUpdateRef(cls.kind, cand)
    end
    return classifyBudget
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

    loadsThisPulse = 0
    Best._scanLists = {}
    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.ResetParseBudget then
        Classify.ResetParseBudget()
    end

    local Score = Best.Score
    local maxHP, maxMana = Score.GetPools()
    local bestByKind = {}
    local budget = CLASSIFY_CAP
    local hadPending = #pendingQueue > 0

    -- Drain pending loads first (resume path).
    if hadPending then
        local q = pendingQueue
        pendingQueue = {}
        pendingSet = {}
        for i = 1, #q do
            budget = ConsiderItem(q[i], bestByKind, maxHP, maxMana, budget)
        end
        -- Pending-only early-return ONLY for classify follow-up pulses.
        -- inv/bag/bank/login/zone must always full-walk or CombatGrid goes stale
        -- (0-count, new loot, bank items never detected while classifyQ>0).
        -- Cold login: never skip the unique walk while the login-scan window is open.
        local loginScan = Best.IsLoginScanActive and Best.IsLoginScanActive()
        if #pendingQueue > 0 and reason and PENDING_ONLY_REASONS[reason] and not loginScan then
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
            budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget)
        end
    end

    local unique
    if api and api.GetUniqueItems then
        unique = api.GetUniqueItems({ bags = true, bank = false, warband = false, equipped = false })
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
                budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget)
            end
        end
    end
    if type(unique) == "table" then
        for itemID in pairs(unique) do
            if budget <= 0 then
                QueuePending(itemID, false)
            else
                budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget)
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
                    budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget)
                end
            end
        elseif inv and inv.Bank then
            if inv.Bank.GetCharacterCounts then
                local counts = inv.Bank.GetCharacterCounts({ allowCached = true })
                if type(counts) == "table" then
                    for itemID, n in pairs(counts) do
                        if budget <= 0 then break end
                        if (tonumber(n) or 0) > 0 then
                            budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget)
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
                            budget = ConsiderItem(itemID, bestByKind, maxHP, maxMana, budget)
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
            local ordered = { 36799, 33312, 22044, 8008, 8007, 5513, 5514 }
            for i = 1, #ordered do
                local id = ordered[i]
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
                Best._classifyResumeTicker = C_Timer.NewTicker(1.5, function()
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
                end)
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

function Scan.OnItemDataLoaded(itemID, success)
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
    local wasPending = Classify and Classify.IsPending and Classify.IsPending(itemID)
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
