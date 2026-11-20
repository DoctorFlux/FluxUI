-- Actual grid relayouts, Info size hooks, envelope and action-strip completion.
-- Optional argument points to a directory with the archived pre-change sources.
local function read(path, baseline)
    if baseline then path = baseline .. "/" .. path:gsub("/", "-") end
    local f = assert(io.open(path, "rb"))
    local source = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return source
end
local function slice(text, first, last)
    local start = assert(text:find(first, 1, true))
    return text:sub(start, assert(text:find(last, start + #first, true)) - 1)
end

local checks = 0
local function check(ok, message)
    checks = checks + 1
    assert(ok, message)
end

local function fixture(baseline)
    local state = { timers = {}, regen = {}, trace = {}, timerWrites = 0, info = 0, envelope = 0, commits = 0 }
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.InCombatLockdown = function() return state.locked end
    env.C_Timer = { After = function(delay, fn)
        check(delay == 0, "grid completion is scheduled for the next frame")
        state.timers[#state.timers + 1] = fn
        state.timerWrites = state.timerWrites + 1
    end }
    local function record(value) state.trace[#state.trace + 1] = value end
    local function frame(name)
        local f = { name = name, w = 1, h = 1, points = {}, scripts = {}, shown = true }
        function f:SetSize(w, h)
            check(not state.locked, "ordinary layout remains outside combat")
            local changed = w ~= self.w or h ~= self.h
            self.w, self.h = w, h
            if changed and self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self, w, h) end
        end
        function f:GetWidth() return self.w end
        function f:GetHeight() return self.h end
        function f:GetLeft() return self.x or 0 end
        function f:GetBottom() return self.y or 0 end
        function f:SetScale() end
        function f:SetClampedToScreen() end
        function f:ClearAllPoints() self.points = {} end
        function f:SetPoint(p, rel, rp, x, y)
            self.points[p] = { rel.name, rp, x, y }
        end
        function f:Hide() self.shown = false end
        function f:Show() self.shown = true end
        function f:IsShown() return self.shown end
        function f:HookScript(name, callback)
            check(not self.scripts[name], "each grid size callback is installed once")
            self.scripts[name] = callback
        end
        return f
    end
    env.CreateFrame = function(_, name) return frame(name) end
    env.UIParent = frame("UIParent")
    env.Flux = { Bars = {}, EBS = {}, Combat = {
        InLockdown = env.InCombatLockdown,
        Defer = function(key, fn) state.regen[key] = fn end,
    } }
    local bars = env.Flux.Bars
    local ui = frame("info")
    local trinket = frame("trinket")
    local envelope = frame("envelope")
    local function run(path)
        assert(load(read(path, baseline), "@" .. path, "t", env))("_FluxUI", { Flux = env.Flux })
    end
    run("ExtraButtonSystem/CombatGrid/Grid.lua")
    run("ExtraButtonSystem/NonCombatGrid/Grid.lua")
    local combat = env.FluxCombatGrid.New(nil, { name = "combat" })
    local noncombat = env.FluxNonCombatGrid.New(nil, { name = "noncombat" })
    for _, grid in ipairs({combat, noncombat}) do
        grid.Buttons[1] = { SlotFrame = frame(grid.Name .. "button") }
        grid.ColumnPriorities[grid.Buttons[1]] = 1
    end
    env.FluxCombatManager = { Grid = combat }
    env.FluxNonCombatAPI = { DefaultGrid = noncombat }

    local function updateInfo()
        if state.locked then return end
        state.info = state.info + 1
        record("info")
        ui.w = combat.Frame.w + noncombat.Frame.w + trinket.w
        ui.x = trinket.x or 0
        if state.onInfo then state.onInfo() end
    end
    env.FluxInfoFrame = { UpdatePosition = updateInfo }
    env.GetBorderAnchors = function()
        return { leftAnchor = noncombat.Frame, rightAnchor = ui, bottomAnchor = noncombat.Frame,
            topAnchor = combat.Frame }
    end
    env.UpdateGapBackdrop = function() end
    env.UpdateActionStripInfoGapBackdrop = function() end
    env.modelInfo, env.modelEnvelope, env.modelUpdateInfo = ui, envelope, updateInfo

    local border = read("Layout/UnifiedBorder.lua", baseline)
    local body = slice(border, "local lastBorderLayoutHash", "--- Unified micro+status chrome")
    local arrowCode = border:find("local function RefreshBorderArrows()", 1, true)
        and slice(border, "local function RefreshBorderArrows()", "local function CreateBorderFrame()") or ""
    env.FluxUnifiedBorder = assert(load("local UnifiedBorder = {}; local borderFrame = modelEnvelope\n"
        .. arrowCode .. body .. "\nUnifiedBorder.UpdateBorder = UpdateBorder; return UnifiedBorder", "@actual-envelope", "t", env))()
    local writeBorder = env.FluxUnifiedBorder.UpdateBorder
    env.FluxUnifiedBorder.UpdateBorder = function()
        if not state.locked then state.envelope = state.envelope + 1; record("envelope") end
        return writeBorder()
    end
    local info = read("StatusBars/FluxInfoFrame.lua", baseline)
    local hook = slice(info, "local function HookGridRelayout()", "-- Try to hook immediately")
    assert(load("local initialized, frame, UpdatePosition = true, modelInfo, modelUpdateInfo\n"
        .. hook .. "\nHookGridRelayout(); HookGridRelayout()", "@actual-info-hooks", "t", env))()

    env.FluxBorder = { Junctions = { CommitLayout = function()
        state.infoAtCommit = ui.w
        state.commits = state.commits + 1
        record("commit")
    end } }
    local pet = frame("pet")
    bars.Pet = {
        GetFrame = function() return pet end,
        CONFIG = { buttonSize = 38, buttonPadding = 1, columns = 5, rows = 2, totalButtons = 0 },
    }
    env.FluxTrinketMenuManager = { UpdateAnchor = function() trinket.w, trinket.x = 29, 609 end }
    env.FluxUILayoutSqueeze = {}
    local settings = read("FluxDefaultSettings.lua", baseline)
    local squeeze = slice(settings, "-- Squeeze callback bodies are shared across notifications.", "local squeezeRefreshScheduled")
    assert(load(squeeze, "@actual-squeeze-notification", "t", env))()
    run("Bars/Pet/Layout.lua")
    run("Bars/Layout.lua")
    bars.Layout.ApplyMappings = function() end
    bars.Layout.ApplyVisual = function() return true end
    state.apply = bars.Layout.Apply
    state.combat, state.noncombat, state.trinket, state.ui = combat, noncombat, trinket, ui
    state.border = env.FluxUnifiedBorder
    state.env = env
    function state.drain()
        local pending = state.timers
        state.timers = {}
        for _, fn in ipairs(pending) do fn() end
    end
    function state.signature()
        local values = { ui.w, ui:GetLeft() }
        for _, grid in ipairs({combat, noncombat}) do
            values[#values + 1] = grid.Frame.w
            values[#values + 1] = grid.Frame.h
            values[#values + 1] = tostring(grid.Frame.shown)
        end
        for _, point in ipairs({"LEFT", "RIGHT", "BOTTOM", "TOP"}) do
            local data = envelope.points[point]
            values[#values + 1] = data and table.concat(data, ":") or "missing"
        end
        return table.concat(values, "|")
    end
    return state
end

local before = arg[1] and fixture(arg[1])
local after = fixture()
after.apply()
local signature = after.signature()
check(table.concat(after.trace, ",") == "info,envelope,commit", "settled Info and envelope publish before the border commit")
check(after.infoAtCommit == after.combat.Frame.w + after.noncombat.Frame.w + after.trinket.w,
    "the immediate commit reads the final dimensions of both grids and Trinket Menu")
after.drain()
check(after.info == 1 and after.envelope == 1 and after.timerWrites == 1 and after.signature() == signature,
    "the consumed wake has no next-frame layout work")
if before then
    before.apply(); before.drain()
    check(before.signature() == signature, "archived layout converges to the same final envelope geometry")
    print(("GRID_ENVELOPE drag timers=%d/%d info=%d/%d envelope=%d/%d commitRequests=%d/%d")
        :format(before.timerWrites, after.timerWrites, before.info, after.info, before.envelope, after.envelope,
            before.commits, after.commits))
    check(before.timerWrites == 2 and before.info == 4 and before.envelope == 3 and before.commits == 2,
        "archived grids refresh Info twice at size and twice after layout, and the pet path commits independently")
end

-- Standalone hide/reveal updates still run even without a strip transaction.
after.combat.Buttons[1].SlotFrame:Hide()
after.combat:Relayout(); after.noncombat:Relayout()
after.drain()
check(not after.combat.Frame:IsShown() and after.info == 2 and after.envelope == 2,
    "depletion and sibling relayout share a deferred update")
after.combat.Buttons[1].SlotFrame:Show()
after.combat:Relayout()
after.locked = true; after.drain()
check(after.info == 2 and after.envelope == 2 and after.regen["layout.grid.envelope"],
    "a wake crossing into combat retains the work and skips ordinary layout")
after.locked = false; after.regen["layout.grid.envelope"]()
check(after.combat.Frame:IsShown() and after.info == 3 and after.envelope == 3,
    "regen applies current panel state once")

-- A fresh request from inside Info must survive completion of the old pass.
after.onInfo = function()
    after.onInfo = nil
    after.border.RequestGridLayoutUpdate()
end
after.noncombat:Relayout()
after.drain()
check(after.info == 4 and #after.timers == 1, "reentrant request retains its own wake")
after.drain()
check(after.info == 5 and #after.timers == 0, "queued successor consumes the fresh request once")
after.env.Flux.Bars.Pet.LayoutButtons()
check(after.commits == 2, "standalone pet layout retains its immediate commit")
local infoFailure = {}
after.env.geterrorhandler = function() return function(err) after.reported = err end end
after.onInfo = function() error(infoFailure, 0) end
after.noncombat:Relayout()
after.drain()
check(after.reported == infoFailure and after.envelope == 6,
    "failed Info reports the original error after updating the usable envelope")
after.onInfo = nil
after.noncombat:Relayout()
after.drain()
check(after.info == 7 and after.envelope == 7, "later grid layout recovers after Info failure")

-- Before UnifiedBorder loads, grid fallback still calls available owners.
local fallback = fixture()
fallback.env.FluxUnifiedBorder = nil
fallback.combat:Relayout()
fallback.drain()
check(fallback.info == 2, "standalone Info size notification and grid refresh remain available")
print(("Grid envelope work: %d checks; actual grid, Info hook, envelope and strip paths. Native latency and pixels pending.")
    :format(checks))
