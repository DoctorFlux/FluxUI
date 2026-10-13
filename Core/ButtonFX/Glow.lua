-- ButtonFX/Glow.lua — SPELL_ACTIVATION_OVERLAY proc glow (strip + Extra Buttons).
-- Hide+Show restarts ProcStart. Transfer reparents the live overlay so the
-- loop continues across main↔mini and same-widget macro identity changes.
-- Pre-DF membership follows SpellActivationOverlay (Era 2.7.9 does not export
-- GlowingSpells or _G.SAO). Read that table from OnEvent upvalues, or one OOC
-- setfenv proxy around SPELLS_CHANGED. Never assign _G.ipairs — that taints
-- every later ipairs (nameplate Layout GetScaledRect, collector Update).
-- Paint owns ActionButtonSpellAlertTemplate / LCG on _fluxProcAlert only —
-- never widget.SpellActivationAlert (that's the manager key leftover/override
-- UpdateSpellAlert uses). AutoCastShine if FlipBook/atlas is missing.
-- Never replace SAO.AddGlow / LibButtonGlow.ShowOverlayGlow: those run on every
-- stock button during a proc, so a Flux wrap taints OverrideActionBar
-- SetAttribute and leftover Update. hooksecurefunc after the original only.
-- Never ActionButtonSpellAlertManager:ShowAlert / HideAlert / activeAlerts.
-- Never ActionButton_ShowOverlayGlow. Never SAO.UpdateActionButton from Flux.
local addonName, ns = ...
local Flux = ns.Flux

local ButtonFX = Flux.ButtonFX or {}
Flux.ButtonFX = ButtonFX

local Glow = {}
ButtonFX.Glow = Glow

local overlayed = {}
local listeners = {}
local started = false

local function Notify()
	for i = 1, #listeners do
		local fn = listeners[i]
		if fn then
			pcall(fn)
		end
	end
end

function Glow.OnChange(fn)
	if type(fn) == "function" then
		listeners[#listeners + 1] = fn
	end
end

local function OverlayFrame(widget)
	if not widget then
		return nil
	end
	if widget._fluxAssistedCombat then
		local rot = widget.AssistedCombatRotationFrame
		if rot then
			return rot.SpellActivationAlert
		end
		local atlas = widget._fluxAssistantAtlas
		if atlas then
			return atlas.SpellActivationAlert
		end
		return nil
	end
	return widget._fluxProcAlert or widget._ProcGlow or widget._fluxProcShine
		or widget.overlay or widget.__LBGoverlay
end

local function OverlayShown(frame)
	if not frame or not frame.IsShown then
		return false
	end
	local ok, shown = pcall(frame.IsShown, frame)
	return ok and shown and true or false
end

function Glow.IsLive(widget)
	local frame = OverlayFrame(widget)
	if not OverlayShown(frame) then
		return false
	end
	local animOut = frame.animOut
	if animOut and animOut.IsPlaying then
		local ok, playing = pcall(animOut.IsPlaying, animOut)
		if ok and playing then
			return false
		end
	end
	return true
end

local function AtlasExists(name)
	if type(name) ~= "string" or name == "" then
		return false
	end
	if C_Texture and C_Texture.GetAtlasInfo then
		local ok, info = pcall(C_Texture.GetAtlasInfo, name)
		return ok and info ~= nil
	end
	return true
end

local function OverlayLooksPainted(widget)
	if not Glow.IsLive(widget) then
		return false
	end
	local frame = OverlayFrame(widget)
	if not frame then
		return false
	end
	if frame.ants then
		return true
	end
	local flip = frame.ProcLoopFlipbook or frame.ProcLoop or frame.ProcStartFlipbook or frame.ProcStart
	if type(flip) == "table" then
		if flip.GetAtlas then
			local ok, atlas = pcall(flip.GetAtlas, flip)
			if ok and type(atlas) == "string" and atlas ~= "" then
				return AtlasExists(atlas)
			end
		end
		if flip.GetTexture then
			local ok, tex = pcall(flip.GetTexture, flip)
			if ok and tex then
				return true
			end
		end
	end
	return true
end

local function SnapClassicAnimIn(widget)
	local frame = OverlayFrame(widget)
	if not frame then
		return
	end
	local animIn = frame.animIn
	if not animIn then
		return
	end
	if animIn.IsPlaying then
		local ok, playing = pcall(animIn.IsPlaying, animIn)
		if ok and playing and animIn.Stop then
			pcall(animIn.Stop, animIn)
		end
	end
	if animIn.GetScript then
		local ok, finish = pcall(animIn.GetScript, animIn, "OnFinished")
		if ok and type(finish) == "function" then
			pcall(finish, animIn)
		end
	end
end

local function SnapRetailLoop(widget)
	local frame = OverlayFrame(widget)
	if not frame then
		return
	end
	if frame.ProcStartAnim and frame.ProcStartAnim.IsPlaying then
		local ok, playing = pcall(frame.ProcStartAnim.IsPlaying, frame.ProcStartAnim)
		if ok and playing and frame.ProcStartAnim.Stop then
			pcall(frame.ProcStartAnim.Stop, frame.ProcStartAnim)
		end
	end
	local loop = frame.ProcLoop or frame.ProcLoopAnim
	if loop and loop.Play then
		local playing = false
		if loop.IsPlaying then
			local ok, v = pcall(loop.IsPlaying, loop)
			playing = ok and v and true or false
		end
		if not playing then
			pcall(loop.Play, loop)
		end
	end
end

local function ProcGlowLib()
	if LibStub then
		local ok, lib = pcall(LibStub, "LibCustomGlow-1.0", true)
		if ok then
			return lib
		end
	end
	return nil
end

local function AnchorOverlay(frame, host)
	if not frame or not host then
		return
	end
	pcall(frame.SetParent, frame, host)
	if frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
	local w = (host.GetWidth and host:GetWidth()) or 36
	local h = (host.GetHeight and host:GetHeight()) or 36
	if not w or w < 1 then
		w = 36
	end
	if not h or h < 1 then
		h = 36
	end
	if frame.SetSize then
		pcall(frame.SetSize, frame, w * 1.4, h * 1.4)
	end
	if frame.ProcLoopFlipbook then
		pcall(frame.SetPoint, frame, "CENTER", host, "CENTER", 0, 0)
	else
		pcall(frame.SetPoint, frame, "TOPLEFT", host, "TOPLEFT", -w * 0.2, h * 0.2)
		pcall(frame.SetPoint, frame, "BOTTOMRIGHT", host, "BOTTOMRIGHT", w * 0.2, -h * 0.2)
	end
	if frame.SetFrameLevel and host.GetFrameLevel then
		pcall(frame.SetFrameLevel, frame, (host:GetFrameLevel() or 0) + 5)
	end
	if frame.EnableMouse then
		pcall(frame.EnableMouse, frame, false)
	end
end

local function AssignOverlay(widget, frame)
	if not widget then
		return
	end
	if frame and frame.ProcLoopFlipbook then
		widget._fluxProcAlert = frame
	elseif frame and frame.ProcLoopAnim then
		widget._ProcGlow = frame
	elseif frame then
		if widget.__LBGoverlay ~= nil or not widget.overlay then
			widget.__LBGoverlay = frame
		end
		widget.overlay = frame
	end
end

local function ClearOverlayRef(widget, frame)
	if not widget then
		return
	end
	if widget._fluxProcAlert == frame then
		widget._fluxProcAlert = nil
	end
	if widget.overlay == frame then
		widget.overlay = nil
	end
	if widget.__LBGoverlay == frame then
		widget.__LBGoverlay = nil
	end
	if widget._ProcGlow == frame then
		widget._ProcGlow = nil
	end
	if widget._fluxProcShine == frame then
		widget._fluxProcShine = nil
	end
end

local function FinishShow(widget, skipBirth)
	if skipBirth then
		SnapRetailLoop(widget)
	end
	local frame = OverlayFrame(widget)
	if frame and frame.EnableMouse then
		pcall(frame.EnableMouse, frame, false)
	end
	if OverlayShown(frame) then
		return true
	end
	return OverlayLooksPainted(widget)
end

--- skipBirth: play ProcLoop instead of ProcStart (transfer / already-glowing).
local function AssistantAlertHost(widget)
	if not widget then
		return nil
	end
	return widget.AssistedCombatRotationFrame or widget._fluxAssistantAtlas
end

local function PlayFlipbook(frame, skipBirth)
	if not frame then
		return
	end
	if frame.Show then
		pcall(frame.Show, frame)
	end
	frame.playingAnimation = true
	if skipBirth then
		if frame.ProcStartAnim and frame.ProcStartAnim.Stop then
			pcall(frame.ProcStartAnim.Stop, frame.ProcStartAnim)
		end
		if frame.ProcLoop and frame.ProcLoop.Play then
			pcall(frame.ProcLoop.Play, frame.ProcLoop)
		end
	elseif frame.ProcStartAnim and frame.ProcStartAnim.Play then
		pcall(frame.ProcStartAnim.Play, frame.ProcStartAnim)
	end
	if frame.EnableMouse then
		pcall(frame.EnableMouse, frame, false)
	end
end

local function StopFlipbook(frame)
	if not frame then
		return
	end
	if frame.Hide then
		pcall(frame.Hide, frame)
	end
	if frame.ProcStartAnim and frame.ProcStartAnim.Stop then
		pcall(frame.ProcStartAnim.Stop, frame.ProcStartAnim)
	end
	local loop = frame.ProcLoop or frame.ProcLoopAnim
	if loop and loop.Stop then
		pcall(loop.Stop, loop)
	end
	frame.playingAnimation = false
end

local function ShowAssistedRotationAlert(widget, skipBirth)
	local host = AssistantAlertHost(widget)
	if not host then
		return false
	end
	local frame = host.SpellActivationAlert
	if not frame then
		local ok, created = pcall(CreateFrame, "Frame", nil, host, "ActionButtonSpellAlertTemplate")
		if ok then
			frame = created
		end
		if not frame then
			return false
		end
		host.SpellActivationAlert = frame
		if frame.SetAllPoints then
			pcall(frame.SetAllPoints, frame, host)
		end
		if frame.ProcStartFlipbook and frame.ProcStartFlipbook.SetAtlas then
			pcall(frame.ProcStartFlipbook.SetAtlas, frame.ProcStartFlipbook, "OneButton_ProcStart_Flipbook")
		end
		if frame.ProcLoopFlipbook and frame.ProcLoopFlipbook.SetAtlas then
			pcall(frame.ProcLoopFlipbook.SetAtlas, frame.ProcLoopFlipbook, "OneButton_ProcLoop_Flipbook")
		end
	end
	PlayFlipbook(frame, skipBirth)
	return true
end

local function EnsureOwnAlert(widget)
	local frame = widget._fluxProcAlert
	if frame then
		AnchorOverlay(frame, widget)
		return frame
	end
	local ok, created = pcall(CreateFrame, "Frame", nil, widget, "ActionButtonSpellAlertTemplate")
	if not ok or not created then
		return nil
	end
	widget._fluxProcAlert = created
	AnchorOverlay(created, widget)
	return created
end

local function StopShine(widget)
	local shine = widget and widget._fluxProcShine
	if not shine then
		return
	end
	if AutoCastShine_AutoCastStop then
		pcall(AutoCastShine_AutoCastStop, shine)
	end
	if shine.Hide then
		pcall(shine.Hide, shine)
	end
end

local function StartShine(widget)
	if not widget then
		return false
	end
	local shine = widget._fluxProcShine
	if not shine then
		local ok, created = pcall(CreateFrame, "Frame", nil, widget, "AutoCastShineTemplate")
		if ok then
			shine = created
		end
		if not shine then
			return false
		end
		widget._fluxProcShine = shine
		if shine.SetAllPoints then
			pcall(shine.SetAllPoints, shine, widget)
		end
		if shine.EnableMouse then
			pcall(shine.EnableMouse, shine, false)
		end
	end
	if AutoCastShine_AutoCastStart then
		pcall(AutoCastShine_AutoCastStart, shine)
	end
	if shine.Show then
		pcall(shine.Show, shine)
	end
	return OverlayShown(shine) or AutoCastShine_AutoCastStart ~= nil
end

function Glow.Set(widget, on, skipBirth)
	if not widget then
		return
	end
	if on then
		if OverlayLooksPainted(widget) or OverlayShown(OverlayFrame(widget)) then
			return
		end
		if widget._fluxAssistedCombat then
			if ShowAssistedRotationAlert(widget, skipBirth and true or false) then
				if skipBirth then
					SnapRetailLoop(widget)
				end
				return
			end
		end
		local frame = EnsureOwnAlert(widget)
		if frame then
			PlayFlipbook(frame, skipBirth and true or false)
			if FinishShow(widget, skipBirth) then
				return
			end
			if not OverlayShown(frame) then
				StopFlipbook(frame)
			else
				return
			end
		end
		local LCG = ProcGlowLib()
		if LCG and LCG.ProcGlow_Start then
			pcall(LCG.ProcGlow_Start, widget, { startAnim = not skipBirth })
			if FinishShow(widget, skipBirth) then
				return
			end
			if not OverlayShown(OverlayFrame(widget)) then
				if LCG.ProcGlow_Stop then
					pcall(LCG.ProcGlow_Stop, widget)
				end
			else
				return
			end
		end
		StartShine(widget)
		return
	end
	local host = AssistantAlertHost(widget)
	StopFlipbook(host and host.SpellActivationAlert)
	StopFlipbook(widget._fluxProcAlert)
	StopFlipbook(widget._ProcGlow)
	StopFlipbook(widget.overlay)
	StopFlipbook(widget.__LBGoverlay)
	StopShine(widget)
	local LCG = ProcGlowLib()
	if LCG and LCG.ProcGlow_Stop then
		pcall(LCG.ProcGlow_Stop, widget)
	end
end

function Glow.Transfer(from, to)
	if not from or not to or from == to then
		return false
	end
	local frame = OverlayFrame(from)
	if not frame or not Glow.IsLive(from) then
		return false
	end
	if frame.startAnim ~= nil then
		frame.startAnim = false
	end
	if frame.ProcStartAnim and frame.ProcStartAnim.Stop then
		pcall(frame.ProcStartAnim.Stop, frame.ProcStartAnim)
	end
	local destOld = OverlayFrame(to)
	if destOld and destOld ~= frame then
		pcall(destOld.Hide, destOld)
		ClearOverlayRef(to, destOld)
	end
	AnchorOverlay(frame, to)
	if frame.GetParent then
		local ok, parent = pcall(frame.GetParent, frame)
		if ok and parent ~= to then
			AnchorOverlay(frame, from)
			return false
		end
	end
	ClearOverlayRef(from, frame)
	AssignOverlay(to, frame)
	if frame.Show then
		pcall(frame.Show, frame)
	end
	local loop = frame.ProcLoop or frame.ProcLoopAnim
	if loop and loop.Play then
		local playing = false
		if loop.IsPlaying then
			local ok, v = pcall(loop.IsPlaying, loop)
			playing = ok and v and true or false
		end
		if not playing then
			pcall(loop.Play, loop)
		end
	end
	SnapClassicAnimIn(to)
	to._fluxGlowSpell = from._fluxGlowSpell
	to._fluxGlowBirthSpell = from._fluxGlowBirthSpell or from._fluxGlowSpell or to._fluxGlowBirthSpell
	from._fluxGlowSpell = nil
	return true
end

function Glow.ShouldSkipBirth(widget, spellId)
	if not widget or not spellId then
		return false
	end
	return widget._fluxGlowBirthSpell == spellId
end

function Glow.NoteShown(widget, spellId)
	if not widget then
		return
	end
	widget._fluxGlowSpell = spellId
	if spellId then
		widget._fluxGlowBirthSpell = spellId
	end
end

function Glow.NoteHidden(widget)
	if not widget then
		return
	end
	local birth = widget._fluxGlowBirthSpell
	widget._fluxGlowSpell = nil
	if birth and not Glow.Want(birth) then
		widget._fluxGlowBirthSpell = nil
	end
end

local function SpellTex(spellId)
	if not spellId then
		return nil
	end
	if Flux.Spell and Flux.Spell.GetTexture then
		local ok, tex = pcall(Flux.Spell.GetTexture, spellId)
		if ok and tex then
			return tex
		end
	end
	if GetSpellTexture then
		local ok, tex = pcall(GetSpellTexture, spellId)
		if ok then
			return tex
		end
	end
	return nil
end

--- True when the shown icon is still that spell. A different (or empty) face
--- is a real macro/target leave — do not keep the proc glow on it.
function Glow.FaceShowsSpell(texture, spellId)
	if not texture or not spellId then
		return false
	end
	local spellTex = SpellTex(spellId)
	return spellTex ~= nil and texture == spellTex
end

local function OverrideSpell(spellId)
	if not spellId then
		return nil
	end
	if Flux.Spell and Flux.Spell.GetOverrideSpell then
		local ok, ov = pcall(Flux.Spell.GetOverrideSpell, spellId)
		if ok and type(ov) == "number" and ov > 0 then
			return ov
		end
	elseif C_Spell and C_Spell.GetOverrideSpell then
		local ok, ov = pcall(C_Spell.GetOverrideSpell, spellId)
		if ok and type(ov) == "number" and ov > 0 then
			return ov
		end
	end
	return spellId
end

local function UseNativeOverlayAPI()
	local c = Flux.Client
	if c and (c.isPreDF or c.isAnyClassic) then
		return false
	end
	return true
end

-- Era SAO 2.7.9 keeps GlowingSpells file-local and never assigns _G.SAO.
local capturedSao
local glowingTriggers = {} -- glowID -> { triggerID = true }
local lbgCounts = {}
local onEventWrapped = false
local lbgHooked = false
local bindTries = 0
local bindTicker

local function SpellName(spellId)
	if type(spellId) ~= "number" then
		return nil
	end
	if Flux.Spell and Flux.Spell.GetName then
		local ok, name = pcall(Flux.Spell.GetName, spellId)
		if ok and type(name) == "string" and name ~= "" then
			return name
		end
	end
	if GetSpellInfo then
		local ok, name = pcall(GetSpellInfo, spellId)
		if ok and type(name) == "string" and name ~= "" then
			return name
		end
	end
	return nil
end

local function SaoAddon()
	if capturedSao then
		return capturedSao
	end
	local a = _G.SpellActivationOverlayAddon or _G.SAO
	if type(a) == "table" and type(a.AddGlow) == "function" then
		return a
	end
	return nil
end

local function IdInSet(set, spellId)
	if type(set) ~= "table" or type(spellId) ~= "number" then
		return false
	end
	if set[spellId] then
		return true
	end
	local ov = OverrideSpell(spellId)
	if ov and ov ~= spellId and set[ov] then
		return true
	end
	local name = SpellName(spellId)
	if not name then
		return false
	end
	for id in pairs(set) do
		if type(id) == "number" and SpellName(id) == name then
			return true
		end
	end
	return false
end

local function TableGlowingSpellsHas(spells, spellId)
	if type(spells) ~= "table" then
		return false
	end
	if IdInSet(spells, spellId) then
		return true
	end
	local ov = OverrideSpell(spellId)
	for gid, triggers in pairs(spells) do
		if gid == spellId or (ov and gid == ov) then
			return true
		end
		if type(triggers) == "table" then
			if triggers[spellId] or (ov and triggers[ov]) then
				return true
			end
		end
	end
	return false
end

local function ExportedGlowingSpellsHas(spellId)
	local seen = {}
	local function check(SAO)
		if type(SAO) ~= "table" or seen[SAO] then
			return false
		end
		seen[SAO] = true
		return TableGlowingSpellsHas(SAO.GlowingSpells, spellId)
	end
	return check(capturedSao) or check(_G.SpellActivationOverlayAddon) or check(_G.SAO)
end

--- Live glow IDs from hooked AddGlowNumber, LBG on stock buttons, or exported GlowingSpells.
function Glow.SaoMembership(spellId)
	if type(spellId) ~= "number" then
		return false
	end
	if IdInSet(glowingTriggers, spellId) then
		return true
	end
	if IdInSet(lbgCounts, spellId) then
		return true
	end
	return ExportedGlowingSpellsHas(spellId)
end

local function NativeOverlayed(spellId)
	local ISO = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed
	if type(ISO) ~= "function" then
		return nil
	end
	local ok, v = pcall(ISO, spellId)
	if not ok then
		return nil
	end
	return v and true or false
end

-- SHOW/HIDE is global, but HIDE is often missing on classic once SAO owns the
-- overlay (macro/target flips). overlayed[] must not pin Want forever on every
-- copy of that spell (macro, direct slot, Extra Buttons).
local function OverlayedRaw(spellId)
	if not spellId then
		return false
	end
	local native = NativeOverlayed(spellId)
	if native == true then
		return true
	end
	if Glow.SaoMembership(spellId) then
		return true
	end
	if native == false then
		-- ISO can lag a frame behind GLOW_SHOW; do not wipe a live SHOW id.
		return overlayed[spellId] and true or IdInSet(overlayed, spellId)
	end
	if UseNativeOverlayAPI() or not capturedSao then
		return overlayed[spellId] and true or IdInSet(overlayed, spellId)
	end
	return false
end

function Glow.Want(spellId)
	if type(spellId) ~= "number" then
		return false
	end
	if OverlayedRaw(spellId) then
		return true
	end
	local ov = OverrideSpell(spellId)
	if ov and ov ~= spellId and OverlayedRaw(ov) then
		return true
	end
	return false
end

function Glow.AnyWanted()
	return next(overlayed) ~= nil
end

--- Drop mixin glow events. Do not replace UpdateSpellAlert / UpdateOverlayGlow:
-- a Flux closure on those methods taints ActionBarButtonEventsFrame:OnEvent
-- (ACTIONBAR_SLOT_CHANGED → Update → SetAttribute on OverrideActionBar).
-- Stay off the collector; Effects.SyncColumn / Glow.Set own paint.
function Glow.SilenceMixin(widget)
	if not widget then
		return
	end
	if widget.UnregisterEvent then
		pcall(widget.UnregisterEvent, widget, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
		pcall(widget.UnregisterEvent, widget, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
	end
end

local function ResolveGlowSpell(frame)
	if not frame then
		return nil
	end
	local btn = frame.FluxButton or frame.ParentButton
	if btn then
		local FX = Flux.ButtonFX
		if FX and FX.SpellIdFromEBS then
			local sid = FX.SpellIdFromEBS(btn)
			if type(sid) == "number" then
				return sid
			end
		end
		if type(btn.SpellId) == "number" then
			return btn.SpellId
		end
	end
	local slot
	if frame.GetAttribute then
		slot = tonumber(frame:GetAttribute("action"))
	end
	if not slot then
		local host = frame._fluxHost
		slot = host and host.slot
	end
	if slot then
		local FX = Flux.ButtonFX
		if FX and FX.SpellIdFromAction then
			return FX.SpellIdFromAction(slot)
		end
	end
	return nil
end

local function SpellFromGlowButton(frame)
	if not frame then
		return nil
	end
	if frame.__sao and frame.__sao.GetGlowID then
		local ok, id = pcall(frame.__sao.GetGlowID)
		if ok and type(id) == "number" and id > 0 then
			return id
		end
	end
	local action = frame.action
	if not action and frame.GetAttribute then
		action = frame:GetAttribute("action")
	end
	action = tonumber(action)
	if action then
		local FX = Flux.ButtonFX
		if FX and FX.SpellIdFromAction then
			local sid = FX.SpellIdFromAction(action)
			if type(sid) == "number" then
				return sid
			end
		end
		if GetActionInfo then
			local ok, actionType, id, subType = pcall(GetActionInfo, action)
			if ok and actionType == "spell" and type(id) == "number" then
				return id
			end
			if ok and actionType == "macro" and subType == "spell" and type(id) == "number" then
				return id
			end
		end
	end
	return ResolveGlowSpell(frame)
end

local function MarkGlow(glowID, triggerID)
	if type(glowID) ~= "number" then
		return
	end
	triggerID = triggerID or glowID
	local t = glowingTriggers[glowID]
	if not t then
		t = {}
		glowingTriggers[glowID] = t
	end
	t[triggerID] = true
end

local function UnmarkTrigger(sao, triggerID, glowIDs)
	if type(triggerID) ~= "number" then
		return
	end
	local onlyThese
	if type(glowIDs) == "table" then
		onlyThese = {}
		for i = 1, #glowIDs do
			local glowID = glowIDs[i]
			if type(glowID) == "number" then
				onlyThese[glowID] = true
			elseif type(glowID) == "string" and sao and sao.GetSpellIDsByName then
				local ok, ids = pcall(sao.GetSpellIDsByName, sao, glowID)
				if ok and type(ids) == "table" then
					for j = 1, #ids do
						local id = ids[j]
						if type(id) == "number" then
							onlyThese[id] = true
						end
					end
				end
			end
		end
	end
	for glowID, triggers in pairs(glowingTriggers) do
		if triggers[triggerID] and (not onlyThese or onlyThese[glowID]) then
			triggers[triggerID] = nil
			if not next(triggers) then
				glowingTriggers[glowID] = nil
				overlayed[glowID] = nil
			end
		end
	end
end

local function HookAfter(tbl, key, hook)
	if type(tbl) ~= "table" or type(key) ~= "string" or type(hook) ~= "function" then
		return
	end
	if type(tbl[key]) ~= "function" then
		return
	end
	-- WoW: original stays secure; hook runs after. Plain Lua smoke: orig then hook.
	if hooksecurefunc then
		pcall(hooksecurefunc, tbl, key, hook)
		return
	end
	local orig = tbl[key]
	tbl[key] = function(...)
		orig(...)
		hook(...)
	end
end

local function BindSAO(SAO)
	if type(SAO) ~= "table" or type(SAO.AddGlow) ~= "function" then
		return
	end
	capturedSao = SAO
	if SAO._fluxGlowHooked then
		return
	end
	SAO._fluxGlowHooked = true
	HookAfter(SAO, "AddGlow", function()
		Notify()
	end)
	HookAfter(SAO, "AddGlowNumber", function(_, triggerID, glowID)
		MarkGlow(glowID, triggerID)
		Notify()
	end)
	HookAfter(SAO, "RemoveGlow", function(self, triggerID, glowIDs)
		UnmarkTrigger(self, triggerID, glowIDs)
		Notify()
	end)
	Notify()
end

local function InLockdown()
	if Flux.Combat and Flux.Combat.InLockdown then
		return Flux.Combat.InLockdown()
	end
	return InCombatLockdown and InCombatLockdown() or false
end

local function IsSaoTable(t)
	return type(t) == "table"
		and type(t.AddGlow) == "function"
		and type(t.AddGlowNumber) == "function"
		and type(t.RemoveGlow) == "function"
end

local function CommunitySaoLoaded()
	if _G.SpellActivationOverlayLABBinder or _G.SpellActivationOverlayDBLoader then
		return true
	end
	if C_AddOns and C_AddOns.IsAddOnLoaded then
		local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, "SpellActivationOverlay")
		if ok and loaded then
			return true
		end
	end
	if IsAddOnLoaded then
		local ok, loaded = pcall(IsAddOnLoaded, "SpellActivationOverlay")
		if ok and loaded then
			return true
		end
	end
	return false
end

local function SaoFromUpvalues(fn)
	if type(fn) ~= "function" then
		return nil
	end
	local getu = debug and debug.getupvalue
	if type(getu) ~= "function" then
		return nil
	end
	for i = 1, 40 do
		local ok, name, val = pcall(getu, fn, i)
		if not ok or name == nil then
			break
		end
		if IsSaoTable(val) then
			return val
		end
	end
	return nil
end

local function ScriptOf(frame)
	if not (frame and frame.GetScript) then
		return nil
	end
	local ok, fn = pcall(frame.GetScript, frame, "OnEvent")
	if ok and type(fn) == "function" then
		return fn
	end
	return nil
end

-- Never write _G.ipairs (taints nameplate Layout / collector). Never invoke
-- Blizzard's SpellActivationOverlay_OnEvent. Community SAO only.
local function CaptureSao()
	if capturedSao then
		return true
	end
	local known = _G.SpellActivationOverlayAddon or _G.SAO or _G.SpellActivationOverlay
	if IsSaoTable(known) then
		BindSAO(known)
		return capturedSao ~= nil
	end
	local frame = _G.SpellActivationOverlayAddonFrame
	if frame and IsSaoTable(frame.SAO) then
		BindSAO(frame.SAO)
		return capturedSao ~= nil
	end
	local fns = {
		ScriptOf(frame),
		ScriptOf(_G.SpellActivationOverlayLABBinder),
		ScriptOf(_G.SpellActivationOverlayGlowEngineFrame),
		ScriptOf(_G.SpellActivationOverlayDBLoader),
	}
	if CommunitySaoLoaded() then
		fns[#fns + 1] = _G.SpellActivationOverlay_OnEvent
		fns[#fns + 1] = _G.SpellActivationOverlay_OnLoad
		fns[#fns + 1] = _G.SpellActivationOverlay_OnChangeGeometry
		fns[#fns + 1] = _G.SpellActivationOverlay_ShowAllOverlays
	end
	for i = 1, #fns do
		local sao = SaoFromUpvalues(fns[i])
		if sao then
			BindSAO(sao)
			return capturedSao ~= nil
		end
	end
	local orig = ScriptOf(frame)
	if type(orig) ~= "function" or not CommunitySaoLoaded() then
		return capturedSao ~= nil
	end
	if InLockdown() then
		return false
	end
	if type(setfenv) ~= "function" or type(getfenv) ~= "function" then
		return capturedSao ~= nil
	end
	local okEnv, savedEnv = pcall(getfenv, orig)
	if not okEnv then
		return capturedSao ~= nil
	end
	savedEnv = savedEnv or _G
	local restored = false
	local function restoreEnv()
		if restored then
			return
		end
		restored = true
		pcall(setfenv, orig, savedEnv)
	end
	local function capturingIpairs(t)
		restoreEnv()
		if type(t) ~= "table" then
			local raw = savedEnv.ipairs or ipairs
			return raw(t)
		end
		local n = 0
		return function()
			n = n + 1
			local fn = t[n]
			if fn == nil then
				return nil
			end
			return n, function(frameArg, sao, ev, ...)
				BindSAO(sao)
				return fn(frameArg, sao, ev, ...)
			end
		end
	end
	local proxy = { ipairs = capturingIpairs }
	setmetatable(proxy, { __index = savedEnv })
	if not pcall(setfenv, orig, proxy) then
		return capturedSao ~= nil
	end
	pcall(orig, frame, "SPELLS_CHANGED")
	if not capturedSao then
		pcall(orig, frame, "PLAYER_LOGIN")
	end
	restoreEnv()
	return capturedSao ~= nil
end

-- Bind when SAO's frame runs, after Blizzard/SAO code. Live OnEvent stays SAO.
local function WrapSaoOnEvent()
	if onEventWrapped then
		return true
	end
	local frame = _G.SpellActivationOverlayAddonFrame
	if not (frame and frame.HookScript) then
		return false
	end
	onEventWrapped = true
	pcall(frame.HookScript, frame, "OnEvent", function()
		local sao = SaoAddon()
		if sao then
			BindSAO(sao)
		end
	end)
	return true
end

local function HookLBG()
	if lbgHooked or not LibStub then
		return lbgHooked
	end
	local ok, lib = pcall(LibStub, "LibButtonGlow-1.0", true)
	if not ok or not lib or type(lib.ShowOverlayGlow) ~= "function" then
		return false
	end
	lbgHooked = true
	local function IncLbg(sid)
		if type(sid) ~= "number" then
			return
		end
		lbgCounts[sid] = (lbgCounts[sid] or 0) + 1
	end
	local function DecLbg(sid)
		if type(sid) ~= "number" or not lbgCounts[sid] then
			return
		end
		lbgCounts[sid] = lbgCounts[sid] - 1
		if lbgCounts[sid] <= 0 then
			lbgCounts[sid] = nil
		end
	end
	HookAfter(lib, "ShowOverlayGlow", function(frame)
		if frame and frame.__sao and frame.__sao._fluxEffectGlow then
			Notify()
			return
		end
		local sid = SpellFromGlowButton(frame)
		local stamped = frame and frame._fluxLbgGlowSpell
		if frame then
			if stamped and sid and stamped ~= sid then
				DecLbg(stamped)
				frame._fluxLbgGlowSpell = nil
				stamped = nil
			end
			if sid and not stamped then
				IncLbg(sid)
				frame._fluxLbgGlowSpell = sid
			end
		end
		Notify()
	end)
	HookAfter(lib, "HideOverlayGlow", function(frame)
		if not (frame and frame.__sao and frame.__sao._fluxEffectGlow) then
			local sid = frame and frame._fluxLbgGlowSpell
			if not sid then
				sid = SpellFromGlowButton(frame)
			end
			if frame then
				frame._fluxLbgGlowSpell = nil
			end
			DecLbg(sid)
		end
		Notify()
	end)
	return true
end

local function TryBind()
	CaptureSao()
	local sao = SaoAddon()
	if sao then
		BindSAO(sao)
	end
	WrapSaoOnEvent()
	HookLBG()
	return capturedSao ~= nil
end

local function PulseBind()
	bindTries = bindTries + 1
	if TryBind() or bindTries >= 40 then
		if bindTicker and bindTicker.Cancel then
			bindTicker:Cancel()
		end
		bindTicker = nil
	end
end

local saoEnableDepth = 0

--- SAO __sao: membership + owner settle only. Flux owns glow paint.
function Glow.InstallSAO(frame)
	if not frame then
		return
	end
	frame.__sao = frame.__sao or {}
	frame.__sao._fluxEffectGlow = true
	frame.__sao.useExternalGlow = true
	frame.__sao.DoesIgnoreNative = function()
		return false
	end
	frame.__sao.GetGlowID = function()
		return ResolveGlowSpell(frame)
	end
	frame.__sao.EnableGlow = function()
		if saoEnableDepth > 0 then
			return
		end
		saoEnableDepth = saoEnableDepth + 1
		Notify()
		saoEnableDepth = saoEnableDepth - 1
	end
	frame.__sao.DisableGlow = function()
		if saoEnableDepth > 0 then
			return
		end
		saoEnableDepth = saoEnableDepth + 1
		Notify()
		saoEnableDepth = saoEnableDepth - 1
	end
end

function Glow.NotifySAO(frame)
	if not frame then
		return
	end
	Glow.InstallSAO(frame)
end

function Glow.Start()
	if started then
		return
	end
	started = true
	TryBind()
	local Ev = Flux.Events
	if Ev and Ev.Register then
		Ev.Register("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", function(_, spellId)
			if spellId then
				overlayed[spellId] = true
			end
			Notify()
		end)
		Ev.Register("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", function(_, spellId)
			if spellId then
				overlayed[spellId] = nil
			end
			Notify()
		end)
		Ev.Register("ADDON_LOADED", function(_, name)
			if name == "SpellActivationOverlay" then
				TryBind()
				Notify()
			end
		end)
		Ev.Register("PLAYER_LOGIN", function()
			TryBind()
			Notify()
		end)
		Ev.Register("PLAYER_REGEN_ENABLED", function()
			if not capturedSao then
				TryBind()
			end
			Notify()
		end)
	end
	if not capturedSao then
		local Timer = Flux.Timer
		if Timer and Timer.NewTicker then
			bindTicker = Timer.NewTicker(0.25, PulseBind, 40)
		end
	end
end

_G.FluxEffectGlow = Glow
