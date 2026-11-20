-- Actual Watch -> State/Hosts -> ProgramFace/Identity -> Paint icon path.
-- Hardware, native callback delivery and GPU output remain modeled boundaries.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s:gsub("\r\n", "\n")
end
local replacements = {}
for i, flag in ipairs(arg or {}) do
    if flag == "--watch" then replacements["Bars/Watch.lua"] = arg[i + 1] end
    if flag == "--hosts" then replacements["Bars/Hosts.lua"] = arg[i + 1] end
    if flag == "--state" then replacements["Bars/State.lua"] = arg[i + 1] end
end
local shared = read("tests/shared_binding_modifiers.lua")
shared = shared:sub(1, assert(shared:find("-- Real host traversal matters", 1, true)) - 1)
shared = shared:gsub("return e, bars, state, compile, effective, applySecure", "return e, bars, state, compile, effective, applySecure, flux")
shared = shared:gsub("ipairs%({ 11, 1, 13, 19 }%)", "ipairs({1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19})")
local boot = assert(load(shared .. "\nreturn fixture", "@shared actual bar fixture", "t", _G))()
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function upvalue(fn, wanted)
    for i = 1, math.huge do
        local name, value = debug.getupvalue(fn, i)
        if not name then return end
        if name == wanted then return value end
    end
end
local function fixture(shape, combat)
    local e, bars, state, _, effective, applySecure, flux = boot()
    local f = { e = e, bars = bars, state = state, effective = effective, now = 1, writes = 0,
        walks = 0, translations = 0, callbacks = {}, events = {}, tokens = {}, badgeMoves = 0, effects = 0 }
    e.GetTime = function() return f.now end
    e.FluxButton = {}; e.HasAction = function() return true end
    e.C_Spell = { GetSpellInfo = function(id) id = tonumber(id); return id and { spellID = id, name = "Spell" .. id, iconID = id * 10 } end }
    e.UnitName = function(unit) return unit end
    e.SecureCmdOptionParse = function(options)
        for part in (options .. ";"):gmatch("(.-);") do
            local condition = part:match("^%s*(%b[])")
            local valid = not condition or (condition == "[mod:shift]" and e.held.shift)
                or (condition == "[mod:ctrl]" and e.held.ctrl)
            if valid then return part:gsub("^%s*%b[]", ""):match("^%s*(.-)%s*$"), "target" end
        end
    end
    flux.Safecall = function(fn, ...) return fn(...) end
    flux.Action = { HasAction = function() return true end, GetTexture = function(slot) return slot * 10 end }
    flux.Spell = { GetInfo = function(id) return { name = "Spell" .. id } end, GetTexture = function(id) return tonumber(id) * 10 end }
    flux.EBS = { buttons = {}, badges = {} }
    flux.Events = { Register = function(event, fn) f.events[event] = fn end, IsValid = function() return true end }
    flux.Timer = { After = function() end, Defer = function() end }
    flux.Context = { HasSubscribers = function() return true end, Subscribe = function(fn) f.context = fn end }
    bars.RequestPaint = function(key) f.tokens[key] = true end
    local ns = { Flux = flux }
    local function owner(path) return assert(loadfile(replacements[path] or path, "t", e))("_FluxUI", ns) end
    owner("Bars/Hosts.lua")
    for _, name in ipairs({ "sec", "tert", "staticMain", "staticSec", "staticTert" }) do
        state.headers[name] = e.CreateFrame("Frame", "VisualHeader" .. name)
        state.headers[name].attrs.actionpage = 1
    end
    bars.ForEachHost(function(host)
        host.widget:SetParent(state.HeaderFor(host.column, host.row))
    end)
    bars.Clicks.InvalidateKeys()
    check(bars.Clicks.RefreshKeys(), "visual fixture rebinds main proxy refs after header preparation")
    local onAttribute = assert(upvalue(bars.Hosts.CreateSurface, "OnActionAttribute"))
    local bodies = {}
    if shape == "plain" or shape == "conditional" then
        for _, slot in ipairs({ 1, 61, 25 }) do bodies[slot] = "/cast " .. (10000 + slot) end
        if shape == "conditional" then bodies[61] = "/cast [mod:shift] 20061; 10061" end
    elseif shape == "main-only" then bodies[1] = "/cast 10001" end
    bars.SlotProgram = { Get = function(slot) return bodies[slot] end, GetAll = function() return bodies end }
    owner("Core/Engine/Identity.lua")
    owner("ExtraButtonSystem/Engine/Action.lua")
    owner("Bars/ProgramFace.lua")
    owner("Bars/Paint.lua")
    -- Keep the actual icon renderer and dirty/full paint dispatch. Other widget
    -- lanes are native boundary captures rather than mock icon decisions.
    for _, lane in ipairs({ "Count", "Name", "Cooldown", "Usable", "Equipped", "Range", "Checked", "Hotkey", "AssistedCombat", "AssistedHighlight" }) do
        bars.Paint["Update" .. lane] = function(host) host["shown" .. lane] = host.slot end
    end
    bars.Paint.NeedsRange = function() return false end
    local originalWalk = bars.ForEachHost
    bars.ForEachHost = function(fn) f.walks = f.walks + 1; originalWalk(fn) end
    local originalTranslate = bars.ProgramFace.TranslateHost
    bars.ProgramFace.TranslateHost = function(...)
        f.translations = f.translations + 1; return originalTranslate(...)
    end
    bars.ForEachHost(function(host)
        local icon = {}
        function icon:SetTexture(value) self.texture = value end
        function icon:SetTexCoord() end
        function icon:SetShown(value) self.shown = value end
        function icon:Show() self.shown = true end
        function icon:Hide() self.shown = false end
        host.WIcon = icon
        host.widget._fluxHost = host
        local rawSet = host.widget.SetAttribute
        function host.widget:SetAttribute(name, value)
            local old = self.attrs[name]
            rawSet(self, name, value); f.writes = f.writes + 1
            if name == "action" and value ~= old then
                f.callbacks[#f.callbacks + 1] = function() onAttribute(self, name, value) end
            end
        end
    end)
    state.ApplySlotsInsecure()
    f.callbacks = {}
    bars.ForEachHost(function(host) bars.ProgramFace.TranslateHost(host, true) end)
    bars.ProgramFace.Start()
    bars.Paint.Flush({ bars = true })
    local function identityBeforeObservers(host)
        check(host._fluxFaceSlot == host.slot, "badge/effects observer sees a rebound face slot")
        local kind, id = flux.Identity.Get(flux.Identity.SlotKey(host.slot))
        local body = bodies[host.slot]
        if body then
            local expected = shape == "conditional" and host.slot == 61 and e.held.shift and 20061 or 10000 + host.slot
            check(kind == "spell" and id == expected, "badge/effects observer sees current published macro identity")
        else check(kind == nil, "plain native slot retains no stale program identity") end
    end
    bars.BadgeHost = {
        NotifyDisplay = function(host) f.badgeMoves = f.badgeMoves + 1; identityBeforeObservers(host) end,
        NotifyModifierPaging = function() error("Context owner must not race a separate badge paging pass") end,
    }
    bars.Effects = { Refresh = function(host) f.effects = f.effects + 1; identityBeforeObservers(host) end }
    owner("Bars/Watch.lua"); bars.Watch.Start()
    e.combat = combat
    function f.flush()
        f.now = f.now + 1
        if f.pendingContext and f.context then f.context({ mods = true }) end
        f.pendingContext = false
        bars.Paint.Flush(f.tokens); f.tokens = {}
    end
    function f.edge(held)
        local sig = (held.shift and "s" or "") .. (held.ctrl and "c" or "") .. (held.alt and "a" or "")
        f.pendingContext = sig ~= f.lastHeldSig; f.lastHeldSig = sig
        local before = f.writes
        e.held = held; f.events.MODIFIER_STATE_CHANGED(); f.flush()
        check(f.writes == before, "visual modifier synchronization does not write protected execution attributes")
    end
    function f.late(swap, page)
        -- Run a real stored child snippet carrying an older display state.
        -- Its actual attribute callback is then delivered after the new edge.
        bars.ForEachHost(function(host) applySecure(host.widget, page or 1, swap) end)
        local before = f.writes
        local callbacks = f.callbacks; f.callbacks = {}
        for _, fn in ipairs(callbacks) do fn() end
        f.flush()
        check(f.writes == before, "late display callback correction does not rewrite secure attributes")
    end
    function f.page(page)
        for _, header in pairs(state.headers) do header.attrs.actionpage = page end
        f.late(state.CurrentSwap(), page)
		f.events.ACTIONBAR_PAGE_CHANGED()
		f.flush()
    end
    function f.stale(value)
        local before = f.writes
        onAttribute(bars.hosts[1].main.widget, "action", value)
        f.flush()
        check(f.writes == before, "older page notification only corrects display metadata")
    end
    function f.headerOrder()
        f.edge({ shift = true })
        local secondary = bars.hosts[1].sec
        state.headers.sec.attrs.actionpage = 7
        applySecure(secondary.widget, 7, 1)
        local callbacks = f.callbacks; f.callbacks = {}
        for _, fn in ipairs(callbacks) do fn() end
        -- Modifier display indexing occurs while the main header is still1.
        f.edge({ shift = true })
        check(secondary.slot == 73 and secondary.WIcon.texture == 730,
            "secondary header may advance before main without an old shared-page rollback")
        state.headers.main.attrs.actionpage = 7
        applySecure(bars.hosts[1].main.widget, 7, 1)
        callbacks = f.callbacks; f.callbacks = {}
        for _, fn in ipairs(callbacks) do fn() end
        f.flush()
        check(secondary.slot == 73 and secondary.WIcon.texture == 730,
            "later main-only callback preserves the already updated secondary display")
        f.page(1); f.edge({})
    end
    function f.verify(slot)
        local host = bars.hosts[1].main
        local expected = bodies[slot] and (shape == "conditional" and slot == 61 and e.held.shift and 20061 or 10000 + slot) or slot
        check(host.slot == slot and host._fluxFaceSlot == slot, "visual mapping follows current hardware input")
        check(host.WIcon.texture == expected * 10 and host.WIcon.shown, "actual Paint.UpdateIcon renders the current native/program action")
        -- A paint-only edge does not advance the secure driver. This fixture
        -- intentionally delays that driver; full native OnClick tests cover
        -- dispatch after its current main program has been published.
        check(effective(e.FluxActionStripKey1, "action") == bars.hosts[1].main.widget:GetAttribute("action"),
            "visual synchronization preserves the secure main's independent keyboard bundle")
    end
    return f
end
for _, shape in ipairs({ "native", "plain", "main-only", "conditional" }) do
    for _, combat in ipairs({ false, true }) do
        local f = fixture(shape, combat)
        f.edge({ shift = true }); f.verify(61)
        f.edge({}); f.verify(1)
        f.late(1); f.verify(1)
        f.edge({ ctrl = true }); f.verify(25)
        f.late(0); f.verify(25)
        f.edge({}); f.verify(1)
        f.late(2); f.verify(1)
        f.headerOrder(); f.verify(1)
        f.page(2); f.verify(13)
        f.edge({ ctrl = true }); f.verify(25)
        f.stale(1); f.verify(25)
        f.edge({}); f.verify(13)
        f.page(11); f.verify(121)
        f.edge({ shift = true }); f.verify(121)
        f.stale(61); f.verify(121)
        f.page(1); f.verify(61)
        f.edge({}); f.verify(1)
        -- Same modifier events may repeat while a key is held. Mapping and
        -- identity should remain stable without another moved-host parse.
        local translations = f.translations
        for _ = 1, 20 do f.edge({}) end
        check(f.translations == translations, "unchanged modifier repeats do not translate moved-host identity again")
        f.e.combat = false
    end
end
print(("Bar modifier visuals: %d checks PASS (actual Lua identity/icon path; native display pending)"):format(checks))
