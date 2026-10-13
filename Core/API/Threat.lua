-- Threat.lua — secret-safe threat queries + Flux rank / scaled-% display.
-- Forever (wow-ui-source-forever): UnitThreatLeadSituation, UnitThreatPercentageOfLead,
-- ShouldUnitThreat*BeSecret, nameplateThreatDisplay, threatShowNumeric exist as APIs
-- but Combat settings do not expose them. GetNumericDisplay stays Classic-style:
-- group placement plus tank-relative scaled % (100 = tanking). Forever nameplates,
-- the target bar, and the Details meter use GetForeverFrameDisplay instead
-- (rawPercentage, or lead % while tanking). Capture multi-returns inside pcall so
-- secret extra returns are not dropped. Never Lua-compare secret numbers;
-- FontString:SetFormattedText and StatusBar:SetValue are the display path.
local addonName, ns = ...
local Flux = ns.Flux
local Client = Flux.Client
local Secrets = Flux.Secrets
local CVar = Flux.CVar
local Spec = Flux.Spec

local Threat = {}
Flux.Threat = Threat
Flux.API = Flux.API or {}
Flux.API.Threat = Threat
ns.API = ns.API or {}
ns.API.Threat = Threat

local pcall = pcall
local type = type
local tonumber = tonumber

local NAMEPLATE_THREAT_CVAR = "nameplateThreatDisplay"
local NUMERIC_THREAT_CVAR = "threatShowNumeric"
local THREAT_WARNING_CVAR = "threatWarning"

local numericOverride = nil

local function IsSecret(v)
	return Secrets and Secrets.IsSecretValue and Secrets.IsSecretValue(v)
end

local function CanAccess(v)
	if v == nil then
		return false
	end
	if IsSecret(v) then
		return false
	end
	if Secrets and Secrets.CanAccessValue then
		return Secrets.CanAccessValue(v) and true or false
	end
	return true
end

local function SafeBool(v, default)
	if Secrets and Secrets.SafeBooleanTest then
		return Secrets.SafeBooleanTest(v, default)
	end
	if v == nil then
		return default
	end
	if v then
		return true
	end
	return false
end

local function IsForeverClient()
	return Client and (Client.isCamelot or Client.isForever) and true or false
end

--- pcall extra-returns drop/mash secrets. Assign inside the protected call instead.
local function CallThreat(fn, a, b)
	if type(fn) ~= "function" then
		return false
	end
	local r1, r2, r3, r4, r5
	local ok = pcall(function()
		if b ~= nil then
			r1, r2, r3, r4, r5 = fn(a, b)
		else
			r1, r2, r3, r4, r5 = fn(a)
		end
	end)
	return ok, r1, r2, r3, r4, r5
end

local function CVarExists(name)
	if CVar and CVar.Get then
		local ok, v = pcall(CVar.Get, CVar, name)
		if ok and v ~= nil and v ~= "" then
			return true
		end
	end
	if C_CVar and C_CVar.GetCVar then
		local ok, v = pcall(C_CVar.GetCVar, name)
		if ok and v ~= nil and v ~= "" then
			return true
		end
	end
	return false
end

function Threat.HasLeadSituation()
	return type(UnitThreatLeadSituation) == "function"
end

function Threat.HasPercentageOfLead()
	return type(UnitThreatPercentageOfLead) == "function"
end

--- Classic stores ~100 threat per 1 damage. Midnight / Forever do not need /100.
function Threat.ShouldDownscaleValues()
	if not Client then
		return true
	end
	if Client.isCamelot or Client.isForever or Client.isMidnight then
		return false
	end
	if Client.isRetail and Client.isPostDF then
		return false
	end
	return true
end

function Threat.ShouldStateBeSecret(unit, mobUnit)
	if type(ShouldUnitThreatStateBeSecret) == "function" then
		local ok, secret = CallThreat(ShouldUnitThreatStateBeSecret, unit, mobUnit)
		if ok then
			return SafeBool(secret, false)
		end
	end
	return false
end

function Threat.ShouldValuesBeSecret(unit, mobUnit)
	if type(ShouldUnitThreatValuesBeSecret) == "function" and mobUnit then
		local ok, secret = CallThreat(ShouldUnitThreatValuesBeSecret, unit, mobUnit)
		if ok then
			return SafeBool(secret, false)
		end
	end
	return false
end

function Threat.UnitExists(unit)
	if not unit or type(UnitExists) ~= "function" then
		return false
	end
	local ok, exists = pcall(UnitExists, unit)
	if not ok then
		return false
	end
	return SafeBool(exists, false)
end

function Threat.UnitCanAttack(unit)
	if not unit or type(UnitCanAttack) ~= "function" then
		return false
	end
	local ok, v = pcall(UnitCanAttack, "player", unit)
	if not ok then
		return false
	end
	return SafeBool(v, false)
end

function Threat.UnitIsPlayer(unit)
	if not unit or type(UnitIsPlayer) ~= "function" then
		return false
	end
	local ok, v = pcall(UnitIsPlayer, unit)
	if not ok then
		return false
	end
	return SafeBool(v, false)
end

function Threat.IsEnemyNpc(unit)
	if not Threat.UnitExists(unit) then
		return false
	end
	if Threat.UnitIsPlayer(unit) then
		return false
	end
	return Threat.UnitCanAttack(unit)
end

function Threat.PlayerInCombat()
	if InCombatLockdown and InCombatLockdown() then
		return true
	end
	if type(UnitAffectingCombat) ~= "function" then
		return false
	end
	local ok, v = pcall(UnitAffectingCombat, "player")
	if not ok then
		return false
	end
	return SafeBool(v, false)
end

--- Forever Combat settings have no threat-warning control. Never hide Flux threat for it.
function Threat.IsWarningEnabled()
	if IsForeverClient() then
		return true
	end
	if type(IsThreatWarningEnabled) == "function" then
		local ok, enabled = pcall(IsThreatWarningEnabled)
		if ok then
			return SafeBool(enabled, true)
		end
	end
	local v = CVar and CVar.Get and CVar.Get(THREAT_WARNING_CVAR)
	if v == "0" or v == 0 then
		return false
	end
	return true
end

function Threat.ShowNumeric()
	if numericOverride ~= nil then
		return numericOverride and true or false
	end
	if not CVarExists(NUMERIC_THREAT_CVAR) then
		return true
	end
	if CVarCallbackRegistry and CVarCallbackRegistry.GetCVarValueBool then
		local ok, v = pcall(CVarCallbackRegistry.GetCVarValueBool, CVarCallbackRegistry, NUMERIC_THREAT_CVAR)
		if ok and v ~= nil then
			return SafeBool(v, true)
		end
	end
	if CVar and CVar.GetBool then
		local ok, v = pcall(CVar.GetBool, CVar, NUMERIC_THREAT_CVAR)
		if ok and v ~= nil then
			return SafeBool(v, true)
		end
	end
	return true
end

function Threat.SetShowNumeric(enabled)
	numericOverride = enabled and true or false
	local value = enabled and "1" or "0"
	if CVarExists(NUMERIC_THREAT_CVAR) then
		if CVar and CVar.Set then
			CVar.Set(NUMERIC_THREAT_CVAR, value)
		elseif SetCVar then
			pcall(SetCVar, NUMERIC_THREAT_CVAR, value)
		end
	end
	return true
end

local NAMEPLATE_THREAT_FLAGS = { "Progressive", "Flash", "HealthBarColor" }

local function GetBlizzardThreatDB()
	local root = FluxUI_DB
	if type(root) ~= "table" then
		return nil
	end
	local db = root.nameplateThreat
	if type(db) ~= "table" then
		db = {}
		root.nameplateThreat = db
	end
	local flags = db.blizzardThreat
	if type(flags) ~= "table" then
		flags = {
			Progressive = true,
			Flash = true,
			HealthBarColor = true,
		}
		db.blizzardThreat = flags
	end
	return flags
end

function Threat.HasNumericCVar()
	return CVarExists(NUMERIC_THREAT_CVAR)
end

function Threat.HasNameplateDisplayCVar()
	return CVarExists(NAMEPLATE_THREAT_CVAR)
end

function Threat.HasWarningCVar()
	return CVarExists(THREAT_WARNING_CVAR)
end

local function ReadNameplateBit(index)
	if not index then
		return nil
	end
	if CVarCallbackRegistry and CVarCallbackRegistry.GetCVarBitfieldIndex then
		local ok, v = pcall(CVarCallbackRegistry.GetCVarBitfieldIndex, CVarCallbackRegistry, NAMEPLATE_THREAT_CVAR, index)
		if ok and v ~= nil then
			return SafeBool(v, false)
		end
	end
	if C_CVar and C_CVar.GetCVarBitfield then
		local ok, v = pcall(C_CVar.GetCVarBitfield, NAMEPLATE_THREAT_CVAR, index)
		if ok and v ~= nil then
			return SafeBool(v, false)
		end
	end
	return nil
end

--- Enum.NamePlateThreatDisplay key: "Progressive" | "Flash" | "HealthBarColor"
function Threat.NameplateDisplayEnabled(flagName)
	local enum = Enum and Enum.NamePlateThreatDisplay
	local index = enum and flagName and enum[flagName]
	if Threat.HasNameplateDisplayCVar() and index ~= nil then
		local bitOn = ReadNameplateBit(index)
		if bitOn ~= nil then
			return bitOn
		end
	end
	local flags = GetBlizzardThreatDB()
	if flags and flagName ~= nil then
		return flags[flagName] ~= false
	end
	return false
end

function Threat.SetNameplateDisplay(flagName, enabled)
	enabled = enabled and true or false
	local flags = GetBlizzardThreatDB()
	if flags and flagName then
		flags[flagName] = enabled
	end
	local enum = Enum and Enum.NamePlateThreatDisplay
	local index = enum and flagName and enum[flagName]
	if not Threat.HasNameplateDisplayCVar() or index == nil then
		return true
	end
	if CVar and CVar.SetBitfield then
		return CVar.SetBitfield(NAMEPLATE_THREAT_CVAR, index, enabled) and true or false
	end
	local setBit = (C_CVar and C_CVar.SetCVarBitfield) or SetCVarBitfield
	if not setBit then
		return false
	end
	local ok = pcall(setBit, NAMEPLATE_THREAT_CVAR, index, enabled)
	return ok and true or false
end

function Threat.GetNameplateDisplayMask()
	local mask = 0
	local enum = Enum and Enum.NamePlateThreatDisplay
	if not enum then
		return mask
	end
	for _, key in ipairs(NAMEPLATE_THREAT_FLAGS) do
		local index = enum[key]
		if type(index) == "number" and index > 0 and Threat.NameplateDisplayEnabled(key) then
			mask = bit.bor(mask, bit.lshift(1, index - 1))
		end
	end
	return mask
end

function Threat.SetNameplateDisplayMask(mask)
	mask = tonumber(mask) or 0
	local enum = Enum and Enum.NamePlateThreatDisplay
	if not enum then
		return
	end
	for _, key in ipairs(NAMEPLATE_THREAT_FLAGS) do
		local index = enum[key]
		if type(index) == "number" and index > 0 then
			local on = bit.band(mask, bit.lshift(1, index - 1)) ~= 0
			Threat.SetNameplateDisplay(key, on)
		end
	end
end

function Threat.GetWarningMode()
	local v = CVar and CVar.Get and CVar.Get(THREAT_WARNING_CVAR)
	local n = tonumber(v)
	if n == 0 or n == 1 or n == 2 or n == 3 then
		return n
	end
	return 3
end

function Threat.SetWarningMode(mode)
	local n = tonumber(mode)
	if n ~= 0 and n ~= 1 and n ~= 2 and n ~= 3 then
		n = 3
	end
	if CVar and CVar.Set then
		return CVar.Set(THREAT_WARNING_CVAR, tostring(n))
	end
	if SetCVar then
		return pcall(SetCVar, THREAT_WARNING_CVAR, n)
	end
	return false
end

function Threat.GetSituation(unit, mobUnit)
	if type(UnitThreatSituation) ~= "function" or not unit then
		return nil
	end
	local ok, status
	if mobUnit then
		ok, status = CallThreat(UnitThreatSituation, unit, mobUnit)
	else
		ok, status = CallThreat(UnitThreatSituation, unit)
	end
	if not ok then
		return nil
	end
	return status
end

function Threat.GetLeadSituation(unit, mobUnit)
	if not Threat.HasLeadSituation() or not unit or not mobUnit then
		return nil
	end
	local ok, status = CallThreat(UnitThreatLeadSituation, unit, mobUnit)
	if not ok then
		return nil
	end
	return status
end

function Threat.GetPercentageOfLead(unit, mobUnit)
	if not Threat.HasPercentageOfLead() or not unit or not mobUnit then
		return nil
	end
	local ok, pct = CallThreat(UnitThreatPercentageOfLead, unit, mobUnit)
	if not ok then
		return nil
	end
	return pct
end

--- Nil is absent. A secret must not be compared to nil.
local function ThreatValueAbsent(v)
	if IsSecret(v) then
		return false
	end
	return v == nil
end

--- isTanking, status, scaledPercentage, rawPercentage, rawThreat (may be secret).
function Threat.GetDetailed(unit, mobUnit)
	if not unit or not mobUnit then
		return nil
	end
	local isTanking, status, scaled, rawPct, rawThreat
	local ok = false
	if type(UnitDetailedThreatSituation) == "function" then
		ok, isTanking, status, scaled, rawPct, rawThreat = CallThreat(UnitDetailedThreatSituation, unit, mobUnit)
	end
	if ok and not (ThreatValueAbsent(isTanking) and ThreatValueAbsent(status) and ThreatValueAbsent(scaled) and ThreatValueAbsent(rawPct) and ThreatValueAbsent(rawThreat)) then
		return {
			isTanking = isTanking,
			status = status,
			scaledPercentage = scaled,
			rawPercentage = rawPct,
			rawThreat = rawThreat,
		}
	end
	if not IsForeverClient() then
		return nil
	end
	local situation = Threat.GetSituation(unit, mobUnit)
	local leadStatus = Threat.GetLeadSituation(unit, mobUnit)
	local lead = Threat.GetPercentageOfLead(unit, mobUnit)
	if ThreatValueAbsent(situation) and ThreatValueAbsent(leadStatus) and ThreatValueAbsent(lead) then
		return nil
	end
	local displayStatus = situation
	if not ThreatValueAbsent(leadStatus) then
		displayStatus = leadStatus
	end
	return {
		isTanking = false,
		status = displayStatus,
		scaledPercentage = lead,
		rawPercentage = lead,
		rawThreat = lead,
	}
end

local function PlayerIsEffectivelyTank()
	if not Spec or not Spec.IsPlayerEffectivelyTank then
		return false
	end
	local ok, v = pcall(Spec.IsPlayerEffectivelyTank)
	if not ok then
		return false
	end
	return SafeBool(v, false)
end

--- Flux numeric: tank-relative scaled % (100 = you have aggro). Not Blizzard lead %.
function Threat.GetNumericDisplay(feedbackUnit, unit)
	feedbackUnit = feedbackUnit or "player"
	if not unit then
		return nil
	end
	local detailed = Threat.GetDetailed(feedbackUnit, unit)
	if not detailed then
		return nil
	end
	local display = detailed.scaledPercentage
	if display == nil then
		display = detailed.rawPercentage
	end
	-- Secret isTanking cannot be treated as false; that forced tanks onto status 2 (yellow)
	-- while FontString still showed 100%.
	local tankingSecret = IsSecret(detailed.isTanking)
	local tanking = SafeBool(detailed.isTanking, false)
	if tanking and display == nil then
		display = 100
	end
	local status = detailed.status
	if (not tanking) and (not tankingSecret) and PlayerIsEffectivelyTank() then
		status = 2
	end
	return display, status, detailed.isTanking, detailed
end

function Threat.ShouldShowNumericOnUnit(unit)
	if not Threat.ShowNumeric() then
		return false
	end
	if Threat.IsExcludedThreatUnit(unit) then
		return false
	end
	return true
end

--- Dead units and critters ("minus") hide the Forever target numeric, same as UnitFrame_UpdateThreatIndicator.
function Threat.IsExcludedThreatUnit(unit)
	if unit and UnitClassification then
		local ok, classif = pcall(UnitClassification, unit)
		if ok and not IsSecret(classif) and classif == "minus" then
			return true
		end
	end
	if unit and UnitIsDead then
		local ok, dead = pcall(UnitIsDead, unit)
		if ok and not IsSecret(dead) and dead then
			return true
		end
	end
	return false
end

--- 255 from UnitThreatPercentageOfLead means "you are the threat lead", not 255%.
--- Tanks display 100. Other numbers stay as returned, including secrets.
function Threat.DisplayNumber(value, isTanking)
	local tankingKnown = (not IsSecret(isTanking)) and SafeBool(isTanking, false)
	if tankingKnown then
		return 100
	end
	if IsSecret(value) then
		return value
	end
	local n = Threat.AccessibleNumber(value)
	if n == nil then
		return nil
	end
	if n >= 255 then
		return 100
	end
	if n < 0 then
		return 0
	end
	return n
end

--- Hide the meter out of combat, and hide a real 0. Secrets still draw while fighting.
function Threat.ShouldShowThreat(display, isTanking)
	if not Threat.PlayerInCombat() then
		return false
	end
	if (not IsSecret(isTanking)) and SafeBool(isTanking, false) then
		return true
	end
	local shown = Threat.DisplayNumber(display, isTanking)
	if IsSecret(shown) then
		return true
	end
	return Threat.HasNonZeroDisplay(shown)
end

--- Forever target frame (UnitFrame_UpdateThreatIndicator): scaled % (100 = you have aggro).
--- Do not print UnitThreatPercentageOfLead. That API is 255 while you are the lead.
--- Status 2 when an effective tank is not tanking. No Classic 999 cap.
--- Nameplate tint uses GetForeverNameplateStatus, not this status.
function Threat.GetForeverFrameDisplay(feedbackUnit, unit)
	feedbackUnit = feedbackUnit or "player"
	if not unit then
		return nil
	end
	local detailed = Threat.GetDetailed(feedbackUnit, unit)
	if not detailed then
		return nil
	end
	local tankingSecret = IsSecret(detailed.isTanking)
	local tanking = SafeBool(detailed.isTanking, false)
	local display = detailed.scaledPercentage
	if ThreatValueAbsent(display) then
		display = detailed.rawPercentage
	end
	display = Threat.DisplayNumber(display, detailed.isTanking)
	local status = detailed.status
	if (not tanking) and (not tankingSecret) and PlayerIsEffectivelyTank() then
		status = 2
	end
	return display, status, detailed.isTanking, detailed
end

--- Nameplate chrome only for a mob the player is actually fighting.
--- UnitThreatSituation is nil when the player is not on that mob's list.
--- UnitThreatLeadSituation is the wrong gate: it returns red whenever you are
--- not first, including mobs you have never touched. A secret situation still
--- counts only if that mob is itself in combat, so idle nameplates stay clear.
function Threat.IsNameplateThreatTarget(unit)
	if not Threat.UnitExists(unit) then
		return false
	end
	if type(UnitAffectingCombat) == "function" then
		local ok, engaged = pcall(UnitAffectingCombat, unit)
		if not ok or not SafeBool(engaged, false) then
			return false
		end
	end
	local status = Threat.GetSituation("player", unit)
	if IsSecret(status) then
		return true
	end
	return status ~= nil
end

--- Forever nameplates: UnitThreatSituation for non-tanks, UnitThreatLeadSituation for tanks.
function Threat.GetForeverNameplateStatus(unit)
	if not unit then
		return nil
	end
	if PlayerIsEffectivelyTank() and Threat.HasLeadSituation() then
		return Threat.GetLeadSituation("player", unit)
	end
	return Threat.GetSituation("player", unit)
end

function Threat.HasNonZeroDisplay(display)
	if display == nil then
		return false
	end
	if IsSecret(display) then
		return true
	end
	if not CanAccess(display) then
		return false
	end
	local ok, n = pcall(tonumber, display)
	if not ok or n == nil then
		return false
	end
	return n ~= 0
end

function Threat.AccessibleNumber(value)
	if value == nil or IsSecret(value) or not CanAccess(value) then
		return nil
	end
	local ok, n = pcall(tonumber, value)
	if not ok or n == nil or IsSecret(n) then
		return nil
	end
	return n
end

function Threat.SetBarValue(bar, percent, isTanking)
	if not bar or not bar.SetValue then
		return 0
	end
	if SafeBool(isTanking, false) then
		pcall(bar.SetValue, bar, 100)
		return 100
	end
	local n = Threat.AccessibleNumber(percent)
	if n then
		if n > 100 then
			n = 100
		elseif n < 0 then
			n = 0
		end
		pcall(bar.SetValue, bar, n)
		return n
	end
	if percent ~= nil then
		pcall(bar.SetValue, bar, percent)
	else
		pcall(bar.SetValue, bar, 0)
	end
	return 0
end

--- 0 none / 1–2 gaining / 3 losing or tanking, matching CompactUnitFrame colors.
function Threat.GetStatusColor(status)
	if type(GetThreatStatusColor) == "function" then
		local ok, r, g, b = CallThreat(GetThreatStatusColor, status)
		if ok and r ~= nil then
			return r, g, b
		end
	end
	if status == nil or IsSecret(status) then
		return nil
	end
	local n = Threat.AccessibleNumber(status)
	if n == nil then
		return nil
	end
	if n >= 3 then
		local c = HIGH_THREAT_COLOR
		if c and c.GetRGB then
			local ok, r, g, b = pcall(c.GetRGB, c)
			if ok and r then
				return r, g, b
			end
		end
		return 1, 0, 0
	end
	if n > 0 then
		local c = GAINING_THREAT_COLOR
		if c and c.GetRGB then
			local ok, r, g, b = pcall(c.GetRGB, c)
			if ok and r then
				return r, g, b
			end
		end
		return 1, 1, 0.47
	end
	return 0.5, 0.5, 0.5
end

function Threat.GetPercentColor(percent)
	local n = Threat.AccessibleNumber(percent)
	if n == nil then
		return nil
	end
	if n < 0 then
		n = 0
	elseif n > 100 then
		n = 100
	end
	if n <= 50 then
		local factor = n / 50
		return factor, 1, 0
	end
	local factor = (n - 50) / 50
	return 1, 1 - factor, 0
end

--- Nameplate / bar chrome: 100% / tanking / rank 1 is red. Percent gradient otherwise.
--- Do not prefer Blizzard status yellow while the player has aggro.
function Threat.GetTintColor(percent, status, isTanking, rank)
	local rankN = Threat.AccessibleNumber(rank)
	if SafeBool(isTanking, false) or rankN == 1 then
		return 1, 0, 0
	end
	local n = Threat.AccessibleNumber(percent)
	if n ~= nil then
		if n >= 99.5 then
			return 1, 0, 0
		end
		return Threat.GetPercentColor(n)
	end
	local statusN = Threat.AccessibleNumber(status)
	if statusN ~= nil and statusN >= 3 then
		return 1, 0, 0
	end
	if not IsSecret(status) and status ~= nil then
		local r, g, b = Threat.GetStatusColor(status)
		if r then
			return r, g, b
		end
	end
	return nil
end

function Threat.SetPercentText(fs, percent)
	if not fs then
		return
	end
	percent = Threat.DisplayNumber(percent)
	if not Threat.HasNonZeroDisplay(percent) then
		if fs.SetText then
			pcall(fs.SetText, fs, "")
		end
		return
	end
	if fs.SetFormattedText then
		if pcall(fs.SetFormattedText, fs, "%.0f%%", percent) then
			return
		end
		if pcall(fs.SetFormattedText, fs, "%d%%", percent) then
			return
		end
		if pcall(fs.SetFormattedText, fs, "%s%%", percent) then
			return
		end
	end
	if fs.SetText then
		pcall(fs.SetText, fs, percent)
	end
end

function Threat.SetRankPercentText(fs, rank, percent)
	if not fs then
		return
	end
	local rankN = Threat.AccessibleNumber(rank)
	if rankN and percent ~= nil then
		if fs.SetFormattedText and pcall(fs.SetFormattedText, fs, "%d  %.0f%%", rankN, percent) then
			return
		end
		if fs.SetFormattedText and pcall(fs.SetFormattedText, fs, "%d  %s%%", rankN, percent) then
			return
		end
	end
	Threat.SetPercentText(fs, percent)
end

local function UnitsAreSame(a, b)
	if not a or not b then
		return false
	end
	if a == b then
		return true
	end
	if type(UnitIsUnit) ~= "function" then
		return false
	end
	local ok, same = pcall(UnitIsUnit, a, b)
	if not ok then
		return false
	end
	return SafeBool(same, false)
end

local function HasThreatPayload(detailed)
	if not detailed then
		return false
	end
	if SafeBool(detailed.isTanking, false) then
		return true
	end
	local function present(value)
		if value == nil then
			return false
		end
		local n = Threat.AccessibleNumber(value)
		if n ~= nil then
			return n > 0
		end
		-- Secret / inaccessible combat numbers are still a payload (do not drop the row).
		return true
	end
	return present(detailed.rawThreat) or present(detailed.scaledPercentage) or present(detailed.rawPercentage)
end

local function ThreatSortGreater(a, b)
	if a.sortNumber ~= nil and b.sortNumber ~= nil then
		return a.sortNumber > b.sortNumber
	end
	if a.threatValue == nil or b.threatValue == nil then
		return false
	end
	local ok, gt = pcall(function()
		return a.threatValue > b.threatValue
	end)
	return ok and gt or false
end

--- Rank among group+pets. Keeps secret threat rows; tanking is always placement 1.
function Threat.GetPlayerRank(targetUnit)
	if not targetUnit or not Threat.UnitExists(targetUnit) then
		return nil
	end

	local list = {}
	local function addUnit(unit)
		if not unit or not Threat.UnitExists(unit) then
			return
		end
		for i = 1, #list do
			if UnitsAreSame(list[i].unit, unit) then
				return
			end
		end
		local detailed = Threat.GetDetailed(unit, targetUnit)
		if not HasThreatPayload(detailed) then
			return
		end
		list[#list + 1] = {
			unit = unit,
			threatValue = detailed.rawThreat or detailed.scaledPercentage or detailed.rawPercentage,
			sortNumber = Threat.AccessibleNumber(detailed.rawThreat)
				or Threat.AccessibleNumber(detailed.scaledPercentage)
				or Threat.AccessibleNumber(detailed.rawPercentage),
			isTanking = SafeBool(detailed.isTanking, false),
		}
	end

	addUnit("player")
	addUnit("pet")
	if IsInRaid and IsInRaid() then
		local n = GetNumGroupMembers and GetNumGroupMembers() or 0
		for i = 1, n do
			addUnit("raid" .. i)
			addUnit("raidpet" .. i)
		end
	elseif IsInGroup and IsInGroup() then
		local n = GetNumGroupMembers and GetNumGroupMembers() or 0
		for i = 1, n do
			addUnit("party" .. i)
			addUnit("partypet" .. i)
		end
	end

	if #list == 0 then
		return nil
	end

	for i = 1, #list do
		if list[i].isTanking and UnitsAreSame(list[i].unit, "player") then
			return 1
		end
	end
	if #list == 1 and UnitsAreSame(list[1].unit, "player") then
		return 1
	end

	table.sort(list, function(a, b)
		if a.isTanking ~= b.isTanking then
			return a.isTanking
		end
		return ThreatSortGreater(a, b)
	end)
	for i = 1, #list do
		if UnitsAreSame(list[i].unit, "player") then
			return i
		end
	end
	return nil
end

local function ForeverMeterRow(unit, targetUnit)
	local detailed = Threat.GetDetailed(unit, targetUnit)
	if not detailed or not HasThreatPayload(detailed) then
		return nil
	end
	local display, status, isTankingRaw = Threat.GetForeverFrameDisplay(unit, targetUnit)
	local tanking = SafeBool(isTankingRaw, false)
	local secret = IsSecret(detailed.rawThreat)
		or IsSecret(detailed.rawPercentage)
		or IsSecret(detailed.scaledPercentage)
		or IsSecret(display)
		or IsSecret(isTankingRaw)
	return {
		unit = unit,
		isTanking = tanking,
		status = status,
		threatPct = display,
		rawPct = detailed.rawPercentage,
		threatVal = detailed.rawThreat,
		secret = secret and true or false,
	}
end

--- Details/meter row. Classic: nil when values are secret (do not invent ranks from secrets).
--- Forever: keep secret rows and use the same raw/lead number as the target frame.
function Threat.GetMeterRow(unit, targetUnit)
	if IsForeverClient() then
		return ForeverMeterRow(unit, targetUnit)
	end
	local detailed = Threat.GetDetailed(unit, targetUnit)
	if not detailed then
		return nil
	end
	if IsSecret(detailed.rawThreat) or IsSecret(detailed.scaledPercentage) or IsSecret(detailed.rawPercentage) then
		return nil
	end
	local threatVal = Threat.AccessibleNumber(detailed.rawThreat)
	if not threatVal or threatVal <= 0 then
		return nil
	end
	if Threat.ShouldDownscaleValues() then
		threatVal = math.floor(threatVal / 100)
	end
	local threatPct = Threat.AccessibleNumber(detailed.scaledPercentage)
		or Threat.AccessibleNumber(detailed.rawPercentage)
		or 0
	local tanking = SafeBool(detailed.isTanking, false)
	if tanking then
		threatPct = 100
	end
	return {
		unit = unit,
		isTanking = tanking,
		status = Threat.AccessibleNumber(detailed.status),
		threatPct = threatPct,
		rawPct = Threat.AccessibleNumber(detailed.rawPercentage) or 0,
		threatVal = threatVal,
	}
end
