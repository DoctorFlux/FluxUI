-- Bars/Pet/Layout.lua — 5×2 slots, X-squeeze, FluxBorder -2/-4.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Pet = Bars.Pet

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function Defer(fn)
	if Flux.Combat and Flux.Combat.Defer then
		Flux.Combat.Defer("bars.pet.layout", fn)
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

function Pet.LayoutButtons()
	local frame = Pet.GetFrame and Pet.GetFrame()
	if not frame then
		return
	end
	if InLockdown() then
		Defer(Pet.LayoutButtons)
		return
	end
	local C = Pet.CONFIG
	local xF = SqueezeX()
	local buttonSize = C.buttonSize
	local padding = C.buttonPadding
	local slotW = buttonSize * xF
	local slotH = buttonSize
	local native = (Bars.CONFIG and Bars.CONFIG.buttonSize) or 44
	local buttons = Pet.GetAllButtons and Pet.GetAllButtons() or {}
	for i = 1, C.totalButtons do
		local btn = buttons[i]
		local widget = btn and btn.Widget
		if widget then
			local row = math.floor((i - 1) / C.columns) + 1
			local col = ((i - 1) % C.columns) + 1
			local xOffset = (col - 1) * (slotW + padding)
			local yOffset = -(row - 1) * (slotH + padding)
			local slot = EnsureSlot(btn, frame)
			local faceW = native * xF
			local faceH = native
			widget:SetSize(faceW, faceH)
			if widget.SetScale then
				pcall(widget.SetScale, widget, slotH / native)
			end
			local Style = Flux.EBS and Flux.EBS.Style
			if Style and Style.RefreshSqueezeChrome then
				Style.RefreshSqueezeChrome(btn, faceW, faceH)
			elseif Style and Style.SizeRing then
				Style.SizeRing(btn)
			end
			if slot then
				slot:SetSize(slotW, slotH)
				slot:ClearAllPoints()
				slot:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
				if slot.SetClipsChildren then
					local clip = xF < 1
					if Flux.Client and (Flux.Client.isAnyClassic or Flux.Client.isPostDF == false) then
						clip = false
					end
					pcall(slot.SetClipsChildren, slot, clip)
				end
				if widget.SetParent then
					pcall(widget.SetParent, widget, slot)
				end
				widget:ClearAllPoints()
				widget:SetPoint("CENTER", slot, "CENTER", 0, 0)
				slot:Show()
			else
				widget:ClearAllPoints()
				widget:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
			end
			widget:Show()
			if Flux.EBS and Flux.EBS.Paint and Flux.EBS.Paint.UpdateAutocast then
				Flux.EBS.Paint.UpdateAutocast(btn, btn.PetAutoCastAllowed, btn.PetAutoCastEnabled)
			end
		end
	end
	local totalWidth = (slotW + padding) * C.columns - padding
	local totalHeight = (slotH + padding) * C.rows - padding
	frame:SetSize(totalWidth, totalHeight)
	if FluxBorder and FluxBorder.ApplyTo then
		FluxBorder:ApplyTo(frame, -2, -4, -2, -4)
	end
	local Stance = Bars.Stance
	if Stance and Stance.RequestSizeOnly then
		Stance.RequestSizeOnly()
	end
	if Pet.UpdatePosition then
		Pet.UpdatePosition()
	end
end
