-- Compare the actual Details geometry functions with the native adapter.
-- Widget/settings mocks do not emulate native rendering, secrets, taint or FPS.
local source = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
local savedArgs = arg; arg = { source, "--harness" }
local harness = assert(loadfile("tests/native_meter_ownership.lua"))(); arg = savedArgs
local checks, failures, cases = 0, 0, 0
local function check(value, label)
    checks = checks + 1
    if not value then failures = failures + 1; if failures <= 12 then print("FAIL " .. label) end end
end
local function near(a, b) return type(a) == "number" and math.abs(a - b) < .000001 end
local function read(path) local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s end
local detailsSource, layoutSource = read("Battlezonemap/FluxDetails.lua"), read("Battlezonemap/FluxMeterLayout.lua")
local function localFunction(text, name)
    local first = assert(text:find("local function " .. name .. "(", 1, true), name)
    local last = assert(text:find("\nend", first, true), name)
    return text:sub(first, last + 3)
end
local function reference(outer)
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.FluxWindowFrame = { WINDOW_WIDTH = 405, WINDOW_HEIGHT = 270 }
    local instances = {}
    for i = 1, 6 do
        local frame = { points = {} }
        function frame:ClearAllPoints() self.points = {} end
        function frame:SetPoint(...) self.points[#self.points + 1] = { ... } end
        function frame:SetScale(scale) self.scale = scale end
        function frame:Hide() end
        instances[i] = { baseframe = frame }
    end
    env.Details = { tabela_instancias = instances }
    env.EnsureNWindows = function() return instances end
    env.EnsureEmbeddedParentage = function() end
    env.WithEmbedAnchorWrite = function(_, callback) callback() end
    env.AssignSlot = function(_, _, used) return used end
    env.SetDetailsFrameLevels = function() end
    local chunk = { "local isEmbedded = true", "local MAX_COLS = 3", "local COL_FRAC_MIN = .10" }
    for _, name in ipairs({ "EMBED_TOP_ROW_FRAC_DEFAULT", "EMBED_TOP_ROW_FRAC_MIN", "EMBED_TOP_ROW_FRAC_MAX",
        "EMBED_DAMAGE_TOP_OFF", "EMBED_HEAL_TOP_OFF", "EMBED_ROW_GAP", "METER_GRID_LEFT_COL_FRAC" }) do
        chunk[#chunk + 1] = "local " .. name .. " = " .. assert(detailsSource:match("local " .. name .. " = ([%d%.]+)"), name)
    end
    chunk[#chunk + 1] = localFunction(layoutSource, "EqualColFracs")
    chunk[#chunk + 1] = localFunction(layoutSource, "NormalizeColFracs")
    chunk[#chunk + 1] = "FluxMeterLayout = { NormalizeColFracs = NormalizeColFracs }"
    for _, name in ipairs({ "NormalizeColFracsEmbed", "GetEmbedContainerWidth", "ForceCorrectPosition", "ForceGridPosition", "LayoutMeterGrid" }) do
        chunk[#chunk + 1] = localFunction(detailsSource, name)
    end
    chunk[#chunk + 1] = "return { layout = LayoutMeterGrid, stack = ForceCorrectPosition, grid = ForceGridPosition }"
    local api = assert(load(table.concat(chunk, "\n"), "@actual Details geometry", "t", env))()
    env.PositionWindow = api.stack; env.PositionWindowGrid = api.grid
    return function(layout) api.layout(outer, layout); return instances end
end
local function nativeSlot() return { kind = "blizzard", damageMeterType = 0 } end
local function threatSlot() return { kind = "plugin", plugin = "DETAILS_PLUGIN_FLUX_THREAT" } end
local function boot(w, h, scale, gamepad)
    local e, s = harness(gamepad)
    -- Geometry compares three pre-existing native windows. Gamepad intentionally
    -- leaves creation to Blizzard rather than initializing dropdowns from Flux.
    s.dm:ShowNewSecondarySessionWindow()
    for _, window in ipairs(s.windows) do window.meterType = 0 end -- Native-selected Damage views.
    local outer = e.CreateFrame(); outer.width, outer.height, outer.scale = w, h, scale
    outer.Content = s.host; s.host:SetParent(outer)
    s.host.width, s.host.height, s.host.scale = w - 40, h - 40, scale
    e.FluxWindowFrame.frame = outer
    local owned = {}
    function owned:IsAvailable() return true end
    function owned:GetFrame() return self.frame end
    function owned:Embed(parent, presentationScale)
        self.frame = self.frame or e.CreateFrame(); self.frame:SetParent(parent); self.frame:SetScale(presentationScale)
        self:Show(); return self.frame
    end
    function owned:Show() if self.frame then self.frame:Show() end end
    function owned:Hide() if self.frame then self.frame:Hide() end end
    function owned:Cleanup() self:Hide() end
    function owned:RefreshLayout() end
    e.FluxThreatMeter = owned
    return e, s, outer, owned, reference(outer)
end
local variants = {
    {},
    { topRowFrac = .25, topColFracs = { .3, .7 }, bottomColFracs = { .2, .5, .3 } },
    { topRowFrac = .75, topColFracs = { .1, .2, .7 }, bottomColFracs = { .65, .35 } },
    { topRowFrac = 0, leftColFracTop = .30, leftColFracBottom = .70 },
    { topRowFrac = 1, topColFracs = { -2, .001, 10 }, bottomColFracs = { -1, 4 } },
}
for _, gamepad in ipairs({ false, true }) do
    for _, size in ipairs({ { 405, 270 }, { 620, 420 }, { 240, 160 }, { 80, 80 } }) do
        for _, scale in ipairs({ .64, 1, 1.25 }) do
            local e, s, outer, owned, expected = boot(size[1], size[2], scale, gamepad)
            for topCount = 0, 3 do for bottomCount = 0, 3 do
                local total = topCount + bottomCount
                if total > 0 and total <= 4 then
                    for threatIndex = total == 4 and 1 or 0, total do
                        for _, variant in ipairs(variants) do
                            local layout = {}; for key, value in pairs(variant) do layout[key] = value end
                            layout.topSlots, layout.bottomSlots = {}, {}
                            local selected = {}
                            for i = 1, total do
                                local slot = i == threatIndex and threatSlot() or nativeSlot()
                                selected[i] = slot
                                local row = i <= topCount and layout.topSlots or layout.bottomSlots
                                row[#row + 1] = slot
                            end
                            local referenceWindows = expected(layout)
                            check(e.FluxBlizzardMeter:Embed(s.host, layout), "native layout embeds")
                            local relativeScale = gamepad and s.dm.scale / scale or s.dm.scale
                            local rootW, rootH = s.dm.width * relativeScale, s.dm.height * relativeScale
                            local rootLeft, rootTop = (size[1] - rootW) / 2, (size[2] - rootH) / 2
                            check(near(rootW, size[1]) and near(rootH, size[2]) and s.dm.points[1][2] == outer,
                                "native canvas matches outer Flux frame and center reference")
                            check(s.dm:GetParent() == (gamepad and e.UIParent or s.host), "native parent contract remains unchanged")
                            local nativeIndex = 1
                            for i, slot in ipairs(selected) do
                                local pane
                                if slot.kind == "plugin" then pane = owned:GetFrame() else pane = s.windows[nativeIndex]; nativeIndex = nativeIndex + 1 end
                                local first, last = pane.points[1], pane.points[2]
                                local wanted = referenceWindows[i].baseframe.points
                                local left, top = rootLeft + first[4] * relativeScale, rootTop - first[5] * relativeScale + 14
                                local right, bottom = rootLeft + rootW + last[4] * relativeScale, rootTop + rootH - last[5] * relativeScale
                                check(near(left, wanted[1][4]) and near(right, size[1] + wanted[2][4])
                                    and near(top, -wanted[1][5]) and near(bottom, size[2] - wanted[2][5]),
                                    "body rectangle equals actual Details positions for every slot")
                            end
                            cases = cases + 1
                        end
                    end
                end
            end end
            local heightCalls, spacingCalls, refreshes = s.barHeightCalls, s.barSpacingCalls, s.rowRefreshes
            for _ = 1, 500 do e.FluxBlizzardMeter:RefreshEmbeddedLayout() end
            check(s.barHeightCalls == heightCalls and s.barSpacingCalls == spacingCalls and s.rowRefreshes == refreshes,
                "500 unchanged layouts make no native row-setting writes or refreshes")
            check(s.sessionCalls == 0, "geometry and row styling never rewrite native session selection")
            e.FluxBlizzardMeter:Cleanup()
        end
    end
end
for _, gamepad in ipairs({ false, true }) do
    local e, s = harness(gamepad); local meter, win = e.FluxBlizzardMeter, s.windows[1]
    check(meter:Embed(s.host), "row-style fixture embeds")
    check(win:GetBarHeight() == 25 and win:GetBarSpacing() == 4,
        "native row density remains owned by Blizzard settings")
    check(s.barHeightCalls == 0 and s.barSpacingCalls == 0 and s.rowRefreshes == 0,
        "docking never invokes native row setters or refreshes")
    win:SetBarHeight(30); win:SetBarSpacing(6); meter:RefreshEmbeddedLayout()
    check(win:GetBarHeight() == 30 and win:GetBarSpacing() == 6, "new native preferences remain untouched while embedded")
    meter:Cleanup()
    check(win:GetBarHeight() == 30 and win:GetBarSpacing() == 6, "cleanup restores the latest observed native preferences")
    meter:Embed(s.host); win:SetBarHeight(31); win:SetBarSpacing(7); meter:Cleanup()
    check(win:GetBarHeight() == 31 and win:GetBarSpacing() == 7, "cleanup never overwrites a newer native change")
    meter:Embed(s.host); s.combat = true; meter:Cleanup()
    check(win:GetBarHeight() == 31 and win:GetBarSpacing() == 7, "combat cleanup never writes native row settings")
    s.combat = false; s.event("PLAYER_REGEN_ENABLED"); s.drain()
    check(win:GetBarHeight() == 31 and win:GetBarSpacing() == 7, "deferred cleanup restores row preferences after combat")
    meter:Embed(s.host); s.details = true; meter:Hide()
    check(win:GetBarHeight() == 31 and win:GetBarSpacing() == 7, "Details handoff restores native row preferences")
    s.details = false; meter:Embed(s.host); s.combat = true; s.details = true; meter:Hide()
    check(win:GetBarHeight() == 31 and win:GetBarSpacing() == 7, "combat Details handoff never writes row settings")
    s.combat = false; s.event("PLAYER_REGEN_ENABLED")
    check(win:GetBarHeight() == 31 and win:GetBarSpacing() == 7, "deferred Details handoff restores preferences once allowed")
end
local e, s = harness(false)
local opaque = setmetatable({}, { __lt = function() error("opaque setting comparison") end,
    __le = function() error("opaque setting comparison") end })
e.issecretvalue = function(value) return value == opaque end
local opaqueWindow = s.windows[1]
function opaqueWindow:GetBarHeight() return opaque end
function opaqueWindow:GetBarSpacing() return opaque end
check(e.FluxBlizzardMeter:Embed(s.host), "unreadable optional row settings do not prevent geometry")
check(s.windows[1].barHeight == nil and s.windows[1].barSpacing == nil,
    "opaque row settings are never compared or overwritten")
e.FluxBlizzardMeter:Cleanup()
print(string.format("native grid parity: %d checks, %d failures; actual Details layouts=%d; native pixels/taint unverified", checks, failures, cases))
assert(failures == 0, "native meter grid parity regressions")
