-- lua tests/raid_nameplate_defaults.lua
-- First-login Classic raid profile completion and old nameplate-size migration.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function read(path)
    local file = assert(io.open(root .. path, "r"))
    local source = file:read("*a")
    file:close()
    return source
end
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end

do
    local loaded, active = false, ""
    local values, profileOptions = {}, {}
    local applyCount = 0
    local write = {
        MayUseSettingsAPI = function() return true end,
        CVar = function(cvar, value) values[cvar] = value; return true end,
        SetSetting = function() end,
        Notify = function() end,
        Run = function(_, fn) applyCount = applyCount + 1; return fn() end,
    }
    local env = {
        HasLoadedCUFProfiles = function() return loaded end,
        GetActiveRaidProfile = function() return active end,
        RaidProfileExists = function(profile) return profile == "My Profile" end,
        SetRaidProfileOption = function(_, key, value) profileOptions[key] = value end,
        CompactRaidFrameManager_SetSetting = function() end,
    }
    env._G = env
    setmetatable(env, { __index = _G })
    local ns = { Flux = { BlizzardSettings = { Write = write } } }
    assert(load(read("BlizzardSettings/Raid.lua"), "raid defaults", "t", env))("_FluxUI", ns)
    local raid = ns.Flux.BlizzardSettings.Raid
    raid.Apply(true)
    check(raid.profilePending and next(profileOptions) == nil,
        "profile remains pending while native profiles are not loaded")
    loaded = true
    raid.OnProfilesLoaded()
    check(raid.profilePending and next(profileOptions) == nil,
        "missing active profile is not treated as a successful write")
    active = "My Profile"
    raid.OnProfilesLoaded()
    check(not raid.profilePending and profileOptions.displayPowerBar
        and profileOptions.useClassColors and profileOptions.frameHeight == 36
        and profileOptions.frameWidth == 72, "loaded profile receives intended native raid options")
    check(applyCount == 3 and values.raidFramesDisplayPowerBars == "1",
        "profile completion reapplies the full native CVar pack")
    raid.OnProfilesLoaded()
    check(applyCount == 3, "completed profile is not replayed")
    profileOptions = {}
    env.FluxRaid_IsFluxRaidEnabled = function() return true end
    raid.profilePending = true
    raid.OnProfilesLoaded()
    check(profileOptions.frameHeight == 36 and profileOptions.frameWidth == 72
        and profileOptions.keepGroupsTogether == nil,
        "native frame size applies while Flux raid frames own the visible layout")
end

local source = read("FluxDefaultSettings.lua")
do
    local firstRetry = assert(source:find("local function FluxFinishPendingRaidProfile(attempt)", 1, true))
    local lastRetry = assert(source:find('frame:SetScript("OnEvent"', firstRetry, true))
    local callbacks, attempts = {}, 0
    local raid = { profilePending = true }
    raid.OnProfilesLoaded = function()
        attempts = attempts + 1
        if attempts == 2 then raid.profilePending = false end
    end
    local env = { BlizzardSettings = { Raid = raid },
        C_Timer = { After = function(delay, callback)
            callbacks[#callbacks + 1] = { delay, callback }
        end } }
    setmetatable(env, { __index = _G })
    local retry = assert(load(source:sub(firstRetry, lastRetry - 1)
        .. "\nreturn FluxFinishPendingRaidProfile", "raid world-entry retry", "t", env))()
    retry(1)
    check(attempts == 1 and #callbacks == 1 and callbacks[1][1] == 1,
        "first world-entry retry waits for a late native raid profile")
    callbacks[1][2]()
    check(attempts == 2 and not raid.profilePending and #callbacks == 1,
        "world-entry retry completes once the active profile appears")
end

local first = assert(source:find("function FluxDefaultSettings.EnsureNameplateSizeMedium()", 1, true))
local last = assert(source:find("function FluxDefaultSettings.ScheduleRaidArenaFrameDefaultsPack", first, true))
local code = source:sub(first, last - 1)
local function migrationFixture(current, deferred, fail)
    local db, writes, queued = {}, 0, nil
    local write = {
        Get = function() return current end,
        Matches = function(_, value) return current == value end,
        CVar = function(_, value)
            writes = writes + 1
            if fail then return false end
            current = value
            return true
        end,
        Run = function(_, fn)
            if deferred then queued = fn; return false end
            return fn()
        end,
    }
    local env = { FluxUI_DB = db, FluxDefaultSettings = {},
        BlizzardSettings = { Write = write } }
    setmetatable(env, { __index = _G })
    assert(load(code, "nameplate size migration", "t", env))()
    return env, db, function() return writes end, function() return queued end,
        function() return current end
end

do
    local env, db, writes, _, value = migrationFixture("3")
    check(env.FluxDefaultSettings.EnsureNameplateSizeMedium() and value() == "2"
        and writes() == 1 and db.nameplateSizeDefaultV2,
        "old Large default changes to Medium once")
    env.FluxDefaultSettings.EnsureNameplateSizeMedium()
    check(writes() == 1, "completed migration does not replay")
end
do
    local env, db, writes = migrationFixture("4")
    check(env.FluxDefaultSettings.EnsureNameplateSizeMedium() and writes() == 0
        and db.nameplateSizeDefaultV2, "custom nameplate size is retained")
end
do
    local env, db, writes, queued, value = migrationFixture("3", true)
    check(not env.FluxDefaultSettings.EnsureNameplateSizeMedium()
        and not db.nameplateSizeDefaultV2 and writes() == 0,
        "deferred write does not mark migration complete")
    check(queued()() and value() == "2" and db.nameplateSizeDefaultV2,
        "deferred write finishes the migration")
end
do
    local env, db = migrationFixture("3", false, true)
    check(not env.FluxDefaultSettings.EnsureNameplateSizeMedium()
        and not db.nameplateSizeDefaultV2, "failed nameplate write remains retryable")
end

local nameplates = read("BlizzardSettings/Nameplates.lua")
local packValue = assert(nameplates:match('nameplateSize%s*=%s*"(%d+)"'))
local templateValue = assert(source:match('%["nameplateSize"%]%s*=%s*"(%d+)"'))
check(packValue == "2" and templateValue == "2",
    "first-account and nameplate pack both recommend Medium on all clients")

print("raid and nameplate defaults: " .. checks .. " checks passed")
