-- Execute production registration and dispatch; no native method replacements
-- on modern clients, including when Edit Mode updates the queue eye's scale.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local source = read("Minimap/FluxMinimap.lua")
local start = assert(source:find("function FluxMinimap:EnsureQueueStatusEyeHooks()", 1, true))
source = source:sub(start, assert(source:find("\n-- --------", start, true)) - 1)
local micro = read("MicroMenu/FluxMicroMenu.lua")
start = assert(micro:find("local function EnsureFluxQueueStatusUpdateHook()", 1, true))
micro = micro:sub(start, assert(micro:find("--- Pre-DF Flux custom", start, true)) - 1)
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function exercise(branch, code)
    local modern = branch == "live" or branch == "forever"
    local hooks, timers, callbacks, after, events, scripts = {}, {}, {}, {}, {}, {}
    local busy, placements = false, 0
    local env = setmetatable({}, { __index = _G }); env._G = env
    local native = function() end
    local function frame() return { UpdatePosition = native, HookScript = function(_, event, fn) scripts[#scripts + 1] = fn end } end
    env.QueueStatusButton, env.QueueStatusFrame = frame(), frame()
    env.MiniMapBattlefieldFrame = not modern and frame() or nil
    env.FluxMinimap = { PositionQueueStatusEye = function() check(not busy, "placement waits for Edit Mode"); placements = placements + 1; return true end }
    env.FLUX_API = { isRetail = modern, isPostDF = modern }
    env.IsRetailPostDfQueueEye = function() return modern end
    env.FluxEditModeBusy = function() return busy end
    env.FluxAfterEditMode = function(fn) after[fn] = fn end
    env.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    env.hooksecurefunc = function(obj, key, fn) hooks[#hooks + 1] = { obj, key, fn } end
    env.EventRegistry = { RegisterCallback = function(_, key, fn) callbacks[key] = fn end }
    env.CreateFrame = function() return { RegisterEvent = function(_, key) events[key] = true end,
        SetScript = function(_, _, fn) env.dispatch = fn end } end
    assert(load(code or source, "@queue-eye-registration", "t", env))()
    env.FluxMinimap:EnsureQueueStatusEyeHooks(); env.FluxMinimap:EnsureQueueStatusEyeHooks()
    check(#hooks == (modern and 0 or 2), branch .. ": native modern methods remain unhooked; Classic refresh retained")
    check(env.QueueStatusButton.UpdatePosition == native and env.QueueStatusFrame.UpdatePosition == native,
        "native position method identity preserved")
    check(events.PLAYER_REGEN_ENABLED and events.DISPLAY_SIZE_CHANGED and events.UI_SCALE_CHANGED,
        "combat recovery and display changes retain eye placement")
    check((events.EDIT_MODE_LAYOUTS_UPDATED == true) == modern, "layout event uses actual client capability")
    env.dispatch(); env.dispatch(); callbacks["QueueStatusUpdate.QueuesUpdated"]()
    check(#timers == 1 and placements == 0, "refresh burst schedules one next-frame placement")
    busy = true; timers[1](); check(placements == 0 and next(after), "layout pass defers through Edit Mode")
    busy = false; for _, fn in pairs(after) do fn() end
    check(placements == 1, "deferred layout reconciles once")
    callbacks["EditMode.Exit"](); check(#timers == 2, "exit restores placement")
    timers[2](); check(placements == 2, "exit callback places eye")
    env.FluxMicroMenu = {}
    assert(load(micro .. "\nreturn EnsureFluxQueueStatusUpdateHook", "@micro-queue-eye", "t", env))()()
    check(#hooks == (modern and 0 or 3), "micro menu does not duplicate modern position hooks")
end
for _, branch in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do exercise(branch) end
local mutant, n = source:gsub('if not managesRetail and q and', 'if q and', 1)
check(n == 1 and not pcall(exercise, "live", mutant), "negative control rejects secure layout hook")
print("Queue eye lifecycle: " .. checks .. " checks; five client models; negative control passed")
