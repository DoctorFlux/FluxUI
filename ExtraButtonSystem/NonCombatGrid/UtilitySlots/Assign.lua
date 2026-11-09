--[[
    ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua

    Per-character assignments for NonCombat Utility Slots (4 slots × modifier chords).
    Accepts spell / item / macro / mount / battlepet / toy / outfit from GetCursorInfo.
]]

local _, ns = ...
FluxNCUtilitySlots = FluxNCUtilitySlots or {}
local Assign = FluxNCUtilitySlots

function Assign.GetOutfitInfo(id)
    local api = ns and ns.API
    return api and api.GetPlayerTransmogOutfitAction and api.GetPlayerTransmogOutfitAction(id)
end

function Assign.PickupOutfit(id)
    local api = ns and ns.API
    return api and api.TryPickupPlayerTransmogOutfit and api.TryPickupPlayerTransmogOutfit(id) or false
end

function Assign.GetOutfitIDForSpell(spellID)
    local api = ns and ns.API
    if api and api.GetPlayerTransmogOutfitIDForSpell then
        return api.GetPlayerTransmogOutfitIDForSpell(spellID)
    end
    return nil
end

function Assign.IsOutfitActive(id)
    local api = ns and ns.API
    return api and api.IsPlayerTransmogOutfitActive and api.IsPlayerTransmogOutfitActive(id) or false
end

local MAX_SLOTS = 4
local MOD_ORDER = { SHIFT = 1, CTRL = 2, ALT = 3 }

local function EnsureDB()
    if type(FluxNCUtilitySlotsDB) ~= "table" then
        FluxNCUtilitySlotsDB = {}
    end
    if type(FluxNCUtilitySlotsDB.slots) ~= "table" then
        FluxNCUtilitySlotsDB.slots = {}
    end
    for i = 1, MAX_SLOTS do
        if type(FluxNCUtilitySlotsDB.slots[i]) ~= "table" then
            FluxNCUtilitySlotsDB.slots[i] = {}
        end
    end
end

function Assign.GetMaxSlots()
    return MAX_SLOTS
end

function Assign.GetSlots()
    EnsureDB()
    return FluxNCUtilitySlotsDB.slots
end

function Assign.NormalizeModKey(mod)
    if not mod or mod == "" then
        return ""
    end
    local parts = {}
    for token in string.gmatch(tostring(mod), "[^-]+") do
        local up = string.upper(token)
        if MOD_ORDER[up] then
            parts[#parts + 1] = up
        end
    end
    table.sort(parts, function(a, b)
        return (MOD_ORDER[a] or 99) < (MOD_ORDER[b] or 99)
    end)
    return table.concat(parts, "-")
end

function Assign.GetCurrentModKey()
    local parts = {}
    if IsShiftKeyDown and IsShiftKeyDown() then
        parts[#parts + 1] = "SHIFT"
    end
    if IsControlKeyDown and IsControlKeyDown() then
        parts[#parts + 1] = "CTRL"
    end
    if IsAltKeyDown and IsAltKeyDown() then
        parts[#parts + 1] = "ALT"
    end
    if #parts == 0 then
        return ""
    end
    return Assign.NormalizeModKey(table.concat(parts, "-"))
end

local BINDING_PREFIX = "FLUXSPELLBOOKSLOT"
local _stripImplicitCache = nil
local _stripImplicitCacheValid = false

local function InvalidateStripImplicitCache()
    _stripImplicitCache = nil
    _stripImplicitCacheValid = false
end

local function NotifyChanged()
    InvalidateStripImplicitCache()
    if Assign.OnSlotsChanged then
        pcall(Assign.OnSlotsChanged)
    end
    -- Options panel (Action Bars → Utility slots) preview refresh.
    if Assign.OnPanelSlotsChanged then
        pcall(Assign.OnPanelSlotsChanged)
    end
    local M = Assign.Manager or _G.FluxNCUtilitySlotsManager
    if M and M.UpdateAllSlots then
        M.UpdateAllSlots()
    end
    -- Stance bar hides forms already on utility slots (V9 parity).
    local stance = _G.FluxStanceBar
    if stance and not InCombatLockdown() then
        pcall(function()
            if stance.RequestDedupRefresh then
                stance:RequestDedupRefresh()
            elseif stance.UpdateLayout then
                stance:UpdateLayout()
            end
        end)
    end
    if _G.FluxStanceBarOrderPanel_RequestRefresh then
        pcall(_G.FluxStanceBarOrderPanel_RequestRefresh)
    end
end

local function IsToyItem(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    if PlayerHasToy and PlayerHasToy(itemID) then
        return true
    end
    if C_ToyBox and C_ToyBox.GetToyInfo then
        local ok, info = pcall(C_ToyBox.GetToyInfo, itemID)
        if ok and info then
            return true
        end
    end
    return false
end

local function ResolveSpellName(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    -- Prefer Name(Rank N) for classic lower-rank casts (Extra Button FormatCastAttribute).
    local Flux = _G.Flux
    if Flux and Flux.Spell and Flux.Spell.FormatCastAttribute then
        local attr = Flux.Spell.FormatCastAttribute(spellID)
        if type(attr) == "string" and attr ~= "" then
            return attr
        end
    end
    if _G.FluxFormatSpellCastAttribute then
        local attr = _G.FluxFormatSpellCastAttribute(spellID)
        if type(attr) == "string" and attr ~= "" then
            return attr
        end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.name
    end
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    return nil
end

local function ResolveItemName(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    if GetItemInfo then
        return GetItemInfo(itemID)
    end
    if C_Item and C_Item.GetItemNameByID then
        return C_Item.GetItemNameByID(itemID)
    end
    return nil
end

local function ResolveMountName(mountID)
    mountID = tonumber(mountID)
    if not mountID then
        return nil
    end
    if C_MountJournal and C_MountJournal.GetMountInfoByID then
        local name = C_MountJournal.GetMountInfoByID(mountID)
        return name
    end
    return nil
end

--- Parse GetCursorInfo into { type, id, name } or nil.
function Assign.ParseCursor()
    local cursorType, a1, a2, a3 = GetCursorInfo()
    if not cursorType then
        return nil
    end
    cursorType = string.lower(tostring(cursorType))
    if cursorType == "outfit" then
        local info = Assign.GetOutfitInfo(a1)
        if info and not info.isDisabled then return { type = "outfit", id = info.id, name = info.name } end
        return nil
    end

    if cursorType == "spell" then
        local spellID = tonumber(a3) or tonumber(a1)
        if not spellID then
            return nil
        end
        local outfitID = Assign.GetOutfitIDForSpell(spellID)
        local outfit = outfitID ~= nil and Assign.GetOutfitInfo(outfitID)
        if outfit then return { type = "outfit", id = outfit.id, name = outfit.name } end
        return {
            type = "spell",
            id = spellID,
            name = ResolveSpellName(spellID),
        }
    end

    if cursorType == "item" then
        local itemID = tonumber(a1)
        if not itemID then
            local link = a2 or a3
            if type(link) == "string" then
                itemID = tonumber(link:match("item:(%d+)"))
            end
        end
        if not itemID then
            return nil
        end
        if IsToyItem(itemID) then
            return {
                type = "toy",
                id = itemID,
                name = ResolveItemName(itemID),
            }
        end
        return {
            type = "item",
            id = itemID,
            name = ResolveItemName(itemID),
        }
    end

    if cursorType == "macro" then
        local macroIndex = tonumber(a1)
        local name = a2
        if not name and macroIndex and GetMacroInfo then
            name = GetMacroInfo(macroIndex)
        end
        if not macroIndex and not name then
            return nil
        end
        return {
            type = "macro",
            id = macroIndex or name,
            name = name or tostring(macroIndex),
        }
    end

    if cursorType == "mount" then
        local mountID = tonumber(a1)
        if not mountID then
            return nil
        end
        return {
            type = "mount",
            id = mountID,
            name = ResolveMountName(mountID),
        }
    end

    if cursorType == "battlepet" then
        local guid = a1
        if not guid or guid == "" then
            return nil
        end
        return {
            type = "battlepet",
            id = guid,
            name = a2 and tostring(a2) or "Battle Pet",
        }
    end

    if cursorType == "companion" then
        -- Classic companion: mount or critter
        local companionType = a2 or a3
        local index = tonumber(a1)
        if companionType and string.lower(tostring(companionType)) == "mount" and index and GetCompanionInfo then
            local name, _, _, _, _, _, creatureSpellID = GetCompanionInfo("MOUNT", index)
            if creatureSpellID then
                return {
                    type = "spell",
                    id = creatureSpellID,
                    name = name,
                }
            end
            if name then
                return {
                    type = "mount",
                    id = index,
                    name = name,
                }
            end
        end
        return nil
    end

    if cursorType == "toy" then
        local itemID = tonumber(a1)
        if not itemID then
            return nil
        end
        return {
            type = "toy",
            id = itemID,
            name = ResolveItemName(itemID),
        }
    end

    return nil
end

function Assign.HasAssignableCursor()
    return Assign.ParseCursor() ~= nil
end

local VALID_TYPES = {
    outfit = true,
    spell = true,
    item = true,
    macro = true,
    mount = true,
    battlepet = true,
    toy = true,
}

function Assign.Assign(slotIndex, entry, modKey)
    slotIndex = tonumber(slotIndex)
    if not slotIndex or slotIndex < 1 or slotIndex > MAX_SLOTS then
        return false
    end
    if type(entry) ~= "table" or not entry.type or entry.id == nil then
        return false
    end
    if not VALID_TYPES[entry.type] then
        return false
    end
    EnsureDB()
    local key = Assign.NormalizeModKey(modKey or "")
    FluxNCUtilitySlotsDB.slots[slotIndex][key] = {
        type = entry.type,
        id = entry.id,
        name = entry.name,
    }
    NotifyChanged()
    return true
end

function Assign.AssignFromCursor(slotIndex, modKey)
    local entry = Assign.ParseCursor()
    if not entry then
        return false
    end
    local ok = Assign.Assign(slotIndex, entry, modKey or Assign.GetCurrentModKey())
    if ok and ClearCursor then
        ClearCursor()
    end
    return ok
end

function Assign.ClearSlot(slotIndex)
    slotIndex = tonumber(slotIndex)
    if not slotIndex or slotIndex < 1 or slotIndex > MAX_SLOTS then
        return
    end
    EnsureDB()
    FluxNCUtilitySlotsDB.slots[slotIndex] = {}
    NotifyChanged()
end

function Assign.ClearModifier(slotIndex, modKey)
    slotIndex = tonumber(slotIndex)
    if not slotIndex or slotIndex < 1 or slotIndex > MAX_SLOTS then
        return
    end
    EnsureDB()
    local key = Assign.NormalizeModKey(modKey or "")
    local slotMap = FluxNCUtilitySlotsDB.slots[slotIndex]
    if slotMap then
        slotMap[key] = nil
    end
    NotifyChanged()
end

function Assign.SlotHasAssignment(slotIndex)
    local slots = Assign.GetSlots()
    local map = slots and slots[slotIndex]
    if type(map) ~= "table" then
        return false
    end
    for _, entry in pairs(map) do
        if type(entry) == "table" and entry.type and entry.id ~= nil then
            return true
        end
    end
    return false
end

--- When nomod is empty, mirror from these mods (user priority).
local MIRROR_PREF_ORDER = {
    "SHIFT",
    "CTRL",
    "ALT",
    "SHIFT-CTRL",
    "SHIFT-ALT",
    "CTRL-ALT",
    "SHIFT-CTRL-ALT",
}

function Assign.GetMirrorPrefOrder()
    return MIRROR_PREF_ORDER
end

--- Resolve entry for a slot map under nomod: real "" or first mirror hit.
function Assign.ResolveNomodEntry(map)
    if type(map) ~= "table" then
        return nil, nil
    end
    local nomod = map[""]
    if type(nomod) == "table" and nomod.type and nomod.id ~= nil then
        return nomod, ""
    end
    for i = 1, #MIRROR_PREF_ORDER do
        local key = MIRROR_PREF_ORDER[i]
        local e = map[key]
        if type(e) == "table" and e.type and e.id ~= nil then
            return e, key
        end
    end
    return nil, nil
end

--- Preferred entry for icon/base: nomod first, else mirror order.
function Assign.GetPreferredEntry(slotIndex)
    local slots = Assign.GetSlots()
    local map = slots and slots[slotIndex]
    return Assign.ResolveNomodEntry(map)
end

-- ---------------------------------------------------------------------------
-- Respec / profile snapshots
-- ---------------------------------------------------------------------------

local function DeepCopyUtilityTable(t)
    if type(t) ~= "table" then
        return t
    end
    local n = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            n[k] = DeepCopyUtilityTable(v)
        else
            n[k] = v
        end
    end
    return n
end

--- Normalize one slot map for compare: key → { type, id }.
local function NormalizeSlotMapForCompare(map)
    local out = {}
    if type(map) ~= "table" then
        return out
    end
    for modKey, entry in pairs(map) do
        if type(entry) == "table" then
            local typ, id
            if entry.type and entry.id ~= nil then
                typ, id = entry.type, entry.id
            elseif entry.spellID then
                -- Legacy spellbook-slot snapshot shape.
                typ, id = "spell", entry.spellID
            end
            if typ and id ~= nil then
                out[tostring(modKey or "")] = {
                    type = typ,
                    id = id,
                }
            end
        end
    end
    return out
end

--- Convert legacy FluxSpellBookSlots snapshot ({ spellID, ... }) into utility shape.
function Assign.MigrateLegacySpellBookSnapshot(snap)
    if type(snap) ~= "table" then
        return nil
    end
    if type(snap.slots) ~= "table" then
        return nil
    end
    local slots = {}
    for slotIndex = 1, MAX_SLOTS do
        local src = snap.slots[slotIndex]
        local dst = {}
        if type(src) == "table" then
            for modKey, entry in pairs(src) do
                if type(entry) == "table" then
                    if entry.type and entry.id ~= nil then
                        dst[modKey] = {
                            type = entry.type,
                            id = entry.id,
                            name = entry.name,
                        }
                    elseif entry.spellID then
                        local spellID = entry.spellID
                        dst[modKey] = {
                            type = "spell",
                            id = spellID,
                            name = ResolveSpellName(spellID),
                        }
                    end
                end
            end
        end
        slots[slotIndex] = dst
    end
    return { slots = slots }
end

function Assign.CaptureSnapshot()
    EnsureDB()
    return {
        slots = DeepCopyUtilityTable(FluxNCUtilitySlotsDB.slots),
    }
end

function Assign.MatchesSnapshot(snap)
    if type(snap) ~= "table" then
        return false
    end
    -- Accept legacy spellbook snapshots by normalizing both sides.
    local normalized = snap
    if type(snap.slots) == "table" then
        local sample
        for i = 1, MAX_SLOTS do
            local m = snap.slots[i]
            if type(m) == "table" then
                for _, e in pairs(m) do
                    if type(e) == "table" then
                        sample = e
                        break
                    end
                end
            end
            if sample then
                break
            end
        end
        if sample and sample.spellID and not sample.type then
            normalized = Assign.MigrateLegacySpellBookSnapshot(snap) or snap
        end
    end
    EnsureDB()
    for slotIndex = 1, MAX_SLOTS do
        local live = NormalizeSlotMapForCompare(FluxNCUtilitySlotsDB.slots and FluxNCUtilitySlotsDB.slots[slotIndex])
        local saved = NormalizeSlotMapForCompare(normalized.slots and normalized.slots[slotIndex])
        for k, v in pairs(saved) do
            local lv = live[k]
            if not lv or lv.type ~= v.type or tostring(lv.id) ~= tostring(v.id) then
                return false
            end
        end
        for k in pairs(live) do
            if saved[k] == nil then
                return false
            end
        end
    end
    return true
end

function Assign.ApplySnapshot(snap)
    if type(snap) ~= "table" then
        return false, "NO_SNAPSHOT"
    end
    if InCombatLockdown and InCombatLockdown() then
        return false, "IN_COMBAT"
    end
    local normalized = snap
    if type(snap.slots) == "table" then
        local sample
        for i = 1, MAX_SLOTS do
            local m = snap.slots[i]
            if type(m) == "table" then
                for _, e in pairs(m) do
                    if type(e) == "table" then
                        sample = e
                        break
                    end
                end
            end
            if sample then
                break
            end
        end
        if sample and sample.spellID and not sample.type then
            normalized = Assign.MigrateLegacySpellBookSnapshot(snap)
        end
    end
    if type(normalized) ~= "table" or type(normalized.slots) ~= "table" then
        return false, "NO_SNAPSHOT"
    end
    EnsureDB()
    for i = 1, MAX_SLOTS do
        FluxNCUtilitySlotsDB.slots[i] = {}
    end
    for slotIndex = 1, MAX_SLOTS do
        local slotMap = normalized.slots[slotIndex]
        if type(slotMap) == "table" then
            for modKey, entry in pairs(slotMap) do
                if type(entry) == "table" and entry.type and entry.id ~= nil and VALID_TYPES[entry.type] then
                    local key = Assign.NormalizeModKey(modKey or "")
                    FluxNCUtilitySlotsDB.slots[slotIndex][key] = {
                        type = entry.type,
                        id = entry.id,
                        name = entry.name,
                    }
                end
            end
        end
    end
    NotifyChanged()
    return true
end

-- ---------------------------------------------------------------------------
-- Binding-facing APIs (strip implicits, base spell, assignment labels)
-- Also exported as FluxSpellBookSlots_* aliases for Binding call sites.
-- ---------------------------------------------------------------------------

function Assign.GetBaseSpellID(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.overridesSpellID then
            local baseID = spellID
            while info and info.overridesSpellID do
                baseID = info.overridesSpellID
                info = C_Spell.GetSpellInfo(baseID)
            end
            return baseID
        end
    end
    if FindBaseSpellByID then
        local ok, base = pcall(FindBaseSpellByID, spellID)
        if ok and type(base) == "number" and base > 0 then
            return base
        end
    end
    return spellID
end

function Assign.FormatAssignmentTierLabel(modKey)
    if not modKey or modKey == "" then
        return "Default (no modifier)"
    end
    return tostring(modKey)
end

local function EntrySpellID(entry)
    if type(entry) ~= "table" then
        return nil
    end
    if entry.type == "spell" then
        return tonumber(entry.id)
    end
    -- Legacy spellbook-slot shape
    if entry.spellID and (not entry.type or entry.type == "spell") then
        return tonumber(entry.spellID)
    end
    return nil
end

--- @return number|nil slotIndex, string|nil modKey
function Assign.GetSpellAssignment(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil, nil
    end
    local wantBase = Assign.GetBaseSpellID(spellID) or spellID
    local slots = Assign.GetSlots()
    local bestSlot, bestMod
    for slotIndex = 1, MAX_SLOTS do
        local map = slots[slotIndex]
        if type(map) == "table" then
            for modKey, entry in pairs(map) do
                local sid = EntrySpellID(entry)
                if sid then
                    local base = Assign.GetBaseSpellID(sid) or sid
                    if base == wantBase or sid == spellID or sid == wantBase then
                        -- Prefer nomod tier when multiple matches
                        if not bestSlot or (modKey == "" and bestMod ~= "") then
                            bestSlot, bestMod = slotIndex, modKey
                        end
                    end
                end
            end
        end
    end
    return bestSlot, bestMod
end

function Assign.GetStripImplicitMapKeyForSpell(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    return Assign.GetBaseSpellID(spellID) or spellID
end

local function UnionUniqueStrings(dst, src)
    dst = dst or {}
    local seen = {}
    for i = 1, #dst do
        seen[dst[i]] = true
    end
    for i = 1, #(src or {}) do
        local s = src[i]
        if s and s ~= "" and not seen[s] then
            seen[s] = true
            dst[#dst + 1] = s
        end
    end
    return dst
end

local function CollectSlotBindingChords(slotIndex)
    local chords = {}
    if not GetBindingKey then
        return chords
    end
    local bindingName = BINDING_PREFIX .. tostring(slotIndex)
    local k1, k2 = GetBindingKey(bindingName)
    if k1 and k1 ~= "" then
        chords[#chords + 1] = k1
    end
    if k2 and k2 ~= "" and k2 ~= k1 then
        chords[#chords + 1] = k2
    end
    return chords
end

local function BuildStripImplicitMap()
    local out = {}
    local slots = Assign.GetSlots()
    for slotIndex = 1, MAX_SLOTS do
        local map = slots[slotIndex]
        if type(map) == "table" then
            local slotChords = CollectSlotBindingChords(slotIndex)
            for modKey, entry in pairs(map) do
                local sid = EntrySpellID(entry)
                if sid then
                    local base = Assign.GetBaseSpellID(sid) or sid
                    local row = out[base]
                    if not row then
                        row = {
                            chords = {},
                            pushFrames = {},
                            castSpellID = sid,
                            spellBookStripModKeys = {},
                            isPet = not not (entry.isPet),
                        }
                        out[base] = row
                    end
                    UnionUniqueStrings(row.chords, slotChords)
                    local mk = Assign.NormalizeModKey(modKey or "")
                    local hasMod = false
                    for i = 1, #row.spellBookStripModKeys do
                        if row.spellBookStripModKeys[i] == mk then
                            hasMod = true
                            break
                        end
                    end
                    if not hasMod then
                        row.spellBookStripModKeys[#row.spellBookStripModKeys + 1] = mk
                    end
                    if entry.isPet then
                        row.isPet = true
                    end
                end
            end
        end
    end
    return out
end

function Assign.GetAllStripImplicitBindings()
    if _stripImplicitCacheValid and _stripImplicitCache then
        return _stripImplicitCache
    end
    _stripImplicitCache = BuildStripImplicitMap()
    _stripImplicitCacheValid = true
    return _stripImplicitCache
end

function Assign.InvalidateStripImplicitCache()
    InvalidateStripImplicitCache()
end

-- Binding / keybind changes must refresh chords without a full slot assign.
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("UPDATE_BINDINGS")
    f:SetScript("OnEvent", function()
        if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        InvalidateStripImplicitCache()
    end)
end

-- Global exports (NC names + legacy Binding aliases).
function _G.FluxNCUtilitySlots_GetBaseSpellID(spellID)
    return Assign.GetBaseSpellID(spellID)
end
function _G.FluxNCUtilitySlots_GetSpellAssignment(spellID)
    return Assign.GetSpellAssignment(spellID)
end
function _G.FluxNCUtilitySlots_FormatAssignmentTierLabel(modKey)
    return Assign.FormatAssignmentTierLabel(modKey)
end
function _G.FluxNCUtilitySlots_GetAllStripImplicitBindings()
    return Assign.GetAllStripImplicitBindings()
end
function _G.FluxNCUtilitySlots_GetStripImplicitMapKeyForSpell(spellID)
    return Assign.GetStripImplicitMapKeyForSpell(spellID)
end

_G.FluxSpellBookSlots_GetBaseSpellID = _G.FluxNCUtilitySlots_GetBaseSpellID
_G.FluxSpellBookSlots_GetSpellAssignment = _G.FluxNCUtilitySlots_GetSpellAssignment
_G.FluxSpellBookSlots_FormatAssignmentTierLabel = _G.FluxNCUtilitySlots_FormatAssignmentTierLabel
_G.FluxSpellBookSlots_GetAllStripImplicitBindings = _G.FluxNCUtilitySlots_GetAllStripImplicitBindings
_G.FluxSpellBookSlots_GetStripImplicitMapKeyForSpell = _G.FluxNCUtilitySlots_GetStripImplicitMapKeyForSpell

-- Respec / preset API (and legacy spellbook-slot names as aliases).
function _G.FluxNCUtilitySlots_CaptureSnapshot()
    return Assign.CaptureSnapshot()
end

function _G.FluxNCUtilitySlots_MatchesSnapshot(snap)
    return Assign.MatchesSnapshot(snap)
end

function _G.FluxNCUtilitySlots_ApplySnapshot(snap)
    return Assign.ApplySnapshot(snap)
end

-- Back-compat aliases so older Respec call sites keep working during transition.
_G.FluxSpellBookSlots_CaptureSnapshot = _G.FluxNCUtilitySlots_CaptureSnapshot
_G.FluxSpellBookSlots_MatchesSnapshot = _G.FluxNCUtilitySlots_MatchesSnapshot
_G.FluxSpellBookSlots_ApplySnapshot = _G.FluxNCUtilitySlots_ApplySnapshot

_G.FluxNCUtilitySlots = Assign
return Assign
