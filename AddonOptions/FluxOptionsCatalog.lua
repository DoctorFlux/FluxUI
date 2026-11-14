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
local meter = { "spacer", "headerMeter", "meterDesc", "meterEditor", "noDetails" }
local restockModes = { "autoRestock", "autoBankRestock", "autoMailRestock", "autoAuctionFollowup" }
local C = {
    groups = {
        { id = "combat", label = "Combat", pages = { "actionbars", "bindings" } },
        { id = "lootItems", label = "Loot & Items", pages = { "lootItems" } },
        { id = "utilities", label = "Utilities", pages = { "windows", "professions" } },
        { id = "hud", label = "HUD", pages = { "layout", "chat", "info", "micromenu", "fluxwindow", "statusBars" } },
        { id = "unitframes", label = "Unit Frame", pages = { "ufGeneral", "ufUnits", "ufParty", "ufRaid", "ufCastBars", "ufNameplates" } },
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
        unitframes = { "ufGeneral" }, nameplates = { "ufNameplates" },
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
        unitframes = { general = { "ufGeneral" }, appearance = { "ufGeneral" }, unitPlayer = { "ufUnits", "unitPlayer" },
            unitTarget = { "ufUnits", "unitTarget" }, unitFocus = { "ufUnits", "unitFocus" }, unitPet = { "ufUnits", "unitPet" },
            party = { "ufParty" }, partyStyle = { "ufParty" }, raid = { "ufRaid" }, partyRaid = { "ufRaid" },
            castBars = { "ufCastBars" }, castBarThemes = { "ufCastBars" }, nameplates = { "ufNameplates" } },
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
C.pages.ufGeneral = P("General", "INV_Misc_Gear_02", "Frame selection, independent scopes, shared appearance, aura timers and threat.")
C.pages.ufGeneral.sources = { S("unitframes", "general") }
C.pages.ufUnits = P("Individual Frames", "Ability_Warrior_BattleShout", "Configure player, target, focus and pet frames separately.", {
    T("unitPlayer", "Player", { S("unitframes", "unitPlayer", { title = "Frame layout" }) }),
    T("unitTarget", "Target", { S("unitframes", "unitTarget", { title = "Frame layout" }) }),
    T("unitFocus", "Focus", { S("unitframes", "unitFocus", { title = "Frame layout" }) }),
    T("unitPet", "Pet", { S("unitframes", "unitPet", { title = "Frame layout" }) }),
})
C.pages.ufParty = P("Party Frames", "Spell_Holy_PrayerOfHealing02", "Player-style party frames, pets, targets and their five-member preview.")
C.pages.ufParty.sources = { S("unitframes", "partyRaid/partyStyle") }
C.pages.ufRaid = P("Raid Frames", "Spell_Holy_PrayerOfFortitude", "Compact raid and party frames, auras, highlights and the raid preview.")
C.pages.ufRaid.sources = { S("unitframes", "partyRaid", { except = { "partyStyle" }, title = "Raid and compact party frames" }) }
C.pages.ufCastBars = P("Cast Bars", "Spell_Fire_Fireball02", "School and spell themes for cast bars.")
C.pages.ufCastBars.sources = { S("unitframes", "castBarThemes") }
C.pages.ufNameplates = P("Nameplates", "Ability_Hunter_EagleEye", "Blizzard nameplates, threat indicators and quest progress.")
C.pages.ufNameplates.sources = { S("nameplates") }
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
C.pages.patchNotes.text = "9 November 2026\n\nHUD contains Layout, Chat, Info, Micro Menu, Flux Window and Status Bars. Layout is visible in the sidebar again. Damage Meter is a tab inside Flux Window; right-click Meter to open it. Windows is under Utilities.\n\nSidebar headers collapse and expand their entries. Search temporarily reveals matches.\n\nGeneral includes shared appearance. Individual Frames has Player, Target, Focus and Pet tabs. Loot & Items contains Loot, Vendor and Restock entries with icons.\n\nRaid previews show at least ten members; the party preview stays at five. The Forever background stays visible when resizing smaller. Existing profiles, scopes and saved values are retained."
C.pages.credits = P("Credits", "INV_Misc_Book_09", "The people and projects behind FluxUI.")
C.pages.credits.text = "FluxUI — DoctorFlux\n\nNative interface artwork and templates — Blizzard Entertainment.\n\nNavigation and settings design reference — Naowh Forever. Its source and artwork remain with their authors.\n\nBundled third-party libraries and components retain their own licenses and notices."
ns.FluxOptionsCatalog = C

function C.HelpText(text)
    -- Update navigation references at presentation time; original option tables
    -- and callback metadata remain untouched for their existing consumers.
    local substitutions = {
        { "on the Layout tab", "in HUD > Layout" }, { "Layout tab ->", "HUD > Layout >" }, { "Layout tab", "HUD > Layout" },
        { "MicroMenu tab", "HUD > Micro Menu" },
        { "Action Bars tab", "Combat > Action Bars > Bars" },
        { "General > Settings scope", "Settings > Settings scope" },
        { "General -> Settings scope", "Settings > Settings scope" },
        { "General -> Features", "Unit Frame > General" },
        { "General > Features", "Unit Frame > General" },
        { "Party / Raid tab", "Party Frames and Raid Frames entries" },
        { "Party / raid scope applies to the Party / Raid tab", "Party / raid scope applies to the Party Frames and Raid Frames entries" },
        { "Nameplate Progressive, Flash, Health Bar Color, and Threat warning are on the Nameplates page.", "Nameplate Progressive, Flash, Health Bar Color, and Threat warning are in the Nameplates entry here." },
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
