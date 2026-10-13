-- Bars/Stance/Init.lua — hybrid stance bar shell and options shims.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars or {}
Flux.Bars = Bars

local Stance = Bars.Stance or {}
Bars.Stance = Stance

Stance.STANCE_SIZE = 30
Stance.STANCE_SPACING = -2
Stance.BORDER_PAD_H = 5.5
Stance.BORDER_PAD_V_EXTRA = 8
Stance.BORDER_PAD_V = Stance.BORDER_PAD_H + Stance.BORDER_PAD_V_EXTRA
Stance.MAX_ROWS_PER_COLUMN = 5
Stance.STANCE_SIZE_REF_COUNT = 3
-- Uniform scale on computed button pixel size (backup V1).
Stance.STANCE_BUTTON_SIZE_MULT = 1.055
Stance.STANCE_WINDOW_GAP_X = -4
Stance.STANCE_WINDOW_GAP_Y = -4
Stance.STATUS_LOC2_STACK_GAP = 2
-- Player-frame X: SetPoint RIGHT→LEFT uses -GAP. Negative GAP nudges toward the unitframe.
Stance.STANCE_ANCHOR_GAP = -4
Stance.COOLDOWN_COUNTDOWN_REF_SIZE = 36
-- Mage-armor remaining uses a stance FontString; Blizzard CD digits ignore SetFont here.
Stance.COOLDOWN_COUNTDOWN_FONT_RATIO = 0.35
Stance.COOLDOWN_COUNTDOWN_SIZE_FACTOR = 0.5
Stance.COOLDOWN_COUNTDOWN_MIN_SCALE = 0.4
Stance.COOLDOWN_COUNTDOWN_MAX_SCALE = 0.65
Stance.PET_SLOT_FLUX_PAD_H = -2
Stance.PET_SLOT_FLUX_PAD_V = -4
Stance.PET_SLOT_LAYOUT_PAD_H = 2
Stance.PET_SLOT_LAYOUT_PAD_V = 4

local frame
local dummyButton
local started = false
local lastBorderMode

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

function Stance.GetFrame()
	return frame
end

function Stance.UsesFluxPlayerFrame()
	return FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ShouldUseFlux("player")
end

function Stance.ShouldAnchorToPlayerBorder()
	if not Stance.UsesFluxPlayerFrame() then
		return false
	end
	if FluxOptions and FluxOptions.GetStanceBarPlacement and FluxOptions:GetStanceBarPlacement() == 2 then
		return false
	end
	return true
end

function Stance.ApplyBorderChrome()
	if not frame or not FluxBorder or InLockdown() then
		return
	end
	local mode = Stance.ShouldAnchorToPlayerBorder() and "player" or "petslot"
	if lastBorderMode == mode then
		return
	end
	lastBorderMode = mode
	if FluxBorder.RemoveFrom then
		FluxBorder:RemoveFrom(frame)
	end
	if mode == "player" then
		FluxBorder:ApplyTo(frame, Stance.BORDER_PAD_H, Stance.BORDER_PAD_V, Stance.BORDER_PAD_H, Stance.BORDER_PAD_V)
	else
		FluxBorder:ApplyTo(frame, Stance.PET_SLOT_FLUX_PAD_H, Stance.PET_SLOT_FLUX_PAD_V, Stance.PET_SLOT_FLUX_PAD_H, Stance.PET_SLOT_FLUX_PAD_V)
	end
	if FluxBorder.SetClassColor then
		FluxBorder:SetClassColor(frame, 1, true)
	end
end

-- SHAPESHIFTBUTTON1-10 follow visible order (forms + extras after reorder),
-- same as backup FluxStanceBar_Bindings. Leftover keys hit a dummy so Blizzard
-- StanceButton1-10 never receive them.
local MAX_STANCE_BINDS = 10

function Stance.ToggleSlotHidden(key)
	return Stance.SetSlotHidden(key, not Stance.IsSlotHidden(key))
end
Stance.ToggleStanceSlotHidden = Stance.ToggleSlotHidden

function Stance.GetSlotOrderDescriptors()
	local numForms, extras, customs, total = Stance.Catalog()
	local list = {}
	local S = Flux.Shapeshift
	for i = 1, total do
		local key = Stance.MakeSlotKey(i, numForms, extras, customs)
		local label, texture, spellID, removable, actionType, itemID, suppressed
		if i <= numForms then
			local tex, _, _, sid
			if S and S.GetFormInfo then
				tex, _, _, sid = S.GetFormInfo(i)
			end
			texture = tex
			spellID = sid
			if sid and Flux.Spell and Flux.Spell.GetName then
				label = Flux.Spell.GetName(sid)
			end
			label = label or ("Stance " .. tostring(i))
		elseif i <= numForms + #extras then
			local data = extras[i - numForms]
			texture = data and data.texture
			spellID = data and data.spellID
			label = (data and (data.name or data.spellName)) or "?"
		else
			local data = customs[i - numForms - #extras]
			texture = data and data.texture
			spellID = data and data.spellID
			label = (data and (data.name or data.spellName)) or "?"
			removable = true
			actionType = data and data.actionType
			itemID = data and data.itemID
			if data and Stance.ShouldShowCustom and not Stance.ShouldShowCustom(data, numForms, extras) then
				suppressed = true
			end
		end
		list[i] = {
			key = key,
			label = label or "?",
			texture = texture,
			slotIndex = i,
			spellID = spellID,
			hidden = Stance.IsSlotHidden(key),
			removable = removable and true or false,
			actionType = actionType,
			itemID = itemID,
			suppressed = suppressed and true or false,
		}
	end
	return list
end

function Stance.GetSlotOrderEditorRows()
	local numForms, extras, customs, total = Stance.Catalog()
	if total == 0 then
		return {}
	end
	local desc = Stance.GetSlotOrderDescriptors()
	local perm = Stance.BuildPermutation(total, numForms, extras, Stance.GetSavedOrder(), customs)
	local rows = {}
	for i = 1, #perm do
		local idx = perm[i]
		rows[#rows + 1] = desc[idx]
	end
	return rows
end

function Stance.GetCanonicalToShapeshiftButtonBindingIndexMap()
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
	local perm = Stance.BuildPermutation(total, numForms, extras, Stance.GetSavedOrder(), customs)
	local map = {}
	local bindIndex = 0
	for i = 1, #perm do
		local idx = perm[i]
		if shouldShow[idx] then
			bindIndex = bindIndex + 1
			if bindIndex <= 10 then
				map[idx] = bindIndex
			end
		end
	end
	return map
end

function Stance.ReassignBindings()
	if not frame or InLockdown() or not SetOverrideBindingClick then
		if InLockdown() and Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.stance.keys", Stance.ReassignBindings)
		end
		return
	end
	if ClearOverrideBindings then
		ClearOverrideBindings(frame)
	end
	if not GetBindingKey then
		return
	end
	if not dummyButton then
		dummyButton = CreateFrame("Button", "FluxStanceBarDummyButton", frame, "SecureActionButtonTemplate")
		dummyButton:Hide()
		dummyButton:EnableMouse(false)
		dummyButton:SetAttribute("type", nil)
		dummyButton:SetAttribute("action", nil)
	end
	local function BindCommand(bindIndex, clickName, clickButton)
		local command = ("SHAPESHIFTBUTTON%d"):format(bindIndex)
		local keys = { GetBindingKey(command) }
		for k = 1, #keys do
			local key = keys[k]
			if key and key ~= "" then
				if clickButton then
					pcall(SetOverrideBindingClick, frame, false, key, clickName, clickButton)
				else
					pcall(SetOverrideBindingClick, frame, false, key, clickName)
				end
			end
		end
	end
	local visible = Stance.visibleBindWidgets or {}
	local bound = {}
	for i = 1, math.min(#visible, MAX_STANCE_BINDS) do
		local widget = visible[i]
		local name = widget and widget.GetName and widget:GetName()
		local shown = true
		if widget and widget.IsShown then
			shown = widget:IsShown()
		end
		local enabled = true
		if widget and widget.IsEnabled then
			enabled = widget:IsEnabled()
		end
		if name and shown and enabled then
			BindCommand(i, name, "KeyBind")
			bound[i] = true
		end
	end
	local dummyName = dummyButton.GetName and dummyButton:GetName() or "FluxStanceBarDummyButton"
	for i = 1, MAX_STANCE_BINDS do
		if not bound[i] then
			BindCommand(i, dummyName)
		end
	end
end

local function InstallGlobal(f)
	f.GetFrame = function()
		return Stance.GetFrame()
	end
	f.Flux_ReanchorToLayout = function()
		lastBorderMode = nil
		if Stance.Anchor then
			Stance.Anchor()
		end
		if Stance.RequestLayout then
			Stance.RequestLayout("reanchor")
		end
		if Bars.Pet and Bars.Pet.UpdatePosition then
			Bars.Pet.UpdatePosition()
		end
	end
	f.RequestLayout = function(_, reason)
		if Stance.RequestLayout then
			Stance.RequestLayout(reason)
		end
	end
	f.RequestSizeOnly = function()
		if Stance.RequestSizeOnly then
			Stance.RequestSizeOnly()
		end
	end
	f.ReassignBindings = function()
		Stance.ReassignBindings()
	end
	f.ApplySavedSlotOrderAndRefresh = function()
		if Stance.RequestLayout then
			Stance.RequestLayout("order")
		end
	end
	f.UpdateLayout = function()
		if Stance.ApplyLayout then
			Stance.ApplyLayout()
		end
	end
	f.GetSlotOrderDescriptors = function()
		return Stance.GetSlotOrderDescriptors()
	end
	f.GetSlotOrderEditorRows = function()
		return Stance.GetSlotOrderEditorRows()
	end
	f.GetCanonicalToShapeshiftButtonBindingIndexMap = function()
		return Stance.GetCanonicalToShapeshiftButtonBindingIndexMap()
	end
	f.ToggleStanceSlotHidden = function(_, key)
		return Stance.ToggleSlotHidden(key)
	end
	f.RemoveCustomSlot = function(_, key)
		return Stance.RemoveCustomSlot(key)
	end
	f.AddCustomFromCursor = function()
		return Stance.AddCustomFromCursor()
	end
	_G.FluxStanceBar = f
	Stance.shim = f
end

function Stance.Start()
	if started then
		return
	end
	if InLockdown() then
		Defer("bars.stance.start", Stance.Start)
		return
	end
	started = true
	frame = CreateFrame("Frame", "FluxStanceBar", UIParent, "SecureHandlerStateTemplate")
	frame:SetFrameStrata("MEDIUM")
	frame:SetFrameLevel(5)
	frame:EnableMouse(false)
	frame:Hide()
	dummyButton = CreateFrame("Button", "FluxStanceBarDummyButton", frame, "SecureActionButtonTemplate")
	dummyButton:Hide()
	dummyButton:EnableMouse(false)
	dummyButton:SetAttribute("type", nil)
	dummyButton:SetAttribute("action", nil)
	InstallGlobal(frame)
	Stance.ApplyBorderChrome()
	if Stance.Watch and Stance.Watch.Start then
		Stance.Watch.Start()
	end
	if Stance.RequestLayout then
		Stance.RequestLayout("start")
	end
	if Bars.Blizzard and Bars.Blizzard.HideUnusedBars then
		Bars.Blizzard.HideUnusedBars()
	end
end

Flux.Module.Register("StanceBar", {
	clients = { era = true, anniversary = true, classic = true, midnight = true },
	OnEnable = function()
		Stance.Start()
	end,
})
