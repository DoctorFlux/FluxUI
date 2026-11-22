-- Execute the exact follow-up driver: hardware batches, live identities and no
-- profession-event/timer continuation. No native permissions are certified.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local fixtureChunk = assert(loadfile(root .. "/tests/auction_restock.lua", "t", export))
if setfenv then setfenv(fixtureChunk, export) end
local fixture = fixtureChunk()
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "MoP" or client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env = fixture(client == "Era" or client == "Anniversary", auctionator, syndicator)
        local actions = {}
        local function native(kind, ...)
            check(st.hardware == true and (st.pcallDepth or 0) == 0, kind .. " retains direct physical input")
            actions[#actions + 1] = { kind = kind, args = { ... } }
            st.lastCraftAction = actions[#actions]
        end
        st.bags = { [200] = 10, [201] = 3 }
        st.profName, st.profInfo = "Alchemy", { professionID = 171 }
        st.output, st.yield, st.learned = 100, 2, true
        local task = { parentID = 100, recipeID = 77, recipeName = "Bandage", skillName = "First Aid", skillLineID = 129,
            legacy = legacy, yield = 2, operations = 7, required = { [200] = 2, [201] = 1 },
            allocation = { { reagent = { itemID = 200 }, dataSlotIndex = 1, quantity = 2 },
                { reagent = { itemID = 201 }, dataSlotIndex = 2, quantity = 1 } } }
        env.Enum = { CraftingReagentType = { Basic = 0 } }
        st.flux.Inventory.Professions.GetOpenProfessionInfo = function() return st.profInfo end
        env.UnitCastingInfo = function(unit) check(unit == "player", "craft busy reads player only"); return st.casting end
        env.UnitChannelInfo = function() return st.channeling end
        env.IsTradeSkillLinked = function() return st.foreign == true end
        env.GetTradeskillRepeatCount = function() return st.repeatCount or 0 end
        env.C_TradeSkillUI = {
            IsDataSourceChanging = function() return st.changing == true end,
            IsTradeSkillReady = function() return st.ready ~= false end,
            IsTradeSkillGuild = function() return st.guild == true end,
            IsNPCCrafting = function() return st.npc == true end,
            GetRecipeInfo = function(id)
                check(id == 77, "exact recipe ID queried")
                if st.noInfo then return nil end
                return { name = st.recipeName or "Bandage", learned = st.learned, supportsQualities = st.quality,
                    disabled = st.disabled }
            end,
            GetRecipeSchematic = function(id, recraft)
                check(id == 77 and recraft == false, "normal exact recipe schematic queried")
                return { quantityMin = st.yield, reagentSlotSchematics = {
                    { dataSlotIndex = 1, reagentType = 0, required = true, quantityRequired = 2,
                        reagents = { { itemID = 200 }, { itemID = 202 } } },
                    { dataSlotIndex = 2, reagentType = 0, required = true, quantityRequired = 1,
                        reagents = { { itemID = 201 } } },
                    { dataSlotIndex = 3, reagentType = 1, required = false, quantityRequired = 0,
                        reagents = { { itemID = 203 } } },
                } }
            end,
            GetRecipeQualityItemIDs = function() return st.qualityIDs end,
            GetCraftingOperationInfo = function(id, allocation, guid, concentration)
                check(id == 77 and guid == nil and concentration == false, "quality guarantee excludes concentration and hidden inputs")
                return st.operation
            end,
            GetRecipeOutputItemData = function(id, allocation, guid, quality)
                check(id == 77 and allocation[1].reagent.itemID == 200 and guid == nil,
                    "output identity uses selected reagent allocation")
                return { itemID = quality and (quality == 1 and 100 or 101) or st.output }
            end,
            OpenTradeSkill = function(id)
                native("open", id); check(id == 129, "opens exact cached skill line")
                if st.syncOpen then st.profInfo = { professionID = 129 } end
                if st.openForeign then st.foreign = true end
                return st.opened ~= false
            end,
            CraftRecipe = function(id, count, allocation, level, order, concentration)
                native("craft", id, count, allocation)
                check(id == 77 and count == task.operations and allocation ~= task.allocation
                    and allocation[1].quantity == 2 and level == nil and order == nil and concentration == false,
                    "one native batch uses validated copied allocation and current submitted operations")
                if st.onCraft then st.onCraft(count) end
            end,
        }
        st.legacyRows = {
            { name = "Bandage", kind = "header", id = 100 },
            { name = "Bandage", kind = "optimal", id = 101 },
            { name = "Bandage", kind = "optimal", id = 100, reagents = { { id = 200, count = 3 }, { id = 201, count = 1 } } },
            { name = "Bandage", kind = "optimal", id = 100, reagents = { { id = 200, count = 2 }, { id = 201, count = 1 } } },
        }
        env.GetTradeSkillLine = function() return st.profName end
        env.GetNumTradeSkills = function() return #st.legacyRows end
        env.GetTradeSkillInfo = function(i) local r = st.legacyRows[i]; return r.name, r.kind end
        env.GetTradeSkillItemLink = function(i) return "item:" .. (st.legacyRows[i].id or 0) end
        env.GetTradeSkillNumMade = function() return st.yield, st.yield end
        env.GetTradeSkillNumReagents = function(i) return #(st.legacyRows[i].reagents or {}) end
        env.GetTradeSkillReagentInfo = function(i, slot) local r = st.legacyRows[i].reagents[slot]; return "Reagent", nil, r.count end
        env.GetTradeSkillReagentItemLink = function(i, slot) return "item:" .. st.legacyRows[i].reagents[slot].id end
        env.SelectTradeSkill = function(i) st.selectedSkill = i end
        env.CastSpellByName = function(name)
            native("cast", name); check(name == "First Aid", "legacy opens localized saved profession name")
            if st.syncOpen then st.profName = name end
        end
        env.DoTradeSkill = function(index, count)
            native("legacy", index, count)
            check(index == st.selectedSkill and count == task.operations, "legacy batch receives current live row and submitted operations")
            if st.onCraft then st.onCraft(count) end
        end
        local frames, timers = st.frames, #st.timers
        local chunk = assert(loadfile(root .. "/Inventory/Restock/Auction/FluxAuctionRestockFollowupCraft.lua", "t", env))
        if setfenv then setfenv(chunk, env) end
        chunk("_FluxUI", { Flux = st.flux })
        local F = A.Followup
        check(st.frames == frames and #st.timers == timers, "driver creates no frame or background timer")
        check(F.CanCraft(task) and #actions == 0 and task.operations == 7,
            "pure readiness allows opening the saved profession without actions or task mutation")
        local function click()
            st.hardware = true
            local state, count, pending = F.CraftClick(task)
            st.hardware = false
            return state, count, pending
        end
        local function ownProfession()
            st.profName, st.profInfo = "First Aid", { professionID = 129 }
        end
        local state, count = click()
        check(state == "opening" and count == nil and #actions == 1, "asynchronous profession opening never continues crafting from a callback")
        ownProfession()
        check(F.CanCraft(task) and #actions == 1, "pure readiness verifies an open owned recipe without crafting")
        st.onCraft = function(n) check(n == 3 and task.operations == 3, "clamped operations are visible before synchronous native callbacks") end
        state, count = click()
        check(state == "crafting" and count == 3 and #actions == 2, "next physical press crafts one batch clamped by every carried reagent")
        if legacy then check(actions[2].args[1] == 4, "legacy saved index77 is replaced with verified current row4") end
        local oldActions = #actions
        st.casting = "Bandage"
        check(not F.CanCraft(task) and #actions == oldActions, "an active cast never advertises another craft click")
        check(F.CraftIsBusy(task) and click() == "crafting" and #actions == oldActions, "busy readback never submits another batch")
        st.casting, st.channeling = nil, "Other spell"
        check(F.CraftIsBusy(task), "channels also prevent overlapping crafting")
        st.channeling = nil
        if legacy then
            st.repeatCount = 2
            check(F.CraftIsBusy(task), "legacy batch repeat counter covers between casts")
            st.repeatCount = 0
        end
        st.syncOpen, task.operations = true, 8
        st.profName, st.profInfo = "Alchemy", { professionID = 171 }
        state, count = click()
        check(state == "crafting" and count == 3 and #actions == oldActions + 2,
            "synchronous profession opening may craft only within that same physical press")
        st.onCraft = nil
        st.entries = { { itemID = 200, name = "Cloth", target = 10 } }
        st.bags[200], task.operations = 10, 3
        A.GetRows(true)
        check(A.GetCraftBagAvailable(200) == 0 and click() == "unavailable",
            "exact crafting cannot consume the material's separate direct restock target")
        st.bags[200] = 12; A.GetRows(true)
        state, count = click()
        check(A.GetCraftBagAvailable(200) == 2 and state == "crafting" and count == 1,
            "only two physical copies above the direct target can fund one craft")
        st.bags[200], st.mail[200], task.operations = 10, 2, 3
        A.GetRows(true)
        check(A.GetCraftBagAvailable(200) == 0 and click() == "unavailable",
            "moving purchased material out of bags cannot consume direct stock or craft from pending mail")
        local originalCount = env.FluxRestock.Inv.GetLiveCount
        st.charged, st.charges, st.uses = 200, 5, 7
        env.FluxRestock.Inv.GetLiveCount = function(id, opts)
            if id == 200 and opts.charges == true then return st.uses end
            return originalCount(id, opts)
        end
        st.entries[1].target, st.bags[200], st.mail[200] = 9, 2, nil
        A.GetRows(true)
        check(A.GetCraftBagAvailable(200) == 0 and click() == "unavailable",
            "partial charged copies remain protected for their own nine-use target")
        st.bags[200], st.uses = 4, 17; A.GetRows(true)
        check(A.GetCraftBagAvailable(200) == 1 and click() == "unavailable",
            "lost charge capacity prevents spending a protected whole copy on a two-item recipe")
        st.bags[200], st.uses = 5, 22; A.GetRows(true)
        state, count = click()
        check(A.GetCraftBagAvailable(200) == 2 and state == "crafting" and count == 1,
            "charged direct stock permits only genuinely surplus physical recipe copies")
        env.FluxRestock.Inv.GetLiveCount, st.charged = originalCount, nil
        st.entries, st.bags[200], task.operations = { { itemID = 100, target = 10 } }, 10, 3
        A.GetRows(true)
        for _, flag in ipairs({ "foreign", "guild", "npc", "combat" }) do
            st[flag] = true
            if flag == "combat" then env.InCombatLockdown = function() return st.combat == true end end
            local before = #actions
            check(click() == "unavailable" and #actions == before, flag .. " context fails closed")
            st[flag] = nil
        end
        st.reliable = false
        check(click() == "unavailable", "unreliable inventory cannot craft")
        st.reliable, st.bags[201] = true, 0
        check(click() == "unavailable", "bank or mailbox facts never replace missing carried reagents")
        st.bags[201] = 3
        local before = #actions
        st.yield = 3
        check(click() == "unavailable" and #actions == before, "changed live recipe yield cannot craft")
        st.yield = 2
        task.required[201] = 2
        check(click() == "unavailable" and #actions == before, "changed reagent counts cannot craft")
        task.required[201] = 1
        if legacy then
            st.legacyRows[2], st.legacyRows[4] = st.legacyRows[4], st.legacyRows[2]
            state = click()
            check(state == "crafting" and st.lastCraftAction.args[1] == 2, "legacy index is re-resolved after list reorder")
            st.legacyRows[2].id = 102
            check(click() == "unavailable", "same-name recipe with another output is rejected")
            st.legacyRows[2].id = 100
            env.TradeSkillFrame = { IsShown = function() return false end }
            before = #actions
            check(click() == "opening" and #actions == before + 1 and st.lastCraftAction.kind == "cast",
                "a hidden legacy window opens its saved skill instead of using its cached row")
        else
            st.output = 101
            check(click() == "unavailable", "another live output SKU is rejected")
            st.output, st.learned = 100, false
            check(click() == "unavailable", "unlearned recipe is rejected")
            st.learned, st.disabled = true, true
            check(click() == "unavailable", "disabled recipe is rejected")
            st.disabled, st.recipeName = nil, "Another Recipe"
            check(click() == "unavailable", "another live recipe identity is rejected")
            st.recipeName = nil
            local allocation = task.allocation
            task.allocation = { false }
            check(click() == "unavailable", "malformed saved allocation fails closed")
            task.allocation = allocation
            st.qualityIDs = { 100, 101 }
            check(click() == "unavailable", "quality output without a live operation guarantee is rejected")
            st.operation = { isQualityCraft = true, guaranteedCraftingQualityID = 2 }
            check(click() == "unavailable", "allocation yielding another quality SKU is rejected")
            st.operation.guaranteedCraftingQualityID = 1
            check(click() == "crafting", "correct live guaranteed output quality can craft")
            task.allocation[3] = { reagent = { itemID = 203 }, dataSlotIndex = 3, quantity = 1 }
            check(click() == "unavailable", "optional allocation outside the planned basic ingredients is rejected")
            task.allocation[3] = nil
            st.profInfo = { professionID = 999, parentProfessionID = 129 }
            check(click() == "crafting", "child profession context matches its cached parent skill line")
            st.profInfo, st.syncOpen, st.openForeign = { professionID = 171 }, true, true
            before = #actions
            check(click() == "unavailable" and #actions == before + 1, "foreign view appearing during open cannot reach craft dispatch")

            st.foreign, st.syncOpen, st.openForeign, st.qualityIDs = nil, nil, nil, nil
            local frameShown, recipesShown, baseID = false, false, 129
            local professionFrame = {
                recipesTabID = 1,
                IsShown = function() return frameShown end,
                IsVisible = function() return frameShown end,
                CraftingPage = {
                    IsShown = function() return recipesShown end,
                    IsVisible = function() return frameShown and recipesShown end,
                },
            }
            env.ProfessionsFrame = professionFrame
            env.C_TradeSkillUI.GetBaseProfessionInfo = function() return { professionID = baseID } end
            env.OpenProfessionUIToSkillLine = function(id)
                native("show-profession", id)
                check(id == 129, "native presentation takes the owned profession skill line")
            end
            ownProfession()
            for _, showFrameOnly in ipairs({ false, true }) do
                frameShown, recipesShown = showFrameOnly, not showFrameOnly
                before = #actions
                check(F.CanCraft(task) and #actions == before, "cached recipe readiness can advertise reopening without showing a panel")
                check(click() == "opening" and #actions == before + 1 and actions[before + 1].kind == "show-profession",
                    "a hidden frame or recipes page reopens the already active base profession without crafting")
                frameShown, recipesShown = true, true
                check(F.CanCraft(task) and #actions == before + 1, "the restored crafting page becomes ready without submitting a craft")
                check(click() == "crafting" and #actions == before + 2,
                    "a later physical press crafts only after the matching page is visible")
            end

            if client == "Forever" then
                local bookShown = true
                frameShown, recipesShown = true, false
                professionFrame.recipesTabID = nil
                professionFrame.BookPage = { IsShown = function() return bookShown end }
                local matchingTab = { skillLine = 129, IsShown = function() return true end }
                function matchingTab:OnClick()
                    check(self == matchingTab and bookShown and not recipesShown, "native tab receives its current Book Page context")
                    native("native-recipes-tab", self.skillLine)
                    bookShown, recipesShown = false, true
                end
                professionFrame.rightProfessionTabs = {
                    { skillLine = 171, IsShown = function() return true end, OnClick = function() error("foreign tab") end },
                    { skillLine = 129, IsShown = function() return false end, OnClick = function() error("hidden tab") end },
                    matchingTab,
                }
                before = #actions
                check(F.CanCraft(task) and #actions == before, "visible Forever Book Page advertises its matching native action")
                check(click() == "crafting" and #actions == before + 2 and actions[before + 1].kind == "native-recipes-tab"
                    and actions[before + 2].kind == "craft" and recipesShown and not bookShown,
                    "the matching native tab opens Recipes without reopening the accepted engine skill")
                professionFrame.recipesTabID, professionFrame.BookPage, professionFrame.rightProfessionTabs = 1, nil, nil
            end

            env.ProfessionsFrame = nil
            env.ProfessionsFrame_LoadUI = function()
                native("load-professions")
                env.ProfessionsFrame = professionFrame
                return true
            end
            frameShown, recipesShown, baseID, st.profInfo = false, false, 0, nil
            before = #actions
            check(F.CanCraft(task) and #actions == before, "cold readiness never preloads the profession UI")
            check(click() == "opening" and #actions == before + 2 and actions[before + 1].kind == "load-professions"
                and actions[before + 2].kind == "open", "the physical press preloads a cold UI before opening the native skill line")

            local recipeProfession
            env.C_TradeSkillUI.GetProfessionInfoByRecipeID = function(id)
                check(id == 77, "profession recovery looks up only the exact saved recipe")
                return recipeProfession
            end
            for _, oldSkillLine in ipairs({ 0, 444, 171 }) do
                task.skillLineID = oldSkillLine
                recipeProfession = oldSkillLine == 0 and { professionID = 129, parentProfessionID = 0 }
                    or { professionID = 444, parentProfessionID = 129 }
                if oldSkillLine == 171 then
                    frameShown, recipesShown, baseID, st.profInfo = true, true, 171, { professionID = 171 }
                end
                before = #actions
                check(F.CanCraft(task) and #actions == before, "the exact recipe can recover an older skill-line identity without opening")
                check(click() == "opening" and #actions == before + 1 and actions[before + 1].kind == "open"
                    and actions[before + 1].args[1] == 129, "an older saved skill line opens the recovered base profession")
                frameShown, recipesShown, baseID = true, true, 129
                st.profInfo = { professionID = 444, parentProfessionID = 129 }
                check(click() == "crafting" and #actions == before + 2,
                    "the recovered base also verifies the opened recipe for a subsequent craft")
                frameShown, recipesShown, baseID, st.profInfo = false, false, 0, nil
            end
            task.skillLineID = 129

            before = #actions
            st.ready, baseID = false, 129
            check(click() == "opening" and #actions == before + 1 and st.lastCraftAction.kind == "open",
                "the opener requests a new session when a retained base has no ready crafting data")
            st.ready, baseID = nil, 0

            before = #actions
            st.changing = true
            check(not F.CanCraft(task) and click() == "unavailable" and #actions == before,
                "a changing native source does not start a competing open or craft")
            st.changing = false
            check(F.CanCraft(task) and #actions == before, "a settled source restores readiness without issuing native actions")
            check(click() == "opening" and #actions == before + 1 and actions[before + 1].kind == "open",
                "a new press opens the correct skill after the prior source settles")

            before = #actions
            st.opened = false
            check(click() == "unavailable" and #actions == before + 1 and actions[before + 1].kind == "open",
                "a direct native refusal leaves the task for a later attempt without crafting")
            st.opened = nil

            before = #actions
            st.mailboxOpen, st.bagStorm = true, false
            check(F.CanCraft(task) and click() == "opening" and #actions == before + 1,
                "settled carried inventory lets the player open the profession while mail remains open")
            before = #actions
            st.bagStorm = true
            check(not F.CanCraft(task) and click() == "unavailable" and #actions == before,
                "inventory storm prevents the otherwise eligible profession open")
            ownProfession()
            frameShown, recipesShown, baseID = true, true, 129
            check(not F.CanCraft(task) and click() == "unavailable" and #actions == before,
                "inventory storm also prevents a craft in the visible owned profession")
            if client == "Forever" then
                st.flux.Client = { isForever = true }
                st.bagStorm, st.noInfo = false, true
                task.operations, st.bags[200], st.bags[201] = 7, 10, 3
                local selected, quantity, maximum, writes = 88, 1, 8, 0
                local single, delayed, disabled
                local page = professionFrame.CraftingPage
                page.SchematicForm = { GetRecipeInfo = function()
                    return { recipeID = selected, canCreateMultiple = not single }
                end }
                page.GetCraftableCount = function() return maximum end
                page.CreateButton = { IsEnabled = function() return true end }
                page.CreateMultipleInputBox = {
                    IsEnabled = function() return not disabled end,
                    GetValue = function() return quantity end,
                    SetValue = function(_, value)
                        check(selected == 77, "only the exact recipe can receive the native batch")
                        quantity, writes = value, writes + 1
                    end,
                }
                env.C_TradeSkillUI.OpenRecipe = function(id)
                    native("native-recipe", id)
                    check(id == 77, "native handoff selects exactly the planned recipe")
                    if not delayed then selected = id end
                end
                before = #actions
                check(F.CanCraft(task) and #actions == before,
                    "a verified plan can prepare a native recipe even before the selected recipe data loads")
                state, count = click()
                check(state == "native_click" and count == 3 and #actions == before + 1
                    and st.lastCraftAction.kind == "native-recipe" and selected == 77 and quantity == 3 and writes == 1,
                    "the Forever HUD fills the entire carried batch without invoking blocked CraftRecipe")
                check(click() == "native_click" and #actions == before + 1 and writes == 1,
                    "an already prepared recipe avoids a redundant selection and quantity write")
                quantity, maximum = 8, 2
                state, count = click()
                check(state == "native_click" and count == 2 and quantity == 2,
                    "the native cap can lower the planned batch and replace a previously larger input")
                single, maximum = true, 8
                state, count = click()
                check(state == "native_click" and count == 1 and quantity == 1,
                    "an exact native recipe that disallows multiple crafts prepares one operation")
                disabled = true
                local canSingle, singleCount = F.CanCraft(task)
                local currentWrites = writes
                state, count = click()
                check(canSingle and singleCount == 1 and state == "native_click" and count == 1 and writes == currentWrites,
                    "the single-craft hint matches Blizzard's ready Create when its quantity field is disabled")
                single, disabled = false, false
                selected = 88
                F.RevealCompanionNativeCraft = function(id, operations)
                    check(operations == 3, "the companion receives craft operations instead of output units")
                    native("companion-reveal", id)
                    selected = id
                    return true
                end
                check(click() == "native_click" and #actions == before + 2 and st.lastCraftAction.kind == "companion-reveal"
                    and selected == 77 and quantity == 3, "the companion can reveal and prepare the owned batch")
                selected, quantity = 88, 6
                F.RevealCompanionNativeCraft = function() return false, "busy" end
                check(click() == "unavailable" and #actions == before + 2 and selected == 88 and quantity == 6,
                    "an armed companion preserves its separate recipe and amount")
                F.RevealCompanionNativeCraft = nil
                delayed = true
                local pending
                state, count, pending = click()
                check(state == "native_click" and count == 3 and pending == page and selected == 88
                    and quantity == 6 and #actions == before + 3,
                    "a delayed native selection leaves the unrelated recipe field untouched")
                env.C_TradeSkillUI.GetRecipeInfo = function()
                    return { recipeID = 77, name = "Bandage", learned = true }
                end
                page.SelectRecipe = function(_, info, keepSearch)
                    check(st.hardware and info.recipeID == 77 and keepSearch == true,
                        "the exact learned recipe can open while the native search hides its row")
                    selected = info.recipeID
                end
                state, count = click()
                check(state == "native_click" and count == 3 and selected == 77 and quantity == 3 and #actions == before + 3,
                    "direct native form selection prepares the batch without calling Craft or clearing filters")
                env.C_TradeSkillUI.GetRemainingRecasts = function() return 2 end
                check(not F.CanCraft(task) and click() == "crafting" and #actions == before + 3,
                    "the native recast counter blocks another preparation between crafts")
                env.C_TradeSkillUI.GetRemainingRecasts = function() return 0 end
                st.noInfo = nil
                env.Enum.SpellBookSpellBank = { Player = 0 }
                env.GetProfessions = function() return nil, nil, 4 end
                env.GetProfessionInfo = function(index)
                    check(index == 4, "the owned profession roster may have empty earlier slots")
                    return "First Aid", nil, nil, nil, 2, 15, 129
                end
                env.C_SpellBook = { GetSpellBookItemInfo = function(slot, bank)
                    check(slot == 16 and bank == 0, "professional opening reads the native player spellbook slot")
                    return { spellID = 45542 }
                end }
                env.C_TradeSkillUI.CanTradeSkillShowCraftingUI = function(id) return id == 45542 end
                check(F.GetProfessionSpell(129) == 45542 and not F.GetProfessionSpell(171),
                    "Forever resolves the actual owned opener spell independently of the skill line and recipe IDs")
                env.C_TradeSkillUI.CanTradeSkillShowCraftingUI = function() return false end
                check(not F.GetProfessionSpell(129), "an entry the client cannot use to show crafting never becomes a secure action")
            end
        end
        check(st.frames == frames and #st.timers == timers and #st.errors == 0,
            "exact crafting adds no background execution or Lua errors")
    end end
end

do
    local env = setmetatable({}, { __index = _G })
    local state = { combat = false, spell = 45542, visible = true, hovered = true }
    local UIParent = { GetEffectiveScale = function() return 1 end, GetLeft = function() return 0 end, GetBottom = function() return 0 end }
    local owner = { GetEffectiveScale = function() return 1 end, IsVisible = function() return state.visible end,
        IsMouseOver = function() return state.hovered end, GetFrameStrata = function() return "MEDIUM" end,
        GetFrameLevel = function() return 100 end, GetRect = function() return 40, 80, 44, 44 end,
        GetScript = function() end, HookScript = function(self, key, callback) self[key] = callback end }
    local button
    env.UIParent, env.InCombatLockdown = UIParent, function() return state.combat end
    env.C_Timer = { After = function(_, callback) callback() end }
    env.CreateFrame = function(kind, _, parent, template)
        if kind == "Frame" then return { RegisterEvent = function() end, SetScript = function() end } end
        check(kind == "Button" and parent == UIParent and template:find("SecureActionButtonTemplate", 1, true)
            and template:find("SecureHandlerStateTemplate", 1, true), "profession proxy is a separate secure frame")
        button = { attrs = {}, SetAttribute = function(self, key, value)
                check(not state.combat, "no insecure spell writes occur in combat")
                self.attrs[key] = value
            end,
            Show = function(self) self.shown = true end, Hide = function(self) self.shown = false end,
            RegisterForClicks = function(self, clicks) self.clicks = clicks end,
            IsShown = function(self) return self.shown end, IsMouseOver = function() return state.hovered end,
            SetFrameStrata = function() end, SetFrameLevel = function() end, ClearAllPoints = function() end,
            SetPoint = function(self, _, relative) check(relative == UIParent, "secure proxy never anchors to the ordinary HUD") end,
            SetSize = function() end }
        return button
    end
    env.RegisterStateDriver = function(frame, attribute, expression)
        check(frame == button and attribute == "fluxcombat" and expression == "[combat] locked; ready",
            "the combat driver owns retirement of the protected click region")
    end
    local ns = { Flux = {} }
    assert(loadfile(root .. "/Core/SecureClickProxy.lua", "t", env))("_FluxUI", ns)
    local proxy = ns.Flux.SecureClickProxy
    proxy.Attach(owner, { spell = function() return state.spell end, enabled = function() return state.visible end,
        clicks = "LeftButtonUp" })
    owner.OnEnter()
    check(button.shown and button.attrs.type == "spell" and button.attrs.spell == 45542
        and button.clicks == "LeftButtonUp", "only the real release click has the exact spell action")
    state.spell = 3101; proxy.Refresh(owner)
    check(button.shown and button.attrs.spell == 3101, "an armed proxy updates to the newly displayed profession")
    state.spell = nil; proxy.Refresh(owner)
    check(not button.shown, "leaving the opening stage retires the old secure hit region")
    state.spell = 45542; proxy.Refresh(owner)
    state.combat = true
    local driver = assert(load("return function(self, newstate) " .. button.attrs["_onstate-fluxcombat"] .. " end"))()
    driver(button, "locked")
    proxy.Refresh(owner)
    check(not button.shown, "combat hides the secure opener without another player interaction")
end
print(("Auction restock follow-up craft: %d checks PASS; %d profiles; native open/craft/input/taint NOT RUN"):format(checks, profiles))
