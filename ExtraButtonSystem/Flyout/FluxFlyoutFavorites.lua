-- FluxFlyoutFavorites.lua
-- Universal favorites system for custom flyout buttons
-- Only applies to specific registered buttons (e.g., Mount button on NonCombatGrid)
--
-- Features:
-- - Per-modifier favorites (nomod, shift, ctrl, alt, combinations)
-- - Right-click to set/clear favorites on flyout buttons
-- - Star indicator on favorited items
-- - Button-specific registration (not global)
-- - Category pairing (e.g., Teleport ↔ Portal sync)
--
-- Usage:
--   FluxFlyoutFavorites.RegisterButton(buttonWidget, category, config)
--   FluxFlyoutFavorites.GetFavorite(category, modKey)
--   FluxFlyoutFavorites.SetFavorite(category, itemIdOrSpellId, modKey)
local addonName, ns = ...

local FluxFlyoutFavorites = {}
_G.FluxFlyoutFavorites = FluxFlyoutFavorites

-- ---------------------------------------------------------------------------
-- CONSTANTS
-- ---------------------------------------------------------------------------

local FAVORITES_SAVED_VAR = "FluxFlyoutFavorites_Data"

-- ---------------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------------

-- Registered buttons that should have favorites functionality
-- Key: buttonWidget, Value: { category = string, config = table }
local registeredButtons = {}

-- Category configurations
-- Key: category name, Value: { syncPartner, itemType, getPairedID, ... }
local categoryConfigs = {}

-- Listener callbacks for favorite changes
local listeners = {}

-- Sync in progress flag (prevent recursion)
local syncInProgress = false

-- ---------------------------------------------------------------------------
-- SAVED VARIABLES
-- ---------------------------------------------------------------------------

local function GetFavoritesTable()
    -- Initialize root table if needed
    if not _G[FAVORITES_SAVED_VAR] then
        _G[FAVORITES_SAVED_VAR] = {}
    end
    
    -- Function to get character key (safe even if called early)
    local function GetCharKey()
        local name = UnitName("player")
        local realm = GetRealmName()
        if not name or not realm then return nil end
        return name .. "-" .. realm
    end
    
    local charKey = GetCharKey()
    if not charKey then
        -- Fallback if player info not available yet (rare)
        -- Return a temp table so we don't error, but won't save
        return {} 
    end
    
    -- Initialize character section
    if not _G[FAVORITES_SAVED_VAR][charKey] then
        _G[FAVORITES_SAVED_VAR][charKey] = {}
    end
    
    return _G[FAVORITES_SAVED_VAR][charKey]
end

-- ---------------------------------------------------------------------------
-- MODIFIER KEY HELPERS
-- ---------------------------------------------------------------------------

local function NormalizeModKey(modKey)
    if type(modKey) ~= "string" or modKey == "" then return "nomod" end
    local s = string.lower(modKey)
    s = s:gsub("control", "ctrl")
    
    local parts = {}
    for token in string.gmatch(s, "[^+]+") do
        token = token:gsub("%s+", "")
        if token == "ctrl" or token == "shift" or token == "alt" or token == "nomod" then
            parts[token] = true
        end
    end
    
    local ordered = {}
    if parts.ctrl then table.insert(ordered, "ctrl") end
    if parts.shift then table.insert(ordered, "shift") end
    if parts.alt then table.insert(ordered, "alt") end
    
    if #ordered == 0 then return "nomod" end
    return table.concat(ordered, "+")
end

local function GetCurrentModKey()
    local tokens = {}
    if IsControlKeyDown and IsControlKeyDown() then table.insert(tokens, "ctrl") end
    if IsShiftKeyDown and IsShiftKeyDown() then table.insert(tokens, "shift") end
    if IsAltKeyDown and IsAltKeyDown() then table.insert(tokens, "alt") end
    if #tokens == 0 then return "nomod" end
    return table.concat(tokens, "+")
end

-- ---------------------------------------------------------------------------
-- NAME LOOKUP HELPERS
-- ---------------------------------------------------------------------------

local function GetSpellNameById(spellId)
    if not spellId then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellId)
        return info and info.name or nil
    end
    if GetSpellInfo then return (GetSpellInfo(spellId)) end
    return nil
end

local function GetItemNameById(itemId)
    if not itemId then return nil end
    if GetItemInfo then
        return select(1, GetItemInfo(itemId))
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- BUTTON DETECTION HELPERS (Old-style pattern compatibility)
-- ---------------------------------------------------------------------------

--- Get item/spell IDs from a flyout button
-- Checks multiple sources for compatibility with different setups
-- @param btn The flyout button
-- @return itemId, spellId
local function GetButtonIDs(btn)
    if not btn then return nil, nil end
    
    -- First check direct properties (set by FluxFlyoutFrame.ConfigureButton)
    local itemId = btn._actionItemID
    local spellId = btn._actionSpellID
    
    -- Also check attributes (for fallback)
    if not itemId and btn.GetAttribute then
        itemId = tonumber(btn:GetAttribute("item"))
    end
    if not spellId and btn.GetAttribute then
        spellId = tonumber(btn:GetAttribute("spell"))
    end
    
    -- Check actionData (support both lowercase and uppercase)
    if btn._actionData then
        if not itemId then
            itemId = btn._actionData["$itemId"] or btn._actionData["$itemID"]
        end
        if not spellId then
            spellId = btn._actionData["$spellId"] or btn._actionData["$spellID"]
        end
    end
    
    -- Also check btn.actionData (FluxFlyoutFrame pattern)
    if btn.actionData then
        if not itemId then
            itemId = btn.actionData["$itemId"] or btn.actionData["$itemID"]
        end
        if not spellId then
            spellId = btn.actionData["$spellId"] or btn.actionData["$spellID"]
        end
    end
    
    return itemId, spellId
end

--- Detect category from a flyout button
-- Checks button attribute, parent button flags, and spell name for fallback
-- @param btn The flyout button
-- @return category string or nil
local function DetectCategoryFromButton(btn)
    if not btn then return nil end
    
    -- First check attribute set directly on button
    local category = btn._fluxFavCategory
    if category then return category end
    
    -- Check FluxFlyoutCategory attribute
    if btn.GetAttribute then
        category = btn:GetAttribute("FluxFlyoutCategory")
        if category then return category end
    end
    
    -- Check parent button (flyoutParent.parentButton pattern)
    local parentButton = btn.flyoutParent and btn.flyoutParent.parentButton
    if parentButton then
        if parentButton.FluxFlyoutCategory then
            return parentButton.FluxFlyoutCategory
        end
        -- Also check registration system
        local reg = registeredButtons[parentButton]
        if reg then return reg.category end
    end
    
    -- Check button's parent frame (old FluxCustomFlyout pattern)
    local parentFrame = btn:GetParent()
    if parentFrame and parentFrame.parentButton then
        if parentFrame.parentButton.FluxFlyoutCategory then
            return parentFrame.parentButton.FluxFlyoutCategory
        end
    end
    
    -- Fallback: detect from spell name (for Teleport/Portal)
    local _, spellId = GetButtonIDs(btn)
    if spellId then
        local name = GetSpellNameById(spellId)
        if name then
            if name:find("^Teleport:") or name:find("Teleport:", 1, true) then return "Teleport" end
            if name:find("^Portal:") or name:find("Portal:", 1, true) then return "Portal" end
        end
    end
    
    return nil
end

--- Check if a flyout button belongs to a grid-owned flyout (should have favorites)
-- @param btn The flyout button
-- @return boolean
local function IsGridOwnedFlyoutButton(btn)
    if not btn then return false end
    
    -- Check flyoutParent.parentButton.FluxGridFlyoutOwner pattern
    local parentButton = btn.flyoutParent and btn.flyoutParent.parentButton
    if parentButton and parentButton.FluxGridFlyoutOwner then
        return true
    end
    
    -- Check btn:GetParent().parentButton pattern (old FluxCustomFlyout)
    local parentFrame = btn:GetParent()
    if parentFrame and parentFrame.parentButton and parentFrame.parentButton.FluxGridFlyoutOwner then
        return true
    end
    
    -- Check registration system
    if parentButton then
        local reg = registeredButtons[parentButton]
        if reg then return true end
    end
    
    return false
end

-- ---------------------------------------------------------------------------
-- CATEGORY REGISTRATION
-- ---------------------------------------------------------------------------

--- Register a category with optional configuration
-- @param category Category name (e.g., "Mount", "Teleport", "Portal")
-- @param config Optional table: { syncPartner, itemType="spell|item|both", getPairedID }
function FluxFlyoutFavorites.RegisterCategory(category, config)
    if not category or type(category) ~= "string" then return end
    categoryConfigs[category] = config or {}
end

local function GetCategoryConfig(category)
    return categoryConfigs[category] or {}
end

local function IsCategoryRegistered(category)
    return categoryConfigs[category] ~= nil
end

-- ---------------------------------------------------------------------------
-- LISTENER SYSTEM
-- ---------------------------------------------------------------------------

--- Register a callback for when favorites change
-- @param callback Function(category) called when favorites change
function FluxFlyoutFavorites.RegisterListener(callback)
    if type(callback) == "function" then
        table.insert(listeners, callback)
    end
end

local function NotifyListeners(category)
    for _, callback in ipairs(listeners) do
        pcall(callback, category)
    end
end

--- Update all visible favorite stars across all flyout frames
-- Call this after setting/clearing a favorite to refresh UI in real-time
function FluxFlyoutFavorites.UpdateAllVisibleStars()
    -- Helper function to update stars on a frame's buttons
    local function UpdateFrameStars(frame)
        if not frame then return end
        if not frame:IsShown() then return end
        
        -- Check if this is a favorites-enabled flyout
        local isGridOwned = frame.parentButton and frame.parentButton.FluxGridFlyoutOwner
        if not isGridOwned then return end
        
        -- Update buttons
        local buttons = frame.buttons or {}
        for _, btn in ipairs(buttons) do
            if btn:IsShown() then
                local star = btn.FluxFlyoutFavStar_Custom
                if star then
                    local category = btn._fluxFavCategory or (btn.GetAttribute and btn:GetAttribute("FluxFlyoutCategory"))
                    if category then
                        local itemID, spellID = GetButtonIDs(btn)
                        if FluxFlyoutFavorites.IsFavoritedAnyMod(category, itemID, spellID) then
                            star:Show()
                        else
                            star:Hide()
                        end
                    end
                end
            end
        end
    end
    
    -- Update FluxFlyoutContainer frames (new system)
    local idx = 1
    while true do
        local frame = _G["FluxFlyoutContainer" .. idx]
        if not frame then break end
        UpdateFrameStars(frame)
        idx = idx + 1
    end
    
    -- Update FluxFlyoutFrame frames (alternate naming)
    idx = 1
    while true do
        local frame = _G["FluxFlyoutFrame" .. idx]
        if not frame then break end
        UpdateFrameStars(frame)
        idx = idx + 1
    end
    
    -- Also update FluxCustomFlyoutFrame frames (old system compatibility)
    idx = 1
    while true do
        local frame = _G["FluxCustomFlyoutFrame" .. idx]
        if not frame then break end
        UpdateFrameStars(frame)
        idx = idx + 1
    end
    
    -- Also check the currently active flyout directly via FluxFlyoutFrame module
    if FluxFlyoutFrame and FluxFlyoutFrame.GetActiveFlyout then
        local activeFlyout = FluxFlyoutFrame.GetActiveFlyout()
        if activeFlyout then
            UpdateFrameStars(activeFlyout)
        end
    end
end

--- Refresh tooltip if it's currently showing on a flyout button
-- Re-triggers the tooltip display to show updated favorites info
function FluxFlyoutFavorites.RefreshFlyoutTooltip()
    if not GameTooltip or not GameTooltip:IsShown() then return end
    
    local owner = GameTooltip:GetOwner()
    if not owner then return end
    
    -- Check if owner is a flyout button with favorites
    if not owner.FluxFlyoutFavStar_Custom then return end
    
    -- Helper to rebuild tooltip
    local function RebuildTooltip()
        if owner and owner:IsVisible() and owner:IsMouseOver() then
            -- Clear current tooltip
            GameTooltip:Hide()
            
            -- Re-trigger OnEnter to rebuild tooltip with fresh data
            local onEnter = owner:GetScript("OnEnter")
            if onEnter then
                pcall(onEnter, owner)
            end
        end
    end
    
    -- Trigger the OnEnter script to rebuild the tooltip
    -- Use a short delay to avoid any race conditions
    if C_Timer and C_Timer.After then
        C_Timer.After(0.01, RebuildTooltip)
    else
        -- Fallback for clients without C_Timer
        RebuildTooltip()
    end
end

-- ---------------------------------------------------------------------------
-- SYNC FUNCTIONS (for paired categories like Teleport ↔ Portal)
-- ---------------------------------------------------------------------------

-- Get paired ID using category's sync function or default logic
local function GetPairedID(category, itemId, spellId)
    local config = GetCategoryConfig(category)
    if config.getPairedID then
        return config.getPairedID(itemId, spellId)
    end
    return nil
end

-- Sync setting a favorite to the paired category
local function SyncSetToPaired(category, itemId, spellId, modKey)
    if syncInProgress then return end
    local config = GetCategoryConfig(category)
    local syncPartner = config.syncPartner
    if not syncPartner then return end
    
    local pairedID = GetPairedID(category, itemId, spellId)
    if not pairedID then return end
    
    syncInProgress = true
    local root = GetFavoritesTable()
    root[syncPartner] = root[syncPartner] or {}
    root[syncPartner][modKey] = pairedID
    syncInProgress = false
end

-- Sync clearing a favorite to the paired category
local function SyncClearToPaired(category, itemId, spellId, modKey)
    if syncInProgress then return end
    local config = GetCategoryConfig(category)
    local syncPartner = config.syncPartner
    if not syncPartner then return end
    
    -- For Teleport/Portal sync, clear the same modifier from partner
    -- regardless of whether we can find the exact paired spell
    syncInProgress = true
    local favs = GetFavoritesTable()[syncPartner]
    if type(favs) == "table" then
        -- Try to find paired ID for exact matching
        local pairedID = GetPairedID(category, itemId, spellId)
        local current = favs[modKey]
        
        -- Clear if: exact match, OR if we couldn't find paired ID but partner has something
        if current and (current == pairedID or not pairedID) then
            favs[modKey] = nil
            -- Cleanup empty category
            local hasAny = false
            for _, v in pairs(favs) do if v then hasAny = true break end end
            if not hasAny then GetFavoritesTable()[syncPartner] = nil end
        end
    end
    syncInProgress = false
end

-- ---------------------------------------------------------------------------
-- PUBLIC API: FAVORITES MANAGEMENT
-- ---------------------------------------------------------------------------

--- Get the favorite for a category and modifier key
-- @param category Category name
-- @param modKey Modifier key (default "nomod")
-- @return itemId/spellId or nil
function FluxFlyoutFavorites.GetFavorite(category, modKey)
    if not IsCategoryRegistered(category) then return nil end
    local favs = GetFavoritesTable()[category]
    if type(favs) ~= "table" then return nil end
    return favs[NormalizeModKey(modKey)]
end

--- Set a favorite for a category and modifier key
-- @param category Category name
-- @param itemIdOrSpellId The item ID or spell ID to set as favorite
-- @param modKey Modifier key (default "nomod")
function FluxFlyoutFavorites.SetFavorite(category, itemIdOrSpellId, modKey)
    if not (IsCategoryRegistered(category) and itemIdOrSpellId) then return end
    
    local key = NormalizeModKey(modKey)
    local root = GetFavoritesTable()
    root[category] = root[category] or {}
    root[category][key] = tonumber(itemIdOrSpellId) or itemIdOrSpellId
    
    -- Sync to paired category if configured
    local config = GetCategoryConfig(category)
    local itemType = config.itemType or "both"
    local itemId = (itemType == "item" or itemType == "both") and itemIdOrSpellId or nil
    local spellId = (itemType == "spell" or itemType == "both") and itemIdOrSpellId or nil
    SyncSetToPaired(category, itemId, spellId, key)
    
    -- Update all visible stars and tooltip immediately
    FluxFlyoutFavorites.UpdateAllVisibleStars()
    FluxFlyoutFavorites.RefreshFlyoutTooltip()
    
    NotifyListeners(category)
end

--- Clear a favorite for a category and modifier key
-- @param category Category name
-- @param modKey Modifier key (default "nomod")
function FluxFlyoutFavorites.ClearFavorite(category, modKey)
    if not IsCategoryRegistered(category) then return end
    
    local key = NormalizeModKey(modKey)
    local favs = GetFavoritesTable()[category]
    if type(favs) ~= "table" then return end
    
    local itemIdOrSpellId = favs[key]
    favs[key] = nil
    
    -- Cleanup empty category
    local hasAny = false
    for _, v in pairs(favs) do if v then hasAny = true break end end
    if not hasAny then GetFavoritesTable()[category] = nil end
    
    -- Sync clear to paired category
    if itemIdOrSpellId then
        local config = GetCategoryConfig(category)
        local itemType = config.itemType or "both"
        local itemId = (itemType == "item" or itemType == "both") and itemIdOrSpellId or nil
        local spellId = (itemType == "spell" or itemType == "both") and itemIdOrSpellId or nil
        SyncClearToPaired(category, itemId, spellId, key)
    end
    
    -- Update all visible stars and tooltip immediately
    FluxFlyoutFavorites.UpdateAllVisibleStars()
    FluxFlyoutFavorites.RefreshFlyoutTooltip()
    
    NotifyListeners(category)
end

--- Toggle a favorite for a category
-- @param category Category name
-- @param itemIdOrSpellId The item/spell ID
-- @param modKey Modifier key (default current held)
function FluxFlyoutFavorites.ToggleFavorite(category, itemIdOrSpellId, modKey)
    if not (IsCategoryRegistered(category) and itemIdOrSpellId) then return end
    
    local key = NormalizeModKey(modKey or GetCurrentModKey())
    local current = FluxFlyoutFavorites.GetFavorite(category, key)
    
    local matches = false
    if type(current) == "number" and current == itemIdOrSpellId then
        matches = true
    elseif type(current) == "string" then
        local config = GetCategoryConfig(category)
        local itemType = config.itemType or "both"
        if itemType == "spell" or itemType == "both" then
            local spellName = GetSpellNameById(itemIdOrSpellId)
            if spellName and current == spellName then matches = true end
        end
        if itemType == "item" or itemType == "both" then
            local itemName = GetItemNameById(itemIdOrSpellId)
            if itemName and current == itemName then matches = true end
        end
    end
    
    if matches then
        FluxFlyoutFavorites.ClearFavorite(category, key)
    else
        FluxFlyoutFavorites.SetFavorite(category, itemIdOrSpellId, key)
    end
end

--- Check if an item/spell is favorited for any modifier in a category
-- @param category Category name
-- @param itemId Item ID (or nil)
-- @param spellId Spell ID (or nil)
-- @return boolean
function FluxFlyoutFavorites.IsFavoritedAnyMod(category, itemId, spellId)
    if not IsCategoryRegistered(category) then return false end
    local favs = GetFavoritesTable()[category]
    if type(favs) ~= "table" then return false end
    
    local config = GetCategoryConfig(category)
    local itemType = config.itemType or "both"
    
    for _, v in pairs(favs) do
        if type(v) == "number" then
            if (itemType == "item" or itemType == "both") and itemId and v == itemId then return true end
            if (itemType == "spell" or itemType == "both") and spellId and v == spellId then return true end
        elseif type(v) == "string" then
            if (itemType == "spell" or itemType == "both") and spellId then
                local spellName = GetSpellNameById(spellId)
                if spellName and v == spellName then return true end
            end
            if (itemType == "item" or itemType == "both") and itemId then
                local itemName = GetItemNameById(itemId)
                if itemName and v == itemName then return true end
            end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- PRIORITY FALLBACK SYSTEM
-- ---------------------------------------------------------------------------

-- Priority order for favorite fallback
-- If the exact modifier favorite is not available, fall back through this order
local PRIORITY_ORDER = { "nomod", "shift", "ctrl", "alt", "ctrl+shift", "shift+alt", "ctrl+alt", "ctrl+shift+alt" }

--- Get favorites table (for external use)
function FluxFlyoutFavorites.GetFavoritesTable()
    return GetFavoritesTable()
end

--- Get the best available favorite that is actually in the provided set
-- Implements the priority fallback: nomod > shift > ctrl > alt > etc.
-- @param category Category name
-- @param requestedModKey The requested modifier key (or "nomod")
-- @param inBagsSet Table of { [itemId] = true } for items that are available
-- @return favId, modKey - The favorite ID and which modifier it came from, or nil
function FluxFlyoutFavorites.GetBestAvailableFavorite(category, requestedModKey, inBagsSet)
    if not IsCategoryRegistered(category) then return nil, nil end
    if not inBagsSet or type(inBagsSet) ~= "table" then return nil, nil end
    
    local key = NormalizeModKey(requestedModKey)
    
    -- 1. Try exact requested modifier first
    local exactFav = FluxFlyoutFavorites.GetFavorite(category, key)
    if exactFav and inBagsSet[exactFav] then
        return exactFav, key
    end
    
    -- 2. Walk through priority order for fallback
    for _, modKey in ipairs(PRIORITY_ORDER) do
        local fav = FluxFlyoutFavorites.GetFavorite(category, modKey)
        if fav and inBagsSet[fav] then
            return fav, modKey
        end
    end
    
    return nil, nil
end

--- Get all favorites for a category that are in the provided bag set
-- Returns a table of { modKey = { itemId, name, icon } }
-- @param category Category name
-- @param inBagsSet Table of { [itemId] = itemData } where itemData has name, icon, etc.
-- @return table of available favorites keyed by modifier
function FluxFlyoutFavorites.GetAvailableFavorites(category, inBagsSet)
    local result = {}
    if not IsCategoryRegistered(category) then return result end
    if not inBagsSet or type(inBagsSet) ~= "table" then return result end
    
    for _, modKey in ipairs(PRIORITY_ORDER) do
        local favId = FluxFlyoutFavorites.GetFavorite(category, modKey)
        if favId and inBagsSet[favId] then
            local itemData = inBagsSet[favId]
            result[modKey] = {
                itemId = favId,
                name = itemData.name or itemData["$name"] or GetItemNameById(favId),
                icon = itemData.icon or itemData["$iconTexture"] or (GetItemIcon and GetItemIcon(favId)),
            }
        end
    end
    
    return result
end

--- Build a table of modifier actions for macro construction
-- Returns an ordered list of { mod, itemId, name } for all modifiers with available favorites
-- @param category Category name  
-- @param inBagsSet Table of { [itemId] = itemData }
-- @return array of { mod, itemId, name }
function FluxFlyoutFavorites.BuildModifierActions(category, inBagsSet)
    local actions = {}
    if not IsCategoryRegistered(category) then return actions end
    if not inBagsSet or type(inBagsSet) ~= "table" then return actions end
    
    -- Modifier order for macro conditionals (complex to simple)
    local modOrder = { "ctrl+shift+alt", "ctrl+shift", "ctrl+alt", "shift+alt", "ctrl", "shift", "alt" }
    
    for _, modKey in ipairs(modOrder) do
        local favId = FluxFlyoutFavorites.GetFavorite(category, modKey)
        if favId and inBagsSet[favId] then
            local itemData = inBagsSet[favId]
            table.insert(actions, {
                mod = modKey,
                itemId = favId,
                name = itemData.name or itemData["$name"] or GetItemNameById(favId),
            })
        end
    end
    
    return actions
end

-- ---------------------------------------------------------------------------
-- (continued from previous section)
-- ---------------------------------------------------------------------------

--- Clear all favorites for a specific item/spell across all modifiers
-- @param category Category name
-- @param itemId Item ID (or nil)
-- @param spellId Spell ID (or nil)
function FluxFlyoutFavorites.ClearAllForItem(category, itemId, spellId)
    if not IsCategoryRegistered(category) then return end
    local favs = GetFavoritesTable()[category]
    if type(favs) ~= "table" then return end
    
    local config = GetCategoryConfig(category)
    local itemType = config.itemType or "both"
    
    local keysToRemove = {}
    for k, v in pairs(favs) do
        local matches = false
        if type(v) == "number" then
            if (itemType == "item" or itemType == "both") and itemId and v == itemId then matches = true end
            if (itemType == "spell" or itemType == "both") and spellId and v == spellId then matches = true end
        elseif type(v) == "string" then
            if (itemType == "spell" or itemType == "both") and spellId then
                local spellName = GetSpellNameById(spellId)
                if spellName and v == spellName then matches = true end
            end
            if (itemType == "item" or itemType == "both") and itemId then
                local itemName = GetItemNameById(itemId)
                if itemName and v == itemName then matches = true end
            end
        end
        if matches then
            table.insert(keysToRemove, k)
        end
    end
    
    for _, k in ipairs(keysToRemove) do
        favs[k] = nil
    end
    
    -- Cleanup empty category
    local hasAny = false
    for _, v in pairs(favs) do if v then hasAny = true break end end
    if not hasAny then GetFavoritesTable()[category] = nil end
    
    -- Sync clear to partner category (for Teleport <-> Portal sync)
    -- For each modifier that was cleared, also clear the partner
    local syncPartner = config.syncPartner
    if syncPartner and #keysToRemove > 0 then
        local partnerFavs = GetFavoritesTable()[syncPartner]
        if type(partnerFavs) == "table" then
            -- Get the paired spell ID to identify what to clear in partner
            local pairedID = nil
            if config.getPairedID then
                pairedID = config.getPairedID(itemId, spellId)
            end
            
            for _, modKey in ipairs(keysToRemove) do
                local currentPartnerFav = partnerFavs[modKey]
                -- Clear if: exact paired ID match, OR if we couldn't find paired ID
                -- This ensures sync works even when paired spell can't be resolved
                if currentPartnerFav and (currentPartnerFav == pairedID or not pairedID) then
                    partnerFavs[modKey] = nil
                end
            end
            
            -- Cleanup empty partner category
            local partnerHasAny = false
            for _, v in pairs(partnerFavs) do if v then partnerHasAny = true break end end
            if not partnerHasAny then GetFavoritesTable()[syncPartner] = nil end
        end
    end
    
    -- Update all visible stars and tooltip immediately
    FluxFlyoutFavorites.UpdateAllVisibleStars()
    FluxFlyoutFavorites.RefreshFlyoutTooltip()
    
    NotifyListeners(category)
    
    -- Also notify partner category listeners
    if syncPartner then
        NotifyListeners(syncPartner)
    end
end

-- ---------------------------------------------------------------------------
-- BUTTON REGISTRATION
-- ---------------------------------------------------------------------------

--- Register a button widget to have favorites functionality
-- Only registered buttons will show favorites UI and behavior
-- @param buttonWidget The button's widget (not the FluxButton instance)
-- @param category The favorites category (e.g., "Mount")
-- @param config Optional configuration table
function FluxFlyoutFavorites.RegisterButton(buttonWidget, category, config)
    if not buttonWidget or not category then return end
    
    -- Ensure category is registered
    if not IsCategoryRegistered(category) then
        FluxFlyoutFavorites.RegisterCategory(category, config)
    end
    
    registeredButtons[buttonWidget] = {
        category = category,
        config = config or {},
    }
    
    -- Mark the button as having favorites enabled
    buttonWidget._fluxFlyoutFavoritesCategory = category
    buttonWidget._fluxFlyoutFavoritesEnabled = true
end

--- Unregister a button from favorites functionality
-- @param buttonWidget The button's widget
function FluxFlyoutFavorites.UnregisterButton(buttonWidget)
    if not buttonWidget then return end
    registeredButtons[buttonWidget] = nil
    buttonWidget._fluxFlyoutFavoritesCategory = nil
    buttonWidget._fluxFlyoutFavoritesEnabled = nil
end

--- Check if a button is registered for favorites
-- @param buttonWidget The button's widget
-- @return boolean, category
function FluxFlyoutFavorites.IsButtonRegistered(buttonWidget)
    if not buttonWidget then return false, nil end
    local reg = registeredButtons[buttonWidget]
    if reg then
        return true, reg.category
    end
    return false, nil
end

--- Get the category for a registered button
-- @param buttonWidget The button's widget
-- @return category or nil
function FluxFlyoutFavorites.GetButtonCategory(buttonWidget)
    if not buttonWidget then return nil end
    local reg = registeredButtons[buttonWidget]
    return reg and reg.category or nil
end

-- ---------------------------------------------------------------------------
-- FLYOUT BUTTON UI INTEGRATION
-- ---------------------------------------------------------------------------

--- Create a star texture on a flyout button (using old naming convention)
-- @param btn The flyout button
-- @return star texture
local function EnsureStarTexture(btn)
    -- Use old naming convention: FluxFlyoutFavStar_Custom
    if btn.FluxFlyoutFavStar_Custom then return btn.FluxFlyoutFavStar_Custom end
    
    local star = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    local ok = pcall(function() star:SetAtlas("PetJournal-FavoritesIcon", true) end)
    if not ok then
        star:SetTexture("Interface\\COMMON\\FavoritesIcon")
        star:SetSize(32, 32)
    end
    star:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
    star:Hide()
    
    -- Store with old naming convention
    btn.FluxFlyoutFavStar_Custom = star
    return star
end

--- Update star visibility on a flyout button
-- @param btn The flyout button
-- @param category The favorites category
-- @param itemId Item ID (or nil)
-- @param spellId Spell ID (or nil)
function FluxFlyoutFavorites.UpdateButtonStar(btn, category, itemId, spellId)
    if not btn or not category then return end
    
    local star = EnsureStarTexture(btn)
    if FluxFlyoutFavorites.IsFavoritedAnyMod(category, itemId, spellId) then
        star:Show()
    else
        star:Hide()
    end
end

--- Append favorites tooltip info to a button
-- @param btn The flyout button
-- @param category The favorites category
-- @param itemId Item ID (or nil)
-- @param spellId Spell ID (or nil)
function FluxFlyoutFavorites.AppendTooltip(btn, category, itemId, spellId)
    if not btn or not category then return end
    
    local tip = GameTooltip
    if not tip or not tip:IsOwned(btn) then return end
    
    local favs = GetFavoritesTable()[category]
    if type(favs) ~= "table" then favs = {} end
    
    local config = GetCategoryConfig(category)
    local itemType = config.itemType or "both"
    
    -- Find all modifiers this item is favorited for
    local modList = {}
    for key, v in pairs(favs) do
        local matches = false
        if type(v) == "number" then
            if (itemType == "item" or itemType == "both") and itemId and v == itemId then matches = true end
            if (itemType == "spell" or itemType == "both") and spellId and v == spellId then matches = true end
        elseif type(v) == "string" then
            if (itemType == "spell" or itemType == "both") and spellId then
                local spellName = GetSpellNameById(spellId)
                if spellName and v == spellName then matches = true end
            end
            if (itemType == "item" or itemType == "both") and itemId then
                local itemName = GetItemNameById(itemId)
                if itemName and v == itemName then matches = true end
            end
        end
        if matches then
            local label = (key == "" or key == "nomod") and "no mod" or key
            table.insert(modList, label)
        end
    end
    
    -- Show favorites info
    if #modList > 0 then
        table.sort(modList, function(a, b)
            local order = { ["no mod"] = 0, ["ctrl"] = 1, ["shift"] = 2, ["alt"] = 3,
                ["ctrl+shift"] = 4, ["ctrl+alt"] = 5, ["shift+alt"] = 6, ["ctrl+shift+alt"] = 7 }
            return (order[a] or 99) < (order[b] or 99)
        end)
        local text = "|cff33ff33Favorites: " .. table.concat(modList, ", ") .. "|r"
        tip:AddLine(text)
    end
    
    -- Show hint
    local isFav = FluxFlyoutFavorites.IsFavoritedAnyMod(category, itemId, spellId)
    local modLabel = GetCurrentModKey()
    if modLabel == "" or modLabel == "nomod" then modLabel = "no mod" end
    
    if isFav then
        tip:AddLine("|cffaaaaaaRight-click: Clear favorite|r")
    else
        tip:AddLine("|cffaaaaaaRight-click: Favorite (for " .. modLabel .. ")|r")
    end
    
    tip:Show()
end

-- ---------------------------------------------------------------------------
-- FLYOUT HOOKS (matching old hookCustomFlyoutButton pattern)
-- ---------------------------------------------------------------------------

--- Hook a flyout button for favorites functionality
-- Matches the old FluxFlyoutFavorites.hookCustomFlyoutButton pattern exactly
-- @param btn The flyout button
-- @param category The favorites category (detected from parent if not provided)
function FluxFlyoutFavorites.HookFlyoutButton(btn, category)
    if not btn then return end
    
    -- Skip if already hooked (use old naming convention)
    if btn.FluxFlyoutFavHooked_Custom then return end
    
    -- Skip rune buttons - they don't need favorites functionality
    if btn.GetAttribute and btn:GetAttribute("isRuneButton") then
        return
    end
    
    -- Skip buttons marked to skip favorites (e.g., reagent items with custom right-click)
    if btn._fluxSkipFavorites then
        return
    end
    
    -- Only apply favorites to grid-owned flyouts (custom flyout macros on the grid)
    local parentFrame = btn:GetParent()
    if parentFrame and parentFrame.parentButton and not parentFrame.parentButton.FluxGridFlyoutOwner then
        return
    end
    
    -- Detect category if not provided
    if not category then
        category = DetectCategoryFromButton(btn)
    end
    
    -- If still no category, don't hook
    if not category then return end
    
    -- Mark as hooked
    btn.FluxFlyoutFavHooked_Custom = true
    
    -- Mark this button with category attribute
    if btn.SetAttribute then
        btn:SetAttribute("FluxFlyoutCategory", category)
    end
    btn._fluxFavCategory = category
    
    -- Create star texture
    local star = EnsureStarTexture(btn)
    
    -- Update star visibility function
    local function updateStar()
        local itemID, spellID = GetButtonIDs(btn)
        local cat = DetectCategoryFromButton(btn)
        if cat and (itemID or spellID) and FluxFlyoutFavorites.IsFavoritedAnyMod(cat, itemID, spellID) then
            star:Show()
        else
            star:Hide()
        end
    end
    
    -- OnShow handler
    btn:HookScript("OnShow", function(self)
        updateStar()
    end)
    
    -- OnHide handler
    btn:HookScript("OnHide", function(self)
        if self.FluxFlyoutFavStar_Custom then self.FluxFlyoutFavStar_Custom:Hide() end
    end)
    
    -- OnEnter - append tooltip info
    btn:HookScript("OnEnter", function(self)
        if self and self:IsMouseOver() then
            local itemID, spellID = GetButtonIDs(self)
            local cat = DetectCategoryFromButton(self)
            if cat and (itemID or spellID) then
                FluxFlyoutFavorites.AppendTooltip(self, cat, itemID, spellID)
            end
        end
    end)
    
    -- Right-click handler for setting/clearing favorites
    btn:HookScript("OnMouseUp", function(self, mouseButton)
        if mouseButton ~= "RightButton" then return end
        local itemID, spellID = GetButtonIDs(self)
        if not itemID and not spellID then return end
        
        local cat = DetectCategoryFromButton(self)
        if not cat then return end
        
        -- If favorited for any modifier, clear all favorites for this item
        if FluxFlyoutFavorites.IsFavoritedAnyMod(cat, itemID, spellID) then
            FluxFlyoutFavorites.ClearAllForItem(cat, itemID, spellID)
        else
            -- Set favorite for current held modifier
            local modKey = GetCurrentModKey()
            local config = GetCategoryConfig(cat)
            local itemType = config.itemType or "both"
            local idToSave = nil
            
            -- Force Item ID for Mount category to ensure macro compatibility
            if cat == "Mount" then
                idToSave = itemID
                if not idToSave then
                    -- If we only have a spell ID, we can't favorite it for the item-based macro
                end
            elseif itemType == "item" then
                idToSave = itemID
            elseif itemType == "spell" then
                idToSave = spellID
            else
                idToSave = itemID or spellID
            end
            
            if idToSave then
                FluxFlyoutFavorites.SetFavorite(cat, idToSave, modKey)
            end
        end
        
        -- Update star visibility for all visible buttons in the flyout
        -- Check FluxFlyoutFrame frames (new system)
        local flyoutIdx = 1
        while true do
            local frame = _G["FluxFlyoutFrame" .. flyoutIdx]
            if not frame then break end
            if frame:IsShown() and frame.buttons then
                for _, b in ipairs(frame.buttons) do
                    if b:IsShown() and b.FluxFlyoutFavStar_Custom then
                        local bid, bsid = GetButtonIDs(b)
                        local bcat = DetectCategoryFromButton(b)
                        if bcat and (bid or bsid) and FluxFlyoutFavorites.IsFavoritedAnyMod(bcat, bid, bsid) then
                            b.FluxFlyoutFavStar_Custom:Show()
                        else
                            b.FluxFlyoutFavStar_Custom:Hide()
                        end
                    end
                end
            end
            flyoutIdx = flyoutIdx + 1
        end
        
        -- Also check FluxCustomFlyoutFrame frames (old system compatibility)
        local cfIdx = 1
        while true do
            local frame = _G["FluxCustomFlyoutFrame" .. cfIdx]
            if not frame then break end
            if frame:IsShown() and frame.buttons then
                for _, b in ipairs(frame.buttons) do
                    if b:IsShown() and b.FluxFlyoutFavStar_Custom then
                        local bid, bsid = GetButtonIDs(b)
                        local bcat = DetectCategoryFromButton(b)
                        if bcat and (bid or bsid) and FluxFlyoutFavorites.IsFavoritedAnyMod(bcat, bid, bsid) then
                            b.FluxFlyoutFavStar_Custom:Show()
                        else
                            b.FluxFlyoutFavStar_Custom:Hide()
                        end
                    end
                end
            end
            cfIdx = cfIdx + 1
        end
        
        -- Refresh tooltip if it's open
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then
            self.FluxFlyoutFav_TooltipAppended = nil
            local bid, bsid = GetButtonIDs(self)
            local bcat = DetectCategoryFromButton(self)
            if bcat and (bid or bsid) then
                FluxFlyoutFavorites.AppendTooltip(self, bcat, bid, bsid)
            end
        end
        
        -- Notify listeners to update header button right-click behavior
        NotifyListeners(cat)
    end)
    
    -- Initial star update
    updateStar()
end

--- Notify that a flyout is about to open for a button
-- @param parentButton The button that triggered the flyout
-- @return boolean, category - true if this flyout should have favorites
function FluxFlyoutFavorites.ShouldEnableFavorites(parentButton)
    if not parentButton then return false, nil end
    
    -- Check registration system first
    local isRegistered, category = FluxFlyoutFavorites.IsButtonRegistered(parentButton)
    if isRegistered then
        return true, category
    end
    
    -- Check old-style FluxGridFlyoutOwner pattern
    if parentButton.FluxGridFlyoutOwner and parentButton.FluxFlyoutCategory then
        return true, parentButton.FluxFlyoutCategory
    end
    
    return false, nil
end

-- ---------------------------------------------------------------------------
-- FLYOUT FRAME HOOKING (matching old installFluxCustomFlyoutHooks pattern)
-- ---------------------------------------------------------------------------

--- Hook all visible buttons in a flyout frame
-- @param flyoutFrame The flyout frame to hook
local function OnFlyoutFrameShow(flyoutFrame)
    if not flyoutFrame or not flyoutFrame.parentButton then return end
    local parentButton = flyoutFrame.parentButton
    
    -- Only apply favorites to grid-owned flyouts
    if not parentButton.FluxGridFlyoutOwner then return end
    
    local category = parentButton.FluxFlyoutCategory
    if not category then return end
    
    -- Hook all visible buttons in the flyout
    if flyoutFrame.buttons then
        for _, btn in ipairs(flyoutFrame.buttons) do
            if btn:IsShown() then
                FluxFlyoutFavorites.HookFlyoutButton(btn, category)
                -- Update star visibility
                if btn.FluxFlyoutFavStar_Custom then
                    local itemID, spellID = GetButtonIDs(btn)
                    local cat = DetectCategoryFromButton(btn)
                    if cat and (itemID or spellID) and FluxFlyoutFavorites.IsFavoritedAnyMod(cat, itemID, spellID) then
                        btn.FluxFlyoutFavStar_Custom:Show()
                    else
                        btn.FluxFlyoutFavStar_Custom:Hide()
                    end
                end
            end
        end
    end
end

--- Notify that a flyout has opened (called by FluxFlyoutFrame.ShowFlyout)
-- @param parentButton The button that triggered the flyout
-- @param flyoutFrame The flyout frame that opened
function FluxFlyoutFavorites.OnFlyoutOpened(parentButton, flyoutFrame)
    if not flyoutFrame or not parentButton then return end
    
    -- Only apply favorites to grid-owned flyouts
    if not parentButton.FluxGridFlyoutOwner then return end
    
    -- Give UI a moment to set up button data, then hook
    -- This ensures all button attributes are properly configured
    local timerFunc = C_Timer and C_Timer.After
    if timerFunc then
        timerFunc(0.05, function()
            if flyoutFrame and flyoutFrame:IsShown() then
                OnFlyoutFrameShow(flyoutFrame)
            end
        end)
    else
        OnFlyoutFrameShow(flyoutFrame)
    end
end

--- Hook a flyout frame for favorites (called once per frame)
-- @param frame The flyout frame to hook
local function HookFlyoutFrame(frame)
    if not frame or frame._FluxFlyoutFavHooked then return end
    
    -- Only hook grid-owned flyout frames
    if not (frame.parentButton and frame.parentButton.FluxGridFlyoutOwner) then
        return
    end
    
    frame._FluxFlyoutFavHooked = true
    
    -- Hook frame OnShow
    frame:HookScript("OnShow", function(self)
        OnFlyoutFrameShow(self)
    end)
    
    -- Hook frame OnHide to hide stars
    frame:HookScript("OnHide", function(self)
        if self.buttons then
            for _, btn in ipairs(self.buttons) do
                if btn.FluxFlyoutFavStar_Custom then
                    btn.FluxFlyoutFavStar_Custom:Hide()
                end
            end
        end
    end)
    
    -- Hook each button's OnShow directly
    if frame.buttons then
        for _, btn in ipairs(frame.buttons) do
            if not btn._FluxFlyoutFavButtonOnShowHooked then
                btn._FluxFlyoutFavButtonOnShowHooked = true
                btn:HookScript("OnShow", function(self)
                    local cat = DetectCategoryFromButton(self)
                    if cat then
                        FluxFlyoutFavorites.HookFlyoutButton(self, cat)
                        -- Update star visibility
                        if self.FluxFlyoutFavStar_Custom then
                            local parentFrame = self:GetParent()
                            if parentFrame and parentFrame.parentButton and parentFrame.parentButton.FluxGridFlyoutOwner then
                                local itemID, spellID = GetButtonIDs(self)
                                if FluxFlyoutFavorites.IsFavoritedAnyMod(cat, itemID, spellID) then
                                    self.FluxFlyoutFavStar_Custom:Show()
                                else
                                    self.FluxFlyoutFavStar_Custom:Hide()
                                end
                            else
                                -- Hide stars for non-grid flyouts
                                self.FluxFlyoutFavStar_Custom:Hide()
                            end
                        end
                    end
                end)
            end
        end
    end
    
    -- If frame is already showing, hook buttons now
    if frame:IsShown() then
        OnFlyoutFrameShow(frame)
    end
end

--- Install frame watchers for flyout frames
local function InstallFlyoutFrameHooks()
    if _G.FluxFlyoutFav_FrameHooksInstalled then return end
    
    -- Hook any existing FluxFlyoutFrame frames
    local i = 1
    while true do
        local frame = _G["FluxFlyoutFrame" .. i]
        if not frame then break end
        if frame.parentButton and frame.parentButton.FluxGridFlyoutOwner then
            HookFlyoutFrame(frame)
        end
        i = i + 1
    end
    
    -- Also check FluxCustomFlyoutFrame for compatibility
    i = 1
    while true do
        local frame = _G["FluxCustomFlyoutFrame" .. i]
        if not frame then break end
        if frame.parentButton and frame.parentButton.FluxGridFlyoutOwner then
            HookFlyoutFrame(frame)
        end
        i = i + 1
    end
    
    -- Flux perf T1.11: the previous permanent OnUpdate watcher fired ~10x per
    -- second forever to discover new FluxFlyoutFrame / FluxCustomFlyoutFrame
    -- instances. These frames are only created when the player opens a
    -- flyout, so an event-driven scan wired to flyout-related events is
    -- equivalent but costs ~0% CPU when idle.
    local function _ScanAndHookFlyoutFrames()
        local idx = 1
        while true do
            local frame = _G["FluxFlyoutFrame" .. idx]
            if not frame then break end
            if not frame._FluxFlyoutFavHooked and frame.parentButton and frame.parentButton.FluxGridFlyoutOwner then
                HookFlyoutFrame(frame)
            end
            idx = idx + 1
        end
        idx = 1
        while true do
            local frame = _G["FluxCustomFlyoutFrame" .. idx]
            if not frame then break end
            if not frame._FluxFlyoutFavHooked and frame.parentButton and frame.parentButton.FluxGridFlyoutOwner then
                HookFlyoutFrame(frame)
            end
            idx = idx + 1
        end
    end

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_LOGIN")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    watcher:RegisterEvent("UPDATE_MACROS")
    watcher:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    watcher:SetScript("OnEvent", function(_, event, ...)
        -- Shapeshift bonus-bar storms: flyout frame scan is unrelated and expensive.
        if event == "UPDATE_BONUS_ACTIONBAR"
            and FluxButtonEvents and FluxButtonEvents.IsFormStormActive
            and FluxButtonEvents.IsFormStormActive() then
            return
        end
        if event == "ACTIONBAR_SLOT_CHANGED"
            and FluxButtonEvents and FluxButtonEvents.IsFormStormActive
            and FluxButtonEvents.IsFormStormActive() then
            return
        end
        _ScanAndHookFlyoutFrames()
    end)

    --- Safety net: some flyout frames are lazily created the first time the
    --- user opens a flyout. Do two short deferred scans to cover those, then
    --- we rely purely on events above.
    if C_Timer and C_Timer.After then
        C_Timer.After(2.0, _ScanAndHookFlyoutFrames)
        C_Timer.After(6.0, _ScanAndHookFlyoutFrames)
    end

    _G.FluxFlyoutFav_FrameHooksInstalled = true
    _G.FluxFlyoutFav_ScanAndHookFrames = _ScanAndHookFlyoutFrames
end

-- ---------------------------------------------------------------------------
-- INITIALIZATION
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- TELEPORT/PORTAL PAIRING HELPERS
-- ---------------------------------------------------------------------------

-- Extract destination from spell name (e.g., "Teleport: Stormwind" -> "Stormwind")
local function GetDestinationFromSpellName(spellName)
    if not spellName then return nil end
    local dest = spellName:match("^Teleport:%s*(.+)$") or spellName:match("^Portal:%s*(.+)$")
    return dest
end

-- Get the paired spell ID (teleport ↔ portal) by name matching
local function GetPairedTeleportPortalSpellID(spellId)
    if not spellId then return nil end
    
    local spellName = GetSpellNameById(spellId)
    if not spellName then return nil end
    
    local destination = GetDestinationFromSpellName(spellName)
    if not destination then return nil end
    
    local pairName
    if spellName:find("^Teleport:") then
        pairName = "Portal: " .. destination
    elseif spellName:find("^Portal:") then
        pairName = "Teleport: " .. destination
    else
        return nil
    end
    
    -- Method 1: Try C_Spell API (modern Retail)
    local pairSpellId = nil
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(pairName)
        if info and info.spellID then
            pairSpellId = info.spellID
        end
    end
    
    -- Method 2: Try GetSpellInfo (classic/older)
    if not pairSpellId and GetSpellInfo then
        local _, _, _, _, _, _, id = GetSpellInfo(pairName)
        if id then pairSpellId = id end
    end
    
    -- Method 3: Scan spellbook for the paired spell
    if not pairSpellId then
        local lowerPairName = pairName:lower()
        
        -- Try modern spellbook API first
        if C_SpellBook and C_SpellBook.GetNumSpellBookItems then
            local numSpells = C_SpellBook.GetNumSpellBookItems(Enum.SpellBookSpellBank.Player) or 0
            for i = 1, numSpells do
                local spellInfo = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
                if spellInfo and spellInfo.spellID then
                    local name = GetSpellNameById(spellInfo.spellID)
                    if name and name:lower() == lowerPairName then
                        pairSpellId = spellInfo.spellID
                        break
                    end
                end
            end
        end
        
        -- Fallback: scan using old spellbook API
        if not pairSpellId and GetNumSpellTabs and GetSpellTabInfo then
            local numTabs = GetNumSpellTabs() or 0
            for tab = 1, numTabs do
                local _, _, offset, numSpells = GetSpellTabInfo(tab)
                if offset and numSpells then
                    for i = offset + 1, offset + numSpells do
                        local name, _, id
                        if GetSpellBookItemName then
                            name = GetSpellBookItemName(i, "spell")
                        end
                        if name and name:lower() == lowerPairName then
                            if GetSpellBookItemInfo then
                                local _, itemId = GetSpellBookItemInfo(i, "spell")
                                pairSpellId = itemId
                            end
                            break
                        end
                    end
                    if pairSpellId then break end
                end
            end
        end
    end
    
    return pairSpellId
end

-- Register default categories
local function RegisterDefaultCategories()
    -- Mount category (items)
    FluxFlyoutFavorites.RegisterCategory("Mount", {
        itemType = "item",  -- Mount items use item IDs
    })
    
    -- Teleport category (spells) - syncs with Portal
    FluxFlyoutFavorites.RegisterCategory("Teleport", {
        syncPartner = "Portal",
        itemType = "spell",
        getPairedID = function(itemId, spellId)
            return GetPairedTeleportPortalSpellID(spellId)
        end,
    })
    
    -- Portal category (spells) - syncs with Teleport
    FluxFlyoutFavorites.RegisterCategory("Portal", {
        syncPartner = "Teleport",
        itemType = "spell",
        getPairedID = function(itemId, spellId)
            return GetPairedTeleportPortalSpellID(spellId)
        end,
    })
    
    -- Item-based teleports (Hearthstone grid — toys / scrolls / Atiesh; not spell Teleport/Portal)
    FluxFlyoutFavorites.RegisterCategory("TeleportItem", {
        itemType = "item",
    })
end

-- Initialize on addon load
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        RegisterDefaultCategories()
    elseif event == "PLAYER_LOGIN" then
        -- Ensure saved vars are initialized
        GetFavoritesTable()
        -- Install frame hooks for flyout favorites
        InstallFlyoutFrameHooks()
    end
end)

-- ---------------------------------------------------------------------------
-- DEBUG
-- ---------------------------------------------------------------------------

SLASH_FLYOUTFAV1 = "/flyoutfav"
SlashCmdList["FLYOUTFAV"] = function(msg)
    local cmd = msg and msg:lower():match("^(%S+)") or ""
    
    if cmd == "list" then
        print("|cff00ffff[FluxFlyoutFavorites]|r Registered categories:")
        for cat, config in pairs(categoryConfigs) do
            local sync = config.syncPartner and (" (syncs with " .. config.syncPartner .. ")") or ""
            print("  " .. cat .. sync)
        end
        
        print("|cff00ffff[FluxFlyoutFavorites]|r Saved favorites:")
        local favs = GetFavoritesTable()
        for cat, modFavs in pairs(favs) do
            print("  " .. cat .. ":")
            for modKey, id in pairs(modFavs) do
                local name = GetItemNameById(id) or GetSpellNameById(id) or tostring(id)
                print("    [" .. modKey .. "] = " .. name .. " (" .. tostring(id) .. ")")
            end
        end
    elseif cmd == "clear" then
        _G[FAVORITES_SAVED_VAR] = {}
        print("|cff00ffff[FluxFlyoutFavorites]|r All favorites cleared.")
    else
        print("|cff00ffff[FluxFlyoutFavorites]|r Commands:")
        print("  /flyoutfav list - Show registered categories and favorites")
        print("  /flyoutfav clear - Clear all favorites")
    end
end



