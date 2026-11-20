-- Bars/Pet/Layout.lua — 5×2 slots, X-squeeze, FluxBorder -2/-4.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Pet = Bars.Pet
local packed

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

local function Offset(layout, index)
	local row = math.floor((index - 1) / layout.columns)
	local column = (index - 1) % layout.columns
	return column * (layout.slotW + layout.padding), -row * (layout.slotH + layout.padding)
end

local function Matches(value, expected)
	if issecretvalue and (issecretvalue(value) or issecretvalue(expected)) then return false end
	if type(expected) == "number" then
		return type(value) == "number" and math.abs(value - expected) < 0.0001
	end
	return value == expected
end

local function SizeMatches(frame, width, height)
	local w, h = frame:GetSize()
	return Matches(w, width) and Matches(h, height)
end

local function PointMatches(frame, point, relative, x, y)
	if not Matches(frame:GetNumPoints(), 1) then return false end
	local p, parent, rp, ox, oy = frame:GetPoint(1)
	return Matches(p, point) and Matches(parent, relative) and Matches(rp, point)
		and Matches(ox, x) and Matches(oy, y)
end

local function PackingMatches(previousPacking, layout, buttons)
	for key, value in pairs(layout) do
		if previousPacking[key] ~= value then return false end
	end
	if not SizeMatches(layout.frame, layout.width, layout.height) then return false end
	for i = 1, layout.count do
		local btn = buttons[i]
		local widget = btn and btn.Widget
		local slot = btn and btn.SlotFrame
		local previous = previousPacking.slots[i]
		if widget then
			local x, y = Offset(layout, i)
			if not previous or previous.button ~= btn or previous.widget ~= widget or previous.slot ~= slot
				or not slot or not Matches(slot:GetParent(), layout.frame) or not Matches(widget:GetParent(), slot)
				or not Matches(slot:IsShown(), true) or not Matches(widget:IsShown(), true)
				or not SizeMatches(slot, layout.slotW, layout.slotH) or not SizeMatches(widget, layout.faceW, layout.native)
				or not Matches(widget:GetScale(), layout.scale)
				or not PointMatches(slot, "TOPLEFT", layout.frame, x, y)
				or not PointMatches(widget, "CENTER", slot, 0, 0) then return false end
			if slot.SetClipsChildren and (not slot.DoesClipChildren
				or not Matches(slot:DoesClipChildren(), layout.clip)) then return false end
			if layout.chrome and (not Matches(widget._fluxLayoutW, layout.faceW)
				or not Matches(widget._fluxLayoutH, layout.native)) then return false end
			if layout.autocast and (not Matches(btn.PetAutoCastAllowed, previous.autoAllowed)
				or not Matches(btn.PetAutoCastEnabled, previous.autoEnabled)) then return false end
		elseif previous then return false end
	end
	return true
end

local function ApplyPacking(layout, buttons)
	packed = nil
	local frame = layout.frame
	local slotW, slotH = layout.slotW, layout.slotH
	local slots = {}
	for i = 1, layout.count do
		local btn = buttons[i]
		local widget = btn and btn.Widget
		if widget then
			local xOffset, yOffset = Offset(layout, i)
			local slot = EnsureSlot(btn, frame)
			slots[i] = { button = btn, widget = widget, slot = slot }
			widget:SetSize(layout.faceW, layout.native)
			if widget.SetScale then
				pcall(widget.SetScale, widget, layout.scale)
			end
			if layout.chrome then
				layout.chrome(btn, layout.faceW, layout.native)
			elseif layout.ring then
				layout.ring(btn)
			end
			if slot then
				slot:SetSize(slotW, slotH)
				slot:ClearAllPoints()
				slot:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
				if slot.SetClipsChildren then
					pcall(slot.SetClipsChildren, slot, layout.clip)
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
			if layout.autocast then
				layout.autocast(btn, btn.PetAutoCastAllowed, btn.PetAutoCastEnabled)
				slots[i].autoAllowed = btn.PetAutoCastAllowed
				slots[i].autoEnabled = btn.PetAutoCastEnabled
			end
		end
	end
	frame:SetSize(layout.width, layout.height)
	layout.slots = slots
	packed = layout
end

function Pet.LayoutButtons(deferBorderCommit, keepPacking)
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
	local slotW, slotH = C.buttonSize * xF, C.buttonSize
	local native = (Bars.CONFIG and Bars.CONFIG.buttonSize) or 44
	local style = Flux.EBS and Flux.EBS.Style
	local paint = Flux.EBS and Flux.EBS.Paint
	local client = Flux.Client
	local layout = {
		frame = frame, count = C.totalButtons, columns = C.columns, padding = C.buttonPadding,
		slotW = slotW, slotH = slotH, native = native, faceW = native * xF, scale = slotH / native,
		width = (slotW + C.buttonPadding) * C.columns - C.buttonPadding,
		height = (slotH + C.buttonPadding) * C.rows - C.buttonPadding,
		clip = xF < 1 and not (client and (client.isAnyClassic or client.isPostDF == false)),
		chrome = style and style.RefreshSqueezeChrome or false, ring = style and style.SizeRing or false,
		autocast = paint and paint.UpdateAutocast or false,
	}
	local buttons = Pet.GetAllButtons and Pet.GetAllButtons() or {}
	local matched
	if deferBorderCommit == true and keepPacking == true and packed then
		local ok, fits = pcall(PackingMatches, packed, layout, buttons)
		matched = ok and fits
	end
	-- The strip can move the pet root without changing any relative slots.
	-- Check live geometry before keeping the existing faces and chrome.
	if not matched then ApplyPacking(layout, buttons) end
	if FluxBorder and FluxBorder.ApplyTo then
		FluxBorder:ApplyTo(frame, -2, -4, -2, -4)
	end
	local Stance = Bars.Stance
	-- The strip notifier samples stance after pet geometry and position settle.
	if Stance and Stance.RequestSizeOnly and not (deferBorderCommit == true and keepPacking == true) then
		Stance.RequestSizeOnly()
	end
	if Pet.UpdatePosition then
		Pet.UpdatePosition()
	end
	-- Action-strip layout commits after its pet and side panels have settled.
	if deferBorderCommit ~= true and FluxBorder and FluxBorder.Junctions then
		FluxBorder.Junctions:CommitLayout()
	end
end
