local addonName, ns = ...

local function GetDB()
    return FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB() or {}
end

local function AfterPerUnitChange()
    if FluxOptions and FluxOptions.RefreshUnitFrameScopedModules then
        FluxOptions:RefreshUnitFrameScopedModules()
    end
end

local function AfterFeatureChange()
    if FluxOptions and FluxOptions.RefreshUnitFrameScopedModules then
        FluxOptions:RefreshUnitFrameScopedModules()
    end
end

local function IsSwingTimerClientSupported()
    local cap = ns.Flux and ns.Flux.Cap
    if cap and cap.disableSwingTimer ~= nil then
        return not cap.disableSwingTimer
    end
    if FLUX_API and FLUX_API.disableSwingTimer ~= nil then
        return not FLUX_API.disableSwingTimer
    end
    return true
end

local function AfterLayoutSizingChange()
    if FluxUnitFrames_ApplyFrameSizesFromDB then
        FluxUnitFrames_ApplyFrameSizesFromDB()
    end
end

local function IsSideBySidePlayerTargetLayout()
    return FluxOptions and FluxOptions.GetPlayerTargetPlacement and FluxOptions:GetPlayerTargetPlacement() == 2
end

--- Per Layout placement bucket (OptionsBridge loads after this file; call only at runtime).
local function FrameSizesBucket()
    local d = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if not d then
        return nil
    end
    local placement = 1
    if FluxOptions and FluxOptions.GetPlayerTargetPlacement then
        placement = FluxOptions:GetPlayerTargetPlacement()
        if placement ~= 2 then
            placement = 1
        end
    end
    if FluxUnitFrames_EnsureAndGetFrameSizesBucket then
        return FluxUnitFrames_EnsureAndGetFrameSizesBucket(d, placement)
    end
    d.frameSizes = d.frameSizes or {}
    return d.frameSizes
end

local function DefaultDim(unit, dim)
    if FluxUnitFrames_GetUnitFrameDefaultDimension then
        local v = FluxUnitFrames_GetUnitFrameDefaultDimension(unit, dim)
        if v then
            return v
        end
    end
    if unit == "player" then
        return dim == "width" and 325 or 100
    end
    if unit == "target" then
        return dim == "width" and 500 or 100
    end
    if unit == "targettarget" then
        return dim == "width" and 125 or 60
    end
    if unit == "focus" then
        return dim == "width" and 119 or 50
    end
    if unit == "pet" then
        return dim == "width" and 100 or 50
    end
    if unit == "pettarget" then
        return dim == "width" and 23
    end
    return nil
end

--- Placement 2 stores larger "design" units; sliders show on-screen (effective) pixels.
local function FrameSizeStorageToEffective(raw)
    if raw == nil then
        return nil
    end
    if not IsSideBySidePlayerTargetLayout() then
        return raw
    end
    if FluxUnitFrames_UnitFrameStorageToEffectiveDimension then
        return FluxUnitFrames_UnitFrameStorageToEffectiveDimension(2, raw)
    end
    return math.max(1, math.floor(raw * 0.7 + 0.5))
end

local function FrameSizeEffectiveToStorage(eff)
    if eff == nil then
        return nil
    end
    if not IsSideBySidePlayerTargetLayout() then
        return eff
    end
    if FluxUnitFrames_UnitFrameEffectiveToStorageDimension then
        return FluxUnitFrames_UnitFrameEffectiveToStorageDimension(2, eff)
    end
    return math.max(1, math.floor(eff / 0.7 + 0.5))
end

local function AfterAuraOptionsChange()
    if FluxUnitFrames_ApplyAuraLayoutFromDB then
        FluxUnitFrames_ApplyAuraLayoutFromDB()
    end
end

local function AfterPortraitOptionsChange()
    if FluxUnitFrames_ApplyPortraitOptionsFromDB then
        FluxUnitFrames_ApplyPortraitOptionsFromDB()
    end
end

local function AfterTargetPlaceholderChange()
    if FluxUnitFrames_RefreshTargetPlaceholderFromDB then
        FluxUnitFrames_RefreshTargetPlaceholderFromDB()
    end
end

local function HealthPartitionGetFor(unit)
    local d = GetDB()
    d.healthPartitions = d.healthPartitions or {}
    local v = d.healthPartitions[unit]
    if v == nil and d.healthPartition ~= nil then
        v = tonumber(d.healthPartition)
    end
    if v == nil then
        v = 0.6
    end
    return v * 100
end

local function HealthPartitionSetFor(unit, val)
    local d = GetDB()
    d.healthPartitions = d.healthPartitions or {}
    d.healthPartitions[unit] = val / 100
    if FluxUnitFrames_RefreshBarPartitionsFromDB then
        FluxUnitFrames_RefreshBarPartitionsFromDB()
    end
end

local function HasFocusUnit()
    return FLUX_API and FLUX_API.hasFocusUnit
end

--- Portrait/side threat bars: always | group | never (legacy threatBarGroupOnly maps to always/group).
local function GetThreatBarVisibility()
    local d = GetDB()
    local v = d.threatBarVisibility
    if v == "always" or v == "group" or v == "never" then
        return v
    end
    if d.threatBarGroupOnly == false then
        return "always"
    end
    return "group"
end

local function SetThreatBarVisibility(v)
    if v ~= "always" and v ~= "group" and v ~= "never" then
        v = "group"
    end
    local d = GetDB()
    d.threatBarVisibility = v
    -- Keep legacy boolean in sync for older readers.
    d.threatBarGroupOnly = (v == "group")
    if FluxUnitFrames_ApplyThreatBarOptionsFromDB then
        FluxUnitFrames_ApplyThreatBarOptionsFromDB()
    end
end

local THREAT_BAR_VISIBILITY_VALUES = {
    always = "Always",
    group = "In group or raid only",
    never = "Never",
}

local THREAT_BAR_VISIBILITY_DESC =
    "When target/focus portrait and side threat bars are allowed. Always = solo and grouped. In group or raid only = party/raid. Never = hide those threat bars. The between-chrome threat strip stays reserved unless Never is selected."

local HEALTH_TEXT_VALUES = {
    both = "Current and percent",
    percent = "Percent",
    values = "Values",
    none = "Hidden",
}

local function DisplayGet(unit, key)
    local row = GetDB().display and GetDB().display[unit]
    if not row or row[key] == nil then
        return true
    end
    return row[key] and true or false
end

local function DisplaySet(unit, key, value)
    local d = GetDB()
    d.display = d.display or {}
    d.display[unit] = d.display[unit] or {}
    d.display[unit][key] = value and true or false
    AfterFeatureChange()
end

local function FlagToggle(unit, key, name, desc, order)
    return {
        type = "toggle",
        name = name,
        desc = desc,
        order = order,
        get = function()
            return DisplayGet(unit, key)
        end,
        set = function(_, v)
            DisplaySet(unit, key, v)
        end,
    }
end

local function HealthTextOpt(unit, fallback, order)
    return {
        type = "select",
        name = "Health text",
        desc = "Current and percent, percent only, values only, or hidden.",
        order = order,
        values = HEALTH_TEXT_VALUES,
        sorting = { "both", "percent", "values", "none" },
        get = function()
            local row = GetDB().display and GetDB().display[unit]
            local mode = row and row.healthText
            if mode == "both" or mode == "percent" or mode == "values" or mode == "none" then
                return mode
            end
            return fallback
        end,
        set = function(_, v)
            if v ~= "both" and v ~= "percent" and v ~= "values" and v ~= "none" then
                v = fallback
            end
            DisplaySet(unit, "healthText", v)
        end,
    }
end

--- DisplaySet stores booleans. Health text is a string, so write it directly.
local function SetHealthText(unit, mode)
    local d = GetDB()
    d.display = d.display or {}
    d.display[unit] = d.display[unit] or {}
    d.display[unit].healthText = mode
    AfterFeatureChange()
end

local function AuraToggle(dbKey, flag, name, order)
    return {
        type = "toggle",
        name = name,
        order = order,
        get = function()
            local t = GetDB()[dbKey]
            if not t or t[flag] == nil then
                return true
            end
            return t[flag] and true or false
        end,
        set = function(_, v)
            local d = GetDB()
            d[dbKey] = d[dbKey] or {}
            d[dbKey][flag] = v and true or false
            AfterAuraOptionsChange()
        end,
    }
end

local function AddTextAndBars(bucket, unit, order, flags)
    bucket[unit .. "TextHeader"] = {
        type = "header",
        name = flags.header or "Text and bars",
        order = order,
    }
    local n = order
    local function nextOrder()
        n = n + 0.1
        return n
    end
    if flags.castBar then
        bucket[unit .. "CastBar"] = FlagToggle(unit, "castBar", "Cast bar", "Show the cast bar on this frame.", nextOrder())
    end
    if flags.castTime then
        bucket[unit .. "CastTime"] = FlagToggle(unit, "castTime", "Cast time", "Show remaining time on the cast bar.", nextOrder())
    end
    if flags.health then
        local opt = HealthTextOpt(unit, flags.health, nextOrder())
        opt.set = function(_, v)
            if v ~= "both" and v ~= "percent" and v ~= "values" and v ~= "none" then
                v = flags.health
            end
            SetHealthText(unit, v)
        end
        bucket[unit .. "HealthText"] = opt
    end
    if flags.power then
        bucket[unit .. "PowerText"] = FlagToggle(unit, "powerText", "Power numbers", nil, nextOrder())
    end
    if flags.heal then
        bucket[unit .. "Heal"] = FlagToggle(unit, "healPrediction", "Heal prediction", nil, nextOrder())
    end
    if flags.absorb then
        bucket[unit .. "Absorb"] = FlagToggle(unit, "absorbs", "Absorbs", nil, nextOrder())
    end
    if flags.classPower then
        bucket[unit .. "ClassPower"] = FlagToggle(unit, "classPower", "Class power", "Combo points, runes, essence, and the other class resource bars.", nextOrder())
    end
end

local function AddIcons(bucket, unit, order, flags)
    bucket[unit .. "IconHeader"] = {
        type = "header",
        name = "Icons",
        order = order,
    }
    local n = order
    local function nextOrder()
        n = n + 0.1
        return n
    end
    if flags.level then
        bucket[unit .. "Level"] = FlagToggle(unit, "level", "Level", nil, nextOrder())
    end
    if flags.classIcon then
        bucket[unit .. "ClassIcon"] = FlagToggle(unit, "classIcon", "Class icon", nil, nextOrder())
    end
    if flags.pvp then
        bucket[unit .. "Pvp"] = FlagToggle(unit, "pvp", "PvP flag", nil, nextOrder())
    end
    if flags.combat then
        bucket[unit .. "Combat"] = FlagToggle(unit, "combat", "Combat icon", nil, nextOrder())
    end
    if flags.raidIcon then
        bucket[unit .. "RaidIcon"] = FlagToggle(unit, "raidIcon", "Raid marker", nil, nextOrder())
    end
    if flags.portraitCombat then
        bucket[unit .. "PortraitCombat"] = FlagToggle(unit, "portraitCombat", "Portrait combat text", nil, nextOrder())
    end
    if flags.mouseover then
        bucket[unit .. "Mouseover"] = FlagToggle(unit, "mouseover", "Mouseover highlight", nil, nextOrder())
    end
end

local function RelaxToggleWidths(group)
    if type(group) ~= "table" or type(group.args) ~= "table" then
        return
    end
    for _, opt in pairs(group.args) do
        if type(opt) == "table" then
            if opt.type == "toggle" then
                opt.width = nil
            elseif opt.type == "group" then
                RelaxToggleWidths(opt)
            end
        end
    end
end

local function AttachMergedFrameOptions(options)
    local args = options.args
    local general = args.general.args
    local player = args.unitPlayer.args
    local target = args.unitTarget.args
    local focus = args.unitFocus.args
    local pet = args.unitPet.args

    general.scopeDesc.name = "Unit frame scope applies to Player, Pet, Target, and Focus. Party / raid scope applies to the Party / Raid tab. Character-specific data is not copied with Profiles.\n"

    general.raidSettingsScope = {
        type = "select",
        name = "Party / raid settings scope",
        desc = "Account-wide stores party and raid options in the active profile. Character-specific keeps them on this character only.",
        order = 0.8,
        width = "full",
        values = {
            account = "Account-wide",
            character = "Character-specific",
        },
        sorting = { "account", "character" },
        get = function()
            return FluxOptions:IsRaidFramesCharacterSpecific() and "character" or "account"
        end,
        set = function(_, val)
            FluxOptions:SetRaidFrameCharacterSpecific(val == "character")
        end,
    }

    general.useFluxRaidFrames = {
        type = "toggle",
        name = "Party / raid",
        desc = "Use Flux compact party and raid frames. When off, Blizzard party and raid frames are restored.",
        order = 8.5,
        get = function()
            local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
            return db.useFluxRaidFrames ~= false
        end,
        set = function(_, v)
            local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
            if db then
                db.useFluxRaidFrames = v and true or false
            end
            if FluxOptions and FluxOptions.RefreshRaidFrameScopedModules then
                FluxOptions:RefreshRaidFrameScopedModules()
            end
        end,
    }

    general.resetRaidFrames = {
        type = "execute",
        name = "Reset party / raid options",
        desc = "Restores Party / Raid tab settings for the current party / raid scope.",
        order = 9.5,
        confirm = true,
        func = function()
            if FluxOptions and FluxOptions.ResetRaidFramesToDefaults then
                FluxOptions:ResetRaidFramesToDefaults()
            end
        end,
    }

    general.resetUnitFrames.desc = "Restores Player, Pet, Target, and Focus settings for the current unit frame scope."

    local moveKeys = {
        "enableMP5Overlay",
        "swingTimerUnsupportedNote",
        "enableSwingTimer",
        "enableFlightPathTimers",
        "enableFlightPathCastBar",
        "enableFlightPathTooltips",
    }
    player.playerExtrasHeader = {
        type = "header",
        name = "Player extras",
        order = 40,
    }
    for i = 1, #moveKeys do
        local key = moveKeys[i]
        local opt = general[key]
        general[key] = nil
        if opt then
            opt.order = 40 + (i * 0.1)
            player[key] = opt
        end
    end

    target.targetThreatBarVisibility = nil
    focus.focusThreatBarVisibility = nil

    local tot = args.unitTargetOfTarget
    args.unitTargetOfTarget = nil
    if tot then
        tot.inline = true
        tot.order = 80
        tot.name = "Target of target"
        target.unitTargetOfTarget = tot
    end
    local petTarget = args.unitPetTarget
    args.unitPetTarget = nil
    if petTarget then
        petTarget.inline = true
        petTarget.order = 80
        petTarget.name = "Pet target"
        pet.unitPetTarget = petTarget
    end

    args.unitPet.order = 2
    args.unitTarget.order = 3
    args.unitFocus.order = 4

    AddTextAndBars(player, "player", 30, {
        castBar = true,
        castTime = true,
        health = "both",
        power = true,
        heal = true,
        absorb = true,
        classPower = true,
    })
    AddIcons(player, "player", 36, {
        level = true,
        classIcon = true,
        pvp = true,
        combat = true,
        raidIcon = true,
        portraitCombat = true,
        mouseover = true,
    })

    AddTextAndBars(target, "target", 20, {
        castBar = true,
        castTime = true,
        health = "both",
        power = true,
        heal = true,
        absorb = true,
    })
    AddIcons(target, "target", 26, {
        level = true,
        classIcon = true,
        pvp = true,
        raidIcon = true,
        portraitCombat = true,
        mouseover = true,
    })
    target.targetShowBuffs = AuraToggle("auraTarget", "showBuffs", "Show buffs", 3.6)
    target.targetShowDebuffs = AuraToggle("auraTarget", "showDebuffs", "Show debuffs", 3.7)
    if tot and tot.args then
        AddTextAndBars(tot.args, "targettarget", 10, {
            header = "Text and bars",
            health = "percent",
            power = true,
            heal = true,
            absorb = true,
        })
        AddIcons(tot.args, "targettarget", 16, {
            raidIcon = true,
            mouseover = true,
        })
    end

    AddTextAndBars(focus, "focus", 20, {
        castBar = true,
        castTime = true,
        health = "percent",
        power = true,
        heal = true,
        absorb = true,
    })
    AddIcons(focus, "focus", 26, {
        level = true,
        classIcon = true,
        pvp = true,
        raidIcon = true,
        portraitCombat = true,
        mouseover = true,
    })
    focus.focusShowBuffs = AuraToggle("auraFocus", "showBuffs", "Show buffs", 3.6)
    focus.focusShowDebuffs = AuraToggle("auraFocus", "showDebuffs", "Show debuffs", 3.7)
    focus.focusTargetHeader = {
        type = "header",
        name = "Focus target",
        order = 70,
    }
    focus.focusTargetDesc = {
        type = "description",
        name = "The focus target bar matches the focus frame size.\n",
        order = 70.05,
        fontSize = "small",
    }
    AddTextAndBars(focus, "focustarget", 70.1, {
        header = "Focus target text",
        health = "percent",
        power = true,
        heal = true,
        absorb = true,
    })
    focus.focustargetMouseover = FlagToggle("focustarget", "mouseover", "Mouseover highlight", nil, 71)
    focus.focustargetRaidIcon = FlagToggle("focustarget", "raidIcon", "Raid marker", nil, 71.1)

    AddTextAndBars(pet, "pet", 20, {
        castTime = true,
        health = "percent",
        power = true,
        heal = true,
        absorb = true,
    })
    AddIcons(pet, "pet", 26, {
        raidIcon = true,
        mouseover = true,
    })
    if petTarget and petTarget.args then
        AddTextAndBars(petTarget.args, "pettarget", 10, {
            header = "Text and bars",
            health = "percent",
            power = true,
            heal = true,
            absorb = true,
        })
        petTarget.args.pettargetMouseover = FlagToggle("pettarget", "mouseover", "Mouseover highlight", nil, 16)
    end

    if ns.FluxOptionsBuildPartyRaidTab then
        args.partyRaid = ns.FluxOptionsBuildPartyRaidTab()
    end

    RelaxToggleWidths(options)
end

local function BuildUnitFrameOptions()
    local options = {
    name = "Unit frames",
    type = "group",
    order = 23,
    childGroups = "tab",
    args = {
        -- ----------------------------------------------------------------
        -- General: scope, Flux vs Blizzard, overlays/features
        -- ----------------------------------------------------------------
        general = {
            type = "group",
            name = "General",
            order = 0,
            args = {
                scopeHeader = {
                    type = "header",
                    name = "Settings",
                    order = 0,
                },
                settingsScope = {
                    type = "select",
                    name = "Unit frame settings scope",
                    desc = "Account-wide stores these options in the active profile (follows the Profiles tab). Character-specific keeps them on this character only, independent of General > Settings scope.",
                    order = 0.5,
                    width = "full",
                    values = {
                        account = "Account-wide",
                        character = "Character-specific",
                    },
                    sorting = { "account", "character" },
                    get = function()
                        return FluxOptions:IsUnitFramesCharacterSpecific() and "character" or "account"
                    end,
                    set = function(_, val)
                        FluxOptions:SetUnitFrameCharacterSpecific(val == "character")
                    end,
                },
                scopeDesc = {
                    type = "description",
                    name = "This scope applies to every sub-tab below. Character-specific unit frame data is not duplicated when you copy profiles in the Profiles tab.\n",
                    order = 0.65,
                    fontSize = "small",
                },

                fluxVsBlizHeader = {
                    type = "header",
                    name = "Flux vs Blizzard",
                    order = 1,
                },
                fluxVsBlizDesc = {
                    type = "description",
                    name = "When Flux is off for a unit, the default Blizzard frame is used. Pet and target-of-target require the Flux player or target frame. Party / raid uses the compact grid. Changes apply immediately.\n",
                    order = 1.5,
                    fontSize = "small",
                },

                useFluxPlayer = {
                    type = "toggle",
                    name = "Player",
                    desc = "Use Flux player frame. When off, Blizzard PlayerFrame is used; Flux pet requires Flux player.",
                    order = 2,
                    width = "full",
                    get = function() return GetDB().useFluxPlayer ~= false end,
                    set = function(_, v)
                        GetDB().useFluxPlayer = v and true or false
                        AfterPerUnitChange()
                    end,
                },
                useFluxTarget = {
                    type = "toggle",
                    name = "Target",
                    desc = "Use Flux target frame. When off, Blizzard TargetFrame is used. Target-of-target (Flux) requires Flux target.",
                    order = 3,
                    width = "full",
                    get = function() return GetDB().useFluxTarget ~= false end,
                    set = function(_, v)
                        GetDB().useFluxTarget = v and true or false
                        AfterPerUnitChange()
                    end,
                },
                useFluxTargetOfTarget = {
                    type = "toggle",
                    name = "Target of target",
                    desc = "Requires Flux target. When off, Blizzard ToT is used if available.",
                    order = 4,
                    width = "full",
                    disabled = function() return GetDB().useFluxTarget == false end,
                    get = function() return GetDB().useFluxTargetOfTarget ~= false end,
                    set = function(_, v)
                        GetDB().useFluxTargetOfTarget = v and true or false
                        AfterPerUnitChange()
                    end,
                },
                useFluxFocus = {
                    type = "toggle",
                    name = "Focus",
                    desc = "Use Flux focus frame. When off, Blizzard FocusFrame is used. Focus target bar requires Flux focus.",
                    order = 5,
                    width = "full",
                    hidden = function() return not HasFocusUnit() end,
                    get = function() return GetDB().useFluxFocus ~= false end,
                    set = function(_, v)
                        GetDB().useFluxFocus = v and true or false
                        AfterPerUnitChange()
                    end,
                },
                useFluxFocusTarget = {
                    type = "toggle",
                    name = "Focus target",
                    desc = "Requires Flux focus. When off, Blizzard focus ToT is used.",
                    order = 6,
                    width = "full",
                    hidden = function() return not HasFocusUnit() end,
                    disabled = function() return GetDB().useFluxFocus == false end,
                    get = function() return GetDB().useFluxFocusTarget ~= false end,
                    set = function(_, v)
                        GetDB().useFluxFocusTarget = v and true or false
                        AfterPerUnitChange()
                    end,
                },
                useFluxPet = {
                    type = "toggle",
                    name = "Pet",
                    desc = "Requires Flux player frame. When off, Blizzard PetFrame is used.",
                    order = 7,
                    width = "full",
                    disabled = function() return GetDB().useFluxPlayer == false end,
                    get = function() return GetDB().useFluxPet ~= false end,
                    set = function(_, v)
                        GetDB().useFluxPet = v and true or false
                        AfterPerUnitChange()
                    end,
                },
                useFluxPetTarget = {
                    type = "toggle",
                    name = "Pet target",
                    desc = "Requires Flux pet (and Flux player). When off, pet target strip is not created.",
                    order = 8,
                    width = "full",
                    disabled = function()
                        local d = GetDB()
                        return d.useFluxPlayer == false or d.useFluxPet == false
                    end,
                    get = function() return GetDB().useFluxPetTarget ~= false end,
                    set = function(_, v)
                        GetDB().useFluxPetTarget = v and true or false
                        AfterPerUnitChange()
                    end,
                },

                resetUnitFrames = {
                    type = "execute",
                    name = "Reset unit frame options to defaults",
                    desc = "Restores Flux vs Blizzard toggles and feature toggles to FluxUI defaults for the current scope (all unit frame tabs).",
                    order = 9,
                    width = "full",
                    confirm = true,
                    func = function()
                        if FluxOptions and FluxOptions.ResetUnitFramesToDefaults then
                            FluxOptions:ResetUnitFramesToDefaults()
                        end
                        AfterPerUnitChange()
                    end,
                },

                featuresHeader = {
                    type = "header",
                    name = "Features",
                    order = 20,
                },
                featuresDesc = {
                    type = "description",
                    name = "These options apply immediately to Flux unit frames.\n",
                    order = 20.5,
                    fontSize = "small",
                },
                use3DPortraits = {
                    type = "toggle",
                    name = "3D portraits",
                    desc = "When enabled, the portrait strip uses animated 3D models. When disabled, classic flat (2D) portraits are used for player, target, focus, and pet.",
                    order = 20.7,
                    width = "full",
                    get = function()
                        return GetDB().use3DPortraits ~= false
                    end,
                    set = function(_, v)
                        GetDB().use3DPortraits = v and true or false
                        if FluxUnitFrames_RefreshPortraitRenderModeFromDB then
                            FluxUnitFrames_RefreshPortraitRenderModeFromDB()
                        end
                    end,
                },
                enablePortraitCombatTint = {
                    type = "toggle",
                    name = "Combat portrait tint",
                    desc = "When this unit is in combat, its portrait border and the background behind the portrait turn red. Each frame uses its own unit, so a target or focus in combat stays red even if you are not.",
                    order = 20.8,
                    width = "full",
                    get = function()
                        return GetDB().enablePortraitCombatTint ~= false
                    end,
                    set = function(_, v)
                        GetDB().enablePortraitCombatTint = v and true or false
                        AfterFeatureChange()
                    end,
                },
                enableHealthLossOverlay = {
                    type = "toggle",
                    name = "Health loss overlay",
                    order = 21,
                    width = "full",
                    get = function() return GetDB().enableHealthLossOverlay ~= false end,
                    set = function(_, v)
                        GetDB().enableHealthLossOverlay = v and true or false
                        AfterFeatureChange()
                    end,
                },
                enablePowerCostOverlay = {
                    type = "toggle",
                    name = "Power cost overlay",
                    order = 22,
                    width = "full",
                    get = function() return GetDB().enablePowerCostOverlay ~= false end,
                    set = function(_, v)
                        GetDB().enablePowerCostOverlay = v and true or false
                        AfterFeatureChange()
                    end,
                },
                enableMP5Overlay = {
                    type = "toggle",
                    name = "MP5 / mana tick overlay (player)",
                    order = 23,
                    width = "full",
                    get = function() return GetDB().enableMP5Overlay ~= false end,
                    set = function(_, v)
                        GetDB().enableMP5Overlay = v and true or false
                        AfterFeatureChange()
                    end,
                },
                swingTimerUnsupportedNote = {
                    type = "description",
                    name = "Weapon swing timer is unavailable on live post-Dragonflight retail and on Cataclysm / Mists Classic. Classic Era, Anniversary, Wrath, and Forever show the overlay on the player cast bar.\n",
                    order = 24.5,
                    width = "full",
                    fontSize = "small",
                    hidden = function() return IsSwingTimerClientSupported() end,
                },
                enableSwingTimer = {
                    type = "toggle",
                    name = "Weapon swing timer (player)",
                    order = 25,
                    width = "full",
                    hidden = function() return not IsSwingTimerClientSupported() end,
                    get = function() return GetDB().enableSwingTimer ~= false end,
                    set = function(_, v)
                        GetDB().enableSwingTimer = v and true or false
                        AfterFeatureChange()
                    end,
                },
                enableFlightPathTimers = {
                    type = "toggle",
                    name = "Flight path timers",
                    desc = "Show flight duration on taxi map tooltips and a progress bar on the player cast bar while flying. Uses bundled flight-time data with optional overrides after landing.",
                    order = 26,
                    width = "full",
                    get = function() return GetDB().enableFlightPathTimers ~= false end,
                    set = function(_, v)
                        GetDB().enableFlightPathTimers = v and true or false
                        AfterFeatureChange()
                    end,
                },
                enableFlightPathCastBar = {
                    type = "toggle",
                    name = "Flight path cast bar (player)",
                    desc = "Show in-flight progress on the player unit frame cast bar slot.",
                    order = 26.1,
                    width = "full",
                    disabled = function() return GetDB().enableFlightPathTimers == false end,
                    get = function() return GetDB().enableFlightPathCastBar ~= false end,
                    set = function(_, v)
                        GetDB().enableFlightPathCastBar = v and true or false
                        AfterFeatureChange()
                    end,
                },
                enableFlightPathTooltips = {
                    type = "toggle",
                    name = "Flight path taxi map tooltips",
                    desc = "Append estimated flight duration when hovering reachable destinations on the taxi map.",
                    order = 26.2,
                    width = "full",
                    disabled = function() return GetDB().enableFlightPathTimers == false end,
                    get = function() return GetDB().enableFlightPathTooltips ~= false end,
                    set = function(_, v)
                        GetDB().enableFlightPathTooltips = v and true or false
                        AfterFeatureChange()
                    end,
                },
                threatBarVisibility = {
                    type = "select",
                    name = "Threat bar visibility",
                    desc = THREAT_BAR_VISIBILITY_DESC,
                    order = 27,
                    width = "full",
                    values = THREAT_BAR_VISIBILITY_VALUES,
                    sorting = { "always", "group", "never" },
                    get = function()
                        return GetThreatBarVisibility()
                    end,
                    set = function(_, v)
                        SetThreatBarVisibility(v)
                    end,
                },
                showNumericThreat = {
                    type = "toggle",
                    name = "Show threat percentage",
                    desc = "Shows tank-relative threat % (100% = you have aggro) on the target/focus threat bar and on nameplates, plus your placement in the group.",
                    order = 27.5,
                    width = "full",
                    get = function()
                        local ThreatAPI = ns.Flux and ns.Flux.Threat
                        if ThreatAPI and ThreatAPI.ShowNumeric then
                            return ThreatAPI.ShowNumeric()
                        end
                        return true
                    end,
                    set = function(_, v)
                        local ThreatAPI = ns.Flux and ns.Flux.Threat
                        if ThreatAPI and ThreatAPI.SetShowNumeric then
                            ThreatAPI.SetShowNumeric(v)
                        end
                        if FluxUnitFrames_ApplyThreatBarOptionsFromDB then
                            FluxUnitFrames_ApplyThreatBarOptionsFromDB()
                        end
                        if FluxNamePlates_RefreshFromDB then
                            FluxNamePlates_RefreshFromDB()
                        end
                    end,
                },
                nameplateOptionsPointer = {
                    type = "description",
                    name = "Nameplate Progressive, Flash, Health Bar Color, and Threat warning are on the Nameplates page.\n",
                    order = 27.6,
                    fontSize = "small",
                    width = "full",
                },
            },
        },

        -- ----------------------------------------------------------------
        unitPlayer = {
            type = "group",
            name = "Player",
            order = 1,
            args = {
                playerShowPortrait = {
                    type = "toggle",
                    name = "Show portrait strip",
                    desc = "When off, only the bar column is shown and it stays centered at the bottom of the screen. When on, the side portrait strip is shown (3D vs flat is set under General -> Features). Applies immediately. Third-party addons that replace the portrait (e.g. BigDebuffs) get a layout refresh when this changes.",
                    order = 0.5,
                    width = "full",
                    get = function()
                        return GetDB().showPortraitPlayer ~= false
                    end,
                    set = function(_, v)
                        GetDB().showPortraitPlayer = v and true or false
                        AfterPortraitOptionsChange()
                    end,
                },
                playerWidth = {
                    type = "range",
                    name = "Width",
                    order = 1,
                    width = "full",
                    min = 150,
                    max = 600,
                    step = 1,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("player", "width")
                        end
                        fs.player = fs.player or {}
                        local raw = fs.player.width
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("player", "width")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.player = fs.player or {}
                        fs.player.width = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                playerHeight = {
                    type = "range",
                    name = "Height",
                    order = 2,
                    width = "full",
                    min = 40,
                    max = 200,
                    step = 1,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("player", "height")
                        end
                        fs.player = fs.player or {}
                        local raw = fs.player.height
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("player", "height")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.player = fs.player or {}
                        fs.player.height = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                playerHealthSplit = {
                    type = "range",
                    name = "Health / resource split %",
                    desc = "Share of the inner bar stack for health when only health + main resource are shown. Alternate power (third bar) still uses a fixed three-way split.",
                    order = 3,
                    width = "full",
                    min = 35,
                    max = 85,
                    step = 1,
                    get = function()
                        return HealthPartitionGetFor("player")
                    end,
                    set = function(_, val)
                        HealthPartitionSetFor("player", val)
                    end,
                },
            },
        },

        unitTarget = {
            type = "group",
            name = "Target",
            order = 2,
            args = {
                targetShowPortrait = {
                    type = "toggle",
                    name = "Show portrait strip",
                    desc = "When off, only the bar column is shown and it stays centered at the top of the screen. When on, the side portrait strip is shown (3D vs flat is under General -> Features). Applies immediately; BigDebuffs and similar mods receive a refresh hook.",
                    order = 0.5,
                    width = "full",
                    get = function()
                        return GetDB().showPortraitTarget ~= false
                    end,
                    set = function(_, v)
                        GetDB().showPortraitTarget = v and true or false
                        AfterPortraitOptionsChange()
                    end,
                },
                targetNoTargetPlaceholder = {
                    type = "toggle",
                    name = "Empty target placeholder",
                    desc = "When enabled, a subtle gray outline marks the target frame area while you have nothing targeted. Turn off to hide that box.",
                    order = 0.55,
                    width = "full",
                    get = function()
                        return GetDB().showTargetNoTargetPlaceholder ~= false
                    end,
                    set = function(_, v)
                        GetDB().showTargetNoTargetPlaceholder = v and true or false
                        AfterTargetPlaceholderChange()
                    end,
                },
                targetSizeFollowsPlayerNote = {
                    type = "description",
                    name = "Layout is set to side-by-side (Layout tab): target width and height match the Player tab - adjust size there.\n",
                    order = 0.58,
                    fontSize = "small",
                    width = "full",
                    hidden = function()
                        return not IsSideBySidePlayerTargetLayout()
                    end,
                },
                targetWidth = {
                    type = "range",
                    name = "Width",
                    order = 1,
                    width = "full",
                    min = 200,
                    max = 800,
                    step = 1,
                    hidden = function()
                        return IsSideBySidePlayerTargetLayout()
                    end,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("target", "width")
                        end
                        fs.target = fs.target or {}
                        local raw = fs.target.width
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("target", "width")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.target = fs.target or {}
                        fs.target.width = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                targetHeight = {
                    type = "range",
                    name = "Height",
                    order = 2,
                    width = "full",
                    min = 40,
                    max = 200,
                    step = 1,
                    hidden = function()
                        return IsSideBySidePlayerTargetLayout()
                    end,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("target", "height")
                        end
                        fs.target = fs.target or {}
                        local raw = fs.target.height
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("target", "height")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.target = fs.target or {}
                        fs.target.height = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                targetHealthSplit = {
                    type = "range",
                    name = "Health / resource split %",
                    desc = "Share of the inner bar stack for health when only health + main resource are shown.",
                    order = 3,
                    width = "full",
                    min = 35,
                    max = 85,
                    step = 1,
                    get = function()
                        return HealthPartitionGetFor("target")
                    end,
                    set = function(_, val)
                        HealthPartitionSetFor("target", val)
                    end,
                },
                targetAurasHeader = {
                    type = "header",
                    name = "Auras",
                    order = 3.5,
                },
                targetAuraBuffSize = {
                    type = "range",
                    name = "Buff icon size",
                    order = 4,
                    width = "full",
                    min = 14,
                    max = 56,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        return d.auraTarget.buffSize or 35
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        d.auraTarget.buffSize = v
                        AfterAuraOptionsChange()
                    end,
                },
                targetAuraDebuffSize = {
                    type = "range",
                    name = "Debuff icon size",
                    order = 5,
                    width = "full",
                    min = 14,
                    max = 56,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        return d.auraTarget.debuffSize or 35
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        d.auraTarget.debuffSize = v
                        AfterAuraOptionsChange()
                    end,
                },
                targetAuraLockOwnDebuffSize = {
                    type = "toggle",
                    name = "Lock own debuff size",
                    desc = "Keep your player/pet/vehicle debuffs at full boosted size (~1.38x). Other players' debuffs can shrink to fit the panel (Classic) or stay at the configured size (Midnight/Forever). When off, yours can shrink down to Own debuff min scale.",
                    order = 5.1,
                    width = "full",
                    get = function()
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        return d.auraTarget.lockOwnDebuffSize ~= false
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        d.auraTarget.lockOwnDebuffSize = v and true or false
                        AfterAuraOptionsChange()
                    end,
                },
                targetAuraOwnDebuffMinScale = {
                    type = "range",
                    name = "Own debuff min scale",
                    desc = "When lock is off, the smallest your own debuffs can get (100% = full boosted size, 50% = half of boosted). They stay larger than other players' icons while the panel is shrinking. Disabled while lock is on. On Midnight/Forever this sets own icon size directly (those frames do not fit-shrink).",
                    order = 5.2,
                    width = "full",
                    min = 50,
                    max = 100,
                    step = 5,
                    softMin = 50,
                    softMax = 100,
                    disabled = function()
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        return d.auraTarget.lockOwnDebuffSize ~= false
                    end,
                    get = function()
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        local s = tonumber(d.auraTarget.ownDebuffMinScale) or 0.75
                        return math.floor(s * 100 + 0.5)
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        d.auraTarget.ownDebuffMinScale = (tonumber(v) or 75) / 100
                        AfterAuraOptionsChange()
                    end,
                },
                targetAuraBuffSpacing = {
                    type = "range",
                    name = "Buff spacing",
                    order = 6,
                    width = "full",
                    min = 0,
                    max = 12,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        return d.auraTarget.buffSpacing or 2
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        d.auraTarget.buffSpacing = v
                        AfterAuraOptionsChange()
                    end,
                },
                targetAuraDebuffSpacing = {
                    type = "range",
                    name = "Debuff spacing",
                    order = 7,
                    width = "full",
                    min = 0,
                    max = 12,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        return d.auraTarget.debuffSpacing or 2
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        d.auraTarget.debuffSpacing = v
                        AfterAuraOptionsChange()
                    end,
                },
                targetAuraMaxBuffs = {
                    type = "range",
                    name = "Max buff icons",
                    desc = "Increasing above the previous cap rebuilds the buff panel once.",
                    order = 8,
                    width = "full",
                    min = 8,
                    max = 40,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        return d.auraTarget.maxBuffs or 32
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        d.auraTarget.maxBuffs = v
                        AfterAuraOptionsChange()
                    end,
                },
                targetAuraMaxDebuffs = {
                    type = "range",
                    name = "Max debuff icons",
                    desc = "Increasing above the previous cap rebuilds the debuff panel once.",
                    order = 9,
                    width = "full",
                    min = 4,
                    max = 24,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        return d.auraTarget.maxDebuffs or 16
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraTarget = d.auraTarget or {}
                        d.auraTarget.maxDebuffs = v
                        AfterAuraOptionsChange()
                    end,
                },
                targetThreatHeader = {
                    type = "header",
                    name = "Threat",
                    order = 10,
                },
                targetThreatBarVisibility = {
                    type = "select",
                    name = "Threat bar visibility",
                    desc = THREAT_BAR_VISIBILITY_DESC,
                    order = 10.5,
                    width = "full",
                    values = THREAT_BAR_VISIBILITY_VALUES,
                    sorting = { "always", "group", "never" },
                    get = function()
                        return GetThreatBarVisibility()
                    end,
                    set = function(_, v)
                        SetThreatBarVisibility(v)
                    end,
                },
                targetThreatBarPosition = {
                    type = "select",
                    name = "Threat bar position",
                    desc = "Portrait overlays the portrait when you have threat. Between reserves a strip between the frame chrome and auras. Left/Right are vertical strips for enemy NPCs only. In side-by-side Layout, Left is coerced to Right so the strip stays on the outer edge.",
                    order = 11,
                    width = "full",
                    values = {
                        portrait = "Portrait overlay",
                        between = "Between chrome and auras",
                        left = "Left (vertical)",
                        right = "Right (vertical)",
                    },
                    get = function()
                        local v = GetDB().threatBarPositionTarget
                        if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then
                            return "portrait"
                        end
                        return v
                    end,
                    set = function(_, v)
                        if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then
                            v = "portrait"
                        end
                        GetDB().threatBarPositionTarget = v
                        if FluxUnitFrames_ApplyThreatBarOptionsFromDB then
                            FluxUnitFrames_ApplyThreatBarOptionsFromDB()
                        end
                    end,
                },
            },
        },

        unitTargetOfTarget = {
            type = "group",
            name = "Target of target",
            order = 3,
            args = {
                totWidth = {
                    type = "range",
                    name = "Width",
                    order = 1,
                    width = "full",
                    min = 80,
                    max = 300,
                    step = 1,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("targettarget", "width")
                        end
                        fs.targettarget = fs.targettarget or {}
                        local raw = fs.targettarget.width
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("targettarget", "width")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.targettarget = fs.targettarget or {}
                        fs.targettarget.width = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                totHeight = {
                    type = "range",
                    name = "Height",
                    order = 2,
                    width = "full",
                    min = 30,
                    max = 120,
                    step = 1,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("targettarget", "height")
                        end
                        fs.targettarget = fs.targettarget or {}
                        local raw = fs.targettarget.height
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("targettarget", "height")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.targettarget = fs.targettarget or {}
                        fs.targettarget.height = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                totHealthSplit = {
                    type = "range",
                    name = "Health / resource split %",
                    desc = "Share of the inner bar stack for health when only health + main resource are shown.",
                    order = 3,
                    width = "full",
                    min = 35,
                    max = 85,
                    step = 1,
                    get = function()
                        return HealthPartitionGetFor("targettarget")
                    end,
                    set = function(_, val)
                        HealthPartitionSetFor("targettarget", val)
                    end,
                },
            },
        },

        unitFocus = {
            type = "group",
            name = "Focus",
            order = 4,
            hidden = function() return not HasFocusUnit() end,
            args = {
                focusShowPortrait = {
                    type = "toggle",
                    name = "Show portrait strip",
                    desc = "When off, only the bar column is shown (focus frame repositions from chat; focus target bar matches width). When on, the side portrait strip is shown (3D vs flat is under General -> Features). Applies immediately.",
                    order = 0.5,
                    width = "full",
                    get = function()
                        return GetDB().showPortraitFocus ~= false
                    end,
                    set = function(_, v)
                        GetDB().showPortraitFocus = v and true or false
                        AfterPortraitOptionsChange()
                    end,
                },
                focusWidth = {
                    type = "range",
                    name = "Width",
                    order = 1,
                    width = "full",
                    min = 80,
                    max = 250,
                    step = 1,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("focus", "width")
                        end
                        fs.focus = fs.focus or {}
                        local raw = fs.focus.width
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("focus", "width")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.focus = fs.focus or {}
                        fs.focus.width = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                focusHeight = {
                    type = "range",
                    name = "Height",
                    order = 2,
                    width = "full",
                    min = 30,
                    max = 120,
                    step = 1,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("focus", "height")
                        end
                        fs.focus = fs.focus or {}
                        local raw = fs.focus.height
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("focus", "height")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.focus = fs.focus or {}
                        fs.focus.height = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                focusHealthSplit = {
                    type = "range",
                    name = "Health / resource split %",
                    desc = "Share of the inner bar stack for health; also used for the focus target-of-target strip height.",
                    order = 3,
                    width = "full",
                    min = 35,
                    max = 85,
                    step = 1,
                    get = function()
                        return HealthPartitionGetFor("focus")
                    end,
                    set = function(_, val)
                        HealthPartitionSetFor("focus", val)
                    end,
                },
                focusAurasHeader = {
                    type = "header",
                    name = "Auras",
                    order = 3.5,
                },
                focusAuraBuffSize = {
                    type = "range",
                    name = "Buff icon size",
                    order = 4,
                    width = "full",
                    min = 14,
                    max = 56,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        return d.auraFocus.buffSize or 20
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        d.auraFocus.buffSize = v
                        AfterAuraOptionsChange()
                    end,
                },
                focusAuraDebuffSize = {
                    type = "range",
                    name = "Debuff icon size",
                    order = 5,
                    width = "full",
                    min = 14,
                    max = 56,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        return d.auraFocus.debuffSize or 20
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        d.auraFocus.debuffSize = v
                        AfterAuraOptionsChange()
                    end,
                },
                focusAuraLockOwnDebuffSize = {
                    type = "toggle",
                    name = "Lock own debuff size",
                    desc = "Keep your player/pet/vehicle debuffs at full boosted size (~1.38x). Other players' debuffs can shrink to fit the panel (Classic) or stay at the configured size (Midnight/Forever). When off, yours can shrink down to Own debuff min scale.",
                    order = 5.1,
                    width = "full",
                    get = function()
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        return d.auraFocus.lockOwnDebuffSize ~= false
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        d.auraFocus.lockOwnDebuffSize = v and true or false
                        AfterAuraOptionsChange()
                    end,
                },
                focusAuraOwnDebuffMinScale = {
                    type = "range",
                    name = "Own debuff min scale",
                    desc = "When lock is off, the smallest your own debuffs can get (100% = full boosted size, 50% = half of boosted). They stay larger than other players' icons while the panel is shrinking. Disabled while lock is on. On Midnight/Forever this sets own icon size directly (those frames do not fit-shrink).",
                    order = 5.2,
                    width = "full",
                    min = 50,
                    max = 100,
                    step = 5,
                    softMin = 50,
                    softMax = 100,
                    disabled = function()
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        return d.auraFocus.lockOwnDebuffSize ~= false
                    end,
                    get = function()
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        local s = tonumber(d.auraFocus.ownDebuffMinScale) or 0.75
                        return math.floor(s * 100 + 0.5)
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        d.auraFocus.ownDebuffMinScale = (tonumber(v) or 75) / 100
                        AfterAuraOptionsChange()
                    end,
                },
                focusAuraBuffSpacing = {
                    type = "range",
                    name = "Buff spacing",
                    order = 6,
                    width = "full",
                    min = 0,
                    max = 12,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        return d.auraFocus.buffSpacing or 2
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        d.auraFocus.buffSpacing = v
                        AfterAuraOptionsChange()
                    end,
                },
                focusAuraDebuffSpacing = {
                    type = "range",
                    name = "Debuff spacing",
                    order = 7,
                    width = "full",
                    min = 0,
                    max = 12,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        return d.auraFocus.debuffSpacing or 2
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        d.auraFocus.debuffSpacing = v
                        AfterAuraOptionsChange()
                    end,
                },
                focusAuraMaxBuffs = {
                    type = "range",
                    name = "Max buff icons",
                    desc = "Increasing above the previous cap rebuilds the buff panel once.",
                    order = 8,
                    width = "full",
                    min = 8,
                    max = 40,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        return d.auraFocus.maxBuffs or 32
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        d.auraFocus.maxBuffs = v
                        AfterAuraOptionsChange()
                    end,
                },
                focusAuraMaxDebuffs = {
                    type = "range",
                    name = "Max debuff icons",
                    desc = "Increasing above the previous cap rebuilds the debuff panel once.",
                    order = 9,
                    width = "full",
                    min = 4,
                    max = 24,
                    step = 1,
                    get = function()
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        return d.auraFocus.maxDebuffs or 16
                    end,
                    set = function(_, v)
                        local d = GetDB()
                        d.auraFocus = d.auraFocus or {}
                        d.auraFocus.maxDebuffs = v
                        AfterAuraOptionsChange()
                    end,
                },
                focusThreatHeader = {
                    type = "header",
                    name = "Threat",
                    order = 10,
                },
                focusThreatBarVisibility = {
                    type = "select",
                    name = "Threat bar visibility",
                    desc = THREAT_BAR_VISIBILITY_DESC,
                    order = 10.5,
                    width = "full",
                    values = THREAT_BAR_VISIBILITY_VALUES,
                    sorting = { "always", "group", "never" },
                    get = function()
                        return GetThreatBarVisibility()
                    end,
                    set = function(_, v)
                        SetThreatBarVisibility(v)
                    end,
                },
                focusThreatBarPosition = {
                    type = "select",
                    name = "Threat bar position",
                    desc = "Portrait overlays the portrait when you have threat. Between reserves a strip between the frame chrome and auras. Left/Right are vertical strips for enemy NPCs only.",
                    order = 11,
                    width = "full",
                    values = {
                        portrait = "Portrait overlay",
                        between = "Between chrome and auras",
                        left = "Left (vertical)",
                        right = "Right (vertical)",
                    },
                    get = function()
                        local v = GetDB().threatBarPositionFocus
                        if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then
                            return "portrait"
                        end
                        return v
                    end,
                    set = function(_, v)
                        if v ~= "between" and v ~= "left" and v ~= "right" and v ~= "portrait" then
                            v = "portrait"
                        end
                        GetDB().threatBarPositionFocus = v
                        if FluxUnitFrames_ApplyThreatBarOptionsFromDB then
                            FluxUnitFrames_ApplyThreatBarOptionsFromDB()
                        end
                    end,
                },
            },
        },

        unitPet = {
            type = "group",
            name = "Pet",
            order = 5,
            args = {
                petShowPortrait = {
                    type = "toggle",
                    name = "Show portrait strip",
                    desc = "When off, only the pet bar column is shown (no portrait strip). When on, the side portrait strip is shown (3D vs flat is under General -> Features). Applies immediately; the pet frame re-anchors to the player frame.",
                    order = 0.5,
                    width = "full",
                    get = function()
                        return GetDB().showPortraitPet ~= false
                    end,
                    set = function(_, v)
                        GetDB().showPortraitPet = v and true or false
                        AfterPortraitOptionsChange()
                    end,
                },
                petShowCastBar = {
                    type = "toggle",
                    name = "Show cast bar",
                    desc = "Overlay a cast/channel bar on the pet resource bar. Off by default.",
                    order = 0.55,
                    width = "full",
                    get = function()
                        return GetDB().showCastBarPet == true
                    end,
                    set = function(_, v)
                        GetDB().showCastBarPet = v and true or false
                        AfterFeatureChange()
                    end,
                },
                petShowTooltipAuras = {
                    type = "toggle",
                    name = "Show auras on mouseover",
                    desc = "When hovering the pet frame, show buff and debuff icons with cooldown countdown next to the unit tooltip.",
                    order = 0.6,
                    width = "full",
                    get = function()
                        return GetDB().showPetTooltipAuras ~= false
                    end,
                    set = function(_, v)
                        GetDB().showPetTooltipAuras = v and true or false
                    end,
                },
                petWidth = {
                    type = "range",
                    name = "Width",
                    order = 1,
                    width = "full",
                    min = 60,
                    max = 220,
                    step = 1,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("pet", "width")
                        end
                        fs.pet = fs.pet or {}
                        local raw = fs.pet.width
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("pet", "width")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.pet = fs.pet or {}
                        fs.pet.width = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                petHeight = {
                    type = "range",
                    name = "Height",
                    order = 2,
                    width = "full",
                    min = 30,
                    max = 120,
                    step = 1,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("pet", "height")
                        end
                        fs.pet = fs.pet or {}
                        local raw = fs.pet.height
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("pet", "height")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.pet = fs.pet or {}
                        fs.pet.height = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
                petHealthSplit = {
                    type = "range",
                    name = "Health / resource split %",
                    desc = "Share of the inner bar stack for health when only health + main resource are shown.",
                    order = 3,
                    width = "full",
                    min = 35,
                    max = 85,
                    step = 1,
                    get = function()
                        return HealthPartitionGetFor("pet")
                    end,
                    set = function(_, val)
                        HealthPartitionSetFor("pet", val)
                    end,
                },
            },
        },

        unitPetTarget = {
            type = "group",
            name = "Pet target",
            order = 6,
            args = {
                petTargetWidth = {
                    type = "range",
                    name = "Width",
                    desc = "Vertical health strip next to the pet frame; height always matches the pet frame.",
                    order = 1,
                    width = "full",
                    min = 12,
                    max = 48,
                    step = 1,
                    get = function()
                        local fs = FrameSizesBucket()
                        if not fs then
                            return DefaultDim("pettarget", "width")
                        end
                        fs.pettarget = fs.pettarget or {}
                        local raw = fs.pettarget.width
                        if raw ~= nil then
                            return FrameSizeStorageToEffective(raw)
                        end
                        return DefaultDim("pettarget", "width")
                    end,
                    set = function(_, v)
                        local fs = FrameSizesBucket()
                        if not fs then
                            return
                        end
                        fs.pettarget = fs.pettarget or {}
                        fs.pettarget.width = FrameSizeEffectiveToStorage(v)
                        AfterLayoutSizingChange()
                    end,
                },
            },
        },
    },
}
    AttachMergedFrameOptions(options)
    return options
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    if FluxOptions and FluxOptions.RegisterModuleOptions then
        FluxOptions:RegisterModuleOptions("unitframes", BuildUnitFrameOptions)
    end
end)

