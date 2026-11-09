-- Secrets_Classic.lua — always-accessible stubs (non-mainline).
-- AllowLoadGameType vanilla, tbc, wrath, cata, mists
local addonName, ns = ...
-- Per-file TOC filters are insufficient isolation for this shared addon.
local Client = ns.Flux and ns.Flux.Client
if Client and (Client.isRetail or Client.isCamelot) then return end

ns._secretsBackendKind = "classic"
ns._secretsBackend = {
	CanAccessValue = function()
		return true
	end,
	IsSecretValue = function()
		return false
	end,
	CanAccessSecrets = function()
		return true
	end,
	IsSecretTable = function()
		return false
	end,
	CanAccessTable = function()
		return true
	end,
}
