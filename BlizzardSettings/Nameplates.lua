-- BlizzardSettings/Nameplates.lua — Flux's Blizzard nameplate CVar pack (all clients).
-- Applied on the first account apply, /fluxdefaults, and when FluxDefaultSettings
-- queues it after Options Defaults. The full pack does not re-apply at login.
-- Missing CVars are skipped, so one table covers Era, Anniversary, Forever, and Live.
-- nameplateSize 3 is Large on every client.
local addonName, ns = ...
local BS = ns.Flux.BlizzardSettings
local Write = BS.Write

local Nameplates = {}
BS.Nameplates = Nameplates

--- Show all / enemies / minions / minus / offscreen. Friendly players off.
--- Large size, 120% auras, Block style (Blocky bars on Era / Anniversary / Live).
Nameplates.SCALARS = {
	nameplateShowAll = "1",
	nameplateShowEnemies = "1",
	nameplateShowEnemyMinions = "1",
	nameplateShowEnemyMinus = "1",
	nameplateShowFriendlyPlayers = "0",
	nameplateShowSelf = "0",
	nameplateShowOffscreen = "1",
	nameplateSize = "3",
	nameplateAuraScale = "1.2",
	nameplateStyle = "2",
}

--- Class colors on enemy players only.
Nameplates.CLASS_COLOR = {
	nameplateShowClassColor = "1",
	nameplateShowFriendlyClassColor = "0",
}

--- NPC Names dropdown = All (Blizzard PROXY_NPC_NAMES value 4).
Nameplates.NPC_NAMES = {
	UnitNameFriendlySpecialNPCName = "0",
	UnitNameHostleNPC = "0",
	UnitNameInteractiveNPC = "0",
	UnitNameNPC = "1",
	ShowQuestUnitCircles = "1",
	UnitNameNonCombatCreatureName = "1",
}

--- Multi-select CVars. `enable` lists the Enum keys switched on; every other key is off.
Nameplates.BITFIELDS = {
	{ cvar = "nameplateInfoDisplay", enum = "NamePlateInfoDisplay",
		enable = { "CurrentHealthPercent", "CurrentHealthValue", "RarityIcon" } },
	{ cvar = "nameplateCastBarDisplay", enum = "NamePlateCastBarDisplay",
		enable = { "SpellName", "SpellIcon", "SpellTarget", "HighlightImportantCasts", "HighlightWhenCastTarget" } },
	{ cvar = "nameplateThreatDisplay", enum = "NamePlateThreatDisplay",
		enable = { "Progressive", "Flash", "HealthBarColor" } },
	{ cvar = "nameplateEnemyNpcAuraDisplay", enum = "NamePlateEnemyNpcAuraDisplay",
		enable = { "Buffs", "Debuffs", "CrowdControl" } },
	{ cvar = "nameplateEnemyPlayerAuraDisplay", enum = "NamePlateEnemyPlayerAuraDisplay",
		enable = { "Buffs", "Debuffs", "LossOfControl" } },
	{ cvar = "nameplateFriendlyPlayerAuraDisplay", enum = "NamePlateFriendlyPlayerAuraDisplay",
		enable = { "Buffs", "Debuffs", "LossOfControl" } },
	{ cvar = "nameplateSimplifiedTypes", enum = "NamePlateSimplifiedType",
		enable = { "Minion", "MinusMob" } },
	{ cvar = "nameplateStackingTypes", enum = "NamePlateStackType",
		enable = { "Enemy", "Friendly" } },
}

--- Settings variables refreshed after a write (Era / Anniversary only; see Write.Notify).
local NOTIFY = {
	"PROXY_NPC_NAMES",
	"UnitNameNonCombatCreatureName",
	"nameplateShowAll",
	"nameplateShowEnemies",
	"nameplateShowEnemyMinions",
	"nameplateShowEnemyMinus",
	"nameplateShowFriendlyPlayers",
	"nameplateShowSelf",
	"nameplateShowOffscreen",
	"nameplateSize",
	"nameplateAuraScale",
	"nameplateStyle",
	"nameplateShowClassColor",
	"nameplateShowFriendlyClassColor",
	"UNIT_NAMEPLATES_CLASS_COLOR",
	"UNIT_NAMEPLATES_INFO_DISPLAY",
	"UNIT_NAMEPLATES_CAST_BAR_DISPLAY",
	"UNIT_NAMEPLATES_THREAT_DISPLAY",
	"UNIT_NAMEPLATES_ENEMY_NPC_AURA_DISPLAY",
	"UNIT_NAMEPLATES_ENEMY_PLAYER_AURA_DISPLAY",
	"UNIT_NAMEPLATES_FRIENDLY_PLAYER_AURA_DISPLAY",
	"UNIT_NAMEPLATES_SIMPLIFIED",
	"UNIT_NAMEPLATES_ENABLE_STACKING",
}

local function ApplyMap(map, force)
	local wrote = false
	for cvar, value in pairs(map) do
		if Write.CVar(cvar, value, force) then
			wrote = true
		end
	end
	return wrote
end

local function EachBit(entry, fn)
	local group = Enum and Enum[entry.enum]
	if type(group) ~= "table" or not Write.Exists(entry.cvar) then
		return
	end
	local enabled = {}
	for _, key in ipairs(entry.enable) do
		enabled[key] = true
	end
	for key, index in pairs(group) do
		if type(key) == "string" and key ~= "None" and type(index) == "number" and index > 0 then
			fn(index, enabled[key] == true)
		end
	end
end

function Nameplates.ApplyScalars(force)
	return ApplyMap(Nameplates.SCALARS, force)
end

function Nameplates.ApplyClassColor(force)
	return ApplyMap(Nameplates.CLASS_COLOR, force)
end

function Nameplates.ApplyNpcNames(force)
	return ApplyMap(Nameplates.NPC_NAMES, force)
end

function Nameplates.ApplyBitfields(force)
	local wrote = false
	for _, entry in ipairs(Nameplates.BITFIELDS) do
		EachBit(entry, function(index, on)
			if Write.Bit(entry.cvar, index, on, force) then
				wrote = true
			end
		end)
	end
	return wrote
end

function Nameplates.Differs()
	for _, map in ipairs({ Nameplates.SCALARS, Nameplates.CLASS_COLOR, Nameplates.NPC_NAMES }) do
		for cvar, value in pairs(map) do
			if not Write.Matches(cvar, value) then
				return true
			end
		end
	end
	local getBit = (C_CVar and C_CVar.GetCVarBitfield) or GetCVarBitfield
	if not getBit then
		return false
	end
	local differs = false
	for _, entry in ipairs(Nameplates.BITFIELDS) do
		EachBit(entry, function(index, on)
			local ok, cur = pcall(getBit, entry.cvar, index)
			if ok and (cur and true or false) ~= on then
				differs = true
			end
		end)
	end
	return differs
end

function Nameplates.ApplyNow(force)
	local wrote = false
	if Nameplates.ApplyNpcNames(force) then
		wrote = true
	end
	if Nameplates.ApplyScalars(force) then
		wrote = true
	end
	if Nameplates.ApplyBitfields(force) then
		wrote = true
	end
	if Nameplates.ApplyClassColor(force) then
		wrote = true
	end
	if Nameplates.ApplyHealthText() then
		wrote = true
	end
	if wrote then
		Write.Notify(NOTIFY)
	end
	return wrote
end

--- Health amount and percent. Any client with Enum.NamePlateInfoDisplay.
--- A secret current value is written through; it is not compared.
function Nameplates.ApplyHealthText()
	local info = Enum and Enum.NamePlateInfoDisplay
	if not info then
		return false
	end
	local wrote = false
	if type(info.CurrentHealthPercent) == "number" and Write.Bit("nameplateInfoDisplay", info.CurrentHealthPercent, true, false) then
		wrote = true
	end
	if type(info.CurrentHealthValue) == "number" and Write.Bit("nameplateInfoDisplay", info.CurrentHealthValue, true, false) then
		wrote = true
	end
	return wrote
end

function Nameplates.Apply(force)
	return Write.Run("nameplates", function()
		local wrote = Nameplates.ApplyNow(force)
		if wrote then
			print("|cFF00FFFF[FluxDefaultSettings]|r Applied FluxUI nameplate defaults.")
		end
		return wrote
	end)
end

--- Zone loads can clear the health readout bits. Re-apply on every client that has them.
local healthBits = CreateFrame("Frame")
healthBits:RegisterEvent("PLAYER_ENTERING_WORLD")
healthBits:SetScript("OnEvent", function()
	Write.Run("nameplateHealthText", function()
		Nameplates.ApplyHealthText()
	end)
end)
