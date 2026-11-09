-- FluxFlyoutParser.lua
-- Parse /flyout macro syntax for custom flyout system
-- Supports all WoW clients: Retail, Classic, Legacy
local addonName, ns = ...

local FluxFlyoutParser = {}
_G.FluxFlyoutParser = FluxFlyoutParser

-- ---------------------------------------------------------------------------
-- CONSTANTS
-- ---------------------------------------------------------------------------

-- Valid main types
FluxFlyoutParser.MAIN_TYPES = {
    ["item_ench_temp"] = true,
    ["conjure"] = true,
    ["spell"] = true,
    ["item"] = true,
    ["mixed"] = true,
}

-- Valid spell sub-types (for dynamic generation)
FluxFlyoutParser.SPELL_SUBTYPES = {
    ["profession"] = true,
    ["portal"] = true,
    ["portal_horde"] = true,
    ["portal_alliance"] = true,
    ["teleport"] = true,
    ["teleport_horde"] = true,
    ["teleport_alliance"] = true,
    ["totem"] = true,
    ["totem_earth"] = true,
    ["totem_fire"] = true,
    ["totem_air"] = true,
    ["totem_water"] = true,
    ["trap"] = true,
    ["track"] = true,
    ["aspect"] = true,
    ["warlockpet"] = true,
    ["shaman_weapon"] = true,
    ["presence"] = true,
    ["shapeshift"] = true,
    ["aura"] = true,
    ["blessing"] = true,
    ["stance"] = true,
    ["chakra"] = true,
    ["fixed"] = true,
}

-- Valid item sub-types (for dynamic generation)
FluxFlyoutParser.ITEM_SUBTYPES = {
    ["mounts"] = true,  -- Dynamic bag scanning for mount items
    ["fixed"] = true,   -- Fixed list of items
}

-- Valid directions
FluxFlyoutParser.DIRECTIONS = {
    ["left"] = "LEFT",
    ["right"] = "RIGHT",
    ["up"] = "UP",
    ["down"] = "DOWN",
}

-- Valid cooldown styles
FluxFlyoutParser.COOLDOWN_STYLES = {
    ["cooldown"] = "BLACK",
    ["cooldown_white"] = "WHITE",
    ["nocooldown"] = "NONE",
}

-- The slash command we're looking for
FluxFlyoutParser.SLASH_COMMAND = "/flyout"

-- ---------------------------------------------------------------------------
-- STRING UTILITIES
-- ---------------------------------------------------------------------------

-- Trim whitespace from both ends of a string
local function trim(s)
    if not s then return "" end
    return s:gsub("^%s*(.-)%s*$", "%1")
end

-- Split a string by delimiter
local function split(str, delimiter)
    if not str then return {} end
    delimiter = delimiter or ","
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        local trimmed = trim(match)
        if trimmed ~= "" then
            table.insert(result, trimmed)
        end
    end
    return result
end

-- ---------------------------------------------------------------------------
-- PARSING FUNCTIONS
-- ---------------------------------------------------------------------------

--- Check if a macro body contains a /flyout command
-- @param macroBody The full macro text
-- @return boolean, string - true and the flyout line if found, false and nil otherwise
function FluxFlyoutParser.ContainsFlyoutCommand(macroBody)
    if not macroBody or macroBody == "" then
        return false, nil
    end
    
    -- Look for /flyout at the start of a line
    for line in macroBody:gmatch("[^\r\n]+") do
        local trimmedLine = trim(line)
        if trimmedLine:match("^" .. FluxFlyoutParser.SLASH_COMMAND .. "%s") or
           trimmedLine:match("^" .. FluxFlyoutParser.SLASH_COMMAND .. "$") then
            -- Extract everything after /flyout
            local flyoutContent = trimmedLine:sub(#FluxFlyoutParser.SLASH_COMMAND + 1)
            return true, trim(flyoutContent)
        end
    end
    
    return false, nil
end

--- Parse the options section [options] from a flyout command
-- Supports TWO syntaxes:
--   1. Type keyword WITHOUT brackets: /flyout spell teleport (preferred, no errors)
--   2. Type keyword in brackets: /flyout [spell] teleport (legacy, may cause WoW warnings)
-- 
-- @param flyoutLine The content after /flyout (e.g., "spell teleport" or "[spell,up] portal")
-- @return table options, string remainder - parsed options and the rest of the line
function FluxFlyoutParser.ParseOptions(flyoutLine)
    if not flyoutLine then
        return {}, ""
    end
    
    local options = {}
    local remainder = trim(flyoutLine)
    
    -- FIRST: Check for type keyword at start WITHOUT brackets
    -- This is the preferred syntax: /flyout spell teleport, /flyout item Hearthstone
    -- It avoids WoW's macro parser treating [item] as a macro conditional
    local typeKeywords = {"item_ench_temp", "conjure", "spell", "item", "mixed"}  -- Longer keywords first
    local foundTypeKeyword = nil
    local lowerRemainder = remainder:lower()
    
    for _, keyword in ipairs(typeKeywords) do
        -- Match keyword at start followed by space or end of string
        local pattern = "^" .. keyword .. "%s+"
        local patternEnd = "^" .. keyword .. "$"
        if lowerRemainder:match(pattern) then
            foundTypeKeyword = keyword
            -- Remove the keyword and following whitespace
            remainder = remainder:gsub("^%S+%s+", "", 1)
            break
        elseif lowerRemainder:match(patternEnd) then
            -- Just the type keyword with no list (e.g., "/flyout spell" by itself)
            foundTypeKeyword = keyword
            remainder = ""
            break
        end
    end
    
    -- SECOND: Look for [options] at the start (legacy/extended syntax)
    local optStart, optEnd, optString = remainder:find("^%s*%[([^%]]*)%]%s*")
    
    if optStart and optString then
        -- Parse comma-separated options
        local optList = split(optString, ",")
        for _, opt in ipairs(optList) do
            options[#options + 1] = opt:lower()
        end
        -- Get the remainder after the options
        remainder = remainder:sub(optEnd + 1)
    end
    
    -- Add type keyword to options if found (at the beginning for priority)
    if foundTypeKeyword then
        table.insert(options, 1, foundTypeKeyword)
    end
    
    return options, trim(remainder)
end

--- Parse the list portion of a flyout command
-- @param listString The comma-separated list (e.g., "portal" or "Hearthstone, Dark Portal")
-- @return table list - array of list items
function FluxFlyoutParser.ParseList(listString)
    if not listString or listString == "" then
        return {}
    end
    
    return split(listString, ",")
end

--- Extract direction from options
-- @param options Array of option strings
-- @return string direction - "UP", "DOWN", "LEFT", "RIGHT", or nil
function FluxFlyoutParser.ExtractDirection(options)
    for _, opt in ipairs(options) do
        local dir = FluxFlyoutParser.DIRECTIONS[opt]
        if dir then
            return dir
        end
    end
    return nil -- Default will be determined by button position
end

--- Extract cooldown style from options
-- @param options Array of option strings
-- @return string style - "BLACK", "WHITE", "NONE", or nil
function FluxFlyoutParser.ExtractCooldownStyle(options)
    for _, opt in ipairs(options) do
        local style = FluxFlyoutParser.COOLDOWN_STYLES[opt]
        if style then
            return style
        end
    end
    return nil -- No explicit cooldown preference
end

--- Extract main type from options
-- @param options Array of option strings
-- @return string mainType - "spell", "item", "conjure", "item_ench_temp", "mixed"
function FluxFlyoutParser.ExtractMainType(options)
    for _, opt in ipairs(options) do
        if FluxFlyoutParser.MAIN_TYPES[opt] then
            return opt
        end
    end
    return "mixed" -- Default to mixed if not specified
end

--- Determine if the flyout is dynamic based on sub-type
-- @param mainType The main type (spell, conjure, etc.)
-- @param subType The sub-type (profession, portal, dynamic, mounts, etc.)
-- @return boolean isDynamic, string dynamicType
function FluxFlyoutParser.IsDynamic(mainType, subType)
    if mainType == "item_ench_temp" then
        if subType == "dynamic" then
            return true, "bag"
        end
    elseif mainType == "conjure" then
        if subType == "dynamic" then
            return true, "spell"
        end
    elseif mainType == "spell" then
        -- If subType is a known spell category, it's dynamic
        if FluxFlyoutParser.SPELL_SUBTYPES[subType] and subType ~= "fixed" then
            return true, "spell"
        end
    elseif mainType == "item" then
        -- If subType is "mounts", it's a dynamic bag scan
        if subType == "mounts" then
            return true, "bag"
        end
    end
    
    return false, nil
end

--- Parse a complete flyout line into a structured result
-- @param flyoutLine The full flyout command content (after /flyout)
-- @return table result - structured flyout configuration
function FluxFlyoutParser.ParseFlyoutLine(flyoutLine)
    local result = {
        direction = nil,        -- "UP", "DOWN", "LEFT", "RIGHT"
        cooldownStyle = nil,    -- "BLACK", "WHITE", "NONE"
        mainType = "mixed",     -- "spell", "item", "conjure", "item_ench_temp", "mixed"
        subType = nil,          -- "profession", "portal", "dynamic", "fixed", etc.
        list = {},              -- Array of items/spells/etc.
        isDynamic = false,      -- Whether content is dynamically generated
        dynamicType = nil,      -- "bag" or "spell" for update tracking
        raw = flyoutLine,       -- Original line for debugging
    }
    
    if not flyoutLine or flyoutLine == "" then
        return result
    end
    
    -- Parse options
    local options, remainder = FluxFlyoutParser.ParseOptions(flyoutLine)
    
    -- Extract known options
    result.direction = FluxFlyoutParser.ExtractDirection(options)
    result.cooldownStyle = FluxFlyoutParser.ExtractCooldownStyle(options)
    result.mainType = FluxFlyoutParser.ExtractMainType(options)
    
    -- Parse the list
    local list = FluxFlyoutParser.ParseList(remainder)
    
    -- Check if first item is a sub-type
    if #list > 0 then
        local firstItem = list[1]:lower()
        
        -- For item_ench_temp and conjure, check for dynamic/fixed
        if result.mainType == "item_ench_temp" or result.mainType == "conjure" then
            if firstItem == "dynamic" or firstItem == "fixed" then
                result.subType = firstItem
                table.remove(list, 1)
            end
        -- For spell type, check for known sub-types
        elseif result.mainType == "spell" then
            if FluxFlyoutParser.SPELL_SUBTYPES[firstItem] then
                result.subType = firstItem
                table.remove(list, 1)
            end
        -- For item type, check for known item sub-types (mounts, fixed)
        elseif result.mainType == "item" then
            if FluxFlyoutParser.ITEM_SUBTYPES[firstItem] then
                result.subType = firstItem
                table.remove(list, 1)
            end
        -- For mixed, check for fixed
        elseif firstItem == "fixed" then
            result.subType = "fixed"
            table.remove(list, 1)
        end
    end
    
    result.list = list
    
    -- Determine if dynamic
    result.isDynamic, result.dynamicType = FluxFlyoutParser.IsDynamic(result.mainType, result.subType)
    
    return result
end

--- Parse a full macro body and extract flyout configuration
-- @param macroBody The complete macro text
-- @return table result or nil - structured flyout configuration or nil if no flyout
function FluxFlyoutParser.ParseMacro(macroBody)
    local hasFlyout, flyoutLine = FluxFlyoutParser.ContainsFlyoutCommand(macroBody)
    
    if not hasFlyout then
        return nil
    end
    
    return FluxFlyoutParser.ParseFlyoutLine(flyoutLine)
end

--- Generate a flyout command string from a configuration
-- @param config Table with direction, cooldownStyle, mainType, subType, list
-- @return string - The /flyout command line
function FluxFlyoutParser.GenerateFlyoutCommand(config)
    local parts = {}
    
    -- Build options
    local options = {}
    
    -- Add main type if not mixed
    if config.mainType and config.mainType ~= "mixed" then
        table.insert(options, config.mainType)
    end
    
    -- Add direction
    if config.direction then
        local dirLower = config.direction:lower()
        table.insert(options, dirLower)
    end
    
    -- Add cooldown style
    if config.cooldownStyle then
        if config.cooldownStyle == "BLACK" then
            table.insert(options, "cooldown")
        elseif config.cooldownStyle == "WHITE" then
            table.insert(options, "cooldown_white")
        elseif config.cooldownStyle == "NONE" then
            table.insert(options, "nocooldown")
        end
    end
    
    -- Build the command
    local cmd = FluxFlyoutParser.SLASH_COMMAND
    
    if #options > 0 then
        cmd = cmd .. " [" .. table.concat(options, ",") .. "]"
    end
    
    -- Add sub-type
    local listParts = {}
    if config.subType then
        table.insert(listParts, config.subType)
    end
    
    -- Add list items
    if config.list and #config.list > 0 then
        for _, item in ipairs(config.list) do
            table.insert(listParts, item)
        end
    end
    
    if #listParts > 0 then
        cmd = cmd .. " " .. table.concat(listParts, ", ")
    end
    
    return cmd
end

-- ---------------------------------------------------------------------------
-- INLINE MACRO PARSING
-- ---------------------------------------------------------------------------

--- Parse /cast and /use commands from macro body to build flyout list
-- When /flyout has an empty list, this extracts spell/item names from the rest of the macro
-- @param macroBody The full macro text
-- @return table list - Array of spell/item names
function FluxFlyoutParser.ParseInlineMacroActions(macroBody)
    if not macroBody then return {} end
    
    local list = {}
    
    for line in macroBody:gmatch("[^\r\n]+") do
        local cleanLine = trim(line)
        -- Skip comments, flyout commands, stopmacro, stopcast, showtooltip
        if not cleanLine:match("^#") and 
           not cleanLine:match("^/flyout") and
           not cleanLine:match("^/stopmacro") and
           not cleanLine:match("^/stopcast") and
           not cleanLine:match("^/stopcasting") then
            local cmd, args = cleanLine:match("^/([%w]+)%s+(.*)")
            if cmd then
                cmd = cmd:lower()
                if cmd == "cast" or cmd == "use" or cmd == "castsequence" or cmd == "castrandom" or cmd == "userandom" then
                    -- Split by semicolon for multiple actions on one line
                    local parts = {strsplit(";", args)}
                    for _, part in ipairs(parts) do
                        -- Remove macro conditionals [mod:shift] etc.
                        local clean = part:gsub("%b[]", "")
                        clean = trim(clean)
                        -- Skip reset= parameters for castsequence
                        if clean ~= "" and not clean:match("^reset=") then
                            table.insert(list, clean)
                        end
                    end
                end
            end
        end
    end
    
    return list
end

-- ---------------------------------------------------------------------------
-- DEBUG FUNCTIONS
-- ---------------------------------------------------------------------------

--- Print parsed flyout configuration
-- @param config The parsed configuration table
function FluxFlyoutParser.DebugPrint(config)
    if not config then
        print("|cff00ffff[FluxFlyoutParser]|r No flyout configuration")
        return
    end
    
    print("|cff00ffff[FluxFlyoutParser]|r Parsed flyout:")
    print("  Direction:", config.direction or "default")
    print("  Cooldown:", config.cooldownStyle or "default")
    print("  Main Type:", config.mainType)
    print("  Sub Type:", config.subType or "none")
    print("  Is Dynamic:", tostring(config.isDynamic))
    print("  Dynamic Type:", config.dynamicType or "none")
    print("  List Items:", #config.list)
    for i, item in ipairs(config.list) do
        print("    [" .. i .. "]:", item)
    end
end

--- Test parser with a sample macro
function FluxFlyoutParser.Test()
    local testMacros = {
        "/flyout [spell,up] portal",
        "/flyout [item] Hearthstone, Dark Portal",
        "/flyout [conjure] dynamic",
        "/flyout [item_ench_temp,cooldown] dynamic",
        "/flyout [mixed] spell:190336, item:6948",
        "#showtooltip\n/flyout [spell] profession\n/stopmacro [btn:1]\n/cast Alchemy",
    }
    
    print("|cff00ffff[FluxFlyoutParser]|r Running tests...")
    for i, macro in ipairs(testMacros) do
        print("\n--- Test " .. i .. " ---")
        print("Input:", macro:gsub("\n", "\\n"))
        local config = FluxFlyoutParser.ParseMacro(macro)
        FluxFlyoutParser.DebugPrint(config)
    end
end

-- Slash command for testing
SLASH_FLYOUTPARSE1 = "/flyoutparse"
SlashCmdList["FLYOUTPARSE"] = function(msg)
    if msg and msg ~= "" then
        local config = FluxFlyoutParser.ParseFlyoutLine(msg)
        FluxFlyoutParser.DebugPrint(config)
    else
        FluxFlyoutParser.Test()
    end
end

