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

function Stance.Anchor()
	local frame = Stance.GetFrame()
	if not frame then
		return
	end
	if InLockdown() then
		Defer("bars.stance.anchor", Stance.Anchor)
		return
	end
	Stance.ApplyBorderChrome()
	frame:ClearAllPoints()
	if Stance.ShouldAnchorToPlayerBorder() then
		local player = ns.PlayerFrame or _G.FluxUIPlayerFrame
		local obf = player and player.outerBorderFrame
		if obf then
			-- -STANCE_ANCHOR_GAP: negative GAP moves the cluster toward the unitframe.
			frame:SetPoint("RIGHT", obf, "LEFT", -Stance.STANCE_ANCHOR_GAP, 0)
			if Bars.Pet and Bars.Pet.UpdatePosition then
				Bars.Pet.UpdatePosition()
			end
			return
		end
	end
	if ShouldAnchorAboveStatusLoc2() then
		local sb = _G.FluxStatusBarContainer
		frame:SetPoint("BOTTOMRIGHT", sb, "TOPRIGHT", Stance.STANCE_WINDOW_GAP_X, Stance.STATUS_LOC2_STACK_GAP)
		if Bars.Pet and Bars.Pet.UpdatePosition then
			Bars.Pet.UpdatePosition()
		end
		return
	end
	-- Detached: left of FluxWindow TOPLEFT (backup), not the action strip.
	local wf = WindowFrame()
	if wf then
		frame:SetPoint("TOPRIGHT", wf, "TOPLEFT", Stance.STANCE_WINDOW_GAP_X, Stance.STANCE_WINDOW_GAP_Y)
	else
		frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -80, -80)
	end
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
			pcall(slot.SetParent, slot, parent)
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
	local usePetSlot = not Stance.ShouldAnchorToPlayerBorder()
	local outerH = (not usePetSlot) and PlayerOuterH() or nil
	local metrics = Stance.ComputeLayoutMetrics(#visible, usePetSlot, outerH)
	local size = metrics.button_size
	local slotW = metrics.slot_width or size
	local xF = metrics.x_factor or 1
	local spacingX = metrics.spacing_x or (Stance.STANCE_SPACING * xF)
	local actual_width, actual_height = metrics.actual_width, metrics.actual_height
	local stackInset = metrics.stackInset
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
						actual_height = matchPetTotalH
						local contentInnerH = actual_height - metrics.layoutPadV * 2
						stackInset = math.max(0, (contentInnerH - metrics.clusterV) / 2)
					else
						actual_height = naturalH
					end
				end
			end
		end
	end
	frame:SetSize(actual_width, actual_height)

	if Stance.BeginExtraVisualPass then
		Stance.BeginExtraVisualPass()
	end
	local shown = {}
	local visibleIndex = 0
	local bindWidgets = {}
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
			-- Native Extra Button height; face width follows xF (same as HUD
			-- extras). Visual stance size is SetScale inside a SlotFrame.
			local native = (Bars.CONFIG and Bars.CONFIG.buttonSize) or 44
			local faceW = native * xF
			local faceH = native
			local slot = EnsureSlot(btn, frame)
			btn.Widget:SetSize(faceW, faceH)
			btn.Widget._fluxStanceButtonSize = size
			if btn.Widget.SetScale then
				pcall(btn.Widget.SetScale, btn.Widget, size / native)
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
			local col = math.floor((visibleIndex - 1) / metrics.num_rows)
			local row = (visibleIndex - 1) % metrics.num_rows
			local x = -(col * (slotW + spacingX))
			local y = stackInset + (row * (size + Stance.STANCE_SPACING))
			if slot then
				slot:SetSize(slotW, size)
				slot:ClearAllPoints()
				slot:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -metrics.layoutPadH + x, -metrics.layoutPadV - y)
				if slot.SetClipsChildren then
					local clip = (metrics.x_factor or 1) < 1
					if Flux.Client and (Flux.Client.isAnyClassic or Flux.Client.isPostDF == false) then
						clip = false
					end
					pcall(slot.SetClipsChildren, slot, clip)
				end
				if btn.Widget.SetParent then
					pcall(btn.Widget.SetParent, btn.Widget, slot)
				end
				btn.Widget:ClearAllPoints()
				btn.Widget:SetPoint("CENTER", slot, "CENTER", 0, 0)
				slot:Show()
			else
				btn.Widget:ClearAllPoints()
				btn.Widget:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -metrics.layoutPadH + x, -metrics.layoutPadV - y)
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
