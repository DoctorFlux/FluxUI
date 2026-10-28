-- Production watcher lifecycle and resource-spark painting. Native operation
-- counts are synthetic; these tests do not measure WoW rendering or taint.
local function read(path)
    local f = assert(io.open(path, "rb")); local text = f:read("*a"):gsub("\r\n", "\n"); f:close(); return text
end
local function slice(text, first, last)
    local a = assert(text:find(first, 1, true), first)
    return text:sub(a, last and assert(text:find(last, a + #first, true), last) - 1 or #text)
end
local function replace(text, old, new)
    local a = assert(text:find(old, 1, true), old)
    return text:sub(1, a - 1) .. new .. text:sub(a + #old)
end
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local branches = { "live", "forever", "classic_era", "classic_anniversary", "classic" }
local power = read("UnitFrames/FluxPowerCostOverlay.lua")
local oldWatchers = read("tests/fixtures/power_cost_watchers_before.txt")
local oldPower = power:sub(1, assert(power:find("local function SafeRegisterUnit(", 1, true)) - 1) .. oldWatchers
local function watchers(branch, text, old)
    local s = { created = {}, enabled = true, casts = {}, channels = {}, empowered = {}, updates = {}, overlays = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.PlayerFrame = setmetatable({}, { __newindex = function() error("native frame mutation") end })
    env.hooksecurefunc = function() error("native hook") end
    env.C_Timer = setmetatable({}, { __index = function() error("watcher lifecycle scheduled a timer") end })
    env.UnitExists = function() return true end
    env.UnitGUID = function(unit) return "guid-" .. unit end
    env.UnitPowerType = function() return 0 end
    env.UnitCastingInfo = function(unit)
        local id = s.casts[unit]; if id then return "spell", nil, nil, 100, 200, nil, nil, nil, id end
    end
    env.UnitChannelInfo = function(unit)
        local id = s.channels[unit]; if id then return "channel", nil, nil, 100, 200, nil, nil, id, nil, s.empowered[unit] and 3 or 0 end
    end
    env.C_Spell = { GetSpellPowerCost = function() return { { type = 0, cost = 20 } } end }
    env.FluxUnitFrames_IsFeatureEnabled = function() return s.enabled end
    local ns = { API = {
        IsSecretValue = function(v) return type(v) == "table" and v.secret end,
        CanAccessValue = function() return true end,
        SafeUnitPowerMax = function() return 100 end,
    }, UnitFrames = { UsesHudUnitBars = function() return branch == "live" or branch == "forever" end } }
    ns.UnitFrames.UpdatePower = function(frame, unit)
        check(frame.unit == unit, "event retains the current unit")
        s.updates[unit] = (s.updates[unit] or 0) + 1
    end
    ns.UnitFrames.UpdateAdditionalPower = function() end
    env.CreateFrame = function(kind)
        check(kind == "Frame", "watchers remain ordinary unprotected event frames")
        local f = { events = {}, scripts = {} }; s.created[#s.created + 1] = f
        function f:UnregisterAllEvents() self.events = {} end
        function f:SetScript(key, value) check(key == "OnEvent", "no idle driver added"); self.scripts[key] = value end
        function f:RegisterUnitEvent(key, unit) self.events[key] = unit end
        function f:RegisterEvent(key)
            if s.failRegistration == key then error("temporary registration failure") end
            self.events[key] = true
        end
        return f
    end
    assert(load(text, "@power-cost-lifecycle-" .. branch, "t", env))("_FluxUI", ns)
    local pco = ns.PowerCostOverlay
    pco.CreateOverlay = function() s.overlays = s.overlays + 1 end
    pco.ApplySegmentArt = function() end
    local function frame(unit)
        local f = { unit = unit, Power = {}, AdditionalPower = {} }
        for _, bar in ipairs({ f.Power, f.AdditionalPower }) do
            bar.CostOverlay = { Hide = function(self) self.hidden = true end }
        end
        return f
    end
    local player, target, focus = frame("player"), frame("target"), frame("focus")
    ns.PlayerFrame, ns.TargetFrame, ns.FocusFrame = player, target, focus
    s.casts.player = 55
    pco.Initialize(player)
    check(player.Power._fluxPredictedCost == 20, "initialization restores a cast already in progress")
    local playerWatcher = player.PowerCostWatcher
    for _ = 1, 100 do
        pco.Initialize(player)
        s.enabled = false; pco.Initialize(player)
        local saved = player.PowerCostWatcher or s.created[#s.created]
        check(next(saved.events) == nil and saved.scripts.OnEvent == nil, "disabled watcher is inert")
        check(player.Power._fluxPredictedCost == nil and player.Power.CostOverlay.hidden, "disabling clears prediction")
        s.enabled = true; pco.Initialize(player)
    end
    local count = #s.created
    if not old then check(count == 1 and player.PowerCostWatcher == playerWatcher, "reapplying options reuses one player watcher") end
    local watcher = player.PowerCostWatcher
    check(watcher.events.UNIT_SPELLCAST_START == "player" and watcher.events.UNIT_POWER_UPDATE == "player",
        "unit filters survive repeated enable and disable")
    s.casts.player = nil
    watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_START", "player", "cast", 61)
    check(player.Power._fluxPredictedCost == 20, "start previews cost")
    local before = s.updates.player
    watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_START", "target", "cast", 61)
    check(s.updates.player == before, "unrelated units do not paint")
    watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 61)
    check(player.Power._fluxCastFinish and player.Power._fluxPredictedCost == nil, "completion retains feedback and clears prediction")
    s.casts.player = 61
    watcher.scripts.OnEvent(watcher, "UNIT_POWER_UPDATE", "player")
    check(player.Power._fluxPredictedCost == 20, "power event refreshes an active cast")
    s.casts.player = nil
    watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_INTERRUPTED", "player")
    check(player.Power._fluxPredictedCost == nil, "interruption clears preview")
    watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_START", "player", 61)
    check(player.Power._fluxPredictedCost == 20, "legacy single-ID payload remains supported")
    if not old then
        s.channels.player = 61
        player.AdditionalPower._fluxPredictedCost = 20
        watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_CHANNEL_START", "player", "channel", 61)
        check(player.Power._fluxPredictedCost == nil and player.AdditionalPower._fluxPredictedCost == nil,
            "channel start clears primary and secondary mana previews")
        check(player.Power.CostOverlay.hidden and player.AdditionalPower.CostOverlay.hidden,
            "channel start hides already-paid cost overlays")
        watcher.scripts.OnEvent(watcher, "UNIT_POWER_UPDATE", "player")
        watcher.scripts.OnEvent(watcher, "UNIT_DISPLAYPOWER", "player")
        check(player.Power._fluxPredictedCost == nil and player.AdditionalPower._fluxPredictedCost == nil,
            "channel power updates cannot restore an already-paid preview")
        player.Power._fluxPredictedCost = 20
        pco.Initialize(player)
        check(player.Power._fluxPredictedCost == nil, "options reapply during a channel clears stale prediction")
        s.channels.target = 61
        pco.Initialize(target)
        target.Power._fluxPredictedCost = 20
        target.PowerCostWatcher.scripts.OnEvent(target.PowerCostWatcher, "PLAYER_TARGET_CHANGED")
        check(target.Power._fluxPredictedCost == nil, "switching to a channeling target does not preview spent mana")
        s.empowered.player = true
        pco.Initialize(player)
        check(player.Power._fluxPredictedCost == 20, "empowered charging keeps its pending cost preview")
        watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_EMPOWER_START", "player", "empower", 61)
        watcher.scripts.OnEvent(watcher, "UNIT_POWER_UPDATE", "player")
        check(player.Power._fluxPredictedCost == 20, "empowered start and power updates retain pending cost")
        s.empowered.player = nil
        s.channels.player, s.channels.target = nil, nil
        s.casts.player = 61
        watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_START", "player", "cast", 61)
        check(player.Power._fluxPredictedCost == 20, "regular cast prediction returns after a channel")
        s.casts.player = nil
    end
    watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_START", "player", "cast", { secret = true })
    check(player.Power._fluxPredictedCost == nil, "secret spell ID is never used as a cost key")
    pco.Initialize(target); pco.Initialize(focus)
    check(target.PowerCostWatcher ~= focus.PowerCostWatcher and target.PowerCostWatcher ~= watcher,
        "independent unit frames retain independent watchers")
    check(target.PowerCostWatcher.events.PLAYER_TARGET_CHANGED and not target.PowerCostWatcher.events.PLAYER_FOCUS_CHANGED,
        "target registration remains scoped")
    target.unit = "focustarget"; pco.Initialize(target)
    local changed = target.PowerCostWatcher
    check(changed.events.UNIT_SPELLCAST_START == "focustarget" and changed.events.PLAYER_FOCUS_CHANGED
        and changed.events.UNIT_TARGET == "focus" and not changed.events.PLAYER_TARGET_CHANGED,
        "rebind replaces old unit and world event filters")
    before = s.updates.focustarget or 0
    changed.scripts.OnEvent(changed, "UNIT_SPELLCAST_START", "target", "cast", 61)
    check((s.updates.focustarget or 0) == before, "rebound callback does not retain previous unit")
    changed.scripts.OnEvent(changed, "UNIT_SPELLCAST_START", "focustarget", "cast", 61)
    check(target.Power._fluxPredictedCost == 20, "rebound callback previews for new unit")
    if not old then
        local failed = frame("target"); s.failRegistration = "PLAYER_TARGET_CHANGED"
        check(not pcall(pco.Initialize, failed), "initialization failure is observable")
        local retained, created = failed.PowerCostWatcher, #s.created
        s.failRegistration = nil; pco.Initialize(failed)
        check(retained and failed.PowerCostWatcher == retained and #s.created == created,
            "partially initialized watcher is reused on retry")
        check(failed.PowerCostWatcher.scripts.OnEvent and failed.PowerCostWatcher.events.PLAYER_TARGET_CHANGED,
            "retry finishes callback and event registration")

        local pending, ghostWrites, stops = {}, 0, 0
        env.C_Timer = { After = function(_, fn) pending[#pending + 1] = fn end }
        pco.RefreshPrediction = function() end
        local bar = player.Power
        local ghost = { shown = true, Show = function(self) self.shown = true end,
            Hide = function(self) self.shown = false end, SetStatusBarTexture = function() end,
            SetStatusBarColor = function() end, SetMinMaxValues = function() end,
            SetValue = function() ghostWrites = ghostWrites + 1 end }
        bar.PowerGhost, bar._fluxCostMeter = ghost, { Hide = function(self) self.hidden = true end }
        bar.GetStatusBarColor = function() return 1, 1, 1 end
        bar.GetStatusBarTexture = function() return { GetWidth = function() return 50 end } end
        bar._fluxGhostPrimed, bar._fluxFeedbackGUID, bar._fluxPrevFillW = true, "guid-player", 50
        bar._fluxCastFinish = nil
        pco.AfterPowerApplied(bar, "player", 50, 100)
        check(#pending == 1 and ghostWrites == 0, "power update retains next-frame ghost commit boundary")
        bar.FeedbackFrame = { SecretLossAnim = { Stop = function() stops = stops + 1 end },
            SecretBarAnim = { Stop = function() stops = stops + 1 end }, Hide = function() end }
        pco.DisableForFrame(player)
        pending[1]()
        check(ghostWrites == 0 and not ghost.shown and bar._fluxCostMeter.hidden,
            "disable invalidates pending ghost commits and hides unused meters")
        check(stops == 2 and not bar._fluxGhostPrimed, "disable stops secret animations and resets feedback priming")
        pco.Initialize(player)
        pco.AfterPowerApplied(bar, "player", 50, 100)
        check(ghostWrites == 1 and ghost.shown, "reenable primes ghost immediately without stale feedback")
    end
    return count
end

local shared = read("UnitFrames/FluxUnitFrames_Shared.lua")
local sparkCode = slice(shared, "function UF.UpdateResourceSpark(", "local function EnsureResourceSpark(")
local oldSpark = read("tests/fixtures/resource_spark_before.txt")
local function spark(branch, text, old)
    local s = { atlasWrites = 0, anchorWrites = 0, scales = 0, width = 50, barWidth = 100, height = 24,
        hud = branch == "live" or branch == "forever", atlasExists = true }
    local env = setmetatable({}, { __index = _G })
    env.UF = { UsesHudUnitBars = function() return s.hud end }
    env.ValueIsSecret = function(v) return type(v) == "table" and v.secret end
    env.type = function(v) return env.ValueIsSecret(v) and "number" or type(v) end
    env.AtlasExists = function() return s.atlasExists end
    local texture = { shown = false }
    function texture:Hide() self.shown = false end
    function texture:Show() self.shown = true end
    function texture:ClearAllPoints() s.anchorWrites = s.anchorWrites + 1; self.point = nil end
    function texture:SetPoint(...)
        if s.failAnchor then error("temporary anchor failure") end
        s.anchorWrites = s.anchorWrites + 1; self.point = { ... }
    end
    function texture:SetAtlas(atlas)
        if s.failAtlas then error("temporary atlas failure") end
        s.atlasWrites = s.atlasWrites + 1; self.atlas = atlas
    end
    function texture:SetScale(scale)
        if s.failScale then error("temporary scale failure") end
        s.scales = s.scales + 1; self.scale = scale
    end
    local fill = { GetWidth = function() return s.width end, GetHeight = function() return s.height end }
    local bar = { Spark = texture, GetWidth = function() return s.barWidth end, GetStatusBarTexture = function() return s.fill end }
    s.fill = fill
    local info = { atlas = "spark", barHeight = 12, xOffset = 2 }
    assert(load(text, "@resource-spark-" .. branch, "t", env))()
    local paint = function() env.UF.UpdateResourceSpark(bar, info) end
    if not s.hud then
        paint(); check(not texture.shown and s.atlasWrites == 0 and not texture.isActive,
            "classic clients retain existing HUD spark gate")
    end
    -- Exercise the capability path independently of the client name too.
    s.hud = true
    for _ = 1, 300 do paint(); check(texture.shown and texture.visualInfo == info, "spark remains visible at partial power") end
    local writes = s.anchorWrites + s.atlasWrites + s.scales
    if not old then check(writes == 4, "unchanged spark retains completed geometry and atlas") end
    s.width = 100; paint(); check(not texture.shown, "full resource hides spark immediately")
    info.showAtMax = true; paint(); check(texture.shown, "show-at-max option remains immediate")
    s.width = 0; paint(); check(not texture.shown, "empty resource hides spark")
    s.width = 35; s.height = 36; paint(); check(texture.shown and texture.scale == 3, "resize updates spark scale")
    info.barHeight = 18; paint(); check(texture.scale == 2, "changed atlas reference height updates scale")
    info.atlas, info.xOffset = "other-spark", 7; paint()
    check(texture.atlas == "other-spark" and texture.point[4] == 7, "in-place style changes invalidate cache")
    s.fill = {}; for k, v in pairs(fill) do s.fill[k] = v end; paint()
    check(texture.point[2] == s.fill, "replacement status-bar fill reanchors")
    s.fill = nil; paint(); check(texture.point[2] == bar and texture.point[3] == "LEFT" and not texture.shown,
        "missing fill retains original fallback")
    s.fill = fill; paint()
    s.atlasExists = false; paint(); check(not texture.shown and not texture.isActive, "missing atlas hides spark")
    s.atlasExists = true; paint(); check(texture.shown, "late atlas readiness retries")
    bar.Spark = nil; paint(); bar.Spark = texture
    if not old then
        info.xOffset = 8; s.failAnchor = true; check(not pcall(paint), "failed anchor propagates")
        s.failAnchor = false; paint(); check(texture.point[4] == 8, "failed anchor retries")
        info.atlas = "retry-spark"; s.failAtlas = true; check(not pcall(paint), "failed atlas propagates")
        s.failAtlas = false; paint(); check(texture.atlas == "retry-spark", "failed atlas retries")
        s.height = 48; s.failScale = true; check(not pcall(paint), "failed scale propagates")
        s.failScale = false; paint(); check(texture.scale == 48 / 18, "failed scale retries")
        local secret = setmetatable({ secret = true }, { __add = function(self) return self end,
            __lt = function() error("secret comparison") end, __le = function() error("secret comparison") end })
        local scaleWrites = s.scales; s.height = secret
        paint(); check(s.scales == scaleWrites, "secret height is never compared, cached or scaled")
        s.width = secret; paint(); check(not texture.shown, "secret width keeps guarded visibility behavior")
        s.height, s.width = 24, 40; paint(); check(texture.shown, "readable display resumes after secrets")
    end
    return writes
end

local oldFrames, newFrames, oldWrites, newWrites
for _, branch in ipairs(branches) do
    oldFrames, newFrames = watchers(branch, oldPower, true), watchers(branch, power)
    oldWrites, newWrites = spark(branch, oldSpark, true), spark(branch, sparkCode)
    check(oldFrames == 201 and newFrames == 1, "retained old code demonstrates frame accumulation")
    check(oldWrites == 1200 and newWrites == 4, "retained old code demonstrates redundant spark styling")
end
local mutants = {
    { "watcher reuse", power, 'local watcher = frame.PowerCostWatcher', 'local watcher = nil', watchers, 'reapplying options reuses' },
    { "disabled callback", power, 'frame.PowerCostWatcher:SetScript("OnEvent", nil)', '-- omitted', watchers, 'disabled watcher is inert' },
    { "disabled ghost", power, '        StopBarFeedback(bar)\n        bar._fluxGhostPrimed = nil', '        bar._fluxGhostPrimed = nil', watchers, 'disable invalidates pending ghost' },
    { "spark atlas", sparkCode, 'if spark._fluxSparkAtlas ~= sparkInfo.atlas then', 'if true then', spark, 'unchanged spark retains' },
    { "spark fill", sparkCode, 'spark._fluxAnchorRelative ~= relative', 'false', spark, 'replacement status-bar fill' },
    { "spark scale", sparkCode, 'if spark._fluxSparkScale ~= scale then', 'if true then', spark, 'unchanged spark retains' },
    { "secret height", sparkCode, 'and not ValueIsSecret(h)', '', spark, 'secret comparison' },
}
for _, m in ipairs(mutants) do
    local ok, err = pcall(m[5], "forever", replace(m[2], m[3], m[4]))
    check(not ok and tostring(err):find(m[6], 1, true), "mutation rejected: " .. m[1] .. ": " .. tostring(err))
end
print(string.format("unit resource lifecycle: %d checks, five client models, %d mutations rejected", checks, #mutants))
print(string.format("  100 option/enable cycles: watcher frames %d -> %d; 300 spark paints: style writes %d -> %d",
    oldFrames, newFrames, oldWrites, newWrites))
