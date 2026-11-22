-- Exercise the real target list, auction need, vendor buyer, and bank entry
-- points through the existing isolated FluxUI auction/source fixture.
local export = setmetatable({ FLUX_AH_SOURCES_FIXTURE_EXPORT = true }, { __index = _G })
local boot = assert(loadfile("tests/auction_restock_sources.lua", "t", export))()
local checks = 0
local function equals(value, expected, reason)
    checks = checks + 1
    assert(value == expected, reason .. " (expected " .. tostring(expected) .. ", got " .. tostring(value) .. ")")
end

local A, st, env, load = boot(false, true, true)
env.Flux = st.flux
env.UnitGUID = function(unit)
    if unit == "player" then return "Player-1-Fixture" end
    if unit == "npc" then return "Creature-1-Fixture" end
end
env.FluxVendorAuto.GetRestockTargetForItem = function() return 40 end
st.settings.restockItems[17001] = { targetQuantity = 40, bankRestock = true }
st.bags[17001], st.bankItems[17001] = 12, 40
load("Inventory/Restock/Core/FluxRestockPolicy.lua")
local policy = st.flux.RestockPolicy
assert(policy and st.flux == env.Flux)
load("Inventory/Restock/Core/FluxRestockList.lua")
env.FluxRestockItemRegistry.IsChargeItem = function() return false end

local requests, accepted, busy = 0, {}, false
local provider = {
    GetCoverage = function(rule)
        assert(rule.id == "item:17001")
        return accepted
    end,
    Request = function(rule, action)
        if action ~= "view" then
            requests = requests + 1
            accepted[#accepted + 1] = { id = "craft:" .. requests, quantity = rule.uncovered, units = "item" }
        end
        return true
    end,
    IsWorkflowBusy = function() return busy end,
}

equals(policy.version, 1, "version marker")
equals(policy.GetMode(), "normal", "default activity mode")
equals(policy.AllowsPassive(), true, "legacy FluxUI without a planner retains automation")
equals(policy.RegisterPlanner(provider), true, "capability checked registration")
equals(policy.AllowsPassive(), false, "Normal has no managed passive ordering")
equals(#policy.GetDemands(), 0, "Normal never yields passive requests")
equals(policy.IncludesMode({ all = true }, "normal", false), true, "all modes includes Normal requirements")
equals(policy.IncludesMode({ openworld = true }, "raid"), true, "raid inherits open-world rules")
equals(policy.IncludesMode({ raid = true }, "openworld"), false, "open-world excludes raid-only rules")
equals(policy.IncludesMode(nil, "raid", false), false, "inactive legacy preset stays inactive")
equals(policy.IncludesMode(nil, "raid", true), true, "selected legacy preset migrates as common")

accepted = {
    { id = "incoming:1", quantity = 8 }, { id = "incoming:1", quantity = 8 },
    { id = "bank:2", quantity = 10, kind = "bank" },
    { id = "another-target", quantity = 9, demandId = "item:90" },
    { id = "wrong-unit", quantity = 24, units = "charge" },
}
policy.NotifyCoverageChanged()
local id = "item:17001"
local demand = assert(policy.GetDemand(id))
equals(demand.uncovered, 10, "shared target example")
equals(demand.ready, 12, "bank reservation is not physical bag stock")
equals(demand.covered, 18, "distinct accepted allocations only")
equals(demand.bankRestock, true, "preserve owner bank flag")
equals(env.FluxRestockList.EntryNeed(env.FluxVendorAuto.GetRestockTargetItems({ policyOnly = true })[1]), 10,
    "vendor reads the same uncovered quantity")
local row = A.SetItemUnits({ itemID = 17001, target = 40, bankCount = 40 })
equals(A.Need(row), 10, "auction reads the same uncovered quantity")

load("Inventory/Restock/Bank/FluxBankRestockRules.lua")
local create = env.CreateFrame
env.CreateFrame = function(...)
    local frame = create(...)
    frame.UnregisterAllEvents = function() end
    return frame
end
env.FluxBankRestockMoveExec = { Start = function(session, options)
    st.bankTasks, st.bankMoveOptions = session.tasks, options
    return true
end }
load("Inventory/Restock/Bank/FluxBankRestock.lua")
local bank = env.FluxBankRestock
equals(bank.GetTooltipItems()[1].needed, 10, "bank reads the same uncovered quantity")
equals(bank.GetTooltipItems()[1].pull, 10, "withdrawal is capped by the shared uncovered quantity")
equals(bank.Start(false), false, "managed Normal blocks a new passive bank restock")
equals(bank.Start(true), true, "manual bank restock is allowed in Normal")
equals(st.bankTasks[1].remaining, 10, "real owner scopes its bank mover task")
bank.Stop()

equals(policy.Request(id, "restock", { manual = false }), false, "passive request fails closed in Normal")
equals(policy.Request(id, "restock", { manual = true, source = "merchant" }), true, "manual request accepted")
equals(policy.Request(id, "craft", { manual = true, source = "bank" }), false, "same accepted coverage suppresses repeat")
equals(policy.Request(id, "restock", { manual = true, source = "auction" }), false, "same cross-view demand suppresses repeat")
equals(requests, 1, "exactly one accepted restock")
equals(policy.GetDemand(id).uncovered, 0, "synchronous coverage refresh after acceptance")

env.FluxVendorAuto.SetRestockItemFlag(17001, "countBank", true)
equals(policy.GetDemand(id).bank, 40, "bags-plus-bank owner scope remains intact")
equals(policy.GetDemand(id).covered, 18, "bank transfer within the counted scope is not counted twice")
env.FluxVendorAuto.SetRestockItemFlag(17001, "countBank", false)
accepted = {}
policy.NotifyCoverageChanged()
busy = true
policy.SetMode("raid")
policy.SetManaged(true)
equals(policy.AllowsPassive(), true, "configured activity mode enables passive eligibility")
policy.SetTrigger(id, 10)
equals(#policy.GetDemands(), 0, "threshold hysteresis defers until below trigger")
policy.SetTrigger(id, 13)
equals(#policy.GetDemands(), 1, "low-stock rule reaches its full refill target")
equals(policy.GetDemand(id).uncovered, 28, "trigger does not shrink refill target")
busy = true
equals(policy.Request(id, "craft", { manual = true }), false, "another workflow holds the coordinator")
busy = false
policy.NotifyChanged("inventory")
st.drain()
equals(requests, 2, "opted-in raid mode creates one new managed order")
policy.NotifyChanged("inventory")
st.drain()
equals(requests, 2, "repeated passive events do not order accepted demand twice")
policy.SetManaged(false)

local records = {
    { itemID = 17001, target = 20, bagCount = 12, bankCount = 7, countBank = true },
    { isTierRestock = true, tierKind = "bandage", target = 40, bagCount = 26, bankCount = 20, countBank = true },
}
policy.ApplyTierOverlap(records, function(kind, item) return kind == "bandage" and item == 17001 end)
equals(records[2].policyTierOffset, 12, "qualified exact stock is reserved before a broader tier")
equals(records[2].policyTierBankOffset, 7, "counted bank stock is allocated to the exact target only once")

do
    local previousTiers, previousBest = env.FluxRestockTiers, env.FluxConsumableBest
    local previousObservation, previousCoverage = A.GetPolicyCoverage, provider.GetCoverage
    local listing, preferred = 17001, 17002
    local observedQuantity, observedItem
    env.FluxRestockTiers = {
        GetTarget = function() return 20 end,
        GetCountBankFlag = function() return false end,
        ItemMatchesRestockKind = function(kind, itemID)
            return kind == "bandage" and (itemID == listing or itemID == preferred)
        end,
    }
    env.FluxConsumableBest = { GetBestRef = function() return { itemID = preferred } end }
    provider.GetCoverage = function(_, quantity, itemID)
        observedQuantity, observedItem = quantity, itemID
        return {}
    end
    local entry = { isTierRestock = true, tierKind = "bandage", itemID = listing, bagCount = 0 }
    local rule = policy.DemandForEntry(entry, 4)
    equals(rule.itemID, preferred, "the tier keeps its preferred item for planning")
    equals(observedQuantity, 4, "the explicit auction pending amount stays unchanged")
    equals(observedItem, listing, "the explicit auction pending amount belongs to the listed item")

    A.GetPolicyCoverage = function(_, units, itemID)
        equals(units, "item", "automatic tier pending lookup keeps its unit")
        equals(itemID, preferred, "automatic owner pending lookup queries the preferred tier item")
        return 2
    end
    policy.DemandForEntry(entry)
    equals(observedQuantity, 2, "automatic lookup forwards the current pending amount")
    equals(observedItem, preferred, "automatic lookup forwards the queried item")

    provider.GetCoverage, A.GetPolicyCoverage = previousCoverage, previousObservation
    env.FluxRestockTiers, env.FluxConsumableBest = previousTiers, previousBest
end

local estimateItem = 9917001
st.settings.merchantSources = st.settings.merchantSources or {}
st.settings.merchantSources[estimateItem] = {
    unlimited = true, unitPrice = 1.2, priceNumerator = 6, priceDenominator = 5,
}
local estimate = assert(policy.GetVendorPriceEstimate(estimateItem))
equals(estimate.unitPrice, 1.2, "estimate preserves unit cost from typed merchant memory")
equals(estimate.bundlePrice, 6, "estimate preserves the observed bundle price")
equals(estimate.bundleSize, 5, "estimate preserves the observed bundle quantity")
equals(estimate.provenance, "merchant", "estimate preserves typed owner provenance")
equals(estimate.estimate, true, "cached vendor amount remains an estimate")
equals(estimate.qualified, nil, "cached vendor estimate is not an executable offer")
equals(#policy.GetAcquisitions(estimateItem, "Player-1-Fixture"), 0, "cached vendor amount cannot authorize a buy")
st.settings.merchantSources[estimateItem].priceDenominator = 8
equals(policy.GetVendorPriceEstimate(estimateItem), nil, "conflicting bundle and unit values remain unknown")
st.settings.merchantSources[estimateItem] = { limited = true, unitPrice = 1.2 }
equals(policy.GetVendorPriceEstimate(estimateItem), nil, "a limited merchant memory is not an unlimited estimate")
st.settings.merchantSources[estimateItem] = nil
local catalogue = A.VendorCatalog
A.VendorCatalog = {
    Has = function(itemID) return itemID == estimateItem end,
    Get = function() return 1.5, "fixture-profile", "fixture-catalogue" end,
    GetTerms = function() return 3, 2 end,
}
estimate = assert(policy.GetVendorPriceEstimate(estimateItem))
equals(estimate.unitPrice, 1.5, "typed catalogue contributes a vendor estimate without a merchant")
equals(estimate.profile, "fixture-profile", "estimate retains owner catalogue profile")
equals(estimate.provenance, "fixture-catalogue", "estimate identifies catalogue provenance")
A.VendorCatalog = catalogue

local bankOffer = policy.GetAcquisitions(17001, "Player-1-Fixture")[1]
equals(bankOffer.kind, "bank", "live character bank produces a qualified offer")
equals(#policy.GetAcquisitions(17001, "Player-Other"), 0, "offers cannot be executed by another actor")
local valid = true
local issued, _, quantity = policy.ExecuteAcquisition(bankOffer, 6, function(_, qty) return valid and qty <= 6 end)
equals(issued, true, "qualified bank acquisition uses owner mover")
equals(quantity, 6, "bank action carries exact accepted quantity")
equals(st.bankTasks[1].remaining, 6, "bank plan leaves all other target tasks untouched")
equals(st.bankMoveOptions.validate({ itemID = 17001 }, 4), true, "bank mover revalidates every scoped step")
valid = false
equals(st.bankMoveOptions.validate({ itemID = 17001 }, 4), false, "stale plan blocks later bank steps")
bank.Stop()

env.MerchantFrame = { IsShown = function() return true end }
env.GetMerchantNumItems = function() return 1 end
env.GetMerchantItemID = function() return 17001 end
env.GetMerchantItemLink = function() return "item:17001" end
env.GetMerchantItemMaxStack = function() return 20 end
local bundlePrice, bundleSize, stock = 6, 5, 30
env.GetMerchantItemInfo = function() return "Material", 17001, bundlePrice, bundleSize, stock, true, true, false end
env.GetMerchantItemCostInfo = function() return 0 end
env.IsShiftKeyDown = function() return false end
env.FluxRestock.Inv.NotifyAutomationPulse = function() end
local purchased = 0
env.BuyMerchantItem = function(slot, qty) assert(slot == 1); purchased = purchased + qty end
local merchantEvents
local createForMerchant = env.CreateFrame
env.CreateFrame = function(...)
    local frame = createForMerchant(...)
    local register = frame.RegisterEvent
    function frame:RegisterEvent(event, ...)
        if event == "MERCHANT_SHOW" then merchantEvents = self end
        return register(self, event, ...)
    end
    return frame
end
load("Inventory/Restock/Vendor/FluxVendorBuy.lua")
env.CreateFrame = createForMerchant
env.FluxVendorAuto.GetMerchantItemIndex(false)
st.drain()
local vendorOffer = policy.GetAcquisitions(17001, "Player-1-Fixture")[1]
equals(vendorOffer.kind, "vendor", "qualified merchant offer comes from the live owner index")
equals(vendorOffer.bundleSize, 5, "merchant bundle unit preserved")
equals(vendorOffer.bundlePrice, 6, "merchant purchase bundle price preserved")
equals(vendorOffer.availableUnits, 30, "finite merchant availability preserved")
bundlePrice = 7
equals(policy.ExecuteAcquisition(vendorOffer, 25, function() return true end), false, "changed offer blocks purchase")
equals(purchased, 0, "changed terms issue no merchant command")
bundlePrice = 6
local bought, _, units = policy.ExecuteAcquisition(vendorOffer, 25, function() return true end)
equals(bought, true, "valid purchase calls the native owner")
equals(units, 20, "current stack limit caps this purchase action")
equals(purchased, 20, "native action receives physical quantities")
stock = 2
equals(policy.ExecuteAcquisition(vendorOffer, 5, function() return true end), false, "finite supply must cover the accepted bundle")

local merchantShown, shifted = true, true
env.MerchantFrame.IsShown = function() return merchantShown end
env.IsShiftKeyDown = function() return shifted end
env.FluxVendorAuto.EnsureSettings = function() end
stock = 30
merchantEvents:Fire("OnEvent", "MERCHANT_SHOW")
shifted = false
env.FluxVendorAuto.GetMerchantItemIndex(false)
st.advance(0.5)
equals(policy.AllowsAutomaticVendorPurchase and policy.AllowsAutomaticVendorPurchase() == false, true,
    "opening with Shift vetoes automatic purchase for the entire merchant visit")
local shiftedOffer = assert(policy.GetAcquisitions(17001, "Player-1-Fixture")[1])
equals(shiftedOffer.kind, "vendor", "Shift-open preserves the live merchant offer")
equals(policy.ExecuteAcquisition(shiftedOffer, 5, function() return true end), true,
    "Shift-open permits an explicit qualified purchase")
equals(purchased, 25, "the explicit purchase still reaches the native owner")
merchantShown = false
merchantEvents:Fire("OnEvent", "MERCHANT_CLOSED")
merchantShown = true
merchantEvents:Fire("OnEvent", "MERCHANT_SHOW")
equals(policy.AllowsAutomaticVendorPurchase(), false, "the merchant Auto Restock toggle applies to companion orders")
st.settings.autoRestock = true
equals(policy.AllowsAutomaticVendorPurchase(), true, "a normal merchant visit resets the Shift veto")
st.settings.autoRestock = false

do
    local vendor = env.FluxVendorAuto
    local previousBags, previousCoverage = st.bags[17001], accepted
    st.bags[17001], accepted = 35, {}
    local job = {id = 8, planRevision = "vendor", status = "queued"}
    local material = {job = job, id = 1, itemID = 17001, quantity = 10, kind = "vendor"}
    local pending = {job = job, id = 2, itemID = 17002, quantity = 3, kind = "vendor", pending = true}
    provider.GetRequirements = function() return {material, pending} end
    provider.GetVendorStage = function() return {canBuy = true} end
    local passes = 0
    provider.BuyVendorRequirements = function(automatic)
        assert(automatic == false)
        equals(vendor.IsAuctionFollowupBusy(), false, "companion purchase starts after the regular merchant work settles")
        passes = passes + 1
        return true
    end
    policy.NotifyCoverageChanged()
    vendor.GetMerchantItemIndex(false)
    st.advance(0.5)
    local temporary = vendor.GetRestockVendorItems(vendor.GetMerchantItemIndex(false))
    local rows = {}
    for _, entry in ipairs(temporary) do rows[entry.itemID] = entry end
    equals(rows[17001].target, 40, "the saved target is still the ordinary target")
    equals(rows[17001].plannerVendorNeed, 10, "queued materials share the same merchant row")
    equals(rows[17002].plannerVendorPending, 3, "a pending receipt remains on the merchant list")
    equals(st.settings.restockItems[17002], nil, "pending craft materials are never saved as a preset")
    local beforeClick = purchased
    equals(vendor.DoRestockManual(), true, "one regular restock press requests both sources of work")
    st.advance(0.5)
    equals(purchased, beforeClick + 5, "ordinary restock starts its five units immediately")
    equals(passes, 0, "the companion does not count an unconfirmed regular buy")
    st.bags[17001] = 40
    merchantEvents:Fire("OnEvent", "BAG_UPDATE_DELAYED")
    st.advance(0.5)
    equals(passes, 1, "the bag update starts the same click's companion batch")
    merchantEvents:Fire("OnEvent", "BAG_UPDATE_DELAYED")
    st.advance(0.5)
    equals(passes, 1, "another update does not resubmit the batch")
    provider.GetRequirements, provider.GetVendorStage, provider.BuyVendorRequirements = nil, nil, nil
    st.bags[17001], accepted = previousBags, previousCoverage
    policy.NotifyCoverageChanged()
end

do
    local job = {id = 11, planRevision = "bank", status = "queued"}
    local together = {job = job, id = 1, itemID = 17001, quantity = 7, kind = "bank",
        groupKey = "two-orders", groupCount = 2}
    provider.GetRequirements = function() return {together} end
    local acquired = 0
    provider.AcquireRequirement = function(surface, selection)
        assert(surface == "bank" and selection.groupKey == "replacement-order")
        acquired = selection.quantity
        return true
    end
    local seen = assert(policy.GetAcquisitionRequirements("bank")[1])
    equals(seen.quantity, 7, "bank policy projects the full material group")
    equals(seen.groupCount, 2, "bank policy carries the number of covered orders")
    together.groupKey = "replacement-order"
    equals(policy.AcquireRequirement("bank", seen), false, "same total with changed orders invalidates a stale click")
    equals(acquired, 0, "a stale group cannot withdraw stock")
    equals(policy.AcquireRequirement("bank", policy.GetAcquisitionRequirements("bank")[1]), true,
        "the current grouped withdrawal uses the existing bank route")
    equals(acquired, 7, "the policy forwards the full bank quantity")
    provider.GetRequirements, provider.AcquireRequirement = nil, nil
end

load("ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua")
local owner = env.FluxNCConsumables
env._FluxUI_CharSavedVars.consumables = {
    activePreset = "default",
    presets = {
        default = { items = { 17001 }, restockTargets = { ["17001"] = 30 } },
        world = { items = { 17001, 17002 }, restockTargets = { [17001] = 45, [17002] = 12 },
            restockMembership = { openworld = true } },
        raid = { items = { 17001, 17003 }, restockTargets = { [17001] = 50, [17003] = 6 },
            restockMembership = { raid = true } },
        disabled = { items = { 17004 }, restockTargets = { [17004] = 100 },
            restockMembership = { all = true }, restockEnabled = false },
    },
}
policy.SetMode("normal")
local effective = owner.GetEffectiveRestockTargets()
equals(effective[17001], 30, "old selected preset migrates as a common target")
equals(effective[17002], nil, "open-world preset excluded from Normal")
equals(effective[17004], nil, "all modes cannot enable disabled presets")
policy.SetMode("openworld")
effective = owner.GetEffectiveRestockTargets()
equals(effective[17001], 45, "overlapping inherited targets use the maximum once")
equals(effective[17002], 12, "open-world membership adds assigned items")
equals(effective[17003], nil, "raid membership stays separate")
policy.SetMode("raid")
effective = owner.GetEffectiveRestockTargets()
equals(effective[17001], 50, "raid uses the largest inherited compatible target")
equals(effective[17003], 6, "raid membership adds assigned items")
equals(owner.GetActivePreset(), "default", "activity mode never changes the selected HUD preset")
equals(owner.GetPresetRestockTarget(17001), 30, "preset editor still owns the selected preset")
equals(owner.SetPresetRestockMembership("raid", { raid = true }, false), true, "owner can disable a mode member")
equals(owner.GetEffectiveRestockTargets()[17001], 45, "disabled raid target no longer applies")

local shoppingJob = { id = 7, planRevision = "rev1" }
local shopping = { job = shoppingJob, id = 1, itemID = 17001, quantity = 7, kind = "buy" }
provider.GetRequirements = function()
    return { shopping, { job = shoppingJob, id = 2, itemID = 17002, quantity = 2, kind = "vendor" } }
end
local quoted = policy.GetShoppingRequirements("auction")
equals(#quoted, 1, "auction shopping shows only accepted AH acquisitions")
equals(quoted[1].quantity, 7, "auction projection uses the accepted requirement's remaining units")
local displayMode, searchName
env.AuctionHouseFrame = {
    IsShown = function() return true end,
    BuyTab = { displayMode = { "Browse" } },
    SetDisplayMode = function(_, mode) displayMode = mode end,
    SetSearchText = function(_, query) searchName = query; return true end,
}
local originalIsLegacy = A.IsLegacy
A.IsLegacy = function() return false end
equals(policy.OpenAuctionRequirement(quoted[1]), true, "modern auction handoff prepares the exact accepted item")
equals(displayMode, env.AuctionHouseFrame.BuyTab.displayMode, "modern handoff enters native Buy view")
equals(searchName, env.FluxItemClass.GetName(17001), "modern handoff fills the exact item name")
shopping.quantity = 5
equals(policy.OpenAuctionRequirement(quoted[1]), false, "stale auction quantity requires a fresh accepted row")
A.IsLegacy = function() return true end
env.AuctionFrame = { IsShown = function() return true end }
local browsed = false
env.AuctionFrameTab1 = { Click = function() browsed = true end }
env.BrowseName = { SetText = function(_, query) searchName = query end }
equals(policy.OpenAuctionRequirement(shopping), true, "legacy auction handoff works from the live queue row")
equals(browsed, true, "legacy handoff enters native Browse view")
equals(searchName, env.FluxItemClass.GetName(17001), "legacy handoff fills the exact item name")
equals(st.calls.quote, nil, "preparing an accepted auction search creates no quote")
equals(st.calls.buyStack, nil, "preparing an accepted auction search creates no purchase")
local panel, menu, reported = {}
env.FluxBlizzardDropdown = { Create = function(parent)
    equals(parent, panel, "shopping menu belongs to the existing Auction House panel")
    return { FluxSetText = function() end, SetShown = function() end,
        FluxSetMenu = function(_, makeMenu) menu = makeMenu end }
end }
env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) reported = message end }
local originalGetDemands = policy.GetDemands
policy.GetDemands = function() return {} end
policy.CreateActions(panel, "auction")
local shoppingAction = menu()[1].submenu[1].func
provider.OpenAuctionShopping = function(parent, item)
    equals(parent, panel, "planner receives the owner Auction House panel")
    equals(item.jobId, 7, "planner receives the accepted job identity")
    equals(item.planRevision, "rev1", "planner receives the current job revision")
    equals(item.itemID, 17001, "planner receives the exact material")
    equals(item.quantity, 5, "planner receives the remaining accepted quantity")
    return false, "shopping feedback"
end
browsed, searchName = false, nil
shoppingAction()
equals(browsed, false, "planner shopping action keeps the existing Auction House panel")
equals(searchName, nil, "planner shopping action skips native search prefill")
equals(reported, policy.Text.plan .. "  shopping feedback", "planner feedback is reported in the standard place")
provider.OpenAuctionShopping = nil
shoppingAction()
equals(browsed, true, "optional planner hook falls back to the existing native shopping handoff")
equals(searchName, env.FluxItemClass.GetName(17001), "fallback selects the accepted item's native search")

local net = 2
provider.GetShoppingRequirements = function()
    return {{job = shoppingJob, id = 1, itemID = 17001, quantity = net, kind = "buy"}}
end
local projected = policy.GetShoppingRequirements("auction")
equals(#projected, 1, "owner consumes an optional net shopping projection")
equals(projected[1].quantity, 2, "owner display excludes covered material")
equals(projected[1].planRevision, shopping.planRevision or shoppingJob.planRevision, "net rows retain plan identity")
policy.NotifyCoverageChanged()
equals(policy.GetReservedSupply("buy", 17001), 5, "supply reservations still use accepted procurement rows")

local opens = 0
provider.OpenAuctionShopping = function(_, item)
    equals(item.quantity, 2, "opening detached shopping uses the verified net row")
    opens = opens + 1
    return true
end
local didOpen = menu()[1].submenu[1].func
didOpen()
equals(opens, 1, "a current projected shortage opens detached shopping")
net = 0
didOpen()
equals(opens, 1, "a stale menu click cannot select a newly covered item")
equals(reported, policy.Text.plan .. "  " .. policy.Text.shoppingChanged, "stale net search gives standard feedback")
equals(policy.OpenAuctionRequirement(projected[1]), false, "legacy native fallback also rejects covered selections")
equals(#policy.GetShoppingRequirements("auction"), 0, "covered requirements are absent from owner shopping")
provider.OpenAuctionShopping = nil
provider.GetShoppingRequirements = nil
equals(policy.GetShoppingRequirements("auction")[1].quantity, 5, "older planners retain their original shopping rows")

policy.GetDemands = originalGetDemands
A.IsLegacy = originalIsLegacy

do
    local _, sweepState, sweepEnv, loadSweep = boot(false, true, false)
    sweepEnv.Flux = sweepState.flux
    sweepEnv.UnitGUID = env.UnitGUID
    local timers = {}
    sweepEnv.C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
    local function nextBatch()
        local callback = assert(table.remove(timers, 1), "expected another managed restock batch")
        callback()
    end
    local function finishBatches()
        local budget = 10
        while #timers > 0 do
            budget = budget - 1
            assert(budget > 0, "managed restock must finish a pass without a retry loop")
            nextBatch()
        end
    end
    local ordered = {}
    for index = 1, 12 do
        ordered[index] = { itemID = 18000 + index, target = 10, bagCount = 0, isCharge = true }
    end
    ordered[13] = { itemID = 18013, target = 10, bagCount = 0 }
    local rows, acceptedByID, attempts = ordered, {}, {}
    sweepEnv.FluxVendorAuto.GetRestockTargetItems = function() return rows end
    loadSweep("Inventory/Restock/Core/FluxRestockPolicy.lua")
    local sweep = sweepState.flux.RestockPolicy
    assert(sweep.RegisterPlanner({
        GetCoverage = function(rule) return acceptedByID[rule.id] end,
        Request = function(rule)
            attempts[#attempts + 1] = rule.id
            if rule.units == "charge" then return false end
            assert(not acceptedByID[rule.id], "an outstanding restock must not be accepted twice")
            acceptedByID[rule.id] = { { id = rule.id, quantity = rule.uncovered, units = rule.units } }
            return true
        end,
    }))
    sweep.SetManaged(true)
    sweep.SetMode("raid")
    local finalID = "item:18013"
    equals(sweep.GetDemand("item:18001").units, "charge", "shared demand preserves its charge units")
    nextBatch()
    equals(#attempts, 12, "one managed batch visits at most twelve demands")
    equals(acceptedByID[finalID], nil, "the last target waits for the next bounded batch")
    equals(#timers, 1, "unvisited demands automatically get another batch")

    rows = { ordered[1], ordered[13], ordered[13] }
    for index = 12, 2, -1 do rows[#rows + 1] = ordered[index] end
    sweep.NotifyChanged("inventory")
    nextBatch()
    equals(attempts[13], finalID, "the next batch reaches the reordered target after earlier requests fail")
    equals(#attempts, 13, "processed and repeated demand IDs are skipped within a pass")
    equals(acceptedByID[finalID][1].quantity, 10, "the later target receives its full eligible refill")

    finishBatches()
    sweep.NotifyChanged("inventory")
    finishBatches()
    equals(sweep.GetDemand(finalID).uncovered, 0, "another inventory event keeps accepted coverage")

    rows, acceptedByID, attempts = ordered, {}, {}
    sweep.NotifyChanged("inventory")
    nextBatch()
    equals(#attempts, 12, "a fresh event starts a new bounded pass")
    sweep.SetMode("normal")
    finishBatches()
    equals(acceptedByID[finalID], nil, "switching to Normal cancels a pending passive batch")
    equals(sweep.Request(finalID, "restock", { manual = true, source = "bank" }), true,
        "Normal still permits explicit work from the bank")
end

print(("FluxLogistics restock bridge PASS (%d checks)"):format(checks))
