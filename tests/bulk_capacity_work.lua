-- Actual RI normalized reader block plus whole bulk-capacity owner. Native bag
-- reads are modeled; no purchase, sale, deletion or item movement is performed.
local source = arg[1] or "Inventory/Restock/FluxRestock_Inv.lua"
local compat = arg[2] or "Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll_Compat.lua"
local baseline = arg[3] == "baseline"
local file = assert(io.open(source, "rb")); local text = file:read("*a"):gsub("\r\n", "\n"); file:close()
local start = assert(text:find("local function NormalizeItemInfo(info)", 1, true))
local stop = assert(text:find("function RI.ItemExistsInInventory(itemID)", start, true))
local checks, models = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function fixture(kind)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local RI, C, s = {}, {}, { infoReads = 0, linkReads = 0, rows = 0, nativePerSlot = {} }
    e.RI, e.Flux, e.Container = RI, {}, function() return C end
    local function row(slot)
        if kind == "empty" or kind == "sparse" and slot > 40 then return end
        local id = kind == "dense-mixed" and slot % 4 ~= 0 and 999 or 100
        return { itemID = id, stackCount = 5, hyperlink = kind ~= "cold-link" and ("item:" .. id .. ":") or nil }
    end
    C.GetItemInfo = function(_, slot)
        s.infoReads = s.infoReads + 1; s.nativePerSlot[slot] = (s.nativePerSlot[slot] or 0) + 1
        if kind == "cold-info" and s.nativePerSlot[slot] == 1 then return end
        local value = row(slot); if value then s.rows = s.rows + 1 end; return value
    end
    C.GetItemLink = function(_, slot)
        s.linkReads = s.linkReads + 1; local value = row(slot)
        return value and ("item:" .. value.itemID .. ":"), "native-extra-result"
    end
    assert(load(text:sub(start, stop - 1), "@" .. source .. ":readers", "t", e))()
    RI.GetBagContainerIDs, RI.GetContainerNumSlots = function() return { 0 } end, function() return 200 end
    e.FluxRestock = { Inv = RI }; e.GetItemFamily = function() return 0 end
    e.GetItemInfoInstant = function() return 100 end
    e.GetItemInfo = function() return nil, nil, nil, nil, nil, nil, nil, 20 end
    assert(loadfile(compat, "t", e))("_FluxUI", {})
    return RI, C, e, s
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    for _, provider in ipairs({ false, true }) do
        for _, kind in ipairs({ "dense-target", "dense-mixed", "sparse", "empty", "cold-link", "cold-info" }) do
            models = models + 1
            local RI, C, e, s = fixture(kind)
            local space, stack = e.FluxBuyEmAllCompat.GetPurchasableBagSpace(100)
            local want = kind == "empty" and 4000 or kind == "sparse" and 3800 or kind == "dense-mixed" and 750 or 3000
            check(space == want and stack == 20, "exact capacity retains occupied, empty and cold slot policy")
            local warm = kind == "dense-target" or kind == "dense-mixed" or kind == "sparse"
            local infoWant = warm and 200 or kind == "empty" and 200 or 400
            if not baseline then check(s.infoReads == infoWant, "warm owned slots use one same-call info read; cold/empty sequence retained") end
            print(("BULK_CAPACITY %s provider=%s %s nativeInfo=%d nativeLink=%d rows=%d space=%d"):format(
                client, tostring(provider), kind, s.infoReads, s.linkReads, s.rows, space))
        end
    end
end
do
    local RI, C, e, s = fixture("dense-target")
    local info, link = RI.GetContainerItemInfo, RI.GetContainerItemLink
    check(select("#", RI.GetContainerItemLink(0, 1)) == 1, "warm existing link getter retains its single return value")
    local overrides = 0
    RI.GetContainerItemInfo = function(...) overrides = overrides + 1; local value = info(...); value.count = 7; return value end
    check(e.FluxBuyEmAllCompat.GetPurchasableBagSpace(100) == 2600 and overrides == 400, "public info overrides retain both original reads and their counts")
    RI.GetContainerItemInfo = info
    RI.GetContainerItemLink = function() return "item:100:" end
    s.infoReads = 0
    check(e.FluxBuyEmAllCompat.GetPurchasableBagSpace(100) == 3000 and s.infoReads == 200, "public link override remains authoritative without redundant native-link reads")
    RI.GetContainerItemLink = function() return nil end
    s.infoReads = 0
    check(e.FluxBuyEmAllCompat.GetPurchasableBagSpace(100) == 4000 and s.infoReads == 0, "nil link override retains empty-slot semantics")
    RI.GetContainerItemLink = function() error("public-link-marker") end
    local ok, err = pcall(e.FluxBuyEmAllCompat.GetPurchasableBagSpace, 100)
    check(not ok and tostring(err):find("public-link-marker", 1, true), "public getter errors propagate")
    RI.GetContainerItemLink = link
    RI.GetContainerItemInfo = function() error("public-info-marker") end
    ok, err = pcall(e.FluxBuyEmAllCompat.GetPurchasableBagSpace, 100)
    check(not ok and tostring(err):find("public-info-marker", 1, true), "info getter errors are not suppressed")
    RI.GetContainerItemInfo = info
    RI.GetContainerItemSnapshot = nil
    s.infoReads = 0
    check(e.FluxBuyEmAllCompat.GetPurchasableBagSpace(100) == 3000 and s.infoReads == 400, "older or alternate inventory facade retains the original fallback")
end
do
    local RI, C, e, s = fixture("dense-target")
    local native = C.GetItemInfo
    C.GetItemInfo = function(...)
        local value = native(...)
        if s.infoReads == 1 then RI.GetContainerItemInfo = function() return { itemID = 100, count = 9 } end end
        return value
    end
    check(e.FluxBuyEmAllCompat.GetPurchasableBagSpace(100) == 2200, "same-stack info override installed during the first read supplies occupied counts")
end
do
    local RI, C, e, s = fixture("cold-link")
    check(select("#", RI.GetContainerItemLink(0, 1)) == 2, "existing link getter keeps all native return values")
    C.GetItemLink = nil
    check(e.FluxBuyEmAllCompat.GetPurchasableBagSpace(100) == 4000, "missing native link fallback retains empty-slot policy")
end
do
    local RI, C, e, s = fixture("dense-target")
    C.GetItemInfo = nil
    check(e.FluxBuyEmAllCompat.GetPurchasableBagSpace(100) == 4000, "cold link-only records retain zero-known-count capacity")
    RI.GetBagContainerIDs = function() return { 0, 1 } end
    RI.GetContainerNumSlots = function(bag) return bag == 0 and 2 or 3 end
    e.C_Container = { ContainerIDToInventoryID = function() return 20 end }
    e.GetInventoryItemLink = function() return "special-bag" end
    e.GetItemFamily = function(id) return id == "special-bag" and 4 or 0 end
    e.bit = { band = function() return 0 end }
    check(e.FluxBuyEmAllCompat.GetPurchasableBagSpace(100) == 40, "incompatible specialty bag slots are excluded")
    check(e.FluxBuyEmAllCompat.GetPurchasableBagSpace("invalid") == 0, "invalid item keeps existing zero capacity")
end
print("Bulk capacity work: " .. checks .. " checks; " .. models .. " client/provider slot models PASS; native transactions/FPS NOT RUN")
