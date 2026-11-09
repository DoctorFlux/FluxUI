-- AceGUI: compact row of 4 NonCombat Utility Slots (same DB as NC grid).

local Type, Version = "FluxSpellBookSlotsPanel", 6
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local CELL = 44
local GAP = 4
local Timer = C_Timer

local function AssignAPI()
    return _G.FluxNCUtilitySlots
end

local function ForeverGamepadUI()
    local Flux = _G.Flux
    local cap = Flux and (Flux.Cap or Flux.Capabilities)
    return cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() == true
end

local function GetDisplayNameForModifier(modKey)
    if not modKey or modKey == "" then
        return "NoMod"
    end
    return tostring(modKey)
end

local function GetEntryIcon(entry)
    if type(entry) ~= "table" or not entry.type or entry.id == nil then
        return nil
    end
    local t = entry.type
    if t == "outfit" then
        local A = AssignAPI()
        local info = A and A.GetOutfitInfo and A.GetOutfitInfo(entry.id)
        return info and info.icon
    elseif t == "spell" then
        if C_Spell and C_Spell.GetSpellTexture then
            return C_Spell.GetSpellTexture(entry.id)
        end
        if GetSpellTexture then
            return GetSpellTexture(entry.id)
        end
    elseif t == "item" or t == "toy" then
        if C_Item and C_Item.GetItemIconByID then
            return C_Item.GetItemIconByID(entry.id)
        end
        if GetItemIcon then
            return GetItemIcon(entry.id)
        end
    elseif t == "macro" then
        if GetMacroInfo then
            local _, icon = GetMacroInfo(entry.name or entry.id)
            return icon
        end
    elseif t == "mount" then
        if C_MountJournal and C_MountJournal.GetMountInfoByID then
            local _, _, icon = C_MountJournal.GetMountInfoByID(tonumber(entry.id) or entry.id)
            return icon
        end
    elseif t == "battlepet" then
        if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
            -- speciesID, customName, level, xp, maxXP, displayID, isFavorite, name, icon
            local ok, _, _, _, _, _, _, _, _, icon = pcall(C_PetJournal.GetPetInfoByPetID, entry.id)
            if ok then
                return icon
            end
        end
    end
    return nil
end

local function GetEntryLabel(entry)
    if type(entry) ~= "table" then
        return "?"
    end
    if entry.name and entry.name ~= "" then
        return entry.name
    end
    if entry.type == "spell" and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(entry.id)
        if info and info.name then
            return info.name
        end
    end
    return string.format("%s %s", tostring(entry.type or "?"), tostring(entry.id))
end

local function ResolveDisplayEntry(slotIndex)
    local A = AssignAPI()
    if not A or not A.GetSlots then
        return nil, nil
    end
    local slots = A.GetSlots()
    local map = slots and slots[slotIndex]
    if type(map) ~= "table" then
        return nil, nil
    end
    local mod = A.GetCurrentModKey and A.GetCurrentModKey() or ""
    if mod ~= "" then
        local e = map[mod]
        if type(e) == "table" and e.type and e.id ~= nil then
            return e, mod
        end
        -- Unassigned modifier → fall back to nomod / mirror (same as live buttons).
    end
    if A.ResolveNomodEntry then
        return A.ResolveNomodEntry(map)
    end
    local e = map[""]
    if type(e) == "table" and e.type and e.id ~= nil then
        return e, ""
    end
    return nil, nil
end

local function ApplySlotVisual(btn, slotIndex)
    if not btn or not slotIndex or not btn.Icon then
        return
    end
    local chosen, chosenModKey = ResolveDisplayEntry(slotIndex)
    local icon = GetEntryIcon(chosen)
    if icon then
        btn.Icon:SetTexture(icon)
        btn.Icon:Show()
        if btn.Text then
            btn.Text:SetText(GetDisplayNameForModifier(chosenModKey))
            btn.Text:Show()
        end
    else
        btn.Icon:Hide()
        if btn.Text then
            btn.Text:SetText("")
            btn.Text:Hide()
        end
    end
    if btn.Bg then
        btn.Bg:Show()
    end
end

local function ShowPanelTooltip(btn, slotIndex)
    if not btn or not slotIndex then
        return
    end
    local A = AssignAPI()
    local slots = A and A.GetSlots and A.GetSlots()
    local data = slots and slots[slotIndex]
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, string.format("Utility slot %d", slotIndex))
    local added = false
    if type(data) == "table" then
        local keys = {}
        for modKey, entry in pairs(data) do
            if type(entry) == "table" and entry.type and entry.id ~= nil then
                keys[#keys + 1] = modKey
            end
        end
        table.sort(keys, function(a, b)
            if a == "" then
                return true
            end
            if b == "" then
                return false
            end
            return tostring(a) < tostring(b)
        end)
        for i = 1, #keys do
            local modKey = keys[i]
            local entry = data[modKey]
            GameTooltip_AddNormalLine(
                GameTooltip,
                string.format("%s: %s", GetDisplayNameForModifier(modKey), GetEntryLabel(entry))
            )
            added = true
        end
    end
    if not added then
        GameTooltip_AddNormalLine(GameTooltip, "Empty")
    end
    GameTooltip_AddBlankLineToTooltip(GameTooltip)
    GameTooltip_AddInstructionLine(GameTooltip, "Drag spell/item/macro/mount/toy (hold Shift/Alt/Ctrl for that modifier).")
    GameTooltip_AddInstructionLine(GameTooltip, "Right-click: clear one modifier or entire slot.")
    GameTooltip:Show()
end

local function OpenContextMenu(owner, slotIndex)
    if ForeverGamepadUI() then
        return
    end
    if not owner or not slotIndex then
        return
    end
    local A = AssignAPI()
    if not A then
        return
    end
    if not MenuUtil then
        if C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_Menu")
        end
        if not MenuUtil and LoadAddOn then
            pcall(LoadAddOn, "Blizzard_Menu")
        end
    end
    if not MenuUtil then
        return
    end

    MenuUtil.CreateContextMenu(owner, function(_, root)
        local slots = A.GetSlots and A.GetSlots()
        local data = slots and slots[slotIndex]
        local any = false
        if type(data) == "table" then
            local keys = {}
            for modKey, entry in pairs(data) do
                if type(entry) == "table" and entry.type and entry.id ~= nil then
                    keys[#keys + 1] = modKey
                end
            end
            table.sort(keys, function(a, b)
                if a == "" then
                    return true
                end
                if b == "" then
                    return false
                end
                return tostring(a) < tostring(b)
            end)
            for i = 1, #keys do
                local modKey = keys[i]
                local entry = data[modKey]
                local line = string.format(
                    "Clear |cffffffff%s|r  (%s)",
                    GetEntryLabel(entry),
                    GetDisplayNameForModifier(modKey)
                )
                local capturedMod = modKey
                root:CreateButton(line, function()
                    if A.ClearModifier then
                        A.ClearModifier(slotIndex, capturedMod)
                    end
                end)
                any = true
            end
        end
        if any then
            root:CreateDivider()
        end
        root:CreateButton("Clear entire slot", function()
            if A.ClearSlot then
                A.ClearSlot(slotIndex)
            end
        end)
    end)
end

local function RequestParentLayout(widget)
    if not widget or not Timer or not Timer.After then
        return
    end
    if widget._fluxParentLayoutPending then
        return
    end
    widget._fluxParentLayoutPending = true
    Timer.After(0, function()
        widget._fluxParentLayoutPending = nil
        if not widget.parent then
            return
        end
        local p = widget.parent
        local depth = 0
        while p and depth < 16 do
            if p.DoLayout then
                pcall(p.DoLayout, p)
                return
            end
            p = p.parent
            depth = depth + 1
        end
    end)
end

local function BuildSlotButton(parent, slotIndex, onDataChanged)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(CELL, CELL)
    btn.slotIndex = slotIndex

    btn.Bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.Bg:SetAllPoints()
    btn.Bg:SetTexture("Interface/Buttons/UI-EmptySlot")

    btn.Icon = btn:CreateTexture(nil, "ARTWORK")
    btn.Icon:SetSize(28, 28)
    btn.Icon:SetPoint("CENTER")
    btn.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.Text:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
    btn.Text:Hide()

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    btn:SetScript("OnEnter", function(self)
        ShowPanelTooltip(self, slotIndex)
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            OpenContextMenu(self, slotIndex)
            return
        end
        if button ~= "LeftButton" then
            return
        end
        local A = AssignAPI()
        if not A or not A.AssignFromCursor then
            return
        end
        if A.AssignFromCursor(slotIndex, A.GetCurrentModKey and A.GetCurrentModKey() or "") then
            if onDataChanged then
                onDataChanged()
            end
        end
    end)

    return btn
end

local function LayoutRow(self)
    if not self._slotParent then
        return
    end
    local totalW = 4 * CELL + 3 * GAP
    self._slotParent:SetSize(totalW, CELL)
    self:SetHeight(CELL)
    RequestParentLayout(self)
end

local methods = {
    OnAcquire = function(self)
        self._fluxReleased = false
        self:SetFullWidth(true)
        local frame = self.frame
        frame:EnableMouse(true)

        if not self._slotParent then
            self._slotParent = CreateFrame("Frame", nil, frame)
            self._slotParent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        end

        if not self._built then
            self._slotBtns = {}
            local function refreshAll()
                if self._fluxReleased then
                    return
                end
                for i = 1, 4 do
                    local b = self._slotBtns[i]
                    if b then
                        ApplySlotVisual(b, i)
                    end
                end
            end

            for i = 1, 4 do
                local b = BuildSlotButton(self._slotParent, i, refreshAll)
                b:SetParent(self._slotParent)
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", self._slotParent, "TOPLEFT", (i - 1) * (CELL + GAP), 0)
                b:Show()
                self._slotBtns[i] = b
            end

            self._refreshSlots = refreshAll
            self._built = true
        end

        self._refreshHandler = function()
            if self._fluxReleased then
                return
            end
            if self.frame and self.frame.IsShown and not self.frame:IsShown() then
                return
            end
            if self._refreshSlots then
                self._refreshSlots()
            end
        end

        local A = AssignAPI()
        if A then
            A.OnPanelSlotsChanged = self._refreshHandler
        end

        if not self._evFrame then
            self._evFrame = CreateFrame("Frame", nil, frame)
            self._evFrame:SetScript("OnEvent", function(_, event)
                if self._fluxReleased then
                    return
                end
                if event == "MODIFIER_STATE_CHANGED" and frame:IsVisible() and self._refreshSlots then
                    self._refreshSlots()
                end
            end)
        end
        self._evFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

        if self._refreshSlots then
            self._refreshSlots()
        end
        if Timer and Timer.After then
            local gen = (self._fluxAcquireGen or 0) + 1
            self._fluxAcquireGen = gen
            Timer.After(0, function()
                if self._fluxReleased or self._fluxAcquireGen ~= gen then
                    return
                end
                LayoutRow(self)
            end)
        else
            LayoutRow(self)
        end
    end,

    OnRelease = function(self)
        self._fluxReleased = true
        self._fluxAcquireGen = (self._fluxAcquireGen or 0) + 1
        local A = AssignAPI()
        if A and A.OnPanelSlotsChanged == self._refreshHandler then
            A.OnPanelSlotsChanged = nil
        end
        self._refreshHandler = nil
        if self._evFrame then
            self._evFrame:UnregisterAllEvents()
        end
    end,

    SetText = function() end,
    SetFontObject = function() end,
    SetImage = function() end,
    SetImageSize = function() end,

    OnWidthSet = function(self, width)
        if self._fluxReleased then
            return
        end
        if type(width) ~= "number" or width <= 0 then
            return
        end
        LayoutRow(self)
    end,
}

local function Constructor()
    local name = "AceGUI30FluxSpellBookSlotsPanel" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:EnableMouse(true)
    frame:Hide()

    local widget = {
        frame = frame,
        type = Type,
        _slotBtns = {},
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

function _G.FluxSpellBookSlotsPanel_OnOptionsClosed()
    local A = AssignAPI()
    if A then
        A.OnPanelSlotsChanged = nil
    end
end
