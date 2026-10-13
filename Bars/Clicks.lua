-- Bars/Clicks.lua — click-route keys as KeyBind; mouse vs key split is ButtonFX.Click.
--
-- Mouse: wrap swallows down; up falls through to the hold-release path, which
-- reads typerelease. The wrap never writes useOnKeyDown or pressAndHoldAction.
-- Key: SetOverrideBindingClick(..., "KeyBind") onto the visible host.
-- Overlay slots: type=macro+macrotext on the visible host, or type=click when
-- the body must run on a hidden FluxSlotClick_<slot>.
-- ACTIONBUTTON* onto a per-slot hidden name is forbidden in combat.
-- Shift/Ctrl remap the same physical key, so ACTIONBUTTONn cannot target the
-- visible host; every strip key is SetOverrideBindingClick onto that host.
-- There is no override for "SHIFT-1": an unbound modified key falls through to
-- the bare key, and the modifier then picks the slot at press time through the
-- host's shift-action* / ctrl-action* attributes (see Bars/State.lua).
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Clicks = {}
Bars.Clicks = Clicks

local lastKeySig
local started = false

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

function Clicks.UseKeyDown()
	if Flux.CVar and Flux.CVar.GetBool then
		return Flux.CVar.GetBool("ActionButtonUseKeyDown") and true or false
	end
	if GetCVarBool then
		return GetCVarBool("ActionButtonUseKeyDown") and true or false
	end
	return false
end

function Clicks.Prepare(widget)
	if not widget or InLockdown() then
		return
	end
	local FX = Flux.ButtonFX
	if FX and FX.Click and FX.Click.Apply then
		FX.Click.Apply(widget)
	else
		widget:RegisterForClicks("AnyUp")
	end
	if widget.EnableMouse then
		widget:EnableMouse(true)
	end
end

function Clicks.ApplyRegistration()
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.clicks", Clicks.ApplyRegistration)
		end
		return
	end
	Bars.ForEachHost(function(host)
		if host.widget then
			Clicks.Prepare(host.widget)
		end
	end)
end

local function SlotIsEmpower(slot)
	if not slot or not HasAction or not HasAction(slot) then
		return false
	end
	if not GetActionInfo then
		return false
	end
	local ok, actionType, id, subType = pcall(GetActionInfo, slot)
	if not ok or not actionType then
		return false
	end
	if not (C_Spell and C_Spell.IsPressHoldReleaseSpell) then
		return false
	end
	local spellID
	if actionType == "spell" then
		spellID = id
	elseif actionType == "macro" and subType == "spell" then
		spellID = id
	end
	if not spellID then
		return false
	end
	if Flux.Secrets and Flux.Secrets.IsSecretValue and Flux.Secrets.IsSecretValue(spellID) then
		return false
	end
	local okPH, isPH = pcall(C_Spell.IsPressHoldReleaseSpell, spellID)
	return okPH and isPH and true or false
end

local function WrapClicks()
	local FX = Flux.ButtonFX
	return not FX or not FX.Click or not FX.Click.UsesWrap or FX.Click.UsesWrap()
end

local function EnsureKeyer(widget, column)
	local name = "FluxActionStripKey" .. tostring(column)
	local keyer = _G[name]
	if not keyer then
		local ok, created = pcall(CreateFrame, "Button", name, widget, "SecureActionButtonTemplate")
		if not ok or not created then
			return nil
		end
		keyer = created
		keyer:Hide()
		keyer:SetSize(1, 1)
		if keyer.EnableMouse then
			keyer:EnableMouse(false)
		end
		if keyer.SetID then
			keyer:SetID(0)
		end
		keyer:RegisterForClicks("AnyDown")
		keyer:SetAttribute("useOnKeyDown", true)
		keyer:SetAttribute("pressAndHoldAction", false)
		-- useparent-<name> recurses with the same modifier prefix and button
		-- suffix, so the host's shift-action* / shift-type* / shift-macrotext*
		-- twins resolve straight through this proxy.
		keyer:SetAttribute("useparent-type", true)
		keyer:SetAttribute("useparent-typerelease", true)
		keyer:SetAttribute("useparent-action", true)
		keyer:SetAttribute("useparent-macrotext", true)
		keyer:SetAttribute("useparent-clickbutton", true)
		keyer:SetAttribute("useparent-unit", true)
		keyer:SetAttribute("useparent-checkmouseovercast", true)
	elseif widget and keyer.SetParent then
		keyer:SetParent(widget)
	end
	local PP = ns.FluxBindingPushPress or _G.FluxBindingPushPress
	if PP and PP.HookKeyer then
		PP.HookKeyer(keyer, column)
	end
	return keyer
end

--- OOC only. Combat page swaps use the restricted ChildUpdate trailer.
function Clicks.ReassertEmpower()
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.empower", Clicks.ReassertEmpower)
		end
		return
	end
	Bars.ForEachHost(function(host)
		local widget = host.widget
		if not widget then
			return
		end
		local slot = tonumber(widget:GetAttribute("action")) or host.slot
		local empower = SlotIsEmpower(slot)
		widget:SetAttribute("IsEmpowerSpell", empower and true or nil)
		-- ButtonFX CLICK_SNIPPET resolves these by modifier, matching the
		-- action* / shift-action* / ctrl-action* slot the press will use.
		for _, prefix in ipairs({ "", "shift-", "ctrl-" }) do
			local swapSlot = tonumber(widget:GetAttribute(prefix .. "action*"))
			widget:SetAttribute(prefix .. "IsEmpowerSpell*",
				swapSlot and SlotIsEmpower(swapSlot) or false)
		end
		local FX = Flux.ButtonFX
		if WrapClicks() then
			widget:SetAttribute("pressAndHoldAction", true)
			-- Do not force typerelease=action: overlay hosts are type=click.
			if FX and FX.Click and FX.Click.MirrorTypeRelease then
				FX.Click.MirrorTypeRelease(widget)
			else
				local t = widget:GetAttribute("type") or "action"
				widget:SetAttribute("typerelease", t)
			end
		else
			-- Forever mouse is AnyUp + useOnKeyDown false. pressAndHold would
			-- force the down-gate and skip UseAction on release.
			widget:SetAttribute("pressAndHoldAction", false)
			widget:SetAttribute("useOnKeyDown", false)
		end
	end)
end

function Clicks.InvalidateKeys()
	lastKeySig = nil
end

function Clicks.RefreshKeys()
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.keys", Clicks.RefreshKeys)
		end
		return
	end
	local owner = Bars.Strip and Bars.Strip.frame
	if not owner or not SetOverrideBindingClick or not GetBindingKey then
		return
	end

	local sig = {}
	for column = 1, Bars.NUM_COLUMNS do
		local col = Bars.hosts[column]
		local host = col and col.main
		local command = host and host.bindingCommand
		local k1, k2
		if command then
			k1, k2 = GetBindingKey(command)
		end
		sig[#sig + 1] = command or "-"
		sig[#sig + 1] = k1 or "-"
		sig[#sig + 1] = k2 or "-"
		sig[#sig + 1] = host and host.widget and host.widget:GetName() or "-"
	end
	sig = table.concat(sig, "|")
	if sig == lastKeySig then
		return
	end
	lastKeySig = sig

	if ClearOverrideBindings then
		ClearOverrideBindings(owner)
	end
	for column = 1, Bars.NUM_COLUMNS do
		local col = Bars.hosts[column]
		local host = col and col.main
		if host and host.bindingCommand and host.widget then
			local widgetName = host.widget:GetName()
			if widgetName then
				local clickName = widgetName
				local clickButton = "KeyBind"
				if not WrapClicks() then
					local keyer = EnsureKeyer(host.widget, column)
					clickName = keyer and keyer:GetName() or widgetName
					clickButton = "LeftButton"
					local PP = ns.FluxBindingPushPress or _G.FluxBindingPushPress
					if PP and PP.HookKeyer and keyer then
						PP.HookKeyer(keyer, column)
					end
				end
				local keys = { GetBindingKey(host.bindingCommand) }
				for i = 1, #keys do
					local key = keys[i]
					if key and key ~= "" then
						pcall(SetOverrideBindingClick, owner, false, key, clickName, clickButton)
					end
				end
			end
			if Bars.Paint and Bars.Paint.UpdateHotkey then
				Bars.Paint.UpdateHotkey(host)
			end
		end
	end
	Clicks.ReassertEmpower()
end

function Clicks.OnCVar(cvarName)
	if type(cvarName) ~= "string" then
		return
	end
	local lower = string.lower(cvarName)
	if lower ~= "actionbuttonusekeydown" and lower ~= "empowertapcontrols" then
		return
	end
	if Flux.ButtonFX and Flux.ButtonFX.Click and Flux.ButtonFX.Click.SyncCVars then
		if InLockdown() then
			if Flux.Combat and Flux.Combat.Defer then
				Flux.Combat.Defer("bars.clickcvar", Flux.ButtonFX.Click.SyncCVars)
			end
		else
			Flux.ButtonFX.Click.SyncCVars()
		end
	end
	Clicks.ApplyRegistration()
	Clicks.InvalidateKeys()
	Clicks.RefreshKeys()
end

function Clicks.Start()
	if started then
		return
	end
	started = true
	Clicks.ApplyRegistration()
	Clicks.RefreshKeys()
	local PP = ns.FluxBindingPushPress or _G.FluxBindingPushPress
	if PP and PP.EnsureBarButtonPushHooks then
		PP.EnsureBarButtonPushHooks()
	end
	local Ev = Flux.Events
	if Ev and Ev.Register then
		Ev.Register("CVAR_UPDATE", function(_, name)
			Clicks.OnCVar(name)
		end)
	end
end
