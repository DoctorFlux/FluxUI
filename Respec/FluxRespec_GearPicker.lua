-- FluxRespec_GearPicker.lua
-- No profile: bag items equippable into a slot — vertical icon flyout above the gear strip.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.GearPicker = R.GearPicker or {}
local P = R.GearPicker

local ICON_BTN = 30
local ROW_GAP = 4
local SIDE_PAD = 6
local FLYOUT_WIDTH = ICON_BTN + SIDE_PAD * 2

P._extraScrollBottom = 0

function P.GetExtraScrollBottom()
    return P._extraScrollBottom or 0
end

local function SyncRespecScrollPad()
    P._extraScrollBottom = 0
    if R.UI and R.UI.SyncRespecScrollForFlyout then
        R.UI.SyncRespecScrollForFlyout()
    end
end

local function RaiseGameTooltipAboveFlyout()
    local tip = _G.GameTooltip
    local fly = P._flyout
    if not tip or not fly or not tip.SetFrameStrata then return end
    tip:SetFrameStrata("TOOLTIP")
    local lv = fly.GetFrameLevel and fly:GetFrameLevel() or 2000
    if tip.SetFrameLevel then
        tip:SetFrameLevel(lv + 50)
    end
end

local function PositionFlyoutAboveAnchor(f, anchor)
    f:ClearAllPoints()
    f:SetPoint("BOTTOM", anchor, "TOP", 0, 4)
end

P._flyout = nil
P._anchorRef = nil
P._openSlotID = nil
P._hideTimer = nil
P._showTimer = nil

local function CancelTimer(t)
    if t and t.Cancel then
        t:Cancel()
    end
    return nil
end

function P.CancelHideTimer()
    P._hideTimer = CancelTimer(P._hideTimer)
end

function P.CancelShowTimer()
    P._showTimer = CancelTimer(P._showTimer)
end

function P.IsOpenFor(slotID, anchor)
    if not P._flyout or not P._flyout:IsShown() then
        return false
    end
    if slotID and P._openSlotID ~= slotID then
        return false
    end
    if anchor and P._anchorRef ~= anchor then
        return false
    end
    return true
end

function P.HasAlternatives(slotID)
    local Eq = R.Equipment
    if not Eq or not Eq.GetBagCandidatesForInventorySlot or not slotID then
        return false
    end
    local candidates = Eq.GetBagCandidatesForInventorySlot(slotID)
    return type(candidates) == "table" and #candidates > 0
end

function P.Hide()
    P.CancelHideTimer()
    P.CancelShowTimer()
    if P._flyout then
        P._flyout:Hide()
    end
    P._anchorRef = nil
    P._openSlotID = nil
    P._extraScrollBottom = 0
    if R.UI and R.UI.SyncRespecScrollForFlyout then
        R.UI.SyncRespecScrollForFlyout()
    end
end

local function MouseOverAnyDropDownList()
    if _G.FluxBlizzardDropdown and _G.FluxBlizzardDropdown.IsMouseOver then
        return _G.FluxBlizzardDropdown.IsMouseOver()
    end
    return false
end

local function CandidateIcon(c)
    if c.itemLink and _G.GetItemInfo then
        local tex = select(10, _G.GetItemInfo(c.itemLink))
        if tex then return tex end
    end
    if c.itemID and _G.C_Item and _G.C_Item.GetItemIconByID then
        local ok, ico = pcall(_G.C_Item.GetItemIconByID, c.itemID)
        if ok and ico then return ico end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function P.NotifyStripEnter(anchor, slotID)
    if R.GetActiveName and R.GetActiveName() then return end
    if not anchor or not slotID then return end
    if not P.HasAlternatives(slotID) then return end
    if R.RunePicker and R.RunePicker.Hide then
        R.RunePicker.Hide()
    end
    P.CancelHideTimer()
    P.CancelShowTimer()
    if _G.C_Timer and _G.C_Timer.After then
        P._showTimer = C_Timer.After(0.06, function()
            P._showTimer = nil
            P.Show(anchor, slotID)
        end)
    else
        P.Show(anchor, slotID)
    end
end

function P.NotifyStripLeave()
    P.CancelShowTimer()
    P.ScheduleHideSoon()
end

function P.ScheduleHideSoon()
    P.CancelHideTimer()
    if not _G.C_Timer or not _G.C_Timer.After then
        P.Hide()
        return
    end
    P._hideTimer = C_Timer.After(0.48, function()
        P._hideTimer = nil
        local f = P._flyout
        if not f or not f:IsShown() then return end
        if f:IsMouseOver() then return end
        if P._anchorRef and P._anchorRef.IsMouseOver and P._anchorRef:IsMouseOver() then return end
        if MouseOverAnyDropDownList() then return end
        P.Hide()
    end)
end

function P.Show(anchor, slotID)
    P.CancelHideTimer()
    if R.GetActiveName and R.GetActiveName() then return end
    if not anchor or not slotID then return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        if R.Warn then R.Warn("Cannot change gear in combat.") end
        return
    end

    local Eq = R.Equipment
    if not Eq or not Eq.GetBagCandidatesForInventorySlot or not Eq.EquipBagSlotToInventorySlot then return end

    local candidates = Eq.GetBagCandidatesForInventorySlot(slotID)
    if #candidates == 0 then
        P.Hide()
        return
    end

    if not P._flyout then
        local f = CreateFrame("Frame", "FluxRespecGearFlyout", UIParent, "BackdropTemplate")
        f:SetFrameStrata("TOOLTIP")
        f:SetFrameLevel(1999)
        f:EnableMouse(true)
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
        f:SetBackdropColor(0.09, 0.09, 0.09, 0.92)

        local content = CreateFrame("Frame", nil, f)
        content:SetPoint("TOPLEFT", f, "TOPLEFT", SIDE_PAD, -SIDE_PAD)
        f.content = content
        f.buttons = {}

        f:SetScript("OnEnter", function()
            P.CancelHideTimer()
        end)
        f:SetScript("OnLeave", function()
            P.ScheduleHideSoon()
        end)

        P._flyout = f

        if _G.tinsert and _G.UISpecialFrames then
            tinsert(_G.UISpecialFrames, f:GetName())
        end
    end

    local f = P._flyout
    local content = f.content
    if not content then
        content = CreateFrame("Frame", nil, f)
        content:SetPoint("TOPLEFT", f, "TOPLEFT", SIDE_PAD, -SIDE_PAD)
        f.content = content
    end

    for _, b in ipairs(f.buttons) do
        b:Hide()
    end

    local y = 0
    for i, c in ipairs(candidates) do
        local btn = f.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, content)
            btn:SetSize(ICON_BTN, ICON_BTN)
            local tex = btn:CreateTexture(nil, "ARTWORK")
            tex:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
            tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.iconTex = tex
            btn:RegisterForClicks("LeftButtonUp")
            btn:SetScript("OnClick", function(self)
                local bag, bslot, inv = self._bag, self._bagSlot, self._invSlot
                if bag == nil or not bslot or not inv then return end
                P.Hide()
                Eq.EquipBagSlotToInventorySlot(bag, bslot, inv)
                if R.UI and R.UI.Refresh then R.UI.Refresh() end
            end)
            btn:SetScript("OnEnter", function(self)
                P.CancelHideTimer()
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local bag, bslot = self._bag, self._bagSlot
                if bag ~= nil and bslot and GameTooltip.SetBagItem then
                    pcall(GameTooltip.SetBagItem, GameTooltip, bag, bslot)
                    if self._source == "bank" or self._source == "warband" then
                        GameTooltip:AddLine("In bank — click to take and equip.", 1, 0.72, 0.38, true)
                    end
                elseif self._itemLink and GameTooltip.SetHyperlink then
                    pcall(GameTooltip.SetHyperlink, GameTooltip, self._itemLink)
                elseif self._name then
                    GameTooltip:AddLine(self._name, 1, 1, 1)
                end
                GameTooltip:Show()
                RaiseGameTooltipAboveFlyout()
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            f.buttons[i] = btn
        end
        btn._bag = c.bag
        btn._bagSlot = c.slot
        btn._invSlot = slotID
        btn._itemLink = c.itemLink
        btn._name = c.name
        btn._source = c.source
        if btn.iconTex then
            btn.iconTex:SetTexture(CandidateIcon(c))
        end
        btn:SetParent(content)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", SIDE_PAD, -y)
        btn:Show()
        y = y + ICON_BTN + ROW_GAP
    end

    local contentH = math.max(1, y - ROW_GAP)
    content:SetSize(FLYOUT_WIDTH, math.max(contentH, 24))
    f:SetWidth(FLYOUT_WIDTH + SIDE_PAD * 2)
    f:SetHeight(contentH + SIDE_PAD * 2)

    PositionFlyoutAboveAnchor(f, anchor)
    f:Show()
    f:Raise()

    P._anchorRef = anchor
    P._openSlotID = slotID

    if anchor and anchor.IsMouseOver and anchor:IsMouseOver() and R.UI and R.UI.ShowGearStripTooltip then
        R.UI.ShowGearStripTooltip(anchor)
    end

    SyncRespecScrollPad()
end
