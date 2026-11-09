-- lua WindowMover/_tmp_charactercombatsmoke.lua
-- Execute the mover's real attachment/layout logic. This models hook isolation,
-- not WoW's secure execution VM.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Compile(path, env)
    if setfenv then local f = assert(loadfile(root .. path)); setfenv(f, env); return f end
    return assert(loadfile(root .. path, "t", env))
end
local function Scenario(camelot, gamepad)
    local hooks, scripts, callbacks, pending = {}, {}, {}, {}
    local combat, scaleWrites = false, 0
    local frame = { IsProtected = function() return true end, IsMouseEnabled = function() return true end,
        GetName = function() return "CharacterFrame" end, SetPoint = function() end,
        SetScale = function() scaleWrites = scaleWrites + 1 end }
    function frame:HookScript(name, callback) scripts[name] = callback end
    local mover = { IsFrame = function(value) return value == frame end,
        Resolve = function() return frame end, ShouldSkip = function() return false end,
        IsBlacklisted = function() return false end, FindDragHandles = function() return { frame } end }
    local flux = { Client = { isCamelot = camelot }, WindowMover = mover,
        Cap = { IsForeverGamepadUI = function() return camelot and gamepad end },
        Combat = { InLockdown = function() return combat end,
            Defer = function(key, callback) pending[key] = callback end } }
    local env = setmetatable({ Flux = flux, FluxInfoFrame = {
        AfterCharacterShown = function(callback) callbacks[#callbacks + 1] = callback end },
        FluxOptions = { GetWindowMoverDB = function() return {
            enabled = true, scaleEnabled = true, frames = { CharacterFrame = { scale = 1.2 } } } end },
        hooksecurefunc = function(object, key, callback) hooks[key] = callback end,
    }, { __index = _G }); env._G = env
    Compile("WindowMover/Engine.lua", env)("_FluxUI", { Flux = flux })
    assert(mover.Attach({ name = "CharacterFrame" }))
    local initialWrites = scaleWrites
    if camelot then
        assert(not hooks.SetPoint and not hooks.SetScale, "mover hooked the native character open path")
        assert(not scripts.OnShow and not scripts.OnHide, "mover hooked native character show/hide")
        assert(#callbacks == 1, "saved layout lost its independent post-open refresh")
        callbacks[1]()
        assert(scaleWrites == initialWrites + 1, "post-open refresh failed to restore saved scale")
        combat = true
        callbacks[1]()
        assert(scaleWrites == initialWrites + 1, "mover changed a protected frame in combat")
        assert(pending["windowmover.apply.CharacterFrame"])
        combat = false
        pending["windowmover.apply.CharacterFrame"]()
        assert(scaleWrites == initialWrites + 2, "saved layout failed to recover after combat")
    else
        assert(hooks.SetPoint and hooks.SetScale and scripts.OnShow, "other clients lost their layout hooks")
        assert(#callbacks == 0)
    end
end
Scenario(true, false)
Scenario(true, true)
Scenario(false, false)
print("Character mover combat OK: native Forever show/layout untouched on keyboard/gamepad; deferred layout recovers; Retail unchanged")
