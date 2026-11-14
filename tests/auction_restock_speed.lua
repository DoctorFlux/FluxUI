-- Actual queue/native-call fixtures: work counts and gestures, not native latency.
local checks, profiles = 0, 0
local metricsOnly = FLUX_AH_SPEED_METRICS_ONLY == true
local function check(value, label) checks = checks + 1; assert(value, label) end
local function Export(path, flag)
    local env = setmetatable({ [flag] = true }, { __index = _G })
    local chunk = assert(loadfile(path, "t", env)); if setfenv then setfenv(chunk, env) end
    return chunk()
end
local fixture = Export("tests/auction_restock.lua", "FLUX_AH_FIXTURE_EXPORT")
local potions = not metricsOnly and Export("tests/auction_restock_potions.lua", "FLUX_AH_POTIONS_FIXTURE_EXPORT")
local function Queries(st) return (st.calls.search or 0) + (st.calls.legacySearch or 0) end
local function Buys(st) return (st.calls.confirm or 0) + (st.calls.buyStack or 0) + (st.calls.buyItem or 0) end
local function Book(legacy, id, quantity, unit)
    return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = quantity, total = quantity * unit } }
        or { { itemID = id, quantity = quantity, unitPrice = unit } } }
end
local function Direct(legacy, auctionator, syndicator, count)
    local A, st, env = fixture(legacy, auctionator, syndicator)
    st.entries, st.books = {}, {}
    for id = 100, 99 + (count or 3) do
        st.entries[#st.entries + 1] = { itemID = id, name = tostring(id), target = 1 }
        st.books[id] = Book(legacy, id, 1, 5)
    end
    return A, st, env
end
local function Open(A, st) st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain() end
local function Complete(st, legacy, unit, total)
    if legacy then st.legacyReceipt()
    else st.emit("COMMODITY_PRICE_UPDATED", unit or 5, total or 5); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
    st.drain()
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        for trial = 1, metricsOnly and 3 or 1 do
            local A, st = Direct(legacy, auctionator, syndicator)
            Open(A, st)
            local initial = Queries(st)
            if not metricsOnly then
                check(initial == 1 and A.offer and A.offer.itemID == 100 and not st.searchedIDs[101] and not st.searchedIDs[102],
                    "first ready queries only the next SKU and reuses its owned native result")
            end
            for id = 100, 102 do
                check(A.offer and A.offer.itemID == id and Buys(st) == id - 100,
                    "ACK prepares the next distinct purchase without a Scan press")
                st.press(); Complete(st, legacy)
                check(Buys(st) == id - 99, "one hardware press submits exactly one transaction")
            end
            if metricsOnly then
                print(("METRIC %s %s %s %d %d %d 3 %d"):format(client, tostring(auctionator), tostring(syndicator),
                    trial, initial, Queries(st), Buys(st)))
            else check(Queries(st) == 3 and Buys(st) == 3, "three-item chain uses three native item queries and three player presses") end
        end
        if not metricsOnly then
            local coldA, coldState = Direct(legacy, auctionator, syndicator)
            coldState.throttle = false; coldState.emit("AUCTION_HOUSE_SHOW"); coldA.Toggle(); coldState.result()
            check(Queries(coldState) == 0 and not coldA.offer and coldA.state == "searching" and Buys(coldState) == 0,
                "unsolicited results while throttled cannot create owned readiness before a native query is sent")
            coldState.throttle = true; coldState.advance(0.4); coldState.drain()
            check(Queries(coldState) == 1 and coldA.offer and coldA.offer.itemID == 100,
                "the first actual owned query supplies readiness once the existing throttle gate opens")
            local A, st, env = Direct(legacy, auctionator, syndicator, 80)
            Open(A, st); st.emit("BAG_UPDATE_DELAYED"); st.drain(); A.Select(179)
            check(Queries(st) == 1 and not st.searchedIDs[101] and A.offer.itemID == 100,
                "unchanged stock events and price-editor selection do not rescan the remaining list")
            st.advance(30); st.press(); st.drain()
            check(Queries(st) == 2 and Buys(st) == 0 and A.offer.itemID == 100,
                "an expired ready result refreshes only its current SKU without spending the preparation gesture")

            A, st, env = Direct(legacy, auctionator, syndicator)
            A.SetMaxPrice(100, 0, false); Open(A, st)
            check(A.offer.itemID == 101 and not st.searchedIDs[100] and not st.searchedIDs[102] and Queries(st) == 1,
                "an explicit zero cap skips paid queries and prepares the next allowed SKU")

            A, st, env = Direct(legacy, auctionator, syndicator)
            Open(A, st)
            if legacy then env.QueryAuctionItems("Item102", nil, nil, 0, false, nil, false, true)
            else env.C_AuctionHouse.SendSearchQuery(env.C_AuctionHouse.MakeItemKey(102), {}, true) end
            st.press(); st.drain()
            check(Buys(st) == 0 and Queries(st) == 3 and A.offer and A.offer.itemID == 100,
                "a competing query revokes native-result reuse and one press reclaims only read-only preparation")

            A, st, env = Direct(legacy, auctionator, syndicator)
            st.entries[1].name = "A output"; st.entries[2].name = "B unrelated"; st.entries[3].name = "C unrelated"
            st.recipeItems = { [100] = true }
            st.recipes = { { recipeID = 700, outputItemID = 100, name = "Recipe", learned = true, legacy = true,
                quantityMin = 1, reagents = { { itemID = 200, count = 1 } } } }
            st.books[100], st.books[200] = Book(legacy, 100, 1, 100), Book(legacy, 200, 1, 5)
            Open(A, st)
            check(A.craftPlans[100] and A.offer.itemID == 200 and Queries(st) == 2
                and not st.searchedIDs[101] and not st.searchedIDs[102],
                "the current recipe prices only output and actual input then prepares its input before unrelated names")

            if legacy then
                A, st = Direct(legacy, auctionator, syndicator); Open(A, st)
                st.offers[1].total = 7; st.press(); st.drain()
                check(Buys(st) == 0 and Queries(st) == 2 and A.offer.total == 7,
                    "changed legacy index identity triggers automatic fresh preparation without spending")
                st.press(); check(Buys(st) == 1, "buying the refreshed whole legacy lot requires its own subsequent press")
            else
                A, st, env = Direct(legacy, auctionator, syndicator, 1)
                st.entries[1].target = 2
                st.books[100] = { commodity = false, offers = { { itemKey = env.C_AuctionHouse.MakeItemKey(100),
                    auctionID = 501, quantity = 2, buyoutAmount = 5 } } }
                Open(A, st); st.press()
                st.books[100].offers[1].auctionID = 502; st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 501); st.drain()
                check(st.calls.buyItem == 1 and Queries(st) == 2 and A.offer.auctionID == 502 and A.offer.quantity == 1,
                    "grouped-item ACK invalidates the purchased SKU and queries its next real auction ID without bidding")
                st.press(); check(st.calls.buyItem == 2, "the second grouped item needs a distinct physical press")

                for _, failure in ipairs({ "price", "unavailable" }) do
                    A, st = Direct(false, auctionator, syndicator, 2)
                    A.SetMaxPrice(100, 5); Open(A, st); st.press()
                    if failure == "price" then st.emit("COMMODITY_PRICE_UPDATED", 6, 6)
                    else st.emit("COMMODITY_PRICE_UNAVAILABLE") end
                    st.drain()
                    check(st.calls.quote == 1 and Buys(st) == 0 and not A.intent and A.offer.itemID == 101,
                        "failed quote prepares another SKU without a second gesture or purchase call")
                    A.offer = nil; A.state = "idle"; st.press(); st.drain()
                    check(st.calls.quote == 1 and A.offer.itemID == 100,
                        "an explicit preparation press can retry the rejected quantity without spending")
                    st.press()
                    if failure == "price" then st.emit("COMMODITY_PRICE_UPDATED", 6, 6)
                    else st.emit("COMMODITY_PRICE_UNAVAILABLE") end
                    st.drain(); st.advance(30); A.ScanQueue(); st.drain()
                    check(st.calls.quote == 2 and Buys(st) == 0 and A.offer.itemID == 100,
                        "a rejected quote expires at thirty seconds and becomes eligible for read-only preparation")
                end
            end

            local best
            A, st, env, best = potions(legacy, auctionator, syndicator)
            Open(A, st)
            check(A.offer and A.offer.itemID == 201 and best.GetBestRef("manaPotion").itemID == 300
                and (st.calls.potionBrowse or st.calls.legacyPotionSearch) == 2,
                "both potion cell choices are gathered once despite the changed sort name")
            st.press(); Complete(st, legacy, 80, 1600)
            check(A.offer and A.offer.itemID == 300 and (st.calls.potionBrowse or st.calls.legacyPotionSearch) == 2,
                "the later mana purchase reuses its own fresh catalogue rather than rescanning")

            A, st, env, best = potions(legacy, auctionator, syndicator)
            st.uncached[201] = true; Open(A, st)
            check(A.offer and A.offer.itemID == 300 and A.PotionRowBlocked({ tierKind = "healPotion", itemID = 100 }),
                "an unresolved healing kind stays blocked while its metadata cannot poison a mana-only job")

            A, st, env, best = potions(legacy, auctionator, syndicator)
            best.Persist.GetRoot().refs = {}; Open(A, st)
            check(A.offer and A.offer.itemID == 203 and best.GetBestRef("manaPotion").itemID == 301
                and (st.calls.potionBrowse or st.calls.legacyPotionSearch) == 2,
                "targets without remembered SKUs receive independent cell choices without full list pricing")
        end
    end end
end
if not metricsOnly then print(("Auction on-demand speed: %d checks PASS; %d profiles; native latency/input/taint NOT RUN"):format(checks, profiles)) end
