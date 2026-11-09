-- Production work-count regressions. Native timings/rendering/taint remain pending.
local sourceRoot = arg[1] or "."
sourceRoot = sourceRoot:gsub("\\", "/"):gsub("/$", "") .. "/"
local selected, checks = arg[2], 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s:gsub("\r\n", "\n")
end
local function replace(s, old, new)
    local a = assert(s:find(old, 1, true), "fixture anchor missing: " .. old)
    return s:sub(1, a - 1) .. new .. s:sub(a + #old)
end
local function fixturePrefix(path, boundary)
    local s = read(path); s = s:sub(1, assert(s:find(boundary, 1, true)) - 1)
    local first = assert(s:find("local function read(path)", 1, true))
    local last = assert(s:find("\nend", first, true)) + 4
    return s:sub(1, first - 1) .. "local function read(path) return readSource(path) end" .. s:sub(last)
end
local fixtureEnv = setmetatable({ arg = {}, readSource = function(path) return read(sourceRoot .. path) end }, { __index = _G })

if not selected or selected == "PERF-01" then
    local source = fixturePrefix("tests/raid_healer_runtime.lua", "local function exercise(client,body)")
    source = replace(source, "function methods:SetScript(event,fn)self.scripts[event]=fn end", [[function methods:SetScript(event,fn)
        self.scripts[event]=fn
        if event=="OnUpdate" and fn then e._workArms=(e._workArms or 0)+1 end
    end]])
    local fixture = assert(load(source .. "\nreturn fixture", "@reused-raid-work-fixture", "t", fixtureEnv))()
    local events = { "UNIT_HEALTH", "UNIT_POWER_UPDATE", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED",
        "UNIT_AURA", "UNIT_THREAT_SITUATION_UPDATE", "UNIT_IN_RANGE_UPDATE" }
    for _, client in ipairs({ "classic_era", "classic_anniversary", "classic", "live", "forever" }) do
        for _, count in ipairs({ 0, 1, 5, 40 }) do
            for _, combat in ipairs({ false, true }) do
                local e, cell, fire, flush, pending, facts, calls, queries = fixture(client)
                local cells = {}
                for i = 1, count do
                    local unit = "raid" .. i
                    facts[unit] = { name = "Member" .. i, health = 75, maximum = 100, power = 40, powerMax = 100,
                        connected = true, dead = false, range = true, role = "HEALER" }
                    cells[i] = cell("FluxWorkCell" .. i); e.FluxRaid_BindUnit(cells[i], unit)
                end
                flush(); e.combat = combat
                local arms, health, power, aura, prediction = e._workArms or 0, queries.health, queries.power, calls.aura, calls.prediction
                local writes = 0; for _, f in ipairs(cells) do writes = writes + f.healthBar.values end
                for _ = 1, 100 do for i, f in ipairs(cells) do for _, event in ipairs(events) do fire(f, event, "raid" .. i) end end end
                check(queries.health == health and calls.aura == aura, "raid burst performs no immediate paint")
                check((e._workArms or 0) - arms == (count > 0 and 1 or 0), "PERF-01 one outstanding arm for merged raid burst")
                check(pending() == (count > 0 and 1 or 0), "raid dispatcher ownership remains singular")
                flush()
                local after = 0; for _, f in ipairs(cells) do after = after + f.healthBar.values end
                check(after - writes == count and queries.power - power == count and calls.aura - aura == count
                    and calls.prediction - prediction == count, "merged raid burst preserves all requested category/member paints")
                check(pending() == 0, "raid dispatcher sleeps after merged paint")
                for i, f in ipairs(cells) do fire(f, "UNIT_AURA", "raid" .. i); f.shown = false; e.FluxRaidUnit_OnHide(f) end
                aura = calls.aura; flush()
                check(calls.aura == aura, "hidden queued raid cells cannot repaint")
            end
        end
        -- A paint callback can dirty itself again while the old batch is flushing.
        local e, cell, fire, flush, pending = fixture(client)
        local f = cell("FluxReentrantWorkCell"); e.FluxRaid_BindUnit(f, "party1"); flush()
        local old, injected = e.FluxRaid_UpdateHealth, false
        e.FluxRaid_UpdateHealth = function(frame)
            old(frame)
            if not injected then injected = true; fire(frame, "UNIT_HEALTH", "party1") end
        end
        fire(f, "UNIT_HEALTH", "party1")
        local arms, writes = e._workArms, f.healthBar.values
        flush()
        check(f.healthBar.values >= writes + 1, "reentrant raid request preserves current paint")
        if pending() > 0 then flush() end
        check(f.healthBar.values == writes + 2 and pending() == 0, "reentrant raid dirtiness paints once more then retires")
        check(e._workArms == arms + 1, "reentrant raid burst owns one new arm")
    end
end

local function opaque()
    return setmetatable({ opaque = true }, { __lt = function() error("secret compare") end,
        __le = function() error("secret compare") end, __sub = function() error("secret arithmetic") end,
        __tostring = function() error("secret serialization") end })
end
local nameplateBoot
local function plates(branch, count, mode)
    if not nameplateBoot then
        local source = fixturePrefix("tests/nameplate_countdown_work.lua", "for _, branch in ipairs(")
        source = replace(source, "local body = read(source)", "local body = '' -- isolate the complete Core owner")
        source = replace(source, "    return s\nend\n", "    s.env = env\n    return s\nend\n")
        nameplateBoot = assert(load(source .. "\nreturn boot", "@reused-nameplate-work-fixture", "t", fixtureEnv))()
    end
    local s = nameplateBoot(branch); local env = s.env
    env.NamePlateSetupOptions = { useClassicHealthBar = true, horizontalScale = 1, verticalScale = 1,
        unitNameAnchorStyle = 2, healthBarFontHeight = 12 }
    env.NamePlateConstants = { NAME_ANCHOR_STYLES = { InsideHealthBar = 1, AboveHealthBar = 2 } }
    env.Enum = { NamePlateStyle = { Modern = 0, CastFocus = 1 } }
    env.C_CVar = { GetCVar = function() return "0" end }
    local work = { alpha = 0, points = 0, hides = 0, textPoints = 0 }
    local function native(fields) return setmetatable({}, { __index = fields, __newindex = function() error("wrote native frame field") end }) end
    local function region(style, fields)
        local d = { alpha = 1, shown = true, points = {}, mode = mode }
        fields = fields or {}
        local function getter(value)
            if d.mode == "throw" then error("native getter unavailable") end
            if d.mode == "opaque" then return opaque() end
            return value
        end
        function fields:SetAlpha(value) check(value == 0, "native artwork keeps intended alpha zero"); d.alpha = value; work.alpha = work.alpha + 1 end
        function fields:Hide() d.shown = false; work.hides = work.hides + 1 end
        function fields:SetPoint(p, r, rp, x, y)
            local found
            for _, item in ipairs(d.points) do if item[1] == p then found = item; break end end
            local item = { p, r, rp, x, y }
            if found then for i = 1, 5 do found[i] = item[i] end else d.points[#d.points + 1] = item end
            local key = style and "points" or "textPoints"; work[key] = work[key] + 1
        end
        function fields:ClearAllPoints() d.points = {} end
        function fields:SetTextHeight(v) d.textHeight = v end
        function fields:SetJustifyH(v) d.justify = v end
        if mode ~= "missing" then
            function fields:GetAlpha() return getter(d.alpha) end
            function fields:IsShown() return getter(d.shown) end
            function fields:GetNumPoints() return getter(#d.points) end
            function fields:GetPoint(index)
                if d.mode == "throw" then error("native getter unavailable") end
                if d.mode == "opaque" then local v = opaque(); return v, v, v, v, v end
                return table.unpack(d.points[index] or {})
            end
        end
        return native(fields), d
    end
    s.controls = {}
    function s:add(unit)
        local art, artData = {}, {}
        for i = 1, 6 do art[i], artData[i] = region(false) end
        local left, ld = region(false); local right, rd = region(false); local mid, md = region(false)
        local bar, bd = region(true, { LeftText = left, RightText = right, Text = mid })
        local health, hd = region(true, { healthBar = bar }); local cast = region(true)
        local cc, cd = region(true); local loc, od = region(true); local name, nd = region(false)
        local diff, dd = region(false, { playerLevelDiffText = art[1], playerLevelDiffIcon = art[2], highLevelTexture = art[3], selectedBorder = art[4] })
        local level, vd = region(false, { LevelText = art[5], HighLevelTexture = art[6] })
        local fields = { unit = unit, HealthBarsContainer = health, CastBarsContainer = cast,
            AurasFrame = native({ CrowdControlListFrame = cc, LossOfControlFrame = loc }), PlayerLevelDiffFrame = diff, LevelFrame = level, name = name }
        local uf = native(fields)
        self.plates[unit] = native({ UnitFrame = uf, unitToken = unit })
        self:event("NAME_PLATE_UNIT_ADDED", unit)
        local c = { fields = fields, art = artData, health = hd, bar = bd, cc = cd, loc = od, diff = dd, level = vd,
            left = ld, right = rd, mid = md, name = nd, healthRegion = health, castRegion = cast, barRegion = bar }
        self.controls[#self.controls + 1] = c; return c
    end
    for i = 1, count do s:add("nameplate" .. i) end
    s.work = work
    return s
end

for _, target in ipairs({ { "PERF-02", "forever" }, { "PERF-03", "live" } }) do
    local id, branch = target[1], target[2]
    if not selected or selected == id then
        for _, count in ipairs({ 0, 1, 5, 40 }) do
            local s = plates(branch, count, "public")
            s:tick(1 / 60)
            local alpha, points, hides = s.work.alpha, s.work.points, s.work.hides
            for _ = 1, 600 do s:tick(1 / 60) end
            check(s.work.alpha == alpha and s.work.points == points and s.work.hides == hides,
                id .. " stable public native state incurs no repeated style writes")
            check(alpha == (branch == "forever" and count * 6 or 0), "first paint preserves artwork alpha")
            check(points == (branch == "forever" and count * 4 or 0) and hides == (branch == "live" and count * 2 or 0), "first paint preserves client geometry/level ownership")
            if count > 0 then
                local c = s.controls[1]
                if branch == "forever" then
                    check(c.health.points[1][1] == "BOTTOMRIGHT" and c.health.points[1][2] == c.castRegion and c.health.points[1][5] == 2,
                        "Forever health geometry preserves exact native relation/spacing")
                    check(c.cc.points[1][2] == c.healthRegion and c.cc.points[1][4] == 5 and c.loc.points[1][4] == 5,
                        "Forever CC/LOC preserve right-edge spacing")
                    check(c.right.points[1][1] == "RIGHT" and c.right.points[1][2] == c.barRegion and c.right.points[1][4] == -2,
                        "quarter-second health readout paint remains active")
                    check(c.diff.shown and c.level.shown, "Forever keeps native level frames shown for layout/options")
                    c.art[1].alpha = 1; c.health.points[1][4] = 99; c.cc.points[1][4] = 99
                else
                    check(#c.health.points == 0 and #c.bar.points == 0, "Live never stretches native health geometry")
                    c.level.shown = true
                end
                s:tick(1 / 60)
                check(s.work.alpha - alpha == (branch == "forever" and 1 or 0) and s.work.points - points == (branch == "forever" and 2 or 0)
                    and s.work.hides - hides == (branch == "live" and 1 or 0), "native external drift repaired on the next active tick")
                local before = s.work.alpha + s.work.points + s.work.hides
                s.env.SettingsPanel = { IsShown = function() return true end }
                c.art[1].alpha = 1; c.level.shown = true; s:tick(1)
                check(s.work.alpha + s.work.points + s.work.hides == before, "settings preview retains its ownership exclusion")
                s.env.SettingsPanel = nil; s:tick(1 / 60)
                check(s.work.alpha + s.work.points + s.work.hides > before, "closing settings restores native repair")
            else check(not s.driver.shown, "zero active nameplates keep the native driver asleep") end
        end
        for _, mode in ipairs({ "opaque", "missing", "throw" }) do
            local s = plates(branch, 1, mode); for _ = 1, 3 do s:tick(1 / 60) end
            check(s.work.alpha == (branch == "forever" and 18 or 0) and s.work.points == (branch == "forever" and 12 or 0)
                and s.work.hides == (branch == "live" and 6 or 0), "unreadable native state preserves original repair writes: " .. mode)
        end
        if branch == "forever" then
            local cadence = plates(branch, 1, "public")
            cadence:tick(0.249)
            check(cadence.work.textPoints == 0, "Forever readout does not paint before its existing quarter-second deadline")
            cadence:tick(0.0011)
            check(cadence.work.textPoints == 5, "Forever readout retains three text and two name anchors at its deadline")
            cadence:tick(0.249)
            check(cadence.work.textPoints == 5, "Forever readout resets its interval after painting")
            cadence:tick(0.0011)
            check(cadence.work.textPoints == 10, "Forever readout keeps its repeated cadence while native style writes stay quiet")
        end
        local s = plates(branch, 1, "public")
        s.controls[1].fields.unit = "preview"; s:tick(1)
        check(s.work.alpha + s.work.points + s.work.hides == 0, "preview plate excluded")
        s.controls[1].fields.unit = "nameplate1"; s:tick(1 / 60)
        local before = s.work.alpha + s.work.points + s.work.hides
        s:add("nameplate1"); s:tick(1 / 60)
        check(s.work.alpha + s.work.points + s.work.hides > before, "same unit with replacement native regions styles the new frame")
        s:event("NAME_PLATE_UNIT_REMOVED", "nameplate1"); before = s.work.alpha + s.work.points + s.work.hides; s:tick(1)
        check(not s.driver.shown and s.work.alpha + s.work.points + s.work.hides == before, "last removed nameplate stops style work")
    end
end
if not selected then
    for _, branch in ipairs({ "era", "anniversary", "progression" }) do
        local s = plates(branch, 40, "public"); for _ = 1, 600 do s:tick(1 / 60) end
        check(s.work.alpha + s.work.points + s.work.hides == 0, "Classic family retains its own native style policy")
    end
end

if not selected or selected == "PERF-04" then
    local source = read(sourceRoot .. "Other/FluxChatColumnMicros.lua")
    local a = assert(source:find("local function TrackCharacterPress(btn)", 1, true))
    local b = assert(source:find("local function WatchCharacterFrame(btn)", a, true))
    local state = { panel = false, holding = false, over = false, frames = {}, callbacks = 0, paints = 0, panelReads = 0 }
    local e = setmetatable({}, { __index = _G }); e._G = e
    function e.CreateFrame(_, _, parent)
        local f = { parent = parent, shown = true }
        function f:SetScript(_, fn) self.fn = fn end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        state.frames[#state.frames + 1] = f; return f
    end
    function e.IsMouseButtonDown() return state.holding end
    local track = assert(load("local CharacterPanelShown,ApplyCharacterPlate=...\n" .. source:sub(a, b - 1) .. "\nreturn TrackCharacterPress",
        "@FluxChatColumnMicros:press-watch", "t", e))(
        function() state.panelReads = state.panelReads + 1; return state.panel end,
        function(btn, pushed) state.paints = state.paints + 1; btn._fluxPlatePushed = pushed end)
    local parent = { shown = true, IsVisible = function(self) return self.shown end }
    local btn = { shown = true, _fluxPlatePushed = false, IsShown = function(self) return self.shown end,
        IsVisible = function(self) return self.shown and parent:IsVisible() end, IsMouseOver = function() return state.over end }
    local function tick(n)
        for _ = 1, n do for _, f in ipairs(state.frames) do if f:IsVisible() and f.fn then state.callbacks = state.callbacks + 1; f.fn() end end end
    end
    track(btn); track(btn); check(#state.frames == 1, "character button owns only one watcher")
    tick(600); check(state.callbacks == 600 and state.panelReads == 600 and state.paints == 0, "visible idle polling cadence remains unchanged")
    btn.shown = false; local before = state.callbacks; tick(600)
    check(state.callbacks == before, "PERF-04 hidden character button receives zero watch callbacks")
    btn.shown = true; state.holding, state.over = true, true; tick(1)
    check(btn._fluxPlatePushed and state.paints == 1, "left press still paints immediately on next native frame")
    tick(600); check(state.paints == 1, "held character press does not repaint redundantly")
    state.holding = false; tick(1); check(not btn._fluxPlatePushed and state.paints == 2, "release restores plate")
    state.panel = true; tick(1); check(btn._fluxPlatePushed, "native panel/keybinding open still pushes plate")
    parent.shown = false; before = state.callbacks; state.panel = false; tick(600)
    check(state.callbacks == before, "hidden ancestor also suppresses character watch callbacks")
    parent.shown = true; tick(1); check(not btn._fluxPlatePushed, "showing ancestor resamples native panel state")
    state.holding, state.over = true, false; tick(1); check(not btn._fluxPlatePushed, "left press outside button stays unpushed")
end
print("performance work budgets: " .. checks .. " checks passed (" .. (selected or "PERF-01..04") .. "; production code, native timing/taint pending)")
