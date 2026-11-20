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
-- Bare keys and otherwise-unassigned SHIFT/CTRL variants route explicitly.
-- Modified dispatch must not depend on the client's bare-key fallback. The
-- same host still chooses its prepared slot at press time (see Bars/State.lua).
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Clicks = {}
Bars.Clicks = Clicks

local installedKeys
local bindingRevision = 0
local started = false
local KEY_MODIFIERS = { "SHIFT-", "CTRL-" }

local function IsBareKey(key)
	local prefix = key:match("^([A-Z]+)%-")
	return prefix ~= "ALT" and prefix ~= "CTRL" and prefix ~= "SHIFT" and prefix ~= "META" and prefix ~= "CMD"
end

local function UnassignedModifierChord(key, command)
	if type(GetBindingAction) ~= "function" then return false end
	local ok, action = pcall(GetBindingAction, key, false)
	if not ok or (issecretvalue and issecretvalue(action)) then return false end
	return action == "" or action == "NONE" or action == command
end

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
		return false
	end
	local FX = Flux.ButtonFX
	if FX and FX.Click and FX.Click.Apply then
		if FX.Click.Apply(widget) == false then return false end
	else
		widget:RegisterForClicks("AnyUp")
	end
	if widget.EnableMouse then
		widget:EnableMouse(true)
	end
	return true
end

function Clicks.ApplyRegistration()
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.clicks", Clicks.ApplyRegistration)
		end
		return false
	end
	local complete = true
	Bars.ForEachHost(function(host)
		if host.widget then
			if Clicks.Prepare(host.widget) == false then complete = false end
		end
	end)
	return complete
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

-- The main's secure state publishes the proxy's complete live action bundle.
-- Remove legacy specific selectors which could outrank that bundle, retaining
-- its bare fields when bindings are refreshed. Unit policy remains inherited.
local KEYER_SELECTORS = {
	"type", "typerelease", "action", "macro", "macrotext", "clickbutton", "unit", "checkmouseovercast",
}
local KEYER_PREFIXES = { "", "shift-", "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-", "*" }
function Clicks.InheritKeyerActions(keyer)
	if not keyer or InLockdown() then return false end
	for _, name in ipairs(KEYER_SELECTORS) do
		for _, prefix in ipairs(KEYER_PREFIXES) do
			if prefix ~= "" and keyer:GetAttribute(prefix .. name) ~= nil then keyer:SetAttribute(prefix .. name, nil) end
			if keyer:GetAttribute(prefix .. name .. "1") ~= nil then keyer:SetAttribute(prefix .. name .. "1", nil) end
			if keyer:GetAttribute(prefix .. name .. "*") ~= nil then keyer:SetAttribute(prefix .. name .. "*", nil) end
		end
		local inherit = name == "unit" or name == "checkmouseovercast"
		if keyer:GetAttribute("useparent-" .. name) ~= inherit then
			keyer:SetAttribute("useparent-" .. name, inherit)
		end
	end
	return true
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
	end
	if not keyer._fluxKeyerReady then
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
		keyer:SetAttribute("useparent-unit", true)
		keyer:SetAttribute("useparent-checkmouseovercast", true)
		keyer._fluxKeyerReady = true
	elseif widget and keyer.SetParent then
		keyer:SetParent(widget)
	end
	Clicks.InheritKeyerActions(keyer)
	local State = Bars.State
	local header = State and State.HeaderFor and State.HeaderFor(column, "main")
	if header and header.SetFrameRef then header:SetFrameRef("keyer-" .. column, keyer) end
	-- A new/reused proxy needs the current bundle even if the main's secure
	-- applied-slot guard will skip an otherwise unchanged ChildUpdate.
	if State and State.SyncMainKeyer then State.SyncMainKeyer(widget, keyer) end
	local PP = ns.FluxBindingPushPress or _G.FluxBindingPushPress
	if PP and PP.HookKeyer then
		PP.HookKeyer(keyer, column)
	end
	return keyer
end

local EMPOWER_ALIASES = {
	{ "ctrl-shift-", "shift-" }, { "alt-", "" }, { "alt-shift-", "shift-" },
	{ "alt-ctrl-", "ctrl-" }, { "alt-ctrl-shift-", "shift-" },
}

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
		-- Compound modifiers share the same three prepared slot selections.
		-- Reuse their flags instead of querying the native spell API again.
		for _, pair in ipairs(EMPOWER_ALIASES) do
			widget:SetAttribute(pair[1] .. "IsEmpowerSpell*", widget:GetAttribute(pair[2] .. "IsEmpowerSpell*") or false)
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
	installedKeys = nil
	bindingRevision = bindingRevision + 1
end

local function RoutesStillReady(routes, owner, wrapped)
	if not routes or routes.owner ~= owner or routes.wrapped ~= wrapped
		or routes.lookup ~= GetBindingKey or routes.install ~= SetOverrideBindingClick
		or #routes.hosts ~= Bars.NUM_COLUMNS then return false end
	for column, route in ipairs(routes.hosts) do
		local col = Bars.hosts[column]
		local host = col and col.main
		local widget = host and host.widget
		if route.widget ~= widget or route.command ~= (host and host.bindingCommand) then return false end
		if widget and not wrapped then
			local keyer = _G["FluxActionStripKey" .. column]
			if not keyer or not keyer._fluxKeyerReady then return false end
			local action = keyer:GetAttribute("action")
			if (issecretvalue and issecretvalue(action)) or action == nil then return false end
		end
	end
	return true
end

function Clicks.RefreshKeys(hoverOnly)
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.keys", Clicks.RefreshKeys)
		end
		return false
	end
	local owner = Bars.Strip and Bars.Strip.frame
	if not owner or not SetOverrideBindingClick or not GetBindingKey then
		return false
	end

	local wrapped = not not WrapClicks()
	local previous = installedKeys
	local revision = bindingRevision
	local watch = Bars.Watch
	local reuse = hoverOnly == true and watch and watch.bindingEvents and watch.bindingEvents == Flux.Events
	-- A pure hover moves the faces while the binding event owns key changes.
	-- Keep checking host identities and the native proxy's live action bundle.
	if reuse and RoutesStillReady(previous, owner, wrapped) and previous == installedKeys then return true end

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
	if not reuse and previous and sig == previous.signature and RoutesStillReady(previous, owner, wrapped)
		and previous == installedKeys then
		return true
	end
	local complete = true
	local routes = { owner = owner, wrapped = wrapped, lookup = GetBindingKey, install = SetOverrideBindingClick,
		hosts = {}, signature = sig }
	installedKeys = nil

	if ClearOverrideBindings then
		ClearOverrideBindings(owner)
	end
	for column = 1, Bars.NUM_COLUMNS do
		local col = Bars.hosts[column]
		local host = col and col.main
		routes.hosts[column] = { widget = host and host.widget, command = host and host.bindingCommand }
		if host and host.bindingCommand and host.widget then
			local widgetName = host.widget:GetName()
			if widgetName then
				local clickName = widgetName
				local clickButton = "KeyBind"
				if not wrapped then
					local keyer = EnsureKeyer(host.widget, column)
					if not keyer then complete = false end
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
						if not pcall(SetOverrideBindingClick, owner, false, key, clickName, clickButton) then complete = false end
						-- ALT and Shift+Ctrl chords belong to Binding's free-chord
						-- owner. Ordinary Shift/Ctrl bar routes use this same keyer,
						-- unless the player assigned that exact native chord elsewhere.
						if IsBareKey(key) then
							for _, prefix in ipairs(KEY_MODIFIERS) do
								local chord = prefix .. key
								if UnassignedModifierChord(chord, host.bindingCommand) then
									if not pcall(SetOverrideBindingClick, owner, false, chord, clickName, clickButton) then complete = false end
								end
							end
						end
					end
				end
			end
			if Bars.Paint and Bars.Paint.UpdateHotkey then
				Bars.Paint.UpdateHotkey(host)
			end
		end
	end
	Clicks.ReassertEmpower()
	if complete and revision == bindingRevision then installedKeys = routes end
	return complete
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
		return true
	end
	if Clicks.ApplyRegistration() == false then return false end
	if Clicks.RefreshKeys() == false then return false end
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
	started = true
	return true
end
