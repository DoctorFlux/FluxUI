-- Binding/Core/MacroFactory.lua
-- Compiles bindings into macro text (Clicked-style clause merging).
--
-- FORWARD macro  — installed on the bar button (slot program) or pool button
--   (free chord): binding clauses in tier order, then the native bar action's
--   tail clauses (mouseover-cast aware), honoring the key-split fallback.
-- REVERSE macro  — per badge: the badge's own clauses show the bar action and
--   every native/tail clause shows the badge's action, so the badge always
--   previews whatever the main button is currently NOT showing.
--
-- Forms / combat / stealth / etc. are baked as bracket conditionals — nothing
-- rebuilds when they flip.

local addonName, ns = ...

local Factory = {}
ns.FluxBindingMacroFactory = Factory
_G.FluxBindingMacroFactory3 = Factory

local Action = ns.FluxBindingAction
local Conditions = ns.FluxBindingConditions
local FLUX_API = _G.FLUX_API or {}

local function MacrotextMax()
	local Client = ns.Flux and ns.Flux.Client
	local api = _G.FLUX_API
	if (Client and Client.isRetail) or (api and api.isRetail) then
		return 1023
	end
	-- Classic family: named-macro / type=macro macrotext cap.
	return 255
end

function Factory.MacrotextMax()
	return MacrotextMax()
end

-- ---------------------------------------------------------------------------
-- Target model -> bracket parts
-- ---------------------------------------------------------------------------

local UNIT_TOKEN = {
    DEFAULT   = nil,
    PLAYER    = "@player",
    TARGET    = "@target",
    MOUSEOVER = "@mouseover",
    FOCUS     = "@focus",
    CURSOR    = "@cursor",
    PET       = "@pet",
    TARGETTARGET = "@targettarget",
}

local HOSTILITY_TOKEN = { FRIENDLY = "help", HELP = "help", HOSTILE = "harm", HARM = "harm" }
local VITALS_TOKEN = { ALIVE = "nodead", DEAD = "dead" }

-- clause sort: unit-frame/mouseover first, defaults last (docs tier order)
local UNIT_PRIORITY = {
    ["@mouseover"] = 1,
    ["@focus"] = 2,
    ["@target"] = 3,
    ["@targettarget"] = 4,
    ["@pet"] = 5,
    ["@player"] = 6,
    ["@cursor"] = 7,
    [""] = 8, -- DEFAULT
}

local function ClauseCondString(parts)
    if not parts or #parts == 0 then return "" end
    return "[" .. table.concat(parts, ",") .. "]"
end

local function AppendAll(dst, src)
    for i = 1, #src do
        dst[#dst + 1] = src[i]
    end
end

--- One clause: { cond = {parts}, token = "SpellName"|"item:123", owner = uid|"native",
---               tier = 1(hover)|2(regular), unitPrio, seq, petCast = bool }
local function MakeClause(condParts, token, owner, tier, unitPrio, seq, petCast)
    return {
        cond = condParts,
        token = token,
        owner = owner,
        tier = tier or 2,
        unitPrio = unitPrio or 8,
        seq = seq or 0,
        petCast = petCast and true or nil,
    }
end

local function CompareClauses(a, b)
    if a.tier ~= b.tier then return a.tier < b.tier end
    if a.unitPrio ~= b.unitPrio then return a.unitPrio < b.unitPrio end
    -- more specific (more condition parts) first within the same unit
    local an, bn = #a.cond, #b.cond
    if an ~= bn then return an > bn end
    return a.seq < b.seq
end

-- ---------------------------------------------------------------------------
-- Per-entry clause generation
-- ---------------------------------------------------------------------------

--- Build clauses for one binding entry (binding + form sub) into `clauses`.
--- extraCond: form condition parts for grouped slots (may be nil).
local function RegularRowIsDefault(row, castAtCursor)
    if castAtCursor then return false end
    if type(row) ~= "table" then return true end
    if (row.unit or "DEFAULT") ~= "DEFAULT" then return false end
    if (row.hostility or "ANY") ~= "ANY" then return false end
    if (row.vitals or "ANY") ~= "ANY" then return false end
    return true
end

--- True when Targets > Key press has any non-DEFAULT row (or cast-at-cursor).
local function DefinesExplicitRegularTargeting(targets, castAtCursor)
    if castAtCursor then return true end
    if type(targets) ~= "table" or type(targets.regular) ~= "table" then return false end
    for i = 1, #targets.regular do
        if not RegularRowIsDefault(targets.regular[i], false) then
            return true
        end
    end
    return false
end

--- includeHovercast: emit the unit-frame hovercast clause. Only the UF hover
--- emission (BuildHover) sets this — keyboard/badge macros must NOT carry the
--- hovercast [@mouseover], otherwise UF-only targeting acts like global
--- mouseover on world units (V10/Clicked parity: hovercast lives on the
--- flux-macrotext-hovercast routing path only).
--- preferNativeTail: bar slot with a native action — skip unconditional DEFAULT
--- regular rows on keyboard so BuildNativeTail stays reachable (V10 ufOnlyDefault).
local function IsPetActionDesc(castDesc)
    if not castDesc or castDesc.type ~= "spell" then return false end
    if castDesc.pet or (Action.IsPetSpell and Action.IsPetSpell(castDesc)) then
        return true
    end
    local Lib = ns.FluxBindingSpellLibrary
    if castDesc.id and Lib and Lib.IsPetAbilitySpell and Lib.IsPetAbilitySpell(castDesc.id) then
        return true
    end
    return false
end

local function BindingUsesCursor(sub, castAtCursor)
    if castAtCursor then return true end
    local targets = sub and sub.targets
    if type(targets) ~= "table" or type(targets.regular) ~= "table" then return false end
    for i = 1, #targets.regular do
        local row = targets.regular[i]
        if type(row) == "table" and (row.unit == "CURSOR" or row.unit == "cursor") then
            return true
        end
    end
    return false
end

--- Default pet binding (no cursor / custom keypress targeting): contribute
--- /petattack instead of /cast Spell — mouseover variant when global MO cast is on.
local function IsDefaultPetAttackBinding(sub, castAtCursor)
    if castAtCursor then return false end
    if BindingUsesCursor(sub, false) then return false end
    local targets = sub and sub.targets
    if DefinesExplicitRegularTargeting(targets, false) then return false end
    local a = sub and sub.action or {}
    -- Any cast-shaping flag besides startPetAttack means a real cast line.
    if a.castAtCursor or a.preventToggle or a.spellIncludeSubtext
        or a.interrupt or a.cancelForm or a.cancelQueuedSpell
        or a.stopSpellTarget or a.targetUnitAfterCast
        or a.cancelAura
        or (type(a.cancelAuraName) == "string" and a.cancelAuraName:match("%S")) then
        return false
    end
    return true
end

local function BuildEntryClauses(clauses, entry, extraCond, seqBase, includeHovercast, preferNativeTail)
    local binding, sub = entry.binding, entry.sub
    local castDesc = entry.castDesc or binding.action
    local targets = sub.targets or {}
    local isPetAction = IsPetActionDesc(castDesc)
    -- @cursor works on Classic/Anniversary as well as retail (pet ground AoE).
    local castAtCursor = sub.action and sub.action.castAtCursor and true or false
    local usesCursor = BindingUsesCursor(sub, castAtCursor)

    -- Default pet rows on a bar with a native (Summon etc.): /petattack only
    -- until the user sets cursor / custom targeting. Free-chord pet spells still
    -- get a /cast line.
    if isPetAction and not includeHovercast and preferNativeTail
        and IsDefaultPetAttackBinding(sub, castAtCursor) then
        entry._fluxPetAttackOnly = true
        return seqBase
    end

    local preventToggle = sub.action and sub.action.preventToggle
    -- Classic/Anniversary: pet @cursor ground casts need !Spell or they never
    -- fire (retail usually works without it). TBC community form: [@cursor]!Freeze
    if isPetAction and usesCursor and not FLUX_API.isRetail then
        preventToggle = true
    end
    local token = Action.MacroToken(castDesc, {
        includeSubtext = sub.action and sub.action.spellIncludeSubtext,
        preventToggle = preventToggle,
    })
    if not token then return seqBase end

    local baked = Conditions.MacroTokensForSub(sub, binding)
    local bakedNoPet = {}
    for i = 1, #baked do
        local t = baked[i]
        if t ~= "pet" and t ~= "nopet" then
            bakedNoPet[#bakedNoPet + 1] = t
        end
    end
    local seq = seqBase

    local function CondBase()
        local parts = {}
        if extraCond then AppendAll(parts, extraCond) end
        return parts
    end

    -- Hovercast: cast on the unit-frame under the cursor (UF emission only)
    -- nil / missing means enabled (V10 default)
    if includeHovercast and targets.hovercastEnabled ~= false then
        local hc = targets.hovercast or {}
        local parts = CondBase()
        parts[#parts + 1] = "@mouseover"
        local hostility = HOSTILITY_TOKEN[hc.hostility or "ANY"]
        if hostility then parts[#parts + 1] = hostility end
        local vitals = VITALS_TOKEN[hc.vitals or "ANY"]
        if vitals then parts[#parts + 1] = vitals end
        AppendAll(parts, baked)
        seq = seq + 1
        clauses[#clauses + 1] = MakeClause(parts, token, binding.uid, 1, 1, seq, isPetAction)
    end

    -- V10 ufOnlyDefault: keyboard + bar native fallthrough + UF hover on + no
    -- explicit keypress targeting → skip unconditional DEFAULT regular rows.
    -- Baked load conditionals (combat / stealth / … and gated mods) still emit
    -- so [combat] / [mod:alt] peers overlay the bar instead of only native fallthrough.
    local ufOnlyDefault = preferNativeTail
        and (not includeHovercast)
        and (#baked == 0)
        and (targets.hovercastEnabled ~= false)
        and (targets.regularEnabled ~= false)
        and not DefinesExplicitRegularTargeting(targets, castAtCursor)

    -- Regular rows: ordered priority list for key presses
    if targets.regularEnabled ~= false and type(targets.regular) == "table" then
        for i = 1, #targets.regular do
            local row = targets.regular[i]
            if type(row) == "table" then
                local isDefaultRow = RegularRowIsDefault(row, castAtCursor)
                if ufOnlyDefault and isDefaultRow then
                    -- leave fallthrough to native tail
                else
                    local parts = CondBase()
                    local unitToken
                    if castAtCursor then
                        unitToken = "@cursor"
                    else
                        unitToken = UNIT_TOKEN[row.unit or "DEFAULT"]
                    end
                    if unitToken then parts[#parts + 1] = unitToken end
                    local hostility = HOSTILITY_TOKEN[row.hostility or "ANY"]
                    if hostility then parts[#parts + 1] = hostility end
                    local vitals = VITALS_TOKEN[row.vitals or "ANY"]
                    if vitals then parts[#parts + 1] = vitals end

                    if isPetAction and unitToken == "@cursor" then
                        if FLUX_API.isRetail then
                            -- Retail: [@cursor,pet] Freeze on its own /cast line.
                            local hasPet = false
                            for bi = 1, #baked do
                                if baked[bi] == "pet" then hasPet = true break end
                            end
                            if not hasPet then
                                parts[#parts + 1] = "pet"
                            end
                            AppendAll(parts, baked)
                        else
                            -- Classic/Anniversary: [@cursor]!Freeze — do NOT put
                            -- [pet] in the same bracket as @cursor (breaks ground
                            -- cast). Branching is /cast [nopet] Summon on the
                            -- other line.
                            AppendAll(parts, bakedNoPet)
                        end
                    else
                        AppendAll(parts, baked)
                    end

                    seq = seq + 1
                    clauses[#clauses + 1] = MakeClause(
                        parts, token, binding.uid, 2,
                        UNIT_PRIORITY[unitToken or ""] or 8, seq, isPetAction)
                end
            end
        end
    end

    return seq
end

-- ---------------------------------------------------------------------------
-- Native tail
-- ---------------------------------------------------------------------------

local function NativeHelpHarm(native)
    if not native or native.kind ~= "spell" or not native.id then return nil end
    if C_Spell and C_Spell.IsSpellHarmful then
        if C_Spell.IsSpellHarmful(native.id) then return "harm" end
        if C_Spell.IsSpellHelpful and C_Spell.IsSpellHelpful(native.id) then return "help" end
        return nil
    end
    if IsHarmfulSpell and native.name then
        local ok, res = pcall(IsHarmfulSpell, native.name)
        if ok and res then return "harm" end
    end
    if IsHelpfulSpell and native.name then
        local ok, res = pcall(IsHelpfulSpell, native.name)
        if ok and res then return "help" end
    end
    return nil
end

--- Tail clauses for the slot's native action (empty native -> none).
--- formCond: optional bracket parts ("noform", "form:N", …) so multi-form
--- chords can emit host-A under [noform] and host-B under [form:N] in one UF body.
---   mouseover-cast on:  [@mouseover,harm|help|exists,form?] N ; [harm|help,form?] N ; [form?] N
---   mouseover-cast off: [harm|help,form?] N ; [form?] N
local function AppendFormCond(parts, formCond)
    if type(formCond) == "table" then
        for i = 1, #formCond do
            parts[#parts + 1] = formCond[i]
        end
    elseif type(formCond) == "string" and formCond ~= "" then
        for part in formCond:gmatch("[^,]+") do
            parts[#parts + 1] = part
        end
    end
    return parts
end

local function BuildNativeTail(clauses, native, mouseoverCast, fallbackToken, seqBase, formCond)
    local seq = seqBase
    if not native or native.kind == "empty" or native.kind == "macro" or not native.token then
        if fallbackToken and (not formCond or (type(formCond) == "table" and #formCond == 0)) then
            seq = seq + 1
            clauses[#clauses + 1] = MakeClause({}, fallbackToken, "tail", 3, 9, seq)
        end
        return seq
    end
    local helpHarm = NativeHelpHarm(native)
    if mouseoverCast then
        local mo = { "@mouseover" }
        if helpHarm then
            mo[#mo + 1] = helpHarm
        else
            mo[#mo + 1] = "exists"
            mo[#mo + 1] = "nodead"
        end
        AppendFormCond(mo, formCond)
        seq = seq + 1
        clauses[#clauses + 1] = MakeClause(mo, native.token, "native", 3, 8, seq)
    end
    if helpHarm then
        local hh = { helpHarm }
        AppendFormCond(hh, formCond)
        seq = seq + 1
        clauses[#clauses + 1] = MakeClause(hh, native.token, "native", 3, 8, seq)
    end
    local bare = {}
    AppendFormCond(bare, formCond)
    seq = seq + 1
    -- Unconditional bare only when no formCond; otherwise [noform]/[form:N] N.
    -- fallbackToken only on the unconditional final (single-native path).
    local bareToken = (#bare == 0) and (fallbackToken or native.token) or native.token
    clauses[#clauses + 1] = MakeClause(bare, bareToken, "tail", 3, 9, seq)
    return seq
end

-- ---------------------------------------------------------------------------
-- Text assembly
-- ---------------------------------------------------------------------------

-- all six secure commands exist on era / anniversary / retail (verified against
-- the three wow-ui-source trees)
local PREFIX_ORDER = {
    { flag = "interrupt",         line = "/stopcasting" },
    { flag = "stopSpellTarget",   line = "/stopspelltarget" },
    { flag = "cancelQueuedSpell", line = "/cancelqueuedspell" },
    { flag = "cancelForm",        line = "/cancelform" },
    { flag = "startAutoAttack",   line = "/startattack" },
    { flag = "startPetAttack",    line = "/petattack" },
}

--- Resolve cancel-aura edit value (spell id or name) to a /cancelaura token.
local function ResolveCancelAuraToken(value)
    if type(value) == "number" then
        value = tostring(value)
    end
    if type(value) ~= "string" then
        return nil
    end
    value = value:match("^%s*(.-)%s*$") or ""
    if value == "" then
        return nil
    end
    local asId = tonumber(value)
    if asId and asId > 0 then
        local name = Action.GetSpellInfoCompat and select(1, Action.GetSpellInfoCompat(asId))
        if type(name) == "string" and name ~= "" then
            return name
        end
        return nil
    end
    return value
end

local function PrefixLineRank(line)
    for i = 1, #PREFIX_ORDER do
        if PREFIX_ORDER[i].line == line then
            return i
        end
    end
    -- After /cancelform (4), before /startattack (5).
    if type(line) == "string" and line:match("^/cancelaura%s+") then
        return 4.5
    end
    return 100
end

local function CondHasToken(parts, token)
    if type(parts) ~= "table" then return false end
    for i = 1, #parts do
        if parts[i] == token then return true end
    end
    return false
end

local function SegFromClause(c, forceNopet)
    local cond = c.cond
    if forceNopet and (c.owner == "native" or c.owner == "tail")
        and not CondHasToken(cond, "nopet") and not CondHasToken(cond, "pet") then
        local parts = { "nopet" }
        for j = 1, #cond do
            parts[#parts + 1] = cond[j]
        end
        cond = parts
    end
    return ClauseCondString(cond) .. ((#cond > 0) and " " or "") .. c.token
end

local function SegsFromClauses(clauseList, forceNopetOnNative)
    local segs = {}
    local seenUnconditional = false
    for i = 1, #clauseList do
        local c = clauseList[i]
        if seenUnconditional then break end
        segs[#segs + 1] = SegFromClause(c, forceNopetOnNative)
        -- Unconditional bare becomes [nopet] when forced — still terminal for
        -- the summon line (pet line is a separate /cast).
        local cond = c.cond
        local effectiveEmpty = (#cond == 0) and not forceNopetOnNative
        if effectiveEmpty then
            seenUnconditional = true
        elseif forceNopetOnNative and (c.owner == "native" or c.owner == "tail")
            and #cond == 0 then
            -- [nopet] N is conditional — keep scanning sibling native segs
        elseif #cond == 0 then
            seenUnconditional = true
        end
    end
    return segs
end

--- When pet abilities share a key with Summon (etc.), bare native must be
--- [nopet] so both /cast lines can run: summon only when no pet, Freeze when pet.
-- (applied at text assembly only — do not mutate clauses used by BuildReverse)

local function CollectPetAttackLines(entries, mouseoverCast)
    local want = false
    for i = 1, #entries do
        if entries[i]._fluxPetAttackOnly then
            want = true
            break
        end
        local sub = entries[i].sub
        if sub and sub.action and sub.action.startPetAttack then
            want = true
            break
        end
    end
    if not want then return {} end
    -- Single line: /petattack [@mouseover][] (mouseover else default).
    -- Without global mouseover cast: plain /petattack.
    if mouseoverCast then
        return { "/petattack [@mouseover][]" }
    end
    return { "/petattack" }
end

local function CollectPrefixLines(entries)
    local lines, seen = {}, {}
    for i = 1, #entries do
        local sub = entries[i].sub
        local act = sub and sub.action or {}
        for p = 1, #PREFIX_ORDER do
            local def = PREFIX_ORDER[p]
            -- startPetAttack is handled as dedicated /petattack lines (with
            -- optional mouseover) so it is not also duplicated here.
            if def.flag == "startPetAttack" then
                -- skip
            elseif act[def.flag] and not seen[def.line] then
                if not def.retailOnly or FLUX_API.isRetail then
                    seen[def.line] = true
                    lines[#lines + 1] = def.line
                end
            end
        end
        if act.cancelAura then
            local aura = ResolveCancelAuraToken(act.cancelAuraName)
            if aura then
                local line = "/cancelaura " .. aura
                if not seen[line] then
                    seen[line] = true
                    lines[#lines + 1] = line
                end
            end
        end
        local custom = sub and sub.macro and sub.macro.prefix
        if type(custom) == "string" and custom ~= "" and not seen[custom] then
            seen[custom] = true
            lines[#lines + 1] = custom
        end
    end
    table.sort(lines, function(a, b)
        local ai, bi = PrefixLineRank(a), PrefixLineRank(b)
        if ai ~= bi then return ai < bi end
        return a < b
    end)
    return lines
end

local function MultiCastExtraLine(e)
    if type(e) ~= "table" then return nil end
    if e.type == "spell" and e.id then
        local token = Action.MacroToken(Action.Spell(e.id, e.name))
        if token then
            return "/cast " .. token
        end
    elseif e.type == "item" and e.id then
        return "/use item:" .. e.id
    elseif e.type == "slot" and e.id then
        return "/use " .. e.id
    end
    return nil
end

local function CollectExtraLines(extras)
    local out = {}
    if type(extras) ~= "table" then return out end
    for i = 1, #extras do
        local line = MultiCastExtraLine(extras[i])
        if line then
            out[#out + 1] = line
        end
    end
    return out
end

local function ExtraLinesHaveMouseover(extras)
    local lines = CollectExtraLines(extras)
    for i = 1, #lines do
        if type(lines[i]) == "string" and lines[i]:upper():find("MOUSEOVER", 1, true) then
            return true
        end
    end
    return false
end

local function ClausesHaveUserMouseover(clauses)
    for i = 1, #(clauses or {}) do
        local c = clauses[i]
        if c.owner ~= "native" and c.owner ~= "tail" then
            local cond = c.cond
            for j = 1, #(cond or {}) do
                local p = cond[j]
                if p == "@mouseover" or p == "mouseover" then
                    return true
                end
            end
        end
    end
    return false
end

--- Factory Action-Bars mouseover-cast tails (native/tail [@mouseover]), not
--- user targeting / UF hovercast / multi-cast extras. Click keeps those legs;
--- display/index use IdleMacroText(..., true) so the compiled body does not
--- need a #flux-no-mo comment.
function Factory.IsFactoryMouseover(text, clauses, includeHovercast, beforeExtras, afterExtras)
    if type(text) ~= "string" or text == "" then
        return false
    end
    if includeHovercast then
        return false
    end
    if not text:upper():find("MOUSEOVER", 1, true) then
        return false
    end
    if ClausesHaveUserMouseover(clauses) then
        return false
    end
    if ExtraLinesHaveMouseover(beforeExtras) or ExtraLinesHaveMouseover(afterExtras) then
        return false
    end
    return true
end

--- Drop factory [@mouseover] legs for icon/index. forceStrip=true when the
--- caller already knows this is a factory tail (no comment in the body).
--- Leftover #flux-no-mo lines are still dropped if present.
function Factory.IdleMacroText(text, forceStrip)
    if type(text) ~= "string" or text == "" then
        return text
    end
    if not forceStrip and not text:find("#flux-no-mo", 1, true) then
        return text
    end
    local function keepSegs(rest)
        local keep = {}
        local padded = tostring(rest or "") .. ";"
        for seg in padded:gmatch("(.-);") do
            local s = seg:match("^%s*(.-)%s*$") or ""
            if s ~= "" then
                local u = s:upper()
                if not u:find("@MOUSEOVER", 1, true) and not u:find("[MOUSEOVER", 1, true) then
                    keep[#keep + 1] = s
                end
            end
        end
        return keep
    end
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        if line:find("#flux-no-mo", 1, true) then
            -- leftover comment; do not keep
        else
            local trimmed = line:match("^%s*(.-)%s*$") or line
            local cmd = trimmed:lower()
            if cmd:find("^/petattack") then
                local nextLine = trimmed:gsub("%[%s*@mouseover[^%]]*%]", "")
                nextLine = nextLine:gsub("%[%s*%]", "")
                nextLine = (nextLine:match("^%s*(.-)%s*$") or nextLine)
                if nextLine:find("^/petattack") then
                    if nextLine:match("^/petattack%s*$") then
                        lines[#lines + 1] = "/petattack"
                    else
                        lines[#lines + 1] = nextLine
                    end
                end
            else
                local verb, rest = trimmed:match("^(/%a+)%s+(.*)$")
                local vlow = verb and verb:lower()
                if vlow == "/cast" or vlow == "/use" then
                    local keep = keepSegs(rest)
                    if #keep > 0 then
                        lines[#lines + 1] = verb .. " " .. table.concat(keep, "; ")
                    end
                else
                    lines[#lines + 1] = line
                end
            end
        end
    end
    local out = table.concat(lines, "\n")
    if out == "" then
        return text
    end
    return out
end

--- Peer binding clauses (not only native bar / factory tail).
function Factory.HasPeerOverlay(clauses)
    if type(clauses) ~= "table" then
        return false
    end
    for i = 1, #clauses do
        local owner = clauses[i] and clauses[i].owner
        if owner and owner ~= "native" and owner ~= "tail" then
            return true
        end
    end
    return false
end

--- True when the compiled body must run on a hidden SAB (sequences, petattack,
--- multi-cast inject, user [@mouseover] keyboard overlay). Peer/badge
--- conditionals use ephemeral macrotext on the visible strip instead.
function Factory.NeedsHiddenClick(text, clauses, extras)
    if type(text) ~= "string" or text == "" then
        return false
    end
    if type(extras) == "table" then
        local before = extras.before
        local after = extras.after
        if (type(before) == "table" and #before > 0)
            or (type(after) == "table" and #after > 0) then
            return true
        end
        if extras.before == nil and extras.after == nil and #extras > 0 then
            return true
        end
    end
    if text:find("/stopcasting", 1, true)
        or text:find("/stopspelltarget", 1, true)
        or text:find("/cancelqueuedspell", 1, true)
        or text:find("/cancelform", 1, true)
        or text:find("/cancelaura", 1, true)
        or text:find("/startattack", 1, true)
        or text:find("/petattack", 1, true)
        or text:find("/castsequence", 1, true) then
        return true
    end
    if text:upper():find("MOUSEOVER", 1, true) then
        local before, after
        if type(extras) == "table" then
            before, after = extras.before, extras.after
            if before == nil and after == nil then
                after = extras
            end
        end
        if Factory.IsFactoryMouseover(text, clauses, false, before, after) then
            return false
        end
        return true
    end
    return false
end

--- Install a strip overlay: "surface" = visible type=macro+macrotext, "display" =
--- native-only factory tail (type=action click + ephemeral display face), "hidden" =
--- legacy FluxSlotClick_<slot>.
function Factory.StripOverlayMode(text, clauses, extras)
    if type(text) ~= "string" or text == "" then
        return nil
    end
    if Factory.NeedsHiddenClick(text, clauses, extras) then
        return "hidden"
    end
    if Factory.HasPeerOverlay(clauses) then
        return "surface"
    end
    return "display"
end

--- Resolve before/after extras from Factory ctx (supports split table or legacy flat after-list).
local function ResolveMultiCastSplit(ctx)
    local m = ctx and ctx.multiCastExtras
    if type(m) == "table" and (m.before ~= nil or m.after ~= nil) then
        return m.before, m.after
    end
    local before = ctx and ctx.multiCastExtrasBefore
    local after = ctx and ctx.multiCastExtrasAfter
    if before or after then
        return before, after
    end
    -- Legacy: flat array = all after main.
    if type(m) == "table" and #m > 0 then
        return nil, m
    end
    return nil, nil
end

--- Insert multi-cast /cast|/use lines before and/or after the native macro body.
--- When extras cast *before* the native, pin `#showtooltip <native>` so the
--- action-bar icon stays on the bar spell (otherwise the first /cast wins).
local function InjectMultiCastExtraLines(text, beforeExtras, afterExtras, native)
    local beforeLines = CollectExtraLines(beforeExtras)
    local afterLines = CollectExtraLines(afterExtras)
    if #beforeLines == 0 and #afterLines == 0 then
        return text
    end
    local lines = {}
    if type(text) == "string" and text ~= "" then
        for line in text:gmatch("[^\r\n]+") do
            lines[#lines + 1] = line
        end
    else
        lines[1] = "#showtooltip"
    end

    -- Keep bar icon on the native action when pre-casts exist.
    if #beforeLines > 0 and native and native.token
        and native.kind ~= "empty" and native.kind ~= "macro" then
        local tip = "#showtooltip " .. tostring(native.token)
        if lines[1] and tostring(lines[1]):lower():find("^#showtooltip", 1) then
            lines[1] = tip
        else
            table.insert(lines, 1, tip)
        end
    end

    local insertAt = 1
    if lines[1] and tostring(lines[1]):lower():find("^#showtooltip", 1) then
        insertAt = 2
    end
    for i = #beforeLines, 1, -1 do
        table.insert(lines, insertAt, beforeLines[i])
    end
    for i = 1, #afterLines do
        lines[#lines + 1] = afterLines[i]
    end
    local out = table.concat(lines, "\n")
    local maxLen = MacrotextMax()
    if #out > maxLen then
        -- Drop trailing (after) extras first, then leading (before) extras.
        while #out > maxLen and #lines > 2 do
            local removed = false
            if #afterLines > 0 then
                table.remove(lines)
                afterLines[#afterLines] = nil
                removed = true
            elseif #beforeLines > 0 and insertAt <= #lines then
                table.remove(lines, insertAt)
                table.remove(beforeLines)
                removed = true
            end
            if not removed then
                break
            end
            out = table.concat(lines, "\n")
        end
    end
    return out
end

local function AppendMultiCastExtraLines(text, extras)
    return InjectMultiCastExtraLines(text, nil, extras, nil)
end

local function ClausesToText(clauses, prefixLines, petAttackLines)
    if #clauses == 0 and not (petAttackLines and #petAttackLines > 0) then
        return nil
    end

    local petClauses, otherClauses = {}, {}
    for i = 1, #clauses do
        local c = clauses[i]
        if c.petCast then
            petClauses[#petClauses + 1] = c
        else
            otherClauses[#otherClauses + 1] = c
        end
    end

    -- With a pet /cast line, drop mouseover/help native legs so summon is just
    -- [nopet] Summon … (matches the known-working Freeze macro).
    if #petClauses > 0 then
        local simple = {}
        for i = 1, #otherClauses do
            local c = otherClauses[i]
            if c.owner ~= "native" and c.owner ~= "tail" then
                simple[#simple + 1] = c
            elseif c.owner == "tail" or #(c.cond or {}) == 0 then
                simple[#simple + 1] = c
            end
        end
        if #simple > 0 then
            otherClauses = simple
        end
    end

    local useUse = false
    for i = 1, #clauses do
        if clauses[i].token:find("^item:") then
            useUse = true
            break
        end
    end
    local castVerb = useUse and "/use " or "/cast "

    local out = { "#showtooltip" }
    if prefixLines then
        for i = 1, #prefixLines do
            out[#out + 1] = prefixLines[i]
        end
    end

    -- Working form (exact community order):
    --   /cast [nopet] Summon Water Elemental
    --   /cast [@cursor,pet]Freeze
    --   /petattack [@mouseover][]
    local forceNopet = #petClauses > 0
    local otherSegs = SegsFromClauses(otherClauses, forceNopet)
    local petSegs = SegsFromClauses(petClauses, false)
    if #otherSegs > 0 then
        out[#out + 1] = castVerb .. table.concat(otherSegs, "; ")
    end
    if #petSegs > 0 then
        local petLine = castVerb .. table.concat(petSegs, "; ")
        petLine = petLine:gsub("%] ", "]")
        out[#out + 1] = petLine
    end
    if #petSegs == 0 and #otherSegs == 0 and #(petAttackLines or {}) == 0
        and not (prefixLines and #prefixLines > 0) then
        return nil
    end

    if petAttackLines then
        for i = 1, #petAttackLines do
            out[#out + 1] = petAttackLines[i]
        end
    end

    local text = table.concat(out, "\n")
    local maxLen = MacrotextMax()
    if #text > maxLen then
        while #text > maxLen and #otherSegs > 1 do
            table.remove(otherSegs, #otherSegs - 1)
            out = { "#showtooltip" }
            if prefixLines then
                for i = 1, #prefixLines do out[#out + 1] = prefixLines[i] end
            end
            if #otherSegs > 0 then
                out[#out + 1] = castVerb .. table.concat(otherSegs, "; ")
            end
            if #petSegs > 0 then
                local petLine = castVerb .. table.concat(petSegs, "; ")
                petLine = petLine:gsub("%] ", "]")
                out[#out + 1] = petLine
            end
            if petAttackLines then
                for i = 1, #petAttackLines do out[#out + 1] = petAttackLines[i] end
            end
            text = table.concat(out, "\n")
        end
    end
    return text
end

-- ---------------------------------------------------------------------------
-- Public build API
-- ---------------------------------------------------------------------------

--- Build the forward slot/free-chord macro + its clause list.
--- ctx = {
---   groups = { { formCond = {parts}|nil, entries = { {binding, sub} } }, ... },
---   native = { kind, id, name, token } | nil,
---   nativesByForm = { [formToken] = native } | nil,  -- multi-form UF hover tails
---   mouseoverCast = bool,
---   fallbackToken = string|nil,
---   includeHovercast = bool,
---   forceNativeTail = bool,
--- }
--- returns text|nil, clauses
function Factory.BuildForward(ctx)
    local clauses = {}
    local seq = 0
    local allEntries = {}
    local hasNativesByForm = type(ctx.nativesByForm) == "table" and next(ctx.nativesByForm) ~= nil
    local preferNativeTail = hasNativesByForm
        or (ctx.native and ctx.native.token
            and ctx.native.kind ~= "empty" and ctx.native.kind ~= "macro")
    for g = 1, #ctx.groups do
        local group = ctx.groups[g]
        for e = 1, #group.entries do
            local entry = group.entries[e]
            -- Rank-sync: cast the bar slot's rank, share settings from the family binding.
            if ctx.native and ctx.native.kind == "spell" and ctx.native.id
                and entry.binding and entry.binding.action
                and Action.IsRankSyncByName and Action.IsRankSyncByName(entry.binding.action) then
                entry = {
                    binding = entry.binding,
                    sub = entry.sub,
                    castDesc = Action.Spell(ctx.native.id, ctx.native.name),
                }
            end
            seq = BuildEntryClauses(clauses, entry, group.formCond, seq,
                ctx.includeHovercast, preferNativeTail)
            allEntries[#allEntries + 1] = entry
        end
    end
    if #clauses == 0 and not ctx.forceNativeTail and not preferNativeTail then
        return nil, clauses
    end
    table.sort(clauses, CompareClauses)

    if hasNativesByForm then
        local Forms = ns.FluxBindingForms
        local tokens = (Forms and Forms.GetTokens and Forms.GetTokens()) or {}
        local multi = Forms and Forms.HasMultipleForms and Forms.HasMultipleForms()
        local clusterOrder, byKey = {}, {}
        for ti = 1, #tokens do
            local token = tokens[ti]
            local native = ctx.nativesByForm[token]
            if native and native.token and native.kind ~= "empty" and native.kind ~= "macro" then
                local key = tostring(native.kind) .. ":" .. tostring(native.token)
                local c = byKey[key]
                if not c then
                    c = { native = native, tokens = {} }
                    byKey[key] = c
                    clusterOrder[#clusterOrder + 1] = c
                end
                c.tokens[#c.tokens + 1] = token
            end
        end
        local tokenCount = #tokens
        for ci = 1, #clusterOrder do
            local c = clusterOrder[ci]
            local isLast = (ci == #clusterOrder)
            if (not multi) or #c.tokens == tokenCount then
                local fb = isLast and ctx.fallbackToken or nil
                seq = BuildNativeTail(clauses, c.native, ctx.mouseoverCast, fb, seq, nil)
            else
                local condGroups = (Forms and Forms.ConditionGroupsForTokens)
                    and Forms.ConditionGroupsForTokens(c.tokens) or {}
                for gi = 1, #condGroups do
                    seq = BuildNativeTail(clauses, c.native, ctx.mouseoverCast, nil, seq, condGroups[gi])
                end
            end
        end
    else
        seq = BuildNativeTail(clauses, ctx.native, ctx.mouseoverCast, ctx.fallbackToken, seq, nil)
    end

    local text = ClausesToText(
        clauses,
        CollectPrefixLines(allEntries),
        CollectPetAttackLines(allEntries, ctx.mouseoverCast)
    )
    local beforeExtras, afterExtras = ResolveMultiCastSplit(ctx)
    local hasExtras = (type(beforeExtras) == "table" and #beforeExtras > 0)
        or (type(afterExtras) == "table" and #afterExtras > 0)
    if (not text) and hasExtras
        and ctx.native and ctx.native.token
        and ctx.native.kind ~= "empty" and ctx.native.kind ~= "macro" then
        local verb = (ctx.native.kind == "item" or tostring(ctx.native.token):find("^item:"))
            and "/use " or "/cast "
        text = "#showtooltip\n" .. verb .. ctx.native.token
    end
    text = InjectMultiCastExtraLines(text, beforeExtras, afterExtras, ctx.native)
    return text, clauses
end

--- UF hover emission: same groups/native, but hovercast [@mouseover] clauses
--- lead (tier 1), then keyboard fallthrough legs, then the native tail. This
--- body routes through flux-macrotext-hovercast / SetUfHoverRouting and only
--- ever fires while the cursor is over a registered unit frame.
function Factory.BuildHover(ctx)
    local hctx = {
        groups = ctx.groups,
        native = ctx.native,
        nativesByForm = ctx.nativesByForm,
        mouseoverCast = ctx.mouseoverCast,
        fallbackToken = ctx.fallbackToken,
        includeHovercast = true,
        forceNativeTail = ctx.forceNativeTail,
        multiCastExtras = ctx.multiCastExtras,
    }
    return Factory.BuildForward(hctx)
end

--- Static badge macro for a binding that contributes no keyboard clauses
--- (UF-only hovercast, keypress targets off): the badge just shows its own
--- action, unconditionally.
function Factory.BuildStaticBadge(badgeToken)
    if not badgeToken then return nil end
    local useUse = badgeToken:find("^item:") ~= nil
    return "#showtooltip\n" .. (useUse and "/use " or "/cast ") .. badgeToken
end

--- Reverse (badge) macro for one badge owner uid, derived from the forward
--- clause list:
---   * badge owner's clauses -> the counter token (bar action / stack top)
---   * native / tail clauses -> the badge action
---   * other bindings' clauses -> dropped
---
--- Pet + @cursor owners: badge display always uses the retail-style reverse
---   [@cursor,pet] Summon; [@mouseover,exists,nodead] Freeze; Freeze
--- even when the forward bar macro is Classic [@cursor]!Freeze + [nopet] Summon.
local function EnsureCursorPetCond(cond)
    local parts = {}
    local hasCursor, hasPet = false, false
    for i = 1, #(cond or {}) do
        local t = cond[i]
        parts[#parts + 1] = t
        if t == "@cursor" then
            hasCursor = true
        elseif t == "pet" then
            hasPet = true
        end
    end
    if hasCursor and not hasPet then
        -- Insert pet immediately after @cursor.
        local out = {}
        for i = 1, #parts do
            out[#out + 1] = parts[i]
            if parts[i] == "@cursor" then
                out[#out + 1] = "pet"
            end
        end
        return out
    end
    return parts
end

local function CondHasAt(cond, token)
    for i = 1, #(cond or {}) do
        if cond[i] == token then return true end
    end
    return false
end

function Factory.BuildReverse(clauses, badgeUid, badgeToken, counterToken)
    if not clauses or #clauses == 0 or not badgeToken then return nil end

    local ownerIsPetCast = false
    for i = 1, #clauses do
        local c = clauses[i]
        if c.owner == badgeUid and c.petCast then
            ownerIsPetCast = true
            break
        end
    end

    local segs = {}
    local useUse = (badgeToken:find("^item:") ~= nil)
        or (counterToken and counterToken:find("^item:") ~= nil)
    local seenUnconditional = false
    local emittedMouseover = false

    for i = 1, #clauses do
        local c = clauses[i]
        if seenUnconditional then break end
        local token
        local cond = c.cond
        if c.owner == badgeUid then
            token = counterToken or badgeToken
            if c.petCast then
                cond = EnsureCursorPetCond(c.cond)
            end
        elseif c.owner == "native" or c.owner == "tail" then
            token = badgeToken
            if ownerIsPetCast then
                if CondHasAt(c.cond, "@mouseover") then
                    -- Canonical badge mouseover leg for pet abilities.
                    cond = { "@mouseover", "exists", "nodead" }
                    if emittedMouseover then
                        token = nil
                    else
                        emittedMouseover = true
                    end
                elseif #(c.cond or {}) > 0 and not CondHasAt(c.cond, "@cursor") then
                    -- Skip [help]/[harm] native-only legs on pet badge reverse.
                    token = nil
                end
            end
        end
        if token then
            segs[#segs + 1] = ClauseCondString(cond)
                .. ((cond and #cond > 0) and " " or "") .. token
            if not cond or #cond == 0 then
                seenUnconditional = true
            end
        end
    end

    -- Pet badge with mouseover cast off: still show the familiar MO leg when a
    -- counter (Summon) exists, matching the requested badge shape.
    if ownerIsPetCast and counterToken and not emittedMouseover and not seenUnconditional then
        local mo = ClauseCondString({ "@mouseover", "exists", "nodead" })
            .. " " .. badgeToken
        -- Insert after the first (cursor) seg when present.
        if #segs >= 1 then
            table.insert(segs, 2, mo)
        else
            segs[#segs + 1] = mo
        end
    end

    if #segs == 0 then return nil end
    if not seenUnconditional then
        segs[#segs + 1] = badgeToken
    end
    local text = "#showtooltip\n" .. (useUse and "/use " or "/cast ") .. table.concat(segs, "; ")
    local maxLen = MacrotextMax()
    if #text > maxLen then
        text = text:sub(1, maxLen)
    end
    return text
end
