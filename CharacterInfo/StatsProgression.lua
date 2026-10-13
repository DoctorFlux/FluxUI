-- Merged TBC/Wrath (Progression) Character Stats (was Progression/CharacterStatsTbc*.lua)
local addonName, ns = ...
local module = ns.CharacterStats
if not (module and module.isProgression) then return end

-- TBC+ character sheet: use "Haste" (not global SPELL_HASTE / haste-rating wording)
local CSC_HASTE_LABEL = "Haste"
-- Retail (Dragonflight+): one Critical Strike and one Haste rating; labels differ from melee/spell split.
local CSC_CRIT_LABEL_UNIFIED = module.isRetail and "Crit" or (_G.STAT_CRITICAL_STRIKE or _G.COMBAT_RATING_NAME11 or "Critical Strike")

local function CSC_UseUnifiedSecondaryStats()
	return module.isRetail;
end

local function CSC_CritCombatRatingIndex()
	if (CSC_UseUnifiedSecondaryStats() and rawget(_G, "CR_CRIT_SPELL")) then
		return CR_CRIT_SPELL;
	end
	return CR_CRIT_MELEE;
end

local function CSC_HasteCombatRatingIndexForContext(meleeIdx, rangedIdx)
	if (CSC_UseUnifiedSecondaryStats() and rawget(_G, "CR_HASTE_SPELL")) then
		return CR_HASTE_SPELL;
	end
	if (rangedIdx and meleeIdx ~= rangedIdx) then
		return rangedIdx;
	end
	return meleeIdx;
end

-- Retail removed several classic stat tooltip APIs; avoid calling nil.
local function CSC_SafeGetAttackPowerForStat(statIndex, effectiveStat)
	if (type(GetAttackPowerForStat) == "function") then
		return GetAttackPowerForStat(statIndex, effectiveStat);
	end
	return 0;
end

local function CSC_SafeGetCritChanceFromAgility(unit)
	if (type(GetCritChanceFromAgility) == "function") then
		return GetCritChanceFromAgility(unit);
	end
	return 0;
end

local function CSC_SafeGetSpellCritChanceFromIntellect(unit)
	if (type(GetSpellCritChanceFromIntellect) == "function") then
		return GetSpellCritChanceFromIntellect(unit);
	end
	return 0;
end

local function CSC_SafeGetUnitMaxHealthModifier(unit)
	if (type(GetUnitMaxHealthModifier) == "function") then
		return GetUnitMaxHealthModifier(unit);
	end
	return 1;
end

local function CSC_SafeGetUnitHealthRegenRateFromSpirit(unit)
	if (type(GetUnitHealthRegenRateFromSpirit) == "function") then
		return GetUnitHealthRegenRateFromSpirit(unit);
	end
	return 0;
end

local function CSC_SafeGetUnitManaRegenRateFromSpirit(unit)
	if (type(GetUnitManaRegenRateFromSpirit) == "function") then
		return GetUnitManaRegenRateFromSpirit(unit);
	end
	return 0;
end

--- Classic PaperDoll constants are not defined on Dragonflight+; use 0 when missing (tooltip may omit effect).
local function CSC_SafeGlobalNumber(name, fallback)
	local v = rawget(_G, name);
	if (type(v) == "number") then
		return v;
	end
	return fallback or 0;
end

-- Retail enUS abbreviates some secondaries ("M.Crit", "S.Haste"); strip M./S./R. only for crit/haste lines.
local function CSC_RetailStripMsrAbbrevPrefix(label)
	if (not module.isRetail or type(label) ~= "string") then
		return label;
	end
	local rest = strmatch(label, "^%s*[MSR]%s*%.%s*(.+)$");
	if (rest) then
		rest = gsub(gsub(rest, "^%s+", ""), "%s+$", "");
		local lower = strlower(rest);
		if (rest ~= "" and (strfind(lower, "crit", 1, true) or strfind(lower, "haste", 1, true))) then
			return rest;
		end
	end
	return label;
end

-- Section: CharacterStatsTbcConstants.lua

__DEBUG__ = false;

-- Class ids
CSC_WARRIOR_CLASS_ID 		= 1;
CSC_PALADIN_CLASS_ID 		= 2;
CSC_HUNTER_CLASS_ID 		= 3;
CSC_ROGUE_CLASS_ID 			= 4;
CSC_PRIEST_CLASS_ID 		= 5;
CSC_DEATHKNIGHT_CLASS_ID 	= 6;
CSC_SHAMAN_CLASS_ID 		= 7;
CSC_MAGE_CLASS_ID 			= 8;
CSC_WARLOCK_CLASS_ID 		= 9;
CSC_MONK_CLASS_ID 			= 10;
CSC_DRUID_CLASS_ID 			= 11;
CSC_DEMONHUNTER_CLASS_ID 	= 12;

-- Combat ratings
CSC_COMBAT_RATING_EXPERTISE     = 1;
CSC_COMBAT_RATING_HASTE         = 2;
CSC_COMBAT_RATING_SPELL_HASTE   = 3;
CSC_COMBAT_RATING_HIT           = 4;
CSC_COMBAT_RATING_SPELL_HIT     = 5;
CSC_COMBAT_RATING_CRIT          = 6;
CSC_COMBAT_RATING_SPELL_CRIT    = 7;
CSC_COMBAT_RATING_DEFENSE       = 8;
CSC_COMBAT_RATING_DODGE         = 9;
CSC_COMBAT_RATING_PARRY         = 10;
CSC_COMBAT_RATING_BLOCK         = 11;

-- Weapon IDs
CSC_LE_ITEM_WEAPON_AXE1H    = 0;
CSC_LE_ITEM_WEAPON_AXE2H    = 1;
CSC_LE_ITEM_WEAPON_MACE1H   = 4;
CSC_LE_ITEM_WEAPON_MACE2H   = 5;
CSC_LE_ITEM_WEAPON_POLEARM  = 6;
CSC_LE_ITEM_WEAPON_SWORD1H  = 7;
CSC_LE_ITEM_WEAPON_SWORD2H  = 8;
CSC_LE_ITEM_WEAPON_STAFF    = 10;
CSC_LE_ITEM_WEAPON_UNARMED  = 13;
CSC_LE_ITEM_WEAPON_DAGGER   = 15;
CSC_LE_ITEM_WEAPON_BOWS     = 2;
CSC_LE_ITEM_WEAPON_CROSSBOW = 18;
CSC_LE_ITEM_WEAPON_GUNS     = 3;

g_WeaponStringByWeaponId = {
	[CSC_LE_ITEM_WEAPON_AXE1H] 		= CSC_WEAPON_AXE1H_TXT,
	[CSC_LE_ITEM_WEAPON_AXE2H] 		= CSC_WEAPON_AXE2H_TXT,
	[CSC_LE_ITEM_WEAPON_MACE1H] 	= CSC_WEAPON_MACE1H_TXT,
	[CSC_LE_ITEM_WEAPON_MACE2H] 	= CSC_WEAPON_MACE2H_TXT,
	[CSC_LE_ITEM_WEAPON_POLEARM] 	= CSC_WEAPON_POLEARM_TXT,
	[CSC_LE_ITEM_WEAPON_SWORD1H] 	= CSC_WEAPON_SWORD1H_TXT,
	[CSC_LE_ITEM_WEAPON_SWORD2H] 	= CSC_WEAPON_SWORD2H_TXT,
	[CSC_LE_ITEM_WEAPON_STAFF] 		= CSC_WEAPON_STAFF_TXT,
	[CSC_LE_ITEM_WEAPON_UNARMED] 	= CSC_WEAPON_UNARMED_TXT,
    [CSC_LE_ITEM_WEAPON_DAGGER] 	= CSC_WEAPON_DAGGER_TXT,
    [CSC_LE_ITEM_WEAPON_BOWS]       = CSC_WEAPON_BOW_TXT,
    [CSC_LE_ITEM_WEAPON_CROSSBOW]   = CSC_WEAPON_CROSSBOW_TXT,
    [CSC_LE_ITEM_WEAPON_GUNS]       = CSC_WEAPON_GUN_TXT
};

g_CombatRatingBaseValues = {
    [CSC_COMBAT_RATING_EXPERTISE]     = 2.5,
    [CSC_COMBAT_RATING_HASTE]         = 10,
    [CSC_COMBAT_RATING_SPELL_HASTE]   = 10,
    [CSC_COMBAT_RATING_HIT]           = 10,
    [CSC_COMBAT_RATING_SPELL_HIT]     = 8,
    [CSC_COMBAT_RATING_CRIT]          = 14,
    [CSC_COMBAT_RATING_SPELL_CRIT]    = 14,
    [CSC_COMBAT_RATING_DEFENSE]       = 1.5,
    [CSC_COMBAT_RATING_DODGE]         = 12,
    [CSC_COMBAT_RATING_PARRY]         = 15,
    [CSC_COMBAT_RATING_BLOCK]         = 5
};

-- Class set items IDs
g_BattlegearOfMightIds = { 
    [16861] = 16861, 
    [16862] = 16862, 
    [16863] = 16863, 
    [16864] = 16864, 
    [16865] = 16865, 
    [16866] = 16866, 
    [16867] = 16867, 
    [16868] = 16868
};

g_VestmentsOfTranscendenceIds = {
    [16925] = 16925, 
    [16926] = 16926, 
    [16919] = 16919, 
    [16921] = 16921, 
    [16920] = 16920, 
    [16922] = 16922, 
    [16924] = 16924, 
    [16923] = 16923,
};

g_StormrageRaimentIds = {
    [16897] = 16897, 
    [16898] = 16898, 
    [16899] = 16899, 
    [16900] = 16900, 
    [16901] = 16901, 
    [16902] = 16902, 
    [16903] = 16903, 
    [16904] = 16904,
};

g_TheTenStormsIds = {
    [16943] = 16943, 
    [16944] = 16944, 
    [16945] = 16945, 
    [16946] = 16946, 
    [16947] = 16947, 
    [16948] = 16948, 
    [16949] = 16949, 
    [16950] = 16950
};

g_PrimalMooncloth = {
    [21875] = 21875, 
    [21874] = 21874, 
    [21873] = 21873
};

g_AuraIdToMp5 = {
	-- BOW
	[19742] = 10,
	[19850] = 15,
	[19852] = 20,
	[19853] = 25,
	[19854] = 30,
    [25290] = 33,
    [27142] = 41,
	-- GBOW
	[25894] = 30,
    [25918] = 33,
    [27143] = 41,
	-- Mana Spring Totem
	[5675] = 10,
	[10495] = 15,
	[10496] = 20,
	[10497] = 25,
	-- Mageblood potion
	[24363] = 12,
	--Nightfin Soup
	[18194] = 8
};
  
g_CombatManaRegenSpellIdToModifier = {
    -- Mage Armor
    [6117] = 0.3,
    [22782] = 0.3,
    [22783] = 0.3
};

g_ArgentDawnAPItems = {
    -- Chests
    [23087] = 81, -- Plate
    [23088] = 81, -- Mail
    [23089] = 81, -- Leather
    -- Gloves
    [23078] = 60, -- Plate
    [23082] = 60, -- Mail
    [23081] = 60, -- Leather
    -- Bracers
    [23090] = 45, -- Plate
    [23092] = 45, -- Mail
    [23093] = 45, -- Leather
    -- Trinkets
    [13209] = 81, -- Seal of the Dawn
    [23206] = 150 -- Mark of the Champion AP
}

g_ArgentDawnSPItems = {
    -- SP cloth set
    [23085] = 48, -- Chest
    [23091] = 26, -- Bracers
    [23084] = 35, -- Gloves
    -- Trinkets
    [19812] = 48, -- Rune of the Dawn 
    [23207] = 85 -- Mark of the Champion SP
}

CSC_SYMBOL_TAB   = "    "; -- for some reason "\t" doesn't work
CSC_SYMBOL_SPACE = " ";
                                

-- Section: CharacterStatsTbcUI.lua

local core = module.core
core.UIConfig = {};

-- Defaults
UISettingsGlobal = {
    useBlizzardBlockValue = false;
    statsPanelHidden = false;
    showPaperDollItemLevel = true;
}

UISettingsCharacter = {
    selectedLeftStatsCategory = 1;
    selectedRightStatsCategory = 2;
    showStatsFromArgentDawnItems = true;
    -- side panel stats options
    sideStatsFrameHidden = false;
    showSideStatsMelee = true;
    showSideStatsRanged = true;
    showSideStatsSpell = true;
    showSideStatsDefense = true;
}

-- for easier referencing the core config
local UIConfig = core.UIConfig;
local CSC_UIFrame = core.UIConfig;

local statsDropdownList = {
    PLAYERSTAT_BASE_STATS,
    PLAYERSTAT_MELEE_COMBAT,
    PLAYERSTAT_RANGED_COMBAT,
    PLAYERSTAT_SPELL_COMBAT,
    PLAYERSTAT_DEFENSES
}

local MAX_STAT_FRAMES = 7
local STATS_VISIBLE_BY_CATEGORY = {
    [PLAYERSTAT_BASE_STATS] = 6,
    [PLAYERSTAT_DEFENSES] = 6,
    [PLAYERSTAT_MELEE_COMBAT] = 7,
    [PLAYERSTAT_RANGED_COMBAT] = 6,
    [PLAYERSTAT_SPELL_COMBAT] = 6,
}
local LeftStatsTable = { }
local RightStatsTable = { }

local SideCategoryStatsMelee = { 
    frames = { };
    numFrames = 7;
    frameLabel = "Melee";
};
local SideCategoryStatsRanged = {
    frames = { };
    numFrames = 7;
    frameLabel = "Ranged";
};
local SideCategoryStatsSpell = { 
    frames = { };
    numFrames = 5;
    frameLabel = "Spell";
};
local SideCategoryStatsDefense = {
    frames = { };
    numFrames = 10;
    frameLabel = "Defense";
};

local function CSC_ResetStatFrames(statFrames)
    for i = 1, MAX_STAT_FRAMES, 1 do
        local f = statFrames[i]
        if f then
            f:Hide();
            f:SetScript("OnEnter", f.OnEnterCallback);
            f.tooltip = nil;
            f.tooltip2 = nil;
            f.tooltip3 = nil;
            f._FluxArmorPenKind = nil;
        end
    end
end

local function CSC_ShowStatFrames(statFrames, category)
    local statsToShow = STATS_VISIBLE_BY_CATEGORY[category] or MAX_STAT_FRAMES

    for i = 1, statsToShow, 1 do
        local f = statFrames[i]
        if f then
            f:Show();
        end
    end
end

--- Melee uses 7 paper rows; tighter spacing + panel nudge keeps the last row off leg/feet slots.
local function CSC_PaperStatsNeedsCompactRowLayout()
    local leftCat = statsDropdownList[UISettingsCharacter.selectedLeftStatsCategory];
    local rightCat = statsDropdownList[UISettingsCharacter.selectedRightStatsCategory];
    return (STATS_VISIBLE_BY_CATEGORY[leftCat] == 7) or (STATS_VISIBLE_BY_CATEGORY[rightCat] == 7);
end

function UIConfig:LayoutPaperStatRows()
    local panel = CSC_UIFrame.CharacterStatsPanel;
    if (not panel or not LeftStatsTable[1]) then return end
    local leftParent = panel.leftStatsDropDown;
    local rightParent = panel.rightStatsDropDown;
    if (not leftParent or not rightParent) then return end

    local compact = CSC_PaperStatsNeedsCompactRowLayout();
    local offsetStepY = compact and 13 or 15;
    local accumulatedOffsetY = 0;
    for i = 1, MAX_STAT_FRAMES do
        accumulatedOffsetY = accumulatedOffsetY + offsetStepY;
        local actualOffset = accumulatedOffsetY;
        if (i == 1) then
            actualOffset = 32;
            accumulatedOffsetY = 32;
        end
        LeftStatsTable[i]:SetPoint("LEFT", leftParent, "TOPLEFT", 20, -actualOffset);
        RightStatsTable[i]:SetPoint("LEFT", rightParent, "TOPLEFT", 20, -actualOffset);
    end

    if (__DEBUG__) then return end
    local cf = _G.CharacterFrame
    if not cf then return end
    local offsetX = 50;
    local baseY = 85;
    local bump = compact and 18 or 0;
    panel:ClearAllPoints();
    panel:SetPoint("LEFT", cf, "BOTTOMLEFT", offsetX, baseY + bump);
end

function UIConfig:InitializeStatsFrames(leftParentFrame, rightParentFrame)
    local function createPaperStatRow(parent)
        if (module.isRetail) then
            local f = CreateFrame("Frame", nil, parent)
            f:SetSize(110, 16)
            f:EnableMouse(true)
            f.Label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            f.Label:SetPoint("LEFT", f, "LEFT", 0, 0)
            f.Label:SetJustifyH("LEFT")
            f.Value = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            f.Value:SetPoint("RIGHT", f.Label, "RIGHT", 0, 0)
            f.Value:SetJustifyH("RIGHT")
            f.OnEnterCallback = nil
            return f
        end
        local f = CreateFrame("Frame", nil, parent, "StatFrameTemplate")
        f:SetWidth(110)
        f.OnEnterCallback = f:GetScript("OnEnter")
        f.Value = f:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
        f.Value:SetPoint("RIGHT", f.Label, "RIGHT", 0, 0)
        f.Value:SetJustifyH("RIGHT")
        return f
    end

    for i = 1, MAX_STAT_FRAMES do
        LeftStatsTable[i] = createPaperStatRow(leftParentFrame)
        RightStatsTable[i] = createPaperStatRow(rightParentFrame)
    end
    UIConfig:LayoutPaperStatRows();
end

function UIConfig:SetCharacterStats(statsTable, category)
    if not statsTable or not statsTable[1] then
        return
    end

    CSC_ResetStatFrames(statsTable);

    local unit = "player";

    if category == PLAYERSTAT_BASE_STATS then
        CSC_PaperDollFrame_SetPrimaryStats(statsTable, unit);
        CSC_PaperDollFrame_SetArmor(statsTable[6], unit);
    elseif category == PLAYERSTAT_DEFENSES then
        CSC_PaperDollFrame_SetArmor(statsTable[1], unit);
        CSC_PaperDollFrame_SetDefense(statsTable[2], unit);
        CSC_PaperDollFrame_SetDodge(statsTable[3]);
        CSC_PaperDollFrame_SetParry(statsTable[4]);
        CSC_PaperDollFrame_SetBlock(statsTable[5], unit);
        CSC_PaperDollFrame_SetResilience(statsTable[6]);
    elseif category == PLAYERSTAT_MELEE_COMBAT then
        if (UISettingsCharacter.showStatsFromArgentDawnItems) then
            CSC_CacheAPFromADItems(unit);
        end
        
        CSC_PaperDollFrame_SetDamage(statsTable[1], unit, category);
        CSC_PaperDollFrame_SetMeleeAttackPower(statsTable[2], unit);
        CSC_PaperDollFrame_SetAttackSpeed(statsTable[3], unit);
        CSC_PaperDollFrame_SetCritChance(statsTable[4], unit);
        CSC_PaperDollFrame_SetHitRating(statsTable[5], unit, CR_HIT_MELEE);
        CSC_PaperDollFrame_SetExpertise(statsTable[6], unit);
        CSC_PaperDollFrame_SetPaperArmorPenetration(statsTable[7], unit, false);
    elseif category == PLAYERSTAT_RANGED_COMBAT then
        if (UISettingsCharacter.showStatsFromArgentDawnItems) then
            CSC_CacheAPFromADItems(unit);
        end
        CSC_PaperDollFrame_SetDamage(statsTable[1], unit, category);
        CSC_PaperDollFrame_SetRangedAttackPower(statsTable[2], unit);
        CSC_PaperDollFrame_SetRangedAttackSpeed(statsTable[3], unit);
        CSC_PaperDollFrame_SetRangedCritChance(statsTable[4], unit);
        CSC_PaperDollFrame_SetHitRating(statsTable[5], unit, CR_HIT_RANGED);
        CSC_PaperDollFrame_SetPaperArmorPenetration(statsTable[6], unit, true);
    elseif category == PLAYERSTAT_SPELL_COMBAT then
        CSC_PaperDollFrame_SetSpellPower(statsTable[1], unit);
        CSC_PaperDollFrame_SetManaRegen(statsTable[2], unit);
        CSC_PaperDollFrame_SetSpellCritChance(statsTable[3], unit);
        CSC_PaperDollFrame_SetHitRating(statsTable[4], unit, CR_HIT_SPELL);
        CSC_PaperDollFrame_SetSpellHaste(statsTable[5]);
        CSC_PaperDollFrame_SetPaperSpellPenetration(statsTable[6], unit);
    end

    CSC_ShowStatFrames(statsTable, category);
end

function UIConfig:InitializeSideStatsCategory(frameObject, accumulatedOffsetY, offsetStepY)
    local accumulatedOffset = accumulatedOffsetY;
    local numFrames = frameObject.numFrames;

    for i = 1, numFrames do
        accumulatedOffset = accumulatedOffset + offsetStepY;
        local actualOffset = accumulatedOffset;

        frameObject.frames[i] = CreateFrame("Frame", nil, CSC_UIFrame.SideStatsFrame.ScrollChild, "StatFrameTemplate");
        frameObject.frames[i]:SetPoint("LEFT", CSC_UIFrame.SideStatsFrame.ScrollChild, "TOPLEFT", 50, -actualOffset);
        frameObject.frames[i]:SetWidth(140);
        frameObject.frames[i].Value = frameObject.frames[i]:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall");
        frameObject.frames[i].Value:SetPoint("RIGHT", frameObject.frames[i].Label, "RIGHT", 0, 0);
        frameObject.frames[i].Value:SetJustifyH("RIGHT");
        
        if i == 1 then
            frameObject.frames[i].Label = frameObject.frames[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frameObject.frames[i].Label:SetText(frameObject.frameLabel)
            frameObject.frames[i].Label:SetTextColor(1, 1, 1)
            frameObject.frames[i].Label:SetPoint("CENTER", 0, 0)

            frameObject.frames[i].BackgroundTex = frameObject.frames[i]:CreateTexture(nil, "ARTWORK");
            frameObject.frames[i].BackgroundTex:SetAllPoints(frameObject.frames[i]);
            frameObject.frames[i].BackgroundTex:SetTexture("Interface\\PaperDollInfoFrame\\PaperDollInfoPart1");
            frameObject.frames[i].BackgroundTex:SetTexCoord(0, 0.193359375, 0.69921875, 0.736328125);
        else
            frameObject.frames[i].BackgroundTex = frameObject.frames[i]:CreateTexture(nil, "BACKGROUND");
            frameObject.frames[i].BackgroundTex:SetAllPoints(frameObject.frames[i]);
            local alpha = 0;
            if i % 2 == 0 then alpha = 0.3 end
            frameObject.frames[i].BackgroundTex:SetColorTexture(0.3, 0.2, 0, alpha);
        end
    end
    accumulatedOffset = accumulatedOffset + 10;
    
    return accumulatedOffset;
end

function UIConfig:InitializeSideStatsCategories()
    local offsetStepY = 15;
    local accumulatedOffsetY = 0;
    
    if UISettingsCharacter.showSideStatsMelee then
        accumulatedOffsetY = UIConfig:InitializeSideStatsCategory(SideCategoryStatsMelee, accumulatedOffsetY, offsetStepY);
    end

    if UISettingsCharacter.showSideStatsRanged then
        accumulatedOffsetY = UIConfig:InitializeSideStatsCategory(SideCategoryStatsRanged, accumulatedOffsetY, offsetStepY);
    end

    if UISettingsCharacter.showSideStatsSpell then
        accumulatedOffsetY = UIConfig:InitializeSideStatsCategory(SideCategoryStatsSpell, accumulatedOffsetY, offsetStepY);
    end

    if UISettingsCharacter.showSideStatsDefense then
        accumulatedOffsetY = UIConfig:InitializeSideStatsCategory(SideCategoryStatsDefense, accumulatedOffsetY, offsetStepY);
    end
end

function UIConfig:SetCharacterSideStats()
    local unit = "player";

    -- frames[1] is reserved for the category label

    if UISettingsCharacter.showSideStatsMelee and SideCategoryStatsMelee.frames[1] then
        CSC_SideFrame_SetMeleeHitChance(SideCategoryStatsMelee.frames[2], unit);
        CSC_SideFrame_SetMissChance(SideCategoryStatsMelee.frames[3], unit, CR_HIT_MELEE);
        CSC_SideFrame_SetCritCap(SideCategoryStatsMelee.frames[4], unit, CR_HIT_MELEE);
        CSC_SideFrame_SetMeleeCritRating(SideCategoryStatsMelee.frames[5], unit);
        CSC_SideFrame_SetMeleeHasteRating(SideCategoryStatsMelee.frames[6], unit);
        CSC_SideFrame_SetArmorPenetration(SideCategoryStatsMelee.frames[7], unit, "melee");
    end

    if UISettingsCharacter.showSideStatsRanged and SideCategoryStatsRanged.frames[1] then
        CSC_SideFrame_SetRangedHitChance(SideCategoryStatsRanged.frames[2], unit);
        CSC_SideFrame_SetMissChance(SideCategoryStatsRanged.frames[3], unit, CR_HIT_RANGED);
        CSC_SideFrame_SetCritCap(SideCategoryStatsRanged.frames[4], unit, CR_HIT_RANGED);
        CSC_SideFrame_SetRangedCritRating(SideCategoryStatsRanged.frames[5], unit);
        CSC_SideFrame_SetRangedHasteRating(SideCategoryStatsRanged.frames[6], unit);
        CSC_SideFrame_SetArmorPenetration(SideCategoryStatsRanged.frames[7], unit, "ranged");
    end

    if UISettingsCharacter.showSideStatsSpell and SideCategoryStatsSpell.frames[1] then
        CSC_SideFrame_SetSpellHitChance(SideCategoryStatsSpell.frames[2], unit);
        CSC_SideFrame_SetSpellCritRating(SideCategoryStatsSpell.frames[3], unit);
        CSC_SideFrame_SetSpellHastePercent(SideCategoryStatsSpell.frames[4], unit);
        CSC_SideFrame_SetSpellPenetration(SideCategoryStatsSpell.frames[5], unit);
    end

    if UISettingsCharacter.showSideStatsDefense and SideCategoryStatsDefense.frames[1] then
        CSC_SideFrame_SetDefenseRating(SideCategoryStatsDefense.frames[2], unit);
        CSC_SideFrame_SetDefenseUncritableCap(SideCategoryStatsDefense.frames[3], unit);
        CSC_SideFrame_SetResilienceUncritableCap(SideCategoryStatsDefense.frames[4], unit);
        CSC_SideFrame_SetChanceToBeCrittedBy73(SideCategoryStatsDefense.frames[5], unit);
        CSC_SideFrame_SetChanceToBeCrittedBy70(SideCategoryStatsDefense.frames[6], unit);
        CSC_SideFrame_SetAvoidance(SideCategoryStatsDefense.frames[7], unit);
        CSC_SideFrame_SetDodgeRating(SideCategoryStatsDefense.frames[8], unit);
        CSC_SideFrame_SetParryRating(SideCategoryStatsDefense.frames[9], unit);
        CSC_SideFrame_SetBlockRating(SideCategoryStatsDefense.frames[10], unit);
    end
end

function UIConfig:InitializeSideStatsFrame()

    CSC_UIFrame.SideStatsFrame = CreateFrame("Frame", "CSC_SideStatsFrame", PaperDollItemsFrame, "BasicFrameTemplateWithInset");
    CSC_UIFrame.SideStatsFrame:SetSize(190, 423);
    CSC_UIFrame.SideStatsFrame:SetPoint("LEFT", PaperDollItemsFrame, "RIGHT", -30,  30);
    CSC_UIFrame.SideStatsFrame.title = CSC_UIFrame.SideStatsFrame:CreateFontString(nil, "OVERLAY");
    CSC_UIFrame.SideStatsFrame.title:SetFontObject("GameFontHighlight");
    CSC_UIFrame.SideStatsFrame.title:SetPoint("CENTER", CSC_UIFrame.SideStatsFrame.TitleBg, "CENTER", 0,  0);
    CSC_UIFrame.SideStatsFrame.title:SetText(module.settingsTitle);

    CSC_UIFrame.SideStatsFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, CSC_UIFrame.SideStatsFrame, "UIPanelScrollFrameTemplate");
    CSC_UIFrame.SideStatsFrame.ScrollFrame:SetPoint("TOPLEFT", CSC_UIFrame.SideStatsFrame, "TOPLEFT", -35, -30);
    CSC_UIFrame.SideStatsFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", CSC_UIFrame.SideStatsFrame, "BOTTOMRIGHT", -35, 10);

    CSC_UIFrame.SideStatsFrame.ScrollChild = CreateFrame("Frame", nil, CSC_UIFrame.SideStatsFrame.ScrollFrame);
    CSC_UIFrame.SideStatsFrame.ScrollChild:SetSize(200, 420);
    CSC_UIFrame.SideStatsFrame.ScrollFrame:SetScrollChild(CSC_UIFrame.SideStatsFrame.ScrollChild);
    --CSC_UIFrame.SideStatsFrame.ScrollFrame:SetScript("OnMouseWheel", function() end);

    CSC_UIFrame.SideStatsFrame.CloseButton:HookScript("OnClick", function()
        UISettingsCharacter.sideStatsFrameHidden = true;
    end)

    PaperDollItemsFrame:HookScript("OnShow", function()
       if UISettingsCharacter.sideStatsFrameHidden then
            CSC_UIFrame.SideStatsFrame:Hide();
       end
    end)

    UIConfig:InitializeSideStatsCategories();
end

function UIConfig:CreateMenu()
    if CSC_UIFrame.CharacterStatsPanel then
        return
    end

    local characterFrame = _G.CharacterFrame
    if not characterFrame then
        return
    end

    if not __DEBUG__ then
        -- Hide the default stats (frame does not exist on Dragonflight+ character UI)
        local caf = _G.CharacterAttributesFrame
        if caf and caf.Hide then
            caf:Hide()
        end
    end

    local offsetX = 50;
    local offsetY = 85;

    if __DEBUG__ then
        offsetY = -120;
    end

    CSC_UIFrame.CharacterStatsPanel = CreateFrame("Frame", nil, characterFrame); --CharacterFrameInsetRight
	CSC_UIFrame.CharacterStatsPanel:SetPoint("LEFT", characterFrame, "BOTTOMLEFT", offsetX, offsetY);
	CSC_UIFrame.CharacterStatsPanel:SetHeight(320);
    CSC_UIFrame.CharacterStatsPanel:SetWidth(200);

    UIConfig:SetupDropdown();

    UIConfig:InitializeStatsFrames(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown);
    local panel = CSC_UIFrame.CharacterStatsPanel
    _G.FluxUI_CSC_StatsParents = { left = panel.leftStatsDropDown, right = panel.rightStatsDropDown }
    UIConfig:UpdateStats();
end

function UIConfig:UpdateStats()
    if not LeftStatsTable[1] or not RightStatsTable[1] then
        return
    end
    UIConfig:SetCharacterStats(LeftStatsTable, statsDropdownList[UISettingsCharacter.selectedLeftStatsCategory]);
    UIConfig:SetCharacterStats(RightStatsTable, statsDropdownList[UISettingsCharacter.selectedRightStatsCategory]);
    UIConfig:LayoutPaperStatRows();
end

function UIConfig:UpdateSideStats()
    -- Side stats panel (CSC_SideStatsFrame) removed; keep function for callers.
end

local function OnClickLeftStatsDropdown(self)
    UISettingsCharacter.selectedLeftStatsCategory = self:GetID();
    UIDropDownMenu_SetSelectedID(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, UISettingsCharacter.selectedLeftStatsCategory);
    UIConfig:SetCharacterStats(LeftStatsTable, statsDropdownList[UISettingsCharacter.selectedLeftStatsCategory]);
    UIConfig:LayoutPaperStatRows();
end

local function OnClickRightStatsDropdown(self)
    UISettingsCharacter.selectedRightStatsCategory = self:GetID();
    UIDropDownMenu_SetSelectedID(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, UISettingsCharacter.selectedRightStatsCategory);
    UIConfig:SetCharacterStats(RightStatsTable, statsDropdownList[UISettingsCharacter.selectedRightStatsCategory]);
    UIConfig:LayoutPaperStatRows();
end

function UIConfig:InitializeLeftStatsDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo();
    for k,v in pairs(statsDropdownList) do
        info.text = v;
        info.func = OnClickLeftStatsDropdown;
        info.checked = false;
        UIDropDownMenu_AddButton(info, level);
     end
end

function UIConfig:InitializeRightStatsDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo();
    for k,v in pairs(statsDropdownList) do
        info.text = v;
        info.func = OnClickRightStatsDropdown;
        info.checked = false;
        UIDropDownMenu_AddButton(info, level);
     end
end

function UIConfig:SetupDropdown()

    CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown = CreateFrame("Frame", nil, CSC_UIFrame.CharacterStatsPanel, "UIDropDownMenuTemplate");
    CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown:SetPoint("TOPLEFT", CSC_UIFrame.CharacterStatsPanel, "TOPLEFT", 0, 0);

    CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown = CreateFrame("Frame", nil, CSC_UIFrame.CharacterStatsPanel, "UIDropDownMenuTemplate");
    CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown:SetPoint("TOPLEFT", CSC_UIFrame.CharacterStatsPanel, "TOPLEFT", 115, 0);

    UIDropDownMenu_Initialize(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, UIConfig.InitializeLeftStatsDropdown);
    UIDropDownMenu_SetSelectedID(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, UISettingsCharacter.selectedLeftStatsCategory);
    UIDropDownMenu_SetWidth(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, 99);
    UIDropDownMenu_JustifyText(CSC_UIFrame.CharacterStatsPanel.leftStatsDropDown, "LEFT");

    UIDropDownMenu_Initialize(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, UIConfig.InitializeRightStatsDropdown);
    UIDropDownMenu_SetSelectedID(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, UISettingsCharacter.selectedRightStatsCategory);
    UIDropDownMenu_SetWidth(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, 99);
    UIDropDownMenu_JustifyText(CSC_UIFrame.CharacterStatsPanel.rightStatsDropDown, "LEFT");
end

function UIConfig:ToggleSideStatsFrame()
    -- Side stats panel removed; no-op.
end

function UIConfig:SetStatsPanelVisibile(isVisible)
    UISettingsGlobal.statsPanelHidden = not isVisible;
end

-- Hook a custom function in order to extend the functionality of the default ToggleCharacter function
local function CSC_ToggleCharacterPostHook(tab, onlyShow)
    local panel = CSC_UIFrame.CharacterStatsPanel
    if not panel then
        return
    end
    if (tab == "PaperDollFrame") then
        if (not UISettingsGlobal.statsPanelHidden) then
            panel:Show();
            CSC_UIFrame:UpdateStats();
        end
        CSC_UIFrame:UpdateSideStats();
    else
        panel:Hide();
    end
end
if not module.isRetail then
    if type(hooksecurefunc) == "function" and type(_G.ToggleCharacter) == "function" then
        hooksecurefunc("ToggleCharacter", CSC_ToggleCharacterPostHook);
    end
end

-- Serializing the DB
local function SerializeGlobalDatabase()
    local db = module.GetGlobalDB()

    if (db.useBlizzardBlockValue == nil) then
        db.useBlizzardBlockValue = UISettingsGlobal.useBlizzardBlockValue;
    else
        UISettingsGlobal.useBlizzardBlockValue = db.useBlizzardBlockValue;
    end

    -- Stats frame visibility
    if (db.statsPanelHidden == nil) then
        db.statsPanelHidden = UISettingsGlobal.statsPanelHidden;
    else
        UISettingsGlobal.statsPanelHidden = db.statsPanelHidden;
    end

    if (db.showPaperDollItemLevel == nil) then
        db.showPaperDollItemLevel = UISettingsGlobal.showPaperDollItemLevel;
    else
        UISettingsGlobal.showPaperDollItemLevel = db.showPaperDollItemLevel;
    end
end

local function SerializeCharacterDatabase()
    local db = module.GetCharacterDB()

    -- Left dropdown category
    if (db.selectedLeftStatsCategory == nil) then
        db.selectedLeftStatsCategory = UISettingsCharacter.selectedLeftStatsCategory;
    else
        UISettingsCharacter.selectedLeftStatsCategory = db.selectedLeftStatsCategory;
    end

    -- Right dropdown category
    if (db.selectedRightStatsCategory == nil) then
        db.selectedRightStatsCategory = UISettingsCharacter.selectedRightStatsCategory;
    else
        UISettingsCharacter.selectedRightStatsCategory = db.selectedRightStatsCategory;
    end

    -- Stats from AD items checkbox
    if (db.showStatsFromArgentDawnItems == nil) then
        db.showStatsFromArgentDawnItems = UISettingsCharacter.showStatsFromArgentDawnItems;
    else
        UISettingsCharacter.showStatsFromArgentDawnItems = db.showStatsFromArgentDawnItems;
    end

    -- Side Stats frame status
    if (db.sideStatsFrameHidden == nil) then
        db.sideStatsFrameHidden = UISettingsCharacter.sideStatsFrameHidden;
    else
        UISettingsCharacter.sideStatsFrameHidden = db.sideStatsFrameHidden;
    end

    -- Side Stats frame category visibilities
    if (db.showSideStatsMelee == nil) then
        db.showSideStatsMelee = UISettingsCharacter.showSideStatsMelee;
    else
        UISettingsCharacter.showSideStatsMelee = db.showSideStatsMelee;
    end
    if (db.showSideStatsRanged == nil) then
        db.showSideStatsRanged = UISettingsCharacter.showSideStatsRanged;
    else
        UISettingsCharacter.showSideStatsRanged = db.showSideStatsRanged;
    end
    if (db.showSideStatsSpell == nil) then
        db.showSideStatsSpell = UISettingsCharacter.showSideStatsSpell;
    else
        UISettingsCharacter.showSideStatsSpell = db.showSideStatsSpell;
    end
    if (db.showSideStatsDefense == nil) then
        db.showSideStatsDefense = UISettingsCharacter.showSideStatsDefense;
    else
        UISettingsCharacter.showSideStatsDefense = db.showSideStatsDefense;
    end
end

local function PersistSettings()
    local globalDB = module.GetGlobalDB()
    local charDB = module.GetCharacterDB()

    globalDB.useBlizzardBlockValue = UISettingsGlobal.useBlizzardBlockValue
    globalDB.statsPanelHidden = UISettingsGlobal.statsPanelHidden
    globalDB.showPaperDollItemLevel = UISettingsGlobal.showPaperDollItemLevel

    charDB.selectedLeftStatsCategory = UISettingsCharacter.selectedLeftStatsCategory
    charDB.selectedRightStatsCategory = UISettingsCharacter.selectedRightStatsCategory
    charDB.showStatsFromArgentDawnItems = UISettingsCharacter.showStatsFromArgentDawnItems
    charDB.sideStatsFrameHidden = UISettingsCharacter.sideStatsFrameHidden
    charDB.showSideStatsMelee = UISettingsCharacter.showSideStatsMelee
    charDB.showSideStatsRanged = UISettingsCharacter.showSideStatsRanged
    charDB.showSideStatsSpell = UISettingsCharacter.showSideStatsSpell
    charDB.showSideStatsDefense = UISettingsCharacter.showSideStatsDefense
end

local dbLoader = CreateFrame("Frame");
dbLoader:RegisterEvent("ADDON_LOADED");
dbLoader:RegisterEvent("PLAYER_LOGOUT");
dbLoader:RegisterEvent("PLAYER_LOGIN");

local cscCharacterStatsMenuInitialized = false

local function TryCreateCharacterStatsMenu()
    -- Retail idle FPS: Blizzard CharacterStatsPane + RetailPane + InfoFrame cover stats.
    -- Skip classic CSC dropdown panel creation on mainline / Forever.
    if module.isRetail or not module.useCscPanel then
        _G.FluxCSC_RetailPanelSkipped = true
        return
    end
    _G.FluxCSC_RetailPanelSkipped = false
    if cscCharacterStatsMenuInitialized or not _G.CharacterFrame then
        return
    end
    UIConfig:CreateMenu()
    if CSC_UIFrame.CharacterStatsPanel then
        cscCharacterStatsMenuInitialized = true
    end
end

function module.InstallClassicStatsPanel()
    TryCreateCharacterStatsMenu()
    return CSC_UIFrame.CharacterStatsPanel ~= nil
end

-- ADDON_LOADED is called after the code of the addon is being executed
-- Therefore I have to call any setup-functions dependent on the DB after the event (UIConfig:SetupDropdown())
function dbLoader:OnEvent(event, arg1)
    if (event == "ADDON_LOADED" and arg1 == addonName) then
        SerializeGlobalDatabase();
        SerializeCharacterDatabase();
        TryCreateCharacterStatsMenu();
    elseif (event == "ADDON_LOADED" and module.IsCharacterUiAddon and module.IsCharacterUiAddon(arg1)) then
        TryCreateCharacterStatsMenu();
    elseif (event == "PLAYER_LOGIN") then
        TryCreateCharacterStatsMenu();
    elseif (event == "PLAYER_LOGOUT") then
        PersistSettings();
    end
end

dbLoader:SetScript("OnEvent", dbLoader.OnEvent);
-- Serializing the DB

-- Section: CharacterStatsTbcMain.lua
-- Retail idle FPS: do not register UNIT_AURA / rating spam for CSC panel (panel not created on retail).
-- InfoFrame keeps its own RequestStatRefresh events for pinned HUD stats.

if not module.isRetail then
local CharacterStatsTbcFrame = CreateFrame("Frame");
CharacterStatsTbcFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
CharacterStatsTbcFrame:RegisterEvent("UNIT_AURA");
CharacterStatsTbcFrame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
CharacterStatsTbcFrame:RegisterEvent("SKILL_LINES_CHANGED");
CharacterStatsTbcFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
CharacterStatsTbcFrame:RegisterEvent("UNIT_DAMAGE");
CharacterStatsTbcFrame:RegisterEvent("UNIT_ATTACK_SPEED");
CharacterStatsTbcFrame:RegisterEvent("UNIT_RANGEDDAMAGE");
CharacterStatsTbcFrame:RegisterEvent("UNIT_ATTACK");
CharacterStatsTbcFrame:RegisterEvent("UNIT_RESISTANCES");
CharacterStatsTbcFrame:RegisterEvent("UNIT_STATS");
CharacterStatsTbcFrame:RegisterEvent("UNIT_MAXHEALTH");
CharacterStatsTbcFrame:RegisterEvent("UNIT_ATTACK_POWER");
CharacterStatsTbcFrame:RegisterEvent("UNIT_RANGED_ATTACK_POWER");
CharacterStatsTbcFrame:RegisterEvent("COMBAT_RATING_UPDATE");
CharacterStatsTbcFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
CharacterStatsTbcFrame:RegisterEvent("VARIABLES_LOADED");

CharacterStatsTbcFrame:SetScript("OnEvent",
    function(self, event, ...)

        local args = {...};

        if event == "VARIABLES_LOADED" then
            core.UIConfig:UpdateStats();
            core.UIConfig:UpdateSideStats();
        end

        if event == "COMBAT_RATING_UPDATE" or event == "PLAYER_DAMAGE_DONE_MODS" then
            module.QueuePlayerStatRefresh();
        elseif args[1] == "player" then
            if ( event == "UNIT_DAMAGE" or
				event == "UNIT_ATTACK_SPEED" or
				event == "UNIT_RANGEDDAMAGE" or
				event == "UNIT_ATTACK" or
				event == "UNIT_RESISTANCES" or
				event == "UNIT_STATS" or
				event == "UNIT_AURA" or
				event == "UNIT_MAXHEALTH" or
				event == "UNIT_ATTACK_POWER" or
				event == "UNIT_RANGED_ATTACK_POWER" or
				event == "SKILL_LINES_CHANGED" or
                event == "GROUP_ROSTER_UPDATE") then
                module.QueuePlayerStatRefresh();
            end
        end
    end)
end -- not module.isRetail

function CSC_QueuedUpdate(self)
    module.QueuePlayerStatRefresh();
end

-- Exposing global functions for showing/hiding the stats panel. For compatibility with other addons
function CSC_HideStatsPanel()
    if not (core.UIConfig and core.UIConfig.CharacterStatsPanel) then
        return
    end
    core.UIConfig.CharacterStatsPanel:Hide();
    core.UIConfig:SetStatsPanelVisibile(false);
end

function CSC_ShowStatsPanel()
    if not (core.UIConfig and core.UIConfig.CharacterStatsPanel) then
        return
    end
    core.UIConfig.CharacterStatsPanel:Show();
    core.UIConfig:UpdateStats();
    core.UIConfig:UpdateSideStats();
    core.UIConfig:SetStatsPanelVisibile(true);
end

-- Section: CharacterStatsTbcUtils.lua

-- Returns the combat rating for 1% bonus
function CSC_GetCombatRatingPerUnitBonus(unit, combatRatingType)
    local result = 0;
    local playerLevel = UnitLevel(unit);
    local baseCombatRatingValue = g_CombatRatingBaseValues[combatRatingType];

    if not baseCombatRatingValue then
        baseCombatRatingValue = 1;
    end

    if (playerLevel >= 1 and playerLevel <= 10) then
        result = baseCombatRatingValue / 26;
    elseif (playerLevel > 10 and playerLevel <= 60) then
        result = baseCombatRatingValue * ((playerLevel - 8) / 52);
    elseif (playerLevel > 60 and playerLevel <= 80) then
        result = baseCombatRatingValue * (82 / (262 - 3 * playerLevel));
    end

    return result;
end

-- 5th return of GetTalentInfo (current rank) can be nil; matches CharacterStatsTBC/Classic robustness
function CSC_TalentPoints(tabIndex, talentIndex)
	if (module.isRetail) then return 0 end
	return tonumber((select(5, GetTalentInfo(tabIndex, talentIndex)))) or 0;
end

local strfind = string.find

-- Resolve rank by talent name when tab order differs (anniversary TBC vs Wrath); fall back to tab/index.
function CSC_GetTalentRankByName(tabIndex, fallbackIndex, namePattern)
	if (module.isRetail) then return 0 end
	if namePattern and GetNumTalents then
		local n = GetNumTalents(tabIndex) or 0;
		for i = 1, n do
			local name, _, _, _, cur = GetTalentInfo(tabIndex, i);
			if not name then
				break;
			end
			if type(name) == "string" and strfind(name, namePattern, 1, true) then
				return tonumber(cur) or 0;
			end
		end
	end
	return CSC_TalentPoints(tabIndex, fallbackIndex);
end

-- My own GetSpellHitModifier since Blizzard are breaking their API so often I can't rely on them
function CSC_GetSpellHitModifier(unit)
	local spellHit = 0;
	local unitClassId = select(3, UnitClass(unit));

	if unitClassId == CSC_PALADIN_CLASS_ID then
		spellHit = CSC_GetTalentRankByName(2, 3, "Precision"); -- 1% per rank
	elseif unitClassId == CSC_SHAMAN_CLASS_ID then
		spellHit = CSC_GetTalentRankByName(3, 6, "Nature's Guidance"); -- 1% per rank
	elseif unitClassId == CSC_DRUID_CLASS_ID then
		spellHit = CSC_GetTalentRankByName(1, 16, "Balance of Power") * 2; -- 2% per rank
	end

	local spellHitFromAuras = 0;
	local hasInspiringPresenceAura = false;
	
	for i = 1, 40 do
		local spellId = select(10, UnitAura(unit, i, "HELPFUL"));
		if spellId then
			if spellId == 28878 then -- Inspiring Presence
				spellHitFromAuras = spellHitFromAuras + 1;
				hasInspiringPresenceAura = true;
			end

			if spellId == 30708 then -- Totem of Wrath
				spellHitFromAuras = spellHitFromAuras + 3;
			end
		end
	end

	if not hasInspiringPresenceAura and IsSpellKnown(28878) then
		spellHitFromAuras = spellHitFromAuras + 1;
	end

	return spellHit + spellHitFromAuras;
end

-- Hit %% from a rating index: prefer GetCombatRatingBonus; if 0 but rating exists, convert via per-level (Classic API quirk)
function CSC_GetHitPercentFromGearByType(unit, crIndex, cscPerKey, approx70, approx80)
	local bonus = 0;
	if GetCombatRatingBonus then
		bonus = GetCombatRatingBonus(crIndex) or 0;
	end
	if bonus > 0.0001 then
		return bonus;
	end
	if not GetCombatRating then
		return 0;
	end
	local rating = GetCombatRating(crIndex) or 0;
	if rating <= 0 then
		return 0;
	end
	local per = CSC_GetCombatRatingPerUnitBonus(unit, cscPerKey);
	if per and per > 0.0001 then
		return rating / per;
	end
	local lv = UnitLevel(unit) or 0;
	if approx80 and lv == 80 then
		return rating / approx80;
	end
	if approx70 and lv == 70 then
		return rating / approx70;
	end
	return 0;
end

function CSC_GetSpellHitPercentFromGear(unit)
	return CSC_GetHitPercentFromGearByType(unit, CR_HIT_SPELL, CSC_COMBAT_RATING_SPELL_HIT, 12.62, 26.23);
end

-- Total spell haste % (rating, buffs, talents). GetCombatRatingBonus(CR_HASTE_SPELL) is often rating-only; UnitSpellHaste includes everything when available.
function CSC_GetTotalSpellHastePercent(unit)
	unit = unit or "player";
	if type(UnitSpellHaste) == "function" then
		local t = UnitSpellHaste(unit);
		if t ~= nil then
			return t;
		end
	end
	return GetCombatRatingBonus(CR_HASTE_SPELL) or 0;
end

--- Same total haste % as CSC_PaperDollFrame_SetSpellHaste / InfoFrame pin.
function CSC_GetDisplayHastePercent(unit)
	unit = unit or "player";
	if (CSC_UseUnifiedSecondaryStats() and type(GetHaste) == "function") then
		return GetHaste();
	end
	return CSC_GetTotalSpellHastePercent(unit);
end
_G.CSC_InfoFrame_GetDisplayHastePercent = CSC_GetDisplayHastePercent;

function CSC_FormatSpellHasteTooltipLine(hastePercent)
	if SPELL_HASTE_TOOLTIP then
		return format(SPELL_HASTE_TOOLTIP, hastePercent);
	end
	return format("Increases your spell haste by %.2f%%", hastePercent);
end

function CSC_GetPhysicalHitPercentFromGear(unit, crIndex)
	return CSC_GetHitPercentFromGearByType(unit, crIndex, CSC_COMBAT_RATING_HIT, 15.77, 32.79);
end

-- Melee: GetHitModifier + hit from gear (with rating to %% when GetCombatRatingBonus is 0)
-- Ranged total: CSC_GetTotalRangedHitPercent (after CSC_GetHitFromBiznicksAccurascope; local scope)
function CSC_GetTotalMeleeHitPercent(unit)
	unit = unit or "player";
	return (GetHitModifier and GetHitModifier() or 0) + CSC_GetPhysicalHitPercentFromGear(unit, CR_HIT_MELEE);
end

-- Total spell %%. Same building blocks as CharacterStatsTBC SetHitRating(CR_HIT_SPELL): gear rating +
-- CSC_GetSpellHitModifier (talents/aurals) + class-specific spell hit talents (e.g. shaman Elemental Precision).
function CSC_GetTotalSpellHitPercent(unit)
	unit = unit or "player";
	local unitClassId = select(3, UnitClass(unit));
	local gear = CSC_GetSpellHitPercentFromGear(unit);
	if gear <= 0.0001 and GetCombatRatingBonus then
		gear = GetCombatRatingBonus(CR_HIT_SPELL) or 0;
	end
	-- Draenei +1%% is already covered by 28878 (Inspiring/Heroic) in CSC_GetSpellHitModifier — do not add race again
	local spellHitChance = CSC_GetSpellHitModifier(unit) or 0;

	if unitClassId == CSC_SHAMAN_CLASS_ID then
		spellHitChance = spellHitChance + (CSC_GetShamanHitFromElementalPrecision() or 0);
	end

	local base = gear + spellHitChance;

	if unitClassId == CSC_MAGE_CLASS_ID then
		local arcaneHit, frostFire = CSC_GetMageSpellHitFromTalents();
		return max((arcaneHit or 0) + base, (frostFire or 0) + base);
	elseif unitClassId == CSC_WARLOCK_CLASS_ID then
		local aff = CSC_GetWarlockSpellHitFromTalents() or 0;
		return max(base, aff + base);
	elseif unitClassId == CSC_PRIEST_CLASS_ID and type(CSC_GetPriestShadowFocusSpellHit) == "function" then
		local sf = CSC_GetPriestShadowFocusSpellHit() or 0;
		return max(base, base + sf);
	end

	return base;
end

-- Only Shadow school; found by name (tab/index differ between TBC 5-rank vs WotLK 3-rank)
function CSC_GetPriestShadowFocusSpellHit()
	if (module.isRetail) then return 0 end
	local n = (GetNumTalents and GetNumTalents(3)) or 0
	if n <= 0 then
		return 0
	end
	for i = 1, n do
		local name, _, _, _, cur, maxR = GetTalentInfo(3, i)
		if not name then
			break
		end
		if type(name) == "string" and strfind(name, "Shadow Focus", 1, true) then
			cur, maxR = tonumber(cur) or 0, tonumber(maxR) or 0
			-- TBC-style 5-rank: 2% per point; WotLK 3-rank: 1% per point
			local per = (maxR == 5) and 2 or 1
			return cur * per
		end
	end
	return 0
end

-- Shared spell hit from gear, racials, auras, and (for shamans) Elemental Precision — same building blocks
-- as CharacterStatsTBC SetHitRating/spell line; mages: add Arcane/EP via CSC_GetMageSpellHitFromTalents per school.
function CSC_GetSpellHitSharedBase(unit)
	unit = unit or "player";
	local gear = CSC_GetSpellHitPercentFromGear(unit);
	local auras = (CSC_GetSpellHitModifier(unit) or 0);
	local base = (gear or 0) + (auras or 0);
	-- TBC+ Elemental (spell) Precision does not go through CSC_GetSpellHitModifier; see CharacterStatsTbcCore SetHitRating
	if select(3, UnitClass(unit)) == CSC_SHAMAN_CLASS_ID and type(CSC_GetShamanHitFromElementalPrecision) == "function" then
		base = base + (CSC_GetShamanHitFromElementalPrecision() or 0);
	end
	return base;
end

-- GENERAL UTIL FUNCTIONS BEGIN--
-- Retail and some API variants omit trailing returns; never do arithmetic on nil.
local function CSC_CoalesceStatBuffs(base, posBuff, negBuff)
	return tonumber(base) or 0, tonumber(posBuff) or 0, tonumber(negBuff) or 0
end

function CSC_GetAppropriateDamage(unit, category)
	if category == PLAYERSTAT_MELEE_COMBAT then
		return UnitDamage(unit);
	elseif category == PLAYERSTAT_RANGED_COMBAT then
		local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
		return minDamage, maxDamage, nil, nil, bonusPos, bonusNeg, percent;
	end
end

function CSC_GetAppropriateAttackSpeed(unit, category)
	if category == PLAYERSTAT_MELEE_COMBAT then
		return UnitAttackSpeed(unit);
	elseif category == PLAYERSTAT_RANGED_COMBAT then
		local attackSpeed = select(1, UnitRangedDamage(unit))
		return attackSpeed, 0;
	end
end

function CSC_GetAppropriateAttackRaiting(unit, category)
	local attackBase = 0;
	local attackModifier = 0;

	if category == PLAYERSTAT_MELEE_COMBAT then
		if type(UnitAttackBothHands) == "function" then
			attackBase, attackModifier = UnitAttackBothHands(unit);
		else
			-- Retail: weapon skill APIs removed; show total attack power for this tooltip line.
			local b, p, n = UnitAttackPower(unit);
			b, p, n = CSC_CoalesceStatBuffs(b, p, n);
			return b + p + n;
		end
	elseif category == PLAYERSTAT_RANGED_COMBAT then
		if type(UnitRangedAttack) == "function" then
			attackBase, attackModifier = UnitRangedAttack(unit);
		else
			local b, p, n = UnitRangedAttackPower(unit);
			b, p, n = CSC_CoalesceStatBuffs(b, p, n);
			return b + p + n;
		end
	end

	attackBase = tonumber(attackBase) or 0;
	attackModifier = tonumber(attackModifier) or 0;
	return attackBase + attackModifier;
end

function CSC_PaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage)
	if ( isPercentage ) then
		local n = tonumber(text);
		if n == nil then
			n = 0;
		end
		text = format("%.2f%%", n);
	end
	
	if ( statFrame.Label ) then
		if (statFrame.Value) then
			statFrame.Value:SetText(text);
		end

		label = CSC_RetailStripMsrAbbrevPrefix(label);
		statFrame.Label:SetText(format(STAT_FORMAT, label));
		statFrame.Label:SetWidth(statFrame:GetWidth());
		statFrame.Label:SetHeight(statFrame:GetHeight());
		statFrame.Label:SetJustifyH("LEFT");
	end
end

function CSC_PaperDollFormatStat(name, base, posBuff, negBuff)
	base, posBuff, negBuff = CSC_CoalesceStatBuffs(base, posBuff, negBuff)
	local effective = max(0,base + posBuff + negBuff);
	local text = HIGHLIGHT_FONT_COLOR_CODE..name.." "..effective;
	if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
		text = text..FONT_COLOR_CODE_CLOSE;
	else 
		if ( posBuff > 0 or negBuff < 0 ) then
			text = text.." ("..base..FONT_COLOR_CODE_CLOSE;
		end
		if ( posBuff > 0 ) then
			text = text..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE;
		end
		if ( negBuff < 0 ) then
			text = text..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE;
		end
		if ( posBuff > 0 or negBuff < 0 ) then
			text = text..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
		end

		-- if there is a negative buff then show the main number in red, even if there are
		-- positive buffs. Otherwise show the number in green
		if ( negBuff < 0 ) then
			effective = RED_FONT_COLOR_CODE..effective..FONT_COLOR_CODE_CLOSE;
		elseif (posBuff > 0) then
			effective = GREEN_FONT_COLOR_CODE..effective..FONT_COLOR_CODE_CLOSE;
		end
	end
    
    return effective, text;
end

function CSC_HasEnchant(unit, slotId, enchantId)
	local itemLink = GetInventoryItemLink(unit, slotId);
	if itemLink then
		local itemId, enchant = itemLink:match("item:(%d+):(%d*)");
		if enchant then
			if tonumber(enchant) == enchantId then
				return true;
			end
		end
	end

	return false;
end
-- GENERAL UTIL FUNCTIONS END--

-- Section: CharacterStatsTbcCore.lua

--[[
    Util functions that wrap my interface and the Blizzard's WoW Classic lua API code for ease of use
]]

local CSC_ScanTooltip = CreateFrame("GameTooltip", "CSC_ScanTooltip", nil, "GameTooltipTemplate");
CSC_ScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
local CSC_ScanTooltipPrefix = "CSC_ScanTooltip";

local g_lastSeenBaseManaRegen = 0;
local g_lastSeenCastingManaRegen = 0;
g_APFromADItems = 0;

local function CSC_GetMP5FromGear(unit)
	local mp5 = 0;
	for i=1,18 do
		local itemLink = GetInventoryItemLink(unit, i);
		if itemLink then
			local stats = GetItemStats(itemLink);
			if stats then
				-- For some reason this returns (mp5 - 1) so I have to add 1 to the result
				local statMP5 = stats["ITEM_MOD_POWER_REGEN0_SHORT"];
				if (statMP5) then
					mp5 = mp5 + statMP5 + 1;
				end
			end
		end
	end

	local unitClassId = select(3, UnitClass(unit));
	if (unitClassId == CSC_PRIEST_CLASS_ID) then
		local zgEnchantMp5 = CSC_GetMp5FromPriestZGEnchants(unit);
		if (zgEnchantMp5 > 0) then
			mp5 = mp5 + zgEnchantMp5;
		end
	end

	if (CSC_HasEnchant(unit, INVSLOT_WRIST, 2565)) then -- Mana Regen
		mp5 = mp5 + 4;
	end

	if (CSC_HasEnchant(unit, INVSLOT_SHOULDER, 2715)) then -- Resilience of the Scourge
		mp5 = mp5 + 5;
	end

	local tempMHEnchantId = select(4, GetWeaponEnchantInfo());
	if (tempMHEnchantId == 2629) then -- Brilliant Mana Oil
		mp5 = mp5 + 12;
	end

	return mp5;
end

local function CSC_GetSkillRankAndModifier(skillHeader, skillName)
	local numSkills = GetNumSkillLines();
	local skillIndex = 0;
	local currentHeader = nil;

	for i = 1, numSkills do
		local currentSkillName = select(1, GetSkillLineInfo(i));
		local isHeader = select(2, GetSkillLineInfo(i));

		if isHeader ~= nil and isHeader then
			currentHeader = currentSkillName;
		else
			if (currentHeader == skillHeader and currentSkillName == skillName) then
				skillIndex = i;
				break;
			end
		end
	end

	local skillRank = nil;
	local skillModifier = nil;
	if (skillIndex > 0) then
		skillRank = select(4, GetSkillLineInfo(skillIndex));
		skillModifier = select(6, GetSkillLineInfo(skillIndex));
	end

	return skillRank, skillModifier;
end

function CSC_GetPlayerWeaponSkill(unit, weaponSlotId)
	local totalWeaponSkill = nil;

	local unitClassId = select(3, UnitClass(unit));
	-- Druid checks
	local shapeIndex = -1;
	if (unitClassId == CSC_DRUID_CLASS_ID) then
		shapeIndex = CSC_GetShapeshiftForm();
	end

	if (unitClassId == CSC_DRUID_CLASS_ID) and (shapeIndex > 0) then
		totalWeaponSkill = UnitLevel(unit) * 5;
	else
		local itemId = GetInventoryItemID(unit, weaponSlotId);
		if (itemId) then
			local itemSubtypeId = select(7, GetItemInfoInstant(itemId));
			if itemSubtypeId then
				local weaponString = g_WeaponStringByWeaponId[itemSubtypeId];
				if weaponString then
					local skillRank, skillModifier = CSC_GetSkillRankAndModifier(CSC_WEAPON_SKILLS_HEADER, weaponString);
					if skillRank and skillModifier then
						-- Weapon skill from racials should be already in skillRank
						totalWeaponSkill = skillRank + skillModifier;
					end
				end
			end
		end
	end

	return totalWeaponSkill;
end

function CSC_GetPlayerMissChances(unit, playerHitChance)
	local missChanceVsNPC = 5;
	local missChanceVsBoss = 8;
	local missChanceVsPlayer = 5;
	
	local hitChance = playerHitChance;
	local level = UnitLevel(unit);
	local bossLevel = 73;
	local playerWeaponSkill = level * 5;
	local bossDefense = bossLevel * 5;

	-- Boss (level 73)
	if (bossDefense - playerWeaponSkill >= 11) then
		missChanceVsBoss = 5 + (bossDefense - playerWeaponSkill) * 0.2;
	end
	if (bossDefense - playerWeaponSkill <= 10) then
		missChanceVsBoss = 5 + (bossDefense - playerWeaponSkill) * 0.1;
	end
	missChanceVsBoss = missChanceVsBoss + 1; -- hit suppression

	local dwMissChanceVsNpc = math.max(missChanceVsNPC + 19 - hitChance);
	local dwMissChanceVsBoss = math.max(missChanceVsBoss + 19 - hitChance);
	local dwMissChanceVsPlayer = math.max(missChanceVsPlayer + 19 - hitChance);

	missChanceVsNPC = math.max(0, missChanceVsNPC - hitChance);
	missChanceVsBoss = math.max(0, missChanceVsBoss - hitChance);
	missChanceVsPlayer = math.max(0, missChanceVsPlayer - hitChance);

	return missChanceVsNPC, missChanceVsBoss, missChanceVsPlayer, dwMissChanceVsNpc, dwMissChanceVsBoss, dwMissChanceVsPlayer;
end

function CSC_GetPlayerCritCap(unit, ratingIndex)
	local totalHit;
	if (ratingIndex == CR_HIT_MELEE) then
		totalHit = CSC_GetTotalMeleeHitPercent(unit);
	elseif (ratingIndex == CR_HIT_RANGED) then
		totalHit = CSC_GetTotalRangedHitPercent(unit);
	else
		local hitChance = GetHitModifier() or 0;
		local hitRatingBonus = GetCombatRatingBonus(ratingIndex) or 0;
		totalHit = hitChance + hitRatingBonus;
	end
	local missChanceVsNPC, missChanceVsBoss, missChanceVsPlayer, dwMissChanceVsNpc, dwMissChanceVsBoss, dwMissChanceVsPlayer = CSC_GetPlayerMissChances(unit, totalHit);
	
	local playerWeaponSkill = UnitLevel(unit) * 5;
	local bossDefense = 73 * 5;
	local critSuppression = 4.8;
	local dodgeChance = 5 + (bossDefense - playerWeaponSkill) * 0,1;
	local glancingChance = math.max(0, 6 + (bossDefense - playerWeaponSkill) * 1.2);

	local critCap = 100 - missChanceVsBoss - dodgeChance - glancingChance + critSuppression;
	local dwCritCap = 100 - dwMissChanceVsBoss - dodgeChance - glancingChance + critSuppression;

	return critCap, dwCritCap;
end

function CSC_GetAttackPowerFromArgentDawnItems(unit)
	local chestId = GetInventoryItemID(unit, INVSLOT_CHEST);
	local glovesId = GetInventoryItemID(unit, INVSLOT_HAND);
	local bracerId = GetInventoryItemID(unit, INVSLOT_WRIST);
	local trinketFirst = GetInventoryItemID(unit, INVSLOT_TRINKET1);
	local trinketSecond = GetInventoryItemID(unit, INVSLOT_TRINKET2);

	local apVsUndead = 0;
	
	if (g_ArgentDawnAPItems[chestId] ~= nil) then
		apVsUndead = apVsUndead + g_ArgentDawnAPItems[chestId];
	end

	if (g_ArgentDawnAPItems[glovesId] ~= nil) then
		apVsUndead = apVsUndead + g_ArgentDawnAPItems[glovesId];
	end

	if (g_ArgentDawnAPItems[bracerId] ~= nil) then
		apVsUndead = apVsUndead + g_ArgentDawnAPItems[bracerId];
	end

	if (g_ArgentDawnAPItems[trinketFirst] ~= nil) then
		apVsUndead = apVsUndead + g_ArgentDawnAPItems[trinketFirst];
	end

	if (g_ArgentDawnAPItems[trinketSecond] ~= nil) then
		apVsUndead = apVsUndead + g_ArgentDawnAPItems[trinketSecond];
	end

	local tempMHEnchantId = select(4, GetWeaponEnchantInfo());
	if (tempMHEnchantId == 2684) then -- Consecrated Sharpening Stone
		apVsUndead = apVsUndead + 100;
	end

	local tempOHEnchantId = select(8, GetWeaponEnchantInfo());
	if (tempOHEnchantId == 2684) then -- Consecrated Sharpening Stone
		apVsUndead = apVsUndead + 100;
	end

	return apVsUndead;
end

function CSC_GetSpellkPowerFromArgentDawnItems(unit)
	local chestId = GetInventoryItemID(unit, INVSLOT_CHEST);
	local glovesId = GetInventoryItemID(unit, INVSLOT_HAND);
	local bracerId = GetInventoryItemID(unit, INVSLOT_WRIST);
	local trinketFirst = GetInventoryItemID(unit, INVSLOT_TRINKET1);
	local trinketSecond = GetInventoryItemID(unit, INVSLOT_TRINKET2);

	local spVsUndead = 0;
	
	if (g_ArgentDawnSPItems[chestId] ~= nil) then
		spVsUndead = spVsUndead + g_ArgentDawnSPItems[chestId];
	end

	if (g_ArgentDawnSPItems[glovesId] ~= nil) then
		spVsUndead = spVsUndead + g_ArgentDawnSPItems[glovesId];
	end

	if (g_ArgentDawnSPItems[bracerId] ~= nil) then
		spVsUndead = spVsUndead + g_ArgentDawnSPItems[bracerId];
	end

	if (g_ArgentDawnSPItems[trinketFirst] ~= nil) then
		spVsUndead = spVsUndead + g_ArgentDawnSPItems[trinketFirst];
	end

	if (g_ArgentDawnSPItems[trinketSecond] ~= nil) then
		spVsUndead = spVsUndead + g_ArgentDawnSPItems[trinketSecond];
	end

	local tempMHEnchantId = select(4, GetWeaponEnchantInfo());
	if (tempMHEnchantId == 2685) then -- Blessed Wizard Oil
		spVsUndead = spVsUndead + 60;
	end

	local tempOHEnchantId = select(8, GetWeaponEnchantInfo());
	if (tempOHEnchantId == 2685) then -- Blessed Wizard Oil
		spVsUndead = spVsUndead + 60;
	end

	return spVsUndead;
end

function CSC_CacheAPFromADItems(unit)
	g_APFromADItems = CSC_GetAttackPowerFromArgentDawnItems(unit);
end

function CSC_GetDefense(unit)
	local numSkills = GetNumSkillLines();
	local skillIndex = 0;
	local currentHeader = nil;
	local playerLevel = UnitLevel(unit);

	for i = 1, numSkills do
		local skillName = select(1, GetSkillLineInfo(i));
		local isHeader = select(2, GetSkillLineInfo(i));

		if isHeader ~= nil and isHeader then
			currentHeader = skillName;
		else
			if (currentHeader == CSC_WEAPON_SKILLS_HEADER and skillName == CSC_DEFENSE) then
				skillIndex = i;
				break;
			end
		end
	end

	local skillRank, skillModifier;
	if (skillIndex > 0) then
		skillRank = select(4, GetSkillLineInfo(skillIndex));
		skillModifier = select(6, GetSkillLineInfo(skillIndex));
	else
		-- Use this as a backup, just in case something goes wrong
		skillRank, skillModifier = UnitDefense(unit); --Not working properly
	end

	return skillRank, skillModifier, playerLevel;
end
-- GENERAL UTIL FUNCTIONS END --

-- PRIMARY STATS --
function CSC_PaperDollFrame_SetPrimaryStats(statFrames, unit)
	
	local statIndexTable = {
		"STRENGTH",
		"AGILITY",
		"STAMINA",
		"INTELLECT",
		"SPIRIT",
	}

	-- Fix for classic (NUM_STATS instead of NUM_STATS-1)
	for i=1, NUM_STATS, 1 do
		
		local statIndex = i;
		local frameText;
		local stat;
		local effectiveStat;
		local posBuff;
		local negBuff;
		stat, effectiveStat, posBuff, negBuff = UnitStat(unit, statIndex);
		local statName = getglobal("SPELL_STAT"..statIndex.."_NAME");
		
		-- Set the tooltip text
		local tooltipText = HIGHLIGHT_FONT_COLOR_CODE..statName.." ";

		if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
			frameText = effectiveStat;
			statFrames[statIndex].tooltip = tooltipText..effectiveStat..FONT_COLOR_CODE_CLOSE;
		else 
			tooltipText = tooltipText..effectiveStat;
			if ( posBuff > 0 or negBuff < 0 ) then
				tooltipText = tooltipText.." ("..(stat - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE;
			end
			if ( posBuff > 0 ) then
				tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE;
			end
			if ( negBuff < 0 ) then
				tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE;
			end
			if ( posBuff > 0 or negBuff < 0 ) then
				tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
			end
			statFrames[statIndex].tooltip = tooltipText;

			-- If there are any negative buffs then show the main number in red even if there are
			-- positive buffs. Otherwise show in green.
			if ( negBuff < 0 ) then
				frameText = RED_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE;
			else
				frameText = GREEN_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE;
			end
		end

		statFrames[statIndex].tooltip2 = getglobal("DEFAULT_STAT"..statIndex.."_TOOLTIP");
		if (type(statFrames[statIndex].tooltip2) ~= "string") then
			statFrames[statIndex].tooltip2 = "";
		end

		if ( statIndex == 1 ) then
			local attackPower = CSC_SafeGetAttackPowerForStat(statIndex,effectiveStat);
			statFrames[statIndex].tooltip2 = format(statFrames[statIndex].tooltip2, attackPower);

			local unitClassId = select(3, UnitClass(unit));
			if ( unitClassId == CSC_WARRIOR_CLASS_ID or unitClassId == CSC_SHAMAN_CLASS_ID or unitClassId == CSC_PALADIN_CLASS_ID ) then
				local blockTip = STAT_BLOCK_TOOLTIP;
				if (type(blockTip) == "string" and blockTip ~= "") then
					statFrames[statIndex].tooltip2 = statFrames[statIndex].tooltip2 .. "\n" .. format(blockTip, effectiveStat * CSC_SafeGlobalNumber("BLOCK_PER_STRENGTH", 0));
				end
			end
		elseif ( statIndex == 3 ) then
			local baseStam = min(20, effectiveStat);
			local moreStam = effectiveStat - baseStam;
			local hps = CSC_SafeGlobalNumber("HEALTH_PER_STAMINA", 10);
			statFrames[statIndex].tooltip2 = format(statFrames[statIndex].tooltip2, (baseStam + (moreStam * hps)) * CSC_SafeGetUnitMaxHealthModifier(unit));
			local petStam = ComputePetBonus("PET_BONUS_STAM", effectiveStat );
			if( petStam > 0 ) then
				local petStamTip = PET_BONUS_TOOLTIP_STAMINA;
				if (type(petStamTip) == "string" and petStamTip ~= "") then
					statFrames[statIndex].tooltip2 = statFrames[statIndex].tooltip2 .. "\n" .. format(petStamTip, petStam);
				end
			end
		elseif ( statIndex == 2 ) then
			local apArmor = CSC_SafeGlobalNumber("ARMOR_PER_AGILITY", 0);
			local attackPower = CSC_SafeGetAttackPowerForStat(statIndex,effectiveStat);
			local apPrefix = STAT_ATTACK_POWER;
			if (type(apPrefix) ~= "string") then
				apPrefix = "";
			end
			if ( attackPower > 0 ) then
				statFrames[statIndex].tooltip2 = format(apPrefix, attackPower) .. format(statFrames[statIndex].tooltip2, CSC_SafeGetCritChanceFromAgility(unit), effectiveStat * apArmor);
			else
				statFrames[statIndex].tooltip2 = format(statFrames[statIndex].tooltip2, CSC_SafeGetCritChanceFromAgility(unit), effectiveStat * apArmor);
			end
		elseif ( statIndex == 4 ) then
			local baseInt = min(20, effectiveStat);
			local moreInt = effectiveStat - baseInt
			local mpi = CSC_SafeGlobalNumber("MANA_PER_INTELLECT", 15);
			if ( UnitHasMana(unit) ) then
				statFrames[statIndex].tooltip2 = format(statFrames[statIndex].tooltip2, baseInt + moreInt * mpi, CSC_SafeGetSpellCritChanceFromIntellect(unit));
			else
				statFrames[statIndex].tooltip2 = nil;
			end
			local petInt = ComputePetBonus("PET_BONUS_INT", effectiveStat );
			if( petInt > 0 ) then
				if ( not statFrames[statIndex].tooltip2 ) then
					statFrames[statIndex].tooltip2 = "";
				end
				local petIntTip = PET_BONUS_TOOLTIP_INTELLECT;
				if (type(petIntTip) == "string" and petIntTip ~= "") then
					statFrames[statIndex].tooltip2 = statFrames[statIndex].tooltip2 .. "\n" .. format(petIntTip, petInt);
				end
			end
		elseif ( statIndex == 5 ) then
			-- All mana regen stats are displayed as mana/5 sec.
			statFrames[statIndex].tooltip2 = format(statFrames[statIndex].tooltip2, CSC_SafeGetUnitHealthRegenRateFromSpirit(unit));
			if ( UnitHasMana(unit) ) then
				local regen = CSC_SafeGetUnitManaRegenRateFromSpirit(unit);
				regen = floor( regen * 5.0 );
				local mrLine = MANA_REGEN_FROM_SPIRIT;
				if (type(mrLine) == "string" and mrLine ~= "") then
					statFrames[statIndex].tooltip2 = statFrames[statIndex].tooltip2 .. "\n" .. format(mrLine, regen);
				end
			end
		end

		CSC_PaperDollFrame_SetLabelAndText(statFrames[i], statName, frameText, false);
	end
end

-- DAMAGE --
function CSC_PaperDollFrame_SetDamage(statFrame, unit, category)

	if (category == PLAYERSTAT_RANGED_COMBAT) and not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, DAMAGE, NOT_APPLICABLE, false);
		return;
	end

    statFrame:SetScript("OnEnter", CSC_CharacterDamageFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)

    local speed, offhandSpeed = CSC_GetAppropriateAttackSpeed(unit, category);
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percentMod = CSC_GetAppropriateDamage(unit, category);
	
	-- sometimes this is wrongly reported as 0
	if percentMod == nil or percentMod == 0 then
		percentMod = 1;
	end

	if speed == nil or speed == 0 then
		speed = 1;
	end

	if (UISettingsCharacter.showStatsFromArgentDawnItems) then
		local bonusDPS = g_APFromADItems / ATTACK_POWER_MAGIC_NUMBER;
		local bonusDmgMainHand = speed * bonusDPS;
		minDamage = minDamage + bonusDmgMainHand;
		maxDamage = maxDamage + bonusDmgMainHand;
	end
    
    local displayMin = max(floor(minDamage),1);
	local displayMax = max(ceil(maxDamage),1);
    
    minDamage = (minDamage / percentMod) - physicalBonusPos - physicalBonusNeg;
	maxDamage = (maxDamage / percentMod) - physicalBonusPos - physicalBonusNeg;
	
    local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percentMod;
	local totalBonus = (fullDamage - baseDamage);
	local damagePerSecond = (max(fullDamage,1) / speed);
    local damageTooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);
    
    local colorPos = "|cff20ff20";
    local colorNeg = "|cffff2020";
	
    -- epsilon check
	if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
		totalBonus = 0.0;
    end
    
    local damageText;

    if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText = displayMin.." - "..displayMax;
		else
			damageText = displayMin.."-"..displayMax;
		end
	else
		-- set bonus color and display
		local color;
		if ( totalBonus > 0 ) then
			color = colorPos;
		else
			color = colorNeg;
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText = color..displayMin.." - "..displayMax.."|r";
		else
			damageText = color..displayMin.."-"..displayMax.."|r";
		end
		if ( physicalBonusPos > 0 ) then
			damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percentMod > 1 ) then
			damageTooltip = damageTooltip..colorPos.." x"..floor(percentMod*100+0.5).."%|r";
		elseif ( percentMod < 1 ) then
			damageTooltip = damageTooltip..colorNeg.." x"..floor(percentMod*100+0.5).."%|r";
		end
    end
    
    CSC_PaperDollFrame_SetLabelAndText(statFrame, DAMAGE, damageText, false);

    statFrame.damage = damageTooltip;
	statFrame.attackSpeed = speed;
    statFrame.dps = damagePerSecond;
	statFrame.attackRating = CSC_GetAppropriateAttackRaiting(unit, category);
	statFrame.TooltipMainTxt = INVTYPE_WEAPONMAINHAND;

	if (category == PLAYERSTAT_RANGED_COMBAT) and IsRangedWeapon() then
		statFrame.TooltipMainTxt = INVTYPE_RANGED;
	end

    -- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed and category == PLAYERSTAT_MELEE_COMBAT) then
		if offhandSpeed == 0 then
			offhandSpeed = 1;
		end

		if (UISettingsCharacter.showStatsFromArgentDawnItems) then
			local bonusDPS = g_APFromADItems / ATTACK_POWER_MAGIC_NUMBER;
			local bonusDmgOffHand = offhandSpeed * bonusDPS;
			minOffHandDamage = minOffHandDamage + bonusDmgOffHand;
			maxOffHandDamage = maxOffHandDamage + bonusDmgOffHand;
		end

		minOffHandDamage = (minOffHandDamage / percentMod) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percentMod) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percentMod;
		local offhandDamagePerSecond = (max(offhandFullDamage,1) / offhandSpeed);
		local offhandDamageTooltip = max(floor(minOffHandDamage),1).." - "..max(ceil(maxOffHandDamage),1);
		if ( physicalBonusPos > 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percentMod > 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percentMod*100+0.5).."%|r";
		elseif ( percentMod < 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percentMod*100+0.5).."%|r";
		end
		statFrame.offhandDamage = offhandDamageTooltip;
		statFrame.offhandAttackSpeed = offhandSpeed;
		statFrame.offhandDps = offhandDamagePerSecond;
	else
		statFrame.offhandAttackSpeed = nil;
    end
end

-- Note: while this function was historically named "BothHands",
-- it looks like it only ever displayed attack rating for the main hand.
function CSC_PaperDollFrame_SetAttackBothHands(statFrame, unit)

	local mainHandAttackBase, mainHandAttackMod = 0, 0;
	if type(UnitAttackBothHands) == "function" then
		mainHandAttackBase, mainHandAttackMod = UnitAttackBothHands(unit);
	else
		local b, p, n = UnitAttackPower(unit);
		b, p, n = CSC_CoalesceStatBuffs(b, p, n);
		mainHandAttackBase = b + p + n;
		mainHandAttackMod = 0;
	end
	mainHandAttackBase = tonumber(mainHandAttackBase) or 0;
	mainHandAttackMod = tonumber(mainHandAttackMod) or 0;
	local attackWithModifier = mainHandAttackBase + mainHandAttackMod;
	local attackText;

	if( mainHandAttackMod == 0 ) then
		attackText = mainHandAttackBase;
	else
		local color = RED_FONT_COLOR_CODE;
		if( mainHandAttackMod > 0 ) then
			color = GREEN_FONT_COLOR_CODE;
		end
		attackText = color..attackWithModifier..FONT_COLOR_CODE_CLOSE;
	end

	CSC_PaperDollFrame_SetLabelAndText(statFrame, DAMAGE, attackText, false);

	statFrame.tooltip = ATTACK_TOOLTIP;
	statFrame.tooltip2 = ATTACK_TOOLTIP_SUBTEXT;
end

function CSC_PaperDollFrame_SetMeleeAttackPower(statFrame, unit)
    
	local base, posBuff, negBuff = UnitAttackPower(unit);
	base, posBuff, negBuff = CSC_CoalesceStatBuffs(base, posBuff, negBuff)

	if (UISettingsCharacter.showStatsFromArgentDawnItems) then
		posBuff = posBuff + g_APFromADItems;
	end
    
    local valueText, tooltipText = CSC_PaperDollFormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff);
    local valueNum = max(0, base + posBuff + negBuff);
    CSC_PaperDollFrame_SetLabelAndText(statFrame, ATTACK_POWER, valueText, false);
    statFrame.tooltip = tooltipText;
	statFrame.tooltip2 = format(MELEE_ATTACK_POWER_TOOLTIP, max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER);
end

function CSC_PaperDollFrame_SetRangedAttackPower(statFrame, unit)
	
	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, ATTACK_POWER, NOT_APPLICABLE, false);
		return;
	end

	if ( HasWandEquipped() ) then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, ATTACK_POWER, NOT_APPLICABLE, false);
		statFrame.tooltip = nil;
		return;
	end

	local base, posBuff, negBuff = UnitRangedAttackPower(unit);
	base, posBuff, negBuff = CSC_CoalesceStatBuffs(base, posBuff, negBuff)

	if (UISettingsCharacter.showStatsFromArgentDawnItems) then
		posBuff = posBuff + g_APFromADItems;
	end
	
    local valueText, tooltipText = CSC_PaperDollFormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff);
    local valueNum = max(0, base + posBuff + negBuff);
    CSC_PaperDollFrame_SetLabelAndText(statFrame, ATTACK_POWER, valueText, false);
	statFrame.tooltip = tooltipText;
    statFrame.tooltip2 = format(RANGED_ATTACK_POWER_TOOLTIP, valueNum/ATTACK_POWER_MAGIC_NUMBER);
end

-- SECONDARY STATS --
function CSC_PaperDollFrame_SetCritChance(statFrame, unit)
	
	statFrame:SetScript("OnEnter", CSC_CharacterMeleeCritFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)
	
	local critChance = CSC_GetDisplayMeleeCritPercent(unit);
	local critLabel = CSC_UseUnifiedSecondaryStats() and CSC_CRIT_LABEL_UNIFIED or MELEE_CRIT_CHANCE;

	CSC_PaperDollFrame_SetLabelAndText(statFrame, critLabel, critChance, true);
	statFrame.critChance = critChance;
	statFrame.unit = unit;
end

function CSC_PaperDollFrame_SetRangedCritChance(statFrame, unit)

	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_CRITICAL_STRIKE, NOT_APPLICABLE, false);
		return;
	end

	statFrame:SetScript("OnEnter", CSC_CharacterRangedCritFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)

	local critChance = CSC_UseUnifiedSecondaryStats() and CSC_GetDisplayMeleeCritPercent(unit) or CSC_GetDisplayRangedCritPercent(unit);
	statFrame.critChance = critChance;
	statFrame.unit = unit;
	local critLabel = CSC_UseUnifiedSecondaryStats() and CSC_CRIT_LABEL_UNIFIED or RANGED_CRIT_CHANCE;

	CSC_PaperDollFrame_SetLabelAndText(statFrame, critLabel, critChance, true);
end

-- Fills per-school crit fields on statFrame (or throwaway table) and returns the displayed max crit %.
function CSC_UpdateSpellCritStatFrame(statFrame, unit)
	if type(CSC_UpdateSpellCritStatFrameFromCalculator) == "function" then
		return CSC_UpdateSpellCritStatFrameFromCalculator(statFrame, unit);
	end

	local MAX_SPELL_SCHOOLS = 7;
	local holySchool = 2;

	local maxSpellCrit = GetSpellCritChance(holySchool);
	for i = holySchool, MAX_SPELL_SCHOOLS do
		local bonusCrit = GetSpellCritChance(i);
		maxSpellCrit = max(maxSpellCrit, bonusCrit);
	end

	statFrame.holyCrit = GetSpellCritChance(2);
	statFrame.fireCrit = GetSpellCritChance(3);
	statFrame.natureCrit = GetSpellCritChance(4);
	statFrame.frostCrit = GetSpellCritChance(5);
	statFrame.shadowCrit = GetSpellCritChance(6);
	statFrame.arcaneCrit = GetSpellCritChance(7);

	local unitClassId = select(3, UnitClass(unit));
	if (unitClassId == CSC_PRIEST_CLASS_ID) then
		local priestHolyCrit = CSC_GetPriestCritStatsFromTalents();
		priestHolyCrit = priestHolyCrit + CSC_GetHolyCritFromBenediction(unit);

		if (priestHolyCrit > 0) then
			statFrame.holyCrit = statFrame.holyCrit + priestHolyCrit;
			maxSpellCrit = max(maxSpellCrit, statFrame.holyCrit);
		end
	elseif (unitClassId == CSC_WARLOCK_CLASS_ID) then
		local destructionCrit = CSC_GetWarlockCritStatsFromTalents();
		if (destructionCrit > 0) then
			statFrame.shadowCrit = statFrame.shadowCrit + destructionCrit;
			statFrame.fireCrit = statFrame.fireCrit + destructionCrit;
			local tmpMax = max(statFrame.shadowCrit, statFrame.fireCrit);
			maxSpellCrit = max(maxSpellCrit, tmpMax);
		end
	elseif (unitClassId == CSC_SHAMAN_CLASS_ID) then
		statFrame.lightningCrit = statFrame.natureCrit;

		local callOfThunderCrit = CSC_GetShamanCallOfThunderCrit();
		if callOfThunderCrit > 0 then
			statFrame.lightningCrit = statFrame.lightningCrit + callOfThunderCrit;
		end

		local tidalMastery = CSC_GetShamanTidalMasteryCrit();
		if tidalMastery > 0 then
			statFrame.lightningCrit = statFrame.lightningCrit + tidalMastery;
			statFrame.natureCrit = statFrame.natureCrit + tidalMastery;
		end

		local tmpMax = max(statFrame.lightningCrit, statFrame.natureCrit);
		maxSpellCrit = max(maxSpellCrit, tmpMax);
	end
	statFrame.unitClassId = unitClassId;
	return maxSpellCrit;
end

function CSC_PaperDollFrame_SetSpellCritChance(statFrame, unit)

	if (CSC_UseUnifiedSecondaryStats()) then
		statFrame:SetScript("OnEnter", CSC_CharacterSpellCritFrame_OnEnter)
		statFrame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		local critChance = CSC_GetDisplayMeleeCritPercent(unit);
		statFrame.critChance = critChance;
		statFrame.maxSpellCrit = nil;
		CSC_PaperDollFrame_SetLabelAndText(statFrame, CSC_CRIT_LABEL_UNIFIED, critChance, true);
		return;
	end

	statFrame:SetScript("OnEnter", CSC_CharacterSpellCritFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	local maxSpellCrit = CSC_UpdateSpellCritStatFrame(statFrame, unit);
	statFrame.maxSpellCrit = maxSpellCrit;
	CSC_PaperDollFrame_SetLabelAndText(statFrame, SPELL_CRIT_CHANCE, maxSpellCrit, true);
end

function CSC_PaperDollFrame_SetHitChance(statFrame, unit)
	
	statFrame:SetScript("OnEnter", CSC_CharacterHitChanceFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	local hitChance = CSC_GetTotalMeleeHitPercent(unit);

	local hitChanceText = hitChance;
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, hitChanceText, true);
	statFrame.hitChance = hitChance;
end

local function CSC_GetHitFromBiznicksAccurascope(unit)
	CSC_ScanTooltip:ClearLines();

	local hitFromScope = 0;
	local rangedIndex = 18;

	local itemLink = GetInventoryItemLink(unit, rangedIndex);
	if itemLink then
		local itemId, enchantId = itemLink:match("item:(%d+):(%d*)");
		if enchantId then
			if tonumber(enchantId) == 2523 then
				hitFromScope = 3;
			end
		end
	end

	return hitFromScope;
end

function CSC_GetTotalRangedHitPercent(unit)
	unit = unit or "player";
	return (GetHitModifier and GetHitModifier() or 0) + (CSC_GetHitFromBiznicksAccurascope(unit) or 0) + CSC_GetPhysicalHitPercentFromGear(unit, CR_HIT_RANGED);
end

function CSC_PaperDollFrame_SetHitRating(statFrame, unit, ratingIndex)

	statFrame:SetScript("OnEnter", CSC_CharacterHitRatingFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local unitClassId = select(3, UnitClass(unit));

	local statName;
	if (CSC_UseUnifiedSecondaryStats()) then
		statName = "Hit";
	else
		statName = getglobal("COMBAT_RATING_NAME"..ratingIndex);
	end
	local totalHit;
	if ( ratingIndex == CR_HIT_MELEE ) then
		totalHit = CSC_GetTotalMeleeHitPercent(unit);
	elseif ( ratingIndex == CR_HIT_RANGED ) then
		totalHit = CSC_GetTotalRangedHitPercent(unit);
	elseif ( ratingIndex == CR_HIT_SPELL ) then
		totalHit = CSC_GetTotalSpellHitPercent(unit);
		statFrame.spellHitGearTalents = totalHit;
		statFrame.spellHitSharedBase = CSC_GetSpellHitSharedBase(unit);
		if unitClassId == CSC_MAGE_CLASS_ID then
			local arcaneHit, frostFireHit = CSC_GetMageSpellHitFromTalents();
			statFrame.arcaneHit = arcaneHit;
			statFrame.frostHit = frostFireHit;
			statFrame.fireHit = frostFireHit;
		elseif unitClassId == CSC_WARLOCK_CLASS_ID then
			statFrame.afflictionHit = CSC_GetWarlockSpellHitFromTalents();
		elseif unitClassId == CSC_PRIEST_CLASS_ID and type(CSC_GetPriestShadowFocusSpellHit) == "function" then
			statFrame.shadowFocusHit = CSC_GetPriestShadowFocusSpellHit() or 0
		end
	else
		totalHit = (GetCombatRatingBonus(ratingIndex) or 0);
	end

	statFrame.unit = unit;
	statFrame.ratingIndex = ratingIndex;
	statFrame.statName = statName;
	statFrame.rating = format("%.2f", totalHit);
	statFrame.ratingBonus = totalHit;
	CSC_PaperDollFrame_SetLabelAndText(statFrame, statName, totalHit, true);
end

function CSC_PaperDollFrame_SetExpertise(statFrame, unit)
	
	local expertise, offhandExpertise = GetExpertise();
	local speed, offhandSpeed = UnitAttackSpeed(unit);
	local text;
	if( offhandSpeed ) then
		text = expertise.." / "..offhandExpertise;
	else
		text = expertise;
	end
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_EXPERTISE, text);
	
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..getglobal("COMBAT_RATING_NAME"..CR_EXPERTISE).." "..text..FONT_COLOR_CODE_CLOSE;
	
	local expertisePercent, offhandExpertisePercent = GetExpertisePercent();
	expertisePercent = format("%.2f", expertisePercent);
	if( offhandSpeed ) then
		offhandExpertisePercent = format("%.2f", offhandExpertisePercent);
		text = expertisePercent.."% / "..offhandExpertisePercent.."%";
	else
		text = expertisePercent.."%";
	end
	statFrame.tooltip2 = format(CR_EXPERTISE_TOOLTIP, text, GetCombatRating(CR_EXPERTISE), GetCombatRatingBonus(CR_EXPERTISE));
end

function CSC_PaperDollFrame_SetRangedHitChance(statFrame, unit)
	
	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, NOT_APPLICABLE, false);
		return;
	end

	statFrame:SetScript("OnEnter", CSC_CharacterRangedHitChanceFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	local hitChance = CSC_GetTotalRangedHitPercent(unit);

	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, hitChance, true);
	statFrame.hitChance = hitChance;
end

function CSC_PaperDollFrame_SetSpellHitChance(statFrame, unit)
	
	statFrame:SetScript("OnEnter", CSC_CharacterSpellHitChanceFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local unitClassId = select(3, UnitClass(unit));

	if unitClassId == CSC_MAGE_CLASS_ID then
		local arcaneHit, frostFireHit = CSC_GetMageSpellHitFromTalents();
		statFrame.arcaneHit = arcaneHit;
		statFrame.frostHit = frostFireHit;
		statFrame.fireHit = frostFireHit;
	elseif unitClassId == CSC_WARLOCK_CLASS_ID then
		statFrame.afflictionHit = CSC_GetWarlockSpellHitFromTalents();
	elseif unitClassId == CSC_PRIEST_CLASS_ID and type(CSC_GetPriestShadowFocusSpellHit) == "function" then
		statFrame.shadowFocusHit = CSC_GetPriestShadowFocusSpellHit() or 0
	end

	local totalHit = CSC_GetTotalSpellHitPercent(unit);
	statFrame.hitChance = totalHit;
	statFrame.spellHitSharedBase = CSC_GetSpellHitSharedBase(unit);
	statFrame.unitClassId = unitClassId;
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, totalHit, true);
end

function CSC_PaperDollFrame_SetAttackSpeed(statFrame, unit)
	local speed, offhandSpeed = UnitAttackSpeed(unit);

	local displaySpeed = format("%.2F", speed);
	if ( offhandSpeed ) then
		offhandSpeed = format("%.2F", offhandSpeed);
	end
	if ( offhandSpeed ) then
		displaySpeed =  displaySpeed.." / ".. offhandSpeed;
	else
		displaySpeed =  displaySpeed;
	end

	CSC_PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, displaySpeed, false);
	statFrame.tooltip = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED).." "..displaySpeed;
	local hIdx = CSC_HasteCombatRatingIndexForContext(CR_HASTE_MELEE, CR_HASTE_MELEE);
	statFrame.tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(hIdx), GetCombatRatingBonus(hIdx));
end

function CSC_PaperDollFrame_SetRangedAttackSpeed(statFrame, unit)
	
	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, NOT_APPLICABLE, false);
		return;
	end

	local attackSpeed, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
	local displaySpeed = format("%.2F", attackSpeed);

	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..ATTACK_SPEED.." "..displaySpeed..FONT_COLOR_CODE_CLOSE;
	local hIdx = CSC_HasteCombatRatingIndexForContext(CR_HASTE_RANGED, CR_HASTE_RANGED);
	statFrame.tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(hIdx), GetCombatRatingBonus(hIdx));
	CSC_PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, displaySpeed, false);
end

-- DEFENSES --
function CSC_PaperDollFrame_GetArmorReduction(armor, attackerLevel)
	local levelModifier = attackerLevel;
	if ( levelModifier > 59 ) then
		levelModifier = levelModifier + (4.5 * (levelModifier-59));
	end
	local temp = 0.1*armor/(8.5*levelModifier + 40);
	temp = temp/(1+temp);

	if ( temp > 0.75 ) then
		return 75;
	end

	if ( temp < 0 ) then
		return 0;
	end

	return format("%.2f", (temp*100));
end

function CSC_PaperDollFrame_SetArmor(statFrame, unit)

	local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor(unit);
	base, posBuff, negBuff = CSC_CoalesceStatBuffs(base, posBuff, negBuff)
	local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, UnitLevel(unit));

	local valueText, tooltipText = CSC_PaperDollFormatStat(ARMOR, base, posBuff, negBuff);
	local valueNum = max(0, base + posBuff + negBuff);

	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_ARMOR, valueText, false);
	statFrame.tooltip = tooltipText;
	statFrame.tooltip2 = format(DEFAULT_STATARMOR_TOOLTIP, armorReduction);
	
	local petBonus = ComputePetBonus("PET_BONUS_ARMOR", effectiveArmor );
	if( petBonus > 0 ) then
		statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_ARMOR, petBonus);
	end
end

function CSC_PaperDollFrame_SetDefense(statFrame, unit)

	statFrame:SetScript("OnEnter", CSC_CharacterDefenseFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local base, modifier = UnitDefense(unit);

	local posBuff = 0;
	local negBuff = 0;
	local posBuff = 0;
	local negBuff = 0;

	if ( modifier > 0 ) then
		posBuff = modifier;
	elseif ( modifier < 0 ) then
		negBuff = modifier;
	end

	local valueText, defenseText = CSC_PaperDollFormatStat(DEFENSE, base, posBuff, negBuff);
	local valueNum = max(0, base + posBuff + negBuff);
	statFrame.defense = defenseText;
	CSC_PaperDollFrame_SetLabelAndText(statFrame, CSC_DEFENSE, valueText, false);
end

function CSC_PaperDollFrame_SetDodge(statFrame)
	local chance = GetDodgeChance();
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_DODGE, chance, true);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..getglobal("DODGE_CHANCE").." "..string.format("%.02f", chance).."%"..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE));
end

function CSC_PaperDollFrame_SetParry(statFrame)
	local chance = GetParryChance();
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_PARRY, chance, true);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..getglobal("PARRY_CHANCE").." "..string.format("%.02f", chance).."%"..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY));
end

function CSC_GetBlockValue(unit)
	CSC_ScanTooltip:ClearLines();

	local blockValueFromItems = 0;
	local firstItemslotIndex = 1;
	local lastItemslotIndex = 18;

	local blockValueIDs = { ITEM_MOD_BLOCK_RATING_SHORT, ITEM_MOD_BLOCK_RATING, ITEM_MOD_BLOCK_VALUE };
	local equippedMightSetItems = 0;

	for itemslot=firstItemslotIndex, lastItemslotIndex do
		local hasItem = CSC_ScanTooltip:SetInventoryItem(unit, itemslot);
		if hasItem then
			local itemId = GetInventoryItemID(unit, itemslot);
			if (itemId == g_BattlegearOfMightIds[itemId]) then
				equippedMightSetItems = equippedMightSetItems + 1;
			else
				local maxLines = CSC_ScanTooltip:NumLines();
				for line=1, maxLines do
					local leftText = getglobal(CSC_ScanTooltipPrefix.."TextLeft"..line);
					if leftText:GetText() then
						for blockValueID=1, 3 do
							local valueTxt = string.match(leftText:GetText(), "%d+ "..blockValueIDs[blockValueID]);
							if not valueTxt then
								valueTxt = string.match(leftText:GetText(), string.sub( blockValueIDs[blockValueID], 1, -5).." %d+");
							end
							if valueTxt then
								valueTxt = string.match(valueTxt, "%d+");
								if valueTxt then
									local numValue = tonumber(valueTxt);
									if numValue then
										blockValueFromItems = blockValueFromItems + numValue;
									end
								end
							end
						end
					end
				end
			end
		end
	end

	local strStatIndex = 1;
	local strength = select(2, UnitStat(unit, strStatIndex));
	local blockValue = blockValueFromItems + (strength / 20);
	
	local requiredMightSetItems = 3;
	if (equippedMightSetItems >= requiredMightSetItems) then
		blockValue = blockValue + 30; -- Set bonus reached
	end

	return blockValue;
end

function CSC_PaperDollFrame_SetBlock(statFrame, unit)

	statFrame:SetScript("OnEnter", CSC_CharacterBlock_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	local blockChance = GetBlockChance();
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_BLOCK, blockChance, true);

	statFrame.blockChance = HIGHLIGHT_FONT_COLOR_CODE..getglobal("BLOCK_CHANCE").." "..string.format("%.02f", blockChance).."%"..FONT_COLOR_CODE_CLOSE;
end

-- SPELL --
function CSC_PaperDollFrame_SetSpellPower(statFrame, unit)

	statFrame:SetScript("OnEnter", CSC_CharacterSpellDamageFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)

	local MAX_SPELL_SCHOOLS = 7;
	local holySchool = 2;

	-- Start at 2 to skip physical damage
	local maxSpellDmg = GetSpellBonusDamage(holySchool);
	for i=holySchool, MAX_SPELL_SCHOOLS do
		local bonusDamage = GetSpellBonusDamage(i);
		maxSpellDmg = max(maxSpellDmg, bonusDamage);
	end

	if (UISettingsCharacter.showStatsFromArgentDawnItems) then
		local spFromAD = CSC_GetSpellkPowerFromArgentDawnItems(unit);
		maxSpellDmg = maxSpellDmg + spFromAD;
		statFrame.spVsUndead = maxSpellDmg;
	end

	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_SPELLPOWER, BreakUpLargeNumbers(maxSpellDmg), false);
end

local function CSC_GetMP5FromAuras()
	local mp5FromAuras = 0;
	local mp5CombatModifier = 0;

	for i = 0, 40 do
		--local name = select(1, UnitAura("player", i, "HELPFUL", "PLAYER"));
		local spellId = select(10, UnitAura("player", i, "HELPFUL", "PLAYER"));
		if spellId then
			if g_AuraIdToMp5[spellId] then
				local auraMp5 = g_AuraIdToMp5[spellId];
				
				local unitClassId = select(3, UnitClass("player"));
				if (unitClassId == CSC_PALADIN_CLASS_ID and CSC_IsBoWSpellId(spellId)) then
					local improvedBoWModifier = CSC_GetPaladinImprovedBoWModifier();
					
					if (improvedBoWModifier > 0) then
						auraMp5 = auraMp5 + auraMp5 * improvedBoWModifier;
					end
				end

				mp5FromAuras = mp5FromAuras + auraMp5;
			elseif g_CombatManaRegenSpellIdToModifier[spellId] then
				mp5CombatModifier = mp5CombatModifier + g_CombatManaRegenSpellIdToModifier[spellId];
			end
			--print(name.." "..spellId);
		end
	end

	return mp5FromAuras, mp5CombatModifier;
end

function CSC_PaperDollFrame_SetManaRegen(statFrame, unit)

	if ( not UnitHasMana(unit) ) then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, MANA_REGEN, NOT_APPLICABLE, false);
		statFrame.tooltip = nil;
		return;
	end

	statFrame:SetScript("OnEnter", CSC_CharacterManaRegenFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)

	-- It looks like Blizzard fixed this. It also takes into account mana regen from talents and gear
	local base, casting = GetManaRegen();
	local mp5FromGear = CSC_GetMP5FromGear(unit) + CSC_GetMP5FromSetBonus(unit); -- gems not included

	-- Convert mana per sec to mp5
	base = base * 5.0;
	casting = casting * 5.0;

	local regenWhenNotCastingText = BreakUpLargeNumbers(base);
	local castingText = BreakUpLargeNumbers(casting);
	
	-- While Casting mana regen is most important to the player, so we display it as the main value
	CSC_PaperDollFrame_SetLabelAndText(statFrame, MANA_REGEN, castingText, false);
	statFrame.mp5FromGear = BreakUpLargeNumbers(mp5FromGear);
	statFrame.mp5Casting = castingText;
	statFrame.mp5NotCasting = regenWhenNotCastingText;
end

function CSC_PaperDollFrame_SetSpellHaste(statFrame)
	local unit = "player";
	local hIdx = CSC_HasteCombatRatingIndexForContext(CR_HASTE_SPELL, CR_HASTE_SPELL);
	local hasteRating = GetCombatRating(hIdx) or 0;
	local hasteFromRating = GetCombatRatingBonus(hIdx) or 0;
	local totalHaste;
	if (CSC_UseUnifiedSecondaryStats() and type(GetHaste) == "function") then
		totalHaste = GetHaste();
	else
		totalHaste = CSC_GetTotalSpellHastePercent(unit);
	end
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. CSC_HASTE_LABEL .. FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = CSC_FormatSpellHasteTooltipLine(totalHaste);
	if hasteRating > 0 and CR_HASTE_RATING_TOOLTIP then
		statFrame.tooltip2 = statFrame.tooltip2 .. "\n\n" .. format(CR_HASTE_RATING_TOOLTIP, hasteRating, hasteFromRating);
	end
	CSC_PaperDollFrame_SetLabelAndText(statFrame, CSC_HASTE_LABEL, totalHaste, true);
end

--- Main paper row (Spell tab): matches Blizzard spell penetration line.
function CSC_PaperDollFrame_SetPaperSpellPenetration(statFrame, unit)
	if not statFrame then return end
	unit = unit or "player"
	local spellPen = (type(GetSpellPenetration) == "function") and GetSpellPenetration() or 0
	local label = SPELL_PENETRATION or "Spell Penetration"
	CSC_PaperDollFrame_SetLabelAndText(statFrame, label, spellPen, false)
	if SPELL_PENETRATION_TOOLTIP then
		statFrame.tooltip = format(SPELL_PENETRATION_TOOLTIP, spellPen, spellPen)
	else
		statFrame.tooltip = label .. " " .. tostring(spellPen)
	end
	statFrame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltip, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		GameTooltip:Show()
	end)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	if _G.FluxInfoFrame and _G.FluxInfoFrame.HookClassicCSCStatFrame then
		_G.FluxInfoFrame.HookClassicCSCStatFrame(statFrame)
	end
end

--- Main paper row (Melee / Ranged tab): same stat; ranged shows N/A without a ranged weapon.
function CSC_PaperDollFrame_SetPaperArmorPenetration(statFrame, unit, isRanged)
	if not statFrame then return end
	unit = unit or "player"
	local label = "Armor Penetration"
	statFrame._FluxArmorPenKind = isRanged and "ranged" or "melee"
	if isRanged and type(IsRangedWeapon) == "function" and not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, label, NOT_APPLICABLE, false)
		statFrame.tooltip = nil
		statFrame:SetScript("OnEnter", nil)
		statFrame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		if _G.FluxInfoFrame and _G.FluxInfoFrame.HookClassicCSCStatFrame then
			_G.FluxInfoFrame.HookClassicCSCStatFrame(statFrame)
		end
		return
	end
	if type(GetArmorPenetration) ~= "function" then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, label, NOT_APPLICABLE, false)
		return
	end
	local ap = GetArmorPenetration()
	CSC_PaperDollFrame_SetLabelAndText(statFrame, label, ap, false)
	if ITEM_MOD_ARMOR_PENETRATION_RATING then
		statFrame.tooltip = format(ITEM_MOD_ARMOR_PENETRATION_RATING, ap)
	else
		statFrame.tooltip = label .. " " .. tostring(ap)
	end
	statFrame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltip, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		GameTooltip:Show()
	end)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	if _G.FluxInfoFrame and _G.FluxInfoFrame.HookClassicCSCStatFrame then
		_G.FluxInfoFrame.HookClassicCSCStatFrame(statFrame)
	end
end

function CSC_PaperDollFrame_SetResilience(statFrame)
	local resilience = GetCombatRating(CR_RESILIENCE_CRIT_TAKEN);
	local bonus = GetCombatRatingBonus(CR_RESILIENCE_CRIT_TAKEN);

	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_RESILIENCE, resilience);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..STAT_RESILIENCE.." "..resilience..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = format(RESILIENCE_TOOLTIP, bonus, min(bonus * 2, 25.00), bonus);
end

-- SIDE STATS FRAME ================================================================================================================================================================
function CSC_SideFrame_SetMissChance(statFrame, unit, ratingIndex)
	local playerLevel = UnitLevel(unit);
	local totalHit;
	if (ratingIndex == CR_HIT_MELEE) then
		totalHit = CSC_GetTotalMeleeHitPercent(unit);
	elseif (ratingIndex == CR_HIT_RANGED) then
		totalHit = CSC_GetTotalRangedHitPercent(unit);
	else
		local hitChance = GetHitModifier() or 0;
		local hitRatingBonus = GetCombatRatingBonus(ratingIndex) or 0;
		totalHit = hitChance + hitRatingBonus;
	end
	local missChanceVsNPC, missChanceVsBoss, missChanceVsPlayer, dwMissChanceVsNpc, dwMissChanceVsBoss, dwMissChanceVsPlayer = CSC_GetPlayerMissChances(unit, totalHit);

	if (ratingIndex == CR_HIT_MELEE) then
		statFrame.tooltip = format("Miss Chance vs Level 73 NPC/Boss: %.2F%%", missChanceVsBoss)..CSC_SYMBOL_TAB..format("(Dual wield: %.2F%%)", dwMissChanceVsBoss);
		local missChanceNPCLineOne = format("Miss Chance vs Level %d NPC:     %.2F%%", playerLevel, missChanceVsNPC);
		local missChanceNPCLineTwo = format("(Dual wield: %.2F%%)", dwMissChanceVsNpc);

		local missChancePlayerLineOne = format("Miss Chance vs Level %d Player:  %.2F%%", playerLevel, missChanceVsPlayer);
		local missChancePlayerLineTwo = format("(Dual wield: %.2F%%)", dwMissChanceVsPlayer);
		statFrame.tooltip2 = missChanceNPCLineOne..CSC_SYMBOL_TAB..missChanceNPCLineTwo.."\n"..missChancePlayerLineOne..CSC_SYMBOL_TAB..missChancePlayerLineTwo;
	else
		statFrame.tooltip = format("Miss Chance vs Level 73 NPC/Boss: %.2F%%", missChanceVsBoss);
		statFrame.tooltip2 = format("Miss Chance vs Level %d NPC: %.2F%%", playerLevel, missChanceVsNPC).."\n"..format("Miss Chance vs Level %d Player: %.2F%%", playerLevel, missChanceVsPlayer);
	end

	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Miss Chance", missChanceVsBoss, true);
end

function CSC_SideFrame_SetCritCap(statFrame, unit, ratingIndex)
	local critCap, dwCritCap = CSC_GetPlayerCritCap(unit, ratingIndex);

	statFrame.tooltip = format("Crit cap vs Level 73 NPC/Boss: %.2F%%", critCap);
	if (ratingIndex == CR_HIT_MELEE) then
		local offhandItemId = GetInventoryItemID(unit, INVSLOT_OFFHAND);
		if (offhandItemId) then
			statFrame.tooltip2 = format("Dual wield crit cap: %.2F%%", dwCritCap);
		end
	end

	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Crit Cap", critCap, true);
end

-- Melee
function CSC_SideFrame_SetMeleeHitChance(statFrame, unit)
	
	statFrame:SetScript("OnEnter", CSC_CharacterMeleeHitChanceSideFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	local totalHit = CSC_GetTotalMeleeHitPercent(unit);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, totalHit, true);
end

function CSC_SideFrame_SetMeleeCritRating(statFrame, unit)
	local critBonus = CSC_GetDisplayMeleeCritPercent(unit) or 0;
	statFrame.tooltip = format(CR_CRIT_MELEE_TOOLTIP, GetCombatRating(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_MELEE));
	CSC_PaperDollFrame_SetLabelAndText(statFrame, COMBAT_RATING_NAME9, critBonus, true);
end

function CSC_SideFrame_SetMeleeHasteRating(statFrame, unit)
	local hasteRating = GetCombatRating(CR_HASTE_MELEE);
	local hasteBonus = GetCombatRatingBonus(CR_HASTE_MELEE);
	statFrame.tooltip = format(CR_HASTE_RATING_TOOLTIP, hasteRating, hasteBonus);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, CSC_HASTE_LABEL, hasteBonus, true);
end

function CSC_SideFrame_SetArmorPenetration(statFrame, unit, penKind)
	local armorPen = GetArmorPenetration();
	statFrame.tooltip = format(ITEM_MOD_ARMOR_PENETRATION_RATING, armorPen);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Armor Penetration", armorPen, false);
	statFrame._FluxArmorPenKind = (penKind == "ranged") and "ranged" or "melee"
	if _G.FluxInfoFrame and _G.FluxInfoFrame.HookClassicCSCStatFrame then
		_G.FluxInfoFrame.HookClassicCSCStatFrame(statFrame)
	end
end

-- Ranged
function CSC_SideFrame_SetRangedHitChance(statFrame, unit)
	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, NOT_APPLICABLE, false);
		return;
	end

	-- TODO: change this in the future with a dedicated function
	statFrame:SetScript("OnEnter", CSC_CharacterMeleeHitChanceSideFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	local totalHit = CSC_GetTotalRangedHitPercent(unit);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, totalHit, true);
end

function CSC_SideFrame_SetRangedCritRating(statFrame, unit)
	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, COMBAT_RATING_NAME9, NOT_APPLICABLE, false);
		return;
	end

	local critBonus = CSC_GetDisplayRangedCritPercent(unit) or 0;
	statFrame.tooltip = format(CR_CRIT_RANGED_TOOLTIP, GetCombatRating(CR_CRIT_RANGED), GetCombatRatingBonus(CR_CRIT_RANGED));
	CSC_PaperDollFrame_SetLabelAndText(statFrame, COMBAT_RATING_NAME9, critBonus, true);
end

function CSC_SideFrame_SetRangedHasteRating(statFrame, unit)
	if not IsRangedWeapon() then
		CSC_PaperDollFrame_SetLabelAndText(statFrame, CSC_HASTE_LABEL, NOT_APPLICABLE, false);
		return;
	end

	local hasteRating = GetCombatRating(CR_HASTE_RANGED);
	local hasteBonus = GetCombatRatingBonus(CR_HASTE_RANGED);
	statFrame.tooltip = format(CR_HASTE_RATING_TOOLTIP, hasteRating, hasteBonus);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, CSC_HASTE_LABEL, hasteBonus, true);
end

-- Spell
function CSC_SideFrame_SetSpellHitChance(statFrame, unit)
	-- TODO: change this in the future with a dedicated function
	statFrame:SetScript("OnEnter", CSC_CharacterMeleeHitChanceSideFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	local totalHit = CSC_GetTotalSpellHitPercent(unit);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_HIT_CHANCE, totalHit, true);
end

function CSC_SideFrame_SetSpellCritRating(statFrame, unit)
	local maxCrit = CSC_UpdateSpellCritStatFrame({}, unit);
	statFrame.tooltip = format(CR_CRIT_SPELL_TOOLTIP, GetCombatRating(CR_CRIT_SPELL), GetCombatRatingBonus(CR_CRIT_SPELL));
	CSC_PaperDollFrame_SetLabelAndText(statFrame, COMBAT_RATING_NAME11, maxCrit, true);
end

function CSC_SideFrame_SetSpellHastePercent(statFrame, unit)
	unit = unit or "player";
	local hasteRating = GetCombatRating(CR_HASTE_SPELL) or 0;
	local hasteFromRating = GetCombatRatingBonus(CR_HASTE_SPELL) or 0;
	local hastePercent = CSC_GetTotalSpellHastePercent(unit);
	statFrame.tooltip = CSC_FormatSpellHasteTooltipLine(hastePercent);
	if hasteRating > 0 and CR_HASTE_RATING_TOOLTIP then
		statFrame.tooltip = statFrame.tooltip .. "\n\n" .. format(CR_HASTE_RATING_TOOLTIP, hasteRating, hasteFromRating);
	end
	CSC_PaperDollFrame_SetLabelAndText(statFrame, CSC_HASTE_LABEL, hastePercent, true);
end

function CSC_SideFrame_SetSpellPenetration(statFrame, unit)
	local spellPen = GetSpellPenetration();
	statFrame.tooltip = format(SPELL_PENETRATION_TOOLTIP, spellPen, spellPen);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Spell Penetration", spellPen, false);
	if _G.FluxInfoFrame and _G.FluxInfoFrame.HookClassicCSCStatFrame then
		_G.FluxInfoFrame.HookClassicCSCStatFrame(statFrame)
	end
end

-- Defense
function CSC_SideFrame_SetDefenseRating(statFrame, unit)
	local defensePercent = GetDodgeBlockParryChanceFromDefense();
	local defenseRating = GetCombatRating(CR_DEFENSE_SKILL);
	local defense = GetCombatRatingBonus(CR_DEFENSE_SKILL);

	statFrame.tooltip = format(DEFAULT_STATDEFENSE_TOOLTIP, defenseRating, defense, defensePercent, defensePercent);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Defense Rating", defenseRating, false);
end

function CSC_SideFrame_SetDodgeRating(statFrame, unit)
	local dodgeRating = GetCombatRating(CR_DODGE);
	local dodgeChance = GetCombatRatingBonus(CR_DODGE);
	statFrame.tooltip = format(CR_DODGE_TOOLTIP, dodgeRating, dodgeChance);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Dodge Rating", dodgeRating, false);
end

function CSC_SideFrame_SetParryRating(statFrame, unit)
	local parryRating = GetCombatRating(CR_PARRY)
	local parryChance = GetCombatRatingBonus(CR_PARRY);
	statFrame.tooltip = format(CR_PARRY_TOOLTIP, parryRating, parryChance);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Parry Rating", parryRating, false);
end

function CSC_SideFrame_SetBlockRating(statFrame, unit)
	local blockRating = GetCombatRating(CR_BLOCK)
	local blockChance = GetCombatRatingBonus(CR_BLOCK);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Block Rating", blockRating, false);
end

function CSC_SideFrame_SetChanceToBeCrittedBy70(statFrame, unit)
	local unitClassId = select(3, UnitClass(unit));
	local base, modifier = UnitDefense(unit);
	local bonusFromTalents = 0;

	if unitClassId == CSC_DRUID_CLASS_ID then
		bonusFromTalents = CSC_TalentPoints(2, 16); -- Survival of the Fittest
	end

    local critChance = (base + modifier)*0.04 + GetCombatRatingBonus(16) + bonusFromTalents; 
	local critChance70 = 19 - critChance;
	local critChance70txt = format("%.2F%%", critChance70);
	
    if critChance70 <= 0 then
		critChance70txt = GREEN_FONT_COLOR_CODE..critChance70txt..FONT_COLOR_CODE_CLOSE;
	elseif critChance70 > 0 then
        critChance70txt = RED_FONT_COLOR_CODE..critChance70txt..FONT_COLOR_CODE_CLOSE;
	end
	
	statFrame.tooltip = "Chance to be critically hit by level 70";
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Crit by lvl 70", critChance70txt, false);
end

function CSC_SideFrame_SetChanceToBeCrittedBy73(statFrame, unit)
	local unitClassId = select(3, UnitClass(unit));
	local base, modifier = UnitDefense(unit);
	local bonusFromTalents = 0;

	if unitClassId == CSC_DRUID_CLASS_ID then
		bonusFromTalents = CSC_TalentPoints(2, 16); -- Survival of the Fittest
	end

	local critChance = (base + modifier)*0.04 + GetCombatRatingBonus(16) + bonusFromTalents;
	local critChance73 = 19.6 - critChance;
	local critChance73txt = format("%.2F%%", critChance73);
	
    if critChance73 <= 0 then
		critChance73txt = GREEN_FONT_COLOR_CODE..critChance73txt..FONT_COLOR_CODE_CLOSE;
	elseif critChance73 > 0 then
        critChance73txt = RED_FONT_COLOR_CODE..critChance73txt..FONT_COLOR_CODE_CLOSE;
	end
	
	statFrame.tooltip = "Chance to be critically hit by level 73";
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Crit by lvl 73", critChance73txt, false);
end

function CSC_SideFrame_SetAvoidance(statFrame, unit)
	local miss = GetDodgeBlockParryChanceFromDefense() + 5;
    local dodge = GetDodgeChance();
    local parry = GetParryChance();
    local block = GetBlockChance();
    local avoidanceCap = 102.4;
    local avoidanceCurrent = miss + dodge + parry + block;
	local avoidanceMissing = avoidanceCap - avoidanceCurrent;
	local avoidanceMissingTxt = format("%.2F%%", avoidanceMissing);

    if avoidanceMissing <= 0 then
		avoidanceMissingTxt = GREEN_FONT_COLOR_CODE..avoidanceMissingTxt..FONT_COLOR_CODE_CLOSE;
    end
    if avoidanceMissing > 0 then
        avoidanceMissingTxt = RED_FONT_COLOR_CODE..avoidanceMissingTxt..FONT_COLOR_CODE_CLOSE;
	end
	
	statFrame.tooltip = "Needed Avoidance";
	statFrame.tooltip2 = format("Needed %.2F%% Avoidance (Miss + Dodge + Parry + Block) to reach Crush cap (%.2F%%).\nCurrent: %.F%%", avoidanceMissing, avoidanceCap, avoidanceCurrent);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Avoidance", avoidanceMissingTxt, false);
end

function CSC_SideFrame_SetDefenseUncritableCap(statFrame, unit)
	local unitClassId = select(3, UnitClass(unit));
	local base, modifier = UnitDefense(unit);
	local bonusFromTalents = 0;

	if unitClassId == CSC_DRUID_CLASS_ID then
		bonusFromTalents = CSC_TalentPoints(2, 16); -- Survival of the Fittest
	end

	local critChance = (base + modifier)*0.04 + GetCombatRatingBonus(16) + bonusFromTalents;
	local defCap73 = (19.6 - critChance)/0.04*2.4;
	local defCap73txt = format("%.2F", defCap73);
	
    if defCap73 <= 0 then
		defCap73txt = GREEN_FONT_COLOR_CODE..defCap73txt..FONT_COLOR_CODE_CLOSE;
	elseif defCap73 > 0 then
        defCap73txt = RED_FONT_COLOR_CODE..defCap73txt..FONT_COLOR_CODE_CLOSE;
	end

	statFrame.tooltip = "Needed Defense rating to become uncritable against lvl 73";
	statFrame.tooltip2 = "Takes into account both Defense and Resilience rating";
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Defense to cap", defCap73txt, false);
end

function CSC_SideFrame_SetResilienceUncritableCap(statFrame, unit)
	local unitClassId = select(3, UnitClass(unit));
	local base, modifier = UnitDefense(unit);
	local bonusFromTalents = 0;

	if unitClassId == CSC_DRUID_CLASS_ID then
		bonusFromTalents = CSC_TalentPoints(2, 16); -- Survival of the Fittest
	end

	local critChance = (base + modifier)*0.04 + GetCombatRatingBonus(16) + bonusFromTalents;
	local defCap73 = (19.6 - critChance)*39.42;
	local defCap73txt = format("%.2F", defCap73);

    if defCap73 <= 0 then
		defCap73txt = GREEN_FONT_COLOR_CODE..defCap73txt..FONT_COLOR_CODE_CLOSE;
	elseif defCap73 > 0 then
        defCap73txt = RED_FONT_COLOR_CODE..defCap73txt..FONT_COLOR_CODE_CLOSE;
	end

	statFrame.tooltip = "Needed Resilience rating to become uncritable against lvl 73";
	statFrame.tooltip2 = "Takes into account both Defense and Resilience rating";
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Resilience to cap", defCap73txt, false);
end

-- SIDE STATS FRAME END ================================================================================================================================================================

-- Section: CharacterStatsTbcClassUtils.lua

--[[
    Util functions specific for Classes
]]

-- returns additional crit % stats from Arcane instability and Critical Mass if any
function CSC_GetMageCritStatsFromTalents()

	-- !! It looks like these are already included in TBC by default
	local arcaneInstabilityCrit = 0;
	local criticalMassCrit = 0;

	-- Arcane Instability (1, 2, 3)%
	-- !!! Already added by default
	--arcaneInstabilityCrit = select(5, GetTalentInfo(1, 17));

	-- Critical Mass (2, 4, 6)%
	--local criticalMassTable = { 2, 4, 6 };
	--local spellRank = select(5, GetTalentInfo(2, 14));
	--if (spellRank > 0) and (spellRank <= 3) then
	--	criticalMassCrit = criticalMassTable[spellRank];
    --end

	return arcaneInstabilityCrit, criticalMassCrit;
end

-- returns the spell hit from Arcane Focus and Elemental Precision talents
function CSC_GetMageSpellHitFromTalents()
	-- Arcane Focus: 2% per rank (TBC/Wrath)
	local arcaneHit = CSC_GetTalentRankByName(1, 2, "Arcane Focus") * 2;
	-- Elemental Precision: 1% per rank on TBC/Wrath (CharacterStatsTBC uses rank as %)
	local frostFireHit = CSC_GetTalentRankByName(3, 3, "Elemental Precision");
	return arcaneHit, frostFireHit;
end

-- returns the spell hit from Suppression talent
function CSC_GetWarlockSpellHitFromTalents()
	return CSC_GetTalentRankByName(1, 1, "Suppression") * 2; -- 2% per rank
end

-- returns the spell crit from Devastation talent
function CSC_GetWarlockCritStatsFromTalents()
	-- the spell rank is equal to the value
	local devastationCrit = CSC_TalentPoints(3, 7);

	return devastationCrit;
end

-- returns the combined crit stats from Holy Specialization and Force of Will
function CSC_GetPriestCritStatsFromTalents()
	
	local holySpecializationCrit = 0;
	local forceOfWillCrit = 0;

	-- !!! Already counted by default
	-- Holy Specialization (1, 2, 3, 4, 5)%
	--holySpecializationCrit = select(5, GetTalentInfo(2, 3));

	-- Force of Will (1, 2, 3, 4, 5)%
	forceOfWillCrit = CSC_TalentPoints(1, 17);

    local critCombined = holySpecializationCrit + forceOfWillCrit;
	return critCombined;
end

-- returns the healing modifier from Spiritual Healing talent for Priests
function CSC_GetPriestBonusHealingModifierFromTalents()
	-- Spiritual Healing
	local spellRank = CSC_TalentPoints(2, 15);
	return spellRank * 0.02;
end

-- returns the crit bonus from Holy Power
-- Already counted by default
function CSC_GetPaladinCritStatsFromTalents()
	-- Holy Power (1, 2, 3, 4, 5)%
	local spellRank = CSC_TalentPoints(1, 13);

	return spellRank;
end

-- returns the defense bonus from the Anticipation Prot talent
local function CSC_GetPaladinDefenseFromTalents()

    local defense = 0;
    local defenseTable = { 2, 4, 6, 8, 10 };

    -- Anticipation (2, 4, 6, 8, 10)%
    local spellRank = CSC_TalentPoints(2, 9);
    if (spellRank > 0) and (spellRank <=5) then
        defense = defenseTable[spellRank];
    end

    return defense;
end

-- returns the modifier from Improved Blessing of Wisdom Holy talent
function CSC_GetPaladinImprovedBoWModifier()
	-- Improved Blessing of Wisdom
	local spellRank = CSC_TalentPoints(1, 10);

	return spellRank * 0.1;
end

-- Checks if spellId is Blessing of Wisdom
function CSC_IsBoWSpellId(spellId)

	if (spellId == 19742 or spellId == 19850 or spellId == 19852 or spellId == 19853 or spellId == 19854 or spellId == 25290 or spellId == 27142 or spellId == 25894 or spellId == 25918 or spellId == 27143) then
		return true;
	end

	return false;
end

-- returns the defense bonus from the Anticipation Prot talent
local function CSC_GetWarriorDefenseFromTalents()
    
    local defense = 0;
    local defenseTable = { 2, 4, 6, 8, 10 };

    -- Anticipation (2, 4, 6, 8, 10)%
    local spellRank = CSC_TalentPoints(3, 2);
    if (spellRank > 0) and (spellRank <=5) then
		defense = defenseTable[spellRank];
	end

    return defense;
end

function CSC_GetDefenseFromTalents(unit)
    
	local defense = 0;
	local unitClassId = select(3, UnitClass(unit));

    if (unitClassId == CSC_PALADIN_CLASS_ID) then
        defense = CSC_GetPaladinDefenseFromTalents();
    elseif (unitClassId == CSC_WARRIOR_CLASS_ID) then
        defense = CSC_GetWarriorDefenseFromTalents();
    end

    return defense;
end

-- returns the shapeshift form index for druids
function CSC_GetShapeshiftForm()
	local shapeIndex = 0;

	for possibleForm=1, GetNumShapeshiftForms() do
		if select(2, GetShapeshiftFormInfo(possibleForm)) then
			shapeIndex = possibleForm;
		end
	end

	return shapeIndex;
end

-- already included by default
-- returns the bonus hit from Nature's Guidance talent (counts as melee and spell hit)
function CSC_GetShamanHitFromTalents()
	-- Nature's Guidance
	return CSC_TalentPoints(3, 6);
end

function CSC_GetShamanHitFromElementalPrecision()
	local spellRank = CSC_GetTalentRankByName(1, 15, "Elemental Precision");
	return 2 * spellRank; -- matches CharacterStatsTBC (Elemental tab EP)
end

-- returns the bonus crit from the Call of Thunder talent for Shamans
function CSC_GetShamanCallOfThunderCrit()
	-- Call of Thunder (Lightning)
	return CSC_TalentPoints(1, 8);
end

-- returns the bonus crit from the Tidal Mastery telent for Shamans
function CSC_GetShamanTidalMasteryCrit()
	-- Tidal Mastery (Nature/Lightning)
	return CSC_TalentPoints(3, 11);
end

-- ITEMS AND ENCHANTS RELATED
function CSC_GetMP5ModifierFromTalents(unit)
    local unitClassId = select(3, UnitClass(unit));
	local spellRank = 0;

	-- All of these spells have 3 ranks (10%, 20%, 30%)
	if unitClassId == CSC_PRIEST_CLASS_ID then
		-- Meditation
        spellRank = CSC_TalentPoints(1, 9);
	elseif unitClassId == CSC_MAGE_CLASS_ID then
		-- Arcane Meditation
		spellRank = CSC_TalentPoints(1, 12);
	elseif unitClassId == CSC_DRUID_CLASS_ID then
		-- Intensity
        spellRank = CSC_TalentPoints(3, 6);
	end
	
	local modifier = spellRank * 0.1;

    return modifier;
end

function CSC_GetMP5FromSetBonus(unit)
	local unitClassId = select(3, UnitClass(unit));
	local mp5 = 0;
	
	-- not Druid or Priest
	if unitClassId ~= CSC_DRUID_CLASS_ID and unitClassId ~= CSC_PRIEST_CLASS_ID then
		return mp5;
	end
	
	local firstItemslotIndex = 1;
	local lastItemslotIndex = 18;

	local equippedSetItems = 0;
    for itemSlot = firstItemslotIndex, lastItemslotIndex do
        local itemId = GetInventoryItemID(unit, itemSlot);
		
		if (itemId) then
			if (itemId == g_VestmentsOfTranscendenceIds[itemId] or itemId == g_StormrageRaimentIds[itemId]) then
				equippedSetItems = equippedSetItems + 1;
			end
		end
    end

    if equippedSetItems >= 3 then
        mp5 = 20;
	end

    return mp5;
end

function CSC_GetMP5ModifierFromSetBonus(unit)
	local unitClassId = select(3, UnitClass(unit));
	local modifier = 0;

	if unitClassId ~= CSC_DRUID_CLASS_ID and unitClassId ~= CSC_PRIEST_CLASS_ID  and unitClassId ~= CSC_PALADIN_CLASS_ID and unitClassId ~= CSC_SHAMAN_CLASS_ID then
		return modifier;
	end

	local firstItemslotIndex = 1;
	local lastItemslotIndex = 18;

	local equippedSetItems = 0;
    for itemSlot = firstItemslotIndex, lastItemslotIndex do
        local itemId = GetInventoryItemID(unit, itemSlot);
		
		if (itemId) then
			if (itemId == g_PrimalMooncloth[itemId]) then
				equippedSetItems = equippedSetItems + 1;
			end
		end
    end

    if equippedSetItems >= 3 then
        modifier = 0.05;
	end

    return modifier;
end

function CSC_GetShamanT2SpellCrit(unit)
	local spellCritFromSet = 0;
	local firstItemslotIndex = 1;
	local lastItemslotIndex = 18;

	local equippedSetItems = 0;
    for itemSlot = firstItemslotIndex, lastItemslotIndex do
        local itemId = GetInventoryItemID(unit, itemSlot);
		
		if (itemId) then
			if (itemId == g_TheTenStormsIds[itemId]) then
				equippedSetItems = equippedSetItems + 1;
			end
		end
    end

    if equippedSetItems >= 5 then
        spellCritFromSet = 3;
	end

    return spellCritFromSet;
end

function CSC_GetHolyCritFromBenediction(unit)
	local benedictionCrit = 0;
	local itemId = GetInventoryItemID(unit, INVSLOT_MAINHAND);
	
	if itemId == 18608 then
		benedictionCrit = 2;
	end

	return benedictionCrit;
end

function CSC_GetBlockValueFromWarriorZGEnchants(unit)
	local blockValue = 0;

	if CSC_HasEnchant(unit, INVSLOT_HEAD, 2583) then
		blockValue = blockValue + 15;
	end

	if CSC_HasEnchant(unit, INVSLOT_LEGS, 2583) then
		blockValue = blockValue + 15;
	end

	return blockValue;
end

function CSC_GetMp5FromPriestZGEnchants(unit)
	local mp5 = 0;

	if CSC_HasEnchant(unit, INVSLOT_HEAD, 2590) then
		mp5 = mp5 + 4;
	end

	if CSC_HasEnchant(unit, INVSLOT_LEGS, 2590) then
		mp5 = mp5 + 4;
	end

	return mp5;
end

-- Section: CharacterStatsTbcCallbacks.lua

-- OnEnter Tooltip functions
function CSC_CharacterDamageFrame_OnEnter(self)
	-- Main hand weapon
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(self.TooltipMainTxt, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2F", self.attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(DAMAGE_COLON, self.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1F", self.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(ATTACK_TOOLTIP..":", self.attackRating, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	-- Check for offhand weapon
	if ( self.offhandAttackSpeed ) then
		GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
		GameTooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2F", self.offhandAttackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddDoubleLine(DAMAGE_COLON, self.offhandDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1F", self.offhandDps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	GameTooltip:Show();
end

function CSC_CharacterSpellDamageFrame_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(STAT_SPELLPOWER, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(STAT_SPELLPOWER_TOOLTIP);
	GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
	for i=2, MAX_SPELL_SCHOOLS do
		GameTooltip:AddDoubleLine(getglobal("DAMAGE_SCHOOL"..i), format("%.2F", GetSpellBonusDamage(i)), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..i);
	end

	if (self.spVsUndead ~= nil and UISettingsCharacter.showStatsFromArgentDawnItems) then
		GameTooltip:AddDoubleLine(DAMAGE.." vs Undead: ", format("%.2F", self.spVsUndead), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	GameTooltip:Show();
end

function CSC_CharacterSpellCritFrame_OnEnter(self)
	if (CSC_UseUnifiedSecondaryStats()) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		local maxTxt = format("%.2F%%", self.critChance or GetCritChance());
		GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..CSC_CRIT_LABEL_UNIFIED.." "..maxTxt..FONT_COLOR_CODE_CLOSE);
		local cr = CSC_CritCombatRatingIndex();
		local tipFmt = rawget(_G, "CR_CRIT_SPELL_TOOLTIP") or rawget(_G, "CR_CRIT_MELEE_TOOLTIP");
		if (tipFmt and cr) then
			GameTooltip:AddLine(format(tipFmt, GetCombatRating(cr), GetCombatRatingBonus(cr)));
		end
		GameTooltip:Show();
		return;
	end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	local maxTxt = self.maxSpellCrit and format("%.2F%%", self.maxSpellCrit) or format("%.2F%%", GetSpellCritChance(2));
	GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..COMBAT_RATING_NAME11.." "..maxTxt..FONT_COLOR_CODE_CLOSE);
	GameTooltip:AddDoubleLine(getglobal("DAMAGE_SCHOOL"..2), format("%.2F", self.holyCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..2);
	GameTooltip:AddDoubleLine(getglobal("DAMAGE_SCHOOL"..3), format("%.2F", self.fireCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..3);
	GameTooltip:AddDoubleLine(getglobal("DAMAGE_SCHOOL"..5), format("%.2F", self.frostCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..5);
	GameTooltip:AddDoubleLine(getglobal("DAMAGE_SCHOOL"..7), format("%.2F", self.arcaneCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..7);
	GameTooltip:AddDoubleLine(getglobal("DAMAGE_SCHOOL"..6), format("%.2F", self.shadowCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..6);
	GameTooltip:AddDoubleLine(getglobal("DAMAGE_SCHOOL"..4), format("%.2F", self.natureCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..4);

	if self.unitClassId == CSC_SHAMAN_CLASS_ID then
		GameTooltip:AddDoubleLine(CSC_LIGHTNING_TXT, format("%.2F", self.lightningCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end

	GameTooltip:Show();
end

function CSC_CharacterManaRegenFrame_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(format(MANA_REGEN_TOOLTIP, self.mp5NotCasting, self.mp5Casting), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(MANA_REGEN.." (From Gear):", self.mp5FromGear);
	GameTooltip:AddDoubleLine(MANA_REGEN.." (While Casting):", self.mp5Casting);
	GameTooltip:AddDoubleLine(MANA_REGEN.." (While Not Casting):", self.mp5NotCasting);
	GameTooltip:Show();
end

function CSC_CharacterBlock_OnEnter(self)
	
	if UISettingsGlobal.useBlizzardBlockValue then
		self.blockValue = GetShieldBlock();
	else
		self.blockValue = CSC_GetBlockValue("player");
		
		local unitClassId = select(3, UnitClass("player"));
		if (unitClassId == CSC_WARRIOR_CLASS_ID) then
			local blockFromZGEnchants = CSC_GetBlockValueFromWarriorZGEnchants("player");
			if (blockFromZGEnchants > 0) then
				self.blockValue = self.blockValue + blockFromZGEnchants;
			end
		end
	end

	local blockRatingTxt = format(CR_BLOCK_TOOLTIP, GetCombatRating(CR_BLOCK), GetCombatRatingBonus(CR_BLOCK), self.blockValue);
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(self.blockChance);
	GameTooltip:AddLine(blockRatingTxt);
	GameTooltip:Show();
end

function CSC_CharacterHitChanceFrame_OnEnter(self)
	local hitChance = self.hitChance;

	local totalWeaponSkill = CSC_GetPlayerWeaponSkill("player", INVSLOT_MAINHAND);
	local missChanceVsNPC, missChanceVsBoss, missChanceVsPlayer, dwMissChanceVsNpc, dwMissChanceVsBoss, dwMissChanceVsPlayer = CSC_GetPlayerMissChances("player", hitChance, totalWeaponSkill);

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(STAT_HIT_CHANCE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddLine("Reduces your chance to miss.");

	GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
	GameTooltip:AddLine("Miss Chance vs.");
	GameTooltip:AddDoubleLine(format(CSC_SYMBOL_TAB.."Level 60 NPC: %.2F%%", missChanceVsNPC), format("(Dual wield: %.2F%%)", dwMissChanceVsNpc));
	GameTooltip:AddDoubleLine(format(CSC_SYMBOL_TAB.."Level 60 Player: %.2F%%", missChanceVsPlayer), format("(Dual wield: %.2F%%)", dwMissChanceVsPlayer));
	GameTooltip:AddDoubleLine(format(CSC_SYMBOL_TAB.."Level 63 NPC/Boss: %.2F%%", missChanceVsBoss), format("(Dual wield: %.2F%%)", dwMissChanceVsBoss));
	GameTooltip:Show();
end

function CSC_CharacterRangedHitChanceFrame_OnEnter(self)
	local hitChance = self.hitChance;

	local totalWeaponSkill = CSC_GetPlayerWeaponSkill("player", INVSLOT_RANGED);
	local missChanceVsNPC, missChanceVsBoss, missChanceVsPlayer, _, _, _ = CSC_GetPlayerMissChances("player", hitChance, totalWeaponSkill);

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(STAT_HIT_CHANCE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddLine("Reduces your chance to miss.");

	GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
	GameTooltip:AddLine("Miss Chance vs.");
	GameTooltip:AddLine(format(CSC_SYMBOL_TAB.."Level 60 NPC: %.2F%%", missChanceVsNPC));
	GameTooltip:AddLine(format(CSC_SYMBOL_TAB.."Level 60 Player: %.2F%%", missChanceVsPlayer));
	GameTooltip:AddLine(format(CSC_SYMBOL_TAB.."Level 63 NPC/Boss: %.2F%%", missChanceVsBoss));
	GameTooltip:Show();
end

function CSC_CharacterSpellHitChanceFrame_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(format(CSC_SPELL_HIT_TOOLTIP_TXT, self.hitChance), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

	-- Per-school: Arcane/Elemental Precision on top of shared base (gear + auras + racial), not the headline total
	local shared = self.spellHitSharedBase;
	if (shared == nil) and (type(CSC_GetSpellHitSharedBase) == "function") then
		shared = CSC_GetSpellHitSharedBase("player");
	end
	if (shared == nil) then
		shared = self.hitChance;
	end
	if self.unitClassId == CSC_MAGE_CLASS_ID then
		GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
		GameTooltip:AddLine(CSC_SPELL_HIT_SUBTOOLTIP_TXT);
		GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_ARCANE_SPELL_HIT_TXT, (self.arcaneHit + shared).."%");
		GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_FIRE_SPELL_HIT_TXT, (self.fireHit + shared).."%");
		GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_FROST_SPELL_HIT_TXT, (self.frostHit + shared).."%");
	elseif self.unitClassId == CSC_WARLOCK_CLASS_ID then
		GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
		GameTooltip:AddLine(CSC_SPELL_HIT_SUBTOOLTIP_TXT);
		local wshared = (self.spellHitSharedBase ~= nil) and self.spellHitSharedBase
			or (type(CSC_GetSpellHitSharedBase) == "function" and CSC_GetSpellHitSharedBase("player"))
			or self.hitChance;
		GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_DESTRUCTION_SPELL_HIT_TXT, wshared.."%");
		GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_AFFLICTION_SPELL_HIT_TXT, (self.afflictionHit + wshared).."%");
	elseif self.unitClassId == CSC_PRIEST_CLASS_ID then
		GameTooltip:AddLine(CSC_SYMBOL_SPACE);
		local sh = (self.spellHitSharedBase ~= nil) and self.spellHitSharedBase
			or (type(CSC_GetSpellHitSharedBase) == "function" and CSC_GetSpellHitSharedBase("player")) or 0
		local sf = (self.shadowFocusHit ~= nil) and (self.shadowFocusHit or 0)
			or (type(CSC_GetPriestShadowFocusSpellHit) == "function" and (CSC_GetPriestShadowFocusSpellHit() or 0)) or 0
		GameTooltip:AddLine(CSC_SPELL_HIT_SUBTOOLTIP_TXT);
		GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB.."Holy", format("%.1f%%", sh));
		GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB.."Shadow", format("%.1f%%", sh + sf));
	elseif self.unitClassId == CSC_SHAMAN_CLASS_ID then
		GameTooltip:SetText(format(CSC_SPELL_HIT_TOOLTIP_2_TXT, self.hitChance), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	GameTooltip:Show();
end

function CSC_CharacterHitRatingFrame_OnEnter(self)

	local unit = self.unit;
	local ratingIndex = self.ratingIndex;
	local statName = self.statName;
	local rating = self.rating;
	local ratingBonus = self.ratingBonus;
	local playerLevel = UnitLevel(unit);
	local unitClassId = select(3, UnitClass(unit));

	-- Set the tooltip text (ratingBonus is total hit %%; rating is the same as string for legacy fields)
	local tooltip = HIGHLIGHT_FONT_COLOR_CODE..statName.." "..format("%.2F%%", ratingBonus)..FONT_COLOR_CODE_CLOSE;
	local tooltip2 = " ";

	if ( ratingIndex == CR_HIT_MELEE ) then
		tooltip2 = format(CR_HIT_MELEE_TOOLTIP, playerLevel, ratingBonus, GetArmorPenetration());
	elseif ( ratingIndex == CR_HIT_RANGED ) then
		tooltip2 = format(CR_HIT_RANGED_TOOLTIP, playerLevel, ratingBonus, GetArmorPenetration());
	elseif ( ratingIndex == CR_HIT_SPELL ) then
		-- spell hit from talents
		if unitClassId == CSC_MAGE_CLASS_ID then
			local arcaneHit, frostFireHit = CSC_GetMageSpellHitFromTalents();
			self.arcaneHit = arcaneHit;
			self.frostHit = frostFireHit;
			self.fireHit = frostFireHit;
		elseif unitClassId == CSC_WARLOCK_CLASS_ID then
			self.afflictionHit = CSC_GetWarlockSpellHitFromTalents();
		elseif unitClassId == CSC_PRIEST_CLASS_ID and type(CSC_GetPriestShadowFocusSpellHit) == "function" then
			self.shadowFocusHit = CSC_GetPriestShadowFocusSpellHit() or 0
		end
		tooltip2 = format(CR_HIT_SPELL_TOOLTIP, playerLevel, ratingBonus, GetSpellPenetration(), GetSpellPenetration());
	else
		tooltip2 = HIGHLIGHT_FONT_COLOR_CODE..getglobal("COMBAT_RATING_NAME"..ratingIndex).." "..rating;	
	end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(tooltip, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddLine(tooltip2);

	if (ratingIndex == CR_HIT_SPELL) then
		if unitClassId == CSC_MAGE_CLASS_ID then
			local sbase = (self.spellHitSharedBase ~= nil) and self.spellHitSharedBase
				or (type(CSC_GetSpellHitSharedBase) == "function" and CSC_GetSpellHitSharedBase(self.unit or "player")) or 0;
			GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
			GameTooltip:AddLine(CSC_SPELL_HIT_SUBTOOLTIP_TXT);
			GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_ARCANE_SPELL_HIT_TXT, format("%.2F%%", self.arcaneHit + sbase));
			GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_FIRE_SPELL_HIT_TXT, format("%.2F%%", self.fireHit + sbase));
			GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_FROST_SPELL_HIT_TXT, format("%.2F%%", self.frostHit + sbase));
		elseif unitClassId == CSC_WARLOCK_CLASS_ID then
			local sbaseW = (self.spellHitSharedBase ~= nil) and self.spellHitSharedBase
				or (type(CSC_GetSpellHitSharedBase) == "function" and CSC_GetSpellHitSharedBase(self.unit or "player")) or 0;
			GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
			GameTooltip:AddLine(CSC_SPELL_HIT_SUBTOOLTIP_TXT);
			GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_DESTRUCTION_SPELL_HIT_TXT, format("%.2F%%", sbaseW));
			GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB..CSC_AFFLICTION_SPELL_HIT_TXT, format("%.2F%%", self.afflictionHit + sbaseW));
		elseif unitClassId == CSC_PRIEST_CLASS_ID then
			local sbaseP = (self.spellHitSharedBase ~= nil) and self.spellHitSharedBase
				or (type(CSC_GetSpellHitSharedBase) == "function" and CSC_GetSpellHitSharedBase(self.unit or "player")) or 0;
			local sfP = (self.shadowFocusHit ~= nil) and (self.shadowFocusHit or 0)
				or (type(CSC_GetPriestShadowFocusSpellHit) == "function" and (CSC_GetPriestShadowFocusSpellHit() or 0)) or 0;
			GameTooltip:AddLine(CSC_SYMBOL_SPACE);
			GameTooltip:AddLine(CSC_SPELL_HIT_SUBTOOLTIP_TXT);
			GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB.."Holy", format("%.2F%%", sbaseP));
			GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB.."Shadow", format("%.2F%%", sbaseP + sfP));
		end
	elseif (ratingIndex == CR_HIT_MELEE) then
		local missChanceVsNPC, missChanceVsBoss, missChanceVsPlayer, dwMissChanceVsNpc, dwMissChanceVsBoss, dwMissChanceVsPlayer = CSC_GetPlayerMissChances(unit, ratingBonus);
		GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
		GameTooltip:AddLine("Miss Chance vs.");
		GameTooltip:AddDoubleLine(format(CSC_SYMBOL_TAB.."Level %d NPC: %.2F%%", playerLevel, missChanceVsNPC), format("(Dual wield: %.2F%%)", dwMissChanceVsNpc));
		GameTooltip:AddDoubleLine(format(CSC_SYMBOL_TAB.."Level %d Player: %.2F%%", playerLevel, missChanceVsPlayer), format("(Dual wield: %.2F%%)", dwMissChanceVsPlayer));
		GameTooltip:AddDoubleLine(format(CSC_SYMBOL_TAB.."Level 73 NPC/Boss: %.2F%%", missChanceVsBoss), format("(Dual wield: %.2F%%)", dwMissChanceVsBoss));
	elseif (ratingIndex == CR_HIT_RANGED) then
		local missChanceVsNPC, missChanceVsBoss, missChanceVsPlayer, _, _, _ = CSC_GetPlayerMissChances(unit, ratingBonus);
		GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
		GameTooltip:AddLine("Miss Chance vs.");
		GameTooltip:AddDoubleLine(format(CSC_SYMBOL_TAB.."Level %d NPC: %.2F%%", playerLevel, missChanceVsNPC));
		GameTooltip:AddDoubleLine(format(CSC_SYMBOL_TAB.."Level %d Player: %.2F%%", playerLevel, missChanceVsPlayer));
		GameTooltip:AddDoubleLine(format(CSC_SYMBOL_TAB.."Level 73 NPC/Boss: %.2F%%", missChanceVsBoss));
	end
	
	GameTooltip:Show();
end

function CSC_CharacterMeleeCritFrame_OnEnter(self)
	if (CSC_UseUnifiedSecondaryStats()) then
		local label = CSC_CRIT_LABEL_UNIFIED;
		local critChanceTxt = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, label).." "..format("%.2F%%", self.critChance);
		local cr = CSC_CritCombatRatingIndex();
		local tipFmt = rawget(_G, "CR_CRIT_SPELL_TOOLTIP") or rawget(_G, "CR_CRIT_MELEE_TOOLTIP");
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(critChanceTxt, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		if (tipFmt and cr) then
			GameTooltip:AddLine(format(tipFmt, GetCombatRating(cr), GetCombatRatingBonus(cr)));
		end
		GameTooltip:Show();
		return;
	end
	
	local critChanceTxt = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MELEE_CRIT_CHANCE).." "..format("%.2F%%", self.critChance);
	local critRatingTxt = format(CR_CRIT_MELEE_TOOLTIP, GetCombatRating(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_MELEE));

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(critChanceTxt, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddLine(critRatingTxt);
	
	GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
	GameTooltip:AddLine("Crit cap vs.");
	local critCap, dwCritCap = CSC_GetPlayerCritCap(self.unit, CR_HIT_MELEE);
	
	local CRITCAP_COLOR_CODE = GREEN_FONT_COLOR_CODE;
	if self.critChance > critCap then CRITCAP_COLOR_CODE = ORANGE_FONT_COLOR_CODE end
	local critCapTxt = CRITCAP_COLOR_CODE..format("%.2F%%", critCap)..FONT_COLOR_CODE_CLOSE;

	local offhandItemId = GetInventoryItemID("player", INVSLOT_OFFHAND);
	if (offhandItemId) then
		local DWCRITCAP_COLOR_CODE = GREEN_FONT_COLOR_CODE;
		if self.critChance > dwCritCap then DWCRITCAP_COLOR_CODE = ORANGE_FONT_COLOR_CODE end

		local critCapDwTxt = DWCRITCAP_COLOR_CODE..format("%.2F%%", dwCritCap)..FONT_COLOR_CODE_CLOSE;
		GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB.."Level 73 NPC/Boss: "..critCapTxt, "(Dual wield: "..critCapDwTxt..")");
	else
		GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB.."Level 73 NPC/Boss: "..critCapTxt);
	end

	GameTooltip:Show();
end

function CSC_CharacterRangedCritFrame_OnEnter(self)
	if (CSC_UseUnifiedSecondaryStats()) then
		local label = CSC_CRIT_LABEL_UNIFIED;
		local critChanceTxt = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, label).." "..format("%.2F%%", self.critChance);
		local cr = CSC_CritCombatRatingIndex();
		local tipFmt = rawget(_G, "CR_CRIT_SPELL_TOOLTIP") or rawget(_G, "CR_CRIT_MELEE_TOOLTIP");
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(critChanceTxt, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		if (tipFmt and cr) then
			GameTooltip:AddLine(format(tipFmt, GetCombatRating(cr), GetCombatRatingBonus(cr)));
		end
		GameTooltip:Show();
		return;
	end
	local critChanceTxt = HIGHLIGHT_FONT_COLOR_CODE..RANGED_CRIT_CHANCE.." "..format("%.2F%%", self.critChance)..FONT_COLOR_CODE_CLOSE;
	local critRatingTxt = format(CR_CRIT_RANGED_TOOLTIP, GetCombatRating(CR_CRIT_RANGED), GetCombatRatingBonus(CR_CRIT_RANGED));

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(critChanceTxt, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddLine(critRatingTxt);

	GameTooltip:AddLine(CSC_SYMBOL_SPACE); -- Blank line.
	GameTooltip:AddLine("Crit cap vs.");
	local critCap, _ = CSC_GetPlayerCritCap(self.unit, CR_HIT_RANGED);
	
	local CRITCAP_COLOR_CODE = GREEN_FONT_COLOR_CODE;
	if self.critChance > critCap then CRITCAP_COLOR_CODE = ORANGE_FONT_COLOR_CODE end
	local critCapTxt = CRITCAP_COLOR_CODE..format("%.2F%%", critCap)..FONT_COLOR_CODE_CLOSE;
	GameTooltip:AddDoubleLine(CSC_SYMBOL_TAB.."Level 73 NPC/Boss: "..critCapTxt);

	GameTooltip:Show();
end

function CSC_CharacterDefenseFrame_OnEnter(self)
	local defensePercent = GetDodgeBlockParryChanceFromDefense();
	local ratingTxt = format(DEFAULT_STATDEFENSE_TOOLTIP, GetCombatRating(CR_DEFENSE_SKILL), GetCombatRatingBonus(CR_DEFENSE_SKILL), defensePercent, defensePercent);

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(self.defense, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddLine(ratingTxt);
	GameTooltip:Show();
end

-- SIDE FRAME CALLBACKS
function CSC_CharacterMeleeHitChanceSideFrame_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(STAT_HIT_CHANCE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddLine("Your total hit rating converted to hit chance (including gear and talents)");
	GameTooltip:Show();
end
-- SIDE FRAME CALLBACKS END
-- OnEnter Tooltip functions END


