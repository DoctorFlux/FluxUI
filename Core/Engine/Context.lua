-- Context.lua — fingerprint-gated display-context bus.
-- Shared hop / target / mod / combat fingerprint for bars, badges, and Extra
-- Buttons. Does not walk hosts. Notifies subscribers on the Scheduler display
-- tier only — never Binding Apply, never eval.
--
-- Subscribers receive a kinded info table on the display tier. Bars/ProgramFace
-- owns overlay + badge faces; Bars/MacrotextDisplay is a Request alias only.
local addonName, ns = ...
local Flux = ns.Flux

local Context = {}
Flux.Context = Context
Flux.Engine = Flux.Engine or {}
Flux.Engine.Context = Context

local subscribers = {}
local subscriberCount = 0
local eventsArmed = false
local refreshScheduled = false
local refreshForce = false
local refreshMouseoverOnly = false
local refreshForm = false
local lastUfPeek = nil
local lastContextFp = nil
local mouseoverScheduled = false
local mouseoverAt = nil
local poller
local pollAccum = 0
local POLL_INTERVAL = 0.05
local stats = {
	requests = 0,
	mouseoverRequests = 0,
	mouseoverCoalesced = 0,
	notifies = 0,
	skippedFp = 0,
}

local function IsUfPeek()
	local MK = _G.FluxMouseoverKeybindModule or _G.FluxMouseoverKeybind
	if MK and MK.IsHovercastPeekMouseContext then
		return MK:IsHovercastPeekMouseContext() and true or false
	end
	return false
end

local function MouseoverReactionClass()
	if not UnitExists or not UnitExists("mouseover") then
		return "-"
	end
	if UnitIsDead and UnitIsDead("mouseover") then
		return "d"
	end
	if UnitCanAttack and UnitCanAttack("player", "mouseover") then
		return "e"
	end
	if UnitCanAssist and UnitCanAssist("player", "mouseover") then
		return "f"
	end
	return "o"
end

local function UnitFpToken(unit, placeholder)
	if not UnitExists or not UnitExists(unit) then
		return "-"
	end
	local Secrets = Flux.Secrets
	if Secrets and Secrets.AccessibleGUIDForUnit then
		local guid = Secrets.AccessibleGUIDForUnit(unit)
		if type(guid) == "string" and guid ~= "" then
			return guid
		end
		return placeholder or "u"
	end
	local guid = UnitGUID and UnitGUID(unit)
	if Secrets and Secrets.IsSecretValue and Secrets.IsSecretValue(guid) then
		return placeholder or "u"
	end
	if Secrets and Secrets.CanAccessValue and not Secrets.CanAccessValue(guid) then
		return placeholder or "u"
	end
	if type(guid) == "string" and guid ~= "" then
		return guid
	end
	return placeholder or "u"
end

local function ContextFingerprint(ufPeek)
	local mods = ""
	if IsShiftKeyDown and IsShiftKeyDown() then
		mods = mods .. "s"
	end
	if IsControlKeyDown and IsControlKeyDown() then
		mods = mods .. "c"
	end
	if IsAltKeyDown and IsAltKeyDown() then
		mods = mods .. "a"
	end
	local tgt = UnitFpToken("target", "t")
	local foc = UnitFpToken("focus", "f")
	local mo = MouseoverReactionClass()
	local combat = (InCombatLockdown and InCombatLockdown()) and "1" or "0"
	return (ufPeek and "1" or "0") .. "|" .. mods .. "|" .. tgt .. "|" .. foc .. "|" .. mo .. "|" .. combat
end

local function FingerprintsEqual(a, b)
	if a == nil or b == nil then
		return a == b
	end
	local Secrets = Flux.Secrets
	if Secrets and Secrets.SafeEqualForCache then
		return Secrets.SafeEqualForCache(a, b) == true
	end
	local ok, same = pcall(function()
		return a == b
	end)
	return ok and same or false
end

local function MouseoverCoalesceInterval()
	local MR = _G.FluxMouseoverRefresh
	if MR and MR.GetInterval then
		local n = MR.GetInterval()
		if type(n) == "number" and n > 0 then
			return n
		end
	end
	return 0.07
end

local function HasSubscribers()
	return subscriberCount > 0
end

local function ParseFingerprint(fp)
	if type(fp) ~= "string" then
		return nil
	end
	local uf, mods, tgt, foc, mo, combat = string.match(fp, "([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)")
	if not uf then
		return nil
	end
	return { ufPeek = uf, mods = mods, tgt = tgt, foc = foc, mo = mo, combat = combat }
end

local function DiffKinds(prevFp, fp, force, form, mouseoverOnly)
	local info = {
		mouseoverOnly = mouseoverOnly and true or false,
		force = force and true or false,
		form = form and true or false,
		all = false,
		mods = false,
		target = false,
		mouseover = false,
		combat = false,
		ufPeekChanged = false,
	}
	if force or form or not prevFp then
		info.all = true
		info.mods = true
		info.target = true
		info.mouseover = true
		info.combat = true
		return info
	end
	local prev = ParseFingerprint(prevFp)
	local nextp = ParseFingerprint(fp)
	if not prev or not nextp then
		info.all = true
		return info
	end
	if prev.ufPeek ~= nextp.ufPeek then
		info.ufPeekChanged = true
	end
	if prev.mods ~= nextp.mods then
		info.mods = true
	end
	if prev.tgt ~= nextp.tgt or prev.foc ~= nextp.foc then
		info.target = true
	end
	if prev.mo ~= nextp.mo then
		info.mouseover = true
	end
	if prev.combat ~= nextp.combat then
		info.combat = true
	end
	if mouseoverOnly then
		info.mods = false
		info.target = false
		info.combat = false
		info.mouseover = true
		info.all = false
	end
	return info
end

local function NotifySubscribers(info)
	stats.notifies = stats.notifies + 1
	for i = 1, #subscribers do
		local fn = subscribers[i]
		if fn then
			Flux.Safecall(fn, info, info.mouseoverOnly, info.ufPeek)
		end
	end
end

local function RequestDisplayTier(info)
	local Scheduler = Flux.Scheduler
	local mouseoverOnly = info and info.mouseoverOnly
	if Scheduler and Scheduler.Request then
		Scheduler.Request("display", "flux.context", function()
			NotifySubscribers(info)
		end, mouseoverOnly and "context.mouseover" or "context")
		return
	end
	NotifySubscribers(info)
end

local function DoRefresh()
	refreshScheduled = false
	mouseoverScheduled = false
	mouseoverAt = nil
	local force = refreshForce
	local mouseoverOnly = refreshMouseoverOnly
	local form = refreshForm
	refreshForce = false
	refreshMouseoverOnly = false
	refreshForm = false
	if not HasSubscribers() then
		return
	end
	local ufPeek = IsUfPeek()
	lastUfPeek = ufPeek
	local fp = ContextFingerprint(ufPeek)
	local prev = lastContextFp
	if not force and not form and FingerprintsEqual(prev, fp) then
		stats.skippedFp = stats.skippedFp + 1
		return
	end
	lastContextFp = fp
	local info = DiffKinds(prev, fp, force, form, mouseoverOnly)
	info.ufPeek = ufPeek
	RequestDisplayTier(info)
end

local function ScheduleDoRefresh(delay)
	if refreshScheduled then
		return
	end
	refreshScheduled = true
	delay = delay or 0
	local after = (Flux.Timer and Flux.Timer.After) or (C_Timer and C_Timer.After)
	if after then
		after(delay, DoRefresh)
	else
		DoRefresh()
	end
end

function Context.Fingerprint(ufPeek)
	if ufPeek == nil then
		ufPeek = IsUfPeek()
	end
	return ContextFingerprint(ufPeek)
end

function Context.MouseoverReactionClass()
	return MouseoverReactionClass()
end

function Context.IsUfPeek()
	return IsUfPeek()
end

function Context.Subscribe(fn)
	if type(fn) ~= "function" then
		return
	end
	subscribers[#subscribers + 1] = fn
	subscriberCount = #subscribers
	if subscriberCount == 1 then
		Context.ArmEvents()
	end
end

function Context.Unsubscribe(fn)
	if type(fn) ~= "function" then
		return
	end
	for i = #subscribers, 1, -1 do
		if subscribers[i] == fn then
			table.remove(subscribers, i)
		end
	end
	subscriberCount = #subscribers
	if subscriberCount == 0 then
		Context.DisarmEvents()
	end
end

function Context.HasSubscribers()
	return HasSubscribers()
end

function Context.Request(force, opts)
	opts = opts or {}
	stats.requests = stats.requests + 1
	if not HasSubscribers() then
		return
	end
	if opts.form then
		refreshForm = true
	end
	if force then
		refreshForce = true
		lastContextFp = nil
		refreshMouseoverOnly = false
	elseif opts.mouseoverOnly then
		refreshMouseoverOnly = true
	else
		refreshMouseoverOnly = false
	end
	if refreshScheduled then
		if opts.mouseoverOnly then
			stats.mouseoverCoalesced = stats.mouseoverCoalesced + 1
		end
		return
	end
	if not force and not refreshForce and not refreshForm then
		local ufPeek = IsUfPeek()
		if FingerprintsEqual(ContextFingerprint(ufPeek), lastContextFp) then
			stats.skippedFp = stats.skippedFp + 1
			return
		end
	end
	ScheduleDoRefresh(0)
end

function Context.RequestMouseover()
	stats.mouseoverRequests = stats.mouseoverRequests + 1
	if not HasSubscribers() then
		return
	end
	local PF = Flux.Bars and Flux.Bars.ProgramFace
	if PF and PF.WakeMouseoverPoll then
		PF.WakeMouseoverPoll()
	end
	if IsUfPeek() then
		Context.Request(false)
		return
	end
	if PF and PF.Needs and not PF.Needs("mouseover") then
		return
	end
	local fp = ContextFingerprint(false)
	if FingerprintsEqual(fp, lastContextFp) then
		stats.skippedFp = stats.skippedFp + 1
		return
	end
	local now = GetTime and GetTime() or 0
	local interval = MouseoverCoalesceInterval()
	mouseoverAt = now + interval
	refreshMouseoverOnly = true
	if mouseoverScheduled or refreshScheduled then
		stats.mouseoverCoalesced = stats.mouseoverCoalesced + 1
		return
	end
	mouseoverScheduled = true
	refreshScheduled = true
	local function fire()
		if not mouseoverAt then
			mouseoverScheduled = false
			refreshScheduled = false
			return
		end
		local t = GetTime and GetTime() or 0
		if t < mouseoverAt then
			local after = (Flux.Timer and Flux.Timer.After) or (C_Timer and C_Timer.After)
			if after then
				after(mouseoverAt - t, fire)
				return
			end
		end
		DoRefresh()
	end
	local after = (Flux.Timer and Flux.Timer.After) or (C_Timer and C_Timer.After)
	if after then
		after(interval, fire)
	else
		DoRefresh()
	end
end

function Context.GetStats()
	return stats
end

function Context.ResetStats()
	for k in pairs(stats) do
		stats[k] = 0
	end
end

local function EnsurePoller()
	if poller then
		return poller
	end
	poller = CreateFrame("Frame")
	poller:Hide()
	poller:SetScript("OnUpdate", function(self, elapsed)
		pollAccum = pollAccum + elapsed
		if pollAccum < POLL_INTERVAL then
			return
		end
		pollAccum = 0
		if not HasSubscribers() then
			self:Hide()
			return
		end
		local peek = IsUfPeek()
		if peek ~= lastUfPeek then
			Context.Request()
		elseif not peek then
			self:Hide()
			local mo = UnitExists and UnitExists("mouseover")
			if not mo then
				Context.RequestMouseover()
			end
		end
	end)
	return poller
end

local function ArmPoll()
	if not HasSubscribers() then
		return
	end
	pollAccum = 0
	EnsurePoller():Show()
end

local function HookUnitFramePeek(frame)
	if not frame or frame._fluxContextPeekHooked then
		return
	end
	frame._fluxContextPeekHooked = true
	if frame.HookScript then
		pcall(frame.HookScript, frame, "OnEnter", function()
			ArmPoll()
			Context.Request()
		end)
		pcall(frame.HookScript, frame, "OnLeave", function()
			ArmPoll()
			Context.Request()
		end)
	end
end

Context.HookUnitFramePeek = HookUnitFramePeek

local function TryWireKeybindHooks()
	local MK = _G.FluxMouseoverKeybindModule or _G.FluxMouseoverKeybind
	if not MK or MK._fluxContextPeekWired then
		return
	end
	MK._fluxContextPeekWired = true
	local orig = MK.RegisterFrame
	if type(orig) == "function" then
		MK.RegisterFrame = function(self, frame)
			orig(self, frame)
			HookUnitFramePeek(frame)
		end
	end
end

local ev
local onMouseover, onTarget, onRegenOn, onRegenOff, onFocus

function Context.ArmEvents()
	if eventsArmed then
		return
	end
	eventsArmed = true
	onMouseover = onMouseover or function()
		if IsUfPeek() then
			ArmPoll()
		end
		Context.RequestMouseover()
	end
	onTarget = onTarget or function()
		Context.Request()
	end
	onRegenOn = onRegenOn or function()
		Context.Request()
	end
	onRegenOff = onRegenOff or function()
		Context.Request()
	end
	onFocus = onFocus or function()
		Context.Request()
	end
	local Ev = Flux.Events
	if Ev and Ev.Register then
		Ev.Register("UPDATE_MOUSEOVER_UNIT", onMouseover)
		Ev.Register("PLAYER_TARGET_CHANGED", onTarget)
		Ev.Register("PLAYER_REGEN_ENABLED", onRegenOn)
		Ev.Register("PLAYER_REGEN_DISABLED", onRegenOff)
		if Ev.IsValid and Ev.IsValid("PLAYER_FOCUS_CHANGED") then
			Ev.Register("PLAYER_FOCUS_CHANGED", onFocus)
		end
	else
		ev = ev or CreateFrame("Frame")
		ev:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		ev:RegisterEvent("PLAYER_TARGET_CHANGED")
		ev:RegisterEvent("PLAYER_REGEN_ENABLED")
		ev:RegisterEvent("PLAYER_REGEN_DISABLED")
		pcall(ev.RegisterEvent, ev, "PLAYER_FOCUS_CHANGED")
		ev:SetScript("OnEvent", function(_, event)
			if event == "UPDATE_MOUSEOVER_UNIT" then
				onMouseover()
				return
			end
			Context.Request()
		end)
	end
	if Flux.Modifier and Flux.Modifier.Register then
		Flux.Modifier.Register("Flux.Context", function()
			Context.Request()
		end)
	end
	TryWireKeybindHooks()
end

function Context.DisarmEvents()
	if not eventsArmed then
		return
	end
	eventsArmed = false
	if poller then
		poller:Hide()
	end
	if Flux.Modifier and Flux.Modifier.Unregister then
		Flux.Modifier.Unregister("Flux.Context")
	end
	local Ev = Flux.Events
	if Ev and Ev.Unregister then
		Ev.Unregister("UPDATE_MOUSEOVER_UNIT", onMouseover)
		Ev.Unregister("PLAYER_TARGET_CHANGED", onTarget)
		Ev.Unregister("PLAYER_REGEN_ENABLED", onRegenOn)
		Ev.Unregister("PLAYER_REGEN_DISABLED", onRegenOff)
		Ev.Unregister("PLAYER_FOCUS_CHANGED", onFocus)
	end
	if ev then
		ev:SetScript("OnEvent", nil)
	end
end

Context.FingerprintEqual = FingerprintsEqual
_G.FluxMouseoverReactionClass = _G.FluxMouseoverReactionClass or MouseoverReactionClass
