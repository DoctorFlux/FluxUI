-- FluxSalvage_Classify.lua
-- Item classification for salvage actions (ported from Molinari api/items.lua)

FluxSalvage = FluxSalvage or {}
local S = FluxSalvage

local Data = S.Data or {}
local Colors = S.Colors or {}

local wipe = table.wipe or wipe

-- ---------------------------------------------------------------------------
-- FluxInv accessors (carried bags / container reads)
-- ---------------------------------------------------------------------------

local function Inv()
    return _G.FluxInv
end

local function CoerceNumber(v)
    if v == nil then
        return nil
    end
    local ok, n = pcall(tonumber, v)
    if ok and type(n) == "number" and n == n then
        return n
    end
end

local function CoerceItemID(v)
    local n = CoerceNumber(v)
    if n and n > 0 then
        return n
    end
end

local function ItemIDFromLink(link)
    if type(link) ~= "string" then
        return nil
    end
    local id = link:match("item:(%d+)")
    return CoerceItemID(id)
end

local function Containers()
    local inv = Inv()
    if inv and inv.Containers then
        return inv.Containers
    end
    local Flux = _G.Flux
    return Flux and Flux.Inventory and Flux.Inventory.Containers
end

--- True when bag is a player-carried container (never Classic bank bag 5).
function S.IsCarriedBag(bagID)
    bagID = CoerceNumber(bagID)
    if not bagID then
        return false
    end
    local C = Containers()
    if C and C.IsCarriedBag then
        return C.IsCarriedBag(bagID)
    end
    local inv = Inv()
    if inv and inv.GetCarriedBagIDs then
        local ids = inv.GetCarriedBagIDs()
        for i = 1, #ids do
            if ids[i] == bagID then
                return true
            end
        end
        return false
    end
    -- Fallback if FluxInv unavailable: backpack + bag slots only (no invented reagent/bank 5).
    if bagID < 0 then
        local keyring = _G.KEYRING_CONTAINER or -2
        return bagID == keyring
    end
    local numBags = _G.NUM_BAG_SLOTS or _G.NUM_BAG_FRAMES or 4
    if bagID >= 0 and bagID <= numBags then
        return true
    end
    local numTotal = _G.NUM_TOTAL_BAG_FRAMES or _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS
    if numTotal and bagID >= 0 and bagID <= numTotal then
        return true
    end
    local numReagent = _G.NUM_REAGENTBAG_SLOTS or 0
    if numReagent > 0 and Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
        return bagID == Enum.BagIndex.ReagentBag
    end
    return false
end

function S.GetContainerItemID(bag, slot)
    bag = CoerceNumber(bag)
    slot = CoerceNumber(slot)
    if not bag or not slot then
        return
    end
    local inv = Inv()
    if inv and inv.GetContainerItemID then
        local id = CoerceItemID(inv.GetContainerItemID(bag, slot))
        if id then
            return id
        end
    end
    if C_Container and C_Container.GetContainerItemID then
        local ok, raw = pcall(C_Container.GetContainerItemID, bag, slot)
        if ok then
            local id = CoerceItemID(raw)
            if id then
                return id
            end
        end
    end
    if _G.GetContainerItemID then
        local ok, raw = pcall(_G.GetContainerItemID, bag, slot)
        if ok then
            local id = CoerceItemID(raw)
            if id then
                return id
            end
        end
    end
    local link
    if inv and inv.GetContainerItemLink then
        link = inv.GetContainerItemLink(bag, slot)
    elseif C_Container and C_Container.GetContainerItemLink then
        local ok, raw = pcall(C_Container.GetContainerItemLink, bag, slot)
        if ok then
            link = raw
        end
    end
    return ItemIDFromLink(link)
end

function S.GetContainerItemStackCount(bag, slot)
    local inv = Inv()
    if inv and inv.GetContainerItemInfo then
        local info = inv.GetContainerItemInfo(bag, slot)
        if info and info.count then
            return info.count
        end
    end
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        return info and info.stackCount or nil
    end
end

-- ---------------------------------------------------------------------------
-- Spell-known + classify caches
-- ---------------------------------------------------------------------------

local spellKnownCache = {}
local classifyCache = {} -- [itemID] = { spellID, color, numItems } | false
local comprehendSpellID
local comprehendSpellName

local MILLING_SPELL = 51005
local PROSPECTING_SPELL = 31252
local DISENCHANT_SPELL = 13262

local function KnowsSpell(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return false
    end
    local cached = spellKnownCache[spellID]
    if cached ~= nil then
        return cached
    end
    local known = false
    if C_SpellBook and C_SpellBook.IsSpellInSpellBook and Enum and Enum.SpellBookSpellBank then
        if C_SpellBook.IsSpellInSpellBook(spellID, Enum.SpellBookSpellBank.Player) then
            known = true
        end
    end
    if not known and C_SpellBook and C_SpellBook.IsSpellKnownOrInSpellBook then
        known = C_SpellBook.IsSpellKnownOrInSpellBook(spellID) and true or false
    end
    if not known and C_SpellBook and C_SpellBook.IsSpellKnown then
        known = C_SpellBook.IsSpellKnown(spellID) and true or false
    end
    if not known and _G.IsPlayerSpell then
        known = _G.IsPlayerSpell(spellID) and true or false
    end
    spellKnownCache[spellID] = known
    return known
end

local IsPlayerSpell = KnowsSpell

--- Public spell-known probe (cached; invalidated on SPELLS_CHANGED).
function S.KnowsSpell(spellID)
    return KnowsSpell(spellID)
end

function S.InvalidateSpellCache()
    wipe(spellKnownCache)
    wipe(classifyCache)
    comprehendSpellID = nil
    comprehendSpellName = nil
end

function S.InvalidateClassifyCache()
    wipe(classifyCache)
end

local COLOR_WHITE = CreateColor(1, 1, 1)

-- Quality/class enums were renamed in modern clients; numeric IDs stay stable.
local MIN_DISENCHANT_QUALITY = (Enum and Enum.ItemQuality and (Enum.ItemQuality.Uncommon or Enum.ItemQuality.Good)) or 2
local MAX_DISENCHANT_QUALITY = (Enum and Enum.ItemQuality and Enum.ItemQuality.Epic) or 4
local ITEM_CLASS_WEAPON = (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or 2
local ITEM_CLASS_ARMOR = (Enum and Enum.ItemClass and Enum.ItemClass.Armor) or 4
local ITEM_CLASS_PROFESSION = (Enum and Enum.ItemClass and Enum.ItemClass.Profession) or 9
local ITEM_CLASS_GEM = (Enum and Enum.ItemClass and Enum.ItemClass.Gem) or 3
local ITEM_GEM_RELIC = Enum and Enum.ItemGemSubclass and Enum.ItemGemSubclass.Artifactrelic
local INVTYPE_BODY = Enum and Enum.InventoryType and (Enum.InventoryType.IndexBodyType or Enum.InventoryType.Body)

local professionSalvagers = {}

local function AddSalvager(name)
    professionSalvagers[#professionSalvagers + 1] = name
end

local function IsCamelot()
    local Flux = _G.Flux
    local C = Flux and Flux.Client
    if C and (C.isCamelot or C.isForever) then
        return true
    end
    local api = _G.FLUX_API
    return api and (api.isCamelot or api.isForever) and true or false
end

local function Professions()
    local Flux = _G.Flux
    local P = Flux and Flux.Inventory and Flux.Inventory.Professions
    if P then
        return P
    end
    local inv = _G.FluxInv
    return inv and inv.Professions
end

local function SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    if GetSpellInfo then
        local name = GetSpellInfo(spellID)
        if type(name) == "string" and name ~= "" then
            return name
        end
    end
end

local function SkillNameHas(name, needle)
    return type(name) == "string" and name:lower():find(needle, 1, true) and true or false
end

local COMPREHEND_SPELL_NAMES = {
    "Comprehend Scroll",
    "Comprehend",
}

local function NameLooksLikeComprehendSpell(name)
    if type(name) ~= "string" or name == "" then
        return false
    end
    local n = name:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if n == "comprehend" or n == "compreend" then
        return true
    end
    if not (n:find("comprehend", 1, true) or n:find("compreend", 1, true)) then
        return false
    end
    return n:find("scroll", 1, true) and true or false
end

local function IsComprehensionSkillName(name)
    return SkillNameHas(name, "comprehension")
        or SkillNameHas(name, "comprehend")
        or SkillNameHas(name, "compreend")
end

local function HintFromComprehensionText(text)
    if type(text) ~= "string" or text == "" then
        return
    end
    local lower = text:lower()
    if not (lower:find("comprehension", 1, true) or lower:find("comprehend", 1, true) or lower:find("compreend", 1, true)) then
        return
    end
    local need = tonumber(lower:match("comprehension%s*%(?%s*(%d+)") )
        or tonumber(lower:match("comprehend%s*%(?%s*(%d+)") )
        or tonumber(lower:match("compreend%s*%(?%s*(%d+)") )
        or tonumber(lower:match("%(%s*(%d+)%s*%)") )
        or 1
    return {
        skillName = "comprehension",
        required = need,
        met = true,
    }
end

function S.HintFromTooltipText(text)
    return HintFromComprehensionText(text)
end

local function PlayerSpellBank()
    return Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
end

local function RememberKnownSpell(spellID)
    spellID = tonumber(spellID)
    if spellID then
        spellKnownCache[spellID] = true
    end
    return spellID
end

local function SpellIDFromIdentifier(ident)
    if not ident or ident == "" then
        return
    end
    if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
        local ok, id = pcall(C_Spell.GetSpellIDForSpellIdentifier, ident)
        if ok then
            id = tonumber(id)
            if id then
                return id
            end
        end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, ident)
        if ok and type(info) == "table" then
            local id = tonumber(info.spellID)
            if id then
                return id
            end
        end
    end
    if GetSpellInfo then
        local _, _, _, _, _, _, spellID = GetSpellInfo(ident)
        spellID = tonumber(spellID)
        if spellID then
            return spellID
        end
    end
end

local function SpellIDFromBookSlot(slot, foundBank)
    local SB = C_SpellBook
    local bank = foundBank or PlayerSpellBank()
    if SB and SB.GetSpellBookItemInfo then
        local okInfo, info = pcall(SB.GetSpellBookItemInfo, slot, bank)
        if okInfo and type(info) == "table" then
            local id = tonumber(info.spellID) or tonumber(info.actionID)
            if id then
                return RememberKnownSpell(id)
            end
        end
    end
    if SB and SB.GetSpellBookItemType then
        local okType, _, actionID, spellID = pcall(SB.GetSpellBookItemType, slot, bank)
        if okType then
            local id = tonumber(spellID) or tonumber(actionID)
            if id then
                return RememberKnownSpell(id)
            end
        end
    end
end

local function FindComprehendScrollInSpellBook()
    local SB = C_SpellBook
    local bank = PlayerSpellBank()
    if SB and SB.FindSpellBookSlotForSpell then
        for i = 1, #COMPREHEND_SPELL_NAMES do
            local ident = COMPREHEND_SPELL_NAMES[i]
            local ok, slot, foundBank = pcall(SB.FindSpellBookSlotForSpell, ident, true, true, false, false)
            if ok and slot then
                local id = SpellIDFromBookSlot(slot, foundBank or bank)
                return id, ident
            end
        end
    end
    if SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemInfo then
        local okLines, nLines = pcall(SB.GetNumSpellBookSkillLines)
        nLines = (okLines and tonumber(nLines)) or 0
        for t = 1, nLines do
            local okTab, tab = pcall(SB.GetSpellBookSkillLineInfo, t)
            if okTab and type(tab) == "table" then
                local offset = tab.itemIndexOffset or 0
                local count = tab.numSpellBookItems or 0
                for i = offset + 1, offset + count do
                    local okInfo, info = pcall(SB.GetSpellBookItemInfo, i, bank)
                    if okInfo and type(info) == "table" and NameLooksLikeComprehendSpell(info.name) then
                        local id = tonumber(info.spellID) or tonumber(info.actionID)
                        if id then
                            RememberKnownSpell(id)
                        end
                        return id, info.name
                    end
                end
            end
        end
    end
    if GetNumSpellTabs and GetSpellTabInfo then
        local tabs = GetNumSpellTabs() or 0
        local book = BOOKTYPE_SPELL or "spell"
        for t = 1, tabs do
            local _, _, offset, count = GetSpellTabInfo(t)
            offset = offset or 0
            count = count or 0
            for i = offset + 1, offset + count do
                local name, _, sid
                if GetSpellBookItemName then
                    name, _, sid = GetSpellBookItemName(i, book)
                end
                if NameLooksLikeComprehendSpell(name) then
                    local id = tonumber(sid) or SpellIDFromIdentifier(name)
                    if id then
                        RememberKnownSpell(id)
                    end
                    return id, name
                end
            end
        end
    end
end

--- Mage spell you learn (Forever). Slot in the spellbook counts as known, even
--- when the client will not give a numeric spell ID.
function S.GetComprehendSpell()
    if comprehendSpellName and (not comprehendSpellID or KnowsSpell(comprehendSpellID)) then
        return comprehendSpellID, comprehendSpellName
    end
    if comprehendSpellID and KnowsSpell(comprehendSpellID) then
        return comprehendSpellID, comprehendSpellName or SpellName(comprehendSpellID)
    end
    comprehendSpellID = nil
    comprehendSpellName = nil

    local function Remember(id, name)
        if name and name ~= "" then
            comprehendSpellName = name
        end
        if id then
            comprehendSpellID = RememberKnownSpell(id)
        end
        if comprehendSpellID or comprehendSpellName then
            return comprehendSpellID, comprehendSpellName
        end
    end

    local id, name = FindComprehendScrollInSpellBook()
    if id or name then
        return Remember(id, name)
    end
    for i = 1, #COMPREHEND_SPELL_NAMES do
        local ident = COMPREHEND_SPELL_NAMES[i]
        id = SpellIDFromIdentifier(ident)
        if id and KnowsSpell(id) then
            return Remember(id, ident)
        end
        local SB = C_SpellBook
        if SB and SB.FindSpellBookSlotForSpell then
            local ok, slot = pcall(SB.FindSpellBookSlotForSpell, ident, true, true, false, false)
            if ok and slot then
                return Remember(id, ident)
            end
        end
    end
end

function S.GetComprehendSpellID()
    local id = S.GetComprehendSpell()
    return id
end

function S.IsComprehendSpell(spell)
    if spell == nil then
        return false
    end
    local id, name = S.GetComprehendSpell()
    if id and tonumber(spell) == id then
        return true
    end
    if type(spell) == "string" and name and spell:lower() == name:lower() then
        return true
    end
    return NameLooksLikeComprehendSpell(tostring(spell))
end

--- Known spell plus skill rank. Missing spell/skill or too-low rank: no overlay.
local function SkillRank(needles)
    local P = Professions()
    local rank = 0
    if P and P.GetSkillLineRank then
        rank = tonumber(P.GetSkillLineRank(needles)) or 0
    end
    if rank <= 0 and P and P.GetProfessionRank then
        rank = tonumber(P.GetProfessionRank(needles)) or 0
    end
    return rank
end

local function RankGate(needles, itemID)
    local rank = SkillRank(needles)
    if rank <= 0 then
        return false
    end
    local P = Professions()
    local req
    if P and P.GetItemSkillRequirement then
        req = P.GetItemSkillRequirement(itemID)
    end
    if req then
        local matches = false
        for i = 1, #needles do
            if SkillNameHas(req.skillName, needles[i]) then
                matches = true
                break
            end
        end
        if matches then
            if req.met == false then
                return false
            end
            local need = tonumber(req.required) or 0
            if need > 0 and rank < need then
                return false
            end
        end
    end
    return true
end

--- Mage spell + Comprehension secondary skill on "Requires Comprehension" scrolls.
--- No spell, no skill, or too-low rank: no glow and no extra tooltip line.
function S.IsComprehensible(itemID, hint)
    local spellID, spellName = S.GetComprehendSpell()
    local action = spellID or spellName
    if not action then
        return
    end
    local rank = SkillRank({ "comprehension", "comprehend", "compreend" })
    if rank <= 0 then
        return
    end
    local P = Professions()
    local req, ready = hint, hint ~= nil
    if not req and itemID and P and P.GetItemSkillRequirement then
        req, ready = P.GetItemSkillRequirement(itemID)
    end
    if not req and not ready then
        return
    end
    if not req or not IsComprehensionSkillName(req.skillName) then
        return
    end
    local need = tonumber(req.required) or 0
    if req.met == false or (need > 0 and rank < need) then
        return
    end
    return action, Colors.comprehensible, 1
end
AddSalvager("IsComprehensible")

function S.IsProspectable(itemID)
    local info = Data.prospectable and Data.prospectable[itemID]
    if not info then
        return
    end
    local spellID = info[1]
    if IsCamelot() then
        spellID = PROSPECTING_SPELL
    end
    if not IsPlayerSpell(spellID) then
        return
    end
    local ok = RankGate({ "jewelcrafting" }, itemID)
    if not ok then
        return
    end
    return spellID, Colors.prospectable, info[2]
end
AddSalvager("IsProspectable")

function S.IsMillable(itemID)
    local info = Data.millable and Data.millable[itemID]
    if not info then
        return
    end
    local spellID = info[1]
    if IsCamelot() then
        spellID = MILLING_SPELL
    end
    if not IsPlayerSpell(spellID) then
        return
    end
    local ok = RankGate({ "inscription" }, itemID)
    if not ok then
        return
    end
    return spellID, Colors.millable, info[2]
end
AddSalvager("IsMillable")

function S.IsCrushable(itemID)
    local info = Data.crushable and Data.crushable[itemID]
    if info and IsPlayerSpell(info[1]) then
        return info[1], Colors.crushable, info[2]
    end
end
AddSalvager("IsCrushable")

function S.IsScrappable(itemID)
    local info = Data.scrappable and Data.scrappable[itemID]
    if info and IsPlayerSpell(info[1]) then
        return info[1], Colors.scrappable, info[2]
    end
end
AddSalvager("IsScrappable")

function S.IsShatterable(itemID)
    local info = Data.shatterable and Data.shatterable[itemID]
    if info and IsPlayerSpell(info[1]) then
        return info[1], Colors.disenchantable, info[2]
    end
end
AddSalvager("IsShatterable")

function S.IsTransmutable(itemID)
    local info = Data.transmutable and Data.transmutable[itemID]
    if info and IsPlayerSpell(info[1]) then
        return info[1], Colors.transmutable, info[2]
    end
end
AddSalvager("IsTransmutable")

function S.NonDisenchantable(itemID)
    return Data.nondisenchantable and Data.nondisenchantable[itemID] and true or false
end

function S.IsDisenchantable(itemID)
    if not IsPlayerSpell(DISENCHANT_SPELL) then
        return
    end

    local eligible
    if Data.disenchantable and Data.disenchantable[itemID] then
        eligible = true
    else
        local _, _, quality, _, _, _, _, _, _, _, _, class, subClass = C_Item.GetItemInfo(itemID)
        if not quality then
            -- Item info not loaded yet — do not treat as definitive miss.
            return
        end
        if quality < MIN_DISENCHANT_QUALITY or quality > MAX_DISENCHANT_QUALITY then
            return
        elseif class ~= ITEM_CLASS_WEAPON and class ~= ITEM_CLASS_ARMOR and class ~= ITEM_CLASS_PROFESSION
            and not (class == ITEM_CLASS_GEM and ITEM_GEM_RELIC and subClass == ITEM_GEM_RELIC) then
            return
        end

        if INVTYPE_BODY then
            local invType = C_Item.GetItemInventoryTypeByID(itemID)
            if invType == INVTYPE_BODY then
                return
            end
        end

        if C_Item.IsCosmeticItem and C_Item.IsCosmeticItem(itemID) then
            return
        end
        eligible = true
    end

    if not eligible then
        return
    end

    local ok = RankGate({ "enchanting" }, itemID)
    if not ok then
        return
    end

    return DISENCHANT_SPELL, Colors.disenchantable
end
AddSalvager("IsDisenchantable")

function S.IsOpenable(itemID)
    local requiredLevel = Data.openable and Data.openable[itemID]
    if not requiredLevel then
        return
    end

    if IsPlayerSpell(1804) and requiredLevel <= UnitLevel("player") then
        return 1804, Colors.openable
    elseif IsPlayerSpell(312890) and requiredLevel <= UnitLevel("player") then
        return 312890, Colors.openable
    elseif IsPlayerSpell(323427) and requiredLevel <= 60 then
        return 323427, Colors.openable
    end
end

local function ItemInfoReadyForMissCache(itemID)
    local comprehendID, comprehendName = S.GetComprehendSpell and S.GetComprehendSpell()
    if comprehendID or comprehendName then
        -- Tooltip skill lines may arrive after item info; never miss-cache scrolls.
        return false
    end
    if not IsPlayerSpell(DISENCHANT_SPELL) then
        return true
    end
    if Data.nondisenchantable and Data.nondisenchantable[itemID] then
        return true
    end
    if Data.disenchantable and Data.disenchantable[itemID] then
        return true
    end
    local _, _, quality = C_Item.GetItemInfo(itemID)
    return quality ~= nil
end

function S.IsSalvageable(itemID, hint)
    itemID = tonumber(itemID)

    if hint then
        local spellID, color, numItems = S.IsComprehensible(itemID, hint)
        if spellID then
            if itemID then
                classifyCache[itemID] = { spellID, color, numItems }
            end
            return spellID, color, numItems
        end
    end

    if not itemID then
        return
    end

    local cached = classifyCache[itemID]
    if cached ~= nil then
        if cached == false then
            return
        end
        return cached[1], cached[2], cached[3]
    end

    for i = 1, #professionSalvagers do
        local method = professionSalvagers[i]
        local spellID, color, numItems = S[method](itemID)
        if spellID then
            classifyCache[itemID] = { spellID, color, numItems }
            return spellID, color, numItems
        end
    end

    local spellID, color = S.IsOpenable(itemID)
    if spellID then
        classifyCache[itemID] = { spellID, color }
        return spellID, color
    end

    if ItemInfoReadyForMissCache(itemID) then
        classifyCache[itemID] = false
    end
end

local function IsKeyUsable(itemID)
    local data = C_TooltipInfo and C_TooltipInfo.GetItemByID(itemID)
    if data and data.lines then
        for index = 3, #data.lines do
            local line = data.lines[index]
            if line.type == Enum.TooltipDataLineType.RestrictedSkill then
                return line.leftColor:IsRGBEqualTo(COLOR_WHITE)
            end
        end
    end

    return true
end

function S.IsOpenableProfession(itemID)
    local requiredLevel = Data.openable and Data.openable[itemID]
    if not requiredLevel or not Data.keys then
        return
    end

    local playerLevel = UnitLevel("player")
    local inv = Inv()
    for pickItemID, info in pairs(Data.keys) do
        local count = 0
        if inv and inv.GetCount then
            count = inv.GetCount(pickItemID) or 0
        elseif C_Item and C_Item.GetItemCount then
            count = C_Item.GetItemCount(pickItemID) or 0
        end
        if info[1] >= requiredLevel
            and info[2] <= playerLevel
            and count > 0
            and IsKeyUsable(pickItemID) then
            return pickItemID, Colors.openable
        end
    end
end

function S.IsBagSlotProtected(bag, slot)
    local lock = _G.FluxRespec and _G.FluxRespec.GearSetLock
    if lock and lock.IsSlotProtected then
        return lock.IsSlotProtected(bag, slot)
    end
    return false
end
