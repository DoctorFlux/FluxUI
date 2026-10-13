-- Binding/Boot.lua
-- Login boot: ensure DB, wire FluxInv, first apply after the bar exists.

local addonName, ns = ...

local booted = false

local function Boot()
    if booted then return end
    booted = true
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
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    -- small delay: bar buttons + keybindings + FluxInv warmup land first
    if C_Timer and C_Timer.After then
        C_Timer.After(1.0, Boot)
    else
        Boot()
    end
end)

