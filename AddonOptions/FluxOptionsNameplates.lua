local addonName, ns = ...

-- /fluxui Nameplates: the only place Flux nameplate options live, on every client.
-- Nothing here is added to Blizzard's Nameplates or Combat settings pages.

ns.FluxOptionsLocale = ns.FluxOptionsLocale or {}
local L = ns.FluxOptionsLocale

local function Label(key, fallback)
    local localeKey = "NP_" .. key
    L[localeKey] = L[localeKey] or fallback
    return L[localeKey]
end

local function NativeWrite()
    local settings = ns.Flux and ns.Flux.BlizzardSettings
    return settings and settings.Write
end

local function ReadCVar(cvar)
    local write = NativeWrite()
    if not write then return nil end
    local ok, value = pcall(write.Get, cvar)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
    return nil
end

local function NativeLocked()
    local write = NativeWrite()
    return not write or not write.CanWriteNow()
end

local function SetCVar(cvar, value)
    if not NativeLocked() and ReadCVar(cvar) ~= nil then NativeWrite().CVar(cvar, value) end
end

local function SelectOption(key, title, order, entries, get, set, hidden, disabled)
    local values, sorting = {}, {}
    for _, choice in ipairs(entries) do
        local value = choice[1]
        sorting[#sorting + 1] = value
        values[value] = Label(key .. "_" .. tostring(value), choice[2])
    end
    return {
        type = "select", width = "full", name = Label(key, title), order = order,
        values = values, sorting = sorting, get = get, set = set, hidden = hidden, disabled = disabled,
    }
end

local function Header(key, title, order)
    return { type = "header", name = Label(key, title), order = order }
end

local function NativeChoice(cvar, title, order, group, choices)
    local values = {}
    for _, choice in ipairs(choices) do
        local index = group and group[choice[1]]
        if type(index) == "number" then values[#values + 1] = { index, choice[2] } end
    end
    return SelectOption(cvar, title, order, values,
        function() return tonumber(ReadCVar(cvar)) end,
        function(_, value) SetCVar(cvar, value) end,
        function() return #values == 0 or ReadCVar(cvar) == nil end, NativeLocked)
end

local function NativeRange(cvar, title, order, min, max, step, isPercent)
    return {
        type = "range", width = "full", name = Label(cvar, title), order = order,
        min = min, max = max, step = step, isPercent = isPercent,
        hidden = function() return tonumber(ReadCVar(cvar)) == nil end, disabled = NativeLocked,
        get = function() return tonumber(ReadCVar(cvar)) end,
        set = function(_, value) SetCVar(cvar, value) end,
    }
end

local function NativeToggle(cvar, title, order, enum, flag, invert)
    local function BitIndex()
        local group = enum and Enum and Enum[enum]
        return group and group[flag]
    end
    local function Read()
        local value = ReadCVar(cvar)
        if value == nil then return end
        if not enum then return (value == "1") ~= (invert == true) end
        local index = BitIndex()
        local getBit = (C_CVar and C_CVar.GetCVarBitfield) or GetCVarBitfield
        if not (type(index) == "number" and index > 0 and getBit) then return end
        local ok, enabled = pcall(getBit, cvar, index)
        if ok and not (issecretvalue and issecretvalue(enabled)) then return enabled end
    end
    return {
        type = "toggle", width = "half", name = Label(cvar .. "_" .. (flag or "toggle"), title), order = order,
        hidden = function() return Read() == nil end, disabled = NativeLocked, get = Read,
        set = function(_, enabled)
            if NativeLocked() or Read() == nil then return end
            if enum then
                return NativeWrite().Bit(cvar, BitIndex(), enabled)
            else
                SetCVar(cvar, enabled ~= (invert == true) and "1" or "0")
            end
        end,
    }
end

local function AddNativeBits(args, prefix, cvar, enum, firstOrder, flags)
    for index, flag in ipairs(flags) do
        args[prefix .. flag[1]] = NativeToggle(cvar, flag[2], firstOrder + index, enum, flag[1])
    end
end

local function NameplatePreferences()
    if type(FluxUI_DB) ~= "table" then FluxUI_DB = {} end
    if type(FluxUI_DB.nameplateAppearance) ~= "table" then FluxUI_DB.nameplateAppearance = {} end
    return FluxUI_DB.nameplateAppearance
end

local function AddPlateOptions(args)
    local enumerations = Enum or {}
    local styles = {
        { "Modern", UNIT_NAMEPLATES_STYLE_MODERN or "Modern" },
        { "Thin", UNIT_NAMEPLATES_STYLE_THIN or "Thin" },
        { "Block", UNIT_NAMEPLATES_STYLE_BLOCK or "Block" },
        { "HealthFocus", UNIT_NAMEPLATES_STYLE_HEALTH_FOCUS or "Health focus" },
        { "CastFocus", UNIT_NAMEPLATES_STYLE_CAST_FOCUS or "Cast focus" },
        { "Legacy", UNIT_NAMEPLATES_STYLE_LEGACY or "Legacy" },
    }
    if not (NameplatesOverrides and NameplatesOverrides.ShowClassicStyleOption)
        or NameplatesOverrides.ShowClassicStyleOption() then
        table.insert(styles, 1, { "Classic", UNIT_NAMEPLATES_STYLE_CLASSIC or "Classic" })
    end
    args.style_frame = Header("FRAME", "Frame", 1)
    args.style_style = NativeChoice("nameplateStyle", UNIT_NAMEPLATES_STYLE or "Nameplate style", 2, enumerations.NamePlateStyle, styles)
    args.style_size = NativeChoice("nameplateSize", UNIT_NAMEPLATES_GLOBAL_SCALE or "Nameplate size", 3, enumerations.NamePlateSize, {
        { "Small", "Small" }, { "Medium", "Medium" }, { "Large", "Large" },
        { "ExtraLarge", "Extra large" }, { "Huge", "Huge" },
    })
    args.style_health = Header("HEALTH_TEXT", "Health and identification", 10)
    AddNativeBits(args, "style_", "nameplateInfoDisplay", "NamePlateInfoDisplay", 10, {
        { "CurrentHealthValue", "Health amount" }, { "CurrentHealthPercent", "Health percent" }, { "RarityIcon", "Rare and elite icon" },
    })
    for _, key in ipairs({ "CurrentHealthValue", "CurrentHealthPercent" }) do
        local option = args["style_" .. key]
        local setBit = option.set
        option.set = function(info, value)
            if setBit(info, value) then
                local preferences = NameplatePreferences()
                if type(preferences.healthText) ~= "table" then preferences.healthText = {} end
                preferences.healthText[key] = value == true
            end
        end
    end
    args.style_classHealth = NativeToggle("nameplateShowClassColor", "Enemy player class colors", 14)
    args.style_friendlyClass = NativeToggle("nameplateUseClassColorForFriendlyPlayerUnitNames", "Friendly player class colors", 15)
end

local function AppearanceOptionValue(key, default)
    local db = FluxUI_DB and FluxUI_DB.nameplateAppearance
    local value = type(db) == "table" and rawget(db, key)
    if value == nil or value == false then return default end
    return value
end

local function SetAppearanceOption(key, value)
    local db = NameplatePreferences()
    db[key] = value
    if FluxNamePlates_RefreshFromDB then FluxNamePlates_RefreshFromDB() end
end

local function AddComponentOptions(args)
    args.cast_display = Header("CAST_DISPLAY", "Cast display", 1)
    local casts = {
        { "SpellName", "Spell name" }, { "SpellIcon", "Spell icon" }, { "SpellTarget", "Cast target" },
        { "HighlightWhenCastTarget", "Highlight casts targeting you" },
    }
    if not (NameplatesOverrides and NameplatesOverrides.ShowHighlightImportantCastsOption)
        or NameplatesOverrides.ShowHighlightImportantCastsOption() then
        table.insert(casts, 4, { "HighlightImportantCasts", "Highlight important casts" })
    end
    AddNativeBits(args, "cast_", "nameplateCastBarDisplay", "NamePlateCastBarDisplay", 1, casts)

    args.aura_layout = Header("AURA_LAYOUT", "Aura layout", 1)
    args.aura_scale = NativeRange("nameplateAuraScale", "Aura icon scale", 2, 0.7, 1.4, 0.1, true)
    args.aura_countdown = SelectOption("AURA_COUNTDOWN", "Aura countdown numbers", 3, {
        { "middle", "Center of icon" }, { "bottom", "Bottom of icon" }, { "below", "Below icon" }, { "none", "Off" },
    }, function() return AppearanceOptionValue("auraCountdown", "middle") end,
        function(_, value) SetAppearanceOption("auraCountdown", value) end)
    args.aura_onlyMine = {
        type = "toggle", width = "full", order = 4,
        name = Label("AURA_ONLY_MINE", "Only show my debuffs"),
        desc = Label("AURA_ONLY_MINE_DESC",
            "Show debuffs and crowd control applied by you, your pet, or your vehicle. Buffs keep their own settings."),
        get = function() return AppearanceOptionValue("onlyMyDebuffs", false) == true end,
        set = function(_, value) SetAppearanceOption("onlyMyDebuffs", value == true) end,
    }
    args.aura_enemyNpc = Header("NPC_AURAS", "Enemy NPC auras", 10)
    AddNativeBits(args, "aura_npc", "nameplateEnemyNpcAuraDisplay", "NamePlateEnemyNpcAuraDisplay", 10, {
        { "Buffs", "Show buffs" }, { "Debuffs", "Show debuffs" }, { "CrowdControl", "Show crowd control" },
    })
    args.aura_enemyPlayer = Header("ENEMY_PLAYER_AURAS", "Enemy player auras", 20)
    AddNativeBits(args, "aura_enemy", "nameplateEnemyPlayerAuraDisplay", "NamePlateEnemyPlayerAuraDisplay", 20, {
        { "Buffs", "Show buffs" }, { "Debuffs", "Show debuffs" }, { "LossOfControl", "Show loss of control" },
    })
    args.aura_friendlyPlayer = Header("FRIENDLY_PLAYER_AURAS", "Friendly player auras", 30)
    AddNativeBits(args, "aura_friendly", "nameplateFriendlyPlayerAuraDisplay", "NamePlateFriendlyPlayerAuraDisplay", 30, {
        { "Buffs", "Show buffs" }, { "Debuffs", "Show debuffs" }, { "LossOfControl", "Show loss of control" },
    })
    args.aura_friendlyDebuffs = NativeToggle("nameplateShowDebuffsOnFriendly", "Show debuffs on friendly units", 34)

    args.target_appearance = Header("TARGET_APPEARANCE", "Targeted plates", 1)
    args.target_scale = NativeRange("nameplateSelectedScale", "Current target scale", 2, 0.5, 2, 0.05, true)
    args.target_occluded = NativeRange("nameplateOccludedAlphaMult", "Out of sight opacity", 3, 0, 1, 0.05, true)
    args.target_sticky = NativeToggle("deselectOnClick", "Sticky targeting", 4, nil, nil, true)

    args.visible_native = Header("GAME_VISIBILITY", "Game nameplate visibility", 1)
    args.visible_all = NativeToggle("nameplateShowAll", "Always show nameplates", 2)
    args.visible_enemies = NativeToggle("nameplateShowEnemies", "Enemy nameplates", 3)
    args.visible_enemyMinions = NativeToggle("nameplateShowEnemyMinions", "Enemy minions", 4)
    args.visible_enemyMinor = NativeToggle("nameplateShowEnemyMinus", "Minor enemy NPCs", 5)
    args.visible_friendly = NativeToggle("nameplateShowFriendlyNpcs", "Friendly NPCs", 6)
    args.visible_friendlyPlayers = NativeToggle("nameplateShowFriendlyPlayers", "Friendly players", 7)
    args.visible_offscreen = NativeToggle("nameplateShowOffscreen", "Keep offscreen plates visible", 8)
    args.visible_stackEnemies = NativeToggle("nameplateStackingTypes", "Stack enemy plates", 9, "NamePlateStackType", "Enemy")
    args.visible_stackFriends = NativeToggle("nameplateStackingTypes", "Stack friendly plates", 10, "NamePlateStackType", "Friendly")
    args.visible_friendlyNames = NativeToggle("nameplateShowOnlyNameForFriendlyPlayerUnits", "Names only for friendly players", 11)

    args.font_overlays = Header("FONT_OVERLAYS", "FluxUI overlay text", 1)
    args.font_countdownSize = {
        type = "range", width = "full", name = Label("COUNTDOWN_SIZE", "Aura countdown text size"), order = 2,
        min = 8, max = 24, step = 1,
        desc = Label("COUNTDOWN_SIZE_DESC", "Size of FluxUI's aura countdown text. The game draws the plate's name and health text."),
        get = function() return AppearanceOptionValue("countdownSize", 12) end,
        set = function(_, value) SetAppearanceOption("countdownSize", value) end,
    }
end

local function ThreatAPI()
    return ns.Flux and ns.Flux.Threat
end

--- Level overlay runs on every client that loads NamePlates (NamePlates/Level.lua).
local function IsLevelOverlaySupported()
    local NP = ns.Flux and ns.Flux.NamePlates
    if NP and NP.IsLevelSupported then
        return NP.IsLevelSupported()
    end
    local client = ns.Flux and ns.Flux.Client
    return client and client.isAnyClassic and true or false
end

--- Live store read by NamePlates/Core.lua (FluxUI_DB SavedVariables).
local function EnsureNameplateThreatDB()
    if type(FluxUI_DB) ~= "table" then
        FluxUI_DB = {}
    end
    local db = FluxUI_DB.nameplateThreat
    if type(db) ~= "table" then
        db = {}
        FluxUI_DB.nameplateThreat = db
    end

    local defaults = FluxOptionsDefaults
        and FluxOptionsDefaults.global
        and FluxOptionsDefaults.global.nameplateThreat
    defaults = defaults or {
        npcThreatBorder = true,
        enemyPlayerTarget = true,
        visibilityMode = "group",
        levelOverlayEnabled = true,
        questOverlayEnabled = true,
    }

    if db.npcThreatBorder == nil then
        db.npcThreatBorder = defaults.npcThreatBorder ~= false
    end
    if db.enemyPlayerTarget == nil then
        db.enemyPlayerTarget = defaults.enemyPlayerTarget ~= false
    end
    if db.visibilityMode ~= "always" and db.visibilityMode ~= "never" and db.visibilityMode ~= "group" then
        db.visibilityMode = defaults.visibilityMode or "group"
    end
    if db.levelOverlayEnabled == nil then
        db.levelOverlayEnabled = defaults.levelOverlayEnabled ~= false
    end
    if db.questOverlayEnabled == nil then
        db.questOverlayEnabled = defaults.questOverlayEnabled ~= false
    end
    return db
end

local function RefreshNameplatesFromDB()
    if FluxNamePlates_RefreshFromDB then
        FluxNamePlates_RefreshFromDB()
    end
end

local function BlizzardThreatToggle(key, name, desc, order)
    return {
        type = "toggle",
        name = name,
        desc = desc,
        order = order,
        width = "full",
        get = function()
            local api = ThreatAPI()
            if api and api.NameplateDisplayEnabled then
                return api.NameplateDisplayEnabled(key)
            end
            return true
        end,
        set = function(_, v)
            local api = ThreatAPI()
            if api and api.SetNameplateDisplay then
                api.SetNameplateDisplay(key, v)
            end
        end,
    }
end

local function BuildNameplatesOptions()
    local args = {
        headerThreat = {
            type = "header",
            name = "Threat",
            order = 1,
        },
        threatDesc = {
            type = "description",
            name = "Flux draws a threat-colored border and your threat rank and percent (100% = you have aggro) on enemy NPC nameplates. Enemy players targeting you get a red border.\n",
            order = 2,
            fontSize = "small",
        },
        visibilityMode = ns.FluxOptionsThreatVisibilityOption(3),
        npcThreatBorder = {
            type = "toggle",
            name = "NPC threat border + rank/%",
            desc = "Color the nameplate border from your threat on enemy NPCs and show threat rank and percent under the health bar.",
            order = 4,
            width = "full",
            get = function()
                return EnsureNameplateThreatDB().npcThreatBorder ~= false
            end,
            set = function(_, v)
                EnsureNameplateThreatDB().npcThreatBorder = v and true or false
                RefreshNameplatesFromDB()
            end,
        },
        showNumericThreat = {
            type = "toggle",
            name = "Show threat percentage",
            desc = "Shows tank-relative threat % (100% = you have aggro) on nameplates and on the Flux target/focus threat bar.",
            order = 4.5,
            width = "full",
            get = function()
                local api = ThreatAPI()
                if api and api.ShowNumeric then
                    return api.ShowNumeric()
                end
                return true
            end,
            set = function(_, v)
                local api = ThreatAPI()
                if api and api.SetShowNumeric then
                    api.SetShowNumeric(v)
                end
                RefreshNameplatesFromDB()
                if FluxUnitFrames_ApplyThreatBarOptionsFromDB then
                    FluxUnitFrames_ApplyThreatBarOptionsFromDB()
                end
            end,
        },
        enemyPlayerTarget = {
            type = "toggle",
            name = "Enemy player targeting you",
            desc = "Red nameplate border when an enemy player is targeting you.",
            order = 5,
            width = "full",
            get = function()
                return EnsureNameplateThreatDB().enemyPlayerTarget ~= false
            end,
            set = function(_, v)
                EnsureNameplateThreatDB().enemyPlayerTarget = v and true or false
                RefreshNameplatesFromDB()
            end,
        },
        headerBlizzardThreat = {
            type = "header",
            name = "Blizzard nameplate threat",
            order = 6,
        },
        blizzardThreatDesc = {
            type = "description",
            name = "The game's own Progressive / Flash / Health Bar Color threat display (nameplateThreatDisplay). Flux writes these bits with SetCVarBitfield only.\n",
            order = 6.1,
            fontSize = "small",
        },
        blizzardProgressive = BlizzardThreatToggle("Progressive", "Progressive",
            "Blizzard progressive aggro highlight on enemy nameplates.", 6.2),
        blizzardFlash = BlizzardThreatToggle("Flash", "Flash",
            "Blizzard aggro flash on enemy nameplates.", 6.3),
        blizzardHealthBarColor = BlizzardThreatToggle("HealthBarColor", "Health Bar Color",
            "Blizzard threat coloring on the nameplate health bar. The Flux border is separate.", 6.4),
    }

    if IsLevelOverlaySupported() then
        args.headerLevel = {
            type = "header",
            name = "Level",
            order = 10,
        }
        args.levelDesc = {
            type = "description",
            name = "On Modern nameplate style, Flux shows a smaller \"Lvl. N\" under the right side of the health bar.\n",
            order = 11,
            fontSize = "small",
        }
        args.levelOverlayEnabled = {
            type = "toggle",
            name = "Show level overlay (Modern style)",
            desc = "Flux level text/skull under the health text on Modern-style nameplates. Ignored while the Classic health-bar style is active.",
            order = 12,
            width = "full",
            get = function()
                return EnsureNameplateThreatDB().levelOverlayEnabled ~= false
            end,
            set = function(_, v)
                EnsureNameplateThreatDB().levelOverlayEnabled = v and true or false
                RefreshNameplatesFromDB()
            end,
        }
    end

    args.headerQuestProgress = {
        type = "header", name = "Quest progress", order = 15,
    }
    args.questOverlayEnabled = {
        type = "toggle",
        name = "Show quest kill / loot progress",
        desc = "Show a kill or loot icon and your current / required count below the left edge of quest mob nameplates. Uses Questie when loaded, otherwise available Blizzard quest information. Disables Questie's own nameplate marker while enabled.",
        order = 16, width = "full",
        get = function() return EnsureNameplateThreatDB().questOverlayEnabled ~= false end,
        set = function(_, value)
            EnsureNameplateThreatDB().questOverlayEnabled = value and true or false
            RefreshNameplatesFromDB()
        end,
    }

    AddPlateOptions(args)
    AddComponentOptions(args)

    return {
        name = "Nameplates",
        type = "group",
        order = 24,
        args = args,
    }
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    if FluxOptions and FluxOptions.RegisterModuleOptions then
        FluxOptions:RegisterModuleOptions("nameplates", BuildNameplatesOptions)
    end
end)

