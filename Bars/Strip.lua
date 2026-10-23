-- Bars/Strip.lua — 19-column holder. Inner scale 1.24; extra upscale 1.0–1.5×
-- when no minis; horizontal squeeze at min UI scale; Y from status-bar overlay.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Strip = {}
Bars.Strip = Strip

Strip.slots = {}
Strip.xFactor = 1
Strip.extraScale = 1

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

--- Bottom offset from UIParent (positive = up). Shared with Extra Button layout.
function Strip.GetBottomScreenOffset()
	local C = Bars.CONFIG
	local lift = 0
	if _G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome then
		lift = _G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome() or 0
	elseif _G.FluxStatusBar_GetBottomOverlayHeight then
		lift = _G.FluxStatusBar_GetBottomOverlayHeight() or 0
		if lift > 0 and FluxOptions and FluxOptions.GetStatusBarPosition and FluxOptions:GetStatusBarPosition() == 3 then
			lift = math.max(0, lift - 4)
		end
	end
	return (C.yOffset or 4) + lift
end

_G.FluxActionBar_GetBottomScreenOffset = Strip.GetBottomScreenOffset

function Strip.UpdatePosition()
	if Bars.Layout and Bars.Layout.Apply then
		Bars.Layout.Apply()
		return
	end
	if Strip.frame then
		Strip.Layout()
	end
end

_G.FluxActionBar = _G.FluxActionBar or {}
_G.FluxActionBar.UpdatePosition = Strip.UpdatePosition

function Strip.Metrics(visibleCols, anyMini, extraScale, xFactor)
	local C = Bars.CONFIG
	local cols = visibleCols or Bars.NUM_COLUMNS
	if cols < 1 then
		cols = 1
	end
	extraScale = extraScale or 1
	xFactor = xFactor or 1
	local buttonW = C.buttonSize * xFactor
	local contentW
	if FluxUILayoutSqueeze and FluxUILayoutSqueeze.ComputeVisibleContentWidth then
		contentW = FluxUILayoutSqueeze.ComputeVisibleContentWidth(C.buttonSize, C.padding, cols, xFactor)
	else
		contentW = cols * buttonW + (cols - 1) * C.padding
	end
	-- Inner is one row when no minis, 1.5 when minis show. Outer chrome always
	-- reserves 1.5 so extraScale can grow buttons into the shell (backup SmartLayout).
	local contentH = C.buttonSize * ((anyMini and 1.5) or 1)
	local chromeH = C.buttonSize * 1.5
	local effectiveScale = C.scale * extraScale
	return contentW, contentH,
		contentW * effectiveScale + C.margin * 2,
		chromeH * C.scale + C.margin * 2 + C.heightTweak,
		buttonW, effectiveScale
end

local function FrameCenterX()
	local frame = Strip.frame
	if not frame or not frame.GetLeft then
		return nil
	end
	local left, right = frame:GetLeft(), frame:GetRight()
	if not left or not right then
		return nil
	end
	return (left + right) / 2
end

--- Extra upscale 1.0–1.5× when no minis and not expanding; cap 1.0 when minis show.
function Strip.ComputeExtraScale(visibleCols, anyMini, expanding)
	if expanding or anyMini then
		return 1
	end
	if not FluxUILayoutSqueeze or not FluxUILayoutSqueeze.GetDynamicScaleTargets then
		return 1
	end
	local centerX = FrameCenterX()
	local targetRightX, barRightMax = FluxUILayoutSqueeze.GetDynamicScaleTargets()
	if not centerX or not barRightMax then
		return 1
	end
	local C = Bars.CONFIG
	local cols = visibleCols or Bars.NUM_COLUMNS
	if cols < 1 then
		cols = 1
	end
	local contentW = cols * C.buttonSize + (cols - 1) * C.padding
	local desiredWidth = 2 * (barRightMax - centerX)
	if targetRightX then
		desiredWidth = math.min(desiredWidth, 2 * (targetRightX - centerX))
	end
	local baseWidth = contentW * C.scale + (C.margin * 2)
	if baseWidth > 0 and desiredWidth > 0 then
		return math.max(1.0, math.min(1.5, desiredWidth / baseWidth))
	end
	return 1
end

function Strip.ComputeXFactor(visibleCols, extraScale)
	extraScale = extraScale or 1
	if not FluxUILayoutSqueeze or not FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactor then
		return 1
	end
	local centerX = FrameCenterX()
	local _, barRightMax
	if FluxUILayoutSqueeze.GetDynamicScaleTargets then
		_, barRightMax = FluxUILayoutSqueeze.GetDynamicScaleTargets()
	end
	local C = Bars.CONFIG
	local cols = visibleCols or Bars.NUM_COLUMNS
	local xFactor = FluxUILayoutSqueeze.ComputeHorizontalSqueezeFactor(
		centerX, cols, C.buttonSize, C.padding, C.scale * extraScale, barRightMax, C.margin
	)
	if not xFactor or xFactor ~= xFactor or xFactor <= 0 then
		return 1
	end
	return xFactor
end

function Strip.ComputeLook(visibleCols, anyMini, expanding)
	local extraScale = Strip.ComputeExtraScale(visibleCols, anyMini, expanding)
	local xFactor = Strip.ComputeXFactor(visibleCols, extraScale)
	return extraScale, xFactor
end

function Strip.Create()
	if Strip.frame and Strip.frame._fluxStripReady then
		return Strip.frame
	end
	local C = Bars.CONFIG

	local frame = Strip.frame or _G.FluxActionStrip or CreateFrame("Frame", "FluxActionStrip", UIParent)
	Strip.frame = frame
	frame:SetFrameStrata(C.strata)
	frame:SetFrameLevel(C.level)
	frame:SetScale(1.0)
	-- HUD (status loc 2/3, player Y, layout preview) still looks up this name.
	_G.FluxMainActionBar = frame

	local inner = Strip.inner or _G.FluxActionStripContent or CreateFrame("Frame", "FluxActionStripContent", frame)
	Strip.inner = inner
	inner:SetScale(C.scale)

	local sensing = Strip.sensing or _G.FluxActionStripSensing or CreateFrame("Frame", "FluxActionStripSensing", UIParent)
	Strip.sensing = sensing
	sensing:SetFrameStrata("LOW")
	sensing:EnableMouse(false)
	sensing:Hide()

	if FluxBorder and FluxBorder.ApplyTo then
		FluxBorder:ApplyTo(frame, 4, -2, 4, -2)
	end
	Strip.ApplyAppearanceAccent()

	Strip.Layout(Bars.NUM_COLUMNS, false, false, 1, 1)
	frame._fluxStripReady = true
	return frame
end

function Strip.ApplyAppearanceAccent()
	local frame = Strip.frame
	if frame and FluxBorder and FluxBorder.SetClassColor then
		FluxBorder:SetClassColor(frame, 1, true)
	end
	if Bars.Hosts and Bars.Hosts.ApplyChrome then
		Bars.Hosts.ApplyChrome()
	end
end

_G.FluxActionBar_ApplyAppearanceAccent = Strip.ApplyAppearanceAccent

function Strip.GetSlot(column)
	return Strip.slots[column]
end

local function GamepadHudOn()
	local Cap = Flux.Cap
	return Cap and Cap.IsGamepadUIEnabled and Cap.IsGamepadUIEnabled() or false
end

local gamepadWatch
local gamepadRetries = 0
local gamepadRetryPending = false
local lastGamepadFloor

local function After(delay, fn)
	local T = Flux.Timer
	if T and T.After then
		T.After(delay, fn)
		return
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(delay, fn)
	end
end

--- Status, extras, chat, and the player frame read the strip. Once it is hidden
--- they need the gamepad bar's top, measured on our timer rather than a bar script.
function Strip.RefreshClearance()
	if _G.FluxStatusBarUpdateLayout then
		pcall(_G.FluxStatusBarUpdateLayout)
	end
	local EBS = Flux.EBS
	if EBS and EBS.Layout and EBS.Layout.Request then
		EBS.Layout.Request("gamepad-hud")
	end
	-- Status layout anchors the row, then these run again so the scaled
	-- non-combat grid, combat grid, info, and border share the raised Y.
	if _G.FluxNonCombatGrid_ApplyScreenBottomAnchor then
		pcall(_G.FluxNonCombatGrid_ApplyScreenBottomAnchor)
	end
	if _G.FluxCombatManager and _G.FluxCombatManager.UpdateAnchor then
		pcall(_G.FluxCombatManager.UpdateAnchor, _G.FluxCombatManager)
	end
	if _G.FluxTrinketMenuManager and _G.FluxTrinketMenuManager.UpdateAnchor then
		pcall(_G.FluxTrinketMenuManager.UpdateAnchor, _G.FluxTrinketMenuManager)
	end
	if _G.FluxInfoFrame and _G.FluxInfoFrame.UpdatePosition then
		pcall(_G.FluxInfoFrame.UpdatePosition)
	end
	if _G.FluxUnifiedBorder and _G.FluxUnifiedBorder.UpdateBorder then
		pcall(_G.FluxUnifiedBorder.UpdateBorder)
	end
	if _G.FluxChatFrame_ApplyPrimaryPosition then
		pcall(_G.FluxChatFrame_ApplyPrimaryPosition, true)
	end
	if _G.FluxUnitFrames_ApplyPlayerStatusBarLayout then
		pcall(_G.FluxUnitFrames_ApplyPlayerStatusBarLayout)
	end
end

local function ScheduleGamepadRetry()
	if gamepadRetryPending or not GamepadHudOn() then
		return
	end
	local Cap = Flux.Cap
	if Cap and Cap.GetGamepadActionBarFloor and Cap.GetGamepadActionBarFloor() then
		gamepadRetries = 0
		return
	end
	if gamepadRetries >= 6 then
		return
	end
	gamepadRetries = gamepadRetries + 1
	gamepadRetryPending = true
	After(0.25, function()
		gamepadRetryPending = false
		Strip.ApplyGamepadHud()
	end)
end

--- Flux strip stays shown in vehicle/override. Paging maps those slots onto
--- Flux hosts; hiding the strip (or following MainActionBar:IsShown) moves
--- RightManagedFrameContainer. Alpha 1 / Show only; never Hide on vehicle.
--- Gamepad HUD is the only hide: those 19 columns and mini rows yield to Blizzard.
function Strip.SyncVisibility()
	local frame = Strip.frame
	if not frame then
		return
	end
	if Bars.secureReady == false then
		if not InLockdown() then frame:Hide() end
		return
	end
	if GamepadHudOn() then
		if InLockdown() then
			if Flux.Combat and Flux.Combat.Defer then
				Flux.Combat.Defer("bars.strip.gamepad", Strip.ApplyGamepadHud)
			end
			return
		end
		frame:Hide()
		if Strip.sensing then
			Strip.sensing:Hide()
		end
		return
	end
	frame:SetAlpha(1)
	if not InLockdown() then
		frame:Show()
	elseif Flux.Combat and Flux.Combat.Defer then
		Flux.Combat.Defer("bars.strip.gamepad", Strip.ApplyGamepadHud)
	end
	if Bars.started and Flux.Startup then
		local visible = frame.IsVisible and frame:IsVisible() or (not frame.IsVisible and frame:IsShown())
		if visible then Flux.Startup.Mark("action_buttons_visible") end
	end
end

function Strip.ApplyGamepadHud()
	local frame = Strip.frame
	local wasShown = frame and frame.IsShown and frame:IsShown() and true or false
	Strip.SyncVisibility()
	if InLockdown() then
		return
	end
	local shown = frame and frame.IsShown and frame:IsShown() and true or false
	local hud = GamepadHudOn()
	local floor
	if hud and Flux.Cap and Flux.Cap.GetGamepadActionBarFloor then
		floor = Flux.Cap.GetGamepadActionBarFloor()
	end
	local floorChanged = floor ~= lastGamepadFloor
	lastGamepadFloor = floor
	if wasShown ~= shown or floorChanged then
		Strip.RefreshClearance()
	end
	if hud then
		ScheduleGamepadRetry()
	else
		gamepadRetries = 0
	end
	if Bars.Stance and Bars.Stance.ApplyLayout then
		Bars.Stance.ApplyLayout()
	end
end

--- Our frame, not InputUtil's secure transition list. The event is absent
--- without the HUD API, so the register is allowed to fail.
function Strip.WatchGamepad()
	if not gamepadWatch then
		gamepadWatch = CreateFrame("Frame")
		pcall(gamepadWatch.RegisterEvent, gamepadWatch, "INPUT_DEVICE_INTERFACE_TRANSITION")
		gamepadWatch:SetScript("OnEvent", function()
			gamepadRetries = 0
			Strip.ApplyGamepadHud()
		end)
	end
	Strip.ApplyGamepadHud()
end

function Strip.Layout(visibleCols, anyMini, expanding, extraScale, xFactor)
	local frame = Strip.frame
	if not frame then
		return
	end
	local C = Bars.CONFIG
	local cols = visibleCols or Bars.NUM_COLUMNS
	if extraScale == nil or xFactor == nil then
		extraScale, xFactor = Strip.ComputeLook(cols, anyMini, expanding)
	end
	Strip.extraScale = extraScale
	Strip.xFactor = xFactor
	if FluxUILayoutSqueeze and FluxUILayoutSqueeze.SetLastHorizontalSqueezeFactor then
		FluxUILayoutSqueeze.SetLastHorizontalSqueezeFactor(xFactor)
	end

	local contentW, contentH, totalW, totalH, _, effectiveScale = Strip.Metrics(cols, anyMini, extraScale, xFactor)
	local y = Strip.GetBottomScreenOffset()

	frame:ClearAllPoints()
	frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, y)
	frame:SetSize(totalW, totalH)

	local inner = Strip.inner
	inner:SetScale(effectiveScale)
	inner:SetSize(contentW, contentH)
	inner:ClearAllPoints()
	if expanding then
		inner:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
	else
		inner:SetPoint("CENTER", frame, "CENTER", 0, 0)
	end

	local sensing = Strip.sensing
	if sensing then
		sensing:SetSize(totalW + 100, totalH + 100)
		sensing:ClearAllPoints()
		sensing:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, y - 50)
	end

	Strip.SyncVisibility()
	if _G.FluxUnitFrames_ApplyPlayerStatusBarLayout then
		pcall(_G.FluxUnitFrames_ApplyPlayerStatusBarLayout)
	end
end
