-- Production merchant index/queue replay. Native purchases and timing are modeled.
local source, measure = "Inventory/Restock/Vendor/FluxVendorBuy.lua", false
local stockOnly, identityOnly = false, false
for i, value in ipairs(arg or {}) do
    if value == "--source" then source = assert(arg[i + 1]) end
    if value == "--measure" then measure = true end
    if value == "--stock-only" then stockOnly = true end
    if value == "--identity-only" then identityOnly = true end
end
assert(not (stockOnly and identityOnly), "choose one focused scenario group")
local checks, failures = 0, 0
local function check(value, label)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. label) end
end
local function boot(modern, links, size, tier, opts)
    opts = opts or {}
    local h = { now = 0, frames = {}, timers = {}, shop = {}, bags = {}, calls = {},
        money = 100000, wrong = 0, missing = 0, wrongCost = 0, idReads = 0, linkReads = 0,
        pulses = 0, merchant = true, open = false, reported = {}, size = size,
        rejected = 0, accounted = 0, infoReads = 0, tokens = opts.tokens or 0 }
    h.money = opts.money or h.money
    for i = 1, size do h.shop[i] = { id = 100000 + i, price = opts.price or 5,
        stock = opts.stock, pack = opts.pack or 1 } end
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.FluxVendorAuto = { EnsureSettings = function() end }
    env.FluxRestockSettings = { Get = function() return {
        autoRepair = false, autoSellGray = false, autoRestock = false } end }
    env.FluxRestock = { Inv = {
        SetMerchantOpen = function(open) h.open = open end,
        IsAutomationQuiet = function() return false end,
        NotifyAutomationPulse = function() h.pulses = h.pulses + 1 end,
    } }
    env.FluxRestockList = { EntryNeed = function(entry) return entry.target - (h.bags[entry.itemID] or 0) end }
    if tier then
        env.FluxRestockTiers = { GetTierCount = function() return h.bags[100009] or 0 end }
    end
    env.FluxVendorAuto.GetRestockTargetItems = function()
        local entries = {}
        local index = env.FluxVendorAuto.GetMerchantItemIndex(false)
        for i = 1, size do
            local id = 100000 + i
            local entry = { itemID = id, target = opts.target or 1, vendorSold = index[id] ~= nil }
            if tier and i == 9 then
                entry.isTierRestock, entry.tierKind, entry.vendorHasStock = true, "food", index[id] ~= nil
                entry.merchantSlot, entry.merchantItemID = index[id] and index[id].slot, id
            end
            entries[#entries + 1] = entry
            if opts.duplicate then entries[#entries + 1] = {
                itemID = id, target = opts.target or 1, vendorSold = index[id] ~= nil } end
        end
        return entries
    end
    env.GetMoney = function() return h.money end
    env.MerchantFrame = { IsShown = function() return h.merchant end }
    env.IsShiftKeyDown = function() return false end
    env.GetTime = function() return h.now end
    env.GetMerchantNumItems = function() return h.size end
    env.GetMerchantItemMaxStack = function() return opts.maxStack or 1 end
    env.GetMerchantItemLink = function(slot)
        h.linkReads = h.linkReads + 1
        local item = h.shop[slot]
        return item and ("item:" .. item.id)
    end
    if not links then
        env.GetMerchantItemID = function(slot)
            h.idReads = h.idReads + 1
            local item = h.shop[slot]
            return item and tostring(item.id)
        end
    end
    local function info(slot)
        h.infoReads = h.infoReads + 1
        local item = h.shop[slot]
        if item then return "Item", 1, item.price, item.pack or 1,
            item.stock == nil and -1 or item.stock, opts.purchasable ~= false, true, opts.alt ~= nil end
    end
    if modern then
        env.C_MerchantFrame = { GetItemInfo = function(slot)
            local name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, hasExtendedCost = info(slot)
            if name then return { name = name, texture = texture, price = price, stackCount = stackCount,
                numAvailable = numAvailable, isPurchasable = isPurchasable, isUsable = isUsable,
                hasExtendedCost = hasExtendedCost } end
        end }
    else env.GetMerchantItemInfo = info end
    if opts.alt then
        env.GetMerchantItemCostInfo = function() return 1 end
        env.GetMerchantItemCostItem = function() return 1, 2, opts.alt .. ":77" end
        env.C_CurrencyInfo = { GetCurrencyInfo = function() return { quantity = h.tokens } end }
        env.GetItemCount = function() return h.tokens end
    end
    env.BuyMerchantItem = function(slot, qty)
        local item = h.shop[slot]
        h.calls[#h.calls + 1] = { slot = slot, qty = qty, id = item and item.id }
        if not item then h.missing = h.missing + 1; return end
        local cost = item.price * qty / (item.pack or 1)
        local tokenCost = opts.alt and (2 * qty / item.pack) or 0
        if (item.stock and item.stock >= 0 and qty > item.stock)
            or cost > h.money or tokenCost > h.tokens then
            h.rejected = h.rejected + 1
            return
        end
        if item.id < 100001 or item.id > 100000 + size then
            h.wrong = h.wrong + 1; h.wrongCost = h.wrongCost + cost
        end
        h.money = h.money - cost
        h.tokens = h.tokens - tokenCost
        if item.stock and item.stock >= 0 then item.stock = item.stock - qty end
        h.bags[item.id] = (h.bags[item.id] or 0) + qty
        if #h.calls == 1 and h.afterFirst then h.afterFirst() end
    end
    env.C_Timer = { After = function(delay, fn)
        h.timers[#h.timers + 1] = { at = h.now + math.max(delay, 0.001), fn = fn }
    end }
    env.CreateFrame = function()
        local f = { events = {} }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:SetScript(_, fn) self.onEvent = fn end
        h.frames[#h.frames + 1] = f
        return f
    end
    env.print = function(value) h.reported[#h.reported + 1] = value end
    function h:event(event, ...)
        for _, f in ipairs(self.frames) do if f.events[event] then f.onEvent(f, event, ...) end end
    end
    function h:advance(seconds)
        local target = self.now + seconds
        for _ = 1, 1000 do
            local nextIndex, nextTimer
            for i, timer in ipairs(self.timers) do
                if timer.at <= target and (not nextTimer or timer.at < nextTimer.at) then nextIndex, nextTimer = i, timer end
            end
            if not nextTimer then self.now = target; return end
            table.remove(self.timers, nextIndex); self.now = nextTimer.at; nextTimer.fn()
        end
        error("timer queue did not settle")
    end
    assert(loadfile(source, "t", env))("_FluxUI", {})
    h.fv, h.env = env.FluxVendorAuto, env
    local addCopper = h.fv.AddBatchCopper
    h.fv.AddBatchCopper = function(copper) h.accounted = h.accounted + copper; addCopper(copper) end
    h:event("MERCHANT_SHOW"); h:advance(0.6)
    h.fv.GetMerchantItemIndex(false); h:advance(0.05)
    check(h.open and #h.calls == 0, "startup/index alone make no purchases")
    return h
end

if not stockOnly then
for _, modern in ipairs({ false, true }) do
    for _, links in ipairs({ false, true }) do
        local label = (modern and "modern" or "legacy") .. (links and "_link" or "_id")
        for _, rebuilt in ipairs({ false, true }) do
            for _, tier in ipairs({ false, true }) do
                local name = label .. (rebuilt and "_rebuilt" or "_debounced") .. (tier and "_tier" or "_manual")
                local h = boot(modern, links, 12, tier)
                h.fv.DoRestockManual()
                check(#h.calls == 8 and h.fv.IsRestockBuyActive(), name .. " first pass keeps eight-call budget")
                for i = 1, 8 do check(h.bags[100000 + i] == 1, name .. " initial target bought once " .. i) end
                h.shop[13], h.shop[9], h.shop[10] = h.shop[9], { id = 999999, price = 800 }, nil
                h.size = 13
                h:event("MERCHANT_UPDATE")
                if rebuilt then h:advance(0.3) end
                local calls, idReads, linkReads, money = #h.calls, h.idReads, h.linkReads, h.money
                h:event("BAG_UPDATE_DELAYED")
                print(("METRIC %s wrong=%d unavailable=%d wrong_cost=%d calls=%d id_reads=%d link_reads=%d spent=%d frames=%d")
                    :format(name, h.wrong, h.missing, h.wrongCost, #h.calls - calls,
                        h.idReads - idReads, h.linkReads - linkReads, money - h.money, #h.frames))
                check(h.wrong == 0 and h.bags[999999] == nil, name .. " replacement item never bought")
                check(h.missing == 0, name .. " missing listing never submitted")
                check(h.bags[100009] == nil and h.bags[100010] == nil, name .. " stale targets remain uncredited")
                check(h.bags[100011] == 1 and h.bags[100012] == 1, name .. " unaffected trailing tasks complete")
                check(not h.fv.IsRestockBuyActive(), name .. " stale task removal drains queue")
                h:advance(0.4)
                h.shop[10] = { id = 100010, price = 5 }
                h.fv.GetMerchantItemIndex(true); h:advance(0.05)
                h.fv.DoRestockManual()
                for i = 1, 12 do check(h.bags[100000 + i] == 1, name .. " fresh request restores target " .. i) end
                check(not h.fv.IsRestockBuyActive(), name .. " fresh request finishes")
                h:event("MERCHANT_CLOSED"); h.merchant = false
                local done = #h.calls; h:advance(1); h:event("BAG_UPDATE_DELAYED")
                check(#h.calls == done and not h.open, name .. " close cancels further purchases")
            end
        end
        -- A listing can also change during a synchronous purchase callback.
        do
            local h = boot(modern, links, 2)
            h.afterFirst = function() h.shop[2] = { id = 999999, price = 800 } end
            h.fv.DoRestockManual()
            check(h.wrong == 0 and h.bags[100001] == 1, label .. " each same-pass task rechecks identity")
        end
        -- Stable large queues retain cadence, budget and resource reuse.
        do
            local h = boot(modern, links, 40)
            local frameCount, idReads, linkReads = #h.frames, h.idReads, h.linkReads
            h.fv.DoRestockManual()
            local passes = 1
            while h.fv.IsRestockBuyActive() and passes < 10 do
                local before = #h.calls
                h:event("BAG_UPDATE_DELAYED"); passes = passes + 1
                check(#h.calls - before <= 8, label .. " stable pass budget")
            end
            check(#h.calls == 40 and passes == 5, label .. " stable queue keeps original five-pass cadence")
            for i = 1, 40 do check(h.bags[100000 + i] == 1, label .. " stable target bought once " .. i) end
            for _ = 1, 100 do h:event("BAG_UPDATE_DELAYED") end
            check(#h.calls == 40 and #h.frames == frameCount, label .. " settled pulses allocate no extra frame or purchase")
            print(("METRIC %s_stable calls=%d passes=%d id_reads=%d link_reads=%d frames=%d")
                :format(label, #h.calls, passes, h.idReads - idReads, h.linkReads - linkReads, #h.frames))
        end
    end
end
end

if not identityOnly then
    local cases = {
        { name = "sold_out", stock = 0, target = 10, maxStack = 2, expected = 0 },
        { name = "finite_same_pass", stock = 3, target = 10, maxStack = 2, expected = 3 },
        { name = "finite_across_passes", stock = 10, target = 12, maxStack = 1, expected = 10 },
        { name = "shared_stock", stock = 3, target = 6, maxStack = 2, duplicate = true, expected = 3 },
        { name = "sold_out_partial_gold", stock = 0, target = 6, maxStack = 20,
            pack = 5, price = 25, money = 10, purchasable = false, expected = 0 },
        { name = "finite_partial_gold", stock = 3, target = 10, maxStack = 20, money = 10, expected = 2 },
        { name = "unlimited", stock = -1, target = 40, maxStack = 1, expected = 40 },
        { name = "unlimited_partial_gold", stock = -1, target = 10, maxStack = 20, money = 10, expected = 2 },
        { name = "finite_currency", stock = 10, target = 20, maxStack = 20,
            pack = 5, price = 0, tokens = 4, alt = "currency", expected = 10 },
        { name = "finite_item_cost", stock = 10, target = 20, maxStack = 20,
            pack = 5, price = 0, tokens = 4, alt = "item", expected = 10 },
    }
    for _, modern in ipairs({ false, true }) do
        for _, case in ipairs(cases) do
            local label = (modern and "modern_" or "legacy_") .. case.name
            local h = boot(modern, false, 1, false, case)
            local initialMoney, frames, reads = h.money, #h.frames, h.infoReads
            h.fv.DoRestockManual()
            local passes = 1
            while h.fv.IsRestockBuyActive() and passes < 12 do
                local before = #h.calls
                h:event("BAG_UPDATE_DELAYED"); passes = passes + 1
                check(#h.calls - before <= 8, label .. " retains eight-call pass budget")
            end
            local bought = h.bags[100001] or 0
            print(("METRIC %s calls=%d rejected=%d bought=%d accounted=%d actual_spent=%d passes=%d info_reads=%d frames=%d")
                :format(label, #h.calls, h.rejected, bought, -h.accounted, initialMoney - h.money,
                    passes, h.infoReads - reads, #h.frames))
            check(h.rejected == 0, label .. " no request exceeds stock or funds")
            check(bought == case.expected, label .. " obtains exact available/affordable quantity")
            check(-h.accounted == initialMoney - h.money, label .. " accounting matches accepted purchases")
            check(not h.fv.IsRestockBuyActive(), label .. " queue terminates")
            local count = #h.calls
            for _ = 1, 100 do h:event("BAG_UPDATE_DELAYED") end
            check(#h.calls == count and #h.frames == frames, label .. " settled pulses retain frame/call counts")
            local meta = h.fv.GetMerchantItemIndex(false)[100001]
            if case.stock >= 0 then
                check(meta.numAvailable == math.max(0, case.stock - bought), label .. " shared index reserves submitted stock")
            else check(meta.numAvailable == -1, label .. " unlimited sentinel retained") end
            if case.name == "finite_same_pass" then
                h.shop[1].stock = 2
                h.fv.GetMerchantItemIndex(true); h:advance(0.05)
                h.fv.DoRestockManual()
                check(h.bags[100001] == 5, label .. " fresh index/request can buy replenished stock")
            end
            h:event("MERCHANT_CLOSED"); h.merchant = false
            local done = #h.calls; h:advance(1); h:event("BAG_UPDATE_DELAYED")
            check(#h.calls == done and not h.open, label .. " close prevents further purchases")
        end
    end
    -- Missing stock metadata keeps the existing uncapped helper contract.
    do
        local h = boot(false, false, 1)
        for _, stock in ipairs({ -1, 0, 2 }) do
            local quantity, received = h.fv.ComputeRestockPurchaseQty(5,
                { slot = 1, price = 5, batchQty = 1, maxStack = 20, numAvailable = stock }, 100)
            local expected = stock < 0 and 5 or stock
            check(quantity == expected and received == expected, "direct quantity helper honors stock " .. stock)
        end
        local quantity = h.fv.ComputeRestockPurchaseQty(5, { slot = 1, maxStack = 20 }, 100)
        check(quantity == 5, "nil stock metadata remains uncapped")
    end
end
print(("Vendor slot/stock: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
