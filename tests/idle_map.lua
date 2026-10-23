-- Native frame hooks cannot be removed. Exercise actual map lifecycle bodies.
local path = debug.getinfo(1, "S").source:sub(2)
local root = (path:match("^(.*)[/\\]") or ".") .. "/../"
local file = assert(io.open(root .. "Battlezonemap/FluxBattlefieldMap.lua", "rb"))
local source = file:read("*a"):gsub("\r\n", "\n")
file:close()
local baseline = arg and arg[1] == "--baseline"
local checks = 0
local function check(value, message) assert(value, message); checks = checks + 1 end
local function section(text, first, last)
    local start = assert(text:find(first, 1, true), first)
    return text:sub(start, assert(text:find(last, start + #first, true), last) - 1)
end
local function replace(text, from, to)
    local start = assert(text:find(from, 1, true), "missing source mutation: " .. from)
    return text:sub(1, start - 1) .. to .. text:sub(start + #from)
end
local hooks = section(source, "local function InstallMapLayoutHooksPostDF", "local function HideCombatMouseBlocker")
local watchers = section(source, "local zoneLayoutWatcher = nil", "local function StripCombatUnsafeMapProviders")
-- Reconstruct only these exact pre-fix production lines for a reproducible benchmark.
if baseline then
    local before = assert(io.open(root .. "tests/fixtures/idle_map_before.txt", "rb"))
    watchers = before:read("*a"):gsub("\r\n", "\n")
    before:close()
    if not hooks:find("    mapFrame.FluxBattlefieldMap_OnShowHooked = nil", 1, true) then
        hooks = replace(hooks, "    mapFrame.FluxLayoutHooked = nil",
            "    mapFrame.FluxBattlefieldMap_OnShowHooked = nil\n    mapFrame.FluxBattlefieldMap_HideHooked = nil\n    mapFrame.FluxLayoutHooked = nil")
    end
end
local function run(client, hookBody, watcherBody, noTimer)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    local modern = client == "live" or client == "forever"
    local state = { isActive = false, fluxPermitHide = false }
    env.state = state
    local queue, nativeShows, embeddedShows, listeners, restores = {}, 0, 0, {}, 0
    env.C_Timer = not noTimer and { After = function(_, callback) queue[#queue + 1] = callback end } or nil
    local frameCount, showHookCount, hideHookCount = 0, 0, 0
    local map = { shown = false, scripts = {} }
    local function nativeOnUpdate() end
    map.scripts.OnUpdate = nativeOnUpdate
    function map:IsShown() return self.shown end
    function map:OnShow() nativeShows = nativeShows + 1 end
    function map:OnEvent() end
    function map:GetScript(event) return self.scripts[event] end
    function map:SetScript(event, callback) self.scripts[event] = callback end
    function map:HookScript(event, callback)
        check(event == "OnHide", client .. ": only the existing map hide script is hooked")
        hideHookCount = hideHookCount + 1
        local previous = self.scripts[event]
        self.scripts[event] = function(...)
            if previous then previous(...) end
            callback(...)
        end
    end
    function map:Show()
        if self.shown then return end
        self.shown = true
        self:OnShow()
    end
    function map:Hide()
        if not self.shown then return end
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    local nativeOnShow, nativeOnEvent, nativeHide = map.OnShow, map.OnEvent, map.Hide
    env.hooksecurefunc = function(owner, method, callback)
        check(owner == map and method == "OnShow", client .. ": preserve native post-hook ownership")
        showHookCount = showHookCount + 1
        local previous = owner[method]
        owner[method] = function(...)
            previous(...)
            callback(...)
        end
    end
    env.CreateFrame = function()
        frameCount = frameCount + 1
        local frame = { events = {}, scripts = {} }
        listeners[#listeners + 1] = frame
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(event, callback) self.scripts[event] = callback end
        function frame:GetScript(event) return self.scripts[event] end
        return frame
    end
    env.IsPostDFClient = function() return modern end
    env.RunEmbeddedOnShowDeferred = function(self)
        check(self == map, client .. ": deferred refresh retains its map")
        embeddedShows = embeddedShows + 1
    end
    env.RunEmbeddedOnShow = function(self)
        check(self == map, client .. ": embedded refresh retains its map")
        embeddedShows = embeddedShows + 1
    end
    env.GetPlayerDisplayMapID = function() return 1 end
    env.ApplyMapSetMapIDSilent = function() return false end
    env.ApplyMapScaling = function() end
    env.CONFIG = { SCALE_X = 1, SCALE_Y = 1 }
    env.MapCanvasMixin = { OnEvent = function() end }
    local body = (watcherBody or watchers) .. (hookBody or hooks) ..
        "\nreturn {install=InstallMapLayoutHooks, restore=RestoreMapLayoutHooks}"
    local lifecycle = assert(load(body, "@production-map-lifecycle", "t", env))()
    local function flush()
        local work = queue
        queue = {}
        for _, callback in ipairs(work) do callback() end
    end
    for _ = 1, 30 do
        state.mapFrame, state.isActive = map, false
        lifecycle.install(map)
        lifecycle.install(map)
        if modern then
            local active = 0
            for _, listener in ipairs(listeners) do if listener.scripts.OnEvent then active = active + 1 end end
            check(active == 1, client .. ": one active zone event listener")
        end
        state.isActive = true
        map:Show()
        flush()
        state.isActive = false
        lifecycle.restore(map)
        map:Hide()
        flush()
        for _, listener in ipairs(listeners) do
            check(not listener.scripts.OnEvent and next(listener.events) == nil, client .. ": inactive watcher has no scripts or events")
            check(not listener.scripts.OnUpdate, client .. ": no watcher polling loop")
        end
    end
    local refreshed, allocated = embeddedShows, frameCount
    local installedShowHooks, installedHideHooks = showHookCount, hideHookCount
    if not baseline then
        check(refreshed == 30, client .. ": one refresh per map tab visit")
        if modern then
            check(showHookCount == 1 and hideHookCount == 1, client .. ": native hooks installed once")
            check(allocated == 1, client .. ": zone watcher reused across map visits")
        end
    end
    check(map.scripts.OnUpdate == nativeOnUpdate, client .. ": native animation/input script preserved")
    if not modern then
        check(map.OnShow == nativeOnShow and map.OnEvent == nativeOnEvent and map.Hide == nativeHide,
            client .. ": Classic methods restore after cleanup")
    end
    map:Show() -- Ordinary native map visibility outside the Flux embed remains independent.
    check(#queue == 0, client .. ": inactive native show schedules no Flux work")
    flush()
    map:Hide()
    state.isActive = false
    lifecycle.install(map)
    state.isActive = true
    map:Show()
    flush()
    map:Hide() -- Native hides while embedding is active must still be repaired.
    if modern then
        if not noTimer then check(not map:IsShown(), client .. ": restoration remains deferred") end
        flush()
        check(map:IsShown(), client .. ": active map repairs a native hide")
        restores = restores + 1
        map:Hide()
        state.isActive = false
        lifecycle.restore(map)
        flush()
        if not noTimer then
            check(not map:IsShown(), client .. ": stale restore cannot resurrect an inactive map")
        end
    end
    return { refreshes = refreshed, zoneWatchers = allocated, showHooks = installedShowHooks, hideHooks = installedHideHooks }
end
local result
for _, client in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do result = run(client) end
local mutants = 0
if not baseline then
    run("forever", nil, nil, true)
    local function rejected(name, expected, callback)
        local ok, err = pcall(callback)
        check(not ok and tostring(err):find(expected, 1, true), name .. " must fail its intended assertion: " .. tostring(err))
        mutants = mutants + 1
    end
    rejected("clear permanent native hook flags", "one refresh per map tab visit", function()
        run("forever", replace(hooks, "    mapFrame.FluxLayoutHooked = nil",
            "    mapFrame.FluxBattlefieldMap_OnShowHooked = nil\n    mapFrame.FluxBattlefieldMap_HideHooked = nil\n    mapFrame.FluxLayoutHooked = nil"))
    end)
    rejected("discard dormant zone watcher", "zone watcher reused across map visits", function()
        run("forever", nil, replace(watchers, '    zoneLayoutWatcher:SetScript("OnEvent", nil)',
            '    zoneLayoutWatcher:SetScript("OnEvent", nil)\n    zoneLayoutWatcher = nil'))
    end)
    rejected("schedule inactive map refreshes", "inactive native show schedules no Flux work", function()
        run("forever", replace(hooks, "            if not state.isActive then\n                return\n            end", ""))
    end)
    rejected("stale map visibility restore", "stale restore cannot resurrect an inactive map", function()
        run("forever", replace(hooks, "                        if state.isActive and not state.fluxPermitHide and self then",
            "                        if not state.fluxPermitHide and self then"))
    end)
    rejected("remove native MapCanvas animation/input", "native animation/input script preserved", function()
        run("forever", replace(hooks, "    mapFrame.FluxLayoutHooked = true",
            '    mapFrame.FluxLayoutHooked = true\n    mapFrame:SetScript("OnUpdate", nil)'))
    end)
end
print("idle map " .. (baseline and "before" or "after") .. ": 30 visits refreshes=" .. result.refreshes ..
    ", zone watchers=" .. result.zoneWatchers .. ", show/hide hooks=" .. result.showHooks .. "/" .. result.hideHooks)
print("idle map: " .. checks .. " checks across five client paths; " .. mutants .. " behavioral mutations rejected")
return result
