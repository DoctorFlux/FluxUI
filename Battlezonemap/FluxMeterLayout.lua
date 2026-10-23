-- FluxMeterLayout.lua
-- Meter layout library, Details attribute/plugin catalog, Blizzard meter catalog, and standalone editor UI.

local addonName, addonTable = ...
local Flux = addonTable and addonTable.Flux or _G.Flux

FluxMeterLayout = FluxMeterLayout or {}

local FLUX_THREAT_PLUGIN = "DETAILS_PLUGIN_FLUX_THREAT"
local TINY_THREAT_PLUGIN = "DETAILS_PLUGIN_TINY_THREAT"
local FLUX_THREAT_ICON = "Interface\\Icons\\Ability_Druid_Cower"

local MAX_COLS = 3
local BLIZZARD_MAX_PANES = 3 -- Blizzard_DamageMeter MAX_DAMAGE_METER_SESSION_WINDOWS
local DETAILS_BUILTIN_COUNT = 11
local BLIZZARD_BUILTIN_COUNT = 6

local METER_TOPROW_MIN = 0.25
local METER_TOPROW_MAX = 0.75
local COL_FRAC_MIN = 0.10

local workingLayout = nil
local activeLayoutId = "builtin:1"
local userLayouts = {}
local loadedBackend = nil -- "Details" | "Blizzard" | nil — which SV set is in memory
local editorFrame = nil
local editorActive = false
local reembedTimer = nil
local liveGeomTimer = nil
local PREVIEW_PAD = 4

local function CancelableAfter(delay, callback)
    if C_Timer.NewTimer then return C_Timer.NewTimer(delay, callback) end
    local cancelled = false
    C_Timer.After(delay, function() if not cancelled then callback() end end)
    return { Cancel = function() cancelled = true end }
end

local LEGACY_TYPE_MAP = {
    damage = { kind = "attr", attribute = 1, subAttribute = 1 },
    healing = { kind = "attr", attribute = 2, subAttribute = 1 },
    interrupts = { kind = "attr", attribute = 4, subAttribute = 3 },
    dispels = { kind = "attr", attribute = 4, subAttribute = 4 },
    threat = { kind = "plugin", plugin = FLUX_THREAT_PLUGIN },
}

local SLOT_COLORS = {
    attr = {
        [1] = { 0.75, 0.22, 0.22, 0.95 },
        [2] = { 0.20, 0.65, 0.30, 0.95 },
        [3] = { 0.20, 0.55, 0.75, 0.95 },
        [4] = { 0.55, 0.30, 0.75, 0.95 },
        [5] = { 0.70, 0.55, 0.20, 0.95 },
    },
    plugin = { 0.85, 0.55, 0.12, 0.95 },
    blizzard = {
        damage = { 0.75, 0.22, 0.22, 0.95 },
        healing = { 0.20, 0.65, 0.30, 0.95 },
        actions = { 0.55, 0.30, 0.75, 0.95 },
    },
}

local DETAILS_BUILTIN_LABELS = {
    [1] = "Damage | Healing",
    [2] = "Threat|Damage, Dispels|Healing",
    [3] = "Interrupts|Damage, Dispels|Healing",
    [4] = "Damage, Interrupts|Healing",
    [5] = "Damage, Dispels|Healing",
    [6] = "Damage, Threat|Healing",
    [7] = "Threat|Damage, Healing",
    [8] = "Interrupts|Damage, Healing",
    [9] = "Damage only (full)",
    [10] = "Threat|Damage (full height)",
    [11] = "Interrupts|Damage (full height)",
}

local BLIZZARD_BUILTIN_LABELS = {
    [1] = "Damage | Healing",
    [2] = "Damage only (full)",
    [3] = "Interrupts|Damage, Healing",
    [4] = "Damage, Dispels|Healing",
    [5] = "Damage | Healing, Absorbs",
    [6] = "DamageTaken | Damage, Healing",
}

-- Compat: older callers read BUILTIN_LABELS directly (Details labels).
FluxMeterLayout.BUILTIN_LABELS = DETAILS_BUILTIN_LABELS

---------------------------------------------------------------------------
-- Backend detection: Details XOR Blizzard_DamageMeter (never both).
-- Blizzard_DamageMeter TOC is AllowLoadGameType standard (live) or
-- standard,camelot (Forever). Classic Era / Anniversary game types drop it
-- from the addon list, so probe existence instead of version flags.
---------------------------------------------------------------------------

local BLIZZARD_METER_ADDON = "Blizzard_DamageMeter"

local function AddOnAPI()
    local Flux = addonTable and addonTable.Flux
    return Flux and Flux.AddOn
end

local function IsNamedAddOnLoaded(name)
    local A = AddOnAPI()
    if A and A.IsLoaded then
        return A.IsLoaded(name) and true or false
    end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, name)
        return ok and loaded and true or false
    end
    if IsAddOnLoaded then
        local ok, loaded = pcall(IsAddOnLoaded, name)
        return ok and loaded and true or false
    end
    return false
end

local function IsNamedAddOnPresent(name)
    local A = AddOnAPI()
    if A and A.Exists then
        return A.Exists(name) and true or false
    end
    local getNum = (C_AddOns and C_AddOns.GetNumAddOns) or GetNumAddOns
    local getter = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
    if getNum and getter then
        local okN, n = pcall(getNum)
        if okN and type(n) == "number" and n > 0 then
            for i = 1, n do
                local ok, addonName = pcall(getter, i)
                if ok and addonName == name then
                    return true
                end
            end
            return false
        end
    end
    if C_AddOns and C_AddOns.DoesAddOnExist then
        local ok, exists = pcall(C_AddOns.DoesAddOnExist, name)
        return ok and exists and true or false
    end
    return false
end

local function IsDetailsAddonLoaded()
    if not IsNamedAddOnLoaded("Details") then
        return false
    end
    return type(_G.Details) == "table"
end

function FluxMeterLayout.IsDetailsAddonLoaded()
    return IsDetailsAddonLoaded()
end

local function HasDamageMeterCAPI()
    return C_DamageMeter ~= nil and type(C_DamageMeter.IsDamageMeterAvailable) == "function"
end

local function IsBlizzardDamageMeterFrame(frame)
    return type(frame) == "table" and frame.GetPrimarySessionWindow ~= nil
end

--- True when this client ships a usable Blizzard_DamageMeter (C API + listed UI).
function FluxMeterLayout.HasBlizzardDamageMeterClient()
    if not HasDamageMeterCAPI() then
        return false
    end
    if IsBlizzardDamageMeterFrame(_G.DamageMeter) then
        return true
    end
    if IsNamedAddOnLoaded(BLIZZARD_METER_ADDON) then
        return true
    end
    return IsNamedAddOnPresent(BLIZZARD_METER_ADDON)
end

--- Active meter backend for layout/options: "Details", "Blizzard", or nil.
-- Details wins when both exist so the Meter tab never hosts both.
function FluxMeterLayout.GetMeterBackend()
    if IsDetailsAddonLoaded() then
        return "Details"
    end
    if FluxMeterLayout.HasBlizzardDamageMeterClient() then
        return "Blizzard"
    end
    return nil
end

function FluxMeterLayout.IsBlizzardBackend()
    return FluxMeterLayout.GetMeterBackend() == "Blizzard"
end

function FluxMeterLayout.IsDetailsBackend()
    return FluxMeterLayout.GetMeterBackend() == "Details"
end

function FluxMeterLayout.HasMeterBackend()
    local b = FluxMeterLayout.GetMeterBackend()
    return b == "Details" or b == "Blizzard"
end

function FluxMeterLayout.GetMaxPanes()
    if FluxMeterLayout.IsBlizzardBackend() then
        return BLIZZARD_MAX_PANES
    end
    return MAX_COLS * 2
end

local function DefaultDamageMeterType()
    if Enum and Enum.DamageMeterType then
        return Enum.DamageMeterType.DamageDone
    end
    return 0
end

local function DefaultHealingMeterType()
    if Enum and Enum.DamageMeterType then
        return Enum.DamageMeterType.HealingDone
    end
    return 2
end

local function BlizzardSlot(damageMeterType)
    return { kind = "blizzard", damageMeterType = damageMeterType }
end

local function BlizzardTypeCategory(damageMeterType)
    local T = Enum and Enum.DamageMeterType
    if not T then return "damage" end
    if damageMeterType == T.HealingDone or damageMeterType == T.Hps or damageMeterType == T.Absorbs then
        return "healing"
    end
    if damageMeterType == T.Interrupts or damageMeterType == T.Dispels or damageMeterType == T.Deaths then
        return "actions"
    end
    return "damage"
end

local function BlizzardTypeName(damageMeterType)
    local T = Enum and Enum.DamageMeterType
    if not T then return "Meter" end
    local names = {
        [T.DamageDone] = (DAMAGE_METER_TYPE_DAMAGE_DONE or "Damage"),
        [T.Dps] = (DAMAGE_METER_TYPE_DPS or "DPS"),
        [T.HealingDone] = (DAMAGE_METER_TYPE_HEALING_DONE or "Healing"),
        [T.Hps] = (DAMAGE_METER_TYPE_HPS or "HPS"),
        [T.Absorbs] = (DAMAGE_METER_TYPE_ABSORBS or "Absorbs"),
        [T.Interrupts] = (DAMAGE_METER_TYPE_INTERRUPTS or "Interrupts"),
        [T.Dispels] = (DAMAGE_METER_TYPE_DISPELS or "Dispels"),
        [T.DamageTaken] = (DAMAGE_METER_TYPE_DAMAGE_TAKEN or "Damage Taken"),
        [T.AvoidableDamageTaken] = (DAMAGE_METER_TYPE_AVOIDABLE_DAMAGE_TAKEN or "Avoidable DT"),
        [T.Deaths] = (DAMAGE_METER_TYPE_DEATHS or "Deaths"),
        [T.EnemyDamageTaken] = (DAMAGE_METER_TYPE_ENEMY_DAMAGE_TAKEN or "Enemy DT"),
    }
    return names[damageMeterType] or ("Type " .. tostring(damageMeterType))
end

local function BlizzardTypeIcon(damageMeterType)
    local T = Enum and Enum.DamageMeterType
    if not T then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    local icons = {
        [T.DamageDone] = "Interface\\Icons\\Ability_DualWield",
        [T.Dps] = "Interface\\Icons\\Ability_Warrior_InnerRage",
        [T.HealingDone] = "Interface\\Icons\\Spell_Holy_FlashHeal",
        [T.Hps] = "Interface\\Icons\\Spell_Holy_Renew",
        [T.Absorbs] = "Interface\\Icons\\Spell_Holy_PowerWordShield",
        [T.Interrupts] = "Interface\\Icons\\Ability_Kick",
        [T.Dispels] = "Interface\\Icons\\Spell_Holy_DispelMagic",
        [T.DamageTaken] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
        [T.AvoidableDamageTaken] = "Interface\\Icons\\Spell_Fire_Fireball02",
        [T.Deaths] = "Interface\\Icons\\Ability_Rogue_FeignDeath",
        [T.EnemyDamageTaken] = "Interface\\Icons\\Ability_Creature_Disease_02",
    }
    return icons[damageMeterType] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function BlizzardBuiltinPresetToLayout(presetId)
    local T = Enum and Enum.DamageMeterType
    if not T then
        return {
            name = "Damage | Healing",
            topSlots = { BlizzardSlot(0) },
            bottomSlots = { BlizzardSlot(2) },
            topColFracs = { 1 },
            bottomColFracs = { 1 },
            topRowFrac = 0.60,
        }
    end
    local presets = {
        [1] = {
            name = BLIZZARD_BUILTIN_LABELS[1],
            topSlots = { BlizzardSlot(T.DamageDone) },
            bottomSlots = { BlizzardSlot(T.HealingDone) },
            topColFracs = { 1 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
        },
        [2] = {
            name = BLIZZARD_BUILTIN_LABELS[2],
            topSlots = { BlizzardSlot(T.DamageDone) },
            bottomSlots = {},
            topColFracs = { 1 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
        },
        [3] = {
            name = BLIZZARD_BUILTIN_LABELS[3],
            topSlots = { BlizzardSlot(T.Interrupts), BlizzardSlot(T.DamageDone) },
            bottomSlots = { BlizzardSlot(T.HealingDone) },
            topColFracs = { 0.45, 0.55 }, bottomColFracs = { 1 }, topRowFrac = 0.60,
        },
        [4] = {
            name = BLIZZARD_BUILTIN_LABELS[4],
            topSlots = { BlizzardSlot(T.DamageDone) },
            bottomSlots = { BlizzardSlot(T.Dispels), BlizzardSlot(T.HealingDone) },
            topColFracs = { 1 }, bottomColFracs = { 0.45, 0.55 }, topRowFrac = 0.60,
        },
        [5] = {
            name = BLIZZARD_BUILTIN_LABELS[5],
            topSlots = { BlizzardSlot(T.DamageDone) },
            bottomSlots = { BlizzardSlot(T.HealingDone), BlizzardSlot(T.Absorbs) },
            topColFracs = { 1 }, bottomColFracs = { 0.55, 0.45 }, topRowFrac = 0.60,
        },
        [6] = {
            name = BLIZZARD_BUILTIN_LABELS[6],
            topSlots = { BlizzardSlot(T.DamageTaken) },
            bottomSlots = { BlizzardSlot(T.DamageDone), BlizzardSlot(T.HealingDone) },
            topColFracs = { 1 }, bottomColFracs = { 0.50, 0.50 }, topRowFrac = 0.40,
        },
    }
    local p = presets[presetId] or presets[1]
    return p
end

function FluxMeterLayout.GetBuiltinLabels()
    if FluxMeterLayout.IsBlizzardBackend() then
        return BLIZZARD_BUILTIN_LABELS
    end
    return DETAILS_BUILTIN_LABELS
end

local function DeepCopySlot(s)
    local defaultBlizzard = function()
        return BlizzardSlot(DefaultDamageMeterType())
    end
    local defaultDetails = function()
        return { kind = "attr", attribute = 1, subAttribute = 1 }
    end
    if not s then
        return FluxMeterLayout.IsBlizzardBackend() and defaultBlizzard() or defaultDetails()
    end
    if type(s) == "string" then
        local m = LEGACY_TYPE_MAP[s]
        if m then
            return { kind = m.kind, attribute = m.attribute, subAttribute = m.subAttribute, plugin = m.plugin }
        end
        return FluxMeterLayout.IsBlizzardBackend() and defaultBlizzard() or defaultDetails()
    end
    if s.type and not s.kind then
        local m = LEGACY_TYPE_MAP[s.type]
        if m then
            return { kind = m.kind, attribute = m.attribute, subAttribute = m.subAttribute, plugin = m.plugin }
        end
    end
    if s.kind == "blizzard" then
        local t = tonumber(s.damageMeterType)
        if t == nil then t = DefaultDamageMeterType() end
        return BlizzardSlot(t)
    end
    if s.kind == "plugin" then
        return { kind = "plugin", plugin = s.plugin or FLUX_THREAT_PLUGIN }
    end
    return {
        kind = "attr",
        attribute = tonumber(s.attribute) or 1,
        subAttribute = tonumber(s.subAttribute) or 1,
    }
end

local function EqualColFracs(n)
    n = math.max(1, math.min(MAX_COLS, n or 1))
    local f, each = {}, 1 / n
    for i = 1, n do f[i] = each end
    return f
end

local function NormalizeColFracs(fracs, n)
    n = math.max(1, math.min(MAX_COLS, n or 1))
    if type(fracs) ~= "table" or #fracs ~= n then
        return EqualColFracs(n)
    end
    local out, sum = {}, 0
    for i = 1, n do
        local v = tonumber(fracs[i]) or 0
        if v < COL_FRAC_MIN then v = COL_FRAC_MIN end
        out[i] = v
        sum = sum + v
    end
    if sum <= 0 then return EqualColFracs(n) end
    for i = 1, n do out[i] = out[i] / sum end
    return out
end

local function ClampTopRowFrac(v)
    v = tonumber(v) or 0.60
    if v < METER_TOPROW_MIN then v = METER_TOPROW_MIN end
    if v > METER_TOPROW_MAX then v = METER_TOPROW_MAX end
    return v
end

local function NormalizeSlots(list)
    local out = {}
    if type(list) ~= "table" then return out end
    for i = 1, math.min(MAX_COLS, #list) do
        out[i] = DeepCopySlot(list[i])
    end
    return out
end

local function CopyLayout(src)
    if not src then return nil end
    local top = NormalizeSlots(src.topSlots)
    local bot = NormalizeSlots(src.bottomSlots)
    if #top < 1 and #bot < 1 then
        top = { DeepCopySlot({ kind = "attr", attribute = 1, subAttribute = 1 }) }
    end
    -- Derive col fracs from legacy leftColFrac* when missing
    local topFracs = src.topColFracs
    if (not topFracs or #topFracs ~= #top) and src.leftColFracTop and #top == 2 then
        topFracs = { src.leftColFracTop, 1 - src.leftColFracTop }
    end
    local botFracs = src.bottomColFracs
    if (not botFracs or #botFracs ~= math.max(1, #bot)) and src.leftColFracBottom and #bot == 2 then
        botFracs = { src.leftColFracBottom, 1 - src.leftColFracBottom }
    end
    -- Legacy widthFrac on slots
    if (not topFracs or #topFracs ~= #top) and #top >= 2 and top[1].widthFrac then
        topFracs = {}
        for i = 1, #top do topFracs[i] = tonumber(src.topSlots[i].widthFrac) or (1 / #top) end
    end
    if (not botFracs or #botFracs ~= math.max(1, #bot)) and #bot >= 2 and bot[1].widthFrac then
        botFracs = {}
        for i = 1, #bot do botFracs[i] = tonumber(src.bottomSlots[i].widthFrac) or (1 / #bot) end
    end
    return {
        id = src.id,
        name = src.name or "Layout",
        topSlots = top,
        bottomSlots = bot,
        topColFracs = NormalizeColFracs(topFracs, #top),
        bottomColFracs = NormalizeColFracs(botFracs, math.max(1, #bot)),
        topRowFrac = ClampTopRowFrac(src.topRowFrac),
    }
end

local function NewBlankLayout(name)
    if FluxMeterLayout.IsBlizzardBackend() then
        return CopyLayout({
            name = name or "New Layout",
            topSlots = { BlizzardSlot(DefaultDamageMeterType()) },
            bottomSlots = { BlizzardSlot(DefaultHealingMeterType()) },
            topColFracs = { 1 },
            bottomColFracs = { 1 },
            topRowFrac = 0.60,
        })
    end
    return CopyLayout({
        name = name or "New Layout",
        topSlots = { { kind = "attr", attribute = 1, subAttribute = 1 } },
        bottomSlots = { { kind = "attr", attribute = 2, subAttribute = 1 } },
        topColFracs = { 1 },
        bottomColFracs = { 1 },
        topRowFrac = 0.60,
    })
end

local function ClampLayoutToMaxPanes(layout)
    if not layout or not FluxMeterLayout.IsBlizzardBackend() then return layout end
    local maxPanes = BLIZZARD_MAX_PANES
    local top = layout.topSlots or {}
    local bot = layout.bottomSlots or {}
    while #top + #bot > maxPanes and #bot > 0 do
        table.remove(bot)
    end
    while #top + #bot > maxPanes and #top > 1 do
        table.remove(top)
    end
    layout.topSlots = top
    layout.bottomSlots = bot
    layout.topColFracs = NormalizeColFracs(layout.topColFracs, #top)
    layout.bottomColFracs = NormalizeColFracs(layout.bottomColFracs, math.max(1, #bot))
    return layout
end

local function BuiltinPresetToLayout(presetId)
    if FluxMeterLayout.IsBlizzardBackend() then
        presetId = math.max(1, math.min(BLIZZARD_BUILTIN_COUNT, tonumber(presetId) or 1))
        local layout = CopyLayout(BlizzardBuiltinPresetToLayout(presetId))
        layout.name = BLIZZARD_BUILTIN_LABELS[presetId] or ("Preset " .. presetId)
        layout.id = "builtin:" .. presetId
        return ClampLayoutToMaxPanes(layout)
    end
    if not FluxDetails or not FluxDetails.CopyLayoutPreset then
        return NewBlankLayout("Preset " .. tostring(presetId))
    end
    local p = FluxDetails:CopyLayoutPreset(presetId)
    if not p then return NewBlankLayout("Preset " .. tostring(presetId)) end
    local layout = CopyLayout(p)
    layout.name = DETAILS_BUILTIN_LABELS[presetId] or ("Preset " .. presetId)
    layout.id = "builtin:" .. presetId
    return layout
end

local function EnsureCharVars()
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    return _FluxUI_CharSavedVars
end

local function SaveLibrary()
    local sv = EnsureCharVars()
    local serial = {}
    for _, lay in ipairs(userLayouts) do
        local c = CopyLayout(lay)
        c.id = lay.id
        c.name = lay.name
        serial[#serial + 1] = c
    end
    if FluxMeterLayout.IsBlizzardBackend() then
        sv.fluxWindowBlizzardMeterLayouts = serial
        sv.fluxWindowBlizzardMeterActiveLayoutId = activeLayoutId
    else
        sv.fluxWindowMeterLayouts = serial
        sv.fluxWindowMeterActiveLayoutId = activeLayoutId
        sv.fluxWindowMeterTopSlots = nil
        sv.fluxWindowMeterBottomSlots = nil
        sv.fluxWindowMeterLeftColTop = nil
        sv.fluxWindowMeterLeftColBottom = nil
        sv.fluxWindowMeterTopRowPct = nil
    end
    loadedBackend = FluxMeterLayout.GetMeterBackend()
end

local function MigrateLegacyIfNeeded(sv)
    if type(sv.fluxWindowMeterLayouts) == "table" then return end
    local topCsv = sv.fluxWindowMeterTopSlots
    local botCsv = sv.fluxWindowMeterBottomSlots
    if topCsv == nil and botCsv == nil and not sv.fluxWindowMeterPresetIndex then
        return
    end

    local function decodeCsv(str, fallback)
        if type(str) ~= "string" or str == "" then
            return fallback
        end
        local out = {}
        for part in string.gmatch(str, "[^,]+") do
            if #out < MAX_COLS then
                out[#out + 1] = DeepCopySlot(part)
            end
        end
        return (#out > 0) and out or fallback
    end

    local top = decodeCsv(topCsv, { DeepCopySlot("damage") })
    local bot
    if botCsv == "" then
        bot = {}
    else
        bot = decodeCsv(botCsv, { DeepCopySlot("healing") })
    end

    local leftTop = (sv.fluxWindowMeterLeftColTop or 45) / 100
    local leftBot = (sv.fluxWindowMeterLeftColBottom or 45) / 100
    local topFracs = EqualColFracs(#top)
    if #top == 2 then topFracs = { leftTop, 1 - leftTop } end
    local botFracs = EqualColFracs(math.max(1, #bot))
    if #bot == 2 then botFracs = { leftBot, 1 - leftBot } end

    local migrated = CopyLayout({
        name = "Migrated",
        topSlots = top,
        bottomSlots = bot,
        topColFracs = topFracs,
        bottomColFracs = botFracs,
        topRowFrac = (sv.fluxWindowMeterTopRowPct or 60) / 100,
    })
    migrated.id = "user:1"
    userLayouts = { migrated }
    activeLayoutId = "user:1"
    workingLayout = CopyLayout(migrated)
    SaveLibrary()
end

local function LoadLibrary()
    local backend = FluxMeterLayout.GetMeterBackend()
    if loadedBackend == backend and workingLayout then
        return
    end

    local sv = EnsureCharVars()
    if backend ~= "Blizzard" then
        MigrateLegacyIfNeeded(sv)
    end

    userLayouts = {}
    local layoutList
    local activeIdKey
    if backend == "Blizzard" then
        layoutList = sv.fluxWindowBlizzardMeterLayouts
        activeIdKey = "fluxWindowBlizzardMeterActiveLayoutId"
    else
        layoutList = sv.fluxWindowMeterLayouts
        activeIdKey = "fluxWindowMeterActiveLayoutId"
    end

    if type(layoutList) == "table" then
        for i, lay in ipairs(layoutList) do
            local c = CopyLayout(lay)
            c = ClampLayoutToMaxPanes(c)
            c.id = lay.id or ("user:" .. i)
            c.name = lay.name or ("Layout " .. i)
            userLayouts[#userLayouts + 1] = c
        end
    end

    activeLayoutId = sv[activeIdKey] or "builtin:1"
    if type(activeLayoutId) ~= "string" then activeLayoutId = "builtin:1" end

    local builtinMax = (backend == "Blizzard") and BLIZZARD_BUILTIN_COUNT or DETAILS_BUILTIN_COUNT

    if activeLayoutId:match("^user:") then
        local found = false
        for _, lay in ipairs(userLayouts) do
            if lay.id == activeLayoutId then
                workingLayout = ClampLayoutToMaxPanes(CopyLayout(lay))
                found = true
                break
            end
        end
        if not found then
            activeLayoutId = "builtin:1"
            workingLayout = BuiltinPresetToLayout(1)
        end
    else
        local n = tonumber(activeLayoutId:match("^builtin:(%d+)$")) or 1
        if backend ~= "Blizzard" then
            n = tonumber(activeLayoutId:match("^builtin:(%d+)$")) or sv.fluxWindowMeterPresetIndex or 1
        end
        n = math.max(1, math.min(builtinMax, n))
        workingLayout = BuiltinPresetToLayout(n)
        activeLayoutId = "builtin:" .. n
    end
    loadedBackend = backend
end

local function NextUserId()
    local maxN = 0
    for _, lay in ipairs(userLayouts) do
        local n = tonumber((lay.id or ""):match("^user:(%d+)$"))
        if n and n > maxN then maxN = n end
    end
    return "user:" .. (maxN + 1)
end

function FluxMeterLayout.NormalizeSlot(slot)
    return DeepCopySlot(slot)
end

function FluxMeterLayout.NormalizeColFracs(fracs, n)
    return NormalizeColFracs(fracs, n)
end

function FluxMeterLayout.CopyLayout(src)
    return CopyLayout(src)
end

function FluxMeterLayout.GetWorkingLayout()
    LoadLibrary()
    return CopyLayout(workingLayout)
end

function FluxMeterLayout.GetActiveLayoutId()
    LoadLibrary()
    return activeLayoutId
end

function FluxMeterLayout.GetUserLayouts()
    LoadLibrary()
    return userLayouts
end

function FluxMeterLayout.GetBuiltinCount()
    if FluxMeterLayout.IsBlizzardBackend() then
        return BLIZZARD_BUILTIN_COUNT
    end
    return DETAILS_BUILTIN_COUNT
end

function FluxMeterLayout.ApplyBuiltin(presetId)
    LoadLibrary()
    local maxN = FluxMeterLayout.GetBuiltinCount()
    presetId = math.max(1, math.min(maxN, tonumber(presetId) or 1))
    workingLayout = BuiltinPresetToLayout(presetId)
    activeLayoutId = "builtin:" .. presetId
    SaveLibrary()
    return workingLayout
end

function FluxMeterLayout.LoadUser(layoutId)
    for _, lay in ipairs(userLayouts) do
        if lay.id == layoutId then
            workingLayout = CopyLayout(lay)
            activeLayoutId = layoutId
            SaveLibrary()
            return workingLayout
        end
    end
    return nil
end

function FluxMeterLayout.SaveWorkingAsNew(name)
    local lay = CopyLayout(workingLayout)
    lay.id = NextUserId()
    lay.name = name or ("Layout " .. (#userLayouts + 1))
    userLayouts[#userLayouts + 1] = lay
    workingLayout = CopyLayout(lay)
    activeLayoutId = lay.id
    SaveLibrary()
    return lay
end

function FluxMeterLayout.SaveWorkingOverActive()
    if not activeLayoutId or not activeLayoutId:match("^user:") then
        return FluxMeterLayout.SaveWorkingAsNew(workingLayout and workingLayout.name or "Layout")
    end
    for i, lay in ipairs(userLayouts) do
        if lay.id == activeLayoutId then
            local updated = CopyLayout(workingLayout)
            updated.id = lay.id
            updated.name = lay.name
            userLayouts[i] = updated
            workingLayout = CopyLayout(updated)
            SaveLibrary()
            return updated
        end
    end
    return FluxMeterLayout.SaveWorkingAsNew(workingLayout and workingLayout.name or "Layout")
end

function FluxMeterLayout.RenameActive(name)
    if not activeLayoutId or not activeLayoutId:match("^user:") then return false end
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return false end
    for _, lay in ipairs(userLayouts) do
        if lay.id == activeLayoutId then
            lay.name = name
            if workingLayout then workingLayout.name = name end
            SaveLibrary()
            return true
        end
    end
    return false
end

function FluxMeterLayout.DeleteActive()
    if not activeLayoutId or not activeLayoutId:match("^user:") then return false end
    for i, lay in ipairs(userLayouts) do
        if lay.id == activeLayoutId then
            table.remove(userLayouts, i)
            activeLayoutId = "builtin:1"
            workingLayout = BuiltinPresetToLayout(1)
            SaveLibrary()
            return true
        end
    end
    return false
end

function FluxMeterLayout.SetTopColCount(n)
    if not workingLayout then return end
    n = math.max(1, math.min(MAX_COLS, n or 1))
    if FluxMeterLayout.IsBlizzardBackend() then
        local botN = #(workingLayout.bottomSlots or {})
        local maxTop = math.max(1, BLIZZARD_MAX_PANES - botN)
        n = math.min(n, maxTop)
    end
    local slots = workingLayout.topSlots or {}
    local defaultSlot = FluxMeterLayout.IsBlizzardBackend()
        and BlizzardSlot(DefaultDamageMeterType())
        or { kind = "attr", attribute = 1, subAttribute = 1 }
    while #slots < n do
        slots[#slots + 1] = DeepCopySlot(defaultSlot)
    end
    while #slots > n do table.remove(slots) end
    workingLayout.topSlots = slots
    workingLayout.topColFracs = EqualColFracs(n)
end

function FluxMeterLayout.SetBottomColCount(n)
    if not workingLayout then return end
    n = math.max(0, math.min(MAX_COLS, n or 0))
    if FluxMeterLayout.IsBlizzardBackend() then
        local topN = #(workingLayout.topSlots or {})
        local maxBot = math.max(0, BLIZZARD_MAX_PANES - topN)
        n = math.min(n, maxBot)
    end
    local slots = workingLayout.bottomSlots or {}
    if n == 0 then
        workingLayout.bottomSlots = {}
        workingLayout.bottomColFracs = { 1 }
        return
    end
    local defaultSlot = FluxMeterLayout.IsBlizzardBackend()
        and BlizzardSlot(DefaultHealingMeterType())
        or { kind = "attr", attribute = 2, subAttribute = 1 }
    while #slots < n do
        slots[#slots + 1] = DeepCopySlot(defaultSlot)
    end
    while #slots > n do table.remove(slots) end
    workingLayout.bottomSlots = slots
    workingLayout.bottomColFracs = EqualColFracs(n)
end

function FluxMeterLayout.CanSetTopColCount(n)
    n = tonumber(n) or 1
    if n < 1 or n > MAX_COLS then return false end
    if not FluxMeterLayout.IsBlizzardBackend() then return true end
    LoadLibrary()
    local botN = workingLayout and #(workingLayout.bottomSlots or {}) or 0
    return n + botN <= BLIZZARD_MAX_PANES
end

function FluxMeterLayout.CanSetBottomColCount(n)
    n = tonumber(n) or 0
    if n < 0 or n > MAX_COLS then return false end
    if not FluxMeterLayout.IsBlizzardBackend() then return true end
    LoadLibrary()
    local topN = workingLayout and #(workingLayout.topSlots or {}) or 1
    return n + topN <= BLIZZARD_MAX_PANES
end

function FluxMeterLayout.SetSlot(row, index, slot)
    if not workingLayout then return end
    local list = (row == "top") and workingLayout.topSlots or workingLayout.bottomSlots
    if not list or index < 1 or index > #list then return end
    local s = DeepCopySlot(slot)
    if s.kind == "plugin" and s.plugin then
        local function scrub(arr)
            for i = 1, #arr do
                if arr[i].kind == "plugin" and arr[i].plugin == s.plugin then
                    arr[i] = DeepCopySlot({ kind = "attr", attribute = 1, subAttribute = 1 })
                end
            end
        end
        scrub(workingLayout.topSlots or {})
        scrub(workingLayout.bottomSlots or {})
    end
    list[index] = s
end

function FluxMeterLayout.SetTopRowFrac(frac)
    if not workingLayout then return end
    workingLayout.topRowFrac = ClampTopRowFrac(frac)
end

function FluxMeterLayout.SetColFracs(row, fracs)
    if not workingLayout then return end
    local n = (row == "top") and #(workingLayout.topSlots or {}) or #(workingLayout.bottomSlots or {})
    if n < 1 then return end
    local norm = NormalizeColFracs(fracs, n)
    if row == "top" then
        workingLayout.topColFracs = norm
    else
        workingLayout.bottomColFracs = norm
    end
end

local function AttrGroupLabel(attr)
    local D = _G.Details
    if D and D.atributos and D.atributos.lista and D.atributos.lista[attr] then
        return D.atributos.lista[attr]
    end
    return ({ "Damage", "Healing", "Resources", "Miscellaneous", "Scripts" })[attr] or ("Attr " .. attr)
end

local function SubAttrName(attr, sub)
    local D = _G.Details
    if D and D.GetSubAttributeName then
        local ok, name = pcall(function() return D:GetSubAttributeName(attr, sub) end)
        if ok and name and name ~= "" then return name end
    end
    if D and D.sub_atributos and D.sub_atributos[attr] and D.sub_atributos[attr].lista then
        return D.sub_atributos[attr].lista[sub] or ("Sub " .. sub)
    end
    return "Sub " .. tostring(sub)
end

--- Returns texturePath, left, right, top, bottom (0-1 coords) for a slot icon.
function FluxMeterLayout.SlotIcon(slot)
    slot = DeepCopySlot(slot)
    if slot.kind == "blizzard" then
        return BlizzardTypeIcon(slot.damageMeterType), 0, 1, 0, 1
    end
    if slot.kind == "plugin" then
        local icon = FLUX_THREAT_ICON
        if slot.plugin == FLUX_THREAT_PLUGIN then
            return icon, 0, 1, 0, 1
        end
        local D = _G.Details
        if D and D.RaidTables and D.RaidTables.NameTable and D.RaidTables.NameTable[slot.plugin] then
            local obj = D.RaidTables.NameTable[slot.plugin]
            if type(obj) == "table" and obj.icon then
                return obj.icon, 0, 1, 0, 1
            end
        end
        local p = _G[slot.plugin or ""]
        if type(p) == "table" and p.icon then
            return p.icon, 0, 1, 0, 1
        end
        return "Interface\\Icons\\INV_Misc_QuestionMark", 0, 1, 0, 1
    end

    local attr = slot.attribute or 1
    local sub = slot.subAttribute or 1
    if attr == 5 then
        return "Interface\\Icons\\INV_Misc_Note_01", 0, 1, 0, 1
    end
    local D = _G.Details
    if D and D.sub_atributos and D.sub_atributos[attr] and D.sub_atributos[attr].icones then
        local entry = D.sub_atributos[attr].icones[sub]
        if type(entry) == "table" then
            local path = entry[1]
            local coords = entry[2] or { 0, 1, 0, 1 }
            return path, coords[1] or 0, coords[2] or 1, coords[3] or 0, coords[4] or 1
        end
    end
    local fallback = {
        [1] = "Interface\\Icons\\Ability_DualWield",
        [2] = "Interface\\Icons\\Spell_Holy_FlashHeal",
        [3] = "Interface\\Icons\\Spell_Nature_Lightning",
        [4] = "Interface\\Icons\\Ability_Warrior_Sunder",
    }
    return fallback[attr] or "Interface\\Icons\\INV_Misc_QuestionMark", 0, 1, 0, 1
end

local function ApplyIconToTexture(tex, slot, size)
    if not tex then return end
    local path, l, r, t, b = FluxMeterLayout.SlotIcon(slot)
    tex:SetTexture(path)
    tex:SetTexCoord(l, r, t, b)
    if size then
        tex:SetSize(size, size)
    end
    tex:Show()
end

local function BuildBlizzardCatalog()
    local T = Enum and Enum.DamageMeterType
    if not T then return {} end

    local function itemsFor(types)
        local items = {}
        for _, meterType in ipairs(types) do
            local slot = BlizzardSlot(meterType)
            items[#items + 1] = {
                label = BlizzardTypeName(meterType),
                slot = slot,
                icon = BlizzardTypeIcon(meterType),
                coords = { 0, 1, 0, 1 },
            }
        end
        return items
    end

    local damageName = DAMAGE_METER_CATEGORY_DAMAGE or "Damage"
    local healingName = DAMAGE_METER_CATEGORY_HEALING or "Healing"
    local actionsName = DAMAGE_METER_CATEGORY_ACTIONS or "Actions"

    return {
        {
            label = damageName,
            icon = "Interface\\Icons\\Ability_DualWield",
            items = itemsFor({
                T.DamageDone, T.Dps, T.DamageTaken, T.AvoidableDamageTaken, T.EnemyDamageTaken,
            }),
        },
        {
            label = healingName,
            icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
            -- Absorbs is in the API/enum even though Blizzard's own dropdown omits it.
            items = itemsFor({ T.HealingDone, T.Hps, T.Absorbs }),
        },
        {
            label = actionsName,
            icon = "Interface\\Icons\\Ability_Kick",
            items = itemsFor({ T.Interrupts, T.Dispels, T.Deaths }),
        },
    }
end

function FluxMeterLayout.BuildCatalog()
    if FluxMeterLayout.IsBlizzardBackend() then
        return BuildBlizzardCatalog()
    end

    local groups = {}
    local D = _G.Details

    local groupIcons = {
        [1] = "Interface\\Icons\\Ability_DualWield",
        [2] = "Interface\\Icons\\Spell_Holy_FlashHeal",
        [3] = "Interface\\Icons\\Spell_Nature_Lightning",
        [4] = "Interface\\Icons\\Ability_Warrior_Sunder",
    }

    for attr = 1, 4 do
        local items = {}
        local count = ({ [1] = 9, [2] = 8, [3] = 6, [4] = 8 })[attr] or 8
        if D and D.atributos and type(D.atributos[attr]) == "number" then
            count = D.atributos[attr]
        end
        for sub = 1, count do
            local slot = { kind = "attr", attribute = attr, subAttribute = sub }
            local path, l, r, t, b = FluxMeterLayout.SlotIcon(slot)
            items[#items + 1] = {
                label = SubAttrName(attr, sub),
                slot = slot,
                icon = path,
                coords = { l, r, t, b },
            }
        end
        groups[#groups + 1] = {
            label = AttrGroupLabel(attr),
            icon = groupIcons[attr],
            items = items,
        }
    end

    local scripts = {}
    if D and type(D.custom) == "table" then
        for i, custom in ipairs(D.custom) do
            local name = (type(custom) == "table" and (custom.name or custom.Name)) or ("Custom " .. i)
            scripts[#scripts + 1] = {
                label = name,
                slot = { kind = "attr", attribute = 5, subAttribute = i },
                icon = "Interface\\Icons\\INV_Misc_Note_01",
                coords = { 0, 1, 0, 1 },
            }
        end
    end
    groups[#groups + 1] = {
        label = "Scripts",
        icon = "Interface\\Icons\\INV_Misc_Note_01",
        items = scripts,
        emptyHint = "No custom displays",
    }

    local plugins = {}
    local seen = {}
    local function addPlugin(absName, label, icon)
        if not absName or seen[absName] then return end
        if absName == TINY_THREAT_PLUGIN then return end
        seen[absName] = true
        if absName == FLUX_THREAT_PLUGIN then
            icon = FLUX_THREAT_ICON
            label = label or "Threat"
        end
        plugins[#plugins + 1] = {
            label = label or absName,
            icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
            coords = { 0, 1, 0, 1 },
            slot = { kind = "plugin", plugin = absName },
        }
    end

    addPlugin(FLUX_THREAT_PLUGIN, "Threat", FLUX_THREAT_ICON)

    if D and D.RaidTables then
        if type(D.RaidTables.Menu) == "table" then
            for _, entry in ipairs(D.RaidTables.Menu) do
                if type(entry) == "table" then
                    local abs = entry[1] or entry.real_name or entry.absolute_name
                    local lab = entry[2] or entry.name or entry.Name
                    local ic = entry[3] or entry.icon
                    if type(abs) == "string" then addPlugin(abs, lab, ic) end
                elseif type(entry) == "string" then
                    addPlugin(entry, entry, nil)
                end
            end
        end
        if type(D.RaidTables.NameTable) == "table" then
            for abs, obj in pairs(D.RaidTables.NameTable) do
                local lab = (type(obj) == "table" and (obj.name or obj.Name)) or abs
                local ic = type(obj) == "table" and obj.icon or nil
                addPlugin(abs, lab, ic)
            end
        end
        if type(D.RaidTables.Plugins) == "table" then
            for _, obj in ipairs(D.RaidTables.Plugins) do
                if type(obj) == "table" then
                    addPlugin(obj.real_name or obj.absolute_name, obj.name or obj.Name, obj.icon)
                end
            end
        end
    end

    groups[#groups + 1] = {
        label = "Plugins",
        icon = FLUX_THREAT_ICON,
        items = plugins,
        emptyHint = "No raid plugins",
    }
    return groups
end

function FluxMeterLayout.SlotShortLabel(slot)
    slot = DeepCopySlot(slot)
    if slot.kind == "blizzard" then
        return BlizzardTypeName(slot.damageMeterType)
    end
    if slot.kind == "plugin" then
        if slot.plugin == FLUX_THREAT_PLUGIN then return "Threat" end
        local name = slot.plugin or "Plugin"
        return name:gsub("DETAILS_PLUGIN_", ""):gsub("_", " ")
    end
    return SubAttrName(slot.attribute or 1, slot.subAttribute or 1)
end

function FluxMeterLayout.SlotColor(slot)
    slot = DeepCopySlot(slot)
    if slot.kind == "blizzard" then
        return SLOT_COLORS.blizzard[BlizzardTypeCategory(slot.damageMeterType)] or { 0.4, 0.4, 0.4, 0.9 }
    end
    if slot.kind == "plugin" then return SLOT_COLORS.plugin end
    return SLOT_COLORS.attr[slot.attribute or 1] or { 0.4, 0.4, 0.4, 0.9 }
end

local function ReembedQuiet()
    SaveLibrary()
    if not FluxWindowFrame or not FluxWindowFrame.GetActiveTab
        or FluxWindowFrame:GetActiveTab() ~= "Meter" then return end
    if InCombatLockdown() then
        if Flux and Flux.Combat then Flux.Combat.Defer("meterlayout.reembed", ReembedQuiet) end
        return
    end
    local layout = FluxMeterLayout.GetWorkingLayout()
    if FluxMeterLayout.IsBlizzardBackend() then
        if not (FluxBlizzardMeter and FluxBlizzardMeter.Embed and FluxWindowFrame and FluxWindowFrame.GetFrame) then
            return
        end
        local frame = FluxWindowFrame:GetFrame()
        local content = frame and frame.Content
        if content and layout then
            FluxBlizzardMeter:Embed(content, layout)
        end
        return
    end
    if not (FluxDetails and FluxDetails.Embed and FluxWindowFrame and FluxWindowFrame.GetFrame) then
        return
    end
    local frame = FluxWindowFrame:GetFrame()
    if frame and layout then
        FluxDetails:Embed(frame, layout)
    end
end

local function ScheduleReembed()
    if reembedTimer then
        reembedTimer:Cancel()
        reembedTimer = nil
    end
    reembedTimer = CancelableAfter(0.12, function()
        reembedTimer = nil
        ReembedQuiet()
        if editorFrame and editorFrame.Refresh and not editorFrame._dragging then
            editorFrame:Refresh()
        end
    end)
end

--- Push only geometry into the live embed (no full Embed) — used while dragging splitters.
local function PushLiveGeometry()
    if liveGeomTimer then return end
    liveGeomTimer = CancelableAfter(0.03, function()
        liveGeomTimer = nil
        if not FluxWindowFrame or FluxWindowFrame:GetActiveTab() ~= "Meter" then return end
        if not workingLayout then return end
        if FluxMeterLayout.IsBlizzardBackend() then
            if FluxBlizzardMeter and FluxBlizzardMeter.SyncGeometryFromLayout then
                FluxBlizzardMeter:SyncGeometryFromLayout(workingLayout)
            end
            return
        end
        if FluxDetails and FluxDetails.SyncGeometryFromLayout then
            FluxDetails:SyncGeometryFromLayout(workingLayout)
        end
    end)
end

function FluxMeterLayout.CancelPendingWork()
    if reembedTimer then reembedTimer:Cancel(); reembedTimer = nil end
    if liveGeomTimer then liveGeomTimer:Cancel(); liveGeomTimer = nil end
end

local function FlushLiveGeometry()
    if liveGeomTimer then
        liveGeomTimer:Cancel()
        liveGeomTimer = nil
    end
    if workingLayout then
        if FluxMeterLayout.IsBlizzardBackend() then
            if FluxBlizzardMeter and FluxBlizzardMeter.SyncGeometryFromLayout then
                FluxBlizzardMeter:SyncGeometryFromLayout(workingLayout)
            end
            if FluxBlizzardMeter and FluxBlizzardMeter.RefreshEmbeddedLayout then
                FluxBlizzardMeter:RefreshEmbeddedLayout()
            end
        else
            if FluxDetails and FluxDetails.SyncGeometryFromLayout then
                FluxDetails:SyncGeometryFromLayout(workingLayout)
            end
            if FluxDetails and FluxDetails.RefreshEmbeddedLayout then
                FluxDetails:RefreshEmbeddedLayout()
            end
        end
    end
    SaveLibrary()
end

function FluxMeterLayout.ReembedQuiet()
    ReembedQuiet()
end

function FluxMeterLayout.ScheduleReembed()
    ScheduleReembed()
end

local function ExitEditor()
    if editorFrame and editorFrame._embedHost then
        return
    end
    editorActive = false
    if editorFrame then editorFrame:Hide() end
end

function FluxMeterLayout.IsEditorOpen()
    return editorActive == true
end

function FluxMeterLayout.CloseEditor()
    ExitEditor()
end

local function PaintMiniPreview(host, layout, withIcons)
    if not host then return end
    host._cells = host._cells or {}
    for _, c in ipairs(host._cells) do c:Hide() end
    if not layout then return end

    local w = host:GetWidth() or host._w or 64
    local h = host:GetHeight() or host._h or 44
    if w < 4 then w = host._w or 64 end
    if h < 4 then h = host._h or 44 end
    local pad = 2
    local top = layout.topSlots or {}
    local bot = layout.bottomSlots or {}
    local hasBot = #bot > 0
    local topFrac = ClampTopRowFrac(layout.topRowFrac)
    local innerH = h - pad * (hasBot and 3 or 2)
    local topH = hasBot and (innerH * topFrac) or (h - pad * 2)
    local botH = hasBot and (innerH - topH) or 0

    local idx = 0
    local function take()
        idx = idx + 1
        local cell = host._cells[idx]
        if not cell then
            cell = CreateFrame("Frame", nil, host, "BackdropTemplate")
            cell:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            cell.icon = cell:CreateTexture(nil, "ARTWORK")
            cell.icon:SetPoint("CENTER", 0, 4)
            cell.label = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cell.label:SetPoint("BOTTOM", 0, 2)
            if cell.label.SetTextScale then cell.label:SetTextScale(0.65) end
            host._cells[idx] = cell
        end
        cell:Show()
        return cell
    end

    local function paintRow(slots, fracs, y, rowH)
        local n = #slots
        if n == 0 then return end
        fracs = NormalizeColFracs(fracs, n)
        local innerW = w - pad * 2
        local x = pad
        for i = 1, n do
            local cell = take()
            local cw = math.max(2, innerW * fracs[i] - (i < n and pad or 0))
            local c = FluxMeterLayout.SlotColor(slots[i])
            cell:SetBackdropColor(c[1] * 0.45, c[2] * 0.45, c[3] * 0.45, 0.95)
            cell:SetBackdropBorderColor(c[1], c[2], c[3], 0.9)
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
            cell:SetSize(cw, rowH)
            local iconSize = math.min(22, math.max(10, math.min(cw - 4, rowH - 12)))
            if withIcons and cell.icon and iconSize >= 10 then
                ApplyIconToTexture(cell.icon, slots[i], iconSize)
                cell.icon:ClearAllPoints()
                cell.icon:SetPoint("CENTER", 0, rowH > 28 and 4 or 0)
                if cell.label then
                    local short = FluxMeterLayout.SlotShortLabel(slots[i])
                    if #short > 8 then short = short:sub(1, 7) .. "…" end
                    cell.label:SetText(rowH > 28 and short or "")
                end
            else
                if cell.icon then cell.icon:Hide() end
                if cell.label then
                    cell.label:ClearAllPoints()
                    cell.label:SetPoint("CENTER")
                    cell.label:SetText(FluxMeterLayout.SlotShortLabel(slots[i]):sub(1, 4))
                end
            end
            x = x + cw + pad
        end
    end

    paintRow(top, layout.topColFracs, pad, topH)
    if hasBot then
        paintRow(bot, layout.bottomColFracs, pad + topH + pad, botH)
    end
end

local function MakePanel(parent, titleText)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    panel:SetBackdropColor(0.09, 0.09, 0.11, 0.98)
    panel:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)

    local hdr = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    hdr:SetPoint("TOPLEFT", 1, -1)
    hdr:SetPoint("TOPRIGHT", -1, -1)
    hdr:SetHeight(22)
    hdr:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    hdr:SetBackdropColor(0.14, 0.14, 0.18, 1)

    local title = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 8, 0)
    title:SetText(titleText or "")
    panel.header = hdr
    panel.title = title
    return panel
end

--- Exact pixel size of the live Flux window (meter embed host is this frame).
local function GetFluxWindowPreviewSize()
    local w = (FluxWindowFrame and FluxWindowFrame.WINDOW_WIDTH) or 405
    local h = (FluxWindowFrame and FluxWindowFrame.WINDOW_HEIGHT) or 270
    local frame = FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame()
    if frame then
        local lw, lh = frame:GetWidth(), frame:GetHeight()
        if lw and lw > 40 then w = lw end
        if lh and lh > 40 then h = lh end
    end
    return w, h
end

local function EnsureEditor()
    if editorFrame and editorFrame.__fluxMeterLayoutV5 then
        return editorFrame
    end
    if editorFrame then
        editorFrame:Hide()
        editorFrame = nil
    end

    local previewW, previewH = GetFluxWindowPreviewSize()
    local LIB_W, PICKER_W = 210, 168
    local PAD = 10
    local TITLE_H = 34
    local STRUCT_H = 56
    local HINT_H = 28
    local CANVAS_PAD_X = 16
    local EDITOR_W = PAD + LIB_W + PAD + CANVAS_PAD_X + previewW + CANVAS_PAD_X + PAD + PICKER_W + PAD
    local EDITOR_H = TITLE_H + 8 + PAD + 28 + STRUCT_H + 10 + previewH + 22 + HINT_H + PAD
    local f = CreateFrame("Frame", "FluxMeterLayoutEditor", UIParent, "BackdropTemplate")
    f.__fluxMeterLayoutV5 = true
    f:SetSize(EDITOR_W, EDITOR_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(120)
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.05, 0.05, 0.07, 0.98)
    f:SetBackdropBorderColor(0.55, 0.48, 0.28, 1)
    f:Hide()
    f:EnableKeyboard(true)
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
            ExitEditor()
        elseif self.SetPropagateKeyboardInput then
            self:SetPropagateKeyboardInput(true)
        end
    end)
    f:SetScript("OnHide", function() editorActive = false end)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(34)
    titleBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    titleBar:SetBackdropColor(0.12, 0.11, 0.09, 1)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local brandIcon = titleBar:CreateTexture(nil, "ARTWORK")
    brandIcon:SetSize(20, 20)
    brandIcon:SetPoint("LEFT", 10, 0)
    brandIcon:SetTexture("Interface\\Icons\\Ability_DualWield")

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", brandIcon, "RIGHT", 8, 0)
    title:SetText("Meter Layout")
    title:SetTextColor(1, 0.86, 0.45)

    local subtitle = titleBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("LEFT", title, "RIGHT", 10, 0)
    subtitle:SetText((FluxMeterLayout.IsBlizzardBackend and FluxMeterLayout.IsBlizzardBackend())
        and "blizzard · max 3 panes · drag to split"
        or "presets · custom layouts · drag to split")

    local doneBtn = CreateFrame("Button", nil, titleBar, "UIPanelButtonTemplate")
    doneBtn:SetSize(70, 24)
    doneBtn:SetPoint("RIGHT", -8, 0)
    doneBtn:SetText("Done")
    doneBtn:SetScript("OnClick", ExitEditor)
    f.titleBar = titleBar
    f.doneBtn = doneBtn
    f.subtitle = subtitle

    -- LEFT: library panel
    local libPanel = MakePanel(f, "Layouts")
    libPanel:SetPoint("TOPLEFT", 10, -42)
    libPanel:SetPoint("BOTTOMLEFT", 10, 10)
    libPanel:SetWidth(210)

    local tabBuiltin = CreateFrame("Button", nil, libPanel, "UIPanelButtonTemplate")
    tabBuiltin:SetSize(96, 20)
    tabBuiltin:SetPoint("TOPLEFT", 8, -28)
    tabBuiltin:SetText("Built-in")
    local tabUser = CreateFrame("Button", nil, libPanel, "UIPanelButtonTemplate")
    tabUser:SetSize(96, 20)
    tabUser:SetPoint("LEFT", tabBuiltin, "RIGHT", 4, 0)
    tabUser:SetText("Saved")
    f.libTab = "builtin"

    local libScroll = CreateFrame("ScrollFrame", nil, libPanel, "UIPanelScrollFrameTemplate")
    libScroll:SetPoint("TOPLEFT", 8, -54)
    libScroll:SetPoint("BOTTOMRIGHT", -28, 36)
    local libChild = CreateFrame("Frame", nil, libScroll)
    libChild:SetSize(170, 1)
    libScroll:SetScrollChild(libChild)
    f.libChild = libChild
    f.libButtons = {}

    local function MakeLibAction(label, w)
        local b = CreateFrame("Button", nil, libPanel, "UIPanelButtonTemplate")
        b:SetSize(w, 22)
        b:SetText(label)
        return b
    end
    local newBtn = MakeLibAction("New", 48)
    newBtn:SetPoint("BOTTOMLEFT", 8, 8)
    local saveBtn = MakeLibAction("Save", 48)
    saveBtn:SetPoint("LEFT", newBtn, "RIGHT", 3, 0)
    local renBtn = MakeLibAction("Rename", 56)
    renBtn:SetPoint("LEFT", saveBtn, "RIGHT", 3, 0)
    local delBtn = MakeLibAction("Del", 36)
    delBtn:SetPoint("LEFT", renBtn, "RIGHT", 3, 0)

    newBtn:SetScript("OnClick", function()
        FluxMeterLayout.SaveWorkingAsNew("Layout " .. (#userLayouts + 1))
        f.libTab = "user"
        ScheduleReembed()
        f:Refresh()
    end)
    saveBtn:SetScript("OnClick", function()
        if activeLayoutId and activeLayoutId:match("^user:") then
            FluxMeterLayout.SaveWorkingOverActive()
        else
            FluxMeterLayout.SaveWorkingAsNew(workingLayout and workingLayout.name or "Layout")
            f.libTab = "user"
        end
        f:Refresh()
    end)
    renBtn:SetScript("OnClick", function()
        if not (activeLayoutId and activeLayoutId:match("^user:")) then return end
        StaticPopupDialogs["FLUX_METER_LAYOUT_RENAME"] = {
            text = "Rename layout:",
            button1 = OKAY,
            button2 = CANCEL,
            hasEditBox = true,
            maxLetters = 40,
            OnShow = function(self)
                local box = self.editBox or self.EditBox
                if box then
                    box:SetText((workingLayout and workingLayout.name) or "")
                    box:HighlightText()
                end
            end,
            OnAccept = function(self)
                local box = self.editBox or self.EditBox
                FluxMeterLayout.RenameActive(box and box:GetText() or "")
                f:Refresh()
            end,
            EditBoxOnEnterPressed = function(self)
                FluxMeterLayout.RenameActive(self:GetText() or "")
                self:GetParent():Hide()
                f:Refresh()
            end,
            timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        }
        StaticPopup_Show("FLUX_METER_LAYOUT_RENAME")
    end)
    delBtn:SetScript("OnClick", function()
        if FluxMeterLayout.DeleteActive() then
            ScheduleReembed()
            f:Refresh()
        end
    end)

    tabBuiltin:SetScript("OnClick", function() f.libTab = "builtin"; f:Refresh() end)
    tabUser:SetScript("OnClick", function() f.libTab = "user"; f:Refresh() end)

    -- CENTER: canvas panel (sized around 1:1 Flux window preview)
    local canvas = MakePanel(f, "Layout canvas · 1:1 Flux window")
    canvas:SetPoint("TOPLEFT", libPanel, "TOPRIGHT", 10, 0)
    canvas:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    canvas:SetWidth(CANVAS_PAD_X + previewW + CANVAS_PAD_X)
    canvas.title:SetText("Layout canvas · 1:1 Flux window")

    local struct = CreateFrame("Frame", nil, canvas)
    struct:SetPoint("TOPLEFT", 8, -28)
    struct:SetPoint("TOPRIGHT", -8, -28)
    struct:SetHeight(STRUCT_H)

    local function Chip(parent, label)
        local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
        b:SetSize(58, 22)
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        b:SetBackdropColor(0.16, 0.16, 0.2, 1)
        b:SetBackdropBorderColor(0.35, 0.35, 0.4, 1)
        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.label:SetPoint("CENTER")
        b.label:SetText(label)
        b:SetScript("OnEnter", function(self)
            if not self._active then self:SetBackdropBorderColor(0.9, 0.75, 0.3, 1) end
        end)
        b:SetScript("OnLeave", function(self)
            if not self._active then self:SetBackdropBorderColor(0.35, 0.35, 0.4, 1) end
        end)
        function b:SetActive(on)
            self._active = on
            if on then
                self:SetBackdropColor(0.35, 0.28, 0.12, 1)
                self:SetBackdropBorderColor(0.95, 0.78, 0.25, 1)
            else
                self:SetBackdropColor(0.16, 0.16, 0.2, 1)
                self:SetBackdropBorderColor(0.35, 0.35, 0.4, 1)
            end
        end
        return b
    end

    local topLabel = struct:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    topLabel:SetPoint("TOPLEFT", 0, 0)
    topLabel:SetText("Top row")
    local t1 = Chip(struct, "Top 1"); t1:SetPoint("TOPLEFT", 52, 2)
    local t2 = Chip(struct, "Top 2"); t2:SetPoint("LEFT", t1, "RIGHT", 4, 0)
    local t3 = Chip(struct, "Top 3"); t3:SetPoint("LEFT", t2, "RIGHT", 4, 0)

    local botLabel = struct:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    botLabel:SetPoint("TOPLEFT", 0, -28)
    botLabel:SetText("Bottom")
    local b0 = Chip(struct, "No Bot"); b0:SetPoint("TOPLEFT", 52, -26)
    local b1 = Chip(struct, "Bot 1"); b1:SetPoint("LEFT", b0, "RIGHT", 4, 0)
    local b2 = Chip(struct, "Bot 2"); b2:SetPoint("LEFT", b1, "RIGHT", 4, 0)
    local b3 = Chip(struct, "Bot 3"); b3:SetPoint("LEFT", b2, "RIGHT", 4, 0)
    f.structBtns = { top = { t1, t2, t3 }, bot = { b0, b1, b2, b3 } }

    t1:SetScript("OnClick", function()
        if FluxMeterLayout.CanSetTopColCount and not FluxMeterLayout.CanSetTopColCount(1) then return end
        FluxMeterLayout.SetTopColCount(1); ScheduleReembed(); f:Refresh()
    end)
    t2:SetScript("OnClick", function()
        if FluxMeterLayout.CanSetTopColCount and not FluxMeterLayout.CanSetTopColCount(2) then return end
        FluxMeterLayout.SetTopColCount(2); ScheduleReembed(); f:Refresh()
    end)
    t3:SetScript("OnClick", function()
        if FluxMeterLayout.CanSetTopColCount and not FluxMeterLayout.CanSetTopColCount(3) then return end
        FluxMeterLayout.SetTopColCount(3); ScheduleReembed(); f:Refresh()
    end)
    b0:SetScript("OnClick", function()
        FluxMeterLayout.SetBottomColCount(0); ScheduleReembed(); f:Refresh()
    end)
    b1:SetScript("OnClick", function()
        if FluxMeterLayout.CanSetBottomColCount and not FluxMeterLayout.CanSetBottomColCount(1) then return end
        FluxMeterLayout.SetBottomColCount(1); ScheduleReembed(); f:Refresh()
    end)
    b2:SetScript("OnClick", function()
        if FluxMeterLayout.CanSetBottomColCount and not FluxMeterLayout.CanSetBottomColCount(2) then return end
        FluxMeterLayout.SetBottomColCount(2); ScheduleReembed(); f:Refresh()
    end)
    b3:SetScript("OnClick", function()
        if FluxMeterLayout.CanSetBottomColCount and not FluxMeterLayout.CanSetBottomColCount(3) then return end
        FluxMeterLayout.SetBottomColCount(3); ScheduleReembed(); f:Refresh()
    end)

    local bigPreview = CreateFrame("Frame", nil, canvas, "BackdropTemplate")
    bigPreview:SetSize(previewW, previewH)
    bigPreview:SetPoint("TOP", canvas, "TOP", 0, -(28 + STRUCT_H + 6))
    bigPreview:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    bigPreview:SetBackdropColor(0.04, 0.04, 0.05, 1)
    bigPreview:SetBackdropBorderColor(0.55, 0.48, 0.28, 1)
    f.bigPreview = bigPreview
    f.previewBaseW, f.previewBaseH = previewW, previewH

    local sizeTag = canvas:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sizeTag:SetPoint("TOP", bigPreview, "BOTTOM", 0, -6)
    sizeTag:SetText(string.format("%d × %d px (Flux window)", previewW, previewH))
    f.sizeTag = sizeTag

    local hint = canvas:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 10, 10)
    hint:SetPoint("BOTTOMRIGHT", -10, 10)
    hint:SetJustifyH("LEFT")
    hint:SetText("Preview is 1:1 with Flux window · click a pane · drag bars to resize")
    f.slotButtons = { top = {}, bottom = {} }
    for _, row in ipairs({ "top", "bottom" }) do
        for i = 1, MAX_COLS do
            local btn = CreateFrame("Button", nil, bigPreview, "BackdropTemplate")
            btn:SetFrameLevel(bigPreview:GetFrameLevel() + 3)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetSize(28, 28)
            btn.icon:SetPoint("TOP", 0, -10)
            btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.label:SetPoint("TOP", btn.icon, "BOTTOM", 0, -4)
            btn.label:SetPoint("LEFT", 4, 0)
            btn.label:SetPoint("RIGHT", -4, 0)
            btn.label:SetWordWrap(true)
            btn.row, btn.index = row, i
            btn:SetScript("OnClick", function(self)
                f.selectedRow, f.selectedIndex = self.row, self.index
                f:RefreshPicker()
                f:Refresh()
            end)
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(self.label:GetText() or "Window")
                GameTooltip:AddLine("Click to select, then choose a type →", 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", GameTooltip_Hide)
            f.slotButtons[row][i] = btn
        end
    end

    f.colHandles = { top = {}, bottom = {} }

    local function CursorInPreview()
        local left, top = bigPreview:GetLeft(), bigPreview:GetTop()
        local width, height = bigPreview:GetWidth(), bigPreview:GetHeight()
        if not left or not top or not width or width < 1 or not height or height < 1 then
            return nil
        end
        local scale = bigPreview:GetEffectiveScale() or 1
        local mx, my = GetCursorPosition()
        mx, my = mx / scale, my / scale
        return mx, my, left, top, width, height
    end

    local function EndSplitterDrag()
        if not f._dragging then return end
        f._dragging = nil
        f._dragRow = nil
        f._dragSplit = nil
        f:SetScript("OnUpdate", nil)
        if f.heightHandle and f.heightHandle.tex then
            f.heightHandle.tex:SetColorTexture(0.35, 0.8, 1, 0.95)
        end
        for _, row in ipairs({ "top", "bottom" }) do
            for i = 1, MAX_COLS - 1 do
                local h = f.colHandles[row][i]
                if h and h.tex and not h:IsMouseOver() then
                    h.tex:SetColorTexture(1, 1, 1, 0.85)
                end
            end
        end
        FlushLiveGeometry()
    end

    local function BeginSplitterDrag(kind, row, splitIndex)
        f._dragging = kind
        f._dragRow = row
        f._dragSplit = splitIndex
        f:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then
                EndSplitterDrag()
                return
            end
            local lay = workingLayout
            if not lay then return end
            local mx, my, left, top, width, height = CursorInPreview()
            if not mx then return end
            local pad = PREVIEW_PAD

            if f._dragging == "col" then
                local slots = (f._dragRow == "top") and lay.topSlots or lay.bottomSlots
                local n = #(slots or {})
                local splitIndex = f._dragSplit
                if n < 2 or not splitIndex or splitIndex >= n then return end
                local gap = 2
                local innerLeft = left + pad
                local innerW = width - pad * 2
                local usable = math.max(1, innerW - gap * (n - 1))
                local fracs = NormalizeColFracs(
                    (f._dragRow == "top") and lay.topColFracs or lay.bottomColFracs,
                    n
                )
                local cumBefore, restAfter = 0, 0
                for i = 1, splitIndex - 1 do cumBefore = cumBefore + fracs[i] end
                for i = splitIndex + 2, n do restAfter = restAfter + fracs[i] end
                local available = 1 - cumBefore - restAfter
                local bandLeft = innerLeft + usable * cumBefore + gap * (splitIndex - 1)
                local leftFrac = math.max(COL_FRAC_MIN, math.min(available - COL_FRAC_MIN, (mx - bandLeft) / usable))
                fracs[splitIndex] = leftFrac
                fracs[splitIndex + 1] = available - leftFrac
                FluxMeterLayout.SetColFracs(f._dragRow, fracs)
            elseif f._dragging == "row" then
                local botN = #(lay.bottomSlots or {})
                if botN < 1 then return end
                local innerTop = top - pad
                local innerH = height - pad * 3
                if innerH < 1 then return end
                local y = innerTop - my
                FluxMeterLayout.SetTopRowFrac(y / innerH)
            end

            f:RefreshCanvas()
            PushLiveGeometry()
        end)
    end

    local function MakeColHandle(row, splitIndex)
        local handle = CreateFrame("Button", nil, bigPreview)
        handle:SetSize(14, 40)
        handle:SetFrameLevel(bigPreview:GetFrameLevel() + 20)
        handle:EnableMouse(true)
        handle:RegisterForClicks("LeftButtonUp")
        handle:SetHitRectInsets(-8, -8, -4, -4)
        local tex = handle:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOP", 0, 0)
        tex:SetPoint("BOTTOM", 0, 0)
        tex:SetWidth(3)
        tex:SetColorTexture(1, 1, 1, 0.85)
        handle.tex = tex
        handle:SetScript("OnEnter", function(self)
            if not f._dragging then self.tex:SetColorTexture(1, 0.85, 0.25, 1) end
        end)
        handle:SetScript("OnLeave", function(self)
            if not f._dragging then self.tex:SetColorTexture(1, 1, 1, 0.85) end
        end)
        handle:SetScript("OnMouseDown", function(self, button)
            if button ~= "LeftButton" then return end
            self.tex:SetColorTexture(1, 0.75, 0.15, 1)
            BeginSplitterDrag("col", row, splitIndex)
        end)
        handle:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then EndSplitterDrag() end
        end)
        return handle
    end
    for _, row in ipairs({ "top", "bottom" }) do
        for i = 1, MAX_COLS - 1 do
            f.colHandles[row][i] = MakeColHandle(row, i)
        end
    end

    local heightHandle = CreateFrame("Button", nil, bigPreview)
    heightHandle:SetSize(80, 14)
    heightHandle:SetFrameLevel(bigPreview:GetFrameLevel() + 21)
    heightHandle:EnableMouse(true)
    heightHandle:SetHitRectInsets(0, 0, -8, -8)
    local htex = heightHandle:CreateTexture(nil, "ARTWORK")
    htex:SetPoint("LEFT", 0, 0)
    htex:SetPoint("RIGHT", 0, 0)
    htex:SetHeight(3)
    htex:SetColorTexture(0.35, 0.8, 1, 0.95)
    heightHandle.tex = htex
    heightHandle:SetScript("OnEnter", function(self)
        if not f._dragging then self.tex:SetColorTexture(0.55, 0.9, 1, 1) end
    end)
    heightHandle:SetScript("OnLeave", function(self)
        if not f._dragging then self.tex:SetColorTexture(0.35, 0.8, 1, 0.95) end
    end)
    heightHandle:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        self.tex:SetColorTexture(0.7, 0.95, 1, 1)
        BeginSplitterDrag("row")
    end)
    heightHandle:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then EndSplitterDrag() end
    end)
    f.heightHandle = heightHandle

    -- RIGHT: type picker
    local picker = MakePanel(f, "Window type")
    picker:SetPoint("TOPLEFT", canvas, "TOPRIGHT", 10, 0)
    picker:SetPoint("BOTTOMLEFT", canvas, "BOTTOMRIGHT", 10, 0)
    picker:SetWidth(PICKER_W)

    local pickerScroll = CreateFrame("ScrollFrame", nil, picker, "UIPanelScrollFrameTemplate")
    pickerScroll:SetPoint("TOPLEFT", 6, -28)
    pickerScroll:SetPoint("BOTTOMRIGHT", -26, 8)
    local pickerChild = CreateFrame("Frame", nil, pickerScroll)
    pickerChild:SetSize(120, 1)
    pickerScroll:SetScrollChild(pickerChild)
    f.pickerChild = pickerChild

    function f:RefreshPicker()
        local child = self.pickerChild
        child._rows = child._rows or {}
        local groups = FluxMeterLayout.BuildCatalog()
        local yOff, rowIdx = 0, 0
        local function takeRow(h)
            rowIdx = rowIdx + 1
            local row = child._rows[rowIdx]
            if not row then
                row = CreateFrame("Button", nil, child, "BackdropTemplate")
                row:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(16, 16)
                row.icon:SetPoint("LEFT", 4, 0)
                row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.label:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
                row.label:SetPoint("RIGHT", -3, 0)
                row.label:SetJustifyH("LEFT")
                child._rows[rowIdx] = row
            end
            row:SetHeight(h or 20)
            row:SetWidth(118)
            row:Show()
            return row
        end
        for _, group in ipairs(groups) do
            local hdr = takeRow(22)
            hdr:SetBackdropColor(0.18, 0.16, 0.12, 1)
            hdr:SetBackdropBorderColor(0.4, 0.35, 0.2, 1)
            if group.icon then
                hdr.icon:SetTexture(group.icon)
                hdr.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                hdr.icon:Show()
            else
                hdr.icon:Hide()
            end
            hdr.label:SetText(group.label)
            hdr.label:SetTextColor(1, 0.86, 0.5)
            hdr:SetScript("OnClick", nil)
            hdr:ClearAllPoints()
            hdr:SetPoint("TOPLEFT", 0, -yOff)
            yOff = yOff + 24

            if group.items and #group.items > 0 then
                for _, item in ipairs(group.items) do
                    local row = takeRow(22)
                    row:SetBackdropColor(0.12, 0.12, 0.14, 1)
                    row:SetBackdropBorderColor(0.22, 0.22, 0.25, 1)
                    if item.icon then
                        row.icon:SetTexture(item.icon)
                        local c = item.coords or { 0, 1, 0, 1 }
                        row.icon:SetTexCoord(c[1], c[2], c[3], c[4])
                        row.icon:Show()
                    else
                        row.icon:Hide()
                    end
                    row.label:SetText(item.label)
                    row.label:SetTextColor(0.92, 0.92, 0.92)
                    row:SetScript("OnClick", function()
                        FluxMeterLayout.SetSlot(self.selectedRow or "top", self.selectedIndex or 1, item.slot)
                        ScheduleReembed()
                        self:Refresh()
                    end)
                    row:SetScript("OnEnter", function(selfBtn)
                        selfBtn:SetBackdropBorderColor(0.95, 0.75, 0.25, 1)
                    end)
                    row:SetScript("OnLeave", function(selfBtn)
                        selfBtn:SetBackdropBorderColor(0.22, 0.22, 0.25, 1)
                    end)
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", 0, -yOff)
                    yOff = yOff + 23
                end
            else
                local empty = takeRow(20)
                empty:SetBackdropColor(0.1, 0.1, 0.1, 1)
                empty:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
                empty.icon:Hide()
                empty.label:SetText(group.emptyHint or "(empty)")
                empty.label:SetTextColor(0.55, 0.55, 0.55)
                empty:SetScript("OnClick", nil)
                empty:ClearAllPoints()
                empty:SetPoint("TOPLEFT", 0, -yOff)
                yOff = yOff + 22
            end
        end
        for i = rowIdx + 1, #child._rows do child._rows[i]:Hide() end
        child:SetHeight(math.max(1, yOff))
    end

    function f:RebuildLibList()
        for _, b in ipairs(self.libButtons) do b:Hide() end
        wipe(self.libButtons)
        local yU = 0
        local function addBtn(name, selected, onClick, thumbLayout)
            local btn = CreateFrame("Button", nil, self.libChild, "BackdropTemplate")
            btn:SetSize(168, 48)
            btn:SetPoint("TOPLEFT", 0, -yU)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            btn:SetBackdropColor(0.11, 0.11, 0.13, 1)
            if selected then
                btn:SetBackdropBorderColor(0.95, 0.75, 0.2, 1)
            else
                btn:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)
            end
            local thumb = CreateFrame("Frame", nil, btn, "BackdropTemplate")
            thumb:SetSize(56, 38)
            thumb:SetPoint("LEFT", 5, 0)
            thumb:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            thumb:SetBackdropColor(0.06, 0.06, 0.07, 1)
            thumb:SetBackdropBorderColor(0.2, 0.2, 0.22, 1)
            thumb._w, thumb._h = 56, 38
            btn.thumb = thumb
            PaintMiniPreview(thumb, thumbLayout, true)
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("TOPLEFT", thumb, "TOPRIGHT", 6, -4)
            text:SetPoint("BOTTOMRIGHT", -4, 4)
            text:SetJustifyH("LEFT")
            text:SetJustifyV("TOP")
            text:SetWordWrap(true)
            text:SetText(name)
            btn:SetScript("OnClick", onClick)
            self.libButtons[#self.libButtons + 1] = btn
            yU = yU + 52
        end

        if self.libTab == "user" then
            if #userLayouts == 0 then
                if not self.emptyUserLabel then
                    self.emptyUserLabel = self.libChild:CreateFontString(nil, "OVERLAY", "GameFontDisable")
                    self.emptyUserLabel:SetPoint("TOPLEFT", 4, -8)
                    self.emptyUserLabel:SetWidth(160)
                    self.emptyUserLabel:SetJustifyH("LEFT")
                end
                self.emptyUserLabel:SetText("No saved layouts yet.\nApply a built-in, edit,\nthen press Save.")
                self.emptyUserLabel:Show()
            elseif self.emptyUserLabel then
                self.emptyUserLabel:Hide()
            end
            for _, lay in ipairs(userLayouts) do
                local id = lay.id
                addBtn(lay.name or id, id == activeLayoutId, function()
                    FluxMeterLayout.LoadUser(id)
                    ScheduleReembed()
                    f:Refresh()
                end, lay)
            end
        else
            if self.emptyUserLabel then self.emptyUserLabel:Hide() end
            local builtinCount = FluxMeterLayout.GetBuiltinCount and FluxMeterLayout.GetBuiltinCount() or 11
            local labels = FluxMeterLayout.GetBuiltinLabels and FluxMeterLayout.GetBuiltinLabels() or FluxMeterLayout.BUILTIN_LABELS
            for i = 1, builtinCount do
                local preset = BuiltinPresetToLayout(i)
                local selected = (activeLayoutId == ("builtin:" .. i))
                local idx = i
                addBtn((labels and labels[idx]) or ("Preset " .. idx), selected, function()
                    FluxMeterLayout.ApplyBuiltin(idx)
                    ScheduleReembed()
                    f:Refresh()
                end, preset)
            end
        end
        self.libChild:SetHeight(math.max(1, yU))
    end

    function f:RefreshCanvas()
        if not workingLayout then LoadLibrary() end
        local lay = workingLayout
        if not lay then return end

        local pw = self.bigPreview and self.bigPreview:GetWidth() or 300
        local ph = self.bigPreview and self.bigPreview:GetHeight() or 200
        if pw < 10 then pw = 300 end
        if ph < 10 then ph = 200 end

        local topN = #(lay.topSlots or {})
        local botN = #(lay.bottomSlots or {})
        if self.structBtns then
            local function setChipEnabled(chip, enabled)
                if not chip then return end
                chip:SetAlpha(enabled and 1 or 0.35)
                if chip.EnableMouse then chip:EnableMouse(enabled) end
            end
            setChipEnabled(self.structBtns.top[1], not FluxMeterLayout.CanSetTopColCount or FluxMeterLayout.CanSetTopColCount(1))
            setChipEnabled(self.structBtns.top[2], not FluxMeterLayout.CanSetTopColCount or FluxMeterLayout.CanSetTopColCount(2))
            setChipEnabled(self.structBtns.top[3], not FluxMeterLayout.CanSetTopColCount or FluxMeterLayout.CanSetTopColCount(3))
            setChipEnabled(self.structBtns.bot[1], true)
            setChipEnabled(self.structBtns.bot[2], not FluxMeterLayout.CanSetBottomColCount or FluxMeterLayout.CanSetBottomColCount(1))
            setChipEnabled(self.structBtns.bot[3], not FluxMeterLayout.CanSetBottomColCount or FluxMeterLayout.CanSetBottomColCount(2))
            setChipEnabled(self.structBtns.bot[4], not FluxMeterLayout.CanSetBottomColCount or FluxMeterLayout.CanSetBottomColCount(3))
            self.structBtns.top[1]:SetActive(topN == 1)
            self.structBtns.top[2]:SetActive(topN == 2)
            self.structBtns.top[3]:SetActive(topN == 3)
            self.structBtns.bot[1]:SetActive(botN == 0)
            self.structBtns.bot[2]:SetActive(botN == 1)
            self.structBtns.bot[3]:SetActive(botN == 2)
            self.structBtns.bot[4]:SetActive(botN == 3)
        end

        local pad = PREVIEW_PAD
        local gap = 2
        local hasBot = botN > 0
        local topFrac = ClampTopRowFrac(lay.topRowFrac)
        local innerH = ph - pad * (hasBot and 3 or 2)
        local topH = hasBot and (innerH * topFrac) or (ph - pad * 2)
        local botH = hasBot and (innerH - topH) or 0

        if not self.selectedRow then
            self.selectedRow, self.selectedIndex = "top", 1
        end

        local function placeRow(row, slots, fracs, yOff, rowH)
            for i = 1, MAX_COLS do
                self.slotButtons[row][i]:Hide()
                if self.colHandles[row][i] then self.colHandles[row][i]:Hide() end
            end
            local n = #slots
            if n == 0 then return end
            fracs = NormalizeColFracs(fracs, n)
            local innerW = pw - pad * 2
            local usable = math.max(1, innerW - gap * (n - 1))
            local x = pad
            for i = 1, n do
                local btn = self.slotButtons[row][i]
                local cw = math.max(20, usable * fracs[i])
                local c = FluxMeterLayout.SlotColor(slots[i])
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", self.bigPreview, "TOPLEFT", x, -yOff)
                btn:SetSize(cw, rowH)
                btn:SetBackdropColor(c[1] * 0.35, c[2] * 0.35, c[3] * 0.35, 0.95)
                local sel = (self.selectedRow == row and self.selectedIndex == i)
                if sel then
                    btn:SetBackdropBorderColor(1, 0.9, 0.4, 1)
                else
                    btn:SetBackdropBorderColor(c[1], c[2], c[3], 0.85)
                end
                -- Skip icon churn while dragging for smoother splits.
                if not self._dragging then
                    ApplyIconToTexture(btn.icon, slots[i], math.min(32, math.max(18, rowH * 0.35)))
                    btn.label:SetText(FluxMeterLayout.SlotShortLabel(slots[i]))
                end
                btn:EnableMouse(not self._dragging)
                btn:Show()
                if i < n then
                    local handle = self.colHandles[row][i]
                    handle:ClearAllPoints()
                    handle:SetSize(14, math.max(20, rowH - 2))
                    handle:SetPoint("TOPLEFT", self.bigPreview, "TOPLEFT", x + cw + gap * 0.5 - 7, -yOff)
                    handle:Show()
                end
                x = x + cw + gap
            end
        end

        placeRow("top", lay.topSlots or {}, lay.topColFracs, pad, topH)
        if hasBot then
            placeRow("bottom", lay.bottomSlots or {}, lay.bottomColFracs, pad + topH + pad, botH)
            self.heightHandle:ClearAllPoints()
            self.heightHandle:SetWidth(math.max(40, pw - 16))
            self.heightHandle:SetHeight(14)
            self.heightHandle:SetPoint("CENTER", self.bigPreview, "TOPLEFT", pw * 0.5, -(pad + topH))
            self.heightHandle:Show()
        else
            -- Always run placeRow so leftover bottom panes/handles from a prior layout are hidden.
            placeRow("bottom", {}, nil, 0, 0)
            self.heightHandle:Hide()
            if self.selectedRow == "bottom" then
                self.selectedRow, self.selectedIndex = "top", 1
            end
        end
    end

    function f:Refresh()
        if self._dragging then
            self:RefreshCanvas()
            return
        end
        if not workingLayout then LoadLibrary() end
        local lay = workingLayout
        self:RebuildLibList()

        -- Keep preview locked 1:1 to the live Flux window size.
        local pw, ph = GetFluxWindowPreviewSize()
        if self.bigPreview then
            self.bigPreview:SetSize(pw, ph)
        end
        if self.sizeTag then
            self.sizeTag:SetText(string.format("%d × %d px (Flux window)", pw, ph))
        end
        do
            local needW = PAD + LIB_W + PAD + CANVAS_PAD_X + pw + CANVAS_PAD_X + PAD + PICKER_W + PAD
            local needH = TITLE_H + 8 + PAD + 28 + STRUCT_H + 10 + ph + 22 + HINT_H + PAD
            if math.abs((self:GetWidth() or 0) - needW) > 1 or math.abs((self:GetHeight() or 0) - needH) > 1 then
                self:SetSize(needW, needH)
            end
            if canvas and canvas.SetWidth then
                canvas:SetWidth(CANVAS_PAD_X + pw + CANVAS_PAD_X)
            end
        end

        self:RefreshCanvas()

        local list = (self.selectedRow == "top") and lay.topSlots or lay.bottomSlots
        if not list or #list < 1 or self.selectedIndex > #list then
            self.selectedRow, self.selectedIndex = "top", 1
            list = lay.topSlots
        end

        local selSlot = list and list[self.selectedIndex]
        if selSlot then
            picker.title:SetText("Set · " .. FluxMeterLayout.SlotShortLabel(selSlot))
        else
            picker.title:SetText("Window type")
        end

        self:RefreshPicker()
    end

    editorFrame = f
    return f
end

local function RestoreStandaloneChrome(editor)
    if not editor then return end
    editor:SetParent(UIParent)
    editor:SetFrameStrata("DIALOG")
    editor:SetFrameLevel(120)
    editor:SetToplevel(true)
    editor:SetMovable(true)
    editor:SetClampedToScreen(true)
    editor:SetScale(1)
    editor:EnableMouse(true)
    editor:RegisterForDrag("LeftButton")
    editor:SetScript("OnDragStart", editor.StartMoving)
    editor:SetScript("OnDragStop", editor.StopMovingOrSizing)
    if editor.titleBar then
        editor.titleBar:EnableMouse(true)
        editor.titleBar:RegisterForDrag("LeftButton")
        editor.titleBar:SetScript("OnDragStart", function() editor:StartMoving() end)
        editor.titleBar:SetScript("OnDragStop", function() editor:StopMovingOrSizing() end)
        editor.titleBar:Show()
    end
    if editor.doneBtn then
        editor.doneBtn:Show()
    end
    if editor.subtitle then
        if FluxMeterLayout.IsBlizzardBackend and FluxMeterLayout.IsBlizzardBackend() then
            editor.subtitle:SetText("blizzard · max 3 panes · drag to split")
        else
            editor.subtitle:SetText("presets · custom layouts · drag to split")
        end
    end
    editor:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
            ExitEditor()
        elseif self.SetPropagateKeyboardInput then
            self:SetPropagateKeyboardInput(true)
        end
    end)
end

function FluxMeterLayout.DetachFromHost()
    local editor = editorFrame
    if not editor or not editor._embedHost then
        return
    end
    editor._embedHost = nil
    RestoreStandaloneChrome(editor)
    editor:Hide()
    editorActive = false
end

--- Mount the meter layout editor inside an AceGUI / options host frame.
function FluxMeterLayout.AttachToHost(host)
    if not host then return nil end
    loadedBackend = nil -- force reload for current backend when opening options
    LoadLibrary()
    local editor = EnsureEditor()
    if not editor then return nil end

    if editor._embedHost and editor._embedHost ~= host then
        FluxMeterLayout.DetachFromHost()
        editor = EnsureEditor()
    end

    editor._embedHost = host
    editor:SetParent(host)
    editor:ClearAllPoints()
    editor:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    editor:SetMovable(false)
    editor:SetToplevel(false)
    editor:SetClampedToScreen(false)
    -- Stay in the options window's strata/clipping so it can move off-screen with it.
    local strata = host.GetFrameStrata and host:GetFrameStrata()
    if strata then
        editor:SetFrameStrata(strata)
    end
    editor:SetFrameLevel((host.GetFrameLevel and host:GetFrameLevel() or 1) + 5)
    editor:RegisterForDrag()
    editor:SetScript("OnDragStart", nil)
    editor:SetScript("OnDragStop", nil)
    editor:SetScript("OnKeyDown", nil)
    if editor.titleBar then
        editor.titleBar:EnableMouse(false)
        editor.titleBar:RegisterForDrag()
        editor.titleBar:SetScript("OnDragStart", nil)
        editor.titleBar:SetScript("OnDragStop", nil)
        editor.titleBar:Show()
    end
    if editor.doneBtn then
        editor.doneBtn:Hide()
    end
    if editor.subtitle then
        if FluxMeterLayout.IsBlizzardBackend and FluxMeterLayout.IsBlizzardBackend() then
            editor.subtitle:SetText("blizzard · max 3 panes · edit in options")
        else
            editor.subtitle:SetText("edit in options · drag bars to resize")
        end
    end
    editorActive = true
    editor:Show()
    editor:Refresh()
    return editor
end

--- Fit editor into host: unscaled when it fits, otherwise uniform scale so nothing sticks out.
function FluxMeterLayout.FitEditorToHost(host, availW, availH)
    local editor = editorFrame
    if not editor or not host or editor._embedHost ~= host then
        return 0, 0
    end
    editor:SetScale(1)
    local ew = editor:GetWidth() or 800
    local eh = editor:GetHeight() or 520
    availW = availW or host:GetWidth() or ew
    availH = availH or eh
    if availW < 40 then availW = ew end
    if availH < 40 then availH = eh end

    local scale = 1
    if ew > availW + 1 then
        scale = math.min(scale, availW / ew)
    end
    -- Prefer fitting width; height can scroll in Ace. Only shrink for height if host is the viewport fill.
    if availH > 40 and availH < eh and availH >= 200 then
        -- Keep scale from width only; scrolling handles vertical overflow.
    end
    if scale < 0.45 then scale = 0.45 end
    if scale > 1 then scale = 1 end
    editor:SetScale(scale)
    local usedW = ew * scale
    local usedH = eh * scale
    host:SetSize(math.max(1, usedW), math.max(1, usedH))
    return usedW, usedH
end

function FluxMeterLayout.AttachToAceWidget(widget)
    if not widget or not widget.frame then return end
    local editor = FluxMeterLayout.AttachToHost(widget.frame)
    if not editor then return end
    widget.width = "fill"
    if widget.SetFullWidth then
        pcall(widget.SetFullWidth, widget, true)
    end
    local availW = widget.frame:GetWidth() or 0
    if availW < 40 and widget.frame.GetParent then
        local p = widget.frame:GetParent()
        availW = (p and p:GetWidth()) or 700
    end
    local usedW, usedH = FluxMeterLayout.FitEditorToHost(widget.frame, availW, nil)
    if usedH and usedH > 40 then
        if widget.SetHeight then widget:SetHeight(usedH) end
        widget.frame:SetHeight(usedH)
    end
    if usedW and usedW > 40 and widget.SetWidth then
        widget:SetWidth(usedW)
    end
end

function FluxMeterLayout.DetachFromAceWidget(widget)
    local editor = editorFrame
    if editor and editor._embedHost and widget and editor._embedHost == widget.frame then
        FluxMeterLayout.DetachFromHost()
    end
end

function FluxMeterLayout.IsEmbeddedInOptions()
    return editorFrame and editorFrame._embedHost ~= nil
end

function FluxMeterLayout.OpenEditor(anchor)
    LoadLibrary()
    if editorFrame and editorFrame._embedHost then
        FluxMeterLayout.DetachFromHost()
    end
    local editor = EnsureEditor()
    if not editor then return end
    RestoreStandaloneChrome(editor)
    if FluxWindowFrame and FluxWindowFrame.GetActiveTab and FluxWindowFrame.SwitchToTab then
        if FluxWindowFrame:GetActiveTab() ~= "Meter" then
            FluxWindowFrame:SwitchToTab("Meter")
        end
    end
    editorActive = true
    editor:ClearAllPoints()
    local host = FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame()
    if host and host:IsShown() then
        editor:SetPoint("RIGHT", host, "LEFT", -16, 0)
    else
        editor:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    end
    editor:Show()
    editor:Raise()
    editor:Refresh()
end

function FluxMeterLayout.Init()
    LoadLibrary()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    FluxMeterLayout.Init()
    self:UnregisterAllEvents()
end)

