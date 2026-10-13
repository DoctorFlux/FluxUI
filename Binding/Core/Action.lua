-- Binding/Core/Action.lua
-- Action descriptors: what a binding casts/uses. Inventory-aware via FluxInv.

local addonName, ns = ...

local Action = {}
ns.FluxBindingAction = Action
_G.FluxBindingAction3 = Action

local FLUX_API = _G.FLUX_API or {}

-- ---------------------------------------------------------------------------
-- Client shims
-- ---------------------------------------------------------------------------

local function GetSpellInfoCompat(spell)
    if C_Spell and C_Spell.GetSpellInfo then
        local si = C_Spell.GetSpellInfo(spell)
        if si then
            return si.name, si.iconID, si.spellID
        end
        return nil
    end
    local name, _, icon, _, _, _, spellID = GetSpellInfo(spell)
    return name, icon, spellID
end
Action.GetSpellInfoCompat = GetSpellInfoCompat

local function GetSpellSubtextCompat(spellID)
    if C_Spell and C_Spell.GetSpellSubtext then
        return C_Spell.GetSpellSubtext(spellID)
    end
    if GetSpellSubtext then
        return GetSpellSubtext(spellID)
    end
    return nil
end
Action.GetSpellSubtextCompat = GetSpellSubtextCompat

--- Classic GetSpellInfo is immediate. Forever/live C_Spell returns nil until cached.
--- No IsSpellDataCached API means "already available" (do not skip rank text).
function Action.SpellDataCached(spellID)
    if not (C_Spell and C_Spell.IsSpellDataCached) then
        return true
    end
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 then
        return true
    end
    local ok, cached = pcall(C_Spell.IsSpellDataCached, spellID)
    if not ok then
        return true
    end
    return cached and true or false
end

local spellLoadRequested = {}

function Action.RequestSpellData(spellID)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 then
        return
    end
    if not (C_Spell and C_Spell.RequestLoadSpellData) then
        return
    end
    if spellLoadRequested[spellID] then
        return
    end
    spellLoadRequested[spellID] = true
    pcall(C_Spell.RequestLoadSpellData, spellID)
end

function Action.NoteSpellDataLoaded(spellID)
    spellID = tonumber(spellID)
    if spellID then
        spellLoadRequested[spellID] = nil
    end
end

local function GetItemInfoInstantCompat(item)
    if C_Item and C_Item.GetItemInfoInstant then
        return C_Item.GetItemInfoInstant(item)
    end
    if GetItemInfoInstant then
        return GetItemInfoInstant(item)
    end
    return nil
end

local function GetItemNameCompat(itemID)
    if C_Item and C_Item.GetItemInfo then
        return (C_Item.GetItemInfo(itemID))
    end
    if GetItemInfo then
        return (GetItemInfo(itemID))
    end
    return nil
end

local function GetItemIconCompat(itemID)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemID)
    end
    if GetItemIcon then
        return GetItemIcon(itemID)
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Descriptor constructors
-- ---------------------------------------------------------------------------

function Action.Spell(spellID, name)
    spellID = tonumber(spellID)
    -- SoD: remap spellbook placeholder rune ids to the engraved learned spell
    local Eng = ns.FluxBindingEngraving
    if Eng and Eng.ResolveLearnedSpellId and spellID then
        local learned = Eng.ResolveLearnedSpellId(spellID, spellID, nil)
        if learned then spellID = learned end
    end
    if not name then
        name = GetSpellInfoCompat(spellID)
    end
    return { type = "spell", id = spellID, name = name }
end

--- Pet-book / pet-bar ability (hunter pet, warlock demon, Water Elemental, …).
--- Same cast pipeline as player spells; flagged so availability uses the pet bank.
function Action.PetSpell(spellID, name)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 then return nil end
    if not name then
        name = GetSpellInfoCompat(spellID)
    end
    return { type = "spell", id = spellID, name = name, pet = true }
end

function Action.IsPetSpell(desc)
    return type(desc) == "table" and desc.type == "spell" and desc.pet == true
end

function Action.Item(itemID, name)
    if not name then
        name = GetItemNameCompat(itemID)
    end
    return { type = "item", id = tonumber(itemID), name = name }
end

--- Equipment slot used as a multi-cast extra (/use N). Identity is the slot, not the item.
function Action.EquipSlot(slotId)
    slotId = tonumber(slotId)
    if not slotId or slotId < 1 or slotId > 19 then return nil end
    return { type = "slot", id = slotId }
end

function Action.Macro(macroName)
    return { type = "macro", name = macroName }
end

--- Virtual ExtraButtonSystem role (best food / smart mount / hearth / …).
--- Not a specific bag item — the button itself.
function Action.Extra(role, name, icon)
    if not role or role == "" then return nil end
    return {
        type = "extra",
        id = tostring(role),
        name = name or tostring(role),
        icon = icon,
    }
end

--- Descriptor from the cursor (editor drag-in). Returns nil for unsupported kinds.
function Action.FromCursor()
    local kind, a, b, c, d = GetCursorInfo()
    if not kind then return nil end
    if kind == "spell" then
        -- Retail: index, bookType, spellID [, baseSpellID]
        -- Prefer explicit spellID; fall back to base / index heuristics.
        local spellID = tonumber(c) or tonumber(d) or tonumber(b)
        if (not spellID or spellID <= 0) and type(a) == "number" and a > 0 and type(b) == "string" then
            if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
                local info = C_SpellBook.GetSpellBookItemInfo(a, b)
                spellID = info and (info.spellID or info.actionID)
            elseif GetSpellBookItemInfo then
                local _, id = GetSpellBookItemInfo(a, b)
                spellID = tonumber(id)
            end
        end
        if spellID and spellID > 0 then
            return Action.Spell(spellID)
        end
    elseif kind == "item" then
        local itemID = tonumber(a)
        if itemID and itemID > 0 then
            return Action.Item(itemID)
        end
    elseif kind == "macro" then
        local name = GetMacroInfo and GetMacroInfo(a)
        if name then
            return Action.Macro(name)
        end
    elseif kind == "petaction" then
        -- Cursor may carry a spell id or a pet-action slot index.
        local spellID = tonumber(a)
        local name
        if (not spellID or spellID <= 0) and type(a) == "number" and GetPetActionInfo then
            local petName, _, _, _, _, _, petSpellID = GetPetActionInfo(a)
            spellID = tonumber(petSpellID)
            name = petName
        elseif spellID and spellID > 0 and GetPetActionInfo and NUM_PET_ACTION_SLOTS then
            -- Prefer live pet-bar name when `a` is an index that also looks like an id.
            for i = 1, NUM_PET_ACTION_SLOTS do
                local petName, _, _, _, _, _, petSpellID = GetPetActionInfo(i)
                if tonumber(petSpellID) == spellID then
                    name = petName
                    break
                end
            end
        end
        if spellID and spellID > 0 then
            return Action.PetSpell(spellID, name)
        end
    elseif kind == "mount" then
        if C_MountJournal and C_MountJournal.GetMountInfoByID then
            local name, spellID = C_MountJournal.GetMountInfoByID(a)
            if spellID then
                return Action.Spell(spellID, name)
            end
        end
    elseif kind == "battlepet" then
        -- Ignore battle pets in the binding editor.
        return nil
    end
    return nil
end

--- Descriptor from a spellbook row (SpellbookHooks / editor open arg).
function Action.FromSpellbookRow(row)
    if type(row) ~= "table" then return nil end
    local spellID = row.actionID and row.actionID ~= 0 and row.actionID or row.spellID
    if not spellID then return nil end
    local isPet = row._fluxPetSpellbook
        or (Enum and Enum.SpellBookItemType
            and row.itemType == Enum.SpellBookItemType.PetAction)
    if isPet then
        return Action.PetSpell(spellID, row.name)
    end
    local Eng = ns.FluxBindingEngraving
    if Eng and Eng.ResolveLearnedSpellId then
        local iconID = row.iconID
        if not iconID and C_Spell and C_Spell.GetSpellTexture then
            iconID = C_Spell.GetSpellTexture(spellID)
        elseif not iconID and GetSpellTexture then
            iconID = GetSpellTexture(spellID)
        end
        local learned = Eng.ResolveLearnedSpellId(spellID, row.actionID or spellID, iconID)
        if learned then
            spellID = learned
            -- Prefer real spell name over placeholder row name
            return Action.Spell(spellID)
        end
    end
    return Action.Spell(spellID, row.name)
end

-- ---------------------------------------------------------------------------
-- Identity / display
-- ---------------------------------------------------------------------------

--- Lowercased spell name used for Classic rank-sync grouping.
function Action.SpellNameKey(spellOrDesc)
    local spellID, name
    if type(spellOrDesc) == "table" then
        spellID = spellOrDesc.id
        name = spellOrDesc.name
    else
        spellID = tonumber(spellOrDesc)
    end
    if not name and spellID then
        name = GetSpellInfoCompat(spellID)
    end
    if type(name) ~= "string" or name == "" then return "" end
    return name:lower()
end

--- Classic / era clients with per-rank bars — offer Sync all ranks.
function Action.ShouldOfferRankSync()
    return FLUX_API.supportsPerRankSpellBarFeatures == true
end

function Action.IsRankSyncByName(spellOrDesc)
    if not Action.ShouldOfferRankSync() then return false end
    local nameKey = Action.SpellNameKey(spellOrDesc)
    if nameKey == "" then return false end
    local DB = ns.FluxBindingDB3
    return DB and DB.IsRankSyncName and DB.IsRankSyncName(nameKey)
end

--- Stable identity key ("s12345", "i6948", "m:My Macro").
--- Per-rank by default — use FamilyKey when rank-sync is on.
function Action.Key(desc)
    if type(desc) ~= "table" then return nil end
    if desc.type == "spell" and desc.id then
        return "s" .. desc.id
    elseif desc.type == "item" and desc.id then
        return "i" .. desc.id
    elseif desc.type == "slot" and desc.id then
        return "slot:" .. tostring(desc.id)
    elseif desc.type == "macro" and desc.name then
        return "m:" .. desc.name
    elseif desc.type == "extra" and desc.id then
        return "extra:" .. tostring(desc.id)
    end
    return nil
end

--- Family identity: rank-synced spells collapse to "sn:<name>", else Action.Key.
function Action.FamilyKey(desc)
    if type(desc) ~= "table" then return nil end
    if desc.type == "spell" and desc.id and Action.IsRankSyncByName(desc) then
        local nk = Action.SpellNameKey(desc)
        if nk ~= "" then return "sn:" .. nk end
    end
    return Action.Key(desc)
end

--- Action key for a bar slot spell id (respects rank sync).
function Action.SlotActionKey(spellID)
    spellID = tonumber(spellID)
    if not spellID then return nil end
    if Action.IsRankSyncByName(spellID) then
        local nk = Action.SpellNameKey(spellID)
        if nk ~= "" then return "sn:" .. nk end
    end
    return "s" .. spellID
end

--- True when `actionKey` refers to this descriptor (id or synced name family).
function Action.KeysMatch(desc, actionKey)
    if type(desc) ~= "table" or type(actionKey) ~= "string" then return false end
    if Action.Key(desc) == actionKey then return true end
    if Action.FamilyKey(desc) == actionKey then return true end
    local sid = actionKey:match("^s(%d+)$")
    if sid and desc.type == "spell" and desc.id then
        local id = tonumber(sid)
        if id and Action.IsRankSyncByName(id)
            and Action.SpellNameKey(id) == Action.SpellNameKey(desc.id) then
            return true
        end
    end
    local sn = actionKey:match("^sn:(.+)$")
    if sn and desc.type == "spell" and desc.id then
        return Action.SpellNameKey(desc.id) == sn
    end
    return false
end

--- Rank label for UI, e.g. "Rank 3" / subtext, or nil.
function Action.GetRankSubtext(desc)
    if type(desc) ~= "table" or desc.type ~= "spell" or not desc.id then return nil end
    local sub = GetSpellSubtextCompat(desc.id)
    if type(sub) == "string" and sub ~= "" then return sub end
    return nil
end

--- Display name with optional rank / "(all ranks)" when synced.
function Action.GetNameWithRank(desc)
    local name = Action.GetName(desc)
    if not name then return "?" end
    if not Action.ShouldOfferRankSync() then return name end
    if Action.IsRankSyncByName(desc) then
        local L = _G.FluxSpellBindingLocale
        local suffix = (L and L["(all ranks)"]) or "(all ranks)"
        return name .. " " .. suffix
    end
    local sub = Action.GetRankSubtext(desc)
    if sub then return name .. " (" .. sub .. ")" end
    return name
end

local function EnumerateSpellIdsForNameKey(nameKey)
    local out, seen = {}, {}
    if not nameKey or nameKey == "" then return out end
    local function add(id)
        id = tonumber(id)
        if id and id > 0 and not seen[id] then
            seen[id] = true
            out[#out + 1] = id
        end
    end
    -- Spellbook
    if C_SpellBook and C_SpellBook.GetNumSpellBookItems and C_SpellBook.GetSpellBookItemInfo then
        local banks = {}
        if Enum and Enum.SpellBookSpellBank then
            banks[#banks + 1] = Enum.SpellBookSpellBank.Player
            if Enum.SpellBookSpellBank.Pet then
                banks[#banks + 1] = Enum.SpellBookSpellBank.Pet
            end
        else
            banks[1] = 0
        end
        for _, bank in ipairs(banks) do
            local n = C_SpellBook.GetNumSpellBookItems(bank) or 0
            for i = 1, n do
                local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
                if info and info.spellID and Action.SpellNameKey(info.spellID) == nameKey then
                    add(info.spellID)
                end
            end
        end
    elseif GetNumSpellTabs and GetSpellBookItemName then
        local tabs = GetNumSpellTabs() or 0
        for t = 1, tabs do
            local _, _, offset, num = GetSpellTabInfo(t)
            offset = offset or 0
            num = num or 0
            for i = offset + 1, offset + num do
                local name, subName, id = GetSpellBookItemName(i, BOOKTYPE_SPELL or "spell")
                if id and Action.SpellNameKey(id) == nameKey then
                    add(id)
                elseif name and name:lower() == nameKey then
                    local link = GetSpellLink and GetSpellLink(i, BOOKTYPE_SPELL or "spell")
                    local sid = link and tonumber(link:match("spell:(%d+)"))
                    add(sid)
                end
            end
        end
    end
    -- Existing binding instances
    local DB = ns.FluxBindingDB3
    if DB and DB.All then
        for _, b in pairs(DB.All()) do
            if b.action and b.action.type == "spell" and b.action.id
                and Action.SpellNameKey(b.action.id) == nameKey then
                add(b.action.id)
            end
        end
    end
    table.sort(out)
    return out
end
Action.EnumerateSpellIdsForNameKey = EnumerateSpellIdsForNameKey

--- Enable/disable shared settings across all ranks of this spell name.
--- On: merge sibling binding rows into one. Off: copy forms onto each known rank.
function Action.SetRankSyncByName(spellID, enabled)
    if not Action.ShouldOfferRankSync() then return end
    spellID = tonumber(spellID)
    if not spellID then return end
    local nameKey = Action.SpellNameKey(spellID)
    if nameKey == "" then return end
    local DB = ns.FluxBindingDB3
    if not DB then return end

    if enabled then
        DB.SetRankSyncName(nameKey, true)
        local siblings = {}
        for uid, b in pairs(DB.All()) do
            if b.action and b.action.type == "spell" and b.action.id
                and Action.SpellNameKey(b.action.id) == nameKey then
                siblings[#siblings + 1] = b
            end
        end
        local keep
        for i = 1, #siblings do
            if siblings[i].action.id == spellID then
                keep = siblings[i]
                break
            end
        end
        keep = keep or siblings[1]
        if not keep then
            keep = DB.Add(Action.Spell(spellID))
        else
            local wasPet = keep.action and keep.action.pet
            if wasPet and Action.PetSpell then
                keep.action = Action.PetSpell(spellID, keep.action and keep.action.name)
            else
                keep.action = Action.Spell(spellID, keep.action and keep.action.name)
            end
        end
        for i = 1, #siblings do
            local b = siblings[i]
            if b.uid ~= keep.uid then
                if (not keep.key or keep.key == "") and b.key and b.key ~= "" then
                    keep.key = b.key
                end
                if b.fallback and b.fallback ~= "ACTION_BAR" then
                    keep.fallback = b.fallback
                end
                -- Prefer non-default forms from a sibling if keep is pristine.
                local FB = _G.FluxBinding
                if FB and FB.IsBindingCustomized and not FB.IsBindingCustomized(keep)
                    and FB.IsBindingCustomized(b) and type(b.forms) == "table" then
                    keep.forms = {}
                    for token, sub in pairs(b.forms) do
                        keep.forms[token] = DB.DeepCopyFormSub(sub)
                    end
                end
                DB.Remove(b.uid)
            end
        end
    else
        DB.SetRankSyncName(nameKey, false)
        local keep
        for uid, b in pairs(DB.All()) do
            if b.action and b.action.type == "spell" and b.action.id
                and Action.SpellNameKey(b.action.id) == nameKey then
                keep = b
                break
            end
        end
        if keep then
            local ranks = EnumerateSpellIdsForNameKey(nameKey)
            local have = {}
            have[keep.action.id] = true
            for i = 1, #ranks do
                local sid = ranks[i]
                if not have[sid] then
                    have[sid] = true
                    local nb = DB.Add(Action.Spell(sid))
                    nb.key = nil -- key stays on the original instance only
                    nb.fallback = keep.fallback
                    nb.forms = {}
                    for token, sub in pairs(keep.forms or {}) do
                        nb.forms[token] = DB.DeepCopyFormSub(sub)
                    end
                end
            end
        end
    end

    local FluxBinding = _G.FluxBinding
    if FluxBinding and FluxBinding.RequestApplyAll then
        FluxBinding.RequestApplyAll("rankSync")
    end
end

--- Remove this spell rank's binding row.
--- If ranks are synced, unsync first (clone settings onto siblings) then drop this rank.
function Action.RemoveRank(spellID)
    if not Action.ShouldOfferRankSync() then return false end
    spellID = tonumber(spellID)
    if not spellID then return false end
    local DB = ns.FluxBindingDB3
    if not DB then return false end

    if Action.IsRankSyncByName(spellID) then
        Action.SetRankSyncByName(spellID, false)
    end

    local nameKey = Action.SpellNameKey(spellID)
    local removed = false
    local toRemove = {}
    for uid, b in pairs(DB.All()) do
        if b.action and b.action.type == "spell" and b.action.id == spellID then
            toRemove[#toRemove + 1] = uid
        end
    end
    for i = 1, #toRemove do
        DB.Remove(toRemove[i])
        removed = true
    end

    -- If this was the last row for the name, clear rank-sync flag.
    if nameKey ~= "" and DB.SetRankSyncName then
        local anyLeft = false
        for _, b in pairs(DB.All()) do
            if b.action and b.action.type == "spell" and b.action.id
                and Action.SpellNameKey(b.action.id) == nameKey then
                anyLeft = true
                break
            end
        end
        if not anyLeft then
            DB.SetRankSyncName(nameKey, false)
        end
    end

    local FluxBinding = _G.FluxBinding
    if removed and FluxBinding and FluxBinding.RequestApplyAll then
        FluxBinding.RequestApplyAll("removeRank")
    end
    return removed
end

function Action.GetName(desc)
    if type(desc) ~= "table" then return "?" end
    if desc.type == "spell" and desc.id then
        local Eng = ns.FluxBindingEngraving
        local id = desc.id
        if Eng and Eng.ResolveLearnedSpellId then
            local learned = Eng.ResolveLearnedSpellId(id, id, nil)
            if learned then id = learned end
        end
        local name = GetSpellInfoCompat(id)
        if name then
            desc.name = name
            if id ~= desc.id then desc.id = id end
            return name
        end
        return desc.name or ("spell:" .. tostring(desc.id))
    elseif desc.type == "item" and desc.id then
        local name = GetItemNameCompat(desc.id)
        if name then
            desc.name = name
            return name
        end
        return desc.name or ("item:" .. desc.id)
    elseif desc.type == "slot" and desc.id then
        local DB = ns.FluxBindingDB3
        if DB and DB.GetMacroExtraLabel then
            return DB.GetMacroExtraLabel({ type = "slot", id = desc.id })
        end
        return desc.name or ("Equip slot " .. tostring(desc.id))
    elseif desc.type == "extra" then
        return desc.name or tostring(desc.id) or "?"
    elseif desc.type == "macro" and desc.name then
        return desc.name
    end
    return desc.name or "?"
end

function Action.GetIcon(desc)
    if type(desc) ~= "table" then return 134400 end
    if desc.type == "spell" and desc.id then
        local id = desc.id
        local Eng = ns.FluxBindingEngraving
        if Eng and Eng.ResolveLearnedSpellId then
            local learned = Eng.ResolveLearnedSpellId(id, id, nil)
            if learned then id = learned end
        end
        if C_Spell and C_Spell.GetSpellTexture then
            return C_Spell.GetSpellTexture(id) or 134400
        end
        return GetSpellTexture(id) or 134400
    elseif desc.type == "item" and desc.id then
        return GetItemIconCompat(desc.id) or 134400
    elseif desc.type == "slot" and desc.id then
        local DB = ns.FluxBindingDB3
        if DB and DB.GetMacroExtraIcon then
            return DB.GetMacroExtraIcon({ type = "slot", id = desc.id }) or 134400
        end
        if GetInventoryItemTexture then
            return GetInventoryItemTexture("player", desc.id) or 134400
        end
        return 134400
    elseif desc.type == "extra" then
        return desc.icon or 134400
    elseif desc.type == "macro" and desc.name then
        if GetMacroInfo then
            local _, icon = GetMacroInfo(desc.name)
            if icon then return icon end
        end
    end
    return 134400
end

-- ---------------------------------------------------------------------------
-- Availability (FluxInv-aware)
-- ---------------------------------------------------------------------------

local spellBookCache

local function RememberBookSpell(cache, info)
    if type(info) ~= "table" then
        return
    end
    if info.actionID then
        cache.ids[info.actionID] = true
    end
    if info.spellID then
        cache.ids[info.spellID] = true
    end
    if type(info.name) == "string" and info.name ~= "" then
        cache.names[info.name:lower()] = true
    end
end

--- Forever's IsSpellKnown is false for a rank spell until the record is in
--- the modern spell-book cache. The book row still has the name and ids.
local function PlayerSpellBook()
    if spellBookCache then
        return spellBookCache
    end
    local cache = { ids = {}, names = {}, scanned = false }
    spellBookCache = cache
    if not (C_SpellBook and C_SpellBook.GetSpellBookItemInfo and C_SpellBook.GetNumSpellBookSkillLines) then
        return cache
    end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local ok, nTabs = pcall(C_SpellBook.GetNumSpellBookSkillLines)
    if not ok or not nTabs then
        return cache
    end
    cache.scanned = true
    for i = 1, nTabs do
        local lineOk, line = pcall(C_SpellBook.GetSpellBookSkillLineInfo, i)
        if lineOk and line then
            local offset = line.itemIndexOffset or 0
            local count = line.numSpellBookItems or 0
            for j = offset + 1, offset + count do
                local infoOk, info = pcall(C_SpellBook.GetSpellBookItemInfo, j, bank)
                if infoOk then
                    RememberBookSpell(cache, info)
                end
            end
        end
    end
    return cache
end

function Action.InvalidateSpellBookCache()
    spellBookCache = nil
end

local spellBookEv = CreateFrame("Frame")
spellBookEv:SetScript("OnEvent", function()
    Action.InvalidateSpellBookCache()
end)
pcall(spellBookEv.RegisterEvent, spellBookEv, "SPELLS_CHANGED")
pcall(spellBookEv.RegisterEvent, spellBookEv, "SPELL_DATA_LOAD_RESULT")
pcall(spellBookEv.RegisterEvent, spellBookEv, "PLAYER_ENTERING_WORLD")

--- Is the action currently available to the player?
--- spells: learned (FluxInv spell cache -> live API); items: owned (bags /
--- equipped); macros: exists.
--- Pet abilities are ALWAYS available (never parked) so secure macros stay
--- compiled for mid-combat summon/dismiss — [pet]/[@cursor]/[nopet] handle runtime.
function Action.IsAvailable(desc)
    if type(desc) ~= "table" then return false end
    if desc.type == "extra" then
        return true
    end
    if desc.type == "slot" and desc.id then
        if GetInventoryItemID then
            return GetInventoryItemID("player", desc.id) ~= nil
        end
        return GetInventoryItemTexture and GetInventoryItemTexture("player", desc.id) ~= nil
    end
    local Inv = _G.FluxInv
    if desc.type == "spell" then
        if not desc.id then return false end
        if desc.pet then
            return true
        end
        local Lib = ns.FluxBindingSpellLibrary
        if Lib and Lib.IsPetAbilitySpell and Lib.IsPetAbilitySpell(desc.id) then
            return true
        end
        local Eng = ns.FluxBindingEngraving
        if Eng and Eng.IsEquippedRuneAbility and Eng.IsEquippedRuneAbility(desc.id) then
            return true
        end
        if Inv and Inv.IsSpellKnown and Inv.IsSpellKnown(desc.id) then
            return true
        end
        if IsSpellKnown and (IsSpellKnown(desc.id) or (IsPlayerSpell and IsPlayerSpell(desc.id))) then
            return true
        end
        local book = PlayerSpellBook()
        local named = type(desc.name) == "string" and desc.name ~= ""
        if book.ids[desc.id] or (named and book.names[desc.name:lower()]) then
            return true
        end
        -- Forever: C_SpellBook.IsSpellKnown is false until the spell record
        -- loads. A named binding the player just saved must still build badges.
        local cold = Action.SpellDataCached and not Action.SpellDataCached(desc.id)
        local bookEmpty = not next(book.ids) and not next(book.names)
        if named and (cold or bookEmpty) then
            if Action.RequestSpellData then
                Action.RequestSpellData(desc.id)
            end
            return true
        end
        if Inv and Inv.IsSpellKnown then
            return false
        end
        return true
    elseif desc.type == "item" then
        if not desc.id then return false end
        if Inv then
            if Inv.Spells and Inv.Spells.PlayerHasItemInInventory then
                return Inv.Spells.PlayerHasItemInInventory(desc.id) and true or false
            end
            if Inv.GetCount then
                local n = Inv.GetCount(desc.id, { bags = true, equipped = true, bank = false, warband = false })
                return (tonumber(n) or 0) > 0
            end
        end
        local n = (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(desc.id))
            or (GetItemCount and GetItemCount(desc.id)) or 0
        return n > 0
    elseif desc.type == "macro" then
        return GetMacroInfo and GetMacroInfo(desc.name) ~= nil
    end
    return false
end

--- Live count for the editor / badges (items only; charges included).
function Action.GetCount(desc)
    if type(desc) ~= "table" or desc.type ~= "item" or not desc.id then return nil end
    local Inv = _G.FluxInv
    if Inv and Inv.GetLiveCount then
        return Inv.GetLiveCount(desc.id, { includeBank = false })
    end
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(desc.id, false, true)
    end
    return GetItemCount and GetItemCount(desc.id, false, true) or nil
end

-- ---------------------------------------------------------------------------
-- Macro token for /cast lines
-- ---------------------------------------------------------------------------

--- The token used in generated macros for this action.
--- Spells cast by name (with optional "(subtext)" rank on classic); items use
--- the unambiguous item:ID form; macros are not mergeable (handled upstream).
function Action.MacroToken(desc, opts)
    opts = opts or {}
    if type(desc) ~= "table" then return nil end
    if desc.type == "spell" then
        local Eng = ns.FluxBindingEngraving
        if Eng and Eng.ResolveCastIdAndName and desc.id then
            local castId, castName = Eng.ResolveCastIdAndName(desc.id, desc.id, nil)
            if castId and castId ~= desc.id then
                desc.id = castId
            end
            if castName then
                desc.name = castName
            end
        end
        local name = Action.GetName(desc)
        if not name then return nil end
        -- Classic ranks: always Name(Rank N) so bar↔badge reverse macros cast the placed rank.
        local wantSubtext = opts.includeSubtext
            or (FLUX_API.supportsPerRankSpellBarFeatures == true)
        -- Cold Forever spells: skip rank text until the record is cached (Clicked).
        if wantSubtext and desc.id and Action.SpellDataCached(desc.id) then
            local sub = GetSpellSubtextCompat(desc.id)
            if sub and sub ~= "" then
                return name .. "(" .. sub .. ")"
            end
        end
        if opts.preventToggle then
            return "!" .. name
        end
        return name
    elseif desc.type == "item" then
        if desc.id then
            return "item:" .. desc.id
        end
        return desc.name
    elseif desc.type == "slot" and desc.id then
        return tostring(desc.id)
    end
    return nil
end