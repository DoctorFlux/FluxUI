-- Bars/BindingMode.lua — LibKeyBound hover-to-bind for the strip, Extra, pet, and stance.
-- Lean adapter: not a port of the old ghost-bar / corner-badge Binding Mode.
local addonName, ns = ...
local Flux = ns.Flux

FluxBindingMode = FluxBindingMode or {}
local BM = FluxBindingMode
_G.FluxBindingMode = BM

local KeyBound = LibStub and LibStub("LibKeyBound-1.0", true)
if not KeyBound then
	function BM:ShouldForceShowAllExtraSlots()
		return false
	end
	function BM:IsActive()
		return false
	end
	function BM:RegisterButton()
	end
	function BM:Activate()
	end
	function BM:Deactivate()
	end
	return
end

BM._active = false
BM._registeredButtons = BM._registeredButtons or {}

local function InLockdown()
	return InCombatLockdown and InCombatLockdown()
end

local function After(delay, fn)
	if C_Timer and C_Timer.After then
		C_Timer.After(delay, fn)
	else
		fn()
	end
end

local function ResetBinderTextLayout(bindFrame)
	if not bindFrame or not bindFrame.text then
		return
	end
	bindFrame.text:ClearAllPoints()
	bindFrame.text:SetAllPoints(bindFrame)
end

local function FluxBinderKeyTextToMainRowIfMinirow(keyBoundSelf, button)
	local bindFrame = keyBoundSelf.frame
	if not bindFrame or not bindFrame.text or not button or not button.GetHotkey then
		return
	end
	local name = button.GetName and button:GetName()
	if not name then
		return
	end
	local col = name:match("^FluxActionStripSec(%d+)$") or name:match("^FluxActionStripTert(%d+)$")
	if not col then
		return
	end
	local mainBtn = _G["FluxActionStripButton" .. col]
	if not mainBtn then
		return
	end
	bindFrame.text:ClearAllPoints()
	bindFrame.text:SetPoint("CENTER", mainBtn, "CENTER")
	bindFrame.text:SetFontObject("GameFontNormalLarge")
	bindFrame.text:SetText(button:GetHotkey())
	if bindFrame.text:GetStringWidth() > mainBtn:GetWidth() then
		bindFrame.text:SetFontObject("GameFontNormal")
	end
end

local function EnsureDim(button)
	if not button then
		return nil
	end
	local t = button._fluxBindingDim
	if not t then
		t = button:CreateTexture(nil, "OVERLAY", nil, 7)
		t:SetColorTexture(0, 0, 0, 0.5)
		t:SetAllPoints(button)
		t:Hide()
		button._fluxBindingDim = t
	end
	return t
end

local function ClearColumnDim()
	local Bars = Flux and Flux.Bars
	local n = (Bars and Bars.NUM_COLUMNS) or 19
	for i = 1, n do
		local faces = {
			_G["FluxActionStripButton" .. i],
			_G["FluxActionStripSec" .. i],
			_G["FluxActionStripTert" .. i],
		}
		for j = 1, #faces do
			local b = faces[j]
			if b and b._fluxBindingDim then
				b._fluxBindingDim:Hide()
			end
		end
	end
end

local function UpdateColumnDim(focusedButton)
	if not KeyBound or not KeyBound.IsShown or not KeyBound:IsShown() or InLockdown() or not focusedButton then
		ClearColumnDim()
		return
	end
	local name = focusedButton.GetName and focusedButton:GetName()
	if not name then
		ClearColumnDim()
		return
	end
	local col = name:match("^FluxActionStripButton(%d+)$")
		or name:match("^FluxActionStripSec(%d+)$")
		or name:match("^FluxActionStripTert(%d+)$")
	if not col then
		ClearColumnDim()
		return
	end
	col = tonumber(col)
	ClearColumnDim()
	local faces = {
		_G["FluxActionStripButton" .. col],
		_G["FluxActionStripSec" .. col],
		_G["FluxActionStripTert" .. col],
	}
	for i = 1, #faces do
		local b = faces[i]
		if b and b ~= focusedButton and b.IsShown and b:IsShown() then
			local dim = EnsureDim(b)
			if dim then
				dim:Show()
			end
		end
	end
end

do
	local origSet = KeyBound.Set
	function KeyBound:Set(button)
		local bindFrame = self.frame
		if bindFrame and bindFrame.text then
			ResetBinderTextLayout(bindFrame)
		end
		origSet(self, button)
		if button and self:IsShown() and not InLockdown() then
			FluxBinderKeyTextToMainRowIfMinirow(self, button)
		end
		UpdateColumnDim(button)
	end
end

do
	local Binder = KeyBound.Binder
	if Binder and Binder.SetKey then
		local origBinderSetKey = Binder.SetKey
		function Binder:SetKey(button, key)
			local name = button and button.GetName and button:GetName()
			if name and type(key) == "string" then
				local strip = name:find("^FluxActionStrip") or name:find("^FluxPetButton")
				if strip and (key:find("SHIFT%-") or key:find("CTRL%-")) then
					if UIErrorsFrame and UIErrorsFrame.AddMessage then
						UIErrorsFrame:AddMessage("Action bar bindings cannot use Shift or Ctrl modifiers.", 1, 0.82, 0, 1, UIERRORS_HOLD_TIME)
					end
					KeyBound:Set(button)
					return
				end
			end
			return origBinderSetKey(self, button, key)
		end
	end
	if Binder and Binder.OnEnter then
		local origBinderOnEnter = Binder.OnEnter
		function Binder:OnEnter(...)
			if FluxTooltipGuard and FluxTooltipGuard.Reset then
				FluxTooltipGuard.Reset(GameTooltip)
			end
			return origBinderOnEnter(self, ...)
		end
	end
end

function BM:ShouldForceShowAllExtraSlots()
	return self._active == true
end

function BM:IsActive()
	return BM._active
end

local function AttachKeyboundMethods(widget, bindingName)
	if not widget or not bindingName then
		return
	end
	if widget._fluxBindingName then
		widget._fluxBindingName = bindingName
		BM._registeredButtons[widget] = bindingName
		return
	end
	widget._fluxBindingName = bindingName

	function widget:GetHotkey()
		local key = GetBindingKey(self._fluxBindingName)
		if key then
			return KeyBound:ToShortKey(key) or key
		end
		return ""
	end

	function widget:GetBindings()
		local keys
		for i = 1, select("#", GetBindingKey(self._fluxBindingName)) do
			local hotKey = select(i, GetBindingKey(self._fluxBindingName))
			if keys then
				keys = keys .. ", " .. GetBindingText(hotKey)
			else
				keys = GetBindingText(hotKey)
			end
		end
		return keys
	end

	function widget:SetKey(key)
		SetBinding(key, self._fluxBindingName)
	end

	function widget:ClearBindings()
		while GetBindingKey(self._fluxBindingName) do
			SetBinding(GetBindingKey(self._fluxBindingName), nil)
		end
	end

	function widget:GetActionName()
		local label = _G["BINDING_NAME_" .. self._fluxBindingName]
		if label then
			return label
		end
		return self._fluxBindingName
	end

	widget:HookScript("OnEnter", function(self)
		if KeyBound and KeyBound:IsShown() then
			KeyBound:Set(self)
		end
	end)

	BM._registeredButtons[widget] = bindingName
end

function BM:RegisterButton(widget, bindingName)
	AttachKeyboundMethods(widget, bindingName)
end

local function WidgetFrom(mod, field)
	if not mod then
		return nil
	end
	local btn = mod[field]
	if not btn then
		return nil
	end
	return btn.Widget or btn
end

local function RegisterStrip()
	local Bars = Flux and Flux.Bars
	local Hosts = Bars and Bars.Hosts
	local n = (Bars and Bars.NUM_COLUMNS) or 19
	for i = 1, n do
		local cmd
		if Hosts and Hosts.BindingCommand then
			cmd = Hosts.BindingCommand(i)
		elseif i <= 12 then
			cmd = "ACTIONBUTTON" .. i
		end
		if cmd then
			AttachKeyboundMethods(_G["FluxActionStripButton" .. i], cmd)
			AttachKeyboundMethods(_G["FluxActionStripSec" .. i], cmd)
			AttachKeyboundMethods(_G["FluxActionStripTert" .. i], cmd)
		end
	end
end

local EXTRA_MAP = {
	{ module = "FluxCombatHealPotion", field = "Button", binding = "FLUXCOMBAT_HEALPOT" },
	{ module = "FluxCombatBandage", field = "Button", binding = "FLUXCOMBAT_BANDAGE" },
	{ module = "FluxCombatHealthstone", field = "Button", binding = "FLUXCOMBAT_HEALTHSTONE" },
	{ module = "FluxCombatManaPotion", field = "Button", binding = "FLUXCOMBAT_MANAPOT" },
	{ module = "FluxCombatManaGem", field = "Button", binding = "FLUXCOMBAT_MANAGEM" },
	{ module = "FluxCombatAssistedCombat", field = "LABButton", binding = "FLUX_ASSISTED_COMBAT" },
	{ module = "FluxCombatAssistedCombat", field = "Button", binding = "FLUX_ASSISTED_COMBAT" },
	{ module = "FluxNCMount", field = "_button", binding = "FLUXGRIDSMARTMOUNT" },
	{ module = "FluxNCHearthstone", field = "_button", binding = "FLUXGRIDHEARTH" },
	{ module = "FluxNCFood", field = "_foodButton", binding = "FLUXGRID_FOOD_OR_RECUP" },
	{ module = "FluxNCFood", field = "Button", binding = "FLUXGRID_FOOD_OR_RECUP" },
	{ module = "FluxNCWater", field = "_waterButton", binding = "FLUXGRID_WATER_OR_COMBINED" },
	{ module = "FluxNCWater", field = "Button", binding = "FLUXGRID_WATER_OR_COMBINED" },
	{ module = "FluxNCTeleportPortal", field = "_button", binding = "FLUXCLASS_TELEPORT" },
	{ module = "FluxNCConsumables", field = "_button", binding = "FLUXGRID_CONSUMABLES" },
}

local function RegisterExtra()
	for i = 1, #EXTRA_MAP do
		local entry = EXTRA_MAP[i]
		local widget = WidgetFrom(_G[entry.module], entry.field)
		if widget and widget.GetName and widget:GetName() then
			AttachKeyboundMethods(widget, entry.binding)
		end
	end

	local Action = Flux and Flux.EBS and Flux.EBS.Action
	if Action and Action.GetAssistantButton then
		local btn = Action.GetAssistantButton()
		if btn and btn.Widget then
			AttachKeyboundMethods(btn.Widget, "FLUX_ASSISTED_COMBAT")
		end
	end

	if FluxNCUtilitySlotsManager and FluxNCUtilitySlotsManager.buttons then
		for slotIndex = 1, 4 do
			local btn = FluxNCUtilitySlotsManager.buttons[slotIndex]
			local widget = btn and (btn.Widget or btn)
			if widget and widget.GetName and widget:GetName() then
				AttachKeyboundMethods(widget, "FLUXSPELLBOOKSLOT" .. slotIndex)
			end
		end
	end

	if FluxTrinketMenu and FluxTrinketMenu.Buttons then
		for index = 0, 1 do
			local btn = FluxTrinketMenu.Buttons[index]
			local widget = btn and (btn.Widget or btn)
			if widget and widget.GetName and widget:GetName() then
				AttachKeyboundMethods(widget, "FLUXTRINKET" .. (index + 1))
			end
		end
	end

	local list = Flux and Flux.EBS and Flux.EBS.buttons
	if list then
		for i = 1, #list do
			local btn = list[i]
			local widget = btn and btn.Widget
			local name = widget and widget.GetName and widget:GetName() or ""
			if widget and name ~= "" and not name:find("^FluxPetButton") and not name:find("^FluxStance") then
				local binding = btn.HotkeyBinding
				if btn.IsAssistedCombat then
					binding = "FLUX_ASSISTED_COMBAT"
				end
				if binding then
					AttachKeyboundMethods(widget, binding)
				end
			end
		end
	end
end

local function RegisterStance()
	local Stance = Flux and Flux.Bars and Flux.Bars.Stance
	local visible = Stance and Stance.visibleBindWidgets
	if visible and #visible > 0 then
		for i = 1, math.min(#visible, 10) do
			local widget = visible[i]
			if widget and widget.GetName and widget:GetName() then
				AttachKeyboundMethods(widget, "SHAPESHIFTBUTTON" .. i)
			end
		end
		return
	end
	local bar = _G.FluxStanceBar
	local buttons = bar and bar.buttons
	if not buttons then
		return
	end
	for i = 1, math.min(#buttons, 10) do
		local btn = buttons[i]
		if btn and btn.GetName and btn:GetName() then
			AttachKeyboundMethods(btn, "SHAPESHIFTBUTTON" .. i)
		end
	end
end

local function RegisterPet()
	local Pet = Flux and Flux.Bars and Flux.Bars.Pet
	local btns = Pet and Pet.GetAllButtons and Pet.GetAllButtons()
	if not btns then
		return
	end
	for i = 1, 10 do
		local btn = btns[i]
		local widget = btn and (btn.Widget or btn)
		if widget and widget.GetName and widget:GetName() then
			AttachKeyboundMethods(widget, "BONUSACTIONBUTTON" .. i)
		end
	end
end

local function RegisterAll()
	RegisterStrip()
	RegisterExtra()
	RegisterStance()
	RegisterPet()
end

local function RefreshExtraAfterChange()
	if FluxExtraButtonVisibility and FluxExtraButtonVisibility.NotifyChanged then
		FluxExtraButtonVisibility.NotifyChanged()
	end
	RegisterAll()
end

function BM:SetBindingModeActive(active)
	active = not not active
	BM._active = active
	local Bars = Flux and Flux.Bars
	if Bars and Bars.Layout and Bars.Layout.SetBindingMode then
		Bars.Layout.SetBindingMode(active)
	end
	if Bars and Bars.Pet and Bars.Pet.SetBindingModeFrameOverride then
		Bars.Pet.SetBindingModeFrameOverride(active)
	else
		local pet = _G.FluxPetBar
		if pet and pet.SetBindingModeFrameOverride then
			pet:SetBindingModeFrameOverride(active)
		end
	end
	if not active then
		ClearColumnDim()
	end
	After(0, function()
		RefreshExtraAfterChange()
	end)
end

local function HookReopenOnDialogHide()
	local dialog = _G.KeyboundDialog
	if not dialog or dialog._fluxReopenHooked then
		return
	end
	dialog._fluxReopenHooked = true
	dialog:HookScript("OnHide", function()
		After(0.05, function()
			if FluxOptions and FluxOptions.OpenToActionBarsBindingsTab then
				FluxOptions:OpenToActionBarsBindingsTab()
			elseif FluxOptions and FluxOptions.OpenToActionBarsTab then
				FluxOptions:OpenToActionBarsTab()
			end
		end)
	end)
end

local function ForceAccountBindingSetInDialog()
	After(0, function()
		local chk = _G.KeyboundDialogCheck
		if chk and chk.SetChecked then
			chk:SetChecked(false)
		end
		if LoadBindings then
			LoadBindings(1)
		end
	end)
end

function BM:Activate()
	if InLockdown() then
		return
	end
	if BM._active then
		return
	end
	RegisterAll()
	if FluxTooltipGuard and FluxTooltipGuard.Reset then
		FluxTooltipGuard.Reset(GameTooltip)
	end
	if GameTooltip and GameTooltip.Hide then
		pcall(function()
			GameTooltip:Hide()
		end)
	end
	BM:SetBindingModeActive(true)
	KeyBound:Activate()
	if KeyBound.frame and KeyBound.Binder and KeyBound.Binder.OnEnter then
		local Binder = KeyBound.Binder
		KeyBound.frame:SetScript("OnEnter", function(self)
			return Binder.OnEnter(self)
		end)
	end
	HookReopenOnDialogHide()
end

function BM:Deactivate()
	if KeyBound.Deactivate then
		KeyBound:Deactivate()
	end
	if FluxTooltipGuard and FluxTooltipGuard.Reset then
		FluxTooltipGuard.Reset(GameTooltip)
	end
	if GameTooltip and GameTooltip.Hide then
		GameTooltip:Hide()
	end
	if BM._active then
		BM:SetBindingModeActive(false)
	end
end

function BM:Toggle()
	if BM._active then
		BM:Deactivate()
	else
		BM:Activate()
	end
end

KeyBound:RegisterCallback("LIBKEYBOUND_ENABLED", function()
	if not BM._active then
		RegisterAll()
		BM:SetBindingModeActive(true)
	end
	ForceAccountBindingSetInDialog()
end)

KeyBound:RegisterCallback("LIBKEYBOUND_DISABLED", function()
	if BM._active then
		BM:SetBindingModeActive(false)
	end
end)

local Stance = Flux and Flux.Bars and Flux.Bars.Stance
if Stance and Stance.ApplyLayout and not Stance._fluxBindingModeHooked then
	Stance._fluxBindingModeHooked = true
	hooksecurefunc(Stance, "ApplyLayout", function()
		if BM._active then
			After(0.1, RegisterStance)
		end
	end)
end
