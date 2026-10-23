-- Execute shared camera and portrait construction on five capability models.
-- Exact rendering for races, pets, NPCs and transformations still requires WoW.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local function slice(s, first, last)
    local a = assert(s:find(first, 1, true)); return s:sub(a, assert(s:find(last, a + #first, true)) - 1)
end
local source = slice(read("UnitFrames/FluxUnitFrames_Shared.lua"), "local function IsCamelotPortraitClient()",
    "--- True when layout should reserve horizontal space")
local compat = slice(read("Core/FluxAPI/UI.lua"), "function FluxSetupPortraitModel(model, unit)", "function FluxNeedsPortraitCompat()")
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function exercise(branch, body)
    local modern = branch == "live" or branch == "forever"
    local env = setmetatable({}, { __index = _G }); env._G = env
    local timers, calls, state = {}, { zoom = 0, custom = 0, baked = 0, target = 0, setUnit = 0 }, { distance = 6 }
    local ns = { Flux = { Client = { isForever = branch == "forever" } }, UnitFrames = {
        UpdatePortrait = function() end, UpdatePortraitCombatTint = function() end,
    } }
    env.FLUX_API = { isPostDF = modern, isForever = branch == "forever" }
    env.IsSecretValue = function(v) return v == state.secret end
    env.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    env.FluxSafeRegisterUnitEvent = function() end
    env.UnitExists, env.UnitIsVisible, env.UnitIsConnected = function() return true end, function() return true end, function() return true end
    local methods = {}
    for _, name in ipairs({ "EnableMouse", "ClearAllPoints", "SetPoint", "SetDoBlend", "SetKeepModelOnHide", "SetDrawLayer" }) do methods[name] = function() end end
    function methods:SetFrameLevel(level) self.level = level end
    function methods:GetFrameLevel() return self.level or 1 end
    function methods:SetSize(w, h) self.width, self.height = w, h end
    function methods:GetHeight() return self.height or 100 end
    function methods:Hide() self.shown = false end
    function methods:IsShown() return self.shown ~= false end
    function methods:SetScript(event, fn) check(event ~= "OnUpdate", "portrait adds no permanent camera polling"); self.scripts[event] = fn end
    function methods:GetScript(event) return self.scripts[event] end
    function methods:CreateTexture() return env.CreateFrame("Texture") end
    function methods:SetCamDistanceScale(value) check(value == 1, "native zoom scale retained") end
    function methods:SetPortraitZoom(value) check(value == 1, "full portrait zoom retained"); calls.zoom = calls.zoom + 1; state.distance = state.seedDistance or 6 end
    function methods:SetPosition(x, y, z) check(x == 0 and y == 0 and z == 0, "model origin retained") end
    function methods:SetModelScale(value) check(value == 1, "model scale retained") end
    function methods:MakeCurrentCameraCustom() calls.custom = calls.custom + 1 end
    function methods:GetCameraDistance() return state.distance end
    function methods:GetCameraTarget() return 0, 0, 1 end
    function methods:GetCameraPosition() return 6, 0, 1 end
    function methods:SetCameraTarget(x, y, z) calls.target = calls.target + 1; state.target = { x, y, z } end
    function methods:SetCameraPosition(x, y, z) state.position = { x, y, z } end
    function methods:SetCameraDistance(value) state.distance = value end
    function methods:RefreshCamera() calls.baked = calls.baked + 1 end
    function methods:SetCamera() calls.baked = calls.baked + 1 end
    function methods:SetUnit(unit) calls.setUnit = calls.setUnit + 1; self.unit = unit end
    env.CreateFrame = function(kind, _, parent)
        return setmetatable({ kind = kind, parent = parent, scripts = {} }, { __index = methods })
    end
    local apply, schedule, setUnit = assert(load("local _, ns = ...; local UF = ns.UnitFrames\n" .. (body or source)
        .. "\nreturn ApplyPortraitCamera, SchedulePortraitCameraRefresh, SetPortraitUnit", "@shared-portrait-camera", "t", env))("_FluxUI", ns)
    local model
    for _, unit in ipairs({ "player", "target", "targettarget", "focus", "focustarget", "pet" }) do
        local f = env.CreateFrame("Frame"); f.unit = unit
        ns.UnitFrames.CreatePortrait(f); model = f.Portrait
        check(model._fluxSharedPortraitCamera and model.unit == unit, branch .. ": every unit owns the shared portrait camera")
        check(calls.baked == 0 and math.abs(state.distance - 1.08) < 0.0001
            and math.abs(state.target[3] - 2.92) < 0.0001, branch .. ": face framing matches the existing Forever calculation")
        local zoom = calls.zoom
        model.scripts.OnAnimStarted(model)
        check(calls.zoom == zoom, "animation start keeps an already close camera")
        local originalShow, originalEvent, originalSetUnit = model.scripts.OnShow, model.scripts.OnEvent, model.SetUnit
        assert(load(compat, "@portrait-compat", "t", env))()
        check(env.FluxSetupPortraitModel(model, unit), "legacy setup accepts a shared portrait")
        check(model.scripts.OnShow == originalShow and model.scripts.OnEvent == originalEvent and model.SetUnit == originalSetUnit,
            "legacy compatibility does not replace shared portrait handlers or SetUnit")
    end
    -- All lifecycle requests coalesce to three finite callbacks per portrait.
    local count = #timers
    for _ = 1, 30 do schedule(model) end
    check(#timers == count, "repeated model refresh requests coalesce")
    local function drain()
        local pending = timers; timers = {}
        for _, fn in ipairs(pending) do fn() end
    end
    drain(); check(#timers == 0 and not model._fluxCamRefreshQueued, "camera work finishes without an idle timer")
    state.seedDistance = 0.9; local target = calls.target
    apply(model); check(calls.target == target and state.distance == 0.9, "native face crop is preserved")
    state.seedDistance = 6
    model._fluxQuestionMark = true; local zoom = calls.zoom
    apply(model); schedule(model); drain()
    check(calls.zoom == zoom, "question-mark fallback keeps its own camera")
    model._fluxQuestionMark = nil
    model.scripts.OnModelLoaded(model); check(state.distance < 1.55 and #timers == 3, "late model load reapplies face framing on every client")
    model.shown = false; zoom = calls.zoom; drain()
    check(calls.zoom == zoom, "hidden portraits do not receive stale delayed camera writes")
    model.shown = true; model.scripts.OnShow(model); drain()
    check(state.distance < 1.55, "showing a portrait restores its face crop")
    -- Missing APIs retain the established branch fallback instead of failing.
    model.MakeCurrentCameraCustom, model.SetCustomCamera = false, false
    local baked = calls.baked; apply(model)
    check(calls.baked == baked + (branch == "forever" and 0 or 1), "missing custom APIs use the appropriate native camera fallback")
    check(calls.setUnit >= 6, "normal unit binding remains intact")
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do exercise(branch) end
local function reject(before, after, expected)
    local a, b = assert(source:find(before, 1, true))
    local ok, err = pcall(exercise, "live", source:sub(1, a - 1) .. after .. source:sub(b + 1))
    check(not ok and tostring(err):find(expected, 1, true), "negative control: " .. expected)
end
reject("if customCamera then", "if customCamera and IsCamelotPortraitClient() then", "face framing matches")
reject("if keepIfClose and customCamera then", "if false then", "animation start keeps")
reject("if portrait._fluxCamRefreshQueued then", "if false then", "refresh requests coalesce")
print("Portrait camera: " .. checks .. " checks; five client models; three negative controls passed")
