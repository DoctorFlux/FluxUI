local export = setmetatable({FLUX_AH_FIXTURE_EXPORT = true}, {__index = _G})
local boot = assert(loadfile("tests/auction_restock.lua", "t", export))()
local checks = 0
local function check(value, label)
    checks = checks + 1
    assert(value, label)
end
local function fixture(legacy, requested)
    local A, st, env = boot(legacy, false, false)
    st.entries = {}
    st.emit("AUCTION_HOUSE_SHOW")
    A.Toggle()
    local entry = {itemID = 100, quantity = requested or 2, kind = "auction", jobId = 1,
        id = 1, planRevision = "job", maxUnitPrice = 100, maxTotalPrice = 100}
    local result = {}
    local function authorize(selected, quantity, total)
        if total then result.authorized = {entry = selected, quantity = quantity, total = total} end
        return true
    end
    local function observe(event, receipt)
        if event == "submitted" then result.receipt = receipt end
    end
    function result.prepare()
        return A.PrepareLogistics(entry, entry.quantity, authorize, observe, true)
    end
    function result.press()
        st.hardware = true
        A.ClickPrimary()
        st.hardware = false
    end
    return A, st, env, entry, result
end

do
    local A, st, _, entry, result = fixture(true)
    st.offers = {{quantity = 2, total = 110}, {quantity = 1, total = 50}}
    check(result.prepare(), "books an explicit legacy search")
    st.result()
    local phase, _, quote = A.GetLogisticsState(entry, 2)
    check(phase == "ready" and quote.quantity == 1 and quote.totalCopper == 50,
        "legacy exact preferred stack exceeding the aggregate budget leaves an affordable smaller stack")
    result.press()
    check(st.calls.buyStack == 1 and result.receipt.quantity == 1 and result.receipt.totalCopper == 50,
        "the original ready explicit owner press buys one smaller listing within budget")
end

do
    local A, st, _, entry, result = fixture(true)
    entry.stackSize, entry.stackMaxTotalPrice = 0, 60
    local ok, reason = result.prepare()
    check(not ok and reason == "invalid", "zero planned stack size is rejected")
    entry.stackSize, entry.stackMaxTotalPrice = 2, 59.5
    ok, reason = result.prepare()
    check(not ok and reason == "invalid", "fractional stack budget is rejected")
    entry.stackSize, entry.stackMaxTotalPrice = 2, 60
    st.offers = {{quantity = 1, total = 12}, {quantity = 2, total = 65}, {quantity = 2, total = 60}}
    check(result.prepare(), "an exact approved legacy size and stack budget prepare")
    st.result()
    local phase, _, quote = A.GetLogisticsState(entry, 2)
    check(phase == "ready" and quote.quantity == 2 and quote.totalCopper == 60,
        "legacy never substitutes a smaller size or a higher priced exact stack")
    entry.stackSize = 1
    check(not A.GetLogisticsState(entry, 2), "different planned stack size cannot reuse a ready quote")
    entry.stackSize, entry.stackMaxTotalPrice = 2, 59
    check(not A.GetLogisticsState(entry, 2), "different planned stack cap cannot reuse a ready quote")
    entry.stackMaxTotalPrice = 60
    st.offers[3].total = 61
    result.press()
    check(not st.calls.buyStack and not result.receipt, "live stack price changes block the ready press")
    st.offers[3].total = 60
    check(result.prepare(), "a fresh exact listing can prepare after price change")
    st.result()
    result.press()
    check(st.calls.buyStack == 1 and st.last.args[2] == 3 and st.last.args[3] == 60,
        "physical owner press buys only the exact approved legacy listing")
    check(result.authorized.entry.stackSize == 2 and result.authorized.entry.stackMaxTotalPrice == 60,
        "authorization receives the copied approved stack details")
end

do
    local A, st, env, entry, result = fixture(false)
    st.commodity = false
    local key = env.C_AuctionHouse.MakeItemKey(100)
    st.offers = {{itemKey = key, auctionID = 88, quantity = 5, buyoutAmount = 59},
        {itemKey = key, auctionID = 99, quantity = 10, buyoutAmount = 40}}
    entry.stackSize, entry.stackMaxTotalPrice = 2, 60
    check(result.prepare(), "modern item search starts before result type is known")
    st.result()
    local phase, reason = A.GetLogisticsState(entry, 2)
    check(not phase and reason == "noOffer" and not st.calls.buyItem,
        "a group of modern single listings cannot masquerade as a two-copy stack")
    entry.stackSize, entry.stackMaxTotalPrice = 1, 40
    check(result.prepare(), "approved modern single listings can prepare")
    st.result()
    local quote
    phase, _, quote = A.GetLogisticsState(entry, 2)
    check(phase == "ready" and quote.quantity == 1 and quote.totalCopper == 40,
        "modern quote preserves one item per listing")
    result.press()
    check(st.calls.buyItem == 1 and st.last.args[1] == 99 and result.receipt.quantity == 1,
        "ready explicit owner primary still buys exactly one modern item")
end

do
    local A, st, _, entry, result = fixture(false)
    st.offers = {{itemID = 100, quantity = 2, unitPrice = 30}}
    entry.stackSize, entry.stackMaxTotalPrice = 2, 60
    check(result.prepare(), "search starts before the commodity classification result")
    st.result()
    local phase, reason = A.GetLogisticsState(entry, 2)
    check(not phase and reason == "changed" and not st.calls.quote,
        "a sealed indivisible listing is not reinterpreted as liquid commodity depth")
end

for _, legacy in ipairs({false, true}) do
    local A, st, _, entry, result = fixture(legacy, 4)
    local total = legacy and 52 or 56
    for _, bad in ipairs({0, -1, 1.5, 5, true}) do
        entry.minQuantity = bad
        local ok, reason = result.prepare()
        check(not ok and reason == "invalid", "minimum must be a positive integer within the order")
    end
    entry.minQuantity, entry.stackSize = 2, 1
    local ok, reason = result.prepare()
    check(not ok and reason == "invalid", "an exact stack cannot be smaller than the minimum")
    entry.stackSize = nil
    st.offers = legacy and {{quantity = 1, total = 1}, {quantity = 2, total = 52},
        {quantity = 3, total = 110}, {quantity = 4, total = 101}}
        or {{itemID = 100, quantity = 1, unitPrice = 1}, {itemID = 100, quantity = 3, unitPrice = 55}}
    check(result.prepare(), "a valid minimum starts exact-item search")
    st.result()
    local phase, _, quote = A.GetLogisticsState(entry, 4)
    check(phase == "ready" and quote.quantity == 2 and quote.totalCopper == total,
        "offer skips undersized lots and chooses enough affordable units")
    check(not st.calls.buyStack and not st.calls.quote, "minimum-aware preparation cannot spend")
    entry.minQuantity = 3
    check(not A.GetLogisticsState(entry, 4), "a changed minimum cannot reuse a prepared order")
    check(result.prepare(), "a changed minimum allows a fresh search")
    st.result()
    phase, reason = A.GetLogisticsState(entry, 4)
    check(not phase and reason == "noOffer" and not st.calls.buyStack and not st.calls.quote,
        "no offer is ready when enough units cannot be bought within the budget")

    entry.minQuantity = 2
    check(result.prepare(), "the valid minimum prepares again")
    st.result()
    if not legacy then st.syncQuote, st.syncSuccess = {55, total}, true end
    result.press()
    check((legacy and st.calls.buyStack == 1 or not legacy and st.calls.confirm == 1)
        and result.receipt.quantity == 2 and result.receipt.totalCopper == total
        and result.authorized.entry.minQuantity == 2,
        "one click and a copied minimum authorize only the displayed affordable quantity")
end

do
    local A, st, env, entry, result = fixture(false)
    st.commodity = false
    local key = env.C_AuctionHouse.MakeItemKey(100)
    st.offers = {{itemKey = key, auctionID = 88, quantity = 5, buyoutAmount = 40}}
    entry.minQuantity = 2
    check(result.prepare(), "modern noncommodity search accepts the minimum until offers are known")
    st.result()
    local phase, reason = A.GetLogisticsState(entry, 2)
    check(not phase and reason == "noOffer" and not st.calls.buyItem,
        "a group of single noncommodity listings cannot satisfy the minimum")
end

print(("Auction logistics exact stack approvals: %d focused checks passed."):format(checks))
