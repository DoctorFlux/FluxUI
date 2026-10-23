-- Binding/Core/Apply.lua
-- The single apply pipeline + the public FluxBinding API.
--
-- Recompute is cheap (a few dozen bindings); SECURE WRITES are the expensive
-- part, so every apply is diff-based: slot programs and badge stacks route
-- through FluxSlotProgram / FluxBadgeHost (which skip unchanged content), and
-- free-chord overrides only rewrite attributes / override bindings on change.
--
-- One coalesced scheduler (next frame). In combat, the whole flush queues and
-- runs on PLAYER_REGEN_ENABLED.

local addonName, ns = ...

local DB = ns.FluxBindingDB3
local Action = ns.FluxBindingAction
local Forms = ns.FluxBindingForms
local ChordMap = ns.FluxBindingChordMap
local Conditions = ns.FluxBindingConditions
local Factory = ns.FluxBindingMacroFactory
local Pool = ns.FluxSecureButtonPool
local FLUX_API = _G.FLUX_API or {}

local FluxBinding = {}
ns.FluxBinding = FluxBinding
_G.FluxBinding = FluxBinding

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

local function MouseoverCastEnabled()
    local fo = _G.FluxOptions
    if fo and fo.GetActionbarsDB then
        local t = fo:GetActionbarsDB()
        if t and t.mouseoverCast == false then
            return false
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Native slot inspection
-- ---------------------------------------------------------------------------

--- A bar spell stays a spell even when C_Spell has not cached the name yet.
--- Returning empty here makes BadgeHost clear the shared-key corner.
local function SpellNativeFromId(id)
    local name = Action.GetSpellInfoCompat(id)
    local token = name
    local cached = not Action.SpellDataCached or Action.SpellDataCached(id)
    if name and cached and FLUX_API.supportsPerRankSpellBarFeatures then
        local fmt = _G.FluxFormatSpellCastAttribute
        if fmt then
            local attr = fmt(id)
            if type(attr) == "string" and attr ~= "" then
                token = attr
            end
        else
            local sub = Action.GetSpellSubtextCompat(id)
            if sub and sub ~= "" then
                token = name .. "(" .. sub .. ")"
            end
        end
    end
    if not name and Action.RequestSpellData then
        Action.RequestSpellData(id)
    end
    return {
        kind = "spell",
        id = id,
        name = name,
        token = token,
        actionKey = (Action.SlotActionKey and Action.SlotActionKey(id)) or ("s" .. id),
    }
end

local function ValueIsSecret(value)
    local Secrets = ns.Flux and ns.Flux.Secrets
    return Secrets and Secrets.IsSecretValue and Secrets.IsSecretValue(value) or false
end

local function PositiveActionId(id)
    if id == nil or ValueIsSecret(id) then
        return nil
    end
    local n = tonumber(id)
    if n and n > 0 then
        return n
    end
    return nil
end

--- pcall GetActionInfo. A secret or failed read is "unreadable", not an empty slot.
--- An empty result is what used to skip the keypress macro and the corner badge.
local function ReadActionInfo(slot)
    local function pull(fn)
        if type(fn) ~= "function" then
            return nil, nil, nil, false
        end
        local ok, actionType, id, subType = pcall(fn, slot)
        if not ok then
            return nil, nil, nil, true
        end
        if ValueIsSecret(actionType) or ValueIsSecret(id) then
            return nil, nil, nil, true
        end
        return actionType, id, subType, false
    end
    local cab = C_ActionBar
    if cab and type(cab.GetActionInfo) == "function" then
        local actionType, id, subType, secret = pull(cab.GetActionInfo)
        if secret or actionType then
            return actionType, id, subType, secret
        end
    end
    if type(GetActionInfo) == "function" then
        return pull(GetActionInfo)
    end
    return nil, nil, nil, false
end

local function SlotNative(slot)
    if not slot then return { kind = "empty" } end
    local actionType, id, subType, secret = ReadActionInfo(slot)
    if secret then
        return { kind = "spell", unread = true }
    end
    local n = PositiveActionId(id)
    if actionType == "spell" then
        if n then
            return SpellNativeFromId(n)
        end
        return { kind = "spell", unread = true }
    elseif actionType == "item" and n then
        return { kind = "item", id = n, token = "item:" .. n, actionKey = "i" .. n }
    elseif actionType == "macro" and n then
        if subType == "spell" then
            local spellNative = SpellNativeFromId(n)
            if spellNative.name or spellNative.token then
                return spellNative
            end
        end
        return { kind = "macro", id = n }
    elseif actionType then
        return { kind = "other" }
    end
    return { kind = "empty" }
end

--- Occupancy cache key (`spell:123`) → Binding actionKey (`s123` / `i6948`).
local function OccupancyKeyToActionKey(occKey)
    if type(occKey) ~= "string" or occKey == "" or occKey == ":" then
        return nil
    end
    local kind, rest = occKey:match("^([^:]+):(.*)$")
    if not kind then
        return nil
    end
    if kind == "spell" then
        local id = tonumber(rest)
        if id and id > 0 then
            return Action.SlotActionKey(id) or ("s" .. id)
        end
    elseif kind == "item" or kind == "toy" then
        local id = tonumber(rest)
        if id then
            return "i" .. id
        end
    end
    return nil
end

local function NativeMatchesBinding(native, b)
    if not native or not native.actionKey or not b or not b.action then
        return false
    end
    if Action.KeysMatch and Action.KeysMatch(b.action, native.actionKey) then
        return true
    end
    return Action.Key(b.action) == native.actionKey
end

local function OccupancyMatchesBinding(occKey, b)
    local ak = OccupancyKeyToActionKey(occKey)
    if not ak or not b or not b.action then
        return false
    end
    if Action.KeysMatch and Action.KeysMatch(b.action, ak) then
        return true
    end
    return Action.Key(b.action) == ak or (Action.FamilyKey and Action.FamilyKey(b.action) == ak)
end

-- ---------------------------------------------------------------------------
-- Sub-profile helpers
-- ---------------------------------------------------------------------------

--- Sub used for a form token: dedicated sub, else inherited noform sub.
local function SubForToken(binding, token)
    if type(binding.forms) ~= "table" then return nil end
    return binding.forms[token] or binding.forms.noform
end

--- Non-default = the profile changes cast behavior vs a plain bar click.
--- V10 parity: hovercastEnabled defaults ON — only explicit opt-out (and other
--- real customizations) counts as customized. Untouched profiles, and
--- native-only factory mouseover tails, stay type=action + FluxMouseoverCast.
local function IsSubNonDefault(sub)
    if type(sub) ~= "table" then return false end
    if sub.active == false then return true end
    local t = sub.targets or {}
    -- Default is hovercastEnabled=true; only explicit opt-out counts.
    if t.hovercastEnabled == false then return true end
    if t.regularEnabled == false then return true end
    if type(t.hovercast) == "table" then
        if t.hovercast.hostility and t.hovercast.hostility ~= "ANY" then return true end
        if t.hovercast.vitals and t.hovercast.vitals ~= "ANY" then return true end
    end
    if type(t.regular) == "table" then
        -- Empty regular list (all rows removed) is non-default.
        if #t.regular == 0 then return true end
        if #t.regular > 1 then return true end
        local row = t.regular[1]
        if type(row) == "table" then
            if (row.unit or "DEFAULT") ~= "DEFAULT" then return true end
            if (row.hostility or "ANY") ~= "ANY" then return true end
            if (row.vitals or "ANY") ~= "ANY" then return true end
        elseif row ~= nil then
            return true
        end
    end
    local a = sub.action or {}
    for _, flag in ipairs({ "interrupt", "startAutoAttack", "startPetAttack", "stopSpellTarget",
        "cancelQueuedSpell", "cancelForm", "cancelAura", "targetUnitAfterCast", "preventToggle",
        "spellIncludeSubtext", "castAtCursor" }) do
        if a[flag] then return true end
    end
    if type(a.cancelAuraName) == "string" and a.cancelAuraName:match("%S") then
        return true
    end
    local l = sub.load or {}
    if l.never then return true end
    for _, k in ipairs({ "combat", "stealth", "mounted", "pet", "outdoors", "swimming",
        "flying", "channeling", "modAlt", "modShiftCtrl",
        "equipped", "instanceType", "zoneName", "specialization" }) do
        local opt = l[k]
        if type(opt) == "table" then
            if opt.selected or opt.negated then return true end
            -- Equipped / zone gates: non-empty value even before selected can linger; count when selected.
            if k == "equipped" or k == "zoneName" then
                if opt.selected and type(opt.value) == "string" and opt.value ~= "" then
                    return true
                end
            end
        end
    end
    if sub.macro and type(sub.macro.prefix) == "string" and sub.macro.prefix:match("%S") then
        return true
    end
    if sub.macro and type(sub.macro.extras) == "table" and #DB.NormalizeMacroExtras(sub.macro.extras) > 0 then
        return true
    end
    -- Badge / bar-corner settings (implicit unbound action-bar spells often only change these).
    local badge = sub.badge
    if type(badge) == "table" then
        local alpha = tonumber(badge.alpha)
        local def = (DB and DB.DEFAULT_BADGE_ALPHA) or 0.75
        if alpha and math.abs(alpha - def) > 0.001 then return true end
        if badge.hiddenSwap or badge.hiddenAlways or badge.hiddenUnlessCd or badge.hiddenMinirow then
            return true
        end
        if badge.cdNumber == false then return true end
        local cds = tonumber(badge.cdNumberScale)
        if cds and math.abs(cds - 1.0) > 0.001 then return true end
        if badge.cdNumberMainrow == false or badge.cdNumberMinirow == false then
            return true
        end
    end
    return false
end

FluxBinding.IsSubNonDefault = IsSubNonDefault

--- Binding counts as Respec/editor "customized": Flux key, key-split fallback,
--- any non-default form sub (incl. badge), or dedicated multi-form subs.
--- Also: any binding instance in DB3 is user-created — if it has a forms table
--- with more than a pristine noform stub, keep it (implicit bar spells).
local function IsBindingCustomized(binding)
    if type(binding) ~= "table" then return false end
    if binding.key and binding.key ~= "" then return true end
    if binding.stickyRespec then return true end
    if binding.fallback and binding.fallback ~= "ACTION_BAR" then return true end
    if type(binding.forms) ~= "table" then return false end
    local formCount = 0
    for token, sub in pairs(binding.forms) do
        formCount = formCount + 1
        if token ~= "noform" then return true end
        if IsSubNonDefault(sub) then return true end
    end
    return false
end

FluxBinding.IsBindingCustomized = IsBindingCustomized

--- True when this binding's action (or placeId) still sits on a bar / Extra / stance.
function FluxBinding.BindingHasLivePlace(binding)
    if type(binding) ~= "table" or type(binding.action) ~= "table" then
        return false
    end
    local Placement = ns.FluxBindingPlacement
    local SpellLibrary = ns.FluxBindingSpellLibrary
    local placeId = binding.placeId
    if type(placeId) == "string" and placeId ~= "" and not placeId:match("^inst:") then
        if Placement and Placement.ChordForPlaceId then
            local chord = Placement.ChordForPlaceId(placeId)
            if chord and chord ~= "" then
                return true
            end
        end
        -- placeId may still be occupied even without a chord (zone-inactive mount).
        if placeId:match("^ab:(%d+)$") then
            local slot = tonumber(placeId:match("^ab:(%d+)$"))
            if slot and HasAction and HasAction(slot) then
                return true
            end
        end
        if placeId:match("^mcast:") and Placement and Placement.IndexMultiCast then
            local map = Placement.IndexMultiCast() or {}
            for _, places in pairs(map) do
                if type(places) == "table" then
                    for i = 1, #places do
                        local p = places[i]
                        local pid = p.placeId or (Placement.PlaceId and Placement.PlaceId(p))
                        if pid == placeId then
                            return true
                        end
                    end
                end
            end
        end
    end

    local ak = Action and ((Action.FamilyKey and Action.FamilyKey(binding.action)) or Action.Key(binding.action))
    local strict = Action and Action.Key(binding.action)
    if Placement and Placement.IndexExtra then
        local map = Placement.IndexExtra()
        if ak and map and map[ak] and #map[ak] > 0 then return true end
        if strict and map and map[strict] and #map[strict] > 0 then return true end
    end
    if Placement and Placement.IndexStance then
        local map = Placement.IndexStance()
        if ak and map and map[ak] and #map[ak] > 0 then return true end
        if strict and map and map[strict] and #map[strict] > 0 then return true end
    end
    if Placement and Placement.IndexMultiCast then
        local map = Placement.IndexMultiCast()
        if ak and map and map[ak] and #map[ak] > 0 then return true end
        if strict and map and map[strict] and #map[strict] > 0 then return true end
    end
    if SpellLibrary and SpellLibrary.IndexBars then
        local barIndex = SpellLibrary.IndexBars()
        local a = binding.action
        if a.type == "spell" and a.id and barIndex.spell and barIndex.spell[tonumber(a.id) or a.id] then
            return true
        end
        if a.type == "item" and a.id and barIndex.item and barIndex.item[tonumber(a.id) or a.id] then
            return true
        end
        if a.type == "macro" and a.name and barIndex.macro and barIndex.macro[a.name] then
            return true
        end
    end
    return false
end

--- Keep customized (keyed / sticky / non-default settings) only.
--- Default unbound rows are never persisted — place display is catalog-only
--- (action bar / Extra / stance). BindingHasLivePlace is used by the editor to
--- decide whether to reset to place-inherited vs fully not-bound after prune.
function FluxBinding.IsBindingRespecRelevant(binding)
    if IsBindingCustomized(binding) then return true end
    return false
end

--- Drop default unbound stubs (no Flux key, default settings).
--- opts.keepUid = leave this uid alone (still being edited).
function FluxBinding.PrunePristineBindings(doc, opts)
    opts = type(opts) == "table" and opts or {}
    local keepUid = opts.keepUid
    local target = doc
    if not target and DB then
        target = (DB.Ensure and DB.Ensure()) or nil
    end
    if type(target) ~= "table" or type(target.bindings) ~= "table" then
        return 0
    end
    local remove = {}
    for uid, b in pairs(target.bindings) do
        if type(b) == "table" and uid ~= keepUid and not FluxBinding.IsBindingRespecRelevant(b) then
            remove[#remove + 1] = uid
        end
    end
    for i = 1, #remove do
        local uid = remove[i]
        if doc then
            target.bindings[uid] = nil
        elseif DB and DB.Remove then
            DB.Remove(uid)
        else
            target.bindings[uid] = nil
        end
    end
    return #remove
end

-- ---------------------------------------------------------------------------
-- Plan computation
-- ---------------------------------------------------------------------------

--- When `slot` is set, only bindings for that bar place (`ab:<slot>`) match
--- (so Icy Veins on C and Z can have different multi-cast extras).
local function BindingBelongsToBarSlot(binding, slot)
    if not binding or not slot then return true end
    local pid = binding.placeId
    if type(pid) ~= "string" or pid == "" or pid:match("^inst:") then
        -- Legacy unplaced row: only OK when no place-scoped sibling is in play
        -- (caller usually filters first). Treat as matching for Collect safety.
        return true
    end
    local ab = pid:match("^ab:(%d+)$")
    if ab then
        return tonumber(ab) == tonumber(slot)
    end
    -- Non-action-bar places do not ride bar slots for multi-cast.
    return false
end

--- Prefer place-scoped bindings for `ab:<slot>`; if any exist, drop legacy
--- unplaced rows so they cannot fan extras onto every copy of the spell.
local function FilterBindingsForBarSlot(bindings, slot)
    if type(bindings) ~= "table" or not slot then
        return bindings or {}
    end
    local want = "ab:" .. tostring(slot)
    local native = SlotNative(slot)
    local placed, legacy = {}, {}
    for i = 1, #bindings do
        local b = bindings[i]
        if b then
            local pid = b.placeId
            if type(pid) == "string" and pid ~= "" and not pid:match("^inst:") then
                if pid == want then
                    placed[#placed + 1] = b
                else
                    -- Relocate missed (peek race): pin still names the vacated
                    -- slot, but this slot now holds the bound action. Steal the
                    -- overlay only when the pinned slot no longer has it — two
                    -- live copies (C vs Z) keep their own pins.
                    local placeSlot = tonumber(pid:match("^ab:(%d+)$"))
                    if placeSlot and placeSlot ~= slot
                        and NativeMatchesBinding(native, b)
                        and not NativeMatchesBinding(SlotNative(placeSlot), b)
                    then
                        placed[#placed + 1] = b
                    end
                end
            else
                legacy[#legacy + 1] = b
            end
        end
    end
    if #placed > 0 then
        return placed
    end
    return legacy
end

--- Drop a keyless binding from this slot's overlay when its action now occupies
--- a different bar slot (dragged host must not become a peer on the vacated key).
--- Keyed bindings stay: the key is the placement, even when that spell also
--- sits on another button. Stripping them left the chord with unit-frame hover
--- only (keyboard macro and corner badge never installed).
local function BindingOccupiesOtherSlot(b, slot, slotsByActionKey)
    if not b or not b.action or not slotsByActionKey then
        return false
    end
    local function homesFor(key)
        return key and slotsByActionKey[key]
    end
    local rk = Action.Key(b.action)
    local fk = Action.FamilyKey and Action.FamilyKey(b.action)
    local homes = homesFor(rk)
    if homes then
        for s in pairs(homes) do
            if s ~= slot then
                return true
            end
        end
    end
    if fk and fk ~= rk then
        homes = homesFor(fk)
        if homes then
            for s in pairs(homes) do
                if s ~= slot then
                    return true
                end
            end
        end
    end
    return false
end

local function FilterBucketForBarSlot(bucket, slot, native, slotsByActionKey)
    if type(bucket) ~= "table" then
        return bucket
    end
    local out = {}
    for i = 1, #bucket do
        local b = bucket[i]
        if b then
            if b.key or NativeMatchesBinding(native, b) then
                out[#out + 1] = b
            elseif not BindingOccupiesOtherSlot(b, slot, slotsByActionKey) then
                out[#out + 1] = b
            end
        end
    end
    return out
end

--- Entries for a slot/free chord from one bucket, grouped per form token.
--- opts.includeDefaultKeyed: free chords still need a cast when the profile is
--- fully default (no native LAB button). Bar slots must NOT — keep native +
--- FluxMouseoverCast.
--- Overlay compile fingerprint (not table identity). Dedicated form copies of
--- the same settings must collapse so Active-on-all-forms does not bake
--- [noform]/[form:1]/[form:2]/… into a 255-char macro.
local ACTION_FLAG_SIG = {
	"interrupt", "startAutoAttack", "startPetAttack", "stopSpellTarget",
	"cancelQueuedSpell", "cancelForm", "cancelAura", "targetUnitAfterCast",
	"preventToggle", "spellIncludeSubtext", "castAtCursor",
}

local function SubOverlaySig(sub, binding)
	if type(sub) ~= "table" then
		return ""
	end
	local bits = {}
	bits[#bits + 1] = sub.active == false and "off" or "on"
	local baked = Conditions.MacroTokensForSub(sub, binding)
	bits[#bits + 1] = table.concat(baked, ",")
	local t = sub.targets or {}
	bits[#bits + 1] = t.hovercastEnabled == false and "h0" or "h1"
	bits[#bits + 1] = t.regularEnabled == false and "r0" or "r1"
	local hc = t.hovercast or {}
	bits[#bits + 1] = tostring(hc.hostility or "ANY")
	bits[#bits + 1] = tostring(hc.vitals or "ANY")
	local regs = {}
	if type(t.regular) == "table" then
		for i = 1, #t.regular do
			local row = t.regular[i]
			if type(row) == "table" then
				regs[#regs + 1] = table.concat({
					tostring(row.unit or "DEFAULT"),
					tostring(row.hostility or "ANY"),
					tostring(row.vitals or "ANY"),
				}, ",")
			end
		end
	end
	bits[#bits + 1] = table.concat(regs, ";")
	local a = sub.action or {}
	for i = 1, #ACTION_FLAG_SIG do
		local flag = ACTION_FLAG_SIG[i]
		bits[#bits + 1] = a[flag] and "1" or "0"
	end
	bits[#bits + 1] = tostring(a.cancelAuraName or "")
	local m = sub.macro or {}
	bits[#bits + 1] = tostring(m.prefix or "")
	bits[#bits + 1] = tostring(m.mainCastIndex or 1)
	local extras = DB.NormalizeMacroExtras(m.extras)
	local extraBits = {}
	for i = 1, #extras do
		local e = extras[i]
		extraBits[#extraBits + 1] = tostring(e.type) .. ":" .. tostring(e.id)
	end
	bits[#bits + 1] = table.concat(extraBits, ",")
	return table.concat(bits, "|")
end

local function SplitFormConds(tokenList)
	if Forms and Forms.ConditionGroupsForTokens then
		return Forms.ConditionGroupsForTokens(tokenList)
	end
	return {}
end

--- Conditioned peers first so [combat] / [mod:shift,mod:ctrl] beat unrestricted peers.
local function PreferModEntriesFirst(entries)
    if not entries or #entries < 2 then return entries end
    local modded, rest = {}, {}
    for i = 1, #entries do
        local e = entries[i]
        if e and Conditions.SubHasMacroCondition and Conditions.SubHasMacroCondition(e.sub, e.binding) then
            modded[#modded + 1] = e
        else
            rest[#rest + 1] = e
        end
    end
    if #modded == 0 then return entries end
    for i = 1, #rest do
        modded[#modded + 1] = rest[i]
    end
    return modded
end

local function BuildGroupsForSlot(bucketBindings, tokens, chordNk, opts)
    opts = opts or {}
    local includeDefaultKeyed = opts.includeDefaultKeyed and true or false
    -- entriesByToken[token] = ordered entries
    local uidSet = {}
    for i = 1, #bucketBindings do
        uidSet[bucketBindings[i].uid] = true
    end
    local order = DB.GetChordStackOrder(chordNk, uidSet)

    local entriesByToken = {}
    local sigByToken = {}
    local anyEntries = false
    for _, token in ipairs(tokens) do
        local entries = {}
        local sig = {}
        for _, uid in ipairs(order) do
            local b = DB.Get(uid)
            if b and Conditions.IsActive(b, token) then
                local sub = SubForToken(b, token)
                local include = sub and IsSubNonDefault(sub)
                if not include and includeDefaultKeyed and sub and b.key then
                    include = true
                end
                if include then
                    entries[#entries + 1] = { binding = b, sub = sub }
                    sig[#sig + 1] = tostring(uid) .. ":" .. SubOverlaySig(sub, b)
                    anyEntries = true
                end
            end
        end
        entries = PreferModEntriesFirst(entries)
        entriesByToken[token] = entries
        sigByToken[token] = table.concat(sig, "|")
    end
    if not anyEntries then return nil end

    -- Collapse by overlay settings, not form-sub table identity. Active on
    -- every form this slot serves → no [form:] gate (client evaluates combat
    -- etc.; shapeshift does not rebuild). A subset merges form:N indexes
    -- into one [form:1/3] clause so the body stays inside the 255-char cap.
    local clusterOrder, clusterBySig = {}, {}
    for _, token in ipairs(tokens) do
        local entries = entriesByToken[token]
        if entries and #entries > 0 then
            local sig = sigByToken[token]
            local c = clusterBySig[sig]
            if not c then
                c = { tokens = {}, entries = entries }
                clusterBySig[sig] = c
                clusterOrder[#clusterOrder + 1] = c
            end
            c.tokens[#c.tokens + 1] = token
        end
    end

    local groups = {}
    local tokenCount = #tokens
    for i = 1, #clusterOrder do
        local c = clusterOrder[i]
        if tokenCount <= 1 or #c.tokens == tokenCount then
            groups[#groups + 1] = { formCond = nil, entries = c.entries }
        else
            local condGroups = SplitFormConds(c.tokens)
            if #condGroups == 0 then
                groups[#groups + 1] = { formCond = nil, entries = c.entries }
            else
                for gi = 1, #condGroups do
                    groups[#groups + 1] = { formCond = condGroups[gi], entries = c.entries }
                end
            end
        end
    end
    if #groups == 0 then return nil end
    return groups
end

--- Badge list for a slot: explicit peers whose action differs from the native
--- action, in badge corner order, max FluxBadgeHost.MAX_BADGES.
--- `clauses` = KEYBOARD emission (no hovercast); `hoverClauses` = UF emission.
--- UF-only peers get a static keyboard badge + a hover reverse for display peek.
---
--- Peers Active in ANY form this slot serves are installed (content stays ready).
--- `forms` maps formToken -> true so BadgeHost can alpha-show/hide by live form
--- without a secure re-apply (combat-taint safe).
local function BuildBadges(slot, native, chordNk, bucketBindings, clauses, tokens, hoverClauses)
    clauses = clauses or {}
    local BadgeHost = ns.FluxBadgeHost
    local maxBadges = (BadgeHost and BadgeHost.MAX_BADGES) or 3

    local extras, extrasOwnerUid, extrasOwnerSub = nil, nil, nil
    local formTok = (type(tokens) == "table" and tokens[1]) or "noform"
    local current = Forms.GetCurrentToken and Forms.GetCurrentToken() or "noform"
    local function tryExtrasFrom(b)
        if not b or not FluxBinding.CanUseMultiCastExtras(b) then return false end
        if not BindingBelongsToBarSlot(b, slot) then return false end
        local sub = SubForToken(b, current) or SubForToken(b, formTok)
        local list = DB.GetMacroExtras(sub)
        if #list > 0 then
            extras, extrasOwnerUid, extrasOwnerSub = list, b.uid, sub
            return true
        end
        return false
    end
    -- Prefer place-scoped owner for this slot, then any matching gate.
    local wantPid = slot and ("ab:" .. tostring(slot)) or nil
    if wantPid then
        for i = 1, #(bucketBindings or {}) do
            local b = bucketBindings[i]
            if b and b.placeId == wantPid and tryExtrasFrom(b) then
                break
            end
        end
    end
    if not extras then
        for i = 1, #(bucketBindings or {}) do
            if tryExtrasFrom(bucketBindings[i]) then
                break
            end
        end
    end

    local uidSet = {}
    for i = 1, #bucketBindings do
        local b = bucketBindings[i]
        if b.key and native then
            local sameFamily = (Action.KeysMatch and Action.KeysMatch(b.action, native.actionKey))
                or (Action.Key(b.action) == native.actionKey)
            if not sameFamily then
                uidSet[b.uid] = true
            end
        end
    end
    -- Peer badges and multi-cast extras are mutually exclusive models.
    if extras and next(uidSet) then
        extras, extrasOwnerUid, extrasOwnerSub = nil, nil, nil
    end
    if not extras and not next(uidSet) then return nil end

    local order = next(uidSet) and DB.GetBadgeCornerOrder(chordNk, uidSet) or {}
    local stackOrder = next(uidSet) and DB.GetChordStackOrder(chordNk, uidSet) or {}

    local tokenList = tokens
    if type(tokenList) ~= "table" or #tokenList == 0 then
        tokenList = { "noform" }
    end

    local badges = {}

    if extras and extrasOwnerUid then
        local formsActive = {}
        for ti = 1, #tokenList do
            formsActive[tokenList[ti]] = true
        end
        -- Multi-cast corner badges use EACH extra's own Bar & Badges binding
        -- (Combustion / Trinket 1 / …). Host (Icy Veins) badge settings never apply.
        -- Skip extras marked Always hidden (or alpha 0) so the next visible
        -- extras fill the 3 corner slots instead of leaving empty holes.
        local badgeForm = current or formTok or "noform"
        local badgeExtras = DB.FilterMacroExtras(extras) -- all available; cap after hide-skip
        for bi = 1, #badgeExtras do
            if #badges >= maxBadges then break end
            local e = badgeExtras[bi]
            local bo = (DB.GetBadgeOptsForMacroExtra
                and DB.GetBadgeOptsForMacroExtra(e, badgeForm, extrasOwnerUid))
                or DB.DefaultBadgeOpts()
            local alpha = tonumber(bo.alpha)
            if alpha == nil then alpha = DB.DEFAULT_BADGE_ALPHA or 0.75 end
            if not bo.hiddenAlways and alpha > 0 then
                local origIndex = e._index or bi
                local reverse, icon, spellId, itemId
                if e.type == "spell" then
                    -- Rank subtext only when the client casts by Name(Rank N); on retail
                    -- ranked tails break IsSpellUsable while numeric id stays correct.
                    local FLUX_API = _G.FLUX_API or {}
                    local token = Action.MacroToken(Action.Spell(e.id, e.name), {
                        includeSubtext = FLUX_API.supportsPerRankSpellBarFeatures == true,
                    })
                    reverse = Factory.BuildStaticBadge(token)
                    icon = DB.GetMacroExtraIcon(e)
                    spellId = e.id
                elseif e.type == "item" then
                    reverse = Factory.BuildStaticBadge("item:" .. e.id)
                    icon = DB.GetMacroExtraIcon(e)
                    itemId = e.id
                elseif e.type == "slot" then
                    -- Prefer equipped item:ID so TranslateMacro resolves icon/CD like an item badge.
                    local eqId = GetInventoryItemID and GetInventoryItemID("player", e.id)
                    if eqId then
                        reverse = Factory.BuildStaticBadge("item:" .. eqId)
                        itemId = eqId
                    else
                        reverse = "#showtooltip\n/use " .. e.id
                    end
                    icon = DB.GetMacroExtraIcon(e)
                end
                if reverse then
                    badges[#badges + 1] = {
                        key = ("extra:%s:%d"):format(extrasOwnerUid, origIndex),
                        macrotext = reverse,
                        forms = formsActive,
                        icon = icon,
                        spellId = spellId,
                        itemId = itemId,
                        alpha = bo.alpha,
                        hiddenAlways = false,
                        hiddenUnlessCd = bo.hiddenUnlessCd,
                        hiddenMinirow = bo.hiddenMinirow,
                        hiddenSwap = bo.hiddenSwap,
                        cdNumber = bo.cdNumber ~= false,
                        cdNumberScale = tonumber(bo.cdNumberScale) or 1,
                        cdNumberMainrow = bo.cdNumberMainrow ~= false,
                        cdNumberMinirow = bo.cdNumberMinirow ~= false,
                    }
                end
            end
        end
    end

    for _, uid in ipairs(order) do
        if #badges >= maxBadges then break end
        local b = DB.Get(uid)
        local formsActive, formTokenForOpts
        if b then
            formsActive = {}
            for ti = 1, #tokenList do
                local tok = tokenList[ti]
                if Conditions.IsActive(b, tok) then
                    formsActive[tok] = true
                    formTokenForOpts = formTokenForOpts or tok
                end
            end
            if formsActive[current] then
                formTokenForOpts = current
            end
        end
        if b and formTokenForOpts then
            local sub = SubForToken(b, formTokenForOpts)
            local badgeToken = Action.MacroToken(b.action, { includeSubtext = true })
            local counterToken = native and native.token
            if not counterToken then
                for _, ouid in ipairs(stackOrder) do
                    if ouid ~= uid then
                        local ob = DB.Get(ouid)
                        if ob then
                            counterToken = Action.MacroToken(ob.action, { includeSubtext = true })
                            break
                        end
                    end
                end
            end
            local reverse = Factory.BuildReverse(clauses, uid, badgeToken, counterToken)
            -- Factory mouseover-cast tails must not sit on the badge: world
            -- unit hops would flip the corner icon. Strip those legs here;
            -- the bar click body still has them.
            if reverse and Factory.IsFactoryMouseover
                and Factory.IsFactoryMouseover(reverse, clauses, false) then
                reverse = Factory.IdleMacroText(reverse, true)
            end
            -- UF-only peers contribute no keyboard clauses; BuildReverse would only
            -- flip native/tail legs (incl. Action Bars [@mouseover] N) onto the
            -- badge — that reintroduces world-mouseover icon flips. Keep a static
            -- keyboard badge and put conditional display on hoverMacrotext.
            local hasOwnerClause = false
            for ci = 1, #clauses do
                if clauses[ci].owner == uid then
                    hasOwnerClause = true
                    break
                end
            end
            if not hasOwnerClause then
                reverse = Factory.BuildStaticBadge(badgeToken)
            elseif not reverse then
                reverse = Factory.BuildStaticBadge(badgeToken)
            end
            local hoverReverse
            if hoverClauses and #hoverClauses > 0 then
                hoverReverse = Factory.BuildReverse(hoverClauses, uid, badgeToken, counterToken)
            end
            if reverse then
                local bo = sub and sub.badge or {}
                local peerSpellId, peerItemId
                local act = b.action
                if type(act) == "table" then
                    if act.type == "spell" and act.id then
                        peerSpellId = tonumber(act.id)
                    elseif act.type == "item" and act.id then
                        peerItemId = tonumber(act.id)
                    end
                end
                badges[#badges + 1] = {
                    key = uid,
                    macrotext = reverse,
                    hoverMacrotext = hoverReverse,
                    conditionalMacro = hasOwnerClause,
                    forms = formsActive,
                    spellId = peerSpellId,
                    itemId = peerItemId,
                    alpha = bo.alpha,
                    hiddenAlways = bo.hiddenAlways,
                    hiddenUnlessCd = bo.hiddenUnlessCd,
                    hiddenMinirow = bo.hiddenMinirow,
                    hiddenSwap = bo.hiddenSwap,
                    cdNumber = bo.cdNumber ~= false,
                    cdNumberScale = tonumber(bo.cdNumberScale) or 1,
                    cdNumberMainrow = bo.cdNumberMainrow ~= false,
                    cdNumberMinirow = bo.cdNumberMinirow ~= false,
                }
            end
        end
    end
    if #badges == 0 then return nil end
    return badges
end

--- Collect multi-cast extras from group entries when the gate allows.
--- Returns { before = {...}, after = {...} } (available only), or nil.
--- When `slot` is set, only bindings for that bar place (`ab:<slot>`) contribute
--- (so Icy Veins on C and Z can have different extras).
local function CollectMultiCastExtras(groups, slot)
    if type(groups) ~= "table" then return nil end
    for g = 1, #groups do
        local entries = groups[g].entries
        for e = 1, #(entries or {}) do
            local entry = entries[e]
            local b = entry and entry.binding
            if b and FluxBinding.CanUseMultiCastExtras(b)
                and BindingBelongsToBarSlot(b, slot) then
                local beforeRaw, afterRaw = DB.SplitMacroExtrasAroundMain(entry.sub)
                local before = DB.FilterMacroExtras(beforeRaw)
                local after = DB.FilterMacroExtras(afterRaw)
                if #before > 0 or #after > 0 then
                    return { before = before, after = after }
                end
            end
        end
    end
    return nil
end

--- Bar chord that reaches `slot` (for UF hover routing of implicit bindings
--- that ride their bar slot). Scans column bindings; SHIFT-/CTRL- variants
--- cover the mini rows.
local function ChordForSlot(slot)
    if not slot then return nil end
    for col = 1, ChordMap.TOTAL_COLUMNS do
        local bindingName = ChordMap.COLUMN_BINDING_NAME[col]
        for k = 1, select("#", GetBindingKey(bindingName)) do
            local key = select(k, GetBindingKey(bindingName))
            if key and key ~= "" then
                local variants = { key, "SHIFT-" .. key, "CTRL-" .. key }
                for v = 1, #variants do
                    local route = ChordMap.Route(variants[v])
                    if route and route.kind == "slot" then
                        for _, s in pairs(route.slotsByForm) do
                            if s == slot then
                                return ChordMap.Normalize(variants[v])
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function NativeDisplayInfo(native, slot)
    if not native then return nil end
    if native.kind == "spell" or native.kind == "item" then
        local icon = 134400
        if native.kind == "spell" and native.id then
            if C_Spell and C_Spell.GetSpellTexture then
                icon = C_Spell.GetSpellTexture(native.id) or icon
            elseif GetSpellTexture then
                icon = GetSpellTexture(native.id) or icon
            end
        elseif native.kind == "item" and native.id then
            if C_Item and C_Item.GetItemIconByID then
                icon = C_Item.GetItemIconByID(native.id) or icon
            elseif GetItemIcon then
                icon = GetItemIcon(native.id) or icon
            end
        end
        return {
            name = native.name or native.token,
            kind = native.kind,
            id = native.id,
            slot = slot,
            icon = icon,
            actionKey = native.actionKey,
        }
    elseif native.kind == "macro" then
        return { kind = "macro", slot = slot, name = "Macro", icon = 134400 }
    end
    return nil
end

--- Any entry in `groups` with unit-frame hovercast enabled?
local function GroupsHaveHovercast(groups)
    for g = 1, #groups do
        local entries = groups[g].entries
        for e = 1, #entries do
            local sub = entries[e].sub
            if sub and sub.targets and sub.targets.hovercastEnabled ~= false then
                return true
            end
        end
    end
    return false
end

-- Slot occupancy cache: skip ACTIONBAR_SLOT_CHANGED storms from macro
-- conditional flips where the spell/item identity on the slot did not change.
-- Extra / SpellRank / Flyout peek on the event *before* Bars/Watch Flush.
-- Those peeks used to write lastSlotSpellCache and schedule After(0) which
-- wiped prev + the wave memo — Watch's After(0) Flush then saw no change
-- and never notified Binding. occupancyDirty stays set until Watch consumes
-- it; After(0) only clears the per-wave memo.
local lastSlotSpellCache = {}
local prevSlotSpellCache = {}
local occupancyDirty = {}
local peekWaveResult = {}
local peekWaveScheduled = false

local function SchedulePeekWaveClear()
    if peekWaveScheduled then return end
    peekWaveScheduled = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            wipe(peekWaveResult)
            peekWaveScheduled = false
        end)
    else
        wipe(peekWaveResult)
        peekWaveScheduled = false
    end
end

local function BuildOccupancyKey(slotNum)
    if not slotNum or slotNum <= 0 or not GetActionInfo then
        return ""
    end
    local actionType, id = GetActionInfo(slotNum)
    -- Type+id only. Shown-spell flips on a bar macro are display, not a
    -- new occupant — treating them as occupancy Binding-Applies every hop.
    return (actionType or "") .. ":" .. tostring(id or "")
end

function _G.FluxActionBarPeekSlotOccupancyChanged(slotNum)
    slotNum = tonumber(slotNum)
    if not slotNum or slotNum <= 0 or not GetActionInfo then
        return true
    end
    if peekWaveResult[slotNum] ~= nil then
        return occupancyDirty[slotNum] == true
    end
    local key = BuildOccupancyKey(slotNum)
    local changed = (lastSlotSpellCache[slotNum] ~= key)
    if changed then
        occupancyDirty[slotNum] = true
        prevSlotSpellCache[slotNum] = lastSlotSpellCache[slotNum]
        lastSlotSpellCache[slotNum] = key
    end
    peekWaveResult[slotNum] = occupancyDirty[slotNum] == true
    SchedulePeekWaveClear()
    return occupancyDirty[slotNum] == true
end

function _G.FluxActionBarPeekSlotOccupancyPrevious(slotNum)
    slotNum = tonumber(slotNum)
    if not slotNum then
        return nil
    end
    return prevSlotSpellCache[slotNum]
end

function _G.FluxActionBarConsumeOccupancyDirty(slotNum)
    slotNum = tonumber(slotNum)
    if not slotNum then
        return
    end
    occupancyDirty[slotNum] = nil
    prevSlotSpellCache[slotNum] = nil
end

function _G.FluxActionBarConsumeAllOccupancyDirty()
    wipe(occupancyDirty)
    wipe(prevSlotSpellCache)
end

--- Flux perf: fill occupancy keys at login / after Binding apply so the first
--- buff-driven ACTIONBAR_SLOT_CHANGED does not look like a cold miss (nil→key)
--- and fan out Binding Apply + Identity + TranslateMacro wipe.
function _G.FluxActionBarSeedSlotOccupancyCache()
    if not GetActionInfo then return end
    -- 1..180 covers main/bonus/override/vehicle pages used by Flux bars.
    for slot = 1, 180 do
        lastSlotSpellCache[slot] = BuildOccupancyKey(slot)
    end
    wipe(peekWaveResult)
    wipe(prevSlotSpellCache)
    wipe(occupancyDirty)
end

function _G.FluxActionBarPeekSlotOccupancy_ClearCache()
    wipe(lastSlotSpellCache)
    wipe(prevSlotSpellCache)
    wipe(occupancyDirty)
    wipe(peekWaveResult)
end

--- Compute the full desired state:
---   slotTexts      = { [slot] = text }              -- keyboard emission (cast)
---   slotHoverTexts = { [slot] = hoverText }         -- UF emission (display peek + routing)
---   slotBadges     = { [slot] = badgeList }
---   freeChords     = { [normChord] = { text, hoverText, mouse } }
---   hoverChords    = { [normChord] = hoverText }    -- UF routing for slot + free chords
---   clickThrough   = { [normChord] = col }          -- Alt/SHIFT+CTRL → FluxActionStripButton{col}
local function ColumnBaseKey(col)
    col = tonumber(col)
    if not col or not ChordMap or not ChordMap.COLUMN_BINDING_NAME then return nil end
    local bindName = ChordMap.COLUMN_BINDING_NAME[col]
    if not bindName then return nil end
    local key = GetBindingKey(bindName)
    if not key or key == "" then return nil end
    return select(1, ChordMap.Parse(key))
end

local function BindingWantsAnyMod(binding)
    if not binding or type(binding.forms) ~= "table" then return false, false end
    local wantAlt, wantSC = false, false
    for _, sub in pairs(binding.forms) do
        local a, s = Conditions.ResolvedModFlags(sub, binding)
        if a then wantAlt = true end
        if s then wantSC = true end
    end
    return wantAlt, wantSC
end

local function AddClickThroughChord(want, freeChords, chord, col)
    if not chord or not col then return end
    local nk = ChordMap.Normalize(chord)
    if nk == "" then return end
    if freeChords and freeChords[nk] then return end
    want[nk] = col
end

--- Resolve bar click-through chords for gated mod conditions on a slot-routed binding.
local function AppendModClickThrough(want, freeChords, binding, route, slot)
    if not binding or not route or route.kind ~= "slot" or not route.col then return end
    local wantAlt, wantSC = BindingWantsAnyMod(binding)
    if not wantAlt and not wantSC then return end

    local col = route.col
    local base = ColumnBaseKey(col)
    if not base or base == "" then return end

    local row = route.row or "main"
    if not slot and route.slotsByForm then
        slot = route.slotsByForm.noform
        if not slot then
            for _, s in pairs(route.slotsByForm) do
                slot = s
                break
            end
        end
    end
    local shared = Conditions.SlotHasShiftAndCtrlChords and Conditions.SlotHasShiftAndCtrlChords(slot)

    if wantAlt and wantSC then
        AddClickThroughChord(want, freeChords, "ALT-CTRL-SHIFT-" .. base, col)
        if shared then
            AddClickThroughChord(want, freeChords, "ALT-SHIFT-" .. base, col)
            AddClickThroughChord(want, freeChords, "ALT-CTRL-" .. base, col)
        elseif row == "secondary" then
            -- Still allow Alt+Shift (paging) without requiring the full triple chord only.
            AddClickThroughChord(want, freeChords, "ALT-SHIFT-" .. base, col)
        elseif row == "tertiary" then
            AddClickThroughChord(want, freeChords, "ALT-CTRL-" .. base, col)
        end
    elseif wantSC then
        AddClickThroughChord(want, freeChords, "CTRL-SHIFT-" .. base, col)
    elseif wantAlt then
        if shared then
            AddClickThroughChord(want, freeChords, "ALT-SHIFT-" .. base, col)
            AddClickThroughChord(want, freeChords, "ALT-CTRL-" .. base, col)
            -- Bare Alt still useful when the shared mini is also promoted to main.
            AddClickThroughChord(want, freeChords, "ALT-" .. base, col)
        elseif row == "secondary" then
            AddClickThroughChord(want, freeChords, "ALT-SHIFT-" .. base, col)
        elseif row == "tertiary" then
            AddClickThroughChord(want, freeChords, "ALT-CTRL-" .. base, col)
        else
            AddClickThroughChord(want, freeChords, "ALT-" .. base, col)
        end
    end
end

local function BuildModClickThrough(freeChords)
    local want = {}
    for uid, b in pairs(DB.All()) do
        local wantAlt, wantSC = BindingWantsAnyMod(b)
        if wantAlt or wantSC then
            local route, slot
            if b.key and b.key ~= "" then
                local _, r = ChordMap.SlotsForChord(ChordMap.Normalize(b.key))
                route = r
            else
                local info = FluxBinding.GetEditorOverlap and FluxBinding.GetEditorOverlap(b.action, uid)
                if info then
                    route = info.route
                    slot = info.slot
                end
            end
            if route and route.kind == "slot" then
                AppendModClickThrough(want, freeChords, b, route, slot)
            end
        end
    end
    return want
end

local function OverlayIdleBody(text, clauses, extras)
    if type(text) ~= "string" or text == "" then
        return nil
    end
    if not (Factory.IsFactoryMouseover and Factory.IdleMacroText) then
        return nil
    end
    local before, after
    if type(extras) == "table" then
        before, after = extras.before, extras.after
    end
    if not Factory.IsFactoryMouseover(text, clauses, false, before, after) then
        return nil
    end
    local idle = Factory.IdleMacroText(text, true)
    if type(idle) == "string" and idle ~= "" and idle ~= text then
        return idle
    end
    return nil
end

local function ComputePlan(slotSet)
    local slotTexts, slotHoverTexts, slotBadges, freeChords, hoverChords, slotModes, slotIdles = {}, {}, {}, {}, {}, {}, {}
    local mouseoverCast = MouseoverCastEnabled()
    local function WantSlot(slot)
        if not slotSet then
            return true
        end
        return slotSet[tonumber(slot) or slot] == true
    end

    -- 1. explicit chord buckets
    local buckets = {}
    local SpellLib = ns.FluxBindingSpellLibrary
    for uid, b in pairs(DB.All()) do
        -- Stamp pet flag on legacy pet-ability rows so they stay sticky/general.
        if b.action and b.action.type == "spell" and b.action.id and not b.action.pet then
            if SpellLib and SpellLib.IsPetAbilitySpell and SpellLib.IsPetAbilitySpell(b.action.id) then
                b.action.pet = true
            end
        end
        if b.action and b.action.pet and b.action.id and SpellLib and SpellLib.RememberPetAbilitySpell then
            SpellLib.RememberPetAbilitySpell(b.action.id)
        end
        if b.key and Action.IsAvailable(b.action) then
            local nk = ChordMap.Normalize(b.key)
            if nk ~= "" then
                local bucket = buckets[nk]
                if not bucket then
                    bucket = {}
                    buckets[nk] = bucket
                end
                bucket[#bucket + 1] = b
            end
        end
    end

    -- 2. occupancy overlays: customized settings follow the live occupant
    -- (keyed-on-bar rows included so cursor-cast / extras ride drag/drop).
    local implicitByActionKey = {}
    for uid, b in pairs(DB.All()) do
        if b.action and b.action.type == "spell" and b.action.id and not b.action.pet then
            if SpellLib and SpellLib.IsPetAbilitySpell and SpellLib.IsPetAbilitySpell(b.action.id) then
                b.action.pet = true
            end
        end
        if b.action and Action.IsAvailable(b.action) then
            local anyNonDefault = false
            for token, sub in pairs(b.forms or {}) do
                if IsSubNonDefault(sub) then
                    anyNonDefault = true
                    break
                end
            end
            if anyNonDefault then
                local ak = Action.FamilyKey(b.action) or Action.Key(b.action)
                if ak then
                    implicitByActionKey[ak] = implicitByActionKey[ak] or {}
                    table.insert(implicitByActionKey[ak], b)
                end
                -- Also index per-rank key so unsynced lookups still find the row.
                local rk = Action.Key(b.action)
                if rk and rk ~= ak then
                    implicitByActionKey[rk] = implicitByActionKey[rk] or {}
                    table.insert(implicitByActionKey[rk], b)
                end
            end
        end
    end

    -- slots the bar can display, for the implicit scan
    local SlotHost = ns.FluxSlotHost
    local implicitSlotEntries = {}
    local slotsByActionKey = {}
    local function NoteActionSlot(slot, actionKey)
        if not actionKey then
            return
        end
        local t = slotsByActionKey[actionKey]
        if not t then
            t = {}
            slotsByActionKey[actionKey] = t
        end
        t[slot] = true
    end
    local function ConsiderImplicitSlot(slot, native)
        if native.actionKey and implicitByActionKey[native.actionKey] then
            local filtered = FilterBindingsForBarSlot(implicitByActionKey[native.actionKey], slot)
            if #filtered > 0 then
                implicitSlotEntries[slot] = {
                    native = native,
                    bindings = filtered,
                }
            end
        end
    end
    if slotSet then
        for slot, occ in pairs(lastSlotSpellCache) do
            NoteActionSlot(slot, OccupancyKeyToActionKey(occ))
        end
        if next(implicitByActionKey) then
            for slot in pairs(slotSet) do
                slot = tonumber(slot) or slot
                local native = SlotNative(slot)
                NoteActionSlot(slot, native.actionKey)
                ConsiderImplicitSlot(slot, native)
            end
        end
    elseif SlotHost then
        for slot in pairs(SlotHost.GetAllBarSlots()) do
            local native = SlotNative(slot)
            NoteActionSlot(slot, native.actionKey)
            if next(implicitByActionKey) then
                ConsiderImplicitSlot(slot, native)
            end
        end
    end

    -- 3. slot programs from explicit chords
    for nk, bucket in pairs(buckets) do
        local bySlot, route = ChordMap.SlotsForChord(nk)
        if route and route.kind == "slot" and bySlot then
            -- Per-form natives for the shared UF _HC body. First-wins from a
            -- single slot used to bake noform host into hoverChords[nk], so a
            -- form page's native never ran on that shared hover path.
            local nativesByForm = {}
            if not slotSet and route.slotsByForm then
                for token, slot in pairs(route.slotsByForm) do
                    local n = SlotNative(slot)
                    if n.kind ~= "macro" and n.kind ~= "other" and n.token then
                        nativesByForm[token] = n
                    end
                end
            end
            local fallbackToken
            for i = 1, #bucket do
                if bucket[i].fallback == "BINDING" then
                    fallbackToken = Action.MacroToken(bucket[i].action, { includeSubtext = true })
                    break
                end
            end

            for slot, tokens in pairs(bySlot) do
                if not WantSlot(slot) then
                    -- occupancy path: leave this slot's existing overlay alone
                else
                local native = SlotNative(slot)
                if native.kind == "empty" then
                    -- Dragged-clear / blank slot: omit from plan so
                    -- SlotProgram + BadgeHost clearMissing wipe leftovers.
                    -- A chord that already has a binding is not blank: Forever
                    -- can fail GetActionInfo while the button still shows Smite.
                    -- Keep the slot so keypress clauses and a static badge install.
                    -- The bar-spell tail is added only when a native token exists.
                    local chordHasBinding = false
                    for bi = 1, #bucket do
                        if bucket[bi] and bucket[bi].key then
                            chordHasBinding = true
                            break
                        end
                    end
                    if not chordHasBinding then
                        if implicitSlotEntries[slot] then
                            implicitSlotEntries[slot] = nil
                        end
                    else
                        native = { kind = "spell", unread = true }
                    end
                end
                if native.kind ~= "macro" and native.kind ~= "other" and native.kind ~= "empty" then
                    -- Occupancy: skip a binding whose action now lives on another
                    -- bar slot so cursor-cast does not wrap the new occupant.
                    local slotBucket = FilterBucketForBarSlot(bucket, slot, native, slotsByActionKey)
                    local groups = BuildGroupsForSlot(slotBucket, tokens, nk)
                    local badgeBindings = {}
                    local seenUid = {}
                    for i = 1, #slotBucket do
                        badgeBindings[#badgeBindings + 1] = slotBucket[i]
                        if slotBucket[i].uid then
                            seenUid[slotBucket[i].uid] = true
                        end
                    end
                    local imp = implicitSlotEntries[slot]
                    if imp then
                        local impGroup = { formCond = nil, entries = {} }
                        for _, b in ipairs(imp.bindings) do
                            if not seenUid[b.uid] then
                                badgeBindings[#badgeBindings + 1] = b
                                seenUid[b.uid] = true
                                local sub = SubForToken(b, tokens[1])
                                if sub and Conditions.IsActive(b, tokens[1]) and IsSubNonDefault(sub) then
                                    impGroup.entries[#impGroup.entries + 1] = { binding = b, sub = sub }
                                end
                            end
                        end
                        if #impGroup.entries > 0 then
                            impGroup.entries = PreferModEntriesFirst(impGroup.entries)
                            groups = groups or {}
                            table.insert(groups, 1, impGroup)
                        end
                        implicitSlotEntries[slot] = nil -- consumed
                    end
                    if groups then
                        local multiCastExtras = CollectMultiCastExtras(groups, slot)
                        local text, clauses = Factory.BuildForward({
                            groups = groups,
                            native = native,
                            mouseoverCast = mouseoverCast,
                            fallbackToken = fallbackToken,
                            multiCastExtras = multiCastExtras,
                        })
                        local hoverText, hoverClauses
                        if GroupsHaveHovercast(groups) then
                            -- Per-slot hover for badge peek / LAB display only.
                            hoverText, hoverClauses = Factory.BuildHover({
                                groups = groups,
                                native = native,
                                mouseoverCast = mouseoverCast,
                                fallbackToken = fallbackToken,
                                multiCastExtras = multiCastExtras,
                            })
                        end
                        -- hover_only: no keyboard overlay — still install a native-only
                        -- slot program so the strip stays on the macrotext display path
                        -- (icons flip via UF peek override).
                        if not text and hoverText then
                            text, clauses = Factory.BuildForward({
                                groups = groups,
                                native = native,
                                mouseoverCast = false,
                                fallbackToken = fallbackToken,
                                forceNativeTail = true,
                                multiCastExtras = multiCastExtras,
                            })
                        end
                        -- Cold bar-spell name: the native tail cannot be written, and
                        -- preferNativeTail would also drop the keypress rows. Rebuild
                        -- from the binding alone so the key still casts.
                        if not text then
                            text, clauses = Factory.BuildForward({
                                groups = groups,
                                native = nil,
                                mouseoverCast = false,
                                fallbackToken = fallbackToken,
                                multiCastExtras = multiCastExtras,
                            })
                        end
                        if text then
                            slotTexts[slot] = text
                            slotModes[slot] = Factory.StripOverlayMode(text, clauses, multiCastExtras)
                            slotIdles[slot] = OverlayIdleBody(text, clauses, multiCastExtras)
                        end
                        if hoverText then
                            slotHoverTexts[slot] = hoverText
                        end
                        if native.actionKey or native.unread then
                            local badges = BuildBadges(slot, native, nk, badgeBindings, clauses, tokens, hoverClauses)
                            if badges then
                                slotBadges[slot] = badges
                            end
                        end
                    end
                end
                end
            end

            -- Chord-level UF routing: one body with form-scoped native tails.
            if not slotSet then
            local chordGroups = BuildGroupsForSlot(bucket, Forms.GetTokens(), nk)
            if chordGroups and GroupsHaveHovercast(chordGroups) then
                local hoverCtx = {
                    groups = chordGroups,
                    mouseoverCast = mouseoverCast,
                    fallbackToken = fallbackToken,
                }
                if next(nativesByForm) then
                    hoverCtx.nativesByForm = nativesByForm
                end
                local hoverText = Factory.BuildHover(hoverCtx)
                if hoverText then
                    hoverChords[nk] = hoverText
                end
            end
            end
        elseif route and route.kind == "free" then
            -- 4. free chords: merged macro on a pooled secure button
            -- (per-form conditionals baked across ALL tokens)
            if not slotSet then
            local groups = BuildGroupsForSlot(bucket, Forms.GetTokens(), nk, { includeDefaultKeyed = true })
            if groups then
                -- keyboard emission: no hovercast legs. UF-only (hover_only)
                -- bindings yield text = nil -> world press stays inert.
                local text = Factory.BuildForward({
                    groups = groups,
                    native = nil,
                    mouseoverCast = false,
                })
                local hoverText
                if GroupsHaveHovercast(groups) then
                    hoverText = Factory.BuildHover({
                        groups = groups,
                        native = nil,
                        mouseoverCast = false,
                    })
                end
                if text or hoverText then
                    freeChords[nk] = {
                        text = text,
                        hoverText = hoverText,
                        mouse = ChordMap.IsMouseChord(nk),
                    }
                end
            end
            end
        end
    end

    -- 5. leftover implicit-only slots (customized profile, no shared chord)
    for slot, info in pairs(implicitSlotEntries) do
        if WantSlot(slot) and not slotTexts[slot] then
            local group = { formCond = nil, entries = {} }
            for _, b in ipairs(info.bindings) do
                local sub = SubForToken(b, "noform")
                if sub and Conditions.IsActive(b, "noform") and IsSubNonDefault(sub) then
                    group.entries[#group.entries + 1] = { binding = b, sub = sub }
                end
            end
            if #group.entries > 0 then
                group.entries = PreferModEntriesFirst(group.entries)
                local groups = { group }
                local multiCastExtras = CollectMultiCastExtras(groups, slot)
                local text, clauses = Factory.BuildForward({
                    groups = groups,
                    native = info.native,
                    mouseoverCast = mouseoverCast,
                    multiCastExtras = multiCastExtras,
                })
                local hoverText, hoverClauses
                if GroupsHaveHovercast(groups) then
                    hoverText, hoverClauses = Factory.BuildHover({
                        groups = groups,
                        native = info.native,
                        mouseoverCast = mouseoverCast,
                        multiCastExtras = multiCastExtras,
                    })
                end
                if not text and hoverText then
                    text, clauses = Factory.BuildForward({
                        groups = groups,
                        native = info.native,
                        mouseoverCast = false,
                        fallbackToken = nil,
                        forceNativeTail = true,
                        multiCastExtras = multiCastExtras,
                    })
                end
                if text then
                    slotTexts[slot] = text
                    slotModes[slot] = Factory.StripOverlayMode(text, clauses, multiCastExtras)
                    slotIdles[slot] = OverlayIdleBody(text, clauses, multiCastExtras)
                end
                if hoverText then
                    slotHoverTexts[slot] = hoverText
                    local nk = ChordForSlot(slot)
                    if nk and not hoverChords[nk] then
                        hoverChords[nk] = hoverText
                    end
                end
                local nk = ChordForSlot(slot)
                if nk and info.native and info.native.actionKey then
                    local badges = BuildBadges(slot, info.native, nk, info.bindings, clauses, { "noform" }, hoverClauses)
                    if badges then
                        slotBadges[slot] = badges
                    end
                end
            end
        end
    end

    local clickThrough = BuildModClickThrough(freeChords)
    return slotTexts, slotHoverTexts, slotBadges, freeChords, hoverChords, clickThrough, slotModes, slotIdles
end

-- ---------------------------------------------------------------------------
-- Free-chord override application (diff-based)
-- ---------------------------------------------------------------------------

local overrideOwner = CreateFrame("Frame", "FluxBinding3OverrideOwner", UIParent)
local appliedFree = {}  -- normChord -> { text, btnName }  (world override installed)
local appliedHover = {} -- normChord -> { text, btnName }  (_HC UF hover body button)
local appliedClickThrough = {} -- normChord -> col (Alt/SHIFT+CTRL → bar button)
local lastHoverRoutingSig = nil

local function PoolButtonName(nk)
    return "FluxBinding3Btn_" .. nk:gsub("[^%w]", "_")
end

--- Dedicated sibling button for the UF hover emission (backup `_HC` parity):
--- the world override button keeps the keyboard macro, this one carries the
--- hovercast body that only fires while the cursor is over a unit frame.
local function HoverButtonName(nk)
    return PoolButtonName(nk) .. "_HC"
end

--- Pool.Acquire arms key-down / press-and-hold proxies. Midnight treats a
--- secure SetBindingClick as a mouse press and ignores that down click, so
--- the hover button must also hear the up click and must not press-and-hold.
--- Do not set typerelease here: the up click would cast a second time.
local function ArmHovercastClick(btn, body)
    if not btn or not btn.SetAttribute or type(body) ~= "string" then
        return
    end
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("type1", "macro")
    btn:SetAttribute("macro", nil)
    btn:SetAttribute("macrotext", body)
    btn:SetAttribute("macrotext1", body)
    btn:SetAttribute("flux-macrotext-hovercast", body)
    btn:SetAttribute("pressAndHoldAction", false)
    btn:SetAttribute("useOnKeyDown", true)
    btn:SetAttribute("typerelease", nil)
    btn:SetAttribute("typerelease1", nil)
    if btn.RegisterForClicks then
        pcall(btn.RegisterForClicks, btn, "AnyDown", "AnyUp")
    end
end

--- freeChords:  { [nk] = { text|nil, hoverText|nil, mouse } } — pool overrides
--- hoverChords: { [nk] = hoverText } — slot-routed chords with UF hovercast
--- clickThrough: { [nk] = col } — Alt/SHIFT+CTRL bar redirects; also claimed for UF _HC
local function ApplyFreeChords(freeChords, hoverChords, clickThrough)
    if InCombatLockdown() then return end
    hoverChords = hoverChords or {}
    clickThrough = clickThrough or {}

    -- desired UF hover bodies across both chord kinds
    local wantHover = {}
    for nk, body in pairs(hoverChords) do
        wantHover[nk] = body
    end
    for nk, want in pairs(freeChords) do
        if want.hoverText then
            wantHover[nk] = want.hoverText
        end
    end

    -- remove stale world overrides (chord gone, or turned hover_only)
    for nk, info in pairs(appliedFree) do
        local want = freeChords[nk]
        if not want or not want.text then
            SetOverrideBinding(overrideOwner, false, nk, nil)
            if Pool and Pool.Retire then
                Pool.Retire(info.btnName)
            end
            appliedFree[nk] = nil
        end
    end
    -- remove stale hover bodies
    for nk, info in pairs(appliedHover) do
        if not wantHover[nk] then
            if Pool and Pool.Retire then
                Pool.Retire(info.btnName)
            end
            appliedHover[nk] = nil
        end
    end

    local PushPress = ns.FluxBindingPushPress or _G.FluxBindingPushPress
    if PushPress and PushPress.WipeUfHover then
        PushPress.WipeUfHover()
    end

    -- add / update world overrides (hover_only chords install none: world
    -- presses stay inert / native, matching backup bind mode "hover_only")
    for nk, want in pairs(freeChords) do
        if want.text then
            local cur = appliedFree[nk]
            local btnName = (cur and cur.btnName) or PoolButtonName(nk)
            local btn = Pool and Pool.Acquire and Pool.Acquire(btnName)
            if btn and (not cur or cur.text ~= want.text) then
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macro", nil)
                btn:SetAttribute("macrotext", want.text)
                if not cur then
                    SetOverrideBindingClick(overrideOwner, false, nk, btnName, "LeftButton")
                end
                appliedFree[nk] = { text = want.text, btnName = btnName }
            end
            if btn and PushPress and PushPress.BindButton then
                PushPress.BindButton(btn, nk)
            end
        end
    end

    -- add / update UF hover bodies on dedicated _HC buttons (sorted for a
    -- stable routing signature)
    local hoverNks = {}
    for nk in pairs(wantHover) do
        hoverNks[#hoverNks + 1] = nk
    end
    table.sort(hoverNks)

    local hoverKeys, hoverBtns, hoverBodies, hoverSet
    for i = 1, #hoverNks do
        local nk = hoverNks[i]
        local body = wantHover[nk]
        local cur = appliedHover[nk]
        local btnName = (cur and cur.btnName) or HoverButtonName(nk)
        local btn = Pool and Pool.Acquire and Pool.Acquire(btnName)
        if btn then
            -- Restamp every apply. Pool.Acquire leaves press-and-hold on a
            -- reused button, and a matching body must not keep that contract.
            ArmHovercastClick(btn, body)
            appliedHover[nk] = { text = body, btnName = btnName }
            if PushPress and PushPress.BindButton then
                PushPress.BindButton(btn, nk)
            end
            if PushPress and PushPress.RegisterUfHover then
                PushPress.RegisterUfHover(btnName, nk)
            end
            hoverKeys = hoverKeys or {}
            hoverBtns = hoverBtns or {}
            hoverBodies = hoverBodies or {}
            hoverSet = hoverSet or {}
            hoverKeys[#hoverKeys + 1] = nk
            hoverBtns[#hoverBtns + 1] = btnName
            hoverBodies[#hoverBodies + 1] = body
            hoverSet[nk] = true
        end
    end

    -- While over a unit frame, Alt / SHIFT+CTRL must hit the same _HC hover body
    -- (not FluxActionButton via bar mod synthesis / world click-through).
    if clickThrough and hoverKeys and #hoverKeys > 0 and ChordMap and ChordMap.Parse then
        local byBase = {}
        for i = 1, #hoverKeys do
            local base = ChordMap.Parse(hoverKeys[i])
            if base and base ~= "" then
                byBase[base] = byBase[base] or {}
                byBase[base][#byBase[base] + 1] = i
            end
        end
        local function PickHoverIndex(ctNk)
            local base, mods = ChordMap.Parse(ctNk)
            local idxs = base and byBase[base]
            if not idxs or #idxs == 0 then return nil end
            local wantMain = not (mods and (mods.shift or mods.ctrl))
            local wantSec = mods and mods.shift and true or false
            local wantTert = mods and mods.ctrl and not mods.shift
            local fallback = idxs[1]
            for j = 1, #idxs do
                local hi = idxs[j]
                local _, hm = ChordMap.Parse(hoverKeys[hi])
                local isMain = not (hm and (hm.shift or hm.ctrl))
                local isSec = hm and hm.shift and not hm.ctrl
                local isTert = hm and hm.ctrl and not hm.shift
                if wantMain and isMain then return hi end
                if wantSec and isSec then return hi end
                if wantTert and isTert then return hi end
                if wantSec and (isSec or isTert) then fallback = hi end
                if wantTert and (isTert or isSec) then fallback = hi end
            end
            return fallback
        end
        local ctList = {}
        for ctNk in pairs(clickThrough) do
            ctList[#ctList + 1] = ctNk
        end
        table.sort(ctList)
        for c = 1, #ctList do
            local ctNk = ctList[c]
            if not hoverSet[ctNk] then
                local hi = PickHoverIndex(ctNk)
                if hi then
                    hoverKeys[#hoverKeys + 1] = ctNk
                    hoverBtns[#hoverBtns + 1] = hoverBtns[hi]
                    hoverBodies[#hoverBodies + 1] = hoverBodies[hi]
                    hoverSet[ctNk] = true
                    if PushPress and PushPress.RegisterUfHover then
                        PushPress.RegisterUfHover(hoverBtns[hi], ctNk)
                    end
                end
            end
        end
    end

    -- unit-frame hover routing for ALL hover chords — keyboard, wheel, and
    -- mouse buttons (only on change: SetUfHoverRouting reapplies secure attrs
    -- on every registered unit frame)
    local sig = hoverKeys and table.concat(hoverKeys, "\1") or ""
    if hoverBodies then
        sig = sig .. "\2" .. table.concat(hoverBodies, "\1")
    end
    if sig ~= lastHoverRoutingSig then
        local MK = _G.FluxMouseoverKeybindModule
        if MK and MK.SetUfHoverRouting then
            local ok, pushed = pcall(MK.SetUfHoverRouting, MK,
                hoverKeys or {}, hoverBtns or {}, hoverSet or {}, hoverBodies or {})
            -- Only advance signature after a successful OOC secure push so combat
            -- deferrals retry on the next Apply / regen flush.
            if ok and pushed ~= false then
                lastHoverRoutingSig = sig
            else
                lastHoverRoutingSig = nil
            end
        elseif not MK then
            -- Module not loaded yet — keep signature unset so the next Apply retries.
            lastHoverRoutingSig = nil
        else
            lastHoverRoutingSig = sig
        end
    elseif _G.FluxMouseoverKeybindModule
        and _G.FluxMouseoverKeybindModule.HasPendingHoverRouting
        and _G.FluxMouseoverKeybindModule:HasPendingHoverRouting() then
        local MK = _G.FluxMouseoverKeybindModule
        if MK.FlushPendingHoverRouting then
            pcall(MK.FlushPendingHoverRouting, MK)
        end
    end
end

local function MainStripButtonName(col)
    col = tonumber(col)
    if not col then
        return nil
    end
    local Flux = ns.Flux
    local rec = Flux and Flux.Bars and Flux.Bars.GetHost and Flux.Bars.GetHost(col)
    local widget = rec and rec.main and rec.main.widget
    if widget and widget.GetName then
        local n = widget:GetName()
        if type(n) == "string" and n ~= "" then
            return n
        end
    end
    return "FluxActionStripButton" .. col
end

--- Redirect Alt / SHIFT+CTRL (+combo) chords onto the column's main strip
--- widget so gated [mod:…] clauses on the shared-slot macro can fire.
--- Click button is KeyBind (same as Bars/Clicks). Free-pool chords win.
local function ApplyBarModClickThrough(clickThrough, freeChords)
    clickThrough = clickThrough or {}
    freeChords = freeChords or {}
    if InCombatLockdown() then return end

    for nk, col in pairs(appliedClickThrough) do
        if not clickThrough[nk] then
            -- Do not wipe an override that ApplyFreeChords just installed on this nk.
            local free = freeChords[nk]
            if not (free and free.text) then
                SetOverrideBinding(overrideOwner, false, nk, nil)
            end
            appliedClickThrough[nk] = nil
        end
    end

    for nk, col in pairs(clickThrough) do
        col = tonumber(col)
        -- Vehicle/override: keep chords on FluxActionStripButton* (pages via possess).
        -- Never redirect onto Blizzard OverrideActionBarButton* (hidden + tainted).
        if col and not (freeChords[nk] and freeChords[nk].text) and appliedClickThrough[nk] ~= col then
            local btnName = MainStripButtonName(col)
            if btnName and not btnName:find("OverrideActionBar", 1, true) then
                local clickButton = "KeyBind"
                local Flux = ns.Flux
                local Click = Flux and Flux.ButtonFX and Flux.ButtonFX.Click
                if Click and Click.UsesWrap and not Click.UsesWrap() then
                    local keyer = _G["FluxActionStripKey" .. col]
                    if keyer then btnName = keyer:GetName(); clickButton = "LeftButton" end
                end
                SetOverrideBindingClick(overrideOwner, false, nk, btnName, clickButton)
                appliedClickThrough[nk] = col
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Scheduler
-- ---------------------------------------------------------------------------

local applyScheduled = false
local combatPending = false
local lastApplyStats = { slots = 0, badges = 0, free = 0, at = 0 }
local appliedCallbacks = {}
-- Residual applied secure/badge/free state (or pending clear). Idle short-circuit
-- when DB is empty AND this is false.
local appliedLive = false
local lastPlanSig = nil
-- Flux perf: skip ComputePlan when nothing plan-relevant dirtied since last apply
-- (e.g. combat-deferred ScheduleApply with no interim Notify*).
local planDirtyGen = 0
local lastAppliedDirtyGen = -1

local function MarkPlanDirty()
    planDirtyGen = planDirtyGen + 1
end

FluxBinding.MarkPlanDirty = MarkPlanDirty

local occupancyQueue = {}
local occupancyQueued = false

local customizedByActionKey = {}
local customizedIndexValid = false

local function InvalidateCustomizedIndex()
    customizedIndexValid = false
end

local function EnsureCustomizedIndex()
    if customizedIndexValid then
        return
    end
    wipe(customizedByActionKey)
    if not DB then
        customizedIndexValid = true
        return
    end
    DB.Ensure()
    for uid, b in pairs(DB.All()) do
        if b.action then
            local any = false
            for _, sub in pairs(b.forms or {}) do
                if IsSubNonDefault(sub) then
                    any = true
                    break
                end
            end
            if any then
                local function add(k)
                    if not k then
                        return
                    end
                    local t = customizedByActionKey[k]
                    if not t then
                        t = {}
                        customizedByActionKey[k] = t
                    end
                    t[#t + 1] = uid
                end
                add(Action.Key(b.action))
                add(Action.FamilyKey and Action.FamilyKey(b.action))
            end
        end
    end
    customizedIndexValid = true
end

local function OccupancyKeyHasCustomized(occKey)
    local ak = OccupancyKeyToActionKey(occKey)
    return ak and customizedByActionKey[ak] ~= nil
end

local function SlotIsInteresting(slot, prevKey, nowKey)
    if OccupancyKeyHasCustomized(prevKey) or OccupancyKeyHasCustomized(nowKey) then
        return true
    end
    local SP = ns.FluxSlotProgram
    if SP and SP.Get and SP.Get(slot) then
        return true
    end
    local BH = ns.FluxBadgeHost
    if BH and BH.GetSlotBadges and BH.GetSlotBadges(slot) then
        return true
    end
    return false
end

--- Move `ab:` pins with the occupant. Prefer a unique dirty dest so a second
--- copy of the same spell (C vs Z extras) is not stolen.
local function RelocatePlaceIds(dirtyList)
    local relocated = false
    if not DB then
        return nil, relocated
    end
    DB.Ensure()
    local dirtySet
    if type(dirtyList) == "table" then
        dirtySet = {}
        if dirtyList[1] ~= nil then
            for i = 1, #dirtyList do
                local s = tonumber(dirtyList[i])
                if s then
                    dirtySet[s] = true
                end
            end
        else
            for s in pairs(dirtyList) do
                s = tonumber(s)
                if s then
                    dirtySet[s] = true
                end
            end
        end
    end
    for uid, b in pairs(DB.All()) do
        local pid = b and b.placeId
        local placeSlot = type(pid) == "string" and tonumber(pid:match("^ab:(%d+)$"))
        if placeSlot then
            if not NativeMatchesBinding(SlotNative(placeSlot), b) then
                local matches, dirtyMatches = {}, {}
                local seen = {}
                local function considerSlot(slot)
                    slot = tonumber(slot)
                    if not slot or seen[slot] then
                        return
                    end
                    local occ = lastSlotSpellCache[slot]
                    if occ == nil then
                        occ = BuildOccupancyKey(slot)
                    end
                    if OccupancyMatchesBinding(occ, b) then
                        seen[slot] = true
                        matches[#matches + 1] = slot
                        if dirtySet and dirtySet[slot] then
                            dirtyMatches[#dirtyMatches + 1] = slot
                        end
                    end
                end
                for slot in pairs(lastSlotSpellCache) do
                    considerSlot(slot)
                end
                if dirtySet then
                    for slot in pairs(dirtySet) do
                        considerSlot(slot)
                    end
                end
                local pick
                if #dirtyMatches == 1 then
                    pick = dirtyMatches[1]
                elseif (not dirtySet or #dirtyMatches == 0) and #matches == 1 then
                    pick = matches[1]
                end
                if pick and pick ~= placeSlot then
                    b.placeId = "ab:" .. tostring(pick)
                    relocated = true
                    if dirtySet then
                        dirtySet[pick] = true
                        dirtySet[placeSlot] = true
                    end
                end
            end
        end
    end
    return dirtySet, relocated
end

local function RunOccupancyApply(slotSet)
    if InCombatLockdown() then
        combatPending = true
        return
    end
    if not slotSet or not next(slotSet) then
        return
    end
    local slotTexts, slotHoverTexts, slotBadges, _, _, _, slotModes, slotIdles = ComputePlan(slotSet)
    local SlotProgram = ns.FluxSlotProgram
    local BadgeHost = ns.FluxBadgeHost
    local hoverMap = {}
    for slot in pairs(slotSet) do
        slot = tonumber(slot) or slot
        if SlotProgram and SlotProgram.Apply then
            SlotProgram.Apply(slot, slotTexts[slot], slotModes and slotModes[slot], slotIdles and slotIdles[slot])
        end
        hoverMap[slot] = slotHoverTexts[slot] or false
        if BadgeHost and BadgeHost.SetSlotBadges then
            BadgeHost.SetSlotBadges(slot, slotBadges[slot])
        end
    end
    if SlotProgram and SlotProgram.ApplyHoverMap then
        SlotProgram.ApplyHoverMap(hoverMap, false)
    end
    if SlotProgram and SlotProgram.HasAny and SlotProgram.HasAny() then
        appliedLive = true
    elseif BadgeHost and BadgeHost.HasAny and BadgeHost.HasAny() then
        appliedLive = true
    elseif next(appliedFree) or next(appliedHover) then
        appliedLive = true
    else
        appliedLive = false
    end
    local Bars = ns.Flux and ns.Flux.Bars
    if Bars and Bars.RequestPaint then
        Bars.RequestPaint("bars.dirty")
        Bars.RequestPaint("bars.icon")
    end
    for _, fn in pairs(appliedCallbacks) do
        pcall(fn)
    end
end

local function PlanSignature(slotTexts, slotHoverTexts, slotBadges, freeChords, hoverChords, clickThrough)
    local parts = {}
    local function fingerprintValue(v)
        local t = type(v)
        if t == "string" or t == "number" or t == "boolean" then
            return tostring(v)
        end
        if t ~= "table" then
            return tostring(v)
        end
        if v.text ~= nil or v.hoverText ~= nil then
            return tostring(v.text) .. "\0" .. tostring(v.hoverText) .. "\0" .. tostring(v.mouse)
        end
        local chunks = {}
        for i = 1, #v do
            local b = v[i]
            if type(b) == "table" then
                chunks[#chunks + 1] = tostring(b.key) .. ":" .. tostring(b.macrotext) .. ":" .. tostring(b.alpha)
            else
                chunks[#chunks + 1] = tostring(b)
            end
        end
        return table.concat(chunks, ";")
    end
    local function addMap(prefix, map)
        local keys = {}
        for k in pairs(map) do
            keys[#keys + 1] = k
        end
        table.sort(keys, function(a, b)
            local na, nb = tonumber(a), tonumber(b)
            if na and nb then return na < nb end
            return tostring(a) < tostring(b)
        end)
        for i = 1, #keys do
            local k = keys[i]
            parts[#parts + 1] = prefix
            parts[#parts + 1] = tostring(k)
            parts[#parts + 1] = "="
            parts[#parts + 1] = fingerprintValue(map[k])
            parts[#parts + 1] = "\n"
        end
    end
    addMap("S", slotTexts)
    addMap("H", slotHoverTexts)
    addMap("B", slotBadges)
    addMap("F", freeChords)
    addMap("V", hoverChords)
    addMap("C", clickThrough or {})
    return table.concat(parts)
end

local function RunApplyBody()
    applyScheduled = false
    if InCombatLockdown() then
        combatPending = true
        return
    end
    if not DB then return end
    DB.Ensure()

    local occSet
    if occupancyQueued then
        occSet = occupancyQueue
        occupancyQueued = false
        occupancyQueue = {}
    end

    -- Nothing plan-relevant changed since last apply — occupancy drag/drop
    -- still stamps dirty slots without a full-bar ComputePlan.
    local needFull = lastPlanSig == nil or planDirtyGen ~= lastAppliedDirtyGen
    if not needFull then
        if occSet and next(occSet) then
            RunOccupancyApply(occSet)
            return
        end
        _G.FluxBindingApplyCoalesceHits = (_G.FluxBindingApplyCoalesceHits or 0) + 1
        return
    end

    local slotTexts, slotHoverTexts, slotBadges, freeChords, hoverChords, clickThrough, slotModes, slotIdles = ComputePlan()
    local planSig = PlanSignature(slotTexts, slotHoverTexts, slotBadges, freeChords, hoverChords, clickThrough)
    local planUnchanged = (lastPlanSig ~= nil and planSig == lastPlanSig)
    lastPlanSig = planSig
    lastAppliedDirtyGen = planDirtyGen
    _G._fluxBindingPlanUnchanged = planUnchanged
    if planUnchanged then
        _G.FluxBindingApplyCoalesceHits = (_G.FluxBindingApplyCoalesceHits or 0) + 1
        -- Still refresh form badge visibility cheaply if needed; skip secure + Identity storm.
        return
    end

    local SlotProgram = ns.FluxSlotProgram
    local BadgeHost = ns.FluxBadgeHost
    local occupancyChanged = false
    if SlotProgram then
        local prev = SlotProgram.GetAll()
        for slot in pairs(slotTexts) do
            if not prev[slot] then occupancyChanged = true end
        end
        for slot in pairs(prev) do
            if not slotTexts[slot] then occupancyChanged = true end
        end
        local texts = {}
        for slot, text in pairs(slotTexts) do
            texts[slot] = text
        end
        SlotProgram.ApplyMap(texts, true, slotModes, slotIdles)
        if SlotProgram.ApplyHoverMap then
            SlotProgram.ApplyHoverMap(slotHoverTexts, true)
        end
    end
    if BadgeHost then
        BadgeHost.ApplyMap(slotBadges, true)
    end
    ApplyFreeChords(freeChords, hoverChords, clickThrough)
    ApplyBarModClickThrough(clickThrough, freeChords)

    local nSlots, nBadges, nFree, nHover = 0, 0, 0, 0
    for _ in pairs(slotTexts) do nSlots = nSlots + 1 end
    for _ in pairs(slotBadges) do nBadges = nBadges + 1 end
    for _ in pairs(freeChords) do nFree = nFree + 1 end
    for _ in pairs(hoverChords) do nHover = nHover + 1 end
    local planHasWork = nSlots > 0 or nBadges > 0 or nFree > 0 or nHover > 0
    local hadApplied = appliedLive
    appliedLive = planHasWork

    local PushPress = ns.FluxBindingPushPress or _G.FluxBindingPushPress
    if PushPress and PushPress.OnApplyComplete then
        PushPress.OnApplyComplete(planHasWork)
    end

    -- Identity republish via RegisterApplied callback only (avoid double OnApplyComplete).

    -- program set changed slot occupancy -> pack-left / promotion may change
    if occupancyChanged then
        local Bars = ns.Flux and ns.Flux.Bars
        if Bars and Bars.Layout and Bars.Layout.Request then
            Bars.Layout.Request("slot")
        end
    end

    -- After Binding apply: paint strip + badge faces from the new overlay.
    if occupancyChanged or planHasWork or hadApplied then
        local Bars = ns.Flux and ns.Flux.Bars
        if Bars and Bars.RequestPaint then
            Bars.RequestPaint("bars")
        end
        if BadgeHost and BadgeHost.RefreshDisplays then
            BadgeHost.RefreshDisplays()
        end
        local C = ns.Flux and ns.Flux.Context
        if C and C.Request then
            C.Request(true)
        end
    end

    lastApplyStats.slots, lastApplyStats.badges, lastApplyStats.free = nSlots, nBadges, nFree
    lastApplyStats.at = GetTime()
    local Startup = ns.Flux and ns.Flux.Startup
    if Startup then Startup.Mark("spell_bindings_input_ready") end

    for _, fn in pairs(appliedCallbacks) do
        pcall(fn)
    end

    -- Seed after apply so the next buff-driven ASC is not a cold occupancy miss.
    if _G.FluxActionBarSeedSlotOccupancyCache then
        pcall(_G.FluxActionBarSeedSlotOccupancyCache)
    end
end

local function RunApply()
    local Regen = _G.Flux and _G.Flux.Perf and _G.Flux.Perf.Regen
    if Regen and Regen.Time then
        return Regen.Time("binding.RunApply", RunApplyBody)
    end
    return RunApplyBody()
end

local function ScheduleApply()
    if applyScheduled then return end
    applyScheduled = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0, RunApply)
    else
        RunApply()
    end
end

-- Forever/live: C_Spell.GetSpellInfo is nil until the record loads. SlotNative
-- requests the id; this fills the cast token and refreshes the shared-key badge.
local spellDataEv = CreateFrame("Frame")
if pcall(spellDataEv.RegisterEvent, spellDataEv, "SPELL_DATA_LOAD_RESULT") then
    spellDataEv:SetScript("OnEvent", function(_, _, spellID, success)
        if Action and Action.NoteSpellDataLoaded then
            Action.NoteSpellDataLoaded(spellID)
        end
        if success == false then
            return
        end
        MarkPlanDirty()
        ScheduleApply()
    end)
end

-- Bag quantities do not change a multicast macro until an extra becomes
-- available/unavailable. Recompiling every binding for every mail attachment
-- was especially expensive with a populated binding database.
local extrasInventorySignature
local function MacroExtrasInventorySignature()
    local states = {}
    for _, b in pairs(DB.All()) do
        for _, sub in pairs(b.forms or {}) do
            local extras = sub and sub.macro and sub.macro.extras
            for _, e in ipairs(type(extras) == "table" and extras or {}) do
                local id = type(e) == "table" and tonumber(e.id)
                if id and e.type == "item" and states["i" .. id] == nil then
                    states["i" .. id] = DB.IsMacroExtraAvailable(e) and "1" or "0"
                elseif id and e.type == "slot" and states["s" .. id] == nil then
                    states["s" .. id] = tostring(GetInventoryItemID and GetInventoryItemID("player", id)
                        or (GetInventoryItemTexture and GetInventoryItemTexture("player", id)) or 0)
                end
            end
        end
    end
    local parts = {}
    for key, value in pairs(states) do parts[#parts + 1] = key .. "=" .. value end
    table.sort(parts)
    return table.concat(parts, ";")
end

local function RefreshMacroExtrasInventory()
    local signature = MacroExtrasInventorySignature()
    if signature == extrasInventorySignature then return end
    local previous = extrasInventorySignature
    extrasInventorySignature = signature
    if signature ~= "" or (previous and previous ~= "") then
        MarkPlanDirty()
        ScheduleApply()
    end
end

local bagExtrasEv = CreateFrame("Frame")
local bagExtrasPending = false
local inventory = ns.Flux and ns.Flux.Inventory
if inventory and inventory.Register then
    inventory.Register("FluxBindingExtras", RefreshMacroExtrasInventory, {
        tier = "scan", regions = { "bags", "equip" }, deferHeavy = true,
    })
else
    bagExtrasEv:RegisterEvent("BAG_UPDATE")
    bagExtrasEv:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end
bagExtrasEv:SetScript("OnEvent", function()
    if bagExtrasPending then return end
    bagExtrasPending = true
    local function flush()
        bagExtrasPending = false
        RefreshMacroExtrasInventory()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, flush)
    else
        flush()
    end
end)

local regen = CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")
regen:SetScript("OnEvent", function()
    if combatPending then
        combatPending = false
        ScheduleApply()
    end
end)

-- Seed occupancy at login so first player aura → ASC is not a nil→key cold miss.
local seedEv = CreateFrame("Frame")
seedEv:RegisterEvent("PLAYER_ENTERING_WORLD")
seedEv:SetScript("OnEvent", function()
    if _G.FluxActionBarSeedSlotOccupancyCache then
        -- Defer one frame so bars/macros are mounted.
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                pcall(_G.FluxActionBarSeedSlotOccupancyCache)
            end)
            C_Timer.After(1, function()
                pcall(_G.FluxActionBarSeedSlotOccupancyCache)
            end)
        else
            pcall(_G.FluxActionBarSeedSlotOccupancyCache)
        end
    end
end)

-- Badges depend on the live form token. RefreshFormVisibility retranlates
-- reverse faces (combat-legal alpha). Do NOT ScheduleApply here —
-- full apply is blocked in combat and slot macros already bake [form:] tags.
-- When Context is subscribed, form settle is one display pass (ProgramFace).
local function RefreshBadgeForms()
    local C = ns.Flux and ns.Flux.Context
    if C and C.HasSubscribers and C.HasSubscribers() then
        return
    end
    local BadgeHost = ns.FluxBadgeHost or _G.FluxBadgeHost
    if BadgeHost and BadgeHost.RefreshFormVisibility then
        BadgeHost.RefreshFormVisibility()
    end
end

-- Blizzard fires UPDATE_SHAPESHIFT_FORM several times for one shapeshift, and
-- again with an unchanged form. FormStorm edge-filters that into one burst, so
-- a walk of every badge slot happens once instead of three to five times.
local FormStorm = ns.Flux and ns.Flux.FormStorm
if FormStorm and FormStorm.OnBurst then
    FormStorm.OnBurst("binding.badgeforms", RefreshBadgeForms)
else
    local formEv = CreateFrame("Frame")
    formEv:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    pcall(formEv.RegisterEvent, formEv, "UPDATE_STEALTH")
    formEv:SetScript("OnEvent", RefreshBadgeForms)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- True when DB has bindings or residual secure/badge state still needs an apply
--- (including a final clear after the last binding was removed).
function FluxBinding.HasActiveWork()
    if appliedLive then
        return true
    end
    if not DB then return false end
    DB.Ensure()
    for _ in pairs(DB.All()) do
        return true
    end
    return false
end

--- Snapshot for /fluxperf: why HasActiveWork is true/false.
function FluxBinding.GetActiveWorkInfo()
    local n = 0
    if DB then
        DB.Ensure()
        for _ in pairs(DB.All()) do
            n = n + 1
        end
    end
    return {
        active = FluxBinding.HasActiveWork(),
        appliedLive = appliedLive and true or false,
        bindingCount = n,
        lastSlots = lastApplyStats.slots or 0,
        lastBadges = lastApplyStats.badges or 0,
        lastFree = lastApplyStats.free or 0,
    }
end

function FluxBinding.RequestApplyAll(reason)
    if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
        and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
        return
    end
    if DB.IsOverrideActive and DB.IsOverrideActive() then
        return
    end
    if not FluxBinding.HasActiveWork() then
        return
    end
    InvalidateCustomizedIndex()
    MarkPlanDirty()
    ScheduleApply()
end

FluxBinding.NotifyBarReady = FluxBinding.RequestApplyAll
FluxBinding.NotifyBindingsChanged = FluxBinding.RequestApplyAll
FluxBinding.NotifyLoadGatesChanged = FluxBinding.RequestApplyAll
FluxBinding.NotifySettingsChanged = FluxBinding.RequestApplyAll

function FluxBinding.NotifyOccupancyChanged(slots)
    if DB.IsOverrideActive and DB.IsOverrideActive() then
        return
    end
    if not FluxBinding.HasActiveWork() then
        return
    end
    if type(slots) ~= "table" then
        return
    end
    EnsureCustomizedIndex()
    local hadQueue = occupancyQueued
    local dirtySet, relocated = RelocatePlaceIds(slots)
    local interesting = relocated and true or false
    local function consider(slot)
        slot = tonumber(slot)
        if not slot then
            return
        end
        occupancyQueue[slot] = true
        if SlotIsInteresting(slot, prevSlotSpellCache[slot], lastSlotSpellCache[slot]) then
            interesting = true
        end
    end
    if slots[1] ~= nil then
        for i = 1, #slots do
            consider(slots[i])
        end
    else
        for slot in pairs(slots) do
            consider(slot)
        end
    end
    if dirtySet then
        for slot in pairs(dirtySet) do
            consider(slot)
        end
    end
    if not interesting then
        if not hadQueue then
            wipe(occupancyQueue)
            occupancyQueued = false
        end
        return
    end
    occupancyQueued = true
    ScheduleApply()
end

function FluxBinding.NotifyBarSlotChanged(slot)
    slot = tonumber(slot)
    if slot then
        FluxBinding.NotifyOccupancyChanged({ slot })
        return
    end
    FluxBinding.NotifyBarSlotsChanged()
end

function FluxBinding.NotifyBarSlotsChanged(slotSet)
    if DB.IsOverrideActive and DB.IsOverrideActive() then
        return
    end
    if not FluxBinding.HasActiveWork() then
        return
    end
    RelocatePlaceIds(nil)
    occupancyQueued = false
    wipe(occupancyQueue)
    MarkPlanDirty()
    ScheduleApply()
end

function FluxBinding.NotifyBindingChanged(uid)
    if DB.IsOverrideActive and DB.IsOverrideActive() then
        Conditions.InvalidateAvailability(uid)
        return
    end
    InvalidateCustomizedIndex()
    Conditions.InvalidateAvailability(uid)
    -- Always schedule: creating the first binding must leave idle short-circuit.
    appliedLive = true
    lastPlanSig = nil
    MarkPlanDirty()
    if _G.FluxActionBarPeekSlotOccupancy_ClearCache then
        _G.FluxActionBarPeekSlotOccupancy_ClearCache()
    end
    ScheduleApply()
end

function FluxBinding.NotifyBindingsAvailabilityChanged(changedUids)
    if not FluxBinding.HasActiveWork() then
        return
    end
    MarkPlanDirty()
    ScheduleApply()
end

function FluxBinding.NormalizeChord(chord)
    return ChordMap.Normalize(chord)
end

function FluxBinding.FindColumnForChord(chord)
    return ChordMap.FindColumnForChord(chord)
end

function FluxBinding.RegisterApplied(key, fn)
    appliedCallbacks[key] = fn
end

function FluxBinding.GetLastApplyStats()
    return lastApplyStats
end

--- True when this binding may use Cast-tab multi-cast extras:
--- subject is the live bar native on its chord, and no different-action peer
--- bindings share that key (peer badge stacking remains the other model).
function FluxBinding.CanUseMultiCastExtras(binding)
    if not binding or not binding.action then return false end
    local subjectAk = Action.Key(binding.action)
    if not subjectAk then return false end

    local overlap = FluxBinding.GetEditorOverlap(binding.action, binding.uid)
    if not overlap or not overlap.subjectIsNative then
        return false
    end
    if not overlap.native or not overlap.native.actionKey then
        return false
    end
    local matchesNative = (Action.KeysMatch and Action.KeysMatch(binding.action, overlap.native.actionKey))
        or (overlap.native.actionKey == subjectAk)
    if not matchesNative then
        return false
    end

    local peers = overlap.peers or {}
    for i = 1, #peers do
        local p = peers[i]
        if p and p.uid and p.uid ~= binding.uid and p.actionKey then
            local sameFamily = (Action.KeysMatch and Action.KeysMatch(p.action, binding.action))
                or (p.actionKey == subjectAk)
            if not sameFamily then
                return false
            end
        end
    end
    return true
end

--- Attach multi-cast extras + reverse hosts onto an editor-overlap info table.
--- Extras include this binding AND every other binding that shares the chord
--- (peers + reverse multi-cast hosts), so Shares key shows the full multi-cast
--- set for that key — not only the open row's list.
local function AttachMultiCastOverlap(info, binding, actionDesc, subjectUid)
    local formToken = "noform"
    local Ed = ns.FluxBindingEditor
    if Ed and Ed.S and Ed.S.formToken then
        formToken = Ed.S.formToken
    elseif Forms.GetCurrentToken then
        formToken = Forms.GetCurrentToken() or "noform"
    end

    local hosts = DB.FindBindingsUsingMacroExtra(actionDesc, subjectUid) or {}

    local extras, seen = {}, {}
    local function ExtraDedupeKey(row)
        if type(row) ~= "table" then return nil end
        if row.type == "slot" and row.id then
            return "slot:" .. tostring(row.id)
        end
        if row.action and Action and Action.Key then
            return (Action.FamilyKey and Action.FamilyKey(row.action)) or Action.Key(row.action)
        end
        if row.type and row.id then
            return tostring(row.type) .. ":" .. tostring(row.id)
        end
        return nil
    end
    local function AppendExtrasFromBinding(b, hostLabel)
        if not b then return end
        local rows = DB.GetMacroExtrasDisplay(b, formToken)
        local hName = hostLabel
            or (Action and Action.GetName and Action.GetName(b.action))
            or "?"
        for i = 1, #rows do
            local row = rows[i]
            local dk = ExtraDedupeKey(row)
            if dk and not seen[dk] then
                seen[dk] = true
                row.hostUid = b.uid
                row.hostName = hName
                row.hostPlaceId = b.placeId
                row.hostKey = b.key
                extras[#extras + 1] = row
            end
        end
    end

    AppendExtrasFromBinding(binding)

    if info and type(info.peers) == "table" then
        for i = 1, #info.peers do
            local p = info.peers[i]
            if p and p.uid and p.uid ~= subjectUid then
                AppendExtrasFromBinding(DB.Get(p.uid), p.name)
            end
        end
    end

    -- Chord peers may exist even when info.peers is empty (or incomplete):
    -- pull every Flux binding on the shared key / bar chord.
    local nk = info and info.chord
    if (not nk or nk == "") and binding and binding.key and binding.key ~= "" then
        nk = ChordMap.Normalize(binding.key)
    end
    if nk and nk ~= "" then
        for uid, b in pairs(DB.All()) do
            if b and uid ~= subjectUid and b.key and ChordMap.Normalize(b.key) == nk then
                AppendExtrasFromBinding(b)
            end
        end
    end

    -- Bar-native host (often no Flux key): still surface its multi-cast extras.
    if info and info.slot and info.native and info.native.actionKey then
        local wantPid = "ab:" .. tostring(info.slot)
        local nak = info.native.actionKey
        for uid, b in pairs(DB.All()) do
            if b and uid ~= subjectUid and type(b.action) == "table" then
                local matchPlace = b.placeId == wantPid
                local matchAction = (Action.KeysMatch and Action.KeysMatch(b.action, nak))
                    or (Action.Key(b.action) == nak)
                if matchPlace or (matchAction and (not b.key or b.key == "")) then
                    AppendExtrasFromBinding(b, info.native.name)
                end
            end
        end
    end

    -- Reverse hosts (this action is an extra on them): include their full lists.
    for i = 1, #hosts do
        local h = hosts[i]
        if h and h.uid then
            AppendExtrasFromBinding(DB.Get(h.uid), h.name)
        end
    end

    if (not info or not next(info)) and #extras == 0 and #hosts == 0 then
        return info
    end
    info = info or { peers = {}, source = "multicast" }
    info.peers = info.peers or {}
    info.multiCastExtras = extras
    info.multiCastHosts = hosts
    if not info.source and (#extras > 0 or #hosts > 0) then
        info.source = "multicast"
    end
    return info
end

--- Editor: everything sharing a chord (peers + bar native), for shared-key UI.
--- subjectActionKey: optional Action.Key of the editor subject (for unbound /
--- cross-instance subject matching against bar native + peers).
function FluxBinding.GetPeersForChord(chord, subjectUid, subjectActionKey)
    local nk = ChordMap.Normalize(chord or "")
    if nk == "" then return nil end
    local out = { chord = nk, peers = {}, subjectIsNative = false, source = "key" }
    local bySlot, route = ChordMap.SlotsForChord(nk)
    out.route = route
    local subjAk = subjectActionKey
    if not subjAk and subjectUid then
        local subj = DB.Get(subjectUid)
        subjAk = subj and Action.Key(subj.action)
    end
    for uid, b in pairs(DB.All()) do
        if b.key and ChordMap.Normalize(b.key) == nk then
            local pak = Action.Key(b.action)
            out.peers[#out.peers + 1] = {
                uid = uid,
                name = Action.GetName(b.action),
                icon = Action.GetIcon(b.action),
                -- Only the open editor row — sibling same-spell instances stay clickable.
                isSubject = (uid == subjectUid) or nil,
                available = Action.IsAvailable(b.action),
                action = b.action,
                actionKey = pak,
                placeId = b.placeId,
                key = b.key,
            }
        end
    end
    table.sort(out.peers, function(a, b)
        if a.isSubject ~= b.isSubject then return a.isSubject end
        return a.uid < b.uid
    end)
    if route and route.kind == "slot" and bySlot then
        local token = Forms.GetCurrentToken()
        local slot = route.slotsByForm[token] or route.slotsByForm.noform
        if slot then
            local native = SlotNative(slot)
            out.native = NativeDisplayInfo(native, slot)
            out.slot = slot
            if out.native and subjAk and out.native.actionKey == subjAk then
                out.subjectIsNative = true
            end
        end
    end
    return out
end

--- Editor overlap for the current subject: Flux key peers AND/OR bar placement
--- when the spell sits on a keybound action-bar slot without its own Flux key.
--- Also attaches multi-cast extras on this binding and reverse multi-cast hosts.
function FluxBinding.GetEditorOverlap(actionDesc, subjectUid)
    local ak = Action.Key(actionDesc)
    local binding = subjectUid and DB.Get(subjectUid)
    local key = binding and binding.key
    local info
    if key and key ~= "" then
        info = FluxBinding.GetPeersForChord(key, subjectUid, ak)
        if info then
            info.source = "key"
            if info.native and ak and info.native.actionKey == ak then
                info.subjectIsNative = true
            end
        end
        return AttachMultiCastOverlap(info, binding, actionDesc, subjectUid)
    end

    if ak then
        local SlotHost = ns.FluxSlotHost
        if SlotHost and SlotHost.GetAllBarSlots then
            local preferSlot
            local pid = binding and binding.placeId
            if type(pid) == "string" then
                preferSlot = tonumber(pid:match("^ab:(%d+)$"))
            end

            local best
            for slot in pairs(SlotHost.GetAllBarSlots()) do
                local native = SlotNative(slot)
                if native.actionKey == ak then
                    local nk = ChordForSlot(slot)
                    if nk and nk ~= "" then
                        local slotInfo = FluxBinding.GetPeersForChord(nk, subjectUid, ak)
                        if not slotInfo then
                            local _, route = ChordMap.SlotsForChord(nk)
                            slotInfo = {
                                chord = nk,
                                peers = {},
                                slot = slot,
                                native = NativeDisplayInfo(native, slot),
                                subjectIsNative = true,
                                route = route,
                            }
                        else
                            slotInfo.subjectIsNative = true
                            if not slotInfo.native then
                                slotInfo.native = NativeDisplayInfo(native, slot)
                                slotInfo.slot = slot
                            end
                        end
                        slotInfo.source = "bar"
                        if preferSlot and tonumber(slot) == preferSlot then
                            best = slotInfo
                            break
                        end
                        if not best then
                            best = slotInfo
                        elseif slotInfo.route and slotInfo.route.row == "main" then
                            best = slotInfo
                        end
                    end
                end
            end
            info = best
        end
    end

    return AttachMultiCastOverlap(info, binding, actionDesc, subjectUid)
end

--- Editor Status: generated macro preview for a binding.
--- Badge reverse bodies are ONLY for this binding's uid (not peer badges).
function FluxBinding.GetPreviewForBinding(uid)
    local b = DB.Get(uid)
    if not b then return { mode = "none", texts = {} } end
    local out = { mode = "none", texts = {}, parked = Conditions.IsParked(b) }
    local Loc = _G.FluxSpellBindingLocale or {}
    local function add(kind, label, text)
        if type(text) ~= "string" or text == "" then return end
        out.texts[#out.texts + 1] = { kind = kind, label = label, text = text }
    end
    local kbLabel = Loc["status_shared_keyboard_macro"] or "Keyboard / action bar button"
    local ufLabel = Loc["status_shared_uf_hover_macro"] or "Unit frame hover"
    local subjectAk = Action.Key(b.action)
    local subjectName = Action.GetName(b.action)

    local function AddSubjectBadges(slot)
        local BadgeHost = ns.FluxBadgeHost or _G.FluxBadgeHost
        local list = BadgeHost and BadgeHost.GetSlotBadges and BadgeHost.GetSlotBadges(slot)
        if not list then return end
        for _, bd in ipairs(list) do
            if bd.key == uid then
                add("reverse", ("Badge reverse — %s"):format(subjectName), bd.macrotext)
                if bd.hoverMacrotext then
                    add("reverseHover", ("Badge UF reverse — %s"):format(subjectName), bd.hoverMacrotext)
                end
            end
        end
    end

    if not b.key then
        local SlotProgram = ns.FluxSlotProgram
        local saw = false
        local placeSlot = nil
        if type(b.placeId) == "string" then
            placeSlot = tonumber(b.placeId:match("^ab:(%d+)$"))
        end
        if subjectAk and SlotProgram then
            for slot, text in pairs(SlotProgram.GetAll()) do
                if not placeSlot or tonumber(slot) == placeSlot then
                    local native = SlotNative(slot)
                    if native.actionKey == subjectAk then
                        saw = true
                        out.mode = "slot"
                        add("keyboard", ("Slot %d (implicit) — %s"):format(slot, kbLabel), text)
                        if SlotProgram.GetHover then
                            add("hover", ("Slot %d — %s"):format(slot, ufLabel), SlotProgram.GetHover(slot))
                        end
                        AddSubjectBadges(slot)
                    end
                end
            end
        end
        if not saw then
            local overlap = FluxBinding.GetEditorOverlap(b.action, uid)
            if overlap and overlap.slot then
                out.mode = "slot"
                local SlotProgram2 = ns.FluxSlotProgram
                if SlotProgram2 then
                    add("keyboard", kbLabel .. (" (slot %d)"):format(overlap.slot),
                        SlotProgram2.Get(overlap.slot))
                    if SlotProgram2.GetHover then
                        add("hover", ufLabel .. (" (slot %d)"):format(overlap.slot),
                            SlotProgram2.GetHover(overlap.slot))
                    end
                end
                AddSubjectBadges(overlap.slot)
            end
        end
        return out
    end

    local nk = ChordMap.Normalize(b.key)
    local bySlot, route = ChordMap.SlotsForChord(nk)
    local SlotProgram = ns.FluxSlotProgram

    if route and route.kind == "slot" and bySlot then
        out.mode = "slot"
        for slot in pairs(bySlot) do
            local text = SlotProgram and SlotProgram.Get(slot)
            add("keyboard", kbLabel .. (" (slot %d)"):format(slot), text)
            if SlotProgram and SlotProgram.GetHover then
                add("hover", ufLabel .. (" (slot %d)"):format(slot), SlotProgram.GetHover(slot))
            end
            AddSubjectBadges(slot)
        end
    elseif route and route.kind == "free" then
        out.mode = "free"
        local info = appliedFree[nk]
        if info and info.text then
            add("keyboard", kbLabel .. (" (%s)"):format(nk), info.text)
        end
        local hoverInfo = appliedHover[nk]
        if hoverInfo and hoverInfo.text then
            add("hover", ufLabel .. (" (%s)"):format(nk), hoverInfo.text)
        end
    end

    if route and route.kind == "slot" then
        local hoverInfo = appliedHover[nk]
        local hasHover = false
        for _, e in ipairs(out.texts) do
            if e.kind == "hover" then hasHover = true break end
        end
        if not hasHover and hoverInfo and hoverInfo.text then
            add("hover", ufLabel, hoverInfo.text)
        end
    end

    return out
end

--- Debug/status snapshot.
function FluxBinding.Debug()
    local info = FluxBinding.GetActiveWorkInfo and FluxBinding.GetActiveWorkInfo() or {}
    print("|cff00ffff[FluxBinding]|r applied:",
        "slots=" .. lastApplyStats.slots,
        "badgeSlots=" .. lastApplyStats.badges,
        "freeChords=" .. lastApplyStats.free)
    print("  activeWork=" .. tostring(info.active),
        "appliedLive=" .. tostring(info.appliedLive),
        "dbBindings=" .. tostring(info.bindingCount or 0))
    local n = 0
    for _ in pairs(DB.All()) do n = n + 1 end
    print("  bindings:", n)
    local SlotProgram = ns.FluxSlotProgram
    local BadgeHost = ns.FluxBadgeHost or _G.FluxBadgeHost
    if SlotProgram and SlotProgram.GetAll then
        local progSlots = {}
        for slot in pairs(SlotProgram.GetAll()) do
            progSlots[#progSlots + 1] = tostring(slot)
        end
        table.sort(progSlots)
        print("  programSlots=" .. ((#progSlots > 0) and table.concat(progSlots, ",") or "none"))
    end
    for uid, b in pairs(DB.All()) do
        local nk = b.key and ChordMap and ChordMap.Normalize and ChordMap.Normalize(b.key) or ""
        local bySlot, route = nil, nil
        if nk ~= "" and ChordMap and ChordMap.SlotsForChord then
            bySlot, route = ChordMap.SlotsForChord(nk)
        end
        local routeKind = route and route.kind or "none"
        local nativeKind = "n/a"
        local kb, hover, badge = false, false, false
        if type(bySlot) == "table" then
            for slot in pairs(bySlot) do
                local native = SlotNative(slot)
                nativeKind = native.unread and "unread" or (native.kind or "?")
                if native.id then
                    nativeKind = nativeKind .. "#" .. tostring(native.id)
                end
                nativeKind = nativeKind .. "@" .. tostring(slot)
                if SlotProgram and SlotProgram.Get and SlotProgram.Get(slot) then
                    kb = true
                end
                if SlotProgram and SlotProgram.GetHover and SlotProgram.GetHover(slot) then
                    hover = true
                end
                local list = BadgeHost and BadgeHost.GetSlotBadges and BadgeHost.GetSlotBadges(slot)
                if type(list) == "table" and #list > 0 then
                    badge = true
                end
            end
        end
        if nk ~= "" and appliedHover[nk] then
            hover = true
        end
        if nk ~= "" and appliedFree[nk] and appliedFree[nk].text then
            kb = true
        end
        local spellId = b.action and b.action.id
        print(string.format(
            "  uid=%s key=%s route=%s native=%s spell=%s keyboard=%s hover=%s badge=%s avail=%s",
            tostring(uid), tostring(b.key), routeKind, nativeKind, tostring(spellId),
            tostring(kb), tostring(hover), tostring(badge),
            tostring(Action.IsAvailable(b.action))))
    end
end
