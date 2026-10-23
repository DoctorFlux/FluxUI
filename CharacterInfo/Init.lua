-- CharacterInfo/Init.lua — overlay boot. Blizzard CharacterFrame stays;
-- Flux waits for the real character addon then installs extras.
local addonName, ns = ...
local Flux = ns.Flux
local module = ns.CharacterStats

local CI = Flux.CharacterInfo or {}
Flux.CharacterInfo = CI

local started = false

local function CallInstaller(fn)
	if type(fn) ~= "function" then
		return true
	end
	return Flux.Safecall(fn)
end

function CI.TryInstall()
	if Flux.Combat and Flux.Combat.InLockdown() then
		Flux.Combat.Defer("characterinfo.install", CI.TryInstall)
		return false
	end
	local Cap = Flux.Cap
	if Cap and Cap.RefreshCharacterInfo then
		Cap.RefreshCharacterInfo()
	end

	local success = true
	if not CallInstaller(module and module.InstallClassicStatsPanel) then success = false end
	if not CallInstaller(module and module.InstallQuality) then success = false end
	if not CallInstaller(module and module.InstallVisibility) then success = false end
	if not CallInstaller(module and module.InstallSecondaryName) then success = false end
	if not CallInstaller(module and module.InstallItemLevel) then success = false end
	if not CallInstaller(module and module.InstallTacoTip) then success = false end
	if not CallInstaller(module and module.InstallRetailPane) then success = false end

	local info = rawget(_G, "FluxInfoFrame")
	if info and type(info.InstallCharacterInfoPinHooks) == "function" then
		info.InstallCharacterInfoPinHooks()
	end
	return success
end

local function OnAddonLoaded(event, name)
	if module and module.IsCharacterUiAddon and module.IsCharacterUiAddon(name) then
		CI.TryInstall()
		return
	end
	if name == "TacoTip" then
		CI.TryInstall()
	end
end

local function Start()
	if started then
		return
	end
	if not CI.TryInstall() then return false end

	if Flux.Events and Flux.Events.Register then
		Flux.Events.Register("ADDON_LOADED", OnAddonLoaded)
		Flux.Events.Register("PLAYER_LOGIN", function()
			CI.TryInstall()
		end)
		Flux.Events.Register("PLAYER_ENTERING_WORLD", function()
			CI.TryInstall()
		end)
	end
	started = true
	return true
end

Flux.Module.Register("CharacterInfo", {
	phase = "deferred",
	protected = true,
	clients = { era = true, anniversary = true, classic = true, midnight = true },
	OnEnable = Start,
})
