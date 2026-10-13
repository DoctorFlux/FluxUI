-- FluxBaganator_EquipmentSetSection.lua
-- Ensures Respec/gear-preset auto categories live under their own Baganator
-- section "Equipment Set", separate from the normal Equipment (Weapons/Armor) section.
-- Baganator has no RegisterCategory API; set subcategories still use
-- default_auto_equipment_sets via RegisterItemSetSource.

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local SETS_SOURCE = "default_auto_equipment_sets"
local SECTION_NAME = "Equipment Set"
local SECTION_END = "__end"

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

--- True when order already has: _X (name Equipment Set) … default_auto_equipment_sets … __end
local function HasEquipmentSetSectionWithSets(order, sections)
    for i = 1, #order do
        local sid = SectionIdFromToken(order[i])
        local details = sid and sections[sid]
        if details and details.name == SECTION_NAME then
            local level = 0
            for j = i + 1, #order do
                local s = order[j]
                if s == SECTION_END then
                    if level == 0 then
                        break
                    end
                    level = level - 1
                elseif IsSectionStart(s) then
                    level = level + 1
                elseif s == SETS_SOURCE then
                    return true, sid, i
                end
            end
        end
    end
    return false
end

local function FindSectionNamed(sections, name)
    for id, details in pairs(sections) do
        if details and details.name == name then
            return tostring(id)
        end
    end
end

--- Index of the built-in Equipment section start token, if present.
local function FindEquipmentSectionIndex(order, sections)
    for i = 1, #order do
        local sid = SectionIdFromToken(order[i])
        local details = sid and sections[sid]
        if details and details.name == "EQUIPMENT" then
            return i
        end
        -- Legacy v1 token
        if order[i] == "_EQUIPMENT" then
            return i
        end
    end
end

local function RemoveAllOccurrences(order, value)
    for i = #order, 1, -1 do
        if order[i] == value then
            table.remove(order, i)
        end
    end
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

--- Move default_auto_equipment_sets into a dedicated "Equipment Set" section.
--- Leaves Weapons/Armor under the normal Equipment section.
--- @return boolean true if the display order was changed
function Compat.EnsureEquipmentSetSection()
    local profile = GetActiveBaganatorConfig()
    if not profile then
        return false
    end

    local order = profile.category_display_order
    local sections = profile.category_sections
    if type(order) ~= "table" or type(sections) ~= "table" or #order == 0 then
        return false
    end

    if HasEquipmentSetSectionWithSets(order, sections) then
        return false
    end

    RemoveAllOccurrences(order, SETS_SOURCE)

    local sectionId = FindSectionNamed(sections, SECTION_NAME)
    if not sectionId then
        sectionId = NextFreeSectionId(sections)
        sections[sectionId] = { name = SECTION_NAME }
    end

    local sectionToken = "_" .. sectionId
    local startIdx = IndexOf(order, sectionToken)

    if startIdx then
        -- Section exists in order: place sets immediately after the header.
        table.insert(order, startIdx + 1, SETS_SOURCE)
    else
        local insertAt = FindEquipmentSectionIndex(order, sections)
        if not insertAt then
            insertAt = IndexOf(order, "default_questitem")
            insertAt = insertAt and (insertAt + 1) or 1
        end
        table.insert(order, insertAt, sectionToken)
        table.insert(order, insertAt + 1, SETS_SOURCE)
        table.insert(order, insertAt + 2, SECTION_END)
    end

    RequestCategoryLayoutRefresh()
    return true
end

function Compat.InitEquipmentSetSection()
    if Compat._equipmentSetSectionInitialized then
        return
    end
    Compat._equipmentSetSectionInitialized = true

    local function Run()
        Compat.EnsureEquipmentSetSection()
    end

    if C_Timer and C_Timer.After then
        -- After Baganator finishes default category import / FixAnyBrokenSections.
        C_Timer.After(0.5, Run)
        C_Timer.After(2.0, Run)
    else
        Run()
    end

    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if registry and registry.RegisterCallback then
        registry:RegisterCallback("BagShow", function()
            Compat.EnsureEquipmentSetSection()
        end)
    end
end
