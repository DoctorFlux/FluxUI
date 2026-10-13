-- ItemRack-style equip flyout (matches ItemRackMenuFrame layout/docking).

FluxEquipSlotFlyout = FluxEquipSlotFlyout or {}
local Flyout = FluxEquipSlotFlyout

local Candidates = FluxEquipSlotCandidates

local BTN_STEP = 40
local FRAME_PAD = 12
local MENU_SCALE = 0.85 -- ItemRack default MenuScale
local SCREEN_PAD = 8

local LEFT_PAPERDOLL_SLOTS = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true,
    [9] = true, [15] = true, [19] = true,
}

Flyout._frame = nil
Flyout._anchorRef = nil
Flyout._openSlotID = nil
Flyout._hideTimer = nil
Flyout._showTimer = nil
Flyout._onEquipped = nil
Flyout._menuDock = nil
Flyout._menuOrient = nil
Flyout._currentDock = nil

-- Copied from ItemRack.DockInfo (mainDock .. menuDock keys).
local DOCK_INFO = {
    TOPRIGHTTOPLEFT = { xoff = 0, yoff = 8, xdir = 1, ydir = -1, xstart = 8, ystart = -8 },
    BOTTOMRIGHTBOTTOMLEFT = { xoff = 0, yoff = -8, xdir = 1, ydir = 1, xstart = 8, ystart = 44 },
    TOPLEFTTOPRIGHT = { xoff = 0, yoff = 8, xdir = -1, ydir = -1, xstart = -44, ystart = -8 },
    BOTTOMLEFTBOTTOMRIGHT = { xoff = 0, yoff = -8, xdir = -1, ydir = 1, xstart = -44, ystart = 44 },
    TOPRIGHTBOTTOMRIGHT = { xoff = 8, yoff = 0, xdir = -1, ydir = 1, xstart = -44, ystart = 44 },
    BOTTOMRIGHTTOPRIGHT = { xoff = 8, yoff = 0, xdir = -1, ydir = -1, xstart = -44, ystart = -8 },
    TOPLEFTBOTTOMLEFT = { xoff = -8, yoff = 0, xdir = 1, ydir = 1, xstart = 8, ystart = 44 },
    BOTTOMLEFTTOPLEFT = { xoff = -8, yoff = 0, xdir = 1, ydir = -1, xstart = 8, ystart = -8 },
}

local function CancelTimer(t)
    if t and t.Cancel then
        t:Cancel()
    end
    return nil
end

function Flyout.CancelHideTimer()
    Flyout._hideTimer = CancelTimer(Flyout._hideTimer)
end

function Flyout.CancelShowTimer()
    Flyout._showTimer = CancelTimer(Flyout._showTimer)
end

function Flyout.IsOpenFor(slotID, anchor)
    if not Flyout._frame or not Flyout._frame:IsShown() then
        return false
    end
    if slotID and Flyout._openSlotID ~= slotID then
        return false
    end
    if anchor and Flyout._anchorRef ~= anchor then
        return false
    end
    return true
end

function Flyout.Hide()
    Flyout.CancelHideTimer()
    Flyout.CancelShowTimer()
    if Flyout._frame then
        Flyout._frame:Hide()
    end
    Flyout._anchorRef = nil
    Flyout._openSlotID = nil
end

local function GetGridCols(count)
    if count > 24 then
        return 6
    elseif count > 12 then
        return 4
    elseif count > 8 then
        return 3
    elseif count > 4 then
        return 2
    end
    return 1
end

local function DockWindows(f, menuDock, anchor, mainDock, menuOrient)
    local dockKey = mainDock .. menuDock
    local dock = DOCK_INFO[dockKey]
    if not dock then
        dock = DOCK_INFO.TOPLEFTTOPRIGHT
        dockKey = "TOPLEFTTOPRIGHT"
    end

    f:ClearAllPoints()
    f:SetParent(anchor)
    f:SetFrameStrata("HIGH")
    f:SetPoint(menuDock, anchor, mainDock, dock.xoff, dock.yoff)

    Flyout._menuDock = menuDock
    Flyout._menuOrient = menuOrient
    Flyout._currentDock = dockKey
end

local function GetDockOptions(slotID)
    if slotID == 0 or (slotID >= 16 and slotID <= 18) then
        return {
            { "TOPLEFT", "BOTTOMLEFT", "VERTICAL" },
            { "BOTTOMLEFT", "TOPLEFT", "VERTICAL" },
            { "TOPLEFT", "TOPRIGHT", "HORIZONTAL" },
            { "TOPRIGHT", "TOPLEFT", "HORIZONTAL" },
        }
    end

    if LEFT_PAPERDOLL_SLOTS[slotID] then
        return {
            { "TOPLEFT", "TOPRIGHT", "HORIZONTAL" },
            { "TOPRIGHT", "TOPLEFT", "HORIZONTAL" },
        }
    end

    return {
        { "TOPLEFT", "TOPRIGHT", "HORIZONTAL" },
        { "TOPRIGHT", "TOPLEFT", "HORIZONTAL" },
    }
end

local function FrameFitsOnScreen(frame)
    if not frame or not frame.GetLeft then
        return false
    end
    local left = frame:GetLeft()
    local right = frame:GetRight()
    local top = frame:GetTop()
    local bottom = frame:GetBottom()
    if not left or not right or not top or not bottom then
        return false
    end

    local scale = frame:GetEffectiveScale() or 1
    left = left * scale
    right = right * scale
    top = top * scale
    bottom = bottom * scale

    local screenW = GetScreenWidth()
    local screenH = GetScreenHeight()
    return left >= SCREEN_PAD
        and right <= screenW - SCREEN_PAD
        and bottom >= SCREEN_PAD
        and top <= screenH - SCREEN_PAD
end

local function DockMenuToCharacterSheet(anchor, slotID, dockIndex)
    local options = GetDockOptions(slotID)
    local pick = options[dockIndex or 1] or options[1]
    DockWindows(Flyout._frame, pick[1], anchor, pick[2], pick[3])
    return options
end

local function CandidateIcon(c, slotID, anchor)
    if c.isEmpty and Candidates and Candidates.GetEmptySlotTexture then
        return Candidates.GetEmptySlotTexture(slotID, anchor)
    end
    if c.itemLink and GetItemInfo then
        local tex = select(10, GetItemInfo(c.itemLink))
        if tex then
            return tex
        end
    end
    if c.itemID and C_Item and C_Item.GetItemIconByID then
        local ok, ico = pcall(C_Item.GetItemIconByID, c.itemID)
        if ok and ico then
            return ico
        end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function HideMenuButtonChrome(btn)
    local name = btn.GetName and btn:GetName()
    if not name then
        return
    end

    local hotkey = _G[name .. "HotKey"]
    if hotkey then
        hotkey:SetText("")
        hotkey:Hide()
    end

    local nameText = btn.Name or _G[name .. "Name"]
    if nameText then
        nameText:SetText("")
        nameText:Hide()
    end

    local count = _G[name .. "Count"]
    if count then
        count:SetText("")
    end

    local cd = _G[name .. "Cooldown"]
    if cd then
        if cd.SetHideCountdownNumbers then
            cd:SetHideCountdownNumbers(true)
        end
        cd:Hide()
    end

    local border = _G[name .. "Border"]
    if border then
        border:Hide()
    end

    local checked = btn.GetCheckedTexture and btn:GetCheckedTexture()
    if checked then
        checked:Hide()
        checked:SetAlpha(0)
    end
end

local function StripActionButtonOverlays(btn)
    HideMenuButtonChrome(btn)

    if not btn._fluxOverlaysStripped then
        btn._fluxOverlaysStripped = true
        btn.SetChecked = function() end

        if btn.UnregisterAllEvents then
            btn:UnregisterAllEvents()
        end
        btn:SetAttribute("action", nil)

        for _, region in ipairs({ btn:GetRegions() }) do
            if region.GetObjectType and region:GetObjectType() == "Texture" then
                local isStandard = false
                if region == btn.NormalTexture or (btn.GetNormalTexture and region == btn:GetNormalTexture()) then
                    isStandard = true
                end
                if region == btn.PushedTexture or (btn.GetPushedTexture and region == btn:GetPushedTexture()) then
                    isStandard = true
                end
                if region == btn.HighlightTexture or (btn.GetHighlightTexture and region == btn:GetHighlightTexture()) then
                    isStandard = true
                end
                local regionName = region.GetName and region:GetName()
                if regionName and (regionName:find("Icon") or regionName:find("icon")) then
                    isStandard = true
                end
                if not isStandard then
                    region:Hide()
                    region:SetAlpha(0)
                    region.Show = function() end
                end
            end
        end
    end
end

local function RaiseGameTooltipAboveFlyout()
    local tip = GameTooltip
    local fly = Flyout._frame
    if not tip or not fly or not tip.SetFrameStrata then
        return
    end
    tip:SetFrameStrata("TOOLTIP")
    local lv = fly.GetFrameLevel and fly:GetFrameLevel() or 2000
    if tip.SetFrameLevel then
        tip:SetFrameLevel(lv + 50)
    end
end

function Flyout.ScheduleHideSoon(extraFrames)
    Flyout.CancelHideTimer()
    if not C_Timer or not C_Timer.After then
        Flyout.Hide()
        return
    end
    Flyout._hideTimer = C_Timer.After(0.25, function()
        Flyout._hideTimer = nil
        local f = Flyout._frame
        if not f or not f:IsShown() then
            return
        end
        if f:IsMouseOver() then
            return
        end
        if Flyout._anchorRef and Flyout._anchorRef.IsMouseOver and Flyout._anchorRef:IsMouseOver() then
            return
        end
        if extraFrames then
            for i = 1, #extraFrames do
                local frame = extraFrames[i]
                if frame and frame.IsMouseOver and frame:IsMouseOver() then
                    return
                end
            end
        end
        Flyout.Hide()
    end)
end

local function CreateMenuButton(f, idx)
    local btnName = "FluxEquipSlotFlyoutBtn" .. idx
    local btn = _G[btnName]
    if not btn then
        btn = CreateFrame("CheckButton", btnName, f, "ActionButtonTemplate")
        btn:SetID(idx)
        btn:SetFrameStrata("HIGH")
        btn:RegisterForClicks("LeftButtonUp")
        StripActionButtonOverlays(btn)

        btn:SetScript("OnClick", function(self)
            local inv = self._invSlot
            Flyout.Hide()
            if self._isEmpty then
                if Candidates and Candidates.UnequipInventorySlot then
                    Candidates.UnequipInventorySlot(inv)
                end
            elseif self._bag ~= nil and self._bagSlot and Candidates and Candidates.EquipToInventorySlot then
                Candidates.EquipToInventorySlot(self._bag, self._bagSlot, inv)
            end
            if Candidates and Candidates.Invalidate then
                Candidates.Invalidate()
            end
            if Flyout._onEquipped then
                Flyout._onEquipped(inv)
            end
        end)
        btn:SetScript("OnEnter", function(self)
            Flyout.CancelHideTimer()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self._isEmpty then
                GameTooltip:SetText(self._name or (_G.EMPTY or "Empty"), 1, 1, 1)
            elseif self._bag ~= nil and self._bagSlot and GameTooltip.SetBagItem then
                pcall(GameTooltip.SetBagItem, GameTooltip, self._bag, self._bagSlot)
                if self._source == "bank" or self._source == "warband" then
                    GameTooltip:AddLine("In bank — click to take and equip.", 1, 0.72, 0.38, true)
                end
            elseif self._itemLink and GameTooltip.SetHyperlink then
                pcall(GameTooltip.SetHyperlink, GameTooltip, self._itemLink)
            elseif self._name then
                GameTooltip:SetText(self._name, 1, 1, 1)
            end
            GameTooltip:Show()
            RaiseGameTooltipAboveFlyout()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        f.buttons[idx] = btn
    end
    return btn
end

local function LayoutButtons(f, candidates, slotID, anchor)
    local dock = DOCK_INFO[Flyout._currentDock] or DOCK_INFO.TOPLEFTTOPRIGHT
    local orient = Flyout._menuOrient or "HORIZONTAL"
    local menuDock = Flyout._menuDock or "TOPLEFT"
    local maxCols = GetGridCols(#candidates)
    local col, row = 0, 0
    local xpos, ypos = dock.xstart, dock.ystart

    for i, c in ipairs(candidates) do
        local btn = CreateMenuButton(f, i)
        btn._bag = c.bag
        btn._bagSlot = c.slot
        btn._invSlot = slotID
        btn._itemLink = c.itemLink
        btn._name = c.name
        btn._isEmpty = c.isEmpty == true
        btn._source = c.source

        local icon = _G[btn:GetName() .. "Icon"]
        if icon then
            icon:SetTexture(CandidateIcon(c, slotID, anchor))
            icon:SetVertexColor(1, 1, 1)
            icon:SetDesaturated(false)
        end

        HideMenuButtonChrome(btn)

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", f, menuDock, xpos, ypos)
        btn:SetFrameLevel(f:GetFrameLevel() + 1)
        btn:Show()

        if orient == "VERTICAL" then
            xpos = xpos + dock.xdir * BTN_STEP
            col = col + 1
            if col >= maxCols then
                xpos = dock.xstart
                col = 0
                ypos = ypos + dock.ydir * BTN_STEP
                row = row + 1
            end
        else
            ypos = ypos + dock.ydir * BTN_STEP
            col = col + 1
            if col >= maxCols then
                ypos = dock.ystart
                col = 0
                xpos = xpos + dock.xdir * BTN_STEP
                row = row + 1
            end
        end
    end

    local i = #candidates + 1
    while f.buttons[i] do
        f.buttons[i]:Hide()
        i = i + 1
    end

    if col == 0 and row > 0 then
        row = row - 1
    end

    if orient == "VERTICAL" then
        f:SetWidth(FRAME_PAD + (maxCols * BTN_STEP))
        f:SetHeight(FRAME_PAD + ((row + 1) * BTN_STEP))
    else
        f:SetWidth(FRAME_PAD + ((row + 1) * BTN_STEP))
        f:SetHeight(FRAME_PAD + (maxCols * BTN_STEP))
    end
end

function Flyout.Show(anchor, slotID, opts)
    opts = opts or {}
    Flyout.CancelHideTimer()
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if not anchor or not slotID or not Candidates or not Candidates.GetForInventorySlot then
        return
    end

    -- Character sheet: bags only. Bank pieces belong on the respec picker
    -- (and only while the banker is live).
    local candidates = Candidates.GetForInventorySlot(slotID, anchor, { includeBank = false })
    if #candidates == 0 then
        Flyout.Hide()
        return
    end

    if not Flyout._frame then
        local frame = CreateFrame("Frame", "FluxEquipSlotFlyoutFrame", UIParent, "BackdropTemplate")
        frame:SetFrameStrata("HIGH")
        frame:SetFrameLevel(1999)
        frame:EnableMouse(false)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileEdge = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        frame.buttons = {}
        if frame.SetClampedToScreen then
            frame:SetClampedToScreen(true)
        end
        Flyout._frame = frame

        if tinsert and UISpecialFrames then
            for i = #UISpecialFrames, 1, -1 do
                if UISpecialFrames[i] == "FluxEquipSlotFlyout" then
                    tremove(UISpecialFrames, i)
                end
            end
            tinsert(UISpecialFrames, frame:GetName())
        end
    end

    local f = Flyout._frame
    local dockOptions = GetDockOptions(slotID)
    for i = 1, #dockOptions do
        DockMenuToCharacterSheet(anchor, slotID, i)
        LayoutButtons(f, candidates, slotID, anchor)
        f:SetScale(MENU_SCALE)
        f:Show()
        if FrameFitsOnScreen(f) then
            break
        end
    end
    f:Raise()

    Flyout._anchorRef = anchor
    Flyout._openSlotID = slotID
end

function Flyout.NotifyEnter(anchor, slotID, opts)
    if not anchor or not slotID then
        return
    end
    if not Candidates or not Candidates.HasAlternatives(slotID, anchor, { includeBank = false }) then
        return
    end
    Flyout.CancelHideTimer()
    Flyout.CancelShowTimer()
    if C_Timer and C_Timer.After then
        Flyout._showTimer = C_Timer.After(0.06, function()
            Flyout._showTimer = nil
            Flyout.Show(anchor, slotID, opts)
        end)
    else
        Flyout.Show(anchor, slotID, opts)
    end
end

function Flyout.NotifyLeave(opts)
    Flyout.CancelShowTimer()
    Flyout.ScheduleHideSoon(opts and opts.mouseoverFrames)
end

function Flyout.SetOnEquipped(fn)
    Flyout._onEquipped = fn
end
