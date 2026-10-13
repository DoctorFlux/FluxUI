-- ButtonFX/Cast.lua — one UNIT_SPELLCAST dispatcher (Blizzard ActionBarActionEventsFrame
-- pattern, LAB-style). Match spell identity, not dummy action 10000. Exclusive owner
-- so 19 columns do not all light up. Own dispatcher only; never the stock
-- action-button event collectors.
-- FollowColumn exclusively settles fill/interrupt/burst: transfer live paint,
-- appear at UnitCastingInfo progress, or ForceClear when the face left the spell
-- (SHIFT/CTRL swap, page change, macro condition / item flip).
local addonName, ns = ...
local Flux = ns.Flux

local ButtonFX = Flux.ButtonFX or {}
Flux.ButtonFX = ButtonFX

local Cast = {}
ButtonFX.Cast = Cast

Cast.RANK_MAIN = 1
Cast.RANK_MINI = 2
Cast.RANK_EBS = 3
Cast.RANK_BADGE = 4

local function OptionsTable()
	local fo = _G.FluxOptions
	if fo and fo.GetActionbarsDB then
		local ok, t = pcall(fo.GetActionbarsDB, fo)
		if ok then
			return t
		end
	end
	return nil
end

--- Post-DF always runs retail overlays. Pre-DF follows Action Bars → Enable VFX.
function Cast.IsSpellCastVFXEnabled()
	if Flux.Client and Flux.Client.isPostDF then
		return true
	end
	local t = OptionsTable()
	if t and t.spellCastVFX == false then
		return false
	end
	return true
end

local UNIT_PLAYER = "player"
local UNIT_PET = "pet"

local entries = {}
local started = false
local activeCasts = {}
local activeReticle
local castGen = 0
local reticleWatching = false
local lastEvent
local lastSpell
local lastOwner

-- Isolated from player Cast._active / activeCasts / interrupt-finish / reticle.
local petBag = {
	activeCasts = {},
	castGen = 0,
	activeReticle = nil,
	lastSpell = nil,
}

local function NormUnit(unit)
	if unit == UNIT_PET then
		return UNIT_PET
	end
	return UNIT_PLAYER
end

local function IsPetUnit(unit)
	return NormUnit(unit) == UNIT_PET
end

local function EntryUnit(entry)
	if not entry then
		return UNIT_PLAYER
	end
	if entry.unit == UNIT_PET then
		return UNIT_PET
	end
	if entry.widget and entry.widget._fluxVfxUnit == UNIT_PET then
		return UNIT_PET
	end
	return UNIT_PLAYER
end

local function CastList(unit)
	if IsPetUnit(unit) then
		return petBag.activeCasts
	end
	return activeCasts
end

local function SetCastList(unit, list)
	list = list or {}
	if IsPetUnit(unit) then
		petBag.activeCasts = list
	else
		activeCasts = list
	end
end

local function BumpGen(unit)
	if IsPetUnit(unit) then
		petBag.castGen = petBag.castGen + 1
	else
		castGen = castGen + 1
	end
end

local function GenOf(unit)
	if IsPetUnit(unit) then
		return petBag.castGen
	end
	return castGen
end

local function LastSpellOf(unit)
	if IsPetUnit(unit) then
		return petBag.lastSpell
	end
	return lastSpell
end

local function GetActive(unit)
	if IsPetUnit(unit) then
		return Cast._petActive
	end
	return Cast._active
end

local function SetActive(unit, value)
	if IsPetUnit(unit) then
		Cast._petActive = value
	else
		Cast._active = value
	end
end

local function GetInterrupt(unit)
	if IsPetUnit(unit) then
		return Cast._petInterrupt
	end
	return Cast._interrupt
end

local function SetInterrupt(unit, value)
	if IsPetUnit(unit) then
		Cast._petInterrupt = value
	else
		Cast._interrupt = value
	end
end

local function SetFinish(unit, value)
	if IsPetUnit(unit) then
		Cast._petFinish = value
	else
		Cast._finish = value
	end
end

local function GetReticle(unit)
	if IsPetUnit(unit) then
		return Cast._petReticle
	end
	return Cast._reticle
end

local function SetReticle(unit, value)
	if IsPetUnit(unit) then
		Cast._petReticle = value
	else
		Cast._reticle = value
	end
end

local function GetReticleOwners(unit)
	if IsPetUnit(unit) then
		return Cast._petReticleOwners
	end
	return Cast._reticleOwners
end

local function SetReticleOwners(unit, value)
	if IsPetUnit(unit) then
		Cast._petReticleOwners = value
	else
		Cast._reticleOwners = value
	end
end

local function GetActiveReticle(unit)
	if IsPetUnit(unit) then
		return petBag.activeReticle
	end
	return activeReticle
end

local function SetActiveReticle(unit, value)
	if IsPetUnit(unit) then
		petBag.activeReticle = value
	else
		activeReticle = value
	end
end

local Overlay
local StopReticleWatch

local function FXOverlay()
	Overlay = Overlay or (ButtonFX.Overlay)
	return Overlay
end

local function SafeNum(value)
	if value == nil then
		return nil
	end
	if Flux.Secrets then
		if Flux.Secrets.IsSecretValue and Flux.Secrets.IsSecretValue(value) then
			return nil
		end
	end
	local n = tonumber(value)
	if n and n > 0 then
		return n
	end
	return nil
end

-- Cooldown, checked, flyout and glow each need the slot's spell, so a full
-- paint used to resolve it four times per button. BeginSlotPass/EndSlotPass
-- bracket a paint so the answer is computed once per slot per pass; outside a
-- pass there is no memo, and a stale answer is impossible.
local slotSpellMemo = {}
local memoActive = false

function ButtonFX.BeginSlotPass()
	memoActive = true
	for slot in pairs(slotSpellMemo) do
		slotSpellMemo[slot] = nil
	end
end

function ButtonFX.EndSlotPass()
	memoActive = false
end

local function ItemSpellId(itemId)
	if not itemId then
		return nil
	end
	if C_Item and C_Item.GetItemSpell then
		local ok, _, sid = pcall(C_Item.GetItemSpell, itemId)
		if ok and sid then
			return SafeNum(sid) or sid
		end
	end
	if GetItemSpell then
		local ok, _, sid = pcall(GetItemSpell, itemId)
		if ok and sid then
			return SafeNum(sid) or sid
		end
	end
	return nil
end

local function ResolveProgramShownSpell(slot)
	local Bars = Flux.Bars
	local PF = Bars and Bars.ProgramFace
	if PF and PF.ShownForSlot then
		local kind, id = PF.ShownForSlot(slot)
		if kind == "spell" then
			return SafeNum(id) or id
		end
		if kind == "item" then
			return ItemSpellId(id)
		end
	end
	local SP = Bars and Bars.SlotProgram
	local body = SP and SP.Get and SP.Get(slot)
	if type(body) ~= "string" or body == "" then
		return nil
	end
	local EBS = Flux.EBS
	local Shown = EBS and EBS.Action and EBS.Action.ShownFromBody
	if not Shown then
		return nil
	end
	local kind, id = Shown(body)
	if kind == "spell" then
		return SafeNum(id) or id
	end
	if kind == "item" then
		return ItemSpellId(id)
	end
	return nil
end

local function ResolveSpellIdFromAction(slot)
	local shown = ResolveProgramShownSpell(slot)
	if shown then
		return shown
	end
	local A = Flux.Action
	if A and A.IsAssistedCombat and A.IsAssistedCombat(slot) then
		local nextId = A.GetAssistedNextSpell and A.GetAssistedNextSpell()
		if nextId then
			return nextId
		end
	end
	if GetActionInfo then
		local ok, actionType, id, subType = pcall(GetActionInfo, slot)
		if ok and actionType then
			if actionType == "spell" then
				return SafeNum(id) or id
			end
			if actionType == "macro" then
				if subType == "spell" then
					return SafeNum(id) or id
				end
				if GetMacroSpell then
					local okm, sid = pcall(GetMacroSpell, id)
					if okm and sid then
						return SafeNum(sid) or sid
					end
				end
				if GetMacroItem then
					local okItem, _, itemLink = pcall(GetMacroItem, id)
					if okItem then
						if C_Item and C_Item.GetItemSpell then
							local okSpell, _, itemSpell = pcall(C_Item.GetItemSpell, itemLink)
							if okSpell and itemSpell then
								return SafeNum(itemSpell) or itemSpell
							end
						end
						if GetItemSpell then
							local okSpell, _, itemSpell = pcall(GetItemSpell, itemLink)
							if okSpell and itemSpell then
								return SafeNum(itemSpell) or itemSpell
							end
						end
					end
				end
				-- Do not fall through to C_ActionBar.GetSpell: that id lags behind
				-- macro conditions and would keep a proc glow on the old face.
				return nil
			end
			if actionType == "item" then
				if C_Item and C_Item.GetItemSpell then
					local okItem, _, sid = pcall(C_Item.GetItemSpell, id)
					if okItem then
						return SafeNum(sid)
					end
				end
				if GetItemSpell then
					local okItem, _, sid = pcall(GetItemSpell, id)
					if okItem then
						return SafeNum(sid)
					end
				end
			end
		end
	end
	if C_ActionBar and C_ActionBar.GetSpell then
		local ok, sid = pcall(C_ActionBar.GetSpell, slot)
		if ok then
			sid = SafeNum(sid)
			if sid and sid > 0 then
				return sid
			end
		end
	end
	return nil
end

function ButtonFX.SpellIdFromAction(slot)
	slot = tonumber(slot)
	if not slot then
		return nil
	end
	if not memoActive then
		return ResolveSpellIdFromAction(slot)
	end
	local hit = slotSpellMemo[slot]
	if hit ~= nil then
		if hit == false then
			return nil
		end
		return hit
	end
	local resolved = ResolveSpellIdFromAction(slot)
	slotSpellMemo[slot] = resolved == nil and false or resolved
	return resolved
end

function ButtonFX.SpellIdFromEBS(btn)
	if not btn then
		return nil
	end
	if btn.ActionType == "pet" then
		local P = Flux.Pet
		local slot = btn.PetSlot or btn.ActionValue
		if P and P.GetActionInfo and slot then
			local _, _, _, _, _, _, spellID = P.GetActionInfo(slot)
			local petSid = SafeNum(spellID)
			if petSid then
				return petSid
			end
		end
	end
	local sid = btn.SpellId
	if btn.IsAssistedCombat then
		sid = btn.AssistedNextSpellId or sid
		if (not sid or sid == 0) and Flux.EBS and Flux.EBS.Action and Flux.EBS.Action.GetAssistantNextSpell then
			sid = Flux.EBS.Action.GetAssistantNextSpell() or sid
		end
	elseif btn._fluxManagedFaceSpellId then
		sid = btn._fluxManagedFaceSpellId
	end
	if sid and Flux.Spell and Flux.Spell.GetOverrideSpell then
		sid = Flux.Spell.GetOverrideSpell(sid) or sid
	end
	sid = SafeNum(sid)
	if sid then
		return sid
	end
	local itemId = btn.ItemId or btn.ToyId
	if itemId then
		if C_Item and C_Item.GetItemSpell then
			local ok, _, itemSpell = pcall(C_Item.GetItemSpell, itemId)
			if ok then
				return SafeNum(itemSpell)
			end
		end
		if GetItemSpell then
			local ok, _, itemSpell = pcall(GetItemSpell, itemId)
			if ok then
				return SafeNum(itemSpell)
			end
		end
	end
	return nil
end

-- Override morphs (form, talent swap) only. Rank 5 and Rank 6 must stay distinct.
local function Normalize(spellId)
	spellId = SafeNum(spellId) or tonumber(spellId)
	if not spellId then
		return nil
	end
	if Flux.Spell and Flux.Spell.GetOverrideSpell then
		local ov = Flux.Spell.GetOverrideSpell(spellId)
		ov = SafeNum(ov) or ov
		if ov then
			spellId = ov
		end
	end
	return spellId
end

local function SpellName(spellId)
	if not spellId then
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
		if ok then
			if type(name) == "table" then
				name = name.name
			end
			if type(name) == "string" and name ~= "" then
				return name
			end
		end
	end
	return nil
end

local function WidgetShown(widget)
	if not widget or widget._fluxParked then
		return false
	end
	if widget._fluxBadgeCombatVisHidden then
		return false
	end
	if widget.GetAlpha then
		local ok, a = pcall(widget.GetAlpha, widget)
		if ok and type(a) == "number" and a <= 0 then
			return false
		end
	end
	if widget.IsShown and not widget:IsShown() then
		return false
	end
	return true
end

local function SpellOf(entry)
	if not entry then
		return nil
	end
	if entry.getSpellId then
		local ok, sid = pcall(entry.getSpellId, entry.widget)
		if ok then
			return sid
		end
	end
	return nil
end

local function StripColumn(widget)
	if not widget then
		return nil
	end
	local host = widget._fluxHost
	if host and host.column then
		return host.column
	end
	local strip = widget._fluxBadgeHost
	if type(strip) == "table" then
		local ph = strip._fluxHost
		if ph and ph.column then
			return ph.column
		end
	end
	local btn = widget.FluxButton
	if btn and btn._fluxBadgeHost then
		local s = btn._fluxBadgeHost
		local ph = s._fluxHost
		if ph and ph.column then
			return ph.column
		end
	end
	return nil
end

local function OwnerKey(entry, widget)
	local rank = entry.rank or Cast.RANK_EBS
	-- Bar-hosted badges share the strip column. Extra window stays RANK_EBS + "ebs:".
	if rank <= Cast.RANK_MINI or rank == Cast.RANK_BADGE then
		local col = StripColumn(widget)
		if col then
			return "col:" .. tostring(col)
		end
		if rank == Cast.RANK_BADGE then
			return "badge:" .. tostring(widget)
		end
		return "host:" .. tostring(widget)
	end
	return "ebs:" .. tostring(widget)
end

local function FaceIsLive(ov, widget)
	if not ov or not widget then
		return false
	end
	if ov.IsLiveCast and ov.IsLiveCast(widget) then
		return true
	end
	if ov.IsLiveBurst and ov.IsLiveBurst(widget) then
		return true
	end
	if ov.IsLiveInterrupt and ov.IsLiveInterrupt(widget) then
		return true
	end
	if ov.IsLiveReticle and ov.IsLiveReticle(widget) then
		return true
	end
	return false
end

local function FaceIsPressed(ov, widget)
	if not ov or not widget then
		return false
	end
	if ov.IsPushed then
		return ov.IsPushed(widget) and true or false
	end
	return false
end

-- Live match > pressed > main rank. Do not steal a matching mini just because
-- RANK_MAIN is lower.
local function OwnerScore(ov, widget, rank)
	local score = 20 - (rank or Cast.RANK_EBS)
	if FaceIsLive(ov, widget) then
		score = score + 1000
	end
	if FaceIsPressed(ov, widget) then
		score = score + 100
	end
	return score
end

local function SpellRankText(spellId)
	if Flux.Spell and Flux.Spell.GetSubtext then
		local ok, sub = pcall(Flux.Spell.GetSubtext, spellId)
		if ok and type(sub) == "string" and sub ~= "" then
			return sub
		end
	end
	if GetSpellSubtext then
		local ok, sub = pcall(GetSpellSubtext, spellId)
		if ok and type(sub) == "string" and sub ~= "" then
			return sub
		end
	end
	if Flux.Spell and Flux.Spell.GetInfo then
		local ok, _, rank = pcall(Flux.Spell.GetInfo, spellId)
		if ok and type(rank) == "string" and rank ~= "" then
			return rank
		end
	end
	if GetSpellInfo then
		local ok, name, rank = pcall(GetSpellInfo, spellId)
		if ok then
			if type(name) == "table" then
				rank = name.rank
			end
			if type(rank) == "string" and rank ~= "" then
				return rank
			end
		end
	end
	return nil
end

-- Rank 5 vs Rank 6 stay distinct. Empty subtext (retail) may still share a name/base.
local function RanksCompatible(a, b)
	local ra, rb = SpellRankText(a), SpellRankText(b)
	if ra or rb then
		return ra == rb
	end
	return true
end

local function BaseId(spellId)
	spellId = SafeNum(spellId) or tonumber(spellId)
	if not spellId then
		return nil
	end
	if Flux.Spell and Flux.Spell.GetBaseSpell then
		local ok, base = pcall(Flux.Spell.GetBaseSpell, spellId)
		if ok then
			base = SafeNum(base) or base
			if base and base ~= 0 then
				return base
			end
		end
	end
	if FindBaseSpellByID then
		local ok, base = pcall(FindBaseSpellByID, spellId)
		if ok then
			base = SafeNum(base) or base
			if base and base ~= 0 then
				return base
			end
		end
	end
	return spellId
end

function ButtonFX.SpellIdsMatch(a, b)
	if not a or not b then
		return false
	end
	local okEq, same = pcall(function()
		return a == b
	end)
	if okEq and same then
		return true
	end
	local function sameNum(x, y)
		if not x or not y then
			return false
		end
		local ok, match = pcall(function()
			return x == y
		end)
		return ok and match
	end
	local na, nb = Normalize(a), Normalize(b)
	if sameNum(na, nb) and RanksCompatible(a, b) then
		return true
	end
	local ba, bb = BaseId(a), BaseId(b)
	if sameNum(ba, bb) and RanksCompatible(a, b) then
		return true
	end
	local nameA, nameB = SpellName(a), SpellName(b)
	if nameA and nameB and nameA == nameB and RanksCompatible(a, b) then
		return true
	end
	return false
end

local function NameMatchesFace(sid, spellName)
	if type(spellName) ~= "string" or spellName == "" then
		return false
	end
	if Flux.Spell and Flux.Spell.FormatCastAttribute then
		local ok, token = pcall(Flux.Spell.FormatCastAttribute, sid)
		if ok and token == spellName then
			return true
		end
	end
	local name = SpellName(sid)
	local rank = SpellRankText(sid)
	if name and rank and spellName == name .. "(" .. rank .. ")" then
		return true
	end
	if name ~= spellName then
		return false
	end
	-- Bare "Flamestrike" is every rank. Ranked faces need Rank N in the token.
	if rank then
		return false
	end
	return true
end

local function FaceMatches(entry, spellId, spellName)
	local sid = SpellOf(entry)
	if not sid then
		return false
	end
	local id = SafeNum(spellId) or spellId
	if id then
		local ok, match = pcall(ButtonFX.SpellIdsMatch, sid, id)
		if ok and match then
			return true
		end
		if SafeNum(spellId) and (type(spellName) ~= "string" or spellName == "") then
			return false
		end
	end
	return NameMatchesFace(sid, spellName)
end

-- Every shown face whose current spell/item/macro identity matches.
-- Reticle uses this so the same thing can light more than one bar or Extra Button.
function Cast.PickAllMatching(spellId, spellName, unit)
	unit = NormUnit(unit)
	local list = {}
	if not spellId and (type(spellName) ~= "string" or spellName == "") then
		return list
	end
	for i = 1, #entries do
		local e = entries[i]
		local w = e.widget
		if EntryUnit(e) == unit and WidgetShown(w) and FaceMatches(e, spellId, spellName) then
			list[#list + 1] = w
		end
	end
	return list
end

-- One shown match per column (live/pressed over main rank). Extra Buttons are
-- their own keys. Current slot spell/item identity only — never a stale stamp.
function Cast.PickOwners(spellId, spellName, unit)
	unit = NormUnit(unit)
	local best = {}
	if not spellId and (type(spellName) ~= "string" or spellName == "") then
		return best
	end
	local ov = FXOverlay()
	for i = 1, #entries do
		local e = entries[i]
		local w = e.widget
		if EntryUnit(e) == unit and WidgetShown(w) and FaceMatches(e, spellId, spellName) then
			local key = OwnerKey(e, w)
			local rank = e.rank or Cast.RANK_EBS
			local score = OwnerScore(ov, w, rank)
			local prev = best[key]
			if not prev or score > prev.score then
				best[key] = { widget = w, rank = rank, score = score }
			end
		end
	end
	local list = {}
	for _, rec in pairs(best) do
		list[#list + 1] = rec.widget
	end
	return list
end

function Cast.PickOwner(spellId)
	local list = Cast.PickOwners(spellId, nil)
	return list[1]
end

function Cast.PickOwnerByName(name)
	local list = Cast.PickOwners(nil, name)
	return list[1]
end

local function LiveCastName(unit)
	unit = NormUnit(unit)
	local function fromUnit(fn)
		if type(fn) ~= "function" then
			return nil
		end
		local ok, name, _, _, _, _, _, _, _, spellId = pcall(fn, unit)
		if not ok then
			return nil
		end
		local id = SafeNum(spellId)
		if id and Flux.Spell and Flux.Spell.FormatCastAttribute then
			local okT, token = pcall(Flux.Spell.FormatCastAttribute, id)
			if okT and type(token) == "string" and token ~= "" then
				return token
			end
		end
		if type(name) == "string" and name ~= "" then
			return name
		end
		return nil
	end
	return fromUnit(UnitCastingInfo) or fromUnit(UnitChannelInfo)
end

local function IsCastGuid(value)
	return type(value) == "string" and value:find("^Cast%-") ~= nil
end

local function ResolveSpellName(spellName, unit)
	if IsCastGuid(spellName) then
		spellName = nil
	end
	if type(spellName) ~= "string" or spellName == "" then
		spellName = LiveCastName(unit)
	end
	return spellName
end

local function PickBy(picker, spellId, spellName, unit)
	unit = NormUnit(unit)
	spellName = ResolveSpellName(spellName, unit)
	local id = SafeNum(spellId)
	if id then
		local list = picker(id, spellName, unit)
		if #list > 0 then
			return list
		end
	elseif spellId then
		local list = picker(spellId, spellName, unit)
		if #list > 0 then
			return list
		end
	end
	if type(spellName) == "string" and spellName ~= "" then
		return picker(nil, spellName, unit)
	end
	return {}
end

-- Per-column exclusive for fill/interrupt. Rank 5 is not Rank 6.
local function PickSmart(spellId, spellName, unit)
	return PickBy(Cast.PickOwners, spellId, spellName, unit)
end

-- Same identity on every shown face. A different spell/item/macro is not a match.
local function PickReticleOwners(spellId, spellName, unit)
	return PickBy(Cast.PickAllMatching, spellId, spellName, unit)
end

local function PickPressed()
	local ov = FXOverlay()
	local best = {}
	if ov and ov.ForEachPressed then
		ov.ForEachPressed(function(widget)
			if not WidgetShown(widget) then
				return
			end
			for i = 1, #entries do
				local e = entries[i]
				if e.widget == widget then
					if EntryUnit(e) == UNIT_PET then
						break
					end
					local key = OwnerKey(e, widget)
					local rank = e.rank or Cast.RANK_EBS
					local prev = best[key]
					if not prev or rank < prev.rank then
						best[key] = { widget = widget, rank = rank }
					end
					break
				end
			end
		end)
	end
	local list = {}
	for _, rec in pairs(best) do
		list[#list + 1] = rec.widget
	end
	return list
end

-- Ground-target channels (Blizzard): the click is on the world, not the button.
-- PickSmart by bare name fails on ranked Classic faces; keep the reticle owners.
local function CopyWidgetList(list)
	local out = {}
	for i = 1, #(list or {}) do
		if list[i] then
			out[#out + 1] = list[i]
		end
	end
	return out
end

local function PickStartOwners(spellId, spellName, unit)
	unit = NormUnit(unit)
	local owners = PickSmart(spellId, spellName, unit)
	if IsPetUnit(unit) then
		if #owners == 0 then
			local rid = Cast._petReticle and Cast._petReticle.spellID
			if rid then
				owners = PickSmart(rid, nil, unit)
			end
		end
		if #owners == 0 then
			owners = CopyWidgetList(Cast._petReticleOwners)
		end
		if #owners == 0 and petBag.activeReticle then
			owners = { petBag.activeReticle }
		end
		return owners
	end
	if #owners == 0 then
		owners = PickPressed()
	end
	if #owners == 0 then
		local rid = Cast._reticle and Cast._reticle.spellID
		if rid then
			owners = PickSmart(rid, nil, unit)
		end
	end
	if #owners == 0 then
		owners = CopyWidgetList(Cast._reticleOwners)
	end
	if #owners == 0 and activeReticle then
		owners = { activeReticle }
	end
	return owners
end

local function SpellFromPayload(...)
	-- Retail: castGUID, spellID. Classic: spellName, rank, lineID, spellID.
	local n = select("#", ...)
	local lastNum, firstString, secondString, lastOther
	for i = 1, n do
		local v = select(i, ...)
		if type(v) == "number" then
			if v > 0 then
				lastNum = v
			end
		elseif type(v) == "string" and v ~= "" then
			if not v:find("^Cast%-") then
				if not firstString then
					firstString = v
				elseif not secondString then
					secondString = v
				end
			end
		elseif v ~= nil and type(v) ~= "boolean" and type(v) ~= "table" then
			lastOther = v
		end
	end
	if firstString and secondString then
		firstString = firstString .. "(" .. secondString .. ")"
	end
	return lastNum or lastOther, firstString
end

local function PayloadBoolean(...)
	local n = select("#", ...)
	for i = 1, n do
		local v = select(i, ...)
		if type(v) == "boolean" then
			return v
		end
	end
	return nil
end

local function DirtyChecked()
	if Flux.Bars and Flux.Bars.RequestPaint then
		Flux.Bars.RequestPaint("bars.checked")
	end
	local EBS = Flux.EBS
	if EBS and EBS.Paint and EBS.Paint.RequestCheckedSettle then
		EBS.Paint.RequestCheckedSettle()
	elseif EBS and EBS.Paint and EBS.Paint.RequestChecked then
		EBS.Paint.RequestChecked()
	elseif Flux.Scheduler and Flux.Scheduler.Request then
		Flux.Scheduler.Request("eval", "ebs.checked")
	end
end

local function WidgetSet(list)
	local set = {}
	for i = 1, #(list or {}) do
		set[list[i]] = true
	end
	return set
end

-- One ground-target spell owns the reticle. Switching Flamestrike → Blizzard
-- must ClearReticle on the previous face, not append a second overlay.
local function ClaimReticle(ov, owners, spellId, unit)
	unit = NormUnit(unit)
	owners = owners or {}
	local keep = WidgetSet(owners)
	local function drop(widget)
		if not widget or keep[widget] then
			return
		end
		if ov and ov.ClearReticle then
			ov.ClearReticle(widget)
		end
	end
	local prev = GetReticleOwners(unit)
	if prev then
		for i = 1, #prev do
			drop(prev[i])
		end
	end
	drop(GetActiveReticle(unit))
	for i = 1, #entries do
		local e = entries[i]
		if EntryUnit(e) == unit then
			local w = e.widget
			if w and not keep[w] then
				local live = w._fluxHadReticle
				if not live and ov and ov.IsLiveReticle then
					live = ov.IsLiveReticle(w)
				end
				if live then
					drop(w)
				end
			end
		end
	end
	SetReticleOwners(unit, owners)
	SetActiveReticle(unit, owners[1])
	if spellId then
		SetReticle(unit, { spellID = spellId })
	end
end

local function StampInflight(list, spellId)
	for i = 1, #(list or {}) do
		local w = list[i]
		if w then
			w._fluxCastSpell = spellId
		end
	end
end

local function ClearInflight(list)
	for i = 1, #(list or {}) do
		local w = list[i]
		if w then
			w._fluxCastSpell = nil
		end
	end
end

local function RewriteOwners(list, from, to)
	local out = {}
	local seen = {}
	local replaced = false
	for i = 1, #(list or {}) do
		local w = list[i]
		if w == from then
			w = to
			replaced = true
		end
		if w and w ~= from and not seen[w] then
			seen[w] = true
			out[#out + 1] = w
		end
	end
	if not replaced and to and not seen[to] then
		out[#out + 1] = to
	end
	return out
end

local function ColumnWidgets(column)
	local Bars = Flux.Bars
	local col = Bars and Bars.GetHost and Bars.GetHost(column)
	if not col then
		return {}
	end
	local out = {}
	if col.main and col.main.widget then
		out[#out + 1] = col.main.widget
	end
	if col.sec and col.sec.widget then
		out[#out + 1] = col.sec.widget
	end
	if col.tert and col.tert.widget then
		out[#out + 1] = col.tert.widget
	end
	local BH = Bars.BadgeHost
	if BH and BH.GetVisibleBadgesForButton then
		local n = #out
		for i = 1, n do
			local list = BH.GetVisibleBadgesForButton(out[i])
			if list then
				for j = 1, #list do
					local w = list[j] and list[j].Widget
					if w and not w._fluxBadgeCombatVisHidden then
						out[#out + 1] = w
					end
				end
			end
		end
	end
	return out
end

local function EntryOf(widget)
	for i = 1, #entries do
		if entries[i].widget == widget then
			return entries[i]
		end
	end
	return nil
end

-- Dest is the unparked host whose current slot spell/item matches inflight.
-- Keep a live match; else prefer pressed, then rank. Nil GetMacroSpell is lag,
-- not a match — do not keep VFX via a stale stamp.
local function BestFace(ov, widgets, inflight)
	if not inflight then
		return nil
	end
	local best, bestScore
	for i = 1, #widgets do
		local w = widgets[i]
		if WidgetShown(w) then
			local e = EntryOf(w)
			local rank = (e and e.rank) or 99
			-- RANK_BADGE is in the column list for bar-hosted Extra faces.
			if rank <= Cast.RANK_MINI or rank == Cast.RANK_BADGE then
				local sid = SpellOf(e)
				if sid then
					local ok, match = pcall(ButtonFX.SpellIdsMatch, sid, inflight)
					if ok and match then
						local score = OwnerScore(ov, w, rank)
						if not best or score > bestScore then
							best, bestScore = w, score
						end
					end
				end
			end
		end
	end
	return best
end

local function ColumnIdentityLag(widgets)
	for i = 1, #widgets do
		local w = widgets[i]
		if w and not w._fluxParked then
			local sid = SpellOf(EntryOf(w))
			if not sid then
				return true
			end
		end
	end
	return false
end

local function LiveSource(ov, widgets, column)
	for i = 1, #widgets do
		local w = widgets[i]
		if ov.IsLiveCast and ov.IsLiveCast(w) then
			return w
		end
		if ov.IsLiveReticle and ov.IsLiveReticle(w) then
			return w
		end
		if ov.IsLiveInterrupt and ov.IsLiveInterrupt(w) then
			return w
		end
	end
	for i = 1, #activeCasts do
		local w = activeCasts[i]
		local host = w and w._fluxHost
		if host and host.column == column then
			return w
		end
	end
	if activeReticle then
		local host = activeReticle._fluxHost
		if host and host.column == column then
			return activeReticle
		end
	end
	return nil
end

local LATCH = 0.35

local function Now()
	return (GetTime and GetTime()) or 0
end

local function OverlayKinds()
	local ov = FXOverlay()
	return (ov and ov.CAST) or 1, (ov and ov.CHANNEL) or 2, (ov and ov.EMPOWER) or 3
end

local function ChannelingNow(unit)
	unit = NormUnit(unit)
	if type(UnitChannelInfo) ~= "function" then
		return false
	end
	local ok, name = pcall(UnitChannelInfo, unit)
	if not ok or name == nil or name == false or name == "" then
		return false
	end
	return true
end

-- SUCCEEDED fires when a channel/empower begins. Do not burst those fills.
local function LiveFillKind(unit)
	unit = NormUnit(unit)
	local _, CHANNEL, EMPOWER = OverlayKinds()
	if ChannelingNow(unit) then
		return CHANNEL
	end
	local kind = GetActive(unit) and GetActive(unit).kind
	if kind == CHANNEL or kind == EMPOWER then
		return kind
	end
	return nil
end

local function WidgetFillKind(widget)
	if not widget then
		return nil
	end
	return widget.actionButtonCastType or widget._fluxClassicKind
end

local function PartitionByKind(list, kind)
	local matched, rest = {}, {}
	for i = 1, #(list or {}) do
		local w = list[i]
		if w then
			if WidgetFillKind(w) == kind then
				matched[#matched + 1] = w
			else
				rest[#rest + 1] = w
			end
		end
	end
	return matched, rest
end

local function FaceSpell(widget)
	return SpellOf(EntryOf(widget))
end

local function KnownOtherSpell(widget, inflight)
	if not widget or not inflight then
		return false
	end
	local sid = FaceSpell(widget)
	if not sid then
		return false
	end
	local ok, match = pcall(ButtonFX.SpellIdsMatch, sid, inflight)
	return not (ok and match)
end

local function HasCastPaint(ov, widget)
	if not widget then
		return false
	end
	if ov.IsLiveBurst and ov.IsLiveBurst(widget) then
		return true
	end
	if ov.IsLiveCast and ov.IsLiveCast(widget) then
		return true
	end
	if ov.IsLiveInterrupt and ov.IsLiveInterrupt(widget) then
		return true
	end
	if ov.IsLiveReticle and ov.IsLiveReticle(widget) then
		return true
	end
	return widget.vfxCastData ~= nil or widget._fluxVfxMode ~= nil or widget._fluxHadReticle
end

local function ArmLatch(widget, spellId)
	if not widget then
		return
	end
	widget._fluxCastLockSpellId = spellId
	widget._fluxCastMigrateUntil = Now() + LATCH
end

local function CaptureUnitCast(unit)
	unit = NormUnit(unit)
	local CAST, CHANNEL = OverlayKinds()
	if type(UnitChannelInfo) == "function" then
		local ok, name, _, _, _, _, _, _, spellId = pcall(UnitChannelInfo, unit)
		if ok and name then
			return name, SafeNum(spellId), CHANNEL
		end
	end
	if type(UnitCastingInfo) == "function" then
		local ok, name, _, _, _, _, _, _, _, spellId = pcall(UnitCastingInfo, unit)
		if ok and name then
			return name, SafeNum(spellId), CAST
		end
	end
	return nil, nil, nil
end

local function SpellIsTargetingNow()
	if type(SpellIsTargeting) ~= "function" then
		return false
	end
	local ok, targeting = pcall(SpellIsTargeting)
	return ok and targeting and true or false
end

-- Unit APIs first (live progress). Interrupt/finish bags cover the kick/burst
-- window. Ground targeting has no UnitCastingInfo — SpellIsTargeting plus the
-- reticle spell id is the inflight identity (paging + macro flips).
-- Do not treat Cast._active as still-casting after unit APIs go idle — that
-- left a full bar stuck after SUCCEEDED with no owners.
local function ResolveInflight(ov, source)
	local CAST = OverlayKinds()
	local name, unitId, unitKind = CaptureUnitCast()
	if name then
		local sid = unitId
			or (Cast._active and Cast._active.spellID)
			or (Cast._reticle and Cast._reticle.spellID)
			or lastSpell
		if sid then
			return sid, unitKind or (Cast._active and Cast._active.kind) or CAST, "cast"
		end
	end
	-- CHANNEL_START can beat UnitChannelInfo by a frame, and SpellIsTargeting
	-- can still be true after placing a ground channel (Blizzard, Hurricane).
	-- Do not settle that as reticle or FollowColumn will PlayReticle and kill the fill.
	local activeKind = Cast._active and Cast._active.kind
	local _, CHANNEL, EMPOWER = OverlayKinds()
	if activeKind == CHANNEL or activeKind == EMPOWER then
		local sid = Cast._active.spellID
			or (Cast._reticle and Cast._reticle.spellID)
			or lastSpell
		if sid then
			return sid, activeKind, "cast"
		end
	end
	if SpellIsTargetingNow() then
		local sid = (Cast._reticle and Cast._reticle.spellID) or lastSpell
		if source then
			sid = source._fluxCastSpell or sid
		end
		if not sid and activeReticle then
			sid = activeReticle._fluxCastSpell
		end
		if sid then
			return sid, nil, "reticle"
		end
	end
	local t = Now()
	if Cast._interrupt and Cast._interrupt.expires and t < Cast._interrupt.expires then
		local sid = Cast._interrupt.spellID
			or (source and (source._fluxInterruptSpell or source._fluxCastSpell))
			or lastSpell
		return sid, nil, "interrupt"
	end
	if Cast._finish and Cast._finish.spellID and Cast._finish.expires and t < Cast._finish.expires then
		return Cast._finish.spellID, nil, "finish"
	end
	if source and HasCastPaint(ov, source) then
		if ov.IsLiveBurst and ov.IsLiveBurst(source) then
			local sid = source._fluxCastSpell or source._fluxCastLockSpellId or lastSpell
			if sid then
				return sid, nil, "finish"
			end
		end
		if ov.IsLiveInterrupt and ov.IsLiveInterrupt(source) then
			local sid = source._fluxInterruptSpell or source._fluxCastSpell or lastSpell
			if sid then
				return sid, nil, "interrupt"
			end
		end
	end
	return nil, nil, nil
end

local function RewriteFollow(source, dest)
	if not dest then
		return
	end
	if source and source ~= dest then
		activeCasts = RewriteOwners(activeCasts, source, dest)
		if activeReticle == source then
			activeReticle = dest
		end
		if lastOwner == source then
			lastOwner = dest
		end
		if Cast._reticleOwners then
			Cast._reticleOwners = RewriteOwners(Cast._reticleOwners, source, dest)
		end
		return
	end
	local found = false
	for i = 1, #activeCasts do
		if activeCasts[i] == dest then
			found = true
			break
		end
	end
	if not found then
		activeCasts[#activeCasts + 1] = dest
	end
	lastOwner = dest
end

local function ClearOthers(ov, widgets, dest, inflight)
	for i = 1, #widgets do
		local w = widgets[i]
		if w and w ~= dest then
			if KnownOtherSpell(w, inflight) or HasCastPaint(ov, w) then
				if ov.ForceClear then
					ov.ForceClear(w)
				end
				if ov.ClearReticle then
					ov.ClearReticle(w)
				end
				w._fluxCastLockSpellId = nil
				w._fluxCastMigrateUntil = nil
			end
		end
	end
end

local retryCols = {}
local retryArmed = false

local function NeedFollowRetry()
	if CaptureUnitCast() then
		return true
	end
	if SpellIsTargetingNow() then
		return true
	end
	local t = Now()
	if Cast._interrupt and Cast._interrupt.expires and t < Cast._interrupt.expires then
		return true
	end
	if Cast._finish and Cast._finish.expires and t < Cast._finish.expires then
		return true
	end
	return false
end

-- Only columns whose slot identity was still lagging. 0 + 0.05s + 0.15s, not
-- a 19-column sweep and not a permanent OnUpdate.
local function ScheduleFollowRetry(column)
	if column then
		retryCols[column] = true
	end
	if retryArmed or not NeedFollowRetry() then
		return
	end
	retryArmed = true
	local function pass()
		if not NeedFollowRetry() then
			retryArmed = false
			for k in pairs(retryCols) do
				retryCols[k] = nil
			end
			return
		end
		local cols = {}
		for c in pairs(retryCols) do
			cols[#cols + 1] = c
			retryCols[c] = nil
		end
		for i = 1, #cols do
			Cast.FollowColumn(cols[i])
		end
	end
	local function last()
		retryArmed = false
		pass()
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, pass)
		C_Timer.After(0.05, pass)
		C_Timer.After(0.15, last)
	else
		retryArmed = false
	end
end

local function PaintPhase(ov, dest, inflight, kind, phase)
	if not dest then
		return
	end
	dest._fluxCastSpell = inflight
	ArmLatch(dest, inflight)
	if phase == "interrupt" then
		dest._fluxInterruptSpell = inflight
		if dest._fluxInterruptFace == nil then
			dest._fluxInterruptFace = FaceSpell(dest)
		end
		if ov.SyncInterrupt and not (ov.IsLiveInterrupt and ov.IsLiveInterrupt(dest)) then
			ov.SyncInterrupt(dest)
		end
		return
	end
	if phase == "finish" then
		if ov.HideCastFill then
			ov.HideCastFill(dest)
		end
		if ov.SyncBurst and not (ov.IsLiveBurst and ov.IsLiveBurst(dest)) then
			ov.SyncBurst(dest)
		end
		return
	end
	if phase == "reticle" then
		if ov.IsLiveCast and ov.IsLiveCast(dest) and not (ov.IsLiveBurst and ov.IsLiveBurst(dest)) then
			return
		end
		if ov.PlayReticle and not (ov.IsLiveReticle and ov.IsLiveReticle(dest)) then
			ov.PlayReticle(dest)
		end
		return
	end
	if ov.IsLiveBurst and ov.IsLiveBurst(dest) then
		return
	end
	-- Appear only. Transfer already moved live fill; always tick dest so a
	-- reparented swipe is not left frozen/hidden.
	if ov.IsLiveCast and ov.IsLiveCast(dest) then
		if ov.TickFill then
			ov.TickFill(dest)
		end
		return
	end
	if ov.SyncCast then
		ov.SyncCast(dest, kind)
	end
end

local function MovePaint(ov, source, dest)
	if source and dest and source ~= dest then
		local ok = false
		if ov.Transfer then
			ok = ov.Transfer(source, dest)
		end
		if not ok and ov.TransferCast then
			ok = ov.TransferCast(source, dest)
		end
		if ov.FollowChrome then
			ov.FollowChrome(source, dest)
		end
		if ok then
			RewriteFollow(source, dest)
			if ov.TickFill and ov.IsLiveCast and ov.IsLiveCast(dest)
				and not (ov.IsLiveBurst and ov.IsLiveBurst(dest)) then
				ov.TickFill(dest)
			end
		else
			RewriteFollow(nil, dest)
		end
		return
	end
	RewriteFollow(source, dest)
end

local function ClearColumnPaint(ov, widgets, except)
	for i = 1, #widgets do
		local w = widgets[i]
		if w and w ~= except and HasCastPaint(ov, w) then
			if ov.ForceClear then
				ov.ForceClear(w)
			end
			if ov.ClearReticle then
				ov.ClearReticle(w)
			end
		end
		if w and w ~= except then
			w._fluxCastLockSpellId = nil
			w._fluxCastMigrateUntil = nil
		end
	end
end

--- Exclusive settle: VFX lives only on the face whose current slot spell/item
--- matches the in-flight id. Paging and macro flips transfer, appear at live
--- progress, or ForceClear — and can appear again when the id comes back.
function Cast.FollowColumn(column)
	column = tonumber(column)
	if not column then
		return
	end
	local ov = FXOverlay()
	if not ov then
		return
	end
	local widgets = ColumnWidgets(column)
	if #widgets == 0 then
		return
	end
	local source = LiveSource(ov, widgets, column)
	local inflight, kind, phase = ResolveInflight(ov, source)
	if not inflight then
		if phase == "interrupt" and source and ov.IsLiveInterrupt and ov.IsLiveInterrupt(source) then
			ClearColumnPaint(ov, widgets, source)
			return
		end
		ClearColumnPaint(ov, widgets, nil)
		return
	end
	local dest = BestFace(ov, widgets, inflight)
	if dest then
		MovePaint(ov, source, dest)
		PaintPhase(ov, dest, inflight, kind, phase)
		ClearOthers(ov, widgets, dest, inflight)
		return
	end
	local lag = ColumnIdentityLag(widgets)
	if phase == "finish" or phase == "interrupt" then
		-- Interrupt must survive strip FollowColumn. Extra Buttons never run
		-- this settle. Keep a live kick on source even when FaceSpell is nil
		-- or the interrupt event had no parseable id. ForceClear only a
		-- known other spell (page/macro leave), not dest-nil lag.
		local keep = false
		if phase == "interrupt" then
			if source and ov.IsLiveInterrupt and ov.IsLiveInterrupt(source) then
				local face = FaceSpell(source)
				local stamped = source._fluxInterruptFace
				if stamped and face then
					local ok, match = pcall(ButtonFX.SpellIdsMatch, face, stamped)
					keep = not (ok and not match)
				elseif not KnownOtherSpell(source, inflight) then
					keep = true
				end
			elseif source and not KnownOtherSpell(source, inflight) then
				keep = true
			end
		elseif source and FaceSpell(source) and not KnownOtherSpell(source, inflight) then
			keep = true
		end
		if keep then
			if phase == "finish" then
				if ov.HideCastFill then
					ov.HideCastFill(source)
				end
				if ov.SyncBurst then
					ov.SyncBurst(source)
				elseif ov.PlayBurst and not (ov.IsLiveBurst and ov.IsLiveBurst(source)) then
					ov.PlayBurst(source)
				end
			elseif ov.SyncInterrupt then
				if not (ov.IsLiveInterrupt and ov.IsLiveInterrupt(source)) then
					ov.SyncInterrupt(source)
				end
			end
			ClearColumnPaint(ov, widgets, source)
		else
			ClearColumnPaint(ov, widgets, nil)
		end
		if lag then
			ScheduleFollowRetry(column)
		end
		return
	end
	-- Nobody currently shows this id. Keep paint only while slot identity is
	-- still nil (GetMacroSpell / action lag). A known other spell is a real
	-- leave — clear so a later flip can appear again on the matching face.
	if source and not KnownOtherSpell(source, inflight) and lag then
		ScheduleFollowRetry(column)
		return
	end
	ClearColumnPaint(ov, widgets, nil)
	if lag then
		ScheduleFollowRetry(column)
	end
end

local function StopList(ov, list, interrupted)
	for i = 1, #(list or {}) do
		local w = list[i]
		if w then
			ov.StopCast(w, interrupted and true or false)
		end
	end
end

local function FollowWidgets(list)
	local seen = {}
	for i = 1, #(list or {}) do
		local w = list[i]
		if w and w._fluxVfxUnit ~= UNIT_PET then
			local host = w._fluxHost
			local col = host and host.column
			if col and not seen[col] then
				seen[col] = true
				Cast.FollowColumn(col)
			end
		end
	end
end

-- UnitChannelInfo start/end are milliseconds. Backup CHANNEL_STOP used
-- GetTime() < (activeCast.endTime / 1000) - 0.25 from this bag, not widget
-- vfxCastData (often missing on the strip).
local function StampActiveChannelTimes(unit)
	unit = NormUnit(unit)
	local ac = GetActive(unit)
	if not ac then
		return
	end
	local _, CHANNEL, EMPOWER = OverlayKinds()
	if ac.kind ~= CHANNEL and ac.kind ~= EMPOWER then
		return
	end
	if type(UnitChannelInfo) ~= "function" then
		return
	end
	local ok, name, _, _, startTime, endTime = pcall(UnitChannelInfo, unit)
	if not ok or name == nil or name == false or name == "" then
		return
	end
	startTime = SafeNum(startTime) or tonumber(startTime)
	endTime = SafeNum(endTime) or tonumber(endTime)
	if startTime and startTime > 0 then
		ac.startTime = startTime
	end
	if endTime and endTime > 0 then
		ac.endTime = endTime
	end
end

function Cast.NoteChannelTimes(startTime, endTime, unit)
	local ac = GetActive(unit)
	if not ac then
		return
	end
	startTime = tonumber(startTime)
	endTime = tonumber(endTime)
	if startTime and startTime > 0 then
		ac.startTime = startTime
	end
	if endTime and endTime > 0 then
		ac.endTime = endTime
	end
end

local function OnStart(spellId, kind, spellName, unit)
	unit = NormUnit(unit)
	if not IsPetUnit(unit) then
		Cast._blockCurrentSpell = nil
		if StopReticleWatch then
			StopReticleWatch()
		end
	end
	local reticle = GetReticle(unit)
	SetActive(unit, {
		spellID = spellId or (reticle and reticle.spellID) or LastSpellOf(unit),
		kind = kind,
		name = spellName,
	})
	StampActiveChannelTimes(unit)
	SetInterrupt(unit, nil)
	SetFinish(unit, nil)
	local ov = FXOverlay()
	if not ov then
		return
	end
	BumpGen(unit)
	local owners = PickStartOwners(spellId, spellName, unit)
	if not IsPetUnit(unit) then
		lastOwner = owners[1]
	end
	local keep = WidgetSet(owners)
	local prev = CastList(unit)
	for i = 1, #prev do
		local w = prev[i]
		if w and not keep[w] then
			ov.StopCast(w, true)
		end
	end
	SetCastList(unit, owners)
	StampInflight(owners, GetActive(unit).spellID)
	for i = 1, #owners do
		owners[i]._fluxVfxUnit = unit
		owners[i]._fluxInterruptSpell = nil
		ov.PlayCast(owners[i], kind)
	end
	if not IsPetUnit(unit) then
		FollowWidgets(owners)
	end
end

local function ChannelFillLive(unit)
	local _, CHANNEL = OverlayKinds()
	local casts = CastList(unit)
	for i = 1, #casts do
		if WidgetFillKind(casts[i]) == CHANNEL then
			return true
		end
	end
	return false
end

local function AppendUnique(list, seen, widget)
	if widget and not seen[widget] then
		seen[widget] = true
		list[#list + 1] = widget
	end
end

-- Backup painted every matching strip column (AreSpellsEquivalent), not only
-- the fill owner bag. Strip SpellIdFromAction often differs from the combat id.
local function CollectInterruptOwners(spellId, spellName, unit)
	unit = NormUnit(unit)
	local ov = FXOverlay()
	local seen, list = {}, {}
	local casts = CastList(unit)
	for i = 1, #casts do
		AppendUnique(list, seen, casts[i])
	end
	local start = PickStartOwners(spellId, spellName, unit)
	for i = 1, #start do
		AppendUnique(list, seen, start[i])
	end
	local picked = PickSmart(spellId, spellName, unit)
	for i = 1, #picked do
		AppendUnique(list, seen, picked[i])
	end
	if IsPetUnit(unit) then
		return list
	end
	local Bars = Flux.Bars
	local n = (Bars and Bars.NUM_COLUMNS) or 19
	local sid = SafeNum(spellId) or spellId
	for col = 1, n do
		local widgets = ColumnWidgets(col)
		local dest = BestFace(ov, widgets, sid)
		AppendUnique(list, seen, dest)
		if not dest then
			AppendUnique(list, seen, LiveSource(ov, widgets, col))
		end
	end
	return list
end

-- CHANNEL_START is missing on some pre-DF ground channels; SUCCEEDED + UnitChannelInfo still starts fill.
local function MaybeAdoptChannel(unit)
	unit = NormUnit(unit)
	if not ChannelingNow(unit) then
		return
	end
	if ChannelFillLive(unit) then
		return
	end
	local name, spellId, kind = CaptureUnitCast(unit)
	local _, CHANNEL = OverlayKinds()
	local reticle = GetReticle(unit)
	OnStart(spellId or (reticle and reticle.spellID) or LastSpellOf(unit), kind or CHANNEL, name, unit)
end

local function InterruptWindowLive(unit)
	local i = GetInterrupt(unit)
	return i and i.expires and Now() < i.expires
end

local function FinishKind(spellId, kind, unit)
	unit = NormUnit(unit)
	local ov = FXOverlay()
	if not ov then
		SetActive(unit, nil)
		SetCastList(unit, {})
		return
	end
	if InterruptWindowLive(unit) then
		return
	end
	local matched, rest = PartitionByKind(CastList(unit), kind)
	-- Instant: SUCCEEDED with no START/fill. Do not play the finish burst.
	if #matched == 0 then
		if #rest == 0 then
			SetActive(unit, nil)
		end
		return
	end
	SetActive(unit, nil)
	BumpGen(unit)
	local burst = (ov.BURST_DURATION or 0.45)
	SetFinish(unit, {
		spellID = spellId or LastSpellOf(unit),
		expires = Now() + burst,
	})
	StopList(ov, matched, false)
	if not IsPetUnit(unit) then
		FollowWidgets(matched)
	end
	SetCastList(unit, rest)
end

-- SUCCEEDED stops CAST fills only (LAB StopSpellCastAnim Cast). A live
-- channel/empower must keep Cast._active and activeCasts.
local function OnSucceeded(spellId, spellName, unit)
	unit = NormUnit(unit)
	if LiveFillKind(unit) then
		MaybeAdoptChannel(unit)
		return
	end
	local CAST = OverlayKinds()
	FinishKind(spellId, CAST, unit)
end

local function ChannelStoppedEarly(unit)
	unit = NormUnit(unit)
	local now = Now()
	local ac = GetActive(unit)
	-- Cast._active.endTime is milliseconds (UnitChannelInfo).
	if ac and ac.endTime and ac.endTime > 0 then
		return now < (ac.endTime / 1000 - 0.25)
	end
	local _, CHANNEL = OverlayKinds()
	local casts = CastList(unit)
	for i = 1, #casts do
		local w = casts[i]
		if WidgetFillKind(w) == CHANNEL then
			local d = w.vfxCastData
			if d and d.start and d.duration and d.duration > 0.05 then
				return now < (d.start + d.duration - 0.25)
			end
			-- Live channel fill with no usable duration (secrets / freeze):
			-- CHANNEL_STOP is a kick, not a finish burst.
			return true
		end
	end
	if ChannelFillLive(unit) then
		return true
	end
	return false
end

local function OnCancel(spellId, spellName, unit)
	unit = NormUnit(unit)
	if InterruptWindowLive(unit) then
		return
	end
	local ov = FXOverlay()
	if not ov then
		return
	end
	BumpGen(unit)
	SetActive(unit, nil)
	SetFinish(unit, nil)
	local owners = CastList(unit)
	if #owners == 0 then
		owners = PickSmart(spellId, spellName, unit)
	end
	StopList(ov, owners, true)
	ClearInflight(owners)
	SetCastList(unit, {})
end

local function OnInterrupt(spellId, spellName, unit)
	unit = NormUnit(unit)
	local ov = FXOverlay()
	if not ov then
		return
	end
	BumpGen(unit)
	local hold = (ov.INTERRUPT_HOLD or 0.35) + (ov.INTERRUPT_FADE or 0.25)
	local active = GetActive(unit)
	local sid = spellId or (active and active.spellID) or LastSpellOf(unit)
	SetInterrupt(unit, {
		spellID = sid,
		expires = Now() + hold,
	})
	SetActive(unit, nil)
	SetFinish(unit, nil)
	local owners = CollectInterruptOwners(spellId, spellName, unit)
	for i = 1, #owners do
		local w = owners[i]
		if w then
			w._fluxVfxUnit = unit
			w._fluxInterruptSpell = sid or w._fluxCastSpell
			w._fluxInterruptFace = FaceSpell(w)
		end
		ov.PlayInterrupt(owners[i])
	end
	-- Keep _fluxCastSpell so FollowColumn can still match the visible face.
	-- Do not FollowWidgets immediately: that settle is what Extra Buttons
	-- never run, and dest-nil lag used to ForceClear the kick.
	SetCastList(unit, {})
end

local function OnChannelStop(spellId, spellName, unit)
	unit = NormUnit(unit)
	-- Kick/lock already owns the face. CHANNEL_STOP must not play EndBurst.
	if InterruptWindowLive(unit) then
		return
	end
	if ChannelStoppedEarly(unit) then
		OnInterrupt(spellId, spellName, unit)
		return
	end
	local _, CHANNEL = OverlayKinds()
	FinishKind(spellId, CHANNEL, unit)
end

local function OnEmpowerStop(spellId, spellName, complete, unit)
	unit = NormUnit(unit)
	if InterruptWindowLive(unit) then
		return
	end
	if complete == false then
		OnInterrupt(spellId, spellName, unit)
		return
	end
	local _, _, EMPOWER = OverlayKinds()
	FinishKind(spellId, EMPOWER, unit)
end

local function OnReticle(spellId, spellName, unit)
	unit = NormUnit(unit)
	if LiveFillKind(unit) then
		return
	end
	if not IsPetUnit(unit) then
		Cast._blockCurrentSpell = nil
	end
	local ov = FXOverlay()
	if not ov then
		return
	end
	spellId = spellId or LastSpellOf(unit)
	if IsPetUnit(unit) then
		petBag.lastSpell = spellId or petBag.lastSpell
	else
		lastSpell = spellId or lastSpell
	end
	SetReticle(unit, { spellID = spellId })
	local owners = PickReticleOwners(spellId, spellName, unit)
	if not IsPetUnit(unit) and #owners == 0 then
		owners = PickPressed()
	end
	if #owners == 0 and GetActiveReticle(unit) then
		owners = { GetActiveReticle(unit) }
	end
	if #owners == 0 then
		return
	end
	ClaimReticle(ov, owners, spellId, unit)
	StampInflight(owners, spellId)
	for i = 1, #owners do
		owners[i]._fluxVfxUnit = unit
		if ov.PlayReticle and not (ov.IsLiveReticle and ov.IsLiveReticle(owners[i])) then
			ov.PlayReticle(owners[i])
		end
	end
	if not IsPetUnit(unit) then
		FollowWidgets(owners)
	end
end

local function OnReticleClear(unit)
	unit = NormUnit(unit)
	local ov = FXOverlay()
	local unitLast = LastSpellOf(unit)
	local unitReticle = GetActiveReticle(unit)
	if not unitLast and unitReticle then
		for i = 1, #entries do
			if entries[i].widget == unitReticle and EntryUnit(entries[i]) == unit then
				unitLast = SpellOf(entries[i])
				if IsPetUnit(unit) then
					petBag.lastSpell = unitLast
				else
					lastSpell = unitLast
				end
				break
			end
		end
	end
	if not IsPetUnit(unit) and lastSpell then
		Cast._blockCurrentSpell = lastSpell
	end
	if ov then
		local seen = {}
		local function clear(widget)
			if widget and not seen[widget] then
				seen[widget] = true
				if ov.ResetTargetChrome then
					ov.ResetTargetChrome(widget)
				else
					ov.ClearReticle(widget)
				end
			end
		end
		local owners = GetReticleOwners(unit)
		if owners then
			for i = 1, #owners do
				clear(owners[i])
			end
		end
		clear(unitReticle)
		for i = 1, #entries do
			if EntryUnit(entries[i]) == unit then
				clear(entries[i].widget)
			end
		end
	end
	do
		local keep = WidgetSet(CastList(unit))
		local function drop(widget)
			if widget and not keep[widget] then
				widget._fluxCastSpell = nil
			end
		end
		local owners = GetReticleOwners(unit)
		if owners then
			for i = 1, #owners do
				drop(owners[i])
			end
		end
		drop(unitReticle)
	end
	SetActiveReticle(unit, nil)
	SetReticleOwners(unit, nil)
	SetReticle(unit, nil)
	if not IsPetUnit(unit) then
		DirtyChecked()
	end
end

function StopReticleWatch()
	reticleWatching = false
	if Flux.Ticker and Flux.Ticker.Remove then
		Flux.Ticker.Remove("buttonfx.reticle")
	end
end

local function KeepUnitReticle(unit)
	unit = NormUnit(unit)
	local ov = FXOverlay()
	local sid = (GetReticle(unit) and GetReticle(unit).spellID) or LastSpellOf(unit)
	local keep = PickReticleOwners(sid, nil, unit)
	if #keep == 0 then
		keep = GetReticleOwners(unit)
	end
	if (not keep or #keep == 0) and GetActiveReticle(unit) then
		keep = { GetActiveReticle(unit) }
	end
	if not ov or not keep or #keep == 0 then
		return
	end
	ClaimReticle(ov, keep, sid, unit)
	for i = 1, #keep do
		if ov.PlayReticle and not (ov.IsLiveReticle and ov.IsLiveReticle(keep[i])) then
			ov.PlayReticle(keep[i])
		end
	end
end

local function OnReticleTick()
	if SpellIsTargetingNow() then
		if GetActiveReticle(UNIT_PLAYER) or Cast._reticle then
			if not GetActiveReticle(UNIT_PLAYER) then
				OnReticle(lastSpell)
			else
				KeepUnitReticle(UNIT_PLAYER)
			end
		end
		-- Pet ground-target (Voidwalker AoE, mage Water Elemental Freeze, …)
		-- uses the same SpellIsTargeting window as the player bar.
		if GetActiveReticle(UNIT_PET) or Cast._petReticle then
			KeepUnitReticle(UNIT_PET)
		end
		return
	end
	OnReticleClear(UNIT_PLAYER)
	-- Escape / right-click cancel must drop pet-bar AOE reticle VFX too.
	OnReticleClear(UNIT_PET)
	StopReticleWatch()
	MaybeAdoptChannel()
end

local function StartReticleWatch()
	if reticleWatching then
		return
	end
	reticleWatching = true
	if Flux.Ticker and Flux.Ticker.Add then
		Flux.Ticker.Add("buttonfx.reticle", OnReticleTick)
	elseif Cast._frame then
		Cast._frame:SetScript("OnUpdate", function(self, elapsed)
			self._fluxReticleAccum = (self._fluxReticleAccum or 0) + (elapsed or 0)
			if self._fluxReticleAccum < 0.05 then
				return
			end
			self._fluxReticleAccum = 0
			if not reticleWatching then
				self:SetScript("OnUpdate", nil)
				return
			end
			OnReticleTick()
		end)
	end
end

local function ClearPetUnitVfx()
	local ov = FXOverlay()
	if ov and ov.ForceClear then
		for i = 1, #entries do
			local e = entries[i]
			if EntryUnit(e) == UNIT_PET and e.widget then
				ov.ForceClear(e.widget)
			end
		end
	end
	petBag.activeCasts = {}
	petBag.castGen = petBag.castGen + 1
	petBag.activeReticle = nil
	Cast._petActive = nil
	Cast._petInterrupt = nil
	Cast._petFinish = nil
	Cast._petReticle = nil
	Cast._petReticleOwners = nil
end

local function EnsureDispatcher()
	if started then
		return started
	end
	local ov = FXOverlay()
	local CAST = (ov and ov.CAST) or 1
	local CHANNEL = (ov and ov.CHANNEL) or 2
	local EMPOWER = (ov and ov.EMPOWER) or 3

	local f = CreateFrame("Frame")
	f:SetScript("OnEvent", function(_, event, unit, ...)
		if event == "UNIT_PET" then
			ClearPetUnitVfx()
			return
		end
		if unit and unit ~= "player" and unit ~= "pet" then
			return
		end
		lastEvent = event
		local spellId, spellName = SpellFromPayload(...)
		local empowerComplete = PayloadBoolean(...)
		if unit == "pet" then
			petBag.lastSpell = spellId or spellName or petBag.lastSpell
		else
			lastSpell = spellId or spellName
		end
		local ok, err = pcall(function()
			if event == "UNIT_SPELLCAST_START" then
				if unit == "pet" then
					OnStart(spellId, CAST, spellName, unit)
				elseif SpellIsTargetingNow() then
					OnReticle(spellId, spellName)
					StartReticleWatch()
				else
					OnStart(spellId, CAST, spellName)
				end
			elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
				if unit == "pet" then
					OnStart(spellId, EMPOWER, spellName, unit)
				elseif SpellIsTargetingNow() then
					OnReticle(spellId, spellName)
					StartReticleWatch()
				else
					OnStart(spellId, EMPOWER, spellName)
				end
			elseif event == "UNIT_SPELLCAST_STOP" then
				-- STOP is cancel only if still active. SUCCEEDED usually wins this race.
				-- Do not treat STOP as interrupt (no PlayInterrupt).
				-- Do not kill a live channel: SUCCEEDED is not the channel end.
				local stopUnit = unit
				local gen = GenOf(stopUnit)
				local pending = CastList(stopUnit)
				if pending and #pending > 0 and C_Timer and C_Timer.After then
					C_Timer.After(0.05, function()
						if gen ~= GenOf(stopUnit) then
							return
						end
						if LiveFillKind(stopUnit) then
							return
						end
						local castsNow = CastList(stopUnit)
						if pending == castsNow or (#castsNow > 0) then
							OnCancel(spellId, spellName, stopUnit)
						end
					end)
				elseif pending and #pending > 0 then
					if not LiveFillKind(stopUnit) then
						OnCancel(spellId, spellName, stopUnit)
					end
				end
			elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
				OnEmpowerStop(spellId, spellName, empowerComplete ~= false, unit)
			elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
				OnSucceeded(spellId, spellName, unit)
			elseif event == "UNIT_SPELLCAST_FAILED" then
				OnCancel(spellId, spellName, unit)
				OnReticleClear(unit)
			elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
				OnInterrupt(spellId, spellName, unit)
				OnReticleClear(unit)
			elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
				-- CHANNEL_START always starts fill. Reticle stays on targeting events.
				OnStart(spellId, CHANNEL, spellName, unit)
			elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
				OnChannelStop(spellId, spellName, unit)
			elseif event == "UNIT_SPELLCAST_RETICLE_TARGET" then
				OnReticle(spellId, spellName, unit)
				StartReticleWatch()
			elseif event == "UNIT_SPELLCAST_RETICLE_CLEAR" then
				if unit == "pet" then
					OnReticleClear(unit)
				elseif not SpellIsTargetingNow() then
					OnReticleClear()
					StopReticleWatch()
					MaybeAdoptChannel()
				end
			elseif event == "CURRENT_SPELL_CAST_CHANGED" then
				if unit ~= "pet" and SpellIsTargetingNow() then
					OnReticle(spellId or lastSpell, spellName)
					StartReticleWatch()
				end
				-- Not targeting: GCD / current-spell edges. Reticle teardown is
				-- UNIT_SPELLCAST_RETICLE_CLEAR and the targeting ticker.
			end
		end)
		if not ok and geterrorhandler then
			geterrorhandler()(tostring(err))
		end
	end)

	local function Arm(eventName)
		-- RegisterUnitEvent player+pet. Filter other units in OnEvent.
		if f.RegisterUnitEvent then
			local ok = pcall(f.RegisterUnitEvent, f, eventName, "player", "pet")
			if ok then
				return true
			end
			ok = pcall(f.RegisterUnitEvent, f, eventName, "player")
			if ok then
				return true
			end
		end
		return pcall(f.RegisterEvent, f, eventName)
	end

	local armed = false
	armed = Arm("UNIT_SPELLCAST_START") or armed
	armed = Arm("UNIT_SPELLCAST_STOP") or armed
	armed = Arm("UNIT_SPELLCAST_SUCCEEDED") or armed
	armed = Arm("UNIT_SPELLCAST_FAILED") or armed
	armed = Arm("UNIT_SPELLCAST_INTERRUPTED") or armed
	armed = Arm("UNIT_SPELLCAST_CHANNEL_START") or armed
	armed = Arm("UNIT_SPELLCAST_CHANNEL_STOP") or armed
	Arm("UNIT_SPELLCAST_EMPOWER_START")
	Arm("UNIT_SPELLCAST_EMPOWER_STOP")
	Arm("UNIT_SPELLCAST_RETICLE_TARGET")
	Arm("UNIT_SPELLCAST_RETICLE_CLEAR")
	Arm("CURRENT_SPELL_CAST_CHANGED")
	if f.RegisterUnitEvent then
		pcall(f.RegisterUnitEvent, f, "UNIT_PET", "player")
	else
		pcall(f.RegisterEvent, f, "UNIT_PET")
	end

	started = armed and true or false
	Cast._frame = f
	Cast._armed = armed
	return started
end

function Cast.Start()
	return EnsureDispatcher()
end

function Cast.RefreshFromOptions()
	if Cast.IsSpellCastVFXEnabled() then
		return
	end
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	if not (ov and ov.ForceClear) then
		return
	end
	for i = 1, #entries do
		local rec = entries[i]
		if rec and rec.widget then
			ov.ForceClear(rec.widget)
		end
	end
end

function Cast.SpellBlockedAsCurrent(spellId)
	if not Cast._blockCurrentSpell or not spellId then
		return false
	end
	return ButtonFX.SpellIdsMatch(spellId, Cast._blockCurrentSpell)
end

function Cast.NoteTargeting(widget)
	EnsureDispatcher()
	if widget and widget._fluxVfxUnit == UNIT_PET then
		local sid = SpellOf(EntryOf(widget))
		if sid then
			petBag.lastSpell = sid
			widget._fluxCastSpell = sid
		end
		OnReticle(sid, nil, UNIT_PET)
		StartReticleWatch()
		return
	end
	StartReticleWatch()
	if not widget then
		return
	end
	local ov = FXOverlay()
	local sid = SpellOf(EntryOf(widget))
	if sid then
		lastSpell = sid
		widget._fluxCastSpell = sid
		Cast._reticle = { spellID = sid }
	end
	-- Same spell/item/macro may keep the reticle on every matching face.
	-- A different identity clears the previous set via ClaimReticle.
	local owners = PickReticleOwners(sid)
	local found = false
	for i = 1, #owners do
		if owners[i] == widget then
			found = true
			break
		end
	end
	if not found then
		table.insert(owners, 1, widget)
	end
	ClaimReticle(ov, owners, sid)
	if ov and ov.PlayReticle then
		for i = 1, #owners do
			if not (ov.IsLiveReticle and ov.IsLiveReticle(owners[i])) then
				ov.PlayReticle(owners[i])
			end
		end
	end
	FollowWidgets(owners)
end

function Cast.Debug()
	return {
		started = started and true or false,
		armed = Cast._armed and true or false,
		entries = #entries,
		lastEvent = lastEvent,
		lastSpell = lastSpell,
		hasOwner = #activeCasts > 0,
		owners = #activeCasts,
		mode = lastOwner and lastOwner._fluxVfxMode,
		hasCastFrame = lastOwner and lastOwner.SpellCastAnimFrame and true or false,
		active = Cast._active and Cast._active.spellID,
		interrupt = Cast._interrupt and Cast._interrupt.spellID,
		finish = Cast._finish and Cast._finish.spellID,
	}
end

function Cast.Register(widget, getSpellId, rank, unit)
	if not widget or widget._fluxCastRegistered then
		return
	end
	widget._fluxCastRegistered = true
	unit = NormUnit(unit)
	widget._fluxVfxUnit = unit
	entries[#entries + 1] = {
		widget = widget,
		getSpellId = getSpellId,
		rank = rank or Cast.RANK_EBS,
		unit = unit,
	}
	EnsureDispatcher()
end

--- Flyout kid → Extra host: move live fill/reticle/interrupt and rewrite
--- the owner bag so hide does not kill the swipe.
function Cast.AdoptFace(from, to)
	if not from or not to or from == to then
		return
	end
	local ov = FXOverlay()
	if not ov then
		return
	end
	MovePaint(ov, from, to)
end
