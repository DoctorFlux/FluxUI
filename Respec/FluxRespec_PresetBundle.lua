-- FluxRespec_PresetBundle.lua
-- Per dual-spec talent group save/apply for action bars and utility slots
-- (legacy field names: spellBookSlots / spellBookSlotsByGroup).
-- stored inside rune presets (and full respec profiles).
-- Action bars in rune presets are tagged with the talent tree snapshot at save time,
-- not merely "Spec 1" / "Spec 2".

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.PresetBundle = R.PresetBundle or {}
local Bundle = R.PresetBundle
local Compat = R.Compat

function Bundle.GetActiveGroup()
    if Compat and Compat.GetActiveGroup then
        local g = Compat.GetActiveGroup()
        if type(g) == "number" and g >= 1 then
            return g
        end
    end
    return 1
end

function Bundle.GroupLabel(group)
    group = group or Bundle.GetActiveGroup()
    local n = (Compat and Compat.GetNumGroups and Compat.GetNumGroups()) or 1
    if type(n) == "number" and n >= 2 then
        return ("Spec %d"):format(group)
    end
    return nil
end

function Bundle.SkipBarsOnClient()
    return Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts()
end

function Bundle.MigrateLegacyBars(preset)
    if type(preset) ~= "table" then return end
    if preset.bars and type(preset.bars) == "table" and type(preset.barsByGroup) ~= "table" then
        preset.barsByGroup = { [1] = preset.bars }
        preset.bars = nil
    end
    if type(preset.barsByGroup) ~= "table" then
        preset.barsByGroup = {}
    end
end

function Bundle.MigrateLegacyBarsTalent(preset)
    if type(preset) ~= "table" then return end
    if type(preset.barsTalentByGroup) ~= "table" then
        preset.barsTalentByGroup = {}
    end
end

function Bundle.MigrateLegacySpellBook(preset)
    if type(preset) ~= "table" then return end
    -- Flat legacy → per-group
    if preset.utilitySlots and type(preset.utilitySlots) == "table"
        and type(preset.utilitySlotsByGroup) ~= "table"
        and type(preset.spellBookSlotsByGroup) ~= "table" then
        preset.utilitySlotsByGroup = { [1] = preset.utilitySlots }
        preset.utilitySlots = nil
    end
    if preset.spellBookSlots and type(preset.spellBookSlots) == "table"
        and type(preset.spellBookSlotsByGroup) ~= "table"
        and type(preset.utilitySlotsByGroup) ~= "table" then
        preset.spellBookSlotsByGroup = { [1] = preset.spellBookSlots }
        preset.spellBookSlots = nil
    end
    if type(preset.utilitySlotsByGroup) ~= "table" then
        preset.utilitySlotsByGroup = {}
    end
    if type(preset.spellBookSlotsByGroup) ~= "table" then
        preset.spellBookSlotsByGroup = {}
    end
    -- Mirror legacy group table into utilitySlotsByGroup when only spellBook* exists.
    for g, snap in pairs(preset.spellBookSlotsByGroup) do
        if snap and preset.utilitySlotsByGroup[g] == nil then
            preset.utilitySlotsByGroup[g] = snap
        end
    end
end

function Bundle.MigratePreset(preset)
    Bundle.MigrateLegacyBars(preset)
    Bundle.MigrateLegacyBarsTalent(preset)
    Bundle.MigrateLegacySpellBook(preset)
end

local function CaptureUtilitySnap()
    if _G.FluxNCUtilitySlots_CaptureSnapshot then
        return _G.FluxNCUtilitySlots_CaptureSnapshot()
    end
    if _G.FluxSpellBookSlots_CaptureSnapshot then
        return _G.FluxSpellBookSlots_CaptureSnapshot()
    end
    return nil
end

local function ApplyUtilitySnap(snap)
    if not snap then return false end
    if _G.FluxNCUtilitySlots_ApplySnapshot then
        return pcall(_G.FluxNCUtilitySlots_ApplySnapshot, snap) == true
    end
    if _G.FluxSpellBookSlots_ApplySnapshot then
        return pcall(_G.FluxSpellBookSlots_ApplySnapshot, snap) == true
    end
    return false
end

local function ResolveUtilitySnapForGroup(preset, group)
    if type(preset) ~= "table" then return nil end
    Bundle.MigrateLegacySpellBook(preset)
    return (preset.utilitySlotsByGroup and preset.utilitySlotsByGroup[group])
        or (preset.spellBookSlotsByGroup and preset.spellBookSlotsByGroup[group])
end

function Bundle.CaptureTalentSnapshot()
    if R.Talents and R.Talents.Capture then
        return R.Talents.Capture()
    end
    return nil
end

function Bundle.TalentTreeLabel(snapshot)
    if type(snapshot) ~= "table" then
        return "talent tree"
    end
    if snapshot.kind == "loadout" and R.TalentsRetail and R.TalentsRetail.Summary then
        local text = R.TalentsRetail.Summary(snapshot)
        if type(text) == "string" and text ~= "" then
            return text
        end
        return "loadout"
    end
    if type(snapshot.points) == "table" then
        local totals = {}
        for tab, tree in pairs(snapshot.points) do
            local s = 0
            for _, rank in pairs(tree) do
                s = s + (tonumber(rank) or 0)
            end
            totals[tab] = s
        end
        return string.format("%d/%d/%d", totals[1] or 0, totals[2] or 0, totals[3] or 0)
    end
    return "talent tree"
end

function Bundle.PresetHasAnyBars(preset)
    if type(preset) ~= "table" then return false end
    Bundle.MigrateLegacyBars(preset)
    for _, bars in pairs(preset.barsByGroup or {}) do
        if type(bars) == "table" then
            return true
        end
    end
    return false
end

--- True when any saved bars bundle's talent tree exists on spec 1 or spec 2 (legacy bars without talent snap count as ok).
function Bundle.PresetBarsTalentMatchesAnySpec(preset)
    if type(preset) ~= "table" then return false end
    if Bundle.SkipBarsOnClient() then return true end
    Bundle.MigratePreset(preset)
    local n = (Compat and Compat.GetNumGroups and Compat.GetNumGroups()) or 1
    for g = 1, n do
        local bars = preset.barsByGroup and preset.barsByGroup[g]
        local talents = preset.barsTalentByGroup and preset.barsTalentByGroup[g]
        if bars then
            if not talents then
                return true
            end
            if R.Talents and R.Talents.FindMatchingGroupIndex and R.Talents.FindMatchingGroupIndex(talents) then
                return true
            end
        end
    end
    return false
end

--- Pick bars to apply: auto when active or either spec matches saved talent tree; confirm when none match.
--- Returns bars, talentSnap, mode ("auto"|"confirm"|"skip"), sourceGroup.
function Bundle.ResolveBarsBundleForPreset(preset)
    if type(preset) ~= "table" then
        return nil, nil, "skip", nil
    end
    if Bundle.SkipBarsOnClient() then
        return nil, nil, "skip", nil
    end
    Bundle.MigratePreset(preset)
    local activeG = Bundle.GetActiveGroup()
    local n = (Compat and Compat.GetNumGroups and Compat.GetNumGroups()) or 1

    for g = 1, n do
        local bars = preset.barsByGroup and preset.barsByGroup[g]
        local talents = preset.barsTalentByGroup and preset.barsTalentByGroup[g]
        if bars and talents and R.Talents and R.Talents.Matches and R.Talents.Matches(talents, activeG) then
            return bars, talents, "auto", g
        end
    end

    for g = 1, n do
        local bars = preset.barsByGroup and preset.barsByGroup[g]
        local talents = preset.barsTalentByGroup and preset.barsTalentByGroup[g]
        if bars and talents and R.Talents and R.Talents.FindMatchingGroupIndex then
            local matchG = R.Talents.FindMatchingGroupIndex(talents)
            if matchG then
                return bars, talents, "auto", g
            end
        end
    end

    if preset.barsByGroup and preset.barsByGroup[activeG]
        and not (preset.barsTalentByGroup and preset.barsTalentByGroup[activeG]) then
        return preset.barsByGroup[activeG], nil, "auto", activeG
    end

    for g = 1, n do
        local bars = preset.barsByGroup and preset.barsByGroup[g]
        if bars then
            local talents = preset.barsTalentByGroup and preset.barsTalentByGroup[g]
            return bars, talents, "confirm", g
        end
    end

    return nil, nil, "skip", nil
end

--- Best talent snapshot associated with this preset's saved action bars (for spec-switch on load).
function Bundle.GetPrimaryTalentSnapshotForPreset(preset)
    if type(preset) ~= "table" then
        return nil
    end
    Bundle.MigratePreset(preset)
    local talents = select(2, Bundle.ResolveBarsBundleForPreset(preset))
    if talents then
        return talents
    end
    local n = (Compat and Compat.GetNumGroups and Compat.GetNumGroups()) or 1
    for g = 1, n do
        local t = preset.barsTalentByGroup and preset.barsTalentByGroup[g]
        if t then
            return t
        end
    end
    return nil
end

function Bundle.ApplyBarsSnapshot(bars)
    if type(bars) ~= "table" then return false end
    if R.ActionBars and R.ActionBars.Apply then
        return pcall(R.ActionBars.Apply, bars) == true
    end
    return false
end

function Bundle.SaveBarsForActiveGroup(preset)
    if type(preset) ~= "table" then return false end
    if Bundle.SkipBarsOnClient() then return false end
    if not R.ActionBars or not R.ActionBars.Capture then return false end
    Bundle.MigratePreset(preset)
    local group = Bundle.GetActiveGroup()
    preset.barsByGroup[group] = R.ActionBars.Capture()
    preset.barsTalentByGroup[group] = Bundle.CaptureTalentSnapshot()
    return true
end

function Bundle.ApplyBarsForActiveGroup(preset)
    if type(preset) ~= "table" then return false end
    if Bundle.SkipBarsOnClient() then return false end
    local bars = select(1, Bundle.ResolveBarsBundleForPreset(preset))
    if not bars then return false end
    return Bundle.ApplyBarsSnapshot(bars)
end

function Bundle.HasBarsForActiveGroup(preset)
    if type(preset) ~= "table" then return false end
    if Bundle.SkipBarsOnClient() then return false end
    local bars = select(1, Bundle.ResolveBarsBundleForPreset(preset))
    return bars ~= nil
end

function Bundle.SaveSpellBookForActiveGroup(preset)
    if type(preset) ~= "table" then return false end
    local snap = CaptureUtilitySnap()
    if not snap then return false end
    Bundle.MigrateLegacySpellBook(preset)
    local group = Bundle.GetActiveGroup()
    preset.utilitySlotsByGroup[group] = snap
    -- Keep legacy key in sync for older preset readers.
    preset.spellBookSlotsByGroup[group] = snap
    return true
end

function Bundle.ApplySpellBookForActiveGroup(preset)
    if type(preset) ~= "table" then return false end
    Bundle.MigrateLegacySpellBook(preset)
    local group = Bundle.GetActiveGroup()
    local snap = ResolveUtilitySnapForGroup(preset, group)
    if not snap then return false end
    return ApplyUtilitySnap(snap)
end

function Bundle.HasSpellBookForActiveGroup(preset)
    if type(preset) ~= "table" then return false end
    Bundle.MigrateLegacySpellBook(preset)
    local group = Bundle.GetActiveGroup()
    return ResolveUtilitySnapForGroup(preset, group) ~= nil
end

--- Human-readable suffix for save messages, e.g. "(31/0/20 action bars & utility slots)".
function Bundle.SaveSuffixForActiveGroup(includeSpellBook, talentSnap)
    talentSnap = talentSnap or Bundle.CaptureTalentSnapshot()
    local label = Bundle.TalentTreeLabel(talentSnap)
    if not label or label == "" then
        return ""
    end
    if includeSpellBook then
        return (" (%s action bars & utility slots)"):format(label)
    end
    return (" (%s action bars)"):format(label)
end

R.PresetBundle = Bundle
