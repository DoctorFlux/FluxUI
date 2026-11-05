-- Loaded-module regression for charge detection while a bank view is open.
local source = assert(io.open(arg[1] or "Inventory/Restock/Core/FluxRestockList.lua", "rb"))
local body = source:read("*a")
source:close()
local baseline = arg[2] == "baseline"
local checks = 0

local function eq(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function loadRegistry(bankOpen, withIterator)
    local bankVisits = 0
    local bank = {
        IsOpen = function() return bankOpen end,
        RegisterBankClose = function() end,
    }
    if withIterator then
        bank.ForEachOpenStack = function(opts, fn)
            eq(opts.bank, true, "character bank included")
            eq(opts.warband, true, "warband bank included")
            bankVisits = bankVisits + 1
            fn(5, 1, { itemID = 123, count = 1 }, "bank")
            fn(6, 1, { itemID = 456, count = 1 }, "warband")
        end
    end
    local inv = {
        Bank = bank,
        ForEachBagSlot = function(fn) fn(0, 1, 123, 1) end,
    }
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.FluxVendorAuto = {}
    env.FluxRestock = { Inv = inv }
    env.FluxRestockSettings = { Get = function() return { restockItems = {} } end }
    env.FluxNCConsumables = { IsWeaponEnchantItem = function() return false end }
    env.C_TooltipInfo = false
    env.C_Item = {
        GetItemCount = function() return 1 end,
        GetItemMaxStackSizeByID = function() return 1 end,
    }
    env.UIParent = {}
    env.CreateFrame = function(kind)
        if kind == "GameTooltip" then
            return {
                SetOwner = function() end,
                ClearLines = function() end,
                SetHyperlink = function() end,
                NumLines = function() return 0 end,
            }
        end
        return { RegisterEvent = function() end, SetScript = function() end }
    end
    assert(load(body, "FluxRestockList.lua", "t", env))()
    local registry = env.FluxRestockItemRegistry
    registry.GetSlotCharges = function(bag)
        return bag == 5 and 3 or 2
    end
    return registry, function() return bankVisits end
end

local registry, visits = loadRegistry(false, true)
local isCharge, maxCharges = registry.GetChargeInfo(123)
eq(isCharge, true, "bag charge item detected with bank closed")
eq(maxCharges, 2, "bag charge count with bank closed")
eq(visits(), 0, "closed bank not walked")

registry, visits = loadRegistry(true, true)
local ok, charge, maximum = pcall(registry.GetChargeInfo, 123)
if baseline then
    eq(ok, false, "old open-bank iterator call fails")
    eq(visits(), 0, "old adapter iterator never reached")
else
    eq(ok, true, "open-bank scan succeeds")
    eq(charge, true, "open-bank charge item detected")
    eq(maximum, 3, "matching bank slot raises maximum")
    eq(visits(), 1, "supported bank iterator used once")
    eq(registry.GetItemMaxCharges(123), 3, "cached bank maximum available")
end

if not baseline then
    registry = loadRegistry(true, false)
    ok, charge, maximum = pcall(registry.GetChargeInfo, 123)
    eq(ok, true, "partially loaded bank adapter does not crash")
    eq(maximum, 2, "bag charges retained without bank iterator")
end

print("Restock charge bank iterator: " .. checks .. " checks passed")
