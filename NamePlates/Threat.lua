-- NamePlates/Threat.lua — threat rank/% and border tint on every client.
-- The rank text stays centered on the bottom of the health bar, inside a
-- nameplate border that frames the text. The same color tints that border,
-- the level border, and the main nameplate border.
local addonName, ns = ...
local Flux = ns.Flux
local NP = Flux.NamePlates

local Threat = NP.RegisterModule("threat", { interval = 0.25 })

local RED_R, RED_G, RED_B = 1, 0, 0
local CLEAR_GRACE_SEC = 0.6
local TEXT_SIZE = 12

local states = {}

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------
local function IsGrouped()
	return (IsInGroup and IsInGroup()) or (IsInRaid and IsInRaid()) or false
end

local function IsVisibilityAllowed()
	local db = NP.GetDB()
	local mode = db.visibilityMode or "group"
	if mode == "never" then
		return false
	end
	if mode == "always" then
		return true
	end
	return IsGrouped()
end

local function IsNpcThreatEnabled()
	return NP.GetDB().npcThreatBorder ~= false
end

local function IsEnemyPlayerTargetEnabled()
	return NP.GetDB().enemyPlayerTarget ~= false
end

-- ---------------------------------------------------------------------------
-- Flux frames
-- ---------------------------------------------------------------------------
local function EnsureState(unit)
	local state = states[unit]
	if state then
		return state
	end
	state = { unit = unit }

	local host = NP.CreateClientPlate("threat")
	local text = host:CreateFontString(nil, "OVERLAY")
	text:SetFont(NP.FONT, TEXT_SIZE, "OUTLINE")
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	text:SetWordWrap(false)
	local textY = NP.IsLiveClient() and 1 or NP.PlateTextOffsetY()
	text:SetPoint("CENTER", host, "CENTER", 0, textY)
	state.host = host
	state.text = text

	states[unit] = state
	return state
end

local function Clear(state, healthBar)
	if not state then
		return
	end
	state.host:Hide()
	local bar = healthBar or state.healthBar
	local tinted = state.active or state.healthBar
	state.active = false
	state.clearAt = nil
	state.healthBar = nil
	NP.SetThreatTint(state.unit, nil)
	if tinted then
		NP.ResetPlateChrome(bar)
	end
end

local function RequestClear(state, healthBar, force)
	if not state or not state.active then
		Clear(state, healthBar)
		return
	end
	if force then
		Clear(state, healthBar)
		return
	end
	local now = GetTime()
	if not state.clearAt then
		state.clearAt = now + CLEAR_GRACE_SEC
	elseif now >= state.clearAt then
		Clear(state, healthBar)
	end
end

local function Show(state, plate, container, healthBar, r, g, b, rank, percent, showText)
	state.clearAt = nil
	state.healthBar = healthBar
	NP.TintPlateChrome(healthBar, r, g, b)
	NP.SetThreatTint(state.unit, r, g, b)
	state.active = true

	if not showText then
		state.host:Hide()
		return
	end
	local ThreatAPI = Flux.Threat
	if ThreatAPI and ThreatAPI.SetRankPercentText then
		ThreatAPI.SetRankPercentText(state.text, rank, percent)
	elseif percent ~= nil then
		pcall(state.text.SetFormattedText, state.text, "%.0f%%", percent)
	else
		state.text:SetText("")
	end
	state.text:SetTextColor(r, g, b, 1)
	NP.FitPlate(state.host, state.text)
	NP.ShowPlate(state.host, state.unit)

	NP.AttachHost(state.host, plate, 1)
	state.host:ClearAllPoints()
	if pcall(state.host.SetPoint, state.host, "CENTER", container, "BOTTOM", 0, -3) then
		state.host:Show()
	else
		state.host:Hide()
	end
end

-- ---------------------------------------------------------------------------
-- Threat evaluation
-- ---------------------------------------------------------------------------
local function CanAttack(unit)
	if not UnitCanAttack then
		return true
	end
	local ok, v = pcall(UnitCanAttack, "player", unit)
	if not ok then
		return true
	end
	return NP.BoolTest(v, false)
end

local function IsTargetingPlayer(unit)
	if not (UnitExists and UnitIsUnit) then
		return false
	end
	local target = unit .. "target"
	local okExists, exists = pcall(UnitExists, target)
	if not okExists or not NP.BoolTest(exists, false) then
		return false
	end
	local okUnit, isYou = pcall(UnitIsUnit, target, "player")
	return okUnit and NP.BoolTest(isYou, false) or false
end

local function InCombat()
	if not UnitAffectingCombat then
		return true
	end
	local ok, v = pcall(UnitAffectingCombat, "player")
	if not ok then
		return true
	end
	return NP.BoolTest(v, true)
end

local function UpdateUnit(unit)
	local state = states[unit]
	if not NP.IsThreatSupported() or not IsVisibilityAllowed()
		or (not IsNpcThreatEnabled() and not IsEnemyPlayerTargetEnabled()) then
		Clear(state)
		return
	end

	local _, plate, container, healthBar = NP.GetParts(unit)
	if not plate or not container or not healthBar or not UnitExists(unit) then
		Clear(state, healthBar)
		return
	end
	if not CanAttack(unit) then
		Clear(state, healthBar)
		return
	end
	state = EnsureState(unit)

	local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
	if okPlayer and NP.BoolTest(isPlayer, false) then
		if IsEnemyPlayerTargetEnabled() and IsTargetingPlayer(unit) then
			Show(state, plate, container, healthBar, RED_R, RED_G, RED_B, nil, nil, false)
		else
			RequestClear(state, healthBar, false)
		end
		return
	end

	if not IsNpcThreatEnabled() then
		Clear(state, healthBar)
		return
	end

	local ThreatAPI = Flux.Threat
	if ThreatAPI and ThreatAPI.IsNameplateThreatTarget and not ThreatAPI.IsNameplateThreatTarget(unit) then
		RequestClear(state, healthBar, true)
		return
	end
	if not (ThreatAPI and ThreatAPI.GetNumericDisplay) then
		Clear(state, healthBar)
		return
	end
	local client = Flux.Client
	local foreverFrame = client and (client.isCamelot or client.isForever) and ThreatAPI.GetForeverFrameDisplay
	local percent, status, isTanking
	if foreverFrame then
		percent, status, isTanking = ThreatAPI.GetForeverFrameDisplay("player", unit)
	else
		percent, status, isTanking = ThreatAPI.GetNumericDisplay("player", unit)
	end
	if foreverFrame and ThreatAPI.IsExcludedThreatUnit and ThreatAPI.IsExcludedThreatUnit(unit) then
		RequestClear(state, healthBar, true)
		return
	end
	if ThreatAPI.ShouldShowThreat and not ThreatAPI.ShouldShowThreat(percent, isTanking) then
		RequestClear(state, healthBar, not InCombat())
		return
	end
	if not ThreatAPI.ShouldShowThreat and ThreatAPI.HasNonZeroDisplay and not ThreatAPI.HasNonZeroDisplay(percent) then
		RequestClear(state, healthBar, not InCombat())
		return
	end

	local rank = ThreatAPI.GetPlayerRank and ThreatAPI.GetPlayerRank(unit) or nil
	local r, g, b
	if foreverFrame and ThreatAPI.GetStatusColor then
		if ThreatAPI.GetForeverNameplateStatus then
			r, g, b = ThreatAPI.GetStatusColor(ThreatAPI.GetForeverNameplateStatus(unit))
		end
		if not r then
			r, g, b = ThreatAPI.GetStatusColor(status)
		end
	end
	if not r and ThreatAPI.GetTintColor then
		r, g, b = ThreatAPI.GetTintColor(percent, status, isTanking, rank)
	end
	if not r then
		if NP.BoolTest(isTanking, false) or (NP.IsUsable(rank) and rank == 1) then
			r, g, b = RED_R, RED_G, RED_B
		elseif ThreatAPI.GetStatusColor then
			r, g, b = ThreatAPI.GetStatusColor(status)
		end
		if not r and ThreatAPI.GetPercentColor then
			r, g, b = ThreatAPI.GetPercentColor(45)
		end
		if not r then
			r, g, b = RED_R, RED_G, RED_B
		end
	end
	local showText = not ThreatAPI.ShouldShowNumericOnUnit or ThreatAPI.ShouldShowNumericOnUnit(unit)
	Show(state, plate, container, healthBar, r, g, b, rank, percent, showText)
end

-- ---------------------------------------------------------------------------
-- Module hooks
-- ---------------------------------------------------------------------------
function Threat.Added(unit)
	UpdateUnit(unit)
end

function Threat.Removed(unit)
	local state = states[unit]
	if not state then
		return
	end
	Clear(state)
	NP.ReleaseHost(state.host)
	states[unit] = nil
end

function Threat.Refresh(unit)
	UpdateUnit(unit)
end

function Threat.Poll()
	for unit in pairs(NP.activeUnits) do
		UpdateUnit(unit)
	end
end
