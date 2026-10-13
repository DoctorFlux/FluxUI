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
		return
	end
	Flux.Safecall(fn)
end

function CI.TryInstall()
	local Cap = Flux.Cap
	if Cap and Cap.RefreshCharacterInfo then
		Cap.RefreshCharacterInfo()
	end

	CallInstaller(module and module.InstallClassicStatsPanel)
	CallInstaller(module and module.InstallQuality)
	CallInstaller(module and module.InstallVisibility)
	CallInstaller(module and module.InstallSecondaryName)
	CallInstaller(module and module.InstallItemLevel)
	CallInstaller(module and module.InstallTacoTip)
	CallInstaller(module and module.InstallRetailPane)

	local info = rawget(_G, "FluxInfoFrame")
	if info and type(info.InstallCharacterInfoPinHooks) == "function" then
		info.InstallCharacterInfoPinHooks()
	end
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
	started = true

	CI.TryInstall()

	if Flux.Events and Flux.Events.Register then
		Flux.Events.Register("ADDON_LOADED", OnAddonLoaded)
		Flux.Events.Register("PLAYER_LOGIN", function()
			CI.TryInstall()
		end)
		Flux.Events.Register("PLAYER_ENTERING_WORLD", function()
			CI.TryInstall()
		end)
	end
end

Flux.Module.Register("CharacterInfo", {
	clients = { era = true, anniversary = true, classic = true, midnight = true },
	OnEnable = Start,
})
