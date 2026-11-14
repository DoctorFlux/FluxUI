-- Real target math, with per-call work counts and mutable source/receipt facts.
-- No cached inventory across publications and no native purchase permission claim.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local function Export(path, flag)
    local env = setmetatable({ [flag] = true }, { __index = _G })
    return assert(loadfile(root .. "/" .. path, "t", env))()
end
local fixture = Export("tests/auction_restock.lua", "FLUX_AH_FIXTURE_EXPORT")
local sources = Export("tests/auction_restock_sources.lua", "FLUX_AH_SOURCES_FIXTURE_EXPORT")
local potions = Export("tests/auction_restock_potions.lua", "FLUX_AH_POTIONS_FIXTURE_EXPORT")
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env = fixture(legacy, auctionator, syndicator)
        st.entries = {}
        for id = 100, 179 do
            st.entries[#st.entries + 1] = { itemID = id, name = "Item" .. id, target = 10 }
            st.bags[id], st.mail[id] = id % 4, id % 3
        end
        local work, need, count, mail = { need = 0, bags = 0, mail = 0 }, A.Need,
            env.FluxRestock.Inv.GetLiveCount, st.inventory.Mail.GetCount
        A.Need = function(row) work.need = work.need + 1; return need(row) end
        env.FluxRestock.Inv.GetLiveCount = function(...) work.bags = work.bags + 1; return count(...) end
        st.inventory.Mail.GetCount = function(...) work.mail = work.mail + 1; return mail(...) end
        local rows = A.GetRows(true)
        check(#rows == 80 and work.need == 80 and work.bags == 80 and work.mail == 80,
            "an ordinary eighty-item refresh computes each final deficit once and reads its mail once")
        for _, row in ipairs(rows) do
            check(row.need == 10 - st.bags[row.itemID] - st.mail[row.itemID]
                and row.pending == st.mail[row.itemID] and row.mailCount == st.mail[row.itemID],
                "reduced reads preserve every live target and mailbox quantity")
        end
        st.bags[100], st.mail[101] = 10, 3
        A.GetRows(true)
        check(A.FindRow(100).need == 0 and A.FindRow(101).need == 6
            and work.need == 160 and work.bags == 160 and work.mail == 160,
            "another publication recomputes every target from current sources without a cross-call cache")
        check(not st.calls.search and not st.calls.legacySearch and not st.calls.quote and not st.calls.buyStack,
            "assembling restock rows never queries or buys an auction")

        -- A reusable row must never turn the single-call mail local into stale state.
        A, st, env = fixture(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, name = "Pending", target = 10 } }
        st.bags[100], st.mail[100] = 2, 1
        local row = A.GetRows(true)[1]
        check(row.need == 7 and row.pending == 1, "baseline stock remains physical")
        local units = A.Reserve(row, 2); A.AcceptReservation({ itemID = 100 })
        check(units == 2 and A.Need(row) == 5 and row.pending == 3, "acknowledged reservation is included once")
        st.mail[100] = 3
        check(A.Need(row) == 5 and row.mailCount == 3 and row.pending == 3 and not A.Settings().pending[100],
            "new authoritative mail retires its receipt once even when the caller reuses its row")
        st.bags[100], st.mail[100] = 5, 0
        check(A.Need(row) == 5 and row.mailCount == 0 and row.pending == 0,
            "collecting the same mail preserves total stock without phantom pending")

        -- Charge conversion and bank usage still precede the one final stock calculation.
        A, st, env = fixture(legacy, auctionator, syndicator)
        st.charged, st.charges, st.uses = 100, 5, { [100] = 2 }
        env.FluxRestock.Inv.GetLiveCount = function(id, opts) return opts.charges and st.uses[id] or st.bags[id] or 0 end
        st.entries = { { itemID = 100, name = "Oil", target = 9, countBank = false, bankCount = 3 } }
        st.bags[100], st.mail[100] = 1, 1
        row = A.GetRows(true)[1]
        check(row.isCharge and row.unitsPerItem == 5 and row.bagCount == 2 and row.mailCount == 5 and row.need == 1,
            "a partially used oil and one mailed physical oil retain their exact use deficit")
        st.entries[1].countBank = true
        check(A.GetRows(true)[1].need == 0, "configured bank uses can satisfy the rounded charge target")

        -- Merge every tier source before counting the shared physical SKU.
        A, st, env = fixture(legacy, auctionator, syndicator)
        env.FluxConsumableBest = { GetBestRef = function() return { itemID = 100 } end }
        env.FluxRestockTiers = { GetTierCount = function() return 7 end, GetBankCountForKind = function() return 2 end }
        st.entries = { { itemID = 100, name = "Shared", target = 10, countBank = true, bankCount = 3 },
            { isTierRestock = true, tierKind = "healPotion", target = 12, countBank = true } }
        st.bags[100] = 4
        rows = A.GetRows(true); row = rows[1]
        check(#rows == 1 and #row.tiers == 1 and row.need == 3 and row.bagCount == 4,
            "ordinary and tier targets merge with their distinct bank and qualifying-tier counts")

        -- The shared vendor split still receives complete final needs.
        A, st, env = fixture(legacy, auctionator, syndicator)
        st.entries = { { itemID = 201, name = "Vendor", target = 9 } }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 5 } }
        st.bags[201], st.mail[201] = 3, 2
        check(#A.GetRows(true) == 0 and A.GetVendorScanRows()[1].need == 4,
            "a hidden vendor row keeps its exact shortage for discount probing")

        local best
        A, st, env, best = potions(legacy, auctionator, syndicator)
        best.Persist.MaybeUpdateRef("healPotion", { itemID = 201, effective = 600, source = "auction" })
        row = A.FindRow(201, true)
        check(row and row.auctionTier == 600 and row.need == 20,
            "upgraded potion tier counts the full stronger target rather than weaker owned stock")
        st.bags[201] = 1
        check(A.FindRow(201, true).need == 19, "the selected stronger potion receives fresh owned counts")

        local load, book, recipe, scan
        A, st, env, load, book, recipe, scan = sources(legacy, auctionator, syndicator)
        st.entries = { { itemID = 100, name = "Output", target = 3 } }
        st.bags[100], st.bags[200] = 1, 1
        recipe(100, 200, 2)
        st.books = { [100] = book(100, 2, 100), [200] = book(200, 3, 5) }
        scan()
        row = A.FindRow(200)
        check(A.craftPlans[100] and row and row.target == 4 and row.need == 3
            and row.craftParents[100] and A.offer and A.offer.itemID == 200 and A.offer.quantity == 3,
            "material construction still receives final parent needs and prices the exact missing ingredients")
        check(not st.calls.quote and not st.calls.buyStack, "planning this material route cannot spend")
    end end
end
print(("Auction restock data work: %d checks PASS; %d profiles; native latency/CPU/FPS NOT RUN"):format(checks, profiles))
