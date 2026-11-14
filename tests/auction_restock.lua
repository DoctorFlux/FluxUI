-- Execute the real auction controls/session on all supported API generations.
-- Restricted quote/bid calls require physical input; confirmation needs one intent.
local checks, profiles = 0, 0
local unpack = table.unpack or unpack
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local base = root .. "/Inventory/Restock/Auction/"
local function load(env, ns, name)
    local chunk = assert(loadfile(base .. name .. ".lua", "t", env))
    if setfenv then setfenv(chunk, env) end
    chunk("_FluxUI", ns)
end
local function fixture(legacy, auctionator, syndicator)
    profiles = profiles + 1
    local env = setmetatable({}, { __index = _G }); env._G = env
    local st = { time = 100, timers = {}, calls = {}, hardware = false, reliable = true,
        bags = {}, mail = {}, bank = 0, commodity = true, throttle = true, money = 100000,
        quoteLeft = 30, legacy = legacy, offers = {}, pages = {}, page = 0, errors = {}, frames = 0 }
    local handlers = {}
    local function emit(event, ...)
        local copy = {}; for _, fn in ipairs(handlers[event] or {}) do copy[#copy + 1] = fn end
        for _, fn in ipairs(copy) do fn(event, ...) end
    end
    st.emit = emit
    env.pcall = function(fn, ...)
        st.pcallDepth = (st.pcallDepth or 0) + 1
        local function pack(...) return { n = select("#", ...), ... } end
        local result = pack(pcall(fn, ...))
        st.pcallDepth = st.pcallDepth - 1
        return unpack(result, 1, result.n)
    end
    env.GetTime = function() return st.time end
    env.InCombatLockdown = function() return st.combat == true end
    env.GetMoney = function() return st.money end
    env.UnitFullName = function() return "Tester", "Realm" end
    env.GetMoneyString = function(n) return n .. "c" end
    env.StaticPopupDialogs = {}
    env.StaticPopup_Show = function(which, text, _, data)
        st.popup = { which = which, text = text, data = data }
        st.popupShows = (st.popupShows or 0) + 1
        return st.popup
    end
    env.StaticPopup_Hide = function(which, data)
        local popup = st.popup
        if not popup or popup.which ~= which or (data and popup.data ~= data) then return end
        st.popup = nil
        local hide = env.StaticPopupDialogs[which].OnHide
        if hide then hide(popup, popup.data) end
    end
    function st.decide(accepted, kind)
        local action = accepted == true and "upgrade" or accepted == "blacklist" and "blacklist" or "keep"
        for _, cell in ipairs(env.FluxAuctionRestock.frame.cells) do
            local card = cell.upgrade
            if card and card.proposal and not card.proposal.resolved and (not kind or card.proposal.kind == kind) then
                st.press(card[action]); return
            end
        end
        error("an upgrade decision needs its visible cell control")
    end
    env.geterrorhandler = function() return function(err) st.errors[#st.errors + 1] = err end end
    env.C_Timer = { NewTimer = function(delay, fn)
        local timer = { at = st.time + delay, fn = fn }
        function timer:Cancel() self.cancelled = true end
        st.timers[#st.timers + 1] = timer
        return timer
    end }
    function st.advance(seconds)
        local finish = st.time + seconds
        for _ = 1, 200 do
            local found
            for _, t in ipairs(st.timers) do if not t.cancelled and t.at <= finish and (not found or t.at < found.at) then found = t end end
            if not found then break end
            st.time, found.cancelled = found.at, true
            found.fn()
        end
        st.time = finish
    end
    local events = {
        Register = function(event, fn) handlers[event] = handlers[event] or {}; table.insert(handlers[event], fn); return true end,
        Unregister = function(event, fn)
            for i = #(handlers[event] or {}), 1, -1 do if handlers[event][i] == fn then table.remove(handlers[event], i) end end
        end,
    }
    local ns = { Flux = { Events = events, Cap = { HasLegacyAuctionHouse = function() return legacy end }, Inventory = {} } }
    ns.Flux.Inventory.Professions = { ListAllCachedRecipes = function() return st.recipes or {} end }
    ns.Flux.Inventory.Mail = { GetCount = function(id) return st.mail[id] or 0 end }
    ns.Flux.Inventory.IsMailboxOpen = function() return st.mailboxOpen == true end
    ns.Flux.Inventory.IsBagStorm = function() return st.bagStorm == true end
    ns.Flux.Inventory.Store = { GetCurrentCharacter = function() return { mail = st.storedMail or {} } end }
    ns.Flux.Inventory.Register = function(key, fn) st.inventoryListeners = st.inventoryListeners or {}; st.inventoryListeners[key] = fn end
    ns.Flux.Inventory.Unregister = function(key) if st.inventoryListeners then st.inventoryListeners[key] = nil end end
    st.inventory = ns.Flux.Inventory
    st.flux = ns.Flux
    local settings = {}
    env.FluxRestockSettings = { Get = function() return settings end }
    st.settings = settings
    st.entries = { { itemID = 100, name = "Elixir", texture = 100, target = 10, bagCount = 0, bankCount = 0, restockSource = "consumable" } }
    env.FluxVendorAuto = { GetRestockTargetItems = function()
        -- Deliberately stale snapshot values: purchasing must use live carried counts.
        return st.entries
    end }
    env.FluxRestock = { Inv = {
        IsReliable = function() return st.reliable end,
        GetLiveCount = function(id, opts)
            check(opts.bags == true and opts.bank == false and opts.warband == false and opts.equipped == false, "carried-only live source")
            return st.bags[id] or 0
        end,
    } }
    env.FluxItemClass = { GetName = function(id) return "Item" .. id end,
        GetClassID = function() return 0 end,
        GetSubClassID = function(id)
            local value = st.recipeItems and st.recipeItems[id]
            return type(value) == "number" and value or value and 1 or 0
        end }
    env.FluxRestockItemRegistry = { IsChargeItem = function(id) return id == st.charged end,
        GetItemMaxCharges = function() return st.charges end }
    if auctionator then
        env.Auctionator = setmetatable({}, { __index = function() error("Auctionator internals accessed") end })
    end
    if syndicator then env.Syndicator = { API = {} } end
    local function call(name, purchase, ...)
        st.calls[name] = (st.calls[name] or 0) + 1
        if purchase then check(st.hardware, name .. " requires a player press") end
        if purchase then check((st.pcallDepth or 0) == 0, name .. " must retain the direct native hardware stack") end
        if purchase and st.origin then check(st.origin.enabled ~= false, name .. " issues before disabling the actual input button") end
        st.last = { name = name, args = { ... } }
    end
    local function market(id)
        if id then st.searchedIDs = st.searchedIDs or {}; st.searchedIDs[id] = (st.searchedIDs[id] or 0) + 1 end
        if not st.books or not st.books[id] then return end
        st.marketItem = id
        local book = st.books[id]
        st.offers, st.pages, st.total = book.offers or {}, book.pages or {}, book.total
        st.commodity = book.commodity ~= false
        for _, o in ipairs(st.offers) do o.itemID = id end
    end
    env.C_AuctionHouse = {
        MakeItemKey = function(id) return { itemID = id, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 } end,
        IsThrottledMessageSystemReady = function() return st.throttle end,
        SendSearchQuery = function(key) call("search", false, key); st.key = key; market(key.itemID) end,
        SendBrowseQuery = function(query)
            if st.potionCatalog and query and query.itemClassFilters then
                call("potionBrowse", false, query)
                check((query.filters[1] == env.Enum.AuctionHouseFilter.UsableOnly or query.searchString == "" and #query.filters == 0)
                    and query.itemClassFilters[1].classID == 0 and query.itemClassFilters[1].subClassID == 1,
                    "potion phrase browse is usable-only; name-free fallback remains potion-class scoped")
                check(not query.searchString:find('"', 1, true), "partial potion names contain no literal quotes")
                st.browseTerm, st.browseStep = query.searchString, 1
            else call("foreignBrowse") end
        end,
        GetBrowseResults = function()
            local catalog = st.potionCatalog and st.potionCatalog[st.browseTerm]
            return catalog and (catalog.browsePages and catalog.browsePages[st.browseStep] or catalog.browse) or {}
        end,
        HasFullBrowseResults = function()
            local catalog = st.potionCatalog and st.potionCatalog[st.browseTerm]
            return not catalog or not catalog.browsePages or st.browseStep >= #catalog.browsePages
        end,
        RequestMoreBrowseResults = function() call("moreBrowse"); st.browseStep = st.browseStep + 1 end,
        RefreshItemSearchResults = function() call("refreshItem") end,
        RefreshCommoditySearchResults = function() call("refreshCommodity") end,
        GetNumCommoditySearchResults = function() return #st.offers end,
        GetCommoditySearchResultInfo = function(_, i) return st.offers[i] end,
        GetNumItemSearchResults = function() return #st.offers end,
        GetItemSearchResultInfo = function(_, i) return st.offers[i] end,
        GetQuoteDurationRemaining = function() return st.quoteLeft end,
        HasFullCommoditySearchResults = function() return st.fullResults ~= false end,
        HasFullItemSearchResults = function() return st.fullResults ~= false end,
        RequestMoreCommoditySearchResults = function(id) call("moreCommodity", false, id) end,
        RequestMoreItemSearchResults = function(key) call("moreItem", false, key) end,
        StartCommoditiesPurchase = function(id, q, unitPrice)
            call("quote", true, id, q, unitPrice)
            st.authorizedQuote = { itemID = id, quantity = q }
            if st.syncQuote then emit("COMMODITY_PRICE_UPDATED", st.syncQuote[1], st.syncQuote[2]) end
        end,
        ConfirmCommoditiesPurchase = function(id, q)
            check(st.authorizedQuote and st.authorizedQuote.itemID == id and st.authorizedQuote.quantity == q,
                "confirmation consumes exactly one matching player-authorized quote")
            st.authorizedQuote = nil
            check((st.pcallDepth or 0) == 0, "confirmation is not hidden in pcall")
            call("confirm", false, id, q)
            if st.syncSuccess then emit("COMMODITY_PURCHASE_SUCCEEDED") end
        end,
        CancelCommoditiesPurchase = function() call("cancel") end,
        PlaceBid = function(id, total) call("buyItem", true, id, total) end,
    }
    env.CanSendAuctionQuery = function() return st.throttle end
    env.QueryAuctionItems = function(name, _, _, page, usable, rarity, all, exact, filters)
        if st.potionCatalog and st.potionCatalog[name] and filters then
            call("legacyPotionSearch", false, name, page)
            check(usable == true and all == false and exact == false and filters[1].classID == 0 and filters[1].subClassID == 1,
                "legacy potion search is partial, usable-only, class scoped and never getAll")
            check(not name:find('"', 1, true), "legacy potion search contains no literal quotes")
            local catalog = st.potionCatalog[name]
            st.page, st.pages, st.offers, st.total = page, catalog.pages or {}, catalog.offers or {}, catalog.total
            return
        end
        call("legacySearch", false, name, page)
        check(all == false and exact == true, "exact legacy item query, never getAll")
        st.page = page
        market(st.itemIDsByName and st.itemIDsByName[name] or tonumber(name:match("Item(%d+)")))
    end
    env.SortAuctionItems = function() call("sort") end
    env.PlaceAuctionBid = function(kind, index, total) call("buyStack", true, kind, index, total) end
    env.GetNumAuctionItems = function()
        local page = st.pages[st.page] or st.offers
        return #page, st.total or #page
    end
    env.GetAuctionItemInfo = function(kind, i)
        check(kind == "list", "legacy buyer list only")
        local o = (st.pages[st.page] or st.offers)[i]
        if not o then return end
        return "Item100", 1, o.quantity, 1, true, 1, nil, 1, 1, o.total, 0, o.highBidder,
            nil, o.owned and "Tester" or o.owner or "Seller", o.owned and "Tester-Realm" or o.owner or "Seller-Realm",
            0, o.itemID or st.marketItem or 100, o.complete ~= false
    end
    env.GetAuctionItemLink = function(_, i)
        local o = (st.pages[st.page] or st.offers)[i]
        return o and (o.link or "item:" .. (o.itemID or st.marketItem or 100))
    end
    env.hooksecurefunc = function(target, name, fn)
        if type(target) == "string" then fn, name, target = name, target, env end
        check(name ~= "StartCommoditiesPurchase" and name ~= "ConfirmCommoditiesPurchase" and name ~= "PlaceBid" and name ~= "PlaceAuctionBid", "restricted purchase APIs remain native and unhooked")
        local original = target[name]
        check(type(original) == "function", "post-hook real native entry")
        target[name] = function(...)
            local values = { original(...) }; fn(...); return unpack(values)
        end
    end
    -- Explicit frame surface. Unknown widget methods fail rather than becoming no-ops.
    local m = {}
    local function widget(kind, parent)
        st.frames = st.frames + 1
        return setmetatable({ kind = kind, parent = parent, scripts = {}, shown = true, enabled = true }, { __index = m })
    end
    function m:SetScript(key, fn) self.scripts[key] = fn end
    function m:HookScript(key, fn)
        local previous = self.scripts[key]
        self.scripts[key] = function(self, ...)
            if previous then previous(self, ...) end
            fn(self, ...)
        end
    end
    function m:Fire(key, ...) if self.scripts[key] then return self.scripts[key](self, ...) end end
    function m:Show() local old = self.shown; self.shown = true; if not old then self:Fire("OnShow") end end
    function m:Hide() local old = self.shown; self.shown = false; if old then self:Fire("OnHide") end end
    function m:IsShown() return self.shown end
    function m:SetShown(value) if value then self:Show() else self:Hide() end end
    function m:SetEnabled(value) self.enabled = value end
    function m:IsEnabled() return self.enabled end
    function m:SetText(value) self.text = value end
    function m:GetText() return self.text or "" end
    function m:SetChecked(value) self.checked = value end
    function m:GetChecked() return self.checked end
    function m:ClearFocus() local old = self.focus; self.focus = false; if old then self:Fire("OnEditFocusLost") end end
    function m:SetFocus() self.focus = true end
    function m:HasFocus() return self.focus == true end
    function m:GetName() return self.name end
    function m:GetWidth() return self.width or 800 end
    function m:GetHeight() return self.height or (self.kind == "Button" and 24 or 600) end
    function m:SetWidth(value) self.width = value end
    function m:SetHeight(value) self.height = value end
    function m:SetSize(width, height) self.width, self.height = width, height end
    function m:SetPoint(...) self.point = { ... } end
    function m:ClearAllPoints() self.point = nil end
    function m:SetScrollChild(child) self.scrollChild = child end
    function m:GetVerticalScroll() return self.verticalScroll or 0 end
    function m:SetVerticalScroll(value) self.verticalScroll = value; self:Fire("OnVerticalScroll", value) end
    function m:EnableMouseWheel(value) self.mouseWheel = value end
    function m:SetTexture(value) self.texture = value end
    function m:GetStringHeight() local _, lines = (self.text or ""):gsub("\n", ""); return (lines + 1) * 12 end
    function m:GetID() return self.id end
    function m:SetID(id) self.id = id end
    function m:GetFont() return "font", 12, "" end
    function m:GetStringWidth() return #(tostring(self.text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) * 6 end
    function m:GetFrameLevel() return 10 end
    function m:SetFrameLevel() end
    function m:GetChildren() return end
    function m:GetRight() return 300 end
    function m:IsObjectType(kind) return self.kind == kind end
    function m:RegisterEvent() end
    function m:UnregisterEvent() end
    function m:SetParent(parent) self.parent = parent end
    function m:CreateFontString() return widget("FontString", self) end
    function m:CreateTexture() return widget("Texture", self) end
    for _, name in ipairs({ "SetJustifyH", "SetJustifyV", "SetClampedToScreen",
        "SetFrameStrata", "EnableMouse", "SetMovable", "RegisterForDrag", "StartMoving", "StopMovingOrSizing",
        "SetBackdrop", "SetBackdropColor", "SetAutoFocus", "SetNumeric", "SetMaxLetters", "HighlightText",
        "SetFont", "SetFontObject", "SetWordWrap", "SetAllPoints", "SetTexCoord", "SetDesaturated", "SetAlpha", "SetColorTexture", "SetBackdropBorderColor", "RegisterForClicks" }) do m[name] = function() end end
    env.UIParent = widget("Frame")
    env.AuctionFrame, env.AuctionHouseFrame = widget("Frame"), widget("Frame")
    env.AuctionFrame.name, env.AuctionHouseFrame.name = "AuctionFrame", "AuctionHouseFrame"
    env.CreateFrame = function(kind, name, parent, template)
        local f = widget(kind, parent)
        f.name = name
        if name then env[name] = f end
        if template == "UICheckButtonTemplate" then f.Text = widget("FontString", f) end
        if template == "InputBoxTemplate" then
            f:SetScript("OnEditFocusLost", function(self) self.nativeFocusLost = true end)
        end
        if template == "UIPanelScrollFrameTemplate" then
            f:SetScript("OnVerticalScroll", function(self) self.nativeVerticalScroll = true end)
            f:SetScript("OnScrollRangeChanged", function(self) self.nativeScrollRange = true end)
        end
        return f
    end
    env.GameTooltip = { SetOwner = function() end, AddLine = function() end, SetItemByID = function() end, Show = function() end, Hide = function() end }
    env.SlashCmdList = {}
    env.PanelTemplates_SelectTab = function(tab) check(tab ~= nil, "native selection has a registered tab"); tab.selected = true end
    env.PanelTemplates_DeselectTab = function(tab) check(tab ~= nil, "native deselection has a registered tab"); tab.selected = false end
    env.PanelTemplates_SetNumTabs = function(owner, count) owner.numTabs = count end
    env.PanelTemplates_TabResize = function() end
    env.PanelTemplates_SetTab = function(owner, id)
        owner.selectedTab = id
        for i = 1, owner.numTabs do
            local tab = owner.Tabs and owner.Tabs[i] or env[owner:GetName() .. "Tab" .. i]
            if i == id then env.PanelTemplates_SelectTab(tab) else env.PanelTemplates_DeselectTab(tab) end
        end
    end
    for _, owner in ipairs({ env.AuctionFrame, env.AuctionHouseFrame }) do
        owner.Tabs, owner.tabsForDisplayMode, owner.numTabs = {}, {}, 3
        for i = 1, 3 do
            local tab = env.CreateFrame("Button", owner:GetName() .. "Tab" .. i, owner)
            tab:SetID(i); owner.Tabs[i] = tab
            tab:SetScript("OnClick", function() env.PanelTemplates_SetTab(owner, i) end)
        end
    end
    env.AuctionHouseFrame.SetDisplayMode = function(owner, mode)
        owner.displayMode = mode
        if owner.tabsForDisplayMode[mode] then env.PanelTemplates_SetTab(owner, owner.tabsForDisplayMode[mode]) end
        for _, name in ipairs(mode) do if owner[name] then owner[name]:Show() end end
    end
    local gridChunk = assert(loadfile(root .. "/ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua", "t", env))
    if setfenv then setfenv(gridChunk, env) end
    gridChunk("_FluxUI", ns)
    for _, name in ipairs({ "FluxAuctionRestockLocale", "FluxAuctionRestockData", "FluxAuctionRestockPrices", "FluxAuctionRestockCraft", "FluxAuctionRestockPotions", "FluxAuctionRestock", "FluxAuctionRestockUI" }) do load(env, ns, name) end
    local A = env.FluxAuctionRestock
    function st.press(control)
        control = control or A.frame.primary
        if not control.enabled then return end
        st.hardware, st.origin = true, control; control:Fire("OnClick"); st.hardware, st.origin = false, nil
    end
    function st.result()
        if legacy then emit("AUCTION_ITEM_LIST_UPDATE")
        elseif A.search and A.search.potionBrowse then emit("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
        elseif st.commodity then emit("COMMODITY_SEARCH_RESULTS_UPDATED", A.search and A.search.itemID or 100)
        else emit("ITEM_SEARCH_RESULTS_UPDATED", st.key) end
    end
    env.ERR_AUCTION_BID_PLACED = "Bid placed."
    function st.legacyReceipt()
        emit("CHAT_MSG_SYSTEM", env.ERR_AUCTION_BID_PLACED)
        emit("AUCTION_ITEM_LIST_UPDATE")
    end
    function st.drain()
        for _ = 1, 100 do
            if A.state == "classifying" then st.advance(0.25)
            elseif A.state == "searching" then st.result()
            elseif A.state == "upgrade" and st.upgradeChoice ~= nil then st.decide(st.upgradeChoice); st.advance(0)
            else return end
            if st.fullResults == false then return end
        end
        error("automatic queue did not settle")
    end
    function st.start(offers)
        A.SetMaxPrice(100, 100)
        st.offers = offers or { { itemID = 100, quantity = 20, unitPrice = 50, numOwnerItems = 0 } }
        emit("AUCTION_HOUSE_SHOW")
        A.Toggle()
        st.drain()
    end
    function st.reset()
        A.ResetCraftPlans()
        if A.frame and A.frame:IsShown() then A.frame:Hide() end
        emit("AUCTION_HOUSE_CLOSED")
        st.advance(20)
        settings.auctionRestock = nil
        st.bags, st.mail, st.pages, st.offers, st.calls = {}, {}, {}, {}, {}
        st.mailboxOpen, st.bagStorm, st.storedMail = nil, nil, nil
        st.inventory.snapshots = nil
        st.searchedIDs = nil
        st.potionCatalog = nil
        if A.ResetPotionDiscovery then A.ResetPotionDiscovery() end
        st.books, st.marketItem, st.recipes, st.recipeItems = nil, nil, nil, nil
        st.total, st.syncQuote, st.syncSuccess, st.combat, st.charged, st.fullResults = nil, nil, nil, false, nil, true
        st.reliable, st.throttle, st.money, st.quoteLeft = true, true, 100000, 30
        A.selectedID, A.editorID, st.authorizedQuote = nil, nil, nil
        st.entries = { { itemID = 100, name = "Elixir", target = 10, bankCount = 0, restockSource = "consumable" } }
    end
    function st.realTargets()
        env.FluxRestockTiers, env.FluxConsumableBest = nil, nil
        settings.restockItems = { [100] = { targetQuantity = 10 }, [101] = { targetQuantity = 5, countBank = true } }
        env.FluxItemClass.GetIcon = function(id) return id end
        env.FluxRestock.Inv.Bank = { GetCount = function() return 2 end, RegisterBankClose = function() end }
        env.FluxNCConsumables = { GetRestockUIItemIDs = function() return { 100, 102 } end,
            GetPresetRestockTarget = function(id) return id == 100 and 12 or 7 end }
        local chunk = assert(loadfile(root .. "/Inventory/Restock/Core/FluxRestockList.lua", "t", env))
        if setfenv then setfenv(chunk, env) end
        chunk("_FluxUI", ns)
        -- Charge detection has its own existing tests; isolate target ownership here.
        env.FluxRestockItemRegistry.IsChargeItem = function() return false end
    end
    return A, st, env
end

if FLUX_AH_FIXTURE_EXPORT then return fixture end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        local A, st, env = fixture(legacy, auctionator, syndicator)
        check(A.ParsePrice("1g 50s 75c") == 15075 and A.ParsePrice("75C") == 75, "explicit unit input")
        check(A.ParsePrice("") == 0 and A.ParsePrice("0") == 0 and A.PurchaseLimit(100) == math.huge, "zero cap means unlimited")
        for _, bad in ipairs({ "1", "-1g", "1.5g", "2g3g", "nan", "1e6g", "1g junk", "100000001g" }) do check(A.ParsePrice(bad) == nil, "reject malformed price " .. bad) end
        check(not A.SetMaxPrice(100, math.huge) and not A.SetMaxPrice(100, 0/0) and not A.SetMaxPrice(100, -1), "finite price validation")
        local pick = A.SelectStack({ { quantity = 6, total = 6 }, { quantity = 10, total = 80 }, { quantity = 20, total = 20 } }, 10, 100, true)
        check(pick.quantity == 10, "exact stack preferred to undershoot and surplus")
        check(A.SelectStack({ { quantity = 20, total = 20 } }, 10, 100, false) == nil, "no implicit surplus")
        check(A.SelectStack({ { quantity = 20, total = 20 }, { quantity = 11, total = 55 } }, 10, 100, true).quantity == 11, "smallest surplus")
        check(A.SelectStack({ { quantity = 3, total = 301 } }, 3, 100, false) == nil, "fractional unit ceiling cannot round down")
        check(A.SelectStack({ { quantity = 3, total = 300 } }, 3, 100, false).total == 300, "exact cap accepted")
        check(A.SelectStack({ { quantity = 10, total = 0 }, { quantity = 10, total = 1, owned = true } }, 10, 100, true) == nil, "no bid-only/own purchase")
        local ladder = A.CommodityOffer({ { unitPrice = 101, quantity = 100 }, { unitPrice = 50, quantity = 4, numOwnerItems = 2 },
            { unitPrice = 75, quantity = 20 }, { unitPrice = 1, quantity = 20, containsAccountItem = true } }, 10, 100)
        check(ladder.quantity == 10 and ladder.total == 700, "exact commodity quantity and owned/account filtering")

        if legacy then
            st.start({ { quantity = 20, total = 200 } })
            check(A.offer == nil and not st.calls.buyStack, "need10/stack20 skipped by default")
            A.Settings().allowExcessStacks = true
            st.press(); st.drain()
            check(A.offer and A.offer.quantity == 20 and A.frame.status.text:find("10 extra", 1, true), "surplus quantity and total exposed before click")
            st.press()
            check(st.calls.buyStack == 1 and st.last.args[3] == 200, "one press one whole-stack buyout")
            st.press(); check(st.calls.buyStack == 1, "pending transaction blocks repeats")
            st.legacyReceipt()
            check(A.Settings().pending[100].units == 20, "whole purchase reserved pending mail")
            st.press(); st.drain(); check(st.calls.buyStack == 1, "reservation prevents overfill repeat")
            st.reset()
            st.pages[0] = { { quantity = 20, total = 100 } }
            st.pages[1] = { { quantity = 10, total = 100 } }; st.total = 51
            st.start({})
            check(A.offer and A.offer.quantity == 10 and st.page == 1, "search later pages for fitting stack")
            st.pages[1][1].owner = "ChangedSeller"
            st.press()
            check(not st.calls.buyStack, "legacy changed identity rejected at click")
            st.reset()
            st.start({ { quantity = 5, total = 50, itemID = 999 }, { quantity = 10, total = 100, owned = true } })
            check(not A.offer, "legacy exact item and own listing exclusion")
        else
            st.start()
            check(A.offer and A.offer.quantity == 10 and A.offer.total == 500, "modern exact deficit at price ladder")
            check(not st.calls.quote and not st.calls.confirm, "search events never start/confirm a purchase")
            st.syncQuote = { 50, 500 }
            st.press()
            check(A.state == "buying" and st.calls.quote == 1 and st.calls.confirm == 1, "one press quotes and confirms exactly one purchase")
            st.press()
            check(st.calls.confirm == 1 and st.last.args[2] == 10, "next press confirms exact quantity")
            st.emit("COMMODITY_PURCHASE_SUCCEEDED")
            check(A.Settings().pending[100].units == 10 and A.state == "idle", "accepted purchase counts pending mail")
            st.press(); st.drain()
            check(st.calls.quote == 1 and st.calls.confirm == 1 and A.Settings().pending[100].units == 10,
                "an explicit scan can refresh prices but cannot rebuy a target covered by pending mail")
            st.bags[100] = 10; A.GetRows(true)
            check(not A.Settings().pending[100] and A.rows[1].need == 0, "delivery reconciles reservation without double credit")
            st.reset(); st.start(); st.press()
            st.emit("COMMODITY_PRICE_UPDATED", 101, 1001)
            check(not A.offer and not st.calls.confirm, "quote over cap cannot buy")
            st.reset(); st.start(); st.press(); st.emit("COMMODITY_PRICE_UPDATED", 75, 750)
            check(st.calls.confirm == 1 and A.Settings().pending[100].units == 10, "changed price within limit confirms the same authorized quantity")
            st.emit("COMMODITY_PRICE_UPDATED", 75, 750)
            check(st.calls.confirm == 1, "duplicate quote cannot spend the same press twice")
            st.reset(); st.start(); st.press(); st.quoteLeft = 0; st.emit("COMMODITY_PRICE_UPDATED", 50, 500)
            check(not st.calls.confirm, "expired quote rejected")
            st.reset(); st.start(); st.press(); st.emit("COMMODITY_PRICE_UPDATED", 50, 500); st.press()
            st.emit("COMMODITY_PURCHASE_FAILED")
            check(not A.Settings().pending[100] and A.state == "idle", "unconfirmed failure cannot become permanent incoming stock")
            st.reset(); st.start()
            st.hardware = true; env.C_AuctionHouse.StartCommoditiesPurchase(999, 1); st.hardware = false
            st.emit("COMMODITY_PRICE_UPDATED", 50, 50)
            local cancelled = st.calls.cancel or 0
            A.frame:Hide()
            check((st.calls.cancel or 0) == cancelled and not st.calls.confirm, "foreign quote not cancelled or purchased on cleanup")
            st.reset(); st.start(); st.press(); st.emit("COMMODITY_PRICE_UPDATED", 50, 500); st.press()
            st.hardware = true; env.C_AuctionHouse.StartCommoditiesPurchase(999, 1); st.hardware = false
            st.emit("COMMODITY_PRICE_UPDATED", 50, 50)
            st.emit("COMMODITY_PURCHASE_FAILED"); st.advance(16)
            check(not A.Settings().pending[100] and not A.transaction, "unconfirmed transaction ends without inventing confirmed incoming stock")
            st.reset(); st.commodity = false
            local key = env.C_AuctionHouse.MakeItemKey(100)
            st.start({ { itemKey = key, auctionID = 55, quantity = 10, buyoutAmount = 50 } })
            check(A.offer and A.offer.auctionID == 55 and A.offer.quantity == 1 and A.offer.availableQuantity == 10,
                "modern noncommodity row selects one auction from its grouped availability")
            st.offers[1].quantity = 1
            st.press(); st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 999)
            check(A.transaction and A.transaction.quantity == 1,
                "remaining grouped availability can shrink before one-item bid; unrelated receipt ignored")
            st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 55)
            check(not A.transaction and A.Settings().pending[100].units == 1, "matching item purchase receives one physical item")
            st.reset(); st.commodity = false
            st.start({ { itemKey = key, auctionID = 55, quantity = 10, buyoutAmount = 500 } })
            check(not A.offer, "grouped availability cannot divide the per-item buyout below its unit-price limit")
            for _, invalid in ipairs({ false, 0, -1, 0.5, math.huge }) do
                st.reset(); st.commodity = false
                local quantity = invalid or nil
                st.start({ { itemKey = key, auctionID = 55, quantity = quantity, buyoutAmount = 50 } })
                check(not A.offer, "missing or invalid item-group availability cannot prepare a bid")
                st.reset(); st.commodity = false
                st.start({ { itemKey = key, auctionID = 55, quantity = 2, buyoutAmount = 50 } })
                st.offers[1].quantity = quantity
                st.press()
                check(not st.calls.buyItem and not A.transaction,
                    "missing or invalid item-group availability at click cannot reserve or bid")
            end
            st.commodity = true
            st.reset(); st.fullResults = false
            st.start({ { itemID = 100, quantity = 2, unitPrice = 50 } })
            check(A.state == "searching" and st.calls.moreCommodity == 1, "incomplete commodity quantity requests more rows")
            st.result()
            check(st.calls.moreCommodity == 1, "duplicate partial notification cannot duplicate request")
            st.offers[2] = { itemID = 100, quantity = 8, unitPrice = 75 }
            st.fullResults = true; st.drain()
            check(A.offer and A.offer.quantity == 10 and A.offer.total == 700, "later commodity rows complete exact quantity")
            st.reset(); st.fullResults = false; st.start({})
            st.result(); st.advance(16)
            check(A.state == "idle" and A.status == "timeout", "duplicate incomplete rows retain bounded timeout")
            st.reset(); st.start(); A.Invalidate()
            st.quoteLeft = 0 -- An external request may still be waiting for its quote.
            env.AuctionHouseFrame.BuyDialog = env.CreateFrame("Frame", nil, env.AuctionHouseFrame)
            st.hardware = true; env.C_AuctionHouse.StartCommoditiesPurchase(999, 1); st.hardware = false
            local searches = st.calls.search
            st.press()
            check(st.calls.search == searches and A.status == "otherSearch", "pending native quote dialog cannot be overwritten")
            env.C_AuctionHouse.CancelCommoditiesPurchase()
            env.AuctionHouseFrame.BuyDialog:Hide()
            st.press()
            check(st.calls.search == searches + 1, "external cancel hands search back")
            st.reset(); st.syncQuote, st.syncSuccess = { 50, 500 }, true
            st.start(); st.press(); st.press(); st.drain()
            check(not A.transaction and A.state == "idle" and A.Settings().pending[100].units == 10
                and st.calls.quote == 1 and st.calls.confirm == 1, "synchronous quote/receipt preserves atomic reservation across a later read-only scan")
        end

        st.reset()
        st.start(legacy and { { quantity = 10, total = 100 } } or nil)
        if legacy then env.QueryAuctionItems("Other", nil, nil, 0, false, nil, false, true)
        else env.C_AuctionHouse.SendBrowseQuery({}) end
        check(A.state == "idle" and A.status == "otherSearch", "foreign UI search yields ownership")
        st.reset()
        st.start(legacy and { { quantity = 10, total = 100 } } or nil)
        A.SetMaxPrice(100, 1); st.press(); st.result()
        check(not st.calls.buyStack and not st.calls.confirm, "changed lower cap invalidates ready offer")
        st.reset()
        st.start(legacy and { { quantity = 10, total = 100 } } or nil)
        local controls = A.frame.currencyGroup
        local box = controls.copper
        controls.gold:SetText("0"); controls.silver:SetText("0")
        box:SetFocus(); box:SetText("1"); st.press()
        check(A.GetMaxPrice(100) == 1 and not st.calls.buyStack and not st.calls.confirm, "focused lower price is committed before purchase button")
        box:SetFocus(); box:SetText("invalid"); box:Fire("OnEnterPressed")
        check(A.GetMaxPrice(100) == 1 and A.state == "idle", "invalid edit cannot preserve a buyable old offer")
        box:SetFocus(); box:SetText("2"); box:Fire("OnEscapePressed")
        check(A.GetMaxPrice(100) == 1 and not box:HasFocus() and box.nativeFocusLost, "Escape restores saved ceiling and preserves native input focus lifecycle")
        st.reset()
        st.start(legacy and { { quantity = 10, total = 100 } } or nil)
        st.bags[100] = 10; st.press()
        check(not st.calls.buyStack and not st.calls.quote, "live carried stock wins over stale provider/list counts")
        st.reset()
        st.start(legacy and { { quantity = 10, total = 100 } } or nil)
        st.combat = true; st.press()
        check(not st.calls.buyStack and not st.calls.quote, "combat blocks action")
        st.reset()
        st.start(legacy and { { quantity = 10, total = 100 } } or nil)
        st.reliable = false; st.press()
        check(not st.calls.buyStack and not st.calls.quote, "unreliable inventory blocks action")
        st.reset()
        st.start(legacy and { { quantity = 10, total = 100 } } or nil)
        st.money = 0; st.press()
        check(not st.calls.buyStack and not st.calls.quote, "insufficient money")

        st.reset()
        A.SetMaxPrice(100, 100); st.throttle = false; st.emit("AUCTION_HOUSE_SHOW"); A.Toggle()
        st.advance(16)
        check(A.state == "idle" and A.status == "auctionNotReady" and not st.calls.search and not st.calls.legacySearch, "bounded throttle wait reports native unavailability without query/purchase")
        local timers = #st.timers
        st.advance(100)
        check(#st.timers == timers, "no idle timer loop")

        st.reset()
        st.settings.itemPrices = { [100] = 1 }
        check(#A.GetRows(true) == 1, "remembered price does not prove unlimited vendor stock")
        st.settings.itemPrices = nil; st.settings.vendorItems = { [100] = true }
        check(#A.GetRows(true) == 1, "untyped vendor witness remains unclassified")
        st.settings.merchantSources = { [100] = { unlimited = true, unitPrice = 0 } }
        check(#A.GetRows(true) == 0, "observed free unlimited vendor stock excluded")
        st.settings.vendorItems, st.settings.merchantSources = nil, nil
        st.entries[1].target, st.entries[1].countBank, st.entries[1].bankCount = 10, true, 4
        st.bags[100] = 2
        check(A.GetRows(true)[1].need == 4, "respect count-bank preference")
        st.charged, st.charges = 100, 5
        check(A.GetRows(true)[1].need == 1, "charge target converted to physical copies")
        st.charges = nil
        check(A.GetRows(true)[1].need == nil, "unknown charge capacity cannot overbuy")
        st.charged = nil
        env.FluxConsumableBest = { GetBestRef = function() return { itemID = 100 } end }
        env.FluxRestockTiers = { GetTierCount = function() return 7 end, GetBankCountForKind = function() return 2 end }
        st.entries = { { isTierRestock = true, tierKind = "bandage", target = 12, countBank = true, name = "Bandage" } }
        check(A.GetRows(true)[1].need == 3, "tier reference uses qualifying aggregate and bank stock")

        st.reset(); env.FluxConsumableBest = nil
        st.start(legacy and { { quantity = 10, total = 100 } } or nil)
        if not legacy then st.press(); st.emit("COMMODITY_PRICE_UPDATED", 50, 500) end
        st.press(); st.emit("AUCTION_HOUSE_CLOSED"); st.advance(20)
        check(not A.Settings().pending[100] and not A.transaction, "close/timeout does not persist an unacknowledged attempt as mail")
        local store = A.Settings()
        A.ShowSession(); A.GetRows(true)
        check(A.rows[1].need == 10 and store == A.Settings(), "unconfirmed attempt no longer blocks a later restock session")
        st.mail[100] = 10; A.GetRows(true)
        check(A.rows[1].need == 0 and A.rows[1].pending == 10 and not A.Settings().pending[100], "observed inbox delivery replaces in-transit reservation automatically")
        check(#st.errors == 0, "no native API exceptions in supported paths")
        st.reset()
        st.realTargets()
        A.SetMaxPrice(100, 88)
        local mapped = {}
        for _, row in ipairs(A.GetRows(true)) do mapped[row.itemID] = row end
        check(mapped[100].target == 12 and mapped[100].restockSource == "consumable", "real target owner preserves active preset precedence")
        check(mapped[101].target == 5 and mapped[101].countBank and mapped[101].need == 3, "real manual target and bank preference")
        check(mapped[102].target == 7 and #A.rows == 3, "real preset/manual merge deduplicates IDs")
        env.FluxRestockList.RecordMerchantPrices({ [100] = { unitPrice = 0, numAvailable = -1 }, [102] = { unitPrice = 10, numAvailable = -1 } })
        check(A.IsVendorItem(100) and A.IsVendorItem(102) and #A.GetRows(true) == 1, "real merchant memory excludes free and priced vendor stock")
        check(st.settings.restockItems[100].targetQuantity == 10 and A.GetMaxPrice(100) == 88, "vendor exclusion preserves targets and auction preference")
    end end
end
print(("Auction restock: %d checks PASS; %d client/provider/addon profiles; native purchases/input/taint/pixels/FPS NOT RUN"):format(checks, profiles))
