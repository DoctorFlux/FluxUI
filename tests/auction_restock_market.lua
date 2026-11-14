-- Latest native screenshot regressions; independent optional price DB fixture.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local chunk = assert(loadfile("tests/auction_restock.lua", "t", export)); if setfenv then setfenv(chunk, export) end
local fixture = chunk()
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env = fixture(legacy, auctionator, syndicator)
        local reads, writes, notices, prices = {}, {}, 0, { [100] = 999 }
        if auctionator then
            env.Auctionator = {
                API = { v1 = { GetAuctionPriceByItemID = function(caller, id)
                    check(caller == "_FluxUI", "public API identifies the calling addon")
                    reads[id] = (reads[id] or 0) + 1; return prices[id]
                end } },
                Database = { SetPrice = function(_, key, price, available)
                    writes[key] = { price = price, available = available }; prices[tonumber(key)] = price
                end },
                EventBus = { Fire = function(_, sender, event)
                    check(sender == A and event == "prices", "price notification uses the addon event contract")
                    notices = notices + 1
                end },
                Search = { Events = { PricesProcessed = "prices" } },
                IncrementalScan = { Events = { PricesProcessed = "prices" } },
            }
        end
        st.entries, st.books = {}, {}
        for id = 100, 129 do
            st.entries[#st.entries + 1] = { itemID = id, name = "Item" .. id, target = 20 }
            st.bags[id] = 18
            st.books[id] = { commodity = not legacy, offers = legacy and { { itemID = id, quantity = 20, total = 400 }, { itemID = id, quantity = 4, total = 40 } }
                or { { itemID = id, quantity = 20, unitPrice = 20 }, { itemID = id, quantity = 4, unitPrice = 10 } } }
        end
        st.settings.itemPrices, st.settings.vendorItems = { [103] = 1, [104] = 1, [105] = 1 }, { [103] = true, [104] = true, [105] = true }
        st.settings.merchantSources = { [103] = { limited = true, lastAvailable = 1 }, [104] = { unlimited = true, unitPrice = 1 } }
        if legacy then A.Settings().allowExcessStacks = true end -- four-item listing can fill the two-item shortage
        st.reliable = false; st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.reliable = true
        if legacy then st.press() else st.press(A.frame.refresh) end; st.drain()
        check(A.frame.cols == 8 and A.frame.gridRows == 4 and A.frame.scroll.scrollChild == A.frame.content
            and A.frame.pageSize == nil and A.frame.prev == nil and A.frame.next == nil,
            "compact full-width grid shows four ordinary rows and scrolls the full list without pagination")
        check(A.frame.detailsText == nil and A.frame.detailsScroll == nil, "recipe/cost pane no longer exists")
        for id = 100, 129 do
            if legacy then
                check(st.searchedIDs[id] == (id == 100 and 1 or nil),
                    "old AH prepares only its next missing item without a whole-list price scan: " .. id .. "=" .. tostring(st.searchedIDs[id]))
                check(id == 100 and A.priceBooks[id] and A.priceBooks[id].minPrice == 10
                    or id ~= 100 and not A.priceBooks[id], "old AH leaves later item prices unqueried")
                if auctionator then check(id == 100 and writes[tostring(id)] and writes[tostring(id)].price == 10
                    or id ~= 100 and not writes[tostring(id)], "old AH writes only its prepared item's live price to Auctionator") end
            else
            if id ~= 104 then
                check(st.searchedIDs[id] == (id == 100 and not legacy and 2 or 1), "missing-item scan/preparation count: " .. client .. "/" .. id .. "=" .. tostring(st.searchedIDs[id]))
                check(A.priceBooks[id] and A.priceBooks[id].minPrice == 10, "complete book records lowest per-unit market price")
                if auctionator then check(reads[id] == 1 and writes[tostring(id)].price == 10 and writes[tostring(id)].available == 24, "Auctionator read and write-back use exact complete scan data") end
            else check(st.searchedIDs[id] == 1 and not A.FindRow(id), "unlimited supply is probed for discounts but stays hidden when auctions are dearer") end
            end
        end
        check(not st.calls.quote and not st.calls.buyStack and not st.calls.confirm, "scanning missing-item prices never purchases without a press")
        check(not auctionator or notices == 1, "all database writes coalesce into one price-change notification")
        if not legacy then
            local grouped = { itemID = 999, commodity = false, at = st.now or 0, offers = {
                { quantity = 1, availableQuantity = 2, total = 100 },
                { quantity = 1, availableQuantity = 3, total = 120 },
            } }
            A.PublishPriceBook(grouped)
            check(grouped.available == 5 and grouped.minPrice == 100,
                "modern market availability counts the groups while unit price stays per purchased copy")
            if auctionator then check(writes["999"].available == 5 and writes["999"].price == 100,
                "Auctionator receives grouped market availability without multiplying a one-item purchase") end
        end
        check(not A.IsVendorItem(103) and not A.IsVendorItem(105), "limited stock and untyped price-only witness remain auction eligible")
        check(A.RouteText(A.FindRow(100)) == "Direct" and A.frame.cells[1].route.text == "Direct", "each item has a compact route label")
        st.entries[#st.entries + 1] = { itemID = 130, name = "Unlisted", target = 2 }
        st.books[130] = { commodity = not legacy, offers = {} }; prices[130] = 777
        if legacy then
            for id = 100, 129 do st.bags[id] = 20 end
            st.press() -- the former item is now full; prepare the next actual shortage
        else st.press(A.frame.refresh) end
        st.drain()
        check(st.searchedIDs[130] == 1 and A.priceBooks[130] and not A.priceBooks[130].minPrice, "empty live result remains a valid completed listed-item scan")
        if auctionator then
            local price, source = A.MarketPrice(130)
            check(not writes["130"] and price == 777 and source == "Auctionator", "missing live offers preserve Auctionator history for display only")
            check(not st.calls.quote and not st.calls.buyStack, "historical fallback never authorizes a purchase")
        end

        -- The pictured phantom reservation: old attempt with no receipt/mail.
        st.reset(); st.entries = { { itemID = 100, name = "Feather", target = 20 } }; st.bags[100] = 19
        st.settings.auctionRestock = { pending = { [100] = { units = 1, bagCount = 19, totalCount = 19 } } }
        st.books = { [100] = { commodity = not legacy, offers = legacy and { { itemID = 100, quantity = 1, total = 5 } }
            or { { itemID = 100, quantity = 1, unitPrice = 5 } } } }
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        check(A.FindRow(100).pending == 0 and A.FindRow(100).need == 1 and A.offer.quantity == 1, "stale unacknowledged saved attempt cannot block the missing feather")
        check(A.frame.cells[1].incoming.text == "", "no Pending1 label when no confirmed incoming item exists")
        st.press()
        if legacy then
            st.emit("AUCTION_ITEM_LIST_UPDATE")
            check(A.transaction ~= nil and not A.Settings().pending[100].accepted, "list mutation is not a legacy purchase receipt")
            st.legacyReceipt()
        else st.emit("COMMODITY_PRICE_UPDATED", 5, 5); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        check(A.Settings().pending[100].accepted and A.FindRow(100).pending == 1, "actual acknowledgement marks exactly one incoming feather")
        st.press(); check((st.calls.confirm or st.calls.buyStack) == 1, "acknowledged incoming still prevents a duplicate purchase")

        -- A remembered limited herb is an auction reagent, not a guaranteed vendor input.
        st.reset(); st.recipeItems = { [100] = true }; st.entries = { { itemID = 100, name = "Potion", target = 2 } }
        st.recipes = { { recipeID = 1, outputItemID = 100, name = "Limited herb recipe", learned = true, legacy = true, quantityMin = 1,
            reagents = { { itemID = 200, count = 1 }, { itemID = 201, count = 1 } } } }
        st.settings.itemPrices, st.settings.vendorItems = { [200] = 1, [201] = 2 }, { [200] = true, [201] = true }
        st.settings.merchantSources = { [200] = { limited = true, lastAvailable = 1 }, [201] = { unlimited = true, unitPrice = 2 } }
        local function Book(id, q, price)
            return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = q, total = q * price } }
                or { { itemID = id, quantity = q, unitPrice = price } } }
        end
        st.books = { [100] = Book(100, 2, 100), [200] = Book(200, 2, 10) }
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        check(A.craftPlans[100] and A.craftPlans[100].cost == 24 and A.offer.itemID == 200 and A.offer.quantity == 2,
            "limited/unknown merchant herb uses actual auction material cost and full shortage")
        check(A.FindRow(200) and not A.FindRow(201) and st.searchedIDs[200] >= 1 and st.searchedIDs[201] >= 1,
            "vendor ingredients are compared read-only and stay out of the buy list without a discount")

        -- Dynamic native merchant metadata; no name/ID exception catalogue.
        st.reset(); st.realTargets()
        env.FluxRestockList.RecordMerchantPrices({ [100] = { unitPrice = 2, numAvailable = 1 },
            [101] = { unitPrice = 3, numAvailable = -1 }, [102] = { unitPrice = 0, numAvailable = -1, hasExtendedCost = true } })
        check(not A.IsVendorItem(100) and A.IsVendorItem(101) and not A.IsVendorItem(102), "only unlimited purchasable gold/free supply counts as guaranteed vendor stock")
        check(st.settings.merchantSources[100].limited and st.settings.merchantSources[100].lastAvailable == 1 and A.VendorPrice(101) == 3,
            "limited availability and exact unlimited buy price are remembered separately")
        check(A.IsFoodWater({ isTierRestock = true, tierKind = "food" }) and A.IsFoodWater({ isTierRestock = true, tierKind = "water" }),
            "food/water tier targets are excluded without requiring item metadata")
        local subclass = env.FluxItemClass.GetSubClassID
        env.FluxItemClass.GetSubClassID = function(id) return id == 100 and 5 or subclass(id) end
        check(not A.FindRow(100, true) and A.FindRow(102), "manual food/drink items are excluded by taxonomy while other restock targets remain")
        check(#st.errors == 0, "market/grid/source paths emit no modeled API exceptions")
    end end
end
print(("Auction dense grid/stock/price bridge: %d checks PASS; %d profiles; native pixels/vendor coverage/coexistence NOT RUN"):format(checks, profiles))
