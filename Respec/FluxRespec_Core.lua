-- FluxRespec_Core.lua
-- Namespace, saved-vars bootstrap, profile CRUD, pub/sub callbacks.
-- Per-character storage under `_FluxUI_CharSavedVars.respec`.

FluxRespec = FluxRespec or {}
local R = FluxRespec
local Compat = R.Compat

-- -----------------------------------------------------------------------------
-- Debug/print helpers
-- -----------------------------------------------------------------------------
function R.Print(msg)
    if DEFAULT_CHAT_FRAME and msg then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffFluxRespec:|r " .. tostring(msg))
    end
end

function R.Warn(msg)
    if DEFAULT_CHAT_FRAME and msg then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800FluxRespec:|r " .. tostring(msg))
    end
end

-- -----------------------------------------------------------------------------
-- Saved variables bootstrap
-- -----------------------------------------------------------------------------

local function EnsureStore()
    if not _G._FluxUI_CharSavedVars then
        _G._FluxUI_CharSavedVars = {}
    end
    local root = _G._FluxUI_CharSavedVars
    if type(root.respec) ~= "table" then
        root.respec = { activeName = nil, profiles = {} }
    end
    -- unitFrameRespecArmedName: profile chosen from unit-frame flyout — gates glow + unit-frame load clicks only.
    if type(root.respec.profiles) ~= "table" then
        root.respec.profiles = {}
    end
    if type(root.respec.settings) ~= "table" then
        root.respec.settings = {}
    end
    if root.respec.settings.protectGearSetItems == nil then
        root.respec.settings.protectGearSetItems = true
    end
    -- loadCheckpointProfile / loadCheckpointStep: persisted in-progress Load (see FluxRespec_Apply).
    return root.respec
end

function R.GetStore()
    return EnsureStore()
end

--- Last seen class-trainer talent unlearn fee (copper), for NEED_TRAINER popup across sessions.
function R.GetPersistedTrainerUnlearnCostCopper()
    local c = EnsureStore().trainerUnlearnCostCopper
    if type(c) == "number" and c > 0 then
        return c
    end
    return nil
end

function R.RememberTrainerUnlearnCostCopper(copper)
    if type(copper) ~= "number" or copper <= 0 then
        return
    end
    local s = EnsureStore()
    s.trainerUnlearnCostCopper = copper
    s.trainerUnlearnCostAt = time()
end

-- -----------------------------------------------------------------------------
-- Pub/sub callbacks
-- -----------------------------------------------------------------------------
R._listeners = R._listeners or {}

function R.On(event, fn)
    if type(event) ~= "string" or type(fn) ~= "function" then return end
    R._listeners[event] = R._listeners[event] or {}
    table.insert(R._listeners[event], fn)
end

function R.Fire(event, ...)
    local list = R._listeners[event]
    if not list then return end
    for _, fn in ipairs(list) do
        pcall(fn, ...)
    end
    if event == "PROFILES_CHANGED" and _G.FluxUnitFrames_PlayerSpecClick_Refresh then
        pcall(_G.FluxUnitFrames_PlayerSpecClick_Refresh)
    end
end

-- -----------------------------------------------------------------------------
-- Profile CRUD
-- -----------------------------------------------------------------------------

--- Get all profile names (sorted, case-insensitive).
function R.GetProfileNames()
    local store = EnsureStore()
    local out = {}
    for name in pairs(store.profiles) do
        table.insert(out, name)
    end
    table.sort(out, function(a, b)
        return (a or ""):lower() < (b or ""):lower()
    end)
    return out
end

--- Get the currently selected profile name (may be nil if none selected).
function R.GetActiveName()
    return EnsureStore().activeName
end

--- Switch global preset selections to match a respec profile's saved links (name only; no bundle apply).
function R.LinkProfilePresets(profile)
    if type(profile) ~= "table" then
        return
    end
    if profile.runePreset == nil then
        profile.runePreset = "default"
    end
    if profile.equipmentPreset == nil then
        profile.equipmentPreset = "default"
    end
    if R.RunePresets and R.RunePresets.LinkProfilePreset then
        pcall(R.RunePresets.LinkProfilePreset, profile)
    end
    if R.EquipmentPresets and R.EquipmentPresets.LinkProfileEquipmentPreset then
        pcall(R.EquipmentPresets.LinkProfileEquipmentPreset, profile)
    end
    -- Consumable list switches on Load (apply-mask), not on profile select.
end

--- Set the selected profile, or pass nil / "" for "No profile" (no spec icon override, no load target).
function R.SetActiveName(name)
    local store = EnsureStore()
    if name == "" then
        name = nil
    end
    if name ~= nil and not store.profiles[name] then
        return false
    end
    store.activeName = name
    if not name then
        store.unitFrameRespecArmedName = nil
    elseif store.unitFrameRespecArmedName and store.unitFrameRespecArmedName ~= name then
        store.unitFrameRespecArmedName = nil
    end
    if name then
        R.LinkProfilePresets(store.profiles[name])
    end
    R.Fire("ACTIVE_CHANGED", name)
    return true
end

function R.HasActiveProfile()
    return R.GetActiveName() ~= nil
end

--- Get an existing profile by name.
function R.GetProfile(name)
    if not name then return nil end
    return EnsureStore().profiles[name]
end

--- Create a new empty profile. Returns the profile table or nil if the name
--- is already taken / invalid.
function R.CreateProfile(name)
    if type(name) ~= "string" or name == "" then
        R.Warn("Profile name cannot be empty.")
        return nil
    end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if R.EquipmentSets and R.EquipmentSets.CanUse and R.EquipmentSets.CanUse() and R.EquipmentSets.TruncName then
        name = R.EquipmentSets.TruncName(name)
    end
    if name == "" then
        R.Warn("Profile name cannot be empty.")
        return nil
    end
    local store = EnsureStore()
    if store.profiles[name] then
        R.Warn(("Profile '%s' already exists."):format(name))
        return nil
    end
    local profile = {
        createdAt = time(),
        client = Compat and Compat.ClientTag() or "Unknown",
        icon = R.DefaultIcon(),
        equipment = nil,
        talents = nil,
        bars = nil,
        runes = nil,
        runePreset = "default",
        equipmentPreset = "default",
        consumables = nil,
        utilitySlots = nil,
        spellBookSlots = nil, -- legacy alias; prefer utilitySlots
        spellBindings = nil,
        infoFrame = nil, -- optional: FluxInfoFrame pins/toggles snapshot (see SerializeRespecProfileSnapshot)
    }
    if R.Includes and R.Includes.ApplyDraftToProfile then
        R.Includes.ApplyDraftToProfile(profile)
    elseif R.Includes and R.Includes.Ensure then
        R.Includes.Ensure(profile)
    end
    store.profiles[name] = profile
    store.activeName = name
    store.unitFrameRespecArmedName = nil
    R.Fire("PROFILE_CREATED", name, profile)
    R.Fire("PROFILES_CHANGED")
    return profile
end

-- -----------------------------------------------------------------------------
-- Spec icon helpers
-- -----------------------------------------------------------------------------

--- Default icon for newly-created profiles: the player's class icon.
function R.DefaultIcon()
    local _, class = UnitClass("player")
    if class then
        return "Interface\\Icons\\ClassIcon_" .. class:lower()
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

--- Get the icon texture (path or fileID) for a profile.
function R.GetIcon(name)
    local p = R.GetProfile(name)
    if not p then return nil end
    if R.EquipmentSets and R.EquipmentSets.DisplayIcon then
        local ic = R.EquipmentSets.DisplayIcon(p, name)
        if ic then
            return ic
        end
    end
    return p.icon or R.DefaultIcon()
end

--- Set the icon texture for a profile. Accepts a path string or numeric fileID.
function R.SetIcon(name, texture)
    local p = R.GetProfile(name)
    if not p then return false end
    p.icon = texture
    p.updatedAt = time()
    if R.EquipmentSets and R.EquipmentSets.PushIcon then
        pcall(R.EquipmentSets.PushIcon, p, texture)
    end
    R.Fire("PROFILE_UPDATED", name, "icon")
    return true
end

--- Delete an existing profile.
function R.DeleteProfile(name)
    local store = EnsureStore()
    if not name or not store.profiles[name] then return false end
    local dying = store.profiles[name]
    if R.EquipmentSets and R.EquipmentSets.DeleteIfManaged then
        pcall(R.EquipmentSets.DeleteIfManaged, dying)
    end
    store.profiles[name] = nil
    if store.unitFrameRespecArmedName == name then
        store.unitFrameRespecArmedName = nil
    end
    if store.activeName == name then
        local names = R.GetProfileNames()
        store.activeName = names[1]
    end
    R.Fire("PROFILE_DELETED", name)
    R.Fire("PROFILES_CHANGED")
    return true
end

--- Rename a profile in-place.
function R.RenameProfile(oldName, newName, skipBlizzard)
    if type(newName) ~= "string" or newName == "" then return false end
    newName = newName:gsub("^%s+", ""):gsub("%s+$", "")
    if not skipBlizzard and R.EquipmentSets and R.EquipmentSets.CanUse and R.EquipmentSets.CanUse() and R.EquipmentSets.TruncName then
        newName = R.EquipmentSets.TruncName(newName)
    end
    if newName == "" then return false end
    local store = EnsureStore()
    if not store.profiles[oldName] then return false end
    if store.profiles[newName] then
        R.Warn(("Profile '%s' already exists."):format(newName))
        return false
    end
    store.profiles[newName] = store.profiles[oldName]
    store.profiles[oldName] = nil
    if store.activeName == oldName then
        store.activeName = newName
    end
    if store.unitFrameRespecArmedName == oldName then
        store.unitFrameRespecArmedName = newName
    end
    if not skipBlizzard and R.EquipmentSets and R.EquipmentSets.PushName then
        pcall(R.EquipmentSets.PushName, store.profiles[newName], newName)
    end
    R.Fire("PROFILE_RENAMED", oldName, newName)
    R.Fire("PROFILES_CHANGED")
    return true
end

--- Duplicate an existing profile under a new name.
function R.DuplicateProfile(srcName, newName)
    if type(newName) ~= "string" or newName == "" then return false end
    local store = EnsureStore()
    if not store.profiles[srcName] then return false end
    if store.profiles[newName] then
        R.Warn(("Profile '%s' already exists."):format(newName))
        return false
    end
    store.profiles[newName] = Compat.DeepCopy(store.profiles[srcName])
    store.profiles[newName].createdAt = time()
    if R.Includes and R.Includes.Ensure then
        R.Includes.Ensure(store.profiles[newName])
    end
    local bs = store.profiles[newName].includes and store.profiles[newName].includes.blizzardSet
    if type(bs) == "table" then
        bs.id = nil
        bs.name = nil
        bs.managed = false
    end
    R.Fire("PROFILE_CREATED", newName, store.profiles[newName])
    R.Fire("PROFILES_CHANGED")
    return true
end

--- Write a section snapshot into a profile. Section is one of
--- "equipment" | "talents" | "bars" | "runes" | "consumables" | "utilitySlots" | "spellBookSlots" | "infoFrame".
function R.SetSection(name, section, data)
    local store = EnsureStore()
    local profile = store.profiles[name]
    if not profile then return false end
    profile[section] = data
    profile.updatedAt = time()
    R.Fire("PROFILE_UPDATED", name, section)
    return true
end

--- Capture the current state into a (possibly new) profile by name.
--- Uses the registered modules if present.
function R.CaptureInto(name)
    if type(name) ~= "string" or name == "" then
        R.Warn("Profile name cannot be empty.")
        return false
    end
    local store = EnsureStore()
    local profile = store.profiles[name]
    if not profile then
        profile = R.CreateProfile(name)
        if not profile then return false end
    end

    if R.Includes and R.Includes.Ensure then
        R.Includes.Ensure(profile)
    end
    local function sectionOn(key)
        if not R.Includes or not R.Includes.SectionEnabled then
            return true
        end
        return R.Includes.SectionEnabled(profile, key) ~= false
    end

    -- Unchecked sections/slots keep last save; checked parts recapture from live.
    if sectionOn("equipment") and R.Equipment and R.Equipment.Capture then
        local live = R.Equipment.Capture()
        if R.Includes and R.Includes.MergeEnabledEquipment then
            profile.equipment = R.Includes.MergeEnabledEquipment(profile.equipment, live, profile)
        else
            profile.equipment = live
        end
    end
    if sectionOn("talents") and R.Talents and R.Talents.Capture then
        profile.talents = R.Talents.Capture()
    end
    -- Retail (post-Dragonflight): action-bar *slots* are part of each Blizzard loadout,
    -- so we do not snapshot slots 1–120. Flux stance bar order/hidden still saves.
    local skipBars = Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts()
    if sectionOn("bars") then
        if not skipBars and R.ActionBars and R.ActionBars.Capture then
            profile.bars = R.ActionBars.Capture()
        elseif skipBars and R.ActionBars and R.ActionBars.CaptureStanceLayout then
            profile.bars = R.ActionBars.CaptureStanceLayout()
        elseif skipBars then
            profile.bars = nil
        end
    end
    if sectionOn("runes") and R.Runes and R.Runes.Capture then
        local shouldPreserve = R.RunePresets and R.RunePresets.ShouldPreserveProfileRunesOnSave
            and R.RunePresets.ShouldPreserveProfileRunesOnSave(profile)
        if not shouldPreserve then
            local live = R.Runes.Capture()
            if live then
                if R.Includes and R.Includes.MergeEnabledRunes then
                    profile.runes = R.Includes.MergeEnabledRunes(profile.runes, live, profile)
                else
                    profile.runes = live
                end
            end
        end
    end
    -- Remember which global presets this profile uses (updated every save).
    if R.RunePresets and R.RunePresets.GetActivePreset then
        profile.runePreset = R.RunePresets.GetActivePreset()
    end
    if R.EquipmentPresets and R.EquipmentPresets.GetActivePreset then
        profile.equipmentPreset = R.EquipmentPresets.GetActivePreset()
    end
    if sectionOn("consumables") and R.Consumables and R.Consumables.Capture then
        profile.consumables = R.Consumables.Capture()
    end
    if sectionOn("utilitySlots") then
        if _G.FluxNCUtilitySlots_CaptureSnapshot then
            profile.utilitySlots = _G.FluxNCUtilitySlots_CaptureSnapshot()
            profile.spellBookSlots = profile.utilitySlots
        elseif _G.FluxSpellBookSlots_CaptureSnapshot then
            profile.utilitySlots = _G.FluxSpellBookSlots_CaptureSnapshot()
            profile.spellBookSlots = profile.utilitySlots
        end
    end
    if sectionOn("spellBindings") and _G.FluxSpellBindings_CaptureSnapshot then
        local snap = _G.FluxSpellBindings_CaptureSnapshot()
        if type(snap) == "table" then
            profile.spellBindings = snap
        elseif _G.FluxSpellBindings_EmptySnapshot then
            if type(profile.spellBindings) ~= "table" then
                profile.spellBindings = _G.FluxSpellBindings_EmptySnapshot()
            end
        end
    end
    if sectionOn("infoFrame") and _G.FluxInfoFrame and _G.FluxInfoFrame.SerializeRespecProfileSnapshot then
        profile.infoFrame = _G.FluxInfoFrame.SerializeRespecProfileSnapshot()
    end

    -- Preserve icon; only seed a default when the profile was just created.
    if not profile.icon then
        profile.icon = R.DefaultIcon()
    end

    if sectionOn("equipment") and R.EquipmentSets and R.EquipmentSets.SyncManaged then
        local ok, reason = R.EquipmentSets.SyncManaged(profile, name, false)
        if not ok and reason == "QUOTA" then
            -- Printed once from EquipmentSets.
        end
    end

    profile.updatedAt = time()
    profile.client = Compat and Compat.ClientTag() or profile.client
    store.activeName = name
    store.unitFrameRespecArmedName = nil
    R.Fire("PROFILE_SAVED", name, profile)
    R.Fire("PROFILES_CHANGED")
    R.Print(("Saved profile '%s'."):format(name))
    return true
end

--- Apply a profile by name. Delegates to FluxRespec_Apply.
function R.LoadProfile(name)
    if R.Apply and R.Apply.Run then
        return R.Apply.Run(name)
    end
    R.Warn("Apply orchestrator not loaded yet.")
    return false
end

--- Apply Flux InfoFrame pinned stats / toggles from a saved profile (if present).
function R.ApplyInfoFrameForProfile(name)
    if type(name) ~= "string" or name == "" then
        return
    end
    local profile = R.GetProfile(name)
    if not profile or profile.infoFrame == nil then
        return
    end
    if R.Includes and R.Includes.SectionEnabled and not R.Includes.SectionEnabled(profile, "infoFrame") then
        return
    end
    local fn = _G.FluxInfoFrame and _G.FluxInfoFrame.ApplyRespecProfileSnapshot
    if type(fn) == "function" then
        fn(profile.infoFrame)
    end
end

function R.ClearUnitFrameRespecArmed()
    EnsureStore().unitFrameRespecArmedName = nil
end

function R.SetUnitFrameRespecArmed(name)
    local store = EnsureStore()
    if type(name) ~= "string" or name == "" then
        store.unitFrameRespecArmedName = nil
    else
        store.unitFrameRespecArmedName = name
    end
end

--- True when the unit-frame flyout armed this profile for glow / left-click load (matches active name).
function R.IsUnitFrameRespecArmedForActiveProfile()
    local store = EnsureStore()
    local armed = store.unitFrameRespecArmedName
    local active = R.GetActiveName()
    return armed ~= nil and active ~= nil and armed == active
end

--- Set active profile without starting apply. Pass fromUnitFlyout=true to arm the player unit-frame spec button (glow + same load path as flyout pick).
function R.SelectActiveProfileOnly(name, fromUnitFlyout)
    if type(name) ~= "string" or name == "" or not R.GetProfile(name) then
        return false
    end
    fromUnitFlyout = fromUnitFlyout and true or false
    local before = R.GetActiveName()
    if not R.SetActiveName(name) then
        return false
    end
    if R.UI and R.UI.Refresh then
        if not (Compat and Compat.SecureUIPanelsBlockRespecWork and Compat.SecureUIPanelsBlockRespecWork()) then
            R.UI.Refresh()
        end
    end
    if before ~= name and R.Apply and R.Apply.IsRunning and R.Apply.IsRunning() then
        R.Apply.Cancel()
    end
    if fromUnitFlyout then
        R.SetUnitFrameRespecArmed(name)
    else
        R.ClearUnitFrameRespecArmed()
    end
    return true
end

--- Same hardware path as the Respec window "Load Profile" button: Apply.Run, optional first CastNext for engrave queue.
function R.RunLoadProfileButtonAction()
    local name = R.GetActiveName()
    if not name then
        return
    end
    if R.Apply and R.Apply.IsRunning and R.Apply.IsRunning()
        and not (R.Apply.IsEngraveButtonMode and R.Apply.IsEngraveButtonMode()) then
        return
    end
    R.LoadProfile(name)
    local prof = R.GetProfile and R.GetProfile(name)
    local headGearBlocked = prof and R.Runes and R.Runes.HeadBlockedByProfileGear
        and R.Runes.HeadBlockedByProfileGear(prof)
    if R.Apply and R.Apply.IsEngraveButtonMode and R.Apply.IsEngraveButtonMode()
        and R.Apply.WillSwitchSpec and not R.Apply.WillSwitchSpec()
        and R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue()
        and R.Runes.CastNext and not headGearBlocked then
        R.Runes.CastNext()
    end
end

-- -----------------------------------------------------------------------------
-- Active profile "build" match (talents + gear + runes on SoD) — for player spec icon override
-- -----------------------------------------------------------------------------

--- True when the active profile's equipment matches what the character is wearing.
function R.ActiveProfileGearMatches(profile)
    if not profile then
        local name = R.GetActiveName()
        if not name then return true end
        profile = R.GetProfile(name)
    end
    if not profile or not profile.equipment then
        return true
    end
    if R.Equipment and R.Equipment.AnyGearChangeNeeded then
        local snap = profile.equipment
        if R.Includes and R.Includes.CopyEnabledEquipment then
            snap = R.Includes.CopyEnabledEquipment(snap, profile) or snap
        end
        return not R.Equipment.AnyGearChangeNeeded(snap)
    end
    return true
end

local cachedTalentRuneMatch = nil
local cachedTalentRuneValid = false

local function GetTalentRuneBuildMatches(profile)
    if cachedTalentRuneValid then
        return cachedTalentRuneMatch
    end
    local Compat = R.Compat
    local ok = true
    local Inc = R.Includes
    if profile.talents and R.Talents and R.Talents.Matches
        and not (Inc and Inc.SectionEnabled and not Inc.SectionEnabled(profile, "talents")) then
        local g = Compat.GetActiveGroup()
        if not R.Talents.Matches(profile.talents, g) then
            ok = false
        end
    end
    if ok and profile.runes and Compat and Compat.IsSoD and Compat.IsSoD() and R.Runes and R.Runes.DiffCount then
        local runes = profile.runes
        if Inc and Inc.CopyEnabledRunes then
            runes = Inc.CopyEnabledRunes(runes, profile) or runes
        end
        if (R.Runes.DiffCount(runes) or 0) > 0 then
            ok = false
        end
    end
    cachedTalentRuneMatch = ok
    cachedTalentRuneValid = true
    return ok
end

--- True when the active profile's talents, equipment, and runes (SoD only) all match the character.
--- Does not include action bars or consumables.
function R.ActiveProfileBuildMatches()
    local name = R.GetActiveName()
    if not name then return false end
    local profile = R.GetProfile(name)
    if not profile then return false end
    if not GetTalentRuneBuildMatches(profile) then
        return false
    end
    if not R.ActiveProfileGearMatches(profile) then
        return false
    end
    return true
end

--- Icon texture for the active profile (profile.icon, else talent snapshot heuristic). No UnitFrames calls.
function R.GetActiveProfileBuildIcon()
    local name = R.GetActiveName()
    if not name then return nil end
    local profile = R.GetProfile(name)
    if not profile then return nil end
    local specIcon = profile.icon
    if (not specIcon or specIcon == "" or specIcon == 0) and R.Talents and R.Talents.SpecIconFromSnapshot and profile.talents then
        specIcon = R.Talents.SpecIconFromSnapshot(profile.talents)
    end
    if not specIcon or specIcon == "" or specIcon == 0 then
        specIcon = R.DefaultIcon()
    end
    return specIcon
end

-- -----------------------------------------------------------------------------
-- Persisted load checkpoint (next step) for Load Profile UI
-- -----------------------------------------------------------------------------

function R.SetLoadCheckpoint(profileName, step)
    local store = EnsureStore()
    store.loadCheckpointProfile = profileName
    store.loadCheckpointStep = step
end

function R.ClearLoadCheckpoint()
    local store = EnsureStore()
    store.loadCheckpointProfile = nil
    store.loadCheckpointStep = nil
end

function R.GetLoadCheckpoint()
    local store = EnsureStore()
    return store.loadCheckpointProfile, store.loadCheckpointStep
end

local lastSpecDecorMatch = nil
local lastSpecDecorIcon = nil
local specDecorCacheValid = false

--- UnitFrames player strip: override spec icon when build matches active profile (set from Register/init).
function R.RefreshPlayerSpecIconDecor()
    if Compat and Compat.SecureUIPanelsBlockRespecWork and Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    local matches = R.ActiveProfileBuildMatches()
    local icon = matches and R.GetActiveProfileBuildIcon() or nil
    if matches == lastSpecDecorMatch and icon == lastSpecDecorIcon then
        return
    end
    lastSpecDecorMatch = matches
    lastSpecDecorIcon = icon
    specDecorCacheValid = true
    if _G.FluxUnitFrames_RefreshPlayerSpecIcon then
        pcall(_G.FluxUnitFrames_RefreshPlayerSpecIcon)
    end
end

local function InvalidateSpecDecorCache()
    lastSpecDecorMatch = nil
    lastSpecDecorIcon = nil
    specDecorCacheValid = false
    cachedTalentRuneValid = false
end

local function ShouldRefreshSpecIconOnEquipChange(changedSlotID)
    local name = R.GetActiveName()
    if not name then
        return false
    end
    local profile = R.GetProfile(name)
    if not profile then
        return false
    end
    local hasEquip = profile.equipment and type(profile.equipment) == "table" and next(profile.equipment)
    local hasRunes = profile.runes and Compat and Compat.IsSoD and Compat.IsSoD() and next(profile.runes)
    if not hasEquip and not hasRunes then
        return false
    end
    if not changedSlotID then
        return true
    end
    if hasEquip and R.Equipment and R.Equipment.SlotRelevantToProfileEquipment then
        if R.Equipment.SlotRelevantToProfileEquipment(profile, changedSlotID) then
            return true
        end
    end
    if hasRunes and profile.runes[changedSlotID] then
        return true
    end
    return false
end

-- -----------------------------------------------------------------------------
-- Init event — make sure the store exists as soon as saved vars are ready.
-- -----------------------------------------------------------------------------
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "_FluxUI" then
            EnsureStore()
            if R.Includes and R.Includes.MigrateAll then
                R.Includes.MigrateAll()
            end
        end
    elseif event == "PLAYER_LOGIN" then
        EnsureStore()
        if R.Includes and R.Includes.MigrateAll then
            R.Includes.MigrateAll()
        end
        local name = R.GetActiveName()
        if name then
            local profile = R.GetProfile(name)
            if profile then
                R.LinkProfilePresets(profile)
            end
        end
        R.Fire("READY")
    end
end)

-- -----------------------------------------------------------------------------
-- Slash commands (debug / headless use)
-- -----------------------------------------------------------------------------
SLASH_FLUXRESPEC1 = "/fluxrespec"
SLASH_FLUXRESPEC2 = "/respec"
SlashCmdList["FLUXRESPEC"] = function(msg)
    msg = msg or ""
    local args = {}
    for w in msg:gmatch("%S+") do table.insert(args, w) end
    local cmd = (args[1] or ""):lower()

    if cmd == "save" and args[2] then
        local name = msg:match("^%s*%S+%s+(.+)$") or args[2]
        R.CaptureInto(name)
    elseif cmd == "load" and args[2] then
        local name = msg:match("^%s*%S+%s+(.+)$") or args[2]
        R.LoadProfile(name)
    elseif cmd == "list" then
        local names = R.GetProfileNames()
        if #names == 0 then
            R.Print("No profiles saved.")
        else
            R.Print("Profiles: " .. table.concat(names, ", "))
        end
    elseif cmd == "delete" and args[2] then
        local name = msg:match("^%s*%S+%s+(.+)$") or args[2]
        if R.DeleteProfile(name) then
            R.Print(("Deleted '%s'."):format(name))
        end
    else
        R.Print("Commands: /respec list | save <name> | load <name> | delete <name>")
    end
end

-- -----------------------------------------------------------------------------
-- Player unit frame spec icon (UnitFrames loads before Respec — late globals)
-- -----------------------------------------------------------------------------

_G.FluxRespec_GetPlayerSpecIconOverride = function()
    if specDecorCacheValid then
        if lastSpecDecorMatch then
            return lastSpecDecorIcon
        end
        return nil
    end
    local flux = _G.FluxRespec
    if not flux or not flux.ActiveProfileBuildMatches or not flux.ActiveProfileBuildMatches() then
        return nil
    end
    if flux.GetActiveProfileBuildIcon then
        return flux.GetActiveProfileBuildIcon()
    end
    return nil
end

local specIconRefreshFrame = CreateFrame("Frame")
local specIconDebounceTimer = nil

--- Player strip spec icon: keep this cheap — TRAIT_CONFIG_UPDATED can fire many times per second on Retail.
local function SchedulePlayerSpecIconRefreshOnceDelayed()
    if Compat and Compat.SecureUIPanelsBlockRespecWork and Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.12, function()
            R.RefreshPlayerSpecIconDecor()
        end)
    else
        R.RefreshPlayerSpecIconDecor()
    end
end

local function SchedulePlayerSpecIconRefreshDebounced()
    if Compat and Compat.SecureUIPanelsBlockRespecWork and Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    if specIconDebounceTimer and specIconDebounceTimer.Cancel then
        pcall(function()
            specIconDebounceTimer:Cancel()
        end)
        specIconDebounceTimer = nil
    end
    if C_Timer and C_Timer.NewTimer then
        specIconDebounceTimer = C_Timer.NewTimer(0.28, function()
            specIconDebounceTimer = nil
            R.RefreshPlayerSpecIconDecor()
        end)
    else
        R.RefreshPlayerSpecIconDecor()
    end
end

local function InitSpecIconRefreshBridge()
    specIconRefreshFrame:UnregisterAllEvents()
    -- Do NOT register TRAIT_CONFIG_UPDATED here — it spams during talent commits and caused heavy lag.
    if _G.FluxSafeRegisterEvent then
        FluxSafeRegisterEvent(specIconRefreshFrame, "PLAYER_SPECIALIZATION_CHANGED")
    else
        pcall(function()
            specIconRefreshFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        end)
    end
    specIconRefreshFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    specIconRefreshFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    specIconRefreshFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    specIconRefreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    specIconRefreshFrame:SetScript("OnEvent", function(_, event, changedSlotID)
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            if not ShouldRefreshSpecIconOnEquipChange(changedSlotID) then
                return
            end
        else
            InvalidateSpecDecorCache()
        end
        SchedulePlayerSpecIconRefreshDebounced()
    end)
    R.On("RUNE_QUEUE_CHANGED", function()
        InvalidateSpecDecorCache()
        SchedulePlayerSpecIconRefreshOnceDelayed()
    end)
    R.On("APPLY_DONE", function()
        InvalidateSpecDecorCache()
        SchedulePlayerSpecIconRefreshOnceDelayed()
    end)
    R.On("TALENTS_APPLIED", function()
        InvalidateSpecDecorCache()
        SchedulePlayerSpecIconRefreshOnceDelayed()
    end)
    R.On("PROFILES_CHANGED", function()
        InvalidateSpecDecorCache()
        SchedulePlayerSpecIconRefreshOnceDelayed()
    end)
    R.On("ACTIVE_CHANGED", function(name)
        InvalidateSpecDecorCache()
        SchedulePlayerSpecIconRefreshOnceDelayed()
    end)
end

local bootSpecIcon = CreateFrame("Frame")
bootSpecIcon:RegisterEvent("PLAYER_LOGIN")
bootSpecIcon:SetScript("OnEvent", function()
    InitSpecIconRefreshBridge()
    SchedulePlayerSpecIconRefreshOnceDelayed()
end)


