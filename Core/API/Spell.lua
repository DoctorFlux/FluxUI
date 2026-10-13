-- Spell.lua — C_Spell vs GetSpellInfo / GetSpellCooldown
local addonName, ns = ...
local Flux = ns.Flux

local Spell = {}
Flux.Spell = Spell
Flux.API = Flux.API or {}
Flux.API.Spell = Spell

local type = type
local tonumber = tonumber

local _GetSpellInfoRaw
if C_Spell and C_Spell.GetSpellInfo then
	local cGet = C_Spell.GetSpellInfo
	_GetSpellInfoRaw = function(spellId)
		local info = cGet(spellId)
		if info then
			local rank
			local Client = Flux.Client
			if Client and not Client.isLiveMidnight
				and (Client.isCamelot or Client.isEra or Client.isAnniversary or Client.isTBC or Client.isWrath) then
				if C_Spell.GetSpellSubtext then
					local ok, sub = pcall(C_Spell.GetSpellSubtext, spellId)
					if ok and type(sub) == "string" and sub ~= "" then
						rank = sub
					end
				end
			end
			return info.name, rank, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
		end
		return nil
	end
elseif GetSpellInfo then
	_GetSpellInfoRaw = GetSpellInfo
else
	_GetSpellInfoRaw = function()
		return nil
	end
end

local cache = {}
local loadRequested = {}

-- Name(subtext) cast keys. Rebuilt on the same events as the info cache; the
-- checked lane asks for one per button per paint, and it is two API calls plus
-- a concat every time.
local castAttrCache = {}

local function ClearCache()
	cache = {}
	castAttrCache = {}
	loadRequested = {}
end

--- Forever C_Spell.GetSpellInfo is nil until the record is cached. A stored
--- miss would keep the badge icon blank after the data arrives.
local function NoteColdSpell(spellId)
	if loadRequested[spellId] then
		return
	end
	loadRequested[spellId] = true
	if C_Spell and C_Spell.RequestLoadSpellData then
		pcall(C_Spell.RequestLoadSpellData, spellId)
	end
end

local function SpellRecordCold(spellId)
	if not (C_Spell and C_Spell.IsSpellDataCached) then
		return false
	end
	local ok, cached = pcall(C_Spell.IsSpellDataCached, spellId)
	if not ok then
		return false
	end
	return not cached
end

function Spell.GetInfo(spellId)
	if type(spellId) == "number" then
		local hit = cache[spellId]
		if hit ~= nil then
			if hit == false then
				return nil
			end
			return hit[1], hit[2], hit[3], hit[4], hit[5], hit[6], hit[7], hit[8]
		end
		local n, r, ic, ct, mn, mx, sid, oic = _GetSpellInfoRaw(spellId)
		if n == nil then
			if SpellRecordCold(spellId) then
				NoteColdSpell(spellId)
				return nil
			end
			cache[spellId] = false
			return nil
		end
		cache[spellId] = { n, r, ic, ct, mn, mx, sid, oic }
		return n, r, ic, ct, mn, mx, sid, oic
	end
	return _GetSpellInfoRaw(spellId)
end

function Spell.GetName(spellId)
	local name = Spell.GetInfo(spellId)
	return name
end

function Spell.GetIcon(spellId)
	local _, _, icon = Spell.GetInfo(spellId)
	return icon
end

-- Uncached live face. ButtonForge paints GetSpellTexture(GetOverrideSpell(id)).
-- CooldownViewer uses GetSpellTexture(base) then conditionalIconID or iconID
-- (form/stealth/proc icon-only swaps). Query override first so extras do not
-- keep the assigned icon when GetSpellTexture(base) returns the original face.
-- Called from every icon paint and from the glow face check, so the helpers
-- live at file scope: three nested closures per call was pure garbage.
local function PickIcon(iconID, originalIconID, conditionalIconID)
	if type(iconID) == "table" then
		local info = iconID
		iconID = info.iconID
		originalIconID = info.originalIconID or originalIconID
		conditionalIconID = info.conditionalIconID or conditionalIconID
	end
	if conditionalIconID and conditionalIconID ~= 0 and conditionalIconID ~= "" then
		return conditionalIconID
	end
	if iconID and iconID ~= 0 and iconID ~= "" then
		return iconID
	end
	return nil
end

local function PullIcon(fn, ident)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, iconID, originalIconID, conditionalIconID = pcall(fn, ident)
	if not ok then
		return nil
	end
	return PickIcon(iconID, originalIconID, conditionalIconID)
end

local function TextureFor(ident)
	if ident == nil or ident == "" then
		return nil
	end
	if C_Spell and C_Spell.GetSpellTexture then
		local tex = PullIcon(C_Spell.GetSpellTexture, ident)
		if tex then
			return tex
		end
	end
	if GetSpellTexture then
		local tex = PullIcon(GetSpellTexture, ident)
		if tex then
			return tex
		end
	end
	return nil
end

-- Third GetSpellTexture return: on-state / form / stealth face. Nil when the
-- client has no conditional swap (Classic GetSpellTexture is icon + original).
function Spell.GetConditionalIcon(spellId)
	if not spellId then
		return nil
	end
	local function pull(ident)
		if ident == nil or ident == "" then
			return nil
		end
		local fn = C_Spell and C_Spell.GetSpellTexture
		if type(fn) ~= "function" then
			return nil
		end
		local ok, iconID, originalIconID, conditionalIconID = pcall(fn, ident)
		if not ok then
			return nil
		end
		if type(iconID) == "table" then
			conditionalIconID = iconID.conditionalIconID
		end
		if conditionalIconID and conditionalIconID ~= 0 and conditionalIconID ~= "" then
			return conditionalIconID
		end
		return nil
	end
	local override = Spell.GetOverrideSpell(spellId) or spellId
	local tex = pull(override)
	if tex then
		return tex
	end
	if spellId ~= override then
		tex = pull(spellId)
		if tex then
			return tex
		end
	end
	local base = Spell.GetBaseSpell(spellId) or spellId
	if base ~= override and base ~= spellId then
		return pull(base)
	end
	return nil
end

function Spell.GetTexture(spellId)
	if not spellId then
		return nil
	end
	local hit = TextureFor
	local override = Spell.GetOverrideSpell(spellId) or spellId
	local tex = hit(override)
	if tex then
		return tex
	end
	if spellId ~= override then
		tex = hit(spellId)
		if tex then
			return tex
		end
	end
	local base = Spell.GetBaseSpell(spellId) or spellId
	if base ~= override and base ~= spellId then
		return hit(base)
	end
	return nil
end

function Spell.GetSubtext(spellId)
	if C_Spell and C_Spell.GetSpellSubtext then
		return C_Spell.GetSpellSubtext(spellId)
	end
	if GetSpellSubtext then
		return GetSpellSubtext(spellId)
	end
	return nil
end

function Spell.GetCooldown(spellId)
	if not spellId then
		return 0, 0, 0
	end
	if C_Spell and C_Spell.GetSpellCooldown then
		local ok, cd = pcall(C_Spell.GetSpellCooldown, spellId)
		if ok and cd then
			if type(cd) == "table" then
				return cd.startTime, cd.duration, cd.isEnabled, cd.modRate, cd.isActive
			end
			return cd
		end
	end
	if GetSpellCooldown then
		local ok, a, b, c, d = pcall(GetSpellCooldown, spellId)
		if ok and a ~= nil then
			if type(a) == "table" then
				return a.startTime or a.start, a.duration, a.isEnabled or a.enable, a.modRate, a.isActive
			end
			return a, b, c, d
		end
	end
	return 0, 0, 0
end

-- Midnight duration object. Nil on Classic / when the API is missing.
function Spell.GetCooldownDuration(spellId)
	if not spellId or not (C_Spell and C_Spell.GetSpellCooldownDuration) then
		return nil
	end
	local ok, dur = pcall(C_Spell.GetSpellCooldownDuration, spellId)
	if ok then
		return dur
	end
	return nil
end

function Spell.GetCount(spellId)
	if not spellId then
		return 0
	end
	if C_Spell and C_Spell.GetSpellCastCount then
		local ok, n = pcall(C_Spell.GetSpellCastCount, spellId)
		if ok then
			if Flux.Secrets and Flux.Secrets.SafeGetNumber then
				return Flux.Secrets.SafeGetNumber(n, 0)
			end
			return tonumber(n) or 0
		end
	end
	if GetSpellCount then
		local ok, n = pcall(GetSpellCount, spellId)
		if ok then
			if Flux.Secrets and Flux.Secrets.SafeGetNumber then
				return Flux.Secrets.SafeGetNumber(n, 0)
			end
			return tonumber(n) or 0
		end
	end
	return 0
end

-- current, max, cooldownStart, cooldownDuration, chargeModRate.
-- Nil if the spell has no charges. Pass Midnight secrets / duration objects through.
function Spell.GetCharges(spellId)
	if not spellId then
		return nil
	end
	local ident = Spell.GetOverrideSpell and Spell.GetOverrideSpell(spellId) or spellId
	if C_Spell and C_Spell.GetSpellCharges then
		local ok, a, b, c, d, e = pcall(C_Spell.GetSpellCharges, ident)
		if ok and a ~= nil then
			local t = type(a)
			if t == "table" or t == "userdata" then
				-- isActive is NeverSecret. Read it even when charge counts are
				-- secret so combat still fetches GetSpellChargeDuration.
				local chargeActive = a.isActive
				local okF, cur, maxC, start, duration, rate = pcall(function()
					return a.currentCharges, a.maxCharges, a.cooldownStartTime, a.cooldownDuration, a.chargeModRate
				end)
				if okF then
					return cur, maxC, start, duration, rate, chargeActive
				end
				return nil, nil, nil, nil, nil, chargeActive
			else
				return a, b, c, d, e
			end
		end
	end
	if GetSpellCharges then
		local ok, cur, maxC, start, duration, rate = pcall(GetSpellCharges, ident)
		if ok and (cur ~= nil or maxC ~= nil) then
			return cur, maxC, start, duration, rate
		end
	end
	if ident ~= spellId and GetSpellCharges then
		local ok, cur, maxC, start, duration, rate = pcall(GetSpellCharges, spellId)
		if ok and (cur ~= nil or maxC ~= nil) then
			return cur, maxC, start, duration, rate
		end
	end
	return nil
end

-- Midnight duration object for the charge recharge (not GCD). Nil on Classic / when missing.
function Spell.GetChargeDuration(spellId)
	if not spellId or not (C_Spell and C_Spell.GetSpellChargeDuration) then
		return nil
	end
	local ident = Spell.GetOverrideSpell and Spell.GetOverrideSpell(spellId) or spellId
	local ok, dur = pcall(C_Spell.GetSpellChargeDuration, ident)
	if ok then
		return dur
	end
	return nil
end

-- Reagents or charges. Midnight may return a secret; callers SetText write-through.
-- Do not CanAccessValue-nil: that blanks the digit in instances.
function Spell.GetDisplayCount(spellId)
	if not spellId or not C_Spell or not C_Spell.GetSpellDisplayCount then
		return nil
	end
	local ident = Spell.GetOverrideSpell and Spell.GetOverrideSpell(spellId) or spellId
	local ok, text = pcall(C_Spell.GetSpellDisplayCount, ident)
	if not ok or text == nil then
		return nil
	end
	return text
end

local function QueryIsUsable(key)
	if not key then
		return nil, nil
	end
	if C_Spell and C_Spell.IsSpellUsable then
		local ok, a, b = pcall(C_Spell.IsSpellUsable, key)
		if ok then
			return a, b
		end
	end
	if IsUsableSpell then
		local ok, a, b = pcall(IsUsableSpell, key)
		if ok then
			return a, b
		end
	end
	return nil, nil
end

local function AccessiblePair(a, b)
	if Flux.Secrets and Flux.Secrets.CanAccessValue then
		if a ~= nil then
			local ok, accessible = pcall(Flux.Secrets.CanAccessValue, a)
			if not ok or not accessible then
				return nil, nil
			end
		end
		if b ~= nil then
			local ok, accessible = pcall(Flux.Secrets.CanAccessValue, b)
			if not ok or not accessible then
				return nil, nil
			end
		end
	end
	return a, b
end

-- true/false, or nil,nil when secret / API miss (do not treat as unusable).
function Spell.IsUsable(spellId)
	if not spellId then
		return nil, nil
	end
	local ident = Spell.GetOverrideSpell(spellId) or spellId
	local a, b = QueryIsUsable(ident)
	if a == nil and b == nil then
		local nameKey = Spell.FormatCastAttribute(ident)
		if nameKey and nameKey ~= ident then
			a, b = QueryIsUsable(nameKey)
		end
	end
	a, b = AccessiblePair(a, b)
	if a == nil and b == nil then
		return nil, nil
	end
	local usable = Flux.Secrets and Flux.Secrets.SafeBooleanTest and Flux.Secrets.SafeBooleanTest(a, nil)
	local noMana = Flux.Secrets and Flux.Secrets.SafeBooleanTest and Flux.Secrets.SafeBooleanTest(b, false)
	if usable == nil then
		if a == nil then
			return nil, nil
		end
		usable = a and true or false
	end
	return usable, noMana and true or false
end

local function NormalizeRange(r)
	if Flux.Secrets and Flux.Secrets.NormalizeTriBool then
		return Flux.Secrets.NormalizeTriBool(r)
	end
	if r == true or r == 1 then
		return true
	end
	if r == false or r == 0 then
		return false
	end
	return nil
end

-- true in range, false out of range, nil = N/A or secret (do not paint OOR).
-- Tries override ID, ranked/name cast key, then localized name (Classic Era).
local function QueryRange(key, unit)
	if not key then
		return nil
	end
	if C_Spell and C_Spell.IsSpellInRange then
		local ok, r = pcall(C_Spell.IsSpellInRange, key, unit)
		if ok and r ~= nil then
			return r
		end
	end
	if IsSpellInRange then
		local ok, r = pcall(IsSpellInRange, key, unit)
		if ok then
			return r
		end
	end
	return nil
end

function Spell.IsInRange(spellId, unit)
	unit = unit or "target"
	if not spellId or not unit then
		return nil
	end
	local ident = Spell.GetOverrideSpell(spellId) or spellId
	-- Probed for every ranged surface five times a second, so try the keys in
	-- place instead of building a list.
	local normalized = NormalizeRange(QueryRange(ident, unit))
	if normalized ~= nil then
		return normalized
	end
	local nameKey = Spell.FormatCastAttribute(ident)
	if nameKey and nameKey ~= ident then
		normalized = NormalizeRange(QueryRange(nameKey, unit))
		if normalized ~= nil then
			return normalized
		end
	end
	local plainName = Spell.GetName(ident)
	if plainName and plainName ~= ident and plainName ~= nameKey then
		return NormalizeRange(QueryRange(plainName, unit))
	end
	return nil
end

-- Form/meta overrides that must cast by ID (ButtonForge Const.IdCastSpellIds).
local ID_CAST = {
	[228260] = true, -- Void Eruption
	[228266] = true, -- Void Bolt
	[1217605] = true, -- Void Metamorphosis
	[473662] = true, -- Consume
	[1226019] = true, -- Reap
}

function Spell.GetBaseSpell(spellId)
	if C_Spell and C_Spell.GetBaseSpell and spellId then
		local ok, base = pcall(C_Spell.GetBaseSpell, spellId)
		if ok and type(base) == "number" and base > 0 then
			return base
		end
	end
	return spellId
end

function Spell.GetOverrideSpell(spellId)
	if not spellId then
		return spellId
	end
	if C_Spell and C_Spell.GetOverrideSpell then
		local ok, ov = pcall(C_Spell.GetOverrideSpell, spellId)
		if ok and type(ov) == "number" and ov > 0 then
			return ov
		end
	end
	-- Classic: wow-ui-source uses C_SpellBook.FindSpellOverrideByID.
	if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
		local ok, ov = pcall(C_SpellBook.FindSpellOverrideByID, spellId)
		if ok and type(ov) == "number" and ov > 0 then
			return ov
		end
	end
	return spellId
end

function Spell.IdsMatch(a, b)
	a = tonumber(a) or a
	b = tonumber(b) or b
	if not a or not b then
		return false
	end
	if a == b then
		return true
	end
	local ba = Spell.GetBaseSpell(a)
	local bb = Spell.GetBaseSpell(b)
	if ba and bb and ba == bb then
		return true
	end
	local oa = Spell.GetOverrideSpell(a)
	local ob = Spell.GetOverrideSpell(b)
	if oa and ob and oa == ob then
		return true
	end
	return false
end

-- Action-button on-state face (wisp) when a shapeshift/form spell is current.
-- Not a per-spell list: Blizzard uses this one replacement on spell actions.
local WISP_FACE = "Interface\\Icons\\Spell_Nature_WispSplode"
local liveFaceCache = {}

function Spell.ClearLiveFaceCache()
	if wipe then
		wipe(liveFaceCache)
	else
		for k in pairs(liveFaceCache) do
			liveFaceCache[k] = nil
		end
	end
end

local function FaceOk(tex)
	return tex ~= nil and tex ~= 0 and tex ~= ""
end

local function SlotIsFlyoutAction(slot)
	if not slot then
		return false
	end
	local actionType
	if Flux.Action and Flux.Action.GetInfo then
		actionType = Flux.Action.GetInfo(slot)
	elseif GetActionInfo then
		local ok, t = pcall(GetActionInfo, slot)
		if ok then
			actionType = t
		end
	end
	return actionType == "flyout"
end

local function SlotFace(slot)
	if not slot then
		return nil
	end
	-- Flyout bar slots use the parent art. Never paint an inner spell with that.
	if SlotIsFlyoutAction(slot) then
		return nil
	end
	if Flux.Action and Flux.Action.GetTexture then
		local tex = Flux.Action.GetTexture(slot)
		if FaceOk(tex) then
			return tex
		end
	end
	if C_ActionBar and C_ActionBar.GetActionTexture then
		local ok, tex = pcall(C_ActionBar.GetActionTexture, slot)
		if ok and FaceOk(tex) then
			return tex
		end
	end
	if GetActionTexture then
		local ok, tex = pcall(GetActionTexture, slot)
		if ok and FaceOk(tex) then
			return tex
		end
	end
	return nil
end

local function ActionBarFace(spellId)
	local cab = C_ActionBar
	if cab and cab.FindSpellActionButtons then
		local seen = {}
		local function consider(id)
			if not id or seen[id] then
				return nil
			end
			seen[id] = true
			local ok, slots = pcall(cab.FindSpellActionButtons, id)
			if not ok or type(slots) ~= "table" then
				return nil
			end
			for i = 1, #slots do
				local tex = SlotFace(slots[i])
				if tex then
					return tex
				end
			end
			return nil
		end
		local tex = consider(Spell.GetBaseSpell(spellId) or spellId)
		if tex then
			return tex
		end
		tex = consider(spellId)
		if tex then
			return tex
		end
		return consider(Spell.GetOverrideSpell(spellId))
	end
	return nil
end

local function BookSlotIsFlyout(slot, bank)
	if not slot then
		return false
	end
	local SB = C_SpellBook
	if SB and SB.GetSpellBookItemInfo then
		local ok, info = pcall(SB.GetSpellBookItemInfo, slot, bank)
		if ok and info then
			local flyoutType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
			if flyoutType and info.itemType == flyoutType then
				return true
			end
			if type(info.itemType) == "string" and info.itemType:lower() == "flyout" then
				return true
			end
		end
	end
	if GetSpellBookItemInfo then
		local ok, kind = pcall(GetSpellBookItemInfo, slot, bank or BOOKTYPE_SPELL)
		if ok then
			if type(kind) == "table" then
				local flyoutType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
				if flyoutType and kind.itemType == flyoutType then
					return true
				end
			elseif type(kind) == "string" and kind:lower() == "flyout" then
				return true
			end
		end
	end
	return false
end

local function SpellBookFace(spellId)
	if not spellId then
		return nil
	end
	local SB = C_SpellBook
	-- includeFlyouts must stay false: the flyout's book slot texture is the
	-- parent icon (Summon Demon), not Imp / Voidwalker / etc.
	if SB and SB.FindSpellBookSlotForSpell and SB.GetSpellBookItemTexture then
		local ok, slot, bank = pcall(SB.FindSpellBookSlotForSpell, spellId, false, false, false, false)
		if ok and slot and not BookSlotIsFlyout(slot, bank) then
			local okTex, tex = pcall(SB.GetSpellBookItemTexture, slot, bank)
			if okTex and FaceOk(tex) then
				return tex
			end
		end
	end
	if FindSpellBookSlotBySpellID and GetSpellBookItemTexture then
		local ok, slot, bookType = pcall(FindSpellBookSlotBySpellID, spellId)
		if ok and slot and not BookSlotIsFlyout(slot, bookType) then
			local okTex, tex = pcall(GetSpellBookItemTexture, slot, bookType or BOOKTYPE_SPELL)
			if okTex and FaceOk(tex) then
				return tex
			end
		end
	end
	return nil
end

-- Extra Buttons have no action slot. Prefer a real bar's GetActionTexture.
-- If this id is the active shapeshift/form and no bar slot exists, use the
-- action-button wisp (GetSpellTexture does not return that face).
function Spell.GetLiveFace(spellId)
	if not spellId then
		return nil
	end
	local hit = liveFaceCache[spellId]
	if hit ~= nil then
		if hit == false then
			return nil
		end
		return hit
	end
	local function store(tex)
		liveFaceCache[spellId] = tex or false
		return tex
	end
	local bar = ActionBarFace(spellId)
	if bar then
		return store(bar)
	end
	local Shapeshift = Flux.Shapeshift
	if Shapeshift and Shapeshift.MatchesActiveForm and Shapeshift.MatchesActiveForm(spellId) then
		return store(WISP_FACE)
	end
	local live = SpellBookFace(spellId) or Spell.GetTexture(spellId) or Spell.GetIcon(spellId)
	if not FaceOk(live) and SpellRecordCold(spellId) then
		-- Do not remember the miss. A cold Forever spell would stay blank.
		return nil
	end
	return store(live)
end

local function SpellIdentHit(fn, ident)
	if ident == nil or ident == "" or type(fn) ~= "function" then
		return false
	end
	local ok, v = pcall(fn, ident)
	if not ok then
		return false
	end
	if Flux.Secrets and Flux.Secrets.SafeBooleanTest then
		return Flux.Secrets.SafeBooleanTest(v, false) and true or false
	end
	return v and true or false
end

-- ButtonForge Classic/TBC: name+rank. Post-DF: GetOverrideSpell(id).
-- Try override id, raw id, then SpellNameRank / formatted name.
local function SpellEachIdent(spellId, nameRank, fn)
	local seen = {}
	local function consider(ident)
		if ident == nil or ident == "" or seen[ident] then
			return false
		end
		seen[ident] = true
		return fn(ident)
	end
	if spellId then
		if consider(Spell.GetOverrideSpell(spellId)) then
			return true
		end
		if consider(spellId) then
			return true
		end
	end
	if consider(nameRank) then
		return true
	end
	if type(spellId) == "number" then
		if consider(Spell.FormatCastAttribute(spellId)) then
			return true
		end
		if consider(Spell.GetName(spellId)) then
			return true
		end
	end
	return false
end

function Spell.IsCurrent(spellId, nameRank)
	if not spellId and (type(nameRank) ~= "string" or nameRank == "") then
		return false
	end
	return SpellEachIdent(spellId, nameRank, function(ident)
		if C_Spell and SpellIdentHit(C_Spell.IsCurrentSpell, ident) then
			return true
		end
		return SpellIdentHit(IsCurrentSpell, ident)
	end)
end

function Spell.IsAutoRepeat(spellId, nameRank)
	if not spellId and (type(nameRank) ~= "string" or nameRank == "") then
		return false
	end
	return SpellEachIdent(spellId, nameRank, function(ident)
		if C_Spell and SpellIdentHit(C_Spell.IsAutoRepeatSpell, ident) then
			return true
		end
		return SpellIdentHit(IsAutoRepeatSpell, ident)
	end)
end

function Spell.IsIdCast(spellId)
	return spellId and ID_CAST[spellId] and true or false
end

--- Classic ranks: "Name(Rank N)". Post-DF: name(+subtext) except a short ID-cast list.
function Spell.FormatCastAttribute(spellId)
	local id = tonumber(spellId)
	if not id or id <= 0 then
		return spellId
	end
	local hit = castAttrCache[id]
	if hit ~= nil then
		return hit
	end
	local result = Spell.BuildCastAttribute(id)
	castAttrCache[id] = result
	return result
end

function Spell.BuildCastAttribute(id)
	local Client = Flux.Client
	local name = Spell.GetName(id)
	local subtext = Spell.GetSubtext(id)
	-- Forever is retail-shaped but keeps classic ranks. Numeric ID casts skip Rank N.
	local rankClient = Client and (Client.isCamelot or Client.isForever)
	if Client and Client.isRetail and Client.isPostDF and not rankClient then
		if ID_CAST[id] then
			return id
		end
		if not name or name == "" then
			return id
		end
		if type(subtext) == "string" and subtext ~= "" then
			return name .. "(" .. subtext .. ")"
		end
		return name
	end
	if not name or name == "" then
		return id
	end
	if type(subtext) == "string" and subtext ~= "" then
		return name .. "(" .. subtext .. ")"
	end
	return name
end

local function PositiveSpellId(value)
	if type(value) == "table" then
		value = value.spellID or value.overrideSpellID or value.flyoutSpellID or value.actionID
	end
	value = tonumber(value)
	if value and value > 0 then
		return value
	end
	return nil
end

local function SlotNameString(value)
	if type(value) == "string" and value ~= "" then
		return value
	end
	if type(value) == "table" then
		if type(value.name) == "string" and value.name ~= "" then
			return value.name
		end
		if type(value.spellName) == "string" and value.spellName ~= "" then
			return value.spellName
		end
	end
	return nil
end

local function CallFlyoutApi(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, a, b, c, d, e = pcall(fn, ...)
	if not ok then
		return nil
	end
	return a, b, c, d, e
end

-- Flyout slot ids: overrideSpellID is often 0. Never treat 0 as a spell.
function Spell.GetFlyoutInfo(flyoutId)
	if not flyoutId then
		return nil
	end
	local a, b, c, d = CallFlyoutApi(GetFlyoutInfo, flyoutId)
	if a == nil and C_Spell and C_Spell.GetFlyoutInfo then
		a, b, c, d = CallFlyoutApi(C_Spell.GetFlyoutInfo, flyoutId)
	end
	if type(a) == "table" then
		local info = a
		return info.name, info.description, info.numSlots or info.slotCount or 0, info.isKnown
	end
	return a, b, c, d
end

function Spell.GetFlyoutSlotInfo(flyoutId, slotIndex)
	if not flyoutId or not slotIndex then
		return nil
	end
	local a, b, c, d, e = CallFlyoutApi(GetFlyoutSlotInfo, flyoutId, slotIndex)
	if a == nil and C_Spell and C_Spell.GetFlyoutSlotInfo then
		a, b, c, d, e = CallFlyoutApi(C_Spell.GetFlyoutSlotInfo, flyoutId, slotIndex)
	end
	if type(a) == "table" then
		local info = a
		a = info.spellID or info.flyoutSpellID
		b = info.overrideSpellID
		c = info.isKnown
		d = info.spellName or info.name
		e = info.slotSpecID
	end
	local flyoutSpellID = PositiveSpellId(a)
	local overrideSpellID = PositiveSpellId(b)
	local name = SlotNameString(d) or Spell.GetName(overrideSpellID or flyoutSpellID)
	return flyoutSpellID, overrideSpellID, c, name, e
end

function Spell.FlyoutSlotCastID(flyoutId, slotIndex)
	local flyoutSpellID, overrideSpellID = Spell.GetFlyoutSlotInfo(flyoutId, slotIndex)
	return overrideSpellID or flyoutSpellID
end

function Spell.FlyoutHasSpell(flyoutId, spellId)
	spellId = PositiveSpellId(spellId)
	if not flyoutId or not spellId then
		return false
	end
	if FlyoutHasSpell then
		local ok, has = pcall(FlyoutHasSpell, flyoutId, spellId)
		if ok and has then
			return true
		end
	end
	if C_Spell and C_Spell.FlyoutHasSpell then
		local ok, has = pcall(C_Spell.FlyoutHasSpell, flyoutId, spellId)
		if ok and has then
			return true
		end
	end
	local _, _, numSlots = Spell.GetFlyoutInfo(flyoutId)
	for i = 1, (numSlots or 0) do
		local sid, ov = Spell.GetFlyoutSlotInfo(flyoutId, i)
		if sid == spellId or ov == spellId then
			return true
		end
		local castId = Spell.FlyoutSlotCastID(flyoutId, i)
		if castId == spellId then
			return true
		end
	end
	return false
end

function Spell.FindFlyoutSlotCastID(spellId, spellName)
	spellId = PositiveSpellId(spellId)
	if not spellId and (type(spellName) ~= "string" or spellName == "") then
		return nil
	end
	local function search(flyoutId)
		if not flyoutId then
			return nil
		end
		local _, _, numSlots = Spell.GetFlyoutInfo(flyoutId)
		for i = 1, (numSlots or 0) do
			local sid, ov, _, name = Spell.GetFlyoutSlotInfo(flyoutId, i)
			if (spellId and (sid == spellId or ov == spellId))
				or (spellName and name == spellName)
			then
				return Spell.FlyoutSlotCastID(flyoutId, i)
			end
		end
		return nil
	end
	if GetNumFlyouts and GetFlyoutID then
		local n = GetNumFlyouts() or 0
		for i = 1, n do
			local hit = search(GetFlyoutID(i))
			if hit then
				return hit
			end
		end
	end
	local SB = C_SpellBook
	if SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemInfo then
		local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
		local flyoutType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
		local okLines, nLines = pcall(SB.GetNumSpellBookSkillLines)
		if okLines and type(nLines) == "number" then
			for line = 1, nLines do
				local okLine, info = pcall(SB.GetSpellBookSkillLineInfo, line)
				if okLine and info then
					local offset = info.itemIndexOffset or 0
					local count = info.numSpellBookItems or 0
					for slot = offset + 1, offset + count do
						local okItem, item = pcall(SB.GetSpellBookItemInfo, slot, bank)
						if okItem and item and flyoutType and item.itemType == flyoutType and item.actionID then
							local hit = search(item.actionID)
							if hit then
								return hit
							end
						end
					end
				end
			end
		end
	end
	return nil
end

function Spell.ClearCache()
	ClearCache()
	Spell.ClearLiveFaceCache()
end

local function OnSpellDataLoad(_, spellID, success)
	spellID = tonumber(spellID)
	if not spellID then
		return
	end
	cache[spellID] = nil
	castAttrCache[spellID] = nil
	liveFaceCache[spellID] = nil
	loadRequested[spellID] = nil
	if success == false then
		return
	end
	local Bars = Flux.Bars
	if Bars and Bars.BadgeHost and Bars.BadgeHost.RefreshDisplays then
		pcall(Bars.BadgeHost.RefreshDisplays)
	end
	if Bars and Bars.ForEachHost and Bars.Paint and Bars.Paint.Dirty then
		Bars.ForEachHost(function(host)
			Bars.Paint.Dirty(host)
		end)
	end
end

Flux.AfterLoad(function()
	if not Flux.Events then
		return
	end
	Flux.Events.RegisterLearnedSpell(Spell.ClearCache)
	if Flux.Events.Register then
		Flux.Events.Register("SPELL_UPDATE_ICON", Spell.ClearCache)
		Flux.Events.Register("SPELL_DATA_LOAD_RESULT", OnSpellDataLoad)
	end
end)
