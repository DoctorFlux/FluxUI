-- Regression for overlapping container lists in the live Restock stack collector.
local env = setmetatable({}, { __index = _G })
env._G = env
env.GetTime = function() return 100 end

local open = true
local inventory = {
    IsBankOpen = function() return open end,
    IsBankLive = function() return open end,
    HasWarband = function() return true end,
    Containers = {
        GetCharacterBankIDs = function() return { 6, 7 } end,
        GetWarbandBankIDs = function() return { 13 } end,
    },
}
local flux = {
    Inventory = inventory,
    Container = {
        GetNumSlots = function() return 1 end,
        GetItemInfo = function(bag)
            return { itemID = 1191, stackCount = 1, isLocked = bag == 7 }
        end,
    },
}
local chargesByBag = { [6] = 3, [7] = 2, [13] = 4 }
local chargeReads = 0
env.FluxRestockItemRegistry = {
    GetSlotCharges = function(bag)
        chargeReads = chargeReads + 1
        return chargesByBag[bag]
    end,
}

local path = arg[1] or "Inventory/Restock/FluxRestock_Inv.lua"
local chunk
if setfenv then
    chunk = setfenv(assert(loadfile(path)), env)
else
    chunk = assert(loadfile(path, "t", env))
end
chunk("_FluxUI", { Flux = flux })

local bank = env.FluxRestock.Inv.Bank
local stacks = bank.FindStacks(1191)
assert(#stacks == 3, "one stack per physical bank location, got " .. #stacks)
assert(stacks[1].bag == 6 and stacks[2].bag == 7 and stacks[3].bag == 13, "first traversal order")
assert(stacks[2].locked and stacks[3].region == "warband", "lock state and bank region")
assert(bank.GetCount(1191, { charges = true }) == 9, "charges count each slot once")
assert(chargeReads == 3, "charges read once per physical slot")

local character = bank.FindStacks(1191, { warband = false })
local account = bank.FindStacks(1191, { bank = false })
assert(#character == 2 and #account == 1, "region filters")

-- A filtered primary list must still pick up a bag from the fallback list.
bank.GetContainerIDs = function() return { 7 } end
character = bank.FindStacks(1191, { warband = false })
assert(#character == 2 and character[1].bag == 7 and character[2].bag == 6, "fallback-only bag and order")

open = false
assert(#bank.FindStacks(1191) == 0, "closed bank remains unavailable for withdrawals")
print("Bank stack collection: 8 checks passed")
