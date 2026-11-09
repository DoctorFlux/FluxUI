-- Prove script ownership through object identity, rather than local variable names.
-- Also execute rejected mutants replacing every script-owner constructor with a native frame.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local checks, mutants = 0, 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end
local function read(path)
    local file = assert(io.open(root .. path, "r"))
    local source = file:read("*a"); file:close(); return source
end
local sources = { "BlizzardSettings/Write.lua", "BlizzardSettings/Nameplates.lua", "BlizzardSettings/Raid.lua",
    "Blizzard/Hide.lua", "NamePlates/Core.lua" }
local function run(branch, mutation)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local frames, timers, scripts = {}, {}, 0
    local locked = false
    local methods = {}
    local function frame(owned)
        local result = setmetatable({ owned = owned, scripts = {}, events = {}, shown = false }, { __index = methods })
        frames[#frames + 1] = result
        return result
    end
    function methods:SetScript(name, callback)
        if not self.owned then error("native frame SetScript forbidden", 0) end
        self.scripts[name] = callback
        scripts = scripts + 1
    end
    function methods:GetScript(name) return self.scripts[name] end
    function methods:HookScript(name, callback) self.hook = callback end
    function methods:RegisterEvent(name) self.events[name] = true end
    function methods:UnregisterEvent(name) self.events[name] = nil end
    function methods:UnregisterAllEvents() self.events = {} end
    function methods:IsShown() return self.shown end
    function methods:Hide() self.shown = false end
    function methods:Show() self.shown = true end
    function methods:SetAllPoints() end
    function methods:GetParent() return self.parent end
    function methods:SetParent(parent) self.parent = parent end
    function methods:IsProtected() return not self.owned end
    env.CreateFrame = function() return frame(true) end
    env.SettingsPanel, env.UIParent = frame(false), frame(false)
    env.SettingsPanel.shown = true
    env.InCombatLockdown = function() return locked end
    env.C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
    env.C_NamePlate = { GetNamePlates = function() return {} end }
    env.C_CVar = { GetCVar = function() return nil end }
    env.Enum = {}
    env.GetTime = function() return 0 end
    env.geterrorhandler = function() return function(err) error(err, 0) end end
    local classic = branch ~= "live" and branch ~= "forever"
    local ns = { Flux = { Client = { isAnyClassic = classic, isRetail = not classic, isPostDF = not classic,
        isForever = branch == "forever", isCamelot = branch == "forever", isLiveMidnight = branch == "live" } } }
    env.Flux = ns.Flux
    for _, path in ipairs(sources) do
        local source = read(path)
        if mutation and mutation.path == path then
            local count
            source, count = source:gsub("local " .. mutation.name .. ' = CreateFrame%("Frame"%)',
                "local " .. mutation.name .. " = SettingsPanel", 1)
            assert(count == 1, "mutation must replace the real constructor: " .. mutation.name)
        end
        assert(load(source, "@" .. path, "t", env))("_FluxUI", ns)
    end
    local function updates()
        for _, f in ipairs(frames) do if f.owned and f.scripts.OnUpdate then f.scripts.OnUpdate(f, 0.1) end end
        local work = timers; timers = {}
        for _, callback in ipairs(work) do callback() end
    end
    local applied = 0
    local write = ns.Flux.BlizzardSettings.Write
    write.Run("ownership", function() applied = applied + 1 end)
    check(write.IsQueued("ownership") and applied == 0, "settings-open work remains queued")
    locked = true
    env.SettingsPanel.shown = false
    updates()
    check(applied == 0, "closing settings cannot flush while in combat")
    locked = false
    for _, f in ipairs(frames) do
        if f.events.PLAYER_REGEN_ENABLED and f.scripts.OnEvent then f.scripts.OnEvent(f, "PLAYER_REGEN_ENABLED") end
    end
    updates()
    check(applied == 1 and not write.IsQueued("ownership"), "queued settings job flushes exactly once")
    check(scripts == (branch == "forever" and 6 or 5), "all production script-owner sites executed")
    return true
end

for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    run(branch)
end
for _, mutation in ipairs({
    { path = "BlizzardSettings/Write.lua", name = "flusher" },
    { path = "BlizzardSettings/Write.lua", name = "watch" },
    { path = "BlizzardSettings/Nameplates.lua", name = "healthBits" },
    { path = "Blizzard/Hide.lua", name = "waiter" },
    { path = "NamePlates/Core.lua", name = "driver" },
    { path = "NamePlates/Core.lua", name = "events" },
}) do
    local ok, err = pcall(run, "forever", mutation)
    check(not ok and tostring(err):find("native frame SetScript forbidden", 1, true), "reject native script-owner mutation: " .. mutation.name)
    mutants = mutants + 1
end
print("Blizzard script ownership: " .. checks .. " checks passed; " .. mutants .. " native-owner mutations rejected")
return { scriptOwnership = true, checks = checks, mutants = mutants }
