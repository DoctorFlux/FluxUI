--[[
    Inventory/Professions.lua

    Layered profession recipe cache:
      Tier C — live API when data is loaded
      Tier B — paced login/reload scan (best-effort; aborts in combat)
      Tier A — authoritative scan when profession UI is open

    Forever (camelot) lists recipes with GetFilteredRecipeIDs / GetProfessionSpells
    and identifies the open skill via GetChildProfessionInfo / GetBaseProfessionInfo.
    GetAllRecipeIDs and GetProfessionInfo are Classic/live leftovers and may be missing.
]]
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory

Inv.Professions = Inv.Professions or {}
local Prof = Inv.Professions

local wipe = table.wipe or wipe
local HAS_MODERN_PROF = (C_TradeSkillUI ~= nil and type(C_TradeSkillUI.GetRecipeInfo) == "function")
local scanBusy = false

local function HasModernRecipeList()
    return C_TradeSkillUI and (
        type(C_TradeSkillUI.GetAllRecipeIDs) == "function"
        or type(C_TradeSkillUI.GetFilteredRecipeIDs) == "function"
        or type(C_TradeSkillUI.GetProfessionSpells) == "function"
    ) and true or false
end

--- Forever has no C_TradeSkillUI.GetProfessionInfo. Blizzard uses child, then base.
function Prof.GetOpenProfessionInfo()
    if not C_TradeSkillUI then
        return nil
    end
    local info
    if C_TradeSkillUI.GetChildProfessionInfo then
        local ok, child = pcall(C_TradeSkillUI.GetChildProfessionInfo)
        if ok and type(child) == "table" and (tonumber(child.professionID) or 0) ~= 0 then
            info = child
        end
    end
    if (not info or (tonumber(info.professionID) or 0) == 0) and C_TradeSkillUI.GetBaseProfessionInfo then
        local ok, base = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
        if ok and type(base) == "table" and (tonumber(base.professionID) or 0) ~= 0 then
            info = base
        end
    end
    if (not info or (tonumber(info.professionID) or 0) == 0) and C_TradeSkillUI.GetProfessionInfo then
        local ok, legacy = pcall(C_TradeSkillUI.GetProfessionInfo)
        if ok and type(legacy) == "table" then
            info = legacy
        end
    end
    if type(info) ~= "table" then
        return nil
    end
    return info
end

local function AppendRecipeIDs(dst, seen, list)
    if type(list) ~= "table" then
        return
    end
    for i = 1, #list do
        local id = tonumber(list[i])
        if id and not seen[id] then
            seen[id] = true
            dst[#dst + 1] = id
        end
    end
end

--- Forever (camelot) lists recipes with GetFilteredRecipeIDs. GetAllRecipeIDs is
--- Classic C_TradeSkillUI and is missing there. Merge every available source.
local function ListOpenRecipeIDs()
    if not C_TradeSkillUI then
        return nil
    end
    local ids, seen = {}, {}
    if type(C_TradeSkillUI.GetAllRecipeIDs) == "function" then
        local ok, list = pcall(C_TradeSkillUI.GetAllRecipeIDs)
        if ok then
            AppendRecipeIDs(ids, seen, list)
        end
    end
    if type(C_TradeSkillUI.GetFilteredRecipeIDs) == "function" then
        local ok, list = pcall(C_TradeSkillUI.GetFilteredRecipeIDs)
        if ok then
            AppendRecipeIDs(ids, seen, list)
        end
    end
    local info = Prof.GetOpenProfessionInfo()
    if info and type(C_TradeSkillUI.GetProfessionSpells) == "function" then
        local profEnum = info.profession
        if profEnum ~= nil then
            local ok, list = pcall(C_TradeSkillUI.GetProfessionSpells, profEnum, info.professionID)
            if ok then
                AppendRecipeIDs(ids, seen, list)
            end
            if info.parentProfessionID then
                ok, list = pcall(C_TradeSkillUI.GetProfessionSpells, profEnum, info.parentProfessionID)
                if ok then
                    AppendRecipeIDs(ids, seen, list)
                end
            end
        end
    end
    if #ids == 0 then
        return nil
    end
    return ids
end

local function TradeSkillDataNotReady()
    if not C_TradeSkillUI then
        return false
    end
    if C_TradeSkillUI.IsDataSourceChanging then
        local ok, changing = pcall(C_TradeSkillUI.IsDataSourceChanging)
        if ok and changing then
            return true
        end
    end
    if C_TradeSkillUI.IsTradeSkillReady then
        local ok, ready = pcall(C_TradeSkillUI.IsTradeSkillReady)
        if ok and ready == false then
            return true
        end
    end
    return false
end

local function After(delay, fn)
    if Flux.Timer and Flux.Timer.After then
        Flux.Timer.After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

local function InCombat()
    if Flux.Combat and Flux.Combat.InLockdown then
        return Flux.Combat.InLockdown()
    end
    return (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) or false
end

local function SafeRegisterEvent(frame, eventName)
    if not frame or not eventName or eventName == "" then
        return false
    end
    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok
end

FluxInvDB = FluxInvDB or {}

local sessionCache = {} -- skillKey -> { recipes, scannedAt, source, name }
local loginScanQueued = false
local loginScanRunning = false
local loginScanAbort = false
local loginScanCompleted = false
local openSkillKey = nil

local function CharKey()
    local PN = Flux and Flux.PlayerName
    if PN and PN.GetCharKey then
        local key = PN.GetCharKey("professions")
        if key then
            return key
        end
    end
    local realm = GetRealmName and GetRealmName() or "Unknown"
    local character = UnitName and UnitName("player") or "Unknown"
    return realm .. "-" .. character
end

local function EnsureDB()
    FluxInvDB = FluxInvDB or {}
    FluxInvDB.professions = FluxInvDB.professions or {}
    local key = CharKey()
    FluxInvDB.professions[key] = FluxInvDB.professions[key] or { bySkillLine = {} }
    return FluxInvDB.professions[key]
end

local function StoreSkill(skillKey, payload)
    skillKey = tostring(skillKey)
    -- Never replace a non-empty recipe cache with an empty failed/partial scan.
    -- Login OpenTradeSkill from timers is protected and used to wipe good data.
    if payload and type(payload.recipes) == "table" and #payload.recipes == 0 then
        local existing = sessionCache[skillKey]
        if not existing then
            local db = EnsureDB()
            existing = db.bySkillLine[skillKey]
        end
        if existing and type(existing.recipes) == "table" and #existing.recipes > 0 then
            payload = {
                recipes = existing.recipes,
                scannedAt = existing.scannedAt or payload.scannedAt,
                source = existing.source or payload.source,
                name = payload.name or existing.name,
                needsOpen = true,
            }
        end
    end
    sessionCache[skillKey] = payload
    local db = EnsureDB()
    db.bySkillLine[skillKey] = {
        recipes = payload.recipes,
        scannedAt = payload.scannedAt,
        source = payload.source,
        name = payload.name,
        needsOpen = payload.needsOpen,
    }
    local Craft = Inv.Craft
    if Craft and Craft.InvalidateCanCraftCache then
        Craft.InvalidateCanCraftCache()
    end
end

local function LoadSkill(skillKey)
    skillKey = tostring(skillKey)
    if sessionCache[skillKey] then
        return sessionCache[skillKey]
    end
    local db = EnsureDB()
    local stored = db.bySkillLine[skillKey]
    if stored then
        sessionCache[skillKey] = stored
        return stored
    end
    return nil
end

local function Now()
    return GetTime and GetTime() or 0
end

-- ---------------------------------------------------------------------------
-- Recipe extraction helpers
-- ---------------------------------------------------------------------------

local function ExtractModernReagents(recipeID)
    local reagents = {}
    if not (C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic) then
        return reagents
    end
    local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
    if not ok or type(schematic) ~= "table" or not schematic.reagentSlotSchematics then
        return reagents
    end
    local function collect(basicOnly)
        local out = {}
        for _, slot in ipairs(schematic.reagentSlotSchematics) do
            local isBasic = true
            if Enum and Enum.CraftingReagentType and slot.reagentType then
                isBasic = (slot.reagentType == Enum.CraftingReagentType.Basic)
            end
            if (not basicOnly or isBasic)
                and slot.reagents and slot.reagents[1] and slot.reagents[1].itemID and slot.quantityRequired then
                out[#out + 1] = {
                    itemID = slot.reagents[1].itemID,
                    count = slot.quantityRequired,
                }
            end
        end
        return out
    end
    reagents = collect(true)
    if #reagents == 0 then
        reagents = collect(false)
    end
    return reagents
end

local function ExtractModernOutput(recipeID)
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeOutputItemData then
        local ok, data = pcall(C_TradeSkillUI.GetRecipeOutputItemData, recipeID)
        if ok and type(data) == "table" and data.itemID then
            return data.itemID, data.hyperlink
        end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if ok and type(info) == "table" then
            if info.hyperlink and type(info.hyperlink) == "string" then
                local id = tonumber(info.hyperlink:match("item:(%d+)"))
                if id then
                    return id, info.hyperlink
                end
            end
            if info.qualityItemIDs and type(info.qualityItemIDs) == "table" and info.qualityItemIDs[1] then
                return info.qualityItemIDs[1], nil
            end
        end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic then
        local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
        if ok and type(schematic) == "table" and schematic.outputItemID then
            return schematic.outputItemID, nil
        end
    end
    return nil, nil
end

--- Items produced per craft (e.g. Mana Potion Injector = 20). Defaults to 1.
local function ExtractModernQuantity(recipeID)
    local qtyMin, qtyMax = 1, 1
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic then
        local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
        if ok and type(schematic) == "table" then
            local amin = tonumber(schematic.quantityMin)
            local amax = tonumber(schematic.quantityMax)
            if amin and amin > 0 then
                qtyMin = amin
            end
            if amax and amax > 0 then
                qtyMax = amax
            elseif amin and amin > 0 then
                qtyMax = amin
            end
            return qtyMin, qtyMax
        end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if ok and type(info) == "table" then
            local amin = tonumber(info.quantityMin) or tonumber(info.numItems)
            local amax = tonumber(info.quantityMax) or amin
            if amin and amin > 0 then
                qtyMin = amin
            end
            if amax and amax > 0 then
                qtyMax = amax
            end
        end
    end
    return qtyMin, qtyMax
end

local function PulseProfessionsChanged()
    -- Recipe load/change must drop craft best cache even when bag gen is unchanged.
    local Craft = Inv.Craft
    if Craft and Craft.InvalidateCanCraftCache then
        Craft.InvalidateCanCraftCache()
    end
    if Inv.Notify then
        Inv.Notify({ professions = true })
    end
end

local function ScanModernOpenProfession(source)
    if not HasModernRecipeList() then
        return nil
    end
    if TradeSkillDataNotReady() then
        return nil
    end
    local recipeIDs = ListOpenRecipeIDs()
    if type(recipeIDs) ~= "table" or #recipeIDs == 0 then
        return nil
    end
    local skillLineID, skillName
    local info = Prof.GetOpenProfessionInfo()
    if type(info) == "table" then
        -- OpenTradeSkill wants the parent skill line when child expansion lines exist.
        skillLineID = info.parentProfessionID or info.professionID or info.skillLineID
        skillName = info.parentProfessionName or info.professionName or info.displayName
    end
    if not skillLineID and GetTradeSkillLine then
        skillName = select(1, GetTradeSkillLine())
        skillLineID = skillName
    end
    skillLineID = skillLineID or skillName or "current"
    local prevByRecipeID = {}
    local prevData = LoadSkill(skillLineID)
    if prevData and prevData.recipes then
        for _, prev in ipairs(prevData.recipes) do
            if prev and prev.recipeID then
                prevByRecipeID[prev.recipeID] = prev
            end
        end
    end
    local recipes = {}
    for _, recipeID in ipairs(recipeIDs) do
        local okInfo, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if okInfo and type(info) == "table"
            and not info.isDummyRecipe
            and not info.isGatheringRecipe
            and not info.isEnchantingRecipe
            and not info.isSalvageRecipe then
            -- Persist known recipes only (matches "character know").
            local learned = info.learned ~= false
            if learned then
                local outputItemID, link = ExtractModernOutput(recipeID)
                local qtyMin, qtyMax = ExtractModernQuantity(recipeID)
                local reagents = ExtractModernReagents(recipeID)
                -- Half-ready opens can return empty reagents; keep prior known mats.
                if #reagents == 0 then
                    local prev = prevByRecipeID[recipeID]
                    if prev and type(prev.reagents) == "table" and #prev.reagents > 0 then
                        reagents = prev.reagents
                    end
                end
                recipes[#recipes + 1] = {
                    recipeID = recipeID,
                    name = info.name,
                    learned = true,
                    craftable = info.craftable and true or false,
                    outputItemID = outputItemID or (prevByRecipeID[recipeID] and prevByRecipeID[recipeID].outputItemID),
                    outputLink = link or (prevByRecipeID[recipeID] and prevByRecipeID[recipeID].outputLink),
                    quantityMin = qtyMin,
                    quantityMax = qtyMax,
                    reagents = reagents,
                    legacy = false,
                    skillLineID = skillLineID,
                    skillName = skillName,
                }
            end
        end
    end
    local payload = {
        recipes = recipes,
        scannedAt = Now(),
        source = source or "open",
        name = skillName,
        needsOpen = false,
    }
    StoreSkill(skillLineID, payload)
    -- Also index by profession name for Classic-style lookups.
    if skillName and tostring(skillName) ~= tostring(skillLineID) then
        StoreSkill(skillName, payload)
    end
    openSkillKey = tostring(skillLineID)
    if source == "open" then
        PulseProfessionsChanged()
    end
    return payload
end

local function ExtractLegacyReagents(skillIndex)
    local reagents = {}
    if not GetTradeSkillNumReagents or not GetTradeSkillReagentInfo then
        return reagents
    end
    local n = GetTradeSkillNumReagents(skillIndex) or 0
    for i = 1, n do
        local name, _, reagentCount, playerCount = GetTradeSkillReagentInfo(skillIndex, i)
        local itemID
        if GetTradeSkillReagentItemLink then
            local link = GetTradeSkillReagentItemLink(skillIndex, i)
            if link then
                itemID = tonumber(link:match("item:(%d+)"))
            end
        end
        reagents[#reagents + 1] = {
            itemID = itemID,
            name = name,
            count = reagentCount or 1,
            playerCount = playerCount,
        }
    end
    return reagents
end

local function ScanLegacyOpenProfession(source)
    if not (GetNumTradeSkills and GetTradeSkillInfo) then
        return nil
    end
    local skillName = GetTradeSkillLine and select(1, GetTradeSkillLine()) or "legacy"
    if not skillName or skillName == "" or skillName == "UNKNOWN" then
        return nil
    end
    local recipes = {}
    local num = GetNumTradeSkills() or 0
    for i = 1, num do
        local name, skillType = GetTradeSkillInfo(i)
        if name and skillType and skillType ~= "header" and skillType ~= "subheader" then
            local itemLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i)
            local itemID = itemLink and tonumber(itemLink:match("item:(%d+)")) or nil
            local qtyMin, qtyMax = 1, 1
            if GetTradeSkillNumMade then
                qtyMin, qtyMax = GetTradeSkillNumMade(i)
            end
            recipes[#recipes + 1] = {
                recipeID = i,
                name = name,
                learned = true,
                craftable = true,
                outputItemID = itemID,
                outputLink = itemLink,
                quantityMin = qtyMin,
                quantityMax = qtyMax,
                reagents = ExtractLegacyReagents(i),
                legacy = true,
                skillName = skillName,
            }
        end
    end
    local payload = {
        recipes = recipes,
        scannedAt = Now(),
        source = source or "open",
        name = skillName,
        needsOpen = false,
    }
    StoreSkill(skillName, payload)
    openSkillKey = skillName
    if source == "open" then
        PulseProfessionsChanged()
    end
    return payload
end

local function ScanOpenProfession(source)
    if scanBusy then
        return nil
    end
    scanBusy = true
    local ok, payload = pcall(function()
        if HAS_MODERN_PROF and HasModernRecipeList() then
            local modern = ScanModernOpenProfession(source)
            if modern then
                return modern
            end
        end
        return ScanLegacyOpenProfession(source)
    end)
    scanBusy = false
    if ok then
        return payload
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Tier C — live lookups
-- ---------------------------------------------------------------------------

function Prof.GetRecipeLive(recipeID)
    recipeID = tonumber(recipeID) or recipeID
    if not recipeID then
        return nil, "none"
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if ok and type(info) == "table" then
            local outputItemID = ExtractModernOutput(recipeID)
            local qtyMin, qtyMax = ExtractModernQuantity(recipeID)
            return {
                recipeID = recipeID,
                name = info.name,
                learned = info.learned and true or false,
                craftable = info.craftable and true or false,
                outputItemID = outputItemID,
                quantityMin = qtyMin,
                quantityMax = qtyMax,
                reagents = ExtractModernReagents(recipeID),
                legacy = false,
                source = "live",
            }, "live"
        end
    end
    return nil, "none"
end

function Prof.GetCompleteness(skillKey)
    skillKey = skillKey and tostring(skillKey) or openSkillKey
    if not skillKey then
        return "none"
    end
    -- Live: if this skill is currently open and modern APIs return recipes
    if openSkillKey and tostring(openSkillKey) == skillKey then
        local ids = ListOpenRecipeIDs()
        if type(ids) == "table" and #ids > 0 then
            return "live"
        end
        if GetNumTradeSkills and (GetNumTradeSkills() or 0) > 0 then
            return "live"
        end
    end
    local data = LoadSkill(skillKey)
    if not data or not data.recipes then
        return "none"
    end
    if data.needsOpen then
        return "partial"
    end
    if data.source == "open" then
        return "cached"
    end
    if data.source == "login" then
        return "cached"
    end
    if data.source == "live" then
        return "live"
    end
    return #data.recipes > 0 and "cached" or "none"
end

-- ---------------------------------------------------------------------------
-- Public query API (Tier C then cache)
-- ---------------------------------------------------------------------------

function Prof.GetRecipe(recipeID, skillKey)
    local live, completeness = Prof.GetRecipeLive(recipeID)
    if live then
        return live, completeness
    end
    skillKey = skillKey and tostring(skillKey) or openSkillKey
    if skillKey then
        local data = LoadSkill(skillKey)
        if data and data.recipes then
            for _, r in ipairs(data.recipes) do
                if r.recipeID == recipeID then
                    return r, Prof.GetCompleteness(skillKey)
                end
            end
        end
    end
    -- Search all cached skills
    local db = EnsureDB()
    for key, data in pairs(db.bySkillLine) do
        if data.recipes then
            for _, r in ipairs(data.recipes) do
                if r.recipeID == recipeID then
                    return r, Prof.GetCompleteness(key)
                end
            end
        end
    end
    return nil, "none"
end

function Prof.GetReagents(recipeID, skillKey)
    local recipe = Prof.GetRecipe(recipeID, skillKey)
    return recipe and recipe.reagents or nil
end

function Prof.GetOutput(recipeID, skillKey)
    local recipe = Prof.GetRecipe(recipeID, skillKey)
    if not recipe then
        return nil
    end
    return recipe.outputItemID, recipe.outputLink
end

function Prof.IsLearned(recipeID, skillKey)
    local recipe = Prof.GetRecipe(recipeID, skillKey)
    if recipe then
        return recipe.learned == true
    end
    if C_TradeSkillUI and C_TradeSkillUI.IsRecipeProfessionLearned then
        local ok, learned = pcall(C_TradeSkillUI.IsRecipeProfessionLearned, recipeID)
        if ok then
            return learned and true or false
        end
    end
    return false
end

function Prof.ListCachedRecipes(skillKey)
    skillKey = skillKey and tostring(skillKey) or openSkillKey
    if not skillKey then
        return {}, "none"
    end
    local data = LoadSkill(skillKey)
    if not data or not data.recipes then
        return {}, Prof.GetCompleteness(skillKey)
    end
    return data.recipes, Prof.GetCompleteness(skillKey)
end

function Prof.ListSkillKeys()
    local db = EnsureDB()
    local keys = {}
    for key in pairs(db.bySkillLine) do
        keys[#keys + 1] = key
    end
    return keys
end

function Prof.GetSkillInfo(skillKey)
    skillKey = tostring(skillKey)
    return LoadSkill(skillKey)
end

-- ---------------------------------------------------------------------------
-- Tier A — profession UI open (authoritative)
-- ---------------------------------------------------------------------------

function Prof.OnProfessionEvent(event, arg1, arg2)
    if TradeSkillDataNotReady() then
        return
    end
    if event == "NEW_RECIPE_LEARNED" then
        -- Rescan if profession is open; else mark needs refresh
        if TradeSkillFrame and TradeSkillFrame:IsShown()
            or (ProfessionsFrame and ProfessionsFrame:IsShown()) then
            ScanOpenProfession("open")
        elseif openSkillKey then
            local data = LoadSkill(openSkillKey)
            if data then
                data.needsOpen = true
                StoreSkill(openSkillKey, data)
            end
            PulseProfessionsChanged()
        end
        if Inv.Craft and Inv.Craft.TryFlushPendingCraft then
            Inv.Craft.TryFlushPendingCraft()
        end
        return
    end
    ScanOpenProfession("open")
    if Inv.Craft and Inv.Craft.TryFlushPendingCraft then
        Inv.Craft.TryFlushPendingCraft()
    end
end

--- All cached recipes across every skill line for this character.
function Prof.ListAllCachedRecipes()
    local db = EnsureDB()
    local out = {}
    local seen = {}
    for key, data in pairs(db.bySkillLine) do
        if data and data.recipes then
            for _, r in ipairs(data.recipes) do
                local id = r.recipeID
                local uniq = tostring(key) .. ":" .. tostring(id) .. ":" .. tostring(r.legacy and 1 or 0)
                if not seen[uniq] then
                    seen[uniq] = true
                    out[#out + 1] = r
                end
            end
        end
    end
    return out
end

function Prof.OnProfessionClosed()
    openSkillKey = nil
end

function Prof.OnEventPulse()
    -- no-op; scan happens in OnProfessionEvent
end

-- ---------------------------------------------------------------------------
-- Tier B — paced login scan
-- ---------------------------------------------------------------------------

local function SkillNameMatches(name, needles)
    if type(name) ~= "string" or name == "" or type(needles) ~= "table" then
        return false
    end
    local n = name:lower()
    for i = 1, #needles do
        local needle = needles[i]
        if type(needle) == "string" and needle ~= "" then
            needle = needle:lower()
            if n:find(needle, 1, true) then
                return true
            end
        end
    end
    return false
end

-- Rank lookup includes skill-pane lines (Comprehension, weapons, etc.) that
-- GetProfessions never returns. Login recipe scans still use the profession
-- book only — do not open those extra lines with OpenTradeSkill.
local rankLinesCache = nil
local itemReqCache = {} -- [itemID] = false | { skillName, required, color }

local COLOR_WHITE = CreateColor and CreateColor(1, 1, 1)

local function ColorLooksWhite(c)
    if not c then
        return false
    end
    if COLOR_WHITE and c.IsRGBEqualTo then
        return c:IsRGBEqualTo(COLOR_WHITE) and true or false
    end
    local r, g, b = c.r, c.g, c.b
    if type(c.GetRGB) == "function" then
        r, g, b = c:GetRGB()
    end
    return (tonumber(r) or 0) > 0.9 and (tonumber(g) or 0) > 0.9 and (tonumber(b) or 0) > 0.9
end

local function ColorLooksRed(c)
    if not c then
        return false
    end
    local r, g, b = c.r, c.g, c.b
    if type(c.GetRGB) == "function" then
        r, g, b = c:GetRGB()
    end
    r, g, b = tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0
    return r > 0.9 and g < 0.35 and b < 0.35
end

local function ParseSkillRequirementFromText(text)
    if type(text) ~= "string" or text == "" then
        return nil, nil
    end
    local lower = text:lower()
    for skillName, req in lower:gmatch("requires%s*:?%s*([%a][%a%s%-%']-)%s*%(?%s*(%d+)%s*%)?") do
        skillName = skillName:gsub("^%s+", ""):gsub("%s+$", "")
        if skillName ~= "" and skillName ~= "level" and not skillName:find("level", 1, true) then
            return skillName, tonumber(req)
        end
    end
    -- "Requires Comprehension" with no number yet, or "Comprehension (75)" alone.
    local skillOnly, reqOnly = lower:match("([%a][%a%s%-%']-)%s*%(%s*(%d+)%s*%)")
    if skillOnly then
        skillOnly = skillOnly:gsub("^%s+", ""):gsub("%s+$", "")
        if skillOnly ~= "" and skillOnly ~= "level" and not skillOnly:find("level", 1, true) then
            return skillOnly, tonumber(reqOnly)
        end
    end
    local named = lower:match("requires%s*:?%s*([%a][%a%s%-%']+)")
    if named then
        named = named:gsub("^%s+", ""):gsub("%s+$", "")
        if named ~= "" and named ~= "level" and not named:find("level", 1, true) then
            return named, 1
        end
    end
    return nil, nil
end

function Prof.InvalidateSkillCaches()
    rankLinesCache = nil
    wipe(itemReqCache)
end

--- Forever C_SkillInfo returns a SkillLineAttributes table. Classic GetSkillLineInfo
--- still returns name, isHeader, _, rank. Accept both so Comprehension is visible.
local function SkillLineNameAndRank(index)
    if C_SkillInfo and C_SkillInfo.GetSkillLineInfo then
        local ok, info = pcall(C_SkillInfo.GetSkillLineInfo, index)
        if ok and type(info) == "table" then
            local name = info.name
            local rank = tonumber(info.rank) or tonumber(info.currentRank) or tonumber(info.skillRank) or 0
            if type(name) == "string" and name ~= "" then
                if info.isHeader and rank <= 0 then
                    return
                end
                return name, rank, tonumber(info.skillID)
            end
            return
        end
    end
    if not GetSkillLineInfo then
        return
    end
    local a, b, _, d = GetSkillLineInfo(index)
    if type(a) == "table" then
        if a.isHeader then
            return
        end
        local name = a.name
        if type(name) == "string" and name ~= "" then
            return name, tonumber(a.rank) or 0, tonumber(a.skillID)
        end
        return
    end
    if type(a) == "string" and a ~= "" and not b then
        return a, tonumber(d) or 0
    end
end

local function GetPlayerProfessionSkillLines()
    local lines = {}
    local seen = {}
    local function addLine(id, name, modern, rank)
        local key = id or name
        if not key or seen[tostring(key)] then
            return
        end
        if name and seen["n:" .. name:lower()] then
            return
        end
        seen[tostring(key)] = true
        if name then
            seen["n:" .. name:lower()] = true
        end
        lines[#lines + 1] = {
            id = key,
            name = name,
            modern = modern and true or false,
            rank = tonumber(rank) or 0,
        }
    end
    -- Prefer GetProfessions: only skills the player actually has.
    -- GetAllProfessionTradeSkillLines can return a broader set and caused
    -- login scans to open unrelated lines / wipe caches on failure.
    if GetProfessions and GetProfessionInfo then
        -- Forever book: prof1, prof2, firstAid, fishing, cooking.
        -- Live: prof1, prof2, archaeology, fishing, cooking, firstAid.
        -- Iterate every returned index instead of assuming a slot map.
        local indices = { GetProfessions() }
        for i = 1, #indices do
            local idx = indices[i]
            if idx then
                local name, _, rank, _, _, _, skillLine = GetProfessionInfo(idx)
                addLine(skillLine or name, name, HAS_MODERN_PROF and type(skillLine) == "number", rank)
            end
        end
        if #lines > 0 then
            return lines
        end
    end
    -- Classic Era / TBC: First Aid and professions live on the skill pane.
    if GetNumSkillLines and GetSkillLineInfo then
        local n = GetNumSkillLines() or 0
        for i = 1, n do
            local name, isHeader, _, rank = GetSkillLineInfo(i)
            if name and not isHeader then
                local lname = name:lower()
                if lname:find("alchemy", 1, true)
                    or lname:find("first aid", 1, true)
                    or lname:find("tailoring", 1, true)
                    or lname:find("engineering", 1, true) then
                    addLine(name, name, false, rank)
                end
            end
        end
        if #lines > 0 then
            return lines
        end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines then
        local ok, all = pcall(C_TradeSkillUI.GetAllProfessionTradeSkillLines)
        if ok and type(all) == "table" then
            for _, id in ipairs(all) do
                if id and not seen[tostring(id)] then
                    addLine(id, nil, true, 0)
                end
            end
        end
    end
    return lines
end

--- GetProfessions plus every non-header skill-pane row (Comprehension, etc.).
local function GetPlayerRankSkillLines()
    if rankLinesCache then
        return rankLinesCache
    end
    local lines = {}
    local seen = {}
    local function addLine(id, name, modern, rank)
        local key = id or name
        if not key or seen[tostring(key)] then
            return
        end
        if name and seen["n:" .. name:lower()] then
            return
        end
        seen[tostring(key)] = true
        if name then
            seen["n:" .. name:lower()] = true
        end
        lines[#lines + 1] = {
            id = key,
            name = name,
            modern = modern and true or false,
            rank = tonumber(rank) or 0,
        }
    end
    if GetProfessions and GetProfessionInfo then
        local indices = { GetProfessions() }
        for i = 1, #indices do
            local idx = indices[i]
            if idx then
                local name, _, rank, _, _, _, skillLine = GetProfessionInfo(idx)
                addLine(skillLine or name, name, HAS_MODERN_PROF and type(skillLine) == "number", rank)
            end
        end
    end
    local n = 0
    if C_SkillInfo and C_SkillInfo.GetNumSkillLines then
        local ok, count = pcall(C_SkillInfo.GetNumSkillLines)
        if ok then
            n = tonumber(count) or 0
        end
    end
    if n <= 0 and GetNumSkillLines then
        n = tonumber(GetNumSkillLines()) or 0
    end
    for i = 1, n do
        local name, rank = SkillLineNameAndRank(i)
        if name then
            addLine(name, name, false, rank)
        end
    end
    rankLinesCache = lines
    return lines
end

--- True when the player has a profession whose name contains any needle.
function Prof.HasProfessionName(needles)
    if type(needles) == "string" then
        needles = { needles }
    end
    local lines = GetPlayerRankSkillLines()
    for i = 1, #lines do
        if SkillNameMatches(lines[i].name, needles) then
            return true
        end
    end
    return false
end

--- Current rank for a profession name, or 0 if unknown / unlearned.
function Prof.GetProfessionRank(needles)
    if type(needles) == "string" then
        needles = { needles }
    end
    local lines = GetPlayerRankSkillLines()
    for i = 1, #lines do
        if SkillNameMatches(lines[i].name, needles) then
            return tonumber(lines[i].rank) or 0
        end
    end
    return 0
end

--- Secondary / weapon / class skill-pane rank (Forever C_SkillInfo). Not GetProfessions.
--- Comprehension lives here; it is not a crafting profession.
function Prof.GetSkillLineRank(needles)
    if type(needles) == "string" then
        needles = { needles }
    end
    local n = 0
    if C_SkillInfo and C_SkillInfo.GetNumSkillLines then
        local ok, count = pcall(C_SkillInfo.GetNumSkillLines)
        if ok then
            n = tonumber(count) or 0
        end
    end
    if n <= 0 and GetNumSkillLines then
        n = tonumber(GetNumSkillLines()) or 0
    end
    local best = 0
    for i = 1, n do
        local name, rank = SkillLineNameAndRank(i)
        if SkillNameMatches(name, needles) then
            rank = tonumber(rank) or 0
            if rank > best then
                best = rank
            end
        end
    end
    return best
end

local function RequirementRecord(parsed)
    if not parsed or not parsed.skillName then
        return nil
    end
    local rank = Prof.GetSkillLineRank({ parsed.skillName })
    if rank <= 0 then
        rank = Prof.GetProfessionRank({ parsed.skillName })
    end
    local required = tonumber(parsed.required) or 0
    local met = false
    if parsed.color == "white" then
        met = true
    elseif parsed.color == "red" then
        met = false
    else
        met = rank >= required
    end
    if not met and rank >= required and parsed.color ~= "red" then
        met = true
    end
    return {
        skillName = parsed.skillName,
        required = parsed.required,
        met = met,
    }
end

--- Parse a single tooltip line / blob for "Requires Skill (N)".
function Prof.GetSkillRequirementFromText(text, colorHint)
    local skillName, required = ParseSkillRequirementFromText(text)
    if not skillName then
        return nil
    end
    return RequirementRecord({
        skillName = skillName,
        required = required or 1,
        color = colorHint or "other",
    })
end

--- Read the live GameTooltip (Alt-hover) so Forever RestrictedSkill lines are not missed.
function Prof.GetSkillRequirementFromTooltip(tooltip)
    if not tooltip or not tooltip.NumLines then
        return nil, false
    end
    local n = tooltip:NumLines() or 0
    if n < 2 then
        return nil, false
    end
    local prefix = tooltip.GetName and tooltip:GetName()
    for i = 2, math.min(n, 40) do
        local fs = prefix and _G[prefix .. "TextLeft" .. i]
        if not fs then
            fs = tooltip["TextLeft" .. i]
        end
        local text = fs and fs.GetText and fs:GetText()
        local colorHint = "other"
        if fs and fs.GetTextColor then
            local r, g, b = fs:GetTextColor()
            if r and g and b then
                if r > 0.9 and g > 0.9 and b > 0.9 then
                    colorHint = "white"
                elseif r > 0.9 and g < 0.35 and b < 0.35 then
                    colorHint = "red"
                end
            end
        end
        local rec = Prof.GetSkillRequirementFromText(text, colorHint)
        if rec then
            return rec, true
        end
    end
    return nil, true
end

function Prof.GetSkillRequirementFromTooltipData(data)
    if type(data) ~= "table" or type(data.lines) ~= "table" then
        return nil, false
    end
    local lineTypes = Enum and Enum.TooltipDataLineType
    for i = 1, #data.lines do
        local line = data.lines[i]
        if line and TooltipUtil and TooltipUtil.SurfaceArgs then
            pcall(TooltipUtil.SurfaceArgs, line)
        end
        local text = line and (line.leftText or line.rightText)
        local colorHint = "other"
        if lineTypes and line and line.type == lineTypes.RestrictedSkill then
            if ColorLooksWhite(line.leftColor) then
                colorHint = "white"
            elseif ColorLooksRed(line.leftColor) then
                colorHint = "red"
            end
        end
        local rec = Prof.GetSkillRequirementFromText(text, colorHint)
        if rec then
            return rec, true
        end
    end
    return nil, true
end

--- Forever combined bags: RestrictedSkill often exists on the bag-slot tooltip, not GetItemByID.
function Prof.GetSkillRequirementFromBagSlot(bagID, slotID)
    bagID = tonumber(bagID)
    slotID = tonumber(slotID)
    if not bagID or not slotID or not C_TooltipInfo or not C_TooltipInfo.GetBagItem then
        return nil, false
    end
    local ok, data = pcall(C_TooltipInfo.GetBagItem, bagID, slotID)
    if not ok or type(data) ~= "table" then
        return nil, false
    end
    if TooltipUtil and TooltipUtil.SurfaceArgs then
        pcall(TooltipUtil.SurfaceArgs, data)
    end
    return Prof.GetSkillRequirementFromTooltipData(data)
end

local function TooltipDataForItem(itemID)
    itemID = tonumber(itemID)
    if not itemID or not C_TooltipInfo then
        return nil
    end
    if C_TooltipInfo.GetItemByID then
        local ok, data = pcall(C_TooltipInfo.GetItemByID, itemID)
        if ok and type(data) == "table" and data.lines then
            return data
        end
    end
    if C_TooltipInfo.GetHyperlink then
        local IC = _G.FluxItemClass
        local link = (IC and IC.GetLink and IC.GetLink(itemID)) or ("item:" .. itemID)
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
        if ok and type(data) == "table" and data.lines then
            return data
        end
    end
    return nil
end

local function RequirementFromRestrictedSkill(data)
    local lineTypes = Enum and Enum.TooltipDataLineType
    if not (data and data.lines and lineTypes and lineTypes.RestrictedSkill) then
        return nil
    end
    for i = 1, #data.lines do
        local line = data.lines[i]
        if line and TooltipUtil and TooltipUtil.SurfaceArgs then
            pcall(TooltipUtil.SurfaceArgs, line)
        end
        if line and line.type == lineTypes.RestrictedSkill then
            local text = line.leftText or line.rightText
            local skillName, required = ParseSkillRequirementFromText(text)
            if not skillName and type(text) == "string" then
                skillName = text:lower():gsub("^requires%s+", ""):gsub("%s*%(%s*%d+%s*%).*$", ""):gsub("%s+$", "")
                if skillName == "" or skillName == "level" then
                    skillName = nil
                end
            end
            if skillName then
                local color = "other"
                if ColorLooksWhite(line.leftColor) then
                    color = "white"
                elseif ColorLooksRed(line.leftColor) then
                    color = "red"
                end
                return {
                    skillName = skillName,
                    required = tonumber(required) or 1,
                    color = color,
                }
            end
        end
    end
    return nil
end

--- Parse "Requires Comprehension (X)" (and the same form for other skills).
--- Returns `{ skillName, required, met }, ready`. Inconclusive tooltip → nil, false
--- (do not cache a miss). Loaded tooltip with no skill line → nil, true.
function Prof.GetItemSkillRequirement(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil, false
    end
    local cached = itemReqCache[itemID]
    if cached ~= nil then
        if cached == false then
            return nil, true
        end
        return RequirementRecord(cached), true
    end

    local data = TooltipDataForItem(itemID)
    local parsed = RequirementFromRestrictedSkill(data)
    if not parsed then
        local IC = _G.FluxItemClass
        local text
        if IC and IC.GetTooltipText then
            local link = IC.GetLink and IC.GetLink(itemID) or ("item:" .. itemID)
            text = IC.GetTooltipText(itemID, link)
        end
        if (not text or text == "") and data and data.lines then
            local parts = {}
            for i = 1, #data.lines do
                local line = data.lines[i]
                local t = line and (line.leftText or line.rightText)
                if t and t ~= "" then
                    parts[#parts + 1] = t
                end
            end
            if #parts > 0 then
                text = table.concat(parts, "\n")
            end
        end
        if text and text ~= "" then
            local skillName, required = ParseSkillRequirementFromText(text)
            if skillName and required then
                parsed = {
                    skillName = skillName,
                    required = required,
                    color = "other",
                }
            end
        end
        local linesReady = data and data.lines and #data.lines >= 2
        if not parsed and not linesReady and (not text or text == "") then
            return nil, false
        end
    end

    if not parsed then
        -- Forever bag tooltips carry RestrictedSkill that GetItemByID often omits.
        local Client = Flux and Flux.Client
        if Client and (Client.isCamelot or Client.isForever) then
            return nil, false
        end
        itemReqCache[itemID] = false
        return nil, true
    end

    itemReqCache[itemID] = {
        skillName = parsed.skillName,
        required = parsed.required,
        color = parsed.color or "other",
    }
    return Prof.GetItemSkillRequirement(itemID)
end

local function CanAttemptOpen()
    if InCombat() then
        return false
    end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
        return false
    end
    return true
end

local function CloseTradeSkillQuiet()
    if C_TradeSkillUI and C_TradeSkillUI.CloseTradeSkill then
        pcall(C_TradeSkillUI.CloseTradeSkill)
    elseif CloseTradeSkill then
        pcall(CloseTradeSkill)
    end
end

local function OpenModernSkill(skillLineID)
    if C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
        return pcall(C_TradeSkillUI.OpenTradeSkill, skillLineID)
    end
    return false
end

local function OpenLegacyByName(name)
    if not name or name == "" then
        return false
    end
    if CastSpellByName then
        local ok = pcall(CastSpellByName, name)
        return ok
    end
    return false
end

--- Mark player professions that lack recipe data. Do NOT call OpenTradeSkill from
--- timers — it is protected on retail and used to wipe good caches with {}.
function Prof.ScheduleLoginScan()
    if loginScanCompleted or loginScanQueued or loginScanRunning then
        return
    end
    loginScanQueued = true
    loginScanAbort = false
    After(3.0, function()
        loginScanQueued = false
        if loginScanCompleted then
            return
        end
        local queue = GetPlayerProfessionSkillLines()
        for _, entry in ipairs(queue) do
            local key = entry.id or entry.name
            if key then
                local existing = LoadSkill(key)
                local recipes = (existing and existing.recipes) or {}
                if #recipes == 0 then
                    StoreSkill(key, {
                        recipes = recipes,
                        scannedAt = (existing and existing.scannedAt) or Now(),
                        source = (existing and existing.source) or "login",
                        name = entry.name or (existing and existing.name),
                        needsOpen = true,
                    })
                end
            end
        end
        loginScanCompleted = true
        loginScanRunning = false
        -- Soft pulse so ExtraButtons re-evaluate craft binds against existing cache.
        PulseProfessionsChanged()
    end)
end

function Prof.AbortLoginScan()
    loginScanAbort = true
    loginScanRunning = false
end

-- Kept for ForceScan / manual callers; login path no longer auto-opens.
local function RunLoginScanStep(queue, index)
    if loginScanAbort or not loginScanRunning then
        loginScanRunning = false
        return
    end
    if InCombat() then
        loginScanRunning = false
        return
    end
    if index > #queue then
        loginScanRunning = false
        loginScanCompleted = true
        CloseTradeSkillQuiet()
        return
    end
    local entry = queue[index]
    if not CanAttemptOpen() then
        local key = entry.id or entry.name or index
        local existing = LoadSkill(key)
        StoreSkill(key, {
            recipes = (existing and existing.recipes) or {},
            scannedAt = Now(),
            source = "login",
            name = entry.name,
            needsOpen = true,
        })
        After(0.35, function()
            RunLoginScanStep(queue, index + 1)
        end)
        return
    end

    local opened = false
    if entry.modern and entry.id then
        opened = OpenModernSkill(entry.id)
    elseif entry.name then
        opened = OpenLegacyByName(entry.name)
    elseif entry.id and type(entry.id) == "number" then
        opened = OpenModernSkill(entry.id)
    end

    After(0.6, function()
        if loginScanAbort then
            loginScanRunning = false
            CloseTradeSkillQuiet()
            return
        end
        local payload = ScanOpenProfession("login")
        if not payload then
            local key = entry.id or entry.name or index
            local existing = LoadSkill(key)
            StoreSkill(key, {
                recipes = (existing and existing.recipes) or {},
                scannedAt = Now(),
                source = "login",
                name = entry.name,
                needsOpen = true,
            })
        end
        CloseTradeSkillQuiet()
        After(0.45, function()
            RunLoginScanStep(queue, index + 1)
        end)
    end)
end

--- Force a fresh open-profession scan (ignores once-per-session login flag).
function Prof.ForceScanOpen()
    return ScanOpenProfession("open")
end

--- Allow a new login-style profession scan (e.g. after learning a profession).
function Prof.ResetLoginScanState()
    loginScanCompleted = false
    loginScanQueued = false
    loginScanRunning = false
    loginScanAbort = false
end

local eventFrame = CreateFrame("Frame")
SafeRegisterEvent(eventFrame, "PLAYER_ENTERING_WORLD")
SafeRegisterEvent(eventFrame, "PLAYER_REGEN_DISABLED")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_SHOW")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_CLOSE")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_UPDATE")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_LIST_UPDATE")
SafeRegisterEvent(eventFrame, "NEW_RECIPE_LEARNED")
SafeRegisterEvent(eventFrame, "TRADE_SKILL_DATA_SOURCE_CHANGED")
SafeRegisterEvent(eventFrame, "SKILL_LINES_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "SKILL_LINES_CHANGED" then
        Prof.InvalidateSkillCaches()
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        Prof.ScheduleLoginScan()
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        Prof.AbortLoginScan()
        return
    end
    if event == "TRADE_SKILL_CLOSE" then
        Prof.OnProfessionClosed()
        return
    end
    Prof.OnProfessionEvent(event, arg1, arg2)
end)

local FluxInv = _G.FluxInv
if FluxInv then
    FluxInv.Professions = Prof
end
