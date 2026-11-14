-- Automatic queue and single-use quote consent, using the real UI handlers.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local chunk = assert(loadfile("tests/auction_restock.lua", "t", export)); if setfenv then setfenv(chunk, export) end
local fixture = chunk()
local mailExport = setmetatable({ FLUX_MAIL_RESTOCK_FIXTURE_EXPORT = true }, { __index = _G })
local mailChunk = assert(loadfile("tests/mail_restock.lua", "t", mailExport)); if setfenv then setfenv(mailChunk, mailExport) end
local mailFixture = mailChunk()
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env = fixture(legacy, auctionator, syndicator)
        local function Book(id, quantity, price)
            return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = quantity, total = quantity * price } }
                or { { itemID = id, quantity = quantity, unitPrice = price } } }
        end
        local function Setup()
            st.reset()
            st.entries = { { itemID = 100, name = "A", target = 10 }, { itemID = 101, name = "B", target = 5 }, { itemID = 102, name = "C", target = 3 } }
            st.books = { [100] = Book(100, 10, 50), [101] = Book(101, 5, 200), [102] = Book(102, 3, 10) }
            A.SetMaxPrice(100, 30); A.SetMaxPrice(102, 20)
            st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        end
        Setup()
        check(A.offer and A.offer.itemID == 101, "automatic queue skips over-cap first row and uses unlimited next row")
        check(not st.calls.quote and not st.calls.buyStack and not st.calls.confirm, "opening and every price result are read only")
        check(A.editorID == 100 and A.selectedID == 101, "initial cell editor does not select the purchase")
        local searches = st.calls.search or st.calls.legacySearch
        A.Select(102)
        check(A.editorID == 102 and A.offer.itemID == 101 and (st.calls.search or st.calls.legacySearch) == searches,
            "cell selection cannot change the queue or discard a ready offer")
        st.press()
        if not legacy then st.emit("COMMODITY_PRICE_UPDATED", 250, 1250) end
        check((st.calls.confirm or st.calls.buyStack) == 1 and A.Settings().pending[101].units == 5, "one press buys one queued quantity without an item selection")
        st.press()
        check((st.calls.confirm or st.calls.buyStack) == 1, "waiting transaction cannot buy another quantity")
        if legacy then st.legacyReceipt() else st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        st.drain()
        check(A.offer and A.offer.itemID == 102 and not A.transaction, "receipt automatically prepares the next eligible row")
        if not legacy then
            st.emit("COMMODITY_PRICE_UPDATED", 250, 1250)
            check(A.offer and A.offer.itemID == 102 and not A.foreign, "duplicate completed quote cannot hijack the next prepared row")
        end
        check((st.calls.confirm or st.calls.buyStack) == 1, "preparing next never purchases it")
        st.press()
        if not legacy then st.emit("COMMODITY_PRICE_UPDATED", 10, 30); st.emit("COMMODITY_PURCHASE_SUCCEEDED") else st.legacyReceipt() end
        check((st.calls.confirm or st.calls.buyStack) == 2 and A.Settings().pending[102].units == 3, "next transaction requires a distinct second press")
        st.mail[101], st.mail[102] = 5, 3; A.GetRows(true)
        check(next(A.Settings().pending) == nil and A.FindRow(101).pending == 5 and A.FindRow(102).pending == 3,
            "incoming mail replaces reservations without double credit")
        check(A.frame.pending == nil and A.ClearPending == nil, "clear pending control and API are removed")
        Setup()
        local count = st.calls.search or st.calls.legacySearch
        st.advance(12)
        check((st.calls.search or st.calls.legacySearch) == count, "ready queue does no periodic polling")

        -- A competing search yields until an explicit user scan, including bag pulses.
        if legacy then env.QueryAuctionItems("Other", nil, nil, 0, false, nil, false, true) else env.C_AuctionHouse.SendBrowseQuery({}) end
        count = st.calls.search or st.calls.legacySearch
        st.emit("BAG_UPDATE_DELAYED"); st.advance(1)
        check(A.yielded and (st.calls.search or st.calls.legacySearch) == count, "bag changes do not fight another addon's search")
        if legacy then st.press() else st.press(A.frame.refresh) end; st.drain()
        check(not A.yielded and A.offer and A.offer.itemID == 101, "the available primary/refresh control resumes only the next eligible item")

        if not legacy then
            local function Quoting()
                Setup(); st.press(); check(A.state == "quoting" and A.intent ~= nil, "physical press creates one quote intent")
            end
            Quoting(); A.Settings().maxUnitPrices[101] = 1; A.Settings().noPriceLimit[101] = false; st.emit("COMMODITY_PRICE_UPDATED", 200, 1000)
            check(not st.calls.confirm and not A.intent, "live lower cap revokes unlimited purchase intent")
            Quoting(); st.money = 0; st.emit("COMMODITY_PRICE_UPDATED", 200, 1000)
            check(not st.calls.confirm and A.status == "money", "wallet revalidated after asynchronous quote")
            Quoting(); st.bags[101] = 5; st.emit("COMMODITY_PRICE_UPDATED", 200, 1000)
            check(not st.calls.confirm, "new bag stock revokes now-unneeded quote quantity")
            Quoting(); st.combat = true; st.emit("COMMODITY_PRICE_UPDATED", 200, 1000)
            check(not st.calls.confirm, "combat arrival revokes the pending purchase")
            Quoting(); A.frame:Hide(); st.emit("COMMODITY_PRICE_UPDATED", 200, 1000)
            check(not st.calls.confirm and not A.intent, "hidden tab cannot complete an earlier purchase intent")
            Quoting(); env.C_AuctionHouse.SendBrowseQuery({}); st.emit("COMMODITY_PRICE_UPDATED", 200, 1000)
            check(not st.calls.confirm, "foreign query cancels consent before a quote can confirm")
            Quoting(); st.advance(16); st.emit("COMMODITY_PRICE_UPDATED", 200, 1000)
            check(not st.calls.confirm, "timed-out press cannot authorize a late quote")
            Quoting(); check(not A.frame.crafting.enabled, "craft preference cannot change during a pending quote")
            st.emit("COMMODITY_PRICE_UPDATED", 200, 1000); st.emit("COMMODITY_PRICE_UPDATED", 200, 1000)
            check(st.calls.confirm == 1 and A.intent == nil, "duplicate asynchronous events consume one press only once")
            Setup(); st.syncQuote, st.syncSuccess = { 200, 1000 }, true; st.press(); st.drain()
            check(st.calls.confirm == 1 and not A.transaction and A.offer.itemID == 102, "synchronous quote and receipt keep one-use consent and automatic next preparation")
        end

        -- A zero output cap must still choose cheaper learned materials.
        st.reset(); st.recipeItems = { [100] = 7 }
        st.recipes = { { recipeID = 7, outputItemID = 100, name = "Two-potion recipe", learned = true, legacy = true, quantityMin = 2,
            reagents = { { itemID = 200, count = 3 } } } }
        st.books = { [100] = Book(100, 10, 100), [200] = Book(200, 15, 10) }
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        check(A.GetMaxPrice(100) == 0 and A.craftPlans[100] and A.offer.itemID == 200 and A.offer.quantity == 15,
            "unlimited finished-item setting still compares learned recipe economics")
        check(A.craftPlans[100].budget == 1000 and A.PurchaseLimit(200) == 10, "unlimited output does not remove the finite craft-vs-buy budget")
        A.frame.crafting:SetChecked(false); st.press(A.frame.crafting); st.drain()
        check(not A.PreferCrafting() and not A.craftPlans[100] and not A.FindRow(200) and A.offer.itemID == 100,
            "craft toggle off buys only the finished item and removes virtual materials")
        check(not A.frame.detailsText and A.RouteText(A.FindRow(100)) == "Direct",
            "craft preference off uses compact direct label without recipe/cost pane")
        A.frame:Hide(); A.Toggle(); st.drain()
        check(not A.PreferCrafting() and A.offer.itemID == 100, "craft preference persists between auction sessions")
        A.frame.crafting:SetChecked(true); st.press(A.frame.crafting); st.drain()
        check(A.PreferCrafting() and A.craftPlans[100] and A.offer.itemID == 200, "craft toggle on restores economic material selection")
        A.SetMaxPrice(200, 1); st.drain()
        check(not A.craftPlans[100] and A.offer and A.offer.itemID == 100, "explicit material price limit can make the finished route preferable")

        -- The user's feather example, through click, mailbox arrival and collection.
        st.reset(); st.entries = { { itemID = 100, name = "Light Feather", target = 20 } }; st.bags[100] = 19
        st.books = { [100] = Book(100, 1, 5) }
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        check(A.offer and A.offer.quantity == 1, "19 of 20 feathers prepares precisely the one missing item")
        st.press()
        if legacy then st.legacyReceipt() else st.emit("COMMODITY_PRICE_UPDATED", 5, 5); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        check(A.FindRow(100).pending == 1 and A.FindRow(100).need == 0, "bought feather is pending immediately before mailbox discovery")
        A.ScanQueue(true); st.drain(); st.press()
        check((st.calls.confirm or st.calls.buyStack) == 1, "refresh/repeated buy cannot buy a second pending feather")
        st.mail[100] = 1; st.inventoryListeners["AuctionRestock.Incoming"](); st.drain()
        check(not A.Settings().pending[100] and A.FindRow(100).pending == 1 and A.FindRow(100).need == 0,
            "same feather in inbox is counted once and reservation reconciles automatically")
        check(A.frame.cells[1].incoming.text:find("Pending 1", 1, true), "cell visibly identifies one incoming feather")
        st.bags[100], st.mail[100] = 20, 0; A.SettingsChanged(); st.drain()
        check(A.FindRow(100).pending == 0 and A.FindRow(100).need == 0, "collecting mail transfers incoming credit into bags")

        -- Collecting older mail cannot erase a separate new purchase in transit.
        st.reset(); st.entries = { { itemID = 100, name = "Feather", target = 20 } }; st.bags[100], st.mail[100] = 10, 5
        st.books = { [100] = Book(100, 5, 5) }
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        check(A.offer.quantity == 5, "existing mailbox stock is deducted before buying")
        st.press()
        if legacy then st.legacyReceipt() else st.emit("COMMODITY_PRICE_UPDATED", 5, 25); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        local ms = mailFixture(client:lower(), syndicator and "syndicator" or "builtin", true)
        ms.mail.SetSetting("Restock", "AutoCollect", false)
        ms.inbox = { { sender = "AH", subject = "Older stock", money = 0, cod = 0,
            items = { { id = 100, quantity = 5 } } } }
        ms:show(); ms.mail.OpenAll(); ms:pumpFrames(6)
        check(ms.pending and #ms.calls == 1 and ms.calls[1].id == 100 and ms.calls[1].quantity == 5,
            "actual ordinary mail owner submits the older five-item take once")
        st.mailboxOpen = true; st.bags[100] = 15; A.GetRows(true)
        local transit = A.Settings().pending[100]
        check(A.FindRow(100).need == 0 and transit and transit.units == 5 and not A.IsReliable(),
            "mailbox handoff keeps planning readable without reconciling stale inbox with already updated bags")
        ms:ack(); ms:advance(.6)
        check(not ms.pending and #ms.calls == 1 and A.Settings().pending[100].units == 5,
            "ordinary native take completion leaves the separate new purchase reserved until provider handoff")
        st.mail[100], st.mailboxOpen = 0, false; A.GetRows(true)
        check(A.Settings().pending[100].units == 5 and A.FindRow(100).need == 0, "collecting older five leaves new five reserved")
        st.mail[100] = 5; A.GetRows(true)
        check(not A.Settings().pending[100] and A.FindRow(100).pending == 5 and A.FindRow(100).need == 0, "later purchased mail replaces only its own transit credit")
        st.inventory.snapshots = { mail = { generation = 0 } }; st.storedMail = { { itemID = 100, itemCount = 5 } }
        A.GetRows(true)
        check(A.FindRow(100).pending == 5, "cold built-in mail snapshot reuses persisted current-character inbox")
        st.inventory.snapshots.mail.generation = 1; st.mail[100] = 0; A.GetRows(true)
        check(A.FindRow(100).pending == 0 and A.FindRow(100).need == 5, "completed empty inbox overrides stale persisted fallback")
        A.frame:Hide()
        check(st.inventoryListeners["AuctionRestock.Incoming"] == nil, "closed tab detaches the existing inventory-mail listener")
        check(#st.errors == 0, "automatic queue emits no modeled API errors")
    end end
end
print(("Auction restock automatic queue: %d checks PASS; %d profiles; native purchase permissions/pixels NOT RUN"):format(checks, profiles))
