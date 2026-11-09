-- Actual Shared power painter and PCO module. Native sink rejection is a model
-- of the source contract, not certification of WoW's secure VM or frame time.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local powerPath = arg[1] or "UnitFrames/FluxPowerCostOverlay.lua"
local sharedPath = arg[2] or "UnitFrames/FluxUnitFrames_Shared.lua"
local measure = arg[3] == "--measure"
local checks = 0
local function check(v, label) assert(v, label); checks = checks + 1 end
local function slice(s, first, last)
    local a = assert(s:find(first, 1, true)); local b = assert(s:find(last, a + #first, true)); return s:sub(a, b - 1)
end
local shared = read(sharedPath)
local base = read("tests/unit_overlay_secret_identity.lua")
base = base:sub(1, assert(base:find("local function healthCases()", 1, true)) - 1)
local context = setmetatable({ arg = { "UnitFrames/FluxHealthLossOverlay.lua", powerPath } }, { __index = _G })
local make = assert(load(base .. "\nreturn fixture", "@snapshot-shared-fixture", "t", context))()
local function noop() end

local function fixture(hud, opaque, enabled)
    local s = make(hud)
    s.enabled, s.opaque = enabled, opaque
    s.snapshotWrites, s.secretSizeAttempts, s.paints, s.valueWrites = 0, 0, 0, 0
    s.uf, s.api = s.ns.UnitFrames, s.ns.API
    local env, uf, api = s.env, s.uf, s.api
    env.UF, env.API, env.ns = uf, api, s.ns
    env.ValueIsSecret = api.IsSecretValue
    env.UnitPowerType = function() return s.powerType, s.powerType == 0 and "MANA" or "ENERGY" end
    api.GetPowerPercent100 = function() return 50 end
    env.FluxUnitFrames_ShouldShowPowerText = function() return false end
    env.StatusBarSetMinMaxAndValueImmediate = function(bar, low, maximum, value)
        s.valueWrites = s.valueWrites + 1
        bar:SetMinMaxValues(low, maximum); bar:SetValue(value)
        if api.IsSecretValue(value) then bar.fill.width = s:secret("number")
        else bar.fill.width = value / maximum * bar.width end
    end
    uf.UnitIsAFKDisplay = function() return false end
    uf.UpdateHealth, uf.ApplyResourceBarStyle = noop, noop
    uf.RefreshResourceConnection, uf.UpdateResourceSpark, uf.UpdateFullResourcePulse = noop, noop, noop
    s.pco.RefreshPrediction = s.realPrediction
    s.pco.CreateOverlay(s.player.Power)
    s.pco.CreateOverlay(s.player.AdditionalPower)
    local methods = getmetatable(s.player).__index
    local setWidth = methods.SetWidth
    function methods:SetWidth(value)
        if self == s.player.Power._fluxSpendAnchor or self == s.player.AdditionalPower._fluxSpendAnchor then
            s.snapshotWrites = s.snapshotWrites + 1
            if api.IsSecretValue(value) then
                s.secretSizeAttempts = s.secretSizeAttempts + 1
                error("SetWidth rejects restricted input in tainted context")
            end
        end
        return setWidth(self, value)
    end
    assert(load(slice(shared, "function UF.PowerValueForDisplay(bar, power)", "local RETAIL_POWER_TINT"),
        "@snapshot:display", "t", env))()
    assert(load(slice(shared, "function UF.UpdatePower(self, unit)", "function UF.CreatePowerBar(frame)"),
        "@snapshot:power-painter", "t", env))()
    function s:paint(value, secondary)
        self.paints = self.paints + 1
        self.mana = opaque and self:secret("number") or value
        if secondary then
            local bar = self.player.AdditionalPower
            -- The additional-power writer uses the same PCO before/value/after
            -- boundary; its removed Shared call is checked separately below.
            if self.pco.BeforePowerApplied then self.pco.BeforePowerApplied(bar) end
            env.StatusBarSetMinMaxAndValueImmediate(bar, 0, 100, self.mana)
            self.pco.AfterPowerApplied(bar, "player", self.mana, 100)
        else
            uf.UpdatePower(self.player, "player")
        end
        self.Flush()
    end
    function s:liveState(secondary)
        local b = secondary and self.player.AdditionalPower or self.player.Power
        local g, f, c = b.PowerGhost, b.FeedbackFrame, b.CostOverlay
        local function value(v) if api.IsSecretValue(v) then return "opaque" end; return tostring(v) end
        return table.concat({ value(b.value), value(g and g.value), value(g and g.high),
            value(g and g.shown), value(c and c.shown), value(c and c.width),
            value(f and f.updatingGain), value(f and f.updatingLoss), value(f and f.secretPlaying) }, "|")
    end
    return s
end

local function exercise()
    check(not shared:find("BeforePowerApplied", 1, true), "both Shared painters drop the unused snapshot callback")
    for _, hud in ipairs({ false, true }) do
        for _, opaque in ipairs({ false, true }) do
            for _, enabled in ipairs({ false, true }) do
                for _, secondary in ipairs({ false, true }) do
                    local s = fixture(hud, opaque, enabled)
                    check(s.pco.BeforePowerApplied == nil, "the unused internal callback is removed")
                    s:paint(100, secondary); s:paint(100, secondary)
                    for i = 1, 25 do s:paint(i % 2 == 0 and 100 or 60, secondary) end
                    local b = secondary and s.player.AdditionalPower or s.player.Power
                    check(not b._fluxSpendAnchor and s.snapshotWrites == 0 and s.secretSizeAttempts == 0,
                        "readable/restricted and disabled power updates allocate no unused snapshot frame or size writes")
                    check(s.valueWrites == 27 and s.opaqueOps == 0, "native bar values retain every power update without opaque arithmetic")
                    if enabled then
                        check(b.PowerGhost and b.PowerGhost:IsShown(), "the live previous-power ghost remains available")
                    else
                        check(not b.PowerGhost, "a disabled feature does not acquire a ghost through the removed snapshot")
                    end
                end
            end
        end
    end
    local gain = fixture(true, false, true); gain.powerType = 3
    gain:paint(50); gain:paint(50); gain:paint(100)
    check(gain.player.Power.FeedbackFrame.updatingGain, "readable builder feedback remains active")
    gain:paint(60)
    check(gain.player.Power.FeedbackFrame.updatingLoss, "readable spender feedback remains active")
    local secret = fixture(true, true, true)
    secret:paint(100); secret:paint(100)
    secret.player.Power._fluxCastFinish, secret.player.Power._fluxCastUnit = true, "player"
    secret:paint(60)
    local f = secret.player.Power.FeedbackFrame
    check(f and f.secretPlaying and f.SecretLossAnim.playing and f.SecretBarAnim.playing,
        "restricted cast-completion feedback retains both live ghost-based animations")
    local relative = f.BarTexture.point[2]
    check(relative == secret.player.Power.PowerGhost.fill,
        "live restricted spender slice stays anchored to the ghost rather than the removed snapshot")
    local cost = fixture(true, false, true)
    cost.player.Power._fluxPredictedCost, cost.player.Power._fluxPredictMax = 20, 100
    cost:paint(80)
    check(cost.player.Power.value == 60 and cost.player.Power.CostOverlay:IsShown(),
        "cost-shortened value and its preview remain visible")
end

if measure then
    for _, opaque in ipairs({ false, true }) do
        for _, secondary in ipairs({ false, true }) do
            local s = fixture(true, opaque, true)
            s:paint(100, secondary); s:paint(100, secondary)
            local started = os.clock()
            for i = 1, 10000 do s:paint(i % 2 == 0 and 100 or 60, secondary) end
            print("SNAPSHOT_MODEL", opaque and "opaque" or "plain", secondary and "secondary" or "primary",
                string.format("%.6f", (os.clock() - started) * 1000), #s.frames, s.snapshotWrites,
                s.secretSizeAttempts, s.valueWrites, s.opaqueOps, s:liveState(secondary))
        end
    end
else
    exercise()
    print("Power snapshot cleanup: " .. checks .. " checks passed (native secure/rendering/performance pending)")
end
