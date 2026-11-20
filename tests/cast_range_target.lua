-- Actual cast-target resolution and Bars/EBS painters. WoW conditional parsing,
-- API answers and widgets are explicit desktop boundaries; no native cast claim.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local replacements = {}
for i, flag in ipairs(arg or {}) do
    if flag == "--range" then replacements["Core/Engine/Range.lua"] = arg[i + 1] end
    if flag == "--mouseover" then replacements["Core/Engine/MouseoverCast.lua"] = arg[i + 1] end
    if flag == "--bars" then replacements["Bars/Paint.lua"] = arg[i + 1] end
    if flag == "--program-face" then replacements["Bars/ProgramFace.lua"] = arg[i + 1] end
    if flag == "--extra" then replacements["ExtraButtonSystem/Engine/Paint.lua"] = arg[i + 1] end
    if flag == "--action" then replacements["ExtraButtonSystem/Engine/Action.lua"] = arg[i + 1] end
end
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; if failures <= 30 then print("FAIL " .. label) end end
end
local names = { [101] = "Frostbolt", [102] = "Heal", [103] = "Pinned", [104] = "Ward" }
local ids = {}; for id, name in pairs(names) do ids[name:lower()] = id end
local function fixture(native)
    local s = { native = native, enabled = true, now = 1, mask = 0, peek = false, combat = false,
        modifier = "NONE", modified = {}, slots = { [6] = { "spell", 101 }, [66] = { "spell", 102 } },
        units = { target = true, mouseover = true, focus = true, player = true },
        friendly = { target = false, mouseover = true, focus = false, player = true },
        answers = { target = false, mouseover = true, focus = false, player = true },
        programs = {}, hovers = {}, idles = {}, probes = {}, protectedWrites = 0 }
    local e = setmetatable({ FluxButton = {}, FLUX_API = { isRetail = true } }, { __index = _G }); e._G = e
    e.GetTime = function() return s.now end
    e.CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
    e.UnitExists = function(unit) return s.units[unit] == true end
    e.UnitIsFriend = function(_, unit) return s.friendly[unit] == true end
    e.UnitCanAssist = e.UnitIsFriend
    e.UnitCanAttack = function(_, unit) return s.units[unit] and s.friendly[unit] == false end
    e.UnitName = function(unit) return unit end
    e.UnitIsDead = function() return false end
    e.IsShiftKeyDown = function() return s.mask % 2 == 1 end
    e.IsControlKeyDown = function() return math.floor(s.mask / 2) % 2 == 1 end
    e.IsAltKeyDown = function() return s.mask >= 4 end
    e.InCombatLockdown = function() return false end
    e.IsMouseoverCastSupported = function() return s.native end
    e.GetModifiedClick = function() return s.modifier end
    e.IsModifiedClick = function(name) return s.modified[name] == true end
    e.C_CVar = { GetCVar = function() return s.enabled and "1" or "0" end }
    e.GetCVar = e.C_CVar.GetCVar
    e.GetCVarBool = function() return s.enabled end
    e.FluxOptions = { GetActionbarsDB = function() return { mouseoverCast = s.enabled } end }
    e.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    local function spellId(value) return tonumber(value) or type(value) == "string" and ids[value:lower()] end
    e.C_Spell = {
        GetSpellIDForSpellIdentifier = spellId,
        GetSpellInfo = function(value) local id = spellId(value); return id and names[id] and { spellID = id, name = names[id], iconID = id } end,
        IsSpellHelpful = function(value) return spellId(value) ~= 101 end,
        IsSpellHarmful = function(value) return spellId(value) == 101 end,
    }
    e.IsSpellHelpful, e.IsSpellHarmful = e.C_Spell.IsSpellHelpful, e.C_Spell.IsSpellHarmful
    e.C_Item = { GetItemInfoInstant = function(value) return tonumber(tostring(value):match("item:(%d+)")) end,
        IsHelpfulItem = function() return true end, IsHarmfulItem = function() return false end }
    e.C_ActionBar = {
        IsHelpfulAction = function(slot) return s.slots[slot] and s.slots[slot][2] ~= 101 end,
        IsHarmfulAction = function(slot) return s.slots[slot] and s.slots[slot][2] == 101 end,
    }
    e.GetActionInfo = function(slot) return table.unpack(s.slots[slot] or {}) end
    e.HasAction = function(slot) return s.slots[slot] ~= nil end
    -- Only the conditionals generated/exercised below are modeled. Unknown
    -- terms fail loudly rather than silently agreeing with production code.
    e.SecureCmdOptionParse = function(options)
        for part in (options .. ";"):gmatch("(.-);") do
            local rest = part:match("^%s*(.-)%s*$")
            local groups = {}
            while rest:sub(1, 1) == "[" do
                local cond, tail = rest:match("^%[([^%]]*)%]%s*(.*)$")
                assert(cond, "malformed modeled options"); groups[#groups + 1] = cond; rest = tail
            end
            if #groups == 0 then groups[1] = "" end
            for _, conditions in ipairs(groups) do
                local unit, ok = "target", true
                for term in conditions:gmatch("[^,]+") do
                    if term:sub(1, 1) == "@" then unit = term:sub(2) end
                end
                for term in conditions:gmatch("[^,]+") do
                    if term:sub(1, 1) == "@" then
                    elseif term == "help" then ok = ok and s.friendly[unit] == true
                    elseif term == "harm" then ok = ok and s.friendly[unit] == false
                    elseif term == "exists" then ok = ok and s.units[unit] == true
                    elseif term == "nodead" then
                    elseif term == "dead" then ok = false
                    elseif term == "combat" then ok = ok and s.combat
                    elseif term == "nocombat" then ok = ok and not s.combat
                    else
                        local key = term:match("^mod:(.+)$")
                        local no = term:match("^nomod:(.+)$")
                        local held = { shift = e.IsShiftKeyDown(), ctrl = e.IsControlKeyDown(), alt = e.IsAltKeyDown() }
                        if key then assert(held[key] ~= nil, "unknown modifier"); ok = ok and held[key]
                        elseif no then assert(held[no] ~= nil, "unknown modifier"); ok = ok and not held[no]
                        else error("unmodeled conditional " .. term) end
                    end
                end
                if ok and rest ~= "" then return rest, unit end
            end
        end
    end
    e.FluxMouseoverKeybindModule = { IsHovercastPeekMouseContext = function() return s.peek end }
    local function probe(kind, id, unit)
        s.probes[#s.probes + 1] = { kind, id, unit }
        return s.answers[unit]
    end
    local f = { Cap = { hasRestrictedClosures = true }, Client = { isRetail = true },
        EBS = { buttons = {}, badges = {} },
        Bars = { COLOR = { usable = {1,1,1}, mana = {.5,.5,1}, unusable = {.4,.4,.4}, outOfRange = {.8,.1,.1} },
            Hosts = { LiveSlot = function(host) return host.slot end } },
        Spell = { IsInRange = function(id, unit) return probe("spell", id, unit) end,
            IsUsable = function() return true, false end, GetOverrideSpell = function(id) return id end,
            GetInfo = function(id) return e.C_Spell.GetSpellInfo(id) end, GetTexture = function(id) return id end },
        Item = { IsInRange = function(id, unit) return probe("item", id, unit) end,
            CanCheckRange = function() return true end, IsUsable = function() return true, false end,
            IsConsumable = function() return false end, UsesConsumableCharges = function() return false end },
        Action = { HasAction = e.HasAction, IsUsable = function() return true, false end } }
    f.Bars.SlotProgram = { Get = function(slot) return s.programs[slot] end,
        GetHover = function(slot) return s.hovers[slot] end, GetIdle = function(slot) return s.idles[slot] end }
    e.Flux = f
    local ns = { Flux = f }
    for _, path in ipairs({ "Binding/Core/Action.lua", "Binding/Core/Conditions.lua", "Binding/Core/MacroFactory.lua",
        "Core/Engine/MouseoverCast.lua", "Core/Engine/Range.lua", "ExtraButtonSystem/Engine/Action.lua",
        "Bars/ProgramFace.lua", "Bars/Paint.lua", "ExtraButtonSystem/Engine/Paint.lua" }) do
        assert(load(read(replacements[path] or path), "@" .. path, "t", e))("_FluxUI", ns)
    end
    local function widget(kind, id)
        local w = { attrs = { type = kind, [kind] = id, checkmouseovercast = native and kind == "action" or false,
            smarttarget = not native or nil, ["flux-smart"] = kind ~= "action" and 3 or nil } }
        function w:GetAttribute(name) return self.attrs[name] end
        function w:SetAttribute(name, value) s.protectedWrites = s.protectedWrites + 1; self.attrs[name] = value end
        return w
    end
    local function icon()
        return { SetVertexColor = function(self, r, g, b) self.color = { r, g, b } end,
            SetDesaturated = function() end }
    end
    function s.bar(slot)
        return { slot = slot or 6, widget = widget("action", slot or 6), WIcon = icon() }
    end
    function s.extra(id)
        return { ActionType = "spell", ActionValue = id or 101, SpellId = id or 101,
            Widget = widget("spell", id or 101), WIcon = icon() }
    end
    function s.macro(body)
        local btn = s.extra()
        btn.ActionType, btn.ActionValue, btn.MacroBody = "macrotext", body, body
        btn._fluxStripFace = true -- actual translation stops before unrelated UI paint.
        f.EBS.Action.TranslateMacro(btn)
        btn._fluxStripFace = nil
        return btn
    end
    function s.overlay(host, body, idle, hover)
        s.programs[host.slot], s.idles[host.slot], s.hovers[host.slot] = body, idle, hover
        host._fluxFace = s.macro(idle or body)
        host._fluxFace._fluxStripFace = true
        host._fluxFaceSlot = host.slot
    end
    function s.frame() s.now = s.now + .01; s.probes = {} end
    function s.assertProbe(surface, button, kind, id, unit, label)
        s.frame()
        local writes = s.protectedWrites
        if surface == "bars" then f.Bars.Paint.UpdateRange(button) else f.EBS.Paint.UpdateRange(button) end
        check(s.protectedWrites == writes, label .. ": range writes no secure attributes")
        local p = s.probes[#s.probes]
        if unit then
            check(#s.probes == 1 and p[1] == kind and p[2] == id and p[3] == unit,
                label .. ": probe follows cast identity/unit (got " .. (p and table.concat(p, "/") or "none") .. ")")
        else check(#s.probes == 0, label .. ": no inferable unit means no probe") end
        local red = unit and s.answers[unit] == false or false
        check(button._outOfRange == red, label .. ": public red state matches actual unit")
        if unit then
            local c = button.WIcon.color
            check(c and c[1] == (red and .8 or 1) and c[2] == (red and .1 or 1), label .. ": actual painter colors action")
        end
    end
    return s, f, ns, e
end

for _, native in ipairs({ true, false }) do
    local s, f, ns, e = fixture(native)
    local label = native and "native" or "legacy"
    local bar, extra = s.bar(), s.extra()
    for _, peek in ipairs({ false, true }) do
        s.peek = peek
        s.assertProbe("bars", bar, "spell", 101, "target", label .. " unbound Frostbolt + friendly hover/peek=" .. tostring(peek))
        s.assertProbe("extra", extra, "spell", 101, "target", label .. " plain extra Frostbolt + friendly hover")
    end
    for _, friendly in ipairs({ false, true }) do
        s.friendly.mouseover = friendly
        for _, id in ipairs({ 101, 102 }) do
            s.slots[6], bar._fluxAType, bar._fluxAId = { "spell", id }, nil, nil
            extra.SpellId, extra.ActionValue = id, id
            local unit = (friendly == (id ~= 101)) and "mouseover" or "target"
            s.assertProbe("bars", bar, "spell", id, unit, label .. " native occupant eligibility")
            s.assertProbe("extra", extra, "spell", id, unit, label .. " standalone eligibility")
        end
    end
    s.friendly.mouseover, s.slots[6] = true, { "spell", 101 }
    bar._fluxAType, bar._fluxAId = nil, nil
    extra.SpellId, extra.ActionValue = 102, 102
    s.enabled = false
    s.assertProbe("extra", extra, "spell", 102, "target", label .. " disabled mouseover")
    s.enabled, s.modifier, s.modified.MOUSEOVERCAST = true, "SHIFT", false
    if native then s.assertProbe("extra", extra, "spell", 102, "target", "inactive native mouseover modifier") end
    s.modifier = "NONE"
    for _, surface in ipairs({ "bars", "extra" }) do
        for _, unit in ipairs({ "target", "focus", "player", "mouseover", "cursor" }) do
            local body = "#showtooltip [@mouseover] Heal\n/cast [@" .. unit .. "] Frostbolt"
            local button = surface == "bars" and s.bar() or s.macro(body)
            if surface == "bars" then s.overlay(button, body) end
            local face = surface == "bars" and button._fluxFace or button
            check(face.SpellId == 102 and face.MacroTarget == "mouseover", "real tooltip translation deliberately disagrees with cast")
            s.assertProbe(surface, button, "spell", 101, unit ~= "cursor" and unit or nil, label .. " " .. surface .. " explicit @" .. unit)
        end
        for _, body in ipairs({ "#showtooltip Heal\n/cast [mod:alt] Frostbolt", "#showtooltip Heal\n/click OtherButton" }) do
            local button = surface == "bars" and s.bar() or s.macro(body)
            if surface == "bars" then s.overlay(button, body) end
            button._outOfRange = true
            s.assertProbe(surface, button, nil, nil, nil, label .. " authoritative inactive/delegated cast clears stale red")
        end
    end
    -- The actual compiler's keyboard and UF-only hover legs are different.
    local factory = ns.FluxBindingMacroFactory
    local ctx = { groups = { { entries = { { binding = { uid = 7, action = ns.FluxBindingAction.Spell(102) },
        sub = { action = {}, targets = { hovercastEnabled = true, regularEnabled = false,
            hovercast = { hostility = "FRIENDLY", vitals = "ALIVE" }, regular = {} } } } } } },
        native = { kind = "spell", id = 101, token = "Frostbolt" }, mouseoverCast = false, forceNativeTail = true }
    local forward = factory.BuildForward(ctx)
    local hover = factory.BuildHover(ctx)
    check(forward and hover and forward ~= hover, "actual compiler emits distinct hover-only body")
    local host = s.bar(); s.overlay(host, forward, nil, hover)
    local badge = s.macro(forward); badge._fluxWant = { macrotext = forward, hoverMacrotext = hover }
    for _, peek in ipairs({ false, true }) do
        s.peek = peek
        s.assertProbe("bars", host, "spell", peek and 102 or 101, peek and "mouseover" or "target", label .. " hover-only strip execution context")
        s.assertProbe("extra", badge, "spell", peek and 102 or 101, peek and "mouseover" or "target", label .. " hover-only badge execution context")
    end
    -- Original executable MO tail must survive idle display stripping.
    s.peek = false
    local full = factory.BuildForward({ groups = {}, native = { kind = "spell", id = 102, token = "Heal" },
        mouseoverCast = true, forceNativeTail = true })
    local idle = factory.IdleMacroText(full, true)
    check(full ~= idle, "actual idle formatter removes automatic mouseover tail")
    s.overlay(host, full, idle)
    check(f.Bars.ProgramFace.BodyForSlot(6) == idle and f.Bars.ProgramFace.CastBodyForSlot(6) == full,
        "actual ProgramFace separates display and cast bodies")
    s.assertProbe("bars", host, "spell", 102, "mouseover", label .. " full strip body owns range despite idle target")
    badge = s.macro(idle); badge._fluxWant = { macrotext = idle, rangeMacrotext = full }
    s.assertProbe("extra", badge, "spell", 102, "mouseover", label .. " full badge range metadata survives idle stripping")
    local reverse = factory.BuildReverse({ { owner = 7, cond = { "mod:alt", "@focus" } },
        { owner = "native", cond = {} } }, 7, "Heal", "Frostbolt")
    badge = s.macro(reverse); badge._fluxWant = { macrotext = reverse }
    for _, alt in ipairs({ false, true, false }) do
        s.mask = alt and 4 or 0
        s.assertProbe("extra", badge, "spell", alt and 101 or 102, alt and "focus" or "target", label .. " reverse badge follows active conditional")
    end
    s.mask = 0
    -- A reverse badge swaps display tokens, not those tokens' real cast
    -- targets. Compile original and reverse bodies from one actual context.
    local regularCtx = { groups = { { entries = { { binding = { uid = 8, action = ns.FluxBindingAction.Spell(102) },
        sub = { action = {}, load = { combat = { selected = true, value = true } },
            targets = { hovercastEnabled = false, regularEnabled = true, regular = { { unit = "FOCUS" } } } } } } } },
        native = { kind = "spell", id = 101, token = "Frostbolt" }, mouseoverCast = false, forceNativeTail = true }
    local mainBody, originalClauses = factory.BuildForward(regularCtx)
    local reverseBody = factory.BuildReverse(originalClauses, 8, "Heal", "Frostbolt")
    check(type(mainBody) == "string" and type(reverseBody) == "string", "actual conditional focus binding compiles both directions")
    s.answers.target, s.answers.focus = true, false
    for _, active in ipairs({ true, false, true }) do
        s.combat = active
        s.overlay(host, mainBody)
        badge = s.macro(reverseBody); badge._fluxWant = { macrotext = reverseBody, rangeClauses = originalClauses }
        check(badge.SpellId == (active and 101 or 102), "actual reverse translation shows current opposite action")
        s.assertProbe("bars", host, "spell", active and 102 or 101, active and "focus" or "target", label .. " original main conditional target")
        s.assertProbe("extra", badge, active and "spell" or nil, active and 101 or nil, active and "target" or nil,
            label .. " reverse visible native uses target; inactive binding does not borrow native unit")
    end
    s.combat, s.answers.target, s.answers.focus = false, false, false
    -- Page/mini occupant and same-frame slot replacement use current identity.
    s.programs, s.idles, s.hovers = {}, {}, {}
    host = s.bar()
    s.assertProbe("bars", host, "spell", 101, "target", label .. " main occupant before paging")
    host.slot, host.widget.attrs.action = 66, 66
    f.Bars.Paint.ClearCache(host)
    s.assertProbe("bars", host, "spell", 102, "mouseover", label .. " promoted mini occupant after paging")
    local extraSame, badgeSame = s.extra(102), s.macro("/cast [@mouseover] Heal")
    s.frame(); f.Bars.Paint.UpdateRange(host); f.EBS.Paint.UpdateRange(extraSame); f.EBS.Paint.UpdateRange(badgeSame)
    check(#s.probes == 1, label .. " same cast unit across bar/extra/badge shares one memoized probe")
    s.slots[66] = { "spell", 101 }; host._fluxAType, host._fluxAId = nil, nil
    f.Bars.Paint.UpdateRange(host)
    local last = s.probes[#s.probes]
    check(last and last[2] == 101 and last[3] == "target", label .. " native slot classification is live within a frame")
end
print(("Cast range target integration: %d checks, %d failures (desktop API/parser/frame boundaries; native pending)"):format(checks, failures))
os.exit(failures > 0 and 1 or 0)
