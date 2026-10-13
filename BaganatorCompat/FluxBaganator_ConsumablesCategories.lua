-- FluxBaganator_ConsumablesCategories.lua
-- Dedicated Baganator section "Consumable Presets" with one subcategory per Flux
-- NC consumables preset (including "default"). Items listed in any Flux preset are
-- claimed via custom category addedItems (higher priority) so they leave
-- Baganator's built-in Consumable / Potion / Food categories.

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local SECTION_NAME = "Consumable Presets"
local SECTION_END = "__end"
local SOURCE_PREFIX = "flux_nc_cons_"
local PRIORITY = 1 -- HIGH: effective 400, beats default_potion/food/consumable

local function GetActiveBaganatorConfig()
    local config = _G.BAGANATOR_CONFIG
    if type(config) ~= "table" then
        return nil
    end
    if type(config.Profiles) == "table" then
        local profileName = _G.BAGANATOR_CURRENT_PROFILE or "DEFAULT"
        return config.Profiles[profileName] or config.Profiles.DEFAULT
    end
    return config
end

local function IndexOf(list, value)
    if type(list) ~= "table" then
        return nil
    end
    for i = 1, #list do
        if list[i] == value then
            return i
        end
    end
end

local function IsSectionStart(source)
    return type(source) == "string" and source:sub(1, 1) == "_" and source ~= SECTION_END
end

local function SectionIdFromToken(source)
    if IsSectionStart(source) then
        return source:sub(2)
    end
end

local function NextFreeSectionId(sections)
    local id = 1
    while sections[tostring(id)] do
        id = id + 1
    end
    return tostring(id)
end

local function FindSectionNamed(sections, name)
    for id, details in pairs(sections) do
        if details and details.name == name then
            return tostring(id)
        end
    end
end

local function IsFluxConsumablesSource(source)
    return type(source) == "string" and source:sub(1, #SOURCE_PREFIX) == SOURCE_PREFIX
end

local function SanitizePresetKey(presetName)
    local key = tostring(presetName or "default"):lower()
    key = key:gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if key == "" then
        key = "default"
    end
    return SOURCE_PREFIX .. key
end

local function DisplayNameForPreset(presetName)
    if presetName == "default" then
        return "Default"
    end
    return tostring(presetName)
end

local function RequestCategoryLayoutRefresh()
    local api = _G.Baganator and _G.Baganator.API
    if not api then
        return
    end
    local reasons = {}
    local constants = _G.Baganator and _G.Baganator.Constants
    local rr = constants and constants.RefreshReason
    if rr then
        if rr.Searches then
            reasons[#reasons + 1] = rr.Searches
        end
        if rr.Layout then
            reasons[#reasons + 1] = rr.Layout
        end
        if rr.ItemWidgets then
            reasons[#reasons + 1] = rr.ItemWidgets
        end
    end
    if #reasons == 0 then
        reasons = { "searches", "layout" }
    end
    if api.RequestItemButtonsRefresh then
        api.RequestItemButtonsRefresh(reasons)
    end
    if api.RequestLayoutUpdate then
        api.RequestLayoutUpdate()
    end
end

local function GetFluxConsumablesModule()
    return _G.FluxNCConsumables
end

--- Build itemID → presetName. Prefer active preset, else first alphabetical owner.
local function BuildItemOwnerMap(data, presetNames)
    local owners = {}
    local active = data.activePreset or "default"
    for i = 1, #presetNames do
        local name = presetNames[i]
        local preset = data.presets and data.presets[name]
        local items = preset and preset.items
        if type(items) == "table" then
            for j = 1, #items do
                local id = tonumber(items[j])
                if id then
                    local prev = owners[id]
                    if not prev then
                        owners[id] = name
                    elseif prev ~= active and name == active then
                        owners[id] = active
                    end
                end
            end
        end
    end
    return owners
end

local function BuildAddedItemsForPreset(owners, presetName)
    local added = {}
    local any = false
    for itemID, owner in pairs(owners) do
        if owner == presetName then
            added["i:" .. itemID] = true
            any = true
        end
    end
    return added, any
end

local function RemoveFluxSourcesFromOrder(order)
    for i = #order, 1, -1 do
        if IsFluxConsumablesSource(order[i]) then
            table.remove(order, i)
        end
    end
end

local function FindInsertIndexBeforeConsumables(order)
    local keys = {
        "default_potion",
        "default_food",
        "default_consumable",
        "default_questitem",
    }
    for k = 1, #keys do
        local idx = IndexOf(order, keys[k])
        if idx then
            return idx
        end
    end
    return math.min(#order + 1, 2)
end

local function EnsureSectionShell(order, sections)
    local sectionId = FindSectionNamed(sections, SECTION_NAME)
    local created = false
    if not sectionId then
        sectionId = NextFreeSectionId(sections)
        sections[sectionId] = { name = SECTION_NAME }
        created = true
    end
    local token = "_" .. sectionId
    local startIdx = IndexOf(order, token)
    if startIdx then
        return sectionId, startIdx, created
    end
    local insertAt = FindInsertIndexBeforeConsumables(order)
    table.insert(order, insertAt, token)
    table.insert(order, insertAt + 1, SECTION_END)
    return sectionId, insertAt, true
end

local function InsertSourcesIntoSection(order, sectionStartIdx, sources)
    -- sectionStartIdx points at _sectionId; insert sources after it, before __end.
    local insertAt = sectionStartIdx + 1
    for i = 1, #sources do
        table.insert(order, insertAt + i - 1, sources[i])
    end
end

local function AddedItemsEqual(a, b)
    a = a or {}
    b = b or {}
    local countA, countB = 0, 0
    for k, v in pairs(a) do
        if v then
            countA = countA + 1
            if not b[k] then
                return false
            end
        end
    end
    for k, v in pairs(b) do
        if v then
            countB = countB + 1
        end
    end
    return countA == countB
end

--- Sync Flux consumable presets into Baganator custom categories + section layout.
--- @return boolean true if config changed
function Compat.SyncConsumablesCategories()
    local profile = GetActiveBaganatorConfig()
    if not profile then
        return false
    end

    local order = profile.category_display_order
    local sections = profile.category_sections
    local custom = profile.custom_categories
    local mods = profile.category_modifications
    local hidden = profile.category_hidden
    if type(order) ~= "table" or type(sections) ~= "table" then
        return false
    end
    if type(custom) ~= "table" then
        custom = {}
        profile.custom_categories = custom
    end
    if type(mods) ~= "table" then
        mods = {}
        profile.category_modifications = mods
    end
    if type(hidden) ~= "table" then
        hidden = {}
        profile.category_hidden = hidden
    end

    local NC = GetFluxConsumablesModule()
    local data = NC and NC.GetData and NC.GetData()
    if type(data) ~= "table" or type(data.presets) ~= "table" then
        return false
    end

    local presetNames = NC.GetPresetNames and NC.GetPresetNames() or {}
    if #presetNames == 0 then
        presetNames = { "default" }
    end

    -- Active preset first in the section, then remaining alphabetical (GetPresetNames is sorted).
    local active = data.activePreset or "default"
    local orderedNames = {}
    local seen = {}
    if data.presets[active] then
        orderedNames[#orderedNames + 1] = active
        seen[active] = true
    end
    for i = 1, #presetNames do
        local name = presetNames[i]
        if name and not seen[name] and data.presets[name] then
            orderedNames[#orderedNames + 1] = name
            seen[name] = true
        end
    end

    local owners = BuildItemOwnerMap(data, orderedNames)
    local wantedSources = {}
    local sourceOrder = {}
    local changed = false

    for i = 1, #orderedNames do
        local presetName = orderedNames[i]
        local source = SanitizePresetKey(presetName)
        -- Disambiguate collisions (two presets sanitizing to same key).
        local base = source
        local n = 2
        while wantedSources[source] and wantedSources[source] ~= presetName do
            source = base .. "_" .. n
            n = n + 1
        end
        wantedSources[source] = presetName
        sourceOrder[#sourceOrder + 1] = source

        local added = BuildAddedItemsForPreset(owners, presetName)
        local displayName = DisplayNameForPreset(presetName)
        local cat = custom[source]
        if not cat or cat.name ~= displayName or cat.search ~= "" then
            custom[source] = { name = displayName, search = "" }
            changed = true
        end
        local m = mods[source]
        if not m then
            mods[source] = { priority = PRIORITY, addedItems = added }
            changed = true
        else
            if m.priority ~= PRIORITY then
                m.priority = PRIORITY
                changed = true
            end
            if not AddedItemsEqual(m.addedItems, added) then
                m.addedItems = added
                changed = true
            end
        end
    end

    -- Prune stale Flux sources.
    for source in pairs(custom) do
        if IsFluxConsumablesSource(source) and not wantedSources[source] then
            custom[source] = nil
            mods[source] = nil
            hidden[source] = nil
            changed = true
        end
    end
    for source in pairs(mods) do
        if IsFluxConsumablesSource(source) and not wantedSources[source] then
            mods[source] = nil
            changed = true
        end
    end

    -- Rebuild display-order membership for Flux sources inside our section.
    local previousFluxOrder = {}
    for i = 1, #order do
        if IsFluxConsumablesSource(order[i]) then
            previousFluxOrder[#previousFluxOrder + 1] = order[i]
        end
    end
    RemoveFluxSourcesFromOrder(order)

    local sectionId, sectionStartIdx, sectionChanged = EnsureSectionShell(order, sections)
    if sectionChanged then
        changed = true
    end
    sectionStartIdx = IndexOf(order, "_" .. sectionId) or sectionStartIdx
    InsertSourcesIntoSection(order, sectionStartIdx, sourceOrder)

    if #previousFluxOrder ~= #sourceOrder then
        changed = true
    else
        for i = 1, #sourceOrder do
            if previousFluxOrder[i] ~= sourceOrder[i] then
                changed = true
                break
            end
        end
    end

    if changed then
        RequestCategoryLayoutRefresh()
    end
    return changed
end

function Compat.InitConsumablesCategories()
    if Compat._consumablesCategoriesInitialized then
        return
    end
    Compat._consumablesCategoriesInitialized = true

    local function Run()
        Compat.SyncConsumablesCategories()
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0.6, Run)
        C_Timer.After(2.0, Run)
    else
        Run()
    end

    local R = _G.FluxRespec
    if R and R.On then
        R.On("CONSUMABLES_CONFIG_CHANGED", function()
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, Run)
            else
                Run()
            end
        end)
    end

    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if registry and registry.RegisterCallback then
        registry:RegisterCallback("BagShow", Run)
    end
end
