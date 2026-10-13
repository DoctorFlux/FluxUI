-- Bars/ProgramFace.lua — Extra TranslateMacro env on strip hosts (no extra widget).
-- Overlay click stays type=click onto a hidden SAB. This table only owns the
-- live face (SpellId / ItemId / MacroMode) so Bars.Paint and badges can follow
-- [mod]/[form]/[combat] the same way Extra window macros do.
local addonName, ns = ...
local Flux = ns.Flux
local Bars = Flux.Bars

local ProgramFace = {}
Bars.ProgramFace = ProgramFace
ns.FluxProgramFace = ProgramFace
_G.FluxProgramFace = ProgramFace

-- Last Extra identity per action slot. false = overlay parsed to nothing
-- (paint falls back to the native slot). nil = not translated yet.
local lastShown = {}
local shownFrame = nil
-- Shown() is asked several times per host per paint. Flat per-slot caches beat
-- one string key plus a { kind, id } table per slot per frame. kind == false
-- means "resolved to nothing"; nil means "not resolved yet".
local shownKindNormal, shownIdNormal = {}, {}
local shownKindPeek, shownIdPeek = {}, {}

local function ResetShownCache()
	shownFrame = nil
	for k in pairs(shownKindNormal) do
		shownKindNormal[k] = nil
		shownIdNormal[k] = nil
	end
	for k in pairs(shownKindPeek) do
		shownKindPeek[k] = nil
		shownIdPeek[k] = nil
	end
end

local function InvalidateShownSlot(slot)
	if not slot then
		return
	end
	lastShown[slot] = nil
	shownKindNormal[slot] = nil
	shownIdNormal[slot] = nil
	shownKindPeek[slot] = nil
	shownIdPeek[slot] = nil
end

local lastPeek = false
local peekPoller = nil
local peekPollAccum = 0
local PEEK_POLL = 0.05

local function CacheFrame()
	if GetTime then
		return GetTime()
	end
	return shownFrame
end

local function LiveSlot(host)
	if Bars.Hosts and Bars.Hosts.LiveSlot then
		return Bars.Hosts.LiveSlot(host)
	end
	return host and host.slot or nil
end

local function PeekContext()
	local km = _G.FluxMouseoverKeybindModule or ns.FluxMouseoverKeybind
	if km and km.IsHovercastPeekMouseContext then
		return km:IsHovercastPeekMouseContext() and true or false
	end
	return false
end

local function IdleMacro(text)
	if type(text) ~= "string" or text == "" then
		return text
	end
	local F = ns.FluxBindingMacroFactory or _G.FluxBindingMacroFactory3
	if F and F.IdleMacroText then
		return F.IdleMacroText(text)
	end
	return text
end

local function ProgramBody(slot)
	local SP = Bars.SlotProgram
	if not (slot and SP) then
		return nil
	end
	if PeekContext() and SP.GetHover then
		local hover = SP.GetHover(slot)
		if type(hover) == "string" and hover ~= "" then
			return hover
		end
	end
	local text = SP.Get and SP.Get(slot)
	if type(text) == "string" and text ~= "" then
		if SP.GetIdle then
			local idle = SP.GetIdle(slot)
			if type(idle) == "string" and idle ~= "" then
				return idle
			end
		end
		return IdleMacro(text)
	end
	return nil
end

function ProgramFace.BodyForSlot(slot)
	return ProgramBody(slot)
end

local function Remember(slot, face)
	if not slot then
		return
	end
	if face and face.MacroMode == "spell" and face.SpellId then
		lastShown[slot] = { "spell", face.SpellId }
		return
	end
	if face and face.MacroMode == "item" and face.ItemId then
		lastShown[slot] = { "item", face.ItemId }
		return
	end
	lastShown[slot] = false
end

local function PublishSlot(slot, face)
	Remember(slot, face)
	local Identity = Flux.Identity
	if not (slot and Identity and Identity.Publish) then
		return
	end
	local key = Identity.SlotKey(slot)
	if Identity.Register and not Identity.Has(key) then
		Identity.Register(key)
	end
	if face and face.MacroMode == "spell" and face.SpellId then
		Identity.Publish(key, "spell", face.SpellId)
	elseif face and face.MacroMode == "item" and face.ItemId then
		Identity.Publish(key, "item", face.ItemId)
	else
		Identity.Publish(key, nil, nil)
	end
end

function ProgramFace.NoteFace(slot, face)
	PublishSlot(slot, face)
end

local function ShownFromBody(body)
	local Shown = Flux.EBS and Flux.EBS.Action and Flux.EBS.Action.ShownFromBody
	if not Shown then
		return nil
	end
	return Shown(body)
end

--- Blizzard action-slot macros (dragged from the macro UI). Extra window
--- macros always TranslateMacro; the strip used to wait on GetActionTexture,
--- which does not re-parse [harm]/[combat]/[@mouseover] on those events.
local function SlotMacro(slot)
	if not slot or not GetActionInfo then
		return nil
	end
	local ok, actionType, id = pcall(GetActionInfo, slot)
	if not ok or actionType ~= "macro" or not id then
		return nil
	end
	if GetMacroInfo then
		local okInfo, _, _, body = pcall(GetMacroInfo, id)
		if okInfo and type(body) == "string" and body ~= "" then
			return body
		end
	end
	if GetMacroBody then
		local okBody, body = pcall(GetMacroBody, id)
		if okBody and type(body) == "string" and body ~= "" then
			return body
		end
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- Condition index: only bodies with `[` are re-parsed on events.
-- Plain spells/items stay on the mouseover-cast range sweep.
-- ---------------------------------------------------------------------------

local function EmptyNeed()
	return { mod = false, combat = false, target = false, mouseover = false, form = false, any = false }
end

-- Binding MacroFactory tags compiled native mouseover-cast tails with this
-- comment so display/index do not treat them as user [@mouseover]. Click
-- macros still contain the tail; hovercast UF bodies are not tagged.
local FACTORY_NO_MO = "#FLUX-NO-MO"

local function BodyHasUserMouseover(body)
	if type(body) ~= "string" or body == "" then
		return false
	end
	local u = string.upper(body)
	if string.find(u, FACTORY_NO_MO, 1, true) then
		return false
	end
	return string.find(u, "MOUSEOVER", 1, true) ~= nil
end

local function OrNeed(dst, src)
	if not src then
		return
	end
	if src.mod then
		dst.mod = true
	end
	if src.combat then
		dst.combat = true
	end
	if src.target then
		dst.target = true
	end
	if src.mouseover then
		dst.mouseover = true
	end
	if src.form then
		dst.form = true
	end
	if src.any then
		dst.any = true
	end
end

--- Classify a macro body into cond kinds. Exported so Extra TranslateMatching
--- uses the same tokens as the strip.
function ProgramFace.ClassifyBody(body)
	local n = EmptyNeed()
	if type(body) ~= "string" or body == "" then
		return n
	end
	if not string.find(body, "[", 1, true) then
		return n
	end
	n.any = true
	local u = string.upper(body)
	if string.find(u, "MOD", 1, true) then
		n.mod = true
	end
	if BodyHasUserMouseover(body) then
		n.mouseover = true
	end
	if string.find(u, "COMBAT", 1, true)
		or string.find(u, "MOUNTED", 1, true)
		or string.find(u, "FLYING", 1, true)
		or string.find(u, "SWIMMING", 1, true)
		or string.find(u, "FLYABLE", 1, true)
		or string.find(u, "INDOORS", 1, true)
		or string.find(u, "OUTDOORS", 1, true)
		or string.find(u, "STEALTH", 1, true)
		or string.find(u, "RESTING", 1, true)
		or string.find(u, "CHANNEL", 1, true)
		or string.find(u, "VEHICLE", 1, true)
		or string.find(u, "GROUP", 1, true)
		or string.find(u, "PARTY", 1, true)
		or string.find(u, "RAID", 1, true)
	then
		n.combat = true
	end
	if string.find(u, "HARM", 1, true)
		or string.find(u, "HELP", 1, true)
		or string.find(u, "@TARGET", 1, true)
		or string.find(u, "@FOCUS", 1, true)
		or string.find(u, "@PET", 1, true)
		or string.find(u, "EXISTS", 1, true)
		or string.find(u, "DEAD", 1, true)
		or string.find(u, "[PET", 1, true)
		or string.find(u, "[NOPET", 1, true)
	then
		n.target = true
	end
	if string.find(u, "FORM", 1, true)
		or string.find(u, "BONUSBAR", 1, true)
		or string.find(u, "STANCE", 1, true)
		or string.find(u, "STEALTH", 1, true)
		-- [bar:N] re-parses on plain page changes, which ride the same burst.
		or string.find(u, "[BAR", 1, true)
	then
		n.form = true
	end
	-- [spec]/[known]/… keep `any` so UPDATE_MACROS/login (`all`) still parse
	-- them. Do not mark mod/combat/target: a SHIFT tap or enemy tab must not
	-- SecureCmdOptionParse a [form:1] body. UMU already ignores non-mouseover.
	return n
end

local condSlots = {}
local condBodies = {}
local stripNeed = EmptyNeed()
local extraNeed = EmptyNeed()
local extraByKind = { mod = {}, combat = {}, target = {}, mouseover = {}, form = {}, any = {} }
local probeFlags = {
	mouseover = false,
	flying = false,
	mounted = false,
	flyable = false,
	swimming = false,
	indoors = false,
}
local indexDirty = true
local lastKindSig = { mod = nil, combat = nil, target = nil, mouseover = nil, form = nil }
local lastAllFrame = nil

local function EmptyExtraLists()
	return { mod = {}, combat = {}, target = {}, mouseover = {}, form = {}, any = {} }
end

local function NoteProbe(body)
	if type(body) ~= "string" or body == "" then
		return
	end
	local u = string.upper(body)
	if BodyHasUserMouseover(body) then
		probeFlags.mouseover = true
	end
	if string.find(u, "FLYING", 1, true) then
		probeFlags.flying = true
	end
	if string.find(u, "MOUNTED", 1, true) then
		probeFlags.mounted = true
	end
	if string.find(u, "FLYABLE", 1, true) then
		probeFlags.flyable = true
	end
	if string.find(u, "SWIMMING", 1, true) then
		probeFlags.swimming = true
	end
	if string.find(u, "INDOORS", 1, true) or string.find(u, "OUTDOORS", 1, true) then
		probeFlags.indoors = true
	end
end

local function PushExtra(kind, btn)
	local list = extraByKind[kind]
	list[#list + 1] = btn
end

local function FaceBody(slot)
	return ProgramBody(slot) or condBodies[slot] or SlotMacro(slot)
end

function ProgramFace.InvalidateIndex()
	indexDirty = true
	lastKindSig.mod = nil
	lastKindSig.combat = nil
	lastKindSig.target = nil
	lastKindSig.mouseover = nil
	lastKindSig.form = nil
	lastAllFrame = nil
end

function ProgramFace.RebuildIndex()
	indexDirty = false
	condSlots = {}
	condBodies = {}
	stripNeed = EmptyNeed()
	extraNeed = EmptyNeed()
	extraByKind = EmptyExtraLists()
	probeFlags = {
		mouseover = false,
		flying = false,
		mounted = false,
		flyable = false,
		swimming = false,
		indoors = false,
	}
	local SP = Bars.SlotProgram
	local function note(slot, body)
		slot = tonumber(slot)
		if not slot then
			return
		end
		NoteProbe(body)
		local n = ProgramFace.ClassifyBody(body)
		if not n.any then
			return
		end
		if not condSlots[slot] then
			condSlots[slot] = EmptyNeed()
		end
		OrNeed(condSlots[slot], n)
		OrNeed(stripNeed, n)
	end
	if SP then
		if SP.GetAll then
			for slot, body in pairs(SP.GetAll()) do
				slot = tonumber(slot)
				local display = (SP.GetIdle and SP.GetIdle(slot)) or IdleMacro(body)
				note(slot, display)
				if slot and condSlots[slot] and type(display) == "string" then
					condBodies[slot] = display
				end
			end
		end
		if SP.GetAllHover then
			for slot, body in pairs(SP.GetAllHover()) do
				note(slot, body)
			end
		end
	end
	local BH = Bars.BadgeHost
	if BH and BH.EachIndexedBody then
		BH.EachIndexedBody(function(slot, body)
			note(slot, body)
		end)
	end
	if Bars.ForEachHost then
		local seen = {}
		Bars.ForEachHost(function(host)
			local slot = LiveSlot(host)
			if not slot or seen[slot] or (SP and SP.Get and SP.Get(slot)) then
				return
			end
			seen[slot] = true
			local body = SlotMacro(slot)
			note(slot, body)
			local n = condSlots[slot]
			if n and n.any and type(body) == "string" then
				condBodies[slot] = body
			end
		end)
	end
	local EBS = Flux.EBS
	local list = EBS and EBS.buttons
	if list then
		for i = 1, #list do
			local btn = list[i]
			if btn and btn.kind ~= "strip" and btn.kind ~= "badge" and not btn.badgeMode
				and (btn.ActionType == "macro" or btn.ActionType == "macrotext")
			then
				NoteProbe(btn.MacroBody)
				local n = ProgramFace.ClassifyBody(btn.MacroBody)
				OrNeed(extraNeed, n)
				if n.any then
					PushExtra("any", btn)
					if n.mod then
						PushExtra("mod", btn)
					end
					if n.combat then
						PushExtra("combat", btn)
					end
					if n.target then
						PushExtra("target", btn)
					end
					if n.mouseover then
						PushExtra("mouseover", btn)
					end
					if n.form then
						PushExtra("form", btn)
					end
				end
			end
		end
	end
	if ProgramFace.ArmMouseoverPoll then
		ProgramFace.ArmMouseoverPoll()
	end
	local Watch = Bars.Watch
	if Watch and Watch.SyncRangeSlots then
		Watch.SyncRangeSlots()
	end
end

local function EnsureIndex()
	if indexDirty then
		ProgramFace.RebuildIndex()
	end
end

function ProgramFace.Needs(kind)
	EnsureIndex()
	if not kind or kind == "all" then
		return (stripNeed.any or extraNeed.any) and true or false
	end
	return (stripNeed[kind] or extraNeed[kind]) and true or false
end

local function KindWanted(need, kinds)
	if not need or not need.any then
		return false
	end
	if not kinds or kinds.all then
		return true
	end
	if kinds.mod and need.mod then
		return true
	end
	if kinds.combat and need.combat then
		return true
	end
	if kinds.target and need.target then
		return true
	end
	if kinds.mouseover and need.mouseover then
		return true
	end
	if kinds.form and need.form then
		return true
	end
	return false
end

function ProgramFace.KindWanted(need, kinds)
	return KindWanted(need, kinds)
end

function ProgramFace.ProbeFlags()
	EnsureIndex()
	return probeFlags
end

local function ExtraParked(btn)
	if btn and btn.badgeMode then
		return false
	end
	local Paint = Flux.EBS and Flux.EBS.Paint
	return Paint and Paint.IsParked and Paint.IsParked(btn)
end

function ProgramFace.EachExtraMatching(kinds, fn)
	if type(fn) ~= "function" then
		return
	end
	EnsureIndex()
	kinds = kinds or { all = true }
	if kinds.all then
		local list = extraByKind.any
		for i = 1, #list do
			local btn = list[i]
			if btn and not ExtraParked(btn) then
				fn(btn)
			end
		end
		return
	end
	local seen = {}
	local function walk(list)
		if not list then
			return
		end
		for i = 1, #list do
			local btn = list[i]
			if btn and not seen[btn] and not ExtraParked(btn) then
				seen[btn] = true
				fn(btn)
			end
		end
	end
	if kinds.mod then
		walk(extraByKind.mod)
	end
	if kinds.combat then
		walk(extraByKind.combat)
	end
	if kinds.target then
		walk(extraByKind.target)
	end
	if kinds.mouseover then
		walk(extraByKind.mouseover)
	end
	if kinds.form then
		walk(extraByKind.form)
	end
end

local pendingKinds = {}
local condStamp = 0

local function BumpStamp()
	condStamp = condStamp + 1
end

local function TakePending()
	local kinds = pendingKinds
	pendingKinds = {}
	return kinds
end

function ProgramFace.TranslateAll()
	if not Bars.ForEachHost then
		return
	end
	BumpStamp()
	EnsureIndex()
	local SP = Bars.SlotProgram
	Bars.ForEachHost(function(host)
		local slot = LiveSlot(host)
		if not slot then
			return
		end
		if condSlots[slot] or (SP and SP.GetHover and SP.GetHover(slot)) then
			ProgramFace.TranslateHost(host)
		end
	end)
end

--- Overlay + hover + indexed slot-macro bodies. No GetActionInfo on plain spells.
function ProgramFace.EachBody(fn)
	if type(fn) ~= "function" then
		return
	end
	EnsureIndex()
	local function walk(map)
		if type(map) ~= "table" then
			return
		end
		for _, text in pairs(map) do
			if type(text) == "string" and text ~= "" then
				fn(text)
			end
		end
	end
	local SP = Bars.SlotProgram
	if SP then
		walk(SP.GetAllHover and SP.GetAllHover())
		if SP.GetAll then
			for slot, text in pairs(SP.GetAll()) do
				if type(text) == "string" and text ~= "" then
					local display = (SP.GetIdle and SP.GetIdle(slot)) or IdleMacro(text) or text
					fn(display)
				end
			end
		end
	end
	for _, body in pairs(condBodies) do
		fn(body)
	end
end

local function TranslateMatching(kinds)
	if not Bars.ForEachHost then
		return
	end
	EnsureIndex()
	Bars.ForEachHost(function(host)
		local slot = LiveSlot(host)
		if slot and KindWanted(condSlots[slot], kinds) then
			ProgramFace.TranslateHost(host)
		end
	end)
end

local function After(delay, fn)
	local after = (Flux.Timer and Flux.Timer.After) or (C_Timer and C_Timer.After)
	if after then
		after(delay, fn)
	else
		fn()
	end
end

local function UnitNameSafe(unit)
	if not unit or not UnitName then
		return nil
	end
	local ok, name = pcall(UnitName, unit)
	if ok and type(name) == "string" and name ~= "" then
		return name
	end
	return nil
end

local function UnitClass(unit)
	local R = Flux.Range
	if R and R.UnitReactionClass then
		return R.UnitReactionClass(unit)
	end
	return "-"
end

local function ReactionClass()
	local R = Flux.Range
	if R and R.MouseoverReactionClass then
		return R.MouseoverReactionClass()
	end
	return UnitClass("mouseover")
end

local function SafeBit(fn, a)
	if type(fn) ~= "function" then
		return "0"
	end
	local ok, v
	if a ~= nil then
		ok, v = pcall(fn, a)
	else
		ok, v = pcall(fn)
	end
	return (ok and v) and "1" or "0"
end

local function GroupBit()
	if IsInRaid then
		local ok, v = pcall(IsInRaid)
		if ok and v then
			return "r"
		end
	end
	if GetNumRaidMembers then
		local ok, n = pcall(GetNumRaidMembers)
		if ok and type(n) == "number" and n > 0 then
			return "r"
		end
	end
	if IsInGroup then
		local ok, v = pcall(IsInGroup)
		if ok and v then
			return "p"
		end
	end
	if GetNumPartyMembers then
		local ok, n = pcall(GetNumPartyMembers)
		if ok and type(n) == "number" and n > 0 then
			return "p"
		end
	end
	if GetNumGroupMembers then
		local ok, n = pcall(GetNumGroupMembers)
		if ok and type(n) == "number" and n > 0 then
			return "g"
		end
	end
	return "0"
end

local function ChannelBit()
	if type(UnitChannelInfo) ~= "function" then
		return "0"
	end
	local ok, name = pcall(UnitChannelInfo, "player")
	return (ok and type(name) == "string" and name ~= "") and "1" or "0"
end

-- Snapshots, not names: two enemies (or two friends) are the same [harm]/[help]
-- face. Distance stays on the range ticker.
local function ModSig()
	return SafeBit(IsShiftKeyDown) .. SafeBit(IsControlKeyDown) .. SafeBit(IsAltKeyDown)
end

local function CombatSig()
	return SafeBit(UnitAffectingCombat, "player")
		.. SafeBit(IsMounted)
		.. SafeBit(IsFlying)
		.. SafeBit(IsSwimming)
		.. SafeBit(IsFlyableArea)
		.. SafeBit(IsIndoors)
		.. SafeBit(IsStealthed)
		.. SafeBit(IsResting)
		.. GroupBit()
		.. ChannelBit()
		.. SafeBit(UnitInVehicle, "player")
end

local function TargetSig()
	return UnitClass("target") .. UnitClass("focus") .. UnitClass("pet") .. UnitClass("targettarget")
end

local function SafeNum(fn)
	if type(fn) ~= "function" then
		return 0
	end
	local ok, v = pcall(fn)
	if not ok then
		return 0
	end
	return tonumber(v) or 0
end

local function PageSig()
	if C_ActionBar and C_ActionBar.GetActionBarPage then
		return SafeNum(C_ActionBar.GetActionBarPage)
	end
	return SafeNum(GetActionBarPage)
end

local function FormSig()
	-- Page rides the same signature: [bar:N] bodies must re-parse on a plain
	-- page change even when form/bonus/stealth are unchanged.
	return SafeNum(GetShapeshiftForm) .. ":" .. SafeNum(GetBonusBarOffset)
		.. ":" .. PageSig() .. ":" .. SafeBit(IsStealthed)
end

local function SameKind(kind)
	local sig
	if kind == "mod" then
		sig = ModSig()
	elseif kind == "combat" then
		sig = CombatSig()
	elseif kind == "target" then
		sig = TargetSig()
	elseif kind == "form" then
		sig = FormSig()
	else
		return false
	end
	if lastKindSig[kind] == sig then
		return true
	end
	lastKindSig[kind] = sig
	return false
end

-- World hops: same 0.2s quiet window as Flux.Range / Watch usable. UF hover
-- peek stays snappy (raid-grid OnEnter is not a nameplate sweep).
ProgramFace.MOUSEOVER_COALESCE = 0.2
local MOUSEOVER_COALESCE = 0.2
local HOVER_PEEK_COALESCE = 0.07
local MO_POLL_KEY = "flux.cond.mo"
local MO_POLL_INTERVAL = 0.07
local minFlushInterval = 0.05
local lastFlushAt = 0
local flushRetryPending = false
local moPending = false
local moPollName = nil
local moPollArmed = false
local moPollAccum = 0
local lastUmuAt = 0
local moDueAt = 0

local function ScheduleCond(kind)
	pendingKinds[kind] = true
	if Flux.Scheduler and Flux.Scheduler.Request then
		Flux.Scheduler.Request("eval", "flux.cond")
		return
	end
	ProgramFace.FlushPending(nil)
end

function ProgramFace.RequestTarget()
	ProgramFace.Request("target")
end

--- One parse after the cursor is quiet. Empty is a real parse so [@mouseover]
--- faces drop; gaps during a sweep never reach here.
local function RequestMouseoverNow()
	EnsureIndex()
	if not ProgramFace.Needs("mouseover") then
		return
	end
	local class = ReactionClass()
	if class == lastKindSig.mouseover then
		return
	end
	lastKindSig.mouseover = class
	ScheduleCond("mouseover")
end

function ProgramFace.NoteMouseoverEvent()
	lastUmuAt = GetTime and GetTime() or 0
	-- Do not RebuildIndex on the hop event. A clean index already knows
	-- whether any body has user [@mouseover]; a dirty index waits for
	-- the trailing parse.
	if not indexDirty and not stripNeed.mouseover and not extraNeed.mouseover then
		return
	end
	-- Trailing debounce: parse once after the cursor stops, never during the
	-- hop storm. Same on Classic and Retail.
	moDueAt = lastUmuAt + MOUSEOVER_COALESCE
	if moPending then
		return
	end
	moPending = true
	local function fire()
		local now = GetTime and GetTime() or 0
		if now < moDueAt then
			After(moDueAt - now, fire)
			return
		end
		moPending = false
		RequestMouseoverNow()
	end
	After(MOUSEOVER_COALESCE, fire)
end

local function RequestMouseover()
	ProgramFace.NoteMouseoverEvent()
end

function ProgramFace.ArmMouseoverPoll()
	EnsureIndex()
	if not probeFlags.mouseover then
		if moPollArmed and Flux.Ticker and Flux.Ticker.Remove then
			Flux.Ticker.Remove(MO_POLL_KEY)
		end
		moPollArmed = false
		return
	end
	if moPollArmed then
		return
	end
	if not (Flux.Ticker and Flux.Ticker.Add) then
		return
	end
	moPollArmed = true
	moPollAccum = 0
	Flux.Ticker.Add(MO_POLL_KEY, function(elapsed)
		-- UMU already parsed during a sweep. This poll only covers leave-to-empty
		-- frames the client sometimes skips; it must not run UnitName 60+ times
		-- a second while the cursor is moving.
		local now = GetTime and GetTime() or 0
		if lastUmuAt > 0 and (now - lastUmuAt) < MOUSEOVER_COALESCE then
			moPollAccum = 0
			return
		end
		moPollAccum = moPollAccum + (elapsed or 0)
		if moPollAccum < MO_POLL_INTERVAL then
			return
		end
		moPollAccum = 0
		local class = ReactionClass()
		if class == moPollName then
			return
		end
		moPollName = class
		RequestMouseoverNow()
	end)
end

local function IsMouseoverOnly(kinds)
	return kinds.mouseover and not kinds.all and not kinds.mod and not kinds.combat
		and not kinds.target and not kinds.form
end

--- Scheduler eval listener (Bars.Init) calls this before Paint.Flush so
--- overlay faces are current in the same coalesced pass.
function ProgramFace.SetMouseoverPollInterval(sec)
	sec = tonumber(sec)
	if not sec then
		return
	end
	if sec < 0.04 then
		sec = 0.04
	elseif sec > 0.2 then
		sec = 0.2
	end
	MO_POLL_INTERVAL = sec
end

function ProgramFace.SetMinFlushInterval(sec)
	sec = tonumber(sec)
	if not sec then
		minFlushInterval = 0
		return
	end
	if sec < 0 then
		sec = 0
	elseif sec > 0.5 then
		sec = 0.5
	end
	minFlushInterval = sec
end

function ProgramFace.FlushPending(tokens)
	if minFlushInterval and minFlushInterval > 0 then
		local now = GetTime and GetTime() or 0
		if lastFlushAt > 0 and (now - lastFlushAt) < minFlushInterval then
			if not flushRetryPending then
				flushRetryPending = true
				After(minFlushInterval - (now - lastFlushAt), function()
					flushRetryPending = false
					ProgramFace.FlushPending(tokens)
				end)
			end
			return
		end
		lastFlushAt = now
	end
	local kinds = TakePending()
	if not kinds.all and not kinds.mod and not kinds.combat and not kinds.target
		and not kinds.mouseover and not kinds.form
	then
		return
	end
	BumpStamp()
	EnsureIndex()
	local Action = Flux.EBS and Flux.EBS.Action
	if Action and Action.TranslateMatching then
		Action.TranslateMatching(kinds)
	end
	local mouseoverOnly = IsMouseoverOnly(kinds)
	local stripHit = KindWanted(stripNeed, kinds)
	if stripHit then
		TranslateMatching(kinds)
	end
	local BH = Bars.BadgeHost
	if not mouseoverOnly then
		-- Badge reverse may be the only [mod]/[harm] consumer. Still reparse
		-- and settle vis so the idle face returns when the condition drops.
		local badgeHit = stripHit or kinds.mod or kinds.all or kinds.target or kinds.combat or kinds.form
		if badgeHit then
			if kinds.mod or kinds.all or kinds.target or kinds.combat or kinds.form then
				if BH and BH.RefreshDisplays then
					BH.RefreshDisplays()
				end
			end
			if BH and BH.SyncShownFaces then
				BH.SyncShownFaces()
			end
		end
	elseif stripHit and Bars.BadgeHost and Bars.BadgeHost.RefreshMouseoverDisplays then
		Bars.BadgeHost.RefreshMouseoverDisplays()
	end
	-- ButtonForge: events only set RefConditional. TranslateMacro then
	-- FullRefresh only the faces whose shown action actually changed.
	-- Do not 6-lane every live host on a [mod]/[harm] hop.
	if Action and Action.SyncMacroProbes then
		Action.SyncMacroProbes()
	end
	ProgramFace.ArmMouseoverPoll()
end

function ProgramFace.Request(kind)
	kind = kind or "all"
	if kind == "mouseover" then
		RequestMouseover()
		return
	end
	EnsureIndex()
	if kind ~= "all" and not ProgramFace.Needs(kind) then
		return
	end
	if kind == "all" and not ProgramFace.Needs("all") then
		return
	end
	if kind == "all" then
		local t = GetTime and GetTime() or 0
		if lastAllFrame == t then
			return
		end
		lastAllFrame = t
		lastKindSig.mod = ModSig()
		lastKindSig.combat = CombatSig()
		lastKindSig.target = TargetSig()
		lastKindSig.form = FormSig()
	elseif SameKind(kind) then
		return
	end
	ScheduleCond(kind)
end

--- Extra paints inside TranslateMacro. Strip faces return before that.
--- Event handlers must not Flush here: one eval pass translates then paints.
function ProgramFace.RequestConditionalRefresh()
	ProgramFace.Request("all")
end

function ProgramFace.HasAny()
	local SP = Bars.SlotProgram
	if SP then
		if SP.HasAny and SP.HasAny() then
			return true
		end
		if SP.HasHover and SP.HasHover() then
			return true
		end
	end
	EnsureIndex()
	return stripNeed.any and true or false
end

--- Keep MacroBody in lockstep with the live slot: Binding overlay first, else
--- a Blizzard macro sitting in the action slot. Always macrotext so Extra's
--- SecureCmdOptionParse path runs (GetMacroSpell lags on Classic).
function ProgramFace.SyncHost(host)
	if not host then
		return nil
	end
	local slot = LiveSlot(host)
	host._fluxFaceSlot = slot
	local body = FaceBody(slot)
	local face = (host.widget and host.widget.FluxButton) or host.btn or host._fluxFace
	if not body then
		if face then
			face.ActionType = nil
			face.ActionValue = nil
			face.MacroBody = nil
			face.MacroIndex = nil
			face.MacroMode = ""
			face.SpellId = nil
			face.ItemId = nil
			face.MacroTexture = nil
			face.MacroTarget = nil
			face._fluxStripFace = nil
		end
		host._fluxFace = face
		host._fluxCondStamp = nil
		if slot then
			InvalidateShownSlot(slot)
			PublishSlot(slot, nil)
		end
		return nil
	end
	if not face then
		face = {
			ActionType = "macrotext",
			_fluxStripFace = true,
			kind = "strip",
		}
	end
	local bodyChanged = face.MacroBody ~= body
	face.ActionType = "macrotext"
	face.ActionValue = body
	face.MacroBody = body
	face.MacroIndex = nil
	face._fluxStripFace = true
	face.kind = face.kind or "strip"
	-- Drop the previous slot's parsed identity until TranslateMacro runs.
	if bodyChanged then
		face.SpellId = nil
		face.ItemId = nil
		face.MacroMode = ""
		face.MacroTexture = nil
		face.MacroTarget = nil
	end
	-- badgeMode is a rank/layout flag for corner badges, not the overlay env.
	if face.kind == "strip" then
		face.badgeMode = false
	end
	face.WIcon = host.WIcon or face.WIcon
	face.WCount = host.WCount or face.WCount
	host._fluxFace = face
	host.btn = face
	InvalidateShownSlot(slot)
	return face
end

--- deferPaint: parse + Identity only. Caller MarkDirty / RequestPaint flushes.
function ProgramFace.TranslateHost(host, deferPaint)
	local face = ProgramFace.SyncHost(host)
	local slot = LiveSlot(host)
	if not face then
		return
	end
	local beforeSpell, beforeItem = face.SpellId, face.ItemId
	local beforeMode, beforeTex = face.MacroMode, face.MacroTexture
	local Action = Flux.EBS and Flux.EBS.Action
	if Action and Action.TranslateMacro then
		pcall(Action.TranslateMacro, face)
	end
	host._fluxCondStamp = condStamp
	PublishSlot(slot, face)
	-- MacroTarget (mouseover vs target) is range-only. Same shown spell must
	-- not FullRefresh icon/cooldown/glow on every unit↔gap hop.
	if face.SpellId ~= beforeSpell or face.ItemId ~= beforeItem
		or face.MacroMode ~= beforeMode
		or face.MacroTexture ~= beforeTex
	then
		if Bars.Paint and Bars.Paint.ClearCache then
			Bars.Paint.ClearCache(host)
		end
		if deferPaint then
			return
		end
		if Bars.Paint and Bars.Paint.UpdateDisplay then
			Bars.Paint.UpdateDisplay(host)
		elseif Bars.Paint and Bars.Paint.UpdateAll then
			Bars.Paint.UpdateAll(host)
		end
		-- Badge columns wait for SyncShownFaces so reverse Identity exists.
		local BH = Bars.BadgeHost
		local hasBadge = BH and BH.GetSlotBadges and slot and BH.GetSlotBadges(slot)
		if not hasBadge and Bars.Effects and Bars.Effects.Refresh then
			Bars.Effects.Refresh(host)
		end
	end
end

function ProgramFace.ShownForSlot(slot)
	slot = tonumber(slot)
	if not slot then
		return nil
	end
	local Identity = Flux.Identity
	if Identity and Identity.Get and Identity.SlotKey then
		local kind, id = Identity.Get(Identity.SlotKey(slot))
		if kind then
			return kind, id
		end
	end
	local body = FaceBody(slot)
	if body then
		return ShownFromBody(body)
	end
	local rec = lastShown[slot]
	if rec and rec ~= false then
		return rec[1], rec[2]
	end
	return nil
end

--- Extra env identity for this host. Re-parse like LAB (same-frame cache).
function ProgramFace.Shown(host)
	local slot = LiveSlot(host)
	local now = CacheFrame()
	local peeking = PeekContext()
	if now ~= shownFrame then
		ResetShownCache()
		shownFrame = now
	end
	local kindCache = peeking and shownKindPeek or shownKindNormal
	local idCache = peeking and shownIdPeek or shownIdNormal
	if slot then
		local cached = kindCache[slot]
		if cached ~= nil then
			if cached == false then
				return nil
			end
			return cached, idCache[slot]
		end
	end
	if slot and not peeking then
		local Identity = Flux.Identity
		if Identity and Identity.Get and Identity.SlotKey then
			local kind, id = Identity.Get(Identity.SlotKey(slot))
			if kind then
				kindCache[slot] = kind
				idCache[slot] = id
				return kind, id
			end
		end
	end
	EnsureIndex()
	local body = ProgramBody(slot) or condBodies[slot]
	if not body then
		if slot then
			kindCache[slot] = false
		end
		return nil
	end
	local face = host and host._fluxFace
	-- Reuse the cond-pass / TranslateHost face. Do not parse twice in one paint.
	-- Face identity is only valid for the slot SyncHost last bound.
	local reuse = face and face.MacroBody == body and host._fluxFaceSlot == slot
		and host._fluxCondStamp == condStamp
	if not reuse then
		ProgramFace.TranslateHost(host)
		face = host and host._fluxFace
	end
	local kind, id
	if face then
		if face.MacroMode == "spell" and face.SpellId then
			kind, id = "spell", face.SpellId
		elseif face.MacroMode == "item" and face.ItemId then
			kind, id = "item", face.ItemId
		end
	end
	if not kind then
		kind, id = ProgramFace.ShownForSlot(slot)
	end
	if slot then
		kindCache[slot] = kind or false
		idCache[slot] = id
	end
	return kind, id
end

local function ArmPeekPoller()
	local SP = Bars.SlotProgram
	if not (SP and SP.HasHover and SP.HasHover()) then
		if peekPoller then
			peekPoller:Hide()
		end
		return
	end
	if not peekPoller then
		peekPoller = CreateFrame("Frame")
		peekPoller:Hide()
		peekPoller:SetScript("OnUpdate", function(self, elapsed)
			peekPollAccum = peekPollAccum + elapsed
			if peekPollAccum < PEEK_POLL then
				return
			end
			peekPollAccum = 0
			local peek = PeekContext()
			local hasHover = SP.HasHover and SP.HasHover()
			if peek ~= lastPeek then
				ProgramFace.RequestHoverPeek()
			elseif not peek and not hasHover then
				self:Hide()
			end
		end)
	end
	peekPollAccum = 0
	peekPoller:Show()
end

local peekPending = false
local lastPeekFp = nil

local function PeekFingerprint()
	local peek = PeekContext()
	local class = ReactionClass()
	local name = UnitNameSafe("mouseover")
	return (peek and "1" or "0") .. ":" .. tostring(class) .. ":" .. tostring(name or "")
end

local function TranslateHoverSlots()
	local SP = Bars.SlotProgram
	local hover = SP and SP.GetAllHover and SP.GetAllHover()
	if type(hover) ~= "table" then
		return
	end
	if not Bars.ForEachHost then
		return
	end
	Bars.ForEachHost(function(host)
		local slot = LiveSlot(host)
		if not slot or hover[slot] == nil then
			return
		end
		local text = hover[slot]
		if type(text) ~= "string" or text == "" then
			return
		end
		ProgramFace.TranslateHost(host)
		if Bars.Paint and Bars.Paint.Dirty then
			Bars.Paint.Dirty(host)
		end
	end)
end

--- UF OnEnter/OnLeave + leave-frame poller. Not UPDATE_MOUSEOVER_UNIT.
--- Keyboard [@mouseover] overlays use the UMU coalescer. Hover-only SlotProgram
--- bodies are 70ms-coalesced and never walk every overlay or retrigger VFX.
function ProgramFace.RequestHoverPeek()
	local SP = Bars.SlotProgram
	if not (SP and SP.HasHover and SP.HasHover()) then
		if peekPoller then
			peekPoller:Hide()
		end
		return
	end
	local fp = PeekFingerprint()
	if fp == lastPeekFp then
		ArmPeekPoller()
		return
	end
	if peekPending then
		return
	end
	peekPending = true
	After(HOVER_PEEK_COALESCE, function()
		peekPending = false
		if not (SP and SP.HasHover and SP.HasHover()) then
			if peekPoller then
				peekPoller:Hide()
			end
			return
		end
		local fp2 = PeekFingerprint()
		if fp2 == lastPeekFp then
			ArmPeekPoller()
			return
		end
		lastPeekFp = fp2
		ResetShownCache()
		lastPeek = PeekContext()
		TranslateHoverSlots()
		if Bars.RequestPaint then
			Bars.RequestPaint("bars.icon")
			Bars.RequestPaint("bars.count")
			Bars.RequestPaint("bars.checked")
			Bars.RequestPaint("bars.range")
		end
		ArmPeekPoller()
	end)
end

local function ContextKinds(info)
	local kinds = {}
	if type(info) ~= "table" then
		return { all = true }
	end
	-- Form bursts stay narrow: Context force-sets all/force alongside form,
	-- so form must win or every [mod]/[harm] body reparses on each shift.
	if info.form then
		kinds.form = true
		return kinds
	end
	if info.all or info.force then
		kinds.all = true
		return kinds
	end
	if info.mods then
		kinds.mod = true
	end
	if info.combat then
		kinds.combat = true
	end
	if info.target then
		kinds.target = true
	end
	if info.mouseover then
		kinds.mouseover = true
	end
	return kinds
end

local function ContextHasKind(kinds)
	return kinds.all or kinds.mod or kinds.combat or kinds.target or kinds.mouseover or kinds.form
end

--- Display-tier hop bus. Kinded: only indexed surfaces that need the change.
function ProgramFace.OnContext(info, mouseoverOnly, ufPeek)
	if type(info) ~= "table" then
		info = {
			mouseoverOnly = info and true or false,
			ufPeek = ufPeek,
			all = not info,
			mouseover = true,
		}
	end
	local SP = Bars.SlotProgram
	if info.ufPeekChanged and SP and SP.ApplyStripDisplayOverrides then
		SP.ApplyStripDisplayOverrides(info.ufPeek)
	end
	local kinds = ContextKinds(info)
	if not ContextHasKind(kinds) then
		if info.ufPeekChanged then
			local BH = Bars.BadgeHost
			if BH and BH.RefreshDisplays then
				BH.RefreshDisplays(info.ufPeek)
			end
			if BH and BH.SyncShownFaces then
				BH.SyncShownFaces()
			end
			ProgramFace.RequestHoverPeek()
		end
		return
	end
	EnsureIndex()
	local stripHit = kinds.all or KindWanted(stripNeed, kinds)
	local extraHit = kinds.all or KindWanted(extraNeed, kinds)
	if not stripHit and not extraHit then
		if kinds.mod or kinds.combat or kinds.target then
			local BH = Bars.BadgeHost
			if BH and BH.RefreshDisplays then
				BH.RefreshDisplays(info.ufPeek)
			end
			if BH and BH.SyncShownFaces then
				BH.SyncShownFaces()
			end
		end
		if info.ufPeekChanged then
			local BH = Bars.BadgeHost
			if BH and BH.RefreshDisplays then
				BH.RefreshDisplays(info.ufPeek)
			end
			if BH and BH.SyncShownFaces then
				BH.SyncShownFaces()
			end
			ProgramFace.RequestHoverPeek()
		end
		return
	end
	BumpStamp()
	local Action = Flux.EBS and Flux.EBS.Action
	if extraHit and Action and Action.TranslateMatching then
		Action.TranslateMatching(kinds)
	end
	if stripHit then
		TranslateMatching(kinds)
	end
	local BH = Bars.BadgeHost
	local light = IsMouseoverOnly(kinds)
	if stripHit then
		if light then
			if BH and BH.RefreshMouseoverDisplays then
				BH.RefreshMouseoverDisplays(info.ufPeek)
			end
		else
			if BH and BH.RefreshDisplays then
				BH.RefreshDisplays(info.ufPeek)
			end
			if info.form and BH and BH.RefreshFormVisibility then
				BH.RefreshFormVisibility()
			end
			if BH and BH.SyncShownFaces then
				BH.SyncShownFaces()
			end
		end
	end
	if Action and Action.SyncMacroProbes then
		Action.SyncMacroProbes()
	end
	if info.ufPeekChanged then
		ProgramFace.RequestHoverPeek()
	end
	-- TranslateHost UpdateDisplays a host whose shown face changed. Badge
	-- vis + Effects.Refresh run after reverse publish (SyncShownFaces).
	-- Overlay-only columns Effects.Refresh inside TranslateHost.
end

local started = false

function ProgramFace.ContextOwnsDisplay()
	local C = Flux.Context
	return C and C.HasSubscribers and C.HasSubscribers() and true or false
end

function ProgramFace.Start()
	if started then
		return
	end
	started = true
	local C = Flux.Context
	if C and C.Subscribe then
		C.Subscribe(ProgramFace.OnContext)
	end
	local Identity = Flux.Identity
	if Identity and Identity.OnChange then
		Identity.OnChange(function(key)
			local BH = Bars.BadgeHost
			if BH and BH.OnIdentityChange then
				BH.OnIdentityChange(key)
			end
			local Hosts = Bars.Hosts
			if Hosts and Hosts.RefreshHoverTooltip then
				Hosts.RefreshHoverTooltip()
			end
		end)
	end
end
