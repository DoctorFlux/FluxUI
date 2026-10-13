-- RetailSecrets.lua — specialization-role helpers (all clients).
-- Blizzard UnitUtil.IsPlayerEffectivelyTank calls GetSpecializationRole when
-- UnitGroupRolesAssigned is NONE. On Classic Era / Anniversary that global is an
-- unsupported stub and errors in CompactUnitFrame_UpdateAggroFlash (nameplate OnEvent).
--
-- NEVER replace PlayerUtil.IsPlayerEffectivelyTank — nameplate SetUnit calls it from
-- UpdateHealthBorder / UpdateAggroHighlight while in a group; an addon replacement
-- taints the rest of SetUnit → AurasFrame:SetUnit → Layout → GetScaledRect.
--
-- Only replace _G.GetSpecializationRole when a probe shows it missing/erroring.
-- Solo SetUnit does not call GetSpecializationRole (aggro flash first-pass + not in
-- party), so the OnEvent threat path can use the shim without poisoning aura Layout.
-- Flux-owned callers should use the Safe helpers below.
local addonName, ns = ...
local H = ns._FluxAPICompat
local _pcall = H.pcall
local _type = H.type

local blizzardGetSpecializationRole = rawget(_G, "GetSpecializationRole")
local compatInstalled = false

function ns.API.GetSpecializationRoleSafe(specIndex, isInspect, isPet)
    if not specIndex then
        return nil
    end
    isInspect = isInspect or false
    isPet = isPet or false

    if C_SpecializationInfo and _type(C_SpecializationInfo.GetSpecializationInfo) == "function" then
        local ok, _id, _name, _desc, _icon, role = _pcall(
            C_SpecializationInfo.GetSpecializationInfo, specIndex, isInspect, isPet)
        if ok and role then
            return role
        end
    end

    if _type(GetSpecializationInfo) == "function" then
        local ok, _id, _name, _desc, _icon, role = _pcall(
            GetSpecializationInfo, specIndex, isInspect, isPet)
        if ok and role then
            return role
        end
    end

    if _type(blizzardGetSpecializationRole) == "function" then
        local ok, role = _pcall(blizzardGetSpecializationRole, specIndex, isInspect, isPet)
        if ok and role then
            return role
        end
    end

    return nil
end

function ns.API.IsPlayerEffectivelyTankSafe()
    if _type(UnitGroupRolesAssigned) == "function" then
        local ok, role = _pcall(UnitGroupRolesAssigned, "player")
        if ok and role and role ~= "NONE" then
            return role == "TANK"
        end
    end
    local spec
    if C_SpecializationInfo and _type(C_SpecializationInfo.GetSpecialization) == "function" then
        local ok, s = _pcall(C_SpecializationInfo.GetSpecialization)
        if ok then
            spec = s
        end
    elseif _type(GetSpecialization) == "function" then
        local ok, s = _pcall(GetSpecialization)
        if ok then
            spec = s
        end
    end
    return (spec and ns.API.GetSpecializationRoleSafe(spec) == "TANK") or false
end

local function NativeGetSpecializationRoleBroken()
    local fn = blizzardGetSpecializationRole
    if _type(fn) ~= "function" then
        return true
    end
    local ok = _pcall(fn, 1)
    return not ok
end

--- Install GetSpecializationRole only when the native API errors/missing.
--- Does not touch PlayerUtil (see file header).
--- Never install on retail: a false-positive probe would taint nameplate SetUnit →
--- Settings preview SimulateCast / aura Layout under _FluxUI.
function ns.API.FluxInstallSpecializationRoleCompat()
    if compatInstalled then
        return true
    end
    if FLUX_API and FLUX_API.isRetail then
        return false
    end
    if not NativeGetSpecializationRoleBroken() then
        return false
    end

    local safeRole = ns.API.GetSpecializationRoleSafe
    _G.GetSpecializationRole = function(specIndex, isInspect, isPet)
        return safeRole(specIndex, isInspect, isPet)
    end

    compatInstalled = true
    return true
end

ns.API.FluxInstallSpecializationRoleCompat()
