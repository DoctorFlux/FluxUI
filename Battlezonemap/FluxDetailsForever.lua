-- FluxDetailsForever.lua
-- Forever (camelot, TOC 16001) makes Details take the Midnight path:
-- IsAddonApocalypseWow() is true, so StartMeUp skips COMBAT_LOG_EVENT_UNFILTERED
-- and refreshes bars from C_DamageMeter. Classic and Classic Era never do that.
-- This file runs at addon load, before PLAYER_LOGIN, and only touches FluxUI.
-- Details' private namespace (Details222) is not global; the load-bearing fix is
-- replacing the global DetailsFramework / Details methods StartMeUp calls.

local _, ns = ...

local Flux = ns.Flux
local Client = Flux and Flux.Client
if not (Client and (Client.isCamelot or Client.isForever)) then
    return
end

local Details = _G.Details
local DF = _G.DetailsFramework
if type(Details) ~= "table" or type(DF) ~= "table" then
    return
end

local Cap = Flux.Cap
if not (Cap and Cap.hasCombatLogUnfiltered) then
    -- Combat log is restricted. Leave damage and healing on the Blizzard meter.
    -- FluxThreat still installs on its own.
    return
end

local applied = false

local function FindDetailsPrivate()
    local direct = rawget(_G, "Details222")
    if type(direct) == "table" and type(direct.UpdateIsAllowed) == "function" then
        return direct
    end
    local found
    pcall(function()
        for key, value in pairs(Details) do
            if type(value) == "table" and type(value.UpdateIsAllowed) == "function" and type(value.StartUp) == "table" then
                found = value
                return
            end
            if key == "Details222" and type(value) == "table" then
                found = value
                return
            end
        end
    end)
    return found
end

local function TypeDetails()
    local privateNs = FindDetailsPrivate()
    local apocalypse = privateNs and privateNs.Apocalypse
    if type(apocalypse) == "table" and apocalypse.TypeDetails ~= nil then
        return apocalypse.TypeDetails
    end
    return 0
end

local function ReleasePossessedMeterWindows()
    for i = 1, 10 do
        local window = _G["DamageMeterSessionWindow" .. i]
        if window then
            local possessed = false
            pcall(function()
                local _, relative = window:GetPoint(1)
                local name = relative and relative.GetName and relative:GetName()
                if type(name) == "string" and name:find("DetailsBaseFrame", 1, true) then
                    possessed = true
                end
            end)
            if possessed then
                pcall(function()
                    local owner = window.GetDamageMeterOwner and window:GetDamageMeterOwner()
                    if owner and owner.HideSessionWindow then
                        owner:HideSessionWindow(window)
                    elseif window.Hide then
                        window:Hide()
                    end
                end)
            end
        end
    end
end

local function EnsureCombatLog()
    local privateNs = FindDetailsPrivate()
    local frame = privateNs and privateNs.parser_frame
    if not frame or not frame.RegisterEvent then
        return
    end
    if frame.IsEventRegistered and frame:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
        return
    end
    pcall(frame.RegisterEvent, frame, "COMBAT_LOG_EVENT_UNFILTERED")
end

local function PointInstancesAtDetailsData()
    local typeDetails = TypeDetails()
    local list = Details.tabela_instancias
    if type(list) ~= "table" then
        return
    end
    for i = 1, #list do
        local instance = list[i]
        if instance then
            if instance.SetApocalypseSourceType then
                pcall(instance.SetApocalypseSourceType, instance, typeDetails)
            else
                instance.source_type = typeDetails
            end
        end
    end
end

local function DisableMeterSwap()
    local privateNs = FindDetailsPrivate()
    local parser = privateNs and privateNs.BParser
    if type(parser) ~= "table" or parser._fluxForeverSwap then
        return
    end
    parser._fluxForeverSwap = true
    parser.UpdateDamageMeterSwap = function()
        Details.damage_meter_type = 0
        ReleasePossessedMeterWindows()
    end
end

local function ApplyAfterStartup()
    if applied or type(_G.Details) ~= "table" then
        return
    end
    if Details.InstallOkey and not Details:InstallOkey() then
        return
    end
    applied = true
    Details.damage_meter_type = 0
    DisableMeterSwap()
    ReleasePossessedMeterWindows()
    EnsureCombatLog()
    PointInstancesAtDetailsData()
end

-- StartMeUp calls these at PLAYER_LOGIN. Replace them now, while addon files
-- are still loading, so Details registers the classic combat-log parser.
if type(DF.IsAddonApocalypseWow) == "function" then
    DF.IsAddonApocalypseWow = function()
        return false
    end
end

function Details:IsUsingBlizzardAPI()
    return false
end

do
    local privateNs = FindDetailsPrivate()
    if privateNs then
        function privateNs.UpdateIsAllowed()
            return true
        end
        DisableMeterSwap()
    end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            local tries = 0
            local function tick()
                tries = tries + 1
                if Details.InstallOkey and Details:InstallOkey() then
                    ApplyAfterStartup()
                    return
                end
                if tries < 40 and C_Timer and C_Timer.After then
                    C_Timer.After(0.1, tick)
                else
                    ApplyAfterStartup()
                end
            end
            tick()
        end)
    else
        ApplyAfterStartup()
    end
end)

