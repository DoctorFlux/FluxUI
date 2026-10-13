-- Bars/BadgeHost.lua — action-ID corner stacks on Flux strip hosts.
-- One stack per host that can display the slot. Combat visibility is alpha only.
local addonName, ns = ...
local Flux = ns.Flux
local Bars = Flux.Bars

local BadgeHost = {}
Bars.BadgeHost = BadgeHost
ns.FluxBadgeHost = BadgeHost
_G.FluxBadgeHost = BadgeHost
_G.FluxBindingMaxCornerBadges = 3

local MAX_BADGES = 3
BadgeHost.MAX_BADGES = MAX_BADGES

local slotBadges = {}
-- instances[widget][slot] = { badge, ... }
local instances = {}
local combatDirty = {}
local compactHosts = {}

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local slotToColumn = nil

local function BuildSlotToColumn()
	local State = Bars.State
	if not State then
		return
	end
	slotToColumn = {}
	for col = 1, (Bars.NUM_COLUMNS or 19) do
		local sec = State.GetSecondarySlot(col)
		if sec then
			slotToColumn[sec] = col
		end
		local tert = State.GetTertiarySlot(col)
		if tert then
			slotToColumn[tert] = col
		end
		for page = 0, 18 do
			local main = State.GetMainSlot(col, page)
			if main then
				slotToColumn[main] = col
			end
		end
	end
end

local function LocateColumn(slot)
	slot = tonumber(slot)
	if not slot then
		return nil
	end
	if not slotToColumn then
		BuildSlotToColumn()
	end
	if slotToColumn and slotToColumn[slot] then
		return slotToColumn[slot]
	end
	return nil
end

local function HostsForColumn(col)
	local rec = Bars.GetHost and Bars.GetHost(col)
	if not rec then
		return nil
	end
	return rec
end

local function LiveSlotOf(host)
	if Bars.Hosts and Bars.Hosts.LiveSlot then
		return Bars.Hosts.LiveSlot(host)
	end
	return host and host.slot
end

local function CurrentFormToken()
	local Forms = ns.FluxBindingForms or _G.FluxBindingForms3
	if Forms and Forms.GetCurrentToken then
		return Forms.GetCurrentToken() or "noform"
	end
	return "noform"
end

local function SlotHasAction(slot)
	if not slot then
		return false
	end
	local fn = (C_ActionBar and C_ActionBar.HasAction) or HasAction
	if not fn then
		return true
	end
	local ok, has = pcall(fn, slot)
	if not ok or has == nil then
		return true
	end
	if Flux.Secrets and Flux.Secrets.SafeBooleanTest then
		-- Secret boolean: keep the corner. A real false still hides an empty slot.
		return Flux.Secrets.SafeBooleanTest(has, true) and true or false
	end
	return has and true or false
end

local function SlotOnCooldown(slot)
	if not slot then
		return false
	end
	local A = Flux.Action
	if A and A.GetCooldown then
		local start, duration = A.GetCooldown(slot)
		start = tonumber(start) or 0
		duration = tonumber(duration) or 0
		return duration > 1.5 and start > 0
	end
	return false
end

local function PeekingUf()
	local km = _G.FluxMouseoverKeybindModule or ns.FluxMouseoverKeybind
	return km and km.IsHovercastPeekMouseContext and km:IsHovercastPeekMouseContext() and true or false
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

local function WantDisplayMacrotext(want)
	if not want then
		return nil
	end
	if PeekingUf() and type(want.hoverMacrotext) == "string" and want.hoverMacrotext ~= "" then
		return want.hoverMacrotext
	end
	if type(want.macrotext) == "string" and want.macrotext ~= "" then
		return IdleMacro(want.macrotext)
	end
	return nil
end

local function ShownSpellOnSlot(slot)
	local PF = Bars.ProgramFace
	if PF and PF.ShownForSlot then
		local kind, id = PF.ShownForSlot(slot)
		if kind == "spell" then
			return tonumber(id) or id
		end
	end
	local body = PF and PF.BodyForSlot and PF.BodyForSlot(slot)
	if type(body) ~= "string" or body == "" then
		local SP = Bars.SlotProgram
		body = SP and SP.Get and SP.Get(slot)
	end
	if type(body) == "string" and body ~= "" then
		local Shown = Flux.EBS and Flux.EBS.Action and Flux.EBS.Action.ShownFromBody
		if Shown then
			local kind, id = Shown(body)
			if kind == "spell" then
				return tonumber(id) or id
			end
		end
	end
	if Flux.ButtonFX and Flux.ButtonFX.SpellIdFromAction then
		return Flux.ButtonFX.SpellIdFromAction(slot)
	end
	return nil
end

-- Live Extra identity of the badge: reverse macrotext via the same parser as
-- TranslateMacro. Frozen want.spellId only when there is no reverse body.
local function BadgeShownSpell(want)
	if not want then
		return nil
	end
	local text = WantDisplayMacrotext(want)
	if type(text) == "string" and text ~= "" then
		local Shown = Flux.EBS and Flux.EBS.Action and Flux.EBS.Action.ShownFromBody
		if Shown then
			local kind, id = Shown(text)
			if kind == "spell" then
				return tonumber(id) or id
			end
		end
		return nil
	end
	return want.spellId
end

local function SameShownSpell(a, b)
	if not a or not b then
		return false
	end
	local Match = Flux.Spell and Flux.Spell.IdsMatch
	if Match and Match(a, b) then
		return true
	end
	return a == b
end

local function SameShownFace(kindA, idA, kindB, idB)
	if not kindA or not kindB or kindA ~= kindB then
		return false
	end
	if kindA == "spell" then
		local Match = Flux.Spell and Flux.Spell.IdsMatch
		if Match and Match(idA, idB) then
			return true
		end
	end
	return idA == idB
end

local function ShouldShow(host, slot, want, index)
	if not host or not want then
		return false
	end
	local widget = host.widget
	if not widget or widget._fluxParked then
		return false
	end
	if LiveSlotOf(host) ~= slot then
		return false
	end
	if not SlotHasAction(slot) then
		return false
	end
	if want.hiddenAlways then
		return false
	end
	if want.hiddenMinirow and host.row ~= "main" then
		return false
	end
	if want.hiddenSwap then
		local Identity = Flux.Identity
		local barKind, barId, badgeKind, badgeId
		if Identity and Identity.Get then
			if Identity.SlotKey then
				barKind, barId = Identity.Get(Identity.SlotKey(slot))
			end
			if Identity.BadgeKey then
				badgeKind, badgeId = Identity.Get(Identity.BadgeKey(slot, index or 1))
			end
		end
		if not barKind then
			local sid = ShownSpellOnSlot(slot)
			if sid then
				barKind, barId = "spell", sid
			end
		end
		if not badgeKind then
			local sid = BadgeShownSpell(want)
			if sid then
				badgeKind, badgeId = "spell", sid
			end
		end
		if barKind and badgeKind and SameShownFace(barKind, barId, badgeKind, badgeId) then
			return false
		end
	end
	if want.hiddenUnlessCd and not SlotOnCooldown(slot) then
		local cd = false
		if want.spellId and Flux.Spell and Flux.Spell.GetCooldown then
			local start, duration = Flux.Spell.GetCooldown(want.spellId)
			cd = (tonumber(duration) or 0) > 1.5 and (tonumber(start) or 0) > 0
		end
		if not cd then
			return false
		end
	end
	local forms = want.forms
	if type(forms) == "table" and next(forms) then
		if not forms[CurrentFormToken()] then
			return false
		end
	end
	local alpha = tonumber(want.alpha)
	if alpha and alpha <= 0 then
		return false
	end
	return true
end

local function FaceFromWant(want)
	local text = WantDisplayMacrotext(want)
	if type(text) == "string" and text ~= "" then
		local Shown = Flux.EBS and Flux.EBS.Action and Flux.EBS.Action.ShownFromBody
		if Shown then
			local kind, id = Shown(text)
			if kind == "item" and type(id) == "number" then
				return kind, id
			end
			if kind == "spell" and type(id) == "number" then
				return kind, id
			end
		end
	end
	-- Reverse text may only be "Lesser Heal(Rank 1)". The saved id still paints,
	-- learned or not.
	if want.spellId then
		return "spell", want.spellId
	end
	if want.itemId then
		return "item", want.itemId
	end
	return nil
end

-- Overlay Identity first (this hop's TranslateMatching). Native occupancy
-- only when the overlay remainder was empty and paint fell back to the slot.
local function BarPublishedFace(slot)
	slot = tonumber(slot)
	if not slot then
		return nil
	end
	local Identity = Flux.Identity
	if Identity and Identity.Get and Identity.SlotKey then
		local kind, id = Identity.Get(Identity.SlotKey(slot))
		if kind and id then
			return kind, id
		end
	end
	if GetActionInfo then
		local ok, actionType, id = pcall(GetActionInfo, slot)
		if ok and id then
			if actionType == "spell" then
				return "spell", id
			end
			if actionType == "item" then
				return "item", id
			end
		end
	end
	return nil
end

-- Empty [mod]/[combat] remainder, or reverse still showing the bar's face after
-- leave (SecureCmdOptionParse lag / leftover SpellId): idle badge token.
-- Keep a parsed face that differs from the bar — that is the swap working.
local function RestoreWantDefault(badge, want)
	if not badge or not want then
		return
	end
	local hasFace = (badge.MacroMode == "spell" and badge.SpellId)
		or (badge.MacroMode == "item" and badge.ItemId)
	-- Rank text ("Lesser Heal(Rank 1)") is not a spell id. Paint the saved id.
	if badge.MacroMode == "spell" and type(badge.SpellId) ~= "number" and want.spellId then
		badge.SpellId = want.spellId
	end
	if hasFace then
		local parsed = badge.MacroAction
		local empty = parsed == nil or parsed == "" or parsed == "?"
		if not empty then
			local barKind, barId = BarPublishedFace(badge._fluxBadgeSlot)
			local badgeKind, badgeId
			if badge.MacroMode == "spell" then
				badgeKind, badgeId = "spell", badge.SpellId
			else
				badgeKind, badgeId = "item", badge.ItemId
			end
			if not (barKind and SameShownFace(barKind, barId, badgeKind, badgeId)) then
				return
			end
		end
	end
	badge.MacroTexture = nil
	if want.spellId then
		badge.MacroMode = "spell"
		badge.SpellId = want.spellId
		badge.ItemId = nil
	elseif want.itemId then
		badge.MacroMode = "item"
		badge.ItemId = want.itemId
		badge.SpellId = nil
	end
end

local function PublishBadgeIdentity(badge, want)
	local Identity = Flux.Identity
	if not (badge and Identity and Identity.Publish) then
		return
	end
	local slot = badge._fluxBadgeSlot
	local index = badge._fluxBadgeWantIndex or 1
	if not slot then
		return
	end
	local key = Identity.BadgeKey(slot, index)
	if Identity.Register and not Identity.Has(key) then
		Identity.Register(key, badge)
	end
	local kind, id
	if badge.MacroMode == "spell" and badge.SpellId then
		kind, id = "spell", badge.SpellId
	elseif badge.MacroMode == "item" and badge.ItemId then
		kind, id = "item", badge.ItemId
	else
		kind, id = FaceFromWant(want)
	end
	Identity.Publish(key, kind, id)
end

-- Reverse body is stable; [harm]/[mod]/[form] only change the parse. SetAction
-- is OOC. TranslateMacro must still run in combat so the icon can flip.
local function TranslateConditionalBadge(badge, want, text)
	if not badge or type(text) ~= "string" or text == "" then
		return false
	end
	if not InLockdown() and badge.SetAction then
		local sig = "macrotext:" .. text
		if badge._fluxAppliedFace ~= sig then
			badge:SetAction("macrotext", text)
			badge._fluxAppliedFace = sig
		end
	else
		badge.ActionType = "macrotext"
		badge.ActionValue = text
		badge.MacroBody = text
		badge.MacroIndex = nil
	end
	if badge.InvalidateTranslateMacroCache then
		badge:InvalidateTranslateMacroCache()
	end
	badge.MacroAction = nil
	local Action = Flux.EBS and Flux.EBS.Action
	if Action and Action.TranslateMacro then
		pcall(Action.TranslateMacro, badge)
	elseif badge.TranslateMacro then
		pcall(badge.TranslateMacro, badge)
	end
	RestoreWantDefault(badge, want)
	PublishBadgeIdentity(badge, want)
	return true
end

-- Reverse swap must add/remove item and spell digits on the new face.
-- cdNumber is cooldown text, not WCount.
local function PaintBadgeFace(badge)
	local Paint = Flux.EBS and Flux.EBS.Paint
	if not Paint then
		return
	end
	if Paint.UpdateIcon then
		Paint.UpdateIcon(badge)
	end
	if Paint.UpdateCount then
		Paint.UpdateCount(badge)
	end
	if Paint.UpdateCooldown then
		pcall(Paint.UpdateCooldown, badge)
	end
end

local function ApplyWant(badge, want)
	if not badge or not want then
		return false
	end
	badge._fluxBadgeKey = want.key
	badge._fluxBadgeAlpha = tonumber(want.alpha) or 0.75
	badge._fluxWant = want
	if badge.WHotKey then
		badge.WHotKey:Hide()
	end
	if badge.WName then
		badge.WName:Hide()
	end
	local text = WantDisplayMacrotext(want)
	local EBS = Flux.EBS
	-- Conditional reverse badges carry ephemeral macrotext; Blizzard owns flips.
	if want.conditionalMacro and type(text) == "string" and text ~= "" then
		if not TranslateConditionalBadge(badge, want, text) then
			return false
		end
		PaintBadgeFace(badge)
		return true
	end
	local kind, id = FaceFromWant(want)
	if not kind then
		return false
	end
	if not InLockdown() and badge.SetAction then
		local sig = tostring(kind) .. ":" .. tostring(id)
		if badge._fluxAppliedFace ~= sig then
			if kind == "spell" then
				badge:SetAction("spell", id)
			elseif kind == "item" then
				badge:SetAction("item", id)
			end
			badge._fluxAppliedFace = sig
		end
	end
	PublishBadgeIdentity(badge, want)
	if kind == "spell" and EBS and EBS.Badge and EBS.Badge.ApplyVisualSpellTexture then
		EBS.Badge.ApplyVisualSpellTexture(badge, id)
	elseif kind == "item" and badge.WIcon then
		local tex
		if C_Item and C_Item.GetItemIconByID then
			tex = C_Item.GetItemIconByID(id)
		elseif GetItemIcon then
			tex = GetItemIcon(id)
		end
		if tex then
			badge.WIcon:SetTexture(tex)
			badge.WIcon:SetTexCoord(0, 1, 0, 1)
			badge.WIcon:Show()
		end
	elseif kind == "spell" and want.spellId and EBS and EBS.Badge and EBS.Badge.ApplyVisualSpellTexture then
		EBS.Badge.ApplyVisualSpellTexture(badge, want.spellId)
	else
		return false
	end
	PaintBadgeFace(badge)
	return true
end

local function EnsureStack(host, slot)
	local widget = host and host.widget
	if not widget then
		return nil
	end
	instances[widget] = instances[widget] or {}
	local set = instances[widget][slot]
	if set then
		return set
	end
	if InLockdown() then
		combatDirty[slot] = true
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.badgehost", BadgeHost.FlushCombatQueue)
		end
		return nil
	end
	local EBS = Flux.EBS
	local New = EBS and EBS.Badge and EBS.Badge.New
	if not New then
		return nil
	end
	set = {}
	instances[widget][slot] = set
	for i = 1, MAX_BADGES do
		local badge = New(widget, {})
		if badge then
			if EBS.Badge.Layout then
				EBS.Badge.Layout(badge, widget, i)
			end
			set[i] = badge
		end
	end
	return set
end

local function HideSet(set)
	local EBS = Flux.EBS
	for i = 1, MAX_BADGES do
		local badge = set and set[i]
		if badge and EBS and EBS.Badge and EBS.Badge.HideVisual then
			EBS.Badge.HideVisual(badge)
		elseif badge and badge.Widget then
			badge.Widget:SetAlpha(0)
			badge.Widget._fluxBadgeCombatVisHidden = true
		end
	end
end

local function CompactHostCooldown(host, visibleCount)
	local fs = host and host.WCount
	if not fs or not fs.SetFont then
		return
	end
	local key = host
	if visibleCount >= 2 then
		if compactHosts[key] then
			return
		end
		compactHosts[key] = true
		if NumberFontNormal and NumberFontNormal.GetFont then
			local font, size, flags = NumberFontNormal:GetFont()
			pcall(fs.SetFont, fs, font, math.floor((size or 14) * 0.8), flags or "OUTLINE")
		end
	elseif compactHosts[key] then
		compactHosts[key] = nil
		if NumberFontNormal and NumberFontNormal.GetFont then
			local font, size, flags = NumberFontNormal:GetFont()
			pcall(fs.SetFont, fs, font, size or 14, flags or "OUTLINE")
		end
	end
end

-- full: EnsureStack + SetAction + Layout (OOC apply / combat flush only).
-- visual: alpha show/hide on stacks that already exist. Never SetParent/SetPoint.
local function PaintCorners(host, slot, set, layout)
	local list = slotBadges[slot]
	if not list or not set then
		HideSet(set)
		CompactHostCooldown(host, 0)
		return
	end
	local shown = 0
	local EBS = Flux.EBS
	local widget = host.widget
	local corner = 0
	for i = 1, #list do
		local want = list[i]
		if want and ShouldShow(host, slot, want, i) then
			corner = corner + 1
			if corner <= MAX_BADGES then
				local badge = set[corner]
				if badge then
					badge._fluxBadgeSlot = slot
					badge._fluxBadgeWantIndex = i
					-- Visual face is combat-legal (texture only). SetAction
					-- spell/item is OOC inside ApplyWant.
					ApplyWant(badge, want)
					if not InLockdown() then
						if layout and EBS and EBS.Badge and EBS.Badge.Layout then
							EBS.Badge.Layout(badge, widget, corner)
						end
					end
					if EBS and EBS.Badge and EBS.Badge.ShowVisual then
						EBS.Badge.ShowVisual(badge)
					elseif badge.Widget then
						badge.Widget._fluxBadgeCombatVisHidden = nil
						badge.Widget:SetAlpha(badge._fluxBadgeAlpha or 0.75)
						if layout then
							badge.Widget:Show()
						end
					end
					shown = shown + 1
				end
			end
		end
	end
	for i = shown + 1, MAX_BADGES do
		local badge = set[i]
		if badge and EBS and EBS.Badge and EBS.Badge.HideVisual then
			EBS.Badge.HideVisual(badge)
		elseif badge and badge.Widget then
			badge.Widget:SetAlpha(0)
			badge.Widget._fluxBadgeCombatVisHidden = true
		end
	end
	CompactHostCooldown(host, shown)
end

local function SyncHost(host, slot, full)
	local list = slotBadges[slot]
	local widget = host and host.widget
	if not widget then
		return
	end
	if not list then
		local set = instances[widget] and instances[widget][slot]
		if set then
			HideSet(set)
		end
		CompactHostCooldown(host, 0)
		return
	end
	local set = instances[widget] and instances[widget][slot]
	if InLockdown() then
		if not set then
			combatDirty[slot] = true
			if Flux.Combat and Flux.Combat.Defer then
				Flux.Combat.Defer("bars.badgehost", BadgeHost.FlushCombatQueue)
			end
			return
		end
		PaintCorners(host, slot, set, false)
		return
	end
	-- Paging / form / SHIFT: existing stacks stay parented; only alpha flips.
	if not full and set then
		PaintCorners(host, slot, set, false)
		return
	end
	set = EnsureStack(host, slot)
	if not set then
		return
	end
	PaintCorners(host, slot, set, true)
end

local function SyncSlot(slot, full)
	slot = tonumber(slot)
	if not slot then
		return
	end
	local col = LocateColumn(slot)
	local rec = col and HostsForColumn(col)
	if not rec then
		return
	end
	if rec.main then
		SyncHost(rec.main, slot, full)
	end
	if rec.sec then
		SyncHost(rec.sec, slot, full)
	end
	if rec.tert then
		SyncHost(rec.tert, slot, full)
	end
end

local function BadgeListFingerprint(list)
	if type(list) ~= "table" or #list == 0 then
		return ""
	end
	local chunks = {}
	for i = 1, #list do
		local b = list[i]
		if type(b) == "table" then
			chunks[#chunks + 1] = table.concat({
				tostring(b.key),
				tostring(b.macrotext),
				tostring(b.hoverMacrotext),
				tostring(b.alpha),
				tostring(b.hiddenAlways),
				tostring(b.hiddenSwap),
				tostring(b.hiddenUnlessCd),
				tostring(b.hiddenMinirow),
				tostring(b.spellId),
				tostring(b.itemId),
				tostring(b.conditionalMacro),
			}, ":")
		else
			chunks[#chunks + 1] = tostring(b)
		end
	end
	return table.concat(chunks, ";")
end

function BadgeHost.SetSlotBadges(slot, badgeList)
	slot = tonumber(slot)
	if not slot then
		return
	end
	if badgeList and #badgeList == 0 then
		badgeList = nil
	end
	if BadgeListFingerprint(slotBadges[slot]) == BadgeListFingerprint(badgeList) then
		return
	end
	slotBadges[slot] = badgeList
	local PF = Bars.ProgramFace
	if PF and PF.InvalidateIndex then
		PF.InvalidateIndex()
	end
	SyncSlot(slot, true)
end

function BadgeHost.ApplyMap(map, clearMissing)
	map = map or {}
	if clearMissing then
		for slot in pairs(slotBadges) do
			if map[slot] == nil then
				map[slot] = false
			end
		end
	end
	for slot, list in pairs(map) do
		BadgeHost.SetSlotBadges(slot, list ~= false and list or nil)
	end
end

function BadgeHost.ClearSlot(slot)
	BadgeHost.SetSlotBadges(slot, nil)
end

function BadgeHost.GetSlotBadges(slot)
	return slotBadges[tonumber(slot)]
end

function BadgeHost.HasAny()
	return next(slotBadges) ~= nil
end

function BadgeHost.EachIndexedBody(fn)
	if type(fn) ~= "function" then
		return
	end
	for slot, list in pairs(slotBadges) do
		if type(list) == "table" then
			for i = 1, #list do
				local want = list[i]
				local text = want and IdleMacro(want.macrotext)
				if type(text) == "string" and text ~= "" then
					fn(slot, text)
				end
				local hover = want and want.hoverMacrotext
				if type(hover) == "string" and hover ~= "" then
					fn(slot, hover)
				end
			end
		end
	end
end

function BadgeHost.NotifyDisplay(host)
	if not host then
		return
	end
	local slot = LiveSlotOf(host)
	if slot and slotBadges[slot] then
		SyncHost(host, slot, false)
	end
	-- Hide stacks this host is no longer displaying.
	local widget = host.widget
	local bySlot = widget and instances[widget]
	if bySlot then
		for other in pairs(bySlot) do
			if other ~= slot then
				HideSet(bySlot[other])
			end
		end
	end
end

-- Binding burst, Bars burst/settle and the Context form path all ask for this
-- on the same shift. One signature-gated pass per storm; force bypasses
-- (Binding apply / options edits with an unchanged form).
local lastFormVisSig = nil

local function FormVisSignature()
	local FS = Flux.FormStorm
	if FS and FS.GetSnapshot then
		local form, bonus, page, stealth = FS.GetSnapshot()
		return tostring(form) .. ":" .. tostring(bonus) .. ":" .. tostring(page) .. ":" .. tostring(stealth)
	end
	local form, bonus = 0, 0
	if type(GetShapeshiftForm) == "function" then
		local ok, v = pcall(GetShapeshiftForm)
		form = ok and (tonumber(v) or 0) or 0
	end
	if type(GetBonusBarOffset) == "function" then
		local ok, v = pcall(GetBonusBarOffset)
		bonus = ok and (tonumber(v) or 0) or 0
	end
	return form .. ":" .. bonus
end

function BadgeHost.RefreshFormVisibility(force)
	local sig = FormVisSignature()
	if not force and lastFormVisSig == sig then
		return
	end
	lastFormVisSig = sig
	for slot in pairs(slotBadges) do
		SyncSlot(slot, false)
	end
end

local identitySyncing = false
local pendingVis = {}
local trailingArmed = false
local trailingRunning = false

-- SecureCmdOptionParse can lag one frame after key-up. Immediate vis already
-- ran; this second pass must not Timer.Defer the first walk.
local function RunTrailingFaces()
	trailingArmed = false
	if trailingRunning or not next(slotBadges) then
		return
	end
	trailingRunning = true
	-- Same-frame parse cache can keep the in-condition remainder after key-up.
	local Action = Flux.EBS and Flux.EBS.Action
	if Action and Action.InvalidateMacroParseCache then
		Action.InvalidateMacroParseCache()
	end
	if BadgeHost.RefreshDisplays then
		BadgeHost.RefreshDisplays()
	end
	identitySyncing = true
	for slot in pairs(slotBadges) do
		pendingVis[slot] = nil
		SyncSlot(slot, false)
	end
	identitySyncing = false
	trailingRunning = false
end

local function ArmTrailingFaces()
	if trailingArmed or trailingRunning then
		return
	end
	trailingArmed = true
	local T = Flux.Timer
	if T and T.Defer then
		T.Defer(RunTrailingFaces)
	elseif C_Timer and C_Timer.After then
		C_Timer.After(0, RunTrailingFaces)
	else
		trailingArmed = false
	end
end

function BadgeHost.OnIdentityChange(key)
	if identitySyncing then
		return
	end
	local Identity = Flux.Identity
	if not Identity then
		return
	end
	local slot = Identity.ParseSlotKey and Identity.ParseSlotKey(key)
	if slot then
		slot = tonumber(slot)
		if slot and slotBadges[slot] then
			-- Bar published first. Do not hiddenSwap-hide against a stale badge.
			pendingVis[slot] = true
			-- Strip paint can TranslateMacro after the cond pass; reverse must
			-- catch that hop or the corner stays on the in-condition face.
			ArmTrailingFaces()
		end
		return
	end
	slot = Identity.ParseBadgeKey and Identity.ParseBadgeKey(key)
	slot = tonumber(slot)
	if not slot or not slotBadges[slot] then
		return
	end
	identitySyncing = true
	SyncSlot(slot, false)
	identitySyncing = false
	pendingVis[slot] = nil
end

--- After overlay + reverse have both published. Immediate, not Timer.Defer:
--- a deferred 57-host walk used to run before the reverse parse.
function BadgeHost.SyncShownFaces()
	if not next(slotBadges) then
		for k in pairs(pendingVis) do
			pendingVis[k] = nil
		end
		return
	end
	identitySyncing = true
	for slot in pairs(slotBadges) do
		pendingVis[slot] = nil
		SyncSlot(slot, false)
	end
	identitySyncing = false
	local Effects = Bars.Effects
	if Effects and Effects.Refresh then
		for slot in pairs(slotBadges) do
			local col = LocateColumn(slot)
			local rec = col and HostsForColumn(col)
			if rec and rec.main then
				Effects.Refresh(rec.main)
			elseif rec and rec.sec then
				Effects.Refresh(rec.sec)
			end
		end
	end
	ArmTrailingFaces()
end

function BadgeHost.RefreshOccupancyVisibility(slot)
	SyncSlot(slot, false)
end

local notifyPending = false

local function RunNotifyDisplays()
	notifyPending = false
	if Bars.ForEachHost then
		-- NotifyDisplay ignores the column/row args, so pass it straight
		-- through instead of allocating a closure per walk.
		Bars.ForEachHost(BadgeHost.NotifyDisplay)
	end
end

-- Bars.Watch fires this on the modifier edge and ProgramFace.FlushPending
-- fires it again for the same [mod] parse. Coalesced to one 57-host walk.
function BadgeHost.NotifyModifierPaging()
	if notifyPending then
		return
	end
	notifyPending = true
	local T = Flux.Timer
	if T and T.Defer then
		T.Defer(RunNotifyDisplays)
	else
		RunNotifyDisplays()
	end
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

local function RefreshOneBadgeDisplay(badge, ufPeek, paging)
	if not badge then
		return
	end
	local want = badge._fluxWant
	if not want then
		return
	end
	local text = WantDisplayMacrotext(want)
	local Action = Flux.EBS and Flux.EBS.Action
	if want.conditionalMacro and type(text) == "string" and text ~= "" then
		TranslateConditionalBadge(badge, want, text)
	else
		if badge.InvalidateTranslateMacroCache then
			badge:InvalidateTranslateMacroCache()
		end
		if badge.TranslateMacro then
			pcall(badge.TranslateMacro, badge)
		elseif Action and Action.TranslateMacro then
			pcall(Action.TranslateMacro, badge)
		end
		PublishBadgeIdentity(badge, want)
	end
	-- Cooldown/usable re-emit on every world hop. Face parse is enough here;
	-- strip Watch already hop-gates those lanes and releases after quiet.
	-- Icon must still flip: an empty remainder restored the default face.
	local hopping = false
	if not ufPeek then
		local R = Flux.Range
		hopping = R and R.IsHopBurst and R.IsHopBurst()
	end
	local Paint = Flux.EBS and Flux.EBS.Paint
	if Paint and Paint.UpdateIcon then
		Paint.UpdateIcon(badge)
	end
	if not hopping then
		if badge.UpdateCooldown then
			pcall(badge.UpdateCooldown, badge)
		end
		if Paint and Paint.UpdateCount then
			Paint.UpdateCount(badge)
		end
		if not paging and badge.UpdateUsable then
			pcall(badge.UpdateUsable, badge)
		end
	end
end

function BadgeHost.RefreshDisplays(ufPeek)
	if not next(instances) then
		return
	end
	local paging = _G._fluxPagingInProgress ~= nil
	for _, byBtn in pairs(instances) do
		for _, set in pairs(byBtn) do
			for i = 1, #set do
				RefreshOneBadgeDisplay(set[i], ufPeek, paging)
			end
		end
	end
end

function BadgeHost.RefreshMouseoverDisplays(ufPeek)
	if not next(instances) then
		return
	end
	local paging = _G._fluxPagingInProgress ~= nil
	for _, byBtn in pairs(instances) do
		for _, set in pairs(byBtn) do
			for i = 1, #set do
				local badge = set[i]
				if not badge then
					-- skip
				else
					local want = badge._fluxWant
					local refresh = ufPeek and true or false
					if not refresh and want and want.conditionalMacro then
						local text = WantDisplayMacrotext(want)
						if type(text) == "string" and BodyNeedsMouseoverRefresh(text) then
							refresh = true
						end
					end
					if refresh then
						RefreshOneBadgeDisplay(badge, ufPeek, paging)
					end
				end
			end
		end
	end
end

function BadgeHost.GetVisibleBadgesForButton(button)
	if not button then
		return nil
	end
	local byBtn = instances[button]
	if not byBtn then
		return nil
	end
	local host = button._fluxHost
	local slot = LiveSlotOf(host)
	if not slot then
		return nil
	end
	local set = byBtn[slot]
	if not set then
		return nil
	end
	local out = {}
	local desired = slotBadges[slot]
	if not desired then
		return nil
	end
	local corner = 0
	for i = 1, #desired do
		if ShouldShow(host, slot, desired[i], i) then
			corner = corner + 1
			if set[corner] then
				local badge = set[corner]
				local w = badge.Widget
				if w and w._fluxBadgeCombatVisHidden then
					-- unused / same-face corners stay shown at alpha 0
				else
					local alphaOk = true
					if w and w.GetAlpha then
						local ok, a = pcall(w.GetAlpha, w)
						if ok and type(a) == "number" and a <= 0 then
							alphaOk = false
						end
					end
					if alphaOk then
						out[#out + 1] = badge
					end
				end
			end
		end
	end
	return #out > 0 and out or nil
end

function BadgeHost.RefreshLayout()
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.badgehost", BadgeHost.FlushCombatQueue)
		end
		return
	end
	local EBS = Flux.EBS
	if not (EBS and EBS.Badge and EBS.Badge.Layout) then
		return
	end
	for widget, bySlot in pairs(instances) do
		if widget then
			for _, set in pairs(bySlot) do
				for i = 1, MAX_BADGES do
					local badge = set and set[i]
					if badge then
						EBS.Badge.Layout(badge, widget, i)
					end
				end
			end
		end
	end
end

function BadgeHost.FlushCombatQueue()
	if InLockdown() then
		return
	end
	for slot in pairs(combatDirty) do
		combatDirty[slot] = nil
		SyncSlot(slot, true)
	end
end
