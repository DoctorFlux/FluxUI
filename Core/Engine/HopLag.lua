-- HopLag.lua — in-game hop / modifier lag overlay. Off by default.
-- /fluxhop on  → overlay + traces. Reproduce cursor hops and Shift/Ctrl swaps.
-- /fluxhop report lists recent bursts and their pass timings.
local addonName, ns = ...
local Flux = ns.Flux

local HopLag = {}
Flux.HopLag = HopLag
Flux.Engine = Flux.Engine or {}
Flux.Engine.HopLag = HopLag

HopLag.enabled = false
HopLag.verbose = false
HopLag.threshold = 3

local profilestop = debugprofilestop
local GetTime = GetTime
local format = string.format
local pairs = pairs
local type = type
local tostring = tostring

local STORM_QUIET = 0.12
local RING = 6

local WATCH_EVENTS = {
	UPDATE_MOUSEOVER_UNIT = "umu",
	PLAYER_TARGET_CHANGED = "target",
	PLAYER_FOCUS_CHANGED = "focus",
	MODIFIER_STATE_CHANGED = "mod",
	ACTIONBAR_UPDATE_USABLE = "usable",
	SPELL_UPDATE_USABLE = "usable",
	ACTIONBAR_SLOT_CHANGED = "slot",
	ACTION_RANGE_CHECK_UPDATE = "range",
	ACTIONBAR_UPDATE_COOLDOWN = "cd",
	UPDATE_SHAPESHIFT_FORM = "form",
	ACTIONBAR_PAGE_CHANGED = "form",
	UPDATE_BONUS_ACTIONBAR = "form",
	UPDATE_VEHICLE_ACTIONBAR = "form",
	UPDATE_OVERRIDE_ACTIONBAR = "form",
	UPDATE_STEALTH = "form",
	SPELLS_CHANGED = "spells",
}

local openPass = {}
local openKind = {}
local wrapsInstalled = false
local overlay
local overlayAcc = 0
local stormCloseArmed = false
local cpuSampleArmed = false

local eventMs = {}
local eventN = {}
local passMs = {}
local passN = {}
local passKind = {}
local counts = {}

local hopStorm
local modStorm
local formStorm
local lastHop
local lastMod
local lastForm
local hopRing = {}
local modRing = {}
local formRing = {}
local hopWorst
local modWorst
local formWorst

local roll
local lastRoll

local function NewRoll(now)
	return {
		t0 = now or 0,
		fpsMin = 999,
		rootMs = 0,
		hopBus = 0,
		modBus = 0,
		formBus = 0,
		umu = 0,
		mod = 0,
		form = 0,
		spells = 0,
		usable = 0,
		slot = 0,
		range = 0,
		attr = 0,
		cpuMs = nil,
		passMs = {},
		passN = {},
	}
end

local cpuMark

local function ReadCpu()
	if not UpdateAddOnCPUUsage or not GetAddOnCPUUsage then
		return nil
	end
	if GetCVar and GetCVar("scriptProfile") ~= "1" then
		return nil
	end
	UpdateAddOnCPUUsage()
	return GetAddOnCPUUsage(addonName) or 0
end

local function EnsureRoll()
	local now = (GetTime and GetTime()) or 0
	if not roll then
		roll = NewRoll(now)
		cpuMark = ReadCpu()
		return roll
	end
	if now - roll.t0 >= 1 then
		local cpu = ReadCpu()
		if cpu and cpuMark then
			roll.cpuMs = cpu - cpuMark
		end
		cpuMark = cpu
		lastRoll = roll
		roll = NewRoll(now)
	end
	return roll
end

local function SortedKeys(tbl)
	local keys = {}
	for key in pairs(tbl) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

local function PushRing(ring, report)
	ring[#ring + 1] = report
	if #ring > RING then
		table.remove(ring, 1)
	end
end

local function SnapshotPass(srcMs, srcN)
	local ms, n = {}, {}
	for key, value in pairs(srcMs) do
		if value ~= 0 then
			ms[key] = value
			n[key] = srcN[key] or 0
		end
	end
	return ms, n
end

local function DiffPass(nowMs, nowN, beforeMs, beforeN)
	local ms, n = {}, {}
	for key, value in pairs(nowMs) do
		local d = value - (beforeMs[key] or 0)
		if d ~= 0 then
			ms[key] = d
			n[key] = (nowN[key] or 0) - (beforeN[key] or 0)
		end
	end
	return ms, n
end

local function SumRoot(ms)
	local total = 0
	for key, value in pairs(ms) do
		if passKind[key] == "root" then
			total = total + value
		end
	end
	return total
end

local function TopPasses(ms, n, limit)
	local keys = SortedKeys(ms)
	table.sort(keys, function(a, b)
		return (ms[a] or 0) > (ms[b] or 0)
	end)
	local out = {}
	for i = 1, math.min(limit or 5, #keys) do
		local key = keys[i]
		out[i] = { key = key, ms = ms[key], n = n and n[key] or 0 }
	end
	return out
end

local function CloseStorm(storm, kind)
	if not storm then
		return nil
	end
	local now = (GetTime and GetTime()) or 0
	local ms, n = DiffPass(passMs, passN, storm.passMs, storm.passN)
	local report = {
		kind = kind,
		reason = storm.reason,
		seconds = now - storm.opened,
		events = storm.events,
		busMs = storm.busMs,
		rootMs = SumRoot(ms) + storm.busMs,
		umu = storm.umu,
		mod = storm.mod,
		form = storm.form,
		spells = storm.spells,
		cd = storm.cd,
		usable = storm.usable,
		slot = storm.slot,
		attr = (counts["attr.action"] or 0) - (storm.attr0 or 0),
		passMs = ms,
		passN = n,
	}
	return report
end

local function MaybePrint(report)
	if not HopLag.verbose or not report then
		return
	end
	if (report.rootMs or 0) < (HopLag.threshold or 3) then
		return
	end
	local tag = report.kind == "mod" and "|cffffaa00mod|r"
		or report.kind == "form" and "|cffaaff66form|r"
		or "|cff66ccffhop|r"
	local parts = {
		format("  [%s] %.2fms over %.2fs  bus=%.2f  events=%d",
			tag, report.rootMs or 0, report.seconds or 0, report.busMs or 0, report.events or 0),
	}
	if (report.umu or 0) > 0 then
		parts[#parts + 1] = "umu=" .. report.umu
	end
	if (report.mod or 0) > 0 then
		parts[#parts + 1] = "mod=" .. report.mod
	end
	if (report.form or 0) > 0 then
		parts[#parts + 1] = "form=" .. report.form
	end
	if (report.spells or 0) > 0 then
		parts[#parts + 1] = "spells=" .. report.spells
	end
	if (report.attr or 0) > 0 then
		parts[#parts + 1] = "attr=" .. report.attr
	end
	print(table.concat(parts, "  "))
	local top = TopPasses(report.passMs, report.passN, 6)
	for i = 1, #top do
		local row = top[i]
		print(format("      %-28s %7.2f ms  x%d", row.key, row.ms, row.n))
	end
end

local function FinishHop()
	if not hopStorm then
		return
	end
	local report = CloseStorm(hopStorm, "hop")
	hopStorm = nil
	if not report then
		return
	end
	lastHop = report
	PushRing(hopRing, report)
	if not hopWorst or (report.rootMs or 0) > (hopWorst.rootMs or 0) then
		hopWorst = report
	end
	MaybePrint(report)
end

local function FinishMod()
	if not modStorm then
		return
	end
	local report = CloseStorm(modStorm, "mod")
	modStorm = nil
	if not report then
		return
	end
	lastMod = report
	PushRing(modRing, report)
	if not modWorst or (report.rootMs or 0) > (modWorst.rootMs or 0) then
		modWorst = report
	end
	MaybePrint(report)
end

local function FinishForm()
	if not formStorm then
		return
	end
	local report = CloseStorm(formStorm, "form")
	formStorm = nil
	if not report then
		return
	end
	lastForm = report
	PushRing(formRing, report)
	if not formWorst or (report.rootMs or 0) > (formWorst.rootMs or 0) then
		formWorst = report
	end
	MaybePrint(report)
end

local function TickStorms()
	if not hopStorm and not modStorm and not formStorm then
		stormCloseArmed = false
		return
	end
	local now = (GetTime and GetTime()) or 0
	local again = false
	if hopStorm then
		if now >= hopStorm.deadline then
			FinishHop()
		else
			again = true
		end
	end
	if modStorm then
		if now >= modStorm.deadline then
			FinishMod()
		else
			again = true
		end
	end
	if formStorm then
		if now >= formStorm.deadline then
			FinishForm()
		else
			again = true
		end
	end
	if again then
		stormCloseArmed = true
		local wait = 0.05
		if hopStorm and hopStorm.deadline - now > 0 then
			wait = hopStorm.deadline - now
		end
		if modStorm and modStorm.deadline - now > 0 then
			wait = math.min(wait, modStorm.deadline - now)
		end
		if formStorm and formStorm.deadline - now > 0 then
			wait = math.min(wait, formStorm.deadline - now)
		end
		local after = Flux.Timer and Flux.Timer.After
		if after then
			after(math.max(0.02, wait), TickStorms)
		else
			stormCloseArmed = false
		end
	else
		stormCloseArmed = false
	end
end

local function OpenStorm(slot, reason)
	local now = (GetTime and GetTime()) or 0
	local storm = slot
	if not storm then
		storm = {
			reason = reason,
			opened = now,
			events = 0,
			busMs = 0,
			umu = 0,
			mod = 0,
			usable = 0,
			slot = 0,
			attr0 = counts["attr.action"] or 0,
			passMs = {},
			passN = {},
		}
		for key, value in pairs(passMs) do
			storm.passMs[key] = value
		end
		for key, value in pairs(passN) do
			storm.passN[key] = value
		end
	end
	storm.deadline = now + STORM_QUIET
	if not stormCloseArmed then
		stormCloseArmed = true
		local after = Flux.Timer and Flux.Timer.After
		if after then
			after(STORM_QUIET, TickStorms)
		end
	end
	return storm
end

local function AddRollPass(key, ms)
	local r = EnsureRoll()
	r.passMs[key] = (r.passMs[key] or 0) + ms
	r.passN[key] = (r.passN[key] or 0) + 1
	if passKind[key] == "root" then
		r.rootMs = r.rootMs + ms
	end
end

function HopLag.Count(key, amount)
	if not HopLag.enabled then
		return
	end
	EnsureRoll()
	counts[key] = (counts[key] or 0) + (amount or 1)
	if key == "attr.action" then
		local r = roll
		r.attr = r.attr + (amount or 1)
		if modStorm then
			modStorm.deadline = ((GetTime and GetTime()) or 0) + STORM_QUIET
		end
	end
end

function HopLag.Begin(key, kind)
	if not HopLag.enabled or not profilestop then
		return
	end
	openPass[key] = profilestop()
	if kind then
		openKind[key] = kind
		passKind[key] = kind
	end
end

function HopLag.Stop(key)
	local started = openPass[key]
	if not started then
		return 0
	end
	openPass[key] = nil
	local ms = profilestop() - started
	passMs[key] = (passMs[key] or 0) + ms
	passN[key] = (passN[key] or 0) + 1
	if openKind[key] then
		passKind[key] = openKind[key]
		openKind[key] = nil
	end
	AddRollPass(key, ms)
	return ms
end

local function NoteEvent(event, ms)
	if not HopLag.enabled then
		return
	end
	EnsureRoll()
	eventMs[event] = (eventMs[event] or 0) + ms
	eventN[event] = (eventN[event] or 0) + 1
	local watch = WATCH_EVENTS[event]
	local r = roll
	if watch == "umu" then
		r.umu = r.umu + 1
		r.hopBus = r.hopBus + ms
		hopStorm = OpenStorm(hopStorm, "hop")
		hopStorm.events = hopStorm.events + 1
		hopStorm.busMs = hopStorm.busMs + ms
		hopStorm.umu = hopStorm.umu + 1
	elseif watch == "mod" then
		r.mod = r.mod + 1
		r.modBus = r.modBus + ms
		modStorm = OpenStorm(modStorm, "mod")
		modStorm.events = modStorm.events + 1
		modStorm.busMs = modStorm.busMs + ms
		modStorm.mod = modStorm.mod + 1
	elseif watch == "form" then
		r.form = r.form + 1
		r.formBus = r.formBus + ms
		formStorm = OpenStorm(formStorm, "form")
		formStorm.events = formStorm.events + 1
		formStorm.busMs = formStorm.busMs + ms
		formStorm.form = (formStorm.form or 0) + 1
	elseif watch == "spells" then
		r.spells = r.spells + 1
		r.formBus = r.formBus + ms
		formStorm = OpenStorm(formStorm, "form")
		formStorm.events = formStorm.events + 1
		formStorm.busMs = formStorm.busMs + ms
		formStorm.spells = (formStorm.spells or 0) + 1
	elseif watch == "target" or watch == "focus" then
		r.hopBus = r.hopBus + ms
		hopStorm = OpenStorm(hopStorm, "hop")
		hopStorm.events = hopStorm.events + 1
		hopStorm.busMs = hopStorm.busMs + ms
	elseif watch == "usable" then
		r.usable = r.usable + 1
		if hopStorm then
			hopStorm.usable = hopStorm.usable + 1
			hopStorm.deadline = ((GetTime and GetTime()) or 0) + STORM_QUIET
		end
		if modStorm then
			modStorm.usable = (modStorm.usable or 0) + 1
			modStorm.deadline = ((GetTime and GetTime()) or 0) + STORM_QUIET
		end
		if formStorm then
			formStorm.usable = (formStorm.usable or 0) + 1
			formStorm.deadline = ((GetTime and GetTime()) or 0) + STORM_QUIET
		end
	elseif watch == "slot" then
		r.slot = r.slot + 1
		if hopStorm then
			hopStorm.slot = hopStorm.slot + 1
			hopStorm.deadline = ((GetTime and GetTime()) or 0) + STORM_QUIET
		end
		if modStorm then
			modStorm.slot = (modStorm.slot or 0) + 1
			modStorm.deadline = ((GetTime and GetTime()) or 0) + STORM_QUIET
		end
		if formStorm then
			formStorm.slot = (formStorm.slot or 0) + 1
			formStorm.deadline = ((GetTime and GetTime()) or 0) + STORM_QUIET
		end
	elseif watch == "cd" then
		if formStorm then
			formStorm.cd = (formStorm.cd or 0) + 1
			formStorm.deadline = ((GetTime and GetTime()) or 0) + STORM_QUIET
		end
	elseif watch == "range" then
		r.range = r.range + 1
	end
end

-- Functions cannot be indexed; remember wraps on (obj, name) instead.
local wrappedNames = {}

local function AlreadyWrapped(obj, name)
	local rec = wrappedNames[obj]
	return rec and rec[name] and true or false
end

local function MarkWrapped(obj, name)
	local rec = wrappedNames[obj]
	if not rec then
		rec = {}
		wrappedNames[obj] = rec
	end
	rec[name] = true
end

local function Wrap(obj, name, key, kind)
	if not obj then
		return
	end
	local orig = obj[name]
	if type(orig) ~= "function" or AlreadyWrapped(obj, name) then
		return
	end
	passKind[key] = kind or "inner"
	MarkWrapped(obj, name)
	obj[name] = function(...)
		if not HopLag.enabled then
			return orig(...)
		end
		HopLag.Begin(key, kind)
		local a, b, c, d = orig(...)
		HopLag.Stop(key)
		return a, b, c, d
	end
end

local function WrapCount(obj, name, key)
	if not obj then
		return
	end
	local orig = obj[name]
	if type(orig) ~= "function" or AlreadyWrapped(obj, name) then
		return
	end
	MarkWrapped(obj, name)
	obj[name] = function(...)
		if HopLag.enabled then
			HopLag.Count(key)
		end
		return orig(...)
	end
end

local function InstallWraps()
	if wrapsInstalled then
		return
	end
	wrapsInstalled = true
	local Bars = Flux.Bars
	Wrap(Flux.Scheduler, "Flush", "sched.flush", "root")
	Wrap(Bars and Bars.Paint, "Flush", "paint.flush", "inner")
	Wrap(Bars and Bars.ProgramFace, "OnContext", "face.OnContext", "root")
	Wrap(Bars and Bars.ProgramFace, "TranslateHost", "face.TranslateHost", "inner")
	Wrap(Bars and Bars.ProgramFace, "TranslateAll", "face.TranslateAll", "inner")
	Wrap(Bars and Bars.BadgeHost, "SyncShownFaces", "badge.SyncShownFaces", "inner")
	Wrap(Bars and Bars.BadgeHost, "NotifyModifierPaging", "badge.NotifyModPage", "inner")
	Wrap(Bars and Bars.BadgeHost, "RefreshDisplays", "badge.RefreshDisplays", "inner")
	Wrap(Bars and Bars.BadgeHost, "RefreshMouseoverDisplays", "badge.RefreshMO", "inner")
	Wrap(Bars and Bars.BadgeHost, "RefreshFormVisibility", "badge.RefreshFormVis", "inner")
	Wrap(Bars and Bars.SlotProgram, "ApplyLiveType", "slot.ApplyLiveType", "inner")
	Wrap(Flux.Range, "Invalidate", "range.Invalidate", "inner")
	Wrap(Flux.Context, "Request", "ctx.Request", "inner")
	Wrap(Flux.Context, "RequestMouseover", "ctx.RequestMouseover", "inner")
	WrapCount(Bars and Bars.Paint, "Dirty", "paint.Dirty")
	WrapCount(Bars and Bars.Effects, "Refresh", "effects.Refresh")
	WrapCount(Bars and Bars.Effects, "RefreshAll", "effects.RefreshAll")
	WrapCount(Flux.Spell, "ClearLiveFaceCache", "spell.ClearLiveFace")
	local EBS = Flux.EBS
	Wrap(EBS and EBS.Paint, "FlushIcons", "ebs.FlushIcons", "inner")
	Wrap(EBS and EBS.Paint, "FlushEval", "ebs.FlushEval", "inner")
	Wrap(EBS and EBS.Paint, "FlushChecked", "ebs.FlushChecked", "inner")
	Wrap(EBS and EBS.Action, "TranslateMatching", "ebs.TranslateMatching", "inner")
end

local function ColorMs(ms)
	if ms >= 8 then
		return format("|cffff5555%.2f|r", ms)
	end
	if ms >= 3 then
		return format("|cffffcc00%.2f|r", ms)
	end
	return format("|cff88ff88%.2f|r", ms)
end

local function ColorFps(fps)
	if fps < 40 then
		return format("|cffff5555%.0f|r", fps)
	end
	if fps < 55 then
		return format("|cffffcc00%.0f|r", fps)
	end
	return format("|cff88ff88%.0f|r", fps)
end

local function Yn(v)
	return v and "yes" or "no"
end

local function LiveRoot(storm)
	if not storm then
		return 0
	end
	local ms = DiffPass(passMs, passN, storm.passMs, storm.passN)
	return SumRoot(ms) + (storm.busMs or 0)
end

local function OverlayText()
	EnsureRoll()
	local fps = GetFramerate and GetFramerate() or 0
	if roll and fps < roll.fpsMin then
		roll.fpsMin = fps
	end
	local r = lastRoll or roll
	local hopLive = hopStorm ~= nil
	local modLive = modStorm ~= nil
	local hopLast = hopLive and LiveRoot(hopStorm) or (lastHop and lastHop.rootMs or 0)
	local hopUmu = hopLive and (hopStorm.umu or 0) or (lastHop and lastHop.umu or 0)
	local hopW = hopWorst and hopWorst.rootMs or 0
	local modLast = modLive and LiveRoot(modStorm) or (lastMod and lastMod.rootMs or 0)
	local modAttr = modLive and ((counts["attr.action"] or 0) - (modStorm.attr0 or 0)) or (lastMod and lastMod.attr or 0)
	local modW = modWorst and modWorst.rootMs or 0
	local formLive = formStorm ~= nil
	local formLast = formLive and LiveRoot(formStorm) or (lastForm and lastForm.rootMs or 0)
	local formEv = formLive and (formStorm.events or 0) or (lastForm and lastForm.events or 0)
	local formSp = formLive and (formStorm.spells or 0) or (lastForm and lastForm.spells or 0)
	local formW = formWorst and formWorst.rootMs or 0
	local cpu = r and r.cpuMs
	local lines = {}
	lines[#lines + 1] = format(
		"|cff00ffffFlux hop/mod|r  %s  fps %s  min %s  cpu %s",
		HopLag.enabled and "|cff88ff88ON|r" or "|cff888888off|r",
		ColorFps(fps),
		r and r.fpsMin < 999 and ColorFps(r.fpsMin) or "—",
		cpu and format("%.1fms/s", cpu) or "n/a"
	)
	lines[#lines + 1] = format(
		"HOP  %s %sms  worst %sms  umu %d  |  MOD  %s %sms  worst %sms  attr %d",
		hopLive and "now" or "last",
		ColorMs(hopLast),
		ColorMs(hopW),
		hopUmu,
		modLive and "now" or "last",
		ColorMs(modLast),
		ColorMs(modW),
		modAttr
	)
	lines[#lines + 1] = format(
		"FORM %s %sms  worst %sms  ev %d  spells %d",
		formLive and "now" or "last",
		ColorMs(formLast),
		ColorMs(formW),
		formEv,
		formSp
	)
	lines[#lines + 1] = format(
		"1s   umu=%d  mod=%d  form=%d  spells=%d  usable=%d  slot=%d  range=%d  attr=%d  root=%sms",
		r and r.umu or 0,
		r and r.mod or 0,
		r and r.form or 0,
		r and r.spells or 0,
		r and r.usable or 0,
		r and r.slot or 0,
		r and r.range or 0,
		r and r.attr or 0,
		ColorMs(r and r.rootMs or 0)
	)
	local top = TopPasses((r and r.passMs) or {}, (r and r.passN) or {}, 4)
	if #top == 0 then
		lines[#lines + 1] = "hot  (hop the cursor / mash Shift+Ctrl)"
	else
		local bits = { "hot " }
		for i = 1, #top do
			bits[#bits + 1] = format("%s %s", top[i].key, ColorMs(top[i].ms))
		end
		lines[#lines + 1] = table.concat(bits, "  ")
	end
	local C = Flux.Context
	local st = C and C.GetStats and C.GetStats() or {}
	local Range = Flux.Range
	local FormStorm = Flux.FormStorm
	lines[#lines + 1] = format(
		"ctx req=%d skip=%d mo=%d coal=%d  | hopBurst=%s form=%s tickers=%d",
		st.requests or 0,
		st.skippedFp or 0,
		st.mouseoverRequests or 0,
		st.mouseoverCoalesced or 0,
		Yn(Range and Range.IsHopBurst and Range.IsHopBurst()),
		Yn(FormStorm and FormStorm.IsBursting and FormStorm.IsBursting()),
		Flux.Ticker and Flux.Ticker.Count and Flux.Ticker.Count() or 0
	)
	lines[#lines + 1] = "|cff888888/fluxhop report   watch   reset   cpu   off|r"
	return table.concat(lines, "\n")
end

local function EnsureOverlay()
	if overlay then
		return overlay
	end
	local tmpl = BackdropTemplateMixin and "BackdropTemplate" or nil
	local f = CreateFrame("Frame", "FluxHopLagOverlay", UIParent, tmpl)
	f:SetSize(560, 162)
	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 18, -70)
	f:SetFrameStrata("DIALOG")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	if f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		f:SetBackdropColor(0, 0, 0, 0.78)
		f:SetBackdropBorderColor(0.35, 0.7, 0.85, 0.9)
	else
		local bg = f:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		if bg.SetColorTexture then
			bg:SetColorTexture(0, 0, 0, 0.78)
		else
			bg:SetTexture(0, 0, 0, 0.78)
		end
	end
	local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", 10, -8)
	text:SetPoint("BOTTOMRIGHT", -10, 8)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	text:SetText("Flux hop/mod")
	f.text = text
	f:SetScript("OnUpdate", function(_, elapsed)
		if not HopLag.enabled then
			return
		end
		local fps = GetFramerate and GetFramerate() or 0
		EnsureRoll()
		if fps < roll.fpsMin then
			roll.fpsMin = fps
		end
		overlayAcc = overlayAcc + (elapsed or 0)
		if overlayAcc < 0.25 then
			return
		end
		overlayAcc = 0
		f.text:SetText(OverlayText())
	end)
	overlay = f
	return f
end

local function ShowOverlay(show)
	local f = EnsureOverlay()
	if show then
		f:Show()
		f.text:SetText(OverlayText())
	else
		f:Hide()
	end
end

local function ArmTraces(on)
	if Flux.Events and Flux.Events.SetTrace then
		Flux.Events.SetTrace(on and NoteEvent or nil)
	end
	if Flux.Modifier and Flux.Modifier.SetTrace then
		Flux.Modifier.SetTrace(on and function(kind, ms)
			if kind == "callbacks" then
				passKind["modifier.callbacks"] = "root"
				passMs["modifier.callbacks"] = (passMs["modifier.callbacks"] or 0) + ms
				passN["modifier.callbacks"] = (passN["modifier.callbacks"] or 0) + 1
				AddRollPass("modifier.callbacks", ms)
				if HopLag.enabled then
					if modStorm then
						modStorm.deadline = ((GetTime and GetTime()) or 0) + STORM_QUIET
					else
						modStorm = OpenStorm(nil, "mod")
					end
				end
			else
				passKind["modifier.event"] = "inner"
				passMs["modifier.event"] = (passMs["modifier.event"] or 0) + ms
				passN["modifier.event"] = (passN["modifier.event"] or 0) + 1
				AddRollPass("modifier.event", ms)
			end
		end or nil)
	end
	if Flux.Ticker and Flux.Ticker.SetTrace then
		Flux.Ticker.SetTrace(on and function(ms)
			passKind["ticker"] = "root"
			passMs["ticker"] = (passMs["ticker"] or 0) + ms
			passN["ticker"] = (passN["ticker"] or 0) + 1
			AddRollPass("ticker", ms)
		end or nil)
	end
end

function HopLag.Reset()
	for key in pairs(eventMs) do
		eventMs[key] = nil
	end
	for key in pairs(eventN) do
		eventN[key] = nil
	end
	for key in pairs(passMs) do
		passMs[key] = nil
	end
	for key in pairs(passN) do
		passN[key] = nil
	end
	for key in pairs(counts) do
		counts[key] = nil
	end
	for key in pairs(openPass) do
		openPass[key] = nil
	end
	hopStorm, modStorm, formStorm = nil, nil, nil
	lastHop, lastMod, lastForm = nil, nil, nil
	hopWorst, modWorst, formWorst = nil, nil, nil
	wipe(hopRing)
	wipe(modRing)
	wipe(formRing)
	roll = NewRoll((GetTime and GetTime()) or 0)
	lastRoll = nil
	HopLag._cpuPrev = nil
	cpuMark = nil
	if Flux.Context and Flux.Context.ResetStats then
		Flux.Context.ResetStats()
	end
end

function HopLag.Enable(on)
	on = on and true or false
	if on then
		InstallWraps()
		HopLag.enabled = true
		ArmTraces(true)
		ShowOverlay(true)
	else
		HopLag.enabled = false
		ArmTraces(false)
		ShowOverlay(false)
		FinishHop()
		FinishMod()
		FinishForm()
	end
end

local function PrintBurst(title, report)
	if not report then
		print("  " .. title .. ": none yet")
		return
	end
	local line = format("  %s  %.2fms over %.2fs  bus=%.2f  events=%d  umu=%d  mod=%d  attr=%d  usable=%d  slot=%d",
		title,
		report.rootMs or 0,
		report.seconds or 0,
		report.busMs or 0,
		report.events or 0,
		report.umu or 0,
		report.mod or 0,
		report.attr or 0,
		report.usable or 0,
		report.slot or 0)
	if (report.form or 0) > 0 or (report.spells or 0) > 0 or (report.cd or 0) > 0 then
		line = line .. format("  form=%d  spells=%d  cd=%d", report.form or 0, report.spells or 0, report.cd or 0)
	end
	print(line)
	local top = TopPasses(report.passMs or {}, report.passN or {}, 8)
	for i = 1, #top do
		print(format("      %-28s %7.2f ms  x%d", top[i].key, top[i].ms, top[i].n))
	end
end

function HopLag.Report()
	EnsureRoll()
	Flux.Print("Hop / modifier lag")
	print("  enabled=" .. Yn(HopLag.enabled)
		.. "  watch=" .. Yn(HopLag.verbose)
		.. "  thresh=" .. tostring(HopLag.threshold) .. "ms"
		.. "  scriptProfile=" .. tostring(GetCVar and GetCVar("scriptProfile")))
	PrintBurst("last HOP", lastHop)
	PrintBurst("worst HOP", hopWorst)
	PrintBurst("last MOD", lastMod)
	PrintBurst("worst MOD", modWorst)
	PrintBurst("last FORM", lastForm)
	PrintBurst("worst FORM", formWorst)
	local r = lastRoll or roll
	if r then
		print(format("  last 1s  umu=%d mod=%d form=%d spells=%d usable=%d slot=%d range=%d attr=%d root=%.2fms fpsMin=%.0f",
			r.umu or 0, r.mod or 0, r.form or 0, r.spells or 0, r.usable or 0, r.slot or 0, r.range or 0, r.attr or 0,
			r.rootMs or 0, (r.fpsMin and r.fpsMin < 999) and r.fpsMin or 0))
		local top = TopPasses(r.passMs or {}, r.passN or {}, 8)
		for i = 1, #top do
			print(format("      %-28s %7.2f ms  x%d", top[i].key, top[i].ms, top[i].n))
		end
	end
	print("  lifetime events")
	local evKeys = SortedKeys(eventN)
	for i = 1, #evKeys do
		local key = evKeys[i]
		print(format("      %-32s %6d  %7.2f ms", key, eventN[key] or 0, eventMs[key] or 0))
	end
	print("  lifetime passes")
	local pKeys = SortedKeys(passMs)
	for i = 1, #pKeys do
		local key = pKeys[i]
		print(format("      %-28s %7.2f ms  x%d  %s",
			key, passMs[key] or 0, passN[key] or 0, passKind[key] or ""))
	end
	local cKeys = SortedKeys(counts)
	if #cKeys > 0 then
		print("  counts")
		for i = 1, #cKeys do
			print(format("      %-28s %7d", cKeys[i], counts[cKeys[i]]))
		end
	end
	local C = Flux.Context
	local st = C and C.GetStats and C.GetStats() or nil
	if st then
		print(format("  context  req=%d skip=%d mo=%d coal=%d",
			st.requests or 0, st.skippedFp or 0, st.mouseoverRequests or 0, st.mouseoverCoalesced or 0))
	end
end

local function PrintHelp()
	Flux.Print("/fluxhop — live hop + Shift/Ctrl lag overlay")
	print("  /fluxhop on|off     arm traces (off costs nothing)")
	print("  /fluxhop overlay    hide or show the panel")
	print("  /fluxhop report     dump last/worst hop, modifier and form bursts")
	print("  /fluxhop watch      print a burst to chat when it exceeds the threshold")
	print("  /fluxhop thresh 5   watch threshold in milliseconds (default 3)")
	print("  /fluxhop cpu        5s addon CPU sample (needs /console scriptProfile 1 + reload)")
	print("  /fluxhop reset      clear counters")
	print("  Drag the overlay. Reproduce: flick the cursor over mobs, mash Shift/Ctrl, shapeshift / vehicle to capture FORM bursts.")
	print("  HOP last/worst = mouseover bus + later paint. MOD = modifier callbacks + action swaps.")
	print("  FORM = shapeshift/page/bonus/vehicle/stealth burst; spells = SPELLS_CHANGED stacked on it.")
	print("  Nested passes (OnContext, TranslateHost, Paint.Flush) are attribution, not extra total.")
end

function HopLag.Slash(msg)
	msg = type(msg) == "string" and msg:lower():match("^%s*(.-)%s*$") or ""
	if msg == "" then
		HopLag.Enable(not HopLag.enabled)
		Flux.Print("hop/mod debug " .. (HopLag.enabled and "ON — flick mouseover and mash Shift/Ctrl" or "off"))
		if HopLag.enabled then
			print("  /fluxhop help for commands")
		end
		return
	end
	if msg == "help" then
		PrintHelp()
		return
	end
	if msg == "on" or msg == "start" then
		HopLag.Enable(true)
		Flux.Print("hop/mod debug ON — overlay is top-left, drag it")
		return
	end
	if msg == "off" or msg == "stop" then
		HopLag.Enable(false)
		Flux.Print("hop/mod debug off")
		return
	end
	if msg == "overlay" then
		if not overlay or not overlay:IsShown() then
			HopLag.Enable(true)
			ShowOverlay(true)
			Flux.Print("overlay shown")
		else
			ShowOverlay(false)
			Flux.Print("overlay hidden (traces still " .. (HopLag.enabled and "on" or "off") .. ")")
		end
		return
	end
	if msg == "report" or msg == "dump" then
		if not HopLag.enabled and not lastHop and not lastMod then
			Flux.Print("nothing recorded yet — /fluxhop on, reproduce, then /fluxhop report")
			return
		end
		HopLag.Report()
		return
	end
	if msg == "reset" then
		HopLag.Reset()
		Flux.Print("hop/mod counters cleared")
		return
	end
	if msg == "watch" then
		HopLag.verbose = not HopLag.verbose
		if HopLag.verbose and not HopLag.enabled then
			HopLag.Enable(true)
		end
		Flux.Print("burst watch " .. (HopLag.verbose and ("on (≥" .. tostring(HopLag.threshold) .. "ms)") or "off"))
		return
	end
	local thresh = msg:match("^thresh%s+([%d%.]+)$") or msg:match("^threshold%s+([%d%.]+)$")
	if thresh then
		HopLag.threshold = tonumber(thresh) or 3
		Flux.Print("watch threshold " .. tostring(HopLag.threshold) .. "ms")
		return
	end
	if msg == "cpu" then
		if not ResetCPUUsage or not GetAddOnCPUUsage then
			Flux.Print("CPU APIs missing on this client")
			return
		end
		if GetCVar and GetCVar("scriptProfile") ~= "1" then
			Flux.Print("turn on |cffffff00/console scriptProfile 1|r then |cffffff00/reload|r, then run this again")
			return
		end
		if cpuSampleArmed then
			Flux.Print("CPU sample already running")
			return
		end
		if not HopLag.enabled then
			HopLag.Enable(true)
		end
		ResetCPUUsage()
		HopLag._cpuPrev = nil
		cpuSampleArmed = true
		Flux.Print("CPU sample started — hop the cursor and mash Shift/Ctrl for 5 seconds")
		local after = (Flux.Timer and Flux.Timer.After) or (C_Timer and C_Timer.After)
		if after then
			after(5, function()
				cpuSampleArmed = false
				UpdateAddOnCPUUsage()
				local ms = GetAddOnCPUUsage(addonName) or 0
				Flux.Print(format("5s addon CPU: %.1f ms  (%.1f ms/s)  — /fluxhop report for which pass", ms, ms / 5))
				HopLag.Report()
			end)
		end
		return
	end
	PrintHelp()
end

SLASH_FLUXHOP1 = "/fluxhop"
SLASH_FLUXHOP2 = "/fluxlag"
SlashCmdList["FLUXHOP"] = function(msg)
	HopLag.Slash(msg)
end
