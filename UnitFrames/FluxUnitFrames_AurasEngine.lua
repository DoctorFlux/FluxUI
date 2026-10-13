-- Midnight 12.1: Blizzard AuraContainer paints auras engine-side.
-- Tainted GetAuraSlots cannot list target auras in combat (RequiresUnitAuraAccess).
-- Ellesmere uses CustomAuraContainerTemplate the same way: addon styles buttons
-- once in initializeFrame; the widget enumerates UNIT_AURA without Lua reading
-- secret values.
local addonName, ns = ...
ns.UnitFrames = ns.UnitFrames or {}
local UF = ns.UnitFrames

local AURA_BORDER_INSET_X = 8
local AURA_BORDER_INSET_Y_TOP = 10
local AURA_BORDER_INSET_Y_BOTTOM = 10

local loaded
local loadFailed
local durationFormatter

local function EnsureLoaded()
	if loaded then
		return true
	end
	if loadFailed then
		return false
	end
	local addOn = C_AddOns
	if addOn and addOn.LoadAddOn and not addOn.IsAddOnLoaded("Blizzard_AuraContainer") then
		pcall(addOn.LoadAddOn, "Blizzard_AuraContainer")
	end
	if not addOn or not addOn.IsAddOnLoaded("Blizzard_AuraContainer") then
		loadFailed = true
		return false
	end
	loaded = true
	return true
end

function UF.UseEngineAuras()
	local Client = ns.Flux and ns.Flux.Client
	local isCamelot = Client and (Client.isCamelot or Client.isForever)
	if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE and not isCamelot then
		return false
	end
	if Client and not isCamelot and (Client.majorVersion or 0) < 12 then
		return false
	end
	return EnsureLoaded()
end

function UF.ContainerUsesEngine(container)
	return container and container._fluxEngine ~= nil
end

function UF.FrameUsesEngineAuras(frame)
	if not frame then
		return false
	end
	return UF.ContainerUsesEngine(frame.BuffContainer) or UF.ContainerUsesEngine(frame.DebuffContainer)
end

local function FlowDir(name)
	local dirs = AnchorUtil and AnchorUtil.FlowDirection
	if not dirs then
		return nil
	end
	return dirs[name]
end

local function SortMethod(name)
	local methods = AuraContainerSortMethod
	if not methods then
		return nil
	end
	local value = methods[name]
	if value ~= nil then
		return value
	end
	return methods.Default
end

local function SortDir()
	local dirs = AuraContainerSortDirection
	if dirs and dirs.Normal ~= nil then
		return dirs.Normal
	end
	return 0
end

local function DispelStylePreserve()
	local e = Enum and Enum.CustomAuraButtonDispelTypeTextureStyle
	return e and e.PreserveAsset
end

local function StealableFilter()
	local e = Enum and Enum.CustomAuraButtonDispelTypeStealableFilter
	return e and e.Stealable
end

local function GetDurationFormatter()
	if durationFormatter ~= nil then
		return durationFormatter
	end
	durationFormatter = false
	if not (C_StringUtil and C_StringUtil.CreateNumericRuleFormatter and Enum and Enum.NumericRuleFormatRounding) then
		return nil
	end
	local Up = Enum.NumericRuleFormatRounding.Up
	local Down = Enum.NumericRuleFormatRounding.Down
	local formatter = C_StringUtil.CreateNumericRuleFormatter()
	local ok = pcall(formatter.SetBreakpoints, formatter, {
		{ threshold = 0, format = "%d", step = 1, rounding = Up },
		{ threshold = 60, format = "%dm", step = 1, rounding = Up, components = { { div = 60 } } },
		{ threshold = 61, format = "%dm", step = 1, rounding = Down, components = { { div = 60 } } },
		{ threshold = 3600, format = "%dh", step = 1, rounding = Down, components = { { div = 3600 } } },
		{ threshold = 86400, format = "%dd", step = 1, rounding = Down, components = { { div = 86400 } } },
	})
	if ok then
		durationFormatter = formatter
		return formatter
	end
	return nil
end

local function XSqueeze()
	local g = FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames
	local m = g and g()
	if type(m) ~= "number" or m ~= m or m <= 0 then
		return 1
	end
	return m
end

local function InitializeEngineButton(button, container, width, height)
	width = width or 35
	height = height or width
	-- Flow layout only anchors; an unsized AuraButton paints nothing.
	button:SetSize(width, height)

	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints(button)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(button)
	cooldown:SetDrawEdge(false)
	cooldown:SetReverse(true)
	if cooldown.SetHideCountdownNumbers then
		cooldown:SetHideCountdownNumbers(true)
	end

	local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
	border:SetAllPoints(button)
	border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	border:SetBackdropBorderColor(0, 0, 0, 1)
	border:EnableMouse(false)
	if cooldown.GetFrameLevel then
		border:SetFrameLevel(cooldown:GetFrameLevel() + 1)
	end

	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
	overlay:SetAllPoints(button)
	overlay:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)

	local stealable = button:CreateTexture(nil, "OVERLAY")
	stealable:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
	stealable:SetPoint("TOPLEFT", -3, 3)
	stealable:SetPoint("BOTTOMRIGHT", 3, -3)
	stealable:SetBlendMode("ADD")
	stealable:SetAlpha(0)

	local textHost = CreateFrame("Frame", nil, button)
	textHost:SetAllPoints(button)
	textHost:EnableMouse(false)
	textHost:SetFrameLevel((cooldown.GetFrameLevel and cooldown:GetFrameLevel() or 1) + 5)

	local isFocus = container.unit == "focus"
	local countSize = isFocus and 8 or 12
	local count = textHost:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	count:SetPoint("BOTTOMRIGHT", textHost, "BOTTOMRIGHT", -1, 0)
	count:SetFont("Fonts\\FRIZQT__.TTF", countSize, "OUTLINE")
	count:SetTextColor(1, 1, 1, 1)
	count:SetShadowColor(0, 0, 0, 1)
	count:SetShadowOffset(1, -1)

	local duration = textHost:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	duration:SetPoint("CENTER", textHost, "CENTER", 0, 0)
	local durSize = isFocus and 8 or 10
	duration:SetFont("Fonts\\FRIZQT__.TTF", durSize, "OUTLINE")
	duration:SetTextColor(1, 1, 1, 1)
	duration:SetShadowColor(0, 0, 0, 1)
	duration:SetShadowOffset(1, -1)

	pcall(button.SetIcon, button, icon)
	pcall(button.SetDurationCooldown, button, cooldown)
	pcall(button.SetApplicationCount, button, count, {})

	local formatter = GetDurationFormatter()
	local durationOpts = formatter and { textFormatter = formatter } or {}
	if not pcall(button.SetDurationText, button, duration, durationOpts) then
		pcall(button.SetDurationText, button, duration, {})
	end

	local preserve = DispelStylePreserve()
	if preserve and overlay then
		pcall(button.AddDispelTypeTexture, button, overlay, {
			style = preserve,
			showWhenHarmful = true,
			showWhenHelpful = false,
		})
	end
	local stealFilter = StealableFilter()
	if preserve and stealFilter ~= nil and stealable then
		pcall(button.AddDispelTypeTexture, button, stealable, {
			style = preserve,
			stealableFilter = stealFilter,
			showWhenHelpful = true,
			showWhenHarmful = false,
		})
	end

	if container._fluxCancelAuras then
		pcall(button.SetCancelAuraButtons, button, "RightButtonUp")
		pcall(button.SetMouseClickEnabled, button, true)
	else
		pcall(button.SetMouseClickEnabled, button, false)
	end
	if button.SetHideTooltipInCombat then
		pcall(button.SetHideTooltipInCombat, button, false)
	end
	if button.EnableMouse then
		button:EnableMouse(true)
	end
end

local function MakeInitializer(container, width, height)
	return function(button)
		pcall(InitializeEngineButton, button, container, width, height)
	end
end

local function GroupLayout(width, height, spacing, layoutIndex)
	local layout = {
		elementWidth = width,
		elementHeight = height,
		elementSpacing = spacing,
		lineSpacing = spacing,
	}
	if layoutIndex then
		layout.layoutIndex = layoutIndex
	end
	return layout
end

local function GroupOptions(maxAuras, sort, dir, init, layout, candidateFilters)
	local options = {
		maxFrameCount = maxAuras,
		initializeFrame = init,
		layout = layout,
	}
	if sort ~= nil then
		options.sortMethod = sort
	end
	if dir ~= nil then
		options.sortDirection = dir
	end
	if candidateFilters then
		options.candidateFilters = candidateFilters
	end
	return options
end

local function ApplyFlow(engine, container)
	if not engine then
		return
	end
	local growUp = container._fluxAuraGrowUpward
	local growHName = container._fluxAuraGrowH
	local growVName = container._fluxAuraGrowV
	if growUp then
		growVName = growVName or "Up"
	end
	local right = FlowDir("Right")
	local left = FlowDir("Left")
	local up = FlowDir("Up")
	local down = FlowDir("Down")
	local anchor = container._fluxAuraAnchorPoint
	if not anchor then
		anchor = growUp and "BOTTOMLEFT" or "TOPLEFT"
	end
	if engine.SetFlowLayoutAnchorPoint then
		pcall(engine.SetFlowLayoutAnchorPoint, engine, anchor)
	end
	local horizontal = (growHName == "Left") and left or right
	local vertical = (growVName == "Up") and up or down
	if engine.SetFlowLayoutGrowthDirection and horizontal and vertical then
		pcall(engine.SetFlowLayoutGrowthDirection, engine, horizontal, vertical)
	end
	local padX, padTop, padBottom = AURA_BORDER_INSET_X, AURA_BORDER_INSET_Y_TOP, AURA_BORDER_INSET_Y_BOTTOM
	if engine.SetFlowLayoutPadding then
		pcall(engine.SetFlowLayoutPadding, engine, padX, padX, padTop, padBottom)
	end
	local innerW = (container.GetWidth and container:GetWidth() or 0) - (padX * 2)
	if innerW < 1 then
		innerW = 1
	end
	if engine.SetFlowLayoutMaximumLineSize then
		pcall(engine.SetFlowLayoutMaximumLineSize, engine, innerW)
	end
end

local function ResizeGroupButtons(engine, key, width, height)
	if not engine or not engine.GetAuraGroupFrameCount or not engine.GetAuraGroupFrame then
		return
	end
	local ok, count = pcall(engine.GetAuraGroupFrameCount, engine, key)
	if not ok or type(count) ~= "number" then
		return
	end
	for i = 1, count do
		local got, frame = pcall(engine.GetAuraGroupFrame, engine, key, i)
		if got and frame and frame.SetSize then
			pcall(frame.SetSize, frame, width, height)
		end
	end
end

local function HasGroup(engine, key)
	if not engine or not engine.HasAuraGroup then
		return false
	end
	local ok, has = pcall(engine.HasAuraGroup, engine, key)
	return ok and has
end

local function IconSizes(container)
	local base = container._fluxAuraBaseSize or 35
	local spacing = container._fluxAuraBaseSpacing or 2
	local lockOwn = container._fluxLockOwnDebuffSize
	if lockOwn == nil then
		lockOwn = true
	end
	local own = UF.AuraOwn
	if own and own.GetIconSizes then
		return own.GetIconSizes(base, spacing, lockOwn, container._fluxOwnDebuffMinScale, XSqueeze(), container._fluxAuraSlotHeight)
	end
	local xF = XSqueeze()
	local width = base * xF
	local height = container._fluxAuraSlotHeight or base
	return width, height, width, height, spacing
end

local function ApplyGroupSizes(container)
	local engine = container._fluxEngine
	if not engine or not engine.SetAuraGroupLayout then
		return
	end
	local maxAuras = container.maxAuras or 32
	local width, height, ownW, ownH, spacing = IconSizes(container)
	if container.containerType == "Buff" then
		if HasGroup(engine, "buffs") then
			pcall(engine.SetAuraGroupLayout, engine, "buffs", GroupLayout(width, height, spacing))
			if engine.SetAuraGroupMaxFrameCount then
				pcall(engine.SetAuraGroupMaxFrameCount, engine, "buffs", maxAuras)
			end
			ResizeGroupButtons(engine, "buffs", width, height)
		end
		return
	end
	if HasGroup(engine, "own") then
		pcall(engine.SetAuraGroupLayout, engine, "own", GroupLayout(ownW, ownH, spacing, 1))
		if engine.SetAuraGroupMaxFrameCount then
			pcall(engine.SetAuraGroupMaxFrameCount, engine, "own", maxAuras)
		end
		ResizeGroupButtons(engine, "own", ownW, ownH)
	end
	if HasGroup(engine, "other") then
		pcall(engine.SetAuraGroupLayout, engine, "other", GroupLayout(width, height, spacing, 2))
		if engine.SetAuraGroupMaxFrameCount then
			pcall(engine.SetAuraGroupMaxFrameCount, engine, "other", maxAuras)
		end
		ResizeGroupButtons(engine, "other", width, height)
	end
	if HasGroup(engine, "all") then
		pcall(engine.SetAuraGroupLayout, engine, "all", GroupLayout(width, height, spacing))
		if engine.SetAuraGroupMaxFrameCount then
			pcall(engine.SetAuraGroupMaxFrameCount, engine, "all", maxAuras)
		end
		ResizeGroupButtons(engine, "all", width, height)
	end
end

function UF.PokeEngineAuras(container, frame)
	if not container or not container._fluxEngine then
		return
	end
	local engine = container._fluxEngine
	local unit = (frame and frame.unit) or container.unit
	if unit and engine.SetUnit then
		pcall(engine.SetUnit, engine, unit)
	end
	if engine.UpdateAllAuras then
		pcall(engine.UpdateAllAuras, engine)
	end
end

function UF.SyncEngineAuras(container, frame)
	if not container or not container._fluxEngine then
		return
	end
	local engine = container._fluxEngine
	local unit = (frame and frame.unit) or container.unit
	if unit and engine.SetUnit then
		pcall(engine.SetUnit, engine, unit)
	end
	if engine.SetEnabled then
		pcall(engine.SetEnabled, engine, true)
	end
	ApplyFlow(engine, container)
	ApplyGroupSizes(container)
	if engine.UpdateAllAuras then
		pcall(engine.UpdateAllAuras, engine)
	end
end

local function AddGroup(engine, key, filter, options)
	if not engine.AddAuraGroup then
		return false
	end
	local ok = pcall(engine.AddAuraGroup, engine, key, filter, options)
	return ok
end

local function DiscardEngine(engine)
	if not engine then
		return
	end
	pcall(engine.Hide, engine)
	pcall(engine.SetParent, engine, nil)
end

local function PlaceEngine(engine, container)
	engine:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	engine:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
	if not container._fluxNoClipChildren then
		if container.SetClipsChildren then
			container:SetClipsChildren(true)
		end
		if engine.SetClipsChildren then
			engine:SetClipsChildren(true)
		end
	end
	engine:SetFrameLevel((container.GetFrameLevel and container:GetFrameLevel() or 1) + 2)
end

function UF.AttachEngineAuras(container, frame)
	if not container or container._fluxEngine then
		if container and container._fluxEngine then
			UF.SyncEngineAuras(container, frame)
			return true
		end
		return false
	end
	if not UF.UseEngineAuras() then
		return false
	end

	local name = (container.GetName and container:GetName() or "FluxAura") .. "Engine"
	local okCreate, created = pcall(CreateFrame, "AuraContainer", name, container, "CustomAuraContainerTemplate")
	local engine = okCreate and created or nil
	if not engine then
		return false
	end

	PlaceEngine(engine, container)

	local unit = (frame and frame.unit) or container.unit
	container.unit = unit
	local isDebuff = container.containerType == "Debuff"
	local maxAuras = container.maxAuras or (isDebuff and 16 or 32)
	local sort = isDebuff and SortMethod("UnitFrameDebuff") or SortMethod("Default")
	local dir = SortDir()
	local width, height, ownW, ownH, spacing = IconSizes(container)

	if not isDebuff then
		if not AddGroup(engine, "buffs", "HELPFUL", GroupOptions(
			maxAuras, sort, dir, MakeInitializer(container, width, height), GroupLayout(width, height, spacing)
		)) then
			DiscardEngine(engine)
			return false
		end
	else
		local own = UF.AuraOwn
		local fullFilter = (own and own.GetHarmfulFilter and own.GetHarmfulFilter()) or "HARMFUL"
		local ownFilter = (own and own.GetOwnHarmfulFilter and own.GetOwnHarmfulFilter())
			or (own and own.PLAYER_HARMFUL_FILTER)
			or "HARMFUL|PLAYER"
		-- Nil when this client has no "!" filters. Do not invent HARMFUL|!PLAYER.
		local otherFilter = own and own.GetOtherHarmfulFilter and own.GetOtherHarmfulFilter() or nil
		local allOptions = GroupOptions(
			maxAuras, sort, dir, MakeInitializer(container, width, height), GroupLayout(width, height, spacing)
		)
		local splitOk = false
		if otherFilter then
			local ownOk = AddGroup(engine, "own", ownFilter, GroupOptions(
				maxAuras, sort, dir, MakeInitializer(container, ownW, ownH), GroupLayout(ownW, ownH, spacing, 1)
			))
			local otherOk = ownOk and AddGroup(engine, "other", otherFilter, GroupOptions(
				maxAuras, sort, dir, MakeInitializer(container, width, height), GroupLayout(width, height, spacing, 2)
			))
			splitOk = ownOk and otherOk and true or false
			if ownOk and not otherOk then
				-- A player-only group would hide every other debuff, including the first one.
				DiscardEngine(engine)
				local okAll, createdAll = pcall(CreateFrame, "AuraContainer", name .. "All", container, "CustomAuraContainerTemplate")
				engine = okAll and createdAll or nil
				if not engine then
					return false
				end
				PlaceEngine(engine, container)
				splitOk = false
			end
		end
		if not splitOk then
			if not AddGroup(engine, "all", fullFilter, allOptions) then
				DiscardEngine(engine)
				return false
			end
		end
	end

	container._fluxEngine = engine
	container.buttons = container.buttons or {}
	UF.SyncEngineAuras(container, frame)
	pcall(engine.Show, engine)
	return true
end
