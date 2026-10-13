-- FluxRespec_RunePresets.lua
-- Global rune preset system for Season of Discovery.
-- Each named preset stores a bundle: runes + utility slots + action bars (tagged with talent tree at save time).
-- Presets live outside respec profiles in _FluxUI_CharSavedVars.runePresets.
-- A respec profile can LINK to a preset name (profile.runePreset) but profile
-- load always uses profile.runes — the link is for UI display and quick-switch.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.RunePresets = R.RunePresets or {}
local Presets = R.RunePresets
local Compat = R.Compat
local Bundle = R.PresetBundle

-- Pending deferred bars from a preset quick-switch (cleared by LinkProfilePreset).
Presets._pendingBarsPresetName = nil
--- Temporary UI choice when preset bars talent tree is missing from both specs (nil = auto).
Presets._barsApplyChoice = nil
local presetApplyGen = 0

function Presets.GetBarsApplyChoice()
    return Presets._barsApplyChoice
end

function Presets.SetBarsApplyChoice(value)
    if value == true or value == false then
        Presets._barsApplyChoice = value
    else
        Presets._barsApplyChoice = nil
    end
end

function Presets.ShouldSkipBarsOnClient()
    return Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts()
end

local function GetActiveNamedPreset()
    local name = Presets.GetActivePreset()
    if not name or name == "default" then
        return nil, nil
    end
    return name, Presets.GetPreset(name)
end

--- Show Yes/No bars toggle on save or load when neither spec has the preset's saved talent tree.
function Presets.NeedsBarsConfirm(action)
    if Presets.ShouldSkipBarsOnClient() or not Bundle then
        return false
    end
    local _, preset = GetActiveNamedPreset()
    if not preset then
        return false
    end
    if action == "save" then
        if not Bundle.PresetHasAnyBars(preset) then
            return false
        end
        return not Bundle.PresetBarsTalentMatchesAnySpec(preset)
    end
    if action == "load" then
        if not Bundle.PresetHasAnyBars(preset) then
            return false
        end
        local _, _, mode = Bundle.ResolveBarsBundleForPreset(preset)
        return mode == "confirm"
    end
    return false
end

function Presets.ShouldSaveBarsForActivePreset()
    if Presets.ShouldSkipBarsOnClient() or not Bundle then
        return false
    end
    if not Presets.NeedsBarsConfirm("save") then
        return true
    end
    return Presets._barsApplyChoice == true
end

function Presets.ShouldApplyBarsForPreset(preset)
    if Presets.ShouldSkipBarsOnClient() or not Bundle or type(preset) ~= "table" then
        return false
    end
    local _, _, mode = Bundle.ResolveBarsBundleForPreset(preset)
    if mode == "skip" then
        return false
    end
    if mode == "auto" then
        return true
    end
    if mode == "confirm" then
        return Presets._barsApplyChoice == true
    end
    return false
end

function Presets.ApplyBarsForPreset(preset)
    if not Presets.ShouldApplyBarsForPreset(preset) then
        return false
    end
    local bars = select(1, Bundle.ResolveBarsBundleForPreset(preset))
    if bars then
        return Bundle.ApplyBarsSnapshot(bars)
    end
    return false
end

-- -----------------------------------------------------------------------------
-- Saved vars bootstrap
-- -----------------------------------------------------------------------------

local function EnsureStore()
    if not _G._FluxUI_CharSavedVars then
        _G._FluxUI_CharSavedVars = {}
    end
    local root = _G._FluxUI_CharSavedVars
    if type(root.runePresets) ~= "table" then
        root.runePresets = { activePreset = "default", presets = {} }
    end
    local store = root.runePresets
    if type(store.presets) ~= "table" then
        store.presets = {}
    end
    if not store.activePreset then
        store.activePreset = "default"
    end
    -- Strip any legacy saved "default" bucket — default is virtual.
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
    R.Fire("RUNE_PRESET_CHANGED")
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
    local store = EnsureStore()
    if store.presets[name] then
        R.Warn(("Rune preset '%s' already exists."):format(name))
        return false
    end
    store.presets[name] = { runes = {}, barsByGroup = {}, barsTalentByGroup = {}, utilitySlotsByGroup = {}, spellBookSlotsByGroup = {} }
    if R.Includes and R.Includes.EnsureRunePreset then
        R.Includes.EnsureRunePreset(store.presets[name])
    end
    store.activePreset = name
    R.Fire("RUNE_PRESET_CHANGED")
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
    store.presets[name] = nil
    if store.activePreset == name then
        store.activePreset = "default"
    end
    R.Fire("RUNE_PRESET_CHANGED")
    return true
end

-- -----------------------------------------------------------------------------
-- Save active preset from live character state
-- -----------------------------------------------------------------------------

function Presets.SaveActivePresetFromLive()
    local store = EnsureStore()
    local name = store.activePreset
    if not name or name == "default" then
        R.Warn("Select a named preset before saving (not default).")
        return false
    end
    local preset = store.presets[name]
    if not preset then
        R.Warn(("Rune preset '%s' does not exist."):format(name))
        return false
    end

    if R.Includes and R.Includes.EnsureRunePreset then
        R.Includes.EnsureRunePreset(preset)
    end
    if R.Runes and R.Runes.Capture then
        local runes = R.Runes.Capture()
        if runes then
            if R.Includes and R.Includes.MergeEnabledPresetRunes then
                preset.runes = R.Includes.MergeEnabledPresetRunes(preset.runes, runes, preset)
            else
                preset.runes = runes
            end
        end
    end

    -- Utility slots always; action bars only when talent tree matches or user confirms Yes.
    if Bundle then
        Bundle.MigratePreset(preset)
        Bundle.SaveSpellBookForActiveGroup(preset)
        local extraParts = {}
        if Presets.ShouldSaveBarsForActivePreset() and Bundle.SaveBarsForActiveGroup(preset) then
            local g = Bundle.GetActiveGroup()
            local talentSnap = preset.barsTalentByGroup and preset.barsTalentByGroup[g]
            extraParts[#extraParts + 1] = Bundle.TalentTreeLabel(talentSnap) .. " action bars"
        end
        extraParts[#extraParts + 1] = "utility slots"
        local suffix = (#extraParts > 0) and (" (" .. table.concat(extraParts, " & ") .. ")") or ""
        R.Print(("Saved rune preset '%s'%s."):format(name, suffix))
    else
        R.Print(("Saved rune preset '%s'."):format(name))
    end
    R.Fire("RUNE_PRESET_SAVED", name)
    return true
end

-- -----------------------------------------------------------------------------
-- Apply (quick-switch)
-- -----------------------------------------------------------------------------

local function ApplyPresetBody(presetName, preset)
    local store = EnsureStore()
    store.activePreset = presetName

    if Bundle then
        Bundle.MigratePreset(preset)
    end

    local hasQueue = false
    if preset.runes and R.Runes and R.Runes.StartQueue then
        local runes = preset.runes
        if R.Includes and R.Includes.CopyEnabledPresetRunes then
            runes = R.Includes.CopyEnabledPresetRunes(runes, preset) or runes
        end
        hasQueue = R.Runes.StartQueue(runes)
    end

    if Bundle and Bundle.ApplySpellBookForActiveGroup(preset) then
        -- applied
    end

    local hasBarsBundle = Bundle and Bundle.PresetHasAnyBars(preset)
    if hasBarsBundle and Presets.ShouldApplyBarsForPreset(preset) then
        if not hasQueue then
            if Presets.ApplyBarsForPreset(preset) then
                Presets._pendingBarsPresetName = nil
            end
        else
            Presets._pendingBarsPresetName = presetName
        end
    else
        Presets._pendingBarsPresetName = nil
    end

    R.Fire("RUNE_PRESET_CHANGED")
    R.Fire("RUNE_PRESET_APPLIED", presetName)
    return true
end

function Presets.Apply(presetName, onDone)
    if type(presetName) ~= "string" or presetName == "" then
        if onDone then onDone(false) end
        return false
    end
    presetApplyGen = presetApplyGen + 1
    local myGen = presetApplyGen

    local function finish(ok)
        if myGen ~= presetApplyGen then return end
        if onDone then pcall(onDone, ok) end
    end

    if InCombatLockdown() then
        R.Warn("Can't load rune preset in combat.")
        finish(false)
        return false
    end

    local store = EnsureStore()

    if presetName == "default" then
        store.activePreset = "default"
        Presets._pendingBarsPresetName = nil
        if R.Runes and R.Runes.ClearQueue then
            R.Runes.ClearQueue()
        end
        R.Fire("RUNE_PRESET_CHANGED")
        R.Fire("RUNE_PRESET_APPLIED", "default")
        finish(true)
        return true
    end

    local preset = store.presets[presetName]
    if not preset then
        R.Warn(("Rune preset '%s' does not exist."):format(presetName))
        finish(false)
        return false
    end

    local talentSnap = Bundle and Bundle.GetPrimaryTalentSnapshotForPreset(preset)
    local needsSwitch = talentSnap and R.Talents and R.Talents.WouldSwitchSpec
        and R.Talents.WouldSwitchSpec(talentSnap)

    local function runApply()
        if myGen ~= presetApplyGen then return end
        local ok = ApplyPresetBody(presetName, preset) and true or false
        finish(ok)
    end

    if needsSwitch and R.Talents.SwitchToMatchingGroup then
        R.Talents.SwitchToMatchingGroup(talentSnap, function(ok, reason)
            if myGen ~= presetApplyGen then return end
            if not ok then
                if reason == "IN_COMBAT" then
                    R.Warn("Can't switch spec for rune preset in combat.")
                elseif reason == "SPEC_SWITCH_TIMEOUT" or reason == "SPEC_SWITCH_CANCELLED" then
                    R.Warn("Spec switch cancelled — rune preset not loaded.")
                else
                    R.Warn(("Could not switch spec for rune preset (%s)."):format(tostring(reason)))
                end
                finish(false)
                return
            end
            if reason == "SPEC_SWITCHED" then
                local matchG = R.Talents.FindMatchingGroupIndex and R.Talents.FindMatchingGroupIndex(talentSnap)
                local label = (Bundle and Bundle.GroupLabel and Bundle.GroupLabel(matchG)) or ("Spec %d"):format(matchG or 0)
                R.Print(("Switched to %s for rune preset."):format(label))
            end
            runApply()
        end)
        return true
    end

    runApply()
    return true
end

--- Apply preset bundle, then engrave the first queued rune (secure click path only).
function Presets.ApplyAndStartEngrave(presetName)
    if InCombatLockdown() then
        R.Warn("Can't engrave runes in combat.")
        return false
    end
    Presets.Apply(presetName, function(ok)
        if not ok or presetName == "default" then
            return
        end
        if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
            if R.Runes.CastNext then
                R.Runes.CastNext()
            end
        end
    end)
    return true
end

-- -----------------------------------------------------------------------------
-- Profile link (set active preset name only, no bundle apply)
-- -----------------------------------------------------------------------------

function Presets.LinkProfilePreset(profile)
    if type(profile) ~= "table" then
        return
    end
    local name = profile.runePreset
    if type(name) ~= "string" or name == "" then
        name = "default"
    end
    local store = EnsureStore()
    store.activePreset = name
    -- Profile load owns bars; clear any pending preset bars override.
    Presets._pendingBarsPresetName = nil
    R.Fire("RUNE_PRESET_CHANGED")
end

-- -----------------------------------------------------------------------------
-- Hook: called by Apply pipeline when rune queue starts during profile load
-- -----------------------------------------------------------------------------

function Presets.OnApplyQueueStarted()
    -- During profile load the queue is from profile.runes, not from a preset.
    -- Clear pending preset bars so profile bars win after the queue finishes.
    Presets._pendingBarsPresetName = nil
end

-- -----------------------------------------------------------------------------
-- Deferred bars: apply preset bars when rune queue finishes (quick-switch only)
-- -----------------------------------------------------------------------------

local function OnRuneQueueChanged()
    if not Presets._pendingBarsPresetName then
        return
    end
    if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
        return
    end
    local name = Presets._pendingBarsPresetName
    Presets._pendingBarsPresetName = nil
    local store = EnsureStore()
    local preset = name and store.presets[name]
    if not preset then
        return
    end
    if Bundle then
        Bundle.MigratePreset(preset)
        if Presets.ShouldApplyBarsForPreset(preset) then
            Presets.ApplyBarsForPreset(preset)
        end
    end
end

R.On("RUNE_QUEUE_CHANGED", OnRuneQueueChanged)

-- -----------------------------------------------------------------------------
-- Target runes resolution
-- -----------------------------------------------------------------------------

--- Runes from the active named preset (nil when default or empty).
function Presets.GetActivePresetRunes()
    local active = Presets.GetActivePreset()
    if not active or active == "default" then
        return nil
    end
    local preset = Presets.GetPreset(active)
    if not preset or not preset.runes then
        return nil
    end
    local hasAny = false
    for _ in pairs(preset.runes) do hasAny = true; break end
    return hasAny and preset.runes or nil
end

--- True when live runes match the named preset's rune snapshot.
function Presets.PresetRunesMatchLive(presetName)
    if type(presetName) ~= "string" or presetName == "" or presetName == "default" then
        return true
    end
    local preset = Presets.GetPreset(presetName)
    if not preset or not preset.runes then
        return true
    end
    if R.Runes and R.Runes.DiffCount then
        local runes = preset.runes
        if R.Includes and R.Includes.CopyEnabledPresetRunes then
            runes = R.Includes.CopyEnabledPresetRunes(runes, preset) or runes
        end
        return (R.Runes.DiffCount(runes) or 0) == 0
    end
    return true
end

--- Diff count for active named preset runes vs live (0 when default).
function Presets.GetActivePresetRuneDiffCount()
    local runes = Presets.GetActivePresetRunes()
    if not runes or not R.Runes or not R.Runes.DiffCount then
        return 0
    end
    local preset = Presets.GetPreset(Presets.GetActivePreset())
    if preset and R.Includes and R.Includes.CopyEnabledPresetRunes then
        runes = R.Includes.CopyEnabledPresetRunes(runes, preset) or runes
    end
    return R.Runes.DiffCount(runes) or 0
end

--- Returns the rune snapshot to use as "target" for strip borders / diff UI.
--- Priority (matches gear): active named preset → profile.runes → linked preset bundle.
function Presets.GetTargetRunesSnapshotForStrip(profile)
    local presetRunes = Presets.GetActivePresetRunes()
    if presetRunes then
        return presetRunes
    end
    if type(profile) ~= "table" then
        return nil
    end
    if profile.runes then
        local hasAny = false
        for _ in pairs(profile.runes) do hasAny = true; break end
        if hasAny then
            return profile.runes
        end
    end
    local linked = profile.runePreset
    if type(linked) == "string" and linked ~= "" and linked ~= "default" then
        local preset = Presets.GetPreset(linked)
        if preset and preset.runes then
            return preset.runes
        end
    end
    return nil
end

--- Returns the rune snapshot to use as "target" for diff/UI.
function Presets.GetTargetRunesSnapshot()
    local pname = R.GetActiveName and R.GetActiveName()
    if pname then
        local profile = R.GetProfile and R.GetProfile(pname)
        return Presets.GetTargetRunesSnapshotForStrip(profile)
    end
    return Presets.GetActivePresetRunes()
end

function Presets.GetTargetRunesSnapshotForProfile(profile)
    return Presets.GetTargetRunesSnapshotForStrip(profile)
end

-- -----------------------------------------------------------------------------
-- Match helpers
-- -----------------------------------------------------------------------------

--- True when the active preset name matches the profile's saved runePreset link.
function Presets.MatchesProfileLink(profile)
    if type(profile) ~= "table" then
        return false
    end
    local linked = profile.runePreset
    if type(linked) ~= "string" or linked == "" then
        linked = "default"
    end
    return Presets.GetActivePreset() == linked
end

--- True when active preset is "default" (no named bundle).
function Presets.IsDefault()
    return Presets.GetActivePreset() == "default"
end

--- Diff count between a target snapshot and live runes.
function Presets.GetTargetRuneDiffCount()
    local target = Presets.GetTargetRunesSnapshot()
    if not target then
        return 0
    end
    if R.Runes and R.Runes.DiffCount then
        return R.Runes.DiffCount(target) or 0
    end
    return 0
end

-- -----------------------------------------------------------------------------
-- Flyout pick (engrave only, no data writes)
-- -----------------------------------------------------------------------------

function Presets.HandleFlyoutPick(slotID, skillLineAbilityID)
    if R.Runes and R.Runes.CastSkillLineOnSlot then
        return R.Runes.CastSkillLineOnSlot(slotID, skillLineAbilityID)
    end
    return false
end

-- -----------------------------------------------------------------------------
-- Preserve runes on save
-- -----------------------------------------------------------------------------

--- When the profile has a runePreset link AND live runes differ from saved
--- profile.runes, Save Profile should keep the old profile.runes/runePreset
--- so temporary flyout tweaks stay revertible via Load Profile.
function Presets.ShouldPreserveProfileRunesOnSave(profile)
    if type(profile) ~= "table" then
        return false
    end
    local linked = profile.runePreset
    if type(linked) ~= "string" or linked == "" or linked == "default" then
        return false
    end
    if not profile.runes then
        return false
    end
    -- Check if live runes differ from saved profile.runes.
    if not R.Runes or not R.Runes.DiffCount then
        return false
    end
    local diff = R.Runes.DiffCount(profile.runes) or 0
    return diff > 0
end

-- -----------------------------------------------------------------------------
-- Engrave advance (player frame / UI "Engrave next")
-- -----------------------------------------------------------------------------

--- Advance the engrave queue or start one from the current target snapshot.
--- Returns true if a cast was attempted (secure path required).
function Presets.AdvanceEngrave()
    if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
        if R.Runes.CastNext then
            return R.Runes.CastNext()
        end
        return false
    end
    -- No active queue; build one from target snapshot if there are diffs.
    local target = Presets.GetTargetRunesSnapshot()
    if not target then
        return false
    end
    if R.Runes and R.Runes.DiffCount and (R.Runes.DiffCount(target) or 0) > 0 then
        if R.Runes.StartQueue then
            R.Runes.StartQueue(target)
        end
        if R.Runes.CastNext then
            return R.Runes.CastNext()
        end
    end
    return false
end

-- -----------------------------------------------------------------------------
-- Player frame glow: preset-only mode (no respec profile)
-- -----------------------------------------------------------------------------

function Presets.ShouldShowUnitFrameRuneGlow()
    -- Only in preset-only mode (no respec profile selected).
    if R.GetActiveName and R.GetActiveName() then
        return false
    end
    if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
        return true
    end
    return false
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

R.RunePresets = Presets


