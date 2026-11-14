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
A.state, A.status = "idle", "intro"
A.debugBuild = "AH-restock-explicit-start-20261114-r27"

local function Now() return GetTime() end
local function Paint() if A.UpdateUI then A.UpdateUI() end end
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

function A.Invalidate(reason)
    if A.transaction then
        -- A submitted purchase must retain its reservation until its outcome is known.
        Paint()
        return
    end
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
    if reason ~= "searching" and A.FlushAuctionatorPrices then A.FlushAuctionatorPrices() end
    Paint()
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
    if not A.active then return end
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
    local row = A.FindRow(id, true)
    if not row or A.IsVendorItem(id) then return nil, "changed" end
    local need = A.Need(row)
    if not need then return nil, "loading" end
    if need <= 0 then return nil, "enough" end
    return row, nil, need
end

local function SearchLimit(id)
    return A.PurchaseLimit(id)
end
local function OffersFor(id, offers, commodity)
    return A.FilterVendorOffers and A.FilterVendorOffers(id, offers, commodity) or offers
end
local function VendorAllowed(id, offer)
    return not A.VendorOfferAllowed or A.VendorOfferAllowed(id, offer)
end

local function Ready(offer)
    CancelTimer()
    local row, reason, need = Eligible(A.selectedID)
    if not row then A.Invalidate(reason); return end
    if offer.quantity > need and not A.AllowExcessStacks(row) then A.Invalidate("changed"); return end
    if offer.total > SearchLimit(row.itemID) * offer.quantity then A.Invalidate("overCap"); return end
    if not VendorAllowed(row.itemID, offer) then A.Invalidate("overCap"); return end
    A.offer, A.state, A.status = offer, "ready", "offer"
    offer.at, offer.itemID = Now(), row.itemID
    Paint()
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
local function FinishProbe(offers, commodity)
    local search = A.search
    if not search or not search.probe then return end
    CancelTimer()
    serial = serial + 1
    A.search, A.offer, A.state = nil, nil, "idle"
    local book = { itemID = search.itemID, offers = offers, commodity = commodity, at = Now() }
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
    count, total = Number(count) or 0, Number(total) or 0
    local offers = {}
    for index = 1, count do
        local offer = LegacyOffer(index)
        if offer and offer.itemID == search.itemID then offer.page = search.page; offers[#offers + 1] = offer end
    end
    if search.probe then
        search.book = search.book or {}
        for _, offer in ipairs(offers) do search.book[#search.book + 1] = offer end
        if (search.page + 1) * 50 < total then
            search.page, search.deadline = search.page + 1, Now() + 15
            SendSearch()
        else FinishProbe(search.book, false) end
        return
    end
    offers = OffersFor(row.itemID, offers, false)
    local fit = A.SelectStack(offers, need, SearchLimit(row.itemID), false)
    if fit then Ready(fit); return end
    local excess = A.AllowExcessStacks(row) and A.SelectStack(offers, need, SearchLimit(row.itemID), true)
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

local function CommodityResults(itemID)
    local ah, offers = C_AuctionHouse, {}
    local count = ah.GetNumCommoditySearchResults(itemID)
    for i = 1, count do
        local info = ah.GetCommoditySearchResultInfo(itemID, i)
        if info and info.itemID == itemID then offers[#offers + 1] = info end
    end
    return offers, count
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
        local count
        offers, count = CommodityResults(search.itemID)
        if search.probe then
            if ah.HasFullCommoditySearchResults and ah.HasFullCommoditySearchResults(search.itemID) == false then More(count)
            else FinishProbe(offers, true) end
            return
        end
        local offer = A.CommodityOffer(OffersFor(row.itemID, offers, true), need, SearchLimit(row.itemID))
        if (not offer or offer.quantity < need) and ah.HasFullCommoditySearchResults
            and ah.HasFullCommoditySearchResults(search.itemID) == false and ah.RequestMoreCommoditySearchResults then
            More(count); return
        end
        if offer then Ready(offer) else A.Invalidate("noOffer") end
    else
        local count = ah.GetNumItemSearchResults(search.key)
        for i = 1, count do
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
            end
        end
        if search.probe then
            if ah.HasFullItemSearchResults and ah.HasFullItemSearchResults(search.key) == false then More(count)
            else FinishProbe(offers, false) end
            return
        end
        local offer = A.SelectStack(OffersFor(row.itemID, offers, false), need, SearchLimit(row.itemID), A.AllowExcessStacks(row))
        if not offer and ah.HasFullItemSearchResults and ah.HasFullItemSearchResults(search.key) == false
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
    if not search or not A.active or not A.houseOpen or A.state ~= "searching" then return end
    if InCombatLockdown() then A.Invalidate("combat"); return end
    if Now() >= search.deadline then A.Invalidate(search.waiting and "auctionNotReady" or "timeout"); return end
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
    Later(15, function() A.Invalidate("timeout") end)
    queryGeneration = queryGeneration + 1
    search.nativeGeneration = queryGeneration
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
    A.Invalidate("searching")
    A.selectedID, A.state = row.itemID, "searching"
    local name = FluxItemClass and FluxItemClass.GetName and FluxItemClass.GetName(row.itemID)
    if A.legacy and not name then A.Invalidate("loading"); return end
    A.search = { itemID = row.itemID, name = name, page = 0, deadline = Now() + 15, probe = probe, row = row,
        key = not A.legacy and C_AuctionHouse.MakeItemKey(row.itemID) or nil }
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
    A.Invalidate("searching")
    A.search = { potionBrowse = true, catalog = {}, page = 0, deadline = Now() + 15, done = done, terms = terms, termKinds = termKinds, termIndex = 1 }
    A.state, A.status = "searching", "potionScan"
    Paint(); SendSearch()
end

-- Planning issues information queries only. A completed probe can supply ready
-- legacy indices only while its exact query/page/identity remains current.
function A.PrepareNext(resume)
    if resume then A.restockRequested = true; A.yielded = nil; rejectedQuotes = {} end
    if not A.restockRequested then return end
    if not A.active or not A.houseOpen or A.transaction or A.foreign or A.yielded then return end
    if A.state == "searching" or A.state == "quoting" or A.state == "classifying" or A.state == "upgrade" then return end
    local dialog = _G.AuctionHouseFrame and _G.AuctionHouseFrame.BuyDialog
    if (dialog and dialog:IsShown()) or (StaticPopup_Visible and
        (StaticPopup_Visible("BUYOUT_AUCTION") or StaticPopup_Visible("BID_AUCTION"))) then A.Invalidate("otherSearch"); return end
    if InCombatLockdown() then A.Invalidate("combat"); return end
    if not A.IsReliable() then A.Invalidate("loading"); return end
    A.Invalidate("changed")
    local job = { planned = {}, attempted = {}, discovered = {}, hidden = {} }
    A.queue = job
    if A.GetVendorCraftTargets and A.HasCraftPlans() then
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
        local rows = A.GetRows(true)
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
            local need = A.Need(row)
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

function A.ScanQueue(resume, scanAll)
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

local function EndTransaction(status, release)
    local t = A.transaction
    if not t then return end
    if status == "bought" then
        A.AcceptReservation(t)
        if A.Followup then A.Followup.Purchased(t) end
    end
    if status == "uncertain" and not t.incomingConfirmed then release = true end
    CancelTimer()
    issuing = false
    if release then A.Release(t.itemID, t.units) end
    if release and A.ReleaseCraftSpend then A.ReleaseCraftSpend(t.craftSpend) end
    A.transaction, A.offer, A.search, A.ownsQuote = nil, nil, nil, false
    A.state, A.status = "idle", status
    A.GetRows(true)
    Paint()
    if status == "bought" or status == "sent" then A.PrepareNext() end
end

local function Submit(row, offer, kind)
    local t = { itemID = row.itemID, quantity = offer.quantity, auctionID = offer.auctionID, kind = kind }
    if A.Followup then t.followup = A.Followup.Capture(row) end
    if A.RecordCraftSpend then t.craftSpend = A.RecordCraftSpend(row, offer.total, offer.quantity) end
    t.units = A.Reserve(row, offer.quantity)
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

function A.Primary()
    if not A.active or not A.houseOpen then A.status = "openAH"; Paint(); return end
    if InCombatLockdown() then A.Invalidate("combat"); return end
    if A.transaction or A.state == "searching" or A.state == "quoting" or A.state == "classifying" or A.state == "upgrade" then return end
    local nativeDialog = _G.AuctionHouseFrame and _G.AuctionHouseFrame.BuyDialog
    if A.foreign or (nativeDialog and nativeDialog:IsShown())
        or (StaticPopup_Visible and (StaticPopup_Visible("BUYOUT_AUCTION") or StaticPopup_Visible("BID_AUCTION"))) then
        A.Invalidate("otherSearch"); return
    end
    A.restockRequested = true
    if not A.IsReliable() then A.Invalidate("loading"); return end
    local row, reason, need = Eligible(A.selectedID)
    if row and A.PotionRowBlocked and A.PotionRowBlocked(row) then
        A.Invalidate(A.IsUpgradeBlacklisted(row.itemID) and "excluded" or "potionData"); return
    end
    local offer = A.offer
    if not row or A.IsCraftOutput(row.itemID) or not offer or offer.itemID ~= row.itemID or Now() - offer.at >= 30 then A.PrepareNext(true); return end
    local cap = A.PurchaseLimit(row.itemID)
    if cap <= 0 then A.Invalidate("overCap"); return end
    if offer.quantity > need then
        if offer.commodity then
            -- Stock/mail may change before BAG_UPDATE reaches this panel. A
            -- commodity can be reduced to the live physical-item shortage;
            -- the excess-stack option applies only to indivisible listings.
            local revised = A.CommodityOffer(OffersFor(row.itemID, CommodityResults(row.itemID), true), need, cap)
            if not revised then A.Invalidate("changed"); return end
            revised.itemID, revised.at = row.itemID, Now()
            A.offer, offer = revised, revised
        elseif not A.AllowExcessStacks(row) then A.Invalidate("changed"); return end
    end
    if offer.total > cap * offer.quantity or (offer.unitPrice and offer.unitPrice > cap) then
        A.Invalidate("overCap"); return
    end
    if not VendorAllowed(row.itemID, offer) then A.Invalidate("overCap"); return end
    if GetMoney() < offer.total then A.Invalidate("money"); return end
    if A.CheckCraftSpend and not A.CheckCraftSpend(row, offer) then A.Invalidate("craftBudget"); return end
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
            A.Invalidate("changed"); A.PrepareNext(); return
        end
        Submit(row, offer, "legacy")
    else
        if not CheckItem(offer) then
            nativeBooks[row.itemID], A.priceBooks[row.itemID] = nil, nil
            A.Invalidate("changed"); A.PrepareNext(); return
        end
        Submit(row, offer, "item")
    end
end

local function RefreshInventory()
    if not A.active or not A.houseOpen then return end
    A.GetRows(true)
    -- Bag/profession/mail pulses repaint live counts without cancelling an
    -- owned search or replacing the player's pending upgrade choices.
    if not A.transaction and A.state == "ready" and A.offer then
        local row = A.FindRow(A.offer.itemID)
        local need = row and A.Need(row)
        if not row or A.IsVendorItem(row.itemID) or (need and need <= 0) then A.Invalidate("changed") end
    end
    -- A user-started operation may have paused for its initial stock snapshot.
    -- Resume that one wait; an idle/finished queue never restarts on a pulse.
    if A.restockRequested and A.status == "loading" and not A.queue and not A.transaction
        and not A.yielded and A.IsReliable() then A.PrepareNext(); return end
    Paint()
end

local function SearchEvent(event, key)
    if not A.active or not A.houseOpen then return end
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
local function Listen(enabled)
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

function A.ShowSession()
    A.active, A.yielded = true, nil
    A.restockRequested = true
    potionScans = {}
    if A.ResetPotionUpgradeChoices then A.ResetPotionUpgradeChoices() end
    A.legacy = A.IsLegacy()
    local owner = A.legacy and _G.AuctionFrame or _G.AuctionHouseFrame
    if owner and owner:IsShown() then A.houseOpen = true end
    if A.houseOpen then InstallHooks() end
    Listen(true)
    A.GetRows(true)
    A.editorID = A.FindRow(A.editorID) and A.editorID or (A.rows[1] and A.rows[1].itemID)
    A.ScanQueue()
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
    if A.applyingAuctionTier then A.GetRows(true); Paint(); return end
    A.GetRows(true)
    A.Invalidate("changed")
    A.ScanQueue()
end

local function RejectQuote(reason, unitPrice, totalPrice)
    local intent = A.intent
    if intent then
        rejectedQuotes[intent.itemID] = { quantity = intent.quantity, at = Now(), reason = reason }
        nativeBooks[intent.itemID], A.priceBooks[intent.itemID] = nil, nil
    end
    if Number(unitPrice) and Number(totalPrice) then A.completedQuote = { at = Now(), unitPrice = unitPrice, total = totalPrice } end
    A.Invalidate(reason)
    A.PrepareNext() -- information only; the rejected gesture cannot buy another SKU
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
        if A.active then A.Invalidate("otherSearch") end
        return
    end
    if A.foreign and A.foreign.kind == "quote" and event == "COMMODITY_PRICE_UNAVAILABLE" then A.foreign = nil end
    if not A.ownsQuote or not A.active or not A.houseOpen or A.state ~= "quoting" then return end
    if event == "COMMODITY_PRICE_UNAVAILABLE" then RejectQuote("noOffer"); return end
    local offer = A.offer
    local intent = A.intent
    local row, reason, need = Eligible(A.selectedID)
    if not row then A.Invalidate(reason); return end
    if A.PotionRowBlocked and A.PotionRowBlocked(row) then
        A.Invalidate(A.IsUpgradeBlacklisted(row.itemID) and "excluded" or "potionData"); return
    end
    if not intent or intent.itemID ~= row.itemID or not offer or intent.quantity ~= offer.quantity
        or Now() - intent.at > 15 or A.foreign or InCombatLockdown() then A.Invalidate("expired"); return end
    local remaining = Number(C_AuctionHouse.GetQuoteDurationRemaining()) or 0
    if remaining <= 0 then A.Invalidate("expired"); return end
    local cap = math.min(intent.cap, A.PurchaseLimit(row.itemID))
    if not Number(unitPrice) or unitPrice <= 0 or not Number(totalPrice) or totalPrice <= 0
        or unitPrice > cap or totalPrice > cap * offer.quantity
        or offer.quantity > need then RejectQuote("overCap", unitPrice, totalPrice); return end
    if not VendorAllowed(row.itemID, { commodity = true, quantity = offer.quantity,
        total = totalPrice, unitPrice = unitPrice }) then RejectQuote("overCap", unitPrice, totalPrice); return end
    if GetMoney() < totalPrice then A.Invalidate("money"); return end
    CancelTimer()
    offer.total, offer.unitPrice, offer.at = totalPrice, unitPrice, Now()
    if not A.CheckCraftSpend(row, offer) then A.Invalidate("craftBudget"); return end
    A.intent = nil -- consume BEFORE the native call, including synchronous events
    A.completedQuote = { at = Now(), unitPrice = unitPrice, total = totalPrice }
    Submit(row, offer, "commodity")
end

local function PurchaseEvent(event, id, quantity)
    local foreign = A.foreign
    if foreign and ((foreign.kind == "commodity" and (event == "COMMODITY_PURCHASE_SUCCEEDED" or event == "COMMODITY_PURCHASE_FAILED"))
        or (foreign.kind == "item" and event == "AUCTION_HOUSE_PURCHASE_COMPLETED" and foreign.auctionID == id)) then A.foreign = nil end
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
    A.houseOpen, A.legacy = true, A.IsLegacy()
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
