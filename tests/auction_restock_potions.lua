-- Real Best.Score/Persist and tier owners with native browse/search transports.
local checks, profiles, context = 0, 0, ""
local function check(value, label) checks = checks + 1; assert(value, label .. " [" .. context .. "]") end
local root = os.getenv("FLUX_AH_ROOT") or "."
local export = setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })
local chunk = assert(loadfile("tests/auction_restock.lua", "t", export)); if setfenv then setfenv(chunk, export) end
local fixture = chunk()
local function boot(legacy, auctionator, syndicator)
    local A, st, env = fixture(legacy, auctionator, syndicator)
    env.Flux = st.flux
    env.wipe = function(table) for key in pairs(table) do table[key] = nil end end
    st.level, st.bankItems, st.generation, st.uncached, st.restricted = 30, {}, 1, {}, { [302] = true }
    st.data = {
        [100] = { name = "Minor Healing Potion", kind = "healPotion", amount = 100, level = 1 },
        [101] = { name = "Minor Mana Potion", kind = "manaPotion", amount = 90, level = 1 },
        [200] = { name = "Greater Healing Potion", kind = "healPotion", amount = 300, level = 20 },
        [201] = { name = "Super Healing Potion", kind = "healPotion", amount = 600, level = 30 },
        [202] = { name = "Future Healing Potion", kind = "healPotion", amount = 900, level = 60 },
        [203] = { name = "Expensive Healing Potion", kind = "healPotion", amount = 800, level = 30 },
        [204] = { name = "Owned Healing Potion", kind = "healPotion", amount = 700, level = 30 },
        [205] = { name = "Vendor Healing Potion", kind = "healPotion", amount = 1000, level = 30 },
        [300] = { name = "Super Mana Potion", kind = "manaPotion", amount = 500, level = 20 },
        [301] = { name = "Expensive Mana Potion", kind = "manaPotion", amount = 700, level = 30 },
        [302] = { name = "Restricted Mana Potion", kind = "manaPotion", amount = 650, level = 30 },
    }
    env.UnitLevel = function() return st.level end
    env.UnitHealthMax = function() return 1000 end
    env.UnitPowerMax = function() return 800 end
    env.FluxIsItemUsable = function(id) return (st.bags[id] or 0) + (st.bankItems[id] or 0) > 0 end
    env.Enum = { AuctionHouseFilter = { UsableOnly = 2 }, AuctionHouseSortOrder = { Name = 1 },
        ItemClass = { Weapon = 2, Armor = 4, Consumable = 0, Miscellaneous = 15 },
        ItemMiscellaneousSubclass = { CompanionPet = 2, Mount = 5 }, ItemWeaponSubclass = { Fishingpole = 20 },
        TooltipDataLineType = { RestrictedRaceClass = 1, RestrictedLevel = 2, RestrictedSkill = 3, RestrictedFaction = 4 } }
    env.C_TooltipInfo = { GetItemByID = function(id)
        return { lines = st.restricted[id] and { { type = 1, leftColor = { r = 1, g = 0, b = 0 } } } or {} }
    end }
    local ic = env.FluxItemClass
    ic.GetInfo = function(id) local row = st.data[id]; if row and not st.uncached[id] then return { name = row.name, minLevel = row.level } end end
    ic.IsLoaded = function(id) return ic.GetInfo(id) ~= nil end
    ic.RequestLoad = function(id) st.loads = (st.loads or 0) + 1 end
    ic.GetClassID = function(id) return st.data[id] and 0 or 7 end
    ic.GetSubClassID = function(id) return st.data[id] and (st.data[id].kind == "bandage" and 7 or 1) or 0 end
    ic.GetName = function(id) return st.data[id] and st.data[id].name or "Item" .. id end
    ic.GetIcon = function(id) return id end
    ic.GetStackSize = function() return 20 end
    ic.GetTooltipText = function() return "" end
    st.itemIDsByName = {}; for id, row in pairs(st.data) do st.itemIDsByName[row.name] = id end
    env.FluxConsumableClassify = { Classify = function(id)
        local row = st.data[id]; if not row or st.uncached[id] then return end
        return { kind = row.kind, effective = row.amount, health = (row.kind == "healPotion" or row.kind == "bandage") and row.amount or 0,
            mana = row.kind == "manaPotion" and row.amount or 0, isConjured = false }
    end, IsRejected = function(id) return st.data[id] == nil end }
    local best = { IsValidKind = function(kind) return kind == "healPotion" or kind == "manaPotion" or kind == "bandage" end,
        IsManaKind = function(kind) return kind == "manaPotion" or kind == "water" end,
        IsManaKindRelevant = function() return true end }
    env.FluxConsumableBest = best
    local function load(path)
        local source = assert(loadfile(root .. "/" .. path, "t", env)); if setfenv then setfenv(source, env) end
        source("_FluxUI", { Flux = st.flux })
    end
    load("Inventory/FluxConsumableBest/Score.lua"); load("Inventory/FluxConsumableBest/Persist.lua")
    best.GetBestRef = best.Persist.GetRef
    best.GetBest = function(kind)
        local found
        for id, n in pairs(st.bags) do
            local row = st.data[id]
            if n > 0 and row and row.kind == kind and best.Score.IsUsable(id, kind) and (not found or row.amount > found.effective) then
                found = { itemID = id, kind = kind, effective = row.amount, count = n }
            end
        end
        return found
    end
    st.flux.Inventory.GetCount = function(id) return st.bags[id] or 0 end
    env.FluxRestock.Inv.GetLiveCount = function(id, opts) return opts.bags == false and (st.bankItems[id] or 0) or (st.bags[id] or 0) end
    env.FluxRestock.Inv.Bags = { GetGeneration = function() return st.generation end,
        GetUniqueItems = function() local result = {}; for id, n in pairs(st.bags) do result[id] = { count = n } end; return result end }
    env.FluxRestock.Inv.Bank = { GetCharacterCounts = function() return st.bankItems end,
        GetCount = function(id) return st.bankItems[id] or 0 end }
    load("Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua")
    load("Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua")
    load("Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua")
    st.settings.junkList = {}
    load("Inventory/Restock/Junk/FluxJunk.lua")
    st.upgradeChoice = true -- Existing buying tests explicitly press each cell's Upgrade control.
    env.FluxRestockTiers.NotifyTierReferenceUIRefresh = function() st.tierUpdates = (st.tierUpdates or 0) + 1; A.SettingsChanged() end
    st.bags[100], st.bags[101] = 19, 19
    best.Persist.MaybeUpdateRef("healPotion", { itemID = 100, effective = 100, source = "owned" })
    best.Persist.MaybeUpdateRef("manaPotion", { itemID = 101, effective = 90, source = "owned" })
    st.entries = { { isTierRestock = true, tierKind = "healPotion", target = 20, name = "Healing" },
        { isTierRestock = true, tierKind = "manaPotion", target = 20, name = "Mana" } }
    st.settings.merchantSources = { [205] = { unlimited = true, unitPrice = 10 } }
    local prices = { [100] = 20, [101] = 20, [200] = 50, [201] = 80, [202] = 10, [203] = 150, [204] = 10,
        [205] = 10, [300] = 70, [301] = 90, [302] = 50 }
    st.books = {}
    for id, price in pairs(prices) do
        st.books[id] = { commodity = not legacy, offers = legacy and { { itemID = id, quantity = 20, total = price * 20, owned = id == 204 } }
            or { { itemID = id, quantity = 20, unitPrice = price, numOwnerItems = id == 204 and 20 or 0 } } }
    end
    st.potionCatalog = {}
    for _, pair in ipairs({ { "healing potion", "healPotion" }, { "mana potion", "manaPotion" } }) do
        local browse, offers = {}, {}
        for id, row in pairs(st.data) do if row.kind == pair[2] then
            browse[#browse + 1] = { itemKey = env.C_AuctionHouse.MakeItemKey(id), totalQuantity = 20, minPrice = prices[id] }
            offers[#offers + 1] = { itemID = id, quantity = 20, total = prices[id] * 20, owned = id == 204 }
        end end
        st.potionCatalog[pair[1]] = { browse = browse, offers = offers }
    end
    A.SetMaxPrice(100, 100); A.SetMaxPrice(101, 80)
    local function Start()
        st.reliable = false; st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.reliable = true
        if legacy then st.press() else st.press(A.frame.refresh) end
        st.drain() -- old AH prepares its next potion; modern supports a full catalogue refresh
    end
    return A, st, env, best, Start
end
local function RealClassifier(st, env)
    local ic = env.FluxItemClass
    ic.GetStatic = function() return { classID = 0, subClassID = 1 } end
    ic.GetTooltipText = function(id)
        local row = st.data[id]; if not row then return "" end
        if st.partialPotion == id and (not st.partialUntil or st.time < st.partialUntil) then return row.name end
        return row.name .. "\nRequires Level " .. row.level .. "\nUse: Restores " .. row.amount .. " to " .. row.amount
            .. (row.kind == "manaPotion" and " mana." or " health.")
    end
    local source = assert(loadfile(root .. "/Inventory/FluxConsumableClassify.lua", "t", env)); if setfenv then setfenv(source, env) end
    source("_FluxUI", {})
    return env.FluxConsumableClassify
end
if FLUX_AH_POTIONS_FIXTURE_EXPORT then return boot end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        context = client .. "/" .. tostring(auctionator) .. "/" .. tostring(syndicator)
        local A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        Start()
        check(best.GetBestRef("healPotion").itemID == 201 and best.GetBestRef("manaPotion").itemID == 300,
            "each independent cell choice updates its persisted reference on either AH generation")
        check(st.settings.restockCombat.savedHealPotionTier == 600 and st.settings.restockCombat.savedManaPotionTier == 500,
            "real saved tier owner updates each accepted potion kind")
        check(A.FindRow(201).need == 20 and not A.FindRow(100) and A.FindRow(300).need == 20 and not A.FindRow(101),
            "nineteen weaker potions do not count toward a discovered stronger target")
        check(A.GetMaxPrice(201) == 100 and A.GetMaxPrice(300) == 80, "upgraded item inherits original slot's configured cap")
        check(not st.searchedIDs[202] and not st.searchedIDs[203] and not st.searchedIDs[205] and not st.searchedIDs[301] and not st.searchedIDs[302],
            "high-level, over-cap, vendor-only and class-restricted potions are not purchase candidates")
        check((legacy or st.searchedIDs[204]) and A.offer and A.offer.itemID == 201, "own-only listing is excluded before buying the strongest valid offer")
        check((st.calls.potionBrowse or st.calls.legacyPotionSearch) == 2 and st.tierUpdates == 2,
            "configured potion choices are gathered together without full old-AH restock pricing or loops")
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack, "discovery and tier promotion never buy automatically")
        st.press()
        if legacy then st.legacyReceipt() else st.emit("COMMODITY_PRICE_UPDATED", 80, 1600); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
        st.drain()
        check(A.Settings().pending[201].units == 20 and A.offer and A.offer.itemID == 300, "one press buys the upgraded heal quantity and prepares upgraded mana")
        check(best.GetBestRef("manaPotion").itemID == 300 and st.settings.restockCombat.savedManaPotionTier == 500
            and A.FindRow(300).need == 20 and not A.FindRow(101) and A.GetMaxPrice(300) == 80,
            "old-AH receipt advances to the stronger usable mana tier and its complete target without a full scan")
        check((st.calls.confirm or st.calls.buyStack) == 1, "next potion kind needs a distinct physical press")

        -- Minimum AH threshold remains strict even with inferior marking disabled.
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        st.settings.restockCombat = { markInferiorHealPotion = false, markInferiorManaPotion = false }
        st.entries[1].countBank = true
        st.bankItems[100], st.bankItems[201], st.bags[100] = 0, 5, 14
        if legacy then st.books[201].offers = { { itemID = 201, quantity = 15, total = 1200 }, { itemID = 201, quantity = 5, total = 400 } } end
        Start()
        check(A.FindRow(201).need == 15 and A.offer.quantity == 15, "only five banked upgraded potions count; weaker bank stock and bags are excluded")
        check(env.FluxRestockTiers.GetBankCountForKind("healPotion", nil, 600, true) == 5, "strict bank option executes the real tier count owner")

        -- Zero targets do not query or promote tiers.
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        st.entries[1].target, st.entries[2].target = 0, 0
        Start()
        check(best.GetBestRef("healPotion").itemID == 100 and not st.calls.potionBrowse and not st.calls.legacyPotionSearch and not A.offer,
            "zero targets skip discovery and leave the saved tier unchanged")
        check(#st.errors == 0, "potion discovery and real reference/tier owners emit no modeled API exceptions")

        -- A no-ref slot still discovers a tier, and limited vendor sightings do not exclude it.
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        best.Persist.GetRoot().refs = {}
        st.settings.merchantSources[203] = { limited = true, unitPrice = 1 }
        Start()
        if legacy then
            check(best.GetBestRef("healPotion").itemID == 203 and best.GetBestRef("manaPotion").itemID == 301
                and st.calls.legacyPotionSearch == 2 and not st.calls.buyStack,
                "empty references gather independent choices before any old-AH whole-stack purchase")
            st.press(); st.legacyReceipt(); st.drain()
        end
        check(best.GetBestRef("healPotion").itemID == 203 and best.GetBestRef("manaPotion").itemID == 301,
            "empty reference slots and limited merchant stock discover offered potion tiers as their turns are prepared")

        -- Native partial results may span browse chunks or legacy pages.
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        local catalog = st.potionCatalog["healing potion"]
        if legacy then
            local first = {}; for i = 1, 50 do first[i] = { itemID = 200, quantity = 20, total = 1000 } end
            catalog.pages, catalog.total = { [0] = first, [1] = catalog.offers }, 50 + #catalog.offers
        else
            catalog.browsePages = { { { itemKey = env.C_AuctionHouse.MakeItemKey(200), totalQuantity = 20, minPrice = 50 } }, catalog.browse }
        end
        Start()
        check(best.GetBestRef("healPotion").itemID == 201 and (legacy and st.calls.legacyPotionSearch == 3 or not legacy and st.calls.moreBrowse == 1),
            "unquoted partial discovery reads every result chunk before choosing strongest tier")

        -- Unresolved metadata must not silently pick a weaker potion.
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        st.uncached[201] = true
        Start()
        check((not A.offer and A.status == "potionData" or A.offer and A.offer.itemID == 300
            and A.PotionRowBlocked(A.FindRow(100))) and not st.calls.quote and not st.calls.buyStack
            and best.GetBestRef("healPotion").itemID == 100,
            "unknown potion metadata blocks that kind without promoting a weaker unverified candidate")
        st.uncached[201] = nil
        if legacy then st.advance(31); st.press() else st.press(A.frame.refresh) end; st.drain()
        check(A.offer and A.offer.itemID == 201 and best.GetBestRef("healPotion").itemID == 201,
            "explicit rescan recovers once item metadata loads")

        -- Losing usability after discovery revokes purchase authorization.
        st.restricted[201] = true
        st.press()
        check(not st.calls.quote and not st.calls.buyStack and not st.calls.confirm,
            "live restriction change prevents buying the previously prepared upgrade")
        if legacy then st.advance(31); st.press() else st.press(A.frame.refresh) end; st.drain()
        if legacy and not best.GetBestRef("healPotion") and A.offer and A.offer.itemID == 300 then
            st.press(); st.legacyReceipt(); st.drain()
        end
        check(best.GetBestRef("healPotion") and best.GetBestRef("healPotion").itemID == 200 and A.GetMaxPrice(200) == 100,
            "scrubbing an unusable ref retains the original cap when choosing a usable replacement")

        -- A close during metadata retries cancels the job and leaves tier state alone.
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        st.uncached[201] = true
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle()
        while A.state == "searching" do st.result() end
        check(A.state == "classifying", "metadata retry uses the existing deferred queue")
        st.emit("AUCTION_HOUSE_CLOSED"); st.uncached[201] = nil; st.advance(20)
        check(best.GetBestRef("healPotion").itemID == 100 and not A.offer and not st.calls.quote,
            "closing auction house cancels metadata work without promotion or purchase")

        -- The real shared parser may have spent its budget on inventory before this tab opens.
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        local classify = RealClassifier(st, env)
        classify.ResetParseBudget(1); classify.Classify(202)
        Start()
        check(best.GetBestRef("healPotion").itemID == 201 and best.GetBestRef("manaPotion").itemID == 300,
            "auction batches renew the real shared parse budget and resolve every usable potion")
        check(A.offer and A.offer.itemID == 201 and not A.HasBlockedPotionTargets(),
            "spent inventory tooltip budget cannot leave discovery waiting or block all potion upgrades")

        -- Name-only classification is useful for bags, but cannot prove an AH restore tier.
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        classify = RealClassifier(st, env)
        st.partialPotion, st.partialUntil = 201, st.time + 1
        Start()
        check(best.GetBestRef("healPotion").itemID == 201 and A.offer and A.offer.itemID == 201,
            "a partial tooltip is retried until its real stronger restore value arrives")
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        classify = RealClassifier(st, env); st.partialPotion = 201
        Start()
        check((A.status == "potionData" and not A.offer or A.offer and A.offer.itemID == 300
            and A.PotionRowBlocked(A.FindRow(100))) and best.GetBestRef("healPotion").itemID == 100,
            "an unresolved name-only restore placeholder never hides a stronger unknown potion")
        A, st, env, best, Start = boot(legacy, auctionator, syndicator)
        classify = RealClassifier(st, env); st.partialPotion = 202
        Start()
        check(best.GetBestRef("healPotion").itemID == 201 and A.offer and A.offer.itemID == 201,
            "a known unusable higher-level potion with a partial tooltip cannot hold a usable upgrade")

        if not legacy then
            -- Native ADDED events carry new rows; GetBrowseResults may retain only the first batch.
            A, st, env, best, Start = boot(legacy, auctionator, syndicator)
            local full = st.potionCatalog["healing potion"].browse
            st.potionCatalog["healing potion"].browsePages = { { { itemKey = env.C_AuctionHouse.MakeItemKey(200), totalQuantity = 20, minPrice = 50 } }, {}, full }
            local get = env.C_AuctionHouse.GetBrowseResults
            env.C_AuctionHouse.GetBrowseResults = function()
                if st.browseTerm == "healing potion" then return st.potionCatalog[st.browseTerm].browsePages[1] end
                return get()
            end
            st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.result()
            st.emit("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", { { itemKey = env.C_AuctionHouse.MakeItemKey(203), totalQuantity = 20, minPrice = 150 } })
            st.emit("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", full)
            st.drain()
            check(best.GetBestRef("healPotion").itemID == 201 and A.offer and A.offer.itemID == 201,
                "native incremental browse payloads find stronger potions beyond the getter's initial batch")
        end
    end end
end
print(("Auction potion upgrades: %d checks PASS; %d profiles; native browse/usability/tier/input NOT RUN"):format(checks, profiles))
