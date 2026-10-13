-- Binding/UI/Editor/Panels.lua
-- Tab panels: Cast / Multi-cast / Targets / Conditions / Forms / Status / Bar & Badges.
-- Every control writes straight into the current form sub-profile and commits
-- (chord-scoped apply); Status shows the ACTUAL generated macros.
-- Forms tab: Active (keypress + UF) / page enable / copy — form-related only.

local addonName, ns = ...

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI then return end

local Editor = ns.FluxBindingEditor
if not Editor then return end

local DB = ns.FluxBindingDB3
local Action = ns.FluxBindingAction
local Forms = ns.FluxBindingForms
local Conditions = ns.FluxBindingConditions
local S = Editor.S
local L = Editor.L
local FLUX_API = _G.FLUX_API or {}

local function OnBarSelfLabel(kind, longForm)
    if kind == "item" then
        return longForm
            and (L["this item is on the bar"] or "this item is on the bar")
            or (L["this item"] or "this item")
    end
    if kind == "spell" then
        return longForm
            and (L["this spell is on the bar"] or "this spell is on the bar")
            or (L["this spell"] or "this spell")
    end
    return longForm
        and (L["this action is on the bar"] or "this action is on the bar")
        or (L["this action"] or "this action")
end

-- ---------------------------------------------------------------------------
-- Tab host
-- ---------------------------------------------------------------------------

local TAB_LIST = {
    { value = "cast", text = "Cast" },
    { value = "multicast", text = "Multi-cast" },
    { value = "targets", text = "Targets" },
    { value = "conditions", text = "Conditions" },
    { value = "forms", text = "Forms" },
    { value = "status", text = "Status" },
    { value = "badges", text = "Bar & Badges" },
}

local function EditorCanShowMultiCastTab()
    local binding = Editor.GetBinding()
    if not binding and S.subject then
        binding = { action = S.subject, uid = S.currentUid, placeId = S.placeId }
    end
    local FluxBinding = _G.FluxBinding
    if binding and FluxBinding and FluxBinding.CanUseMultiCastExtras
        and FluxBinding.CanUseMultiCastExtras(binding) then
        return true
    end
    local sub = Editor.GetSub()
    if sub and DB.GetMacroExtras and #DB.GetMacroExtras(sub) > 0 then
        return true
    end
    return false
end

--- AceGUI ScrollFrame's stock FixScroll calls DoLayout when the scrollbar
--- appears/disappears, which rebuilds content and snaps scroll back to the top
--- (feels like "scroll down forces go up"). Replace it with a layout-safe pin.
local function PinAceScrollFrameFixScroll(scroll)
    if not scroll or not scroll.scrollframe or not scroll.scrollbar then
        return
    end
    scroll.scrollBarShown = false
    scroll.FixScroll = function(self)
        if self.updateLock then
            return
        end
        self.updateLock = true
        local status = self.status or self.localstatus
        local viewH = self.scrollframe:GetHeight() or 0
        local contentH = self.content and self.content:GetHeight() or 0
        if contentH < viewH + 2 then
            if self.scrollBarShown then
                self.scrollBarShown = false
                self.scrollbar:Hide()
                self.scrollframe:SetPoint("BOTTOMRIGHT", 0, 0)
                if self.content.original_width then
                    self.content.width = self.content.original_width
                end
            end
            self.scrollbar:SetValue(0)
            self:SetScroll(0)
        else
            if not self.scrollBarShown then
                self.scrollBarShown = true
                self.scrollbar:Show()
                self.scrollframe:SetPoint("BOTTOMRIGHT", -20, 0)
                if self.content.original_width then
                    self.content.width = self.content.original_width - 20
                end
            end
            local offset = (status and status.offset) or 0
            local diff = contentH - viewH
            local value = (diff > 0) and (offset / diff * 1000) or 0
            if value > 1000 then
                value = 1000
            end
            if value < 0 then
                value = 0
            end
            self.scrollbar:SetValue(value)
            self:SetScroll(value)
        end
        self.updateLock = nil
    end

    -- Correct wheel direction using content/viewport (stock MoveScroll swaps names
    -- and relies on a negative diff — fragile after our FixScroll pin).
    scroll.MoveScroll = function(self, wheelDelta)
        local status = self.status or self.localstatus
        if not status or not self.scrollBarShown then
            return
        end
        local viewH = self.scrollframe:GetHeight() or 0
        local contentH = self.content and self.content:GetHeight() or 0
        local diff = contentH - viewH
        if diff <= 0 then
            return
        end
        -- WoW: wheelDelta > 0 = scroll up → decrease scrollvalue.
        local step = (wheelDelta > 0) and -1 or 1
        local next = (status.scrollvalue or 0) + step * (1000 / (diff / 45))
        if next < 0 then
            next = 0
        end
        if next > 1000 then
            next = 1000
        end
        self.scrollbar:SetValue(next)
    end
end

function Editor.BuildTabs(root)
    local tabs = AceGUI:Create("FluxBindingTabGroup") or AceGUI:Create("TabGroup")
    -- Fill remaining editor height; each tab gets its own ScrollFrame so Cast /
    -- Targets / Conditions can scroll to the bottom inside the Binding pane.
    tabs:SetLayout("Fill")
    tabs:SetFullWidth(true)
    tabs:SetFullHeight(true)
    tabs:SetAutoAdjustHeight(false)
    local list = {}
    for _, def in ipairs(TAB_LIST) do
        if def.value == "multicast" and not EditorCanShowMultiCastTab() then
            -- Native-alone bar spells only.
        else
            list[#list + 1] = {
                value = def.value,
                text = L["editor_tab_" .. def.value] or def.text,
            }
        end
    end
    tabs:SetTabs(list)
    tabs:SetCallback("OnGroupSelected", function(container, _, tab)
        S.currentTab = tab
        container:ReleaseChildren()
        local scroll = AceGUI:Create("ScrollFrame")
        scroll:SetLayout("Flow")
        scroll:SetFullWidth(true)
        scroll:SetFullHeight(true)
        PinAceScrollFrameFixScroll(scroll)
        container:AddChild(scroll)
        S.tabScroll = scroll
        if tab == "cast" then
            Editor.BuildCastPanel(scroll)
        elseif tab == "multicast" then
            Editor.BuildMultiCastPanel(scroll)
        elseif tab == "targets" then
            Editor.BuildTargetsPanel(scroll)
        elseif tab == "conditions" then
            Editor.BuildConditionsPanel(scroll)
        elseif tab == "forms" then
            Editor.BuildFormsPanel(scroll)
        elseif tab == "status" then
            Editor.BuildStatusPanel(scroll)
        elseif tab == "badges" then
            Editor.BuildBadgesPanel(scroll)
        end
        -- Ace needs a layout pass after the panel widgets are added.
        if scroll.DoLayout then
            scroll:DoLayout()
        end
    end)
    root:AddChild(tabs)
    local want = S.currentTab or "cast"
    if want == "multicast" and not EditorCanShowMultiCastTab() then
        want = "cast"
        S.currentTab = "cast"
    end
    tabs:SelectTab(want)
end

-- ---------------------------------------------------------------------------
-- Shared control helpers
-- ---------------------------------------------------------------------------

local function AddHeading(container, text)
    local h = AceGUI:Create("Heading")
    h:SetText(text)
    h:SetFullWidth(true)
    container:AddChild(h)
    return h
end

local function AddCheck(container, label, get, set, width)
    local cb = AceGUI:Create("CheckBox")
    cb:SetLabel(label)
    cb:SetValue(get() and true or false)
    cb:SetWidth(width or 330)
    cb:SetCallback("OnValueChanged", function(_, _, val)
        set(val and true or false)
        Editor.Commit()
    end)
    container:AddChild(cb)
    return cb
end

local function AddDropdown(container, label, list, order, get, set, width)
    local dd = AceGUI:Create("FluxBlizzardDropdown") or AceGUI:Create("Dropdown")
    dd:SetLabel(label)
    dd:SetList(list, order)
    dd:SetValue(get())
    dd:SetWidth(width or 180)
    dd:SetCallback("OnValueChanged", function(_, _, val)
        set(val)
        Editor.Commit()
    end)
    container:AddChild(dd)
    return dd
end

-- ---------------------------------------------------------------------------
-- Cast panel
-- ---------------------------------------------------------------------------

local CAST_FLAGS = {
    { key = "interrupt",           label = "Interrupt current cast" },
    { key = "startAutoAttack",     label = "Start auto attacks" },
    { key = "startPetAttack",      label = "Start pet attacks" },
    { key = "stopSpellTarget",     label = "Clear blue casting cursor (/stopspelltarget)" },
    { key = "cancelQueuedSpell",   label = "Override queued spell (/cancelqueuedspell)" },
    { key = "cancelForm",          label = "Exit shapeshift form first" },
    { key = "preventToggle",       label = "Prevent toggling off (!spell)" },
    { key = "castAtCursor",        label = "Cast at cursor position (ground AoE)" },
    { key = "spellIncludeSubtext", label = "Include spell subtext / rank (Classic)", classicOnly = true },
}

function Editor.BuildCastPanel(container)
    local sub = Editor.GetSub()
    if not sub then return end
    AddHeading(container, L["Cast behaviour"] or "Cast behaviour")
    for _, def in ipairs(CAST_FLAGS) do
        local show = true
        local rankClient = FLUX_API.isCamelot or FLUX_API.isForever
            or FLUX_API.supportsPerRankSpellBarFeatures
        if def.retailOnly and not FLUX_API.isRetail then show = false end
        if def.classicOnly and FLUX_API.isRetail and not rankClient then show = false end
        if show then
            AddCheck(container, L[def.label] or def.label,
                function() return sub.action[def.key] end,
                function(v)
                    local esub = Editor.EnsureEditableSub()
                    if esub then esub.action[def.key] = v end
                end)
        end
    end

    AddCheck(container, L["Cancel an aura"] or "Cancel an aura before cast",
        function() return sub.action.cancelAura end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then esub.action.cancelAura = v and true or false end
        end)

    local auraBox = AceGUI:Create("EditBox")
    auraBox:SetLabel(L["Target aura"] or "Aura name or spell ID")
    auraBox:SetText(sub.action.cancelAuraName or "")
    auraBox:SetFullWidth(true)
    auraBox:SetDisabled(not sub.action.cancelAura)
    auraBox:SetCallback("OnEnterPressed", function(_, _, val)
        local esub = Editor.EnsureEditableSub()
        if esub then
            esub.action.cancelAuraName = type(val) == "string" and val or ""
            -- Typing an aura implies enabling cancel-aura.
            if esub.action.cancelAuraName:match("%S") then
                esub.action.cancelAura = true
            end
            Editor.Commit()
        end
    end)
    container:AddChild(auraBox)
    local auraHint = AceGUI:Create("Label")
    auraHint:SetFullWidth(true)
    auraHint:SetFontObject(GameFontDisableSmall)
    auraHint:SetText(L["Enter the aura name or spell ID."]
        or "Emits /cancelaura before the cast. Use the aura name, or a spell ID (resolved to name).")
    container:AddChild(auraHint)

    AddHeading(container, L["Macro options"] or "Macro options")
    local prefix = AceGUI:Create("EditBox")
    prefix:SetLabel(L["Custom prefix lines"] or "Custom prefix line (added before the /cast)")
    prefix:SetText(sub.macro and sub.macro.prefix or "")
    prefix:SetFullWidth(true)
    prefix:SetCallback("OnEnterPressed", function(_, _, val)
        local esub = Editor.EnsureEditableSub()
        if esub then
            esub.macro = esub.macro or {}
            esub.macro.prefix = val or ""
            Editor.Commit()
        end
    end)
    container:AddChild(prefix)

    -- Classic: sync settings across all ranks of this spell name.
    local binding = Editor.GetBinding()
    if binding and binding.action and binding.action.type == "spell"
        and Action.ShouldOfferRankSync and Action.ShouldOfferRankSync() then
        AddHeading(container, L["action_lbl_rank_sync"] or "Spell ranks")
        local rankLine = Action.GetNameWithRank and Action.GetNameWithRank(binding.action)
            or Action.GetName(binding.action)
        local rankLbl = AceGUI:Create("Label")
        rankLbl:SetText(rankLine or "")
        rankLbl:SetFullWidth(true)
        container:AddChild(rankLbl)
        AddCheck(container,
            L["rank_sync_by_name"] or "Sync all ranks (same spell name)",
            function()
                return Action.IsRankSyncByName and Action.IsRankSyncByName(binding.action)
            end,
            function(v)
                local b = Editor.GetBinding()
                if not b or not b.action or not b.action.id then return end
                Action.SetRankSyncByName(b.action.id, v and true or false)
                -- Refresh subject lookup under new family key.
                Editor.SetSubject(b.action)
            end, 360)
        local hint = AceGUI:Create("Label")
        hint:SetText(L["rank_sync_by_name_desc"]
            or "One shared profile for every rank of this spell. Turn off to edit ranks separately.")
        hint:SetFullWidth(true)
        container:AddChild(hint)

        local removeRank = AceGUI:Create("Button")
        removeRank:SetText(L["remove_rank"] or "Remove this rank")
        removeRank:SetWidth(160)
        removeRank:SetCallback("OnClick", function()
            local b = Editor.GetBinding()
            if not b or not b.action or not b.action.id then return end
            local sid = b.action.id
            if Action.RemoveRank and Action.RemoveRank(sid) then
                -- Prefer another remaining rank of the same name, else pending.
                local nameKey = Action.SpellNameKey and Action.SpellNameKey(sid)
                local nextDesc
                if nameKey and Action.EnumerateSpellIdsForNameKey then
                    local ranks = Action.EnumerateSpellIdsForNameKey(nameKey)
                    for i = 1, #ranks do
                        if ranks[i] ~= sid then
                            nextDesc = Action.Spell(ranks[i])
                            break
                        end
                    end
                end
                if nextDesc then
                    Editor.SetSubject(nextDesc)
                else
                    S.pending = true
                    S.subject = nil
                    S.subjectKey = nil
                    S.uids = {}
                    S.currentUid = nil
                    Editor.Redraw()
                end
                if _G.FluxBindingBrowser_Refresh then
                    pcall(_G.FluxBindingBrowser_Refresh)
                end
            end
        end)
        container:AddChild(removeRank)
        local removeHint = AceGUI:Create("Label")
        removeHint:SetText(L["remove_rank_desc"]
            or "Deletes the binding row for this spell rank. If ranks were synced, they are unsynced first.")
        removeHint:SetFullWidth(true)
        container:AddChild(removeHint)
    end
end

-- ---------------------------------------------------------------------------
-- Targets panel
-- ---------------------------------------------------------------------------

local HOSTILITY_LIST = { ANY = "Friendly or hostile", FRIENDLY = "Friendly", HOSTILE = "Hostile" }
local HOSTILITY_ORDER = { "ANY", "FRIENDLY", "HOSTILE" }
local VITALS_LIST = { ANY = "Alive or dead", ALIVE = "Alive", DEAD = "Dead" }
local VITALS_ORDER = { "ANY", "ALIVE", "DEAD" }
local UNIT_LIST = {
    DEFAULT = "Default (current target)",
    PLAYER = "Player (you)",
    TARGET = "Target",
    MOUSEOVER = "Mouseover",
    FOCUS = "Focus",
    PET = "Pet",
    TARGETTARGET = "Target of target",
    CURSOR = "Cursor (ground)",
}
local UNIT_ORDER = { "DEFAULT", "PLAYER", "TARGET", "MOUSEOVER", "FOCUS", "PET", "TARGETTARGET", "CURSOR" }


-- ---------------------------------------------------------------------------
-- Multi-cast cast-order: AceGUI Icon strip (stance-style drag).
-- Custom CreateFrame widgets do not receive clicks inside Binding ScrollFrame;
-- AceGUI Icon is a real Button and works here (same as Targets controls).
-- ---------------------------------------------------------------------------

local MC_ICON = 28
local MC_DRAG_THRESHOLD = 6
local mcGhost, mcGhostTex
local mcDrag = nil -- { from, frames, rows, startX, startY, moved, texture, sourceFrame }
local mcDragDriver
local MC_FinishDrag

local function MC_HideGhost()
    if mcGhost then mcGhost:Hide() end
end

local function MC_CursorPos()
    if GetScaledCursorPosition then
        return GetScaledCursorPosition()
    end
    local s = UIParent:GetEffectiveScale() or 1
    local cx, cy = GetCursorPosition()
    return cx / s, cy / s
end

local function MC_ShowGhost(tex)
    if not mcGhost or not mcGhostTex then
        if mcGhost then
            -- Partial create from a prior error — rebuild cleanly.
            mcGhost:Hide()
            mcGhost = nil
            mcGhostTex = nil
        end
        mcGhost = CreateFrame("Frame", "FluxMultiCastAceOrderGhost", UIParent)
        mcGhost:SetFrameStrata("TOOLTIP")
        mcGhost:SetFrameLevel(20000) -- must be <= 65535
        mcGhost:EnableMouse(false)
        mcGhost:SetSize(36, 36)
        if mcGhost.SetToplevel then
            mcGhost:SetToplevel(true)
        end
        local bg = mcGhost:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.65)
        mcGhostTex = mcGhost:CreateTexture(nil, "ARTWORK")
        mcGhostTex:SetPoint("TOPLEFT", 2, -2)
        mcGhostTex:SetPoint("BOTTOMRIGHT", -2, 2)
        mcGhostTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    if tex and tex ~= "" then
        mcGhostTex:SetTexture(tex)
    else
        mcGhostTex:SetTexture(134400)
    end
    local x, y = MC_CursorPos()
    mcGhost:ClearAllPoints()
    mcGhost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x + 16, y - 16)
    mcGhost:Show()
    if mcGhost.Raise then mcGhost:Raise() end
end

local function MC_PlaceGhost()
    if not mcGhost or not mcGhost:IsShown() then return end
    local x, y = MC_CursorPos()
    mcGhost:ClearAllPoints()
    mcGhost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x + 16, y - 16)
    if mcGhost.Raise then mcGhost:Raise() end
end

local function MC_ComputeDropIndex(frames, cx, cy)
    local n = #frames
    if n == 0 then return 1 end
    cx = cx or select(1, GetCursorPosition())
    cy = cy or select(2, GetCursorPosition())
    local best, bestD = 1, math.huge
    for i = 1, n do
        local f = frames[i]
        if f and f:IsShown() and f.GetScaledRect then
            local l, b, w, h = f:GetScaledRect()
            if l and w and h and w > 0 then
                local mx, my = l + w * 0.5, b + h * 0.5
                local d = (cx - mx) ^ 2 + (cy - my) ^ 2
                if d < bestD then bestD, best = d, i end
            end
        end
    end
    local f = frames[best]
    if f and f.GetScaledRect then
        local l, b, w, h = f:GetScaledRect()
        -- Column layout: insert before/after by vertical mid.
        if b and h then
            local mid = b + h * 0.5
            return (cy > mid) and best or math.min(best + 1, n + 1)
        end
    end
    return best
end

local function MC_CloneRows(rows)
    local out = {}
    for i = 1, #(rows or {}) do
        local r = rows[i]
        if r and r.kind == "main" then
            out[i] = { kind = "main", action = r.action }
        elseif r and r.kind == "extra" and type(r.e) == "table" then
            out[i] = {
                kind = "extra",
                extraIndex = r.extraIndex,
                e = { type = r.e.type, id = r.e.id, name = r.e.name },
            }
        end
    end
    return out
end

local function MC_RowIcon(row)
    if not row then return 134400 end
    if row.kind == "main" and row.action and Action and Action.GetIcon then
        return Action.GetIcon(row.action) or 134400
    end
    if row.kind == "extra" and row.e and DB.GetMacroExtraIcon then
        return DB.GetMacroExtraIcon(row.e) or 134400
    end
    return 134400
end

local function MC_RowLabel(row)
    if not row then return "?" end
    if row.kind == "main" then
        local name = "?"
        if row.action and Action and Action.GetName then
            name = Action.GetName(row.action) or name
        elseif row.action and row.action.name then
            name = row.action.name
        end
        return name .. " " .. (L["multicast_main_mark"] or "(main)")
    end
    if row.e and DB.GetMacroExtraLabel then
        local name = DB.GetMacroExtraLabel(row.e)
        local avail = not DB.IsMacroExtraAvailable or DB.IsMacroExtraAvailable(row.e)
        if not avail then
            local skip = L["multicast_extras_skipped"] or "skipped"
            if row.e.type == "slot" then
                skip = L["multicast_extras_unequipped"] or "unequipped"
            elseif row.e.type == "item" then
                skip = L["multicast_extras_missing"] or "missing"
            end
            name = name .. " (" .. skip .. ")"
        end
        return name
    end
    return "?"
end

local function MC_Short(text, n)
    n = n or 9
    text = tostring(text or "?"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    if #text > n then return text:sub(1, n - 1) .. "…" end
    return text
end

local function MC_PersistAndReload(rows)
    local esub = Editor.EnsureEditableSub()
    if not esub then return end
    DB.ApplyMultiCastOrderRows(esub, rows)
    S.currentTab = "multicast"
    local FB = _G.FluxBinding
    if FB and FB.NotifyBindingChanged then
        FB.NotifyBindingChanged(S.currentUid)
    end
    Editor.Commit()
end

local function MC_EnsureDragDriver()
    if mcDragDriver then return mcDragDriver end
    mcDragDriver = CreateFrame("Frame", "FluxMultiCastOrderDragDriver", UIParent)
    mcDragDriver:Hide()
    mcDragDriver:SetScript("OnUpdate", function()
        if not mcDrag then
            mcDragDriver:Hide()
            return
        end
        local x, y = MC_CursorPos()
        if not mcDrag.moved then
            local dx = x - (mcDrag.startX or x)
            local dy = y - (mcDrag.startY or y)
            if (dx * dx + dy * dy) >= (MC_DRAG_THRESHOLD * MC_DRAG_THRESHOLD) then
                mcDrag.moved = true
                if mcDrag.sourceFrame then
                    mcDrag.sourceFrame:SetAlpha(0.42)
                end
                MC_ShowGhost(mcDrag.texture)
            end
        end
        if mcDrag.moved then
            MC_PlaceGhost()
        end
        if not IsMouseButtonDown("LeftButton") then
            MC_FinishDrag()
        end
    end)
    return mcDragDriver
end

MC_FinishDrag = function()
    local d = mcDrag
    mcDrag = nil
    MC_HideGhost()
    if mcDragDriver then mcDragDriver:Hide() end
    if not d then return end
    if d.sourceFrame then
        d.sourceFrame:SetAlpha(1)
    end
    -- Click without drag: do nothing.
    if not d.moved then
        return
    end
    if d.from and d.frames and d.rows then
        local cx, cy = GetCursorPosition()
        local to = MC_ComputeDropIndex(d.frames, cx, cy)
        if to and to ~= d.from and to ~= d.from + 1 then
            local rows = MC_CloneRows(d.rows)
            local entry = table.remove(rows, d.from)
            local insertAt = to
            if to > d.from then insertAt = to - 1 end
            if insertAt < 1 then insertAt = 1 end
            if insertAt > #rows + 1 then insertAt = #rows + 1 end
            table.insert(rows, insertAt, entry)
            -- Keep exactly one main (bar action); only its cast position changes.
            local mainCount = 0
            for i = 1, #rows do
                if rows[i] and rows[i].kind == "main" then mainCount = mainCount + 1 end
            end
            if mainCount == 1 then
                MC_PersistAndReload(rows)
            end
        end
    end
end

--- Build cast-order column (smaller icons, full names, drag + right-click remove).
local function MC_BuildOrderStrip(container, binding, sub, canAdd, maxExtras, suppressSubjectDrop)
    local rows = DB.BuildMultiCastOrderRows(binding, sub)
    local strip = AceGUI:Create("InlineGroup")
    strip:SetTitle(L["multicast_extras_list_heading"] or "Cast order")
    strip:SetFullWidth(true)
    strip:SetLayout("List")
    container:AddChild(strip)

    local tip = AceGUI:Create("Label")
    tip:SetFullWidth(true)
    tip:SetFontObject(GameFontHighlightSmall)
    tip:SetText(L["multicast_order_tip"]
        or "Drag to set cast order (including the action-bar main). The bar always keeps that main spell. Right-click an extra to remove.")
    strip:AddChild(tip)

    local frames = {}
    local host = strip.frame

    local function TryDropOnIndex(insertAt)
        if not canAdd then return false end
        if not Action or not Action.FromCursor then return false end
        local desc = Action.FromCursor()
        if not desc or (desc.type ~= "spell" and desc.type ~= "item") then return false end
        local list = DB.GetMacroExtras(Editor.GetSub() or sub)
        if #list >= maxExtras then return true end
        if suppressSubjectDrop then suppressSubjectDrop() end
        if ClearCursor then ClearCursor() end
        local newRows = MC_CloneRows(rows)
        table.insert(newRows, insertAt, {
            kind = "extra",
            e = {
                type = desc.type,
                id = desc.id,
                name = (Action.GetName and Action.GetName(desc)) or desc.name,
            },
        })
        MC_PersistAndReload(newRows)
        return true
    end

    if host then
        host:EnableMouse(true)
        host:SetScript("OnReceiveDrag", function()
            TryDropOnIndex(#rows + 1)
        end)
    end

    for i = 1, #rows do
        local row = rows[i]
        local isMain = row.kind == "main"
        local avail = isMain or (not DB.IsMacroExtraAvailable) or DB.IsMacroExtraAvailable(row.e)
        local rowIndex = i

        local cell = AceGUI:Create("SimpleGroup")
        cell:SetLayout("Flow")
        cell:SetFullWidth(true)
        strip:AddChild(cell)

        local ic = AceGUI:Create("Icon")
        ic:SetImage(MC_RowIcon(row))
        ic:SetImageSize(MC_ICON, MC_ICON)
        ic:SetWidth(MC_ICON + 8)
        ic:SetHeight(MC_ICON + 8)
        ic:SetLabel("")
        if not avail and ic.image then
            ic.image:SetVertexColor(0.55, 0.55, 0.55, 1)
        elseif isMain and ic.image then
            ic.image:SetVertexColor(1, 0.92, 0.55, 1)
        end
        cell:AddChild(ic)

        local nameLbl = AceGUI:Create("Label")
        nameLbl:SetFontObject(GameFontHighlightSmall)
        nameLbl:SetWidth(280)
        if isMain then
            local base = "?"
            if row.action and Action and Action.GetName then
                base = Action.GetName(row.action) or base
            elseif row.action and row.action.name then
                base = row.action.name
            end
            nameLbl:SetText(("%d. %s %s"):format(i, base, L["multicast_main_bar_mark"] or "(action bar)"))
            nameLbl:SetColor(0.95, 0.85, 0.45)
        else
            nameLbl:SetText(("%d. %s"):format(i, MC_RowLabel(row)))
            if not avail then
                nameLbl:SetColor(0.65, 0.65, 0.65)
            end
        end
        cell:AddChild(nameLbl)

        local frame = ic.frame
        frames[i] = frame
        if frame then
            frame:EnableMouse(true)
            frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            frame:SetScript("OnClick", function(_, btn)
                AceGUI:ClearFocus()
                if btn == "RightButton" then
                    if isMain or mcDrag then return end
                    local newRows = MC_CloneRows(rows)
                    if newRows[rowIndex] and newRows[rowIndex].kind == "extra" then
                        table.remove(newRows, rowIndex)
                        MC_PersistAndReload(newRows)
                    end
                end
            end)
            frame:SetScript("OnEnter", function()
                if mcDrag then return end
                GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                if isMain then
                    local base = "?"
                    if row.action and Action and Action.GetName then
                        base = Action.GetName(row.action) or base
                    end
                    GameTooltip:SetText(base .. " " .. (L["multicast_main_bar_mark"] or "(action bar)"), 1, 1, 1)
                    GameTooltip:AddLine(L["multicast_main_tip"] or "Native bar action — drag to cast extras before or after it.", 0.55, 0.62, 0.7, true)
                else
                    GameTooltip:SetText(MC_RowLabel(row), 1, 1, 1)
                    GameTooltip:AddLine(L["multicast_order_tip"] or "Drag to reorder. Right-click to remove.", 0.55, 0.62, 0.7, true)
                end
                GameTooltip:Show()
            end)
            frame:SetScript("OnLeave", function()
                if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
            end)
            frame:SetScript("OnMouseDown", function(_, btn)
                if btn ~= "LeftButton" then return end
                if TryDropOnIndex(rowIndex) then return end
                if mcDrag then return end
                local sx, sy = MC_CursorPos()
                mcDrag = {
                    from = rowIndex,
                    frames = frames,
                    rows = rows,
                    startX = sx,
                    startY = sy,
                    moved = false,
                    texture = MC_RowIcon(row),
                    sourceFrame = frame,
                }
                MC_EnsureDragDriver():Show()
            end)
            frame:SetScript("OnReceiveDrag", function()
                TryDropOnIndex(rowIndex)
            end)
        end
    end

    if #rows == 0 then
        local empty = AceGUI:Create("Label")
        empty:SetFullWidth(true)
        empty:SetText(L["multicast_order_empty"] or "Drop spells or items here to build cast order.")
        strip:AddChild(empty)
    end
end

function Editor.BuildMultiCastPanel(container)
    local sub = Editor.GetSub()
    if not sub then return end

    local binding = Editor.GetBinding()
    if not binding and S.subject then
        binding = { action = S.subject, uid = S.currentUid, placeId = S.placeId }
    end
    local FluxBinding = _G.FluxBinding
    local canExtras = binding and FluxBinding and FluxBinding.CanUseMultiCastExtras
        and FluxBinding.CanUseMultiCastExtras(binding)

    AddHeading(container, L["multicast_extras_heading"] or "Multi-cast extras")

    if not canExtras then
        local blocked = AceGUI:Create("Label")
        blocked:SetFullWidth(true)
        blocked:SetFontObject(GameFontHighlightSmall)
        blocked:SetText(L["multicast_extras_unavailable"]
            or "Multi-cast extras only apply to a native action-bar spell that does not share its key with another binding. Existing extras below are kept until you remove them.")
        container:AddChild(blocked)
    else
        local help = AceGUI:Create("Label")
        help:SetFullWidth(true)
        help:SetFontObject(GameFontHighlightSmall)
        help:SetText(L["multicast_extras_help"]
            or "Drop spells or items onto the cast order. Drag to reorder (including the main bar action). Right-click an extra to remove. Corner badges show the first 3 available.")
        container:AddChild(help)
    end

    local maxExtras = (DB and DB.MAX_MACRO_EXTRAS) or 20
    local extras = DB.GetMacroExtras(sub)

    local function SuppressSubjectDrop()
        S._suppressSubjectDrop = true
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                S._suppressSubjectDrop = nil
            end)
        else
            S._suppressSubjectDrop = nil
        end
    end

    local function SlotName(id)
        -- Prefer numbered names for rings/trinkets (Blizzard globals omit 1/2).
        local numbered = L["multicast_slot_" .. tostring(id)]
        if type(numbered) == "string" and numbered ~= "" then
            return ("%s (#%d)"):format(numbered, id)
        end
        local slotGlobals = {
            [1] = "HEADSLOT", [2] = "NECKSLOT", [3] = "SHOULDERSLOT", [4] = "SHIRTSLOT",
            [5] = "CHESTSLOT", [6] = "WAISTSLOT", [7] = "LEGSSLOT", [8] = "FEETSLOT",
            [9] = "WRISTSLOT", [10] = "HANDSSLOT", [11] = "FINGER0SLOT", [12] = "FINGER1SLOT",
            [13] = "TRINKET0SLOT", [14] = "TRINKET1SLOT", [15] = "BACKSLOT",
            [16] = "MAINHANDSLOT", [17] = "SECONDARYHANDSLOT", [18] = "RANGEDSLOT", [19] = "TABARDSLOT",
        }
        local loc = _G[slotGlobals[id]]
        if type(loc) == "string" and loc ~= "" then
            return ("%s (#%d)"):format(loc, id)
        end
        return (L["multicast_slot_fmt"] or "Equip slot %d"):format(id)
    end

    local function AddSlotExtra(id)
        if not canExtras then return end
        id = tonumber(id)
        if not id or id < 1 or id > 19 then return end
        local esub = Editor.EnsureEditableSub()
        if not esub then return end
        local list = DB.GetMacroExtras(esub)
        if #list >= maxExtras then return end
        for i = 1, #list do
            local e = list[i]
            if e and e.type == "slot" and tonumber(e.id) == id then
                return
            end
        end
        list[#list + 1] = { type = "slot", id = id }
        DB.SetMacroExtras(esub, list)
        S.currentTab = "multicast"
        Editor.Commit()
    end

    -- Equipment slot: normal AceGUI Dropdown (same pattern as Targets).
    if canExtras then
        local slotOrder = { 13, 14, 11, 12, 16, 17, 1, 2, 3, 5, 6, 7, 8, 9, 10, 15, 4, 18, 19 }
        local slotList = { [0] = L["multicast_add_equip_choose"] or "Choose a slot…" }
        local ddOrder = { 0 }
        for i = 1, #slotOrder do
            local id = slotOrder[i]
            slotList[id] = SlotName(id)
            ddOrder[#ddOrder + 1] = id
        end
        local slotDd = AddDropdown(container,
            L["multicast_add_equip_slot"] or "Add equipment slot",
            slotList,
            ddOrder,
            function() return 0 end,
            function(val)
                local id = tonumber(val)
                if id and id >= 1 and id <= 19 then
                    AddSlotExtra(id)
                end
            end,
            280)
        if slotDd and slotDd.SetDisabled and #extras >= maxExtras then
            slotDd:SetDisabled(true)
        end
        local slotHelp = AceGUI:Create("Label")
        slotHelp:SetFullWidth(true)
        slotHelp:SetFontObject(GameFontHighlightSmall)
        slotHelp:SetText(L["multicast_add_equip_slot_help"]
            or "Pick a paperdoll slot (Trinket 1/2, Finger 1/2, …). Adds a /use N line; unequipped slots stay in order but are skipped until equipped.")
        container:AddChild(slotHelp)
    end

    local badgeNote = AceGUI:Create("Label")
    badgeNote:SetFullWidth(true)
    badgeNote:SetFontObject(GameFontHighlightSmall)
    badgeNote:SetText(L["multicast_extras_badge_note"]
        or "Corner badges use the first 3 available extras. Missing items and unequipped slots stay in the order but are skipped in the cast macro until available. Drag the main action to cast extras before or after it.")
    container:AddChild(badgeNote)

    if canExtras and #extras >= maxExtras then
        local full = AceGUI:Create("Label")
        full:SetFullWidth(true)
        full:SetFontObject(GameFontHighlightSmall)
        full:SetText((L["multicast_extras_full"] or "Maximum of %d extras reached."):format(maxExtras))
        container:AddChild(full)
    end

    MC_BuildOrderStrip(container, binding, sub, canExtras, maxExtras, SuppressSubjectDrop)
end

function Editor.BuildTargetsPanel(container)
    local sub = Editor.GetSub()
    local binding = Editor.GetBinding()
    if not sub then return end

    AddHeading(container, L["Activate on"] or "Activate on")
    AddCheck(container, L["Unit frame (hovercast)"] or "Unit frame / mouseover hover (hovercast)",
        -- V10 parity: nil means enabled (older DB3 rows may omit the field)
        function() return sub.targets.hovercastEnabled ~= false end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then esub.targets.hovercastEnabled = v end
        end, 320)
    AddCheck(container, L["Key press"] or "Key press (regular targets)",
        function() return sub.targets.regularEnabled ~= false end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then esub.targets.regularEnabled = v end
        end, 320)

    if sub.targets.hovercastEnabled ~= false then
        AddHeading(container, L["Unit frame target"] or "Hovercast (unit under cursor)")
        local hc = sub.targets.hovercast or {}
        AddDropdown(container, L["Hostility"] or "Hostility", HOSTILITY_LIST, HOSTILITY_ORDER,
            function() return hc.hostility or "ANY" end,
            function(v)
                local esub = Editor.EnsureEditableSub()
                if esub then
                    esub.targets.hovercast = esub.targets.hovercast or {}
                    esub.targets.hovercast.hostility = v
                end
            end)
        AddDropdown(container, L["Vitals"] or "Alive / dead", VITALS_LIST, VITALS_ORDER,
            function() return hc.vitals or "ANY" end,
            function(v)
                local esub = Editor.EnsureEditableSub()
                if esub then
                    esub.targets.hovercast = esub.targets.hovercast or {}
                    esub.targets.hovercast.vitals = v
                end
            end)
    end

    if sub.targets.regularEnabled ~= false then
        AddHeading(container, L["Key press targets"] or "Key press targets (first match wins)")
        local rows = sub.targets.regular or {}
        for i = 1, #rows do
            local row = rows[i]
            local rowGroup = AceGUI:Create("FluxTargetRow") or AceGUI:Create("SimpleGroup")
            rowGroup:SetLayout("Flow")
            rowGroup:SetFullWidth(true)
            if rowGroup.SetMoveUpButton then
                rowGroup:SetMoveUpButton(i > 1)
                rowGroup:SetMoveDownButton(i < #rows)
                rowGroup:SetCallback("OnMoveUp", function()
                    local esub = Editor.EnsureEditableSub()
                    if esub and i > 1 then
                        esub.targets.regular[i], esub.targets.regular[i - 1] =
                            esub.targets.regular[i - 1], esub.targets.regular[i]
                        Editor.Commit()
                    end
                end)
                rowGroup:SetCallback("OnMoveDown", function()
                    local esub = Editor.EnsureEditableSub()
                    if esub and i < #esub.targets.regular then
                        esub.targets.regular[i], esub.targets.regular[i + 1] =
                            esub.targets.regular[i + 1], esub.targets.regular[i]
                        Editor.Commit()
                    end
                end)
            end
            container:AddChild(rowGroup)

            AddDropdown(rowGroup, i == 1 and (L["Unit"] or "Unit") or "", UNIT_LIST, UNIT_ORDER,
                function() return row.unit or "DEFAULT" end,
                function(v)
                    local esub = Editor.EnsureEditableSub()
                    if esub and esub.targets.regular[i] then esub.targets.regular[i].unit = v end
                end, 170)
            AddDropdown(rowGroup, i == 1 and (L["Hostility"] or "Hostility") or "", HOSTILITY_LIST, HOSTILITY_ORDER,
                function() return row.hostility or "ANY" end,
                function(v)
                    local esub = Editor.EnsureEditableSub()
                    if esub and esub.targets.regular[i] then esub.targets.regular[i].hostility = v end
                end, 150)
            AddDropdown(rowGroup, i == 1 and (L["Vitals"] or "Alive / dead") or "", VITALS_LIST, VITALS_ORDER,
                function() return row.vitals or "ANY" end,
                function(v)
                    local esub = Editor.EnsureEditableSub()
                    if esub and esub.targets.regular[i] then esub.targets.regular[i].vitals = v end
                end, 140)

            local del = AceGUI:Create("Button")
            del:SetText(L["X"] or "X")
            del:SetWidth(40)
            del:SetCallback("OnClick", function()
                local esub = Editor.EnsureEditableSub()
                if esub and #esub.targets.regular > 1 then
                    table.remove(esub.targets.regular, i)
                    Editor.Commit()
                end
            end)
            rowGroup:AddChild(del)
        end

        local add = AceGUI:Create("Button")
        add:SetText(L["Add target row"] or "Add target row")
        add:SetWidth(150)
        add:SetCallback("OnClick", function()
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.targets.regular = esub.targets.regular or {}
                local rows = esub.targets.regular
                local last = rows[#rows]
                table.insert(rows, {
                    unit = "DEFAULT",
                    hostility = (last and last.hostility) or "ANY",
                    vitals = (last and last.vitals) or "ANY",
                })
                Editor.Commit()
            end
        end)
        container:AddChild(add)
    end

    -- key-split fallback (only meaningful when the chord shares a bar slot)
    if binding then
        local FluxBinding = _G.FluxBinding
        local peers = FluxBinding and FluxBinding.GetEditorOverlap
            and FluxBinding.GetEditorOverlap(binding.action, binding.uid)
        if peers and peers.route and peers.route.kind == "slot" and peers.native and peers.native.name then
            AddHeading(container, L["Same key — cast last"] or "Same key — cast last")
            AddDropdown(container, nil, {
                ACTION_BAR = (L["Action bar spell"] or "Action bar spell") .. " (" .. peers.native.name .. ")",
                BINDING = (L["This spell (binding)"] or "This binding") .. " (" .. Action.GetName(binding.action) .. ")",
            }, { "ACTION_BAR", "BINDING" },
                function() return binding.fallback or "ACTION_BAR" end,
                function(v)
                    binding.fallback = v
                end, 340)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Conditions panel
-- ---------------------------------------------------------------------------

local MACRO_CONDS = {
    { key = "combat",     label = "Combat",     onText = "In combat",   offText = "Out of combat" },
    { key = "stealth",    label = "Stealth",    onText = "Stealthed",   offText = "Not stealthed" },
    { key = "mounted",    label = "Mounted",    onText = "Mounted",     offText = "Not mounted" },
    { key = "pet",        label = "Pet",        onText = "With pet",    offText = "Without pet" },
    { key = "outdoors",   label = "Outdoors",   onText = "Outdoors",    offText = "Indoors" },
    { key = "swimming",   label = "Swimming",   onText = "Swimming",    offText = "Not swimming" },
    { key = "flying",     label = "Flying",     onText = "Flying",      offText = "Not flying" },
    { key = "channeling", label = "Channeling", onText = "Channeling",  offText = "Not channeling" },
}

function Editor.BuildConditionsPanel(container)
    local sub = Editor.GetSub()
    if not sub then return end

    AddHeading(container, L["Macro conditions"] or "Macro conditions (evaluated by the client — no rebuilds)")
    for _, def in ipairs(MACRO_CONDS) do
        local opt = sub.load[def.key]
        if type(opt) ~= "table" then
            opt = { selected = false, value = true }
        end
        local row = AceGUI:Create("SimpleGroup")
        row:SetLayout("Flow")
        row:SetFullWidth(true)
        container:AddChild(row)

        AddCheck(row, L[def.label] or def.label,
            function() return opt.selected end,
            function(v)
                local esub = Editor.EnsureEditableSub()
                if esub then
                    esub.load[def.key] = esub.load[def.key] or { selected = false, value = true }
                    esub.load[def.key].selected = v
                end
            end, 160)

        if opt.selected then
            AddDropdown(row, nil, { [true] = def.onText, [false] = def.offText }, { true, false },
                function() return opt.value ~= false end,
                function(v)
                    local esub = Editor.EnsureEditableSub()
                    if esub and esub.load[def.key] then
                        esub.load[def.key].value = v and true or false
                    end
                end, 180)
        end
    end

    -- Gated modifier conditions (shared action-bar key only)
    local binding = Editor.GetBinding()
    if binding and Conditions then
        if Conditions.SanitizeModLoadOptions then
            Conditions.SanitizeModLoadOptions(binding)
        end
        local canAlt = Conditions.CanOfferModAlt and Conditions.CanOfferModAlt(binding)
        local canSC = Conditions.CanOfferModShiftCtrl and Conditions.CanOfferModShiftCtrl(binding)
        if canAlt or canSC then
            AddHeading(container, L["Modifier conditions"]
                or "Modifier conditions (shared action-bar key)")
            if canAlt then
                local opt = sub.load.modAlt
                if type(opt) ~= "table" then
                    opt = { selected = false }
                    sub.load.modAlt = opt
                end
                AddCheck(container, L["Alt modifier"] or "Alt",
                    function() return opt.selected end,
                    function(v)
                        local esub = Editor.EnsureEditableSub()
                        if esub then
                            esub.load.modAlt = esub.load.modAlt or { selected = false }
                            esub.load.modAlt.selected = v and true or false
                        end
                    end)
            end
            if canSC then
                local opt = sub.load.modShiftCtrl
                if type(opt) ~= "table" then
                    opt = { selected = false }
                    sub.load.modShiftCtrl = opt
                end
                AddCheck(container, L["Shift+Ctrl modifier"] or "SHIFT+CTRL",
                    function() return opt.selected end,
                    function(v)
                        local esub = Editor.EnsureEditableSub()
                        if esub then
                            esub.load.modShiftCtrl = esub.load.modShiftCtrl or { selected = false }
                            esub.load.modShiftCtrl.selected = v and true or false
                        end
                    end)
            end
            local hint = AceGUI:Create("Label")
            hint:SetFullWidth(true)
            local hintText = L["modifier_conditions_hint"]
                or "Only offered when this spell shares an action-bar key. SHIFT+CTRL requires the SHIFT mini, a Shift/Ctrl shared mini, or Main when that column has no minirows. Selecting both Alt and SHIFT+CTRL bakes SHIFT+CTRL+ALT."
            hint:SetText("|cffaaaaaa" .. hintText .. "|r")
            container:AddChild(hint)
        end
    end

    AddHeading(container, L["Load conditions"] or "Load conditions (re-checked on rare events)")

    AddCheck(container, L["Never load"] or "Never load (disable this form profile)",
        function() return sub.load.never end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then esub.load.never = v end
        end)

    -- equipped
    local eqRow = AceGUI:Create("SimpleGroup")
    eqRow:SetLayout("Flow")
    eqRow:SetFullWidth(true)
    container:AddChild(eqRow)
    AddCheck(eqRow, L["Item equipped"] or "Item equipped",
        function() return sub.load.equipped and sub.load.equipped.selected end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.load.equipped = esub.load.equipped or { selected = false, value = "" }
                esub.load.equipped.selected = v
            end
        end, 160)
    if sub.load.equipped and sub.load.equipped.selected then
        local eq = AceGUI:Create("EditBox")
        eq:SetLabel(nil)
        eq:SetText(sub.load.equipped.value or "")
        eq:SetWidth(240)
        eq:SetCallback("OnEnterPressed", function(_, _, val)
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.load.equipped.value = val or ""
                Editor.Commit()
            end
        end)
        eqRow:AddChild(eq)
    end

    -- instance type
    local itRow = AceGUI:Create("SimpleGroup")
    itRow:SetLayout("Flow")
    itRow:SetFullWidth(true)
    container:AddChild(itRow)
    AddCheck(itRow, L["Instance type"] or "Instance type",
        function() return sub.load.instanceType and sub.load.instanceType.selected end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.load.instanceType = esub.load.instanceType or { selected = false, value = "NONE" }
                esub.load.instanceType.selected = v
            end
        end, 160)
    if sub.load.instanceType and sub.load.instanceType.selected then
        AddDropdown(itRow, nil,
            { NONE = "Open world", PARTY = "Dungeon", RAID = "Raid", PVP = "Battleground", ARENA = "Arena" },
            { "NONE", "PARTY", "RAID", "PVP", "ARENA" },
            function() return sub.load.instanceType.value or "NONE" end,
            function(v)
                local esub = Editor.EnsureEditableSub()
                if esub then esub.load.instanceType.value = v end
            end, 160)
    end

    -- zone name
    local znRow = AceGUI:Create("SimpleGroup")
    znRow:SetLayout("Flow")
    znRow:SetFullWidth(true)
    container:AddChild(znRow)
    AddCheck(znRow, L["Zone name"] or "Zone name",
        function() return sub.load.zoneName and sub.load.zoneName.selected end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.load.zoneName = esub.load.zoneName or { selected = false, value = "" }
                esub.load.zoneName.selected = v
            end
        end, 160)
    if sub.load.zoneName and sub.load.zoneName.selected then
        local zn = AceGUI:Create("EditBox")
        zn:SetText(sub.load.zoneName.value or "")
        zn:SetWidth(240)
        zn:SetCallback("OnEnterPressed", function(_, _, val)
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.load.zoneName.value = val or ""
                Editor.Commit()
            end
        end)
        znRow:AddChild(zn)
    end

    -- specialization
    local spRow = AceGUI:Create("SimpleGroup")
    spRow:SetLayout("Flow")
    spRow:SetFullWidth(true)
    container:AddChild(spRow)
    AddCheck(spRow, L["Specialization"] or "Talent spec / group",
        function() return sub.load.specialization and sub.load.specialization.selected end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.load.specialization = esub.load.specialization or { selected = false, value = 1 }
                esub.load.specialization.selected = v
            end
        end, 160)
    if sub.load.specialization and sub.load.specialization.selected then
        AddDropdown(spRow, nil, { [1] = "Spec 1", [2] = "Spec 2", [3] = "Spec 3", [4] = "Spec 4" },
            { 1, 2, 3, 4 },
            function() return tonumber(sub.load.specialization.value) or 1 end,
            function(v)
                local esub = Editor.EnsureEditableSub()
                if esub then esub.load.specialization.value = tonumber(v) or 1 end
            end, 120)
    end
end

-- ---------------------------------------------------------------------------
-- Forms panel (form-only: Active / page enable / copy — gates KB + UF)
-- ---------------------------------------------------------------------------

function Editor.BuildFormsPanel(container)
    local binding = Editor.GetBinding()
    if not binding then
        local hint = AceGUI:Create("Label")
        hint:SetFullWidth(true)
        hint:SetText("|cff9ecfff" .. (L["forms_need_binding"]
            or "Change a setting or bind a key to create a binding profile for form overrides.") .. "|r")
        container:AddChild(hint)
        return
    end

    AddHeading(container, L["form_panel_heading"] or "Form / Stance / Skyriding")
    local help = AceGUI:Create("Label")
    help:SetFullWidth(true)
    help:SetFontObject(GameFontHighlightSmall)
    help:SetText(L["form_panel_help"]
        or "Enable Active on a form to apply this binding there for both keypress and unit-frame hover. Inactive forms fall back to the action bar.")
    container:AddChild(help)

    local multi = Forms.HasMultipleForms and Forms.HasMultipleForms()
    local hasCond = Forms.HasMacroConditionForms and Forms.HasMacroConditionForms()
    if not multi or not hasCond then
        local none = AceGUI:Create("Label")
        none:SetFullWidth(true)
        none:SetText("|cff9ecfff" .. (L["form_panel_noforms"]
            or "No forms or stances for this character — this binding always applies.") .. "|r")
        container:AddChild(none)
        return
    end

    local note = AceGUI:Create("Label")
    note:SetFullWidth(true)
    note:SetFontObject(GameFontDisableSmall)
    note:SetText(L["form_panel_active_both"]
        or "Active applies to keypress and unit-frame hover together. Use the Targets tab for per-form keypress / hovercast clause options.")
    container:AddChild(note)

    -- Copy from (into currently selected form)
    do
        local copyRow = AceGUI:Create("SimpleGroup")
        copyRow:SetLayout("Flow")
        copyRow:SetFullWidth(true)
        container:AddChild(copyRow)
        local copyList, copyOrder = {}, {}
        for _, tok in ipairs(Forms.GetTokens()) do
            if tok ~= S.formToken then
                local info = Forms.GetTokenInfo(tok)
                local label = L["form_tab_" .. tok] or (info and info.name) or tok
                if DB.HasDedicatedFormSub(binding, tok) or tok == "noform" then
                    copyList[tok] = label
                    copyOrder[#copyOrder + 1] = tok
                end
            end
        end
        if #copyOrder > 0 then
            local dd = AceGUI:Create("FluxBlizzardDropdown") or AceGUI:Create("Dropdown")
            dd:SetLabel(L["Copy from"] or "Copy from...")
            dd:SetList(copyList, copyOrder)
            dd:SetWidth(220)
            dd:SetCallback("OnValueChanged", function(_, _, fromTok)
                if not fromTok then return end
                local toTok = S.formToken or "noform"
                if DB.CopyFormSub then
                    DB.CopyFormSub(binding, fromTok, toTok)
                end
                Editor.Commit()
            end)
            copyRow:AddChild(dd)
        end
    end

    AddHeading(container, L["status_form_matrix_heading"] or "Forms / stances")

    for _, token in ipairs(Forms.GetTokens()) do
        local info = Forms.GetTokenInfo(token)
        local displayName = L["form_tab_" .. token] or (info and info.name) or token
        local row = AceGUI:Create("SimpleGroup")
        row:SetLayout("Flow")
        row:SetFullWidth(true)
        container:AddChild(row)

        local ic = AceGUI:Create("Icon")
        ic:SetImage(Forms.GetTokenIcon(token))
        ic:SetImageSize(22, 22)
        ic:SetWidth(28)
        ic:SetHeight(26)
        local selected = (S.formToken == token)
        if ic.image then
            ic.image:SetVertexColor(1, 1, selected and 0.7 or 1, selected and 1 or 0.75)
        end
        ic:SetCallback("OnClick", function()
            S.formToken = token
            Editor.Redraw()
        end)
        ic:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:SetText(displayName, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        ic:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        row:AddChild(ic)

        local nameBtn = AceGUI:Create("InteractiveLabel")
        if not nameBtn then
            nameBtn = AceGUI:Create("Label")
        end
        nameBtn:SetText(selected and ("|cffffd100" .. displayName .. "|r") or displayName)
        nameBtn:SetWidth(140)
        if nameBtn.SetCallback then
            nameBtn:SetCallback("OnClick", function()
                S.formToken = token
                Editor.Redraw()
            end)
        end
        row:AddChild(nameBtn)

        local isActive = DB.IsCustomActiveForForm(binding, token)
        local activeCb = AceGUI:Create("CheckBox")
        activeCb:SetLabel(L["form_panel_active_label"]
            and (L["form_panel_active_label"]):format(displayName)
            or ("Active in " .. displayName))
        activeCb:SetValue(isActive)
        activeCb:SetWidth(220)
        activeCb:SetCallback("OnValueChanged", function(_, _, val)
            if token == "noform" then
                DB.EnsureFormSub(binding, "noform").active = val and true or false
            elseif val then
                if not DB.HasDedicatedFormSub(binding, token) then
                    local src = binding.forms and binding.forms.noform
                    local copy = DB.DeepCopyFormSub and DB.DeepCopyFormSub(src) or DB.NewFormSubProfile()
                    copy.active = true
                    if type(binding.forms) ~= "table" then binding.forms = {} end
                    binding.forms[token] = copy
                else
                    binding.forms[token].active = true
                end
            else
                -- Dedicated inactive: keep settings for re-enable; no dedicated = already inactive
                if DB.HasDedicatedFormSub(binding, token) then
                    binding.forms[token].active = false
                end
            end
            S.formToken = token
            Editor.Commit()
        end)
        row:AddChild(activeCb)

        local pageCb = AceGUI:Create("CheckBox")
        pageCb:SetLabel(L["form_panel_page_enable"] or "Page enabled")
        pageCb:SetValue(DB.IsFormPageEnabled(token))
        pageCb:SetWidth(130)
        pageCb:SetCallback("OnValueChanged", function(_, _, val)
            DB.SetFormPageEnabled(token, val and true or false)
            Editor.Commit()
        end)
        row:AddChild(pageCb)

        local statusBits = {}
        if not DB.IsFormPageEnabled(token) then
            statusBits[#statusBits + 1] = "|cffff8080" .. (L["status_form_disabled_short"] or "Disabled") .. "|r"
        elseif isActive then
            statusBits[#statusBits + 1] = "|cff40ff40" .. (L["status_form_custom_binding"] or "Custom binding") .. "|r"
        else
            statusBits[#statusBits + 1] = "|cff808080" .. (L["status_form_inactive_short"] or "Inactive") .. "|r"
        end
        local cond = Forms.MacroCondition and Forms.MacroCondition(token)
        if cond then
            statusBits[#statusBits + 1] = "|cff9ecfff[" .. cond .. "]|r"
        else
            statusBits[#statusBits + 1] = "|cff808080" .. (L["form_panel_no_macro_cond"] or "no macro condition") .. "|r"
        end
        local st = AceGUI:Create("Label")
        st:SetText(table.concat(statusBits, "  "))
        st:SetWidth(220)
        st:SetFontObject(GameFontHighlightSmall)
        row:AddChild(st)
    end
end

-- ---------------------------------------------------------------------------
-- Status panel
-- ---------------------------------------------------------------------------

function Editor.BuildStatusPanel(container)
    local binding = Editor.GetBinding()
    if not binding then
        local hint = AceGUI:Create("Label")
        hint:SetFullWidth(true)
        hint:SetText("|cff9ecfff" .. (L["status_unbound_no_row"]
            or "UNBOUND — no Flux binding yet. Place on a bar / Extra / Utility or edit a setting to create one.") .. "|r")
        container:AddChild(hint)
        return
    end
    local FluxBinding = _G.FluxBinding
    local Factory = ns.FluxBindingMacroFactory
    local MACRO_MAX = (Factory and Factory.MacrotextMax and Factory.MacrotextMax()) or 255

    if Conditions.IsParked(binding) then
        local warn = AceGUI:Create("Label")
        warn:SetFullWidth(true)
        warn:SetText("|cffff4040" .. (L["Spell not learned — binding disabled"]
            or "Action not available — binding parked (key kept, nothing applied).") .. "|r")
        container:AddChild(warn)
    end

    AddHeading(container, L["Routing"] or "Routing")
    local peers = FluxBinding and FluxBinding.GetEditorOverlap
        and FluxBinding.GetEditorOverlap(binding.action, binding.uid)
    local routeLbl = AceGUI:Create("Label")
    routeLbl:SetFullWidth(true)
    if binding.key and binding.key ~= "" then
        if peers and peers.route then
            if peers.route.kind == "slot" then
                routeLbl:SetText(("Key |cffffffff%s|r drives |cff9ecfffcolumn %d (%s)|r — the generated macro is installed INTO the bar button."):format(
                    binding.key, peers.route.col, peers.route.row))
            else
                routeLbl:SetText(("Key |cffffffff%s|r is a free chord — generated macro on a hidden secure button."):format(binding.key))
            end
        else
            routeLbl:SetText("No routing information.")
        end
    elseif peers and peers.source == "bar" and peers.chord then
        local noun = (peers.native and peers.native.kind == "item") and "item"
            or (peers.native and peers.native.kind == "spell") and "spell"
            or "action"
        local fmt = (noun == "item")
            and (L["status_no_key_on_bar_item"]
                or "No Flux key — this item is on the action bar under key |cffffffff%s|r (slot %s). Shared Flux bindings on that key still apply.")
            or (noun == "spell")
            and (L["status_no_key_on_bar_spell"]
                or "No Flux key — this spell is on the action bar under key |cffffffff%s|r (slot %s). Shared Flux bindings on that key still apply.")
            or (L["status_no_key_on_bar_action"]
                or "No Flux key — this action is on the action bar under key |cffffffff%s|r (slot %s). Shared Flux bindings on that key still apply.")
        routeLbl:SetText(fmt:format(peers.chord, tostring(peers.slot or "?")))
    else
        routeLbl:SetText(L["Implicit"] and (L["Implicit"] .. ": customized profile rides the bar keys for this action.")
            or "No Flux key — customized profile rides the bar keys where this action is placed (implicit).")
    end
    container:AddChild(routeLbl)

    if peers and peers.native and peers.native.name and peers.native.kind ~= "macro" then
        local fb = AceGUI:Create("Label")
        fb:SetFullWidth(true)
        fb:SetFontObject(GameFontHighlightSmall)
        local fallbackFmt = (peers.native.kind == "item")
            and (L["status_shared_bar_fallback_item_fmt"]
                or "When no conditional clause matches, the key falls back to the action bar item: |cffffcc00%s|r.")
            or (L["status_shared_bar_fallback_fmt"]
                or "When no conditional clause matches, the key falls back to the action bar spell: |cffffcc00%s|r.")
        fb:SetText(fallbackFmt:format(peers.native.name))
        container:AddChild(fb)
    end

    -- Shared peers: clickable icons (open that spell's binding editor)
    local extras = peers and peers.multiCastExtras or {}
    local hosts = peers and peers.multiCastHosts or {}
    if peers and (peers.native or (peers.peers and #peers.peers > 0)
        or #extras > 0 or #hosts > 0) then
        AddHeading(container, L["Shared key"] or "Shared key / action bar")
        local shareIcons = AceGUI:Create("SimpleGroup")
        shareIcons:SetLayout("Flow")
        shareIcons:SetFullWidth(true)
        container:AddChild(shareIcons)

        local function AddShareIcon(tex, tip, highlight, dim, openTarget)
            local ic = AceGUI:Create("Icon")
            ic:SetImage(tex or 134400)
            ic:SetImageSize(22, 22)
            ic:SetWidth(28)
            ic:SetHeight(26)
            if ic.image then
                if dim then
                    ic.image:SetVertexColor(0.5, 0.5, 0.5, 0.7)
                elseif highlight then
                    ic.image:SetVertexColor(1, 1, 0.7, 1)
                else
                    ic.image:SetVertexColor(1, 1, 1, 1)
                end
            end
            local clickHint = (Editor.IsEmbedded and Editor.IsEmbedded())
                and (L["Click to select in list"] or "Click to select in list")
                or (L["Click to open binding editor"] or "Click to open binding editor")
            local clickTip = openTarget
                and ((tip or "?") .. "\n|cff808080" .. clickHint .. "|r")
                or tip
            ic:SetCallback("OnEnter", function(widget)
                GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
                GameTooltip:SetText(clickTip or "?", nil, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            ic:SetCallback("OnLeave", function()
                GameTooltip:Hide()
            end)
            if openTarget then
                ic:SetCallback("OnClick", function()
                    if Editor.OpenSharedPeer then
                        Editor.OpenSharedPeer(openTarget)
                    elseif _G.FluxSpellBindingEditor_Open then
                        local act = type(openTarget) == "table" and (openTarget.action or openTarget) or openTarget
                        _G.FluxSpellBindingEditor_Open(act)
                    end
                end)
            end
            shareIcons:AddChild(ic)
        end

        if peers.native and peers.native.kind ~= "macro" then
            local nativeAction
            if peers.native.kind == "spell" and peers.native.id then
                nativeAction = { type = "spell", id = peers.native.id, name = peers.native.name }
            elseif peers.native.kind == "item" and peers.native.id then
                nativeAction = { type = "item", id = peers.native.id, name = peers.native.name }
            end
            local nativeTarget
            if (not peers.subjectIsNative) and nativeAction then
                nativeTarget = {
                    action = nativeAction,
                    placeId = peers.slot and ("ab:" .. tostring(peers.slot)) or nil,
                    preferChord = peers.chord,
                }
            end
            AddShareIcon(
                peers.native.icon,
                (L["Action bar"] or "Action bar") .. ": " .. (peers.native.name or "?")
                    .. (peers.subjectIsNative
                        and ("\n|cff40ff40(" .. OnBarSelfLabel(peers.native.kind, false) .. ")|r")
                        or ""),
                peers.subjectIsNative,
                false,
                nativeTarget)
        end
        for _, peer in ipairs(peers.peers or {}) do
            local peerTarget
            if not peer.isSubject and peer.action then
                peerTarget = {
                    action = peer.action,
                    placeId = peer.placeId,
                    uid = peer.uid,
                    key = peer.key,
                    preferChord = peer.key,
                }
            end
            AddShareIcon(
                peer.icon,
                (peer.isSubject and "|cffffd100(this binding)|r\n" or "")
                    .. (peer.name or "?")
                    .. (peer.available and "" or "\n|cff808080unavailable|r"),
                peer.isSubject,
                not peer.available,
                peerTarget)
        end
        for _, ex in ipairs(extras) do
            local tip = (L["multicast_share_extra_tip"] or "Multi-cast") .. ": " .. (ex.name or "?")
            if ex.hostName and ex.hostUid and binding and ex.hostUid ~= binding.uid then
                tip = tip .. "\n|cff9ecfff" .. (L["multicast_share_extra_on_fmt"] or "on %s"):format(ex.hostName) .. "|r"
            end
            if not ex.available then
                tip = tip .. "\n|cff808080" .. (L["multicast_extras_skipped"] or "skipped") .. "|r"
            end
            local exTarget
            if ex.action then
                local eb = DB.FindBindingForMacroExtra and DB.FindBindingForMacroExtra({
                    type = ex.type, id = ex.id, name = ex.name,
                }, ex.hostUid or (binding and binding.uid))
                exTarget = {
                    action = ex.action,
                    placeId = eb and eb.placeId,
                    uid = eb and eb.uid,
                    key = eb and eb.key,
                }
            end
            AddShareIcon(ex.icon, tip, false, not ex.available, exTarget)
        end
        for _, host in ipairs(hosts) do
            local tip = (L["multicast_share_host_tip"] or "Multi-cast host") .. ": " .. (host.name or "?")
            local hostTarget
            if host.action then
                hostTarget = {
                    action = host.action,
                    placeId = host.placeId,
                    uid = host.uid,
                    key = host.key,
                }
            end
            AddShareIcon(host.icon, tip, false, false, hostTarget)
        end
    end

    AddHeading(container, L["Generated macros"] or "Generated macros (live)")
    local preview = FluxBinding and FluxBinding.GetPreviewForBinding(binding.uid)
    local sawKeyboard = false
    if preview and type(preview.texts) == "table" then
        for _, entry in ipairs(preview.texts) do
            if entry.kind == "keyboard" then
                sawKeyboard = true
                break
            end
        end
    end
    if preview and not sawKeyboard then
        local why = AceGUI:Create("Label")
        why:SetFullWidth(true)
        local whyText = L["status_keyboard_not_installed"]
        if type(whyText) ~= "string" or whyText == "" or whyText == "status_keyboard_not_installed" then
            whyText = "Keypress macro is not on this bar button, so the corner badge was not installed either."
        end
        why:SetText("|cffff4040" .. whyText .. "|r")
        container:AddChild(why)
    end
    if preview and #preview.texts > 0 then
        for _, entry in ipairs(preview.texts) do
            local text = entry.text or ""
            local len = #text
            local head = AceGUI:Create("Label")
            head:SetFullWidth(true)
            head:SetFontObject(GameFontNormal)
            local kindTag = ""
            if entry.kind == "hover" or entry.kind == "reverseHover" then
                kindTag = " |cff9ecfff[UF]|r"
            elseif entry.kind == "reverse" then
                kindTag = " |cffffcc00[badge]|r"
            end
            head:SetText("|cff9ecfff" .. (entry.label or "") .. "|r" .. kindTag
                .. ("  |cff808080(%d/%d)|r"):format(len, MACRO_MAX))
            container:AddChild(head)

            local box = AceGUI:Create("MultiLineEditBox")
            if not box then
                box = AceGUI:Create("EditBox")
            end
            box:SetFullWidth(true)
            if box.SetNumLines then
                box:SetNumLines(math.min(8, math.max(3, select(2, text:gsub("\n", "\n")) + 2)))
            end
            if box.DisableButton then box:DisableButton(true) end
            if box.SetLabel then box:SetLabel("") end
            box:SetText(text)
            if box.SetCallback then
                box:SetCallback("OnEnterPressed", function(widget)
                    widget:SetText(text)
                end)
            end
            container:AddChild(box)
        end
    else
        local none = AceGUI:Create("Label")
        none:SetFullWidth(true)
        none:SetText(L["No generated macro — default bar behaviour."]
            or "No generated macro — native bar behaviour (profile is default / not applied yet).")
        container:AddChild(none)
    end
end

-- ---------------------------------------------------------------------------
-- Bar & Badges panel
-- ---------------------------------------------------------------------------

local function BuildOrderList(container, title, orderList, onMove)
    AddHeading(container, title)
    for i, uid in ipairs(orderList) do
        local b = DB.Get(uid)
        if b then
            local row = AceGUI:Create("FluxTargetRow") or AceGUI:Create("SimpleGroup")
            row:SetLayout("Flow")
            row:SetFullWidth(true)
            if row.SetMoveUpButton then
                row:SetMoveUpButton(i > 1)
                row:SetMoveDownButton(i < #orderList)
                row:SetCallback("OnMoveUp", function()
                    onMove(i, i - 1)
                end)
                row:SetCallback("OnMoveDown", function()
                    onMove(i, i + 1)
                end)
            end
            container:AddChild(row)
            local lbl = AceGUI:Create("Label")
            local tex = Action.GetIcon(b.action)
            lbl:SetText((tex and ("|T" .. tex .. ":16|t ") or "") .. Action.GetName(b.action))
            lbl:SetWidth(300)
            row:AddChild(lbl)
        end
    end
end

function Editor.BuildBadgesPanel(container)
    local binding = Editor.GetBinding()
    local sub = Editor.GetSub()
    if not sub then return end
    if not binding then
        -- Ephemeral defaults until first edit; EnsureEditableSub creates the row.
    end
    local FluxBinding = _G.FluxBinding

    AddHeading(container, L["Badge display"] or "Badge display (this binding)")

    local subjectAction = (binding and binding.action) or S.subject
    local subjectUid = binding and binding.uid or S.currentUid
    local canExtrasHost = binding and FluxBinding and FluxBinding.CanUseMultiCastExtras
        and FluxBinding.CanUseMultiCastExtras(binding)
    local hostExtras = canExtrasHost and DB.GetMacroExtras(sub) or {}
    if #hostExtras > 0 then
        local hostNote = AceGUI:Create("Label")
        hostNote:SetFullWidth(true)
        hostNote:SetFontObject(GameFontHighlightSmall)
        hostNote:SetText(L["multicast_host_badge_settings_hint"]
            or "Settings below are for this spell only. Corner badges (trinkets, Combustion, …) use Bar & Badges on each extra’s own binding in the list.")
        container:AddChild(hostNote)
    end

    local alpha = AceGUI:Create("Slider")
    alpha:SetLabel(L["Badge transparency"] or "Badge opacity")
    alpha:SetSliderValues(0, 1, 0.05)
    alpha:SetValue((sub.badge and sub.badge.alpha) or DB.DEFAULT_BADGE_ALPHA)
    alpha:SetWidth(250)
    alpha:SetCallback("OnMouseUp", function(_, _, val)
        local esub = Editor.EnsureEditableSub()
        if esub then
            esub.badge = esub.badge or {}
            esub.badge.alpha = tonumber(val) or DB.DEFAULT_BADGE_ALPHA
            Editor.Commit()
        end
    end)
    container:AddChild(alpha)

    local flags = {
        { key = "hiddenAlways",   label = "Always hidden (swap still active)" },
        { key = "hiddenUnlessCd", label = "Hidden unless on cooldown" },
        { key = "hiddenMinirow",  label = "Hidden on mini rows" },
        { key = "hiddenSwap",     label = "Hide badge but keep swap active" },
    }
    for _, def in ipairs(flags) do
        AddCheck(container, L[def.label] or def.label,
            function() return sub.badge and sub.badge[def.key] end,
            function(v)
                local esub = Editor.EnsureEditableSub()
                if esub then
                    esub.badge = esub.badge or {}
                    esub.badge[def.key] = v
                end
            end)
    end

    AddHeading(container, L["badge_cd_number_heading"] or "Cooldown numbers")
    local cdHelp = AceGUI:Create("Label")
    cdHelp:SetFullWidth(true)
    cdHelp:SetFontObject(GameFontHighlightSmall)
    cdHelp:SetText(L["badge_cd_number_help"]
        or "Cooldown countdown digits on this binding’s corner badge(s). Default size is 100% (max). Applies to peer badges and multi-cast extras.")
    container:AddChild(cdHelp)

    AddCheck(container, L["badge_cd_number_show"] or "Show cooldown numbers",
        function()
            if not sub.badge or sub.badge.cdNumber == nil then return true end
            return sub.badge.cdNumber ~= false
        end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.badge = esub.badge or {}
                esub.badge.cdNumber = v and true or false
            end
        end)

    local cdScale = AceGUI:Create("Slider")
    cdScale:SetLabel(L["badge_cd_number_scale"] or "Cooldown number size")
    cdScale:SetSliderValues(0, 1, 0.05)
    local curScale = (sub.badge and tonumber(sub.badge.cdNumberScale)) or 1
    cdScale:SetValue(curScale)
    cdScale:SetWidth(250)
    cdScale:SetCallback("OnMouseUp", function(_, _, val)
        local esub = Editor.EnsureEditableSub()
        if esub then
            esub.badge = esub.badge or {}
            local n = tonumber(val) or 1
            if n < 0 then n = 0 elseif n > 1 then n = 1 end
            esub.badge.cdNumberScale = n
            Editor.Commit()
        end
    end)
    container:AddChild(cdScale)
    local scaleHint = AceGUI:Create("Label")
    scaleHint:SetFullWidth(true)
    scaleHint:SetFontObject(GameFontDisableSmall)
    scaleHint:SetText(L["badge_cd_number_scale_hint"] or "0% = hidden size · 100% = maximum")
    container:AddChild(scaleHint)

    AddCheck(container, L["badge_cd_number_mainrow"] or "Show on main row",
        function()
            if not sub.badge or sub.badge.cdNumberMainrow == nil then return true end
            return sub.badge.cdNumberMainrow ~= false
        end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.badge = esub.badge or {}
                esub.badge.cdNumberMainrow = v and true or false
            end
        end)
    AddCheck(container, L["badge_cd_number_minirow"] or "Show on mini rows (Shift / Ctrl)",
        function()
            if not sub.badge or sub.badge.cdNumberMinirow == nil then return true end
            return sub.badge.cdNumberMinirow ~= false
        end,
        function(v)
            local esub = Editor.EnsureEditableSub()
            if esub then
                esub.badge = esub.badge or {}
                esub.badge.cdNumberMinirow = v and true or false
            end
        end)

    local overlap = subjectAction and FluxBinding and FluxBinding.GetEditorOverlap
        and FluxBinding.GetEditorOverlap(subjectAction, subjectUid)
    local hosts = overlap and overlap.multiCastHosts
    if (not hosts or #hosts == 0) and subjectAction and DB.FindBindingsUsingMacroExtra then
        hosts = DB.FindBindingsUsingMacroExtra(subjectAction, subjectUid)
    end
    local isMultiCastExtra = (type(hosts) == "table" and #hosts > 0)
        or (S.placeSource == "multicast")
        or (type(S.placeId) == "string" and tostring(S.placeId):match("^mcast:"))
        or (subjectAction and subjectAction.type == "slot")

    local nk = binding and (binding.key and binding.key ~= "" and (FluxBinding and FluxBinding.NormalizeChord(binding.key) or binding.key))
        or (overlap and overlap.chord)
    if not nk then
        local info = AceGUI:Create("Label")
        info:SetFullWidth(true)
        if isMultiCastExtra then
            info:SetText(L["multicast_badge_settings_hint"]
                or "These Bar & Badges settings apply when this action appears as a multi-cast corner badge on its host spell.")
        else
            info:SetText(L["Badges appear when this binding shares a key with a bar slot."]
                or "Badges appear when this binding has a key shared with a bar slot.")
        end
        container:AddChild(info)
        return
    end

    if (not binding.key or binding.key == "") and overlap and overlap.source == "bar" then
        local note = AceGUI:Create("Label")
        note:SetFullWidth(true)
        note:SetFontObject(GameFontHighlightSmall)
        note:SetText(("|cff9ecfffOn bar under |cffffffff%s|r — badge order for that shared key:|r"):format(nk))
        container:AddChild(note)
    end

    -- Multi-cast extras own corner badges — reorder on the Multi-cast tab.
    local canExtras = binding and FluxBinding and FluxBinding.CanUseMultiCastExtras
        and FluxBinding.CanUseMultiCastExtras(binding)
    local extras = canExtras and DB.GetMacroExtras(sub) or {}
    if #extras > 0 then
        AddHeading(container, L["multicast_badge_order_heading"]
            or "Badge corner order (multi-cast extras)")
        local note = AceGUI:Create("Label")
        note:SetFullWidth(true)
        note:SetFontObject(GameFontHighlightSmall)
        note:SetText(L["multicast_badge_order_help"]
            or "Corner badges follow the Multi-cast tab order (first 3 available). Reorder there with ▲ ▼.")
        container:AddChild(note)
        local icons = {}
        for i = 1, #extras do
            local e = extras[i]
            local tex = (DB.GetMacroExtraIcon and DB.GetMacroExtraIcon(e)) or 134400
            icons[#icons + 1] = ("|T%s:22|t"):format(tostring(tex))
        end
        local row = AceGUI:Create("Label")
        row:SetFullWidth(true)
        row:SetText(table.concat(icons, " "))
        container:AddChild(row)
        return
    end

    local uidSet = {}
    for uid, b in pairs(DB.All()) do
        if b.key and FluxBinding and FluxBinding.NormalizeChord(b.key) == nk then
            uidSet[uid] = true
        end
    end
    local count = 0
    for _ in pairs(uidSet) do count = count + 1 end
    if count > 1 then
        local stack = DB.GetChordStackOrder(nk, uidSet)
        BuildOrderList(container, L["Merged macro order"] or "Merged macro order (top wins)", stack, function(from, to)
            if to >= 1 and to <= #stack then
                stack[from], stack[to] = stack[to], stack[from]
                DB.SetChordStackOrder(nk, stack)
                Editor.Commit()
            end
        end)
        local corner = DB.GetBadgeCornerOrder(nk, uidSet)
        BuildOrderList(container, L["Badge corner order"] or "Badge corner order (top = first corner)", corner, function(from, to)
            if to >= 1 and to <= #corner then
                corner[from], corner[to] = corner[to], corner[from]
                DB.SetBadgeCornerOrder(nk, corner)
                Editor.Commit()
            end
        end)
    end
end
