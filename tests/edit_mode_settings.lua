-- Native CUF callbacks must never be entered by the central writer on secret
-- clients. These mocks check dispatch/data ownership, not WoW's taint VM.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local writeSource, raidSource = read("BlizzardSettings/Write.lua"), read("BlizzardSettings/Raid.lua")
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function exercise(branch, writer, raid)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local classic = branch ~= "live" and branch ~= "forever"
    local frames, callbacks, values, writes, profiles = {}, {}, { showTutorials = "1", unrelated = "0" }, {}, {}
    local combat, editing, nativeProfileCalls = false, false, 0
    env.FluxEditModeBusy = function() return editing end
    env.FluxAfterEditMode = function(fn) callbacks[fn] = fn end
    env.InCombatLockdown = function() return combat end
    env.CreateFrame = function()
        local frame = { events = {} }
        function frame:SetScript(_, fn) self.callback = fn end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        frames[#frames + 1] = frame; return frame
    end
    env.C_CVar = { GetCVar = function(key) return values[key] end, SetCVar = function(key, value)
        check(not combat and not editing, "CVar writes wait for combat and Edit Mode")
        writes[#writes + 1] = key; values[key] = value
    end }
    env.GetActiveRaidProfile = function() return "Existing player profile" end
    env.HasLoadedCUFProfiles = function() return true end
    env.SetRaidProfileOption = function(profile, key, value)
        nativeProfileCalls = nativeProfileCalls + 1
        check(classic, "secret clients never mutate native CUF profiles")
        check(profile == "Existing player profile", "existing profile retained")
        profiles[key] = value
    end
    local ns = { Flux = { Client = { isRetail = not classic, isPostDF = not classic, isAnyClassic = classic,
        isForever = branch == "forever", isCamelot = branch == "forever" } } }
    assert(load(writer or writeSource, "@BlizzardSettings/Write.lua", "t", env))("_FluxUI", ns)
    assert(load(raid or raidSource, "@BlizzardSettings/Raid.lua", "t", env))("_FluxUI", ns)
    local bs = ns.Flux.BlizzardSettings
    for _, entry in ipairs(bs.Raid.CVARS) do values[entry[1]] = "existing" end
    editing = true; bs.Raid.Apply(true)
    check(#writes == 0 and next(profiles) == nil, "Edit Mode queues all native settings work")
    editing = false; combat = true
    for _, fn in pairs(callbacks) do fn() end
    check(#writes == 0, "combat beginning before exit keeps native work queued")
    combat = false; bs.Write.Flush()
    check(classic or nativeProfileCalls == 0, "secret clients never dispatch native CUF profile callbacks")
    check(values.showTutorials == "0", "safe tutorial setting still applies")
    for _, entry in ipairs(bs.Raid.CVARS) do
        check(values[entry[1]] == (classic and entry[2] or "existing"),
            branch .. ": native CUF defaults follow client callback safety policy: " .. entry[1])
        if not classic then
            check(not bs.Write.CVar(entry[1]:upper(), entry[2], true), "forced/case-variant CUF writes cannot bypass guard")
        end
    end
    check(bs.Write.CVar("unrelated", "1") and values.unrelated == "1", "unrelated CVar functionality retained")
    check(next(profiles) ~= nil == classic, "Classic profile defaults retained; modern native profile untouched")
    local count = #writes; bs.Write.Flush()
    check(#writes == count, "queued settings apply exactly once")
    if classic then
        check(profiles.displayPowerBar and profiles.useClassColors and profiles.healthText == "perc"
            and profiles.frameHeight == 36 and profiles.frameWidth == 72, "all Classic raid/profile layout defaults retained")
    end
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do exercise(branch) end
local unsafeWriter, n = writeSource:gsub('if Write.IsSecretClient%(%) and IsCompactFrameCVar%(cvar%) then return false end', '', 1)
check(n == 1, "central writer negative-control anchor exists")
local ok, err = pcall(exercise, "live", unsafeWriter)
check(not ok and tostring(err):find("native CUF defaults follow", 1, true), "negative control detects unsafe central CVar writer")
local unsafeRaid, m = raidSource:gsub('if not Write.MayUseSettingsAPI%(%) then return false end', '', 1)
check(m == 1, "native profile negative-control anchor exists")
-- Raid.ApplyProfile uses pcall; verify the assertions through a direct profile
-- side effect as well, so a swallowed native callback failure cannot pass.
ok, err = pcall(exercise, "forever", nil, unsafeRaid)
check(not ok and tostring(err):find("secret clients never dispatch native CUF profile callbacks", 1, true),
    "negative control detects unsafe native profile dispatch")
print("Edit Mode settings: " .. checks .. " checks across five clients; two negative controls passed")
