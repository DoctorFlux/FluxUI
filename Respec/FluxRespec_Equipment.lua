-- FluxRespec_Equipment.lua
-- Gear capture/apply. Bag-scan driven like ItemRack (works on all clients).

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.Equipment = R.Equipment or {}
local Equipment = R.Equipment
local Compat = R.Compat

local function Inv()
    return R.Inv
end

local function GetCharacterBagIDs()
    local inv = Inv()
    if inv and inv.GetBagIDs then
        return inv.GetBagIDs()
    end
    return { 0, 1, 2, 3, 4 }
end

-- Slots 1..19 only. Secondary shoulder (SoD slot 20) is excluded from Respec gear snapshots/UI.
local SLOT_MIN = 1
local RESPEC_GEAR_SLOT_MAX = 19
local INVSLOT_MAINHAND = 16
local INVSLOT_OFFHAND = 17
local INVSLOT_SHIRT = 4
local INVSLOT_TABARD = 19

local function SlotMax()
    local raw = (Compat.EquipmentSlotMax and Compat.EquipmentSlotMax()) or RESPEC_GEAR_SLOT_MAX
    return math.min(RESPEC_GEAR_SLOT_MAX, raw)
end

function Equipment.GetSlotMax()
    return SlotMax()
end

--- True if `equipLoc` is a two-handed weapon type (main hand uses both hands).
local function IsTwoHandEquipLoc(equipLoc)
    if not equipLoc or equipLoc == "" then return false end
    return equipLoc == "INVTYPE_2HWEAPON"
        or equipLoc == "INVTYPE_STAFF"
        or equipLoc == "INVTYPE_POLEARM"
        or equipLoc == "INVTYPE_FISHINGPOLE"
end

local function GetItemEquipLoc(itemID, itemLink)
    local id = itemID
    if (not id or id == 0) and itemLink and Compat.ParseItemID then
        id = Compat.ParseItemID(itemLink)
    end
    if not id or id == 0 then return nil end
    if _G.GetItemInfo then
        local loc = select(9, _G.GetItemInfo(itemLink or id))
        if type(loc) == "string" and loc ~= "" then
            return loc
        end
    end
    if _G.C_Item and _G.C_Item.GetItemInfoInstant then
        local ok, t = pcall(_G.C_Item.GetItemInfoInstant, id)
        if ok and type(t) == "table" then
            local loc = t.itemEquipLoc or t.equipLoc
            if type(loc) == "string" and loc ~= "" then
                return loc
            end
        end
    end
    return nil
end

--- True when main-hand (slot 16) resolves to a two-hander: profile snapshot first, else live equipped.
function Equipment.IsMainHandTwoHanded(equipmentSnapshot)
    local link, id
    local mh = equipmentSnapshot and equipmentSnapshot[INVSLOT_MAINHAND]
    if mh then
        link = mh.itemLink
        id = mh.itemID
    end
    if not link or link == "" then
        link = GetInventoryItemLink and GetInventoryItemLink("player", INVSLOT_MAINHAND)
    end
    if (not id or id == 0) and link and Compat.ParseItemID then
        id = Compat.ParseItemID(link)
    end
    if not id and not link then return false end
    local loc = GetItemEquipLoc(id, link)
    return IsTwoHandEquipLoc(loc)
end

--- Hide / skip off-hand row when a 2H occupies main hand (paperdoll behavior).
function Equipment.ShouldIgnoreOffHandSlot(equipmentSnapshot)
    return Equipment.IsMainHandTwoHanded(equipmentSnapshot)
end

-- -----------------------------------------------------------------------------
-- Tooltip-scanned item identity (itemKey = itemID|greens)
-- -- Classic/Vanilla hides permanent enchants inside the tooltip, not the itemLink,
-- -- so two copies of the same item with different enchants (e.g. "Cryomancer" vs
-- -- "Eternal Caretaker") share a link. We build a deterministic key from the
-- -- tooltip's green lines to treat those copies as distinct items.
-- -- Set bonus / tier lines are excluded — they change with what else you wear and are
-- -- not part of this item's own enchant identity.
-- -----------------------------------------------------------------------------

local SCAN_TIP_NAME = "FluxRespecScanTip"
local _scanTip
local BANK_CONTAINER = _G.BANK_CONTAINER or -1
local REAGENTBANK_CONTAINER = _G.REAGENTBANK_CONTAINER or -3

local function GetScanTip()
    if _scanTip then return _scanTip end
    _scanTip = _G[SCAN_TIP_NAME] or CreateFrame("GameTooltip", SCAN_TIP_NAME, nil, "GameTooltipTemplate")
    return _scanTip
end

local function IsGreenEnchantColor(r, g, b)
    if not r or not g or not b then return false end
    return g > 0.7 and r < 0.3 and b < 0.3
end

local EXCLUDE_LINE_TEXT = {
    [_G.ITEM_SOULBOUND or "Soulbound"] = true,
    [_G.ITEM_BIND_ON_PICKUP or "Binds when picked up"] = true,
    [_G.ITEM_BIND_ON_EQUIP or "Binds when equipped"] = true,
    [_G.ITEM_BIND_ON_USE or "Binds when used"] = true,
    [_G.ITEM_ACCOUNTBOUND or "Account Bound"] = true,
}

local function LineMatchesRuneFilter(trimmed, runeFilter)
    if not runeFilter then return false end
    for _, needle in ipairs(runeFilter) do
        if needle and needle ~= "" then
            if trimmed == needle then return true end
            -- SoD engraved tooltips render rune name inside "Equip: <rune name>" / header + effect; use literal substring.
            if type(needle) == "string" and #needle >= 3 then
                local escaped = needle:gsub("(%W)", "%%%1")
                if trimmed:find(escaped) then return true end
            end
        end
    end
    return false
end

--- True if `equipLoc` is a weapon that can carry temporary enchants (MH/OH slot types).
local function IsWeaponInventoryTypeFromLoc(equipLoc)
    if not equipLoc or equipLoc == "" then return false end
    return equipLoc == "INVTYPE_WEAPON"
        or equipLoc == "INVTYPE_2HWEAPON"
        or equipLoc == "INVTYPE_STAFF"
        or equipLoc == "INVTYPE_POLEARM"
        or equipLoc == "INVTYPE_WEAPONMAINHAND"
        or equipLoc == "INVTYPE_WEAPONOFFHAND"
        or equipLoc == "INVTYPE_FISHINGPOLE"
        or equipLoc == "INVTYPE_RANGED"
        or equipLoc == "INVTYPE_RANGEDRIGHT"
        or equipLoc == "INVTYPE_THROWN"
end

local function ItemIsWeaponForTempEnchantStrip(itemID, itemLink)
    local loc = GetItemEquipLoc(itemID, itemLink)
    return IsWeaponInventoryTypeFromLoc(loc)
end

local function GetSpellNameLowerForEnchantOrSpellId(id)
    if not id or id == 0 then return nil end
    local name
    if _G.C_Spell and _G.C_Spell.GetSpellInfo then
        local ok, info = pcall(_G.C_Spell.GetSpellInfo, id)
        if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
            name = info.name
        end
    end
    if not name and _G.GetSpellInfo then
        local ok, n = pcall(_G.GetSpellInfo, id)
        if ok and type(n) == "string" and n ~= "" then
            name = n
        end
    end
    if not name then return nil end
    return name:lower():gsub("^%s+", ""):gsub("%s+$", "")
end

--- Spell name needles from the weapon currently enchanted on `inventorySlot` (16 MH / 17 OH), if any.
local function CollectWeaponTempEnchantNeedlesForInventorySlot(inventorySlot)
    local needles = {}
    if inventorySlot ~= INVSLOT_MAINHAND and inventorySlot ~= INVSLOT_OFFHAND then
        return needles
    end
    if not _G.GetWeaponEnchantInfo then return needles end
    local ok, hasMH, _expMH, _chMH, idMH, hasOH, _expOH, _chOH, idOH = pcall(_G.GetWeaponEnchantInfo)
    if not ok then return needles end
    local enchantId
    if inventorySlot == INVSLOT_MAINHAND then
        local has = (type(hasMH) == "boolean" and hasMH) or (type(hasMH) == "number" and hasMH > 0)
        if has and idMH and idMH ~= 0 then enchantId = idMH end
    else
        local has = (type(hasOH) == "boolean" and hasOH) or (type(hasOH) == "number" and hasOH > 0)
        if has and idOH and idOH ~= 0 then enchantId = idOH end
    end
    local sn = GetSpellNameLowerForEnchantOrSpellId(enchantId)
    if sn and sn ~= "" then
        needles[#needles + 1] = sn
    end
    return needles
end

--- Conservative: duration-style text plus weapon-temp cues (oils, poisons, coatings) or generic "remaining".
local function LineLooksLikeTemporaryWeaponEnchantHeuristic(trimmed)
    if not trimmed or trimmed == "" then return false end
    local low = trimmed:lower()
    local hasDur = trimmed:match("%(%d+%s*[Mm]in%)")
        or trimmed:match("%(%d+%s*[Ss]ec%)")
        or trimmed:match("%d+%s*[Mm]in%s+[Rr]emaining")
        or trimmed:match("%d+%s*[Hh][Rr]")
        or trimmed:match("%d+%s*[Mm]in%.")
        or trimmed:match("%(%d+%s*[Hh][Rr]%)")
    if not hasDur and not low:find("remaining", 1, true) then
        return false
    end
    if low:find("oil", 1, true) or low:find("poison", 1, true) or low:find("coating", 1, true)
        or low:find("sharpen", 1, true) or low:find("weightstone", 1, true)
        or low:find("wizard oil", 1, true) or low:find("mana oil", 1, true)
        or low:find("deadly poison", 1, true) or low:find("instant poison", 1, true)
        or low:find("crippling poison", 1, true) or low:find("wound poison", 1, true)
        or low:find("scratching poison", 1, true) then
        return true
    end
    if hasDur and low:find("remaining", 1, true) then
        return true
    end
    -- Buff-style duration in parentheses (oils/poisons often omit product name in the green line).
    if hasDur then
        return true
    end
    return false
end

local function LineMatchesTemporaryWeaponEnchant(line, apiNeedlesLower)
    local trimmed = line and line:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if trimmed == "" then return false end
    local low = trimmed:lower()
    if apiNeedlesLower then
        for _, needle in ipairs(apiNeedlesLower) do
            if needle and needle ~= "" and low:find(needle, 1, true) then
                return true
            end
        end
    end
    return LineLooksLikeTemporaryWeaponEnchantHeuristic(trimmed)
end

--- Remove tooltip green lines that come from **temporary** weapon enchants only (not permanent gem/enchant lines).
--- `inventorySlot` 16/17 enables GetWeaponEnchantInfo-based stripping for the live hand; otherwise heuristic-only for weapons.
local function StripTemporaryWeaponEnchantGreenLines(greenLines, inventorySlot, itemID, itemLink)
    if not greenLines or #greenLines == 0 then return greenLines end
    if not itemID or not ItemIsWeaponForTempEnchantStrip(itemID, itemLink) then
        return greenLines
    end
    local apiNeedles = {}
    if inventorySlot == INVSLOT_MAINHAND or inventorySlot == INVSLOT_OFFHAND then
        apiNeedles = CollectWeaponTempEnchantNeedlesForInventorySlot(inventorySlot)
    end
    local out = {}
    for _, line in ipairs(greenLines) do
        if not LineMatchesTemporaryWeaponEnchant(line, apiNeedles) then
            out[#out + 1] = line
        end
    end
    table.sort(out)
    return out
end

--- Tier / set bonus lines (depend on other equipped pieces); not used for per-item enchant identity.
--- Patterns skew English-friendly; globals help where Blizzard exposes them.
local function LineLooksLikeSetBonusContext(trimmed)
    if not trimmed or trimmed == "" then return false end
    local low = trimmed:lower()
    -- Piece progress e.g. "(2/6)" at start or after a label
    if trimmed:match("^%(%d+/%d+%)") or trimmed:match(":%s*%(%d+/%d+%)") then
        return true
    end
    -- English "Set:" set name / header lines
    if trimmed:match("^Set:") or trimmed:match("^Set%s*:") then
        return true
    end
    -- "(2) Set:" / "(3) Set:" Wrath+ tier bonus lines
    if trimmed:match("^%(%d+%)%s*[Ss]et%s*:") then
        return true
    end
    -- "Set Bonuses (2/4)" style (retail-ish)
    if low:find("set bonus", 1, true) or low:find("set bonuses", 1, true) then
        return true
    end
    return false
end

local function ExtractGreenLines(tip, runeFilter)
    if not tip or not tip.NumLines then return nil end
    local name = tip:GetName()
    local n = tip:NumLines() or 0
    local out = {}
    for i = 2, n do -- skip item name (line 1)
        local fs = _G[name .. "TextLeft" .. i]
        if fs then
            local text = fs:GetText()
            if text and text ~= "" then
                local r, g, b = fs:GetTextColor()
                if IsGreenEnchantColor(r, g, b) then
                    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
                    if trimmed ~= "" and not EXCLUDE_LINE_TEXT[trimmed]
                        and not LineMatchesRuneFilter(trimmed, runeFilter)
                        and not LineLooksLikeSetBonusContext(trimmed) then
                        out[#out + 1] = trimmed
                    end
                end
            end
        end
    end
    if #out == 0 then return out end
    table.sort(out)
    return out
end

--- On SoD, return rune name + description for the equipped slot (both used as filter needles for itemKey).
local function GetRuneFilterForInventorySlot(slotID)
    if not (Compat.IsSoD and Compat.IsSoD()) then return nil end
    if not _G.C_Engraving or not _G.C_Engraving.GetRuneForEquipmentSlot then return nil end
    local ok, r = pcall(_G.C_Engraving.GetRuneForEquipmentSlot, slotID)
    if not ok or type(r) ~= "table" then return nil end
    local out = {}
    if type(r.name) == "string" and r.name ~= "" then out[#out + 1] = r.name end
    if type(r.description) == "string" and r.description ~= "" then out[#out + 1] = r.description end
    if #out == 0 then return nil end
    return out
end

local function GetRuneFilterForBagSlot(bag, slot)
    if not (Compat.IsSoD and Compat.IsSoD()) then return nil end
    if not _G.C_Engraving or not _G.C_Engraving.GetRuneForInventorySlot then return nil end
    local ok, r = pcall(_G.C_Engraving.GetRuneForInventorySlot, bag, slot)
    if not ok or type(r) ~= "table" then return nil end
    local out = {}
    if type(r.name) == "string" and r.name ~= "" then out[#out + 1] = r.name end
    if type(r.description) == "string" and r.description ~= "" then out[#out + 1] = r.description end
    if #out == 0 then return nil end
    return out
end

local function BuildItemKey(itemID, greenLines)
    if not itemID then return nil end
    if not greenLines or #greenLines == 0 then
        return tostring(itemID) .. "|no_enchant"
    end
    return tostring(itemID) .. "|" .. table.concat(greenLines, "||")
end

-- ItemRack-style: SoD rune identity comes from C_Engraving, not tooltip text. Appended to itemKey so
-- bag scans match even when rune tooltip lines differ; stripped before enchant-line compare.
local function StripRuneSkillSuffixFromKey(itemKey)
    if not itemKey or type(itemKey) ~= "string" then return itemKey end
    return (itemKey:gsub("@@rune@@%d+$", ""))
end

local function AppendRuneSkillSuffix(bag, slot, equipSlotID)
    if not (Compat.IsSoD and Compat.IsSoD()) or not _G.C_Engraving then
        return ""
    end
    local ok, info
    if bag and slot then
        ok, info = pcall(_G.C_Engraving.GetRuneForInventorySlot, bag, slot)
    elseif equipSlotID then
        ok, info = pcall(_G.C_Engraving.GetRuneForEquipmentSlot, equipSlotID)
    else
        return ""
    end
    local sk = (ok and info and info.skillLineAbilityID) and tonumber(info.skillLineAbilityID) or 0
    return "@@rune@@" .. tostring(sk)
end

local function ParseItemIDFromKey(itemKey)
    if type(itemKey) ~= "string" then return nil end
    local cleaned = StripRuneSkillSuffixFromKey(itemKey)
    local id = cleaned:match("^(%d+)|")
    return id and tonumber(id) or nil
end

-- Identity keys cost a tooltip scan, and every item move bumps the bag
-- generation. Keys are cached per slot and reused while what the key is built
-- from (link, live temp enchant, rune) is unchanged.
local itemKeyBagCache = {}
local itemKeyInvCache = {}

local function CurrentBagsGeneration()
    local inv = Inv()
    if inv and inv.GetGeneration then
        return inv.GetGeneration()
    end
    return GetTime()
end

function Equipment.InvalidateItemKeyCache()
    wipe(itemKeyBagCache)
    wipe(itemKeyInvCache)
end

local function InventoryKeyStamp(slotID, link)
    local stamp = link
    if (slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND) and _G.GetWeaponEnchantInfo then
        local ok, _, _, _, idMH, _, _, _, idOH = pcall(_G.GetWeaponEnchantInfo)
        if ok then
            stamp = stamp .. "#" .. tostring(slotID == INVSLOT_MAINHAND and idMH or idOH)
        end
    end
    return stamp .. AppendRuneSkillSuffix(nil, nil, slotID)
end

--- Scan equipped item in `slotID` and return an identity key, or nil if the tooltip could not be populated.
function Equipment.GetItemKeyForInventorySlot(slotID)
    local link = GetInventoryItemLink("player", slotID)
    if not link then return nil end
    local itemID = Compat.ParseItemID(link)
    if not itemID then return nil end
    local stamp = InventoryKeyStamp(slotID, link)
    local hit = itemKeyInvCache[slotID]
    if hit and hit.stamp == stamp then
        return hit.key
    end
    local tip = GetScanTip()
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    local ok = pcall(tip.SetInventoryItem, tip, "player", slotID)
    if not ok then return nil end
    -- SoD: strip rune-name / rune-description green lines so itemKey stays stable across rune swaps.
    local runeFilter = GetRuneFilterForInventorySlot(slotID)
    local greens = ExtractGreenLines(tip, runeFilter)
    if not greens then return nil end
    greens = StripTemporaryWeaponEnchantGreenLines(greens, slotID, itemID, link)
    local key = BuildItemKey(itemID, greens) .. AppendRuneSkillSuffix(nil, nil, slotID)
    itemKeyInvCache[slotID] = { stamp = stamp, key = key }
    return key
end

--- Populate the scan tooltip for any container slot, including main bank / reagent bank grids.
local function PopulateScanTipForContainerSlot(tip, bag, slot)
    if not tip then return false end
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    if bag == BANK_CONTAINER and _G.BankButtonIDToInvSlotID then
        local invSlot = _G.BankButtonIDToInvSlotID(slot)
        if not invSlot then return false end
        return pcall(tip.SetInventoryItem, tip, "player", invSlot)
    end
    if bag == REAGENTBANK_CONTAINER and _G.ReagentBankButtonIDToInvSlotID then
        local invSlot = _G.ReagentBankButtonIDToInvSlotID(slot)
        if not invSlot then return false end
        return pcall(tip.SetInventoryItem, tip, "player", invSlot)
    end
    return pcall(tip.SetBagItem, tip, bag, slot)
end

local function ScanBagSlotItemKey(bag, slot)
    local itemID = (Inv() and Inv().GetItemID and Inv().GetItemID(bag, slot)) or Compat.GetContainerItemID(bag, slot)
    if not itemID then
        return nil
    end
    local tip = GetScanTip()
    local ok = PopulateScanTipForContainerSlot(tip, bag, slot)
    if not ok then
        return nil
    end
    local runeFilter = GetRuneFilterForBagSlot(bag, slot)
    local greens = ExtractGreenLines(tip, runeFilter)
    if not greens then
        return nil
    end
    local link = (Inv() and Inv().GetItemLink and Inv().GetItemLink(bag, slot)) or Compat.GetContainerItemLink(bag, slot)
    greens = StripTemporaryWeaponEnchantGreenLines(greens, nil, itemID, link)
    return BuildItemKey(itemID, greens)
end

--- Scan bag item `(bag, slot)` and return an identity key, or nil if the tooltip could not be populated.
function Equipment.GetItemKeyForBagSlot(bag, slot)
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot then
        return nil
    end
    local gen = CurrentBagsGeneration()
    local ck = ("%d:%d"):format(bag, slot)
    -- Live link, not the snapshot: a closed bank must not validate last visit's keys.
    local link = Compat.GetContainerItemLink(bag, slot)
    local hit = itemKeyBagCache[ck]
    -- Failed scans retry once the bags change.
    if hit and hit.link == link and (hit.key or hit.gen == gen) then
        return hit.key or nil
    end
    local key = ScanBagSlotItemKey(bag, slot)
    itemKeyBagCache[ck] = { link = link, key = key or false, gen = gen }
    return key
end

-- -----------------------------------------------------------------------------
-- Capture
-- -----------------------------------------------------------------------------

--- Snapshot the current equipment as a table indexed by inventory slotID.
--- Each entry is { itemID = number, itemLink = string, itemKey = string? } or { empty = true }.
function Equipment.Capture()
    local out = {}
    for slotID = SLOT_MIN, SlotMax() do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local itemID = Compat.ParseItemID(link)
            if itemID then
                out[slotID] = {
                    itemID = itemID,
                    itemLink = link,
                    itemKey = Equipment.GetItemKeyForInventorySlot(slotID),
                }
            end
        end
    end
    local skipOH = Equipment.ShouldIgnoreOffHandSlot(out)
    for slotID = SLOT_MIN, SlotMax() do
        if not out[slotID] then
            if slotID ~= INVSLOT_SHIRT and slotID ~= INVSLOT_TABARD
                and not (skipOH and slotID == INVSLOT_OFFHAND) then
                out[slotID] = { empty = true }
            end
        end
    end
    return out
end

--- Snapshot a single paperdoll slot (same entry shape as Capture). Empty slots are `{ empty = true }`.
function Equipment.CaptureSlot(slotID)
    if not slotID then
        return nil
    end
    local link = GetInventoryItemLink("player", slotID)
    if link then
        local itemID = Compat.ParseItemID(link)
        if itemID then
            return {
                itemID = itemID,
                itemLink = link,
                itemKey = Equipment.GetItemKeyForInventorySlot(slotID),
            }
        end
    end
    return { empty = true }
end

--- Sparse snapshot for the given slot set (`{ [slotID] = true }`).
function Equipment.CaptureSlots(slotSet)
    local out = {}
    if type(slotSet) ~= "table" then
        return out
    end
    for slotID, included in pairs(slotSet) do
        if included then
            local sid = tonumber(slotID) or slotID
            out[sid] = Equipment.CaptureSlot(sid)
        end
    end
    return out
end

--- True when a saved equipment entry means the paperdoll slot should be empty.
function Equipment.IsWantEmpty(want)
    return type(want) == "table" and want.empty == true
end

--- True when the player has nothing equipped in `slotID`.
function Equipment.IsInventorySlotEmpty(slotID)
    return not GetInventoryItemLink("player", slotID)
end

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

--- Saved profiles may store itemID as string; APIs return numbers — normalize before compare.
local function ItemIDsEqual(a, b)
    if a == nil or b == nil then return false end
    return tonumber(a) == tonumber(b)
end

local function GetEquippedItemID(slotID)
    local link = GetInventoryItemLink("player", slotID)
    if not link then return nil end
    local id = Compat.ParseItemID(link)
    return id and tonumber(id) or id
end

--- Green-line segments from an `itemKey` string (`id|line1||line2` or `id|no_enchant`, optional `@@rune@@id`).
local function EnchantLinesFromItemKey(itemKey)
    if not itemKey or type(itemKey) ~= "string" then return {} end
    itemKey = StripRuneSkillSuffixFromKey(itemKey)
    local _, rest = itemKey:match("^(%d+)|(.+)$")
    if not rest or rest == "no_enchant" then return {} end
    local lines = {}
    local pos = 1
    local len = #rest
    while pos <= len do
        local j = rest:find("||", pos, true)
        if not j then
            local chunk = rest:sub(pos):match("^%s*(.-)%s*$")
            if chunk and chunk ~= "" then lines[#lines + 1] = chunk end
            break
        end
        local chunk = rest:sub(pos, j - 1):match("^%s*(.-)%s*$")
        if chunk and chunk ~= "" then lines[#lines + 1] = chunk end
        pos = j + 2
    end
    return lines
end

--- True if two itemKeys refer to the same enchant/gem identity; rune-only differences are ignored
--- using C_Engraving needles (bag + inventory + saved profile rune name during Apply).
local function ItemKeysEnchantMatch(wantKey, liveKey, equipSlotID, bag, bagSlot)
    if not wantKey or not liveKey or type(wantKey) ~= "string" or type(liveKey) ~= "string" then
        return false
    end
    if wantKey == liveKey then return true end
    local wantCore = StripRuneSkillSuffixFromKey(wantKey)
    local liveCore = StripRuneSkillSuffixFromKey(liveKey)
    if wantCore == liveCore then return true end
    if not ItemIDsEqual(ParseItemIDFromKey(wantKey), ParseItemIDFromKey(liveKey)) then
        return false
    end
    local needles = {}
    if Compat.IsSoD and Compat.IsSoD() then
        if bag and bagSlot then
            local f = GetRuneFilterForBagSlot(bag, bagSlot)
            if f then for _, n in ipairs(f) do needles[#needles + 1] = n end end
        elseif equipSlotID then
            local f = GetRuneFilterForInventorySlot(equipSlotID)
            if f then for _, n in ipairs(f) do needles[#needles + 1] = n end end
        end
        local rs = Equipment._applyRuneSnapshot
        if equipSlotID and rs and rs[equipSlotID] and type(rs[equipSlotID].name) == "string" and rs[equipSlotID].name ~= "" then
            needles[#needles + 1] = rs[equipSlotID].name
        end
    end
    local function strip(lines)
        local out = {}
        for _, line in ipairs(lines) do
            if not LineMatchesRuneFilter(line, needles) then
                out[#out + 1] = line
            end
        end
        table.sort(out)
        return out
    end
    local baseItemID = ParseItemIDFromKey(wantKey)
    local function applyWeaponTempStrip(lines)
        if equipSlotID == INVSLOT_MAINHAND or equipSlotID == INVSLOT_OFFHAND then
            return StripTemporaryWeaponEnchantGreenLines(lines, equipSlotID, baseItemID)
        end
        return lines
    end
    local sw = strip(applyWeaponTempStrip(EnchantLinesFromItemKey(wantCore)))
    local sl = strip(applyWeaponTempStrip(EnchantLinesFromItemKey(liveCore)))
    if #sw ~= #sl then return false end
    for i = 1, #sw do
        if sw[i] ~= sl[i] then return false end
    end
    return true
end

--- Strip color codes so two links to the same item instance compare equal.
local function ItemLinksMatch(a, b)
    if not a or not b then return false end
    if a == b then return true end
    local function strip(s)
        return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
    return strip(a) == strip(b)
end

local function WantHasSpecificLink(want)
    return want and want.itemLink and want.itemLink ~= ""
end

local function WantHasItemKey(want)
    return want and type(want.itemKey) == "string" and want.itemKey ~= ""
end

function Equipment.WantHasSpecificLink(want)
    return WantHasSpecificLink(want)
end

function Equipment.WantHasItemKey(want)
    return WantHasItemKey(want)
end

--- True when two saved wants refer to the same gear identity (enchant/link/itemID rules).
function Equipment.WantsSameIdentity(wantA, wantB)
    if not wantA or not wantB or not wantA.itemID or not wantB.itemID then
        return false
    end
    if not ItemIDsEqual(wantA.itemID, wantB.itemID) then
        return false
    end
    if WantHasItemKey(wantA) or WantHasItemKey(wantB) then
        if not WantHasItemKey(wantA) or not WantHasItemKey(wantB) then
            return false
        end
        if wantA.itemKey == wantB.itemKey then
            return true
        end
        return ItemKeysEnchantMatch(wantA.itemKey, wantB.itemKey, nil, nil, nil)
    end
    if WantHasSpecificLink(wantA) or WantHasSpecificLink(wantB) then
        if not WantHasSpecificLink(wantA) or not WantHasSpecificLink(wantB) then
            return false
        end
        return ItemLinksMatch(wantA.itemLink, wantB.itemLink)
    end
    return true
end

function Equipment.WantsMatchSavedWant(wantA, wantB, invSlotID)
    return Equipment.WantsSameIdentity(wantA, wantB)
end

--- Build itemKey from a stored hyperlink (legacy snapshots with itemLink only). `inventorySlotID` drives SoD rune strip + temp weapon strip.
local function GetItemKeyFromItemLink(itemLink, inventorySlotID)
    if not itemLink or itemLink == "" or not inventorySlotID then return nil end
    local itemID = Compat.ParseItemID(itemLink)
    if not itemID then return nil end
    local tip = GetScanTip()
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    local ok = pcall(function()
        tip:SetHyperlink(itemLink)
    end)
    if not ok then return nil end
    local runeFilter = GetRuneFilterForInventorySlot(inventorySlotID)
    local greens = ExtractGreenLines(tip, runeFilter)
    if not greens then return nil end
    greens = StripTemporaryWeaponEnchantGreenLines(greens, inventorySlotID, itemID, itemLink)
    return BuildItemKey(itemID, greens) .. AppendRuneSkillSuffix(nil, nil, inventorySlotID)
end

--- True if the paperdoll slot matches the snapshot.
-- With `itemKey`: enchant/gem lines must match after stripping rune tooltip lines (SoD: bag + profile
-- needles). Different runes on the same enchanted item still count as a match.
-- Legacy snapshots (itemID only): same base item counts as a match.
local function SlotMatchesWant(slotID, want)
    local elink = GetInventoryItemLink("player", slotID)
    if not elink or not want or not want.itemID then return false end
    if not ItemIDsEqual(GetEquippedItemID(slotID), want.itemID) then
        return false
    end
    if WantHasItemKey(want) then
        local key = Equipment.GetItemKeyForInventorySlot(slotID)
        if not key then return false end
        if key == want.itemKey then return true end
        return ItemKeysEnchantMatch(want.itemKey, key, slotID, nil, nil)
    end
    if WantHasSpecificLink(want) then
        if ItemLinksMatch(elink, want.itemLink) then
            return true
        end
        -- Same base item but hyperlink differs (e.g. temporary weapon enchant in link suffix): compare normalized itemKeys.
        if slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND then
            if ItemIDsEqual(GetEquippedItemID(slotID), want.itemID) then
                local liveKey = Equipment.GetItemKeyForInventorySlot(slotID)
                local wantKeyFromLink = GetItemKeyFromItemLink(want.itemLink, slotID)
                if liveKey and wantKeyFromLink then
                    if liveKey == wantKeyFromLink then return true end
                    return ItemKeysEnchantMatch(wantKeyFromLink, liveKey, slotID, nil, nil)
                end
            end
        end
        return false
    end
    return true
end

-- Rings (11–12) and trinkets (13–14): the wanted item may be on the paired paperdoll slot
-- (different profiles can save the same ring on finger 1 vs finger 2).
local INVSLOT_FINGER1 = 11
local INVSLOT_FINGER2 = 12
local INVSLOT_TRINKET1 = 13
local INVSLOT_TRINKET2 = 14

local function JewelryPeerSlot(slotID)
    if slotID == INVSLOT_FINGER1 then return INVSLOT_FINGER2 end
    if slotID == INVSLOT_FINGER2 then return INVSLOT_FINGER1 end
    if slotID == INVSLOT_TRINKET1 then return INVSLOT_TRINKET2 end
    if slotID == INVSLOT_TRINKET2 then return INVSLOT_TRINKET1 end
    return nil
end

Equipment.GetJewelryPeerSlot = JewelryPeerSlot

--- True if `want` is already satisfied on `slotID` or (for rings/trinkets only) on the paired slot.
--- Two slots that save the *same* ring/trinket each need their own copy — one equipped item
--- cannot satisfy both fingers/trinkets.
local function SlotWantSatisfiedIncludingJewelryPeer(slotID, want, snap)
    if not want or not want.itemID or type(snap) ~= "table" then
        return false
    end
    if SlotMatchesWant(slotID, want) then
        return true
    end
    local peer = JewelryPeerSlot(slotID)
    if not peer or not SlotMatchesWant(peer, want) then
        return false
    end
    if Equipment.WantsSameIdentity(want, snap[peer]) then
        return false
    end
    return true
end

--- Steal from the paired jewelry slot only when this is a reorder (peer wants a different item).
local function CanStealJewelryPeer(snapshot, slotID, want)
    local peer = JewelryPeerSlot(slotID)
    if not peer or not want or not SlotMatchesWant(peer, want) then
        return false
    end
    local peerWant = type(snapshot) == "table" and snapshot[peer] or nil
    if Equipment.WantsSameIdentity(want, peerWant) then
        return false
    end
    return true
end

--- True if `want` matches what is in that paperdoll slot (used by overlays / cross-slot checks).
function Equipment.PaperdollSlotMatchesWant(slotID, want)
    return SlotMatchesWant(slotID, want)
end

local function GetBagItemEngravingSkillLine(bag, slot)
    if not _G.C_Engraving or not _G.C_Engraving.GetRuneForInventorySlot then return nil end
    local ok, info = pcall(_G.C_Engraving.GetRuneForInventorySlot, bag, slot)
    if ok and info and info.skillLineAbilityID then
        return info.skillLineAbilityID
    end
    return nil
end

local function LocKey(bag, slot)
    if bag == nil or slot == nil then
        return nil
    end
    return tostring(bag) .. ":" .. tostring(slot)
end

local function IsLocUsed(used, bag, slot)
    local k = LocKey(bag, slot)
    return k and used and used[k] == true
end

local function MarkLocUsed(used, bag, slot)
    local k = LocKey(bag, slot)
    if used and k then
        used[k] = true
    end
end

local function PickRuneCandidate(candidates, wantSkillLine, used)
    if type(candidates) ~= "table" or #candidates == 0 then
        return nil
    end
    local list = candidates
    if used then
        list = {}
        for i = 1, #candidates do
            local bag, slot = candidates[i][1], candidates[i][2]
            if not IsLocUsed(used, bag, slot) then
                list[#list + 1] = candidates[i]
            end
        end
    end
    if #list == 0 then return nil end
    if #list == 1 then return list[1][1], list[1][2] end
    if not wantSkillLine or not Compat.IsSoD or not Compat.IsSoD() then
        return list[1][1], list[1][2]
    end
    for _, c in ipairs(list) do
        local bag, slot = c[1], c[2]
        if GetBagItemEngravingSkillLine(bag, slot) == wantSkillLine then
            return bag, slot
        end
    end
    return list[1][1], list[1][2]
end

--- Scan bags for an item with the given itemID (first unused match). Legacy snapshots without itemLink.
local function FindItemInBagsByItemID(itemID, used)
    if not itemID then return nil end
    local inv = Inv()
    local locs = inv and inv.Find and inv.Find(itemID, "bags") or {}
    for i = 1, #locs do
        local loc = locs[i]
        if loc and not IsLocUsed(used, loc.bag, loc.slot) then
            return loc.bag, loc.slot
        end
    end
    return nil
end

--- Prefer a bag stack whose engraving matches `wantSkillLine` when multiple copies share itemID (SoD).
local function FindItemInBagsByItemIDPreferringRune(itemID, wantSkillLine, used)
    if not itemID then return nil end
    local inv = Inv()
    local locs = inv and inv.Find and inv.Find(itemID, "bags") or {}
    local candidates = {}
    for i = 1, #locs do
        candidates[#candidates + 1] = { locs[i].bag, locs[i].slot }
    end
    return PickRuneCandidate(candidates, wantSkillLine, used)
end

--- Scan bags for a bag slot whose link matches (enchants, gems, runes differ per link).
local function FindItemInBagsByLink(targetLink, used)
    if not targetLink then return nil end
    local inv = Inv()
    local itemID = Compat.ParseItemID and Compat.ParseItemID(targetLink)
    if itemID then
        local locs = inv and inv.Find and inv.Find(itemID, "bags") or {}
        for i = 1, #locs do
            local loc = locs[i]
            if loc and not IsLocUsed(used, loc.bag, loc.slot) then
                local link = loc.link or (inv and inv.GetItemLink and inv.GetItemLink(loc.bag, loc.slot))
                if ItemLinksMatch(link, targetLink) then
                    return loc.bag, loc.slot
                end
            end
        end
        return nil
    end
    if inv and inv.ForEachLocation then
        local foundBag, foundSlot
        inv.ForEachLocation(function(loc)
            if foundBag then return end
            if loc and not IsLocUsed(used, loc.bag, loc.slot) and ItemLinksMatch(loc.link, targetLink) then
                foundBag, foundSlot = loc.bag, loc.slot
            end
        end, "bags")
        return foundBag, foundSlot
    end
    return nil
end

--- All bag slot positions carrying `itemID` (for duplicate / fallback logic).
local function CollectBagSlotsWithItemID(itemID)
    local out = {}
    if not itemID then return out end
    local inv = Inv()
    local locs = inv and inv.Find and inv.Find(itemID, "bags") or {}
    for i = 1, #locs do
        out[#out + 1] = { locs[i].bag, locs[i].slot }
    end
    return out
end

--- Bag stacks matching `targetKey` (exact or same enchant after stripping rune lines). SoD: rune tiebreaker.
--- With multiple same-itemID copies differing only by enchants, only stacks whose enchant signature
--- matches the profile (after rune strip) are considered — not arbitrary same-ID picks.
local function FindItemInBagsByItemKey(targetKey, wantSkillLine, itemIDFallback, equipSlotID, used)
    if not targetKey then
        return FindItemInBagsByItemIDPreferringRune(itemIDFallback, wantSkillLine, used)
    end
    local wantItemID = ParseItemIDFromKey(targetKey) or (itemIDFallback and tonumber(itemIDFallback) or nil)
    if not wantItemID then return nil end
    local exact, fuzzy = {}, {}
    local inv = Inv()
    local locs = inv and inv.Find and inv.Find(wantItemID, "bags") or {}
    for i = 1, #locs do
        local bag, slot = locs[i].bag, locs[i].slot
        if not IsLocUsed(used, bag, slot) then
            local k = Equipment.GetItemKeyForBagSlot(bag, slot)
            if k then
                if k == targetKey then
                    exact[#exact + 1] = { bag, slot }
                elseif ItemKeysEnchantMatch(targetKey, k, equipSlotID, bag, slot) then
                    fuzzy[#fuzzy + 1] = { bag, slot }
                end
            end
        end
    end
    local candidates = (#exact > 0) and exact or fuzzy
    if #candidates > 0 then
        return PickRuneCandidate(candidates, wantSkillLine, used)
    end
    local stacks = CollectBagSlotsWithItemID(wantItemID)
    local unused = {}
    for i = 1, #stacks do
        if not IsLocUsed(used, stacks[i][1], stacks[i][2]) then
            unused[#unused + 1] = stacks[i]
        end
    end
    if #unused == 1 then
        local bag, slot = unused[1][1], unused[1][2]
        local k = Equipment.GetItemKeyForBagSlot(bag, slot)
        if not k then
            return bag, slot
        end
        if k == targetKey or ItemKeysEnchantMatch(targetKey, k, equipSlotID, bag, slot) then
            return bag, slot
        end
        return nil
    end
    return nil
end

--- First unused bag stack matching `want`. Marks the location in `used` so two identical
--- rings/trinkets each consume their own copy.
local function FindBagCopyForWant(want, slotID, used)
    if not want or not want.itemID then
        return nil
    end
    local runeSnap = Equipment._applyRuneSnapshot
    local wantRune = runeSnap and runeSnap[slotID] and runeSnap[slotID].skillLineAbilityID
    local bag, bagSlot
    if WantHasItemKey(want) then
        bag, bagSlot = FindItemInBagsByItemKey(want.itemKey, wantRune, want.itemID, slotID, used)
    elseif WantHasSpecificLink(want) then
        bag, bagSlot = FindItemInBagsByLink(want.itemLink, used)
    else
        bag, bagSlot = FindItemInBagsByItemIDPreferringRune(want.itemID, wantRune, used)
    end
    if bag then
        MarkLocUsed(used, bag, bagSlot)
        return bag, bagSlot
    end
    return nil
end

-- -----------------------------------------------------------------------------
-- Bank containers (when bank is open via Flux.Inventory — no auto-open)
-- -----------------------------------------------------------------------------

local function IsBankFrameOpen()
    local inv = Inv()
    if inv and inv.IsBankOpen then
        return inv.IsBankOpen()
    end
    return _G.BankFrame and _G.BankFrame:IsShown()
end

local function CanTakeFromBank()
    local inv = Inv()
    if inv and inv.CanTakeFromBank then
        return inv.CanTakeFromBank()
    end
    if inv and inv.IsBankLive then
        return inv.IsBankLive()
    end
    return IsBankFrameOpen()
end

local function FindItemInBankByItemID(itemID, which, used)
    if not itemID then return nil end
    local inv = Inv()
    local locs = inv and inv.Find and inv.Find(itemID, which or "bank") or {}
    for i = 1, #locs do
        local loc = locs[i]
        if loc and not IsLocUsed(used, loc.bag, loc.slot) then
            return loc.bag, loc.slot
        end
    end
    return nil
end

local function FindItemInBankByLink(targetLink, which, used)
    if not targetLink then return nil end
    which = which or "bank"
    local inv = Inv()
    local itemID = Compat.ParseItemID and Compat.ParseItemID(targetLink)
    if itemID then
        local locs = inv and inv.Find and inv.Find(itemID, which) or {}
        for i = 1, #locs do
            local loc = locs[i]
            if loc and not IsLocUsed(used, loc.bag, loc.slot) then
                local link = loc.link or (inv and inv.GetItemLink and inv.GetItemLink(loc.bag, loc.slot))
                if ItemLinksMatch(link, targetLink) then
                    return loc.bag, loc.slot
                end
            end
        end
        return nil
    end
    if inv and inv.ForEachLocation then
        local foundBag, foundSlot
        inv.ForEachLocation(function(loc)
            if foundBag then return end
            if loc and not IsLocUsed(used, loc.bag, loc.slot) and ItemLinksMatch(loc.link, targetLink) then
                foundBag, foundSlot = loc.bag, loc.slot
            end
        end, which)
        return foundBag, foundSlot
    end
    return nil
end

local function CollectBankSlotsWithItemID(itemID, which)
    local out = {}
    if not itemID then return out end
    local inv = Inv()
    local locs = inv and inv.Find and inv.Find(itemID, which or "bank") or {}
    for i = 1, #locs do
        out[#out + 1] = { locs[i].bag, locs[i].slot }
    end
    return out
end

local function FindItemInBankByItemIDPreferringRune(itemID, wantSkillLine, which, used)
    if not itemID then return nil end
    local inv = Inv()
    local locs = inv and inv.Find and inv.Find(itemID, which or "bank") or {}
    local candidates = {}
    for i = 1, #locs do
        candidates[#candidates + 1] = { locs[i].bag, locs[i].slot }
    end
    return PickRuneCandidate(candidates, wantSkillLine, used)
end

local function FindItemInBankByItemKey(targetKey, wantSkillLine, itemIDFallback, equipSlotID, which, used)
    which = which or "bank"
    if not targetKey then
        return FindItemInBankByItemIDPreferringRune(itemIDFallback, wantSkillLine, which, used)
    end
    local wantItemID = ParseItemIDFromKey(targetKey) or (itemIDFallback and tonumber(itemIDFallback) or nil)
    if not wantItemID then return nil end
    local exact, fuzzy = {}, {}
    local inv = Inv()
    local locs = inv and inv.Find and inv.Find(wantItemID, which) or {}
    for i = 1, #locs do
        local bag, slot = locs[i].bag, locs[i].slot
        if not IsLocUsed(used, bag, slot) then
            local k = Equipment.GetItemKeyForBagSlot(bag, slot)
            if k then
                if k == targetKey then
                    exact[#exact + 1] = { bag, slot }
                elseif ItemKeysEnchantMatch(targetKey, k, equipSlotID, bag, slot) then
                    fuzzy[#fuzzy + 1] = { bag, slot }
                end
            end
        end
    end
    local candidates = (#exact > 0) and exact or fuzzy
    if #candidates > 0 then
        return PickRuneCandidate(candidates, wantSkillLine, used)
    end
    local stacks = CollectBankSlotsWithItemID(wantItemID, which)
    local unused = {}
    for i = 1, #stacks do
        if not IsLocUsed(used, stacks[i][1], stacks[i][2]) then
            unused[#unused + 1] = stacks[i]
        end
    end
    if #unused == 1 then
        local bag, slot = unused[1][1], unused[1][2]
        local k = Equipment.GetItemKeyForBagSlot(bag, slot)
        if not k then
            return bag, slot
        end
        if k == targetKey or ItemKeysEnchantMatch(targetKey, k, equipSlotID, bag, slot) then
            return bag, slot
        end
        return nil
    end
    return nil
end

local function FindBankCopyForWant(want, slotID, used, which)
    if not want or not want.itemID then
        return nil
    end
    which = which or "bank"
    local runeSnap = Equipment._applyRuneSnapshot
    local wantRune = runeSnap and runeSnap[slotID] and runeSnap[slotID].skillLineAbilityID
    local bag, bagSlot
    if WantHasItemKey(want) then
        bag, bagSlot = FindItemInBankByItemKey(want.itemKey, wantRune, want.itemID, slotID, which, used)
    elseif WantHasSpecificLink(want) then
        bag, bagSlot = FindItemInBankByLink(want.itemLink, which, used)
    else
        bag, bagSlot = FindItemInBankByItemIDPreferringRune(want.itemID, wantRune, which, used)
    end
    if bag then
        MarkLocUsed(used, bag, bagSlot)
        return bag, bagSlot
    end
    return nil
end

--- First empty slot in player bags (Flux.Inventory carried bag IDs).
local function FindFirstEmptyPlayerBagSlot()
    local inv = Inv()
    if inv and inv.GetFirstFreeBagSlot then
        local bag, slot = inv.GetFirstFreeBagSlot()
        if bag ~= nil then
            return bag, slot
        end
    end
    local mover = _G.FluxItemMover
    if mover and mover.FindFirstEmptyBagSlot then
        local bag, slot = mover.FindFirstEmptyBagSlot(GetCharacterBagIDs())
        if bag ~= nil then
            return bag, slot
        end
    end
    return nil, nil
end

local function UnequipInventorySlotToBag(invSlot)
    local destBag, destSlot = FindFirstEmptyPlayerBagSlot()
    if not destBag then
        return false
    end
    ClearCursor()
    if not _G.PickupInventoryItem then
        return false
    end
    pcall(_G.PickupInventoryItem, invSlot)
    if not GetCursorInfo() then
        ClearCursor()
        return false
    end
    Compat.PickupContainerItem(destBag, destSlot)
    ClearCursor()
    return Equipment.IsInventorySlotEmpty(invSlot)
end

local function WithdrawOneStackFromBankToBags(bankBag, bankSlot)
    ClearCursor()
    local destBag, destSlot = FindFirstEmptyPlayerBagSlot()
    if not destBag then
        R.Warn("No empty bag space to withdraw from bank.")
        ClearCursor()
        return false
    end
    Compat.PickupContainerItem(bankBag, bankSlot)
    if not GetCursorInfo() then
        ClearCursor()
        return false
    end
    Compat.PickupContainerItem(destBag, destSlot)
    ClearCursor()
    return true
end

--- Build ordered list of { bankBag, bankSlot } for items needed by snapshot that are in bank but not in bags.
local function BuildBankWithdrawQueue(snapshot)
    local q = {}
    local seen = {}
    local usedBags = {}
    local usedBank = {}
    for slotID = SLOT_MIN, SlotMax() do
        if slotID == INVSLOT_OFFHAND and Equipment.ShouldIgnoreOffHandSlot(snapshot) then
        else
            local want = snapshot[slotID]
            if want and want.itemID and not SlotWantSatisfiedIncludingJewelryPeer(slotID, want, snapshot) then
                local bag = FindBagCopyForWant(want, slotID, usedBags)
                if not bag then
                    local bankBag, bankSlot = FindBankCopyForWant(want, slotID, usedBank)
                    if bankBag and bankSlot then
                        local k = LocKey(bankBag, bankSlot)
                        if k and not seen[k] then
                            seen[k] = true
                            q[#q + 1] = { bankBag, bankSlot }
                        end
                    end
                end
            end
        end
    end
    return q
end

--- True while async bank→bag moves are in progress (guards duplicate Apply / bank-open hook).
Equipment._bankWithdrawInProgress = false

--- Active profile name (unused legacy; kept for saved-var compatibility).
Equipment._bankWithdrawPendingName = nil

--- Delay between bank withdrawals so the server updates bank/bag state (0-tick chains can drop picks).
local BANK_WITHDRAW_STEP_DELAY = 0.08

--- Withdraw one stack per tick, rebuilding the queue each time so coordinates stay valid and nothing is skipped.
local function RunBankWithdrawSequence(snapshot, onDone)
    local stepCount = 0
    local MAX_BANK_WITHDRAW_STEPS = 64
    local function step()
        stepCount = stepCount + 1
        if stepCount > MAX_BANK_WITHDRAW_STEPS then
            Equipment._bankWithdrawInProgress = false
            R.Warn("Bank withdraw stopped (bag full or too many items). Free bag space and try again.")
            if onDone then
                onDone()
            end
            return
        end
        if type(snapshot) ~= "table" then
            Equipment._bankWithdrawInProgress = false
            if onDone then
                onDone()
            end
            return
        end
        if not CanTakeFromBank() or InCombatLockdown() then
            Equipment._bankWithdrawInProgress = false
            if onDone then
                onDone()
            end
            return
        end
        local q = BuildBankWithdrawQueue(snapshot)
        if not q or #q == 0 then
            Equipment._bankWithdrawInProgress = false
            if onDone then
                onDone()
            end
            return
        end
        Equipment._bankWithdrawInProgress = true
        local e = q[1]
        pcall(function()
            WithdrawOneStackFromBankToBags(e[1], e[2])
        end)
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(BANK_WITHDRAW_STEP_DELAY, step)
        else
            step()
        end
    end
    step()
end

--- Load pipeline: move profile gear from bank to bags only (no equip). Used in parallel with talent/spec cast.
function Equipment.StartParallelBankWithdrawForLoad(snapshot, runesSnapshot)
    if type(snapshot) ~= "table" or InCombatLockdown() or not CanTakeFromBank() then
        return false
    end
    Equipment._applyRuneSnapshot = runesSnapshot
    local q = BuildBankWithdrawQueue(snapshot)
    if not q or #q == 0 then
        return false
    end
    RunBankWithdrawSequence(snapshot, function()
        -- Withdraw-only; equip runs later via ApplyWithCallback / ApplyInternalCore.
    end)
    return true
end

local function BagSlotStillHasWant(bag, bagSlot, want, equipSlotID)
    if not bag or not bagSlot or not want then return false end
    local itemID
    local inv = Inv()
    if inv and inv.GetItemID then
        itemID = inv.GetItemID(bag, bagSlot)
    else
        itemID = Compat.GetContainerItemID(bag, bagSlot)
    end
    if not ItemIDsEqual(itemID, want.itemID) then return false end
    if WantHasItemKey(want) then
        local k = Equipment.GetItemKeyForBagSlot(bag, bagSlot)
        if not k then return false end
        if k == want.itemKey then return true end
        return ItemKeysEnchantMatch(want.itemKey, k, equipSlotID, bag, bagSlot)
    end
    if WantHasSpecificLink(want) then
        local link = Compat.GetContainerItemLink(bag, bagSlot)
        return ItemLinksMatch(link, want.itemLink)
    end
    return true
end

--- True if the stack at `(bag, slot)` is the same item identity as saved `want`
--- (itemKey / itemLink / legacy itemID-only). `profileInvSlotID` is the profile
--- paperdoll slot (1–19) for this entry — used for SoD rune-line stripping when
--- comparing keys. Same rules as apply / BagSlotStillHasWant.
function Equipment.BagSlotMatchesSavedWant(bag, slot, want, profileInvSlotID)
    return BagSlotStillHasWant(bag, slot, want, profileInvSlotID)
end

--- True when `(bag, slot)` matches any saved gear entry across respec profiles / equipment presets.
function Equipment.IsBagSlotInSavedGearSet(bag, slot)
    local idx = _G.FluxRespec_GearSetIndex or (R.GearSetIndex)
    return idx and idx.IsBagSlotInSavedGearSet and idx.IsBagSlotInSavedGearSet(bag, slot) or false
end

local function IsAnyInventoryLocked()
    for i = SLOT_MIN, SlotMax() do
        if IsInventoryItemLocked(i) then
            return true
        end
    end
    for _, bag in ipairs(GetCharacterBagIDs()) do
        local num = Compat.GetContainerNumSlots(bag)
        for slot = 1, num do
            if _G.C_Container and _G.C_Container.GetContainerItemInfo then
                local info = _G.C_Container.GetContainerItemInfo(bag, slot)
                if info and info.isLocked then return true end
            elseif _G.GetContainerItemInfo then
                local _, _, locked = _G.GetContainerItemInfo(bag, slot)
                if locked then return true end
            end
        end
    end
    return false
end

-- -----------------------------------------------------------------------------
-- Apply
-- -----------------------------------------------------------------------------

-- Persistent swap list survives iterations of ITEM_LOCK_CHANGED.
Equipment._pending = nil   -- snapshot waiting for out-of-combat.
Equipment._pendingRuneSnapshot = nil
Equipment._applyRuneSnapshot = nil -- optional rune profile during Apply (SoD duplicate pick).
Equipment._applySnapshot = nil -- equipment snapshot currently being applied (jewelry steal checks).
Equipment._active = false  -- true while iterating swaps.
-- ITEM_LOCK_CHANGED / BAG_UPDATE can fire synchronously inside EquipCursorItem / ClearCursor.
-- Running IterateSwaps from the event handler in the same call stack recurses until C stack overflow
-- (and can cascade through SecureHandlers / action bar updates). Always continue on the next frame.
Equipment._swapDeferScheduled = false

local function UsedBagLocsFromSwaps(swaps, exceptSlot)
    local used = {}
    if type(swaps) ~= "table" then
        return used
    end
    for sid, inf in pairs(swaps) do
        if sid ~= exceptSlot and inf and inf.bag ~= nil and inf.slot ~= nil then
            MarkLocUsed(used, inf.bag, inf.slot)
        end
    end
    return used
end

local function BuildSwapList(snapshot)
    -- Returns slotID -> { itemID, itemLink?, bag, slot } or { fromInventorySlot, ... } for slots that need changing.
    local swaps = {}
    local missing = {}
    local usedBags = {}
    for slotID = SLOT_MIN, SlotMax() do
        if slotID == INVSLOT_OFFHAND and Equipment.ShouldIgnoreOffHandSlot(snapshot) then
            -- Two-handed main hand: paperdoll hides off-hand; do not swap or diff this slot.
        else
        local want = snapshot[slotID]
        if want and want.itemID then
            if not SlotMatchesWant(slotID, want) then
                local bag, bagSlot = FindBagCopyForWant(want, slotID, usedBags)
                if bag and bagSlot then
                    swaps[slotID] = {
                        itemID = want.itemID,
                        itemLink = want.itemLink,
                        itemKey = want.itemKey,
                        bag = bag,
                        slot = bagSlot,
                    }
                elseif CanStealJewelryPeer(snapshot, slotID, want) then
                    local peer = JewelryPeerSlot(slotID)
                    swaps[slotID] = {
                        itemID = want.itemID,
                        itemLink = want.itemLink,
                        itemKey = want.itemKey,
                        fromInventorySlot = peer,
                    }
                else
                    missing[#missing + 1] = want.itemID
                end
            end
        elseif want and want.empty then
            if not Equipment.IsInventorySlotEmpty(slotID) then
                local bag = FindFirstEmptyPlayerBagSlot()
                if bag then
                    swaps[slotID] = { unequip = true }
                else
                    missing[#missing + 1] = ("slot:%d"):format(slotID)
                end
            end
        end
        end
    end
    return swaps, missing
end

--- SoD: equip slots that appear first in the rune queue before other swaps so the correct item is
--- in place before the player (or CastNext) engraves that slot.
local function OrderedSwapSlotIDs(swaps)
    local seen = {}
    local ordered = {}
    if R.Runes and R.Runes.GetActiveQueue then
        local q = R.Runes.GetActiveQueue()
        if type(q) == "table" then
            for i = 1, #q do
                local e = q[i]
                local sid = e and e.slotID
                if sid and swaps[sid] and not seen[sid] then
                    seen[sid] = true
                    ordered[#ordered + 1] = sid
                end
            end
        end
    end
    local rest = {}
    for slotID in pairs(swaps) do
        if swaps[slotID] and not seen[slotID] then
            rest[#rest + 1] = slotID
        end
    end
    table.sort(rest)
    for i = 1, #rest do
        ordered[#ordered + 1] = rest[i]
    end
    return ordered
end

local function IterateSwaps(swaps)
    -- One pass: for each slot needing change, equip from a bag stack or move from the paired ring/trinket slot.
    local remaining = 0
    local snapshot = Equipment._applySnapshot
    for _, slotID in ipairs(OrderedSwapSlotIDs(swaps)) do
        local info = swaps[slotID]
        if info then
            if info.unequip then
                if Equipment.IsInventorySlotEmpty(slotID) then
                    swaps[slotID] = nil
                else
                    UnequipInventorySlotToBag(slotID)
                    if Equipment.IsInventorySlotEmpty(slotID) then
                        swaps[slotID] = nil
                    else
                        remaining = remaining + 1
                    end
                end
            elseif SlotMatchesWant(slotID, info) then
                swaps[slotID] = nil
            else
                local invSrc = info.fromInventorySlot
                if invSrc then
                    if not SlotMatchesWant(invSrc, info) then
                        local peer = JewelryPeerSlot(slotID)
                        if peer and SlotMatchesWant(peer, info) and CanStealJewelryPeer(snapshot, slotID, info) then
                            invSrc = peer
                            info.fromInventorySlot = peer
                        else
                            invSrc = nil
                        end
                    elseif not CanStealJewelryPeer(snapshot, slotID, info) then
                        invSrc = nil
                    end
                end
                if invSrc and _G.PickupInventoryItem then
                    ClearCursor()
                    pcall(_G.PickupInventoryItem, invSrc)
                    local cursorType = GetCursorInfo()
                    if cursorType then
                        if _G.EquipCursorItem then
                            _G.EquipCursorItem(slotID)
                        elseif _G.PickupInventoryItem then
                            _G.PickupInventoryItem(slotID)
                        end
                        ClearCursor()
                    end
                else
                    local bag, bagSlot = info.bag, info.slot
                    local used = UsedBagLocsFromSwaps(swaps, slotID)
                    if not BagSlotStillHasWant(bag, bagSlot, info, slotID) or IsLocUsed(used, bag, bagSlot) then
                        bag, bagSlot = FindBagCopyForWant(info, slotID, used)
                        info.bag, info.slot = bag, bagSlot
                        info.fromInventorySlot = nil
                    end
                    if bag and bagSlot then
                        ClearCursor()
                        Compat.PickupContainerItem(bag, bagSlot)
                        local cursorType = GetCursorInfo()
                        if cursorType then
                            if _G.EquipCursorItem then
                                _G.EquipCursorItem(slotID)
                            elseif _G.PickupInventoryItem then
                                _G.PickupInventoryItem(slotID)
                            end
                            ClearCursor()
                        end
                    end
                end
                if SlotMatchesWant(slotID, info) then
                    swaps[slotID] = nil
                else
                    remaining = remaining + 1
                end
            end
        end
    end
    return remaining
end

local function EndApply(ok)
    Equipment._active = false
    Equipment._swapDeferScheduled = false
    Equipment._swaps = nil
    Equipment._applyRuneSnapshot = nil
    Equipment._applySnapshot = nil
    if Equipment._lockWatcher then
        Equipment._lockWatcher:UnregisterAllEvents()
        Equipment._lockWatcher:SetScript("OnEvent", nil)
        Equipment._lockWatcher = nil
    end
    local cb = Equipment._applyDoneCallback
    Equipment._applyDoneCallback = nil
    if cb then
        pcall(cb, ok)
    end
    R.Fire("EQUIPMENT_APPLIED", ok)
end

--- Run one swap pass when not inside EquipCursorItem's synchronous event chain.
local function RunSwapContinuePass()
    if not Equipment._active or not Equipment._swaps then
        Equipment._swapDeferScheduled = false
        return
    end
    if IsAnyInventoryLocked() then
        Equipment._swapDeferScheduled = false
        -- Still mid-pickup / server lock — try again next frame (do not recurse synchronously).
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0, RunSwapContinuePass)
        elseif Equipment._lockWatcher then
            Equipment._lockWatcher:SetScript("OnUpdate", function(self)
                self:SetScript("OnUpdate", nil)
                RunSwapContinuePass()
            end)
        end
        return
    end
    Equipment._swapDeferScheduled = false
    local remaining = IterateSwaps(Equipment._swaps)
    if remaining == 0 then
        EndApply(true)
    end
end

--- Coalesced next-frame (or next OnUpdate) continuation; never call IterateSwaps synchronously from events.
local function DeferSwapContinue()
    if not Equipment._active or not Equipment._swaps then return end
    if Equipment._swapDeferScheduled then return end
    Equipment._swapDeferScheduled = true
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, RunSwapContinuePass)
    elseif Equipment._lockWatcher then
        Equipment._lockWatcher:SetScript("OnUpdate", function(self)
            self:SetScript("OnUpdate", nil)
            RunSwapContinuePass()
        end)
    else
        RunSwapContinuePass()
    end
end

local function StartLockWatcher()
    if Equipment._lockWatcher then return end
    local f = CreateFrame("Frame")
    f:RegisterEvent("ITEM_LOCK_CHANGED")
    f:RegisterEvent("BAG_UPDATE_DELAYED")
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:SetScript("OnEvent", function()
        if not Equipment._active or not Equipment._swaps then return end
        DeferSwapContinue()
    end)
    Equipment._lockWatcher = f
end

local function ApplyInternalCore(snapshot)
    Equipment._swapDeferScheduled = false
    Equipment._applySnapshot = snapshot
    if type(snapshot) ~= "table" then
        EndApply(false)
        return false
    end
    local swaps, missing = BuildSwapList(snapshot)
    if #missing > 0 then
        R.Warn(("Could not find %d gear item(s) in bags (withdraw from bank first if they are stored there)."):format(#missing))
    end
    if next(swaps) == nil then
        EndApply(true)
        return true
    end
    Equipment._swaps = swaps
    Equipment._active = true
    StartLockWatcher()
    -- First pass runs immediately; further work is always deferred (see DeferSwapContinue).
    local remaining = IterateSwaps(swaps)
    if remaining == 0 then
        EndApply(true)
    else
        -- Ensure a follow-up pass even if lock events were coalesced or missed after the first equip.
        DeferSwapContinue()
    end
    return true
end

local function ApplyInternal(snapshot)
    Equipment._swapDeferScheduled = false
    if type(snapshot) ~= "table" then
        EndApply(false)
        return false
    end
    if CanTakeFromBank() and not InCombatLockdown() then
        local q = BuildBankWithdrawQueue(snapshot)
        if q and #q > 0 then
            RunBankWithdrawSequence(snapshot, function()
                ApplyInternalCore(snapshot)
            end)
            return true
        end
    end
    return ApplyInternalCore(snapshot)
end

--- Like Apply, but invokes callback(ok) once when the swap finishes (sync or async).
--- `runesSnapshot` (optional): profile.runes — used to pick the right duplicate item by engraving (SoD).
--- Use before rune engraving so gear matches the profile. Callback always runs once.
function Equipment.ApplyWithCallback(snapshot, callback, runesSnapshot)
    if not callback then
        return Equipment.Apply(snapshot, runesSnapshot)
    end
    if type(snapshot) ~= "table" or next(snapshot) == nil then
        callback(true)
        return true
    end
    Equipment._applyDoneCallback = callback
    return Equipment.Apply(snapshot, runesSnapshot)
end

--- Apply an equipment snapshot. Defers until PLAYER_REGEN_ENABLED when in combat.
--- `runesSnapshot`: optional profile.runes table for duplicate bag selection (SoD).
function Equipment.Apply(snapshot, runesSnapshot)
    Equipment._applyRuneSnapshot = runesSnapshot
    if InCombatLockdown() then
        Equipment._pending = snapshot
        Equipment._pendingRuneSnapshot = runesSnapshot
        R.Print("In combat: gear swap will apply when combat ends.")
        if not Equipment._combatWatcher then
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            f:SetScript("OnEvent", function(self)
                if Equipment._pending then
                    local s = Equipment._pending
                    Equipment._applyRuneSnapshot = Equipment._pendingRuneSnapshot
                    Equipment._pending = nil
                    Equipment._pendingRuneSnapshot = nil
                    ApplyInternal(s)
                end
                self:UnregisterAllEvents()
                self:SetScript("OnEvent", nil)
                Equipment._combatWatcher = nil
            end)
            Equipment._combatWatcher = f
        end
        return false
    end
    return ApplyInternal(snapshot)
end

--- True when an inventory slot change can affect active-profile gear matching (incl. ring/trinket peers).
function Equipment.SlotRelevantToProfileEquipment(profile, slotID)
    local snap = profile and profile.equipment
    if type(snap) ~= "table" or not slotID then
        return false
    end
    local want = snap[slotID]
    if want and want.itemID then
        return true
    end
    if want and want.empty then
        return true
    end
    local peer = JewelryPeerSlot(slotID)
    if peer then
        want = snap[peer]
        return want and want.itemID and true or false
    end
    return false
end

--- How many items differ from the snapshot? Useful for UI summaries.
function Equipment.DiffCount(snapshot)
    if type(snapshot) ~= "table" then return 0 end
    local count = 0
    local skipOH = Equipment.ShouldIgnoreOffHandSlot(snapshot)
    for slotID = SLOT_MIN, SlotMax() do
        if not (skipOH and slotID == INVSLOT_OFFHAND) then
            local want = snapshot[slotID]
            if want and want.itemID then
                if not SlotWantSatisfiedIncludingJewelryPeer(slotID, want, snapshot) then
                    count = count + 1
                end
            elseif want and want.empty then
                if not Equipment.IsInventorySlotEmpty(slotID) then
                    count = count + 1
                end
            end
        end
    end
    return count
end

--- True if gear apply should run: any slot not covered by the loose jewelry-peer rule, or ring/trinket
--- order differs from the snapshot (DiffCount can be 0 while PickupInventoryItem reorder is still needed).
function Equipment.AnyGearChangeNeeded(snapshot)
    if type(snapshot) ~= "table" then
        return false
    end
    if Equipment.DiffCount(snapshot) > 0 then
        return true
    end
    for slotID = SLOT_MIN, SlotMax() do
        local peer = JewelryPeerSlot(slotID)
        if peer then
            local want = snapshot[slotID]
            if want and want.itemID and not SlotMatchesWant(slotID, want) then
                return true
            end
        else
            local want = snapshot[slotID]
            if want and want.empty and not Equipment.IsInventorySlotEmpty(slotID) then
                return true
            end
        end
    end
    return false
end

--- True if the item currently equipped in `slotID` matches the profile entry (same rules as apply / DiffCount).
--- Pass `equipmentSnapshot` (full profile.equipment) so rings/trinkets count when worn on the paired slot.
function Equipment.SlotMatchesEntry(slotID, want, equipmentSnapshot)
    if not want then return false end
    if want.empty then
        return Equipment.IsInventorySlotEmpty(slotID)
    end
    if not want.itemID then return false end
    if equipmentSnapshot and type(equipmentSnapshot) == "table" and JewelryPeerSlot(slotID) then
        return SlotWantSatisfiedIncludingJewelryPeer(slotID, want, equipmentSnapshot)
    end
    return SlotMatchesWant(slotID, want)
end

--- Returns bag, slot for a bag stack whose link matches `targetLink`, or nil (for bag-style GameTooltip:SetBagItem).
function Equipment.FindBagSlotByItemLink(targetLink)
    return FindItemInBagsByLink(targetLink)
end

local GEAR_SLOT_LABELS = {
    [1] = "Head",
    [2] = "Neck",
    [3] = "Shoulders",
    [4] = "Shirt",
    [5] = "Chest",
    [6] = "Waist",
    [7] = "Legs",
    [8] = "Feet",
    [9] = "Wrists",
    [10] = "Hands",
    [11] = "Ring 1",
    [12] = "Ring 2",
    [13] = "Trinket 1",
    [14] = "Trinket 2",
    [15] = "Back",
    [16] = "Main Hand",
    [17] = "Off Hand",
    [18] = "Ranged",
    [19] = "Tabard",
}

local function WantItemDisplayName(want)
    if not want then return "?" end
    if want.empty then
        return "(empty)"
    end
    if want.itemLink and _G.GetItemInfo then
        local n = select(1, _G.GetItemInfo(want.itemLink))
        if n and n ~= "" then return n end
    end
    if want.itemID and _G.GetItemInfo then
        local n = select(1, _G.GetItemInfo(want.itemID))
        if n and n ~= "" then return n end
    end
    return "#" .. tostring(want.itemID or "?")
end

--- Rows for UI: `status` = equipped | bags | bank | missing | unknown (no bank memory yet).
function Equipment.GetProfileGearAvailability(profile)
    local snap = profile and profile.equipment
    local out = {}
    if type(snap) ~= "table" then
        return out
    end
    if type(profile) == "table" and profile.includes and R.Includes and R.Includes.CopyEnabledEquipment then
        snap = R.Includes.CopyEnabledEquipment(snap, profile) or snap
    elseif type(profile) == "table" and profile.equipmentSlots and R.Includes and R.Includes.CopyEnabledPresetEquipment then
        snap = R.Includes.CopyEnabledPresetEquipment(snap, profile) or snap
    end
    local inv = Inv()
    local hasBankMemory = inv and inv.HasCachedBank and inv.HasCachedBank() or false
    local usedBags = {}
    local usedBank = {}
    local bankCountUsed = {}
    for slotID = SLOT_MIN, SlotMax() do
        if not (slotID == INVSLOT_OFFHAND and Equipment.ShouldIgnoreOffHandSlot(snap)) then
            local want = snap[slotID]
            if want and want.itemID then
                local label = GEAR_SLOT_LABELS[slotID] or ("Slot " .. tostring(slotID))
                local itemName = WantItemDisplayName(want)
                if SlotWantSatisfiedIncludingJewelryPeer(slotID, want, snap) then
                    out[#out + 1] = {
                        slotID = slotID,
                        label = label,
                        itemName = itemName,
                        status = "equipped",
                    }
                else
                    local bag = FindBagCopyForWant(want, slotID, usedBags)
                    if bag then
                        out[#out + 1] = {
                            slotID = slotID,
                            label = label,
                            itemName = itemName,
                            status = "bags",
                        }
                    else
                        local bankBag = FindBankCopyForWant(want, slotID, usedBank, "bankCached")
                        if not bankBag and inv and inv.GetCachedBankCount then
                            local n = inv.GetCachedBankCount(want.itemID) or 0
                            local already = bankCountUsed[want.itemID] or 0
                            if n > already then
                                bankCountUsed[want.itemID] = already + 1
                                bankBag = true
                            end
                        elseif bankBag then
                            bankCountUsed[want.itemID] = (bankCountUsed[want.itemID] or 0) + 1
                        end
                        if bankBag then
                            out[#out + 1] = {
                                slotID = slotID,
                                label = label,
                                itemName = itemName,
                                status = "bank",
                            }
                        elseif hasBankMemory then
                            out[#out + 1] = {
                                slotID = slotID,
                                label = label,
                                itemName = itemName,
                                status = "missing",
                            }
                        else
                            out[#out + 1] = {
                                slotID = slotID,
                                label = label,
                                itemName = itemName,
                                status = "unknown",
                            }
                        end
                    end
                end
            elseif want and want.empty then
                local label = GEAR_SLOT_LABELS[slotID] or ("Slot " .. tostring(slotID))
                local itemName = WantItemDisplayName(want)
                if Equipment.IsInventorySlotEmpty(slotID) then
                    out[#out + 1] = {
                        slotID = slotID,
                        label = label,
                        itemName = itemName,
                        status = "equipped",
                    }
                else
                    out[#out + 1] = {
                        slotID = slotID,
                        label = label,
                        itemName = itemName,
                        status = "bags",
                    }
                end
            end
        end
    end
    return out
end

--- Single-slot availability for UI incremental refresh.
function Equipment.GetSlotGearStatus(profile, slotID)
    slotID = tonumber(slotID)
    if not slotID then
        return nil
    end
    for _, row in ipairs(Equipment.GetProfileGearAvailability(profile)) do
        if row.slotID == slotID then
            return row.status
        end
    end
    return nil
end

--- True if any needed piece is not on the character and not in bags (definitively missing when bank was open).
function Equipment.ProfileHasMissingGear(profile)
    for _, row in ipairs(Equipment.GetProfileGearAvailability(profile)) do
        if row.status == "missing" then
            return true
        end
    end
    return false
end

--- True if something is only in the bank (or unknown while bank closed) — still needs attention before equip.
function Equipment.ProfileHasGearIssue(profile)
    for _, row in ipairs(Equipment.GetProfileGearAvailability(profile)) do
        if row.status == "bank" or row.status == "missing" or row.status == "unknown" then
            return true
        end
    end
    return false
end

--- For flyout border: "missing" (worst), "bank", "unknown", or nil if OK for diff display.
function Equipment.GetProfileGearIssueKind(profile)
    local worst = nil
    local rank = { missing = 3, unknown = 2, bank = 1 }
    for _, row in ipairs(Equipment.GetProfileGearAvailability(profile)) do
        local s = row.status
        if s == "missing" or s == "bank" or s == "unknown" then
            if not worst or (rank[s] or 0) > (rank[worst] or 0) then
                worst = s
            end
        end
    end
    return worst
end

-- -----------------------------------------------------------------------------
-- No-profile UI: bag items that can be equipped into a paperdoll slot
-- -----------------------------------------------------------------------------

--- Whether `equipLoc` (INVTYPE_*) from GetItemEquipLoc can go in `invSlot` (1..19).
local function EquipLocFitsInventorySlot(equipLoc, invSlot)
    if not equipLoc or equipLoc == "" or not invSlot then return false end
    if invSlot == 5 then
        return equipLoc == "INVTYPE_CHEST" or equipLoc == "INVTYPE_ROBE"
    end
    if invSlot == 11 or invSlot == 12 then
        return equipLoc == "INVTYPE_FINGER"
    end
    if invSlot == 13 or invSlot == 14 then
        return equipLoc == "INVTYPE_TRINKET"
    end
    if invSlot == INVSLOT_MAINHAND then
        return equipLoc == "INVTYPE_WEAPON"
            or equipLoc == "INVTYPE_2HWEAPON"
            or equipLoc == "INVTYPE_STAFF"
            or equipLoc == "INVTYPE_POLEARM"
            or equipLoc == "INVTYPE_WEAPONMAINHAND"
            or equipLoc == "INVTYPE_FISHINGPOLE"
    end
    if invSlot == INVSLOT_OFFHAND then
        return equipLoc == "INVTYPE_WEAPON"
            or equipLoc == "INVTYPE_SHIELD"
            or equipLoc == "INVTYPE_HOLDABLE"
            or equipLoc == "INVTYPE_WEAPONOFFHAND"
    end
    if invSlot == 18 then
        return equipLoc == "INVTYPE_RANGED"
            or equipLoc == "INVTYPE_RANGEDRIGHT"
            or equipLoc == "INVTYPE_THROWN"
    end
    local map = {
        [1] = "INVTYPE_HEAD",
        [2] = "INVTYPE_NECK",
        [3] = "INVTYPE_SHOULDER",
        [4] = "INVTYPE_BODY",
        [6] = "INVTYPE_WAIST",
        [7] = "INVTYPE_LEGS",
        [8] = "INVTYPE_FEET",
        [9] = "INVTYPE_WRIST",
        [10] = "INVTYPE_HAND",
        [15] = "INVTYPE_CLOAK",
        [19] = "INVTYPE_TABARD",
    }
    return map[invSlot] == equipLoc
end

--- True if the item can be placed in `invSlot` (and this character can use it).
function Equipment.CanItemGoInInventorySlot(itemID, itemLink, invSlot)
    local shared = _G.FluxEquipSlotCandidates
    if shared and shared.CanItemGoInInventorySlot then
        return shared.CanItemGoInInventorySlot(itemID, itemLink, invSlot)
    end
    if not itemID or itemID == 0 or not invSlot then return false end
    if not _G.IsEquippableItem or not _G.IsEquippableItem(itemID) then return false end
    local loc = GetItemEquipLoc(itemID, itemLink)
    if not loc then return false end
    if not EquipLocFitsInventorySlot(loc, invSlot) then return false end
    -- Two-handers never go in off-hand.
    if invSlot == INVSLOT_OFFHAND and IsTwoHandEquipLoc(loc) then
        return false
    end
    return true
end

--- Sorted list of `{ bag, slot, itemID, itemLink, name }` for items in bags
--- (plus live bank when the banker is open so a click can take and equip).
function Equipment.GetBagCandidatesForInventorySlot(invSlot)
    local shared = _G.FluxEquipSlotCandidates
    if shared and shared.GetForInventorySlot then
        local list = shared.GetForInventorySlot(invSlot, nil, { includeBank = true }) or {}
        local out = {}
        for i = 1, #list do
            local c = list[i]
            if c and not c.isEmpty then
                out[#out + 1] = c
            end
        end
        return out
    end
    local out = {}
    if not invSlot or invSlot < SLOT_MIN or invSlot > SlotMax() then return out end
    for _, bag in ipairs(GetCharacterBagIDs()) do
        local num = Compat.GetContainerNumSlots(bag)
        for slot = 1, num do
            local id = Compat.GetContainerItemID(bag, slot)
            if id and id ~= 0 then
                local link = Compat.GetContainerItemLink(bag, slot)
                if Equipment.CanItemGoInInventorySlot(id, link, invSlot) then
                    local name = (GetItemInfo and select(1, GetItemInfo(link or id))) or ("#" .. tostring(id))
                    out[#out + 1] = {
                        bag = bag,
                        slot = slot,
                        itemID = id,
                        itemLink = link,
                        name = name,
                    }
                end
            end
        end
    end
    table.sort(out, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)
    return out
end

--- Pick up from bag and equip to paperdoll slot (call only from a secure click path).
function Equipment.EquipBagSlotToInventorySlot(bag, bagSlot, invSlot)
    local shared = _G.FluxEquipSlotCandidates
    if shared and shared.EquipToInventorySlot then
        return shared.EquipToInventorySlot(bag, bagSlot, invSlot)
    end
    if InCombatLockdown() then return false end
    if bag == nil or not bagSlot or not invSlot then return false end
    ClearCursor()
    Compat.PickupContainerItem(bag, bagSlot)
    local cursorType = GetCursorInfo and GetCursorInfo()
    if cursorType then
        if _G.EquipCursorItem then
            _G.EquipCursorItem(invSlot)
        elseif _G.PickupInventoryItem then
            _G.PickupInventoryItem(invSlot)
        end
        ClearCursor()
    end
    return true
end

-- -----------------------------------------------------------------------------
-- Bank withdraw runs only via explicit Equipment.Apply (Load Profile / Equip Preset).
-- Selecting a profile or opening the bank does not auto-withdraw or equip gear.
-- -----------------------------------------------------------------------------

function Equipment.NotifyActiveProfileMayNeedBankWithdraw()
    -- Intentional no-op: gear moves only when the user clicks Equip gear / Load Profile / Equip Preset.
end

R.Equipment = Equipment
