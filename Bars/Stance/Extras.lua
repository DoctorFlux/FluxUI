-- Bars/Stance/Extras.lua — class extras (mage armor / summons) + form dedup.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Stance = Bars.Stance or {}
Bars.Stance = Stance

local cached
local cachedClass
local mageArmorIds = {}

local PET_SUMMON = {
	["Summon Imp"] = true,
	["Summon Voidwalker"] = true,
	["Summon Felhunter"] = true,
	["Summon Succubus"] = true,
	["Summon Felguard"] = true,
	["Summon Sayaad"] = true,
}

local WARLOCK_SUMMON_IDS = {
	{ "Summon Imp", 688 },
	{ "Summon Voidwalker", 697 },
	{ "Summon Succubus", 712 },
	{ "Summon Felhunter", 691 },
	{ "Summon Felguard", 30146 },
	{ "Summon Sayaad", 366222 },
}

local ARMORS = { "Ice Armor", "Mage Armor", "Frost Armor", "Molten Armor" }
local WISP_ICON = "Interface\\Icons\\spell_nature_wispsplode"

-- Classic / anniversary ranks. Lookup by id, not a full helpful-aura scan.
local MAGE_ARMOR_SPELL_IDS = {
	168, 7300, 7301,
	7302, 7320, 10219, 10220,
	27124, 43008,
	6117, 22782, 22783,
	30482, 43045, 43046,
}

local ICE_ARMOR_IDS = { 7302, 7320, 10219, 10220, 27124, 43008 }
local FROST_ARMOR_IDS = { 168, 7300, 7301 }

local MAGE_ARMOR_FALLBACK = {
	{ "Frost Armor", 168 },
	{ "Ice Armor", 7302 },
	{ "Mage Armor", 6117 },
	{ "Molten Armor", 30482 },
}

local DEMON_FAMILY = {
	Imp = "Summon Imp",
	Voidwalker = "Summon Voidwalker",
	Felhunter = "Summon Felhunter",
	Succubus = "Summon Succubus",
	Felguard = "Summon Felguard",
	Incubus = "Summon Sayaad",
	Sayaad = "Summon Sayaad",
	["Water Elemental"] = "Summon Water Elemental",
}

local function SpellName(id)
	if Flux.Spell and Flux.Spell.GetName then
		return Flux.Spell.GetName(id)
	end
	if GetSpellInfo then
		local n = GetSpellInfo(id)
		if type(n) == "table" then
			return n.name
		end
		return n
	end
	return nil
end

local function SpellIcon(id)
	if Flux.Spell and Flux.Spell.GetIcon then
		return Flux.Spell.GetIcon(id)
	end
	return nil
end

local function SpellKnown(id)
	if not id then
		return false
	end
	if IsPlayerSpell then
		local ok, v = pcall(IsPlayerSpell, id)
		if ok and v then
			return true
		end
	end
	if IsSpellKnown then
		local ok, v = pcall(IsSpellKnown, id)
		if ok and v then
			return true
		end
	end
	return false
end

local function AsName(v)
	if type(v) == "table" then
		return v.name
	end
	if type(v) == "string" then
		return v
	end
	return nil
end

local function ListHasName(list, name)
	if not name then
		return false
	end
	for i = 1, #list do
		local n = list[i] and (list[i].name or list[i].spellName)
		if n == name then
			return true
		end
	end
	return false
end

local function ExtraName(data)
	return data and (data.name or data.spellName) or nil
end

local function ExtraLooksLikeIceArmor(data)
	if not data then
		return false
	end
	local n = ExtraName(data)
	if n and n:find("Ice Armor", 1, true) then
		return true
	end
	local sid = data.spellID
	if not sid then
		return false
	end
	for i = 1, #ICE_ARMOR_IDS do
		if sid == ICE_ARMOR_IDS[i] then
			return true
		end
	end
	return false
end

local function ExtraLooksLikeFrostArmor(data)
	if not data then
		return false
	end
	local n = ExtraName(data)
	if n and n:find("Frost Armor", 1, true) then
		return true
	end
	local sid = data.spellID
	if not sid then
		return false
	end
	for i = 1, #FROST_ARMOR_IDS do
		if sid == FROST_ARMOR_IDS[i] then
			return true
		end
	end
	return false
end

local function PlayerKnowsIceArmor()
	for i = 1, #ICE_ARMOR_IDS do
		if SpellKnown(ICE_ARMOR_IDS[i]) then
			return true
		end
	end
	return false
end

-- Ice Armor replaces Frost Armor; keep only Ice when both are known.
local function PruneFrostIfIceKnown(list)
	if not list then
		return
	end
	local iceKnown = PlayerKnowsIceArmor()
	if not iceKnown then
		for i = 1, #list do
			if ExtraLooksLikeIceArmor(list[i]) then
				iceKnown = true
				break
			end
		end
	end
	if not iceKnown then
		return
	end
	for i = #list, 1, -1 do
		if ExtraLooksLikeFrostArmor(list[i]) then
			table.remove(list, i)
		end
	end
end

local function AddExtra(list, name, spellID, texture, flags)
	spellID = tonumber(spellID)
	if not spellID or spellID <= 0 then
		return
	end
	local n = name or SpellName(spellID) or "?"
	if ListHasName(list, n) then
		return
	end
	list[#list + 1] = {
		name = n,
		spellName = n,
		spellID = spellID,
		texture = texture or SpellIcon(spellID),
		isMageArmor = flags and flags.isMageArmor or nil,
	}
	if flags and flags.isMageArmor then
		mageArmorIds[spellID] = true
	end
end

function Stance.InvalidateExtras()
	cached = nil
	cachedClass = nil
	mageArmorIds = {}
end

function Stance.GetMageArmorIds()
	return mageArmorIds
end

function Stance.GetActivePetSpell()
	local class = select(2, UnitClass("player"))
	if class ~= "WARLOCK" and class ~= "MAGE" then
		return nil
	end
	if not (UnitExists and UnitExists("pet")) then
		return nil
	end
	local family = UnitCreatureFamily and UnitCreatureFamily("pet")
	if family and DEMON_FAMILY[family] then
		return DEMON_FAMILY[family]
	end
	local petName = UnitName and UnitName("pet")
	if petName then
		for demonName, spellName in pairs(DEMON_FAMILY) do
			if petName:find(demonName, 1, true) then
				return spellName
			end
		end
	end
	return nil
end

local lastArmor

local function AurasRestricted()
	local S = Flux.Secrets
	if S and S.AurasRestricted then
		return S.AurasRestricted()
	end
	return false
end

local function PublicNumber(value)
	if value == nil then
		return nil
	end
	local S = Flux.Secrets
	if S and S.IsSecretValue and S.IsSecretValue(value) then
		return nil
	end
	if S and S.CanAccessValue and not S.CanAccessValue(value) then
		return nil
	end
	local ok, n = pcall(tonumber, value)
	if not ok or n == nil then
		return nil
	end
	if S and S.IsSecretValue and S.IsSecretValue(n) then
		return nil
	end
	return n
end

local function PublicString(value)
	if type(value) ~= "string" then
		return nil
	end
	local S = Flux.Secrets
	if S and S.SafeAccessibleString then
		return S.SafeAccessibleString(value)
	end
	return value
end

local function IdsMatch(a, b)
	if a == nil or b == nil then
		return false
	end
	if Flux.Spell and Flux.Spell.IdsMatch then
		return Flux.Spell.IdsMatch(a, b)
	end
	if Flux.Secrets and Flux.Secrets.SafeEqualForCache then
		return Flux.Secrets.SafeEqualForCache(a, b)
	end
	return a == b
end

local function CooldownAuraId(spellId)
	local Aura = Flux.Aura
	if Aura and Aura.GetCooldownAuraBySpellID then
		return Aura.GetCooldownAuraBySpellID(spellId)
	end
	return nil
end

local function AuraFromSpellId(spellId)
	if not spellId then
		return nil
	end
	local Aura = Flux.Aura
	local data
	if Aura and Aura.GetPlayerAuraBySpellID then
		data = Aura.GetPlayerAuraBySpellID(spellId)
	elseif C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
		local ok, result = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellId)
		if ok then
			data = result
		end
	end
	if not data then
		return nil
	end
	local name, duration, expirationTime, sid, inst, timeMod
	pcall(function()
		name = data.name
		duration = data.duration
		expirationTime = data.expirationTime
		sid = data.spellId or data.spellID or spellId
		inst = data.auraInstanceID
		timeMod = data.timeMod
	end)
	return {
		name = name,
		duration = duration,
		expirationTime = expirationTime,
		spellID = sid or spellId,
		auraInstanceID = inst,
		timeMod = timeMod,
	}
end

local function ArmorNameMatch(buffName)
	if not buffName then
		return false
	end
	for i = 1, #ARMORS do
		if buffName:find(ARMORS[i], 1, true) then
			return true
		end
	end
	return false
end

local function ArmorFromNameDurExp(name, duration, expirationTime, spellId)
	if not ArmorNameMatch(name) then
		return nil
	end
	return {
		name = name,
		duration = duration,
		expirationTime = expirationTime,
		spellID = spellId,
	}
end

local function AuraFromHelpfulScan()
	local S = Flux.Secrets
	if AurasRestricted() then
		return nil
	end
	local function take(name, duration, expirationTime, spellId)
		if S and S.CanAccessValue and name ~= nil and not S.CanAccessValue(name) then
			return nil
		end
		return ArmorFromNameDurExp(name, duration, expirationTime, spellId)
	end
	if Flux.Aura and Flux.Aura.GetSlots and Flux.Aura.GetDataBySlot then
		local slots = Flux.Aura.GetSlots("player", "HELPFUL")
		if type(slots) == "table" then
			for i = 1, #slots do
				local slot = slots[i]
				if type(slot) == "number" then
					local ok, data = pcall(Flux.Aura.GetDataBySlot, "player", slot)
					if ok and data and data.name then
						local hit = take(data.name, data.duration, data.expirationTime, data.spellId or data.spellID)
						if hit then
							return hit
						end
					end
				end
			end
		end
	end
	if Flux.Aura and Flux.Aura.GetDataByIndex then
		for i = 1, 40 do
			local data = Flux.Aura.GetDataByIndex("player", i, "HELPFUL")
			if data and data.name then
				local hit = take(data.name, data.duration, data.expirationTime, data.spellId or data.spellID)
				if hit then
					return hit
				end
			elseif not data then
				break
			end
		end
	end
	if UnitAura then
		for i = 1, 40 do
			local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitAura("player", i, "HELPFUL")
			if not name then
				break
			end
			local hit = take(name, duration, expirationTime, spellId)
			if hit then
				return hit
			end
		end
	end
	if UnitBuff then
		for i = 1, 40 do
			local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", i)
			if not name then
				break
			end
			local hit = take(name, duration, expirationTime, spellId)
			if hit then
				return hit
			end
		end
	end
	return nil
end

-- Present even when duration/name are secret. Public expiration in the past is gone.
local function NormalizeArmor(data)
	if not data then
		return nil
	end
	local sid = data.spellID or data.spellId
	local inst = data.auraInstanceID
	local name = data.name
	if sid == nil and inst == nil and name == nil then
		return nil
	end
	local dur = PublicNumber(data.duration)
	local exp = PublicNumber(data.expirationTime)
	local now = (GetTime and GetTime()) or 0
	if exp and exp <= (now + 0.05) then
		return nil
	end
	local instPublic = PublicNumber(inst)
	local durObj
	if instPublic and Flux.Aura and Flux.Aura.GetAuraDuration then
		durObj = Flux.Aura.GetAuraDuration("player", instPublic)
	end
	return {
		name = name,
		duration = dur,
		expirationTime = exp,
		spellID = sid,
		auraInstanceID = instPublic,
		durationObject = durObj,
		timeMod = PublicNumber(data.timeMod),
		present = true,
	}
end

local function TryArmorId(spellId)
	if not spellId then
		return nil
	end
	local hit = NormalizeArmor(AuraFromSpellId(spellId))
	if hit then
		return hit
	end
	return NormalizeArmor(AuraFromSpellId(CooldownAuraId(spellId)))
end

local function ArmorStillTimed(data)
	if not data then
		return false
	end
	local now = (GetTime and GetTime()) or 0
	local exp = PublicNumber(data.expirationTime)
	if exp then
		return exp > (now + 0.05)
	end
	if data.durationObject ~= nil then
		return true
	end
	return data.present and true or false
end

-- GetAuraDuration fails when the instance is gone (cancel / expiry) even if
-- GetPlayerAuraBySpellID is RequiresNonSecretAura-nil in combat.
-- true = still up, false = confirmed gone, nil = could not probe.
local function RefreshHeldDuration(data)
	if not data then
		return nil
	end
	local inst = PublicNumber(data.auraInstanceID)
	if not inst then
		return nil
	end
	local Aura = Flux.Aura
	if not (Aura and Aura.GetAuraDuration) then
		return nil
	end
	if not ((Flux.Cap and Flux.Cap.hasC_UnitAuras_GetAuraDuration) or (C_UnitAuras and C_UnitAuras.GetAuraDuration)) then
		return nil
	end
	local obj = Aura.GetAuraDuration("player", inst)
	if obj then
		data.durationObject = obj
		data.auraInstanceID = inst
		return true
	end
	return false
end

local function MergeHeld(hit, prev)
	if not hit or not prev then
		return hit
	end
	if prev.spellID ~= nil and hit.spellID ~= nil and not IdsMatch(hit.spellID, prev.spellID) then
		return hit
	end
	if PublicNumber(hit.duration) == nil then
		hit.duration = prev.duration
	end
	if PublicNumber(hit.expirationTime) == nil then
		hit.expirationTime = prev.expirationTime
	end
	if hit.durationObject == nil then
		hit.durationObject = prev.durationObject
	end
	if PublicNumber(hit.auraInstanceID) == nil then
		hit.auraInstanceID = prev.auraInstanceID
	end
	if hit.name == nil then
		hit.name = prev.name
	end
	if PublicNumber(hit.timeMod) == nil then
		hit.timeMod = prev.timeMod
	end
	return hit
end

local function MergeHeldArmor(hit)
	return MergeHeld(hit, lastArmor)
end

local function ArmorFromActiveForm()
	local S = Flux.Shapeshift
	if not (S and S.GetNumForms and S.GetFormInfo) then
		return nil
	end
	local n = S.GetNumForms() or 0
	for i = 1, n do
		local _, isActive, _, formSpell = S.GetFormInfo(i)
		local on = isActive
		local Sec = Flux.Secrets
		if Sec and Sec.SafeBooleanTest then
			on = Sec.SafeBooleanTest(isActive, false)
		end
		if on and formSpell and Stance.IsMageArmorSpell and Stance.IsMageArmorSpell(formSpell) then
			return {
				spellID = formSpell,
				present = true,
			}
		end
	end
	return nil
end

function Stance.NoteMageArmorCast(spellId)
	spellId = tonumber(spellId)
	if not spellId then
		return
	end
	local hit = TryArmorId(spellId)
	if hit then
		lastArmor = MergeHeldArmor(hit)
		return
	end
	lastArmor = {
		spellID = spellId,
		present = true,
	}
end

function Stance.IsMageArmorSpell(spellId)
	spellId = tonumber(spellId)
	if not spellId then
		return false
	end
	for i = 1, #MAGE_ARMOR_SPELL_IDS do
		if IdsMatch(spellId, MAGE_ARMOR_SPELL_IDS[i]) then
			return true
		end
	end
	for sid in pairs(mageArmorIds) do
		if IdsMatch(spellId, sid) then
			return true
		end
	end
	local n = PublicString(SpellName(spellId))
	if n and ArmorNameMatch(n) then
		return true
	end
	return false
end

function Stance.GetActiveMageArmor()
	local hit
	for i = 1, #MAGE_ARMOR_SPELL_IDS do
		hit = TryArmorId(MAGE_ARMOR_SPELL_IDS[i])
		if hit then
			break
		end
	end
	if not hit then
		for sid in pairs(mageArmorIds) do
			hit = TryArmorId(sid)
			if hit then
				break
			end
		end
	end
	if not hit then
		hit = NormalizeArmor(AuraFromHelpfulScan())
	end
	if hit then
		lastArmor = MergeHeldArmor(hit)
		return lastArmor
	end
	if lastArmor then
		local still = RefreshHeldDuration(lastArmor)
		if still == true then
			return lastArmor
		end
		-- GetAuraDuration is AllowedWhenUntainted: a tainted combat fail is not
		-- a cancel. Only trust a fail when aura reads are actually open.
		if still == false and not AurasRestricted() then
			lastArmor = nil
			return nil
		end
		if AurasRestricted() then
			local exp = PublicNumber(lastArmor.expirationTime)
			local now = (GetTime and GetTime()) or 0
			if exp and exp <= (now + 0.05) then
				lastArmor = nil
				return nil
			end
			if ArmorStillTimed(lastArmor) or lastArmor.present then
				return lastArmor
			end
		end
		lastArmor = nil
	end
	if AurasRestricted() then
		local fromForm = ArmorFromActiveForm()
		if fromForm then
			lastArmor = MergeHeldArmor(fromForm)
			return lastArmor
		end
	end
	return nil
end

function Stance.ArmorPollSignature()
	local active = Stance.GetActiveMageArmor and Stance.GetActiveMageArmor()
	local base = ""
	if active then
		local sid = PublicNumber(active.spellID)
		local exp = PublicNumber(active.expirationTime)
		if sid and exp then
			base = tostring(sid) .. ":" .. tostring(exp)
		elseif sid then
			base = tostring(sid) .. ":live"
		else
			base = "live"
		end
	end
	local custom = Stance.CustomAuraPollSignature and Stance.CustomAuraPollSignature() or ""
	if base == "" then
		return custom
	end
	if custom == "" then
		return base
	end
	return base .. "|" .. custom
end

local visualArmor
local visualArmorReady

function Stance.BeginExtraVisualPass()
	visualArmor = nil
	visualArmorReady = false
end

local function ActiveMageArmorForVisual()
	if not visualArmorReady then
		visualArmor = Stance.GetActiveMageArmor()
		visualArmorReady = true
	end
	return visualArmor
end

local function ArmorMatchesExtra(active, data)
	if not active or not data then
		return false
	end
	local sid = data.spellID
	local aid = active.spellID
	if IdsMatch(sid, aid) then
		return true
	end
	if IdsMatch(CooldownAuraId(sid), aid) then
		return true
	end
	local n = PublicString(ExtraName(data))
	local an = PublicString(active.name)
	if an and n then
		if an == n or an:find(n, 1, true) or n:find(an, 1, true) then
			return true
		end
	end
	local spellName = PublicString(data.spellName)
	if an and spellName and (an == spellName or an:find(spellName, 1, true)) then
		return true
	end
	return false
end

-- start/duration for CooldownFrame_Set so remaining = expiration - now.
-- Nil when times are secret; swipe then uses durationObject instead.
local function ArmorCooldownTimes(active)
	if not active then
		return nil, nil
	end
	local now = (GetTime and GetTime()) or 0
	local dur = PublicNumber(active.duration)
	local exp = PublicNumber(active.expirationTime)
	if exp and exp > 0 then
		local rem = exp - now
		local tmod = PublicNumber(active.timeMod)
		if tmod and tmod > 0 and tmod ~= 1 then
			rem = rem / tmod
		end
		if rem <= 0.05 then
			return nil, nil
		end
		if dur and dur > 0 then
			return exp - dur, dur
		end
		return now, rem
	end
	return nil, nil
end

local function ArmorWispTexture(spellId)
	if Flux.Spell and Flux.Spell.GetConditionalIcon then
		local cond = Flux.Spell.GetConditionalIcon(spellId)
		if cond then
			return cond
		end
	end
	return WISP_ICON
end

-- The icon the player placed. Not the cast/form wisp and not an action-bar face.
local function CustomRestingIcon(data, btn)
	if type(data) ~= "table" then
		return nil
	end
	local kind = data.actionType or data.type
	if kind == "spell" then
		local id = tonumber(data.spellID or data.id) or (btn and tonumber(btn.SpellId))
		if id and Flux.Spell and Flux.Spell.GetIcon then
			return Flux.Spell.GetIcon(id)
		end
	elseif kind == "item" or kind == "toy" then
		local id = tonumber(data.itemID or data.id) or (btn and tonumber(btn.ItemId or btn.ToyId))
		if id and Flux.Item and Flux.Item.GetIcon then
			return Flux.Item.GetIcon(id)
		end
	elseif kind == "mount" then
		local mountID = tonumber(data.id or data.actionValue) or (btn and tonumber(btn.MountId))
		if mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
			local ok, _, _, icon = pcall(C_MountJournal.GetMountInfoByID, mountID)
			if ok and icon then
				return icon
			end
		end
	end
	if type(data.texture) == "string" and data.texture ~= "" then
		return data.texture
	end
	return nil
end

local function PlayerIsCastingSpell(spellId)
	if not spellId then
		return false
	end
	local function Same(id)
		return id and IdsMatch(id, spellId)
	end
	if UnitChannelInfo then
		local ok, _, _, _, _, _, _, _, channelId = pcall(UnitChannelInfo, "player")
		if ok and Same(channelId) then
			return true
		end
	end
	if UnitCastingInfo then
		local ok, _, _, _, _, _, _, _, _, castId = pcall(UnitCastingInfo, "player")
		if ok and Same(castId) then
			return true
		end
	end
	return false
end

local function ExtraAuraTimerOwned(btn)
	return btn and (btn.FluxStanceManagedCooldown or btn.FluxConsumableAuraCooldown) and true or false
end

local auraCountdownActive = {}
local auraCountdownDriver

local function AuraCountdownFontPx(size)
	size = tonumber(size) or 30
	local ratio = Stance.COOLDOWN_COUNTDOWN_FONT_RATIO or 0.35
	local px = size * ratio
	if px < 9 then
		px = 9
	elseif px > 12 then
		px = 12
	end
	return px
end

local function ApplyAuraCountdownFont(fs, size)
	if not fs or not fs.SetFont then
		return false
	end
	local px = AuraCountdownFontPx(size)
	local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
	local ok = pcall(fs.SetFont, fs, font, px, "OUTLINE")
	if ok then
		fs._fluxFontReady = true
	end
	return ok
end

local function AuraCountdownSetText(fs, text)
	if not fs then
		return
	end
	if not fs._fluxFontReady then
		ApplyAuraCountdownFont(fs, 30)
	end
	if fs._fluxFontReady and fs.SetText then
		pcall(fs.SetText, fs, text or "")
	end
end

-- Same thresholds as SecondsToTimeAbbrev (1.5). BuffFrame uses %d on seconds
-- (truncates); ceil here made the stance digit sit one second behind the aura.
local function FormatAuraRemain(rem)
	if rem < 0 then
		rem = 0
	end
	if rem >= 129600 then
		return tostring(math.ceil(rem / 86400)) .. "d"
	end
	if rem >= 5400 then
		return tostring(math.ceil(rem / 3600)) .. "h"
	end
	if rem >= 90 then
		return tostring(math.ceil(rem / 60)) .. "m"
	end
	return tostring(math.floor(rem + 1e-6))
end

local function AuraRemainSeconds(btn, cd, now)
	-- BuffFrame: (expirationTime - GetTime()) / timeMod, then SecondsToTimeAbbrev.
	local exp = PublicNumber(btn.StanceBuffExpirationTime)
	if exp then
		local rem = exp - now
		local tmod = PublicNumber(btn.StanceBuffTimeMod)
		if tmod and tmod > 0 and tmod ~= 1 then
			rem = rem / tmod
		end
		return rem
	end
	if cd and cd.GetCooldownDisplayDuration then
		local ok, ms = pcall(cd.GetCooldownDisplayDuration, cd)
		if ok then
			local n = PublicNumber(ms)
			if n and n > 0 then
				return n / 1000
			end
		end
	end
	local start = PublicNumber(btn.StanceBuffCooldownStart)
	local dur = PublicNumber(btn.StanceBuffCooldownDuration)
	return (start and dur) and ((start + dur) - now) or 0
end

local function HideBlizzardAuraDigits(cd)
	if not cd then
		return
	end
	if cd.SetHideCountdownNumbers then
		pcall(cd.SetHideCountdownNumbers, cd, true)
	end
	cd.noCooldownCount = true
	cd._fluxHideCountdownNumbers = true
	local fs
	if cd.GetCountdownFontString then
		local ok, result = pcall(cd.GetCountdownFontString, cd)
		if ok then
			fs = result
		end
	end
	if not fs and cd.GetRegions then
		local regions = { cd:GetRegions() }
		for i = 1, #regions do
			local r = regions[i]
			if r and r.GetObjectType and r:GetObjectType() == "FontString" then
				fs = r
				break
			end
		end
	end
	if fs then
		if fs.SetTextColor then
			pcall(fs.SetTextColor, fs, 1, 1, 1, 0)
		end
		if fs.SetAlpha then
			pcall(fs.SetAlpha, fs, 0)
		end
	end
end

function Stance.EnsureAuraCountdown(btn)
	if not btn or not btn.Widget then
		return nil
	end
	if btn._fluxStanceAuraText then
		if not btn._fluxStanceAuraText._fluxFontReady then
			local size = btn.Widget._fluxStanceButtonSize or 30
			ApplyAuraCountdownFont(btn._fluxStanceAuraText, size)
		end
		return btn._fluxStanceAuraText
	end
	local widget = btn.Widget
	-- Parent to UIParent, not the secure extra button (SetText on a secure child taints).
	local holder = CreateFrame("Frame", nil, UIParent)
	holder:SetAllPoints(widget)
	holder:EnableMouse(false)
	if holder.SetUsingParentLevel then
		pcall(holder.SetUsingParentLevel, holder, false)
	end
	if widget.GetFrameStrata and holder.SetFrameStrata then
		pcall(holder.SetFrameStrata, holder, widget:GetFrameStrata() or "MEDIUM")
	end
	local base = widget.GetFrameLevel and widget:GetFrameLevel() or 0
	pcall(holder.SetFrameLevel, holder, base + 26)
	local fs
	local okFS = pcall(function()
		fs = holder:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	end)
	if not okFS or not fs then
		fs = holder:CreateFontString(nil, "OVERLAY")
	end
	fs:SetPoint("CENTER", holder, "CENTER", 0, 0)
	if fs.SetJustifyH then
		fs:SetJustifyH("CENTER")
	end
	if fs.SetJustifyV then
		fs:SetJustifyV("MIDDLE")
	end
	fs:SetTextColor(1, 1, 1, 1)
	if fs.SetShadowColor then
		fs:SetShadowColor(0, 0, 0, 1)
		fs:SetShadowOffset(1, -1)
	end
	local size = widget._fluxStanceButtonSize or (widget.GetWidth and widget:GetWidth()) or 30
	ApplyAuraCountdownFont(fs, size)
	if not fs._fluxFontReady then
		fs._fluxFontReady = true
	end
	pcall(fs.SetText, fs, "")
	holder:Hide()
	btn._fluxStanceAuraHolder = holder
	btn._fluxStanceAuraText = fs
	return fs
end

local function AuraCountdownTick()
	local now = (GetTime and GetTime()) or 0
	local any = false
	for btn in pairs(auraCountdownActive) do
		local fs = btn._fluxStanceAuraText
		local holder = btn._fluxStanceAuraHolder
		local widget = btn.Widget
		local shown = widget and (not widget.IsShown or widget:IsShown())
		local cd = btn.WCooldown or (widget and (widget.cooldown or widget.Cooldown))
		local rem = AuraRemainSeconds(btn, cd, now)
		local hasTimer = PublicNumber(btn.StanceBuffExpirationTime)
			or (PublicNumber(btn.StanceBuffCooldownStart) and PublicNumber(btn.StanceBuffCooldownDuration))
		if not fs or not shown or not ExtraAuraTimerOwned(btn) or not hasTimer or rem <= 0.05 then
			auraCountdownActive[btn] = nil
			AuraCountdownSetText(fs, "")
			if holder then
				holder:Hide()
			end
		else
			any = true
			HideBlizzardAuraDigits(cd)
			AuraCountdownSetText(fs, FormatAuraRemain(rem))
			if holder then
				holder:Show()
			end
		end
	end
	if not any and auraCountdownDriver then
		auraCountdownDriver:SetScript("OnUpdate", nil)
		auraCountdownDriver:Hide()
	end
end

local function EnsureAuraCountdownDriver()
	if not auraCountdownDriver then
		auraCountdownDriver = CreateFrame("Frame")
		auraCountdownDriver:Hide()
	end
	if auraCountdownDriver:GetScript("OnUpdate") then
		return
	end
	auraCountdownDriver:SetScript("OnUpdate", function()
		AuraCountdownTick()
	end)
	auraCountdownDriver:Show()
end

function Stance.SyncAuraCountdown(btn)
	if not btn then
		return
	end
	local widget = btn.Widget
	local cd = btn.WCooldown or (widget and (widget.cooldown or widget.Cooldown))
	local holder = btn._fluxStanceAuraHolder
	local start = PublicNumber(btn.StanceBuffCooldownStart)
	local dur = PublicNumber(btn.StanceBuffCooldownDuration)
	if not ExtraAuraTimerOwned(btn) then
		auraCountdownActive[btn] = nil
		if holder then
			holder:Hide()
		end
		AuraCountdownSetText(btn._fluxStanceAuraText, "")
		if cd then
			cd.noCooldownCount = nil
			cd._fluxHideCountdownNumbers = nil
		end
		return
	end
	HideBlizzardAuraDigits(cd)
	local exp = PublicNumber(btn.StanceBuffExpirationTime)
	if not start or not dur then
		if not exp then
			-- Swipe may still run from a duration object. Digits stay off.
			auraCountdownActive[btn] = nil
			if holder then
				holder:Hide()
			end
			AuraCountdownSetText(btn._fluxStanceAuraText, "")
			return
		end
	end
	local fs = Stance.EnsureAuraCountdown(btn)
	holder = btn._fluxStanceAuraHolder
	if holder and widget and not (InCombatLockdown and InCombatLockdown()) then
		local base = widget.GetFrameLevel and widget:GetFrameLevel() or 0
		holder:SetFrameLevel(base + 26)
	end
	if fs then
		local size = (widget and widget._fluxStanceButtonSize) or (widget and widget.GetWidth and widget:GetWidth()) or 30
		ApplyAuraCountdownFont(fs, size)
	end
	auraCountdownActive[btn] = true
	EnsureAuraCountdownDriver()
	AuraCountdownTick()
end

local function FormArmorIsActive(btn)
	local S = Flux.Shapeshift
	local index = btn and (btn.ShapeshiftIndex or btn.ActionValue)
	if not (S and S.GetFormInfo and index) then
		return false
	end
	local _, isActive = S.GetFormInfo(index)
	local Sec = Flux.Secrets
	if Sec and Sec.SafeBooleanTest then
		return Sec.SafeBooleanTest(isActive, false) and true or false
	end
	return isActive and true or false
end

local lastCustom = {}
local customBuffSeen = {}

local function ItemUseSpell(item)
	if item == nil or item == "" then
		return nil
	end
	if Flux.Item and Flux.Item.GetSpell then
		local _, sid = Flux.Item.GetSpell(item)
		sid = tonumber(sid)
		if sid and sid > 0 then
			return sid
		end
	end
	return nil
end

local function SpellIdFromToken(token)
	if type(token) ~= "string" or token == "" then
		return nil
	end
	local asNum = tonumber(token)
	if asNum and Flux.Spell and Flux.Spell.GetName and Flux.Spell.GetName(asNum) then
		return asNum
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local ok, info = pcall(C_Spell.GetSpellInfo, token)
		if ok and type(info) == "table" then
			local id = tonumber(info.spellID)
			if id and id > 0 then
				return id
			end
		end
	end
	if GetSpellInfo then
		local ok, a, _, _, _, _, _, g = pcall(GetSpellInfo, token)
		if ok then
			if type(g) == "number" and g > 0 then
				return g
			end
			if type(a) == "table" then
				local id = tonumber(a.spellID)
				if id and id > 0 then
					return id
				end
			end
		end
	end
	return nil
end

-- One /cast or /use, no semicolon list. Anything else is just a button.
local function MacroSingleSpell(name)
	if type(name) ~= "string" or name == "" or not (GetMacroIndexByName and GetMacroInfo) then
		return nil
	end
	local idx = GetMacroIndexByName(name)
	if not idx or idx <= 0 then
		return nil
	end
	local _, _, body = GetMacroInfo(idx)
	if type(body) ~= "string" or body == "" then
		return nil
	end
	local found
	for line in body:gmatch("[^\r\n]+") do
		local trimmed = line:match("^%s*(.-)%s*$") or ""
		if trimmed ~= "" and not trimmed:match("^#") then
			local cmd, rest = trimmed:match("^/(%S+)%s*(.*)$")
			if cmd then
				cmd = cmd:lower()
				if cmd == "castrandom" or cmd == "castsequence" then
					return nil
				end
				if cmd == "cast" or cmd == "use" then
					if found then
						return nil
					end
					rest = rest or ""
					if rest:find(";", 1, true) then
						return nil
					end
					rest = rest:gsub("%b[]", "")
					rest = rest:match("^%s*(.-)%s*$") or ""
					if rest == "" then
						return nil
					end
					found = { cmd = cmd, token = rest }
				end
			end
		end
	end
	if not found then
		return nil
	end
	local token = found.token
	local itemId = token:match("item:(%d+)")
	if itemId then
		return ItemUseSpell(tonumber(itemId))
	end
	if found.cmd == "use" and token:match("^%d+$") then
		return ItemUseSpell(tonumber(token))
	end
	local sid = SpellIdFromToken(token)
	if sid then
		return sid
	end
	if found.cmd == "use" then
		return ItemUseSpell(token)
	end
	return nil
end

function Stance.CustomTrackSpell(data, btn)
	if type(data) ~= "table" then
		return nil
	end
	local kind = data.actionType or data.type
	if kind == "spell" then
		return tonumber(data.spellID or data.id or data.actionValue)
	end
	if kind == "item" or kind == "toy" then
		local itemID = data.itemID or data.id or data.actionValue
		if btn and btn.ItemId then
			itemID = itemID or btn.ItemId
		end
		return ItemUseSpell(itemID)
	end
	if kind == "mount" then
		if btn and tonumber(btn.MountSpellId) then
			return tonumber(btn.MountSpellId)
		end
		local mountID = tonumber(data.id or data.actionValue)
		if mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
			local ok, _, spellID = pcall(C_MountJournal.GetMountInfoByID, mountID)
			if ok then
				return tonumber(spellID)
			end
		end
		return nil
	end
	if kind == "macro" then
		return MacroSingleSpell(data.name or data.id)
	end
	return nil
end

function Stance.IsTrackedCustomSpell(spellId)
	spellId = tonumber(spellId)
	if not spellId then
		return false
	end
	local entries = Stance.GetCustomEntries and Stance.GetCustomEntries() or {}
	for i = 1, #entries do
		local sid = Stance.CustomTrackSpell(entries[i])
		if sid and IdsMatch(sid, spellId) then
			return true
		end
	end
	if Stance.ForEachPooled then
		local hit = false
		Stance.ForEachPooled(function(btn)
			if hit or not btn or not btn.spellData or not btn.spellData.custom then
				return
			end
			local sid = Stance.CustomTrackSpell(btn.spellData, btn)
			if sid and IdsMatch(sid, spellId) then
				hit = true
			end
		end)
		if hit then
			return true
		end
	end
	return false
end

local function TryCustomAura(spellId)
	local function One(id)
		if not id then
			return nil
		end
		local raw = AuraFromSpellId(id)
		if not raw then
			return nil
		end
		local exp = PublicNumber(raw.expirationTime)
		local now = (GetTime and GetTime()) or 0
		if exp and exp > 0.05 and exp <= (now + 0.05) then
			return nil
		end
		local hit = NormalizeArmor(raw)
		if hit then
			return hit
		end
		-- Duration 0 / no expiration is still up (activate/deactivate buff).
		return {
			name = raw.name,
			spellID = raw.spellID or id,
			present = true,
			permanent = true,
			auraInstanceID = PublicNumber(raw.auraInstanceID),
		}
	end
	return One(spellId) or One(CooldownAuraId(spellId))
end

local function GetActiveCustomAura(spellId)
	spellId = tonumber(spellId)
	if not spellId then
		return nil
	end
	local hit = TryCustomAura(spellId)
	if hit then
		if not AurasRestricted() then
			customBuffSeen[spellId] = true
		end
		local merged = MergeHeld(hit, lastCustom[spellId])
		merged.permanent = hit.permanent and true or nil
		merged.fresh = true
		lastCustom[spellId] = merged
		return merged
	end
	local held = lastCustom[spellId]
	if not held then
		return nil
	end
	local still = RefreshHeldDuration(held)
	if still == true then
		held.fresh = nil
		return held
	end
	if still == false and not AurasRestricted() then
		lastCustom[spellId] = nil
		return nil
	end
	if AurasRestricted() then
		local exp = PublicNumber(held.expirationTime)
		local now = (GetTime and GetTime()) or 0
		if exp and exp <= (now + 0.05) then
			lastCustom[spellId] = nil
			return nil
		end
		if ArmorStillTimed(held) or held.present then
			held.fresh = nil
			return held
		end
	end
	lastCustom[spellId] = nil
	return nil
end

function Stance.NoteCustomCast(spellId)
	spellId = tonumber(spellId)
	if not spellId or not Stance.IsTrackedCustomSpell(spellId) then
		return false
	end
	local hit = TryCustomAura(spellId)
	if hit then
		if not AurasRestricted() then
			customBuffSeen[spellId] = true
		end
		local merged = MergeHeld(hit, lastCustom[spellId])
		merged.permanent = hit.permanent and true or nil
		merged.fresh = true
		lastCustom[spellId] = merged
		return true
	end
	if AurasRestricted() and (customBuffSeen[spellId] or lastCustom[spellId]) then
		local prev = lastCustom[spellId] or { spellID = spellId, present = true }
		prev.present = true
		prev.fresh = nil
		prev.spellID = prev.spellID or spellId
		lastCustom[spellId] = prev
		return true
	end
	return false
end

function Stance.CustomAuraPollSignature()
	if not Stance.ForEachPooled then
		return ""
	end
	local parts = {}
	Stance.ForEachPooled(function(btn)
		local data = btn and btn.spellData
		if not data or not data.custom then
			return
		end
		local sid = Stance.CustomTrackSpell(data, btn)
		if not sid then
			return
		end
		local active = GetActiveCustomAura(sid)
		if active then
			local exp = PublicNumber(active.expirationTime)
			parts[#parts + 1] = tostring(sid) .. ":" .. tostring(exp or "live")
		elseif Flux.Spell and Flux.Spell.IsCurrent and Flux.Spell.IsCurrent(sid) then
			parts[#parts + 1] = tostring(sid) .. ":on"
		end
	end)
	table.sort(parts)
	return table.concat(parts, "|")
end

function Stance.ApplyExtraActiveVisual(btn)
	if not btn then
		return
	end
	local data = btn.spellData
	local formArmor = btn._fluxStanceMageArmorForm and true or false
	if not data and not formArmor then
		btn.IconOverrideTexture = nil
		btn.StanceActiveVisual = nil
		btn.FluxStanceManagedCooldown = nil
		btn.StanceBuffCooldownStart = nil
		btn.StanceBuffCooldownDuration = nil
		btn.StanceBuffDurationObject = nil
		btn.StanceBuffExpirationTime = nil
		btn.StanceBuffTimeMod = nil
		Stance.SyncAuraCountdown(btn)
		return
	end
	local showWisp = false
	local buffStart, buffDuration, durationObject, buffExp, buffMod
	local wispSpell = (data and data.spellID) or btn.SpellId
	local isArmor = formArmor or (data and data.isMageArmor)
	if isArmor then
		local armorData = data or {
			isMageArmor = true,
			spellID = btn.SpellId,
		}
		local active = ActiveMageArmorForVisual()
		local matched = ArmorMatchesExtra(active, armorData)
		if not matched and formArmor and FormArmorIsActive(btn) then
			matched = true
		end
		if not matched and isArmor and armorData.spellID then
			local Sh = Flux.Shapeshift
			if Sh and Sh.MatchesActiveForm and Sh.MatchesActiveForm(armorData.spellID) then
				matched = true
			end
		end
		if matched then
			showWisp = true
			if active then
				buffStart, buffDuration = ArmorCooldownTimes(active)
				durationObject = active.durationObject
				buffExp = PublicNumber(active.expirationTime)
				buffMod = PublicNumber(active.timeMod)
			end
		end
	elseif data and data.custom then
		-- Wisp only while this spell's buff is up. A cast by itself keeps the spell icon.
		local trackSpell = Stance.CustomTrackSpell and Stance.CustomTrackSpell(data, btn)
		local casting = trackSpell and PlayerIsCastingSpell(trackSpell)
		local active = trackSpell and GetActiveCustomAura(trackSpell)
		if active and active.permanent and not active.fresh and trackSpell
			and Flux.Spell and Flux.Spell.IsCurrent and not Flux.Spell.IsCurrent(trackSpell) then
			active = nil
		end
		-- A cast can look current before the aura exists. That is not a buff.
		if casting and active and active.permanent and not active.fresh then
			active = nil
		end
		if active then
			showWisp = true
			wispSpell = trackSpell or wispSpell
			if not active.permanent then
				buffStart, buffDuration = ArmorCooldownTimes(active)
				durationObject = active.durationObject
				buffExp = PublicNumber(active.expirationTime)
				buffMod = PublicNumber(active.timeMod)
			end
		end
	else
		local petSpell = Stance.GetActivePetSpell and Stance.GetActivePetSpell()
		local n = ExtraName(data)
		if petSpell and n then
			if petSpell == n or petSpell == data.spellName or petSpell == data.name then
				showWisp = true
			elseif n:find(petSpell, 1, true) or petSpell:find(n, 1, true) then
				showWisp = true
			end
		end
	end
	if data and data.custom then
		if showWisp then
			btn.IconOverrideTexture = ArmorWispTexture(wispSpell)
			btn.StanceActiveVisual = true
		else
			btn.IconOverrideTexture = CustomRestingIcon(data, btn)
			btn.StanceActiveVisual = nil
		end
	elseif showWisp then
		btn.IconOverrideTexture = ArmorWispTexture(wispSpell)
		btn.StanceActiveVisual = true
	else
		btn.IconOverrideTexture = nil
		btn.StanceActiveVisual = nil
	end
	if durationObject or (buffStart and buffDuration) then
		btn.FluxStanceManagedCooldown = true
		btn.StanceBuffCooldownStart = buffStart
		btn.StanceBuffCooldownDuration = buffDuration
		btn.StanceBuffDurationObject = durationObject
		btn.StanceBuffExpirationTime = buffExp
		btn.StanceBuffTimeMod = buffMod
	elseif showWisp and AurasRestricted() and btn.FluxStanceManagedCooldown then
		-- Combat lookup is secret, not expired. Keep the running swipe.
	else
		btn.FluxStanceManagedCooldown = nil
		btn.StanceBuffCooldownStart = nil
		btn.StanceBuffCooldownDuration = nil
		btn.StanceBuffDurationObject = nil
		btn.StanceBuffExpirationTime = nil
		btn.StanceBuffTimeMod = nil
	end
	Stance.SyncAuraCountdown(btn)
end

local function BookSpellID(index, bookType)
	if not GetSpellBookItemInfo then
		return nil
	end
	local a, b = GetSpellBookItemInfo(index, bookType)
	if type(a) == "table" then
		return a.spellID or a.actionID
	end
	return b
end

local function IsSummonDemonFlyout(flyoutID, flyoutName)
	if type(flyoutName) == "string" and flyoutName:find("Summon Demon", 1, true) then
		return true
	end
	local S = Flux.Spell
	if S and S.FlyoutHasSpell then
		for i = 1, #WARLOCK_SUMMON_IDS do
			if S.FlyoutHasSpell(flyoutID, WARLOCK_SUMMON_IDS[i][2]) then
				return true
			end
		end
	end
	if S and S.GetFlyoutInfo and S.GetFlyoutSlotInfo then
		local _, _, numSlots = S.GetFlyoutInfo(flyoutID)
		for i = 1, (numSlots or 0) do
			local _, _, _, slotName = S.GetFlyoutSlotInfo(flyoutID, i)
			slotName = AsName(slotName)
			if slotName and PET_SUMMON[slotName] then
				return true
			end
		end
	end
	return false
end

local function ExpandSummonDemonFlyout(list, flyoutID, seen)
	if not flyoutID then
		return false
	end
	local S = Flux.Spell
	if not (S and S.GetFlyoutInfo and S.GetFlyoutSlotInfo and S.FlyoutSlotCastID) then
		return false
	end
	local flyoutName, _, numSlots, known = S.GetFlyoutInfo(flyoutID)
	if known == false then
		return false
	end
	if not IsSummonDemonFlyout(flyoutID, flyoutName) then
		return false
	end
	seen = seen or {}
	local added = 0
	for slotIndex = 1, (numSlots or 0) do
		local _, _, isKnown, slotName = S.GetFlyoutSlotInfo(flyoutID, slotIndex)
		local sid = S.FlyoutSlotCastID(flyoutID, slotIndex)
		if isKnown ~= false and sid then
			slotName = AsName(slotName) or SpellName(sid)
			if not seen[sid] and not (slotName and seen[slotName]) then
				seen[sid] = true
				if slotName then
					seen[slotName] = true
				end
				local before = #list
				AddExtra(list, slotName, sid, SpellIcon(sid))
				if #list > before then
					added = added + 1
				end
			end
		end
	end
	return added > 0
end

local function ScanClassicBook(list, class, seen)
	if not (GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName) then
		return false
	end
	local bookType = BOOKTYPE_SPELL or "spell"
	local tabs = GetNumSpellTabs() or 0
	local foundFlyout = false
	seen = seen or {}
	local pending = {}
	local foundArmors = {}
	local iceKnown = false
	for tab = 1, tabs do
		local _, _, offset, num = GetSpellTabInfo(tab)
		for i = 1, (num or 0) do
			local index = offset + i
			local sName = AsName(GetSpellBookItemName(index, bookType))
			local itemKind, itemID
			if GetSpellBookItemInfo then
				local a, b = GetSpellBookItemInfo(index, bookType)
				if type(a) == "table" then
					local info = a
					local t = info.itemType
					if Enum and Enum.SpellBookItemType then
						if t == Enum.SpellBookItemType.Flyout then
							itemKind, itemID = "flyout", info.actionID
						elseif t == Enum.SpellBookItemType.Spell or t == Enum.SpellBookItemType.FutureSpell then
							itemKind, itemID = "spell", info.spellID or info.actionID
						end
					elseif type(t) == "string" then
						local lower = t:lower()
						if lower == "flyout" then
							itemKind, itemID = "flyout", info.actionID
						elseif lower == "spell" or lower == "futurespell" then
							itemKind, itemID = "spell", info.spellID or info.actionID
						end
					end
					sName = sName or AsName(info.name)
				elseif a ~= nil then
					itemKind = tostring(a):lower()
					itemID = b
				end
			end
			if class == "WARLOCK" then
				if itemKind == "flyout" and ExpandSummonDemonFlyout(list, itemID, seen) then
					foundFlyout = true
				elseif sName and PET_SUMMON[sName] then
					pending[#pending + 1] = { name = sName, spellID = itemID or BookSpellID(index, bookType) }
				end
			end
			if class == "MAGE" and sName then
				for a = 1, #ARMORS do
					if sName:find(ARMORS[a], 1, true) then
						foundArmors[ARMORS[a]] = BookSpellID(index, bookType) or itemID
						if ARMORS[a] == "Ice Armor" then
							iceKnown = true
						end
					end
				end
			end
		end
	end
	if class == "WARLOCK" and not foundFlyout then
		for i = 1, #pending do
			AddExtra(list, pending[i].name, pending[i].spellID, SpellIcon(pending[i].spellID))
		end
	end
	if class == "MAGE" then
		for a = 1, #ARMORS do
			local sid = foundArmors[ARMORS[a]]
			if sid and not (ARMORS[a] == "Frost Armor" and iceKnown) then
				AddExtra(list, ARMORS[a], sid, SpellIcon(sid), { isMageArmor = true })
			end
		end
	end
	return foundFlyout
end

function Stance.GetAvailableSpells()
	local class = select(2, UnitClass("player"))
	if cached and cachedClass == class then
		return cached
	end
	mageArmorIds = {}
	local list = {}

	if class == "MAGE" and SpellKnown(31687) then
		AddExtra(list, "Summon Water Elemental", 31687, SpellIcon(31687) or "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2")
	end

	if class == "WARLOCK" then
		local seen = {}
		local foundFlyout = false
		if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and Enum and Enum.SpellBookSpellBank then
			local bank = Enum.SpellBookSpellBank.Player
			local nLines = C_SpellBook.GetNumSpellBookSkillLines() or 0
			local pending = {}
			for line = 1, nLines do
				local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
				if info then
					local offset = info.itemIndexOffset or 0
					local count = info.numSpellBookItems or 0
					for slot = offset + 1, offset + count do
						local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
						if item then
							if item.itemType == Enum.SpellBookItemType.Flyout and item.actionID then
								if ExpandSummonDemonFlyout(list, item.actionID, seen) then
									foundFlyout = true
								end
							elseif (item.itemType == Enum.SpellBookItemType.Spell
								or item.itemType == Enum.SpellBookItemType.FutureSpell)
								and item.name and PET_SUMMON[item.name] then
								pending[#pending + 1] = item
							end
						end
					end
				end
			end
			if not foundFlyout then
				for i = 1, #pending do
					local item = pending[i]
					local sid = item.spellID or item.actionID
					AddExtra(list, item.name, sid, item.iconID or SpellIcon(sid))
				end
			end
		end
		if not foundFlyout then
			if ScanClassicBook(list, class, seen) then
				foundFlyout = true
			end
		end
		if not foundFlyout then
			for i = 1, #WARLOCK_SUMMON_IDS do
				local name, sid = WARLOCK_SUMMON_IDS[i][1], WARLOCK_SUMMON_IDS[i][2]
				if SpellKnown(sid) then
					AddExtra(list, name, sid, SpellIcon(sid))
				end
			end
		end
	end

	if class == "MAGE" then
		ScanClassicBook(list, class)
		if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and Enum and Enum.SpellBookSpellBank then
			local bank = Enum.SpellBookSpellBank.Player
			local nLines = C_SpellBook.GetNumSpellBookSkillLines() or 0
			local iceKnown = false
			local found = {}
			for line = 1, nLines do
				local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
				if info then
					local offset = info.itemIndexOffset or 0
					local count = info.numSpellBookItems or 0
					for slot = offset + 1, offset + count do
						local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
						local sName = item and AsName(item.name)
						if sName then
							for a = 1, #ARMORS do
								if sName:find(ARMORS[a], 1, true) then
									found[ARMORS[a]] = item.spellID or item.actionID
									if ARMORS[a] == "Ice Armor" then
										iceKnown = true
									end
								end
							end
						end
					end
				end
			end
			for a = 1, #ARMORS do
				local sid = found[ARMORS[a]]
				if sid and not (ARMORS[a] == "Frost Armor" and iceKnown) then
					AddExtra(list, ARMORS[a], sid, SpellIcon(sid), { isMageArmor = true })
				end
			end
		end
		local iceKnown = PlayerKnowsIceArmor()
		for i = 1, #MAGE_ARMOR_FALLBACK do
			local name, sid = MAGE_ARMOR_FALLBACK[i][1], MAGE_ARMOR_FALLBACK[i][2]
			if SpellKnown(sid) and not (name == "Frost Armor" and iceKnown) then
				AddExtra(list, name, sid, SpellIcon(sid), { isMageArmor = true })
			end
		end
		PruneFrostIfIceKnown(list)
	end

	cached = list
	cachedClass = class
	return list
end

function Stance.ShouldShowExtra(data, numForms)
	if not data then
		return false
	end
	local name = data.name or data.spellName
	local sid = data.spellID
	local function SameSpell(a, b)
		if a == nil or b == nil then
			return false
		end
		if Flux.Secrets and Flux.Secrets.SafeEqualForCache then
			return Flux.Secrets.SafeEqualForCache(a, b)
		end
		return a == b
	end
	local S = Flux.Shapeshift
	if S and S.GetFormInfo then
		for i = 1, (numForms or 0) do
			local _, _, _, formSid = S.GetFormInfo(i)
			if SameSpell(formSid, sid) then
				return false
			end
			if formSid then
				local fn = SpellName(formSid)
				if fn and name and fn == name then
					return false
				end
			end
		end
	end
	return true
end

function Stance.ShouldShowCustom(data, numForms, extras)
	if not data or not data.custom then
		return false
	end
	local sid = Stance.CustomTrackSpell and Stance.CustomTrackSpell(data)
	local spellName = (data.actionType == "spell") and (data.name or data.spellName) or nil
	if (sid or spellName) and Stance.BuiltinHasSpell and Stance.BuiltinHasSpell(sid, spellName) then
		return false
	end
	if type(extras) == "table" and sid then
		for i = 1, #extras do
			local extra = extras[i]
			if extra and IdsMatch(extra.spellID, sid) then
				return false
			end
			local n = extra and (extra.name or extra.spellName)
			if spellName and n and n == spellName then
				return false
			end
		end
	end
	return true
end
