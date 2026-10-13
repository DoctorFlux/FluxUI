-- AceGUI: NonCombat flyout hide / reorder (FluxNCFlyoutCharDB per character).

local Type, Version = "FluxNCFlyoutPanel", 12
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local CELL = 44
local TEX = 36
local GAP = 4
local Timer = C_Timer
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

local lastActiveWidget = nil
local RefreshPanel

local function mergeEntryOrder(knownList, orderIds, getIdFn)
    orderIds = orderIds or {}
    local byId = {}
    for _, e in ipairs(knownList) do
        local id = getIdFn(e)
        if id then
            byId[id] = e
        end
    end
    local seen = {}
    local out = {}
    for _, oid in ipairs(orderIds) do
        if byId[oid] and not seen[oid] then
            out[#out + 1] = byId[oid]
            seen[oid] = true
        end
    end
    local tail = {}
    for _, e in ipairs(knownList) do
        local id = getIdFn(e)
        if id and not seen[id] then
            tail[#tail + 1] = e
        end
    end
    table.sort(tail, function(a, b)
        return (a.name or "") < (b.name or "")
    end)
    for _, e in ipairs(tail) do
        out[#out + 1] = e
    end
    return out
end

--- Group Teleport: X + Portal: X (same destination) into one row; shared hide/order on all spell IDs in the group.
local function destinationGroupKey(spellName)
    if not spellName then
        return "?"
    end
    local rest = spellName:match(":%s*(.+)$")
    if rest and rest ~= "" then
        return rest:lower()
    end
    return spellName:lower()
end

local function shortDestLabel(spellName)
    local rest = spellName and spellName:match(":%s*(.+)$")
    return rest or spellName or "?"
end

local function getUnifiedClassSpellEntries()
    local TP = _G.FluxNCTeleportPortal
    if not TP then
        return {}
    end
    local groups = {}
    local function addSpell(s, teleportPass)
        if not s or not s.spellID or not s.name then
            return
        end
        local gk = destinationGroupKey(s.name)
        local g = groups[gk]
        if not g then
            g = { spellIDs = {}, repId = nil, labelName = s.name }
            groups[gk] = g
        end
        g.spellIDs[s.spellID] = true
        if teleportPass then
            g.repId = s.spellID
            g.labelName = s.name
        elseif not g.repId then
            -- Portal-only destination (no personal teleport)
            g.repId = s.spellID
            g.labelName = s.name
        end
    end
    for _, s in ipairs(TP.GetKnownTeleportSpells and TP.GetKnownTeleportSpells() or {}) do
        addSpell(s, true)
    end
    for _, s in ipairs(TP.GetKnownPortalSpells and TP.GetKnownPortalSpells() or {}) do
        addSpell(s, false)
    end

    local out = {}
    for _, g in pairs(groups) do
        local linked = {}
        for sid in pairs(g.spellIDs) do
            linked[#linked + 1] = sid
        end
        table.sort(linked)
        local repId = g.repId or linked[1]
        local icon
        local API = _G.FluxAPICompat and FluxAPICompat.API
        if API and API.GetSpellDisplayTexture then
            icon = API.GetSpellDisplayTexture(repId)
        elseif GetSpellTexture then
            icon = GetSpellTexture(repId)
        end
        if not icon or icon == "" then
            icon = "Interface\\Icons\\INV_Misc_QuestionMark"
        end
        out[#out + 1] = {
            spellID = repId,
            linkedSpellIDs = linked,
            name = shortDestLabel(g.labelName or ""),
            icon = icon,
        }
    end
    table.sort(out, function(a, b)
        return (a.name or "") < (b.name or "")
    end)
    return out
end

--- Drop stale spell IDs from saved order (keep rep + linked portal/teleport ids).
local function pruneClassSpellOrder(cs, spellEntries)
    local valid = {}
    for _, e in ipairs(spellEntries) do
        valid[e.spellID] = true
        for _, lid in ipairs(e.linkedSpellIDs or {}) do
            valid[lid] = true
        end
    end
    local o = cs.order or {}
    local new = {}
    local seen = {}
    for _, id in ipairs(o) do
        if valid[id] and not seen[id] then
            new[#new + 1] = id
            seen[id] = true
        end
    end
    cs.order = new
end

local function getTeleportItemEntries()
    local H = _G.FluxNCHearthstone
    if not H or not H.GetTeleportItems then
        return {}
    end
    local items = H.GetTeleportItems(true) or {}
    local out = {}
    for _, it in ipairs(items) do
        if it.itemId then
            out[#out + 1] = {
                itemId = it.itemId,
                name = it.name or ("#" .. tostring(it.itemId)),
                icon = it.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
            }
        end
    end
    table.sort(out, function(a, b)
        return (a.name or "") < (b.name or "")
    end)
    return out
end

local function getMountItemEntries()
    local M = _G.FluxNCMount
    if not M or not M.GetBagMountItems then
        return {}
    end
    -- true = show flying / zone-restricted bag mounts too (same list you can configure in any zone)
    local actions = M.GetBagMountItems(true) or {}
    local out = {}
    for _, a in ipairs(actions) do
        local iid = a["$itemId"]
        if iid then
            out[#out + 1] = {
                itemId = iid,
                name = a["$name"] or ("#" .. tostring(iid)),
                icon = a["$iconTexture"] or "Interface\\Icons\\INV_Misc_QuestionMark",
            }
        end
    end
    table.sort(out, function(a, b)
        return (a.name or "") < (b.name or "")
    end)
    return out
end

-- ── Drag ghost ──────────────────────────────────────────────────────────────

local ghostFrame, ghostIcon

local function PlaceGhostAtCursor(self)
    if not self then return end
    local x, y
    if GetScaledCursorPosition then
        x, y = GetScaledCursorPosition()
    else
        local s = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        x, y = cx / s, cy / s
    end
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    if self.Raise then
        self:Raise()
    end
end

local function HideGhost()
    if ghostFrame then
        ghostFrame:Hide()
    end
end

local function ShowGhost(texture)
    HideGhost()
    if not ghostFrame then
        ghostFrame = CreateFrame("Frame", "FluxNCFlyoutDragGhost", UIParent)
        -- TOOLTIP strata so the ghost draws above AceGUI / Flux options windows (FULLSCREEN_DIALOG can sit under some config frames).
        ghostFrame:SetFrameStrata("TOOLTIP")
        -- Frame level must be 0-65535 (API hard limit; values above error at runtime).
        ghostFrame:SetFrameLevel(63000)
        ghostFrame:SetToplevel(true)
        ghostFrame:EnableMouse(false)
        ghostFrame:SetSize(math.floor(CELL * 1.1), math.floor(CELL * 1.1))
        ghostIcon = ghostFrame:CreateTexture(nil, "ARTWORK", nil, 1)
        ghostIcon:SetAllPoints()
        ghostIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    ghostIcon:SetTexture(texture or "Interface/Icons/INV_Misc_QuestionMark")
    ghostFrame:SetAlpha(0.92)
    PlaceGhostAtCursor(ghostFrame)
    if ghostFrame.Raise then
        ghostFrame:Raise()
    end
    ghostFrame:Show()
end

local function ComputeDropIndexUniform(slots, cx, cy)
    local n = #slots
    if n == 0 then
        return nil
    end
    for i = 1, n do
        local s = slots[i]
        if s and s:IsShown() and s.GetScaledRect then
            local l, b, w, h = s:GetScaledRect()
            if l and b and w and h and w > 0 and h > 0 then
                local r = l + w
                local t = b + h
                if cx >= l and cx <= r and cy >= b and cy <= t then
                    local mid = l + w * 0.5
                    return (cx < mid) and i or math.min(i + 1, n + 1)
                end
            end
        end
    end
    local best, bestD = 1, math.huge
    for i = 1, n do
        local s = slots[i]
        if s and s.GetScaledRect then
            local l, b, w, h = s:GetScaledRect()
            if l and w and h then
                local mx, my = l + w * 0.5, b + h * 0.5
                local d = (cx - mx) ^ 2 + (cy - my) ^ 2
                if d < bestD then
                    bestD, best = d, i
                end
            end
        end
    end
    local s = slots[best]
    if s and s.GetScaledRect then
        local l, b, w, h = s:GetScaledRect()
        if l and w then
            local mid = l + w * 0.5
            return (cx < mid) and best or math.min(best + 1, n + 1)
        end
    end
    return best
end

local function LayoutRow(parent, slots, cols)
    cols = math.max(1, cols or 6)
    local n = #slots
    for i, slot in ipairs(slots) do
        local idx = i - 1
        local row = math.floor(idx / cols)
        local col = idx % cols
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", parent, "TOPLEFT", col * (CELL + GAP), -row * (CELL + GAP))
    end
    local rows = math.max(1, math.ceil(n / cols))
    local pw = cols * CELL + (cols - 1) * GAP
    local ph = rows * CELL + (rows - 1) * GAP
    parent:SetSize(pw, ph)
    return ph
end

local function wipeFrameTree(f)
    if not f then
        return
    end
    if f.SetScript then
        f:SetScript("OnUpdate", nil)
        f:SetScript("OnEnter", nil)
        f:SetScript("OnLeave", nil)
        f:SetScript("OnClick", nil)
        f:SetScript("OnMouseDown", nil)
        f:SetScript("OnMouseUp", nil)
        f:SetScript("OnDragStart", nil)
        f:SetScript("OnDragStop", nil)
        f:SetScript("OnReceiveDrag", nil)
    end
    if f.GetChildren then
        for i = select("#", f:GetChildren()), 1, -1 do
            wipeFrameTree(select(i, f:GetChildren()))
        end
    end
    f:Hide()
    f:SetParent(nil)
end

local function clearContentAll(content)
    if not content then
        return
    end
    if content.GetRegions then
        for i = select("#", content:GetRegions()), 1, -1 do
            local r = select(i, content:GetRegions())
            if r then
                r:Hide()
                r:SetParent(nil)
            end
        end
    end
    if content.GetChildren then
        for i = select("#", content:GetChildren()), 1, -1 do
            wipeFrameTree(select(i, content:GetChildren()))
        end
    end
end

local function NotifyFlyoutChanged()
    if FluxNCFlyoutOptions and FluxNCFlyoutOptions.NotifyChanged then
        FluxNCFlyoutOptions.NotifyChanged()
    end
end

-- Pixel movement (cursor space) before a press counts as a drag-reorder vs a click-to-hide.
local DRAG_THRESHOLD_SQ = 64

local favoritesListenerRegistered

local function EnsureFavoritesListener()
    if favoritesListenerRegistered then
        return
    end
    local FF = _G.FluxFlyoutFavorites
    if not FF or not FF.RegisterListener then
        return
    end
    favoritesListenerRegistered = true
    FF.RegisterListener(function()
        local w = lastActiveWidget
        if not w or not RefreshPanel or w._fluxReleased then
            return
        end
        if w.frame and w.frame.IsShown and not w.frame:IsShown() then
            return
        end
        RefreshPanel(w)
    end)
end

local function FluxPendingDragOnUpdate(f)
    local w = f._fluxNCPanelOwner
    if not w or not w._fluxPendingDrag then
        return
    end
    local p = w._fluxPendingDrag
    if IsMouseButtonDown("LeftButton") then
        local cx, cy = GetCursorPosition()
        local dx = cx - p.startCX
        local dy = cy - p.startCY
        if not p.dragActive and (dx * dx + dy * dy) >= DRAG_THRESHOLD_SQ then
            p.dragActive = true
            w._fluxDragging = true
            ShowGhost(p.icon)
        end
        if p.dragActive and ghostFrame then
            PlaceGhostAtCursor(ghostFrame)
            if ghostFrame.Raise then
                ghostFrame:Raise()
            end
        end
        return
    end
    f:SetScript("OnUpdate", w._fluxPrevOnUpdate)
    w._fluxPrevOnUpdate = nil
    w._fluxPendingDrag = nil
    GameTooltip:Hide()

    if p.dragActive then
        HideGhost()
        local cx, cy = GetCursorPosition()
        local dragIds = p.ids
        local fromIdx = p.fromIdx
        local specLocal = p.spec
        local slots = p.slots
        w._fluxDragging = false
        local didReorder = false
        if dragIds and specLocal and fromIdx then
            local dropIdx = ComputeDropIndexUniform(slots, cx, cy)
            if dropIdx and dropIdx ~= fromIdx then
                local toIdx = dropIdx
                if fromIdx < toIdx then
                    toIdx = toIdx - 1
                end
                if toIdx < 1 then
                    toIdx = 1
                end
                if toIdx > #dragIds then
                    toIdx = #dragIds
                end
                local val = table.remove(dragIds, fromIdx)
                table.insert(dragIds, toIdx, val)
                specLocal.setOrder(dragIds)
                NotifyFlyoutChanged()
                didReorder = true
            end
        end
        if didReorder then
            RefreshPanel(w)
        end
    else
        w._fluxDragging = false
        local hid = p.spec.getHidden(p.id)
        p.spec.setHidden(p.id, not hid)
        NotifyFlyoutChanged()
        RefreshPanel(w)
    end
end

-- ── Favorites helpers ────────────────────────────────────────────────────────

local function IsFavoritedInPanel(spec, id, entry)
    local FF = _G.FluxFlyoutFavorites
    if not FF or not FF.IsFavoritedAnyMod then
        return false
    end
    if spec.kind == "spell" then
        local linked = entry and entry.linkedSpellIDs or { id }
        for _, sid in ipairs(linked) do
            local cat = "Teleport"
            local sn
            if C_Spell and C_Spell.GetSpellInfo then
                local si = C_Spell.GetSpellInfo(sid)
                sn = si and si.name
            elseif GetSpellInfo then
                sn = GetSpellInfo(sid)
            end
            if sn and sn:find("^Portal:") then cat = "Portal" end
            if FF.IsFavoritedAnyMod(cat, nil, sid) then
                return true
            end
        end
        return false
    end
    local cat = spec.favCategory
    if cat then
        return FF.IsFavoritedAnyMod(cat, id, nil)
    end
    return false
end

local function ToggleFavInPanel(spec, id, entry)
    local FF = _G.FluxFlyoutFavorites
    if not FF then return end

    if spec.kind == "spell" then
        local TP = _G.FluxNCTeleportPortal
        local mode = (TP and TP.GetMode and TP.GetMode()) or "Teleport"
        local targetSid = id
        if entry and entry.linkedSpellIDs then
            for _, sid in ipairs(entry.linkedSpellIDs) do
                local sn
                if C_Spell and C_Spell.GetSpellInfo then
                    local si = C_Spell.GetSpellInfo(sid)
                    sn = si and si.name
                elseif GetSpellInfo then
                    sn = GetSpellInfo(sid)
                end
                if sn then
                    if mode == "Portal" and sn:find("^Portal:") then targetSid = sid; break end
                    if mode == "Teleport" and sn:find("^Teleport:") then targetSid = sid; break end
                end
            end
        end
        local cat = "Teleport"
        local sn2
        if C_Spell and C_Spell.GetSpellInfo then
            local si = C_Spell.GetSpellInfo(targetSid)
            sn2 = si and si.name
        elseif GetSpellInfo then
            sn2 = GetSpellInfo(targetSid)
        end
        if sn2 and sn2:find("^Portal:") then cat = "Portal" end
        if FF.ToggleFavorite then
            -- Omit modKey so favorites use GetCurrentModKey() (Shift/Ctrl/Alt combos) like in-game flyouts.
            FF.ToggleFavorite(cat, targetSid)
        end
        return
    end

    local cat = spec.favCategory
    if cat and FF.ToggleFavorite then
        FF.ToggleFavorite(cat, id)
    end
end

local function GetFavModList(spec, id, entry)
    local FF = _G.FluxFlyoutFavorites
    if not FF or not FF.GetFavoritesTable then
        return {}
    end
    local modList = {}
    local checkPairs = {}
    if spec.kind == "spell" then
        local linked = entry and entry.linkedSpellIDs or { id }
        for _, sid in ipairs(linked) do
            local cat = "Teleport"
            local sn
            if C_Spell and C_Spell.GetSpellInfo then
                local si = C_Spell.GetSpellInfo(sid)
                sn = si and si.name
            elseif GetSpellInfo then
                sn = GetSpellInfo(sid)
            end
            if sn and sn:find("^Portal:") then cat = "Portal" end
            checkPairs[#checkPairs + 1] = { cat = cat, id = sid }
        end
    elseif spec.favCategory then
        checkPairs[#checkPairs + 1] = { cat = spec.favCategory, id = id }
    end

    local favRoot = FF.GetFavoritesTable()
    local seen = {}
    for _, p in ipairs(checkPairs) do
        local favs = favRoot[p.cat]
        if type(favs) == "table" then
            for mk, v in pairs(favs) do
                if type(v) == "number" and v == p.id and not seen[mk] then
                    seen[mk] = true
                    local label = (mk == "" or mk == "nomod") and "no mod" or mk
                    modList[#modList + 1] = label
                end
            end
        end
    end
    table.sort(modList, function(a, b)
        local order = { ["no mod"] = 0, ["ctrl"] = 1, ["shift"] = 2, ["alt"] = 3,
            ["ctrl+shift"] = 4, ["ctrl+alt"] = 5, ["shift+alt"] = 6, ["ctrl+shift+alt"] = 7 }
        return (order[a] or 99) < (order[b] or 99)
    end)
    return modList
end

-- ── Build icon row ──────────────────────────────────────────────────────────

local function BuildRow(widget, parent, spec)
    local slots = {}

    local order = spec.getOrder() or {}
    local merged = mergeEntryOrder(spec.entries, order, spec.getId)
    local ids = {}
    for _, e in ipairs(merged) do
        ids[#ids + 1] = spec.getId(e)
    end

    for i, e in ipairs(merged) do
        local id = spec.getId(e)
        local btn = CreateFrame("Button", nil, parent, backdropTemplate)
        btn:SetSize(CELL, CELL)
        if btn.SetBackdrop then
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false,
                edgeSize = 8,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            btn:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
        end

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(TEX, TEX)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetTexture(e.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local star = btn:CreateTexture(nil, "OVERLAY", nil, 7)
        local starOk = pcall(function() star:SetAtlas("PetJournal-FavoritesIcon", true) end)
        if not starOk then
            star:SetTexture("Interface\\COMMON\\FavoritesIcon")
            star:SetSize(18, 18)
        else
            star:SetSize(18, 18)
        end
        star:SetPoint("TOPLEFT", btn, "TOPLEFT", -3, 3)
        star:Hide()

        local function RefreshStarVisual()
            if IsFavoritedInPanel(spec, id, e) then
                star:Show()
            else
                star:Hide()
            end
        end

        local function RefreshHiddenVisual()
            local hid = spec.getHidden(id)
            if hid then
                icon:SetDesaturated(true)
                icon:SetVertexColor(0.45, 0.45, 0.45)
                if btn.SetBackdropBorderColor then
                    btn:SetBackdropBorderColor(0.55, 0.25, 0.22, 1)
                end
            else
                icon:SetDesaturated(false)
                icon:SetVertexColor(1, 1, 1)
                if btn.SetBackdropBorderColor then
                    btn:SetBackdropBorderColor(0.35, 0.45, 0.55, 1)
                end
            end
            RefreshStarVisual()
        end
        RefreshHiddenVisual()

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if spec.kind == "spell" and id and GameTooltip.SetSpellByID then
                pcall(GameTooltip.SetSpellByID, GameTooltip, id)
            elseif spec.kind == "item" and id then
                GameTooltip:SetItemByID(id)
            else
                GameTooltip:SetText(e.name or "?", 1, 1, 1)
            end
            local favMods = GetFavModList(spec, id, e)
            if #favMods > 0 then
                GameTooltip:AddLine("|cff33ff33Favorite: " .. table.concat(favMods, ", ") .. "|r")
            end
            if spec.kind == "spell" then
                GameTooltip:AddLine("Teleport and portal stay synced.", 0.45, 0.52, 0.6, true)
            end
            GameTooltip:AddLine("Click hide/show. Drag reorder. Right-click favorite.", 0.55, 0.62, 0.7, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        btn:RegisterForClicks("RightButtonUp")
        btn:SetScript("OnClick", function(_, button)
            if button == "RightButton" then
                ToggleFavInPanel(spec, id, e)
                RefreshStarVisual()
                NotifyFlyoutChanged()
            end
        end)

        btn:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" then
                return
            end
            if widget._fluxPendingDrag then
                return
            end
            local cx, cy = GetCursorPosition()
            widget._fluxPendingDrag = {
                startCX = cx,
                startCY = cy,
                fromIdx = i,
                slots = slots,
                ids = ids,
                spec = spec,
                icon = e.icon,
                entry = e,
                id = id,
                dragActive = false,
            }
            if widget.frame then
                widget.frame._fluxNCPanelOwner = widget
                widget._fluxPrevOnUpdate = widget.frame:GetScript("OnUpdate")
                widget.frame:SetScript("OnUpdate", FluxPendingDragOnUpdate)
            end
        end)

        slots[i] = btn
    end

    local fw = 400
    if widget.frame and widget.frame.GetWidth then
        fw = widget.frame:GetWidth() or fw
    end
    local inner = math.max(120, fw - 28)
    local cols = math.max(1, math.floor((inner + GAP) / (CELL + GAP)))
    local h = LayoutRow(parent, slots, cols)
    return h, #merged == 0
end

RefreshPanel = function(widget)
    if not widget or not widget._content then
        return
    end
    if widget._fluxReleased then
        return
    end
    if widget.frame and widget.frame.IsShown and not widget.frame:IsShown() then
        return
    end
    if widget._fluxRefreshing then
        return
    end
    widget._fluxRefreshing = true
    lastActiveWidget = widget
    EnsureFavoritesListener()
    if widget._fluxDragging then
        widget._fluxRefreshing = false
        return
    end

    local content = widget._content
    clearContentAll(content)

    if not FluxNCFlyoutOptions or not FluxNCFlyoutOptions.EnsureDB then
        widget._fluxRefreshing = false
        return
    end
    local db = FluxNCFlyoutOptions.EnsureDB()
    if not db then
        widget._fluxRefreshing = false
        return
    end

    db.classSpells = db.classSpells or { hidden = {}, order = {} }
    db.classSpells.hidden = db.classSpells.hidden or {}
    db.classSpells.order = db.classSpells.order or {}
    local cs = db.classSpells

    local y = -4
    local function nextRow(delta)
        y = y - delta
    end

    local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetBtn:SetSize(320, 22)
    resetBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    resetBtn:SetText("Reset order and hide")
    resetBtn:SetScript("OnClick", function()
        if FluxNCFlyoutOptions.ResetFlyoutLayoutToDefault then
            FluxNCFlyoutOptions.ResetFlyoutLayoutToDefault()
        else
            db.classSpells.hidden = {}
            db.classSpells.order = {}
            db.teleportItems.hidden = {}
            db.teleportItems.order = {}
            db.mountItems.hidden = {}
            db.mountItems.order = {}
            NotifyFlyoutChanged()
        end
        RefreshPanel(widget)
    end)
    nextRow(28)

    local spellEntries = getUnifiedClassSpellEntries()
    pruneClassSpellOrder(cs, spellEntries)

    -- Only show class-spell grid when there is more than one destination (nothing to reorder with a single row).
    if #spellEntries > 1 then
        local labSpells = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        labSpells:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        labSpells:SetText("Class spells. Click hide/show, drag to reorder.")
        nextRow(20)

        local linkedByRep = {}
        for _, e in ipairs(spellEntries) do
            linkedByRep[e.spellID] = e.linkedSpellIDs or { e.spellID }
        end

        local spellParent = CreateFrame("Frame", nil, content)
        spellParent:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        local spellSpec = {
            kind = "spell",
            entries = spellEntries,
            getId = function(e)
                return e.spellID
            end,
            getHidden = function(id)
                local linked = linkedByRep[id] or { id }
                for _, lid in ipairs(linked) do
                    if cs.hidden[lid] then
                        return true
                    end
                end
                return false
            end,
            setHidden = function(id, v)
                local linked = linkedByRep[id] or { id }
                for _, lid in ipairs(linked) do
                    if v then
                        cs.hidden[lid] = true
                    else
                        cs.hidden[lid] = nil
                    end
                end
            end,
            getOrder = function()
                return cs.order
            end,
            setOrder = function(ids)
                local full = {}
                for _, id in ipairs(ids) do
                    full[#full + 1] = id
                    for _, lid in ipairs(linkedByRep[id] or {}) do
                        if lid ~= id then
                            full[#full + 1] = lid
                        end
                    end
                end
                cs.order = full
            end,
        }
        local h1, empty1 = BuildRow(widget, spellParent, spellSpec)
        nextRow(h1 + (empty1 and 20 or 8))

        if empty1 then
            local fs = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            fs:SetText("No class teleports on this character.")
            nextRow(18)
        end
    elseif #spellEntries == 0 then
        local fs = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        fs:SetText("No class teleports on this character.")
        nextRow(18)
    end

    local ti = db.teleportItems or { hidden = {}, order = {} }
    ti.hidden = ti.hidden or {}
    ti.order = ti.order or {}
    db.teleportItems = ti

    local tpEntries = getTeleportItemEntries()
    if #tpEntries > 1 then
        local labTp = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        labTp:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        labTp:SetText("Teleport items")
        nextRow(18)

        local tpParent = CreateFrame("Frame", nil, content)
        tpParent:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        local tpSpec = {
            kind = "item",
            favCategory = "TeleportItem",
            entries = tpEntries,
            getId = function(e)
                return e.itemId
            end,
            getHidden = function(id)
                return ti.hidden[id] and true or false
            end,
            setHidden = function(id, v)
                if v then
                    ti.hidden[id] = true
                else
                    ti.hidden[id] = nil
                end
            end,
            getOrder = function()
                return ti.order
            end,
            setOrder = function(ids)
                ti.order = ids
            end,
        }
        local h3, empty3 = BuildRow(widget, tpParent, tpSpec)
        nextRow(h3 + (empty3 and 20 or 8))

        if empty3 then
            local fs = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            fs:SetText("No teleport items.")
            nextRow(18)
        end
    elseif #tpEntries == 0 then
        local fs = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        fs:SetText("No teleport items.")
        nextRow(18)
    end

    local mi = db.mountItems or { hidden = {}, order = {} }
    mi.hidden = mi.hidden or {}
    mi.order = mi.order or {}
    db.mountItems = mi

    local mpEntries = getMountItemEntries()
    if #mpEntries > 1 then
        local labM = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        labM:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        labM:SetText("Mount items")
        nextRow(18)

        local mpParent = CreateFrame("Frame", nil, content)
        mpParent:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        local mpSpec = {
            kind = "item",
            favCategory = "Mount",
            entries = mpEntries,
            getId = function(e)
                return e.itemId
            end,
            getHidden = function(id)
                return mi.hidden[id] and true or false
            end,
            setHidden = function(id, v)
                if v then
                    mi.hidden[id] = true
                else
                    mi.hidden[id] = nil
                end
            end,
            getOrder = function()
                return mi.order
            end,
            setOrder = function(ids)
                mi.order = ids
            end,
        }
        local h4, empty4 = BuildRow(widget, mpParent, mpSpec)
        nextRow(h4 + (empty4 and 20 or 8))

        if empty4 then
            local fs = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            fs:SetText("No mount items.")
        end
    elseif #mpEntries == 0 then
        local fs = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        fs:SetText("No mount items.")
        nextRow(18)
    end

    local totalH = -y + 24
    content:SetHeight(math.max(totalH, 200))
    -- Cap Ace widget height so Action Bars does not grow into a multi-thousand-pixel layout storm.
    local frameH = math.min(math.max(totalH + 12, 160), 420)
    widget.frame:SetHeight(frameH)
    if widget.SetHeight then
        widget:SetHeight(frameH)
    end
    widget._fluxContentBuilt = true
    widget._fluxRefreshing = false
end

local methods = {
    OnAcquire = function(self)
        self._fluxReleased = false
        self:SetFullWidth(true)
        local frame = self.frame
        frame:EnableMouse(true)
        frame._fluxNCPanelOwner = self

        if not self._content then
            self._content = CreateFrame("Frame", nil, frame)
            self._content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            self._content:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            self._content:SetWidth(400)
        end

        -- Reuse previously built content when Ace re-acquires the pooled widget.
        if self._fluxContentBuilt and self._content then
            local h = self.frame:GetHeight() or 160
            self:SetHeight(h)
            lastActiveWidget = self
            return
        end

        self._fluxAcquireGen = (self._fluxAcquireGen or 0) + 1
        local gen = self._fluxAcquireGen
        -- Defer heavy teleport/item/mount enumeration so Action Bars first paint stays light.
        if Timer and Timer.After then
            Timer.After(0.15, function()
                if self._fluxReleased or self._fluxAcquireGen ~= gen then
                    return
                end
                RefreshPanel(self)
            end)
        else
            RefreshPanel(self)
        end
    end,

    OnRelease = function(self)
        self._fluxReleased = true
        self._fluxAcquireGen = (self._fluxAcquireGen or 0) + 1
        self._fluxRefreshing = false
        self._fluxDragging = false
        self._fluxPendingDrag = nil
        if self.frame then
            self.frame:SetScript("OnUpdate", self._fluxPrevOnUpdate)
            self._fluxPrevOnUpdate = nil
        end
        HideGhost()
        if lastActiveWidget == self then
            lastActiveWidget = nil
        end
    end,

    OnWidthSet = function(self, width)
        if type(width) == "number" and width > 40 and self._content then
            self._content:SetWidth(width - 8)
        end
    end,

    SetLabel = function() end,
    SetText = function() end,
    SetFontObject = function() end,
}

local function Constructor()
    local name = "AceGUI30FluxNCFlyoutPanel" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:EnableMouse(true)
    frame:Hide()

    local widget = {
        frame = frame,
        type = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

function _G.FluxNCFlyoutPanel_RequestRefresh()
    local w = lastActiveWidget
    if not w or not RefreshPanel or w._fluxReleased then
        return
    end
    if w.frame and w.frame.IsShown and not w.frame:IsShown() then
        return
    end
    RefreshPanel(w)
end

function _G.FluxNCFlyoutPanel_OnOptionsClosed()
    lastActiveWidget = nil
end
