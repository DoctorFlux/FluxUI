-- Entire installed/source-pinned SecureTemplates.lua, including native OnClick,
-- unit conversion, phase gates and SECURE_ACTIONS macro/click/action handlers.
-- C frame lookup, registration and hardware delivery remain modeled. Capturing
-- C_Macro.RunMacroText proves the selected program, not actual native casting
-- or which conditional branch the native macro parser chooses.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s:gsub("\r\n", "\n")
end
local nativePath = "../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua"
for i, flag in ipairs(arg or {}) do if flag == "--native" then nativePath = arg[i + 1] end end
local native = read(nativePath)
local shared = read("tests/shared_binding_modifiers.lua")
shared = shared:sub(1, assert(shared:find("-- Real host traversal matters", 1, true)) - 1)
shared = shared:gsub("return e, bars, state, compile, effective, applySecure", "return e, bars, state, compile, effective, applySecure, flux")
local boot = assert(load(shared .. "\nreturn fixture", "@shared bar owners", "t", _G))()
local checks = 0
local function check(ok, message) checks = checks + 1; assert(ok, message) end
local function held(mask)
    return { alt = mask % 2 == 1, ctrl = math.floor(mask / 2) % 2 == 1, shift = mask >= 4 }
end
local function fixture(shape)
    local e, bars, state, _, _, applySecure, flux = boot()
    local methods = getmetatable(bars.hosts[1].main.widget).__index
    -- Model C Frame:GetAttribute's modified lookup. The eight prepared exact
    -- prefixes win before wildcard/bare fallback; actual Lua inheritance comes
    -- from the installed SecureTemplates.lua loaded below.
    function methods:GetAttribute(prefix, name, suffix)
        if not name then return self.attrs[prefix] end
        for _, key in ipairs({ prefix .. name .. suffix, "*" .. name .. suffix,
            prefix .. name .. "*", "*" .. name .. "*", prefix .. name, name .. suffix, name .. "*", name }) do
            if self.attrs[key] ~= nil then return self.attrs[key] end
        end
    end
    e.CopyTable = function(t) local copy = {}; for k, v in pairs(t) do copy[k] = v end; return copy end
    e.GetFrameMetatable = function() return { __index = methods } end
    e.C_PaperDollInfo = { GetInventorySlotInfo = function() return 16 end, IsRangedSlotShown = function() return false end }
    e.GetInventorySlotInfo = e.C_PaperDollInfo.GetInventorySlotInfo
    e.UnitExists = function(unit) return unit == "player" end
    e.UnitHasVehicleUI = function() return false end
    e.UnitCanAssist, e.UnitCanAttack = function() return false end, function() return false end
    e.IsModifiedClick = function() return false end
    e.GetModifiedClick = function() return "NONE" end
    e.SpellCanTargetItem, e.SpellCanTargetItemID = function() return false end, function() return false end
    e.GetCursorInfo = function() end
    e.securecallfunction = function(fn, ...) return fn(...) end
    e.forceinsecure = function() error("unexpected insecure action handler") end
    e.SpellFlyout = { Hide = function() end }
    e.Enum = { ForbiddenAspect = { ScriptedInput = 1 } }
    e.C_ActionBar = { GetActionBarPage = function() return 1 end }
    e.NUM_ACTIONBAR_BUTTONS = 12
    e.calls, e.phase = {}, {}
    e.C_Macro = { RunMacroText = function(body, button) e.calls[#e.calls + 1] = { kind = "macro", body = body, button = button } end }
    e.RunMacro = function(index) e.calls[#e.calls + 1] = { kind = "stored-macro", index = index } end
    e.UseAction = function(slot, unit, button) e.calls[#e.calls + 1] = { kind = "action", slot = slot, unit = unit, button = button } end
    assert(load(native, "@" .. nativePath, "t", e))()
    methods.CalculateAction = e.SecureActionButtonMixin.CalculateAction
    function methods:HasAccessConstraints() return false end
    function methods:HasAnyForbiddenAspects() return false end
    function methods:Click(button, down)
        local allowed = false
        for _, registration in ipairs(self.clicks or {}) do
            if registration == (down and "AnyDown" or "AnyUp") or registration == button .. (down and "Down" or "Up") then allowed = true end
        end
        if not allowed then return false end
        local physical = e.held
        -- The physical native trace showed an empty modifier prefix inside
        -- key dispatch although the secure main had already paged to Shift.
        -- Clear only the dispatch-time globals, after state/visual updates.
        if e.consumeModifiers then e.held = {} end
        e.phase[#e.phase + 1] = { frame = self:GetName(), button = button, down = down,
            prefix = e.SecureButton_GetModifierPrefix(self) }
        local ok, result = pcall(e.SecureActionButton_OnClick, self, button, down)
        e.held = physical
        assert(ok, result)
        return result
    end
    local ns = { Flux = flux }
    assert(loadfile("Binding/Core/SecurePool.lua", "t", e))("_FluxUI", ns)
    assert(loadfile("Bars/SlotProgram.lua", "t", e))("_FluxUI", ns)
    e.overrides = {}
    e.GetBindingAction = function() return "" end
    e.SetOverrideBindingClick = function(_, _, key, target, button) e.overrides[key] = { target, button } end
    e.ClearOverrideBindings = function() e.overrides = {} end
    bars.Clicks.InvalidateKeys(); check(bars.Clicks.RefreshKeys(), "actual Clicks installs key-down routes")
    state.ApplySlotsInsecure()
    local bodies = {}
    for _, slot in ipairs({ 1, 61, 25 }) do
        local text = slot == 61 and "/cast [mod:ctrl,mod:shift] FireWard; FrostWard"
            or slot == 25 and "/cast [mod:alt] AltCtrlPeer; CtrlSpell" or "/cast [mod:alt] AltMainPeer; MainSpell"
        if shape ~= "native" then
            bodies[slot] = text
            bars.SlotProgram.Apply(slot, text, shape)
        end
    end
    state.ApplySlotsInsecure()
    local keyer = e.FluxActionStripKey1
    check(keyer.clicks[1] == "AnyDown" and #keyer.clicks == 1, "actual key proxy listens to down only")
    check(keyer.attrs.useOnKeyDown == true and keyer.attrs.pressAndHoldAction == false, "actual key proxy phase policy is intact")
    for _, key in ipairs({ "Q", "SHIFT-Q", "CTRL-Q" }) do
        local route = e.overrides[key]
        check(route and route[1] == keyer:GetName() and route[2] == "LeftButton", "actual explicit route targets same main key proxy: " .. key)
    end
    return e, bars, state, bodies, applySecure
end

for _, shape in ipairs({ "native", "surface", "hidden" }) do
for _, transport in ipairs({ "fallback-ooc", "live-child" }) do
for _, consumed in ipairs({ false, true }) do
    local e, bars, state, bodies, applySecure = fixture(shape)
    e.consumeModifiers = consumed
    for mask = 0, 7 do
        e.held = held(mask)
        local swap = e.held.shift and 1 or e.held.ctrl and 2 or 0
        if transport == "live-child" then
            e.combat = true
            state.IndexLiveSlots()
            bars.ForEachHost(function(host) applySecure(host.widget, 1, swap) end)
        else
            e.combat = false
            state.ApplySlotsInsecure()
            e.combat = true
        end
        local main = bars.hosts[1].main
        local expected = swap == 1 and 61 or swap == 2 and 25 or 1
        check(main.slot == expected, shape .. "/" .. transport .. ": currently shown main is the selected slot")
        local keyer = e.FluxActionStripKey1
        e.calls, e.phase = {}, {}
        check(keyer:Click("LeftButton", true) == true, "installed native gate accepts the real keyer down phase")
        check(#e.calls == 1, shape .. "/" .. transport .. ": one key-down executes exactly one native handler")
        local call = e.calls[1]
        check(e.phase[1].prefix == (consumed and "" or e.SecureButton_GetModifierPrefix(keyer)),
            "consumption changes dispatch globals only, after the main's secure program is selected")
        check(call.button == "LeftButton", "native handler receives the configured physical click button")
        if shape == "native" then
            check(call.kind == "action" and call.slot == main.slot, "native UseAction casts the currently shown main, without double paging")
        else
            check(call.kind == "macro" and call.body == bodies[main.slot],
                "native RunMacroText executes the currently shown main program, including its conditional peer clauses")
        end
        if shape == "hidden" then
            local phase = e.phase[2]
            check(#e.phase == 2 and phase.frame == "FluxSlotClick_" .. expected and phase.down == nil,
                "native click handler delegates once with omitted down, then native hold-release runs macro")
        else check(#e.phase == 1, "surface/native input stays on one keyer") end
        check(keyer:Click("LeftButton", false) == false and #e.calls == 1, "unregistered release neither double-casts nor remaps the main")
    end
    -- Negative gates distinguish routed/consumed input from actual execution.
    local keyer = e.FluxActionStripKey1
    e.held, e.calls = { shift = true }, {}
    check(e.SecureActionButton_OnClick(keyer, "LeftButton", true, false, true) == false and #e.calls == 0,
        "a secure-mouse classification would reject down: native input classification remains a hardware acceptance boundary")
    keyer.attrs.unit = "focus"
    check(e.SecureActionButton_OnClick(keyer, "LeftButton", true) == true and #e.calls == 0,
        "missing unit can consume the down gate without reaching a macro/action handler")
    keyer.attrs.unit = nil
    e.combat = false
end
end
end
print(("Native bar click route: %d checks PASS; full native OnClick/handlers from %s; C frame/hardware arbitration and actual casts remain unverified")
    :format(checks, nativePath))
