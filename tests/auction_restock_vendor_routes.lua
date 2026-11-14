-- Actual missing-material invoices choose vendor vs AH, including whole stacks.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local source = assert(loadfile("tests/auction_restock.lua", "t", export)); if setfenv then setfenv(source, export) end
local fixture = source()
local function Followup(st, env)
    local chunk = assert(loadfile(root .. "/Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua", "t", env))
    if setfenv then setfenv(chunk, env) end
    chunk("_FluxUI", { Flux = st.flux })
    return env.FluxAuctionRestock.Followup
end
local function Book(legacy, id, q, unit, whole, auctionID)
    if legacy then return { commodity = false, offers = { { itemID = id, quantity = q, total = q * unit } } } end
    if whole then return { commodity = false, offers = { { itemID = id, quantity = q, buyoutAmount = unit,
        auctionID = auctionID or id, itemKey = { itemID = id, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 } } } } end
    return { commodity = true, offers = { { itemID = id, quantity = q, unitPrice = unit } } }
end
local function Open(A, st) st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain() end
local function Setup(legacy, auctionator, syndicator, vendorPrice, auctionPrice, quantity, whole, cap)
    local A, st, env = fixture(legacy, auctionator, syndicator)
    st.entries = { { itemID = 100, name = "Bandage", target = 1 } }
    st.recipeItems = { [100] = 7 }
    st.recipes = { { recipeID = 77, outputItemID = 100, name = "Bandage", learned = true, legacy = true,
        quantityMin = 1, reagents = { { itemID = 200, count = 1 }, { itemID = 201, count = 1 } } } }
    st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = vendorPrice } }
    st.books = { [100] = Book(legacy, 100, 1, 100), [200] = Book(legacy, 200, 1, 5),
        [201] = Book(legacy, 201, quantity or 1, auctionPrice, whole) }
    A.Settings().allowExcessStacks = true
    if cap then A.SetMaxPrice(201, cap) end
    Open(A, st)
    return A, st, env
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env = Setup(legacy, auctionator, syndicator, 2, 1)
        local plan = assert(A.craftPlans[100])
        check(st.searchedIDs[201] and st.searchedIDs[200], "recipe pricing searches known vendor inputs as well as auction-only inputs")
        check(plan.cost == 6 and plan.vendorCost == 0 and not plan.vendorItems[201] and plan.limits[201] == 1,
            "strictly cheaper exact AH invoice chooses the vendor-sold ingredient on AH")
        check(A.FindRow(201) and A.FindRow(201).target == 1 and A.FindRow(201).craftLimit == 1,
            "chosen auction vial becomes an exact material row with its own auction limit")
        check(not next(A.Settings().vendorCraftPlans[100].prices),
            "auction-chosen vial does not become a later vendor shopping target")
        local F = Followup(st, env)
        check(not F.Capture(A.FindRow(200)).outputs[100].prices[201], "follow-up snapshot does not change a chosen AH route back to vendor")
        local scanned = st.searchedIDs[201]
        st.advance(30); A.ScanQueue(true); st.drain()
        check(st.searchedIDs[201] > scanned and not A.craftPlans[100].vendorItems[201],
            "expired recipe books refresh at thirty seconds before reusing an auction route")

        A, st, env = Setup(legacy, auctionator, syndicator, 2, 2)
        plan = assert(A.craftPlans[100])
        check(plan.vendorItems[201] and plan.vendorCost == 2 and plan.cost == 7 and not A.FindRow(201),
            "equal vendor/AH prices keep the vendor route and exclude its AH material row")

        -- An attractive unit price must still beat the actual required invoice.
        if legacy then
        A, st, env = Setup(legacy, auctionator, syndicator, 2, 1, 20, true)
        plan = assert(A.craftPlans[100])
        check(A.HasUnlimitedVendor(201) and not A.IsVendorItem(201), "fresh unit discount is recorded separately from the raw vendor fact")
        check(plan.vendorItems[201] and plan.vendorCost == 2 and plan.cost == 7 and not A.FindRow(201),
            "whole stack twenty at one copper cannot replace one vendor item costing two copper")
        check(A.Settings().vendorCraftPlans[100].prices[201] == 2 and plan.vendorPrices[201] == 2 and plan.budget == 98,
            "selected vendor invoice persists and remains deducted from the crafting budget")
        st.inventory.Professions.ListRecipesForOutput = function() return st.recipes end
        local targets = A.GetVendorCraftTargets(st.entries)
        check(targets[201] and targets[201].target == 1 and targets[201].maxUnitPrice == 2,
            "persisted vendor target validates raw availability even while global AH discount is fresh")
        F = Followup(st, env)
        st.settings.merchantSources[201].unitPrice = 3
        check(F.Capture(A.FindRow(200)).outputs[100].prices[201] == 2,
            "follow-up preserves the chosen vendor price despite a later raw-price update and global unit discount")
        st.press()
        if legacy then st.legacyReceipt() else st.emit("COMMODITY_PRICE_UPDATED", 5, 5); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        st.bags[200] = 1; F.Refresh()
        check(F.GetState().kind == "vendor" and F.GetState().items[201] == 1 and F.GetState().prices[201] == 2,
            "owned auction materials lead to the chosen one-item vendor invoice")

        A, st, env = Setup(legacy, auctionator, syndicator, 2, 1, 2, true)
        check(A.craftPlans[100].vendorItems[201] and not A.FindRow(201), "equal complete invoices prefer vendor even when AH unit price is lower")
        else
            A, st, env = Setup(legacy, auctionator, syndicator, 2, 1, 20, true)
            plan = assert(A.craftPlans[100])
            check(A.HasUnlimitedVendor(201) and not A.IsVendorItem(201) and not plan.vendorItems[201]
                and plan.vendorCost == 0 and plan.cost == 6,
                "modern grouped availability twenty still compares a one-item unit invoice against the vendor")
            check(A.priceBooks[201].offers[1].quantity == 1 and A.priceBooks[201].offers[1].availableQuantity == 20,
                "modern vendor discount books keep availability separate from purchase quantity")
            F = Followup(st, env)
            check(not F.Capture(A.FindRow(200)).outputs[100].prices[201],
                "modern grouped discount remains an AH route in the saved follow-up")
            st.bags[200] = 1; A.PrepareNext(); st.drain()
            check(A.offer and A.offer.itemID == 201 and A.offer.quantity == 1 and A.offer.total == 1,
                "modern grouped vendor item prepares one physical bid at its own unit price")
            st.press()
            check(st.calls.buyItem == 1 and A.transaction.quantity == 1 and st.last.args[1] == 201 and st.last.args[2] == 1,
                "modern grouped vendor bargain submits one native auction bid per press")
            st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 201); st.drain()
            check(A.Settings().pending[201].units == 1 and F.GetMailItems()[201] == 1
                and st.books[201].offers[1].quantity == 20,
                "one grouped purchase reserves one item without consuming the remaining availability book")
            A, st, env = Setup(legacy, auctionator, syndicator, 2, 2, 20, true)
            check(A.craftPlans[100].vendorItems[201] and not A.FindRow(201),
                "equal modern unit price prefers one vendor item regardless of grouped availability")
        end
        A, st, env = Setup(legacy, auctionator, syndicator, 5, 3, 1, false, 2)
        check(A.craftPlans[100].vendorItems[201] and A.craftPlans[100].vendorCost == 5 and not A.FindRow(201),
            "an explicit auction item cap can reject a discount without changing its known vendor alternative")
        A, st, env = Setup(legacy, auctionator, syndicator, 2, 1)
        A.SetMaxPrice(100, 5); st.drain()
        check(not A.craftPlans[100], "discounted ingredients do not override the finished output price cap")
        check(#st.errors == 0, "vendor/auction recipe comparison produces no modeled API errors")

        -- Keep rational vendor terms intact through the actual craft invoice.
        A, st, env = fixture(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, name = "Bandage", target = 1 } }
        st.recipeItems = { [100] = 7 }
        st.recipes = { { recipeID = 77, outputItemID = 100, name = "Bandage", learned = true, legacy = true,
            quantityMin = 1, reagents = { { itemID = 201, count = 25 } } } }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 7 / 25,
            priceNumerator = 7, priceDenominator = 25 } }
        st.books = { [100] = Book(legacy, 100, 1, 7), [201] = Book(legacy, 201, 25, 1) }
        A.SetMaxPrice(100, 7); Open(A, st)
        plan = A.craftPlans[100]
        check(plan and plan.vendorItems[201] and plan.cost == 7 and plan.vendorCost == 7 and plan.budget == 0,
            "twenty-five ingredients priced seven per twenty-five exactly tie the seven-copper finished item")
        check(not A.FindRow(201), "exact fractional vendor invoice does not create an auction ingredient row")

        -- Same reagent, two output plans: AH twenty, vendor one. Partial AH
        -- delivery must not repeatedly spend vendor gold on the AH allocation.
        if legacy then
        A, st, env = fixture(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, name = "A Bandage", target = 1 }, { itemID = 101, name = "B Bandage", target = 1 } }
        st.recipeItems = { [100] = 7, [101] = 7 }
        st.recipes = {
            { recipeID = 1, outputItemID = 100, name = "A Bandage", learned = true, legacy = true,
                quantityMin = 1, reagents = { { itemID = 201, count = 20 } } },
            { recipeID = 2, outputItemID = 101, name = "B Bandage", learned = true, legacy = true,
                quantityMin = 1, reagents = { { itemID = 201, count = 1 } } },
        }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 2 } }
        local first, second = Book(legacy, 201, 10, 1, true, 55), Book(legacy, 201, 10, 1, true, 56)
        first.offers[2] = second.offers[1]
        st.books = { [100] = Book(legacy, 100, 1, 100), [101] = Book(legacy, 101, 1, 100), [201] = first }
        A.Settings().allowExcessStacks = true
        F = Followup(st, env)
        Open(A, st)
        check(A.craftPlans[100] and not A.craftPlans[100].vendorItems[201] and not A.craftPlans[101],
            "old AH prepares the first selected recipe's auction inputs before planning the next output")
        check(A.FindRow(201).target == 20 and A.offer.quantity == 10,
            "only the twenty auction-selected units enter the merged material target")
        local function BuyListing()
            local id = A.offer.auctionID
            st.press()
            table.remove(st.books[201].offers, 1)
            if legacy then st.legacyReceipt() else st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", id) end
            st.drain()
        end
        BuyListing(); st.bags[201] = 10; F.Refresh()
        check(A.craftPlans[100] and not A.craftPlans[100].vendorItems[201] and A.craftPlans[101].vendorItems[201],
            "next per-item preparation preserves shared recipes' distinct actual-invoice routes")
        check(F.GetState().kind == "waiting" and F.GetState().items[201] == 10,
            "partial auction delivery waits for its other ten without substituting vendor purchases")
        local buys = 0
        env.FluxVendorAuto.DoAuctionFollowup = function(manual)
            check(st.hardware and manual == true and F.GetVendorTargets()[201] == 1,
                "HUD delegates only the scoped physical vendor requirement on its press")
            buys = buys + 1; st.bags[201] = st.bags[201] + 1
        end
        st.emit("MERCHANT_SHOW"); st.hardware = true; F.Click(); st.hardware = false
        check(buys == 0 and F.GetState().kind == "waiting", "vendor interaction cannot override incomplete AH provenance")
        BuyListing(); st.bags[201] = 20; F.Refresh()
        check(F.GetState().kind == "vendor" and F.GetState().items[201] == 1,
            "complete twenty AH items expose only the single vendor-chosen requirement")
        st.hardware = true; F.Click(); st.hardware = false
        check(buys == 1 and F.GetState().kind == "craft" and F.GetState().task.parentID == 100,
            "one vendor purchase prepares the first exact output recipe")
        local crafted = {}
        F.CraftClick = function(task)
            check(st.hardware and task.operations == 1, "each chosen output recipe needs a separate press")
            crafted[#crafted + 1] = task.parentID
            st.bags[201] = st.bags[201] - task.required[201]
            st.bags[task.parentID] = 1
            return "crafting", 1
        end
        st.hardware = true; F.Click(); st.hardware = false
        check(#crafted == 1 and crafted[1] == 100 and F.GetState().task.parentID == 101 and buys == 1,
            "first recipe consumes its twenty and prepares the other recipe without another action")
        st.hardware = true; F.Click(); st.hardware = false
        check(#crafted == 2 and crafted[2] == 101 and st.bags[201] == 0 and not F.GetState(),
            "the final one-item recipe completes the shared chosen-route job exactly")
        end
    end end
end
print(("Auction restock vendor routes: %d checks PASS; %d client/addon profiles; native price/stack/vendor/craft permissions NOT RUN"):format(checks, profiles))
