--[[
    Inventory/FluxInv/FluxInv_Containers.lua

    Flavor-safe bag/bank container ID discovery.
    Never assume bag numbers are shared across Classic and Midnight retail.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Containers = Inv.Containers or {}
local C = Inv.Containers

local Compat = function()
    return Inv.Compat
end

local BACKPACK = _G.BACKPACK_CONTAINER or 0
local NUM_BAGS = _G.NUM_BAG_SLOTS or 4
local BANK_MAIN = _G.BANK_CONTAINER or -1
local REAGENTBANK = _G.REAGENTBANK_CONTAINER or -3
local KEYRING = _G.KEYRING_CONTAINER or -2
local NUM_BANKBAGSLOTS = _G.NUM_BANKBAGSLOTS or 7

local cachedCarried
local cachedCharBank
local cachedWarband
local cachedCharBankSet
local cachedWarbandSet

local function AppendID(ids, seen, bagID)
    bagID = tonumber(bagID)
    if not bagID or seen[bagID] then
        return false
    end
    ids[#ids + 1] = bagID
    seen[bagID] = true
    return true
end

local function GetReagentBagID()
    if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
        return Enum.BagIndex.ReagentBag
    end
    return 5
end

local function HasReagentBagSlot()
    local compat = Compat()
    if compat and compat.HasReagentBag then
        return compat.HasReagentBag()
    end
    return (_G.NUM_REAGENTBAG_SLOTS or 0) > 0
end

local function IsModernBank()
    local compat = Compat()
    if compat and compat.IsModernBank then
        return compat.IsModernBank()
    end
    return compat and compat.HAS_MODERN_BANK or false
end

function C.Invalidate()
    cachedCarried = nil
    cachedCharBank = nil
    cachedWarband = nil
    cachedCharBankSet = nil
    cachedWarbandSet = nil
end

--- Player-carried containers: backpack, bags, reagent bag, keyring when present.
function C.GetCarriedBagIDs()
    if cachedCarried then
        return cachedCarried
    end
    local compat = Compat()
    local ids, seen = {}, {}
    AppendID(ids, seen, BACKPACK)
    for i = 1, NUM_BAGS do
        AppendID(ids, seen, i)
    end
    -- Reagent bag is retail-only (NUM_REAGENTBAG_SLOTS). On Classic, bag index 5 is
    -- often the first bank bag — never treat it as carried there.
    if HasReagentBagSlot() then
        local reagentID = GetReagentBagID()
        if compat and compat.GetContainerNumSlots(reagentID) > 0 then
            AppendID(ids, seen, reagentID)
        end
    end
    if KEYRING and compat and compat.GetContainerNumSlots(KEYRING) > 0 then
        AppendID(ids, seen, KEYRING)
    end
    cachedCarried = ids
    return ids
end

local function AppendFetchedTabs(ids, seen, bankType)
    local compat = Compat()
    if not (compat and IsModernBank() and Enum and Enum.BankType) then
        return 0
    end
    local ok, tabs = pcall(C_Bank.FetchPurchasedBankTabIDs, bankType)
    local added = 0
    if ok and type(tabs) == "table" then
        for _, id in ipairs(tabs) do
            if AppendID(ids, seen, id) then
                added = added + 1
            end
        end
    end
    return added
end

local function AppendStaticCharacterBankTabs(ids, seen)
    if not (Enum and Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1) then
        return
    end
    for i = 1, 6 do
        AppendID(ids, seen, Enum.BagIndex["CharacterBankTab_" .. i])
    end
end

local function GetPurchasedBankBagCount()
    local numBankBags = NUM_BANKBAGSLOTS
    if _G.GetNumBankSlots then
        local purchased = _G.GetNumBankSlots()
        if type(purchased) == "number" then
            numBankBags = purchased
        end
    end
    return numBankBags
end

--- Classic bags-in-bank: main grid + purchased bank bags. Never skip bag 5 —
--- on Classic Era / Anniversary that ID is bank bag #1, not a reagent bag.
--- Bank bags are appended highest-numbered first (Restocker withdraw order).
local function AppendLegacyBankContainers(ids, seen)
    local compat = Compat()
    if not compat then
        return
    end
    local numBankBags = GetPurchasedBankBagCount()
    for i = numBankBags, 1, -1 do
        local bag = NUM_BAGS + i
        if not seen[bag] and compat.GetContainerNumSlots(bag) > 0 then
            AppendID(ids, seen, bag)
        end
    end
    local mainBank = (Enum and Enum.BagIndex and Enum.BagIndex.Bank) or BANK_MAIN
    if mainBank and not seen[mainBank] and compat.GetContainerNumSlots(mainBank) > 0 then
        AppendID(ids, seen, mainBank)
    end
    if BANK_MAIN and BANK_MAIN ~= mainBank and not seen[BANK_MAIN]
        and compat.GetContainerNumSlots(BANK_MAIN) > 0 then
        AppendID(ids, seen, BANK_MAIN)
    end
    if _G.IsReagentBankUnlocked and _G.IsReagentBankUnlocked()
        and not seen[REAGENTBANK] and compat.GetContainerNumSlots(REAGENTBANK) > 0 then
        AppendID(ids, seen, REAGENTBANK)
    end
end

--- Modern-safe legacy append: main bank grid + any leftover bank bags, skipping
--- the player reagent bag only when the client actually has one.
local function AppendSafeLegacyBankContainers(ids, seen)
    local compat = Compat()
    if not compat then
        return
    end
    local reagentBagID = HasReagentBagSlot() and GetReagentBagID() or nil
    local mainBank = (Enum and Enum.BagIndex and Enum.BagIndex.Bank) or BANK_MAIN
    if mainBank and not seen[mainBank] and compat.GetContainerNumSlots(mainBank) > 0 then
        AppendID(ids, seen, mainBank)
    end
    if BANK_MAIN and BANK_MAIN ~= mainBank and not seen[BANK_MAIN]
        and compat.GetContainerNumSlots(BANK_MAIN) > 0 then
        AppendID(ids, seen, BANK_MAIN)
    end
    local numBankBags = GetPurchasedBankBagCount()
    for i = numBankBags, 1, -1 do
        local bag = NUM_BAGS + i
        if bag ~= reagentBagID and not seen[bag] and compat.GetContainerNumSlots(bag) > 0 then
            AppendID(ids, seen, bag)
        end
    end
end

--- Character bank container IDs (tabs or legacy main + bank bags).
function C.GetCharacterBankIDs()
    if cachedCharBank then
        return cachedCharBank
    end
    local ids, seen = {}, {}
    if IsModernBank() and Enum and Enum.BankType then
        local added = AppendFetchedTabs(ids, seen, Enum.BankType.Character)
        if added == 0 then
            AppendStaticCharacterBankTabs(ids, seen)
        end
        AppendSafeLegacyBankContainers(ids, seen)
    else
        -- Seed classic main even if slots probe is flaky at bank open.
        local classicMain = (Enum and Enum.BagIndex and Enum.BagIndex.Bank) or BANK_MAIN
        AppendID(ids, seen, classicMain)
        AppendLegacyBankContainers(ids, seen)
    end
    cachedCharBank = ids
    cachedCharBankSet = {}
    for _, id in ipairs(ids) do
        cachedCharBankSet[id] = true
    end
    return ids
end

--- Warband / Account bank tab IDs when unlocked.
function C.GetWarbandBankIDs()
    if cachedWarband then
        return cachedWarband
    end
    local compat = Compat()
    local ids, seen = {}, {}
    if compat and compat.HasWarbandBank and compat.HasWarbandBank() and Enum and Enum.BankType then
        AppendFetchedTabs(ids, seen, Enum.BankType.Account)
    end
    cachedWarband = ids
    cachedWarbandSet = {}
    for _, id in ipairs(ids) do
        cachedWarbandSet[id] = true
    end
    return ids
end

function C.IsCarriedBag(bag)
    bag = tonumber(bag)
    if not bag then
        return false
    end
    C.GetCarriedBagIDs()
    for _, id in ipairs(cachedCarried or {}) do
        if id == bag then
            return true
        end
    end
    return false
end

function C.IsCharacterBankContainer(bag)
    bag = tonumber(bag)
    if not bag then
        return false
    end
    C.GetCharacterBankIDs()
    return cachedCharBankSet and cachedCharBankSet[bag] or false
end

function C.IsWarbandBankContainer(bag)
    bag = tonumber(bag)
    if not bag then
        return false
    end
    C.GetWarbandBankIDs()
    return cachedWarbandSet and cachedWarbandSet[bag] or false
end

function C.IsBankContainer(bag)
    bag = tonumber(bag)
    if not bag then
        return false
    end
    if bag == BANK_MAIN or bag == REAGENTBANK then
        return true
    end
    if C.IsCharacterBankContainer(bag) or C.IsWarbandBankContainer(bag) then
        return true
    end
    -- Classic: bank bag IDs are NUM_BAG_SLOTS+i; treat as bank before set rebuild.
    if not IsModernBank() and bag > NUM_BAGS then
        return true
    end
    return false
end

function C.GetBankTypeForContainer(bag)
    if not (IsModernBank() and Enum and Enum.BankType) then
        return nil
    end
    if C.IsWarbandBankContainer(bag) then
        return Enum.BankType.Account
    end
    if C.IsCharacterBankContainer(bag) then
        return Enum.BankType.Character
    end
    return nil
end

_G.FluxInv = Inv
