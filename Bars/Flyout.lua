-- Bars/Flyout.lua — native SpellFlyout on the visible Flux host.
-- SpellFlyout exists on Retail and Classic clients that ship Blizzard flyouts.
-- FlyoutButtonMixin.HasPopup is "SpellFlyout is assigned", not "this slot is a
-- flyout". SetPopup on every empty ActionButtonTemplate leaves the arrow up.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Flyout = {}
Bars.Flyout = Flyout

local function HideArrow(widget)
	if widget.FlyoutArrowContainer then
		widget.FlyoutArrowContainer:Hide()
	end
	if widget.FlyoutArrow then
		widget.FlyoutArrow:Hide()
	end
	if widget.Arrow then
		widget.Arrow:Hide()
	end
end

local function ShowArrow(widget)
	if widget.FlyoutArrowContainer then
		widget.FlyoutArrowContainer:Show()
	elseif widget.FlyoutArrow then
		widget.FlyoutArrow:Show()
	elseif widget.Arrow then
		widget.Arrow:Show()
	end
end

function Flyout.HasSpellFlyout()
	return _G.SpellFlyout ~= nil
end

function Flyout.Hide(widget)
	if widget then
		HideArrow(widget)
	end
end

-- Direction only. Do not SetPopup here: HasPopup() shows mixin.Arrow.
function Flyout.Attach(widget)
	if not widget or not Flyout.HasSpellFlyout() then
		return
	end
	local dir = widget:GetAttribute("flyoutDirection") or "UP"
	if widget.SetPopupDirection then
		pcall(widget.SetPopupDirection, widget, dir)
	else
		widget.popupDirection = dir
	end
end

function Flyout.IsFlyoutSlot(slot)
	if not slot or not GetActionInfo then
		return false
	end
	local ok, isFlyout = pcall(function()
		local actionType = GetActionInfo(slot)
		return actionType == "flyout"
	end)
	return ok and isFlyout == true
end

local function BindPopup(widget)
	local popup = _G.SpellFlyout
	if not popup then
		return
	end
	if widget.SetPopup then
		pcall(widget.SetPopup, widget, popup)
	else
		widget.popup = popup
		ShowArrow(widget)
	end
end

local function UnbindPopup(widget)
	if widget.ClearPopup then
		pcall(widget.ClearPopup, widget)
	else
		widget.popup = nil
	end
	HideArrow(widget)
end

function Flyout.Update(host)
	local widget = host and host.widget
	if not widget then
		return
	end
	if not Flyout.HasSpellFlyout() then
		HideArrow(widget)
		return
	end
	local slot = host.slot or (widget.GetAttribute and tonumber(widget:GetAttribute("action")))
	local lockdown = InCombatLockdown and InCombatLockdown()
	local ok, isFlyout = pcall(function()
		return Flyout.IsFlyoutSlot(slot)
	end)
	if not ok then
		return
	end
	if isFlyout then
		if not lockdown then
			if not widget:GetAttribute("flyoutDirection") then
				widget:SetAttribute("flyoutDirection", "UP")
			end
			Flyout.Attach(widget)
			BindPopup(widget)
			if widget.UpdateFlyout then
				pcall(widget.UpdateFlyout, widget)
			end
		end
		ShowArrow(widget)
	else
		HideArrow(widget)
		if not lockdown then
			UnbindPopup(widget)
		end
	end
end
