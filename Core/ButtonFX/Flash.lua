-- ButtonFX/Flash.lua — auto-attack / auto-shot / wand red flash.
-- Mixin OnEvent is detached, so Blizzard never StartFlash. Flux owns the
-- template Flash texture and blinks it like ActionBarActionButtonMixin.
-- Melee flash follows PLAYER_ENTER_COMBAT / PLAYER_LEAVE_COMBAT, not
-- tagged combat (a fight without an auto-attack swing is not melee flash).
local addonName, ns = ...
local Flux = ns.Flux

local ButtonFX = Flux.ButtonFX or {}
Flux.ButtonFX = ButtonFX

local Flash = {}
ButtonFX.Flash = Flash

local FLASH_ATLAS = "UI-HUD-ActionBar-IconFrame-Flash"
local FLASH_FILE = "Interface\\Buttons\\UI-QuickslotRed"
local ATTACK_SPELL_ID = 6603
local DF_RING_W, DF_RING_H, DF_SLOT = 46, 45, 44
local TICKER_KEY = "buttonfx.flash"

local flashing = {}
local nFlash = 0
local inMelee = false
local started = false
local listeners = {}
local flashTime = 0
local flashOn = false
local tickerArmed = false
local fallbackFrame

local function SafeBool(value)
	local S = Flux.Secrets
	if S and S.SafeBooleanTest then
		return S.SafeBooleanTest(value, false) and true or false
	end
	return value and true or false
end

local function UseQuickslotFlash()
	local C = Flux.Client
	if not C then
		return true
	end
	if C.isAnyClassic then
		return true
	end
	if C.isForever or C.isCamelot then
		return false
	end
	return not C.isPostDF
end

local function AtlasExists(name)
	if C_Texture and C_Texture.GetAtlasInfo then
		local ok, info = pcall(C_Texture.GetAtlasInfo, name)
		return ok and info and true or false
	end
	if GetAtlasInfo then
		local ok, info = pcall(GetAtlasInfo, name)
		return ok and info and true or false
	end
	return false
end

local function ResolveFlash(widget)
	if not widget then
		return nil
	end
	local tex = widget.Flash or widget._fluxAutoFlash
	if tex then
		return tex
	end
	local name = widget.GetName and widget:GetName()
	if name then
		tex = _G[name .. "Flash"]
		if tex then
			return tex
		end
	end
	local btn = widget.FluxButton
	if btn and btn.WFlashTexture then
		return btn.WFlashTexture
	end
	return nil
end

local function SizeFlash(tex, widget, useQuickslot)
	local w = (widget.GetWidth and widget:GetWidth()) or 0
	local h = (widget.GetHeight and widget:GetHeight()) or 0
	if type(w) ~= "number" or w < 1 then
		w = 36
	end
	if type(h) ~= "number" or h < 1 then
		h = 36
	end
	if tex._fluxFlashOwner == widget and tex._fluxFlashW == w and tex._fluxFlashH == h
		and tex._fluxFlashQuick == useQuickslot
	then
		return
	end
	tex._fluxFlashOwner = widget
	tex._fluxFlashW = w
	tex._fluxFlashH = h
	tex._fluxFlashQuick = useQuickslot
	if useQuickslot or not AtlasExists(FLASH_ATLAS) then
		if tex.SetTexture then
			tex:SetTexture(FLASH_FILE)
		end
		if tex.SetBlendMode then
			pcall(tex.SetBlendMode, tex, "ADD")
		end
		tex:SetSize(w, h)
		tex:ClearAllPoints()
		tex:SetPoint("CENTER", widget, "CENTER", 0, 0)
		if tex.SetDrawLayer then
			pcall(tex.SetDrawLayer, tex, "ARTWORK")
		end
	else
		if tex.SetAtlas then
			pcall(tex.SetAtlas, tex, FLASH_ATLAS, false)
		end
		tex:SetSize(DF_RING_W * (w / DF_SLOT), DF_RING_H * (h / DF_SLOT))
		tex:ClearAllPoints()
		tex:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
		if tex.SetDrawLayer then
			pcall(tex.SetDrawLayer, tex, "ARTWORK", 1)
		end
	end
end

function Flash.Ensure(widget)
	if not widget then
		return nil
	end
	local tex = ResolveFlash(widget)
	if not tex and widget.CreateTexture then
		tex = widget:CreateTexture(nil, "ARTWORK", nil, 1)
		widget._fluxAutoFlash = tex
		tex:Hide()
	end
	if not tex then
		return nil
	end
	widget.Flash = widget.Flash or tex
	local btn = widget.FluxButton
	if btn and not btn.WFlashTexture then
		btn.WFlashTexture = tex
	end
	SizeFlash(tex, widget, UseQuickslotFlash())
	if flashing[widget] then
		if flashOn then
			tex:Show()
		else
			tex:Hide()
		end
	end
	return tex
end

local function HideTex(tex)
	if tex and tex.Hide then
		tex:Hide()
	end
end

local function DisarmTicker()
	if not tickerArmed then
		return
	end
	tickerArmed = false
	flashOn = false
	flashTime = 0
	local T = Flux.Ticker
	if T and T.Remove then
		T.Remove(TICKER_KEY)
	end
	if fallbackFrame then
		fallbackFrame:SetScript("OnUpdate", nil)
		fallbackFrame:Hide()
	end
	_G.FluxPerfEBSFlashArmed = false
end

local function OnTick(elapsed)
	local t = flashTime - (elapsed or 0)
	if t <= 0 then
		local step = ATTACK_BUTTON_FLASH_TIME or 0.4
		local overtime = -t
		if overtime >= step then
			overtime = 0
		end
		t = step - overtime
		flashOn = not flashOn
		local any = false
		for widget, tex in pairs(flashing) do
			if widget and tex then
				any = true
				if flashOn then
					tex:Show()
				else
					tex:Hide()
				end
			end
		end
		if not any then
			nFlash = 0
			DisarmTicker()
			return
		end
	end
	flashTime = t
end

local function ArmTicker()
	if tickerArmed then
		return
	end
	tickerArmed = true
	flashTime = 0
	flashOn = false
	local T = Flux.Ticker
	if T and T.Add then
		T.Add(TICKER_KEY, OnTick)
	else
		if not fallbackFrame then
			fallbackFrame = CreateFrame("Frame")
		end
		fallbackFrame:SetScript("OnUpdate", function(_, elapsed)
			OnTick(elapsed)
		end)
		fallbackFrame:Show()
	end
	_G.FluxPerfEBSFlashArmed = true
end

function Flash.Set(widget, on)
	if not widget then
		return
	end
	if on then
		local tex = Flash.Ensure(widget)
		if not tex then
			return
		end
		if not flashing[widget] then
			flashing[widget] = tex
			nFlash = nFlash + 1
			ArmTicker()
		end
		return
	end
	if flashing[widget] then
		HideTex(flashing[widget])
		flashing[widget] = nil
		nFlash = nFlash - 1
		if nFlash <= 0 then
			nFlash = 0
			DisarmTicker()
		end
		return
	end
	HideTex(ResolveFlash(widget) or widget._fluxAutoFlash)
end

function Flash.InMeleeCombat()
	return inMelee and true or false
end

local function IsAttackSpell(spellId)
	if not spellId then
		return false
	end
	if tonumber(spellId) == ATTACK_SPELL_ID then
		return true
	end
	local S = Flux.Spell
	if S and S.IdsMatch then
		return S.IdsMatch(spellId, ATTACK_SPELL_ID) and true or false
	end
	return false
end

function Flash.WantSlot(slot)
	if not slot then
		return false
	end
	local A = Flux.Action
	if A then
		if A.IsAutoRepeat and A.IsAutoRepeat(slot) then
			return true
		end
		if inMelee and A.IsAttack and A.IsAttack(slot) and A.IsCurrent and A.IsCurrent(slot) then
			return true
		end
		return false
	end
	if IsAutoRepeatAction and SafeBool(IsAutoRepeatAction(slot)) then
		return true
	end
	if inMelee and IsAttackAction and IsCurrentAction
		and SafeBool(IsAttackAction(slot)) and SafeBool(IsCurrentAction(slot))
	then
		return true
	end
	return false
end

function Flash.WantSpell(spellId, nameRank)
	if not spellId and (type(nameRank) ~= "string" or nameRank == "") then
		return false
	end
	local S = Flux.Spell
	if S and S.IsAutoRepeat and S.IsAutoRepeat(spellId, nameRank) then
		return true
	end
	if inMelee and IsAttackSpell(spellId) then
		if S and S.IsCurrent and S.IsCurrent(spellId, nameRank) then
			return true
		end
		if IsCurrentSpell then
			local ident = spellId or nameRank
			local ok, v = pcall(IsCurrentSpell, ident)
			if ok and SafeBool(v) then
				return true
			end
		end
	end
	if C_Spell and C_Spell.IsAutoRepeatSpell then
		local ident = spellId or nameRank
		local ok, v = pcall(C_Spell.IsAutoRepeatSpell, ident)
		if ok and SafeBool(v) then
			return true
		end
	end
	if IsAutoRepeatSpell then
		local ident = spellId or nameRank
		local ok, v = pcall(IsAutoRepeatSpell, ident)
		if ok and SafeBool(v) then
			return true
		end
	end
	return false
end

function Flash.WantItem(itemId)
	if not itemId then
		return false
	end
	local I = Flux.Item
	if I and I.GetSpell then
		local name, spellId = I.GetSpell(itemId)
		if spellId or name then
			return Flash.WantSpell(spellId, name)
		end
	end
	if GetItemSpell then
		local ok, name, rankOrId, spellID = pcall(GetItemSpell, itemId)
		if ok then
			local sid = spellID
			if type(sid) ~= "number" and type(rankOrId) == "number" then
				sid = rankOrId
			end
			if sid or name then
				return Flash.WantSpell(sid, name)
			end
		end
	end
	return false
end

local function Notify()
	for i = 1, #listeners do
		local fn = listeners[i]
		if fn then
			pcall(fn)
		end
	end
end

function Flash.OnChange(fn)
	if type(fn) == "function" then
		listeners[#listeners + 1] = fn
	end
end

function Flash.Start()
	if started then
		return
	end
	started = true
	local Ev = Flux.Events
	if not (Ev and Ev.Register) then
		return
	end
	Ev.Register("PLAYER_ENTER_COMBAT", function()
		inMelee = true
		Notify()
	end)
	Ev.Register("PLAYER_LEAVE_COMBAT", function()
		inMelee = false
		Notify()
	end)
	Ev.Register("START_AUTOREPEAT_SPELL", Notify)
	Ev.Register("STOP_AUTOREPEAT_SPELL", Notify)
end

_G.FluxEffectFlash = Flash
