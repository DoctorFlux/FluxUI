-- Binding/Aux/Respec.lua
-- FluxSpellBindings_* snapshot API for the Respec module, over FluxBindingDB3.
-- Snapshots store customized bindings only: Flux keys AND/OR non-default
-- spell/item settings (targets, load, action flags, badge, forms, fallback)
-- — including unbound action-bar spells that ride bar keys implicitly.
-- Contract (matches Respec Apply step + Docs/Binding.md):
--   ApplySnapshot(snap, afterFn) → ok, reason
--   Combat: queues restore, returns false, "IN_COMBAT"; afterFn(true) after regen
--   Success: afterFn(true) after short settle; returns true

local addonName, ns = ...

local DB = ns.FluxBindingDB3

local SNAPSHOT_VERSION = 3

local _pendingSnap = nil
local _pendingDone = nil
local _combatWatcher = nil

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do
        n[k] = DeepCopy(v)
    end
    return n
end

local function DeepEquals(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do
        if not DeepEquals(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local function IsBindingCustomized(binding)
    local FB = _G.FluxBinding
    if FB and FB.IsBindingCustomized then
        return FB.IsBindingCustomized(binding)
    end
    -- Fallback if Apply.lua not loaded yet: key / fallback / any form table.
    if type(binding) ~= "table" then return false end
    if binding.key and binding.key ~= "" then return true end
    if binding.stickyRespec then return true end
    if binding.fallback and binding.fallback ~= "ACTION_BAR" then return true end
    if type(binding.forms) == "table" then
        for token, sub in pairs(binding.forms) do
            if token ~= "noform" then return true end
            if type(sub) == "table" then
                if sub.active == false then return true end
                local badge = sub.badge
                if type(badge) == "table" then
                    local alpha = tonumber(badge.alpha)
                    local def = (DB and DB.DEFAULT_BADGE_ALPHA) or 0.75
                    if alpha and math.abs(alpha - def) > 0.001 then return true end
                    if badge.hiddenSwap or badge.hiddenAlways
                        or badge.hiddenUnlessCd or badge.hiddenMinirow then
                        return true
                    end
                    if badge.cdNumber == false then return true end
                    local cds = tonumber(badge.cdNumberScale)
                    if cds and math.abs(cds - 1.0) > 0.001 then return true end
                    if badge.cdNumberMainrow == false or badge.cdNumberMinirow == false then
                        return true
                    end
                end
                if FB and FB.IsSubNonDefault and FB.IsSubNonDefault(sub) then
                    return true
                end
            end
        end
    end
    return false
end

--- Snapshot the live document. Keep customized / sticky rows only.
--- Pristine unbound defaults are omitted (still appear in Binding via bars/Extra).
local function CompactDoc(doc)
    if type(doc) ~= "table" then
        return {
            bindings = {},
            chordStackOrder = {},
            badgeCornerOrder = {},
            formPageEnabled = {},
            rankSyncNames = {},
        }
    end
    local srcBindings = type(doc.bindings) == "table" and doc.bindings or {}
    local bindings = {}
    local keepUid = {}
    local FB = _G.FluxBinding
    for uid, b in pairs(srcBindings) do
        if type(b) == "table" and type(b.action) == "table" then
            local at = b.action.type
            local keep = (at == "spell" or at == "item" or at == "macro")
            if keep and FB and FB.IsBindingRespecRelevant then
                keep = FB.IsBindingRespecRelevant(b)
            elseif keep then
                keep = IsBindingCustomized(b)
            end
            if keep then
                bindings[uid] = DeepCopy(b)
                keepUid[uid] = true
            end
        end
    end

    local function pruneOrder(map)
        local out = {}
        if type(map) ~= "table" then return out end
        for chord, list in pairs(map) do
            if type(list) == "table" then
                local kept = {}
                for i = 1, #list do
                    local uid = list[i]
                    if keepUid[uid] then
                        kept[#kept + 1] = uid
                    end
                end
                if #kept > 0 then
                    out[chord] = kept
                end
            end
        end
        return out
    end

    local formPageEnabled = {}
    if type(doc.formPageEnabled) == "table" then
        for token, enabled in pairs(doc.formPageEnabled) do
            if enabled == false then
                formPageEnabled[token] = false
            end
        end
    end

    local rankSyncNames = {}
    if type(doc.rankSyncNames) == "table" then
        for nameKey, enabled in pairs(doc.rankSyncNames) do
            if enabled then
                rankSyncNames[nameKey] = true
            end
        end
    end

    return {
        bindings = bindings,
        chordStackOrder = pruneOrder(doc.chordStackOrder),
        badgeCornerOrder = pruneOrder(doc.badgeCornerOrder),
        formPageEnabled = formPageEnabled,
        rankSyncNames = rankSyncNames,
    }
end

local function CurrentDoc()
    -- Always the live SavedVariables document (ignore Binding-tab preview override).
    local s = (DB.EnsureLive and DB.EnsureLive()) or DB.Ensure()
    return {
        bindings = s.bindings,
        chordStackOrder = s.chordStackOrder,
        badgeCornerOrder = s.badgeCornerOrder,
        formPageEnabled = s.formPageEnabled,
        rankSyncNames = s.rankSyncNames,
    }
end

local function DocFromTable(s)
    if type(s) ~= "table" then return CurrentDoc() end
    return {
        bindings = s.bindings,
        chordStackOrder = s.chordStackOrder,
        badgeCornerOrder = s.badgeCornerOrder,
        formPageEnabled = s.formPageEnabled,
        rankSyncNames = s.rankSyncNames,
    }
end

--- Snapshot an arbitrary doc table (Binding browser Respec preview persistence).
function _G.FluxSpellBindings_CaptureDocSnapshot(doc)
    return {
        version = SNAPSHOT_VERSION,
        doc = CompactDoc(DocFromTable(doc)),
    }
end

local function InvokeAfter(afterFn, ok, reason)
    if type(afterFn) ~= "function" then return end
    if ok then
        C_Timer.After(0.05, function()
            pcall(afterFn, true)
        end)
    else
        pcall(afterFn, false, reason)
    end
end

local function BindingIdentityKey(binding)
    if type(binding) ~= "table" or type(binding.action) ~= "table" then return nil end
    local Action = ns.FluxBindingAction
    if Action and Action.FamilyKey then
        return Action.FamilyKey(binding.action) or Action.Key(binding.action)
    end
    local a = binding.action
    if a.type == "spell" and a.id then return "s" .. a.id end
    if a.type == "item" and a.id then return "i" .. a.id end
    if a.type == "macro" and a.name then return "m:" .. a.name end
    return nil
end

--- Pull stickyRespec rows from the live document before a Respec replace.
local function CollectStickyFromLive()
    local live = DB.EnsureLive and DB.EnsureLive() or DB.Ensure()
    local sticky = {}
    local bindings = type(live.bindings) == "table" and live.bindings or {}
    for uid, b in pairs(bindings) do
        if type(b) == "table" and b.stickyRespec then
            local key = BindingIdentityKey(b)
            if key then
                sticky[key] = DeepCopy(b)
            end
        end
    end
    return sticky
end

--- Re-insert sticky bindings after applying a Respec snapshot (same action wins sticky).
local function MergeStickyIntoDoc(doc, sticky)
    if type(doc) ~= "table" or type(sticky) ~= "table" then return end
    doc.bindings = type(doc.bindings) == "table" and doc.bindings or {}
    local byKey = {}
    for uid, b in pairs(doc.bindings) do
        local key = BindingIdentityKey(b)
        if key then
            byKey[key] = uid
        end
    end
    local maxUid = 0
    for uid in pairs(doc.bindings) do
        if type(uid) == "number" and uid > maxUid then maxUid = uid end
    end
    for key, stickyB in pairs(sticky) do
        local copy = DeepCopy(stickyB)
        copy.stickyRespec = true
        local existingUid = byKey[key]
        if existingUid then
            copy.uid = existingUid
            doc.bindings[existingUid] = copy
        else
            maxUid = maxUid + 1
            copy.uid = maxUid
            doc.bindings[maxUid] = copy
            byKey[key] = maxUid
        end
    end
    if (tonumber(doc.nextUid) or 1) <= maxUid then
        doc.nextUid = maxUid + 1
    end
end

local function ApplySnapshotInternal(snap)
    local sticky = CollectStickyFromLive()
    local s = DB.EnsureLive and DB.EnsureLive() or DB.Ensure()
    -- Prepare the whole replacement before touching live SavedVariables.
    local replacement = {
        bindings = DeepCopy(snap.doc.bindings) or {},
        chordStackOrder = DeepCopy(snap.doc.chordStackOrder) or {},
        badgeCornerOrder = DeepCopy(snap.doc.badgeCornerOrder) or {},
        formPageEnabled = DeepCopy(snap.doc.formPageEnabled) or {},
        rankSyncNames = DeepCopy(snap.doc.rankSyncNames) or {},
        nextUid = s.nextUid,
    }
    MergeStickyIntoDoc(replacement, sticky)
    -- keep nextUid above every restored uid
    local maxUid = 0
    for uid in pairs(replacement.bindings) do
        if type(uid) == "number" and uid > maxUid then
            maxUid = uid
        end
    end
    if (tonumber(replacement.nextUid) or 1) <= maxUid then
        replacement.nextUid = maxUid + 1
    end
    local previous = {}
    for key, value in pairs(replacement) do
        previous[key] = s[key]
        s[key] = value
    end
    local Conditions = ns.FluxBindingConditions
    local ok, reason = pcall(function()
        if Conditions then
            Conditions.InvalidateAvailability()
        end
        if _G.FluxBinding and _G.FluxBinding.RequestApplyAll then
            _G.FluxBinding.RequestApplyAll("respec")
        end
    end)
    if not ok then
        -- A failed restore must keep the original document, including UID and
        -- ordering state. Reconcile any request queued before the error.
        for key in pairs(replacement) do
            s[key] = previous[key]
        end
        if Conditions then pcall(Conditions.InvalidateAvailability) end
        if _G.FluxBinding and _G.FluxBinding.RequestApplyAll then
            pcall(_G.FluxBinding.RequestApplyAll, "respec.rollback")
        end
        return false, tostring(reason)
    end
    if _G.FluxSpellBindingEditor_ReloadLiveSession then
        pcall(_G.FluxSpellBindingEditor_ReloadLiveSession)
    end
    if _G.FluxBindingBrowser_Refresh then
        pcall(_G.FluxBindingBrowser_Refresh)
    end
    return true
end

local function FinishPending(ok, reason)
    local done = _pendingDone
    _pendingSnap = nil
    _pendingDone = nil
    if _combatWatcher then
        _combatWatcher:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
    if done then
        if ok then
            InvokeAfter(done, true)
        else
            pcall(done, false, reason)
        end
    end
end

local function EnsureCombatWatcher()
    if not _combatWatcher then
        _combatWatcher = CreateFrame("Frame")
        _combatWatcher:SetScript("OnEvent", function(self)
            if _pendingSnap and not InCombatLockdown() then
                local snap = _pendingSnap
                local called, ok, reason = pcall(ApplySnapshotInternal, snap)
                if not called then reason, ok = ok, false end
                FinishPending(ok, reason)
            end
            if not _pendingSnap then
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            end
        end)
    end
    _combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
end

--- Cancel only the deferred restore owned by this completion callback.
--- A cancelled profile must not overwrite live bindings when combat ends.
function _G.FluxSpellBindings_CancelPendingApply(afterFn)
    if not _pendingSnap or _pendingDone ~= afterFn then return false end
    FinishPending(false, "CANCELLED")
    return true
end

function _G.FluxSpellBindings_EmptySnapshot()
    return {
        version = SNAPSHOT_VERSION,
        doc = {
            bindings = {},
            chordStackOrder = {},
            badgeCornerOrder = {},
            formPageEnabled = {},
            rankSyncNames = {},
        },
    }
end

function _G.FluxSpellBindings_CaptureSnapshot()
    return {
        version = SNAPSHOT_VERSION,
        doc = CompactDoc(CurrentDoc()),
    }
end

function _G.FluxSpellBindings_MatchesSnapshot(snap)
    if type(snap) ~= "table" or type(snap.doc) ~= "table" then
        return false
    end
    if snap.version ~= SNAPSHOT_VERSION then
        -- old-format snapshot (pre-rewrite): treat as non-matching but valid
        return false
    end
    -- Compare compacted views so default stubs in live DB don't false-diff.
    return DeepEquals(CompactDoc(snap.doc), CompactDoc(CurrentDoc()))
end

function _G.FluxSpellBindings_IsLegacySnapshot(snap)
    return type(snap) == "table"
        and type(snap.doc) == "table"
        and type(snap.version) == "number"
        and snap.version ~= SNAPSHOT_VERSION
end

--- True when snap is a V3 document (or empty helper). False for nil/invalid/legacy.
function _G.FluxSpellBindings_IsV3Snapshot(snap)
    return type(snap) == "table"
        and type(snap.doc) == "table"
        and snap.version == SNAPSHOT_VERSION
end

--- Count Binding-editor instances in the snapshot (keyed + unbound/implicit).
function _G.FluxSpellBindings_CountBoundSpells(snap)
    local doc = type(snap) == "table" and snap.doc
    if type(doc) ~= "table" then return 0 end
    local compact = CompactDoc(doc)
    local n = 0
    for _ in pairs(compact.bindings) do
        n = n + 1
    end
    return n
end

--- Count only rows with a Flux key (UI detail / debug).
function _G.FluxSpellBindings_CountKeyedBindings(snap)
    local doc = type(snap) == "table" and snap.doc
    local bindings = type(doc) == "table" and doc.bindings
    if type(bindings) ~= "table" then return 0 end
    local n = 0
    for _, b in pairs(bindings) do
        if type(b) == "table" and b.key and b.key ~= "" then
            n = n + 1
        end
    end
    return n
end

--- Count rows with non-default settings (incl. unbound action-bar profiles).
function _G.FluxSpellBindings_CountCustomizedBindings(snap)
    local doc = type(snap) == "table" and snap.doc
    local bindings = type(doc) == "table" and doc.bindings
    if type(bindings) ~= "table" then return 0 end
    local n = 0
    for _, b in pairs(bindings) do
        if IsBindingCustomized(b) then
            n = n + 1
        end
    end
    return n
end

--- Replace the live document with the snapshot and re-apply.
--- @return ok boolean, reason string|nil
function _G.FluxSpellBindings_ApplySnapshot(snap, afterFn)
    if type(snap) ~= "table" or type(snap.doc) ~= "table" then
        return false, "invalid snapshot"
    end
    if snap.version ~= SNAPSHOT_VERSION then
        return false, "snapshot from the previous binding system (not restorable)"
    end
    -- Normalize and detach from the caller for both immediate and deferred
    -- restores; a combat wait must not change which document gets applied.
    local normalized = {
        version = SNAPSHOT_VERSION,
        doc = CompactDoc(snap.doc),
    }
    if _pendingSnap then
        FinishPending(false, "SUPERSEDED")
    end
    if InCombatLockdown() then
        _pendingSnap = normalized
        _pendingDone = afterFn
        EnsureCombatWatcher()
        return false, "IN_COMBAT"
    end
    local called, ok, reason = pcall(ApplySnapshotInternal, normalized)
    if not called then reason, ok = ok, false end
    InvokeAfter(afterFn, ok, reason)
    return ok, reason
end
