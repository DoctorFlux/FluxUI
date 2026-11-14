-- Actual shared profession store -> SavedVariables round trip -> AH/vendor consumers.
local root = os.getenv("FLUX_AH_ROOT") or "."
local checks, profiles, context = 0, 0, ""
local function check(value, label) checks = checks + 1; assert(value, label .. " [" .. context .. "]") end
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local fixture = assert(loadfile("tests/auction_restock.lua", "t", export))()
local function RoundTrip(value)
    local function literal(v)
        local typ = type(v)
        if typ == "number" or typ == "boolean" then return tostring(v) end
        if typ == "string" then return string.format("%q", v) end
        assert(typ == "table", "saved recipes contain plain data only")
        local out = { "{" }
        for key, item in pairs(v) do out[#out + 1] = "[" .. literal(key) .. "]=" .. literal(item) .. "," end
        out[#out + 1] = "}"; return table.concat(out)
    end
    return assert(load("return " .. literal(value)))()
end
local function boot(client, auctionator, syndicator, saved, character, offline)
    local legacy = client == "Era" or client == "Anniversary"
    local A, st, env = fixture(legacy, auctionator, syndicator)
    local function load(path)
        local chunk = assert(loadfile(root .. "/" .. path, "t", env)); if setfenv then setfenv(chunk, env) end
        chunk("_FluxUI", { Flux = st.flux })
    end
    env.FluxInvDB, env.FluxInv = saved and RoundTrip(saved) or {}, st.inventory
    env.GetRealmName = function() return "Realm" end
    st.flux.PlayerName = { GetCharKey = function() return "Realm-" .. (character or "Alice") end }
    st.ids, st.dataMode = { 11, 12 }, offline and "offline" or "open"
    env.ProfessionsFrame = { IsShown = function() return st.dataMode == "open" or st.dataMode == "partial" end }
    st.recipeData = {
        [11] = { name = "Potion A", output = 100, yield = 2, learned = true, mats = { { 200, 2 }, { 201, 1 } } },
        [12] = { name = "Potion B", output = 101, yield = 1, learned = true, mats = { { 202, 3 } } },
    }
    env.GetProfessions = function() return 1 end
    env.GetProfessionInfo = function() return "Alchemy", 1, 150, 300, 2, 0, 171 end
    env.GetTradeSkillLine = function() return "Alchemy", 150, 300 end
    env.Enum = { CraftingReagentType = { Basic = 0 } }
    if not legacy then
        env.C_TradeSkillUI = {
            GetChildProfessionInfo = function() return { professionID = st.professionID or 171, professionName = "Alchemy" } end,
            GetFilteredRecipeIDs = function() return st.ids end,
            IsNPCCrafting = function() return st.foreign == true end,
            GetRecipeInfo = function(id)
                if st.dataMode == "offline" then return end
                local row = st.recipeData[id]; if not row then return end
                return { name = row.name, learned = row.learned, supportsQualities = row.quality == true }
            end,
            GetRecipeOutputItemData = function(id)
                local row = st.recipeData[id]
                if st.dataMode == "open" and row then return { itemID = row.output, hyperlink = "item:" .. row.output } end
            end,
            GetRecipeSchematic = function(id)
                local row = st.recipeData[id]; if st.dataMode ~= "open" or not row then return end
                local slots = {}
                for i, pair in ipairs(row.mats) do slots[i] = { required = true, reagentType = 0, quantityRequired = pair[2],
                    dataSlotIndex = i, reagents = { { itemID = pair[1] } } } end
                return { outputItemID = row.output, quantityMin = row.yield, quantityMax = row.yield, reagentSlotSchematics = slots,
                    hasCraftingOperationInfo = row.operation == true }
            end,
            GetRecipeQualityItemIDs = function(id)
                local row = st.recipeData[id]; if row and row.quality then return { row.output, row.output + 1000 } end
                return row and { row.output }
            end,
        }
        if client ~= "Forever" then env.C_TradeSkillUI.GetAllRecipeIDs = function() return st.ids end end
    else
        env.C_TradeSkillUI = nil
        env.IsTradeSkillLinked = function() return st.foreign == true end
        env.GetNumTradeSkills = function() return st.dataMode == "offline" and 0 or #st.ids end
        env.GetTradeSkillInfo = function(index) return st.recipeData[st.ids[index]].name, "optimal" end
        env.GetTradeSkillItemLink = function(index) return "item:" .. st.recipeData[st.ids[index]].output end
        env.GetTradeSkillNumMade = function(index) local n = st.recipeData[st.ids[index]].yield; return n, n end
        env.GetTradeSkillNumReagents = function(index) return #st.recipeData[st.ids[index]].mats end
        env.GetTradeSkillReagentInfo = function(index, reagent)
            local pair = st.recipeData[st.ids[index]].mats[reagent]; return "Item" .. pair[1], 1, pair[2], 0
        end
        env.GetTradeSkillReagentItemLink = function(index, reagent) return "item:" .. st.recipeData[st.ids[index]].mats[reagent][1] end
    end
    load("Inventory/Professions.lua")
    st.recipeItems, st.entries = { [100] = true, [101] = true }, { { itemID = 100, name = "Item100", target = 10 } }
    env.FluxItemClass.GetIcon = function(id) return id end
    env.FluxItemClass.GetStackSize = function() return 20 end
    st.settings.restockItems, st.settings.itemPrices = { [100] = { targetQuantity = 10 } }, {}
    st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 5 } }
    return A, st, env, st.inventory.Professions, load
end
local function RealList(st, env, load)
    load("Inventory/Restock/Core/FluxRestockList.lua")
    env.FluxRestockItemRegistry.IsChargeItem = function() return false end
    return env.FluxVendorAuto, env.FluxRestockList
end
local function Vendor(st, env, load, price)
    env.MerchantFrame = { IsShown = function() return true end }
    env.GetMerchantNumItems = function() return 1 end
    env.GetMerchantItemID = function() return 201 end
    env.GetMerchantItemLink = function() return "item:201" end
    env.GetMerchantItemMaxStack = function() return 20 end
    env.GetMerchantItemInfo = function() return "Item201", 201, price, 1, -1, true, true, false end
    env.GetMerchantItemCostInfo = function() return 0 end
    env.IsShiftKeyDown = function() return false end
    st.inventory.NotifyAutomationPulse = function() end
    env.FluxRestock.Inv.NotifyAutomationPulse = function() end
    env.BuyMerchantItem = function(_, quantity)
        st.vendorBought = (st.vendorBought or 0) + quantity
        st.bags[201] = (st.bags[201] or 0) + quantity
        st.money = st.money - quantity * price
    end
    load("Inventory/Restock/Vendor/FluxVendorBuy.lua")
    env.FluxVendorAuto.DoRestockManual()
end
if FLUX_CHARACTER_RECIPE_FIXTURE_EXPORT then return boot end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1; context = client .. "/" .. tostring(auctionator) .. "/" .. tostring(syndicator)
        local A, st, env, P, load = boot(client, auctionator, syndicator)
        check(P.ForceScanOpen() ~= nil and #P.ListAllCachedRecipes() == 2, "own learned recipes are saved once despite ID/name aliases")
        check(P.ListRecipesForOutput(100)[1].quantityMin == 2 and #P.ListRecipesForOutput(100)[1].reagents == 2,
            "shared output query retains conservative yield and every ingredient")
        local saved = RoundTrip(env.FluxInvDB)
        st.ids = { 12 }; P.ForceScanOpen()
        check(#P.ListAllCachedRecipes() == 2 and #P.ListRecipesForOutput(100) == 1, "filtered nonempty scans retain recipes not currently visible")
        local ownRecipeID = (client == "Era" or client == "Anniversary") and 1 or 11
        local priorMatCount = P.GetReagents(ownRecipeID)[1].count
        st.foreign, st.ids = true, { 11 }; st.recipeData[11].mats[1][2] = 99; P.ForceScanOpen()
        check(P.ListRecipesForOutput(100)[1].reagents[1].count == 2, "another player's or NPC profession cannot overwrite this character")
        local own = P.GetReagents(ownRecipeID)
        check(own and own[1].count == priorMatCount, "public recipe queries also ignore another player's or NPC live profession")

        A, st, env, P, load = boot(client, auctionator, syndicator, saved, "Alice", true)
        local cached = P.GetReagents((client == "Era" or client == "Anniversary") and 1 or 11)
        check(#P.ListRecipesForOutput(100) == 1 and cached and #cached == 2,
            "saved recipes reload without opening the profession")
        local variants = A.CraftRecipes({ itemID = 100, name = "Item100" })
        check(#variants == 1 and variants[1].required[200] == 2 and variants[1].required[201] == 1 and variants[1].yield == 2,
            "AH uses real reloaded recipe cache while live profession APIs have no data")
        if client ~= "Era" and client ~= "Anniversary" then
            local ts = env.C_TradeSkillUI
            local original = { info = ts.GetRecipeInfo, schematic = ts.GetRecipeSchematic,
                quality = ts.GetRecipeQualityItemIDs, output = ts.GetRecipeOutputItemData }
            local nativeReads = 0
            ts.GetRecipeInfo = function() nativeReads = nativeReads + 1; return { learned = false } end
            ts.GetRecipeSchematic = function()
                nativeReads = nativeReads + 1
                return { outputItemID = 999, quantityMin = 99, reagentSlotSchematics = {
                    { required = true, reagentType = 0, quantityRequired = 99, dataSlotIndex = 1,
                        reagents = { { itemID = 999 } } },
                } }
            end
            ts.GetRecipeQualityItemIDs = function() nativeReads = nativeReads + 1; return { 999, 1000 } end
            ts.GetRecipeOutputItemData = function() nativeReads = nativeReads + 1; return { itemID = 999 } end
            ts.OpenTradeSkill = function() error("cost comparison opened a profession") end
            ts.CraftRecipe = function() error("cost comparison crafted an item") end
            local function cached(label)
                local before = nativeReads
                local found = A.CraftRecipes({ itemID = 100 })
                check(#found == 1 and found[1].required[200] == 2 and found[1].required[201] == 1
                    and found[1].yield == 2 and found[1].skillLineID == 171 and nativeReads == before, label)
            end
            st.dataMode = "closed"
            cached("closed profession learned=false and unrelated snapshots cannot override the reloaded character recipe")
            local closedBooks = { [100] = { commodity = true, offers = { { unitPrice = 100, quantity = 10 } } },
                [200] = { commodity = true, offers = { { unitPrice = 10, quantity = 10 } } } }
            local closedPlan = A.CompareCraft(A.GetRows(true)[1], A.CraftRecipes({ itemID = 100 }), closedBooks)
            check(closedPlan and closedPlan.cost == 125 and closedPlan.operations == 5,
                "closed profession still chooses cheaper cached materials including vendor costs without opening or crafting")
            st.dataMode, st.professionID = "open", 999
            cached("another open profession cannot provide learned or reagent facts for this saved recipe")
            st.professionID = 171
            ts.IsTradeSkillReady = function() return false end
            cached("not-ready matching profession retains saved complete facts")
            ts.IsTradeSkillReady = nil
            ts.IsDataSourceChanging = function() return true end
            cached("changing profession source retains saved complete facts")
            ts.IsDataSourceChanging = nil
            env.IsTradeSkillLinked = function() return true end
            cached("linked profession cannot override this character's saved recipe")
            env.IsTradeSkillLinked = nil
            ts.IsTradeSkillGuild = function() return true end
            cached("guild profession cannot override this character's saved recipe")
            ts.IsTradeSkillGuild = nil
            st.foreign = true
            cached("NPC profession cannot override this character's saved recipe")
            st.foreign = false
            check(#A.CraftRecipes({ itemID = 100 }) == 0,
                "explicit learned=false from the matching open owned profession rejects the recipe")
            ts.GetRecipeInfo = function() return { learned = true, supportsQualities = false } end
            check(#A.CraftRecipes({ itemID = 100 }) == 0,
                "matching open owned profession's changed output supersedes older cached facts")
            ts.GetRecipeInfo = function() return { learned = nil } end
            cached("incomplete learned state cannot override saved facts with an unrelated schematic")
            ts.GetRecipeInfo, ts.GetRecipeSchematic = original.info, original.schematic
            ts.GetRecipeQualityItemIDs, ts.GetRecipeOutputItemData = original.quality, original.output
            ts.OpenTradeSkill, ts.CraftRecipe = nil, nil
            st.dataMode = "offline"
            local catalogue = P.ListRecipesForOutput
            local deterministic = RoundTrip(catalogue(100)[1])
            deterministic.craftingData.schematic.outputItemID = nil
            deterministic.craftingData.schematic.hasCraftingOperationInfo = true
            P.ListRecipesForOutput = function() return { deterministic } end
            check(#A.CraftRecipes({ itemID = 100 }) == 1,
                "known deterministic output survives closed API even when its schematic omits redundant output ID")
            P.ListRecipesForOutput = catalogue
        end
        local books = { [100] = { commodity = true, offers = { { unitPrice = 100, quantity = 10 } } },
            [200] = { commodity = true, offers = { { unitPrice = 10, quantity = 30 } } } }
        local row = A.GetRows(true)[1]
        A.SetMaxPrice(100, 12)
        check(not A.CompareCraft(row, variants, books), "finished-item cap rejects total ingredient cost including vendor reagents")
        A.SetMaxPrice(100, 20)
        local plan = A.CompareCraft(row, variants, books)
        check(plan and plan.cost == 125 and plan.vendorCost == 25, "allowed crafting route includes all vendor costs")
        A.craftPlans[100] = plan; A.GetRows(true)
        local vendor = A.GetVendorCraftTargets(st.entries)
        check(vendor[201] and vendor[201].target == 5 and vendor[201].maxUnitPrice == 5, "chosen craft creates precise temporary vendor ingredient target and price ceiling")
        local restockSaved = RoundTrip(st.settings)
        local FV, List = RealList(st, env, load)
        local list = FV.GetRestockTargetItems({ forOptionsPanel = true })
        local vial; for _, entry in ipairs(list) do if entry.itemID == 201 then vial = entry end end
        check(vial and vial.restockSource == "craftMaterial" and List.EntryNeed(vial) == 5,
            "temporary crafting ingredient flows through the real vendor restock list")
        check(st.settings.restockItems[201] == nil and st.settings.restockItems[100].targetQuantity == 10,
            "temporary vendor plan never modifies permanent manual restock targets")
        st.mail[201] = 2
        list = FV.GetRestockTargetItems({ forOptionsPanel = true }); for _, entry in ipairs(list) do if entry.itemID == 201 then vial = entry end end
        check(List.EntryNeed(vial) == 3, "incoming ingredient mail prevents buying the same two units at a vendor")
        st.bags[201], st.mail[201] = 5, 0
        list = FV.GetRestockTargetItems({ forOptionsPanel = true }); for _, entry in ipairs(list) do if entry.itemID == 201 then vial = entry end end
        check(List.EntryNeed(vial) == 0, "collected vendor ingredients satisfy temporary target")
        st.bags[100] = 10
        FV.GetRestockTargetItems({ forOptionsPanel = true })
        check(next(A.Settings().vendorCraftPlans) == nil, "crafting the target removes temporary vendor restock plan")

        -- A second boot has only persisted character facts, no live craft plans.
        A, st, env, P, load = boot(client, auctionator, syndicator, saved, "Alice", true)
        for key, value in pairs(RoundTrip(restockSaved)) do st.settings[key] = value end
        FV, List = RealList(st, env, load)
        list = FV.GetRestockTargetItems({ forOptionsPanel = true })
        vial = nil; for _, entry in ipairs(list) do if entry.itemID == 201 then vial = entry end end
        check(vial and List.EntryNeed(vial) == 5 and not next(A.craftPlans),
            "temporary vendor targets survive reload and AH close using the per-character plan")
        Vendor(st, env, load, 5)
        check(st.vendorBought == 5 and st.bags[201] == 5, "actual vendor buyer purchases exactly the five missing recipe reagents")
        check(st.settings.restockItems[201] == nil, "vendor purchase leaves no permanent ingredient target")

        A, st, env, P, load = boot(client, auctionator, syndicator, saved, "Alice", true)
        for key, value in pairs(RoundTrip(restockSaved)) do st.settings[key] = value end
        st.settings.restockItems[201] = { targetQuantity = 2 }
        FV, List = RealList(st, env, load)
        Vendor(st, env, load, 6)
        check(st.vendorBought == 2 and st.money == 99988,
            "vendor price above crafting ceiling skips craft units while honoring two permanent manual units")
        check(st.settings.restockItems[201].targetQuantity == 2, "temporary and permanent vendor targets retain separate ownership")
        A.Settings().preferCrafting = false
        check(not next(A.GetVendorCraftTargets(FV.GetRestockTargetItems({ forOptionsPanel = true }))) and not A.Settings().vendorCraftPlans,
            "turning crafting off removes the temporary vendor plan")

        if client ~= "Era" and client ~= "Anniversary" then
            A, st, env, P, load = boot(client, auctionator, syndicator, saved, "Alice")
            st.ids, st.dataMode = { 11 }, "partial"
            P.ForceScanOpen()
            check(#P.GetReagents(11) == 2 and P.GetRecipe(11).quantityMin == 2,
                "partial live info cannot replace saved materials or yield in the public API")
            st.dataMode, st.recipeData[11].learned = "open", false
            P.ForceScanOpen()
            check(#P.ListRecipesForOutput(100) == 0 and #P.ListRecipesForOutput(101) == 1,
                "explicit unlearn removes the recipe through both skill-name and numeric aliases")
            st.recipeData[11].learned = nil
            P.ForceScanOpen()
            check(#P.ListRecipesForOutput(100) == 0, "unknown learned state is never stored as a learned recipe")
            st.recipeData[11].learned, st.recipeData[11].quality = true, true
            P.ForceScanOpen()
            check(#P.ListRecipesForOutput(1100) == 1, "quality output alternatives are saved for shared future queries")
            st.dataMode = "offline"
            A, st, env, P, load = boot(client, auctionator, syndicator, RoundTrip(env.FluxInvDB), "Alice", true)
            check(#A.CraftRecipes({ itemID = 100 }) == 0, "saved quality recipe cannot guess a guaranteed craft output without live operation proof")
            A, st, env, P, load = boot(client, auctionator, syndicator, saved, "Alice")
            st.recipeData[11].mats[1][1] = nil; P.ForceScanOpen(); st.dataMode = "offline"
            check(#A.CraftRecipes({ itemID = 100 }) == 0,
                "an unsupported required reagent invalidates the older saved schematic instead of buying an incomplete recipe")
            A, st, env, P, load = boot(client, auctionator, syndicator)
            st.recipeData[11].operation = true; P.ForceScanOpen(); st.dataMode = "offline"
            check(#A.CraftRecipes({ itemID = 100 }) == 1,
                "a proven fixed non-quality output remains usable even when live bonus-operation stats are unavailable")
        end

        A, st, env, P, load = boot(client, auctionator, syndicator)
        st.recipeData[12].mats[2] = { 201, 1 }; P.ForceScanOpen()
        st.entries[2], st.settings.restockItems[101] = { itemID = 101, name = "Item101", target = 4 }, { targetQuantity = 4 }
        local variantsA, variantsB = A.CraftRecipes(st.entries[1]), A.CraftRecipes(st.entries[2])
        local sharedBooks = { [100] = books[100], [200] = books[200],
            [101] = { commodity = true, offers = { { unitPrice = 100, quantity = 4 } } },
            [202] = { commodity = true, offers = { { unitPrice = 1, quantity = 12 } } } }
        A.SetMaxPrice(100, 20); A.SetMaxPrice(101, 0)
        A.GetRows(true)
        A.craftPlans[100] = A.CompareCraft(A.FindRow(100), variantsA, sharedBooks)
        A.craftPlans[101] = A.CompareCraft(A.FindRow(101), variantsB, sharedBooks)
        A.GetRows(true)
        check(A.GetVendorCraftTargets(st.entries)[201].target == 9, "shared vendor ingredient sums five plus four units across both selected recipes")
        st.bags[201], st.mail[201] = 2, 1
        FV, List = RealList(st, env, load)
        list = FV.GetRestockTargetItems({ forOptionsPanel = true })
        for _, entry in ipairs(list) do if entry.itemID == 201 then vial = entry end end
        check(List.EntryNeed(vial) == 6, "shared vendor requirements subtract the same bags/mail stock only once")
        A.SetMaxPrice(100, 1)
        check(not next(A.GetVendorCraftTargets(st.entries)), "changing the finished-item price cap invalidates temporary vendor plans before any purchase")

        A, st, env, P, load = boot(client, auctionator, syndicator, saved, "Alice", true)
        RealList(st, env, load)
        local legacy = client == "Era" or client == "Anniversary"
        local function book(id, unit)
            return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = 10, total = 10 * unit } }
                or { { itemID = id, quantity = 10, unitPrice = unit, numOwnerItems = 0 } } }
        end
        st.books = { [100] = book(100, 100), [200] = book(200, 10) }
        A.SetMaxPrice(100, 20)
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        check(A.offer and A.offer.itemID == 200 and A.Settings().vendorCraftPlans[100],
            "full AH queue uses reloaded character recipe, buys material route and publishes temporary vendor plan (" .. A.state .. "/" .. A.status .. "/" .. tostring(A.offer and A.offer.itemID) .. ")")
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack,
            "cached recipe planning never spends without the player's buy press")
        A.SetMaxPrice(100, 12); st.drain()
        check(not A.offer and not A.craftPlans[100] and not next(A.Settings().vendorCraftPlans or {}),
            "full queue rejects crafting and temporary vendor buys above the finished item's unit limit")
        A.SetMaxPrice(100, 0); st.drain()
        check(A.offer and A.offer.itemID == 200 and A.craftPlans[100], "zero finished-item cap also means unlimited for the crafting route")
        st.emit("AUCTION_HOUSE_CLOSED")
        check(A.Settings().vendorCraftPlans[100] and not A.active,
            "closing the actual AH tab keeps the temporary plan available for the vendor trip")

        local otherA, other, otherEnv, otherP = boot(client, auctionator, syndicator, saved, "Bob", true)
        check(#otherP.ListAllCachedRecipes() == 0 and #otherP.ListRecipesForOutput(100) == 0, "another character does not inherit Alice's learned recipes")
        check(#otherP.ListRecipesForOutput(100, "Realm-Alice") == 1 and #otherP.ListAllCachedRecipes() == 0,
            "future consumers can inspect a named character without contaminating current-character knowledge")
    end end
end
print(("Character recipe persistence/vendor crafting: %d checks PASS; %d profiles; native persistence/buying NOT RUN"):format(checks, profiles))
