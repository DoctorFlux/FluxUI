-- Replay the live roster branch and Flux threat anchor code with modeled widgets.
-- Optional argument is an archived UnitFrames/FluxUnitFrames_Shared.lua.
local function read(path)
    local f = assert(io.open(path, "rb"))
    local source = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return source
end

local function section(source, first, last)
    local start = assert(source:find(first, 1, true))
    local stop = assert(source:find(last, start + #first, true))
    return source:sub(start, stop - 1)
end

local function boot(source, unit, position)
    local state = { allowed = true, enemy = true, position = position, writes = 0, paints = 0, auras = 0 }
    local sealed = setmetatable({}, {
        __eq = function() error("private value compared") end,
        __sub = function() error("private value used in arithmetic") end,
    })
    local e = setmetatable({
        ns = {},
        ValueIsSecret = function(v) return rawequal(v, sealed) end,
        PublicGeometryNumber = function(v) return type(v) == "number" and v == v and v or nil end,
        THREAT_EMPTY_R = .1, THREAT_EMPTY_G = .1, THREAT_EMPTY_B = .1,
        THREAT_BAR_HEIGHT = 20, THREAT_BAR_PORTRAIT_HEIGHT = 10, THREAT_OUTER_OVERLAP = 4,
        UnitExists = function() return true end,
        UnitAffectingCombat = function() return true end,
        ThreatBarAurasAboveUnit = function() return state.above == true end,
        ThreatBarAllowedByGroup = function() return state.allowed end,
        ThreatBarModeIsVertical = function(v) return v == "left" or v == "right" end,
        ThreatBarShouldShowStrip = function() return state.enemy end,
        ThreatBarUpdateGlow = function(shell) shell._fluxThreatGlowBand = 0 end,
        UF = {
            GetThreatBarPosition = function() return state.position end,
            UpdateAuraPosition = function() state.auras = state.auras + 1 end,
            FrameUsesPortraitLayout = function() return true end,
        },
    }, { __index = _G })
    local function region(name)
        local t = { name = name, width = 160, height = 55, points = {}, shown = true }
        function t:ClearAllPoints() self.points = {}; state.writes = state.writes + 1 end
        function t:SetPoint(...) self.points[#self.points + 1] = {...}; state.writes = state.writes + 1 end
        function t:GetPoint(i)
            if self.private then return sealed, sealed, sealed, sealed, sealed end
            if self.fault then error("point temporarily unavailable") end
            return table.unpack(self.points[i] or {})
        end
        function t:GetNumPoints() return #self.points end
        function t:GetWidth() return self.width end
        function t:GetHeight() return self.height end
        function t:SetWidth(value) self.width = value end
        function t:SetHeight(value) self.height = value end
        function t:Show() self.shown = true end
        function t:Hide() self.shown = false end
        function t:SetValue(value) self.value = value end
        function t:SetStatusBarColor(r, g, b) self.color = table.concat({r, g, b}, ",") end
        function t:SetOrientation(value) self.orientation = value end
        function t:GetStatusBarTexture() end
        return t
    end

    local frame = region(unit)
    frame.unit, frame.outerBorderFrame, frame.PortraitFrame = unit, region("outer"), region("portrait")
    frame.ThreatBar = region("threat")
    frame.ThreatBar.StatusBar = region("fill")
    frame.ThreatBar.FluxBorderFrame = region("border")
    e.UF.UpdateThreatBar = function(self)
        state.paints = state.paints + 1
        self.ThreatBar.StatusBar:SetValue(state.paints)
    end

    local event = section(source, '    elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE"',
        '    elseif event == "PLAYER_UPDATE_RESTING"')
    local queue = source:find("    local function RefreshRosterChrome(frame)", 1, true)
        and section(source, "do\n    local queuedFrames, queuedSet", "local function OnEvent") or ""
    local code = section(source, "local function ThreatBarSetEmptyVisual(", "function UF.CreateThreatBar(")
        .. section(source, "function UF.LayoutThreatBar(", "-- Compat alias")
        .. queue
        .. "return function(self, event)\n    if false then\n" .. event .. "\n    end\nend"
    local dispatch = assert(load(code, "@actual-threat-roster-layout", "t", e))()
    function state.event() dispatch(frame, "GROUP_ROSTER_UPDATE") end
    function state.explicit() e.UF.LayoutThreatBar(frame) end
    function state.signature()
        local values = {}
        local function record(f)
            for _, point in ipairs(f.points) do
                local p, a, rp, x, y = table.unpack(point)
                values[#values + 1] = table.concat({p, a.name, rp, x + 0, y + 0}, ",")
                assert(a == frame or a == frame.ThreatBar or a == frame.outerBorderFrame or a == frame.PortraitFrame)
            end
            values[#values + 1] = table.concat({tostring(f.shown), f.width, f.height, f.orientation or "",
                f.value or "", f.color or "", f._fluxPublicHeight or "", f._fluxPublicWidth or ""}, "|")
        end
        record(frame.ThreatBar); record(frame.ThreatBar.StatusBar); record(frame.ThreatBar.FluxBorderFrame)
        return table.concat(values, ";")
    end
    state.frame, state.region = frame, region
    return state
end

local current = read("UnitFrames/FluxUnitFrames_Shared.lua")
local prior = arg[1] and read(arg[1])
-- The local control calls the complete explicit layout on each roster event.
local reference = prior or current:gsub("UF%.LayoutThreatBar%(frame, true%)", "UF.LayoutThreatBar(frame)")
local checks, before, after = 0, 0, 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
for _, unit in ipairs({"target", "focus"}) do
    for _, position in ipairs({"portrait", "between", "left", "right"}) do
        local a, b = boot(reference, unit, position), boot(current, unit, position)
        local function compare(label, change, useExplicit)
            for _, s in ipairs({a, b}) do
                if change then change(s) end
                if useExplicit then s.explicit() else s.event() end
            end
            check(a.signature() == b.signature(), unit .. " " .. position .. " " .. label)
            check(a.paints == b.paints and a.auras == b.auras, label .. " retains paint and aura cadence")
        end
        compare("initial")
        a.writes, b.writes = 0, 0
        for _ = 1, 20 do compare("steady roster") end
        check(a.writes == 120 and b.writes == 0, "known shell and fill points stay in place")
        before, after = before + a.writes, after + b.writes
        compare("leave", function(s) s.allowed = false end)
        compare("settled solo")
        compare("join", function(s) s.allowed = true end)
        compare("unit type changed", function(s) s.enemy = false end)
        compare("eligible enemy", function(s) s.enemy = true end)
        compare("changed side and warning mode", function(s) s.above = true; s.position = "between" end)
        compare("portrait selected again", function(s) s.position = "portrait" end)
        compare("replacement portrait owner", function(s) s.frame.PortraitFrame = s.region("replacement") end)
        compare("drifting shell and fill", function(s)
            s.frame.ThreatBar.points[1][4] = 7
            s.frame.ThreatBar.StatusBar.points[3] = {"CENTER", s.frame.ThreatBar, "CENTER", 0, 0}
        end)
        for _, kind in ipairs({"private", "fault"}) do
            compare(kind .. " point getters", function(s) s.frame.ThreatBar[kind] = true end)
            check(b.writes > 0, kind .. " native geometry follows the repair path")
            a.frame.ThreatBar[kind], b.frame.ThreatBar[kind] = nil, nil
        end
        a.writes, b.writes = 0, 0
        compare("explicit settings application", nil, true)
        check(a.writes == 6 and b.writes == 6, "explicit layout retains original anchoring")
    end
end
print(("Threat roster anchors: %d checks, repeated points cleared/set %d -> %d. Native latency/taint pending.")
    :format(checks, before, after))
