-- Binding/Boot.lua
-- Kernel login boot: prepare bindings immediately; the coalesced Apply pipeline
-- checks lockdown at execution and resumes its secure writes after regen.

local addonName, ns = ...

local booted = false
local Flux = ns.Flux
local ev = CreateFrame("Frame")

local function Boot()
    if booted then return end
    local DB = ns.FluxBindingDB3
    if DB then DB.Ensure() end
    local Eng = ns.FluxBindingEngraving
    if Eng then
        if Eng.Refresh then Eng.Refresh() end
        if Eng.MigrateBindingDB then Eng.MigrateBindingDB() end
    end
    local Conditions = ns.FluxBindingConditions
    if Conditions then
        Conditions.EnsureInventoryListener()
        local Lib = ns.FluxBindingSpellLibrary
        if Lib and Lib.SeedPetAbilitiesFromBindings then
            Lib.SeedPetAbilitiesFromBindings()
        end
        Conditions.DiffAvailability() -- prime the availability cache
    end
    if _G.FluxBinding and _G.FluxBinding.RequestApplyAll then
        _G.FluxBinding.RequestApplyAll("boot")
    end
    -- Leave retries armed if any initializer above raises an error.
    booted = true
    ev:UnregisterAllEvents()
    ev:SetScript("OnEvent", nil)
end

-- A failed boot can retry on a later world/regen event without allocating a
-- timer loop or marking partially initialized bindings as complete.
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function()
    if not Flux or Flux.loggedIn then
        Boot()
    end
end)

if Flux and Flux.AfterLogin then
    Flux.AfterLogin(Boot)
else
    ev:RegisterEvent("PLAYER_LOGIN")
end
