-- Real map initialization/hide/cleanup with mocked native widgets. These
-- bounded retry watchers must not allocate frames or outlive tab ownership.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local function section(s, first, last)
    local a = assert(s:find(first, 1, true), first)
    return s:sub(a, assert(s:find(last, a + #first, true), last) - 1)
end
local function replace(s, old, new)
    local a = assert(s:find(old, 1, true), old)
    return s:sub(1, a - 1) .. new .. s:sub(a + #old)
end
local source = read("Battlezonemap/FluxBattlefieldMap.lua")
local init = section(source, "-- Initialization retries are bounded", "-- Initialize the battlefield map for use with FluxWindowFrame")
local publicInit = section(source, "function FluxBattlefieldMap:Initialize(parentFrame)", "-- Show the battlefield map")
local hide = section(source, "function FluxBattlefieldMap:Hide()", "-- Set scaling factors")
local cleanup = section(source, "function FluxBattlefieldMap:Cleanup()", "-- Slash command for testing")
local finish = section(source, "local function FinishDeferredEmbed()", "local zoneRefresher = CreateFrame")
local old = read("tests/fixtures/map_initialization_before.txt")
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function fixture(branch, body, baseline, zoomFallback)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local s = { frames = {}, state = {}, zooms = 0, scales = 0, refreshes = 0, pending = false }
    env.state, env.FluxBattlefieldMap, env.CONFIG, env.UIParent = s.state, {}, { SCALE_X = 1, SCALE_Y = 1 }, {}
    local modern = branch == "live" or branch == "forever"
    env.IsOlderClient = function() return not modern end
    env.InCombatLockdown = function() return s.combat end
    env.C_Map = { GetBestMapForUnit = function(unit) check(unit == "player", "display map resolves player"); return 17 end }
    env.C_AddOns = { LoadAddOn = function() return false end }
    env.positionUpdateQueue = {}
    env.C_Timer = setmetatable({}, { __index = function() error("initialization must not add timer retries") end })
    env.CreateFrame = function(kind, _, _, template)
        check(kind == "Frame" and not template, "watchers are owned unprotected frames")
        local f = { scripts = {} }
        function f:SetScript(event, fn) check(event == "OnUpdate", "watchers only own their update script"); self.scripts[event] = fn end
        s.frames[#s.frames + 1] = f; return f
    end
    local map = { parent = env.UIParent, shown = true }
    function map:SetScale() end
    function map:RefreshAlpha() end
    function map:UpdateUnitsVisibility() end
    function map:SetShouldZoomInOnClick() end
    function map:SetShouldPanOnClick() end
    function map:SetShouldNavigateOnClick() end
    function map:SetMapZoom(value) check(value == 0, "legacy zoom resets fully out"); s.zooms = s.zooms + 1 end
    function map:ZoomOut() s.zooms = s.zooms + 1 end
    if zoomFallback then map.SetMapZoom = nil end
    function map:SetFrameStrata() end
    function map:Hide() self.shown = false end
    function map:GetParent() return self.parent end
    function map:ClearAllPoints() end
    env.BattlefieldMapFrame = map
    env.GetBlizzardBattlefieldMap = function() return not s.missing and map or nil end
    env.SetupMapParenting = function(got, parent) check(got == map and parent ~= nil, "initial map receives its parent") end
    env.ApplyMapScaling = function(got) check(got == map, "scaling uses current map"); s.scales = s.scales + 1 end
    env.RefreshMapOnZoneChange = function() s.refreshes = s.refreshes + 1 end
    env.ApplyMapSetMapIDSilent = function(got, id) check(got == map and id == 17, "displayed map identity retained") end
    for _, name in ipairs({ "InvalidateLayoutCache", "HideBattlefieldMapTabInstantly", "InstallMapLayoutHooks",
        "InstallLightweightMapUpdate", "StopLayoutDriver", "HideCombatMouseBlocker", "ShowBlizzardUIBorder",
        "RestoreBattlefieldMapTab", "RestoreMapLayoutHooks", "SetCVar", "HideBlizzardUIBorder",
        "StartLayoutDriver", "StripCombatUnsafeMapProviders" }) do env[name] = function() end end
    local hideBody, cleanupBody, publicBody = hide, cleanup, publicInit
    if baseline then
        hideBody = hideBody:gsub("    StopInitializationWatchers%(%)\n", "")
        cleanupBody = cleanupBody:gsub("    StopInitializationWatchers%(%)\n", "")
        publicBody = publicBody:gsub("    StopInitializationWatchers%(%)\n", "")
    end
    s.finish = assert(load(body .. publicBody .. hideBody .. cleanupBody .. finish .. "\nreturn FinishDeferredEmbed",
        "@map-init-watchers-" .. branch, "t", env))()
    function s:step(count)
        for _ = 1, count do
            for _, frame in ipairs(self.frames) do if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 1 / 240) end end
        end
    end
    function s:active()
        local n = 0
        for _, frame in ipairs(self.frames) do if frame.scripts.OnUpdate then n = n + 1 end end
        return n
    end
    s.env, s.api, s.modern, s.map = env, env.FluxBattlefieldMap, modern, map
    return s
end
local function exercise(branch, body, baseline, zoomFallback)
    local s = fixture(branch, body or init, baseline, zoomFallback)
    check(not s.api:Initialize(nil) and #s.frames == 0, "missing parent does not initialize map")
    for _ = 1, 30 do
        check(s.api:Initialize({}), branch .. ": map reinitializes on every visit")
        check(s:active() == (s.modern and 1 or 2), "same original scaling/zoom next-frame work")
        s.state.isActive = true; s:step(1)
        check(s:active() == 0, "ready initialization retries stop after their first frame")
        s.api:Hide(); s.api:Cleanup()
    end
    check(s.refreshes == 30 and s.zooms == (s.modern and 0 or (zoomFallback and 300 or 30)),
        "zone refresh and legacy zoom happen once per visit")
    check(#s.frames == (s.modern and (baseline and 30 or 1) or (baseline and 60 or 2)),
        "initialization watcher frames are reused across visits")
    local frames = #s.frames
    -- Hide/cleanup can happen in the same frame as initialization. The next
    -- frame must not scale or zoom the map after another tab has taken over.
    s.api:Initialize({}); local scales, zooms, refreshes = s.scales, s.zooms, s.refreshes
    s.api:Hide(); s:step(1)
    if not baseline then
        check(s.scales == scales and s.zooms == zooms and s.refreshes == refreshes,
            "hide cancels stale scaling/zoom work")
    end
    s.api:Initialize({}); scales, zooms, refreshes = s.scales, s.zooms, s.refreshes
    s.api:Cleanup(); s:step(20)
    if not baseline then check(s.scales == scales and s.zooms == zooms and s.refreshes == refreshes,
        "cleanup cancels stale initialization work") end
    s.missing = true; check(not s.api:Initialize({}), "failed native addon load remains retryable")
    s.missing = false; check(s.api:Initialize({}), "later native map availability initializes")
    s:step(1); check(s:active() == 0, "retry after failure returns to idle")
    -- Combat initialization retains its existing structural barrier and does
    -- not create/run these OOC setup watchers until the legal retry.
    s.api:Hide(); s.api:Cleanup(); s.combat = true
    local allocation = #s.frames
    check(s.api:Initialize({}) and s.state.embedPending and #s.frames == allocation and s:active() == 0,
        "combat startup defers structural watchers")
    s.combat = false; check(s.api:Initialize({}), "out-of-combat retry initializes")
    s:step(1); check(s:active() == 0, "combat recovery is bounded")
    if not baseline then
        s.api:Initialize({}); s.state.isActive = true
        scales, zooms, refreshes = s.scales, s.zooms, s.refreshes
        s.combat = true; s:step(1)
        check(s.scales == scales and s.zooms == zooms and s.refreshes == refreshes
            and s.state.embedPending and s:active() == 0, "combat beginning before a retry defers structural work")
        s.combat = false; s.finish(); s:step(1)
        check(not s.state.embedPending and s.scales > scales and s.refreshes == refreshes + 1,
            "existing regen recovery completes interrupted initialization")
        scales, zooms, refreshes = s.scales, s.zooms, s.refreshes
        s.finish(); s:step(1)
        check(s.scales == scales and s.zooms == zooms and s.refreshes == refreshes,
            "deferred initialization recovery runs exactly once")
        s.api:Initialize({}); s.combat = true; s.api:Initialize({})
        check(s:active() == 0 and s.state.embedPending, "combat reinitialization cancels prior OOC watchers")
        s.combat = false; s.finish(); s:step(1)
    end
    return frames
end
local before, after
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    before = exercise(branch, old, true)
    after = exercise(branch)
end
exercise("classic_era", nil, false, true)
local mutants = 0
local function reject(body, oldText, newText, expected)
    local ok, err = pcall(exercise, "classic_era", replace(body, oldText, newText))
    check(not ok and tostring(err):find(expected, 1, true), "mutation rejected: " .. expected .. ": " .. tostring(err)); mutants = mutants + 1
end
reject(init, "initializationWatchers.scaling = scalingWatcher", "", "watcher frames are reused")
reject(init, "initializationWatchers.zoom = zoomWatcher", "", "watcher frames are reused")
reject(init, 'watcher:SetScript("OnUpdate", nil)', "", "hide cancels stale")
reject(init, "self:SetScript(\"OnUpdate\", nil)", "", "ready initialization retries stop")
reject(init, "if InCombatLockdown() then\n            state.embedPending = true", "if false then\n            state.embedPending = true",
    "combat beginning before a retry defers structural work")
print(string.format("map initialization: %d checks; five clients plus legacy zoom fallback; %d mutations rejected; 30 visits modern watcher frames %d -> %d (legacy 60 -> 2)", checks, mutants, before, after))
