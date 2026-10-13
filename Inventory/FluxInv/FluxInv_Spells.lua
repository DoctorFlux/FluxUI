--[[
    Inventory/FluxInv/FluxInv_Spells.lua

    Spell known state, reagent usage, and create-item spells (conjure/healthstone/etc.).
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Spells = Inv.Spells or {}
local Spells = Inv.Spells

local wipe = table.wipe or wipe

local Compat = function()
    return Inv.Compat
end

-- Curated create-item spell names (cross-flavor). Matched case-insensitively.
local CREATE_ITEM_NAME_PATTERNS = {
    { pattern = "^conjure food", kind = "food" },
    { pattern = "^conjure water", kind = "water" },
    { pattern = "^conjure refreshment", kind = "refreshment" },
    { pattern = "^ritual of refreshment", kind = "refreshment" },
    -- Classic ranks: "Create Lesser Healthstone", "Create Greater Healthstone", etc.
    { pattern = "create.*healthstone", kind = "healthstone" },
    { pattern = "^create soulwell", kind = "soulwell" },
    { pattern = "^create soulstone", kind = "soulstone" },
    { pattern = "^create firestone", kind = "firestone" },
    { pattern = "^create spellstone", kind = "spellstone" },
    { pattern = "^conjure mana gem", kind = "managem" },
    { pattern = "^conjure mana sapphire", kind = "managem" },
    { pattern = "^conjure mana emerald", kind = "managem" },
    { pattern = "^conjure mana ruby", kind = "managem" },
    { pattern = "^conjure mana citrine", kind = "managem" },
    { pattern = "^conjure mana jade", kind = "managem" },
    { pattern = "^conjure mana agate", kind = "managem" },
}

-- Soul Shard is never treated as a restockable spell reagent (matched by localized name).
local SOUL_SHARD_NAME = "soul shard"

local knownCache = {} -- spellID -> bool
local reagentBySpell = {} -- spellID -> { {itemID, name?}, ... }
local spellsUsingReagent = {} -- itemID -> { spellID = true }
local allReagentItemIDs = {} -- itemID -> true (all ranks; internal/debug)
local activeReagentItemIDs = {} -- itemID -> true (max-rank only; public restock set)
local maxRankReagentSpell = {} -- spellID -> true (family winners that use reagents)
local createItemSpells = {} -- list of { spellID, name, kind, outputItemID? }
local createBySpell = {} -- spellID -> entry
-- Live name → itemID learned from bags / bank / merchant / API (no reagent catalog).
local nameToItemID = {} -- lowerName -> itemID
local pendingReagentNames = {} -- lowerName -> true (seen on spell tooltips, unresolved)
local dirty = true
local warmScheduled = false
local warmDone = false
-- Full-spellbook reagent tooltip scan is paced (not sync on every Refresh).
local reagentsDirty = true
local reagentsWarmDone = false
local reagentQueue = {}
local reagentQueueIdx = 1
local reagentWarmPending = false
local reagentWarmGen = 0
local REAGENT_SCAN_CAP = 6
local REAGENT_SCAN_INTERVAL = 0.05
-- Forward: defined after RankScore; invoked when reagent warm completes.
local FinalizeActiveReagents
local ResolvePendingReagentNames

-- Debug counters for /fluxperf and /fluxinvdebug.
local dbg = {
    coreRebuilds = 0,
    lastCoreMs = 0,
    lastCoreSpells = 0,
    lastCoreTooltips = 0,
    reagentBatches = 0,
    reagentScanned = 0,
    reagentPending = 0,
}

local scannerTip

-- Soul-currency spells teach us the localized Soul Shard name (no itemID hardcode).
local function IsSoulCurrencySpellName(spellName)
    if type(spellName) ~= "string" or spellName == "" then
        return false
    end
    local lower = spellName:lower()
    return lower:find("healthstone", 1, true)
        or lower:find("soulstone", 1, true)
        or lower:find("firestone", 1, true)
        or lower:find("spellstone", 1, true)
        or lower:find("soulwell", 1, true)
        or lower:find("ritual of souls", 1, true)
        or lower:find("ritual of summoning", 1, true)
        or lower:find("summon voidwalker", 1, true)
        or lower:find("summon succubus", 1, true)
        or lower:find("summon felhunter", 1, true)
        or lower:find("summon felguard", 1, true)
        or lower:find("summon incubus", 1, true)
        or lower:find("enslave demon", 1, true)
        or lower:find("shadowburn", 1, true)
        or lower:find("soul fire", 1, true)
end

local blacklistedReagentNames = {
    [SOUL_SHARD_NAME] = true, -- English fallback until a soul-currency spell teaches the locale name
}

local function RememberBlacklistedReagentName(name)
    if type(name) == "string" and name ~= "" then
        blacklistedReagentNames[name:lower()] = true
    end
end

local function IsSoulShardName(name)
    return type(name) == "string" and blacklistedReagentNames[name:lower()] == true
end

--- Blacklist Soul Shard only (by learned/localized name).
local function IsBlacklistedReagent(itemID, name)
    if IsSoulShardName(name) then
        return true
    end
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local itemName
    if C_Item and C_Item.GetItemNameByID then
        itemName = C_Item.GetItemNameByID(itemID)
    end
    if (not itemName or itemName == "") and GetItemInfo then
        itemName = GetItemInfo(itemID)
    end
    return IsSoulShardName(itemName)
end

function Spells.IsBlacklistedReagent(itemID)
    return IsBlacklistedReagent(itemID, nil)
end

-- Compat: empty table so old callers iterating BLACKLIST_ITEM_IDS still work.
Spells.BLACKLIST_ITEM_IDS = setmetatable({}, {
    __index = function(_, key)
        local id = tonumber(key)
        return id and IsBlacklistedReagent(id, nil) or nil
    end,
})

local function GetScanner()
    if scannerTip then
        return scannerTip
    end
    scannerTip = CreateFrame("GameTooltip", "FluxInvSpellReagentTip", UIParent, "GameTooltipTemplate")
    scannerTip:SetOwner(UIParent, "ANCHOR_NONE")
    return scannerTip
end

local function WipeTip(tip)
    local base = tip:GetName() or "FluxInvSpellReagentTip"
    for i = 1, 40 do
        local l, r = _G[base .. "TextLeft" .. i], _G[base .. "TextRight" .. i]
        if l and l.SetText then
            l:SetText("")
        end
        if r and r.SetText then
            r:SetText("")
        end
    end
end

local function RememberItemName(itemID, name)
    itemID = tonumber(itemID)
    if not itemID or not name or name == "" then
        return
    end
    if IsSoulShardName(name) then
        return
    end
    nameToItemID[name:lower()] = itemID
    if pendingReagentNames[name:lower()] then
        pendingReagentNames[name:lower()] = nil
    end
end

local function GetItemNameForID(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    if C_Item and C_Item.GetItemNameByID then
        local n = C_Item.GetItemNameByID(itemID)
        if type(n) == "string" and n ~= "" then
            return n
        end
    end
    if GetItemInfo then
        local n = GetItemInfo(itemID)
        if type(n) == "string" and n ~= "" then
            return n
        end
    end
    return nil
end

--- Learn name→ID from anything the player can see (bags / bank / merchant).
local function HarvestVisibleItemNames()
    local bags = Inv.Bags
    if bags and bags.GetUniqueItems then
        local set = bags.GetUniqueItems()
        if type(set) == "table" then
            for itemID in pairs(set) do
                itemID = tonumber(itemID)
                local name = GetItemNameForID(itemID)
                if name then
                    RememberItemName(itemID, name)
                end
            end
        end
    end
    local bank = Inv.Bank
    if bank and bank.GetCharacterCounts then
        local counts = bank.GetCharacterCounts()
        if type(counts) == "table" then
            for itemID in pairs(counts) do
                itemID = tonumber(itemID)
                local name = GetItemNameForID(itemID)
                if name then
                    RememberItemName(itemID, name)
                end
            end
        end
    end
    if GetMerchantNumItems and GetMerchantItemLink then
        local num = GetMerchantNumItems() or 0
        for i = 1, num do
            local link = GetMerchantItemLink(i)
            local itemID = link and tonumber(link:match("item:(%d+)"))
            local name
            if GetMerchantItemInfo then
                name = GetMerchantItemInfo(i)
            end
            if (not name or name == "") and itemID then
                name = GetItemNameForID(itemID)
            end
            if itemID and name then
                RememberItemName(itemID, name)
            end
        end
    end
end

--- Resolve reagent display name → itemID via live cache + game APIs (no reagent catalog).
local function GetItemIDFromName(itemName)
    if not itemName or itemName == "" then
        return nil
    end
    local trimmed = itemName:match("^%s*(.-)%s*$") or itemName
    if IsSoulShardName(trimmed) then
        return nil
    end
    local key = trimmed:lower()
    local cached = nameToItemID[key]
    if cached and not IsBlacklistedReagent(cached, trimmed) then
        return cached
    end
    if C_Item and C_Item.GetItemInfoByName then
        local itemID = tonumber(C_Item.GetItemInfoByName(trimmed))
        if itemID and not IsBlacklistedReagent(itemID, trimmed) then
            RememberItemName(itemID, trimmed)
            return itemID
        end
    end
    if GetItemInfo then
        local _, link = GetItemInfo(trimmed)
        if link then
            local itemID = tonumber(link:match("item:(%d+)"))
            if itemID and not IsBlacklistedReagent(itemID, trimmed) then
                RememberItemName(itemID, trimmed)
                return itemID
            end
        end
    end
    pendingReagentNames[key] = true
    return nil
end

local function AddReagentNamesFromText(text, dest)
    if not text or text == "" then
        return
    end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " ")
    text = text:gsub("|T.-|t", "") -- strip texture escapes
    for part in text:gmatch("[^,]+") do
        local name = part:match("^(.-)%s*%(%d+%)%s*$") or part -- "Maple Seed (1)"
        name = name:match("^%d+%s+(.+)$") or name -- "1 Maple Seed"
        name = name:match("^%s*(.-)%s*$")
        if name and name ~= "" and not name:lower():find("^requires%s") then
            local id = GetItemIDFromName(name)
            if id then
                dest[#dest + 1] = { itemID = id, name = name }
            else
                dest[#dest + 1] = { itemID = nil, name = name }
            end
        end
    end
end

--- Classic uses both "Reagents:" (Gift of the Wild) and "Requires Reagent:" (Rebirth).
--- Returns the items portion of the line, or nil if not a reagent line.
local function ExtractReagentItemsFromLine(lineText)
    if type(lineText) ~= "string" or lineText == "" then
        return nil
    end
    local cleaned = lineText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " "):gsub("|T.-|t", "")
    cleaned = cleaned:match("^%s*(.-)%s*$") or cleaned

    -- Requires Reagent(s): Maple Seed (1)
    local items = cleaned:match("^[Rr]equires%s+[Rr]eagents?%s*:%s*(.+)$")
    if items then
        return items
    end
    -- Reagent(s): Wild Thornroot
    items = cleaned:match("^[Rr]eagents?%s*:%s*(.+)$")
    if items then
        return items
    end

    -- Localized REAGENTS global (may be plural or singular depending on client).
    local reagentLabel = REAGENTS or "Reagents"
    if type(reagentLabel) == "string" and reagentLabel ~= "" then
        local escaped = reagentLabel:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        items = cleaned:match("^" .. escaped .. "%s*:%s*(.+)$")
        if items then
            return items
        end
        items = cleaned:match("^[Rr]equires%s+" .. escaped .. "%s*:%s*(.+)$")
        if items then
            return items
        end
    end
    return nil
end

--- End of a reagent section (not the reagent line itself).
local function IsReagentSectionEndLine(lineText)
    if type(lineText) ~= "string" then
        return true
    end
    if lineText:match("^%s*$") then
        return true
    end
    if ExtractReagentItemsFromLine(lineText) then
        return false
    end
    local lower = lineText:lower()
    if lower:find("^cast") then
        return true
    end
    if lower:find("^requires%s+level") then
        return true
    end
    -- Other "Requires …" lines (gear, skill) end the section; reagent lines already handled.
    if lower:find("^requires%s") then
        return true
    end
    return false
end

local function CollectReagentsFromTooltipData(data, reagents)
    if type(data) ~= "table" then
        return
    end
    local lines = data.lines
    if type(lines) ~= "table" then
        return
    end
    local inSection = false
    local function IsSecret(v)
        if scrubsecretvalues then
            local cleaned = scrubsecretvalues(v)
            -- scrubsecretvalues replaces secrets with nil; identical non-secret returns same.
            if cleaned == nil and v ~= nil then
                return true
            end
            return false
        end
        if issecretvalue and issecretvalue(v) then
            return true
        end
        if canaccessvalue and not canaccessvalue(v) then
            return true
        end
        return false
    end
    local function RawIsUsable(raw)
        if type(raw) ~= "string" then
            return false
        end
        if scrubsecretvalues then
            raw = scrubsecretvalues(raw)
            if type(raw) ~= "string" or raw == "" then
                return false
            end
            return raw
        end
        if IsSecret(raw) then
            return false
        end
        local ok, nonempty = pcall(function()
            return raw ~= ""
        end)
        if not (ok and nonempty) then
            return false
        end
        return raw
    end
    for i = 1, #lines do
        local line = lines[i]
        if type(line) == "table" then
            local raw = RawIsUsable(line.leftText or line.text)
            if raw then
                for id in raw:gmatch("item:(%d+)") do
                    local n = tonumber(id)
                    if n and not IsBlacklistedReagent(n) then
                        reagents[#reagents + 1] = { itemID = n }
                    end
                end
                local args = line.args
                if type(args) == "table" then
                    for _, arg in ipairs(args) do
                        if type(arg) == "table" and arg.itemID and not IsSecret(arg.itemID) then
                            local n = tonumber(arg.itemID)
                            if n and not IsBlacklistedReagent(n) then
                                reagents[#reagents + 1] = { itemID = n }
                            end
                        end
                    end
                end
                local lineText = raw:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " ")
                local itemsPart = ExtractReagentItemsFromLine(lineText)
                if itemsPart then
                    inSection = true
                    if itemsPart ~= "" then
                        AddReagentNamesFromText(itemsPart, reagents)
                    end
                elseif inSection then
                    if IsReagentSectionEndLine(lineText) then
                        inSection = false
                    else
                        AddReagentNamesFromText(lineText, reagents)
                    end
                end
            elseif type(line.args) == "table" then
                -- Secret leftText: still harvest structured itemID args when accessible.
                for _, arg in ipairs(line.args) do
                    if type(arg) == "table" and arg.itemID and not IsSecret(arg.itemID) then
                        local n = tonumber(arg.itemID)
                        if n and not IsBlacklistedReagent(n) then
                            reagents[#reagents + 1] = { itemID = n }
                        end
                    end
                end
            end
        end
    end
end

local function CollectReagentsFromTooltip(spellID)
    local reagents = {}
    local createsItemID

    -- Prefer structured tooltip data when available (retail).
    if C_TooltipInfo then
        local data
        if C_TooltipInfo.GetSpellByID then
            local ok, d = pcall(C_TooltipInfo.GetSpellByID, spellID)
            if ok then
                data = d
            end
        end
        if not data and C_TooltipInfo.GetSpell then
            local ok, d = pcall(C_TooltipInfo.GetSpell, spellID)
            if ok then
                data = d
            end
        end
        if data then
            CollectReagentsFromTooltipData(data, reagents)
        end
    end

    if #reagents == 0 then
        local tip = GetScanner()
        tip:ClearLines()
        WipeTip(tip)
        local ok = pcall(function()
            tip:SetSpellByID(spellID)
        end)
        if not ok then
            pcall(function()
                if tip.SetSpell then
                    tip:SetSpell(spellID)
                end
            end)
        end
        local base = tip:GetName() or "FluxInvSpellReagentTip"
        local numLines = math.min(40, math.max(0, tip:NumLines() or 0))
        local inSection = false
        local function LineTextUsable(raw)
            if type(raw) ~= "string" then
                return nil
            end
            if scrubsecretvalues then
                raw = scrubsecretvalues(raw)
            elseif issecretvalue and issecretvalue(raw) then
                return nil
            elseif canaccessvalue and not canaccessvalue(raw) then
                return nil
            end
            if type(raw) ~= "string" or raw == "" then
                return nil
            end
            return raw
        end
        for line = 1, numLines do
            local textObj = _G[base .. "TextLeft" .. line]
            if textObj and textObj.GetText then
                local raw = LineTextUsable(textObj:GetText())
                if raw then
                    for id in raw:gmatch("item:(%d+)") do
                        local n = tonumber(id)
                        if n and not IsBlacklistedReagent(n) then
                            reagents[#reagents + 1] = { itemID = n }
                        end
                    end
                    local lineText = raw:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " ")
                    local lower = lineText:lower()
                    if lower:find("creat", 1, true) and lineText:find("item:(%d+)") then
                        createsItemID = tonumber(lineText:match("item:(%d+)")) or createsItemID
                    end
                    local itemsPart = ExtractReagentItemsFromLine(lineText)
                    if itemsPart then
                        inSection = true
                        if itemsPart ~= "" then
                            AddReagentNamesFromText(itemsPart, reagents)
                        end
                    elseif inSection then
                        if IsReagentSectionEndLine(lineText) then
                            inSection = false
                        else
                            AddReagentNamesFromText(lineText, reagents)
                        end
                    end
                end
            end
        end
    end

    for i = 1, #reagents do
        local r = reagents[i]
        if not r.itemID and r.name then
            r.itemID = GetItemIDFromName(r.name)
        end
    end

    -- Classic fallback: action-count lib already knows spellID → reagent itemID
    -- (used for bar stack counts). Prefer tooltip names; fill gaps only.
    if #reagents == 0 or (reagents[1] and not reagents[1].itemID) then
        local lib = LibStub and LibStub("LibClassicSpellActionCount-1.0", true)
        if lib and lib.GetSpellReagentItemID then
            local reagentID = lib:GetSpellReagentItemID(spellID)
            reagentID = tonumber(reagentID)
            if reagentID and not IsBlacklistedReagent(reagentID) then
                local name = GetItemNameForID(reagentID)
                if #reagents == 0 then
                    reagents[1] = { itemID = reagentID, name = name }
                elseif reagents[1] and not reagents[1].itemID then
                    reagents[1].itemID = reagentID
                    if name and not reagents[1].name then
                        reagents[1].name = name
                    end
                end
                if name then
                    RememberItemName(reagentID, name)
                end
            end
        end
    end

    return reagents, createsItemID
end

local function MatchCreateKind(spellName)
    if not spellName then
        return nil
    end
    local lower = spellName:lower()
    for _, entry in ipairs(CREATE_ITEM_NAME_PATTERNS) do
        if lower:find(entry.pattern) then
            return entry.kind
        end
    end
    return nil
end

local function ForEachKnownPlayerSpell(callback)
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
            if skillLineInfo then
                local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
                for j = skillLineInfo.itemIndexOffset + 1, skillLineInfo.itemIndexOffset + skillLineInfo.numSpellBookItems do
                    local spellInfo = C_SpellBook.GetSpellBookItemInfo(j, bank)
                    if spellInfo and (spellInfo.actionID or spellInfo.spellID) then
                        local itemType = spellInfo.itemType
                        local isFlyout = Enum and Enum.SpellBookItemType
                            and itemType == Enum.SpellBookItemType.Flyout
                        local isSpell = true
                        if Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell then
                            isSpell = (itemType == Enum.SpellBookItemType.Spell)
                        elseif type(itemType) == "string" then
                            isSpell = (itemType == "SPELL" or itemType == "Spell")
                        end
                        -- Forever ranks: actionID is the base spell, spellID is the
                        -- rank/override. Record both or a rank binding looks unknown.
                        if not isFlyout and (isSpell or spellInfo.spellID) then
                            if spellInfo.actionID then
                                callback(spellInfo.actionID)
                            end
                            if spellInfo.spellID and spellInfo.spellID ~= spellInfo.actionID then
                                callback(spellInfo.spellID)
                            end
                        end
                    end
                end
            end
        end
        return
    end
    if GetNumSpellTabs then
        for tabIndex = 1, GetNumSpellTabs() do
            local _, _, offset, numSlots = GetSpellTabInfo(tabIndex)
            for slotIndex = offset + 1, offset + numSlots do
                local spellType, spellID = GetSpellBookItemInfo(slotIndex, "spell")
                if spellType == "SPELL" and spellID then
                    callback(spellID)
                end
            end
        end
    end
end

--- True when the spell name is a create/conjure candidate worth a tooltip parse.
local function IsCreateTooltipCandidate(name)
    if MatchCreateKind(name) then
        return true
    end
    if not name or name == "" then
        return false
    end
    local lower = name:lower()
    -- Broad name filter keeps tooltip work tiny vs scanning the entire spellbook.
    return lower:find("conjure", 1, true) ~= nil or lower:find("create", 1, true) ~= nil
end

local function IngestReagents(spellID, reagents)
    if not reagents or #reagents == 0 then
        return
    end
    reagentBySpell[spellID] = reagents
    local spellName = Compat().GetSpellName and Compat().GetSpellName(spellID)
    local learnSoulShard = IsSoulCurrencySpellName(spellName)
    for _, r in ipairs(reagents) do
        if learnSoulShard and r.name then
            RememberBlacklistedReagentName(r.name)
        end
        if r.itemID and not IsBlacklistedReagent(r.itemID, r.name) then
            allReagentItemIDs[r.itemID] = true
            spellsUsingReagent[r.itemID] = spellsUsingReagent[r.itemID] or {}
            spellsUsingReagent[r.itemID][spellID] = true
            if r.name then
                RememberItemName(r.itemID, r.name)
            end
        elseif r.name and not r.itemID then
            if learnSoulShard then
                -- Soul Shard: keep blacklisted, never restock.
            else
                pendingReagentNames[r.name:lower()] = true
            end
        end
    end
end

--- Cheap path: known cache + create/conjure spells only (tooltip for those few).
--- Full reagent mapping for the rest of the spellbook is paced via ScheduleReagentWarm.
local function rebuildCore()
    local t0 = (debugprofilestop and debugprofilestop()) or 0
    wipe(knownCache)
    wipe(reagentBySpell)
    wipe(spellsUsingReagent)
    wipe(allReagentItemIDs)
    wipe(activeReagentItemIDs)
    wipe(maxRankReagentSpell)
    wipe(createItemSpells)
    wipe(createBySpell)

    local pending = {}
    local spellCount, tipCount = 0, 0

    ForEachKnownPlayerSpell(function(spellID)
        knownCache[spellID] = true
        spellCount = spellCount + 1
        local name = Compat().GetSpellName(spellID)
        if IsCreateTooltipCandidate(name) then
            tipCount = tipCount + 1
            local reagents, tipCreates = CollectReagentsFromTooltip(spellID)
            IngestReagents(spellID, reagents)
            local kind = MatchCreateKind(name)
            if kind or tipCreates then
                local entry = {
                    spellID = spellID,
                    name = name,
                    kind = kind or "create",
                    outputItemID = tipCreates,
                    usesReagents = reagents and #reagents > 0 or false,
                }
                createItemSpells[#createItemSpells + 1] = entry
                createBySpell[spellID] = entry
            end
        else
            pending[#pending + 1] = spellID
        end
    end)

    reagentWarmGen = reagentWarmGen + 1
    reagentQueue = pending
    reagentQueueIdx = 1
    reagentsDirty = #pending > 0
    reagentsWarmDone = not reagentsDirty
    reagentWarmPending = false
    dbg.reagentPending = #pending
    dbg.reagentScanned = tipCount
    dirty = false
    warmDone = true

    local t1 = (debugprofilestop and debugprofilestop()) or t0
    dbg.coreRebuilds = dbg.coreRebuilds + 1
    dbg.lastCoreMs = t1 - t0
    dbg.lastCoreSpells = spellCount
    dbg.lastCoreTooltips = tipCount

    -- No pending spellbook scan: finalize now (create-spell reagents already ingested).
    if reagentsWarmDone then
        FinalizeActiveReagents(true)
    end
end

local function processReagentBatch(gen)
    if gen ~= reagentWarmGen then
        -- Stale batch after Invalidate/rebuildCore; a newer warm owns the queue.
        return
    end
    reagentWarmPending = false
    if not reagentsDirty then
        reagentsWarmDone = true
        dbg.reagentPending = 0
        FinalizeActiveReagents(true)
        return
    end
    local n = 0
    while n < REAGENT_SCAN_CAP and reagentQueueIdx <= #reagentQueue do
        local spellID = reagentQueue[reagentQueueIdx]
        reagentQueueIdx = reagentQueueIdx + 1
        if spellID and knownCache[spellID] and not reagentBySpell[spellID] then
            local reagents = CollectReagentsFromTooltip(spellID)
            IngestReagents(spellID, reagents)
            n = n + 1
            dbg.reagentScanned = dbg.reagentScanned + 1
        end
    end
    dbg.reagentBatches = dbg.reagentBatches + 1
    dbg.reagentPending = math.max(0, #reagentQueue - reagentQueueIdx + 1)
    if reagentQueueIdx <= #reagentQueue then
        reagentWarmPending = true
        Compat().After(REAGENT_SCAN_INTERVAL, function()
            processReagentBatch(gen)
        end)
    else
        reagentsDirty = false
        reagentsWarmDone = true
        wipe(reagentQueue)
        reagentQueueIdx = 1
        dbg.reagentPending = 0
        FinalizeActiveReagents(true)
    end
end

function Spells.ScheduleReagentWarm()
    if reagentWarmPending then
        return
    end
    if not reagentsDirty or reagentsWarmDone then
        return
    end
    if #reagentQueue == 0 then
        reagentsDirty = false
        reagentsWarmDone = true
        FinalizeActiveReagents(true)
        return
    end
    local gen = reagentWarmGen
    reagentWarmPending = true
    Compat().After(REAGENT_SCAN_INTERVAL, function()
        processReagentBatch(gen)
    end)
end

function Spells.Invalidate()
    dirty = true
    warmDone = false
    reagentsDirty = true
    reagentsWarmDone = false
end

function Spells.Refresh()
    if dirty then
        rebuildCore()
        Spells.ScheduleReagentWarm()
    end
    return true
end

function Spells.ScheduleWarm()
    if warmScheduled then
        return
    end
    -- Login PEW already pulses spells; do not force a second full invalidate.
    if warmDone and not dirty and (reagentsWarmDone or reagentWarmPending) then
        return
    end
    warmScheduled = true
    Compat().After(1.5, function()
        warmScheduled = false
        local pulsed = false
        if dirty then
            Spells.Refresh()
            pulsed = true
            if Inv.Events then
                Inv.Events.Pulse("scan", { "spells" })
            end
        end
        if not pulsed then
            Spells.ScheduleReagentWarm()
        end
    end)
end

function Spells.IsWarmed()
    return warmDone and not dirty
end

function Spells.AreReagentsWarmed()
    return reagentsWarmDone and not reagentsDirty
end

--- Snapshot for /fluxperf and /fluxinvdebug stuck.
function Spells.GetDebugStats()
    local activeCount, allCount = 0, 0
    for _ in pairs(activeReagentItemIDs) do
        activeCount = activeCount + 1
    end
    for _ in pairs(allReagentItemIDs) do
        allCount = allCount + 1
    end
    return {
        dirty = dirty,
        warmDone = warmDone,
        reagentsDirty = reagentsDirty,
        reagentsWarmDone = reagentsWarmDone,
        reagentWarmPending = reagentWarmPending,
        coreRebuilds = dbg.coreRebuilds,
        lastCoreMs = dbg.lastCoreMs,
        lastCoreSpells = dbg.lastCoreSpells,
        lastCoreTooltips = dbg.lastCoreTooltips,
        reagentBatches = dbg.reagentBatches,
        reagentScanned = dbg.reagentScanned,
        reagentPending = dbg.reagentPending,
        createCount = #createItemSpells,
        activeReagentCount = activeCount,
        allReagentCount = allCount,
    }
end

function Spells.IsKnown(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return false
    end
    -- Live check preferred
    if Compat().IsSpellKnown(spellID) then
        return true
    end
    Spells.Refresh()
    return knownCache[spellID] == true
end

--- Classic "Rank N" from subtext (0 when unranked / unavailable).
local function GetSpellRankNumber(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return 0
    end
    local subtext
    if C_Spell and C_Spell.GetSpellSubtext then
        subtext = C_Spell.GetSpellSubtext(spellID)
    elseif GetSpellSubtext then
        subtext = GetSpellSubtext(spellID)
    end
    if type(subtext) == "string" and subtext ~= "" then
        local rankNum = tonumber(subtext:match("[Rr]ank%s*(%d+)"))
        if rankNum then
            return rankNum
        end
    end
    -- Some Classic tooltips embed rank in the name: "Conjure Food (Rank 5)"
    local name = Compat().GetSpellName and Compat().GetSpellName(spellID)
    if type(name) == "string" and name ~= "" then
        local rankNum = tonumber(name:match("%(%s*[Rr]ank%s*(%d+)%s*%)"))
        if rankNum then
            return rankNum
        end
    end
    return 0
end

--- Prefer higher Rank N; spellID breaks ties (newer IDs ≈ higher ranks when unranked).
local function RankScore(spellID)
    spellID = tonumber(spellID) or 0
    return GetSpellRankNumber(spellID) * 1000000 + spellID
end

--- Strip trailing "(Rank N)" so Classic ranks share one family key.
local function GetSpellBaseNameKey(spellID)
    local name = Compat().GetSpellName and Compat().GetSpellName(spellID)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    local base = name:gsub("%s*%(%s*[Rr]ank%s*%d+%s*%)%s*$", "")
    base = base:match("^%s*(.-)%s*$") or base
    if base == "" then
        return nil
    end
    return base:lower()
end

--- Fill missing reagent itemIDs from the live name cache / APIs.
ResolvePendingReagentNames = function()
    HarvestVisibleItemNames()
    local changed = false
    for spellID, reagents in pairs(reagentBySpell) do
        if type(reagents) == "table" then
            for i = 1, #reagents do
                local r = reagents[i]
                if type(r) == "table" then
                    if not r.itemID and r.name then
                        local id = GetItemIDFromName(r.name)
                        if id then
                            r.itemID = id
                            if not IsBlacklistedReagent(id, r.name) then
                                allReagentItemIDs[id] = true
                                spellsUsingReagent[id] = spellsUsingReagent[id] or {}
                                spellsUsingReagent[id][spellID] = true
                            end
                            changed = true
                        end
                    elseif r.itemID and r.name then
                        RememberItemName(r.itemID, r.name)
                    end
                end
            end
        end
    end
    return changed
end

--- Keep only max-rank reagents per spell-name family in the public restock set.
--- When runMigration is true, notify Restock to transfer qty / junk superseded reagents.
FinalizeActiveReagents = function(runMigration)
    ResolvePendingReagentNames()

    wipe(activeReagentItemIDs)
    wipe(maxRankReagentSpell)

    local families = {} -- baseKey -> { bestID, bestScore, spells = { spellID, ... } }
    for spellID, reagents in pairs(reagentBySpell) do
        if type(reagents) == "table" and #reagents > 0 then
            local baseKey = GetSpellBaseNameKey(spellID)
            if baseKey then
                local fam = families[baseKey]
                if not fam then
                    fam = { bestID = spellID, bestScore = RankScore(spellID), spells = { spellID } }
                    families[baseKey] = fam
                else
                    fam.spells[#fam.spells + 1] = spellID
                    local score = RankScore(spellID)
                    if score > fam.bestScore then
                        fam.bestScore = score
                        fam.bestID = spellID
                    end
                end
            end
        end
    end

    -- Pass 1: active reagents = union of max-rank reagents across all families.
    for _, fam in pairs(families) do
        maxRankReagentSpell[fam.bestID] = true
        local bestReagents = reagentBySpell[fam.bestID]
        if bestReagents then
            for i = 1, #bestReagents do
                local itemID = bestReagents[i] and tonumber(bestReagents[i].itemID)
                if itemID and not IsBlacklistedReagent(itemID) then
                    activeReagentItemIDs[itemID] = true
                end
            end
        end
    end

    -- Pass 2: per-family obsolete = lower-rank reagents not used by any max-rank spell.
    local migrations = {}
    for baseKey, fam in pairs(families) do
        local activeList = {}
        local bestReagents = reagentBySpell[fam.bestID]
        if bestReagents then
            local seen = {}
            for i = 1, #bestReagents do
                local itemID = bestReagents[i] and tonumber(bestReagents[i].itemID)
                if itemID and not IsBlacklistedReagent(itemID) and not seen[itemID] then
                    seen[itemID] = true
                    activeList[#activeList + 1] = itemID
                end
            end
        end

        local obsoleteSet = {}
        local hasObsolete = false
        for i = 1, #fam.spells do
            local spellID = fam.spells[i]
            if spellID ~= fam.bestID then
                local rs = reagentBySpell[spellID]
                if rs then
                    for j = 1, #rs do
                        local itemID = rs[j] and tonumber(rs[j].itemID)
                        if itemID and not IsBlacklistedReagent(itemID)
                            and not activeReagentItemIDs[itemID] then
                            obsoleteSet[itemID] = true
                            hasObsolete = true
                        end
                    end
                end
            end
        end

        if hasObsolete then
            migrations[#migrations + 1] = {
                family = baseKey,
                maxSpellID = fam.bestID,
                activeIDs = activeList,
                obsoleteIDs = obsoleteSet,
            }
        end
    end

    if runMigration then
        local List = _G.FluxRestockList
        if List and List.OnActiveReagentsFinalized then
            pcall(List.OnActiveReagentsFinalized, migrations)
        end
    end
end

--- Bags / bank / merchant changed: resolve pending tooltip reagent names → itemIDs.
function Spells.OnVisibleItemsChanged()
    local changed = ResolvePendingReagentNames()
    if changed and reagentsWarmDone then
        FinalizeActiveReagents(true)
        return true
    end
    return changed
end

function Spells.IsKnownByName(name)
    if not name or name == "" then
        return false
    end
    local lower = name:lower()
    Spells.Refresh()
    -- pairs(knownCache) is unordered — must pick highest rank, not first hit
    -- (Conjure Food/Water, etc. share one name across Rank 1..N).
    local bestID, bestScore = nil, -1
    for spellID in pairs(knownCache) do
        local sn = Compat().GetSpellName(spellID)
        if sn and sn:lower() == lower then
            local score = RankScore(spellID)
            if score > bestScore then
                bestScore = score
                bestID = spellID
            end
        end
    end
    if bestID then
        return true, bestID
    end
    -- Fallback: GetSpellInfo by name then IsSpellKnown
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, name)
        if ok and type(info) == "table" and info.spellID and Compat().IsSpellKnown(info.spellID) then
            return true, info.spellID
        end
    end
    if GetSpellInfo then
        local results = { pcall(GetSpellInfo, name) }
        if results[1] then
            local spellID = results[8] or results[7]
            if spellID and Compat().IsSpellKnown(spellID) then
                return true, spellID
            end
        end
    end
    return false
end

function Spells.UsesReagents(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return false
    end
    Spells.Refresh()
    local r = reagentBySpell[spellID]
    if r and #r > 0 then
        return true
    end
    return Compat().GetSpellCastCount(spellID) > 0 and Spells.IsKnown(spellID)
end

function Spells.GetReagents(spellID)
    spellID = tonumber(spellID)
    Spells.Refresh()
    return reagentBySpell[spellID]
end

function Spells.GetCastCount(spellID)
    return Compat().GetSpellCastCount(spellID)
end

function Spells.GetReagentItemIDs()
    Spells.Refresh()
    local out = {}
    local src = reagentsWarmDone and activeReagentItemIDs or allReagentItemIDs
    for id in pairs(src) do
        if not IsBlacklistedReagent(id) then
            out[#out + 1] = id
        end
    end
    return out
end

--- Set of reagent itemIDs from max-rank known spells (active restock set).
function Spells.GetReagentItemIDSet()
    Spells.Refresh()
    local out = {}
    local src = reagentsWarmDone and activeReagentItemIDs or allReagentItemIDs
    for id in pairs(src) do
        if not IsBlacklistedReagent(id) then
            out[id] = true
        end
    end
    return out
end

function Spells.IsReagentItem(itemID)
    itemID = tonumber(itemID)
    if not itemID or IsBlacklistedReagent(itemID) then
        return false
    end
    Spells.Refresh()
    if reagentsWarmDone then
        return activeReagentItemIDs[itemID] == true
    end
    return allReagentItemIDs[itemID] == true
end

--- Display label for tooltips: "Rebirth (Rank 5)" (rank from subtext when name is bare).
local function FormatSpellReagentLabel(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return "Spell"
    end
    local name = Compat().GetSpellName and Compat().GetSpellName(spellID)
    if type(name) ~= "string" or name == "" then
        return "Spell " .. spellID
    end
    local base = name:gsub("%s*%(%s*[Rr]ank%s*%d+%s*%)%s*$", "")
    base = base:match("^%s*(.-)%s*$") or base
    local rankNum = GetSpellRankNumber(spellID)
    if rankNum and rankNum > 0 then
        return string.format("%s (Rank %d)", base, rankNum)
    end
    local subtext
    if C_Spell and C_Spell.GetSpellSubtext then
        subtext = C_Spell.GetSpellSubtext(spellID)
    elseif GetSpellSubtext then
        subtext = GetSpellSubtext(spellID)
    end
    if type(subtext) == "string" and subtext ~= "" then
        local lower = subtext:lower()
        if not lower:find("^rank%s*%d") then
            return base .. " (" .. subtext .. ")"
        end
    end
    return base
end

function Spells.GetSpellsUsingReagent(itemID)
    itemID = tonumber(itemID)
    Spells.Refresh()
    local set = spellsUsingReagent[itemID]
    if not set then
        return {}
    end
    local out = {}
    for spellID in pairs(set) do
        -- Prefer max-rank family winners once warm is complete.
        if not reagentsWarmDone or maxRankReagentSpell[spellID] then
            out[#out + 1] = spellID
        end
    end
    -- Obsolete reagents: no max-rank spell uses them — still list lower ranks.
    if #out == 0 and reagentsWarmDone then
        for spellID in pairs(set) do
            out[#out + 1] = spellID
        end
    end
    table.sort(out, function(a, b)
        return RankScore(a) > RankScore(b)
    end)
    return out
end

--- Labeled rows for tooltips / Restock UI: { { spellID, label, rank }, ... }
--- Sorted highest rank first. Labels include Rank N when available.
function Spells.GetSpellsUsingReagentLabeled(itemID)
    itemID = tonumber(itemID)
    Spells.Refresh()
    local set = spellsUsingReagent[itemID]
    if not set then
        return {}
    end
    local out = {}
    local function addSpell(spellID)
        local rank = GetSpellRankNumber(spellID)
        out[#out + 1] = {
            spellID = spellID,
            rank = rank,
            label = FormatSpellReagentLabel(spellID),
        }
    end
    for spellID in pairs(set) do
        if not reagentsWarmDone or maxRankReagentSpell[spellID] then
            addSpell(spellID)
        end
    end
    if #out == 0 and reagentsWarmDone then
        for spellID in pairs(set) do
            addSpell(spellID)
        end
    end
    table.sort(out, function(a, b)
        local ra, rb = a.rank or 0, b.rank or 0
        if ra ~= rb then
            return ra > rb
        end
        return (a.label or ""):lower() < (b.label or ""):lower()
    end)
    return out
end

function Spells.CreatesItem(spellID)
    spellID = tonumber(spellID)
    Spells.Refresh()
    local entry = createBySpell[spellID]
    if entry then
        return entry.outputItemID, entry.kind, entry
    end
    return nil
end

function Spells.GetCreateItemSpells(kindFilter)
    Spells.Refresh()
    if not kindFilter then
        return createItemSpells
    end
    local out = {}
    for _, entry in ipairs(createItemSpells) do
        if entry.kind == kindFilter then
            out[#out + 1] = entry
        end
    end
    return out
end

function Spells.HasCreateKind(kind)
    Spells.Refresh()
    -- Spellbook order is not max-rank order; pick highest Rank N / spellID.
    local bestID, bestScore = nil, -1
    for _, entry in ipairs(createItemSpells) do
        if entry.kind == kind and entry.spellID and Spells.IsKnown(entry.spellID) then
            -- Ritual shares kind "refreshment" with Conjure Refreshment — never
            -- treat Ritual as the preferred create for that kind.
            local entryName = entry.name and entry.name:lower() or ""
            if kind == "refreshment" and entryName:find("ritual", 1, true) then
                -- skip
            else
                local score = RankScore(entry.spellID)
                if score > bestScore then
                    bestScore = score
                    bestID = entry.spellID
                end
            end
        end
    end
    if bestID then
        return true, bestID
    end
    if kind == "healthstone" then
        local spellID = Spells.GetPreferredCreateSpell("healthstone")
        if spellID then
            return true, spellID
        end
    end
    return false
end

local MANA_GEM_SPELL_RANK = {
    ["conjure mana gem"] = 100,
    ["conjure mana sapphire"] = 90,
    ["conjure mana emerald"] = 80,
    ["conjure mana ruby"] = 70,
    ["conjure mana citrine"] = 60,
    ["conjure mana jade"] = 50,
    ["conjure mana agate"] = 40,
}

local MANA_GEM_CHARGE_SPELL = {
    ["conjure mana gem"] = true,
    ["conjure mana sapphire"] = true,
    ["conjure mana emerald"] = true,
}

--- Highest known create spell for kind (mana gem / healthstone / food / water).
function Spells.GetPreferredCreateSpell(kind)
    local list = Spells.GetCreateItemSpells(kind)
    local bestID, bestName, bestRank = nil, nil, -1
    local Bridge = _G.FluxEBSConsumableBridge
    local chargeOnly = kind == "managem" and Bridge and Bridge.ShouldUseChargeBasedManaGemOnly
        and Bridge.ShouldUseChargeBasedManaGemOnly()
    for i = 1, #list do
        local entry = list[i]
        local spellID = entry.spellID
        if spellID and Spells.IsKnown(spellID) then
            local name = entry.name
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(spellID)
                name = (info and info.name) or name
            elseif GetSpellInfo then
                name = GetSpellInfo(spellID) or name
            end
            local rank = RankScore(spellID)
            if kind == "managem" and name then
                local lower = name:lower()
                if chargeOnly and not MANA_GEM_CHARGE_SPELL[lower] then
                    rank = -1
                else
                    -- Named gem tiers outrank bare RankScore when present.
                    rank = (MANA_GEM_SPELL_RANK[lower] or 0) * 1000000 + (tonumber(spellID) or 0)
                end
            elseif kind == "refreshment" and name then
                -- Ritual is secondary (ctrl/shift), not the preferred group conjure.
                if name:lower():find("ritual", 1, true) then
                    rank = -1
                end
            end
            if rank > bestRank then
                bestRank = rank
                bestID = spellID
                bestName = name
            end
        end
    end
    if bestID then
        return bestID, bestName
    end
    -- Fallback name scan (Classic ranks not yet in createItemSpells).
    if kind == "managem" then
        local FALLBACKS = {
            "Conjure Mana Gem",
            "Conjure Mana Sapphire",
            "Conjure Mana Emerald",
            "Conjure Mana Ruby",
            "Conjure Mana Citrine",
            "Conjure Mana Jade",
            "Conjure Mana Agate",
        }
        for i = 1, #FALLBACKS do
            local lower = FALLBACKS[i]:lower()
            if chargeOnly and not MANA_GEM_CHARGE_SPELL[lower] then
                -- skip
            else
                local known, spellID = Spells.IsKnownByName(FALLBACKS[i])
                if known then
                    return spellID, FALLBACKS[i]
                end
            end
        end
    end
    if kind == "healthstone" then
        local FALLBACKS = {
            "Create Fel Healthstone",
            "Create Master Healthstone",
            "Create Major Healthstone",
            "Create Greater Healthstone",
            "Create Healthstone",
            "Create Healthstone (Major)",
            "Create Healthstone (Greater)",
            "Create Healthstone (Lesser)",
            "Create Healthstone (Minor)",
            "Create Lesser Healthstone",
            "Create Minor Healthstone",
        }
        for i = 1, #FALLBACKS do
            local known, spellID = Spells.IsKnownByName(FALLBACKS[i])
            if known then
                return spellID, FALLBACKS[i]
            end
        end
    end
    return nil, nil
end

-- ---------------------------------------------------------------------------
-- Mage conjure helpers (trade UI / ExtraButtons consumers)
-- ---------------------------------------------------------------------------

--- Resolve a known conjure spell to (localizedName, spellID). Never invents English
--- cast strings from HasCreateKind alone — that broke cold-login /cast Food.
local function ResolveKnownConjure(englishName)
    local known, spellID = Spells.IsKnownByName(englishName)
    if not known or not spellID then
        return nil, nil
    end
    local name = Compat().GetSpellName and Compat().GetSpellName(spellID)
    if (not name or name == "") and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        name = info and info.name
    end
    if (not name or name == "") and GetSpellInfo then
        name = GetSpellInfo(spellID)
    end
    return name or englishName, spellID
end

local function ResolveCreateKindConjure(kind)
    local has, spellID = Spells.HasCreateKind(kind)
    if not has or not spellID then
        return nil, nil
    end
    local name = Compat().GetSpellName and Compat().GetSpellName(spellID)
    if (not name or name == "") and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        name = info and info.name
    end
    if (not name or name == "") and GetSpellInfo then
        name = GetSpellInfo(spellID)
    end
    -- Prefer a non-nil first return so single-value callers stay truthy; cast path uses spellID.
    return name or tostring(spellID), spellID
end

--- Resolve create-kind to (localizedName, spellID) via max-rank create picker.
local function ResolvePreferredCreateKind(kind)
    local spellID, name = Spells.GetPreferredCreateSpell(kind)
    if not spellID then
        return nil, nil
    end
    if not name or name == "" then
        name = Compat().GetSpellName and Compat().GetSpellName(spellID)
    end
    if (not name or name == "") and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        name = info and info.name
    end
    if (not name or name == "") and GetSpellInfo then
        name = GetSpellInfo(spellID)
    end
    return name or tostring(spellID), spellID
end

function Spells.HasConjureFood()
    return Spells.IsKnownByName("Conjure Food") and true or false
end

function Spells.HasConjureWater()
    return Spells.IsKnownByName("Conjure Water") and true or false
end

function Spells.HasConjureRefreshment()
    return Spells.IsKnownByName("Conjure Refreshment") and true or false
end

function Spells.HasRitualOfRefreshment()
    return Spells.IsKnownByName("Ritual of Refreshment") and true or false
end

function Spells.HasAnyConjureSpell()
    return Spells.HasConjureFood()
        or Spells.HasConjureWater()
        or Spells.HasConjureRefreshment()
        or Spells.HasRitualOfRefreshment()
        or Spells.HasCreateKind("food")
        or Spells.HasCreateKind("water")
        or Spells.HasCreateKind("refreshment")
end

local function PlayerInGroup()
    if _G.IsInGroup then
        return _G.IsInGroup()
    end
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        return true
    end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return true
    end
    return false
end

function Spells.GetPreferredGroupConjureSpell()
    -- RankScore over every known refreshment create (excludes Ritual).
    local name, spellID = ResolvePreferredCreateKind("refreshment")
    if name or spellID then
        return name, spellID
    end
    name, spellID = ResolveKnownConjure("Conjure Refreshment")
    if name then
        return name, spellID
    end
    return ResolveCreateKindConjure("refreshment")
end

--- Always prefer pure Conjure Food on right-click (even in group).
--- Ritual stays on shift-right via GetSecondaryFoodConjureSpell.
--- Returns localizedName, spellID (spellID preferred for secure cast binding).
function Spells.GetPreferredFoodConjureSpell()
    -- createItemSpells path first: RankScore over every known food conjure.
    local foodName, foodID = ResolvePreferredCreateKind("food")
    if foodName or foodID then
        return foodName, foodID
    end
    foodName, foodID = ResolveKnownConjure("Conjure Food")
    if foodName or foodID then
        return foodName, foodID
    end
    foodName, foodID = ResolveCreateKindConjure("food")
    if foodName or foodID then
        return foodName, foodID
    end
    local groupName, groupID = Spells.GetPreferredGroupConjureSpell()
    if groupName or groupID then
        return groupName, groupID
    end
    return ResolveKnownConjure("Conjure Refreshment")
end

--- Always prefer pure Conjure Water on right-click (even in group).
--- Ritual stays on shift-right via GetSecondaryWaterConjureSpell.
function Spells.GetPreferredWaterConjureSpell()
    local waterName, waterID = ResolvePreferredCreateKind("water")
    if waterName or waterID then
        return waterName, waterID
    end
    waterName, waterID = ResolveKnownConjure("Conjure Water")
    if waterName or waterID then
        return waterName, waterID
    end
    waterName, waterID = ResolveCreateKindConjure("water")
    if waterName or waterID then
        return waterName, waterID
    end
    local groupName, groupID = Spells.GetPreferredGroupConjureSpell()
    if groupName or groupID then
        return groupName, groupID
    end
    return ResolveKnownConjure("Conjure Refreshment")
end

function Spells.GetSecondaryFoodConjureSpell()
    local ritualName, ritualID = ResolveKnownConjure("Ritual of Refreshment")
    if ritualName or ritualID then
        return ritualName, ritualID
    end
    local primary = Spells.GetPreferredFoodConjureSpell()
    local primaryLower = type(primary) == "string" and primary:lower() or ""
    -- When primary is pure food, offer Refreshment on shift-right.
    if primaryLower:find("food", 1, true) and not primaryLower:find("refreshment", 1, true) then
        return Spells.GetPreferredGroupConjureSpell()
    end
    -- When primary is Refreshment (no pure food), offer Food on shift-right if known.
    if primaryLower:find("refreshment", 1, true) then
        local foodName, foodID = ResolvePreferredCreateKind("food")
        if foodName or foodID then
            return foodName, foodID
        end
        foodName, foodID = ResolveKnownConjure("Conjure Food")
        if foodName or foodID then
            return foodName, foodID
        end
        return ResolveCreateKindConjure("food")
    end
    return nil, nil
end

function Spells.GetSecondaryWaterConjureSpell()
    local ritualName, ritualID = ResolveKnownConjure("Ritual of Refreshment")
    if ritualName or ritualID then
        return ritualName, ritualID
    end
    local primary = Spells.GetPreferredWaterConjureSpell()
    local primaryLower = type(primary) == "string" and primary:lower() or ""
    -- When primary is pure water, offer Refreshment on shift-right.
    if primaryLower:find("water", 1, true) and not primaryLower:find("refreshment", 1, true) then
        return Spells.GetPreferredGroupConjureSpell()
    end
    -- When primary is Refreshment (no pure water), offer Water on shift-right if known.
    if primaryLower:find("refreshment", 1, true) then
        local waterName, waterID = ResolvePreferredCreateKind("water")
        if waterName or waterID then
            return waterName, waterID
        end
        waterName, waterID = ResolveKnownConjure("Conjure Water")
        if waterName or waterID then
            return waterName, waterID
        end
        return ResolveCreateKindConjure("water")
    end
    return nil, nil
end

-- Classification cache (itemId → bool). Only store definitive results (never sticky false on missing data).
local isMountItemCache = {}

local function EnsureMountScanTooltip()
    local tip = _G.FluxInvMountScanTooltip
    if not tip then
        tip = CreateFrame("GameTooltip", "FluxInvMountScanTooltip", UIParent, "GameTooltipTemplate")
        tip:SetOwner(UIParent, "ANCHOR_NONE")
        _G.FluxInvMountScanTooltip = tip
    end
    return tip
end

local function GetMountTooltipTextLower(itemId)
    if not itemId then
        return "", false
    end
    local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local tip = EnsureMountScanTooltip()
    tip:ClearLines()
    local itemReady = getItemInfo and getItemInfo(itemId) ~= nil
    local okSet = pcall(function()
        if tip.SetItemByID then
            tip:SetItemByID(itemId)
        elseif tip.SetHyperlink then
            local link = getItemInfo and select(2, getItemInfo(itemId))
            if link then
                tip:SetHyperlink(link)
            else
                tip:SetHyperlink("item:" .. itemId)
            end
        end
    end)
    if not okSet then
        return "", false
    end
    local text = ""
    local numLines = tip:NumLines() or 0
    for i = 1, numLines do
        local left = _G["FluxInvMountScanTooltipTextLeft" .. i]
        if left then
            local line = left:GetText()
            if line and line ~= "" then
                text = text .. "\n" .. string.lower(line)
            end
        end
    end
    -- Definitive only when item info is known and tooltip has content.
    local definitive = itemReady and text ~= ""
    return text, definitive
end

--- True if itemID is a mount-use item (journal, class/subclass, or tooltip keywords).
--- Does not permanently cache false when item data / tooltip is not ready yet.
--- Explicitly excludes companion / vanity pets (same "summon and dismiss" wording as mounts).
function Spells.IsItemAMount(itemId)
    itemId = tonumber(itemId)
    if not itemId or itemId <= 0 then
        return false
    end

    local cached = isMountItemCache[itemId]
    if cached ~= nil then
        return cached
    end

    local function finish(result, definitive)
        if definitive ~= false then
            isMountItemCache[itemId] = result and true or false
        end
        return result and true or false
    end

    -- Pet journal item → never a mount.
    if C_PetJournal and C_PetJournal.GetPetInfoByItemID then
        local ok, speciesId = pcall(C_PetJournal.GetPetInfoByItemID, itemId)
        if ok and speciesId then
            return finish(false, true)
        end
    end

    if C_MountJournal and C_MountJournal.GetMountFromItem then
        local ok, mountId = pcall(C_MountJournal.GetMountFromItem, itemId)
        if ok and mountId then
            return finish(true, true)
        end
    end

    local classId, subclassId
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemId)
        classId, subclassId = classID, subclassID
    elseif GetItemInfoInstant then
        local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemId)
        classId, subclassId = classID, subclassID
    end

    local miscClass = (Enum and Enum.ItemClass and Enum.ItemClass.Miscellaneous) or 15
    local mountSub = (Enum and Enum.ItemMiscellaneousSubclass and Enum.ItemMiscellaneousSubclass.Mount) or 5
    local companionSub = (Enum and Enum.ItemMiscellaneousSubclass and Enum.ItemMiscellaneousSubclass.CompanionPet) or 2
    -- Companion / vanity pet subclass is never a mount.
    if classId == miscClass and subclassId == companionSub then
        return finish(false, true)
    end
    if classId == miscClass and subclassId == mountSub then
        return finish(true, true)
    end

    local text, definitive = GetMountTooltipTextLower(itemId)
    if not definitive and text == "" then
        return finish(false, false)
    end

    -- Companion / critter wording without mount evidence → not a mount.
    local companionHint = text:find("companion", 1, true)
        or text:find("critter", 1, true)
        or text:find("right click to summon and dismiss your", 1, true)
        or text:find("teaches you how to summon this companion", 1, true)
        or text:find("teaches you how to summon", 1, true) and text:find("pet", 1, true)
    local mountHint = text:find("mount", 1, true)
        or text:find("rideable", 1, true)
        or text:find("ridable", 1, true)
        or text:find("riding ", 1, true)
        or text:find("movement speed", 1, true)

    if companionHint and not mountHint then
        return finish(false, definitive)
    end

    -- Strong mount-only patterns.
    if text:find("very fast mount", 1, true)
        or text:find("flying mount", 1, true)
        or text:find("ground mount", 1, true)
        or text:find("rideable", 1, true)
        or text:find("ridable", 1, true)
        or (text:find("increases your movement speed", 1, true) and text:find("mount", 1, true))
    then
        return finish(true, true)
    end

    -- "Summons and dismisses" is shared by companions — require mount context.
    if (text:find("summons and dismisses", 1, true) or text:find("summon and dismiss", 1, true))
        and mountHint
        and not companionHint
    then
        return finish(true, true)
    end

    -- Only cache false when we had a definitive tooltip parse.
    return finish(false, definitive)
end

local function ConsiderMountItem(itemId, bag, slot, seen, mounts)
    itemId = tonumber(itemId)
    if not itemId or itemId <= 0 or seen[itemId] then
        return
    end
    if not Spells.IsItemAMount(itemId) then
        return
    end
    seen[itemId] = true

    local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local getItemIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    local name, _, quality, _, _, _, _, _, _, icon = getItemInfo(itemId)
    name = name or ("Item " .. tostring(itemId))
    if not icon and getItemIcon then
        icon = getItemIcon(itemId)
    end

    local qualityNum = quality
    if type(quality) == "string" then
        local qualityMap = {
            poor = 0, junk = 0, common = 1, uncommon = 2,
            rare = 3, epic = 4, legendary = 5, artifact = 6, heirloom = 7,
        }
        qualityNum = qualityMap[string.lower(quality)] or 1
    end

    mounts[#mounts + 1] = {
        itemId = itemId,
        name = name,
        icon = icon,
        quality = qualityNum or 1,
        bag = bag,
        slot = slot,
        ["$itemId"] = itemId,
        ["$name"] = name,
        ["$iconTexture"] = icon,
        ["$quality"] = qualityNum or 1,
    }
end

-- ---------------------------------------------------------------------------
-- Flying / zone-restricted mount detection (TBC / WotLK item mounts)
-- ---------------------------------------------------------------------------

-- Instance map IDs (GetInstanceInfo select 8)
local OUTLAND_INSTANCE_ID = 530
local NORTHREND_INSTANCE_ID = 571
-- Open-world continent instance IDs (not dungeons/BGs)
local EASTERN_KINGDOMS_INSTANCE_ID = 0
local KALIMDOR_INSTANCE_ID = 1
-- C_Map continent uiMapIDs (not the same as instance IDs)
local OUTLAND_UIMAP_ID = 101
local NORTHREND_UIMAP_ID = 113
local MOUNT_TRAIT_CACHE_EXPIRY = 60
local mountTraitCache = {}
local mountItemSettleUntil = 0
local mountItemSettleStartedAt = 0
local mountItemLastLocationKey = nil
local mountItemStablePolls = 0
local MOUNT_ITEM_SETTLE_MIN_SEC = 0.25
local MOUNT_ITEM_SETTLE_STABLE_POLLS = 2

local OUTLAND_NORTHREND_INSTANCE_IDS = {
    [OUTLAND_INSTANCE_ID] = true,
    [NORTHREND_INSTANCE_ID] = true,
}
local OPEN_WORLD_INSTANCE_IDS = {
    [EASTERN_KINGDOMS_INSTANCE_ID] = true,
    [KALIMDOR_INSTANCE_ID] = true,
    [OUTLAND_INSTANCE_ID] = true,
    [NORTHREND_INSTANCE_ID] = true,
}
local OUTLAND_NORTHREND_UIMAP_IDS = {
    [OUTLAND_UIMAP_ID] = true,
    [NORTHREND_UIMAP_ID] = true,
}
local RESTRICTED_INSTANCE_TYPES = {
    pvp = true,
    arena = true,
    party = true,
    raid = true,
    scenario = true,
}

-- Conservative name fallbacks only (no short ambiguous tokens like "nagrand"/"dalaran").
local OUTLAND_NORTHREND_ZONE_NAMES = {
    ["outland"] = true,
    ["northrend"] = true,
    ["hellfire peninsula"] = true,
    ["zangarmarsh"] = true,
    ["terokkar forest"] = true,
    ["blade's edge mountains"] = true,
    ["netherstorm"] = true,
    ["shadowmoon valley"] = true,
    ["borean tundra"] = true,
    ["howling fjord"] = true,
    ["dragonblight"] = true,
    ["grizzly hills"] = true,
    ["zul'drak"] = true,
    ["sholazar basin"] = true,
    ["crystalsong forest"] = true,
    ["the storm peaks"] = true,
    ["icecrown"] = true,
    ["wintergrasp"] = true,
    ["shattrath city"] = true,
}

function Spells.GetCurrentInstanceMapID()
    if GetInstanceInfo then
        local mapID = select(8, GetInstanceInfo())
        mapID = tonumber(mapID)
        if mapID and mapID > 0 then
            return mapID
        end
    end
    return nil
end

function Spells.GetCurrentContinentMapID()
    local mapID
    if C_Map and C_Map.GetBestMapForUnit then
        mapID = C_Map.GetBestMapForUnit("player")
    elseif GetCurrentMapAreaID then
        mapID = GetCurrentMapAreaID()
    end
    if not mapID or mapID == 0 then
        return nil
    end
    if not C_Map or not C_Map.GetMapInfo then
        return mapID
    end
    local mapInfo = C_Map.GetMapInfo(mapID)
    while mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0 do
        mapID = mapInfo.parentMapID
        mapInfo = C_Map.GetMapInfo(mapID)
    end
    return mapID
end

--- True if player is on Outland or Northrend continent (item usability / zone filter).
function Spells.IsOutlandOrNorthrendContinent()
    local instanceID = Spells.GetCurrentInstanceMapID()
    if instanceID then
        if OUTLAND_NORTHREND_INSTANCE_IDS[instanceID] then
            return true
        end
        -- Dungeon/BG/raid map IDs are not open-world continents. Do not walk C_Map
        -- parents up to Outland/Northrend (Eye of the Storm etc.).
        if instanceID > 1 and not OPEN_WORLD_INSTANCE_IDS[instanceID] then
            return false
        end
    end

    -- Inside any instance type: never treat as open-world continent for mount items.
    if GetInstanceInfo then
        local _, instanceType = GetInstanceInfo()
        if instanceType and RESTRICTED_INSTANCE_TYPES[instanceType] then
            return false
        end
    end
    if IsInInstance and IsInInstance() then
        return false
    end

    local mapID
    if C_Map and C_Map.GetBestMapForUnit then
        mapID = C_Map.GetBestMapForUnit("player")
    elseif GetCurrentMapAreaID then
        mapID = GetCurrentMapAreaID()
    end
    if mapID and mapID ~= 0 then
        if OUTLAND_NORTHREND_UIMAP_IDS[mapID] or OUTLAND_NORTHREND_INSTANCE_IDS[mapID] then
            return true
        end
        if C_Map and C_Map.GetMapInfo then
            local mapInfo = C_Map.GetMapInfo(mapID)
            while mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0 do
                mapID = mapInfo.parentMapID
                if OUTLAND_NORTHREND_UIMAP_IDS[mapID] then
                    return true
                end
                mapInfo = C_Map.GetMapInfo(mapID)
            end
        end
    end
    -- Last resort: long zone names only (avoid false positives after teleport).
    local zoneText = (GetZoneText and GetZoneText()) or ""
    local realZone = (GetRealZoneText and GetRealZoneText()) or ""
    local zoneLower = (zoneText .. " " .. realZone):lower()
    if zoneLower:find("outland", 1, true) or zoneLower:find("northrend", 1, true) then
        return true
    end
    for name in pairs(OUTLAND_NORTHREND_ZONE_NAMES) do
        if zoneLower:find(name, 1, true) then
            return true
        end
    end
    return false
end

--- Alias kept for legacy callers.
function Spells.IsPlayerInOutlandOrNorthrend()
    return Spells.IsOutlandOrNorthrendContinent()
end

--- Fingerprint of location inputs used by bag-mount flyable picks (no [flyable] macro).
function Spells.GetMountItemLocationKey()
    local name, instanceType, instanceMapID = "", "none", 0
    if GetInstanceInfo then
        name, instanceType = GetInstanceInfo()
        instanceMapID = select(8, GetInstanceInfo())
    end
    instanceType = instanceType or "none"
    instanceMapID = tonumber(instanceMapID) or 0
    local inInst = (IsInInstance and IsInInstance()) and 1 or 0
    local continent = Spells.IsOutlandOrNorthrendContinent() and 1 or 0
    local outdoors = (not IsOutdoors or IsOutdoors()) and 1 or 0
    local flyable = (IsFlyableArea and IsFlyableArea()) and 1 or 0
    local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
    return table.concat({
        tostring(name or ""),
        tostring(instanceType),
        tostring(instanceMapID),
        tostring(inInst),
        tostring(continent),
        tostring(outdoors),
        tostring(flyable),
        tostring(zone),
    }, "|")
end

--- Call on PEW / NEW_AREA so bag mounts default to ground until APIs settle.
function Spells.BeginMountItemLocationSettle(durationSec)
    local now = (GetTime and GetTime()) or 0
    local untilTime = now + (durationSec or 2.5)
    if untilTime > mountItemSettleUntil then
        mountItemSettleUntil = untilTime
    end
    mountItemSettleStartedAt = now
    mountItemLastLocationKey = nil
    mountItemStablePolls = 0
end

function Spells.EndMountItemLocationSettle()
    mountItemSettleUntil = 0
    mountItemStablePolls = 0
end

function Spells.IsMountItemLocationSettling()
    local now = (GetTime and GetTime()) or 0
    return now < mountItemSettleUntil
end

--- True when location key stopped changing (or settle window ended with a key).
--- Ends settle early once the key is unchanged for MOUNT_ITEM_SETTLE_STABLE_POLLS
--- consecutive polls after MOUNT_ITEM_SETTLE_MIN_SEC (safety net still expires at until).
function Spells.UpdateMountItemLocationSettle(key)
    key = key or Spells.GetMountItemLocationKey()
    local changed = key ~= mountItemLastLocationKey
    if changed then
        mountItemLastLocationKey = key
        mountItemStablePolls = 0
    else
        mountItemStablePolls = mountItemStablePolls + 1
    end

    if Spells.IsMountItemLocationSettling() then
        local now = (GetTime and GetTime()) or 0
        local elapsed = now - (mountItemSettleStartedAt or 0)
        if not changed
            and elapsed >= MOUNT_ITEM_SETTLE_MIN_SEC
            and mountItemStablePolls >= MOUNT_ITEM_SETTLE_STABLE_POLLS
        then
            Spells.EndMountItemLocationSettle()
            return key, changed, true
        end
        return key, changed, false
    end
    return key, changed, true
end

--- BGs / arenas / dungeons / raids: TBC flying mounts cannot be used here
--- even when the map parents up to Outland/Northrend (e.g. Eye of the Storm).
function Spells.IsInMountRestrictedInstance()
    if GetInstanceInfo then
        local _, instanceType, _, _, _, _, _, mapID = GetInstanceInfo()
        if instanceType and RESTRICTED_INSTANCE_TYPES[instanceType] then
            return true
        end
        mapID = tonumber(mapID) or 0
        -- Non-continent instance map IDs (dungeons, BGs, raids).
        if mapID > 1 and not OPEN_WORLD_INSTANCE_IDS[mapID] then
            return true
        end
    end
    if IsInInstance and IsInInstance() then
        return true
    end
    return false
end

--- Smart flying vs ground preference — matches Blizzard [flyable] macros.
--- Journal / configured mounts use this (secure macros use [flyable]).
function Spells.IsFlyableHere()
    if IsFlyableArea and IsFlyableArea() then
        return true
    end
    return false
end

--- Bag mount items (Classic Era / TBC): only prefer flying in open-world
--- Outland/Northrend when the area is actually flyable. Never in BGs,
--- arenas, dungeons, or raids. Clients without [flyable] macros rely on this.
--- During settle: prefer ground only while flyable is false/uncertain; if
--- IsFlyableArea is already true, switch to flying immediately.
function Spells.CanPreferFlyingMountItem()
    if Spells.IsInMountRestrictedInstance() then
        return false
    end
    local api = _G.FLUX_API
    local useContinent = not api or api.isTBC or api.isWrath or api.isClassicEra
    local flyableNow = IsFlyableArea and IsFlyableArea() or false

    if Spells.IsMountItemLocationSettling() then
        -- Trust a positive flyable reading during settle; force ground only when
        -- the API still says not flyable (map lag after teleport).
        if not flyableNow then
            return false
        end
    end

    if useContinent then
        if not Spells.IsOutlandOrNorthrendContinent() then
            return false
        end
        -- Trust IsFlyableArea when present. Previously we returned true for any
        -- outdoors Outland/Northrend subzone (Telredor workaround), which cast
        -- flying mounts in non-flyable outdoor areas on bag-item clients.
        return flyableNow and true or false
    end
    return Spells.IsFlyableHere()
end

local function GetMountTraits(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false, false, true
    end
    local now = GetTime and GetTime() or 0
    local entry = mountTraitCache[itemId]
    if entry and (now - entry.timestamp) < MOUNT_TRAIT_CACHE_EXPIRY then
        return entry.isFlying, entry.isZoneRestricted, false
    end
    local text = select(1, GetMountTooltipTextLower(itemId))
    -- Empty/partial tooltip after zone/cache wipe: keep mounts usable in the list.
    -- Do NOT treat unknown as flying (that emptied the button after dungeon exits).
    if not text or #text < 24 then
        return false, false, true
    end
    local isFlying = false
    -- Do not treat bare "riding 150" as flying (epic ground mounts also require 150).
    if text:find("riding 225", 1, true)
        or text:find("riding 300", 1, true)
        or text:find("flying mount", 1, true)
    then
        isFlying = true
    end
    local isZoneRestricted = false
    local hasOutlandOrNorthrend = text:find("outland", 1, true) or text:find("northrend", 1, true)
    if hasOutlandOrNorthrend then
        local summonRestrict = text:find("can only be summoned", 1, true)
            or text:find("only be summoned", 1, true)
            or text:find("summoned in", 1, true)
            or text:find("summoned outland", 1, true)
            or text:find("summoned northrend", 1, true)
        if summonRestrict then
            isZoneRestricted = true
            -- Zone-restricted flying mounts (TBC/WotLK) are flying even without riding 225 text.
            isFlying = true
        end
    end
    mountTraitCache[itemId] = { isFlying = isFlying, isZoneRestricted = isZoneRestricted, timestamp = now }
    return isFlying, isZoneRestricted, false
end

function Spells.IsMountFlyingByRidingRequirement(itemId)
    local isFlying, _, unknown = GetMountTraits(itemId)
    if unknown then
        return false
    end
    return isFlying
end

--- True when tooltip traits are not loaded yet (after zone/cache invalidate).
function Spells.IsMountTraitUnknown(itemId)
    return select(3, GetMountTraits(itemId)) and true or false
end

function Spells.IsMountZoneRestrictedToOutlandOrNorthrend(itemId)
    local _, isZoneRestricted, unknown = GetMountTraits(itemId)
    if unknown then
        return false
    end
    return isZoneRestricted
end

--- Flying / zone-restricted mounts are unusable outside Outland/Northrend on TBC/Wrath.
--- Also unusable inside instances (BGs etc.) even when geography is Outland/Northrend.
--- Selection (prefer ground) is owned by MountItems ResolveBest — do not empty the
--- bag list during settle or for unknown tooltips after dungeon/teleport exits.
function Spells.IsMountUsableInCurrentZone(itemId)
    if not itemId then
        return true
    end
    local api = _G.FLUX_API
    local isTBC = api and api.isTBC
    local isWrath = api and api.isWrath
    if not isTBC and not isWrath then
        return true
    end
    local isFlying, isZoneRestricted, unknown = GetMountTraits(itemId)
    if unknown then
        return true
    end
    if not (isFlying or isZoneRestricted) then
        return true
    end
    -- Restricted instances: known flyers are unusable. Settle must NOT strip them
    -- from the list (that emptied flyer-only bags after dungeon exits).
    if Spells.IsInMountRestrictedInstance() then
        return false
    end
    return Spells.IsOutlandOrNorthrendContinent()
end

local MOUNT_ITEMS_CACHE_TTL = 5
local mountItemsCache = nil
local mountItemsCacheTime = 0
local mountItemsCacheBagsGen = -1
local mountItemsCacheInstanceID = -1

local function GetBagsGeneration()
    local bags = Inv.Bags
    if bags and bags.GetGeneration then
        return bags.GetGeneration() or 0
    end
    return 0
end

--- Soft invalidate for settle pulses: rescan bags / classify, keep mount traits.
--- Wiping traits every pulse caused cold-tooltip "unknown" loops after zoning.
function Spells.InvalidateMountItemsCacheForSettle()
    mountItemsCache = nil
    mountItemsCacheTime = 0
    mountItemsCacheBagsGen = -1
    mountItemsCacheInstanceID = -1
    wipe(isMountItemCache)
end

function Spells.InvalidateMountItemsCache()
    Spells.InvalidateMountItemsCacheForSettle()
    -- Full invalidate (bag identity / login): drop trait cache too.
    mountTraitCache = {}
end
-- Alias used by Mount.lua / legacy callers
Spells.InvalidateAllMountItemsCache = Spells.InvalidateMountItemsCache

local function WalkCarriedBagsForMounts(seen, mounts)
    local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
    local GetContainerItemID = C_Container and C_Container.GetContainerItemID or _G.GetContainerItemID
    local bagIDs = Inv.GetCarriedBagIDs and Inv.GetCarriedBagIDs() or nil
    if not bagIDs or #bagIDs == 0 then
        bagIDs = {}
        local n = NUM_BAG_SLOTS or 4
        for bag = 0, n do
            bagIDs[#bagIDs + 1] = bag
        end
    end
    if not GetContainerNumSlots or not GetContainerItemID then
        return
    end
    for _, bag in ipairs(bagIDs) do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            ConsiderMountItem(GetContainerItemID(bag, slot), bag, slot, seen, mounts)
        end
    end
end

local function WalkKeyringForMounts(seen, mounts)
    local keyringBagId = _G.FLUX_API and _G.FLUX_API.keyringBagId
    if not keyringBagId then
        return
    end
    local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
    local GetContainerItemID = C_Container and C_Container.GetContainerItemID or _G.GetContainerItemID
    if not GetContainerNumSlots or not GetContainerItemID then
        return
    end
    local n = GetContainerNumSlots(keyringBagId) or 0
    for slot = 1, n do
        ConsiderMountItem(GetContainerItemID(keyringBagId, slot), keyringBagId, slot, seen, mounts)
    end
end

--- Unique bag mount items for flyout generators (legacy FluxItemDetection shape).
-- Returns { { itemId, name, icon, quality, bag, slot }, ... } sorted by quality then name.
-- Keyed by Bags.GetGeneration(); short TTL as secondary. forceRefresh bypasses both.
function Spells.ScanBagsForAllMountItems(forceRefresh)
    local now = GetTime and GetTime() or 0
    local bagsGen = GetBagsGeneration()
    local instanceID = Spells.GetCurrentInstanceMapID() or 0
    if not forceRefresh
        and mountItemsCache
        and mountItemsCacheBagsGen == bagsGen
        and mountItemsCacheInstanceID == instanceID
        and (now - mountItemsCacheTime) < MOUNT_ITEMS_CACHE_TTL
    then
        return mountItemsCache
    end

    local mounts = {}
    local seen = {}
    local bags = Inv.Bags

    if bags and bags.Refresh then
        bags.Refresh()
        bagsGen = GetBagsGeneration()
    end

    local unique = bags and bags.GetUniqueItems and bags.GetUniqueItems() or nil
    if unique and next(unique) then
        for itemId, rec in pairs(unique) do
            ConsiderMountItem(itemId, rec and rec.bag, rec and rec.slot, seen, mounts)
        end
    end

    -- Live walk when unique found nothing, or on forceRefresh (covers stale classify / late item info).
    if #mounts == 0 or forceRefresh then
        WalkCarriedBagsForMounts(seen, mounts)
    end

    WalkKeyringForMounts(seen, mounts)

    table.sort(mounts, function(a, b)
        local qa, qb = a.quality or 0, b.quality or 0
        if qa ~= qb then
            return qa > qb
        end
        return (a.name or "") < (b.name or "")
    end)

    mountItemsCache = mounts
    mountItemsCacheTime = now
    mountItemsCacheBagsGen = bagsGen
    mountItemsCacheInstanceID = Spells.GetCurrentInstanceMapID() or 0
    return mounts
end

function Spells.HasAnyCollectedMount()
    if C_MountJournal and C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, id in ipairs(ids) do
                local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(id)
                if isCollected then
                    return true
                end
            end
        end
    end
    if GetNumCompanions then
        if (GetNumCompanions("MOUNT") or 0) > 0 then
            return true
        end
    end
    local list = Spells.ScanBagsForAllMountItems()
    return list and #list > 0
end

-- ---------------------------------------------------------------------------
-- Teleport / hearth items (Hearthstone NC button — name-based scan)
-- ---------------------------------------------------------------------------

-- Place-specific teleports (not bindable hearthstones). Matched by ID so detection
-- still works when GetItemInfo has not cached the name yet.
Spells.TELEPORT_ITEM_IDS = {
    [243229] = true, -- Hearthstone of the Dawn (SoD — Light's Hope Chapel)
}

Spells.TELEPORT_ITEM_NAME_PATTERNS = {
    "Atiesh",
    "Hearthstone of the Dawn",
    "Beacon of Hydraxis",
    "Aragriar's Whimsical World Warper",
    "Scroll of Liminal Passage",
    "Hearthstone",
}

-- Quest fragments that match the Atiesh name scan but are not the staff teleport.
Spells.TELEPORT_ITEM_EXCLUDED_IDS = {
    [22726] = true, -- Splinter of Atiesh
}

function Spells.IsExcludedTeleportItem(itemId, name)
    itemId = tonumber(itemId)
    if itemId and Spells.TELEPORT_ITEM_EXCLUDED_IDS[itemId] then
        return true
    end
    if type(name) == "string" and name ~= "" then
        if string.lower(name):find("splinter of atiesh", 1, true) then
            return true
        end
    end
    return false
end

local TELEPORT_ITEMS_CACHE_TTL = 5
local teleportItemsCache = nil
local teleportItemsCacheTime = 0

local function ItemIsEquippable(itemId)
    if not itemId then
        return false
    end
    if C_Item and C_Item.IsEquippableItem then
        return C_Item.IsEquippableItem(itemId) and true or false
    end
    if IsEquippableItem then
        return IsEquippableItem(itemId) and true or false
    end
    return false
end

function Spells.IsItemEquipped(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end
    local equip = Inv.Equip
    if equip and equip.GetCount then
        return (equip.GetCount(itemId) or 0) > 0
    end
    for slot = 1, 19 do
        local id = GetInventoryItemID and GetInventoryItemID("player", slot)
        if id and id == itemId then
            return true
        end
    end
    return false
end

local function NameMatchesTeleportPatterns(name, patterns)
    if not name or not patterns then
        return false
    end
    local lowerName = string.lower(name)
    for _, p in ipairs(patterns) do
        if type(p) == "string" and p ~= "" then
            local lp = string.lower(p)
            -- Bare "Hearthstone" must be exact — place teleports like
            -- "Hearthstone of the Dawn" have their own dedicated patterns / IDs.
            if lp == "hearthstone" then
                if lowerName == "hearthstone" then
                    return true
                end
            elseif lp == "atiesh" then
                -- Staff is "Atiesh, Greatstaff of the Guardian". Splinter of Atiesh is a quest fragment.
                if not lowerName:find("splinter of atiesh", 1, true) and lowerName:find(lp, 1, true) then
                    return true
                end
            elseif lowerName:find(lp, 1, true) then
                return true
            end
        end
    end
    return false
end

local function AddTeleportItemFromId(itemId, bag, slot, seen, out, patterns)
    itemId = tonumber(itemId)
    if not itemId or seen[itemId] then
        return
    end
    local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local getItemIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    local name, _, _, _, _, _, _, _, _, icon = getItemInfo(itemId)
    if Spells.IsExcludedTeleportItem(itemId, name) then
        return
    end
    local knownId = Spells.TELEPORT_ITEM_IDS and Spells.TELEPORT_ITEM_IDS[itemId]
    if not knownId then
        if not name or not NameMatchesTeleportPatterns(name, patterns) then
            return
        end
    end
    seen[itemId] = true
    out[#out + 1] = {
        itemId = itemId,
        name = name or ("item:" .. tostring(itemId)),
        icon = icon or (getItemIcon and getItemIcon(itemId)) or "Interface\\Icons\\INV_Misc_QuestionMark",
        isEquipment = ItemIsEquippable(itemId),
        isEquipped = Spells.IsItemEquipped(itemId),
        bag = bag,
        slot = slot,
    }
end

--- Scan bags, optional keyring, and equipped inventory for teleport-related items.
--- @return table[] { itemId, name, icon, isEquipment, isEquipped, bag, slot }
function Spells.ScanForTeleportItems(patterns, forceRefresh)
    patterns = (type(patterns) == "table" and #patterns > 0) and patterns or Spells.TELEPORT_ITEM_NAME_PATTERNS
    local now = GetTime and GetTime() or 0
    if not forceRefresh and teleportItemsCache and (now - teleportItemsCacheTime) < TELEPORT_ITEMS_CACHE_TTL then
        return teleportItemsCache
    end

    local out = {}
    local seen = {}

    local bags = Inv.Bags
    local unique = bags and bags.GetUniqueItems and bags.GetUniqueItems() or nil
    if unique then
        for itemId, rec in pairs(unique) do
            AddTeleportItemFromId(itemId, rec and rec.bag, rec and rec.slot, seen, out, patterns)
        end
    end

    -- Keyring (classic / when exposed)
    local keyringBagId = _G.FLUX_API and _G.FLUX_API.keyringBagId
    if keyringBagId then
        local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
        local GetContainerItemID = C_Container and C_Container.GetContainerItemID or _G.GetContainerItemID
        if GetContainerNumSlots and GetContainerItemID then
            local n = GetContainerNumSlots(keyringBagId) or 0
            for slot = 1, n do
                local itemId = GetContainerItemID(keyringBagId, slot)
                if itemId then
                    AddTeleportItemFromId(itemId, keyringBagId, slot, seen, out, patterns)
                end
            end
        end
    end

    local equip = Inv.Equip
    if equip and equip.GetSlots then
        equip.Refresh()
        for invSlot, rec in pairs(equip.GetSlots() or {}) do
            if rec and rec.itemID and not seen[rec.itemID] then
                AddTeleportItemFromId(rec.itemID, -1, invSlot, seen, out, patterns)
            end
        end
    else
        for invSlot = 1, 19 do
            local itemId = GetInventoryItemID and GetInventoryItemID("player", invSlot)
            if itemId and not seen[itemId] then
                AddTeleportItemFromId(itemId, -1, invSlot, seen, out, patterns)
            end
        end
    end

    table.sort(out, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    teleportItemsCache = out
    teleportItemsCacheTime = now
    return out
end

function Spells.InvalidateTeleportItemCache()
    teleportItemsCache = nil
    teleportItemsCacheTime = 0
end

--- True if player has item in bags, keyring, or equipped (FluxInv SoT; no GetItemCount bypass).
function Spells.PlayerHasItemInInventory(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end
    if Spells.IsItemEquipped(itemId) then
        return true
    end
    if Inv.Bags and Inv.Bags.GetCount and (Inv.Bags.GetCount(itemId) or 0) > 0 then
        return true
    end
    local keyringBagId = _G.FLUX_API and _G.FLUX_API.keyringBagId
    if keyringBagId and Inv.Bags and Inv.Bags.GetUniqueItems then
        -- Prefer Bags unique if keyring is included; else direct keyring slot walk (FluxInv containers).
        local uniq = Inv.Bags.GetUniqueItems()
        if uniq and uniq[itemId] and (uniq[itemId].count or 0) > 0 then
            return true
        end
    end
    if keyringBagId then
        local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
        local GetContainerItemID = C_Container and C_Container.GetContainerItemID or _G.GetContainerItemID
        if GetContainerNumSlots and GetContainerItemID then
            local n = GetContainerNumSlots(keyringBagId) or 0
            for slot = 1, n do
                if GetContainerItemID(keyringBagId, slot) == itemId then
                    return true
                end
            end
        end
    end
    return false
end

-- Soft shims for legacy callers that still look at FluxItemDetection / FluxNCItemDetection.
do
    local Det = _G.FluxItemDetection or {}
    _G.FluxItemDetection = Det
    Det.HasConjureFood = Spells.HasConjureFood
    Det.HasConjureWater = Spells.HasConjureWater
    Det.HasConjureRefreshment = Spells.HasConjureRefreshment
    Det.HasRitualOfRefreshment = Spells.HasRitualOfRefreshment
    Det.HasAnyConjureSpell = Spells.HasAnyConjureSpell
    Det.GetPreferredGroupConjureSpell = Spells.GetPreferredGroupConjureSpell
    Det.GetPreferredFoodConjureSpell = Spells.GetPreferredFoodConjureSpell
    Det.GetPreferredWaterConjureSpell = Spells.GetPreferredWaterConjureSpell
    Det.GetSecondaryFoodConjureSpell = Spells.GetSecondaryFoodConjureSpell
    Det.GetSecondaryWaterConjureSpell = Spells.GetSecondaryWaterConjureSpell
    Det.IsItemAMount = Spells.IsItemAMount
    Det.ScanBagsForAllMountItems = Spells.ScanBagsForAllMountItems
    Det.InvalidateMountItemsCache = Spells.InvalidateMountItemsCache
    Det.InvalidateMountItemsCacheForSettle = Spells.InvalidateMountItemsCacheForSettle
    Det.InvalidateAllMountItemsCache = Spells.InvalidateAllMountItemsCache
    Det.HasAnyCollectedMount = Spells.HasAnyCollectedMount
    Det.GetCurrentContinentMapID = Spells.GetCurrentContinentMapID
    Det.GetCurrentInstanceMapID = Spells.GetCurrentInstanceMapID
    Det.IsOutlandOrNorthrendContinent = Spells.IsOutlandOrNorthrendContinent
    Det.IsPlayerInOutlandOrNorthrend = Spells.IsPlayerInOutlandOrNorthrend
    Det.IsInMountRestrictedInstance = Spells.IsInMountRestrictedInstance
    Det.GetMountItemLocationKey = Spells.GetMountItemLocationKey
    Det.BeginMountItemLocationSettle = Spells.BeginMountItemLocationSettle
    Det.EndMountItemLocationSettle = Spells.EndMountItemLocationSettle
    Det.IsMountItemLocationSettling = Spells.IsMountItemLocationSettling
    Det.UpdateMountItemLocationSettle = Spells.UpdateMountItemLocationSettle
    Det.IsFlyableHere = Spells.IsFlyableHere
    Det.CanPreferFlyingMountItem = Spells.CanPreferFlyingMountItem
    Det.IsMountFlyingByRidingRequirement = Spells.IsMountFlyingByRidingRequirement
    Det.IsMountTraitUnknown = Spells.IsMountTraitUnknown
    Det.IsMountZoneRestrictedToOutlandOrNorthrend = Spells.IsMountZoneRestrictedToOutlandOrNorthrend
    Det.IsMountUsableInCurrentZone = Spells.IsMountUsableInCurrentZone

    local NCDet = _G.FluxNCItemDetection or {}
    _G.FluxNCItemDetection = NCDet
    NCDet.TELEPORT_ITEM_NAME_PATTERNS_DEFAULT = Spells.TELEPORT_ITEM_NAME_PATTERNS
    NCDet.TELEPORT_ITEM_IDS = Spells.TELEPORT_ITEM_IDS
    NCDet.TELEPORT_ITEM_EXCLUDED_IDS = Spells.TELEPORT_ITEM_EXCLUDED_IDS
    NCDet.IsExcludedTeleportItem = Spells.IsExcludedTeleportItem
    NCDet.ScanForTeleportItems = Spells.ScanForTeleportItems
    NCDet.InvalidateTeleportItemCache = Spells.InvalidateTeleportItemCache
    NCDet.IsItemEquipped = Spells.IsItemEquipped
    NCDet.PlayerHasItemInInventory = Spells.PlayerHasItemInInventory
    NCDet.IsItemAMount = Spells.IsItemAMount
    NCDet.ScanBagsForAllMountItems = Spells.ScanBagsForAllMountItems
    NCDet.InvalidateMountItemsCache = Spells.InvalidateMountItemsCache
    NCDet.InvalidateMountItemsCacheForSettle = Spells.InvalidateMountItemsCacheForSettle
    NCDet.InvalidateAllMountItemsCache = Spells.InvalidateAllMountItemsCache
    NCDet.HasAnyCollectedMount = Spells.HasAnyCollectedMount
    NCDet.GetCurrentContinentMapID = Spells.GetCurrentContinentMapID
    NCDet.GetCurrentInstanceMapID = Spells.GetCurrentInstanceMapID
    NCDet.IsOutlandOrNorthrendContinent = Spells.IsOutlandOrNorthrendContinent
    NCDet.IsPlayerInOutlandOrNorthrend = Spells.IsPlayerInOutlandOrNorthrend
    NCDet.IsInMountRestrictedInstance = Spells.IsInMountRestrictedInstance
    NCDet.GetMountItemLocationKey = Spells.GetMountItemLocationKey
    NCDet.BeginMountItemLocationSettle = Spells.BeginMountItemLocationSettle
    NCDet.EndMountItemLocationSettle = Spells.EndMountItemLocationSettle
    NCDet.IsMountItemLocationSettling = Spells.IsMountItemLocationSettling
    NCDet.UpdateMountItemLocationSettle = Spells.UpdateMountItemLocationSettle
    NCDet.IsFlyableHere = Spells.IsFlyableHere
    NCDet.CanPreferFlyingMountItem = Spells.CanPreferFlyingMountItem
    NCDet.IsMountFlyingByRidingRequirement = Spells.IsMountFlyingByRidingRequirement
    NCDet.IsMountTraitUnknown = Spells.IsMountTraitUnknown
    NCDet.IsMountZoneRestrictedToOutlandOrNorthrend = Spells.IsMountZoneRestrictedToOutlandOrNorthrend
    NCDet.IsMountUsableInCurrentZone = Spells.IsMountUsableInCurrentZone
end

_G.FluxInv = Inv
