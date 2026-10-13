-- Binding/UI/Editor/Core.lua
-- Editor session state, window shell, open/close, commit + redraw.
-- Same UX skeleton as the old EditorV2 (toolbar / form strip / tabs), wired to
-- the single FluxBindingDB3 document: widget change -> doc -> Commit(uid) ->
-- chord-scoped apply -> status refresh.

local addonName, ns = ...

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI then return end

local Editor = {}
ns.FluxBindingEditor = Editor
_G.FluxBindingEditor3 = Editor

local DB = ns.FluxBindingDB3
local Action = ns.FluxBindingAction
local Forms = ns.FluxBindingForms

local L = _G.FluxSpellBindingLocale or setmetatable({}, { __index = function(_, k) return k end })
Editor.L = L

-- ---------------------------------------------------------------------------
-- Session state
-- ---------------------------------------------------------------------------

local S = {
    win = nil,            -- FluxBindingFrame widget (standalone)
    embedRoot = nil,      -- AceGUI SimpleGroup when hosted in Binding browser
    hostFrame = nil,      -- native parent frame for embed mode
    subject = nil,        -- action descriptor
    subjectKey = nil,     -- Action.Key(subject)
    uids = {},            -- binding instances for the subject
    currentUid = nil,
    formToken = "noform",
    currentTab = "cast",
    tabScroll = nil,      -- AceGUI ScrollFrame inside active Cast/Targets/… tab
    pending = false,      -- waiting for a drag-in subject
    embedded = false,     -- true when hosted inside FluxWindow Binding tab
    placeId = nil,        -- Clicked-style placement id for current row
    preferChord = nil,
    placeRole = nil,      -- Placement.role (use / mount / utility / …)
    placeSource = nil,    -- actionbar | extra | utility | stance
}
Editor.S = S

function Editor.IsEmbedded()
    return S.embedded and S.hostFrame ~= nil
end

local CONSUMABLE_EXTRA_IDS = {
    food = true,
    water = true,
    bandage = true,
    healPotion = true,
    manaPotion = true,
    healthstone = true,
    manaGem = true,
}

local CONSUMABLE_ROLES = {
    use = true,
    conjure = true,
    ritual = true,
    ritual_modifier = true,
}

local CONSUMABLE_BINDINGS = {
    FLUXGRID_FOOD_OR_RECUP = true,
    FLUXGRID_WATER_OR_COMBINED = true,
    FLUXCOMBAT_BANDAGE = true,
    FLUXCOMBAT_HEALPOT = true,
    FLUXCOMBAT_MANAPOT = true,
    FLUXCOMBAT_HEALTHSTONE = true,
    FLUXCOMBAT_MANAGEM = true,
    FLUXMAGE_CONJURE_FOOD = true,
    FLUXMAGE_CONJURE_WATER = true,
    FLUXMAGE_RITUAL_OF_REFRESHMENT = true,
    FLUXMAGE_CONJURE_MANAGEM = true,
}

function Editor.IsStancePlace()
    local pid = S.placeId
    if type(pid) == "string" and pid:match("^stance:") then
        return true
    end
    return S.placeSource == "stance"
end

function Editor.IsUtilityPlace()
    local pid = S.placeId
    if type(pid) == "string" and pid:match("^util:") then
        return true
    end
    return S.placeSource == "utility"
        or S.placeRole == "utility"
        or S.placeRole == "utility_flyout"
end

function Editor.IsConsumableExtraPlace()
    if S.placeRole and CONSUMABLE_ROLES[S.placeRole] then
        return true
    end
    if S.subject and S.subject.type == "extra" then
        if CONSUMABLE_EXTRA_IDS[tostring(S.subject.id or "")] then
            return true
        end
    end
    local pid = S.placeId
    if type(pid) == "string" then
        for bind in pairs(CONSUMABLE_BINDINGS) do
            if pid:find(bind, 1, true) then
                return true
            end
        end
    end
    return false
end

--- Extra button place (not Utility). Includes mount/hearth/teleport and consumables.
function Editor.IsExtraButtonPlace()
    if Editor.IsUtilityPlace() then
        return false
    end
    if S.placeSource == "extra" then
        return true
    end
    local pid = S.placeId
    if type(pid) == "string" and (pid:match("^extra:") or pid:match("^bind:")) then
        return true
    end
    if S.subject and S.subject.type == "extra" then
        return true
    end
    return false
end

--- Cast / Targets / Conditions / Forms / Status / Badges — action bars, Utility,
--- and Extra consumables (food/water/bandage/pots/stones/gems). Not stance or
--- other Extra buttons (mount/hearth/teleport).
function Editor.SupportsBindingTabs()
    if Editor.IsStancePlace() then
        return false
    end
    if Editor.IsUtilityPlace() then
        return true
    end
    if Editor.IsConsumableExtraPlace() then
        return true
    end
    if Editor.IsExtraButtonPlace() then
        return false
    end
    return true
end

--- Add binding / Remove / instance dropdown — not for Extra or stance.
function Editor.SupportsBindingInstances()
    if Editor.IsStancePlace() or Editor.IsExtraButtonPlace() then
        return false
    end
    return true
end

--- Key capture row — action bars + Utility. Extra/stance keys live in Bindings.xml.
function Editor.SupportsKeyEditor()
    if Editor.IsStancePlace() or Editor.IsExtraButtonPlace() then
        return false
    end
    return true
end

--- Notify Binding browser list to refresh after commits.
local function NotifyBrowser()
    if _G.FluxBindingBrowser_OnEditorCommit then
        pcall(_G.FluxBindingBrowser_OnEditorCommit)
    end
end

function Editor.GetBinding()
    return S.currentUid and DB.Get(S.currentUid) or nil
end

--- Sub-profile currently being edited (dedicated for the form, else noform).
--- Off-bar unbound spells use an ephemeral sub until the user actually edits
--- (no "Default (no key)" DB stub).
function Editor.GetSub()
    local b = Editor.GetBinding()
    if not b then
        if not S._ephemeralSub and DB.NewFormSubProfile then
            S._ephemeralSub = DB.NewFormSubProfile()
        end
        return S._ephemeralSub
    end
    S._ephemeralSub = nil
    return DB.GetFormSub(b, S.formToken)
end

--- Create the dedicated per-form sub on first edit (deep-copies noform).
function Editor.EnsureEditableSub()
    local b = Editor.GetBinding() or (Editor.EnsureBindingRow and Editor.EnsureBindingRow())
    if not b then return nil end
    S._ephemeralSub = nil
    if S.formToken == "noform" then
        return DB.EnsureFormSub(b, "noform")
    end
    if not DB.HasDedicatedFormSub(b, S.formToken) then
        local src = b.forms and b.forms.noform
        local copy = (DB.DeepCopyFormSub and DB.DeepCopyFormSub(src)) or DB.NewFormSubProfile()
        copy.active = true -- editing this form activates it (V10 Forms tab parity)
        if type(b.forms) ~= "table" then b.forms = {} end
        b.forms[S.formToken] = copy
    end
    return DB.EnsureFormSub(b, S.formToken)
end

-- ---------------------------------------------------------------------------
-- Commit + redraw
-- ---------------------------------------------------------------------------

local redrawScheduled = false

function Editor.Redraw()
    local root = Editor.GetContentRoot()
    if not root or not root.frame or not root.frame:IsShown() then return end
    if redrawScheduled then return end
    redrawScheduled = true
    C_Timer.After(0, function()
        redrawScheduled = false
        root = Editor.GetContentRoot()
        if root and root.frame and root.frame:IsShown() then
            Editor.Rebuild()
        end
    end)
end

function Editor.Commit()
    local FluxBinding = _G.FluxBinding
    if FluxBinding and FluxBinding.NotifyBindingChanged then
        FluxBinding.NotifyBindingChanged(S.currentUid)
    end
    if DB.IsOverrideActive and DB.IsOverrideActive() and _G.FluxBindingBrowser_PersistPreview then
        pcall(_G.FluxBindingBrowser_PersistPreview)
    end
    -- Protect Add-binding drafts and live place stubs while editing. Pristine
    -- rows with no bar / Extra / stance place are always dropped (no
    -- "Default (no key)" leftovers for unbound spellbook spells).
    local keepUid = S.currentUid
    local b = keepUid and DB.Get(keepUid)
    if b and FluxBinding and FluxBinding.IsBindingRespecRelevant
        and not FluxBinding.IsBindingRespecRelevant(b) then
        local pid = b.placeId
        local isDraft = type(pid) == "string" and pid:match("^inst:")
        local hasPlace = FluxBinding.BindingHasLivePlace and FluxBinding.BindingHasLivePlace(b)
        if not isDraft and not hasPlace then
            keepUid = nil
        end
    end
    if FluxBinding and FluxBinding.PrunePristineBindings then
        pcall(FluxBinding.PrunePristineBindings, nil, { keepUid = keepUid })
    end
    Editor.SyncAfterPrune()
    Editor.Redraw()
    NotifyBrowser()
end

--- After prune: if the active row was removed, reset to not-bound / place-inherited.
function Editor.SyncAfterPrune()
    if S.currentUid and DB.Get(S.currentUid) then
        S.uids = S.subjectKey and DB.UidsForActionKey(S.subjectKey) or { S.currentUid }
        return
    end
    local lost = S.currentUid ~= nil
    local keptPlaceId = S.placeId
    S.currentUid = nil
    S.uids = S.subjectKey and DB.UidsForActionKey(S.subjectKey) or {}
    if #S.uids > 0 then
        S.currentUid = S.uids[1]
        local b = DB.Get(S.currentUid)
        S.placeId = b and b.placeId or S.placeId
        return
    end
    -- No DB row left — clear draft placeIds; keep real bar/Extra placeIds when still live.
    if keptPlaceId and tostring(keptPlaceId):match("^inst:") then
        S.placeId = nil
        S.preferChord = nil
        return
    end
    if lost and keptPlaceId and not tostring(keptPlaceId):match("^inst:") then
        local Placement = ns.FluxBindingPlacement
        local chord = Placement and Placement.ChordForPlaceId and Placement.ChordForPlaceId(keptPlaceId)
        if chord and chord ~= "" then
            S.placeId = keptPlaceId
            S.preferChord = chord
            return
        end
    end
    -- Orphan: nothing in DB and no live place → fully not-bound.
    local FluxBinding = _G.FluxBinding
    local hasPlace = false
    if S.subject and FluxBinding and FluxBinding.BindingHasLivePlace then
        hasPlace = FluxBinding.BindingHasLivePlace({
            action = S.subject,
            placeId = keptPlaceId,
        })
    elseif Editor.SubjectHasPhysicalPlace and Editor.SubjectHasPhysicalPlace() then
        hasPlace = true
    end
    if not hasPlace then
        S.placeId = nil
        S.preferChord = nil
    elseif keptPlaceId and not tostring(keptPlaceId):match("^inst:") then
        S.placeId = keptPlaceId
        local Placement = ns.FluxBindingPlacement
        if Placement and Placement.ChordForPlaceId then
            S.preferChord = Placement.ChordForPlaceId(keptPlaceId)
        end
    end
end

--- Prune default unbound orphans and reset the editor if needed.
--- opts.keepCurrent = false → drop everything pristine (tab hide / subject switch).
--- opts.dropCurrentIfOrphan = drop the open row only when its place is gone.
function Editor.PruneOrphans(opts)
    opts = type(opts) == "table" and opts or {}
    local FluxBinding = _G.FluxBinding
    if not FluxBinding or not FluxBinding.PrunePristineBindings then return 0 end

    local keepUid = nil
    if opts.keepCurrent ~= false and S.currentUid then
        local b = DB.Get(S.currentUid)
        if b then
            local relevant = FluxBinding.IsBindingRespecRelevant and FluxBinding.IsBindingRespecRelevant(b)
            local pid = b.placeId
            local isDraft = type(pid) == "string" and pid:match("^inst:")
            local hasPlace = FluxBinding.BindingHasLivePlace and FluxBinding.BindingHasLivePlace(b)
            if relevant or isDraft or hasPlace then
                keepUid = S.currentUid
            end
            -- Pristine with no live place: never keep (spellbook unbound).
        end
    end

    local n = FluxBinding.PrunePristineBindings(nil, { keepUid = keepUid }) or 0

    if opts.keepCurrent == false and S.currentUid and DB.Get(S.currentUid) then
        local b = DB.Get(S.currentUid)
        if b and FluxBinding.IsBindingRespecRelevant and not FluxBinding.IsBindingRespecRelevant(b) then
            DB.Remove(S.currentUid)
            n = n + 1
        end
    elseif opts.dropCurrentIfOrphan and S.currentUid and DB.Get(S.currentUid) then
        local b = DB.Get(S.currentUid)
        if b and FluxBinding.IsBindingRespecRelevant and not FluxBinding.IsBindingRespecRelevant(b) then
            local hasPlace = FluxBinding.BindingHasLivePlace and FluxBinding.BindingHasLivePlace(b)
            local pid = b.placeId
            local isDraft = type(pid) == "string" and pid:match("^inst:")
            if not hasPlace and not isDraft then
                DB.Remove(S.currentUid)
                n = n + 1
            end
        end
    end

    Editor.SyncAfterPrune()
    return n
end

-- refresh Status previews after each apply while the editor is open
local appliedHooked = false
local function EnsureAppliedHook()
    if appliedHooked then return end
    local FluxBinding = _G.FluxBinding
    if not FluxBinding or not FluxBinding.RegisterApplied then return end
    appliedHooked = true
    FluxBinding.RegisterApplied("FluxBindingEditor", function()
        local root = Editor.GetContentRoot()
        if root and root.frame and root.frame:IsShown() and S.currentTab == "status" then
            Editor.Redraw()
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Subject / instance management
-- ---------------------------------------------------------------------------

function Editor.SetSubject(desc, opts)
    if not desc then return end
    opts = type(opts) == "table" and opts or {}
    local newKey = (Action.FamilyKey and Action.FamilyKey(desc)) or Action.Key(desc)
    local newPlace = opts.placeId
    local placeChanging = (newPlace or "") ~= (S.placeId or "")
    local keyChanging = S.subjectKey and newKey and S.subjectKey ~= newKey
    -- Leaving a subject/place: purge pristine stubs so settings tabs don't leak.
    if Editor.PruneOrphans and (keyChanging or placeChanging) then
        Editor.PruneOrphans({ keepCurrent = false })
    end
    S.subject = desc
    -- Rank-sync: look up by family key so all ranks share one binding row.
    S.subjectKey = newKey
    S.pending = false
    S.placeId = opts.placeId
    S.preferChord = opts.preferChord
    S.placeRole = opts.placeRole
    S.placeSource = opts.placeSource
    S._ephemeralSub = nil
    -- New pick (list click, spellbook right-click, drag/drop) → start on Cast.
    S.currentTab = "cast"
    S.uids = S.subjectKey and DB.UidsForActionKey(S.subjectKey) or {}
    if #S.uids == 0 and Action.Key(desc) and Action.Key(desc) ~= S.subjectKey then
        S.uids = DB.UidsForActionKey(Action.Key(desc))
    end
    local allowCreate = opts.noCreate ~= true
    local placeId = opts.placeId
    local preferChord = opts.preferChord

    local chosen
    if placeId and DB.FindUidForPlace then
        chosen = DB.FindUidForPlace(S.subjectKey, placeId, nil)
        if not chosen then
            local strict = Action.Key(desc)
            if strict and strict ~= S.subjectKey then
                chosen = DB.FindUidForPlace(strict, placeId, nil)
            end
        end
        -- First open on this place: claim a legacy same-spell row with no placeId
        -- so C and Z can diverge (second place creates a new uid via EnsureBindingRow).
        if not chosen and DB.FindUnplacedUidForActionKey then
            chosen = DB.FindUnplacedUidForActionKey(S.subjectKey)
            if not chosen then
                local strict = Action.Key(desc)
                if strict and strict ~= S.subjectKey then
                    chosen = DB.FindUnplacedUidForActionKey(strict)
                end
            end
        end
    elseif preferChord and DB.FindUidForPlace then
        chosen = DB.FindUidForPlace(S.subjectKey, nil, preferChord)
    end

    if chosen then
        S.currentUid = chosen
    elseif placeId then
        -- Place row: Rebuild.EnsureBindingRow creates a stub so Cast/Targets/…
        -- tabs work; pruned on hide / leave if never customized.
        if allowCreate and opts.forceCreate then
            local b = DB.Add(desc, { placeId = placeId })
            S.uids = DB.UidsForActionKey(S.subjectKey) or { b.uid }
            S.currentUid = b.uid
        else
            S.currentUid = nil
        end
    elseif #S.uids == 0 and S.subjectKey and allowCreate then
        local b = DB.Add(desc)
        S.uids = { b.uid }
        S.currentUid = b.uid
    else
        S.currentUid = S.uids[1]
    end

    -- Keep action.id on the opened rank so previews / include-subtext know which rank.
    local cur = S.currentUid and DB.Get(S.currentUid)
    if cur and desc.type == "spell" and desc.id then
        if desc.pet and Action.PetSpell then
            cur.action = Action.PetSpell(desc.id, desc.name)
        else
            cur.action = Action.Spell(desc.id, desc.name)
        end
    end
    if cur and placeId and (not cur.placeId or cur.placeId == "") then
        cur.placeId = placeId
    end
    S.formToken = Forms.GetCurrentToken()
    Editor.Redraw()
end

--- Ensure a binding row exists for the current subject (browser may open without creating).
function Editor.EnsureBindingRow()
    if S.currentUid and DB.Get(S.currentUid) then
        return DB.Get(S.currentUid)
    end
    if not S.subject then return nil end

    -- Claim legacy unplaced same-spell row for this place before creating another.
    if S.placeId and S.subjectKey and DB.FindUnplacedUidForActionKey then
        local claim = DB.FindUnplacedUidForActionKey(S.subjectKey)
        if not claim then
            local strict = Action.Key(S.subject)
            if strict and strict ~= S.subjectKey then
                claim = DB.FindUnplacedUidForActionKey(strict)
            end
        end
        if claim then
            local b = DB.Get(claim)
            if b then
                b.placeId = S.placeId
                S.currentUid = claim
                S.uids = DB.UidsForActionKey(S.subjectKey) or { claim }
                return b
            end
        end
    end

    local b = DB.Add(S.subject, S.placeId and { placeId = S.placeId } or nil)
    S.subjectKey = (Action.FamilyKey and Action.FamilyKey(S.subject)) or Action.Key(S.subject)
    S.uids = DB.UidsForActionKey(S.subjectKey) or { b.uid }
    S.currentUid = b.uid
    if S.placeId then
        b.placeId = S.placeId
    end
    return b
end

function Editor.AddInstance()
    if not S.subject then return end
    -- Extra Clicked-style instance: shows on the list as UNBOUND; not saved until keyed.
    local b = DB.Add(S.subject)
    b.placeId = "inst:" .. tostring(b.uid)
    S.uids = DB.UidsForActionKey(S.subjectKey) or { b.uid }
    S.currentUid = b.uid
    S.placeId = b.placeId
    local Browser = ns.FluxBindingBrowser
    if Browser and Browser.S and S.subjectKey then
        Browser.S.selectedKey = S.subjectKey .. "|" .. b.placeId
    end
    Editor.Commit()
end

--- Live inherited chord from action bar / Extra / stance for the current place row.
function Editor.GetInheritedChord()
    if S.preferChord and S.preferChord ~= "" then
        return S.preferChord
    end
    if S.placeId and not tostring(S.placeId):match("^inst:") then
        local Placement = ns.FluxBindingPlacement
        if Placement and Placement.ChordForPlaceId then
            return Placement.ChordForPlaceId(S.placeId)
        end
    end
    return nil
end

--- Extra button keys come from Bindings.xml (FLUXGRID*, FLUXCLASS*, …) — show them
--- in the list/editor but do not allow rebinding here. Utility *spell/item* tiers
--- (util:N:mod) may still take a Flux key; the Utility button itself stays locked.
function Editor.IsExtraSystemKeyLocked()
    local subject = S.subject
    if subject and subject.type == "extra" then
        return true
    end
    local placeId = S.placeId
    local b = S.currentUid and DB.Get(S.currentUid)
    if (not placeId or placeId == "") and b then
        placeId = b.placeId
    end
    if type(placeId) ~= "string" or placeId == "" then
        return false
    end
    -- Utility parent button only.
    if placeId:match("^util:%d+$") then
        return true
    end
    -- Utility mod tiers hold real spells/items — allow Flux key.
    if placeId:match("^util:") then
        return false
    end
    -- Extra button / Extra flyout place (Bindings.xml).
    if placeId:match("^extra:") or placeId:match("^bind:") then
        return true
    end
    return false
end

--- True when the subject sits on a bar / Extra / stance (not a free draft instance).
function Editor.SubjectHasPhysicalPlace()
    if S.placeId and not tostring(S.placeId):match("^inst:") then
        return true
    end
    if not S.subject or not Action then return false end
    local Placement = ns.FluxBindingPlacement
    local SpellLibrary = ns.FluxBindingSpellLibrary
    local ak = S.subjectKey or (Action.FamilyKey and Action.FamilyKey(S.subject)) or Action.Key(S.subject)
    if not ak then return false end
    if Placement and Placement.IndexExtra then
        local map = Placement.IndexExtra()
        if map and map[ak] and #map[ak] > 0 then return true end
        local strict = Action.Key(S.subject)
        if strict and map and map[strict] and #map[strict] > 0 then return true end
    end
    if Placement and Placement.IndexStance then
        local map = Placement.IndexStance()
        if map and map[ak] and #map[ak] > 0 then return true end
        local strict = Action.Key(S.subject)
        if strict and map and map[strict] and #map[strict] > 0 then return true end
    end
    if Placement and Placement.IndexMultiCast then
        local map = Placement.IndexMultiCast()
        if map and map[ak] and #map[ak] > 0 then return true end
        local strict = Action.Key(S.subject)
        if strict and map and map[strict] and #map[strict] > 0 then return true end
    end
    if SpellLibrary and SpellLibrary.IndexBars then
        local barIndex = SpellLibrary.IndexBars()
        local a = S.subject
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

--- Refresh preferChord from live placement (bar moves / rebinds).
--- Clears placeId when the slot/Extra/stance place is gone → editor shows not-bound.
function Editor.RefreshInheritedChord()
    if not S.placeId or tostring(S.placeId):match("^inst:") then
        return false
    end
    local Placement = ns.FluxBindingPlacement
    if not Placement or not Placement.ChordForPlaceId then return false end
    local placeId = S.placeId
    local chord = Placement.ChordForPlaceId(placeId)
    -- Zone-inactive Extra mounts may have a placeId with no live chord; keep the row.
    local stillOccupied = false
    local slot = placeId:match("^ab:(%d+)$")
    if slot then
        stillOccupied = HasAction and HasAction(tonumber(slot)) and true or false
    elseif placeId:match("^stance:(%d+)$") then
        stillOccupied = chord and chord ~= ""
    elseif placeId:match("^util:") or placeId:match("^extra:") or placeId:match("^bind:") then
        -- Chord nil can mean zone-inactive mount still in the Extra index.
        if Placement.IndexExtra then
            local map = Placement.IndexExtra() or {}
            for _, places in pairs(map) do
                if type(places) == "table" then
                    for i = 1, #places do
                        local p = places[i]
                        local pid = p.placeId or (Placement.PlaceId and Placement.PlaceId(p))
                        if pid == placeId then
                            stillOccupied = true
                            break
                        end
                    end
                end
                if stillOccupied then break end
            end
        end
    elseif placeId:match("^mcast:") then
        if Placement.IndexMultiCast then
            local map = Placement.IndexMultiCast() or {}
            for _, places in pairs(map) do
                if type(places) == "table" then
                    for i = 1, #places do
                        local p = places[i]
                        local pid = p.placeId or (Placement.PlaceId and Placement.PlaceId(p))
                        if pid == placeId then
                            stillOccupied = true
                            break
                        end
                    end
                end
                if stillOccupied then break end
            end
        end
    end
    if not stillOccupied and (not chord or chord == "") then
        S.placeId = nil
        S.preferChord = nil
        return true
    end
    if chord ~= S.preferChord then
        S.preferChord = chord
        return true
    end
    return false
end

local inheritWatcher
local inheritPending
local function EnsureInheritWatcher()
    if inheritWatcher then return inheritWatcher end
    inheritWatcher = CreateFrame("Frame")
    inheritWatcher:SetScript("OnEvent", function(_, event)
        if event == "UPDATE_BINDINGS"
            and _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        if not Editor.IsEmbedded or not Editor.IsEmbedded() then return end
        if not S.subject then return end
        if inheritPending then return end
        inheritPending = true
        C_Timer.After(0.05, function()
            inheritPending = false
            if not Editor.IsEmbedded or not Editor.IsEmbedded() then return end
            Editor.RefreshInheritedChord()
            -- Spell removed from bar / Extra / stance: purge default unbound stubs
            -- and reset the editor when nothing is left to inherit.
            if Editor.PruneOrphans then
                Editor.PruneOrphans({ dropCurrentIfOrphan = true })
            end
            Editor.Redraw()
        end)
    end)
    return inheritWatcher
end

function Editor.SetInheritWatchEnabled(on)
    local w = EnsureInheritWatcher()
    if on then
        w:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        w:RegisterEvent("UPDATE_BINDINGS")
        w:RegisterEvent("UPDATE_MACROS")
        w:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        w:RegisterEvent("BAG_UPDATE")
        pcall(w.RegisterEvent, w, "UPDATE_SHAPESHIFT_FORMS")
        pcall(w.RegisterEvent, w, "UPDATE_SHAPESHIFT_FORM")
    else
        w:UnregisterAllEvents()
    end
end

function Editor.RemoveInstance()
    if not S.currentUid then return end
    DB.Remove(S.currentUid)
    S.uids = DB.UidsForActionKey(S.subjectKey) or {}
    S.currentUid = S.uids[1]
    local cur = S.currentUid and DB.Get(S.currentUid)
    S.placeId = cur and cur.placeId or S.placeId
    Editor.Commit()
end

local function TryAcceptCursorSubject()
    -- Cast-tab multi-cast extras zone handled this pickup already.
    if S._suppressSubjectDrop then
        return false
    end
    local desc = Action.FromCursor()
    if not desc then return false end
    if ClearCursor then ClearCursor() end
    local Browser = ns.FluxBindingBrowser
    -- Prefer selecting an existing list row (bar / Extra / unbound catalog).
    if Browser and Browser.SelectAction and Browser.SelectAction(desc) then
        return true
    end
    -- Not in the catalog list yet — open as unbound subject in the editor.
    Editor.SetSubject(desc, { noCreate = true })
    if Browser then
        if Browser.S then
            local ak = (Action.FamilyKey and Action.FamilyKey(desc)) or Action.Key(desc)
            Browser.S.selectedKey = ak
        end
        if Browser.RefreshList then
            Browser.RefreshList()
        end
    end
    return true
end

--- Public: drop spell/item/macro from cursor into the Binding editor.
function Editor.AcceptCursorSubject()
    return TryAcceptCursorSubject()
end

local function EnableDropTarget(frame)
    if not frame or frame._fluxBindingDropHooked then return end
    frame._fluxBindingDropHooked = true
    frame:EnableMouse(true)
    frame:SetScript("OnReceiveDrag", function()
        TryAcceptCursorSubject()
    end)
    -- Click-drop while holding a pickup (bags / spellbook).
    if frame.HookScript then
        frame:HookScript("OnMouseUp", function()
            if GetCursorInfo and GetCursorInfo() then
                TryAcceptCursorSubject()
            end
        end)
    else
        frame:SetScript("OnMouseUp", function()
            if GetCursorInfo and GetCursorInfo() then
                TryAcceptCursorSubject()
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Window shell (standalone FluxBindingFrame OR embedded host)
-- ---------------------------------------------------------------------------

function Editor.GetContentRoot()
    if S.embedded and S.embedRoot then
        return S.embedRoot
    end
    return S.win
end

local function EnsureStandaloneWindow()
    if S.win then return S.win end
    local win = AceGUI:Create("FluxBindingFrame") or AceGUI:Create("Frame")
    win:SetTitle(L["Flux Binding"] or "Flux Binding")
    win:SetLayout("Fill")
    win:SetWidth(760)
    win:SetHeight(620)
    if win.SetMinWidth then win:SetMinWidth(640) end
    if win.SetMinHeight then win:SetMinHeight(480) end
    win:SetCallback("OnClose", function(widget)
        widget.frame:Hide()
    end)
    if _G.FluxBindingEditorTheme and _G.FluxBindingEditorTheme.ApplyAceFrame then
        pcall(_G.FluxBindingEditorTheme.ApplyAceFrame, win)
    end
    -- drag a spell/item/macro anywhere onto the window to set the subject
    EnableDropTarget(win.frame)
    S.win = win
    return win
end

--- Host the editor inside a FluxWindow Binding-tab pane (no left list chrome).
function Editor.AttachHost(hostFrame)
    if not hostFrame then return end
    S.hostFrame = hostFrame
    S.embedded = true
    if Editor.SetInheritWatchEnabled then
        Editor.SetInheritWatchEnabled(true)
    end
    if S.win and S.win.frame then
        S.win.frame:Hide()
    end
    EnableDropTarget(hostFrame)
    if not S.embedRoot then
        local root = AceGUI:Create("SimpleGroup")
        root:SetLayout("Fill")
        root.frame:SetParent(hostFrame)
        root.frame:ClearAllPoints()
        root.frame:SetAllPoints(hostFrame)
        root.frame:Show()
        -- AceGUI needs width/height from the parent
        root.frame:SetScript("OnSizeChanged", function(f, w, h)
            if root.LayoutFinished then
                -- force AceGUI layout
            end
            if root.DoLayout then root:DoLayout() end
            if root.content then
                root.content:SetWidth(w)
                root.content:SetHeight(h)
            end
        end)
        S.embedRoot = root
    else
        S.embedRoot.frame:SetParent(hostFrame)
        S.embedRoot.frame:ClearAllPoints()
        S.embedRoot.frame:SetAllPoints(hostFrame)
        S.embedRoot.frame:Show()
    end
    EnableDropTarget(S.embedRoot.frame)
    local w, h = hostFrame:GetWidth(), hostFrame:GetHeight()
    if w and h and w > 0 and h > 0 then
        S.embedRoot:SetWidth(w)
        S.embedRoot:SetHeight(h)
    end
end

function Editor.DetachHost()
    if Editor.SetInheritWatchEnabled then
        Editor.SetInheritWatchEnabled(false)
    end
    S.embedded = false
    S.hostFrame = nil
    if S.embedRoot and S.embedRoot.frame then
        S.embedRoot:ReleaseChildren()
        S.embedRoot.frame:Hide()
    end
end

local function EnsureWindow()
    if S.embedded and S.hostFrame then
        Editor.AttachHost(S.hostFrame)
        return S.embedRoot
    end
    -- Floating editor removed — only paint when hosted in Options → Binding.
    if S.embedRoot and S.hostFrame then
        return S.embedRoot
    end
    return nil
end

--- Full rebuild of the window contents (cheap; AceGUI recycled widgets).
function Editor.Rebuild()
    local win = EnsureWindow()
    if not win then
        return
    end
    win:ReleaseChildren()
    S.tabScroll = nil

    if S.pending or not S.subject then
        local root = AceGUI:Create("ScrollFrame")
        root:SetLayout("Flow")
        root:SetFullWidth(true)
        root:SetFullHeight(true)
        win:AddChild(root)
        if root.frame then
            EnableDropTarget(root.frame)
        end
        local hint = AceGUI:Create("Label")
        hint:SetFullWidth(true)
        hint:SetFontObject(GameFontHighlightLarge)
        hint:SetText("\n\n" .. (L["Drag a spell, item or macro here to begin."]
            or "Drag a spell, item or macro here to begin.\n\nOr right-click a spell in the spellbook."))
        root:AddChild(hint)
        return
    end

    -- Toolbar + form strip (natural height) above a Fill tab group whose panel
    -- content scrolls — so Cast / Targets / etc. can reach the bottom.
    local page = AceGUI:Create("SimpleGroup")
    page:SetLayout("Flow")
    page:SetFullWidth(true)
    page:SetFullHeight(true)
    win:AddChild(page)
    if page.frame then
        EnableDropTarget(page.frame)
    end

    -- Full editor tabs: only auto-create a DB row when the action lives on a
    -- bar / Extra / stance (or Utility). Spellbook-only unbound stays unbound
    -- until the user edits a setting or binds a key — no "Default (no key)" stub.
    if Editor.SupportsBindingTabs and Editor.SupportsBindingTabs() then
        if not S.currentUid and Editor.EnsureBindingRow then
            local hasPlace = (Editor.SubjectHasPhysicalPlace and Editor.SubjectHasPhysicalPlace())
                or (Editor.IsUtilityPlace and Editor.IsUtilityPlace())
                or (Editor.IsConsumableExtraPlace and Editor.IsConsumableExtraPlace())
                or (S.placeId and not tostring(S.placeId):match("^inst:"))
            if hasPlace then
                Editor.EnsureBindingRow()
            end
        end
    end

    if Editor.BuildToolbar then
        Editor.BuildToolbar(page)
    end
    if Editor.SupportsBindingTabs and Editor.SupportsBindingTabs() then
        if Editor.BuildFormStrip then
            Editor.BuildFormStrip(page)
        end
        if Editor.BuildTabs then
            Editor.BuildTabs(page)
        end
    else
        local note = AceGUI:Create("Label")
        note:SetFullWidth(true)
        note:SetFontObject(GameFontHighlightSmall)
        local chord = (Editor.GetInheritedChord and Editor.GetInheritedChord()) or S.preferChord
        local where = Editor.IsStancePlace and Editor.IsStancePlace() and "Stance bar"
            or "Extra button"
        local lines = {
            ("|cff9ecfff%s — keys and layout come from Flux Bindings / Extra UI.|r"):format(where),
        }
        if chord and chord ~= "" then
            lines[#lines + 1] = ("Key: |cffffffff%s|r"):format(tostring(chord))
        end
        lines[#lines + 1] = "|cff808080Cast / Targets / Conditions / Forms / Badges apply to action-bar, Utility, and consumable Extra buttons.|r"
        note:SetText(table.concat(lines, "\n"))
        page:AddChild(note)
    end
end

-- ---------------------------------------------------------------------------
-- Open API
-- ---------------------------------------------------------------------------

local function ApplyOpenArg(openArg)
    if openArg == nil or (type(openArg) == "table" and openArg.pending) then
        S.pending = true
        S.subject = nil
        S.subjectKey = nil
        S.uids = {}
        S.currentUid = nil
        S.placeId = nil
        S.preferChord = nil
        S.placeRole = nil
        S.placeSource = nil
        Editor.Redraw()
        return
    end

    local desc
    if type(openArg) == "table" and openArg.type and (openArg.id or openArg.name) then
        desc = openArg
    elseif type(openArg) == "table" and (openArg.spellID or openArg.actionID) then
        desc = Action.FromSpellbookRow(openArg)
    elseif type(openArg) == "number" then
        desc = Action.Spell(openArg)
    end
    if desc then
        Editor.SetSubject(desc)
    else
        S.pending = true
        Editor.Redraw()
    end
end

local function HideStandaloneWindow()
    if S.win and S.win.frame then
        S.win.frame:Hide()
    end
end

--- openArg: nil/{pending=true} | {spellID=..., actionID=...} (spellbook row)
---          | action descriptor {type=..., id=...}
--- opts.embeddedHost = frame to host editor inside Binding browser.
--- Spellbook / slash / shared-key open FluxUI Options → Binding (no floating editor).
function _G.FluxSpellBindingEditor_Open(openArg, opts)
    DB.Ensure()
    EnsureAppliedHook()
    opts = type(opts) == "table" and opts or {}

    if opts.embeddedHost then
        Editor.AttachHost(opts.embeddedHost)
        ApplyOpenArg(openArg)
        return
    end

    HideStandaloneWindow()

    local Browser = ns.FluxBindingBrowser
    if Browser and Browser.QueueOpenArg then
        Browser.QueueOpenArg(openArg)
    end

    local FO = _G.FluxOptions
    if FO and FO.OpenToBindingTab then
        FO:OpenToBindingTab()
    end

    local function tryConsume()
        if Browser and Browser.IsShown and Browser.IsShown()
            and Browser.ConsumePendingOpen then
            return Browser.ConsumePendingOpen()
        end
        return false
    end

    if tryConsume() then
        return
    end
    -- AceConfig may attach the Binding embed on the next frame.
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if tryConsume() then return end
            C_Timer.After(0.05, tryConsume)
        end)
    end
end

--- Legacy alias used by spellbook hooks.
_G.FluxBindingEditor_Open = _G.FluxSpellBindingEditor_Open

function _G.FluxSpellBindingEditor_ReloadLiveSession()
    local root = Editor.GetContentRoot()
    if root and root.frame and root.frame:IsShown() and S.subject then
        S.uids = S.subjectKey and DB.UidsForActionKey(S.subjectKey) or {}
        if not S.currentUid or not DB.Get(S.currentUid) then
            S.currentUid = S.uids[1]
        end
        Editor.Redraw()
        return true
    end
    return false
end

--- Shared-key peer icon click: jump to that spell in the Binding-tab list when
--- embedded; otherwise open FluxUI Options → Binding for that action.
--- `target` may be an action desc, or { action, placeId, uid, key/preferChord }.
function Editor.OpenSharedPeer(target)
    if not target then return end
    local action, opts
    if type(target) == "table" and target.action then
        action = target.action
        opts = {
            placeId = target.placeId,
            uid = target.uid,
            preferChord = target.preferChord or target.key,
        }
    else
        action = target
        opts = nil
    end
    if not action then return end
    if Editor.IsEmbedded() then
        local Browser = ns.FluxBindingBrowser
        if Browser and Browser.SelectAction and Browser.SelectAction(action, opts) then
            return
        end
        if Editor.OpenInHost(action, {
            create = true,
            placeId = opts and opts.placeId,
            preferChord = opts and opts.preferChord,
        }) then
            return
        end
    end
    if _G.FluxSpellBindingEditor_Open then
        _G.FluxSpellBindingEditor_Open(action)
    end
end

--- Open/select subject inside an already-attached Binding browser host.
--- opts.create = true creates a DB row so settings/tabs work (bar-only spells).
function Editor.OpenInHost(openArg, opts)
    if not S.hostFrame then return false end
    opts = type(opts) == "table" and opts or {}
    S.embedded = true
    if openArg == nil or (type(openArg) == "table" and openArg.pending) then
        ApplyOpenArg(openArg)
        return true
    end
    local desc
    if type(openArg) == "table" and openArg.type and (openArg.id or openArg.name) then
        desc = openArg
    elseif type(openArg) == "table" and (openArg.spellID or openArg.actionID) then
        desc = Action.FromSpellbookRow(openArg)
    elseif type(openArg) == "number" then
        desc = Action.Spell(openArg)
    end
    if desc then
        -- Browser default: noCreate. Place / bar rows create a place-linked UID.
        Editor.SetSubject(desc, {
            noCreate = opts.create ~= true,
            placeId = opts.placeId,
            preferChord = opts.preferChord,
            placeRole = opts.placeRole,
            placeSource = opts.placeSource,
        })
    else
        ApplyOpenArg({ pending = true })
    end
    return true
end
