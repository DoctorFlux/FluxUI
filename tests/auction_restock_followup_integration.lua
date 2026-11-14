-- Actual Followup -> vendor context -> pure target snapshot -> native-owner queue
-- plus actual HUD paint. Cross-owner recursion and stage-wide action regression.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({ FLUX_AH_SOURCES_FIXTURE_EXPORT = true }, { __index = _G })
local sources = assert(loadfile(root .. "/tests/auction_restock_sources.lua", "t", export))()
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    for _, provider in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env, load, book, recipe, scan = sources(client == "Era" or client == "Anniversary", false, provider)
        st.entries = { { itemID = 100, name = "Item100", target = 2 } }
        st.settings.restockItems = { [100] = { targetQuantity = 2 } }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 5 }, [202] = { unlimited = true, unitPrice = 5 } }
        st.settings.autoRestock = false
        recipe(100, 201, 1); st.recipes[1].reagents[2] = { itemID = 202, count = 2 }
        load("Inventory/Restock/Core/FluxRestockList.lua")
        env.FluxRestockItemRegistry.IsChargeItem = function() return false end
        env.FluxRestockItemRegistry.GetChargeInfo = function() return false end
        env.FluxRestockItemRegistry.GetItemMaxCharges = function() return nil end
        st.books = { [100] = book(100, 2, 100) }; scan()
        check(A.craftPlans[100] and A.Settings().vendorCraftPlans[100] and not A.offer,
            "actual AH planner persists a two-ingredient vendor-only craft route")
        A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
        st.settings.restockItems[999] = { targetQuantity = 7 }
        st.inventory.NotifyAutomationPulse = function() end
        env.FluxRestock.Inv.NotifyAutomationPulse = function() end
        env.print = function() end
        env.MerchantFrame = { IsShown = function() return st.merchantOpen == true end }
        local ids = { 201, 202, 999 }
        env.GetMerchantNumItems = function() return #ids end
        env.GetMerchantItemID = function(slot) return ids[slot] end
        env.GetMerchantItemLink = function(slot) return "item:" .. ids[slot] end
        env.GetMerchantItemMaxStack = function() return 20 end
        env.GetMerchantItemInfo = function(slot) return "Item" .. ids[slot], 1, 5, 1, -1, true, true, false end
        env.GetMerchantItemCostInfo = function() return 0 end
        st.vendorBuys = {}
        env.BuyMerchantItem = function(slot, quantity)
            check(not st.combat and st.merchantOpen, "actual vendor command retains its live interaction boundary")
            local id = ids[slot]; st.vendorBuys[id] = (st.vendorBuys[id] or 0) + quantity
            st.bags[id] = (st.bags[id] or 0) + quantity
        end
        load("Inventory/Restock/Auction/FluxAuctionRestockFollowup.lua")
        local F = A.Followup
        F.Resume()
        check(F.GetState() and F.GetState().kind == "vendor" and F.GetVendorTargets()[201] == 2 and F.GetVendorTargets()[202] == 4,
            "actual follow-up restores every exact saved vendor ingredient")
        load("Inventory/Restock/Vendor/FluxVendorBuy.lua")
        -- Extend only the existing desktop widget surface for actual HUD source.
        local m = getmetatable(env.UIParent).__index
        function m:GetSize() return self:GetWidth(), self:GetHeight() end
        function m:SetNormalTexture(value) self.normal = value end
        function m:SetPushedTexture(value) self.pushed = value end
        function m:SetHighlightTexture(value) self.highlight = value end
        function m:SetTextColor(...) self.textColor = { ... } end
        function m:SetShadowColor(...) self.shadowColor = { ... } end
        function m:SetShadowOffset(...) self.shadowOffset = { ... } end
        env.FluxExtraAbilityHost = {}
        st.flux.Cap.HasAtlas = function() return true end
        local effects, starts, stops = {}, 0, 0
        local art = {
            ProcGlow_Start = function(button, options)
                check(button.kind == "Button" and button:IsEnabled() and not effects[button] and options.key == "FluxRestockFollowup"
                    and options.startAnim == false and options.color == nil, "only each actionable item owns the native-colored private proc loop")
                effects[button], starts = true, starts + 1
            end,
            ProcGlow_Stop = function(button, key)
                check(effects[button] and key == "FluxRestockFollowup", "retired or unusable items stop their private proc loop")
                effects[button], stops = nil, stops + 1
            end,
        }
        env.LibStub = function(name) if name == "LibCustomGlow-1.0" then return art end end
        local uiNamespace = { Flux = st.flux }
        assert(loadfile(root .. "/Inventory/Restock/Auction/FluxAuctionRestockLocale.lua", "t", env))("_FluxUI", uiNamespace)
        local uiPath = os.getenv("FLUX_FOLLOWUP_UI_SOURCE") or root .. "/Inventory/Restock/Auction/FluxAuctionRestockFollowupUI.lua"
        assert(loadfile(uiPath, "t", env))("_FluxUI", uiNamespace)
        local nativeRefresh, refreshCalls, depth = F.Refresh, 0, 0
        F.Refresh = function()
            refreshCalls, depth = refreshCalls + 1, depth + 1
            check(depth < 10, "actual context/target/paint chain cannot recursively rebuild the stage")
            nativeRefresh(); depth = depth - 1
        end
        local actualCan, canQueries = env.FluxVendorAuto.CanAuctionFollowup, 0
        env.FluxVendorAuto.CanAuctionFollowup = function() canQueries = canQueries + 1; return actualCan() end
        F.Refresh()
        check(F.frame:IsShown() and F.frame.itemCount == 2 and not F.GetState().contextOpen and not F.GetState().canAct
            and not F.icons[1]:IsEnabled() and not next(effects),
            "actual HUD shows all targets but stays unready while the merchant is closed")
        st.merchantOpen = true; env.FluxVendorAuto.GetMerchantItemIndex(false); st.advance(1); st.emit("MERCHANT_SHOW")
        F.Refresh()
        check(F.GetState().contextOpen and F.GetState().canAct and F.frame:IsShown() and F.icons[1]:IsEnabled() and F.icons[2]:IsEnabled()
            and effects[F.icons[1]] and effects[F.icons[2]] and starts == 2,
            "actual vendor eligibility publishes readiness and enables and lights each usable item button")
        check(F.icons[1].itemID == 201 and F.icons[1].count.text == "2" and F.icons[2].itemID == 202 and F.icons[2].count.text == "4",
            "actual saved two-ingredient plan reaches the sorted HUD with exact physical badges")
        local before = refreshCalls
        for _ = 1, 5 do check(F.IsContextOpen("vendor"), "actual external context query remains ready") end
        check(refreshCalls == before, "vendor readiness queries read the published target snapshot without reentering Refresh")
        local beforeQueries = canQueries
        for _ = 1, 5 do F.Paint(F.GetState()) end
        check(refreshCalls == before and canQueries == beforeQueries and starts == 2,
            "actual HUD paints consume published readiness without querying vendor ownership again")
        st.hardware = true; F.icons[2]:Fire("OnClick"); st.hardware = false; st.advance(1)
        check(st.vendorBuys[201] == 2 and st.vendorBuys[202] == 4 and not st.vendorBuys[999],
            "one actual second-item button press buys every available stage target and no unrelated target")
        check(F.GetState() and F.GetState().kind == "craft" and F.frame:IsShown() and F.frame.itemCount == 1
            and F.icons[1].itemID == 100 and F.icons[1].count.text == "2" and not next(effects) and stops == 2,
            "actual owner completion advances to the output icon and stops the prior item art while its craft owner is unavailable")
        check(not st.calls.quote and not st.calls.buyStack and not st.calls.buyItem and not F.CraftClick,
            "opening, querying, painting and vendor follow-up never invent an auction or craft gesture")
        st.merchantOpen = false; st.emit("MERCHANT_CLOSED")
        check(not F.IsContextOpen("vendor") and st.settings.autoRestock == false,
            "closing the interaction leaves normal icon controls and preserves normal automation settings")
    end
end
print(("Auction restock follow-up integration: %d checks PASS; %d client/provider profiles; native actions/pixels/input/taint NOT RUN"):format(checks, profiles))
