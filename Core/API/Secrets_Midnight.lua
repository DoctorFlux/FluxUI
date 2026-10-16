-- Secrets_Midnight.lua — secret-value backend (Retail Midnight + Forever camelot).
local addonName, ns = ...
local Client = ns.Flux and ns.Flux.Client
if Client and not (Client.isRetail or Client.isCamelot) then return end

local pcall = pcall
local _canaccessvalue = canaccessvalue
local _issecretvalue = issecretvalue or IsSecretValue
local _canaccesssecrets = canaccesssecrets
local _issecrettable = issecrettable
local _canaccesstable = canaccesstable

ns._secretsBackendKind = "midnight"
ns._secretsBackend = {
	CanAccessValue = function(value)
		if _canaccessvalue then
			local ok, res = pcall(_canaccessvalue, value)
			return ok and res or false
		end
		return true
	end,
	IsSecretValue = function(value)
		if _issecretvalue then
			local ok, res = pcall(_issecretvalue, value)
			return ok and res and true or false
		end
		return false
	end,
	CanAccessSecrets = function()
		if _canaccesssecrets then
			local ok, res = pcall(_canaccesssecrets)
			return ok and res and true or false
		end
		return true
	end,
	IsSecretTable = function(value)
		if type(value) ~= "table" then
			return false
		end
		if _issecrettable then
			local ok, res = pcall(_issecrettable, value)
			return ok and res and true or false
		end
		return false
	end,
	CanAccessTable = function(value)
		if type(value) ~= "table" then
			return true
		end
		if _canaccesstable then
			local ok, res = pcall(_canaccesstable, value)
			return ok and res or false
		end
		return true
	end,
}
