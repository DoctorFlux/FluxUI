-- Typed vendor facts remain separate from live strict AH discount policy.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local fixtureChunk = assert(loadfile(root .. "/tests/auction_restock.lua", "t", export))
if setfenv then setfenv(fixtureChunk, export) end
local fixture = fixtureChunk()
local function Contains(rows, id)
    for _, row in ipairs(rows) do if row.itemID == id then return true end end
    return false
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env = fixture(legacy, auctionator, syndicator)
        local historicalReads = 0
        if auctionator then env.Auctionator = { API = { v1 = {
            GetAuctionPriceByItemID = function(caller, id)
                check(caller == "_FluxUI", "historical API retains caller identity")
                historicalReads = historicalReads + 1; return 1
            end,
            GetVendorPriceByItemID = function() error("untyped optional buy price used as an unlimited-stock fact") end,
        } } } end
        env.TSM_API = { GetCustomPriceValue = function() error("TSM vendorbuy imported as a source fact") end }
        env.GetItemInfo = function() error("sell price used as vendor buy price") end
        st.settings.itemPrices, st.settings.vendorItems = { [102] = 1 }, { [102] = true }
        st.settings.merchantSources = {
            [100] = { unlimited = true, unitPrice = 3 },
            [101] = { limited = true, unitPrice = 1, lastAvailable = 1 },
            [103] = { unlimited = true }, [104] = { unlimited = true, unitPrice = 0 },
            [105] = { unlimited = true, unitPrice = 1.5 }, [106] = { unlimited = true, unitPrice = 3 },
            [107] = { unlimited = true, unitPrice = 5 },
        }
        st.entries = {
            { itemID = 100, name = "Manual", target = 2, restockSource = "manual" },
            { itemID = 101, name = "Limited", target = 1, restockSource = "consumable" },
            { itemID = 102, name = "Unknown", target = 1, restockSource = "spellReagent", isSpellReagent = true },
            { itemID = 103, name = "Unknown buy price", target = 1, restockSource = "consumable" },
            { itemID = 104, name = "Free", target = 1, restockSource = "manual" },
            { itemID = 105, name = "Fractional vendor batch", target = 2, restockSource = "spellReagent" },
            { itemID = 106, name = "Drink", target = 2 },
            { isTierRestock = true, tierKind = "bandage", target = 2 },
        }
        local subclass = env.FluxItemClass.GetSubClassID
        env.FluxItemClass.GetSubClassID = function(id) return id == 106 and 5 or subclass(id) end
        env.FluxConsumableBest = { GetBestRef = function() return { itemID = 107 } end }
        env.FluxRestockTiers = { GetTierCount = function() return 0 end }
        local visible = A.GetRows(true)
        check(#visible == 2 and Contains(visible, 101) and Contains(visible, 102),
            "limited and untyped source items remain eligible while proven unlimited defaults to vendor")
        local hidden = A.GetVendorScanRows()
        check(#hidden == 5 and Contains(hidden, 100) and Contains(hidden, 103) and Contains(hidden, 104)
            and Contains(hidden, 105) and Contains(hidden, 107) and not Contains(hidden, 106),
            "hidden probes retain manual, preset, spell reagent and tier targets but never food/water")
        check(A.HasUnlimitedVendor(100) and not A.HasUnlimitedVendor(101) and not A.HasUnlimitedVendor(102),
            "raw unlimited fact is never inferred from limited stock or remembered untyped prices")
        check(A.VendorPrice(100) == 3 and A.VendorPrice(103) == nil and A.VendorPrice(104) == 0,
            "raw buy price preserves known, unknown and free vendor supplies")
        local history = A.MarketPrice(100)
        check((not auctionator or history == 1) and A.IsVendorItem(100) and not A.HasCheaperVendorBook(100),
            "cheap historical auction hint cannot admit an unlimited vendor item")
        check(not A.HasUnlimitedVendor(102) and A.VendorPrice(102) == nil,
            "optional vendor APIs and native sell price cannot create unlimited buy facts")

        local listings = {
            { itemID = 100, quantity = 2, total = 5 },
            { itemID = 100, quantity = 2, total = 6 },
            { itemID = 100, quantity = 2, total = 7 },
            { itemID = 100, quantity = 1, total = 1, owned = true },
            { itemID = 100, quantity = 1, total = 1, containsAccountItem = true },
            { itemID = 100, quantity = 1, total = 1, containsOwnerItem = true },
            { itemID = 102, quantity = 1, total = 1 },
            { itemID = 100, quantity = 0, total = 1 },
        }
        local filtered = A.FilterVendorOffers(100, listings, false)
        check(#filtered == 1 and filtered[1] == listings[1] and #listings == 8,
            "whole listing fractional unit discount uses exact total multiplication without mutating the book")
        check(A.VendorOfferAllowed(100, listings[1]) and not A.VendorOfferAllowed(100, listings[2]),
            "strictly cheaper stack qualifies while equal vendor unit price does not")
        check(A.FilterVendorOffers(101, listings, false) == listings and A.FilterVendorOffers(102, listings, false) == listings,
            "limited and unknown source filters preserve existing auction handling")
        check(not A.VendorOfferAllowed(103, listings[1]) and not A.VendorOfferAllowed(104, listings[1]),
            "unknown or free vendor buy price never authorizes an AH exception")
        A.SetMaxPrice(100, 0)
        check(A.PurchaseLimit(100) == math.huge and not A.VendorOfferAllowed(100, listings[2])
            and A.VendorOfferAllowed(100, listings[1]), "zero user cap remains unlimited while vendor discount remains strict")
        check(A.CommodityVendorLimit(100, math.huge) == 2 and A.CommodityVendorLimit(105, math.huge) == 1
            and A.CommodityVendorLimit(102, 20) == 20, "only native integer commodity prices use the exclusive integer ceiling")
        local commodity = {
            { itemID = 100, quantity = 5, unitPrice = 2, numOwnerItems = 3 },
            { itemID = 100, quantity = 2, unitPrice = 3 },
            { itemID = 100, quantity = 2, unitPrice = 1, numOwnerItems = 2 },
            { itemID = 100, quantity = 2, unitPrice = 1, containsAccountItem = true },
            { itemID = 100, quantity = 2, unitPrice = 1, owned = true },
            { itemID = 100, quantity = 2, unitPrice = 1.5 },
        }
        filtered = A.FilterVendorOffers(100, commodity, true)
        check(#filtered == 1 and filtered[1] == commodity[1], "commodity exception requires cheap whole copper and available non-owned quantity")
        check(not A.VendorOfferAllowed(100, { commodity = true, quantity = 2, total = 5, unitPrice = 3 })
            and A.VendorOfferAllowed(100, { commodity = true, quantity = 2, total = 4, unitPrice = 2 }),
            "quote highest unit price cannot reach vendor price even when its average would be cheaper")

        A.PublishPriceBook({ itemID = 100, commodity = false, at = st.time, offers = { listings[4] } })
        check(A.IsVendorItem(100), "owned cheap listing cannot qualify through the published book minimum")
        A.PublishPriceBook({ itemID = 100, commodity = true, at = st.time, offers = { commodity[3] } })
        check(A.IsVendorItem(100), "fully owned commodity tier cannot qualify through the published book minimum")
        A.PublishPriceBook({ itemID = 100, commodity = false, at = st.time, offers = { listings[1] } })
        check(not A.IsVendorItem(100) and A.HasUnlimitedVendor(100) and A.VendorPrice(100) == 3
            and Contains(A.GetRows(true), 100), "fresh usable strict discount admits a vendor target without changing its source facts")
        st.time = st.time + 29.99
        check(not A.IsVendorItem(100), "discount remains fresh before thirty seconds")
        st.time = st.time + 0.01
        check(A.IsVendorItem(100) and not Contains(A.GetRows(true), 100), "thirty-second-old opportunity returns to the vendor route")
        A.priceBooks[100] = { itemID = 102, commodity = false, at = st.time, offers = { listings[1] }, minPrice = 1 }
        check(A.IsVendorItem(100), "another item's book cannot admit this target")
        A.priceBooks[100].itemID, A.priceBooks[100].at = 100, st.time + 1
        check(A.IsVendorItem(100), "future-dated book cannot admit this target")
        A.PublishPriceBook({ itemID = 100, commodity = false, at = st.time, offers = {} })
        check(A.IsVendorItem(100), "new empty native result retires a previous discount")

        -- A vendor-chosen recipe input stays out of the AH even when its unit
        -- price is lower there: buying the whole stack costs more than one vial.
        env.FluxConsumableBest, env.FluxRestockTiers = nil, nil
        st.settings.merchantSources[108] = { unlimited = true, unitPrice = 2 }
        st.entries = {
            { itemID = 120, name = "Output", target = 1 },
            { itemID = 108, name = "Vendor input", target = 1, craftBaseTarget = 0, craftTarget = 1,
                restockSource = "craftMaterial" },
            { itemID = 109, name = "Manual base", target = 12, craftBaseTarget = 10, craftTarget = 2,
                restockSource = "manual" },
            { itemID = 110, name = "Preset charge base", target = 11, craftBaseTarget = 9, craftTarget = 2,
                restockSource = "consumable" },
        }
        st.charged, st.charges = 110, 5
        local vendorBook = { itemID = 108, commodity = false, at = st.time,
            offers = { { itemID = 108, quantity = 20, total = 20 } } }
        A.PublishPriceBook(vendorBook)
        A.Settings().allowExcessStacks = true
        A.GetRows(true)
        local plan = A.CompareCraft(A.FindRow(120), {
            { recipeID = 77, name = "Output", yield = 1, required = { [108] = 1 }, legacy = true },
        }, { [108] = vendorBook, [120] = { commodity = false,
            offers = { { itemID = 120, quantity = 1, total = 100 } } } })
        check(plan and plan.vendorItems[108] and plan.vendorCost == 2 and plan.cost == 2,
            "actual recipe invoice chooses one vendor input over twenty cheaper-per-unit auction copies")
        A.craftPlans[120] = plan; A.GetRows(true)
        check(not A.FindRow(108) and not Contains(A.GetVendorScanRows(), 108),
            "pure temporary vendor material never leaks into hidden probes or visible AH purchases")
        check(A.FindRow(109).target == 10 and A.FindRow(110).target == 9 and A.FindRow(110).unitsPerItem == 5,
            "AH copies preserve only manual/preset direct base targets including charge units")
        check(st.entries[2].target == 1 and st.entries[3].target == 12 and st.entries[4].target == 11,
            "normalizing AH targets never mutates the shared vendor/options list")

        -- Bundled source fallback is independent of optional auction addons and
        -- never supersedes this character's typed merchant observations.
        local previousCatalogue = A.VendorCatalog
        local cataloguePrices = { [111] = 10, [112] = 10, [113] = 10, [114] = 10, [115] = 10,
            [116] = 10, [117] = 10, [125] = 0, [126] = -1, [127] = math.huge, [128] = "10" }
        local catalogueReads = {}
        A.VendorCatalog = { Get = function(id)
            catalogueReads[id] = (catalogueReads[id] or 0) + 1
            return cataloguePrices[id], "selected-client", "LibItemDB-v1.9.0"
        end }
        st.settings.merchantSources[112] = { unlimited = true, unitPrice = 7 }
        st.settings.merchantSources[113] = { limited = true, unitPrice = 1 }
        st.settings.merchantSources[114] = { unlimited = true }
        st.settings.merchantSources[115] = { unlimited = true, unitPrice = 0 }
        st.settings.merchantSources[116] = { unitPrice = 2 }
        st.settings.merchantSources[117] = { unlimited = true, limited = true, unitPrice = 8 }
        st.settings.itemPrices[111], st.settings.vendorItems[111] = 1, true
        local unlimited, price, profile, provenance = A.VendorSource(111)
        check(unlimited and price == 10 and profile == "selected-client" and provenance == "LibItemDB-v1.9.0",
            "catalogue fallback supplies canonical price and labelled provenance before a merchant visit")
        check(A.HasUnlimitedVendor(112) and A.VendorPrice(112) == 7 and not catalogueReads[112],
            "learned unlimited buy price overrides a different bundled base price without another lookup")
        check(not A.HasUnlimitedVendor(113) and A.VendorPrice(113) == nil and not catalogueReads[113],
            "learned limited supply overrides bundled unlimited inference")
        check(A.HasUnlimitedVendor(114) and A.VendorPrice(114) == nil and not catalogueReads[114],
            "learned unlimited supply with unknown buy price never invents a catalogue benchmark")
        check(A.HasUnlimitedVendor(115) and A.VendorPrice(115) == 0 and not catalogueReads[115],
            "learned free supply retains zero instead of using a positive bundled price")
        check(A.HasUnlimitedVendor(116) and A.VendorPrice(116) == 10
            and st.settings.merchantSources[116].unitPrice == 2 and st.settings.merchantSources[116].unlimited == nil,
            "untyped price-only merchant memory cannot override catalogue stock or mutate saved facts")
        check(A.HasUnlimitedVendor(117) and A.VendorPrice(117) == 8 and not catalogueReads[117],
            "an explicit unlimited observation remains authoritative when both learned stock flags exist")
        check(not A.HasUnlimitedVendor(125) and not A.HasUnlimitedVendor(126) and not A.HasUnlimitedVendor(127)
            and not A.HasUnlimitedVendor(128) and not A.HasUnlimitedVendor(111.5),
            "catalogue fallback accepts only valid positive numeric prices and item IDs")
        st.entries = { { itemID = 111, name = "Unvisited vendor reagent", target = 1, restockSource = "spellReagent" },
            { itemID = 113, name = "Observed limited herb", target = 1, restockSource = "manual" } }
        visible = A.GetRows(true)
        check(not Contains(visible, 111) and Contains(visible, 113) and Contains(A.GetVendorScanRows(), 111),
            "bundled vendor reagent starts hidden but price-probeable while observed limited stock stays auction eligible")
        check(st.settings.merchantSources[111] == nil and st.settings.itemPrices[111] == 1,
            "catalogue policy never writes historical inference into learned merchant records")
        A.PublishPriceBook({ itemID = 111, commodity = false, at = st.time,
            offers = { { itemID = 111, quantity = 1, total = 9 } } })
        check(not A.IsVendorItem(111) and A.HasUnlimitedVendor(111) and A.VendorPrice(111) == 10,
            "fresh strict AH discount can override the bundled route while preserving catalogue source facts")
        st.settings.merchantSources[111] = { unlimited = true, unitPrice = 8 }
        check(A.IsVendorItem(111) and A.VendorPrice(111) == 8,
            "new learned discount immediately replaces the bundled benchmark for current AH offers")
        A.VendorCatalog = { Get = function() return nil end }
        st.settings.merchantSources[111] = nil
        check(not A.HasUnlimitedVendor(111) and A.VendorPrice(111) == nil
            and A.HasUnlimitedVendor(112) and A.VendorPrice(112) == 7,
            "client without catalogue data has no guessed profile fallback and still uses learned observations")
        local termsReads = {}
        A.VendorCatalog = { profile = "unit-normalized", source = "catalogue-proof",
            Has = function(id) return id == 130 or id == 132 or id == 133 or id == 135 or id >= 140 and id <= 145 end,
            Get = function(id)
                local value = id == 130 and 7 / 25 or id == 132 and 700 / 25 or id == 134 and 3
                    or id == 135 and 0 or id >= 140 and id <= 145 and 9 or nil
                return value, "unit-normalized", "catalogue-proof"
            end,
            GetTerms = function(id)
                termsReads[id] = (termsReads[id] or 0) + 1
                if id == 130 or id == 133 then return 7, 25 end
                if id == 132 then return 700, 25 end
                return 9, 1
            end,
        }
        local numerator, denominator = A.VendorTerms(130)
        check(A.HasUnlimitedVendor(130) and A.VendorPrice(130) == 7 / 25 and numerator == 7 and denominator == 25,
            "catalogue benchmark retains the verified raw buy price and physical-item denominator")
        local exactTie, realDiscount = { itemID = 130, quantity = 25, total = 7 }, { itemID = 130, quantity = 50, total = 8 }
        check(not A.VendorOfferAllowed(130, exactTie) and A.VendorOfferAllowed(130, realDiscount),
            "exact 7/25 invoice tie is rejected while 8/50 is strictly cheaper by rational comparison")
        filtered = A.FilterVendorOffers(130, { exactTie, realDiscount, { itemID = 130, quantity = 1, total = 7 } }, false)
        check(#filtered == 1 and filtered[1] == realDiscount,
            "catalogue batch buy price never becomes an erroneous per-item bargain threshold")
        check(not A.VendorOfferAllowed(132, { itemID = 132, quantity = 25, total = 700 })
            and not A.VendorOfferAllowed(132, { itemID = 132, quantity = 1, total = 28 })
            and A.VendorOfferAllowed(132, { itemID = 132, quantity = 1, total = 27 }),
            "raw batch and normalized unit ties are both rejected without rounding")
        check(not A.VendorOfferAllowed(132, { commodity = true, itemID = 132, quantity = 2, total = 55, unitPrice = 28 })
            and A.VendorOfferAllowed(132, { commodity = true, itemID = 132, quantity = 2, total = 54, unitPrice = 27 }),
            "commodity total and highest unit both use exact vendor batch terms")
        check(A.CommodityVendorLimit(130, math.huge) == 0 and A.CommodityVendorLimit(132, math.huge) == 27,
            "integer commodity ceiling is computed from exact batch terms")
        unlimited, price, profile, provenance = A.VendorSource(133)
        check(unlimited and price == nil and profile == "unit-normalized" and provenance == "catalogue-proof"
            and A.IsVendorItem(133) and A.VendorTerms(133) == nil and not termsReads[133],
            "stock-only catalogue member stays vendor-sourced with unknown price and cannot borrow a denominator")
        check(#A.FilterVendorOffers(133, { { itemID = 133, quantity = 100, total = 1 } }, false) == 0
            and not A.VendorOfferAllowed(133, { itemID = 133, quantity = 100, total = 1 }),
            "even a tiny AH price cannot authorize an unknown-price vendor exception")
        check(not A.HasUnlimitedVendor(134) and A.VendorPrice(134) == nil,
            "explicit catalogue stock absence overrides a stray price-only value")
        check(A.HasUnlimitedVendor(135) and A.VendorPrice(135) == nil,
            "unpriced catalogue zero is not invented as a verified free merchant price")
        st.settings.merchantSources[140] = { unlimited = true, unitPrice = 7 / 25, priceNumerator = 7, priceDenominator = 25 }
        st.settings.merchantSources[141] = { unlimited = true, unitPrice = 7 / 25 }
        st.settings.merchantSources[142] = { unlimited = true, unitPrice = 7 / 25, priceNumerator = 8, priceDenominator = 25 }
        st.settings.merchantSources[143] = { unlimited = true, priceNumerator = 7, priceDenominator = 25 }
        st.settings.merchantSources[144] = { limited = true, unitPrice = 9, priceNumerator = 9, priceDenominator = 1 }
        st.settings.merchantSources[145] = { unlimited = true, unitPrice = 0, priceNumerator = 0, priceDenominator = 25 }
        numerator, denominator = A.VendorTerms(140)
        check(numerator == 7 and denominator == 25 and not termsReads[140]
            and not A.VendorOfferAllowed(140, { itemID = 140, quantity = 25, total = 7 })
            and A.VendorOfferAllowed(140, { itemID = 140, quantity = 50, total = 8 }),
            "learned verified batch terms override catalogue terms and compare exact invoices")
        check(A.VendorTerms(141) == nil and not termsReads[141]
            and not A.VendorOfferAllowed(141, { itemID = 141, quantity = 25, total = 7 })
            and A.VendorOfferAllowed(141, { itemID = 141, quantity = 50, total = 8 }),
            "legacy learned scalar price divides the AH invoice too so a floating multiplication tie cannot look cheaper")
        check(A.VendorTerms(142) == nil and not termsReads[142] and A.VendorPrice(142) == 7 / 25,
            "incoherent learned terms are ignored without replacing the observed scalar or importing catalogue terms")
        check(A.HasUnlimitedVendor(143) and A.VendorPrice(143) == nil and A.VendorTerms(143) == nil and not termsReads[143],
            "learned unknown scalar remains unknown even if stale batch fields exist")
        check(not A.HasUnlimitedVendor(144) and A.VendorTerms(144) == nil and not termsReads[144],
            "learned limited stock never imports catalogue price terms")
        numerator, denominator = A.VendorTerms(145)
        check(numerator == 0 and denominator == 25 and A.VendorPrice(145) == 0
            and not A.VendorOfferAllowed(145, { itemID = 145, quantity = 25, total = 1 }),
            "verified free learned batch remains free and never authorizes a positive AH buy")
        st.entries = { { itemID = 133, name = "Unpriced vendor source", target = 1 } }
        A.PublishPriceBook({ itemID = 133, commodity = false, at = st.time,
            offers = { { itemID = 133, quantity = 100, total = 1 } } })
        check(not A.FindRow(133, true) and Contains(A.GetVendorScanRows(), 133),
            "unpriced known catalogue stock remains hidden after a fresh native price read")
        A.VendorCatalog = previousCatalogue
        check(not st.calls.quote and not st.calls.buyStack and not st.calls.confirm and #st.errors == 0,
            "source and opportunity policy neither buys nor emits Lua errors")
        check(not auctionator or historicalReads > 0, "optional historical hints remain usable without route authority")
    end end
end
print(("Auction vendor opportunity prices: %d checks PASS; %d profiles; native vendor/AH prices/input NOT RUN"):format(checks, profiles))
