-- Module.lua — register / enable / disable by client + capability + optional dep.
-- TOC AllowLoadGameType is the first gate; this is the second.
local addonName, ns = ...
local Flux = ns.Flux

local Module = {}
Flux.Module = Module

local registry = {} -- name -> spec
local enabled = {} -- name -> true
local order = {}

local function ClientOk(spec)
	return Flux.Client.Matches(spec.clients)
end

local function CapsOk(spec)
	local caps = spec.capabilities
	if type(caps) ~= "table" then
		return true
	end
	local Cap = Flux.Cap
	for i = 1, #caps do
		local key = caps[i]
		if not Cap or not Cap[key] then
			return false
		end
	end
	return true
end

local function AddonsOk(spec)
	local required = spec.requiredAddons
	if type(required) ~= "table" then
		return true
	end
	local AddOn = Flux.AddOn
	for i = 1, #required do
		local name = required[i]
		if not AddOn or not AddOn.IsLoaded(name) then
			return false
		end
	end
	return true
end

function Module.IsEligible(name)
	local spec = registry[name]
	if not spec then
		return false
	end
	return ClientOk(spec) and CapsOk(spec) and AddonsOk(spec)
end

--- Register a feature module. Does not enable until EnableEligible / Enable.
-- spec.clients = { era=true, anniversary=true, classic=true, midnight=true }
-- spec.capabilities = { "hasFocusUnit" }
-- spec.optional = { Syndicator = "prefer" }  -- does not block
-- spec.requiredAddons = { "Syndicator" }     -- blocks if missing
-- spec.OnLoad / OnEnable / OnDisable
function Module.Register(name, spec)
	if type(name) ~= "string" or type(spec) ~= "table" then
		return
	end
	if not registry[name] then
		order[#order + 1] = name
	end
	registry[name] = spec
	if spec.OnLoad then
		Flux.AfterLoad(spec.OnLoad)
	end
	if Flux.loggedIn then
		Module.Enable(name)
	end
end

function Module.Enable(name)
	local spec = registry[name]
	if not spec or enabled[name] then
		return false
	end
	if not Module.IsEligible(name) then
		return false
	end
	enabled[name] = true
	if spec.OnEnable then
		Flux.Safecall(spec.OnEnable)
	end
	return true
end

function Module.Disable(name)
	local spec = registry[name]
	if not spec or not enabled[name] then
		return false
	end
	enabled[name] = nil
	if spec.OnDisable then
		Flux.Safecall(spec.OnDisable)
	end
	return true
end

function Module.IsEnabled(name)
	return enabled[name] and true or false
end

function Module.EnableEligible()
	for i = 1, #order do
		Module.Enable(order[i])
	end
end

function Module.List()
	local out = {}
	for i = 1, #order do
		local name = order[i]
		out[#out + 1] = {
			name = name,
			eligible = Module.IsEligible(name),
			enabled = enabled[name] and true or false,
		}
	end
	return out
end
