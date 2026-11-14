-- Actual selected recipe, CoreList, Followup and execution-owner boundaries.
-- A rejected mover/native vendor invoice cannot become an accepted batch.
local export = setmetatable({ FLUX_AH_SOURCES_FIXTURE_EXPORT = true }, { __index = _G })
local boot = assert(loadfile("tests/auction_restock_sources.lua", "t", export))()
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function Owner(legacy, provider, kind)
    local A, st, env, load, book, recipe, scan = boot(legacy, false, provider == "ready")
    env.print = function() end
    st.settings.autoBankRestock, st.settings.autoRestock = false, false
    st.settings.restockItems = { [100] = { targetQuantity = 1 }, [201] = { targetQuantity = 0, countBank = kind == "bank" } }
    st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 5 } }
    st.entries = { { itemID = 100, target = 1, name = "Recipe100", countBank = false } }
    st.bankItems[201] = kind == "bank" and 1 or 0
    recipe(100, 201, 1); st.books = { [100] = book(100, 1, 100) }; scan()
    check(A.Settings().vendorCraftPlans[100], "actual learned recipe selects a persistent owner invoice")
    A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
    check(A.Settings().vendorCraftPlans[100], "selected owner invoice survives closing the auction house")
    load("Inventory/Restock/Core/FluxRestockList.lua")
    env.FluxRestockItemRegistry.IsChargeItem = function() return false end
    env.FluxRestockItemRegistry.GetChargeInfo = function() return false end
    check(A.Settings().vendorCraftPlans[100], "selected owner invoice survives loading the existing target owner")
    load("Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua")
    local F = A.Followup
    st.inventory.GetBagGeneration = function() return st.generation or 0 end
    if kind == "bank" then
        load("Inventory/Restock/Bank/FluxBankRestockRules.lua")
        env.FLUX_API = env.FLUX_API or {}; env.FLUX_API.HasUnifiedBankUI = function() return true end
        env.C_Timer.After = function(delay, fn) return env.C_Timer.NewTimer(delay, fn) end
        env.FluxBankRestockMoveExec = { Start = function(session, opts)
            st.attempts = (st.attempts or 0) + 1
            st.session, st.onDone = session, opts.onDone
            return st.accept == true
        end }
        local create = env.CreateFrame
        env.CreateFrame = function(...) local f = create(...); f.UnregisterAllEvents = function() end; return f end
        load("Inventory/Restock/Bank/FluxBankRestock.lua")
    else
        env.MerchantFrame = { IsShown = function() return true end }
        env.GetMerchantNumItems = function() return 1 end
        env.GetMerchantItemID = function() return 201 end
        env.GetMerchantItemLink = function() return "item:201" end
        env.GetMerchantItemMaxStack = function() return 20 end
        st.price = 5
        env.GetMerchantItemInfo = function() return "Item201", 1, st.price, 1, -1, true, true, false end
        env.GetMerchantItemCostInfo = function() return 0 end
        env.FluxRestock.Inv.NotifyAutomationPulse, st.inventory.NotifyAutomationPulse = function() end, function() end
        env.BuyMerchantItem = function(_, quantity) st.buys = (st.buys or 0) + quantity end
        load("Inventory/Restock/Vendor/FluxVendorBuy.lua")
        env.FluxVendorAuto.GetMerchantItemIndex(true); st.advance(.1)
    end
    check(A.Settings().vendorCraftPlans[100], "selected owner invoice survives loading its bank/vendor execution owner")
    local selected = A.Settings().vendorCraftPlans[100]
    check(A.SavedRecipeKnowledge(selected, 100) == true and A.CraftBankFlagsMatch(selected),
        "selected owner invoice retains verified recipe and bank policy")
    local targets = env.FluxVendorAuto.GetRestockTargetItems({ forOptionsPanel = true })
    local source
    for _, entry in ipairs(targets) do if entry.itemID == 100 then source = entry end end
    check(source and source.target == selected.target and (source.countBank == true) == selected.countBank,
        "published owner target matches the saved selected recipe: " .. tostring(source and source.target) .. "/" .. tostring(selected.target))
    F.Resume()
    if kind == "vendor" then st.emit("MERCHANT_SHOW"); st.advance(.6) end
    check(F.GetState() and F.GetState().kind == kind and F.GetState().items[201] == 1,
        "actual saved recipe resumes the exact pending owner stage: " .. kind .. "/" .. tostring(F.GetState() and F.GetState().kind))
    return A, st, env, F
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "ready" }) do
        profiles = profiles + 1
        local A, st, env, F = Owner(legacy, provider, "bank")
        F.SetAutoEnabled(true)
        check(not st.attempts and not F.GetState().canAct, "deferred bank acceptance waits once for the unified bank layout")
        st.advance(.1); F.Refresh()
        check(st.attempts == 1 and not env.FluxBankRestock.IsRunning(), "actual mover refusal ends the bank session without a native transfer")
        F.Refresh(); st.advance(.1)
        check(st.attempts == 1, "unchanged facts do not loop a rejected deferred bank start")
        F.Click(); st.advance(.1)
        check(st.attempts == 2, "a fresh manual bank click can retry a deferred zero-move refusal")
        st.accept, st.generation = true, 1; F.Refresh(); st.advance(.1)
        check(st.attempts == 3 and env.FluxBankRestock.IsRunning() and not F.GetState().canAct,
            "changed inventory facts retry a rejected bank start and retain the accepted running session")
        F.Click(); F.Refresh(); st.advance(.1)
        check(st.attempts == 3, "accepted in-flight bank work cannot duplicate before bag publication")
        env.FluxBankRestock.Stop(); st.bags[201], st.bankItems[201] = 1, 0; F.Refresh()
        check(F.GetState().kind == "craft" and not st.settings.autoBankRestock,
            "fulfilled bank material advances without changing global automation")

        A, st, env, F = Owner(legacy, provider, "bank")
        env.FLUX_API.HasUnifiedBankUI = function() return false end
        F.SetAutoEnabled(true); F.Click()
        check(st.attempts == 2, "synchronous zero-command bank refusal cannot be overwritten by accepted submission")

        A, st, env, F = Owner(legacy, provider, "bank")
        F.SetAutoEnabled(true)
        local executor = env.FluxBankRestockMoveExec; env.FluxBankRestockMoveExec = nil
        st.advance(.1); env.FluxBankRestockMoveExec = executor
        F.Click(); st.advance(.1)
        check(st.attempts == 1, "early deferred bank refusal before session creation releases only its accepted request")

        A, st, env, F = Owner(legacy, provider, "bank")
        st.accept = true; F.SetAutoEnabled(true); st.advance(.1)
        check(st.attempts == 1 and env.FluxBankRestock.IsRunning(), "actual bank start retains a deferred active executor")
        st.onDone("cursor_stuck"); F.Click(); st.advance(.1)
        check(st.attempts == 2, "zero-command terminal bank failure permits a fresh player retry")
        st.session.followupIssued = true
        st.onDone("cursor_stuck"); F.Click(); F.Refresh(); st.advance(.1)
        check(st.attempts == 2 and not F.GetState().canAct,
            "a terminal bank session with an issued possibly-unacknowledged transfer remains guarded")

        A, st, env, F = Owner(legacy, provider, "vendor")
        st.price = 6; F.Click()
        check(not st.buys and not env.FluxVendorAuto.IsRestockBuyActive(),
            "a fresh live vendor invoice above the saved price issues no native purchase")
        st.price = 5; env.FluxVendorAuto.InvalidateMerchantIndex(); env.FluxVendorAuto.GetMerchantItemIndex(true); st.advance(.1)
        F.Refresh(); F.Click()
        check(st.buys == 1, "a fresh manual vendor click retries a zero-command price refusal after the price returns")
        F.Refresh(); F.Click()
        check(st.buys == 1 and not F.GetState().canAct,
            "an issued vendor purchase retains its accepted latch while bag publication is pending")
        st.bags[201] = 1; F.Refresh()
        check(F.GetState().kind == "craft" and not st.settings.autoRestock,
            "published vendor material advances without changing global automation")

        A, st, env, F = Owner(legacy, provider, "vendor")
        st.price = 6; F.SetAutoEnabled(true)
        check(not st.buys, "independent automation rejects a live six-copper invoice from its cached five-copper index")
        env.FluxVendorAuto.InvalidateMerchantIndex(); env.FluxVendorAuto.GetMerchantItemIndex(true); st.advance(.1)
        F.Refresh()
        check(not st.buys and not F.GetState().contextOpen,
            "the rebuilt six-copper invoice stays nonactionable without repeated native attempts")
        st.price = 5; env.FluxVendorAuto.InvalidateMerchantIndex(); env.FluxVendorAuto.GetMerchantItemIndex(true); st.advance(.1)
        F.Refresh()
        check(st.buys == 1, "restored five-copper vendor invoice retries automatically without bag money or free-space changes")
        env.FluxVendorAuto.InvalidateMerchantIndex(); env.FluxVendorAuto.GetMerchantItemIndex(true); st.advance(.1)
        F.Refresh(); F.Click()
        check(st.buys == 1, "unchanged vendor index rebuilds cannot repeat an issued purchase before publication")
    end
end
print(("Auction owner rejection: %d checks PASS; %d client/provider profiles; native permissions/moves NOT RUN"):format(checks, profiles))
