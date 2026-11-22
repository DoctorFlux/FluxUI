-- Auction preferences and target math. Shares the existing inventory/target owners.
local _, ns = ...
FluxAuctionRestock = FluxAuctionRestock or {}
local A = FluxAuctionRestock
A.rows = {}
A.vendorScanRows = {}

function A.Number(value)
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then return nil end
    return value
end
local Number = A.Number

-- Validate the addon-private defining-function/query pair once at load.
local carriedRestockRecord = rawget(ns, "RestockCarriedLiveQuery")
local carriedRestockFlux = rawget(ns, "Flux")
local carriedRestockGetter, carriedRestockQuery
if type(carriedRestockRecord) == "table" and type(carriedRestockFlux) == "table"
    and rawequal(rawget(carriedRestockRecord, "namespace"), ns)
    and rawequal(rawget(carriedRestockRecord, "flux"), carriedRestockFlux) then
    local getter = rawget(carriedRestockRecord, "getter")
    local query = rawget(carriedRestockRecord, "query")
    if type(getter) == "function" and type(query) == "function" then
        carriedRestockGetter, carriedRestockQuery = getter, query
    end
end

function A.Settings()
    local s = FluxRestockSettings.Get()
    if type(s.auctionRestock) ~= "table" then s.auctionRestock = {} end
    local a = s.auctionRestock
    if type(a.maxUnitPrices) ~= "table" then a.maxUnitPrices = {} end
    if type(a.noPriceLimit) ~= "table" then a.noPriceLimit = {} end
    if type(a.pending) ~= "table" then a.pending = {} end
    if type(a.upgradeBlacklist) ~= "table" then a.upgradeBlacklist = {} end
    if type(a.upgradePrompts) ~= "table" then a.upgradePrompts = {} end
    return a
end

local upgradeDefaults = { healPotion = true, manaPotion = true, bandage = false }
function A.IsUpgradeEnabled(kind)
    if upgradeDefaults[kind] == nil then return false end
    local enabled = A.Settings().upgradePrompts[kind]
    if type(enabled) == "boolean" then return enabled end
    return upgradeDefaults[kind]
end
function A.SetUpgradeEnabled(kind, enabled)
    if upgradeDefaults[kind] == nil or type(enabled) ~= "boolean" or A.transaction or A.state == "quoting" then return false end
    A.Settings().upgradePrompts[kind] = enabled
    if A.ResetPotionDiscovery then A.ResetPotionDiscovery() end
    if A.SettingsChanged then A.SettingsChanged() end
    return true
end

function A.UpgradeItemID(value)
    local id = type(value) == "number" and value or type(value) == "string"
        and tonumber(value:match("item:(%d+)") or value:match("^%s*(%d+)%s*$"))
    return Number(id) and id > 0 and id % 1 == 0 and id or nil
end
function A.IsUpgradeBlacklisted(id)
    local best = _G.FluxConsumableBest
    local score = best and best.Score
    return A.Settings().upgradeBlacklist[id] == true or score and score.IsExcludedFromBest and score.IsExcludedFromBest(id) or false
end
function A.RefreshConsumableExclusions()
    local best, tiers = _G.FluxConsumableBest, _G.FluxRestockTiers
    if best and best.RequestRecompute then best.RequestRecompute({ reason = "exclusions", force = true, delay = 0 }) end
    if tiers and tiers.InvalidateTierQueryCache then tiers.InvalidateTierQueryCache() end
    if tiers and tiers.RequestRecompute then tiers.RequestRecompute({ scope = "inferior", force = true, notify = true }) end
end
function A.ExcludesDiscoloredHealing() return A.Settings().excludeDiscoloredHealingPotions ~= false end
function A.SetExcludeDiscoloredHealing(enabled)
    if type(enabled) ~= "boolean" or A.transaction then return false end
    A.Settings().excludeDiscoloredHealingPotions = enabled
    A.RefreshConsumableExclusions()
    if A.ResetCraftPlans then A.ResetCraftPlans() end
    if A.ResetPotionDiscovery then A.ResetPotionDiscovery() end
    if A.SettingsChanged then A.SettingsChanged() end
    return true
end
function A.SetUpgradeBlacklisted(value, excluded)
    local id = A.UpgradeItemID(value)
    if not id or type(excluded) ~= "boolean" or A.transaction then return false end
    A.Settings().upgradeBlacklist[id] = excluded and true or nil
    A.RefreshConsumableExclusions()
    if A.ResetCraftPlans then A.ResetCraftPlans() end
    if A.ResetPotionDiscovery then A.ResetPotionDiscovery() end
    if A.SettingsChanged then A.SettingsChanged() end
    return true
end
function A.UpgradeBlacklistItems()
    local result, ic = {}, _G.FluxItemClass
    for id, excluded in pairs(A.Settings().upgradeBlacklist) do
        if excluded == true and A.UpgradeItemID(id) then result[id] = ic and ic.GetName and ic.GetName(id) or tostring(id) end
    end
    return result
end

function A.GetMaxPrice(id)
    return Number(A.Settings().maxUnitPrices[id]) or 0
end
function A.IsPriceUnlimited(id)
    local settings = A.Settings()
    local unlimited = settings.noPriceLimit[id]
    if type(unlimited) ~= "boolean" then
        -- Preserve old positive caps. Zero and absent prices meant unlimited
        -- before the explicit toggle existed; newly added items default to it.
        unlimited = A.GetMaxPrice(id) == 0
        if Number(id) and id > 0 and id % 1 == 0 then settings.noPriceLimit[id] = unlimited end
    end
    return unlimited
end
function A.PriceLimit(id)
    return A.IsPriceUnlimited(id) and math.huge or A.GetMaxPrice(id)
end
function A.PricePolicyMatches(id, price, unlimited)
    if type(unlimited) ~= "boolean" then unlimited = price == 0 end
    return A.GetMaxPrice(id) == price and A.IsPriceUnlimited(id) == unlimited
end
function A.PreferCrafting() return A.Settings().preferCrafting ~= false end
function A.SetPreferCrafting(enabled)
    A.Settings().preferCrafting = enabled == true
    if A.ResetCraftPlans then A.ResetCraftPlans() end
    if A.SettingsChanged then A.SettingsChanged() end
end
function A.PurchaseLimit(id)
    local derived = A.MaterialLimit and A.MaterialLimit(id)
    if derived ~= nil then return derived end
    return A.PriceLimit(id)
end

function A.SetMaxPrice(id, price, unlimited)
    if not Number(id) or id <= 0 or id % 1 ~= 0 or not Number(price)
        or price % 1 ~= 0 or price > 1000000000000
        or (unlimited ~= nil and type(unlimited) ~= "boolean") then return false end
    -- Two-argument callers retain their existing combined price/mode contract.
    -- The editor supplies the explicit mode, so a limited zero stays zero.
    if unlimited == nil then unlimited = price == 0 end
    local settings = A.Settings()
    settings.maxUnitPrices[id], settings.noPriceLimit[id] = price, unlimited
    if A.ResetCraftPlans then A.ResetCraftPlans() end
    if A.SettingsChanged then A.SettingsChanged() elseif A.Invalidate then A.Invalidate("changed") end
    return true
end
function A.SetPriceUnlimited(id, unlimited)
    if type(unlimited) ~= "boolean" then return false end
    return A.SetMaxPrice(id, A.GetMaxPrice(id), unlimited)
end

function A.ParsePrice(text)
    if type(text) ~= "string" then return nil end
    text = text:lower():gsub("%s+", "")
    if text == "" or text == "0" then return 0 end
    local amount, seen = 0, {}
    while text ~= "" do
        local token, unit, rest = text:match("^(%d+)([gsc])(.*)$")
        if not token or seen[unit] then return nil end
        seen[unit] = true
        local value = tonumber(token)
        if not Number(value) then return nil end
        amount = amount + value * (unit == "g" and 10000 or unit == "s" and 100 or 1)
        if amount > 1000000000000 then return nil end
        text = rest
    end
    return amount
end

function A.PriceText(amount)
    amount = math.floor(Number(amount) or 0)
    if amount == 0 then return "" end
    return ("%dg %ds %dc"):format(math.floor(amount / 10000), math.floor(amount / 100) % 100, amount % 100)
end

-- Canonical source facts: this character's typed merchant observations override
-- the selected bundled catalogue. Price-only memories do not establish stock.
-- Returns unlimited, unit buy price, catalogue profile, source provenance.
function A.VendorSource(id)
    if not Number(id) or id <= 0 or id % 1 ~= 0 then return false end
    local s = FluxRestockSettings.Get()
    local source = type(s.merchantSources) == "table" and s.merchantSources[id]
    if type(source) == "table" then
        if source.unlimited == true then return true, Number(source.unitPrice), nil, "merchant" end
        if source.limited == true then return false, nil, nil, "merchant" end
    end
    local catalogue = A.VendorCatalog
    if catalogue then
        local hasStock = type(catalogue.Has) == "function" and catalogue.Has(id)
        if type(catalogue.Has) == "function" and hasStock ~= true then return false end
        local price, profile, provenance
        if type(catalogue.Get) == "function" then price, profile, provenance = catalogue.Get(id) end
        price = Number(price)
        if hasStock == true or (price and price > 0) then
            return true, price and price > 0 and price or nil, profile or catalogue.profile, provenance or catalogue.source
        end
    end
    return false
end
function A.HasUnlimitedVendor(id)
    local unlimited = A.VendorSource(id)
    return unlimited
end
function A.IsVendorItem(id)
    return A.HasUnlimitedVendor(id) and not (A.HasCheaperVendorBook and A.HasCheaperVendorBook(id))
end
function A.VendorPrice(id)
    local unlimited, price = A.VendorSource(id)
    return unlimited and price or nil
end
function A.VendorTerms(id)
    local price = A.VendorPrice(id)
    if price == nil then return end
    local s = FluxRestockSettings.Get()
    local source = type(s.merchantSources) == "table" and s.merchantSources[id]
    local numerator, denominator
    if type(source) == "table" and source.unlimited == true then
        numerator, denominator = source.priceNumerator, source.priceDenominator
    elseif type(source) == "table" and source.limited == true then return
    else
        local catalogue = A.VendorCatalog
        if catalogue and type(catalogue.GetTerms) == "function" then numerator, denominator = catalogue.GetTerms(id) end
    end
    numerator, denominator = Number(numerator), Number(denominator)
    if numerator and numerator % 1 == 0 and denominator and denominator > 0 and denominator % 1 == 0
        and numerator / denominator == price then return numerator, denominator end
end
function A.IsFoodWater(row)
    if row.tierKind == "food" or row.tierKind == "water" then return true end
    if not Number(row.itemID) then return false end
    local ic = _G.FluxItemClass
    -- Item class/subclass identifiers are the shared client item taxonomy.
    if ic and ic.GetClassID and ic.GetClassID(row.itemID) ~= 0 then return false end
    if ic and ic.GetSubClassID and ic.GetSubClassID(row.itemID) == 5 then return true end
    local classify = _G.FluxConsumableClassify
    local cls = classify and classify.Classify and classify.Classify(row.itemID)
    return cls and (cls.kind == "food" or cls.kind == "water") or false
end

local function Inventory() return _G.FluxRestock and _G.FluxRestock.Inv end
-- Targets and carried counts use remaining charges; auction quantities and
-- unit-price limits always use physical items. Keep the shared registry as
-- the owner of charge detection/capacity, including after a tier changes SKU.
function A.SetItemUnits(row)
    local registry = _G.FluxRestockItemRegistry
    local charged, capacity
    if registry then
        charged = registry.IsChargeItem and registry.IsChargeItem(row.itemID)
        if charged and registry.GetChargeInfo then
            local _
            _, capacity = registry.GetChargeInfo(row.itemID)
        elseif charged and registry.GetItemMaxCharges then capacity = registry.GetItemMaxCharges(row.itemID) end
    end
    row.isCharge = charged == true
    capacity = Number(capacity)
    -- An unresolved capacity must never become a physical stack-size guess.
    row.unitsPerItem = not row.isCharge and 1 or (capacity and capacity >= 1 and capacity % 1 == 0 and capacity or nil)
    return row
end

local setItemUnits, ordinaryCharge = A.SetItemUnits, rawget(ns, "RestockOrdinaryCharge")
local chargeInventory = ns.Flux.Inventory
local getBagGeneration = chargeInventory and chargeInventory.GetBagGeneration
local getSnapshotGeneration = chargeInventory and chargeInventory.GetSnapshotGeneration
local isReliable = chargeInventory and chargeInventory.IsReliable
local isBankOpen = chargeInventory and chargeInventory.IsBankOpen

local function ChargeGenerations()
    if ordinaryCharge and ordinaryCharge.CanReuse() and A.SetItemUnits == setItemUnits
        and A.ApplyPotionReplacements and A.ApplyPotionReplacements == ns.AuctionRestockApplyPotionReplacements
        and chargeInventory and ns.Flux.Inventory == chargeInventory and getBagGeneration
        and chargeInventory.GetBagGeneration == getBagGeneration and getSnapshotGeneration
        and chargeInventory.GetSnapshotGeneration == getSnapshotGeneration and isReliable
        and chargeInventory.IsReliable == isReliable and isBankOpen
        and chargeInventory.IsBankOpen == isBankOpen and isReliable() and not isBankOpen() then
        return getBagGeneration(), getSnapshotGeneration("bank"), getSnapshotGeneration("warband")
    end
end

local function RememberOrdinaryCharge(rows, row)
    if rows and row.isCharge == false and row.unitsPerItem == 1 and ordinaryCharge.IsResolved(row.itemID) then
        rows[row] = row.itemID
    end
end

-- Excess applies only to indivisible legacy listings of ordinary items.
-- Use the SKU's canonical charge fact even when a recipe row counts copies.
function A.AllowExcessStacks(item)
    if A.Settings().allowExcessStacks ~= true then return false end
    local legacy = A.legacy == true
    if type(A.IsLegacy) == "function" then legacy = A.IsLegacy() == true end
    if not legacy then return false end
    local id = type(item) == "table" and item.itemID or item
    if not Number(id) or id < 1 or id % 1 ~= 0 then return false end
    return A.SetItemUnits({ itemID = id }).isCharge ~= true
end
-- Stock math and remembered follow-up plans need trustworthy inventory. An
-- open mailbox blocks AH execution, not inspection of already settled bags.
function A.IsInventoryReliable()
    local inv = Inventory()
    local api = ns.Flux.Inventory
    if api and api.IsBagStorm and api.IsBagStorm() then return false end
    return inv and inv.IsReliable and inv.IsReliable() == true
end
function A.IsReliable()
    local api = ns.Flux.Inventory
    if api and api.IsMailboxOpen and api.IsMailboxOpen() then return false end
    return A.IsInventoryReliable()
end

local mailCounts = {}
local restockMailFacts = {}
function A.NoteRestockMailbox(counts, receipts)
    local ids = {}
    for id in pairs(restockMailFacts) do ids[id] = true end
    for id in pairs(receipts or {}) do ids[id] = true end
    local api = ns.Flux.Inventory
    for id in pairs(ids) do
        local provider = api and api.Mail and api.Mail.GetCount and Number(api.Mail.GetCount(id))
        restockMailFacts[id] = { count = math.max(0, Number(counts[id]) or 0), providerCount = provider or mailCounts[id] or 0 }
    end
end
function A.RefreshMailFacts()
    mailCounts = {}
    local api = ns.Flux.Inventory
    local char = api and api.Store and api.Store.GetCurrentCharacter and api.Store.GetCurrentCharacter()
    local now = time and time() or 0
    for _, item in pairs(char and char.mail or {}) do
        local id, count = Number(item.itemID), Number(item.itemCount or item.count)
        local expiry = Number(item.expirationTime)
        if id and count and (not expiry or expiry > now) then mailCounts[id] = (mailCounts[id] or 0) + count end
    end
end
function A.MailUnits(row)
    local api = ns.Flux.Inventory
    local snap = api and api.snapshots and api.snapshots.mail
    local count
    if api and api.Mail and api.Mail.GetCount and (not snap or (snap.generation or 0) > 0) then count = Number(api.Mail.GetCount(row.itemID)) end
    count = count or mailCounts[row.itemID] or 0
    local observed = restockMailFacts[row.itemID]
    if observed ~= nil then
        if count == observed.count or count ~= observed.providerCount then restockMailFacts[row.itemID] = nil
        else count = observed.count end
    end
    return count * (row.isCharge and (Number(row.unitsPerItem) or 0) or 1)
end
function A.PredictedMailUnits(row)
    local api = ns.Flux.Inventory
    local mail = api and api.Builtin and api.Builtin.Mail
    local count = mail and mail.GetPredictedCount and Number(mail.GetPredictedCount(row.itemID)) or 0
    return (count or 0) * (row.isCharge and (Number(row.unitsPerItem) or 0) or 1)
end

local function Carried(row, physical)
    local inv = Inventory()
    -- Preserve the original nil/false chain without evaluating row fields.
    local value = inv and inv.GetLiveCount
    if value then
        -- Select the second getter before either row field can call outward.
        local getLiveCount = inv.GetLiveCount
        local itemID = row.itemID
        local charges = row.isCharge == true and not physical
        if carriedRestockQuery and getLiveCount == carriedRestockGetter then
            value = carriedRestockQuery(itemID, charges)
        else
            value = getLiveCount(itemID, {
                bags = true, bank = false, warband = false, equipped = false, charges = charges,
            })
        end
    end
    return Number(value)
end

local function ItemTotal(row)
    local units = Number(row.unitsPerItem)
    if not units or units < 1 then return nil end
    local physical = Carried(row, true)
    if physical then return physical + (A.MailUnits(row) - A.PredictedMailUnits(row)) / units end
end

function A.Pending(row, have, observeOnly)
    local pending = A.Settings().pending
    local p = pending[row.itemID]
    if type(p) ~= "table" then return 0 end
    -- Old/failed attempts were formerly persisted as though already purchased.
    -- Only an active submission or an acknowledged receipt can reserve stock.
    local transaction = A.transaction
    if p.accepted ~= true and (observeOnly or not (transaction and transaction.itemID == row.itemID)) then
        local accepted = Number(p.acceptedUnits) or 0
        if observeOnly then
            p = { units = accepted, bagCount = p.bagCount, totalCount = p.totalCount,
                itemCount = p.itemCount, unitScale = p.unitScale }
        else
            if accepted <= 0 then pending[row.itemID] = nil; return 0 end
            p.units, p.accepted = accepted, true
        end
    end
    local units = Number(p.units) or 0
    local storedScale, currentScale = Number(p.unitScale), Number(row.unitsPerItem)
    local scale = storedScale and storedScale >= 1 and currentScale and currentScale >= 1
        and currentScale / storedScale or 1
    -- Inbox and bags may publish a take separately while mail is open. That
    -- temporary double count cannot prove a different purchase has arrived.
    -- The owned mailbox worker supplies exact take/empty-inbox proof itself.
    if have and A.IsReliable() then
        local total = have + A.MailUnits(row) - A.PredictedMailUnits(row)
        if storedScale and currentScale and currentScale >= 1 then total = total / scale end
        local previous = Number(p.totalCount) or Number(p.bagCount) or total
        local itemTotal = Number(p.itemCount) and ItemTotal(row)
        local arrived = Number(p.itemCount) and (itemTotal and (itemTotal - p.itemCount) * (storedScale or currentScale or 1) or 0)
            or total - previous
        -- Credit arrival once across bags + inbox. Taking old mail into bags
        -- moves that stock without consuming a different in-transit purchase.
        -- New reservations track physical arrivals, so using an owned charge
        -- or changing between a use target and recipe input cannot alter them.
        units = math.max(0, units - math.max(0, arrived))
        if not observeOnly then
            p.units, p.bagCount, p.totalCount = units, have / scale, total
            if itemTotal then p.itemCount = itemTotal end
            if units == 0 then pending[row.itemID] = nil end
        end
    end
    -- Keep the saved basis immutable while a transaction can still fail and
    -- release its original units. Callers receive their current row's units.
    return units * scale
end

-- Read the owner ledger without modifying a receipt while a plan is previewed.
function A.GetPolicyCoverage(entry, units, itemID)
    if not A.IsInventoryReliable() then return nil end
    local row = A.SetItemUnits({ itemID = itemID, bagCount = entry.bagCount })
    if not row or not row.unitsPerItem then return nil end
    local have = Carried(row)
    if not have then return nil end
    local quantity = A.MailUnits(row) + math.max(0, A.Pending(row, have, true) - A.PredictedMailUnits(row))
    if units == "item" and row.unitsPerItem then quantity = math.floor(quantity / row.unitsPerItem) end
    return quantity
end

function A.Need(row)
    if not row or not A.IsInventoryReliable() then return nil end
    local have = Carried(row)
    if not have then return nil end
    local mail = A.MailUnits(row)
    local pending = mail + math.max(0, A.Pending(row, have) - A.PredictedMailUnits(row))
    row.bagCount, row.pending, row.mailCount = have, pending, mail
    local units = Number(row.unitsPerItem)
    if not units or units < 1 then return nil end
    local bank = row.countBank and (Number(row.bankCount) or 0) or 0
    if row.craftParents then bank = math.min(bank, row.baseTarget or 0) end
    bank = math.max(bank, Number(row.craftBankCount) or 0)
    local missing = row.isTierRestock and 0 or ((Number(row.target) or 0) - have - bank - pending)
    local policy = _G.Flux and _G.Flux.RestockPolicy
    if policy and policy.IsPlannerRegistered() and not row.isTierRestock and not row.craftParents then
        local demand = policy.DemandForEntry(row, pending)
        if demand then
            missing = demand.uncovered
            row.policyCoverage = demand.covered
        end
    end
    local tiers = _G.FluxRestockTiers
    for _, source in ipairs(row.tiers or {}) do
        -- Ordinary tiers aggregate qualifying physical items. A charged target
        -- instead needs remaining uses of this SKU; other tier copies provide
        -- no reliable information about their remaining charge counts.
        local count, stored
        if row.isCharge then
            count = have
            if source.countBank then
                local inv = Inventory()
                local owner = inv and inv.Bank
                stored = owner and owner.GetCount and Number(owner.GetCount(row.itemID, { charges = true }))
                if not stored then return nil end
                row.bankCount = stored
            end
        else
            count = tiers and tiers.GetTierCount and Number(tiers.GetTierCount(source.tierKind, nil, row.auctionTier))
            stored = source.countBank and tiers and tiers.GetBankCountForKind and Number(tiers.GetBankCountForKind(source.tierKind, nil, row.auctionTier, row.auctionTier ~= nil)) or 0
            if row.isTierRestock and row.auctionTier and source.countBank then row.bankCount = stored or 0 end
        end
        if not count then return nil end
        local tierMissing = (Number(source.target) or 0) - count - (stored or 0) - pending
        if policy and policy.IsPlannerRegistered() then
            local entry = {}
            for key, value in pairs(source) do entry[key] = value end
            entry.itemID, entry.bagCount, entry.bankCount = row.itemID, count, stored or 0
            local exactOwnsPending = entry.policyExactItems and entry.policyExactItems[row.itemID]
            local demand = policy.DemandForEntry(entry, exactOwnsPending and 0 or pending)
            if demand then
                tierMissing = demand.uncovered
                row.policyCoverage = math.max(row.policyCoverage or 0, demand.covered)
            end
        end
        if policy and policy.IsPlannerRegistered() and source.policyExactItems
            and source.policyExactItems[row.itemID] and not row.isTierRestock then
            missing = math.max(0, missing) + math.max(0, tierMissing)
        else
            missing = math.max(missing, tierMissing)
        end
        if row.isTierRestock then row.bagCount = count end
    end
    return math.max(0, math.ceil(missing / units))
end

function A.Reserve(row, quantity)
    local have = Carried(row)
    local units = quantity * row.unitsPerItem
    local pending = A.Settings().pending
    local prior = A.Pending(row, have)
    pending[row.itemID] = { units = prior + units, bagCount = have or row.bagCount or 0,
        totalCount = (have or row.bagCount or 0) + A.MailUnits(row) - A.PredictedMailUnits(row),
        itemCount = ItemTotal(row), unitScale = row.unitsPerItem, accepted = false, acceptedUnits = prior }
    return units
end
function A.AcceptReservation(transaction)
    restockMailFacts[transaction.itemID] = nil
    local record = A.Settings().pending[transaction.itemID]
    if record then record.accepted, record.acceptedUnits = true, record.units end
    local policy = _G.Flux and _G.Flux.RestockPolicy
    if policy then policy.NotifyChanged("inventory") end
end

function A.Release(id, units)
    local pending = A.Settings().pending
    local p = pending[id]
    if type(p) ~= "table" then return end
    p.units = math.max(0, (Number(p.units) or 0) - units)
    if p.units > 0 and (Number(p.acceptedUnits) or 0) > 0 then p.accepted = true; p.acceptedUnits = math.min(p.acceptedUnits, p.units) end
    if p.units == 0 then pending[id] = nil end
    local policy = _G.Flux and _G.Flux.RestockPolicy
    if policy then policy.NotifyChanged("inventory") end
end

local presetOrder = { healPotion = 1, manaPotion = 2, bandage = 3 }
local function RowOrder(row)
    local order = presetOrder[row.tierKind]
    -- A manual target can share its item with a preset. Keep that merged row
    -- in the preset group, including after an accepted tier replacement.
    local tiers = row.tiers
    if tiers then
        for _, tier in ipairs(tiers) do
            local rank = presetOrder[tier.tierKind]
            if rank and (not order or rank < order) then order = rank end
        end
    end
    return order or (row.restockSource == "spellReagent" and 4)
        or (row.restockSource == "consumable" and 5) or 6
end
function A.RowLess(a, b)
    local ao, bo = RowOrder(a), RowOrder(b)
    if ao ~= bo then return ao < bo end
    local an, bn = a.name or "", b.name or ""
    if an == bn then return a.itemID < b.itemID end
    return an < bn
end

local vendorTargetList = FluxVendorAuto and FluxVendorAuto.GetRestockTargetItems
local isFoodWater, auctionSettings = A.IsFoodWater, A.Settings

local function BuildRows(list)
    if A.CapturePotionTargets then A.CapturePotionTargets(list) end
    local rows, seen = {}, {}
    local bags, bank, warband = ChargeGenerations()
    local ordinaryRows = bags ~= nil and {}
    for _, entry in ipairs(list) do
        local id = Number(entry.itemID)
        if id and id > 0 and not entry.isTierRestock and not seen[id] and not A.IsFoodWater(entry) then
            seen[id] = true
            local row = {}
            for k, v in pairs(entry) do row[k] = v end
            A.SetItemUnits(row)
            RememberOrdinaryCharge(ordinaryRows, row)
            row.maxPrice = A.GetMaxPrice(id)
            rows[#rows + 1] = row
            seen[id] = row
        end
    end
    -- Generic tier targets buy their existing remembered non-conjured reference.
    -- Count every qualifying tier item through Tiers; never reset its threshold.
    local best = _G.FluxConsumableBest
    for _, entry in ipairs(list) do
        if entry.isTierRestock and (Number(entry.target) or 0) >= 0 and not A.IsFoodWater(entry) then
            local ref = best and best.GetBestRef and best.GetBestRef(entry.tierKind)
            local id = ref and Number(ref.itemID)
            if id and id > 0 and not ref.isConjured then
                local row = seen[id]
                if not row then
                    row = {}
                    for k, v in pairs(entry) do row[k] = v end
                    row.itemID = id
                    A.SetItemUnits(row)
                    RememberOrdinaryCharge(ordinaryRows, row)
                    row.name = FluxItemClass and FluxItemClass.GetName(id) or entry.name
                    row.texture = FluxItemClass and FluxItemClass.GetIcon and FluxItemClass.GetIcon(id) or entry.texture
                    row.maxPrice = A.GetMaxPrice(id)
                    rows[#rows + 1], seen[id] = row, row
                end
                row.tiers = row.tiers or {}
                row.tiers[#row.tiers + 1] = entry
            end
        end
    end
    if A.ApplyPotionReplacements then rows = A.ApplyPotionReplacements(rows, true) end
    if ordinaryRows then
        local finalBags, finalBank, finalWarband = ChargeGenerations()
        if finalBags ~= bags or finalBank ~= bank or finalWarband ~= warband then ordinaryRows = nil end
    end
    return rows, ordinaryRows
end

function A.GetRows(refresh)
    if not refresh then return A.rows end
    A.RefreshMailFacts()
    local getTargets = FluxVendorAuto.GetRestockTargetItems
    local options = { forOptionsPanel = true }
    local vendorCraft = ns.VendorCraftBaseRows
    if getTargets == vendorTargetList and A.IsFoodWater == isFoodWater and A.Settings == auctionSettings
        and A.CapturePotionTargets and A.CapturePotionTargets == ns.AuctionRestockCapturePotionTargets
        and vendorCraft and vendorCraft.owner == A and vendorCraft.canBorrow()
        and A.HasCraftPlans and not A.HasCraftPlans() and not A.transaction then
        -- Food and water tiers are discarded below. Saved vendor plans can still read their counts.
        local saved = auctionSettings().vendorCraftPlans
        if not saved or (type(saved) == "table" and not next(saved)) then options.skipAuctionFoodWaterBank = true end
    end
    local list = {}
    for _, entry in ipairs(getTargets(options) or {}) do
        if entry.craftTarget ~= nil then
            local base = Number(entry.craftBaseTarget) or 0
            -- The shared list includes temporary vendor-plan ingredients.
            -- AH ingredients come exclusively from the chosen AH material plan.
            if entry.restockSource ~= "craftMaterial" or base > 0 then
                local copy = {}; for key, value in pairs(entry) do copy[key] = value end
                copy.target = base
                list[#list + 1] = copy
            end
        else list[#list + 1] = entry end
    end
    local rows, ordinaryRows
    local withBagTooltips = ns.WithAuctionRestockBagTooltips
    if withBagTooltips then rows, ordinaryRows = withBagTooltips(BuildRows, list)
    else rows, ordinaryRows = BuildRows(list) end
    -- Compute stock after all tier sources/replacements are assembled. Earlier
    -- counts would be discarded here and could reconcile the same receipt twice.
    -- Only reuse resolved ordinary units on the same row and item. Replacement
    -- SKUs, charge capacity and unsettled inventory still get the fresh read.
    for _, row in ipairs(rows) do
        if not ordinaryRows or ordinaryRows[row] ~= row.itemID or row.isCharge ~= false or row.unitsPerItem ~= 1 then
            A.SetItemUnits(row)
        end
        row.need = A.Need(row)
    end
    -- Keep hidden vendor targets available to the native price-only probe.
    -- A fresh discount may admit them; remembered/historical prices may not.
    local visible, hidden = {}, {}
    for _, row in ipairs(rows) do
        if A.IsVendorItem(row.itemID) then hidden[#hidden + 1] = row
        else visible[#visible + 1] = row end
    end
    A.vendorScanRows, rows = hidden, visible
    if A.MaterialRows then A.MaterialRows(rows) end
    table.sort(rows, A.RowLess)
    A.rows = rows
    return rows
end

function A.GetVendorScanRows() return A.vendorScanRows end

function A.FindRow(id, refresh)
    for _, row in ipairs(A.GetRows(refresh)) do
        if row.itemID == id then return row end
    end
end

-- Only compare buyouts. Integer multiplication preserves fractional copper/unit.
function A.SelectStack(offers, need, cap, excess)
    local best
    for _, offer in ipairs(offers) do
        local q, cost = Number(offer.quantity), Number(offer.total)
        if q and q > 0 and q % 1 == 0 and cost and cost > 0 and cost % 1 == 0
            and not offer.owned and cost <= cap * q and (q <= need or excess) then
            local rank = q == need and 0 or q < need and 1 or 2
            local better = not best or rank < best.rank
            if best and rank == best.rank then
                if rank == 2 and q ~= best.quantity then better = q < best.quantity
                elseif cost * best.quantity ~= best.total * q then better = cost * best.quantity < best.total * q
                else better = cost < best.total end
            end
            if better then
                best = {}
                for k, v in pairs(offer) do best[k] = v end
                best.rank = rank
            end
        end
    end
    return best
end

local function CommodityUnitPriceLess(a, b)
    return (Number(a.unitPrice) or math.huge) < (Number(b.unitPrice) or math.huge)
end

function A.CommodityOffer(offers, need, cap, minimum, budget)
    local sorted = {}
    for _, offer in ipairs(offers) do sorted[#sorted + 1] = offer end
    table.sort(sorted, CommodityUnitPriceLess)
    local quantity, total, highest = 0, 0, 0
    for _, offer in ipairs(sorted) do
        local price, available = Number(offer.unitPrice), Number(offer.quantity)
        local own = Number(offer.numOwnerItems) or 0
        if price and price > 0 and price <= cap and available and available > own
            and not offer.containsAccountItem then
            local n = math.min(need - quantity, math.floor(available - own))
            if budget then n = math.min(n, math.floor((budget - total) / price)) end
            if n > 0 then quantity, total, highest = quantity + n, total + n * price, price end
            if quantity >= need or budget and budget - total < price then break end
        end
    end
    if quantity >= (minimum or 1) then
        return { quantity = quantity, total = total, unitPrice = highest, commodity = true }
    end
end
