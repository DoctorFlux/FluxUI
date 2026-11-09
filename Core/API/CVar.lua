-- CVar.lua — safe CVar access. Never overwrite Blizzard C_CVar.
-- Retail nameplate / raid-preview CVars can re-enter NamePlateDriver or
-- CompactUnitFrameProfiles under this addon and taint Settings preview.
local addonName, ns = ...
local Flux = ns.Flux
local Client = Flux.Client

local CVar = {}
Flux.CVar = CVar
Flux.API = Flux.API or {}
Flux.API.CVar = CVar

local function IsBlocked(cvar)
	if type(cvar) ~= "string" then
		return false
	end
	local lower = string.lower(cvar)

	-- Action targeting + cast-bar preview: block on retail only.
	if lower == "softtargetenemy"
		or lower == "showenemycastbar"
		or lower == "showtargetcastbar" then
		if Client.isEra or Client.isAnniversary then
			return false
		end
		return true
	end

	-- nameplate*: blocked here on post-DF for every caller. The Flux nameplate pack
	-- writes through BlizzardSettings/Write.lua (out of combat, Settings closed).
	-- Post-DF SetCVar fires NamePlateAurasMixin.UpdateAuraScale → RefreshAuras → Layout → GetScaledRect.
	if string.sub(lower, 1, 9) == "nameplate" then
		if Client.isEra or Client.isAnniversary then
			return false
		end
		if Client.isRetail and Client.isPostDF == false then
			return false
		end
		return true
	end

	-- CUF raid/arena Options CVars: block on post-DF retail only.
	if Client.isRetail and Client.isPostDF then
		if string.sub(lower, 1, 10) == "raidframes"
			or string.sub(lower, 1, 9) == "pvpframes"
			or lower == "usecompactpartyframes"
			or lower == "raidoptiondisplaymaintankandassist"
			or lower == "raidoptiondisplaypets"
			or lower == "pvpoptiondisplaypets" then
			return true
		end
	end

	return false
end

function CVar.IsBlocked(cvar)
	return IsBlocked(cvar)
end

--- Forever/post-DF: raw SetCVar("nameplate*") is blocked (aura Layout taint).
--- nameplateThreatDisplay bits are safe: NamePlateUnitFrameMixin:UpdateThreatDisplay
--- does not walk AurasFrame.
function CVar.IsThreatBitfieldCVar(cvar)
	return type(cvar) == "string" and string.lower(cvar) == "nameplatethreatdisplay"
end

function CVar.SetBitfield(cvar, index, enabled)
	if InCombatLockdown and InCombatLockdown() then
		return false
	end
	if type(cvar) ~= "string" or index == nil then
		return false
	end
	if IsBlocked(cvar) and not CVar.IsThreatBitfieldCVar(cvar) then
		return false
	end
	local setBit = (C_CVar and C_CVar.SetCVarBitfield) or SetCVarBitfield
	if not setBit then
		return false
	end
	local ok = pcall(setBit, cvar, index, enabled and true or false)
	return ok and true or false
end

function CVar.Get(cvar)
	if C_CVar and C_CVar.GetCVar then
		return C_CVar.GetCVar(cvar)
	elseif GetCVar then
		return GetCVar(cvar)
	end
	return nil
end

function CVar.GetDefault(cvar)
	if C_CVar and C_CVar.GetCVarDefault then
		return C_CVar.GetCVarDefault(cvar)
	elseif GetCVarDefault then
		return GetCVarDefault(cvar)
	end
	return nil
end

function CVar.GetBool(cvar)
	if C_CVar and C_CVar.GetCVarBool then
		return C_CVar.GetCVarBool(cvar)
	end
	local v = CVar.Get(cvar)
	return v == "1" or v == 1 or v == true
end

function CVar.Set(cvar, value)
	if InCombatLockdown and InCombatLockdown() then
		return false
	end
	if IsBlocked(cvar) then
		return false
	end
	if C_CVar and C_CVar.SetCVar then
		local ok = pcall(C_CVar.SetCVar, cvar, value)
		return ok
	elseif SetCVar then
		local ok = pcall(SetCVar, cvar, value)
		return ok
	end
	return false
end
