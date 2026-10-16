-- Client.lua — Era / Anniversary / Mists / Midnight (+ leftover Wrath/Cata flags)
local addonName, ns = ...
local Flux = ns.Flux

local tonumber = tonumber
local type = type
local rawget = rawget

local project = WOW_PROJECT_ID
local function IsProject(id)
	return id ~= nil and project == id
end

local isEra = IsProject(WOW_PROJECT_CLASSIC)
local isAnniversary = IsProject(WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isTBC = isAnniversary
local isWrath = IsProject(WOW_PROJECT_WRATH_CLASSIC)
local isCata = IsProject(WOW_PROJECT_CATACLYSM_CLASSIC)
local isMists = IsProject(WOW_PROJECT_MISTS_CLASSIC)
local isAnyClassicProject = isEra or isAnniversary or isWrath or isCata or isMists

local majorVersion = 12
local minorVersion = 0
local patchVersion = 0
local buildNumber = 0
local uiVersion = 0
local versionString = "unknown"

if GetBuildInfo then
	local version, build, _, tocVersion = GetBuildInfo()
	versionString = version or "unknown"
	if version then
		majorVersion = tonumber(version:match("^(%d+)")) or 12
		minorVersion = tonumber(version:match("^%d+%.(%d+)")) or 0
		patchVersion = tonumber(version:match("^%d+%.%d+%.(%d+)")) or 0
	end
	buildNumber = tonumber(build) or 0
	uiVersion = tocVersion or 0
end

-- Live Midnight vs Forever. Both can sit in Interface\AddOns under _retail_.
-- wow-ui-source-live CharacterFrame: CharacterStatsPane only.
-- wow-ui-source-forever CharacterFrame: CharacterStatsPaneScrollBox + Pet.
-- The Camelot module validates its runtime before setting its flag. Also bound
-- detection here: a stray TOC flag or similarly named widget/API cannot turn
-- a 12.x Retail build into Forever.
local tocCamelot = ns._isCamelotGameType == true
local foreverTimer = C_Timer and type(C_Timer.NewTimedSignalMap) == "function"
local foreverStatsPane = rawget(_G, "CharacterStatsPaneScrollBox") ~= nil
	and rawget(_G, "CharacterStatsPanePetScrollBox") ~= nil
local foreverBuild = IsProject(WOW_PROJECT_MAINLINE) and majorVersion > 0 and majorVersion < 10
local isCamelot = not isAnyClassicProject and majorVersion < 12 and (
	tocCamelot
	or foreverBuild
	or (majorVersion < 12 and (foreverTimer or foreverStatsPane))
)
-- Some modules read the namespace flag directly; keep it canonical as well.
ns._isCamelotGameType = isCamelot

local isRetail = IsProject(WOW_PROJECT_MAINLINE) or isCamelot

local isPreDF = (majorVersion < 10) and not isCamelot
local isPostDF = (majorVersion >= 10) or isCamelot
local isV12 = majorVersion >= 12
local isMidnight = (isRetail and isV12) or isCamelot
local isTWW = isRetail and majorVersion >= 11 and majorVersion < 12
local isDF = isRetail and isPostDF and majorVersion >= 10 and majorVersion < 11 and not isCamelot
local isLiveMidnight = isRetail and not isCamelot and isV12
local gameType = isCamelot and "camelot" or (isAnyClassicProject and "classic" or "live")

-- One product, four families. Mainline (including Forever/camelot) is midnight.
local flavor
if isRetail or isCamelot then
	flavor = "midnight"
elseif isMists or isCata or isWrath then
	flavor = "classic"
elseif isAnniversary then
	flavor = "anniversary"
elseif isEra then
	flavor = "era"
else
	flavor = "unknown"
end

local expansion
if isCamelot then
	expansion = "Forever"
elseif isRetail then
	if majorVersion >= 12 then
		expansion = "Midnight"
	elseif majorVersion >= 11 then
		expansion = "The War Within"
	elseif majorVersion >= 10 then
		expansion = "Dragonflight"
	else
		expansion = "Retail"
	end
elseif isMists then
	expansion = "Mists of Pandaria Classic"
elseif isCata then
	expansion = "Cataclysm Classic"
elseif isWrath then
	expansion = "Wrath Classic"
elseif isTBC then
	expansion = "TBC Classic"
elseif isEra then
	expansion = "Classic Era"
else
	expansion = "Unknown"
end

local Client = {
	flavor = flavor,
	expansion = expansion,
	isRetail = isRetail,
	isCamelot = isCamelot,
	isForever = isCamelot,
	isLiveMidnight = isLiveMidnight,
	gameType = gameType,
	isMidnight = isMidnight,
	isEra = isEra,
	isClassicEra = isEra,
	isAnniversary = isAnniversary,
	isTBC = isTBC,
	isWrath = isWrath,
	isCata = isCata,
	isMists = isMists,
	isClassic = isMists or isCata or isWrath,
	isAnyClassic = isEra or isAnniversary or isWrath or isCata or isMists,
	majorVersion = majorVersion,
	minorVersion = minorVersion,
	patchVersion = patchVersion,
	buildNumber = buildNumber,
	uiVersion = uiVersion,
	versionString = versionString,
	isPreDF = isPreDF,
	isPostDF = isPostDF,
	isV12 = isV12,
	isDF = isDF,
	isTWW = isTWW,
	hasModernAPIs = (C_Timer ~= nil) or isPostDF,
}

function Client.Is(name)
	return Client.flavor == name
end

--- spec.clients = { era=true, anniversary=true, classic=true, midnight=true }
function Client.Matches(clients)
	if type(clients) ~= "table" then
		return true
	end
	return clients[Client.flavor] == true
end

Flux.Client = Client
