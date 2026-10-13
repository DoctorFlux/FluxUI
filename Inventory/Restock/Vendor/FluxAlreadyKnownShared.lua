--[[
    FluxAlreadyKnownShared.lua
    Built-in AlreadyKnown integration for FluxUI vendor/restock.
    Based on AlreadyKnown by Sanex (see AlreadyKnown/LICENSE.txt).
]]

FluxAlreadyKnown = FluxAlreadyKnown or {}
local AK = FluxAlreadyKnown

local function RestockTable()
    if FluxRestockSettings and FluxRestockSettings.Get then
        return FluxRestockSettings.Get()
    end
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    _FluxUI_CharSavedVars.Restock = _FluxUI_CharSavedVars.Restock or {}
    return _FluxUI_CharSavedVars.Restock
end

function AK.GetSettings()
    local restock = RestockTable()
    restock.alreadyKnown = restock.alreadyKnown or {}
    local db = restock.alreadyKnown
    if db.enabled == nil then db.enabled = true end
    if db.r == nil then db.r = 0 end
    if db.g == nil then db.g = 1 end
    if db.b == nil then db.b = 0 end
    if db.monochrome == nil then db.monochrome = false end
    if db.debug == nil then db.debug = false end
    if db.exclude == nil then db.exclude = false end
    return db
end

function AK.IsStandaloneLoaded()
    return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("AlreadyKnown")
end

function AK.ShouldRun()
    if AK.IsStandaloneLoaded() then
        return false
    end
    local db = AK.GetSettings()
    return db.enabled ~= false
end

function AK.IsEnabled()
    return AK.ShouldRun()
end

function AK.IsItemKnown(itemLink)
    if not itemLink or not AK.ShouldRun() then
        return false
    end
    local fn = AK._checkIfKnown
    return fn and fn(itemLink) or false
end

function AK.ClearKnownCache()
    if AK._knownTable then
        wipe(AK._knownTable)
    end
end

function AK.MigrateLegacySettings()
    if AK._legacyMigrated then
        return
    end
    AK._legacyMigrated = true
    local legacy = _G.AlreadyKnownSettings
    if type(legacy) ~= "table" then
        return
    end
    local db = AK.GetSettings()
    for _, key in ipairs({ "r", "g", "b", "monochrome", "debug", "exclude" }) do
        if legacy[key] ~= nil and db[key] == nil then
            db[key] = legacy[key]
        end
    end
    db._migratedFromStandalone = true
end

function AK.NotifySettingsChanged()
    if AK.RefreshMerchant then
        pcall(AK.RefreshMerchant)
    end
    if AK.RefreshAuctionHouse then
        pcall(AK.RefreshAuctionHouse)
    end
    if AK.RefreshGuildBank then
        pcall(AK.RefreshGuildBank)
    end
end

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
    AK.MigrateLegacySettings()
end)

_G.FluxAlreadyKnown = AK

