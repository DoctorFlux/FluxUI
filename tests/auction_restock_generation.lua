-- Actual central generation probe plus native auction transaction intent paths.
-- Mocked inputs establish selection/quantity/press ownership, not native access.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local file = assert(io.open(root .. "/Core/Capabilities.lua", "rb"))
local source = file:read("*a"); file:close()
local first = assert(source:find("function Cap.HasLegacyAuctionHouse()", 1, true))
local last = assert(source:find("function Cap.RefreshInventoryCaps()", first, true))
local capabilitySource = "local Client, Cap = ...\n" .. source:sub(first, last - 1) .. "\nreturn Cap.HasLegacyAuctionHouse"
local function capability(env, client)
    return assert(load(capabilitySource, "@production-auction-generation", "t", env))(client or {}, {})
end
local function frame(shown) return { IsShown = function() return shown end } end
local function probe(options)
    local env = setmetatable({}, { __index = _G }); env._G = env
    if options.native ~= nil then
        env.IsUsingLegacyAuctionClient = function()
            if options.native == "error" then error("unavailable client probe") end
            if options.native == "nil" then return nil end
            return options.native
        end
    end
    env.C_AuctionHouse = options.modern and { SendSearchQuery = function() end } or options.namespace and {} or nil
    env.GetNumAuctionItems = options.oldAPI and function() return 0 end or nil
    env.AuctionFrame = options.oldShown ~= nil and frame(options.oldShown) or nil
    env.AuctionHouseFrame = options.newShown ~= nil and frame(options.newShown) or nil
    return capability(env, { isEra = options.era })()
end
for _, case in ipairs({
    { { native = false, era = true, namespace = true, oldAPI = true, oldShown = true }, false, "native false overrides Era flag and shown compatibility owner" },
    { { native = true, modern = true, newShown = true }, true, "native true overrides a modern compatibility namespace and frame" },
    { { native = false, oldAPI = true }, false, "native false remains authoritative without a loaded modern namespace" },
    { { oldShown = true, newShown = false, modern = true }, true, "shown old native owner beats namespace presence when native probe is absent" },
    { { oldShown = false, newShown = true, era = true, oldAPI = true }, false, "shown modern native owner beats brand fallback" },
    { { oldShown = false, newShown = false, modern = true, oldAPI = true }, false, "hidden old frame does not override usable modern search API" },
    { { oldShown = true, newShown = true, modern = true, oldAPI = true }, false, "ambiguous shown owners fall back to modern search capability" },
    { { namespace = true, oldAPI = true }, true, "empty compatibility namespace does not conceal legacy API" },
    { { namespace = true }, false, "empty namespace alone cannot establish legacy support" },
    { { era = true, modern = true }, true, "Era fallback stays legacy without runtime or shown-owner evidence" },
    { { native = "error", oldShown = true, modern = true }, true, "failed native probe falls back to actual shown owner" },
    { { native = "nil", namespace = true, oldAPI = true }, true, "unresolved native probe uses the capability fallback" },
    { { native = "false", namespace = true, oldAPI = true }, true, "nonboolean native value is not interpreted as a client result" },
}) do check(probe(case[1]) == case[2], case[3]) end

local function observer(fresh, cached, helper, external)
    local hooks, events = {}, {}
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.PlaceAuctionBid = function() end
    env.C_AuctionHouse = { ConfirmCommoditiesPurchase = function() end }
    env.hooksecurefunc = function(target, name)
        local key = type(target) == "string" and target or name
        hooks[key] = (hooks[key] or 0) + 1
    end
    local flux = { Cap = { hasLegacyAuctionHouse = cached }, Inventory = {
        Builtin = { Mail = {} }, Store = { UsesSyndicator = function() return external end },
    }, Events = { Register = function(event)
        check(not events[event], "purchase observer registers the selected event only once")
        events[event] = true
    end } }
    if helper then flux.Cap.HasLegacyAuctionHouse = function() return fresh end end
    assert(loadfile(root .. "/Inventory/Builtin/AuctionPurchases.lua", "t", env))("_FluxUI", { Flux = flux })
    flux.Inventory.Builtin.AuctionPurchases.Start(); flux.Inventory.Builtin.AuctionPurchases.Start()
    return hooks, events
end
do
    local hooks, events = observer(false, true, true)
    check(hooks.ConfirmCommoditiesPurchase == 1 and not hooks.PlaceAuctionBid and events.COMMODITY_PURCHASE_SUCCEEDED,
        "purchase observer honors fresh modern result over stale legacy cache")
    hooks, events = observer(true, false, true)
    check(hooks.PlaceAuctionBid == 1 and not hooks.ConfirmCommoditiesPurchase and events.CHAT_MSG_SYSTEM,
        "purchase observer honors fresh legacy result over stale modern cache")
    hooks = observer(nil, true, false)
    check(hooks.PlaceAuctionBid == 1 and not hooks.ConfirmCommoditiesPurchase, "older observer capability interface retains cached legacy fallback")
    hooks = observer(nil, false, false)
    check(hooks.ConfirmCommoditiesPurchase == 1 and not hooks.PlaceAuctionBid, "older observer capability interface retains cached modern fallback")
    hooks, events = observer(false, true, true, true)
    check(not next(hooks) and not next(events), "ready external provider retains exclusive incoming ownership")
end

local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local fixture = assert(loadfile(root .. "/tests/auction_restock.lua", "t", export))()
local function open(A, st)
    st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env = fixture(legacy, auctionator, syndicator)
        local nativeLegacy = legacy
        env.IsUsingLegacyAuctionClient = function() return nativeLegacy end
        st.flux.Cap.HasLegacyAuctionHouse = capability(env, { isEra = not legacy })
        st.flux.Cap.hasLegacyAuctionHouse = not legacy
        check(A.IsLegacy() == legacy, "restock uses current typed generation instead of opposite cached/brand flags")
        nativeLegacy = not legacy
        check(A.IsLegacy() == not legacy, "generation getter re-evaluates a changed native result")
        nativeLegacy = legacy
        local getter = st.flux.Cap.HasLegacyAuctionHouse
        st.flux.Cap.HasLegacyAuctionHouse = nil
        check(A.IsLegacy() == not legacy, "older capability interface may fall back to its cached flag")
        st.flux.Cap.HasLegacyAuctionHouse = getter
        st.entries = { { itemID = 100, name = "Material", target = 40 } }
        A.SetMaxPrice(100, 0)
        check(A.GetMaxPrice(100) == 0 and A.PurchaseLimit(100) == math.huge, "zero unit limit stays unlimited on both generations")
        if legacy then
            st.books = { [100] = { commodity = false, offers = {
                { itemID = 100, quantity = 20, total = 200 },
                { itemID = 100, quantity = 20, total = 220 },
            } } }
        else
            st.books = { [100] = { commodity = true, offers = {
                { itemID = 100, quantity = 20, unitPrice = 10 },
                { itemID = 100, quantity = 20, unitPrice = 15 },
            } } }
        end
        open(A, st)
        check(A.legacy == legacy, "open restock session records the actual current auction generation")
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack, "generation detection/pricing never buys")
        if legacy then
            check(A.offer and A.offer.quantity == 20 and A.offer.total == 200, "legacy offer is one whole twenty-item listing")
            st.press()
            check(st.calls.buyStack == 1 and A.transaction.quantity == 20, "first legacy press buys only one whole listing")
            st.press(); check(st.calls.buyStack == 1, "unacknowledged first listing cannot be submitted twice")
            table.remove(st.books[100].offers, 1); st.legacyReceipt(); st.drain()
            check(st.calls.buyStack == 1 and A.offer and A.offer.quantity == 20 and A.offer.total == 220,
                "first receipt automatically prepares the second listing without buying it")
            st.press()
            check(st.calls.buyStack == 2 and A.transaction.quantity == 20, "second legacy listing requires a distinct physical press")
            table.remove(st.books[100].offers, 1); st.legacyReceipt(); st.drain()
            check(A.Settings().pending[100].units == 40 and not A.offer and st.calls.buyStack == 2,
                "two legacy receipts reserve forty items without an extra automatic purchase")
        else
            check(A.offer and A.offer.commodity and A.offer.quantity == 40 and A.offer.total == 500,
                "modern material offer aggregates forty across the commodity price ladder")
            st.syncQuote = { 15, 500 }; st.press()
            check(st.calls.quote == 1 and st.calls.confirm == 1 and A.transaction.quantity == 40,
                "one modern Buy press quotes and confirms all forty material units")
            st.press(); check(st.calls.confirm == 1, "repeated press cannot duplicate a submitted forty-item transaction")
            st.emit("COMMODITY_PURCHASE_SUCCEEDED"); st.drain()
            check(A.Settings().pending[100].units == 40 and not A.offer and st.calls.confirm == 1,
                "one acknowledged commodity transaction reserves forty and satisfies its target")
            check(not st.calls.buyStack and not st.calls.buyItem, "modern commodity intent never uses a whole-listing purchase API")
        end
        check(#st.errors == 0, "generation and transaction paths raise no modeled native errors")
    end end
end
print(("Auction generation/quantity: %d checks PASS; %d client/provider profiles; native detection/buying NOT RUN"):format(checks, profiles))
