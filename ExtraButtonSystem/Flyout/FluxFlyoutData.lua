-- FluxFlyoutData.lua
-- Spell and item databases for custom flyout system
-- Supports all WoW clients: Retail, Classic, Legacy
local addonName, ns = ...

local FluxFlyoutData = {}
_G.FluxFlyoutData = FluxFlyoutData

-- ---------------------------------------------------------------------------
-- SPELL LISTS BY CATEGORY
-- These are checked dynamically against the player's spellbook
-- ---------------------------------------------------------------------------

FluxFlyoutData.SpellLists = {
    -- Professions (Primary and Secondary)
    profession = {
        -- Primary Professions
        "Alchemy",
        "Blacksmithing",
        "Enchanting",
        "Disenchant",
        "Engineering",
        "Leatherworking",
        "Smelting",
        "Mining",
        "Tailoring",
        "Jewelcrafting",
        "Prospecting",
        "Inscription",
        "Milling",
        "Herbalism",
        "Skinning",
        -- Secondary Professions
        "Cooking",
        "First Aid",
        "Fishing",
        -- Class-specific Profession-like
        "Poisons",
        "Pick Lock",
        "Pick Pocket",
        -- Dragonflight+ Professions UI
        "Profession Window",
    },
    
    -- Mage Portals (Horde)
    portal_horde = {
        "Portal: Orgrimmar",
        "Portal: Undercity",
        "Portal: Thunder Bluff",
        "Portal: Silvermoon",
        "Portal: Stonard",
        "Portal: Shattrath",
        "Portal: Dalaran",
        "Portal: Dalaran - Northrend",
        "Portal: Tol Barad",
        "Portal: Vale of Eternal Blossoms",
        "Portal: Warspear",
        "Portal: Dazar'alor",
        "Portal: Oribos",
        "Portal: Valdrakken",
    },
    
    -- Mage Portals (Alliance)
    portal_alliance = {
        "Portal: Stormwind",
        "Portal: Ironforge",
        "Portal: Darnassus",
        "Portal: Exodar",
        "Portal: Theramore",
        "Portal: Shattrath",
        "Portal: Dalaran",
        "Portal: Dalaran - Northrend",
        "Portal: Tol Barad",
        "Portal: Vale of Eternal Blossoms",
        "Portal: Stormshield",
        "Portal: Boralus",
        "Portal: Oribos",
        "Portal: Valdrakken",
    },
    
    -- Combined portal list (checked against faction)
    portal = {
        "Portal: Orgrimmar",
        "Portal: Undercity",
        "Portal: Thunder Bluff",
        "Portal: Silvermoon",
        "Portal: Stonard",
        "Portal: Stormwind",
        "Portal: Ironforge",
        "Portal: Darnassus",
        "Portal: Exodar",
        "Portal: Theramore",
        "Portal: Shattrath",
        "Portal: Dalaran",
        "Portal: Dalaran - Northrend",
        "Portal: Tol Barad",
        "Portal: Vale of Eternal Blossoms",
        "Portal: Warspear",
        "Portal: Stormshield",
        "Portal: Dazar'alor",
        "Portal: Boralus",
        "Portal: Oribos",
        "Portal: Valdrakken",
    },
    
    -- Mage Teleports (Horde)
    teleport_horde = {
        "Teleport: Orgrimmar",
        "Teleport: Undercity",
        "Teleport: Thunder Bluff",
        "Teleport: Silvermoon",
        "Teleport: Stonard",
        "Teleport: Shattrath",
        "Teleport: Dalaran",
        "Teleport: Dalaran - Northrend",
        "Teleport: Tol Barad",
        "Teleport: Vale of Eternal Blossoms",
        "Teleport: Warspear",
        "Teleport: Dazar'alor",
        "Teleport: Oribos",
        "Teleport: Valdrakken",
    },
    
    -- Mage Teleports (Alliance)
    teleport_alliance = {
        "Teleport: Stormwind",
        "Teleport: Ironforge",
        "Teleport: Darnassus",
        "Teleport: Exodar",
        "Teleport: Theramore",
        "Teleport: Shattrath",
        "Teleport: Dalaran",
        "Teleport: Dalaran - Northrend",
        "Teleport: Tol Barad",
        "Teleport: Vale of Eternal Blossoms",
        "Teleport: Stormshield",
        "Teleport: Boralus",
        "Teleport: Oribos",
        "Teleport: Valdrakken",
    },
    
    -- Combined teleport list
    teleport = {
        "Teleport: Orgrimmar",
        "Teleport: Undercity",
        "Teleport: Thunder Bluff",
        "Teleport: Silvermoon",
        "Teleport: Stonard",
        "Teleport: Stormwind",
        "Teleport: Ironforge",
        "Teleport: Darnassus",
        "Teleport: Exodar",
        "Teleport: Theramore",
        "Teleport: Shattrath",
        "Teleport: Dalaran",
        "Teleport: Dalaran - Northrend",
        "Teleport: Tol Barad",
        "Teleport: Vale of Eternal Blossoms",
        "Teleport: Warspear",
        "Teleport: Stormshield",
        "Teleport: Dazar'alor",
        "Teleport: Boralus",
        "Teleport: Oribos",
        "Teleport: Valdrakken",
    },
    
    -- Shaman Air Totems
    totem_air = {
        "Grounding Totem",
        "Nature Resistance Totem",
        "Windfury Totem",
        "Grace of Air Totem",
        "Windwall Totem",
        "Sentry Totem",
        "Tranquil Air Totem",
        "Wrath of Air Totem",
        "Wind Rush Totem",
        "Capacitor Totem",
    },
    
    -- Shaman Earth Totems
    totem_earth = {
        "Earthbind Totem",
        "Stoneskin Totem",
        "Stoneclaw Totem",
        "Strength of Earth Totem",
        "Tremor Totem",
        "Earth Elemental Totem",
        "Earthgrab Totem",
        "Stone Bulwark Totem",
    },
    
    -- Shaman Fire Totems
    totem_fire = {
        "Totem of Wrath",
        "Searing Totem",
        "Fire Nova Totem",
        "Magma Totem",
        "Frost Resistance Totem",
        "Flametongue Totem",
        "Fire Elemental Totem",
        "Liquid Magma Totem",
    },
    
    -- Shaman Water Totems
    totem_water = {
        "Fire Resistance Totem",
        "Mana Spring Totem",
        "Healing Stream Totem",
        "Mana Tide Totem",
        "Disease Cleansing Totem",
        "Poison Cleansing Totem",
        "Cleansing Totem",
        "Spirit Link Totem",
        "Cloudburst Totem",
        "Healing Tide Totem",
    },
    
    -- All Shaman Totems
    totem = {
        -- Air
        "Grounding Totem", "Nature Resistance Totem", "Windfury Totem",
        "Grace of Air Totem", "Windwall Totem", "Sentry Totem",
        "Tranquil Air Totem", "Wrath of Air Totem", "Wind Rush Totem",
        "Capacitor Totem",
        -- Earth
        "Earthbind Totem", "Stoneskin Totem", "Stoneclaw Totem",
        "Strength of Earth Totem", "Tremor Totem", "Earth Elemental Totem",
        "Earthgrab Totem", "Stone Bulwark Totem",
        -- Fire
        "Totem of Wrath", "Searing Totem", "Fire Nova Totem",
        "Magma Totem", "Frost Resistance Totem", "Flametongue Totem",
        "Fire Elemental Totem", "Liquid Magma Totem",
        -- Water
        "Fire Resistance Totem", "Mana Spring Totem", "Healing Stream Totem",
        "Mana Tide Totem", "Disease Cleansing Totem", "Poison Cleansing Totem",
        "Cleansing Totem", "Spirit Link Totem", "Cloudburst Totem",
        "Healing Tide Totem",
    },
    
    -- Shaman Weapon Enchants
    shaman_weapon = {
        "Earthliving Weapon",
        "Frostbrand Weapon",
        "Flametongue Weapon",
        "Windfury Weapon",
        "Rockbiter Weapon",
    },
    
    -- Hunter Traps
    trap = {
        "Freezing Trap",
        "Frost Trap",
        "Ice Trap",
        "Immolation Trap",
        "Explosive Trap",
        "Snake Trap",
        "Tar Trap",
        "Steel Trap",
        "High Explosive Trap",
    },
    
    -- Hunter Tracking
    track = {
        "Find Herbs",
        "Find Minerals",
        "Find Fish",
        "Track Humanoids",
        "Track Beasts",
        "Track Demons",
        "Track Undead",
        "Track Dragonkin",
        "Track Elementals",
        "Track Giants",
        "Track Hidden",
        "Sense Demons",
        "Sense Undead",
    },
    
    -- Hunter Aspects
    aspect = {
        "Aspect of the Hawk",
        "Aspect of the Monkey",
        "Aspect of the Pack",
        "Aspect of the Cheetah",
        "Aspect of the Viper",
        "Aspect of the Beast",
        "Aspect of the Wild",
        "Aspect of the Eagle",
        "Aspect of the Fox",
        "Aspect of the Turtle",
        "Aspect of the Chameleon",
    },
    
    -- Warlock Demon Summons
    warlockpet = {
        "Summon Imp",
        "Summon Voidwalker",
        "Summon Incubus",
        "Summon Succubus",
        "Summon Felhunter",
        "Summon Felguard",
        "Summon Infernal",
        "Summon Doomguard",
        "Inferno",
        "Ritual of Doom",
        "Enslave Demon",
        "Subjugate Demon",
        "Summon Demonic Tyrant",
    },
    
    -- Death Knight Presences (WotLK)
    presence = {
        "Blood Presence",
        "Frost Presence",
        "Unholy Presence",
    },
    
    -- Druid Forms
    shapeshift = {
        "Bear Form",
        "Dire Bear Form",
        "Cat Form",
        "Travel Form",
        "Aquatic Form",
        "Flight Form",
        "Swift Flight Form",
        "Moonkin Form",
        "Tree of Life",
    },
    
    -- Paladin Auras
    aura = {
        "Devotion Aura",
        "Retribution Aura",
        "Concentration Aura",
        "Shadow Resistance Aura",
        "Frost Resistance Aura",
        "Fire Resistance Aura",
        "Sanctity Aura",
        "Crusader Aura",
    },
    
    -- Paladin Blessings
    blessing = {
        "Blessing of Might",
        "Blessing of Wisdom",
        "Blessing of Kings",
        "Blessing of Salvation",
        "Blessing of Sanctuary",
        "Blessing of Light",
        "Blessing of Freedom",
        "Blessing of Protection",
        "Greater Blessing of Might",
        "Greater Blessing of Wisdom",
        "Greater Blessing of Kings",
        "Greater Blessing of Salvation",
        "Greater Blessing of Sanctuary",
        "Greater Blessing of Light",
    },
    
    -- Warrior Stances
    stance = {
        "Battle Stance",
        "Defensive Stance",
        "Berserker Stance",
    },
    
    -- Priest Chakras (Cata)
    chakra = {
        "Chakra: Serenity",
        "Chakra: Sanctuary",
        "Chakra: Chastise",
    },
}

-- ---------------------------------------------------------------------------
-- CONJURE SPELL TO ITEM MAPPINGS
-- Maps conjure spell IDs to the item IDs they create
-- ---------------------------------------------------------------------------

FluxFlyoutData.ConjureSpellItemMap = {
    -- Mage Conjure Water
    [587]   = 5349,   -- Conjure Water Rank 1 -> Conjured Water
    [5504]  = 5350,   -- Conjure Water Rank 2 -> Conjured Fresh Water
    [6129]  = 1487,   -- Conjure Water Rank 3 -> Conjured Purified Water
    [10144] = 8075,   -- Conjure Water Rank 4 -> Conjured Spring Water
    [10145] = 8076,   -- Conjure Water Rank 5 -> Conjured Mineral Water
    [27090] = 22018,  -- Conjure Water Rank 6 -> Conjured Sparkling Water
    [37420] = 30703,  -- Conjure Water Rank 7 -> Conjured Mountain Spring Water
    [42985] = 33312,  -- Conjure Refreshment -> Conjured Mana Strudel
    
    -- Mage Conjure Food
    [990]   = 1114,   -- Conjure Food Rank 1 -> Conjured Muffin
    [6127]  = 3772,   -- Conjure Food Rank 2 -> Conjured Bread
    [10054] = 8008,   -- Conjure Food Rank 3 -> Conjured Rye
    [597]   = 1113,   -- Conjure Food Rank 4 -> Conjured Pumpernickel
    [3552]  = 5513,   -- Conjure Food Rank 5 -> Conjured Sourdough
    [5506]  = 2136,   -- Conjure Food Rank 6 -> Conjured Sweet Roll
    [10053] = 8007,   -- Conjure Food Rank 7 -> Conjured Cinnamon Roll
    [28612] = 22895,  -- Conjure Food Rank 8 -> Conjured Croissant
    [33717] = 22019,  -- Conjure Food Rank 9 -> Conjured Mana Brownie
    [42955] = 43518,  -- Conjure Refreshment -> Conjured Mana Strudel
    [42956] = 43523,  -- Conjure Refreshment Rank 2 -> Conjured Mana Pie
    
    -- Mage Mana Gems
    [759]   = 5514,   -- Conjure Mana Agate -> Mana Agate
    [5505]  = 2288,   -- Conjure Mana Jade -> Mana Jade
    [10138] = 8077,   -- Conjure Mana Citrine -> Mana Citrine
    [10139] = 8078,   -- Conjure Mana Ruby -> Mana Ruby
    [10140] = 8079,   -- Conjure Mana Emerald -> Mana Emerald
    [27101] = 22044,  -- Conjure Mana Gem (WotLK+) -> Mana Emerald
    
    -- Warlock Healthstones (base items, talents modify)
    [6201]  = 5512,   -- Create Healthstone Rank 1
    [6202]  = 5511,   -- Create Healthstone Rank 2
    [5699]  = 5509,   -- Create Healthstone Rank 3
    [11729] = 5510,   -- Create Healthstone Rank 4
    [11730] = 9421,   -- Create Healthstone Rank 5
    [27230] = 22103,  -- Create Healthstone Rank 6
    [47871] = 36889,  -- Create Healthstone Rank 7
    [47878] = 36892,  -- Create Healthstone Rank 8
    
    -- Warlock Soulstones
    [693]   = 5232,   -- Create Soulstone Rank 1
    [20752] = 16892,  -- Create Soulstone Rank 2
    [20755] = 16893,  -- Create Soulstone Rank 3
    [20756] = 16895,  -- Create Soulstone Rank 4
    [20757] = 16896,  -- Create Soulstone Rank 5
    [27238] = 22116,  -- Create Soulstone Rank 6
    [47884] = 36895,  -- Create Soulstone Rank 7
    
    -- Warlock Firestones
    [6366]  = 1254,   -- Create Firestone Rank 1
    [17951] = 13699,  -- Create Firestone Rank 2
    [17952] = 13700,  -- Create Firestone Rank 3
    [17953] = 13701,  -- Create Firestone Rank 4
    [27250] = 22128,  -- Create Firestone Rank 5
    [60219] = 41173,  -- Create Firestone Rank 6
    [60220] = 41174,  -- Create Firestone Rank 7
    
    -- Warlock Spellstones
    [2362]  = 5522,   -- Create Spellstone Rank 1
    [17727] = 13602,  -- Create Spellstone Rank 2
    [17728] = 13603,  -- Create Spellstone Rank 3
    [28172] = 22646,  -- Create Spellstone Rank 4
    [47886] = 41191,  -- Create Spellstone Rank 5
    [47888] = 41196,  -- Create Spellstone Rank 6
}

FluxFlyoutData.ConjureSpellKinds = {
    food = {
        [990] = true, [6127] = true, [10054] = true, [597] = true, [3552] = true,
        [5506] = true, [10053] = true, [28612] = true, [33717] = true,
    },
    water = {
        [587] = true, [5504] = true, [6129] = true, [10144] = true, [10145] = true,
        [27090] = true, [37420] = true,
    },
    refreshment = {
        [42985] = true, [42955] = true, [42956] = true,
    },
}

function FluxFlyoutData.GetConjureSpellKind(spellId)
    spellId = tonumber(spellId)
    if not spellId then
        return nil
    end
    local kinds = FluxFlyoutData.ConjureSpellKinds
    if not kinds then
        return nil
    end
    if kinds.refreshment[spellId] then
        return "refreshment"
    end
    if kinds.food[spellId] then
        return "food"
    end
    if kinds.water[spellId] then
        return "water"
    end
    return nil
end

function FluxFlyoutData.PlayerHasConjureKind(kind)
    if not kind or not IsPlayerSpell then
        return false
    end
    local set = FluxFlyoutData.ConjureSpellKinds and FluxFlyoutData.ConjureSpellKinds[kind]
    if not set then
        return false
    end
    for spellId in pairs(set) do
        if IsPlayerSpell(spellId) then
            return true
        end
    end
    return false
end

function FluxFlyoutData.PlayerHasAnyConjureFoodWater()
    return FluxFlyoutData.PlayerHasConjureKind("food")
        or FluxFlyoutData.PlayerHasConjureKind("water")
        or FluxFlyoutData.PlayerHasConjureKind("refreshment")
end

-- Conjure spell names for dynamic detection
FluxFlyoutData.ConjureSpells = {
    -- Mage
    "Conjure Water",
    "Conjure Food",
    "Conjure Refreshment",
    "Conjure Mana Ruby",
    "Conjure Mana Citrine",
    "Conjure Mana Agate",
    "Conjure Mana Jade",
    "Conjure Mana Emerald",
    "Conjure Mana Gem",
    "Ritual of Refreshment",
    -- Warlock
    "Create Healthstone",
    "Create Soulstone",
    "Create Firestone",
    "Create Spellstone",
}

-- ---------------------------------------------------------------------------
-- TEMPORARY WEAPON ENCHANTS
-- Item IDs for poisons, oils, sharpening stones, weightstones, etc.
-- ---------------------------------------------------------------------------

FluxFlyoutData.ItemEnchantTemp = {
    -- Rogue Poisons (crafted items)
    [43231] = true, -- Instant Poison IX
    [43233] = true, -- Deadly Poison IX
    [43235] = true, -- Wound Poison VII
    [43237] = true, -- Anesthetic Poison II
    [21927] = true, -- Instant Poison VII
    [22054] = true, -- Deadly Poison VII
    [22055] = true, -- Wound Poison V
    [21835] = true, -- Anesthetic Poison
    [8928]  = true, -- Instant Poison VI
    [22053] = true, -- Deadly Poison VI
    [10922] = true, -- Wound Poison IV
    [8927]  = true, -- Instant Poison V
    [20844] = true, -- Deadly Poison V
    [10921] = true, -- Wound Poison III
    [8926]  = true, -- Instant Poison IV
    [8985]  = true, -- Deadly Poison IV
    [10920] = true, -- Wound Poison II
    [6950]  = true, -- Instant Poison III
    [8984]  = true, -- Deadly Poison III
    [10918] = true, -- Wound Poison
    [6949]  = true, -- Instant Poison II
    [2893]  = true, -- Deadly Poison II
    [6947]  = true, -- Instant Poison
    [2892]  = true, -- Deadly Poison
    [3775]  = true, -- Crippling Poison
    [3776]  = true, -- Crippling Poison II
    [5237]  = true, -- Mind-numbing Poison
    [6951]  = true, -- Mind-numbing Poison II
    [9186]  = true, -- Mind-numbing Poison III
    [31535] = true, -- Bloodboil Poison
    [43232] = true, -- Deadly Poison VIII
    [43230] = true, -- Instant Poison VIII
    [43234] = true, -- Wound Poison VI
    
    -- Wizard Oils
    [20748] = true, -- Brilliant Mana Oil
    [20749] = true, -- Brilliant Wizard Oil
    [22522] = true, -- Superior Wizard Oil
    [20750] = true, -- Wizard Oil
    [22521] = true, -- Superior Mana Oil
    [20747] = true, -- Lesser Mana Oil
    [20746] = true, -- Lesser Wizard Oil
    [23123] = true, -- Blessed Wizard Oil
    [20744] = true, -- Minor Wizard Oil
    [20745] = true, -- Minor Mana Oil
    [36900] = true, -- Exceptional Wizard Oil
    [36899] = true, -- Exceptional Mana Oil
    
    -- Sharpening Stones
    [28421] = true, -- Adamantite Weightstone
    [18262] = true, -- Elemental Sharpening Stone
    [23529] = true, -- Adamantite Sharpening Stone
    [12643] = true, -- Dense Weightstone
    [12404] = true, -- Dense Sharpening Stone
    [2863]  = true, -- Coarse Sharpening Stone
    [2862]  = true, -- Rough Sharpening Stone
    [23122] = true, -- Consecrated Sharpening Stone
    [23528] = true, -- Fel Sharpening Stone
    [2871]  = true, -- Heavy Sharpening Stone
    [7964]  = true, -- Solid Sharpening Stone
    [28420] = true, -- Fel Weightstone
    [3241]  = true, -- Heavy Weightstone
    [3240]  = true, -- Coarse Weightstone
    [7965]  = true, -- Solid Weightstone
    [3239]  = true, -- Rough Weightstone
    [34538] = true, -- Blessed Weapon Coating
    [34539] = true, -- Righteous Weapon Coating
    
    -- Misc Oils
    [3829]  = true, -- Frost Oil
    [3824]  = true, -- Shadow Oil
    
    -- Fishing Lures
    [6533]  = true, -- Aquadynamic Fish Attractor
    [6532]  = true, -- Bright Baubles
    [6530]  = true, -- Nightcrawlers
    [6529]  = true, -- Shiny Bauble
    [34861] = true, -- Sharpened Fish Hook
    [6811]  = true, -- Aquadynamic Fish Lens
    [7307]  = true, -- Flesh Eating Worm
    [46006] = true, -- Glow Worm
    [35713] = true, -- Ninja Hook
    
    -- Wards
    [23576] = true, -- Greater Ward of Shielding
    [25521] = true, -- Greater Rune of Warding
    [23575] = true, -- Lesser Ward of Shielding
    [23559] = true, -- Lesser Rune of Warding
    
    -- Comfort Items
    [25679] = true, -- Comfortable Insoles
    
    -- Warlock Stones (created items)
    [41196] = true, -- Grand Spellstone
    [41194] = true, -- Master Spellstone
    [41174] = true, -- Grand Firestone
    [40773] = true, -- Master Firestone
    [41191] = true, -- Spellstone
    [41169] = true, -- Firestone
    [41173] = true, -- Fel Firestone
    [41192] = true, -- Greater Spellstone
    [41193] = true, -- Major Spellstone
    [41170] = true, -- Lesser Firestone
    [41171] = true, -- Greater Firestone
    [41172] = true, -- Major Firestone
    [41195] = true, -- Demonic Spellstone
}

-- ---------------------------------------------------------------------------
-- HEARTHSTONE AND TELEPORT ITEMS
-- Items that teleport the player
-- ---------------------------------------------------------------------------

FluxFlyoutData.TeleportItems = {
    6948,   -- Hearthstone
    64488,  -- The Innkeeper's Daughter
    93672,  -- Dark Portal
    110560, -- Garrison Hearthstone
    140192, -- Dalaran Hearthstone
    141605, -- Flight Master's Whistle
    162973, -- War-Scroll of Recall
    163045, -- Headless Horseman's Hearthstone
    165669, -- Lunar Elder's Hearthstone
    165670, -- Peddlefeet's Lovely Hearthstone
    165802, -- Noble Gardener's Hearthstone
    166746, -- Fire Eater's Hearthstone
    166747, -- Brewfest Reveler's Hearthstone
    168907, -- Holographic Digitalization Hearthstone
    172179, -- Eternal Traveler's Hearthstone
    180290, -- Night Fae Hearthstone
    180817, -- Cypher of Relocation
    182773, -- Necrolord Hearthstone
    183716, -- Venthyr Sinstone
    184353, -- Kyrian Hearthstone
    188952, -- Dominated Hearthstone
    190237, -- Broker Translocation Matrix
    193588, -- Timewalker's Hearthstone
    200630, -- Ohn'ir Windsage's Hearthstone
    206195, -- Path of the Naaru
    208704, -- Deepdweller's Earthen Hearthstone
    209035, -- Hearthstone of the Flame
    210455, -- Draenic Hologem
    212337, -- Stone of the Hearth
    228940, -- Notorious Thread's Hearthstone
}

-- ---------------------------------------------------------------------------
-- MOUNT ITEMS (items that summon mounts)
-- ---------------------------------------------------------------------------

FluxFlyoutData.MountItems = {
    -- Epic Mount Items
    18241, -- Black Qiraji Resonating Crystal
    21176, -- Black Qiraji Resonating Crystal (different ID)
    49285, -- X-53 Touring Rocket
    50818, -- Invincible's Reins
    54069, -- Blazing Hippogryph
    -- More can be added
}

-- ---------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-- ---------------------------------------------------------------------------

-- Get player faction for portal/teleport filtering
function FluxFlyoutData.GetPlayerFaction()
    local faction = UnitFactionGroup("player")
    return faction -- "Alliance", "Horde", or "Neutral"
end

-- Check if a spell is known by name
function FluxFlyoutData.IsSpellKnown(spellName)
    if not spellName then return false end
    
    -- Modern API (10.0+)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellName)
        if info and info.spellID then
            if IsSpellKnown then
                return IsSpellKnown(info.spellID)
            end
            -- Fallback: check if spell is in spellbook
            if C_SpellBook and C_SpellBook.IsSpellBookItemLearned then
                return C_SpellBook.IsSpellBookItemLearned(spellName)
            end
            return true
        end
        return false
    end
    
    -- Legacy API
    if GetSpellInfo then
        local name, _, _, _, _, _, spellId = GetSpellInfo(spellName)
        if name and spellId then
            if IsSpellKnown then
                return IsSpellKnown(spellId)
            end
            return true
        end
    end
    
    return false
end

-- Get spell info cross-version
function FluxFlyoutData.GetSpellInfo(spellIdOrName)
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

-- Get spell texture cross-version
function FluxFlyoutData.GetSpellTexture(spellIdOrName)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellIdOrName)
    elseif GetSpellTexture then
        return GetSpellTexture(spellIdOrName)
    end
    -- Fallback: get from spell info
    local _, _, icon = FluxFlyoutData.GetSpellInfo(spellIdOrName)
    return icon
end

-- Get item info cross-version
function FluxFlyoutData.GetItemInfo(itemIdOrName)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemIdOrName)
    elseif GetItemInfo then
        return GetItemInfo(itemIdOrName)
    end
    return nil
end

-- Get item icon cross-version
function FluxFlyoutData.GetItemIcon(itemId)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemId)
    elseif GetItemIcon then
        return GetItemIcon(itemId)
    end
    -- Fallback from item info
    local _, _, _, _, _, _, _, _, _, icon = FluxFlyoutData.GetItemInfo(itemId)
    return icon
end

-- Get known spells from a spell list
function FluxFlyoutData.GetKnownSpellsFromList(listName)
    local spellList = FluxFlyoutData.SpellLists[listName]
    if not spellList then return {} end
    
    local knownSpells = {}
    for _, spellName in ipairs(spellList) do
        if FluxFlyoutData.IsSpellKnown(spellName) then
            table.insert(knownSpells, spellName)
        end
    end
    
    return knownSpells
end

-- Get conjure item ID for a spell ID
function FluxFlyoutData.GetConjuredItemId(spellId)
    return FluxFlyoutData.ConjureSpellItemMap[spellId]
end

-- Check if an item is a temporary weapon enchant
function FluxFlyoutData.IsTempEnchantItem(itemId)
    return FluxFlyoutData.ItemEnchantTemp[itemId] == true
end

-- Scan bags for temp enchant items
function FluxFlyoutData.GetBagTempEnchantItems()
    local items = {}
    local seen = {}
    
    -- Modern container API
    local GetContainerNumSlots = _G.GetContainerNumSlots or (C_Container and C_Container.GetContainerNumSlots)
    local GetContainerItemID = FluxGetContainerItemID or _G.GetContainerItemID or (C_Container and C_Container.GetContainerItemID)
    
    if not GetContainerNumSlots or not GetContainerItemID then
        return items
    end
    
    local numBags = NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemId = GetContainerItemID(bag, slot)
            if itemId and FluxFlyoutData.ItemEnchantTemp[itemId] and not seen[itemId] then
                table.insert(items, itemId)
                seen[itemId] = true
            end
        end
    end
    
    return items
end

-- Get known conjure spells
function FluxFlyoutData.GetKnownConjureSpells()
    local knownSpells = {}
    
    for _, spellName in ipairs(FluxFlyoutData.ConjureSpells) do
        if FluxFlyoutData.IsSpellKnown(spellName) then
            local name, _, _, _, _, _, spellId = FluxFlyoutData.GetSpellInfo(spellName)
            if spellId then
                table.insert(knownSpells, spellId)
            end
        end
    end
    
    return knownSpells
end

-- Debug: Print all loaded data counts
function FluxFlyoutData.DebugPrint()
    print("|cff00ffff[FluxFlyoutData]|r Loaded:")
    print("  SpellLists categories:", 0)
    local count = 0
    for k, v in pairs(FluxFlyoutData.SpellLists) do
        count = count + 1
    end
    print("  SpellLists categories:", count)
    
    count = 0
    for k, v in pairs(FluxFlyoutData.ConjureSpellItemMap) do
        count = count + 1
    end
    print("  ConjureSpellItemMap entries:", count)
    
    count = 0
    for k, v in pairs(FluxFlyoutData.ItemEnchantTemp) do
        count = count + 1
    end
    print("  ItemEnchantTemp entries:", count)
end

-- Export for slash command debugging
SLASH_FLYOUTDATA1 = "/flyoutdata"
SlashCmdList["FLYOUTDATA"] = function(msg)
    FluxFlyoutData.DebugPrint()
end

