-- CVars.lua — safe CVar access (modern clients only)
local addonName, ns = ...

-- SoftTargetEnemy / cast-bar preview CVars on retail can re-enter NamePlateDriver under _FluxUI.
-- softTargetInteract (Enable Interact Key) is allowed — Controls pack needs it.
-- nameplate* writes are allowed here on Era / Anniversary / pre-DF retail only. The Flux
-- nameplate pack writes through BlizzardSettings/Write.lua on every client.
-- Post-DF SetCVar re-enters nameplate aura Layout (GetScaledRect).
-- raidFrames*/pvpFrames* on post-DF retail: SetCVar → CompactUnitFrameProfiles:ApplyCurrentSettings
-- under _FluxUI, poisoning RaidFrameSettingsPreviewFrame health colors (secret oldR compare).
local function IsBlizzardNameplateCoupledCVarBlocked(cvar)
    if type(cvar) ~= "string" then
        return false
    end
    local lower = string.lower(cvar)
    local api = FLUX_API

    -- Action targeting + cast-bar preview: block on retail only.
    if lower == "softtargetenemy"
        or lower == "showenemycastbar"
        or lower == "showtargetcastbar" then
        if api and (api.isClassicEra or api.isAnniversary) then
            return false
        end
        return true
    end

    -- Other softTarget* (e.g. softTargetInteract) allowed everywhere.

    -- nameplate*: Era / Anniversary / pre-DF pack only. Post-DF retail blocked.
    if string.sub(lower, 1, 9) == "nameplate" then
        if api and (api.isClassicEra or api.isAnniversary) then
            return false
        end
        if api and api.isRetail and api.isPostDF == false then
            return false
        end
        return true
    end

    -- CUF raid/arena Options CVars: block on post-DF retail only.
    if api and api.isRetail and api.isPostDF then
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

_G.FluxGetCVar = function(cvar)
    if C_CVar and C_CVar.GetCVar then
        return C_CVar.GetCVar(cvar)
    elseif GetCVar then
        return GetCVar(cvar)
    end
    return nil
end

_G.FluxGetCVarDefault = function(cvar)
    if C_CVar and C_CVar.GetCVarDefault then
        return C_CVar.GetCVarDefault(cvar)
    elseif GetCVarDefault then
        return GetCVarDefault(cvar)
    end
    return nil
end

_G.FluxSetCVar = function(cvar, value)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    if IsBlizzardNameplateCoupledCVarBlocked(cvar) then
        return false
    end
    if C_CVar and C_CVar.SetCVar then
        local success = pcall(C_CVar.SetCVar, cvar, value)
        return success
    elseif SetCVar then
        local success = pcall(SetCVar, cvar, value)
        return success
    end
    return false
end
