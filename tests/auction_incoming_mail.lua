-- Actual built-in Mail + receipt observer + actual auction-restock controls.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local chunk = assert(loadfile("tests/auction_restock.lua", "t", export)); if setfenv then setfenv(chunk, export) end
local fixture = chunk()
local function setup(legacy, provider)
    local A, st, env = fixture(legacy, false, provider)
    local inv = st.inventory
    local saved, external = { mail = {} }, { mail = {} }
    st.externalReady = provider == "ready"
    st.publications, st.marks, st.storeWrites, st.purchaseHooks = 0, 0, 0, {}
    inv.Builtin = {}
    inv.snapshots = { mail = { byIndex = {}, counts = {}, generation = 1 } }
    inv.Store = {
        UsesSyndicator = function() return st.externalReady end,
        GetCurrentCharacter = function() return st.externalReady and external or saved end,
        EnsureCurrentCharacter = function() st.storeWrites = st.storeWrites + 1; check(not st.externalReady, "never resolve provider-owned destination for write"); return saved end,
        GetCurrentCharacterName = function() return "Tester-Realm" end,
        MarkPending = function() st.marks = st.marks + 1 end,
    }
    inv.Mail.GetCount = function(id) return inv.snapshots.mail.counts[id] or 0 end
    inv.Notify = function()
        st.publications = st.publications + 1
        local listener = st.inventoryListeners and st.inventoryListeners["AuctionRestock.Incoming"]
        if listener then listener() end
    end
    env.time = function() return 1000 end
    env.ERR_AUCTION_BID_PLACED = "Bid placed."
    env.C_AuctionHouse.GetAuctionInfoByID = function(id)
        for _, info in ipairs(st.offers) do if info.auctionID == id then return {
            itemKey = info.itemKey, itemLink = info.itemLink, minBid = info.minBid,
            bidAmount = info.bidAmount, buyoutAmount = info.buyoutAmount, bidder = info.bidder,
        } end end
    end
    env.hooksecurefunc = function(target, name, callback)
        if type(target) == "string" then callback, name, target = name, target, env end
        check(name ~= "StartCommoditiesPurchase", "restricted commodity quote entry stays unhooked")
        st.purchaseHooks[name] = (st.purchaseHooks[name] or 0) + 1
        local original = assert(target[name])
        target[name] = function(...) local result = original(...); callback(...); return result end
    end
    for _, path in ipairs({ "Inventory/Builtin/Mail.lua", "Inventory/Builtin/AuctionPurchases.lua" }) do
        local source = assert(loadfile(root .. "/" .. path, "t", env)); if setfenv then setfenv(source, env) end
        source("_FluxUI", { Flux = st.flux })
    end
    inv.Builtin.AuctionPurchases.Start(); inv.Builtin.AuctionPurchases.Start()
    return A, st, env, saved, external
end
if FLUX_INCOMING_FIXTURE_EXPORT then return setup end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "pending", "ready" }) do
        profiles = profiles + 1
        local A, st, env, saved, external = setup(legacy, provider)
        local baselineFrames, baselineTimers = st.frames, #st.timers
        if provider == "ready" then
            check(next(st.purchaseHooks) == nil and not st.inventory.Builtin.Mail.RecordAuctionDelivery(100, 1), "ready Syndicator owns incoming publication exclusively")
            check(st.storeWrites == 0 and #saved.mail == 0 and #external.mail == 0, "ready-provider path never mutates either ledger")
        elseif legacy then
            st.offers = { { itemID = 100, quantity = 5, total = 50 } }
            st.hardware = true; env.PlaceAuctionBid("list", 1, 50); st.hardware = false
            check(#saved.mail == 0, "legacy click alone does not invent delivered mail")
            st.emit("CHAT_MSG_SYSTEM", "Unrelated message")
            check(#saved.mail == 0, "unrelated legacy system response ignored")
            st.emit("CHAT_MSG_SYSTEM", env.ERR_AUCTION_BID_PLACED)
            check(st.inventory.Mail.GetCount(100) == 5 and saved.mail[1].itemCount == 5, "legacy confirmed buyout instantly publishes the entire stack to built-in mail")
            st.emit("CHAT_MSG_SYSTEM", env.ERR_AUCTION_BID_PLACED)
            check(#saved.mail == 1 and st.publications == 1, "duplicate legacy acknowledgement cannot publish twice")
            st.hardware = true; env.PlaceAuctionBid("list", 1, 10); st.hardware = false; st.emit("CHAT_MSG_SYSTEM", env.ERR_AUCTION_BID_PLACED)
            check(#saved.mail == 1, "ordinary legacy bid is not immediate incoming stock")
        else
            st.hardware = true; env.C_AuctionHouse.StartCommoditiesPurchase(100, 3, 5); env.C_AuctionHouse.ConfirmCommoditiesPurchase(100, 3); st.hardware = false
            check(#saved.mail == 0, "confirmation request alone cannot credit failed commodities")
            st.emit("COMMODITY_PURCHASE_SUCCEEDED"); st.emit("COMMODITY_PURCHASED", 100, 3); st.emit("COMMODITY_PURCHASE_SUCCEEDED")
            check(st.inventory.Mail.GetCount(100) == 3 and #saved.mail == 1 and st.publications == 1, "native commodity receipt immediately publishes once without opening mailbox")
            st.hardware = true; env.C_AuctionHouse.StartCommoditiesPurchase(100, 2, 5); env.C_AuctionHouse.ConfirmCommoditiesPurchase(100, 2); st.hardware = false
            st.emit("COMMODITY_PURCHASE_FAILED"); st.emit("COMMODITY_PURCHASE_SUCCEEDED")
            check(st.inventory.Mail.GetCount(100) == 3, "failed commodity request does not add incoming stock")
            local key = env.C_AuctionHouse.MakeItemKey(101)
            st.offers = { { itemKey = key, itemLink = "item:101", auctionID = 55, quantity = 7, buyoutAmount = 70 } }
            st.emit("ITEM_SEARCH_RESULTS_UPDATED", key)
            st.hardware = true; env.C_AuctionHouse.PlaceBid(55, 70); st.hardware = false
            st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 55); st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 55)
            check(st.inventory.Mail.GetCount(101) == 1 and #saved.mail == 2, "modern item bid receives one physical item from grouped availability and deduplicates auction ID")
        end
        check(st.frames == baselineFrames and #st.timers == baselineTimers, "receipt publication adds no frame/timer or inbox scan")
        if provider ~= "ready" then
            check(st.inventory.Builtin.Mail.GetPredictedCount(100) == (legacy and 5 or 3), "incoming purchase prediction distinguished from observed inbox")
            check(saved.mail[1].expirationTime == 1000 + 30 * 86400 and saved.mail[1].auctionDelivery, "predicted incoming uses existing durable mail record schema")
            local writes, publications = st.storeWrites, st.publications
            if legacy then st.hardware = true; env.PlaceAuctionBid("list", 1, 50); st.hardware = false
            else st.hardware = true; env.C_AuctionHouse.StartCommoditiesPurchase(100, 1, 5); env.C_AuctionHouse.ConfirmCommoditiesPurchase(100, 1); st.hardware = false end
            st.externalReady = true
            st.emit(legacy and "CHAT_MSG_SYSTEM" or "COMMODITY_PURCHASE_SUCCEEDED", env.ERR_AUCTION_BID_PLACED)
            check(st.storeWrites == writes and st.publications == publications and #external.mail == 0, "ownership handoff makes stale completion inert")
        end

        if not legacy and provider ~= "ready" then
            -- Native commodity success can be paired with an item-style completion.
            -- A cached listing is not proof that its entire stack was purchased.
            A, st, env, saved = setup(false, provider)
            st.hardware = true
            env.C_AuctionHouse.StartCommoditiesPurchase(100, 1, 338)
            env.C_AuctionHouse.ConfirmCommoditiesPurchase(100, 1)
            st.hardware = false
            st.emit("COMMODITY_PURCHASE_SUCCEEDED")
            local id = 987654
            st.offers = { { auctionID = id, itemKey = env.C_AuctionHouse.MakeItemKey(200),
                quantity = 38, itemLink = "item:200", buyoutAmount = 380 } }
            st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", id)
            check(st.inventory.Mail.GetCount(100) == 1 and st.inventory.Mail.GetCount(200) == 0 and #saved.mail == 1,
                "paired commodity completion cannot invent an unbid material stack of 38")
            st.emit("COMMODITY_PURCHASED", 100, 1); st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", id)
            check(st.publications == 1 and #saved.mail == 1, "paired and duplicate receipts retain exactly the confirmed potion")
            st.hardware = true; env.C_AuctionHouse.PlaceBid(id, 1); st.hardware = false
            st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", id)
            check(st.inventory.Mail.GetCount(200) == 0, "ordinary item bid is insufficient proof of a bought whole stack")
            st.hardware = true; env.C_AuctionHouse.PlaceBid(id, 380); st.hardware = false
            check(st.inventory.Mail.GetCount(200) == 0, "matching buyout request still waits for native completion")
            st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", id); st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", id)
            check(st.inventory.Mail.GetCount(200) == 1 and #saved.mail == 2 and st.publications == 2,
                "later proven modern item bid publishes one physical auction instead of its thirty-eight available auctions")
        end

        -- Own restock registers context before native calls, including sync receipts.
        A, st, env, saved = setup(legacy, false)
        st.entries[1].name, st.entries[1].target, st.bags[100] = "Light Feather", 20, 19
        if not legacy then st.syncQuote, st.syncSuccess = { 5, 5 }, true end
        st.start(legacy and { { itemID = 100, quantity = 1, total = 5 } } or { { itemID = 100, quantity = 1, unitPrice = 5 } })
        st.press()
        if legacy then st.emit("CHAT_MSG_SYSTEM", env.ERR_AUCTION_BID_PLACED); st.emit("AUCTION_ITEM_LIST_UPDATE") end
        check(st.inventory.Mail.GetCount(100) == 1 and saved.mail[1].itemCount == 1, "own buy instantly visible to the built-in Syndicator-style service")
        check(A.FindRow(100).pending == 1 and A.FindRow(100).need == 0 and A.Settings().pending[100].units == 1,
            "provider prediction and private in-transit reservation count once; private credit survives until actual inbox")
        A.ScanQueue(true); st.drain(); st.press()
        check((st.calls.confirm or st.calls.buyStack) == 1, "instant built-in publication cannot cause duplicate feather buying")
        A.frame:Hide()
        local inboxCount, scanFrame = 0
        env.GetInboxNumItems = function() return inboxCount end
        env.GetInboxHeaderInfo = function() return nil, nil, nil, nil, nil, nil, 30, 1 end
        env.GetInboxItem = function(_, slot) if slot == 1 then return "Feather", 100, 1, 1, 1 end end
        local create = env.CreateFrame
        env.CreateFrame = function(...) local frame = create(...); scanFrame = frame; return frame end
        local mail = st.inventory.Builtin.Mail
        mail.Refresh({ force = true }); st.advance(0.2); scanFrame:Fire("OnUpdate"); A.GetRows(true)
        check(st.inventory.Mail.GetCount(100) == 0 and A.FindRow(100).pending == 1 and A.FindRow(100).need == 0,
            "authoritative inbox empty before arrival cannot discard the own purchase transit credit")
        inboxCount = 1; mail.Refresh({ force = true }); st.advance(0.2); scanFrame:Fire("OnUpdate"); A.GetRows(true)
        check(mail.GetPredictedCount(100) == 0 and st.inventory.Mail.GetCount(100) == 1 and not A.Settings().pending[100],
            "real inbox publication replaces prediction and reconciles the transit reservation once")
        inboxCount, st.bags[100] = 0, 20; mail.Refresh({ force = true }); st.advance(0.2); scanFrame:Fire("OnUpdate"); A.GetRows(true)
        check(A.FindRow(100).pending == 0 and A.FindRow(100).need == 0, "collecting the confirmed feather leaves only its actual bag count")
        if not legacy then
            A, st, env, saved = setup(false, false)
            st.start(); st.press(); st.emit("COMMODITY_PRICE_UPDATED", 50, 500); st.emit("COMMODITY_PURCHASE_FAILED")
            check(A.status == "failed" and not A.Settings().pending[100] and st.inventory.Mail.GetCount(100) == 0,
                "owned failed confirmation releases its private reservation automatically without a clear control")
            st.emit("COMMODITY_PURCHASE_SUCCEEDED")
            check(st.inventory.Mail.GetCount(100) == 0 and st.calls.quote == 1, "failed context cannot publish late phantom mail or automatically retry")
            A, st, env, saved = setup(false, false)
            st.start(); st.press()
            env.C_AuctionHouse.ConfirmCommoditiesPurchase = function() st.emit("ADDON_ACTION_BLOCKED", "_FluxUI", "ConfirmCommoditiesPurchase") end
            st.emit("COMMODITY_PRICE_UPDATED", 50, 500); st.emit("COMMODITY_PURCHASE_SUCCEEDED")
            check(A.status == "blocked" and not A.Settings().pending[100] and st.inventory.Mail.GetCount(100) == 0,
                "synchronously blocked call releases only its own reservation and erases speculative receipt context")
        end
    end
end
print(("Auction incoming mail: %d checks PASS; %d client/provider profiles; native purchase/taint/latency NOT RUN"):format(checks, profiles))
