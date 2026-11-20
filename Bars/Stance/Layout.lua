-- Bars/Stance/Layout.lua — size, stack, anchors. Dirty layout vs visual-only.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Stance = Bars.Stance

local dirty = {
	layout = true,
	formsVisual = false,
	extrasVisual = false,
	extrasDiscover = true,
}
local layoutPending = false
local lastVisibleCount = -1
local settledLayout

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function Defer(key, fn)
	if Flux.Combat and Flux.Combat.Defer then
		Flux.Combat.Defer(key, fn)
	elseif not InLockdown() then
		fn()
	end
end

-- Read current native geometry on every pass. Missing, failed or private
-- getters retain the original setters; no desired-state cache can hide drift.
local function NativeValue(frame, method, ...)
	local getter = frame[method]
	if (issecretvalue and issecretvalue(getter)) or type(getter) ~= "function" then return false end
	local ok, a, b, c, d, e = pcall(getter, frame, ...)
	if not ok or (issecretvalue and (issecretvalue(a) or issecretvalue(b)
		or issecretvalue(c) or issecretvalue(d) or issecretvalue(e))) then return false end
	return true, a, b, c, d, e
end

local function SetSize(frame, width, height)
	local ok, w, h = NativeValue(frame, "GetSize")
	if not (issecretvalue and (issecretvalue(width) or issecretvalue(height)))
		and ok and w == width and h == height then return end
	frame:SetSize(width, height)
end

local function SetScale(frame, scale)
	local ok, current = NativeValue(frame, "GetScale")
	if not (issecretvalue and issecretvalue(scale)) and ok and current == scale then return end
	frame:SetScale(scale)
end

local function SetParent(frame, parent)
	local ok, current = NativeValue(frame, "GetParent")
	if not (issecretvalue and issecretvalue(parent)) and ok and current == parent then return end
	frame:SetParent(parent)
end

local function LayoutNumberMatches(value, expected)
	return not (issecretvalue and (issecretvalue(value) or issecretvalue(expected)))
		and type(value) == "number" and type(expected) == "number" and math.abs(value - expected) < 0.0001
end

local function PointMatches(frame, point, relative, relativePoint, x, y)
	local ok, count = NativeValue(frame, "GetNumPoints")
	if ok and count == 1 then
		local public, p, parent, rp, ox, oy = NativeValue(frame, "GetPoint", 1)
		return public and not (issecretvalue and issecretvalue(relative)) and p == point and parent == relative
			and rp == relativePoint and LayoutNumberMatches(ox, x) and LayoutNumberMatches(oy, y)
	end
	return false
end

local function SetSinglePoint(frame, point, relative, relativePoint, x, y)
	if PointMatches(frame, point, relative, relativePoint, x, y) then return end
	frame:ClearAllPoints()
	frame:SetPoint(point, relative, relativePoint, x, y)
end

local function SqueezeX()
	local g = FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames
	local m = g and g()
	if type(m) ~= "number" or m ~= m or m <= 0 then
		return 1
	end
	return m
end

function Stance.ComputeLayoutMetrics(visibleCount, usePetSlot, outerH)
	local layoutPadH = usePetSlot and Stance.PET_SLOT_LAYOUT_PAD_H or Stance.BORDER_PAD_H
	local layoutPadV = usePetSlot and Stance.PET_SLOT_LAYOUT_PAD_V or Stance.BORDER_PAD_V
	local availableHeight
	-- Pos 1: content budget from player outerBorder height (BORDER_PAD_H, not V).
	-- Detached: 5-row STANCE_SIZE stack, then ApplyLayout may stretch to pet height.
	if outerH and outerH > 1 then
		availableHeight = outerH - (Stance.BORDER_PAD_H * 2)
	else
		availableHeight = Stance.STANCE_SIZE * Stance.MAX_ROWS_PER_COLUMN
			+ (Stance.MAX_ROWS_PER_COLUMN - 1) * Stance.STANCE_SPACING
	end
	if availableHeight < 1 then
		availableHeight = Stance.STANCE_SIZE
	end
	local num_rows = math.min(visibleCount, Stance.MAX_ROWS_PER_COLUMN)
	local cols = math.ceil(visibleCount / math.max(num_rows, 1))
	local rowsV = (cols == 1) and visibleCount or num_rows
	if rowsV < 1 then
		rowsV = 1
	end
	local function fitN(n)
		return (availableHeight - (n - 1) * Stance.STANCE_SPACING) / n
	end
	local refCount = Stance.STANCE_SIZE_REF_COUNT or 3
	local maxButtonSize = fitN(refCount)
	local minFitSize = fitN(rowsV)
	-- n < refCount → clamp to ref stack size; n >= refCount → fill availableHeight.
	local button_size = math.min(minFitSize, maxButtonSize)
	local mult = Stance.STANCE_BUTTON_SIZE_MULT or 1.055
	button_size = math.max(button_size, 4)
	button_size = button_size * mult
	button_size = math.max(button_size, 4)
	local refButtonSize = math.max(maxButtonSize, 4) * mult
	refButtonSize = math.max(refButtonSize, 4)
	local innerHRef = refCount * refButtonSize + (refCount - 1) * Stance.STANCE_SPACING
	local clusterV = rowsV * button_size + (rowsV - 1) * Stance.STANCE_SPACING
	local innerH = math.max(innerHRef, clusterV)
	local stackInset = math.max(0, (innerH - clusterV) / 2)
	local xF = SqueezeX()
	local slotW = button_size * xF
	local spacingX = Stance.STANCE_SPACING * xF
	return {
		layoutPadH = layoutPadH,
		layoutPadV = layoutPadV,
		num_rows = num_rows,
		cols = cols,
		button_size = button_size,
		slot_width = slotW,
		spacing_x = spacingX,
		x_factor = xF,
		stackInset = stackInset,
		actual_width = cols * slotW + (cols - 1) * spacingX + layoutPadH * 2,
		actual_height = innerH + layoutPadV * 2,
		clusterV = clusterV,
		innerH = innerH,
	}
end

local function PlayerOuterH()
	local player = ns.PlayerFrame or _G.FluxUIPlayerFrame
	local obf = player and player.outerBorderFrame
	if obf and obf.GetHeight then
		return obf:GetHeight()
	end
	return nil
end

local function ShouldAnchorAboveStatusLoc2()
	if Stance.ShouldAnchorToPlayerBorder() then
		return false
	end
	if not FluxOptions or not FluxOptions.GetStatusBarPosition or FluxOptions:GetStatusBarPosition() ~= 2 then
		return false
	end
	local sb = _G.FluxStatusBarContainer
	return sb and sb.IsShown and sb:IsShown()
end

local function WindowFrame()
	if FluxWindowFrame and FluxWindowFrame.GetFrame then
		return FluxWindowFrame:GetFrame()
	end
	return _G.FluxWindowFrame
end

local function DesiredScale(frame)
	local player = Stance.ShouldAnchorToPlayerBorder() and (ns.PlayerFrame or _G.FluxUIPlayerFrame)
	-- Anchoring does not inherit scale: the secure stance root stays under UIParent.
	return player and player:GetEffectiveScale() / frame:GetParent():GetEffectiveScale() or 1
end

local function SyncPlayerScale(frame)
	local scale = DesiredScale(frame)
	if frame:GetScale() ~= scale then
		frame:SetScale(scale)
	end
end

local function AnchorPoint()
	if Stance.ShouldAnchorToPlayerBorder() then
		local player = ns.PlayerFrame or _G.FluxUIPlayerFrame
		local obf = player and player.outerBorderFrame
		if obf then
			-- -STANCE_ANCHOR_GAP: negative GAP moves the cluster toward the unitframe.
			return "RIGHT", obf, "LEFT", -Stance.STANCE_ANCHOR_GAP, 0
		end
	end
	if ShouldAnchorAboveStatusLoc2() then
		return "BOTTOMRIGHT", _G.FluxStatusBarContainer, "TOPRIGHT",
			Stance.STANCE_WINDOW_GAP_X, Stance.STATUS_LOC2_STACK_GAP
	end
	-- Detached: left of FluxWindow TOPLEFT (backup), not the action strip.
	local wf = WindowFrame()
	if wf then
		return "TOPRIGHT", wf, "TOPLEFT", Stance.STANCE_WINDOW_GAP_X, Stance.STANCE_WINDOW_GAP_Y
	end
	return "TOPRIGHT", UIParent, "TOPRIGHT", -80, -80
end

function Stance.Anchor()
	local frame = Stance.GetFrame()
	if not frame then
		return
	end
	if InLockdown() then
		Defer("bars.stance.anchor", Stance.Anchor)
		return
	end
	SyncPlayerScale(frame)
	Stance.ApplyBorderChrome()
	SetSinglePoint(frame, AnchorPoint())
	if Bars.Pet and Bars.Pet.UpdatePosition then
		Bars.Pet.UpdatePosition()
	end
end

local function HideWidget(btn)
	if not btn or not btn.Widget then
		return
	end
	if InLockdown() then
		return
	end
	btn.Widget:Hide()
	if btn.SlotFrame and btn.SlotFrame.Hide then
		btn.SlotFrame:Hide()
	end
end

-- Extra Buttons pack a visual SlotFrame and SetScale the native 44px widget
-- inside it. Anchoring the 44px widget on visual-size steps overlaps neighbors.
local function EnsureSlot(btn, parent)
	if not btn then
		return nil
	end
	local slot = btn.SlotFrame
	if slot then
		if parent and slot.SetParent then
			pcall(SetParent, slot, parent)
		end
		return slot
	end
	if InLockdown() then
		return nil
	end
	slot = CreateFrame("Frame", nil, parent)
	if slot.EnableMouse then
		pcall(slot.EnableMouse, slot, false)
	end
	btn.SlotFrame = slot
	return slot
end

local function Sizing(frame, visibleCount)
	local usePetSlot = not Stance.ShouldAnchorToPlayerBorder()
	local outerH = (not usePetSlot) and PlayerOuterH() or nil
	local metrics = Stance.ComputeLayoutMetrics(visibleCount, usePetSlot, outerH)
	if usePetSlot then
		local petF = Bars.Pet and Bars.Pet.GetFrame and Bars.Pet.GetFrame()
		if petF and frame.GetEffectiveScale then
			local eff = frame:GetEffectiveScale()
			if eff and eff > 0 then
				local petH = petF.GetHeight and petF:GetHeight() or 0
				local petScale = petF.GetEffectiveScale and petF:GetEffectiveScale() or 1
				local matchPetTotalH = (petH * petScale) / eff
				if matchPetTotalH > 1 then
					local naturalH = metrics.innerH + metrics.layoutPadV * 2
					if matchPetTotalH >= naturalH then
						metrics.actual_height = matchPetTotalH
						local contentInnerH = matchPetTotalH - metrics.layoutPadV * 2
						metrics.stackInset = math.max(0, (contentInnerH - metrics.clusterV) / 2)
					else
						metrics.actual_height = naturalH
					end
				end
			end
		end
	end
	return metrics, usePetSlot
end

local function SlotPoint(metrics, index)
	local size = metrics.button_size
	local slotW = metrics.slot_width or size
	local spacingX = metrics.spacing_x or (Stance.STANCE_SPACING * (metrics.x_factor or 1))
	local column = math.floor((index - 1) / metrics.num_rows)
	local row = (index - 1) % metrics.num_rows
	return -metrics.layoutPadH - column * (slotW + spacingX),
		-metrics.layoutPadV - (metrics.stackInset + row * (size + Stance.STANCE_SPACING))
end

local function ClipsChildren(metrics)
	local client = Flux.Client
	return (metrics.x_factor or 1) < 1
		and not (client and (client.isAnyClassic or client.isPostDF == false))
end

function Stance.ApplyLayout()
	local frame = Stance.GetFrame()
	if not frame then
		return false
	end
	if InLockdown() then
		Defer("bars.stance.layout", function()
			dirty.layout = true
			Stance.ApplyLayout()
		end)
		return false
	end
	settledLayout = nil
	SyncPlayerScale(frame)
	if dirty.extrasDiscover and Stance.InvalidateExtras then
		Stance.InvalidateExtras()
		dirty.extrasDiscover = false
	end
	local numForms, extras, customs, total = Stance.Catalog()
	local shouldShow = {}
	for i = 1, numForms do
		shouldShow[i] = true
	end
	for e = 1, #extras do
		shouldShow[numForms + e] = Stance.ShouldShowExtra and Stance.ShouldShowExtra(extras[e], numForms) or true
	end
	for c = 1, #customs do
		local show = true
		if Stance.ShouldShowCustom then
			show = Stance.ShouldShowCustom(customs[c], numForms, extras) and true or false
		end
		shouldShow[numForms + #extras + c] = show
	end
	if Stance.ApplyHiddenToShouldShow then
		Stance.ApplyHiddenToShouldShow(shouldShow, total, numForms, extras, customs)
	end
	local perm = Stance.BuildPermutation and Stance.BuildPermutation(total, numForms, extras, Stance.GetSavedOrder(), customs)
		or {}
	local visible = {}
	for p = 1, #perm do
		local idx = perm[p]
		if shouldShow[idx] then
			visible[#visible + 1] = idx
		end
	end
	local metrics, usePetSlot = Sizing(frame, #visible)
	local size = metrics.button_size
	local slotW = metrics.slot_width or size
	local xF = metrics.x_factor or 1
	SetSize(frame, metrics.actual_width, metrics.actual_height)

	if Stance.BeginExtraVisualPass then
		Stance.BeginExtraVisualPass()
	end
	local shown = {}
	local visibleIndex = 0
	local bindWidgets = {}
	local visibleButtons = {}
	for v = 1, #visible do
		local idx = visible[v]
		local btn
		if idx <= numForms then
			btn = Stance.EnsureFormButton(idx, frame, size)
			if not (btn and btn.Widget) then return false end
			shown[btn] = true
			if Stance.TagFormArmor then
				Stance.TagFormArmor(btn, idx)
			end
		elseif idx <= numForms + #extras then
			local data = extras[idx - numForms]
			local key = Stance.MakeSlotKey(idx, numForms, extras, customs)
			btn = Stance.EnsureExtraButton(key, frame, size, data)
			if not (btn and btn.Widget) then return false end
			shown[btn] = true
		else
			local data = customs[idx - numForms - #extras]
			local key = (data and data.key) or Stance.MakeSlotKey(idx, numForms, extras, customs)
			btn = Stance.EnsureExtraButton(key, frame, size, data)
			if not (btn and btn.Widget) then return false end
			shown[btn] = true
		end
		if btn and btn.Widget then
			visibleIndex = visibleIndex + 1
			bindWidgets[#bindWidgets + 1] = btn.Widget
			visibleButtons[visibleIndex] = btn
			-- Native Extra Button height; face width follows xF (same as HUD
			-- extras). Visual stance size is SetScale inside a SlotFrame.
			local native = (Bars.CONFIG and Bars.CONFIG.buttonSize) or 44
			local faceW = native * xF
			local faceH = native
			local slot = EnsureSlot(btn, frame)
			SetSize(btn.Widget, faceW, faceH)
			btn.Widget._fluxStanceButtonSize = size
			if btn.Widget.SetScale then
				pcall(SetScale, btn.Widget, size / native)
			end
			-- Placement 2 sits with the pet bar. Stamp the squeezed face so the
			-- ring, border, and highlight match it (GetWidth is still square here).
			local Style = Flux.EBS and Flux.EBS.Style
			local petSlot = not Stance.ShouldAnchorToPlayerBorder()
			if petSlot and Style and Style.RefreshSqueezeChrome then
				Style.RefreshSqueezeChrome(btn, faceW, faceH)
			else
				if Style and Style.SizeRing then
					Style.SizeRing(btn)
				end
				if FluxButtonUtil and FluxButtonUtil.SyncFluxButtonLayerSizesToWidget then
					FluxButtonUtil:SyncFluxButtonLayerSizesToWidget(btn)
				end
			end
			if Stance.AttachReorderControls then
				Stance.AttachReorderControls(btn)
			end
			local x, y = SlotPoint(metrics, visibleIndex)
			if slot then
				SetSize(slot, slotW, size)
				SetSinglePoint(slot, "TOPRIGHT", frame, "TOPRIGHT", x, y)
				if slot.SetClipsChildren then
					pcall(slot.SetClipsChildren, slot, ClipsChildren(metrics))
				end
				if btn.Widget.SetParent then
					pcall(SetParent, btn.Widget, slot)
				end
				SetSinglePoint(btn.Widget, "CENTER", slot, "CENTER", 0, 0)
				slot:Show()
			else
				SetSinglePoint(btn.Widget, "TOPRIGHT", frame, "TOPRIGHT", x, y)
			end
			btn.Widget:Show()
			if Stance.ApplyExtraActiveVisual and (btn.spellData or btn._fluxStanceMageArmorForm) then
				Stance.ApplyExtraActiveVisual(btn)
			end
			if Flux.EBS and Flux.EBS.Paint and Flux.EBS.Paint.Update then
				Flux.EBS.Paint.Update(btn)
			end
		end
	end
	-- Hide unused pooled buttons.
	if Stance.ForEachPooled then
		Stance.ForEachPooled(function(btn)
			if not shown[btn] then
				HideWidget(btn)
			end
		end)
	end

	lastVisibleCount = #visible
	Stance.visibleBindWidgets = bindWidgets
	Stance.Anchor()
	if Stance.ReassignBindings() == false then return false end
	if #visible == 0 then
		frame:Hide()
	else
		frame:Show()
	end
	dirty.layout = false
	dirty.formsVisual = false
	dirty.extrasVisual = false
	if FluxBorder and FluxBorder.Junctions then
		FluxBorder.Junctions:CommitLayout()
	end
	settledLayout = { frame = frame, border = frame.FluxBorderFrame, widgets = bindWidgets,
		buttons = visibleButtons, petSlot = usePetSlot }
	return true
end

function Stance.RequestLayout(reason)
	dirty.layout = true
	if reason == "discover" then
		dirty.extrasDiscover = true
	end
	if layoutPending then
		return
	end
	layoutPending = true
	local after = (Flux.Timer and Flux.Timer.Defer) or (C_Timer and C_Timer.After and function(fn)
		C_Timer.After(0, fn)
	end)
	local function run()
		layoutPending = false
		if dirty.layout then
			Stance.ApplyLayout()
		end
	end
	if after then
		after(run)
	else
		run()
	end
end

function Stance.RequestSizeOnly()
	Stance.RequestLayout("size")
end

local function SizeMatches(frame, width, height)
	local ok, w, h = NativeValue(frame, "GetSize")
	return ok and LayoutNumberMatches(w, width) and LayoutNumberMatches(h, height)
end

local function ValueMatches(frame, method, expected)
	local ok, value = NativeValue(frame, method)
	return ok and value == expected
end

local function StripLayoutMatches(layout, frame)
	if layout.frame ~= frame or layout.border ~= frame.FluxBorderFrame
		or layout.widgets ~= Stance.visibleBindWidgets then return false end
	local count = #layout.widgets
	local ok, scale = NativeValue(frame, "GetScale")
	local desired = DesiredScale(frame)
	if not ok or not LayoutNumberMatches(scale, desired)
		or not PointMatches(frame, AnchorPoint()) or not ValueMatches(frame, "IsShown", count > 0) then return false end
	local metrics, petSlot = Sizing(frame, count)
	if petSlot ~= layout.petSlot or not SizeMatches(frame, metrics.actual_width, metrics.actual_height) then return false end
	local size = metrics.button_size
	local native = (Bars.CONFIG and Bars.CONFIG.buttonSize) or 44
	local clip = ClipsChildren(metrics)
	for i, widget in ipairs(layout.widgets) do
		local button = layout.buttons[i]
		local slot = button.SlotFrame
		local x, y = SlotPoint(metrics, i)
		local scaleOK, faceScale = NativeValue(widget, "GetScale")
		if button.Widget ~= widget or not slot or not scaleOK or not LayoutNumberMatches(faceScale, size / native)
			or not SizeMatches(widget, native * (metrics.x_factor or 1), native)
			or not SizeMatches(slot, metrics.slot_width or size, size)
			or not ValueMatches(widget, "GetParent", slot) or not ValueMatches(slot, "GetParent", frame)
			or not ValueMatches(widget, "IsShown", true) or not ValueMatches(slot, "IsShown", true)
			or not PointMatches(widget, "CENTER", slot, "CENTER", 0, 0)
			or not PointMatches(slot, "TOPRIGHT", frame, "TOPRIGHT", x, y)
			or (slot.SetClipsChildren and not ValueMatches(slot, "DoesClipChildren", clip)) then return false end
	end
	return true
end

function Stance.RequestStripLayout()
	local frame = Stance.GetFrame()
	if not frame then return end
	-- A strip crossing translates the existing anchor's owner. Form discovery,
	-- bindings and button paint retain their normal event paths.
	if settledLayout and not dirty.layout and not InLockdown() then
		local ok, matches = pcall(StripLayoutMatches, settledLayout, frame)
		if ok and matches then return end
	end
	Stance.RequestSizeOnly()
end

function Stance.RequestFormsVisual()
	dirty.formsVisual = true
	local after = Flux.Timer and Flux.Timer.Defer
	local function run()
		if dirty.layout then
			dirty.formsVisual = false
			return
		end
		if dirty.formsVisual and Stance.PaintFormVisuals then
			Stance.PaintFormVisuals()
		end
		dirty.formsVisual = false
	end
	if after then
		after(run)
	else
		run()
	end
end

function Stance.RequestExtrasVisual()
	dirty.extrasVisual = true
	local after = Flux.Timer and Flux.Timer.Defer
	local function run()
		if dirty.layout then
			dirty.extrasVisual = false
			return
		end
		if dirty.extrasVisual and Stance.PaintExtraVisuals then
			Stance.PaintExtraVisuals()
		end
		dirty.extrasVisual = false
	end
	if after then
		after(run)
	else
		run()
	end
end

function Stance.RequestDiscover()
	Stance.RequestLayout("discover")
end
