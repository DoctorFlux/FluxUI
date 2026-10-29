-- Production merchant index/queue replay. Native purchases and timing are modeled.
local source, measure = "Inventory/Restock/Vendor/FluxVendorBuy.lua", false
for i, value in ipairs(arg or {}) do
    if value == "--source" then source = assert(arg[i + 1]) end
    if value == "--measure" then measure = true end
end
local checks, failures = 0, 0
local function check(value, label)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. label) end
end
local function boot(modern, links, size, tier)
    local h = { now = 0, frames = {}, timers = {}, shop = {}, bags = {}, calls = {},
        money = 100000, wrong = 0, missing = 0, wrongCost = 0, idReads = 0, linkReads = 0,
        pulses = 0, merchant = true, open = false, reported = {}, size = size }
    for i = 1, size do h.shop[i] = { id = 100000 + i, price = 5 } end
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
            local entry = { itemID = id, target = 1, vendorSold = index[id] ~= nil }
            if tier and i == 9 then
                entry.isTierRestock, entry.tierKind, entry.vendorHasStock = true, "food", index[id] ~= nil
                entry.merchantSlot, entry.merchantItemID = index[id] and index[id].slot, id
            end
            entries[#entries + 1] = entry
        end
        return entries
    end
    env.GetMoney = function() return h.money end
    env.MerchantFrame = { IsShown = function() return h.merchant end }
    env.IsShiftKeyDown = function() return false end
    env.GetTime = function() return h.now end
    env.GetMerchantNumItems = function() return h.size end
    env.GetMerchantItemMaxStack = function() return 1 end
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
        local item = h.shop[slot]
        if item then return "Item", 1, item.price, 1, -1, true, true, false end
    end
    if modern then
        env.C_MerchantFrame = { GetItemInfo = function(slot)
            local name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, hasExtendedCost = info(slot)
            if name then return { name = name, texture = texture, price = price, stackCount = stackCount,
                numAvailable = numAvailable, isPurchasable = isPurchasable, isUsable = isUsable,
                hasExtendedCost = hasExtendedCost } end
        end }
    else env.GetMerchantItemInfo = info end
    env.BuyMerchantItem = function(slot, qty)
        local item = h.shop[slot]
        h.calls[#h.calls + 1] = { slot = slot, qty = qty, id = item and item.id }
        if not item then h.missing = h.missing + 1; return end
        local cost = item.price * qty
        if item.id < 100001 or item.id > 100000 + size then
            h.wrong = h.wrong + 1; h.wrongCost = h.wrongCost + cost
        end
        h.money = h.money - cost
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
    h:event("MERCHANT_SHOW"); h:advance(0.6)
    h.fv.GetMerchantItemIndex(false); h:advance(0.05)
    check(h.open and #h.calls == 0, "startup/index alone make no purchases")
    return h
end

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
print(("Vendor slot identity: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
