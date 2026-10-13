-- Binding/Core/DB.lua
-- FluxBindingDB3: the single source of truth for the rewritten Binding module.
-- Fresh schema (no migration from the legacy dual DB); per character.
--
-- Layout:
--   FluxBindingDB3 = {
--     version = 3,
--     nextUid = <n>,
--     bindings = {
--       [uid] = {
--         uid      = <n>,
--         action   = { type = "spell"|"item"|"macro", id = <n>|nil, name = <s> },
--         key      = "SHIFT-1" | nil,        -- one chord per binding instance
--         placeId  = "ab:45" | "stance:2" | "extra:…" | nil,  -- list-row placement
--         fallback = "ACTION_BAR"|"BINDING", -- key-split "cast last"
--         forms    = { [formToken] = <sub profile> },  -- see NewFormSubProfile
--       },
--     },
--     chordStackOrder  = { [normChord] = { uid, ... } },  -- merged-macro order
--     badgeCornerOrder = { [normChord] = { uid, ... } },  -- badge stack order
--     formPageEnabled  = { [formToken] = false },         -- default enabled
--     rankSyncNames    = { [lowerSpellName] = true },     -- Classic: share profile across ranks
--   }
--
--         stickyRespec=true survives Respec Load/Apply (merged back after snapshot).
--         placeId   = "ab:45"|… optional Clicked-style placement link
-- DB.SetDocumentOverride(doc) temporarily redirects Ensure()/All() for Respec preview.
--
-- Sub-profile field vocabulary intentionally matches the old editor panels
-- (action / targets / load / macro / badge) so the ported UI reads naturally.

local addonName, ns = ...

local DB = {}
ns.FluxBindingDB3 = DB
_G.FluxBindingDB3API = DB

DB.VERSION = 3
DB.DEFAULT_BADGE_ALPHA = 0.75
--- Soft cap for stored multi-cast extras (settings). Badges still max BadgeHost.MAX_BADGES.
DB.MAX_MACRO_EXTRAS = 20
DB.MAX_MACRO_EXTRA_BADGES = 3

local store -- -> _G.FluxBindingDB3 after Ensure()
local overrideDoc -- temporary document for Respec profile preview (not live SV)

-- ---------------------------------------------------------------------------
-- Templates
-- ---------------------------------------------------------------------------

local function NewLoadOption(value)
    return { selected = false, value = value, negated = false }
end
DB.NewLoadOption = NewLoadOption

function DB.NewFormSubProfile()
    return {
        active = true,
        action = {
            interrupt           = false,
            startAutoAttack     = false,
            startPetAttack      = false,
            stopSpellTarget     = false,
            cancelQueuedSpell   = false,
            cancelForm          = false,
            cancelAura          = false,
            cancelAuraName      = "",
            targetUnitAfterCast = false,
            preventToggle       = false,
            spellIncludeSubtext = false,
            castAtCursor        = false,
        },
        targets = {
            hovercastEnabled = true,  -- V10/Clicked default: unit-frame hover on
            regularEnabled   = true,
            hovercast = { hostility = "ANY", vitals = "ANY" },
            regular  = {
                { unit = "DEFAULT", hostility = "ANY", vitals = "ANY" },
            },
        },
        load = {
            never        = false,
            combat       = NewLoadOption(true),   -- macro conditional
            stealth      = NewLoadOption(true),   -- macro conditional
            mounted      = NewLoadOption(true),   -- macro conditional
            pet          = NewLoadOption(true),   -- macro conditional
            outdoors     = NewLoadOption(true),   -- macro conditional
            swimming     = NewLoadOption(true),   -- macro conditional
            flying       = NewLoadOption(true),   -- macro conditional
            channeling   = NewLoadOption(true),   -- macro conditional
            -- Gated modifier conditions (shared action-bar key only; see Conditions.CanOffer*)
            modAlt       = { selected = false },
            modShiftCtrl = { selected = false },
            equipped     = { selected = false, value = "" },       -- load gate
            instanceType = NewLoadOption("NONE"),                  -- load gate
            zoneName     = { selected = false, value = "" },       -- load gate
            specialization = NewLoadOption(1),                     -- load gate
        },
        macro = {
            prefix = "",
            extras = {}, -- multi-cast extras: spell/item/slot (soft-capped; badges use first 3 available)
            -- Position of the bar/main action in the cast sequence (1 .. #extras+1).
            -- 1 = main first (extras after); #extras+1 = main last (extras before).
            mainCastIndex = 1,
        },
        badge = {
            alpha = DB.DEFAULT_BADGE_ALPHA,
            hiddenSwap = false,
            hiddenAlways = false,
            hiddenUnlessCd = false,
            hiddenMinirow = false,
            -- Cooldown countdown digits on this binding's corner badge(s).
            cdNumber = true,          -- show numbers (default on)
            cdNumberScale = 1.0,      -- 0..1 → 0%..100% of max digit size (default 100%)
            cdNumberMainrow = true,   -- show on main action-bar row
            cdNumberMinirow = true,   -- show on SHIFT/CTRL mini rows
        },
    }
end

function DB.NewBinding(actionDesc, opts)
    opts = type(opts) == "table" and opts or {}
    local forms = { noform = DB.NewFormSubProfile() }
    -- Pet abilities default to [pet] so macros only fire with a pet out.
    if type(actionDesc) == "table" and actionDesc.pet and forms.noform and forms.noform.load then
        local petOpt = forms.noform.load.pet
        if type(petOpt) == "table" then
            petOpt.selected = true
            petOpt.value = true
            petOpt.negated = false
        end
    end
    return {
        uid = nil, -- assigned by Add
        action = actionDesc,
        key = nil,
        fallback = "ACTION_BAR",
        stickyRespec = false, -- survive Respec Load/Apply
        placeId = opts.placeId, -- optional: ab:45 / stance:2 / extra:…
        forms = forms,
    }
end

-- ---------------------------------------------------------------------------
-- Store access
-- ---------------------------------------------------------------------------

local function NormalizeDoc(doc)
    if type(doc) ~= "table" then doc = {} end
    doc.version = DB.VERSION
    doc.nextUid = tonumber(doc.nextUid) or 1
    doc.bindings = type(doc.bindings) == "table" and doc.bindings or {}
    doc.chordStackOrder = type(doc.chordStackOrder) == "table" and doc.chordStackOrder or {}
    doc.badgeCornerOrder = type(doc.badgeCornerOrder) == "table" and doc.badgeCornerOrder or {}
    doc.formPageEnabled = type(doc.formPageEnabled) == "table" and doc.formPageEnabled or {}
    doc.rankSyncNames = type(doc.rankSyncNames) == "table" and doc.rankSyncNames or {}
    return doc
end

--- Redirect Ensure()/mutations to a working document (Respec preview). nil = live SV.
function DB.SetDocumentOverride(doc)
    if doc == nil then
        overrideDoc = nil
        return nil
    end
    overrideDoc = NormalizeDoc(doc)
    return overrideDoc
end

function DB.GetDocumentOverride()
    return overrideDoc
end

function DB.IsOverrideActive()
    return overrideDoc ~= nil
end

function DB.Ensure()
    if overrideDoc then
        return overrideDoc
    end
    if store then return store end
    if type(_G.FluxBindingDB3) ~= "table" then
        _G.FluxBindingDB3 = {}
    end
    store = NormalizeDoc(_G.FluxBindingDB3)
    _G.FluxBindingDB3 = store
    return store
end

--- Live SavedVariables document (ignores preview override).
function DB.EnsureLive()
    if type(_G.FluxBindingDB3) ~= "table" then
        _G.FluxBindingDB3 = {}
    end
    if not store or store ~= _G.FluxBindingDB3 then
        store = NormalizeDoc(_G.FluxBindingDB3)
        _G.FluxBindingDB3 = store
    else
        NormalizeDoc(store)
    end
    return store
end

function DB.IsReady()
    return store ~= nil or overrideDoc ~= nil
end

function DB.Get(uid)
    local s = DB.Ensure()
    return s.bindings[tonumber(uid) or uid]
end

function DB.All()
    return DB.Ensure().bindings
end

--- Ordered, deterministic iteration (uid ascending).
function DB.SortedUids()
    local s = DB.Ensure()
    local out = {}
    for uid in pairs(s.bindings) do
        out[#out + 1] = uid
    end
    table.sort(out)
    return out
end

function DB.Add(actionDesc, opts)
    local s = DB.Ensure()
    opts = type(opts) == "table" and opts or {}
    local b = DB.NewBinding(actionDesc, opts)
    b.uid = s.nextUid
    s.nextUid = s.nextUid + 1
    if opts.placeId then
        b.placeId = opts.placeId
    end
    s.bindings[b.uid] = b
    return b
end

function DB.Remove(uid)
    local s = DB.Ensure()
    uid = tonumber(uid) or uid
    local b = s.bindings[uid]
    s.bindings[uid] = nil
    -- scrub order lists
    for _, orderMap in ipairs({ s.chordStackOrder, s.badgeCornerOrder }) do
        for chord, list in pairs(orderMap) do
            for i = #list, 1, -1 do
                if list[i] == uid then
                    table.remove(list, i)
                end
            end
            if #list == 0 then
                orderMap[chord] = nil
            end
        end
    end
    return b
end

--- Ensure a form sub-profile exists (fills missing fields on old entries too).
function DB.EnsureFormSub(binding, formToken)
    formToken = formToken or "noform"
    if type(binding.forms) ~= "table" then
        binding.forms = {}
    end
    local sub = binding.forms[formToken]
    if type(sub) ~= "table" then
        sub = DB.NewFormSubProfile()
        binding.forms[formToken] = sub
        return sub
    end
    -- backfill any missing sections/fields from the template
    local tpl = DB.NewFormSubProfile()
    for section, fields in pairs(tpl) do
        if type(fields) == "table" then
            if type(sub[section]) ~= "table" then
                sub[section] = fields
            else
                for k, v in pairs(fields) do
                    if sub[section][k] == nil then
                        sub[section][k] = v
                    end
                end
            end
        elseif sub[section] == nil then
            sub[section] = fields
        end
    end
    if type(sub.macro) == "table" then
        sub.macro.extras = DB.NormalizeMacroExtras(sub.macro.extras)
        sub.macro.mainCastIndex = DB.ClampMainCastIndex(sub.macro.mainCastIndex, #sub.macro.extras)
    end
    return sub
end

--- Normalize multi-cast extras list (spell | item | slot). Soft-capped for storage.
function DB.NormalizeMacroExtras(list)
    local out = {}
    if type(list) ~= "table" then return out end
    local maxN = DB.MAX_MACRO_EXTRAS or 20
    for i = 1, #list do
        if #out >= maxN then break end
        local e = list[i]
        if type(e) == "table" then
            local t = e.type
            local id = tonumber(e.id)
            if (t == "spell" or t == "item") and id and id > 0 then
                out[#out + 1] = { type = t, id = id, name = e.name }
            elseif t == "slot" and id and id >= 1 and id <= 19 then
                out[#out + 1] = { type = "slot", id = id }
            end
        end
    end
    return out
end

--- True when an extra should fire / show a badge right now.
--- Items with count 0 and empty equip slots are skipped (next entry used).
function DB.IsMacroExtraAvailable(e)
    if type(e) ~= "table" or not e.type then return false end
    if e.type == "spell" then
        return e.id and e.id > 0
    elseif e.type == "item" then
        if not e.id or e.id <= 0 then return false end
        local Action = ns.FluxBindingAction
        local n = 0
        if Action and Action.GetCount then
            n = tonumber(Action.GetCount(Action.Item(e.id))) or 0
        elseif C_Item and C_Item.GetItemCount then
            n = C_Item.GetItemCount(e.id, false, true) or 0
        elseif GetItemCount then
            n = GetItemCount(e.id, false, true) or 0
        end
        return n > 0
    elseif e.type == "slot" then
        if not e.id then return false end
        if GetInventoryItemID then
            return GetInventoryItemID("player", e.id) ~= nil
        end
        return GetInventoryItemTexture and GetInventoryItemTexture("player", e.id) ~= nil
    end
    return false
end

--- Available extras in list order. maxN nil = all available; else first maxN.
--- Each entry keeps `_index` = 1-based index in the normalized full list.
function DB.FilterMacroExtras(list, maxN)
    local src = DB.NormalizeMacroExtras(list)
    local out = {}
    for i = 1, #src do
        if DB.IsMacroExtraAvailable(src[i]) then
            local copy = {
                type = src[i].type,
                id = src[i].id,
                name = src[i].name,
                _index = i,
            }
            out[#out + 1] = copy
            if maxN and #out >= maxN then break end
        end
    end
    return out
end

function DB.GetMacroExtras(sub)
    if type(sub) ~= "table" or type(sub.macro) ~= "table" then return {} end
    return DB.NormalizeMacroExtras(sub.macro.extras)
end

--- Clamp main cast index into 1 .. (#extras + 1). Missing/invalid → 1.
function DB.ClampMainCastIndex(index, extrasCount)
    local n = tonumber(extrasCount) or 0
    if n < 0 then n = 0 end
    local maxI = n + 1
    local i = tonumber(index)
    if not i or i < 1 then
        return 1
    end
    if i > maxI then
        return maxI
    end
    return math.floor(i)
end

function DB.GetMainCastIndex(sub)
    local extras = DB.GetMacroExtras(sub)
    if type(sub) ~= "table" or type(sub.macro) ~= "table" then
        return 1
    end
    return DB.ClampMainCastIndex(sub.macro.mainCastIndex, #extras)
end

function DB.SetMainCastIndex(sub, index)
    if type(sub) ~= "table" then return 1 end
    sub.macro = type(sub.macro) == "table" and sub.macro or { prefix = "", extras = {} }
    local extras = DB.NormalizeMacroExtras(sub.macro.extras)
    sub.macro.extras = extras
    local clamped = DB.ClampMainCastIndex(index, #extras)
    sub.macro.mainCastIndex = clamped
    return clamped
end

function DB.SetMacroExtras(sub, list)
    if type(sub) ~= "table" then return end
    sub.macro = type(sub.macro) == "table" and sub.macro or { prefix = "" }
    sub.macro.extras = DB.NormalizeMacroExtras(list)
    sub.macro.mainCastIndex = DB.ClampMainCastIndex(sub.macro.mainCastIndex, #sub.macro.extras)
    return sub.macro.extras
end

--- Split extras into lists cast before / after the main bar action.
--- Index is in the full (unfiltered) extras list: before = [1..mainIdx-1], after = [mainIdx..n].
function DB.SplitMacroExtrasAroundMain(sub)
    local extras = DB.GetMacroExtras(sub)
    local mainIdx = DB.GetMainCastIndex(sub)
    local before, after = {}, {}
    for i = 1, #extras do
        if i < mainIdx then
            before[#before + 1] = extras[i]
        else
            after[#after + 1] = extras[i]
        end
    end
    return before, after
end

--- UI rows for cast-order strip: main + extras interleaved by mainCastIndex.
--- Each row: { kind="main"|"extra", extraIndex?, e?, action? }
function DB.BuildMultiCastOrderRows(binding, sub)
    local extras = DB.GetMacroExtras(sub)
    local mainIdx = DB.GetMainCastIndex(sub)
    local action = binding and binding.action or nil
    local rows = {}
    local extraI = 1
    local seqLen = #extras + 1
    for seq = 1, seqLen do
        if seq == mainIdx then
            rows[#rows + 1] = { kind = "main", action = action }
        else
            local e = extras[extraI]
            rows[#rows + 1] = {
                kind = "extra",
                extraIndex = extraI,
                e = e,
            }
            extraI = extraI + 1
        end
    end
    return rows
end

--- Persist cast-order rows back to extras + mainCastIndex.
function DB.ApplyMultiCastOrderRows(sub, rows)
    if type(sub) ~= "table" or type(rows) ~= "table" then return end
    local extras = {}
    local mainIdx = 1
    local foundMain = false
    for i = 1, #rows do
        local r = rows[i]
        if type(r) == "table" and r.kind == "main" then
            mainIdx = i
            foundMain = true
        elseif type(r) == "table" and r.kind == "extra" and type(r.e) == "table" then
            extras[#extras + 1] = r.e
        end
    end
    if not foundMain then
        mainIdx = 1
    end
    DB.SetMacroExtras(sub, extras)
    DB.SetMainCastIndex(sub, mainIdx)
end

--- Icon texture for an extra (spell / item / equipped slot).
function DB.GetMacroExtraIcon(e)
    if type(e) ~= "table" then return 134400 end
    local Action = ns.FluxBindingAction
    if e.type == "spell" and e.id then
        if Action and Action.GetIcon then
            return Action.GetIcon(Action.Spell(e.id, e.name)) or 134400
        end
        if C_Spell and C_Spell.GetSpellTexture then
            return C_Spell.GetSpellTexture(e.id) or 134400
        end
    elseif e.type == "item" and e.id then
        if Action and Action.GetIcon then
            return Action.GetIcon(Action.Item(e.id, e.name)) or 134400
        end
        if C_Item and C_Item.GetItemIconByID then
            return C_Item.GetItemIconByID(e.id) or 134400
        elseif GetItemIcon then
            return GetItemIcon(e.id) or 134400
        end
    elseif e.type == "slot" and e.id then
        local tex = GetInventoryItemTexture and GetInventoryItemTexture("player", e.id)
        if tex then return tex end
        local iid = GetInventoryItemID and GetInventoryItemID("player", e.id)
        if iid and GetItemIcon then
            return GetItemIcon(iid) or 134400
        end
    end
    return 134400
end

--- Display name for a multi-cast extra (spell / item / equip slot).
function DB.GetMacroExtraLabel(e)
    if type(e) ~= "table" then return "?" end
    local Action = ns.FluxBindingAction
    local L = _G.FluxSpellBindingLocale or {}
    if e.type == "spell" then
        if Action and Action.GetName then
            return Action.GetName(Action.Spell(e.id, e.name)) or ("Spell " .. tostring(e.id))
        end
        return e.name or ("Spell " .. tostring(e.id))
    elseif e.type == "item" then
        local n = e.name
        if Action and Action.GetName then
            n = Action.GetName(Action.Item(e.id, e.name)) or n
        end
        n = n or ("Item " .. tostring(e.id))
        if Action and Action.GetCount then
            local c = Action.GetCount(Action.Item(e.id))
            if c ~= nil then return n .. " ×" .. c end
        end
        return n
    elseif e.type == "slot" then
        -- Prefer Flux numbered labels (Trinket 1/2, Finger 1/2) over Blizzard globals.
        local name = L["multicast_slot_" .. tostring(e.id)]
        if type(name) ~= "string" or name == "" then
            local loc = ({
                [1] = _G.HEADSLOT, [2] = _G.NECKSLOT, [3] = _G.SHOULDERSLOT, [4] = _G.SHIRTSLOT,
                [5] = _G.CHESTSLOT, [6] = _G.WAISTSLOT, [7] = _G.LEGSSLOT, [8] = _G.FEETSLOT,
                [9] = _G.WRISTSLOT, [10] = _G.HANDSSLOT, [11] = _G.FINGER0SLOT, [12] = _G.FINGER1SLOT,
                [13] = _G.TRINKET0SLOT, [14] = _G.TRINKET1SLOT, [15] = _G.BACKSLOT,
                [16] = _G.MAINHANDSLOT, [17] = _G.SECONDARYHANDSLOT, [18] = _G.RANGEDSLOT,
                [19] = _G.TABARDSLOT,
            })[e.id]
            if type(loc) == "string" and loc ~= "" then
                name = loc
            else
                name = (L["multicast_slot_fmt"] or "Equip slot %d"):format(e.id or 0)
            end
        end
        return ("%s (#%d)"):format(name, e.id or 0)
    end
    return "?"
end

--- True when extra `e` refers to the same spell/item/equip slot.
function DB.MacroExtraMatchesAction(e, actionDesc)
    if type(e) ~= "table" or type(actionDesc) ~= "table" then return false end
    local Action = ns.FluxBindingAction
    if e.type == "spell" and actionDesc.type == "spell" and e.id and actionDesc.id then
        if e.id == actionDesc.id then return true end
        if Action and Action.KeysMatch then
            return Action.KeysMatch(Action.Spell(e.id, e.name), Action.Key(actionDesc)) == true
        end
        return false
    end
    if e.type == "item" and actionDesc.type == "item" and e.id and actionDesc.id then
        return e.id == actionDesc.id
    end
    if e.type == "slot" and actionDesc.type == "slot" and e.id and actionDesc.id then
        return tonumber(e.id) == tonumber(actionDesc.id)
    end
    -- Legacy: slot extras used to surface as the equipped item in the list.
    if e.type == "slot" and e.id and actionDesc.type == "item" and actionDesc.id then
        local iid = GetInventoryItemID and GetInventoryItemID("player", e.id)
        return iid ~= nil and iid == actionDesc.id
    end
    return false
end

--- Action desc for opening the editor on an extra (equip slots keep slot identity).
function DB.MacroExtraToAction(e)
    if type(e) ~= "table" then return nil end
    local Action = ns.FluxBindingAction
    if e.type == "spell" and e.id then
        return Action and Action.Spell and Action.Spell(e.id, e.name)
            or { type = "spell", id = e.id, name = e.name }
    end
    if e.type == "item" and e.id then
        return Action and Action.Item and Action.Item(e.id, e.name)
            or { type = "item", id = e.id, name = e.name }
    end
    if e.type == "slot" and e.id then
        return Action and Action.EquipSlot and Action.EquipSlot(e.id)
            or { type = "slot", id = e.id }
    end
    return nil
end

--- Default Bar & Badges opts (never inherit from a multi-cast host).
function DB.DefaultBadgeOpts()
    return {
        alpha = DB.DEFAULT_BADGE_ALPHA,
        hiddenSwap = false,
        hiddenAlways = false,
        hiddenUnlessCd = false,
        hiddenMinirow = false,
        cdNumber = true,
        cdNumberScale = 1.0,
        cdNumberMainrow = true,
        cdNumberMinirow = true,
    }
end

--- Binding row that owns Bar & Badges for this multi-cast extra (spell/item/slot).
--- Prefers an mcast: place tied to hostUid, then any matching action. Nil if none.
function DB.FindBindingForMacroExtra(e, hostUid)
    if type(e) ~= "table" then return nil end
    local Action = ns.FluxBindingAction
    local action = DB.MacroExtraToAction(e)
    if type(action) ~= "table" then return nil end

    local wantPrefix = nil
    if hostUid then
        wantPrefix = ("mcast:%s:"):format(tostring(hostUid))
    end

    local function BadgeNonDefault(b)
        local sub = b.forms and (b.forms.noform or select(2, next(b.forms)))
        local badge = sub and sub.badge
        if type(badge) ~= "table" then return false end
        local alpha = tonumber(badge.alpha)
        local def = DB.DEFAULT_BADGE_ALPHA or 0.75
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
        return false
    end

    local best, bestScore = nil, -1
    for uid, b in pairs(DB.All()) do
        if b and type(b.action) == "table" then
            local match = DB.MacroExtraMatchesAction(e, b.action)
            if not match and Action and Action.KeysMatch and Action.Key then
                local ak = (Action.FamilyKey and Action.FamilyKey(action)) or Action.Key(action)
                match = ak and Action.KeysMatch(b.action, ak) == true
            end
            if match then
                local score = 1
                local pid = b.placeId and tostring(b.placeId) or ""
                if wantPrefix and pid:sub(1, #wantPrefix) == wantPrefix then
                    score = 5
                elseif pid:sub(1, 6) == "mcast:" then
                    score = 4
                elseif BadgeNonDefault(b) then
                    score = 3
                elseif b.key and b.key ~= "" then
                    score = 2
                end
                if score > bestScore then
                    best, bestScore = b, score
                end
            end
        end
    end
    return best
end

--- Bar & Badges for a multi-cast extra: that extra's own binding, else defaults.
--- Never uses the host spell's badge settings.
function DB.GetBadgeOptsForMacroExtra(e, formToken, hostUid)
    local b = DB.FindBindingForMacroExtra(e, hostUid)
    if b and type(b.forms) == "table" then
        local sub = DB.GetFormSub and DB.GetFormSub(b, formToken or "noform")
        if not sub and b.forms.noform then
            sub = b.forms.noform
        end
        if sub and type(sub.badge) == "table" then
            return sub.badge, b.uid
        end
    end
    return DB.DefaultBadgeOpts(), nil
end

--- Bindings whose multi-cast extras include this action (any form sub).
--- Returns { { uid, action, name, icon, placeId }, ... }
function DB.FindBindingsUsingMacroExtra(actionDesc, skipUid)
    local out = {}
    if type(actionDesc) ~= "table" then return out end
    local Action = ns.FluxBindingAction
    for uid, b in pairs(DB.All()) do
        if b and uid ~= skipUid and type(b.forms) == "table" then
            local hit = false
            for _, sub in pairs(b.forms) do
                local list = DB.GetMacroExtras(sub)
                for i = 1, #list do
                    if DB.MacroExtraMatchesAction(list[i], actionDesc) then
                        hit = true
                        break
                    end
                end
                if hit then break end
            end
            if hit then
                out[#out + 1] = {
                    uid = uid,
                    action = b.action,
                    name = (Action and Action.GetName and Action.GetName(b.action)) or "?",
                    icon = (Action and Action.GetIcon and Action.GetIcon(b.action)) or 134400,
                    placeId = b.placeId,
                    key = b.key,
                }
            end
        end
    end
    table.sort(out, function(a, b)
        return tostring(a.name) < tostring(b.name)
    end)
    return out
end

--- Extras on a binding for the given form (falls back to noform).
--- Returns display rows: { type, id, name, icon, available, action, isExtra=true }
function DB.GetMacroExtrasDisplay(binding, formToken)
    local out = {}
    if not binding then return out end
    local sub = DB.GetFormSub(binding, formToken or "noform")
    local list = DB.GetMacroExtras(sub)
    for i = 1, #list do
        local e = list[i]
        out[#out + 1] = {
            type = e.type,
            id = e.id,
            name = DB.GetMacroExtraLabel(e),
            icon = DB.GetMacroExtraIcon(e),
            available = DB.IsMacroExtraAvailable(e),
            action = DB.MacroExtraToAction(e),
            isExtra = true,
            index = i,
        }
    end
    return out
end

--- Sub-profile for reading; falls back to the noform profile when the token
--- has no dedicated entry (per-form data is created on demand by the editor).
function DB.GetFormSub(binding, formToken)
    if type(binding.forms) ~= "table" then return nil end
    return binding.forms[formToken or "noform"] or binding.forms.noform
end

function DB.HasDedicatedFormSub(binding, formToken)
    return type(binding.forms) == "table" and binding.forms[formToken] ~= nil
end

--- V10: custom binding applies for this form?
--- - Single-form characters: noform sub with active ~= false
--- - Multi-form: noform uses forms.noform; other tokens need a dedicated
---   sub with active ~= false (do NOT inherit noform Active into cat/bear)
function DB.IsCustomActiveForForm(binding, formToken)
    if not binding or type(binding.forms) ~= "table" then return false end
    formToken = formToken or "noform"
    local Forms = ns.FluxBindingForms
    local multi = Forms and Forms.HasMultipleForms and Forms.HasMultipleForms()
    if not multi or formToken == "noform" then
        local sub = binding.forms.noform
        return sub ~= nil and sub.active ~= false
    end
    local sub = binding.forms[formToken]
    return sub ~= nil and sub.active ~= false
end

--- Deep-copy a form sub-profile (for Copy from / EnsureEditableSub).
function DB.DeepCopyFormSub(src)
    if type(src) ~= "table" then return DB.NewFormSubProfile() end
    local function deep(t)
        if type(t) ~= "table" then return t end
        local n = {}
        for k, v in pairs(t) do n[k] = deep(v) end
        return n
    end
    return deep(src)
end

--- Copy source form sub into dest token; preserves dest Active flag.
function DB.CopyFormSub(binding, fromToken, toToken)
    if not binding then return nil end
    fromToken = fromToken or "noform"
    toToken = toToken or "noform"
    local src = binding.forms and (binding.forms[fromToken] or binding.forms.noform)
    if not src then return nil end
    local prevActive
    if binding.forms and binding.forms[toToken] then
        prevActive = binding.forms[toToken].active
    end
    local copy = DB.DeepCopyFormSub(src)
    if prevActive ~= nil then
        copy.active = prevActive
    else
        copy.active = true
    end
    if type(binding.forms) ~= "table" then binding.forms = {} end
    binding.forms[toToken] = copy
    return copy
end

-- ---------------------------------------------------------------------------
-- Chord order lists
-- ---------------------------------------------------------------------------

local function EnsureOrderList(map, chord)
    local list = map[chord]
    if not list then
        list = {}
        map[chord] = list
    end
    return list
end

--- Stable stack order for a chord: stored order first, unknown uids appended
--- ascending. Also prunes stale uids.
local function OrderedUidsForChord(map, chord, uidSet)
    local list = EnsureOrderList(map, chord)
    -- prune
    for i = #list, 1, -1 do
        if not uidSet[list[i]] then
            table.remove(list, i)
        end
    end
    -- append new
    local present = {}
    for i = 1, #list do present[list[i]] = true end
    local missing = {}
    for uid in pairs(uidSet) do
        if not present[uid] then
            missing[#missing + 1] = uid
        end
    end
    table.sort(missing)
    for i = 1, #missing do
        list[#list + 1] = missing[i]
    end
    return list
end

function DB.GetChordStackOrder(chord, uidSet)
    return OrderedUidsForChord(DB.Ensure().chordStackOrder, chord, uidSet)
end

function DB.GetBadgeCornerOrder(chord, uidSet)
    return OrderedUidsForChord(DB.Ensure().badgeCornerOrder, chord, uidSet)
end

function DB.SetChordStackOrder(chord, list)
    DB.Ensure().chordStackOrder[chord] = list
end

function DB.SetBadgeCornerOrder(chord, list)
    DB.Ensure().badgeCornerOrder[chord] = list
end

-- ---------------------------------------------------------------------------
-- Form page enable
-- ---------------------------------------------------------------------------

function DB.IsFormPageEnabled(formToken)
    local s = DB.Ensure()
    return s.formPageEnabled[formToken or "noform"] ~= false
end

function DB.SetFormPageEnabled(formToken, enabled)
    local s = DB.Ensure()
    local key = formToken or "noform"
    -- nil = default on (absent). Do NOT use `enabled and nil or false` — in Lua
    -- that always evaluates to false.
    if enabled then
        s.formPageEnabled[key] = nil
    else
        s.formPageEnabled[key] = false
    end
end

-- ---------------------------------------------------------------------------
-- Queries
-- ---------------------------------------------------------------------------

--- All binding uids for a given action key (see Action.Key / FamilyKey).
--- Matches per-rank ids and rank-synced name keys interchangeably.
function DB.UidsForActionKey(actionKey)
    local out = {}
    local Action = ns.FluxBindingAction
    if not actionKey or not Action then return out end
    for uid, b in pairs(DB.All()) do
        if Action.KeysMatch and Action.KeysMatch(b.action, actionKey) then
            out[#out + 1] = uid
        elseif Action.Key(b.action) == actionKey then
            out[#out + 1] = uid
        end
    end
    table.sort(out)
    return out
end

--- Find a binding UID for an action placement (Clicked-style per-place instance).
--- Prefer exact placeId. Chord match only when placeId is nil/empty (not as a
--- fallback that would steal another bar slot's row for the same spell).
function DB.FindUidForPlace(actionKey, placeId, preferChord)
    if not actionKey then return nil end
    local uids = DB.UidsForActionKey(actionKey)
    if #uids == 0 then return nil end

    if placeId and placeId ~= "" then
        for i = 1, #uids do
            local b = DB.Get(uids[i])
            if b and b.placeId == placeId then
                return uids[i]
            end
        end
        -- Exact place miss: do not fall through to chord (C vs Z must stay distinct).
        return nil
    end

    if preferChord and preferChord ~= "" then
        local CM = ns.FluxChordMap or _G.FluxChordMap
        local want = preferChord
        if CM and CM.Normalize then
            want = CM.Normalize(preferChord) or preferChord
        end
        for i = 1, #uids do
            local b = DB.Get(uids[i])
            if b and b.key and b.key ~= "" then
                local have = b.key
                if CM and CM.Normalize then
                    have = CM.Normalize(b.key) or b.key
                end
                if have == want then
                    return uids[i]
                end
            end
        end
    end
    return nil
end

--- First same-action binding with no placeId (legacy shared row) — claimable for a place.
function DB.FindUnplacedUidForActionKey(actionKey)
    if not actionKey then return nil end
    local uids = DB.UidsForActionKey(actionKey)
    for i = 1, #uids do
        local b = DB.Get(uids[i])
        if b and (not b.placeId or b.placeId == "") then
            return uids[i]
        end
    end
    return nil
end

--- Rank-sync map: lowercased spell name → true.
function DB.GetRankSyncNames()
    return DB.Ensure().rankSyncNames
end

function DB.IsRankSyncName(nameKey)
    if type(nameKey) ~= "string" or nameKey == "" then return false end
    return DB.Ensure().rankSyncNames[nameKey] == true
end

function DB.SetRankSyncName(nameKey, enabled)
    if type(nameKey) ~= "string" or nameKey == "" then return end
    local map = DB.Ensure().rankSyncNames
    if enabled then
        map[nameKey] = true
    else
        map[nameKey] = nil
    end
end
