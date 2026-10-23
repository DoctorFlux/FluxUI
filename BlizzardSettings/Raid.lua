-- BlizzardSettings/Raid.lua — tutorials off and Flux's raid / arena frame defaults.
-- Native compact-frame defaults apply only where their callbacks can safely run.
-- Settings.SetValue / NotifyUpdate and the raid manager run only where secrets
-- are not enforced (Classic clients). Flux's own raid options are independent.
local addonName, ns = ...
local Flux = ns.Flux
local BS = Flux.BlizzardSettings
local Write = BS.Write

local Raid = {}
BS.Raid = Raid

--- { cvar, cvarValue, settingValue }
Raid.CVARS = {
	{ "useCompactPartyFrames", "1", true },
	{ "raidFramesDisplayPowerBars", "1", true },
	{ "raidFramesDisplayClassColor", "1", true },
	{ "raidFramesHealthText", "perc", "perc" },
	{ "raidFramesDisplayIncomingHeals", "1", true },
	{ "raidFramesDisplayDebuffs", "1", true },
	{ "raidFramesDisplayBuffs", "1", true },
	{ "raidFramesDisplayOnlyDispellableDebuffs", "1", true },
	{ "raidFramesFadeOutOfRange", "1", true },
	{ "raidFramesDisplayInOtherPhase", "1", true },
	{ "raidOptionDisplayMainTankAndAssist", "1", true },
	{ "raidOptionDisplayPets", "0", false },
	{ "raidFramesDisplayOnlyHealerPowerBars", "0", false },
	{ "raidFramesDisplayAggroHighlight", "1", true },
	{ "raidFramesDisplayLargerRoleSpecificDebuffs", "1", true },
	{ "raidFramesCenterBigDefensive", "1", true },
	{ "pvpFramesDisplayPowerBars", "1", true },
	{ "pvpFramesDisplayClassColor", "1", true },
	{ "pvpFramesHealthText", "perc", "perc" },
	{ "pvpFramesDisplayOnlyHealerPowerBars", "0", false },
	{ "pvpOptionDisplayPets", "0", false },
}

local function IsFluxRaidEnabled()
	return _G.FluxRaid_IsFluxRaidEnabled and _G.FluxRaid_IsFluxRaidEnabled() and true or false
end

local function ProfilesLoaded()
	if not HasLoadedCUFProfiles then
		return true
	end
	local ok, loaded = pcall(HasLoadedCUFProfiles)
	return ok and loaded and true or false
end

function Raid.ApplyTutorials()
	local wrote = Write.CVar("showTutorials", "0")
	Write.SetSetting("showTutorials", false)
	Write.Notify("showTutorials")
	return wrote
end

function Raid.ApplyProfile()
	if not Write.MayUseSettingsAPI() then return false end
	if not (SetRaidProfileOption and GetActiveRaidProfile) then
		return false
	end
	if not ProfilesLoaded() then
		Raid.profilePending = true
		return false
	end
	Raid.profilePending = false
	local ok = pcall(function()
		local profile = GetActiveRaidProfile()
		if not profile or profile == "" then
			return
		end
		if RaidProfileExists and not RaidProfileExists(profile) then
			return
		end
		SetRaidProfileOption(profile, "displayPowerBar", true)
		SetRaidProfileOption(profile, "useClassColors", true)
		SetRaidProfileOption(profile, "healthText", "perc")
		SetRaidProfileOption(profile, "displayNonBossDebuffs", true)
		SetRaidProfileOption(profile, "displayOnlyDispellableDebuffs", true)
		pcall(SetRaidProfileOption, profile, "displayHealPrediction", true)
		if not IsFluxRaidEnabled() then
			SetRaidProfileOption(profile, "keepGroupsTogether", true)
			SetRaidProfileOption(profile, "horizontalGroups", false)
			SetRaidProfileOption(profile, "frameHeight", 36)
			SetRaidProfileOption(profile, "frameWidth", 72)
			SetRaidProfileOption(profile, "displayPets", false)
			SetRaidProfileOption(profile, "displayMainTankAndAssist", true)
		end
	end)
	return ok
end

function Raid.ApplyNow(force)
	local wrote = Raid.ApplyTutorials()

	local notify = {}
	for _, entry in ipairs(Raid.CVARS) do
		if Write.CVar(entry[1], entry[2], force) then
			wrote = true
		end
		notify[#notify + 1] = entry[1]
	end

	if Write.MayUseSettingsAPI() then
		for _, entry in ipairs(Raid.CVARS) do
			Write.SetSetting(entry[1], entry[3])
		end
		Write.Notify(notify)

		if not IsFluxRaidEnabled() and CompactRaidFrameManager_SetSetting then
			pcall(function()
				CompactRaidFrameManager_SetSetting("KeepGroupsTogether", "1")
				CompactRaidFrameManager_SetSetting("HorizontalGroups", "0")
				CompactRaidFrameManager_SetSetting("DisplayPets", "0")
				CompactRaidFrameManager_SetSetting("DisplayMainTankAndAssist", "1")
				CompactRaidFrameManager_SetSetting("ShowBorders", "1")
			end)
		end
	end

	if Raid.ApplyProfile() then
		wrote = true
	end
	return wrote
end

--- Apply now, or queue until combat ends / Settings closes.
function Raid.Apply(force)
	return Write.Run("raid", function()
		return Raid.ApplyNow(force)
	end)
end

--- COMPACT_UNIT_FRAME_PROFILES_LOADED: finish a profile write that ran before profiles existed.
function Raid.OnProfilesLoaded()
	if Raid.profilePending then
		Write.Run("raidProfile", Raid.ApplyProfile)
	end
end
