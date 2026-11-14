-- Real profession store/serializer, AH receipts, mailbox worker and storm owner.
-- Native interactions remain explicit fixtures, never an in-game success claim.
local root = os.getenv("FLUX_AH_ROOT") or "."
-- WoW's table primitive is needed by the actual profession cache invalidator.
wipe = wipe or function(value) for key in pairs(value) do value[key] = nil end; return value end
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function Export(path, flag)
    local env = setmetatable({ [flag] = true }, { __index = _G })
    return assert(loadfile(root .. "/tests/" .. path .. ".lua", "t", env))()
end
local cacheFixture = Export("character_recipe_cache", "FLUX_CHARACTER_RECIPE_FIXTURE_EXPORT")
local mailFixture = Export("mail_restock", "FLUX_MAIL_RESTOCK_FIXTURE_EXPORT")
local function Saved(value)
    local function Literal(v)
        if type(v) == "number" or type(v) == "boolean" then return tostring(v) end
        if type(v) == "string" then return ("%q"):format(v) end
        assert(type(v) == "table", "saved workflow contains plain facts only")
        local out = { "{" }; for key, item in pairs(v) do out[#out + 1] = "[" .. Literal(key) .. "]=" .. Literal(item) .. "," end
        out[#out + 1] = "}"; return table.concat(out)
    end
    return assert(load("return " .. Literal(value)))()
end
local function StormOwner(st, env)
    local file = assert(io.open(root .. "/Inventory/Init.lua", "rb")); local text = file:read("*a"); file:close()
    local first = assert(text:find("local STORM_HOLD = 0.25", 1, true))
    local last = assert(text:find("function Inv.SetMerchantOpen", first, true))
    env.C_Timer.After = function(delay, callback) return env.C_Timer.NewTimer(delay, callback) end
    st.flux.Safecall = function(callback, ...) return callback(...) end
    local chunk = assert(load("local _, ns = ...; local Flux, Inv = ns.Flux, ns.Flux.Inventory\n" .. text:sub(first, last - 1), "@Inventory/Init.lua:storm-owner", "t", env))
    chunk("_FluxUI", { Flux = st.flux })
    st.inventory.IsMailboxOpen = function() return st.mailboxOpen == true end
end
local function Book(legacy, id, quantity, price)
    return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = quantity, total = quantity * price } }
        or { { itemID = id, quantity = quantity, unitPrice = price } } }
end
do
    local _, st, env = cacheFixture("Retail", false, false)
    StormOwner(st, env)
    local inv, calls = st.inventory, {}
    local function Tick(name) calls[name] = (calls[name] or 0) + 1 end
    local replacement = function() Tick("replacement") end
    local stable = function() Tick("stable") end
    inv.RegisterStormSettled("stable", stable); inv.RegisterStormSettled("stable", stable)
    inv.RegisterStormSettled("cancel", function() Tick("cancel") end)
    inv.RegisterStormSettled("replace", function() Tick("old") end)
    inv.RegisterStormSettled("self", function()
        Tick("self"); inv.UnregisterStormSettled("self")
        inv.RegisterStormSettled("next", function() Tick("next") end)
    end)
    inv.NotifyBagStorm(.25)
    inv.OnStormSettled(function()
        Tick("one"); inv.UnregisterStormSettled("cancel")
        inv.RegisterStormSettled("stable", stable)
        inv.RegisterStormSettled("replace", replacement)
        inv.RegisterStormSettled("added", function() Tick("added") end)
    end)
    st.advance(.31)
    check(calls.one == 1 and calls.stable == 1 and calls.self == 1
        and not calls.cancel and not calls.old and not calls.replacement and not calls.added and not calls.next,
        "actual storm dispatch permits cancellation/replacement/self-removal and defers all new registrations")
    inv.NotifyBagStorm(.25); st.advance(.31)
    check(calls.stable == 2 and calls.replacement == 1 and calls.added == 1 and calls.next == 1
        and calls.self == 1 and calls.one == 1,
        "next actual settle invokes each still-current registration once without invalid-next errors")
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "pending", "ready" }) do
        for _, countBank in ipairs({ false, true }) do
            profiles = profiles + 1
            local A, st, env, P, loadRuntime = cacheFixture(client, false, provider ~= "absent")
            P.ForceScanOpen()
            check(#P.ListRecipesForOutput(100) == 1, "an actual owned profession scan saves the learned output before restocking")
            st.dataMode = "offline"
            if provider == "pending" then env.GetProfessions = function() return end; P.InvalidateSkillCaches() end
            st.settings.restockItems[201] = { targetQuantity = 0, countBank = countBank }
            st.bankItems = { [201] = 5 }
            env.FluxRestock.Inv.Bank = { GetCount = function(id) return st.bankItems[id] or 0 end }
            A.SetMaxPrice(100, 100, false)
            env.C_TradeSkillUI = env.C_TradeSkillUI or {}
            env.C_TradeSkillUI.OpenTradeSkill = function() error("planning must not open a profession") end
            env.C_TradeSkillUI.CraftRecipe = function() error("planning must not craft") end
            env.CastSpellByName = function() error("planning must not cast a profession") end
            StormOwner(st, env); loadRuntime("Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua")
            local F = A.Followup
            st.books = { [100] = Book(legacy, 100, 10, 100), [200] = Book(legacy, 200, 10, 10) }
            st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
            check(A.craftPlans[100] and A.offer and A.offer.itemID == 200 and A.offer.quantity == 10,
                "closed saved profession selects exact ten AH materials without opening its UI")
            st.press()
            if legacy then st.legacyReceipt() else st.emit("COMMODITY_PRICE_UPDATED", 10, 100); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
            A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
            local selectedPlan, selectedSource = A.craftPlans[100], A.Settings().vendorCraftPlans[100]
            st.inventory.NotifyBagStorm(.25); A.GetRows(true)
            check(A.craftPlans[100] == selectedPlan and A.Settings().vendorCraftPlans[100] == selectedSource,
                "a transient nil shortage retains the selected recipe and vendor-source snapshot")
            st.advance(.31)
            local targetRows = st.entries; st.entries = {}; A.GetRows(true)
            check(A.craftPlans[100] == selectedPlan and A.Settings().vendorCraftPlans[100] == selectedSource,
                "a temporarily empty target provider retains the exact in-memory recipe and saved source counterpart")
            check(not next(A.GetVendorCraftTargets({})) and A.Settings().vendorCraftPlans[100] == selectedSource,
                "missing target rows emit no vendor goals without destroying the selected source invoice")
            st.entries = targetRows; A.GetRows(true)
            local settings, professionDB = Saved(st.settings), Saved(env.FluxInvDB)
            check(settings.auctionRestock.followup.outputs[100].recipeOwner == "Realm-Alice"
                and settings.auctionRestock.vendorCraftPlans[100].recipeVerified == true,
                "selected recipe provenance, output, materials and profession persist with the current character")
            if provider == "pending" then settings.auctionRestock.followup = nil end

            -- A fresh Lua environment models logout/login with only serialized
            -- recipe/settings facts. No open tradeskill data is available.
            A, st, env, P, loadRuntime = cacheFixture(client, false, provider ~= "absent", professionDB, "Alice", true)
            st.settings.auctionRestock, st.settings.restockItems = settings.auctionRestock, settings.restockItems
            if provider == "pending" then env.GetProfessions = function() return end; P.InvalidateSkillCaches() end
            st.bankItems = { [201] = 5 }
            env.FluxRestock.Inv.Bank = { GetCount = function(id) return st.bankItems[id] or 0 end }
            StormOwner(st, env)
            loadRuntime("Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua"); F = A.Followup
            st.inventory.NotifyBagStorm(.25); st.reliable = false; st.emit("PLAYER_LOGIN")
            if provider == "pending" then
                check(not A.Settings().followup and st.inventoryListeners["AuctionRestock.Followup.Resume"],
                    "a saved selected plan without a job waits for inventory using its owned login subscription")
            else
                check(A.Settings().followup.outputs[100] and F.GetMailItems()[200] == 10,
                    "login with unavailable inventory retains both the receipt and exact saved recipe")
            end
            st.reliable = true; st.advance(.31)
            check(F.GetState() and F.GetState().kind == "mail" and #P.ListRecipesForOutput(100) == 1,
                "the existing storm owner resumes saved work with the profession closed")
            check(A.Settings().followup.outputs[100].required[200] == 2
                and A.Settings().followup.outputs[100].required[201] == 1,
                "login restores every saved per-craft material even without a prior follow-up job or live recipe UI")
            check(A.CraftRecipes({ itemID = 100 })[1].yield == 2 and A.GetMaxPrice(100) == 100
                and not A.IsPriceUnlimited(100), "reloaded cached yield and explicit finite cap remain unchanged")
            local authoritativeKnowledge = P.GetRecipeKnowledge
            P.GetRecipeKnowledge = function() return false end
            check(#A.CraftRecipes({ itemID = 100 }) == 0,
                "an explicit recipe revocation cannot be bypassed by a stale positive cached catalogue")
            P.GetRecipeKnowledge = authoritativeKnowledge

            local ms = mailFixture(client:lower(), provider == "ready" and "syndicator" or "builtin", true)
            ms.env.FluxAuctionRestock, st.flux.Mail = A, ms.mail
            ms.mail.SetSetting("Restock", "AutoCollect", false)
            ms.inbox = { { sender = "AH", subject = "Materials", money = 0, cod = 0,
                items = { { id = 200, quantity = 10 }, { id = 999, quantity = 1 } } } }
            st.mailboxOpen = true; ms:show(); st.emit("MAIL_SHOW"); ms:update()
            st.inventory.NotifyBagStorm(.25)
            F.Click(); ms:pumpFrames(6)
            check(ms.pending and #ms.calls == 1 and ms.calls[1].id == 200,
                "actual restock mailbox worker takes only this job's AH attachment")
            st.bags[200] = 10; ms:ack(); ms:advance(.6)
            check(not next(F.GetMailItems()) and F.GetState().kind == "waiting",
                "native take proof clears mail while unsettled bag facts defer later stages")
            st.advance(.31)
            local expected = countBank and "bank" or "vendor"
            check(F.GetState() and F.GetState().kind == expected and F.GetState().items[201] == 5,
                "mail collection advances to exact bank/vendor inputs from saved recipes without a profession event")
            check(A.IsInventoryReliable() and not A.IsReliable() and st.mailboxOpen,
                "trusted planning progresses while the mailbox is open but AH execution stays blocked")
            check(not st.calls.quote and not st.calls.buyStack and not st.calls.buyItem,
                "restoring and collecting never invent a new AH purchase gesture")
            local vendor = A.GetVendorCraftTargets(st.entries)
            check(vendor[201] and vendor[201].need == (countBank and 0 or 5)
                and A.Settings().vendorCraftPlans[100].bankFlags[201] == countBank,
                "saved ingredient Count Bank alone controls both vendor shortage and bank reminder")

            st.inventory.NotifyBagStorm(.25); st.mailboxOpen = false; st.emit("MAIL_CLOSED")
            check(F.GetState().kind == "waiting", "mail close hold may defer the stage without deleting its job")
            st.advance(.31)
            check(F.GetState().kind == expected,
                "actual storm-settled callback restores the next step after close without opening a tradeskill")
            targetRows, selectedSource = st.entries, A.Settings().vendorCraftPlans[100]
            st.entries = {}; F.Refresh(); A.GetVendorCraftTargets({})
            check(F.GetState().kind == "waiting" and A.Settings().vendorCraftPlans[100] == selectedSource
                and A.Settings().followup.outputs[100], "a cold target-row publication waits while retaining the full saved job and counterpart")
            st.entries = targetRows; F.Refresh()
            check(F.GetState().kind == expected and A.Settings().vendorCraftPlans[100] == selectedSource,
                "restoring the exact target rows resumes bank/vendor work without repricing or opening professions")

            -- Actual current-character cache aliases all temporarily contain
            -- only identity/learned facts. There is no complete alternate alias
            -- to hide this consumer case; the selected snapshot remains exact.
            local partials = {}
            local selected = A.Settings().followup.outputs[100]
            for _, skill in pairs(env.FluxInvDB.professions[P.GetCharacterKey()].bySkillLine) do
                for _, raw in ipairs(skill.recipes or {}) do
                    if raw.outputItemID == 100 then
                        partials[#partials + 1] = { row = raw, saved = Saved(raw) }
                        raw.quantityMin, raw.quantityMax, raw.outputPerCraft, raw.reagents, raw.craftingData = nil, nil, nil, nil, nil
                    end
                end
            end
            local partialKnown, partialRaw = P.GetRecipeKnowledge(selected)
            check(partialKnown == true and partialRaw.quantityMin == nil and partialRaw.reagents == nil,
                "actual profession owner can return known learned identity while every cached material/yield alias is partial")
            F.Refresh()
            check(F.GetState().kind == expected and A.GetVendorCraftTargets(st.entries)[201],
                "partial known recipe replies retain the selected complete source plan without opening its profession")
            for _, entry in ipairs(partials) do
                wipe(entry.row); for key, value in pairs(entry.saved) do entry.row[key] = value end
            end
            for _, entry in ipairs(partials) do
                if legacy then entry.row.quantityMin, entry.row.reagents = nil, { { count = 1 } }
                else entry.row.craftingData = { version = 1, complete = false } end
            end
            F.Refresh()
            check(F.GetState().kind == "waiting" and not next(A.GetVendorCraftTargets(st.entries))
                and A.Settings().followup.outputs[100], "new unsupported required-reagent facts fail closed without deleting the remembered selected recipe")
            for _, entry in ipairs(partials) do wipe(entry.row); for key, value in pairs(entry.saved) do entry.row[key] = value end end
            F.Refresh(); check(F.GetState().kind == expected, "valid complete facts restore the waiting material stage")
            if not legacy then
                for _, entry in ipairs(partials) do
                    entry.row.craftingData = Saved(entry.row.craftingData)
                    entry.row.craftingData.supportsQualities, entry.row.craftingData.qualityItemIDs = true, { 100, 1100 }
                end
                F.Refresh()
                check(F.GetState().kind == "waiting" and not next(A.GetVendorCraftTargets(st.entries)),
                    "new uncertain quality-output facts require verification instead of authorizing the old material route")
                for _, entry in ipairs(partials) do wipe(entry.row); for key, value in pairs(entry.saved) do entry.row[key] = value end end
                F.Refresh()
            end
            local beforeOutputChange = Saved(A.Settings())
            for _, entry in ipairs(partials) do
                entry.row.outputItemID = 999
                if entry.row.craftingData then
                    entry.row.craftingData = Saved(entry.row.craftingData)
                    entry.row.craftingData.schematic.outputItemID, entry.row.craftingData.qualityItemIDs = 999, { 999 }
                end
            end
            F.Refresh()
            check(not A.Settings().followup and not next(A.GetVendorCraftTargets(st.entries)),
                "a positively changed recipe output invalidates the old selected material job")
            for _, entry in ipairs(partials) do wipe(entry.row); for key, value in pairs(entry.saved) do entry.row[key] = value end end
            st.settings.auctionRestock = beforeOutputChange; F.Resume()

            -- Missing catalogue/provider replies are not a negative learned fact.
            local recipeQuery, allQuery, knowledge, profession = P.ListRecipesForOutput, P.ListAllCachedRecipes, P.GetRecipeKnowledge, P.GetProfessionKnowledge
            P.ListRecipesForOutput, P.ListAllCachedRecipes = function() return {} end, function() return {} end
            P.GetRecipeKnowledge, P.GetProfessionKnowledge = function() return nil end, function() return nil end
            F.Refresh()
            check(F.GetState().kind == expected and A.Settings().followup.outputs[100]
                and A.Settings().vendorCraftPlans[100], "a verified full selected snapshot survives transient empty recipe/provider replies")
            local snapshot, selection = A.Settings().followup.outputs[100], A.Settings().vendorCraftPlans[100]
            local snapshotOwner, selectionOwner = snapshot.recipeOwner, selection.recipeOwner
            snapshot.recipeOwner, selection.recipeOwner, snapshot.recipeVerified, selection.recipeVerified = nil, nil, nil, nil
            F.Refresh()
            check(F.GetState().kind == expected, "complete historical per-character snapshots remain usable without new provenance fields")
            snapshot.recipeOwner, selection.recipeOwner, snapshot.recipeVerified, selection.recipeVerified = snapshotOwner, selectionOwner, true, true
            local oldAllocation = A.Settings().followup.outputs[100].allocation
            A.Settings().followup.outputs[100].allocation = nil
            F.Refresh()
            check(F.GetState().kind == "waiting" and A.Settings().followup.outputs[100],
                "an incomplete unknown snapshot waits and cannot authorize a new material stage")
            A.Settings().followup.outputs[100].allocation = oldAllocation
            local vendorAllocation = A.Settings().vendorCraftPlans[100].allocation
            A.Settings().vendorCraftPlans[100].allocation = nil; F.Refresh()
            check(F.GetState().kind == "waiting" and not next(A.GetVendorCraftTargets(st.entries))
                and A.Settings().vendorCraftPlans[100], "an incomplete unknown saved vendor plan stays pending without authorizing a purchase")
            A.Settings().vendorCraftPlans[100].allocation = vendorAllocation
            P.ListRecipesForOutput, P.ListAllCachedRecipes, P.GetRecipeKnowledge, P.GetProfessionKnowledge = recipeQuery, allQuery, knowledge, profession
            F.Refresh(); check(F.GetState().kind == expected, "restored complete facts resume the retained job")
            local completeSettings = Saved(A.Settings())
            A.SetMaxPrice(100, 0, false); F.Refresh()
            check(not A.Settings().followup and not next(A.GetVendorCraftTargets(st.entries))
                and A.PriceLimit(100) == 0, "an explicit zero output cap still revokes paid saved material work while professions are closed")
            st.settings.auctionRestock = Saved(completeSettings); F.Resume()
            st.settings.restockItems[201].countBank = not countBank; F.Refresh()
            check(not A.Settings().followup and not next(A.GetVendorCraftTargets(st.entries)),
                "changing the ingredient bank flag invalidates the old allocation instead of silently reusing it")
            st.settings.restockItems[201].countBank = countBank
            st.settings.auctionRestock = Saved(completeSettings); F.Resume()
            check(st.settings.restockItems[100].targetQuantity == 10 and st.settings.restockItems[201].targetQuantity == 0,
                "restoring saved recipe work never rewrites either permanent restock target")
            local savedPlan = A.Settings().vendorCraftPlans[100]
            savedPlan.recipeOwner = "Realm-Other"
            local foreign = A.GetVendorCraftTargets(st.entries)
            check(not foreign[201] and not A.Settings().vendorCraftPlans[100],
                "another character's selected recipe cannot authorize this character's vendor inputs")
            A.Settings().followup.outputs[100].recipeOwner = "Realm-Other"; F.Refresh()
            check(not A.Settings().followup, "positive character mismatch invalidates the retained output job")
        end
    end
end
-- The exact craft driver and permanent inventory owner publish progress after
-- each output settles; a spell event cannot fabricate either output or clicks.
local followFixture = Export("auction_restock_followup", "FLUX_FOLLOWUP_FIXTURE_EXPORT")
local progressProfiles = 0
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "ready" }) do
      for _, yield in ipairs({ 1, 3 }) do
        progressProfiles = progressProfiles + 1
        local A, st, env, F = followFixture(legacy, provider)
        st.entries[1].target = yield == 1 and 3 or 6
        st.recipes[1].quantityMin = yield
        st.books[100] = Book(legacy, 100, yield == 1 and 2 or 5, 100)
        A.SetMaxPrice(100, 100, false)
        env.GetTradeSkillNumMade = function() return yield end
        local schematic = env.C_TradeSkillUI.GetRecipeSchematic
        env.C_TradeSkillUI.GetRecipeSchematic = function(...)
            local value = schematic(...); if value then value.quantityMin = yield end; return value
        end
        if st.recipes[1].craftingData then st.recipes[1].craftingData.schematic.quantityMin = yield end
        StormOwner(st, env)
        st.openAH(); st.press(); st.ack(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
        st.bags[200], st.bags[201] = 2, 2; st.emit("BAG_UPDATE_DELAYED")
        check(F.GetState().kind == "craft" and F.GetState().canAct and F.GetState().items[100] == 2 * yield
            and #st.opens == 0 and #st.crafts == 0,
            "closed saved profession is ready for a meaningful opening click with the exact rounded physical output remaining")
        st.professionName, st.professionID = "First Aid", 129; st.emit("TRADE_SKILL_SHOW")
        check(F.GetState().canAct and #st.crafts == 0, "readiness publication never crafts from profession callbacks")
        st.followPress()
        local original = F.GetState().task
        check(#st.crafts == 1 and F.GetState().kind == "crafting" and not F.GetState().canAct
            and F.GetState().items[100] == 2 * yield and original.operations == 2,
            "one physical press starts one batch and publishes its unfulfilled physical output count")
        st.inventory.NotifyBagStorm(.25)
        st.bags[100], st.bags[200], st.bags[201], st.repeatCount = 1 + yield, 1, 1, 1
        st.emit("UNIT_SPELLCAST_STOP", "player")
        check(not F.GetState().canAct and #st.crafts == 1,
            "unsettled output facts cannot advertise or submit another protected craft")
        st.advance(.31)
        check(F.GetState().kind == "crafting" and F.GetState().items[100] == yield and F.GetState().quantity == 1
            and F.GetState().task == original and original.operations == 2 and not F.GetState().canAct,
            "actual bag-storm settlement decrements the pending output badge without rewriting the submitted batch")
        st.inventory.NotifyBagStorm(.25)
        st.bags[100], st.bags[200], st.bags[201], st.repeatCount, st.casting = 1 + 2 * yield, 0, 0, 0, false
        st.emit("UNIT_SPELLCAST_STOP", "player"); st.advance(.31)
        check(not F.GetState() and not A.Settings().followup and #st.crafts == 1 and #st.opens == 0,
            "the last settled craft output retires the pending job automatically without a manual refresh or extra click")
      end
    end
end
print(("Closed-profession restock follow-up: %d checks PASS; %d client/provider/bank +%d craft-progress profiles; native mail/login/profession execution NOT RUN"):format(checks, profiles, progressProfiles))
