-- Actual overlay modules with explicit opaque sentinels. Desktop Lua cannot
-- reproduce WoW's secure VM; fake type() results and trapped arithmetic catch
-- unsafe branches, while cache/sink assertions cover the permitted boundary.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local healthPath = arg[1] or "UnitFrames/FluxHealthLossOverlay.lua"
local powerPath = arg[2] or "UnitFrames/FluxPowerCostOverlay.lua"
local checks = 0
local function check(v, label) assert(v, label); checks = checks + 1 end
local base = read("tests/mp5_mana_ticks.lua")
base = base:sub(1, assert(base:find('for _,branch in ipairs({"era","anniversary","tbc","forever"})do', 1, true)) - 1)
base = base:gsub('loadAddon%("UnitFrames/FluxPowerCostOverlay.lua",e,ns%)',
    function() return "loadAddon(" .. string.format("%q", powerPath) .. ",e,ns)" end)
local make = assert(load(base .. "\nreturn fixture", "@overlay-shared-fixture", "t", _G))()
local rawtype = type

local function fixture(hud)
    local s, e, ns = make(hud and "forever" or "era", 100)
    s.guid, s.health, s.healthMax = "guid-player", 100, 100
    s.opaqueOps, s.lossUpdates, s.lossWrites, s.predictions = 0, 0, 0, 0
    function s:secret(kind)
        local function forbidden() self.opaqueOps = self.opaqueOps + 1; error("opaque operation") end
        return setmetatable({ secret = true, secretKind = kind }, {
            __eq = forbidden, __add = forbidden, __sub = forbidden, __div = forbidden,
            __mul = forbidden, __lt = forbidden, __le = forbidden, __tostring = forbidden,
        })
    end
    e.type = function(v)
        if rawtype(v) == "table" and rawget(v, "secretKind") then return rawget(v, "secretKind") end
        return rawtype(v)
    end
    ns.API.IsSecretValue = function(v) return rawtype(v) == "table" and rawget(v, "secret") == true end
    ns.API.CanAccessValue = function(v)
        return not ns.API.IsSecretValue(v) and not (rawtype(v) == "table" and rawget(v, "inaccessible"))
    end
    e.UnitGUID = function() return s.guid end
    e.UnitHealth = function() return s.health end
    e.UnitHealthMax = function() return s.healthMax end
    e.UnitGetTotalAbsorbs = function() return 0 end
    e.UnitExists = function() return true end
    e.UnitCastingInfo = function()
        if s.cast then return "cast", nil, nil, 100, 200, nil, nil, nil, s.cast end
    end
    e.UnitChannelInfo = function() end
    e.C_Spell = { GetSpellPowerCost = function() return { { type = 0, cost = 20 } } end }
    e.GetCVar = function() return "1" end
    e.GetCVarBool = function() return true end
    local methods = getmetatable(s.player).__index
    function methods:CreateAnimationGroup()
        local g = { scripts = {} }
        function g:SetToFinalAlpha() end
        function g:SetScript(k, fn) self.scripts[k] = fn end
        function g:Play() self.playing = true end
        function g:Stop() self.playing = false end
        function g:CreateAnimation()
            return setmetatable({}, { __index = function() return function() end end })
        end
        return g
    end
    ns.UnitFrames.UsesHudUnitBars = function() return hud end
    ns.PlayerFrame = s.player
    s.player.Health = e.CreateFrame("StatusBar", nil, s.player)
    s.player.Health:SetStatusBarTexture("health")
    local loss = e.CreateFrame("StatusBar", nil, s.player.Health)
    function loss:UpdateFromPixels(current, previous, width)
        s.lossUpdates = s.lossUpdates + 1; s.lastLoss = { current, previous, width }
    end
    local nativeValue = loss.SetValue
    function loss:SetValue(v) s.lossWrites = s.lossWrites + 1; nativeValue(self, v) end
    s.player.Health.AnimatedLossBar = loss
    assert(loadfile(healthPath, "t", e))("_FluxUI", ns)
    s.hlo, s.pco, s.ns, s.env = ns.HealthLossOverlay, ns.PowerCostOverlay, ns, e
    s.hlo.Initialize(s.player)
    s.realPrediction = s.pco.RefreshPrediction
    s.pco.RefreshPrediction = function() s.predictions = s.predictions + 1 end
    function s:healthSample(value, width)
        self.hlo.OnBeforeHealthValueSet(self.player.Health)
        self.health = value; self.player.Health.fill.width = width
        self.hlo.OnAfterHealthValueSet(self.player.Health)
    end
    function s:powerSample(value, width)
        self.player.Power.fill.width = width
        self.pco.AfterPowerApplied(self.player.Power, self.player.unit, value, 100)
    end
    return s
end

local function healthCases()
    local s = fixture(true)
    s:healthSample(100, 100); s:healthSample(80, 80)
    check(s.lossUpdates == 1 and s.lastLoss[1] == 80, "readable health damage keeps its loss trail")
    s.guid = "guid-other"; s:healthSample(60, 60)
    check(s.lossUpdates == 1 and s.player.Health._fluxLossGUID == s.guid,
        "readable GUID change primes a new unit instead of cross-unit damage")
    s.guid = s:secret("string"); s:healthSample(50, 50)
    check(s.player.Health._fluxLossGUID == "guid-other" and s.lossUpdates == 2,
        "opaque health identity preserves the last readable GUID and the first restricted hit")
    s.guid = s:secret("string"); s:healthSample(40, 40)
    check(s.lossUpdates == 3 and s.opaqueOps == 0, "opaque identity samples retain damage feedback without comparison")
    s.player.Health._fluxLossGUID = s:secret("string")
    s:healthSample(30, 30)
    check(s.opaqueOps == 0 and s.player.Health._fluxLossGUID == nil, "previous opaque GUID cache is rejected before comparison")
    s.hlo.ResetIdentityForFrame(s.player)
    local previous = s.lossUpdates
    s:healthSample(90, 90); s:healthSample(70, 70)
    check(s.lossUpdates == previous + 1, "opaque unit-change event primes once then preserves subsequent loss")
    s.guid = "guid-readable"; s:healthSample(60, 60)
    check(s.lossUpdates == previous + 2, "first readable identity after an opaque-only unit preserves damage feedback")
    s:healthSample(0, 0); s:healthSample(100, 100)
    check(s.lossUpdates == previous + 3, "zero health and resurrection do not create a healing loss trail")
    s.player.unit = "focus"; s.hlo.Initialize(s.player); previous = s.lossUpdates
    s:healthSample(50, 50)
    check(s.lossUpdates == previous, "health unit-token rebind clears the previous unit samples")

    local secret = fixture(true)
    secret.guid = secret:secret("string")
    secret:healthSample(secret:secret("number"), secret:secret("number"))
    secret:healthSample(secret:secret("number"), secret:secret("number"))
    check(secret.opaqueOps == 0 and secret.player.Health._fluxLossSecretPending and #secret.timers == 1,
        "secret health width uses the existing delayed native-value catch-up without arithmetic")
    local queued = secret.timers[1]
    secret.hlo.ResetIdentityForFrame(secret.player)
    local writes = secret.lossWrites; queued()
    check(secret.lossWrites == writes and not secret.player.Health.AnimatedLossBar:IsShown(),
        "opaque unit swap invalidates the previous delayed catch-up")
    secret.hlo.DisableForHealthBar(secret.player.Health)
    secret:healthSample(80, 80)
    check(not secret.player.Health._fluxHealthLossUnderlay and secret.lossWrites == writes,
        "disabled health overlay does no sample or catch-up work")

    local classic = fixture(false)
    classic:healthSample(100, 100); classic:healthSample(70, 70)
    check(classic.player.Health.ClassicLossTex:IsShown(), "Classic readable health retains the visible loss texture")
    classic.healthMax = classic:secret("number"); classic:healthSample(classic:secret("number"), 60)
    check(classic.opaqueOps == 0 and classic.player.Health._fluxLossPrevHealth == 70,
        "number-typed opaque health/max never reach comparisons or replace a readable Classic sample")
    classic.healthMax = 0; classic:healthSample(0, 0)
    check(classic.player.Health._fluxLossPrevHealth == 70,
        "zero health maximum is not used as a divisor or cached as an invalid sample")
end

local function powerCases()
    local s = fixture(true)
    s:powerSample(100, 100); s:powerSample(100, 100); s:powerSample(60, 60)
    check(s.player.Power.FeedbackFrame and s.player.Power.FeedbackFrame.updatingLoss,
        "readable power spending keeps the loss flash")
    s.guid = s:secret("string"); s:powerSample(50, 50)
    check(s.player.Power._fluxFeedbackGUID == "guid-player", "opaque power identity preserves only the last readable GUID")
    s.guid = s:secret("string"); s:powerSample(45, 45); s:powerSample(20, 20)
    check(s.player.Power.FeedbackFrame.updatingLoss and s.opaqueOps == 0,
        "repeated opaque identities keep spending feedback")
    s.player.Power._fluxFeedbackGUID = s:secret("string"); s:powerSample(10, 10)
    check(s.opaqueOps == 0 and s.player.Power._fluxFeedbackGUID == nil,
        "old opaque power identity is discarded before equality")
    s.pco.ResetIdentityForFrame(s.player); s:powerSample(90, 90)
    check(not s.player.Power.FeedbackFrame.updatingLoss and s.player.Power._fluxGhostPrimed,
        "opaque unit swap primes the current ghost and clears cross-unit feedback")
    s.player.Power._fluxPrevFillW = s:secret("number")
    s:powerSample(80, s:secret("number"))
    check(s.opaqueOps == 0 and s.player.Power._fluxPrevFillW == nil,
        "opaque old/current fill widths never participate in feedback math")
    s.player.Power._fluxCastUnitGUID = s:secret("string")
    s.player.Power._fluxCastFinish = true; s:powerSample(70, 70)
    check(s.opaqueOps == 0 and not s.player.Power._fluxCastFinish,
        "previous opaque cast identity cannot authorize a completion flash")

    local changed = fixture(true)
    changed.player.unit = "target"; changed.ns.TargetFrame = changed.player
    changed.guid, changed.cast = "public-before", 42
    changed.pco.Initialize(changed.player)
    changed.guid, changed.cast = "public-after", nil
    local changedWatcher = changed.player.PowerCostWatcher
    changedWatcher.scripts.OnEvent(changedWatcher, "UNIT_SPELLCAST_SUCCEEDED", "target", "cast", 42)
    check(not changed.player.Power._fluxCastFinish,
        "unequal readable GUIDs cannot use the same-unit-token completion fallback")

    for _, opaque in ipairs({ false, true }) do
        local cast = fixture(true)
        cast.player.unit = "target"; cast.ns.TargetFrame = cast.player
        cast.guid = opaque and cast:secret("string") or "guid-target"
        cast.cast = 42; cast.pco.Initialize(cast.player)
        local bar, watcher = cast.player.Power, cast.player.PowerCostWatcher
        check(bar._fluxPredictedCost == 20 and not cast.ns.API.IsSecretValue(bar._fluxCastUnitGUID),
            "active cast preview stores only readable identity metadata")
        cast.guid = opaque and "same-unit-now-readable" or cast:secret("string")
        cast.cast = nil
        watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_SUCCEEDED", "target", "cast", 42)
        check(bar._fluxCastFinish and cast.opaqueOps == 0, "readable/opaque cast completion marks feedback without comparing secrets")
        cast.guid = opaque and cast:secret("string") or "guid-target-new"
        watcher.scripts.OnEvent(watcher, "PLAYER_TARGET_CHANGED")
        check(not bar._fluxCastFinish and not bar._fluxCastUnit and bar._fluxPredictedCost == nil,
            "target-change watcher clears old cast identity before reusing the token")
        cast.cast = 43; watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_START", "target", "cast", 43)
        check(bar._fluxPredictedCost == 20 and bar._fluxCastUnit == "target",
            "new target cast still previews with either identity visibility")
        cast.player.unit = "focus"; cast.pco.Initialize(cast.player)
        check(cast.player.PowerCostWatcher == watcher and watcher.unit == "focus",
            "watcher token rebind resets state without creating a replacement frame")
    end

    for _, opaque in ipairs({ false, true }) do
        local pet = fixture(true)
        pet.player.unit = "pet"; pet.ns.PetFrame = pet.player
        pet.guid = opaque and pet:secret("string") or "pet-before"
        pet.cast = 42; pet.pco.Initialize(pet.player)
        local bar, watcher = pet.player.Power, pet.player.PowerCostWatcher
        check(watcher.events.UNIT_PET == "player", "pet watcher filters identity events to its player owner")
        pet.guid = opaque and pet:secret("string") or "pet-after"; pet.cast = nil
        watcher.scripts.OnEvent(watcher, "UNIT_PET", "target")
        check(bar._fluxCastUnit == "pet" and bar._fluxPredictedCost == 20,
            "another owner's pet event cannot clear this pet's cast preview")
        watcher.scripts.OnEvent(watcher, "UNIT_PET", "player")
        check(not bar._fluxCastUnit and not bar._fluxCastFinish and bar._fluxPredictedCost == nil,
            "readable/opaque pet swap clears old cast identity and preview")
        watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_SUCCEEDED", "pet", "cast", 42)
        check(not bar._fluxCastFinish and pet.opaqueOps == 0,
            "completion from a replaced pet cannot use a stale same-token fallback")
        pet.cast = 43; watcher.scripts.OnEvent(watcher, "UNIT_PET", "player")
        check(bar._fluxCastUnit == "pet" and bar._fluxPredictedCost == 20
            and pet.player.PowerCostWatcher == watcher,
            "pet replacement restores its active cast using the existing watcher")
    end
    local healthOnly = fixture(true)
    local frames = #healthOnly.frames
    healthOnly.pco.Initialize({ unit = "pettarget", HealthBar = {} })
    check(#healthOnly.frames == frames, "current health-only pet-target frame does not mount power feedback")

    local prediction = fixture(true)
    local bar = prediction.player.Power
    prediction.pco.CreateOverlay(bar)
    bar._fluxPredictedCost, bar._fluxPredictMax = 20, 100
    prediction.realPrediction(bar)
    check(bar.CostOverlay:IsShown() and bar.CostOverlay.width == 40,
        "readable cost/max retain the same preview width")
    bar._fluxPredictedCost, bar._fluxPredictMax = prediction:secret("number"), prediction:secret("number")
    prediction.realPrediction(bar)
    check(prediction.opaqueOps == 0 and bar._fluxCostMeter,
        "number-typed opaque cost/max reach native meter sinks instead of Lua arithmetic")
end

if arg[3] == "--measure" then
    local s = fixture(true)
    s:healthSample(100, 100); s:powerSample(100, 100)
    local started = os.clock()
    for i = 1, 10000 do
        local v = 80 + i % 2
        s:healthSample(v, v); s:powerSample(v, v)
    end
    print("OVERLAY_MODEL", string.format("%.6f", (os.clock() - started) * 1000),
        s.lossUpdates, s.lossWrites, #s.frames, #s.timers, s.opaqueOps)
else
    healthCases(); powerCases()
    print("Unit overlay secret identity: " .. checks .. " checks passed (native taint/rendering unverified)")
end
