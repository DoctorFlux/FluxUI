-- Actual hotkey renderers and bar/EBS range owners. Inline RGB is inspected;
-- a FontString color spy deliberately does not tint embedded textures for us.
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s:gsub("\r\n", "\n")
end
local overrides = {}
for i, flag in ipairs(arg or {}) do
    if flag == "--hotkey" then overrides["Core/Hotkey.lua"] = arg[i + 1] end
    if flag == "--util" then overrides["ExtraButtonSystem/Shared/HotkeyUtil.lua"] = arg[i + 1] end
    if flag == "--bars" then overrides["Bars/Paint.lua"] = arg[i + 1] end
    if flag == "--extra" then overrides["ExtraButtonSystem/Engine/Paint.lua"] = arg[i + 1] end
    if flag == "--trinket" then overrides["ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua"] = arg[i + 1] end
    if flag == "--utility" then overrides["ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua"] = arg[i + 1] end
end
local function fixture()
    local f = { binding = {}, range = true, exists = true, filled = true, usable = true, noMana = false, keep = false, revision = 1, timers = {} }
    local e = setmetatable({ FLUX_API = { majorVersion = 12 }, FluxButton = {} }, { __index = _G }); e._G = e
    e.GetBindingKey = function(command) return f.binding[command] end
    e.GetBindingText = function(key) return key end
    e.IsShiftKeyDown = function() return f.shift end
    e.IsControlKeyDown = function() return f.ctrl end
    e.IsAltKeyDown = function() return f.alt end
    e.InCombatLockdown = function() return false end
    e.UnitExists = function() return f.exists end
    e.GetActionInfo = function() return "spell", 201 end
    e.UnitClass = function() return "Mage", "MAGE" end
    e.RAID_CLASS_COLORS = { MAGE = { r = .2, g = .6, b = 1 } }
    e.GetInventoryItemID = function(_, slot) return slot == 13 and 900001 or nil end
    e.GetInventoryItemLink = function(_, slot) return slot == 13 and "item:900001" or nil end
    e.ClearOverrideBindings = function() end
    e.SetOverrideBindingClick = function() end
    e.C_Timer = { After = function(_, fn) f.timers[#f.timers + 1] = fn end }
    e.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    local function font()
        local fs = { text = "", writes = 0, color = { .75, .75, .75 }, shown = true }
        function fs:SetText(text) self.text = text; self.writes = self.writes + 1 end
        function fs:GetText() return self.text end
        function fs:SetTextColor(r, g, b) self.color = { r, g, b } end
        function fs:GetTextColor() return table.unpack(self.color) end
        function fs:SetVertexColor(r, g, b) self.color = { r, g, b } end
        function fs:GetVertexColor() return table.unpack(self.color) end
        function fs:Show() self.shown = true end
        function fs:Hide() self.shown = false end
        function fs:GetFont() return "font", 14, "OUTLINE" end
        function fs:GetWidth() return self.width or 30 end
        function fs:SetSize(w, h) self.width, self.height = w, h end
        function fs:SetHeight(h) self.height = h end
        function fs:SetPoint(...) self.point = { ... } end
        for _, name in ipairs({ "ClearAllPoints", "SetFontObject", "SetFont", "SetJustifyH", "SetJustifyV", "SetWordWrap" }) do fs[name] = function() end end
        return fs
    end
    local function widget(name)
        local w = { name = name }
        function w:GetName() return self.name end
        function w:GetWidth() return 22 end
        function w:GetHeight() return 44 end
        function w:GetAttribute() end
        function w:CreateFontString() return font() end
        function w:RegisterEvent() end
        function w:SetScript() end
        function w:Show() end
        function w:Hide() end
        return w
    end
    e.CreateFrame = function(_, name) return widget(name) end
    local flux = { Client = { isPostDF = true }, EBS = { buttons = {}, badges = {} },
        Bars = { CONFIG = { buttonSize = 44 }, COLOR = { usable = {1,1,1}, mana = {.5,.5,1}, unusable = {.4,.4,.4}, outOfRange = {.8,.1,.1} } },
        Action = { HasAction = function() return f.filled end, IsUsable = function() return f.usable, f.noMana end },
        Spell = { IsUsable = function() return f.usable, f.noMana end },
        Item = { IsUsable = function() return f.usable, f.noMana end, GetSpell = function() return "Use Effect", 201 end,
            IsEquipped = function() return true end, IsConsumable = function() return false end, UsesConsumableCharges = function() return false end },
        Range = { ResolveUnit = function() return "target" end, CheckSpell = function() return f.range, f.keep end,
            CheckItem = function() return f.range, f.keep end, CheckAction = function() return f.range, f.keep end,
            GetUnitRevision = function() return f.revision end },
    }
    e.Flux = flux
    local ns = { Flux = flux }
    local function owner(path) return assert(load(read(overrides[path] or path), "@" .. path, "t", e))("_FluxUI", ns) end
    for _, path in ipairs({ "Core/Hotkey.lua", "ExtraButtonSystem/Shared/HotkeyUtil.lua", "Bars/Paint.lua",
        "ExtraButtonSystem/Engine/Paint.lua", "ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua",
        "ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua" }) do owner(path) end
    function f.button(name)
        local w, fs = widget(name), font()
        w.HotKey = fs
        local icon = { writes = 0 }
        function icon:SetVertexColor(r, g, b) self.color = { r, g, b }; self.writes = self.writes + 1 end
        function icon:SetDesaturated() end
        function icon:SetTexture() error("range hotkey refresh replaced action artwork") end
        local count = { GetText = function() return "3" end, SetText = function() error("range hotkey refresh changed count text") end }
        return { Widget = w, widget = w, WHotKey = fs, WIcon = icon, WCount = count, ActionType = "spell", SpellId = 201,
            ActionValue = 201, row = "main", slot = 1, bindingCommand = "ACTIONBUTTON1" }
    end
    f.e, f.flux, f.h, f.util, f.font = e, flux, flux.Hotkey, e.FluxNCHotkeyUtil, font
    return f
end
local sizes = { MouseButton3 = {32,80}, MouseButton4 = {32,80}, MouseButton5 = {32,80}, MouseScrollUp = {8,20}, MouseScrollDown = {8,20}, SpaceBarButton = {48,48} }
local function glyph(text)
    local inside = text:match("|T([^|]+)|t")
    if not inside then return nil end
    local parts = {}; for part in (inside .. ":"):gmatch("(.-):") do parts[#parts + 1] = part end
    return parts
end
local function redGlyph(fs, why)
    local parts = glyph(fs.text)
    check(parts and #parts == 14, why .. ": inline glyph has explicit RGB fields")
    check(tonumber(parts[12]) == 255 and tonumber(parts[13]) == 26 and tonumber(parts[14]) == 26, why .. ": white artwork uses red vertex tint")
    local token = parts[1]:match("([^\\/]+)%.tga$")
    local dimension = sizes[token]
    check(dimension and tonumber(parts[6]) == dimension[1] and tonumber(parts[7]) == dimension[2]
        and tonumber(parts[8]) == 0 and tonumber(parts[9]) == dimension[1]
        and tonumber(parts[10]) == 0 and tonumber(parts[11]) == dimension[2], why .. ": full original texture crop is preserved")
    check(fs.color[1] == 1 and fs.color[2] == .1 and fs.color[3] == .1, why .. ": ordinary glyph text shares red feedback")
end
local function normal(fs, original, why)
    check(fs.text == original, why .. ": original markup/text returns byte for byte")
    check(fs.color[1] == .75 and fs.color[2] == .75 and fs.color[3] == .75, why .. ": original font gray returns")
    local parts = glyph(fs.text)
    if parts then check(#parts == 5, why .. ": neutral artwork keeps original untinted short markup") end
end

for _, key in ipairs({ "Q", "NUMPAD3", "BUTTON3", "BUTTON4", "BUTTON5", "MOUSEWHEELUP", "MOUSEWHEELDOWN", "SPACE",
    "ALT-BUTTON5", "CTRL-MOUSEWHEELUP", "SHIFT-SPACE", "ALT-Q" }) do
    for _, surface in ipairs({ "bars", "combat", "utility", "trinket" }) do
        local f = fixture()
        local b = f.button("Hotkey" .. surface)
        local render, range
        if surface == "bars" then
            f.binding.ACTIONBUTTON1 = key
            render = function() f.flux.Bars.Paint.UpdateHotkey(b) end
            range = function() f.flux.Bars.Paint.UpdateRange(b) end
        elseif surface == "utility" then
            b.slotIndex, b.SlotData = 1, { [""] = {}, SHIFT = {} }
            b.ActionType, b.MacroMode, b._fluxUtilityGetEntry = "macrotext", "spell", true
            f.binding.FLUXSPELLBOOKSLOT1 = key
            render = function() f.e.FluxNCUtilitySlotsManager.UpdateHotkeys(b) end
            range = function() f.flux.EBS.Paint.UpdateRange(b) end
        elseif surface == "trinket" then
            b.ActionType, b.ItemId = "item", 900001
            local tm = f.e.FluxTrinketMenu
            tm.Buttons, tm.VisibilityState = { [0] = b, [1] = f.button("OtherTrinket") }, "one_equipped"
            tm.SyncKeybindPushWatch = function() end
            f.binding.FLUXTRINKET2 = key -- First binding absent: use the existing multiple-label fallback.
            render = function() tm.UpdateKeybindings(true) end
            range = function() f.flux.EBS.Paint.UpdateRange(b) end
        else
            b.IsHealthstoneButton = true
            f.binding.FLUXCOMBAT_HEALTHSTONE = key
            render = function() f.util.UpdateHotkeyText(b, "FLUXCOMBAT_HEALTHSTONE") end
            range = function() f.flux.EBS.Paint.UpdateRange(b) end
        end
        render(); local initial = b.WHotKey.text
        check(initial ~= "" and b.WHotKey.shown, surface .. " renders assigned hotkey")
        local initialGlyph = glyph(initial)
        if initialGlyph then check(tonumber(initialGlyph[2]) == (surface == "trinket" and 17 or 14), surface .. " retains native consumer icon size") end
        f.range = false; range()
        check(f.h.IsOutOfRange(b.WHotKey), surface .. " existing range owner publishes OOR")
        if initialGlyph then
            redGlyph(b.WHotKey, surface .. "/" .. key)
            check(b.WHotKey.text:match("^(.-)|T") == initial:match("^(.-)|T"), surface .. " glyph tint preserves binding modifier prefix")
        else check(b.WHotKey.text == initial and b.WHotKey.color[1] == 1 and b.WHotKey.color[2] == .1, surface .. " ordinary key text retains content and becomes red") end
        local writes = b.WHotKey.writes
        for _ = 1, 30 do range() end
        check(b.WHotKey.writes == writes, surface .. " unchanged range probes do not rebuild hotkey markup")
        render() -- FullRefresh/binding repaint while still OOR must retain tint.
        if initialGlyph then redGlyph(b.WHotKey, surface .. " repaint") end
        if surface ~= "bars" then
            b.WHotKey = f.font(); b.Widget.HotKey = b.WHotKey
            render(); range()
            if initialGlyph then redGlyph(b.WHotKey, surface .. " new font while OOR") end
        end
        f.range = true; range(); normal(b.WHotKey, initial, surface .. " range recovery")
        f.usable, f.noMana = false, true
        if surface == "bars" then f.flux.Bars.Paint.UpdateUsable(b) else f.flux.EBS.Paint.UpdateUsable(b) end
        normal(b.WHotKey, initial, surface .. " mana/unusable does not trigger range red")
        f.usable, f.noMana, f.exists, f.range = true, false, true, false
        range()
        f.exists = false; range(); normal(b.WHotKey, initial, surface .. " losing the target clears prior red")
    end
end

do
    local f = fixture(); local b = f.button("TrinketRangeHold")
    b.ActionType, b.ItemId = "item", 900001
    f.binding.TRINKET_HOLD = "BUTTON3"
    f.util.UpdateHotkeyText(b, "TRINKET_HOLD", nil, nil, 17)
    local initial = b.WHotKey.text
    f.range = false; f.flux.EBS.Paint.UpdateRange(b)
    redGlyph(b.WHotKey, "known item OOR")
    f.range, f.keep = nil, true
    f.flux.EBS.Paint.UpdateRange(b)
    redGlyph(b.WHotKey, "restricted same-item range retains prior public state")
    f.revision = f.revision + 1
    f.flux.EBS.Paint.UpdateRange(b)
    normal(b.WHotKey, initial, "changed target revision does not retain old item red")
end

-- The bar's modifier prefix is a separate FontString beside its TGA glyph.
do
    local f = fixture(); local b = f.button("ModifierGlyph")
    f.binding.ACTIONBUTTON1, f.shift = "BUTTON4", true
    f.flux.Bars.Paint.UpdateHotkey(b)
    local overlay = assert(b.widget._fluxHotkeyMod)
    check(overlay.text == "S-" and overlay.shown, "existing separate bar modifier overlay remains visible")
    local initial = b.WHotKey.text
    f.range = false; f.flux.Bars.Paint.UpdateRange(b)
    redGlyph(b.WHotKey, "bar modifier glyph")
    check(overlay.color[1] == 1 and overlay.color[2] == .1, "bar modifier overlay shares the hotkey range state")
    f.range = true; f.flux.Bars.Paint.UpdateRange(b)
    normal(b.WHotKey, initial, "bar modifier recovery")
    check(overlay.text == "S-" and overlay.color[1] == .75, "modifier text and normal color recover without layout changes")
end

-- Creating the prefix or re-preparing its geometry while already red must not
-- reset the range state; clearing the label must retire its logical text too.
do
    local f = fixture(); local b = f.button("LateModifierGlyph")
    f.binding.ACTIONBUTTON1 = "BUTTON5"
    f.flux.Bars.Paint.UpdateHotkey(b)
    f.range = false; f.flux.Bars.Paint.UpdateRange(b)
    check(b.widget._fluxHotkeyMod == nil, "bare icon starts without a modifier overlay")
    f.ctrl = true; f.flux.Bars.Paint.UpdateHotkey(b)
    local overlay = assert(b.widget._fluxHotkeyMod)
    redGlyph(b.WHotKey, "late-created modifier")
    check(overlay.text == "C-" and overlay.color[1] == 1 and overlay.color[2] == .1,
        "modifier overlay created during OOR starts red")
    b.widget.GetWidth = function() return 33 end
    f.flux.Bars.Paint.UpdateHotkey(b)
    redGlyph(b.WHotKey, "red squeeze refresh")
    check(tonumber(glyph(b.WHotKey.text)[3]) == 11, "squeeze refresh preserves the rounded glyph width")
    f.binding.ACTIONBUTTON1 = nil; f.flux.Bars.Paint.UpdateHotkey(b)
    f.flux.Bars.Paint.UpdateRange(b)
    check(b.WHotKey.text == "" and not b.WHotKey.shown and not overlay.shown,
        "unbind while red cannot resurrect the previous icon or prefix")
    f.binding.ACTIONBUTTON1 = "SPACE"; f.flux.Bars.Paint.UpdateHotkey(b)
    redGlyph(b.WHotKey, "replacement binding while OOR")
    check(glyph(b.WHotKey.text)[1]:find("SpaceBarButton.tga", 1, true), "replacement binding replaces the logical glyph asset")
end

-- These existing EBS early exits clear only the hotkey range presentation.
-- Refreshing the retained binding label must not revive a stale red flag.
for _, kind in ipairs({ "empty", "placeholder", "ignore" }) do
    local f = fixture(); local b = f.button("EarlyExit" .. kind)
    f.binding.TEST_EARLY = "BUTTON4"
    f.util.UpdateHotkeyText(b, "TEST_EARLY")
    local initial = b.WHotKey.text
    f.range = false; f.flux.EBS.Paint.UpdateRange(b)
    redGlyph(b.WHotKey, kind .. " before early exit")
    if kind == "empty" then b.ActionType, b.ActionValue = nil, nil
    elseif kind == "placeholder" then b.PlaceholderTexture = 134400
    else b.IgnoreUsabilityVisual = true end
    b.WIcon = nil -- The hotkey branch runs before the unrelated icon renderer.
    f.flux.EBS.Paint.UpdateUsable(b)
    normal(b.WHotKey, initial, kind .. " early exit")
    f.util.UpdateHotkeyText(b, "TEST_EARLY")
    normal(b.WHotKey, initial, kind .. " subsequent binding repaint")
end

do
    local f = fixture(); local b = f.button("FullRefreshUnbound")
    f.binding.FULL_REFRESH_KEY = "BUTTON4"
    f.util.UpdateHotkeyText(b, "FULL_REFRESH_KEY")
    f.range = false; f.flux.EBS.Paint.UpdateRange(b)
    local source = read("ExtraButtonSystem/Engine/Button.lua")
    local first = assert(source:find("function FluxButton:UpdateButtonText()", 1, true))
    local last = assert(source:find("\nend", first, true)) + 3
    assert(load(source:sub(first, last), "@actual EBS UpdateButtonText", "t", f.e))()
    local countUpdates = 0
    b.UpdateTextCount = function() countUpdates = countUpdates + 1 end
    b.HotkeyBinding = nil
    f.e.FluxButton.UpdateButtonText(b)
    f.util.SetRange(b, false); f.util.SetRange(b, true)
    check(b.WHotKey.text == "" and not b.WHotKey.shown, "unbound EBS FullRefresh retires old logical glyph across later range changes")
    check(countUpdates == 1 and b.WCount:GetText() == "3", "FullRefresh retains the existing separate count owner")
end

-- Old/partial HotkeyUtil capability: these two real callers fall back to raw
-- key text while Core.Hotkey still owns color and logical-text restoration.
for _, surface in ipairs({ "trinket", "utility" }) do
    for _, state in ipairs({ "active", "empty", "placeholder", "ignore", "unbound" }) do
        local f = fixture(); local b = f.button("Fallback" .. surface .. state)
        f.util.UpdateHotkeyText = nil
        local command, render
        if surface == "trinket" then
            command = "FLUXTRINKET1"
            local tm = f.e.FluxTrinketMenu
            tm.Buttons, tm.VisibilityState = { [0] = b, [1] = f.button("FallbackOtherTrinket") }, "both_equipped"
            tm.SyncKeybindPushWatch = function() end
            render = function() tm.UpdateKeybindings(true) end
        else
            command, b.slotIndex = "FLUXSPELLBOOKSLOT1", 1
            render = function() f.e.FluxNCUtilitySlotsManager.UpdateHotkeys(b) end
        end
        f.binding[command] = "BUTTON4"
        render()
        check(b.WHotKey.text == "BUTTON4", surface .. " fallback preserves its existing raw-key text path")
        f.range = false; f.flux.EBS.Paint.UpdateRange(b); render()
        check(f.h.IsOutOfRange(b.WHotKey) and b.WHotKey.color[1] == 1,
            surface .. " fallback keeps a genuine active out-of-range label red")
        if state == "active" then f.range = true; f.flux.EBS.Paint.UpdateRange(b)
        elseif state == "empty" then b.ActionType, b.ActionValue = nil, nil
        elseif state == "placeholder" then b.PlaceholderTexture = 134400
        elseif state == "ignore" then b.IgnoreUsabilityVisual = true
        else f.binding[command] = nil end
        if state ~= "active" and state ~= "unbound" then
            b.WIcon = nil
            f.flux.EBS.Paint.UpdateUsable(b)
            check(b._outOfRange == true, "fallback presentation leaves the prior action's range cache alone")
        end
        render()
        check(not f.h.IsOutOfRange(b.WHotKey), surface .. "/" .. state .. " fallback does not revive stale red")
        if state == "unbound" then
            check(b.WHotKey.text == "" and not b.WHotKey.shown, surface .. " fallback unbind retires the old logical text")
        else normal(b.WHotKey, "BUTTON4", surface .. "/" .. state .. " fallback recovery") end
    end
end
print(("Hotkey range glyphs: %d checks PASS; four actual consumers; native GPU tint pending"):format(checks))
