-- Automatic price planning; each player press authorizes one transaction only.
local _, ns = ...
local Flux = ns.Flux
local Events, A = Flux.Events, FluxAuctionRestock
local Number = A.Number
local timer, serial = nil, 0
local issuing, hooksInstalled, listening = false, false, false
local nativeBooks, lastNative, queryGeneration = {}, nil, 0
local potionScans = {}
local rejectedQuotes = {}
local skipTransientPaint = {}
local logistics, lastLogistics, Listen
local lastFollowupOffer, lastFollowupBusy = nil, false
local bookScan
local BOOK_ITEM_LIMIT, BOOK_PAGE_LIMIT, BOOK_ROW_LIMIT, BOOK_SCAN_SECONDS = 24, 12, 600, 60
local attemptID = 0
A.state, A.status = "idle", "intro"
A.debugBuild = "AH-restock-explicit-start-20261114-r27"

local function Now() return GetTime() end
local function Paint()
    if A.UpdateUI then A.UpdateUI() end
    local followup = A.Followup
    if not followup or not followup.Refresh then return end
    local offer = A.GetFollowupOffer()
    local busy = A.transaction ~= nil or A.ownsQuote == true or A.state == "quoting"
    if lastFollowupOffer == offer and lastFollowupBusy == busy then return end
    lastFollowupOffer, lastFollowupBusy = offer, busy
    followup.Refresh()
end
local function PlainBool(value)
    if issecretvalue and issecretvalue(value) then return "restricted" end
    return type(value) == "boolean" and tostring(value) or "unknown"
end
local function RememberAttempt(phase, row, offer)
    local button = A.frame and A.frame.primary
    local frameAllowed = "unknown"
    if button and C_RestrictedActions and C_RestrictedActions.CheckAllowProtectedFunctions then
        local ok, allowed = pcall(C_RestrictedActions.CheckAllowProtectedFunctions, button, true)
        if ok then frameAllowed = PlainBool(allowed) end
    end
    A.lastAttempt = { phase = phase, itemID = row.itemID, quantity = offer.quantity,
        buttonEnabled = button and button.IsEnabled and PlainBool(button:IsEnabled()) or "unknown",
        frameFunctions = frameAllowed, secureExecution = issecure and PlainBool(issecure()) or "unknown" }
end
function A.PrintStatus()
    local emit = Flux.Print or print
    emit(("Auction restock %s: mode=%s open=%s active=%s state=%s reliable=%s selected=%s"):format(
        A.debugBuild, A.legacy and "legacy" or "modern", tostring(A.houseOpen), tostring(A.active), A.state,
        tostring(A.IsReliable()), tostring(A.selectedID)))
    local catalog = A.VendorCatalog
    if catalog then emit(("Vendor catalogue: profile=%s rows=%s"):format(tostring(catalog.profile), tostring(catalog.count))) end
    local search = A.search
    if search then
        emit(("Search: phase=%s term=%s results=%s page=%s expires=%.1fs"):format(
            search.potionBrowse and "potions" or "item", search.potionBrowse and tostring(search.terms[search.termIndex]) or tostring(search.itemID),
            tostring(search.browseCount or 0), tostring(search.page or 0), math.max(0, search.deadline - Now())))
        emit(("Query: waiting=%s sent=%s categoryFallback=%s nativeReady=%s"):format(tostring(search.waiting == true),
            tostring(search.nativeGeneration ~= nil), tostring(search.categoryFallback == true),
            tostring(A.legacy or not C_AuctionHouse.IsThrottledMessageSystemReady or C_AuctionHouse.IsThrottledMessageSystemReady())))
    end
    local attempt = A.lastAttempt
    if attempt then
        emit(("Last %s: item=%s quantity=%s buttonEnabled=%s frameFunctions=%s secureExecution=%s blocked=%s"):format(
            attempt.phase, tostring(attempt.itemID), tostring(attempt.quantity), attempt.buttonEnabled,
            attempt.frameFunctions, attempt.secureExecution, tostring(attempt.blocked)))
    end
end
local function Active()
    return A.active or logistics ~= nil or bookScan ~= nil
end
local function PositiveInteger(value)
    return Number(value) and value > 0 and value % 1 == 0
end
local function SameLogistics(request, entry, quantity)
    return request and type(entry) == "table" and request.quantity == quantity
        and request.entry.itemID == entry.itemID and request.entry.jobId == entry.jobId
        and request.entry.id == entry.id and request.entry.planRevision == entry.planRevision
        and request.entry.groupRevision == entry.groupRevision
        and request.entry.kind == entry.kind and request.entry.quantity == entry.quantity
        and request.entry.actorKey == entry.actorKey and request.entry.minQuantity == entry.minQuantity
        and request.entry.maxUnitPrice == entry.maxUnitPrice and request.entry.maxTotalPrice == entry.maxTotalPrice
        and request.entry.stackSize == entry.stackSize and request.entry.stackMaxTotalPrice == entry.stackMaxTotalPrice
end
function A.GetLogisticsState(entry, quantity)
    if SameLogistics(logistics, entry, quantity) then
        if A.state ~= "ready" then return A.state end
        local offer = A.offer
        local age = offer and Now() - offer.at
        if age and age >= 0 and age < 30 then
            return "ready", nil, { quantity = offer.quantity, totalCopper = offer.total }
        end
        return nil, "expired"
    end
    if SameLogistics(lastLogistics, entry, quantity) then return nil, lastLogistics.reason end
end
function A.GetLogisticsRow()
    return logistics and logistics.row
end
local function NotifyLogisticsState(request, phase, reason)
    local entry = request.entry
    request.observe("state", { phase = phase, reason = reason, jobId = entry.jobId, id = entry.id,
        planRevision = entry.planRevision, groupRevision = entry.groupRevision,
        itemID = entry.itemID, quantity = request.quantity })
end
local function FinishLogistics(reason, submitted)
    if not logistics then return end
    local request = logistics
    lastLogistics = { entry = request.entry, quantity = request.quantity, reason = reason }
    logistics = nil
    if not A.active then Listen(false) end
    if not submitted then NotifyLogisticsState(request, "idle", reason) end
end
local function FinishBookScan(reason)
    local scan = bookScan
    if not scan then return end
    bookScan = nil
    A.selectedID = scan.selectedID
    if not reason then A.state, A.status = "idle", scan.status end
    if not A.active then Listen(false) end
    Paint()
    local ok, err = pcall(scan.callback, scan.books, reason or scan.reason)
    if not ok and geterrorhandler then geterrorhandler()(err) end
end
local function Authorized(request, quantity, total)
    if not request or not PositiveInteger(quantity) or quantity > request.quantity then return false end
    local entry = request.entry
    if entry.minQuantity and quantity < entry.minQuantity then return false end
    if total and (not PositiveInteger(total) or total > entry.maxUnitPrice * quantity
        or entry.maxTotalPrice and total > entry.maxTotalPrice
        or entry.stackSize and quantity ~= entry.stackSize
        or entry.stackMaxTotalPrice and total > entry.stackMaxTotalPrice) then return false end
    return request.authorize(request.entry, quantity, total) == true
end
local function CancelTimer()
    if timer then timer:Cancel(); timer = nil end
end
local function Later(delay, fn)
    CancelTimer()
    local token = serial
    timer = C_Timer.NewTimer(delay, function()
        timer = nil
        if serial == token then fn() end
    end)
end
A.Defer = Later

local function Call(fn, ...)
    issuing = true
    -- Do not hide protected-operation errors. The reservation survives an error.
    -- Restore ownership even when a native call throws.
    local ok, result = pcall(fn, ...)
    issuing = false
    if not ok then
        if A.transaction then A.transaction.uncertain = true end
        A.status = "uncertain"
        Paint()
        local handler = geterrorhandler and geterrorhandler()
        if handler then handler(result) end
    end
    return ok
end

local function CancelQuote()
    if not A.ownsQuote then return end
    A.ownsQuote = false
    if not A.transaction and C_AuctionHouse and C_AuctionHouse.CancelCommoditiesPurchase then
        Call(C_AuctionHouse.CancelCommoditiesPurchase)
    end
end

function A.Invalidate(reason, paintMode)
    if A.transaction then
        -- A submitted purchase must retain its reservation until its outcome is known.
        Paint()
        return
    end
    local scanningBooks = bookScan ~= nil
    serial = serial + 1
    if reason == "intro" or reason == "combat" or reason == "otherSearch" or reason == "blocked" then
        nativeBooks, lastNative = {}, nil
        rejectedQuotes = {}
    end
    issuing = false
    if reason ~= "searching" then
        A.queue, A.intent = nil, nil
        if A.CancelCraftPricing then A.CancelCraftPricing() end
        if A.CancelPotionDiscovery then A.CancelPotionDiscovery() end
    end
    CancelTimer()
    CancelQuote()
    A.search, A.offer = nil, nil
    A.state, A.status = "idle", reason or "changed"
    if reason ~= "searching" then FinishLogistics(A.status) end
    if reason ~= "searching" and not scanningBooks and A.FlushAuctionatorPrices then A.FlushAuctionatorPrices() end
    if reason ~= "searching" and scanningBooks then FinishBookScan(A.houseOpen and A.status or "openAH")
    elseif paintMode ~= skipTransientPaint then Paint() end
end

local invalidate = A.Invalidate
local function InvalidateForSearch()
    -- Both search starters paint their complete state before sending a query.
    if A.Invalidate == invalidate and A.UpdateUI == ns.AuctionRestockUpdateUI
        and not A.transaction and not A.ownsQuote then
        invalidate("searching", skipTransientPaint)
    else
        A.Invalidate("searching")
    end
end

local getRows, hasCraftPlans = A.GetRows, A.HasCraftPlans
local auctionSettings = A.Settings
local flushPrices, cancelCraftPricing, cancelPotionDiscovery = A.FlushAuctionatorPrices, A.CancelCraftPricing, A.CancelPotionDiscovery
local vendor = _G.FluxVendorAuto
local getTargetItems = vendor and vendor.GetRestockTargetItems

local function StartupInventory()
    local inv = Flux.Inventory
    if not inv or not inv.GetSnapshotGeneration or not inv.GetBagGeneration or not inv.IsBankOpen
        or not inv.IsMailboxOpen or not inv.IsMerchantOpen or not inv.IsBagStorm
        or inv.IsBankOpen() or inv.IsMailboxOpen() or inv.IsMerchantOpen() or inv.IsBagStorm() then return end
    return inv
end

local function StartupOwnersMatch()
    return A.Invalidate == invalidate and A.GetRows == getRows and A.HasCraftPlans == hasCraftPlans
        and A.Settings == auctionSettings
        and A.FlushAuctionatorPrices == flushPrices and not _G.Auctionator
        and A.CancelCraftPricing == cancelCraftPricing and A.CancelPotionDiscovery == cancelPotionDiscovery
        and A.UpdateUI and A.UpdateUI == ns.AuctionRestockUpdateUI
        and A.ApplyPotionReplacements and A.ApplyPotionReplacements == ns.AuctionRestockApplyPotionReplacements
        and vendor and _G.FluxVendorAuto == vendor and vendor.GetRestockTargetItems == getTargetItems
end

local function CaptureStartup()
    if not StartupOwnersMatch() or A.queue or A.intent or A.search or A.offer or A.ownsQuote or A.transaction
        or not hasCraftPlans or hasCraftPlans() or not A.Followup or not A.Followup.HasWork
        or A.Followup.HasWork() then return end
    local inv = StartupInventory()
    if inv then
        return { inventory = inv, bags = inv.GetBagGeneration(), bank = inv.GetSnapshotGeneration("bank"),
            warband = inv.GetSnapshotGeneration("warband"), mail = inv.GetSnapshotGeneration("mail"), at = time(), serial = serial }
    end
end

local function ReuseStartupRows(startup)
    if not startup or not startup.rows or A.rows ~= startup.rows or A.vendorScanRows ~= startup.vendorRows
        or serial ~= startup.serial + 1 or time() ~= startup.at or not StartupOwnersMatch() then return end
    local inv = StartupInventory()
    if inv ~= startup.inventory or inv.GetBagGeneration() ~= startup.bags or inv.GetSnapshotGeneration("bank") ~= startup.bank
        or inv.GetSnapshotGeneration("warband") ~= startup.warband or inv.GetSnapshotGeneration("mail") ~= startup.mail
        or not A.Followup or not A.Followup.HasWork or A.Followup.HasWork() then return end
    for _, row in ipairs(startup.rows) do
        if row.need == nil or row.isCharge then return end
    end
    for _, row in ipairs(startup.vendorRows or {}) do
        if row.need == nil or row.isCharge then return end
    end
    return startup.rows
end

local function ReleaseFinishedForeignQuote()
    local foreign = A.foreign
    if not foreign or foreign.kind ~= "quote" or not foreign.finished or A.transaction then return end
    local getRemaining = C_AuctionHouse and C_AuctionHouse.GetQuoteDurationRemaining
    local remaining = getRemaining and Number(getRemaining())
    if remaining and remaining <= 0 and A.foreign == foreign then A.foreign = nil end
end

local function ForeignCall(purchase)
    if issuing or not A.houseOpen then return end
    nativeBooks, lastNative = {}, nil
    rejectedQuotes = {}
    if purchase == "cancel" then A.foreign = nil end
    if A.transaction then
        if purchase then A.transaction.uncertain = true end
        return
    end
    if not Active() then return end
    A.yielded = true
    -- A foreign quote now belongs to its caller. Never cancel it during cleanup.
    A.ownsQuote = false
    A.Invalidate("otherSearch")
end

local function InstallHooks()
    if hooksInstalled or not hooksecurefunc then return end
    hooksInstalled = true
    if A.legacy then
        hooksecurefunc("QueryAuctionItems", function() ForeignCall(false) end)
        if SortAuctionItems then hooksecurefunc("SortAuctionItems", function() ForeignCall(false) end) end
    else
        local ah = C_AuctionHouse
        for _, name in ipairs({ "SendSearchQuery", "SendBrowseQuery", "SendSellSearchQuery",
            "QueryAuctionsByItemKey", "RefreshCommoditySearchResults", "RefreshItemSearchResults",
            "RequestMoreCommoditySearchResults", "RequestMoreItemSearchResults" }) do
            if type(ah[name]) == "function" then hooksecurefunc(ah, name, function() ForeignCall(false) end) end
        end
        -- Restricted money/quote entry points must remain native and unhooked.
        if type(ah.RequestMoreBrowseResults) == "function" then hooksecurefunc(ah, "RequestMoreBrowseResults", function() ForeignCall(false) end) end
        -- Only observe the unrestricted cancellation and read-only query APIs.
        if type(ah.CancelCommoditiesPurchase) == "function" then
            hooksecurefunc(ah, "CancelCommoditiesPurchase", function() ForeignCall("cancel") end)
        end
    end
end

function A.IsLegacy()
    if type(Flux.Cap.HasLegacyAuctionHouse) == "function" then
        return Flux.Cap.HasLegacyAuctionHouse() == true
    end
    return Flux.Cap.hasLegacyAuctionHouse == true
end

function A.Select(id)
    if A.transaction then return end
    -- Cell selection edits preferences only; it never changes the shopping queue.
    A.editorID = id
    Paint()
end

local function Eligible(id)
    if logistics then
        if logistics.entry.itemID == id and Authorized(logistics, logistics.quantity) then
            return logistics.row, nil, logistics.quantity
        end
        return nil, "changed"
    end
    local row = A.FindRow(id, true)
    if not row or A.IsVendorItem(id) then return nil, "changed" end
    local need = A.Need(row)
    if not need then return nil, "loading" end
    if need <= 0 then return nil, "enough" end
    return row, nil, need
end

local function SearchLimit(id)
    if logistics and logistics.entry.itemID == id then return logistics.entry.maxUnitPrice end
    return A.PurchaseLimit(id)
end
local function AllowExcess(row)
    return not logistics and A.AllowExcessStacks(row)
end
local function OffersFor(id, offers, commodity)
    -- An accepted craft already compared the required quantity against the
    -- full vendor bundle. Keep the exact accepted purchase limits.
    local useAcceptedLimits = logistics and logistics.entry.itemID == id
    return A.FilterVendorOffers and A.FilterVendorOffers(id, offers, commodity, useAcceptedLimits) or offers
end
local function CommodityFor(id, offers, need, cap)
    local entry = logistics and logistics.entry
    local minimum = entry and entry.minQuantity
    return A.CommodityOffer(OffersFor(id, offers, true), need, cap, minimum,
        minimum and entry.maxTotalPrice)
end
local function ListingsFor(id, offers)
    offers = OffersFor(id, offers, false)
    local entry = logistics and logistics.entry
    if not entry then return offers end
    local cap = math.min(entry.maxTotalPrice or math.huge, entry.stackMaxTotalPrice or math.huge)
    if not entry.stackSize and not entry.minQuantity and cap == math.huge then return offers end
    local eligible = {}
    for _, offer in ipairs(offers) do
        if (not entry.minQuantity or PositiveInteger(offer.quantity) and offer.quantity >= entry.minQuantity)
            and (not entry.stackSize or offer.quantity == entry.stackSize)
            and PositiveInteger(offer.total) and offer.total <= cap then
            eligible[#eligible + 1] = offer
        end
    end
    return eligible
end
local function VendorAllowed(id, offer)
    return logistics and logistics.entry.itemID == id or not A.VendorOfferAllowed or A.VendorOfferAllowed(id, offer)
end

local function Ready(offer)
    CancelTimer()
    local row, reason, need = Eligible(A.selectedID)
    if not row then A.Invalidate(reason); return end
    if offer.quantity > need and not AllowExcess(row) then A.Invalidate("changed"); return end
    if offer.total > SearchLimit(row.itemID) * offer.quantity then A.Invalidate("overCap"); return end
    if logistics and not Authorized(logistics, offer.quantity, offer.total) then A.Invalidate("overCap"); return end
    if not VendorAllowed(row.itemID, offer) then A.Invalidate("overCap"); return end
    A.offer, A.state, A.status = offer, "ready", "offer"
    offer.at, offer.itemID = Now(), row.itemID
    if A.Followup and A.Followup.Refresh and A.GetFollowupOffer() then
        Later(30, function() if A.offer == offer then Paint() end end)
    end
    Paint()
    if logistics then NotifyLogisticsState(logistics, "ready") end
end

local function LegacyOffer(index)
    local name, _, quantity, _, _, _, _, _, _, buyout, _, highBidder, _, owner, fullOwner,
        _, id, complete = GetAuctionItemInfo("list", index)
    local link = GetAuctionItemLink("list", index)
    if not Number(id) and type(link) == "string" then id = tonumber(link:match("item:(%d+)")) end
    if not name or complete == false or not owner or owner == "" or not Number(id) then return end
    local player, realm = UnitFullName("player")
    local own = owner == player or (fullOwner and realm and fullOwner == player .. "-" .. realm)
    return { index = index, itemID = id, quantity = quantity, total = buyout,
        owned = own or highBidder == true, owner = fullOwner or owner, link = link }
end

local SendSearch, ReadPotionBrowse
local function SearchRow(search)
    if search.probe then return search.row, nil, search.row.target end
    return Eligible(search.itemID)
end
local function FinishProbe(offers, commodity, complete, reason)
    local search = A.search
    if not search or not search.probe then return end
    CancelTimer()
    serial = serial + 1
    A.search, A.offer, A.state = nil, nil, "idle"
    local book = { itemID = search.itemID, offers = offers, commodity = commodity, at = Now() }
    if search.bookScan then
        search.probe(book, complete ~= false, reason)
        return
    end
    if A.PublishPriceBook then A.PublishPriceBook(book) end
    nativeBooks[search.itemID] = { book = book, generation = search.nativeGeneration, page = search.page, key = search.key }
    search.probe(book)
end
local function ReadLegacy()
    local search = A.search
    if not search or A.state ~= "searching" then return end
    if not search.nativeGeneration or search.nativeGeneration ~= queryGeneration then return end
    if search.potionBrowse then ReadPotionBrowse(); return end
    CancelTimer()
    local row, reason, need = SearchRow(search)
    if not row then A.Invalidate(reason); return end
    local count, total = GetNumAuctionItems("list")
    if search.bookScan and (not Number(count) or not Number(total) or count % 1 ~= 0 or total % 1 ~= 0) then
        FinishProbe(search.book or {}, false, false, "incomplete")
        return
    end
    count, total = Number(count) or 0, Number(total) or 0
    local offers = {}
    local rows = search.bookScan and math.min(count, 50) or count
    for index = 1, rows do
        local offer = LegacyOffer(index)
        if offer and offer.itemID == search.itemID then offer.page = search.page; offers[#offers + 1] = offer end
        if search.bookScan and not offer then search.missingRows = true end
    end
    if search.probe then
        search.book = search.book or {}
        for _, offer in ipairs(offers) do search.book[#search.book + 1] = offer end
        if search.bookScan and count > rows then
            FinishProbe(search.book, false, false, "limit")
            return
        end
        if (search.page + 1) * 50 < total then
            if search.bookScan and search.page + 1 >= BOOK_PAGE_LIMIT then
                FinishProbe(search.book, false, false, "limit")
                return
            end
            search.page, search.deadline = search.page + 1, Now() + 15
            SendSearch()
        else FinishProbe(search.book, false, not search.missingRows, search.missingRows and "incomplete" or nil) end
        return
    end
    offers = ListingsFor(row.itemID, offers)
    local fit = A.SelectStack(offers, need, SearchLimit(row.itemID), false)
    if fit then Ready(fit); return end
    local excess = AllowExcess(row) and A.SelectStack(offers, need, SearchLimit(row.itemID), true)
    if excess and (not search.excess or excess.quantity < search.excess.quantity
        or (excess.quantity == search.excess.quantity and excess.total < search.excess.total)) then
        excess.page = search.page
        search.excess = excess
    end
    if search.returning then
        if excess then Ready(excess) else A.Invalidate("noOffer") end
    elseif (search.page + 1) * 50 < total then
        search.page = search.page + 1
        search.deadline = Now() + 15
        SendSearch()
    elseif search.excess then
        if search.page == search.excess.page then Ready(search.excess)
        else
            search.page, search.returning = search.excess.page, true
            search.deadline = Now() + 15
            SendSearch()
        end
    else A.Invalidate("noOffer") end
end

local function SameKey(a, b)
    return a and b and a.itemID == b.itemID and (a.itemLevel or 0) == (b.itemLevel or 0)
        and (a.itemSuffix or 0) == (b.itemSuffix or 0)
        and (a.battlePetSpeciesID or 0) == (b.battlePetSpeciesID or 0)
end

local function CommodityResults(itemID, limit)
    local ah, offers = C_AuctionHouse, {}
    local missing
    local count = ah.GetNumCommoditySearchResults(itemID)
    local rows = count
    if limit then
        rows = Number(count)
        if not rows then return offers end
        rows = math.min(rows, limit)
    end
    for i = 1, rows do
        local info = ah.GetCommoditySearchResultInfo(itemID, i)
        if info and info.itemID == itemID then offers[#offers + 1] = info end
        if limit and (not info or info.itemID ~= itemID) then missing = true end
    end
    return offers, count, missing
end

local function FinishIncompleteProbe(search, offers, commodity, count, full, requestMore, missing)
    if not search.bookScan then return false end
    if not count or count % 1 ~= 0 or type(full) ~= "boolean"
        or not full and type(requestMore) ~= "function" or full and missing then
        FinishProbe(offers, commodity, false, "incomplete")
        return true
    end
    if count > BOOK_ROW_LIMIT or not full and search.requests >= BOOK_PAGE_LIMIT then
        FinishProbe(offers, commodity, false, "limit")
        return true
    end
    return false
end

local function RetryUnwitnessedLogisticsResult(search, count, full)
    local hasResults = C_AuctionHouse.HasSearchResults
    if not logistics or search.more or not hasResults
        or (hasResults(search.key) and (full ~= false or count ~= 0)) then return false end
    if search.retriedUnwitnessed then
        A.Invalidate("loading")
    else
        -- A matching update can arrive before results for this key exist.
        search.retriedUnwitnessed, search.nativeGeneration = true, nil
        Later(0.3, SendSearch)
    end
    return true
end

local function ReadModern(event, key)
    local search = A.search
    if not search or A.state ~= "searching" then return end
    if not search.nativeGeneration or search.nativeGeneration ~= queryGeneration then return end
    if search.potionBrowse then
        if event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
            ReadPotionBrowse(event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" and key or nil)
        end
        return
    end
    local commodity = event:find("COMMODITY", 1, true) ~= nil
    if commodity and key ~= search.itemID then return end
    if not commodity and not SameKey(key, search.key) then return end
    local row, reason, need = SearchRow(search)
    if not row then A.Invalidate(reason); return end
    CancelTimer()
    local ah, offers = C_AuctionHouse, {}
    local function More(count)
        if search.moreAtCount == count then
            Later(math.max(0, search.deadline - Now()), function() A.Invalidate("timeout") end)
            return
        end
        search.moreAtCount, search.more = count, commodity and "commodity" or "item"
        search.deadline = Now() + 15
        SendSearch()
    end
    if commodity then
        local count, missing
        offers, count, missing = CommodityResults(search.itemID, search.bookScan and BOOK_ROW_LIMIT)
        if search.probe then
            local full = ah.HasFullCommoditySearchResults and ah.HasFullCommoditySearchResults(search.itemID)
            if FinishIncompleteProbe(search, offers, true, Number(count), full, ah.RequestMoreCommoditySearchResults, missing) then return end
            if full == false then More(count)
            else FinishProbe(offers, true) end
            return
        end
        local full = ah.HasFullCommoditySearchResults and ah.HasFullCommoditySearchResults(search.itemID)
        if RetryUnwitnessedLogisticsResult(search, count, full) then return end
        if logistics and (logistics.entry.stackSize or logistics.entry.stackMaxTotalPrice) then
            A.Invalidate("changed")
            return
        end
        local offer = CommodityFor(row.itemID, offers, need, SearchLimit(row.itemID))
        if (not offer or offer.quantity < need) and full == false and ah.RequestMoreCommoditySearchResults then
            More(count); return
        end
        if offer then Ready(offer) else A.Invalidate("noOffer") end
    else
        local count = ah.GetNumItemSearchResults(search.key)
        local rows = count
        local missing
        if search.bookScan then rows = math.min(Number(count) or 0, BOOK_ROW_LIMIT) end
        for i = 1, rows do
            local info = ah.GetItemSearchResultInfo(search.key, i)
            local available = info and Number(info.quantity)
            if info and Number(info.auctionID) and info.auctionID > 0 and SameKey(info.itemKey, search.key)
                and available and available >= 1 and available % 1 == 0 then
                -- Non-commodity rows group available auctions. PlaceBid buys
                -- one physical item at this buyout, not the group's quantity.
                offers[#offers + 1] = { auctionID = info.auctionID, quantity = 1,
                    availableQuantity = available, modernItemGroup = true,
                    total = info.buyoutAmount, owned = info.containsOwnerItem or info.containsAccountItem,
                    link = info.itemLink }
            elseif search.bookScan then missing = true end
        end
        if search.probe then
            local full = ah.HasFullItemSearchResults and ah.HasFullItemSearchResults(search.key)
            if FinishIncompleteProbe(search, offers, false, Number(count), full, ah.RequestMoreItemSearchResults, missing) then return end
            if full == false then More(count)
            else FinishProbe(offers, false) end
            return
        end
        local full = ah.HasFullItemSearchResults and ah.HasFullItemSearchResults(search.key)
        if RetryUnwitnessedLogisticsResult(search, count, full) then return end
        local offer = A.SelectStack(ListingsFor(row.itemID, offers), need, SearchLimit(row.itemID), AllowExcess(row))
        if not offer and full == false
            and ah.RequestMoreItemSearchResults then More(count); return end
        if offer then Ready(offer) else A.Invalidate("noOffer") end
    end
end

local function MarkBrowseKinds(search, entry)
    if search.categoryFallback then entry.allUpgradeKinds = true; return end
    local kind = search.termKinds and search.termKinds[search.terms[search.termIndex]]
    if kind then
        entry.upgradeKinds = entry.upgradeKinds or {}; entry.upgradeKinds[kind] = true
    else entry.allUpgradeKinds = true end
end
ReadPotionBrowse = function(addedResults)
    local search = A.search
    if not search or not search.potionBrowse or A.state ~= "searching" or search.waiting then return end
    CancelTimer()
    local count, total
    if A.legacy then
        count, total = GetNumAuctionItems("list")
        for i = 1, count do
            local offer = LegacyOffer(i)
            if offer and not offer.owned and Number(offer.total) and offer.total > 0 and Number(offer.quantity) and offer.quantity > 0 then
                local id = offer.itemID
                local entry = search.catalog[id] or { itemID = id, minPrice = math.huge, offers = {} }
                MarkBrowseKinds(search, entry)
                entry.minPrice = math.min(entry.minPrice, offer.total / offer.quantity)
                entry.offers[#entry.offers + 1] = offer
                search.catalog[id] = entry
            end
        end
        if (search.page + 1) * 50 < total then
            search.page, search.deadline = search.page + 1, Now() + 15
            SendSearch(); return
        end
    else
        -- Native ADDED events carry later chunks; the getter may still expose
        -- only the initial batch. Track distinct keys across the whole term.
        local results = type(addedResults) == "table" and addedResults or C_AuctionHouse.GetBrowseResults() or {}
        search.browseSeen = search.browseSeen or {}
        for _, result in ipairs(results) do
            local key = result.itemKey
            local id = key and Number(key.itemID)
            if id and Number(result.totalQuantity) and result.totalQuantity > 0 and Number(result.minPrice) and result.minPrice > 0 then
                local identity = table.concat({ id, key.itemLevel or 0, key.itemSuffix or 0, key.battlePetSpeciesID or 0 }, ":")
                if not search.browseSeen[identity] then
                    search.browseSeen[identity] = true; search.browseCount = (search.browseCount or 0) + 1
                end
                local entry = search.catalog[id]
                if not entry then entry = { itemID = id, minPrice = result.minPrice }; search.catalog[id] = entry end
                entry.minPrice, entry.quantity = math.min(entry.minPrice, result.minPrice), result.totalQuantity
                MarkBrowseKinds(search, entry)
            end
        end
        count = search.browseCount or 0
        if C_AuctionHouse.HasFullBrowseResults and not C_AuctionHouse.HasFullBrowseResults() then
            if search.moreAtCount == count then Later(math.max(0, search.deadline - Now()), function() A.Invalidate("timeout") end); return end
            search.moreAtCount, search.more, search.deadline = count, "browse", Now() + 15
            SendSearch(); return
        end
    end
    if search.terms[search.termIndex + 1] then
        search.termIndex, search.page, search.more, search.moreAtCount = search.termIndex + 1, 0, nil, nil
        search.browseSeen, search.browseCount = nil, nil
        search.deadline = Now() + 15
        SendSearch(); return
    end
    if not A.legacy and not search.categoryFallback and not next(search.catalog) then
        -- Text/usable-only results need not cover every restorative potion.
        -- One category fallback discovers actual listings without item names.
        search.categoryFallback, search.more, search.moreAtCount = true, nil, nil
        search.browseSeen, search.browseCount = nil, nil
        search.deadline = Now() + 15
        SendSearch(); return
    end
    local done = search.done
    A.search, A.state = nil, "idle"
    serial = serial + 1
    done(search.catalog)
end

SendSearch = function()
    local search = A.search
    if not search or not Active() or not A.houseOpen or A.state ~= "searching" then return end
    if InCombatLockdown() then A.Invalidate("combat"); return end
    if search.bookScan then search.deadline = math.min(search.deadline, search.bookScan.deadline) end
    if Now() >= search.deadline then
        A.Invalidate(search.waiting == "key" and "loading" or search.waiting and "auctionNotReady" or "timeout")
        return
    end
    local itemKeyInfo = logistics and not A.legacy and not search.more and C_AuctionHouse.GetItemKeyInfo
    if itemKeyInfo and not itemKeyInfo(search.key) then
        search.waiting, search.nativeGeneration = "key", nil
        A.status = "loading"; Paint()
        Later(0.3, SendSearch); return
    end
    local canSend = A.legacy and CanSendAuctionQuery() or (not A.legacy
        and (not C_AuctionHouse.IsThrottledMessageSystemReady or C_AuctionHouse.IsThrottledMessageSystemReady()))
    if not canSend then
        search.waiting, search.nativeGeneration = true, nil
        A.status = "auctionWaiting"; Paint()
        Later(0.3, SendSearch); return
    end
    search.waiting = nil
    A.status = search.potionBrowse and "potionScan" or "searching"
    -- Install the timeout BEFORE issuing: native events may be synchronous.
    local timeout = search.bookScan and math.max(0, search.deadline - Now()) or 15
    Later(timeout, function() A.Invalidate("timeout") end)
    queryGeneration = queryGeneration + 1
    search.nativeGeneration = queryGeneration
    if search.bookScan then search.requests = search.requests + 1 end
    lastNative = not search.potionBrowse and queryGeneration or nil
    local ok
    if search.potionBrowse and A.legacy then
        ok = Call(QueryAuctionItems, search.terms[search.termIndex], nil, nil, search.page, true, nil, false, false,
            { { classID = 0, subClassID = 1 }, { classID = 0, subClassID = 7 } })
    elseif search.potionBrowse then
        if search.more == "browse" then ok = Call(C_AuctionHouse.RequestMoreBrowseResults)
        else ok = Call(C_AuctionHouse.SendBrowseQuery, { searchString = search.categoryFallback and "" or search.terms[search.termIndex], sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = false } },
            filters = search.categoryFallback and {} or { Enum.AuctionHouseFilter.UsableOnly },
            itemClassFilters = { { classID = 0, subClassID = 1 }, { classID = 0, subClassID = 7 } } }) end
    elseif A.legacy then
        ok = Call(QueryAuctionItems, search.name, nil, nil, search.page, false, nil, false, true)
    elseif search.more == "commodity" then ok = Call(C_AuctionHouse.RequestMoreCommoditySearchResults, search.itemID)
    elseif search.more == "item" then ok = Call(C_AuctionHouse.RequestMoreItemSearchResults, search.key)
    else ok = Call(C_AuctionHouse.SendSearchQuery, search.key, {}, true) end
    if not ok then A.Invalidate("unavailable") end
end

local function BeginSearch(row, probe)
    InvalidateForSearch()
    A.selectedID, A.state = row.itemID, "searching"
    local name = FluxItemClass and FluxItemClass.GetName and FluxItemClass.GetName(row.itemID)
    if A.legacy and not name then
        if bookScan then
            probe({itemID = row.itemID, offers = {}, commodity = false, at = Now()}, false, "loading")
        else A.Invalidate("loading") end
        return
    end
    A.search = { itemID = row.itemID, name = name, page = 0, deadline = Now() + 15, probe = probe, row = row,
        key = not A.legacy and C_AuctionHouse.MakeItemKey(row.itemID) or nil }
    if bookScan then A.search.bookScan, A.search.requests = bookScan, 0 end
    Paint()
    SendSearch()
end
A.BeginSearch = BeginSearch
local function FreshBook(book)
    return book and Number(book.at) and Now() - book.at >= 0 and Now() - book.at < 30
end
local function Preview(row, book, need)
    local offers = OffersFor(row.itemID, book.offers, book.commodity)
    local cap = A.PurchaseLimit(row.itemID)
    return book.commodity and A.CommodityOffer(offers, need, cap)
        or not book.commodity and A.SelectStack(offers, need, cap, A.AllowExcessStacks(row))
end
local function ReadyFromBook(row, book, offer)
    local proof = nativeBooks[row.itemID]
    if not proof or not proof.generation or proof.book ~= book or proof.generation ~= lastNative or not FreshBook(book) then return false end
    if A.legacy then
        if offer.page ~= proof.page then return false end
        local live = LegacyOffer(offer.index)
        if not live or live.owned or live.itemID ~= row.itemID or live.quantity ~= offer.quantity
            or live.total ~= offer.total or live.owner ~= offer.owner or live.link ~= offer.link then return false end
    end
    -- Only a completed result from our still-current native query is reusable.
    -- The real click still rechecks legacy identity / modern auction ID, while
    -- a commodity quote consumes one fresh player-authorized intent.
    A.selectedID = row.itemID
    A.search = { itemID = row.itemID, key = proof.key, page = proof.page }
    Ready(offer)
    return A.state == "ready"
end
function A.BeginPotionBrowse(done, terms, termKinds)
    InvalidateForSearch()
    A.search = { potionBrowse = true, catalog = {}, page = 0, deadline = Now() + 15, done = done, terms = terms, termKinds = termKinds, termIndex = 1 }
    A.state, A.status = "searching", "potionScan"
    Paint(); SendSearch()
end

-- Planning issues information queries only. A completed probe can supply ready
-- legacy indices only while its exact query/page/identity remains current.
local function PrepareNext(resume, startup)
    if resume then A.restockRequested = true; A.yielded = nil; rejectedQuotes = {} end
    if not A.restockRequested then return end
    if not A.active or not A.houseOpen or A.transaction or A.foreign or A.yielded then return end
    if A.state == "searching" or A.state == "quoting" or A.state == "classifying" or A.state == "upgrade" then return end
    local dialog = _G.AuctionHouseFrame and _G.AuctionHouseFrame.BuyDialog
    if (dialog and dialog:IsShown()) or (StaticPopup_Visible and
        (StaticPopup_Visible("BUYOUT_AUCTION") or StaticPopup_Visible("BID_AUCTION"))) then A.Invalidate("otherSearch"); return end
    if InCombatLockdown() then A.Invalidate("combat"); return end
    if not A.IsReliable() then A.Invalidate("loading"); return end
    if startup and startup.paintAfterPlanning and not A.ownsQuote and StartupOwnersMatch() then
        -- OnShow paints the finished state in this call. Keep the paints that
        -- publish a search, a result or an error while planning.
        invalidate("changed", skipTransientPaint)
    else
        A.Invalidate("changed")
    end
    -- The caller just built these rows. Consume them only for this initial
    -- planning step. Every later response builds against current inventory.
    local firstRows = ReuseStartupRows(startup)
    local job = { planned = {}, attempted = {}, discovered = {}, hidden = {} }
    A.queue = job
    if A.GetVendorCraftTargets and A.HasCraftPlans() then
        firstRows = nil
        local bases = {}
        for _, row in ipairs(A.GetRows(true)) do
            if not row.isCraftMaterial or (row.baseTarget or 0) > 0 then
                local base = {}; for key, value in pairs(row) do base[key] = value end
                base.target = row.baseTarget or row.target; bases[#bases + 1] = base
            end
        end
        -- Reusing a saved route must not silently replace lost owned vendor
        -- ingredients with an invoice that was never included in its budget.
        A.GetVendorCraftTargets(bases)
    end
    local Advance
    local function Alive() return A.queue == job and A.active and A.houseOpen and not A.yielded end
    local function Planned()
        if A.Followup and A.Followup.Planned then A.Followup.Planned() end
        if A.FlushAuctionatorPrices then A.FlushAuctionatorPrices() end
    end
    Advance = function()
        if not Alive() then return end
        local rows = firstRows or A.GetRows(true)
        firstRows = nil
        if job.focusKind and not A.FindRow(job.focus) then
            for _, row in ipairs(rows) do
                if A.PotionKind and A.PotionKind(row) == job.focusKind then job.focus = row.itemID; break end
            end
        end
        local ordered, preferred = {}, {}
        for _, row in ipairs(rows) do
            if row.itemID == job.focus or (row.craftParents and row.craftParents[job.focus]) then
                ordered[#ordered + 1], preferred[row.itemID] = row, true
            end
        end
        for _, row in ipairs(rows) do if not preferred[row.itemID] then ordered[#ordered + 1] = row end end
        rows = ordered
        for _, row in ipairs(rows) do
            -- GetRows(true) just calculated final needs, including materials.
            -- Reuse that synchronous refresh; submission revalidates live stock.
            local need = row.need
            if need and need > 0 and not A.IsCraftOutput(row.itemID) and not job.attempted[row.itemID] then
                local rejected = rejectedQuotes[row.itemID]
                if rejected and Now() - rejected.at < 30 and need == rejected.quantity then
                    job.rejectionReason = rejected.reason
                    job.attempted[row.itemID] = true; return Advance()
                end
                local kind = A.PotionKind and A.PotionKind(row)
                if not preferred[row.itemID] then job.focus, job.focusKind = row.itemID, kind end
                if kind and not job.discovered[kind] then
                    job.discovered[kind] = true
                    if not potionScans[kind] or Now() - potionScans[kind] >= 30
                        or (A.HasPotionCatalog and not A.HasPotionCatalog(kind)) then
                        local targets = {}
                        for _, target in ipairs(A.potionTargets or {}) do if target.kind == kind then targets[#targets + 1] = target end end
                        if A.DiscoverPotionUpgrades and A.DiscoverPotionUpgrades(targets, function(scanned)
                            for _, entry in ipairs(scanned or targets) do potionScans[entry.kind] = Now() end
                            Advance()
                        end) then return end
                    end
                end
                if A.PotionRowBlocked and A.PotionRowBlocked(row) then job.attempted[row.itemID] = true; return Advance() end
                if not row.isCraftMaterial and not row.craftParents and not job.planned[row.itemID] then
                    job.planned[row.itemID] = true
                    A.RefreshCraftRecipes({ row })
                    if A.StartCraftPricing(row, false, Advance) then return end
                end
                for parent in pairs(row.craftParents or {}) do
                    local plan = A.craftPlans[parent]
                    if plan and Now() - plan.at >= 30 then
                        local original = A.FindRow(parent)
                        if original and A.StartCraftPricing(original, true, Advance) then return end
                    end
                end
                if A.RepriceMaterial and A.RepriceMaterial(row) then return end
                if A.PurchaseLimit(row.itemID) == 0 then job.attempted[row.itemID] = true; return Advance() end
                local book = A.priceBooks[row.itemID]
                if not FreshBook(book) then
                    A.BeginSearch({ itemID = row.itemID, target = need, unitsPerItem = 1 }, Advance)
                    return
                end
                local offer = Preview(row, book, need)
                if offer then
                    A.queue = nil; Planned()
                    if not ReadyFromBook(row, book, offer) then BeginSearch(row) end
                    return
                end
                job.attempted[row.itemID] = true
                return Advance()
            end
        end
        -- A configured kind without a remembered SKU is still missing stock.
        -- Filled known tiers do not start automatic upgrade searches.
        for _, target in ipairs(A.potionTargets or {}) do
            local kind = target.kind
            if not target.sourceID and (target.target or 0) > 0 and not job.discovered[kind] then
                job.focus, job.focusKind = nil, kind
                job.discovered[kind] = true
                if (not potionScans[kind] or Now() - potionScans[kind] >= 30
                    or A.HasPotionCatalog and not A.HasPotionCatalog(kind)) and A.DiscoverPotionUpgrades then
                    if A.DiscoverPotionUpgrades({ target }, function(scanned)
                        for _, entry in ipairs(scanned or { target }) do potionScans[entry.kind] = Now() end
                        Advance()
                    end) then return end
                end
            end
        end
        -- Unlimited vendor targets remain hidden until a real bargain exists.
        -- Probe only the next unresolved shortage, after ordinary purchases.
        for _, row in ipairs(A.GetVendorScanRows and A.GetVendorScanRows() or {}) do
            local need, rejected = A.Need(row) or 0, rejectedQuotes[row.itemID]
            if rejected and Now() - rejected.at < 30 and need == rejected.quantity then
                job.rejectionReason = rejected.reason
            elseif need > 0 and not job.hidden[row.itemID]
                and (not A.legacy or (FluxItemClass and FluxItemClass.GetName and FluxItemClass.GetName(row.itemID))) then
                job.hidden[row.itemID] = true
                if not FreshBook(A.priceBooks[row.itemID]) then
                    A.BeginSearch({ itemID = row.itemID, target = 1, unitsPerItem = 1 }, Advance)
                    return
                end
            end
        end
        A.queue = nil; Planned()
        A.Invalidate(A.HasCraftPlans() and "craftReady" or "enough")
        for _, row in ipairs(rows) do
            if (A.Need(row) or 0) > 0 and not A.IsCraftOutput(row.itemID) then
                A.status = A.IsUpgradeBlacklisted(row.itemID) and "excluded"
                    or A.PotionRowBlocked and A.PotionRowBlocked(row) and "potionData" or "noOffer"; break
            end
        end
        if A.status == "enough" and A.HasBlockedPotionTargets and A.HasBlockedPotionTargets() then A.status = "potionData" end
        if job.rejectionReason and (A.status == "enough" or A.status == "noOffer" or A.status == "craftReady") then
            A.status = job.rejectionReason
        end
        Paint()
    end
    Advance()
end

function A.PrepareNext(resume)
    if not logistics and not bookScan then return PrepareNext(resume) end
end
local prepareNext = A.PrepareNext

function A.ScanQueue(resume, scanAll)
    if logistics or bookScan then return end
    if resume then A.restockRequested = true end
    if not A.restockRequested then return end
    -- Old auction houses prepare one purchase at a time, including callers
    -- retaining an earlier full-refresh request.
    if scanAll ~= true or A.legacy then return A.PrepareNext(resume) end
    if not A.active or not A.houseOpen or A.transaction or A.state == "quoting" then return end
    if resume then A.yielded = nil end
    if A.yielded then return end
    local nativeDialog = _G.AuctionHouseFrame and _G.AuctionHouseFrame.BuyDialog
    if A.foreign or (nativeDialog and nativeDialog:IsShown()) then A.Invalidate("otherSearch"); return end
    if InCombatLockdown() then A.Invalidate("combat"); return end
    if not A.IsReliable() then A.Invalidate("loading"); return end
    rejectedQuotes = {}
    if A.ResetPotionDiscovery then A.ResetPotionDiscovery() end
    A.Invalidate("changed")
    local queue = { rows = {}, index = 0, scanAll = scanAll == true, beforeBooks = {}, priced = {} }
    if queue.scanAll then for id, book in pairs(A.priceBooks or {}) do queue.beforeBooks[id] = book end end
    A.GetRows(true)
    A.queue = queue
    local Advance
    local function Finish()
        A.queue = nil
        if A.FlushAuctionatorPrices then A.FlushAuctionatorPrices() end
        if A.Followup and A.Followup.Planned then A.Followup.Planned() end
        A.PrepareNext()
    end
    local function RemainingPrices()
        if A.queue ~= queue or not A.active or not A.houseOpen then return end
        -- Craft planning can add visible ingredients or omit a free owned
        -- route's price queries. Explicit scans still price those listed rows.
        for _, row in ipairs(A.GetRows(true)) do
            local id = row.itemID
            if not queue.priced[id] then
                queue.priced[id] = true
                if not A.priceBooks[id] or A.priceBooks[id] == queue.beforeBooks[id] then
                    A.BeginSearch({ itemID = id, target = 1, unitsPerItem = 1 }, RemainingPrices)
                    return
                end
            end
        end
        Finish()
    end
    local function StartPricing()
        if A.queue ~= queue then return end
        local rows = A.GetRows(true)
        if A.LoadMarketHints then A.LoadMarketHints(rows) end
        local targets = {}
        for _, row in ipairs(rows) do
            if not row.isCraftMaterial and not A.IsUpgradeBlacklisted(row.itemID)
                and (queue.scanAll or (A.Need(row) or 0) > 0) then targets[#targets + 1] = row end
        end
        A.RefreshCraftRecipes(targets)
        queue.rows = targets
        Advance()
    end
    Advance = function()
        if A.queue ~= queue or not A.active or not A.houseOpen then return end
        queue.index = queue.index + 1
        local row = queue.rows[queue.index]
        if row then
            if queue.scanAll and (A.Need(row) or 0) <= 0 then
                -- Price every listed restock item on an explicit scan, even
                -- when stocked. A probe cannot submit a purchase or craft.
                A.BeginSearch({ itemID = row.itemID, target = 1, unitsPerItem = 1 }, Advance)
            elseif not A.StartCraftPricing(row, queue.scanAll, Advance) then Advance() end
        else
            if queue.scanAll then RemainingPrices() else Finish() end
        end
    end
    local function DiscoverPotions()
        if A.queue ~= queue then return end
        local targets = {}
        for _, target in ipairs(A.potionTargets or {}) do
            -- Filling the old tier never satisfies the stronger tier target.
            -- Discovery must run before a shortage can be known for that SKU.
            if (target.target or 0) > 0 then targets[#targets + 1] = target end
        end
        if A.DiscoverPotionUpgrades and A.DiscoverPotionUpgrades(targets, function(scanned)
            for _, target in ipairs(scanned or targets) do potionScans[target.kind] = Now() end
            StartPricing()
        end, true) then return end
        StartPricing()
    end
    -- Vendor rows stay hidden unless a fresh usable offer beats their buy price.
    -- Probe them read-only first so standalone clients can discover discounts.
    local vendorRows = A.GetVendorScanRows and A.GetVendorScanRows() or {}
    local vendorIndex = 0
    local function NextVendor()
        if A.queue ~= queue or not A.active or not A.houseOpen then return end
        vendorIndex = vendorIndex + 1
        local row = vendorRows[vendorIndex]
        -- Legacy queries need a localized item name. A cold hidden vendor row
        -- must not block every ordinary target; keep it excluded until loaded.
        while row and ((not queue.scanAll and (A.Need(row) or 0) <= 0)
            or (A.legacy and not (FluxItemClass and FluxItemClass.GetName and FluxItemClass.GetName(row.itemID)))) do
            vendorIndex = vendorIndex + 1; row = vendorRows[vendorIndex]
        end
        if row then A.BeginSearch({ itemID = row.itemID, target = 1, unitsPerItem = 1 }, NextVendor)
        else DiscoverPotions() end
    end
    NextVendor()
end
local scanQueue = A.ScanQueue

local function NotifyPurchase(t, state, reason)
    local request = t.logistics
    local entry = request.entry
    request.observe(state, {
        attemptID = t.attemptID, jobId = entry.jobId, id = entry.id, planRevision = entry.planRevision,
        groupRevision = entry.groupRevision, itemID = t.itemID, quantity = t.quantity, totalCopper = t.total, kind = t.kind,
        auctionID = t.auctionID, reason = reason,
    })
end

local function ReportPurchaseEnd(t, status, release)
    if t.dispatching then
        -- The client may publish an outcome during the native call.
        t.finished, t.released = status, release
        return
    end
    local state = status == "bought" and "confirmed"
        or (status == "failed" or status == "blocked" and release) and "failed" or "uncertain"
    NotifyPurchase(t, state, status)
end

local function EndTransaction(status, release)
    local t = A.transaction
    if not t then return end
    if status == "bought" and not t.logistics then
        A.AcceptReservation(t)
        if A.Followup then A.Followup.Purchased(t) end
    end
    if status == "uncertain" and not t.incomingConfirmed then release = true end
    CancelTimer()
    issuing = false
    if release and not t.logistics then
        A.Release(t.itemID, t.units)
        if A.ReleaseCraftSpend then A.ReleaseCraftSpend(t.craftSpend) end
    end
    A.transaction, A.offer, A.search, A.ownsQuote = nil, nil, nil, false
    A.state, A.status = "idle", status
    A.GetRows(true)
    Paint()
    if t.logistics then
        FinishLogistics(status, true)
        ReportPurchaseEnd(t, status, release)
    elseif status == "bought" or status == "sent" then A.PrepareNext() end
end

local function Submit(row, offer, kind)
    local t = { itemID = row.itemID, quantity = offer.quantity, auctionID = offer.auctionID, kind = kind }
    if logistics then
        if not Authorized(logistics, offer.quantity, offer.total) then A.Invalidate("changed"); return end
        attemptID = attemptID + 1
        t.logistics, t.attemptID, t.total, t.dispatching = logistics, attemptID, offer.total, true
    else
        if A.Followup then t.followup = A.Followup.Capture(row) end
        if A.RecordCraftSpend then t.craftSpend = A.RecordCraftSpend(row, offer.total, offer.quantity) end
        t.units = A.Reserve(row, offer.quantity)
    end
    nativeBooks[row.itemID], A.priceBooks[row.itemID] = nil, nil
    A.transaction, A.state, A.status = t, "buying", "buying"
    Later(15, function() EndTransaction("uncertain") end)
    -- Bids retain the physical OnClick stack. Commodity confirmation consumes
    -- the single-use intent established by that click when its quote arrives.
    RememberAttempt(kind, row, offer)
    local purchases = Flux.Inventory.Builtin and Flux.Inventory.Builtin.AuctionPurchases
    if purchases then purchases.TrackRestock(t, offer) end
    issuing = true
    if kind == "commodity" then C_AuctionHouse.ConfirmCommoditiesPurchase(row.itemID, offer.quantity)
    elseif kind == "legacy" then PlaceAuctionBid("list", offer.index, offer.total)
    else C_AuctionHouse.PlaceBid(offer.auctionID, offer.total) end
    issuing = false
    if purchases then purchases.FinishRestock() end
    if t.logistics then
        t.dispatching = nil
        NotifyPurchase(t, "submitted")
        if t.finished then ReportPurchaseEnd(t, t.finished, t.released) end
    end
    Paint()
end

local function SameLegacy(a, b)
    return a and b and a.itemID == b.itemID and a.quantity == b.quantity and a.total == b.total
        and a.owner == b.owner and a.link == b.link and not b.owned
end

local function CheckItem(offer)
    local search = A.search
    if not search then return false end
    local ah = C_AuctionHouse
    for i = 1, ah.GetNumItemSearchResults(search.key) do
        local info = ah.GetItemSearchResultInfo(search.key, i)
        if info and info.auctionID == offer.auctionID then
            local available = Number(info.quantity)
            return SameKey(info.itemKey, search.key) and offer.quantity == 1
                and available and available >= 1 and available % 1 == 0
                and info.buyoutAmount == offer.total and not info.containsOwnerItem and not info.containsAccountItem
        end
    end
    return false
end

function A.Primary(logisticsPress)
    if bookScan then return end
    if logistics and logistics.preparedOnly and logisticsPress ~= logistics then return end
    local policy = _G.Flux and _G.Flux.RestockPolicy
    if policy and policy.IsPlannerRegistered() and policy.IsWorkflowBusy(logistics and "planner" or "auction") then
        policy.Report(policy.Text.busy)
        return
    end
    if not Active() or not A.houseOpen then A.status = "openAH"; Paint(); return end
    if InCombatLockdown() then A.Invalidate("combat"); return end
    if A.transaction or A.state == "searching" or A.state == "quoting" or A.state == "classifying" or A.state == "upgrade" then return end
    ReleaseFinishedForeignQuote()
    local nativeDialog = _G.AuctionHouseFrame and _G.AuctionHouseFrame.BuyDialog
    if A.foreign or (nativeDialog and nativeDialog:IsShown())
        or (StaticPopup_Visible and (StaticPopup_Visible("BUYOUT_AUCTION") or StaticPopup_Visible("BID_AUCTION"))) then
        A.Invalidate("otherSearch"); return
    end
    if not logistics then A.restockRequested = true end
    if not A.IsReliable() then A.Invalidate("loading"); return end
    local row, reason, need = Eligible(A.selectedID)
    if not logistics and row and A.PotionRowBlocked and A.PotionRowBlocked(row) then
        A.Invalidate(A.IsUpgradeBlacklisted(row.itemID) and "excluded" or "potionData"); return
    end
    local offer = A.offer
    if not row or not logistics and A.IsCraftOutput(row.itemID) or not offer
        or offer.itemID ~= row.itemID or Now() - offer.at >= 30 then
        if logistics then A.Invalidate(reason or "expired") else A.PrepareNext(true) end
        return
    end
    local cap = SearchLimit(row.itemID)
    if cap <= 0 then A.Invalidate("overCap"); return end
    if offer.quantity > need then
        if offer.commodity then
            -- Stock/mail may change before BAG_UPDATE reaches this panel. A
            -- commodity can be reduced to the live physical-item shortage;
            -- the excess-stack option applies only to indivisible listings.
            local revised = CommodityFor(row.itemID, CommodityResults(row.itemID), need, cap)
            if not revised then A.Invalidate("changed"); return end
            revised.itemID, revised.at = row.itemID, Now()
            A.offer, offer = revised, revised
        elseif not AllowExcess(row) then A.Invalidate("changed"); return end
    end
    if offer.total > cap * offer.quantity or (offer.unitPrice and offer.unitPrice > cap) then
        A.Invalidate("overCap"); return
    end
    if not VendorAllowed(row.itemID, offer) then A.Invalidate("overCap"); return end
    if GetMoney() < offer.total then A.Invalidate("money"); return end
    if logistics then
        if not Authorized(logistics, offer.quantity, offer.total) then A.Invalidate("changed"); return end
    elseif A.CheckCraftSpend and not A.CheckCraftSpend(row, offer) then A.Invalidate("craftBudget"); return end
    if offer.commodity then
        -- Exactly one intent, created only by this button press. Quote callbacks
        -- can confirm this item/quantity once; they cannot start another purchase.
        A.intent = { itemID = row.itemID, quantity = offer.quantity, cap = cap, at = Now() }
        A.state, A.status, A.ownsQuote = "quoting", "quoting", true
        Later(15, function() A.Invalidate("timeout") end)
        RememberAttempt("quote", row, offer)
        issuing = true
        -- All three pinned modern native UIs pass the displayed unit price as
        -- the third argument, although the generated declaration lists two.
        C_AuctionHouse.StartCommoditiesPurchase(row.itemID, offer.quantity, offer.unitPrice)
        issuing = false
        Paint()
    elseif A.legacy then
        if not SameLegacy(offer, LegacyOffer(offer.index)) then
            nativeBooks[row.itemID], A.priceBooks[row.itemID] = nil, nil
            local wasLogistics = logistics ~= nil
            A.Invalidate("changed")
            if not wasLogistics then A.PrepareNext() end
            return
        end
        Submit(row, offer, "legacy")
    else
        if not CheckItem(offer) then
            nativeBooks[row.itemID], A.priceBooks[row.itemID] = nil, nil
            local wasLogistics = logistics ~= nil
            A.Invalidate("changed")
            if not wasLogistics then A.PrepareNext() end
            return
        end
        Submit(row, offer, "item")
    end
end

local function RefreshInventory()
    if not Active() or not A.houseOpen then return end
    if bookScan then return end
    if logistics then
        if not A.transaction and not Eligible(logistics.entry.itemID) then A.Invalidate("changed") else Paint() end
        return
    end
    A.GetRows(true)
    -- Bag/profession/mail pulses repaint live counts without cancelling an
    -- owned search or replacing the player's pending upgrade choices.
    if not A.transaction and A.state == "ready" and A.offer then
        local row = A.FindRow(A.offer.itemID)
        -- The rebuild above already reconciled this row's stock and receipts.
        local need = row and row.need
        if not row or A.IsVendorItem(row.itemID) or (need and need <= 0) then A.Invalidate("changed") end
    end
    -- A user-started operation may have paused for its initial stock snapshot.
    -- Resume that one wait; an idle/finished queue never restarts on a pulse.
    if A.restockRequested and A.status == "loading" and not A.queue and not A.transaction
        and not A.yielded and A.IsReliable() then A.PrepareNext(); return end
    Paint()
end

local function SearchEvent(event, key)
    if not Active() or not A.houseOpen then return end
    if bookScan and InCombatLockdown() then A.Invalidate("combat"); return end
    if event == "AUCTION_ITEM_LIST_UPDATE" then
        if A.transaction and A.transaction.kind == "legacy" then Paint()
        elseif A.state == "searching" then ReadLegacy()
        elseif A.state == "ready" then A.Invalidate("changed") end
    elseif event == "BAG_UPDATE_DELAYED" then
        RefreshInventory()
    elseif event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
        -- A request already sent must await its results, not send a second query.
        if A.state == "searching" and A.search and A.search.waiting then SendSearch() end
    elseif not A.legacy then ReadModern(event, key) end
end

local SEARCH_EVENTS = { "AUCTION_ITEM_LIST_UPDATE", "COMMODITY_SEARCH_RESULTS_UPDATED",
    "COMMODITY_SEARCH_RESULTS_ADDED", "ITEM_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_ADDED",
    "BAG_UPDATE_DELAYED", "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
    "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" }
Listen = function(enabled)
    if listening == enabled then return end
    listening = enabled
    for _, event in ipairs(SEARCH_EVENTS) do
        if enabled then Events.Register(event, SearchEvent) else Events.Unregister(event, SearchEvent) end
    end
    local inv = Flux.Inventory
    if enabled and inv and inv.Register then
        inv.Register("AuctionRestock.Incoming", function()
            RefreshInventory()
        end, { tier = "light", regions = { "mail", "professions" } })
    elseif not enabled and inv and inv.Unregister then inv.Unregister("AuctionRestock.Incoming") end
end

local function CopyBookDepth(book, complete, reason)
    local offers = {}
    for _, offer in ipairs(book.offers) do
        if book.commodity then
            local owned = Number(offer.numOwnerItems) or 0
            local quantity = Number(offer.quantity)
            local unitPrice = offer.unitPrice
            if quantity and PositiveInteger(quantity - owned) and PositiveInteger(unitPrice)
                and not offer.containsAccountItem then
                offers[#offers + 1] = {quantity = quantity - owned, unitPrice = unitPrice}
            end
        elseif not offer.owned and PositiveInteger(offer.quantity) and PositiveInteger(offer.total) then
            local count = PositiveInteger(offer.availableQuantity) and offer.availableQuantity or 1
            offers[#offers + 1] = {quantity = offer.quantity, total = offer.total, count = count}
        end
    end
    return { itemID = book.itemID, commodity = book.commodity, offers = offers, at = book.at,
        complete = complete, reason = reason }
end

-- One explicit information-only lease through the existing query handlers.
-- Depth contains no listing handles and never enters the purchase path.
function A.ScanLogisticsBooks(itemIDs, callback)
    if type(itemIDs) ~= "table" or #itemIDs == 0 or type(callback) ~= "function" then return false, "invalid" end
    if #itemIDs > BOOK_ITEM_LIMIT then return false, "limit" end
    local legacy = A.IsLegacy()
    local owner = legacy and _G.AuctionFrame or not legacy and _G.AuctionHouseFrame
    if not A.houseOpen or not owner or not owner:IsShown() then return false, "openAH" end
    if InCombatLockdown() then return false, "combat" end
    local policy = _G.Flux and _G.Flux.RestockPolicy
    -- A ready standalone offer retains search results but has no query or
    -- purchase in flight. Explicit pricing may replace that unsubmitted offer.
    local replaceOffer = A.active and A.state == "ready" and A.offer ~= nil
    if bookScan or logistics or A.queue or A.transaction or A.ownsQuote
        or not replaceOffer and (A.search or A.offer or A.state ~= "idle")
        or policy and policy.IsWorkflowBusy and policy.IsWorkflowBusy("planner") then return false, "busy" end
    ReleaseFinishedForeignQuote()
    local nativeDialog = not legacy and owner.BuyDialog
    if A.foreign or A.active and A.yielded or nativeDialog and nativeDialog:IsShown()
        or StaticPopup_Visible and (StaticPopup_Visible("BUYOUT_AUCTION") or StaticPopup_Visible("BID_AUCTION")) then
        return false, "otherSearch"
    end
    if not A.IsReliable() then return false, "loading" end
    local ids, seen = {}, {}
    for _, id in ipairs(itemIDs) do
        if not PositiveInteger(id) then return false, "invalid" end
        if not seen[id] then ids[#ids + 1], seen[id] = id, true end
    end
    local scan = { callback = callback, books = {}, deadline = Now() + BOOK_SCAN_SECONDS,
        selectedID = A.selectedID, status = replaceOffer and "intro" or A.status }
    local index = 0
    local function Advance(book, complete, reason)
        if bookScan ~= scan then return end
        if book then scan.books[book.itemID] = CopyBookDepth(book, complete, reason) end
        scan.reason = scan.reason or reason
        index = index + 1
        local id = ids[index]
        if id then BeginSearch({itemID = id, target = 1}, Advance)
        else FinishBookScan() end
    end
    bookScan, A.legacy = scan, legacy
    InstallHooks()
    Listen(true)
    Advance()
    return true, "searching"
end

local function RunLogistics(entry, quantity, authorize, observe, execute, explicit)
    if type(entry) ~= "table" or (entry.kind ~= "auction" and entry.kind ~= "buy")
        or not PositiveInteger(entry.itemID) or not entry.jobId or not entry.id or not entry.planRevision
        or (issecretvalue and issecretvalue(entry.groupRevision))
        or entry.groupRevision ~= nil and (type(entry.groupRevision) ~= "string" or entry.groupRevision == "")
        or not PositiveInteger(entry.quantity) or not PositiveInteger(quantity) or quantity > entry.quantity
        or not PositiveInteger(entry.maxUnitPrice)
        or entry.maxTotalPrice ~= nil and not PositiveInteger(entry.maxTotalPrice)
        or entry.minQuantity ~= nil and (not PositiveInteger(entry.minQuantity) or entry.minQuantity > quantity)
        or entry.stackSize ~= nil and (not PositiveInteger(entry.stackSize) or entry.stackSize > quantity
            or entry.minQuantity and entry.stackSize < entry.minQuantity)
        or entry.stackMaxTotalPrice ~= nil and not PositiveInteger(entry.stackMaxTotalPrice)
        or type(authorize) ~= "function" or type(observe) ~= "function" then return false, "invalid" end
    local legacy = A.IsLegacy()
    local owner = legacy and _G.AuctionFrame or not legacy and _G.AuctionHouseFrame
    if not A.houseOpen or not owner or not owner:IsShown() then return false, "openAH" end
    if InCombatLockdown() then return false, "combat" end
    local same = SameLogistics(logistics, entry, quantity)
    if same and (A.transaction or A.ownsQuote) then return true, A.state end
    local policy = _G.Flux and _G.Flux.RestockPolicy
    if bookScan or A.transaction or A.ownsQuote or policy and policy.IsWorkflowBusy("planner") then return false, "busy" end
    -- An explicit Find offer can reclaim search after yielding. Foreign purchases retain their own gate.
    if not execute and not same and (explicit ~= true and (A.active or A.yielded)
        or (logistics and not logistics.preparedOnly)) then
        return false, "otherSearch"
    end
    ReleaseFinishedForeignQuote()
    local nativeDialog = not legacy and owner.BuyDialog
    if A.foreign or (nativeDialog and nativeDialog:IsShown())
        or (StaticPopup_Visible and (StaticPopup_Visible("BUYOUT_AUCTION") or StaticPopup_Visible("BID_AUCTION"))) then
        return false, "otherSearch"
    end
    if not A.IsReliable() then return false, "loading" end
    if authorize(entry, quantity) ~= true then return false, "changed" end
    local current = A.GetLogisticsState(entry, quantity)
    if explicit == true and same and logistics.preparedOnly and (current == "searching" or current == "ready") then
        logistics.manual, logistics.authorize, logistics.observe = true, authorize, observe
        if current == "ready" and A.Followup and A.Followup.Refresh and A.offer ~= lastFollowupOffer then
            local offer = A.offer
            Later(offer.at + 30 - Now(), function() if A.offer == offer then Paint() end end)
            Paint()
        end
    end
    if current == "searching" then return true, current end
    if current == "ready" then
        if not execute then return true, current end
        logistics.authorize, logistics.observe = authorize, observe
        local submitted = attemptID
        A.Primary(logistics) -- retains the real click stack
        if attemptID ~= submitted then return true, "buying" end
        if A.state == "quoting" then return true, "quoting" end
        return false, A.status
    end
    A.Invalidate("changed")
    local accepted = {}
    for _, key in ipairs({"itemID", "quantity", "jobId", "id", "kind", "planRevision", "groupRevision", "actorKey", "maxUnitPrice",
        "maxTotalPrice", "minQuantity", "stackSize", "stackMaxTotalPrice"}) do
        accepted[key] = entry[key]
    end
    logistics = { entry = accepted, quantity = quantity, authorize = authorize, observe = observe,
        preparedOnly = not execute, manual = explicit == true,
        row = { itemID = entry.itemID, target = quantity } }
    A.restockRequested, A.yielded = false, nil
    InstallHooks()
    Listen(true)
    BeginSearch(logistics.row)
    if logistics then return true, A.state end
    return false, A.status
end

-- Explicit preparation may use the open Restock tab. No preparation submits a purchase.
function A.PrepareLogistics(entry, quantity, authorize, observe, explicit)
    return RunLogistics(entry, quantity, authorize, observe, false, explicit)
end

function A.ExecuteLogistics(entry, quantity, authorize, observe)
    return RunLogistics(entry, quantity, authorize, observe, true)
end

-- Only the visible Restock button can act on a manually selected queue offer.
local function ReadyPrimaryOrder(order)
    return order and order.preparedOnly and order.manual and A.active
        and A.GetLogisticsState(order.entry, order.quantity) == "ready"
end

function A.IsLogisticsPrimaryReady(selected)
    local order = logistics
    return ReadyPrimaryOrder(order) and type(selected) == "table" and PositiveInteger(selected.quantity)
        and selected.jobId == order.entry.jobId and selected.id == order.entry.id
        and selected.itemID == order.entry.itemID and selected.planRevision == order.entry.planRevision
        and selected.groupRevision == order.entry.groupRevision
        and A.offer.quantity <= selected.quantity or false
end

function A.ClickPrimary(selected)
    local order = logistics
    if selected ~= nil then
        if A.IsLogisticsPrimaryReady(selected) then return A.Primary(order) end
        return
    end
    if order and order.preparedOnly then
        if not ReadyPrimaryOrder(order) then return end
        return A.Primary(order)
    end
    return A.Primary()
end

function A.GetFollowupOffer()
    local offer = A.offer
    if not A.houseOpen or A.state ~= "ready" or A.transaction or A.ownsQuote or A.foreign
        or not offer or Now() >= offer.at + 30 then return end
    if logistics then
        if logistics.preparedOnly and logistics.manual then return offer end
    elseif A.active then return offer end
end

function A.ClickFollowupOffer(shown)
    if shown and shown == A.GetFollowupOffer() then return A.Primary(logistics) end
end

local function ShowSession(paintAfterPlanning)
    A.active, A.yielded = true, nil
    if bookScan then A.Invalidate("otherSearch") end
    if logistics and logistics.preparedOnly and not logistics.manual and not A.transaction and not A.ownsQuote then
        A.Invalidate("otherSearch")
    end
    if logistics then return end
    A.restockRequested = true
    potionScans = {}
    if A.ResetPotionUpgradeChoices then A.ResetPotionUpgradeChoices() end
    A.legacy = A.IsLegacy()
    local owner = A.legacy and _G.AuctionFrame or _G.AuctionHouseFrame
    if owner and owner:IsShown() then A.houseOpen = true end
    if A.houseOpen then InstallHooks() end
    Listen(true)
    local startup = A.ScanQueue == scanQueue and A.PrepareNext == prepareNext and CaptureStartup()
    local rows = A.GetRows(true)
    A.editorID = A.FindRow(A.editorID) and A.editorID or (A.rows[1] and A.rows[1].itemID)
    if startup and A.ScanQueue == scanQueue and A.PrepareNext == prepareNext then
        startup.rows, startup.vendorRows = rows, A.vendorScanRows
        startup.paintAfterPlanning = paintAfterPlanning
        PrepareNext(nil, startup)
    else
        A.ScanQueue()
    end
end

function A.ShowSession()
    ShowSession()
end
local showSession = A.ShowSession

function ns.AuctionRestockOnShow()
    if A.ShowSession == showSession then
        ShowSession(true)
    else
        A.ShowSession()
    end
    A.UpdateUI()
end

function A.HideSession()
    A.active = false
    A.restockRequested = false
    Listen(false)
    A.Invalidate("intro")
end

function A.SettingsChanged()
    potionScans = {}
    rejectedQuotes = {}
    if A.Followup then A.Followup.Refresh() end
    if not A.active then return end
    if logistics or bookScan then Paint(); return end
    if A.applyingAuctionTier then A.GetRows(true); Paint(); return end
    local startup = A.ScanQueue == scanQueue and A.PrepareNext == prepareNext and CaptureStartup()
    if startup then
        local settings = auctionSettings()
        local saved = settings.vendorCraftPlans
        if next(settings.pending) or (saved ~= nil and (type(saved) ~= "table" or next(saved))) then startup = nil end
    end
    local rows = A.GetRows(true)
    if startup then startup.rows, startup.vendorRows = rows, A.vendorScanRows end
    A.Invalidate("changed")
    if startup and serial == startup.serial + 1 and A.ScanQueue == scanQueue and A.PrepareNext == prepareNext then
        -- Keep the settings repaint. The planner checks the inventory again
        -- after its own invalidation and uses fresh rows if anything changed.
        startup.serial = serial
        return PrepareNext(nil, startup)
    end
    A.ScanQueue()
end

local function RejectQuote(reason, unitPrice, totalPrice)
    local intent = A.intent
    if intent then
        rejectedQuotes[intent.itemID] = { quantity = intent.quantity, at = Now(), reason = reason }
        nativeBooks[intent.itemID], A.priceBooks[intent.itemID] = nil, nil
    end
    if Number(unitPrice) and Number(totalPrice) then A.completedQuote = { at = Now(), unitPrice = unitPrice, total = totalPrice } end
    local wasLogistics = logistics ~= nil
    A.Invalidate(reason)
    if not wasLogistics then A.PrepareNext() end -- information only
end

local function QuoteEvent(event, unitPrice, totalPrice)
    if event == "COMMODITY_PRICE_UPDATED" and (not A.ownsQuote or A.state ~= "quoting") then
        -- Repeated price notifications cannot spend again or taint an already
        -- consumed intent. There is no new permission in an unkeyed event.
        if A.transaction then return end
        local completed = A.completedQuote
        if completed and Number(unitPrice) and Number(totalPrice) and Now() - completed.at <= 15
            and completed.unitPrice == unitPrice and completed.total == totalPrice then return end
        A.foreign, A.ownsQuote = { kind = "quote" }, false
        if Active() then A.Invalidate("otherSearch") end
        return
    end
    if A.foreign and A.foreign.kind == "quote" and event == "COMMODITY_PRICE_UNAVAILABLE" then A.foreign = nil end
    if not A.ownsQuote or not Active() or not A.houseOpen or A.state ~= "quoting" then return end
    if event == "COMMODITY_PRICE_UNAVAILABLE" then RejectQuote("noOffer"); return end
    local offer = A.offer
    local intent = A.intent
    local row, reason, need = Eligible(A.selectedID)
    if not row then A.Invalidate(reason); return end
    if not logistics and A.PotionRowBlocked and A.PotionRowBlocked(row) then
        A.Invalidate(A.IsUpgradeBlacklisted(row.itemID) and "excluded" or "potionData"); return
    end
    if not intent or intent.itemID ~= row.itemID or not offer or intent.quantity ~= offer.quantity
        or Now() - intent.at > 15 or A.foreign or InCombatLockdown() then A.Invalidate("expired"); return end
    local remaining = Number(C_AuctionHouse.GetQuoteDurationRemaining()) or 0
    if remaining <= 0 then A.Invalidate("expired"); return end
    local cap = math.min(intent.cap, SearchLimit(row.itemID))
    if not Number(unitPrice) or unitPrice <= 0 or not Number(totalPrice) or totalPrice <= 0
        or unitPrice > cap or totalPrice > cap * offer.quantity
        or offer.quantity > need then RejectQuote("overCap", unitPrice, totalPrice); return end
    if not VendorAllowed(row.itemID, { commodity = true, quantity = offer.quantity,
        total = totalPrice, unitPrice = unitPrice }) then RejectQuote("overCap", unitPrice, totalPrice); return end
    if GetMoney() < totalPrice then A.Invalidate("money"); return end
    CancelTimer()
    offer.total, offer.unitPrice, offer.at = totalPrice, unitPrice, Now()
    if logistics then
        local policy = _G.Flux and _G.Flux.RestockPolicy
        if not A.IsReliable() or policy and policy.IsWorkflowBusy("planner")
            or not Authorized(logistics, offer.quantity, offer.total) then A.Invalidate("changed"); return end
    elseif not A.CheckCraftSpend(row, offer) then A.Invalidate("craftBudget"); return end
    A.intent = nil -- consume BEFORE the native call, including synchronous events
    A.completedQuote = { at = Now(), unitPrice = unitPrice, total = totalPrice }
    Submit(row, offer, "commodity")
end

local function PurchaseEvent(event, id, quantity)
    local foreign = A.foreign
    local commodityEnded = event == "COMMODITY_PURCHASE_SUCCEEDED" or event == "COMMODITY_PURCHASE_FAILED"
    if foreign then
        if foreign.kind == "quote" and not A.transaction and (commodityEnded or event == "COMMODITY_PURCHASED") then
            -- Outside confirmation can close without calling CancelCommoditiesPurchase.
            -- Terminal events lack quote identity, so retain any live native quote.
            foreign.finished = true
            ReleaseFinishedForeignQuote()
        elseif (foreign.kind == "commodity" and commodityEnded)
            or (foreign.kind == "item" and event == "AUCTION_HOUSE_PURCHASE_COMPLETED" and foreign.auctionID == id) then
            A.foreign = nil
        end
    end
    local t = A.transaction
    if not t then return end
    if t.uncertain then return end
    -- This failure has no item/transaction ID. Keep the reservation rather than
    -- crediting an unrelated addon's failure to our still-pending submission.
    if event == "COMMODITY_PURCHASE_FAILED" and t.kind == "commodity" then
        local purchases = Flux.Inventory.Builtin and Flux.Inventory.Builtin.AuctionPurchases
        local owned = purchases and purchases.ConsumeFailure(t)
        EndTransaction(owned and "failed" or "uncertain", owned)
    elseif event == "COMMODITY_PURCHASE_SUCCEEDED" and t.kind == "commodity" then EndTransaction("bought")
    elseif event == "COMMODITY_PURCHASED" and t.kind == "commodity"
        and id == t.itemID and quantity == t.quantity then EndTransaction("bought")
    elseif event == "AUCTION_HOUSE_PURCHASE_COMPLETED" and t.kind == "item" and id == t.auctionID then EndTransaction("bought") end
    if event == "CHAT_MSG_SYSTEM" and t.kind == "legacy" and id == ERR_AUCTION_BID_PLACED then EndTransaction("bought") end
end

Events.Register("AUCTION_HOUSE_SHOW", function()
    A.houseOpen, A.legacy, A.yielded = true, A.IsLegacy(), nil
    InstallHooks()
    if A.AttachButton then A.AttachButton() end
    if A.active then A.GetRows(true); Paint() end
end)
Events.Register("AUCTION_HOUSE_CLOSED", function()
    A.houseOpen = false
    A.foreign = nil
    if A.frame then A.frame:Hide() end
    A.HideSession()
    if A.launcher then A.launcher:Hide() end
end)
Events.Register("AUCTION_ITEM_LIST_UPDATE", function()
    if A.foreign and A.foreign.kind == "legacy" then A.foreign = nil end
end)
Events.Register("ADDON_LOADED", function(_, addon)
    if A.houseOpen and (addon == "Blizzard_AuctionHouseUI" or addon == "Blizzard_AuctionUI")
        and A.AttachButton then A.AttachButton() end
end)
Events.Register("COMMODITY_PRICE_UPDATED", QuoteEvent)
Events.Register("COMMODITY_PRICE_UNAVAILABLE", QuoteEvent)
local function ActionBlocked(_, addon, action)
    local matching = type(action) == "string" and (action:find("CommoditiesPurchase", 1, true) or action:find("PlaceBid", 1, true) or action:find("PlaceAuctionBid", 1, true))
    if addon ~= "_FluxUI" and addon ~= "UNKNOWN" and addon ~= nil and not matching then return end
    if A.lastAttempt and (A.transaction or A.state == "quoting") then A.lastAttempt.blocked = true end
    local purchases = Flux.Inventory.Builtin and Flux.Inventory.Builtin.AuctionPurchases
    if purchases then purchases.AbortRestock(A.transaction) end
    if A.transaction then EndTransaction("blocked", issuing == true)
    elseif A.state == "quoting" then
        A.ownsQuote = false
        A.Invalidate("blocked")
    end
end
Events.Register("ADDON_ACTION_BLOCKED", ActionBlocked)
Events.Register("ADDON_ACTION_FORBIDDEN", ActionBlocked)
for _, event in ipairs({ "COMMODITY_PURCHASE_FAILED", "COMMODITY_PURCHASE_SUCCEEDED",
    "COMMODITY_PURCHASED", "AUCTION_HOUSE_PURCHASE_COMPLETED", "CHAT_MSG_SYSTEM" }) do Events.Register(event, PurchaseEvent) end
