-- FluxRespec_TalentsRetail.lua
-- Retail (post-Dragonflight) talent engine. On retail a profile does NOT store
-- per-talent point trees or action-bar snapshots: talents + hotkey layouts are
-- owned by Blizzard's saved loadout system, so we store a reference to a saved
-- loadout (name + the export string we captured it from) and apply by:
--   1) switching to the target spec if needed,
--   2) waiting until the trait config is stable,
--   3) LoadConfig on the saved loadout whose name matches, or (fallback) replaying
--      the export string via C_Traits.ResetTree + PurchaseRank/SetSelection + CommitConfig
--      (same flow as TalentLoadoutsEx/modules/import.lua).
--
-- This file is loaded BEFORE FluxRespec_Talents.lua so the classic router can
-- delegate to it via Compat.HasTalentLoadouts(). Loads without errors on every
-- client but every entry point is a no-op unless HasTalentLoadouts() is true.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.TalentsRetail = R.TalentsRetail or {}
local TR = R.TalentsRetail
local Compat = R.Compat

-- -----------------------------------------------------------------------------
-- Gate: every public function short-circuits on non-retail clients so this
-- module loading on Classic / Wrath / Cata can never call a missing API.
-- -----------------------------------------------------------------------------

local function Enabled()
    return Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts() == true
end

TR.IsEnabled = Enabled

-- -----------------------------------------------------------------------------
-- Small helpers
-- -----------------------------------------------------------------------------

local function GetCurrentSpecIndex()
    if _G.GetSpecialization then
        local ok, idx = pcall(_G.GetSpecialization)
        if ok and type(idx) == "number" and idx >= 1 then return idx end
    end
    return nil
end

local function GetSpecIDFromIndex(idx)
    if not idx or not _G.GetSpecializationInfo then return nil end
    local ok, specID, name, _, icon = pcall(_G.GetSpecializationInfo, idx)
    if ok and type(specID) == "number" then
        return specID, name, icon
    end
    return nil
end

local function GetCurrentSpecID()
    local idx = GetCurrentSpecIndex()
    if not idx then return nil end
    local id = GetSpecIDFromIndex(idx)
    return id
end

--- Current spec: returns (idx, specID, name, icon). Any field may be nil if the
--- client is still loading spec info (first login frame).
local function GetCurrentSpec()
    local idx = GetCurrentSpecIndex()
    if not idx then return nil end
    if not _G.GetSpecializationInfo then return idx end
    local ok, specID, name, _, icon = pcall(_G.GetSpecializationInfo, idx)
    if not ok then return idx end
    return idx, specID, name, icon
end

--- Returns the specIndex (1..4) that maps to `targetSpecID`, or nil if not found.
local function FindSpecIndexForID(targetSpecID)
    if type(targetSpecID) ~= "number" or not _G.GetNumSpecializations or not _G.GetSpecializationInfo then
        return nil
    end
    local ok, n = pcall(_G.GetNumSpecializations)
    if not ok or type(n) ~= "number" then return nil end
    for i = 1, n do
        local ok2, sid = pcall(_G.GetSpecializationInfo, i)
        if ok2 and sid == targetSpecID then return i end
    end
    return nil
end

local function GetActiveConfigID()
    if _G.C_ClassTalents and _G.C_ClassTalents.GetActiveConfigID then
        local ok, id = pcall(_G.C_ClassTalents.GetActiveConfigID)
        if ok and type(id) == "number" and id > 0 then return id end
    end
    return nil
end

local function GetConfigInfo(configID)
    if not configID or not _G.C_Traits or not _G.C_Traits.GetConfigInfo then return nil end
    local ok, info = pcall(_G.C_Traits.GetConfigInfo, configID)
    if ok and type(info) == "table" then return info end
    return nil
end

local function GetLastSelectedSavedConfigID(specID)
    if not specID or not _G.C_ClassTalents or not _G.C_ClassTalents.GetLastSelectedSavedConfigID then
        return nil
    end
    local ok, id = pcall(_G.C_ClassTalents.GetLastSelectedSavedConfigID, specID)
    if ok and type(id) == "number" and id > 0 then return id end
    return nil
end

local function GetSavedConfigIDsForSpec(specID)
    if not specID or not _G.C_ClassTalents or not _G.C_ClassTalents.GetConfigIDsBySpecID then
        return {}
    end
    local ok, ids = pcall(_G.C_ClassTalents.GetConfigIDsBySpecID, specID)
    if ok and type(ids) == "table" then return ids end
    return {}
end

local function TrimStr(s)
    if type(s) ~= "string" then return "" end
    if _G.strtrim then return strtrim(s) end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function NamesEqual(a, b)
    return TrimStr(a) == TrimStr(b)
end

local function GetSavedConfigIDByName(specID, name)
    if type(name) ~= "string" or name == "" then return nil end
    local ids = GetSavedConfigIDsForSpec(specID)
    for _, cid in ipairs(ids) do
        local info = GetConfigInfo(cid)
        if info and NamesEqual(info.name, name) then
            return cid
        end
    end
    return nil
end

local function GetStarterBuildActive()
    if _G.C_ClassTalents and _G.C_ClassTalents.GetStarterBuildActive then
        local ok, active = pcall(_G.C_ClassTalents.GetStarterBuildActive)
        return ok and active == true
    end
    return false
end

--- Try to make Blizzard_PlayerSpells.TalentsFrame available. Some entry points
--- fire before the player ever opens the talents panel; UIParentLoadAddOn is a
--- no-op if the addon is already loaded.
local function EnsureTalentsFrame()
    local ps = _G.PlayerSpellsFrame
    if ps and ps.TalentsFrame then return ps.TalentsFrame end
    if _G.UIParentLoadAddOn then
        pcall(_G.UIParentLoadAddOn, "Blizzard_PlayerSpells")
    elseif _G.LoadAddOn then
        pcall(_G.LoadAddOn, "Blizzard_PlayerSpells")
    end
    ps = _G.PlayerSpellsFrame
    if ps and ps.TalentsFrame then return ps.TalentsFrame end
    return nil
end

-- -----------------------------------------------------------------------------
-- Export / current tree hash
-- -----------------------------------------------------------------------------

local function GetActiveTreeID(talentsFrame)
    if not talentsFrame or not talentsFrame.GetTreeInfo then return nil end
    local ok, info = pcall(talentsFrame.GetTreeInfo, talentsFrame)
    if ok and type(info) == "table" then return info.ID end
    return nil
end

local function GetActiveTreeHash(talentsFrame)
    local treeID = GetActiveTreeID(talentsFrame)
    if not treeID or not _G.C_Traits or not _G.C_Traits.GetTreeHash then return nil end
    local ok, hash = pcall(_G.C_Traits.GetTreeHash, treeID)
    if not ok then return nil end
    return hash
end

--- Build an export string for the current loadout (same binary format as the
--- default Blizzard export). Returns nil if PlayerSpells isn't loaded or the
--- stream APIs aren't available yet.
local function BuildExportString()
    local tf = EnsureTalentsFrame()
    if not tf or not tf.WriteLoadoutHeader or not tf.WriteLoadoutContent then return nil end
    if not _G.ExportUtil or not _G.ExportUtil.MakeExportDataStream then return nil end

    -- Hidden TalentsFrame can lag C_ClassTalents.GetActiveConfigID() after LoadConfig / commits; export must
    -- reflect the live character or Matches() stays false and the UI keeps asking to "learn" / load.
    local activeID = GetActiveConfigID()
    local frameID
    if tf.GetConfigID then
        local ok, id = pcall(tf.GetConfigID, tf)
        if ok and type(id) == "number" and id > 0 then frameID = id end
    end
    if activeID and frameID ~= activeID then
        if tf.RefreshConfigID then
            pcall(tf.RefreshConfigID, tf)
        elseif tf.SetConfigID then
            pcall(function() tf:SetConfigID(activeID) end)
        end
    end

    local configID = GetActiveConfigID()
    if not configID or configID == 0 then
        if tf.GetConfigID then
            local ok, id = pcall(tf.GetConfigID, tf)
            if ok and type(id) == "number" and id > 0 then configID = id end
        end
    end
    if not configID then return nil end

    local treeInfo
    local ok, info = pcall(tf.GetTreeInfo, tf)
    if ok and type(info) == "table" then treeInfo = info end
    if not treeInfo or not treeInfo.ID then return nil end

    local specID
    if _G.PlayerUtil and _G.PlayerUtil.GetCurrentSpecID then
        local ok2, sid = pcall(_G.PlayerUtil.GetCurrentSpecID)
        if ok2 and type(sid) == "number" then specID = sid end
    end
    specID = specID or GetCurrentSpecID()
    if not specID then return nil end

    local treeHash = GetActiveTreeHash(tf)
    if not treeHash or not _G.C_Traits.GetLoadoutSerializationVersion then return nil end
    local ok3, serializationVersion = pcall(_G.C_Traits.GetLoadoutSerializationVersion)
    if not ok3 or type(serializationVersion) ~= "number" then return nil end

    local stream = _G.ExportUtil.MakeExportDataStream()
    local ok4 = pcall(tf.WriteLoadoutHeader, tf, stream, serializationVersion, specID, treeHash)
    if not ok4 then return nil end
    local ok5 = pcall(tf.WriteLoadoutContent, tf, stream, configID, treeInfo.ID)
    if not ok5 then return nil end
    if not stream.GetExportString then return nil end
    local ok6, s = pcall(stream.GetExportString, stream)
    if ok6 and type(s) == "string" and s ~= "" then return s end
    return nil
end

TR.BuildExportString = BuildExportString

-- -----------------------------------------------------------------------------
-- Capture
-- -----------------------------------------------------------------------------

function TR.Capture()
    if not Enabled() then return nil end
    local _, class = UnitClass("player")
    local specIdx, specID, specName, specIcon = GetCurrentSpec()
    if not specIdx or not specID then
        return nil
    end

    local loadoutName
    local lastID = GetLastSelectedSavedConfigID(specID)
    if lastID then
        local info = GetConfigInfo(lastID)
        if info and type(info.name) == "string" and info.name ~= "" then
            loadoutName = info.name
        end
    end

    local starterBuild = GetStarterBuildActive()
    local noNamedLoadout = not (type(loadoutName) == "string" and loadoutName ~= "")
    local exportString = BuildExportString()
    -- Explicit "spec only" retail profile: no Blizzard saved loadout row, not on starter, no export captured.
    local specOnly = noNamedLoadout and not starterBuild and (not exportString or exportString == "")

    local snap = {
        kind = "loadout",
        class = class,
        specID = specID,
        specIndex = specIdx,
        specName = specName,
        specIcon = specIcon,
        loadoutName = loadoutName,
        starterBuild = starterBuild,
        noNamedLoadout = noNamedLoadout,
        specOnly = specOnly,
        exportString = exportString,
    }

    local tf = _G.PlayerSpellsFrame and _G.PlayerSpellsFrame.TalentsFrame or nil
    snap.configHash = GetActiveTreeHash(tf)

    return snap
end

-- -----------------------------------------------------------------------------
-- Compare
-- -----------------------------------------------------------------------------

local function CurrentExportString()
    local tf = EnsureTalentsFrame()
    if not tf then return nil end
    return BuildExportString()
end

-- After a successful Apply, APIs + PlayerSpells can lag; treat as matched briefly so UI clears.
local matchGraceUntil = nil
local matchGraceKey = nil

local function BuildMatchGraceKey(snapshot)
    if type(snapshot) ~= "table" or snapshot.kind ~= "loadout" then return nil end
    return string.format(
        "%d|%s|%s",
        tonumber(snapshot.specID) or 0,
        TrimStr(snapshot.loadoutName or ""),
        snapshot.starterBuild and "1" or "0"
    )
end

local function SetMatchGraceFromSnapshot(snapshot)
    local key = BuildMatchGraceKey(snapshot)
    if not key then return end
    matchGraceKey = key
    matchGraceUntil = (GetTime and GetTime() or 0) + 2.5
end

local function ClearMatchGrace()
    matchGraceKey = nil
    matchGraceUntil = nil
end

--- True when the live character already matches this snapshot (same spec AND
--- either the last-selected saved loadout name matches, or the current tree
--- export equals the snapshot's export string).
function TR.Matches(snapshot)
    if not Enabled() then return true end
    if type(snapshot) ~= "table" or snapshot.kind ~= "loadout" then return false end
    local _, class = UnitClass("player")
    if snapshot.class and class and snapshot.class ~= class then return false end

    local curSpec = GetCurrentSpecID()
    if not curSpec or curSpec ~= snapshot.specID then return false end

    local gKey = BuildMatchGraceKey(snapshot)
    if gKey and matchGraceKey == gKey and matchGraceUntil
        and (GetTime and GetTime() or 0) <= matchGraceUntil then
        return true
    end

    local liveStarter = GetStarterBuildActive()

    -- Fast path: active trait config display name matches saved loadout name (handles post–LoadConfig timing).
    if type(snapshot.loadoutName) == "string" and snapshot.loadoutName ~= "" then
        local active = GetActiveConfigID()
        if active then
            local ainfo = GetConfigInfo(active)
            if ainfo and NamesEqual(ainfo.name, snapshot.loadoutName) then
                return true
            end
        end
    end

    -- Explicit starter-build profile (saved while using Blizzard's starter build).
    if snapshot.starterBuild == true then
        if not liveStarter then
            return false
        end
        if type(snapshot.exportString) == "string" and snapshot.exportString ~= "" then
            local cur = CurrentExportString()
            return cur ~= nil and cur == snapshot.exportString
        end
        return true
    end

    -- Saved profile expects a normal saved loadout / import; still on starter → not a match.
    if snapshot.starterBuild == false and liveStarter then
        return false
    end

    if type(snapshot.loadoutName) == "string" and snapshot.loadoutName ~= "" then
        -- Prefer active config ID vs the saved loadout row: GetLastSelectedSavedConfigID can lag one frame
        -- after LoadConfig; comparing to GetActiveConfigID() matches what the player actually has equipped.
        local namedID = GetSavedConfigIDByName(curSpec, snapshot.loadoutName)
        if namedID then
            local active = GetActiveConfigID()
            if active and active == namedID then
                return true
            end
        end
        local lastID = GetLastSelectedSavedConfigID(curSpec)
        if lastID then
            local info = GetConfigInfo(lastID)
            if info and NamesEqual(info.name, snapshot.loadoutName) then
                return true
            end
        end
    end

    if type(snapshot.exportString) == "string" and snapshot.exportString ~= "" then
        EnsureTalentsFrame()
        local cur = CurrentExportString()
        if cur and cur == snapshot.exportString then
            return true
        end
    end

    -- Spec-only / "no saved loadout" rows: same spec and same mode (not on starter when profile wasn't starter).
    if snapshot.starterBuild ~= true
        and (snapshot.specOnly == true or snapshot.noNamedLoadout == true)
        and (not snapshot.exportString or snapshot.exportString == "") then
        return not liveStarter
    end

    -- Treat an unverified loadout as a mismatch even when the spec matches.
    -- so Apply actually runs LoadConfig / replay. If both name and string are
    -- missing, accept the spec match to avoid retrying indefinitely.
    if (not snapshot.loadoutName or snapshot.loadoutName == "")
        and (not snapshot.exportString or snapshot.exportString == "") then
        return true
    end
    return false
end

function TR.WouldSwitchSpec(snapshot)
    if not Enabled() then return false end
    if type(snapshot) ~= "table" then return false end
    local cur = GetCurrentSpecID()
    return cur ~= nil and snapshot.specID ~= nil and cur ~= snapshot.specID
end

-- -----------------------------------------------------------------------------
-- Apply: spec switch -> LoadConfig by name, else replay export string.
-- -----------------------------------------------------------------------------

local applyCancelGen = 0

local applyState = nil

local function ClearApplyWatchers()
    if not applyState then return end
    if applyState.specFrame then
        applyState.specFrame:UnregisterAllEvents()
        applyState.specFrame:SetScript("OnEvent", nil)
    end
    if applyState.configFrame then
        applyState.configFrame:UnregisterAllEvents()
        applyState.configFrame:SetScript("OnEvent", nil)
    end
    if applyState.specTimer and applyState.specTimer.Cancel then
        pcall(function() applyState.specTimer:Cancel() end)
    end
    if applyState.configTimer and applyState.configTimer.Cancel then
        pcall(function() applyState.configTimer:Cancel() end)
    end
    if applyState.commitTicker and applyState.commitTicker.Cancel then
        pcall(function() applyState.commitTicker:Cancel() end)
    end
    applyState.specFrame = nil
    applyState.configFrame = nil
    applyState.specTimer = nil
    applyState.configTimer = nil
    applyState.commitTicker = nil
end

function TR.AbortApply()
    applyCancelGen = applyCancelGen + 1
    ClearApplyWatchers()
    applyState = nil
    ClearMatchGrace()
end

local function FinishApply(ok, reason)
    local state = applyState
    local done = state and state.done
    ClearApplyWatchers()
    applyState = nil
    if done then pcall(done, ok, reason) end
end

--- Run `fn` shortly after `TRAIT_CONFIG_UPDATED` fires for the active config,
--- or after a short timeout, whichever comes first. Used to wait for the trait
--- system to settle after a spec switch / starter-build toggle before we
--- mutate the tree.
--- Retail uses C_SpecializationInfo.SetSpecialization; the global SetSpecialization
--- helper is not present on current Mainline clients.
local function TrySetPlayerSpecialization(specIndex)
    if type(specIndex) ~= "number" or specIndex < 1 then
        return false
    end
    local CSI = _G.C_SpecializationInfo
    if CSI and CSI.SetSpecialization then
        local ok, accepted = pcall(CSI.SetSpecialization, specIndex)
        if ok and accepted ~= false then
            return true
        end
        if not ok then
            return false
        end
        -- accepted == false: denied (e.g. in combat) — do not fall through to a missing global.
        return false
    end
    if _G.SetSpecialization then
        local ok, ret = pcall(_G.SetSpecialization, specIndex)
        return ok and ret ~= false
    end
    return false
end

local function WaitForTraitConfigStable(expectedConfigID, myGen, fn)
    if not fn then return end
    local f = CreateFrame("Frame")
    applyState = applyState or {}
    applyState.configFrame = f
    local settled = false
    local function resolve()
        if settled then return end
        settled = true
        if applyState and applyState.configFrame == f then
            f:UnregisterAllEvents()
            f:SetScript("OnEvent", nil)
            applyState.configFrame = nil
        else
            f:UnregisterAllEvents()
            f:SetScript("OnEvent", nil)
        end
        if applyState and applyState.configTimer and applyState.configTimer.Cancel then
            pcall(function() applyState.configTimer:Cancel() end)
            applyState.configTimer = nil
        end
        if myGen ~= applyCancelGen then return end
        fn()
    end
    f:RegisterEvent("TRAIT_CONFIG_UPDATED")
    f:SetScript("OnEvent", function(_, _, updatedID)
        if expectedConfigID and updatedID and updatedID ~= expectedConfigID then
            return
        end
        resolve()
    end)
    -- Cap wait: trait config usually updates within a few frames; 1s felt like "lag" after casts.
    if _G.C_Timer and _G.C_Timer.NewTimer then
        applyState.configTimer = _G.C_Timer.NewTimer(0.35, resolve)
    else
        resolve()
    end
end

--- Turn off starter build before applying a normal saved loadout / spec-only snapshot.
local function EnsureStarterOff(myGen, onDone)
    if not GetStarterBuildActive() then
        onDone()
        return
    end
    if _G.C_ClassTalents and _G.C_ClassTalents.SetStarterBuildActive then
        pcall(_G.C_ClassTalents.SetStarterBuildActive, false)
        WaitForTraitConfigStable(GetActiveConfigID(), myGen, onDone)
    else
        onDone()
    end
end

local function SwitchSpecThen(targetIdx, myGen, fn)
    local hasApi = (_G.C_SpecializationInfo and _G.C_SpecializationInfo.SetSpecialization) or _G.SetSpecialization
    if not hasApi then
        fn(false, "NO_SPEC_API")
        return
    end
    if not TrySetPlayerSpecialization(targetIdx) then
        fn(false, "SPEC_CALL_FAILED")
        return
    end
    local f = CreateFrame("Frame")
    applyState = applyState or {}
    applyState.specFrame = f
    local settled = false
    local function resolve(okSwitch, reason)
        if settled then return end
        settled = true
        if applyState and applyState.specFrame == f then
            f:UnregisterAllEvents()
            f:SetScript("OnEvent", nil)
            applyState.specFrame = nil
        else
            f:UnregisterAllEvents()
            f:SetScript("OnEvent", nil)
        end
        if applyState and applyState.specTimer and applyState.specTimer.Cancel then
            pcall(function() applyState.specTimer:Cancel() end)
            applyState.specTimer = nil
        end
        if myGen ~= applyCancelGen then return end
        fn(okSwitch, reason)
    end
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    f:SetScript("OnEvent", function()
        local curIdx = GetCurrentSpecIndex()
        if curIdx == targetIdx then
            -- Wait one more trait-config tick so GetActiveConfigID is valid.
            WaitForTraitConfigStable(nil, myGen, function()
                resolve(true, "SPEC_SWITCHED")
            end)
        end
    end)
    if _G.C_Timer and _G.C_Timer.After then
        applyState.specTimer = _G.C_Timer.NewTimer(10, function()
            resolve(false, "SPEC_SWITCH_TIMEOUT")
        end)
    end
end

local function ApplyButtonEnabled()
    local tf = _G.PlayerSpellsFrame and _G.PlayerSpellsFrame.TalentsFrame
    if not tf or not tf.ApplyButton then return true end -- if no button exists, commit path may still work
    local ab = tf.ApplyButton
    local shown = ab.IsShown and ab:IsShown()
    local enabled = ab.IsEnabled and ab:IsEnabled()
    if shown == false then return false end
    if enabled == false then return false end
    return true
end

local function CommitIfPossible(configID, myGen, onDone)
    if not configID then onDone(true, "DONE"); return end
    -- If the current tree already matches the import, the import path committed directly.
    -- Otherwise wait briefly for the apply button to enable (mirrors TalentLoadoutsEx /tlx).
    if not _G.C_Traits or not _G.C_Traits.CommitConfig then
        onDone(true, "DONE")
        return
    end
    local tries = 0
    local maxTries = 6
    local function attempt()
        if myGen ~= applyCancelGen then return end
        tries = tries + 1
        if ApplyButtonEnabled() or tries >= maxTries then
            pcall(_G.C_Traits.CommitConfig, configID)
            onDone(true, "DONE")
            return
        end
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0.05, attempt)
        else
            onDone(true, "DONE")
        end
    end
    attempt()
end

local function ReplayExportString(importText, configID, myGen, onDone, opts)
    opts = opts or {}
    if type(importText) ~= "string" or importText == "" then
        onDone(false, "NO_IMPORT_STRING")
        return
    end
    local tf = EnsureTalentsFrame()
    if not tf then
        onDone(false, "NO_TALENTS_FRAME")
        return
    end
    if not _G.ExportUtil or not _G.ExportUtil.MakeImportDataStream then
        onDone(false, "NO_IMPORT_API")
        return
    end
    if not _G.C_Traits then
        onDone(false, "NO_TRAITS_API")
        return
    end
    configID = configID or GetActiveConfigID()
    if not configID then
        onDone(false, "NO_CONFIG_ID")
        return
    end

    -- Disable Starter Build before ResetTree / PurchaseRank unless applying a starter snapshot.
    if not opts.starterProfile and _G.C_ClassTalents and _G.C_ClassTalents.GetStarterBuildActive then
        local ok, active = pcall(_G.C_ClassTalents.GetStarterBuildActive)
        if ok and active then
            if _G.C_ClassTalents.SetStarterBuildActive then
                pcall(_G.C_ClassTalents.SetStarterBuildActive, false)
            end
            WaitForTraitConfigStable(configID, myGen, function()
                ReplayExportString(importText, configID, myGen, onDone, opts)
            end)
            return
        end
    end

    local treeInfo
    if tf.GetTreeInfo then
        local ok, info = pcall(tf.GetTreeInfo, tf)
        if ok and type(info) == "table" then treeInfo = info end
    end
    if not treeInfo or not treeInfo.ID then
        onDone(false, "NO_TREE_INFO")
        return
    end

    local stream = _G.ExportUtil.MakeImportDataStream(importText)
    -- Consume the header so the reader is positioned at the content.
    if not tf.ReadLoadoutHeader or not tf.ReadLoadoutContent or not tf.ConvertToImportLoadoutEntryInfo then
        onDone(false, "NO_IMPORT_READER")
        return
    end
    local ok1 = pcall(tf.ReadLoadoutHeader, tf, stream)
    if not ok1 then
        onDone(false, "BAD_IMPORT_HEADER")
        return
    end
    local ok2, content = pcall(tf.ReadLoadoutContent, tf, stream, treeInfo.ID)
    if not ok2 or type(content) ~= "table" then
        onDone(false, "BAD_IMPORT_CONTENT")
        return
    end

    local specID = GetCurrentSpecID()
    local ok3, entries = pcall(tf.ConvertToImportLoadoutEntryInfo, tf, specID, configID, treeInfo.ID, content)
    if not ok3 or type(entries) ~= "table" then
        -- Some builds pass (configID, treeID, loadoutContent). Retry the other signature.
        ok3, entries = pcall(tf.ConvertToImportLoadoutEntryInfo, tf, configID, treeInfo.ID, content)
        if not ok3 or type(entries) ~= "table" then
            onDone(false, "CONVERT_FAILED")
            return
        end
    end

    if _G.C_Traits.ResetTree then
        pcall(_G.C_Traits.ResetTree, configID, treeInfo.ID)
    end

    for _, entry in ipairs(entries) do
        local nodeID = entry.nodeID
        if nodeID then
            local nodeInfo
            if _G.C_Traits.GetNodeInfo then
                local okN, ni = pcall(_G.C_Traits.GetNodeInfo, configID, nodeID)
                if okN then nodeInfo = ni end
            end
            local nodeType = nodeInfo and nodeInfo.type
            if nodeType == (Enum and Enum.TraitNodeType and Enum.TraitNodeType.Single)
                or nodeType == (Enum and Enum.TraitNodeType and Enum.TraitNodeType.Tiered)
                or entry.ranksPurchased then
                for _ = 1, (entry.ranksPurchased or 0) do
                    if _G.C_Traits.PurchaseRank then
                        pcall(_G.C_Traits.PurchaseRank, configID, nodeID)
                    end
                end
            else
                if entry.selectionEntryID and _G.C_Traits.SetSelection then
                    pcall(_G.C_Traits.SetSelection, configID, nodeID, entry.selectionEntryID)
                end
            end
        end
    end

    CommitIfPossible(configID, myGen, onDone)
end

--- Apply a profile saved on the Blizzard starter build (optional export for the starter tree).
local function ApplyStarterBuild(snapshot, myGen, onDone)
    if not (_G.C_ClassTalents and _G.C_ClassTalents.SetStarterBuildActive) then
        if type(snapshot.exportString) == "string" and snapshot.exportString ~= "" then
            ReplayExportString(snapshot.exportString, GetActiveConfigID(), myGen, onDone)
        else
            onDone(false, "NO_STARTER_API")
        end
        return
    end
    pcall(_G.C_ClassTalents.SetStarterBuildActive, true)
    WaitForTraitConfigStable(nil, myGen, function()
        if myGen ~= applyCancelGen then return end
        if type(snapshot.exportString) == "string" and snapshot.exportString ~= "" then
            ReplayExportString(snapshot.exportString, GetActiveConfigID(), myGen, onDone, { starterProfile = true })
        else
            CommitIfPossible(GetActiveConfigID(), myGen, onDone)
        end
    end)
end

local function DoLoadConfig(configID, specID, myGen, onDone)
    if not _G.C_ClassTalents or not _G.C_ClassTalents.LoadConfig then
        onDone(false, "NO_LOAD_CONFIG_API")
        return
    end
    pcall(_G.C_ClassTalents.LoadConfig, configID, true)
    if _G.C_ClassTalents.UpdateLastSelectedSavedConfigID then
        pcall(_G.C_ClassTalents.UpdateLastSelectedSavedConfigID, specID, configID)
    end
    -- Blizzard's LoadConfig returns a status but we treat any dispatch as success;
    -- CommitIfPossible still waits for the Apply button when changes are pending.
    CommitIfPossible(GetActiveConfigID(), myGen, onDone)
end

local function ApplyAfterSpecReady(snapshot, myGen, onDone)
    if myGen ~= applyCancelGen then return end
    local specID = snapshot.specID

    if snapshot.starterBuild == true then
        ApplyStarterBuild(snapshot, myGen, onDone)
        return
    end

    -- Named Blizzard saved loadout row.
    if type(snapshot.loadoutName) == "string" and snapshot.loadoutName ~= "" then
        local cid = GetSavedConfigIDByName(specID, snapshot.loadoutName)
        if cid then
            EnsureStarterOff(myGen, function()
                if myGen ~= applyCancelGen then return end
                DoLoadConfig(cid, specID, myGen, onDone)
            end)
            return
        end
    end

    if type(snapshot.exportString) == "string" and snapshot.exportString ~= "" then
        EnsureStarterOff(myGen, function()
            if myGen ~= applyCancelGen then return end
            ReplayExportString(snapshot.exportString, GetActiveConfigID(), myGen, onDone)
        end)
        return
    end

    -- Spec-only / explicitly "no saved loadout" snapshot: spec switch (if any) is enough; clear starter if needed.
    if snapshot.starterBuild ~= true
        and (snapshot.specOnly == true or snapshot.noNamedLoadout == true) then
        EnsureStarterOff(myGen, function()
            if myGen ~= applyCancelGen then return end
            onDone(true, "DONE")
        end)
        return
    end

    onDone(false, "NO_LOADOUT")
end

--- Apply a retail loadout snapshot.
--- onDone(ok, reason) reasons: "NOOP" | "DONE" | "WRONG_CLASS" | "IN_COMBAT" |
--- "SPEC_SWITCH_TIMEOUT" | "NO_LOADOUT" | "NO_LOAD_CONFIG_API" | "NO_IMPORT_*" | "NO_SPEC_API"
function TR.Apply(snapshot, onDone)
    -- Tear down any watchers from a previous Apply so the new spec/config listeners own the state.
    ClearApplyWatchers()
    applyState = nil
    applyCancelGen = applyCancelGen + 1
    local myGen = applyCancelGen

    local function done(ok, reason)
        if myGen ~= applyCancelGen then return end
        if ok then
            SetMatchGraceFromSnapshot(snapshot)
        else
            ClearMatchGrace()
        end
        if onDone then pcall(onDone, ok, reason) end
        R.Fire("TALENTS_APPLIED", ok, reason)
    end

    if not Enabled() then
        done(true, "NOOP")
        return
    end

    if type(snapshot) ~= "table" or snapshot.kind ~= "loadout" then
        done(true, "NOOP")
        return
    end

    local _, class = UnitClass("player")
    if snapshot.class and snapshot.class ~= class then
        R.Warn(("Talent profile is for %s, not your class (%s)."):format(snapshot.class, class))
        done(false, "WRONG_CLASS")
        return
    end

    if InCombatLockdown() then
        R.Warn("Can't change talents in combat.")
        done(false, "IN_COMBAT")
        return
    end

    if TR.Matches(snapshot) then
        done(true, "NOOP")
        return
    end

    applyState = { done = done }

    local curSpecID = GetCurrentSpecID()
    if snapshot.specID and curSpecID ~= snapshot.specID then
        local targetIdx = snapshot.specIndex
        if not targetIdx or targetIdx < 1 then
            targetIdx = FindSpecIndexForID(snapshot.specID)
        end
        if not targetIdx then
            done(false, "NO_SPEC_INDEX")
            return
        end
        SwitchSpecThen(targetIdx, myGen, function(okSwitch, reason)
            if not okSwitch then
                done(false, reason or "SPEC_SWITCH_TIMEOUT")
                return
            end
            ApplyAfterSpecReady(snapshot, myGen, done)
        end)
        return
    end

    ApplyAfterSpecReady(snapshot, myGen, done)
end

-- -----------------------------------------------------------------------------
-- UI / summary helpers
-- -----------------------------------------------------------------------------

function TR.SpecIconFromSnapshot(snapshot)
    if type(snapshot) ~= "table" then return nil end
    if snapshot.specIcon and snapshot.specIcon ~= "" and snapshot.specIcon ~= 0 then
        return snapshot.specIcon
    end
    if snapshot.specID and _G.GetSpecializationInfoByID then
        local ok, _, _, _, icon = pcall(_G.GetSpecializationInfoByID, snapshot.specID)
        if ok and icon and icon ~= 0 then return icon end
    end
    return nil
end

function TR.LiveSummaryForUI()
    local idx, specID, specName, specIcon = GetCurrentSpec()
    if not idx then
        return "No spec", "[live]", nil
    end
    if GetStarterBuildActive() then
        return ("%s — Starter build"):format(specName or "Spec"), "[live]", specIcon
    end
    local loadoutName
    local lastID = GetLastSelectedSavedConfigID(specID)
    if lastID then
        local info = GetConfigInfo(lastID)
        if info and type(info.name) == "string" and info.name ~= "" then
            loadoutName = info.name
        end
    end
    local text
    if loadoutName then
        text = ("%s — %s"):format(specName or "Spec", loadoutName)
    else
        text = ("%s — No saved loadout"):format(specName or "Spec")
    end
    return text, "[live]", specIcon
end

--- Retail has no dual-spec / talent group concept; this always accepts.
function TR.CanApplyWithoutTrainerReset(_)
    return true
end

--- Retail has no talent groups; Apply path targets the active config directly.
function TR.FindMatchingGroupIndex(snapshot)
    if TR.Matches(snapshot) then return 1 end
    return nil
end

--- Dual-spec swap is meaningless on retail (use SetSpecialization via Apply instead).
function TR.ToggleDualSpecGroup()
    return false
end

--- UI row wants a compact `(text, tag, icon)` tuple for a saved snapshot.
function TR.Summary(snapshot)
    if type(snapshot) ~= "table" or snapshot.kind ~= "loadout" then
        return nil
    end
    local text
    if snapshot.starterBuild == true then
        text = ("%s — Starter build"):format(snapshot.specName or "Spec")
    elseif snapshot.loadoutName and snapshot.loadoutName ~= "" then
        text = ("%s — %s"):format(snapshot.specName or "Spec", snapshot.loadoutName)
    elseif snapshot.noNamedLoadout == true or snapshot.specOnly == true then
        text = ("%s — No saved loadout"):format(snapshot.specName or "Spec")
    else
        text = snapshot.specName or "Spec"
    end
    local tag
    if TR.Matches(snapshot) then
        tag = "[matches]"
    elseif TR.WouldSwitchSpec(snapshot) then
        tag = "[other spec]"
    elseif type(snapshot.loadoutName) == "string" and snapshot.loadoutName ~= ""
        and not GetSavedConfigIDByName(snapshot.specID, snapshot.loadoutName)
        and (not snapshot.exportString or snapshot.exportString == "") then
        tag = "[loadout missing]"
    else
        tag = "[needs load]"
    end
    return text, tag, TR.SpecIconFromSnapshot(snapshot)
end

R.TalentsRetail = TR
