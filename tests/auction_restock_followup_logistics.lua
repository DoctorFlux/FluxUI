local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({FLUX_FOLLOWUP_FIXTURE_EXPORT = true}, {__index = _G})
local fixture = assert(loadfile(root .. "/tests/auction_restock_followup.lua", "t", export))()
local checks = 0
local function check(value, label)
    checks = checks + 1
    assert(value, label)
end
local function selection()
    return {jobId = 8, taskId = "t2", planRevision = "sealed", itemID = 700, quantity = 2, outputQuantity = 6}
end
for _, legacy in ipairs({true, false}) do
    for _, source in ipairs({"absent", "ready"}) do
        local A, st, _, F = fixture(legacy, source)
        local ready, processed, queries = nil, {}, 0
        local provider = {
            GetReady = function() queries = queries + 1; return ready end,
            Process = function(chosen)
                check(st.hardware and not st.combat, "the callback runs in the manual click stack")
                processed[#processed + 1] = chosen
                ready = nil
                F.Refresh()
            end,
        }
        check(F.RegisterLogisticsCraft(provider) == true, "registered the optional craft provider")
        check(not F.GetState() and not next(st.inventoryListeners or {}), "idle companion adds no owner watch")
        check(F.RegisterLogisticsCraft({GetReady = provider.GetReady}) == false, "invalid provider rejected")
        ready = selection()
        F.SetAutoEnabled(true)
        local state = assert(F.GetState())
        check(state.kind == "craft" and state.quantity == 2 and state.items[700] == 6 and state.canAct,
            "the existing reminder uses craft operations and icon output quantities")
        check(not A.Settings().followup and #processed == 0 and not next(st.inventoryListeners or {}),
            "a ready accepted plan adds no native job, owner watch, or automatic press")
        st.reliable = false
        F.Refresh()
        check(not F.GetState().canAct, "unreliable owner inventory disables the press")
        st.followPress()
        check(#processed == 0, "unreliable inventory cannot execute")
        st.reliable = true
        F.Refresh()
        st.combat = true
        st.followPress()
        check(#processed == 0, "combat cannot execute")
        st.combat = false
        for field, update in pairs({
            jobId = 9, taskId = "t3", planRevision = "replacement", itemID = 701,
            quantity = 1, outputQuantity = 3,
        }) do
            ready = selection()
            F.Refresh()
            ready[field] = update
            st.followPress()
            check(#processed == 0 and F.GetState().logistics[field] == update, "stale " .. field .. " repaints only")
        end
        ready = selection()
        F.Refresh()
        A.transaction = {}
        st.followPress()
        check(#processed == 0 and not F.GetState(), "active native purchase blocks companion crafting")
        A.transaction = nil
        F.Refresh()
        A.Settings().followup = {version = 1, receipts = {[200] = {remaining = 2, lastBags = 0}}, outputs = {}}
        local beforeNative = queries
        st.followPress()
        check(#processed == 0 and F.GetState().kind == "mail" and queries == beforeNative,
            "native followup preempts companion display and click without polling the provider")
        A.Settings().followup = nil
        st.followPress()
        check(#processed == 0 and F.GetState().kind == "craft", "a native mail press cannot fall through to companion craft")
        st.followPress()
        check(#processed == 1 and not F.GetState() and not A.Settings().followup,
            "a fresh companion press dispatches exactly one task and refreshes after processing")
        local result = processed[1]
        check(result.jobId == 8 and result.taskId == "t2" and result.planRevision == "sealed"
            and result.itemID == 700 and result.quantity == 2 and result.outputQuantity == 6, "exact selection reaches Process")
        st.followPress()
        check(#processed == 1, "an already dispatched item cannot replay once provider clears it")
        ready = selection()
        ready.outputQuantity = -1
        F.Refresh()
        check(not F.GetState(), "invalid counts never paint a button")
        check(F.RegisterLogisticsCraft(nil) == true and not F.GetState(), "provider can be removed without native state")
    end
end

do
    local _, st, _, F = fixture(false, "ready")
    local settle, registrations, presses = nil, 0, 0
    st.flux.Inventory.OnStormSettled = function(callback)
        registrations = registrations + 1
        settle = callback
    end
    local ready = selection()
    ready.direct = true
    check(F.RegisterLogisticsCraft({
        GetReady = function() return ready end,
        Process = function(chosen)
            check(st.hardware and chosen.quantity == 9 and chosen.outputQuantity == 9,
                "the next press uses the settled nine-craft remainder")
            presses = presses + 1
            ready = nil
        end,
    }), "the companion can publish a direct craft without a standalone order")
    ready.quantity, ready.outputQuantity = 9, 9
    st.bagStorm = true
    F.Refresh(); F.Refresh()
    local shown = F.GetProfessionWindowAction()
    check(shown.quantity == 9 and not shown.canAct and registrations == 1,
        "a transient bag storm leaves the exact remainder visible and registers only one wake-up")
    st.followPress()
    check(presses == 0 and registrations == 1, "a press cannot dispatch while bags are settling")
    st.bagStorm = false
    settle()
    check(F.GetProfessionWindowAction().canAct and F.GetState().canAct,
        "the existing HUD and profession button re-enable when the storm alone ends")
    st.followPress()
    check(presses == 1 and not F.GetState(), "the fresh action runs once and retires when the provider clears it")
end

do
    local A, st, _, F = fixture(false, "ready")
    st.flux.Client = { isForever = true }
    local ready, presses = selection(), 0
    ready.quantity, ready.outputQuantity = 2, 2
    ready.resume, ready.carriedOutput, ready.remainingOutput = "saved-attempt:2", 2, 2
    check(F.RegisterLogisticsCraft({
        GetReady = function() return ready end,
        Process = function(chosen)
            check(st.hardware and chosen.resume == "second-attempt:2" and chosen.carriedOutput == 2
                and chosen.remainingOutput == 2 and chosen.taskId == ready.taskId,
                "a fresh HUD press passes the exact two-pack recovery and remainder")
            presses = presses + 1
            ready.resume, ready.carriedOutput, ready.remainingOutput = nil, nil, nil
        end,
    }), "registers the companion carried recovery")
    local shown = assert(F.GetProfessionWindowAction())
    check(shown.kind == "craft" and shown.logistics.resume and shown.items[700] == 2
        and not shown.nativeCraft and shown.canAct and not A.Settings().followup,
        "the old attempt displays the two missing outputs without creating a FluxUI job")
    ready.resume = "second-attempt:2"
    st.hardware = true; F.ClickProfessionWindowAction(shown); st.hardware = false
    check(presses == 0 and F.GetProfessionWindowAction().logistics.resume == "second-attempt:2",
        "an equal-quantity replacement cannot reuse the old Process press")
    st.followPress()
    check(presses == 1 and F.GetProfessionWindowAction().nativeCraft
        and not F.GetProfessionWindowAction().logistics.resume,
        "after counting the carried output the ordinary native craft action returns")
end

for _, legacy in ipairs({true, false}) do
    local A, st, _, F = fixture(legacy, "ready")
    local incoming, ready = {}, nil
    check(F.RegisterLogisticsCraft({
        GetReady = function() return ready end,
        Process = function() assert(st.hardware, "companion work requires a player press") end,
        GetIncoming = function() return incoming end,
    }), "registered the optional incoming receipt provider")
    check(not F.GetState() and not next(F.GetMailItems(true)), "an empty companion receipt map stays hidden")

    incoming = {[600] = 3, [601] = 2}
    F.RefreshLogistics()
    local state = assert(F.GetState())
    local targets = F.GetMailItems(true)
    check(state.kind == "mail" and state.companionMail == true and state.items[600] == 3
        and state.items[601] == 2 and state.quantity == 5, "confirmed companion receipts show the mail reminder")
    check(targets[600] == 3 and targets[601] == 2 and not next(F.GetMailItems()),
        "companion targets stay independent from ordinary restock mail")

    A.Settings().followup = {version = 1, receipts = {[200] = {remaining = 2, lastBags = 0}}, outputs = {}}
    F.Refresh()
    state = assert(F.GetState())
    check(state.kind == "mail" and not state.companionMail and state.items[200] == 2 and not state.items[600],
        "ordinary restock mail retains priority over companion mail")
    check(F.GetMailItems()[200] == 2 and F.GetMailItems(true)[600] == 3,
        "priority preserves both mail sources' independent targets")

    local waiting = {version = 1, receipts = {}, outputs = {[999] = {}}}
    A.Settings().followup = waiting
    F.Refresh()
    state = assert(F.GetState())
    check(state.kind == "mail" and state.companionMail == true,
        "a native plan waiting for materials allows pending companion mail to appear")

    incoming = {}
    ready = selection()
    F.RefreshLogistics()
    state = assert(F.GetState())
    check(state.kind == "craft" and state.logistics.jobId == 8 and state.canAct
        and not next(F.GetMailItems(true)) and A.Settings().followup == waiting,
        "ready companion crafting replaces cleared mail while the native plan continues to wait")

    ready = nil
    F.RefreshLogistics()
    state = F.GetState()
    check((not state or state.kind == "waiting") and A.Settings().followup == waiting,
        "cleared companion work leaves native waiting bookkeeping without an actionable reminder")
end
for _, legacy in ipairs({true, false}) do
    local A, st, _, F = fixture(legacy, "ready")
    local stage = {key = "vendor:closed", items = {[2321] = 6, [2605] = 2}, canBuy = false}
    local incoming, bought = {}, 0
    local provider = {
        GetReady = function() if not stage then return selection() end end,
        Process = function() error("vendor press cannot craft") end,
        GetIncoming = function() return incoming end,
        GetVendorStage = function() return stage end,
    }
    check(not F.RegisterLogisticsCraft(provider), "rejects a partial vendor-stage callback pair")
    provider.BuyVendorStage = function(key)
        check(st.hardware and stage.canBuy and key == "vendor:replacement", "vendor press dispatches the exact live stage")
        stage.canBuy = false
        bought = bought + 1
        return true
    end
    F.SetAutoEnabled(true)
    check(F.RegisterLogisticsCraft(provider), "registers the optional vendor reminder and owner")
    local shown = assert(F.GetState())
    check(shown.kind == "vendor" and shown.items[2321] == 6 and shown.items[2605] == 2 and shown.quantity == 8
        and not shown.canAct and not F.GetProfessionWindowAction() and not next(F.GetVendorTargets()),
        "companion vendor needs appear before the visit and never feed standalone vendor buys")
    st.followPress()
    check(bought == 0, "the reminder stays passive with the vendor closed")
    incoming[700] = 2
    F.RefreshLogistics()
    check(F.GetState().companionMail and F.GetMailItems(true)[700] == 2, "pending mail keeps its existing priority")
    incoming[700] = nil
    stage.key, stage.canBuy = "vendor:original", true
    F.RefreshLogistics()
    check(F.GetState().canAct and bought == 0, "the matching merchant readies the reminder without a second scheduler buying")
    stage.key = "vendor:replacement"
    st.followPress()
    check(bought == 0 and F.GetState().canAct, "a same-quantity vendor replacement requires a fresh press")
    st.followPress()
    check(bought == 1 and F.GetState().kind == "vendor" and not F.GetState().canAct and not F.GetProfessionWindowAction(),
        "one press buys through the companion and keeps crafting hidden while the materials settle")
    stage = nil
    F.Refresh()
    check(F.GetState().kind == "craft" and F.GetProfessionWindowAction().kind == "craft",
        "crafting returns once the companion clears its vendor stage")
end

for _, legacy in ipairs({true, false}) do
    local A, st, _, F = fixture(legacy, "ready")
    st.emit("AUCTION_HOUSE_SHOW")
    check(not F.GetState(), "opening an ordinary Auction House does not show an offer")
    local entry = {jobId = 8, id = 1, planRevision = "approved", itemID = 200, kind = "auction",
        quantity = 2, maxUnitPrice = 10, maxTotalPrice = 20}
    local submitted, confirmed = 0, 0
    local function authorize(request, units) return request.jobId == 8 and units <= 2 end
    local function observe(event)
        if event == "submitted" then submitted = submitted + 1 end
        if event == "confirmed" then confirmed = confirmed + 1 end
    end
    check(A.PrepareLogistics(entry, 2, authorize, observe, false), "passive Shopping quote prepared")
    st.drain()
    check(A.state == "ready" and not F.GetState(), "passive Shopping quote stays off the HUD")
    check(A.PrepareLogistics(entry, 2, authorize, observe, true), "explicit Shopping selection claims its ready quote")
    check(F.GetState().kind == "auction" and F.GetState().items[200] == 2 and F.GetState().canAct,
        "explicit Shopping selection is actionable on the HUD")
    local replacement = {}
    for key, value in pairs(A.offer) do replacement[key] = value end
    A.offer = replacement
    st.followPress()
    check(submitted == 0 and not st.calls.quote and not st.calls.buyStack and F.GetState().offer == replacement,
        "a redirected click repaints an unshown quote without submitting it")
    st.followPress()
    st.ack()
    check(submitted == 1 and confirmed == 1 and not F.GetState() and not A.Settings().followup,
        "the HUD submits the current Shopping offer once through its existing owner")

    st.openAH()
    local state = assert(F.GetState())
    check(state.kind == "auction" and state.itemID == A.offer.itemID, "standalone Restock projects its current offer")
    st.advance(31)
    check(not A.GetFollowupOffer() and (not F.GetState() or F.GetState().kind == "waiting"),
        "the expired quote retires the HUD without another player click")
end
for _, legacy in ipairs({true, false}) do
    local A, st, env, F = fixture(legacy, "ready")
    st.openAH(); st.press(); st.ack(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
    check(F.GetState().kind == "mail" and st.painted.kind == "mail" and not F.GetProfessionWindowAction(),
        "an acknowledged FluxUI craft plan shows collection before its profession opener")
    st.mailboxOpen, st.bagStorm = true, true
    st.emit("MAIL_SHOW")
    check(st.painted.kind == "mail" and not F.GetProfessionWindowAction() and F.GetMailItems()[200] == 2,
        "the opener stays hidden while the mailbox transfer is unsettled")
    A.GetCraftBankAvailable = function(id) return id == 201 and 2 or 0 end
    st.bagStorm, st.bags[200] = false, 2
    st.emit("BAG_UPDATE_DELAYED")
    check(st.painted.kind == "bank" and st.painted.items[201] == 2 and not F.GetProfessionWindowAction(),
        "the remaining bank reagent keeps the exact craft and profession hidden")
    st.bags[201] = 2
    st.emit("BAG_UPDATE_DELAYED")
    local shown = assert(F.GetProfessionWindowAction())
    check(shown.kind == "profession" and shown.canAct and shown.itemID == 100,
        "all carried materials let standalone FluxUI offer the exact profession")
    F.Refresh()
    check(F.GetProfessionWindowAction() == shown, "unchanged profession refresh retains the painted window token")
    st.hardware = true; F.ClickProfessionWindowAction(shown); st.hardware = false
    check(#st.opens == 1 and #st.crafts == 0 and #st.errors == 0,
        "one hardware press opens the exact FluxUI profession")
    st.professionID, st.professionName = 129, "First Aid"
    st.emit("TRADE_SKILL_SHOW")
    local craft = F.GetProfessionWindowAction()
    check(st.painted.kind == "craft" and craft and craft.kind == "craft", "the ready profession publishes its exact craft")
    st.hardware = true; F.ClickProfessionWindowAction(shown); st.hardware = false
    check(#st.opens == 1 and #st.crafts == 0, "a stale window opener cannot fall through to crafting")

    A.Settings().followup = nil
    local selected = selection()
    selected.professionID, selected.professionName = 171, "Alchemy"
    local opened, notifications, incoming = 0, 0, { [700] = 2 }
    st.flux.Mail = { NotifyRestockTargetsChanged = function() notifications = notifications + 1 end }
    check(F.RegisterLogisticsCraft({
        GetReady = function() end,
        Process = function() error("opening a window cannot craft") end,
        GetIncoming = function() return incoming end,
        GetProfession = function() return selected end,
        OpenProfession = function(request)
            check(st.hardware and request.professionID == 171 and request.taskId == selected.taskId,
                "the companion callback receives the exact queued profession on the player press")
            opened = opened + 1
            selected = nil
        end,
    }), "registers the companion profession opener")
    check(notifications == 1 and st.painted.kind == "mail" and not F.GetProfessionWindowAction() and F.GetMailItems(true)[700] == 2,
        "companion pending mail refreshes the mailbox owner and keeps the window opener hidden")
    incoming = {}
    F.RefreshLogistics()
    shown = assert(F.GetProfessionWindowAction())
    selected.taskId = "replacement"
    st.hardware = true; F.ClickProfessionWindowAction(shown); st.hardware = false
    check(opened == 0 and st.painted.logistics.taskId == "replacement", "an unshown queue replacement cannot open a profession")
    st.hardware = true; F.ClickProfessionWindowAction(F.GetProfessionWindowAction()); st.hardware = false
    check(opened == 1 and not F.GetProfessionWindowAction() and not next(F.GetMailItems()),
        "the exact companion opener dispatches after mail settles and creates no FluxUI reservation")
    F.RefreshLogistics()
    check(notifications == 2, "unchanged companion batches do not restart the mailbox scan")
end
do
    local A, st, env, F = fixture(false, "ready")
    st.flux.Client = { isForever = true }
    local settleInventory
    st.flux.Inventory.RegisterStormSettled = function(key, callback)
        if key == "AuctionRestock.Followup" then settleInventory = callback end
    end
    st.openAH(); st.press(); st.ack(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
    st.professionID, st.bags[200], st.bags[201] = 129, 2, 2
    local recipeID, nativeCount, nativeEnabled = 78, 1, true
    local shown = function() return true end
    local page = { IsShown = shown,
        SchematicForm = { GetRecipeInfo = function() return { recipeID = recipeID } end },
        GetCraftableCount = function() return 5 end,
        CreateMultipleInputBox = { IsEnabled = function() return nativeEnabled end, GetValue = function() return nativeCount end,
            SetValue = function(_, count) nativeCount = count end } }
    local nativePresses = 0
    page.SetupMultipleInputBox = function(self, count) self.CreateMultipleInputBox:SetValue(count) end
    page.CreateInternal = function(_, id, count)
        check(st.hardware and id == 77 and count == 2, "only the simulated player presses Blizzard's Create for the prepared batch")
        nativePresses = nativePresses + 1
    end
    env.ProfessionsFrame = { IsShown = shown, CraftingPage = page }
    env.C_Timer.After = env.C_Timer.NewTimer
    env.hooksecurefunc = function(object, key, observer)
        local native = object[key]
        object[key] = function(...)
            native(...)
            observer(...)
        end
    end
    local reveals = 0
    check(F.RegisterLogisticsCraft({
        GetReady = function() end, Process = function() end,
        RevealNativeCraft = function(id, operations)
            check(st.hardware and id == 77 and operations == 2, "the original Restock workload hands off its exact recipe and batch")
            reveals, recipeID = reveals + 1, id
            return true
        end,
    }), "the companion may reveal native Create without supplying a queued craft")
    check(st.painted.kind == "craft" and st.painted.nativeCraft and st.painted.canAct and st.painted.nativeCraftOperations == 2,
        "a ready owner craft advertises its operation count through the ordinary HUD")
    st.followPress()
    check(reveals == 1 and nativeCount == 2 and #st.crafts == 0 and A.Settings().followup and F.GetState().kind == "craft",
        "opening the native recipe never submits an addon craft or marks the saved plan complete")
    check(st.painted.nativeCraftPrepared == 2 and not st.painted.canAct,
        "the HUD only advertises Create once the exact native amount is verified")
    st.followPress()
    check(reveals == 1 and nativePresses == 0, "a prepared owner's HUD remains a passive native Create instruction")

    st.bagStorm = true
    page:SetupMultipleInputBox(1)
    st.advance(0)
    check(nativeCount == 1 and not st.painted.nativeCraftPrepared,
        "a native amount reset does not authorize a rewrite during an inventory storm")
    st.bagStorm = false
    settleInventory()
    st.advance(0)
    check(nativeCount == 2 and st.painted.nativeCraftPrepared == 2,
        "the exact standalone preparation restores Blizzard's reset after the inventory settles")
    page.CreateMultipleInputBox:SetValue(1)
    st.advance(0)
    check(nativeCount == 1 and not st.painted.nativeCraftPrepared,
        "editing Blizzard's amount directly releases the HUD preparation")
    st.followPress()
    st.hardware = true; page:CreateInternal(77, nativeCount); st.hardware = false
    page:SetupMultipleInputBox(1)
    st.advance(0)
    check(nativePresses == 1 and nativeCount == 1 and not st.painted.nativeCraftPrepared and A.Settings().followup,
        "the native invocation consumes the preparation but only carried output advances the plan")

    local requested = 0
    env.C_TradeSkillUI.OpenRecipe = function(id)
        check(st.hardware and id == 77, "a delayed recipe selection starts with the displayed owner press")
        requested = requested + 1
    end
    F.RegisterLogisticsCraft(nil)
    recipeID, nativeCount = 78, 1
    st.followPress()
    check(requested == 1 and nativeCount == 1, "the owner never edits another recipe while waiting for Blizzard")
    st.emit("OPEN_RECIPE_RESPONSE", 78)
    st.advance(0)
    check(nativeCount == 1, "an unrelated native response cannot fill the amount")
    st.emit("OPEN_RECIPE_RESPONSE", 77)
    recipeID = 77
    st.emit("TRADE_SKILL_LIST_UPDATE")
    check(nativeCount == 1, "a synchronous list update leaves room for Blizzard to hydrate and reset the quantity")
    st.advance(0)
    check(nativeCount == 2, "the exact native response fills the saved batch after Blizzard selects the form")

    page.CreateMultipleInputBox:SetValue(1)
    st.advance(0)
    nativeEnabled = false
    st.followPress()
    st.advance(0)
    check(requested == 1 and nativeCount == 1, "an already selected recipe can wait for its native quantity field")
    st.bagStorm = true
    st.emit("BAG_UPDATE_DELAYED")
    nativeEnabled = true
    st.advance(0)
    check(nativeCount == 1, "field hydration cannot prepare the batch before carried inventory settles")
    st.bagStorm = false
    settleInventory()
    st.advance(0)
    check(nativeCount == 2, "inventory settlement prepares the already selected batch without another player press")

    local companionBusy = false
    check(F.RegisterLogisticsCraft({
        GetReady = function() end, Process = function() end,
        IsNativeCraftBusy = function() return companionBusy end,
    }), "the companion can publish native surface occupancy without moving the recipe")
    recipeID, nativeCount = 78, 1
    st.emit("TRADE_SKILL_LIST_UPDATE")
    st.followPress()
    companionBusy, recipeID = true, 77
    st.advance(0)
    check(nativeCount == 1, "a companion handoff on the same recipe preempts the delayed owner's quantity")
    companionBusy = false
    st.emit("BAG_UPDATE_DELAYED")
    st.advance(0)
    check(nativeCount == 1, "releasing the companion does not revive the older quantity request")

    recipeID, nativeCount = 78, 1
    st.followPress()
    st.emit("OPEN_RECIPE_RESPONSE", 77)
    st.bags[100] = 3
    st.emit("BAG_UPDATE_DELAYED")
    recipeID = 77
    st.advance(0)
    check(not A.Settings().followup and not F.GetState() and nativeCount == 1,
        "actual bag output retires the Restock craft and any older native quantity request")

    local prepared, dispatched = selection(), 0
    check(F.RegisterLogisticsCraft({
        GetReady = function() end,
        GetPreparedNativeCraft = function() return prepared end,
        Process = function() dispatched = dispatched + 1 end,
    }), "the companion can publish a read-only prepared native batch")
    check(st.painted.nativeCraftPrepared == 2 and st.painted.items[700] == 6
        and st.painted.logisticsPrepared and not st.painted.canAct,
        "the prepared companion HUD distinguishes Create operations from the item output count")
    st.followPress()
    check(dispatched == 0, "a prepared companion notice cannot call Process again")
    prepared = nil
    F.RefreshLogistics()
    check(not F.GetState(), "consuming or cancelling the native handoff retires the companion notice")
end
do
    local _, st, _, F = fixture(false, "ready")
    st.flux.Client = { isForever = true }
    local ready, processed = selection(), {}
    check(F.RegisterLogisticsCraft({
        GetReady = function() return ready end,
        Process = function(chosen)
            check(st.hardware, "direct companion selection still requires its own physical click")
            processed[#processed + 1] = chosen
            ready = nil
        end,
    }), "the original provider contract accepts optional direct capability")
    F.SetAutoEnabled(true)
    check(F.GetState().nativeCraft and F.GetState().logistics.direct == nil,
        "an ordinary companion task still advertises Open recipe")
    ready.direct = true
    st.followPress()
    local direct = F.GetState()
    check(#processed == 0 and direct.logistics.direct == true and direct.canAct
        and not direct.nativeCraft and not direct.nativeCraftOperations and not direct.direct,
        "a new direct capability refreshes the HUD as Craft without acting on the stale press")
    st.followPress()
    check(#processed == 1 and processed[1].direct == true and not F.GetState(),
        "a fresh press forwards the exact direct selection once")
    ready = selection()
    ready.direct = true
    F.Refresh()
    ready.direct = false
    st.followPress()
    check(#processed == 1 and F.GetState().nativeCraft and F.GetState().logistics.direct == nil,
        "losing direct capability falls back to Open recipe without submitting on a stale press")
    ready.direct = nil
    st.followPress()
    check(#processed == 2 and processed[2].direct == nil,
        "false and absent capabilities represent the same native preparation action")
end
do
    local _, st, _, F = fixture(false, "ready")
    local ready, opened = selection(), {}
    ready.professionID, ready.professionName = 171, "Alchemy"
    F.GetProfessionSpell = function(id)
        check(id == 171, "the spell overlay retains its exact skill lookup for older companions")
        return 2259
    end
    check(F.RegisterLogisticsCraft({
        GetReady = function() end,
        Process = function() error("opening a profession cannot craft") end,
        GetProfession = function() return ready end,
        OpenProfession = function(chosen)
            check(st.hardware and chosen.professionID == 171 and chosen.jobId == 8 and chosen.taskId == "t2",
                "one physical HUD click forwards the exact companion switch")
            opened[#opened + 1] = chosen
        end,
    }), "registers the optional tracked switch with the same provider contract")
    local shown = st.painted
    check(shown.kind == "profession" and shown.profession.spellID == 2259 and shown.logistics.queueSwitch == nil,
        "the original secure spell overlay still serves older companion selections")
    ready.queueSwitch = true
    st.hardware = true; F.ClickProfession(shown); st.hardware = false
    check(#opened == 0 and st.painted.profession.spellID == nil and st.painted.logistics.queueSwitch == true,
        "the tracked switch removes the spell overlay and retires the previously shown action")
    st.hardware = true; F.ClickProfession(st.painted); st.hardware = false
    check(#opened == 1 and opened[1].queueSwitch == true,
        "a fresh click enters the companion opener for the exact tracked switch")
    shown = st.painted
    ready.queueSwitch = false
    st.hardware = true; F.ClickProfession(shown); st.hardware = false
    check(#opened == 1 and st.painted.profession.spellID == 2259 and st.painted.logistics.queueSwitch == nil,
        "losing the capability re-enables the original overlay without dispatching a stale tracked action")
    shown = st.painted
    ready.queueSwitch = nil
    st.hardware = true; F.ClickProfession(shown); st.hardware = false
    check(#opened == 2 and opened[2].queueSwitch == nil,
        "false and absent normalize to the same original action")
end
print(("Companion auction Followup: %d checks across thirteen owner profiles."):format(checks))
