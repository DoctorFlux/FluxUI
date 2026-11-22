-- FluxUI navigation: reference-style presentation, feature-based organization.
-- Views retain their original source objects, callback contexts and saved paths.
local _, ns = ...
local ICON = "Interface\\Icons\\"
local function S(module, path, selector)
    local source = selector or {}
    source.module, source.path = module, {}
    for key in string.gmatch(path or "", "[^/]+") do source.path[#source.path + 1] = key end
    return source
end
local function T(key, name, sources, notice)
    return { key = key, name = name, sources = sources or {}, notice = notice }
end
local function P(name, icon, description, tabs)
    return { name = name, icon = ICON .. icon, description = description, tabs = tabs }
end

ns.FluxOptionsLocale = ns.FluxOptionsLocale or {}
local L = ns.FluxOptionsLocale
local frameStrings = {
    UF_GENERAL = "General", UF_INDIVIDUAL = "Individual Frames", UF_GROUP = "Party & Raid",
    UF_PARTY = "Party", UF_RAID = "Raid", UF_CAST_BARS = "Cast Bars",
    UF_PLAYER = "Player", UF_TARGET = "Target", UF_FOCUS = "Focus", UF_PET = "Pet",
    UF_GENERAL_DESC = "Choose Flux or Blizzard frames and configure shared behavior and cast bars.",
    UF_INDIVIDUAL_DESC = "Select the player, target, focus, pet or an attached target.",
    UF_GROUP_DESC = "Choose Party or Raid to edit its layout, appearance and world preview.",
    UF_OWNERSHIP_DESC = "The switches choose which Blizzard frames Flux replaces. Pet and attached targets require their Flux parent. Choose the party layout under Party & Raid.",
    UF_SCOPE = "Settings scope and reset", UF_OWNERSHIP = "Flux and Blizzard frames",
    UF_LAYOUT = "Display and sizing", UF_PARTY_LAYOUT = "Party layout and size",
    UF_HEALTH = "Health bar", UF_POWER = "Power bar", UF_PORTRAIT = "Portrait",
    UF_ABSORBS = "Healing and absorbs", UF_CLASS_RESOURCE = "Class resource",
    UF_AURAS = "Aura appearance", UF_AURA_TIMERS = "Aura countdowns", UF_BUFFS = "Buffs", UF_DEBUFFS = "Debuffs",
    UF_CAST = "Cast bar", UF_NAME = "Name and text", UF_NAME_LEVEL = "Name and level", UF_INDICATORS = "Indicators and highlights",
    UF_PARTY_HIGHLIGHTS = "Borders and highlights",
    UF_THREAT = "Threat", UF_EXTRAS = "Player extras", UF_ATTACHED = "Pet and target frames",
    UF_TARGET_TARGET = "Target of target", UF_FOCUS_TARGET = "Focus target", UF_PET_TARGET = "Pet target",
    UF_FOCUS_TARGET_SIZE = "Focus target height and scale follow Focus. The vertical strip uses Party target width under Party & Raid > Party.",
    UF_TARGET_SHARED_SIZE = "In the side-by-side layout, Target uses the width and height set under Player.",
    UF_OPACITY = "Opacity and range fade", UF_WORLD_PREVIEW = "World preview",
    UF_SHARED_COMPACT = "Shared compact appearance", UF_OPEN_RAID = "Open Raid settings",
    UF_SHARED_COMPACT_DESC = "Compact parties share frame size, bars, auras and other appearance settings with the Raid tab.",
    NP_PAGE = "Nameplates", NP_PAGE_DESC = "Nameplate appearance, cast bars, auras, threat and quest progress.",
    NP_STYLE = "Plate", NP_EXTRAS = "Extras", NP_CAST = "Cast Bar", NP_AURAS = "Auras",
    NP_TARGETING = "Targeting", NP_VISIBILITY = "Visibility", NP_FONTS = "Fonts",
}
for key, value in pairs(frameStrings) do L[key] = L[key] or value end

-- Each section uses the original option paths. The section without an explicit
-- key list gets the remaining options so future controls still have a home.
local function FrameSections(path, sections, excluded)
    local sources, assigned = {}, {}
    for _, key in ipairs(excluded or {}) do assigned[#assigned + 1] = key end
    for _, section in ipairs(sections) do
        for _, key in ipairs(section[3] or {}) do assigned[#assigned + 1] = key end
    end
    for _, section in ipairs(sections) do
        local part, title, keys = section[1], section[2], section[3]
        sources[#sources + 1] = S("unitframes", path, {
            part = part, title = title, only = keys, except = not keys and assigned or nil,
        })
    end
    return sources
end

local function UnitSections(path, prefix, excluded)
    local function keys(...)
        local suffixed = { ... }
        for i, suffix in ipairs(suffixed) do suffixed[i] = prefix .. suffix end
        return suffixed
    end
    local powerKeys = keys("HealthSplit", "PowerText")
    if prefix == "targettarget" then powerKeys[#powerKeys + 1] = "totHealthSplit" end
    local sections = {
        { "layout", L.UF_LAYOUT },
        { "portrait", L.UF_PORTRAIT, keys("ShowPortrait", "PortraitCombat") },
        { "name", L.UF_NAME_LEVEL, keys("Level") },
        { "health", L.UF_HEALTH, keys("TextHeader", "HealthText", "ClassHP") },
        { "power", L.UF_POWER, powerKeys },
        { "cast", L.UF_CAST, keys("CastBar", "ShowCastBar", "CastTime") },
        { "classResource", L.UF_CLASS_RESOURCE, keys("ClassPower", "ClassPowerScale") },
        { "buffs", L.UF_BUFFS, keys("ShowBuffs", "AuraBuffSize", "AuraBuffSpacing", "AuraMaxBuffs") },
        { "debuffs", L.UF_DEBUFFS, keys("AurasHeader", "ShowDebuffs", "AuraDebuffSize", "AuraDebuffSpacing",
            "AuraLockOwnDebuffSize", "AuraOwnDebuffMinScale", "AuraMaxDebuffs") },
        { "absorbs", L.UF_ABSORBS, keys("Heal", "Absorb") },
        { "indicators", L.UF_INDICATORS, keys("IconHeader", "ClassIcon", "Pvp", "Combat", "RaidIcon", "Mouseover",
            "ThreatHeader", "ThreatBarPosition") },
    }
    if prefix == "player" then
        sections[#sections + 1] = { "extras", L.UF_EXTRAS, {
            "playerExtrasHeader", "enableMP5Overlay", "swingTimerUnsupportedNote", "enableSwingTimer",
            "enableFlightPathTimers", "enableFlightPathCastBar", "enableFlightPathTooltips",
        } }
    elseif prefix == "pet" then
        sections[#sections + 1] = { "auras", L.UF_AURAS, { "petShowTooltipAuras" } }
    end
    return FrameSections(path, sections, excluded)
end

local focusTargetSections = {
    { "layout", L.UF_LAYOUT, { "focusTargetHeader", "focusTargetDesc" } },
    { "health", L.UF_HEALTH, { "focustargetTextHeader", "focustargetHealthText", "focustargetClassHP" } },
    { "power", L.UF_POWER, { "focustargetPowerText" } },
    { "absorbs", L.UF_ABSORBS, { "focustargetHeal", "focustargetAbsorb" } },
    { "indicators", L.UF_INDICATORS, { "focustargetMouseover", "focustargetRaidIcon" } },
}
local focusTargetKeys = {}
for _, section in ipairs(focusTargetSections) do
    for _, key in ipairs(section[3]) do focusTargetKeys[#focusTargetKeys + 1] = key end
end

local meter = { "spacer", "headerMeter", "meterDesc", "meterEditor", "noDetails" }
local restockModes = { "autoRestock", "autoBankRestock", "autoMailRestock", "autoAuctionFollowup" }
local C = {
    groups = {
        { id = "combat", label = "Combat", pages = { "actionbars", "bindings", "ufNameplates" } },
        { id = "lootItems", label = "Loot & Items", pages = { "lootItems" } },
        { id = "utilities", label = "Utilities", pages = { "windows", "professions" } },
        { id = "hud", label = "HUD", pages = { "layout", "chat", "info", "micromenu", "fluxwindow", "statusBars" } },
        { id = "unitframes", label = "Unit Frame", pages = { "ufGeneral", "ufUnits", "ufPartyRaid" } },
        { id = "system", label = "", pages = { "settings", "profiles", "patchNotes", "credits" }, system = true },
    },
    sourceModules = { "general", "windows", "layout", "actionbars", "statusBars", "info", "micromenu", "chat", "unitframes", "nameplates", "fluxwindow", "vendor", "loot", "binding" },
    sources = {},
    pages = {},
    advancedHeaders = { Performance = true },
    subpageLabels = {},
    sectionOrder = { statusBars = { "Status bar scope", "Account gold (multi-character tooltip)", "Honor & Arena on status bar", "Item currency (bag counts)" } },
    aliases = {
        general = { "settings" }, qol = { "windows" },
        unitframes = { "ufGeneral", "general" }, nameplates = { "ufNameplates" },
        ufMini = { "ufUnits", "unitPet" }, ufParty = { "ufPartyRaid", "party" },
        ufRaid = { "ufPartyRaid", "raid" }, ufCastBars = { "ufGeneral", "castBars" },
        vendor = { "lootItems", "vendor" }, loot = { "lootItems", "loot" }, binding = { "bindings", "browser" },
        macros = { "bindings", "browser" }, keybindings = { "bindings", "settings" }, consumableBar = { "actionbars", "buttons" },
        gearTrinkets = { "actionbars", "buttons" }, journeys = { "actionbars", "buttons" },
        swingTimer = { "ufUnits", "unitPlayer" },
        pvp = { "statusBars" },
    },
    subAliases = {
        actionbars = { bar = { "actionbars", "bars" }, settings = { "actionbars", "bars" }, extra = { "actionbars", "buttons" },
            bindings = { "bindings", "settings" }, barSets = { "profiles" },
            consumables = { "actionbars", "buttons" }, trinkets = { "actionbars", "buttons" },
            travel = { "actionbars", "buttons" }, utilitySlots = { "actionbars", "buttons" } },
        vendor = { salvage = { "professions", "settings" }, vendor = { "lootItems", "vendor" }, restock = { "lootItems", "restock" } },
        lootItems = { settings = { "lootItems", "loot" } },
        unitframes = { general = { "ufGeneral", "general" }, appearance = { "ufGeneral", "general" },
            unitPlayer = { "ufUnits", "unitPlayer" }, unitTarget = { "ufUnits", "unitTarget" }, unitFocus = { "ufUnits", "unitFocus" },
            unitPet = { "ufUnits", "unitPet" }, unitTargetOfTarget = { "ufUnits", "unitTargetOfTarget" },
            unitFocusTarget = { "ufUnits", "unitFocusTarget" }, unitPetTarget = { "ufUnits", "unitPetTarget" },
            party = { "ufPartyRaid", "party" }, partyStyle = { "ufPartyRaid", "party" },
            raid = { "ufPartyRaid", "raid" }, partyRaid = { "ufPartyRaid", "raid" },
            castBars = { "ufGeneral", "castBars" }, castBarThemes = { "ufGeneral", "castBars" }, nameplates = { "ufNameplates" } },
        settings = { modules = { "actionbars", "buttons" }, general = { "settings" } },
        fluxwindow = { settings = { "fluxwindow", "general" } },
        qol = {
            windows = { "windows" }, interface = { "windows" }, chat = { "chat" }, info = { "info" },
            microMenu = { "micromenu" }, fluxWindow = { "fluxwindow", "general" },
            statusBars = { "statusBars" }, damageMeter = { "fluxwindow", "damageMeter" }, combat = { "ufNameplates" },
            mapPins = { "layout" }, questingGroup = { "ufNameplates" }, xp = { "statusBars" },
            lootItems = { "lootItems", "loot" }, glimmer = { "lootItems", "vendor" },
            travel = { "actionbars", "buttons" }, cursorCrosshair = { "lootItems", "vendor" },
        },
        ufMini = {
            unitPet = { "ufUnits", "unitPet" }, unitTargetOfTarget = { "ufUnits", "unitTargetOfTarget" },
            unitFocusTarget = { "ufUnits", "unitFocusTarget" }, unitPetTarget = { "ufUnits", "unitPetTarget" },
        },
    },
}
local sourceNames = { general="General", windows="Windows", layout="Layout", actionbars="Action Bars", statusBars="Status Bars",
    info="Info", micromenu="Micro Menu", chat="Chat", unitframes="Unit Frames", nameplates="Nameplates",
    fluxwindow="Flux Window", vendor="Inventory", loot="Loot", binding="Binding", profiles="Profiles" }
for key, name in pairs(sourceNames) do C.sources[key] = { name = name } end

C.pages.windows = P("Windows", "INV_Misc_Gear_02", "Native window positioning and behavior.")
C.pages.windows.module = "windows"
C.pages.chat = P("Chat", "INV_Misc_Note_01", "Chat appearance and behavior.")
C.pages.chat.module = "chat"
C.pages.info = P("Info", "INV_Misc_Book_09", "HUD information displays.")
C.pages.info.module = "info"
C.pages.micromenu = P("Micro Menu", "INV_Misc_Gear_02", "Micro Menu buttons, size, spacing and ordering.")
C.pages.micromenu.sources = { S("micromenu", nil, { exceptPrefix = "tradeSkills" }) }
C.pages.statusBars = P("Status Bars", "INV_Misc_Coin_01", "Experience, gold, currencies and honor.")
C.pages.statusBars.sources = { S("statusBars", nil, { exceptPrefix = "invTip" }) }
C.pages.fluxwindow = P("Flux Window", "INV_Misc_Map_01", "Flux Window tabs and damage meter settings.", {
    T("general", "General", { S("fluxwindow", nil, { except = meter }) }),
    T("damageMeter", "Damage Meter", { S("fluxwindow", nil, { only = meter }) }),
})
C.pages.actionbars = P("Action Bars", "Ability_DualWield", "Action bars and their extra, consumable, trinket, travel, and utility buttons.", {
    T("bars", "Bars", { S("actionbars", "bar") }),
    T("buttons", "Extra Buttons", { S("actionbars", "extra") }),
    T("stance", "Stance Order", { S("actionbars", "stance") }),
})
C.pages.actionbars.tabs[2].externalActions = {
    { label = "Open Trinket Menu", owner = "FluxTrinketMenu", method = "Toggle" },
    { label = "Mount settings", owner = "FluxSmartMountConfig", method = "OpenMountJournal" },
    { label = "Hearthstone settings", owner = "FluxHearthConfig", method = "OpenToyBox" },
}
C.pages.bindings = P("Bindings", "INV_Misc_Key_03", "Spell, item and macro bindings, action-bar keys and FluxUI defaults.", {
    T("browser", "Bindings", { S("binding") }),
    T("settings", "Keybindings", { S("actionbars", "bindings") }),
})
C.pages.bindings.wholePane = true
C.pages.bindings.tabs[1].search = "binding bindings macro macros spell spells item items browser"
C.pages.lootItems = P("Loot & Items", "INV_Misc_Bag_10", "Looting, vendor and junk automation, and item restocking.", {
    T("loot", "Loot", { S("loot"), S("statusBars", nil, { onlyPrefix = "invTip" }) }),
    T("vendor", "Vendor", { S("vendor", "vendor", { except = restockModes }) }),
    T("restock", "Restock", { S("vendor", "vendor", { only = restockModes, title = "Restock automation" }),
        S("vendor", "restock", { title = "Items and targets" }) }),
})
C.pages.professions = P("Professions", "Trade_BlackSmithing", "Profession buttons and salvage: disenchanting, milling, and prospecting.", {
    T("settings", "Settings", { S("micromenu", nil, { onlyPrefix = "tradeSkills" }), S("vendor", "salvage", { title = "Salvage" }) }),
})
C.pages.ufGeneral = P(L.UF_GENERAL, "INV_Misc_Gear_02", L.UF_GENERAL_DESC, {
    T("general", L.UF_GENERAL, FrameSections("general", {
        { "layout", L.UF_OWNERSHIP },
        { "portrait", L.UF_PORTRAIT, { "use3DPortraits", "enablePortraitCombatTint" } },
        { "health", L.UF_HEALTH, { "enableHealthLossOverlay" } },
        { "power", L.UF_POWER, { "enablePowerCostOverlay" } },
        { "auras", L.UF_AURA_TIMERS, { "auraTimersUnderMinute" } },
        { "indicators", L.UF_THREAT, { "threatBarVisibility", "showNumericThreat", "nameplateOptionsPointer" } },
        { "scope", L.UF_SCOPE, { "scopeHeader", "settingsScope", "raidSettingsScope", "scopeDesc", "resetUnitFrames", "resetRaidFrames" } },
    })),
    T("castBars", L.UF_CAST_BARS, { S("unitframes", "castBarThemes") }),
})
C.pages.ufUnits = P(L.UF_INDIVIDUAL, "Ability_Warrior_BattleShout", L.UF_INDIVIDUAL_DESC, {
    T("unitPlayer", L.UF_PLAYER, UnitSections("unitPlayer", "player")),
    T("unitTarget", L.UF_TARGET, UnitSections("unitTarget", "target", { "unitTargetOfTarget" })),
    T("unitFocus", L.UF_FOCUS, UnitSections("unitFocus", "focus", focusTargetKeys)),
    T("unitPet", L.UF_PET, UnitSections("unitPet", "pet", { "unitPetTarget" })),
    T("unitTargetOfTarget", L.UF_TARGET_TARGET, UnitSections("unitTarget/unitTargetOfTarget", "targettarget")),
    T("unitFocusTarget", L.UF_FOCUS_TARGET, FrameSections("unitFocus", focusTargetSections)),
    T("unitPetTarget", L.UF_PET_TARGET, UnitSections("unitPet/unitPetTarget", "pettarget")),
})
local party = T("party", L.UF_PARTY, FrameSections("partyRaid/partyStyle", {
    { "layout", L.UF_PARTY_LAYOUT },
    { "portrait", L.UF_PORTRAIT, { "portraits" } },
    { "name", L.UF_NAME, { "textScale" } },
    { "health", L.UF_HEALTH, { "healthText" } },
    { "power", L.UF_POWER, { "powerHeight", "powerText" } },
    { "cast", L.UF_CAST, { "casts" } },
    { "auras", L.UF_AURAS, { "auraScale" } },
    { "indicators", L.UF_PARTY_HIGHLIGHTS, { "classColor", "threat" } },
    { "attached", L.UF_ATTACHED, { "pets", "petScale", "targets", "targetWidth", "targetClassColor" } },
    { "preview", L.UF_WORLD_PREVIEW, { "preview" } },
}))
party.action = { label = L.UF_SHARED_COMPACT, buttonText = L.UF_OPEN_RAID, desc = L.UF_SHARED_COMPACT_DESC, page = "ufPartyRaid", sub = "raid" }
local raidSources = FrameSections("partyRaid", {
    { "layout", L.UF_LAYOUT },
    { "name", L.UF_NAME, { "masterHeader", "nameUseClassColor" } },
    { "health", L.UF_HEALTH, { "displayHeader", "useClassColors", "healthText" } },
    { "power", L.UF_POWER, { "displayPowerBar", "powerBarHeightScale" } },
    { "absorbs", L.UF_ABSORBS, { "showHealPrediction", "showEstimatedHoTs" } },
    { "auras", L.UF_AURAS, { "auraIconScale", "auraWidthScale", "auraDurationFontScale", "auraIconAlpha", "auraFocusMode" } },
    { "buffs", L.UF_BUFFS, { "displayBuffs", "maxBuffs", "showClassBuffs", "showMissingClassBuffs" } },
    { "debuffs", L.UF_DEBUFFS, { "dispelHeader", "showDispelHighlight", "displayDebuffs", "maxDebuffs", "displayOnlyDispellableDebuffs" } },
    { "indicators", L.UF_INDICATORS, { "highlightHeader", "showAggroHighlight", "showTargetHighlight", "showMouseoverHighlight", "showRoleIcon" } },
    { "attached", L.UF_ATTACHED, { "showPets", "showFriendlyTarget" } },
    { "opacity", L.UF_OPACITY, { "transparencyHeader", "transparencyDesc", "frameBaseAlpha", "rangeAlphaInRange", "rangeAlphaOutOfRange", "showRangeFade" } },
}, { "partyStyle", "previewGroup" })
raidSources[#raidSources + 1] = S("unitframes", "partyRaid/previewGroup", { part = "preview", title = L.UF_WORLD_PREVIEW })
C.pages.ufPartyRaid = P(L.UF_GROUP, "Spell_Holy_PrayerOfHealing02", L.UF_GROUP_DESC, {
    party,
    T("raid", L.UF_RAID, raidSources),
})
local nameplateExtras = { "headerThreat", "threatDesc", "visibilityMode", "npcThreatBorder", "showNumericThreat",
    "enemyPlayerTarget", "headerBlizzardThreat", "blizzardThreatDesc", "blizzardProgressive", "blizzardFlash",
    "blizzardHealthBarColor", "headerLevel", "levelDesc", "levelOverlayEnabled", "headerQuestProgress", "questOverlayEnabled" }
C.pages.ufNameplates = P(L.NP_PAGE, "Ability_Hunter_EagleEye", L.NP_PAGE_DESC, {
    T("style", L.NP_STYLE, { S("nameplates", nil, { onlyPrefix = "style_" }) }),
    T("extras", L.NP_EXTRAS, { S("nameplates", nil, { onlyPrefix = "extra_" }), S("nameplates", nil, { only = nameplateExtras }) }),
    T("cast", L.NP_CAST, { S("nameplates", nil, { onlyPrefix = "cast_" }) }),
    T("auras", L.NP_AURAS, { S("nameplates", nil, { onlyPrefix = "aura_" }) }),
    T("targeting", L.NP_TARGETING, { S("nameplates", nil, { onlyPrefix = "target_" }) }),
    T("visibility", L.NP_VISIBILITY, { S("nameplates", nil, { onlyPrefix = "visible_" }) }),
    T("fonts", L.NP_FONTS, { S("nameplates", nil, { onlyPrefix = "font_" }) }),
})
C.pages.ufNameplates.category = "Combat"
C.pages.ufNameplates.checkAvailability = true
C.pages.lootItems.sidebarSubpages = true
local itemIcons = { "INV_Misc_Bag_10", "INV_Misc_Coin_01", "INV_Misc_Bag_10" }
for i, tab in ipairs(C.pages.lootItems.tabs) do tab.icon = ICON .. itemIcons[i] end
C.pages.settings = P("Settings", "INV_Misc_Gear_02", "Settings scope and global HUD appearance.")
C.pages.settings.module = "general"
C.pages.profiles = P("Profiles", "INV_Misc_Book_09", "Switch, copy, and reset FluxUI profiles.")
C.pages.profiles.profiles = true
C.pages.layout = P("Layout", "INV_Misc_Map_01", "Place and size FluxUI HUD displays.")
C.pages.layout.module = "layout"
for _, group in ipairs(C.groups) do
    if group.id == "unitframes" then
        for _, id in ipairs(group.pages) do C.pages[id].category, C.pages[id].checkAvailability = "Unit Frame", true end
    elseif group.id == "hud" then
        for _, id in ipairs(group.pages) do C.pages[id].category = "HUD" end
    end
end
C.pages.patchNotes = P("Patch Notes", "INV_Misc_Note_05", "What changed in FluxUI options.")
C.pages.patchNotes.text =
    "21 November 2026\n\nUnit Frame contains General, Individual Frames and Party & Raid. Cast Bars is a tab under General. Nameplates is under Combat. Select a unit type in Individual Frames or choose the Party or Raid tab. Click part of the right-hand preview to open its settings. Both group tabs have a World preview section.\n\n"
    .. "9 November 2026\n\nHUD contains Layout, Chat, Info, Micro Menu, Flux Window and Status Bars. Layout is visible in the sidebar again. Damage Meter is a tab inside Flux Window; right-click Meter to open it. Windows is under Utilities.\n\nSidebar headers collapse and expand their entries. Search temporarily reveals matches.\n\nLoot & Items contains Loot, Vendor and Restock entries with icons."
C.pages.credits = P("Credits", "INV_Misc_Book_09", "The people and projects behind FluxUI.")
C.pages.credits.text = "FluxUI — DoctorFlux\n\nNative interface artwork and templates — Blizzard Entertainment.\n\nNavigation and settings design reference — Naowh Forever. Its source and artwork remain with their authors.\n\nBundled third-party libraries and components retain their own licenses and notices."
ns.FluxOptionsCatalog = C

function C.HelpText(text)
    -- Update navigation references at presentation time; original option tables
    -- and callback metadata remain untouched for their existing consumers.
    local substitutions = {
        { "The focus target bar matches the focus frame size.", L.UF_FOCUS_TARGET_SIZE },
        { "Layout is set to side-by-side (Layout tab): target width and height match the Player tab - adjust size there.", L.UF_TARGET_SHARED_SIZE },
        { "When Flux is off for a unit, the default Blizzard frame is used. Pet and target-of-target require the Flux player or target frame. Party / raid uses the compact grid. Changes apply immediately.", L.UF_OWNERSHIP_DESC },
        { "on the Layout tab", "in HUD > Layout" }, { "Layout tab ->", "HUD > Layout >" }, { "Layout tab", "HUD > Layout" },
        { "MicroMenu tab", "HUD > Micro Menu" },
        { "Action Bars tab", "Combat > Action Bars > Bars" },
        { "General > Settings scope", "Settings > Settings scope" },
        { "General -> Settings scope", "Settings > Settings scope" },
        { "General -> Features", "Unit Frame > General" },
        { "General > Features", "Unit Frame > General" },
        { "Party / Raid tab", "Party & Raid page" },
        { "Nameplate Progressive, Flash, Health Bar Color, and Threat warning are on the Nameplates page.", "Nameplate Progressive, Flash, Health Bar Color, and Threat warning are under Combat > Nameplates > Extras." },
        { "Profiles tab", "Profiles page" },
        { "Repair, selling, and restock that run when a vendor or the bank opens.", "Repair and selling that run when a vendor opens. Restock options are in the Restock entry." },
        { "Applies to borders, backdrops, and the on-state of this options window.", "Applies to FluxUI HUD borders and backdrops." },
    }
    for _, pair in ipairs(substitutions) do
        local start = 1
        while true do
            local first, last = text:find(pair[1], start, true)
            if not first then break end
            text = text:sub(1, first - 1) .. pair[2] .. text:sub(last + 1)
            start = first + #pair[2]
        end
    end
    local oldAccent = "This options window uses it for the selected page, the active tab, toggles, and sliders."
    local first, last = text:find(oldAccent, 1, true)
    if first then text = text:sub(1, first - 1) .. "The options window keeps this client's native window skin." .. text:sub(last + 1) end
    return text
end
