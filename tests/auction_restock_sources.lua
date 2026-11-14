-- Real AH planner, normal merchant list/buyer and bank owner source handoff.
local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local fixture = assert(loadfile(root .. "/tests/auction_restock.lua", "t", export))()
local checks, profiles, context = 0, 0, ""
local function check(value, label) checks = checks + 1; assert(value, label .. " [" .. context .. "]") end
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for k, v in pairs(value) do out[k] = copy(v) end; return out
end
local function boot(legacy, auctionator, syndicator)
    local A, st, env = fixture(legacy, auctionator, syndicator)
    local function load(path)
        assert(loadfile(root .. "/" .. path, "t", env))("_FluxUI", { Flux = st.flux })
    end
    st.bankItems, st.bankUses, st.bagUses = {}, {}, {}
    env.FluxRestock.Inv.GetLiveCount = function(id, opts)
        return opts.charges and st.bagUses[id] or st.bags[id] or 0
    end
    env.FluxRestock.Inv.GetCount = env.FluxRestock.Inv.GetLiveCount
    env.FluxRestock.Inv.Bank = {
        GetCount = function(id, opts) return opts and opts.charges and st.bankUses[id] or st.bankItems[id] or 0 end,
        IsOpen = function() return true end, IsLive = function() return true end,
        RegisterBankOpen = function(_, callback) st.bankOpenCallback = callback end, RegisterBankClose = function() end,
    }
    env.FluxItemClass.GetIcon = function(id) return id end
    env.FluxItemClass.GetStackSize = function() return 20 end
    env.FluxItemClass.GetMaxStackSize = function() return 20 end
    env.FluxItemClass.RequestLoad = function() end
    env.wipe = function(value) for key in pairs(value) do value[key] = nil end; return value end
    st.settings.restockItems, st.settings.itemPrices = {}, {}
    local function book(id, q, p)
        return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = q, total = q * p } }
            or { { itemID = id, quantity = q, unitPrice = p } } }
    end
    local function recipe(output, ingredient, count)
        st.recipeItems = st.recipeItems or {}; st.recipeItems[output] = true
        st.recipes = st.recipes or {}
        st.recipes[#st.recipes + 1] = { recipeID = output + 500, outputItemID = output, learned = true,
            legacy = true, name = "Recipe" .. output, quantityMin = 1, reagents = { { itemID = ingredient, count = count } } }
    end
    local function scan()
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); A.ScanQueue(); st.drain()
    end
    return A, st, env, load, book, recipe, scan
end
local function find(list, id) for _, entry in ipairs(list) do if entry.itemID == id then return entry end end end
local function BankFlag(st, id, enabled)
    local saved = st.settings.restockItems[id] or { targetQuantity = 0 }
    saved.countBank = enabled == true; st.settings.restockItems[id] = saved
    for _, row in ipairs(st.entries) do if row.itemID == id then
        row.countBank = enabled == true
        row.bankCount = st.charged == id and (st.bankUses[id] or 0) or (st.bankItems[id] or 0)
    end end
end
if FLUX_AH_SOURCES_FIXTURE_EXPORT then return boot end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1; context = client .. "/" .. tostring(auctionator) .. "/" .. tostring(syndicator)
        local A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, name = "Potion", target = 2 } }
        st.bankItems[200] = 2; BankFlag(st, 200, true); recipe(100, 200, 1); st.books = { [100] = book(100, 2, 100) }
        scan()
        check(A.craftPlans[100] and A.craftPlans[100].cost == 0, "bank materials choose zero-cost crafting with profession closed")
        check(not st.searchedIDs and not A.offer, "fully bank-covered plan does not search or buy finished items")
        check(A.FindRow(200).need == 0 and A.FindRow(200).craftBankCount == 2, "temporary AH material row credits exactly its bank allocation")
        local saved = copy(A.Settings().vendorCraftPlans)
        check(saved[100] and next(saved[100].prices) == nil, "bank-only plan persists without pretending a vendor purchase")
        check(A.GetCraftBankAvailable(200) == 2, "bank physical pool is available to follow-up")

        -- Two selected recipes share one bank pool, with the second paying only
        -- for its uncovered requirement. Actual invoice belongs to that plan.
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 1 }, { itemID = 101, target = 2 } }
        st.bankItems[200] = 1; BankFlag(st, 200, true); recipe(100, 200, 1); recipe(101, 200, 1)
        st.books = { [100] = book(100, 1, 100), [101] = book(101, 2, 100), [200] = book(200, 2, 5) }
        scan()
        check(A.craftPlans[100].cost == 0 and A.craftPlans[101].cost == 10, "second recipe cannot spend the first recipe bank material twice")
        check(A.FindRow(200).target == 3 and A.FindRow(200).need == 2 and A.offer.quantity == 2, "shared bank credit reduces total purchases exactly once")
        A.RecordCraftSpend(A.FindRow(200), 10, 2)
        check(A.craftPlans[100].spent == 0 and A.craftPlans[101].spent == 10, "bank-covered recipe is not charged another recipe invoice")

        -- An ingredient with its bank flag off never credits stored copies.
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 2 }, { itemID = 200, target = 10, countBank = false } }
        st.bags[200], st.bankItems[200] = 10, 2; recipe(100, 200, 1)
        st.books = { [100] = book(100, 2, 100), [200] = book(200, 2, 10) }
        scan()
        check(A.GetCraftBagAvailable(200) == 0 and A.GetCraftBankAvailable(200) == 0,
            "disabled ingredient bank flag protects direct stock and excludes bank copies from crafting")
        check(A.FindRow(200).target == 12 and A.FindRow(200).need == 2,
            "disabled bank credit leaves the full craft purchase in the merged target")
        st.bags[200] = 8; A.GetRows(true)
        check(A.FindRow(200).need == 4, "disabled bank flag preserves both direct and craft carried shortages")
        A.ResetCraftPlans(); A.ScanQueue(); st.drain()
        check(A.craftPlans[100] and A.craftPlans[100].cost == 20 and A.FindRow(200).need == 4 and A.offer and A.offer.quantity == 2,
            "recipe cost excludes disabled bank stock while a whole fitting stack remains buyable")
        check(A.CheckCraftSpend(A.FindRow(200), { total = 20, quantity = 2 }), "own direct refill does not consume the craft invoice")
        st.press()
        if legacy then st.legacyReceipt()
        else st.emit("COMMODITY_PRICE_UPDATED", 10, 20); st.press(); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        check((st.calls.buyStack or st.calls.confirm) == 1 and A.craftPlans[100].spent == 0,
            "one player transaction refills only the direct share before spending craft budget")

        -- Partly used carried charges need extra physical protection before a
        -- charged item can be treated as a recipe reagent.
        A.Settings().pending = {}
        st.charged, st.charges = 200, 5; st.bags[200], st.bagUses[200], st.bankItems[200], st.bankUses[200] = 2, 6, 3, 15
        st.entries[2].target = 9; BankFlag(st, 200, true); A.ResetCraftPlans(); A.ScanQueue(); st.drain()
        check(A.GetCraftBagAvailable(200) == 2 and A.GetCraftBankAvailable(200) == 0, "counted bank copies protect the direct target while partly used bags supply physical reagents")
        check(A.FindRow(200).need == 0, "mixed charged row credits actual bank uses rather than inventing one missing physical copy")

        -- A vendor invoice has already allocated its owned bank copy. With
        -- exact whole listings required, stealing it blocks the other plan.
        if legacy then
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 1 }, { itemID = 101, target = 1 } }
        st.bankItems[201] = 1; BankFlag(st, 201, true); recipe(100, 201, 2); recipe(101, 201, 2)
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 10 } }
        st.books = { [100] = book(100, 1, 100), [101] = book(101, 1, 100),
            [201] = legacy and { commodity = false, offers = { { itemID = 201, quantity = 2, total = 15 } } }
                or { commodity = false, offers = { { itemID = 201, quantity = 2, buyoutAmount = 15, auctionID = 201,
                    itemKey = { itemID = 201, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 } } } } }
        A.Settings().allowExcessStacks = false; A.SetMaxPrice(101, 15); scan()
        check(A.craftPlans[100].vendorItems[201] and not A.craftPlans[101].vendorItems[201], "exact stack policy permits a vendor and AH route for the same reagent")
        check(A.FindRow(201).target == 3 and A.FindRow(201).need == 2 and A.offer and A.offer.quantity == 2,
            "vendor-owned bank share cannot shrink the other plan below its complete AH listing")
        check(A.GetVendorCraftTargets(st.entries)[201].need == 1, "normal vendor route retains its already allocated bank share before AH delivery")
        local row = A.FindRow(201)
        check(A.CheckCraftSpend(row, { total = 15, quantity = 2 }), "whole AH invoice stays inside its selected recipe budget")
        A.RecordCraftSpend(row, 8, 1)
        st.bags[201] = 1
        check(not A.CheckCraftSpend(row, { total = 8, quantity = 1 }), "second shared-input invoice cannot hide behind vendor-owned stock")
        end

        -- Ingredient bank credit is opt-in and independent of its output's flag.
        for _, countBank in ipairs({ false, true }) do
            A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
            st.entries = { { itemID = 100, name = "Output", target = 10 } }
            st.bankItems[200] = 5; BankFlag(st, 100, true)
            if countBank then BankFlag(st, 200, true) end
            recipe(100, 200, 1)
            local needed = countBank and 5 or 10
            st.books = { [100] = book(100, 10, 100), [200] = book(200, needed, 10) }
            scan()
            check(A.CraftCountsBank(200) == countBank and A.GetCraftBankAvailable(200) == (countBank and 5 or 0),
                "ingredient bank flag alone controls physical crafting bank availability")
            check(A.craftPlans[100].cost == needed * 10 and A.FindRow(200).need == needed
                and A.FindRow(200).countBank == countBank and A.offer.itemID == 200 and A.offer.quantity == needed,
                "ten craft ingredients with five banked buy ten when off or five when on")
            st.press()
            if legacy then st.legacyReceipt()
            else st.emit("COMMODITY_PRICE_UPDATED", 10, needed * 10); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
            check((st.calls.buyStack or st.calls.confirm) == 1 and A.Settings().pending[200].units == needed,
                "one authorized purchase reserves exactly the flag-adjusted AH quantity")

            A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
            st.entries = { { itemID = 100, name = "Output", target = 10 } }
            st.settings.restockItems[100] = { targetQuantity = 10 }
            st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 1 } }
            st.bankItems[201] = 5; BankFlag(st, 100, true)
            if countBank then BankFlag(st, 201, true) end
            recipe(100, 201, 1); st.books = { [100] = book(100, 10, 100) }; scan()
            check(A.craftPlans[100].vendorCost == needed and not A.FindRow(201) and not A.offer,
                "vendor recipe inputs remain vendor-routed with flag-adjusted cost")
            load("Inventory/Restock/Core/FluxRestockList.lua")
            env.FluxRestockItemRegistry.IsChargeItem = function() return false end
            env.FluxRestockItemRegistry.GetItemMaxCharges = function() return 0 end
            env.FluxRestockItemRegistry.GetChargeInfo = function() return false, 0 end
            local vendorTarget = find(env.FluxVendorAuto.GetRestockTargetItems({ merchantAware = true }), 201)
            check(vendorTarget and env.FluxRestockList.EntryNeed(vendorTarget) == needed,
                "normal vendor target excludes bank five when on and ignores it when off")
            env.MerchantFrame = { IsShown = function() return true end }
            env.GetMerchantNumItems = function() return 1 end
            env.GetMerchantItemID = function() return 201 end
            env.GetMerchantItemLink = function() return "item:201" end
            env.GetMerchantItemMaxStack = function() return 20 end
            env.GetMerchantItemInfo = function() return "Material", 201, 1, 1, -1, true, true, false end
            env.GetMerchantItemCostInfo = function() return 0 end
            env.IsShiftKeyDown = function() return false end
            env.FluxRestock.Inv.NotifyAutomationPulse = function() end
            st.inventory.NotifyAutomationPulse = function() end
            env.BuyMerchantItem = function(_, quantity) st.vendorBought = quantity; st.bags[201] = (st.bags[201] or 0) + quantity end
            load("Inventory/Restock/Vendor/FluxVendorBuy.lua"); env.FluxVendorAuto.DoRestockManual()
            check(st.vendorBought == needed, "actual vendor buyer purchases ten when bank off or five when on")
        end

        -- Fully owned vendor ingredients preserve their source and shared share.
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 1 } }; st.bags[201] = 1
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 10 } }
        recipe(100, 201, 1); st.books = { [100] = book(100, 1, 100) }; scan()
        check(A.craftPlans[100].cost == 0 and A.craftPlans[100].vendorItems[201]
            and A.craftPlans[100].vendorOwned[201] == 1 and not A.FindRow(201),
            "owned unlimited vendor reagent never becomes a Direct auction material cell")
        st.entries[2] = { itemID = 101, target = 1 }; recipe(101, 201, 2)
        st.books[101] = book(101, 1, 100)
        st.books[201] = legacy and { commodity = false, offers = { { itemID = 201, quantity = 2, total = 15 } } }
            or { commodity = false, offers = { { itemID = 201, quantity = 2, buyoutAmount = 7, auctionID = 201,
                itemKey = { itemID = 201, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 } } } }
        A.SetMaxPrice(101, 15); A.ScanQueue(); st.drain()
        local sharedRow = A.FindRow(201)
        check(sharedRow and sharedRow.target == 3 and sharedRow.need == 2 and A.offer and A.offer.quantity == (legacy and 2 or 1),
            "a different AH recipe cannot steal a fully owned vendor allocation or block its exact listing")
        if not legacy then
            local shared = A.FindRow(201)
            check(A.craftPlans[101].cost == 14 and A.offer.availableQuantity == 2,
                "modern shared recipe costs both available individual items without making a bulk bid")
            A.RecordCraftSpend(shared, 8, 1); st.bags[201] = 2
            check(not A.CheckCraftSpend(shared, { total = 8, quantity = 1 }),
                "separate grouped-item buys cannot evade the selected recipe's total budget")
        end

        -- A live stock change must prepare prices automatically, before Buy.
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 1 }, { itemID = 200, target = 9 } }
        st.bags[200] = 10; recipe(100, 200, 1)
        st.books = { [100] = book(100, 1, 100), [200] = book(200, 1, 10) }; scan()
        check(A.craftPlans[100].cost == 0 and not A.offer, "owned ingredient initially needs no price query")
        A.priceBooks[200] = { itemID = 200, at = st.time, commodity = not legacy, offers = st.books[200].offers }
        st.bags[200] = 9; A.GetRows(true)
        check(A.PurchaseLimit(200) == 0 and A.FindRow(200).need == 1, "stock loss exposes the old zero-cost derived limit")
        A.PrepareNext(); st.drain()
        check(A.offer and A.offer.itemID == 200 and A.offer.quantity == 1 and A.PurchaseLimit(200) == 10,
            "prepare-next refreshes the changed recipe cost without a scan or empty Buy press")
        st.press()
        if legacy then st.legacyReceipt()
        else st.emit("COMMODITY_PRICE_UPDATED", 10, 10); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        check((st.calls.buyStack or st.calls.confirm) == 1, "first Buy press after stock change purchases the missing ingredient")

        -- A bank toggle invalidates a free source snapshot before vendor buying.
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 5 } }; st.settings.restockItems[100] = { targetQuantity = 5 }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 10 } }
        st.bankItems[201] = 5; BankFlag(st, 201, true); recipe(100, 201, 1)
        st.books = { [100] = book(100, 5, 1) }; A.SetMaxPrice(100, 1); scan()
        check(A.craftPlans[100].cost == 0, "counted bank can establish a free capped craft plan")
        BankFlag(st, 201, false)
        check(not next(A.GetVendorCraftTargets(st.entries)), "changed bank flag cannot authorize an old free vendor plan above its parent cap")
        A.PrepareNext(); st.drain()
        check(not A.craftPlans[100] and A.offer and A.offer.itemID == 100,
            "changed bank flag re-compares current costs and selects the affordable finished item")

        -- Losing reserved owned inputs cannot silently expand a vendor invoice.
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 1 } }; st.settings.restockItems[100] = { targetQuantity = 1 }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 10 } }
        st.bags[201] = 1; recipe(100, 201, 1); st.books = { [100] = book(100, 1, 1) }
        A.SetMaxPrice(100, 1); scan()
        check(A.craftPlans[100].cost == 0, "owned vendor input can establish a free capped recipe")
        st.bags[201] = 0
        check(not next(A.GetVendorCraftTargets(st.entries)) and not A.craftPlans[100],
            "losing reserved owned material cannot authorize a new vendor invoice above the selected budget")
        A.PrepareNext(); st.drain()
        check(A.offer and A.offer.itemID == 100, "lost owned source is compared again before any material purchase")

        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 2 } }; st.settings.restockItems[100] = { targetQuantity = 2 }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 10 } }
        st.bags[201] = 1; recipe(100, 201, 1); st.books = { [100] = book(100, 2, 100) }; scan()
        st.bags[100], st.bags[201] = 1, 0
        local remaining = A.GetVendorCraftTargets(st.entries)
        check(remaining[201] and remaining[201].need == 1,
            "consuming the originally owned input in a completed craft preserves its original paid vendor remainder")

        -- Excess policy follows each actual ingredient SKU, not its parent's
        -- charge type, while recipe quantities remain physical copies.
        local function ItemListing(id, quantity, unit)
            return legacy and { commodity = false, offers = { { itemID = id, quantity = quantity, total = quantity * unit } } }
                or { commodity = false, offers = { { itemID = id, quantity = quantity, buyoutAmount = quantity * unit,
                    auctionID = id, itemKey = { itemID = id, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 } } } }
        end
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 1 } }; st.charged, st.charges = 200, 5
        A.Settings().allowExcessStacks = true; recipe(100, 200, 1)
        st.books = { [100] = book(100, 1, 100), [200] = ItemListing(200, 2, 1) }; scan()
        check(legacy and not A.craftPlans[100] and A.offer and A.offer.itemID == 100
            or not legacy and A.craftPlans[100] and A.offer and A.offer.itemID == 200 and A.offer.quantity == 1,
            "charged recipe input never gains whole-listing excess through its physical material row")
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 5 } }; st.charged, st.charges = 100, 5
        A.Settings().allowExcessStacks = true; recipe(100, 201, 1)
        st.books = { [100] = ItemListing(100, 1, 100), [201] = ItemListing(201, 2, 1) }; scan()
        check(legacy and A.craftPlans[100] and A.offer.itemID == 201 and A.offer.quantity == 2
            or not legacy and A.craftPlans[100] and A.offer and A.offer.itemID == 201 and A.offer.quantity == 1,
            "charged output permits old-AH uncharged ingredient excess while modern AH prepares one exact item")

        -- Modern item availability describes separate one-item purchases at
        -- a unit price; virtual costing must preserve the native source book.
        local grouped = { commodity = false, offers = {
            { auctionID = 900, quantity = 1, availableQuantity = 2, total = 7 },
            { auctionID = 901, quantity = 1, availableQuantity = 3, total = 8 },
        } }
        local groupedCost = A.BookCost(grouped, 3, 100, false)
        check(groupedCost and groupedCost.cost == 22 and groupedCost.quantity == 3 and groupedCost.limit == 8,
            "grouped item rows cost each separately buyable physical copy at its unit price")
        check(grouped.offers[1].availableQuantity == 2 and grouped.offers[2].availableQuantity == 3
            and grouped.offers[1].quantity == 1 and #grouped.offers == 2,
            "virtual grouped pricing never consumes the shared native availability book")
        check(not A.BookCost(grouped, 6, 100, false) and not A.BookCost(grouped, 3, 7, false),
            "grouped planning cannot invent unavailable copies or bypass unit limits")
        check(not A.BookCost({ commodity = false, offers = {
            { auctionID = 902, quantity = 1, availableQuantity = 0, total = 1 },
        } }, 1, 100, false), "empty grouped availability is not treated as one buyable item")
        local whole = A.BookCost({ commodity = false, offers = {
            { index = 1, quantity = 20, total = 100 },
        } }, 20, 100, false)
        check(whole and whole.cost == 100 and whole.quantity == 20,
            "legacy whole listings retain their entire physical quantity and invoice")

        if not legacy then
            A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
            st.entries = { { itemID = 100, target = 1 } }; st.charged, st.charges = 200, 5
            recipe(100, 200, 2)
            st.books = { [100] = book(100, 1, 100), [200] = { commodity = false, offers = {
                { itemID = 200, quantity = 2, buyoutAmount = 7, auctionID = 900,
                    itemKey = { itemID = 200, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 } },
            } } }; scan()
            check(A.craftPlans[100] and A.craftPlans[100].cost == 14 and A.offer and A.offer.quantity == 1
                and A.offer.availableQuantity == 2, "two grouped craft inputs are priced at fourteen while preparing one physical bid")
            check(A.priceBooks[200].offers[1].availableQuantity == 2 and st.books[200].offers[1].quantity == 2,
                "planning keeps both normalized and raw grouped availability immutable")
            st.press()
            check(st.calls.buyItem == 1 and A.transaction.quantity == 1 and A.transaction.auctionID == 900
                and A.craftPlans[100].spent == 7, "first hardware press spends one unit invoice for one grouped item")
            st.books[200].offers[1].quantity, st.books[200].offers[1].auctionID = 1, 901
            st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 900); st.drain()
            check(st.calls.buyItem == 1 and A.offer and A.offer.auctionID == 901 and A.offer.quantity == 1,
                "acknowledgement queries the next actual auction ID without bidding automatically")
            st.press(); st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 901); st.drain()
            check(st.calls.buyItem == 2 and A.craftPlans[100].spent == 14 and A.Settings().pending[200].units == 2,
                "second fresh press completes two physical recipe inputs with one exact total invoice")
        end

        -- All-vendor plans use the normal merchant restock list, survive a
        -- reload, and never modify permanent source targets.
        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.settings.restockItems = { [100] = { targetQuantity = 2 } }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 5 } }
        st.entries = { { itemID = 100, target = 2 } }; BankFlag(st, 201, true); recipe(100, 201, 1)
        st.books = { [100] = book(100, 2, 100) }; scan()
        check(A.craftPlans[100] and A.craftPlans[100].vendorCost == 10 and not A.offer, "vendor-only recipe can be selected without an AH purchase")
        saved = copy(A.Settings().vendorCraftPlans)
        load("Inventory/Restock/Core/FluxRestockList.lua")
        env.FluxRestockItemRegistry.IsChargeItem = function(id) return id == st.charged end
        env.FluxRestockItemRegistry.GetItemMaxCharges = function() return st.charges end
        env.FluxRestockItemRegistry.GetChargeInfo = function(id) return id == st.charged, st.charges end
        A.Settings().vendorCraftPlans = copy(saved); A.craftPlans[100] = nil
        local list = env.FluxVendorAuto.GetRestockTargetItems({ merchantAware = true })
        local extra = find(list, 201)
        check(extra and extra.target == 2 and env.FluxRestockList.EntryNeed(extra) == 2, "reloaded vendor-only plan creates an exact normal merchant target")
        check(st.settings.restockItems[201].targetQuantity == 0 and st.settings.restockItems[201].countBank == true and st.settings.restockItems[100].targetQuantity == 2, "temporary vendor target does not rewrite permanent source data")
        st.bankItems[201] = 2
        list = env.FluxVendorAuto.GetRestockTargetItems({ merchantAware = true })
        check(env.FluxRestockList.EntryNeed(find(list, 201)) == 0, "normal vendor restock does not rebuy bank-held craft ingredients")
        st.bankItems[201], st.bags[201] = 0, 1
        list = env.FluxVendorAuto.GetRestockTargetItems({ merchantAware = true })
        check(env.FluxRestockList.EntryNeed(find(list, 201)) == 1, "normal vendor restock buys only the current physical craft shortage")
        env.MerchantFrame = { IsShown = function() return true end }
        env.GetMerchantNumItems = function() return 1 end
        env.GetMerchantItemID = function() return 201 end
        env.GetMerchantItemLink = function() return "item:201" end
        env.GetMerchantItemMaxStack = function() return 20 end
        env.GetMerchantItemInfo = function() return "Item201", 201, 5, 1, -1, true, true, false end
        env.GetMerchantItemCostInfo = function() return 0 end
        env.IsShiftKeyDown = function() return false end
        env.FluxRestock.Inv.NotifyAutomationPulse = function() end
        st.inventory.NotifyAutomationPulse = function() end
        env.BuyMerchantItem = function(_, quantity) st.vendorBought = (st.vendorBought or 0) + quantity; st.bags[201] = st.bags[201] + quantity end
        load("Inventory/Restock/Vendor/FluxVendorBuy.lua")
        env.FluxVendorAuto.DoRestockManual()
        check(st.vendorBought == 1 and st.bags[201] == 2, "existing manual vendor purchase completes the persisted craft target")
        env.FluxVendorAuto.RefreshRestockCacheEntries(list)
        check(env.FluxRestockList.EntryNeed(find(list, 201)) == 0, "normal restock cache drops fulfilled temporary vendor shortage")
        st.advance(1); st.vendorBought, st.bags[201], st.settings.autoRestock = 0, 1, true
        env.FluxVendorAuto.TriggerAutoRestock(); st.advance(1)
        check(st.vendorBought == 1 and st.bags[201] == 2,
            "normal automatic vendor entry point buys the same exact temporary recipe shortage without a manual press")

        st.charged, st.charges = 201, 5
        st.settings.restockItems[201] = { targetQuantity = 9, countBank = true }
        st.bags[201], st.bagUses[201] = 1, 5
        list = env.FluxVendorAuto.GetRestockTargetItems({ merchantAware = true })
        extra = find(list, 201)
        check(extra.target == 19 and extra.craftUnitsPerItem == 5 and env.FluxRestockList.EntryNeed(extra) == 14,
            "temporary physical vendor input is added in existing direct charge target units")
        st.vendorBought = 0; env.FluxVendorAuto.DoRestockManual()
        check(st.vendorBought == 3, "normal vendor owner converts charged direct plus craft shortage to physical copies once")
        st.charged, st.charges = nil, nil

        -- Exercise the bank owner list, summary and real Start task handoff;
        -- the native mover is a capture only, never a simulated native claim.
        A.Followup = { GetBankTargets = function() return st.followBank or {} end }
        st.settings.restockItems = { [200] = { targetQuantity = 10, countBank = false } }
        st.bags[200], st.bankItems[200] = 10, 20
        st.followBank = { { itemID = 200, target = 12, restockSource = "craftMaterial", countBank = false } }
        env.FluxRestockItemRegistry.InvalidateBankTargetsCache()
        load("Inventory/Restock/Bank/FluxBankRestockRules.lua")
        env.FluxBankRestockMoveExec = { Start = function(session) st.bankTasks = session.tasks; return true end }
        local create = env.CreateFrame
        env.CreateFrame = function(...)
            local frame = create(...); frame.UnregisterAllEvents = function() end; return frame
        end
        load("Inventory/Restock/Bank/FluxBankRestock.lua")
        local BR = env.FluxBankRestock
        check(BR.GetPendingSummary() == 2, "normal bank summary includes temporary craft surplus above permanent target")
        check(BR.RunManual() == true and st.bankTasks[1].withdraw == 2, "normal bank button submits temporary need to its existing move owner")
        check(st.settings.restockItems[200].targetQuantity == 10, "bank task union never mutates permanent targets")
        BR.Stop(); st.bankTasks = nil; st.settings.autoBankRestock = true
        st.bankOpenCallback(); st.advance(1)
        check(st.bankTasks and st.bankTasks[1].withdraw == 2,
            "normal bank-open automatic restock submits temporary materials through the same move owner")

        BR.Stop(); st.bags[200] = 15; st.followBank[1].target = 17; BR.InvalidateCanRunCache()
        check(BR.GetPendingSummary() == 2, "surplus carried copies do not swallow added physical bank need")
        st.charged, st.charges = 200, 5; st.settings.restockItems[200].targetQuantity = 9
        st.bags[200], st.bagUses[200], st.bankUses[200] = 2, 6, 100
        st.followBank[1].target = 3; env.FluxRestockItemRegistry.InvalidateBankTargetsCache(); BR.InvalidateCanRunCache()
        check(BR.GetPendingSummary() == 8, "bank task union adds physical reagent need in existing charge units")
        check(find(BR.GetTooltipItems(), 200).target == 14, "bank tooltip retains combined target in native charge units")
        st.followBank = {}; env.FluxRestockItemRegistry.InvalidateBankTargetsCache(); BR.InvalidateCanRunCache()
        check(BR.GetPendingSummary() == 3, "completed craft task removes only temporary bank target")
        check(#st.errors == 0, "source handoffs did not swallow runtime errors")
    end end
end
print(string.format("Auction restock sources: %d checks PASS; %d profiles; native bank/vendor permissions NOT RUN", checks, profiles))
