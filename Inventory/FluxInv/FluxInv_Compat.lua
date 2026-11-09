--[[
    Inventory/FluxInv/FluxInv_Compat.lua

    Capability probes and container/spell shims for FluxInv.
    Self-contained: does not modify FluxAPICompat.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Compat = Inv.Compat or {}
local Compat = Inv.Compat

local pcall = pcall
local type = type
local tonumber = tonumber

local USES_C_CONTAINER = (C_Container ~= nil and type(C_Container.GetContainerItemInfo) == "function")
local C_GetNumSlots = (C_Container and C_Container.GetContainerNumSlots) or _G.GetContainerNumSlots
local C_GetNumFreeSlots = (C_Container and C_Container.GetContainerNumFreeSlots) or _G.GetContainerNumFreeSlots
local C_GetItemInfo = (C_Container and C_Container.GetContainerItemInfo) or _G.GetContainerItemInfo
local C_GetItemID = (C_Container and C_Container.GetContainerItemID) or _G.GetContainerItemID
local C_GetItemLink = (C_Container and C_Container.GetContainerItemLink) or _G.GetContainerItemLink

Compat.USES_C_CONTAINER = USES_C_CONTAINER
Compat.HAS_MODERN_BANK = (C_Bank ~= nil and type(C_Bank.FetchPurchasedBankTabIDs) == "function")
Compat.HAS_C_SPELL = (C_Spell ~= nil and type(C_Spell.GetSpellInfo) == "function")
Compat.HAS_C_SPELLBOOK = (C_SpellBook ~= nil and type(C_SpellBook.IsSpellKnown) == "function")
Compat.HAS_MODERN_PROF = (C_TradeSkillUI ~= nil and type(C_TradeSkillUI.GetRecipeInfo) == "function")
Compat.HAS_LEGACY_PROF = (type(_G.GetNumTradeSkills) == "function" and type(_G.GetTradeSkillInfo) == "function")

--- True when the client uses C_Bank tab IDs (Retail), not bags-in-bank.
function Compat.IsModernBank()
    return Compat.HAS_MODERN_BANK
end

--- True when the client has a player reagent bag slot (never invent ID 5 on Classic).
function Compat.HasReagentBag()
    return (_G.NUM_REAGENTBAG_SLOTS or 0) > 0
end

function Compat.After(delay, fn)
    if FluxAPICompat and FluxAPICompat.After then
        FluxAPICompat.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

function Compat.SafeRegisterEvent(frame, eventName)
    if not frame or not eventName or eventName == "" then
        return false
    end
    if FluxAPICompat and FluxAPICompat.SafeRegisterEvent then
        return FluxAPICompat.SafeRegisterEvent(frame, eventName)
    end
    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok
end

function Compat.GetContainerNumSlots(bag)
    if not C_GetNumSlots then
        return 0
    end
    return C_GetNumSlots(bag) or 0
end

--- True when bags-in-bank containers may exist (Classic, or hybrid leftover slots).
function Compat.HasLegacyBankBags()
    if type(_G.GetNumBankSlots) ~= "function" then
        return false
    end
    if not Compat.HAS_MODERN_BANK then
        return true
    end
    local purchased = _G.GetNumBankSlots()
    if type(purchased) == "number" and purchased > 0 then
        return true
    end
    local numBags = _G.NUM_BAG_SLOTS or 4
    local maxBankBags = _G.NUM_BANKBAGSLOTS or 7
    for i = 1, maxBankBags do
        if Compat.GetContainerNumSlots(numBags + i) > 0 then
            return true
        end
    end
    return false
end

function Compat.GetContainerNumFreeSlots(bag)
    if not C_GetNumFreeSlots then
        return 0, 0
    end
    local free, family = C_GetNumFreeSlots(bag)
    return free or 0, family or 0
end

--- Normalized: { itemID, count, locked, quality, hyperlink, noValue }
function Compat.GetContainerItemInfo(bag, slot)
    if not C_GetItemInfo then
        return nil
    end
    if USES_C_CONTAINER then
        local info = C_GetItemInfo(bag, slot)
        if not info or not info.itemID then
            return nil
        end
        return {
            itemID = info.itemID,
            count = info.stackCount or 1,
            locked = info.isLocked or false,
            quality = info.quality,
            hyperlink = info.hyperlink,
            noValue = info.hasNoValue or false,
        }
    end
    local _, count, locked, quality, _, _, link, _, noValue, itemID = C_GetItemInfo(bag, slot)
    if not itemID and C_GetItemID then
        itemID = C_GetItemID(bag, slot)
    end
    if not itemID then
        return nil
    end
    return {
        itemID = itemID,
        count = count or 1,
        locked = locked or false,
        quality = quality,
        hyperlink = link,
        noValue = noValue or false,
    }
end

function Compat.GetContainerItemID(bag, slot)
    if USES_C_CONTAINER then
        local info = C_GetItemInfo(bag, slot)
        return info and info.itemID or nil
    end
    if C_GetItemID then
        return C_GetItemID(bag, slot)
    end
    local info = Compat.GetContainerItemInfo(bag, slot)
    return info and info.itemID or nil
end

function Compat.GetContainerItemLink(bag, slot)
    if C_GetItemLink then
        return C_GetItemLink(bag, slot)
    end
    local info = Compat.GetContainerItemInfo(bag, slot)
    return info and info.hyperlink or nil
end

function Compat.HasWarbandBank()
    if not (Compat.HAS_MODERN_BANK and Enum and Enum.BankType and Enum.BankType.Account and C_Bank.FetchBankLockedReason) then
        return false
    end
    local ok, reason = pcall(C_Bank.FetchBankLockedReason, Enum.BankType.Account)
    return ok and reason == nil
end

function Compat.IsSpellKnown(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return false
    end
    if Compat.HAS_C_SPELLBOOK then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID)
        if ok and known then
            return true
        end
        if C_SpellBook.IsSpellKnownOrInSpellBook then
            ok, known = pcall(C_SpellBook.IsSpellKnownOrInSpellBook, spellID)
            if ok and known then
                return true
            end
        end
        if C_SpellBook.IsSpellInSpellBook then
            local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
            ok, known = pcall(C_SpellBook.IsSpellInSpellBook, spellID, bank)
            if ok and known then
                return true
            end
        end
    end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellID)
        if ok and known then
            return true
        end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellID)
        if ok and known then
            return true
        end
    end
    return false
end

function Compat.GetSpellCastCount(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return 0
    end
    if C_Spell and C_Spell.GetSpellCastCount then
        local ok, n = pcall(C_Spell.GetSpellCastCount, spellID)
        if ok and type(n) == "number" then
            return n
        end
    end
    if GetSpellCount then
        local ok, n = pcall(GetSpellCount, spellID)
        if ok and type(n) == "number" then
            return n
        end
    end
    return 0
end

function Compat.GetSpellName(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and type(info) == "table" then
            return info.name
        end
        if ok and type(info) == "string" then
            return info
        end
    end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok then
            return name
        end
    end
    return nil
end

function Compat.InCombat()
    return (UnitAffectingCombat and UnitAffectingCombat("player")) or false
end

_G.FluxInv = Inv
