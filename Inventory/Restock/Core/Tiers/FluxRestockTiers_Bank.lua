--[[
    Restock/Core/Tiers/FluxRestockTiers_Bank.lua
]]

local Tiers = FluxRestockTiers
local P = Tiers._Private

local bankKindStacksIndex = {
    gen = nil,
    byKind = {},
}

local function SortBankStacks(out)
    table.sort(out, function(a, b)
        if a.count == b.count then
            if a.itemID == b.itemID then
                return (a.slot or 0) < (b.slot or 0)
            end
            return (a.itemID or 0) < (b.itemID or 0)
        end
        return a.count < b.count
    end)
end

--- One bank/warband slot walk builds kind→stacks for the current bank generation.
local function EnsureBankKindStacksIndex()
    local inv = P.Inv()
    if not inv or not inv.Bank or not inv.Bank.IsOpen or not inv.Bank.IsOpen() then
        bankKindStacksIndex.gen = nil
        wipe(bankKindStacksIndex.byKind)
        return nil
    end
    local bankGen = inv.Bank.GetGeneration and inv.Bank.GetGeneration() or 0
    if bankKindStacksIndex.gen == bankGen then
        return bankKindStacksIndex.byKind
    end

    local byKind = {}
    for _, kind in ipairs(P.KINDS) do
        byKind[kind] = {}
    end

    local matchCache = {} -- [itemID] = { [kind] = true } or false sentinel empty
    local function kindsForItem(itemID, itemLink)
        local cached = matchCache[itemID]
        if cached ~= nil then
            return cached
        end
        local matches = {}
        local any = false
        for _, kind in ipairs(P.KINDS) do
            if (P.GetTierRestockThreshold(kind) or 0) > 0
                and Tiers.StackMatchesBankRestockKind(kind, itemID, itemLink) then
                matches[kind] = true
                any = true
            end
        end
        if not any then
            matches = false
        end
        matchCache[itemID] = matches
        return matches
    end

    local function considerStack(bag, slot, rec)
        local itemID = tonumber(rec and rec.itemID)
        if not itemID or (tonumber(rec.count) or 0) <= 0 then
            return
        end
        local matches = kindsForItem(itemID, rec.link)
        if not matches then
            return
        end
        local entry = {
            bag = bag,
            slot = slot,
            count = rec.count,
            locked = rec.locked,
            itemID = itemID,
            tierPriority = 0,
        }
        for kind in pairs(matches) do
            local list = byKind[kind]
            list[#list + 1] = entry
        end
    end

    if inv.Bank.ForEachOpenStack then
        inv.Bank.ForEachOpenStack({ bank = true, warband = true }, considerStack)
    elseif inv.Bank.FindStacks then
        -- Fallback: unique IDs then FindStacks (older FluxInv without ForEachOpenStack).
        local seen = {}
        local function considerMap(counts)
            if type(counts) ~= "table" then
                return
            end
            for itemID, n in pairs(counts) do
                itemID = tonumber(itemID)
                if itemID and (tonumber(n) or 0) > 0 and not seen[itemID] then
                    seen[itemID] = true
                    local matches = kindsForItem(itemID)
                    if matches then
                        local stacks = inv.Bank.FindStacks(itemID, { bank = true, warband = true })
                        for i = 1, #stacks do
                            local st = stacks[i]
                            considerStack(st.bag, st.slot, {
                                itemID = itemID,
                                count = st.count,
                                locked = st.locked,
                            })
                        end
                    end
                end
            end
        end
        considerMap(inv.Bank.GetCharacterCounts and inv.Bank.GetCharacterCounts() or {})
        considerMap(inv.Bank.GetWarbandCounts and inv.Bank.GetWarbandCounts() or {})
    end

    for _, kind in ipairs(P.KINDS) do
        SortBankStacks(byKind[kind])
    end
    bankKindStacksIndex.gen = bankGen
    bankKindStacksIndex.byKind = byKind
    return byKind
end

function Tiers.InvalidateBankKindStacksIndex()
    bankKindStacksIndex.gen = nil
    wipe(bankKindStacksIndex.byKind)
end

function Tiers.FindBankStacksForKind(kind)
    local inv = P.Inv()
    if not inv or not inv.Bank or not inv.Bank.IsLive or not inv.Bank.IsLive() then
        return {}
    end
    local ref = P.GetTierRestockThreshold(kind)
    if ref <= 0 then
        return {}
    end
    local byKind = EnsureBankKindStacksIndex()
    if not byKind then
        return {}
    end
    return byKind[kind] or {}
end

function Tiers.SumBankStacksForKind(kind)
    local total = 0
    for _, st in ipairs(Tiers.FindBankStacksForKind(kind)) do
        total = total + (tonumber(st.count) or 0)
    end
    return total
end

function Tiers.GetBankRestockEntries()
    local inv = P.Inv()
    local ic = P.IC()
    if not inv or not inv.Bank then
        return {}
    end

    local bankItemsByID = {}
    local function addBankItem(itemID, n)
        itemID = tonumber(itemID)
        n = tonumber(n) or 0
        if itemID and n > 0 then
            bankItemsByID[itemID] = (bankItemsByID[itemID] or 0) + n
        end
    end
    local char = inv.Bank.GetCharacterCounts and inv.Bank.GetCharacterCounts({ allowCached = true }) or {}
    for itemID, n in pairs(char) do
        addBankItem(itemID, n)
    end
    if inv.Bank.GetWarbandCounts then
        for itemID, n in pairs(inv.Bank.GetWarbandCounts({ allowCached = true }) or {}) do
            addBankItem(itemID, n)
        end
    end

    local out = {}
    for _, kind in ipairs(P.KINDS) do
        local target = Tiers.GetTarget(kind)
        if target > 0 and Tiers.IsTierEligible(kind) then
            local have = Tiers.GetTierBagTotalForBankRestock(kind)
            local needed = target - have
            if needed > 0 then
                local ref = P.GetTierRestockThreshold(kind)
                if ref > 0 then
                    local strictCandidates = {}
                    local strictTotal = 0
                    for itemID, bankCount in pairs(bankItemsByID) do
                        local cls = P.ClassificationForTierCount(kind, itemID)
                        if P.ItemMatchesTierForBank(kind, cls, ref) then
                            local value = P.TierAxisValue(kind, cls)
                            strictCandidates[#strictCandidates + 1] = {
                                itemID = itemID,
                                bankCount = bankCount,
                                value = value,
                            }
                            strictTotal = strictTotal + bankCount
                        end
                    end
                    table.sort(strictCandidates, function(a, b)
                        if a.bankCount == b.bankCount then
                            return a.value > b.value
                        end
                        return a.bankCount < b.bankCount
                    end)
                    if #strictCandidates > 0 then
                        local pick = strictCandidates[1]
                        out[#out + 1] = {
                            itemID = pick.itemID,
                            target = target,
                            mode = "stack",
                            maxStack = ic and ic.GetStackSize and ic.GetStackSize(pick.itemID) or 20,
                            restock = true,
                            tierKind = kind,
                            isTierBankEntry = true,
                            tierWithdraw = math.min(needed, strictTotal),
                            tierBankCount = strictTotal,
                        }
                    end
                end
            end
        end
    end
    return out
end

_G.FluxRestockTiers = Tiers
return Tiers
