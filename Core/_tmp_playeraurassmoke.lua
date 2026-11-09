-- lua Core/_tmp_playeraurassmoke.lua -- native Blizzard aura positioning only.
local dir = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local combat, editing, normalWidth = false, false, 190
local queued, watchers, hooks, callbacks = {}, {}, {}, {}
local function forbidden() error("native aura behavior or data was touched", 2) end
local ui = {}
local native = {}
local function auraFrame()
    local state = { scale = 1, writes = 0, parent = ui, events = { UNIT_AURA = true }, paints = 0 }
    local methods = {
        GetScale = function() return state.scale end,
        ClearAllPointsBase = function() assert(not combat and not editing); state.point = nil; state.writes = state.writes + 1 end,
        SetPointBase = function(_, ...) assert(not combat and not editing); state.point = { ... }; state.writes = state.writes + 1 end,
        -- Blizzard's Edit Mode overrides must never be called by Flux positioning.
        ClearAllPoints = forbidden, SetPoint = forbidden,
        ApplySystemAnchor = function() state.point = { "TOPRIGHT", ui, "TOPRIGHT", -255, -10 } end,
        OnEvent = function(_, event) if event == "UNIT_AURA" then state.paints = state.paints + 1 end end,
    }
    local frame = setmetatable({}, {
        __index = function(_, key) return methods[key] or forbidden end,
        __newindex = forbidden,
    })
    native[frame] = { state = state, methods = methods }
    return frame
end
local buff, debuff = auraFrame(), auraFrame()
local env = setmetatable({
    Flux = {},
    UIParent = ui,
    FluxMinimap = { GetNormalWidth = function() return normalWidth end },
    Minimap = { parent = ui, width = 190, shown = true },
    InCombatLockdown = function() return combat end,
    FluxEditModeBusy = function() return editing end,
    C_Timer = { After = function(_, fn) queued[#queued + 1] = fn end },
    CreateFrame = function(kind, name, parent, template)
        assert(kind == "Frame" and not name and not parent and not template, "replacement aura frame was created")
        local frame = { events = {}, scripts = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:SetScript(script, fn) self.scripts[script] = fn end
        watchers[#watchers + 1] = frame
        return frame
    end,
    hooksecurefunc = function(frame, method, fn)
        assert(native[frame] and method == "ApplySystemAnchor", "hooked a widget method or an aura updater")
        assert(not hooks[frame], "duplicate layout hook")
        hooks[frame] = fn
    end,
    EventRegistry = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end },
    C_UnitAuras = setmetatable({}, { __index = forbidden }),
}, { __index = _G })
env._G = env
local path = dir .. "Minimap/FluxBuffDebuffFrames.lua"
local chunk
if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, env)
else chunk = assert(loadfile(path, "t", env)) end
chunk("_FluxUI", {})
local function emit(event, ...)
    for _, frame in ipairs(watchers) do
        if frame.events[event] then frame.scripts.OnEvent(frame, event, ...) end
    end
end
local function flush()
    local batch = queued
    queued = {}
    for _, fn in ipairs(batch) do fn() end
    assert(#queued == 0, "positioning loop scheduled itself")
end
-- Loading before Blizzard_BuffFrame exists must be harmless.
emit("PLAYER_LOGIN")
flush()
assert(#watchers == 1, "unexpected extra event listeners or replacement rows")
env.BuffFrame, env.DebuffFrame = buff, debuff
emit("ADDON_LOADED", "Blizzard_BuffFrame")
flush()
local function assertPosition(x)
    local b, d = native[buff].state, native[debuff].state
    assert(b.point[2] == ui and d.point[2] == ui, "auras depend on the minimap or another system frame")
    assert(b.point[4] * b.scale == x and b.point[5] * b.scale == -10, "buff position differs from the normal minimap dock")
    assert(d.point[4] * d.scale == x - 15 and d.point[5] * d.scale == -155, "native row separation changed")
end
assertPosition(-200)
local b, d = native[buff].state, native[debuff].state
local originalBuffEvent, originalDebuffEvent = buff.OnEvent, debuff.OnEvent
local writes = b.writes + d.writes
-- Moving/hiding/resizing the embedded minimap cannot affect the aura anchors.
env.Minimap.parent, env.Minimap.width, env.Minimap.shown = {}, 450, false
env.FluxMinimap:PositionBuffFrames()
assertPosition(-200)
assert(b.parent == ui and d.parent == ui and b.events.UNIT_AURA and d.events.UNIT_AURA, "native aura visibility/events changed")
-- Native combat events continue to execute without any addon payload inspection.
combat = true
writes = b.writes + d.writes
local payload = setmetatable({}, { __index = forbidden, __len = forbidden })
for _ = 1, 600 do
    buff.OnEvent(buff, "UNIT_AURA", "player", payload)
    debuff.OnEvent(debuff, "UNIT_AURA", "player", payload)
end
env.FluxMinimap:RefreshBlizzardAuraFrames()
assert(b.writes + d.writes == writes, "native frames were moved during combat")
assert(b.paints == 600 and d.paints == 600 and buff.OnEvent == originalBuffEvent and debuff.OnEvent == originalDebuffEvent,
    "Blizzard aura handlers were disabled or replaced")
combat = false
emit("PLAYER_REGEN_ENABLED")
flush()
assertPosition(-200)
-- A Blizzard layout reset is corrected after the native call returns.
buff:ApplySystemAnchor()
hooks[buff]()
flush()
assertPosition(-200)
editing = true
callbacks["EditMode.Enter"]()
writes = b.writes + d.writes
emit("EDIT_MODE_LAYOUT_APPLIED")
flush()
assert(b.writes + d.writes == writes, "positioning interfered with an active Edit Mode pass")
editing = false
callbacks["EditMode.Exit"]()
flush()
assertPosition(-200)
-- Preserve physical screen placement for native frame scales and Classic map width.
b.scale, d.scale = 2, 0.5
normalWidth = 175
emit("UI_SCALE_CHANGED")
flush()
assertPosition(-185)
print("native aura smoke OK (only stock frame anchors, combat events, embed, Edit Mode, scaling, late load)")
