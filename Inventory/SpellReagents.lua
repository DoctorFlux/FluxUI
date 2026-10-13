-- Inventory/SpellReagents.lua — spell-book reagent map for restock lists.
-- Attaches onto existing FluxInv.Spells / Flux.Inventory.CreateSpells (conjure stays there).
local addonName, ns = ...
local Flux = ns.Flux

local Spells = (_G.FluxInv and _G.FluxInv.Spells)
    or (Flux and Flux.Inventory and Flux.Inventory.CreateSpells)
if type(Spells) ~= "table" then
    return
end

local wipe = wipe or function(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

local SOUL_SHARD_NAME = "soul shard"
local REAGENT_SCAN_CAP = 6
local REAGENT_SCAN_INTERVAL = 0.05

local reagentBySpell = {}
local spellsUsingReagent = {}
local allReagentItemIDs = {}
local activeReagentItemIDs = {}
local maxRankReagentSpell = {}
local nameToItemID = {}
local pendingReagentNames = {}
local reagentQueue = {}
local reagentQueueIdx = 1
local reagentsDirty = true
local reagentsWarmDone = false
local reagentWarmPending = false
local reagentWarmGen = 0
local scannerTip
local FinalizeActiveReagents

local function After(delay, fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

-- Midnight tooltip leftText is a secret string. type() is allowed; == / gmatch is not.
local function AccessibleString(value)
    if value == nil then
        return nil
    end
    local S = Flux and Flux.Secrets
    if S and S.SafeAccessibleString then
        local ok, text = pcall(S.SafeAccessibleString, value)
        if not ok or text == nil then
            return nil
        end
        value = text
    elseif S and S.IsSecretValue then
        local ok, secret = pcall(S.IsSecretValue, value)
        if ok and secret then
            return nil
        end
    end
    if type(value) ~= "string" or value == "" then
        return nil
    end
    return value
end

local function SpellName(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if type(info) == "table" then
            return AccessibleString(info.name)
        end
    end
    if GetSpellInfo then
        return AccessibleString(GetSpellInfo(spellID))
    end
    return nil
end

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
    subtext = AccessibleString(subtext)
    if subtext then
        local rankNum = tonumber(subtext:match("[Rr]ank%s*(%d+)"))
        if rankNum then
            return rankNum
        end
    end
    local name = AccessibleString(SpellName(spellID))
    if name then
        local rankNum = tonumber(name:match("%(%s*[Rr]ank%s*(%d+)%s*%)"))
        if rankNum then
            return rankNum
        end
    end
    return 0
end

local function RankScore(spellID)
    spellID = tonumber(spellID) or 0
    return GetSpellRankNumber(spellID) * 1000000 + spellID
end

local function IsSoulCurrencySpellName(spellName)
    if type(spellName) ~= "string" then
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
    [SOUL_SHARD_NAME] = true,
}

local function RememberBlacklistedReagentName(name)
    if type(name) == "string" and name ~= "" then
        blacklistedReagentNames[name:lower()] = true
    end
end

local function IsSoulShardName(name)
    return type(name) == "string" and blacklistedReagentNames[name:lower()] == true
end

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

local function GetScanner()
    if scannerTip then
        return scannerTip
    end
    scannerTip = CreateFrame("GameTooltip", "FluxSpellReagentTip", UIParent, "GameTooltipTemplate")
    scannerTip:SetOwner(UIParent, "ANCHOR_NONE")
    return scannerTip
end

local function WipeTip(tip)
    local base = tip:GetName() or "FluxSpellReagentTip"
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
    pendingReagentNames[name:lower()] = nil
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

local function HarvestVisibleItemNames()
    local api = Flux and Flux.Inventory
    if api and api.GetUniqueItems then
        local set = api.GetUniqueItems({ bags = true, bank = true, warband = true })
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
    if GetMerchantNumItems and GetMerchantItemLink then
        local num = GetMerchantNumItems() or 0
        for i = 1, num do
            local link = GetMerchantItemLink(i)
            local itemID = link and tonumber(link:match("item:(%d+)"))
            local name
            if GetMerchantItemInfo then
                name = GetMerchantItemInfo(i)
            elseif C_MerchantFrame and C_MerchantFrame.GetItemInfo then
                local info = C_MerchantFrame.GetItemInfo(i)
                name = type(info) == "table" and info.name or nil
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
    text = AccessibleString(text)
    if not text then
        return
    end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " ")
    text = text:gsub("|T.-|t", "")
    for part in text:gmatch("[^,]+") do
        local name = part:match("^(.-)%s*%(%d+%)%s*$") or part
        name = name:match("^%d+%s+(.+)$") or name
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

local function ExtractReagentItemsFromLine(lineText)
    lineText = AccessibleString(lineText)
    if not lineText then
        return nil
    end
    local cleaned = lineText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " "):gsub("|T.-|t", "")
    cleaned = cleaned:match("^%s*(.-)%s*$") or cleaned
    local items = cleaned:match("^[Rr]equires%s+[Rr]eagents?%s*:%s*(.+)$")
    if items then
        return items
    end
    items = cleaned:match("^[Rr]eagents?%s*:%s*(.+)$")
    if items then
        return items
    end
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
    if lower:find("^cast") or lower:find("^requires%s") then
        return true
    end
    return false
end

local function CollectReagentsFromTooltipData(data, reagents)
    if type(data) ~= "table" or type(data.lines) ~= "table" then
        return
    end
    local S = Flux and Flux.Secrets
    if S then
        if S.IsSecretTable and (S.IsSecretTable(data) or S.IsSecretTable(data.lines)) then
            return
        end
        if S.CanAccessTable and (not S.CanAccessTable(data) or not S.CanAccessTable(data.lines)) then
            return
        end
    end
    local inSection = false
    for i = 1, #data.lines do
        local line = data.lines[i]
        if type(line) == "table" then
            local raw = AccessibleString(line.leftText) or AccessibleString(line.text)
            if raw then
                for id in raw:gmatch("item:(%d+)") do
                    local n = tonumber(id)
                    if n and not IsBlacklistedReagent(n) then
                        reagents[#reagents + 1] = { itemID = n }
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
            end
        end
    end
end

local function CollectReagentsFromTooltip(spellID)
    local reagents = {}
    if C_TooltipInfo then
        local data
        if C_TooltipInfo.GetSpellByID then
            local ok, d = pcall(C_TooltipInfo.GetSpellByID, spellID)
            if ok then
                data = d
            end
        end
        if data then
            pcall(CollectReagentsFromTooltipData, data, reagents)
        end
    end
    if #reagents == 0 then
        local tip = GetScanner()
        tip:ClearLines()
        WipeTip(tip)
        pcall(function()
            tip:SetSpellByID(spellID)
        end)
        local base = tip:GetName() or "FluxSpellReagentTip"
        local numLines = math.min(40, math.max(0, tip:NumLines() or 0))
        pcall(function()
            local inSection = false
            for line = 1, numLines do
                local textObj = _G[base .. "TextLeft" .. line]
                if textObj and textObj.GetText then
                    local raw = AccessibleString(textObj:GetText())
                    if raw then
                        for id in raw:gmatch("item:(%d+)") do
                            local n = tonumber(id)
                            if n and not IsBlacklistedReagent(n) then
                                reagents[#reagents + 1] = { itemID = n }
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
                    end
                end
            end
        end)
    end
    for i = 1, #reagents do
        local r = reagents[i]
        if not r.itemID and r.name then
            r.itemID = GetItemIDFromName(r.name)
        end
    end
    if #reagents == 0 or (reagents[1] and not reagents[1].itemID) then
        local lib = LibStub and LibStub("LibClassicSpellActionCount-1.0", true)
        if lib and lib.GetSpellReagentItemID then
            local reagentID = tonumber(lib:GetSpellReagentItemID(spellID))
            if reagentID and not IsBlacklistedReagent(reagentID) then
                local name = GetItemNameForID(reagentID)
                if #reagents == 0 then
                    reagents[1] = { itemID = reagentID, name = name }
                elseif reagents[1] and not reagents[1].itemID then
                    reagents[1].itemID = reagentID
                    reagents[1].name = reagents[1].name or name
                end
                if name then
                    RememberItemName(reagentID, name)
                end
            end
        end
    end
    return reagents
end

local function ForEachKnownPlayerSpell(callback)
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
            if skillLineInfo then
                local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
                for j = skillLineInfo.itemIndexOffset + 1, skillLineInfo.itemIndexOffset + skillLineInfo.numSpellBookItems do
                    local spellInfo = C_SpellBook.GetSpellBookItemInfo(j, bank)
                    if spellInfo and spellInfo.actionID then
                        local itemType = spellInfo.itemType
                        local isSpell = true
                        if Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell then
                            isSpell = (itemType == Enum.SpellBookItemType.Spell)
                        end
                        if isSpell then
                            callback(spellInfo.actionID)
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

local function IngestReagents(spellID, reagents)
    if not reagents or #reagents == 0 then
        return
    end
    reagentBySpell[spellID] = reagents
    local spellName = SpellName(spellID)
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
        elseif r.name and not r.itemID and not learnSoulShard then
            pendingReagentNames[r.name:lower()] = true
        end
    end
end

local function GetSpellBaseNameKey(spellID)
    local name = SpellName(spellID)
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

local function ResolvePendingReagentNames()
    HarvestVisibleItemNames()
    local changed = false
    for spellID, reagents in pairs(reagentBySpell) do
        if type(reagents) == "table" then
            for i = 1, #reagents do
                local r = reagents[i]
                if type(r) == "table" and not r.itemID and r.name then
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
                end
            end
        end
    end
    return changed
end

FinalizeActiveReagents = function(runMigration)
    ResolvePendingReagentNames()
    wipe(activeReagentItemIDs)
    wipe(maxRankReagentSpell)
    local families = {}
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
    local migrations = {}
    for baseKey, fam in pairs(families) do
        local activeList, seen = {}, {}
        local bestReagents = reagentBySpell[fam.bestID]
        if bestReagents then
            for i = 1, #bestReagents do
                local itemID = bestReagents[i] and tonumber(bestReagents[i].itemID)
                if itemID and not IsBlacklistedReagent(itemID) and not seen[itemID] then
                    seen[itemID] = true
                    activeList[#activeList + 1] = itemID
                end
            end
        end
        local obsoleteSet, hasObsolete = {}, false
        for i = 1, #fam.spells do
            local spellID = fam.spells[i]
            if spellID ~= fam.bestID then
                local rs = reagentBySpell[spellID]
                if rs then
                    for j = 1, #rs do
                        local itemID = rs[j] and tonumber(rs[j].itemID)
                        if itemID and not IsBlacklistedReagent(itemID) and not activeReagentItemIDs[itemID] then
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
    local RI = _G.FluxRestock and _G.FluxRestock.Inv
    if RI and RI.Notify then
        RI.Notify({ regions = { spells = true }, source = "spells" })
    end
end

local function rebuildReagents()
    wipe(reagentBySpell)
    wipe(spellsUsingReagent)
    wipe(allReagentItemIDs)
    wipe(activeReagentItemIDs)
    wipe(maxRankReagentSpell)
    local pending = {}
    ForEachKnownPlayerSpell(function(spellID)
        pending[#pending + 1] = spellID
    end)
    reagentWarmGen = reagentWarmGen + 1
    reagentQueue = pending
    reagentQueueIdx = 1
    reagentsDirty = #pending > 0
    reagentsWarmDone = not reagentsDirty
    reagentWarmPending = false
    if reagentsWarmDone then
        FinalizeActiveReagents(true)
    end
end

local function processReagentBatch(gen)
    if gen ~= reagentWarmGen then
        return
    end
    reagentWarmPending = false
    if not reagentsDirty then
        reagentsWarmDone = true
        FinalizeActiveReagents(true)
        return
    end
    local n = 0
    while n < REAGENT_SCAN_CAP and reagentQueueIdx <= #reagentQueue do
        local spellID = reagentQueue[reagentQueueIdx]
        reagentQueueIdx = reagentQueueIdx + 1
        if spellID and not reagentBySpell[spellID] then
            IngestReagents(spellID, CollectReagentsFromTooltip(spellID))
            n = n + 1
        end
    end
    if reagentQueueIdx <= #reagentQueue then
        reagentWarmPending = true
        After(REAGENT_SCAN_INTERVAL, function()
            processReagentBatch(gen)
        end)
    else
        reagentsDirty = false
        reagentsWarmDone = true
        wipe(reagentQueue)
        reagentQueueIdx = 1
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
    After(REAGENT_SCAN_INTERVAL, function()
        processReagentBatch(gen)
    end)
end

local warmScheduled = false
function Spells.ScheduleWarm()
    if warmScheduled then
        return
    end
    warmScheduled = true
    After(1.5, function()
        warmScheduled = false
        Spells.Refresh()
    end)
end

local origInvalidate = Spells.Invalidate
local origRefresh = Spells.Refresh

function Spells.Invalidate()
    reagentsDirty = true
    reagentsWarmDone = false
    if origInvalidate then
        origInvalidate()
    end
end

function Spells.Refresh()
    -- Only rebuild the reagent queue when the spellbook actually scanned.
    -- A no-op Refresh must not bump reagentWarmGen (that cancels in-flight warm).
    local scanned = origRefresh and origRefresh()
    if reagentsDirty then
        if scanned then
            rebuildReagents()
        end
        Spells.ScheduleReagentWarm()
    end
    return scanned and true or false
end

function Spells.AreReagentsWarmed()
    return reagentsWarmDone
end

function Spells.OnVisibleItemsChanged()
    local changed = ResolvePendingReagentNames()
    if changed and reagentsWarmDone then
        FinalizeActiveReagents(true)
        return true
    end
    return changed
end

function Spells.UsesReagents(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return false
    end
    Spells.Refresh()
    local r = reagentBySpell[spellID]
    return r and #r > 0 or false
end

function Spells.GetReagents(spellID)
    spellID = tonumber(spellID)
    Spells.Refresh()
    return reagentBySpell[spellID]
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

local function FormatSpellReagentLabel(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return "Spell"
    end
    local name = SpellName(spellID)
    if type(name) ~= "string" or name == "" then
        return "Spell " .. spellID
    end
    local base = name:gsub("%s*%(%s*[Rr]ank%s*%d+%s*%)%s*$", "")
    base = base:match("^%s*(.-)%s*$") or base
    local rankNum = GetSpellRankNumber(spellID)
    if rankNum and rankNum > 0 then
        return string.format("%s (Rank %d)", base, rankNum)
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
        if not reagentsWarmDone or maxRankReagentSpell[spellID] then
            out[#out + 1] = spellID
        end
    end
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

function Spells.GetSpellsUsingReagentLabeled(itemID)
    itemID = tonumber(itemID)
    Spells.Refresh()
    local set = spellsUsingReagent[itemID]
    if not set then
        return {}
    end
    local out = {}
    local function addSpell(spellID)
        out[#out + 1] = {
            spellID = spellID,
            rank = GetSpellRankNumber(spellID),
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

-- SPELLS_CHANGED is signature-gated via CreateSpells → SpellBook.OnChanged → Invalidate.
-- PLAYER_ENTERING_WORLD one-shot lives on CreateSpells (Invalidate + ScheduleWarm).
