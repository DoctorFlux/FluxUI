-- Real AH queue and controls: hidden vendor probes may prepare a strict bargain,
-- but purchases/quotes still belong to each physical player press.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local chunk = assert(loadfile(root .. "/tests/auction_restock.lua", "t", export))
if setfenv then setfenv(chunk, export) end
local fixture = chunk()
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env = fixture(legacy, auctionator, syndicator)
        if auctionator then env.Auctionator = { API = { v1 = {
            GetAuctionPriceByItemID = function(caller) check(caller == "_FluxUI", "optional hint uses public caller ID"); return 1 end,
        } } } end
        local function PurchaseCalls()
            return (st.calls.quote or 0) + (st.calls.confirm or 0) + (st.calls.buyStack or 0) + (st.calls.buyItem or 0)
        end
        local function SearchCalls() return (st.calls.search or 0) + (st.calls.legacySearch or 0) end
        local function Offers(price)
            return legacy and { { itemID = 100, quantity = 2, total = price } }
                or { { itemID = 100, quantity = 20, unitPrice = price, numOwnerItems = 0 } }
        end
        local function Open(offers, opts)
            opts = opts or {}
            st.reset()
            st.entries = { { itemID = 100, name = "Vendor target", target = 2, restockSource = "spellReagent" } }
            st.settings.merchantSources = { [100] = { unlimited = true, unitPrice = opts.vendorPrice or 3 } }
            st.offers, st.bags[100] = offers, opts.bags or 0
            A.Settings().allowExcessStacks = opts.excess == true
            local cap = opts.cap or 0
            A.SetMaxPrice(100, cap)
            check(A.GetMaxPrice(100) == cap and A.PurchaseLimit(100) == (cap == 0 and math.huge or cap),
                "player cap retains its meaning before native vendor comparison")
            check(not A.FindRow(100, true) and #A.GetVendorScanRows() == 1,
                "vendor target is hidden but retained for native probing before prices arrive")
            if opts.history then
                local hint = A.MarketPrice(100)
                check((not auctionator or hint == 1) and A.IsVendorItem(100),
                    "historical bargain does not admit a vendor target before a native scan")
            end
            st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
            check((opts.bags == 2 and SearchCalls() == 0 or opts.bags ~= 2 and SearchCalls() > 0) and PurchaseCalls() == 0 and not A.transaction,
                "opening the tab probes vendor candidates without any buying action")
        end
        local function Finish()
            if legacy then st.legacyReceipt() else st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
            st.drain()
        end

        Open(Offers(legacy and 5 or 2))
        check(A.FindRow(100, true) and not A.IsVendorItem(100) and A.HasUnlimitedVendor(100)
            and A.VendorPrice(100) == 3 and A.state == "ready" and A.offer.quantity == 2,
            "native strict discount automatically admits the hidden vendor row and prepares its exact shortage")
        st.press()
        if legacy then
            check(st.calls.buyStack == 1 and A.transaction and A.transaction.quantity == 2
                and A.transaction.units == 2, "one legacy press buys the complete two-item fractional-unit bargain")
        else
            check(st.calls.quote == 1 and not st.calls.confirm and st.authorizedQuote.quantity == 2,
                "one modern press starts only the exact player-authorized commodity quote")
            st.emit("COMMODITY_PRICE_UPDATED", 2, 4)
            check(st.calls.confirm == 1 and A.transaction and A.transaction.quantity == 2,
                "strictly cheaper live quote confirms the same two-item purchase")
            st.emit("COMMODITY_PRICE_UPDATED", 2, 4)
            check(st.calls.confirm == 1, "repeated quote event cannot confirm another purchase")
        end
        local before = PurchaseCalls()
        st.press()
        check(PurchaseCalls() == before, "in-flight purchase blocks another press from duplicating its batch")
        Finish()
        check(A.Settings().pending[100] and A.Settings().pending[100].accepted
            and A.Settings().pending[100].units == 2, "acknowledged vendor bargain reserves exactly the purchased physical quantity")
        st.press(); st.drain()
        check(PurchaseCalls() == before, "fulfilled pending target never buys a second vendor bargain")

        if not legacy then
            for _, total in ipairs({ 6, 5 }) do
                Open(Offers(2)); st.press()
                st.emit("COMMODITY_PRICE_UPDATED", 3, total)
                check(st.calls.quote == 1 and not st.calls.confirm and not A.transaction
                    and A.status == "overCap" and not A.Settings().pending[100],
                    "quote reaching vendor highest unit price is rejected even with unlimited user cap")
                check((st.calls.cancel or 0) > 0, "rejected player quote is cancelled rather than purchased")
            end
            Open({ { itemID = 100, quantity = 1, unitPrice = 4, numOwnerItems = 0 },
                { itemID = 100, quantity = 20, unitPrice = 6, numOwnerItems = 0 } }, { vendorPrice = 10, cap = 9 })
            st.press()
            check(A.intent and A.intent.cap == 9 and A.offer.unitPrice == 6,
                "mixed-price native book captures a quote below the old vendor benchmark and explicit cap")
            st.settings.merchantSources[100].unitPrice = 5
            check(not A.IsVendorItem(100), "a remaining cheap tier keeps the row eligible after learning a lower vendor benchmark")
            st.emit("COMMODITY_PRICE_UPDATED", 6, 12)
            check(not st.calls.confirm and not A.transaction and A.status == "overCap",
                "new lower vendor benchmark rejects a quote still below its captured explicit price cap")
        else
            Open(Offers(5))
            check(A.priceBooks[100].offers[1].total == 5, "tamper regression retains independent old cheap probe book")
            st.offers[1].total, A.offer.total = 6, 6
            check(not A.IsVendorItem(100) and A.priceBooks[100].offers[1].total == 5,
                "old cheap book keeps the row eligible while both prepared/native listings now match the vendor price")
            st.press()
            check(not st.calls.buyStack and A.status == "overCap" and not A.transaction,
                "actual whole-stack vendor comparison rejects equal cost before the matching legacy identity check")

            Open({ { itemID = 100, quantity = 2, total = 6 },
                { itemID = 100, quantity = 3, total = 8 }, { itemID = 100, quantity = 4, total = 9 } }, { excess = true })
            check(A.offer and A.offer.quantity == 3 and A.offer.total == 8,
                "filtered legacy offers exclude vendor-priced exact fit and retain the smallest authorized cheap excess listing")
            st.press()
            check(st.calls.buyStack == 1 and A.transaction.quantity == 3,
                "cheap legacy excess listing remains one complete listing per player press")
            Finish()
            check(A.Settings().pending[100].units == 3, "legacy surplus receipt records the whole bought listing")
        end

        for _, price in ipairs(legacy and { 6, 7 } or { 3, 4 }) do
            Open(Offers(price))
            check(not A.FindRow(100, true) and A.IsVendorItem(100) and not A.offer and #A.GetRows(false) == 0,
                "equal and above-vendor native prices leave the vendor target hidden after a complete scan")
            st.press(); st.drain()
            check(PurchaseCalls() == 0, "hidden vendor-priced target cannot initiate a purchase")
        end
        Open(legacy and { { itemID = 100, quantity = 2, total = 2, owned = true } }
            or { { itemID = 100, quantity = 2, unitPrice = 1, numOwnerItems = 2 } })
        check(not A.FindRow(100, true) and A.IsVendorItem(100) and not A.offer,
            "a cheap wholly owned native listing cannot admit the vendor row")
        Open({}, { history = true })
        check(not A.FindRow(100, true) and A.IsVendorItem(100) and not A.offer,
            "cheap optional history plus empty native results cannot admit the vendor row")

        Open(Offers(legacy and 5 or 2), { bags = 2 })
        check(not A.priceBooks[100] and not A.FindRow(100, true) and not A.offer,
            "a full vendor target is neither probed nor admitted by an all-item price scan")
        st.press(); st.drain()
        check(PurchaseCalls() == 0, "full carried stock never buys even below vendor price")

        Open(Offers(legacy and 5 or 2))
        local searches = SearchCalls()
        st.time = st.time + 30.01
        st.offers = Offers(legacy and 6 or 3)
        st.press()
        check(SearchCalls() > searches and PurchaseCalls() == 0 and not A.transaction,
            "pressing an expired bargain first performs a new read and never buys from its stale book")
        st.drain()
        check(not A.FindRow(100, true) and A.IsVendorItem(100) and not A.offer and A.priceBooks[100].at == st.time,
            "fresh non-discount result replaces stale admission and keeps the vendor row hidden")
        check(A.GetMaxPrice(100) == 0 and #st.errors == 0, "native queue price checks preserve player cap and produce no modeled Lua errors")
        if legacy then
            st.reset()
            st.entries = { { itemID = 100, name = "Cold vendor target", target = 2, restockSource = "spellReagent" },
                { itemID = 101, name = "Usable target", target = 1, restockSource = "manual" } }
            st.settings.merchantSources = { [100] = { unlimited = true, unitPrice = 3 } }
            st.books = { [100] = { commodity = false, offers = Offers(5) },
                [101] = { commodity = false, offers = { { itemID = 101, quantity = 1, total = 1 } } } }
            local name = env.FluxItemClass.GetName
            env.FluxItemClass.GetName = function(id) if id ~= 100 then return name(id) end end
            A.SetMaxPrice(100, 0); A.SetMaxPrice(101, 0)
            st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
            check(A.state == "ready" and A.offer and A.offer.itemID == 101 and st.searchedIDs[101] == 1,
                "cold hidden legacy vendor metadata cannot abort normal pricing and preparation of the next usable item")
            check(not st.searchedIDs[100] and not A.priceBooks[100] and not A.FindRow(100, true)
                and #A.GetVendorScanRows() == 1 and PurchaseCalls() == 0,
                "unsearchable vendor stays hidden without an extra query or purchase while the ordinary item is ready")
            env.FluxItemClass.GetName = name
            st.bags[101] = 1
            st.press(); st.drain()
            check(st.searchedIDs[100] and A.priceBooks[100] and A.FindRow(100, true) and PurchaseCalls() == 0,
                "the next per-item preparation probes the vendor after the preceding item is full and its name becomes available")
        end
        st.reset()
    end end
end
print(("Auction vendor opportunity queue: %d checks PASS; %d profiles; native purchasing/taint/provider coexistence NOT RUN"):format(checks, profiles))
