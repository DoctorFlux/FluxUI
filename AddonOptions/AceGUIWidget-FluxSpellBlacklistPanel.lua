-- AceGUI: blacklisted spell icons (auto rank-up) for Action Bars tab.

local Type, Version = "FluxSpellBlacklistPanel", 23
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local ICON = 42
--- Horizontal/vertical gap between spell icons in the grid (0 = flush / tile).
local PAD = 0
--- Hard cap only to avoid absurd column counts if width APIs glitch (normal grids stay well below this).
local MAX_COLS_SANITY = 64
--- Minimum height of the shaded drop/grid area when the blacklist is empty (no ScrollFrame).
local MIN_EMPTY_DROP_H = 64
--- Fallback width before AceGUI has laid out the widget frame.
local DEFAULT_CONTENT_W = 400
--- Padding inside the shaded backdrop so the tint shows around icons (not flush under them).
local GRID_INSET = 8

local Timer = C_Timer
local wipe = table.wipe or wipe

local DROP_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local function GetSpellNameForTooltip(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then
            return info.name
        end
    end
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    return nil
end

--- Numeric rank for Classic per-rank spells (matches FluxSpellRankManager.GetSpellRank logic).
local function GetSpellRankNumber(spellID)
    if not spellID then return nil end
    local subtext
    if C_Spell and C_Spell.GetSpellSubtext then
        subtext = C_Spell.GetSpellSubtext(spellID)
    elseif GetSpellSubtext then
        subtext = GetSpellSubtext(spellID)
    end
    if subtext and subtext ~= "" then
        local rankNum = tonumber(subtext:match("Rank%s*(%d+)"))
        if rankNum then
            return rankNum
        end
    end
    local spellName
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            spellName = info.name
        end
    elseif GetSpellInfo then
        spellName = GetSpellInfo(spellID)
    end
    if spellName then
        local rankNum = tonumber(spellName:match("%(%s*Rank%s*(%d+)%s*%)"))
        if rankNum then
            return rankNum
        end
    end
    return nil
end

--- Gray rank/subtext line (e.g. "Rank 3") for the blacklisted spell ID.
local function GetSpellRankSubtextLine(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellSubtext then
        local s = C_Spell.GetSpellSubtext(spellID)
        if s and s ~= "" then
            return s
        end
    end
    if GetSpellSubtext then
        local s = GetSpellSubtext(spellID)
        if s and s ~= "" then
            return s
        end
    end
    local name = GetSpellNameForTooltip(spellID)
    if name then
        local r = name:match("%(%s*Rank%s*%d+%s*%)")
        if r then
            return r
        end
    end
    return nil
end

--- Match spell book / action bar: include gray rank/subtext line when the API supports it.
local function SetGameTooltipSpellByIDWithSubtext(spellID)
    if not spellID or not GameTooltip.SetSpellByID then
        return false
    end
    local tip = GameTooltip
    local ok4 = select(1, pcall(function()
        return tip:SetSpellByID(spellID, false, false, true)
    end))
    if ok4 then
        return true
    end
    local ok3 = select(1, pcall(function()
        return tip:SetSpellByID(spellID, false, true)
    end))
    if ok3 then
        return true
    end
    local ok1 = select(1, pcall(function()
        return tip:SetSpellByID(spellID)
    end))
    return ok1 and true or false
end

local function ShowBlacklistSpellTooltip(btn, spellID)
    if not btn or not btn:IsVisible() then return end
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    if GameTooltip.ClearLines then
        GameTooltip:ClearLines()
    end

    local ok = SetGameTooltipSpellByIDWithSubtext(spellID)
    if not ok and spellID and GameTooltip.SetHyperlink then
        ok = select(1, pcall(function()
            GameTooltip:SetHyperlink("spell:" .. tostring(spellID))
        end))
    end
    if not ok then
        local name = GetSpellNameForTooltip(spellID) or ("Spell " .. tostring(spellID))
        GameTooltip:SetText(name, 1, 1, 1)
    end

    local rankLine = GetSpellRankSubtextLine(spellID)
    if rankLine and rankLine ~= "" then
        GameTooltip:AddLine("Blacklisted rank: " .. rankLine, 0.65, 0.65, 0.65, true)
    else
        GameTooltip:AddLine("Blacklisted spell ID: " .. tostring(spellID), 0.55, 0.55, 0.55, true)
    end

    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("Skipped by auto rank-up.", 0.55, 0.82, 1, true)
    GameTooltip:AddLine("Click remove. Drag here to add.", 0.65, 0.65, 0.65, true)
    GameTooltip:Show()
end

local function AttachBlacklistTooltipKeepAlive(btn, spellID)
    btn:SetScript("OnEnter", function(self)
        ShowBlacklistSpellTooltip(self, spellID)
        self:SetScript("OnUpdate", function(this)
            if not this:IsMouseOver() then
                this:SetScript("OnUpdate", nil)
                return
            end
            local owned = true
            if GameTooltip.IsOwned then
                owned = GameTooltip:IsOwned(this)
            elseif GameTooltip.GetOwner then
                owned = (GameTooltip:GetOwner() == this)
            end
            if not GameTooltip:IsShown() or not owned then
                ShowBlacklistSpellTooltip(this, spellID)
            end
        end)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetScript("OnUpdate", nil)
        GameTooltip:Hide()
    end)
end

local function TryConsumeSpellFromCursor(mgr)
    if not mgr or not mgr.ToggleSpellBlacklist then return false end
    local cursorType, id, subType, subSubType = GetCursorInfo()
    if cursorType ~= "spell" then
        return false
    end
    local spellID = subSubType or id
    if type(spellID) ~= "number" then
        spellID = tonumber(spellID)
    end
    if not spellID then
        return false
    end
    mgr:ToggleSpellBlacklist(spellID)
    ClearCursor()
    return true
end

local function GetSpellRankManager()
    return _G.FluxSpellRankManagerModule or _G.FluxSpellRankManager
end

--- Forward declaration: used by BindSpellDropHandlers before definition below.
local RefreshPanel

local function BindSpellDropHandlers(frame, widgetRef)
    if not frame then return end
    frame:RegisterForDrag("LeftButton")
    frame:EnableMouse(true)
    frame:SetScript("OnReceiveDrag", function()
        if TryConsumeSpellFromCursor(GetSpellRankManager()) then
            RefreshPanel(widgetRef)
        end
    end)
    frame:SetScript("OnMouseUp", function(_, btn)
        if btn ~= "LeftButton" then return end
        if TryConsumeSpellFromCursor(GetSpellRankManager()) then
            RefreshPanel(widgetRef)
        end
    end)
end

--- Clears drag/drop scripts so a parent frame does not steal mouse from children (e.g. spell icon buttons).
local function UnbindSpellDropHandlers(frame)
    if not frame then return end
    frame:SetScript("OnReceiveDrag", nil)
    frame:SetScript("OnMouseUp", nil)
    if frame.RegisterForDrag then
        frame:RegisterForDrag()
    end
end

--- When empty, also accept drops on the hint line (FontString is not a mouse target). When spells are shown,
--- content must not capture mouse or it blocks tooltips and click-to-remove on icons.
local function SetContentHintDropOnly(widget, enable)
    local content = widget._fluxContent
    if not content then return end
    if enable then
        content:EnableMouse(true)
        BindSpellDropHandlers(content, widget)
    else
        UnbindSpellDropHandlers(content)
        content:EnableMouse(false)
    end
end

local function ClearIconButtons(widget)
    if not widget._fluxSpellButtons then return end
    for _, btn in ipairs(widget._fluxSpellButtons) do
        if btn then
            btn:SetParent(nil)
            btn:Hide()
        end
    end
    wipe(widget._fluxSpellButtons)
end

--- Options content width from the Ace widget frame (List layout sets width on fill children).
local function GetEffectiveContentWidth(widget)
    local f = widget and widget.frame
    if not f then
        return DEFAULT_CONTENT_W
    end
    local w = f.width or f:GetWidth() or 0
    if not w or w <= 0 then
        w = DEFAULT_CONTENT_W
    end
    return math.max(w, 200)
end

--- Re-run AceGUI container layout once, next frame only (sync DoLayout + OnWidthSet + RefreshPanel loops crash the client).
--- Prefer skipping parent DoLayout unless height actually changed — Action Bars hosts many panels and thrashing freezes the client.
local function RequestParentLayout(widget)
    if not widget or not Timer or not Timer.After then
        return
    end
    if widget._fluxReleased then
        return
    end
    if widget._fluxParentLayoutPending then
        return
    end
    widget._fluxParentLayoutPending = true
    widget._fluxLayoutGen = (widget._fluxLayoutGen or 0) + 1
    local gen = widget._fluxLayoutGen
    Timer.After(0, function()
        if widget._fluxLayoutGen ~= gen or widget._fluxReleased then
            return
        end
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

local function ApplyWidgetLayoutHeight(widget, h)
    h = math.max(tonumber(h) or 1, 1)
    local prev = widget._fluxLastLayoutHeight
    widget:SetHeight(h)
    if widget.frame then
        widget.frame:SetHeight(h)
    end
    widget._fluxLastLayoutHeight = h
    -- Only bubble layout when height changes (stops Ace scrollbar width feedback loops).
    if not prev or math.abs(h - prev) >= 1 then
        RequestParentLayout(widget)
    end
end

RefreshPanel = function(widget)
    if not widget or widget._fluxReleased then
        return
    end
    if widget.frame and widget.frame.IsShown and not widget.frame:IsShown() then
        return
    end
    local mgr = GetSpellRankManager()
    local parent = widget._fluxIconParent
    local empty = widget._fluxEmptyText
    local content = widget._fluxContent
    local dropBg = widget._fluxDropBackdrop
    if not parent or not empty or not content then return end

    ClearIconButtons(widget)
    widget._fluxSpellButtons = widget._fluxSpellButtons or {}

    local layoutW = GetEffectiveContentWidth(widget)
    empty:SetWidth(layoutW)

    local function PointDropAreaBelowHint()
        parent:ClearAllPoints()
        parent:SetWidth(math.max(layoutW - 16, 40))
        parent:SetPoint("TOPLEFT", empty, "BOTTOMLEFT", 0, -6)
    end

    local function PointDropAreaTopContent()
        parent:ClearAllPoints()
        parent:SetWidth(math.max(layoutW - 16, 40))
        parent:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end

    if not mgr or not mgr.GetBlacklistSpellIDs or not mgr.IsRankFeaturesSupported or not mgr:IsRankFeaturesSupported() then
        empty:SetText("Classic only.")
        empty:Show()
        parent:ClearAllPoints()
        parent:Hide()
        if dropBg then dropBg:Hide() end
        SetContentHintDropOnly(widget, false)
        ApplyWidgetLayoutHeight(widget, 28)
        return
    end

    parent:Show()
    if dropBg then dropBg:Show() end

    local ids = mgr:GetBlacklistSpellIDs()
    if #ids == 0 then
        empty:SetText("Drag spells here to skip auto rank-up.")
        empty:Show()
        PointDropAreaBelowHint()
        parent:SetHeight(MIN_EMPTY_DROP_H)
        SetContentHintDropOnly(widget, true)
        ApplyWidgetLayoutHeight(widget, empty:GetStringHeight() + 6 + MIN_EMPTY_DROP_H + 10)
        return
    end

    SetContentHintDropOnly(widget, false)

    empty:Hide()
    PointDropAreaTopContent()

    -- Columns from actual shaded backdrop width (icon area = width minus left/right GRID_INSET).
    local shadedW = parent:GetWidth()
    if not shadedW or shadedW < ICON + 2 * GRID_INSET then
        shadedW = math.max(layoutW - 16, 40)
    end
    local innerAvail = math.max(shadedW - 2 * GRID_INSET, ICON + PAD)
    local cols = math.max(1, math.floor((innerAvail + PAD) / (ICON + PAD)))
    if cols > MAX_COLS_SANITY then
        cols = MAX_COLS_SANITY
    end
    local rowCount = math.max(1, math.ceil(#ids / cols))
    for i, spellID in ipairs(ids) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(ICON, ICON)
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonUp")
        btn:RegisterForDrag("LeftButton")
        btn:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            GRID_INSET + col * (ICON + PAD),
            -(GRID_INSET + row * (ICON + PAD))
        )
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
            or (GetSpellTexture and GetSpellTexture(spellID))
        if icon then
            tex:SetTexture(icon)
        else
            tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        local rankNum = GetSpellRankNumber(spellID)
        local rankFs = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        rankFs:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 2)
        if rankNum then
            rankFs:SetText(tostring(rankNum))
            rankFs:SetTextColor(1, 0.95, 0.6)
            rankFs:Show()
        else
            rankFs:SetText("")
            rankFs:Hide()
        end

        AttachBlacklistTooltipKeepAlive(btn, spellID)
        btn:SetScript("OnReceiveDrag", function()
            if TryConsumeSpellFromCursor(mgr) then
                RefreshPanel(widget)
            end
        end)
        btn:SetScript("OnClick", function()
            if select(1, GetCursorInfo()) == "spell" then
                if TryConsumeSpellFromCursor(mgr) then
                    RefreshPanel(widget)
                end
                return
            end
            if mgr.ClearSpellFromBlacklist then
                mgr:ClearSpellFromBlacklist(spellID)
            end
        end)
        widget._fluxSpellButtons[#widget._fluxSpellButtons + 1] = btn
        btn:SetFrameLevel((parent:GetFrameLevel() or 0) + 20)
        btn:Show()
    end

    -- Natural grid width with fixed PAD; shaded box spans config width (extra space on the right when wide).
    local innerW = (#ids <= cols) and (#ids * (ICON + PAD) - PAD) or (cols * (ICON + PAD) - PAD)
    local innerH = rowCount * (ICON + PAD) - PAD
    local boxW = math.max(layoutW - 16, innerW + GRID_INSET * 2)
    local boxH = math.max(innerH + GRID_INSET * 2, ICON + GRID_INSET * 2)
    parent:SetSize(boxW, boxH)
    parent:Show()
    if parent.OnBackdropSizeChanged then
        parent:OnBackdropSizeChanged()
    end
    ApplyWidgetLayoutHeight(widget, boxH + 12)
end

local methods = {
    ["OnAcquire"] = function(self)
        self._fluxReleased = false
        self:SetFullWidth(true)
        local frame = self.frame
        frame:EnableMouse(true)
        frame:SetClipsChildren(false)

        if not self._fluxContent then
            local content = CreateFrame("Frame", nil, frame)
            content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
            content:EnableMouse(true)
            self._fluxContent = content

            local empty = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            empty:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
            empty:SetWidth(DEFAULT_CONTENT_W)
            empty:SetJustifyH("LEFT")
            empty:SetTextColor(0.75, 0.75, 0.75)
            self._fluxEmptyText = empty

            -- Single bordered frame for grid + empty drop zone (no child Button - invisible Buttons can
            -- still draw highlight/pushed layers and look like a broken second "button" overlay).
            local iconParent = CreateFrame("Frame", nil, content, BackdropTemplateMixin and "BackdropTemplate" or nil)
            iconParent:SetWidth(math.max(DEFAULT_CONTENT_W - 16, 40))
            iconParent:EnableMouse(true)
            iconParent:SetFrameLevel(10)

            if iconParent.SetBackdrop then
                iconParent:SetBackdrop(DROP_BACKDROP)
                iconParent:SetBackdropColor(0.06, 0.06, 0.08, 0.55)
                iconParent:SetBackdropBorderColor(0.35, 0.35, 0.4, 0.9)
                self._fluxDropBackdrop = iconParent
            end

            self._fluxIconParent = iconParent

            BindSpellDropHandlers(iconParent, self)
            -- Content drag for hint-line drops is toggled in RefreshPanel (empty list only).
        end

        local mgr = GetSpellRankManager()
        if mgr and mgr.SetSpellBlacklistPanelRefreshHandler then
            mgr:SetSpellBlacklistPanelRefreshHandler(function()
                if not self._fluxReleased then
                    RefreshPanel(self)
                end
            end)
        end

        self._fluxLastPanelWidth = nil
        self._fluxLastLayoutHeight = nil
        self._fluxLayoutGen = (self._fluxLayoutGen or 0) + 1
        local gen = self._fluxLayoutGen
        -- One deferred refresh after Ace has set fill width (avoid double RefreshPanel + layout storms).
        Timer.After(0, function()
            if self._fluxReleased or self._fluxLayoutGen ~= gen then
                return
            end
            if self._fluxIconParent then
                RefreshPanel(self)
            end
        end)
    end,

    ["OnRelease"] = function(self)
        self._fluxReleased = true
        self._fluxLayoutGen = (self._fluxLayoutGen or 0) + 1
        self._fluxParentLayoutPending = nil
        local mgr = GetSpellRankManager()
        if mgr and mgr.SetSpellBlacklistPanelRefreshHandler then
            mgr:SetSpellBlacklistPanelRefreshHandler(nil)
        end
        ClearIconButtons(self)
    end,

    ["SetText"] = function(self, text)
        self._fluxTitle = text
    end,
    ["SetFontObject"] = function() end,
    ["SetImage"] = function() end,
    ["SetImageSize"] = function() end,

    ["OnWidthSet"] = function(self, width)
        if self._fluxReleased then
            return
        end
        if type(width) ~= "number" or width <= 0 or not self._fluxIconParent then
            return
        end
        local last = self._fluxLastPanelWidth
        if last and math.abs(width - last) < 2 then
            return
        end
        self._fluxLastPanelWidth = width
        -- Debounce width-driven rebuilds; rapid Ace layout passes must not RefreshPanel every frame.
        self._fluxWidthRefreshGen = (self._fluxWidthRefreshGen or 0) + 1
        local gen = self._fluxWidthRefreshGen
        Timer.After(0.05, function()
            if self._fluxReleased or self._fluxWidthRefreshGen ~= gen then
                return
            end
            RefreshPanel(self)
        end)
    end,
}

local function Constructor()
    local name = "AceGUI30FluxSpellBlacklist" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:Hide()

    local widget = {
        frame = frame,
        type = Type,
        _fluxSpellButtons = {},
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

function _G.FluxSpellBlacklistPanel_OnOptionsClosed()
    -- Refresh handler cleared in OnRelease; this is a defensive no-op hook for CloseFluxUIOptions.
end
