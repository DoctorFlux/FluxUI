-- AddOn.lua — C_AddOns vs legacy GetAddOnMetadata / IsAddOnLoaded
local addonName, ns = ...
local Flux = ns.Flux

local AddOn = {}
Flux.AddOn = AddOn
Flux.API = Flux.API or {}
Flux.API.AddOn = AddOn

local _IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
local _GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local _LoadAddOn = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
local _EnableAddOn = (C_AddOns and C_AddOns.EnableAddOn) or EnableAddOn
local _GetAddOnInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
local _DoesAddOnExist = C_AddOns and C_AddOns.DoesAddOnExist
local _IsAddOnLoadable = (C_AddOns and C_AddOns.IsAddOnLoadable) or IsAddOnLoadable
local _GetNumAddOns = (C_AddOns and C_AddOns.GetNumAddOns) or GetNumAddOns
local _UsesCAddOnsInfo = C_AddOns and C_AddOns.GetAddOnInfo and true or false

local function InfoReason(fourth, fifth, sixth)
	if _UsesCAddOnsInfo then
		return fifth
	end
	return sixth
end

function AddOn.IsLoaded(name)
	if not name or not _IsAddOnLoaded then
		return false
	end
	local ok, loaded = pcall(_IsAddOnLoaded, name)
	return ok and loaded and true or false
end

function AddOn.GetMetadata(name, field)
	if not _GetAddOnMetadata then
		return nil
	end
	local ok, value = pcall(_GetAddOnMetadata, name or addonName, field)
	if ok then
		return value
	end
	return nil
end

function AddOn.Load(name)
	if not name or not _LoadAddOn then
		return false
	end
	local ok, loaded = pcall(_LoadAddOn, name)
	return ok and loaded and true or false
end

function AddOn.Enable(name)
	if not name or not _EnableAddOn then
		return false
	end
	return pcall(_EnableAddOn, name)
end

function AddOn.GetInfo(name)
	if not name or not _GetAddOnInfo then
		return nil
	end
	local ok, title, notes, loadable, reason, security, missingUpdate = pcall(_GetAddOnInfo, name)
	if not ok then
		return nil
	end
	return title, notes, loadable, reason, security, missingUpdate
end

--- True when this addon is in the current game type's addon list.
-- Scan GetNumAddOns (AllowLoadGameType already dropped Classic-incompatible
-- Blizzard addons). DoesAddOnExist / GetAddOnInfo(name) can echo a missing name.
function AddOn.Exists(name)
	if not name then
		return false
	end
	if _GetNumAddOns and _GetAddOnInfo then
		local okN, n = pcall(_GetNumAddOns)
		if okN and type(n) == "number" and n > 0 then
			for i = 1, n do
				local ok, addonName, _, _, fourth, fifth, sixth = pcall(_GetAddOnInfo, i)
				if ok and addonName == name then
					return InfoReason(fourth, fifth, sixth) ~= "MISSING"
				end
			end
			return false
		end
	end
	if _DoesAddOnExist then
		local ok, exists = pcall(_DoesAddOnExist, name)
		return ok and exists and true or false
	end
	return false
end

function AddOn.IsLoadable(name)
	if not name then
		return false
	end
	if _IsAddOnLoadable then
		local ok, loadable = pcall(_IsAddOnLoadable, name)
		if ok then
			if loadable == true or loadable == 1 then
				return true
			end
			if loadable == "DEMAND_LOADED" then
				return true
			end
		end
	end
	if not _GetAddOnInfo then
		return false
	end
	local ok, _, _, _, fourth, fifth, sixth = pcall(_GetAddOnInfo, name)
	if not ok then
		return false
	end
	if C_AddOns and C_AddOns.GetAddOnInfo then
		return fourth == true or fourth == 1 or fifth == "DEMAND_LOADED"
	end
	return fifth == true or fifth == 1 or sixth == "DEMAND_LOADED"
end
