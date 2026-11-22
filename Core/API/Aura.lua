-- Aura.lua — C_UnitAuras vs UnitAura (UnitAura is gone on Midnight)
local addonName, ns = ...
local Flux = ns.Flux

local Aura = {}
Flux.Aura = Aura
Flux.API = Flux.API or {}
Flux.API.Aura = Aura

local Cap = Flux.Cap

local dispelTypes = {
	magic = "Magic",
	curse = "Curse",
	disease = "Disease",
	poison = "Poison",
	bleed = "Bleed",
	enrage = "Enrage",
}
local dispelIcons = {
	Magic = "RaidFrame-Icon-DebuffMagic",
	Curse = "RaidFrame-Icon-DebuffCurse",
	Disease = "RaidFrame-Icon-DebuffDisease",
	Poison = "RaidFrame-Icon-DebuffPoison",
	Bleed = "RaidFrame-Icon-DebuffBleed",
}
local dispelIconFiles = {
	Magic = "Interface\\Icons\\Spell_Holy_DispelMagic",
	Curse = "Interface\\Icons\\Spell_Shadow_CurseOfTounges",
	Disease = "Interface\\Icons\\Spell_Nature_NullifyDisease",
	Poison = "Interface\\Icons\\Spell_Nature_NullifyPoison",
	Bleed = "Interface\\Icons\\Ability_Druid_Rake",
	Enrage = "Interface\\Icons\\Ability_Druid_ChallangingRoar",
}
local availableDispelAtlases = {}
local paintedDispelIcons = setmetatable({}, { __mode = "k" })
local fallbackDispelColors = {
	Magic = { .2, .6, 1 },
	Curse = { .6, 0, 1 },
	Disease = { .65, .42, 0 },
	Poison = { 0, .6, 0 },
	Bleed = { .85, .16, .2 },
	Enrage = { .95, .3, .22 },
}

local function CanRead(value)
	if value == nil then return false end
	if issecretvalue and issecretvalue(value) then return false end
	return not canaccessvalue or canaccessvalue(value)
end

function Aura.NormalizeDispelType(value)
	if CanRead(value) and type(value) == "string" then return dispelTypes[value:lower()] end
end

function Aura.GetDispelTypeColor(value)
	local kind = Aura.NormalizeDispelType(value)
	if not kind then return end
	local color = DebuffTypeColor and DebuffTypeColor[kind]
	if color and type(color.r) == "number" and type(color.g) == "number" and type(color.b) == "number" then
		return color.r, color.g, color.b
	end
	local fallback = fallbackDispelColors[kind]
	return fallback[1], fallback[2], fallback[3]
end

function Aura.LayoutDispelTypeIcon(texture, anchor, iconSize)
	local size = CanRead(iconSize) and type(iconSize) == "number" and iconSize >= 1 and iconSize or 18
	local side = math.max(size >= 18 and 8 or 5, math.floor(size * .38 + .5))
	texture:ClearAllPoints()
	texture:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 1, 1)
	texture:SetSize(side, side)
end

function Aura.CreateDispelTypeIcon(anchor, parent, iconSize)
	local texture = (parent or anchor):CreateTexture(nil, "OVERLAY", nil, 3)
	Aura.LayoutDispelTypeIcon(texture, anchor, iconSize)
	texture:Hide()
	return texture
end

function Aura.CreateDispelTypeBorder(anchor, parent)
	local texture = (parent or anchor):CreateTexture(nil, "OVERLAY", nil, 2)
	texture:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
	texture:SetTexCoord(.296875, .5703125, 0, .515625)
	texture:SetAllPoints(anchor)
	texture:Hide()
	return texture
end

local NAMEPLATE_MEDIA = [[Interface\AddOns\_FluxUI\Texture\NameplateAuras\]]
local NAMEPLATE_COLORS = {
	Buff = { .80, .60, .34 },
	None = { .95, .32, .28 },
	Magic = { .38, .65, 1 },
	Curse = { .76, .42, 1 },
	Disease = { .92, .70, .30 },
	Poison = { .45, .85, .38 },
}

function Aura.GetNameplateAuraColor(kind)
	local color = NAMEPLATE_COLORS[kind] or NAMEPLATE_COLORS.None
	return color[1], color[2], color[3]
end

function Aura.CreateNameplateAuraBorder(anchor)
	local border = anchor:CreateTexture(nil, "OVERLAY", nil, 1)
	border:SetTexture(NAMEPLATE_MEDIA .. "IconBorder.tga")
	border:SetAllPoints(anchor)
	return border
end

function Aura.CreateNameplateAuraArt(anchor)
	local image = anchor:CreateTexture(nil, "ARTWORK")
	image:SetTexCoord(.08, .92, .08, .92)
	local background = anchor:CreateTexture(nil, "BACKGROUND")
	background:SetColorTexture(0, 0, 0, 1)
	background:SetAllPoints(image)
	if anchor.CreateMaskTexture and image.AddMaskTexture then
		local mask = anchor:CreateMaskTexture()
		mask:SetTexture(NAMEPLATE_MEDIA .. "IconMask.tga", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		mask:SetAllPoints(anchor)
		image:AddMaskTexture(mask)
		background:AddMaskTexture(mask)
	end
	return image, background
end

function Aura.LayoutNameplateAuraArt(image, anchor, size)
	local inset = size * 6 / 128
	image:ClearAllPoints()
	image:SetPoint("TOPLEFT", anchor, "TOPLEFT", inset, -inset)
	image:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -inset, inset)
end

function Aura.StyleNameplateAuraCooldown(cooldown)
	cooldown:SetReverse(true)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawBling(false)
	if cooldown.SetUseCircularEdge then cooldown:SetUseCircularEdge(false) end
	cooldown:SetDrawSwipe(true)
	cooldown:SetSwipeTexture(NAMEPLATE_MEDIA .. "IconMask.tga")
	cooldown:SetSwipeColor(0, 0, 0, .7)
	cooldown:SetDrawEdge(true)
	cooldown:SetEdgeTexture(NAMEPLATE_MEDIA .. "Edge.tga", 1, 1, 1, 1)
	if cooldown.SetEdgeScale then cooldown:SetEdgeScale(1.6) end
end

function Aura.SetDispelTypeIcon(texture, value)
	local kind = Aura.NormalizeDispelType(value)
	if not kind then
		texture:Hide()
		return false
	end
	local atlas = dispelIcons[kind]
	if atlas and texture.SetAtlas and availableDispelAtlases[atlas] == nil then
		local lookup = (C_Texture and C_Texture.GetAtlasInfo) or GetAtlasInfo
		availableDispelAtlases[atlas] = not lookup or not not lookup(atlas)
	end
	local useAtlas = atlas and texture.SetAtlas and availableDispelAtlases[atlas]
	local art = useAtlas and atlas or dispelIconFiles[kind]
	if paintedDispelIcons[texture] ~= art then
		if useAtlas then texture:SetAtlas(art, false) else texture:SetTexture(art) end
		paintedDispelIcons[texture] = art
	end
	texture:Show()
	return true
end

-- The button owns aura classification and visibility for secure bindings.
function Aura.BindDispelTypeIcon(button, texture)
	local styles = Enum and Enum.CustomAuraButtonDispelTypeTextureStyle
	if not (styles and styles.Icon ~= nil and button.AddDispelTypeTexture) then return false end
	local ok, accepted = pcall(button.AddDispelTypeTexture, button, texture, {
		style = styles.Icon,
		showWhenHarmful = true,
		showWhenHelpful = false,
		showWithoutDispelType = false,
	})
	return ok and accepted ~= false
end

local function SecretsAccessible()
	local S = Flux.Secrets
	if S and S.CanAccessSecrets and not S.CanAccessSecrets() then
		return false
	end
	return true
end

function Aura.GetSlots(unit, filter)
	if not unit then
		return {}, true
	end
	if not SecretsAccessible() then
		return nil, false
	end
	if not Cap.hasC_UnitAuras_GetAuraSlots then
		return {}, true
	end
	local packed = { pcall(C_UnitAuras.GetAuraSlots, unit, filter) }
	if not packed[1] then
		return nil, false
	end
	if type(packed[2]) == "table" then
		local S = Flux.Secrets
		if S and ((S.IsSecretTable and S.IsSecretTable(packed[2])) or (S.CanAccessTable and not S.CanAccessTable(packed[2]))) then
			return nil, false
		end
		return packed[2], true
	end
	-- continuationToken, slot, slot, ...
	local slots = {}
	for i = 3, #packed do
		slots[#slots + 1] = packed[i]
	end
	return slots, true
end

function Aura.GetDataBySlot(unit, slot)
	if not unit then
		return nil
	end
	if not SecretsAccessible() then
		return nil
	end
	if Cap.hasC_UnitAuras_GetAuraDataBySlot then
		local ok, data = pcall(C_UnitAuras.GetAuraDataBySlot, unit, slot)
		if ok then
			return data
		end
		return nil
	end
	return nil
end

function Aura.GetDataByIndex(unit, index, filter)
	if not unit then
		return nil
	end
	if not SecretsAccessible() then
		return nil
	end
	if Cap.hasC_UnitAuras_GetAuraDataByIndex then
		local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
		if ok then
			return data
		end
		return nil
	end
	-- UnitAura was removed on Midnight (12.0+); only use when still present.
	if not UnitAura then
		return nil
	end
	local ok, name, icon, count, dispelType, duration, expirationTime, source, isStealable,
		nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod =
		pcall(UnitAura, unit, index, filter)
	if not ok or not name then
		return nil
	end
	return {
		name = name,
		icon = icon,
		applications = count,
		dispelName = dispelType,
		duration = duration,
		expirationTime = expirationTime,
		sourceUnit = source,
		isStealable = isStealable,
		nameplateShowPersonal = nameplateShowPersonal,
		spellId = spellId,
		canApplyAura = canApplyAura,
		isBossAura = isBossDebuff,
		isFromPlayerOrPlayerPet = castByPlayer,
		nameplateShowAll = nameplateShowAll,
		timeMod = timeMod,
	}
end

function Aura.GetDataByInstanceID(unit, auraInstanceID)
	if not unit or not Cap.hasC_UnitAuras_GetAuraDataByAuraInstanceID then
		return nil
	end
	if not SecretsAccessible() then
		return nil
	end
	local ok, data = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, unit, auraInstanceID)
	if ok then
		return data
	end
	return nil
end

-- AllowedWhenTainted + RequiresNonSecretAura: returns nil instead of a secret
-- table. Do not gate on CanAccessSecrets (that is the tainted combat default).
function Aura.GetPlayerAuraBySpellID(spellId)
	spellId = tonumber(spellId)
	if not spellId then
		return nil
	end
	if Cap.hasC_UnitAuras_GetPlayerAuraBySpellID or (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
		local ok, data = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellId)
		if ok then
			return data
		end
	end
	return nil
end

-- Maps a cast/spell id to the self-buff used for an action-button aura swipe.
function Aura.GetCooldownAuraBySpellID(spellId)
	spellId = tonumber(spellId)
	if not spellId then
		return nil
	end
	if Cap.hasC_UnitAuras_GetCooldownAuraBySpellID or (C_UnitAuras and C_UnitAuras.GetCooldownAuraBySpellID) then
		local ok, id = pcall(C_UnitAuras.GetCooldownAuraBySpellID, spellId)
		if not ok or id == nil then
			return nil
		end
		local n = tonumber(id)
		if n and n ~= 0 then
			return n
		end
	end
	return nil
end

-- LuaDurationObject for SetCooldownFromDurationObject. Instance id must be a
-- public number; secret ids cannot be passed while tainted.
function Aura.GetAuraDuration(unit, auraInstanceID)
	if not unit or auraInstanceID == nil then
		return nil
	end
	local S = Flux.Secrets
	if S and S.IsSecretValue and S.IsSecretValue(auraInstanceID) then
		return nil
	end
	if S and S.CanAccessValue and not S.CanAccessValue(auraInstanceID) then
		return nil
	end
	if Cap.hasC_UnitAuras_GetAuraDuration or (C_UnitAuras and C_UnitAuras.GetAuraDuration) then
		local ok, duration = pcall(C_UnitAuras.GetAuraDuration, unit, auraInstanceID)
		if ok then
			return duration
		end
	end
	return nil
end

-- Display wrappers. Do not branch combat decisions on these values on Midnight.
function Aura.UnitHealth(unit)
	return UnitHealth(unit)
end

function Aura.UnitHealthMax(unit)
	return UnitHealthMax(unit)
end

function Aura.UnitPower(unit, powerType)
	return UnitPower(unit, powerType)
end

function Aura.UnitPowerMax(unit, powerType)
	return UnitPowerMax(unit, powerType)
end
