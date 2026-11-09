-- ExtraButtonSystem/FlyoutEngine/Init.lua — UFO-style secure flyout engine.
-- Combat-safe open/close. Player catalog and auto-wiring stay unused.
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS

local Flyout = EBS.Flyout or {}
EBS.Flyout = Flyout
Flux.Flyout = Flyout

Flyout.MAX_BUTTONS = 36
Flyout.ACTION_TYPE = "fluxflyout"
Flyout.OPENER_TYPE = "FLUXFLYOUT_OPENER"
Flyout.OPENER_ATTR = "_FLUXFLYOUT_OPENER"
Flyout.LAYOUT_ATTR = "_FLUXFLYOUT_LAYOUT"
Flyout.SLOT_ATTR = "FLUX_FLYOUT_SLOT"
Flyout.DUMMY_NAME = "FluxEBSFlyoutDummy"

-- UFO Germ clickers (OPEN only this pass).
Flyout.ClickBehavior = {
	OPEN = "OPEN",
	PRIME_BTN = "PRIME_BTN",
	RANDOM_BTN = "RANDOM_BTN",
	CYCLE_ALL_BTNS = "CYCLE_ALL_BTNS",
}

Flyout.defs = Flyout.defs or {}
Flyout.attached = Flyout.attached or {}
Flyout.byId = Flyout.byId or {}
Flyout._dirty = Flyout._dirty or {}
Flyout._menuSeq = Flyout._menuSeq or 0
Flyout._overlaySeq = Flyout._overlaySeq or 0

function Flyout.InLockdown()
	if Flux.Combat and Flux.Combat.InLockdown then
		return Flux.Combat.InLockdown()
	end
	return InCombatLockdown and InCombatLockdown() and true or false
end

function Flyout.Defer(key, fn)
	if type(fn) ~= "function" then
		return
	end
	if Flyout.InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer(key, fn)
		end
		return false
	end
	fn()
	return true
end

function Flyout.Dummy()
	return _G[Flyout.DUMMY_NAME]
end

function Flyout.EnsureDummy()
	local dummy = Flyout.Dummy()
	if not dummy then
		if Flyout.InLockdown() then
			return nil
		end
		dummy = CreateFrame("Frame", Flyout.DUMMY_NAME, UIParent, "SecureFrameTemplate")
		dummy:Hide()
		if SecureHandler_OnLoad then
			pcall(SecureHandler_OnLoad, dummy)
		end
	end
	if dummy.SetAttribute and not Flyout.InLockdown() then
		if dummy:GetAttribute("doCloseOnClick") == nil then
			dummy:SetAttribute("doCloseOnClick", true)
		end
		if dummy:GetAttribute("FLYOUT_MAX_LEN") == nil then
			dummy:SetAttribute("FLYOUT_MAX_LEN", 12)
		end
	end
	return dummy
end

function Flyout.MouseIndex(button)
	if button == "RightButton" then
		return 2
	end
	if button == "MiddleButton" then
		return 3
	end
	if button == "Button4" then
		return 4
	end
	if button == "Button5" then
		return 5
	end
	return 1
end

function Flyout.DirOk(dir)
	if dir == "UP" or dir == "DOWN" or dir == "LEFT" or dir == "RIGHT" then
		return dir
	end
	return "UP"
end

-- popupPoint, hostPoint, x, y
function Flyout.DirPoints(dir)
	dir = Flyout.DirOk(dir)
	if dir == "DOWN" then
		return "TOP", "BOTTOM", 0, -2
	end
	if dir == "LEFT" then
		return "RIGHT", "LEFT", -2, 0
	end
	if dir == "RIGHT" then
		return "LEFT", "RIGHT", 2, 0
	end
	return "BOTTOM", "TOP", 0, 2
end

function Flyout.HostOf(widget)
	if not widget then
		return nil
	end
	return Flyout.attached[widget]
end

function Flyout.GetPopup(widget)
	local host = Flyout.HostOf(widget)
	return host and host.popup or nil
end

function Flyout.GetArrow(widget)
	local host = Flyout.HostOf(widget)
	if host and host.arrow then
		return host.arrow
	end
	return widget and widget.FluxFlyoutArrow or nil
end

function Flyout.IsOpen(widget)
	local popup = Flyout.GetPopup(widget)
	return popup and popup:IsShown() and true or false
end

function Flyout.OnDependentsLayoutChanged()
	if Flyout.InLockdown() then
		Flyout.Defer("flyout.squeeze", Flyout.OnDependentsLayoutChanged)
		return
	end
	for widget, rec in pairs(Flyout.attached or {}) do
		if widget and rec and rec.popup and rec.popup.IsShown and rec.popup:IsShown() then
			if Flyout.Popup and Flyout.Popup.Layout then
				Flyout.Popup.Layout(widget, rec.buttons, rec.opts)
			end
		end
	end
	if Flyout.Arrow and Flyout.Arrow.RefreshAll then
		Flyout.Arrow.RefreshAll()
	end
end
