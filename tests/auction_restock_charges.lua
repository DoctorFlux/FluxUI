-- Charged targets are uses; AH listings, quotes, receipts and prices are items.
local checks, profiles, receiptProfiles = 0, 0, 0
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
        st.uses, st.predicted = {}, {}
        env.FluxRestock.Inv.GetLiveCount = function(id, opts)
            check(opts.bags == true and opts.bank == false and opts.warband == false and opts.equipped == false,
                "charged restock retains carried-only inventory ownership")
            -- FluxInv.GetLiveCount defaults to uses unless charges is false.
            return (opts.charges ~= false and st.uses[id] or st.bags[id]) or 0
        end
        env.FluxRestockItemRegistry.GetChargeInfo = function(id)
            return id == st.charged, id == st.charged and st.charges or nil
        end
        st.inventory.Builtin = { Mail = { GetPredictedCount = function(id) return st.predicted[id] or 0 end } }
        local function charged(target, source)
            st.charged, st.charges = 100, 5
            st.entries = { { itemID = 100, name = "Oil", target = target or 9, bankCount = 0,
                restockSource = source or "manual" } }
        end

        for _, source in ipairs({ "manual", "consumable", "reagent" }) do
            charged(9, source)
            local row = A.GetRows(true)[1]
            check(row.need == 2 and row.unitsPerItem == 5 and row.isCharge,
                "every item target rounds nine uses to two five-charge items")
            check(row.target == 9 and row.restockSource == source and st.entries[1].unitsPerItem == nil,
                "charge conversion preserves target, source and shared target entries")
        end
        A.Settings().allowExcessStacks = true
        check(not A.AllowExcessStacks(100) and not A.AllowExcessStacks({ itemID = 100, isCharge = false, unitsPerItem = 1 }),
            "canonical charged SKU never permits excess physical copies, including physical recipe rows")
        check(A.AllowExcessStacks(101) == legacy, "ordinary excess listings are permitted only by the old AH generation")
        local savedMode = A.legacy
        A.legacy = not legacy
        check(A.AllowExcessStacks(101) == legacy, "fresh AH capability overrides a stale cached excess-generation flag")
        A.legacy = savedMode
        A.Settings().allowExcessStacks = false
        st.uses[100], st.bags[100] = 2, 1
        local row = A.GetRows(true)[1]
        check(row.bagCount == 2 and row.need == 2, "partly used owned item contributes its remaining uses")
        st.entries[1].countBank, st.entries[1].bankCount = true, 3
        check(A.GetRows(true)[1].need == 1, "bank uses combine with partial carried uses")
        st.entries[1].countBank = false
        st.mail[100] = 1
        row = A.GetRows(true)[1]
        check(row.mailCount == 5 and row.pending == 5 and row.need == 1, "physical mailbox count converts to uses once")
        st.mail[100] = 0
        st.inventory.snapshots = { mail = { generation = 0 } }
        st.storedMail = { { itemID = 100, itemCount = 1 } }
        check(A.GetRows(true)[1].pending == 5, "cold saved mailbox items also count as uses")
        st.inventory.snapshots, st.storedMail = nil, nil

        row = A.GetRows(true)[1]
        local units = A.Reserve(row, 2)
        check(units == 10 and A.Settings().pending[100].units == 10,
            "two purchased items reserve ten target uses")
        A.AcceptReservation({ itemID = 100 })
        st.mail[100], st.predicted[100] = 1, 1
        row = A.GetRows(true)[1]
        check(row.pending == 10 and row.need == 0, "provider prediction and local receipt do not double count uses")
        st.mail[100], st.predicted[100] = 2, 0
        row = A.GetRows(true)[1]
        check(row.pending == 10 and not A.Settings().pending[100], "authoritative mailbox consumes the reservation once")
        st.mail[100], st.uses[100], st.bags[100] = 0, 12, 3
        row = A.GetRows(true)[1]
        check(row.pending == 0 and row.bagCount == 12 and row.need == 0, "collecting physical mail preserves fulfilled use target")

        -- Consuming an old charge while a purchased copy is in transit cannot
        -- hide part of that physical arrival or leave a phantom pending use.
        st.entries[1].target, st.uses[100], st.bags[100] = 10, 5, 1
        row = A.GetRows(true)[1]
        A.Reserve(row, 1); A.AcceptReservation({ itemID = 100 })
        check(A.Settings().pending[100].itemCount == 1, "new charged reservations remember physical arrival baseline")
        st.uses[100] = 4
        check(A.GetRows(true)[1].pending == 5, "using an owned charge does not consume a pending physical item")
        st.uses[100], st.bags[100] = 9, 2
        row = A.GetRows(true)[1]
        check(not A.Settings().pending[100] and row.pending == 0 and row.need == 1,
            "full physical delivery clears its reservation despite spending an older charge")
        st.entries[1].target, st.uses[100], st.bags[100], st.mail[100] = 20, 4, 1, 1
        row = A.GetRows(true)[1]
        A.Reserve(row, 1); A.AcceptReservation({ itemID = 100 })
        st.uses[100], st.bags[100], st.mail[100] = 9, 2, 0
        check(A.GetRows(true)[1].pending == 5, "collecting older charged mail cannot consume a different incoming copy")
        st.mail[100] = 1
        check(A.GetRows(true)[1].pending == 5 and not A.Settings().pending[100],
            "new authoritative charged mail replaces the physical reservation once")
        st.mail[100], st.entries[1].target = nil, 9

        st.uses, st.bags = {}, {}
        st.charges = nil
        env.FluxRestockItemRegistry.GetItemMaxCharges = function() return 200 end
        check(A.GetRows(true)[1].need == nil, "unresolved registry capacity is not guessed from a physical stack limit")
        st.charges = 2.5
        check(A.GetRows(true)[1].need == nil, "fractional capacity cannot authorize purchases")
        st.charges = 5
        check(not A.CommodityOffer({ { quantity = 20, unitPrice = 101 } }, 2, 100),
            "unit price cap remains per physical item rather than per charge")

        local replace = A.ApplyPotionReplacements
        A.ApplyPotionReplacements = function(rows) rows[1].itemID = 101; return rows end
        row = A.GetRows(true)[1]
        check(row.itemID == 101 and not row.isCharge and row.unitsPerItem == 1 and row.need == 9,
            "replacement SKU does not inherit the previous item capacity")
        A.ApplyPotionReplacements = replace
        env.FluxConsumableBest = { GetBestRef = function() return { itemID = 101 } end }
        env.FluxRestockTiers = { GetTierCount = function() return 7 end, GetBankCountForKind = function() return 2 end }
        st.entries = { { isTierRestock = true, tierKind = "bandage", target = 12, countBank = true } }
        row = A.GetRows(true)[1]
        check(row.need == 3 and row.unitsPerItem == 1 and not row.isCharge,
            "ordinary tier targets retain qualifying aggregate and bank counts")
        env.FluxConsumableBest.GetBestRef = function() return { itemID = 100 } end
        env.FluxRestockTiers.GetTierCount = function() error("physical tier aggregate used for a charge target") end
        env.FluxRestockTiers.GetBankCountForKind = env.FluxRestockTiers.GetTierCount
        env.FluxRestock.Inv.Bank = { GetCount = function(id, opts)
            check(id == 100 and opts.charges == true, "charged tier bank uses the exact SKU charge owner")
            return 3
        end }
        st.uses[100], st.bags[100], st.entries[1].target, st.entries[1].bankCount = 2, 1, 9, 99
        row = A.GetRows(true)[1]
        check(row.need == 1 and row.bagCount == 2 and row.bankCount == 3 and row.unitsPerItem == 5,
            "charged tier target uses exact SKU charges instead of physical tier aggregates")
        st.mail[100] = 1
        check(A.GetRows(true)[1].need == 0, "charged tier credits matching physical mailbox items as uses")
        st.mail[100], env.FluxRestock.Inv.Bank = nil, nil
        check(A.GetRows(true)[1].need == nil, "charged bank preference fails closed without charge-aware bank facts")
        env.FluxConsumableBest, env.FluxRestockTiers = nil, nil

        st.reset(); charged()
        st.uses, st.predicted = {}, {}
        A.Settings().allowExcessStacks = false
        local offers = legacy and { { itemID = 100, quantity = 2, total = 100 } }
            or { { itemID = 100, quantity = 20, unitPrice = 50 } }
        st.start(offers)
        check(A.state == "ready" and A.offer.quantity == 2,
            "unavoidable use rounding is available with excess stacks disabled")
        st.press()
        if legacy then
            check(st.calls.buyStack == 1 and A.transaction.quantity == 2 and A.transaction.units == 10,
                "one legacy press buys one complete two-item listing and reserves ten uses")
            st.legacyReceipt()
        else
            check(st.authorizedQuote.quantity == 2 and st.calls.quote == 1,
                "one modern press requests two physical items for nine uses")
            st.emit("COMMODITY_PRICE_UPDATED", 50, 100)
            check(A.transaction.quantity == 2 and A.transaction.units == 10 and st.calls.confirm == 1,
                "modern confirmation retains physical quantity and use reservation")
            st.emit("COMMODITY_PURCHASE_SUCCEEDED")
        end
        st.drain()
        check(A.Settings().pending[100].accepted and A.Settings().pending[100].units == 10,
            "acknowledged physical receipt credits ten pending uses")
        st.press()
        check((st.calls.buyStack or st.calls.quote) == 1, "fulfilled uses never start a second purchase")

        if legacy then
            st.reset(); charged(); st.uses = {}
            A.Settings().allowExcessStacks = false
            st.start({ { itemID = 100, quantity = 1, total = 50 } })
            st.press(); st.legacyReceipt(); st.drain()
            check(st.calls.buyStack == 1 and A.Settings().pending[100].units == 5
                and A.FindRow(100, true).need == 1, "one legacy listing receipt leaves the remaining physical item available")
            st.press(); st.legacyReceipt(); st.drain()
            check(st.calls.buyStack == 2 and A.Settings().pending[100].units == 10,
                "a second legacy physical item requires its own player press")
            st.reset(); charged(); st.uses = {}
            A.Settings().allowExcessStacks = false
            st.start({ { itemID = 100, quantity = 3, total = 150 } })
            check(not A.offer and not st.calls.buyStack, "larger physical listings still require excess-stack opt-in")
            A.Settings().allowExcessStacks = true
            A.ScanQueue(true); st.drain()
            check(not A.offer and not st.calls.buyStack,
                "charged items reject an oversized physical listing even when ordinary excess is enabled")
        end

        local function Book(id, quantity, unit)
            return { commodity = not legacy, offers = legacy
                and { { itemID = id, quantity = quantity, total = quantity * unit } }
                or { { itemID = id, quantity = quantity, unitPrice = unit } } }
        end
        local function OpenCraft()
            st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        end
        local function Buy(unit, total)
            st.press()
            if legacy then st.legacyReceipt()
            else st.emit("COMMODITY_PRICE_UPDATED", unit, total); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
            st.drain()
        end
        -- A receipt keeps its physical identity when a direct charged target
        -- disappears and that SKU becomes a physical recipe input (or back).
        st.reset(); charged(); st.uses, st.predicted = {}, {}
        A.Settings().allowExcessStacks = false
        st.start(legacy and { { itemID = 100, quantity = 2, total = 100 } }
            or { { itemID = 100, quantity = 20, unitPrice = 50 } })
        Buy(50, 100)
        st.mail[100], st.predicted[100] = 2, 2
        st.entries = { { itemID = 300, name = "Bandage", target = 1 } }
        st.recipeItems = { [300] = true }
        st.recipes = { { recipeID = 76, name = "Bandage", outputItemID = 300, learned = true, legacy = true, quantityMin = 1,
            reagents = { { itemID = 100, count = 3 } } } }
        st.books = { [300] = Book(300, 1, 100), [100] = Book(100, 1, 10) }
        A.ResetCraftPlans(); A.SetMaxPrice(300, 100); A.ScanQueue(true); st.drain()
        local switched = A.FindRow(100, true)
        check(switched.isCraftMaterial and switched.pending == 2 and switched.need == 1
            and A.Settings().pending[100].units == 10 and A.Settings().pending[100].unitScale == 5,
            "two charged receipt copies become two recipe inputs without changing their saved basis")
        check(A.offer and A.offer.itemID == 100 and A.offer.quantity == 1,
            "role transition leaves the third required physical recipe input buyable")
        Buy(10, 10)
        check(A.Settings().pending[100].units == 3 and A.Settings().pending[100].unitScale == 1,
            "next material reservation rebases prior accepted copies into physical items")

        st.reset(); st.charged, st.charges = 200, 5; st.uses, st.predicted = {}, {}
        st.entries = { { itemID = 100, name = "Bandage", target = 1 } }
        st.recipeItems = { [100] = true }
        st.recipes = { { recipeID = 75, name = "Bandage", outputItemID = 100, learned = true, legacy = true, quantityMin = 1,
            reagents = { { itemID = 200, count = 2 } } } }
        st.books = { [100] = Book(100, 1, 100), [200] = Book(200, 2, 10) }
        A.SetMaxPrice(100, 100); OpenCraft(); Buy(10, 20)
        st.entries = { { itemID = 200, name = "Oil", target = 9 } }
        st.mail[200], st.predicted[200] = 2, 2
        A.ResetCraftPlans()
        switched = A.GetRows(true)[1]
        check(switched.pending == 10 and switched.need == 0 and A.Settings().pending[200].units == 2
            and A.Settings().pending[200].unitScale == 1,
            "two physical recipe receipt copies become ten uses without rebasing the saved record")
        st.mail[200], st.predicted[200] = 2, 0
        check(A.GetRows(true)[1].pending == 10 and not A.Settings().pending[200],
            "authoritative delivery consumes a physical reservation after switching to a use target")
        st.mail[200] = nil
        local direct = A.GetRows(true)[1]
        local reserved = A.Reserve(direct, 2)
        A.transaction = { itemID = 200, units = reserved }
        local material = { itemID = 200, target = 3, unitsPerItem = 1, isCraftMaterial = true }
        check(A.Need(material) == 1 and A.Settings().pending[200].units == 10,
            "viewing an active charged reservation as materials preserves its release basis")
        A.Release(200, reserved); A.transaction = nil
        check(not A.Settings().pending[200], "failed transaction releases its original units after a role change")
        -- Recipe yield is physical output. A five-charge output target of nine
        -- needs two crafts, including after the saved AH-to-vendor handoff.
        st.reset(); charged(); st.uses, st.predicted = {}, {}
        st.recipeItems = { [100] = true }
        st.recipes = { { recipeID = 77, name = "Oil", outputItemID = 100, learned = true, legacy = true, quantityMin = 1,
            reagents = { { itemID = 200, count = 2 }, { itemID = 201, count = 1 } } } }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 5 } }
        st.books = { [100] = Book(100, 2, 100), [200] = Book(200, 4, 10) }
        A.SetMaxPrice(100, 100); OpenCraft()
        check(A.craftPlans[100] and A.craftPlans[100].operations == 2
            and A.craftPlans[100].required[200] == 4 and A.craftPlans[100].required[201] == 2,
            "charged recipe output rounds physical crafts and exact ingredient quantities")
        local vendor = A.GetVendorCraftTargets(st.entries)
        check(vendor[201] and vendor[201].target == 2, "saved vendor plan remembers charged output target units")
        st.uses[100], st.bags[100] = 5, 1
        vendor = A.GetVendorCraftTargets(st.entries)
        check(vendor[201] and vendor[201].target == 1, "one owned charged output reduces saved vendor crafts to one")
        st.uses[100], st.bags[100] = 10, 2
        check(not next(A.GetVendorCraftTargets(st.entries)), "enough charged outputs retire saved vendor materials")

        -- Existing charged targets and physical recipe inputs share one SKU.
        -- Protect the partially used copies, then charge only the craft share
        -- of a mixed direct/craft invoice against the output's 25c budget.
        st.reset(); st.charged, st.charges = 200, 5; st.uses, st.predicted = { [200] = 7 }, {}
        st.bags[200] = 2
        st.settings.merchantSources = nil
        st.entries = { { itemID = 100, name = "Bandage", target = 1 },
            { itemID = 200, name = "Oil", target = 9, bankCount = 0 } }
        st.recipeItems = { [100] = true }
        st.recipes = { { recipeID = 78, name = "Bandage", outputItemID = 100, learned = true, legacy = true, quantityMin = 1,
            reagents = { { itemID = 200, count = 2 } } } }
        st.books = { [100] = Book(100, 1, 25), [200] = Book(200, 3, 10) }
        if legacy then st.books[200].offers[2] = { itemID = 200, quantity = 2, total = 20 } end
        A.Settings().allowExcessStacks = false
        A.SetMaxPrice(100, 25); OpenCraft()
        local ingredient = A.FindRow(200, true)
        check(A.craftPlans[100] and A.craftPlans[100].cost == 20 and A.craftPlans[100].budget == 25,
            "charged reagent planner protects the direct target while comparing two craft items")
        check(ingredient.target == 19 and ingredient.baseTarget == 9 and ingredient.unitsPerItem == 5
            and ingredient.bagCount == 7 and ingredient.need == 3,
            "physical craft requirements add uses to an existing charged target once")
        check(A.offer and A.offer.itemID == 200 and A.offer.quantity == 3 and A.offer.total == 30,
            "mixed direct and craft shortage prepares three physical items")
        Buy(10, 30)
        check(A.craftPlans[100].spent == 20 and A.Settings().pending[200].units == 15,
            "30c invoice credits fifteen uses and spends only its 20c recipe share")
        local plan = A.CompareCraft(A.FindRow(100, true), A.CraftRecipes(st.entries[1]), st.books)
        check(plan and plan.cost == 0, "charged pending uses convert back to physical reagents without double reservation")

        -- Without a direct charge target, recipes continue to require physical
        -- copies; five uses in one owned item cannot satisfy four reagents.
        st.reset(); st.charged, st.charges = 200, 5; st.uses, st.predicted = { [200] = 5 }, {}
        st.bags[200] = 1
        st.entries = { { itemID = 100, name = "Bandage", target = 2 } }
        st.recipeItems = { [100] = true }
        st.recipes = { { recipeID = 79, name = "Bandage", outputItemID = 100, learned = true, legacy = true, quantityMin = 1,
            reagents = { { itemID = 200, count = 2 } } } }
        st.books = { [100] = Book(100, 2, 100), [200] = Book(200, 3, 10) }
        A.SetMaxPrice(100, 100); OpenCraft()
        ingredient = A.FindRow(200, true)
        check(ingredient.isCraftMaterial and ingredient.unitsPerItem == 1 and ingredient.target == 4
            and ingredient.bagCount == 1 and ingredient.need == 3,
            "material-only charged SKU counts physical recipe items with an explicit false charge flag")
        Buy(10, 30)
        check(A.Settings().pending[200].units == 3 and A.craftPlans[100].spent == 30,
            "material-only receipt and budget remain in physical item units")
        if legacy then
            st.reset(); st.charged, st.charges = 200, 5; st.uses, st.predicted = {}, {}
            st.entries = { { itemID = 100, name = "Bandage", target = 1 } }
            st.recipeItems = { [100] = true }
            st.recipes = { { recipeID = 80, name = "Bandage", outputItemID = 100, learned = true, legacy = true, quantityMin = 1,
                reagents = { { itemID = 200, count = 2 } } } }
            st.books = { [100] = Book(100, 1, 100), [200] = Book(200, 3, 10) }
            A.Settings().allowExcessStacks = true
            A.SetMaxPrice(100, 100); OpenCraft()
            check(not A.craftPlans[100] and A.offer and A.offer.itemID == 100,
                "physical recipe inputs of a charged SKU cannot use the excess option to buy an oversized stack")
            st.books[200].offers[2] = { itemID = 200, quantity = 2, total = 20 }
            A.ResetCraftPlans()
            A.ScanQueue(true); st.drain()
            check(A.craftPlans[100] and A.offer and A.offer.itemID == 200 and A.offer.quantity == 2,
                "a fitting charged physical reagent listing remains buyable without excess copies")
        end
        st.reset()
        check(#st.errors == 0, "charge flows emit no Lua errors")
    end end
end
-- Real built-in receipt observer/public mail owner, including Syndicator handoff.
-- Item-search quantity is grouped availability; PlaceBid still buys one item.
local incomingExport = setmetatable({ FLUX_INCOMING_FIXTURE_EXPORT = true }, { __index = _G })
local incomingChunk = assert(loadfile("tests/auction_incoming_mail.lua", "t", incomingExport))
if setfenv then setfenv(incomingChunk, incomingExport) end
local incoming = incomingChunk()
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "pending", "ready" }) do
        for _, kind in ipairs(legacy and { "legacy" } or { "item", "commodity_one", "commodity_two" }) do
            receiptProfiles = receiptProfiles + 1
            local A, st, env, saved = incoming(legacy, provider)
            st.charged, st.charges = 100, 5
            env.FluxRestockItemRegistry.GetChargeInfo = function(id) return id == 100, 5 end
            env.FluxRestock.Inv.GetLiveCount = function() return 0 end
            st.entries[1].target = kind == "commodity_one" and 5 or 9
            st.commodity = kind ~= "item"
            local key = env.C_AuctionHouse.MakeItemKey(100)
            local offers = legacy and { { itemID = 100, quantity = 1, total = 10 } }
                or kind == "item" and { { itemKey = key, auctionID = 881, quantity = 2, buyoutAmount = 10, itemLink = "item:100" } }
                or { { itemID = 100, quantity = 20, unitPrice = 10 } }
            st.start(offers)
            local physical = kind == "commodity_two" and 2 or 1
            check(A.offer and A.offer.quantity == physical,
                "each bid buys one physical item; a commodity quote keeps its explicit physical quantity")
            if kind == "item" then
                check(A.offer.availableQuantity == 2 and A.offer.total == 10
                    and env.C_AuctionHouse.GetAuctionInfoByID(881).quantity == nil,
                    "two grouped item auctions retain per-auction price while native AuctionInfo has no quantity")
            end
            st.press()
            if not legacy and kind ~= "item" then st.emit("COMMODITY_PRICE_UPDATED", 10, physical * 10) end
            check(A.transaction and A.transaction.quantity == physical and A.transaction.units == physical * 5,
                "physical quantity converts into charge units once before native completion")
            if legacy then st.legacyReceipt()
            elseif kind == "item" then st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 881)
            else st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
            if provider == "ready" then
                st.inventory.snapshots.mail.counts[100] = physical
                st.inventory.snapshots.mail.generation = st.inventory.snapshots.mail.generation + 1
                check(#saved.mail == 0, "ready Syndicator remains the only incoming-mail owner")
            else
                check(st.inventory.Mail.GetCount(100) == physical and saved.mail[1].itemCount == physical,
                    "actual built-in observer publishes purchased physical quantity rather than grouped availability")
            end
            local row = A.FindRow(100, true)
            local expectedNeed = (kind == "commodity_one" or physical == 2) and 0 or 1
            check(row.pending == physical * 5 and row.need == expectedNeed,
                "one five-charge item shows five pending uses; a legitimate two-item commodity shows ten")
            if legacy then st.emit("CHAT_MSG_SYSTEM", env.ERR_AUCTION_BID_PLACED)
            elseif kind == "item" then st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 881)
            else st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
            check(A.FindRow(100, true).pending == physical * 5,
                "duplicate native completion cannot multiply pending charge credit")
        end
    end
end
print(("Auction restock charges: %d checks PASS; %d profiles +%d real-receipt profiles; native charges/mail/purchases NOT RUN"):format(checks, profiles, receiptProfiles))
