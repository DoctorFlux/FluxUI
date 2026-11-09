--[[
    ExtraButtonSystem/Shared/FluxNCFlyoutOptions.lua
    Per-character flyout hide/order: SavedVariablesPerCharacter → FluxNCFlyoutCharDB.
    Class teleport + portal spells share one hidden/order list. Reagent rows are not customized (always last in flyout).
]]

FluxNCFlyoutOptions = FluxNCFlyoutOptions or {}
local NFO = FluxNCFlyoutOptions

local function GetActionbarsTable()
    if FluxOptions and FluxOptions.GetActionbarsDB then
        return FluxOptions:GetActionbarsDB()
    end
    return nil
end

local function mergeOrderLists(dst, src)
    if not src then
        return
    end
    local seen = {}
    for _, id in ipairs(dst) do
        seen[id] = true
    end
    for _, id in ipairs(src) do
        if not seen[id] then
            dst[#dst + 1] = id
            seen[id] = true
        end
    end
end

local function mergeHidden(dst, src)
    if not src then
        return
    end
    for k, v in pairs(src) do
        if v and dst[k] == nil then
            dst[k] = true
        end
    end
end

--- One-time per character: copy legacy Ace actionbars.ncFlyout → FluxNCFlyoutCharDB
local function migrateLegacyNcFlyoutFromActionbars(db)
    if db._importedLegacyAceNcFlyout then
        return
    end
    local ab = GetActionbarsTable()
    if not ab or not ab.ncFlyout or type(ab.ncFlyout) ~= "table" then
        db._importedLegacyAceNcFlyout = true
        return
    end
    local old = ab.ncFlyout

    db.classSpells = db.classSpells or { hidden = {}, order = {} }
    db.classSpells.hidden = db.classSpells.hidden or {}
    db.classSpells.order = db.classSpells.order or {}

    local ct = old.classTeleport
    if ct then
        for _, modeKey in ipairs({ "Teleport", "Portal" }) do
            local block = ct[modeKey]
            if block and block.spells then
                mergeHidden(db.classSpells.hidden, block.spells.hidden)
                mergeOrderLists(db.classSpells.order, block.spells.order)
            end
        end
    end

    if old.teleportItems then
        db.teleportItems = db.teleportItems or { hidden = {}, order = {} }
        db.teleportItems.hidden = db.teleportItems.hidden or {}
        mergeHidden(db.teleportItems.hidden, old.teleportItems.hidden)
        db.teleportItems.order = db.teleportItems.order or {}
        mergeOrderLists(db.teleportItems.order, old.teleportItems.order)
    end
    if old.mountItems then
        db.mountItems = db.mountItems or { hidden = {}, order = {} }
        db.mountItems.hidden = db.mountItems.hidden or {}
        mergeHidden(db.mountItems.hidden, old.mountItems.hidden)
        db.mountItems.order = db.mountItems.order or {}
        mergeOrderLists(db.mountItems.order, old.mountItems.order)
    end
    db._importedLegacyAceNcFlyout = true
end

--- Ensure FluxNCFlyoutCharDB exists with expected nested tables.
function NFO.EnsureDB()
    if not _G.FluxNCFlyoutCharDB or type(_G.FluxNCFlyoutCharDB) ~= "table" then
        _G.FluxNCFlyoutCharDB = {}
    end
    local n = _G.FluxNCFlyoutCharDB

    migrateLegacyNcFlyoutFromActionbars(n)

    if not n.classSpells then
        n.classSpells = { hidden = {}, order = {} }
    else
        n.classSpells.hidden = n.classSpells.hidden or {}
        n.classSpells.order = n.classSpells.order or {}
    end
    if not n.teleportItems then
        n.teleportItems = { hidden = {}, order = {} }
    else
        n.teleportItems.hidden = n.teleportItems.hidden or {}
        n.teleportItems.order = n.teleportItems.order or {}
    end
    if not n.mountItems then
        n.mountItems = { hidden = {}, order = {} }
    else
        n.mountItems.hidden = n.mountItems.hidden or {}
        n.mountItems.order = n.mountItems.order or {}
    end
    return n
end

function NFO.GetDB()
    return NFO.EnsureDB()
end

--- Clear saved order + hide for class spells, teleport items, and mount-item flyouts.
--- Does not touch FluxFlyoutFavorites (favorites stay as-is).
function NFO.ResetFlyoutLayoutToDefault()
    local db = NFO.EnsureDB()
    if not db then
        return
    end
    db.classSpells = db.classSpells or { hidden = {}, order = {} }
    db.classSpells.hidden = {}
    db.classSpells.order = {}
    db.teleportItems = db.teleportItems or { hidden = {}, order = {} }
    db.teleportItems.hidden = {}
    db.teleportItems.order = {}
    db.mountItems = db.mountItems or { hidden = {}, order = {} }
    db.mountItems.hidden = {}
    db.mountItems.order = {}
    NFO.NotifyChanged()
end

local function sortByName(actions)
    table.sort(actions, function(a, b)
        local na = a["$name"] or ""
        local nb = b["$name"] or ""
        return na < nb
    end)
end

local function applyHideAndOrder(actions, block, getId)
    if not actions or #actions == 0 then
        return actions
    end
    block = block or {}
    local hidden = block.hidden or {}
    local order = block.order or {}

    local kept = {}
    for _, a in ipairs(actions) do
        local id = getId(a)
        if id and not hidden[id] then
            kept[#kept + 1] = a
        elseif not id then
            kept[#kept + 1] = a
        end
    end

    local byId = {}
    for _, a in ipairs(kept) do
        local id = getId(a)
        if id then
            byId[id] = a
        end
    end

    local seen = {}
    local out = {}
    for _, id in ipairs(order) do
        local a = byId[id]
        if a and not seen[id] then
            out[#out + 1] = a
            seen[id] = true
        end
    end

    local tail = {}
    for _, a in ipairs(kept) do
        local id = getId(a)
        if id and not seen[id] then
            tail[#tail + 1] = a
        elseif not id then
            out[#out + 1] = a
        end
    end
    sortByName(tail)
    for _, a in ipairs(tail) do
        out[#out + 1] = a
    end
    return out
end

local function destKeyFromSpellName(name)
    if not name then
        return ""
    end
    local rest = name:match(":%s*(.+)$")
    return (rest or name):lower()
end

--- After hide/order, keep teleport + portal rows for the same destination adjacent and ordered like saved rep list.
local function sortClassSpellsForSharedDestinations(spellActions, classSpells)
    if not spellActions or #spellActions <= 1 then
        return spellActions
    end
    local order = classSpells.order or {}
    local destPos = {}
    for i, sid in ipairs(order) do
        local sn
        if C_Spell and C_Spell.GetSpellInfo then
            local si = C_Spell.GetSpellInfo(sid)
            sn = si and si.name
        elseif GetSpellInfo then
            sn = GetSpellInfo(sid)
        end
        if sn then
            local dk = destKeyFromSpellName(sn)
            if destPos[dk] == nil then
                destPos[dk] = i
            end
        end
    end
    table.sort(spellActions, function(a, b)
        local na, nb = a["$name"] or "", b["$name"] or ""
        local da, db = destKeyFromSpellName(na), destKeyFromSpellName(nb)
        local pa, pb = destPos[da] or 9999, destPos[db] or 9999
        if pa ~= pb then
            return pa < pb
        end
        return na < nb
    end)
    return spellActions
end

--- Shared class teleport + portal spell list (mode only filters which spells exist in the flyout).
function NFO.ApplyClassTeleportSpells(mode, spellActions)
    NFO.EnsureDB()
    local db = _G.FluxNCFlyoutCharDB
    if not db or not db.classSpells then
        return spellActions
    end
    local out = applyHideAndOrder(spellActions, db.classSpells, function(a)
        return a["$spellID"]
    end)
    return sortClassSpellsForSharedDestinations(out, db.classSpells)
end

function NFO.ApplyTeleportItemActions(actions)
    NFO.EnsureDB()
    local db = _G.FluxNCFlyoutCharDB
    if not db or not db.teleportItems then
        return actions
    end
    return applyHideAndOrder(actions, db.teleportItems, function(a)
        return a["$itemId"]
    end)
end

function NFO.ApplyMountItemActions(actions)
    NFO.EnsureDB()
    local db = _G.FluxNCFlyoutCharDB
    if not db or not db.mountItems then
        return actions
    end
    return applyHideAndOrder(actions, db.mountItems, function(a)
        return a["$itemId"]
    end)
end

-- Debounce: options + rapid drag fire many notifies; coalesce to one light refresh.
local notifyPending
local function runNotifyNow()
    notifyPending = nil
    local function run(fn)
        if type(fn) == "function" then
            pcall(fn)
        end
    end
    if FluxNCTeleportPortal and FluxNCTeleportPortal.RefreshFlyoutIfOpen then
        run(FluxNCTeleportPortal.RefreshFlyoutIfOpen)
    end
    if FluxNCHearthstone and FluxNCHearthstone.RefreshFlyoutIfOpen then
        run(FluxNCHearthstone.RefreshFlyoutIfOpen)
    end
    if FluxNCMount and FluxNCMount.RefreshFlyoutIfOpen then
        run(FluxNCMount.RefreshFlyoutIfOpen)
    end
    -- Intentionally omit FluxNC* Update() here — full grid updates are expensive; flyout rebuild is enough.
end

function NFO.NotifyChanged()
    if notifyPending then
        return
    end
    notifyPending = true
    local T = C_Timer
    if T and T.After then
        T.After(0.12, function()
            runNotifyNow()
        end)
    else
        runNotifyNow()
    end
end
