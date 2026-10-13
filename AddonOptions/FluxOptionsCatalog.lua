-- FluxOptionsCatalog.lua
-- Sidebar groups, icons, and which registered builder feeds each page.
-- Section order overrides the Ace `order` field when a page lists headers here.
local _, ns = ...

local ICON = "Interface\\Icons\\"

ns.FluxOptionsCatalog = {
    groups = {
        { id = "general", label = "General", pages = { "general", "nameplates", "windows", "profiles" }, description = "Scope, nameplates, windows, and profiles." },
        { id = "hud", label = "HUD", pages = { "layout", "actionbars", "statusBars", "info", "micromenu", "chat", "unitframes", "fluxwindow" }, description = "Layout, bars, unit frames, chat, and the Flux window." },
        { id = "tools", label = "Tools", pages = { "vendor", "binding" }, description = "Inventory and the binding editor." },
    },

    -- Header names whose section (and everything after it, until the next
    -- normal header) sits behind the page's "More options" fold.
    advancedHeaders = {
        Performance = true,
    },

    -- Display names for subpages whose Ace group name should read differently.
    subpageLabels = {
        actionbars = { bar = "Bars" },
    },

    -- Explicit header order. Pages omitted here keep Ace `order` sorting.
    sectionOrder = {
        statusBars = {
            "Status bar scope",
            "Account gold (multi-character tooltip)",
            "Inventory awareness",
            "Honor & Arena on status bar",
            "Item currency (bag counts)",
        },
    },

    pages = {
        general = {
            name = "General",
            icon = ICON .. "INV_Misc_Gear_02",
            description = "Settings scope and accent.",
        },
        windows = {
            name = "Windows",
            icon = ICON .. "INV_Box_01",
            description = "Drag and scale Blizzard windows.",
        },
        profiles = {
            name = "Profiles",
            icon = ICON .. "INV_Misc_Book_09",
            description = "Ace profile for account-wide FluxUI settings.",
            profiles = true,
        },
        layout = {
            name = "Layout",
            icon = ICON .. "INV_Misc_Map_01",
            description = "Where Flux HUD pieces sit on screen.",
        },
        actionbars = {
            name = "Action Bars",
            icon = ICON .. "Ability_DualWield",
            description = "Bars, key bindings, extra buttons, and stance order.",
        },
        statusBars = {
            name = "Status Bars",
            icon = ICON .. "INV_Misc_Coin_01",
            description = "Gold, experience, honor, and item counts.",
        },
        info = {
            name = "Info",
            icon = ICON .. "INV_Misc_PocketWatch_01",
            description = "FPS, ping, durability, and the order of pinned stats.",
        },
        micromenu = {
            name = "Micro Menu",
            icon = ICON .. "INV_Misc_Bag_08",
            description = "Micro bar size, order, and profession buttons.",
        },
        chat = {
            name = "Chat",
            icon = ICON .. "INV_Misc_Note_01",
            description = "Buttons on the chat column.",
        },
        unitframes = {
            name = "Unit Frames",
            icon = ICON .. "Spell_Holy_SealOfSacrifice",
            description = "Player, target, focus, pet, and party / raid frames.",
        },
        nameplates = {
            name = "Nameplates",
            icon = ICON .. "Ability_Hunter_SniperShot",
            description = "Threat borders, Blizzard threat display, and level text.",
        },
        fluxwindow = {
            name = "Flux Window",
            icon = ICON .. "INV_Misc_Map02",
            description = "Map, meter, respec, and buttons tabs.",
        },
        vendor = {
            name = "Inventory",
            icon = ICON .. "INV_Misc_Bag_10",
            description = "Vendor repair and junk, restock targets, and salvage.",
            search = "inventory vendor junk sell repair restock salvage mill prospect disenchant bag indicator automation",
        },
        binding = {
            name = "Binding",
            icon = ICON .. "INV_Misc_Key_03",
            description = "Spell, item, and macro binding browser.",
        },
    },
}
