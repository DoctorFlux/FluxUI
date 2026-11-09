-- Merchant chat amounts include denominations and coin textures on every client.
local lines = {}
local env = setmetatable({
    FluxVendorAuto = {},
    GetMoney = function() return 0 end,
    print = function(line) lines[#lines + 1] = line end,
    CreateFrame = function()
        return { RegisterEvent = function() end, SetScript = function() end }
    end,
}, { __index = _G })

local function loadFile(path)
    local chunk = assert(loadfile(path, "t", env))
    chunk()
end

loadFile("Inventory/Restock/Junk/FluxSellJunk.lua")
loadFile("Inventory/Restock/Vendor/FluxVendorBuy.lua")

local gold = "349|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local silver = "42|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local copper = "36|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
local amount = gold .. " " .. silver .. " " .. copper
assert(env.FluxVendorAuto.FormatVendorMoney(3494236) == amount)
assert(env.FluxVendorAuto.FormatVendorMoney(5) ==
    "5|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t")
assert(env.FluxVendorAuto.FormatVendorMoney(10000) ==
    "1|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t " ..
    "0|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t " ..
    "0|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t")

env.FluxVendorAuto.AddBatchCopper(3494236)
assert(lines[1] == "|cff00ffff[FluxUI]|r Vendor: +" .. amount)
env.FluxVendorAuto.AddBatchCopper(-3494236)
assert(lines[2] == "|cff00ffff[FluxUI]|r Vendor: -" .. amount)
env.FluxVendorAuto.ReportManualRepairDelta(3494236)
assert(lines[3] == "|cff00ffff[FluxUI]|r Repaired for " .. amount .. ".")

local standaloneLines = {}
local standalone = setmetatable({
    FluxVendorAuto = {},
    print = function(line) standaloneLines[#standaloneLines + 1] = line end,
    CreateFrame = env.CreateFrame,
}, { __index = _G })
assert(loadfile("Inventory/Restock/Vendor/FluxVendorBuy.lua", "t", standalone))()
standalone.FluxVendorAuto.AddBatchCopper(-3494236)
assert(standaloneLines[1] == "|cff00ffff[FluxUI]|r Vendor: -" .. amount)

print("Vendor money chat OK: denominations, textures, gain, expense, manual repair, standalone vendor")
