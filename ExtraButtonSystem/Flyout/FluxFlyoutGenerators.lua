-- FluxFlyoutGenerators.lua
-- Action generators for custom flyout buttons
-- Supports all WoW clients: Retail, Classic, Legacy
local addonName, ns = ...

local FluxFlyoutGenerators = {}
_G.FluxFlyoutGenerators = FluxFlyoutGenerators

-- Maximum number of flyout buttons
FluxFlyoutGenerators.MAX_BUTTONS = 12

-- ---------------------------------------------------------------------------
-- CROSS-VERSION API HELPERS
-- ---------------------------------------------------------------------------

local function GetContainerAPI()
    local GetContainerNumSlots = _G.GetContainerNumSlots or (C_Container and C_Container.GetContainerNumSlots)
    local GetContainerItemID = FluxGetContainerItemID or _G.GetContainerItemID or (C_Container and C_Container.GetContainerItemID)
    local GetContainerItemInfo = _G.GetContainerItemInfo or (C_Container and C_Container.GetContainerItemInfo)
    return GetContainerNumSlots, GetContainerItemID, GetContainerItemInfo
end

local function SafeGetSpellInfo(spellIdOrName)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellIdOrName)
        if info then
            return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
        end
        return nil
    elseif GetSpellInfo then
        return GetSpellInfo(spellIdOrName)
    end
    return nil
end

local function SafeGetSpellTexture(spellIdOrName)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellIdOrName)
    elseif GetSpellTexture then
        return GetSpellTexture(spellIdOrName)
    end
    local _, _, icon = SafeGetSpellInfo(spellIdOrName)
    return icon
end

local function SafeGetSpellSubtext(spellId)
    if C_Spell and C_Spell.GetSpellSubtext then
        return C_Spell.GetSpellSubtext(spellId)
    elseif GetSpellSubtext then
        return GetSpellSubtext(spellId)
    end
    return nil
end

local function SafeGetItemInfo(itemIdOrName)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemIdOrName)
    elseif GetItemInfo then
        return GetItemInfo(itemIdOrName)
    end
    return nil
end

local function SafeGetItemIcon(itemId)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemId)
    elseif GetItemIcon then
        return GetItemIcon(itemId)
    end
    local _, _, _, _, _, _, _, _, _, icon = SafeGetItemInfo(itemId)
    return icon
end

local function SafeGetMacroInfo(macroIdOrName)
    if GetMacroInfo then
        return GetMacroInfo(macroIdOrName)
    end
    return nil
end

-- Check if a spell is known by the player
-- Works on ALL WoW clients: Retail, Classic Era, TBC, Wrath, Cata
local function IsSpellKnownSafe(spellIdOrName)
    if not spellIdOrName then return false end
    
    -- Get spell info (works on all clients)
    local name, _, _, _, _, _, spellId = SafeGetSpellInfo(spellIdOrName)
    if not name then return false end
    
    -- Method 1: IsSpellKnown (most reliable, available on most clients)
    if IsSpellKnown and spellId then
        local ok, result = pcall(IsSpellKnown, spellId)
        if ok and result then return true end
    end
    
    -- Method 2: IsPlayerSpell (available on some clients)
    if IsPlayerSpell and spellId then
        local ok, result = pcall(IsPlayerSpell, spellId)
        if ok and result then return true end
    end
    
    -- Method 3: C_SpellBook.IsSpellBookItemLearned (10.0+ only)
    if C_SpellBook and C_SpellBook.IsSpellBookItemLearned then
        local ok, result = pcall(C_SpellBook.IsSpellBookItemLearned, spellIdOrName)
        if ok and result then return true end
    end
    
    -- Method 4: GetSpellLink (returns nil for unknown spells on many clients)
    -- This is a weaker check - spell link can exist even for unknown spells
    if GetSpellLink then
        local ok, link = pcall(GetSpellLink, spellIdOrName)
        if ok and link then
            -- Additional check: on some clients, we can verify via FindSpellBookSlotBySpellID
            if FindSpellBookSlotBySpellID and spellId then
                local ok2, slot = pcall(FindSpellBookSlotBySpellID, spellId)
                if ok2 and slot then return true end
            elseif C_SpellBook and C_SpellBook.FindSpellBookSlotBySpellID and spellId then
                local ok2, slot = pcall(C_SpellBook.FindSpellBookSlotBySpellID, spellId)
                if ok2 and slot then return true end
            else
                -- On legacy clients without FindSpellBookSlotBySpellID, having a spell link
                -- combined with IsSpellKnown/IsPlayerSpell failing means spell is NOT known
                -- So we return false here rather than true
            end
        end
    end
    
    -- Method 5: Legacy fallback - check if spell is in spellbook by name
    -- This is slow but works on old Classic clients
    if GetNumSpellTabs and GetSpellTabInfo then
        local okTabs, numTabs = pcall(GetNumSpellTabs)
        if okTabs and type(numTabs) == "number" then
            for tab = 1, numTabs do
                local okInfo, _, _, offset, numSpells = pcall(function()
                    local n, tex, off, num = GetSpellTabInfo(tab)
                    return n, tex, off, num
                end)
                if okInfo and numSpells and numSpells > 0 then
                    for j = 1, numSpells do
                        local idx = offset + j
                        local bookSpellName
                        if GetSpellBookItemName then
                            local ok, n = pcall(GetSpellBookItemName, idx, BOOKTYPE_SPELL or "spell")
                            if ok then bookSpellName = n end
                        elseif GetSpellName then
                            local ok, n = pcall(GetSpellName, idx, BOOKTYPE_SPELL or "spell")
                            if ok then bookSpellName = n end
                        end
                        if bookSpellName and bookSpellName == name then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

-- Scan spellbook for portal or teleport spells
-- @param spellType "portal" or "teleport"
-- @return table Array of spell names found
local function ScanSpellbookForPortals(spellType)
    local foundSpells = {}
    local prefix = (spellType == "portal") and "Portal: " or "Teleport: "
    local seen = {} -- Prevent duplicates
    
    -- Modern API (10.0+)
    if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
        local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 1
        local i = 1
        while i <= 1000 do -- Safety limit
            local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
            if not info then break end
            
            if info.itemType == (Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell) and info.actionID then
                local spellName, _, _, _, _, _, _ = SafeGetSpellInfo(info.actionID)
                if spellName and type(spellName) == "string" and spellName:match("^" .. prefix) then
                    -- Filter by faction if needed (Horde vs Alliance portals)
                    local faction = UnitFactionGroup("player")
                    local isHorde = (faction == "Horde")
                    local isAlliance = (faction == "Alliance")
                    
                    -- Check if spell is faction-appropriate
                    local includeSpell = true
                    if isHorde then
                        -- Horde: exclude Alliance-only cities
                        if spellName:match("Stormwind") or spellName:match("Ironforge") or 
                           spellName:match("Darnassus") or spellName:match("Exodar") or
                           spellName:match("Theramore") or spellName:match("Stormshield") or
                           spellName:match("Boralus") then
                            includeSpell = false
                        end
                    elseif isAlliance then
                        -- Alliance: exclude Horde-only cities
                        if spellName:match("Orgrimmar") or spellName:match("Undercity") or
                           spellName:match("Thunder Bluff") or spellName:match("Silvermoon") or
                           spellName:match("Stonard") or spellName:match("Warspear") or
                           spellName:match("Dazar'alor") then
                            includeSpell = false
                        end
                    end
                    
                    if includeSpell and not seen[spellName] then
                        table.insert(foundSpells, spellName)
                        seen[spellName] = true
                    end
                end
            end
            i = i + 1
        end
    -- Legacy API
    elseif GetNumSpellTabs and (GetSpellBookItemName or GetSpellName) then
        local okTabs, numTabs = pcall(GetNumSpellTabs)
        if okTabs and type(numTabs) == "number" and numTabs > 0 then
            for tab = 1, numTabs do
                local okInfo, _, _, offset, numSpells = pcall(function()
                    local n, tex, off, num = GetSpellTabInfo(tab)
                    return n, tex, off, num
                end)
                if okInfo and numSpells and numSpells > 0 then
                    for j = 1, numSpells do
                        local idx = offset + j
                        local spellName
                        if GetSpellBookItemName then
                            local ok, n = pcall(GetSpellBookItemName, idx, BOOKTYPE_SPELL or "spell")
                            if ok then spellName = n end
                        elseif GetSpellName then
                            local ok, n = pcall(GetSpellName, idx, BOOKTYPE_SPELL or "spell")
                            if ok then spellName = n end
                        end
                        
                        if spellName and type(spellName) == "string" and spellName:match("^" .. prefix) then
                            -- Filter by faction
                            local faction = UnitFactionGroup("player")
                            local isHorde = (faction == "Horde")
                            local isAlliance = (faction == "Alliance")
                            
                            local includeSpell = true
                            if isHorde then
                                if spellName:match("Stormwind") or spellName:match("Ironforge") or 
                                   spellName:match("Darnassus") or spellName:match("Exodar") or
                                   spellName:match("Theramore") or spellName:match("Stormshield") or
                                   spellName:match("Boralus") then
                                    includeSpell = false
                                end
                            elseif isAlliance then
                                if spellName:match("Orgrimmar") or spellName:match("Undercity") or
                                   spellName:match("Thunder Bluff") or spellName:match("Silvermoon") or
                                   spellName:match("Stonard") or spellName:match("Warspear") or
                                   spellName:match("Dazar'alor") then
                                    includeSpell = false
                                end
                            end
                            
                            if includeSpell and not seen[spellName] then
                                table.insert(foundSpells, spellName)
                                seen[spellName] = true
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sort alphabetically for consistent ordering
    table.sort(foundSpells)
    
    return foundSpells
end

-- ---------------------------------------------------------------------------
-- ACTION GENERATORS
-- These create structured action data for flyout buttons
-- ---------------------------------------------------------------------------

--- Generate action data for a spell
-- @param spellIdOrName Spell ID or name
-- @return table action - Action data with icon, type, attributes
function FluxFlyoutGenerators.GenerateSpellAction(spellIdOrName)
    local name, _, icon, _, _, _, spellId = SafeGetSpellInfo(spellIdOrName)
    if not name then return nil end
    
    -- Get rank if available (Classic)
    local rank = SafeGetSpellSubtext(spellId)
    local spellNameWithRank = name
    if rank and rank ~= "" then
        spellNameWithRank = name .. "(" .. rank .. ")"
    end
    
    -- Get icon
    icon = icon or SafeGetSpellTexture(spellIdOrName)
    
    return {
        ["$icon"] = icon and ("spell:" .. tostring(spellId)) or nil,
        ["$iconTexture"] = icon,
        ["$name"] = name,
        ["$spellId"] = spellId,
        ["type"] = "spell",
        ["spell"] = spellNameWithRank,
    }
end

--- Generate action data for an item
-- @param itemIdOrName Item ID or name
-- @return table action - Action data with icon, type, attributes
function FluxFlyoutGenerators.GenerateItemAction(itemIdOrName)
    local itemName, _, _, _, _, _, _, _, _, icon = SafeGetItemInfo(itemIdOrName)
    
    -- If item info not cached yet, create a placeholder
    local itemId
    if type(itemIdOrName) == "number" then
        itemId = itemIdOrName
    else
        itemId = tonumber(itemIdOrName)
    end
    
    if not icon and itemId then
        icon = SafeGetItemIcon(itemId)
    end
    
    -- Build macro text for using item
    local macrotext
    if itemId then
        macrotext = "/use item:" .. itemId
    elseif itemIdOrName then
        macrotext = "/use " .. tostring(itemIdOrName)
    end
    
    return {
        ["$icon"] = itemId and ("item:" .. tostring(itemId)) or nil,
        ["$iconTexture"] = icon,
        ["$name"] = itemName or tostring(itemIdOrName),
        ["$itemId"] = itemId,
        ["type"] = "macro",
        ["macrotext"] = macrotext,
    }
end

--- Generate action data for a macro
-- @param macroIdOrName Macro index or name
-- @return table action - Action data with icon, type, attributes
function FluxFlyoutGenerators.GenerateMacroAction(macroIdOrName)
    local name, icon, body = SafeGetMacroInfo(macroIdOrName)
    if not name then return nil end
    
    return {
        ["$icon"] = icon and ("texture:" .. tostring(icon) .. ":" .. tostring(name)) or nil,
        ["$iconTexture"] = icon,
        ["$name"] = name,
        ["$macroIndex"] = type(macroIdOrName) == "number" and macroIdOrName or nil,
        ["type"] = "macro",
        ["macro"] = macroIdOrName,
    }
end

--- Generate action data for a conjure spell (left-click use item, right-click cast spell)
-- @param spellIdOrName Conjure spell ID or name
-- @return table action - Action data with different left/right click behaviors
function FluxFlyoutGenerators.GenerateConjureAction(spellIdOrName)
    local name, _, icon, _, _, _, spellId = SafeGetSpellInfo(spellIdOrName)
    if not name then return nil end
    
    -- Get rank if available
    local rank = SafeGetSpellSubtext(spellId)
    local spellNameWithRank = name
    if rank and rank ~= "" then
        spellNameWithRank = name .. "(" .. rank .. ")"
    end
    
    -- Get the conjured item ID from our mapping
    local itemId = FluxFlyoutData and FluxFlyoutData.ConjureSpellItemMap and FluxFlyoutData.ConjureSpellItemMap[spellId]
    
    -- Get item icon if available
    local itemIcon
    if itemId then
        itemIcon = SafeGetItemIcon(itemId)
    end
    
    -- Build macro for using the item
    local useMacro = itemId and ("/use item:" .. itemId) or ("/cast " .. spellNameWithRank)
    
    return {
        ["$icon"] = itemId and ("item:" .. tostring(itemId)) or ("spell:" .. tostring(spellId)),
        ["$iconTexture"] = itemIcon or icon,
        ["$name"] = name,
        ["$spellId"] = spellId,
        ["$itemId"] = itemId,
        -- Left click uses item, right click casts spell
        ["*type1"] = "macro",
        ["*macrotext1"] = useMacro,
        ["*type2"] = "spell",
        ["spell2"] = spellNameWithRank,
    }
end

--- Generate action data for a temporary weapon enchant (left-click MH, right-click OH)
-- @param itemIdOrName Item ID or name
-- @return table action - Action data with MH/OH click behaviors
function FluxFlyoutGenerators.GenerateWeaponEnchantAction(itemIdOrName)
    local itemName, _, _, _, _, _, _, _, _, icon = SafeGetItemInfo(itemIdOrName)
    
    local itemId
    if type(itemIdOrName) == "number" then
        itemId = itemIdOrName
    else
        itemId = tonumber(itemIdOrName)
    end
    
    if not icon and itemId then
        icon = SafeGetItemIcon(itemId)
    end
    
    -- Build macro: use item, then apply to weapon slot
    -- Slot 16 = Main Hand, Slot 17 = Off Hand
    local useCmd
    if itemId then
        useCmd = "/use item:" .. itemId
    else
        useCmd = "/use " .. tostring(itemIdOrName)
    end
    
    local macrotext = useCmd .. "\n/use [btn:1] 16; [btn:2] 17\n/click StaticPopup1Button1"
    
    return {
        ["$icon"] = itemId and ("item:" .. tostring(itemId)) or nil,
        ["$iconTexture"] = icon,
        ["$name"] = itemName or tostring(itemIdOrName),
        ["$itemId"] = itemId,
        ["type"] = "macro",
        ["macrotext"] = macrotext,
    }
end

--- Generate action for a mixed-type entry (spell:id, item:id, macro:id)
-- @param mixedEntry String like "spell:12345" or "item:6948" or "macro:MyMacro"
-- @return table action - Appropriate action data based on type prefix
function FluxFlyoutGenerators.GenerateMixedAction(mixedEntry)
    if not mixedEntry then return nil end
    
    local entryType, id = mixedEntry:match("^(%w+):(.+)$")
    if not entryType then
        -- No prefix, try to determine type
        local numId = tonumber(mixedEntry)
        if numId then
            -- Could be item or spell, default to item
            return FluxFlyoutGenerators.GenerateItemAction(numId)
        else
            -- Try as spell name
            return FluxFlyoutGenerators.GenerateSpellAction(mixedEntry)
        end
    end
    
    entryType = entryType:lower()
    
    if entryType == "spell" then
        local spellId = tonumber(id) or id
        return FluxFlyoutGenerators.GenerateSpellAction(spellId)
    elseif entryType == "item" then
        local itemId = tonumber(id) or id
        return FluxFlyoutGenerators.GenerateItemAction(itemId)
    elseif entryType == "macro" then
        local macroId = tonumber(id) or id
        return FluxFlyoutGenerators.GenerateMacroAction(macroId)
    end
    
    return nil
end

-- ---------------------------------------------------------------------------
-- LIST GENERATORS
-- These generate arrays of actions based on dynamic content
-- ---------------------------------------------------------------------------

--- Generate actions for weapon enchant items in bags
-- @param list Optional fixed list of item IDs
-- @return table actions, string cacheKey - Array of actions and cache key for change detection
function FluxFlyoutGenerators.GenerateWeaponEnchantList(list)
    local actions = {}
    local itemIds = {}
    
    if list and #list > 0 then
        -- Use provided list
        for _, itemIdOrName in ipairs(list) do
            local itemId = tonumber(itemIdOrName)
            if itemId then
                table.insert(itemIds, itemId)
            end
        end
    else
        -- Scan bags for temp enchant items
        if FluxFlyoutData and FluxFlyoutData.GetBagTempEnchantItems then
            itemIds = FluxFlyoutData.GetBagTempEnchantItems()
        end
    end
    
    -- Sort for consistent cache key
    table.sort(itemIds)
    
    -- Generate actions
    for i = 1, math.min(FluxFlyoutGenerators.MAX_BUTTONS, #itemIds) do
        local action = FluxFlyoutGenerators.GenerateWeaponEnchantAction(itemIds[i])
        if action then
            table.insert(actions, action)
        end
    end
    
    -- Cache key for change detection
    local cacheKey = table.concat(itemIds, ",")
    
    return actions, cacheKey
end

--- Generate actions for conjure spells
-- @param list Optional fixed list of spell names/IDs
-- @return table actions, string cacheKey
function FluxFlyoutGenerators.GenerateConjureList(list)
    local actions = {}
    local spellIds = {}
    
    if list and #list > 0 then
        -- Use provided list
        for _, spellIdOrName in ipairs(list) do
            local action = FluxFlyoutGenerators.GenerateConjureAction(spellIdOrName)
            if action and action["$spellId"] then
                table.insert(actions, action)
                table.insert(spellIds, action["$spellId"])
            end
        end
    else
        -- Get known conjure spells
        if FluxFlyoutData and FluxFlyoutData.GetKnownConjureSpells then
            local knownSpells = FluxFlyoutData.GetKnownConjureSpells()
            for _, spellId in ipairs(knownSpells) do
                local action = FluxFlyoutGenerators.GenerateConjureAction(spellId)
                if action then
                    table.insert(actions, action)
                    table.insert(spellIds, spellId)
                end
            end
        end
    end
    
    -- Limit to max buttons
    while #actions > FluxFlyoutGenerators.MAX_BUTTONS do
        table.remove(actions)
        table.remove(spellIds)
    end
    
    local cacheKey = table.concat(spellIds, ",")
    return actions, cacheKey
end

--- Generate actions for a spell list (professions, portals, totems, etc.)
-- @param subType The spell list sub-type (e.g., "profession", "portal", "totem_fire")
-- @param list Optional fixed list of spell names/IDs
-- @return table actions, string cacheKey
function FluxFlyoutGenerators.GenerateSpellList(subType, list)
    local actions = {}
    local spellIds = {}
    local seenSpells = {} -- Track added spells to prevent duplicates
    
    -- Helper to add a spell if known and not already added
    local function TryAddSpell(spellName)
        if seenSpells[spellName] then return end
        if not IsSpellKnownSafe(spellName) then return end
        
        local action = FluxFlyoutGenerators.GenerateSpellAction(spellName)
        if action and action["$spellId"] then
            seenSpells[spellName] = true
            table.insert(actions, action)
            table.insert(spellIds, action["$spellId"])
        end
    end
    
    if list and #list > 0 then
        -- Use provided list (explicit user-provided spells)
        for _, spellIdOrName in ipairs(list) do
            TryAddSpell(spellIdOrName)
        end
    elseif subType and FluxFlyoutData and FluxFlyoutData.SpellLists then
        -- PRIMARY: Use hardcoded spell lists from FluxFlyoutData
        -- This works on ALL clients (Retail, Classic Era, TBC, Wrath, Cata)
        local spellList = FluxFlyoutData.SpellLists[subType]
        if spellList then
            for _, spellName in ipairs(spellList) do
                TryAddSpell(spellName)
            end
        end
        
        -- ENHANCEMENT (10.0+ only): For portal/teleport, also scan spellbook dynamically
        -- This catches any newly added portals not in our hardcoded list
        local isPortalType = (subType == "portal" or subType == "portal_horde" or subType == "portal_alliance")
        local isTeleportType = (subType == "teleport" or subType == "teleport_horde" or subType == "teleport_alliance")
        
        if isPortalType or isTeleportType then
            -- Only use dynamic scanning on modern clients (10.0+) where the API is reliable
            local majorVersion = FLUX_API and FLUX_API.majorVersion or 12
            if majorVersion >= 10 and C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
                local baseType = isPortalType and "portal" or "teleport"
                local foundSpells = ScanSpellbookForPortals(baseType)
                for _, spellName in ipairs(foundSpells) do
                    TryAddSpell(spellName) -- Will skip if already added from hardcoded list
                end
            end
        end
    end
    
    -- Limit to max buttons
    while #actions > FluxFlyoutGenerators.MAX_BUTTONS do
        table.remove(actions)
        table.remove(spellIds)
    end
    
    local cacheKey = table.concat(spellIds, ",")
    return actions, cacheKey
end

local function IsMountItem(itemID)
    local Spells = _G.FluxInv and _G.FluxInv.Spells
    if Spells and Spells.IsItemAMount then
        return Spells.IsItemAMount(itemID)
    end
    if FluxItemDetection and FluxItemDetection.IsItemAMount then
        return FluxItemDetection.IsItemAMount(itemID)
    end
    if C_MountJournal and C_MountJournal.GetMountFromItem then
        return C_MountJournal.GetMountFromItem(itemID) ~= nil
    end
    return false
end

local function ScanBagMountItems()
    if FluxNCMountItems and FluxNCMountItems.GetBagMountItems then
        -- Convert flyout rows back to scan-shaped tables for GenerateMountList
        local rows = FluxNCMountItems.GetBagMountItems(true) or {}
        local mounts = {}
        for _, item in ipairs(rows) do
            mounts[#mounts + 1] = {
                itemId = item["$itemId"],
                name = item["$name"],
                icon = item["$iconTexture"],
                quality = item["$quality"] or 0,
                ["$itemId"] = item["$itemId"],
                ["$name"] = item["$name"],
                ["$iconTexture"] = item["$iconTexture"],
                ["$quality"] = item["$quality"] or 0,
            }
        end
        return mounts
    end
    local Spells = _G.FluxInv and _G.FluxInv.Spells
    if Spells and Spells.ScanBagsForAllMountItems then
        return Spells.ScanBagsForAllMountItems() or {}
    end
    if FluxItemDetection and FluxItemDetection.ScanBagsForAllMountItems then
        return FluxItemDetection.ScanBagsForAllMountItems() or {}
    end

    local mounts = {}
    local bags = _G.FluxInv and _G.FluxInv.Bags
    local unique = bags and bags.GetUniqueItems and bags.GetUniqueItems() or nil
    if unique then
        for itemID in pairs(unique) do
            if IsMountItem(itemID) then
                local name, _, quality, _, _, _, _, _, _, icon = SafeGetItemInfo(itemID)
                mounts[#mounts + 1] = {
                    itemId = itemID,
                    name = name or ("Item " .. itemID),
                    icon = icon,
                    quality = quality or 0,
                    ["$itemId"] = itemID,
                    ["$name"] = name or ("Item " .. itemID),
                    ["$iconTexture"] = icon,
                    ["$quality"] = quality or 0,
                }
            end
        end
        return mounts
    end

    -- Last resort: walk containers directly
    local GetContainerNumSlots, GetContainerItemID = GetContainerAPI()
    if not GetContainerNumSlots or not GetContainerItemID then
        return mounts
    end

    local numBags = NUM_BAG_SLOTS or 4
    local seen = {}
    for bag = 0, numBags do
        local okSlots, numSlots = pcall(GetContainerNumSlots, bag)
        if okSlots and numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local okItem, itemID = pcall(GetContainerItemID, bag, slot)
                if okItem and itemID and itemID > 0 and not seen[itemID] and IsMountItem(itemID) then
                    seen[itemID] = true
                    local name, _, quality, _, _, _, _, _, _, icon = SafeGetItemInfo(itemID)
                    mounts[#mounts + 1] = {
                        itemId = itemID,
                        name = name or ("Item " .. itemID),
                        icon = icon,
                        quality = quality or 0,
                        ["$itemId"] = itemID,
                        ["$name"] = name or ("Item " .. itemID),
                        ["$iconTexture"] = icon,
                        ["$quality"] = quality or 0,
                    }
                end
            end
        end
    end
    return mounts
end

--- Generate actions for mount items in bags (for legacy clients without mount journal)
-- Scans bags for mount items and returns them sorted by quality, then alphabetically
-- @return table actions, string cacheKey
function FluxFlyoutGenerators.GenerateMountList()
    local actions = {}
    local itemIds = {}

    local mounts = ScanBagMountItems()

    -- Sort mounts by quality (Epic > Rare > etc), then alphabetically
    table.sort(mounts, function(a, b)
        local qualityA = a["$quality"] or a.quality or 0
        local qualityB = b["$quality"] or b.quality or 0
        if qualityA ~= qualityB then
            return qualityA > qualityB  -- Higher quality first
        end
        local nameA = a["$name"] or a.name or ""
        local nameB = b["$name"] or b.name or ""
        return nameA < nameB  -- Alphabetical
    end)

    -- Build actions from mount list
    for i = 1, math.min(FluxFlyoutGenerators.MAX_BUTTONS, #mounts) do
        local mount = mounts[i]
        local itemId = mount["$itemId"] or mount.itemId
        local itemName = mount["$name"] or mount.name
        local icon = mount["$iconTexture"] or mount.icon
        
        -- Get additional item info if not already cached
        if not icon and itemId then
            icon = SafeGetItemIcon(itemId)
        end
        if not itemName and itemId then
            itemName = SafeGetItemInfo(itemId) or ("Item " .. itemId)
        end
        
        -- Build the action - use item type for direct item usage
        -- Must use "item:ID" format for C_Item.IsEquippableItem in SecureTemplates
        local action = {
            ["$icon"] = itemId and ("item:" .. tostring(itemId)) or nil,
            ["$iconTexture"] = icon,
            ["$name"] = itemName,
            ["$itemId"] = itemId,
            ["type"] = "item",
            ["item"] = itemId and ("item:" .. tostring(itemId)) or nil,
        }
        
        table.insert(actions, action)
        table.insert(itemIds, itemId)
    end
    
    -- Cache key for change detection
    local cacheKey = table.concat(itemIds, ",")
    
    return actions, cacheKey
end

--- Generate actions for an item list
-- @param list Array of item IDs or names
-- @return table actions, string cacheKey
function FluxFlyoutGenerators.GenerateItemList(list)
    local actions = {}
    local itemIds = {}
    
    if not list then return actions, "" end
    
    for _, itemIdOrName in ipairs(list) do
        local action = FluxFlyoutGenerators.GenerateItemAction(itemIdOrName)
        if action then
            table.insert(actions, action)
            table.insert(itemIds, action["$itemId"] or tostring(itemIdOrName))
        end
    end
    
    -- Limit to max buttons
    while #actions > FluxFlyoutGenerators.MAX_BUTTONS do
        table.remove(actions)
        table.remove(itemIds)
    end
    
    local cacheKey = table.concat(itemIds, ",")
    return actions, cacheKey
end

--- Generate actions for a mixed list
-- @param list Array of mixed entries (spell:id, item:id, macro:name)
-- @return table actions, string cacheKey
function FluxFlyoutGenerators.GenerateMixedList(list)
    local actions = {}
    local keys = {}
    
    if not list then return actions, "" end
    
    for _, entry in ipairs(list) do
        local action = FluxFlyoutGenerators.GenerateMixedAction(entry)
        if action then
            table.insert(actions, action)
            table.insert(keys, entry)
        end
    end
    
    -- Limit to max buttons
    while #actions > FluxFlyoutGenerators.MAX_BUTTONS do
        table.remove(actions)
        table.remove(keys)
    end
    
    local cacheKey = table.concat(keys, ",")
    return actions, cacheKey
end

-- ---------------------------------------------------------------------------
-- INLINE ACTION GENERATORS (for /cast and /use parsing)
-- ---------------------------------------------------------------------------

--- Generate action for a bare name (tries spell first, then item)
-- Used when parsing /cast and /use commands from macro body
-- @param nameOrId Spell or item name/ID
-- @return table action or nil
function FluxFlyoutGenerators.GenerateInlineAction(nameOrId)
    if not nameOrId then return nil end
    
    -- Try as spell first (most common case for /cast)
    local spellAction = FluxFlyoutGenerators.GenerateSpellAction(nameOrId)
    if spellAction and spellAction["$spellId"] then
        return spellAction
    end
    
    -- Try as item (for /use commands or items like Hearthstone)
    local itemAction = FluxFlyoutGenerators.GenerateItemAction(nameOrId)
    if itemAction then
        return itemAction
    end
    
    return nil
end

--- Generate actions from inline-parsed list (tries spell then item for each)
-- @param list Array of spell/item names from ParseInlineMacroActions
-- @return table actions, string cacheKey
function FluxFlyoutGenerators.GenerateInlineList(list)
    local actions = {}
    local keys = {}
    
    if not list then return actions, "" end
    
    for _, entry in ipairs(list) do
        local action = FluxFlyoutGenerators.GenerateInlineAction(entry)
        if action then
            table.insert(actions, action)
            table.insert(keys, entry)
        end
    end
    
    -- Limit to max buttons
    while #actions > FluxFlyoutGenerators.MAX_BUTTONS do
        table.remove(actions)
        table.remove(keys)
    end
    
    local cacheKey = table.concat(keys, ",")
    return actions, cacheKey
end

-- ---------------------------------------------------------------------------
-- MAIN GENERATOR FUNCTION
-- ---------------------------------------------------------------------------

--- Generate actions based on parsed flyout configuration
-- @param config Parsed flyout configuration from FluxFlyoutParser
-- @return table actions, string cacheKey
function FluxFlyoutGenerators.GenerateActions(config)
    if not config then
        return {}, ""
    end
    
    -- Check for inline parsed list first (from /cast and /use commands)
    if config.inlineList and #config.inlineList > 0 then
        return FluxFlyoutGenerators.GenerateInlineList(config.inlineList)
    end
    
    local mainType = config.mainType
    local subType = config.subType
    local list = config.list
    
    -- Route to appropriate generator
    if mainType == "item_ench_temp" then
        return FluxFlyoutGenerators.GenerateWeaponEnchantList(subType ~= "dynamic" and list or nil)
        
    elseif mainType == "conjure" then
        return FluxFlyoutGenerators.GenerateConjureList(subType ~= "dynamic" and list or nil)
        
    elseif mainType == "spell" then
        return FluxFlyoutGenerators.GenerateSpellList(subType, (subType == "fixed") and list or nil)
        
    elseif mainType == "item" then
        -- Check for special "mounts" subtype (dynamic bag scanning for mount items)
        if subType == "mounts" then
            return FluxFlyoutGenerators.GenerateMountList()
        end
        return FluxFlyoutGenerators.GenerateItemList(list)
        
    elseif mainType == "mixed" then
        return FluxFlyoutGenerators.GenerateMixedList(list)
    end
    
    return {}, ""
end

--- Refresh dynamic content for a specific type
-- @param dynamicType "bag" or "spell"
-- @param config The original flyout configuration
-- @return table actions, string cacheKey
function FluxFlyoutGenerators.RefreshDynamic(dynamicType, config)
    if not config or not config.isDynamic then
        return nil, nil
    end
    
    if config.dynamicType ~= dynamicType then
        return nil, nil
    end
    
    return FluxFlyoutGenerators.GenerateActions(config)
end

-- ---------------------------------------------------------------------------
-- DEBUG
-- ---------------------------------------------------------------------------

function FluxFlyoutGenerators.Test()
    print("|cff00ffff[FluxFlyoutGenerators]|r Running tests...")
    
    -- Test spell action
    print("\n-- Spell Action --")
    local spellAction = FluxFlyoutGenerators.GenerateSpellAction("Fireball")
    if spellAction then
        print("  Name:", spellAction["$name"])
        print("  Icon:", spellAction["$iconTexture"])
        print("  Type:", spellAction["type"])
    else
        print("  (Spell not found or not known)")
    end
    
    -- Test item action
    print("\n-- Item Action --")
    local itemAction = FluxFlyoutGenerators.GenerateItemAction(6948) -- Hearthstone
    if itemAction then
        print("  Name:", itemAction["$name"])
        print("  Icon:", itemAction["$iconTexture"])
        print("  Macro:", itemAction["macrotext"])
    else
        print("  (Item not found)")
    end
    
    -- Test conjure action
    print("\n-- Conjure Action --")
    local conjureAction = FluxFlyoutGenerators.GenerateConjureAction("Conjure Refreshment")
    if conjureAction then
        print("  Name:", conjureAction["$name"])
        print("  SpellId:", conjureAction["$spellId"])
        print("  ItemId:", conjureAction["$itemId"])
    else
        print("  (Conjure spell not found)")
    end
    
    print("\n|cff00ffff[FluxFlyoutGenerators]|r Tests complete")
end

SLASH_FLYOUTGEN1 = "/flyoutgen"
SlashCmdList["FLYOUTGEN"] = function(msg)
    FluxFlyoutGenerators.Test()
end

