--[[
    Inventory/FluxInv/FluxInv_Index.lua

    Unified itemID index across bags / bank / warband / equipped.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Index = Inv.Index or {}
local Index = Inv.Index

local generation = 0

function Index.Bump()
    generation = generation + 1
end

function Index.GetGeneration()
    return generation
end

local function defaultOpts(opts)
    opts = opts or {}
    return {
        bags = opts.bags ~= false,
        bank = opts.bank ~= false,
        warband = opts.warband ~= false,
        equipped = opts.equipped ~= false,
        allowCached = opts.allowCached ~= false,
        charges = opts.charges == true,
        includeBank = opts.includeBank, -- legacy alias used by button engine
    }
end

local function LiveItemCount(itemID, includeBank, includeCharges)
    includeBank = includeBank and true or false
    includeCharges = includeCharges and true or false
    -- When bank is requested, also include reagent + account/warband bank.
    local includeReagent = includeBank
    local includeAccount = includeBank
    if C_Item and C_Item.GetItemCount then
        local ok, n = pcall(C_Item.GetItemCount, itemID, includeBank, includeCharges, includeReagent, includeAccount)
        if ok and type(n) == "number" then
            return n
        end
    end
    if GetItemCount then
        local ok, n = pcall(GetItemCount, itemID, includeBank, includeCharges, includeReagent)
        if ok and type(n) == "number" then
            return n
        end
    end
    return nil
end

function Index.GetCount(itemID, opts)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    opts = defaultOpts(opts)
    -- Legacy button-engine aliases
    if opts.includeBank == false then
        opts.bank = false
        opts.warband = false
    elseif opts.includeBank == true then
        opts.bank = true
    end

    -- Charge-aware live count (consumables): prefer Blizzard API so charges are included
    if opts.charges then
        local includeBank = opts.bank or opts.warband
        local live = LiveItemCount(itemID, includeBank, true)
        if live ~= nil then
            if opts.equipped and Inv.Equip then
                -- GetItemCount typically includes bags; equipped stackables are rare.
                -- Snapshot equipped extras only when live API excludes them (usually 0).
            end
            return live
        end
    end

    local n = 0
    if opts.bags and Inv.Bags then
        n = n + Inv.Bags.GetCount(itemID)
    end
    if (opts.bank or opts.warband) and Inv.Bank then
        n = n + Inv.Bank.GetCount(itemID, {
            bank = opts.bank,
            warband = opts.warband,
            allowCached = opts.allowCached,
        })
    end
    if opts.equipped and Inv.Equip then
        n = n + Inv.Equip.GetCount(itemID)
    end
    return n
end

--- Always live via C_Item/GetItemCount (optional charges). Falls back to snapshot GetCount.
function Index.GetLiveCount(itemID, opts)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    opts = opts or {}
    local includeBank = opts.includeBank == true or opts.bank == true or opts.warband == true
    local includeCharges = opts.charges ~= false -- default true for live
    local live = LiveItemCount(itemID, includeBank, includeCharges)
    if live ~= nil then
        return live
    end
    return Index.GetCount(itemID, {
        bags = true,
        bank = includeBank,
        warband = includeBank,
        equipped = opts.equipped ~= false,
        charges = includeCharges,
        allowCached = opts.allowCached,
    })
end

function Index.FindItem(itemID, opts)
    itemID = tonumber(itemID)
    local locations = {}
    if not itemID then
        return locations
    end
    opts = defaultOpts(opts)
    if opts.bags and Inv.Bags then
        for _, loc in ipairs(Inv.Bags.FindStacks(itemID)) do
            locations[#locations + 1] = loc
        end
    end
    if (opts.bank or opts.warband) and Inv.Bank then
        for _, loc in ipairs(Inv.Bank.FindStacks(itemID, {
            bank = opts.bank,
            warband = opts.warband,
            allowCached = opts.allowCached,
        })) do
            locations[#locations + 1] = loc
        end
    end
    if opts.equipped and Inv.Equip then
        for _, loc in ipairs(Inv.Equip.FindStacks(itemID)) do
            locations[#locations + 1] = loc
        end
    end
    return locations
end

function Index.GetFirst(itemID, opts)
    local locs = Index.FindItem(itemID, opts)
    return locs[1]
end

function Index.RefreshRegions(regions)
    regions = regions or { bags = true, bank = true, equip = true }
    if regions.bags and Inv.Bags then
        Inv.Bags.Refresh()
    end
    if regions.bank and Inv.Bank and Inv.Bank.IsOpen() then
        Inv.Bank.Refresh()
    end
    if regions.equip and Inv.Equip then
        Inv.Equip.Refresh()
    end
    Index.Bump()
end

_G.FluxInv = Inv
