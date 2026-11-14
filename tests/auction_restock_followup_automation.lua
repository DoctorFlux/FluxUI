-- Job-specific follow-up dispatch uses the existing bank/vendor/mail owners.
-- Native permissions, visual glow and protected input remain in-game checks.
local root = os.getenv("FLUX_AH_ROOT") or "."
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function fixture(path, flag)
    local export = setmetatable({ [flag] = true }, { __index = _G })
    return assert(loadfile(root .. "/tests/" .. path .. ".lua", "t", export))()
end
local follow = fixture("auction_restock_followup", "FLUX_FOLLOWUP_FIXTURE_EXPORT")
local sources = fixture("auction_restock_sources", "FLUX_AH_SOURCES_FIXTURE_EXPORT")
local mailFixture = fixture("mail_restock", "FLUX_MAIL_RESTOCK_FIXTURE_EXPORT")
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "ready" }) do
        for _, globalAuto in ipairs({ false, true }) do
            profiles = profiles + 1
            local A, st, env, F = follow(legacy, provider)
            st.settings.autoRestock, st.settings.autoBankRestock = globalAuto, globalAuto
            st.recipes[1].reagents[3] = { itemID = 202, count = 2 }
            if not legacy then
                local third = { required = true, reagentType = 0, quantityRequired = 2,
                    dataSlotIndex = 3, reagents = { { itemID = 202 } } }
                st.recipes[1].craftingData.schematic.reagentSlotSchematics[3] = third
                local schematic = env.C_TradeSkillUI.GetRecipeSchematic
                env.C_TradeSkillUI.GetRecipeSchematic = function(id)
                    local value = schematic(id); if value then value.reagentSlotSchematics[3] = third end; return value
                end
            end
            st.settings.merchantSources[202] = { unlimited = true, unitPrice = 5 }
            st.openAH(); st.press(); st.ack(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
            st.bags[200] = 2; F.Refresh()
            check(F.GetState().kind == "vendor" and F.GetVendorTargets()[201] == 2 and F.GetVendorTargets()[202] == 4,
                "one current vendor stage exposes every required item in physical units")
            check(not F.IsAutoEnabled() and A.Settings().autoFollowup == nil,
                "new job automation defaults off independently of both global automation options")
            local batches = 0
            env.FluxVendorAuto.DoAuctionFollowup = function(manual)
                if st.otherVendorBuy then return "busy" end
                batches = batches + 1
                local targets = F.GetVendorTargets()
                check(targets[201] == 2 and targets[202] == 4 and targets[999] == nil,
                    "clicking the stage dispatches every relevant vendor ingredient and no unrelated target")
                check(manual == (not F.IsAutoEnabled()), "manual and independent automatic intents remain distinct")
                for id, quantity in pairs(targets) do st.bags[id] = (st.bags[id] or 0) + quantity end
                return true
            end
            st.merchantOpen = true; st.emit("MERCHANT_SHOW")
            check(F.IsContextOpen("vendor") and F.GetState().contextOpen and batches == 0,
                "relevant open context becomes ready without silently enabling independent automation")
            st.otherVendorBuy = true; st.followPress()
            check(batches == 0, "clicking during an existing global owner queue never restarts or duplicates it")
            st.otherVendorBuy = false; st.emit("BAG_UPDATE_DELAYED")
            check(batches == 1 and F.GetState().kind == "craft" and #st.crafts == 0,
                "one queued press completes all remaining vendor goals and leaves crafting for a player press")
            check(st.settings.autoRestock == globalAuto and st.settings.autoBankRestock == globalAuto,
                "job dispatch never changes either global automation preference")

            A, st, env, F = follow(legacy, provider)
            st.settings.autoRestock, st.settings.autoBankRestock = globalAuto, globalAuto
            st.openAH(); st.press(); st.ack(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
            st.bags[200] = 2; F.Refresh()
            batches = 0
            env.FluxVendorAuto.DoAuctionFollowup = function(manual)
                check(not manual, "enabled independent automation uses the existing owner without inventing a player click")
                batches = batches + 1
                return true -- Hold bag publication, as the native owner can finish first.
            end
            F.SetAutoEnabled(true)
            check(batches == 0, "independent automation waits for the relevant interaction")
            st.merchantOpen = true; st.emit("MERCHANT_SHOW")
            F.Refresh(); st.emit("MERCHANT_UPDATE"); st.emit("BAG_UPDATE_DELAYED")
            check(batches == 1, "unchanged native bag facts cannot automatically repeat the same vendor batch")
            check(F.GetState().canAct == false, "an accepted owner batch cannot advertise another usable pending action")
            st.followPress()
            check(batches == 1, "a repeated icon press cannot repeat an accepted owner batch before bag publication")
            F.SetAutoEnabled(false); F.SetAutoEnabled(true)
            check(batches == 1, "toggling independent automation cannot repeat an accepted batch on stale bag facts")
            st.combat = true; st.emit("MERCHANT_UPDATE")
            check(not F.IsContextOpen("vendor") and batches == 1, "combat suppresses context readiness and automatic dispatch")
            st.combat = false; F.SetAutoEnabled(false)
            check(not F.IsAutoEnabled() and not A.Settings().autoFollowup and st.settings.autoRestock == globalAuto,
                "disabling job automation leaves global automation unchanged")

            -- Bank readiness must be live, even if a bag addon shows a cached bank.
            A, st, env, F = follow(legacy, provider)
            st.settings.autoRestock, st.settings.autoBankRestock = globalAuto, globalAuto
            st.settings.restockItems = { [200] = { countBank = true }, [201] = { countBank = true } }
            st.bankItems = { [200] = 2, [201] = 2 }
            env.FluxRestock.Inv.Bank = { GetCount = function(id) return st.bankItems[id] or 0 end,
                IsOpen = function() return true end, IsLive = function() return st.liveBank == true end }
            st.openAH(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED"); F.Refresh()
            check(F.GetState().kind == "bank" and not F.IsContextOpen("bank"), "cached bank counts cannot glow or start native bank moves")
            check(F.GetState().canAct == false, "cached bank context cannot advertise a usable pending action")
            local bankBatches, bankAttempts = 0, 0
            st.inventory.GetBagGeneration = function() return st.bagGeneration or 0 end
            env.FluxBankRestock = { RunAuctionFollowup = function()
                bankAttempts = bankAttempts + 1
                if st.bankBlocked then return false end
                bankBatches = bankBatches + 1
                local goals = F.GetBankTargets()
                check(#goals == 2, "one bank press submits all current job material targets")
                for _, entry in ipairs(goals) do st.bags[entry.itemID] = entry.target end
                return true
            end }
            F.Refresh()
            check(F.GetState().canAct == false and bankAttempts == 0,
                "cached bank context cannot advertise a usable pending action even with its owner loaded")
            st.liveBank = true; st.emit("BANKFRAME_OPENED")
            check(F.GetState().contextOpen and F.IsContextOpen("bank") and bankBatches == 0,
                "bank lifecycle refreshes readiness even when cached quantities do not change")
            st.followPress()
            check(bankBatches == 1 and F.GetState().kind == "craft" and #st.crafts == 0,
                "one bank press supplies all required bank items without automatically crafting")
            st.bags[200], st.bags[201], st.bankBlocked = 0, 0, true; F.Refresh(); F.SetAutoEnabled(true)
            F.Refresh(); st.emit("BANKFRAME_OPENED")
            check(bankAttempts == 2 and bankBatches == 1,
                "a failed automatic owner attempt is bounded while inventory and money facts stay unchanged")
            st.bankBlocked, st.bagGeneration = false, 1; st.emit("BAG_UPDATE_DELAYED")
            check(bankBatches == 2 and F.GetState().kind == "craft" and #st.crafts == 0
                and st.settings.autoBankRestock == globalAuto and st.settings.autoRestock == globalAuto,
                "independent automatic bank dispatch works with either global setting and never starts crafting")

            -- Real execution owners: scoped vendor goals exclude ordinary targets.
            local load
            A, st, env, load = sources(legacy, false, provider == "ready")
            env.print = function() end
            st.settings.autoRestock = globalAuto
            st.settings.restockItems = { [201] = { targetQuantity = 2 }, [202] = { targetQuantity = 7 }, [203] = { targetQuantity = 3 } }
            A.Followup = { GetVendorTargets = function() return { [201] = 2, [203] = 3 } end }
            load("Inventory/Restock/Core/FluxRestockList.lua")
            env.FluxRestockItemRegistry.IsChargeItem = function() return false end
            env.FluxRestockItemRegistry.GetChargeInfo = function() return false end
            env.FluxRestockItemRegistry.GetItemMaxCharges = function() return nil end
            env.MerchantFrame = { IsShown = function() return true end }
            env.GetMerchantNumItems = function() return 3 end
            env.GetMerchantItemID = function(slot) return 200 + slot end
            env.GetMerchantItemLink = function(slot) return "item:" .. 200 + slot end
            env.GetMerchantItemMaxStack = function() return 20 end
            env.GetMerchantItemInfo = function(slot) return "Item" .. 200 + slot, 1, 5, 1, -1, true, true, false end
            env.GetMerchantItemCostInfo = function() return 0 end
            env.FluxRestock.Inv.NotifyAutomationPulse = function() end
            st.inventory.NotifyAutomationPulse = function() end
            st.vendorBuys = {}
            env.BuyMerchantItem = function(slot, quantity)
                check(env.FluxVendorAuto.IsAuctionFollowupBusy(), "actual vendor native dispatch never advertises an idle follow-up owner")
                st.vendorJoin = env.FluxVendorAuto.DoAuctionFollowup(false)
                local id = 200 + slot; st.vendorBuys[id] = (st.vendorBuys[id] or 0) + quantity
                st.bags[id] = (st.bags[id] or 0) + quantity
            end
            load("Inventory/Restock/Vendor/FluxVendorBuy.lua")
            check(not env.FluxVendorAuto.IsAuctionFollowupBusy(), "actual vendor readiness query is idle before dispatch")
            env.FluxVendorAuto.DoAuctionFollowup(false); st.advance(1)
            check(st.vendorBuys[201] == 2 and st.vendorBuys[203] == 3 and not st.vendorBuys[202],
                "actual vendor owner executes all scoped ingredients while unrelated restock stays untouched")
            check(st.vendorJoin == "busy", "actual vendor owner refuses a second follow-up queue while its native purchase is in flight")
            check(st.settings.autoRestock == globalAuto, "scoped vendor owner preserves global auto setting")
            check(not env.FluxVendorAuto.CanAuctionFollowup(),
                "a merchant with only unrelated remaining targets cannot keep this job's vendor context ready")
            local vendorTargets = A.GetVendorCraftTargets
            A.GetVendorCraftTargets = function() return { [201] = { target = 1, maxUnitPrice = 1 } } end
            A.Followup.GetVendorTargets = function() return { [201] = 1 } end
            st.settings.restockItems[201].targetQuantity = 10
            env.GetMerchantItemInfo = function(slot) return "Item" .. 200 + slot, 1, st.livePrice, 1, -1, true, true, false end
            for _, phase in ipairs({ "prepare", "execute" }) do
                st.bags[201], st.vendorBuys = 0, {}
                st.livePrice = phase == "prepare" and 2 or 1
                env.FluxVendorAuto.InvalidateMerchantIndex(); env.FluxVendorAuto.GetMerchantItemIndex(false); st.advance(1)
                if phase == "prepare" then check(not env.FluxVendorAuto.CanAuctionFollowup(),
                    "scoped vendor preparation rejects an invoice above the saved craft price despite an ordinary base shortage") end
                if phase == "execute" then st.livePrice = 2 end
                env.FluxVendorAuto.DoAuctionFollowup(false)
                check(not st.vendorBuys[201] and st.bags[201] == 0,
                    "scoped vendor preparation and execution cannot borrow an unrelated base target to bypass the saved craft price")
            end
            env.FluxVendorAuto.DoRestockManual()
            check(st.vendorBuys[201] == 10, "ordinary manual restock retains its separate base-target fallback above the craft price")
            A.GetVendorCraftTargets = vendorTargets

            -- Real bank owner: capture its native mover boundary, not native moves.
            st.settings.autoBankRestock = globalAuto
            st.settings.restockItems = { [202] = { targetQuantity = 7 } }
            st.bags[200], st.bags[201], st.bags[202], st.bankItems[200], st.bankItems[201], st.bankItems[202] = 0, 0, 0, 20, 20, 20
            A.Followup = { GetBankTargets = function() return { { itemID = 200, target = 2, mode = "stack", restock = true },
                { itemID = 201, target = 3, mode = "stack", restock = true } } end }
            env.FluxRestockItemRegistry.InvalidateBankTargetsCache()
            load("Inventory/Restock/Bank/FluxBankRestockRules.lua")
            env.FluxBankRestockMoveExec = { Start = function(session) st.bankTasks = session.tasks; return true end }
            local create = env.CreateFrame
            env.CreateFrame = function(...) local frame = create(...); frame.UnregisterAllEvents = function() end; return frame end
            load("Inventory/Restock/Bank/FluxBankRestock.lua")
            local BR = env.FluxBankRestock
            check(BR.CanAuctionFollowup() and not st.bankTasks, "actual bank readiness resolves scoped work without submitting a mover task")
            check(BR.RunAuctionFollowup(false) == true and #st.bankTasks == 2,
                "actual bank owner submits all job-scoped targets without the unrelated ordinary target")
            local tasks = st.bankTasks
            check(not BR.CanAuctionFollowup(), "running shared bank mover does not advertise another follow-up click")
            check(BR.RunAuctionFollowup(false) == "busy" and st.bankTasks == tasks,
                "an already running global/shared bank mover is joined without resetting its tasks")
            check(st.bankTasks[1].withdraw == 2 and st.bankTasks[2].withdraw == 3 and st.settings.autoBankRestock == globalAuto,
                "scoped bank quantities and the existing auto preference remain exact")
            BR.Stop()

            -- Real mailbox worker: one request made before snapshot completion
            -- collects every relevant attachment, regardless of global auto.
            local ms = mailFixture(client:lower(), provider, true)
            ms.mail.SetSetting("Restock", "AutoCollect", globalAuto)
            ms:realFollowup({ [200] = 2, [201] = 3 }, { [200] = 2, [201] = 3 })
            ms.inbox = {
                { sender = "AH", subject = "Won", money = 0, cod = 0, items = { { id = 200, quantity = 2 } } },
                { sender = "AH", subject = "Won", money = 0, cod = 0, items = { { id = 201, quantity = 3 } } },
                { sender = "Other", subject = "Unrelated", money = 0, cod = 0, items = { { id = 999, quantity = 9 } } },
            }
            ms:show(); ms:event("MAIL_INBOX_UPDATE")
            ms.bagStorm, ms.unreliable = true, true
            check(ms.mail.IsRestockContextOpen() and ms.followup.IsContextOpen("mail"),
                "native mailbox context remains actionable while bag counts are settling")
            ms.followup.Click()
            ms:pumpFrames(6)
            for _ = 1, 2 do check(ms.pending, "mail worker owns one current attachment command"); ms:ack(); ms:advance(2) end
            check(#ms.calls == 2 and not next(ms.followup.GetMailItems()) and #ms.inbox == 1 and ms.inbox[1].items[1].id == 999,
                "existing mail worker collects every job item once and leaves unrelated attachments")

            ms = mailFixture(client:lower(), provider, true)
            ms.mail.SetSetting("Restock", "AutoCollect", globalAuto)
            ms:realFollowup({ [200] = 2, [201] = 3 }, { [200] = 2, [201] = 3 })
            ms.inbox = {
                { sender = "AH", subject = "First", money = 0, cod = 0, items = { { id = 200, quantity = 2 } } },
                { sender = "AH", subject = "Second", money = 0, cod = 0, items = { { id = 201, quantity = 3 } } },
            }
            ms.followup.SetAutoEnabled(true)
            local refresh, depth, peak, notices = ms.followup.Refresh, 0, 0, 0
            ms.followup.Refresh = function(...)
                depth, notices = depth + 1, notices + 1; peak = math.max(peak, depth)
                refresh(...); depth = depth - 1
            end
            ms:show(); ms:update()
            for _ = 1, 2 do check(ms.pending, "independent mail automation starts each relevant native command once"); ms:ack(); ms:advance(2) end
            check(#ms.calls == 2 and not next(ms.followup.GetMailItems())
                and ms.mail.GetSetting("Restock", "AutoCollect") == globalAuto,
                "independent mail automation collects the complete job with global auto off or on and preserves its setting")
            check(depth == 0 and peak <= 2 and notices < 100,
                "mail readiness publication and follow-up dispatch remain bounded without worker-update recursion")

            for _, readyBeforeAuto in ipairs({ false, true }) do
                ms = mailFixture(client:lower(), provider, true)
                ms.mail.SetSetting("Restock", "AutoCollect", false)
                ms:realFollowup({ [101] = 1 }, { [101] = 1 })
                ms.inbox = { { sender = "AH", subject = "Won", money = 0, cod = 0, items = { { id = 101, quantity = 1 } } } }
                ms.free = 1
                if not readyBeforeAuto then ms.followup.SetAutoEnabled(true) end
                ms:show(); ms:update(); ms:pumpFrames(8)
                if readyBeforeAuto then ms.followup.SetAutoEnabled(true) end
                check(#ms.calls == 0 and not ms.mail.GetJobGroup() and not ms.followup.GetState().canAct,
                    "a full-bag automatic mail attempt remains bounded without an accepted native take")
                ms.free = 20; ms.followup.Refresh(); ms:pumpFrames(8)
                check(#ms.calls == 1 and ms.pending and not ms.followup.GetState().canAct,
                    "freeing bag space retries a rejected mail attempt without reopening or another player click")
                ms.followup.Refresh(); ms.followup.Click(); ms:pumpFrames(8)
                check(#ms.calls == 1, "accepted retried mail take remains protected from duplicate dispatch")
            end

            for _, failed in ipairs({ false, true }) do
                ms = mailFixture(client:lower(), provider, true)
                ms.mail.SetSetting("Restock", "AutoCollect", false)
                ms:realFollowup({ [101] = 1 }, { [101] = 1 })
                ms.inbox = { { sender = "AH", subject = "Won", money = 0, cod = 0, items = { { id = 101, quantity = 1 } } } }
                ms.followup.SetAutoEnabled(true); ms:show(); ms:update()
                check(#ms.calls == 1 and ms.pending and not ms.followup.GetState().canAct,
                    "a started mail batch owns exactly one native command before cancellation")
                if failed then ms:event("MAIL_FAILED") else ms.mail.StopRestockItems() end
                ms.pending = false; ms:pumpFrames(8); ms.followup.Refresh(); ms:pumpFrames(8)
                check(#ms.calls == 1 and not ms.mail.GetJobGroup() and ms.followup.GetMailItems()[101] == 1,
                    "failed or cancelled mail owner preserves its receipt and bounds retries on unchanged facts")
                ms.followup.Click(); ms:pumpFrames(8)
                check(#ms.calls == 2 and ms.pending and not ms.followup.GetState().canAct,
                    "a fresh manual click after native mail failure or cancellation retries once without a stale accepted latch")
            end
        end
    end
end
print(("Auction follow-up automation: %d checks PASS; %d client/provider/global-option profiles; native actions/glow NOT RUN"):format(checks, profiles))
