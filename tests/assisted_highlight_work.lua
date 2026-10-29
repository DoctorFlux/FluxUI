-- Execute real bar painting with 57 surfaces, fresh batch facts and direct-call controls.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local path, measure, mutation = "Bars/Paint.lua", false
for i, v in ipairs(arg or {}) do
    if v == "--source" then path = assert(arg[i + 1]) end
    if v == "--measure" then measure = true end
    if v == "--mutation" then mutation = assert(arg[i + 1]) end
end
local sourceBody = read(path)
local function replace(s, old, new)
    local at = assert(s:find(old, 1, true), "mutation anchor missing")
    return s:sub(1, at - 1) .. new .. s:sub(at + #old)
end
if mutation == "no_batch_fact" then
    sourceBody = replace(sourceBody, "host, nextId, true, highlightActive)", "host, nextId, true)")
elseif mutation == "no_direct_refresh" then
    sourceBody = replace(sourceBody, "if highlightActive == nil then", "if false then")
elseif mutation == "skip_disabled_cleanup" then
    sourceBody = replace(sourceBody, "\t\tHideAssistedHighlight(widget)\n\t\treturn", "\t\treturn")
elseif mutation == "geometry" then
    sourceBody = replace(sourceBody, "w * (66 / 45)", "w * 2")
elseif mutation == "stale_fact" then
    sourceBody = replace(sourceBody, "function Paint.PaintAssistedHighlights()", "local rememberedHighlightActive\nfunction Paint.PaintAssistedHighlights()")
    local line = "local highlightActive = (A and A.IsAssistedHighlightActive and A.IsAssistedHighlightActive()) and true or false"
    sourceBody = replace(sourceBody, line, "if rememberedHighlightActive == nil then rememberedHighlightActive = (A and A.IsAssistedHighlightActive and A.IsAssistedHighlightActive()) and true or false end\nlocal highlightActive = rememberedHighlightActive")
elseif mutation then error("unknown mutation") end
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function boot(branch)
    local s = { active = false, nextId = 10, queries = 0, nextQueries = 0, candidates = 0,
        frames = 0, shows = 0, hides = 0, plays = 0, stops = 0, hosts = {} }
    local flux = { Bars = {}, Secrets = { IsSecretValue = function(v) return type(v) == "table" and v.opaque end } }
    local B = flux.Bars
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.UnitAffectingCombat = function() return s.combat end
    local function widget(size)
        local w = { shown = false, width = size or 44, height = size or 44 }
        function w:Hide() self.shown = false; s.hides = s.hides + 1 end
        function w:Show() self.shown = true; s.shows = s.shows + 1 end
        function w:SetSize(x, y) self.width, self.height = x, y end
        function w:ClearAllPoints() end
        function w:SetPoint(p) self.point = p end
        function w:EnableMouse(v) self.mouse = v end
        function w:EnableMouseClicks(v) self.clicks = v end
        function w:GetWidth() return self.width end
        function w:GetHeight() return self.height end
        function w:GetFrameStrata() return "MEDIUM" end
        function w:GetFrameLevel() return self.level or 5 end
        function w:SetFrameStrata(v) self.strata = v end
        function w:SetFrameLevel(v) self.level = v end
        return w
    end
    env.CreateFrame = function(kind, name, parent, template)
        assert(kind == "Frame" and not name and template == "ActionBarButtonAssistedCombatHighlightTemplate")
        s.frames = s.frames + 1
        local f = widget(); f.parent = parent; f.Flipbook = widget()
        f.Flipbook.Anim = { Play = function() s.plays = s.plays + 1 end,
            Stop = function() s.stops = s.stops + 1 end }
        return f
    end
    flux.Action = { IsAssistedHighlightActive = function() s.queries = s.queries + 1; return s.active end,
        GetAssistedHighlightSpell = function()
            s.nextQueries = s.nextQueries + 1
            if not flux.Action.IsAssistedHighlightActive() then return end
            return s.nextId
        end,
        SpellForAssistedHighlight = function(slot) s.candidates = s.candidates + 1; return s.mapping[slot] end,
        HasAction = function() return true end }
    B.Hosts = { LiveSlot = function(h) return h.slot end }
    B.ForEachHost = function(fn) for _, h in ipairs(s.hosts) do fn(h) end end
    B.RequestPaint = function() end
    s.mapping = {}
    for i = 1, 57 do
        local h = { slot = i, widget = widget(i <= 19 and 44 or 22) }
        s.hosts[i] = h; s.mapping[i] = i == 1 and 10 or 20
        -- Retained overlays must still stop/hide even when the feature is off.
        h.widget.AssistedCombatHighlightFrame = env.CreateFrame("Frame", nil, h.widget,
            "ActionBarButtonAssistedCombatHighlightTemplate")
    end
    assert(load(sourceBody, "@assisted-highlight-source", "t", env))("_FluxUI", { Flux = flux })
    s.P, s.env, s.flux, s.B = B.Paint, env, flux, B
    function s:counts() return { queries = self.queries, next = self.nextQueries, candidates = self.candidates,
        shows = self.shows, hides = self.hides, plays = self.plays, stops = self.stops } end
    function s:metric(label, run, active)
        self.active = active
        for _ = 1, 20 do run() end
        local before = self:counts(); local began = os.clock()
        for _ = 1, 100 do run() end
        local elapsed = os.clock() - began; local after = self:counts()
        local values = {}
        for k, v in pairs(after) do values[k] = v - before[k] end
        check(values.queries == (active and 200 or 100), branch .. " " .. label .. " one activation sample per batch plus helper guard")
        check(values.next == (active and 100 or 0), branch .. " " .. label .. " next-spell query count")
        check(self.frames == 57, branch .. " " .. label .. " no frame growth")
        print(("METRIC %s_%s active_reads=%d next_reads=%d candidates=%d shows=%d hides=%d plays=%d stops=%d frames=%d cpu_seconds=%.6f")
            :format(branch, label, values.queries, values.next, values.candidates, values.shows,
                values.hides, values.plays, values.stops, self.frames, elapsed))
    end
    return s
end
for _, branch in ipairs({ "era", "anniversary", "progression", "live", "forever" }) do
    local s = boot(branch); local P = s.P
    s:metric("disabled", P.PaintAssistedHighlights, false)
    check(s.hides > 0 and s.stops > 0, branch .. " disabled clears retained effects")
    s.active = true; P.PaintAssistedHighlights()
    local w = s.hosts[1].widget.AssistedCombatHighlightFrame
    check(w.shown and w.parent == s.hosts[1].widget and w.width == 44 and w.height == 44,
        branch .. " matching face retains geometry")
    check(w.level == 15 and w.strata == "MEDIUM" and not w.mouse and not w.clicks, branch .. " overlay levels/input")
    check(w.Flipbook.width == 44 * (66 / 45), branch .. " exact flipbook dimensions")
    s:metric("enabled", P.PaintAssistedHighlights, true)
    s.nextId = 20; P.PaintAssistedHighlights()
    check(not w.shown and s.hosts[57].widget.AssistedCombatHighlightFrame.shown, branch .. " next pass reads changed spell")
    s.hosts[57]._fluxParked = true; P.PaintAssistedHighlights()
    check(not s.hosts[57].widget.AssistedCombatHighlightFrame.shown, branch .. " parked face clears")
    s.hosts[57]._fluxParked = false
    s.combat = true; local plays = s.plays; P.PaintAssistedHighlights()
    check(s.plays > plays, branch .. " combat animation plays at existing cadence")
    s.combat = false; local stops = s.stops; P.PaintAssistedHighlights()
    check(s.stops > stops, branch .. " out-of-combat animation stops")
    s.mapping[57] = { opaque = true }; P.PaintAssistedHighlights()
    check(not s.hosts[57].widget.AssistedCombatHighlightFrame.shown, branch .. " opaque spell is not compared")
    s.mapping[57] = 20
    -- Standalone callers retain fresh state, including explicitly prequeried nil IDs.
    local before = s.queries; P.UpdateAssistedHighlight(s.hosts[1], nil, true)
    check(s.queries == before + 1, branch .. " direct caller still samples activation")
    s.active = false; P.PaintAssistedHighlights(); s.active = true
    before = s.queries; P.UpdateAssistedHighlight(s.hosts[57])
    check(s.queries == before + 2 and s.hosts[57].widget.AssistedCombatHighlightFrame.shown,
        branch .. " direct caller has no stale batch cache")
    s.active = false; P.PaintAssistedHighlights()
    for _, h in ipairs(s.hosts) do check(not h.widget.AssistedCombatHighlightFrame.shown, branch .. " disabling clears every face") end
    for cycle = 1, 100 do
        s.active = true; P.PaintAssistedHighlights()
        check(s.hosts[57].widget.AssistedCombatHighlightFrame.shown, branch .. " cycle enables " .. cycle)
        s.active = false; P.PaintAssistedHighlights()
        check(not s.hosts[57].widget.AssistedCombatHighlightFrame.shown and s.frames == 57,
            branch .. " cycle disables without resource growth " .. cycle)
    end
    -- Exercise the real Flush traversal while replacing unrelated render lanes.
    for _, lane in ipairs({ "AssistedCombat", "Icon", "Count", "Name", "Cooldown", "Usable", "Equipped", "Range", "Checked", "Hotkey" }) do
        P["Update" .. lane] = function() end
    end
    s:metric("flush_disabled", function() P.Flush({ ["bars.icon"] = true }) end, false)
    s:metric("flush_enabled", function() P.Flush({ ["bars.icon"] = true }) end, true)
    local a = s.flux.Action; s.flux.Action = nil
    P.PaintAssistedHighlights(); P.UpdateAssistedHighlight(s.hosts[1])
    check(not w.shown, branch .. " missing action API clears safely")
    s.flux.Action = a
    local created = boot(branch)
    local mini = created.hosts[57]
    mini.widget.AssistedCombatHighlightFrame = nil
    created.active, created.nextId = true, 20
    created.P.PaintAssistedHighlights()
    local overlay = mini.widget.AssistedCombatHighlightFrame
    check(overlay and created.frames == 58 and overlay.point == "CENTER" and overlay.mouse == false and overlay.clicks == false,
        branch .. " first native template construction preserves input/anchor")
    check(overlay.width == 22 and overlay.height == 22 and overlay.Flipbook.width == 22 * (66 / 45),
        branch .. " minirow dimensions preserved")
    created.P.PaintAssistedHighlights(); check(created.frames == 58, branch .. " constructed template reused")
end
print(("Assisted highlight work: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
