-- Client.lua — WOW_PROJECT and version flags (modern clients only)
local addonName, ns = ...
local H = ns._FluxAPICompat
local _tonumber = H.tonumber

local FluxClient = ns.Flux and ns.Flux.Client
local isAnniversary = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isTBC = isAnniversary
local isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local isCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
local isMists = (WOW_PROJECT_MISTS_CLASSIC ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)
local isClassicEra = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local isAnyClassicProject = isClassicEra or isTBC or isWrath or isCata or isMists

local majorVersion = 12
local minorVersion = 0
local buildNumber = 0
local uiVersion = 0

if GetBuildInfo then
    local version, build, _date, tocVersion = GetBuildInfo()
    if version then
        majorVersion = _tonumber(version:match("^(%d+)")) or 12
        minorVersion = _tonumber(version:match("^%d+%.(%d+)")) or 0
    end
    buildNumber = _tonumber(build) or 0
    uiVersion = tocVersion or 0
end

-- Trust Core\Client.lua. Do not OR CharacterStatsPaneScrollBox: that frame is
-- Forever-only in wow-ui-source-forever, but a 12.x live client must stay live
-- so per-rank spellbook features stay off.
local isCamelot
if FluxClient and FluxClient.isCamelot ~= nil then
    isCamelot = FluxClient.isCamelot == true
else
    local tocCamelot = ns._isCamelotGameType == true
    local foreverTimer = C_Timer and type(C_Timer.NewTimedSignalMap) == "function"
    local foreverStatsPane = rawget(_G, "CharacterStatsPaneScrollBox") ~= nil
        and rawget(_G, "CharacterStatsPanePetScrollBox") ~= nil
    local foreverBuild = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) and majorVersion > 0 and majorVersion < 10
    isCamelot = tocCamelot
        or foreverBuild
        or (majorVersion < 12 and (foreverTimer or foreverStatsPane))
end
isCamelot = isCamelot and not isAnyClassicProject
local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) or isCamelot

ns.IsRetail = isRetail
ns.IsWrath = isWrath
ns.IsClassic = isClassicEra
ns.IsCata = isCata
ns.IsMists = isMists
ns.IsAnniversary = isAnniversary
ns.IsTBC = isTBC

local isPreDF = (majorVersion < 10) and not isCamelot
local isPostDF = (majorVersion >= 10) or isCamelot
local isV12 = majorVersion >= 12
local isMidnight = isV12 or isCamelot

local hasModernAPIs = (C_Timer ~= nil) or isPostDF
local isLegacyClient = not hasModernAPIs and not isCamelot and majorVersion < 10
local isModernClient = not isLegacyClient

ns.API.isV12 = isV12
ns.API.isMidnight = isMidnight
ns.API.isRetail = isRetail
ns.API.isAnniversary = isAnniversary
ns.API.isTBC = isTBC
ns.API.majorVersion = majorVersion
ns.API.minorVersion = minorVersion
ns.API.isPreDF = isPreDF
ns.API.isPostDF = isPostDF
ns.API.useAccountWideGoldLedger = isRetail and isPostDF
ns.API.hasBlizzardObjectiveTrackerScroll = isRetail and isPostDF

FLUX_API.isRetail = isRetail
FLUX_API.isCamelot = isCamelot
FLUX_API.isForever = isCamelot
FLUX_API.isLiveMidnight = isRetail and not isCamelot and isV12
FLUX_API.gameType = isCamelot and "camelot" or (isAnyClassicProject and "classic" or "live")
FLUX_API.isAnniversary = isAnniversary
FLUX_API.isWrath = isWrath
FLUX_API.isCata = isCata
FLUX_API.isMists = isMists
FLUX_API.isClassic = isClassicEra
FLUX_API.isClassicEra = isClassicEra
FLUX_API.isTBC = isTBC
do
	local hasLowRank = C_SpellBook and type(C_SpellBook.IsSpellBookItemLowRank) == "function"
	if isCata or isMists or (isRetail and not isCamelot and isV12) then
		FLUX_API.supportsPerRankSpellBarFeatures = false
	elseif isClassicEra or isTBC or isWrath then
		FLUX_API.supportsPerRankSpellBarFeatures = true
	else
		FLUX_API.supportsPerRankSpellBarFeatures = hasLowRank == true
	end
end
FLUX_API.majorVersion = majorVersion
FLUX_API.minorVersion = minorVersion
FLUX_API.buildNumber = buildNumber
FLUX_API.uiVersion = uiVersion
FLUX_API.isPreDF = isPreDF
FLUX_API.isPostDF = isPostDF
FLUX_API.useAccountWideGoldLedger = isRetail and isPostDF
FLUX_API.isLegacyClient = isLegacyClient
FLUX_API.isModernClient = isModernClient
FLUX_API.hasModernAPIs = hasModernAPIs
FLUX_API.isAnyClassic = isClassicEra or isTBC or isWrath or isCata or isMists
FLUX_API.isClassicProgression = FLUX_API.isAnyClassic
FLUX_API.isWOTLK = isWrath
FLUX_API.isDF = isPostDF and majorVersion >= 10 and majorVersion < 11
FLUX_API.isTWW = majorVersion >= 11 and majorVersion < 12
FLUX_API.isMidnight = isMidnight
FLUX_API.isV12 = isV12
FLUX_API.versionString = GetBuildInfo and GetBuildInfo() or "unknown"
FLUX_API.isPrivateServer = false
FLUX_API.isHardcoreServer = false
FLUX_API.isSeasonOfDiscovery = false
FLUX_API.isPlunderstorm = false
FLUX_API.battlefieldMapScalingEnabled = isRetail and isPostDF

if isCamelot then
    FLUX_API.expansion = "Forever"
elseif isRetail then
    if majorVersion >= 12 then
        FLUX_API.expansion = "Midnight"
    elseif majorVersion >= 11 then
        FLUX_API.expansion = "The War Within"
    elseif majorVersion >= 10 then
        FLUX_API.expansion = "Dragonflight"
    else
        FLUX_API.expansion = "Retail"
    end
elseif isMists then
    FLUX_API.expansion = "Mists of Pandaria Classic"
elseif isCata then
    FLUX_API.expansion = "Cataclysm Classic"
elseif isWrath then
    FLUX_API.expansion = "Wrath Classic"
elseif isTBC then
    FLUX_API.expansion = "TBC Classic"
elseif isClassicEra then
    FLUX_API.expansion = "Classic Era"
else
    FLUX_API.expansion = "Unknown"
end

local GetAddOnMetadataCompat = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
do
    local addonVer = GetAddOnMetadataCompat and GetAddOnMetadataCompat(addonName, "Version")
    if (not addonVer or addonVer == "") and addonName ~= "_FluxUI" then
        addonVer = GetAddOnMetadataCompat and GetAddOnMetadataCompat("_FluxUI", "Version")
    end
    FLUX_API.addonVersion = (addonVer and addonVer ~= "") and addonVer or nil
end

-- Stash client locals for modules that run before FLUX_API is fully populated.
H.isRetail = isRetail
H.isCamelot = isCamelot
H.isForever = isCamelot
H.isLiveMidnight = isRetail and not isCamelot and isV12
H.isAnniversary = isAnniversary
H.isTBC = isTBC
H.isWrath = isWrath
H.isCata = isCata
H.isMists = isMists
H.isClassicEra = isClassicEra
H.majorVersion = majorVersion
H.minorVersion = minorVersion
H.buildNumber = buildNumber
H.uiVersion = uiVersion
H.isPreDF = isPreDF
H.isPostDF = isPostDF
H.isV12 = isV12
H.isLegacyClient = isLegacyClient
H.hasModernAPIs = hasModernAPIs
