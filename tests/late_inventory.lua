-- Production adapter readiness handoff, with native inventory facts mocked.
local env = setmetatable({}, { __index = _G })
env._G = env
local callbacks, requests, rebuilds, starts = {}, 0, 0, 0
local ready = false
local inv = {
    Syndicator = {}, Containers = { NewItemSetLog = function() return {} end },
    Request = function() requests = requests + 1 end,
    HasWarband = function() return false end,
    Store = { SetUsesSyndicator = function(value) env.usesSyndicator = value end },
    source = "builtin",
}
local ns = { Flux = { Inventory = inv, Timer = { After = function(_, fn) fn() end }, Events = { Register = function() end },
    Scheduler = { Request = function() requests = requests + 1 end } } }
env.GetTime = function() return 0 end
assert(loadfile("Inventory/Syndicator/Adapter.lua", "t", env))("_FluxUI", ns)
inv.Syndicator.RebuildAll = function() rebuilds = rebuilds + 1 end
inv.Builtin = { Start = function() starts = starts + 1; inv.source = "builtin" end }
assert(inv.Syndicator.Start() == false, "absent provider remains retryable")
env.Syndicator = { API = { IsReady = function() return ready end }, CallbackRegistry = { RegisterCallback = function(_, event, fn)
    assert(callbacks[event] == nil, "no duplicate provider callbacks")
    callbacks[event] = fn
end } }
inv.Syndicator.Start()
assert(inv.source == "builtin" and rebuilds == 0 and callbacks.Ready, "native facts remain available before readiness")
ready = true
callbacks.Ready()
assert(inv.source == "syndicator" and rebuilds == 1 and env.usesSyndicator == true, "late source handoff")
callbacks.Ready()
inv.Syndicator.Start()
assert(rebuilds == 1 and requests == 8 and starts == 0, "handoff is idempotent and refreshes each region once")
print("late inventory: absent, pending, ready and duplicate readiness handoffs passed")
