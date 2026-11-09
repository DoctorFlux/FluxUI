-- Execute the whole native-bar suppression module, not a copied guard.
local f = assert(io.open("Bars/Blizzard.lua", "rb")); local source = f:read("*a"):gsub("\r\n", "\n"); f:close()
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function exercise(branch, code)
    local editing, writes = true, 0
    local timers, after, callbacks = {}, {}, {}
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.FluxEditModeBusy = function() return editing end
    env.FluxAfterEditMode = function(fn, key) after[key or fn] = fn end
    env.MainActionBar = { SetAlpha = function() check(not editing, "native bar mutation during Edit Mode"); writes = writes + 1 end }
    env.EventRegistry = { RegisterCallback = function(_, key, fn) callbacks[key] = fn end }
    env.CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
    local modern = branch == "live" or branch == "forever"
    local flux = { Bars = { NUM_NATIVE = 0, secureReady = true }, Client = { isRetail = modern, isPostDF = modern },
        Combat = { InLockdown = function() return false end }, Timer = { Defer = function(fn) timers[#timers + 1] = fn end } }
    assert(load(code or source, "@production-bars-edit-mode", "t", env))("_FluxUI", { Flux = flux })
    local b = flux.Bars.Blizzard
    b.Prepare()
    for _ = 1, 4 do
        b.HideStockButtons(); b.KillLeftoverMouse(); b.HideUnusedBars(); b.QuietGrid(); b.QueueLeftoverMouse()
    end
    check(writes == 0 and #timers == 1, "startup and event bursts do not touch native bars during Edit Mode")
    local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
    local count = 0; for _ in pairs(after) do count = count + 1 end
    check(writes == 0 and count == 5, "each deferred entry coalesces without native mutations")
    check(callbacks["EditMode.Enter"] == nil, "v9/main policy retained: no native suppression sweep on Enter")
    if modern then check(callbacks["EditMode.Exit"] ~= nil, "modern exit reconciliation retained") end
    editing = false
    for _, fn in pairs(after) do fn() end
    check(writes > 0, "deferred suppression still runs after Edit Mode")
end
for _, branch in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do exercise(branch) end
local mutant, n = source:gsub('if FluxEditModeBusy and FluxEditModeBusy%(%) then', 'if false then')
check(n == 5 and not pcall(exercise, "live", mutant), "negative control rejects native bar changes during Edit Mode")
print("Bars Edit Mode: " .. checks .. " checks; five client models; negative control passed")
