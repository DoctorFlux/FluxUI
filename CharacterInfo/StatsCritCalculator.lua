-- Shared crit calculator: Blizzard APIs + talent overlays + explicit registry supplements.
-- Classic/Progression: trust GetCritChance / GetSpellCritChance for buffs and gear (same as
-- CharacterStatsClassic/TBC). Only CRIT_AURA_REGISTRY entries supplement known API gaps.
-- Loaded on all supported clients (Era, TBC/Wrath, Retail).
local _, ns = ...
local module = ns.CharacterStats
if not (module and module.isSupported) then return end

local max = math.max
local strfind = string.find
local strlower = string.lower
local strmatch = string.match
local format = string.format
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local select = select
local type = type
local pcall = pcall
local rawget = rawget

local HOLY_SCHOOL = 2
local MAX_SPELL_SCHOOL = 7
local ALL_SPELL_SCHOOLS = { 2, 3, 4, 5, 6, 7 }
local CRIT_DISPLAY_CAP = 100

local function CSC_CapCritPercent(value)
    if type(value) ~= "number" then return value end
    if value > CRIT_DISPLAY_CAP then return CRIT_DISPLAY_CAP end
    return value
end

local function CSC_CapCritSchoolValues(values)
    if type(values) ~= "table" then return end
    for _, s in ipairs(ALL_SPELL_SCHOOLS) do
        if values[s] ~= nil then
            values[s] = CSC_CapCritPercent(values[s])
        end
    end
end

local function CSC_RequestCritStatRefresh()
    if _G.FluxCSC_QueuePlayerStatRefresh then
        _G.FluxCSC_QueuePlayerStatRefresh()
    elseif _G.FluxInfoFrame and _G.FluxInfoFrame.RequestStatRefresh then
        _G.FluxInfoFrame.RequestStatRefresh()
    end
end

local CLASS_ID = {
    warrior = rawget(_G, "CSC_WARRIOR_CLASS_ID") or 1,
    paladin = rawget(_G, "CSC_PALADIN_CLASS_ID") or 2,
    hunter = rawget(_G, "CSC_HUNTER_CLASS_ID") or 3,
    rogue = rawget(_G, "CSC_ROGUE_CLASS_ID") or 4,
    priest = rawget(_G, "CSC_PRIEST_CLASS_ID") or 5,
    shaman = rawget(_G, "CSC_SHAMAN_CLASS_ID") or 7,
    mage = rawget(_G, "CSC_MAGE_CLASS_ID") or 8,
    warlock = rawget(_G, "CSC_WARLOCK_CLASS_ID") or 9,
    druid = rawget(_G, "CSC_DRUID_CLASS_ID") or 11,
}

local RELEVANT_SCHOOLS_BY_CLASS = {
    [CLASS_ID.druid] = { [4] = true, [7] = true },
    [CLASS_ID.priest] = { [2] = true, [6] = true },
    [CLASS_ID.warlock] = { [3] = true, [6] = true },
    [CLASS_ID.mage] = { [3] = true, [5] = true, [7] = true },
    [CLASS_ID.shaman] = { [3] = true, [4] = true, [5] = true },
    [CLASS_ID.paladin] = { [2] = true },
    [CLASS_ID.hunter] = { [4] = true },
}

local SCHOOL_KEYWORDS = {
    { key = "fire", school = 3 },
    { key = "frost", school = 5 },
    { key = "nature", school = 4 },
    { key = "shadow", school = 6 },
    { key = "arcane", school = 7 },
    { key = "holy", school = 2 },
}

-- includedInAPI=false: add on top of Blizzard APIs when the stat panel misses the bonus.
-- hiddenAura=true: buff may be invisible to UnitAura; combat log backs up stack tracking.
-- incrementOnSchoolCast: while active, +flatPerStack on each cast of that spell school.
local CRIT_AURA_REGISTRY = {
    [11129] = {
        schools = { 3 }, flatPerStack = 10, includedInAPI = false, scope = "spell",
        hiddenAura = true, incrementOnSchoolCast = 3,
    },
    [1213319] = { schools = { 3 }, multiply = 1.5, includedInAPI = false, scope = "spell" },
    [1213320] = { schools = { 3 }, multiply = 1.5, includedInAPI = false, scope = "spell" },
    [1213321] = { schools = { 3 }, multiply = 1.5, includedInAPI = false, scope = "spell" },
    [1213322] = { schools = { 3 }, multiply = 1.5, includedInAPI = false, scope = "spell" },
}

local COMBUSTION_SPELL_ID = 11129
local HiddenAuraTrackers = {}

local function GetHiddenTracker(spellId)
    if not HiddenAuraTrackers[spellId] then
        HiddenAuraTrackers[spellId] = { active = false, bonus = 0 }
    end
    return HiddenAuraTrackers[spellId]
end

local function ResetHiddenTracker(spellId)
    local t = HiddenAuraTrackers[spellId]
    if t then
        t.active = false
        t.bonus = 0
    end
end

local function UseUnifiedSecondaryStats()
    return module.isRetail
end

-- Generic aura/gear tooltip crit parsing is disabled: Blizzard APIs already include standard bonuses.
local function AllowGenericCritTooltipParsing()
    return false
end

local function GetRelevantSchools(classId)
    if type(rawget(_G, "CSC_RelevantSchoolsByClass")) == "table" then
        local t = _G.CSC_RelevantSchoolsByClass[classId]
        if t then return t end
    end
    return RELEVANT_SCHOOLS_BY_CLASS[classId] or {}
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d
end

local function NewSchoolTable(default)
    local t = {}
    for _, s in ipairs(ALL_SPELL_SCHOOLS) do
        t[s] = default or 0
    end
    return t
end

local CritAuraScanner = CreateFrame("GameTooltip", "CSC_CritAuraScanner", nil, "GameTooltipTemplate")
CritAuraScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function DetectSchoolsFromText(lower)
    local found = {}
    local any = false
    for _, entry in ipairs(SCHOOL_KEYWORDS) do
        if strfind(lower, entry.key, 1, true) then
            found[entry.school] = true
            any = true
        end
    end
    return found, any
end

local function DetectScopeFromText(lower)
    if strfind(lower, "ranged", 1, true) then return "ranged" end
    if strfind(lower, "melee", 1, true) then return "melee" end
    if strfind(lower, "spell", 1, true) or strfind(lower, "magic", 1, true) then return "spell" end
    if strfind(lower, "attack", 1, true) then return "all" end
    return "spell"
end

local function ParseCritBonusFromText(text)
    if not text or text == "" then return end
    local lower = strlower(text)

    local multiplyPercent = strmatch(lower, "([%d%.]+)%% increased critical strike chance")
        or strmatch(lower, "increased critical strike chance by ([%d%.]+)%%")
        or strmatch(lower, "critical strike chance increased by ([%d%.]+)%%")
    if multiplyPercent then
        local pct = tonumber(multiplyPercent)
        if pct and pct > 0 then
            return nil, 1 + (pct / 100), DetectSchoolsFromText(lower), DetectScopeFromText(lower)
        end
    end

    local flat = strmatch(lower, "critical strike chance by ([%d%.]+)%%")
        or strmatch(lower, "increases your critical strike chance by ([%d%.]+)%%")
        or strmatch(lower, "increases the critical strike chance of your .- by ([%d%.]+)%%")
        or strmatch(lower, "critical strike chance with fire damage spells by ([%d%.]+)%%")
        or strmatch(lower, "critical strike chance with fire spells by ([%d%.]+)%%")
        or strmatch(lower, "increase.-critical strike chance.-fire.-by ([%d%.]+)%%")
        or strmatch(lower, "critical strike chance with.-spells by ([%d%.]+)%%")
        or strmatch(lower, "(%+[%d%.]+)%% critical strike")
        or strmatch(lower, "([%d%.]+)%% critical strike")
        or strmatch(lower, "improves your chance to get a critical strike by ([%d%.]+)%%")
        or strmatch(lower, "chance to get a critical strike by ([%d%.]+)%%")
        or strmatch(lower, "gain ([%d%.]+)%% increased critical strike chance")
        or strmatch(lower, "([%d%.]+)%% increased critical strike chance for your next")
    if flat then
        local v = tonumber((flat:gsub("^%+", "")))
        if v and v > 0 then
            return v, nil, DetectSchoolsFromText(lower), DetectScopeFromText(lower)
        end
    end
end

local function ScanUnitAuraTooltip(unit, index)
    CritAuraScanner:ClearLines()
    local numLines = 0

    if CritAuraScanner.SetUnitAura then
        local ok = pcall(CritAuraScanner.SetUnitAura, CritAuraScanner, unit, index, "HELPFUL")
        if ok then
            numLines = CritAuraScanner:NumLines() or 0
        end
    end
    if numLines <= 1 and CritAuraScanner.SetUnitBuff then
        CritAuraScanner:ClearLines()
        local ok = pcall(CritAuraScanner.SetUnitBuff, CritAuraScanner, unit, index)
        if ok then
            numLines = CritAuraScanner:NumLines() or 0
        end
    end
    if numLines <= 1 then
        return
    end

    local combined = {}
    for i = 2, numLines do
        local line = _G["CSC_CritAuraScannerTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and text ~= "" then
                combined[#combined + 1] = text
            end
        end
    end
    if #combined == 0 then return end
    return table.concat(combined, "\n")
end

local function ScanSpellTooltipLines(spellId)
    if not spellId then return end
    CritAuraScanner:ClearLines()
    if CritAuraScanner.SetSpellByID then
        CritAuraScanner:SetSpellByID(spellId)
    elseif CritAuraScanner.SetHyperlink then
        CritAuraScanner:SetHyperlink("spell:" .. spellId)
    else
        return
    end
    local combined = {}
    for i = 2, CritAuraScanner:NumLines() do
        local line = _G["CSC_CritAuraScannerTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and text ~= "" then
                combined[#combined + 1] = text
            end
        end
    end
    if #combined == 0 then return end
    return table.concat(combined, "\n")
end

local function IsSpellOfSchool(spellId, school)
    if not spellId or not school then return false end
    if school == 3 and spellId == COMBUSTION_SPELL_ID then return true end
    local text = ScanSpellTooltipLines(spellId)
    if not text then return false end
    local lower = strlower(text)
    for _, entry in ipairs(SCHOOL_KEYWORDS) do
        if entry.school == school and strfind(lower, entry.key, 1, true) then
            if strfind(lower, "school", 1, true) or strfind(lower, entry.key .. " damage", 1, true) or strfind(lower, entry.key .. " spell", 1, true) then
                return true
            end
        end
    end
    if school == 3 and strfind(lower, "school:%s*fire", 1) then return true end
    if school == 5 and strfind(lower, "school:%s*frost", 1) then return true end
    if school == 4 and strfind(lower, "school:%s*nature", 1) then return true end
    if school == 6 and strfind(lower, "school:%s*shadow", 1) then return true end
    if school == 7 and strfind(lower, "school:%s*arcane", 1) then return true end
    if school == 2 and strfind(lower, "school:%s*holy", 1) then return true end
    return false
end

local function ReadAuraAtIndex(unit, index)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, "HELPFUL")
        if ok and aura and aura.spellId then
            local stacks = aura.applications or aura.count or 1
            if stacks <= 0 then stacks = 1 end
            return aura.spellId, stacks
        end
    end

    if UnitAura then
        local name, _, count, _, _, _, _, _, _, spellId = UnitAura(unit, index, "HELPFUL")
        if name and spellId then
            local stacks = count or 1
            if stacks <= 0 then stacks = 1 end
            return spellId, stacks
        end
        return nil
    end

    if UnitBuff then
        local name, _, count, _, _, _, _, _, _, spellId = UnitBuff(unit, index)
        if name and spellId then
            local stacks = count or 1
            if stacks <= 0 then stacks = 1 end
            return spellId, stacks
        end
    end
end

local function ApplyHiddenTrackerBonus(entry, bonus, out)
    if not entry or not bonus or bonus <= 0 then return end
    local schools = entry.schools
    if schools then
        for _, s in ipairs(schools) do
            out.schoolFlat[s] = out.schoolFlat[s] + bonus
        end
    else
        for _, s in ipairs(ALL_SPELL_SCHOOLS) do
            out.schoolFlat[s] = out.schoolFlat[s] + bonus
        end
    end
end

-- Hidden-aura combat log tracking (Combustion stacks, etc.) is classic-only.
-- Post-DF retail forbids addon RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED").
local HiddenAuraEventFrame = CreateFrame("Frame")
local hiddenAuraEventsRegistered = false

local function OnHiddenAuraEvent(_, event, unit)
    if event == "UNIT_AURA" then
        if unit ~= "player" then return end
        for spellId, entry in pairs(CRIT_AURA_REGISTRY) do
            if entry.hiddenAura then
                local found = false
                for i = 1, 40 do
                    local auraSpellId = ReadAuraAtIndex("player", i)
                    if not auraSpellId then break end
                    if auraSpellId == spellId then
                        found = true
                        break
                    end
                end
                if not found then
                    ResetHiddenTracker(spellId)
                end
            end
        end
        CSC_RequestCritStatRefresh()
        return
    end

    if type(CombatLogGetCurrentEventInfo) ~= "function" then return end

    local _, subevent, _, srcGUID, _, _, _, _, _, _, _, spellId, _, _, amount = CombatLogGetCurrentEventInfo()
    if srcGUID ~= UnitGUID("player") then return end

    local entry = CRIT_AURA_REGISTRY[spellId]
    if entry and entry.hiddenAura then
        local tracker = GetHiddenTracker(spellId)
        if subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH" then
            tracker.active = true
            local stacks = (type(amount) == "number" and amount > 0) and amount or 1
            local add = (entry.flatPerStack or 0) * stacks
            if add > 0 then
                tracker.bonus = max(tracker.bonus, add)
            end
        elseif subevent == "SPELL_AURA_REMOVED" then
            ResetHiddenTracker(spellId)
        elseif subevent == "SPELL_CAST_SUCCESS" and entry.flatPerStack then
            tracker.active = true
            tracker.bonus = max(tracker.bonus, entry.flatPerStack)
        end
        CSC_RequestCritStatRefresh()
        return
    end

    if subevent == "SPELL_CAST_SUCCESS" then
        for regSpellId, regEntry in pairs(CRIT_AURA_REGISTRY) do
            if regEntry.hiddenAura and regEntry.incrementOnSchoolCast and regEntry.flatPerStack then
                local tracker = GetHiddenTracker(regSpellId)
                if tracker.active and spellId ~= regSpellId and IsSpellOfSchool(spellId, regEntry.incrementOnSchoolCast) then
                    tracker.bonus = tracker.bonus + regEntry.flatPerStack
                    CSC_RequestCritStatRefresh()
                end
            end
        end
    end
end

local function RegisterHiddenAuraEvents()
    if hiddenAuraEventsRegistered or module.isRetail then return end
    HiddenAuraEventFrame:SetScript("OnEvent", OnHiddenAuraEvent)
    pcall(function()
        HiddenAuraEventFrame:RegisterEvent("UNIT_AURA")
    end)
    pcall(function()
        HiddenAuraEventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end)
    hiddenAuraEventsRegistered = true
end

local hiddenAuraBootFrame = CreateFrame("Frame")
hiddenAuraBootFrame:RegisterEvent("PLAYER_LOGIN")
hiddenAuraBootFrame:SetScript("OnEvent", function()
    RegisterHiddenAuraEvents()
    hiddenAuraBootFrame:UnregisterEvent("PLAYER_LOGIN")
end)

local function ApplyRegistryEntry(entry, stacks, out)
    stacks = stacks or 1
    if entry.includedInAPI then return end

    local schools = entry.schools
    if entry.flatPerStack and entry.flatPerStack ~= 0 then
        local add = entry.flatPerStack * stacks
        if entry.scope == "melee" then
            out.meleeFlat = out.meleeFlat + add
        elseif entry.scope == "ranged" then
            out.rangedFlat = out.rangedFlat + add
        elseif entry.scope == "all" then
            out.meleeFlat = out.meleeFlat + add
            out.rangedFlat = out.rangedFlat + add
            for _, s in ipairs(ALL_SPELL_SCHOOLS) do
                out.schoolFlat[s] = out.schoolFlat[s] + add
            end
        else
            if schools then
                for _, s in ipairs(schools) do
                    out.schoolFlat[s] = out.schoolFlat[s] + add
                end
            else
                for _, s in ipairs(ALL_SPELL_SCHOOLS) do
                    out.schoolFlat[s] = out.schoolFlat[s] + add
                end
            end
        end
    end

    if entry.multiply and entry.multiply > 1 then
        local mult = entry.multiply
        if entry.scope == "melee" then
            out.meleeMult = max(out.meleeMult, mult)
        elseif entry.scope == "ranged" then
            out.rangedMult = max(out.rangedMult, mult)
        elseif entry.scope == "all" then
            out.meleeMult = max(out.meleeMult, mult)
            out.rangedMult = max(out.rangedMult, mult)
            for _, s in ipairs(ALL_SPELL_SCHOOLS) do
                out.schoolMult[s] = max(out.schoolMult[s], mult)
            end
        else
            if schools then
                for _, s in ipairs(schools) do
                    out.schoolMult[s] = max(out.schoolMult[s], mult)
                end
            else
                for _, s in ipairs(ALL_SPELL_SCHOOLS) do
                    out.schoolMult[s] = max(out.schoolMult[s], mult)
                end
            end
        end
    end
end

local function ApplyParsedBonus(flat, mult, schoolMap, scope, out)
    out.meleeMult = out.meleeMult or 1
    out.rangedMult = out.rangedMult or 1
    if not out.schoolMult then
        out.schoolMult = NewSchoolTable(1)
    end
    if flat and flat > 0 then
        if scope == "melee" then
            out.meleeFlat = out.meleeFlat + flat
        elseif scope == "ranged" then
            out.rangedFlat = out.rangedFlat + flat
        elseif scope == "all" then
            out.meleeFlat = out.meleeFlat + flat
            out.rangedFlat = out.rangedFlat + flat
            for _, s in ipairs(ALL_SPELL_SCHOOLS) do
                out.schoolFlat[s] = out.schoolFlat[s] + flat
            end
        else
            if schoolMap and next(schoolMap) then
                for s in pairs(schoolMap) do
                    out.schoolFlat[s] = out.schoolFlat[s] + flat
                end
            else
                for _, s in ipairs(ALL_SPELL_SCHOOLS) do
                    out.schoolFlat[s] = out.schoolFlat[s] + flat
                end
            end
        end
    end

    if mult and mult > 1 then
        if scope == "melee" then
            out.meleeMult = max(out.meleeMult, mult)
        elseif scope == "ranged" then
            out.rangedMult = max(out.rangedMult, mult)
        elseif scope == "all" then
            out.meleeMult = max(out.meleeMult, mult)
            out.rangedMult = max(out.rangedMult, mult)
            for _, s in ipairs(ALL_SPELL_SCHOOLS) do
                out.schoolMult[s] = max(out.schoolMult[s], mult)
            end
        else
            if schoolMap and next(schoolMap) then
                for s in pairs(schoolMap) do
                    out.schoolMult[s] = max(out.schoolMult[s], mult)
                end
            else
                for _, s in ipairs(ALL_SPELL_SCHOOLS) do
                    out.schoolMult[s] = max(out.schoolMult[s], mult)
                end
            end
        end
    end
end

function CSC_ScanAuraCritBonuses(unit, opts)
    unit = unit or "player"
    opts = opts or {}
    local out = {
        meleeFlat = 0,
        rangedFlat = 0,
        schoolFlat = NewSchoolTable(0),
        meleeMult = 1,
        rangedMult = 1,
        schoolMult = NewSchoolTable(1),
    }

    local registryApplied = {}
    local allowFlatTooltip = AllowGenericCritTooltipParsing()

    for i = 1, 40 do
        local spellId, stacks = ReadAuraAtIndex(unit, i)
        if not spellId then break end

        local entry = CRIT_AURA_REGISTRY[spellId]
        if entry and not entry.includedInAPI then
            ApplyRegistryEntry(entry, stacks, out)
            if entry.flatPerStack then
                registryApplied[spellId] = entry.flatPerStack * stacks
            else
                registryApplied[spellId] = registryApplied[spellId] or 0
            end
        end

        if allowFlatTooltip then
            local tooltipText = ScanUnitAuraTooltip(unit, i)
            if tooltipText then
                local flat, mult, schoolMap, scope = ParseCritBonusFromText(tooltipText)
                if mult then
                    ApplyParsedBonus(nil, mult, schoolMap, scope or "spell", out)
                end
                if flat and (entry and entry.includedInAPI == false) then
                    if entry and entry.flatPerStack then
                        flat = max(flat, entry.flatPerStack * stacks)
                    end
                    ApplyParsedBonus(flat, nil, schoolMap, scope or "spell", out)
                    registryApplied[spellId] = max(registryApplied[spellId] or 0, flat)
                end
            end

            if not entry then
                tooltipText = ScanSpellTooltipLines(spellId)
                if tooltipText then
                    local flat, mult, schoolMap, scope = ParseCritBonusFromText(tooltipText)
                    if mult then
                        ApplyParsedBonus(nil, mult, schoolMap, scope or "spell", out)
                    elseif flat then
                        ApplyParsedBonus(flat, nil, schoolMap, scope or "spell", out)
                    end
                end
            end
        end
    end

    for spellId, entry in pairs(CRIT_AURA_REGISTRY) do
        if entry.hiddenAura and not entry.includedInAPI then
            local tracker = HiddenAuraTrackers[spellId]
            local applied = registryApplied[spellId] or 0
            if tracker and tracker.active and tracker.bonus > applied then
                ApplyHiddenTrackerBonus(entry, tracker.bonus - applied, out)
            end
        end
    end

    return out
end

local function ScanGearCritBonuses(_unit)
    -- Gear crit is included in Blizzard APIs; no tooltip scan (matches CharacterStatsClassic/TBC).
    return {
        meleeFlat = 0,
        rangedFlat = 0,
        schoolFlat = NewSchoolTable(0),
        meleeMult = 1,
        rangedMult = 1,
        schoolMult = NewSchoolTable(1),
    }
end

local function MergeAuraCritOntoBase(base, auraBonuses, gearBonuses)
    local flat = max(auraBonuses.meleeFlat or 0, auraBonuses.rangedFlat or 0)
    for _, s in ipairs(ALL_SPELL_SCHOOLS) do
        flat = max(flat, auraBonuses.schoolFlat[s] or 0)
    end
    if gearBonuses then
        flat = max(flat, gearBonuses.meleeFlat or 0, gearBonuses.rangedFlat or 0)
        for _, s in ipairs(ALL_SPELL_SCHOOLS) do
            flat = max(flat, gearBonuses.schoolFlat[s] or 0)
        end
    end

    local mult = max(auraBonuses.meleeMult or 1, auraBonuses.rangedMult or 1, 1)
    for _, s in ipairs(ALL_SPELL_SCHOOLS) do
        mult = max(mult, auraBonuses.schoolMult[s] or 1)
    end

    local crit = (base or 0) + flat
    if mult > 1 then
        crit = crit * mult
    end
    return crit
end

local function ApplyAuraAndGearToSchoolValues(values, auraBonuses, gearBonuses)
    for _, s in ipairs(ALL_SPELL_SCHOOLS) do
        local v = values[s] or 0
        v = v + (auraBonuses.schoolFlat[s] or 0) + (gearBonuses.schoolFlat[s] or 0)
        local mult = max(auraBonuses.schoolMult[s] or 1, 1)
        if mult > 1 then
            v = v * mult
        end
        values[s] = v
    end
end

local function ApplyClassTalentCritOverlays(values, unit)
    local classId = select(3, UnitClass(unit))

    if classId == CLASS_ID.mage then
        local arcaneBonus, fireBonus = SafeCall(_G.CSC_GetMageCritStatsFromTalents)
        arcaneBonus = arcaneBonus or 0
        fireBonus = fireBonus or 0
        if arcaneBonus > 0 then
            for _, s in ipairs(ALL_SPELL_SCHOOLS) do
                values[s] = values[s] + arcaneBonus
            end
        end
        if fireBonus > 0 then
            values[3] = values[3] + fireBonus
        end
    elseif classId == CLASS_ID.priest then
        local priestHolyCrit = SafeCall(_G.CSC_GetPriestCritStatsFromTalents) or 0
        priestHolyCrit = priestHolyCrit + (SafeCall(_G.CSC_GetHolyCritFromBenediction, unit) or 0)
        if priestHolyCrit > 0 then
            values[2] = values[2] + priestHolyCrit
        end
    elseif classId == CLASS_ID.warlock then
        local destructionCrit = SafeCall(_G.CSC_GetWarlockCritStatsFromTalents) or 0
        if destructionCrit > 0 then
            values[6] = values[6] + destructionCrit
            values[3] = values[3] + destructionCrit
        end
    elseif classId == CLASS_ID.shaman then
        local natureCrit = values[4]
        local lightningCrit = natureCrit
        local callOfThunderCrit = SafeCall(_G.CSC_GetShamanCallOfThunderCrit) or 0
        if callOfThunderCrit > 0 then
            lightningCrit = lightningCrit + callOfThunderCrit
        end
        local tidalMastery = SafeCall(_G.CSC_GetShamanTidalMasteryCrit) or 0
        if tidalMastery > 0 then
            lightningCrit = lightningCrit + tidalMastery
            values[4] = values[4] + tidalMastery
        end
        return lightningCrit
    end

    return nil
end

function CSC_BuildSpellCritData(unit)
    unit = unit or "player"
    local classId = select(3, UnitClass(unit))
    local relevant = GetRelevantSchools(classId)
    local values = NewSchoolTable(0)
    local extras = {}

    if UseUnifiedSecondaryStats() and type(GetCritChance) == "function" then
        local auraBonuses = CSC_ScanAuraCritBonuses(unit)
        local gearBonuses = ScanGearCritBonuses(unit)
        local crit = CSC_CapCritPercent(MergeAuraCritOntoBase(GetCritChance() or 0, auraBonuses, gearBonuses))
        return crit, nil, values, relevant, extras
    end

    if type(GetSpellCritChance) == "function" then
        for _, s in ipairs(ALL_SPELL_SCHOOLS) do
            values[s] = GetSpellCritChance(s) or 0
        end
    end

    local lightningCrit = ApplyClassTalentCritOverlays(values, unit)
    if lightningCrit then
        extras.lightningCrit = lightningCrit
    end

    local auraBonuses = CSC_ScanAuraCritBonuses(unit)
    local gearBonuses = ScanGearCritBonuses(unit)
    ApplyAuraAndGearToSchoolValues(values, auraBonuses, gearBonuses)

    if lightningCrit and classId == CLASS_ID.shaman then
        local callOfThunderCrit = SafeCall(_G.CSC_GetShamanCallOfThunderCrit) or 0
        lightningCrit = values[4] + callOfThunderCrit
        extras.lightningCrit = lightningCrit
    end

    local maxCrit = 0
    local topSchool = nil
    for school = HOLY_SCHOOL, MAX_SPELL_SCHOOL do
        if not next(relevant) or relevant[school] then
            local v = values[school] or 0
            if v > maxCrit then
                maxCrit = v
                topSchool = school
            end
        end
    end

    if lightningCrit and lightningCrit > maxCrit then
        maxCrit = lightningCrit
    end

    CSC_CapCritSchoolValues(values)
    if extras.lightningCrit then
        extras.lightningCrit = CSC_CapCritPercent(extras.lightningCrit)
    end
    maxCrit = CSC_CapCritPercent(maxCrit)

    return maxCrit, topSchool, values, relevant, extras
end

function CSC_UpdateSpellCritStatFrameFromCalculator(statFrame, unit)
    unit = unit or "player"
    statFrame = statFrame or {}

    local maxCrit, _, values, _, extras = CSC_BuildSpellCritData(unit)
    statFrame.holyCrit = CSC_CapCritPercent(values[2])
    statFrame.fireCrit = CSC_CapCritPercent(values[3])
    statFrame.natureCrit = CSC_CapCritPercent(values[4])
    statFrame.frostCrit = CSC_CapCritPercent(values[5])
    statFrame.shadowCrit = CSC_CapCritPercent(values[6])
    statFrame.arcaneCrit = CSC_CapCritPercent(values[7])
    statFrame.lightningCrit = CSC_CapCritPercent(extras and extras.lightningCrit or values[4])
    statFrame.unitClassId = select(3, UnitClass(unit))

    return CSC_CapCritPercent(maxCrit)
end

local function ApplyPhysicalCritBonuses(base, auraBonuses, gearBonuses, which)
    local flatKey = (which == "ranged") and "rangedFlat" or "meleeFlat"
    local multKey = (which == "ranged") and "rangedMult" or "meleeMult"
    local flat = (auraBonuses[flatKey] or 0) + (gearBonuses[flatKey] or 0)
    local mult = max(auraBonuses[multKey] or 1, gearBonuses[multKey] or 1, 1)

    local crit = (base or 0) + flat
    if mult > 1 then
        crit = crit * mult
    end
    return crit
end

function CSC_GetDisplayMeleeCritPercent(unit)
    unit = unit or "player"
    local auraBonuses = CSC_ScanAuraCritBonuses(unit)
    local gearBonuses = ScanGearCritBonuses(unit)
    if UseUnifiedSecondaryStats() and type(GetCritChance) == "function" then
        return CSC_CapCritPercent(MergeAuraCritOntoBase(GetCritChance(), auraBonuses, gearBonuses))
    end
    local base = (type(GetCritChance) == "function" and GetCritChance()) or 0
    return CSC_CapCritPercent(ApplyPhysicalCritBonuses(base, auraBonuses, gearBonuses, "melee"))
end

function CSC_GetDisplayRangedCritPercent(unit)
    unit = unit or "player"
    local auraBonuses = CSC_ScanAuraCritBonuses(unit)
    local gearBonuses = ScanGearCritBonuses(unit)
    if UseUnifiedSecondaryStats() and type(GetCritChance) == "function" then
        return CSC_CapCritPercent(MergeAuraCritOntoBase(GetCritChance(), auraBonuses, gearBonuses))
    end
    local base
    if type(GetRangedCritChance) == "function" then
        base = GetRangedCritChance()
    else
        base = (type(GetCritChance) == "function" and GetCritChance()) or 0
    end
    return CSC_CapCritPercent(ApplyPhysicalCritBonuses(base, auraBonuses, gearBonuses, "ranged"))
end

_G.CSC_BuildSpellCritData = CSC_BuildSpellCritData
_G.CSC_InfoFrame_GetDisplayMeleeCritPercent = CSC_GetDisplayMeleeCritPercent
_G.CSC_InfoFrame_GetDisplayRangedCritPercent = CSC_GetDisplayRangedCritPercent
_G.CSC_InfoFrame_BuildSpellCritData = function(unit)
    local maxCrit, topSchool, values, relevant = CSC_BuildSpellCritData(unit)
    return maxCrit, topSchool, values, relevant
end

