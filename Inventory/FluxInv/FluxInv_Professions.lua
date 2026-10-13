--[[
    Inventory/FluxInv/FluxInv_Professions.lua

    Layered profession recipe cache:
      Tier C — live API when data is loaded
      Tier B — paced login/reload scan (best-effort; aborts in combat)
      Tier A — authoritative scan when profession UI is open
]]

FluxInv = FluxInv or {}
local Inv = FluxInv
Inv.Professions = Inv.Professions or {}
local Prof = Inv.Professions

local Compat = function()
    return Inv.Compat
end

FluxInvDB = FluxInvDB or {}

local sessionCache = {} -- skillKey -> { recipes, scannedAt, source, name }
local loginScanQueued = false
local loginScanRunning = false
local loginScanAbort = false
local loginScanCompleted = false
local openSkillKey = nil

local function CharKey()
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
    if Inv.Events and Inv.Events.Pulse then
        Inv.Events.Pulse("scan", { "professions" })
    end
end

local function ScanModernOpenProfession(source)
    if not (C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs) then
        return nil
    end
    local ok, recipeIDs = pcall(C_TradeSkillUI.GetAllRecipeIDs)
    if not ok or type(recipeIDs) ~= "table" or #recipeIDs == 0 then
        return nil
    end
    local skillLineID, skillName
    if C_TradeSkillUI.GetProfessionInfo then
        local ok2, info = pcall(C_TradeSkillUI.GetProfessionInfo)
        if ok2 and type(info) == "table" then
            skillLineID = info.professionID or info.skillLineID or info.parentProfessionID
            skillName = info.professionName or info.parentProfessionName
        end
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
        if okInfo and type(info) == "table" then
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
    local compat = Compat()
    if compat.HAS_MODERN_PROF and C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
        local payload = ScanModernOpenProfession(source)
        if payload then
            return payload
        end
    end
    return ScanLegacyOpenProfession(source)
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
        if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
            local ok, ids = pcall(C_TradeSkillUI.GetAllRecipeIDs)
            if ok and type(ids) == "table" and #ids > 0 then
                return "live"
            end
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

local function GetPlayerProfessionSkillLines()
    local lines = {}
    local seen = {}
    -- Prefer GetProfessions: only skills the player actually has.
    -- GetAllProfessionTradeSkillLines can return a broader set and caused
    -- login scans to open unrelated lines / wipe caches on failure.
    if GetProfessions and GetProfessionInfo then
        local p1, p2, arch, fish, cook, firstAid = GetProfessions()
        for _, idx in ipairs({ p1, p2, arch, fish, cook, firstAid }) do
            if idx then
                local name, _, _, _, _, _, skillLine = GetProfessionInfo(idx)
                local key = skillLine or name
                if name and key and not seen[tostring(key)] then
                    seen[tostring(key)] = true
                    lines[#lines + 1] = {
                        id = skillLine or name,
                        name = name,
                        modern = Compat().HAS_MODERN_PROF and type(skillLine) == "number",
                    }
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
                    seen[tostring(id)] = true
                    lines[#lines + 1] = { id = id, modern = true }
                end
            end
        end
    end
    return lines
end

local function CanAttemptOpen()
    if Compat().InCombat() then
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
    Compat().After(3.0, function()
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
    if Compat().InCombat() then
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
        Compat().After(0.35, function()
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

    Compat().After(0.6, function()
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
        Compat().After(0.45, function()
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

_G.FluxInv = Inv
