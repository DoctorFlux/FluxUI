--[[
    ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua
    Consumables button module (flasks, potions, buff food, etc.)
    
    Features:
    - Configurable list of consumables with priority order
    - Preset system for different situations (raid, dungeon, etc.)
    - Left-click uses first eligible consumable (missing buff or <=5min remaining)
    - Right-click opens config window
    - WISP LOCK state when all consumables are active with >5min remaining
    - Correct cooldown overlay math (startTime = expirationTime - duration)
    
    SavedVariables: Uses _FluxUI_CharSavedVars.consumables (same pattern as FluxMinimapButtons)
    
    Compatible with all WoW versions via FluxAPICompat.lua
]]

local _, ns = ...

-- Create namespace
FluxNCConsumables = FluxNCConsumables or {}
local Module = FluxNCConsumables

-- Patch 12+ secret aura values: avoid raw == / compare on spellId, duration, expirationTime (FluxAPICompat)
local SafeCompare = ns and ns.API and ns.API.SafeCompare
local CanAccessValue = ns and ns.API and ns.API.CanAccessValue or function() return true end
local CoerceNumberLoose = ns and ns.API and ns.API.CoerceNumberLoose or function(v, default)
    default = default or 0
    if v == nil then return default end
    local ok, n = pcall(function()
        return (v + 0)
    end)
    if ok and type(n) == "number" and n == n and n < math.huge and n > -math.huge then
        return n
    end
    return default
end

local function SafeSpellIdEquals(a, b)
    if a == nil or b == nil then return false end
    if SafeCompare then
        return SafeCompare(a, b, "==") == true
    end
    local ok, eq = pcall(function()
        return a == b
    end)
    return ok and eq == true
end

-- CanAccessSecrets is the tainted-combat default on Forever; index scans go
-- empty. Spell-ID lookup (GetPlayerAuraBySpellID) is AllowedWhenTainted.
local function AurasRestricted()
    local Flux = _G.Flux
    local S = Flux and Flux.Secrets
    if S and S.AurasRestricted then
        return S.AurasRestricted() and true or false
    end
    return false
end

local function PublicAuraNumber(v)
    if v == nil then
        return nil
    end
    local Flux = _G.Flux
    local S = Flux and Flux.Secrets
    if S then
        if S.IsSecretValue and S.IsSecretValue(v) then
            return nil
        end
        if S.CanAccessValue and not S.CanAccessValue(v) then
            return nil
        end
    elseif not CanAccessValue(v) then
        return nil
    end
    local n = tonumber(v)
    if type(n) == "number" and n == n and n < math.huge and n > -math.huge then
        return n
    end
    return nil
end

local function PlayerHelpfulAura(index)
    if AurasRestricted() then
        return nil
    end
    local Flux = _G.Flux
    if Flux and Flux.Aura and Flux.Aura.GetDataByIndex then
        return Flux.Aura.GetDataByIndex("player", index, "HELPFUL")
    end
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
        if ok then
            return aura
        end
    end
    return nil
end

local heldBuffByKey = {}

local function PackAuraBuff(data, fallbackSpellID)
    if not data then
        return nil
    end
    local name, icon, count, duration, expirationTime, sid, inst, timeMod
    pcall(function()
        name = data.name
        icon = data.icon
        count = data.applications or data.charges or data.count or 0
        duration = data.duration
        expirationTime = data.expirationTime
        sid = data.spellId or data.spellID or fallbackSpellID
        inst = data.auraInstanceID
        timeMod = data.timeMod
    end)
    local durN = PublicAuraNumber(duration)
    local expN = PublicAuraNumber(expirationTime)
    local instN = PublicAuraNumber(inst)
    local now = GetTime()
    if expN and expN <= (now + 0.05) then
        return nil
    end
    local Flux = _G.Flux
    local Aura = Flux and Flux.Aura
    local durObj
    if instN and Aura and Aura.GetAuraDuration then
        durObj = Aura.GetAuraDuration("player", instN)
    end
    local maxDuration = durN or 0
    if maxDuration <= 0 and expN then
        local remaining = expN - now
        if remaining > 0 then
            maxDuration = remaining
        end
    end
    return {
        name = name,
        icon = icon,
        count = PublicAuraNumber(count) or 0,
        duration = durN or 0,
        maxDuration = maxDuration or 0,
        expirationTime = expN or 0,
        spellID = sid or fallbackSpellID,
        auraInstanceID = instN,
        durationObject = durObj,
        timeMod = PublicAuraNumber(timeMod),
        present = true,
    }
end

local function AuraDataFromSpellID(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    local Flux = _G.Flux
    local Aura = Flux and Flux.Aura
    local data
    if Aura and Aura.GetPlayerAuraBySpellID then
        data = Aura.GetPlayerAuraBySpellID(spellID)
    elseif C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, result = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok then
            data = result
        end
    end
    local packed = PackAuraBuff(data, spellID)
    if packed then
        return packed
    end
    local mapped
    if Aura and Aura.GetCooldownAuraBySpellID then
        mapped = Aura.GetCooldownAuraBySpellID(spellID)
    elseif C_UnitAuras and C_UnitAuras.GetCooldownAuraBySpellID then
        local ok, id = pcall(C_UnitAuras.GetCooldownAuraBySpellID, spellID)
        if ok then
            mapped = tonumber(id)
        end
    end
    if mapped and mapped ~= spellID then
        if Aura and Aura.GetPlayerAuraBySpellID then
            data = Aura.GetPlayerAuraBySpellID(mapped)
        elseif C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
            local ok, result = pcall(C_UnitAuras.GetPlayerAuraBySpellID, mapped)
            if ok then
                data = result
            end
        else
            data = nil
        end
        return PackAuraBuff(data, mapped)
    end
    return nil
end

local function MergeHeldBuff(key, hit)
    if not key then
        return hit
    end
    local last = heldBuffByKey[key]
    if not hit then
        if AurasRestricted() and last and last.present then
            local Flux = _G.Flux
            local Aura = Flux and Flux.Aura
            local inst = PublicAuraNumber(last.auraInstanceID)
            if inst and Aura and Aura.GetAuraDuration then
                local obj = Aura.GetAuraDuration("player", inst)
                if obj then
                    last.durationObject = obj
                    last.auraInstanceID = inst
                    return last
                end
                heldBuffByKey[key] = nil
                return nil
            end
            local exp = PublicAuraNumber(last.expirationTime)
            if exp and exp > (GetTime() + 0.05) then
                return last
            end
            if last.durationObject then
                return last
            end
        end
        heldBuffByKey[key] = nil
        return nil
    end
    if last then
        if (not hit.duration or hit.duration == 0) and last.duration and last.duration > 0 then
            hit.duration = last.duration
        end
        if (not hit.expirationTime or hit.expirationTime == 0) and last.expirationTime and last.expirationTime > 0 then
            hit.expirationTime = last.expirationTime
        end
        if (not hit.maxDuration or hit.maxDuration == 0) and last.maxDuration and last.maxDuration > 0 then
            hit.maxDuration = last.maxDuration
        end
        if not hit.durationObject then
            hit.durationObject = last.durationObject
        end
        if not hit.auraInstanceID then
            hit.auraInstanceID = last.auraInstanceID
        end
        if (not hit.timeMod or hit.timeMod == 0) and last.timeMod then
            hit.timeMod = last.timeMod
        end
        if hit.name == nil then
            hit.name = last.name
        end
    end
    heldBuffByKey[key] = hit
    return hit
end

local function BuffRemainingSeconds(buff)
    if not buff then
        return 0
    end
    local exp = PublicAuraNumber(buff.expirationTime) or (type(buff.expirationTime) == "number" and buff.expirationTime) or nil
    if exp and exp > 0 then
        local rem = exp - GetTime()
        local tmod = PublicAuraNumber(buff.timeMod)
        if tmod and tmod > 0 and tmod ~= 1 then
            rem = rem / tmod
        end
        if rem > 0 then
            return rem
        end
        return 0
    end
    if (buff.durationObject or buff.present) and AurasRestricted() then
        return 86400
    end
    return 0
end

Module.GetBuffRemaining = BuffRemainingSeconds

local ClearConsumableAuraTimer, ApplyConsumableAuraTimer

-- Constants
Module.COLUMN_PRIORITY = 5
Module.ORDER = 1

-- Placeholder icon and WISP LOCK icon
local PLACEHOLDER_ICON = "Interface\\Icons\\inv_potion_41"
local PLACEHOLDER_LABEL = "Consumables"
local WISP_LOCK_ICON = "Interface\\Icons\\Spell_Nature_WispSplode"

-- Refresh threshold (5 minutes = 300 seconds)
local REFRESH_THRESHOLD = 300

-- State
Module._grid = nil
Module._button = nil
Module._registered = false
Module._isPlaceholder = true
Module._isWispLocked = false
Module._wispLockMinRemaining = 0
Module._wispLockBuff = nil
Module._wispLockLastCheck = 0
Module._wispLockStableTime = 0
Module._lastUpdateTime = 0
Module._updateDebounceTime = 0.2  -- Debounce updates to 200ms
-- Combat safety state
Module._pendingItemChange = nil  -- Queue for item change during combat: {itemID = itemID, buff = buff}
Module._pendingWispLockChange = nil  -- Queue for WISP LOCK state change during combat: {minRemaining = minRemaining, minRemainingBuff = minRemainingBuff}
Module._inCombat = false  -- Track combat state
Module._pendingKeybindUpdate = false  -- Flag to update keybindings after combat
Module._auraCoalesceTimer = false  -- pending coalesced UNIT_AURA UpdateButtonState (reduces SetAttribute churn)

-- Timer shim for legacy clients
local Timer = C_Timer or {}
if not Timer.After then
    function Timer.After(delay, cb)
        local f = CreateFrame("Frame")
        local t = 0
        f:SetScript("OnUpdate", function(self, dt)
            t = t + dt
            if t >= (tonumber(delay) or 0) then
                self:SetScript("OnUpdate", nil)
                pcall(cb)
                self:Hide()
            end
        end)
        return f
    end
end

-- Compatibility function for math.isfinite (Lua 5.1 doesn't have it)
local function isfinite(n)
    if type(n) ~= "number" then return false end
    -- Check for NaN (NaN != NaN)
    if n ~= n then return false end
    -- Check for infinity
    if n == math.huge or n == -math.huge then return false end
    return true
end

-- ============================================================================
-- SAVED VARIABLES (Mirror FluxMinimapButtons.lua pattern)
-- ============================================================================

local function LoadSavedVars()
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    
    if not _FluxUI_CharSavedVars.consumables then
        _FluxUI_CharSavedVars.consumables = {
            presets = {
                ["default"] = { items = {} },
            },
            activePreset = "default",
            refreshThreshold = 300,  -- Default 5 minutes (300 seconds)
        }
    end
    
    -- Ensure default preset always exists
    if not _FluxUI_CharSavedVars.consumables.presets then
        _FluxUI_CharSavedVars.consumables.presets = {}
    end
    if not _FluxUI_CharSavedVars.consumables.presets["default"] then
        _FluxUI_CharSavedVars.consumables.presets["default"] = { items = {} }
    end
    
    -- Ensure activePreset is valid
    local activePreset = _FluxUI_CharSavedVars.consumables.activePreset
    if not activePreset or not _FluxUI_CharSavedVars.consumables.presets[activePreset] then
        _FluxUI_CharSavedVars.consumables.activePreset = "default"
    end
    
    -- Ensure refreshThreshold exists (for existing characters)
    if not _FluxUI_CharSavedVars.consumables.refreshThreshold then
        _FluxUI_CharSavedVars.consumables.refreshThreshold = 300  -- Default 5 minutes
    end

    -- Ground-placed item aura bindings (feasts, cauldrons, etc.)
    if type(_FluxUI_CharSavedVars.consumables.groundAuras) ~= "table" then
        _FluxUI_CharSavedVars.consumables.groundAuras = {}
    end
    do
        local normalized = {}
        for key, binding in pairs(_FluxUI_CharSavedVars.consumables.groundAuras) do
            local id = tonumber(key)
            if id and type(binding) == "table" then
                local spellID = tonumber(binding.spellID)
                if spellID and spellID > 0 then
                    normalized[id] = {
                        spellID = spellID,
                        name = (type(binding.name) == "string" and binding.name ~= "") and binding.name or nil,
                    }
                end
            end
        end
        _FluxUI_CharSavedVars.consumables.groundAuras = normalized
    end

    -- SavedVariables may deserialize restockTargets keys as strings.
    for _, preset in pairs(_FluxUI_CharSavedVars.consumables.presets or {}) do
        if type(preset.restockTargets) == "table" then
            local normalized = {}
            for key, qty in pairs(preset.restockTargets) do
                local id = tonumber(key)
                local n = tonumber(qty)
                if id and n and n > 0 then
                    normalized[id] = n
                end
            end
            preset.restockTargets = normalized
        end
    end
    
    return _FluxUI_CharSavedVars.consumables
end

local function NotifyRespecConsumablesConfigChanged()
    local F = _G.FluxRespec
    if F and F.Fire then
        pcall(F.Fire, "CONSUMABLES_CONFIG_CHANGED")
    end
end

-- Get the current consumables data
function Module.GetData()
    return LoadSavedVars()
end

-- Get the active preset
function Module.GetActivePreset()
    local data = LoadSavedVars()
    return data.activePreset or "default"
end

-- ============================================================================
-- CHRONOBOON HELPER FUNCTIONS (for GetItems and restock target functions)
-- ============================================================================

-- Initialize saved variables for restock targets (needed by helper functions)
local function InitRestockSavedVars()
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    
    if not _FluxUI_CharSavedVars.VendorAuto then
        _FluxUI_CharSavedVars.VendorAuto = {
            autoRepair = false,
            autoRestock = false,
            autoSellGray = false,
            restockItems = {}
        }
    end
    
    if not _FluxUI_CharSavedVars.VendorAuto.restockItems then
        _FluxUI_CharSavedVars.VendorAuto.restockItems = {}
    end
    
    return _FluxUI_CharSavedVars.VendorAuto
end

-- Known Chronoboon item IDs (Classic Era / Anniversary / SoD variants).
local REGULAR_CHRONOBOON_IDS = {
    [184937] = true, -- Chronoboon Displacer
}
local SUPERCHRONOBOON_IDS = {
    [184938] = true, -- Supercharged Chronoboon Displacer
}

-- Runtime + saved discovery for forked client variants (e.g. SoD vs Era).
local discoveredRegularChronoboonIDs = {}
local discoveredSuperChronoboonIDs = {}

local function LoadDiscoveredChronoboonVariants()
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    local stored = _FluxUI_CharSavedVars.chronoboonVariants
    if type(stored) ~= "table" then
        return
    end
    for id in pairs(stored.regular or {}) do
        id = tonumber(id)
        if id then
            discoveredRegularChronoboonIDs[id] = true
        end
    end
    for id in pairs(stored.super or {}) do
        id = tonumber(id)
        if id then
            discoveredSuperChronoboonIDs[id] = true
        end
    end
end

local function PersistDiscoveredChronoboonVariant(itemID, kind)
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    _FluxUI_CharSavedVars.chronoboonVariants = _FluxUI_CharSavedVars.chronoboonVariants or {}
    local stored = _FluxUI_CharSavedVars.chronoboonVariants
    stored.regular = stored.regular or {}
    stored.super = stored.super or {}
    if kind == "super" then
        stored.super[tostring(itemID)] = true
    else
        stored.regular[tostring(itemID)] = true
    end
end

local function RegisterChronoboonVariant(itemID, kind)
    itemID = tonumber(itemID)
    if not itemID or not kind then
        return
    end
    if kind == "super" then
        if discoveredSuperChronoboonIDs[itemID] then
            return
        end
        discoveredSuperChronoboonIDs[itemID] = true
        PersistDiscoveredChronoboonVariant(itemID, kind)
    elseif kind == "regular" then
        if discoveredRegularChronoboonIDs[itemID] then
            return
        end
        discoveredRegularChronoboonIDs[itemID] = true
        PersistDiscoveredChronoboonVariant(itemID, kind)
    end
end

LoadDiscoveredChronoboonVariants()

local function IsKnownRegularChronoboonID(itemID)
    itemID = tonumber(itemID)
    return itemID and (REGULAR_CHRONOBOON_IDS[itemID] == true or discoveredRegularChronoboonIDs[itemID] == true)
end

local function IsKnownSuperChronoboonID(itemID)
    itemID = tonumber(itemID)
    return itemID and (SUPERCHRONOBOON_IDS[itemID] == true or discoveredSuperChronoboonIDs[itemID] == true)
end

local function IsKnownChronoboonID(itemID)
    return IsKnownRegularChronoboonID(itemID) or IsKnownSuperChronoboonID(itemID)
end

-- Chronoboon is Classic Era (Vanilla) only — not TBC+ or Retail.
function Module.IsChronoboonFeatureEnabled()
    return FLUX_API and FLUX_API.isClassicEra == true
end

function Module.GetDefaultChronoboonItemID()
    if not Module.IsChronoboonFeatureEnabled() then
        return nil
    end
    return 184937
end

function Module.GetDefaultSuperChronoboonItemID()
    if not Module.IsChronoboonFeatureEnabled() then
        return nil
    end
    for itemID in pairs(SUPERCHRONOBOON_IDS) do
        return itemID
    end
    for itemID in pairs(discoveredSuperChronoboonIDs) do
        return itemID
    end
    return 184938
end

local function ItemsListEqual(a, b)
    if not a or not b or #a ~= #b then
        return false
    end
    for i = 1, #a do
        if tonumber(a[i]) ~= tonumber(b[i]) then
            return false
        end
    end
    return true
end

-- Fast chronoboon check for list filtering (known IDs only; no name lookup).
local function IsKnownChronoboonListEntry(itemID)
    itemID = tonumber(itemID)
    return itemID and IsKnownChronoboonID(itemID)
end

local function StripChronoboonFromItemList(items)
    local out = {}
    for i = 1, #(items or {}) do
        local id = tonumber(items[i])
        if id and not IsKnownChronoboonListEntry(id) then
            out[#out + 1] = id
        end
    end
    return out
end

-- One regular + optional super slot at end of preset storage (restock target key).
function Module.EnsureChronoboonPresetEntry(canonicalID)
    canonicalID = tonumber(canonicalID)
    if not canonicalID or not Module.IsChronoboonFeatureEnabled() then
        return false
    end
    if Module.IsSuperchargedChronoboonItem and Module.IsSuperchargedChronoboonItem(canonicalID) then
        return false
    end
    local data = LoadSavedVars()
    local presetName = data.activePreset or "default"
    data.presets[presetName] = data.presets[presetName] or { items = {} }
    local preset = data.presets[presetName]
    preset.items = preset.items or {}
    local stripped = StripChronoboonFromItemList(preset.items)
    stripped[#stripped + 1] = canonicalID
    if ItemsListEqual(preset.items, stripped) then
        return true
    end
    preset.items = stripped
    return true
end

local function GetSuperChronoboonItemIDInBags()
    if not Module.HasSuperchargedChronoboonInBags() then
        return nil
    end
    local collected = Module.CollectChronoboonIDs(false)
    for _, chronoboonID in ipairs(collected.super or {}) do
        if Module.GetItemCount(chronoboonID) > 0 then
            return chronoboonID
        end
    end
    if collected.super and collected.super[1] then
        return collected.super[1]
    end
    return Module.GetDefaultSuperChronoboonItemID()
end

local SyncChronoboonPresetStorage

-- Regular Chronoboon goes first on the button when world buffs are active.
local function SelectRegularChronoboonForButton()
    if not Module.IsChronoboonFeatureEnabled() then
        return nil
    end
    if not Module.HasWorldBuff() then
        return nil
    end

    local collected = Module.CollectChronoboonIDs(false)
    for _, chronoboonID in ipairs(collected.regular or {}) do
        if not Module.IsSuperchargedChronoboonItem(chronoboonID)
            and Module.GetItemCount(chronoboonID) > 0 then
            return chronoboonID
        end
    end
    if Module.GetChronoboonBagCount() > 0 then
        return (Module.GetCanonicalChronoboonID and Module.GetCanonicalChronoboonID())
            or Module.GetDefaultChronoboonItemID()
    end
    return (Module.GetCanonicalChronoboonID and Module.GetCanonicalChronoboonID())
        or Module.GetDefaultChronoboonItemID()
end

-- Supercharged Chronoboon: last by default; first when a world buff is active (unboon before boon).
local function SelectSuperChronoboonForButton()
    if not Module.IsChronoboonFeatureEnabled() then
        return nil
    end
    if not Module.HasSuperchargedChronoboonBuff() and not Module.HasSuperchargedChronoboonInBags() then
        return nil
    end
    return GetSuperChronoboonItemIDInBags()
end

-- Search through saved presets to find a regular Chronoboon item ID.
local function FindChronoboonIDFromSavedItems()
    local data = LoadSavedVars()
    local presetName = data.activePreset or "default"
    local preset = data.presets and data.presets[presetName]
    if preset and preset.items then
        for _, itemID in ipairs(preset.items) do
            if IsKnownRegularChronoboonID(itemID) or (
                not IsKnownSuperChronoboonID(itemID) and Module.IsChronoboonItem(itemID)
                and not Module.IsSuperchargedChronoboonItem(itemID)
            ) then
                return itemID
            end
        end
    end
    for _, p in pairs(data.presets or {}) do
        if p.items then
            for _, itemID in ipairs(p.items) do
                if IsKnownRegularChronoboonID(itemID) or (
                    not IsKnownSuperChronoboonID(itemID) and Module.IsChronoboonItem(itemID)
                    and not Module.IsSuperchargedChronoboonItem(itemID)
                ) then
                    return itemID
                end
            end
        end
    end
    return nil
end

-- Search through restockItems to find any regular Chronoboon item ID key.
local function FindChronoboonIDFromRestockItems()
    local settings = InitRestockSavedVars()
    for key, value in pairs(settings.restockItems or {}) do
        if type(value) == "table" then
            local itemID = tonumber(key)
            if itemID and not IsKnownSuperChronoboonID(itemID) then
                if IsKnownRegularChronoboonID(itemID) or Module.IsChronoboonItem(itemID) then
                    if not Module.IsSuperchargedChronoboonItem(itemID) then
                        return itemID
                    end
                end
            end
        end
    end
    return nil
end

-- User consumables only (config drag/drop grid — no Chronoboon entries).
function Module.GetConfigItems()
    local data = LoadSavedVars()
    local presetName = data.activePreset or "default"
    local preset = data.presets[presetName]
    local items = {}
    if preset and preset.items then
        items = preset.items
    end
    return StripChronoboonFromItemList(items)
end

function Module.SetConfigItems(userItems)
    userItems = StripChronoboonFromItemList(userItems or {})
    Module.SetItems(userItems)
    local FVA = _G.FluxVendorAuto
    if FVA and FVA.InvalidateRestockOptionsPanelCache then
        FVA.InvalidateRestockOptionsPanelCache()
    end
    if Module.IsChronoboonFeatureEnabled() then
        local chronoID = FindChronoboonIDFromRestockItems()
            or (Module.GetCanonicalChronoboonID and Module.GetCanonicalChronoboonID())
            or Module.GetDefaultChronoboonItemID()
        if chronoID then
            Module.EnsureChronoboonPresetEntry(chronoID)
        end
    end
end

-- Get items from active preset (button/flyout order with Chronoboon bookends).
function Module.GetItems()
    local data = LoadSavedVars()
    local presetName = data.activePreset or "default"
    local preset = data.presets[presetName]
    local items = {}
    if preset and preset.items then
        items = preset.items
    end

    local regularItems = StripChronoboonFromItemList(items)

    if not Module.IsChronoboonFeatureEnabled() then
        if not ItemsListEqual(items, regularItems) then
            Module.SetItems(regularItems)
        end
        return regularItems
    end

    local filteredItems = {}
    for _, itemID in ipairs(regularItems) do
        filteredItems[#filteredItems + 1] = itemID
    end

    local regularChronoboonID = SelectRegularChronoboonForButton()
    local superChronoboonID = SelectSuperChronoboonForButton()

    -- World buff + supercharged: unboon first, then regular Chronoboon, then other consumables.
    if regularChronoboonID and superChronoboonID then
        table.insert(filteredItems, 1, superChronoboonID)
        table.insert(filteredItems, 2, regularChronoboonID)
    else
        if regularChronoboonID then
            table.insert(filteredItems, 1, regularChronoboonID)
        end
        if superChronoboonID then
            filteredItems[#filteredItems + 1] = superChronoboonID
        end
    end

    SyncChronoboonPresetStorage(items, regularItems)

    return filteredItems
end

-- Get refresh threshold (in seconds)
function Module.GetRefreshThreshold()
    local data = LoadSavedVars()
    return data.refreshThreshold or 300  -- Default 5 minutes
end

-- Set refresh threshold (in seconds)
function Module.SetRefreshThreshold(seconds)
    local data = LoadSavedVars()
    data.refreshThreshold = math.max(0, math.floor(seconds))  -- Ensure non-negative integer
    Module.UpdateButtonState(true)  -- Force update
end

-- Set items for active preset
function Module.SetItems(items)
    local data = LoadSavedVars()
    local presetName = data.activePreset or "default"
    if not data.presets[presetName] then
        data.presets[presetName] = { items = {} }
    end
    data.presets[presetName].items = items or {}
end

-- Add item to active preset
function Module.AddItem(itemID)
    if not itemID then return false end
    if Module.IsChronoboonItem(itemID) then return false end
    local items = Module.GetConfigItems()
    
    -- Check for duplicate
    for _, id in ipairs(items) do
        if id == itemID then
            return false
        end
    end
    
    table.insert(items, itemID)
    Module.SetConfigItems(items)
    -- Default restock target to 1 when adding a new consumable.
    local existing = Module.GetPresetRestockTarget and Module.GetPresetRestockTarget(itemID)
    if not existing or existing <= 0 then
        if Module.SetPresetRestockTarget then
            Module.SetPresetRestockTarget(itemID, 1)
        end
    end
    return true
end

-- Remove item from active preset
function Module.RemoveItem(itemID)
    if not itemID then return false end
    if Module.IsChronoboonItem(itemID) then return false end
    local items = Module.GetConfigItems()
    
    for i, id in ipairs(items) do
        if id == itemID then
            table.remove(items, i)
            Module.SetConfigItems(items)
            if Module.SetPresetRestockTarget then
                Module.SetPresetRestockTarget(itemID, 0)
            end
            return true
        end
    end
    return false
end

-- Remove item by index (config grid indices — user consumables only)
function Module.RemoveItemAtIndex(index)
    local items = Module.GetConfigItems()
    if index >= 1 and index <= #items then
        local itemID = items[index]
        table.remove(items, index)
        Module.SetConfigItems(items)
        if itemID and Module.SetPresetRestockTarget then
            Module.SetPresetRestockTarget(itemID, 0)
        end
        return true
    end
    return false
end

-- Move item from one index to another (insert-style, config grid only)
function Module.MoveItem(fromIndex, toIndex)
    local items = Module.GetConfigItems()
    if fromIndex < 1 or fromIndex > #items then return false end
    if toIndex < 1 then toIndex = 1 end
    if toIndex > #items then toIndex = #items end
    
    local item = table.remove(items, fromIndex)
    table.insert(items, toIndex, item)
    Module.SetConfigItems(items)
    return true
end

-- Insert item at a specific config grid index
function Module.AddItemAtIndex(itemID, index)
    if not itemID then return false end
    if Module.IsChronoboonItem(itemID) then return false end
    local items = Module.GetConfigItems()

    for _, id in ipairs(items) do
        if id == itemID then
            return false
        end
    end

    index = math.max(1, math.min(index or (#items + 1), #items + 1))
    table.insert(items, index, itemID)
    Module.SetConfigItems(items)
    local existing = Module.GetPresetRestockTarget and Module.GetPresetRestockTarget(itemID)
    if not existing or existing <= 0 then
        if Module.SetPresetRestockTarget then
            Module.SetPresetRestockTarget(itemID, 1)
        end
    end
    return true
end

-- Set active preset
function Module.SetActivePreset(presetName)
    local data = LoadSavedVars()
    if data.presets[presetName] then
        data.activePreset = presetName
        NotifyRespecConsumablesConfigChanged()
        return true
    end
    return false
end

-- Create new preset (empty, not cloned)
function Module.CreatePreset(presetName)
    if not presetName or presetName == "" then return false end
    local data = LoadSavedVars()
    
    if data.presets[presetName] then
        return false -- Already exists
    end
    
    -- Create empty preset (do not clone current items)
    data.presets[presetName] = { items = {} }
    data.activePreset = presetName
    NotifyRespecConsumablesConfigChanged()
    return true
end

-- Delete preset
function Module.DeletePreset(presetName)
    if not presetName or presetName == "default" then return false end
    local data = LoadSavedVars()
    
    if not data.presets[presetName] then
        return false
    end
    
    data.presets[presetName] = nil
    
    -- Switch to default if we deleted the active preset
    if data.activePreset == presetName then
        data.activePreset = "default"
    end

    NotifyRespecConsumablesConfigChanged()
    return true
end

-- Get all preset names
function Module.GetPresetNames()
    local data = LoadSavedVars()
    local names = {}
    for name in pairs(data.presets) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- ============================================================================
-- CHRONOBOON RESTOCK TARGET FUNCTIONS
-- ============================================================================

-- Targets are stored per preset so switching presets switches targets too.
local function GetPresetRestockTargets(presetName)
    local data = LoadSavedVars()
    presetName = presetName or data.activePreset or "default"
    local preset = data.presets[presetName]
    if not preset then
        return nil
    end
    preset.restockTargets = preset.restockTargets or {}
    return preset.restockTargets
end

-- Get canonical regular Chronoboon itemID (used as key for restock target).
local function GetCanonicalChronoboonID()
    if not Module.IsChronoboonFeatureEnabled() then
        return nil
    end
    if Module.CollectChronoboonIDs then
        local collected = Module.CollectChronoboonIDs(true)
        if collected.regular and collected.regular[1] then
            return collected.regular[1]
        end
    else
        local chronoboonIDs = Module.FindChronoboonItemIDs()
        for _, id in ipairs(chronoboonIDs) do
            if not Module.IsSuperchargedChronoboonItem(id) then
                return id
            end
        end
    end

    local savedID = FindChronoboonIDFromSavedItems()
    if savedID then
        return savedID
    end

    local restockID = FindChronoboonIDFromRestockItems()
    if restockID then
        return restockID
    end

    return Module.GetDefaultChronoboonItemID()
end

SyncChronoboonPresetStorage = function(items, regularItems)
    if not Module.IsChronoboonFeatureEnabled() then
        if not ItemsListEqual(items, regularItems) then
            Module.SetItems(regularItems)
        end
        return
    end

    local preservedChronoboonID = FindChronoboonIDFromRestockItems()
        or FindChronoboonIDFromSavedItems()
        or GetCanonicalChronoboonID()
        or Module.GetDefaultChronoboonItemID()
    local updatedItems = {}
    for _, itemID in ipairs(regularItems) do
        updatedItems[#updatedItems + 1] = itemID
    end
    if preservedChronoboonID then
        updatedItems[#updatedItems + 1] = preservedChronoboonID
    end
    if not ItemsListEqual(items, updatedItems) then
        Module.SetItems(updatedItems)
    end
end

-- Read Chronoboon target from preset + legacy restockItems without circular getters.
local function ReadChronoboonTargetForID(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local targets = GetPresetRestockTargets()
    if targets then
        local qty = targets[itemID] or targets[tostring(itemID)]
        if qty ~= nil then
            return tonumber(qty) or 0
        end
    end
    local settings = InitRestockSavedVars()
    local data = settings.restockItems and settings.restockItems[itemID]
    if data and data.targetQuantity ~= nil then
        return tonumber(data.targetQuantity) or 0
    end
    return 0
end

function Module.GetCanonicalChronoboonID()
    return GetCanonicalChronoboonID()
end

-- Get restock target for Chronoboon items (shared between regular and SuperCharged)
function Module.GetChronoboonRestockTarget()
    if not Module.IsChronoboonFeatureEnabled() then
        return 0
    end
    if Module.ReadChronoboonRestockTargetCombined then
        return Module.ReadChronoboonRestockTargetCombined()
    end
    local canonicalID = GetCanonicalChronoboonID()
    if not canonicalID then
        return 0
    end
    return ReadChronoboonTargetForID(canonicalID)
end

-- Write legacy + active-preset targets for the canonical Chronoboon ID.
local function WriteChronoboonTarget(canonicalID, targetQuantity)
    canonicalID = tonumber(canonicalID)
    if not canonicalID then
        return false
    end
    local settings = InitRestockSavedVars()
    local existing = settings.restockItems[canonicalID]
    if type(existing) ~= "table" then
        existing = {}
    end
    settings.restockItems[canonicalID] = {
        targetQuantity = targetQuantity,
        countBank = existing.countBank,
        bankRestock = existing.bankRestock,
        bankStash = existing.bankStash,
    }

    local data = LoadSavedVars()
    local presetName = data.activePreset or "default"
    data.presets[presetName] = data.presets[presetName] or { items = {} }
    local preset = data.presets[presetName]
    preset.restockTargets = preset.restockTargets or {}
    if targetQuantity > 0 then
        preset.restockTargets[canonicalID] = targetQuantity
        preset.restockTargets[tostring(canonicalID)] = nil
    else
        preset.restockTargets[canonicalID] = nil
        preset.restockTargets[tostring(canonicalID)] = nil
    end
    return true
end

-- Set restock target for Chronoboon items (shared between regular and SuperCharged)
function Module.SetChronoboonRestockTarget(targetQuantity)
    if not Module.IsChronoboonFeatureEnabled() then
        return false
    end
    targetQuantity = math.max(0, math.min(999, tonumber(targetQuantity) or 0))
    local canonicalID = GetCanonicalChronoboonID()
        or FindChronoboonIDFromRestockItems()
        or FindChronoboonIDFromSavedItems()
        or Module.GetDefaultChronoboonItemID()

    if not canonicalID then
        return false
    end

    Module.EnsureChronoboonPresetEntry(canonicalID)

    if not WriteChronoboonTarget(canonicalID, targetQuantity) then
        return false
    end

    local FVA = _G.FluxVendorAuto
    if FVA and FVA.RefreshMerchantOptionsCheckboxes then
        pcall(FVA.RefreshMerchantOptionsCheckboxes)
    end
    if _G.FluxBankRestockButton and _G.FluxBankRestockButton.Refresh then
        pcall(_G.FluxBankRestockButton.Refresh)
    end
    if _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive()
        and _G.FluxRestockPanel_RequestRefresh then
        pcall(_G.FluxRestockPanel_RequestRefresh)
    end
    return true
end

-- ============================================================================
-- PER-PRESET RESTOCK TARGETS (bank restock for consumables)
-- ============================================================================

-- Read the active preset's restock target for an item. Chronoboon falls back to
-- the legacy (global) Chronoboon target for backward compatibility.
function Module.GetPresetRestockTarget(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    if Module.IsChronoboonItem and Module.IsChronoboonItem(itemID)
        and not Module.IsSuperchargedChronoboonItem(itemID) then
        if Module.ReadChronoboonRestockTargetCombined then
            return Module.ReadChronoboonRestockTargetCombined()
        end
        return ReadChronoboonTargetForID(itemID)
    end
    local targets = GetPresetRestockTargets()
    if targets then
        local qty = targets[itemID] or targets[tostring(itemID)]
        if qty ~= nil then
            return tonumber(qty) or 0
        end
    end
    return 0
end

-- Set the active preset's restock target for an item (0 clears it).
function Module.SetPresetRestockTarget(itemID, qty, skipNotify)
    itemID = tonumber(itemID)
    if not itemID then
        return
    end
    qty = math.max(0, math.min(999, tonumber(qty) or 0))
    local data = LoadSavedVars()
    local presetName = data.activePreset or "default"
    data.presets[presetName] = data.presets[presetName] or { items = {} }
    local preset = data.presets[presetName]
    preset.restockTargets = preset.restockTargets or {}
    if qty > 0 then
        preset.restockTargets[itemID] = qty
        preset.restockTargets[tostring(itemID)] = nil
    else
        preset.restockTargets[itemID] = nil
        preset.restockTargets[tostring(itemID)] = nil
    end
    -- Keep the legacy Chronoboon target in sync so existing UI still works.
    if Module.IsChronoboonItem and Module.IsChronoboonItem(itemID)
        and not Module.IsSuperchargedChronoboonItem(itemID) then
        local canonical = GetCanonicalChronoboonID() or itemID
        Module.EnsureChronoboonPresetEntry(canonical)
        WriteChronoboonTarget(canonical, qty)
    end
    local FVA = _G.FluxVendorAuto
    if FVA and FVA.InvalidateRestockOptionsPanelCache then
        FVA.InvalidateRestockOptionsPanelCache()
    end
    if FVA and FVA.RefreshMerchantOptionsCheckboxes then
        if skipNotify then
            pcall(FVA.RefreshMerchantOptionsCheckboxes, {
                skipRestockPanelRebuild = true,
                skipOptionsNotify = true,
            })
        else
            pcall(FVA.RefreshMerchantOptionsCheckboxes)
        end
    end
    if _G.FluxBankRestockButton and _G.FluxBankRestockButton.Refresh then
        pcall(_G.FluxBankRestockButton.Refresh)
    end
    if _G.FluxRestockPanel_IsActive and _G.FluxRestockPanel_IsActive() then
        if skipNotify and _G.FluxRestockPanel_RefreshCellData then
            pcall(_G.FluxRestockPanel_RefreshCellData)
        elseif _G.FluxRestockPanel_RequestRefresh then
            pcall(_G.FluxRestockPanel_RequestRefresh)
        end
    end
end

-- Raw preset item IDs for the FluxUI restock options grid (not flyout-filtered).
function Module.GetRestockUIItemIDs()
    local data = LoadSavedVars()
    local presetName = data.activePreset or "default"
    local preset = data.presets and data.presets[presetName]
    local seen = {}
    local out = {}
    if preset and preset.items then
        for _, rawID in ipairs(preset.items) do
            local id = tonumber(rawID)
            if id and not seen[id] and not IsKnownChronoboonListEntry(id) then
                seen[id] = true
                out[#out + 1] = id
            end
        end
    end
    if Module.IsChronoboonFeatureEnabled() then
        local chronoID = GetCanonicalChronoboonID()
        if chronoID then
            local id = tonumber(chronoID)
            if id and not seen[id] and not Module.IsSuperchargedChronoboonItem(id) then
                seen[id] = true
                out[#out + 1] = id
            end
        end
    end
    return out
end

function Module.IsRestockUIItem(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    for _, id in ipairs(Module.GetRestockUIItemIDs()) do
        if id == itemID then
            return true
        end
    end
    return false
end

-- Total remaining charges of a charged item across bags (FluxInv SoT; fail closed).
function Module.GetItemChargeCount(itemID, includeBank)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local inv = _G.FluxInv
    if not inv then
        return 0
    end
    if inv.GetLiveCount then
        return inv.GetLiveCount(itemID, {
            includeBank = includeBank == true,
            charges = true,
        }) or 0
    end
    if inv.GetCount then
        return inv.GetCount(itemID, {
            includeBank = includeBank == true,
            charges = true,
        }) or 0
    end
    return 0
end

-- Register a bank-restock provider that pulls the active preset's items
-- (charge-aware for weapon temp enchants) up to their targets. Deferred because
-- the registry module loads after this file.
local consumablesBankProviderRegistered = false
local function TryRegisterConsumablesBankProvider()
    if consumablesBankProviderRegistered then
        return
    end
    local Registry = _G.FluxRestockItemRegistry
    if not (Registry and Registry.RegisterProvider) then
        return
    end
    consumablesBankProviderRegistered = true
    Registry.RegisterProvider("consumables", function()
        local out = {}
        local seen = {}
        for _, itemID in ipairs(Module.GetRestockUIItemIDs()) do
            itemID = tonumber(itemID)
            if itemID and not seen[itemID] then
                if Module.IsSuperchargedChronoboonItem and Module.IsSuperchargedChronoboonItem(itemID) then
                    -- Supercharged Chronoboon has no restock target.
                else
                seen[itemID] = true
                local target = Module.GetPresetRestockTarget(itemID)
                if target and target > 0 then
                    local isChronoboon = Module.IsChronoboonItem
                        and Module.IsChronoboonItem(itemID)
                        and not (Module.IsSuperchargedChronoboonItem and Module.IsSuperchargedChronoboonItem(itemID))
                    local isCharge
                    if Registry.IsChargeItem then
                        isCharge = Registry.IsChargeItem(itemID)
                    else
                        isCharge = Module.IsWeaponEnchantItem and Module.IsWeaponEnchantItem(itemID)
                    end
                    local maxStack
                    if isCharge and Registry.GetItemMaxCharges then
                        maxStack = Registry.GetItemMaxCharges(itemID)
                    elseif Registry.GetItemMaxStack then
                        maxStack = Registry.GetItemMaxStack(itemID)
                    end
                    out[#out + 1] = {
                        itemID = itemID,
                        target = target,
                        mode = isCharge and "charge" or "stack",
                        maxStack = maxStack,
                        restock = true,
                        stash = false,
                        isChronoboon = isChronoboon or nil,
                    }
                end
                end
            end
        end
        return out
    end)
end
Module.TryRegisterConsumablesBankProvider = TryRegisterConsumablesBankProvider

local function SanitizeAllPresetChronoboonEntries()
    if not Module.IsChronoboonFeatureEnabled() then
        return
    end
    local data = LoadSavedVars()
    for _, preset in pairs(data.presets or {}) do
        if preset.items then
            local chronoCount = 0
            for _, id in ipairs(preset.items) do
                if IsKnownChronoboonListEntry(id) then
                    chronoCount = chronoCount + 1
                end
            end
            if chronoCount > 1 then
                local regular = StripChronoboonFromItemList(preset.items)
                local keep
                for _, id in ipairs(preset.items) do
                    if IsKnownRegularChronoboonID(id) then
                        keep = id
                        break
                    end
                end
                keep = keep or Module.GetDefaultChronoboonItemID()
                if keep then
                    regular[#regular + 1] = keep
                end
                preset.items = regular
            end
        end
    end
end

local consumablesProviderFrame = CreateFrame("Frame")
consumablesProviderFrame:RegisterEvent("PLAYER_LOGIN")
consumablesProviderFrame:RegisterEvent("ADDON_LOADED")
consumablesProviderFrame:SetScript("OnEvent", function(_, event, arg1)
    -- Restock registry loads later in the same addon TOC; ADDON_LOADED fires after all files.
    if event == "ADDON_LOADED" and (arg1 == "_FluxUI" or arg1 == addonName) then
        TryRegisterConsumablesBankProvider()
    elseif event == "PLAYER_LOGIN" then
        SanitizeAllPresetChronoboonEntries()
        TryRegisterConsumablesBankProvider()
    end
end)
if C_Timer and C_Timer.After then
    C_Timer.After(0, TryRegisterConsumablesBankProvider)
    C_Timer.After(1, TryRegisterConsumablesBankProvider)
    C_Timer.After(5, TryRegisterConsumablesBankProvider)
end

-- ============================================================================
-- BUFF DETECTION HELPERS
-- ============================================================================

-- Get item info with caching
local itemInfoCache = {}
local function GetCachedItemInfo(itemID)
    if itemInfoCache[itemID] then
        return unpack(itemInfoCache[itemID])
    end
    
    local name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
    if name then
        itemInfoCache[itemID] = {name, link, icon}
        return name, link, icon
    end
    return nil, nil, nil
end

-- Bags only (never bank / warband). Extra Buttons SoT; fail closed without inventory.
local BAG_OWNED_OPTS = {
    charges = true,
    bags = true,
    bank = false,
    warband = false,
    equipped = false,
    includeBank = false,
}

local function ShouldHoldItemIdentity()
    local B = _G.FluxEBSConsumableBridge
    if B and B.ShouldHoldItemIdentity then
        return B.ShouldHoldItemIdentity() and true or false
    end
    local BestMod = _G.FluxConsumableBest
    if BestMod and BestMod.ShouldSoftHoldOwned then
        return BestMod.ShouldSoftHoldOwned() and true or false
    end
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.SnapshotLooksCollapsed and api.SnapshotLooksCollapsed() then
        return true
    end
    return false
end

function Module.GetItemCount(itemID)
    itemID = tonumber(itemID)
    if not itemID then return 0 end
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.GetLiveCount then
        return api.GetLiveCount(itemID, BAG_OWNED_OPTS) or 0
    end
    local inv = _G.FluxInv
    if inv and inv.GetLiveCount then
        return inv.GetLiveCount(itemID, BAG_OWNED_OPTS) or 0
    end
    if api and api.GetCount then
        return api.GetCount(itemID, BAG_OWNED_OPTS) or 0
    end
    if inv and inv.GetCount then
        return inv.GetCount(itemID, BAG_OWNED_OPTS) or 0
    end
    if inv and inv.Bags and inv.Bags.GetCount then
        return inv.Bags.GetCount(itemID) or 0
    end
    return 0
end

-- Get spell max duration from spell info
local function GetSpellMaxDuration(spellID)
    if not spellID then return 0 end
    if not CanAccessValue(spellID) then return 0 end

    local ok, result = pcall(function()
        -- Try to get spell info
        local spellInfo
        if C_Spell and C_Spell.GetSpellInfo then
            spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo then
                local mdMs = CoerceNumberLoose(spellInfo.maxDuration, 0)
                if mdMs > 0 then
                    return mdMs / 1000 -- Convert from milliseconds to seconds
                end
            end
        end

        -- Fallback: try GetSpellInfo
        if GetSpellInfo then
            -- 10th return is maxDuration (ms) on clients that support it
            local _, _, _, _, _, _, _, _, _, maxDuration = GetSpellInfo(spellID)
            local md = CoerceNumberLoose(maxDuration, 0)
            if md > 0 then
                return md / 1000 -- Convert from milliseconds to seconds
            end
        end

        return 0
    end)
    return ok and result or 0
end

-- ============================================================================
-- CHRONOBOON DETECTION HELPERS
-- ============================================================================

local function GetPlayerBagMaxIndex()
    local det = _G.FluxNCItemDetection
    if det and det.GetMaxBagIndex then
        return det.GetMaxBagIndex()
    end
    if C_Container and Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
        return Enum.BagIndex.ReagentBag
    end
    return 4
end

local function ForEachCharacterBag(bagFn)
    local BC = _G.FluxRestockBankCompat
    if BC and BC.GetBagContainerIDs then
        for _, bag in ipairs(BC.GetBagContainerIDs()) do
            bagFn(bag)
        end
        return
    end
    for bag = BACKPACK_CONTAINER or 0, GetPlayerBagMaxIndex() do
        bagFn(bag)
    end
end

local function GetContainerItemLinkCompat(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
    return nil
end

local function ParseItemIDFromLink(link)
    if not link then
        return nil
    end
    if GetItemInfoInstant then
        local id = GetItemInfoInstant(link)
        if id then
            return tonumber(id)
        end
    end
    if C_Item and C_Item.GetItemInfoInstant then
        local instant = C_Item.GetItemInfoInstant(link)
        if type(instant) == "table" then
            if instant.itemID then
                return tonumber(instant.itemID)
            end
        elseif instant then
            return tonumber(instant)
        end
    end
    return tonumber(link:match("item:(%d+)"))
end

-- Item name from link text works even when GetItemInfo has not cached the item yet.
local function ParseNameFromItemLink(link)
    if not link or type(link) ~= "string" then
        return nil
    end
    return link:match("%[(.-)%]")
end

local function GetNameFromItemID(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    if C_Item and C_Item.GetItemInfoInstant then
        local instant = C_Item.GetItemInfoInstant(itemID)
        if type(instant) == "table" and instant.itemName and instant.itemName ~= "" then
            return instant.itemName
        end
    end
    if GetItemInfoInstant then
        local name = GetItemInfoInstant(itemID)
        if name and name ~= "" then
            return name
        end
    end
    local cachedName = GetCachedItemInfo(itemID)
    if cachedName then
        return cachedName
    end
    if C_Item and C_Item.GetItemInfoByID then
        local info = C_Item.GetItemInfoByID(itemID)
        if type(info) == "table" and info.itemName and info.itemName ~= "" then
            return info.itemName
        end
        if type(info) == "table" and info.hyperlink then
            local fromLink = ParseNameFromItemLink(info.hyperlink)
            if fromLink then
                return fromLink
            end
        end
    end
    if GetItemInfo then
        local name = GetItemInfo(itemID)
        if name then
            return name
        end
    end
    if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    return nil
end

local function GetMerchantSlotName(slotIndex)
    if not slotIndex or not GetMerchantItemInfo then
        return nil
    end
    local name = GetMerchantItemInfo(slotIndex)
    if name and name ~= "" then
        return name
    end
    return nil
end

local function GetSlotStackCount(bag, slot, info)
    if info then
        return info.stackCount or info.count or 0
    end
    if C_Container and C_Container.GetContainerItemInfo then
        local slotInfo = C_Container.GetContainerItemInfo(bag, slot)
        if slotInfo then
            return slotInfo.stackCount or slotInfo.count or 0
        end
    end
    if GetContainerItemInfo then
        local _, count = GetContainerItemInfo(bag, slot)
        return count or 0
    end
    return 0
end

local function ResolveEntryName(opts)
    opts = opts or {}
    if opts.name and opts.name ~= "" then
        return opts.name
    end
    if opts.merchantIndex then
        local merchantName = GetMerchantSlotName(opts.merchantIndex)
        if merchantName then
            return merchantName
        end
    end
    if opts.link then
        local fromLink = ParseNameFromItemLink(opts.link)
        if fromLink then
            return fromLink
        end
    end
    if opts.itemID then
        return GetNameFromItemID(opts.itemID)
    end
    if opts.bag ~= nil and opts.slot then
        local link = opts.link or GetContainerItemLinkCompat(opts.bag, opts.slot)
        local fromLink = ParseNameFromItemLink(link)
        if fromLink then
            return fromLink
        end
        if link and GetItemInfo then
            local name = GetItemInfo(link)
            if name then
                return name
            end
        end
    end
    return nil
end

local function ClassifyChronoboonFromName(itemName)
    if not itemName then
        return nil
    end
    local lowerName = string.lower(itemName)
    if not lowerName:find("chronoboon displacer", 1, true) then
        return nil
    end
    if lowerName:find("supercharged", 1, true) then
        return "super"
    end
    return "regular"
end

function Module.IsChronoboonName(itemName)
    return ClassifyChronoboonFromName(itemName) ~= nil
end

-- Name-first classification (Era / SoD / Anniversary variants). Returns "regular", "super", or nil.
function Module.ClassifyChronoboon(itemID, bag, slot, link, name)
    if not Module.IsChronoboonFeatureEnabled() then
        return nil
    end
    itemID = tonumber(itemID)
    local resolvedName = ResolveEntryName({
        itemID = itemID,
        bag = bag,
        slot = slot,
        link = link,
        name = name,
    })
    local kind = ClassifyChronoboonFromName(resolvedName)
    if kind then
        if not itemID then
            if link then
                itemID = ParseItemIDFromLink(link)
            elseif bag ~= nil and slot then
                itemID = FluxGetContainerItemID and FluxGetContainerItemID(bag, slot)
                    or (C_Container and C_Container.GetContainerItemID and C_Container.GetContainerItemID(bag, slot))
                    or (GetContainerItemID and GetContainerItemID(bag, slot))
            end
            itemID = tonumber(itemID)
        end
        if itemID then
            RegisterChronoboonVariant(itemID, kind)
        end
        return kind
    end
    return nil
end

function Module.NoteChronoboonVariant(itemID)
    return Module.ClassifyChronoboon(itemID)
end

local function ConsiderChronoboonEntry(opts, regular, super, regSeen, superSeen)
    opts = opts or {}
    local link = opts.link
    if not link and opts.bag ~= nil and opts.slot then
        link = GetContainerItemLinkCompat(opts.bag, opts.slot)
    end
    if not opts.itemID and link then
        opts.itemID = ParseItemIDFromLink(link)
    end
    local name = ResolveEntryName({
        itemID = opts.itemID,
        bag = opts.bag,
        slot = opts.slot,
        link = link,
        name = opts.name,
        merchantIndex = opts.merchantIndex,
    })
    local kind = ClassifyChronoboonFromName(name)
    if not kind then
        return
    end
    local itemID = tonumber(opts.itemID)
    if itemID then
        RegisterChronoboonVariant(itemID, kind)
    end
    if kind == "regular" then
        local key = itemID or ("name:" .. string.lower(name))
        if not regSeen[key] then
            regSeen[key] = true
            if itemID then
                regular[#regular + 1] = itemID
            end
        end
    elseif kind == "super" then
        local key = itemID or ("name:" .. string.lower(name))
        if not superSeen[key] then
            superSeen[key] = true
            if itemID then
                super[#super + 1] = itemID
            end
        end
    end
end

local function CountChronoboonStacksInBagSlots(kind)
    kind = kind or "regular"
    local total = 0
    ForEachCharacterBag(function(bag)
        local numSlots
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag)
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag)
        end
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local link = GetContainerItemLinkCompat(bag, slot)
                if link then
                    local name = ParseNameFromItemLink(link)
                    if ClassifyChronoboonFromName(name) == kind then
                        total = total + GetSlotStackCount(bag, slot)
                        local itemID = ParseItemIDFromLink(link)
                        if itemID then
                            RegisterChronoboonVariant(itemID, kind)
                        end
                    end
                end
            end
        end
    end)
    return total
end

local function CountChronoboonStacksInBankSlots(kind)
    kind = kind or "regular"
    local BC = _G.FluxRestockBankCompat
    if not BC or not BC.IsBankOpen or not BC.IsBankOpen() then
        return nil
    end
    local total = 0
    for _, bag in ipairs(BC.GetBankContainerIDs()) do
        local slots = BC.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = BC.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink then
                local name = ParseNameFromItemLink(info.hyperlink) or GetNameFromItemID(info.itemID)
                if ClassifyChronoboonFromName(name) == kind then
                    total = total + (info.count or 0)
                    if info.itemID then
                        RegisterChronoboonVariant(info.itemID, kind)
                    end
                end
            end
        end
    end
    return total
end

local function CountChronoboonInBankSnapshot(kind)
    kind = kind or "regular"
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    local snap = _FluxUI_CharSavedVars.bankSnapshot or {}
    local total = 0
    for rawID, count in pairs(snap) do
        local itemID = tonumber(rawID)
        if itemID then
            local name = GetNameFromItemID(itemID)
            if ClassifyChronoboonFromName(name) == kind then
                total = total + (tonumber(count) or 0)
                RegisterChronoboonVariant(itemID, kind)
            end
        end
    end
    return total
end

local function ScanBagsForChronoboonIDs(regular, super, regSeen, superSeen)
    ForEachCharacterBag(function(bag)
        local numSlots
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag)
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag)
        end
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local link = GetContainerItemLinkCompat(bag, slot)
                ConsiderChronoboonEntry({
                    bag = bag,
                    slot = slot,
                    link = link,
                    itemID = ParseItemIDFromLink(link),
                }, regular, super, regSeen, superSeen)
            end
        end
    end)
end

local function ScanBankForChronoboonIDs(regular, super, regSeen, superSeen)
    local BC = _G.FluxRestockBankCompat
    if not BC then
        return
    end
    if BC.IsBankOpen and BC.IsBankOpen() then
        for _, bag in ipairs(BC.GetBankContainerIDs()) do
            local slots = BC.GetContainerNumSlots(bag)
            for slot = 1, slots do
                local info = BC.GetContainerItemInfo(bag, slot)
                if info and (info.hyperlink or info.itemID) then
                    ConsiderChronoboonEntry({
                        bag = bag,
                        slot = slot,
                        link = info.hyperlink,
                        itemID = info.itemID,
                    }, regular, super, regSeen, superSeen)
                end
            end
        end
    else
        _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
        for itemID in pairs(_FluxUI_CharSavedVars.bankSnapshot or {}) do
            ConsiderChronoboonEntry({ itemID = itemID }, regular, super, regSeen, superSeen)
        end
    end
end

local function ResolveMerchantSlotItemID(slotIndex)
    local itemID = GetMerchantItemID and GetMerchantItemID(slotIndex)
    if not itemID then
        local itemLink = GetMerchantItemLink and GetMerchantItemLink(slotIndex)
        itemID = ParseItemIDFromLink(itemLink)
    end
    return tonumber(itemID)
end

local function ScanMerchantForChronoboonIDs(regular, super, regSeen, superSeen)
    if not MerchantFrame or not MerchantFrame.IsShown or not MerchantFrame:IsShown() then
        return
    end
    local numMerchantItems = GetMerchantNumItems and GetMerchantNumItems() or 0
    for i = 1, numMerchantItems do
        local itemLink = GetMerchantItemLink and GetMerchantItemLink(i)
        ConsiderChronoboonEntry({
            merchantIndex = i,
            link = itemLink,
            itemID = ResolveMerchantSlotItemID(i),
            name = GetMerchantSlotName(i),
        }, regular, super, regSeen, superSeen)
    end
end

local function ScanSavedForChronoboonIDs(regular, super, regSeen, superSeen)
    local data = LoadSavedVars()
    for _, preset in pairs(data.presets or {}) do
        if preset.items then
            for _, itemID in ipairs(preset.items) do
                ConsiderChronoboonEntry({ itemID = itemID }, regular, super, regSeen, superSeen)
            end
        end
    end
    local settings = InitRestockSavedVars()
    for key in pairs(settings.restockItems or {}) do
        ConsiderChronoboonEntry({ itemID = key }, regular, super, regSeen, superSeen)
    end
end

local function ForEachRegularChronoboonVariantID(fn)
    for itemID in pairs(REGULAR_CHRONOBOON_IDS) do
        fn(itemID)
    end
    for itemID in pairs(discoveredRegularChronoboonIDs) do
        fn(itemID)
    end
end

function Module.GetRegularChronoboonVariantIDs()
    local out, seen = {}, {}
    ForEachRegularChronoboonVariantID(function(itemID)
        if not seen[itemID] then
            seen[itemID] = true
            out[#out + 1] = itemID
        end
    end)
    return out
end

-- Collect regular/super Chronoboon IDs by name (bags, bank, merchant, saved data).
local chronoboonIDsCache = nil
local chronoboonIDsCacheBank = nil

local function InvalidateChronoboonIDsCache()
	chronoboonIDsCache = nil
	chronoboonIDsCacheBank = nil
end

function Module.CollectChronoboonIDs(includeBank)
	if includeBank then
		if chronoboonIDsCacheBank then
			return chronoboonIDsCacheBank
		end
	else
		if chronoboonIDsCache then
			return chronoboonIDsCache
		end
	end
	local regular, super = {}, {}
	local regSeen, superSeen = {}, {}
	if not Module.IsChronoboonFeatureEnabled() then
		local empty = { regular = regular, super = super }
		if includeBank then
			chronoboonIDsCacheBank = empty
		else
			chronoboonIDsCache = empty
		end
		return empty
	end
	ScanBagsForChronoboonIDs(regular, super, regSeen, superSeen)
	if includeBank then
		ScanBankForChronoboonIDs(regular, super, regSeen, superSeen)
	end
	ScanMerchantForChronoboonIDs(regular, super, regSeen, superSeen)
	ScanSavedForChronoboonIDs(regular, super, regSeen, superSeen)
	local result = { regular = regular, super = super }
	if includeBank then
		chronoboonIDsCacheBank = result
	else
		chronoboonIDsCache = result
	end
	return result
end

function Module.GetChronoboonBagCount()
    if not Module.IsChronoboonFeatureEnabled() then
        return 0
    end
    return CountChronoboonStacksInBagSlots("regular")
end

function Module.GetChronoboonBankCount()
    if not Module.IsChronoboonFeatureEnabled() then
        return 0
    end
    local live = CountChronoboonStacksInBankSlots("regular")
    if live ~= nil then
        return live
    end
    return CountChronoboonInBankSnapshot("regular")
end

-- Bank stacks for restock withdraw (name matched, any variant).
function Module.FindChronoboonBankSlotStacks()
    local BC = _G.FluxRestockBankCompat
    if not BC or not BC.IsBankOpen or not BC.IsBankOpen() then
        return {}
    end
    local stacks = {}
    for _, bag in ipairs(BC.GetBankContainerIDs()) do
        local slots = BC.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = BC.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink then
                local name = ParseNameFromItemLink(info.hyperlink) or GetNameFromItemID(info.itemID)
                if ClassifyChronoboonFromName(name) == "regular" then
                    stacks[#stacks + 1] = {
                        bag = bag,
                        slot = slot,
                        count = info.count or 0,
                        locked = info.locked or false,
                        itemID = info.itemID,
                    }
                end
            end
        end
    end
    table.sort(stacks, function(a, b)
        if a.count == b.count then
            if a.bag == b.bag then
                return a.slot < b.slot
            end
            return a.bag < b.bag
        end
        return a.count < b.count
    end)
    return stacks
end

-- Match any regular Chronoboon on the open merchant by item name (not ID).
function Module.ResolveMerchantRegularChronoboon(merchantItemIndex)
    if not MerchantFrame or not MerchantFrame.IsShown or not MerchantFrame:IsShown() then
        return nil, nil
    end
    local numMerchantItems = GetMerchantNumItems and GetMerchantNumItems() or 0
    for i = 1, numMerchantItems do
        local name = GetMerchantSlotName(i)
        if ClassifyChronoboonFromName(name) == "regular" then
            local itemID = ResolveMerchantSlotItemID(i)
            if itemID then
                RegisterChronoboonVariant(itemID, "regular")
            end
            return i, itemID
        end
    end
    if merchantItemIndex then
        for _, itemID in ipairs(Module.GetRegularChronoboonVariantIDs()) do
            local merchantIndex = merchantItemIndex[itemID]
            if merchantIndex then
                return merchantIndex, itemID
            end
        end
    end
    return nil, nil
end

function Module.ReadChronoboonRestockTargetCombined()
    if not Module.IsChronoboonFeatureEnabled() then
        return 0
    end
    local best = 0
    local collected = Module.CollectChronoboonIDs(true)
    for _, itemID in ipairs(collected.regular) do
        best = math.max(best, ReadChronoboonTargetForID(itemID))
    end
    local targets = GetPresetRestockTargets()
    if targets then
        for key, qty in pairs(targets) do
            local itemID = tonumber(key)
            if itemID and IsKnownRegularChronoboonID(itemID) then
                best = math.max(best, tonumber(qty) or 0)
            end
        end
    end
    local settings = InitRestockSavedVars()
    for key, data in pairs(settings.restockItems or {}) do
        local itemID = tonumber(key)
        if itemID and type(data) == "table" and IsKnownRegularChronoboonID(itemID) then
            if data.targetQuantity ~= nil then
                best = math.max(best, tonumber(data.targetQuantity) or 0)
            end
        end
    end
    return best
end

-- Check if item is a Chronoboon Displacer (regular or SuperCharged)
function Module.IsChronoboonItem(itemID)
    if not Module.IsChronoboonFeatureEnabled() then
        return false
    end
    itemID = tonumber(itemID)
    if IsKnownChronoboonID(itemID) then
        return true
    end
    local kind = Module.ClassifyChronoboon(itemID)
    return kind == "regular" or kind == "super"
end

-- Check if item is a SuperCharged Chronoboon Displacer
function Module.IsSuperchargedChronoboonItem(itemID)
    if not Module.IsChronoboonFeatureEnabled() then
        return false
    end
    itemID = tonumber(itemID)
    if IsKnownSuperChronoboonID(itemID) then
        return true
    end
    return Module.ClassifyChronoboon(itemID) == "super"
end

-- Check if player has SuperCharged Chronoboon Displacer buff
function Module.HasSuperchargedChronoboonBuff()
    local cache = Module._tooltipAuraCache
    if cache then
        return cache.hasSuperChrono == true
    end
    local index = 1
    -- Check if we're on a 12.0+ client that uses secret values
    local isV12 = FLUX_API and FLUX_API.isV12
    local canAccessValue = canaccessvalue or function() return true end
    local isSecretValue = issecretvalue or function() return false end
    
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellID
        
        -- Modern API
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = PlayerHelpfulAura(index)
            if not aura then break end
            name = aura.name
            spellID = aura.spellId
        elseif UnitAura then
            -- Legacy API
            name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellID = UnitAura("player", index, "HELPFUL")
            if not name then break end
        else
            break
        end
        
        -- Check if this is the SuperCharged Chronoboon Displacer buff
        -- Handle secret values safely for 12.0+ clients
        if name then
            local nameMatches = false
            
            -- For 12.0+ clients, check if name is a secret value
            if isV12 and isSecretValue(name) then
                -- For 12.0+ with secret values, we can't use string methods (name:lower())
                -- Try using string functions instead (string.lower() as C function may work)
                local success, result = pcall(function()
                    local lowerName = string.lower(name)
                    return string.find(lowerName, "supercharged chronoboon displacer") ~= nil
                end)
                
                if success then
                    nameMatches = result
                end
                -- If pcall fails, nameMatches stays false and we skip this aura
            else
                -- Pre-12.0 or accessible value: use normal string operations
                -- Use function form (string.lower) instead of method form (name:lower) for consistency
                nameMatches = string.find(string.lower(name), "supercharged chronoboon displacer") ~= nil
            end
            
            if nameMatches then
                return true
            end
        end
        
        index = index + 1
    end
    return false
end

-- Check if player has SuperCharged Chronoboon Displacer in bags
function Module.HasSuperchargedChronoboonInBags()
    return CountChronoboonStacksInBagSlots("super") > 0
end

-- World buff names that Chronoboon can pack
local WORLD_BUFF_NAMES = {
    "Warchief's Blessing",
    "Rallying Cry of the Dragonslayer",
    "Spirit of Zandalar",
    "Sayge's Dark Fortune of Damage",
    "Sayge's Dark Fortune of Resistance",
    "Sayge's Dark Fortune of Armor",
    "Sayge's Dark Fortune of Intelligence",
    "Sayge's Dark Fortune of Spirit",
    "Sayge's Dark Fortune of Stamina",
    "Sayge's Dark Fortune of Strength",
    "Sayge's Dark Fortune of Agility",
    "Mol'dar's Moxie",
    "Fengus' Ferocity",
    "Slip'kik's Savvy",
    "Songflower Serenade",
}

-- Check if player has any world buff that can be packed by Chronoboon
function Module.HasWorldBuff()
    local count = Module.GetWorldBuffCount()
    return count > 0
end

-- Get count of active world buffs (wrapped: aura APIs can error or taint with certain buffs; must not break GetItems / UI)
function Module.GetWorldBuffCount()
    local cache = Module._tooltipAuraCache
    if cache and cache.worldBuffCount ~= nil then
        return cache.worldBuffCount
    end
    local ok, count = pcall(function()
        local worldBuffCount = 0
        local index = 1
        local isV12 = FLUX_API and FLUX_API.isV12
        local isSecretValue = issecretvalue or function() return false end
        
        while true do
            local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellID
            
            if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                local aura = PlayerHelpfulAura(index)
                if not aura then break end
                name = aura.name
                spellID = aura.spellId
            elseif UnitAura then
                name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellID = UnitAura("player", index, "HELPFUL")
                if not name then break end
            else
                break
            end
            
            if name then
                local lowerName = nil
                if isV12 and isSecretValue(name) then
                    local success, result = pcall(function()
                        return string.lower(name)
                    end)
                    if success then
                        lowerName = result
                    end
                else
                    lowerName = string.lower(name)
                end
                
                if lowerName then
                    for _, buffName in ipairs(WORLD_BUFF_NAMES) do
                        local buffNameLower = string.lower(buffName)
                        if lowerName == buffNameLower then
                            worldBuffCount = worldBuffCount + 1
                            break
                        end
                    end
                end
            end
            
            index = index + 1
        end
        return worldBuffCount
    end)
    if ok and type(count) == "number" then
        return count
    end
    return 0
end

-- Find all Chronoboon Displacer items in bags
function Module.FindChronoboonItemIDs()
    local collected = Module.CollectChronoboonIDs(false)
    local out = {}
    for _, id in ipairs(collected.regular) do
        out[#out + 1] = id
    end
    for _, id in ipairs(collected.super) do
        out[#out + 1] = id
    end
    return out
end

-- Well Fed spell IDs (Retail: 1232324, alternate: 451920)
local WELL_FED_SPELL_IDS = { 1232324, 451920 }

-- ============================================================================
-- GROUND-PLACED ITEM AURA BINDINGS (feasts, cauldrons, etc.)
-- ============================================================================

local GROUND_PLACEABLE_TOOLTIP_KEYWORDS = {
    "feast", "cauldron", "set out", "place a", "places a",
    "summon a", "summons a", "put down", "deploy a", "deploys a",
}

local GROUND_AURA_LEARN_TIMEOUT = 90
local GROUND_AURA_PLACE_CHECK_DELAY = 1.5
local GROUND_AURA_MIN_DURATION = 60

-- Learner runtime state (not saved): { itemID, snapshot, armedAt, placeSpellID }
Module._groundAuraLearner = nil

function Module.GetGroundAuraBinding(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    local data = LoadSavedVars()
    local binding = data.groundAuras and data.groundAuras[itemID]
    if type(binding) ~= "table" then return nil end
    local spellID = tonumber(binding.spellID)
    if not spellID or spellID <= 0 then return nil end
    return {
        spellID = spellID,
        name = binding.name,
    }
end

function Module.SetGroundAuraBinding(itemID, spellID, name)
    itemID = tonumber(itemID)
    spellID = tonumber(spellID)
    if not itemID or not spellID or spellID <= 0 then return false end
    local data = LoadSavedVars()
    data.groundAuras = data.groundAuras or {}
    data.groundAuras[itemID] = {
        spellID = spellID,
        name = (type(name) == "string" and name ~= "") and name or nil,
    }
    NotifyRespecConsumablesConfigChanged()
    return true
end

function Module.ClearGroundAuraBinding(itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end
    local data = LoadSavedVars()
    if not data.groundAuras or not data.groundAuras[itemID] then
        return false
    end
    data.groundAuras[itemID] = nil
    if Module._groundAuraLearner and Module._groundAuraLearner.itemID == itemID then
        Module._groundAuraLearner = nil
    end
    NotifyRespecConsumablesConfigChanged()
    return true
end

function Module.IsGroundAuraLearnerArmed(itemID)
    local learner = Module._groundAuraLearner
    if not learner then return false end
    if itemID and tonumber(itemID) ~= tonumber(learner.itemID) then
        return false
    end
    local armedAt = learner.armedAt or 0
    if (GetTime() - armedAt) > GROUND_AURA_LEARN_TIMEOUT then
        Module._groundAuraLearner = nil
        return false
    end
    return true
end

local GroundPlaceableScanTooltip = nil
local function EnsureGroundPlaceableScanTooltip()
    if GroundPlaceableScanTooltip then return GroundPlaceableScanTooltip end
    local tip = CreateFrame("GameTooltip", "FluxConsumablesGroundPlaceableScanTooltip", UIParent, "GameTooltipTemplate")
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    GroundPlaceableScanTooltip = tip
    return tip
end

function Module.IsGroundPlaceableItem(itemID)
    if not itemID then return false end
    itemID = tonumber(itemID) or itemID
    if Module.IsChronoboonItem and Module.IsChronoboonItem(itemID) then
        return false
    end
    if Module.IsWeaponEnchantItem and Module.IsWeaponEnchantItem(itemID) then
        return false
    end

    local link = select(2, GetItemInfo(itemID)) or ("item:" .. tostring(itemID))
    local tip = EnsureGroundPlaceableScanTooltip()
    tip:ClearLines()
    local ok = pcall(function() tip:SetHyperlink(link) end)
    if not ok then return false end
    local text = ""
    for i = 1, tip:NumLines() do
        local left = _G["FluxConsumablesGroundPlaceableScanTooltipTextLeft" .. i]
        if left then
            local t = (left:GetText() or ""):lower()
            if t ~= "" then text = text .. "\n" .. t end
        end
    end
    for _, kw in ipairs(GROUND_PLACEABLE_TOOLTIP_KEYWORDS) do
        if text:find(kw, 1, true) then
            return true
        end
    end
    return false
end

-- Find a specific HELPFUL aura by spell ID on the player
function Module.FindBuffBySpellID(spellID)
    spellID = tonumber(spellID)
    if not spellID then return nil end

    local hit = AuraDataFromSpellID(spellID)
    if hit then
        if (not hit.maxDuration or hit.maxDuration <= 0) and hit.spellID then
            hit.maxDuration = GetSpellMaxDuration(hit.spellID)
        end
        return MergeHeldBuff("spell:" .. tostring(spellID), hit)
    end

    if AurasRestricted() then
        return MergeHeldBuff("spell:" .. tostring(spellID), nil)
    end

    local index = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, auraSpellID

        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = PlayerHelpfulAura(index)
            if not aura then break end
            name = aura.name
            icon = aura.icon
            count = aura.applications or 0
            duration = aura.duration or 0
            expirationTime = aura.expirationTime or 0
            auraSpellID = aura.spellId
        elseif UnitAura then
            name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, auraSpellID =
                UnitAura("player", index, "HELPFUL")
            if not name then break end
        else
            break
        end

        if auraSpellID and SafeSpellIdEquals(auraSpellID, spellID) then
            local packed = PackAuraBuff({
                name = name,
                icon = icon,
                applications = count,
                duration = duration,
                expirationTime = expirationTime,
                spellId = auraSpellID,
            }, spellID)
            if packed then
                if (not packed.maxDuration or packed.maxDuration <= 0) then
                    packed.maxDuration = GetSpellMaxDuration(auraSpellID)
                end
                return MergeHeldBuff("spell:" .. tostring(spellID), packed)
            end
        end

        index = index + 1
    end
    return MergeHeldBuff("spell:" .. tostring(spellID), nil)
end

local function SnapshotHelpfulAuraSpellIDs()
    local snapshot = {}
    local index = 1
    while true do
        local auraSpellID
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = PlayerHelpfulAura(index)
            if not aura then break end
            auraSpellID = aura.spellId
        elseif UnitAura then
            local name, _, _, _, _, _, _, _, _, sid = UnitAura("player", index, "HELPFUL")
            if not name then break end
            auraSpellID = sid
        else
            break
        end
        local sid = tonumber(auraSpellID)
        if sid then
            snapshot[sid] = true
        end
        index = index + 1
    end
    return snapshot
end

local function CollectNewHelpfulAuras(snapshot)
    local news = {}
    local index = 1
    while true do
        local name, icon, count, duration, expirationTime, auraSpellID
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = PlayerHelpfulAura(index)
            if not aura then break end
            name = aura.name
            icon = aura.icon
            count = aura.applications or 0
            duration = aura.duration or 0
            expirationTime = aura.expirationTime or 0
            auraSpellID = aura.spellId
        elseif UnitAura then
            local n, ic, c, _, dur, exp, _, _, _, sid = UnitAura("player", index, "HELPFUL")
            if not n then break end
            name, icon, count, duration, expirationTime, auraSpellID = n, ic, c, dur, exp, sid
        else
            break
        end

        local sid = tonumber(auraSpellID)
        if sid and not (snapshot and snapshot[sid]) then
            local durN = CoerceNumberLoose(duration, 0)
            local expN = CoerceNumberLoose(expirationTime, 0)
            local remaining = (expN > 0) and (expN - GetTime()) or 0
            local durable = (durN >= GROUND_AURA_MIN_DURATION)
                or (remaining >= GROUND_AURA_MIN_DURATION)
            news[#news + 1] = {
                name = name,
                icon = icon,
                count = count or 0,
                duration = durN,
                expirationTime = expN,
                spellID = sid,
                remaining = remaining,
                durable = durable,
            }
        end
        index = index + 1
    end
    return news
end

local function FindPresetItemForCastSpellID(spellID)
    spellID = tonumber(spellID)
    if not spellID then return nil end
    local items = Module.GetItems()
    if not items then return nil end
    for _, itemID in ipairs(items) do
        itemID = tonumber(itemID)
        if itemID and not (Module.IsChronoboonItem and Module.IsChronoboonItem(itemID)) then
            local itemSpellName, itemSpellID
            if C_Item and C_Item.GetItemSpell then
                itemSpellName, itemSpellID = C_Item.GetItemSpell(itemID)
            elseif GetItemSpell then
                itemSpellName, itemSpellID = GetItemSpell(itemID)
            end
            if itemSpellID and SafeSpellIdEquals(itemSpellID, spellID) then
                return itemID, itemSpellID, itemSpellName
            end
        end
    end
    return nil
end

local function DisarmGroundAuraLearner()
    Module._groundAuraLearner = nil
end

local function ArmGroundAuraLearner(itemID, snapshot, placeSpellID)
    itemID = tonumber(itemID)
    if not itemID then return end
    Module._groundAuraLearner = {
        itemID = itemID,
        snapshot = snapshot or {},
        armedAt = GetTime(),
        placeSpellID = tonumber(placeSpellID),
    }
end

function Module.TryProcessGroundAuraLearner()
    local learner = Module._groundAuraLearner
    if not learner then return false end
    if (GetTime() - (learner.armedAt or 0)) > GROUND_AURA_LEARN_TIMEOUT then
        DisarmGroundAuraLearner()
        return false
    end

    local news = CollectNewHelpfulAuras(learner.snapshot)
    if #news == 0 then
        return false
    end

    -- Prefer durable auras (feast / cauldron buffs); ignore short procs
    local durable = {}
    for _, aura in ipairs(news) do
        if aura.durable then
            durable[#durable + 1] = aura
        end
    end

    local candidates = (#durable > 0) and durable or news
    if #candidates == 0 then
        return false
    end

    -- Pick the longest-lived new aura
    table.sort(candidates, function(a, b)
        local ar = a.remaining or a.duration or 0
        local br = b.remaining or b.duration or 0
        if ar == br then
            return (a.spellID or 0) < (b.spellID or 0)
        end
        return ar > br
    end)

    -- If multiple durable auras appeared at once, still take the longest
    local best = candidates[1]
    if not best or not best.spellID then
        return false
    end

    -- Do not bind the place spell itself
    if learner.placeSpellID and SafeSpellIdEquals(best.spellID, learner.placeSpellID) then
        return false
    end

    Module.SetGroundAuraBinding(learner.itemID, best.spellID, best.name)
    DisarmGroundAuraLearner()
    if Module.ForceUpdate then
        Module.ForceUpdate()
    end
    return true
end

function Module.OnGroundPlaceableCastSucceeded(spellID)
    spellID = tonumber(spellID)
    if not spellID then return end

    local itemID, itemSpellID = FindPresetItemForCastSpellID(spellID)
    if not itemID then return end

    -- Already learned: do not re-arm unless unbound
    if Module.GetGroundAuraBinding(itemID) then
        return
    end

    -- Skip classes that already resolve buffs without ground learning
    if Module.IsWeaponEnchantItem and Module.IsWeaponEnchantItem(itemID) then
        return
    end
    if Module.ItemGrantsWellFed and Module.ItemGrantsWellFed(itemID) then
        return
    end

    local snapshot = SnapshotHelpfulAuraSpellIDs()

    -- Short delay: if place spell became a player aura, this is a normal consumable
    Timer.After(GROUND_AURA_PLACE_CHECK_DELAY, function()
        if Module.GetGroundAuraBinding(itemID) then
            return
        end
        if Module.FindBuffBySpellID(itemSpellID or spellID) then
            return
        end
        ArmGroundAuraLearner(itemID, snapshot, itemSpellID or spellID)
    end)
end

-- Check if item grants Well Fed buff (buff food - tooltip contains "well fed")
function Module.ItemGrantsWellFed(itemID)
    if not itemID then return false end
    itemID = tonumber(itemID) or itemID
    local IC = _G.FluxItemClass
    if IC and IC.GetRestore then
        local restore = IC.GetRestore(itemID)
        if restore and restore.ready then
            return restore.wellFed == true
        end
    end
    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.ParseFoodWaterRestore and IC and IC.GetTooltipText then
        local link = (IC.GetLink and IC.GetLink(itemID))
            or select(2, GetItemInfo(itemID))
            or ("item:" .. tostring(itemID))
        local text = IC.GetTooltipText(itemID, link)
        if text then
            local name = IC.GetName and IC.GetName(itemID) or nil
            local parsed = Classify.ParseFoodWaterRestore(text, link, name)
            if parsed then
                return parsed.isWellFed == true
            end
        end
    end
    local link = (IC and IC.GetLink and IC.GetLink(itemID))
        or select(2, GetItemInfo(itemID))
        or ("item:" .. tostring(itemID))
    if not link then return false end
    if FluxNCItemDetection and FluxNCItemDetection.ItemGrantsWellFed then
        return FluxNCItemDetection.ItemGrantsWellFed(link)
    end
    -- Fallback: use GetItemRestoreValues 5th return
    if FluxNCItemDetection and FluxNCItemDetection.GetItemRestoreValues then
        local _, _, _, _, isWellFed = FluxNCItemDetection.GetItemRestoreValues(link)
        return isWellFed == true
    end
    return false
end

-- Find Well Fed buff on player (locale-independent via spell ID)
-- Returns: {name, icon, count, duration, maxDuration, expirationTime, spellID} or nil
function Module.FindWellFedBuff()
    for _, wellFedId in ipairs(WELL_FED_SPELL_IDS) do
        local hit = AuraDataFromSpellID(wellFedId)
        if hit then
            if (not hit.maxDuration or hit.maxDuration <= 0) and hit.spellID then
                hit.maxDuration = GetSpellMaxDuration(hit.spellID)
            end
            return MergeHeldBuff("wellfed", hit)
        end
    end

    if AurasRestricted() then
        return MergeHeldBuff("wellfed", nil)
    end

    local index = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellID
        
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = PlayerHelpfulAura(index)
            if not aura then break end
            name = aura.name
            icon = aura.icon
            count = aura.applications or 0
            duration = aura.duration or 0
            expirationTime = aura.expirationTime or 0
            spellID = aura.spellId
        elseif UnitAura then
            name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellID = UnitAura("player", index, "HELPFUL")
            if not name then break end
        else
            break
        end
        
        -- Match by spell ID (locale-independent) or by buff name "well fed"
        local isWellFed = false
        if spellID then
            for _, wellFedId in ipairs(WELL_FED_SPELL_IDS) do
                if SafeSpellIdEquals(spellID, wellFedId) then
                    isWellFed = true
                    break
                end
            end
        end
        if not isWellFed and name then
            local nameLower = nil
            local isSecretValue = issecretvalue or function() return false end
            if FLUX_API and FLUX_API.isV12 and isSecretValue(name) then
                local ok, result = pcall(function() return string.lower(name) end)
                nameLower = ok and result or ""
            else
                nameLower = (type(name) == "string" and name:lower()) or ""
            end
            if nameLower and nameLower:find("well fed", 1, true) then
                isWellFed = true
            end
        end
        if isWellFed then
            local packed = PackAuraBuff({
                name = name,
                icon = icon,
                applications = count,
                duration = duration,
                expirationTime = expirationTime,
                spellId = spellID,
            }, spellID)
            if packed then
                if (not packed.maxDuration or packed.maxDuration <= 0) and spellID then
                    packed.maxDuration = GetSpellMaxDuration(spellID)
                end
                return MergeHeldBuff("wellfed", packed)
            end
        end
        
        index = index + 1
    end
    return MergeHeldBuff("wellfed", nil)
end

-- Find buff by item spell effect
-- Returns: auraData = {name, icon, count, duration, maxDuration, expirationTime, spellID} or nil
function Module.FindBuffForItem(itemID)
    if not itemID then return nil end
    
    -- Chronoboon items don't have buffs to track
    if Module.IsChronoboonItem(itemID) then
        return nil
    end
    
    -- Check if this is a weapon enchant item - if so, check weapon enchant info
    if Module.IsWeaponEnchantItem(itemID) then
        if GetWeaponEnchantInfo then
            local hasMainHand, expirationMainHand, chargesMainHand, enchantIdMainHand, 
                  hasOffHand, expirationOffHand, chargesOffHand, enchantIdOffHand = GetWeaponEnchantInfo()
            
            -- Get item spell ID to match against enchant
            local itemSpellName, itemSpellID
            if C_Item and C_Item.GetItemSpell then
                itemSpellName, itemSpellID = C_Item.GetItemSpell(itemID)
            elseif GetItemSpell then
                itemSpellName, itemSpellID = GetItemSpell(itemID)
            end
            
            -- Check both main hand and offhand to see if this item's enchant is active
            -- We check both because the item might target either slot
            local mainHandSlot = GetInventorySlotInfo and GetInventorySlotInfo("MainHandSlot") or 16
            local offHandSlot = GetInventorySlotInfo and GetInventorySlotInfo("SecondaryHandSlot") or 17
            
            -- Check main hand first
            local hasEnchant = false
            local expirationRemaining = 0
            local charges = 0
            local enchantId = nil
            
            if Module.CanEnchantApplyToSlot(itemID, mainHandSlot) then
                if type(hasMainHand) == "boolean" then
                    hasEnchant = hasMainHand
                elseif type(hasMainHand) == "number" then
                    hasEnchant = hasMainHand > 0
                end
                if hasEnchant then
                    -- GetWeaponEnchantInfo returns expiration time in MILLISECONDS, convert to seconds
                    expirationRemaining = (expirationMainHand or 0) / 1000
                    charges = chargesMainHand or 0
                    enchantId = enchantIdMainHand
                end
            end
            
            -- If main hand doesn't have it, check offhand
            if not hasEnchant and Module.CanEnchantApplyToSlot(itemID, offHandSlot) then
                if type(hasOffHand) == "boolean" then
                    hasEnchant = hasOffHand
                elseif type(hasOffHand) == "number" then
                    hasEnchant = hasOffHand > 0
                end
                if hasEnchant then
                    -- GetWeaponEnchantInfo returns expiration time in MILLISECONDS, convert to seconds
                    expirationRemaining = (expirationOffHand or 0) / 1000
                    charges = chargesOffHand or 0
                    enchantId = enchantIdOffHand
                end
            end
            
            if hasEnchant and expirationRemaining and expirationRemaining > 0 then
                    -- Convert remaining time to absolute expiration time
                    local expirationTime = GetTime() + expirationRemaining
                    
                    -- Get item info for name and icon
                    local itemName, _, itemIcon = GetItemInfo(itemID)
                    if not itemName then
                        itemName, _, itemIcon = GetCachedItemInfo(itemID)
                    end
                    
                    -- Try to get max duration from item spell
                    local maxDuration = 0
                    local itemSpellName, itemSpellID
                    if C_Item and C_Item.GetItemSpell then
                        itemSpellName, itemSpellID = C_Item.GetItemSpell(itemID)
                    elseif GetItemSpell then
                        itemSpellName, itemSpellID = GetItemSpell(itemID)
                    end
                    
                    -- Try multiple methods to get the actual max duration
                    -- Method 1: Get from item spell ID
                    if itemSpellID then
                        maxDuration = GetSpellMaxDuration(itemSpellID)
                        if maxDuration <= 0 and C_Spell and C_Spell.GetSpellInfo then
                            local spellInfo = C_Spell.GetSpellInfo(itemSpellID)
                            if spellInfo and spellInfo.maxDuration then
                                maxDuration = spellInfo.maxDuration / 1000 -- Convert from milliseconds to seconds
                            end
                        end
                    end
                    
                    -- Method 2: Get from enchant ID (the actual enchant spell on the weapon)
                    if maxDuration <= 0 and enchantId then
                        maxDuration = GetSpellMaxDuration(enchantId)
                        if maxDuration <= 0 and C_Spell and C_Spell.GetSpellInfo then
                            local spellInfo = C_Spell.GetSpellInfo(enchantId)
                            if spellInfo and spellInfo.maxDuration then
                                maxDuration = spellInfo.maxDuration / 1000
                            end
                        end
                    end
                    
                    -- Method 3: If we still don't have maxDuration, estimate based on remaining time
                    -- We need to be smart about this - use the smallest standard duration that could fit
                    -- Common weapon enchant durations: 30 min (1800s), 1 hour (3600s), 2 hours (7200s)
                    if maxDuration <= 0 then
                        if expirationRemaining > 3600 then
                            -- More than 1 hour remaining - must be at least 2 hour enchant
                            maxDuration = 7200
                        elseif expirationRemaining > 1800 then
                            -- More than 30 min remaining - must be at least 1 hour enchant
                            maxDuration = 3600
                        elseif expirationRemaining > 0 then
                            -- 30 min or less remaining - could be 30 min, 1 hour, or 2 hour
                            -- Use 30 min as conservative estimate (shows more progress)
                            maxDuration = 1800
                        else
                            -- No time remaining - use remaining time (assume just applied)
                            maxDuration = expirationRemaining
                        end
                    end
                    
                    return {
                        name = itemName or "Weapon Enchant",
                        icon = itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
                        count = charges or 0,
                        duration = expirationRemaining or 0,
                        maxDuration = maxDuration or 0,
                        expirationTime = expirationTime or 0,
                        spellID = enchantId or itemSpellID,
                    }
                end
            end
        -- If weapon enchant but no active enchant found, return nil
        return nil
    end
    
    -- Well Fed items: do NOT check item's aura - only check if player has Well Fed buff
    -- Items with "well fed" in tooltip are buff food; we care about Well Fed presence, not the specific stat aura
    if Module.ItemGrantsWellFed(itemID) then
        return Module.FindWellFedBuff()
    end

    -- Ground-placed items (feasts, cauldrons): use learned click-aura binding
    local groundBinding = Module.GetGroundAuraBinding(itemID)
    if groundBinding and groundBinding.spellID then
        return Module.FindBuffBySpellID(groundBinding.spellID)
    end
    
    -- Regular consumable: Get item spell (the spell the item casts when used)
    local itemSpellName, itemSpellID
    if C_Item and C_Item.GetItemSpell then
        itemSpellName, itemSpellID = C_Item.GetItemSpell(itemID)
    elseif GetItemSpell then
        itemSpellName, itemSpellID = GetItemSpell(itemID)
    end
    
    if not itemSpellName and not itemSpellID then
        return MergeHeldBuff("item:" .. tostring(itemID), nil)
    end

    local heldKey = "item:" .. tostring(itemID)
    if itemSpellID then
        local hit = AuraDataFromSpellID(itemSpellID)
        if hit then
            if (not hit.maxDuration or hit.maxDuration <= 0) and hit.spellID then
                hit.maxDuration = GetSpellMaxDuration(hit.spellID)
            end
            return MergeHeldBuff(heldKey, hit)
        end
    end

    local auraCache = Module._tooltipAuraCache
    if auraCache and not auraCache.restricted and not AurasRestricted() then
        if itemSpellID and auraCache.bySpellID[itemSpellID] then
            return MergeHeldBuff(heldKey, auraCache.bySpellID[itemSpellID])
        end
        if itemSpellName then
            local cached = auraCache.byName[string.lower(itemSpellName)]
            if cached then
                return MergeHeldBuff(heldKey, cached)
            end
        end
    end

    if AurasRestricted() then
        return MergeHeldBuff(heldKey, nil)
    end
    
    -- Search player buffs
    local index = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellID
        
        -- Modern API
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = PlayerHelpfulAura(index)
            if not aura then break end
            name = aura.name
            icon = aura.icon
            count = aura.applications or 0
            duration = aura.duration or 0
            expirationTime = aura.expirationTime or 0
            spellID = aura.spellId
        elseif UnitAura then
            -- Legacy API
            name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellID = UnitAura("player", index, "HELPFUL")
            if not name then break end
        else
            break
        end
        
        -- Match by spell ID or name
        -- Handle secret values safely for 12.0+ clients
        local isMatch = false
        local isV12 = FLUX_API and FLUX_API.isV12
        local isSecretValue = issecretvalue or function() return false end
        
        if spellID and itemSpellID and SafeSpellIdEquals(spellID, itemSpellID) then
            isMatch = true
        elseif itemSpellName and name then
            -- For 12.0+ with secret values, use string functions instead of methods
            local nameLower = nil
            local itemSpellNameLower = string.lower(itemSpellName)
            
            if isV12 and isSecretValue(name) then
                local success, result = pcall(function()
                    return string.lower(name)
                end)
                if success then
                    nameLower = result
                end
            else
                -- Pre-12.0 or accessible value: use normal string operations
                nameLower = string.lower(name)
            end
            
            if nameLower and nameLower == itemSpellNameLower then
                isMatch = true
            end
        end
        
        if isMatch then
            local durN = CoerceNumberLoose(duration, 0)
            local expN = CoerceNumberLoose(expirationTime, 0)
            -- Get max duration from spell info if aura duration is 0 or missing
            local maxDuration = durN
            if maxDuration <= 0 and spellID and CanAccessValue(spellID) then
                maxDuration = GetSpellMaxDuration(spellID)
            end
            -- If we still don't have max duration but have expirationTime, calculate from remaining
            if maxDuration <= 0 and expN > 0 then
                local remaining = expN - GetTime()
                if remaining > 0 then
                    -- Estimate: assume it was just applied (conservative estimate)
                    maxDuration = remaining
                end
            end

            return MergeHeldBuff("item:" .. tostring(itemID), {
                name = name,
                icon = icon,
                count = count or 0,
                duration = durN,
                maxDuration = maxDuration or 0,
                expirationTime = expN,
                spellID = spellID,
                present = true,
            })
        end
        
        index = index + 1
    end
    
    return MergeHeldBuff("item:" .. tostring(itemID), nil)
end

-- ============================================================================
-- WEAPON ENCHANT DETECTION
-- ============================================================================

-- Reusable tooltip for weapon enchant detection
local WeaponEnchantScanTooltip = nil
local function EnsureWeaponEnchantScanTooltip()
    if WeaponEnchantScanTooltip then return WeaponEnchantScanTooltip end
    local tip = CreateFrame("GameTooltip", "FluxConsumablesWeaponEnchantScanTooltip", UIParent, "GameTooltipTemplate")
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    WeaponEnchantScanTooltip = tip
    return tip
end

-- Tooltip keywords that indicate a temporary weapon enchant
local WEAPON_ENCHANT_TOOLTIP_KEYWORDS = {
    "apply to weapon", "apply to your weapon", "enchant weapon", "use on your weapon",
    "use: apply to weapon", "use: apply to your weapon", "applies to weapon",
    "temporary weapon enchant", "weapon coating", "weapon oil",
}

-- Check if item tooltip indicates weapon enchant (fallback for items not in FluxFlyoutData)
local function ItemTooltipIndicatesWeaponEnchant(itemID)
    if not itemID then return false end
    local link = select(2, GetItemInfo(itemID)) or ("item:" .. tostring(itemID))
    if not link then return false end
    local tip = EnsureWeaponEnchantScanTooltip()
    tip:ClearLines()
    local ok = pcall(function() tip:SetHyperlink(link) end)
    if not ok then return false end
    local text = ""
    for i = 2, tip:NumLines() do
        local left = _G["FluxConsumablesWeaponEnchantScanTooltipTextLeft" .. i]
        if left then
            local t = (left:GetText() or ""):lower()
            if t ~= "" then text = text .. "\n" .. t end
        end
    end
    for _, kw in ipairs(WEAPON_ENCHANT_TOOLTIP_KEYWORDS) do
        if text:find(kw, 1, true) then
            return true
        end
    end
    return false
end

-- Check if an item is a weapon enchant (oils, poisons, sharpening stones, etc.)
function Module.IsWeaponEnchantItem(itemID)
    if not itemID then return false end
    
    -- Check FluxFlyoutData table if available
    if FluxFlyoutData and FluxFlyoutData.ItemEnchantTemp then
        if FluxFlyoutData.ItemEnchantTemp[itemID] == true then
            return true
        end
    end
    
    -- Fallback: Check if item spell targets weapon slots
    -- This is a heuristic - weapon enchants typically have spells that apply to weapons
    local itemSpellName, itemSpellID
    if C_Item and C_Item.GetItemSpell then
        itemSpellName, itemSpellID = C_Item.GetItemSpell(itemID)
    elseif GetItemSpell then
        itemSpellName, itemSpellID = GetItemSpell(itemID)
    end
    
    if itemSpellName then
        local lowerName = itemSpellName:lower()
        if lowerName:match("oil") or lowerName:match("poison") or 
           lowerName:match("sharpening") or lowerName:match("weightstone") or
           lowerName:match("coating") or lowerName:match("enchant") then
            return true
        end
    end
    
    -- Fallback: Tooltip scan for "Apply to weapon", "Enchant weapon", etc.
    -- Catches mana oils and other temp enchants not in FluxFlyoutData or with different spell names
    if ItemTooltipIndicatesWeaponEnchant(itemID) then
        return true
    end
    
    return false
end

-- Check if a weapon enchant item can be applied to a specific weapon slot
-- Returns: true if compatible, false otherwise
function Module.CanEnchantApplyToSlot(enchantItemID, slotID)
    if not enchantItemID or not slotID then return false end
    
    -- Get the weapon item in the slot
    local weaponItemID = GetInventoryItemID and GetInventoryItemID("player", slotID)
    if not weaponItemID then return false end
    
    -- Get weapon item info
    local weaponName, weaponLink, _, _, _, weaponType, weaponSubType, _, weaponEquipLoc = GetItemInfo(weaponItemID)
    if not weaponType or not weaponEquipLoc then 
        -- If we can't get item info, be conservative and return false
        return false
    end
    
    -- Weapon must be a weapon type
    if weaponType ~= "Weapon" then return false end
    
    -- Get enchant item info to determine enchant type
    local enchantName, _, _, _, _, enchantType, enchantSubType = GetItemInfo(enchantItemID)
    if not enchantName then return false end
    
    -- Check enchant item name/type to determine compatibility
    local enchantNameLower = enchantName:lower()
    
    -- Helper: Check if weapon is melee (not ranged, not shield, not holdable)
    local function IsMeleeWeapon(equipLoc)
        if not equipLoc then return false end
        -- Explicitly check for melee weapon types
        if equipLoc == "INVTYPE_WEAPON" or 
           equipLoc == "INVTYPE_WEAPONMAINHAND" or 
           equipLoc == "INVTYPE_WEAPONOFFHAND" or
           equipLoc == "INVTYPE_2HWEAPON" then
            return true
        end
        -- Exclude ranged, shields, and holdables
        if equipLoc == "INVTYPE_RANGED" or 
           equipLoc == "INVTYPE_RANGEDRIGHT" or
           equipLoc == "INVTYPE_SHIELD" or 
           equipLoc == "INVTYPE_HOLDABLE" or
           equipLoc == "INVTYPE_RELIC" or
           equipLoc == "INVTYPE_THROWN" then
            return false
        end
        -- For unknown types, be conservative
        return false
    end
    
    -- Oils, poisons, sharpening stones, and coatings only work on melee weapons
    if enchantNameLower:match("oil") or 
       enchantNameLower:match("poison") or 
       enchantNameLower:match("sharpening") or 
       enchantNameLower:match("weightstone") or
       enchantNameLower:match("coating") then
        -- Must be a melee weapon
        return IsMeleeWeapon(weaponEquipLoc)
    end
    
    -- For other enchant types, be conservative - only allow if it's explicitly a melee weapon
    -- This prevents trying to enchant incompatible items
    return IsMeleeWeapon(weaponEquipLoc)
end

-- Auto-detect which weapon slot to target for a weapon enchant
-- Returns: slot number (16=main hand, 17=offhand, 18=ranged) or nil
function Module.GetWeaponEnchantSlot(itemID)
    if not itemID then return 16 end  -- Default to main hand
    
    -- Get slot IDs
    local mainHandSlot = GetInventorySlotInfo and GetInventorySlotInfo("MainHandSlot") or 16
    local offHandSlot = GetInventorySlotInfo and GetInventorySlotInfo("SecondaryHandSlot") or 17
    -- RangedSlot was removed on post-DF (hunters use MainHandSlot); wrap in pcall to avoid Invalid inventory slot
    local rangedSlot = nil
    if GetInventorySlotInfo then
        local ok, slot = pcall(GetInventorySlotInfo, "RangedSlot")
        if ok and slot then
            rangedSlot = slot
        end
    end
    
    -- Get item spell ID to match against existing enchants
    local itemSpellName, itemSpellID
    if C_Item and C_Item.GetItemSpell then
        itemSpellName, itemSpellID = C_Item.GetItemSpell(itemID)
    elseif GetItemSpell then
        itemSpellName, itemSpellID = GetItemSpell(itemID)
    end
    
    -- Check if weapons have enchants and get expiration times (call once to get both main hand and offhand info)
    local mainHandHasEnchant = false
    local mainHandExpiration = 0
    local mainHandEnchantId = nil
    local offHandHasEnchant = false
    local offHandExpiration = 0
    local offHandEnchantId = nil
    if GetWeaponEnchantInfo then
        local hasMainHand, expirationMainHand, chargesMainHand, enchantIdMainHand, 
              hasOffHand, expirationOffHand, chargesOffHand, enchantIdOffHand = GetWeaponEnchantInfo()
        -- GetWeaponEnchantInfo can return boolean or number depending on WoW version
        -- Handle both cases
        if type(hasMainHand) == "boolean" then
            mainHandHasEnchant = hasMainHand
        elseif type(hasMainHand) == "number" then
            mainHandHasEnchant = hasMainHand > 0
        end
        if mainHandHasEnchant then
            -- Convert from milliseconds to seconds
            mainHandExpiration = (expirationMainHand or 0) / 1000
            mainHandEnchantId = enchantIdMainHand
        end
        
        if type(hasOffHand) == "boolean" then
            offHandHasEnchant = hasOffHand
        elseif type(hasOffHand) == "number" then
            offHandHasEnchant = hasOffHand > 0
        end
        if offHandHasEnchant then
            -- Convert from milliseconds to seconds
            offHandExpiration = (expirationOffHand or 0) / 1000
            offHandEnchantId = enchantIdOffHand
        end
    end
    
    -- Helper: Check if existing enchant on slot is from this item and needs refresh
    local function ShouldTargetSlot(slotID, hasEnchant, expirationRemaining, enchantId)
        if not Module.CanEnchantApplyToSlot(itemID, slotID) then
            return false
        end
        
        local slotItem = GetInventoryItemID and GetInventoryItemID("player", slotID)
        if not slotItem then
            return false
        end
        
        if not hasEnchant then
            -- No enchant - can target this slot
            return true
        end
        
        -- Has enchant - check if it's from this item and needs refresh
        -- Try to match by enchant ID or spell ID
        local isSameEnchant = false
        if enchantId and itemSpellID and enchantId == itemSpellID then
            isSameEnchant = true
        elseif enchantId and enchantId > 0 then
            -- Could be same enchant type (different items can create same enchant)
            -- For now, assume if enchant exists and is under threshold, we should refresh
            isSameEnchant = true
        end
        
        if isSameEnchant and expirationRemaining > 0 then
            -- Check if remaining time is under refresh threshold
            local threshold = Module.GetRefreshThreshold()
            if expirationRemaining <= threshold then
                -- Same enchant and under threshold - target this slot to refresh
                return true
            end
        end
        
        -- Different enchant or above threshold - don't target
        return false
    end
    
    -- Check if main hand slot has an item
    local mainHandItem = GetInventoryItemID and GetInventoryItemID("player", mainHandSlot)
    local offHandItem = GetInventoryItemID and GetInventoryItemID("player", offHandSlot)
    local rangedItem = (rangedSlot and GetInventoryItemID) and GetInventoryItemID("player", rangedSlot) or nil
    
    -- Determine if this enchant type can work on ranged weapons
    -- Most weapon enchants (oils, poisons, sharpening stones) don't work on ranged
    local enchantName = GetItemInfo(itemID)
    local canWorkOnRanged = false
    if enchantName then
        local enchantNameLower = enchantName:lower()
        -- Most enchants don't work on ranged, but check for exceptions
        -- For now, assume only unknown enchant types might work on ranged
        if not enchantNameLower:match("oil") and 
           not enchantNameLower:match("poison") and 
           not enchantNameLower:match("sharpening") and 
           not enchantNameLower:match("weightstone") and
           not enchantNameLower:match("coating") then
            -- Unknown enchant type - might work on ranged, check compatibility
            canWorkOnRanged = true
        end
    end
    
    -- Priority: main hand > offhand > ranged
    -- Target a slot if:
    -- 1. It has an item and is compatible
    -- 2. Either has no enchant, OR has this item's enchant that's under refresh threshold
    if ShouldTargetSlot(mainHandSlot, mainHandHasEnchant, mainHandExpiration, mainHandEnchantId) then
        return mainHandSlot
    end
    
    if ShouldTargetSlot(offHandSlot, offHandHasEnchant, offHandExpiration, offHandEnchantId) then
        return offHandSlot
    end
    
    -- Only check ranged slot if this enchant type might work on ranged weapons
    if canWorkOnRanged and rangedItem then
        if Module.CanEnchantApplyToSlot(itemID, rangedSlot) then
            -- For ranged, we don't check existing enchants (GetWeaponEnchantInfo doesn't return ranged info)
            return rangedSlot
        end
    end
    
    -- If no compatible slot found, return nil to indicate no valid target
    -- The calling code should handle this gracefully
    return nil
end

local CHARGE_UNKNOWN_SENTINEL = 999999

local function GetContainerStackCount(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and type(info.stackCount) == "number" then
            return info.stackCount
        end
    elseif GetContainerItemInfo then
        local _, itemCount = GetContainerItemInfo(bag, slot)
        if type(itemCount) == "number" then
            return itemCount
        end
    end
    return 1
end

local function CollectCarriedItemStacks(itemID)
    local candidates = {}
    itemID = tonumber(itemID)
    if not itemID then
        return candidates
    end

    local inv = _G.FluxInv
    if inv and inv.Bags and inv.Bags.FindStacks then
        local stacks = inv.Bags.FindStacks(itemID)
        for _, st in ipairs(stacks or {}) do
            if st.bag ~= nil and st.slot ~= nil then
                candidates[#candidates + 1] = {
                    bag = st.bag,
                    slot = st.slot,
                    stackCount = tonumber(st.count) or GetContainerStackCount(st.bag, st.slot),
                }
            end
        end
        if #candidates > 0 then
            return candidates
        end
    end

    local numBags = (FLUX_API and FLUX_API.isPostDF) and 5 or 4
    for bag = 0, numBags do
        local numSlots
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag)
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag)
        end

        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local slotItemID = FluxGetContainerItemID and FluxGetContainerItemID(bag, slot)
                    or (C_Container and C_Container.GetContainerItemID and C_Container.GetContainerItemID(bag, slot))
                    or (GetContainerItemID and GetContainerItemID(bag, slot))

                if slotItemID and slotItemID == itemID then
                    candidates[#candidates + 1] = {
                        bag = bag,
                        slot = slot,
                        stackCount = GetContainerStackCount(bag, slot),
                    }
                end
            end
        end
    end
    return candidates
end

local function IsPreferredCandidateBetter(a, b, preferCharges)
    if preferCharges then
        if a.charges ~= b.charges then
            return a.charges < b.charges
        end
    end
    if a.stackCount ~= b.stackCount then
        return a.stackCount < b.stackCount
    end
    if a.bag ~= b.bag then
        return a.bag < b.bag
    end
    return a.slot < b.slot
end

-- Find bag/slot for an item, preferring lowest stack or lowest remaining charges.
-- prefer: "stack" (default) or "charges"
-- Returns: bagID, slotIndex or nil, nil if not found
function Module.FindPreferredBagSlot(itemID, prefer)
    local candidates = CollectCarriedItemStacks(itemID)
    if #candidates == 0 then
        return nil, nil
    end

    local preferCharges = (prefer == "charges")
    local anyChargesKnown = false

    if preferCharges then
        local reg = _G.FluxRestockItemRegistry
        for _, c in ipairs(candidates) do
            local charges = nil
            if reg and reg.GetSlotCharges then
                charges = reg.GetSlotCharges(c.bag, c.slot)
            end
            if type(charges) == "number" and charges > 0 then
                c.charges = charges
                anyChargesKnown = true
            else
                c.charges = CHARGE_UNKNOWN_SENTINEL
            end
        end
        -- If no slot reported charges, fall back to lowest stack size.
        if not anyChargesKnown then
            preferCharges = false
        end
    else
        for _, c in ipairs(candidates) do
            c.charges = CHARGE_UNKNOWN_SENTINEL
        end
    end

    local best = candidates[1]
    for i = 2, #candidates do
        if IsPreferredCandidateBetter(candidates[i], best, preferCharges) then
            best = candidates[i]
        end
    end

    return best.bag, best.slot
end

-- Find the bag/slot of the weapon enchant item with the fewest remaining charges
-- Returns: bagID, slotIndex or nil, nil if not found
function Module.GetWeaponEnchantSlotWithLowestCharges(itemID)
    return Module.FindPreferredBagSlot(itemID, "charges")
end

function Module.GetBagSlotWithLowestStack(itemID)
    return Module.FindPreferredBagSlot(itemID, "stack")
end

local function StoreConsumablesBoundSlot(btn, bag, slot, prefer)
    if not btn then return end
    btn.ConsumablesBoundBag = bag
    btn.ConsumablesBoundSlot = slot
    btn.ConsumablesBoundPrefer = prefer
end

local function ClearConsumablesBoundSlot(btn)
    if not btn then return end
    btn.ConsumablesBoundBag = nil
    btn.ConsumablesBoundSlot = nil
    btn.ConsumablesBoundPrefer = nil
end

-- Check if item buff is eligible for refresh (missing or <= 5 min remaining)
-- Get item cooldown remaining time in seconds
-- Returns: remaining time in seconds, or 0 if not on cooldown
local function GetItemCooldownRemaining(itemID)
    if not itemID then return 0 end
    
    local startTime, duration, isEnabled = 0, 0, 0
    
    -- Try modern API first
    if C_Item and C_Item.GetItemCooldown then
        local cooldownInfo = C_Item.GetItemCooldown(itemID)
        if cooldownInfo and type(cooldownInfo) == "table" then
            startTime = cooldownInfo.startTime or 0
            duration = cooldownInfo.duration or 0
            isEnabled = (cooldownInfo.isEnabled and 1) or 0
        else
            startTime, duration, isEnabled = C_Item.GetItemCooldown(itemID)
            startTime = startTime or 0
            duration = duration or 0
            isEnabled = isEnabled and 1 or 0
        end
    elseif C_Container and C_Container.GetItemCooldown then
        local cooldownInfo = C_Container.GetItemCooldown(itemID)
        if cooldownInfo and type(cooldownInfo) == "table" then
            startTime = cooldownInfo.startTime or 0
            duration = cooldownInfo.duration or 0
            isEnabled = 1
        else
            startTime, duration = C_Container.GetItemCooldown(itemID)
            startTime = startTime or 0
            duration = duration or 0
            isEnabled = 1
        end
    elseif GetItemCooldown then
        startTime, duration, isEnabled = GetItemCooldown(itemID)
        startTime = startTime or 0
        duration = duration or 0
        isEnabled = isEnabled and 1 or 0
    end
    
    -- Check if item is on cooldown
    if isEnabled == 1 and duration > 0 then
        local remaining = (startTime + duration) - GetTime()
        if remaining > 0 then
            return remaining
        end
    end
    
    return 0
end

function Module.IsItemEligible(itemID, ignoreCooldown)
    if not itemID then return false, nil end
    
    -- Must be in bags
    local count = Module.GetItemCount(itemID)
    if count <= 0 then
        return false, nil
    end
    
    -- Check item cooldown - skip if on cooldown for more than 10 seconds (unless ignoreCooldown is true)
    if not ignoreCooldown then
        local cooldownRemaining = GetItemCooldownRemaining(itemID)
        if cooldownRemaining > 10 then
            return false, nil  -- Item is on cooldown, skip it
        end
    end
    
    -- For Chronoboon items, check world buff and SuperCharged buff status
    if Module.IsChronoboonItem(itemID) then
        local hasSuperchargedBuff = Module.HasSuperchargedChronoboonBuff()
        local hasSuperchargedInBags = Module.HasSuperchargedChronoboonInBags()
        local isSupercharged = Module.IsSuperchargedChronoboonItem(itemID)
        
        if isSupercharged then
            if hasSuperchargedBuff then
                return true, nil
            end
            -- Store the active world buff in supercharged Chronoboon before booning a new one.
            if Module.HasWorldBuff() then
                return true, nil
            end
            return false, nil
        end
        
        if Module.HasWorldBuff() then
            return true, nil
        end
        return false, nil
    end
    
    -- For weapon enchant items, check buff status first
    -- Skip only if enchant is applied AND above threshold
    -- Don't skip if enchant is missing OR under threshold
    if Module.IsWeaponEnchantItem(itemID) then
        -- Check if there's a compatible weapon slot first
        local targetSlot = Module.GetWeaponEnchantSlot(itemID)
        if not targetSlot then
            -- No compatible weapon slot - treat as "not eligible" (can't use this enchant)
            return false, nil
        end
        
        -- Check buff status (FindBuffForItem now detects weapon enchant buffs)
        local buff = Module.FindBuffForItem(itemID)
        if not buff then
            -- No weapon enchant active = eligible (need to apply it)
            return true, nil
        end
        
        -- Check remaining time
        local remaining = BuffRemainingSeconds(buff)
        local threshold = Module.GetRefreshThreshold()
        if remaining <= threshold then
            -- Enchant expires soon = eligible (need to refresh it)
            return true, buff
        end
        
        -- Enchant active with >threshold = not eligible (skip this item)
        return false, buff
    end
    
    -- Regular consumable: Check buff status
    local buff = Module.FindBuffForItem(itemID)
    if not buff then
        return true, nil -- No buff = eligible
    end
    
    -- Check remaining time
    local remaining = BuffRemainingSeconds(buff)
    local threshold = Module.GetRefreshThreshold()
    if remaining <= threshold then
        return true, buff -- Buff expires soon = eligible
    end
    
    return false, buff -- Buff active with >threshold = not eligible
end

-- Get the first eligible item from the list
function Module.GetFirstEligibleItem()
    local items = Module.GetItems()
    
    -- First pass: try to find an eligible item without cooldown
    local firstEligibleWithCooldown = nil
    local firstEligibleBuff = nil
    
    for _, itemID in ipairs(items) do
        local eligible, buff = Module.IsItemEligible(itemID, false)  -- Check cooldown
        if eligible then
            return itemID, buff  -- Found one without cooldown, return it
        end
        
        -- Also check if it would be eligible ignoring cooldown (for fallback)
        if not firstEligibleWithCooldown then
            local eligibleIgnoreCooldown, buffIgnoreCooldown = Module.IsItemEligible(itemID, true)
            if eligibleIgnoreCooldown then
                firstEligibleWithCooldown = itemID
                firstEligibleBuff = buffIgnoreCooldown
            end
        end
    end
    
    -- If no item found without cooldown, but we found one with cooldown, return it anyway
    -- This handles the case where all higher priority items are active and only items on cooldown remain
    if firstEligibleWithCooldown then
        return firstEligibleWithCooldown, firstEligibleBuff
    end
    
    -- Supercharged Chronoboon in bags: show on button when no higher-priority item is ready.
    if Module.HasSuperchargedChronoboonInBags() then
        local superID = GetSuperChronoboonItemIDInBags()
        if superID then
            return superID, nil
        end
    end
    
    return nil, nil
end

-- Regular (non-Supercharged) Chronoboon in bags while world buffs exist
function Module.GetEligibleRegularChronoboonItemID()
    if not Module.HasWorldBuff() then
        return nil
    end
    local chronoboonIDs = Module.FindChronoboonItemIDs()
    for _, chronoboonID in ipairs(chronoboonIDs) do
        if not Module.IsSuperchargedChronoboonItem(chronoboonID) and Module.GetItemCount(chronoboonID) > 0 then
            return chronoboonID
        end
    end
    return nil
end

-- When a higher-priority consumable is shown but Chronoboon is also usable (world buff + regular Chrono), allow Shift/Ctrl/Alt+click to use Chronoboon (SecureActionButton shift-type / ctrl-type / alt-type)
function Module.GetChronoboonModifierOverrideChronoID(primaryItemID)
    if not primaryItemID or Module.IsChronoboonItem(primaryItemID) then
        return nil
    end
    if not Module.HasWorldBuff() then
        return nil
    end
    local chrono = Module.GetEligibleRegularChronoboonItemID()
    if not chrono or not Module.IsItemEligible(chrono, false) then
        return nil
    end
    return chrono
end

--- Extra Paint owns usable/CD/range/glow (same as Extra slots / flyout hosts).
function Module.RefreshConsumablesUsability(btn)
    if not btn or not btn.WIcon then
        return
    end
    if Module._isWispLocked or btn.IsWispLockPlaceholder or btn.PlaceholderTexture == WISP_LOCK_ICON then
        return
    end
    if btn.PlaceholderTexture or btn.IsConsumablesPlaceholder then
        return
    end
    local itemID = btn.ConsumablesItemID or btn.ConsumablesCurrentItem or btn.ItemId
    if btn._consumablesModChronoVisual and btn.ConsumablesModifierChronoboonID then
        itemID = btn.ConsumablesModifierChronoboonID
    end
    if not itemID then
        return
    end
    btn.ItemId = itemID
    btn.MacroMode = "item"
    btn._fluxManagedFaceItemId = itemID
    btn._fluxManagedFaceSpellId = nil
    local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
    if Paint and Paint.UpdateLiveFace then
        Paint.UpdateLiveFace(btn)
        return
    end
    local U = _G.FluxButtonUsability
    if not U or not U.CheckItemUsability or not U.ApplyVisualFeedback then
        return
    end
    local state, mana = U:CheckItemUsability(itemID)
    btn._isUsable = (state == U.STATE_USABLE or state == U.STATE_UNKNOWN)
    btn._notEnoughMana = mana or (state == U.STATE_NOT_ENOUGH_MANA)
    btn._usabilityState = state
    U:ApplyVisualFeedback(btn, state, mana)
end

local function RestoreConsumablesPrimaryAppearance(btn)
    if not btn or (not btn.WIcon and not (btn.Widget and btn.Widget.icon)) then
        return
    end
    local id = btn.ConsumablesCurrentItem
    if not id then
        return
    end
    local name, link, icon = GetCachedItemInfo(id)
    if not icon then
        name, link, _, _, _, _, _, _, _, icon = GetItemInfo(id)
    end
    if icon then
        if btn.WIcon then
            btn.WIcon:SetTexture(icon)
            btn.WIcon:Show()
        end
        if btn.Widget and btn.Widget.icon then
            btn.Widget.icon:SetTexture(icon)
            btn.Widget.icon:Show()
        end
    end
    if btn.WCount then
        local c = Module.GetItemCount(id)
        if c > 0 then
            btn.WCount:SetText(tostring(c))
            btn.WCount:SetTextColor(1, 1, 1, 1)
        else
            btn.WCount:SetText("0")
            btn.WCount:SetTextColor(1, 0.3, 0.3, 1)
        end
        btn.WCount:Show()
    end
    Module.RefreshConsumablesUsability(btn)
end

-- SecureActionButton uses modifier-name-buttonNumber (e.g. shift-type1 = Shift+left). Plain "shift-type" is ignored.
-- FluxButton sets type + typerelease for items; match both for modifier clicks (see Blizzard SecureTemplates.lua).
local function ClearConsumablesModifierSecureAttrs(widget)
    local legacy = {
        "shift-type", "shift-item", "shift-macrotext", "shift-typerelease",
        "ctrl-type", "ctrl-item", "ctrl-macrotext", "ctrl-typerelease",
        "alt-type", "alt-item", "alt-macrotext", "alt-typerelease",
    }
    local numbered = {
        "shift-type1", "shift-item1", "shift-macrotext1", "shift-typerelease1",
        "ctrl-type1", "ctrl-item1", "ctrl-macrotext1", "ctrl-typerelease1",
        "alt-type1", "alt-item1", "alt-macrotext1", "alt-typerelease1",
    }
    for _, k in ipairs(legacy) do
        widget:SetAttribute(k, nil)
    end
    for _, k in ipairs(numbered) do
        widget:SetAttribute(k, nil)
    end
end

-- FluxButtonCore sets unnumbered type/item; that also applies to right-click. Bind use to button 1 only (ManaGem.lua).
-- SetAttribute is blocked during combat; ClearAction can run from UpdateButtonState while fighting (e.g. empty preset).
local function ClearConsumablesSecureClickAttrs(widget)
    if not widget then return end
    if InCombatLockdown() then
        Timer.After(0.2, function()
            if widget and not widget:IsForbidden() then
                ClearConsumablesSecureClickAttrs(widget)
            end
        end)
        return
    end
    widget:SetAttribute("type", nil)
    widget:SetAttribute("typerelease", nil)
    widget:SetAttribute("spell", nil)
    widget:SetAttribute("item", nil)
    widget:SetAttribute("macro", nil)
    widget:SetAttribute("macrotext", nil)
    widget:SetAttribute("action", nil)
    widget:SetAttribute("clickbutton", nil)
    widget:SetAttribute("id", nil)
    widget:SetAttribute("type1", nil)
    widget:SetAttribute("typerelease1", nil)
    widget:SetAttribute("item1", nil)
    widget:SetAttribute("macrotext1", nil)
    widget:SetAttribute("type2", nil)
    widget:SetAttribute("typerelease2", nil)
    widget:SetAttribute("macrotext2", nil)
    widget:SetAttribute("item2", nil)
end

local function ApplyPrimaryUseToButton1Only(widget, itemID, bag, slot)
    if not widget or not itemID then return end
    local itemAttr
    if bag ~= nil and slot ~= nil then
        itemAttr = tostring(bag) .. " " .. tostring(slot)
    else
        local itemName = GetItemInfo and GetItemInfo(itemID)
        itemAttr = itemName or ("item:" .. tostring(itemID))
    end
    widget:SetAttribute("type", nil)
    widget:SetAttribute("typerelease", nil)
    widget:SetAttribute("item", nil)
    widget:SetAttribute("macro", nil)
    widget:SetAttribute("macrotext", nil)
    widget:SetAttribute("type1", "item")
    widget:SetAttribute("typerelease1", "item")
    widget:SetAttribute("item1", itemAttr)
end

local function BindRegularConsumableUse(btn, itemID, prefer)
    prefer = prefer or "stack"
    local bag, slot = Module.FindPreferredBagSlot(itemID, prefer)
    if btn.SetAction then
        btn:SetAction("item", itemID)
    elseif btn.Widget then
        btn.Widget:SetAttribute("type", "item")
        btn.Widget:SetAttribute("item", "item:" .. itemID)
    end
    if btn.Widget then
        ApplyPrimaryUseToButton1Only(btn.Widget, itemID, bag, slot)
    end
    StoreConsumablesBoundSlot(btn, bag, slot, prefer)
    return bag, slot
end

local function ApplyWeaponEnchantMacroToButton1Only(widget, macrotext)
    if not widget or not macrotext then return end
    widget:SetAttribute("type", nil)
    widget:SetAttribute("typerelease", nil)
    widget:SetAttribute("item", nil)
    widget:SetAttribute("macro", nil)
    widget:SetAttribute("macrotext", nil)
    widget:SetAttribute("type1", "macro")
    widget:SetAttribute("typerelease1", "macro")
    widget:SetAttribute("macrotext1", macrotext)
end

-- Lightweight rebind of preferred bag/slot without full SetItemMode (bag count refresh).
-- Returns true if attributes were updated.
function Module.RebindPreferredUseSlot(btn)
    if not btn or InCombatLockdown() then
        return false
    end
    if Module._isWispLocked or btn.IsWispLocked or btn.IsWispLockPlaceholder or btn.IsConsumablesPlaceholder then
        return false
    end
    local itemID = btn.ConsumablesItemID
    if not itemID then
        return false
    end

    local prefer = btn.ConsumablesBoundPrefer
    if not prefer then
        prefer = Module.IsWeaponEnchantItem(itemID) and "charges" or "stack"
    end

    local bag, slot = Module.FindPreferredBagSlot(itemID, prefer)
    if bag == btn.ConsumablesBoundBag and slot == btn.ConsumablesBoundSlot then
        return false
    end

    if btn.ConsumablesIsWeaponEnchant then
        local targetSlot = Module.GetWeaponEnchantSlot(itemID)
        if not targetSlot then
            BindRegularConsumableUse(btn, itemID, prefer)
            return true
        end
        local useCmd
        if bag and slot then
            useCmd = "/use [btn:1] " .. bag .. " " .. slot
        else
            useCmd = "/use [btn:1] item:" .. itemID
        end
        local macrotext = useCmd .. "\n/use [btn:1] " .. targetSlot .. "\n/click [btn:1] StaticPopup1Button1"
        if btn.SetAction then
            btn:SetAction("macrotext", macrotext)
        elseif btn.Widget then
            btn.Widget:SetAttribute("type", "macro")
            btn.Widget:SetAttribute("macrotext", macrotext)
        end
        if btn.Widget then
            ApplyWeaponEnchantMacroToButton1Only(btn.Widget, macrotext)
        end
        StoreConsumablesBoundSlot(btn, bag, slot, prefer)
        return true
    end

    if btn.Widget then
        ApplyPrimaryUseToButton1Only(btn.Widget, itemID, bag, slot)
    end
    StoreConsumablesBoundSlot(btn, bag, slot, prefer)
    return true
end

local function SetConsumablesModifierItemUseAttrs(widget, itemAttr)
    for _, prefix in ipairs({ "shift-", "ctrl-", "alt-" }) do
        widget:SetAttribute(prefix .. "type1", "item")
        widget:SetAttribute(prefix .. "typerelease1", "item")
        widget:SetAttribute(prefix .. "item1", itemAttr)
    end
end

-- Chronoboon modifier preview: demand-driven via FluxModifierTracker (not per-frame OnUpdate).
local consumablesChronoPreviewBtn = nil

local function ConsumablesChronoModifierCallback()
    if consumablesChronoPreviewBtn then
        Module.ApplyConsumablesChronoboonModifierVisual(consumablesChronoPreviewBtn)
    end
end

local function ConsumablesChronoModifierActive()
    return consumablesChronoPreviewBtn
        and consumablesChronoPreviewBtn.ConsumablesChronoboonModifierLayer
        and consumablesChronoPreviewBtn._consumablesModifierPreviewActive
end

local function SetConsumablesModifierPreviewActive(btn, active)
    if not btn then return end
    if active then
        consumablesChronoPreviewBtn = btn
        btn._consumablesModifierPreviewActive = true
    elseif consumablesChronoPreviewBtn == btn then
        consumablesChronoPreviewBtn = nil
        btn._consumablesModifierPreviewActive = nil
    end
    if FluxModifierTracker and FluxModifierTracker.NotifyActiveChanged then
        FluxModifierTracker.NotifyActiveChanged()
    end
    if active then
        Module.ApplyConsumablesChronoboonModifierVisual(btn)
    end
end

local function EnsureConsumablesModifierDriver(btn)
    -- Legacy no-op: modifier preview uses FluxModifierTracker.
    if btn then
        btn._consumablesModifierDriver = btn._consumablesModifierDriver or true
    end
end

function Module.ApplyConsumablesChronoboonModifierVisual(btn)
    if not btn then
        return
    end
    if not btn.ConsumablesChronoboonModifierLayer or not btn.ConsumablesModifierChronoboonID then
        if btn._consumablesModChronoVisual then
            RestoreConsumablesPrimaryAppearance(btn)
            btn._consumablesModChronoVisual = nil
        end
        return
    end
    local chrono = btn.ConsumablesModifierChronoboonID
    local wantChrono = IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown()
    if wantChrono then
        local name, link, icon = GetCachedItemInfo(chrono)
        if not icon then
            name, link, _, _, _, _, _, _, _, icon = GetItemInfo(chrono)
        end
        if icon then
            if btn.WIcon then
                btn.WIcon:SetTexture(icon)
                btn.WIcon:Show()
            end
            if btn.Widget and btn.Widget.icon then
                btn.Widget.icon:SetTexture(icon)
                btn.Widget.icon:Show()
            end
        end
        Module.RefreshConsumablesUsability(btn)
        if btn.WCount then
            local c = Module.GetItemCount(chrono)
            if c > 0 then
                btn.WCount:SetText(tostring(c))
                btn.WCount:SetTextColor(1, 1, 1, 1)
            else
                btn.WCount:SetText("0")
                btn.WCount:SetTextColor(1, 0.3, 0.3, 1)
            end
            btn.WCount:Show()
        end
        btn._consumablesModChronoVisual = true
    else
        if btn._consumablesModChronoVisual then
            RestoreConsumablesPrimaryAppearance(btn)
            btn._consumablesModChronoVisual = nil
        end
    end
end

function Module.ApplyChronoboonModifierLayer(btn, primaryItemID)
    if not btn or not btn.Widget then
        return
    end
    if InCombatLockdown() then
        Timer.After(0.2, function()
            Module.ApplyChronoboonModifierLayer(btn, primaryItemID)
        end)
        return
    end
    local widget = btn.Widget
    if btn._consumablesModChronoVisual then
        RestoreConsumablesPrimaryAppearance(btn)
        btn._consumablesModChronoVisual = nil
    end
    ClearConsumablesModifierSecureAttrs(widget)

    local chrono = Module.GetChronoboonModifierOverrideChronoID(primaryItemID)
    if not chrono then
        btn.ConsumablesChronoboonModifierLayer = nil
        btn.ConsumablesModifierChronoboonID = nil
        SetConsumablesModifierPreviewActive(btn, false)
        return
    end

    local itemName = GetItemInfo and GetItemInfo(chrono)
    local itemAttr = itemName or ("item:" .. tostring(chrono))
    SetConsumablesModifierItemUseAttrs(widget, itemAttr)

    btn.ConsumablesChronoboonModifierLayer = true
    btn.ConsumablesModifierChronoboonID = chrono
    EnsureConsumablesModifierDriver(btn)
    SetConsumablesModifierPreviewActive(btn, true)
end

function Module.ClearChronoboonModifierLayer(btn)
    if not btn or not btn.Widget then
        return
    end
    if InCombatLockdown() then
        Timer.After(0.2, function()
            Module.ClearChronoboonModifierLayer(btn)
        end)
        return
    end
    local widget = btn.Widget
    ClearConsumablesModifierSecureAttrs(widget)
    btn.ConsumablesChronoboonModifierLayer = nil
    btn.ConsumablesModifierChronoboonID = nil
    btn._consumablesModChronoVisual = nil
    SetConsumablesModifierPreviewActive(btn, false)
end

-- Check WISP LOCK state (all items active with >5min remaining)
-- Returns: isWispLocked, minRemaining, minRemainingBuff, isStable
function Module.CheckWispLockState()
    local items = Module.GetItems()
    
    if #items == 0 then
        return false, 0, nil, false
    end
    
    local hasAnyInBags = false
    local allBuffed = true
    local minRemaining = math.huge
    local minRemainingBuff = nil
    
    for _, itemID in ipairs(items) do
        local count = Module.GetItemCount(itemID)
        if count > 0 then
            hasAnyInBags = true
            
            local buff = Module.FindBuffForItem(itemID)
            if not buff then
                allBuffed = false
                break
            end
            
            local remaining = BuffRemainingSeconds(buff)
            -- Check if buff expired or is invalid
            if not isfinite(remaining) or remaining <= 0 then
                allBuffed = false
                break
            end
            local threshold = Module.GetRefreshThreshold()
            if remaining <= threshold then
                allBuffed = false
                break
            end
            
            if remaining < minRemaining and remaining > 0 and isfinite(remaining) then
                minRemaining = remaining
                minRemainingBuff = buff
            end
        end
    end
    
    -- If not all buffed, immediately exit WISP LOCK (no stability check needed)
    if not allBuffed then
        return false, 0, nil, true  -- isStable = true to allow immediate exit
    end
    
    -- Validate minRemaining is finite
    if not isfinite(minRemaining) or minRemaining <= 0 or minRemaining == math.huge then
        return false, 0, nil, true  -- isStable = true to allow immediate exit
    end
    
    local isWispLocked = (hasAnyInBags and allBuffed)
    local isStable = true
    
    -- Stability check: if we were in WISP LOCK, require consistent state for a short time before exiting
    -- BUT: if a buff expired or is below threshold, exit immediately (no stability delay)
    if Module._isWispLocked and not isWispLocked then
        -- Buff expired or below threshold - exit immediately
        Module._wispLockStableTime = 0
        isStable = true
    elseif isWispLocked then
        -- Entering or staying in WISP LOCK - reset stability timer
        Module._wispLockStableTime = 0
    end
    
    if isWispLocked then
        return true, minRemaining, minRemainingBuff, isStable
    end
    
    return false, 0, nil, false
end

-- ============================================================================
-- USE CONSUMABLE
-- ============================================================================

function Module.UseNextConsumable()
    -- Combat check
    if InCombatLockdown() then
        return false
    end
    
    -- WISP LOCK check
    if Module._isWispLocked then
        return false
    end
    
    local itemID = Module.GetFirstEligibleItem()
    if not itemID then
        return false
    end
    
    local prefer = Module.IsWeaponEnchantItem(itemID) and "charges" or "stack"
    local bag, slot = Module.FindPreferredBagSlot(itemID, prefer)
    local macroText
    if bag and slot then
        macroText = "/use " .. bag .. " " .. slot
    else
        local itemName = GetCachedItemInfo(itemID)
        if itemName then
            macroText = "/use " .. itemName
        else
            macroText = "/use item:" .. tostring(itemID)
        end
    end

    if macroText then
        local body = SecureCmdOptionParse(macroText)
        if body then
            if ChatFrame1 and ChatFrame1.editBox then
                ChatFrame1.editBox:SetText(macroText)
                ChatEdit_SendText(ChatFrame1.editBox)
            end
        end
    end
    
    -- Schedule update
    Timer.After(0.10, function()
        Module.UpdateButtonState()
    end)
    
    -- Immediate UI reaction
    Module.UpdateButtonState()
    
    return true
end

-- ============================================================================
-- PLACEHOLDER HANDLING
-- ============================================================================

local function SetPlaceholder(btn)
    if not btn then return end
    
    -- Combat safety: queue placeholder change if in combat
    if InCombatLockdown() then
        -- Queue placeholder change (will be applied after combat)
        Module._pendingItemChange = nil  -- Clear any pending item change
        -- Placeholder doesn't need special queue, just prevent the change during combat
        return
    end
    
    -- Clear weapon enchant state so restore block won't re-display item on next UpdateButtonState
    if btn.ConsumablesIsWeaponEnchant then
        btn.ConsumablesIsWeaponEnchant = nil
        btn.ConsumablesItemID = nil
        btn.ConsumablesWeaponEnchantUpdateHooked = nil
    end
    ClearConsumablesBoundSlot(btn)
    
    Module._isPlaceholder = true
    Module._isWispLocked = false
    Module._wispLockBuff = nil
    ClearConsumableAuraTimer(btn)
    btn.IsConsumablesPlaceholder = true
    btn.IsWispLocked = false  -- Clear WISP LOCK flag
    
    -- Clear WISP LOCK placeholder state if it was set
    if btn.IsWispLockPlaceholder then
        btn.IsWispLockPlaceholder = nil
    end
    
    if btn.SetPlaceholder then
        btn:SetPlaceholder(PLACEHOLDER_ICON, PLACEHOLDER_LABEL)
    else
        btn.PlaceholderTexture = PLACEHOLDER_ICON
        btn.PlaceholderLabel = PLACEHOLDER_LABEL
        if btn.ClearAction then
            btn:ClearAction()
        end
        if btn.UpdateAppearance then
            btn:UpdateAppearance()
        elseif btn.FullRefresh then
            btn:FullRefresh()
        end
    end
    
    -- Hide cooldown overlay
    if btn.Widget and btn.Widget.cooldown then
        btn.Widget.cooldown:Hide()
    end
    if btn.WCooldown then
        btn.WCooldown:Hide()
    end
    
    -- Blank the count. Leave the region shown so the next digit can land.
    if btn.WCount then
        btn.WCount:Show()
        btn.WCount:SetText("")
    end
    btn.PlaceholderHideCount = true

    Module.ClearChronoboonModifierLayer(btn)
    if btn.Widget then
        ClearConsumablesSecureClickAttrs(btn.Widget)
    end
    if not InCombatLockdown() then
        Module.SetupRightClickConfig(btn)
    end
end

local function SetWispLock(btn, minRemaining, minRemainingBuff)
    if not btn then return end
    
    -- Combat safety: queue WISP LOCK change if in combat
    if InCombatLockdown() then
        -- Queue WISP LOCK change (will be applied after combat)
        Module._pendingWispLockChange = {
            minRemaining = minRemaining,
            minRemainingBuff = minRemainingBuff
        }
        -- Don't change button state during combat
        return
    end
    
    -- CRITICAL: Clear weapon enchant flags when entering WISP LOCK
    -- This prevents SetItemMode from being called and causing flickering
    if btn.ConsumablesIsWeaponEnchant then
        btn.ConsumablesIsWeaponEnchant = nil
        btn.ConsumablesWeaponEnchantUpdateHooked = nil
    end
    
    -- If already in WISP LOCK, only update cooldown (don't change icon/action)
    if Module._isWispLocked then
        -- Update cooldown if remaining time changed
        if math.abs((Module._wispLockMinRemaining or 0) - minRemaining) > 0.5 then
            Module._wispLockMinRemaining = minRemaining
            Module._wispLockBuff = minRemainingBuff
            Module.UpdateWispLockCooldown(btn, minRemaining, minRemainingBuff)
        end
        return
    end
    
    Module.ClearChronoboonModifierLayer(btn)
    
    Module._isPlaceholder = false
    Module._isWispLocked = true
    Module._wispLockMinRemaining = minRemaining
    Module._wispLockBuff = minRemainingBuff
    btn.IsConsumablesPlaceholder = false
    btn.IsWispLocked = true  -- Flag to prevent external updates
    btn.IsWispLockPlaceholder = true  -- Flag to distinguish from regular placeholder
    ClearConsumablesBoundSlot(btn)
    
    -- Use SetPlaceholder to leverage FluxButton's built-in flicker prevention
    -- Set PlaceholderHideCount to hide count text
    btn.PlaceholderHideCount = true
    if btn.SetPlaceholder then
        btn:SetPlaceholder(WISP_LOCK_ICON, "WISP LOCK")
    else
        btn.PlaceholderTexture = WISP_LOCK_ICON
        btn.PlaceholderLabel = "WISP LOCK"
        if btn.ClearAction then
            btn:ClearAction()
        end
    end
    
    -- Override the desaturated styling that SetPlaceholder applies
    -- WISP icon should be normal (not desaturated/gray like regular placeholders)
    if btn.WIcon then
        btn.WIcon:SetDesaturated(false)
        btn.WIcon:SetVertexColor(1, 1, 1, 1)
    end
    if btn.Widget and btn.Widget.icon then
        btn.Widget.icon:SetDesaturated(false)
        btn.Widget.icon:SetVertexColor(1, 1, 1, 1)
    end
    
    -- Blank the count. Leave the region shown so the next digit can land.
    if btn.WCount then
        btn.WCount:Show()
        btn.WCount:SetText("")
    end
    
    -- Show cooldown swipe for min remaining buff
    Module.UpdateWispLockCooldown(btn, minRemaining, minRemainingBuff)

    if btn.Widget then
        ClearConsumablesSecureClickAttrs(btn.Widget)
    end
    if not InCombatLockdown() then
        Module.SetupRightClickConfig(btn)
    end
end

function Module.UpdateWispLockCooldown(btn, minRemaining, minRemainingBuff)
    if not btn or not minRemaining or minRemaining <= 0 then return end
    
    -- Validate minRemaining is finite
    if not isfinite(minRemaining) then
        local cooldown = btn.WCooldown or (btn.Widget and btn.Widget.cooldown)
        if cooldown then cooldown:Hide() end
        return
    end
    
    -- Verify we're in WISP LOCK placeholder state
    if btn.PlaceholderTexture ~= WISP_LOCK_ICON and not btn.IsWispLockPlaceholder then
        return
    end
    
    local threshold = Module.GetRefreshThreshold() or 0
    if minRemaining <= threshold then
        local cooldown = btn.WCooldown or (btn.Widget and btn.Widget.cooldown)
        if cooldown then cooldown:Hide() end
        return
    end
    
    -- Ensure icon styling is correct (not desaturated)
    if btn.WIcon then
        btn.WIcon:SetDesaturated(false)
        btn.WIcon:SetVertexColor(1, 1, 1, 1)
    end
    
    -- Blank the count. Leave the region shown so the next digit can land.
    if btn.WCount then
        btn.WCount:Show()
        btn.WCount:SetText("")
    end
    
    -- Ensure PlaceholderHideCount is set
    btn.PlaceholderHideCount = true
    
    local cooldown = btn.WCooldown or (btn.Widget and btn.Widget.cooldown)
    if not cooldown then return end
    
    -- Force show cooldown (FluxButton might hide it for placeholders)
    cooldown:Show()
    
    -- Cooldown ring shows proportional fill: from buff apply to refresh point
    -- startTime = when buff was applied; duration = maxDuration - threshold (period until refresh)
    -- Ring fills proportionally: 15min remaining of 30min buff = half filled
    local maxDuration = 0
    if minRemainingBuff and minRemainingBuff.maxDuration and minRemainingBuff.maxDuration > 0 and isfinite(minRemainingBuff.maxDuration) then
        maxDuration = minRemainingBuff.maxDuration
    elseif minRemainingBuff and minRemainingBuff.duration and minRemainingBuff.duration > 0 and isfinite(minRemainingBuff.duration) then
        maxDuration = minRemainingBuff.duration
    else
        maxDuration = minRemaining
    end
    
    local expirationTime = 0
    if minRemainingBuff and minRemainingBuff.expirationTime and isfinite(minRemainingBuff.expirationTime) then
        expirationTime = minRemainingBuff.expirationTime
    else
        expirationTime = GetTime() + minRemaining
    end
    
    -- Period from "buff applied" to "time to refresh" = maxDuration - threshold
    local displayDuration = math.max(1, maxDuration - threshold)
    -- When buff was applied
    local startTime = expirationTime - maxDuration
    
    if not isfinite(startTime) or not isfinite(displayDuration) or displayDuration <= 0 then
        cooldown:Hide()
        return
    end
    
    cooldown:SetCooldown(startTime, displayDuration)
    cooldown.noCooldownCount = true
    cooldown:Show()
    ApplyConsumableAuraTimer(btn, minRemainingBuff)
end

-- Right-click opens config (same pattern as Food.lua SetupRightClickConjure: type2 + macrotext2 on SecureActionButton)
function Module.SetupRightClickConfig(btn)
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Timer.After(0.2, function() Module.SetupRightClickConfig(btn) end)
        return
    end
    local widget = btn.Widget
    widget:SetAttribute("type2", nil)
    widget:SetAttribute("typerelease2", nil)
    widget:SetAttribute("macrotext2", nil)
    widget:SetAttribute("type2", "macro")
    widget:SetAttribute("typerelease2", "macro")
    widget:SetAttribute("macrotext2", (FluxMacroClickProxies and FluxMacroClickProxies.MACRO_CONSUMABLES_CONFIG) or "/click FluxMacroProxy_ConsumablesConfig")
end

local function SetItemMode(btn, itemID, buff)
    if not btn or not itemID then return end
    
    -- Combat safety: queue item change if in combat
    if InCombatLockdown() then
        -- Queue item change (will be applied after combat)
        Module._pendingItemChange = {
            itemID = itemID,
            buff = buff
        }
        -- Don't change button state during combat
        return
    end
    
    -- CRITICAL: Don't set item mode if we're in WISP LOCK placeholder (prevent flickering)
    if Module._isWispLocked or btn.IsWispLocked or btn.PlaceholderTexture == WISP_LOCK_ICON or btn.IsWispLockPlaceholder then
        return
    end
    
    Module._isPlaceholder = false
    Module._isWispLocked = false
    btn.IsConsumablesPlaceholder = false
    btn.IsWispLocked = false  -- Clear WISP LOCK flag
    
    -- Clear placeholder state
    if btn.ClearPlaceholder then
        btn:ClearPlaceholder()
    else
        btn.PlaceholderTexture = nil
        btn.PlaceholderLabel = nil
    end
    
    -- Check if this is a weapon enchant item
    if Module.IsWeaponEnchantItem(itemID) then
        -- Get target slot for weapon enchant
        local targetSlot = Module.GetWeaponEnchantSlot(itemID)
        
        -- If no compatible slot found, fall back to regular item usage
        if not targetSlot then
            -- No compatible weapon slot - use as regular item (game will show error if needed)
            -- Prefer lowest charges when available, else lowest stack
            BindRegularConsumableUse(btn, itemID, "charges")
            btn.ConsumablesItemID = itemID
        else
            -- Get item name for macro
            local itemName, _, _ = GetCachedItemInfo(itemID)
            if not itemName then
                itemName = GetItemInfo(itemID)
            end
            
            -- Build macro text: [btn:1] for left-click only (apply weapon enchant)
            -- Right-click handled via type2 below - [btn:2] in /run is invalid Lua
            -- Prefer bag/slot with lowest charges so partially-used items are consumed first
            local useCmd
            local bag, slot
            if itemID then
                bag, slot = Module.GetWeaponEnchantSlotWithLowestCharges(itemID)
                if bag and slot then
                    useCmd = "/use [btn:1] " .. bag .. " " .. slot
                else
                    useCmd = "/use [btn:1] item:" .. itemID
                end
            else
                useCmd = "/use [btn:1] " .. (itemName or "")
            end
            local macrotext = useCmd .. "\n/use [btn:1] " .. targetSlot .. "\n/click [btn:1] StaticPopup1Button1"
            
            -- Set macro action via SetAction (clears all attributes first, prevents wrong action on click)
            if btn.SetAction then
                btn:SetAction("macrotext", macrotext)
            elseif btn.Widget then
                btn.Widget:SetAttribute("type", "macro")
                btn.Widget:SetAttribute("macrotext", macrotext)
            end
            if btn.Widget then
                ApplyWeaponEnchantMacroToButton1Only(btn.Widget, macrotext)
            end
            StoreConsumablesBoundSlot(btn, bag, slot, "charges")
            
            -- CRITICAL: For weapon enchants with macro actions, we need to manually set icon and count
            -- because FluxButton might clear them when it sees a macro action
            -- Get item info first
            local name, link, icon = GetCachedItemInfo(itemID)
            if not icon then
                name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
            end
            
            -- Force set icon (override any clearing by FluxButton); tint via usability after.
            if btn.WIcon then
                if icon then
                    btn.WIcon:SetTexture(icon)
                else
                    btn.WIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end
                btn.WIcon:Show()
            end
            
            -- Force set count (override any clearing by FluxButton)
            local count = Module.GetItemCount(itemID)
            if btn.WCount then
                if count > 0 then
                    btn.WCount:SetText(tostring(count))
                    btn.WCount:SetTextColor(1, 1, 1, 1)
                else
                    btn.WCount:SetText("0")
                    btn.WCount:SetTextColor(1, 0.3, 0.3, 1)
                end
                btn.WCount:Show()
                -- CRITICAL: Clear PlaceholderHideCount to prevent FluxButton from hiding count
                btn.PlaceholderHideCount = nil
            end
            
            -- Store item ID on button so we can restore icon/count if FluxButton clears them
            btn.ConsumablesItemID = itemID
            btn.ConsumablesIsWeaponEnchant = true
            Module.RefreshConsumablesUsability(btn)
            
            -- CRITICAL: Hook UpdateTextCount to prevent FluxButton from clearing count for weapon enchants
            if btn.UpdateTextCount and not btn.ConsumablesWeaponEnchantUpdateHooked then
                btn.ConsumablesWeaponEnchantUpdateHooked = true
                -- Store original function
                btn._originalUpdateTextCount = btn.UpdateTextCount
                -- Guard flag to prevent recursion
                btn._inUpdateTextCount = false
                btn.UpdateTextCount = function(self)
                    -- Prevent infinite recursion
                    if self._inUpdateTextCount then
                        return
                    end
                    self._inUpdateTextCount = true
                    
                    -- Call original first
                    if self._originalUpdateTextCount then
                        self._originalUpdateTextCount(self)
                    end
                    
                    -- Then immediately restore count for weapon enchant items
                    if self.ConsumablesIsWeaponEnchant and self.ConsumablesItemID and self.WCount then
                        local count = Module.GetItemCount(self.ConsumablesItemID)
                        if count > 0 then
                            self.WCount:SetText(tostring(count))
                            self.WCount:SetTextColor(1, 1, 1, 1)
                        else
                            self.WCount:SetText("0")
                            self.WCount:SetTextColor(1, 0.3, 0.3, 1)
                        end
                        self.WCount:Show()
                        self.PlaceholderHideCount = nil
                    end
                    
                    -- Clear guard flag
                    self._inUpdateTextCount = false
                end
            end
            
            -- EVENT-BASED: Mark button for event-based updates instead of OnUpdate
            -- Updates will be triggered by BAG_UPDATE events
            if btn.Widget and not btn.ConsumablesWeaponEnchantWidgetUpdateHooked then
                btn.ConsumablesWeaponEnchantWidgetUpdateHooked = true
                -- Store original OnUpdate if it exists (for restoration later)
                if not btn._originalWidgetOnUpdate then
                    btn._originalWidgetOnUpdate = btn.Widget:GetScript("OnUpdate")
                end
            end
        end
    else
        -- Regular item action (preserve right-click handler)
        -- Clear weapon enchant flags since this is a regular item
        if btn.ConsumablesIsWeaponEnchant then
            btn.ConsumablesIsWeaponEnchant = nil
            btn.ConsumablesWeaponEnchantUpdateHooked = nil
            btn.ConsumablesWeaponEnchantWidgetUpdateHooked = nil
            -- Restore original UpdateTextCount if it was hooked
            if btn.UpdateTextCount and btn._originalUpdateTextCount then
                btn.UpdateTextCount = btn._originalUpdateTextCount
                btn._originalUpdateTextCount = nil
                btn._inUpdateTextCount = nil
            end
            -- Restore original OnUpdate if it was hooked
            if btn.Widget and btn._originalWidgetOnUpdate then
                btn.Widget:SetScript("OnUpdate", btn._originalWidgetOnUpdate)
                btn._originalWidgetOnUpdate = nil
                btn._inWidgetOnUpdate = nil
            end
        end
        btn.ConsumablesItemID = itemID  -- Still store itemID for reference
        
        -- Prefer lowest stack size so partially-used stacks are consumed first
        BindRegularConsumableUse(btn, itemID, "stack")
    end
    
    -- Update icon (ensure it's set for both regular items and weapon enchants)
    -- Only do this for regular items - weapon enchants with targetSlot already handled above
    local isWeaponEnchant = Module.IsWeaponEnchantItem(itemID)
    if not isWeaponEnchant or not btn.ConsumablesIsWeaponEnchant then
        local name, link, icon = GetCachedItemInfo(itemID)
        if not icon then
            -- Fallback: try GetItemInfo directly
            name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
        end
        
        if icon and btn.WIcon then
            btn.WIcon:SetTexture(icon)
            btn.WIcon:Show()
        elseif btn.WIcon then
            -- If no icon available, show question mark but keep it visible
            btn.WIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            btn.WIcon:Show()
        end
        
        -- Update count (ensure it's shown for regular items)
        local count = Module.GetItemCount(itemID)
        if btn.WCount then
            if count > 0 then
                btn.WCount:SetText(tostring(count))
                btn.WCount:SetTextColor(1, 1, 1, 1)
                btn.WCount:Show()
            else
                btn.WCount:SetText("0")
                btn.WCount:SetTextColor(1, 0.3, 0.3, 1)
                btn.WCount:Show()  -- Still show "0" so user knows they have none
            end
        end
    end
    
    -- Clear PlaceholderHideCount flag so count can be shown
    btn.PlaceholderHideCount = nil
    
    -- Force update of count text via button's UpdateTextCount if available
    if btn.UpdateTextCount then
        btn:UpdateTextCount()
    end
    ApplyConsumableAuraTimer(btn, buff)
    Module.RefreshConsumablesUsability(btn)
    
    -- Store current item for reference
    btn.ConsumablesCurrentItem = itemID
    
    -- Right-click opens config (Food.lua: type2 + macrotext2 on SecureActionButton)
    if btn.Widget and not InCombatLockdown() then
        Module.SetupRightClickConfig(btn)
    end
    Module.ApplyChronoboonModifierLayer(btn, itemID)
end

ClearConsumableAuraTimer = function(btn)
    if not btn then
        return
    end
    btn.FluxConsumableAuraCooldown = nil
    btn.StanceBuffCooldownStart = nil
    btn.StanceBuffCooldownDuration = nil
    btn.StanceBuffDurationObject = nil
    btn.StanceBuffExpirationTime = nil
    btn.StanceBuffTimeMod = nil
    local Stance = _G.Flux and _G.Flux.Bars and _G.Flux.Bars.Stance
    if Stance and Stance.SyncAuraCountdown then
        Stance.SyncAuraCountdown(btn)
    end
end

ApplyConsumableAuraTimer = function(btn, buff)
    if not btn then
        return
    end
    if not buff then
        ClearConsumableAuraTimer(btn)
        return
    end
    local remaining = BuffRemainingSeconds(buff)
    if remaining <= 0 then
        ClearConsumableAuraTimer(btn)
        return
    end
    local exp = PublicAuraNumber(buff.expirationTime) or buff.expirationTime
    local maxDuration = buff.maxDuration or buff.duration or 0
    if (not maxDuration or maxDuration <= 0) and type(exp) == "number" and exp > 0 then
        maxDuration = remaining
    end
    local startTime
    if type(exp) == "number" and exp > 0 and maxDuration and maxDuration > 0 then
        startTime = exp - maxDuration
    end
    btn.FluxConsumableAuraCooldown = true
    btn.StanceBuffCooldownStart = startTime
    btn.StanceBuffCooldownDuration = maxDuration
    btn.StanceBuffDurationObject = buff.durationObject
    btn.StanceBuffExpirationTime = exp
    btn.StanceBuffTimeMod = buff.timeMod
    local Stance = _G.Flux and _G.Flux.Bars and _G.Flux.Bars.Stance
    if Stance and Stance.SyncAuraCountdown then
        Stance.SyncAuraCountdown(btn)
    end
    local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
    if Paint and Paint.UpdateCooldown then
        Paint.UpdateCooldown(btn)
    end
end

function Module.RefreshAuraTimerOverlay()
    local btn = Module._button
    if not btn then
        return
    end
    if Module._isWispLocked then
        ApplyConsumableAuraTimer(btn, Module._wispLockBuff)
        return
    end
    local itemID = btn.ConsumablesItemID or btn.ConsumablesCurrentItem
    local buff = itemID and Module.FindBuffForItem(itemID) or nil
    ApplyConsumableAuraTimer(btn, buff)
end

function Module.UpdateBuffCooldown(btn, buff)
    ApplyConsumableAuraTimer(btn, buff)
end

-- ============================================================================
-- BUTTON STATE UPDATE
-- ============================================================================

-- Apply any pending changes queued during combat
function Module.ApplyPendingChanges()
    if InCombatLockdown() then return end
    
    local btn = Module._button
    if not btn then return end
    
    -- Apply pending item change
    if Module._pendingItemChange then
        local itemID = Module._pendingItemChange.itemID
        local buff = Module._pendingItemChange.buff
        SetItemMode(btn, itemID, buff)
        Module._pendingItemChange = nil
    end
    
    -- Apply pending WISP LOCK change
    if Module._pendingWispLockChange then
        local minRemaining = Module._pendingWispLockChange.minRemaining
        local minRemainingBuff = Module._pendingWispLockChange.minRemainingBuff
        SetWispLock(btn, minRemaining, minRemainingBuff)
        Module._pendingWispLockChange = nil
    end
end

function Module.UpdateButtonState(force)
    local btn = Module._button
    if not btn then return end

    if FluxExtraButtonVisibility and FluxExtraButtonVisibility.ApplyConsumables
        and not FluxExtraButtonVisibility.ApplyConsumables() then
        -- SlotFrame/Widget/Relayout use protected Frame APIs — cannot call during combat lockdown
        if not InCombatLockdown() then
            if btn.SlotFrame then btn.SlotFrame:Hide() end
            if btn.Widget then btn.Widget:Hide() end
            if Module._grid and Module._grid.Relayout then Module._grid:Relayout() end
            Module.ClearKeybindings()
        else
            Module._pendingUpdate = true
        end
        if Module._SyncBuffCheckTicker then
            Module._SyncBuffCheckTicker()
        end
        return
    end
    if Module._SyncBuffCheckTicker then
        Module._SyncBuffCheckTicker()
    end
    if not InCombatLockdown() then
        if btn.SlotFrame then btn.SlotFrame:Show() end
        if btn.Widget then btn.Widget:Show() end
    else
        Module._pendingUpdate = true
    end
    Module.UpdateKeybindings()

    -- Track combat state
    Module._inCombat = InCombatLockdown()
    
    -- Debounce rapid updates (unless forced)
    if not force then
        local now = GetTime()
        if (now - Module._lastUpdateTime) < Module._updateDebounceTime then
            return
        end
        Module._lastUpdateTime = now
    end
    
    -- CRITICAL: Restore icon and count for weapon enchant items if they're missing
    -- This prevents flickering when FluxButton clears them during updates
    -- Skip when count is 0 - we're about to switch to placeholder
    if btn.ConsumablesIsWeaponEnchant and btn.ConsumablesItemID then
        local itemID = btn.ConsumablesItemID
        local count = Module.GetItemCount(itemID)
        if count <= 0 then
            -- Load-screen bag flicker: keep the last consumable; do not SetPlaceholder.
            if not ShouldHoldItemIdentity() then
                btn.ConsumablesIsWeaponEnchant = nil
                btn.ConsumablesItemID = nil
                btn.ConsumablesWeaponEnchantUpdateHooked = nil
            end
        else
            -- Check if icon is missing or hidden
            if btn.WIcon and (not btn.WIcon:IsShown() or not btn.WIcon:GetTexture() or btn.WIcon:GetTexture() == "") then
                local name, link, icon = GetCachedItemInfo(itemID)
                if not icon then
                    name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
                end
                if icon then
                    btn.WIcon:SetTexture(icon)
                    btn.WIcon:Show()
                end
            end
            -- Check if count is missing or hidden
            if btn.WCount and (not btn.WCount:IsShown() or btn.WCount:GetText() == "" or btn.PlaceholderHideCount) then
                local count = Module.GetItemCount(itemID)
                if count > 0 then
                    btn.WCount:SetText(tostring(count))
                    btn.WCount:SetTextColor(1, 1, 1, 1)
                else
                    btn.WCount:SetText("0")
                    btn.WCount:SetTextColor(1, 0.3, 0.3, 1)
                end
                btn.WCount:Show()
                btn.PlaceholderHideCount = nil
            end
            Module.RefreshConsumablesUsability(btn)
        end
    end
    
    local items = Module.GetItems()
    
    -- Empty preset or no items
    if #items == 0 then
        -- Clear weapon enchant state so placeholder shows correctly
        if btn.ConsumablesIsWeaponEnchant then
            btn.ConsumablesIsWeaponEnchant = nil
            btn.ConsumablesItemID = nil
            btn.ConsumablesWeaponEnchantUpdateHooked = nil
        end
        -- Clear action so any previous item/macro is fully removed
        if btn.ClearAction then
            btn:ClearAction()
        end
        -- Clear WISP LOCK state
        if Module._isWispLocked then
            Module._isWispLocked = false
            Module._wispLockMinRemaining = 0
            Module._wispLockBuff = nil
            Module._wispLockStableTime = 0
            btn.IsWispLocked = false
            btn.IsWispLockPlaceholder = nil
            -- Clear WISP LOCK placeholder if it's set
            if btn.PlaceholderTexture == WISP_LOCK_ICON then
                if btn.ClearPlaceholder then
                    btn:ClearPlaceholder()
                else
                    btn.PlaceholderTexture = nil
                    btn.PlaceholderLabel = nil
                end
            end
        end
        SetPlaceholder(btn)
        -- Full refresh to ensure count, icon, and all visuals are reset
        if btn.FullRefresh then
            btn:FullRefresh()
        end
        Module.RefreshTooltip()
        return
    end
    
    -- CRITICAL: If we're in WISP LOCK, check if we should stay in it FIRST
    -- This prevents any flickering by prioritizing WISP LOCK state
    if Module._isWispLocked then
        local isWispLocked, minRemaining, minRemainingBuff, isStable = Module.CheckWispLockState()
        
        if isWispLocked then
            -- Still in WISP LOCK - ensure placeholder is still set (in case it was cleared)
            if not btn.PlaceholderTexture or btn.PlaceholderTexture ~= WISP_LOCK_ICON then
                SetWispLock(btn, minRemaining, minRemainingBuff)
            else
                -- Just update cooldown overlay without changing icon/action
                -- Update if min remaining changed by >1 second OR if forced update
                if force or math.abs((Module._wispLockMinRemaining or 0) - minRemaining) > 1 then
                    Module._wispLockMinRemaining = minRemaining
                    Module._wispLockBuff = minRemainingBuff
                    Module.UpdateWispLockCooldown(btn, minRemaining, minRemainingBuff)
                end
            end
            Module.RefreshTooltip()
            return -- CRITICAL: Return immediately, don't check anything else
        elseif not isStable then
            -- Not stable yet - stay in WISP LOCK (don't update anything, don't change icon)
            -- But still update cooldown if forced
            if force then
                Module.UpdateWispLockCooldown(btn, Module._wispLockMinRemaining, Module._wispLockBuff)
            end
            Module.RefreshTooltip()
            return -- CRITICAL: Return immediately, stay in WISP LOCK
        else
            -- Stable exit from WISP LOCK
            -- Combat safety: if in combat, keep WISP LOCK icon visible until combat ends
            if InCombatLockdown() then
                -- Queue the exit from WISP LOCK - will be applied after combat
                -- Keep showing WISP LOCK icon during combat
                Module._pendingWispLockChange = nil  -- Clear any pending WISP LOCK entry
                -- Queue item change for after combat
                local itemID, buff = Module.GetFirstEligibleItem()
                if itemID then
                    Module._pendingItemChange = {
                        itemID = itemID,
                        buff = buff
                    }
                end
                -- Update cooldown overlay (can be removed/updated during combat, but keep icon)
                -- If buff expired, cooldown will be hidden, but icon stays
                if Module._wispLockBuff and Module._wispLockBuff.expirationTime then
                    local currentRemaining = BuffRemainingSeconds(Module._wispLockBuff)
                    if currentRemaining > 0 then
                        Module._wispLockMinRemaining = currentRemaining
                        Module.UpdateWispLockCooldown(btn, currentRemaining, Module._wispLockBuff)
                    else
                        -- Buff expired - hide cooldown but keep icon
                        Module._wispLockMinRemaining = 0
                        local cooldown = btn.WCooldown or (btn.Widget and btn.Widget.cooldown)
                        if cooldown then
                            cooldown:Hide()
                        end
                    end
                else
                    -- No buff - hide cooldown
                    Module._wispLockMinRemaining = 0
                    local cooldown = btn.WCooldown or (btn.Widget and btn.Widget.cooldown)
                    if cooldown then
                        cooldown:Hide()
                    end
                end
                -- Keep WISP LOCK state and icon visible during combat
                Module.RefreshTooltip()
                return -- Stay in WISP LOCK until combat ends
            end
            
            -- Not in combat - safe to exit WISP LOCK
            Module._isWispLocked = false
            Module._wispLockMinRemaining = 0
            Module._wispLockBuff = nil
            Module._wispLockStableTime = 0
            btn.IsWispLocked = false
            btn.IsWispLockPlaceholder = nil
            -- Clear placeholder if it's the WISP LOCK one
            if btn.PlaceholderTexture == WISP_LOCK_ICON then
                if btn.ClearPlaceholder then
                    btn:ClearPlaceholder()
                else
                    btn.PlaceholderTexture = nil
                    btn.PlaceholderLabel = nil
                end
            end
            -- Clear PlaceholderHideCount so count can be shown
            btn.PlaceholderHideCount = nil
            -- Force button refresh to show item
            if btn.FullRefresh then
                btn:FullRefresh()
            end
            -- Force update of count text
            if btn.UpdateTextCount then
                btn:UpdateTextCount()
            end
        end
    end
    
    -- Check WISP LOCK state (only if we're not already in it)
    -- CRITICAL: Check this BEFORE SetItemMode to prevent flickering when transitioning
    local isWispLocked, minRemaining, minRemainingBuff, isStable = Module.CheckWispLockState()
    if isWispLocked then
        -- Entering WISP LOCK - clear weapon enchant flags to prevent SetItemMode from being called
        if btn.ConsumablesIsWeaponEnchant then
            btn.ConsumablesIsWeaponEnchant = nil
            btn.ConsumablesWeaponEnchantUpdateHooked = nil
        end
        -- Entering WISP LOCK
        SetWispLock(btn, minRemaining, minRemainingBuff)
        Module.RefreshTooltip()
        return
    end
    
    -- Find first eligible item
    local itemID, buff = Module.GetFirstEligibleItem()
    
    if itemID then
        -- CRITICAL: Double-check WISP LOCK state right before SetItemMode to prevent race conditions
        -- This ensures we don't show the item if we should be in WISP LOCK
        local doubleCheckWispLocked, _, _, _ = Module.CheckWispLockState()
        if doubleCheckWispLocked then
            -- State changed - enter WISP LOCK instead
            if btn.ConsumablesIsWeaponEnchant then
                btn.ConsumablesIsWeaponEnchant = nil
                btn.ConsumablesWeaponEnchantUpdateHooked = nil
            end
            SetWispLock(btn, minRemaining, minRemainingBuff)
            Module.RefreshTooltip()
            return
        end
        SetItemMode(btn, itemID, buff)
    else
        -- No eligible items and not WISP locked means no items in bags
        -- Check if any item exists in bags
        local anyInBags = false
        for _, id in ipairs(items) do
            if Module.GetItemCount(id) > 0 then
                anyInBags = true
                break
            end
        end
        
        if anyInBags then
            -- Items exist but all have long buffs - show first item with its buff
            for _, id in ipairs(items) do
                if Module.GetItemCount(id) > 0 then
                    local b = Module.FindBuffForItem(id)
                    SetItemMode(btn, id, b)
                    break
                end
            end
        else
            local BestMod = _G.FluxConsumableBest
            local holding = ShouldHoldItemIdentity()
                or (BestMod and BestMod.ShouldSoftHoldOwned and BestMod.ShouldSoftHoldOwned())
            local Flux = _G.Flux
            local collapsed = Flux and Flux.Inventory and Flux.Inventory.SnapshotLooksCollapsed
                and Flux.Inventory.SnapshotLooksCollapsed()
            local keepID = btn.ConsumablesItemID or btn.ConsumablesCurrentItem
            if (holding or collapsed) and keepID then
                Module.RefreshTooltip()
                return
            end
            -- No items in bags - fully reset to placeholder
            if btn.ClearAction then
                btn:ClearAction()
            end
            SetPlaceholder(btn)
            if btn.FullRefresh then
                btn:FullRefresh()
            end
        end
    end
    
    -- Refresh tooltip if it's currently showing
    Module.RefreshTooltip()
end

-- ============================================================================
-- BUTTON CREATION AND REGISTRATION
-- ============================================================================

function Module.Register(grid)
    if not grid or Module._registered then return end
    if InCombatLockdown() then return false end
    
    Module._grid = grid
    
    -- Load saved variables
    LoadSavedVars()
    
    -- Create the button
    Module.CreateButton()
    if not Module._button then return false end
    
    -- Register events
    if not Module._eventsRegistered then
        Module.RegisterEvents()
        Module._eventsRegistered = true
    end
    
    -- CreateButton returns only after its widget exists. Bind immediately while
    -- legal; inventory settling must not hold back secure click configuration.
    Module.UpdateKeybindings()
    
    Module.RunPostLoginConsumablesRefresh()
    Module._registered = true
    return true
end

function Module.CreateButton()
    if not Module._grid or Module._button then return end
    if InCombatLockdown() then
        Timer.After(0.5, Module.CreateButton)
        return
    end
    
    local grid = Module._grid
    
    -- Create button using grid's method
    local btn = grid:CreateButton({
        columnPriority = Module.COLUMN_PRIORITY,
        columnGroup = "consumables",
        order = Module.ORDER,
        scope = "class",
    })
    
    if not btn then return end
    
    Module._button = btn
    
    -- Mark as consumables button (for grid pairing logic)
    btn.IsConsumableButton = true

    -- Same usability pipeline as Food/Water (item IsUsableItem tint).
    btn.UpdateUsable = function(self)
        Module.RefreshConsumablesUsability(self)
    end
    
    -- DISABLE DRAG/DROP - Pre-set button (match Food/Water)
    btn.ButtonLocked = true
    if btn.SetLocked then btn:SetLocked(true) end
    if btn.Widget then
        btn.Widget:SetScript("OnDragStart", nil)
        btn.Widget:SetScript("OnReceiveDrag", nil)
        btn.Widget:SetScript("OnDragStop", nil)
        if btn.Widget.RegisterForDrag then
            btn.Widget:RegisterForDrag()
            btn.Widget:SetScript("OnDragStart", nil)
            btn.Widget:SetScript("OnReceiveDrag", nil)
            btn.Widget:SetScript("OnDragStop", nil)
        end
    end
    
    -- Hook SetAction to prevent updates when in WISP LOCK
    if btn.SetAction then
        local originalSetAction = btn.SetAction
        btn.SetAction = function(self, actionType, actionValue)
            -- If in WISP LOCK placeholder, prevent any action updates
            if Module._isWispLocked or self.IsWispLocked or self.PlaceholderTexture == WISP_LOCK_ICON or self.IsWispLockPlaceholder then
                return
            end
            return originalSetAction(self, actionType, actionValue)
        end
    end
    
    -- ClearAction leaves type1/type2 on the widget; wipe consumables split-click attrs
    if btn.ClearAction then
        local originalClearAction = btn.ClearAction
        btn.ClearAction = function(self)
            originalClearAction(self)
            if self.Widget then
                ClearConsumablesSecureClickAttrs(self.Widget)
            end
        end
    end
    
    -- Hook UpdateTexture to preserve WISP LOCK styling and weapon enchant icon/count
    if btn.UpdateTexture then
        local originalUpdateTexture = btn.UpdateTexture
        btn.UpdateTexture = function(self)
            originalUpdateTexture(self)
            -- If this is WISP LOCK placeholder, restore custom styling
            if self.PlaceholderTexture == WISP_LOCK_ICON or self.IsWispLockPlaceholder then
                if self.WIcon then
                    self.WIcon:SetDesaturated(false)
                    self.WIcon:SetVertexColor(1, 1, 1, 1)
                end
                -- Blank the count. Leave the region shown so the next digit can land.
                if self.WCount then
                    self.WCount:Show()
                    self.WCount:SetText("")
                end
                -- Ensure PlaceholderHideCount is set
                self.PlaceholderHideCount = true
            end
            -- If this is a weapon enchant item, restore icon and count (FluxButton may clear them for macro actions)
            if self.ConsumablesIsWeaponEnchant and self.ConsumablesItemID then
                local itemID = self.ConsumablesItemID
                local name, link, icon = GetCachedItemInfo(itemID)
                if not icon then
                    name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
                end
                if self.WIcon then
                    if icon then
                        self.WIcon:SetTexture(icon)
                    else
                        self.WIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    end
                    self.WIcon:Show()
                end
                local count = Module.GetItemCount(itemID)
                if self.WCount then
                    if count > 0 then
                        self.WCount:SetText(tostring(count))
                        self.WCount:SetTextColor(1, 1, 1, 1)
                    else
                        self.WCount:SetText("0")
                        self.WCount:SetTextColor(1, 0.3, 0.3, 1)
                    end
                    self.WCount:Show()
                end
                self.PlaceholderHideCount = nil
                Module.RefreshConsumablesUsability(self)
            end
            Module.ApplyConsumablesChronoboonModifierVisual(self)
        end
    end
    
    -- Hook FullRefresh to preserve WISP LOCK styling and weapon enchant icon/count
    if btn.FullRefresh then
        local originalFullRefresh = btn.FullRefresh
        btn.FullRefresh = function(self)
            originalFullRefresh(self)
            -- If this is WISP LOCK placeholder, restore custom styling
            if self.PlaceholderTexture == WISP_LOCK_ICON or self.IsWispLockPlaceholder then
                if self.WIcon then
                    self.WIcon:SetDesaturated(false)
                    self.WIcon:SetVertexColor(1, 1, 1, 1)
                end
                -- Blank the count. Leave the region shown so the next digit can land.
                if self.WCount then
                    self.WCount:Show()
                    self.WCount:SetText("")
                end
                -- Ensure PlaceholderHideCount is set
                self.PlaceholderHideCount = true
                -- Restore cooldown if we have one
                if Module._isWispLocked and Module._wispLockMinRemaining and Module._wispLockMinRemaining > 0 then
                    Module.UpdateWispLockCooldown(self, Module._wispLockMinRemaining, Module._wispLockBuff)
                end
            end
            -- If this is a weapon enchant item, restore icon and count (FluxButton may clear them for macro actions)
            if self.ConsumablesIsWeaponEnchant and self.ConsumablesItemID then
                local itemID = self.ConsumablesItemID
                local name, link, icon = GetCachedItemInfo(itemID)
                if not icon then
                    name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
                end
                if self.WIcon then
                    if icon then
                        self.WIcon:SetTexture(icon)
                    else
                        self.WIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    end
                    self.WIcon:Show()
                end
                local count = Module.GetItemCount(itemID)
                if self.WCount then
                    if count > 0 then
                        self.WCount:SetText(tostring(count))
                        self.WCount:SetTextColor(1, 1, 1, 1)
                    else
                        self.WCount:SetText("0")
                        self.WCount:SetTextColor(1, 0.3, 0.3, 1)
                    end
                    self.WCount:Show()
                end
                self.PlaceholderHideCount = nil
                Module.RefreshConsumablesUsability(self)
            end
            Module.ApplyConsumablesChronoboonModifierVisual(self)
        end
    end
    
    -- Hook UpdateAppearance to preserve WISP LOCK styling and weapon enchant icon/count
    if btn.UpdateAppearance then
        local originalUpdateAppearance = btn.UpdateAppearance
        btn.UpdateAppearance = function(self)
            originalUpdateAppearance(self)
            -- If this is WISP LOCK placeholder, restore custom styling
            if self.PlaceholderTexture == WISP_LOCK_ICON or self.IsWispLockPlaceholder then
                if self.WIcon then
                    self.WIcon:SetDesaturated(false)
                    self.WIcon:SetVertexColor(1, 1, 1, 1)
                end
                -- Blank the count. Leave the region shown so the next digit can land.
                if self.WCount then
                    self.WCount:Show()
                    self.WCount:SetText("")
                end
                -- Ensure PlaceholderHideCount is set
                self.PlaceholderHideCount = true
            end
            -- If this is a weapon enchant item, restore icon and count (FluxButton may clear them for macro actions)
            if self.ConsumablesIsWeaponEnchant and self.ConsumablesItemID then
                local itemID = self.ConsumablesItemID
                local name, link, icon = GetCachedItemInfo(itemID)
                if not icon then
                    name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
                end
                if self.WIcon then
                    if icon then
                        self.WIcon:SetTexture(icon)
                    else
                        self.WIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    end
                    self.WIcon:Show()
                end
                local count = Module.GetItemCount(itemID)
                if self.WCount then
                    if count > 0 then
                        self.WCount:SetText(tostring(count))
                        self.WCount:SetTextColor(1, 1, 1, 1)
                    else
                        self.WCount:SetText("0")
                        self.WCount:SetTextColor(1, 0.3, 0.3, 1)
                    end
                    self.WCount:Show()
                end
                self.PlaceholderHideCount = nil
                Module.RefreshConsumablesUsability(self)
            end
            Module.ApplyConsumablesChronoboonModifierVisual(self)
        end
    end
    
    -- Hook UpdateTextCount to preserve WISP LOCK count hiding
    if btn.UpdateTextCount then
        local originalUpdateTextCount = btn.UpdateTextCount
        btn.UpdateTextCount = function(self)
            originalUpdateTextCount(self)
            -- Blank the count while the wisp-lock placeholder is up.
            if self.PlaceholderTexture == WISP_LOCK_ICON or self.IsWispLockPlaceholder then
                if self.WCount then
                    self.WCount:Show()
                    self.WCount:SetText("")
                end
            end
        end
    end
    
    -- Hook UpdateCooldown to prevent cooldown from being hidden for WISP LOCK
    -- Note: This might not exist, but we'll check for it
    if btn.UpdateCooldown then
        local originalUpdateCooldown = btn.UpdateCooldown
        btn.UpdateCooldown = function(self)
            originalUpdateCooldown(self)
            -- If this is WISP LOCK placeholder, restore cooldown if we have one
            if (self.PlaceholderTexture == WISP_LOCK_ICON or self.IsWispLockPlaceholder) and Module._isWispLocked then
                if Module._wispLockMinRemaining and Module._wispLockMinRemaining > 0 then
                    Module.UpdateWispLockCooldown(self, Module._wispLockMinRemaining, Module._wispLockBuff)
                end
            end
        end
    end
    
    -- Set up click handling
    Module.SetupClickHandling(btn)
    
    -- Set up tooltip
    Module.SetupTooltip(btn)
    
    -- Initial placeholder state
    SetPlaceholder(btn)
    
    -- Apply button styling
    if FluxNonCombatGrid and FluxNonCombatGrid.ApplyButtonStyle then
        FluxNonCombatGrid.ApplyButtonStyle(btn, "class")
    elseif FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
        FluxButtonUtil:ApplyButtonStyle(btn, "class")
    end
    
    -- Set column priority and order
    grid:SetButtonOrder(btn, Module.ORDER)
    
    -- Ensure cooldown frame exists and has noCooldownCount set
    local cooldown = btn.WCooldown or (btn.Widget and btn.Widget.cooldown)
    if cooldown then
        cooldown.noCooldownCount = true
    end
    
    return btn
end

function Module.SetupClickHandling(btn)
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Timer.After(0.2, function() Module.SetupClickHandling(btn) end)
        return
    end

    local widget = btn.Widget

    -- Click.Apply({ onDown = true }) already registered AnyUp+AnyDown. AnyUp
    -- alone would drop press-to-use on the NC consumable extra.

    -- Cooldown swipe can sit above siblings and steal clicks; let the secure button receive them (Food.lua pattern)
    if btn.WCooldown and btn.WCooldown.EnableMouse then
        pcall(function() btn.WCooldown:EnableMouse(false) end)
    end
    if widget.cooldown and widget.cooldown.EnableMouse then
        pcall(function() widget.cooldown:EnableMouse(false) end)
    end

    Module.SetupRightClickConfig(btn)
    EnsureConsumablesModifierDriver(btn)

    -- Left-click only: item use is handled by secure attrs; we refresh state after
    widget:HookScript("OnClick", function(self, mouseButton, down)
        if mouseButton == "LeftButton" then
            if Module._isWispLocked then
                return
            end
            Timer.After(0.10, function()
                Module.UpdateButtonState()
            end)
        end
    end)
end

-- ============================================================================
-- TOOLTIP
-- ============================================================================

-- Tooltip state tracking (matching TeleportPortal pattern)
local tooltipShowing = false
local TOOLTIP_REFRESH_INTERVAL = 0.25
local tooltipItemsCache = nil
local tooltipItemsCacheTime = 0

local function GetTooltipItems()
    local now = GetTime()
    if tooltipShowing and tooltipItemsCache and (now - tooltipItemsCacheTime) < 0.5 then
        return tooltipItemsCache
    end
    local items = Module.GetItems()
    if tooltipShowing then
        tooltipItemsCache = items
        tooltipItemsCacheTime = now
    end
    return items
end

local function BuildTooltipAuraCache()
    if AurasRestricted() then
        local prev = Module._tooltipAuraCache
        Module._tooltipAuraCache = {
            bySpellID = (prev and prev.bySpellID) or {},
            byName = {},
            hasSuperChrono = prev and prev.hasSuperChrono,
            worldBuffCount = prev and prev.worldBuffCount or 0,
            restricted = true,
        }
        return
    end
    local bySpellID = {}
    local byName = {}
    local hasSuperChrono = false
    local worldBuffCount = 0
    local index = 1
    local isV12 = FLUX_API and FLUX_API.isV12
    local isSecretValue = issecretvalue or function() return false end

    while true do
        local name, icon, count, duration, expirationTime, spellID
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = PlayerHelpfulAura(index)
            if not aura then break end
            name = aura.name
            icon = aura.icon
            count = aura.applications or 0
            duration = aura.duration or 0
            expirationTime = aura.expirationTime or 0
            spellID = aura.spellId
        elseif UnitAura then
            name, icon, count, _, duration, expirationTime, _, _, _, spellID = UnitAura("player", index, "HELPFUL")
            if not name then break end
        else
            break
        end

        if name then
            local lowerName = nil
            if isV12 and isSecretValue(name) then
                local success, result = pcall(function()
                    return string.lower(name)
                end)
                if success then lowerName = result end
            else
                lowerName = string.lower(name)
            end

            local nameMatches = false
            if lowerName then
                if string.find(lowerName, "supercharged chronoboon displacer") then
                    nameMatches = true
                else
                    for _, buffName in ipairs(WORLD_BUFF_NAMES) do
                        if lowerName == string.lower(buffName) then
                            worldBuffCount = worldBuffCount + 1
                            break
                        end
                    end
                end
            end
            if nameMatches then
                hasSuperChrono = true
            end
            local entry = {
                name = name,
                icon = icon,
                count = count or 0,
                duration = duration or 0,
                maxDuration = duration or 0,
                expirationTime = expirationTime or 0,
                spellID = spellID,
            }
            -- Midnight: never index tables with secret spellIDs / secret names.
            local safeSpellID = spellID
            if isV12 and spellID ~= nil then
                if isSecretValue(spellID) then
                    safeSpellID = nil
                elseif canaccessvalue and not canaccessvalue(spellID) then
                    safeSpellID = nil
                else
                    safeSpellID = tonumber(spellID)
                end
            end
            if safeSpellID then
                bySpellID[safeSpellID] = entry
            end
            if name and not (isV12 and isSecretValue(name)) then
                local okLower, lowered = pcall(string.lower, name)
                if okLower and type(lowered) == "string" then
                    byName[lowered] = entry
                end
            end
        end
        index = index + 1
    end

    Module._tooltipAuraCache = {
        bySpellID = bySpellID,
        byName = byName,
        hasSuperChrono = hasSuperChrono,
        worldBuffCount = worldBuffCount,
    }
end

local function ClearTooltipAuraCache()
    Module._tooltipAuraCache = nil
end

local function GetTooltipRefreshInterval()
    local inv = _G.FluxInventory
    if inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() then
        return 0.5
    end
    if MerchantFrame and MerchantFrame:IsShown() then
        return 0.5
    end
    return TOOLTIP_REFRESH_INTERVAL
end

function Module.SetupTooltip(btn)
    if not btn or not btn.Widget then return end
    
    -- DISABLE DEFAULT TOOLTIP - We use our own custom tooltip
    btn.TooltipEnabled = false
    
    local widget = btn.Widget
    local Hover = _G.FluxTooltipHover

    local function hideGridTooltip()
        ClearTooltipAuraCache()
        tooltipItemsCache = nil
        if GameTooltip then
            GameTooltip:Hide()
        end
    end
    if Hover and Hover.RegisterGridWidget then
        Hover.RegisterGridWidget(widget, hideGridTooltip)
    end
    
    -- OnEnter: Show tooltip and start tracking
    -- Use SetScript (not HookScript) to completely replace default tooltip
    widget:SetScript("OnEnter", function(self)
        tooltipShowing = true
        
        local hoverOpts = {
            interval = GetTooltipRefreshInterval(),
            isActive = function() return tooltipShowing end,
            onRefresh = function()
                if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
                    Module.ShowTooltip()
                end
            end,
        }
        if Hover and Hover.BeginGridHover then
            Hover.BeginGridHover(self, function()
                Module.ShowTooltip()
            end, hoverOpts)
        else
            Module.ShowTooltip()
            if Hover and Hover.Start then
                Hover.Start(self, hoverOpts)
            end
        end
    end)
    
    -- OnLeave: Hide tooltip and stop tracking
    widget:SetScript("OnLeave", function(self)
        tooltipShowing = false
        self:SetScript("OnUpdate", nil)
        if Hover and Hover.EndGridHover then
            Hover.EndGridHover(self, hideGridTooltip)
        else
            if Hover and Hover.Stop then
                Hover.Stop(self)
            end
            hideGridTooltip()
        end
    end)
end

function Module.ShowTooltip()
    BuildTooltipAuraCache()
    local btn = Module._button
    if not btn or not btn.Widget then return end
    
    GameTooltip:SetOwner(btn.Widget, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    local items = GetTooltipItems()
    local worldBuffCount = Module.GetWorldBuffCount()
    
    -- Header
    GameTooltip:AddLine("Consumables", 1, 1, 1)
    GameTooltip:AddLine(" ")
    
    -- Check SuperCharged Chronoboon buff status
    local hasSuperchargedBuff = Module.HasSuperchargedChronoboonBuff()
    if hasSuperchargedBuff then
        GameTooltip:AddLine("Supercharged Chronoboon Displacer is active", 0.5, 1, 0.5)
        GameTooltip:AddLine(" ")
    end
    
    if #items == 0 then
        GameTooltip:AddLine("No consumables configured", 1, 0.5, 0.5)
        GameTooltip:AddLine("Right-click to add items", 0.7, 0.7, 0.7)
    else
        -- Show all consumables with their status
        for _, itemID in ipairs(items) do
            local itemName, itemLink, itemIcon = GetCachedItemInfo(itemID)
            if not itemName then
                itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
            end
            
            if itemName then
                -- Get item count in bags
                local count = Module.GetItemCount(itemID)
                
                -- Check if this is a Chronoboon item
                local isChronoboon = Module.IsChronoboonItem(itemID)
                local isSupercharged = false
                if isChronoboon then
                    isSupercharged = Module.IsSuperchargedChronoboonItem(itemID)
                end
                
                -- Get buff status (skip for Chronoboon items)
                local buff = nil
                local isActive = false
                local remaining = 0
                
                if not isChronoboon then
                    buff = Module.FindBuffForItem(itemID)
                    if buff then
                        remaining = BuffRemainingSeconds(buff)
                        if remaining > 0 then
                            isActive = true
                        end
                    end
                end
                
                -- Format the line: icon + name + status (with count)
                local statusText
                local statusColor = {1, 0.5, 0.5}  -- Red for inactive
                
                if count <= 0 then
                    -- No items in bags
                    statusText = "Missing"
                    statusColor = {1, 0.3, 0.3}  -- Dark red for missing
                elseif isChronoboon and isSupercharged then
                    -- SuperCharged Chronoboon - show count only
                    statusText = string.format("x%d", count)
                    statusColor = {1, 1, 1}  -- White
                elseif isChronoboon and not isSupercharged then
                    -- Regular Chronoboon - check item cooldown first
                    local startTime, duration, isEnabled = 0, 0, 0
                    local cooldownRemaining = 0
                    
                    -- Try modern API first
                    if C_Item and C_Item.GetItemCooldown then
                        local cooldownInfo = C_Item.GetItemCooldown(itemID)
                        if cooldownInfo and type(cooldownInfo) == "table" then
                            startTime = cooldownInfo.startTime or 0
                            duration = cooldownInfo.duration or 0
                            isEnabled = (cooldownInfo.isEnabled and 1) or 0
                        else
                            startTime, duration, isEnabled = C_Item.GetItemCooldown(itemID)
                            startTime = startTime or 0
                            duration = duration or 0
                            isEnabled = isEnabled and 1 or 0
                        end
                    elseif C_Container and C_Container.GetItemCooldown then
                        local cooldownInfo = C_Container.GetItemCooldown(itemID)
                        if cooldownInfo and type(cooldownInfo) == "table" then
                            startTime = cooldownInfo.startTime or 0
                            duration = cooldownInfo.duration or 0
                            isEnabled = 1
                        else
                            startTime, duration = C_Container.GetItemCooldown(itemID)
                            startTime = startTime or 0
                            duration = duration or 0
                            isEnabled = 1
                        end
                    elseif GetItemCooldown then
                        startTime, duration, isEnabled = GetItemCooldown(itemID)
                        startTime = startTime or 0
                        duration = duration or 0
                        isEnabled = isEnabled and 1 or 0
                    end
                    
                    if isEnabled == 1 and duration > 0 then
                        cooldownRemaining = (startTime + duration) - GetTime()
                    end
                    
                    -- Show world buff count or cooldown status
                    if cooldownRemaining > 0 then
                        -- Item is on cooldown
                        local mins = math.floor(cooldownRemaining / 60)
                        local secs = math.floor(cooldownRemaining % 60)
                        if mins > 0 then
                            statusText = string.format("On cooldown: %dm %ds (x%d)", mins, secs, count)
                        else
                            statusText = string.format("On cooldown: %ds (x%d)", secs, count)
                        end
                        statusColor = {1, 0.8, 0.3}  -- Orange/yellow for cooldown
                    else
                        -- Not on cooldown - show world buff count
                        if worldBuffCount > 0 then
                            statusText = string.format("%d world buff(s) active (x%d)", worldBuffCount, count)
                            statusColor = {0.5, 1, 0.5}  -- Green
                        else
                            statusText = string.format("No world buffs (x%d)", count)
                            statusColor = {1, 0.5, 0.5}  -- Red
                        end
                    end
                elseif isActive then
                    -- Active buff - show duration and count
                    local mins = math.floor(remaining / 60)
                    local secs = math.floor(remaining % 60)
                    statusText = string.format("Active: %d:%02d (x%d)", mins, secs, count)
                    statusColor = {0.5, 1, 0.5}  -- Green for active
                else
                    -- Not active but have items - show count
                    statusText = string.format("Not active (x%d)", count)
                    statusColor = {1, 0.5, 0.5}  -- Red for inactive
                end
                
                -- Add texture (icon) and text on same line
                -- Format: |Ttexture:width:height|t text
                local lineText
                if itemIcon then
                    -- Use texture string format: |Ttexture:width:height:offsetX:offsetY:texWidth:texHeight:left:right:top:bottom|t
                    lineText = "|T" .. itemIcon .. ":16:16:0:0:64:64:4:60:4:60|t " .. itemName
                else
                    lineText = itemName
                end
                
                -- Use AddDoubleLine to show item name (with icon) on left and status on right
                GameTooltip:AddDoubleLine(
                    lineText,
                    statusText,
                    1, 1, 1,  -- Item name color (white)
                    statusColor[1], statusColor[2], statusColor[3]  -- Status color
                )
            end
        end
    end
    
    -- Add separator and instructions
    GameTooltip:AddLine(" ")
    
    if Module._isWispLocked then
        -- Show time until next refresh (shortest buff remaining minus threshold)
        if Module._wispLockMinRemaining > 0 and isfinite(Module._wispLockMinRemaining) then
            local threshold = Module.GetRefreshThreshold()
            local nextRefresh = math.max(0, Module._wispLockMinRemaining - (threshold or 0))
            local mins = math.floor(nextRefresh / 60)
            local secs = math.floor(nextRefresh % 60)
            GameTooltip:AddLine(string.format("All active - Next refresh: %d:%02d", mins, secs), 0.5, 1, 0.5)
        else
            GameTooltip:AddLine("All active", 0.5, 1, 0.5)
        end
    else
        local itemID = btn.ConsumablesCurrentItem
        if itemID then
            GameTooltip:AddLine("Left-click to use", 0.5, 0.8, 1)
        end
        GameTooltip:AddLine("Or /fluxconsumables if right-click fails", 0.5, 0.6, 0.7)
    end
    
    GameTooltip:AddLine("Right-click to configure", 0.5, 0.8, 1)
    
    -- Show active preset
    local presetName = Module.GetActivePreset()
    if presetName then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Preset: " .. presetName, 0.7, 0.7, 0.7)
    end
    
    GameTooltip:Show()
    ClearTooltipAuraCache()
end

-- Refresh tooltip if currently shown
function Module.RefreshTooltip()
    if tooltipShowing and Module._button and Module._button.Widget then
        Module.ShowTooltip()
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

-- Update weapon enchant button display (count and icon)
-- Called from BAG_UPDATE events instead of OnUpdate
function Module.UpdateWeaponEnchantButton()
    local btn = Module._button
    if not btn or not btn.ConsumablesIsWeaponEnchant or not btn.ConsumablesItemID then
        return
    end
    
    -- Update count
    if btn.WCount then
        local count = Module.GetItemCount(btn.ConsumablesItemID)
        if count > 0 then
            btn.WCount:SetText(tostring(count))
            btn.WCount:SetTextColor(1, 1, 1, 1)
        else
            btn.WCount:SetText("0")
            btn.WCount:SetTextColor(1, 0.3, 0.3, 1)
        end
        btn.WCount:Show()
        btn.PlaceholderHideCount = nil
    end
    
    -- Update icon
    if btn.WIcon then
        local name, link, icon = GetCachedItemInfo(btn.ConsumablesItemID)
        if not icon then
            name, link, _, _, _, _, _, _, _, icon = GetItemInfo(btn.ConsumablesItemID)
        end
        if icon then
            btn.WIcon:SetTexture(icon)
            btn.WIcon:Show()
        end
    end
    Module.RefreshConsumablesUsability(btn)
end

function Module.RunPostLoginConsumablesRefresh()
    if FluxNCItemDetection then
        if FluxNCItemDetection.InvalidateTooltipCache then FluxNCItemDetection.InvalidateTooltipCache() end
        if FluxNCItemDetection.InvalidateQuickSubclassCache then FluxNCItemDetection.InvalidateQuickSubclassCache() end
    end
    local function doUpdate()
        if not InCombatLockdown() then
            Module.UpdateButtonState(true)
        else
            Module._pendingUpdate = true
        end
    end
    -- Select from the active saved preset and currently available facts now.
    -- The shared settle pulse is a later reconciliation, never an input barrier.
    doUpdate()
    if FluxEBS_PostLoginBagRefresh and FluxEBS_PostLoginBagRefresh.Schedule then
        FluxEBS_PostLoginBagRefresh.Schedule(doUpdate)
    end
end

-- Coalesce frequent UNIT_AURA events into one UpdateButtonState (matches _updateDebounceTime).
-- force=false so debounce can absorb back-to-back ticks; force only on chronoboon/wisp flips.
local function ScheduleCoalescedAuraUpdate(force)
    if Module._auraCoalesceTimer then
        if force then
            Module._auraCoalesceForce = true
        end
        return
    end
    Module._auraCoalesceTimer = true
    if force then
        Module._auraCoalesceForce = true
    end
    Timer.After(Module._updateDebounceTime, function()
        Module._auraCoalesceTimer = nil
        local doForce = Module._auraCoalesceForce == true
        Module._auraCoalesceForce = nil
        if Module._registered then
            if InCombatLockdown() then
                Module._pendingUpdate = true
            else
                Module.UpdateButtonState(doForce)
            end
        end
    end)
end

--- Cheap signature of consumable-relevant aura state. Unrelated buffs must not
--- force UpdateButtonState (first food/proc aura was a cold SetAttribute hitch).
local function ConsumableAuraWatchSig(reuseCache)
    if not reuseCache or not Module._tooltipAuraCache then
        BuildTooltipAuraCache()
    end
    local itemID, buff = nil, nil
    if Module.GetFirstEligibleItem then
        itemID, buff = Module.GetFirstEligibleItem()
    end
    local exp = buff and buff.expirationTime or 0
    local cache = Module._tooltipAuraCache
    local super = cache and cache.hasSuperChrono and 1 or 0
    local world = cache and cache.worldBuffCount or 0
    local wisp = Module._isWispLocked and 1 or 0
    return tostring(itemID or "")
        .. ":" .. tostring(exp)
        .. ":" .. tostring(super)
        .. ":" .. tostring(world)
        .. ":" .. tostring(wisp)
end

function Module.SeedConsumableAuraWatchSig()
    BuildTooltipAuraCache()
    Module._lastConsumableAuraSig = ConsumableAuraWatchSig(true)
    Module._lastSuperchargedState = Module.HasSuperchargedChronoboonBuff()
end

function Module.RegisterEvents()
    if Module._eventFrame then return end
    
    local eventFrame = CreateFrame("Frame")
    Module._eventFrame = eventFrame
    
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    pcall(function() eventFrame:RegisterUnitEvent("UNIT_AURA", "player") end)
    do
        local ok = pcall(function()
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        end)
        if not ok then
            eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        end
    end
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    -- GET_ITEM_INFO_RECEIVED: handled by FluxBagChangeDispatcher (see NCConsumables registration)
    eventFrame:RegisterEvent("PLAYER_DEAD")
    eventFrame:RegisterEvent("PLAYER_ALIVE")
    eventFrame:RegisterEvent("PLAYER_UNGHOST")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

    local function runBuffDurationCheck()
        if not Module._button then
            Module._StopBuffCheckTicker()
            return
        end
        if not Module._BuffWatchNeeded() then
            Module._StopBuffCheckTicker()
            return
        end
        if not (not InCombatLockdown() or Module._isWispLocked) then return end
        local needsUpdate = false

        if Module._isWispLocked then
            local isWispLocked, minRemaining = Module.CheckWispLockState()
            if not isWispLocked or (minRemaining and Module._wispLockMinRemaining and math.abs(minRemaining - Module._wispLockMinRemaining) > 5) then
                needsUpdate = true
            end
        else
            local itemID, buff = Module.GetFirstEligibleItem()
            if not itemID or (buff and buff.expirationTime) then
                local currentTime = GetTime()
                if buff and buff.expirationTime then
                    local timeLeft = buff.expirationTime - currentTime
                    if timeLeft <= REFRESH_THRESHOLD then
                        needsUpdate = true
                    end
                end
            end
        end

        if needsUpdate then
            if InCombatLockdown() then
                Module._pendingUpdate = true
            else
                Module.UpdateButtonState(false)
            end
        end
    end

    function Module._BuffWatchNeeded()
        if not Module._button then
            return false
        end
        local EBV = _G.FluxExtraButtonVisibility
        if EBV and EBV.GetEffectiveMode then
            local mode = EBV.GetEffectiveMode("nc_consumables")
            if mode == "hidden" or mode == "off" then
                return false
            end
        end
        local frame = Module._button.Widget or Module._button.SlotFrame or Module._button
        if frame and frame.IsShown and not frame:IsShown() then
            return false
        end
        return true
    end

    function Module._StopBuffCheckTicker()
        if Module._buffCheckTicker then
            Module._buffCheckTicker:Cancel()
            Module._buffCheckTicker = nil
        end
    end

    function Module._StartBuffCheckTicker()
        if Module._buffCheckTicker or not Module._BuffWatchNeeded() then return end
        if C_Timer and C_Timer.NewTicker then
            Module._buffCheckTicker = C_Timer.NewTicker(5.0, runBuffDurationCheck)
        end
    end

    function Module._SyncBuffCheckTicker()
        if Module._BuffWatchNeeded() then
            Module._StartBuffCheckTicker()
        else
            Module._StopBuffCheckTicker()
        end
    end

    Module._SyncBuffCheckTicker()
    
    eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            -- Combat ended - apply any pending changes
            Module._inCombat = false
            Module.ApplyPendingChanges()
            
            -- Update keybindings if pending
            if Module._pendingKeybindUpdate then
                Module._pendingKeybindUpdate = nil
                Module.UpdateKeybindings()
            end
            
            if Module._pendingUpdate then
                Module._pendingUpdate = nil
                Module.UpdateButtonState(true)  -- Force update after combat
            end
            
        elseif event == "PLAYER_REGEN_DISABLED" then
            -- Entered combat - track state
            Module._inCombat = true
            
        elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
            local isLogin = (event == "PLAYER_LOGIN") or (arg1 == true or arg2 == true)
            if not isLogin and not Module._fluxSeenPew then
                isLogin = true
            end
            Module._fluxSeenPew = true
            if isLogin then
                Module.RunPostLoginConsumablesRefresh()
            elseif Module._registered then
                if InCombatLockdown() then
                    Module._pendingUpdate = true
                else
                    Module.UpdateButtonState(false)
                end
            end
            -- Seed aura watch sig so the first unrelated buff is not a cold miss.
            if Timer and Timer.After then
                Timer.After(0.5, function()
                    if Module.SeedConsumableAuraWatchSig then
                        pcall(Module.SeedConsumableAuraWatchSig)
                    end
                end)
            elseif Module.SeedConsumableAuraWatchSig then
                pcall(Module.SeedConsumableAuraWatchSig)
            end
            
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            -- arg1 = unit, arg2 = castGUID, arg3 = spellID (RegisterUnitEvent)
            if arg1 == "player" then
                local spellID = ...
                -- Some clients pass spellID as arg2 when not using unit-event packing
                if type(spellID) ~= "number" then
                    spellID = arg2
                end
                if Module.OnGroundPlaceableCastSucceeded then
                    Module.OnGroundPlaceableCastSucceeded(spellID)
                end
                if Module.RefreshAuraTimerOverlay then
                    Module.RefreshAuraTimerOverlay()
                end
            end

        elseif event == "UNIT_AURA" then
            if arg1 == "player" then
                local updateInfo = arg2
                local S = _G.Flux and _G.Flux.Secrets
                if S and S.AuraUpdateInfoIsNoop and S.AuraUpdateInfoIsNoop(updateInfo) then
                    return
                end
                if Module._groundAuraLearner and Module.TryProcessGroundAuraLearner then
                    Module.TryProcessGroundAuraLearner()
                end

                -- Build aura cache once for this event (avoids full HELPFUL rescans).
                BuildTooltipAuraCache()
                if Module.RefreshAuraTimerOverlay then
                    Module.RefreshAuraTimerOverlay()
                end

                -- Check if SuperCharged Chronoboon buff state changed
                local currentSuperchargedState = Module.HasSuperchargedChronoboonBuff()
                local superchargedFlipped = (Module._lastSuperchargedState ~= nil
                    and Module._lastSuperchargedState ~= currentSuperchargedState)
                if superchargedFlipped then
                    -- SuperCharged buff state changed - update saved items to replace Chronoboon items in-place
                    local items = Module.GetItems()
                    local chronoboonIDs = Module.FindChronoboonItemIDs()
                    local updated = false
                    
                    for i, itemID in ipairs(items) do
                        if Module.IsChronoboonItem(itemID) then
                            local isSupercharged = Module.IsSuperchargedChronoboonItem(itemID)
                            -- Check if this item doesn't match current state
                            if (currentSuperchargedState and not isSupercharged) or (not currentSuperchargedState and isSupercharged) then
                                -- Find replacement Chronoboon item
                                for _, chronoboonID in ipairs(chronoboonIDs) do
                                    local replacementIsSupercharged = Module.IsSuperchargedChronoboonItem(chronoboonID)
                                    if (currentSuperchargedState and replacementIsSupercharged) or (not currentSuperchargedState and not replacementIsSupercharged) then
                                        if Module.GetItemCount(chronoboonID) > 0 then
                                            -- Replace in-place to preserve priority
                                            items[i] = chronoboonID
                                            updated = true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if updated then
                        -- Update saved items with replaced Chronoboon IDs
                        Module.SetItems(items)
                    end
                end
                Module._lastSuperchargedState = currentSuperchargedState
                
                -- EVENT-BASED: Update WISP LOCK cooldown when auras change
                local wispNeedsForce = false
                if Module._isWispLocked and Module._button then
                    local minRemaining = Module._wispLockMinRemaining or 0
                    local buff = Module._wispLockBuff
                    if minRemaining > 0 and buff then
                        -- Recalculate remaining time
                        local currentRemaining = BuffRemainingSeconds(buff)
                        if currentRemaining > 0 and isfinite(currentRemaining) then
                            Module._wispLockMinRemaining = currentRemaining
                            Module.UpdateWispLockCooldown(Module._button, currentRemaining, buff)
                            Module.RefreshTooltip()
                        else
                            -- Buff expired or invalid
                            if InCombatLockdown() then
                                -- In combat: hide cooldown but keep WISP LOCK icon
                                Module._wispLockMinRemaining = 0
                                local cooldown = Module._button.WCooldown or (Module._button.Widget and Module._button.Widget.cooldown)
                                if cooldown then
                                    cooldown:Hide()
                                end
                                Module.RefreshTooltip()
                            else
                                -- Not in combat: force full update (will exit WISP LOCK)
                                wispNeedsForce = true
                                Module.UpdateButtonState(true)
                            end
                        end
                    else
                        -- No buff
                        if InCombatLockdown() then
                            -- In combat: hide cooldown but keep WISP LOCK icon
                            local cooldown = Module._button.WCooldown or (Module._button.Widget and Module._button.Widget.cooldown)
                            if cooldown then
                                cooldown:Hide()
                            end
                            Module.RefreshTooltip()
                        else
                            -- Not in combat: force full update (will exit WISP LOCK)
                            wispNeedsForce = true
                            Module.UpdateButtonState(true)
                        end
                    end
                end
                
                -- Skip SetAttribute UpdateButtonState when consumable-relevant auras unchanged.
                if not wispNeedsForce then
                    local sig = ConsumableAuraWatchSig(true)
                    if Module._lastConsumableAuraSig ~= nil
                        and sig == Module._lastConsumableAuraSig
                        and not superchargedFlipped then
                        return
                    end
                    Module._lastConsumableAuraSig = sig
                    ScheduleCoalescedAuraUpdate(superchargedFlipped)
                end
            end
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            -- EVENT-BASED: Update WISP LOCK cooldown when spell cooldowns update
            if Module._isWispLocked and Module._button then
                local minRemaining = Module._wispLockMinRemaining or 0
                local buff = Module._wispLockBuff
                if minRemaining > 0 and buff then
                    -- Recalculate remaining time
                    local currentRemaining = BuffRemainingSeconds(buff)
                    if currentRemaining > 0 and isfinite(currentRemaining) then
                        Module._wispLockMinRemaining = currentRemaining
                        Module.UpdateWispLockCooldown(Module._button, currentRemaining, buff)
                    end
                end
            end
        elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
            -- Instant update on death/resurrection (auras are cleared on death)
            if InCombatLockdown() then
                Module._pendingUpdate = true
            else
                Module.UpdateButtonState(true)  -- Force immediate update
            end
        end
    end)

    local function RefreshCountOnly()
        local btn = Module._button
        if not btn or not Module._registered then return end
        if btn.ConsumablesIsWeaponEnchant and btn.ConsumablesItemID then
            Module.UpdateWeaponEnchantButton()
        elseif btn.UpdateTextCount then
            btn:UpdateTextCount()
        end
        if btn.UpdateUsable then
            btn:UpdateUsable()
        end
        -- Keep concrete bag/slot binding on the preferred stack/charges after bag moves
        if not InCombatLockdown() and btn.ConsumablesItemID then
            Module.RebindPreferredUseSlot(btn)
        end
    end

    local function NeedsConsumablesIdentityRefresh()
        local btn = Module._button
        if not btn then return false end
        if Module._isPlaceholder or btn.IsConsumablesPlaceholder then
            local items = Module.GetItems()
            for _, id in ipairs(items or {}) do
                if Module.GetItemCount(id) > 0 then
                    return true
                end
            end
            local itemID = select(1, Module.GetFirstEligibleItem())
            if itemID and Module.GetItemCount(itemID) > 0 then
                return true
            end
        end
        if btn.ConsumablesItemID then
            local count = Module.GetItemCount(btn.ConsumablesItemID)
            if count <= 0 and not Module._isPlaceholder then
                return true
            end
        end
        return false
    end

    local consumablesFullUpdatePending = false

    local function FullConsumablesBagUpdate()
        if consumablesFullUpdatePending then
            return
        end
        consumablesFullUpdatePending = true
        local function run()
            consumablesFullUpdatePending = false
            if not Module._registered then return end
            InvalidateChronoboonIDsCache()
            if not InCombatLockdown() then
                Module.UpdateWeaponEnchantButton()
                Module.UpdateButtonState(true)
            else
                Module._pendingUpdate = true
            end
        end
        if Timer and Timer.After then
            Timer.After(0.25, run)
        else
            run()
        end
    end

    -- Primary: FluxInv bag/bank listeners (ItemDetection dispatcher is TOC-disabled)
    if _G.FluxInv and _G.FluxInv.RegisterListener and not Module._fluxInvListenerRegistered then
        Module._fluxInvListenerRegistered = true
        _G.FluxInv.RegisterListener("FluxNCConsumables", function(ctx)
            if not Module._registered then return end
            local tier = ctx and ctx.tier
            local countOnly = ctx and ctx.changeKind == "countOnly" and not ctx.force
            if countOnly or tier == "instant" or tier == "light" then
                RefreshCountOnly()
                if not countOnly and NeedsConsumablesIdentityRefresh() then
                    if InCombatLockdown() then
                        Module._pendingUpdate = true
                    else
                        Module.UpdateButtonState(true)
                    end
                end
                return
            end
            FullConsumablesBagUpdate()
        end, { tier = "scan", regions = { "bags", "bank" }, deferHeavy = true })
    end

    if FluxBagChangeDispatcher and FluxBagChangeDispatcher.Register then
        FluxBagChangeDispatcher.RegisterCountListener("NCConsumables_instant", function(ctx)
            RefreshCountOnly()
            if not Module._registered then return end
            local countOnly = ctx and ctx.changeKind == "countOnly" and not ctx.force
                and not ctx.fromItemData and not ctx.itemDataItemID
            local inv = _G.FluxInv or _G.FluxInventory
            if countOnly and inv and inv.CountOnlyNeedsIdentityRefresh and inv.CountOnlyNeedsIdentityRefresh(ctx) then
                countOnly = false
            end
            if countOnly then return end
            if NeedsConsumablesIdentityRefresh() then
                if InCombatLockdown() then
                    Module._pendingUpdate = true
                else
                    Module.UpdateButtonState(true)
                end
            end
        end)

        FluxBagChangeDispatcher.RegisterScanListener("NCConsumables", function(ctx)
            if FluxBagChangeDispatcher.OnBagChangeForCombatModule then
                FluxBagChangeDispatcher.OnBagChangeForCombatModule(
                    FullConsumablesBagUpdate, RefreshCountOnly, ctx)
            elseif not Module._bagUpdatePending then
                Module._bagUpdatePending = true
                Timer.After(0.3, function()
                    Module._bagUpdatePending = nil
                    FullConsumablesBagUpdate()
                end)
            end
        end)
    end

    if FluxEBS_PostLoginBagRefresh and FluxEBS_PostLoginBagRefresh.RegisterPulseEndCallback
        and not Module._pulseEndRegistered then
        Module._pulseEndRegistered = true
        FluxEBS_PostLoginBagRefresh.RegisterPulseEndCallback("NCConsumables", function()
            if not Module._registered then return end
            if InCombatLockdown() then
                Module._pendingUpdate = true
            else
                Module.UpdateButtonState(true)
            end
        end)
    end

    if FluxEBS_PostLoginBagRefresh and FluxEBS_PostLoginBagRefresh.RegisterFirstBagDelayedCallback then
        FluxEBS_PostLoginBagRefresh.RegisterFirstBagDelayedCallback("NCConsumables", function()
            if not Module._registered then return end
            if InCombatLockdown() then
                Module._pendingUpdate = true
                return
            end
            if FluxNCItemDetection then
                if FluxNCItemDetection.InvalidateTooltipCache then FluxNCItemDetection.InvalidateTooltipCache() end
                if FluxNCItemDetection.InvalidateQuickSubclassCache then FluxNCItemDetection.InvalidateQuickSubclassCache() end
            end
            Module.UpdateButtonState(true)
        end)
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Force update (called by config window after changes)
function Module.ForceUpdate()
    -- Force update bypasses debounce and stability checks
    Module.UpdateButtonState(true)
end

-- Get button reference
function Module.GetButton()
    return Module._button
end

-- ============================================================================
-- GLOBAL HELPER FOR RIGHT-CLICK MACRO
-- ============================================================================

-- ============================================================================
-- KEYBINDING SETUP
-- ============================================================================

-- Update keybindings to point to the button widget
-- Uses SetOverrideBindingClick for secure keybinding (no taint)
function Module.UpdateKeybindings()
    if InCombatLockdown() then
        Module._pendingKeybindUpdate = true
        return
    end

    local btn = Module._button
    if not btn or not btn.Widget then return end

    local widget = btn.Widget
    local widgetName = widget:GetName()
    if not widgetName then return end

    -- Clear existing bindings first
    ClearOverrideBindings(widget)

    -- Consumables keybinding (left-click)
    local consumablesKey = GetBindingKey("FLUXGRID_CONSUMABLES")
    if consumablesKey then
        SetOverrideBindingClick(widget, false, consumablesKey, widgetName, "LeftButton")
    end

    -- Update hotkey text display
    if FluxNCHotkeyUtil and FluxNCHotkeyUtil.UpdateHotkeyText then
        FluxNCHotkeyUtil.UpdateHotkeyText(btn, "FLUXGRID_CONSUMABLES")
    end
end

-- Clear keybindings (called before update or on module unload)
function Module.ClearKeybindings()
    if InCombatLockdown() then return end
    
    local btn = Module._button
    if not btn or not btn.Widget then return end
    
    ClearOverrideBindings(btn.Widget)
end

-- Global function for right-click macro to call (must be in global scope for secure macros)
function FluxNCConsumables_OpenConfig()
    if not FluxConsumablesConfig or not FluxConsumablesConfig.Toggle then
        return
    end
    -- Anchor is optional; Config.Show falls back to FluxNCConsumables._button for positioning
    local anchor = FluxNCConsumables and FluxNCConsumables._button
    FluxConsumablesConfig.Toggle(anchor)
end

SLASH_FLUXCONSUMABLES1 = "/fluxconsumables"
SlashCmdList["FLUXCONSUMABLES"] = function()
    FluxNCConsumables_OpenConfig()
end

-- Export
if FluxModifierTracker and FluxModifierTracker.Register then
    FluxModifierTracker.Register("NCConsumablesChrono", ConsumablesChronoModifierCallback, {
        isActive = ConsumablesChronoModifierActive,
    })
end

_G.FluxNCConsumables = Module


