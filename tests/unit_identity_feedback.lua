-- Actual Shared.OnEvent routing and actual health-loss identity reset.
-- Geometry/paint sinks are fixtures; native rendering and event order need WoW.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n"); file:close(); return source
end
local function section(source, first, last)
    local a = assert(source:find(first, 1, true))
    local b = assert(source:find(last, a + #first, true))
    return source:sub(a, b - 1)
end
local shared = read((arg and arg[1]) or "UnitFrames/FluxUnitFrames_Shared.lua")
local health = read("UnitFrames/FluxHealthLossOverlay.lua")
local checks = 0
local function check(value, message) assert(value, message); checks = checks + 1 end
local function fixture(source, disabled, missingChild)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local s = { log = {}, frames = {}, timers = {}, powerResets = 0 }
    local ns, uf, hlo = {}, {}, {}
    env.ns, env.UF, env.HLO = ns, uf, hlo
    ns.PowerCostOverlay = { ResetIdentityForFrame = function()
        s.powerResets = s.powerResets + 1; error("Shared must not reset power feedback")
    end }
    local function display()
        return { shown = true, Hide = function(self) self.shown = false end }
    end
    for _, unit in ipairs({ "player", "target", "targettarget", "focus", "focustarget", "pet", "pettarget" }) do
        s.frames[unit] = { unit = unit, Health = {
            _fluxHealthLossUnderlay = disabled ~= "bar",
            _fluxLossPrimed = true, _fluxLossGUID = "old", _fluxLossSecretPending = true,
            _fluxLossSecretSeq = 0, ClassicLossTex = display(), AnimatedLossBar = display(),
        } }
    end
    ns.TargetFrame, ns.TargetOfTargetFrame = s.frames.target, s.frames.targettarget
    ns.FocusTargetFrame, ns.PetTargetFrame = s.frames.focustarget, s.frames.pettarget
    if missingChild then ns[missingChild] = nil end
    local resetSource = section(health, "local function HideClassicLoss(healthBar)", "local function DriveClassicLoss")
        .. section(health, "function HLO.ResetIdentityForFrame(frame)", "local function ReadableHealth")
    assert(load(resetSource, "@actual-health-identity-reset", "t", env))()
    local actualReset = hlo.ResetIdentityForFrame
    hlo.ResetIdentityForFrame = function(frame)
        if frame then s.log[#s.log + 1] = "reset:" .. frame.unit end
        actualReset(frame)
    end
    if disabled ~= "module" then ns.HealthLossOverlay = hlo end
    if disabled == "method" then ns.HealthLossOverlay = {} end
    env.GetTime = function() return 1 end
    env.UnitGUID = function() error("identity-event routing must not probe GUIDs") end
    env.C_Timer = { After = function(_, callback) s.timers[#s.timers + 1] = callback end }
    uf.UpdateHealth = function(frame)
        s.log[#s.log + 1] = "health:" .. frame.unit
        if s.expectFresh and s.expectFresh[frame.unit] then
            assert(frame.Health._fluxLossPrimed == nil,
                frame.unit .. ": old identity must clear before the first health paint")
        end
    end
    for _, method in ipairs({ "UpdatePower", "UpdatePortrait", "UpdatePortraitCombatTint",
        "UpdateFrameVisualElements", "UpdateBorderColors", "UpdateThreatBar", "UpdateAuras",
        "SyncWatchedUnitFrameVisibility" }) do uf[method] = function() end end
    local sync = section(source, "local function SyncRelatedWatchedFrames(self)", "--- Accessible name for painting.")
    local events = section(source, "local OUTER_BORDER_POWER_HEALTH_THROTTLE", "-- Emulated horizontal squeeze")
    s.onEvent = assert(load(sync .. events .. "\nreturn OnEvent", "@actual-shared-identity-events", "t", env))()
    return s
end

local function runCase(source, case)
    local s = fixture(source, case.disabled, case.missingChild)
    s.expectFresh = not case.disabled and case.resets or nil
    s.onEvent(s.frames[case.unit], case.event, case.payload)
    local actual = {}
    for _, entry in ipairs(s.log) do
        local unit = entry:match("^reset:(.+)$")
        if unit then actual[unit] = (actual[unit] or 0) + 1 end
    end
    if case.disabled == "module" or case.disabled == "method" then
        check(next(actual) == nil, case.label .. ": optional overlay has no reset calls")
    else
        for unit in pairs(s.frames) do
            check((actual[unit] or 0) == ((case.resets and case.resets[unit]) and 1 or 0),
                case.label .. ": exact affected identity " .. unit)
        end
    end
    if case.disabled == "bar" then
        for _, frame in pairs(s.frames) do
            check(frame.Health._fluxLossSecretSeq == 0 and frame.Health._fluxLossPrimed,
                case.label .. ": disabled bar has no feedback work")
        end
    end
    check(s.powerResets == 0, case.label .. ": independent power-event owner remains intact")
    return s
end

local function exercise(source)
    for _, case in ipairs({
        { label="target swap parent", unit="target", event="PLAYER_TARGET_CHANGED", resets={target=true,targettarget=true} },
        { label="focus swap parent", unit="focus", event="PLAYER_FOCUS_CHANGED", resets={focus=true,focustarget=true} },
        { label="target swap child", unit="targettarget", event="PLAYER_TARGET_CHANGED", resets={targettarget=true} },
        { label="focus swap child", unit="focustarget", event="PLAYER_FOCUS_CHANGED", resets={focustarget=true} },
        { label="target changes target parent", unit="target", event="UNIT_TARGET", payload="target", resets={targettarget=true} },
        { label="focus changes target parent", unit="focus", event="UNIT_TARGET", payload="focus", resets={focustarget=true} },
        { label="pet changes target parent", unit="pet", event="UNIT_TARGET", payload="pet", resets={pettarget=true} },
        { label="target changes target child", unit="targettarget", event="UNIT_TARGET", payload="target", resets={targettarget=true} },
        { label="focus changes target child", unit="focustarget", event="UNIT_TARGET", payload="focus", resets={focustarget=true} },
        { label="pet changes target child", unit="pettarget", event="UNIT_TARGET", payload="pet", resets={pettarget=true} },
        { label="pet replacement owner payload", unit="pet", event="UNIT_PET", payload="player", resets={pet=true,pettarget=true} },
        { label="pet target replacement owner payload", unit="pettarget", event="UNIT_PET", payload="player", resets={pettarget=true} },
        { label="world boolean true payload", unit="target", event="PLAYER_ENTERING_WORLD", payload=true, resets={target=true,targettarget=true} },
        { label="world boolean false payload", unit="focus", event="PLAYER_ENTERING_WORLD", payload=false, resets={focus=true,focustarget=true} },
        { label="world legacy no payload", unit="pettarget", event="PLAYER_ENTERING_WORLD", resets={pettarget=true} },
        { label="ordinary name update", unit="target", event="UNIT_NAME_UPDATE", payload="target" },
        { label="ordinary health", unit="target", event="UNIT_HEALTH", payload="target" },
        { label="ordinary power", unit="target", event="UNIT_POWER_UPDATE", payload="target" },
        { label="unrelated health", unit="target", event="UNIT_HEALTH", payload="party1" },
        { label="unrelated target", unit="target", event="UNIT_TARGET", payload="party1" },
        { label="unrelated pet", unit="pet", event="UNIT_PET", payload="party1" },
        { label="other identity event", unit="focus", event="PLAYER_TARGET_CHANGED" },
        { label="missing target child", unit="target", event="PLAYER_TARGET_CHANGED", missingChild="TargetOfTargetFrame", resets={target=true} },
        { label="overlay absent", unit="target", event="PLAYER_TARGET_CHANGED", disabled="module" },
        { label="overlay method absent", unit="target", event="PLAYER_TARGET_CHANGED", disabled="method" },
        { label="overlay disabled", unit="target", event="PLAYER_TARGET_CHANGED", disabled="bar", resets={target=true,targettarget=true} },
    }) do runCase(source, case) end
end

exercise(shared)
local function replace(source, old, new)
    local a,b = assert(source:find(old,1,true)); return source:sub(1,a-1)..new..source:sub(b+1)
end
local function rejects(source, message)
    local before = checks
    local accepted = pcall(exercise, source)
    checks = before
    check(not accepted, message)
end
local invocation = "    if HEALTH_LOSS_IDENTITY_EVENTS[event] then\n        ResetHealthLossForIdentityEvent(self, event, unit)\n    end\n"
local afterFilter = "    -- Full partition (portrait, atlas, separators, anchors) deferred from combat lockdown"
local moved = replace(shared, invocation, "")
moved = replace(moved, afterFilter, invocation .. afterFilter)
rejects(moved, "regression rejects identity resets after the unit filter")
local omitted = replace(shared, invocation, "")
rejects(omitted, "regression rejects missing event integration")
local oldExit = replace(shared, "    if changed then loss.ResetIdentityForFrame(self) end",
    "    if not changed then return end\n    loss.ResetIdentityForFrame(self)")
rejects(oldExit, "regression rejects skipped parent UNIT_TARGET child reset")
print("Unit identity feedback: " .. checks .. " checks passed; three routing mutations rejected")
