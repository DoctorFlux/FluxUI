local _, ns = ...
local module = ns.CharacterStats
if not (module and module.useClassicPaperDollChrome) then return end

-- Addon: CharacterStatsCustomExtensions (FIXED STABLE VERSION + WORKING CAST SPEED)

-- ======================================
-- ============== CONSTANTS =============
-- ======================================
-- Class IDs: Era/Progression modules early-return on retail so CSC_*_CLASS_ID may be nil; use fallbacks.
local _cid = {
    druid = CSC_DRUID_CLASS_ID or 11,
    priest = CSC_PRIEST_CLASS_ID or 5,
    warlock = CSC_WARLOCK_CLASS_ID or 9,
    mage = CSC_MAGE_CLASS_ID or 8,
    shaman = CSC_SHAMAN_CLASS_ID or 7,
    paladin = CSC_PALADIN_CLASS_ID or 2,
    hunter = CSC_HUNTER_CLASS_ID or 3,
}

CSC_RelevantSchoolsByClass = {
    [_cid.druid]   = { [4]=true, [7]=true },
    [_cid.priest]  = { [2]=true, [6]=true },
    [_cid.warlock] = { [3]=true, [6]=true },
    [_cid.mage]    = { [3]=true, [5]=true, [7]=true },
    [_cid.shaman]  = { [3]=true, [4]=true, [5]=true },
    [_cid.paladin] = { [2]=true },
    [_cid.hunter]  = { [4]=true },
}

local schoolNames = {
    [2] = "Holy",
    [3] = "Fire",
    [4] = "Nature",
    [5] = "Frost",
    [6] = "Shadow",
    [7] = "Arcane"
}

local colorBySchool = {
    [2] = "ffff99",
    [3] = "ff8000",
    [4] = "3A9E3A",
    [5] = "66ccff",
    [6] = "cc66ff",
    [7] = "99ccff"
}

local orderedSchools = { 2, 3, 4, 5, 6, 7 }

local CSC_SPELL_HIT_CAP = module.majorVersion >= 3 and 17 or 16

-- ======================================
-- ===== SAFE RUNE BONUS FUNCTION =======
-- ======================================

local RingRuneSpellHitByName = {
    ["Arcane Specialization"] = 7,
    ["Fire Specialization"] = 3,
    ["Nature Specialization"] = 4,
    ["Frost Specialization"] = 5,
    ["Shadow Specialization"] = 6,
    ["Holy Specialization"] = 2,
}

function GetRingRuneSpellHitBonuses()
    local bonuses = {}

    if not C_Engraving or not C_Engraving.GetRuneForEquipmentSlot then
        return bonuses
    end

    for _, slot in ipairs({ INVSLOT_FINGER1, INVSLOT_FINGER2 }) do
        local rune = C_Engraving.GetRuneForEquipmentSlot(slot)
        if rune and rune.name and RingRuneSpellHitByName[rune.name] then
            local school = RingRuneSpellHitByName[rune.name]
            bonuses[school] = 6
        end
    end

    return bonuses
end

-- ======================================
-- ===== SAFE TALENT WRAPPERS ===========
-- ======================================

local function SafeMageHit()
    if CSC_GetMageSpellHitFromTalents then
        local ok, a, b = pcall(CSC_GetMageSpellHitFromTalents)
        if ok then return a or 0, b or 0 end
    end
    return 0, 0
end

local function SafeWarlockHit()
    if CSC_GetWarlockSpellHitFromTalents then
        local ok, v = pcall(CSC_GetWarlockSpellHitFromTalents)
        if ok then return v or 0 end
    end
    return 0
end

-- ======================================
-- ===== TOOLTIP GROUPING HELPERS =======
-- ======================================

local function JoinColoredSchoolNames(schools)
    local parts = {}
    for _, school in ipairs(schools) do
        local color = colorBySchool[school] or "ffffff"
        local name = schoolNames[school] or "Unknown"
        parts[#parts + 1] = string.format("|cff%s%s|r", color, name)
    end
    return table.concat(parts, " / ")
end

local function AddGroupedSchoolLines(tooltip, values, relevant, isPercent)
    local grouped = {}
    local order = {}

    for _, school in ipairs(orderedSchools) do
        if relevant[school] and values[school] ~= nil then
            local value = values[school]
            local key = isPercent and string.format("%.1f", value) or tostring(value)

            if not grouped[key] then
                grouped[key] = {
                    value = value,
                    schools = {}
                }
                order[#order + 1] = key
            end

            table.insert(grouped[key].schools, school)
        end
    end

    for _, key in ipairs(order) do
        local entry = grouped[key]
        local label = JoinColoredSchoolNames(entry.schools)

        if isPercent then
            tooltip:AddLine(string.format("%s: %.1f%%", label, entry.value))
        else
            tooltip:AddLine(string.format("%s: %d", label, entry.value))
        end
    end
end

-- ======================================
-- ===== DISPLAY COLOR TIE HELPERS ======
-- ======================================

local function GetPrimaryTalentTabIndex()
    if not GetNumTalentTabs or not GetTalentTabInfo then
        return nil
    end

    local bestTab = nil
    local bestPoints = -1

    for tab = 1, GetNumTalentTabs() do
        local _, _, pointsSpent = GetTalentTabInfo(tab)
        pointsSpent = tonumber(pointsSpent) or 0

        if pointsSpent > bestPoints then
            bestPoints = pointsSpent
            bestTab = tab
        end
    end

    if bestPoints <= 0 then
        return nil
    end

    return bestTab
end

local function GetDominantSpecSchool(classId)
    local tab = GetPrimaryTalentTabIndex()
    if not tab then
        return nil
    end

    if classId == CSC_MAGE_CLASS_ID then
        if tab == 1 then return 7 end -- Arcane
        if tab == 2 then return 3 end -- Fire
        if tab == 3 then return 5 end -- Frost
    elseif classId == CSC_PRIEST_CLASS_ID then
        if tab == 2 then return 2 end -- Holy
        if tab == 3 then return 6 end -- Shadow
    elseif classId == CSC_WARLOCK_CLASS_ID then
        if tab == 1 then return 6 end -- Affliction -> Shadow
        if tab == 3 then return 3 end -- Destruction -> Fire
    elseif classId == CSC_PALADIN_CLASS_ID then
        if tab == 1 then return 2 end -- Holy
    elseif classId == CSC_DRUID_CLASS_ID then
        if tab == 1 then return 4 end -- Balance -> Nature
    elseif classId == CSC_SHAMAN_CLASS_ID then
        if tab == 1 then return 4 end -- Elemental -> Nature
    end

    return nil
end

local function GetTopSchoolsByDisplayedValue(values, relevant, maxVal, isPercent)
    local result = {}
    local maxKey = isPercent and string.format("%.1f", maxVal) or tostring(maxVal)

    for _, school in ipairs(orderedSchools) do
        if relevant[school] and values[school] ~= nil then
            local key = isPercent and string.format("%.1f", values[school]) or tostring(values[school])
            if key == maxKey then
                result[#result + 1] = school
            end
        end
    end

    return result
end

local function GetDisplayColorForTop(values, relevant, maxVal, isPercent)
    local topSchools = GetTopSchoolsByDisplayedValue(values, relevant, maxVal, isPercent)

    if #topSchools == 1 then
        return colorBySchool[topSchools[1]] or "ffffff"
    end

    if #topSchools > 1 then
        local classId = select(3, UnitClass("player"))
        local dominantSchool = GetDominantSpecSchool(classId)

        if dominantSchool then
            for _, school in ipairs(topSchools) do
                if school == dominantSchool then
                    return colorBySchool[school] or "ffffff"
                end
            end
        end
    end

    return "ffffff"
end

-- ======================================
-- ===== DATA BUILDERS FOR TOOLTIPS =====
-- ======================================

local function BuildSpellPowerData()
    local classId = select(3, UnitClass("player"))
    local relevant = CSC_RelevantSchoolsByClass[classId] or {}

    local maxDmg = 0
    local topSchool = nil
    local values = {}

    for school = 2, 7 do
        if relevant[school] then
            local dmg = GetSpellBonusDamage(school)
            values[school] = dmg

            if dmg > maxDmg then
                maxDmg = dmg
                topSchool = school
            end
        end
    end

    local heal = GetSpellBonusHealing()
    return maxDmg, heal, topSchool, values, relevant
end

local function BuildSpellHitData(unit)
    local classId = select(3, UnitClass(unit))
    local rune = GetRingRuneSpellHitBonuses()
    local relevant = CSC_RelevantSchoolsByClass[classId] or {}
    local values = {}

    if classId == CSC_MAGE_CLASS_ID then
        local B
        if type(CSC_GetSpellHitSharedBase) == "function" then
            B = CSC_GetSpellHitSharedBase(unit) or 0
        else
            B = (type(GetSpellHitModifier) == "function" and (GetSpellHitModifier() or 0)) or 0
        end
        local arcane, frostFire = SafeMageHit()
        -- Arcane Focus vs Fire/Frost (Elemental Precision) — only schools with that talent get the bonus
        values[7] = (arcane or 0) + B + (rune[7] or 0)
        values[3] = (frostFire or 0) + B + (rune[3] or 0)
        values[5] = (frostFire or 0) + B + (rune[5] or 0)
    elseif classId == CSC_WARLOCK_CLASS_ID then
        local B
        if type(CSC_GetSpellHitSharedBase) == "function" then
            B = CSC_GetSpellHitSharedBase(unit) or 0
        else
            B = (type(GetSpellHitModifier) == "function" and (GetSpellHitModifier() or 0)) or 0
        end
        local aff = SafeWarlockHit()
        values[6] = (aff or 0) + B + (rune[6] or 0)
    elseif classId == (CSC_PRIEST_CLASS_ID or _cid.priest) then
        local B
        if type(CSC_GetSpellHitSharedBase) == "function" then
            B = CSC_GetSpellHitSharedBase(unit) or 0
        else
            B = (type(GetSpellHitModifier) == "function" and (GetSpellHitModifier() or 0)) or 0
        end
        local sf = 0
        if type(CSC_GetPriestShadowFocusSpellHit) == "function" then
            local ok, v = pcall(CSC_GetPriestShadowFocusSpellHit)
            if ok and v then
                sf = v
            end
        end
        -- Holy: shared hit only; Shadow: + Shadow Focus (not applied to Holy spells)
        values[2] = B + (rune[2] or 0)
        values[6] = B + sf + (rune[6] or 0)
    elseif classId == (CSC_SHAMAN_CLASS_ID or _cid.shaman) then
        local shared = (type(CSC_GetSpellHitSharedBase) == "function" and CSC_GetSpellHitSharedBase(unit)) or 0
        local ep = 0
        if type(CSC_GetShamanHitFromElementalPrecision) == "function" then
            local ok, v = pcall(CSC_GetShamanHitFromElementalPrecision)
            if ok and v then
                ep = v
            end
        end
        local withoutEp = shared - ep
        -- Elemental Precision (TBC): Lightning / Nature only; Fire/Frost use gear + Nature's Guidance + auras
        if relevant[3] then
            values[3] = withoutEp + (rune[3] or 0)
        end
        if relevant[4] then
            values[4] = shared + (rune[4] or 0)
        end
        if relevant[5] then
            values[5] = withoutEp + (rune[5] or 0)
        end
    else
        local gearHit = 0
        if type(CSC_GetTotalSpellHitPercent) == "function" then
            gearHit = CSC_GetTotalSpellHitPercent(unit) or 0
        elseif type(GetSpellHitModifier) == "function" then
            gearHit = GetSpellHitModifier() or 0
        end
        for school = 2, 7 do
            if relevant[school] then
                values[school] = gearHit + (rune[school] or 0)
            end
        end
    end

    local maxVal = 0
    local topSchool = nil
    for school, v in pairs(values) do
        if v > maxVal then
            maxVal = v
            topSchool = school
        end
    end

    -- Summary number for list return (hook uses per-school from values; max is headline-style cap)
    local gearHit = (type(CSC_GetTotalSpellHitPercent) == "function" and (CSC_GetTotalSpellHitPercent(unit) or 0))
        or (type(GetSpellHitModifier) == "function" and (GetSpellHitModifier() or 0))
        or 0
    return maxVal, topSchool, values, relevant, gearHit
end

-- ======================================
-- ========== SPELL POWER ===============
-- ======================================

local _pendingHooks = {}
local _hookedByName = {}
local _retryFrame

local function TryInstallHookByName(funcName, handler)
    if _hookedByName[funcName] then
        return true
    end
    local fn = _G and _G[funcName]
    if type(fn) ~= "function" then
        return false
    end
    hooksecurefunc(funcName, handler)
    _hookedByName[funcName] = true
    return true
end

local function RetryPendingHooks()
    local anyPending = false
    for funcName, handler in pairs(_pendingHooks) do
        if TryInstallHookByName(funcName, handler) then
            _pendingHooks[funcName] = nil
        else
            anyPending = true
        end
    end
    if _retryFrame then
        if anyPending then
            _retryFrame:RegisterEvent("ADDON_LOADED")
            _retryFrame:RegisterEvent("PLAYER_LOGIN")
        else
            _retryFrame:UnregisterEvent("ADDON_LOADED")
            _retryFrame:UnregisterEvent("PLAYER_LOGIN")
        end
    end
end

local function SafeHookByName(funcName, handler)
    if type(funcName) ~= "string" or type(handler) ~= "function" then
        return false
    end
    if TryInstallHookByName(funcName, handler) then
        return true
    end
    _pendingHooks[funcName] = handler
    if not _retryFrame then
        _retryFrame = CreateFrame("Frame")
        _retryFrame:SetScript("OnEvent", RetryPendingHooks)
    end
    _retryFrame:RegisterEvent("ADDON_LOADED")
    _retryFrame:RegisterEvent("PLAYER_LOGIN")
    return false
end

--- Shared by CSC spell row and InfoFrame when no PaperDoll statFrame resolves (Heal vs S.P. display).
local function ShowFluxCSCSpellPowerTooltip(owner)
    if not owner then return end
    local maxDmg, heal, topSchool, values, relevant = BuildSpellPowerData()

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Power", 1, 1, 1)
    GameTooltip:AddLine(string.format("Spell Power: |cffffff00%d|r", maxDmg))
    GameTooltip:AddLine(string.format("Healing: |cff20ff20%d|r", heal))
    GameTooltip:AddLine(" ")

    AddGroupedSchoolLines(GameTooltip, values, relevant, false)

    GameTooltip:Show()
end

_G.CSC_InfoFrame_ShowSpellPowerTooltip = ShowFluxCSCSpellPowerTooltip

SafeHookByName("CSC_PaperDollFrame_SetSpellPower", function(statFrame)
    local maxDmg, heal, topSchool, values, relevant = BuildSpellPowerData()
    local color = GetDisplayColorForTop(values, relevant, maxDmg, false)

    statFrame.Value:SetText(
        string.format("|cff%s%d|r / |cff20ff20%d|r", color, maxDmg, heal)
    )

    statFrame.Label:SetText("Power:")

    statFrame:SetScript("OnEnter", function(self)
        ShowFluxCSCSpellPowerTooltip(self)
    end)

    statFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    if _G.FluxInfoFrame and _G.FluxInfoFrame.HookClassicCSCStatFrame then
        _G.FluxInfoFrame.HookClassicCSCStatFrame(statFrame)
    end
end)

-- ======================================
-- ========== SPELL CRIT ================
-- ======================================

SafeHookByName("CSC_PaperDollFrame_SetSpellCritChance", function(statFrame)
    local buildFn = _G.CSC_BuildSpellCritData or _G.CSC_InfoFrame_BuildSpellCritData
    local maxCrit, topSchool, values, relevant
    if type(buildFn) == "function" then
        maxCrit, topSchool, values, relevant = buildFn("player")
    end
    if type(maxCrit) ~= "number" then return end
    values = values or {}
    relevant = relevant or {}
    local color = GetDisplayColorForTop(values, relevant, maxCrit, true)

    statFrame.Value:SetText(
        string.format("|cff%s%.1f%%|r", color, maxCrit)
    )

    statFrame.Label:SetText("Crit:")

    statFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Crit", 1, 1, 1)
        GameTooltip:AddLine(string.format("Total Crit: |cffffff00%.1f%%|r", maxCrit))
        GameTooltip:AddLine(" ")

        AddGroupedSchoolLines(GameTooltip, values, relevant, true)

        GameTooltip:Show()
    end)

    statFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    if _G.FluxInfoFrame and _G.FluxInfoFrame.HookClassicCSCStatFrame then
        _G.FluxInfoFrame.HookClassicCSCStatFrame(statFrame)
    end
end)

-- ======================================
-- ========== SPELL HIT =================
-- ======================================

local function ApplyFluxSpellHitDisplay(statFrame, unit)
    local maxVal, topSchool, values, relevant = BuildSpellHitData(unit)
    local color = GetDisplayColorForTop(values, relevant, maxVal, true)

    statFrame.Value:SetText(
        string.format("|cff%s%.1f%%|r|cffffffff/%d%%|r", color, maxVal, CSC_SPELL_HIT_CAP)
    )

    statFrame.Label:SetText("Hit:")

    statFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Hit", 1, 1, 1)
        GameTooltip:AddLine(string.format("Current: |cffffff00%.1f%%|r / |cffffff00%d%%|r", maxVal, CSC_SPELL_HIT_CAP))
        GameTooltip:AddLine(" ")

        AddGroupedSchoolLines(GameTooltip, values, relevant, true)

        GameTooltip:Show()
    end)

    statFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    if _G.FluxInfoFrame and _G.FluxInfoFrame.HookClassicCSCStatFrame then
        _G.FluxInfoFrame.HookClassicCSCStatFrame(statFrame)
    end
end

SafeHookByName("CSC_PaperDollFrame_SetSpellHitChance", function(statFrame, unit)
    ApplyFluxSpellHitDisplay(statFrame, unit)
end)

SafeHookByName("CSC_PaperDollFrame_SetHitRating", function(statFrame, unit, ratingIndex)
    if ratingIndex == CR_HIT_SPELL then
        ApplyFluxSpellHitDisplay(statFrame, unit)
    end
end)

-- ======================================
-- ====== CAST SPEED (REPLACES HEALING) =
-- ======================================

local CastSpeedScanner = CreateFrame("GameTooltip", "CSC_CastSpeedScanner", nil, "GameTooltipTemplate")
CastSpeedScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function GetCastSpeedStats()
    local gearPercent = 0
    local buffPercent = 0
    local multiplier = 1

    -- =========================
    -- Scan Gear
    -- =========================
    for slot = 1, 18 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            CastSpeedScanner:ClearLines()
            CastSpeedScanner:SetHyperlink(itemLink)

            for i = 2, CastSpeedScanner:NumLines() do
                local line = _G["CSC_CastSpeedScannerTextLeft" .. i]
                if line then
                    local text = line:GetText()
                    if text then
                        local lower = text:lower()

                        -- Avoid counting on-use tooltip lines as passive haste
                        if not lower:find("^use:") then
                            local value = lower:match("increases your casting speed by ([%d%.]+)%%")
                            if value then
                                local v = tonumber(value)
                                if v then
                                    gearPercent = gearPercent + v
                                    multiplier = multiplier * (1 + v / 100)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- =========================
    -- Scan Buffs
    -- =========================
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if not spellId then break end

        if spellId == 467141 then
            buffPercent = buffPercent + 33
            multiplier = multiplier * 1.33
        elseif spellId == 1219557 then
            buffPercent = buffPercent + 2
            multiplier = multiplier * 1.02
        elseif spellId == 425121 then
            buffPercent = buffPercent + 20
            multiplier = multiplier * 1.20
        elseif spellId == 1218695 then
            buffPercent = buffPercent + 10
            multiplier = multiplier * 1.10
        end
    end

    local totalIncrease = gearPercent + buffPercent
    local reduction = (1 - (1 / multiplier)) * 100

    return totalIncrease, reduction
end

if module.isClassicEra then
    SafeHookByName("CSC_PaperDollFrame_SetHealing", function(statFrame)
        if not statFrame then return end

        local totalIncrease, reduction = GetCastSpeedStats()

        statFrame.Value:SetText(string.format("|cffffffff%.1f%%|r", totalIncrease))
        statFrame.Label:SetText("Haste:")

        statFrame.numericValue = totalIncrease
        statFrame.tooltip = nil
        statFrame.tooltip2 = nil

        statFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Haste", 1, 1, 1)
            GameTooltip:AddLine(string.format("Total Increase: |cffffff00%.1f%%|r", totalIncrease))
            GameTooltip:AddLine(string.format("Cast Time Reduction: |cffffff00%.1f%%|r", reduction))
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Formula: multiplicative scaling", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)

        statFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        if _G.FluxInfoFrame and _G.FluxInfoFrame.HookClassicCSCStatFrame then
            _G.FluxInfoFrame.HookClassicCSCStatFrame(statFrame)
        end
    end)
end

-- Expose calculation helpers so InfoFrame can produce matching values/colors
-- without reading from the character panel UI elements.
_G.CSC_InfoFrame_BuildSpellPowerData    = BuildSpellPowerData
_G.CSC_InfoFrame_BuildSpellHitData      = BuildSpellHitData
_G.CSC_InfoFrame_GetCastSpeedStats      = GetCastSpeedStats
_G.CSC_InfoFrame_GetDisplayColorForTop  = GetDisplayColorForTop


