-- Optional.lua — detect companion addons. No inventory scanning.
local addonName, ns = ...
local Flux = ns.Flux

local Optional = {}
Flux.Optional = Optional

local NAMES = {
	Syndicator = "Syndicator",
	Baganator = "Baganator",
	Details = "Details",
	BigDebuffs = "BigDebuffs",
	TacoTip = "TacoTip",
	ConsolePort = "ConsolePort",
	Questie = "Questie",
	Masque = "Masque",
	Clicked = "Clicked",
}

local function Loaded(name)
	return Flux.AddOn and Flux.AddOn.IsLoaded(name)
end

local probes = {}

probes.Syndicator = function()
	local loaded = Loaded("Syndicator")
	local api = rawget(_G, "Syndicator")
	local ready = false
	if api and api.API and type(api.API.IsReady) == "function" then
		local ok, isReady = pcall(api.API.IsReady)
		ready = ok and isReady and true or false
	end
	return {
		loaded = loaded,
		ready = ready,
		api = api and api.API or nil,
	}
end

probes.Baganator = function()
	local loaded = Loaded("Baganator")
	local api = rawget(_G, "Baganator")
	return { loaded = loaded, ready = loaded and api ~= nil, api = api }
end

probes.Details = function()
	local loaded = Loaded("Details")
	local api = rawget(_G, "Details")
	return { loaded = loaded, ready = loaded and api ~= nil, api = api }
end

probes.BigDebuffs = function()
	local loaded = Loaded("BigDebuffs")
	return { loaded = loaded, ready = loaded, api = rawget(_G, "BigDebuffs") }
end

probes.TacoTip = function()
	local loaded = Loaded("TacoTip")
	return { loaded = loaded, ready = loaded, api = rawget(_G, "TacoTip") }
end

probes.ConsolePort = function()
	local loaded = Loaded("ConsolePort")
	return { loaded = loaded, ready = loaded, api = rawget(_G, "ConsolePort") }
end

probes.Questie = function()
	local loaded = Loaded("Questie")
	return { loaded = loaded, ready = loaded, api = rawget(_G, "Questie") }
end

probes.Masque = function()
	local loaded = Loaded("Masque")
	return { loaded = loaded, ready = loaded, api = rawget(_G, "Masque") }
end

probes.Clicked = function()
	local loaded = Loaded("Clicked")
	return { loaded = loaded, ready = loaded, api = rawget(_G, "Clicked") }
end

function Optional.Get(name)
	local probe = probes[name]
	local info
	if probe then
		info = probe()
	else
		local addon = NAMES[name] or name
		local loaded = Loaded(addon)
		info = { loaded = loaded, ready = loaded, api = rawget(_G, addon) }
	end
	if Flux.Startup then Flux.Startup.ObserveOptional(name, info) end
	return info
end

function Optional.IsLoaded(name)
	return Optional.Get(name).loaded
end

function Optional.IsReady(name)
	return Optional.Get(name).ready
end

function Optional.Snapshot()
	local out = {}
	for name in pairs(probes) do
		out[name] = Optional.Get(name)
	end
	return out
end
