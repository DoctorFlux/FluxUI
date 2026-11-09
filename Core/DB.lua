-- DB.lua — SavedVariables bootstrap. Keep existing SV names so later steps can migrate.
local addonName, ns = ...
local Flux = ns.Flux

local DB = {}
Flux.DB = DB

local ACCOUNT_VARS = {
	"FluxUI_DB",
	"FluxUI_Options",
	"FluxNonCombatGridDB",
	"FluxFlyoutFavorites_Data",
	"FluxUIGoldLedger",
	"FluxSalvageDB",
	"FluxInvDB",
	"FluxUIInventoryDB",
}

local CHAR_VARS = {
	"_FluxUI_CharSavedVars",
	"FluxSpellBookSlotsDB",
	"FluxNCUtilitySlotsDB",
	"FluxSpellBindingProfilesDB",
	"FluxSpellDirectBindDB",
	"FluxSpellProfileBindingsDB",
	"FluxBindingProfilesPerStateDB",
	"FluxBindingDBv2",
	"FluxBindingDB3",
	"FluxTradeSkillScannerDB",
	"TrinketMenuOptions",
	"TrinketMenuPerOptions",
	"TrinketMenuQueue",
	"FluxNCFlyoutCharDB",
}

local function EnsureTable(name)
	local t = _G[name]
	if type(t) ~= "table" then
		local replacement = {}
		if t ~= nil then
			-- Preserve malformed but serializable roots before repairing their
			-- shape. Never discard a player's recoverable SavedVariables value.
			local account = name == "FluxUI_DB" and replacement or _G.FluxUI_DB
			if type(account) ~= "table" then
				account = {}
				if _G.FluxUI_DB ~= nil then account.__invalidAccountRoot = _G.FluxUI_DB end
				_G.FluxUI_DB = account
			end
			local recovery = account.__fluxRootRecoveryV1
			if type(recovery) ~= "table" then
				recovery = { version = 1, previous = recovery, roots = {} }
				account.__fluxRootRecoveryV1 = recovery
			end
			if type(recovery.roots) ~= "table" then
				recovery.previousRoots = recovery.roots
				recovery.roots = {}
			end
			if recovery.roots[name] == nil then recovery.roots[name] = t end
		end
		t = replacement
		_G[name] = replacement
	end
	return t
end

function DB.GetAccount()
	return EnsureTable("FluxUI_DB")
end

function DB.GetOptions()
	return EnsureTable("FluxUI_Options")
end

function DB.GetChar()
	return EnsureTable("_FluxUI_CharSavedVars")
end

function DB.EnsureAll()
	for i = 1, #ACCOUNT_VARS do
		EnsureTable(ACCOUNT_VARS[i])
	end
	for i = 1, #CHAR_VARS do
		EnsureTable(CHAR_VARS[i])
	end
end

Flux.AfterLoad(function()
	DB.EnsureAll()
end)
