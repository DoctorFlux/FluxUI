-- Execute real chat retry/hooks and map tab discovery, including bounded idle work.
-- Native secure/taint execution and actual frame rendering require the client.
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
local chat = section(read("Other/FluxChatFrame.lua"), "local function ApplyRetailChatChannelAndQuickJoin()",
    "local function InitSocialButtonPositioning()")
local mapSource = read("Battlezonemap/FluxBattlefieldMap.lua")
local map = section(mapSource, "-- Event frame for instant tab hiding", "-- Anchor map to FluxWindowFrame")
local hide = section(mapSource, "local function HideBattlefieldMapTabInstantly()", "local function RestoreBattlefieldMapTab()")
local oldChat, oldMap = read("tests/fixtures/chat_retries_before.txt"), read("tests/fixtures/map_tab_watch_before.txt")
local checks = 0
local function check(ok, msg) assert(ok, msg); checks = checks + 1 end
local function chatFixture(body, branch, noAlert)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local s = { now = 0, armed = 0, executed = 0, timers = {}, calls = 0, hooks = {}, wanted = 1 }
    env.C_Timer = { After = function(delay, fn)
        s.armed = s.armed + 1
        s.timers[#s.timers + 1] = { at = s.now + math.max(.001, delay), fn = fn, serial = s.armed }
    end }
    function s:advance(to)
        while true do
            table.sort(self.timers, function(a, b) return a.at < b.at or (a.at == b.at and a.serial < b.serial) end)
            local nextTimer = self.timers[1]
            if not nextTimer or nextTimer.at > to then break end
            table.remove(self.timers, 1); self.now = nextTimer.at
            self.executed = self.executed + 1
            assert(self.executed < 10000, "unbounded retry loop")
            nextTimer.fn()
        end
        self.now = to
    end
    env.ApplyChatFrameChannelButtonTopOffset = function() s.channel = s.wanted end
    env.ApplyQuickJoinAnchorToChannel = function() s.quickJoin = s.channel end
    env.FluxCCP = { PlaceColumnButtons = function()
        check(not s.busy, branch .. ": no layout writes during native Edit Mode")
        s.calls, s.presented = s.calls + 1, s.quickJoin
    end }
    env.FluxEditModeBusy = function() return s.busy end
    env.FluxAfterEditMode = function(fn) s.deferred = fn end
    env.QuickJoinToastButton, env.ChatFrameChannelButton, env.ChatFrame1 = {}, {}, {}
    env.ChatAlertFrame = not noAlert and { UpdateAnchors = function() end } or nil
    env.FCF_SetButtonSide, env.FCF_UpdateButtonSide = function() end, function() end
    env.hooksecurefunc = function(owner, method, fn)
        if type(owner) == "string" then s.hooks[owner] = method else s.hooks[method] = fn end
    end
    env.EventRegistry = { RegisterCallback = function(_, event, fn) s.hooks[event] = fn end }
    local init = assert(load("local quickJoinAnchorHooksDone = false\n" .. body ..
        "\nreturn InitQuickJoinAnchorHooks", "@production-chat-retries", "t", env))()
    s.env, s.init = env, init
    return s
end
local function exerciseChat(body, branch, baseline, noAlert)
    local s = chatFixture(body, branch, noAlert)
    s.init(); s.init()
    check(s.armed == 3, branch .. ": setup hooks installed once with three original deadlines")
    for _ = 1, 100 do
        s.hooks.FCF_SetButtonSide(s.env.ChatFrame1)
        s.hooks.FCF_UpdateButtonSide(s.env.ChatFrame1)
        if not noAlert then s.hooks.UpdateAnchors() end
    end
    local burst = s.armed
    check(burst == (baseline and (noAlert and 603 or 903) or 3), branch .. ": same-frame native burst queues one retry batch")
    s.hooks.FCF_SetButtonSide({})
    check(s.armed == burst, branch .. ": secondary chat keeps its own anchors")
    s:advance(.001)
    check(s.presented == 1, branch .. ": next-frame presentation retained")
    local first = s.calls
    s.wanted = 2; s:advance(.1)
    check(s.presented == 2 and s.calls > first, branch .. ": 100ms late-anchor retry retained")
    local second = s.calls
    s.wanted = 3; s:advance(1)
    check(s.presented == 3 and s.calls > second, branch .. ": one-second late-anchor retry retained")
    local settled = s.calls
    s:advance(60)
    check(s.calls == settled and #s.timers == 0, branch .. ": no permanent chat retry loop")
    s.wanted = 4; s.hooks.FCF_UpdateButtonSide(s.env.ChatFrame1)
    s:advance(60.002)
    check(s.presented == 4, branch .. ": later frame receives immediate reconciliation without debounce")
    s.busy, s.wanted = true, 5
    s.hooks["EditMode.Exit"]()
    check(s.deferred ~= nil and s.presented == 4, branch .. ": native Edit Mode exit uses safe queue")
    s:advance(62)
    check(s.presented == 4, branch .. ": pending retries also defer while Edit Mode is busy")
    s.busy = false; s.deferred()
    check(s.presented == 5, branch .. ": queued work reads latest layout after Edit Mode")
    return burst
end
local function mapFixture(body, branch)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local s = { frames = {}, state = {}, writes = 0, updates = 0 }
    env.state, env.UIParent = s.state, {}
    env.CreateFrame = function()
        local frame = { scripts = {}, events = {} }; s.frames[#s.frames + 1] = frame
        function frame:SetScript(event, fn) self.scripts[event] = fn end
        function frame:RegisterEvent(event) self.events[event] = true end
        return frame
    end
    function s:event(event, addon)
        local count = #self.frames
        for i = 1, count do
            local f = self.frames[i]
            if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, addon) end
        end
    end
    function s:step(count)
        for _ = 1, count do
            for _, f in ipairs(self.frames) do
                if f.scripts.OnUpdate then self.updates = self.updates + 1; f.scripts.OnUpdate(f, 1 / 240) end
            end
        end
    end
    function s:idle()
        for _, f in ipairs(self.frames) do if f.scripts.OnUpdate then return false end end
        return true
    end
    function s:addTab()
        local t = { shown = true, mouse = true, alpha = 1 }
        function t:Hide() s.writes = s.writes + 1; self.shown = false end
        function t:EnableMouse(v) self.mouse = v end
        function t:SetAlpha(v) self.alpha = v end
        function t:ClearAllPoints() end
        function t:SetPoint(_, parent, _, x, y) self.parent, self.x, self.y = parent, x, y end
        env.BattlefieldMapTab = t
        return t
    end
    assert(load(hide .. body, "@production-map-tab-" .. branch, "t", env))()
    return s
end
local function exerciseMap(body, branch, baseline)
    local s = mapFixture(body, branch)
    s:step(29); s:event("PLAYER_LOGIN"); s:event("PLAYER_ENTERING_WORLD")
    check(s.writes == 0, branch .. ": missing optional tab is not accessed")
    s:step(20)
    check(not s:idle(), branch .. ": initial/transition discovery window retained")
    s:step(30)
    check(s:idle(), branch .. ": discovery polling stops at its bounded deadline")
    local tab = s:addTab()
    s:event("ADDON_LOADED", "UnrelatedAddon")
    check(tab.shown, branch .. ": unrelated late addon does not change tab visibility")
    s:event("ADDON_LOADED", "Blizzard_BattlefieldMap")
    check(not tab.shown and not tab.mouse and tab.alpha == 0 and tab.x == -500 and tab.y == -500,
        branch .. ": late map load retains hidden tab/input/anchor behavior")
    s:step(60)
    local before = s.updates
    for _ = 1, 100 do
        tab.shown, tab.mouse, tab.alpha = true, true, 1
        s:event("PLAYER_ENTERING_WORLD"); s:step(1)
        check(not tab.shown and not tab.mouse and tab.alpha == 0, branch .. ": native tab resurfacing reconciles immediately")
    end
    check(#s.frames == (baseline and 104 or 1), branch .. ": repeated transitions reuse one event/discovery frame")
    if not baseline then check(s.updates == before, branch .. ": known tab schedules no discovery callbacks") end
    check(s:idle(), branch .. ": known tab leaves no polling script")
    if not baseline then
        -- A late load may announce itself before creating its tab, even after
        -- the startup window expired. One bounded discovery pass handles it.
        local late = mapFixture(body, branch); late:step(50)
        late:event("ADDON_LOADED", "Blizzard_BattlefieldMap"); late:step(29)
        local delayed = late:addTab(); late:step(1)
        check(not delayed.shown and late:idle(), branch .. ": delayed tab after optional addon load is found")
    end
    return #s.frames
end
local beforeTimers, afterTimers, beforeFrames, afterFrames
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    beforeTimers = exerciseChat(oldChat, branch, true)
    afterTimers = exerciseChat(chat, branch)
    exerciseChat(chat, branch, false, true)
    beforeFrames = exerciseMap(oldMap, branch, true)
    afterFrames = exerciseMap(map, branch)
    local optional = chatFixture(chat, branch)
    optional.env.QuickJoinToastButton = nil; optional.init()
    check(optional.armed == 0 and next(optional.hooks) == nil, branch .. ": clients without QuickJoin install no extra hooks or timers")
    optional.env.QuickJoinToastButton = {}; optional.env.ChatFrameChannelButton = nil; optional.init()
    check(optional.armed == 0, branch .. ": absent channel button also leaves initialization retryable")
    optional.env.ChatFrameChannelButton = {}; optional.init(); optional.init()
    check(optional.armed == 3, branch .. ": late optional chat controls initialize once")
end
local mutants = 0
local function reject(body, old, new, exercise, expected)
    local ok, err = pcall(exercise, replace(body, old, new), "forever")
    check(not ok and tostring(err):find(expected, 1, true), "mutation rejected: " .. expected .. ": " .. tostring(err))
    mutants = mutants + 1
end
reject(chat, "if chatChannelApplyQueued then return end", "", exerciseChat, "same-frame native burst")
reject(chat, "chatChannelApplyQueued = false\n    ApplyRetail", "chatChannelApplyQueued = true\n    ApplyRetail", exerciseChat, "later frame receives immediate")
reject(chat, "C_Timer.After(1, ApplyRetailChatChannelAndQuickJoin)", "", exerciseChat, "three original deadlines")
reject(chat, "if FluxEditModeBusy and FluxEditModeBusy() then", "if false then", exerciseChat, "no layout writes during native Edit Mode")
reject(map, "tabHiderFrame:SetScript(\"OnUpdate\", nil)", "", exerciseMap, "polling stops at its bounded deadline")
reject(map, "tabChecksRemaining = tabChecksRemaining - 1", "tabChecksRemaining = tabChecksRemaining", exerciseMap, "polling stops at its bounded deadline")
print(string.format("idle layout retries: %d checks across five clients; %d mutations rejected", checks, mutants))
print(string.format("same-frame chat burst: %d -> %d timers; 102 login/world events: %d -> %d watcher frames", beforeTimers, afterTimers, beforeFrames, afterFrames))
