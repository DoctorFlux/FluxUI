-- Bars/Effects.lua — identity-stable proc glow on the currently shown spell.
-- Main↔mini is three widgets; Hide+Show restarts the birth anim. SyncColumn
-- transfers the live overlay onto the row that currently shows the spell.
-- Cast.FollowColumn exclusively settles fill/interrupt/burst on the same dirty flush.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Effects = {}
Bars.Effects = Effects

local started = false
local dirtyCols = {}
local flushQueued = false

local function SpellForSlot(slot)
	local FX = Flux.ButtonFX
	if FX and FX.SpellIdFromAction then
		return FX.SpellIdFromAction(slot)
	end
	if not slot then
		return nil
	end
	local ok, actionType, id, subType = pcall(GetActionInfo, slot)
	if not ok or not actionType then
		return nil
	end
	if actionType == "spell" then
		return id
	end
	if actionType == "macro" then
		if subType == "spell" then
			return id
		end
		if GetMacroSpell then
			local okMacro, spellId = pcall(GetMacroSpell, id)
			if okMacro then
				return spellId
			end
		end
	end
	return nil
end

Effects.SpellForSlot = SpellForSlot

local function Glow()
	return Flux.ButtonFX and Flux.ButtonFX.Glow
end

local function HostSlot(host)
	if Bars.Hosts and Bars.Hosts.LiveSlot then
		return Bars.Hosts.LiveSlot(host)
	end
	return host and host.slot
end

local function Rows(column)
	local col = Bars.GetHost and Bars.GetHost(column)
	if not col then
		return nil, nil, nil
	end
	return col.main, col.sec, col.tert
end

local function SlotTexture(slot)
	if not slot or not GetActionTexture then
		return nil
	end
	local ok, tex = pcall(GetActionTexture, slot)
	if ok then
		return tex
	end
	return nil
end

local function HostIconTex(host)
	local icon = host and host.WIcon
	if icon and icon.GetTexture then
		local ok, tex = pcall(icon.GetTexture, icon)
		if ok and tex then
			return tex
		end
	end
	local widget = host and host.widget
	local btn = widget and widget.FluxButton
	if btn and btn.WIcon and btn.WIcon.GetTexture then
		local ok, tex = pcall(btn.WIcon.GetTexture, btn.WIcon)
		if ok and tex then
			return tex
		end
	end
	return SlotTexture(HostSlot(host))
end

local function HostSpellId(host)
	local slot = HostSlot(host)
	local Identity = Flux.Identity
	if slot and Identity and Identity.Get and Identity.SlotKey then
		local kind, id = Identity.Get(Identity.SlotKey(slot))
		if kind == "spell" then
			return tonumber(id) or id
		end
	end
	local PF = Bars.ProgramFace
	if PF and PF.Shown then
		local kind, id = PF.Shown(host)
		if kind == "spell" then
			return tonumber(id) or id
		end
	end
	return SpellForSlot(HostSlot(host))
end

local function HostWants(G, host)
	if not host or not host.widget or not G or not G.Want then
		return false, nil
	end
	local sid = HostSpellId(host)
	local tex = HostIconTex(host)
	if sid and G.Want(sid) then
		-- Id can lag a frame behind the icon on macro/target flips.
		if tex and G.FaceShowsSpell and not G.FaceShowsSpell(tex, sid) then
			return false, sid
		end
		return true, sid
	end
	if sid then
		return false, sid
	end
	-- Nil id: keep only while the icon is still the last overlayed spell.
	local last = host.widget._fluxGlowSpell
	if last and G.Want(last) and tex and G.FaceShowsSpell and G.FaceShowsSpell(tex, last) then
		return true, last
	end
	return false, sid
end

local function BadgeWants(G, face)
	local widget = face and face.widget
	if not widget or widget._fluxBadgeCombatVisHidden or not G or not G.Want then
		return false, nil
	end
	local btn = face.badge or widget.FluxButton
	local sid
	local FX = Flux.ButtonFX
	if FX and FX.SpellIdFromEBS then
		sid = FX.SpellIdFromEBS(btn)
	elseif btn then
		sid = btn.SpellId
	end
	local tex
	local icon = btn and btn.WIcon
	if icon and icon.GetTexture then
		local ok, t = pcall(icon.GetTexture, icon)
		if ok then
			tex = t
		end
	end
	if sid and G.Want(sid) then
		if tex and G.FaceShowsSpell and not G.FaceShowsSpell(tex, sid) then
			return false, sid
		end
		return true, sid
	end
	if sid then
		return false, sid
	end
	local last = widget._fluxGlowSpell
	if last and G.Want(last) and tex and G.FaceShowsSpell and G.FaceShowsSpell(tex, last) then
		return true, last
	end
	return false, sid
end

local function FaceWants(G, face)
	if face and face.host then
		return HostWants(G, face.host)
	end
	return BadgeWants(G, face)
end

-- SyncColumn runs across all 19 columns on every glow / modifier / target /
-- icon edge. The face records are pooled per column so a resync allocates
-- nothing; keeping the pool per column also keeps the identity comparisons in
-- SyncColumn (face ~= wantFace) stable.
local columnFaceCache = {}

local function ColumnFaces(column)
	local cache = columnFaceCache[column]
	if not cache then
		cache = { faces = {}, pool = {}, rows = {} }
		columnFaceCache[column] = cache
	end
	local faces, pool, rows = cache.faces, cache.pool, cache.rows
	rows[1], rows[2], rows[3] = Rows(column)

	local n = 0
	for i = 1, 3 do
		local host = rows[i]
		if host and host.widget then
			n = n + 1
			local face = pool[n]
			if not face then
				face = {}
				pool[n] = face
			end
			face.widget = host.widget
			face.host = host
			face.badge = nil
			faces[n] = face
		end
	end
	local BH = Bars.BadgeHost
	if BH and BH.GetVisibleBadgesForButton then
		local nStrip = n
		for i = 1, nStrip do
			local list = BH.GetVisibleBadgesForButton(faces[i].widget)
			if list then
				for j = 1, #list do
					local badge = list[j]
					local w = badge and badge.Widget
					if w and not w._fluxBadgeCombatVisHidden then
						n = n + 1
						local face = pool[n]
						if not face then
							face = {}
							pool[n] = face
						end
						face.widget = w
						face.host = nil
						face.badge = badge
						faces[n] = face
					end
				end
			end
		end
	end
	for i = n + 1, #faces do
		faces[i] = nil
	end
	return faces, rows
end

function Effects.SetGlow(widget, on, skipBirth)
	local G = Glow()
	if G and G.Set then
		G.Set(widget, on, skipBirth)
	end
end

local function FaceEnv(face)
	return face.badge or (face.widget and face.widget.FluxButton)
end

local function MarkGlowShown(G, face, sid)
	if face.host then
		face.host._glowing = true
	end
	local btn = FaceEnv(face)
	if btn then
		btn._glowing = true
	end
	if G.NoteShown then
		G.NoteShown(face.widget, sid)
	else
		face.widget._fluxGlowSpell = sid
	end
end

local function MarkGlowHidden(G, face)
	if face.host then
		face.host._glowing = false
	end
	local btn = FaceEnv(face)
	if btn then
		btn._glowing = false
	end
	if G.NoteHidden then
		G.NoteHidden(face.widget)
	else
		face.widget._fluxGlowSpell = nil
	end
end

local function FaceIsGlowing(G, face)
	if face.host and face.host._glowing then
		return true
	end
	local btn = FaceEnv(face)
	if btn and btn._glowing then
		return true
	end
	return G.IsLive and G.IsLive(face.widget) and true or false
end

local function FaceSpell(face)
	if face.host then
		return HostSpellId(face.host)
	end
	local btn = FaceEnv(face)
	if not btn then
		return nil
	end
	local FX = Flux.ButtonFX
	if FX and FX.SpellIdFromEBS then
		return FX.SpellIdFromEBS(btn)
	end
	return btn.SpellId
end

local function FaceChecked(face)
	if face.host then
		return face.host._checked and true or false
	end
	local w = face.widget
	return w and w._fluxPaintChecked and true or false
end

local function UncheckFace(face)
	local widget = face.widget
	if face.host then
		face.host._checked = false
	end
	local btn = FaceEnv(face)
	if btn then
		btn._lastChecked = false
	end
	if not widget then
		return
	end
	widget._fluxPaintChecked = false
	widget._fluxCheckedFromPaint = true
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	if ov and ov.ApplyChecked then
		ov.ApplyChecked(widget, false)
	elseif widget.SetChecked then
		widget._fluxCheckedApplied = false
		widget:SetChecked(false)
	end
	widget._fluxCheckedFromPaint = nil
end

-- Reused per SyncColumn call; never retained past the exclusivity pass.
local goldScratch = {}

function Effects.SyncColumn(column)
	column = tonumber(column)
	if not column then
		return
	end
	local G = Glow()
	local faces = ColumnFaces(column)
	if G then
		local liveFace
		local wantFace
		local wantSpell
		for i = 1, #faces do
			local face = faces[i]
			local w = face.widget
			if G.IsLive and G.IsLive(w) then
				liveFace = face
			end
			local want, sid = FaceWants(G, face)
			if want then
				local parked = w._fluxParked
				if not wantFace then
					wantFace = face
					wantSpell = sid
				elseif parked then
					-- keep unparked owner
				else
					if wantFace.widget and wantFace.widget._fluxParked then
						wantFace = face
						wantSpell = sid
					end
				end
			end
		end

		local transferred = false
		if wantFace and liveFace and wantFace ~= liveFace and G.Transfer then
			if G.Transfer(liveFace.widget, wantFace.widget) then
				MarkGlowHidden(G, liveFace)
				MarkGlowShown(G, wantFace, wantSpell)
				for i = 1, #faces do
					local face = faces[i]
					if wantSpell then
						face.widget._fluxGlowBirthSpell = wantSpell
					end
					if face ~= wantFace and G.IsLive and G.IsLive(face.widget) then
						G.Set(face.widget, false)
						MarkGlowHidden(G, face)
					end
				end
				transferred = true
			end
		end

		if not transferred then
			for i = 1, #faces do
				local face = faces[i]
				local widget = face.widget
				local want, sid = FaceWants(G, face)
				if wantFace and face ~= wantFace then
					want = false
				end
				if want then
					local live = G.IsLive and G.IsLive(widget)
					if live then
						MarkGlowShown(G, face, sid)
					else
						-- First paint of a new proc plays intro. skipBirth when
						-- this column is already live, or this spell already birthed.
						local skip = liveFace ~= nil
						if not skip and G.ShouldSkipBirth then
							skip = G.ShouldSkipBirth(widget, sid)
						end
						G.Set(widget, true, skip)
						MarkGlowShown(G, face, sid)
					end
					if sid then
						for j = 1, #faces do
							faces[j].widget._fluxGlowBirthSpell = sid
						end
					end
				else
					if FaceIsGlowing(G, face) then
						G.Set(widget, false)
					end
					MarkGlowHidden(G, face)
				end
			end
		end
	end
	if G and G.NotifySAO then
		for i = 1, #faces do
			G.NotifySAO(faces[i].widget)
		end
	end
	local CastMod = Flux.ButtonFX and Flux.ButtonFX.Cast
	if CastMod and CastMod.FollowColumn then
		CastMod.FollowColumn(column)
	end
	local Paint = Bars.Paint
	if Paint and Paint.UpdateChecked then
		for i = 1, #faces do
			if faces[i].host then
				Paint.UpdateChecked(faces[i].host)
			end
		end
	end
	local EBS = Flux.EBS
	if EBS and EBS.Paint and EBS.Paint.UpdateChecked then
		for i = 1, #faces do
			if faces[i].badge then
				EBS.Paint.UpdateChecked(faces[i].badge)
			end
		end
	end
	-- One gold checked per live Extra identity. Alpha-0 badges are already unchecked.
	local Match = Flux.Spell and Flux.Spell.IdsMatch
	local gold = goldScratch
	local nGold = 0
	for i = 1, #faces do
		if FaceChecked(faces[i]) then
			nGold = nGold + 1
			gold[nGold] = faces[i]
		end
	end
	for i = nGold + 1, #gold do
		gold[i] = nil
	end
	for i = 1, #gold do
		local a = gold[i]
		if FaceChecked(a) then
			local sidA = FaceSpell(a)
			if sidA then
				for j = i + 1, #gold do
					local b = gold[j]
					if FaceChecked(b) then
						local sidB = FaceSpell(b)
						local same = sidB and ((Match and Match(sidA, sidB)) or sidA == sidB)
						if same then
							UncheckFace(b)
						end
					end
				end
			end
		end
	end
end

local pendingCols = {}

local function FlushDirty()
	flushQueued = false
	local n = 0
	for column in pairs(dirtyCols) do
		n = n + 1
		pendingCols[n] = column
		dirtyCols[column] = nil
	end
	if n == 0 then
		return
	end
	local FX = Flux.ButtonFX
	if FX and FX.BeginSlotPass then
		FX.BeginSlotPass()
	end
	for i = 1, n do
		Effects.SyncColumn(pendingCols[i])
		pendingCols[i] = nil
	end
	if FX and FX.EndSlotPass then
		FX.EndSlotPass()
	end
end

local function QueueFlush()
	if flushQueued then
		return
	end
	flushQueued = true
	if Flux.Timer and Flux.Timer.Defer then
		Flux.Timer.Defer(FlushDirty)
	else
		FlushDirty()
	end
end

function Effects.Refresh(host)
	if not host then
		return
	end
	local column = host.column
	if not column then
		return
	end
	dirtyCols[column] = true
	QueueFlush()
end

function Effects.RefreshAll()
	for i = 1, Bars.NUM_COLUMNS do
		dirtyCols[i] = true
	end
	QueueFlush()
end

function Effects.Start()
	if started then
		return
	end
	started = true
	local G = Glow()
	if G and G.Start then
		G.Start()
	end
	if G and G.OnChange then
		G.OnChange(Effects.RefreshAll)
	end
	local F = Flux.ButtonFX and Flux.ButtonFX.Flash
	if F then
		if F.Start then
			F.Start()
		end
		if F.OnChange then
			F.OnChange(function()
				local Paint = Bars.Paint
				if not (Paint and Paint.UpdateFlash) then
					return
				end
				Bars.ForEachHost(function(host)
					Paint.UpdateFlash(host)
				end)
			end)
		end
	end
	local function ContextOwnsDisplay()
		local C = Flux.Context
		return C and C.HasSubscribers and C.HasSubscribers() and true or false
	end
	local function OnContextedHop()
		-- ProgramFace.OnContext SyncShownFaces then Effects.Refresh the
		-- live columns. Running here first settles VFX on a stale face.
		if ContextOwnsDisplay() then
			return
		end
		Effects.RefreshAll()
	end
	local FormStorm = Flux.FormStorm
	if FormStorm and FormStorm.OnBurst then
		-- Page / bonus bar / form are one burst. Context settle runs
		-- Identity + badge vis + Effects.Refresh; bursting here first
		-- settles VFX on a stale face.
		-- Glow transfer rides the frame after the burst (with the deferred
		-- cooldown/usable lanes in Watch), keeping the burst frame icon-only.
		local burstDeferred = false
		FormStorm.OnBurst("bars.effects", function()
			if ContextOwnsDisplay() then
				return
			end
			if burstDeferred then
				return
			end
			burstDeferred = true
			if Flux.Timer and Flux.Timer.Defer then
				Flux.Timer.Defer(function()
					burstDeferred = false
					Effects.RefreshAll()
				end)
			else
				burstDeferred = false
				Effects.RefreshAll()
			end
		end)
	end
	local Ev = Flux.Events
	if Ev and Ev.Register then
		if not (FormStorm and FormStorm.OnBurst) then
			Ev.Register("ACTIONBAR_PAGE_CHANGED", Effects.RefreshAll)
			Ev.Register("UPDATE_BONUS_ACTIONBAR", Effects.RefreshAll)
			Ev.Register("UPDATE_SHAPESHIFT_FORM", Effects.RefreshAll)
		end
		Ev.Register("SPELL_UPDATE_ICON", Effects.RefreshAll)
		Ev.Register("UPDATE_MACROS", Effects.RefreshAll)
		Ev.Register("PLAYER_TARGET_CHANGED", OnContextedHop)
		Ev.Register("PLAYER_FOCUS_CHANGED", OnContextedHop)
		Ev.Register("MODIFIER_STATE_CHANGED", OnContextedHop)
		Ev.Register("PLAYER_REGEN_DISABLED", OnContextedHop)
		Ev.Register("PLAYER_REGEN_ENABLED", OnContextedHop)
		Ev.Register("PLAYER_EQUIPMENT_CHANGED", Effects.RefreshAll)
	end
	Effects.RefreshAll()
end
