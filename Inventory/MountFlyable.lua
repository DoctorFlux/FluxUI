-- Inventory/MountFlyable.lua — flyable vs ground for bag mount items.
-- Journal clients bake [nomod,flyable] into macros. Era/TBC bag items cannot:
-- they store item IDs, so Lua must decide flying vs ground.
-- Backup FluxInv_Spells used IsFlyableArea() and never preferred flying when
-- that API (and the [flyable] macro option) is missing. Here: use IsFlyableArea
-- when present; otherwise Outland + outdoors + riding skill, never in instances.

local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory

local Flyable = {}
Inv.Flyable = Flyable

local wipe = wipe or function(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

local OUTLAND_INSTANCE_ID = 530
local NORTHREND_INSTANCE_ID = 571
local EASTERN_KINGDOMS_INSTANCE_ID = 0
local KALIMDOR_INSTANCE_ID = 1
local OUTLAND_UIMAP_ID = 101
local NORTHREND_UIMAP_ID = 113

local OUTLAND_INSTANCE_IDS = {
	[OUTLAND_INSTANCE_ID] = true,
}
local NORTHREND_INSTANCE_IDS = {
	[NORTHREND_INSTANCE_ID] = true,
}
local OPEN_WORLD_INSTANCE_IDS = {
	[EASTERN_KINGDOMS_INSTANCE_ID] = true,
	[KALIMDOR_INSTANCE_ID] = true,
	[OUTLAND_INSTANCE_ID] = true,
	[NORTHREND_INSTANCE_ID] = true,
}
local OUTLAND_UIMAP_IDS = {
	[OUTLAND_UIMAP_ID] = true,
}
local NORTHREND_UIMAP_IDS = {
	[NORTHREND_UIMAP_ID] = true,
}
local RESTRICTED_INSTANCE_TYPES = {
	pvp = true,
	arena = true,
	party = true,
	raid = true,
	scenario = true,
}

-- Long names only (no "nagrand" / "dalaran").
local OUTLAND_ZONE_NAMES = {
	["outland"] = true,
	["hellfire peninsula"] = true,
	["zangarmarsh"] = true,
	["terokkar forest"] = true,
	["blade's edge mountains"] = true,
	["netherstorm"] = true,
	["shadowmoon valley"] = true,
	["shattrath city"] = true,
}
local NORTHREND_ZONE_NAMES = {
	["northrend"] = true,
	["borean tundra"] = true,
	["howling fjord"] = true,
	["dragonblight"] = true,
	["grizzly hills"] = true,
	["zul'drak"] = true,
	["sholazar basin"] = true,
	["crystalsong forest"] = true,
	["the storm peaks"] = true,
	["icecrown"] = true,
	["wintergrasp"] = true,
}

local FLYING_SKILL_SPELLS = { 90265, 34091, 34090 } -- Master / Artisan / Expert Riding
local COLD_WEATHER_FLYING_SPELL = 54197

local MOUNT_TRAIT_CACHE_EXPIRY = 60
local mountTraitCache = {}
local mountItemSettleUntil = 0
local mountItemSettleStartedAt = 0
local mountItemLastLocationKey = nil
local mountItemStablePolls = 0
local MOUNT_ITEM_SETTLE_MIN_SEC = 0.25
local MOUNT_ITEM_SETTLE_STABLE_POLLS = 2

local function ClientFlags()
	local Client = Flux.Client
	if Client then
		return Client
	end
	return _G.FLUX_API
end

local function IsEraClient()
	local api = ClientFlags()
	if api then
		if api.isEra or api.isClassicEra then
			return true
		end
		if api.isTBC or api.isWrath or api.isCata or api.isMists or api.isRetail then
			return false
		end
	end
	return (api and (api.majorVersion or 0) or 0) == 1
end

local function IsTBCClient()
	local api = ClientFlags()
	if api and api.isTBC then
		return true
	end
	return false
end

local function SpellKnown(spellID)
	spellID = tonumber(spellID)
	if not spellID then
		return false
	end
	if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
		local ok, known = pcall(C_SpellBook.IsSpellInSpellBook, spellID)
		if ok and known then
			return true
		end
	end
	if IsPlayerSpell and IsPlayerSpell(spellID) then
		return true
	end
	if IsSpellKnown and IsSpellKnown(spellID) then
		return true
	end
	return false
end

local function HasSpellProbe()
	return (C_SpellBook and C_SpellBook.IsSpellInSpellBook) or IsPlayerSpell or IsSpellKnown
end

local function PlayerHasFlyingSkill()
	if IsEraClient() then
		return false
	end
	if not HasSpellProbe() then
		return true
	end
	for i = 1, #FLYING_SKILL_SPELLS do
		if SpellKnown(FLYING_SKILL_SPELLS[i]) then
			return true
		end
	end
	return false
end

local function PlayerHasColdWeatherFlying()
	if not HasSpellProbe() then
		return true
	end
	return SpellKnown(COLD_WEATHER_FLYING_SPELL)
end

local function ZoneBlobLower()
	local zoneText = (GetZoneText and GetZoneText()) or ""
	local realZone = (GetRealZoneText and GetRealZoneText()) or ""
	return (zoneText .. " " .. realZone):lower()
end

local function IsWintergraspZone()
	return ZoneBlobLower():find("wintergrasp", 1, true) ~= nil
end

function Flyable.HasIsFlyableAreaAPI()
	local Cap = Flux.Cap
	if Cap and Cap.hasIsFlyableArea ~= nil then
		return Cap.hasIsFlyableArea and true or false
	end
	return type(IsFlyableArea) == "function"
end

--- [flyable] / [noflyable] exist from Wrath 3.0.2. Era and TBC Anniversary do not.
function Flyable.HasFlyableMacroCondition()
	local Cap = Flux.Cap
	if Cap and Cap.hasFlyableMacro ~= nil then
		return Cap.hasFlyableMacro and true or false
	end
	local api = ClientFlags()
	if api then
		if api.isEra or api.isClassicEra or api.isTBC then
			return false
		end
		if api.isRetail or api.isMists or api.isCata or api.isWrath then
			return true
		end
		if (api.majorVersion or 0) >= 3 then
			return true
		end
	end
	return false
end

function Flyable.GetCurrentInstanceMapID()
	if GetInstanceInfo then
		local mapID = tonumber((select(8, GetInstanceInfo())))
		if mapID and mapID > 0 then
			return mapID
		end
	end
	return nil
end

function Flyable.GetCurrentContinentMapID()
	local mapID
	if C_Map and C_Map.GetBestMapForUnit then
		mapID = C_Map.GetBestMapForUnit("player")
	elseif GetCurrentMapAreaID then
		mapID = GetCurrentMapAreaID()
	end
	if not mapID or mapID == 0 then
		return nil
	end
	if not C_Map or not C_Map.GetMapInfo then
		return mapID
	end
	local mapInfo = C_Map.GetMapInfo(mapID)
	while mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0 do
		mapID = mapInfo.parentMapID
		mapInfo = C_Map.GetMapInfo(mapID)
	end
	return mapID
end

--- True on an open-world continent. Does not walk C_Map parents out of dungeons/BGs.
local function IsOnContinent(instanceIds, uimapIds, zoneNames)
	local instanceID = Flyable.GetCurrentInstanceMapID()
	if instanceID then
		if instanceIds[instanceID] then
			return true
		end
		if instanceID > 1 and not OPEN_WORLD_INSTANCE_IDS[instanceID] then
			return false
		end
	end
	if GetInstanceInfo then
		local _, instanceType = GetInstanceInfo()
		if instanceType and RESTRICTED_INSTANCE_TYPES[instanceType] then
			return false
		end
	end
	if IsInInstance and IsInInstance() then
		return false
	end

	local mapID
	if C_Map and C_Map.GetBestMapForUnit then
		mapID = C_Map.GetBestMapForUnit("player")
	elseif GetCurrentMapAreaID then
		mapID = GetCurrentMapAreaID()
	end
	if mapID and mapID ~= 0 then
		if uimapIds[mapID] or instanceIds[mapID] then
			return true
		end
		if C_Map and C_Map.GetMapInfo then
			local mapInfo = C_Map.GetMapInfo(mapID)
			while mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0 do
				mapID = mapInfo.parentMapID
				if uimapIds[mapID] then
					return true
				end
				mapInfo = C_Map.GetMapInfo(mapID)
			end
		end
	end

	local zoneLower = ZoneBlobLower()
	for name in pairs(zoneNames) do
		if zoneLower:find(name, 1, true) then
			return true
		end
	end
	return false
end

function Flyable.IsOutlandContinent()
	return IsOnContinent(OUTLAND_INSTANCE_IDS, OUTLAND_UIMAP_IDS, OUTLAND_ZONE_NAMES)
end

function Flyable.IsNorthrendContinent()
	return IsOnContinent(NORTHREND_INSTANCE_IDS, NORTHREND_UIMAP_IDS, NORTHREND_ZONE_NAMES)
end

function Flyable.IsOutlandOrNorthrendContinent()
	return Flyable.IsOutlandContinent() or Flyable.IsNorthrendContinent()
end

function Flyable.IsPlayerInOutlandOrNorthrend()
	return Flyable.IsOutlandOrNorthrendContinent()
end

function Flyable.IsInMountRestrictedInstance()
	if GetInstanceInfo then
		local _, instanceType, _, _, _, _, _, mapID = GetInstanceInfo()
		if instanceType and RESTRICTED_INSTANCE_TYPES[instanceType] then
			return true
		end
		mapID = tonumber(mapID) or 0
		if mapID > 1 and not OPEN_WORLD_INSTANCE_IDS[mapID] then
			return true
		end
	end
	if IsInInstance and IsInInstance() then
		return true
	end
	return false
end

function Flyable.GetMountItemLocationKey()
	local name, instanceType, instanceMapID = "", "none", 0
	if GetInstanceInfo then
		name, instanceType = GetInstanceInfo()
		instanceMapID = select(8, GetInstanceInfo())
	end
	instanceType = instanceType or "none"
	instanceMapID = tonumber(instanceMapID) or 0
	local inInst = (IsInInstance and IsInInstance()) and 1 or 0
	local continent = Flyable.IsOutlandOrNorthrendContinent() and 1 or 0
	local outdoors = (not IsOutdoors or IsOutdoors()) and 1 or 0
	local flyable = (Flyable.HasIsFlyableAreaAPI() and IsFlyableArea()) and 1 or 0
	local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
	return table.concat({
		tostring(name or ""),
		tostring(instanceType),
		tostring(instanceMapID),
		tostring(inInst),
		tostring(continent),
		tostring(outdoors),
		tostring(flyable),
		tostring(zone),
	}, "|")
end

function Flyable.BeginMountItemLocationSettle(durationSec)
	local now = (GetTime and GetTime()) or 0
	local untilTime = now + (durationSec or 2.5)
	if untilTime > mountItemSettleUntil then
		mountItemSettleUntil = untilTime
	end
	mountItemSettleStartedAt = now
	mountItemLastLocationKey = nil
	mountItemStablePolls = 0
end

function Flyable.EndMountItemLocationSettle()
	mountItemSettleUntil = 0
	mountItemStablePolls = 0
end

function Flyable.IsMountItemLocationSettling()
	local now = (GetTime and GetTime()) or 0
	return now < mountItemSettleUntil
end

function Flyable.UpdateMountItemLocationSettle(key)
	key = key or Flyable.GetMountItemLocationKey()
	local changed = key ~= mountItemLastLocationKey
	if changed then
		mountItemLastLocationKey = key
		mountItemStablePolls = 0
	else
		mountItemStablePolls = mountItemStablePolls + 1
	end

	if Flyable.IsMountItemLocationSettling() then
		local now = (GetTime and GetTime()) or 0
		local elapsed = now - (mountItemSettleStartedAt or 0)
		if not changed
			and elapsed >= MOUNT_ITEM_SETTLE_MIN_SEC
			and mountItemStablePolls >= MOUNT_ITEM_SETTLE_STABLE_POLLS
		then
			Flyable.EndMountItemLocationSettle()
			return key, changed, true
		end
		return key, changed, false
	end
	return key, changed, true
end

--- Journal / [flyable] clients: Blizzard IsFlyableArea. Bag-item clients without
--- that API fall through to CanPreferFlyingMountItem.
function Flyable.IsFlyableHere()
	if Flyable.HasIsFlyableAreaAPI() then
		return IsFlyableArea() and true or false
	end
	return Flyable.CanPreferFlyingMountItem()
end

--- Prefer a flying bag mount (no [flyable] in the item macro).
function Flyable.CanPreferFlyingMountItem()
	if Flyable.IsInMountRestrictedInstance() then
		return false
	end
	if IsEraClient() then
		return false
	end
	if not PlayerHasFlyingSkill() then
		return false
	end

	local hasAPI = Flyable.HasIsFlyableAreaAPI()
	local flyableNow = hasAPI and IsFlyableArea() or false

	if Flyable.IsMountItemLocationSettling() then
		if hasAPI then
			if not flyableNow then
				return false
			end
		else
			return false
		end
	end

	if hasAPI then
		if not flyableNow then
			return false
		end
		-- TBC flying items only work in Outland. Trust a positive API during settle
		-- (map parent walk can lag); after settle also require the continent.
		if IsTBCClient() and not Flyable.IsMountItemLocationSettling() then
			return Flyable.IsOutlandContinent()
		end
		return true
	end

	-- No IsFlyableArea: TBC Outland outdoors. Never Wintergrasp (Wrath no-fly).
	if IsOutdoors and not IsOutdoors() then
		return false
	end
	if IsTBCClient() then
		return Flyable.IsOutlandContinent()
	end
	if Flyable.IsOutlandContinent() then
		return true
	end
	if Flyable.IsNorthrendContinent() and not IsWintergraspZone() then
		return PlayerHasColdWeatherFlying()
	end
	return false
end

--- Icon / binding label / bag-item pick: Lua geography when [flyable] is absent.
function Flyable.PreferFlying()
	if not Flyable.HasFlyableMacroCondition() then
		return Flyable.CanPreferFlyingMountItem()
	end
	return Flyable.IsFlyableHere()
end

local function GetMountTooltipLower(itemId)
	local IC = _G.FluxItemClass
	if IC and IC.GetTooltipText then
		local text = IC.GetTooltipText(itemId)
		if type(text) == "string" and text ~= "" then
			return text:lower(), true
		end
	end
	return "", false
end

local function GetMountTraits(itemId)
	itemId = tonumber(itemId)
	if not itemId then
		return false, false, true
	end
	local now = (GetTime and GetTime()) or 0
	local entry = mountTraitCache[itemId]
	if entry and (now - entry.timestamp) < MOUNT_TRAIT_CACHE_EXPIRY then
		return entry.isFlying, entry.isZoneRestricted, false
	end
	local text, definitive = GetMountTooltipLower(itemId)
	if not definitive or #text < 24 then
		return false, false, true
	end
	local isFlying = false
	if text:find("riding 225", 1, true)
		or text:find("riding 300", 1, true)
		or text:find("flying mount", 1, true)
	then
		isFlying = true
	end
	local isZoneRestricted = false
	local hasOutlandOrNorthrend = text:find("outland", 1, true) or text:find("northrend", 1, true)
	if hasOutlandOrNorthrend then
		local summonRestrict = text:find("can only be summoned", 1, true)
			or text:find("only be summoned", 1, true)
			or text:find("summoned in", 1, true)
			or text:find("summoned outland", 1, true)
			or text:find("summoned northrend", 1, true)
		if summonRestrict then
			isZoneRestricted = true
			isFlying = true
		end
	end
	mountTraitCache[itemId] = {
		isFlying = isFlying,
		isZoneRestricted = isZoneRestricted,
		timestamp = now,
	}
	return isFlying, isZoneRestricted, false
end

function Flyable.IsMountFlyingByRidingRequirement(itemId)
	local isFlying, _, unknown = GetMountTraits(itemId)
	if unknown then
		return false
	end
	return isFlying
end

function Flyable.IsMountTraitUnknown(itemId)
	return select(3, GetMountTraits(itemId)) and true or false
end

function Flyable.IsMountZoneRestrictedToOutlandOrNorthrend(itemId)
	local _, isZoneRestricted, unknown = GetMountTraits(itemId)
	if unknown then
		return false
	end
	return isZoneRestricted
end

function Flyable.IsMountUsableInCurrentZone(itemId)
	if not itemId then
		return true
	end
	if not IsTBCClient() then
		local api = ClientFlags()
		if not (api and api.isWrath) then
			return true
		end
	end
	local isFlying, isZoneRestricted, unknown = GetMountTraits(itemId)
	if unknown then
		return true
	end
	if not (isFlying or isZoneRestricted) then
		return true
	end
	if Flyable.IsInMountRestrictedInstance() then
		return false
	end
	return Flyable.IsOutlandOrNorthrendContinent()
end

function Flyable.InvalidateMountItemsCacheForSettle()
	-- Bag list cache lives in MountItems. Keep tooltip traits across settle pulses.
end

function Flyable.InvalidateMountItemsCache()
	wipe(mountTraitCache)
end

Flyable.InvalidateAllMountItemsCache = Flyable.InvalidateMountItemsCache

local SHIM_NAMES = {
	"GetCurrentInstanceMapID",
	"GetCurrentContinentMapID",
	"IsOutlandContinent",
	"IsNorthrendContinent",
	"IsOutlandOrNorthrendContinent",
	"IsPlayerInOutlandOrNorthrend",
	"GetMountItemLocationKey",
	"BeginMountItemLocationSettle",
	"EndMountItemLocationSettle",
	"IsMountItemLocationSettling",
	"UpdateMountItemLocationSettle",
	"IsInMountRestrictedInstance",
	"HasIsFlyableAreaAPI",
	"HasFlyableMacroCondition",
	"IsFlyableHere",
	"CanPreferFlyingMountItem",
	"PreferFlying",
	"IsMountFlyingByRidingRequirement",
	"IsMountTraitUnknown",
	"IsMountZoneRestrictedToOutlandOrNorthrend",
	"IsMountUsableInCurrentZone",
	"InvalidateMountItemsCacheForSettle",
	"InvalidateMountItemsCache",
	"InvalidateAllMountItemsCache",
}

local function InstallShims()
	local FluxInv = _G.FluxInv or {}
	_G.FluxInv = FluxInv
	FluxInv.Spells = FluxInv.Spells or {}
	for i = 1, #SHIM_NAMES do
		local name = SHIM_NAMES[i]
		FluxInv.Spells[name] = Flyable[name]
	end
	local Det = _G.FluxItemDetection
	if type(Det) == "table" then
		for i = 1, #SHIM_NAMES do
			local name = SHIM_NAMES[i]
			Det[name] = Flyable[name]
		end
	end
end

InstallShims()
