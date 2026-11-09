-- Bars/Stance/Forms.lua — hidden StanceButton donors + Extra Button form faces.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Stance = Bars.Stance or {}
Bars.Stance = Stance

local donors = {}
local formButtons = {}
local extraButtons = {}
local extraSeq = 0
local extraNames = {}

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

function Stance.GetDonor(index)
	return donors[index]
end

function Stance.EnsureDonor(index, parent)
	if donors[index] and donors[index]._fluxDonorReady then
		return donors[index]
	end
	if InLockdown() then
		return nil
	end
	local donor = donors[index] or _G["FluxStanceDonor" .. index]
	local ok = pcall(function()
		donor = donor or CreateFrame("CheckButton", "FluxStanceDonor" .. index, parent, "StanceButtonTemplate")
	end)
	if not ok or not donor then
		return nil
	end
	donors[index] = donor
	donor:SetID(index)
	donor:SetSize(1, 1)
	donor:Hide()
	donor:EnableMouse(false)
	if donor.HotKey then
		donor.HotKey:Hide()
	end
	donor._fluxDonorReady = true
	return donor
end

function Stance.GetFormButton(index)
	return formButtons[index]
end

function Stance.GetExtraButton(key)
	return extraButtons[key]
end

function Stance.EnsureFormButton(index, parent, size)
	local btn = formButtons[index]
	if btn and btn._fluxFormReady then
		return btn
	end
	if InLockdown() then
		return nil
	end
	local EBS = Flux.EBS
	if not (EBS and EBS.Widget) then
		return nil
	end
	local donor = Stance.EnsureDonor(index, parent)
	if not donor then return nil end
	local native = (Flux.Bars and Flux.Bars.CONFIG and Flux.Bars.CONFIG.buttonSize) or 44
	btn = btn or EBS.Widget.Create(parent, {
		name = "FluxStanceFormButton" .. index,
		size = native,
		showBorder = true,
		tooltip = true,
		macroText = false,
		locked = true,
	})
	if not btn then
		return nil
	end
	formButtons[index] = btn
	btn.locked = true
	btn.categoryScope = "character"
	btn.ShapeshiftDonor = donor
	btn.slotKey = "stance:" .. tostring(index)
	if EBS.Action and EBS.Action.SetAction then
		EBS.Action.SetAction(btn, "shapeshift", index)
	end
	if EBS.Style and EBS.Style.Apply then
		EBS.Style.Apply(btn, "character")
	end
	local G = Flux.ButtonFX and Flux.ButtonFX.Glow
	if G and btn.Widget and G.NotifySAO then
		G.NotifySAO(btn.Widget)
	end
	btn._fluxFormReady = true
	return btn
end

function Stance.EnsureExtraButton(key, parent, size, data)
	local btn = extraButtons[key]
	if not btn then
		if InLockdown() then
			return nil
		end
		local EBS = Flux.EBS
		if not (EBS and EBS.Widget) then
			return nil
		end
		if not extraNames[key] then
			extraSeq = extraSeq + 1
			extraNames[key] = "FluxStanceExtraButton" .. extraSeq
		end
		local native = (Flux.Bars and Flux.Bars.CONFIG and Flux.Bars.CONFIG.buttonSize) or 44
		btn = EBS.Widget.Create(parent, {
			name = extraNames[key],
			size = native,
			showBorder = true,
			tooltip = true,
			macroText = false,
			locked = true,
		})
		if not btn then
			return nil
		end
		btn.locked = true
		btn.categoryScope = "character"
		extraButtons[key] = btn
	end
	btn.slotKey = key
	btn.spellData = data
	btn._fluxExactSpell = (data and data.custom and (data.actionType or data.type) == "spell") and true or nil
	local EBS = Flux.EBS
	if data and data.custom and data.actionType and EBS and EBS.Action and EBS.Action.SetAction then
		local value = data.actionValue
		if data.actionType == "macro" then
			value = { name = data.name or data.id }
		end
		EBS.Action.SetAction(btn, data.actionType, value)
	elseif data and data.spellID and EBS and EBS.Action and EBS.Action.SetAction then
		EBS.Action.SetAction(btn, "spell", data.spellID)
	end
	if EBS and EBS.Style and EBS.Style.Apply then
		EBS.Style.Apply(btn, "character")
	end
	if Stance.EnsureAuraCountdown then
		Stance.EnsureAuraCountdown(btn)
	end
	local G = Flux.ButtonFX and Flux.ButtonFX.Glow
	if G and btn.Widget and G.NotifySAO then
		G.NotifySAO(btn.Widget)
	end
	return btn
end

function Stance.AttachReorderControls(btn)
	local widget = btn and btn.Widget
	if not widget or widget._fluxStanceReorderWired then
		return
	end
	widget._fluxStanceReorderWired = true
	-- Left-drag reorder only. Right-click must not hide/remove slots.
	widget:HookScript("OnDragStart", function()
		if not InLockdown() then
			Stance._dragKey = btn.slotKey
		end
	end)
	widget:HookScript("OnReceiveDrag", function()
		local from = Stance._dragKey
		Stance._dragKey = nil
		if from and btn.slotKey and from ~= btn.slotKey and Stance.ReorderKey then
			Stance.ReorderKey(from, btn.slotKey)
		end
	end)
	widget:HookScript("OnDragStop", function()
		local from = Stance._dragKey
		Stance._dragKey = nil
		if not from or InLockdown() or not Stance.ReorderKey then
			return
		end
		local mouse = GetMouseFocus and GetMouseFocus()
		if not mouse and GetMouseFoci then
			local foci = GetMouseFoci()
			mouse = foci and foci[1]
		end
		if not mouse then
			return
		end
		Stance.ForEachPooled(function(other)
			local w = other and other.Widget
			if not w or not other.slotKey or other.slotKey == from then
				return
			end
			if mouse == w or (mouse.GetParent and mouse:GetParent() == w) then
				Stance.ReorderKey(from, other.slotKey)
			end
		end)
	end)
end

-- Keep the old name as an alias so leftover calls still wire reorder only.
function Stance.AttachHideControls(btn)
	return Stance.AttachReorderControls(btn)
end

function Stance.ForEachPooled(fn)
	for _, btn in pairs(formButtons) do
		fn(btn)
	end
	for _, btn in pairs(extraButtons) do
		fn(btn)
	end
end

local QueueArmorPoll

function Stance.TagFormArmor(btn, index)
	if not btn then
		return
	end
	index = index or btn.ShapeshiftIndex or btn.ActionValue
	local S = Flux.Shapeshift
	local spellID
	if S and S.GetFormInfo and index then
		local _, _, _, sid = S.GetFormInfo(index)
		spellID = sid
	end
	if spellID then
		btn.SpellId = tonumber(spellID) or btn.SpellId
	end
	if Stance.IsMageArmorSpell and Stance.IsMageArmorSpell(btn.SpellId) then
		btn._fluxStanceMageArmorForm = true
		if Stance.EnsureAuraCountdown then
			Stance.EnsureAuraCountdown(btn)
		end
		return
	end
	if btn._fluxStanceMageArmorForm then
		btn._fluxStanceMageArmorForm = nil
		btn.IconOverrideTexture = nil
		btn.StanceActiveVisual = nil
		btn.FluxStanceManagedCooldown = nil
		btn.StanceBuffCooldownStart = nil
		btn.StanceBuffCooldownDuration = nil
		btn.StanceBuffDurationObject = nil
		btn.StanceBuffExpirationTime = nil
		btn.StanceBuffTimeMod = nil
		if Stance.SyncAuraCountdown then
			Stance.SyncAuraCountdown(btn)
		end
	end
end

function Stance.PaintFormVisuals()
	local paint = Flux.EBS and Flux.EBS.Paint
	if not paint then
		return
	end
	if Stance.BeginExtraVisualPass then
		Stance.BeginExtraVisualPass()
	end
	local needsArmorPoll = false
	for _, btn in pairs(formButtons) do
		if btn and btn.Widget and btn.Widget:IsShown() then
			if Stance.TagFormArmor then
				Stance.TagFormArmor(btn)
			end
			if btn._fluxStanceMageArmorForm and Stance.ApplyExtraActiveVisual then
				Stance.ApplyExtraActiveVisual(btn)
			end
			if btn._fluxStanceMageArmorForm and (btn.FluxStanceManagedCooldown or btn.StanceActiveVisual) then
				needsArmorPoll = true
			end
			paint.Update(btn)
		end
	end
	if needsArmorPoll then
		QueueArmorPoll()
	end
end

local function ArmorPollSig()
	if Stance.ArmorPollSignature then
		return Stance.ArmorPollSignature()
	end
	local active = Stance.GetActiveMageArmor and Stance.GetActiveMageArmor()
	if not active then
		return ""
	end
	return "live"
end

QueueArmorPoll = function()
	if Stance._armorPollQueued or not (C_Timer and C_Timer.After) then
		return
	end
	Stance._armorPollQueued = true
	C_Timer.After(0.25, function()
		Stance._armorPollQueued = false
		local sig = ArmorPollSig()
		local prev = Stance._armorPollSig or ""
		if sig ~= prev then
			Stance._armorPollSig = sig
			if Stance.RequestExtrasVisual then
				Stance.RequestExtrasVisual()
			end
			if Stance.RequestFormsVisual then
				Stance.RequestFormsVisual()
			end
		elseif sig ~= "" then
			QueueArmorPoll()
		end
	end)
end

function Stance.PaintExtraVisuals()
	local paint = Flux.EBS and Flux.EBS.Paint
	if not paint then
		return
	end
	if Stance.BeginExtraVisualPass then
		Stance.BeginExtraVisualPass()
	end
	local needsArmorPoll = false
	for _, btn in pairs(extraButtons) do
		if btn and btn.Widget and btn.Widget:IsShown() then
			if Stance.ApplyExtraActiveVisual then
				Stance.ApplyExtraActiveVisual(btn)
			end
			if btn.spellData and (btn.spellData.isMageArmor or btn.spellData.custom) and (btn.FluxStanceManagedCooldown or btn.StanceActiveVisual) then
				needsArmorPoll = true
			end
			paint.Update(btn)
		end
	end
	Stance._armorPollSig = ArmorPollSig()
	-- Buff cancel / expiry can miss a UNIT_AURA. Poll while armor is actually up.
	if needsArmorPoll then
		QueueArmorPoll()
	end
end
