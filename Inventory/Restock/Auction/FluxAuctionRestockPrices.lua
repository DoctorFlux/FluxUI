-- Optional Auctionator price bridge. Historical prices never authorize a buy.
local _, ns = ...
local A = FluxAuctionRestock
local hints, dirty = {}, false
local function Addon()
    local addon = rawget(_G, "Auctionator")
    return type(addon) == "table" and addon or nil
end
local function Field(table, key) return type(table) == "table" and rawget(table, key) or nil end
local function FreshBook(book, id)
    local at = book and A.Number(book.at)
    local age = at and GetTime() - at
    return book and book.itemID == id and age and age >= 0 and age < 30
end
local function UsableOffer(id, offer, commodity)
    if type(offer) ~= "table" or offer.owned or offer.containsAccountItem
        or (offer.itemID ~= nil and offer.itemID ~= id) then return false end
    local quantity = A.Number(offer.quantity)
    if not quantity or quantity < 1 or quantity % 1 ~= 0 then return false end
    if commodity then
        local price, own = A.Number(offer.unitPrice), A.Number(offer.numOwnerItems) or 0
        return price and price > 0 and price % 1 == 0 and own % 1 == 0 and quantity - own >= 1
            and not (offer.containsOwnerItem and own == 0)
    end
    local total = A.Number(offer.total)
    return total and total > 0 and total % 1 == 0 and not offer.containsOwnerItem
end
local function BelowVendor(total, quantity, price, numerator, denominator)
    if numerator and denominator then return total * denominator < numerator * quantity end
    -- Old learned prices have no original batch terms. Divide the auction
    -- invoice too, so equal 7/25 cannot appear cheaper than (7/25)*25 by rounding.
    return total / quantity < price
end

function A.VendorOfferAllowed(id, offer)
    if not A.HasUnlimitedVendor(id) then return true end
    local price = A.VendorPrice(id)
    if not price or price <= 0 or not UsableOffer(id, offer, offer and offer.commodity) then return false end
    local quantity, total = A.Number(offer.quantity), A.Number(offer.total)
    if not total or total <= 0 or total % 1 ~= 0 then return false end
    local numerator, denominator = A.VendorTerms(id)
    return BelowVendor(total, quantity, price, numerator, denominator)
        and (not offer.commodity or BelowVendor(offer.unitPrice, 1, price, numerator, denominator))
end

function A.FilterVendorOffers(id, offers, commodity)
    if not A.HasUnlimitedVendor(id) then return offers end
    local price, filtered = A.VendorPrice(id), {}
    if not price or price <= 0 then return filtered end
    local numerator, denominator = A.VendorTerms(id)
    for _, offer in ipairs(offers or {}) do
        if UsableOffer(id, offer, commodity) and (commodity and BelowVendor(offer.unitPrice, 1, price, numerator, denominator)
            or not commodity and BelowVendor(offer.total, offer.quantity, price, numerator, denominator)) then filtered[#filtered + 1] = offer end
    end
    return filtered
end

function A.HasCheaperVendorBook(id)
    if not A.HasUnlimitedVendor(id) then return false end
    local book = A.priceBooks and A.priceBooks[id]
    return FreshBook(book, id) and #A.FilterVendorOffers(id, book.offers, book.commodity) > 0 or false
end

-- Commodity unit prices are integer copper. Whole auction listings must keep
-- their exact fractional unit comparison through VendorOfferAllowed instead.
function A.CommodityVendorLimit(id, cap)
    if not A.HasUnlimitedVendor(id) then return cap end
    local price = A.VendorPrice(id)
    if not price then return 0 end
    local numerator, denominator = A.VendorTerms(id)
    local maximum = numerator and math.floor((numerator - 1) / denominator) or math.ceil(price) - 1
    return math.min(cap or math.huge, math.max(0, maximum))
end

function A.MarketPrice(id)
    local book = A.priceBooks and A.priceBooks[id]
    if FreshBook(book, id) and book.minPrice then return book.minPrice, "live" end
    local hint = hints[id]
    if hint and GetTime() - hint.at < 30 then return hint.price, "Auctionator" end
    local addon = Addon()
    local api = Field(Field(addon, "API"), "v1")
    local reader = Field(api, "GetAuctionPriceByItemID")
    if type(reader) ~= "function" then return end
    local ok, price = pcall(reader, "_FluxUI", id)
    price = ok and A.Number(price)
    hints[id] = { at = GetTime(), price = price and price > 0 and price or nil }
    return hints[id].price, "Auctionator"
end
function A.LoadMarketHints(rows)
    for _, row in ipairs(rows) do A.MarketPrice(row.itemID) end
end
function A.PublishPriceBook(book)
    if type(book) ~= "table" or not A.Number(book.itemID) or book.itemID <= 0 or book.itemID % 1 ~= 0 then return end
    local lowest, available = nil, 0
    for _, offer in ipairs(book.offers or {}) do
        local quantity = A.Number(offer.quantity)
        local cost = A.Number(book.commodity and offer.unitPrice or offer.total)
        if quantity and quantity > 0 and cost and cost > 0 then
            local unit = book.commodity and cost or cost / quantity
            -- Modern item groups still buy one copy per bid, but their market
            -- availability is the whole group reported by the native search.
            local stock = not book.commodity and A.Number(offer.availableQuantity) or nil
            stock = stock and stock >= 1 and stock % 1 == 0 and stock or quantity
            lowest, available = lowest and math.min(lowest, unit) or unit, available + stock
        end
    end
    book.minPrice, book.available = lowest, available
    A.priceBooks = A.priceBooks or {}
    A.priceBooks[book.itemID] = book
    if not lowest then return end -- do not overwrite a database with missing data
    local addon = Addon()
    local database = Field(addon, "Database")
    local writer = Field(database, "SetPrice")
    if type(writer) ~= "function" then return end
    -- No stable public writer exists in Auctionator345. Isolate its observed
    -- SetPrice contract here; preserve its own history/availability bookkeeping.
    local ok = pcall(writer, database, tostring(book.itemID), math.ceil(lowest), available)
    if ok then dirty = true; hints[book.itemID] = nil end
    A.auctionatorWriteAvailable = ok
end
function A.FlushAuctionatorPrices()
    if not dirty then return end
    dirty = false
    local addon = Addon()
    local bus = Field(addon, "EventBus")
    local source = Field(addon, A.legacy and "Search" or "IncrementalScan")
    local event = Field(Field(source, "Events"), "PricesProcessed")
    if type(bus) == "table" and type(bus.Fire) == "function" and type(event) == "string" then
        pcall(bus.Fire, bus, A, event)
    end
end
