-- Production State/SlotMath and source-pinned native modified-attribute helper.
-- C attribute lookup, driver delivery and secure transport are modeled. This
-- does not establish native casting, taint, rendering, controller or FPS safety.
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function read(path)
    local f = assert(io.open(path, "rb")); local value = f:read("*a"); f:close()
    return value:gsub("\r\n", "\n")
end
local statePath, measureOnly = "Bars/State.lua", false
for i, flag in ipairs(arg or {}) do
    if flag == "--state" then statePath = arg[i + 1] end
    if flag == "--measure-only" then measureOnly = true end
end
local native = read("../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua")
local function nativeFunction(signature, declaration, env)
    local first = assert(native:find(signature, 1, true))
    local last = assert(native:find("\nend", first, true)) + 3
    return assert(load(declaration .. native:sub(first + #signature, last), "pinned native attribute helper", "t", env))()
end
local prefixes = { "", "alt-", "ctrl-", "alt-ctrl-", "shift-", "alt-shift-", "ctrl-shift-", "alt-ctrl-shift-" }
local function held(mask)
    return { alt = mask % 2 == 1, ctrl = math.floor(mask / 2) % 2 == 1, shift = mask >= 4 }
end
local function swapFor(mask) return mask >= 4 and 1 or mask >= 2 and 2 or 0 end
local layouts = {
    { name = "full", promoted = 0, sec = true, tert = true,
        main = { "main", "sec", "tert" }, secondary = { "sec", "main", "sec" }, tertiary = { "tert", "tert", "main" } },
    { name = "lone-secondary", promoted = 0, sec = true, tert = false,
        main = { "main", "sec", "sec" }, secondary = { "sec", "main", "main" }, tertiary = { "tert", "tert", "main" } },
    { name = "lone-tertiary", promoted = 0, sec = false, tert = true,
        main = { "main", "tert", "tert" }, secondary = { "sec", "main", "sec" }, tertiary = { "tert", "main", "main" } },
    { name = "empty", promoted = 0, sec = false, tert = false,
        main = { "main", "main", "main" }, secondary = { "sec", "main", "sec" }, tertiary = { "tert", "tert", "main" } },
    { name = "promoted-secondary", promoted = 1, sec = true, tert = false,
        main = { "sec", "sec", "sec" }, secondary = { "sec", "main", "main" }, tertiary = { "tert", "tert", "main" } },
    { name = "promoted-tertiary", promoted = 2, sec = false, tert = true,
        main = { "tert", "tert", "tert" }, secondary = { "sec", "main", "sec" }, tertiary = { "tert", "main", "main" } },
    { name = "promoted-both", promoted = 3, sec = true, tert = true,
        main = { "sec", "tert", "tert" }, secondary = { "sec", "sec", "sec" }, tertiary = { "tert", "sec", "sec" } },
}
local function fixture(column, layout, shape)
    local e = setmetatable({ ATTRIBUTE_NOOP = "", held = {}, metrics = { writes = 0, actionInfo = 0, empower = 0 } }, { __index = _G })
    e._G = e
    e.InCombatLockdown = function() return e.combat end
    e.IsShiftKeyDown = function() return e.held.shift end
    e.IsControlKeyDown = function() return e.held.ctrl end
    e.IsAltKeyDown = function() return e.held.alt end
    e.UnitClass = function() return "Priest", "PRIEST" end
    e.GetActionInfo = function(slot) e.metrics.actionInfo = e.metrics.actionInfo + 1; return "spell", slot end
    e.IsPressHoldReleaseSpell = function(slot) e.metrics.empower = e.metrics.empower + 1; return slot % 2 == 1 end
    e.C_ActionBar = { GetActionBarPage = function() return 1 end }
    e.NUM_ACTIONBAR_BUTTONS = 12
    local flux = { Client = { isForever = true, isCamelot = true }, Bars = {} }
    flux.Combat = { InLockdown = e.InCombatLockdown }
    local ns = { Flux = flux }
    local methods, frame = {}, nil
    local function run(self, body, arguments, control)
        local context = setmetatable({ self = self, control = control or self }, { __index = e })
        for key, value in pairs(arguments or {}) do context[key] = value end
        local prior = e.secure; e.secure = true
        local result = assert(load(body, "modeled restricted transport", "t", context))()
        e.secure = prior
        return result
    end
    function methods:GetAttribute(prefix, name, suffix)
        if not name then return self.attrs[prefix] end
        for _, key in ipairs({ prefix .. name .. suffix, "*" .. name .. suffix,
            prefix .. name .. "*", "*" .. name .. "*", name }) do
            if self.attrs[key] ~= nil then return self.attrs[key] end
        end
    end
    function methods:SetAttribute(key, value)
        assert(not e.combat or e.secure, "ordinary protected write in combat")
        e.metrics.writes = e.metrics.writes + 1
        local changed = self.attrs[key] ~= value; self.attrs[key] = value
        local state = key:match("^state%-(.+)$")
        if changed and state and self.attrs["_onstate-" .. state] then
            run(self, self.attrs["_onstate-" .. state], { stateid = state, newstate = value })
        end
    end
    function methods:SetParent(parent)
        assert(not e.combat, "parent write in combat")
        if self.parent then self.parent.children[self] = nil end
        self.parent = parent; if parent then parent.children[self] = true end
    end
    function methods:GetParent() return self.parent end
    function methods:SetID(id) self.id = id end
    function methods:GetID() return self.id or 0 end
    function methods:GetName() return self.name end
    function methods:SetSize() end
    function methods:Show() end
    function methods:GetFrameLevel() return 1 end
    function methods:SetFrameLevel() end
    function methods:SetFrameRef(name, value) self.refs[name] = value end
    function methods:GetFrameRef(name) return self.refs[name] end
    function methods:RunAttribute(name) return run(self, assert(self.attrs[name])) end
    function methods:Execute(body) return run(self, body) end
    function methods:ChildUpdate(name, message)
        for child in pairs(self.children) do
            local body = child.attrs["_childupdate-" .. name]
            if body then run(child, body, { message = message }, self) end
        end
    end
    frame = function(name, parent)
        local f = setmetatable({ name = name, attrs = {}, refs = {}, children = {} }, { __index = methods })
        if name then e[name] = f end
        if parent then f:SetParent(parent) end
        return f
    end
    e.CreateFrame = function(_, name, parent) return frame(name, parent) end
    e.LOCAL_CHECK_Frame = { GetAttribute = methods.GetAttribute, GetParent = methods.GetParent }
    e.SecureButton_GetModifierPrefix = function()
        return (e.held.alt and "alt-" or "") .. (e.held.ctrl and "ctrl-" or "") .. (e.held.shift and "shift-" or "")
    end
    e.SecureButton_GetButtonSuffix = function(button) return button == "LeftButton" and "1" or button == "RightButton" and "2" or "3" end
    e.SecureButton_GetModifiedAttribute = nativeFunction("function SecureButton_GetModifiedAttribute(frame, name, button, prefix, suffix)",
        "return function(frame, name, button, prefix, suffix)", e)
    methods.CalculateAction = nativeFunction("function SecureActionButtonMixin:CalculateAction(button)", "return function(self, button)", e)
    flux.Restricted = { PagingWorks = function() return true end,
        SetPagingSnippet = function(f, key, body) f:SetAttribute(key, body); return true end,
        RegisterPagingDriver = function(f, name) f:SetAttribute("state-" .. name, name == "native" and "1" or "0"); return true end,
        UnregisterPagingDriver = function() return true end,
        ExecutePaging = function(f, body) return f:Execute(body) end }
    assert(load(read("Bars/SlotMath.lua"), "@Bars/SlotMath.lua", "t", e))("_FluxUI", ns)
    assert(load(read(statePath), "@" .. statePath, "t", e))("_FluxUI", ns)
    local bars, state = flux.Bars, flux.Bars.State
    bars.Strip = { inner = frame("inner") }
    state.Create()
    local hosts = {}
    bars.Hosts = { IndexSlot = function(host, slot) host.slot = slot end }
    bars.ForEachHost = function(fn) for _, row in ipairs({ "main", "sec", "tert" }) do fn(hosts[row]) end end
    for _, row in ipairs({ "main", "sec", "tert" }) do
        local widget = frame(row .. column)
        state.Attach(state.HeaderFor(column, row), widget, column, row)
        widget.attrs["flux-promoted"] = layout.promoted
        widget.attrs["flux-has-sec"], widget.attrs["flux-has-tert"] = layout.sec and 1 or 0, layout.tert and 1 or 0
        hosts[row] = { widget = widget, row = row, column = column }
        widget._fluxHost = hosts[row]
    end
    local keyer = frame("FluxActionStripKey" .. column, hosts.main.widget)
    for _, key in ipairs({ "action", "type", "typerelease", "macro", "macrotext", "clickbutton" }) do keyer.attrs["useparent-" .. key] = false end
    state.HeaderFor(column, "main"):SetFrameRef("keyer-" .. column, keyer)
    if state.SyncMainKeyer then state.SyncMainKeyer(hosts.main.widget, keyer) end
    local function slots(page)
        return { main = column <= 12 and (page - 1) * 12 + column or column,
            sec = column <= 12 and 60 + column or 36 + column, tert = 24 + column }
    end
    local function programKind(slot, page)
        local s = slots(page)
        if shape == "mixed" then return slot == s.main and "surface" or slot == s.sec and "hidden" or "native" end
        return shape
    end
    local function programs(page)
        for _, slot in pairs(slots(page)) do
            local kind = programKind(slot, page)
            local text = "/cast [mod:alt] Peer" .. slot .. "; Native" .. slot
            for _, host in pairs(hosts) do
                host.widget.attrs["flux-p-" .. slot] = kind ~= "native" and text or nil
                host.widget.attrs["flux-click-" .. slot] = kind == "hidden" and { slot = slot, body = text } or nil
                host.widget.attrs["flux-m-" .. slot] = kind == "display" and "d" or nil
            end
        end
    end
    local function securePage(page, swap)
        for _, host in pairs(hosts) do
            run(host.widget, host.widget.attrs["_childupdate-state"], { message = tostring(page + swap * 100) }, host.widget:GetParent())
        end
    end
    local function effective(widget, key, button) return e.SecureButton_GetModifiedAttribute(widget, key, button or "LeftButton") end
    local function resetMetrics() e.metrics = { writes = 0, actionInfo = 0, empower = 0 } end
    return e, bars, state, hosts, keyer, slots, programs, programKind, securePage, effective, resetMetrics
end

local function measures()
    local e, bars, state, hosts, _, _, programs, _, securePage, _, reset = fixture(1, layouts[1], "mixed")
    programs(1); programs(7)
    reset(); securePage(1, 0)
    local initial = e.metrics
    reset()
    for _, mask in ipairs({ 4, 5, 6, 7, 2, 3, 0, 1 }) do e.held = held(mask); securePage(1, swapFor(mask)) end
    local edges = e.metrics
    reset()
    e.held = {}; state.RegisterDrivers(); state.ForceApply()
    reset()
    for _, name in ipairs({ "main", "sec", "tert" }) do state.headers[name]:SetAttribute("state-native", "7") end
    local page = e.metrics
    print(("Modifier work: initial=%dw/%dinfo/%dempower; steady8masks=%dw/%dinfo/%dempower; ordinary-page=%dw/%dinfo/%dempower")
        :format(initial.writes, initial.actionInfo, initial.empower, edges.writes, edges.actionInfo, edges.empower, page.writes, page.actionInfo, page.empower))
end
if measureOnly then measures(); return end

for _, column in ipairs({ 1, 12, 13, 19 }) do
for _, page in ipairs({ 1, 2, 7, 9, 11, 12 }) do
for _, layout in ipairs(layouts) do
for _, shape in ipairs({ "native", "surface", "hidden", "display", "mixed" }) do
    local e, bars, state, hosts, keyer, slots, programs, programKind, securePage, effective = fixture(column, layout, shape)
    programs(page)
    local slotIds = slots(page)
    -- Enter combat with Shift or Ctrl already held. The subsequent mask and
    -- release checks deliberately do not deliver another display/driver update.
    local initialMask = column % 2 == 1 and 4 or 2
    for _, transport in ipairs({ "fallback", "secure" }) do
        e.combat, e.held = false, held(initialMask)
        state.headers.main.attrs.actionpage = page
        if transport == "fallback" then check(state.ApplySlotsInsecure(), "fallback preparation succeeds")
        else
            -- Match the reset sent by secure ForceApply; fallback-only clients
            -- do not install the restricted empower classification attributes.
            for _, host in pairs(hosts) do host.widget.attrs["flux-applied-mods"], host.widget.attrs["flux-applied"] = nil, nil end
            securePage(page, swapFor(initialMask))
        end
        e.combat = true
        for mask = 0, 7 do
            e.held = held(mask)
            local swap = swapFor(mask)
            local label = transport .. "/" .. column .. "/" .. page .. "/" .. layout.name .. "/" .. shape .. "/" .. prefixes[mask + 1]
            for _, row in ipairs({ "main", "sec", "tert" }) do
                local rowKey = row == "sec" and "secondary" or row == "tert" and "tertiary" or "main"
                local chosen = layout[rowKey][swap + 1]
                local temporary = column <= 12 and page >= 11
                if temporary then chosen = row end
                local expectedSlot = slotIds[chosen]
                local widget = hosts[row].widget
                local kind = programKind(expectedSlot, page)
                local expectedType = temporary and row == "main" and "action"
                    or kind == "hidden" and "click" or kind == "surface" and "macro" or "action"
                for _, button in ipairs({ "LeftButton", "RightButton", "MiddleButton" }) do
                    check(widget:CalculateAction(button) == expectedSlot, label .. "/" .. row .. ": native slot " .. button)
                    check(effective(widget, "type", button) == expectedType and effective(widget, "typerelease", button) == expectedType,
                        label .. "/" .. row .. ": prepared press/release type " .. button)
                end
                if expectedType == "macro" then
                    check(effective(widget, "macrotext") == "/cast [mod:alt] Peer" .. expectedSlot .. "; Native" .. expectedSlot,
                        label .. "/" .. row .. ": surface body matches selected slot")
                elseif expectedType == "click" then
                    local delegate = effective(widget, "clickbutton")
                    check(delegate and delegate.slot == expectedSlot, label .. "/" .. row .. ": hidden delegate matches selected slot")
                end
                if transport == "secure" then
                    check(widget:GetAttribute(prefixes[mask + 1] .. "IsEmpowerSpell*") == (expectedSlot % 2 == 1),
                        label .. "/" .. row .. ": empower capability follows prepared slot")
                end
            end
            -- Mouse sets above are independent of driver delivery. Keyboard
            -- execution follows the published current main instead: native
            -- bound-click dispatch may consume every physical modifier.
            if transport == "secure" then securePage(page, swap) end
            local main = hosts.main.widget
            local physical = e.held; e.held = {}
            for _, key in ipairs({ "action", "type", "typerelease", "macro", "macrotext", "clickbutton" }) do
                check(effective(keyer, key) == main:GetAttribute(key), label .. ": key follows the published main's " .. key .. " with consumed modifiers")
            end
            e.held = physical
        end
        e.combat = false
    end
end
end
end
end

-- Actual header PACK_MINI, not a direct child call: changing the native page
-- while no modifier is held must update the inverse routes before the hub runs.
do
    local e, _, state, hosts, _, _, programs, _, _, effective = fixture(1, layouts[1], "native")
    programs(1); programs(7)
    check(state.RegisterDrivers(), "actual header drivers register")
    state.ForceApply()
    e.combat, e.secure = true, true
    for _, name in ipairs({ "main", "sec", "tert" }) do state.headers[name]:SetAttribute("state-native", "7") end
    e.secure = false
    check(hosts.sec.widget:GetAttribute("action") == 61 and hosts.tert.widget:GetAttribute("action") == 25,
        "resting mini faces stay on their own slots after form change")
    e.held = { shift = true }
    check(effective(hosts.sec.widget, "action") == 73, "secondary inverse reaches the new main page before modifier hub")
    e.held = { ctrl = true, alt = true }
    check(effective(hosts.tert.widget, "action") == 73, "tertiary compound inverse reaches the new main page before modifier hub")
    e.held = {}; check(state.hub:GetAttribute("state-mod") == "0", "inverse check did not advance the modifier hub")
end
measures()
print(("Bar modifier matrix: %d checks PASS; eight modifier masks, pages, promotion, delegates, held combat entry and release (modeled transport only)"):format(checks))
