-- FluxRespec_EquipmentPresets.lua
-- Global equipment preset system — same pattern as rune presets.
-- Each named preset stores equipment only (no action bars).
-- No player-frame flyout (per design).

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.EquipmentPresets = R.EquipmentPresets or {}
local Presets = R.EquipmentPresets

-- -----------------------------------------------------------------------------
-- Saved vars bootstrap
-- -----------------------------------------------------------------------------

local function EnsureStore()
    if not _G._FluxUI_CharSavedVars then
        _G._FluxUI_CharSavedVars = {}
    end
    local root = _G._FluxUI_CharSavedVars
    if type(root.equipmentPresets) ~= "table" then
        root.equipmentPresets = { activePreset = "default", presets = {} }
    end
    local store = root.equipmentPresets
    if type(store.presets) ~= "table" then
        store.presets = {}
    end
    if not store.activePreset then
        store.activePreset = "default"
    end
    if store.presets["default"] then
        store.presets["default"] = nil
    end
    return store
end

function Presets.EnsureStore()
    return EnsureStore()
end

-- -----------------------------------------------------------------------------
-- Accessors
-- -----------------------------------------------------------------------------

function Presets.GetActivePreset()
    return EnsureStore().activePreset or "default"
end

function Presets.SetActivePreset(name)
    local store = EnsureStore()
    if name == nil or name == "" then
        name = "default"
    end
    if name ~= "default" and not store.presets[name] then
        return false
    end
    store.activePreset = name
    R.Fire("EQUIPMENT_PRESET_CHANGED")
    return true
end

function Presets.GetPresetNames()
    local store = EnsureStore()
    local out = {}
    for name in pairs(store.presets) do
        if name ~= "default" then
            out[#out + 1] = name
        end
    end
    table.sort(out, function(a, b)
        return (a or ""):lower() < (b or ""):lower()
    end)
    return out
end

function Presets.GetPreset(name)
    if not name or name == "default" then
        return nil
    end
    return EnsureStore().presets[name]
end

-- -----------------------------------------------------------------------------
-- CRUD
-- -----------------------------------------------------------------------------

function Presets.CreatePreset(name)
    if type(name) ~= "string" or name == "" or name == "default" then
        R.Warn("Invalid preset name.")
        return false
    end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if R.EquipmentSets and R.EquipmentSets.CanUse and R.EquipmentSets.CanUse() and R.EquipmentSets.TruncName then
        name = R.EquipmentSets.TruncName(name)
    end
    if name == "" or name == "default" then
        R.Warn("Invalid preset name.")
        return false
    end
    local store = EnsureStore()
    if store.presets[name] then
        R.Warn(("Equipment preset '%s' already exists."):format(name))
        return false
    end
    store.presets[name] = { equipment = {} }
    if R.Includes and R.Includes.EnsureEquipmentPreset then
        R.Includes.EnsureEquipmentPreset(store.presets[name])
    end
    store.activePreset = name
    R.Fire("EQUIPMENT_PRESET_CHANGED")
    return true
end

function Presets.RenamePreset(oldName, newName, skipBlizzard)
    if type(oldName) ~= "string" or oldName == "" or oldName == "default" then
        return false
    end
    if type(newName) ~= "string" or newName == "" then
        return false
    end
    newName = newName:gsub("^%s+", ""):gsub("%s+$", "")
    if not skipBlizzard and R.EquipmentSets and R.EquipmentSets.CanUse and R.EquipmentSets.CanUse() and R.EquipmentSets.TruncName then
        newName = R.EquipmentSets.TruncName(newName)
    end
    if newName == "" or newName == "default" then
        return false
    end
    local store = EnsureStore()
    if not store.presets[oldName] then
        return false
    end
    if store.presets[newName] then
        R.Warn(("Equipment preset '%s' already exists."):format(newName))
        return false
    end
    store.presets[newName] = store.presets[oldName]
    store.presets[oldName] = nil
    if store.activePreset == oldName then
        store.activePreset = newName
    end
    local respec = _G._FluxUI_CharSavedVars and _G._FluxUI_CharSavedVars.respec
    if type(respec) == "table" and type(respec.profiles) == "table" then
        for _, profile in pairs(respec.profiles) do
            if type(profile) == "table" and profile.equipmentPreset == oldName then
                profile.equipmentPreset = newName
            end
        end
    end
    if not skipBlizzard and R.EquipmentSets and R.EquipmentSets.PushName then
        pcall(R.EquipmentSets.PushName, store.presets[newName], newName)
    end
    R.Fire("EQUIPMENT_PRESET_CHANGED")
    return true
end

function Presets.DeletePreset(name)
    if type(name) ~= "string" or name == "" or name == "default" then
        return false
    end
    local store = EnsureStore()
    if not store.presets[name] then
        return false
    end
    local dying = store.presets[name]
    if R.EquipmentSets and R.EquipmentSets.DeleteIfManaged then
        pcall(R.EquipmentSets.DeleteIfManaged, dying)
    end
    store.presets[name] = nil
    if store.activePreset == name then
        store.activePreset = "default"
    end
    R.Fire("EQUIPMENT_PRESET_CHANGED")
    return true
end

-- -----------------------------------------------------------------------------
-- Save active preset from live character state
-- -----------------------------------------------------------------------------

function Presets.SaveActivePresetFromLive()
    local store = EnsureStore()
    local name = store.activePreset
    if not name or name == "default" then
        R.Warn("Select a named equipment preset before saving (not default).")
        return false
    end
    local preset = store.presets[name]
    if not preset then
        R.Warn(("Equipment preset '%s' does not exist."):format(name))
        return false
    end

    if R.Includes and R.Includes.EnsureEquipmentPreset then
        R.Includes.EnsureEquipmentPreset(preset)
    end
    if R.Equipment and R.Equipment.Capture then
        local live = R.Equipment.Capture()
        if R.Includes and R.Includes.MergeEnabledPresetEquipment then
            preset.equipment = R.Includes.MergeEnabledPresetEquipment(preset.equipment, live, preset)
        else
            preset.equipment = live
        end
    end
    if not preset.icon and R.EquipmentSets and R.EquipmentSets.PickIcon then
        preset.icon = R.EquipmentSets.PickIcon(preset, true)
    end
    if R.EquipmentSets and R.EquipmentSets.SyncManaged then
        pcall(R.EquipmentSets.SyncManaged, preset, name, true)
    end

    R.Print(("Saved equipment preset '%s'."):format(name))
    R.Fire("EQUIPMENT_PRESET_SAVED", name)
    return true
end

-- -----------------------------------------------------------------------------
-- Apply
-- -----------------------------------------------------------------------------

function Presets.Apply(presetName)
    if type(presetName) ~= "string" or presetName == "" then
        return false
    end
    local store = EnsureStore()

    if presetName == "default" then
        store.activePreset = "default"
        R.Fire("EQUIPMENT_PRESET_CHANGED")
        R.Fire("EQUIPMENT_PRESET_APPLIED", "default")
        return true
    end

    local preset = store.presets[presetName]
    if not preset then
        R.Warn(("Equipment preset '%s' does not exist."):format(presetName))
        return false
    end

    store.activePreset = presetName

    local snap = preset.equipment
    if snap and R.Includes and R.Includes.CopyEnabledPresetEquipment then
        snap = R.Includes.CopyEnabledPresetEquipment(snap, preset) or snap
    end

    local function finishEquip()
        if snap and R.Equipment and R.Equipment.Apply then
            pcall(R.Equipment.Apply, snap)
        end
        R.Fire("EQUIPMENT_PRESET_CHANGED")
        R.Fire("EQUIPMENT_PRESET_APPLIED", presetName)
    end

    local wanted = R.Includes and R.Includes.WantedPresetEquipmentSlotSet and R.Includes.WantedPresetEquipmentSlotSet(preset)
    if R.EquipmentSets and R.EquipmentSets.TryApply then
        R.EquipmentSets.TryApply(preset, wanted, finishEquip, presetName)
    else
        finishEquip()
    end
    return true
end

-- -----------------------------------------------------------------------------
-- Profile link
-- -----------------------------------------------------------------------------

function Presets.LinkProfileEquipmentPreset(profile)
    if type(profile) ~= "table" then
        return
    end
    local name = profile.equipmentPreset
    if type(name) ~= "string" or name == "" then
        name = "default"
    end
    local store = EnsureStore()
    store.activePreset = name
    R.Fire("EQUIPMENT_PRESET_CHANGED")
end

-- -----------------------------------------------------------------------------
-- Match helpers
-- -----------------------------------------------------------------------------

function Presets.MatchesProfileLink(profile)
    if type(profile) ~= "table" then
        return false
    end
    local linked = profile.equipmentPreset
    if type(linked) ~= "string" or linked == "" then
        linked = "default"
    end
    return Presets.GetActivePreset() == linked
end

function Presets.IsDefault()
    return Presets.GetActivePreset() == "default"
end

--- Equipment from the active named preset (nil when default or empty).
function Presets.GetActivePresetEquipment()
    local active = Presets.GetActivePreset()
    if not active or active == "default" then
        return nil
    end
    local preset = Presets.GetPreset(active)
    if not preset or not preset.equipment then
        return nil
    end
    local hasAny = false
    for _ in pairs(preset.equipment) do hasAny = true; break end
    return hasAny and preset.equipment or nil
end

--- Equipment snapshot for UI diff: active preset when named, else profile equipment.
function Presets.GetTargetEquipmentSnapshot(profile)
    local equip = Presets.GetActivePresetEquipment()
    if equip then
        return equip
    end
    if type(profile) == "table" and profile.equipment then
        return profile.equipment
    end
    return nil
end

function Presets.GetTargetEquipmentDiffCount(profile)
    local equip = Presets.GetTargetEquipmentSnapshot(profile)
    if not equip or not R.Equipment or not R.Equipment.DiffCount then
        return 0
    end
    local Inc = R.Includes
    if Inc then
        local preset = Inc.ActiveEquipmentPreset and select(1, Inc.ActiveEquipmentPreset())
        if preset and Inc.CopyEnabledPresetEquipment then
            equip = Inc.CopyEnabledPresetEquipment(equip, preset) or equip
        elseif type(profile) == "table" and Inc.CopyEnabledEquipment then
            equip = Inc.CopyEnabledEquipment(equip, profile) or equip
        end
    end
    return R.Equipment.DiffCount(equip) or 0
end

function Presets.PresetEquipmentMatchLive(presetName)
    if type(presetName) ~= "string" or presetName == "" or presetName == "default" then
        return true
    end
    local preset = Presets.GetPreset(presetName)
    if not preset or not preset.equipment then
        return true
    end
    if R.Equipment and R.Equipment.DiffCount then
        local snap = preset.equipment
        if R.Includes and R.Includes.CopyEnabledPresetEquipment then
            snap = R.Includes.CopyEnabledPresetEquipment(snap, preset) or snap
        end
        return (R.Equipment.DiffCount(snap) or 0) == 0
    end
    return true
end

-- -----------------------------------------------------------------------------
-- Init
-- -----------------------------------------------------------------------------

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "_FluxUI" then
        EnsureStore()
    elseif event == "PLAYER_LOGIN" then
        EnsureStore()
    end
end)

R.EquipmentPresets = Presets


