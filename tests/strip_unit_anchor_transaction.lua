-- Exercise the real strip, squeeze notification and unit-root layout together.
-- An optional checkpoint directory supplies the exact before sources.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local contents = file:read("*a")
    file:close()
    return (contents:gsub("\r\n", "\n"))
end
local function section(source, first, last)
    local begin = assert(source:find(first, 1, true))
    return source:sub(begin, assert(source:find(last, begin + #first, true)) - 1)
end

local checkpoint = arg[1]
local stripFixture = read("tests/bars_strip_layout_work.lua")
stripFixture = stripFixture:sub(1, assert(stripFixture:find("\nlocal candidate=true;local checks", 1, true)) - 1)
local function fixture(before, placement, scale, lateEnvelope)
    local function source(path)
        return read(before and checkpoint .. "/" .. path:gsub("/", "-") or path)
    end
    local fixtureEnv = setmetatable({arg = before and {
        checkpoint .. "/Bars-Layout.lua", checkpoint .. "/Bars-Strip.lua",
    } or {}}, {__index = _G})
    local make = assert(load(stripFixture .. "\nreturn fixture", "@actual-strip-fixture", "t", fixtureEnv))()
    local strip = make(not before)
    local env = strip.env
    local trace = {}
    local function mark(name) trace[#trace + 1] = name end
    local function count(name)
        local n = 0
        for _, value in ipairs(trace) do
            if value == name then n = n + 1 end
        end
        return n
    end
    local ui = env.UIParent
    function ui:GetBottom() return 0 end
    function ui:GetEffectiveScale() return .75 end
    env.InCombatLockdown = function() return strip.combat end
    env.FLUX_PLAYER_TARGET_SIDE_BY_SIDE_GAP = 6
    env.FluxUnitFrames_GetPlayerTargetPlacement = function() return placement end
    env.FluxUnitFrames_ShouldUseFlux = function() return true end
    env.FluxUnitFrames_GetWholeFrameScale = function() return scale end
    env.FluxUnitFrames_GetScreenAnchorCenterOffsetX = function(_, _, _, h) return h / 2 end

    local function unit(name, alignment)
        local f = { unit = name, outerBorderAlignment = alignment, points = {}, shown = true, portraitPosition = "LEFT" }
        function f:GetHeight() return 88 end
        function f:GetWidth() return 238 end
        function f:GetBottom() return self.points[1] and self.points[1][5] or 0 end
        function f:GetEffectiveScale() return .75 * scale end
        function f:GetNumPoints() return #self.points end
        function f:GetPoint(index) return table.unpack(self.points[index]) end
        function f:ClearAllPoints()
            assert(not strip.combat)
            self.points = {}
            mark(name .. "Clear")
        end
        function f:SetPoint(...)
            assert(not strip.combat)
            self.points[#self.points + 1] = {...}
            mark(name .. "Point")
        end
        f.atlasBorderFrame = {GetEffectiveScale = f.GetEffectiveScale}
        f.atlasBorderFrame.FluxBorderFrame = {Bottom = {
            GetParent = function() return f.atlasBorderFrame end,
            GetRect = function() return 0, f:GetBottom() - 8, 230, 16 end,
        }}
        return f
    end
    local player, target = unit("player", "BOTTOM"), unit("target", placement == 2 and "BOTTOM" or "TOP")
    target.UpdateOuterBorder = function() mark("targetOuter") end
    target.CastBar = {UpdateLayout = function() mark("targetCast") end}
    local db = {threatBarPositionTarget = "right"}
    env.FluxOptions = {GetUnitFrameDB = function() return db end}
    local ns = {Flux = env.Flux, PlayerFrame = player, TargetFrame = target, UnitFrames = {
        LayoutThreatBar = function() mark("targetThreat") end,
        UpdateFrameVisualElements = function() mark("targetIcons") end,
    }, TargetOfTargetFrame = {_fluxRefreshTotAnchor = function() mark("targetTot") end}}
    local bridge = section(source("UnitFrames/FluxUnitFrames_OptionsBridge.lua"),
        "function _G.FluxUnitFrames_GetPlayerScreenBottomOffset()", "function FluxUnitFrames_ApplyThreatBarOptionsFromDB()")
    assert(load("local ns=...\n" .. bridge, "@actual-unit-root-layout", "t", env))(ns)
    local unitLayout = env.FluxUnitFrames_ApplyPlayerStatusBarLayout
    env.FluxUnitFrames_ApplyPlayerStatusBarLayout = function(anchorsOnly)
        mark(anchorsOnly == true and "anchorOnly" or "full")
        unitLayout(anchorsOnly)
    end
    local squeeze = section(source("FluxDefaultSettings.lua"),
        "-- Squeeze callback bodies are shared across notifications.", "local squeezeRefreshScheduled")
    assert(load(squeeze, "@actual-squeeze-transaction", "t", env))()

    local stripRoot = strip.B.Strip.frame
    env.FluxActionStrip = stripRoot
    function stripRoot:GetTop() return 110 + (self.height or 0) end
    function stripRoot:GetEffectiveScale() return .75 end
    local envelopeTop
    local envelope = {
        GetTop = function() return envelopeTop or stripRoot:GetTop() + 6 end,
        IsShown = function() return true end,
        GetEffectiveScale = function() return .75 end,
    }
    envelope.FluxBorderFrame = {Top = {
        GetParent = function() return envelope end,
        GetRect = function() return 0, envelope:GetTop() - 9, 1000, 17 end,
    }}
    env.FluxUnifiedBorderFrame = envelope
    env.FluxUnifiedBorder.UpdateBorder = function()
        mark("envelope")
        if lateEnvelope then envelopeTop = stripRoot:GetTop() + 22 end
    end
    local anchorAtCommit
    env.FluxBorder.Junctions.CommitLayout = function()
        mark("border")
        anchorAtCommit = player.points[1][5]
    end
    unitLayout()
    trace = {}

    local function crossing(inside)
        trace = {}
        strip.cursor, strip.hover = "spell", inside
        strip.B.Layout.OnCursor()
        strip.drain()
        assert(count("envelope") == 1 and count("border") == 1, "one envelope and border completion")
        if not before then
            local endOrder = table.concat(trace, ",")
            assert(endOrder:find("envelope,anchorOnly", 1, true) and trace[#trace] == "border",
                "unit roots settle after the envelope and before junction geometry")
            assert(count("full") == 0 and count("anchorOnly") == 1 and count("targetOuter") == 0)
            assert(count("playerPoint") <= 1 and count("targetPoint") <= 1)
            assert(math.abs(anchorAtCommit - envelope:GetTop() / scale) < 1e-8, "unit joins the current envelope top")
        end
        return anchorAtCommit, count("full"), count("anchorOnly"), count("targetOuter"), count("targetPoint")
    end
    return {
        crossing = crossing, unitLayout = unitLayout, trace = function() return table.concat(trace, ",") end,
        reset = function() trace = {} end, count = count, strip = strip, player = player, target = target,
        db = db, env = env, setPlacement = function(mode) placement = mode end,
    }
end

for _, placement in ipairs({1, 2}) do
    for _, scale in ipairs({.75, 1, 1.25}) do
        local after = fixture(false, placement, scale)
        local before = checkpoint and fixture(true, placement, scale)
        for _, inside in ipairs({true, false, true, false, true, false}) do
            local y, full, light, chrome, targetPoints = after.crossing(inside)
            assert(targetPoints == 0, "same support height keeps both the classic and joined target anchors")
            if before then
                local oldY, oldFull, oldLight, oldChrome, oldPoints = before.crossing(inside)
                assert(oldY == y and oldPoints == 2 and oldFull == 2 and oldLight == 0 and oldChrome == 2)
                assert(before.strip.signature() == after.strip.signature(), "same strip hosts, bindings and geometry")
                print(("STRIP_UNIT_ANCHORS placement=%d scale=%.2f enter=%s calls=%d/%d targetChrome=%d/%d rootPoints=%d/%d")
                    :format(placement, scale, tostring(inside), oldFull, full + light, oldChrome, chrome, oldPoints, targetPoints))
            end
        end
    end
end

local changedEnvelope = fixture(false, 2, 1, true)
changedEnvelope.crossing(true)
assert(changedEnvelope.count("playerPoint") == 1 and changedEnvelope.count("targetPoint") == 1,
    "a rising envelope moves both units once")
if checkpoint then
    local previousEnvelope = fixture(true, 2, 1, true)
    local oldY = previousEnvelope.crossing(true)
    assert(changedEnvelope.player.points[1][5] > oldY, "before source used the stale lower envelope")
end

local repair = fixture(false, 1, 1)
repair.reset()
repair.setPlacement(2)
repair.db.threatBarPositionTarget = "left"
repair.unitLayout(true)
assert(repair.target.outerBorderAlignment == "BOTTOM" and repair.db.threatBarPositionTarget == "right")
for _, name in ipairs({"targetOuter", "targetCast", "targetThreat", "targetIcons", "targetTot"}) do
    assert(repair.count(name) == 1, "placement changes fully refresh " .. name)
end
repair.reset()
repair.unitLayout()
assert(repair.count("targetOuter") == 1 and repair.count("targetPoint") == 1, "explicit refresh retains full path")

local private = setmetatable({}, {__eq = function() error("opaque anchor comparison") end})
repair.env.issecretvalue = function(value) return rawequal(private, value) end
local getPoint = repair.target.GetPoint
for _, kind in ipairs({"privatePoint", "privateCount", "denied", "missing", "extra", "drift"}) do
    repair.reset()
    repair.target.GetPoint = getPoint
    repair.target.GetNumPoints = function() return #repair.target.points end
    if kind == "privatePoint" then repair.target.GetPoint = function() return private, private, private, private, private end
    elseif kind == "privateCount" then repair.target.GetNumPoints = function() return private end
    elseif kind == "denied" then repair.target.GetPoint = function() error("anchor unavailable") end
    elseif kind == "missing" then repair.target.GetPoint = false
    elseif kind == "extra" then repair.target.points[2] = {"TOP", repair.env.UIParent, "BOTTOM", 5, 5}
    else repair.target.points[1][4] = -101 end
    repair.unitLayout(true)
    assert(repair.count("targetPoint") == 1 and #repair.target.points == 1 and repair.target.points[1][4] == 3,
        "native anchor recovery: " .. kind)
end
repair.reset()
repair.strip.combat = true
repair.unitLayout(true)
assert(repair.trace() == "", "ordinary placement writes remain outside lockdown")
print("Strip unit anchor transaction passes both placements, three scales, envelope changes, anchor recovery and lockdown.")
