-- Real mouseover/Action/MacroFactory owners; restricted VM and native facts modeled.
local function read(path)
    local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
local replacements = {}
for i, flag in ipairs(arg or {}) do
    if flag == "--engine" then replacements["Core/Engine/MouseoverCast.lua"] = arg[i + 1] end
    if flag == "--factory" then replacements["Binding/Core/MacroFactory.lua"] = arg[i + 1] end
    if flag == "--apply" then replacements["Binding/Core/Apply.lua"] = arg[i + 1] end
end
local function source(path) return read(replacements[path] or path) end
local base = read("tests/mouseover_native.lua")
local stop = assert(base:find('for _, branch in ipairs({ "live", "forever" }) do', 1, true))
local fixtureEnv = setmetatable({ arg = { replacements["Core/Engine/MouseoverCast.lua"] } }, { __index = _G })
local fixture = assert(load(base:sub(1, stop - 1) .. "return fixture", "@mouseover-fixture", "t", fixtureEnv))()
local checks, failures = 0, 0
local counters = { clicks = 0, actionQueries = 0, polarityQueries = 0, compiles = 0 }
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local spells = { [10] = "Heal", [20] = "Strike", [30] = "Neutral", [40] = "Ground" }
local helpful = { [10] = true }
local harmful = { [20] = true, [40] = true }
local function spellID(value)
    if type(value) == "number" then return value end
    value = tostring(value):gsub("^!", ""):gsub("%b()$", "")
    for id, name in pairs(spells) do if name == value then return id end end
end
local function itemID(value) return tonumber(value) or tonumber(tostring(value):match("item:(%d+)")) end
local function spellHelp(value) return helpful[spellID(value)] == true end
local function spellHarm(value) return harmful[spellID(value)] == true end
local function itemHelp(value) return itemID(value) == 100 end
local function itemHarm(value) return itemID(value) == 200 end

-- Evaluate generated conditionals, not just clause arrays. This is a bounded
-- macro-language model, not a substitute for the client's protected parser.
local function selectCast(body, state)
    for line in tostring(body or ""):gmatch("[^\r\n]+") do
        local rest = line:match("^/cast%s+(.+)") or line:match("^/use%s+(.+)")
        if rest then
            for segment in (rest .. ";"):gmatch("(.-);") do
                segment = segment:match("^%s*(.-)%s*$")
                local conditions = segment:match("^(%b[])")
                local token = conditions and segment:sub(#conditions + 1):match("^%s*(.-)%s*$") or segment
                local unit, valid = "target", true
                if conditions then
                    local parts = {}
                    for part in conditions:sub(2, -2):gmatch("[^,]+") do
                        if part:sub(1, 1) == "@" then unit = part:sub(2) else parts[#parts + 1] = part end
                    end
                    local reaction = state[unit]
                    for _, part in ipairs(parts) do
                        if part == "help" then valid = valid and reaction == "friend"
                        elseif part == "harm" then valid = valid and reaction == "enemy"
                        elseif part == "exists" then valid = valid and reaction ~= nil
                        elseif part == "nodead" then valid = valid and not state[unit .. "Dead"]
                        elseif part == "dead" then valid = valid and state[unit .. "Dead"] == true
                        elseif part:match("^mod:") then valid = valid and state[part:sub(5)] == true
                        elseif part == "combat" then valid = valid and state.combat == true
                        elseif part == "noform" then valid = valid and (state.form or 0) == 0
                        elseif part:match("^form:") then valid = valid and state.form == tonumber(part:sub(6))
                        else error("unmodeled conditional: " .. part) end
                    end
                end
                if valid and token ~= "" then return token, unit end
            end
        end
    end
end

for _, family in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local native = family == "live" or family == "forever"
    local f = fixture(native, "1", family ~= "forever")
    local e = f.env
    f.flux.Client = { isRetail = family == "live", isForever = family == "forever" }
    -- Model the already-existing repaired-handler probe, not a new bypass.
    f.flux.Restricted.PagingWorks = function() return true end
    f.db.mouseoverCast = true
    e.C_Spell = { IsSpellHelpful = spellHelp, IsSpellHarmful = spellHarm,
        GetSpellInfo = function(id) id = spellID(id); if id then return { name = spells[id], spellID = id } end end,
        IsSpellDataCached = function() return true end }
    e.C_Item = { IsHelpfulItem = itemHelp, IsHarmfulItem = itemHarm }
    e.IsSpellHelpful, e.IsSpellHarmful = spellHelp, spellHarm
    e.IsHelpfulItem, e.IsHarmfulItem = itemHelp, itemHarm
    e.IsHelpfulSpell, e.IsHarmfulSpell = spellHelp, spellHarm
    e.GetSpellInfo = function(id) id = spellID(id); if id then return spells[id], nil, 1, nil, nil, nil, id end end
    e.GetSpellSubtext = function() return nil end
    e.GetActionInfo = function(slot)
        counters.actionQueries = counters.actionQueries + 1
        return slot == 3 and "item" or "spell", slot == 1 and 10 or slot == 2 and 20 or 100
    end
    e.GetInventoryItemID = function(_, slot) return slot == 13 and 100 or 200 end
    e.IsSpellHelpful = function(id) counters.polarityQueries = counters.polarityQueries + 1; return spellHelp(id) end
    e.IsSpellHarmful = function(id) counters.polarityQueries = counters.polarityQueries + 1; return spellHarm(id) end
    e.IsHelpfulItem = function(id) counters.polarityQueries = counters.polarityQueries + 1; return itemHelp(id) end
    e.IsHarmfulItem = function(id) counters.polarityQueries = counters.polarityQueries + 1; return itemHarm(id) end
    local held, reaction, targetExists = {}, "friend", true
    e.IsShiftKeyDown = function() return held.shift end
    e.IsControlKeyDown = function() return held.ctrl end
    e.IsAltKeyDown = function() return held.alt end
    e.UnitExists = function(unit) return (unit == "target" and targetExists) or (unit == "mouseover" and reaction ~= nil) end
    e.SecureCmdOptionParse = function(condition)
        if not reaction then return nil end
        if condition:find(",help", 1, true) and reaction ~= "friend" then return nil end
        if condition:find(",harm", 1, true) and reaction ~= "enemy" then return nil end
        return "mouseover"
    end

    local function click(widget, button)
        f.secure = true
        assert(load("local self, button = ...\n" .. assert(widget.scripts.PreClick), "@production-pick", "t", e))(widget, button or "LeftButton")
        f.secure = false
        counters.clicks = counters.clicks + 1
    end
    local function release(widget)
        f.secure = true
        assert(load("local self, button = ...\n" .. assert(widget.scripts.PostClick), "@production-release", "t", e))(widget, "LeftButton")
        f.secure = false
        check(widget.attrs.unit == nil, family .. " standalone leaves no parked unit")
    end
    for _, id in ipairs({ 10, 20, 30, 100, 200 }) do
        local widget = f.frame(); widget.attrs.type = id >= 100 and "item" or "spell"
        widget.attrs[widget.attrs.type] = id >= 100 and "item:" .. id or spells[id]
        f.mc.RegisterButton(widget)
        if id >= 100 then f.mc.SetButtonItem(widget, id) else f.mc.SetButtonSpell(widget, id) end
        check(type(widget.scripts.PreClick) == "string", family .. " standalone has verified click-time adapter")
        if type(widget.scripts.PreClick) == "string" then
        for _, mo in ipairs({ "friend", "enemy", "none" }) do
            reaction = mo ~= "none" and mo or nil
            click(widget)
            local valid = reaction and (id == 30 or ((id == 10 or id == 100) and reaction == "friend")
                or ((id == 20 or id == 200) and reaction == "enemy"))
            check(widget.attrs.unit == (valid and "mouseover" or "target"), family .. " standalone polarity " .. id .. " " .. mo)
            release(widget)
        end
        reaction, targetExists = nil, false
        click(widget); check(widget.attrs.unit == nil, family .. " no unit leaves client default"); release(widget)
        targetExists = true
        if native then
            f.modifier, f.held, reaction = "SHIFT", false, (id == 20 or id == 200) and "enemy" or "friend"
            f.mc.ApplyNativeCheck(widget); click(widget)
            check(widget.attrs.unit == nil, family .. " native standalone waits for modifier"); release(widget)
            f.held = true; click(widget)
            check(widget.attrs.unit == "mouseover", family .. " native standalone accepts modifier"); release(widget)
            f.modifier, f.held = "NONE", false
            f.mc.ApplyNativeCheck(widget)
        else
            f.db.mouseoverCast = false; f.mc.Apply(); click(widget)
            check(widget.attrs.unit == nil, family .. " fallback switch off"); release(widget)
            f.db.mouseoverCast = true; f.mc.Apply(); reaction = (id == 20 or id == 200) and "enemy" or "friend"
            click(widget); check(widget.attrs.unit == "mouseover", family .. " fallback re-enable without rebuilding item"); release(widget)
        end
        if id == 10 or id == 100 then
            widget.attrs["shift-" .. widget.attrs.type .. "*"] = id == 10 and 20 or "item:200"
            held.shift, reaction = true, "enemy"
            click(widget); check(widget.attrs.unit == "mouseover", family .. " standalone modifier overrides base identity"); release(widget)
            reaction = "friend"; click(widget)
            check(widget.attrs.unit == "target", family .. " standalone modifier rejects base spell polarity"); release(widget)
            held = {}
        end
        end
    end
    if not native then
        local widget = f.frame(); widget.attrs.type, widget.attrs.action = "action", 1
        widget.attrs["alt-ctrl-shift-type*"], widget.attrs["alt-ctrl-shift-action*"] = "action", 2
        f.mc.AttachHost(widget)
        held.alt, held.ctrl, held.shift, reaction = true, true, true, "enemy"
        click(widget); check(widget.attrs.unit == "mouseover", family .. " modifier action classified instead of base heal"); release(widget)
        reaction = "friend"; click(widget)
        check(widget.attrs.unit == "target", family .. " modifier harmful action rejects friendly mouseover"); release(widget)
        held = {}
    end
    f.mc.Start()
    if not native then
        local beforeAction, beforePolarity = counters.actionQueries, counters.polarityQueries
        for _, slot in ipairs({ 1, 2, 3 }) do
            local widget = f.frame(); widget.attrs.type, widget.attrs.action = "action", slot
            f.mc.AttachHost(widget)
            local click = assert(widget.scripts.PreClick)
            for _, mo in ipairs({ "friend", "enemy", "none" }) do
                reaction = mo ~= "none" and mo or nil
                f.secure = true
                assert(load("local self, button = ...\n" .. click, "@production-mouseover-click", "t", e))(widget, "LeftButton")
                f.secure = false
                local want = reaction and ((slot == 2 and reaction == "enemy") or (slot ~= 2 and reaction == "friend"))
                    and "mouseover" or "target"
                check(widget.attrs.unit == want, family .. " plain slot " .. slot .. " " .. mo .. " compatible mouseover/target")
                f.secure = true
                assert(load("local self, button = ...\n" .. widget.scripts.PostClick, "@production-mouseover-post", "t", e))(widget, "LeftButton")
                f.secure = false
                check(widget.attrs.unit == nil, family .. " click leaves no live mouseover unit")
            end
        end
        print(("Matched plain clicks: %s clicks=9 actionQueries=%d polarityQueries=%d"):format(family,
            counters.actionQueries - beforeAction, counters.polarityQueries - beforePolarity))
    end

    local ns = { Flux = f.flux, FluxBindingConditions = { MacroTokensForSub = function(sub) return sub.testConditions or {} end } }
    e.FLUX_API = { isRetail = family == "live" }
    local function loadOwner(path) return assert(load(source(path), "@" .. path, "t", e))("_FluxUI", ns) end
    loadOwner("Binding/Core/Action.lua")
    loadOwner("Binding/Core/MacroFactory.lua")
    local factory, action = ns.FluxBindingMacroFactory, ns.FluxBindingAction
    local apply = source("Binding/Core/Apply.lua")
    local first = assert(apply:find("local function MouseoverCastEnabled()", 1, true))
    local last = assert(apply:find("-- Native slot inspection", first, true))
    local enabled = assert(load("local ns=...\n" .. apply:sub(first, last - 1) .. "\nreturn MouseoverCastEnabled", "@apply-global-gate", "t", e))(ns)
    check(enabled(), family .. " binding compiler follows the enabled universal setting")
    local function entry(id, unit, flags)
        local desc = id >= 100 and action.Item(id) or action.Spell(id)
        return { binding = { uid = id, action = desc }, sub = { action = flags or {},
            targets = { hovercastEnabled = false, regularEnabled = true, regular = { { unit = unit or "DEFAULT" } } } } }
    end
    local function build(entries, nativeAction, on)
        counters.compiles = counters.compiles + 1
        local body, clauses = factory.BuildForward({ groups = { { entries = entries } }, native = nativeAction, mouseoverCast = on })
        check(not body or #body <= factory.MacrotextMax(), family .. " generated program stays within existing client limit")
        return body, clauses
    end
    local function cast(body, state, wantToken, wantUnit, why)
        state.player = "friend"
        local token, unit = selectCast(body, state)
        check(token == wantToken and unit == wantUnit, family .. " " .. why .. " got " .. tostring(token) .. "@" .. tostring(unit))
    end
    local nativeHeal = { kind = "spell", id = 10, name = "Heal", token = "Heal" }
    local legacy = entry(10, "DEFAULT")
    legacy.sub.targets.regular = "legacy-invalid-rows"
    local legacyBody = build({ legacy }, nativeHeal, true)
    cast(legacyBody, { mouseover = "friend", target = "enemy" }, "Heal", "mouseover", "legacy non-table rows retain native fallback")
    local body, clauses = build({ entry(10, "DEFAULT", { interrupt = true }) }, nativeHeal, enabled())
    check(body and body:find("/stopcasting", 1, true), family .. " native spell retains interrupt prefix")
    check(factory.StripOverlayMode(body, clauses) == "hidden", family .. " prefix still executes through actual macro delegate")
    cast(body, { mouseover = "friend", target = "enemy" }, "Heal", "mouseover", "native bar spell plus stopcasting")
    cast(body, { mouseover = "enemy", target = "friend" }, "Heal", "target", "native prefix incompatible mouseover fallback")
    check(factory.IsFactoryMouseover(body, clauses, false), family .. " generated mouseover remains an idle-display tail")
    local idle = factory.IdleMacroText(body, true)
    check(not idle:find("mouseover", 1, true) and idle:find("/stopcasting", 1, true), family .. " idle badges keep prefix and omit automatic world hover")
    local reverse = factory.BuildReverse(clauses, 10, "Heal", "Strike")
    check(reverse and reverse:find("Strike", 1, true) and reverse:find("Heal", 1, true), family .. " badge retains both shared-key identities")
    for _, id in ipairs({ 10, 20, 100, 200 }) do
        local token = id >= 100 and "item:" .. id or spells[id]
        local right, wrong = (id == 10 or id == 100) and "friend" or "enemy", (id == 10 or id == 100) and "enemy" or "friend"
        for _, unit in ipairs({ "DEFAULT", "TARGET", "MOUSEOVER" }) do
            local compiled = build({ entry(id, unit) }, nil, unit ~= "MOUSEOVER")
            cast(compiled, { mouseover = right, target = wrong }, token, "mouseover", unit .. " compatible " .. token)
            cast(compiled, { mouseover = wrong, target = right }, token, "target", unit .. " fallback " .. token)
            cast(compiled, { target = right }, token, "target", unit .. " absent mouseover " .. token)
        end
    end
    local nativeStrike = { kind = "spell", id = 20, name = "Strike", token = "Strike" }
    body = build({ entry(10, "TARGET") }, nativeStrike, true)
    cast(body, { mouseover = "enemy", target = "friend" }, "Strike", "mouseover", "all mouseover legs precede target legs")
    cast(body, { mouseover = "friend", target = "enemy" }, "Heal", "mouseover", "binding mouseover precedes native target")
    for _, unit in ipairs({ "FOCUS", "PLAYER", "CURSOR" }) do
        body = build({ entry(10, unit) }, nativeStrike, true)
        cast(body, { focus = "friend", mouseover = "enemy", target = "friend" }, "Heal", unit:lower(), "explicit " .. unit .. " remains authoritative")
    end
    body = build({ entry(10, "DEFAULT") }, nil, false)
    cast(body, { mouseover = "friend", target = "enemy" }, "Heal", "target", "global off leaves default targeting")
    body, clauses = build({ entry(10, "MOUSEOVER") }, nil, false)
    check(not factory.IsFactoryMouseover(body, clauses, false), family .. " explicit mouseover is retained in badge preview")
    local filtered = entry(10, "MOUSEOVER")
    filtered.sub.targets.regular[1].vitals = "DEAD"
    body = build({ filtered }, nil, true)
    cast(body, { mouseover = "friend", target = "friend", targetDead = true }, "Heal", "target", "explicit dead filter applies before fallback")
    cast(body, { mouseover = "friend", mouseoverDead = true, target = "friend" }, "Heal", "mouseover", "explicit dead mouseover remains eligible")
    cast(body, { mouseover = "friend", target = "friend" }, nil, nil, "explicit dead filter is never removed")

    local flags = { interrupt = true, stopSpellTarget = true, cancelQueuedSpell = true, cancelForm = true, startAutoAttack = true, startPetAttack = true }
    body = build({ entry(20, "DEFAULT", flags) }, nativeStrike, true)
    for _, prefix in ipairs({ "/stopcasting", "/stopspelltarget", "/cancelqueuedspell", "/cancelform", "/startattack" }) do
        check(body:find(prefix, 1, true), family .. " keeps " .. prefix)
    end
    check(body:find("/petattack [@mouseover,harm][]", 1, true), family .. " pet attack only prioritizes hostile mouseover")
    local custom = entry(20, "DEFAULT")
    custom.sub.macro = { prefix = "/cast [@focus] Heal" }
    body = build({ custom }, nativeStrike, true)
    cast(body, { focus = "friend", mouseover = "enemy", target = "enemy" }, "Heal", "focus", "user macro prefix remains authoritative")

    for _, desc in ipairs({ action.Spell(10), action.Item(100), action.EquipSlot(13) }) do
        local text = factory.BuildForward({ groups = {}, native = nativeStrike, mouseoverCast = true,
            multiCastExtras = { before = { desc } } })
        local token = desc.type == "slot" and "13" or desc.type == "item" and "item:100" or "Heal"
        cast(text, { mouseover = "friend", target = "enemy" }, token, "mouseover", "multi-cast extra " .. desc.type)
        cast(text, { mouseover = "enemy", target = "friend" }, token, "target", "multi-cast fallback " .. desc.type)
    end

    ns.FluxBindingForms = { GetTokens = function() return { "noform", "form:1" } end, HasMultipleForms = function() return true end,
        ConditionGroupsForTokens = function(tokens) return { { tokens[1] } } end }
    body = factory.BuildForward({ groups = {}, nativesByForm = { noform = nativeHeal, ["form:1"] = nativeStrike }, mouseoverCast = true })
    cast(body, { mouseover = "friend", target = "enemy", form = 0 }, "Heal", "mouseover", "noform uses matching native polarity")
    cast(body, { mouseover = "enemy", target = "friend", form = 1 }, "Strike", "mouseover", "form page uses matching native polarity")
    e.GetSpellSubtext = function() return "Rank 1" end
    body = build({ entry(10, "TARGET", { spellIncludeSubtext = true }) }, nil, true)
    cast(body, { mouseover = "friend", target = "enemy" }, "Heal(Rank 1)", "mouseover", "rank is preserved")
    e.GetSpellSubtext = function() return nil end
    if native then
        f.modifier = "SHIFT"
        body = build({}, nativeHeal, true)
        cast(body, { mouseover = "friend", target = "enemy" }, "Heal", "target", "native modifier not held")
        cast(body, { mouseover = "friend", target = "enemy", shift = true }, "Heal", "mouseover", "native modifier held")
        body = build({ entry(10, "DEFAULT", { startPetAttack = true }) }, nativeHeal, true)
        check(body:find("/petattack [@mouseover,harm,mod:shift][]", 1, true), family .. " pet flag honors native modifier")
    end
end
print(("Resources: clicks=%d actionQueries=%d polarityQueries=%d compiles=%d"):format(counters.clicks, counters.actionQueries, counters.polarityQueries, counters.compiles))
print(("Universal mouseover priority: %d checks, %d failures; native protected execution pending"):format(checks, failures))
assert(failures == 0, "universal mouseover priority regression")
