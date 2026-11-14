-- Consumable upgrade discovery. Reuses classification, usability and tier owners.
local _, ns = ...
local A, L = FluxAuctionRestock, ns.FluxOptionsLocale
local replacements, catalog, current, blocked = {}, nil, nil, {}
local replacementKinds = {}
local declined = {}
local function UpgradeCombat()
    if current and #A.GetUpgradeProposals() > 0 then A.Invalidate("combat") end
end
function A.GetUpgradeProposals()
    local result = {}
    for _, proposal in ipairs(current and current.proposals or {}) do
        if not proposal.resolved then result[#result + 1] = proposal end
    end
    return result
end
function A.ResolveUpgrade(proposal, action)
    if A.state ~= "upgrade" or not current or not A.active or not A.houseOpen or InCombatLockdown()
        or not proposal or not A.IsUpgradeEnabled(proposal.kind)
        or (action ~= "upgrade" and action ~= "keep" and action ~= "blacklist") then return false end
    for _, live in ipairs(current.proposals) do
        if live == proposal and not live.resolved then
            live.resolved = true; live.resolve(action); return true
        end
    end
    return false
end
local function Services()
    local best, classify = _G.FluxConsumableBest, _G.FluxConsumableClassify
    return best, best and best.Score, classify
end
local function Kind(row)
    if row.tierKind == "healPotion" or row.tierKind == "manaPotion" or row.tierKind == "bandage" then return row.tierKind end
    local ic, classify = _G.FluxItemClass, _G.FluxConsumableClassify
    if not row.itemID or not ic or not ic.GetClassID or not ic.GetSubClassID
        or ic.GetClassID(row.itemID) ~= 0
        or (ic.GetSubClassID(row.itemID) ~= 1 and ic.GetSubClassID(row.itemID) ~= 7) then return end
    local cls = classify and classify.Classify and classify.Classify(row.itemID)
    if cls and (cls.kind == "healPotion" or cls.kind == "manaPotion" or cls.kind == "bandage") then return cls.kind end
end
A.PotionKind = Kind
function A.CapturePotionTargets(list)
    A.potionTargets = {}
    local best, score = Services()
    if not score or not score.IsBetter or not score.IsUsableForVendor then return end
    local preferences = A.Settings()
    preferences.potionLimitSources = type(preferences.potionLimitSources) == "table" and preferences.potionLimitSources or {}
    for _, row in ipairs(list) do
        local kind = Kind(row)
        if kind and (row.target or 0) >= 0 and (not best.IsManaKindRelevant or best.IsManaKindRelevant(kind)) then
            local ref = row.isTierRestock and best.GetBestRef and best.GetBestRef(kind)
            local id = ref and ref.itemID or row.itemID
            local limitID = id
            if row.isTierRestock then
                local previous = preferences.potionLimitSources[kind]
                if id and (not previous or preferences.maxUnitPrices[id] ~= nil) then preferences.potionLimitSources[kind] = id end
                limitID = preferences.potionLimitSources[kind] or id
            end
            A.potionTargets[#A.potionTargets + 1] = { kind = kind, sourceID = id, limitSourceID = limitID, target = row.target, countBank = row.countBank }
        end
    end
end
function A.PotionReplacement(id)
    local replacement = replacements[id]
    local _, score = Services()
    local kind = replacement and Kind({ itemID = replacement })
    if replacement and kind and kind == replacementKinds[id] and score and (not score.IsKnownUnusable or not score.IsKnownUnusable(replacement, kind))
        and score.IsUsableForVendor(replacement, kind) then return replacement end
end
-- GetRows computes final stock after replacement/merge; standalone callers
-- still receive populated needs without opting into that owning batch.
function A.ApplyPotionReplacements(rows, deferNeed)
    local result, seen = {}, {}
    for _, original in ipairs(rows) do
        local id = A.PotionReplacement(original.itemID)
        local row = original
        if id and id ~= original.itemID and not A.IsVendorItem(id) then
            row = {}; for key, value in pairs(original) do row[key] = value end
            row.itemID, row.upgradeFrom = id, original.itemID
            A.SetItemUnits(row)
            local ic = _G.FluxItemClass
            row.name = ic and ic.GetName(id) or original.name
            row.texture = ic and ic.GetIcon and ic.GetIcon(id) or original.texture
            local inv = _G.FluxRestock and _G.FluxRestock.Inv
            row.bankCount = inv and inv.Bank and inv.Bank.GetCount and inv.Bank.GetCount(id, { charges = row.isCharge }) or 0
            if not deferNeed then row.need = A.Need(row) end
        end
        local kind = Kind(row)
        local best = _G.FluxConsumableBest
        local ref = kind and best and best.GetBestRef and best.GetBestRef(kind)
        if ref and ref.source == "auction" and (ref.effective or 0) > 0 then
            row.auctionTier = ref.effective
            if not deferNeed then row.need = A.Need(row) end
        end
        local existing = seen[row.itemID]
        if existing then
            existing.target = math.max(existing.target or 0, row.target or 0)
            existing.isTierRestock = existing.isTierRestock and row.isTierRestock
            existing.tiers = existing.tiers or {}
            for _, source in ipairs(row.tiers or {}) do existing.tiers[#existing.tiers + 1] = source end
            if not deferNeed then existing.need = A.Need(existing) end
        else result[#result + 1], seen[row.itemID] = row, row end
    end
    return result
end
function A.CancelPotionDiscovery()
    local job = current
    current = nil
    if job then ns.Flux.Events.Unregister("PLAYER_REGEN_DISABLED", UpgradeCombat) end
end
function A.ResetPotionUpgradeChoices() declined = {} end
function A.ResetPotionDiscovery()
    A.CancelPotionDiscovery()
    catalog, blocked, declined = nil, {}, {}
end
local function PlayerLevel()
    return UnitLevel and A.Number(UnitLevel("player")) or 0
end
function A.HasPotionCatalog(kind)
    local entry = catalog and catalog[kind]
    local at = entry and entry.at
    return entry and entry.level == PlayerLevel()
        and type(at) == "number" and GetTime() - at >= 0 and GetTime() - at < 30 or false
end
function A.HasBlockedPotionTargets() return next(blocked) ~= nil end
function A.PotionRowBlocked(row)
    local kind = Kind(row)
    if not kind then return false end
    local best, score = Services()
    return A.IsUpgradeBlacklisted(row.itemID) or blocked[kind] == true or (best and best.IsManaKindRelevant and not best.IsManaKindRelevant(kind))
        or (score and score.IsKnownUnusable and score.IsKnownUnusable(row.itemID, kind)) or false
end

local function RequestRestoreSpell(id)
    local item = ns.Flux.Item
    if not current or not item or not item.GetSpell or not C_Spell or not C_Spell.RequestLoadSpellData then return end
    current.spellLoads = current.spellLoads or {}
    if current.spellLoads[id] then return end
    local _, spellID = item.GetSpell(id)
    spellID = A.Number(spellID)
    if spellID and spellID > 0 and spellID % 1 == 0 then
        current.spellLoads[id] = { spellID = spellID }
        -- Item metadata can be ready while its Use spell text is still cold.
        -- Prime that linked record once; the bounded classifier batches retry.
        C_Spell.RequestLoadSpellData(spellID)
    end
end
local function RefreshRestoreSpell(id, classify)
    local record = current and current.spellLoads and current.spellLoads[id]
    if not record or record.ready or not C_Spell or not C_Spell.GetSpellDescription then return end
    local text = C_Spell.GetSpellDescription(record.spellID)
    if type(text) == "string" and text ~= "" then
        record.ready = true
        -- A name-free potion may have reached a negative parse before its Use
        -- spell arrived. Reconsider that item once, using the now-ready tooltip.
        if classify.InvalidateCache then classify.InvalidateCache(id) end
    end
end
local function Candidate(id)
    local _, score, classify = Services()
    local ic = _G.FluxItemClass
    if not score or not classify or not classify.Classify then return end
    if A.IsUpgradeBlacklisted(id) then return end
    if ic and ic.IsLoaded and not ic.IsLoaded(id) then if ic.RequestLoad then ic.RequestLoad(id) end; return nil, true end
    if score.IsKnownUnusable and score.IsKnownUnusable(id) then return end
    RefreshRestoreSpell(id, classify)
    local cls = classify.Classify(id)
    if not cls then
        local pending = not (classify.IsRejected and classify.IsRejected(id))
        if pending then RequestRestoreSpell(id) end
        local record = current and current.spellLoads and current.spellLoads[id]
        if record and not record.ready and C_Spell and C_Spell.GetSpellDescription then pending = true end
        return nil, pending
    end
    if cls.isConjured or (cls.kind ~= "healPotion" and cls.kind ~= "manaPotion" and cls.kind ~= "bandage") then return end
    if not score.IsUsableForVendor(id, cls.kind) or (score.IsKnownUnusable and score.IsKnownUnusable(id, cls.kind)) then return end
    if cls.restoreKnown == false then
        -- The bag classifier can keep a name-only placeholder. AH ranking needs
        -- the real restore line, which may arrive after metadata is already loaded.
        if classify.InvalidateCache then classify.InvalidateCache(id) end
        RequestRestoreSpell(id)
        return nil, true, cls.kind
    end
    local effective = score.EffectiveFromClassify and A.Number(score.EffectiveFromClassify(cls))
    if not effective or effective <= 0 then return end
    return { itemID = id, kind = cls.kind, effective = effective, isConjured = false,
        isPercent = cls.isPercent, restoreRaw = cls.restoreRaw or effective, health = cls.health, mana = cls.mana,
        maxStack = score.GetMaxStack and score.GetMaxStack(id) or 0 }
end
local function Limit(target, id)
    local saved = A.Number(A.Settings().maxUnitPrices[id])
    local source = id
    if saved == nil then
        source = target.limitSourceID or target.sourceID
    end
    return A.PriceLimit(source), A.GetMaxPrice(source), A.IsPriceUnlimited(source)
end
local function MissingTarget(target)
    if not target.sourceID then return (target.target or 0) > 0 end
    local row = A.FindRow(target.sourceID)
    if not row then
        for _, hidden in ipairs(A.GetVendorScanRows and A.GetVendorScanRows() or {}) do
            if hidden.itemID == target.sourceID then row = hidden; break end
        end
    end
    local need = row and A.Need(row)
    return need ~= nil and need > 0
end
function A.DiscoverPotionUpgrades(targets, done, includeStocked)
    if not targets or #targets == 0 then return false end
    local _, score = Services()
    if not score then return false end
    -- Gather the configured consumable choices together. Pricing and buying the
    -- restock list still remain per item on old auction houses.
    local all, seen = {}, {}
    for _, source in ipairs({ targets, A.potionTargets or {} }) do
        for _, target in ipairs(source) do
            local key = target.kind .. ":" .. (target.sourceID or 0)
            if (target.target or 0) > 0 and A.IsUpgradeEnabled(target.kind) and not seen[key]
                and (includeStocked or MissingTarget(target)) then all[#all + 1], seen[key] = target, true end
        end
    end
    targets = all
    if #targets == 0 then return false end
    local modern = C_AuctionHouse and C_AuctionHouse.GetBrowseResults and C_AuctionHouse.SendBrowseQuery
        and C_AuctionHouse.HasFullBrowseResults and C_AuctionHouse.RequestMoreBrowseResults
        and Enum and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.UsableOnly and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Name
    if not A.legacy and not modern then for _, target in ipairs(targets) do blocked[target.kind] = true end; return false end
    local job = { targets = targets, candidates = {}, proposals = {}, index = 1, deadline = GetTime() + 12 }
    current = job
    local requestedKinds = {}
    for _, target in ipairs(targets) do requestedKinds[target.kind] = true; blocked[target.kind] = nil end
    local function Alive() return current == job and A.active and A.houseOpen end
    local function Complete()
        if not Alive() then return end
        job.discoveryDone = true
        if #A.GetUpgradeProposals() > 0 then
            A.state, A.status = "upgrade", "potionUpgrade"
            if A.UpdateUI then A.UpdateUI() end
            return
        end
        ns.Flux.Events.Unregister("PLAYER_REGEN_DISABLED", UpgradeCombat)
        current = nil; A.state = "idle"; done(targets)
    end
    local targetIndex = 0
    local NextTarget
    NextTarget = function()
        if not Alive() then return end
        targetIndex = targetIndex + 1
        local target = targets[targetIndex]
        if not target then Complete(); return end
        if blocked[target.kind] or declined[target.kind] == (target.sourceID or 0) then NextTarget(); return end
        local baseline = target.sourceID and Candidate(target.sourceID)
        if not baseline and target.sourceID then
            local best = _G.FluxConsumableBest
            local ref = best and best.GetBestRef and best.GetBestRef(target.kind)
            if ref and ref.itemID == target.sourceID then baseline = ref end
        end
        if baseline and job.market[baseline.itemID] then
            local priced = {}; for key, value in pairs(baseline) do priced[key] = value end
            priced.price = job.market[baseline.itemID].minPrice; baseline = priced
        end
        local options = {}
        for _, candidate in pairs(job.candidates) do
            local market = job.market[candidate.itemID]
            candidate.price = market.minPrice
            local cap = Limit(target, candidate.itemID)
            local vendor = A.HasUnlimitedVendor and A.HasUnlimitedVendor(candidate.itemID)
                or (not A.HasUnlimitedVendor and A.IsVendorItem(candidate.itemID))
            local vendorPrice = vendor and A.VendorPrice(candidate.itemID)
            local auctionSource = not vendor or (vendorPrice and market.minPrice < vendorPrice)
            if candidate.kind == target.kind and candidate.itemID ~= target.sourceID and auctionSource
                and market.minPrice <= cap and (not baseline or score.IsBetter(candidate, baseline, false)) then
                options[#options + 1] = candidate
            end
        end
        table.sort(options, function(a, b) return score.IsBetter(a, b, false) end)
        local optionIndex = 0
        local function TargetDone()
            if job.discoveryDone then Complete() else NextTarget() end
        end
        local TryOption
        TryOption = function()
            if not Alive() then return end
            optionIndex = optionIndex + 1
            local candidate = options[optionIndex]
            if not candidate then TargetDone(); return end
            if A.IsUpgradeBlacklisted(candidate.itemID) then TryOption(); return end
            local cap, inherited, inheritedUnlimited = Limit(target, candidate.itemID)
            local function Check(book)
                if not Alive() then return end
                A.priceBooks[candidate.itemID] = book
                local offers = A.FilterVendorOffers and A.FilterVendorOffers(candidate.itemID, book.offers, book.commodity) or book.offers
                local offer = book.commodity and A.CommodityOffer(offers, 1, cap)
                    or (not book.commodity and A.SelectStack(offers, target.target > 0 and target.target or math.huge, cap, A.AllowExcessStacks(candidate.itemID)))
                if not offer then TryOption(); return end
                candidate.price = offer.total / offer.quantity
                local best = _G.FluxConsumableBest
                local reference = best and best.GetBestRef and best.GetBestRef(target.kind)
                local referenceID, referenceTier = reference and reference.itemID, reference and reference.effective
                local level = PlayerLevel()
                local proposal = { sourceID = target.sourceID, kind = target.kind, candidate = candidate,
                    unitPrice = candidate.price, target = target.target, previousRestore = baseline and baseline.effective or 0 }
                proposal.resolve = function(action)
                    if not Alive() then return end
                    if action == "blacklist" then
                        A.Settings().upgradeBlacklist[candidate.itemID] = true
                        A.RefreshConsumableExclusions()
                        TryOption(); return
                    elseif action == "keep" then
                        declined[target.kind] = target.sourceID or 0
                    else
                        -- The cell authorizes only this tier change, never a buy.
                        -- Recheck mutable eligibility/settings before any saved change.
                        local fresh = Candidate(candidate.itemID)
                        local ref = best and best.GetBestRef and best.GetBestRef(target.kind)
                        local freshCap, freshInherited, freshUnlimited = Limit(target, candidate.itemID)
                        A.GetRows(true)
                        local targetMatches = false
                        for _, latest in ipairs(A.potionTargets or {}) do
                            if latest.kind == target.kind and latest.sourceID == target.sourceID and latest.target == target.target
                                and latest.countBank == target.countBank then targetMatches = true; break end
                        end
                        local tiers = _G.FluxRestockTiers
                        if InCombatLockdown() or level ~= PlayerLevel() or not fresh or fresh.kind ~= target.kind
                            or fresh.effective ~= candidate.effective or (ref and ref.itemID) ~= referenceID
                            or (ref and ref.effective) ~= referenceTier or not targetMatches or freshCap ~= cap
                            or freshInherited ~= inherited or freshUnlimited ~= inheritedUnlimited
                            or not tiers or not tiers.ApplyAuctionTierUpgrade then
                            A.Invalidate("changed")
                            A.Defer(0, function() if A.active and A.houseOpen then A.PrepareNext() end end)
                            return
                        end
                        A.applyingAuctionTier = true
                        local ok, changed = pcall(tiers.ApplyAuctionTierUpgrade, target.kind, candidate)
                        A.applyingAuctionTier = false
                        if not ok then
                            A.Invalidate("unavailable")
                            local handler = geterrorhandler and geterrorhandler(); if handler then handler(changed) end
                            return
                        end
                        if changed then
                            if target.sourceID then replacements[target.sourceID], replacementKinds[target.sourceID] = candidate.itemID, target.kind end
                            if A.Settings().maxUnitPrices[candidate.itemID] == nil then
                                A.Settings().maxUnitPrices[candidate.itemID] = inherited
                                A.Settings().noPriceLimit[candidate.itemID] = inheritedUnlimited
                            end
                            -- Inferior junk belongs to the global tier service.
                            -- A proposal or mailbox item is not a carried upgrade.
                        end
                    end
                    Complete()
                end
                job.proposals[#job.proposals + 1] = proposal
                if not job.observing then
                    job.observing = true; ns.Flux.Events.Register("PLAYER_REGEN_DISABLED", UpgradeCombat)
                end
                if A.UpdateUI then A.UpdateUI() end
                TargetDone()
            end
            local book = A.priceBooks[candidate.itemID]
            if book and GetTime() - book.at < 30 then Check(book)
            else A.BeginSearch({ itemID = candidate.itemID, target = target.target, unitsPerItem = 1 }, Check) end
        end
        TryOption()
    end
    local function ClassifyBatch()
        if not Alive() then return end
        local _, _, classify = Services()
        -- Inventory may have exhausted this shared budget before the AH opened.
        -- Renew it for each deferred batch; this owner still processes at most8 IDs.
        if classify and classify.ResetParseBudget then classify.ResetParseBudget() end
        local stop = math.min(#job.ids, job.index + 7)
        for i = job.index, stop do
            local id = job.ids[i]
            local candidate, pending, kind = Candidate(id)
            if candidate then job.candidates[id] = candidate
            elseif pending then job.pending[#job.pending + 1] = id; job.pendingKinds[id] = kind end
        end
        job.index = stop + 1
        if job.index <= #job.ids then A.Defer(0.01, ClassifyBatch)
        elseif #job.pending > 0 and GetTime() < job.deadline then
            job.ids, job.pending, job.index = job.pending, {}, 1
            A.Defer(0.2, ClassifyBatch)
        else
            for _, id in ipairs(job.pending) do
                local market, kind = job.market[id], job.pendingKinds[id]
                for _, target in ipairs(targets) do
                    if kind == target.kind or (not kind and (market.allUpgradeKinds or not market.upgradeKinds or market.upgradeKinds[target.kind])) then
                        blocked[target.kind] = true
                    end
                end
            end
            NextTarget()
        end
    end
    local function ReadCatalog(market, cached)
        if not Alive() then return end
        catalog = catalog or {}
        for kind in pairs(requestedKinds) do
            if not cached then catalog[kind] = { market = market, at = GetTime(), level = PlayerLevel() } end
        end
        job.deadline = GetTime() + 12
        job.market, job.ids, job.pending, job.pendingKinds = market, {}, {}, {}
        for id in pairs(market) do job.ids[#job.ids + 1] = id end
        A.state, A.status = "classifying", "potionScan"
        if A.UpdateUI then A.UpdateUI() end
        ClassifyBatch()
    end
    local covered = catalog ~= nil
    for kind in pairs(requestedKinds) do if not A.HasPotionCatalog(kind) then covered = false end end
    if covered then
        local market = {}
        for kind in pairs(requestedKinds) do for id, offer in pairs(catalog[kind].market) do market[id] = offer end end
        ReadCatalog(market, true)
    else
        local terms, kinds, termKinds = {}, {}, {}
        for _, target in ipairs(targets) do kinds[target.kind] = true end
        if kinds.healPotion then terms[#terms + 1] = L.AH_SEARCH_HEALING_POTION end
        if kinds.manaPotion then terms[#terms + 1] = L.AH_SEARCH_MANA_POTION end
        if kinds.bandage then terms[#terms + 1] = L.AH_SEARCH_BANDAGE end
        termKinds[L.AH_SEARCH_HEALING_POTION], termKinds[L.AH_SEARCH_MANA_POTION], termKinds[L.AH_SEARCH_BANDAGE] = "healPotion", "manaPotion", "bandage"
        A.BeginPotionBrowse(ReadCatalog, terms, termKinds)
    end
    return true
end
