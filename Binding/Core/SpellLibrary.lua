-- Binding/Core/SpellLibrary.lua
-- Spellbook skill-line catalog (Clicked-style tabName/tabIcon groups) plus
-- items that already have a Binding row or sit on an action bar.

local addonName, ns = ...

local Action = ns.FluxBindingAction
local DB = ns.FluxBindingDB3

local SpellLibrary = {}
ns.FluxBindingSpellLibrary = SpellLibrary

-- Extra buttons group icon (engineering gizmos — fits the Extra button strip).
local EXTRA_TAB_ICON = "Interface\\Icons\\INV_Misc_EngGizmos_20"
SpellLibrary.EXTRA_TAB_ICON = EXTRA_TAB_ICON

-- Stance bar catalog group (forms / mage armors / summons / SoD stance slots).
local STANCE_TAB_ICON = 132349
SpellLibrary.STANCE_TAB_ICON = STANCE_TAB_ICON

-- Multi-cast equipment-slot extras (Trinket 1, Finger 2, …) — not Items.
local EQUIP_SLOTS_TAB_NAME = "Equipment slots"
local EQUIP_SLOTS_TAB_ICON = "Interface\\Icons\\INV_Misc_Gear_01"
SpellLibrary.EQUIP_SLOTS_TAB_NAME = EQUIP_SLOTS_TAB_NAME
SpellLibrary.EQUIP_SLOTS_TAB_ICON = EQUIP_SLOTS_TAB_ICON

-- Pet abilities catalog group (hunter / warlock / mage elemental / …).
local PET_TAB_ICON = 132161 -- Ability_Hunter_BeastCall
local PET_TAB_NAME = "Pet"
SpellLibrary.PET_TAB_ICON = PET_TAB_ICON
SpellLibrary.PET_TAB_NAME = PET_TAB_NAME

local PASSIVE_ICON = 134419 -- Classic profession/rune tab skip (Clicked parity)

-- Last-seen SoD Runes skill-line label (locale-aware) + spell→tab memory for
-- synthesizing bar/binding spells that are missing from the current spellbook.
local cachedRunesTabName, cachedRunesTabIcon
local spellTabById = {}      -- [spellID] = { name=, icon= }
local spellTabByNameKey = {} -- [SpellNameKey] = { name=, icon= }

local function RememberSpellTab(spellID, tabName, tabIcon)
    spellID = tonumber(spellID)
    if not spellID or type(tabName) ~= "string" or tabName == "" then return end
    if tabIcon == PASSIVE_ICON
        or tabName == "Runes"
        or tabName:lower():find("rune", 1, true) then
        cachedRunesTabName = tabName
        cachedRunesTabIcon = tabIcon or PASSIVE_ICON
    end
    spellTabById[spellID] = { name = tabName, icon = tabIcon or 134400 }
    if Action and Action.SpellNameKey and tabIcon ~= PASSIVE_ICON then
        local nk = Action.SpellNameKey(spellID)
        if nk and nk ~= "" then
            spellTabByNameKey[nk] = { name = tabName, icon = tabIcon or 134400 }
        end
    end
end

local function IsSoDRuneSpellId(spellID)
    spellID = tonumber(spellID)
    if not spellID or not _G.C_Engraving then return false end
    local Eng = ns.FluxBindingEngraving
    if not Eng then return false end
    if Eng.IsRuneAbilitySpell and Eng.IsRuneAbilitySpell(spellID) then
        return true
    end
    if Eng.IsEquippedRuneAbility and Eng.IsEquippedRuneAbility(spellID) then
        return true
    end
    if Eng.ResolveLearnedSpellId then
        local learned = Eng.ResolveLearnedSpellId(spellID, spellID, nil)
        if learned and learned ~= spellID then
            if Eng.IsRuneAbilitySpell and Eng.IsRuneAbilitySpell(learned) then
                return true
            end
            if Eng.IsEquippedRuneAbility and Eng.IsEquippedRuneAbility(learned) then
                return true
            end
        end
    end
    return false
end

--- Prefer skill-line tab over General when synthesizing missing bar/binding spells.
local function ResolveSpellTab(spellID, families)
    spellID = tonumber(spellID)
    if not spellID then
        return "General", 134400
    end
    if IsSoDRuneSpellId(spellID) then
        return cachedRunesTabName or "Runes", cachedRunesTabIcon or PASSIVE_ICON
    end
    local hit = spellTabById[spellID]
    if hit then
        return hit.name, hit.icon
    end

    local FindSlot = FindSpellBookSlotBySpellID
        or (C_SpellBook and C_SpellBook.FindSpellBookSlotBySpellID)
    if FindSlot and GetNumSpellTabs and GetSpellTabInfo then
        local ok, slot = pcall(FindSlot, spellID)
        if ok and type(slot) == "number" and slot > 0 then
            local tabs = GetNumSpellTabs() or 0
            for t = 1, tabs do
                local tabName, tabIcon, offset, count = GetSpellTabInfo(t)
                offset = offset or 0
                count = count or 0
                if slot > offset and slot <= offset + count then
                    RememberSpellTab(spellID, tabName, tabIcon)
                    return tabName or "General", tabIcon or 134400
                end
            end
        end
    end

    if Action and Action.SpellNameKey then
        local nk = Action.SpellNameKey(spellID)
        hit = nk and spellTabByNameKey[nk]
        if hit then
            return hit.name, hit.icon
        end
        if type(families) == "table" and nk then
            local fam = families[nk]
            if fam and fam.ids then
                for i = 1, #fam.ids do
                    local sib = fam.byId and fam.byId[fam.ids[i]]
                    if sib and sib.tabName and sib.tabName ~= "General" then
                        return sib.tabName, sib.tabIcon or 134400
                    end
                end
            end
        end
    end

    return "General", 134400
end

local function EntryHasFluxBinding(entry)
    if not (entry and entry.action and DB and DB.UidsForActionKey and Action) then
        return false
    end
    local ak = (Action.FamilyKey and Action.FamilyKey(entry.action)) or Action.Key(entry.action)
    if not ak then return false end
    local uids = DB.UidsForActionKey(ak)
    return type(uids) == "table" and #uids > 0
end

--- SoD: hide runes that are not on a bar / Extra / stance / multi-cast and have
--- no Flux binding in the active binding source.
local function FilterOrphanSoDRunes(catalog)
    if not _G.C_Engraving or type(catalog) ~= "table" then
        return catalog
    end
    local out = {}
    for i = 1, #catalog do
        local e = catalog[i]
        local sid = tonumber(e.spellID)
            or (e.action and e.action.type == "spell" and tonumber(e.action.id))
        local isRune = IsSoDRuneSpellId(sid)
        if not isRune then
            local n = e.tabName
            if e.tabIcon == PASSIVE_ICON
                or n == "Runes"
                or (type(n) == "string" and n:lower():find("rune", 1, true)) then
                isRune = true
            end
        end
        if not isRune then
            out[#out + 1] = e
        else
            local keep = e.onActionBar or e.onExtra or e.onStance or e.onMultiCast
                or EntryHasFluxBinding(e)
            if keep then
                if not e.tabName or e.tabName == "General" then
                    e.tabName = cachedRunesTabName or "Runes"
                    e.tabIcon = cachedRunesTabIcon or PASSIVE_ICON
                end
                out[#out + 1] = e
            end
        end
    end
    return out
end

-- Well-known summon / call-pet spell IDs (class-agnostic gate; names also matched).
local PET_SUMMON_SPELL_IDS = {
    883, 83242, 83243, 83244, 83245, -- Call Pet 1–5
    982,                             -- Revive Pet
    688, 697, 691, 712, 30146, 366222, -- Warlock demons (+ Sayaad era)
    31687,                           -- Summon Water Elemental
    46584, 52150,                    -- Raise Dead (DK)
    51533,                           -- Feral Spirit
}

local function IsPassiveSpell(spellID)
    spellID = tonumber(spellID)
    if not spellID then return false end
    if C_Spell and C_Spell.IsSpellPassive then
        return C_Spell.IsSpellPassive(spellID) and true or false
    end
    if IsPassiveSpell then
        return IsPassiveSpell(spellID) and true or false
    end
    return false
end

local function AddSpell(out, seen, spellID, tabName, tabIcon, specId)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 or seen[spellID] then return end
    if IsPassiveSpell(spellID) then return end
    seen[spellID] = true
    RememberSpellTab(spellID, tabName or "General", tabIcon or 134400)
    local desc = Action and Action.Spell and Action.Spell(spellID) or { type = "spell", id = spellID }
    local displayName = (Action and Action.GetNameWithRank and Action.GetNameWithRank(desc))
        or (Action and Action.GetName and Action.GetName(desc))
        or tostring(spellID)
    out[#out + 1] = {
        kind = "spell",
        spellID = spellID,
        action = desc,
        tabName = tabName or "General",
        tabIcon = tabIcon or 134400,
        specId = specId,
        name = displayName,
        icon = (Action and Action.GetIcon and Action.GetIcon(desc)) or 134400,
    }
end

local function ScanSpellbookClassic(out, seen)
    if not GetNumSpellTabs or not GetSpellTabInfo then return end
    local tabs = GetNumSpellTabs() or 0
    for t = 1, tabs do
        local tabName, tabIcon, offset, count, _, specId = GetSpellTabInfo(t)
        -- Clicked parity: skip the Runes/profession tab (icon 134419); remember
        -- its locale name for synthesized bar/binding rune rows.
        if tabIcon == PASSIVE_ICON then
            cachedRunesTabName = tabName or cachedRunesTabName or "Runes"
            cachedRunesTabIcon = tabIcon or PASSIVE_ICON
        else
            offset = offset or 0
            count = count or 0
            for i = offset + 1, offset + count do
                local spellType, id
                if GetSpellBookItemInfo then
                    spellType, id = GetSpellBookItemInfo(i, BOOKTYPE_SPELL or "spell")
                end
                if (spellType == "SPELL" or spellType == "FUTURESPELL" or not spellType) and id then
                    AddSpell(out, seen, id, tabName, tabIcon, specId)
                elseif GetSpellBookItemName then
                    local name, _, sid = GetSpellBookItemName(i, BOOKTYPE_SPELL or "spell")
                    if sid then
                        AddSpell(out, seen, sid, tabName, tabIcon, specId)
                    elseif name and GetSpellLink then
                        local link = GetSpellLink(i, BOOKTYPE_SPELL or "spell")
                        local linkId = link and tonumber(link:match("spell:(%d+)"))
                        AddSpell(out, seen, linkId, tabName, tabIcon, specId)
                    end
                end
            end
        end
    end

    -- SoD: do NOT dump every rune into the Binding list. Unowned / unengraved /
    -- unbound runes stay out; bar / Extra / stance / Flux-binding rows are
    -- synthesized later in GetCatalog / PruneSpellRanks under the Runes tab.
    if C_Engraving then
        local Eng = ns.FluxBindingEngraving
        if Eng and Eng.Refresh then
            pcall(Eng.Refresh)
        end
    end
end

local function ScanSpellbookTWW(out, seen)
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines
        and C_SpellBook.GetSpellBookSkillLineInfo
        and C_SpellBook.GetSpellBookItemInfo) then
        return false
    end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    local nTabs = C_SpellBook.GetNumSpellBookSkillLines() or 0
    for t = 1, nTabs do
        local tab = C_SpellBook.GetSpellBookSkillLineInfo(t)
        if tab and tab.iconID ~= PASSIVE_ICON then
            local offset = tab.itemIndexOffset or 0
            local count = tab.numSpellBookItems or 0
            for i = offset + 1, offset + count do
                local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
                if info and info.spellID then
                    local itemType = info.itemType
                    local ok = true
                    if Enum and Enum.SpellBookItemType then
                        ok = itemType == Enum.SpellBookItemType.Spell
                            or itemType == Enum.SpellBookItemType.FutureSpell
                    end
                    if ok then
                        AddSpell(out, seen, info.spellID, tab.name, tab.iconID, tab.specID)
                    end
                end
            end
        end
    end
    return true
end

local function ScanSpellbookFlat(out, seen)
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookItems and C_SpellBook.GetSpellBookItemInfo) then
        return
    end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    local n = C_SpellBook.GetNumSpellBookItems(bank) or 0
    for i = 1, n do
        local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
        if info and info.spellID then
            AddSpell(out, seen, info.spellID, "General", 134400, nil)
        end
    end
end

--- All castable player spellbook spells, tagged with skill-line tab name/icon.
function SpellLibrary.GetSpellbookSpells()
    local out, seen = {}, {}
    if not ScanSpellbookTWW(out, seen) then
        if GetNumSpellTabs then
            ScanSpellbookClassic(out, seen)
        else
            ScanSpellbookFlat(out, seen)
        end
    end
    table.sort(out, function(a, b)
        local ta, tb = a.tabName or "", b.tabName or ""
        if ta ~= tb then return ta:lower() < tb:lower() end
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)
    return out
end

local function NameLooksLikePetSummon(name)
    if type(name) ~= "string" or name == "" then return false end
    if name:find("^Call Pet", 1, true) then return true end
    if name:find("^Revive Pet", 1, true) then return true end
    if name:find("^Dismiss Pet", 1, true) then return true end
    if name:find("^Summon Water Elemental", 1, true) then return true end
    if name:find("^Summon Demon", 1, true) then return true end
    if name:find("^Summon Imp", 1, true) then return true end
    if name:find("^Summon Voidwalker", 1, true) then return true end
    if name:find("^Summon Felhunter", 1, true) then return true end
    if name:find("^Summon Succubus", 1, true) then return true end
    if name:find("^Summon Felguard", 1, true) then return true end
    if name:find("^Summon Sayaad", 1, true) then return true end
    if name:find("^Raise Dead", 1, true) then return true end
    if name:find("^Feral Spirit", 1, true) then return true end
    return false
end

local function PlayerKnowsSpellId(spellID)
    spellID = tonumber(spellID)
    if not spellID then return false end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    if IsSpellKnown and IsSpellKnown(spellID) then return true end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID)
        if ok and known then return true end
    end
    return false
end

local function HasLivePetActionSpells()
    if not (UnitExists and UnitExists("pet") and GetPetActionInfo and NUM_PET_ACTION_SLOTS) then
        return false
    end
    for i = 1, NUM_PET_ACTION_SLOTS do
        local name, _, isToken, _, _, _, spellID = GetPetActionInfo(i)
        spellID = tonumber(spellID)
        if spellID and spellID > 0 then
            if isToken and type(name) == "string"
                and (name:find("^PET_ACTION_", 1, true) or name:find("^PET_MODE_", 1, true)) then
                -- command / mode tokens
            else
                return true
            end
        end
    end
    return false
end

local function HasPetSpellBookEntries()
    if HasPetSpells then
        local ok, n = pcall(HasPetSpells)
        if ok and n and n ~= 0 then
            return true
        end
    end
    if C_SpellBook and C_SpellBook.GetNumSpellBookItems and Enum and Enum.SpellBookSpellBank
        and Enum.SpellBookSpellBank.Pet then
        local ok, n = pcall(C_SpellBook.GetNumSpellBookItems, Enum.SpellBookSpellBank.Pet)
        if ok and (tonumber(n) or 0) > 0 then
            return true
        end
    end
    return false
end

--- True when the player has learned a summon/call-pet ability, or pet spells exist.
local canUsePetCache, canUsePetCacheAt

function SpellLibrary.InvalidatePetAbilityGate()
    canUsePetCache = nil
    canUsePetCacheAt = nil
end

local function PlayerSpellbookHasSummonByName()
    if C_SpellBook and C_SpellBook.GetNumSpellBookItems and C_SpellBook.GetSpellBookItemInfo then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        local n = C_SpellBook.GetNumSpellBookItems(bank) or 0
        -- Cap: summon spells sit early; avoid a full-book walk on every gate miss.
        local limit = math.min(n, 400)
        for i = 1, limit do
            local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
            if info and NameLooksLikePetSummon(info.name) then
                return true
            end
        end
        return false
    end
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
        local book = BOOKTYPE_SPELL or "spell"
        local tabs = GetNumSpellTabs() or 0
        for t = 1, tabs do
            local _, _, offset, count = GetSpellTabInfo(t)
            offset = offset or 0
            count = count or 0
            for i = offset + 1, offset + count do
                local name = GetSpellBookItemName(i, book)
                if NameLooksLikePetSummon(name) then
                    return true
                end
            end
        end
    end
    return false
end

function SpellLibrary.PlayerCanUsePetAbilities()
    local now = (GetTime and GetTime()) or 0
    if canUsePetCache ~= nil and canUsePetCacheAt and (now - canUsePetCacheAt) < 2 then
        return canUsePetCache
    end
    local result = false
    if HasPetSpellBookEntries() then
        result = true
    elseif HasLivePetActionSpells() then
        result = true
    else
        for i = 1, #PET_SUMMON_SPELL_IDS do
            if PlayerKnowsSpellId(PET_SUMMON_SPELL_IDS[i]) then
                result = true
                break
            end
        end
        if not result then
            result = PlayerSpellbookHasSummonByName() and true or false
        end
    end
    canUsePetCache = result
    canUsePetCacheAt = now
    return result
end

local function AddPetSpell(out, seen, spellID, tabName, tabIcon)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 or seen[spellID] then return end
    if IsPassiveSpell(spellID) then return end
    seen[spellID] = true
    local desc = Action and Action.PetSpell and Action.PetSpell(spellID)
        or { type = "spell", id = spellID, pet = true }
    local displayName = (Action and Action.GetNameWithRank and Action.GetNameWithRank(desc))
        or (Action and Action.GetName and Action.GetName(desc))
        or tostring(spellID)
    out[#out + 1] = {
        kind = "spell",
        spellID = spellID,
        action = desc,
        tabName = tabName or PET_TAB_NAME,
        tabIcon = tabIcon or PET_TAB_ICON,
        name = displayName,
        icon = (Action and Action.GetIcon and Action.GetIcon(desc)) or PET_TAB_ICON,
        pet = true,
    }
end

local function ScanPetSpellbookClassic(out, seen)
    local book = BOOKTYPE_PET or "pet"
    if not GetNumSpellTabs then
        -- Flat classic pet book via HasPetSpells index range.
        local n = HasPetSpells and select(1, HasPetSpells())
        n = tonumber(n) or 0
        for i = 1, n do
            local spellType, id
            if GetSpellBookItemInfo then
                spellType, id = GetSpellBookItemInfo(i, book)
            end
            if (spellType == "SPELL" or spellType == "PETACTION" or not spellType) and id then
                AddPetSpell(out, seen, id, PET_TAB_NAME, PET_TAB_ICON)
            elseif GetSpellBookItemName then
                local _, _, sid = GetSpellBookItemName(i, book)
                if sid then
                    AddPetSpell(out, seen, sid, PET_TAB_NAME, PET_TAB_ICON)
                end
            end
        end
        return
    end
    -- Some Classic clients expose pet spells as a separate book without tabs.
    local n = HasPetSpells and select(1, HasPetSpells())
    n = tonumber(n) or 0
    if n <= 0 and GetNumSpellBookItems then
        n = GetNumSpellBookItems(book) or 0
    end
    for i = 1, n do
        local spellType, id
        if GetSpellBookItemInfo then
            spellType, id = GetSpellBookItemInfo(i, book)
        end
        if (spellType == "SPELL" or spellType == "PETACTION" or spellType == "FUTURESPELL" or not spellType) and id then
            AddPetSpell(out, seen, id, PET_TAB_NAME, PET_TAB_ICON)
        elseif GetSpellBookItemName then
            local _, _, sid = GetSpellBookItemName(i, book)
            if sid then
                AddPetSpell(out, seen, sid, PET_TAB_NAME, PET_TAB_ICON)
            end
        end
    end
end

local function ScanPetSpellbookRetail(out, seen)
    if not (C_SpellBook and C_SpellBook.GetSpellBookItemInfo and Enum and Enum.SpellBookSpellBank
        and Enum.SpellBookSpellBank.Pet) then
        return false
    end
    local bank = Enum.SpellBookSpellBank.Pet
    local tabName, tabIcon = PET_TAB_NAME, PET_TAB_ICON
    -- Prefer skill-line metadata when the pet bank exposes lines.
    if C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo then
        -- Pet bank items are indexed in the Pet bank; skill lines may still be player-global.
        -- Flat scan of Pet bank is the reliable source.
    end
    if not C_SpellBook.GetNumSpellBookItems then
        return false
    end
    local n = C_SpellBook.GetNumSpellBookItems(bank) or 0
    if n <= 0 then return true end
    for i = 1, n do
        local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
        if info and info.spellID then
            local itemType = info.itemType
            local ok = true
            if Enum and Enum.SpellBookItemType then
                ok = itemType == Enum.SpellBookItemType.Spell
                    or itemType == Enum.SpellBookItemType.FutureSpell
                    or itemType == Enum.SpellBookItemType.PetAction
            end
            if ok then
                if info.name and info.name ~= "" then
                    tabName = PET_TAB_NAME
                end
                AddPetSpell(out, seen, info.spellID, tabName, tabIcon)
            end
        end
    end
    return true
end

local function ScanLivePetActions(out, seen)
    if not (GetPetActionInfo and NUM_PET_ACTION_SLOTS) then return end
    for i = 1, NUM_PET_ACTION_SLOTS do
        local name, texture, isToken, _, _, _, spellID = GetPetActionInfo(i)
        spellID = tonumber(spellID)
        if spellID and spellID > 0 then
            if isToken and type(name) == "string"
                and (name:find("^PET_ACTION_", 1, true) or name:find("^PET_MODE_", 1, true)) then
                -- Skip Attack / Follow / Stay / stance-mode tokens.
            else
                AddPetSpell(out, seen, spellID, PET_TAB_NAME, texture or PET_TAB_ICON)
            end
        end
    end
end

--- Pet-book + live pet-bar abilities for the Binding catalog (empty when gated off).
--- Remembers the last non-empty scan so abilities stay listable after dismiss.
local cachedPetCatalog = {}
local cachedPetSpellIds = {}

function SpellLibrary.IsPetAbilitySpell(spellID)
    spellID = tonumber(spellID)
    if not spellID then return false end
    if cachedPetSpellIds[spellID] then return true end
    if not IsSpellKnown then return false end
    -- Second argument is the pet bank. A thrown call used to abort binding
    -- apply, which left the bar spell in place and installed no badge.
    local ok, known = pcall(IsSpellKnown, spellID, true)
    if ok and known then
        cachedPetSpellIds[spellID] = true
        return true
    end
    return false
end

function SpellLibrary.RememberPetAbilitySpell(spellID)
    spellID = tonumber(spellID)
    if spellID and spellID > 0 then
        cachedPetSpellIds[spellID] = true
    end
end

--- Seed pet-id memory from saved bindings so mid-combat availability/catalog
--- work before the pet book has been scanned this session.
function SpellLibrary.SeedPetAbilitiesFromBindings()
    local DB = ns.FluxBindingDB3
    if not DB or not DB.All then return end
    for _, b in pairs(DB.All()) do
        if type(b) == "table" and type(b.action) == "table" and b.action.type == "spell" then
            if b.action.pet and b.action.id then
                cachedPetSpellIds[tonumber(b.action.id) or b.action.id] = true
            end
        end
    end
end

function SpellLibrary.GetPetSpellbookSpells()
    local out, seen = {}, {}
    if not SpellLibrary.PlayerCanUsePetAbilities() then
        wipe(cachedPetCatalog)
        -- Keep spell-id memory so existing bindings stay available after gate flicker.
        return out
    end
    if not ScanPetSpellbookRetail(out, seen) then
        ScanPetSpellbookClassic(out, seen)
    end
    ScanLivePetActions(out, seen)
    if #out > 0 then
        wipe(cachedPetCatalog)
        for i = 1, #out do
            local e = out[i]
            cachedPetCatalog[#cachedPetCatalog + 1] = {
                spellID = e.spellID,
                name = e.name,
                icon = e.icon,
            }
            if e.spellID then
                cachedPetSpellIds[e.spellID] = true
            end
        end
    elseif #cachedPetCatalog > 0 then
        for i = 1, #cachedPetCatalog do
            local c = cachedPetCatalog[i]
            AddPetSpell(out, seen, c.spellID, PET_TAB_NAME, c.icon or PET_TAB_ICON)
            if c.spellID then
                cachedPetSpellIds[c.spellID] = true
            end
        end
    end
    table.sort(out, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)
    return out
end

local function RankNumber(spellID)
    spellID = tonumber(spellID)
    if not spellID or not Action then return nil end
    local sub = Action.GetSpellSubtextCompat and Action.GetSpellSubtextCompat(spellID)
    if type(sub) == "string" and sub ~= "" then
        local n = tonumber(sub:match("[Rr]ank%s*(%d+)"))
        if n then return n end
    end
    local desc = Action.Spell and Action.Spell(spellID)
    local name = desc and Action.GetName and Action.GetName(desc)
    if type(name) == "string" then
        local n = tonumber(name:match("[Rr]ank%s*(%d+)"))
        if n then return n end
    end
    return nil
end

local function PickMaxSpellId(ids)
    if type(ids) ~= "table" or #ids == 0 then return nil end
    local bestRanked, bestRank = nil, -1
    local bestId = ids[1]
    for i = 1, #ids do
        local id = ids[i]
        local r = RankNumber(id)
        if r and r > bestRank then
            bestRank = r
            bestRanked = id
        end
        if id > bestId then
            bestId = id
        end
    end
    return bestRanked or bestId
end

local function CollectMustKeepSpellIds(barIndex)
    local keep = {}
    if type(barIndex) == "table" and type(barIndex.spell) == "table" then
        for sid in pairs(barIndex.spell) do
            sid = tonumber(sid)
            if sid then keep[sid] = true end
        end
    end
    if DB and DB.All then
        for _, b in pairs(DB.All()) do
            if b.action and b.action.type == "spell" and b.action.id then
                local sid = tonumber(b.action.id)
                if sid then keep[sid] = true end
            end
        end
    end
    return keep
end

--- Keep max rank per name family; also keep any lower rank on bars or with a Binding row.
function SpellLibrary.PruneSpellRanks(spells, barIndex)
    if type(spells) ~= "table" then return spells or {} end
    local keepForced = CollectMustKeepSpellIds(barIndex)

    local function AppendMissingForced(out, seen, families)
        for sid in pairs(keepForced) do
            if not seen[sid] then
                local tabName, tabIcon = ResolveSpellTab(sid, families)
                -- Prefer sibling tab from the same family when Resolve fell back to General.
                if (not tabName or tabName == "General") and type(families) == "table"
                    and Action and Action.SpellNameKey then
                    local nk = Action.SpellNameKey(sid)
                    local fam = nk and families[nk]
                    if fam then
                        for _, id in ipairs(fam.ids) do
                            local sib = fam.byId[id]
                            if sib and sib.tabName then
                                tabName = sib.tabName
                                tabIcon = sib.tabIcon or tabIcon
                                break
                            end
                        end
                    end
                end
                AddSpell(out, seen, sid, tabName, tabIcon, nil)
            end
        end
    end

    -- No Classic per-rank bars: keep all ranks, still synthesize missing bar/bindings.
    if Action and Action.ShouldOfferRankSync and not Action.ShouldOfferRankSync() then
        local out, seen = {}, {}
        for i = 1, #spells do
            local e = spells[i]
            local sid = tonumber(e.spellID) or (e.action and tonumber(e.action.id))
            if sid then seen[sid] = true end
            out[#out + 1] = e
        end
        AppendMissingForced(out, seen, nil)
        return out
    end

    if #spells == 0 then
        local out, seen = {}, {}
        AppendMissingForced(out, seen, nil)
        return out
    end

    local families = {} -- nameKey -> { ids = {}, byId = {} }
    for i = 1, #spells do
        local e = spells[i]
        local sid = e.spellID or (e.action and e.action.id)
        sid = tonumber(sid)
        if sid and Action and Action.SpellNameKey then
            local nk = Action.SpellNameKey(sid)
            if nk and nk ~= "" then
                local fam = families[nk]
                if not fam then
                    fam = { ids = {}, byId = {} }
                    families[nk] = fam
                end
                if not fam.byId[sid] then
                    fam.ids[#fam.ids + 1] = sid
                    fam.byId[sid] = e
                end
            end
        end
    end

    local out, seen = {}, {}
    for _, fam in pairs(families) do
        local maxId = PickMaxSpellId(fam.ids)
        for i = 1, #fam.ids do
            local id = fam.ids[i]
            local keep = (id == maxId) or keepForced[id] or (#fam.ids == 1)
            if keep and fam.byId[id] and not seen[id] then
                seen[id] = true
                local entry = fam.byId[id]
                -- Refresh display name with rank.
                if Action and Action.GetNameWithRank and entry.action then
                    entry.name = Action.GetNameWithRank(entry.action)
                end
                out[#out + 1] = entry
            end
        end
    end

    -- Bar/binding spells missing from spellbook scan (still must appear).
    AppendMissingForced(out, seen, families)

    table.sort(out, function(a, b)
        local ta, tb = a.tabName or "", b.tabName or ""
        if ta ~= tb then return ta:lower() < tb:lower() end
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)
    return out
end

local function AddItem(out, seen, itemID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 or seen[itemID] then return end
    seen[itemID] = true
    local desc = Action and Action.Item and Action.Item(itemID) or { type = "item", id = itemID }
    out[#out + 1] = {
        kind = "item",
        itemID = itemID,
        action = desc,
        tabName = "Items",
        tabIcon = 133789,
        name = (Action and Action.GetName and Action.GetName(desc)) or ("item:" .. itemID),
        icon = (Action and Action.GetIcon and Action.GetIcon(desc)) or 134400,
    }
end

--- Items from Binding DB rows and action-bar slots (not bag contents).
--- @param barIndex table|nil from IndexBars (optional; live scan if nil)
function SpellLibrary.GetRelevantItems(barIndex)
    local out, seen = {}, {}
    if DB and DB.All then
        for _, b in pairs(DB.All()) do
            if b.action and b.action.type == "item" and b.action.id then
                AddItem(out, seen, b.action.id)
            end
        end
    end
    if type(barIndex) == "table" and type(barIndex.item) == "table" then
        for itemID in pairs(barIndex.item) do
            AddItem(out, seen, itemID)
        end
    else
        for slot = 1, 120 do
            if HasAction and HasAction(slot) then
                local actionType, id = GetActionInfo(slot)
                if actionType == "item" and id then
                    AddItem(out, seen, id)
                end
            end
        end
    end
    table.sort(out, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)
    return out
end

local function AddMacro(out, seen, macroName, icon)
    if type(macroName) ~= "string" or macroName == "" or seen[macroName] then return end
    seen[macroName] = true
    local desc = Action and Action.Macro and Action.Macro(macroName) or { type = "macro", name = macroName }
    out[#out + 1] = {
        kind = "macro",
        action = desc,
        tabName = "Macros",
        tabIcon = 136377,
        name = (Action and Action.GetName and Action.GetName(desc)) or macroName,
        icon = icon or (Action and Action.GetIcon and Action.GetIcon(desc)) or 136377,
    }
end

--- Macros from Binding DB rows and/or action bars.
function SpellLibrary.GetBoundMacros(barIndex)
    local out, seen = {}, {}
    if DB and DB.All then
        for _, b in pairs(DB.All()) do
            if b.action and b.action.type == "macro" and b.action.name then
                AddMacro(out, seen, b.action.name)
            end
        end
    end
    if type(barIndex) == "table" and type(barIndex.macro) == "table" then
        for macroName, info in pairs(barIndex.macro) do
            AddMacro(out, seen, macroName, info and info.icon)
        end
    end
    table.sort(out, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)
    return out
end

local function PushSlot(map, key, slot, extra)
    if key == nil then return end
    local e = map[key]
    if not e then
        e = { slots = {}, icon = extra and extra.icon }
        map[key] = e
    end
    local slots = e.slots
    for i = 1, #slots do
        if slots[i] == slot then return end
    end
    slots[#slots + 1] = slot
    if extra and extra.icon and not e.icon then
        e.icon = extra.icon
    end
end

local function SortSlotLists(index)
    for _, kindMap in pairs(index) do
        if type(kindMap) == "table" then
            for _, info in pairs(kindMap) do
                if type(info) == "table" and type(info.slots) == "table" then
                    table.sort(info.slots)
                end
            end
        end
    end
end

--- Index action-bar contents: spell/item/macro → slot list.
--- @param barsSnap table|nil Respec profile.bars; nil = scan live GetActionInfo(1..120)
--- @return { spell = {[id]= {slots={}, icon?}}, item=..., macro={[name]=...} }
function SpellLibrary.IndexBars(barsSnap)
    local index = { spell = {}, item = {}, macro = {} }

    local function ingest(slot, actionType, id, extra)
        if not actionType or not id then return end
        if actionType == "spell" or actionType == "companion" then
            PushSlot(index.spell, tonumber(id), slot)
        elseif actionType == "item" then
            PushSlot(index.item, tonumber(id), slot)
        elseif actionType == "macro" then
            local name = extra and extra.macroName
            if (not name or name == "") and GetMacroInfo then
                name = GetMacroInfo(id)
            end
            if name and name ~= "" then
                PushSlot(index.macro, name, slot, { icon = extra and extra.macroIcon })
            end
        end
    end

    local Placement = ns.FluxBindingPlacement
    local catalogSlots = Placement and Placement.CatalogBarSlotSet and Placement.CatalogBarSlotSet() or nil

    if type(barsSnap) == "table" and type(barsSnap.slots) == "table" then
        for slot, entry in pairs(barsSnap.slots) do
            slot = tonumber(slot) or slot
            if type(entry) == "table" and (not catalogSlots or catalogSlots[slot]) then
                ingest(slot, entry.type, entry.id, entry)
            end
        end
    else
        if catalogSlots then
            for slot in pairs(catalogSlots) do
                slot = tonumber(slot) or slot
                if slot and HasAction and HasAction(slot) then
                    local actionType, id, subType = GetActionInfo(slot)
                    local extra
                    if actionType == "macro" and id then
                        local name, icon = GetMacroInfo(id)
                        extra = { macroName = name, macroIcon = icon, subType = subType }
                    end
                    ingest(slot, actionType, id, extra)
                end
            end
        else
            for slot = 1, 120 do
                if HasAction and HasAction(slot) then
                    local actionType, id, subType = GetActionInfo(slot)
                    local extra
                    if actionType == "macro" and id then
                        local name, icon = GetMacroInfo(id)
                        extra = { macroName = name, macroIcon = icon, subType = subType }
                    end
                    ingest(slot, actionType, id, extra)
                end
            end
        end
    end

    SortSlotLists(index)
    return index
end

--- Short label for slot list — prefer main/mini + key via Placement module.
function SpellLibrary.FormatBarSlots(slots)
    local Placement = ns.FluxBindingPlacement
    if Placement and Placement.FormatBarSlots then
        return Placement.FormatBarSlots(slots)
    end
    return nil
end

local function SlotsForEntry(entry, barIndex)
    if type(barIndex) ~= "table" or type(entry) ~= "table" or type(entry.action) ~= "table" then
        return nil
    end
    local a = entry.action
    -- Exact id only — do not merge same-name ranks onto one row.
    -- Spells: match raw catalog spellID (IndexBars stores GetActionInfo ids).
    -- Do not use Engraving-remapped action.id alone — that attaches unrelated
    -- bar slots when a placeholder/sibling collapses to another spell.
    if a.type == "spell" then
        local want = tonumber(entry.spellID) or tonumber(a.id)
        if not want then return nil end
        local slots, seen = {}, {}
        local function addFrom(id)
            id = tonumber(id)
            if not id then return end
            local info = barIndex.spell and barIndex.spell[id]
            if not (info and info.slots) then return end
            for i = 1, #info.slots do
                local s = info.slots[i]
                if s and not seen[s] then
                    seen[s] = true
                    slots[#slots + 1] = s
                end
            end
        end
        addFrom(want)
        -- SoD: also attach slots that still store the placeholder/skill-line id
        -- for this learned ability.
        local Eng = ns.FluxBindingEngraving
        local learned = tonumber(a.id)
        if Eng and Eng.ResolveLearnedSpellId and type(barIndex.spell) == "table" then
            for rawId in pairs(barIndex.spell) do
                rawId = tonumber(rawId)
                if rawId and rawId ~= want then
                    local resolved = Eng.ResolveLearnedSpellId(rawId, rawId, nil)
                    if resolved and (resolved == want or (learned and resolved == learned)) then
                        addFrom(rawId)
                    end
                end
            end
        end
        return #slots > 0 and slots or nil
    elseif a.type == "item" and a.id then
        local info = barIndex.item and barIndex.item[tonumber(a.id) or a.id]
        return info and info.slots
    elseif a.type == "macro" and a.name then
        local info = barIndex.macro and barIndex.macro[a.name]
        return info and info.slots
    end
    return nil
end

--- Full catalog for the Binding browser list.
--- @param opts { bars = profile.bars|nil, utilitySlots = profile.utilitySlots|nil }
function SpellLibrary.GetCatalog(opts)
    opts = type(opts) == "table" and opts or {}
    SpellLibrary.SeedPetAbilitiesFromBindings()
    local barIndex = SpellLibrary.IndexBars(opts.bars)
    local Placement = ns.FluxBindingPlacement
    local extraIndex = Placement and Placement.IndexExtra and Placement.IndexExtra({
        utilitySlots = opts.utilitySlots,
    }) or {}
    local stanceIndex = Placement and Placement.IndexStance and Placement.IndexStance() or {}
    local multiCastIndex = Placement and Placement.IndexMultiCast and Placement.IndexMultiCast() or {}

    local spells = SpellLibrary.PruneSpellRanks(SpellLibrary.GetSpellbookSpells(), barIndex)
    local petSpells = SpellLibrary.GetPetSpellbookSpells()
    local items = SpellLibrary.GetRelevantItems(barIndex)
    local macros = SpellLibrary.GetBoundMacros(barIndex)
    local out = {}
    for i = 1, #spells do out[#out + 1] = spells[i] end
    for i = 1, #petSpells do out[#out + 1] = petSpells[i] end
    for i = 1, #items do out[#out + 1] = items[i] end
    for i = 1, #macros do out[#out + 1] = macros[i] end

    -- Also surface items/spells that only exist on EBS buttons (not spellbook / bars).
    local function EnsureEntryForActionKey(ak, seed)
        if not ak then return end
        for i = 1, #out do
            local e = out[i]
            local eak = e.action and ((Action.FamilyKey and Action.FamilyKey(e.action)) or Action.Key(e.action))
            if eak == ak then return end
        end
        if seed then
            out[#out + 1] = seed
        end
    end

    local function SynthesizeFromPlaces(placeMap, defaultTab, defaultIcon)
        for ak, places in pairs(placeMap) do
            local found = false
            for i = 1, #out do
                local e = out[i]
                local eak = e.action and ((Action.FamilyKey and Action.FamilyKey(e.action)) or Action.Key(e.action))
                if eak == ak then found = true break end
            end
            if not found and type(places) == "table" and places[1] then
                local sid = ak:match("^s(%d+)$")
                local iid = ak:match("^i(%d+)$")
                local mname = ak:match("^m:(.+)$")
                local erole = ak:match("^extra:(.+)$")
                local p0 = places[1]
                if erole and Action and Action.Extra then
                    local desc = Action.Extra(erole, p0.name, p0.icon)
                    EnsureEntryForActionKey(ak, {
                        kind = "extra",
                        action = desc,
                        tabName = defaultTab or "Extra buttons",
                        tabIcon = defaultIcon or EXTRA_TAB_ICON,
                        name = p0.name or erole,
                        icon = p0.icon or (Action.GetIcon and Action.GetIcon(desc)) or 133789,
                    })
                elseif sid and Action and Action.Spell then
                    local id = tonumber(sid)
                    local isPet = SpellLibrary.IsPetAbilitySpell and SpellLibrary.IsPetAbilitySpell(id)
                    local desc = (isPet and Action.PetSpell and Action.PetSpell(id))
                        or Action.Spell(id)
                    EnsureEntryForActionKey(ak, {
                        kind = "spell",
                        spellID = id,
                        action = desc,
                        tabName = isPet and PET_TAB_NAME or (defaultTab or "Extra buttons"),
                        tabIcon = isPet and PET_TAB_ICON or (defaultIcon or EXTRA_TAB_ICON),
                        name = p0.name
                            or (Action.GetNameWithRank and Action.GetNameWithRank(desc))
                            or Action.GetName(desc),
                        icon = p0.icon or Action.GetIcon(desc),
                        pet = isPet and true or nil,
                    })
                elseif iid and Action and Action.Item then
                    local desc = Action.Item(tonumber(iid))
                    EnsureEntryForActionKey(ak, {
                        kind = "item",
                        itemID = tonumber(iid),
                        action = desc,
                        tabName = defaultTab or "Extra buttons",
                        tabIcon = defaultIcon or EXTRA_TAB_ICON,
                        name = Action.GetName(desc),
                        icon = Action.GetIcon(desc),
                    })
                elseif mname and Action and Action.Macro then
                    local desc = Action.Macro(mname)
                    EnsureEntryForActionKey(ak, {
                        kind = "macro",
                        action = desc,
                        tabName = defaultTab or "Extra buttons",
                        tabIcon = defaultIcon or EXTRA_TAB_ICON,
                        name = Action.GetName(desc),
                        icon = Action.GetIcon(desc),
                    })
                end
            end
        end
    end

    SynthesizeFromPlaces(extraIndex, "Extra buttons", EXTRA_TAB_ICON)
    SynthesizeFromPlaces(stanceIndex, "Stance bar", STANCE_TAB_ICON)
    -- Multi-cast-only spells stay under General; bag items under Items;
    -- equip-slot extras under Equipment slots (never Items).
    do
        for ak, places in pairs(multiCastIndex) do
            local found = false
            for i = 1, #out do
                local e = out[i]
                local eak = e.action and ((Action.FamilyKey and Action.FamilyKey(e.action)) or Action.Key(e.action))
                if eak == ak then found = true break end
            end
            if not found and type(places) == "table" and places[1] then
                local sid = ak:match("^s(%d+)$")
                local iid = ak:match("^i(%d+)$")
                local slotId = ak:match("^slot:(%d+)$")
                local p0 = places[1]
                if slotId and Action and Action.EquipSlot then
                    local id = tonumber(slotId)
                    local desc = Action.EquipSlot(id)
                    EnsureEntryForActionKey(ak, {
                        kind = "slot",
                        slotID = id,
                        action = desc,
                        tabName = EQUIP_SLOTS_TAB_NAME,
                        tabIcon = EQUIP_SLOTS_TAB_ICON,
                        name = p0.extraName or Action.GetName(desc),
                        icon = p0.extraIcon or Action.GetIcon(desc),
                    })
                elseif sid and Action and Action.Spell then
                    local id = tonumber(sid)
                    local isPet = SpellLibrary.IsPetAbilitySpell and SpellLibrary.IsPetAbilitySpell(id)
                    local desc = (isPet and Action.PetSpell and Action.PetSpell(id)) or Action.Spell(id)
                    local tabName, tabIcon = "General", 134400
                    if isPet then
                        tabName, tabIcon = PET_TAB_NAME, PET_TAB_ICON
                    else
                        tabName, tabIcon = ResolveSpellTab(id, nil)
                    end
                    EnsureEntryForActionKey(ak, {
                        kind = "spell",
                        spellID = id,
                        action = desc,
                        tabName = tabName,
                        tabIcon = tabIcon,
                        name = (Action.GetNameWithRank and Action.GetNameWithRank(desc)) or Action.GetName(desc),
                        icon = Action.GetIcon(desc),
                        pet = isPet and true or nil,
                    })
                elseif iid and Action and Action.Item then
                    local desc = Action.Item(tonumber(iid))
                    EnsureEntryForActionKey(ak, {
                        kind = "item",
                        itemID = tonumber(iid),
                        action = desc,
                        tabName = "Items",
                        tabIcon = 133789,
                        name = Action.GetName(desc),
                        icon = Action.GetIcon(desc),
                    })
                end
            end
        end
    end

    -- Force pet abilities into the Pet tab (never General / skill-line bleed).
    out = SpellLibrary.CoalescePetCatalogEntries(out)

    for i = 1, #out do
        local entry = out[i]
        entry.barSlots = SlotsForEntry(entry, barIndex)
        entry.onActionBar = entry.barSlots and #entry.barSlots > 0 or false
        if Placement and Placement.CollectForEntry then
            entry.places = Placement.CollectForEntry(entry, entry.barSlots, extraIndex, stanceIndex, multiCastIndex)
        else
            entry.places = nil
        end
        entry.onExtra = false
        entry.onStance = false
        entry.onMultiCast = false
        if entry.places then
            for p = 1, #entry.places do
                local src = entry.places[p].source
                if src == "stance" then
                    entry.onStance = true
                elseif src == "multicast" then
                    entry.onMultiCast = true
                elseif src and src ~= "actionbar" then
                    entry.onExtra = true
                end
            end
        end
        entry.hasBarKey = false
        if entry.places then
            for p = 1, #entry.places do
                local pl = entry.places[p]
                if pl.chord and pl.chord ~= "" and not pl.inactiveUntilFlying then
                    entry.hasBarKey = true
                    break
                end
            end
        end
    end

    -- SoD: drop unowned/unengraved runes that are not on a bar and have no
    -- Flux binding in the active binding source.
    out = FilterOrphanSoDRunes(out)

    -- Clicked-style: one catalog row per occupied placement.
    out = SpellLibrary.ExpandByPlace(out)
    out = SpellLibrary.AppendDraftInstances(out)
    out = SpellLibrary.CoalescePetCatalogEntries(out)
    return out, barIndex, extraIndex, stanceIndex, multiCastIndex
end

--- Stamp Pet tab + pet flag; drop General duplicates of the same pet spell id.
function SpellLibrary.CoalescePetCatalogEntries(catalog)
    local out = {}
    local petSeen = {}
    for i = 1, #(catalog or {}) do
        local e = catalog[i]
        if type(e) ~= "table" then
            -- skip
        else
            local sid = tonumber(e.spellID)
                or (e.action and e.action.type == "spell" and tonumber(e.action.id))
            local isPet = e.pet
                or (e.action and e.action.pet)
                or (sid and SpellLibrary.IsPetAbilitySpell and SpellLibrary.IsPetAbilitySpell(sid))
            -- Extra / stance hosts keep their tab; still stamp pet on the action.
            local keepExtra = (e.tabName == "Extra buttons" or e.onExtra)
                and e.tabName ~= PET_TAB_NAME
            local keepStance = (e.tabName == "Stance bar" or e.onStance)
            if isPet then
                e.pet = true
                if sid then
                    SpellLibrary.RememberPetAbilitySpell(sid)
                end
                if e.action and e.action.type == "spell" then
                    e.action.pet = true
                elseif sid and Action and Action.PetSpell then
                    e.action = Action.PetSpell(sid, e.name)
                    e.spellID = sid
                    e.kind = "spell"
                end
                if not keepExtra and not keepStance then
                    e.tabName = PET_TAB_NAME
                    e.tabIcon = PET_TAB_ICON
                end
                if sid and not keepExtra and not keepStance then
                    if petSeen[sid] then
                        -- skip duplicate General/skill-line copy
                    else
                        petSeen[sid] = true
                        out[#out + 1] = e
                    end
                else
                    out[#out + 1] = e
                end
            else
                out[#out + 1] = e
            end
        end
    end
    return out
end

--- Clone catalog entries so each occupied place is its own list row.
function SpellLibrary.ExpandByPlace(catalog)
    local PlacementMod = ns.FluxBindingPlacement
    local out, seenPlace = {}, {}
    for i = 1, #(catalog or {}) do
        local e = catalog[i]
        local places = e.places
        if type(places) == "table" and #places >= 1 then
            for p = 1, #places do
                local place = places[p]
                local pid = place.placeId
                    or (PlacementMod and PlacementMod.PlaceId and PlacementMod.PlaceId(place))
                if not (pid and seenPlace[pid]) then
                    if pid then
                        seenPlace[pid] = true
                        place.placeId = place.placeId or pid
                    end
                    local clone = {}
                    for k, v in pairs(e) do
                        clone[k] = v
                    end
                    clone.place = place
                    clone.places = { place }
                    if place.source == "actionbar" and place.slot then
                        clone.barSlots = { place.slot }
                        clone.onActionBar = true
                        clone.onStance = false
                        clone.onExtra = false
                        clone.onMultiCast = false
                    elseif place.source == "stance" then
                        clone.barSlots = nil
                        clone.onActionBar = false
                        clone.onStance = true
                        clone.onExtra = false
                        clone.onMultiCast = false
                        -- Stance-bound spells live under Stance bar, not the skill line / Runes tab.
                        clone.tabName = "Stance bar"
                        clone.tabIcon = STANCE_TAB_ICON
                        if place.name and place.name ~= "" then
                            clone.name = place.name
                        end
                        if place.spellID then
                            clone.spellID = place.spellID
                            if clone.action and clone.action.type == "spell" then
                                clone.action = Action and Action.Spell and Action.Spell(place.spellID, place.name)
                                    or clone.action
                            end
                        end
                        if place.icon then
                            clone.icon = place.icon
                        end
                    elseif place.source == "multicast" then
                        -- Stay on spellbook/Items/Equipment slots; do not migrate to Extra.
                        clone.barSlots = nil
                        clone.onActionBar = false
                        clone.onStance = false
                        clone.onExtra = false
                        clone.onMultiCast = true
                        if place.extraType == "slot" or (clone.action and clone.action.type == "slot") then
                            clone.tabName = EQUIP_SLOTS_TAB_NAME
                            clone.tabIcon = EQUIP_SLOTS_TAB_ICON
                            clone.kind = "slot"
                            if place.extraName and place.extraName ~= "" then
                                clone.name = place.extraName
                            end
                            if place.extraIcon then
                                clone.icon = place.extraIcon
                            end
                        end
                    else
                        clone.barSlots = nil
                        clone.onActionBar = false
                        clone.onStance = false
                        clone.onExtra = true
                        clone.onMultiCast = false
                        -- Extra-bound spells/items live under Extra buttons, not the skill line.
                        clone.tabName = "Extra buttons"
                        clone.tabIcon = EXTRA_TAB_ICON
                    end
                    clone.hasBarKey = (place.chord and place.chord ~= ""
                        and not place.inactiveUntilFlying) and true or false
                    out[#out + 1] = clone
                end
            end
        else
            out[#out + 1] = e
        end
    end
    return out, seenPlace
end

--- Session drafts from "Add binding" (placeId inst:<uid>) appear as extra list rows.
function SpellLibrary.AppendDraftInstances(catalog)
    local DB = ns.FluxBindingDB3
    local ActionMod = ns.FluxBindingAction
    if not DB or not DB.All or not ActionMod then
        return catalog
    end
    local out = catalog or {}
    local seen = {}
    for i = 1, #out do
        local e = out[i]
        local pid = e.place and e.place.placeId
        if pid then
            seen[pid] = true
        end
    end
    for uid, b in pairs(DB.All()) do
        if type(b) == "table" and b.placeId and tostring(b.placeId):match("^inst:") then
            local pid = b.placeId
            if not seen[pid] and b.action then
                seen[pid] = true
                local place = {
                    source = "extra",
                    placeId = pid,
                    role = "instance",
                    label = "UNBOUND",
                    placeholder = not (b.key and b.key ~= ""),
                }
                local name = ActionMod.GetNameWithRank and ActionMod.GetNameWithRank(b.action)
                    or ActionMod.GetName(b.action)
                local icon = ActionMod.GetIcon and ActionMod.GetIcon(b.action)
                local tabName = "General"
                local tabIcon = 134400
                local isPet = (b.action.pet == true)
                    or (b.action.type == "spell" and b.action.id
                        and SpellLibrary.IsPetAbilitySpell
                        and SpellLibrary.IsPetAbilitySpell(b.action.id))
                if isPet then
                    tabName = PET_TAB_NAME
                    tabIcon = PET_TAB_ICON
                    b.action.pet = true
                elseif b.action.type == "spell" and b.action.id then
                    tabName, tabIcon = ResolveSpellTab(b.action.id, nil)
                end
                -- Prefer matching an existing catalog entry's tab for this action.
                local ak = (ActionMod.FamilyKey and ActionMod.FamilyKey(b.action))
                    or ActionMod.Key(b.action)
                if not isPet then
                    for i = 1, #out do
                        local e = out[i]
                        local eak = e.action and ((ActionMod.FamilyKey and ActionMod.FamilyKey(e.action))
                            or ActionMod.Key(e.action))
                        if eak == ak and e.tabName and e.tabName ~= "General" then
                            tabName = e.tabName
                            tabIcon = e.tabIcon or tabIcon
                            if not name then name = e.name end
                            if not icon then icon = e.icon end
                            break
                        end
                    end
                end
                out[#out + 1] = {
                    kind = b.action.type,
                    action = b.action,
                    tabName = tabName,
                    tabIcon = tabIcon,
                    name = name or "?",
                    icon = icon or 134400,
                    place = place,
                    places = { place },
                    onActionBar = false,
                    onExtra = true,
                    onStance = false,
                    hasBarKey = false,
                    draftInstance = true,
                    pet = isPet and true or nil,
                }
            end
        end
    end
    return out
end

--- Group catalog entries by tabName.
--- Order: General → class spellbook tabs → Pet → SoD Runes → Stance bar →
--- Extra buttons → Items → Macros → Equipment slots.
function SpellLibrary.GroupByTab(catalog)
    local groups, order, index = {}, {}, {}
    for i = 1, #(catalog or {}) do
        local entry = catalog[i]
        local name = entry.tabName or "General"
        if name == "Extra buttons" then
            entry.tabIcon = EXTRA_TAB_ICON
        elseif name == "Stance bar" then
            entry.tabIcon = STANCE_TAB_ICON
        elseif name == EQUIP_SLOTS_TAB_NAME then
            entry.tabIcon = EQUIP_SLOTS_TAB_ICON
        elseif name == PET_TAB_NAME or entry.pet then
            entry.tabName = PET_TAB_NAME
            name = PET_TAB_NAME
            entry.tabIcon = PET_TAB_ICON
        end
        if not index[name] then
            index[name] = true
            order[#order + 1] = name
            groups[name] = {
                name = name,
                icon = (name == "Extra buttons") and EXTRA_TAB_ICON
                    or (name == "Stance bar") and STANCE_TAB_ICON
                    or (name == EQUIP_SLOTS_TAB_NAME) and EQUIP_SLOTS_TAB_ICON
                    or (name == PET_TAB_NAME) and PET_TAB_ICON
                    or (entry.tabIcon or 134400),
                entries = {},
            }
        end
        local g = groups[name]
        g.entries[#g.entries + 1] = entry
        if name == "Extra buttons" then
            g.icon = EXTRA_TAB_ICON
        elseif name == "Stance bar" then
            g.icon = STANCE_TAB_ICON
        elseif name == EQUIP_SLOTS_TAB_NAME then
            g.icon = EQUIP_SLOTS_TAB_ICON
        elseif name == PET_TAB_NAME then
            g.icon = PET_TAB_ICON
        elseif entry.tabIcon then
            g.icon = entry.tabIcon
        end
    end

    -- First-seen index preserves spellbook skill-line order within the class band.
    local seenAt = {}
    for i = 1, #order do
        seenAt[order[i]] = i
    end

    local function isRunesTab(n)
        if n == "Runes" then return true end
        local g = groups[n]
        local icon = g and g.icon
        return icon == PASSIVE_ICON or icon == 134419
    end

    local function tabRank(n)
        if n == "General" then return 10 end
        if n == PET_TAB_NAME then return 25 end
        if isRunesTab(n) then return 30 end
        if n == "Stance bar" then return 40 end
        if n == "Extra buttons" then return 50 end
        if n == "Items" then return 60 end
        if n == "Macros" then return 65 end
        if n == EQUIP_SLOTS_TAB_NAME then return 70 end
        return 20 -- class schools / other spellbook tabs
    end

    table.sort(order, function(a, b)
        local ra, rb = tabRank(a), tabRank(b)
        if ra ~= rb then
            return ra < rb
        end
        -- Keep spellbook discovery order for class skill lines.
        if ra == 20 then
            return (seenAt[a] or 0) < (seenAt[b] or 0)
        end
        return a:lower() < b:lower()
    end)
    return groups, order
end
