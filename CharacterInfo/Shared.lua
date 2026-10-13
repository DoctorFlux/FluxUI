-- Character Info overlays: client flags, saved vars, coalesced stat refresh.
-- Era/Anniversary CSC flags come from Flux.Client, never from build "1.x"
-- (Forever is 1.x mainline) and never from Forever's stats ScrollBox globals.
local addonName, ns = ...
local Flux = ns.Flux
local Client = Flux.Client

ns.CharacterStats = ns.CharacterStats or {}
local module = ns.CharacterStats

module.addonName = addonName
module.displayName = "FluxUI Character Stats"
module.settingsTitle = module.displayName
module.majorVersion = (Client and Client.majorVersion) or 0

module.isClassicEra = Client and Client.isEra == true
module.isProgression = Client and (Client.isAnniversary or Client.isTBC or Client.isWrath) == true
module.isRetail = Client and (Client.isRetail or Client.isCamelot) == true
-- Dual-dropdown CSC: Vanilla Era + TBC/Wrath. Cata/Mists and mainline use a stats pane.
module.useCscPanel = module.isClassicEra or module.isProgression
module.useClassicPaperDollChrome = module.useCscPanel
module.useRetailPaneHooks = not module.useCscPanel
module.isSupported = module.isClassicEra or module.isProgression or module.isRetail or (Client and Client.isClassic == true)
module.core = module.core or {}

function module.IsCharacterUiAddon(name)
	return name == "Blizzard_CharacterFrame"
		or name == "Blizzard_UIPanels_Game"
		or name == "Blizzard_CharacterUI"
end

function module.HasCharacterFrame()
	return rawget(_G, "CharacterFrame") ~= nil
end

function module.HasClassicAttributes()
	local f = rawget(_G, "CharacterAttributesFrame")
	return f ~= nil
end

local function EnsureStorage()
	FluxUI_DB = FluxUI_DB or {}
	FluxUI_DB.CharacterStats = FluxUI_DB.CharacterStats or {}

	_FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
	_FluxUI_CharSavedVars.CharacterStats = _FluxUI_CharSavedVars.CharacterStats or {}

	return FluxUI_DB.CharacterStats, _FluxUI_CharSavedVars.CharacterStats
end

function module.GetModeKey()
	if module.isClassicEra then
		return "era"
	end
	if module.isRetail then
		return "retail"
	end
	return "progression"
end

function module.GetGlobalDB()
	local accountRoot = EnsureStorage()
	local modeKey = module.GetModeKey()
	accountRoot[modeKey] = accountRoot[modeKey] or {}
	accountRoot[modeKey].global = accountRoot[modeKey].global or {}
	return accountRoot[modeKey].global
end

function module.GetCharacterDB()
	local _, charRoot = EnsureStorage()
	local modeKey = module.GetModeKey()
	charRoot[modeKey] = charRoot[modeKey] or {}
	return charRoot[modeKey]
end

local statRefreshPending = false
local statRefreshFallbackFrame = nil

local function FlushPlayerStatRefresh()
	statRefreshPending = false

	local core = module.core
	if core and core.UIConfig then
		local lfgBlocked = (LFGListingFrame and LFGListingFrame:IsVisible())
			or (LFGListFrame and LFGListFrame:IsVisible())
		if not lfgBlocked then
			local panel = core.UIConfig.CharacterStatsPanel
			if panel and panel:IsVisible() then
				core.UIConfig:UpdateStats()
			end
		end
	end

	local info = rawget(_G, "FluxInfoFrame")
	if info and type(info._FlushPlayerStatRefresh) == "function" then
		info._FlushPlayerStatRefresh()
	end
end

function module.QueuePlayerStatRefresh()
	if statRefreshPending then
		return
	end
	statRefreshPending = true

	if C_Timer and C_Timer.After then
		C_Timer.After(0, FlushPlayerStatRefresh)
		return
	end

	if not statRefreshFallbackFrame then
		statRefreshFallbackFrame = CreateFrame("Frame")
	end
	statRefreshFallbackFrame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil)
		FlushPlayerStatRefresh()
	end)
end

_G.FluxCSC_QueuePlayerStatRefresh = module.QueuePlayerStatRefresh
