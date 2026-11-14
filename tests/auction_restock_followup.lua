-- Actual AH ACK -> persisted follow-up -> mail -> vendor -> exact recipe action.
-- Explicit native stubs establish intent/identity/count, not in-game permission.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({ FLUX_INCOMING_FIXTURE_EXPORT = true }, { __index = _G })
local fixtureChunk = assert(loadfile("tests/auction_incoming_mail.lua", "t", export))
if setfenv then setfenv(fixtureChunk, export) end
local incoming = fixtureChunk()
local function Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for k, v in pairs(value) do out[k] = Copy(v) end; return out
end
local function Fixture(legacy, provider, savedSettings)
    local A, st, env = incoming(legacy, provider)
    st.followEvents, st.takes, st.vendorBuys, st.crafts, st.opens = {}, {}, {}, {}, {}
    st.inbox, st.liveVendor = {}, { price = 5, batch = 1, stock = -1, purchasable = true, extended = false, itemID = 201 }
    local events, register, unregister = st.flux.Events, st.flux.Events.Register, st.flux.Events.Unregister
    events.Register = function(event, fn)
        st.followEvents[event] = st.followEvents[event] or {}; st.followEvents[event][fn] = true
        return register(event, fn)
    end
    events.Unregister = function(event, fn)
        if st.followEvents[event] then st.followEvents[event][fn] = nil end
        return unregister(event, fn)
    end
    st.entries = { { itemID = 100, name = "Bandage", texture = 100, target = 3 } }
    st.bags[100] = 1
    st.recipeItems = { [100] = 7 }
    st.recipes = { { recipeID = 77, outputItemID = 100, name = "Bandage", learned = true, legacy = legacy,
        skillName = "First Aid", skillLineID = 129, quantityMin = 1,
        reagents = { { itemID = 200, count = 1 }, { itemID = 201, count = 1 } } } }
    local function Book(id, q, price)
        return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = q, total = q * price } }
            or { { itemID = id, quantity = q, unitPrice = price } } }
    end
    st.books = { [100] = Book(100, 2, 100), [200] = Book(200, 2, 10) }
    st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 5 } }
    if savedSettings then st.settings.auctionRestock = Copy(savedSettings) end
    local function Hardware(action)
        check(st.hardware and not st.combat, action .. " needs a fresh player press outside combat")
    end
    env.GetInboxNumItems = function() return #st.inbox end
    env.GetInboxHeaderInfo = function(index)
        local mail = st.inbox[index]
        return nil, nil, nil, nil, nil, mail.cod or 0, 30, #mail.items, false, false, false, false, mail.gm == true
    end
    env.GetInboxItem = function(index, slot)
        local item = st.inbox[index].items[slot]
        if item then return "Item" .. item.itemID, item.itemID, 1, item.quantity end
    end
    env.TakeInboxItem = function(index, slot)
        check(not st.combat and st.mailboxOpen, "mail owner collects only outside combat with mailbox open")
        st.takes[#st.takes + 1] = { index = index, slot = slot, item = Copy(st.inbox[index].items[slot]) }
    end
    env.GetMerchantItemLink = function(slot) return slot == 7 and "item:" .. st.liveVendor.itemID end
    env.FluxVendorBuy = { GetMerchantSlotInfo = function(slot)
        check(slot == 7, "current merchant metadata is read from the verified slot")
        local v = st.liveVendor
        return "Vial", 1, v.price, v.batch, v.stock, v.purchasable, true, v.extended
    end }
    local vendor = env.FluxVendorAuto
    vendor.GetMerchantItemIndex = function() return { [201] = { slot = 7, price = 999, unitPrice = 999, batchQty = 9 } } end
    vendor.IsMerchantIndexBuildPending = function() return st.vendorIndexPending == true end
    vendor.IsRestockBuyActive = function() return st.otherVendorBuy == true end
    vendor.ComputeRestockPurchaseQty = function(need, meta, money, id)
        check(id == 201 and meta.price == st.liveVendor.price and meta.batchQty == st.liveVendor.batch
            and meta.numAvailable == st.liveVendor.stock, "purchase uses current merchant facts rather than the stale cached price")
        local count = math.min(need, math.floor(money / meta.unitPrice))
        if meta.numAvailable >= 0 then count = math.min(count, meta.numAvailable) end
        return count
    end
    vendor.DoRestockManual = function()
        check(st.hardware and st.merchantOpen, "HUD delegates manual vendor work in the current interaction")
        st.vendorRequests = (st.vendorRequests or 0) + 1
    end
    vendor.DoAuctionFollowup = function(manual)
        check(manual == true, "HUD vendor request retains its explicit manual intent")
        return vendor.DoRestockManual()
    end
    vendor.AddBatchCopper = function(delta) st.vendorCopper = (st.vendorCopper or 0) + delta end
    env.BuyMerchantItem = function(slot, count)
        Hardware("BuyMerchantItem"); st.vendorBuys[#st.vendorBuys + 1] = { slot = slot, quantity = count }
    end
    env.UnitCastingInfo = function() if st.casting then return "Bandage" end end
    env.UnitChannelInfo = function() return nil end
    env.GetTradeskillRepeatCount = function() return st.repeatCount or 0 end
    env.GetTradeSkillLine = function() return st.professionName end
    env.IsTradeSkillLinked = function() return st.foreignProfession == true end
    env.CastSpellByName = function(name)
        Hardware("CastSpellByName"); st.opens[#st.opens + 1] = name
    end
    env.GetNumTradeSkills = function() return 3 end
    env.GetTradeSkillInfo = function(index)
        return index == 1 and "First Aid" or index == 3 and "Bandage" or "Other", index == 1 and "header" or "optimal"
    end
    env.GetTradeSkillItemLink = function(index) return "item:" .. (index == 3 and (st.outputID or 100) or 999) end
    env.GetTradeSkillNumMade = function() return 1 end
    env.GetTradeSkillNumReagents = function() return 2 end
    env.GetTradeSkillReagentInfo = function(_, slot) return "Item" .. slot, 1, 1 end
    env.GetTradeSkillReagentItemLink = function(_, slot) return "item:" .. (slot == 1 and 200 or 201) end
    env.SelectTradeSkill = function(index) check(index == 3, "legacy craft selects the verified exact recipe index") end
    env.DoTradeSkill = function(index, count)
        Hardware("DoTradeSkill"); check(index == 3, "legacy craft never uses an unverified recipe index")
        st.crafts[#st.crafts + 1] = { index = index, quantity = count }; st.casting, st.repeatCount = true, count
    end
    env.Enum = { CraftingReagentType = { Basic = 0 } }
    env.C_TradeSkillUI = {
        GetRecipeInfo = function(id) return id == 77 and { learned = true, name = "Bandage" } end,
        GetRecipeSchematic = function(id)
            if id ~= 77 then return end
            return { outputItemID = 100, quantityMin = 1, reagentSlotSchematics = {
                { required = true, reagentType = 0, quantityRequired = 1, dataSlotIndex = 1, reagents = { { itemID = 200 } } },
                { required = true, reagentType = 0, quantityRequired = 1, dataSlotIndex = 2, reagents = { { itemID = 201 } } },
            } }
        end,
        GetRecipeOutputItemData = function() return { itemID = st.outputID or 100 } end,
        IsTradeSkillReady = function() return st.professionID ~= nil end,
        IsDataSourceChanging = function() return false end,
        OpenTradeSkill = function(id) Hardware("OpenTradeSkill"); st.opens[#st.opens + 1] = id; return true end,
        CraftRecipe = function(id, count, allocation, orderID, quality, concentration)
            Hardware("CraftRecipe")
            check(id == 77 and orderID == nil and quality == nil and concentration == false,
                "modern craft uses only the planned recipe without order/quality/concentration surprises")
            local allocated = {}; for _, entry in ipairs(allocation) do allocated[entry.reagent.itemID] = entry.quantity end
            check(allocated[200] == 1 and allocated[201] == 1, "modern craft uses the exact saved reagent allocation")
            st.crafts[#st.crafts + 1] = { recipeID = id, quantity = count }; st.casting = true
        end,
    }
    st.inventory.Professions.GetOpenProfessionInfo = function() return { professionID = st.professionID } end
    if not legacy then
        st.recipes[1].craftingData = { version = 1, complete = true, supportsQualities = false,
            schematic = env.C_TradeSkillUI.GetRecipeSchematic(77) }
    end
    for _, name in ipairs({ "FluxAuctionRestockFollowup", "FluxAuctionRestockFollowupCraft" }) do
        local source = assert(loadfile(root .. "/Inventory/Restock/Auction/" .. name .. ".lua", "t", env))
        if setfenv then setfenv(source, env) end
        source("_FluxUI", { Flux = st.flux })
    end
    local F = A.Followup
    F.Paint = function(state) st.painted = state end
    function st.followPress()
        st.hardware = true; F.Click(); st.hardware = false
    end
    function st.mailTake()
        if st.combat or not st.mailboxOpen then return end
        local items = F.GetMailItems()
        for index = #st.inbox, 1, -1 do
            local mail = st.inbox[index]
            if not mail.cod and not mail.gm then
                for slot, item in pairs(mail.items) do
                    if items[item.itemID] and item.quantity <= items[item.itemID]
                        and F.MailTakeStarted(item.itemID, item.quantity) then env.TakeInboxItem(index, slot); return end
                end
            end
        end
    end
    function st.openAH()
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
    end
    function st.ack()
        if legacy then st.legacyReceipt() else st.emit("COMMODITY_PRICE_UPDATED", 10, 20); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        st.drain()
    end
    function st.deliverTake()
        local take = st.takes[#st.takes]
        st.bags[take.item.itemID] = (st.bags[take.item.itemID] or 0) + take.item.quantity
        st.inbox[take.index].items[take.slot] = nil
        st.emit("BAG_UPDATE_DELAYED"); F.MailTakeFinished()
    end
    return A, st, env, F
end
if FLUX_FOLLOWUP_FIXTURE_EXPORT then return Fixture end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "ready" }) do
        profiles = profiles + 1
        local A, st, env, F = Fixture(legacy, provider)
        F.Refresh()
        check(not F.GetState() and not A.Settings().followup and not st.inventoryListeners,
            "an idle restock has no job, reminder or demand inventory subscription")
        st.openAH()
        check(A.offer and A.offer.itemID == 200 and A.offer.quantity == 2 and not next(F.GetMailItems()),
            "pricing prepares selected recipe work without inventing an auction receipt")
        st.press()
        check(not next(F.GetMailItems()), "unacknowledged submission cannot create a mail receipt")
        st.ack()
        check(F.GetState() and F.GetState().kind == "mail" and F.GetState().items[200] == 2
            and A.Settings().followup.outputs[100].skillLineID == 129,
            "actual restock ACK records physical quantity and exact selected recipe/profession")
        local recipe = A.Settings().followup.outputs[100]
        check(recipe.recipeID == 77 and recipe.recipeName == "Bandage" and recipe.skillName == "First Aid"
            and recipe.row.itemID == 100 and recipe.yield == 1 and recipe.required[200] == 1 and recipe.required[201] == 1
            and type(recipe.bankFlags) == "table",
            "saved button task retains profession, exact recipe, output, yield, reagents and per-ingredient bank flags")
        A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
        local persisted = Copy(A.Settings())
        A, st, env, F = Fixture(legacy, provider, persisted)
        F.Refresh()
        check(F.GetState().kind == "mail" and F.GetState().items[200] == 2
            and st.inventoryListeners["AuctionRestock.Followup"], "reload preserves unfinished work while the auction house is closed")
        st.reliable, st.bags[200] = false, 99; F.Refresh()
        check(A.Settings().followup.receipts[200].remaining == 2, "unreliable/loading bag facts cannot erase a bought receipt")
        st.reliable, st.bags[200] = true, 0; F.Refresh()
        st.inbox = {
            { items = { { itemID = 200, quantity = 1 }, { itemID = 200, quantity = 1 } } },
            { items = { { itemID = 999, quantity = 99 } } },
            { cod = 10, items = { { itemID = 200, quantity = 5 } } },
            { gm = true, items = { { itemID = 200, quantity = 5 } } },
        }
        st.followPress(); check(#st.takes == 0, "mail action cannot collect without an open mailbox")
        st.combat = true; st.mailboxOpen = true; st.emit("MAIL_SHOW"); st.followPress()
        check(#st.takes == 0 and st.painted == nil, "combat can neither show the reminder nor collect mail")
        st.combat = false; F.Refresh(); st.followPress()
        check(#st.takes == 0, "HUD mail reminder never loots attachments")
        st.mailTake()
        check(#st.takes == 1 and st.takes[1].index == 1 and st.takes[1].slot == 1,
            "one press collects one planned attachment, skipping COD, GM and unrelated items")
        st.mailTake(); check(#st.takes == 1, "mail latency cannot duplicate the same outstanding take")
        st.deliverTake()
        check(F.GetState().kind == "mail" and F.GetState().items[200] == 1, "first attachment arrival leaves exactly one physical item outstanding")
        st.mailTake(); check(#st.takes == 2 and st.takes[2].slot == 2, "second attachment requires a new press")
        st.deliverTake(); st.mailboxOpen = false; st.emit("MAIL_CLOSED")
        check(F.GetState().kind == "vendor" and F.GetState().items[201] == 2 and #st.vendorBuys == 0,
            "collected auction materials prepare the exact missing vendor materials without buying")
        st.followPress(); check(#st.vendorBuys == 0, "vendor action cannot buy outside a merchant interaction")
        st.merchantOpen = true; st.emit("MERCHANT_SHOW"); st.followPress()
        check(st.vendorRequests == 1 and #st.vendorBuys == 0,
            "HUD delegates to the existing manual vendor queue instead of owning purchases")
        st.bags[201] = 2; st.emit("BAG_UPDATE_DELAYED"); st.merchantOpen = false; st.emit("MERCHANT_CLOSED")
        check(F.GetState().kind == "craft" and F.GetState().task.parentID == 100 and F.GetState().task.operations == 2,
            "bag arrival prepares exactly two crafts of the selected output SKU")
        st.followPress()
        check(#st.opens == 1 and st.opens[1] == (legacy and "First Aid" or 129) and #st.crafts == 0,
            "closed profession opens only the saved profession and waits for its asynchronous readiness")
        st.professionName, st.professionID = "First Aid", 129; st.emit("TRADE_SKILL_SHOW")
        check(#st.crafts == 0 and F.GetState().kind == "craft", "profession callbacks never start crafting automatically")
        st.outputID = 999; st.followPress()
        check(#st.crafts == 0, "a recipe resolving to a different output SKU cannot craft")
        st.outputID, st.foreignProfession = nil, true; st.followPress()
        check(#st.crafts == 0, "linked or foreign profession state cannot authorize crafting")
        st.foreignProfession = false; st.followPress()
        check(#st.crafts == 1 and st.crafts[1].quantity == 2 and F.GetState().kind == "crafting" and F.GetState().quantity == 2,
            "one fresh press queues the exact planned craft count")
        st.bags[200], st.bags[201] = 0, 0; st.emit("BAG_UPDATE_DELAYED")
        check(F.GetState().kind == "crafting" and #st.crafts == 1,
            "an active batch remains crafting after its materials are consumed")
        st.followPress(); st.emit("TRADE_SKILL_LIST_UPDATE")
        check(#st.crafts == 1, "repeated clicks and profession callbacks cannot duplicate the active batch")
        st.bags[100], st.casting, st.repeatCount = 3, false, 0; st.emit("BAG_UPDATE_DELAYED")
        check(not F.GetState() and not A.Settings().followup and not st.inventoryListeners["AuctionRestock.Followup"],
            "finished output clears the job, reminder and demand inventory subscription")
        check(not next(st.followEvents.MAIL_SHOW or {}) and not next(st.followEvents.MERCHANT_SHOW or {})
            and not next(st.followEvents.TRADE_SKILL_SHOW or {}), "finished follow-up detaches its world-action event listeners")

        -- Only acknowledged private reservations can bootstrap an older saved session.
        local resume = Copy(persisted); resume.followup = nil
        A, st, env, F = Fixture(legacy, provider, resume)
        st.emit("PLAYER_LOGIN")
        check(F.GetState() and F.GetState().kind == "mail" and F.GetState().items[200] == 2,
            "login resumes two physical items from an accepted restock reservation")
        check(A.Settings().followup.outputs[100] and A.Settings().followup.outputs[100].skillLineID == 129,
            "accepted purchase plus exact saved vendor recipe restores the selected output snapshot")
        st.bags[200] = 2; F.Refresh()
        check(F.GetState() and F.GetState().kind == "vendor" and F.GetState().items[201] == 2,
            "resumed recipe survives equivalent nil/false count-bank flags and prepares vendor work")
        st.bags[100], st.bags[201] = 3, 2; F.Refresh()
        check(not F.GetState() and not A.Settings().followup, "resumed work retires when its output target is fulfilled")
        resume.vendorCraftPlans = nil
        A, st, env, F = Fixture(legacy, provider, resume)
        st.reliable = false; st.emit("PLAYER_LOGIN")
        check(not F.GetState() and st.inventoryListeners["AuctionRestock.Followup.Resume"],
            "accepted reservations wait for reliable login inventory through the existing inventory service")
        st.reliable = true; st.inventoryListeners["AuctionRestock.Followup.Resume"]()
        check(F.GetState().kind == "mail" and F.GetState().items[200] == 2
            and not st.inventoryListeners["AuctionRestock.Followup.Resume"],
            "inventory readiness resumes proved work and removes its temporary readiness subscription")
        A, st, env, F = Fixture(legacy, provider, resume); st.emit("PLAYER_LOGIN")
        st.bags[200] = 2; F.Refresh()
        check(not F.GetState() and not A.Settings().followup, "resumed direct receipt alone ends as soon as its physical items arrive")
        resume = Copy(persisted); resume.followup, resume.pending = nil, {}
        A, st, env, F = Fixture(legacy, provider, resume); st.inventory.snapshots.mail.counts[100] = 99; st.emit("PLAYER_LOGIN")
        check(not F.GetState() and not next(F.GetMailItems()),
            "an already fulfilled output cannot create work from unrelated cached mail")
        resume.pending[200] = { units = 2, accepted = false, acceptedUnits = 0, unitScale = 1, totalCount = 0 }
        A, st, env, F = Fixture(legacy, provider, resume); st.emit("PLAYER_LOGIN")
        check(not next(F.GetMailItems()), "unacknowledged saved attempts cannot bootstrap mail work")

        -- A direct purchase needs only collection, without retaining a craft job.
        A, st, env, F = Fixture(legacy, provider)
        st.recipes, st.recipeItems = {}, {}
        st.entries[1].target = 2
        st.books[100].offers = legacy and { { itemID = 100, quantity = 1, total = 10 } }
            or { { itemID = 100, quantity = 10, unitPrice = 10 } }
        st.openAH(); st.press()
        if legacy then st.legacyReceipt() else st.emit("COMMODITY_PRICE_UPDATED", 10, 10); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        check(F.GetState().kind == "mail" and F.GetState().items[100] == 1 and not next(A.Settings().followup.outputs),
            "direct purchase activates only its own one-item collection work")
        st.mailboxOpen = true; st.emit("MAIL_SHOW"); st.bags[100] = 2; F.Refresh()
        check(not F.GetState() and not A.Settings().followup and not st.inventoryListeners["AuctionRestock.Followup"],
            "direct item arrival finishes while its mailbox is still open")

        -- Older same-SKU inbox stock is part of the outstanding collection work.
        A, st, env, F = Fixture(legacy, provider)
        st.recipes, st.recipeItems = {}, {}
        st.entries[1].target = 4; st.inventory.snapshots.mail.counts[100] = 2
        st.books[100].offers = legacy and { { itemID = 100, quantity = 1, total = 10 } }
            or { { itemID = 100, quantity = 10, unitPrice = 10 } }
        st.openAH(); check(A.offer.quantity == 1, "older two inbox items reduce this restock purchase to one")
        st.press()
        if legacy then st.legacyReceipt() else st.emit("COMMODITY_PRICE_UPDATED", 10, 10); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        check(F.GetState().kind == "mail" and F.GetState().items[100] == 3,
            "new one-item receipt retains the older two items awaiting collection")
        A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
        st.inbox = { { items = { { itemID = 100, quantity = 2 }, { itemID = 100, quantity = 1 } } } }
        st.mailboxOpen = true; st.emit("MAIL_SHOW"); st.mailTake(); st.deliverTake()
        check(F.GetState().kind == "mail" and F.GetState().items[100] == 1,
            "collecting the older two leaves the new purchased item outstanding")
        st.mailTake(); st.deliverTake()
        check(not F.GetState() and not A.Settings().followup, "final same-SKU attachment completes the direct job before mailbox close")

        -- A synchronous native block can clear the in-flight local attempt.
        A, st, env, F = Fixture(legacy, provider)
        st.openAH(); st.press(); st.ack(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
        st.bags[200], st.bags[201], st.professionName, st.professionID = 2, 2, "First Aid", 129; F.Refresh()
        local blocked = 0
        local function BlockCraft()
            check(st.hardware and not st.combat, "blocked native craft still receives only the current hardware click")
            blocked = blocked + 1
            st.emit("ADDON_ACTION_BLOCKED", "_FluxUI", legacy and "DoTradeSkill" or "CraftRecipe")
        end
        if legacy then env.DoTradeSkill = BlockCraft else env.C_TradeSkillUI.CraftRecipe = BlockCraft end
        st.followPress()
        check(blocked == 1 and #st.crafts == 0 and F.GetState().kind ~= "crafting",
            "synchronously blocked craft neither crashes nor resurrects its cleared busy attempt")

        -- Taking one bought charged copy can coincide with using an old last charge.
        A, st, env, F = Fixture(legacy, provider)
        st.recipes, st.recipeItems = {}, {}
        st.charged, st.charges, st.entries[1].target, st.uses = 100, 5, 6, { [100] = 1 }
        local live = env.FluxRestock.Inv.GetLiveCount
        env.FluxRestock.Inv.GetLiveCount = function(id, opts)
            if id == 100 and opts.charges then return st.uses[id] or 0 end
            return live(id, opts)
        end
        st.books[100].offers = legacy and { { itemID = 100, quantity = 1, total = 10 } }
            or { { itemID = 100, quantity = 10, unitPrice = 10 } }
        st.openAH(); check(A.offer.quantity == 1, "one old remaining charge needs exactly one new physical five-use item")
        st.press()
        if legacy then st.legacyReceipt() else st.emit("COMMODITY_PRICE_UPDATED", 10, 10); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
        st.inbox = { { items = { { itemID = 100, quantity = 1 } } } }
        local scanFrame
        local create = env.CreateFrame
        env.CreateFrame = function(...) local frame = create(...); scanFrame = frame; return frame end
        local function PublishInbox()
            if provider == "ready" then
                -- External-provider publication: same owned source contract, no built-in write.
                st.inventory.snapshots.mail.counts[100] = st.inbox[1].items[1] and 1 or 0
                st.inventory.snapshots.mail.generation = st.inventory.snapshots.mail.generation + 1
            else
                st.inventory.Builtin.Mail.Refresh({ force = true })
                st.advance(0.2); assert(scanFrame):Fire("OnUpdate")
            end
            st.emit("MAIL_INBOX_UPDATE")
        end
        PublishInbox(); st.mailboxOpen = true; st.emit("MAIL_SHOW")
        check(F.GetState().items[100] == 1 and A.Settings().pending[100] and A.Settings().pending[100].accepted,
            "one actual charged attachment retains its matching accepted private reservation")
        local generation = st.inventory.snapshots.mail.generation
        st.mailTake()
        check(#st.takes == 1 and st.takes[1].item.quantity == 1, "owned click takes exactly the new charged attachment")
        st.bags[100], st.uses[100], st.inbox[1].items[1] = 1, 5, nil
        PublishInbox()
        check(st.inventory.snapshots.mail.generation > generation and st.inventory.Mail.GetCount(100) == 0
            and st.bags[100] == 1, "authoritative inbox changes while net physical bag copies remain one")
        check(not F.GetState() and not A.Settings().followup and not A.Settings().pending[100] and st.painted == nil,
            "matching take proof clears receipt, private pending and reminder despite net bag copies one-to-one")

        -- Crafting may consume the recipe's stock only after protecting direct targets.
        A, st, env, F = Fixture(legacy, provider)
        st.entries[2] = { itemID = 200, name = "Cloth", target = 10 }
        st.bags[200], st.bags[201] = 10, 2
        st.openAH()
        check(A.offer and A.offer.itemID == 200 and A.offer.quantity == 2,
            "direct cloth target ten remains protected when buying two craft materials")
        st.press(); st.ack(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
        st.bags[200] = 12; F.Refresh()
        check(F.GetState().kind == "craft" and F.GetState().task.operations == 2,
            "twelve owned cloth leave exactly two available after protecting ten direct stock")
        local task = Copy(F.GetState().task)
        st.bags[200] = 10; F.Refresh()
        check(F.GetState().kind == "waiting" and F.GetState().items[200] == 2,
            "moving the two recipe cloth out leaves a two-cloth shortage instead of consuming direct stock")
        st.followPress()
        check(#st.crafts == 0 and #st.opens == 0, "missing allocated recipe stock cannot trigger crafting or profession opening")
        st.professionName, st.professionID = "First Aid", 129
        st.hardware = true; local status = F.CraftClick(task); st.hardware = false
        check(status == "unavailable" and #st.crafts == 0,
            "craft driver independently rechecks protected direct stock before the native call")

        -- A failed/unknown purchase and unrelated native/manual purchases do not activate this workflow.
        A, st, env, F = Fixture(legacy, provider)
        st.openAH(); st.press()
        if legacy then st.advance(16) else st.emit("COMMODITY_PRICE_UPDATED", 10, 20); st.emit("COMMODITY_PURCHASE_FAILED") end
        check(not next(F.GetMailItems()), "failed or unacknowledged purchase never becomes mail work")
        A, st, env, F = Fixture(legacy, provider)
        st.hardware = true
        if legacy then
            st.offers = { { itemID = 999, quantity = 1, total = 1 } }; env.PlaceAuctionBid("list", 1, 1)
        else env.C_AuctionHouse.StartCommoditiesPurchase(999, 1, 1); env.C_AuctionHouse.ConfirmCommoditiesPurchase(999, 1) end
        st.hardware = false
        st.emit(legacy and "CHAT_MSG_SYSTEM" or "COMMODITY_PURCHASE_SUCCEEDED", env.ERR_AUCTION_BID_PLACED)
        check(not A.Settings().followup and not F.GetState() and not st.inventoryListeners,
            "unrelated native purchases never create this restock's follow-up reminder")
    end
end
print(("Auction restock follow-up: %d checks PASS; %d client/provider profiles; native mail/vendor/craft permissions NOT RUN"):format(checks, profiles))
