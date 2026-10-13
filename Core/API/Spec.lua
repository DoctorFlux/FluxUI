-- Spec.lua — specialization / role helpers.
-- NEVER replace PlayerUtil.IsPlayerEffectivelyTank — nameplate SetUnit taints
-- AurasFrame:SetUnit → Layout → GetScaledRect.
-- Only shim _G.GetSpecializationRole when the native Classic stub is broken.
-- Never install that shim on retail.
local addonName, ns = ...
local Flux = ns.Flux
local Client = Flux.Client

local Spec = {}
Flux.Spec = Spec
Flux.API = Flux.API or {}
Flux.API.Spec = Spec

local pcall = pcall
local type = type
local rawget = rawget

local blizzardGetSpecializationRole = rawget(_G, "GetSpecializationRole")
local compatInstalled = false

function Spec.GetSpecialization()
	if C_SpecializationInfo and type(C_SpecializationInfo.GetSpecialization) == "function" then
		local ok, spec = pcall(C_SpecializationInfo.GetSpecialization)
		if ok then
			return spec
		end
	end
	if type(GetSpecialization) == "function" then
		local ok, spec = pcall(GetSpecialization)
		if ok then
			return spec
		end
	end
	return nil
end

function Spec.GetRole(specIndex, isInspect, isPet)
	if not specIndex then
		return nil
	end
	isInspect = isInspect or false
	isPet = isPet or false

	if C_SpecializationInfo and type(C_SpecializationInfo.GetSpecializationInfo) == "function" then
		local ok, _id, _name, _desc, _icon, role = pcall(
			C_SpecializationInfo.GetSpecializationInfo, specIndex, isInspect, isPet)
		if ok and role then
			return role
		end
	end

	if type(GetSpecializationInfo) == "function" then
		local ok, _id, _name, _desc, _icon, role = pcall(
			GetSpecializationInfo, specIndex, isInspect, isPet)
		if ok and role then
			return role
		end
	end

	if type(blizzardGetSpecializationRole) == "function" then
		local ok, role = pcall(blizzardGetSpecializationRole, specIndex, isInspect, isPet)
		if ok and role then
			return role
		end
	end

	return nil
end

function Spec.IsPlayerEffectivelyTank()
	if type(UnitGroupRolesAssigned) == "function" then
		local ok, role = pcall(UnitGroupRolesAssigned, "player")
		if ok and role and role ~= "NONE" then
			return role == "TANK"
		end
	end
	local spec = Spec.GetSpecialization()
	return (spec and Spec.GetRole(spec) == "TANK") or false
end

local function NativeGetSpecializationRoleBroken()
	local fn = blizzardGetSpecializationRole
	if type(fn) ~= "function" then
		return true
	end
	local ok = pcall(fn, 1)
	return not ok
end

--- Install GetSpecializationRole only when the native API errors/missing.
--- Does not touch PlayerUtil. Never install on retail.
function Spec.InstallRoleCompat()
	if compatInstalled then
		return true
	end
	if Client.isRetail then
		return false
	end
	if not NativeGetSpecializationRoleBroken() then
		return false
	end

	_G.GetSpecializationRole = function(specIndex, isInspect, isPet)
		return Spec.GetRole(specIndex, isInspect, isPet)
	end
	compatInstalled = true
	return true
end

Flux.AfterLoad(function()
	Spec.InstallRoleCompat()
end)
Flux.AfterLogin(function()
	Spec.InstallRoleCompat()
end)
