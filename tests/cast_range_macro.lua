-- Real EBS Action parser: range identity/unit must follow the cast command,
-- independently of #showtooltip and the stable badge/strip display body.
-- SecureCmdOptionParse and sequence state are bounded desktop models.
local root = arg[1]
local function read(path)
    local f = root and io.open(root .. "/" .. path, "rb")
    f = f or assert(io.open(path, "rb"))
    local body = f:read("*a"); f:close(); return body
end
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local s = { alt = false, shift = false, peek = false, exists = { target = true, focus = true, mouseover = true, player = true } }
local spells = { frostbolt = 101, heal = 102, pinned = 103, ward = 104 }
local items = { healthstone = 201 }
local env = setmetatable({}, { __index = _G }); env._G = env
env.FluxButton = {}
env.UnitExists = function(unit) return s.exists[unit] == true end
env.GetTime = function() return 1 end
env.C_Spell = { GetSpellIDForSpellIdentifier = function(value)
    return type(value) == "string" and spells[value:lower()]
end }
env.C_Item = { GetItemInfoInstant = function(value)
    return type(value) == "string" and items[value:lower()]
end }
env.GetInventoryItemID = function(_, slot) return slot == 13 and 213 or nil end
env.SecureCmdOptionParse = function(options)
    for part in (options .. ";"):gmatch("(.-);") do
        local cond, token = part:match("^%s*%[([^%]]*)%]%s*(.-)%s*$")
        if not cond then token = part:match("^%s*(.-)%s*$") end
        local matches, unit = true, nil
        for rule in (cond or ""):gmatch("[^,]+") do
            if rule:sub(1, 1) == "@" then unit = rule:sub(2)
            elseif rule == "mod:alt" then matches = matches and s.alt
            elseif rule == "nomod:alt" then matches = matches and not s.alt
            elseif rule == "mod:shift" then matches = matches and s.shift
            elseif rule == "exists" then matches = matches and s.exists[unit or "target"] == true
            else error("unmodeled conditional " .. rule) end
        end
        if matches and token then return token, unit end
    end
end
local flux = { EBS = { buttons = {}, badges = {} } }
local ns = { Flux = flux }
env.Flux = flux
env.FluxMouseoverKeybindModule = { IsHovercastPeekMouseContext = function() return s.peek end }
assert(load(read("ExtraButtonSystem/Engine/Action.lua"), "@Action.lua", "t", env))("_FluxUI", ns)
local action = flux.EBS.Action
check(type(action.CastFromBody) == "function", "actual parser API exists")
check(type(action.CastForRange) == "function", "actual consumer API exists")
if not action.CastFromBody or not action.CastForRange then os.exit(1) end
local function cast(body, kind, id, unit, label)
    local k, i, u = action.CastFromBody(body)
    check(k == kind and i == id and u == unit, label)
end
cast("#showtooltip Pinned\n/cast [@focus] Frostbolt", "spell", 101, "focus", "pinned tooltip does not own cast target/identity")
cast("#showtooltip [@mouseover] Heal\n/cast [@target] Frostbolt", "spell", 101, "target", "tooltip unit cannot replace explicit cast target")
cast("#showtooltip\n/stopcasting\n/cast Frostbolt", "spell", 101, "target", "bare hint and harmless prefix retain default cast target")
for _, unit in ipairs({ "focus", "target", "mouseover", "player", "cursor", "pet", "targettarget" }) do
    cast("/cast [@" .. unit .. "] Ward", "spell", 104, unit, "explicit " .. unit .. " preserved")
end
cast("/USE [@focus] item:201", "item", 201, "focus", "uppercase use retains item target")
cast("/spell [@mouseover] Heal", "spell", 102, "mouseover", "spell alias uses cast options")
cast("/use 13", "item", 213, "target", "inventory item resolved without effect spell")
cast("/cast !Frostbolt", "spell", 101, "target", "prevent-toggle marker retains cast identity")
cast("/cast UncachedSpell", "spell", "UncachedSpell", "target", "cold spell name remains range-queryable")
cast("/cast [mod:alt,@focus] Frostbolt\n/cast [@mouseover] Heal", "spell", 102, "mouseover", "inactive first command permits next eligible cast")
s.alt = true
cast("/cast [mod:alt,@focus] Frostbolt\n/cast [@mouseover] Heal", "spell", 101, "focus", "active first command owns bounded cast context")
s.alt = false
for _, body in ipairs({ "", "#showtooltip Frostbolt", "/stopcasting", "/cast [mod:alt] Frostbolt" }) do
    cast(body, nil, nil, nil, "no active cast is authoritative")
end
for _, command in ipairs({ "/target", "/targetexact", "/targetenemy", "/assist", "/focus", "/clearfocus", "/cleartarget", "/click", "/castrandom", "/userandom" }) do
    cast(command .. " Friend\n/cast Frostbolt", nil, nil, nil, "unknown delegate/target transition " .. command)
end
cast("/stopmacro [mod:shift]\n/cast Frostbolt", "spell", 101, "target", "inactive stopmacro permits later cast")
s.shift = true
cast("/stopmacro [mod:shift]\n/cast Frostbolt", nil, nil, nil, "active stopmacro prevents invented later cast")
cast("/stopmacro\n/cast Frostbolt", nil, nil, nil, "unconditional empty-string stopmacro result is truthy")
cast("/cast Frostbolt\n/stopmacro [mod:shift]\n/cast Heal", "spell", 101, "target", "stop after first eligible cast does not remove that cast")
s.shift = false
local sequence = "reset=target Frostbolt, Heal"
env.QueryCastSequence = function(text)
    check(text == sequence, "sequence query receives complete active options")
    return 2, nil, "Heal"
end
cast("/castsequence [@focus] " .. sequence, "spell", 102, "focus", "native sequence query owns current spell")
env.QueryCastSequence = function() return 2, "Healthstone", "Heal" end
cast("/castsequence " .. sequence, "item", 201, "target", "sequence item takes priority over its reported effect spell")
env.QueryCastSequence = function() return 2, "UncachedItem", "Heal" end
cast("/castsequence " .. sequence, "item", "UncachedItem", "target", "cold sequence item remains an item identity")
env.QueryCastSequence = function() return 1, "13", nil end
cast("/castsequence " .. sequence, "item", 213, "target", "sequence inventory slot resolves current equipped item")
env.QueryCastSequence = function() return 2, nil, nil end
cast("/castsequence " .. sequence, nil, nil, nil, "empty native sequence step does not invent first cast")
env.QueryCastSequence = function() error("unavailable") end
cast("/castsequence [@focus] " .. sequence, nil, nil, nil, "query failure cannot invent current sequence step")
env.QueryCastSequence = nil
cast("/castsequence " .. sequence, nil, nil, nil, "absent query cannot invent current sequence step")
cast("/castsequence reset=target Frostbolt", nil, nil, nil, "unavailable single-token sequence remains unknown")

local function context(btn, kind, id, unit, handled, label)
    local k, i, u, h = action.CastForRange(btn)
    check(k == kind and i == id and u == unit and h == handled, label)
end
local btn = { ActionType = "macrotext", ActionValue = "/cast [@focus] Frostbolt",
    MacroBody = "#showtooltip Pinned\n/cast [@focus] Frostbolt", MacroTarget = "mouseover", SpellId = 103 }
context(btn, "spell", 101, "focus", true, "ordinary macro ignores stale display identity/unit")
check(btn.MacroTarget == "mouseover" and btn.SpellId == 103 and btn.MacroBody:find("Pinned", 1, true), "range parser does not mutate display/action")
btn.MacroBody = "/cast [mod:alt] Frostbolt"
context(btn, nil, nil, nil, true, "inactive macro remains handled instead of falling through to display")
btn._fluxUtilityGetEntry = function() return { type = "spell", id = 104 } end
context(btn, nil, nil, nil, false, "exact native utility entry retains its existing route")
btn._fluxUtilityGetEntry = nil
btn.ActionType, btn.MacroIndex, btn.MacroBody = "macro", 1, "/cast Heal"
env.GetMacroInfo = function(index)
    check(index == 1, "native macro index preserved")
    return "Live", 1, "/cast [@focus] Frostbolt"
end
context(btn, "spell", 101, "focus", true, "macro index reads current body without changing cached display")
check(btn.MacroBody == "/cast Heal", "live macro read leaves cached display body unchanged")
env.GetMacroInfo = function() error("not available") end
context(btn, "spell", 102, "target", true, "temporarily unavailable live macro retains saved body")
local badge = { ActionType = "macrotext", MacroBody = "/cast Pinned", _fluxWant = {
    macrotext = "/cast [@target] Ward", rangeMacrotext = "/cast [@focus] Frostbolt",
    hoverMacrotext = "/cast [@mouseover] Heal" } }
context(badge, "spell", 101, "focus", true, "badge range uses full metadata instead of displayed idle body")
s.peek = true
context(badge, "spell", 102, "mouseover", true, "strict UF peek selects configured hover range body")
s.peek = false
context(badge, "spell", 101, "focus", true, "world cursor restores regular range body")
badge._fluxWant.rangeClauses = {
    { token = "Heal", cond = { "mod:alt", "@focus" } },
    { token = "Frostbolt", cond = { "@target" } },
}
badge._fluxWant.rangeHoverClauses = {
    { token = "Heal", cond = { "@mouseover" } },
    { token = "Frostbolt", cond = { "@focus" } },
}
badge.MacroMode, badge.SpellId = "spell", 101
s.alt = true
context(badge, "spell", 101, "target", true, "reverse native token does not inherit binding focus target")
badge.SpellId = 102
context(badge, "spell", 102, "focus", true, "reverse binding token uses its own original focus clause")
s.alt = false
context(badge, nil, nil, nil, true, "inactive original binding clause does not invent a target from native reverse")
s.peek = true
context(badge, "spell", 102, "mouseover", true, "strict hover metadata uses original hover clause")
badge.SpellId = 101
context(badge, "spell", 101, "focus", true, "hover reverse native token retains original native clause target")
badge.SpellId = 999
context(badge, nil, nil, nil, true, "unmatched stale display identity cannot inherit unrelated clause target")
flux.Spell = { IdsMatch = function(a, b) return a == 101 and b == 999 end }
context(badge, "spell", 101, "focus", true, "public spell override matching preserves original clause identity")
s.peek = false
badge._fluxWant.rangeClauses = { { token = "item:201", cond = { "@focus" } } }
badge.MacroMode, badge.ItemId, badge.SpellId = "item", 201, nil
context(badge, "item", 201, "focus", true, "badge original item clause remains an item target")
context({ ActionType = "spell", SpellId = 101 }, nil, nil, nil, false, "plain spell remains owned by native mouseover target resolver")
print(("Cast range macro: %d checks, %d failures"):format(checks, failures))
os.exit(failures > 0 and 1 or 0)
