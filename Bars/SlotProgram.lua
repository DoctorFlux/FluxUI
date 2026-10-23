-- Bars/SlotProgram.lua — compiled overlay bodies keyed by action slot ID.
-- Peer/badge conditionals: ephemeral type=macro+macrotext on the visible host.
-- Sequences / petattack / multi-cast: hidden FluxSlotClick_<slot> + type=click.
local addonName, ns = ...
local Flux = ns.Flux
local Bars = Flux.Bars

local SlotProgram = {}
Bars.SlotProgram = SlotProgram
ns.FluxSlotProgram = SlotProgram
_G.FluxSlotProgram = SlotProgram

local programs = {}
local programModes = {}
local idlePrograms = {}
local hoverPrograms = {}
local clickers = {}

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function NoteIndex()
	local PF = Bars.ProgramFace
	if PF and PF.InvalidateIndex then
		PF.InvalidateIndex()
	end
end

local ATTR = "flux-p-"
local ATTR_IDLE = "flux-p-idle-"
local ATTR_H = "flux-h-"
local ATTR_CLICK = "flux-click-"
local ATTR_MODE = "flux-m-"

local function ModeToken(mode)
	if mode == "hidden" then
		return "h"
	end
	if mode == "display" then
		return "d"
	end
	if mode == "surface" then
		return "s"
	end
	return nil
end

local function EffectiveDisplayBody(host, slot, body)
	if host and host._fluxMacrotextDisplayBody then
		return host._fluxMacrotextDisplayBody
	end
	return body
end

local function ClickerName(slot)
	return "FluxSlotClick_" .. tostring(slot)
end

local function RetireClicker(slot)
	clickers[slot] = nil
	if InLockdown() then
		return
	end
	local Pool = ns.FluxSecureButtonPool or _G.FluxSecureButtonPool
	if Pool and Pool.Retire then
		Pool.Retire(ClickerName(slot))
	end
	local btn = _G[ClickerName(slot)]
	if btn and btn.SetAttribute then
		btn:SetAttribute("macrotext", "")
	end
end

local function EnsureClicker(slot, text)
	if type(text) ~= "string" or text == "" then
		RetireClicker(slot)
		return nil
	end
	if InLockdown() then
		return clickers[slot]
	end
	local Pool = ns.FluxSecureButtonPool or _G.FluxSecureButtonPool
	if not (Pool and Pool.Acquire) then
		return nil
	end
	local btn = Pool.Acquire(ClickerName(slot))
	if not btn then
		return nil
	end
	if Pool.ArmMacroDelegate and not Pool.ArmMacroDelegate(btn) then
		RetireClicker(slot)
		return nil
	end
	btn:Hide()
	btn:SetAttribute("type", "macro")
	btn:SetAttribute("macro", nil)
	btn:SetAttribute("macrotext", text)
	btn:SetAttribute("checkmouseovercast", false)
	btn:SetAttribute("unit", nil)
	clickers[slot] = btn
	return btn
end

local function SyncSurfaceFace(host, body)
	if not host then
		return
	end
	local PF = Bars.ProgramFace
	if type(body) ~= "string" or body == "" then
		if PF and PF.SyncHost then
			PF.SyncHost(host)
		else
			host._fluxFace = nil
		end
		return
	end
	-- Overlay face is ProgramFace / FluxButton occupancy, not a second env.
	if PF and PF.TranslateHost then
		PF.TranslateHost(host)
	elseif PF and PF.SyncHost then
		PF.SyncHost(host)
	end
end

local function WriteHostProgram(host, slot, text, mode)
	local widget = host and host.widget
	if not widget or not widget.SetAttribute then
		return
	end
	-- Bars.State bakes nomod / shift- / ctrl- click sets from these per-slot
	-- bodies, so a new body has to drop the guard that would skip the restamp.
	widget:SetAttribute("flux-applied-mods", nil)
	local key = ATTR .. tostring(slot)
	local idleKey = ATTR_IDLE .. tostring(slot)
	local clickKey = ATTR_CLICK .. tostring(slot)
	widget:SetAttribute(idleKey, nil)
	local modeTok = ModeToken(mode)
	if modeTok then
		widget:SetAttribute(ATTR_MODE .. tostring(slot), modeTok)
	else
		widget:SetAttribute(ATTR_MODE .. tostring(slot), nil)
	end
	if text and text ~= "" then
		widget:SetAttribute(key, text)
		if mode == "hidden" then
			widget:SetAttribute(clickKey, EnsureClicker(slot, text))
		else
			RetireClicker(slot)
			widget:SetAttribute(clickKey, nil)
		end
	else
		RetireClicker(slot)
		widget:SetAttribute(key, nil)
		widget:SetAttribute(clickKey, nil)
	end
	local hover = hoverPrograms[slot]
	local hkey = ATTR_H .. tostring(slot)
	if hover and hover ~= "" then
		widget:SetAttribute(hkey, hover)
	else
		widget:SetAttribute(hkey, nil)
	end
end

local function ApplyLiveType(host)
	local widget = host and host.widget
	if not widget or not widget.GetAttribute then
		return
	end
	local slot = host.slot or tonumber(widget:GetAttribute("action"))
	if not slot then
		return
	end
	local body = widget:GetAttribute(ATTR .. tostring(slot))
	local mode = programModes[slot]
	local clicker = widget:GetAttribute(ATTR_CLICK .. tostring(slot)) or clickers[slot]
	local State = Bars.State
	if host.row == "main" and host.column and host.column <= 12
		and State and State.GetCurrentPage and State.GetCurrentPage() >= 11 then
		body, clicker = nil, nil
	end
	local hasOverlay = clicker or (type(body) == "string" and body ~= "")
	if not InLockdown() then
		if not hasOverlay then
			local t = widget:GetAttribute("type")
			local mt = widget:GetAttribute("macrotext")
			local cb = widget:GetAttribute("clickbutton")
			if t ~= "action" or (mt and mt ~= "") or cb then
				widget:SetAttribute("unit", nil)
				widget:SetAttribute("macrotext", nil)
				widget:SetAttribute("macro", nil)
				widget:SetAttribute("type", "action")
				widget:SetAttribute("typerelease", "action")
				widget:SetAttribute("clickbutton", nil)
				local FX = Flux.ButtonFX
				if FX and FX.Click and FX.Click.MirrorTypeRelease then
					FX.Click.MirrorTypeRelease(widget)
				end
			end
		else
			widget:SetAttribute("unit", nil)
			if clicker then
				widget:SetAttribute("macrotext", nil)
				widget:SetAttribute("macro", nil)
				widget:SetAttribute("type", "click")
				widget:SetAttribute("typerelease", "click")
				widget:SetAttribute("clickbutton", clicker)
			elseif mode == "display" then
				widget:SetAttribute("macrotext", nil)
				widget:SetAttribute("macro", nil)
				widget:SetAttribute("type", "action")
				widget:SetAttribute("typerelease", "action")
				widget:SetAttribute("clickbutton", nil)
			else
				widget:SetAttribute("type", "macro")
				widget:SetAttribute("typerelease", "macro")
				widget:SetAttribute("clickbutton", nil)
				widget:SetAttribute("macro", nil)
				widget:SetAttribute("macrotext", body)
				widget:SetAttribute("checkmouseovercast", false)
			end
			local FX = Flux.ButtonFX
			if FX and FX.Click and FX.Click.MirrorTypeRelease then
				FX.Click.MirrorTypeRelease(widget)
			end
		end
		local MC = Flux.MouseoverCast
		if MC and MC.ApplyNativeCheck then
			MC.ApplyNativeCheck(widget)
		end
	end
	-- Always rebind this host's face to the live action slot. Skipping
	-- SyncHost left mini/main sharing the previous slot's _fluxFace and
	-- Identity (same icon, tooltip, and badges in a column after paging).
	-- Overlay / slot-macro still TranslateHost so [mod]/[mouseover] faces
	-- land now. deferPaint: OnActionAttribute MarkDirty + one bars.dirty
	-- flush paints; do not UpdateDisplay inside the attribute storm.
	local PF = Bars.ProgramFace
	if hasOverlay then
		if PF and PF.TranslateHost then
			PF.TranslateHost(host, true)
		end
	elseif PF and PF.SyncHost then
		local rebound = PF.SyncHost(host)
		if rebound and PF.TranslateHost then
			PF.TranslateHost(host, true)
		end
	end
end

SlotProgram.ApplyLiveType = ApplyLiveType

-- Binding Apply implicit scan: every slot the strip can display.
local SlotHost = ns.FluxSlotHost or {}
ns.FluxSlotHost = SlotHost
_G.FluxSlotHost = SlotHost

function SlotHost.GetAllBarSlots()
	local set = {}
	local State = Bars.State
	if not State then
		return set
	end
	local cols = Bars.NUM_COLUMNS or 19
	for col = 1, cols do
		local sec = State.GetSecondarySlot and State.GetSecondarySlot(col)
		local tert = State.GetTertiarySlot and State.GetTertiarySlot(col)
		if sec then
			set[sec] = true
		end
		if tert then
			set[tert] = true
		end
		for page = 0, 18 do
			local main = State.GetMainSlot and State.GetMainSlot(col, page)
			if main then
				set[main] = true
			end
		end
	end
	return set
end

local restampQueued = false

--- ApplyLiveType only rebinds the live face. The nomod / shift- / ctrl- click
--- sets are baked from the per-slot bodies, so they need a pass of their own --
--- coalesced, because ApplyMap writes many slots in a row.
local function QueueClickSetRestamp()
	if restampQueued or InLockdown() then
		return
	end
	restampQueued = true
	local function flush()
		restampQueued = false
		local State = Bars.State
		if State and State.ForceApply then
			State.ForceApply()
		end
	end
	if Flux.Timer and Flux.Timer.Defer then
		Flux.Timer.Defer(flush)
	else
		flush()
	end
end

local function WriteAllHosts(slot, text, mode)
	if not Bars.ForEachHost then
		return
	end
	Bars.ForEachHost(function(host)
		WriteHostProgram(host, slot, text, mode)
		local live = Bars.Hosts and Bars.Hosts.LiveSlot and Bars.Hosts.LiveSlot(host)
		if live == slot then
			ApplyLiveType(host)
		end
	end)
	QueueClickSetRestamp()
end

function SlotProgram.Apply(slot, text, mode, idle)
	slot = tonumber(slot)
	if not slot then
		return
	end
	if text == false or text == "" then
		text = nil
		mode = nil
		idle = nil
	end
	if mode ~= "hidden" and mode ~= "surface" and mode ~= "display" then
		mode = text and "surface" or nil
	end
	if type(idle) ~= "string" or idle == "" or idle == text then
		idle = nil
	end
	if programs[slot] == text and programModes[slot] == mode and idlePrograms[slot] == idle then
		return
	end
	programs[slot] = text
	programModes[slot] = mode
	idlePrograms[slot] = idle
	NoteIndex()
	local function run()
		WriteAllHosts(slot, text, mode)
	end
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.slotprogram", function()
				for s, body in pairs(programs) do
					WriteAllHosts(s, body, programModes[s])
				end
			end)
		end
		return
	end
	run()
end

function SlotProgram.ApplyMap(map, clearMissing, modes, idles)
	-- Slot ids must be numbers. A string key ("1") and a number key (1) are
	-- different table keys, so clearMissing used to write false over the body
	-- it had just installed and the keypress macro disappeared.
	local norm, normModes, normIdles = {}, {}, {}
	for slot, text in pairs(map or {}) do
		local n = tonumber(slot)
		if n then
			norm[n] = text
			if modes then
				normModes[n] = modes[slot]
			end
			if idles then
				normIdles[n] = idles[slot]
			end
		end
	end
	if clearMissing then
		for slot in pairs(programs) do
			if norm[slot] == nil then
				norm[slot] = false
			end
		end
	end
	for slot, text in pairs(norm) do
		SlotProgram.Apply(slot, text, normModes[slot], normIdles[slot])
	end
end

function SlotProgram.Get(slot)
	return programs[tonumber(slot)]
end

function SlotProgram.GetIdle(slot)
	slot = tonumber(slot)
	if not slot then
		return nil
	end
	return idlePrograms[slot]
end

function SlotProgram.GetMode(slot)
	return programModes[tonumber(slot)]
end

function SlotProgram.GetAll()
	return programs
end

function SlotProgram.ClickButtonName(slot)
	slot = tonumber(slot)
	if not slot or not programs[slot] then
		return nil
	end
	if programModes[slot] ~= "hidden" then
		return nil
	end
	return ClickerName(slot)
end

function SlotProgram.ClickButton(slot)
	if programModes[tonumber(slot)] ~= "hidden" then
		return nil
	end
	return clickers[tonumber(slot)]
end

function SlotProgram.HasAny()
	return next(programs) ~= nil
end

function SlotProgram.SetHover(slot, text)
	slot = tonumber(slot)
	if not slot then
		return
	end
	if text == false or text == "" then
		text = nil
	end
	hoverPrograms[slot] = text
	NoteIndex()
end

function SlotProgram.ApplyHoverMap(map, clearMissing)
	map = map or {}
	if clearMissing then
		for slot in pairs(hoverPrograms) do
			if map[slot] == nil then
				map[slot] = false
			end
		end
	end
	local function peek()
		local PF = Bars.ProgramFace
		if PF and PF.RequestHoverPeek then
			PF.RequestHoverPeek()
		end
	end
	local function run()
		for slot, text in pairs(map) do
			SlotProgram.SetHover(slot, text)
			local nslot = tonumber(slot)
			if nslot then
				WriteAllHosts(nslot, programs[nslot], programModes[nslot])
			end
		end
		peek()
	end
	if InLockdown() then
		for slot, text in pairs(map) do
			SlotProgram.SetHover(slot, text)
		end
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.slotprogram.hover", run)
		end
		peek()
		return
	end
	run()
end

function SlotProgram.GetHover(slot)
	return hoverPrograms[tonumber(slot)]
end

function SlotProgram.GetAllHover()
	return hoverPrograms
end

function SlotProgram.HasHover()
	return next(hoverPrograms) ~= nil
end

local function BodyNeedsMouseoverRefresh(body)
	if type(body) ~= "string" or body == "" then
		return false
	end
	local u = body:upper()
	if u:find("#FLUX-NO-MO", 1, true) then
		return false
	end
	return u:find("MOUSEOVER", 1, true) ~= nil
end

local function DisplayBodyForSlot(slot, ufPeek)
	slot = tonumber(slot)
	if ufPeek then
		local hover = hoverPrograms[slot]
		if type(hover) == "string" and hover ~= "" then
			return hover
		end
	end
	return programs[slot]
end

--- Fingerprint-driven display refresh for strip overlay faces (no Binding Apply).
function SlotProgram.RefreshDisplays(ufPeek, mouseoverOnly, cols)
	if not Bars.ForEachHost then
		return
	end
	local PF = Bars.ProgramFace
	Bars.ForEachHost(function(host)
		local col = host.column
		if cols and col and not cols[col] then
			return
		end
		local slot = Bars.Hosts and Bars.Hosts.LiveSlot and Bars.Hosts.LiveSlot(host)
		if not slot or not programs[slot] then
			return
		end
		local body = host._fluxMacrotextDisplayBody or DisplayBodyForSlot(slot, ufPeek)
		if type(body) ~= "string" or body == "" then
			return
		end
		if mouseoverOnly and not ufPeek and not BodyNeedsMouseoverRefresh(body) then
			return
		end
		local mode = programModes[slot]
		if PF and PF.TranslateHost then
			PF.TranslateHost(host)
		elseif mode == "hidden" then
			if PF and PF.TranslateHost then
				PF.TranslateHost(host)
			end
		elseif mode == "display" or mode == "surface" then
			SyncSurfaceFace(host, body)
		end
		if Bars.Paint and Bars.Paint.Dirty then
			Bars.Paint.Dirty(host)
		end
	end)
end

function SlotProgram.ApplyStripDisplayOverrides(ufPeek)
	if not Bars.ForEachHost then
		return
	end
	Bars.ForEachHost(function(host)
		host._fluxMacrotextDisplayBody = nil
		if not ufPeek then
			return
		end
		local slot = Bars.Hosts and Bars.Hosts.LiveSlot and Bars.Hosts.LiveSlot(host)
		if not slot then
			return
		end
		local hoverBody = hoverPrograms[slot]
		if type(hoverBody) == "string" and hoverBody ~= "" then
			host._fluxMacrotextDisplayBody = hoverBody
		end
	end)
end

function SlotProgram.ReassertAll()
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.slotprogram", SlotProgram.ReassertAll)
		end
		return
	end
	if Bars.ForEachHost then
		Bars.ForEachHost(function(host)
			if host.widget then
				ApplyLiveType(host)
			end
		end)
	end
	for slot, text in pairs(programs) do
		WriteAllHosts(slot, text, programModes[slot])
	end
end

function SlotProgram.FlushCombatQueue()
	if InLockdown() then
		return
	end
	SlotProgram.ReassertAll()
end
