-- Binding/Core/Conditions.lua
-- Load gates + macro-conditional mapping for binding sub-profiles.
--
-- Two families (Clicked-style):
--   * LOAD gates   — evaluated in Lua on rare events (spell learned / item
--     owned via FluxInv, equipped, zone, instance, spec). Failing gates drop
--     the binding from generated macros entirely.
--   * MACRO conditionals — combat / stealth / mounted / pet / outdoors /
--     swimming / flying / channeling. Baked into the macro as [combat] etc.
--     so NOTHING rebuilds when they flip (the client evaluates them).
--   * Gated modifier conditionals — mod:alt / mod:shift+mod:ctrl when the
--     binding shares an action-bar key (see CanOfferMod*).

local addonName, ns = ...

local Conditions = {}
ns.FluxBindingConditions = Conditions
_G.FluxBindingConditions3 = Conditions

local Action = ns.FluxBindingAction

-- ---------------------------------------------------------------------------
-- Macro conditionals
-- ---------------------------------------------------------------------------

local MACRO_OPTION_TOKENS = {
    combat     = { [true] = "combat",   [false] = "nocombat" },
    stealth    = { [true] = "stealth",  [false] = "nostealth" },
    mounted    = { [true] = "mounted",  [false] = "nomounted" },
    pet        = { [true] = "pet",      [false] = "nopet" },
    outdoors   = { [true] = "outdoors", [false] = "indoors" },
    swimming   = { [true] = "swimming", [false] = "noswimming" },
    flying     = { [true] = "flying",   [false] = "noflying" },
    channeling = { [true] = "channeling", [false] = "nochanneling" },
}
Conditions.MACRO_OPTION_TOKENS = MACRO_OPTION_TOKENS

--- Editor overlap for gated mod conditions (shared bar key).
local function EditorOverlap(binding)
    if not binding or not binding.action then return nil end
    local FB = _G.FluxBinding
    if not FB or not FB.GetEditorOverlap then return nil end
    return FB.GetEditorOverlap(binding.action, binding.uid)
end

--- True when Placement chords for this slot include both SHIFT- and CTRL- variants
--- (SmartLayout "Shift/Ctrl" shared mini).
local function SlotHasShiftAndCtrlChords(slot)
    slot = tonumber(slot)
    if not slot then return false end
    local Placement = ns.FluxBindingPlacement
    local CM = ns.FluxBindingChordMap
    if not Placement or not Placement.DescribeBarSlot or not CM or not CM.Parse then
        return false
    end
    local d = Placement.DescribeBarSlot(slot)
    if not d or type(d.chords) ~= "table" then return false end
    local hasShift, hasCtrl = false, false
    for i = 1, #d.chords do
        local _, mods = CM.Parse(d.chords[i])
        if mods then
            if mods.shift then hasShift = true end
            if mods.ctrl then hasCtrl = true end
        end
    end
    return hasShift and hasCtrl
end
Conditions.SlotHasShiftAndCtrlChords = SlotHasShiftAndCtrlChords

--- True when the column has no SHIFT mini and no CTRL mini actions.
local function ColumnHasNoMinis(col)
    col = tonumber(col)
    if not col then return false end
    local State = ns.FluxActionBarState or _G.FluxActionBarState
    if not State or not State.GetSecondarySlot or not State.GetTertiarySlot then
        return false
    end
    if not HasAction then return false end
    local sec = State.GetSecondarySlot(col)
    local tert = State.GetTertiarySlot(col)
    local hasSec = sec and HasAction(sec)
    local hasTert = tert and HasAction(tert)
    return (not hasSec) and (not hasTert)
end
Conditions.ColumnHasNoMinis = ColumnHasNoMinis

--- Alt modifier condition: only when the spell/item shares an action-bar key.
function Conditions.CanOfferModAlt(binding)
    local info = EditorOverlap(binding)
    return info and info.route and info.route.kind == "slot" and true or false
end

--- SHIFT+CTRL condition: shared bar key AND (
---   on SHIFT mini, or Shift/Ctrl shared mini, or main with no minirows in that column).
function Conditions.CanOfferModShiftCtrl(binding)
    local info = EditorOverlap(binding)
    if not (info and info.route and info.route.kind == "slot") then
        return false
    end
    if info.route.row == "secondary" then
        return true
    end
    if SlotHasShiftAndCtrlChords(info.slot) then
        return true
    end
    -- Main (or promoted-as-main) with an empty mini column: Shift+Ctrl is free to use.
    if (info.route.row == "main" or not info.route.row) and ColumnHasNoMinis(info.route.col) then
        return true
    end
    return false
end

--- Selected mod flags after gating (stale selections ignored when gate fails).
--- When binding is nil, selected flags are returned as-is (preview without gate).
function Conditions.ResolvedModFlags(sub, binding)
    local load = sub and sub.load
    if type(load) ~= "table" then
        return false, false
    end
    local wantAlt = type(load.modAlt) == "table" and load.modAlt.selected and true or false
    local wantSC = type(load.modShiftCtrl) == "table" and load.modShiftCtrl.selected and true or false
    if binding then
        if wantAlt and not Conditions.CanOfferModAlt(binding) then
            wantAlt = false
        end
        if wantSC and not Conditions.CanOfferModShiftCtrl(binding) then
            wantSC = false
        end
    end
    return wantAlt, wantSC
end

function Conditions.SubHasModCondition(sub, binding)
    local wantAlt, wantSC = Conditions.ResolvedModFlags(sub, binding)
    return wantAlt or wantSC
end

--- Clear invalid mod selections on all form subs (editor / commit).
function Conditions.SanitizeModLoadOptions(binding)
    if not binding or type(binding.forms) ~= "table" then return end
    local canAlt = Conditions.CanOfferModAlt(binding)
    local canSC = Conditions.CanOfferModShiftCtrl(binding)
    for _, sub in pairs(binding.forms) do
        local load = sub and sub.load
        if type(load) == "table" then
            if type(load.modAlt) == "table" and load.modAlt.selected and not canAlt then
                load.modAlt.selected = false
            end
            if type(load.modShiftCtrl) == "table" and load.modShiftCtrl.selected and not canSC then
                load.modShiftCtrl.selected = false
            end
        end
    end
end

--- Bracket tokens ("combat", "nostealth", "mod:alt", ...) from a sub-profile's load table.
--- Optional binding gates mod:alt / mod:shift+mod:ctrl (stale flags ignored).
--- Returned as an ordered array; empty when nothing selected.
function Conditions.MacroTokensForSub(sub, binding)
    local out = {}
    local load = sub and sub.load
    if type(load) ~= "table" then return out end
    for key, tokenPair in pairs(MACRO_OPTION_TOKENS) do
        local opt = load[key]
        if type(opt) == "table" and opt.selected then
            local val = opt.value
            if opt.negated then val = not val end
            local token = tokenPair[val == true]
            if token then
                out[#out + 1] = token
            end
        end
    end
    local wantAlt, wantSC = Conditions.ResolvedModFlags(sub, binding)
    if wantSC then
        out[#out + 1] = "mod:shift"
        out[#out + 1] = "mod:ctrl"
    end
    if wantAlt then
        out[#out + 1] = "mod:alt"
    end
    table.sort(out)
    return out
end

--- True when the sub bakes any keyboard macro conditional (combat / stealth /
--- mounted / … and gated mod:alt / SHIFT+CTRL). Shared-key badge peers with
--- only this set still overlay the bar; fully default peers do not.
function Conditions.SubHasMacroCondition(sub, binding)
    local tokens = Conditions.MacroTokensForSub(sub, binding)
    return type(tokens) == "table" and #tokens > 0
end

--- Compact human tags for tooltips / KeyVisualizer (conditions, targets, flags, badges).
--- Disabled toggles (e.g. key press off) are omitted — only active settings are listed.
--- opts.omitBadge = true skips Bar & Badges phrases (Actionbars LAB tooltips).
--- @return string empty when the sub has nothing noteworthy
function Conditions.SummarizeSub(sub, opts)
    if type(sub) ~= "table" then return "" end
    opts = type(opts) == "table" and opts or nil
    local omitBadge = opts and opts.omitBadge
    local bits = {}

    local TOKEN_LABEL = {
        combat = "in combat",
        nocombat = "out of combat",
        stealth = "stealthed",
        nostealth = "not stealthed",
        mounted = "mounted",
        nomounted = "not mounted",
        pet = "pet out",
        nopet = "no pet",
        outdoors = "outdoors",
        indoors = "indoors",
        swimming = "swimming",
        noswimming = "not swimming",
        flying = "flying",
        noflying = "not flying",
        channeling = "channeling",
        nochanneling = "not channeling",
        ["mod:alt"] = "Alt held",
        ["mod:shift"] = "Shift held",
        ["mod:ctrl"] = "Ctrl held",
    }
    local UNIT_LABEL = {
        PLAYER = "self",
        TARGET = "target",
        MOUSEOVER = "mouseover",
        FOCUS = "focus",
        PET = "pet",
        TARGETTARGET = "target-of-target",
        CURSOR = "cursor",
    }
    local HOSTILITY_LABEL = {
        FRIENDLY = "friendly",
        HOSTILE = "hostile",
    }
    local VITALS_LABEL = {
        ALIVE = "alive",
        DEAD = "dead",
    }
    local FLAG_LABEL = {
        interrupt = "interrupt",
        startAutoAttack = "start auto-attack",
        startPetAttack = "start pet attack",
        cancelQueuedSpell = "cancel queued spell",
        cancelForm = "cancel form",
        castAtCursor = "cast at cursor",
        preventToggle = "prevent toggle",
    }
    local LOAD_GATE_LABEL = {
        equipped = "equipped",
        zoneName = "zone",
        instanceType = "instance",
        specialization = "spec",
    }

    local function push(label)
        if label and label ~= "" then
            bits[#bits + 1] = label
        end
    end

    local function JoinParts(parts)
        if #parts == 0 then return nil end
        return table.concat(parts, " · ")
    end

    local load = sub.load
    if type(load) == "table" then
        if load.never then
            push("never loads")
        end
        local tokens = Conditions.MacroTokensForSub(sub)
        local seen = {}
        local hasShift, hasCtrl = false, false
        for i = 1, #tokens do
            if tokens[i] == "mod:shift" then hasShift = true end
            if tokens[i] == "mod:ctrl" then hasCtrl = true end
        end
        if hasShift and hasCtrl then
            push("Shift+Ctrl held")
            seen["mod:shift"] = true
            seen["mod:ctrl"] = true
        end
        for i = 1, #tokens do
            local tok = tokens[i]
            if not seen[tok] then
                push(TOKEN_LABEL[tok] or tok)
            end
        end
        for _, k in ipairs({ "equipped", "zoneName", "instanceType", "specialization" }) do
            local opt = load[k]
            if type(opt) == "table" and opt.selected then
                local gate = LOAD_GATE_LABEL[k] or k
                local label = gate
                if type(opt.value) == "string" and opt.value ~= "" then
                    label = gate .. " " .. opt.value
                elseif opt.value ~= nil then
                    label = gate .. " " .. tostring(opt.value)
                end
                if opt.negated then label = "not " .. label end
                push(label)
            end
        end
    end

    local t = sub.targets
    if type(t) == "table" then
        -- Unit-frame cast (hovercast): only when enabled (default on).
        if t.hovercastEnabled ~= false then
            local hc = t.hovercast
            if type(hc) == "table" then
                local parts = {}
                local h = hc.hostility and HOSTILITY_LABEL[hc.hostility]
                local v = hc.vitals and VITALS_LABEL[hc.vitals]
                if h then parts[#parts + 1] = h end
                if v then parts[#parts + 1] = v end
                if #parts > 0 then
                    push("unit frame cast (" .. table.concat(parts, ", ") .. ")")
                end
            end
        end
        -- Key press targets: only when enabled. Do not mention when toggled off.
        if t.regularEnabled ~= false then
            local rows = t.regular
            if type(rows) == "table" then
                if #rows == 0 then
                    push("key press: no targets")
                elseif #rows == 1 and type(rows[1]) == "table" then
                    local row = rows[1]
                    local parts = {}
                    if row.unit and row.unit ~= "DEFAULT" then
                        parts[#parts + 1] = UNIT_LABEL[row.unit]
                            or string.lower(tostring(row.unit))
                    end
                    local h = row.hostility and HOSTILITY_LABEL[row.hostility]
                    local v = row.vitals and VITALS_LABEL[row.vitals]
                    if h then parts[#parts + 1] = h end
                    if v then parts[#parts + 1] = v end
                    local joined = JoinParts(parts)
                    if joined then
                        push("key press: " .. joined)
                    end
                elseif #rows > 1 then
                    push(("key press: %d targets"):format(#rows))
                end
            end
        end
    end

    local a = sub.action
    if type(a) == "table" then
        for _, flag in ipairs({
            "interrupt", "startAutoAttack", "startPetAttack", "cancelQueuedSpell",
            "cancelForm", "castAtCursor", "preventToggle",
        }) do
            if a[flag] then
                push(FLAG_LABEL[flag] or flag)
            end
        end
        if a.cancelAura then
            local aura = a.cancelAuraName
            if type(aura) == "string" then
                aura = aura:match("^%s*(.-)%s*$") or ""
            else
                aura = ""
            end
            if aura ~= "" then
                local asId = tonumber(aura)
                if asId and Action and Action.GetSpellInfoCompat then
                    local name = select(1, Action.GetSpellInfoCompat(asId))
                    if type(name) == "string" and name ~= "" then
                        aura = name
                    end
                end
                push("cancel aura " .. aura)
            else
                push("cancel aura")
            end
        end
    end

    if sub.macro and type(sub.macro.prefix) == "string" and sub.macro.prefix:match("%S") then
        push("custom macro prefix")
    end
    if sub.macro and type(sub.macro.extras) == "table" then
        local DB = ns.FluxBindingDB3
        local n = DB and DB.NormalizeMacroExtras and #DB.NormalizeMacroExtras(sub.macro.extras)
            or #sub.macro.extras
        if n > 0 then
            push(n == 1 and "multi-cast ×1" or ("multi-cast ×" .. n))
        end
    end

    local badge = sub.badge
    if type(badge) == "table" and not omitBadge then
        if badge.hiddenAlways then push("badge always hidden") end
        if badge.hiddenSwap then push("badge hides when swapped") end
        if badge.hiddenUnlessCd then push("badge only on cooldown") end
        if badge.hiddenMinirow then push("badge hidden on mini-row") end
        if badge.cdNumber == false then push("badge cooldown text off") end
        local cds = tonumber(badge.cdNumberScale)
        if cds and math.abs(cds - 1.0) > 0.001 then
            push(("badge cooldown text %d%%"):format(math.floor(cds * 100 + 0.5)))
        end
        if badge.cdNumberMainrow == false then push("badge cooldown text off (main)") end
        if badge.cdNumberMinirow == false then push("badge cooldown text off (mini)") end
        local alpha = tonumber(badge.alpha)
        local def = (ns.FluxBindingDB3 and ns.FluxBindingDB3.DEFAULT_BADGE_ALPHA) or 0.75
        if alpha and math.abs(alpha - def) > 0.001 then
            push(("badge opacity %d%%"):format(math.floor(alpha * 100 + 0.5)))
        end
    end

    if sub.active == false then
        push("inactive in this form")
    end

    return table.concat(bits, "; ")
end

-- ---------------------------------------------------------------------------
-- Load gates
-- ---------------------------------------------------------------------------

local function GetSpecializationCompat()
    if GetSpecialization then
        return GetSpecialization()
    elseif GetActiveTalentGroup then
        return GetActiveTalentGroup()
    end
    return 1
end

local function IsEquippedCompat(value)
    if not value or value == "" then return true end
    if C_Item and C_Item.IsEquippedItem then
        local ok, res = pcall(C_Item.IsEquippedItem, value)
        if ok and res then return true end
    end
    if IsEquippedItem then
        local ok, res = pcall(IsEquippedItem, value)
        if ok and res then return true end
    end
    if IsEquippedItemType then
        local ok, res = pcall(IsEquippedItemType, value)
        if ok and res then return true end
    end
    return false
end

local function InstanceTypeMatches(opt)
    if not opt.selected then return true end
    local want = opt.value
    local inInstance, instanceType = IsInInstance()
    local actual = "NONE"
    if inInstance and instanceType then
        actual = string.upper(instanceType)
    end
    local match = (actual == string.upper(tostring(want or "NONE")))
    if opt.negated then match = not match end
    return match
end

--- Evaluate the LOAD gates for one binding + sub-profile.
--- The action-availability check (spell learned / item owned) is separate so
--- callers can distinguish "parked" from "filtered".
function Conditions.SubPassesLoadGates(sub)
    local load = sub and sub.load
    if type(load) ~= "table" then return true end
    if load.never then return false end

    if type(load.equipped) == "table" and load.equipped.selected then
        if not IsEquippedCompat(load.equipped.value) then
            return false
        end
    end

    if type(load.instanceType) == "table" then
        if not InstanceTypeMatches(load.instanceType) then
            return false
        end
    end

    if type(load.zoneName) == "table" and load.zoneName.selected then
        local want = tostring(load.zoneName.value or "")
        if want ~= "" then
            local zone = GetRealZoneText and GetRealZoneText() or ""
            local sub2 = GetSubZoneText and GetSubZoneText() or ""
            if zone ~= want and sub2 ~= want then
                return false
            end
        end
    end

    if type(load.specialization) == "table" and load.specialization.selected then
        local want = tonumber(load.specialization.value)
        if want then
            local match = (GetSpecializationCompat() == want)
            if load.specialization.negated then match = not match end
            if not match then
                return false
            end
        end
    end

    return true
end

--- Full active check for one binding + form token:
--- action available + custom-active for form + form page enabled + load gates.
--- V10: non-noform forms need a dedicated Active sub (no inherit of noform Active).
function Conditions.IsActive(binding, formToken)
    if not binding then return false end
    local DB = ns.FluxBindingDB3
    if DB and not DB.IsFormPageEnabled(formToken) then
        return false
    end
    if not Action.IsAvailable(binding.action) then
        return false
    end
    if not DB or not DB.IsCustomActiveForForm(binding, formToken) then
        return false
    end
    -- Read the dedicated (or noform) sub for load gates — same source as Active.
    local Forms = ns.FluxBindingForms
    local multi = Forms and Forms.HasMultipleForms and Forms.HasMultipleForms()
    local sub
    if not multi or (formToken or "noform") == "noform" then
        sub = binding.forms and binding.forms.noform
    else
        sub = binding.forms and binding.forms[formToken]
    end
    if not sub then return false end
    return Conditions.SubPassesLoadGates(sub)
end

--- "Parked": the binding has a key but its action is unavailable (spell
--- unlearned / item missing). Purely informational; apply just filters it.
function Conditions.IsParked(binding)
    return binding and binding.key and not Action.IsAvailable(binding.action) or false
end

-- ---------------------------------------------------------------------------
-- Change tracking -> dirty notifications
-- ---------------------------------------------------------------------------

-- Cache availability per binding so FluxInv pulses only dirty CHANGED bindings.
local availabilityCache = {}

--- Diff availability for all bindings; returns array of changed uids (or nil).
function Conditions.DiffAvailability()
    local DB = ns.FluxBindingDB3
    if not DB then return nil end
    local changed
    for uid, b in pairs(DB.All()) do
        local avail = Action.IsAvailable(b.action) and true or false
        if availabilityCache[uid] ~= avail then
            availabilityCache[uid] = avail
            changed = changed or {}
            changed[#changed + 1] = uid
        end
    end
    for uid in pairs(availabilityCache) do
        if not DB.Get(uid) then
            availabilityCache[uid] = nil
        end
    end
    return changed
end

function Conditions.InvalidateAvailability(uid)
    if uid then
        availabilityCache[uid] = nil
    else
        wipe(availabilityCache)
    end
end

-- FluxInv listener: spells (learn/unlearn) + bags/equip (item-owned, equipped
-- gates). FluxInv debounces (~50ms); we only trigger apply on real changes.
local invRegistered = false
function Conditions.EnsureInventoryListener()
    if invRegistered then return end
    local Inv = _G.FluxInv
    if not Inv or not Inv.RegisterListener then return end
    invRegistered = true
    Inv.RegisterListener("FluxBinding3", function(ctx)
        local changed = Conditions.DiffAvailability()
        if changed and #changed > 0 then
            local FluxBinding = _G.FluxBinding
            if FluxBinding and FluxBinding.NotifyBindingsAvailabilityChanged then
                FluxBinding.NotifyBindingsAvailabilityChanged(changed)
            end
        end
    end, {
        tier = "scan",
        regions = { "bags", "equip", "spells" },
        -- DiffAvailability tests every binding; batch it during loot storms.
        deferHeavy = true,
    })
end

-- Rare-event load gates (zone / spec / equip fallback when FluxInv missing).
local gateEvents = CreateFrame("Frame")
gateEvents:RegisterEvent("ZONE_CHANGED_NEW_AREA")
gateEvents:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
pcall(gateEvents.RegisterEvent, gateEvents, "PLAYER_SPECIALIZATION_CHANGED")
pcall(gateEvents.RegisterEvent, gateEvents, "ACTIVE_TALENT_GROUP_CHANGED")
gateEvents:SetScript("OnEvent", function()
    local FluxBinding = _G.FluxBinding
    if FluxBinding and FluxBinding.NotifyLoadGatesChanged then
        FluxBinding.NotifyLoadGatesChanged()
    end
end)

-- Pet summon / dismiss / pet-bar changes → catalog gate only.
-- Do NOT reapply secure macros on UNIT_PET: pet ability bindings stay compiled
-- and always available so mid-combat summon works ([pet]/[@cursor]/[nopet]).
local petEvents = CreateFrame("Frame")
petEvents:RegisterEvent("UNIT_PET")
pcall(petEvents.RegisterEvent, petEvents, "PET_BAR_UPDATE")
pcall(petEvents.RegisterEvent, petEvents, "PET_BAR_UPDATE_COOLDOWN")
pcall(petEvents.RegisterEvent, petEvents, "SPELLS_CHANGED")
petEvents:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_PET" and unit and unit ~= "player" then
        return
    end
    local Lib = ns.FluxBindingSpellLibrary
    if Lib and Lib.InvalidatePetAbilityGate then
        Lib.InvalidatePetAbilityGate()
    end
    -- Pet bindings are always available — do not DiffAvailability/reapply on
    -- summon/dismiss (that would be a no-op for pet rows and risks combat taint
    -- for any non-pet rows that falsely flip). Catalog refresh is browser-side.
end)
