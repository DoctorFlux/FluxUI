-- Execute the real unit-frame polling and portrait lifecycle, including rejected
-- mutants. Operation counts describe mocked API work, not in-game frame rates.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local file = assert(io.open(root .. "UnitFrames/FluxUnitFrames_Shared.lua", "r"))
local source = file:read("*a"); file:close()
local checks = 0
local mutationChecks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end
local function slice(text, first, last)
    local a = assert(text:find(first, 1, true), first)
    local b = assert(text:find(last, a + #first, true), last)
    return text:sub(a, b - 1)
end
local function boot(branch, text, noTimers, initialCombat)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local state = { frames = {}, locked = initialCombat or false, exists = false, visible = true, use3D = true,
        health = 100, maxHealth = 100, power = 70, maxPower = 100, powerType = 0,
        healthUpdates = 0, powerUpdates = 0, additional = 0, threat = 0,
        clear = 0, keep = 0, alpha = 0, chrome = 0, portraitPaints = 0, protected = 0,
        now = 0, timers = {}, callbacks = 0, frameCallbacks = 0 }
    local ns = { UnitFrames = {}, API = {}, Flux = { Client = { isForever = branch == "forever",
        isRetail = branch == "live", isAnyClassic = branch ~= "forever" and branch ~= "live" } } }
    env.InCombatLockdown = function() return state.locked end
    env.UnitHealth = function() return state.health end
    env.UnitHealthMax = function() return state.maxHealth end
    env.UnitPowerType = function() return state.powerType end
    env.UnitPower = function() return state.power end
    env.UnitPowerMax = function() return state.maxPower end
    env.UnitName = function() return "Watched" end
    ns.API.IsSecretValue = function(value) return type(value) == "table" and value.secret end
    ns.API.CanAccessValue = function(value) return not ns.API.IsSecretValue(value) end
    env.issecretvalue = ns.API.IsSecretValue
    env.CreateFrame = function()
        local frame = { scripts = {}, shown = true, events = {} }
        function frame:SetScript(name, fn) self.scripts[name] = fn end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        function frame:RegisterEvent(event) self.events[event] = true end
        state.frames[#state.frames + 1] = frame
        return frame
    end
    if not noTimers then
        ns.Flux.Timer = { NewTicker = function(interval, callback)
            local timer = { interval = interval, callback = callback, deadline = state.now + interval }
            function timer:Cancel() self.cancelled = true end
            state.timers[#state.timers + 1] = timer
            return timer
        end }
    end
    local UF = ns.UnitFrames
    assert(load(slice(text, "-- UnitFrames/FluxUnitFrames_Shared.lua", "-- Replaced by"),
        "@UnitFrames/FluxUnitFrames_Shared.lua:poll", "t", env))("_FluxUI", ns)
    UF.UpdateHealth = function() state.healthUpdates = state.healthUpdates + 1 end
    UF.UpdatePower = function() state.powerUpdates = state.powerUpdates + 1 end
    UF.UpdateAdditionalPower = function() state.additional = state.additional + 1 end
    UF.UpdateThreatBar = function() state.threat = state.threat + 1 end
    env.UF = UF
    local helpers = [[
local UF = UF
local function PortraitUnitExists() return state.exists end
local function PortraitFrameIsVisuallyShown() return state.visible end
local function PortraitShouldShowOutOfRangeMark() return state.outOfRange end
local function ShowPortraitQuestionMark(portrait) portrait:SetModel("question"); portrait:Show() end
local function BindPortraitUnit() end
local function SetPortraitUnit(portrait) portrait:SetUnit("watched") end
local function ApplyPortraitCamera() end
local function SchedulePortraitCameraRefresh() end
]]
    env.state = state
    env.FluxUnitFrames_ShouldUse3DPortrait = function() return state.use3D end
    env.SetPortraitTexture = function() state.portraitPaints = state.portraitPaints + 1 end
    local visibility = slice(text, "local function SetWatchedFrameAlpha", "--- Empty-target outline:")
    local portrait = slice(text, "function UF.UpdatePortrait(self, unit)", "--- Resize the PlayerModel")
    assert(load(helpers .. visibility .. portrait .. [[
return { alpha = SetWatchedFrameAlpha, chrome = ApplyWatchedUnitChrome }
]], "@UnitFrames/FluxUnitFrames_Shared.lua:portrait", "t", env))()
    local modelLoaded = slice(text, '    pcall(function()\n        model:SetScript("OnModelLoaded"',
        '    pcall(function()\n        model:SetScript("OnAnimStarted"')
    local installModelLoaded = assert(load(helpers .. "\nlocal model = ...\n" .. modelLoaded,
        "@UnitFrames/FluxUnitFrames_Shared.lua:model-loaded", "t", env))
    local function region(model)
        local result = { shown = true, alpha = 1, model = model, scripts = {} }
        function result:SetScript(event, callback) self.scripts[event] = callback end
        function result:IsShown() return self.shown end
        function result:Show() self.shown = true end
        function result:Hide() self.shown = false end
        function result:SetShown(value) self.shown = value; state.chrome = state.chrome + 1 end
        function result:GetAlpha() return self.alpha end
        function result:SetAlpha(value) self.alpha = value; state.alpha = state.alpha + 1 end
        function result:SetKeepModelOnHide(value) state.keep = state.keep + 1; self.keep = value end
        function result:ClearModel()
            state.clear = state.clear + 1
            if state.failClear then error("transient model clear") end
            self.model = nil
        end
        function result:SetModel(value) self.model = value end
        function result:SetUnit(value) self.model = value end
        return result
    end
    state.region = region
    state.installModelLoaded = installModelLoaded
    state.tick = function(elapsed)
        state.now = state.now + elapsed
        local poll = env.UF_UnitFramePollFrame
        if poll.shown then
            state.frameCallbacks = state.frameCallbacks + 1
            poll.scripts.OnUpdate(poll, elapsed)
        end
        for _, timer in ipairs(state.timers) do
            if not timer.cancelled and timer.deadline <= state.now + 1e-9 then
                timer.deadline = state.now + timer.interval
                state.callbacks = state.callbacks + 1
                timer.callback()
            end
        end
    end
    state.poll = env.UF_UnitFramePollFrame
    for _, f in ipairs(state.frames) do
        if f.events.PLAYER_REGEN_DISABLED then state.combatEvents = f end
    end
    function state.activeTimers()
        local count = 0
        for _, timer in ipairs(state.timers) do if not timer.cancelled then count = count + 1 end end
        return count
    end
    return state, UF, env
end

local finalClear
local function exercise(branch, noTimers, text)
    local s, UF, env = boot(branch, text, noTimers)
    local frame = { unit = "player", Health = {}, Power = {}, AdditionalPower = {} }
    UF.RegisterUnitFramePoll(frame, { health = true, power = true })
    UF.RegisterUnitFramePoll(frame, { health = true, power = true })
    check(s.activeTimers() == (noTimers and 0 or 1), branch .. " registration does not duplicate timers")
    check(env.FluxUI_GetUnitFramePollStats().active, branch .. " diagnostics report active timer work")
    check(s.poll.shown == noTimers, branch .. " native timers park per-frame fallback")
    -- Keep the existing 0.2s health/power and 0.5s combat threat cadences.
    s.tick(0.199); check(s.healthUpdates == 0 and s.powerUpdates == 0, branch .. " no early sample")
    s.tick(0.001); check(s.healthUpdates == 1 and s.powerUpdates == 1, branch .. " initial sample")
    for i = 1, 100 do s.tick(0.2) end
    check(s.healthUpdates == 1 and s.powerUpdates == 1, branch .. " unchanged values skip painting")
    s.health = 99; s.power = 60; s.tick(0.2)
    check(s.healthUpdates == 2 and s.powerUpdates == 2 and s.additional == 2, branch .. " changed values paint")
    s.powerType = 3; s.tick(0.2)
    check(s.powerUpdates == 3, branch .. " power type wakes repaint")
    local secret = { secret = true }
    s.health = secret; s.power = secret
    s.tick(0.2); s.tick(0.2)
    check(s.healthUpdates == 4 and s.powerUpdates == 5, branch .. " secrets always paint")
    check(frame._fluxPollHealth == nil and frame._fluxPollPower == nil, branch .. " secrets never cached")
    s.health = 98; s.power = 40; s.tick(0.2)
    check(s.healthUpdates == 5 and s.powerUpdates == 6, branch .. " readable recovery")
    s.powerType = secret; s.tick(0.2)
    check(frame._fluxPollPowerType == nil, branch .. " secret power type never compared or cached")
    s.powerType = 0; s.tick(0.2)
    check(frame._fluxPollPowerType == 0, branch .. " power type readable recovery")
    UF.UnregisterUnitFramePoll("player")
    check(not s.poll.shown and s.activeTimers() == 0, branch .. " no poll work parks driver")
    local lastHealth, lastPower = s.healthUpdates, s.powerUpdates
    s.tick(1)
    check(s.healthUpdates == lastHealth and s.powerUpdates == lastPower, branch .. " unsubscribe stops callbacks")
    local enemy = { unit = "target" }
    UF.RegisterUnitFramePoll(enemy, { threat = true })
    check(not s.poll.shown and s.activeTimers() == 0, branch .. " idle threat remains parked")
    s.locked = true; s.combatEvents.scripts.OnEvent(s.combatEvents, "PLAYER_REGEN_DISABLED")
    s.tick(0.499); check(s.threat == 0, branch .. " threat cadence unchanged")
    s.tick(0.001); check(s.threat == 1, branch .. " combat wakes threat")
    s.locked = false; s.combatEvents.scripts.OnEvent(s.combatEvents, "PLAYER_REGEN_ENABLED")
    check(not s.poll.shown and s.activeTimers() == 0, branch .. " combat end parks threat")
    s.tick(2); check(s.threat == 1, branch .. " canceled combat timer stays idle")

    local visibilityCalls, borders = 0, 0
    s.unitVisible = true
    UF.SyncWatchedUnitFrameVisibility = function()
        visibilityCalls = visibilityCalls + 1
        return s.unitVisible
    end
    for _, unit in ipairs({ "target", "focus", "targettarget", "focustarget" }) do
        UF.RegisterUnitFramePoll({ unit = unit, Health = {}, Power = {}, AdditionalPower = {},
            UpdateOuterBorder = function() borders = borders + 1 end }, { health = true })
    end
    local hp, pp, ap = s.healthUpdates, s.powerUpdates, s.additional
    s.tick(0.2)
    check(visibilityCalls == 4 and s.healthUpdates == hp + 2 and s.powerUpdates == pp + 2,
        branch .. " watched visibility and ToT polling retain cadence")
    check(s.additional == ap + 2 and borders == 2, branch .. " ToT additional power and name border preserved")
    s.tick(0.2)
    check(s.healthUpdates == hp + 2 and s.powerUpdates == pp + 2 and borders == 2,
        branch .. " unchanged ToT samples skip only redundant paint")
    env.UnitName = function() return "Changed" end
    s.tick(0.2); check(borders == 4, branch .. " ToT name change wakes border")
    s.unitVisible = false; s.health = 2; s.tick(0.2)
    check(s.healthUpdates == hp + 2, branch .. " absent ToT leaves no stale health repaint")
    for _, unit in ipairs({ "target", "focus", "targettarget", "focustarget" }) do
        UF.UnregisterUnitFramePoll(unit)
    end

    -- Four absent watched frames over one minute at the existing 5Hz poll.
    local watched = {}
    for i, unit in ipairs({ "target", "focus", "targettarget", "focustarget" }) do
        watched[i] = { unit = unit, Portrait = s.region("old"), Portrait2D = s.region() }
    end
    local before = s.clear
    for i = 1, 300 do for _, f in ipairs(watched) do UF.HideEmptyUnitPortrait(f) end end
    local clears = s.clear - before
    check(clears == 4, branch .. " idle missing units clear each model once")
    for _, f in ipairs(watched) do
        check(not f.Portrait.shown and not f.Portrait2D.shown and f.Portrait.model == nil,
            branch .. " absent units leave no portrait")
        s.exists = true
        UF.UpdatePortrait(f, f.unit)
        check(f.Portrait.shown and f.Portrait.model ~= nil, branch .. " portrait immediately resumes")
        f.Portrait:Hide() -- The parent can disappear before the next missing-unit check.
        s.exists = false
        UF.HideEmptyUnitPortrait(f)
        check(f.Portrait.model == nil and not f.Portrait.shown, branch .. " new model cleared")
        local count = s.clear
        UF.HideEmptyUnitPortrait(f)
        check(s.clear == count, branch .. " new absence remains idle")
    end
    local f = watched[1]
    f.Portrait = s.region("replacement")
    UF.HideEmptyUnitPortrait(f)
    check(f.Portrait.model == nil, branch .. " replacement model cleared")
    f.Portrait = s.region("retry")
    s.failClear = true; UF.HideEmptyUnitPortrait(f)
    s.failClear = false; UF.HideEmptyUnitPortrait(f)
    check(f.Portrait.model == nil, branch .. " failed clear remains retryable")
    -- A shown model is reconciled even if another caller bypasses the normal paint.
    f.Portrait.model = "external"; f.Portrait:Show(); UF.HideEmptyUnitPortrait(f)
    check(f.Portrait.model == nil and not f.Portrait.shown, branch .. " external show clears again")
    s.installModelLoaded(f.Portrait)
    f.Portrait.model = "late hidden load"
    f.Portrait.scripts.OnModelLoaded(f.Portrait)
    UF.HideEmptyUnitPortrait(f)
    check(f.Portrait.model == nil and not f.Portrait.shown, branch .. " delayed hidden model load clears again")
    s.exists = true; s.outOfRange = true; UF.UpdatePortrait(f, f.unit)
    check(f.Portrait.model == "question" and f.Portrait.shown, branch .. " question mark preserved")
    s.exists = false; UF.HideEmptyUnitPortrait(f)
    check(f.Portrait.model == nil, branch .. " question mark clear invalidates")
    s.exists = true; s.use3D = false; UF.UpdatePortrait(f, f.unit)
    check(f.Portrait2D.shown and not f.Portrait.shown, branch .. " flat portrait preserved")
    s.exists = false; UF.HideEmptyUnitPortrait(f)
    check(not f.Portrait2D.shown, branch .. " flat portrait hides immediately")
    if branch == "forever" then finalClear = clears end
end

for _, noTimers in ipairs({ false, true }) do
    for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
        exercise(branch, noTimers, source)
        local s, UF, env = boot(branch, source, noTimers, true)
        local player = { unit = "player", Health = {}, Power = {} }
        local target = { unit = "target" }
        UF.RegisterUnitFramePoll(player, { health = true })
        UF.RegisterUnitFramePoll(target, { threat = true })
        s.tick(0.2)
        check(s.healthUpdates == 1 and s.threat == 0, branch .. " load already in combat retains health cadence")
        s.tick(0.299); check(s.threat == 0, branch .. " initial combat threat waits correct deadline")
        s.tick(0.001); check(s.threat == 1, branch .. " initial combat threat ready")
        UF.UnregisterUnitFramePoll("player"); UF.UnregisterUnitFramePoll("target")
        UF.RegisterUnitFramePoll(player, { health = true })
        UF.RegisterUnitFramePoll(target, { threat = true })
        UF.RegisterUnitFramePoll(player, { health = true })
        UF.RegisterUnitFramePoll(target, { threat = true })
        check(s.activeTimers() == (noTimers and 0 or 2), branch .. " rapid re-register has two independent deadlines")
        s.locked = false; s.combatEvents.scripts.OnEvent(s.combatEvents, "PLAYER_REGEN_ENABLED")
        check(s.activeTimers() == (noTimers and 0 or 1), branch .. " combat end preserves health deadline")
        local oldThreat = s.threat
        s.tick(0.5); check(s.threat == oldThreat, branch .. " combat end cancels only threat")
        UF.UnregisterUnitFramePoll("player"); UF.UnregisterUnitFramePoll("target")
        check(not env.FluxUI_GetUnitFramePollStats().active and s.activeTimers() == 0,
            branch .. " no subscribers park every source")
    end
end

local function replace(text, from, to)
    local first, last = text:find(from, 1, true)
    assert(first, "mutation target missing: " .. from)
    return text:sub(1, first - 1) .. to .. text:sub(last + 1)
end
do
    local mutations = {
        { "empty model guard", "if not portrait._fluxEmptyCleared or (portrait.IsShown and portrait:IsShown()) then", "if true then", "idle missing units clear each model once" },
        { "portrait invalidation", "self.Portrait._fluxEmptyCleared = nil", "-- omitted", "new model cleared" },
        { "failed clear retry", "portrait._fluxEmptyCleared = ok or nil", "portrait._fluxEmptyCleared = true", "failed clear remains retryable" },
        { "external model show", "or (portrait.IsShown and portrait:IsShown())", "", "external show clears again" },
        { "late model load", "self._fluxEmptyCleared = nil", "-- omitted", "delayed hidden model load clears again" },
        { "power type secret", "or PollValueUnusable(powerType)", "", "secret power type never compared or cached" },
        { "duplicate health timers", "if not pollHealthTimer then", "if true then", "registration does not duplicate timers" },
        { "health timer cancellation", "pollHealthTimer:Cancel()", "-- omitted", "no poll work parks driver" },
        { "threat timer cancellation", "pollThreatTimer:Cancel()", "-- omitted", "combat end parks threat" },
        { "health cadence", "local POLL_HEALTH_INTERVAL = 0.2", "local POLL_HEALTH_INTERVAL = 0.25", "initial sample" },
        { "threat cadence", "local POLL_THREAT_INTERVAL = 0.5", "local POLL_THREAT_INTERVAL = 0.6", "combat wakes threat" },
    }
    for _, mutation in ipairs(mutations) do
        local mutant = replace(source, mutation[2], mutation[3])
        local ok, err = pcall(exercise, "forever", false, mutant)
        check(not ok and type(err) == "string" and err:find(mutation[4], 1, true),
            "production mutation rejected for intended reason: " .. mutation[1] .. " (" .. tostring(err) .. ")")
        mutationChecks = mutationChecks + 1
    end
end

local function sample(noTimers)
    local s, UF = boot("forever", source, noTimers)
    UF.RegisterUnitFramePoll({ unit = "player", Health = {}, Power = {} }, { health = true })
    for i = 1, 4800 do s.tick(1 / 240) end
    return { frameCallbacks = s.frameCallbacks, timerCallbacks = s.callbacks }
end
local oldDispatch, newDispatch = sample(true), sample(false)
check(oldDispatch.frameCallbacks == 4800 and newDispatch.frameCallbacks == 0
    and newDispatch.timerCallbacks == 100, "deadline driver retains 100 samples while removing 4800 frame callbacks")
local function missingClears(text)
    local s, UF = boot("forever", text)
    local frames = {}
    for i = 1, 4 do frames[i] = { Portrait = s.region("old"), Portrait2D = s.region() } end
    for i = 1, 300 do for _, frame in ipairs(frames) do UF.HideEmptyUnitPortrait(frame) end end
    return s.clear
end
-- Reproduce the pre-change unconditional clear path as a negative control.
local oldClears = missingClears(replace(source,
    "if not portrait._fluxEmptyCleared or (portrait.IsShown and portrait:IsShown()) then", "if true then"))
check(oldClears == 1200 and missingClears(source) == 4, "unconditional clear control reproduces pre-change API work")

local closureControl = replace(source,
    "if frame._fluxPollHealth == h and frame._fluxPollHealthMax == m then",
    "local ok, same = pcall(function() return frame._fluxPollHealth == h and frame._fluxPollHealthMax == m end)\n    if ok and same then")
closureControl = replace(closureControl,
    "if frame._fluxPollPower == p and frame._fluxPollPowerMax == m and frame._fluxPollPowerType == powerType then",
    "local ok, same = pcall(function() return frame._fluxPollPower == p and frame._fluxPollPowerMax == m and frame._fluxPollPowerType == powerType end)\n    if ok and same then")
local function pollingAllocations(text)
    local s, UF = boot("forever", text)
    UF.RegisterUnitFramePoll({ unit = "player", Health = {}, Power = {} }, { health = true })
    s.tick(0.2) -- Warm the plain-number cache before measuring unchanged samples.
    collectgarbage("collect"); collectgarbage("stop")
    local before = collectgarbage("count")
    for i = 1, 3000 do s.tick(0.2) end
    local allocated = collectgarbage("count") - before
    collectgarbage("restart")
    return allocated
end
local oldKB, newKB = pollingAllocations(closureControl), pollingAllocations(source)
check(oldKB > newKB + 250, "plain-number polling removes allocations from the pre-change closure control")
print(string.format("idle units: %d checks; missing-unit ClearModel calls/minute = %d -> %d", checks, oldClears, finalClear))
print(string.format("  20s/240Hz dispatch: fallback=%d frame callbacks, native=%d frame callbacks + %d health timer callbacks; %d mutations rejected",
    oldDispatch.frameCallbacks, newDispatch.frameCallbacks, newDispatch.timerCallbacks, mutationChecks))
print(string.format("  3000 unchanged samples, Lua heap allocated with GC paused: closure control=%.2fKB, candidate=%.2fKB", oldKB, newKB))
