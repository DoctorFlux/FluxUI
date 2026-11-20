-- Production plain-target resolver against source-pinned native unit selection
-- and production PreClick targeting. C frame lookup, API results and hardware
-- modifiers are models; this does not certify native casting or taint safety.
local function read(path)
    local file = assert(io.open(path, "rb")); local body = file:read("*a"); file:close()
    return body:gsub("\r\n", "\n")
end
local sourcePath = "Core/Engine/MouseoverCast.lua"
local nativePath = "../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua"
for i, flag in ipairs(arg or {}) do
    if flag == "--source" then sourcePath = arg[i + 1] end
    if flag == "--native" then nativePath = arg[i + 1] end
end
local source, native = read(sourcePath), read(nativePath)
local nativeStart = assert(native:find("function SecureButton_GetModifierPrefix", 1, true))
local nativeEnd = assert(native:find("function SecureButton_GetUnit(self)", nativeStart, true))
local nativeUnits = native:sub(nativeStart, nativeEnd - 1)
local pre = assert(source:match("local UNIT_PRECLICK = %[%[(.-)%]%]"))
local checks = 0
local function check(ok, message) checks = checks + 1; assert(ok, message) end
local classes = { [101] = { false, true }, [102] = { true, false },
    [103] = { false, false }, [104] = { true, true } }

local function fixture(nativeClient)
    local f = { native = nativeClient, enabled = true, modifier = "NONE", mask = 0,
        mods = {}, friendly = true, exists = true, now = 1, spellCalls = 0, actionCalls = 0,
        spell = 101, slot = 1, unknown = false, secret = {}, writes = 0 }
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.GetTime = function() return f.now end
    e.UnitExists = function(unit) return unit ~= "mouseover" or f.exists end
    e.UnitIsFriend = function() return f.friendly end
    e.GetCVar = function() return f.enabled and "1" or "0" end
    e.GetCVarBool = function() return f.enabled end
    e.IsMouseoverCastSupported = function() return f.native end
    e.GetModifiedClick = function() return f.modifier end
    e.IsModifiedClick = function(name) return f.mods[name] == true end
    e.IsShiftKeyDown = function() return f.mask >= 4 end
    e.IsControlKeyDown = function() return math.floor(f.mask / 2) % 2 == 1 end
    e.IsAltKeyDown = function() return f.mask % 2 == 1 end
    e.SpellIsTargeting = function() return false end
    e.SecureCmdOptionParse = function(condition)
        if not f.exists then return nil end
        if condition:find(",help", 1, true) and not f.friendly then return nil end
        if condition:find(",harm", 1, true) and f.friendly then return nil end
        return "mouseover"
    end
    local function classify(id, helpful)
        f.spellCalls = f.spellCalls + 1
        local class = classes[id]
        return class and class[helpful and 1 or 2]
    end
    e.C_Spell = { IsSpellHelpful = function(id) return classify(id, true) end,
        IsSpellHarmful = function(id) return classify(id, false) end }
    e.IsSpellHelpful, e.IsSpellHarmful = e.C_Spell.IsSpellHelpful, e.C_Spell.IsSpellHarmful
    e.C_Item = { IsHelpfulItem = e.C_Spell.IsSpellHelpful, IsHarmfulItem = e.C_Spell.IsSpellHarmful }
    e.IsHelpfulItem, e.IsHarmfulItem = e.C_Item.IsHelpfulItem, e.C_Item.IsHarmfulItem
    e.C_ActionBar = {}
    local function actionClass(slot, neutral, helpful)
        f.actionCalls = f.actionCalls + 1
        check(slot == f.slot and neutral == true, "native slot classifier uses current slot and includeNeutral=true")
        if f.classError then error("restricted classifier") end
        if f.secretClass then return f.secret end
        if f.unknown then return nil end
        local class = classes[f.spell]
        -- The native neutral contract intentionally differs from a standalone
        -- unclassified/neutral spell's exists gate.
        if f.spell == 103 then return neutral and f.neutralAction == true end
        return class and class[helpful and 1 or 2]
    end
    e.C_ActionBar.IsHelpfulAction = function(slot, neutral) return actionClass(slot, neutral, true) end
    e.C_ActionBar.IsHarmfulAction = function(slot, neutral) return actionClass(slot, neutral, false) end
    e.GetActionInfo = function(slot) check(slot == f.slot, "legacy lookup uses live slot"); return "spell", f.spell end
    local flux = { Cap = { hasRestrictedClosures = true },
        Secrets = { IsSecretValue = function(value) return value == f.secret end } }
    e.FluxOptions = { GetActionbarsDB = function() return { mouseoverCast = f.enabled } end }
    assert(load(source, "@" .. sourcePath, "t", e))("_FluxUI", { Flux = flux })
    f.mc = flux.MouseoverCast
    check(type(f.mc.RangeUnit) == "function", "production plain target helper exists")
    local methods = {}
    function methods:GetAttribute(prefix, name, suffix)
        if not name then return self.attrs[prefix] end
        for _, key in ipairs({ prefix .. name .. suffix, "*" .. name .. suffix,
            prefix .. name .. "*", "*" .. name .. "*", prefix .. name, name .. suffix, name .. "*", name }) do
            if self.attrs[key] ~= nil then return self.attrs[key] end
        end
    end
    function methods:SetAttribute(name, value) self.attrs[name] = value; f.writes = f.writes + 1 end
    function methods:CalculateAction() return f.slot end
    function methods:GetParent() return self.parent end
    local prelude = "local LOCAL_CHECK_Frame = ...; local strsplit = strsplit; "
    assert(load(prelude .. nativeUnits, "@native targeting helpers", "t", e))(methods)
    f.click = assert(load("return function(self, button)\n" .. pre .. "\nend", "@production UNIT_PRECLICK", "t", e))()
    function f.widget(kind)
        return setmetatable({ attrs = { type = kind or "action", action = f.slot,
            ["flux-mo-spell"] = f.spell, ["flux-mo-item"] = f.spell,
            ["flux-mo-native-modifier"] = f.native and f.modifier or nil,
            checkmouseovercast = f.native and kind == nil or false,
            ["flux-smart"] = kind and 3 or nil, smarttarget = not f.native and true or nil } }, { __index = methods })
    end
    f.env = e
    return f
end

for _, enabled in ipairs({ false, true }) do
for _, modifier in ipairs({ "NONE", "SHIFT" }) do
for _, held in ipairs({ false, true }) do
for _, friendly in ipairs({ false, true }) do
for _, spell in ipairs({ 101, 102, 103, 104 }) do
for mask = 0, 7 do
    local f = fixture(true)
    f.enabled, f.modifier, f.mods.MOUSEOVERCAST = enabled, modifier, held
    f.friendly, f.spell, f.mask = friendly, spell, mask
    f.neutralAction = mask % 2 == 1
    local widget = f.widget()
    local expected = f.env.SecureButton_GetModifiedUnit(widget, "LeftButton")
    local actual = f.mc.RangeUnit(widget, "action", f.slot)
    check(actual == expected, "native plain action matches installed source target under every modifier mask")
    check(f.writes == 0, "range helper never changes protected attributes")
    widget.attrs.checkmouseovercast = false
    check(f.mc.RangeUnit(widget, "action", f.slot) == nil, "disabled native button does not invent hover casting")
end end end end end end

for _, nativeClient in ipairs({ false, true }) do
for _, kind in ipairs({ "spell", "item", "action" }) do
if not (nativeClient and kind == "action") then
for _, friendly in ipairs({ false, true }) do
for _, spell in ipairs({ 101, 102, 103, 104, 999 }) do
for mask = 0, 7 do
    local f = fixture(nativeClient)
    f.friendly, f.spell, f.mask = friendly, spell, mask
    local widget = f.widget(kind)
    local argument = kind == "action" and f.slot or spell
    local actual = f.mc.RangeUnit(widget, kind, argument)
    check(f.writes == 0, "standalone helper is read-only")
    f.click(widget, "LeftButton")
    local expected = widget.attrs.unit == "mouseover" and "mouseover" or nil
    check(actual == expected, "standalone/legacy range chooses production PreClick target")
    widget.attrs.unit = nil
    local calls = f.spellCalls
    f.mc.RangeUnit(widget, kind, argument)
    check(f.spellCalls == calls, "same-frame consecutive range requests reuse immutable identity classification")
end end end
end end end

do
    local f = fixture(true)
    local widget = f.widget()
    f.enabled = false; f.mods.SELFCAST = true; f.mods.FOCUSCAST = true
    widget.attrs.checkselfcast, widget.attrs.checkfocuscast = true, true
    check(f.mc.RangeUnit(widget, "action", 1) == "player", "selfcast precedes focus when mouseover is inactive")
    widget.attrs["shift-checkselfcast1"] = false; f.mask = 4
    check(f.mc.RangeUnit(widget, "action", 1) == "focus", "exact modified selfcast authorization can disable bare flag")
    widget.attrs["shift-checkfocuscast1"] = ""
    check(f.mc.RangeUnit(widget, "action", 1) == nil, "native no-op flag suppresses focus override")
    widget.attrs["shift-checkselfcast1"], widget.attrs["shift-checkfocuscast1"] = nil, nil
    f.enabled, f.spell, f.friendly = true, 102, true
    check(f.mc.RangeUnit(widget, "action", 1) == "mouseover", "eligible mouseover precedes self/focus modifiers")
    f.exists = false
    check(f.mc.RangeUnit(widget, "action", 1) == "player", "absent mouseover permits selfcast fallback")
    widget.attrs.checkselfcast, widget.attrs.checkfocuscast = nil, nil
    check(f.mc.RangeUnit(widget, "action", 1) == nil, "modifiers do not invent unauthorized self/focus targeting")
    f.exists = true; f.unknown = true
    check(f.mc.RangeUnit(widget, "action", 1) == nil, "unknown native action classification keeps selected target")
    f.unknown, f.classError = false, true
    check(f.mc.RangeUnit(widget, "action", 1) == nil, "restricted native action classifier keeps selected target")
    f.classError, f.secretClass = false, true
    check(f.mc.RangeUnit(widget, "action", 1) == nil, "secret native classification cannot become invented hover")
    f.secretClass = false
    check(f.mc.RangeUnit(widget, "action", f.secret) == nil, "secret action identifier is not inspected")
    local adapter = f.widget("spell")
    adapter.attrs["flux-smart"] = nil
    check(f.mc.RangeUnit(adapter, "spell", 102) == nil, "unconfigured standalone button does not invent a cast adapter")
end

print("PASS " .. checks .. " plain cast range target checks (native C APIs/frame lookup modeled)")
