-- FluxRespec_Apply.lua
-- Orchestrator for loading a profile. Flow:
--   1) Talents (incl. dual-spec switch) and gear swap start together on the first apply click (parallel).
--   2) SoD rune queue — built at the same time as (1); you can engrave while spec/gear update (secure click each).
--   3) Action Bars                         Only after setup (1–2) completes.
--   4) Consumables preset (FluxNC active preset also set on first apply click; reapplied at end if needed)
--   5) Utility slots (addon-owned; OOC)
--   6) Flux spell bindings (Binding V3 snapshot via FluxSpellBindings_*; combat-deferred)
--
-- Steps are skipped when a section already matches (DiffCount / Matches / etc.).
-- Talent or gear failure aborts the load (in-flight talents cancelled; rune queue cleared).
--
-- One main button: runs every automatic step (talents+gear in parallel, then bars/consumables when
-- applicable) until the first step that needs a secure action — SoD runes: one engrave per further click.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.Apply = R.Apply or {}
local Apply = R.Apply
local Compat = R.Compat

--- Blizzard GENERIC_CONFIRMATION only — never register addon keys on global StaticPopupDialogs (taint / GameMenu).
local function ShowNeedTrainerDialog()
    if Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    local body
    if R.Talents and R.Talents.BuildNeedTrainerPopupText then
        body = R.Talents.BuildNeedTrainerPopupText()
    end
    if not body or body == "" then
        body = "This profile needs a class trainer talent reset before it can load. Visit your trainer, then try Load again."
    end
    StaticPopup_Show("GENERIC_CONFIRMATION", nil, nil, {
        text = body,
        acceptText = "Auto-confirm @ trainer",
        cancelText = "I'll confirm manually",
        callback = function()
            if R.Talents and R.Talents.SetTrainerPayPreauthorized then
                R.Talents.SetTrainerPayPreauthorized(true)
            end
            if R.Print then
                R.Print("FluxRespec: trainer gold / wipe prompts will auto-accept until talents match this profile.")
            end
        end,
        cancelCallback = function()
            if R.Talents and R.Talents.SetTrainerPayPreauthorized then
                R.Talents.SetTrainerPayPreauthorized(false)
            end
        end,
    })
end

local function ShowWrongClassTalentDialog()
    if Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    StaticPopup_Show("GENERIC_CONFIRMATION", nil, nil, {
        text = "FluxUI couldn't apply the talent build: %s",
        text_arg1 = "wrong class for this profile",
        acceptText = OKAY or "Okay",
        cancelText = CANCEL or "Cancel",
        callback = function() end,
    })
end

Apply._state = nil

local function SectionOn(profile, section)
    local Inc = R.Includes
    if not Inc or not Inc.SectionEnabled then
        return true
    end
    return Inc.SectionEnabled(profile, section) ~= false
end

local function EquipSnap(profile)
    if not profile or not profile.equipment or not SectionOn(profile, "equipment") then
        return nil
    end
    if R.Includes and R.Includes.CopyEnabledEquipment then
        return R.Includes.CopyEnabledEquipment(profile.equipment, profile)
    end
    return profile.equipment
end

local function RuneSnap(profile)
    if not profile or not profile.runes or not SectionOn(profile, "runes") then
        return nil
    end
    if R.Includes and R.Includes.CopyEnabledRunes then
        return R.Includes.CopyEnabledRunes(profile.runes, profile)
    end
    return profile.runes
end

--- Retail (post-DF): talents/action-bar layout are owned by Blizzard loadouts, so the Respec pipeline
--- skips the Bars step entirely — see StepBars / ProfileAlreadyFullyApplied / NextStepLabel below.
local function SkipBarsOnRetail()
    return Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts() == true
end

local function SetStatus(msg)
end

local function FinishSuccess()
    Apply._state = nil
    if R.ClearLoadCheckpoint then
        R.ClearLoadCheckpoint()
    end
    R.Fire("APPLY_DONE", true, "DONE")
end

--- Clear an in-progress apply (rune queue, state). Does not fire APPLY_DONE.
--- @param preserveRunes boolean|nil SoD: keep the rune engrave queue when stopping for NEEDS_TRAINER so you can engrave before visiting the trainer.
local function ClearApplyState(preserveRunes)
    Apply._state = nil
    if R.Talents and R.Talents.AbortApply then
        pcall(R.Talents.AbortApply)
    end
    if not preserveRunes and R.Runes and R.Runes.ClearQueue then
        pcall(R.Runes.ClearQueue)
    end
end

--- Stop load with failure; clears queue so gear/runes/bars do not continue.
local function AbortPipeline(reason)
    local preserveRunes = false
    if reason == "NEEDS_TRAINER"
        and Compat.IsSoD and Compat.IsSoD()
        and R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
        preserveRunes = true
    end
    ClearApplyState(preserveRunes)
    if R.ClearLoadCheckpoint then
        R.ClearLoadCheckpoint()
    end
    R.Fire("APPLY_DONE", false, reason or "ABORTED")
    if preserveRunes and R.Fire then
        R.Fire("RUNE_QUEUE_CHANGED")
    end
end

local function IsCurrent(id)
    return Apply._state ~= nil and Apply._state.id == id
end

function Apply.IsRunning()
    return Apply._state ~= nil
end

function Apply.IsWaitingForRuneEngrave()
    local s = Apply._state
    return s and s.waitingForRunes == true
end

--- Engrave mode: the rune queue is the source of truth so the label survives spec-switch completion.
function Apply.IsEngraveButtonMode()
    if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
        return true
    end
    local s = Apply._state
    return (s and s.waitingForRunes) and true or false
end

--- True while the current load will (or did) initiate a dual-spec switch. Used by hardware-click handlers
--- so they don't auto-engrave the first rune while the spec-change confirmation is pending.
function Apply.WillSwitchSpec()
    local s = Apply._state
    return s and s.willSwitchSpec == true or false
end

function Apply.Cancel()
    if not Apply._state then return end
    ClearApplyState()
    if R.ClearLoadCheckpoint then
        R.ClearLoadCheckpoint()
    end
    SetStatus("Load cancelled.")
    R.Fire("APPLY_DONE", false, "CANCELLED")
end

local StepTalentsAndGear, StepBars, StepConsumables, StepSpellBookSlots, StepSpellBindings, StepDone

--- True when talents, gear, and SoD runes all match (bars/consumables may still differ).
local function ProfileParallelSetupComplete(profile)
    if SectionOn(profile, "talents") and profile.talents and R.Talents and R.Talents.Matches then
        local g = Compat.GetActiveGroup()
        if not R.Talents.Matches(profile.talents, g) then
            return false
        end
    end
    local equip = EquipSnap(profile)
    if equip and R.Equipment and R.Equipment.AnyGearChangeNeeded then
        if R.Equipment.AnyGearChangeNeeded(equip) then
            return false
        end
    end
    local runes = RuneSnap(profile)
    if runes and Compat.IsSoD and Compat.IsSoD() and R.Runes and R.Runes.DiffCount then
        if (R.Runes.DiffCount(runes) or 0) > 0 then
            return false
        end
    end
    return true
end

local function ResolveSpellBindingsSnap(profile)
    if not profile then return nil end
    -- nil = never captured: skip restore (do not wipe live FluxBindingDB3).
    local snap = profile.spellBindings
    if type(snap) ~= "table" then return nil end
    return snap
end

local function ProfileSpellBindingsMatch(profile)
    if not _G.FluxSpellBindings_MatchesSnapshot then return true end
    local snap = ResolveSpellBindingsSnap(profile)
    if not snap then return true end
    -- Legacy V2 blobs are unrestorable — treat as non-blocking "match" so load continues.
    if _G.FluxSpellBindings_IsLegacySnapshot and _G.FluxSpellBindings_IsLegacySnapshot(snap) then
        return true
    end
    if _G.FluxSpellBindings_IsV3Snapshot and not _G.FluxSpellBindings_IsV3Snapshot(snap) then
        return true
    end
    return _G.FluxSpellBindings_MatchesSnapshot(snap)
end

local function ResolveProfileUtilitySnap(profile)
    if not profile then return nil end
    if type(profile.utilitySlots) == "table" then
        return profile.utilitySlots
    end
    if type(profile.spellBookSlots) == "table" then
        return profile.spellBookSlots
    end
    return nil
end

local function UtilityMatches(snap)
    if _G.FluxNCUtilitySlots_MatchesSnapshot then
        return _G.FluxNCUtilitySlots_MatchesSnapshot(snap)
    end
    if _G.FluxSpellBookSlots_MatchesSnapshot then
        return _G.FluxSpellBookSlots_MatchesSnapshot(snap)
    end
    return false
end

local function UtilityApply(snap)
    if _G.FluxNCUtilitySlots_ApplySnapshot then
        return _G.FluxNCUtilitySlots_ApplySnapshot(snap)
    end
    if _G.FluxSpellBookSlots_ApplySnapshot then
        return _G.FluxSpellBookSlots_ApplySnapshot(snap)
    end
    return false, "NO_API"
end

--- True when talents, gear, runes, bars, and consumables already match the profile (skip whole pipeline).
local function ProfileAlreadyFullyApplied(profile)
    if SectionOn(profile, "talents") and profile.talents and R.Talents and R.Talents.Matches then
        local g = Compat.GetActiveGroup()
        if not R.Talents.Matches(profile.talents, g) then
            return false
        end
    end
    local equip = EquipSnap(profile)
    if equip and R.Equipment and R.Equipment.AnyGearChangeNeeded then
        if R.Equipment.AnyGearChangeNeeded(equip) then
            return false
        end
    end
    local runes = RuneSnap(profile)
    if runes and Compat.IsSoD and Compat.IsSoD() and R.Runes and R.Runes.DiffCount then
        if (R.Runes.DiffCount(runes) or 0) > 0 then
            return false
        end
    end
    if SectionOn(profile, "bars") and profile.bars and R.ActionBars and R.ActionBars.MatchesSnapshot then
        if not R.ActionBars.MatchesSnapshot(profile.bars) then
            return false
        end
    end
    if SectionOn(profile, "consumables") and profile.consumables and R.Consumables and R.Consumables.IsDifferent then
        if R.Consumables.IsDifferent(profile.consumables) then
            return false
        end
    end
    if SectionOn(profile, "utilitySlots") and ResolveProfileUtilitySnap(profile)
        and (_G.FluxNCUtilitySlots_MatchesSnapshot or _G.FluxSpellBookSlots_MatchesSnapshot) then
        local snap = ResolveProfileUtilitySnap(profile)
        if not UtilityMatches(snap) then
            return false
        end
    end
    if SectionOn(profile, "spellBindings") and _G.FluxSpellBindings_MatchesSnapshot
        and not ProfileSpellBindingsMatch(profile) then
        return false
    end
    if SectionOn(profile, "infoFrame") and R.Includes and R.Includes.InfoFrameMatches then
        if not R.Includes.InfoFrameMatches(profile) then
            return false
        end
    end
    return true
end

--- True when the profile matches the character in every saved section (full pipeline noop).
function Apply.IsProfileFullyApplied(name)
    if not name or name == "" then return false end
    local profile = R.GetProfile(name)
    if not profile then return false end
    return ProfileAlreadyFullyApplied(profile)
end

--- Rune count remaining from the live queue (running) or the profile-vs-char diff (preview).
local function RuneCountForLabel(profile)
    if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
        local q = R.Runes.GetActiveQueue and R.Runes.GetActiveQueue()
        if type(q) == "table" and #q > 0 then return #q end
        return 1
    end
    local runes = RuneSnap(profile)
    if runes and Compat and Compat.IsSoD and Compat.IsSoD()
        and R.Runes and R.Runes.DiffCount then
        return (R.Runes.DiffCount(runes) or 0)
    end
    return 0
end

local function ProfileTalentsMatchActive(profile)
    if not SectionOn(profile, "talents") then return true end
    if not (profile and profile.talents and R.Talents and R.Talents.Matches) then return true end
    local active = Compat and Compat.GetActiveGroup and Compat.GetActiveGroup() or 1
    return R.Talents.Matches(profile.talents, active) and true or false
end

local function ProfileWouldSwitchSpec(profile)
    if not SectionOn(profile, "talents") then return false end
    if not (profile and profile.talents and R.Talents and R.Talents.WouldSwitchSpec) then return false end
    return R.Talents.WouldSwitchSpec(profile.talents) and true or false
end

local function ProfileGearDiffers(profile)
    local equip = EquipSnap(profile)
    if not (equip and R.Equipment and R.Equipment.AnyGearChangeNeeded) then return false end
    return R.Equipment.AnyGearChangeNeeded(equip) and true or false
end

local function ProfileBarsDiffer(profile)
    if not SectionOn(profile, "bars") then return false end
    if not (profile and profile.bars and R.ActionBars and R.ActionBars.MatchesSnapshot) then return false end
    return not R.ActionBars.MatchesSnapshot(profile.bars)
end

local function ProfileConsumablesDiffer(profile)
    if not SectionOn(profile, "consumables") then return false end
    if not (profile and profile.consumables and R.Consumables and R.Consumables.IsDifferent) then return false end
    return R.Consumables.IsDifferent(profile.consumables) and true or false
end

local function ProfileSpellBookSlotsDiffer(profile)
    if not SectionOn(profile, "utilitySlots") then return false end
    local snap = ResolveProfileUtilitySnap(profile)
    if not snap then return false end
    if not (_G.FluxNCUtilitySlots_MatchesSnapshot or _G.FluxSpellBookSlots_MatchesSnapshot) then
        return false
    end
    return not UtilityMatches(snap)
end

local function ProfileSpellBindingsDiffer(profile)
    if not SectionOn(profile, "spellBindings") then return false end
    if not _G.FluxSpellBindings_MatchesSnapshot then return false end
    return not ProfileSpellBindingsMatch(profile)
end

--- Label for the main button: the specific next step this click will perform.
--- Never returns "Apply profile"; callers should also handle the checkpoint/resume case separately.
--- Returns `label, kind` where kind ∈ { "engrave", "spec", "talents", "gear", "bars", "consumables",
--- "spellbook", "bindings", "infoframe", "parallel-running", "bars-running", "consumables-running", "noop", "none" }.
function Apply.NextStepLabel(profileOrName)
    local profile
    if type(profileOrName) == "string" then
        profile = R.GetProfile(profileOrName)
    elseif type(profileOrName) == "table" then
        profile = profileOrName
    else
        local name = R.GetActiveName and R.GetActiveName()
        profile = name and R.GetProfile and R.GetProfile(name) or nil
    end

    -- Rune cast targets the item in each paperdoll slot — equip profile gear for the queue head first.
    if profile and R.Runes and R.Runes.HeadBlockedByProfileGear and R.Runes.HeadBlockedByProfileGear(profile) then
        local st = Apply._state
        if st and st.phase == "parallel" and st.needGear then
            return "Equipping gear…", "parallel-running"
        end
        return "Equip gear", "gear"
    end

    local runeN = RuneCountForLabel(profile)
    if runeN > 0 then
        return ("Engrave next (%d)"):format(runeN), "engrave"
    end

    local state = Apply._state
    if state then
        if state.phase == "bars" then
            return SkipBarsOnRetail() and "Updating stance bar…" or "Updating bars…", "bars-running"
        elseif state.phase == "consumables" then
            return "Switching consumables…", "consumables-running"
        elseif state.phase == "spellbook" then
            return "Utility slots…", "spellbook-running"
        elseif state.phase == "bindings" then
            return "Spell bindings…", "bindings-running"
        elseif state.phase == "parallel" then
            -- needTalents stays true for the whole parallel step; use talentsPhaseDone so we don't show
            -- "Learning talents" after Retail loadout/spec work has already finished (common UI bug).
            if state.needTalents and not state.talentsPhaseDone then
                if state.willSwitchSpec then
                    return "Switching spec…", "parallel-running"
                end
                return "Learning talents…", "parallel-running"
            end
            if state.needGear and not state.gearPhaseDone then
                return "Equipping gear…", "parallel-running"
            end
            if state.needTalents and state.needGear then
                return "Applying…", "parallel-running"
            elseif state.needTalents or state.needGear then
                return "Applying…", "parallel-running"
            end
            return "Applying…", "parallel-running"
        end
    end

    if not profile then
        return "Load Profile", "none"
    end

    if ProfileWouldSwitchSpec(profile) then
        return "Switch spec", "spec"
    end
    if not ProfileTalentsMatchActive(profile) then
        return "Learn talents", "talents"
    end
    if ProfileGearDiffers(profile) then
        return "Equip gear", "gear"
    end
    if ProfileBarsDiffer(profile) then
        return "Update bars", "bars"
    end
    if ProfileConsumablesDiffer(profile) then
        return "Switch consumables", "consumables"
    end
    if ProfileSpellBookSlotsDiffer(profile) then
        return "Utility slots", "spellbook"
    end
    if ProfileSpellBindingsDiffer(profile) then
        return "Spell bindings", "bindings"
    end
    if SectionOn(profile, "infoFrame") and R.Includes and R.Includes.InfoFrameMatches
        and not R.Includes.InfoFrameMatches(profile) then
        return "Info Frame", "infoframe"
    end
    return "Load Profile", "noop"
end

--- Proceed to action bars only when talents, gear, and runes (if any) are all finished.
local function TryJoinFullSetup(id)
    if not IsCurrent(id) then return end
    local state = Apply._state
    if not state then return end
    if state.setupJoined then return end
    -- Never advance while the SoD queue still has casts (avoids runesPhaseDone / UI desync after spec swap).
    if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
        state.runesPhaseDone = false
        state.waitingForRunes = true
        if R.Fire then
            R.Fire("RUNE_QUEUE_CHANGED")
        end
        return
    end
    if not state.talentsPhaseDone or not state.gearPhaseDone or not state.runesPhaseDone then return end
    if not state.talentsPhaseOk or not state.gearPhaseOk or not state.runesPhaseOk then return end
    state.setupJoined = true
    state.waitingForRunes = nil
    if R.SetLoadCheckpoint and state.name then
        R.SetLoadCheckpoint(state.name, "bars")
    end
    if R.RunePresets and R.RunePresets.LinkProfilePreset then
        pcall(R.RunePresets.LinkProfilePreset, state.profile)
    end
    if R.EquipmentPresets and R.EquipmentPresets.LinkProfileEquipmentPreset then
        pcall(R.EquipmentPresets.LinkProfileEquipmentPreset, state.profile)
    end
    StepBars()
end

--- SoD: build rune queue when setup starts (parallel with talents+gear); engraves use secure main-button clicks.
local function BeginRunesPhase(id)
    if not IsCurrent(id) then return end
    local state = Apply._state
    if not state then return end
    local profile = state.profile

    state.runesPhaseOk = true

    if not (R.Runes and Compat and Compat.IsSoD and Compat.IsSoD()) then
        state.runesPhaseDone = true
        return
    end

    local runes = RuneSnap(profile)
    if not runes then
        state.runesPhaseDone = true
        return
    end

    local queueLen = (R.Runes.DiffCount and R.Runes.DiffCount(runes)) or 0
    if queueLen == 0 then
        state.runesPhaseDone = true
        return
    end

    -- Set before Runes.Apply: StartQueue fires RUNE_QUEUE_CHANGED synchronously; UI must see
    -- waitingForRunes so the main button shows "Engrave next" instead of "Applying…".
    state.waitingForRunes = true
    state.runesPhaseDone = false

    if R.Runes.Apply then
        R.Runes.Apply(runes)
    end

    if not (R.Runes.HasActiveQueue and R.Runes.HasActiveQueue()) then
        state.waitingForRunes = nil
        state.runesPhaseDone = true
    else
        if R.RunePresets and R.RunePresets.OnApplyQueueStarted then
            pcall(R.RunePresets.OnApplyQueueStarted)
        end
        if R.Fire then
            -- Queue built: refresh UI now that waitingForRunes is fully settled (belt-and-suspenders).
            R.Fire("RUNE_QUEUE_CHANGED")
        end
    end
end

--- SoD: true if this profile still has rune diffs (queue will be built when we reach the rune step).
local function ProfileNeedsRuneQueue(profile)
    local runes = RuneSnap(profile)
    if not (runes and Compat.IsSoD and Compat.IsSoD() and R.Runes and R.Runes.DiffCount) then
        return false
    end
    return (R.Runes.DiffCount(runes) or 0) > 0
end

local function HandleTalentPhaseResult(id, ok, reason)
    if not IsCurrent(id) then return end
    local state = Apply._state
    if not state then return end
    state.talentsPhaseDone = true
    state.talentsPhaseOk = ok

    if not ok then
        if reason == "NEEDS_TRAINER" then
            SetStatus("Visit a class trainer to reset talents, then try Load again.")
            ShowNeedTrainerDialog()
            R.Warn("Load stopped: talents need a trainer reset before this profile can apply.")
            if R.Talents and R.Talents.SyncTrainerUnlearnQueueForActiveProfile then
                R.Talents.SyncTrainerUnlearnQueueForActiveProfile()
            end
        elseif reason == "WRONG_CLASS" then
            ShowWrongClassTalentDialog()
            R.Warn("Load stopped: profile is for a different class.")
        elseif reason == "IN_COMBAT" then
            SetStatus("In combat: talents will not apply. Load again out of combat.")
            R.Warn("Load stopped: in combat.")
        elseif reason == "SPEC_SWITCH_TIMEOUT" then
            R.Warn("Load stopped: dual specialization change timed out (try Load again).")
        elseif reason == "SPEC_SWITCH_CANCELLED" then
            R.Warn("Load stopped: specialization did not change (dialog cancelled or blocked).")
        else
            SetStatus("Talent apply failed (" .. tostring(reason) .. ").")
            R.Warn("Load stopped: talents — " .. tostring(reason))
        end
        AbortPipeline(reason or "TALENTS_FAILED")
        return
    end

    if reason == "SPEC_SWITCHED" then
        SetStatus("Switched dual-spec.")
    elseif reason == "DONE" then
        SetStatus("Talents applied.")
    elseif reason == "NOOP" then
        SetStatus("Talents already match.")
    end

    TryJoinFullSetup(id)
end

--- Talents, gear, and (SoD) rune queue all start together; engrave anytime (secure). Bars after all three finish.
StepTalentsAndGear = function()
    local state = Apply._state
    if not state then return end
    local profile = state.profile
    local id = state.id

    local needTalents = SectionOn(profile, "talents") and R.Talents and profile.talents and R.Talents.Apply
    local equip = EquipSnap(profile)
    local needGearReorder = equip and R.Equipment and R.Equipment.AnyGearChangeNeeded
        and R.Equipment.AnyGearChangeNeeded(equip)
    local needGear = equip and R.Equipment and R.Equipment.ApplyWithCallback and needGearReorder
    local needRunesQueue = ProfileNeedsRuneQueue(profile)
    local runeSnap = RuneSnap(profile)

    state.phase = "parallel"
    state.talentsPhaseDone = not needTalents
    state.gearPhaseDone = not needGear
    state.talentsPhaseOk = true
    state.gearPhaseOk = true
    state.setupJoined = false
    state.runesPhaseOk = true
    state.waitingForRunes = nil
    state.needTalents = needTalents and true or false
    state.needGear = needGear and true or false

    if needRunesQueue then
        BeginRunesPhase(id)
    else
        state.runesPhaseDone = true
    end

    local baseMsg
    if needTalents and needGear then
        baseMsg = "Applying talents and equipping gear"
    elseif needTalents then
        baseMsg = "Applying talents"
    elseif needGear then
        baseMsg = "Equipping gear"
    end
    if state.waitingForRunes then
        local rem = 0
        if R.Runes and R.Runes.GetActiveQueue then
            local q = R.Runes.GetActiveQueue()
            if type(q) == "table" then
                rem = #q
            end
        end
        local tail = (" — engrave %d rune(s) in parallel (main button)."):format(rem > 0 and rem or 1)
        if baseMsg then
            SetStatus(baseMsg .. "…" .. tail)
        else
            SetStatus("Engrave runes" .. tail)
        end
    elseif baseMsg then
        SetStatus(baseMsg .. "…")
    end

    if needGear then
        local function StartFluxGear()
            R.Equipment.ApplyWithCallback(equip, function(ok)
                if not IsCurrent(id) then return end
                local st = Apply._state
                if not st then return end
                st.gearPhaseDone = true
                st.gearPhaseOk = ok
                if not ok then
                    SetStatus("Equipment apply failed.")
                    R.Warn("Load stopped: could not complete gear swap.")
                    AbortPipeline("EQUIPMENT_FAILED")
                    return
                end
                TryJoinFullSetup(id)
            end, runeSnap)
        end
        local wanted = R.Includes and R.Includes.WantedEquipmentSlotSet and R.Includes.WantedEquipmentSlotSet(profile)
        local pname = state.name
        if R.EquipmentSets and R.EquipmentSets.TryApply then
            R.EquipmentSets.TryApply(profile, wanted, function()
                if not IsCurrent(id) then return end
                StartFluxGear()
            end, pname)
        else
            StartFluxGear()
        end
    end

    if needTalents then
        R.Talents.Apply(profile.talents, function(ok, reason)
            HandleTalentPhaseResult(id, ok, reason)
        end)
    end

    if not needTalents and not needGear then
        TryJoinFullSetup(id)
    end
end

R.On("RUNE_QUEUE_CHANGED", function()
    local state = Apply._state
    if not state or not state.waitingForRunes then return end
    local id = state.id
    if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
        local remaining = #(R.Runes.GetActiveQueue and R.Runes.GetActiveQueue() or {})
        SetStatus(("Engraving… %d left — press the main button once per rune."):format(remaining))
        return
    end
    state.waitingForRunes = nil
    state.runesPhaseDone = true
    state.runesPhaseOk = true
    SetStatus("Runes applied.")
    TryJoinFullSetup(id)
end)

StepBars = function()
    local state = Apply._state
    if not state then return end
    state.phase = "bars"
    local profile = state.profile
    if not SectionOn(profile, "bars") or not profile.bars then
        StepConsumables()
        return
    end
    if R.ActionBars and R.ActionBars.MatchesSnapshot and R.ActionBars.MatchesSnapshot(profile.bars) then
        SetStatus(SkipBarsOnRetail() and "Stance bar layout already matches." or "Action bars already match.")
        StepConsumables()
        return
    end
    -- Retail: Blizzard loadouts own action slots; still apply Flux stance order/hidden.
    if SkipBarsOnRetail() then
        SetStatus("Updating stance bar layout…")
        if R.ActionBars and R.ActionBars.ApplyStanceLayout then
            pcall(R.ActionBars.ApplyStanceLayout, profile.bars)
        elseif R.ActionBars and R.ActionBars.Apply then
            pcall(R.ActionBars.Apply, profile.bars)
        end
        StepConsumables()
        return
    end
    SetStatus("Updating action bar slots that differ from this profile…")
    if R.ActionBars and R.ActionBars.Apply then
        pcall(R.ActionBars.Apply, profile.bars)
    end
    StepConsumables()
end

StepSpellBookSlots = function()
    local state = Apply._state
    if not state then return end
    state.phase = "spellbook"
    local profile = state.profile
    if not SectionOn(profile, "utilitySlots") then
        StepSpellBindings()
        return
    end
    local snap = ResolveProfileUtilitySnap(profile)
    if snap and (_G.FluxNCUtilitySlots_ApplySnapshot or _G.FluxSpellBookSlots_ApplySnapshot) then
        if UtilityMatches(snap) then
            SetStatus("Utility slots already match.")
        else
            SetStatus("Applying utility slot assignments…")
            local ok, reason = UtilityApply(snap)
            if not ok and reason then
                R.Warn("Utility slots: " .. tostring(reason))
            end
        end
    end
    StepSpellBindings()
end

StepSpellBindings = function()
    local state = Apply._state
    if not state then return end
    state.phase = "bindings"
    local profile = state.profile
    if not SectionOn(profile, "spellBindings") or not _G.FluxSpellBindings_ApplySnapshot then
        StepDone()
        return
    end
    local snap = ResolveSpellBindingsSnap(profile)
    if not snap then
        StepDone()
        return
    end
    if _G.FluxSpellBindings_IsLegacySnapshot and _G.FluxSpellBindings_IsLegacySnapshot(snap) then
        R.Warn("Spell bindings were saved with the previous Binding system — re-save this profile to update them.")
        StepDone()
        return
    end
    if _G.FluxSpellBindings_IsV3Snapshot and not _G.FluxSpellBindings_IsV3Snapshot(snap) then
        R.Warn("Spell bindings snapshot is invalid — skipped.")
        StepDone()
        return
    end
    if _G.FluxSpellBindings_MatchesSnapshot and _G.FluxSpellBindings_MatchesSnapshot(snap) then
        SetStatus("Flux spell bindings already match.")
        StepDone()
        return
    end
    if R.SetLoadCheckpoint and state.name then
        R.SetLoadCheckpoint(state.name, "bindings")
    end
    SetStatus("Applying Flux spell bindings and badges…")
    local function afterBindings(ok)
        if not Apply._state or Apply._state ~= state then return end
        state.waitingForBindings = nil
        if ok then
            StepDone()
        else
            R.Warn("Spell bindings could not be applied.")
            SetStatus("Load failed.")
            FinishSuccess()
        end
    end
    local ok, reason = _G.FluxSpellBindings_ApplySnapshot(snap, afterBindings)
    if not ok and (reason == "IN_COMBAT" or reason == "in combat") then
        state.waitingForBindings = true
        R.Print("In combat: spell bindings will be applied after combat ends.")
        return
    end
    if not ok then
        R.Warn("Spell bindings: " .. tostring(reason or "FAILED"))
        StepDone()
    end
end

StepConsumables = function()
    local state = Apply._state
    if not state then return end
    state.phase = "consumables"
    local profile = state.profile
    if SectionOn(profile, "consumables") and profile.consumables and R.Consumables and R.Consumables.Apply then
        if R.Consumables.IsDifferent and not R.Consumables.IsDifferent(profile.consumables) then
            SetStatus("Consumables preset already matches.")
        else
            SetStatus("Switching consumables preset...")
            pcall(R.Consumables.Apply, profile.consumables)
        end
    end
    StepSpellBookSlots()
end

StepDone = function()
    SetStatus("Load complete.")
    FinishSuccess()
end

local function TryAdvanceRuneQueue(name)
    local state = Apply._state
    if not state or state.name ~= name or state.setupJoined then
        return false
    end
    if not (R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue()) then
        return false
    end
    state.waitingForRunes = true
    SetStatus("Engraving next rune...")
    if R.Runes.CastNext then
        R.Runes.CastNext()
    end
    return true
end

function Apply.Run(name)
    if not name or name == "" then
        R.Warn('Select a profile first (or pick "No profile" in the dropdown to clear Respec).')
        return false
    end
    local profile = R.GetProfile(name)
    if not profile then
        R.Warn(("Profile '%s' not found."):format(tostring(name)))
        return false
    end

    if Apply._state and Apply._state.name ~= name
        and (Apply._state.waitingForRunes or (R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue())) then
        Apply.Cancel()
    end

    if Apply._state and Apply._state.name == name and not Apply._state.setupJoined then
        if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
            if TryAdvanceRuneQueue(name) then
                return true
            end
        elseif Apply._state.waitingForRunes
            and not (R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue()) then
            -- Queue just cleared; RUNE_QUEUE_CHANGED may not have fired yet — avoid blocking further clicks.
            return true
        end
    end

    if Apply._state then
        R.Warn("A load is already in progress.")
        return false
    end

    R.GetStore().activeName = name
    if R.Includes and R.Includes.Ensure then
        R.Includes.Ensure(profile)
    end
    R.ApplyInfoFrameForProfile(name)
    R.LinkProfilePresets(profile)
    Apply._state = {
        id   = (tostring(time()) .. "-" .. tostring(math.random(100000))),
        profile = profile,
        name = name,
        willSwitchSpec = (SectionOn(profile, "talents") and profile.talents and R.Talents
            and R.Talents.WouldSwitchSpec and R.Talents.WouldSwitchSpec(profile.talents)) or false,
    }
    R.Fire("APPLY_START", name)
    if R.SetLoadCheckpoint then
        R.SetLoadCheckpoint(name, "parallel")
    end
    SetStatus(("Loading profile '%s'..."):format(name))

    -- FluxNC consumables config: switch active preset to match this profile on the first apply click
    -- (same saved vars as the Consumables UI). StepConsumables still runs at the end if anything differs.
    if SectionOn(profile, "consumables") and profile.consumables and R.Consumables and R.Consumables.Apply then
        pcall(R.Consumables.Apply, profile.consumables)
    end

    if ProfileAlreadyFullyApplied(profile) then
        if R.RunePresets and R.RunePresets.LinkProfilePreset then
            pcall(R.RunePresets.LinkProfilePreset, profile)
        end
        if R.EquipmentPresets and R.EquipmentPresets.LinkProfileEquipmentPreset then
            pcall(R.EquipmentPresets.LinkProfileEquipmentPreset, profile)
        end
        SetStatus("Profile already matches — nothing to apply.")
        FinishSuccess()
        return true
    end

    -- Talents/spec (incl. dual-spec), gear, and runes already match — only bars/consumables left.
    if ProfileParallelSetupComplete(profile) then
        local id = Apply._state.id
        local state = Apply._state
        state.talentsPhaseDone = true
        state.gearPhaseDone = true
        state.runesPhaseDone = true
        state.talentsPhaseOk = true
        state.gearPhaseOk = true
        state.runesPhaseOk = true
        state.setupJoined = false
        SetStatus("Talents, gear, and runes match — applying action bars / consumables...")
        if R.SetLoadCheckpoint then
            R.SetLoadCheckpoint(name, "bars")
        end
        TryJoinFullSetup(id)
        return true
    end

    StepTalentsAndGear()
    return true
end

R.Apply = Apply
