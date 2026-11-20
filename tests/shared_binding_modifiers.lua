-- Actual bar owners + macro compiler and native modified-attribute helper.
-- Frame transport and macro selection are modeled; no native casting/taint claim.
local checks = 0
local function check(ok, message) checks = checks + 1; assert(ok, message) end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return s:gsub("\r\n", "\n")
end
local replacements = {}
local selectedShape
for i, flag in ipairs(arg or {}) do
    if flag == "--state" then replacements["Bars/State.lua"] = arg[i + 1] end
    if flag == "--clicks" then replacements["Bars/Clicks.lua"] = arg[i + 1] end
    if flag == "--shape" then selectedShape = arg[i + 1] end
end
local native = read("../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua")
local function nativeFunction(signature, declaration, env)
    local a = assert(native:find(signature, 1, true))
    local b = assert(native:find("\nend", a, true)) + 3
    return assert(load(declaration .. native:sub(a + #signature, b), "native modified attributes", "t", env))()
end
local function fixture()
    local e = setmetatable({ UIParent = {}, SlashCmdList = {}, ATTRIBUTE_NOOP = "", held = {} }, { __index = _G })
    e._G = e
    e.InCombatLockdown = function() return e.combat end
    e.IsShiftKeyDown = function() return e.held.shift end
    e.IsControlKeyDown = function() return e.held.ctrl end
    e.IsAltKeyDown = function() return e.held.alt end
    e.GetCVarBool = function() return false end
    e.GetBindingKey = function(command) return command == "ACTIONBUTTON1" and "Q" or command == "ACTIONBUTTON11" and "F" or nil end
    e.SetOverrideBindingClick = function(_, _, key, target, button) e.bound = { key, target, button } end
    e.ClearOverrideBindings = function() end
    e.UnitClass = function() return "Priest", "PRIEST" end
    e.GetSpellInfo = function(id) return "Spell" .. id, nil, id end
    e.GetActionInfo = function(slot) return "spell", slot end
    e.IsPressHoldReleaseSpell = function() return false end
    local flux = { Client = { isForever = true, isCamelot = true }, Module = { Register = function() end } }
    flux.Combat = { InLockdown = e.InCombatLockdown }
    flux.ButtonFX = { Click = { UsesWrap = function() return false end } }
    local ns = { Flux = flux, FluxBindingConditions = { MacroTokensForSub = function() return { "mod:alt" } end } }
    local methods = {}
    function methods:GetAttribute(prefix, name, suffix)
        if name then
            -- C frame attribute lookup, before the native Lua helper attempts
            -- useparent recursion. A child's bare selector wins before parent.
            return self.attrs[prefix .. name .. suffix] or self.attrs["*" .. name .. suffix]
                or self.attrs[prefix .. name .. "*"] or self.attrs["*" .. name .. "*"] or self.attrs[name]
        end
        return self.attrs[prefix]
    end
    function methods:SetAttribute(k, v)
        assert(not e.combat or e.secure, "ordinary protected attribute writes in combat")
        self.attrs[k] = v
    end
    function methods:GetParent() return self.parent end
    function methods:SetParent(p) assert(not e.combat, "parent write in combat"); self.parent = p end
    function methods:GetName() return self.name end
    function methods:SetID(id) self.id = id end
    function methods:GetID() return self.id or 0 end
    function methods:RegisterForClicks(...) self.clicks = { ... } end
    function methods:Hide() end
    function methods:SetSize() end
    function methods:EnableMouse() end
    function methods:HookScript() end
    function methods:SetScript() end
    function methods:RegisterEvent() end
    function methods:SetFrameRef(name, value) self.refs = self.refs or {}; self.refs[name] = value end
    function methods:GetFrameRef(name) return self.refs and self.refs[name] end
    local function frame(name, parent)
        local f = setmetatable({ name = name, parent = parent, attrs = {} }, { __index = methods })
        if name then e[name] = f end
        return f
    end
    e.CreateFrame = function(_, name, parent) return frame(name, parent) end
    e.LOCAL_CHECK_Frame = { GetAttribute = methods.GetAttribute, GetParent = methods.GetParent }
    e.SecureButton_GetModifierPrefix = function()
        return (e.held.alt and "alt-" or "") .. (e.held.ctrl and "ctrl-" or "") .. (e.held.shift and "shift-" or "")
    end
    e.SecureButton_GetButtonSuffix = function(button) return button == "LeftButton" and "1" or "-" .. button end
    e.SecureButton_GetModifiedAttribute = nativeFunction(
        "function SecureButton_GetModifiedAttribute(frame, name, button, prefix, suffix)",
        "return function(frame, name, button, prefix, suffix)", e)
    flux.Restricted = { PagingWorks = function() return true end }
    local function owner(path) return assert(load(read(replacements[path] or path), "@" .. path, "t", e))("_FluxUI", ns) end
    for _, path in ipairs({ "Bars/Init.lua", "Bars/SlotMath.lua", "Bars/State.lua", "Bars/Clicks.lua",
        "Binding/Core/Action.lua", "Binding/Core/MacroFactory.lua" }) do owner(path) end
    local bars, state = flux.Bars, flux.Bars.State
    bars.Strip = { frame = frame("strip") }
    bars.Hosts = { IndexSlot = function(host, slot) host.slot = slot end }
    state.headers = {}
    for _, name in ipairs({ "main", "sec", "tert", "staticMain", "staticSec", "staticTert" }) do
        state.headers[name] = frame("header-" .. name)
        state.headers[name].attrs.actionpage = 1
    end
    for _, column in ipairs({ 11, 1, 13, 19 }) do
        bars.hosts[column] = {}
        for _, row in ipairs({ "main", "sec", "tert" }) do
            local widget = frame("FluxActionStrip" .. row .. column)
            state.Attach(state.HeaderFor(column, row), widget, column, row)
            widget.attrs["flux-has-sec"], widget.attrs["flux-has-tert"] = 1, 1
            bars.hosts[column][row] = { widget = widget, column = column, row = row,
                bindingCommand = "ACTIONBUTTON" .. column }
        end
    end
    check(bars.Clicks.RefreshKeys(), "actual Clicks creates main-owned key proxies")
    local function compile(slot, targeting, hidden)
        local action, factory = ns.FluxBindingAction, ns.FluxBindingMacroFactory
        local body, clauses = factory.BuildForward({ groups = { { entries = { {
            binding = { uid = slot + 100, action = action.Spell(slot + 100) },
            sub = { action = hidden and { interrupt = true, cancelQueuedSpell = true } or {}, targets = { hovercastEnabled = false, regularEnabled = targeting,
                regular = { { unit = "DEFAULT" } } } },
        } } } }, native = { kind = "spell", id = slot, token = "Native" .. slot }, mouseoverCast = false })
        check(type(body) == "string" and body:find("Native" .. slot, 1, true), "real compiler retains native fallback")
        check((body:find("mod:alt", 1, true) ~= nil) == targeting, "real compiler preserves target-enabled/disabled semantics")
        if hidden then check(factory.StripOverlayMode(body, clauses) == "hidden", "cast flags select the actual hidden delegate route") end
        return body
    end
    local function effective(widget, name) return e.SecureButton_GetModifiedAttribute(widget, name, "LeftButton") end
    local function applySecure(widget, page, swap)
        e.secure = true
        local context = setmetatable({ self = widget, control = widget:GetParent(), message = tostring(page + swap * 100) }, { __index = e })
        assert(load(widget.attrs["_childupdate-state"], "actual secure child update", "t", context))()
        e.secure = false
    end
    return e, bars, state, compile, effective, applySecure
end

-- Real host traversal matters: minis used to overwrite the proxy belonging to
-- their main, so checking one isolated host missed the final effective route.
for _, shape in ipairs({ "hidden_pair", "all", "main", "sec", "tert", "hidden", "display", "disabled" }) do
if not selectedShape or selectedShape == shape then
    local e, bars, state, compile, effective, applySecure = fixture()
    for _, column in ipairs({ 11, 1, 13, 19 }) do
        local slots = { main = column, sec = column <= 12 and 60 + column or 36 + column,
            tert = column <= 12 and 24 + column or 24 + column }
        for row, slot in pairs(slots) do
            local selected = shape == row or shape == "all" or (shape == "hidden_pair" and row ~= "tert")
                or ((shape == "hidden" or shape == "display" or shape == "disabled") and row == "main")
            local body = selected and compile(slot, shape ~= "disabled", shape == "hidden_pair") or nil
            -- Slot programs are prepared on every row that can resolve it.
            for _, host in pairs(bars.hosts[column]) do
                host.widget.attrs["flux-p-" .. slot] = body
                if selected and (shape == "hidden" or shape == "hidden_pair") then
                    host.widget.attrs["flux-click-" .. slot] = { name = "delegate" .. slot, body = body }
                elseif selected and shape == "display" then host.widget.attrs["flux-m-" .. slot] = "d" end
            end
        end
    end
    -- Disk-backed report: column11 is F, both11/71 have hidden cast-flag
    -- programs and35 is native. Reconcile while Shift is held, as the fallback
    -- does on that modifier event, before executing the actual key route.
    e.held = shape == "hidden_pair" and { shift = true } or {}
    check(state.ApplySlotsInsecure(), shape .. " prepares all three physical modifier routes")
    -- The independent pre-stamp contract covers the prepared no/Shift/Ctrl
    -- sets. Pure Alt is checked from the ordinary main state in other shapes;
    -- it does not have its own prepared routing prefix in State.
    local modifiers = shape == "hidden_pair" and { { shift = true }, {}, { ctrl = true } }
        or { {}, { alt = true }, { shift = true }, { ctrl = true } }
    for _, transport in ipairs({ "prestamped", "secure" }) do
        for _, held in ipairs(modifiers) do
            e.held = held
            local swap = held.shift and 1 or held.ctrl and 2 or 0
            -- The combat path may update the host's face but never an ordinary
            -- local child selector. Neither path may depend on such a write.
            e.combat = true
            if transport == "secure" then
                bars.ForEachHost(function(host) applySecure(host.widget, 1, swap) end)
            else
                check(state.ApplySlotsInsecure() == false, "combat fallback only reindexes the face")
            end
            for _, column in ipairs({ 11, 1, 13, 19 }) do
                local host = bars.hosts[column].main.widget
                local keyer = e["FluxActionStripKey" .. column]
                -- Mouse selectors retain their press-time modifier matrix.
                -- Keyboard dispatch follows the live secure main bundle once
                -- its child update lands; paint-only indexing is not that update.
                local input = transport == "secure" and keyer or host
                local expectedSlot = swap == 1 and (column <= 12 and 60 + column or 36 + column)
                    or swap == 2 and (column <= 12 and 24 + column or 24 + column) or column
                check(effective(input, "action") == expectedSlot, shape .. "/" .. transport .. ": column" .. column
                    .. " swap" .. swap .. " modified input slot " .. tostring(effective(input, "action")) .. ", expected " .. expectedSlot)
                local typ = effective(input, "type")
                local selectedToken = "Native" .. tostring(effective(input, "action"))
                if typ == "macro" or typ == "click" then
                    local delegate = effective(input, "clickbutton")
                    local text = typ == "click" and delegate and delegate.body or effective(input, "macrotext")
                    local cast = text and text:match("/cast%s+([^\n]+)")
                    selectedToken = nil
                    for segment in ((cast or "") .. ";"):gmatch("(.-);") do
                        local condition = segment:match("^%s*(%b[])")
                        if not condition or (condition == "[mod:alt]" and held.alt) then
                            selectedToken = segment:gsub("^%s*%b[]", ""):match("^%s*(.-)%s*$")
                            break
                        end
                    end
                end
                local row = swap == 1 and "sec" or swap == 2 and "tert" or "main"
                local peer = shape == row or shape == "all" or (shape == "hidden_pair" and row ~= "tert") or (shape == "hidden" and row == "main")
                local expectedToken = held.alt and peer and "Spell" .. (expectedSlot + 100) or "Native" .. expectedSlot
                check(selectedToken == expectedToken, shape .. "/" .. transport .. ": actual key action " .. tostring(selectedToken) .. ", expected " .. expectedToken)
                for _, name in ipairs({ "type", "typerelease", "action", "macrotext", "clickbutton" }) do
                    if transport == "secure" then
                        check(effective(keyer, name) == effective(host, name), shape .. "/" .. transport .. ": secure main owns keyboard " .. name)
                    end
                end
                if not held.alt then
                    local wantOverlay = shape == row or shape == "all" or (shape == "hidden_pair" and row ~= "tert")
                        or ((shape == "hidden" or shape == "disabled") and row == "main")
                    local wantType = wantOverlay and ((shape == "hidden" or shape == "hidden_pair") and "click" or "macro") or "action"
                    check(effective(input, "type") == wantType, shape .. ": input uses its mapped main program kind")
                end
            end
            e.combat = false
        end
    end
    -- Retire every overlay after the modifier has changed; stale release or
    -- hidden-click selectors must not survive and steal the next native action.
    e.held = {}
    bars.ForEachHost(function(host)
        for key in pairs(host.widget.attrs) do if key:match("^flux%-[pcm]%-") or key:match("^flux%-click%-") then host.widget.attrs[key] = nil end end
    end)
    check(state.ApplySlotsInsecure(), "overlay removal reconciles actual hosts")
    for _, held in ipairs({ {}, { shift = true }, { ctrl = true } }) do
        e.held = held
        for _, column in ipairs({ 11, 1, 13, 19 }) do
            local keyer = e["FluxActionStripKey" .. column]
            check(effective(keyer, "type") == "action" and effective(keyer, "typerelease") == "action", "removal restores native press/release")
            check(effective(keyer, "macrotext") == nil and effective(keyer, "clickbutton") == nil, "removal clears old macro/delegate selectors")
        end
    end
end
end
print(("Shared binding modifier regression: %d checks PASS (desktop transport only)"):format(checks))
