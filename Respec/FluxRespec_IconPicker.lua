-- FluxRespec_IconPicker.lua
-- Icon picker popup for Respec profile spec icons. Mirrors ItemRackOptions'
-- PopulateInitialIcons flow: equipment-slot quick-picks first, then every
-- macro/spell icon available to the client. Cross-version compatible:
--   * Classic Era / Wrath / Cata: GetMacroIcons(MACRO_ICON_FILENAMES)
--   * Retail 10.x+:               IconDataProviderMixin fallback
--
-- Scrolling: FauxScrollFrame row offset lives in frame.offset; Blizzard's
-- scrollbar OnValueChanged only drives SetVerticalScroll unless we sync
-- offset here and forward wheel from the icon area.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.IconPicker = R.IconPicker or {}
local Picker = R.IconPicker

local COLUMNS         = 6
local ROWS            = 7
local VISIBLE         = COLUMNS * ROWS
local CELL_SIZE       = 30
local CELL_GAP        = 4
local ROW_STEP        = CELL_SIZE + CELL_GAP
-- Extra outer padding so FluxBorder clears grid + scrollbar comfortably.
local PADDING         = 18
local HEADER_HEIGHT     = 56
local FOOTER_HEIGHT     = 34
local GRID_WIDTH        = COLUMNS * CELL_SIZE + (COLUMNS - 1) * CELL_GAP
-- UIPanelScrollFrameTemplate places the slider OUTSIDE the scrollframe (TOPRIGHT+6px),
-- which drew past the border. Reserve one column wide enough to hold slider + insets.
local SCROLL_COLUMN     = 46
local GRID_SCROLL_GAP   = 10
local FRAME_WIDTH       = PADDING * 2 + GRID_WIDTH + GRID_SCROLL_GAP + SCROLL_COLUMN
local GRID_HEIGHT       = ROWS * CELL_SIZE + (ROWS - 1) * CELL_GAP
local FRAME_HEIGHT      = HEADER_HEIGHT + GRID_HEIGHT + FOOTER_HEIGHT + PADDING * 2

Picker._iconsAll = nil
Picker._profileName = nil
Picker._anchorFrame = nil -- spec icon button; picker anchors above it
Picker._frame = nil
Picker._inRefresh = false
Picker._scrollHooked = false

-- -----------------------------------------------------------------------------
-- Icon source
-- -----------------------------------------------------------------------------

local function EquipmentSlotIcons()
    local out = {}
    local slots = {
        "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
        "ShirtSlot", "TabardSlot", "WristSlot", "HandsSlot", "WaistSlot",
        "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot",
        "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot",
    }
    local fn = _G.GetInventorySlotInfo
    if type(fn) ~= "function" then
        return out
    end
    for _, slotName in ipairs(slots) do
        -- Retail (and some builds) error on deprecated names like RangedSlot; Classic still has them.
        local ok, slotID, emptyTex = pcall(fn, slotName)
        if ok and slotID and slotID ~= 0 then
            local tex = GetInventoryItemTexture and GetInventoryItemTexture("player", slotID)
            if not tex then
                tex = emptyTex
            end
            if tex then
                table.insert(out, tex)
            end
        end
    end
    return out
end

local function ClassIcons()
    local out = {}
    local _, class = UnitClass("player")
    if class then
        table.insert(out, "Interface\\Icons\\ClassIcon_" .. class:lower())
    end
    table.insert(out, "Interface\\Icons\\INV_Misc_Book_09")
    table.insert(out, "Interface\\Icons\\Spell_Holy_BorrowedTime")
    table.insert(out, "Interface\\Icons\\INV_Misc_QuestionMark")
    return out
end

local function CollectAllIcons()
    local icons = {}
    for _, t in ipairs(ClassIcons()) do table.insert(icons, t) end
    for _, t in ipairs(EquipmentSlotIcons()) do table.insert(icons, t) end

    if _G.RefreshPlayerSpellIconInfo then
        pcall(_G.RefreshPlayerSpellIconInfo)
    end
    if _G.GetMacroIcons and _G.MACRO_ICON_FILENAMES then
        local list = _G.GetMacroIcons(_G.MACRO_ICON_FILENAMES)
        if type(list) == "table" then
            local n = #list
            local getInfo = _G.GetSpellorMacroIconInfo
            for i = 1, n do
                local t = getInfo and getInfo(i) or list[i]
                if type(t) == "number" then
                    table.insert(icons, t)
                elseif type(t) == "string" then
                    if t:find("\\") then
                        table.insert(icons, t)
                    else
                        table.insert(icons, "Interface\\Icons\\" .. t)
                    end
                end
            end
        end
    elseif _G.IconDataProviderMixin then
        local kind = _G.IconDataProviderExtraType and _G.IconDataProviderExtraType.Spell or 0
        local ok, provider = pcall(_G.CreateAndInitFromMixin, _G.IconDataProviderMixin, kind)
        if ok and provider then
            local count = provider:GetNumIcons()
            for i = 1, count do
                table.insert(icons, provider:GetIconByIndex(i))
            end
            if provider.Release then provider:Release() end
        end
    end

    return icons
end

-- -----------------------------------------------------------------------------
-- Scroll sync: Blizzard scrollbar does not update FauxScrollFrame.offset
-- -----------------------------------------------------------------------------

local function SyncOffsetFromScrollBar(scroll)
    local sb = scroll.ScrollBar
    if not sb then return 0 end
    local v = sb:GetValue()
    scroll.offset = math.floor((v / ROW_STEP) + 0.5)
    return scroll.offset
end

local function ScrollBarStep(scroll, delta)
    local sb = scroll.ScrollBar
    if not sb then return end
    local min, max = sb:GetMinMaxValues()
    local v = sb:GetValue()
    if delta > 0 then
        sb:SetValue(math.max(min, v - ROW_STEP))
    else
        sb:SetValue(math.min(max, v + ROW_STEP))
    end
end

local function EnsureScrollHook(scroll)
    if Picker._scrollHooked or not scroll or not scroll.ScrollBar then return end
    Picker._scrollHooked = true
    scroll.ScrollBar:HookScript("OnValueChanged", function(self, value)
        if Picker._inRefresh then return end
        local faux = self:GetParent()
        if not faux then return end
        faux.offset = math.floor((value / ROW_STEP) + 0.5)
        Picker.RefreshIconsOnly()
    end)
end

function Picker.RefreshIconsOnly()
    Picker.Refresh(true)
end

-- -----------------------------------------------------------------------------
-- Layering + position: UIParent (not inside Flux window) + above spec icon
-- -----------------------------------------------------------------------------

local function PositionPickerNearSpecIcon(f, anchor)
    f:ClearAllPoints()
    if anchor and anchor.IsVisible and anchor:IsVisible() then
        -- Above the Respec spec icon; UIParent child + TOOLTIP strata stacks over Flux (MEDIUM).
        f:SetPoint("BOTTOM", anchor, "TOP", 0, 10)
    else
        f:SetPoint("CENTER", UIParent, "CENTER")
    end
end

--- Parent to UIParent, draw above FluxWindowFrame (MEDIUM) and Respec overlay.
local function ApplyPickerLayerAndPosition(f, anchor)
    f:SetParent(UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(8000)
    -- FluxBorder uses borderFrame at f:GetFrameLevel()+10; keep UI above border + tint.
    if f.content then
        f.content:SetFrameLevel(f:GetFrameLevel() + 25)
    end
    PositionPickerNearSpecIcon(f, anchor)
    f:Raise()
end

-- Blizzard's default anchors put the slider to the RIGHT of the scrollframe edge.
-- Re-anchor so the track + thumb sit inside our reserved column (inside FluxBorder).
local function AnchorScrollBarInsideColumn(scroll)
    local sb = scroll.ScrollBar
    if not sb then return end
    sb:ClearAllPoints()
    sb:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", -5, -18)
    sb:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", -5, 18)
    local up = sb.ScrollUpButton
    local down = sb.ScrollDownButton
    if up then
        up:ClearAllPoints()
        up:SetPoint("BOTTOM", sb, "TOP", 0, 4)
    end
    if down then
        down:ClearAllPoints()
        down:SetPoint("TOP", sb, "BOTTOM", 0, -4)
    end
end

-- -----------------------------------------------------------------------------
-- UI
-- -----------------------------------------------------------------------------

local function BuildFrame()
    if Picker._frame then return Picker._frame end

    -- Plain frame: BackdropTemplate's fill can paint above children; FluxBorder + optional SetBackdrop only.
    local f = CreateFrame("Frame", "FluxRespecIconPicker", UIParent)
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetScript("OnShow", function(self)
        ApplyPickerLayerAndPosition(self, Picker._anchorFrame)
    end)

    -- Positive pad pulls border corners inward so artwork frames grid+scrollbar.
    if _G.FluxBorder and _G.FluxBorder.ApplyTo then
        pcall(_G.FluxBorder.ApplyTo, _G.FluxBorder, f, 8, 8, 6, 6)
        if _G.FluxBorder.SetClassColor then
            pcall(_G.FluxBorder.SetClassColor, _G.FluxBorder, f, 1, true)
        end
    else
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        f:SetBackdropColor(0, 0, 0, 0.92)
    end

    -- FluxBorder draws border at f:GetFrameLevel()+10; keep all interactive UI above that layer.
    local content = CreateFrame("Frame", nil, f)
    content:SetAllPoints()
    content:SetFrameLevel((f:GetFrameLevel() or 0) + 25)
    f.content = content

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING + 44, -PADDING)
    title:SetText("Respec Spec Icon")
    f.title = title

    local subtitle = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetJustifyH("LEFT")
    f.subtitle = subtitle

    local preview = CreateFrame("Button", nil, content)
    preview:SetSize(36, 36)
    preview:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING, -PADDING)
    local previewTex = preview:CreateTexture(nil, "ARTWORK")
    previewTex:SetAllPoints(preview)
    previewTex:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    preview.icon = previewTex
    f.preview = preview

    local close = CreateFrame("Button", nil, content, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() Picker.Close() end)

    local grid = CreateFrame("Frame", nil, content)
    grid:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING, -(PADDING + HEADER_HEIGHT))
    grid:SetSize(GRID_WIDTH, GRID_HEIGHT)
    grid:EnableMouseWheel(true)

    local function OnIconAreaMouseWheel(_, delta)
        if f.scroll and f.scroll.ScrollBar then
            ScrollBarStep(f.scroll, delta)
        end
    end
    grid:SetScript("OnMouseWheel", OnIconAreaMouseWheel)

    local buttons = {}
    for i = 1, VISIBLE do
        local row = math.floor((i - 1) / COLUMNS)
        local col = (i - 1) % COLUMNS
        local b = CreateFrame("Button", nil, grid)
        b:SetSize(CELL_SIZE, CELL_SIZE)
        b:SetPoint("TOPLEFT", grid, "TOPLEFT",
            col * (CELL_SIZE + CELL_GAP),
            -(row * (CELL_SIZE + CELL_GAP)))
        local tex = b:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(b)
        b.icon = tex

        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(b)
        hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        hl:SetBlendMode("ADD")

        local selected = b:CreateTexture(nil, "OVERLAY")
        selected:SetAllPoints(b)
        selected:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        selected:SetBlendMode("ADD")
        selected:Hide()
        b.selected = selected

        b:SetScript("OnClick", function(self)
            local t = self._texture
            if not t or not Picker._profileName then return end
            R.SetIcon(Picker._profileName, t)
            Picker.Close()
        end)
        b:SetScript("OnEnter", function(self)
            if not self._texture then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local tip = self._texture
            if type(tip) == "string" then
                GameTooltip:AddLine(tip, 1, 1, 1, true)
            else
                GameTooltip:AddLine(("Icon #%s"):format(tostring(tip)))
            end
            GameTooltip:AddLine("Click to set as spec icon", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)

        b:EnableMouseWheel(true)
        b:SetScript("OnMouseWheel", OnIconAreaMouseWheel)

        buttons[i] = b
    end
    f.buttons = buttons
    f.grid = grid

    local scroll = CreateFrame("ScrollFrame", "FluxRespecIconPickerScroll", content, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", grid, "TOPRIGHT", GRID_SCROLL_GAP, 0)
    scroll:SetPoint("BOTTOMLEFT", grid, "BOTTOMRIGHT", GRID_SCROLL_GAP, 0)
    scroll:SetWidth(SCROLL_COLUMN)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        ScrollBarStep(self, delta)
    end)
    f.scroll = scroll
    EnsureScrollHook(scroll)
    AnchorScrollBarInsideColumn(scroll)

    local reset = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    reset:SetSize(136, 24)
    reset:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", PADDING, PADDING)
    reset:SetText("Reset to class icon")
    reset:SetScript("OnClick", function()
        if not Picker._profileName then return end
        R.SetIcon(Picker._profileName, R.DefaultIcon())
        Picker.Close()
    end)

    local cancel = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    cancel:SetSize(96, 24)
    cancel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -PADDING, PADDING)
    cancel:SetText(CANCEL or "Cancel")
    cancel:SetScript("OnClick", function() Picker.Close() end)

    Picker._frame = f
    return f
end

function Picker.Refresh(iconsOnly)
    local f = Picker._frame
    if not f or not f:IsShown() then return end

    local icons = Picker._iconsAll or {}
    local total = #icons
    local rowCount = math.max(1, math.ceil(total / COLUMNS))

    Picker._inRefresh = true

    if not iconsOnly then
        local needBar = rowCount > ROWS
        FauxScrollFrame_Update(
            f.scroll,
            rowCount,
            ROWS,
            ROW_STEP,
            nil, nil, nil, nil, nil, nil,
            needBar
        )
        if f.scroll.ScrollBar then
            if not needBar then
                f.scroll.ScrollBar:SetValue(0)
            end
            SyncOffsetFromScrollBar(f.scroll)
        else
            f.scroll.offset = 0
        end
    else
        SyncOffsetFromScrollBar(f.scroll)
    end

    Picker._inRefresh = false

    local offset = FauxScrollFrame_GetOffset(f.scroll) or 0
    local current = Picker._profileName and R.GetIcon(Picker._profileName) or nil

    for i = 1, VISIBLE do
        local b = f.buttons[i]
        local rowIdx = math.floor((i - 1) / COLUMNS)
        local colIdx = (i - 1) % COLUMNS
        local iconIdx = (offset + rowIdx) * COLUMNS + colIdx + 1
        local texture = icons[iconIdx]
        if texture then
            b.icon:SetTexture(texture)
            b._texture = texture
            b:Show()
            if current == texture then
                b.selected:Show()
            else
                b.selected:Hide()
            end
        else
            b.icon:SetTexture(nil)
            b._texture = nil
            b.selected:Hide()
            b:Hide()
        end
    end

    if current then
        f.preview.icon:SetTexture(current)
    else
        f.preview.icon:SetTexture(R.DefaultIcon())
    end
    f.subtitle:SetText(("Profile: %s  |  %d icons"):format(
        Picker._profileName or "<none>",
        total
    ))
end

--- @param profileName string
--- @param anchorFrame Frame|nil spec icon button; picker is placed just above it
function Picker.Open(profileName, anchorFrame)
    if not profileName or not R.GetProfile(profileName) then return end
    local f = BuildFrame()
    Picker._profileName = profileName
    Picker._anchorFrame = anchorFrame
    if not Picker._iconsAll or #Picker._iconsAll == 0 then
        Picker._iconsAll = CollectAllIcons()
    end
    ApplyPickerLayerAndPosition(f, anchorFrame)
    f:Show()
    f:Raise()
    if f.scroll and f.scroll.ScrollBar then
        f.scroll.ScrollBar:SetValue(0)
        f.scroll.offset = 0
    end
    Picker.Refresh()
end

function Picker.Close()
    if Picker._frame then Picker._frame:Hide() end
    Picker._profileName = nil
    Picker._anchorFrame = nil
end

local evt = CreateFrame("Frame")
evt:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
evt:SetScript("OnEvent", function()
    Picker._iconsAll = nil
end)

R.IconPicker = Picker
