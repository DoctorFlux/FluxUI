-- FluxDetailsForever.lua
-- Forever (camelot, TOC 16001) makes Details take the Midnight path:
-- IsAddonApocalypseWow() is true, so StartMeUp skips COMBAT_LOG_EVENT_UNFILTERED
-- and refreshes bars from C_DamageMeter. Classic and Classic Era never do that.
-- Installs at addon load or Details ADDON_LOADED, before its login startup.
-- Details' private namespace (Details222) is not global; the load-bearing fix is
-- replacing the global DetailsFramework / Details methods StartMeUp calls.

local _, ns = ...

local Flux = ns.Flux
local Client = Flux and Flux.Client
if not (Client and (Client.isCamelot or Client.isForever)) then
    return
end

local Details, DF
local installedFor
local postStartupScheduled = false

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
    if InCombatLockdown() then
        if Flux.Combat then Flux.Combat.Defer("details.forever", ApplyAfterStartup) end
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

local function InstallCompatibility()
    local cap = Flux.Cap
    if not (cap and cap.hasCombatLogUnfiltered) then return false end
    local candidate, framework = _G.Details, _G.DetailsFramework
    if type(candidate) ~= "table" or type(framework) ~= "table" then return false end
    if installedFor == candidate then return true end
    Details, DF = candidate, framework
    applied = false
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

    installedFor = candidate
    return true
end

local function ScheduleAfterStartup()
    if postStartupScheduled or not installedFor then return end
    postStartupScheduled = true
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
    if C_Timer and C_Timer.After then C_Timer.After(0, tick) else tick() end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= "Details" then return end
        -- Preserve the provider's own saved-profile restoration before patching.
        -- PLAYER_LOGIN below also installs synchronously before its After(0)
        -- startup, even if login arrives before this next-frame callback.
        C_Timer.After(0, function()
            if InstallCompatibility() and IsLoggedIn and IsLoggedIn() then ScheduleAfterStartup() end
        end)
        return
    end
    if not InstallCompatibility() then return end
    if event == "PLAYER_LOGIN" or (IsLoggedIn and IsLoggedIn()) then
        ScheduleAfterStartup()
    end
end)

-- Preserve pre-login patching when Details loaded first. When Flux loaded first,
-- Details' ADDON_LOADED occurs before its PLAYER_LOGIN -> After(0) StartMeUp.
-- Upstream parser.lua d1e8ad7226616b4a796eebc6ca3ed905ef410b64.
if InstallCompatibility() and IsLoggedIn and IsLoggedIn() then ScheduleAfterStartup() end
