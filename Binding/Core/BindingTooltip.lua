-- Binding/Core/BindingTooltip.lua
-- Append Flux Binding peers / badges / multi-cast / conditions onto strip action tooltips.
-- Bar & Badges display settings are omitted here (edit them in Binding; they save via Respec).
--
-- Retail: TooltipDataProcessor rebuilds GameTooltip after SetSpellByID/SetAction, so
-- sync AddLine from UpdateTooltip is wiped — PostCall is the reliable path.
-- Classic: Hosts.UpdateTooltip calls AppendForButton directly after SetTooltip.

local addonName, ns = ...

local BT = {}
ns.FluxBindingTooltip = BT
_G.FluxBindingTooltip = BT

local hooksInstalled = false

local function TextureTag(tex)
    if not tex then return "" end
    return "|T" .. tostring(tex) .. ":14:14:0:0|t "
end

local function L(key, fallback)
    local loc = _G.FluxSpellBindingLocale
    if type(loc) == "table" and type(loc[key]) == "string" and loc[key] ~= "" then
        return loc[key]
    end
    return fallback or key
end

local function GetFormToken()
    local Forms = ns.FluxBindingForms
    if Forms and Forms.GetCurrentToken then
        return Forms.GetCurrentToken() or "noform"
    end
    return "noform"
end

local function SummarizeSub(sub)
    local Conditions = ns.FluxBindingConditions
    if Conditions and Conditions.SummarizeSub then
        -- Action bar LAB tips: list peers / badges / multi-cast, not Bar & Badges settings.
        return Conditions.SummarizeSub(sub, { omitBadge = true }) or ""
    end
    return ""
end

local function IsFluxLabButton(button)
    if not button then return false end
    if button._fluxBarSlotIndex or button._fluxBarRow then
        return true
    end
    local name = button.GetName and button:GetName()
    if type(name) == "string" then
        if name:match("^FluxActionStripButton")
            or name:match("^FluxActionStripSec")
            or name:match("^FluxActionStripTert")
            or name:match("^FluxActionButton")
            or name:match("^FluxSecondaryButton")
            or name:match("^FluxTertiaryButton") then
            return true
        end
    end
    return false
end

local function ResolveButtonSlot(button)
    if not button then return nil end
    if button.GetAttribute then
        local slot = tonumber(button:GetAttribute("action"))
        if slot and slot > 0 then return slot end
    end
    local host = button._fluxHost
    if host and host.slot then
        local slot = tonumber(host.slot)
        if slot then return slot end
    end
    if button.GetEffectiveActionSlot then
        local slot = tonumber(button:GetEffectiveActionSlot())
        if slot then return slot end
    end
    if button.GetMacrotextSlot then
        local slot = tonumber(button:GetMacrotextSlot())
        if slot then return slot end
    end
    local SlotHost = ns.FluxSlotHost or _G.FluxSlotHost
    if SlotHost and SlotHost.GetDisplayedSlot then
        return tonumber(SlotHost.GetDisplayedSlot(button))
    end
    return nil
end

--- Native action descriptor for an action slot (spell/item), for GetEditorOverlap.
local function ActionDescForSlot(slot)
    if not slot or not GetActionInfo then return nil end
    local Action = ns.FluxBindingAction
    if not Action then return nil end
    local ok, actionType, id, subType = pcall(GetActionInfo, slot)
    if not ok then return nil end
    if actionType == "spell" and id and id > 0 then
        return Action.Spell and Action.Spell(id)
    elseif actionType == "item" and id then
        return Action.Item and Action.Item(id)
    elseif actionType == "macro" and subType == "spell" and id and id > 0 then
        return Action.Spell and Action.Spell(id)
    end
    return nil
end

local function SlotChordPrimary(slot)
    local Placement = ns.FluxBindingPlacement
    if not (Placement and Placement.DescribeBarSlot) then
        return nil, nil
    end
    local d = Placement.DescribeBarSlot(slot)
    if not d then
        return nil, nil
    end
    local primary = d.primary or d.chord
    if (not primary or primary == "") and type(d.chords) == "table" then
        primary = d.chords[1]
    end
    local label = primary
    if type(d.chords) == "table" and #d.chords > 1 then
        label = table.concat(d.chords, ", ")
    end
    return primary, label
end

--- Resolve the Flux binding for THIS bar slot only.
--- Never fall through to another same-spell instance on a different key/place
--- (e.g. Icy Veins on C must not pick the Z multi-cast profile).
local function FindSubjectUidForSlot(slot, actionDesc)
    local DB = ns.FluxBindingDB3
    local Action = ns.FluxBindingAction
    if not DB or not DB.All or not slot then return nil end
    local wantPid = "ab:" .. tostring(slot)
    local ak = actionDesc and Action and Action.Key and Action.Key(actionDesc)
    local familyAk = actionDesc and Action and Action.FamilyKey and Action.FamilyKey(actionDesc)
    local lookupAk = ak or familyAk

    -- Exact placeId for this slot (strongest).
    if lookupAk and DB.FindUidForPlace then
        local uid = DB.FindUidForPlace(lookupAk, wantPid)
        if uid then return uid end
        if familyAk and familyAk ~= lookupAk then
            uid = DB.FindUidForPlace(familyAk, wantPid)
            if uid then return uid end
        end
    end
    for uid, b in pairs(DB.All()) do
        if b and b.placeId == wantPid then
            return uid
        end
    end

    -- Same action keyed to this slot's live chord (C vs Z stay distinct).
    local chordPrimary = SlotChordPrimary(slot)
    if lookupAk and chordPrimary and chordPrimary ~= "" and DB.FindUidForPlace then
        local uid = DB.FindUidForPlace(lookupAk, nil, chordPrimary)
        if uid then return uid end
        if familyAk and familyAk ~= lookupAk then
            uid = DB.FindUidForPlace(familyAk, nil, chordPrimary)
            if uid then return uid end
        end
    end

    -- Legacy unplaced same-action row only when no other placed sibling exists.
    -- Never claim a binding that is place-scoped to a different ab: slot.
    if not lookupAk or not Action then
        return nil
    end
    local unplaced, sawOtherPlace = nil, false
    local ChordMap = ns.FluxChordMap or _G.FluxChordMap
    local wantChord = chordPrimary
    if wantChord and ChordMap and ChordMap.Normalize then
        wantChord = ChordMap.Normalize(wantChord) or wantChord
    end
    for uid, b in pairs(DB.All()) do
        if b and type(b.action) == "table" then
            local match = (Action.KeysMatch and Action.KeysMatch(b.action, lookupAk))
                or (Action.Key and Action.Key(b.action) == lookupAk)
                or (familyAk and Action.Key and Action.Key(b.action) == familyAk)
            if match then
                local pid = b.placeId
                if type(pid) == "string" and pid ~= "" and not pid:match("^inst:") then
                    if pid ~= wantPid then
                        sawOtherPlace = true
                    end
                elseif b.key and b.key ~= "" and wantChord then
                    local have = b.key
                    if ChordMap and ChordMap.Normalize then
                        have = ChordMap.Normalize(b.key) or b.key
                    end
                    if have == wantChord then
                        return uid
                    end
                elseif not b.key or b.key == "" then
                    if not pid or pid == "" or pid:match("^inst:") then
                        unplaced = unplaced or uid
                    end
                end
            end
        end
    end
    if sawOtherPlace then
        return nil
    end
    return unplaced
end

--- Primary chord for API lookup + display label (may list several).
--- Prefer the hovered slot's live bar chord over editor-overlap chord so a
--- same-spell instance on another key cannot relabel this tip as "Shared key Z".
local function ChordInfoForSlot(slot, info)
    local primary, label = SlotChordPrimary(slot)
    if primary and primary ~= "" then
        return primary, label
    end
    if info and info.chord and info.chord ~= "" then
        return info.chord, info.chord
    end
    return nil, nil
end

local function BindingBelongsToSlotChord(binding, slotChord)
    if not binding or not slotChord or slotChord == "" then
        return false
    end
    if not binding.key or binding.key == "" then
        return true
    end
    local ChordMap = ns.FluxChordMap or _G.FluxChordMap
    local want, have = slotChord, binding.key
    if ChordMap and ChordMap.Normalize then
        want = ChordMap.Normalize(slotChord) or slotChord
        have = ChordMap.Normalize(binding.key) or binding.key
    end
    return want == have
end

local function LineForNameIcon(name, icon, cond, tipTag)
    local line = TextureTag(icon) .. (name or "?")
    if cond and cond ~= "" then
        line = line .. " |cffaaaaaa— " .. cond .. "|r"
    elseif tipTag and tipTag ~= "" then
        line = line .. " |cffaaaaaa— " .. tipTag .. "|r"
    end
    return line
end

local function ResolveBadgeLine(bd, formToken, covered)
    if type(bd) ~= "table" then return nil end
    local DB = ns.FluxBindingDB3
    local Action = ns.FluxBindingAction
    local key = bd.key
    local isExtra = type(key) == "string" and key:match("^extra:") ~= nil

    if not isExtra and key and DB and DB.Get then
        local b = DB.Get(key)
        if b and Action then
            if covered then covered[key] = true end
            local sub = DB.GetFormSub and DB.GetFormSub(b, formToken)
            local name = (Action.GetNameWithRank and Action.GetNameWithRank(b.action))
                or (Action.GetName and Action.GetName(b.action))
                or "?"
            return LineForNameIcon(name, Action.GetIcon and Action.GetIcon(b.action), SummarizeSub(sub), "corner badge")
        end
    end

    local icon = bd.icon
    local name
    local spellId = tonumber(bd.spellId)
    local itemId = tonumber(bd.itemId)
    if isExtra and DB then
        local ownerUid, idx = tostring(key):match("^extra:([^:]+):(%d+)$")
        local owner = ownerUid and DB.Get(tonumber(ownerUid) or ownerUid)
        if owner then
            local sub = DB.GetFormSub and DB.GetFormSub(owner, formToken)
            local list = DB.GetMacroExtras and DB.GetMacroExtras(sub) or {}
            local e = list[tonumber(idx)]
            if e then
                icon = icon or (DB.GetMacroExtraIcon and DB.GetMacroExtraIcon(e))
                name = (DB.GetMacroExtraLabel and DB.GetMacroExtraLabel(e)) or name
                if e.type == "spell" then
                    spellId = spellId or tonumber(e.id)
                elseif e.type == "item" then
                    itemId = itemId or tonumber(e.id)
                end
            end
        end
    end
    if Action then
        if spellId and not name then
            local desc = Action.Spell and Action.Spell(spellId)
            name = (Action.GetNameWithRank and Action.GetNameWithRank(desc))
                or (Action.GetName and Action.GetName(desc))
            icon = icon or (Action.GetIcon and Action.GetIcon(desc))
        elseif itemId and not name then
            local desc = Action.Item and Action.Item(itemId)
            name = Action.GetName and Action.GetName(desc)
            icon = icon or (Action.GetIcon and Action.GetIcon(desc))
        end
    end
    if not icon and not name then return nil end
    return LineForNameIcon(name or "Multi-cast", icon or 134400, nil, isExtra and "multi-cast" or "corner badge")
end

local function CollectBadges(button, slot)
    local BadgeHost = ns.FluxBadgeHost or _G.FluxBadgeHost
    if not BadgeHost then return nil end
    local list = BadgeHost.GetSlotBadges and BadgeHost.GetSlotBadges(slot)
    if type(list) == "table" and #list > 0 then
        return list
    end
    -- Visible widgets may exist even if map lookup keyed oddly during paging.
    if BadgeHost.GetVisibleBadgesForButton then
        local widgets = BadgeHost.GetVisibleBadgesForButton(button)
        if type(widgets) == "table" and #widgets > 0 and type(list) == "table" then
            return list
        end
        if type(widgets) == "table" and #widgets > 0 then
            -- Reconstruct want entries from widget keys when slot map empty.
            local out = {}
            for i = 1, #widgets do
                local rec = widgets[i]
                local want = rec and rec._fluxWant
                local w = rec and rec.Widget or rec
                local key = (rec and rec._fluxBadgeKey)
                    or (w and w._fluxBadgeKey)
                    or (want and want.key)
                if key then
                    out[#out + 1] = {
                        key = key,
                        icon = (want and want.icon)
                            or (w and w.icon and w.icon.GetTexture and w.icon:GetTexture()),
                        spellId = (want and want.spellId) or (rec and rec.SpellId) or (w and w._fluxSpellId),
                        itemId = (want and want.itemId) or (rec and rec.ItemId) or (w and w._fluxItemId),
                    }
                end
            end
            if #out > 0 then return out end
        end
    end
    return list
end

--- Binding + current-form sub for this bar slot (placeId or action match).
local function ResolveSlotBinding(slot, actionDesc)
    local DB = ns.FluxBindingDB3
    if not DB or not DB.Get then return nil, nil, nil end
    local uid = FindSubjectUidForSlot(slot, actionDesc)
    local binding = uid and DB.Get(uid)
    if not binding then return nil, nil, nil end
    local sub = DB.GetFormSub and DB.GetFormSub(binding, GetFormToken())
    return uid, binding, sub
end

local function IsCustomSub(sub)
    if type(sub) ~= "table" then return false end
    -- Ignore Bar & Badges-only customizations for tooltip gating (settings live in Binding UI).
    return SummarizeSub(sub) ~= ""
end

local function FinishTooltipLines(tooltip, button, lines)
    if #lines <= 1 then
        return false
    end
    tooltip:AddLine(" ")
    for i = 1, #lines do
        local row = lines[i]
        tooltip:AddLine(row.text, row.r, row.g, row.b, true)
    end
    tooltip:Show()
    tooltip._fluxBindingTipOwner = button
    return true
end

--- Append shared-key / badge / multi-cast lines, or solo non-default Binding settings.
--- @param button Frame LAB action button
--- @param tooltip? GameTooltip
--- @return boolean true if any binding lines were added
function BT.AppendForButton(button, tooltip)
    tooltip = tooltip or GameTooltip
    if not button or not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then
        return false
    end
    if not IsFluxLabButton(button) then
        return false
    end

    local KeyBound = LibStub and LibStub("LibKeyBound-1.0", true)
    if KeyBound and KeyBound.IsShown and KeyBound:IsShown() then
        return false
    end

    -- Already appended for this tooltip fill (PostCall + LAB sync).
    if tooltip._fluxBindingTipOwner == button then
        return false
    end

    local FluxBinding = _G.FluxBinding
    local DB = ns.FluxBindingDB3
    local Action = ns.FluxBindingAction
    local SlotProgram = ns.FluxSlotProgram or _G.FluxSlotProgram
    local BadgeHost = ns.FluxBadgeHost or _G.FluxBadgeHost
    if not FluxBinding and not BadgeHost and not SlotProgram and not DB then
        return false
    end

    local slot = ResolveButtonSlot(button)
    if not slot then return false end

    local hasProgram = SlotProgram and SlotProgram.Get and SlotProgram.Get(slot) and true or false
    local badges = CollectBadges(button, slot)
    local hasBadges = type(badges) == "table" and #badges > 0

    local actionDesc = ActionDescForSlot(slot)
    local subjectUid, subjectBinding, subjectSub = ResolveSlotBinding(slot, actionDesc)
    if not actionDesc and subjectBinding and type(subjectBinding.action) == "table" then
        actionDesc = subjectBinding.action
    end
    local soloCustom = IsCustomSub(subjectSub)
    local soloSummary = SummarizeSub(subjectSub)

    -- Slot chord is authoritative for the tip label / peer set.
    local chordPrimary, chordLabel = ChordInfoForSlot(slot, nil)

    local info
    -- Only use editor-overlap for this slot's binding when it actually belongs
    -- on this chord (do not pull Z multi-cast onto a plain C Icy Veins).
    local placeMatch = subjectBinding
        and subjectBinding.placeId == ("ab:" .. tostring(slot))
    local keyMatch = subjectBinding and chordPrimary
        and BindingBelongsToSlotChord(subjectBinding, chordPrimary)
    local subjectOnThisChord = false
    if subjectBinding then
        if subjectBinding.key and subjectBinding.key ~= "" then
            -- Keyed profiles only attach when the key is this slot's chord.
            subjectOnThisChord = keyMatch and true or false
        else
            subjectOnThisChord = placeMatch or keyMatch or (not chordPrimary)
        end
    end
    if subjectOnThisChord and FluxBinding and FluxBinding.GetEditorOverlap and actionDesc then
        local ok, result = pcall(FluxBinding.GetEditorOverlap, actionDesc, subjectUid)
        if ok then info = result end
    end

    if FluxBinding and FluxBinding.GetPeersForChord and chordPrimary then
        local ak = actionDesc and Action and Action.Key and Action.Key(actionDesc)
        local ok, byChord = pcall(FluxBinding.GetPeersForChord, chordPrimary, subjectUid, ak)
        if ok and byChord and ((byChord.peers and #byChord.peers > 0) or byChord.native) then
            if not info then
                info = byChord
            else
                -- Peers always from THIS slot's chord; never keep another key's peer list.
                info.peers = byChord.peers or info.peers
                if not info.native and byChord.native then
                    info.native = byChord.native
                    info.slot = info.slot or byChord.slot
                end
                info.chord = chordPrimary
            end
        end
    end

    if info and chordPrimary then
        info.chord = chordPrimary
    end

    if subjectOnThisChord and info and FluxBinding and FluxBinding.GetEditorOverlap
        and actionDesc and not info.multiCastExtras then
        local ok, full = pcall(FluxBinding.GetEditorOverlap, actionDesc, subjectUid)
        if ok and full then
            info.multiCastExtras = full.multiCastExtras
            info.multiCastHosts = full.multiCastHosts
        end
    end

    local peers = info and info.peers
    local extras = info and info.multiCastExtras
    local hosts = info and info.multiCastHosts
    local peerCount = 0
    if type(peers) == "table" then
        for i = 1, #peers do
            local p = peers[i]
            if p and p.uid and p.uid ~= subjectUid then
                peerCount = peerCount + 1
            end
        end
    end
    local hasPeers = peerCount > 0
    local hasMulti = (type(extras) == "table" and #extras > 0) or (type(hosts) == "table" and #hosts > 0)
    local hasShared = hasPeers or hasBadges or hasMulti

    if not hasProgram and not hasShared and not soloCustom then
        return false
    end

    if FluxTooltipGuard and FluxTooltipGuard.Reset then
        FluxTooltipGuard.Reset(tooltip)
    elseif FluxTooltipGuard and FluxTooltipGuard.Unblock then
        FluxTooltipGuard.Unblock(tooltip)
    end

    local formToken = GetFormToken()
    if not chordLabel then
        _, chordLabel = ChordInfoForSlot(slot, info)
    end
    local lines = {}
    local covered = {}

    -- Solo non-default cast/load profile (Bar & Badges settings are omitted from LAB tips).
    if not hasShared then
        if not soloCustom and not hasProgram then
            return false
        end
        if not soloCustom then
            return false
        end
        lines[#lines + 1] = {
            text = "Binding settings",
            r = 1, g = 0.82, b = 0,
        }
        local name, icon
        if subjectBinding and Action then
            name = (Action.GetNameWithRank and Action.GetNameWithRank(subjectBinding.action))
                or (Action.GetName and Action.GetName(subjectBinding.action))
            icon = Action.GetIcon and Action.GetIcon(subjectBinding.action)
        elseif info and info.native then
            name, icon = info.native.name, info.native.icon
        end
        local cond = soloSummary
        if cond == "" then
            cond = nil
        end
        lines[#lines + 1] = {
            text = LineForNameIcon(name, icon, cond, cond and nil or "customized"),
            r = 1, g = 1, b = 1,
        }
        return FinishTooltipLines(tooltip, button, lines)
    end

    if chordLabel and chordLabel ~= "" then
        lines[#lines + 1] = {
            text = (L("badge_slot_shared_intro", "Shared key |cffffcc00%s|r — spells on this bind:")
                ):format(chordLabel),
            r = 1, g = 0.82, b = 0,
        }
    else
        lines[#lines + 1] = {
            text = L("related_bindings_heading", "Spells on the same key"),
            r = 1, g = 0.82, b = 0,
        }
    end

    if info and info.native and info.native.kind ~= "macro" then
        local nak = info.native.actionKey
        local already = (subjectUid and covered[subjectUid])
            or (nak and covered["ak:" .. nak])
        if not already then
            local cond = soloSummary
            if subjectUid then covered[subjectUid] = true end
            if type(peers) == "table" and nak and cond == "" then
                for i = 1, #peers do
                    local p = peers[i]
                    if p and p.actionKey == nak and p.uid and DB and DB.Get then
                        local b = DB.Get(p.uid)
                        cond = SummarizeSub(b and DB.GetFormSub and DB.GetFormSub(b, formToken))
                        covered[p.uid] = true
                        break
                    end
                end
            end
            if nak then covered["ak:" .. nak] = true end
            local tag = info.subjectIsNative and "on action bar" or nil
            lines[#lines + 1] = {
                text = LineForNameIcon(info.native.name, info.native.icon, cond, tag),
                r = 1, g = 1, b = 1,
            }
        end
    elseif soloCustom and soloSummary ~= "" then
        local name, icon
        if subjectBinding and Action then
            name = (Action.GetNameWithRank and Action.GetNameWithRank(subjectBinding.action))
                or (Action.GetName and Action.GetName(subjectBinding.action))
            icon = Action.GetIcon and Action.GetIcon(subjectBinding.action)
        end
        if subjectUid then covered[subjectUid] = true end
        lines[#lines + 1] = {
            text = LineForNameIcon(name, icon, soloSummary, "on action bar"),
            r = 1, g = 1, b = 1,
        }
    end

    if hasBadges then
        for i = 1, #badges do
            local line = ResolveBadgeLine(badges[i], formToken, covered)
            if line then
                lines[#lines + 1] = { text = line, r = 0.9, g = 0.9, b = 0.9 }
            end
        end
    end

    if type(peers) == "table" then
        for i = 1, #peers do
            local p = peers[i]
            if p and p.uid and not covered[p.uid]
                and not (p.actionKey and covered["ak:" .. p.actionKey]) then
                covered[p.uid] = true
                if p.actionKey then covered["ak:" .. p.actionKey] = true end
                local b = DB and DB.Get and DB.Get(p.uid)
                local sub = b and DB.GetFormSub and DB.GetFormSub(b, formToken)
                local cond = SummarizeSub(sub)
                local name = p.name
                if b and Action then
                    name = (Action.GetNameWithRank and Action.GetNameWithRank(b.action)) or name
                end
                local tag = p.isSubject and "this binding" or nil
                lines[#lines + 1] = {
                    text = LineForNameIcon(name, p.icon, cond, tag),
                    r = p.available == false and 0.55 or 0.9,
                    g = p.available == false and 0.55 or 0.9,
                    b = p.available == false and 0.55 or 0.9,
                }
            end
        end
    end

    if type(extras) == "table" and not hasBadges then
        for i = 1, #extras do
            local ex = extras[i]
            if ex then
                local tip = LineForNameIcon(
                    ex.name,
                    ex.icon or (ex.action and Action and Action.GetIcon and Action.GetIcon(ex.action)),
                    nil,
                    "multi-cast")
                if ex.hostName and ex.hostUid and subjectUid and ex.hostUid ~= subjectUid then
                    tip = tip .. (" |cff9ecfff(%s)|r"):format(ex.hostName)
                end
                lines[#lines + 1] = { text = tip, r = 0.85, g = 0.9, b = 1 }
            end
        end
    elseif type(extras) == "table" and hasBadges and #extras > #badges then
        for i = #badges + 1, #extras do
            local ex = extras[i]
            if ex then
                lines[#lines + 1] = {
                    text = LineForNameIcon(ex.name, ex.icon, nil, "multi-cast"),
                    r = 0.85, g = 0.9, b = 1,
                }
            end
        end
    end

    if type(hosts) == "table" then
        for i = 1, #hosts do
            local h = hosts[i]
            if h and h.name then
                lines[#lines + 1] = {
                    text = ("|cff9ecfffUsed as multi-cast on:|r %s"):format(h.name),
                    r = 0.6, g = 0.8, b = 1,
                }
            end
        end
    end

    return FinishTooltipLines(tooltip, button, lines)
end

--- Strip UpdateTooltip entry: append now (classic) and/or schedule (retail wipe race).
function BT.OnLabTooltip(button)
    if not button then return end
    BT.AppendForButton(button, GameTooltip)
    -- Retail TooltipDataProcessor may rebuild after this; PostCall also runs.
    -- One-frame retry catches late fills that do not fire our registered types.
    local function retry()
        if not button or not button.IsMouseOver or not button:IsMouseOver() then
            return
        end
        if GameTooltip and GameTooltip._fluxBindingTipOwner == button then
            return
        end
        BT.AppendForButton(button, GameTooltip)
    end
    if RunNextFrame then
        RunNextFrame(retry)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(0, retry)
    end
end

local function OnTooltipPostCall(tooltip)
    if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then
        return
    end
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    if not IsFluxLabButton(owner) then
        return
    end
    BT.AppendForButton(owner, tooltip)
end

function BT.InstallHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipCleared", function(self)
            self._fluxBindingTipOwner = nil
        end)
        GameTooltip:HookScript("OnHide", function(self)
            self._fluxBindingTipOwner = nil
        end)
    end

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        local types = {
            Enum.TooltipDataType.Spell,
            Enum.TooltipDataType.Item,
            Enum.TooltipDataType.Macro,
            Enum.TooltipDataType.Toy,
            Enum.TooltipDataType.PetAction,
            Enum.TooltipDataType.Mount,
        }
        for i = 1, #types do
            if types[i] ~= nil then
                TooltipDataProcessor.AddTooltipPostCall(types[i], OnTooltipPostCall)
            end
        end
    end

    -- Classic / fallback: after Blizzard Set* fills the tip.
    if GameTooltip then
        if GameTooltip.SetSpellByID then
            hooksecurefunc(GameTooltip, "SetSpellByID", function(tip)
                local owner = tip.GetOwner and tip:GetOwner()
                if IsFluxLabButton(owner) then
                    BT.AppendForButton(owner, tip)
                end
            end)
        end
        if GameTooltip.SetItemByID then
            hooksecurefunc(GameTooltip, "SetItemByID", function(tip)
                local owner = tip.GetOwner and tip:GetOwner()
                if IsFluxLabButton(owner) then
                    BT.AppendForButton(owner, tip)
                end
            end)
        end
        if GameTooltip.SetAction then
            hooksecurefunc(GameTooltip, "SetAction", function(tip)
                local owner = tip.GetOwner and tip:GetOwner()
                if IsFluxLabButton(owner) then
                    BT.AppendForButton(owner, tip)
                end
            end)
        end
        if GameTooltip.SetHyperlink then
            hooksecurefunc(GameTooltip, "SetHyperlink", function(tip)
                local owner = tip.GetOwner and tip:GetOwner()
                if IsFluxLabButton(owner) then
                    BT.AppendForButton(owner, tip)
                end
            end)
        end
    end
end

BT.InstallHooks()
