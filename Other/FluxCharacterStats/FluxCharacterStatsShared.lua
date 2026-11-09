local addonName, ns = ...

ns.CharacterStats = ns.CharacterStats or {}

local module = ns.CharacterStats
local fluxAPI = rawget(_G, "FLUX_API") or {}

local versionString = GetBuildInfo and select(1, GetBuildInfo()) or ""
local detectedMajor = tonumber(type(versionString) == "string" and versionString:match("^(%d+)")) or 0

module.addonName = addonName
module.displayName = "FluxUI Character Stats"
module.settingsTitle = module.displayName
module.majorVersion = detectedMajor > 0 and detectedMajor or (fluxAPI.majorVersion or 0)

local Client = ns.Flux and ns.Flux.Client
local _wowPid = rawget(_G, "WOW_PROJECT_ID")
local _wowMainline = rawget(_G, "WOW_PROJECT_MAINLINE")
local _wowClassic = rawget(_G, "WOW_PROJECT_CLASSIC")
local _wowBcc = rawget(_G, "WOW_PROJECT_BURNING_CRUSADE_CLASSIC")
local _wowWrath = rawget(_G, "WOW_PROJECT_WRATH_CLASSIC")
local isCamelot = (Client and Client.isCamelot) or ns._isCamelotGameType == true

-- Era is Classic Era project, not "version starts with 1" (Forever is 1.x mainline).
module.isClassicEra = (type(_wowPid) == "number" and type(_wowClassic) == "number" and _wowPid == _wowClassic)
    or (type(_wowPid) ~= "number" and module.majorVersion == 1 and not isCamelot)
module.isProgression = module.majorVersion == 2 or module.majorVersion == 3
-- Build string alone can mis-detect anniversary TBC; trust WOW_PROJECT_ID when present.
if type(_wowPid) == "number" then
    if type(_wowBcc) == "number" and _wowPid == _wowBcc then
        module.isProgression = true
        module.isClassicEra = false
    elseif type(_wowWrath) == "number" and _wowPid == _wowWrath then
        module.isProgression = true
        module.isClassicEra = false
    end
end
module.isRetail = type(_wowPid) == "number" and type(_wowMainline) == "number" and _wowPid == _wowMainline
if (Client and (Client.isRetail or Client.isCamelot)) or isCamelot or module.isRetail then
    module.isClassicEra = false
    module.isProgression = false
    module.isRetail = true
end
module.isSupported = module.isClassicEra or module.isProgression or module.isRetail
module.core = module.core or {}

local function EnsureStorage()
    FluxUI_DB = FluxUI_DB or {}
    FluxUI_DB.CharacterStats = FluxUI_DB.CharacterStats or {}

    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    _FluxUI_CharSavedVars.CharacterStats = _FluxUI_CharSavedVars.CharacterStats or {}

    return FluxUI_DB.CharacterStats, _FluxUI_CharSavedVars.CharacterStats
end

function module.GetModeKey()
    if module.isClassicEra then
        return "era"
    end
    if module.isRetail then
        return "retail"
    end

    return "progression"
end

function module.GetGlobalDB()
    local accountRoot = EnsureStorage()
    local modeKey = module.GetModeKey()

    accountRoot[modeKey] = accountRoot[modeKey] or {}
    accountRoot[modeKey].global = accountRoot[modeKey].global or {}

    return accountRoot[modeKey].global
end

function module.GetCharacterDB()
    local _, charRoot = EnsureStorage()
    local modeKey = module.GetModeKey()

    charRoot[modeKey] = charRoot[modeKey] or {}

    return charRoot[modeKey]
end

-- Coalesced next-frame refresh for CSC panel + FluxInfoFrame (UNIT_AURA / COMBAT_RATING_UPDATE bursts).
local statRefreshPending = false
local statRefreshFallbackFrame = nil

local function FlushPlayerStatRefresh()
    statRefreshPending = false

    local core = module.core
    if core and core.UIConfig then
        local lfgBlocked = (LFGListingFrame and LFGListingFrame:IsVisible())
            or (LFGListFrame and LFGListFrame:IsVisible())
        if not lfgBlocked then
            local panel = core.UIConfig.CharacterStatsPanel
            if panel and panel:IsVisible() then
                core.UIConfig:UpdateStats()
            end
        end
    end

    local info = rawget(_G, "FluxInfoFrame")
    if info and type(info._FlushPlayerStatRefresh) == "function" then
        info._FlushPlayerStatRefresh()
    end
end

function module.QueuePlayerStatRefresh()
    if statRefreshPending then
        return
    end
    statRefreshPending = true

    if C_Timer and C_Timer.After then
        C_Timer.After(0, FlushPlayerStatRefresh)
        return
    end

    if not statRefreshFallbackFrame then
        statRefreshFallbackFrame = CreateFrame("Frame")
    end
    statRefreshFallbackFrame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        FlushPlayerStatRefresh()
    end)
end

_G.FluxCSC_QueuePlayerStatRefresh = module.QueuePlayerStatRefresh
