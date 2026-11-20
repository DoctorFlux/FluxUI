-- Actual bar range/event/hotkey owners + shared text/texture tint utility.
-- FontString rendering is captured as text/color calls; native pixels pending.
local checks = 0
local function check(ok, message) checks = checks + 1; assert(ok, message) end
local paintPath = (arg and arg[1]) or "Bars/Paint.lua"
local function fixture(client, key)
    local f = { key = key, inRange = true, hasAction = true, units = { target = true, focus = true }, unit = "target",
        rangeQueries = 0, usableUpdates = 0, textWrites = 0, colorWrites = 0 }
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.GetBindingKey = function() return f.key end
    e.GetBindingText = function(value) return value end
    e.IsShiftKeyDown = function() return f.shift end
    e.IsControlKeyDown = function() return f.ctrl end
    e.UnitExists = function(unit) return f.units[unit] end
    e.GetActionInfo = function() return "spell", 101 end
    e.InCombatLockdown = function() return true end
    local flux = { Client = { key = client, isPostDF = client == "live" }, Bars = {} }
    flux.Action = { HasAction = function() return f.hasAction end }
    flux.Range = { ResolveUnit = function() return f.unit end,
        CheckSpell = function() f.rangeQueries = f.rangeQueries + 1; return f.inRange end }
    local function font()
        local fs = { text = "", shown = false }
        function fs:SetText(text) self.text = text; f.textWrites = f.textWrites + 1 end
        function fs:GetText() return self.text end
        function fs:SetTextColor(r, g, b) self.r, self.g, self.b = r, g, b; f.colorWrites = f.colorWrites + 1 end
        function fs:SetFontObject() self.r, self.g, self.b = 0.75, 0.75, 0.75 end
        function fs:GetFont() return "font", 14, "OUTLINE" end
        function fs:SetFont() end
        function fs:GetWidth() return 40 end
        function fs:Show() self.shown = true end
        function fs:Hide() self.shown = false end
        for _, name in ipairs({ "ClearAllPoints", "SetPoint", "SetHeight", "SetJustifyH", "SetJustifyV", "SetWordWrap" }) do fs[name] = function() end end
        return fs
    end
    local widget = { GetWidth = function() return f.width or 44 end, GetHeight = function() return 44 end }
    function widget:CreateFontString() return font() end
    local host = { slot = 1, row = "main", widget = widget, bindingCommand = "ACTIONBUTTON1", _fluxAType = "spell", _fluxAId = 101 }
    flux.Bars.Hosts = { LiveSlot = function(h) return h.slot end, ForSlot = function() return { host } end }
    flux.Bars.ForEachHost = function(fn) fn(host) end
    local ns = { Flux = flux }
    assert(loadfile("Core/Hotkey.lua", "t", e))("_FluxUI", ns)
    assert(loadfile(paintPath, "t", e))("_FluxUI", ns)
    local p = flux.Bars.Paint
    f.actualUsable = p.UpdateUsable
    p.UpdateUsable = function() f.usableUpdates = f.usableUpdates + 1 end
    f.e, f.flux, f.paint, f.host, f.font = e, flux, p, host, font
    function f.verify(red, glyph)
        local fs = assert(host.WHotKey)
        check(fs.r == (red and 1 or 0.75) and fs.g == (red and 0.1 or 0.75) and fs.b == (red and 0.1 or 0.75), client .. ": range controls hotkey text color")
        check(flux.Hotkey.IsOutOfRange(fs) == red, client .. ": shared range state matches bar owner")
        if glyph then
            check(fs.text:find("|T", 1, true) ~= nil, "mouse binding retains its texture glyph")
            check((fs.text:find(":255:26:26|t", 1, true) ~= nil) == red, "only out-of-range state adds red glyph vertex tint")
        end
        local overlay = widget._fluxHotkeyMod
        if overlay and overlay.shown then
            check(overlay.r == fs.r and overlay.g == fs.g and overlay.b == fs.b, "modifier overlay uses the same range color")
        end
    end
    return f
end

for _, client in ipairs({ "live", "forever", "classic" }) do
for _, key in ipairs({ "Q", "BUTTON4", "MOUSEWHEELUP", "SPACE" }) do
    local f = fixture(client, key)
    local p, h, H = f.paint, f.host, f.flux.Hotkey
    local glyph = key ~= "Q"
    check(H.SetText and H.SetRange and H.IsOutOfRange, "shared hotkey range API is available")
    -- Range can arrive before a label is constructed. No extra range check is
    -- needed when hotkey preparation later consumes that existing result.
    f.inRange = false; p.UpdateRange(h)
    check(h._outOfRange == true and f.rangeQueries == 1, "range owner records public out-of-range before label readiness")
    h.WHotKey = f.font(); p.UpdateHotkey(h); f.verify(true, glyph)
    check(f.rangeQueries == 1, "hotkey creation does not query range")
    local textWrites, colorWrites = f.textWrites, f.colorWrites
    for _ = 1, 10 do p.UpdateRange(h); p.UpdateHotkey(h) end
    check(f.textWrites == textWrites and f.colorWrites == colorWrites, "stable range/hotkey cache skips text and color writes")
    check(f.rangeQueries == 11, "existing range call cadence is unchanged")

    -- Rebuilding font style, modifier labels and squeeze must retain red.
    f.shift = true; p.UpdateHotkey(h); f.verify(true, glyph)
    if glyph then check(h.widget._fluxHotkeyMod and h.widget._fluxHotkeyMod.text == "S-", "mouse modifier overlay retains its label") end
    f.width = 31; p.UpdateHotkey(h); f.verify(true, glyph)
    f.key = "Z"; p.UpdateHotkey(h); f.verify(true, false)
    check(h.WHotKey.text:find("Z", 1, true), "binding refresh keeps the new logical label")
    f.key = key; f.shift = false; p.UpdateHotkey(h); f.verify(true, glyph)

    local before = f.rangeQueries
    p.ApplySlotRange(1, true, true); f.verify(false, glyph)
    p.ApplySlotRange(1, false, true); f.verify(true, glyph)
    p.ApplySlotRange(1, false, false); f.verify(false, glyph)
    check(f.rangeQueries == before, "native slot payload tint adds no range probe")
    f.inRange = false; p.UpdateRange(h); f.verify(true, glyph)
    f.inRange = nil; p.UpdateRange(h); f.verify(false, glyph)
    f.inRange = false; p.UpdateRange(h)
    before = f.rangeQueries; f.units.target = false; p.UpdateRange(h); f.verify(false, glyph)
    check(f.rangeQueries == before, "target loss clears hotkey without probing a missing unit")
    f.units.target = true; p.UpdateRange(h); f.verify(true, glyph)
    f.hasAction = false; before = f.rangeQueries; p.UpdateRange(h); f.verify(false, glyph)
    check(f.rangeQueries == before, "empty action clears range without a range probe")
    f.hasAction = true; p.UpdateRange(h); f.verify(true, glyph)
    p.ClearCache(h); f.verify(false, glyph)
    p.UpdateRange(h); f.verify(true, glyph)
    h._fluxParked = true; before = f.rangeQueries
    p.Flush({ ["bars.range"] = true }); f.verify(false, glyph)
    check(f.rangeQueries == before, "range-only parked sweep clears stale red without a probe")
    h._fluxParked = false; p.UpdateRange(h); f.verify(true, glyph)
    f.hasAction = false; f.actualUsable(h); f.verify(false, glyph)

    -- Older isolated mocks may omit the shared module; their numeric labels
    -- still receive range color without requiring additional services.
    f.flux.Hotkey = nil; f.key = "Q"; f.hasAction = true
    p.UpdateHotkey(h); p.UpdateRange(h)
    check(h.WHotKey.r == 1 and h.WHotKey.g == 0.1, "legacy adapter retains out-of-range text color")
    f.inRange = true; p.UpdateRange(h)
    check(h.WHotKey.r == 0.75 and h.WHotKey.g == 0.75, "legacy adapter restores normal text color")
end
end
print(("Bar hotkey range: %d checks PASS; actual range/event/hotkey Lua owners, FontString sink modeled; native glyph pixels pending"):format(checks))
