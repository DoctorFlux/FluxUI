-- Blizzard renders harmful nameplate aura art on clients with secure AuraButtons.
local _, ns = ...
local Flux = ns.Flux
local NP, Aura = Flux.NamePlates, Flux.Aura
local SecureAuras = {}
NP.SecureAuras = SecureAuras

local DEBUFF_FILTER = "HARMFUL|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL"
local CC_FILTER = "HARMFUL|CROWD_CONTROL"
local PLAYER_DEBUFF_FILTER = DEBUFF_FILTER .. "|PLAYER"
local PLAYER_CC_FILTER = CC_FILTER .. "|PLAYER"
local GROUP = "harmful"
local plates = setmetatable({}, { __mode = "k" })
local active = {}
local leases = setmetatable({}, { __mode = "k" })
local colorMap, formatter

local function Call(object, method, ...)
	local fn = object and object[method]
	if fn then return pcall(fn, object, ...) end
	return false
end

local function ReadNumber(value)
	if type(value) == "number" and NP.IsUsable(value) and value == value then return value end
end

local function LaneUsable(lane)
	if not lane then return false end
	local ok, forbidden = Call(lane, "IsForbidden")
	if ok and NP.BoolTest(forbidden, true) then return false end
	local visible, shown = Call(lane, "IsVisible")
	return visible and NP.BoolTest(shown, false)
end

local function HasNativeAura(lane)
	local loc = lane.AuraItemFrame
	if loc then
		local ok, shown = Call(loc, "IsShown")
		return ok and NP.BoolTest(shown, false)
	end
	local children = { Call(lane, "GetChildren") }
	if not children[1] then return false end
	for i = 2, #children do
		local item = children[i]
		if NP.IsUsable(item) and (item.Icon or item.Cooldown) then
			local ok, shown = Call(item, "IsShown")
			if ok and NP.BoolTest(shown, false) then return true end
		end
	end
	return false
end

local function RestoreLane(lane)
	local lease = leases[lane]
	if not lease then return true end
	local ok, alpha = Call(lane, "GetAlpha")
	if not ok or not ReadNumber(alpha) then return false end
	if alpha == 0 and not Call(lane, "SetAlpha", lease.alpha) then return false end
	leases[lane] = nil
	return true
end

local function ConcealLane(lane, row)
	local lease = leases[lane]
	if lease and lease.row ~= row and not RestoreLane(lane) then return false end
	local ok, alpha = Call(lane, "GetAlpha")
	if not ok or not ReadNumber(alpha) then return false end
	if alpha == 0 then return lease ~= nil and lease.row == row end
	if not Call(lane, "SetAlpha", 0) then return false end
	leases[lane] = { row = row, alpha = alpha }
	return true
end

local function Stop(row)
	if not row then return end
	if row.unit then
		row.host:Hide()
		Call(row.box, "SetEnabled", false)
		Call(row.box, "SetUnit", "none")
		row.unit = nil
	end
	if row.lane and RestoreLane(row.lane) then row.lane = nil end
end

function SecureAuras.Release(unit)
	local state = active[unit]
	if not state then return end
	Stop(state.debuffs)
	Stop(state.cc)
	state.unit = nil
	active[unit] = nil
end

local function GetColorMap()
	if colorMap then return colorMap end
	colorMap = {}
	for _, kind in ipairs({ "None", "Magic", "Curse", "Disease", "Poison", "Bleed", "Enrage" }) do
		local r, g, b = Aura.GetNameplateAuraColor(kind)
		colorMap[kind] = CreateColor(r, g, b, 1)
	end
	return colorMap
end

local function GetFormatter()
	if formatter ~= nil then return formatter end
	formatter = false
	local rounding = Enum and Enum.NumericRuleFormatRounding
	if not (rounding and C_StringUtil and C_StringUtil.CreateNumericRuleFormatter) then return end
	local ok, rules = pcall(C_StringUtil.CreateNumericRuleFormatter)
	if not ok or not rules then return end
	if Call(rules, "SetBreakpoints", {
		{ threshold = 0, format = "%d", step = 1, rounding = rounding.Up },
		{ threshold = 60, format = "", step = 1, rounding = rounding.Down },
	}) then formatter = rules end
	return formatter
end

local function SetTimer(view, placement, fontSize)
	local timer, button = view.timer, view.button
	timer:ClearAllPoints()
	timer:SetFont(NP.FONT, fontSize, "OUTLINE")
	local offset = placement == "bottom" and math.floor(fontSize / 2) + 1 or placement == "below" and -1 or 0
	local point = placement == "below" and "TOP" or "CENTER"
	local anchor = placement == "middle" and "CENTER" or "BOTTOM"
	timer:SetPoint(point, button, anchor, 0, offset)
	if placement == "none" then
		button:ClearDurationText()
		timer:Hide()
	else
		local format = GetFormatter()
		timer:Show()
		if not format or not Call(button, "SetDurationText", timer, { textFormatter = format }) then
			button:SetDurationText(timer, {})
		end
	end
end

local function InitializeButton(row, button)
	button:SetSize(row.size, row.size)
	-- Blizzard's AuraButton handles the exact aura tooltip on motion. Clicks
	-- still pass through to the world/nameplate below.
	local enableMotion = button.SetMouseMotionEnabled or button.EnableMouseMotion or button.EnableMouse
	if button.SetMouseClickEnabled then
		enableMotion(button, true)
		button:SetMouseClickEnabled(false)
	end
	local icon = Aura.CreateNameplateAuraArt(button)
	Aura.LayoutNameplateAuraArt(icon, button, row.size)
	local baseLevel = button:GetFrameLevel()
	local borderHost = CreateFrame("Frame", nil, button)
	borderHost:SetAllPoints(button)
	borderHost:EnableMouse(false)
	borderHost:SetFrameLevel(baseLevel + 1)
	local bevel = Aura.CreateNameplateAuraBorder(borderHost)
	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(button)
	cooldown:SetFrameLevel(baseLevel + 2)
	Aura.StyleNameplateAuraCooldown(cooldown)
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetAllPoints(button)
	overlay:EnableMouse(false)
	overlay:SetFrameLevel(baseLevel + 4)
	local count = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
	local timer = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	local view = { button = button, timer = timer }
	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetApplicationCount(count, {})
	SetTimer(view, row.placement, row.fontSize)
	local glyph = Aura.CreateDispelTypeIcon(overlay, nil, row.size)
	assert(Aura.BindDispelTypeIcon(button, glyph), "Nameplate aura type icon registration failed")
	local borderOptions = {
		style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
		showWhenHarmful = true, showWhenHelpful = false, showWithoutDispelType = true,
		customDispelColorMap = GetColorMap(),
	}
	assert(button:AddDispelTypeTexture(bevel, borderOptions) ~= false, "Nameplate aura border registration failed")
	row.timers[#row.timers + 1] = view
end

local function SetupRow(row)
	local flow = AnchorUtil and AnchorUtil.FlowDirection
	local axis = AnchorUtil and AnchorUtil.FlowLayoutAxis
	local box = CreateFrame("AuraContainer", nil, row.host, "CustomAuraContainerTemplate")
	row.box = box
	local point = row.isCC and "LEFT" or "BOTTOMLEFT"
	box:SetPoint(point, row.host, point, 0, 0)
	box:SetFrameLevel(row.host:GetFrameLevel() + 1)
	box:EnableMouse(false)
	box:SetFlowLayoutAxis(axis.Horizontal)
	box:SetFlowLayoutAnchorPoint("BOTTOMLEFT")
	box:SetFlowLayoutGrowthDirection(flow.Right, flow.Up)
	box:SetUnit("none")
	box:SetEnabled(false)
	assert(box:AddAuraGroup(GROUP, row.filter, {
		maxFrameCount = 1,
		sortMethod = AuraContainerSortMethod.Default,
		layout = { elementWidth = row.size, elementHeight = row.size },
		initializeFrame = function(button)
			if not pcall(InitializeButton, row, button) then row.failed = true end
		end,
	}) ~= false, "Nameplate aura group registration failed")
	assert(not row.failed and #row.timers > 0, "Nameplate aura frames were not initialized")
end

local function ConfigureTimers(row, placement, fontSize)
	if row.placement == placement and row.fontSize == fontSize then return true end
	for _, view in ipairs(row.timers) do
		if not pcall(SetTimer, view, placement, fontSize) then return false end
	end
	row.placement, row.fontSize = placement, fontSize
	return true
end

local function LaneScale(lane, auras, size)
	local scale = ReadNumber(auras.auraItemScale) or 1
	if lane.AuraItemFrame then
		local ok, width = Call(lane.AuraItemFrame, "GetWidth")
		local shownSize = ok and ReadNumber(width)
		if shownSize and shownSize > 0 then scale = scale * shownSize / size end
	end
	return scale
end

local function ConfigureRow(row, lane, scale, placement, fontSize, filter)
	local size = row.size
	local maximum = ReadNumber(lane.maxAuraItemsDisplayed) or 1
	local stride = ReadNumber(lane.stride) or maximum
	if maximum < 1 or scale <= 0 then return false end
	if row.filter ~= filter then
		local ok, result = Call(row.box, "SetAuraGroupFilterString", GROUP, filter)
		if not ok or result == false then
			row.filter = nil
			return false
		end
		row.filter = filter
	end
	local point = row.isCC and "LEFT" or "BOTTOMLEFT"
	if row.anchor ~= lane then
		row.host:ClearAllPoints()
		if not Call(row.host, "SetPoint", point, lane, point, 0, 0) then return false end
		row.anchor = lane
	end
	if row.scale ~= scale then
		if not Call(row.host, "SetScale", scale) then return false end
		row.scale = scale
	end
	if row.maximum ~= maximum or row.stride ~= stride then
		if not Call(row.box, "SetAuraGroupMaxFrameCount", GROUP, maximum)
			or not Call(row.box, "SetFlowLayoutMaximumLineSize", math.max(1, stride) * size) then return false end
		row.maximum, row.stride = maximum, stride
	end
	if not row.isCC then
		local localOnly = NP.BoolTest(lane.requireSourceIsLocalPlayer, false)
		local cvar = NamePlateConstants and NamePlateConstants.SHOW_ALL_PERSONAL_AURAS_CVAR
		local getBool = (C_CVar and C_CVar.GetCVarBool) or GetCVarBool
		local checked, showAll
		if cvar and getBool then checked, showAll = pcall(getBool, cvar) end
		local personalOnly = checked and NP.IsUsable(showAll) and showAll == false or false
		if row.localOnly ~= localOnly or row.personalOnly ~= personalOnly then
			local candidates = { nameplateShowAll = false }
			if localOnly then candidates.isFromPlayerOrPlayerPet = true end
			if personalOnly then candidates.nameplateShowPersonal = true end
			if not Call(row.box, "SetAuraGroupCandidateFilters", GROUP, candidates) then return false end
			row.localOnly, row.personalOnly = localOnly, personalOnly
		end
	end
	return ConfigureTimers(row, placement, fontSize / scale)
end

local function SyncRow(state, key, lane, plate, unit, auras, placement, fontSize, filter)
	local row = state[key]
	if not LaneUsable(lane) or (not (row and row.unit) and not HasNativeAura(lane)) then
		Stop(row)
		return false
	end
	if row and row.lane ~= lane then Stop(row) end
	local size = row and row.size or (NamePlateConstants and ReadNumber(NamePlateConstants.AURA_ITEM_HEIGHT)) or 25
	local scale = LaneScale(lane, auras, size)
	if scale <= 0 then Stop(row); return false end
	if not row then
		local host = NP.CreateHost(1, 1)
		if not NP.AttachHost(host, plate, 10) then return false end
		row = { host = host, placement = placement, fontSize = fontSize / scale, timers = {}, size = size,
			isCC = key == "cc", filter = filter }
		state[key] = row
		if not pcall(SetupRow, row) then row.failed = true end
	end
	if row.failed or (row.lane and row.lane ~= lane)
		or not ConfigureRow(row, lane, scale, placement, fontSize, filter) then
		Stop(row)
		return false
	end
	if not row.unit then
		row.unit = unit
		if not Call(row.box, "SetUnit", unit) or not Call(row.box, "SetEnabled", true) then
			Stop(row)
			return false
		end
	end
	if row.failed or not ConcealLane(lane, row) then
		Stop(row)
		return false
	end
	row.lane = lane
	row.host:Show()
	return true
end

function SecureAuras.Update(plate, unit, auras, placement, fontSize, onlyMine)
	local engine = ns.UnitFrames and ns.UnitFrames.UseEngineAuras
	if not (engine and Aura and CreateColor and AuraContainerSortMethod and AnchorUtil
		and Enum and Enum.CustomAuraButtonDispelTypeTextureStyle and engine()) then
		SecureAuras.Release(unit)
		return false
	end
	local state = plates[plate]
	if active[unit] and active[unit] ~= state then SecureAuras.Release(unit) end
	local owner = auras and auras.unitToken
	if not auras or (type(owner) ~= "nil" and (not NP.IsUsable(owner) or owner ~= unit)) then
		SecureAuras.Release(unit)
		return false
	end
	if not state then state = {}; plates[plate] = state end
	if state.unit and state.unit ~= unit then SecureAuras.Release(state.unit) end
	state.unit, active[unit] = unit, state
	local debuffFilter = onlyMine and PLAYER_DEBUFF_FILTER or DEBUFF_FILTER
	local ownsDebuffs = SyncRow(state, "debuffs", auras.DebuffListFrame, plate, unit, auras, placement, fontSize, debuffFilter)
	local ccLane = LaneUsable(auras.CrowdControlListFrame) and auras.CrowdControlListFrame or auras.LossOfControlFrame
	local ccFilter = onlyMine and PLAYER_CC_FILTER or CC_FILTER
	if SyncRow(state, "cc", ccLane, plate, unit, auras, placement, fontSize, ccFilter) then return ownsDebuffs, ccLane end
	return ownsDebuffs
end
