-- Actual merchant indexing and shared source-price writer; no native purchases.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local function Read(path)
    local file = assert(io.open(path, "rb")); local source = file:read("*a"); file:close()
    return source:gsub("\r\n", "\n")
end
-- Reuse the event/index fixture without its explicit manual-index request,
-- which would conceal a missing index on the normal merchant-open path.
local source = Read("tests/vendor_slot_identity.lua")
source = source:sub(1, assert(source:find("\nif not stockOnly then", 1, true)) - 1)
local first = assert(source:find('\n    h:event("MERCHANT_SHOW"); h:advance(0.6)', 1, true))
local last = assert(source:find("\n    return h", first, true))
source = source:sub(1, first - 1) .. source:sub(last)
local export = setmetatable({ arg = { "--source", root .. "/Inventory/Restock/Vendor/FluxVendorBuy.lua" } }, { __index = _G })
local Boot = assert(load(source .. "\nreturn boot", "@merchant-source-learning-fixture", "t", export))()

local function Fixture(modern, mode, size)
    local h = Boot(modern, false, size or 8, false)
    local env = h.env
    h.settings = { autoRepair = false, autoSellGray = false, autoRestock = false, restockItems = {} }
    env.FluxRestockSettings.Get = function() return h.settings end
    env.FluxVendorAuto.EnsureSettings = function() return h.settings end
    env.IsShiftKeyDown = function() return h.shift == true end
    env.FluxItemClass = { GetName = function(id) return "Item" .. id end, GetIcon = function(id) return id end }
    h.scans = 0
    if mode == "manual" or mode == "fulfilled" then h.settings.restockItems[100001] = { targetQuantity = 5 }
    elseif mode == "zero" then h.settings.restockItems[100001] = { targetQuantity = 0 }
    elseif mode == "dismissed" then h.settings.restockItems[100001] = { targetQuantity = 5, dismissed = true }
    elseif mode == "flagOnly" then h.settings.restockItems[100001] = { countBank = true }
    elseif mode == "preset" then
        env.FluxNCConsumables = { GetRestockUIItemIDs = function() return { 100001 } end,
            GetPresetRestockTarget = function() return 0 end }
    elseif mode == "reagent" then
        env.FluxRestock.Inv.Spells = { GetReagentItemIDSet = function() return { [100001] = true } end,
            Refresh = function() h.scans = h.scans + 1 end, ScheduleWarm = function() h.scans = h.scans + 1 end }
    elseif mode == "tier" then
        env.FluxRestockTiers = { IsTierEligible = function() return true end,
            GetTarget = function(kind) return kind == "bandage" and 1 or 0 end }
    end
    if mode == "fulfilled" then h.bags[100001] = 5 end
    assert(loadfile(root .. "/Inventory/Restock/Core/FluxRestockList.lua", "t", env))("_FluxUI", {})
    assert(loadfile(root .. "/Inventory/Restock/Auction/FluxAuctionRestockData.lua", "t", env))("_FluxUI", { Flux = {} })
    h.auction = env.FluxAuctionRestock
    h.learning, h.infoReads, h.readsAt = 0, 0, {}
    local record = env.FluxRestockList.RecordMerchantPrices
    env.FluxRestockList.RecordMerchantPrices = function(index)
        h.learning = h.learning + 1
        return record(index)
    end
    local function Info(slot)
        h.infoReads = h.infoReads + 1
        h.readsAt[h.now] = (h.readsAt[h.now] or 0) + 1
        local item = h.shop[slot]
        if not item then return end
        local stock
        if not item.unknown then stock = item.stock == nil and -1 or item.stock end
        return "Item" .. item.id, 1, item.price, item.pack or 1, stock,
            item.purchasable ~= false, true, item.extended == true
    end
    if modern then
        env.GetMerchantItemInfo = nil
        env.C_MerchantFrame = { GetItemInfo = function(slot)
            local name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, hasExtendedCost = Info(slot)
            if name then return { name = name, texture = texture, price = price, stackCount = stackCount,
                numAvailable = numAvailable, isPurchasable = isPurchasable, isUsable = isUsable, hasExtendedCost = hasExtendedCost } end
        end }
    else env.GetMerchantItemInfo = Info end
    return h
end

for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local modern = client == "Retail" or client == "Forever"
    for _, mode in ipairs({ "manual", "fulfilled", "zero", "preset", "reagent", "tier" }) do
        profiles = profiles + 1
        local h = Fixture(modern, mode)
        h.shop[2].stock, h.shop[3].stock = 3, 0
        h.shop[4].unknown, h.shop[5].purchasable, h.shop[6].extended = true, false, true
        h.shop[7].price = 0
        local frames = #h.frames
        h:event("MERCHANT_SHOW"); h:advance(0.6)
        check(h.learning == 1 and h.infoReads == 8, client .. mode .. " normal visit indexes once without explicit manual index")
        check(h.auction.IsVendorItem(100001) and h.auction.VendorPrice(100001) == 5,
            "unlimited purchasable plain-gold stock becomes a reusable vendor source")
        check(not h.auction.IsVendorItem(100002) and not h.auction.IsVendorItem(100003),
            "finite and sold-out limited listings stay auction eligible")
        check(h.settings.merchantSources[100002].limited and h.settings.merchantSources[100002].lastAvailable == 3,
            "limited stock is remembered without being promoted to unlimited")
        check(not h.auction.IsVendorItem(100004) and not h.auction.IsVendorItem(100005) and not h.auction.IsVendorItem(100006),
            "unknown stock, unavailable purchases and extended-cost items do not prove unlimited supply")
        check(h.auction.IsVendorItem(100007) and h.auction.VendorPrice(100007) == 0,
            "free unlimited stock retains its zero-copper unit price")
        check(#h.calls == 0 and not h.settings.autoRestock and not h.settings.autoSellGray and not h.settings.autoRepair,
            "source learning does not buy or enable automation")
        check(h.scans == 0, "merchant learning reads the cached spell-reagent set without scanning the spell book")
        for _ = 1, 30 do h:event("BAG_UPDATE_DELAYED") end
        h:advance(1)
        check(h.learning == 1 and h.infoReads == 8 and #h.frames == frames and #h.calls == 0,
            "settled bag pulses reuse the completed index without scans, frames or purchases")
        h:event("MERCHANT_CLOSED"); h.merchant = false; h:advance(1)
        check(not h.open and #h.calls == 0 and #h.timers == 0, "closing detaches/cancels the existing merchant work")
        check(h.auction.IsVendorItem(100001), "source facts persist after the merchant closes")
    end
    for _, mode in ipairs({ "none", "dismissed", "flagOnly" }) do
        local h = Fixture(modern, mode)
        h:event("MERCHANT_SHOW"); h:advance(1)
        check(h.learning == 0 and h.infoReads == 0 and #h.calls == 0,
            "unconfigured, dismissed or bank-flag-only characters retain the idle merchant path")
        h:event("MERCHANT_CLOSED"); h:advance(1)
        check(#h.timers == 0, "idle close leaves no source-learning loop")
    end
    local h = Fixture(modern, "manual")
    h.shift, h.settings.autoRestock = true, true
    h:event("MERCHANT_SHOW"); h:advance(1)
    check(h.learning == 1 and h.auction.IsVendorItem(100001) and #h.calls == 0,
        "Shift skips configured automation while allowing metadata-only source learning")
    h:event("MERCHANT_CLOSED"); h:advance(1)

    -- A newer unambiguous observation replaces the previous stock kind, while
    -- incomplete metadata cannot erase exact learned source facts.
    h = Fixture(modern, "manual")
    h.auction.VendorCatalog = { Has = function(id) return id == 100001 end,
        Get = function() return 50, "fixture", "catalogue" end }
    local function Observe(stock, price, count, purchasable, extended)
        h.env.FluxRestockList.RecordMerchantPrices({ [100001] = {
            numAvailable = stock, price = price, batchQty = count, unitPrice = price / count,
            isPurchasable = purchasable, hasExtendedCost = extended,
        } })
    end
    Observe(-1, 7, 25, true, false)
    local fact = h.settings.merchantSources[100001]
    local unlimited, price, _, provenance = h.auction.VendorSource(100001)
    local numerator, denominator = h.auction.VendorTerms(100001)
    check(unlimited and price == 7 / 25 and provenance == "merchant" and not fact.limited,
        "verified unlimited stock uses this character's latest exact source price")
    check(numerator == 7 and denominator == 25, "unlimited source retains exact physical invoice terms")
    Observe(3, 11, 25, true, false)
    unlimited, price, _, provenance = h.auction.VendorSource(100001)
    check(fact.limited and not fact.unlimited and fact.lastAvailable == 3,
        "a newer finite stock observation clears the older unlimited flag")
    check(not unlimited and price == nil and provenance == "merchant" and not h.auction.IsVendorItem(100001),
        "latest learned limited supply stays AH eligible despite an unlimited catalogue record")
    for _, unknown in ipairs({ {}, { stock = math.huge }, { stock = 0 / 0 }, { stock = 1.5 },
        { stock = -1, purchasable = false }, { stock = -1, extended = true } }) do
        Observe(unknown.stock, 99, 1, unknown.purchasable, unknown.extended)
        check(fact.limited and not fact.unlimited and fact.lastAvailable == 3 and fact.unitPrice == 7 / 25
            and fact.priceNumerator == 7 and fact.priceDenominator == 25,
            "unknown or unusable metadata preserves prior limited classification and exact learned terms")
    end
    Observe(-1, 13, 5, true, false)
    unlimited, price, _, provenance = h.auction.VendorSource(100001)
    numerator, denominator = h.auction.VendorTerms(100001)
    check(fact.unlimited and not fact.limited and unlimited and price == 13 / 5 and provenance == "merchant",
        "returning to verified unlimited stock clears the older limited flag")
    check(numerator == 13 and denominator == 5, "renewed unlimited observation replaces exact invoice terms coherently")
    Observe(nil, 101, 1, true, false)
    numerator, denominator = h.auction.VendorTerms(100001)
    check(h.auction.HasUnlimitedVendor(100001) and h.auction.VendorPrice(100001) == 13 / 5
        and numerator == 13 and denominator == 5,
        "unknown stock after unlimited observation cannot demote its verified source or overwrite exact terms")

    -- Physical quantities use the merchant's coherent integer invoice terms.
    h = Fixture(modern, "manual")
    local terms = { slot = 1, price = 7, batchQty = 25, unitPrice = 7 / 25, maxStack = 200, numAvailable = -1 }
    local quantity, received = h.fv.ComputeRestockPurchaseQty(25, terms, 7)
    check(quantity == 25 and received == 25, "seven copper affords all twenty-five physical items from exact merchant terms")
    check(h.fv.ComputeRestockPurchaseQty(25, terms, 6) == 21, "six copper still affords only twenty-one of the fractional-price items")
    check(h.fv.ComputeRestockPurchaseQty(10, terms, 7) == 10, "exact affordability preserves the requested shortage cap")
    terms.numAvailable = 9
    check(h.fv.ComputeRestockPurchaseQty(25, terms, 7) == 9, "exact affordability preserves current limited stock")
    terms.numAvailable, terms.maxStack = -1, 8
    check(h.fv.ComputeRestockPurchaseQty(25, terms, 7) == 8, "exact affordability preserves the physical stack cap")
    terms.maxStack = 200
    check(h.fv.ComputeRestockPurchaseQty(25, terms, 7, nil, { money = 6 }) == 21, "multi-buy wallet retains priority over the caller's money")
    terms.unitPrice = 1
    check(h.fv.ComputeRestockPurchaseQty(25, terms, 7) == 7, "incoherent invoice metadata retains the existing scalar unit-price fallback")
    terms.price, terms.batchQty, terms.unitPrice = nil, nil, 7 / 25
    check(h.fv.ComputeRestockPurchaseQty(25, terms, 7) == 24, "untyped memories preserve their existing scalar affordability path")

    -- Large sellers retain the existing sixteen-slot paced index budget.
    h = Fixture(modern, "zero", 48)
    h:event("MERCHANT_SHOW"); h:advance(0.002)
    check(h.fv.IsMerchantIndexBuildPending() and h.infoReads == 0, "large seller enters the existing deferred index path")
    h:advance(1)
    local peak = 0; for _, count in pairs(h.readsAt) do peak = math.max(peak, count) end
    check(h.learning == 1 and h.infoReads == 48 and peak == 16 and #h.calls == 0,
        "large metadata-only seller completes in sixteen-slot slices with no purchase")
    h:event("MERCHANT_CLOSED"); h:advance(1)
end
print(("Auction vendor source learning: %d checks PASS; %d configured client/source profiles; native merchant operation/FPS NOT RUN"):format(checks, profiles))
