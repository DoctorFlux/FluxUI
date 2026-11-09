--[[
    ExtraButtonSystem/ExtraButtons/Core.lua
    Core initialization and SavedVariables handling for ExtraButtons
    Based on ExtraButtons.lua from old FluxExtraButtonSystem
]]

local addonName, ns = ...
local Flux = ns and ns.Flux

-- Create namespace
FluxExtraButtons = FluxExtraButtons or {}
local E = FluxExtraButtons

local ADDON_NAME = "_FluxUI"

-- Configuration constants
-- Native widget size is Bars.CONFIG.buttonSize (44). Visual size is SlotFrame * 1.3.
E.BUTTON_SPACING = 0
E.HEADER_HEIGHT = 18
E.NUM_BUTTON_COLUMNS_TARGET = 7
E.CONTROL_BUTTON_WIDTH = 16
E.CATEGORY_ACTION_BUTTON_SIZE = 14
E.CATEGORY_ACTION_BUTTON_SPACING = 2
E.EXTRA_BUTTONS_SCALE = 1 / 1.265
-- Button slot multiplier: Makes the frame/slot bigger than the actual button widget
-- This gives more space around buttons without resizing the button icons themselves
E.BUTTON_SLOT_SIZE_MULTIPLIER = 1.3  -- 30% bigger slot frame than button widget

-- Visual settings
E.CATEGORY_WINDOW_BACKDROP_COLOR_ALPHA = 0.20
E.CATEGORY_WINDOW_BORDER_COLOR_ALPHA = 0.9
-- Increased padding to make category frames bigger (buttons stay same size)
E.WINDOW_PADDING_HORIZONTAL = 80  -- Increased from 62
E.WINDOW_PADDING_VERTICAL = 10    -- Increased from 6
E.BUTTONS_LEFT_INSET = 10          -- Increased from 6
E.BUTTONS_RIGHT_INSET = 10         -- Increased from 6
E.HEADER_TO_BUTTONS_SPACING = 4
E.HEADER_TOP_OFFSET_ADJUST = 2
E.BUTTON_VISUAL_OVERHANG_FACTOR = 0.25  -- Extra height factor for button border overhang

-- Colors
E.DEFAULT_NEUTRAL_COLOR = {r = 0.25, g = 0.25, b = 0.25}
E.NEUTRAL_BORDER_COLOR_FACTOR = 0.2
E.NEUTRAL_TEXT_COLOR = {r = 0.85, g = 0.85, b = 0.85}

-- Get class color
local _, playerClass = UnitClass("player")
E.CLASS_COLOUR = RAID_CLASS_COLORS[playerClass] or {r = 1, g = 1, b = 1}

-- Generate unique ID for categories/buttons
function E:GenerateUniqueID()
    return tostring(GetTime()) .. "-" .. tostring(math.random(10000, 99999))
end

-- Initialize SavedVariables structure
function E:LoadSavedVars()
    -- Global database
    if not FluxUI_DB then FluxUI_DB = {} end
    if type(FluxUI_DB.ExtraButtonCategories) ~= "table" then
        FluxUI_DB.ExtraButtonCategories = {}
    end
    if type(FluxUI_DB.ExtraButtonSettings) ~= "table" then
        FluxUI_DB.ExtraButtonSettings = {}
    end
    
    -- Account-wide categories
    if type(FluxUI_DB.ExtraButtonCategories.Account) ~= "table" then
        FluxUI_DB.ExtraButtonCategories.Account = { entries = {} }
    end
    
    -- Class categories
    if type(FluxUI_DB.ExtraButtonCategories.Class) ~= "table" then
        FluxUI_DB.ExtraButtonCategories.Class = {}
    end
    if playerClass then
        if type(FluxUI_DB.ExtraButtonCategories.Class[playerClass]) ~= "table" then
            FluxUI_DB.ExtraButtonCategories.Class[playerClass] = { entries = {} }
        end
    end
    
    -- Realm categories
    local realmName = GetRealmName()
    if type(FluxUI_DB.ExtraButtonCategories.Realm) ~= "table" then
        FluxUI_DB.ExtraButtonCategories.Realm = {}
    end
    if realmName then
        if type(FluxUI_DB.ExtraButtonCategories.Realm[realmName]) ~= "table" then
            FluxUI_DB.ExtraButtonCategories.Realm[realmName] = { entries = {} }
        end
    end
    
    -- Character database
    if not _FluxUI_CharSavedVars then _FluxUI_CharSavedVars = {} end
    if type(_FluxUI_CharSavedVars.ExtraButtonCategories) ~= "table" then
        _FluxUI_CharSavedVars.ExtraButtonCategories = { entries = {} }
    end
    if type(_FluxUI_CharSavedVars.characterDisplayOrder) ~= "table" then
        _FluxUI_CharSavedVars.characterDisplayOrder = {}
    end
    if type(_FluxUI_CharSavedVars.hiddenGlobalCategories) ~= "table" then
        _FluxUI_CharSavedVars.hiddenGlobalCategories = {}
    end
    
    -- Migrate existing categories
    self:MigrateCategories()
    
    -- Ensure all category IDs are in the display order
    self:PopulateDisplayOrder()
end

-- Ensure characterDisplayOrder contains all existing category IDs
function E:PopulateDisplayOrder()
    local _, playerClass = UnitClass("player")
    local realmName = GetRealmName()
    
    -- Build a set of IDs already in display order
    local idsInOrder = {}
    for _, id in ipairs(_FluxUI_CharSavedVars.characterDisplayOrder) do
        idsInOrder[id] = true
    end
    
    -- All sources to check for categories
    local sources = {
        _FluxUI_CharSavedVars.ExtraButtonCategories and _FluxUI_CharSavedVars.ExtraButtonCategories.entries,
        FluxUI_DB.ExtraButtonCategories.Account and FluxUI_DB.ExtraButtonCategories.Account.entries,
        playerClass and FluxUI_DB.ExtraButtonCategories.Class and FluxUI_DB.ExtraButtonCategories.Class[playerClass] and FluxUI_DB.ExtraButtonCategories.Class[playerClass].entries,
        realmName and FluxUI_DB.ExtraButtonCategories.Realm and FluxUI_DB.ExtraButtonCategories.Realm[realmName] and FluxUI_DB.ExtraButtonCategories.Realm[realmName].entries
    }
    
    -- Add any missing category IDs to display order
    for _, entriesTable in ipairs(sources) do
        if entriesTable and type(entriesTable) == "table" then
            for _, entry in ipairs(entriesTable) do
                if entry.type == "category" and entry.id and not idsInOrder[entry.id] then
                    table.insert(_FluxUI_CharSavedVars.characterDisplayOrder, entry.id)
                    idsInOrder[entry.id] = true
                end
            end
        end
    end
end

-- Migrate category entries to ensure proper structure
function E:MigrateCategories()
    local function migrateCategoryEntries(entriesTable, defaultScope)
        if not entriesTable then return end
        for i, entry in ipairs(entriesTable) do
            if entry.type == "category" then
                if not entry.id then entry.id = self:GenerateUniqueID() end
                if entry.isCollapsed == nil then entry.isCollapsed = false end
                if not entry.scope then entry.scope = defaultScope or "character" end
            end
        end
    end
    
    -- Migrate character entries
    if _FluxUI_CharSavedVars.ExtraButtonCategories and _FluxUI_CharSavedVars.ExtraButtonCategories.entries then
        migrateCategoryEntries(_FluxUI_CharSavedVars.ExtraButtonCategories.entries, "character")
    end
    
    -- Migrate account entries
    if FluxUI_DB.ExtraButtonCategories.Account and FluxUI_DB.ExtraButtonCategories.Account.entries then
        migrateCategoryEntries(FluxUI_DB.ExtraButtonCategories.Account.entries, "account")
    end
    
    -- Migrate class entries
    if playerClass and FluxUI_DB.ExtraButtonCategories.Class and FluxUI_DB.ExtraButtonCategories.Class[playerClass] then
        migrateCategoryEntries(FluxUI_DB.ExtraButtonCategories.Class[playerClass].entries, "class")
    end
    
    -- Migrate realm entries
    local realmName = GetRealmName()
    if realmName and FluxUI_DB.ExtraButtonCategories.Realm and FluxUI_DB.ExtraButtonCategories.Realm[realmName] then
        migrateCategoryEntries(FluxUI_DB.ExtraButtonCategories.Realm[realmName].entries, "realm")
    end
end

-- Get entries table for a specific scope
function E:GetEntriesTableForScope(scope)
    self:LoadSavedVars()
    
    local _, playerClass = UnitClass("player")
    local realmName = GetRealmName()
    
    if scope == "character" then
        return _FluxUI_CharSavedVars.ExtraButtonCategories.entries
    elseif scope == "account" then
        return FluxUI_DB.ExtraButtonCategories.Account and FluxUI_DB.ExtraButtonCategories.Account.entries
    elseif scope == "class" and playerClass then
        return FluxUI_DB.ExtraButtonCategories.Class and 
               FluxUI_DB.ExtraButtonCategories.Class[playerClass] and 
               FluxUI_DB.ExtraButtonCategories.Class[playerClass].entries
    elseif scope == "realm" and realmName then
        return FluxUI_DB.ExtraButtonCategories.Realm and 
               FluxUI_DB.ExtraButtonCategories.Realm[realmName] and 
               FluxUI_DB.ExtraButtonCategories.Realm[realmName].entries
    end
    
    return nil
end

-- Find category entry by ID
function E:FindCategoryByID(categoryID)
    local _, playerClass = UnitClass("player")
    local realmName = GetRealmName()
    
    local sourcesToSearch = {
        _FluxUI_CharSavedVars.ExtraButtonCategories and _FluxUI_CharSavedVars.ExtraButtonCategories.entries,
        FluxUI_DB.ExtraButtonCategories.Account and FluxUI_DB.ExtraButtonCategories.Account.entries,
        playerClass and FluxUI_DB.ExtraButtonCategories.Class and 
            FluxUI_DB.ExtraButtonCategories.Class[playerClass] and 
            FluxUI_DB.ExtraButtonCategories.Class[playerClass].entries,
        realmName and FluxUI_DB.ExtraButtonCategories.Realm and 
            FluxUI_DB.ExtraButtonCategories.Realm[realmName] and 
            FluxUI_DB.ExtraButtonCategories.Realm[realmName].entries
    }
    
    for _, entriesTable in ipairs(sourcesToSearch) do
        if entriesTable and type(entriesTable) == "table" then
            for _, entry in ipairs(entriesTable) do
                if entry.type == "category" and entry.id == categoryID then
                    return entry
                end
            end
        end
    end
    
    return nil
end

-- Get all displayable categories in order
function E:GetAllCategoriesInOrder()
    self:LoadSavedVars()
    
    local _, playerClass = UnitClass("player")
    local realmName = GetRealmName()
    
    local allCategories = {}
    local idMap = {}
    
    -- Gather all categories
    local sources = {
        { entries = _FluxUI_CharSavedVars.ExtraButtonCategories and _FluxUI_CharSavedVars.ExtraButtonCategories.entries, scope = "character" },
        { entries = playerClass and FluxUI_DB.ExtraButtonCategories.Class and FluxUI_DB.ExtraButtonCategories.Class[playerClass] and FluxUI_DB.ExtraButtonCategories.Class[playerClass].entries, scope = "class" },
        { entries = realmName and FluxUI_DB.ExtraButtonCategories.Realm and FluxUI_DB.ExtraButtonCategories.Realm[realmName] and FluxUI_DB.ExtraButtonCategories.Realm[realmName].entries, scope = "realm" },
        { entries = FluxUI_DB.ExtraButtonCategories.Account and FluxUI_DB.ExtraButtonCategories.Account.entries, scope = "account" },
    }
    
    for _, source in ipairs(sources) do
        if source.entries and type(source.entries) == "table" then
            for _, entry in ipairs(source.entries) do
                if entry.type == "category" and entry.id and not idMap[entry.id] then
                    -- Check if hidden for this character
                    local hidden = _FluxUI_CharSavedVars.hiddenGlobalCategories and 
                                   _FluxUI_CharSavedVars.hiddenGlobalCategories[entry.id]
                    if not hidden then
                        table.insert(allCategories, entry)
                        idMap[entry.id] = true
                    end
                end
            end
        end
    end
    
    -- Sort by display order if available
    local displayOrder = _FluxUI_CharSavedVars.characterDisplayOrder or {}
    if #displayOrder > 0 then
        local orderMap = {}
        for i, id in ipairs(displayOrder) do
            orderMap[id] = i
        end
        
        table.sort(allCategories, function(a, b)
            local orderA = orderMap[a.id] or 9999
            local orderB = orderMap[b.id] or 9999
            return orderA < orderB
        end)
    end
    
    return allCategories
end

-- Check if scope uses class color
function E:ScopeUsesClassColor(scope)
    return scope == "character" or scope == "class"
end

-- Get color for scope
function E:GetScopeColor(scope)
    if self:ScopeUsesClassColor(scope) then
        return self.CLASS_COLOUR.r, self.CLASS_COLOUR.g, self.CLASS_COLOUR.b
    else
        return self.NEUTRAL_TEXT_COLOR.r, self.NEUTRAL_TEXT_COLOR.g, self.NEUTRAL_TEXT_COLOR.b
    end
end

-- Get border color for scope
function E:GetScopeBorderColor(scope)
    if self:ScopeUsesClassColor(scope) then
        return self.CLASS_COLOUR.r, self.CLASS_COLOUR.g, self.CLASS_COLOUR.b, self.CATEGORY_WINDOW_BORDER_COLOR_ALPHA
    else
        return self.NEUTRAL_TEXT_COLOR.r * self.NEUTRAL_BORDER_COLOR_FACTOR, 
               self.NEUTRAL_TEXT_COLOR.g * self.NEUTRAL_BORDER_COLOR_FACTOR, 
               self.NEUTRAL_TEXT_COLOR.b * self.NEUTRAL_BORDER_COLOR_FACTOR, 
               self.CATEGORY_WINDOW_BORDER_COLOR_ALPHA
    end
end

-- Native Extra Button size (SpellFX fill is authored for 44). Visual pack is SetScale.
function E:GetDefaultButtonSize()
    if Flux and Flux.Bars and Flux.Bars.CONFIG and Flux.Bars.CONFIG.buttonSize then
        return Flux.Bars.CONFIG.buttonSize
    end
    return 44
end

-- Get category block range (category entry + its buttons) in the flat entries table
-- Returns startIndex, endIndex where entries[startIndex] is the category and 
-- entries[startIndex+1..endIndex] are its buttons
function E:GetCategoryBlockRange(entriesTable, categoryID)
    if not entriesTable or not categoryID then return -1, -1 end
    
    local catStartIndex = -1
    -- Find the category by ID
    for i, entry in ipairs(entriesTable) do
        if entry.type == "category" and entry.id == categoryID then
            catStartIndex = i
            break
        end
    end
    
    if catStartIndex == -1 then return -1, -1 end
    
    -- Find the end of this category's buttons (until next category or end)
    local catEndIndex = catStartIndex
    for i = catStartIndex + 1, #entriesTable do
        if entriesTable[i].type == "category" then
            break
        end
        catEndIndex = i
    end
    
    return catStartIndex, catEndIndex
end

-- Get buttons for a category from the flat entries table
function E:GetButtonsForCategory(categoryData)
    if not categoryData or not categoryData.id or not categoryData.scope then
        return {}
    end
    
    local entriesTable = self:GetEntriesTableForScope(categoryData.scope)
    if not entriesTable then return {} end
    
    local catStart, catEnd = self:GetCategoryBlockRange(entriesTable, categoryData.id)
    if catStart == -1 then return {} end
    
    local buttons = {}
    for i = catStart + 1, catEnd do
        local entry = entriesTable[i]
        if entry and entry.type == "button" then
            table.insert(buttons, entry)
        end
    end
    
    return buttons
end

-- Add a button entry to the flat entries table after a category
function E:AddButtonToEntriesTable(categoryData)
    if not categoryData or not categoryData.id or not categoryData.scope then return nil end
    
    local entriesTable = self:GetEntriesTableForScope(categoryData.scope)
    if not entriesTable then return nil end
    
    local catStart, catEnd = self:GetCategoryBlockRange(entriesTable, categoryData.id)
    if catStart == -1 then return nil end
    
    -- Create new button entry
    local newButton = {
        type = "button",
        dataType = nil,
        data = nil,
    }
    
    -- Insert after the last button of this category (or after the category if no buttons)
    table.insert(entriesTable, catEnd + 1, newButton)
    
    return newButton
end

-- Remove a button entry from the flat entries table
function E:RemoveButtonFromEntriesTable(categoryData, buttonEntry)
    if not categoryData or not categoryData.scope or not categoryData.id or not buttonEntry then return false end
    
    local entriesTable = self:GetEntriesTableForScope(categoryData.scope)
    if not entriesTable then return false end
    
    -- Get category block range (category + its buttons)
    local catStart, catEnd = self:GetCategoryBlockRange(entriesTable, categoryData.id)
    if catStart == -1 then return false end
    
    -- Search within the category's button range (catStart+1 to catEnd)
    for i = catStart + 1, catEnd do
        local entry = entriesTable[i]
        -- Check both reference equality and content equality
        if entry == buttonEntry or (entry.type == "button" and entry == buttonEntry) then
            table.remove(entriesTable, i)
            return true
        end
    end
    
    return false
end

-- Initialize the ExtraButtons system
function E:Initialize()
    self:LoadSavedVars()
    
    -- Initialize UI
    if self.UI and self.UI.Initialize then
        self.UI:Initialize()
    end
    
    -- Initialize categories
    if self.Categories and self.Categories.Initialize then
        self.Categories:Initialize()
    end
    
    -- Initialize buttons
    if self.Buttons and self.Buttons.Initialize then
        self.Buttons:Initialize()
    end
end

-- Export
_G.FluxExtraButtons = E
