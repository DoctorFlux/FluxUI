local export = setmetatable({FLUX_AH_FIXTURE_EXPORT = true}, {__index = _G})
local boot = assert(loadfile("tests/auction_restock.lua", "t", export))()
local checks = 0
local function check(value, label)
    checks = checks + 1
    assert(value, label)
end
local function fixture(legacy)
    local A, st, env = boot(legacy, false, false)
    local result = {calls = 0, writes = 0}
    env.Auctionator = {Database = {SetPrice = function() result.writes = result.writes + 1 end}}
    function result.start(ids)
        return A.ScanLogisticsBooks(ids, function(books, reason)
            result.books, result.reason = books, reason
            result.calls = result.calls + 1
        end)
    end
    st.emit("AUCTION_HOUSE_SHOW")
    return A, st, env, result
end

do
    local A, st, env, result = fixture(false)
    local itemKey = env.C_AuctionHouse.MakeItemKey(101)
    st.books = {
        [100] = {offers = {{quantity = 4, unitPrice = 10, numOwnerItems = 2},
            {quantity = 50, unitPrice = 1, containsAccountItem = true}}},
        [101] = {commodity = false, offers = {
            {itemKey = itemKey, auctionID = 701, quantity = 3, buyoutAmount = 25, itemLink = "copied?"},
            {itemKey = itemKey, auctionID = 702, quantity = 2, buyoutAmount = 29},
            {itemKey = itemKey, auctionID = 703, quantity = 8, buyoutAmount = 1, containsOwnerItem = true},
        }},
    }
    local ok, state = result.start({100, 100, 101})
    check(ok and state == "searching" and st.calls.search == 1, "starts first distinct item")
    local busy, reason = result.start({102})
    check(not busy and reason == "busy", "active depth lease rejects a second scan")
    local entry = {itemID = 100, quantity = 2, kind = "auction", jobId = 1, id = 1, planRevision = "job", maxUnitPrice = 50}
    local queued, queuedReason = A.PrepareLogistics(entry, 2, function() return true end, function() end, true)
    check(not queued and queuedReason == "busy", "accepted purchase preparation cannot replace depth")
    A.ClickPrimary()
    check(not st.calls.quote and not st.calls.buyItem, "owner primary cannot purchase from depth")
    st.fullResults = false
    st.result()
    check(st.calls.moreCommodity == 1 and result.calls == 0, "partial commodity requests another page")
    st.offers[#st.offers + 1] = {itemID = 100, quantity = 20, unitPrice = 15}
    st.fullResults = true
    st.result()
    check(st.calls.search == 2 and result.calls == 0, "second distinct item starts after first full result")
    st.result()
    check(result.calls == 1 and result.reason == nil, "all observed items delivered by one callback")
    local cloth = result.books[100]
    check(cloth.complete and cloth.commodity and cloth.at == st.time and #cloth.offers == 2,
        "commodity depth only includes eligible observed tiers")
    check(cloth.offers[1].quantity == 2 and cloth.offers[1].unitPrice == 10
        and cloth.offers[2].quantity == 20 and cloth.offers[2].unitPrice == 15, "commodity tiers preserve net quantities and prices")
    local bolts = result.books[101]
    check(bolts.complete and not bolts.commodity and #bolts.offers == 2, "grouped modern offers exclude owners")
    check(bolts.offers[1].quantity == 1 and bolts.offers[1].count == 3 and bolts.offers[1].total == 25
        and bolts.offers[2].quantity == 1 and bolts.offers[2].count == 2 and bolts.offers[2].total == 29,
        "modern listing group availability is a count of single bids")
    check(not bolts.offers[1].auctionID and not bolts.offers[1].link and not cloth.offers[1].itemID,
        "the callback does not expose reusable native tokens or raw records")
    st.books[100].offers[1].unitPrice = 3
    check(cloth.offers[1].unitPrice == 10 and not A.priceBooks[100] and result.writes == 0,
        "buyers get copied depth without mutating the owner price cache or Auctionator")
    check(not st.calls.quote and not st.calls.confirm and not st.calls.buyItem and not st.calls.buyStack,
        "no native purchase for a depth scan")
    st.result()
    check(result.calls == 1 and A.state == "idle", "terminal native notifications cannot replay the result")
end

do
    local A, st, _, result = fixture(true)
    local rows = {{itemID = 100, quantity = 2, total = 38}, {itemID = 100, quantity = 8, total = 80, owned = true},
        {itemID = 199, quantity = 3, total = 1}}
    for index = 4, 50 do rows[index] = {itemID = 100, quantity = 4, total = 100} end
    st.books = {
        [100] = {pages = {[0] = rows, [1] = {{itemID = 100, quantity = 9, total = 320}}}, total = 51},
        [101] = {offers = {{itemID = 101, quantity = 1, total = 700}}},
    }
    check(result.start({100, 101}), "legacy exact query starts")
    st.result()
    check(st.page == 1 and st.calls.legacySearch == 2, "legacy follows the exact next page")
    st.result()
    st.result()
    local book = result.books[100]
    check(result.calls == 1 and book.complete and not book.commodity and #book.offers == 49,
        "legacy exact item includes valid stacks across all pages")
    check(book.offers[1].quantity == 2 and book.offers[1].total == 38 and book.offers[1].count == 1
        and book.offers[49].quantity == 9 and book.offers[49].total == 320 and book.offers[49].count == 1,
        "legacy stack quantity and stack buyout stay indivisible")
    check(result.books[101].complete and result.books[101].offers[1].total == 700, "second legacy item is measured")
    check(not st.calls.buyStack and result.writes == 0 and A.state == "idle", "legacy scans are also read-only")
end

do
    local _, st, _, result = fixture(true)
    local page, pages = {}, {}
    for index = 1, 50 do page[index] = {itemID = 100, quantity = 1, total = index} end
    for index = 0, 12 do pages[index] = page end
    st.books = {[100] = {pages = pages, total = 650}}
    check(result.start({100}), "bounded legacy scan starts")
    for _ = 1, 12 do st.result() end
    check(st.calls.legacySearch == 12 and result.calls == 1 and result.reason == "limit",
        "legacy stops after twelve native pages")
    check(not result.books[100].complete and #result.books[100].offers == 600, "truncated legacy is marked incomplete")
end

do
    local _, st, _, result = fixture(false)
    local offers = {}
    for index = 1, 601 do offers[index] = {itemID = 100, quantity = 1, unitPrice = index} end
    st.books = {[100] = {offers = offers}}
    check(result.start({100}), "bounded modern scan starts")
    st.result()
    check(result.calls == 1 and result.reason == "limit" and not result.books[100].complete
        and #result.books[100].offers == 600, "modern depth read is capped and incomplete")
end

do
    local _, st, env, result = fixture(false)
    st.books = {[100] = {offers = {{quantity = 2, unitPrice = 10}}}, [101] = {offers = {}}}
    check(result.start({100, 101}), "first search starts before foreign interruption")
    st.result()
    env.C_AuctionHouse.SendBrowseQuery({})
    check(result.calls == 1 and result.reason == "otherSearch" and result.books[100].complete and not result.books[101],
        "foreign default or Auctionator search yields without inventing an item book")
    st.result()
    check(result.calls == 1 and not st.calls.quote, "foreign results cannot revive the canceled authority")
end

do
    local _, st, env, result = fixture(false)
    st.books = {[100] = {offers = {{quantity = 2, unitPrice = 10}}}}
    env.C_AuctionHouse.HasFullCommoditySearchResults = nil
    check(result.start({100}), "partial-capability search starts")
    st.result()
    check(result.calls == 1 and result.reason == "incomplete" and not result.books[100].complete,
        "unspecified result completeness cannot certify exact depth")
    check(result.start({100}), "idle lease can be reused by next explicit request")
    st.combat = true
    st.result()
    check(result.calls == 2 and result.reason == "combat" and not result.books[100], "combat interrupts depth before reading")
    local ok, reason = result.start({100})
    check(not ok and reason == "combat" and result.calls == 2, "combat rejects new scans without a callback")
    st.combat = false
    check(result.start({100}), "out of combat can search")
    st.emit("AUCTION_HOUSE_CLOSED")
    check(result.calls == 3 and result.reason == "openAH", "close releases the lease and completes once")
end

do
    local _, st, _, result = fixture(false)
    st.books = {[100] = {offers = {}}, [101] = {offers = {}}, [102] = {offers = {}}, [103] = {offers = {}}, [104] = {offers = {}}}
    check(result.start({100, 101, 102, 103, 104}), "bounded time scan starts")
    for _ = 1, 4 do st.advance(14); st.result() end
    st.advance(4.01)
    check(result.calls == 1 and result.reason == "timeout" and result.books[103].complete and not result.books[104],
        "batch times out at sixty seconds and preserves completed empty books")
end
print(("Auction logistics depth: %d focused checks passed."):format(checks))
