-- Real tab/cell/currency/session and learned-recipe planner; no native purchases.
local checks, profiles = 0, 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local chunk = assert(loadfile("tests/auction_restock.lua", "t", export)); if setfenv then setfenv(chunk, export) end
local fixture = chunk()
local function Drain(A, st)
    for _ = 1, 80 do
        if A.state ~= "searching" then return end
        st.result()
    end
    error("pricing did not finish")
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env = fixture(legacy, auctionator, syndicator)
        local function Book(id, quantity, unit)
            return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = quantity, total = quantity * unit } }
                or { { itemID = id, quantity = quantity, unitPrice = unit, numOwnerItems = 0 } } }
        end
        -- No limit defaults on; opening searches without an item selection.
        st.offers = Book(100, 10, 100).offers
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); Drain(A, st)
        check((st.calls.search or st.calls.legacySearch or 0) == 1 and A.offer ~= nil, "unset cap prepares a live offer from one owned native query")
        st.press()
        if not legacy then st.emit("COMMODITY_PRICE_UPDATED", 100, 1000); st.emit("COMMODITY_PURCHASE_SUCCEEDED") else st.legacyReceipt() end
        check(A.Settings().pending[100].units == 10 and (st.calls.confirm or st.calls.buyStack) == 1, "zero limit permits one authorized purchase")
        local owner = legacy and env.AuctionFrame or env.AuctionHouseFrame
        check(A.frame.parent == owner and A.launcher:GetID() == 4 and owner.numTabs == 4, "actual owner tab registration and child content")
        check(A.launcher.point[1] == "TOPLEFT" and A.launcher.point[3] == "TOPRIGHT" and A.launcher:GetHeight() == owner.Tabs[3]:GetHeight(), "restock tab matches neighboring top edge and height")
        check(A.frame.cells[1]._icon and A.frame.cells[1]._countStr and A.frame.cells[1].limit, "real shared restock cell chrome/count/limit")
        local g = A.frame.currencyGroup
        g.gold:SetText("1"); g.silver:SetText("23"); g.copper:SetText("45"); g.gold:SetFocus(); g.gold:Fire("OnEnterPressed")
        check(A.GetMaxPrice(100) == 12345, "three currency fields save one copper ceiling")
        g.silver:SetText("100"); g.silver:SetFocus(); g.silver:Fire("OnEnterPressed")
        check(A.GetMaxPrice(100) == 12345 and g.silver:GetText() == "23", "invalid silver restores saved amount")
        local native = env.CreateFrame("Button", owner:GetName() .. "Tab5", owner)
        local nativeClicks = 0; native:SetScript("OnClick", function() nativeClicks = nativeClicks + 1 end)
        native:SetID(5); owner.Tabs[5], owner.numTabs = native, 5; A.AttachButton(); st.press(native)
        check(nativeClicks == 1 and not A.frame:IsShown(), "native tab handler retained and restock content hidden")
        st.press(A.launcher)
        check(A.frame:IsShown(), "restock tab restores own content")
        env.FluxCombatBandage = { Button = { ItemId = 100, WIcon = { GetTexture = function() return 123456 end } } }
        check(A.CellIcon({ itemID = 100, tierKind = "bandage" }) == 123456, "matching current bandage face supplies exact icon")
        env.FluxItemClass.GetIcon = function(id) return id + 9000 end
        check(A.CellIcon({ itemID = 200, tierKind = "bandage" }) == 9200, "different item never receives misleading tracked-item icon")

        local function Setup(yield, count, materialPrice, owned)
            st.reset()
            st.recipeItems = { [100] = true }
            st.recipes = { { recipeID = 77, outputItemID = 100, name = "Elixir", learned = true,
                legacy = true, quantityMin = yield, quantityMax = yield, reagents = { { itemID = 200, count = count }, { itemID = 201, count = 1 } } } }
            st.bags[200] = owned or 0
            st.settings.vendorItems = { [201] = true }; st.settings.itemPrices = { [201] = 5 }
            st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 5 } }
            local operations = math.ceil(10 / yield)
            st.books = { [100] = Book(100, 10, 100), [200] = Book(200, math.max(1, operations * count - (owned or 0)), materialPrice) }
            st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); A.SetMaxPrice(100, 100); st.press(); Drain(A, st)
        end
        Setup(2, 3, 10, 3)
        check(A.craftPlans[100] and A.craftPlans[100].operations == 5, "known multi-yield recipe rounds operations correctly")
        check(A.craftPlans[100].required[200] == 15 and A.craftPlans[100].required[201] == 5, "full ingredient quantities are calculated")
        check(A.craftPlans[100].cost == 145, "owned ingredients deducted and vendor costs included")
        check(not A.frame.detailsText and not A.frame.detailsScroll and A.RouteText(A.FindRow(100)) == "Craftable",
            "recipe pane is removed; chosen craft route remains compact")
        check(A.offer and A.offer.itemID == 200 and A.offer.quantity == 12, "cheaper materials replace finished purchase with precise missing amount")
        check(A.PurchaseLimit(200) == 10 and A.GetMaxPrice(200) == 0, "derived material limit preserves explicit item preferences")
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack, "price comparison never buys automatically")
        st.press()
        if not legacy then st.emit("COMMODITY_PRICE_UPDATED", 10, 120); st.press(); st.emit("COMMODITY_PURCHASE_SUCCEEDED")
        else st.legacyReceipt() end
        check(A.Settings().pending[200].units == 12 and A.craftPlans[100].spent == 120, "material submission reserves mail and its actual cost")
        local purchases = (st.calls.quote or 0) + (st.calls.confirm or 0) + (st.calls.buyStack or 0)
        st.press(); Drain(A, st)
        check(not A.transaction and (st.calls.quote or 0) + (st.calls.confirm or 0) + (st.calls.buyStack or 0) == purchases
            and A.Settings().pending[200].units == 12, "refreshing covered craft prices never buys the output or duplicates its pending ingredient")
        check(A.CraftStatus():find("Get 5 Item201", 1, true), "missing vendor reagent is visible and not auction-bought")
        st.bags[200], st.bags[201] = 15, 5; A.GetRows(true)
        check(not A.Settings().pending[200] and A.FindRow(200).need == 0, "ingredient delivery reconciles the existing mail reservation")
        st.bags[100], st.bags[200], st.bags[201] = 10, 0, 0; A.GetRows(true)
        check(not A.craftPlans[100] and not A.FindRow(200), "crafting enough output retires temporary material targets")

        Setup(1, 1, 100, 0)
        check(not A.craftPlans[100] and A.offer and A.offer.itemID == 100, "more expensive materials fall back to finished item")
        Setup(1, 1, 95, 0) -- 950 herb + 50 vendor = finished1000.
        check(A.craftPlans[100] and A.offer.itemID == 200, "equal total cost prefers materials")
        Setup(3, 1, 10, 0)
        check(A.craftPlans[100].operations == 4 and A.craftPlans[100].required[200] == 4, "non-divisible shortage uses enough complete crafts")
        A.ResetCraftPlans(); st.recipes[1].learned = false; A.Invalidate(); st.press(); Drain(A, st)
        check(not A.craftPlans[100], "unlearned recipe never selects a material route")
        Setup(1, 1, 95, 0)
        A.craftPlans[100].budget = 1
        st.press()
        check(not st.calls.quote and not st.calls.buyStack and A.status == "craftBudget", "whole purchase cannot exceed remaining finished-item materials budget")

        -- Unknown prices are never interpreted as zero/free materials.
        Setup(1, 1, 95, 0)
        A.ResetCraftPlans(); st.books[200].offers = {}; A.Invalidate(); A.selectedID = 100; st.press(); Drain(A, st)
        check(not A.craftPlans[100], "missing material price disables speculative comparison")

        -- Two outputs share one ingredient pool; stock is allocated once.
        st.reset(); st.recipeItems = { [100] = 7, [101] = true }
        st.entries = { { itemID = 100, name = "Bandage", target = 10 }, { itemID = 101, name = "Potion", target = 4 } }
        st.recipes = {
            { recipeID = 1, outputItemID = 100, name = "Shared bandage recipe", learned = true, legacy = true, quantityMin = 1, reagents = { { itemID = 200, count = 1 } } },
            { recipeID = 2, outputItemID = 101, name = "Shared potion recipe", learned = true, legacy = true, quantityMin = 1, reagents = { { itemID = 200, count = 2 } } },
        }
        st.bags[200] = 10
        st.books = { [100] = Book(100, 10, 100), [101] = Book(101, 4, 100), [200] = Book(200, 8, 10) }
        if legacy then st.books[200].offers[2] = { itemID = 200, quantity = 10, total = 100 } end
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); A.SetMaxPrice(100, 100); A.SetMaxPrice(101, 50)
        st.press(); Drain(A, st)
        check(A.craftPlans[100] and A.craftPlans[100].cost == 0, "owned stock can cover a bandage craft plan without buying")
        check(A.craftPlans[101] and A.craftPlans[101].cost == 80, "second output cannot reuse the first plan's owned materials")
        local ingredient = A.FindRow(200)
        check(ingredient.target == 18 and ingredient.need == 8 and A.offer.quantity == 8, "shared ingredients merge into one exact purchase target")
        st.press()
        if not legacy then st.emit("COMMODITY_PRICE_UPDATED", 10, 80); st.press(); st.emit("COMMODITY_PURCHASE_SUCCEEDED")
        else st.legacyReceipt() end
        check(A.craftPlans[100].spent == 0 and A.craftPlans[101].spent == 80, "material cost is charged to the output that needs the purchased units")

        -- Compare full old-AH stack costs rather than a deceptively low unit price.
        A.ResetCraftPlans(); A.Settings().pending = {}
        st.entries = { { itemID = 100, name = "Bandage", target = 10 } }; st.bags = {}
        A.Settings().allowExcessStacks = true; A.GetRows(true)
        local variants = A.CraftRecipes(st.entries[1])
        local books = {
            [100] = { commodity = false, offers = { { index = 1, quantity = 10, total = 100 } } },
            [200] = { commodity = false, offers = { { index = 1, quantity = 20, total = 120 } } },
        }
        check(A.CompareCraft(A.FindRow(100), variants, books) == nil, "cheap unit price cannot hide a more expensive excess material stack")
        books[200].offers[1].total = 100
        if not legacy then
            check(A.CompareCraft(A.FindRow(100), variants, books) == nil,
                "modern auction recipes ignore a saved whole-stack excess preference")
            books[200].offers[1].quantity = 10
        end
        check(A.CompareCraft(A.FindRow(100), variants, books) ~= nil, "equal fitting-stack cost still prefers materials")

        if not legacy then
            Setup(2, 3, 10, 3); st.press(); st.emit("COMMODITY_PRICE_UPDATED", 10, 120); st.press()
            st.emit("COMMODITY_PURCHASE_FAILED")
            check(not A.Settings().pending[200] and A.craftPlans[100].spent == 0, "unconfirmed failure releases provisional ingredient credit and budget")
            Setup(2, 3, 10, 3); st.press(); st.emit("ADDON_ACTION_BLOCKED", "_FluxUI", "StartCommoditiesPurchase")
            check(A.state == "idle" and A.status == "blocked" and not A.ownsQuote, "native blocked quote is surfaced without retry")
        end

        -- Reagent-quality choice must guarantee the exact requested output ID.
        st.reset(); st.recipeItems = { [100] = true }
        st.recipes = { { recipeID = 88, outputItemID = 100, name = "Elixir", learned = true, quantityMin = 1, reagents = {},
            skillLineID = 171, skillName = "Alchemy" } }
        env.ProfessionsFrame = { IsShown = function() return true end }
        st.inventory.Professions.GetOpenProfessionInfo = function() return { professionID = 171, professionName = "Alchemy" } end
        env.Enum = { CraftingReagentType = { Basic = 0 } }
        env.C_TradeSkillUI = {
            GetRecipeInfo = function() return { learned = true, supportsQualities = true } end,
            GetRecipeQualityItemIDs = function() return { 100, 101 } end,
            GetRecipeSchematic = function() return { quantityMin = 1, hasCraftingOperationInfo = true,
                reagentSlotSchematics = { { required = true, reagentType = 0, quantityRequired = 2, dataSlotIndex = 1,
                    reagents = { { itemID = 200 }, { itemID = 202 } } } } } end,
            GetCraftingOperationInfo = function(_, allocation, guid, concentration)
                check(guid == nil and concentration == false, "quality prediction uses no concentration or hidden inputs")
                return { isQualityCraft = true, guaranteedCraftingQualityID = allocation[1].reagent.itemID == 200 and 1 or 2 }
            end,
            GetRecipeOutputItemData = function(_, allocation, _, quality) return { itemID = quality == 1 and 100 or 101 } end,
        }
        local variants = A.CraftRecipes(st.entries[1])
        check(#variants == 1 and variants[1].required[200] == 2, "wrong output quality is excluded even when its materials differ")
        env.C_TradeSkillUI.GetCraftingOperationInfo = function() return nil end
        check(#A.CraftRecipes(st.entries[1]) == 0, "unknown output guarantee cannot choose materials")
        check(#st.errors == 0, "no API exceptions in tested tab/cell/crafting paths")
    end end
end
print(("Auction restock crafting/tab: %d checks PASS; %d profiles; native quote permissions/rendering/controller NOT RUN"):format(checks, profiles))
