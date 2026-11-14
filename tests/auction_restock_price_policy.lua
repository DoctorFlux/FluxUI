-- Explicit per-item No limit policy using the real editor, queue and planners.
-- Native mouse permission/rendering remain outside this widget/API model.
local checks, profiles, context = 0, 0, ""
local function check(value, label) checks = checks + 1; assert(value, label .. " [" .. context .. "]") end
local root = os.getenv("FLUX_AH_ROOT") or "."
local function exported(path, flag)
    local env = setmetatable({ [flag] = true }, { __index = _G })
    local source = assert(loadfile(root .. "/" .. path, "t", env)); if setfenv then setfenv(source, env) end
    return source()
end
local fixture = exported("tests/auction_restock.lua", "FLUX_AH_FIXTURE_EXPORT")
local sources = exported("tests/auction_restock_sources.lua", "FLUX_AH_SOURCES_FIXTURE_EXPORT")
local potions = exported("tests/auction_restock_potions.lua", "FLUX_AH_POTIONS_FIXTURE_EXPORT")
local function purchaseCalls(st)
    return (st.calls.quote or 0) + (st.calls.confirm or 0) + (st.calls.buyItem or 0) + (st.calls.buyStack or 0)
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1; context = client .. "/" .. tostring(auctionator) .. "/" .. tostring(syndicator)
        local A, st, env = fixture(legacy, auctionator, syndicator)
        A.Settings().maxUnitPrices = { [100] = 123, [101] = 0 }
        check(not A.IsPriceUnlimited(100) and A.PriceLimit(100) == 123,
            "legacy positive price migrates to an enabled limit")
        check(A.IsPriceUnlimited(101) and A.PriceLimit(101) == math.huge and A.IsPriceUnlimited(102),
            "legacy zero and new items default to No limit")
        check(A.Settings().noPriceLimit[100] == false and A.Settings().noPriceLimit[101] == true,
            "migration persists explicit boolean modes without replacing stored copper")
        check(A.SetMaxPrice(100, 0, false) and A.PurchaseLimit(100) == 0 and not A.IsPriceUnlimited(100),
            "explicit limited zero remains a true zero purchase cap")
        check(A.PricePolicyMatches(100, 0, false) and not A.PricePolicyMatches(100, 0, true)
            and not A.PricePolicyMatches(100, 0, nil), "zero mode is part of saved-plan identity")
        A.SetMaxPrice(100, 7, true)
        check(A.GetMaxPrice(100) == 7 and A.PurchaseLimit(100) == math.huge,
            "No limit ignores a retained positive amount")
        A.SetPriceUnlimited(100, false)
        check(A.GetMaxPrice(100) == 7 and A.PurchaseLimit(100) == 7,
            "turning No limit off restores the retained amount")
        check(not A.SetMaxPrice(100, 0, "false") and not A.SetPriceUnlimited(100, 0),
            "nonboolean modes cannot erase a valid price policy")
        A.Settings().maxUnitPrices[103], A.Settings().noPriceLimit[103] = 0, false
        local saved = st.settings.auctionRestock
        local reloaded, reloadState = fixture(legacy, auctionator, syndicator)
        reloadState.settings.auctionRestock = saved
        check(reloaded.PriceLimit(103) == 0 and not reloaded.IsPriceUnlimited(103)
            and reloaded.PriceLimit(100) == 7, "a reloaded character preserves both zero and positive limited modes")

        -- Real dirty-text focus loss must not undo the newly clicked mode.
        st.entries = { { itemID = 100, name = "Target", target = 1 } }; st.bags[100] = 1
        A.SetMaxPrice(100, 0, true); st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        local f, g = A.frame, A.frame.currencyGroup
        check(f.noLimit:GetChecked() and f.noLimit:IsEnabled(), "new item editor exposes checked No limit")
        local owner = legacy and env.AuctionFrame or env.AuctionHouseFrame
        owner:SetSize(504, 360); f:Fire("OnSizeChanged")
        local noLimitRight = f.noLimit.point[2] + f.noLimit:GetWidth() + f.noLimit.Text:GetWidth()
        check(f.layoutWidth == 480 and noLimitRight <= f.excess.point[2]
            and f.excess.point[2] + f.excess:GetWidth() + f.excess.Text:GetWidth() <= f.layoutWidth,
            "minimum-width editor reserves disjoint price-toggle and bounded excess caption regions")
        check(f.noLimit.Text:GetStringWidth() <= f.noLimit.Text:GetWidth() and f.excess.Text:GetHeight() == 28
            and f.scroll.point[3] == -74, "the English toggle fits and excess wrapping retains the grid's original top edge")
        owner:SetSize(1024, 768); f:Fire("OnSizeChanged")
        check(f.layoutWidth == 1000 and f.noLimit.point[2] + f.noLimit:GetWidth() + f.noLimit.Text:GetWidth() <= f.excess.point[2],
            "resizing retains independent native checkbox and label regions")
        g.gold:SetText("0"); g.silver:SetText("1"); g.copper:SetText("25"); g.gold:SetFocus()
        f.noLimit:SetChecked(false); st.press(f.noLimit); st.drain()
        check(not A.IsPriceUnlimited(100) and A.GetMaxPrice(100) == 125 and A.PurchaseLimit(100) == 125
            and not g.gold:HasFocus(), "clicking off commits dirty currency text then keeps the requested limited mode")
        g.copper:SetText("99"); g.copper:SetFocus(); f.noLimit:SetChecked(true); st.press(f.noLimit); st.drain()
        check(A.IsPriceUnlimited(100) and A.GetMaxPrice(100) == 199 and A.PurchaseLimit(100) == math.huge,
            "clicking on after dirty focus loss keeps No limit and the edited amount")
        f.noLimit:SetChecked(false); st.press(f.noLimit); st.drain()
        g.gold:SetText("0"); g.silver:SetText("0"); g.copper:SetText("0"); g.copper:SetFocus(); g.copper:Fire("OnEnterPressed")
        check(not A.IsPriceUnlimited(100) and A.PurchaseLimit(100) == 0
            and f.cells[1].limit.text:find("0|T", 1, true), "editing all-zero currency retains an explicit zero and displays zero copper")
        A.transaction = {}; A.UpdateUI(); f.noLimit:SetChecked(true); f.noLimit:Fire("OnClick")
        check(not f.noLimit:IsEnabled() and not A.IsPriceUnlimited(100), "a stale disabled toggle cannot alter an in-flight purchase policy")
        A.transaction = nil; local state = A.state; A.state = "quoting"; A.UpdateUI()
        f.noLimit:SetChecked(true); f.noLimit:Fire("OnClick")
        check(not f.noLimit:IsEnabled() and not A.IsPriceUnlimited(100), "a stale quoting toggle cannot alter the pending quote policy")
        A.state = state
        check(f.clearPending == nil and purchaseCalls(st) == 0, "the editor offers no Clear pending control and never buys")

        local load, book, recipe, scan
        A, st, env, load, book, recipe, scan = sources(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 2 } }; st.books = { [100] = book(100, 2, 5) }
        A.SetMaxPrice(100, 0, false); scan(); st.press()
        check(not A.offer and purchaseCalls(st) == 0 and A.PurchaseLimit(100) == 0,
            "limited-zero direct targets cannot prepare or buy a paid commodity or legacy stack")
        A.SetMaxPrice(100, 1, true); st.drain()
        check(A.offer and A.offer.itemID == 100 and A.offer.total == 10 and A.GetMaxPrice(100) == 1,
            "No limit prepares a real offer above the retained finite amount")
        if not legacy then
            st.press(); check(A.state == "quoting" and st.calls.quote == 1, "one hardware press alone opens a commodity intent")
            A.Settings().maxUnitPrices[100], A.Settings().noPriceLimit[100] = 0, false
            st.emit("COMMODITY_PRICE_UPDATED", 5, 10)
            check(not st.calls.confirm and not A.intent, "a new explicit zero revokes an existing unlimited commodity intent")
            A, st, env, load, book, recipe, scan = sources(legacy, auctionator, syndicator)
            st.entries = { { itemID = 100, target = 2 } }
            st.books = { [100] = { commodity = false, offers = {
                { itemKey = env.C_AuctionHouse.MakeItemKey(100), auctionID = 700, quantity = 2, buyoutAmount = 5 },
            } } }
            A.SetMaxPrice(100, 0, false); scan(); st.press()
            check(not A.offer and not st.calls.buyItem, "limited zero also rejects grouped modern noncommodity auctions")
            A.SetPriceUnlimited(100, true); st.drain(); st.press()
            check(st.calls.buyItem == 1 and A.transaction.quantity == 1,
                "No limit restores a single native grouped-item bid per hardware press")
        end

        -- Finished and input caps independently constrain both auction and vendor routes.
        A, st, env, load, book, recipe, scan = sources(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 1 } }; recipe(100, 200, 1)
        st.books = { [100] = book(100, 1, 100), [200] = book(200, 1, 5) }
        A.SetMaxPrice(100, 0, false); scan()
        check(not A.craftPlans[100] and not A.offer, "zero output cap rejects a paid material route and paid finished item")
        A.SetPriceUnlimited(100, true); st.drain()
        check(A.craftPlans[100] and A.FindRow(200) and A.PurchaseLimit(200) == 5,
            "unlimited output can select its cheaper material route")
        A.Settings().maxUnitPrices[200], A.Settings().noPriceLimit[200] = 0, false
        check(A.MaterialLimit(200) == 0 and A.PurchaseLimit(200) == 0,
            "explicit zero input cap clamps a previously derived positive recipe limit")
        A.PrepareNext(); st.drain(); st.press()
        check(purchaseCalls(st) == 0, "a stale derived limit cannot buy an ingredient after its explicit zero cap")
        A.ResetCraftPlans(); A.ScanQueue(); st.drain()
        check(not A.craftPlans[100] and A.offer and A.offer.itemID == 100,
            "an input zero cap permits the independently unlimited finished-item route")

        A, st, env, load, book, recipe, scan = sources(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 1 } }; recipe(100, 201, 1)
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 5 } }
        st.books = { [100] = book(100, 1, 100) }
        A.SetMaxPrice(201, 0, false); scan()
        check(A.craftPlans[100] and A.craftPlans[100].vendorCost == 5 and A.GetVendorCraftTargets(st.entries)[201].need == 1,
            "an ingredient AH zero cap preserves a vendor alternative inside the finished-item budget")
        A.SetMaxPrice(100, 0, false); st.drain()
        check(not A.craftPlans[100] and not A.offer and not next(A.GetVendorCraftTargets(st.entries)),
            "a zero finished-item cap rejects a paid vendor ingredient invoice")
        st.bags[201] = 1; A.ScanQueue(); st.drain()
        check(A.craftPlans[100] and A.craftPlans[100].cost == 0,
            "owned vendor ingredients can still craft for free under zero output and ingredient caps")
        A.SetPriceUnlimited(100, true); st.bags[201] = 0; st.drain(); A.ScanQueue(); st.drain()
        check(A.craftPlans[100] and A.craftPlans[100].cost == 5 and A.Settings().vendorCraftPlans[100].capUnlimited == true,
            "paid vendor source saves the output's unlimited mode explicitly")
        A.Settings().noPriceLimit[100] = false
        check(not next(A.GetVendorCraftTargets(st.entries)), "saved zero/unlimited vendor plans cannot survive changing to zero/limited")

        A, st, env, load, book, recipe, scan = sources(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, target = 2 } }
        st.settings.merchantSources = { [100] = { unlimited = true, unitPrice = 10 } }
        st.books = { [100] = book(100, 2, 5) }; A.SetMaxPrice(100, 0, false); scan(); st.press()
        check(A.HasCheaperVendorBook(100) and not A.offer and purchaseCalls(st) == 0,
            "a strict vendor bargain still cannot bypass an explicit zero AH limit")
        A.SetMaxPrice(100, 1, true); st.drain()
        check(A.offer and A.offer.itemID == 100 and A.offer.total == 10,
            "No limit restores the bargain while retaining its lower ignored amount")

        A, st, env, _, scan = potions(legacy, auctionator, syndicator)
        A.SetMaxPrice(100, 0, false); A.SetMaxPrice(101, 0, false); scan()
        check(env.FluxConsumableBest.GetBestRef("healPotion").itemID == 100
            and env.FluxConsumableBest.GetBestRef("manaPotion").itemID == 101 and not A.offer,
            "zero-limited healing and mana targets cannot discover or buy a paid stronger tier")
        check((not st.searchedIDs or not st.searchedIDs[201] and not st.searchedIDs[300]) and purchaseCalls(st) == 0,
            "discovery's inherited zero prevents live candidate searches and buying")
        A, st, env, _, scan = potions(legacy, auctionator, syndicator)
        A.SetMaxPrice(100, 1, true); A.SetMaxPrice(101, 1, true); scan()
        if legacy then
            check(env.FluxConsumableBest.GetBestRef("healPotion").itemID == 203
                and env.FluxConsumableBest.GetBestRef("manaPotion").itemID == 301,
                "old AH gathers both cell choices under their inherited No limit mode")
            check(A.GetMaxPrice(203) == 1 and A.IsPriceUnlimited(203) and purchaseCalls(st) == 0,
                "legacy healing preparation inherits the ignored finite cap without buying automatically")
            st.press()
            check(purchaseCalls(st) == 1 and st.calls.buyStack == 1,
                "one legacy player press buys exactly one upgraded healing listing")
            st.legacyReceipt(); st.drain()
            check(purchaseCalls(st) == 1 and A.offer and A.offer.itemID == 301,
                "the healing receipt prepares the upgraded mana listing without a second purchase")
        end
        check(env.FluxConsumableBest.GetBestRef("healPotion").itemID == 203
            and env.FluxConsumableBest.GetBestRef("manaPotion").itemID == 301,
            "No limit discovers the strongest usable tiers above retained finite caps")
        check(A.GetMaxPrice(203) == 1 and A.GetMaxPrice(301) == 1 and A.IsPriceUnlimited(203) and A.IsPriceUnlimited(301),
            "upgrades inherit both retained copper and explicit unlimited mode")
    end end
end
print(("Auction explicit price policy: %d checks PASS; %d profiles; native input/rendering NOT RUN"):format(checks, profiles))
