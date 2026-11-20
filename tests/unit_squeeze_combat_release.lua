-- Execute the actual Shared squeeze producer and its registered regen handler.
-- This permission/value model measures redundant layout work, not native FPS.
-- An external exact source can be supplied as arg[1]; --measure preserves its
-- old behavior while recording matched work instead of enforcing new budgets.
local sourcePath = arg[1] or "UnitFrames/FluxUnitFrames_Shared.lua"
local measure = arg[2] == "--measure"
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function corrected(ok, why) if not measure then check(ok, why) end end
local f = assert(io.open(sourcePath, "rb")); local source = f:read("*a"); f:close()
source = source:gsub("\r\n", "\n")
local function section(first, last)
    local a = assert(source:find(first, 1, true), first)
    local b = assert(source:find(last, a + #first, true), last)
    return source:sub(a, b - 1)
end
local geometry = section("local function ValueIsSecret(value)", "function UF.GetFramePublicDimensions(frame)")
local squeeze = section("local emulatedSqueezeFrames = {}", "-- Base Frame Construction")
local function opaque(accessible)
    local function forbidden() error("restricted value inspected") end
    return setmetatable({secret = accessible ~= false, inaccessible = accessible == false}, {
        __eq = forbidden, __lt = forbidden, __le = forbidden, __add = forbidden,
        __sub = forbidden, __mul = forbidden, __div = forbidden, __tostring = forbidden,
    })
end

local function fixture()
    local state = {factor = .8125, placement = 1, combat = false, events = {}, timers = {},
        writes = 0, partitions = 0, atlas = 0, outer = 0, reads = 0, dimensions = 0,
        notifications = 0, invalidations = 0, timings = {}, frames = {}, resources = 0}
    local UF, API = {}, {}
    API.IsSecretValue = function(value) return type(value) == "table" and value.secret == true end
    API.CanAccessValue = function(value) return not (type(value) == "table" and value.inaccessible) end
    local ns = {UnitFrames = UF, API = API, Flux = {Perf = {Regen = {}}}}
    ns.Flux.Perf.Regen.Time = function(key, callback, ...)
        state.timings[#state.timings + 1] = {key = key, callback = callback, changedOnly = ...}
        return callback(...)
    end
    local e = setmetatable({UF = UF, API = API, ns = ns,
        InCombatLockdown = function() return state.combat end,
        FluxUnitFrames_GetPlayerTargetPlacement = function() return state.placement end,
        FluxUILayoutSqueeze = {
            GetEffectiveEmulatedDependentXFactorForUnitFrames = function() return state.factor end,
            InvalidateEmulatedDependentCache = function() state.invalidations = state.invalidations + 1 end,
            NotifyLayoutDependents = function() state.notifications = state.notifications + 1 end,
        }, C_Timer = {After = function(delay, callback)
            state.timers[#state.timers + 1] = {delay = delay, callback = callback}
        end},
        CreateFrame = function()
            state.resources = state.resources + 1
            local frame = {}
            function frame:RegisterEvent(event) state.events[event] = true end
            function frame:SetScript(name, callback) state[name] = callback end
            return frame
        end,
    }, {__index = _G})
    assert(load(geometry .. squeeze, "@squeeze-actual-producer", "t", e))()
    local record = UF.RecordFrameDimensions
    UF.RecordFrameDimensions = function(...)
        state.dimensions = state.dimensions + 1
        return record(...)
    end
    function state:add(unit, width)
        local frame = {unit = unit, _fluxLayoutBaseWidth = width or 251.375, height = 88,
            Health = {_fluxPublicWidth = "retained", _fluxPublicHeight = "retained"}, ownWrites = 0}
        function frame:GetWidth()
            state.reads = state.reads + 1
            if self.widthUnavailable then return nil end
            return self.readWidth or self.width
        end
        function frame:SetWidth(value)
            assert(not state.combat, "protected width write in combat")
            assert(type(value) == "number", "only public planned widths reach native writer")
            state.writes, self.ownWrites, self.width = state.writes + 1, self.ownWrites + 1, value
        end
        function frame:UpdatePartition()
            assert(not state.combat, "partition called in combat")
            state.partitions = state.partitions + 1; self.partitionHeight = self.height
        end
        function frame:UpdateAtlasBorder() state.atlas = state.atlas + 1 end
        function frame:UpdateOuterBorder() state.outer = state.outer + 1 end
        state.frames[#state.frames + 1] = frame
        UF.RegisterEmulatedHorizontalSqueeze(frame)
        return frame
    end
    function state:reset()
        for _, key in ipairs({"writes", "partitions", "atlas", "outer", "reads", "dimensions",
            "notifications", "invalidations"}) do self[key] = 0 end
        self.timings = {}
    end
    function state:fire(event) self.OnEvent(nil, event) end
    return state, UF, e, ns
end

local work
for _, client in ipairs({"live", "forever", "classic", "classic_era", "classic_anniversary"}) do
    local s, UF, e, ns = fixture()
    for _, unit in ipairs({"player", "target", "focus", "pet", "party1"}) do s:add(unit) end
    local first = s.frames[1]
    check(s.resources == 1 and s.events.PLAYER_REGEN_ENABLED and s.events.UI_SCALE_CHANGED
        and s.events.DISPLAY_SIZE_CHANGED and s.events.PLAYER_ENTERING_WORLD, client .. " preserves event owner")
    check(s.writes == 5 and s.partitions == 5 and s.atlas == 5 and s.outer == 5,
        client .. " registration still fully prepares each frame")
    for _, frame in ipairs(s.frames) do frame.Health._fluxPublicWidth = "retained" end
    s:reset()
    for _ = 1, 10 do s:fire("PLAYER_REGEN_ENABLED") end
    corrected(s.writes == 0 and s.partitions == 0 and s.atlas == 0 and s.outer == 0 and s.dimensions == 0,
        client .. " ten unchanged regen events skip every width and nested layout writer")
    corrected(first.Health._fluxPublicWidth == "retained", client .. " unchanged regen preserves prepared dimension facts")
    check(s.notifications == 10 and s.invalidations == 10, client .. " dependent notification cadence retained")
    corrected(#s.timings == 10 and s.timings[1].key == "uf.Squeeze"
        and s.timings[1].callback == UF.UpdateAllEmulatedHorizontalSqueeze and s.timings[1].changedOnly == true,
        client .. " existing Regen.Time encloses the actual changed-only route")
    check(s.resources == 1 and #s.timers == 0, client .. " no new per-regen resources or timers")
    if not work then work = {writes = s.writes, partitions = s.partitions, atlas = s.atlas,
        outer = s.outer, dimensions = s.dimensions, reads = s.reads, notifications = s.notifications} end

    s:reset(); s.factor = .75
    s:fire("PLAYER_REGEN_ENABLED")
    check(s.writes == 5 and s.partitions == 5 and s.atlas == 5 and s.outer == 5,
        client .. " changed squeeze factor relayouts every affected frame")
    s:reset(); s:fire("PLAYER_REGEN_ENABLED")
    corrected(s.writes == 0, client .. " new factor applies once")
    first._fluxLayoutBaseWidth = 333.75; s:reset(); s:fire("PLAYER_REGEN_ENABLED")
    corrected(s.writes == 1 and first.width == 333.75 * .75 and s.partitions == 1,
        client .. " real base-width change refreshes only the affected frame")
    s:reset(); s:fire("PLAYER_REGEN_ENABLED")
    corrected(s.writes == 0, client .. " base-width change applies once")

    first.width = first.width + 1 / 2048; s:reset(); s:fire("PLAYER_REGEN_ENABLED")
    corrected(s.writes == 0, client .. " native float32 drift below 1/1024 UI unit does not trigger relayout")
    first.width = first.width + 1 / 256; s:reset(); s:fire("PLAYER_REGEN_ENABLED")
    corrected(s.writes == 1, client .. " larger real width mismatch still repairs")
    for _, unknown in ipairs({opaque(), opaque(false), "not a width", math.huge}) do
        first.readWidth = unknown; s:reset(); s:fire("PLAYER_REGEN_ENABLED")
        check(first.width == 333.75 * .75, client .. " unknown actual width conservatively writes known planned width")
        corrected(s.writes == 1 and s.partitions == 1 and s.atlas == 1 and s.outer == 1,
            client .. " unknown actual width does not skip required layout")
    end
    first.readWidth = nil
    first.widthUnavailable = true; s:reset(); s:fire("PLAYER_REGEN_ENABLED")
    corrected(s.writes == 1 and s.partitions == 1, client .. " absent actual width conservatively refreshes")
    first.widthUnavailable = nil
    for _, field in ipairs({"factor", "base"}) do
        local oldFactor, oldBase = s.factor, first._fluxLayoutBaseWidth
        if field == "factor" then s.factor = opaque() else first._fluxLayoutBaseWidth = opaque() end
        s:reset()
        if not measure then
            s:fire("PLAYER_REGEN_ENABLED")
            check(s.writes == 0,
                client .. " restricted planned " .. field .. " is guarded before arithmetic")
        end
        s.factor, first._fluxLayoutBaseWidth = oldFactor, oldBase
    end

    s:reset(); s.combat = true; s.factor = .625
    UF.UpdateAllEmulatedHorizontalSqueeze(); s:fire("PLAYER_REGEN_ENABLED")
    check(s.writes == 0 and s.partitions == 0 and s.atlas == 0 and s.outer == 0,
        client .. " protected layout writers remain inactive while combat-locked")
    check(s.notifications == 2, client .. " combat guard retains established notification cadence")
    s.combat = false; s:reset(); s:fire("PLAYER_REGEN_ENABLED")
    check(s.writes == 5, client .. " factor changed during combat applies at release")
    s:reset(); s:fire("PLAYER_REGEN_ENABLED")
    corrected(s.writes == 0, client .. " released factor is not applied again")

    -- Unchanged width can accompany a changed height/settings partition. Only
    -- the registered regen path opts into skipping; public callers still force.
    first.height = 111; s:reset(); UF.ApplyEmulatedHorizontalSqueezeForFrame(first)
    check(s.writes == 1 and s.partitions == 1 and first.partitionHeight == 111,
        client .. " direct frame caller retains height-driven refresh")
    s:reset(); UF.UpdateAllEmulatedHorizontalSqueeze()
    check(s.writes == 5 and s.atlas == 5 and s.outer == 5, client .. " public all-frame caller still forces refresh")
    s:reset(); e.FluxUnitFrames_UpdateAllEmulatedHorizontalSqueeze()
    check(s.writes == 5, client .. " public global caller still forces refresh")
    for _, event in ipairs({"UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do
        s:reset(); s:fire(event)
        check(s.writes == 5 and s.notifications == 1 and s.invalidations == 1,
            client .. " " .. event .. " retains full refresh")
    end
    s:reset(); s:fire("PLAYER_ENTERING_WORLD")
    check(s.writes == 5 and #s.timers == 2 and s.timers[1].delay == 0 and s.timers[2].delay == .05,
        client .. " loading retains immediate and existing settled geometry refreshes")
    for _, timer in ipairs(s.timers) do timer.callback() end
    check(s.writes == 15 and s.notifications == 3 and s.invalidations == 3,
        client .. " loading callbacks retain full refresh cadence")
    s:reset(); ns.Flux.Perf = nil; s:fire("PLAYER_REGEN_ENABLED")
    corrected(s.writes == 0 and s.notifications == 1, client .. " optional Perf absence preserves changed-only behavior")

    local focus = s.frames[3]; s.placement = 2; s:reset(); s:fire("PLAYER_REGEN_ENABLED")
    check(focus.width == focus._fluxLayoutBaseWidth, client .. " placement2 focus still keeps configured unsqueezed width")
    local compact = s:add("focustarget"); compact._fluxVerticalFocusTarget = true
    s:reset(); UF.ApplyEmulatedHorizontalSqueezeForFrame(compact)
    check(s.writes == 0, client .. " vertical focus target still owns its fixed width")
end
print(string.format("SQUEEZE_WORK regens=10 frames=5 writes=%d partitions=%d atlas=%d outer=%d dimensions=%d reads=%d notifications=%d",
    work.writes, work.partitions, work.atlas, work.outer, work.dimensions, work.reads, work.notifications))
print(string.format("unit squeeze combat release: %d checks passed%s", checks, measure and " (measurement)" or ""))
