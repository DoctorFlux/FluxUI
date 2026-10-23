-- Module.lua — register / enable / disable by client + capability + optional dep.
-- TOC AllowLoadGameType is the first gate; this is the second.
local addonName, ns = ...
local Flux = ns.Flux

local Module = {}
Flux.Module = Module

local registry = {} -- name -> spec
local enabled = {} -- name -> true
local order = {}
local enabling = {}
local failures = {}
local dependencyQueued = {}

local function PhaseReady(spec)
	local phase = spec.phase or "hud"
	if phase == "secure" then return Flux.securePhaseReady end
	if phase == "deferred" then return Flux.deferredPhaseReady end
	return Flux.loggedIn
end

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
	local i = #order
	while i > 1 and order[i] == name and (registry[order[i - 1]].priority or 50) > (spec.priority or 50) do
		order[i], order[i - 1] = order[i - 1], order[i]
		i = i - 1
	end
	if spec.OnLoad then
		Flux.AfterLoad(spec.OnLoad)
	end
	if PhaseReady(spec) then
		Module.Enable(name)
	end
end

function Module.Enable(name)
	local spec = registry[name]
	if not spec or enabled[name] or enabling[name] then
		return false
	end
	if not PhaseReady(spec) then return false end
	if not Module.IsEligible(name) then
		return false
	end
	if spec.protected and Flux.Combat and Flux.Combat.InLockdown() then
		Flux.Combat.Defer("module." .. name, function() Module.Enable(name) end)
		return false
	end
	enabling[name] = true
	local ok, result = true, nil
	if spec.OnEnable then
		ok, result = Flux.Safecall(spec.OnEnable)
	end
	enabling[name] = nil
	if not ok or result == false then
		failures[name] = result or "initialization incomplete"
		return false
	end
	failures[name] = nil
	enabled[name] = true
	if Flux.Startup then Flux.Startup.Mark("module." .. name) end
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

function Module.EnableEligible(phase)
	-- Stable priorities preserve registration order for equal priorities.
	for i = 1, #order do
		local name = order[i]
		local spec = registry[name]
		if (not phase or (spec.phase or "hud") == phase) and PhaseReady(spec) then
			Module.Enable(name)
		end
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
			phase = registry[name].phase or "hud",
			error = failures[name],
		}
	end
	return out
end

if Flux.Events then
	Flux.Events.Register("ADDON_LOADED", function(_, addon)
		if not Flux.loaded then return end
		for i = 1, #order do
			local name = order[i]
			local spec = registry[name]
			if not enabled[name] and PhaseReady(spec) and spec.requiredAddons then
				for j = 1, #spec.requiredAddons do
					if spec.requiredAddons[j] == addon then
						if not dependencyQueued[name] then
							dependencyQueued[name] = true
							local function EnableDependency()
								dependencyQueued[name] = nil
								Module.Enable(name)
							end
							-- Provider ADDON_LOADED handlers may still be on the event
							-- dispatch list. Initialize integrations after they finish.
							if Flux.Timer then Flux.Timer.After(0, EnableDependency) else EnableDependency() end
						end
						break
					end
				end
			end
		end
	end)
end
