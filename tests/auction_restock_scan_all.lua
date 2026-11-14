-- Modern explicit scans price every listed item; old AH prepares one purchase.
-- Real queue, UI callbacks, price bridge and persisted tier owners; no native operation.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function Export(file, flag)
    local env = setmetatable({ [flag] = true }, { __index = _G })
    local source = assert(loadfile(file, "t", env)); if setfenv then setfenv(source, env) end
    return source()
end
local fixture = Export("tests/auction_restock.lua", "FLUX_AH_FIXTURE_EXPORT")
local potions = Export("tests/auction_restock_potions.lua", "FLUX_AH_POTIONS_FIXTURE_EXPORT")
local sources = Export("tests/auction_restock_sources.lua", "FLUX_AH_SOURCES_FIXTURE_EXPORT")
local function Book(legacy, id, quantity, price)
    return { commodity = not legacy, offers = legacy
        and { { itemID = id, quantity = quantity, total = quantity * price } }
        or { { itemID = id, quantity = quantity, unitPrice = price } } }
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st = fixture(legacy, auctionator, syndicator)
        st.entries = {
            { itemID = 100, name = "Missing", target = 3 },
            { itemID = 101, name = "Full", target = 10 },
            { itemID = 102, name = "Disabled", target = 0 },
            { itemID = 201, name = "Full vendor", target = 4 },
        }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 10 } }
        st.bags[100], st.bags[101], st.bags[201] = 1, 10, 4
        st.books = { [100] = Book(legacy, 100, 2, 10), [101] = Book(legacy, 101, 20, 10),
            [102] = Book(legacy, 102, 20, 10), [201] = Book(legacy, 201, 20, 1) }
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        check(st.searchedIDs[100] and not st.searchedIDs[101], "automatic queue recovery remains scoped to actual shortages")
        if legacy then
            check(A.frame.refresh == nil, "the old auction house allocates no Scan all restock control")
            A.ScanQueue(true, true); st.drain()
            check(st.searchedIDs[100] == 1 and not st.searchedIDs[101] and not st.searchedIDs[102] and not st.searchedIDs[201]
                and not A.priceBooks[101] and not A.priceBooks[201],
                "an old full-scan request remains one owned current-item query without full/disabled/vendor background scans")
            st.entries[#st.entries + 1] = { itemID = 103, name = "Next item", target = 1 }
            st.books[103] = Book(true, 103, 1, 4)
            check(A.offer and A.offer.itemID == 100 and A.offer.quantity == 2 and not st.calls.buyStack,
                "old-AH preparation readies one fitting stack without spending the scan gesture")
            st.press()
            check(st.calls.buyStack == 1 and A.transaction and not st.searchedIDs[103],
                "one old-AH Buy press issues one listing and waits for its actual receipt before the next scan")
            st.legacyReceipt(); st.drain()
            check(A.offer and A.offer.itemID == 103 and A.offer.quantity == 1 and st.searchedIDs[103] == 1 and st.calls.buyStack == 1,
                "a receipt prepares only the next missing item without another scan press or an automatic purchase")
            st.press(); st.legacyReceipt(); st.drain()
            check(st.calls.buyStack == 2 and A.Settings().pending[100].units == 2 and A.Settings().pending[103].units == 1
                and not st.searchedIDs[101] and not st.searchedIDs[102] and not st.searchedIDs[201],
                "a second item requires a second physical press and completed targets remain unscanned")
            local best, Start
            A, st, _, best, Start = potions(true, auctionator, syndicator)
            st.bags[100], st.bags[101] = 19, 19
            Start(); A.ScanQueue(true, true); st.drain()
            check(best.GetBestRef("healPotion").itemID == 201 and best.GetBestRef("manaPotion").itemID == 300
                and st.calls.legacyPotionSearch == 2 and A.offer and A.offer.itemID == 201,
                "old-AH missing potion upgrades are gathered together without full-restock price scanning")
            st.bags[100], st.generation = 19, st.generation + 1
            st.emit("BAG_UPDATE_DELAYED"); st.drain()
            check(best.GetBestRef("healPotion").itemID == 201 and best.GetBestRef("manaPotion").itemID == 300
                and A.offer and A.offer.itemID == 201 and A.FindRow(201).need == 20 and st.calls.legacyPotionSearch == 2,
                "later weak-stock changes preserve the complete stronger target without rescanning its kind")
            check(not st.calls.buyStack, "old potion discovery still needs a separate Buy press")
        else
        local before = st.searchedIDs[100]
        st.press(A.frame.refresh); st.drain()
        check(st.searchedIDs[100] > before and st.searchedIDs[101] and st.searchedIDs[201] and st.searchedIDs[102],
            "the actual Scan restock button prices all listed items, including full and zero targets and vendor opportunities")
        check(A.priceBooks[101] and A.priceBooks[201], "full-item probes preserve the same price books as shortage searches")
        check(A.offer and A.offer.itemID == 100 and A.offer.quantity == 2 and A.Need(A.FindRow(101)) == 0,
            "full-item prices cannot turn stocked targets into purchases or change their counts")
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack,
            "one scan press never buys an auction, including filled vendor candidates")
        A.offer = nil; A.state = "idle"
        local priced = st.searchedIDs[101]
        st.press(A.frame.primary); st.drain()
        check(st.searchedIDs[101] == priced and not st.calls.quote and not st.calls.confirm and not st.calls.buyStack,
            "the primary fallback prepares only the next shortage without rescanning full rows")

        local best, Start
        A, st, _, best, Start = potions(legacy, auctionator, syndicator)
        st.bags[100], st.bags[101] = 20, 20
        Start()
        check(best.GetBestRef("healPotion").itemID == 201 and best.GetBestRef("manaPotion").itemID == 300,
            "full weaker potion bags do not prevent stronger usable healing and mana discovery")
        check(st.settings.restockCombat.savedHealPotionTier == 600 and st.settings.restockCombat.savedManaPotionTier == 500,
            "discovering stronger potions updates both persisted tiers even when old targets were filled")
        check(A.FindRow(201).need == 20 and A.FindRow(300).need == 20 and A.offer and A.offer.itemID == 201,
            "the stronger tier receives the entire target; weaker stock cannot satisfy it")
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack,
            "automatic tier discovery never reuses a scan gesture to purchase")

        local load, book, recipe, scan
        A, st, _, load, book, recipe, scan = sources(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, name = "Craft output", target = 1 } }
        st.bags[200] = 1
        recipe(100, 200, 1)
        st.books = { [100] = book(100, 20, 100), [200] = book(200, 20, 5) }
        scan(); st.searchedIDs = {}
        st.press(A.frame.refresh); st.drain()
        check(st.searchedIDs[100] == 1 and st.searchedIDs[200] == 1,
            "explicit scans price a free craft output and its newly displayed owned ingredient exactly once")
        check(A.priceBooks[100] and A.priceBooks[200] and A.craftPlans[100] and A.craftPlans[100].cost == 0,
            "read-only prices retain the valid zero-cost owned-material route")
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack,
            "pricing a free craft route never buys its owned ingredient or the finished output")
        st.searchedIDs = {}
        st.press(A.frame.refresh); st.drain()
        check(st.searchedIDs[100] == 1 and st.searchedIDs[200] == 1,
            "a new explicit scan refreshes every listed price despite recent cached books")
        st.bags[200] = 0; A.ResetCraftPlans()
        st.books[100], st.books[200] = book(100, 1, 100), book(200, 1, 5)
        st.press(A.frame.refresh); st.drain()
        check(A.craftPlans[100] and A.craftPlans[100].cost == 5,
            "fresh cheap ingredients select the paid craft route within the output budget")
        st.books[200] = book(200, 1, 200)
        A.offer = nil; A.state = "idle"
        st.press(A.frame.refresh); st.drain()
        check(not A.craftPlans[100] and A.offer and A.offer.itemID == 100,
            "an explicit scan ignores fresh-looking old caches and selects the finished item when ingredients become dearer")
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack,
            "repricing between craft and direct routes never submits a purchase")
        end
    end end
end
print(("Auction all-target scans: %d checks PASS; %d client/provider/addon profiles; native searches/tier updates NOT RUN"):format(checks, profiles))
