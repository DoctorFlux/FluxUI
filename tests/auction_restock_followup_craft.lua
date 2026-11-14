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
            local state, count = F.CraftClick(task)
            st.hardware = false
            return state, count
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
        end
        check(st.frames == frames and #st.timers == timers and #st.errors == 0,
            "exact crafting adds no background execution or Lua errors")
    end end
end
print(("Auction restock follow-up craft: %d checks PASS; %d profiles; native open/craft/input/taint NOT RUN"):format(checks, profiles))
