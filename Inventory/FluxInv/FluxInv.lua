--[[
    Inventory/FluxInv/FluxInv.lua

    Public facade for the universal inventory / spell / profession store.
    Parallel to legacy FluxInventory/FluxBank — does not replace them yet.
]]

FluxInv = FluxInv or {}
local Inv = FluxInv

FluxInvDB = FluxInvDB or {}

Inv.VERSION = 1

--- Register a change listener.
--- opts.tier = "instant"|"light"|"scan"|"heavy"
--- opts.regions = { "bags", "bank", "warband", "equip", "spells", "professions" }
--- opts.sync = true — always run in the same frame as snapshot refresh (counts/overlays)
--- opts.deferHeavy = true — frame-budget queue during bag storms / identity changes
function Inv.RegisterListener(key, fn, opts)
    if Inv.Events and Inv.Events.RegisterListener then
        Inv.Events.RegisterListener(key, fn, opts)
    end
end

function Inv.UnregisterListener(key)
    if Inv.Events and Inv.Events.UnregisterListener then
        Inv.Events.UnregisterListener(key)
    end
end

function Inv.OnChanged(fn, opts)
    if type(fn) ~= "function" then
        return
    end
    local key = opts and opts.key or ("FluxInv_anon_" .. tostring(fn))
    Inv.RegisterListener(key, fn, opts)
end

--- Count an item across requested regions.
--- opts: bags, bank, warband, equipped, allowCached, charges, includeBank
function Inv.GetCount(itemID, opts)
    if Inv.Index and Inv.Index.GetCount then
        return Inv.Index.GetCount(itemID, opts)
    end
    return 0
end

--- Live count via Blizzard GetItemCount (charges included by default).
--- opts: includeBank, charges (default true), equipped
function Inv.GetLiveCount(itemID, opts)
    if Inv.Index and Inv.Index.GetLiveCount then
        return Inv.Index.GetLiveCount(itemID, opts)
    end
    return Inv.GetCount(itemID, opts)
end

--- Locations for an item: { { bag, slot, count, region }, ... }
function Inv.FindItem(itemID, opts)
    if Inv.Index and Inv.Index.FindItem then
        return Inv.Index.FindItem(itemID, opts)
    end
    return {}
end

function Inv.GetFirst(itemID, opts)
    if Inv.Index and Inv.Index.GetFirst then
        return Inv.Index.GetFirst(itemID, opts)
    end
    return nil
end

--- region: "bags" | "bank" | "warband" | "equip"
function Inv.GetSnapshot(region)
    region = region or "bags"
    if region == "bags" and Inv.Bags then
        return Inv.Bags.GetSnapshot()
    end
    if region == "bank" and Inv.Bank then
        return Inv.Bank.GetSnapshot("bank")
    end
    if region == "warband" and Inv.Bank then
        return Inv.Bank.GetSnapshot("warband")
    end
    if region == "equip" and Inv.Equip then
        return Inv.Equip.GetSnapshot()
    end
    return nil
end

function Inv.Refresh(opts)
    opts = opts or {}
    if opts.bags ~= false and Inv.Bags then
        Inv.Bags.Invalidate()
        Inv.Bags.Refresh()
    end
    if opts.bank ~= false and Inv.Bank and Inv.Bank.IsOpen() then
        Inv.Bank.Invalidate()
        Inv.Bank.Refresh()
    end
    if opts.equip ~= false and Inv.Equip then
        Inv.Equip.Invalidate()
        Inv.Equip.Refresh()
    end
    if opts.spells and Inv.Spells then
        Inv.Spells.Invalidate()
        Inv.Spells.Refresh()
    end
    if Inv.Index then
        Inv.Index.Bump()
    end
end

function Inv.IsBankOpen()
    return Inv.Bank and Inv.Bank.IsOpen() or false
end

function Inv.HasWarbandBank()
    return Inv.Bank and Inv.Bank.HasWarband and Inv.Bank.HasWarband() or false
end

function Inv.IsModernBank()
    return Inv.Compat and Inv.Compat.IsModernBank and Inv.Compat.IsModernBank() or false
end

function Inv.HasLegacyBankBags()
    return Inv.Compat and Inv.Compat.HasLegacyBankBags and Inv.Compat.HasLegacyBankBags() or false
end

function Inv.HasReagentBag()
    return Inv.Compat and Inv.Compat.HasReagentBag and Inv.Compat.HasReagentBag() or false
end

function Inv.GetCarriedBagIDs()
    return Inv.Containers and Inv.Containers.GetCarriedBagIDs() or {}
end

function Inv.GetCharacterBankIDs()
    return Inv.Containers and Inv.Containers.GetCharacterBankIDs() or {}
end

function Inv.GetWarbandBankIDs()
    return Inv.Containers and Inv.Containers.GetWarbandBankIDs() or {}
end

-- Convenience spell/profession passthroughs on the facade
Inv.IsSpellKnown = function(spellID)
    return Inv.Spells and Inv.Spells.IsKnown(spellID) or false
end

Inv.SpellUsesReagents = function(spellID)
    return Inv.Spells and Inv.Spells.UsesReagents(spellID) or false
end

Inv.GetSpellReagents = function(spellID)
    return Inv.Spells and Inv.Spells.GetReagents(spellID)
end

Inv.GetSpellReagentItemIDs = function()
    return Inv.Spells and Inv.Spells.GetReagentItemIDs() or {}
end

Inv.GetSpellReagentItemIDSet = function()
    return Inv.Spells and Inv.Spells.GetReagentItemIDSet() or {}
end

Inv.IsSpellReagentItem = function(itemID)
    return Inv.Spells and Inv.Spells.IsReagentItem(itemID) or false
end

Inv.GetSpellsUsingReagent = function(itemID)
    return Inv.Spells and Inv.Spells.GetSpellsUsingReagent(itemID) or {}
end

Inv.GetSpellsUsingReagentLabeled = function(itemID)
    return Inv.Spells and Inv.Spells.GetSpellsUsingReagentLabeled(itemID) or {}
end

Inv.GetCreateItemSpells = function(kind)
    return Inv.Spells and Inv.Spells.GetCreateItemSpells(kind) or {}
end

Inv.ListProfessionRecipes = function(skillKey)
    if Inv.Professions then
        return Inv.Professions.ListCachedRecipes(skillKey)
    end
    return {}, "none"
end

Inv.GetProfessionCompleteness = function(skillKey)
    return Inv.Professions and Inv.Professions.GetCompleteness(skillKey) or "none"
end

_G.FluxInv = Inv
