-- Native purchase receipts -> the built-in incoming-mail ledger. Never buys.
local _, ns = ...
local Flux, Inv = ns.Flux, ns.Flux.Inventory
local P, Store = {}, Inv.Store
Inv.Builtin.AuctionPurchases = P
local started, commodity, legacyBid, own
local itemBook = {}
local pendingOrder = {}
local completed, completionOrder = {}, {}
local function Now() return GetTime() end
local function Positive(n)
    return not (issecretvalue and issecretvalue(n)) and type(n) == "number" and n > 0 and n < math.huge and n % 1 == 0
end
local function Owned() return not Store.UsesSyndicator() end
local function Commit(receipt)
    if not receipt or receipt.credited or not Owned() or Now() - receipt.at > 20 then return end
    receipt.credited = true -- consume before publication, which can notify listeners
    if receipt.transaction then receipt.transaction.incomingConfirmed = true end
    return Inv.Builtin.Mail.RecordAuctionDelivery(receipt.itemID, receipt.quantity, receipt.link)
end
local function New(id, quantity, link, kind, auctionID)
    if not Positive(id) or not Positive(quantity) then return end
    return { itemID = id, quantity = quantity, link = link, kind = kind, auctionID = auctionID, at = Now() }
end
local function RememberItem(record)
    if not record or not record.auctionID then return end
    local id = record.auctionID
    if not itemBook[id] then
        pendingOrder[#pendingOrder + 1] = id
        if #pendingOrder > 128 then itemBook[table.remove(pendingOrder, 1)] = nil end
    end
    itemBook[id] = record
end

function P.TrackRestock(transaction, offer)
    if not started or not Owned() then return end
    own = New(transaction.itemID, transaction.quantity, offer.link, transaction.kind, transaction.auctionID)
    if own then
        own.transaction = transaction
        if own.kind == "commodity" then commodity = own elseif own.kind == "legacy" then legacyBid = own
        elseif own.auctionID then RememberItem(own) end
    end
end
function P.FinishRestock() own = nil end
function P.AbortRestock(transaction)
    if commodity and commodity.transaction == transaction then commodity = nil end
    if legacyBid and legacyBid.transaction == transaction then legacyBid = nil end
    if transaction and transaction.auctionID then itemBook[transaction.auctionID] = nil end
    own = nil
end
function P.ConsumeFailure(transaction)
    if not Owned() then return false end
    if transaction.incomingFailed then return true end
    if commodity and commodity.transaction == transaction then
        commodity = nil; transaction.incomingFailed = true; return true
    end
    return false
end

local function Receipt(event, id, quantity)
    if not Owned() then commodity, legacyBid, own, itemBook, pendingOrder = nil, nil, nil, {}, {}; return end
    if event == "COMMODITY_PURCHASE_FAILED" then
        if commodity and commodity.transaction then commodity.transaction.incomingFailed = true end
        commodity = nil; return
    end
    if event == "COMMODITY_PURCHASE_SUCCEEDED" then
        local pending = commodity; commodity = nil; Commit(pending)
    elseif event == "COMMODITY_PURCHASED" then
        if commodity and commodity.itemID == id and commodity.quantity == quantity then
            local pending = commodity; commodity = nil; Commit(pending)
        end
    elseif event == "AUCTION_HOUSE_PURCHASE_COMPLETED" then
        if completed[id] then return end
        -- Commodity buys also emit this completion. Only a matching observed
        -- item bid (or our own pre-call context) proves which listing was bought.
        local record = own and own.auctionID == id and own or itemBook[id]
        itemBook[id] = nil
        if record then
            record.at = Now()
            completed[id] = true; completionOrder[#completionOrder + 1] = id
            if #completionOrder > 128 then completed[table.remove(completionOrder, 1)] = nil end
            Commit(record)
        end
    elseif event == "CHAT_MSG_SYSTEM" and id == ERR_AUCTION_BID_PLACED then
        local pending = legacyBid; legacyBid = nil; Commit(pending)
    end
end
function P.Start()
    if started or not Owned() then return end
    started = true
    local cap = Flux.Cap
    local legacy = cap.hasLegacyAuctionHouse == true
    if type(cap.HasLegacyAuctionHouse) == "function" then legacy = cap.HasLegacyAuctionHouse() == true end
    local events = Flux.Events
    if legacy and PlaceAuctionBid then
        -- Observe one whole-stack buyout, not an ordinary bid. No API replacement.
        hooksecurefunc("PlaceAuctionBid", function(list, index, amount)
            if not Owned() then legacyBid = nil; return end
            if own and own.kind == "legacy" and Now() - own.at <= 20 then return end
            local _, _, q, _, _, _, _, _, _, buyout, _, _, _, _, _, _, id = GetAuctionItemInfo(list, index)
            legacyBid = buyout and buyout > 0 and buyout == amount and New(id, q, GetAuctionItemLink(list, index), "legacy") or nil
        end)
        events.Register("CHAT_MSG_SYSTEM", Receipt)
    elseif C_AuctionHouse then
        -- Native post-hooks observe context only, after the original call.
        -- No result-list scan, item-data request, replacement or Start hook.
        hooksecurefunc(C_AuctionHouse, "ConfirmCommoditiesPurchase", function(id, q)
            if not Owned() then commodity = nil; return end
            if own and own.kind == "commodity" and Now() - own.at <= 20 then return end
            commodity = New(id, q, nil, "commodity")
        end)
        if C_AuctionHouse.GetAuctionInfoByID then
            hooksecurefunc(C_AuctionHouse, "PlaceBid", function(id, amount)
                if not Owned() or (own and own.auctionID == id and Now() - own.at <= 20) then return end
                local info = C_AuctionHouse.GetAuctionInfoByID(id)
                if info and info.itemKey and info.buyoutAmount and info.buyoutAmount > 0 and info.buyoutAmount == amount then
                    -- A modern item bid buys one auction; AuctionInfo has no
                    -- physical-quantity field. Search-row quantity is grouped
                    -- availability and cannot be used as the receipt count.
                    RememberItem(New(info.itemKey.itemID, 1, info.itemLink, "item", id))
                end
            end)
        end
        for _, event in ipairs({ "COMMODITY_PURCHASED", "COMMODITY_PURCHASE_SUCCEEDED", "COMMODITY_PURCHASE_FAILED", "AUCTION_HOUSE_PURCHASE_COMPLETED" }) do
            events.Register(event, Receipt)
        end
    end
end
