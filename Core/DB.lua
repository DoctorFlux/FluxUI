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
		t = {}
		_G[name] = t
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
