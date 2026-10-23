-- Actual optional bridge install: no load ordering dependency or combat timer race.
local env = setmetatable({}, { __index = _G }); env._G = env
local spec, timer, deferred
local combat, refreshes, hooks = false, 0, 0
local flux = {
    Module = { Register = function(_, value) spec = value end },
    Combat = { Defer = function(key, fn)
        assert(key == "unitframes.bigdebuffs.refresh"); deferred = fn
    end },
}
env.Flux = flux
env.InCombatLockdown = function() return combat end
env.hooksecurefunc = function() hooks = hooks + 1 end
env.C_Timer = { After = function(_, fn) assert(not timer); timer = fn end }
local ns = { Flux = flux, UnitFrames = {} }
assert(loadfile("UnitFrames/FluxUnitFrames_BigDebuffs.lua", "t", env))("_FluxUI", ns)
assert(spec.phase == "deferred" and spec.protected and spec.requiredAddons[1] == "BigDebuffs")
assert(spec.OnEnable() == false, "absent provider remains retryable")
env.BigDebuffs = { anchors = {}, db = { profile = { unitFrames = {} } }, AttachUnitFrame = function() end,
    Refresh = function() assert(not combat, "native refresh may not run locked down"); refreshes = refreshes + 1 end }
assert(spec.OnEnable() == true and env.BigDebuffs.anchors.FluxUI, "late install preserves anchor bridge")
assert(hooks == 1 and timer)
combat = true
local run = timer; timer = nil; run()
assert(refreshes == 0 and deferred, "lockdown rechecked when delayed refresh executes")
combat = false
deferred()
assert(refreshes == 1)
assert(spec.OnEnable() == true and not timer and hooks == 1, "completed bridge is idempotent")
print("optional BigDebuffs startup: late install, idempotency and execution-time combat deferral passed")
