-- Secrets_Classic.lua — always-accessible stubs (non-mainline).
-- AllowLoadGameType vanilla, tbc, wrath, cata, mists
local addonName, ns = ...

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
