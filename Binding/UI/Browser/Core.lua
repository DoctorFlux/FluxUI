-- Binding/UI/Browser/Core.lua
-- FluxWindowFrame "Binding" tab: Clicked-style left catalog (spellbook skill-line
-- groups) + embedded editor on the right. Respec profile picker previews that
-- profile's spellBindings without applying gear/bars/live DB.

local addonName, ns = ...

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local DB = ns.FluxBindingDB3
local Action = ns.FluxBindingAction
local SpellLibrary = ns.FluxBindingSpellLibrary
local Editor = ns.FluxBindingEditor

local L = _G.FluxSpellBindingLocale or setmetatable({}, { __index = function(_, k) return k end })

local Browser = {}
ns.FluxBindingBrowser = Browser

local BINDING_W, BINDING_H = 920, 600
local LIST_W = 300
-- Blizzard Settings → AddOns → FluxUI: keep the catalog slim so the editor fits.
local LIST_W_BLIZ = 160
local LIST_W_MIN = 110
local EDITOR_MIN_W = 220
local EDITOR_MIN_W_BLIZ = 260

--- List column width for the current host.
--- opts.blizzard: narrower catalog for Blizzard Settings canvas.
local function EffectiveListWidth(hostW, opts)
    opts = type(opts) == "table" and opts or {}
    local blizzard = opts.blizzard and true or false
    hostW = tonumber(hostW) or 0
    if hostW <= 0 then
        return blizzard and LIST_W_BLIZ or LIST_W
    end

    local cap = blizzard and LIST_W_BLIZ or LIST_W
    local editorMin = blizzard and EDITOR_MIN_W_BLIZ or EDITOR_MIN_W
    local frac = blizzard and 0.28 or ((hostW < 560) and 0.34 or 0.40)
    local w = math.floor(hostW * frac + 0.5)
    if w > cap then w = cap end
    if w < LIST_W_MIN then w = LIST_W_MIN end
    local maxList = math.max(LIST_W_MIN, hostW - editorMin)
    if w > maxList then w = maxList end
    return w
end

local S = {
    shown = false,
    main = nil,
    listBorder = nil,
    listScroll = nil,
    listContent = nil,
    editorHost = nil,
    listWidth = LIST_W_BLIZ,
    hostBlizzard = false,
    filter = "all", -- all | unbound | default | customized
    search = "",
    sortMode = "name", -- name | key (Clicked Key/ABC toggle)
    source = "live", -- "live" | respec profile name
    previewProfile = nil,
    selectedKey = nil,
    collapsed = {}, -- tabName -> true when collapsed; nil = collapsed (minimized by default)
    flyoutExpanded = {}, -- flyout family key -> true when nested options shown
    savedWindowW = nil,
    savedWindowH = nil,
    pendingOpen = false,
    pendingOpenArg = nil,
}
Browser.S = S

-- Category headers ~original size; rows ~15% larger than the compact pass.
local ROW_H = 23
local HEADER_H = 22
local ROW_ICON = 21
local FLYOUT_INDENT = 16

--- Keep list scroll offset within the current range (fixes stuck offset when
--- jump-to-spell ran while range was 0, or host resize shrunk the range).
local function ClampListScroll()
    local scroll = S.listScroll
    if not scroll then
        return
    end
    if scroll.UpdateScrollChildRect then
        scroll:UpdateScrollChildRect()
    end
    local maxS = 0
    if scroll.GetVerticalScrollRange then
        maxS = scroll:GetVerticalScrollRange() or 0
    end
    local cur = scroll:GetVerticalScroll() or 0
    if cur > maxS then
        scroll:SetVerticalScroll(maxS)
    elseif cur < 0 then
        scroll:SetVerticalScroll(0)
    end
end

local function ScrollListByDelta(delta)
    local scroll = S.listScroll
    if not scroll then
        return false
    end
    local cur = scroll:GetVerticalScroll() or 0
    local maxS = 0
    if scroll.GetVerticalScrollRange then
        maxS = scroll:GetVerticalScrollRange() or 0
    end
    if maxS <= 0 then
        if cur ~= 0 then
            scroll:SetVerticalScroll(0)
        end
        return false
    end
    if cur > maxS then
        scroll:SetVerticalScroll(maxS)
        cur = maxS
    elseif cur < 0 then
        scroll:SetVerticalScroll(0)
        cur = 0
    end
    local step = math.max(ROW_H, 24) * 3
    local new = math.min(maxS, math.max(0, cur - (delta * step)))
    -- At end of list range: do not consume — let Ace outer ScrollFrame move.
    if new == cur then
        return false
    end
    scroll:SetVerticalScroll(new)
    return true
end

--- When the catalog list cannot scroll, forward wheel to AceConfig's outer ScrollFrame.
local function ForwardWheelToAceOuter(delta)
    local frame = S.main
    while frame do
        local obj = frame.obj
        if obj and obj.type == "ScrollFrame" and obj.MoveScroll then
            obj:MoveScroll(delta)
            return true
        end
        frame = frame:GetParent()
    end
    return false
end

--- Consume mouse wheel for the catalog list when the cursor is over it.
function Browser.TryListMouseWheel(delta)
    if not S.shown or not S.listBorder or not S.listScroll then
        return false
    end
    if MouseIsOver and not MouseIsOver(S.listBorder) then
        return false
    end
    return ScrollListByDelta(delta)
end

_G.FluxBindingBrowser_TryListMouseWheel = function(delta)
    return Browser.TryListMouseWheel(delta)
end

--- Consume mouse wheel for Cast/Targets/… tab scroll when over the editor pane.
function Browser.TryTabMouseWheel(delta)
    if not S.shown or not S.editorHost then
        return false
    end
    if MouseIsOver and not MouseIsOver(S.editorHost) then
        return false
    end
    local ed = Editor and Editor.S
    local scroll = ed and ed.tabScroll
    if not scroll or not scroll.MoveScroll then
        return false
    end
    local status = scroll.status or scroll.localstatus
    if not status then
        return false
    end
    local before = status.scrollvalue or 0
    scroll:MoveScroll(delta)
    local after = status.scrollvalue or 0
    -- Also treat "scrollbar present and moved" as handled; SetValue may be same at ends.
    if after ~= before then
        return true
    end
    if scroll.scrollBarShown then
        local viewH = scroll.scrollframe and scroll.scrollframe:GetHeight() or 0
        local contentH = scroll.content and scroll.content:GetHeight() or 0
        if contentH > viewH + 2 then
            -- At end of range — consume so Ace outer does not yank the pane the other way.
            return true
        end
    end
    return false
end

_G.FluxBindingBrowser_TryTabMouseWheel = function(delta)
    return Browser.TryTabMouseWheel(delta)
end

local function IsGroupCollapsed(groupName)
    -- Minimized by default until the user expands a category.
    if S.collapsed[groupName] == nil then
        return true
    end
    return S.collapsed[groupName] and true or false
end

-- Flyout child roles nest under the main Extra button (hearth / mount / class TP / utility).
local FLYOUT_CHILD_TO_FAMILY = {
    hearth_flyout = "hearth",
    mount_flyout = "mount",
    class_teleport_spell = "class_teleport",
}

local FLYOUT_PARENT_ROLE = {
    hearth = "hearth",
    mount = "mount",
    class_teleport = "class_teleport",
}

local function FlyoutFamilyOfPlace(place)
    if type(place) ~= "table" then return nil end
    local role = place.role
    if role == "utility_flyout" or role == "utility" then
        local slot = tonumber(place.slotIndex) or tonumber(place.slot)
        if slot then
            return "utility:" .. tostring(slot)
        end
    end
    if FLYOUT_CHILD_TO_FAMILY[role] then
        return FLYOUT_CHILD_TO_FAMILY[role]
    end
    if FLYOUT_PARENT_ROLE[role] then
        return FLYOUT_PARENT_ROLE[role]
    end
    return nil
end

local function FlyoutFamilyOfEntry(entry)
    return entry and FlyoutFamilyOfPlace(entry.place) or nil
end

local function IsFlyoutChildEntry(entry)
    local role = entry and entry.place and entry.place.role
    if role == "utility_flyout" then return true end
    return role and FLYOUT_CHILD_TO_FAMILY[role] and true or false
end

local function IsFlyoutParentEntry(entry)
    local role = entry and entry.place and entry.place.role
    if role == "utility" then return true end
    return role and FLYOUT_PARENT_ROLE[role] and true or false
end

local function FlyoutFamilyDisplayName(family, sample)
    if family == "hearth" then return "Best hearth / teleport" end
    if family == "mount" then return "Mount" end
    if family == "class_teleport" then return "Class teleport" end
    local utilSlot = type(family) == "string" and family:match("^utility:(%d+)$")
    if utilSlot then
        return ("Utility %s"):format(utilSlot)
    end
    return (sample and sample.name) or family
end

local UTIL_MOD_SORT = {
    [""] = 1,
    base = 1,
    nomod = 1,
    SHIFT = 2,
    shift = 2,
    CTRL = 3,
    ctrl = 3,
    ALT = 4,
    alt = 4,
}

local function UtilityChildSortKey(entry)
    local mk = entry and entry.place and entry.place.modKey
    if mk == nil then return 1 end
    local s = tostring(mk)
    if UTIL_MOD_SORT[s] then return UTIL_MOD_SORT[s] end
    return 50 + (#s)
end

--- Nest hearth/mount/class-teleport/utility flyout options under their main Extra button row.
local function NestFlyoutEntries(entries)
    local parents = {} -- family -> entry
    local children = {} -- family -> { entries }
    local out = {}

    for i = 1, #(entries or {}) do
        local e = entries[i]
        local family = FlyoutFamilyOfEntry(e)
        if IsFlyoutChildEntry(e) and family then
            children[family] = children[family] or {}
            children[family][#children[family] + 1] = e
        elseif IsFlyoutParentEntry(e) and family then
            parents[family] = e
            out[#out + 1] = e
        else
            out[#out + 1] = e
        end
    end

    for family, kids in pairs(children) do
        -- Single spell/item: show that row alone (no parent nest).
        if #kids == 1 then
            local parent = parents[family]
            if parent then
                for i = #out, 1, -1 do
                    if out[i] == parent then
                        table.remove(out, i)
                        break
                    end
                end
            end
            out[#out + 1] = kids[1]
        else
            local parent = parents[family]
            if not parent then
                -- Synthesize a main-button row when Placement only emitted flyout children.
                local sample = kids[1]
                local place = sample and sample.place
                local utilSlot = type(family) == "string" and family:match("^utility:(%d+)$")
                parent = {
                    kind = "extra",
                    name = FlyoutFamilyDisplayName(family, sample),
                    icon = (function()
                        if family == "class_teleport" then
                            local TP = _G.FluxNCTeleportPortal
                            if TP and TP.GetSpellForModifier then
                                local sp = TP.GetSpellForModifier("nomod")
                                if type(sp) == "table" and (sp.icon or sp.spellID) then
                                    return sp.icon
                                        or (GetSpellTexture and GetSpellTexture(sp.spellID))
                                end
                            end
                            return "Interface\\Icons\\Spell_Arcane_TeleportStormwind"
                        end
                        return (place and place.icon) or (sample and sample.icon) or 134400
                    end)(),
                    tabName = "Extra buttons",
                    tabIcon = SpellLibrary and SpellLibrary.EXTRA_TAB_ICON,
                    action = {
                        type = "extra",
                        id = (family == "class_teleport" and "classTeleport")
                            or (utilSlot and ("utility" .. utilSlot))
                            or family,
                    },
                    place = {
                        source = utilSlot and "utility" or "extra",
                        role = utilSlot and "utility" or family,
                        slotIndex = utilSlot and tonumber(utilSlot) or nil,
                        binding = place and place.binding,
                        chord = place and place.chord,
                        label = place and place.label,
                        placeId = utilSlot and ("util:" .. utilSlot)
                            or (place and place.binding and ("extra:" .. tostring(place.binding)))
                            or ("extra:" .. family),
                        name = family,
                        icon = place and place.icon,
                    },
                    places = nil,
                    onExtra = true,
                    onActionBar = false,
                    onStance = false,
                    hasBarKey = place and place.chord and place.chord ~= "" and true or false,
                }
                parent.places = { parent.place }
                parents[family] = parent
                out[#out + 1] = parent
            end
            if family:match("^utility:") then
                table.sort(kids, function(a, b)
                    local ka, kb = UtilityChildSortKey(a), UtilityChildSortKey(b)
                    if ka ~= kb then return ka < kb end
                    return (a.name or ""):lower() < (b.name or ""):lower()
                end)
            else
                table.sort(kids, function(a, b)
                    return (a.name or ""):lower() < (b.name or ""):lower()
                end)
            end
            parent.flyoutChildren = kids
            parent.flyoutFamily = family
        end
    end

    return out
end

local function EntryRowHeight(entry)
    local h = ROW_H
    local family = entry and (entry.flyoutFamily or FlyoutFamilyOfEntry(entry))
    if entry and entry.flyoutChildren and family and S.flyoutExpanded[family] then
        h = h + (#entry.flyoutChildren * ROW_H)
    end
    return h
end

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do
        n[k] = DeepCopy(v)
    end
    return n
end

local function IsCustomized(binding)
    local FB = _G.FluxBinding
    if FB and FB.IsBindingCustomized then
        return FB.IsBindingCustomized(binding)
    end
    if type(binding) ~= "table" then return false end
    if binding.key and binding.key ~= "" then return true end
    if binding.stickyRespec then return true end
    return false
end

local function BindingsForAction(desc)
    if not desc or not Action then return {} end
    local key = (Action.FamilyKey and Action.FamilyKey(desc)) or Action.Key(desc)
    if not key or not DB then return {} end
    return DB.UidsForActionKey(key) or {}
end

local function PrimaryBindingForEntry(entry)
    if not entry or not entry.action or not DB then return nil end
    local placeId = entry.place and entry.place.placeId
    local preferChord = entry.place and entry.place.chord
    local family = (Action.FamilyKey and Action.FamilyKey(entry.action)) or Action.Key(entry.action)
    local strict = Action.Key and Action.Key(entry.action)

    if placeId and DB.FindUidForPlace then
        local uid = DB.FindUidForPlace(family, placeId, preferChord)
        if not uid and strict and strict ~= family then
            uid = DB.FindUidForPlace(strict, placeId, preferChord)
        end
        if uid then
            return DB.Get(uid)
        end
        -- Place row with no linked UID yet → unbound for this placement.
        return nil
    end

    local uids = BindingsForAction(entry.action)
    if #uids == 0 then return nil end
    return DB.Get(uids[1])
end

--- Legacy: action-only lookup (no place). Prefer PrimaryBindingForEntry for list rows.
local function PrimaryBinding(desc)
    if type(desc) == "table" and desc.action then
        return PrimaryBindingForEntry(desc)
    end
    local uids = BindingsForAction(desc)
    if #uids == 0 then return nil end
    return DB.Get(uids[1])
end

local function EntryInactiveUntilFlying(entry)
    if not entry or entry.onActionBar then return false end
    local places = entry.places
    if type(places) ~= "table" or #places == 0 then return false end
    local hasFlyingOnly, hasLive = false, false
    for i = 1, #places do
        local p = places[i]
        if p.source == "actionbar" then
            return false
        end
        if p.inactiveUntilFlying then
            hasFlyingOnly = true
        elseif p.chord and p.chord ~= "" then
            hasLive = true
        elseif p.source and p.source ~= "actionbar" and not p.inactiveUntilFlying then
            -- Live Extra place without chord still counts as an active listing
            -- (role placeholders); only pure "bound when flying" rows should gray.
            if p.role ~= "mount_flyout" then
                hasLive = true
            end
        end
    end
    return hasFlyingOnly and not hasLive
end

local function PrettyChordLabel(chord)
    if not chord or chord == "" then return chord end
    local s = tostring(chord)
    s = s:gsub("SHIFT%-", "Shift-"):gsub("CTRL%-", "Ctrl-"):gsub("ALT%-", "Alt-"):gsub("META%-", "Meta-")
    s = s:gsub("STRG%-", "Ctrl-")
    s = s:gsub("S%-", "Shift-"):gsub("C%-", "Ctrl-"):gsub("A%-", "Alt-")
    return s
end

local function EntryIsExtraPlaceholder(entry)
    if not entry then return false end
    if entry.place and entry.place.placeholder then
        return true
    end
    if entry.action and entry.action.type == "extra" then
        local places = entry.places
        if type(places) == "table" then
            for i = 1, #places do
                if places[i].placeholder then
                    return true
                end
            end
        end
        -- Best food/water/… role rows with no owned item.
        local id = tostring(entry.action.id or "")
        if id == "food" or id == "water" or id == "bandage" or id == "healPotion"
            or id == "manaPotion" or id == "healthstone" or id == "manaGem" then
            return true
        end
    end
    return false
end

local function EntryStatus(entry)
    local b = PrimaryBindingForEntry(entry)
    local Placement = ns.FluxBindingPlacement
    local placeLabel = nil
    if entry.place and entry.place.label then
        placeLabel = entry.place.label
    elseif entry.places and Placement and Placement.FormatPlaces then
        placeLabel = Placement.FormatPlaces(entry.places)
    elseif entry.onActionBar and SpellLibrary and SpellLibrary.FormatBarSlots then
        placeLabel = SpellLibrary.FormatBarSlots(entry.barSlots)
    end
    local barChord = (entry.place and entry.place.chord)
        or (entry.places and Placement and Placement.PrimaryChord
            and Placement.PrimaryChord(entry.places))
        or nil

    local status, subtitle, customized
    local fluxKey = b and b.key and b.key ~= "" and b.key or nil
    customized = b and IsCustomized(b) or false

    local abPrefix = L["browser_actionbar_prefix"] or "Action bar"
    local hasActionBarPlace = false
    local hasStancePlace = false
    if entry.place then
        if entry.place.source == "actionbar" then
            hasActionBarPlace = true
        elseif entry.place.source == "stance" then
            hasStancePlace = true
        end
    elseif entry.places then
        for i = 1, #entry.places do
            local src = entry.places[i].source
            if src == "actionbar" then
                hasActionBarPlace = true
            elseif src == "stance" then
                hasStancePlace = true
            end
        end
    end
    hasActionBarPlace = hasActionBarPlace or entry.onActionBar
    hasStancePlace = hasStancePlace or entry.onStance

    -- Empty Extra consumable placeholders: same gray look as unbound / Extra button placeholders.
    if not fluxKey and EntryIsExtraPlaceholder(entry) then
        status = "unbound"
        subtitle = placeLabel or (entry.name or "Best")
        return status, subtitle, customized, entry.onActionBar, entry.onExtra, nil
    end

    -- Flying mount favorites in a non-flyable zone: grayed like unbound, still labeled.
    if not fluxKey and not hasActionBarPlace and not hasStancePlace and EntryInactiveUntilFlying(entry) then
        status = "unbound"
        subtitle = placeLabel or (L["bound_when_flying"] or "bound when flying")
        return status, subtitle, customized, entry.onActionBar, entry.onExtra, nil
    end

    if fluxKey then
        local pretty = PrettyChordLabel(fluxKey)
        status, subtitle = "keyed", pretty
        if placeLabel then
            subtitle = pretty .. " · " .. placeLabel
        end
    elseif placeLabel and (hasActionBarPlace or hasStancePlace) then
        status = (barChord or entry.hasBarKey) and "barkey" or "bar"
        if hasActionBarPlace then
            subtitle = abPrefix .. " · " .. placeLabel
        else
            subtitle = placeLabel
        end
    elseif placeLabel then
        -- Extra / utility only
        status = (barChord or entry.hasBarKey) and "barkey" or "bar"
        subtitle = placeLabel
    else
        -- Not on action bars / Extra / stance: never "Default (no key)" — treat as unbound
        -- (pristine DB stubs are pruned; list must not show a fake default binding).
        status, subtitle = "unbound", L["UNBOUND"] or "UNBOUND"
    end

    return status, subtitle, customized, entry.onActionBar, entry.onExtra, barChord
end

local function PassesFilter(entry)
    local status, _, customized = EntryStatus(entry)
    if S.filter == "unbound" then
        return status == "unbound"
    elseif S.filter == "customized" then
        return customized
    elseif S.filter == "default" then
        -- On bar / Extra / stance with no Flux key and default settings.
        return (status == "bar" or status == "barkey") and not customized
    elseif S.filter == "onbar" then
        return entry.onActionBar or entry.onExtra or entry.onStance or entry.onMultiCast
            or status == "barkey" or status == "bar"
    elseif S.filter == "barkey" then
        local b = PrimaryBindingForEntry(entry)
        return status == "barkey" or (entry.hasBarKey and not (b and b.key))
    end
    return true
end

local function PassesSearch(entry)
    local q = (S.search or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if q == "" then return true end
    local name = (entry.name or ""):lower()
    local _, subtitle = EntryStatus(entry)
    local sub = (subtitle or ""):lower()
    local bar = ""
    if entry.barSlots then
        for i = 1, #entry.barSlots do
            bar = bar .. " " .. tostring(entry.barSlots[i])
        end
    end
    return name:find(q, 1, true) or sub:find(q, 1, true) or bar:find(q, 1, true)
end

--- Respec profile.bars when previewing a profile that saved bars; otherwise nil (= live bars).
local function CurrentBarsSnapshot()
    if S.source == "live" or not S.source then
        return nil
    end
    local R = _G.FluxRespec
    local profile = R and R.GetProfile and R.GetProfile(S.source)
    if profile and type(profile.bars) == "table" and type(profile.bars.slots) == "table" then
        return profile.bars
    end
    return nil
end

--- Respec utility slot assignments (NC spellbook slots); nil = live FluxNCUtilitySlotsDB.
local function CurrentUtilitySnapshot()
    if S.source == "live" or not S.source then
        return nil
    end
    local R = _G.FluxRespec
    local profile = R and R.GetProfile and R.GetProfile(S.source)
    if not profile then return nil end
    if type(profile.utilitySlots) == "table" then
        return profile.utilitySlots
    end
    if type(profile.spellBookSlots) == "table" then
        return profile.spellBookSlots
    end
    return nil
end

local function BarsSourceLabel()
    if S.source ~= "live" and S.source then
        local snap = CurrentBarsSnapshot()
        local util = CurrentUtilitySnapshot()
        local parts = {}
        if snap then
            parts[#parts + 1] = (L["browser_bars_profile"] or "Bars: Respec")
        else
            parts[#parts + 1] = (L["browser_bars_live_fallback"] or "Bars: live (no profile bars)")
        end
        if util then
            parts[#parts + 1] = (L["browser_util_profile"] or "Util: Respec")
        else
            parts[#parts + 1] = (L["browser_util_live"] or "Util/EBS: live")
        end
        return table.concat(parts, " · ")
    end
    return (L["browser_bars_live"] or "Bars + EBS: live")
end

local function EntryIdentity(entry)
    if not entry or not entry.action then return nil end
    local ak = (Action.FamilyKey and Action.FamilyKey(entry.action)) or Action.Key(entry.action)
    if not ak then return nil end
    local place = entry.place
    local pid = place and (place.placeId
        or (ns.FluxBindingPlacement and ns.FluxBindingPlacement.PlaceId
            and ns.FluxBindingPlacement.PlaceId(place)))
    if pid and pid ~= "" then
        return ak .. "|" .. pid
    end
    return ak
end

local function EntryMatchesAction(entry, want, wantStrict)
    if not entry or not entry.action then return false end
    local ek = (Action.FamilyKey and Action.FamilyKey(entry.action)) or Action.Key(entry.action)
    local esk = Action.Key and Action.Key(entry.action)
    if want and ek == want then return true end
    if wantStrict and esk == wantStrict then return true end
    if want and Action.KeysMatch and Action.KeysMatch(entry.action, want) then return true end
    if wantStrict and Action.KeysMatch and Action.KeysMatch(entry.action, wantStrict) then return true end
    return false
end

-- ---------------------------------------------------------------------------
-- Respec preview document override
-- ---------------------------------------------------------------------------

local function ClearPreview()
    if DB.SetDocumentOverride then
        DB.SetDocumentOverride(nil)
    end
    S.previewProfile = nil
    S.source = "live"
end

function Browser.ActivateLiveSource()
    ClearPreview()
end

function Browser.ActivateProfilePreview(profileName)
    local R = _G.FluxRespec
    if not R or not R.GetProfile then
        Browser.ActivateLiveSource()
        return false
    end
    local profile = R.GetProfile(profileName)
    if not profile then
        Browser.ActivateLiveSource()
        return false
    end
    local snap = profile.spellBindings
    local doc
    if type(snap) == "table" and type(snap.doc) == "table" and snap.version == 3 then
        doc = DeepCopy(snap.doc)
    else
        doc = {
            bindings = {},
            chordStackOrder = {},
            badgeCornerOrder = {},
            formPageEnabled = {},
            rankSyncNames = {},
            nextUid = 1,
        }
    end
    -- Ensure nextUid
    local maxUid = 0
    for uid in pairs(doc.bindings or {}) do
        if type(uid) == "number" and uid > maxUid then maxUid = uid end
    end
    doc.nextUid = math.max(tonumber(doc.nextUid) or 1, maxUid + 1)
    if DB.SetDocumentOverride then
        DB.SetDocumentOverride(doc)
    end
    S.source = profileName
    S.previewProfile = profileName
    return true
end

-- Keep local aliases for call sites that still use the short names.
local function ActivateLiveSource()
    return Browser.ActivateLiveSource()
end

local function ActivateProfilePreview(profileName)
    return Browser.ActivateProfilePreview(profileName)
end

function Browser.PersistPreview()
    if not S.previewProfile or not DB.IsOverrideActive or not DB.IsOverrideActive() then
        return
    end
    local R = _G.FluxRespec
    local profile = R and R.GetProfile and R.GetProfile(S.previewProfile)
    if not profile then return end
    local working = DB.GetDocumentOverride()
    if type(working) ~= "table" then return end
    if _G.FluxBinding and _G.FluxBinding.PrunePristineBindings then
        _G.FluxBinding.PrunePristineBindings(working)
    end
    if _G.FluxSpellBindings_CaptureDocSnapshot then
        profile.spellBindings = _G.FluxSpellBindings_CaptureDocSnapshot(working)
    else
        profile.spellBindings = {
            version = 3,
            doc = DeepCopy(working),
        }
    end
    profile.updatedAt = time()
end

_G.FluxBindingBrowser_PersistPreview = Browser.PersistPreview

-- ---------------------------------------------------------------------------
-- Preview note (defined before EnsureMain so dropdown closures are safe).
-- ---------------------------------------------------------------------------

function Browser.UpdatePreviewNote()
    if not S.previewNote then return end
    local barsLine = BarsSourceLabel()
    if S.source ~= "live" then
        S.previewNote:SetText((L["browser_preview_note"]
            or "Preview — edits save to this Respec profile only (not applied live).")
            .. "\n" .. barsLine)
        S.previewNote:SetTextColor(1, 0.75, 0.2)
    else
        S.previewNote:SetText((L["browser_sticky_hint"]
            or "* Sticky across Respec survives Load/Apply")
            .. "\n" .. barsLine)
        S.previewNote:SetTextColor(0.7, 0.7, 0.7)
    end
end

local function UpdatePreviewNote()
    Browser.UpdatePreviewNote()
end

-- ---------------------------------------------------------------------------
-- Window size
-- ---------------------------------------------------------------------------

local function ExpandWindow()
    local FW = _G.FluxWindowFrame
    if not FW or not FW.SetSize then return end
    if not S.savedWindowW then
        local frame = FW.GetFrame and FW:GetFrame()
        if frame then
            S.savedWindowW = frame:GetWidth() or FW.WINDOW_WIDTH or 405
            S.savedWindowH = frame:GetHeight() or FW.WINDOW_HEIGHT or 270
        else
            S.savedWindowW = FW.WINDOW_WIDTH or 405
            S.savedWindowH = FW.WINDOW_HEIGHT or 270
        end
    end
    FW:SetSize(BINDING_W, BINDING_H)
end

local function RestoreWindow()
    local FW = _G.FluxWindowFrame
    if not FW or not FW.SetSize then return end
    if S.savedWindowW and S.savedWindowH then
        FW:SetSize(S.savedWindowW, S.savedWindowH)
        S.savedWindowW = nil
        S.savedWindowH = nil
    end
end

-- ---------------------------------------------------------------------------
-- List UI
-- ---------------------------------------------------------------------------

local function ClearList()
    if S.listContent then
        S.listContent:Hide()
        -- destroy children
        local kids = { S.listContent:GetChildren() }
        for i = 1, #kids do
            kids[i]:Hide()
            kids[i]:SetParent(nil)
        end
    end
end

local function SelectEntry(entry)
    if not entry then return end
    S.selectedKey = EntryIdentity(entry)
    if Editor and Editor.OpenInHost then
        -- Do not create a DB stub until the user binds a key or edits settings.
        Editor.OpenInHost(entry.action, {
            create = false,
            placeId = entry.place and entry.place.placeId,
            preferChord = entry.place and entry.place.chord,
            placeRole = entry.place and entry.place.role,
            placeSource = entry.place and entry.place.source,
        })
    elseif _G.FluxSpellBindingEditor_Open then
        _G.FluxSpellBindingEditor_Open(entry.action, { embeddedHost = S.editorHost })
    end
    Browser.RefreshList()
end

local function MakeRow(parent, entry, y, opts)
    opts = type(opts) == "table" and opts or {}
    local indent = tonumber(opts.indent) or 0
    local status, subtitle, customized = EntryStatus(entry)
    local id = EntryIdentity(entry)
    local selected = id and id == S.selectedKey
    local family = entry.flyoutFamily or FlyoutFamilyOfEntry(entry)
    local hasFlyout = entry.flyoutChildren and #entry.flyoutChildren > 0
    local flyoutOpen = hasFlyout and family and S.flyoutExpanded[family]

    local row = CreateFrame("Button", nil, parent)
    local rowW = (S.listWidth or LIST_W) - 16 - indent
    row:SetSize(math.max(rowW, 40), ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4 + indent, y)
    row:RegisterForClicks("LeftButtonUp")

    -- Clicked OptionsList-style highlight
    local highlight = row:CreateTexture(nil, "BACKGROUND")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(selected and 0.45 or 0)
    row._selHighlight = highlight
    row:SetScript("OnEnter", function(self)
        if not selected then
            highlight:SetAlpha(0.25)
        end
    end)
    row:SetScript("OnLeave", function(self)
        highlight:SetAlpha(selected and 0.45 or 0)
    end)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ROW_ICON, ROW_ICON)
    local leftPad = 2
    if hasFlyout then
        -- Same +/- control as category headers so flyout open/close is obvious.
        local chev = CreateFrame("Button", nil, row)
        chev:SetSize(14, ROW_H)
        chev:SetPoint("LEFT", row, "LEFT", 0, 0)
        chev:RegisterForClicks("LeftButtonUp")
        chev:EnableMouse(true)
        chev:SetFrameLevel((row:GetFrameLevel() or 1) + 5)
        local chevFS = chev:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        chevFS:SetAllPoints()
        chevFS:SetJustifyH("CENTER")
        chevFS:SetText(flyoutOpen and "-" or "+")
        chevFS:SetTextColor(0.85, 0.85, 0.85)
        chev:SetScript("OnClick", function()
            S.flyoutExpanded[family] = not S.flyoutExpanded[family]
            Browser.RefreshList()
        end)
        chev:SetScript("OnEnter", function()
            GameTooltip:SetOwner(chev, "ANCHOR_RIGHT")
            GameTooltip:SetText(flyoutOpen
                and (L["Hide flyout options"] or "Hide flyout options")
                or (L["Show flyout options"] or "Show flyout options"), 1, 1, 1)
            GameTooltip:Show()
            if not selected then
                highlight:SetAlpha(0.25)
            end
        end)
        chev:SetScript("OnLeave", function()
            GameTooltip:Hide()
            highlight:SetAlpha(selected and 0.45 or 0)
        end)
        leftPad = 14
    end
    icon:SetPoint("LEFT", leftPad, 0)
    icon:SetTexture(entry.icon or 134400)
    local grayLikePlaceholder = status == "unbound" and not customized
    if grayLikePlaceholder then
        icon:SetDesaturated(true)
        -- Extra "Best food/…" placeholders match Extra button style (near-black gray).
        if EntryIsExtraPlaceholder(entry) then
            icon:SetVertexColor(0.25, 0.25, 0.25)
        else
            icon:SetVertexColor(0.6, 0.6, 0.6)
        end
    else
        icon:SetDesaturated(false)
        icon:SetVertexColor(1, 1, 1)
    end

    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameFS:SetPoint("TOPLEFT", icon, "TOPRIGHT", 4, 1)
    nameFS:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetWordWrap(false)
    local title = entry.name or "?"
    if hasFlyout then
        title = title .. "  |cff808080(" .. tostring(#entry.flyoutChildren) .. ")|r"
    end
    if grayLikePlaceholder then
        nameFS:SetTextColor(0.55, 0.55, 0.55)
    else
        nameFS:SetTextColor(1, 0.82, 0)
    end
    local b = PrimaryBindingForEntry(entry)
    if b and b.stickyRespec then
        title = title .. " *"
    end
    nameFS:SetText(title)

    local subFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subFS:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 4, 0)
    subFS:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    subFS:SetJustifyH("LEFT")
    subFS:SetWordWrap(false)
    if status == "unbound" then
        subFS:SetTextColor(0.5, 0.5, 0.5)
        -- Keep placement hint (e.g. "bound when flying") when present; else UNBOUND.
        local sub = subtitle
        if not sub or sub == "" or sub == (L["UNBOUND"] or "UNBOUND") then
            sub = L["UNBOUND"] or "UNBOUND"
        end
        subFS:SetText(sub)
    else
        subFS:SetTextColor(0.65, 0.65, 0.65)
        subFS:SetText(subtitle or "")
    end

    row:SetScript("OnClick", function()
        -- Toggle flyout options open/closed when clicking the main Extra button.
        if hasFlyout and family then
            S.flyoutExpanded[family] = not S.flyoutExpanded[family]
        end
        SelectEntry(entry)
    end)

    return -ROW_H
end

local function MakeGroupHeader(parent, groupName, groupIcon, y, count)
    local collapsed = IsGroupCollapsed(groupName)
    local hdr = CreateFrame("Button", nil, parent)
    hdr:SetSize(math.max((S.listWidth or LIST_W) - 12, 40), HEADER_H)
    hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, y)

    local toggle = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toggle:SetPoint("LEFT", 2, 0)
    toggle:SetText(collapsed and "+" or "-")
    toggle:SetWidth(12)

    local icon = hdr:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", toggle, "RIGHT", 2, 0)
    icon:SetTexture(groupIcon or 134400)

    local fs = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    fs:SetPoint("RIGHT", hdr, "RIGHT", -4, 0)
    fs:SetJustifyH("LEFT")
    local displayName = groupName
    if groupName == "Pet" or (SpellLibrary and SpellLibrary.PET_TAB_NAME and groupName == SpellLibrary.PET_TAB_NAME) then
        displayName = L["browser_tab_pet"] or L["Pet"] or groupName
    end
    fs:SetText(string.format("%s (%d)", displayName, count))

    hdr:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight", "ADD")
    hdr:SetScript("OnClick", function()
        S.collapsed[groupName] = not IsGroupCollapsed(groupName)
        Browser.RefreshList()
    end)
    return -HEADER_H
end

-- Extra buttons: fixed category order (Key and ABC), always.
-- hearth → class TP → TP toggle → mounts → vendor → food → water → bandage →
-- heal pot → mana pot → healthstone → mana gem → utility.
local EXTRA_ROLE_RANK = {
    hearth = 10,
    hearth_flyout = 10,
    class_teleport = 20,
    class_teleport_spell = 20,
    class_teleport_toggle = 30,
    mount = 40,
    mount_flyout = 40,
    vendor_mount = 50,
    conjure = 61,
    ritual = 62,
    ritual_modifier = 63,
    utility = 200,
    utility_flyout = 200,
}

local EXTRA_ACTION_ID_RANK = {
    hearth = 10,
    classTeleport = 20,
    classTeleportToggle = 30,
    mount = 40,
    vendorMount = 50,
    food = 60,
    water = 70,
    bandage = 80,
    healPotion = 90,
    manaPotion = 100,
    healthstone = 110,
    manaGem = 120,
    utility1 = 201,
    utility2 = 202,
    utility3 = 203,
    utility4 = 204,
}

local EXTRA_BINDING_RANK = {
    FLUXGRIDHEARTH = 10,
    FLUXCLASS_TELEPORT = 20,
    FLUXMAGE_TOGGLE_TPPT = 30,
    FLUXGRIDSMARTMOUNT = 40,
    FLUXGRIDVENDORMOUNT = 50,
    FLUXGRID_FOOD_OR_RECUP = 60,
    FLUXMAGE_CONJURE_FOOD = 61,
    FLUXMAGE_RITUAL_OF_REFRESHMENT = 62,
    FLUXGRID_WATER_OR_COMBINED = 70,
    FLUXMAGE_CONJURE_WATER = 71,
    FLUXCOMBAT_BANDAGE = 80,
    FLUXCOMBAT_HEALPOT = 90,
    FLUXCOMBAT_MANAPOT = 100,
    FLUXCOMBAT_HEALTHSTONE = 110,
    FLUXCOMBAT_MANAGEM = 120,
    FLUXMAGE_CONJURE_MANAGEM = 121,
}

local function ExtraPlaceRank(place)
    if type(place) ~= "table" then return nil end
    local src = place.source
    if src ~= "extra" and src ~= "utility" then return nil end
    if src == "utility" then
        return 200 + (tonumber(place.slotIndex) or 0)
    end
    local binding = place.binding
    if type(binding) == "string" then
        local utilSlot = binding:match("^FLUXSPELLBOOKSLOT(%d+)$")
        if utilSlot then
            return 200 + (tonumber(utilSlot) or 0)
        end
        if EXTRA_BINDING_RANK[binding] then
            return EXTRA_BINDING_RANK[binding]
        end
    end
    if place.role and EXTRA_ROLE_RANK[place.role] then
        return EXTRA_ROLE_RANK[place.role]
    end
    return 150
end

local function ExtraCategoryRank(entry)
    if not entry then return 9000 end
    local best
    if type(entry.places) == "table" then
        for i = 1, #entry.places do
            local r = ExtraPlaceRank(entry.places[i])
            if r and (not best or r < best) then
                best = r
            end
        end
    end
    if entry.action and entry.action.type == "extra" then
        local id = tostring(entry.action.id or "")
        local r = EXTRA_ACTION_ID_RANK[id]
        if r and (not best or r < best) then
            best = r
        end
    end
    return best or 9000
end

local function SortEntries(entries, groupName)
    local isExtra = (groupName == "Extra buttons")
    table.sort(entries, function(a, b)
        if isExtra then
            local ra, rb = ExtraCategoryRank(a), ExtraCategoryRank(b)
            if ra ~= rb then
                return ra < rb
            end
        end
        if S.sortMode == "key" then
            local _, sa = EntryStatus(a)
            local _, sb = EntryStatus(b)
            sa = (sa or ""):lower()
            sb = (sb or ""):lower()
            -- UNBOUND last in key sort (within the same Extra category)
            local ua = sa == "unbound" or sa:find("unbound", 1, true)
            local ub = sb == "unbound" or sb:find("unbound", 1, true)
            if ua ~= ub then return not ua end
            if sa ~= sb then return sa < sb end
        end
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)
end

--- Select a spell/item in the Binding-tab list (shared-key peer clicks).
--- Clears filter/search and expands the group when needed so the row is visible.
--- opts: optional { placeId, uid, preferChord/key } to pick a specific instance
--- when the action has multiple list rows (two bar slots, Extra + bar, …).
function Browser.SelectAction(action, opts)
    if not action or not S.shown or not SpellLibrary or not Action then
        return false
    end
    opts = type(opts) == "table" and opts or {}
    local wantPlaceId = opts.placeId
    local wantUid = opts.uid
    local wantChord = opts.preferChord or opts.key
    if wantUid and DB and DB.Get and (not wantPlaceId or wantPlaceId == "") then
        local b = DB.Get(wantUid)
        if b then
            wantPlaceId = wantPlaceId or b.placeId
            wantChord = wantChord or b.key
        end
    end
    if type(wantChord) == "string" and wantChord ~= "" then
        local FB = _G.FluxBinding
        if FB and FB.NormalizeChord then
            wantChord = FB.NormalizeChord(wantChord)
        end
    else
        wantChord = nil
    end

    local want = (Action.FamilyKey and Action.FamilyKey(action)) or Action.Key(action)
    local wantStrict = Action.Key and Action.Key(action)
    if not want and not wantStrict then
        return false
    end

    local catalog = SpellLibrary.GetCatalog({
        bars = CurrentBarsSnapshot(),
        utilitySlots = CurrentUtilitySnapshot(),
    })

    local function EntryPlaceId(e)
        local place = e and e.place
        if not place then return nil end
        return place.placeId
            or (ns.FluxBindingPlacement and ns.FluxBindingPlacement.PlaceId
                and ns.FluxBindingPlacement.PlaceId(place))
    end

    local function EntryChord(e)
        local place = e and e.place
        if place and place.chord and place.chord ~= "" then
            return place.chord
        end
        return nil
    end

    -- Score: placeId exact > uid-linked place > chord match > any place > plain.
    local best, bestScore = nil, -1
    for i = 1, #catalog do
        local e = catalog[i]
        if EntryMatchesAction(e, want, wantStrict) then
            local score = e.place and 1 or 0
            local pid = EntryPlaceId(e)
            if wantPlaceId and pid and pid == wantPlaceId then
                score = 100
            elseif wantUid then
                local b = PrimaryBindingForEntry(e)
                if b and b.uid == wantUid then
                    score = 80
                end
            end
            if score < 100 and wantChord then
                local ch = EntryChord(e)
                local FB = _G.FluxBinding
                local nch = ch and FB and FB.NormalizeChord and FB.NormalizeChord(ch) or ch
                if nch and nch == wantChord then
                    score = math.max(score, 60)
                end
            end
            if score > bestScore then
                best, bestScore = e, score
            end
        end
    end
    local match = best
    if not match then
        return false
    end

    if not PassesFilter(match) then
        S.filter = "all"
        if _G.FluxBindingBrowserFilterDD and _G.FluxBindingBrowserFilterDD.FluxSetText then
            _G.FluxBindingBrowserFilterDD:FluxSetText(L["browser_filter_all"] or "All")
        end
    end
    if not PassesSearch(match) then
        S.search = ""
        if _G.FluxBindingBrowserSearch then
            _G.FluxBindingBrowserSearch:SetText("")
        end
    end

    -- Expand the group that owns this entry.
    local filtered = {}
    for i = 1, #catalog do
        local e = catalog[i]
        if PassesFilter(e) and PassesSearch(e) then
            filtered[#filtered + 1] = e
        end
    end
    filtered = NestFlyoutEntries(filtered)

    -- If the match is a flyout child, prefer the nested copy and expand its parent.
    local matchId = EntryIdentity(match)
    for i = 1, #filtered do
        local e = filtered[i]
        if EntryIdentity(e) == matchId then
            match = e
            break
        end
        local kids = e.flyoutChildren
        if kids then
            for k = 1, #kids do
                if EntryIdentity(kids[k]) == matchId
                    or EntryMatchesAction(kids[k], want, wantStrict) then
                    local child = kids[k]
                    local take = true
                    if wantPlaceId then
                        take = EntryPlaceId(child) == wantPlaceId
                    end
                    if take then
                        match = child
                        matchId = EntryIdentity(match)
                        local family = e.flyoutFamily or FlyoutFamilyOfEntry(e)
                        if family then
                            S.flyoutExpanded[family] = true
                        end
                        break
                    end
                end
            end
        end
    end

    local groups, order = SpellLibrary.GroupByTab(filtered)
    local scrollY = 0
    local y = -2
    for _, gName in ipairs(order) do
        local g = groups[gName]
        if g and g.entries then
            SortEntries(g.entries, gName)
            local inGroup = false
            for i = 1, #g.entries do
                local e = g.entries[i]
                if EntryIdentity(e) == matchId then
                    inGroup = true
                    break
                end
                local kids = e.flyoutChildren
                if kids then
                    for k = 1, #kids do
                        if EntryIdentity(kids[k]) == matchId then
                            inGroup = true
                            local family = e.flyoutFamily or FlyoutFamilyOfEntry(e)
                            if family then
                                S.flyoutExpanded[family] = true
                            end
                            break
                        end
                    end
                end
                if inGroup then break end
            end
            if inGroup then
                S.collapsed[gName] = false
            end
            y = y - HEADER_H
            if not IsGroupCollapsed(gName) then
                for i = 1, #g.entries do
                    local e = g.entries[i]
                    if EntryIdentity(e) == matchId then
                        scrollY = -y
                    end
                    y = y - ROW_H
                    local kids = e.flyoutChildren
                    local family = e.flyoutFamily or FlyoutFamilyOfEntry(e)
                    if kids and family and S.flyoutExpanded[family] then
                        for k = 1, #kids do
                            if EntryIdentity(kids[k]) == matchId then
                                scrollY = -y
                            end
                            y = y - ROW_H
                        end
                    end
                end
            end
        end
    end

    SelectEntry(match)

    -- Jump scroll after layout; defer one frame so embed/host resize has settled.
    local wantScrollY = scrollY
    local function ApplyJumpScroll()
        if not S.listScroll or not S.shown then
            return
        end
        if S.listScroll.UpdateScrollChildRect then
            S.listScroll:UpdateScrollChildRect()
        end
        local maxScroll = 0
        if S.listScroll.GetVerticalScrollRange then
            maxScroll = S.listScroll:GetVerticalScrollRange() or 0
        end
        if maxScroll <= 0 or wantScrollY <= 0 then
            S.listScroll:SetVerticalScroll(0)
            return
        end
        local viewH = S.listScroll:GetHeight() or 0
        local target = math.min(maxScroll, math.max(0, wantScrollY - (viewH * 0.35)))
        S.listScroll:SetVerticalScroll(target)
    end
    ApplyJumpScroll()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, ApplyJumpScroll)
    end
    return true
end

_G.FluxBindingBrowser_SelectAction = function(action, opts)
    return Browser.SelectAction(action, opts)
end

--- Queue an open from spellbook / slash until the Options Binding browser is shown.
function Browser.QueueOpenArg(openArg)
    S.pendingOpen = true
    S.pendingOpenArg = openArg
end

--- Apply a queued spellbook/slash open. Returns true if a queue entry was consumed.
function Browser.ConsumePendingOpen()
    if not S.pendingOpen then
        return false
    end
    if not S.shown or not Editor or not Editor.IsEmbedded or not Editor.IsEmbedded() then
        return false
    end
    S.pendingOpen = false
    local arg = S.pendingOpenArg
    S.pendingOpenArg = nil

    if arg == nil or (type(arg) == "table" and arg.pending) then
        Editor.OpenInHost({ pending = true })
        Browser.RefreshList()
        return true
    end

    local desc
    if type(arg) == "table" and arg.type and (arg.id or arg.name) then
        desc = arg
    elseif type(arg) == "table" and (arg.spellID or arg.actionID) then
        desc = Action and Action.FromSpellbookRow and Action.FromSpellbookRow(arg)
    elseif type(arg) == "number" then
        desc = Action and Action.Spell and Action.Spell(arg)
    end

    if desc then
        if Browser.SelectAction(desc) then
            return true
        end
        -- Not in the catalog list — still open in the embedded editor.
        Editor.OpenInHost(desc, { create = false })
        S.selectedKey = (Action.FamilyKey and Action.FamilyKey(desc)) or (Action.Key and Action.Key(desc))
        Browser.RefreshList()
        return true
    end

    Editor.OpenInHost({ pending = true })
    Browser.RefreshList()
    return true
end

function Browser.RefreshList()
    if not S.listContent or not SpellLibrary then return end
    ClearList()

    local catalog = SpellLibrary.GetCatalog({
        bars = CurrentBarsSnapshot(),
        utilitySlots = CurrentUtilitySnapshot(),
    })
    local filtered = {}
    for i = 1, #catalog do
        local e = catalog[i]
        if PassesFilter(e) and PassesSearch(e) then
            filtered[#filtered + 1] = e
        end
    end
    filtered = NestFlyoutEntries(filtered)
    local groups, order = SpellLibrary.GroupByTab(filtered)

    local y = -2
    local totalH = 4
    for _, gName in ipairs(order) do
        local g = groups[gName]
        SortEntries(g.entries, gName)
        totalH = totalH + HEADER_H
        if not IsGroupCollapsed(gName) then
            for i = 1, #g.entries do
                totalH = totalH + EntryRowHeight(g.entries[i])
            end
        end
    end
    S.listContent:SetHeight(math.max(totalH, 1))
    S.listContent:Show()

    for _, gName in ipairs(order) do
        local g = groups[gName]
        -- Count includes nested flyout options so the header stays informative.
        local visibleCount = #g.entries
        for i = 1, #g.entries do
            local kids = g.entries[i].flyoutChildren
            if kids then
                visibleCount = visibleCount + #kids
            end
        end
        y = y + MakeGroupHeader(S.listContent, gName, g.icon, y, visibleCount)
        if not IsGroupCollapsed(gName) then
            for i = 1, #g.entries do
                local entry = g.entries[i]
                y = y + MakeRow(S.listContent, entry, y)
                local family = entry.flyoutFamily or FlyoutFamilyOfEntry(entry)
                if entry.flyoutChildren and family and S.flyoutExpanded[family] then
                    for k = 1, #entry.flyoutChildren do
                        y = y + MakeRow(S.listContent, entry.flyoutChildren[k], y, {
                            indent = FLYOUT_INDENT,
                        })
                    end
                end
            end
        end
    end

    if S.listScroll and S.listScroll.UpdateScrollChildRect then
        S.listScroll:UpdateScrollChildRect()
    end
    ClampListScroll()
    if S.sortBtn then
        S.sortBtn:SetText(S.sortMode == "key" and (L["browser_sort_key"] or "Key")
            or (L["browser_sort_abc"] or "ABC"))
    end
end

_G.FluxBindingBrowser_Refresh = function()
    if S.shown then Browser.RefreshList() end
end

_G.FluxBindingBrowser_OnEditorCommit = function()
    if S.shown then Browser.RefreshList() end
end

-- ---------------------------------------------------------------------------
-- Layout
-- ---------------------------------------------------------------------------

local function EnsureMain(parent)
    if S.main then
        S.main:SetParent(parent)
        S.main:ClearAllPoints()
        S.main:SetAllPoints(parent)
        return S.main
    end

    local main = CreateFrame("Frame", "FluxBindingBrowserFrame", parent)
    main:SetAllPoints(parent)

    -- Top toolbar
    local toolbar = CreateFrame("Frame", nil, main)
    toolbar:SetPoint("TOPLEFT", 4, -4)
    toolbar:SetPoint("TOPRIGHT", -4, -4)
    toolbar:SetHeight(48)

    local sourceLabel = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceLabel:SetPoint("TOPLEFT", 0, 0)
    sourceLabel:SetText(L["browser_source"] or "Bindings source")

    local sourceDD = _G.FluxBlizzardDropdown.Create(toolbar, "FluxBindingBrowserSourceDD", 180)
    sourceDD:SetPoint("TOPLEFT", sourceLabel, "BOTTOMLEFT", 0, -2)

    local function RefreshSourceDD()
        sourceDD:FluxSetMenu(function()
            local list = { { value = "live", text = L["browser_live"] or "Live (current)" } }
            local R = _G.FluxRespec
            if R and R.GetProfileNames then
                local names = R.GetProfileNames()
                for i = 1, #names do
                    list[#list + 1] = { value = names[i], text = names[i] }
                end
            end
            local entries = {}
            for i = 1, #list do
                local entry = list[i]
                entries[#entries + 1] = {
                    text = entry.text,
                    checked = (S.source == entry.value),
                    func = function()
                        local v = entry.value
                        if v == "live" then
                            Browser.ActivateLiveSource()
                        else
                            Browser.ActivateProfilePreview(v)
                        end
                        sourceDD:FluxSetText(entry.text)
                        Browser.UpdatePreviewNote()
                        if Browser.RefreshList then
                            Browser.RefreshList()
                        end
                        if Editor and Editor.OpenInHost then
                            if S.selectedKey and Editor.S and Editor.S.subject then
                                Editor.OpenInHost(Editor.S.subject)
                            else
                                Editor.OpenInHost({ pending = true })
                            end
                        end
                    end,
                }
            end
            return entries
        end)
        local label = (S.source == "live") and (L["browser_live"] or "Live (current)") or tostring(S.source)
        sourceDD:FluxSetText(label)
    end
    S.refreshSourceDD = RefreshSourceDD
    RefreshSourceDD()

    -- Filter dropdown
    local filterDD = _G.FluxBlizzardDropdown.Create(toolbar, "FluxBindingBrowserFilterDD", 160)
    filterDD:SetPoint("LEFT", sourceDD, "RIGHT", 8, 0)
    local filters = {
        { value = "all", text = L["browser_filter_all"] or "All" },
        { value = "unbound", text = L["browser_filter_unbound"] or "Unbound" },
        { value = "barkey", text = L["browser_filter_barkey"] or "Bar / EBS key only" },
        { value = "default", text = L["browser_filter_default"] or "Default" },
        { value = "customized", text = L["browser_filter_customized"] or "Customized" },
        { value = "onbar", text = L["browser_filter_onbar"] or "On bar / Stance / Extra" },
    }
    filterDD:FluxSetMenu(function()
        local entries = {}
        for i = 1, #filters do
            local entry = filters[i]
            entries[#entries + 1] = {
                text = entry.text,
                checked = (S.filter == entry.value),
                func = function()
                    S.filter = entry.value
                    filterDD:FluxSetText(entry.text)
                    Browser.RefreshList()
                end,
            }
        end
        return entries
    end)
    filterDD:FluxSetText(filters[1].text)

    -- Search
    local search = CreateFrame("EditBox", "FluxBindingBrowserSearch", toolbar, "InputBoxTemplate")
    search:SetSize(120, 20)
    search:SetPoint("LEFT", filterDD, "RIGHT", 8, 2)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self)
        S.search = self:GetText() or ""
        Browser.RefreshList()
    end)
    search:SetScript("OnEditFocusGained", function(self)
        if self.hint then self.hint:Hide() end
    end)
    search:SetScript("OnEditFocusLost", function(self)
        if self.hint and (self:GetText() or "") == "" then
            self.hint:Show()
        end
    end)
    local searchHint = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", 8, 0)
    searchHint:SetText(L["browser_search"] or "Search...")
    search.hint = searchHint

    -- Clicked-style Key / ABC sort toggle
    local sortBtn = CreateFrame("Button", "FluxBindingBrowserSortBtn", toolbar, "UIPanelButtonTemplate")
    sortBtn:SetSize(48, 22)
    sortBtn:SetPoint("LEFT", search, "RIGHT", 6, 0)
    sortBtn:SetText(L["browser_sort_abc"] or "ABC")
    sortBtn:SetScript("OnClick", function()
        S.sortMode = (S.sortMode == "name") and "key" or "name"
        Browser.RefreshList()
    end)
    S.sortBtn = sortBtn

    local vizBtn = CreateFrame("Button", "FluxBindingBrowserVizBtn", toolbar, "UIPanelButtonTemplate")
    vizBtn:SetSize(120, 22)
    vizBtn:SetPoint("LEFT", sortBtn, "RIGHT", 6, 0)
    vizBtn:SetText(L["browser_show_on_keyboard"] or "Show on keyboard")
    vizBtn:SetScript("OnClick", function()
        local KV = _G.FluxKeyVisualizer
        if KV and KV.Open then
            KV:Open()
        end
    end)
    S.vizBtn = vizBtn

    local previewNote = toolbar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    previewNote:SetPoint("TOPRIGHT", 0, -4)
    previewNote:SetJustifyH("RIGHT")
    previewNote:SetText("")
    S.previewNote = previewNote

    -- Left list
    local listBorder = CreateFrame("Frame", nil, main, "BackdropTemplate")
    listBorder:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -4)
    listBorder:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", 4, 4)
    local initialListW = S.listWidth or LIST_W
    listBorder:SetWidth(initialListW)
    if listBorder.SetBackdrop then
        listBorder:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        listBorder:SetBackdropColor(0, 0, 0, 0.35)
        listBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end

    local scroll = CreateFrame("ScrollFrame", "FluxBindingBrowserListScroll", listBorder, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -26, 4)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(math.max(initialListW - 30, 50), 1)
    scroll:SetScrollChild(content)

    -- Prefer catalog list scroll; when at end/range 0, forward to Ace outer.
    local function onListWheel(_, delta)
        if ScrollListByDelta(delta) then
            return
        end
        ForwardWheelToAceOuter(delta)
    end
    scroll:EnableMouse(true)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", onListWheel)
    listBorder:EnableMouse(true)
    listBorder:EnableMouseWheel(true)
    listBorder:SetScript("OnMouseWheel", onListWheel)

    S.listBorder = listBorder
    S.listScroll = scroll
    S.listContent = content

    -- Right editor host (accepts spell/item/macro drag-drop into the Binding editor).
    local editorHost = CreateFrame("Frame", "FluxBindingBrowserEditorHost", main)
    editorHost:SetPoint("TOPLEFT", listBorder, "TOPRIGHT", 6, 0)
    editorHost:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -4, 4)
    editorHost:EnableMouse(true)
    editorHost:EnableMouseWheel(true)
    editorHost:SetScript("OnReceiveDrag", function()
        if Editor and Editor.AcceptCursorSubject then
            Editor.AcceptCursorSubject()
        end
    end)
    editorHost:SetScript("OnMouseUp", function()
        if GetCursorInfo and GetCursorInfo() and Editor and Editor.AcceptCursorSubject then
            Editor.AcceptCursorSubject()
        end
    end)
    -- Prefer Cast/Targets/… tab scroll; avoid Ace outer yanking the pane up/down.
    editorHost:SetScript("OnMouseWheel", function(_, delta)
        if Browser.TryTabMouseWheel and Browser.TryTabMouseWheel(delta) then
            return
        end
    end)
    S.editorHost = editorHost

    S.main = main
    S.toolbar = toolbar
    return main
end

-- ---------------------------------------------------------------------------
-- Layout / show / hide
-- ---------------------------------------------------------------------------

-- Refresh live bar / Extra / stance occupancy while the browser is open.
local barWatcher

local function ScheduleBrowserRefresh(invalidateMount)
    if not S.shown then return end
    if invalidateMount then
        if _G.FluxNCMountItems and _G.FluxNCMountItems.InvalidateCache then
            _G.FluxNCMountItems.InvalidateCache()
        elseif _G.FluxNCMountItems and _G.FluxNCMountItems.InvalidateFavoriteMap then
            _G.FluxNCMountItems.InvalidateFavoriteMap()
        end
    end
    if Browser._barRefreshPending then return end
    Browser._barRefreshPending = true
    C_Timer.After(0.15, function()
        Browser._barRefreshPending = false
        if S.shown then
            -- Purge default unbound DB stubs (no Flux key, no customization).
            -- Catalog still shows live bar / Extra / stance places.
            local Editor = ns.FluxBindingEditor
            if Editor and Editor.PruneOrphans then
                pcall(Editor.PruneOrphans, { dropCurrentIfOrphan = true })
            elseif _G.FluxBinding and _G.FluxBinding.PrunePristineBindings then
                pcall(_G.FluxBinding.PrunePristineBindings)
            end
            Browser.RefreshList()
            if Editor and Editor.IsEmbedded and Editor.IsEmbedded() and Editor.Redraw then
                Editor.Redraw()
            end
        end
    end)
end

local function EnsureBarWatcher()
    if barWatcher then return end
    barWatcher = CreateFrame("Frame")
    barWatcher:SetScript("OnEvent", function(_, event, unit)
        if not S.shown then return end
        if event == "UPDATE_BINDINGS"
            and _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        if event == "UNIT_PET" and unit and unit ~= "player" then
            return
        end
        if event == "UNIT_PET" or event == "PET_BAR_UPDATE" or event == "PET_BAR_UPDATE_COOLDOWN"
            or event == "SPELLS_CHANGED" then
            local Lib = ns.FluxBindingSpellLibrary
            if Lib and Lib.InvalidatePetAbilityGate then
                Lib.InvalidatePetAbilityGate()
            end
        end
        if S.source ~= "live" and CurrentBarsSnapshot() then
            -- Still refresh Extra/stance when bags/toggles change (those are always live).
            if event ~= "BAG_UPDATE" and event ~= "PLAYER_EQUIPMENT_CHANGED"
                and event ~= "ZONE_CHANGED" and event ~= "ZONE_CHANGED_INDOORS"
                and event ~= "ZONE_CHANGED_NEW_AREA" and event ~= "PLAYER_ENTERING_WORLD"
                and event ~= "SPELLS_CHANGED" and event ~= "UPDATE_BINDINGS"
                and event ~= "UNIT_PET" and event ~= "PET_BAR_UPDATE"
                and event ~= "PET_BAR_UPDATE_COOLDOWN" then
                return
            end
        end
        local bagLike = (event == "BAG_UPDATE" or event == "ZONE_CHANGED"
            or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA"
            or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_EQUIPMENT_CHANGED")
        ScheduleBrowserRefresh(bagLike)
    end)
end

local function EnsureExtraUpdateListeners()
    if Browser._extraListenersHooked then return end
    Browser._extraListenersHooked = true

    local function onExtraPulse()
        ScheduleBrowserRefresh(true)
    end

    -- Bags / consumable best-item changes → Extra food/water/pots/HS/gem rows.
    if _G.FluxInv and _G.FluxInv.RegisterListener then
        pcall(_G.FluxInv.RegisterListener, "FluxBindingBrowser", onExtraPulse, {
            tier = "scan",
            regions = { "bags" },
        })
    end
    if _G.FluxConsumableBest and _G.FluxConsumableBest.RegisterListener then
        pcall(_G.FluxConsumableBest.RegisterListener, "FluxBindingBrowser", onExtraPulse)
    end

    -- Mount / hearth / teleport config + mode toggles.
    if _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.RegisterListener then
        pcall(_G.FluxSmartMountConfig.RegisterListener, onExtraPulse)
    end
    if _G.FluxHearthConfig and _G.FluxHearthConfig.RegisterListener then
        pcall(_G.FluxHearthConfig.RegisterListener, onExtraPulse)
    end
    if _G.FluxSmartHearthConfig and _G.FluxSmartHearthConfig.RegisterListener then
        pcall(_G.FluxSmartHearthConfig.RegisterListener, onExtraPulse)
    end

    -- Mode toggles that don't always go through config listeners.
    if not Browser._extraToggleHooks then
        Browser._extraToggleHooks = true
        if _G.FluxNCMount and _G.FluxNCMount.ToggleMode then
            hooksecurefunc(_G.FluxNCMount, "ToggleMode", onExtraPulse)
        end
        if _G.FluxNCTeleportPortal and _G.FluxNCTeleportPortal.ToggleMode then
            hooksecurefunc(_G.FluxNCTeleportPortal, "ToggleMode", onExtraPulse)
        end
        if _G.FluxNCHearthstone and _G.FluxNCHearthstone.ToggleMode then
            hooksecurefunc(_G.FluxNCHearthstone, "ToggleMode", onExtraPulse)
        end
    end

    -- Flyout favorites (mount / hearth / teleport / class TP).
    if not Browser._favListener and _G.FluxFlyoutFavorites and _G.FluxFlyoutFavorites.RegisterListener then
        Browser._favListener = onExtraPulse
        pcall(_G.FluxFlyoutFavorites.RegisterListener, Browser._favListener)
    end
end

local function SetBarWatcherEnabled(on)
    EnsureBarWatcher()
    if on then
        barWatcher:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        barWatcher:RegisterEvent("UPDATE_MACROS")
        barWatcher:RegisterEvent("UPDATE_BINDINGS")
        barWatcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        barWatcher:RegisterEvent("BAG_UPDATE")
        pcall(barWatcher.RegisterEvent, barWatcher, "PLAYER_ENTERING_WORLD")
        pcall(barWatcher.RegisterEvent, barWatcher, "ZONE_CHANGED")
        pcall(barWatcher.RegisterEvent, barWatcher, "ZONE_CHANGED_INDOORS")
        pcall(barWatcher.RegisterEvent, barWatcher, "ZONE_CHANGED_NEW_AREA")
        pcall(barWatcher.RegisterEvent, barWatcher, "SPELLS_CHANGED")
        pcall(barWatcher.RegisterEvent, barWatcher, "UPDATE_SHAPESHIFT_FORMS")
        pcall(barWatcher.RegisterEvent, barWatcher, "UPDATE_SHAPESHIFT_FORM")
        pcall(barWatcher.RegisterEvent, barWatcher, "UNIT_PET")
        pcall(barWatcher.RegisterEvent, barWatcher, "PET_BAR_UPDATE")
        pcall(barWatcher.RegisterEvent, barWatcher, "PET_BAR_UPDATE_COOLDOWN")
        EnsureExtraUpdateListeners()
    else
        barWatcher:UnregisterAllEvents()
    end
end

--- hostMode: "options" (FluxUI Options tab) or "window" (FluxWindowFrame; expands size).
function Browser.Show(parentOrTab, hostMode)
    local parent = parentOrTab
    if type(parentOrTab) == "table" and parentOrTab.content then
        parent = parentOrTab.content
    end
    if not parent then
        parent = _G.FluxWindowFrame and _G.FluxWindowFrame:GetContentFrame()
    end
    if not parent then return end

    S.shown = true
    S.hostMode = hostMode or S.hostMode or "options"
    if S.hostMode == "window" then
        ExpandWindow()
    end
    -- Strip pristine unbound stubs from live (or preview) doc once per open.
    local Editor = ns.FluxBindingEditor
    if Editor and Editor.PruneOrphans then
        pcall(Editor.PruneOrphans, { keepCurrent = false })
    elseif _G.FluxBinding and _G.FluxBinding.PrunePristineBindings then
        pcall(_G.FluxBinding.PrunePristineBindings)
    end

    local main = EnsureMain(parent)
    main:Show()
    if S.refreshSourceDD then S.refreshSourceDD() end
    UpdatePreviewNote()
    if Editor and S.editorHost then
        Editor.AttachHost(S.editorHost)
        if not Browser.ConsumePendingOpen() then
            if not Editor.S.subject then
                Editor.OpenInHost({ pending = true })
            else
                Editor.Redraw()
            end
            Browser.RefreshList()
        end
        -- ConsumePendingOpen / SelectAction already refresh when they succeed.
    else
        Browser.RefreshList()
    end
    SetBarWatcherEnabled(true)
end

function Browser.Hide()
    if not S.shown then return end
    S.shown = false
    SetBarWatcherEnabled(false)
    -- Drop unbound drafts (Add binding / never keyed) so they are not saved.
    local Editor = ns.FluxBindingEditor
    if Editor and Editor.PruneOrphans then
        pcall(Editor.PruneOrphans, { keepCurrent = false })
    elseif _G.FluxBinding and _G.FluxBinding.PrunePristineBindings then
        pcall(_G.FluxBinding.PrunePristineBindings)
    end
    if S.source ~= "live" then
        Browser.PersistPreview()
        ClearPreview()
    end
    if Editor and Editor.DetachHost then
        Editor.DetachHost()
    end
    if S.main then
        S.main:Hide()
    end
    if S.hostMode == "window" then
        RestoreWindow()
    end
end

--- AceGUI dialogControl attach (FluxUI Options → Binding tab).
function Browser.AttachToAceWidget(widget)
    if not widget or not widget.frame then return end
    S.hostMode = "options"
    S.embedWidget = widget
    -- Prefer slim catalog until host kind is known (Blizzard is the tight case).
    if not S.listWidth or S.listWidth > LIST_W_BLIZ then
        S.listWidth = LIST_W_BLIZ
        if S.listBorder then
            S.listBorder:SetWidth(LIST_W_BLIZ)
        end
    end
    Browser.Show(widget.frame, "options")
    Browser.FitToHost()
    if widget.frame and not widget.frame._fluxBindSizeHooked then
        widget.frame._fluxBindSizeHooked = true
        widget.frame:HookScript("OnSizeChanged", function(f, width, height)
            if S.embedWidget and S.embedWidget.frame == f and S.shown then
                Browser.OnHostResized(width, height, {
                    blizzard = S.hostBlizzard or (S.embedWidget and S.embedWidget._fluxBindBlizzard),
                })
            end
        end)
    end
end

--- Size browser + editor to the current embed / options window content box.
function Browser.FitToHost()
    local host = S.embedWidget and S.embedWidget.frame or (S.main and S.main:GetParent())
    if not host then return end
    local w = host:GetWidth() or 0
    local h = host:GetHeight() or 0
    if S.main then
        S.main:ClearAllPoints()
        S.main:SetAllPoints(host)
        S.main:Show()
    end
    if w > 0 and h > 0 then
        Browser.OnHostResized(w, h, {
            blizzard = S.hostBlizzard or (S.embedWidget and S.embedWidget._fluxBindBlizzard),
        })
    end
end

function Browser.OnHostResized(w, h, opts)
    opts = type(opts) == "table" and opts or {}
    w = tonumber(w) or 0
    h = tonumber(h) or 0
    S.hostBlizzard = opts.blizzard and true or false

    if S.main and S.main:IsShown() then
        local host = S.main:GetParent()
        if host then
            S.main:ClearAllPoints()
            S.main:SetAllPoints(host)
        end
    end

    -- Slim catalog in Blizzard Settings; wider in /fluxui.
    local wantList = EffectiveListWidth(w, { blizzard = S.hostBlizzard })
    local listChanged = S.listBorder and wantList ~= (S.listWidth or 0)
    if S.listBorder then
        S.listWidth = wantList
        S.listBorder:SetWidth(wantList)
        if S.listContent then
            S.listContent:SetWidth(math.max(wantList - 30, 50))
        end
        if listChanged and S.shown and Browser.RefreshList then
            Browser.RefreshList()
        end
    else
        S.listWidth = wantList
    end

    if S.editorHost and Editor then
        local root = Editor.S and Editor.S.embedRoot
        if root and root.frame then
            root.frame:SetParent(S.editorHost)
            root.frame:ClearAllPoints()
            root.frame:SetAllPoints(S.editorHost)
            local ew = S.editorHost:GetWidth() or 0
            local eh = S.editorHost:GetHeight() or 0
            if ew > 0 and eh > 0 then
                if root.SetWidth then root:SetWidth(ew) end
                if root.SetHeight then root:SetHeight(eh) end
                if root.content then
                    root.content:SetWidth(ew)
                    root.content:SetHeight(eh)
                end
                if root.DoLayout then root:DoLayout() end
            end
        elseif Editor.AttachHost then
            Editor.AttachHost(S.editorHost)
        end
    end
    if S.listContent and S.shown then
        local listW = (S.listScroll and S.listScroll:GetWidth()) or 0
        if listW > 20 then
            S.listContent:SetWidth(math.max(listW - 4, 50))
        end
        if S.listScroll and S.listScroll.UpdateScrollChildRect then
            S.listScroll:UpdateScrollChildRect()
        end
        ClampListScroll()
    end
end

function Browser.DetachFromAceWidget(widget)
    S.embedWidget = nil
    Browser.Hide()
end

_G.FluxBindingBrowser_Attach = function(widget)
    Browser.AttachToAceWidget(widget)
end

_G.FluxBindingBrowser_Detach = function(widget)
    Browser.DetachFromAceWidget(widget)
end

_G.FluxBindingBrowser_OnHostResized = function(w, h, opts)
    Browser.OnHostResized(w, h, opts)
end

function Browser.IsShown()
    return S.shown
end

-- Optional: still available if something calls AddTab manually (not auto-registered).
function Browser.AddTab()
    if not _G.FluxWindowFrame or not _G.FluxWindowFrame.AddTab then return end
    if _G.FluxWindowFrame.GetTabContent and _G.FluxWindowFrame:GetTabContent("Binding") then
        return
    end
    _G.FluxWindowFrame:AddTab("Binding", function(tab)
        Browser.Show(tab, "window")
    end, function()
        Browser.Hide()
    end,
    "Spell & item bindings\nBrowse all class spells by school, edit keys, preview Respec profiles.")
end
