-- FluxRespec_RunePicker.lua
-- SoD: RuneReminder-style vertical flyout (icons stacked above slot, no inner scroll). Opens on mouseover.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.RunePicker = R.RunePicker or {}
local P = R.RunePicker
local Compat = R.Compat

local ADJUST_SLOT = {
    [12] = 11,
    [15] = 16,
}

local function AdjustedCategorySlot(slotID)
    return ADJUST_SLOT[slotID] or slotID
end

local ICON_BTN = 32
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

local function BuildAlternatives(slotID)
    if not (_G.C_Engraving and _G.C_Engraving.GetRunesForCategory) then
        return {}
    end
    pcall(function()
        if _G.C_Engraving.RefreshRunesList then _G.C_Engraving.RefreshRunesList() end
    end)
    local cat = AdjustedCategorySlot(slotID)
    pcall(function()
        _G.C_Engraving.ClearCategoryFilter(cat)
        _G.C_Engraving.ClearExclusiveCategoryFilter()
        _G.C_Engraving.SetSearchFilter("")
    end)
    local all = {}
    local ok, runes = pcall(_G.C_Engraving.GetRunesForCategory, cat, false)
    if ok and type(runes) == "table" then
        all = runes
    end
    local currentID
    do
        local ok2, r = pcall(_G.C_Engraving.GetRuneForEquipmentSlot, slotID)
        if ok2 and r and r.skillLineAbilityID then
            currentID = r.skillLineAbilityID
        end
    end
    local filtered = {}
    for _, rune in ipairs(all) do
        if not (currentID and rune.skillLineAbilityID == currentID) then
            filtered[#filtered + 1] = rune
        end
    end
    return filtered
end

function P.HasAlternatives(slotID)
    return #BuildAlternatives(slotID) > 0
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

function P.NotifyStripEnter(anchor, slotID)
    if not (Compat and Compat.IsSoD and Compat.IsSoD()) then return end
    if R.GearPicker and R.GearPicker.Hide then
        R.GearPicker.Hide()
    end
    P.CancelHideTimer()
    P.CancelShowTimer()
    if not anchor or not slotID then return end
    if not P.HasAlternatives(slotID) then return end
    if _G.C_Timer and _G.C_Timer.After then
        P._showTimer = C_Timer.After(0.06, function()
            P._showTimer = nil
            P.Show(anchor, slotID, function() end)
        end)
    else
        P.Show(anchor, slotID, function() end)
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

function P.Show(anchor, slotID, onPicked)
    P.CancelHideTimer()
    if not (Compat and Compat.IsSoD and Compat.IsSoD()) then return end
    if not anchor or not slotID then return end

    local all = BuildAlternatives(slotID)
    if #all == 0 then
        P.Hide()
        return
    end

    if not P._flyout then
        local f = CreateFrame("Frame", "FluxRespecRuneFlyout", UIParent, "BackdropTemplate")
        f:SetFrameStrata("TOOLTIP")
        f:SetFrameLevel(2000)
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
        if f.scroll then
            f.scroll:Hide()
            f.scroll:SetParent(nil)
            f.scroll = nil
        end
        content = CreateFrame("Frame", nil, f)
        content:SetPoint("TOPLEFT", f, "TOPLEFT", SIDE_PAD, -SIDE_PAD)
        f.content = content
    end

    for _, b in ipairs(f.buttons) do
        b:Hide()
    end

    local y = 0
    for i, rune in ipairs(all) do
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
                local r = self._rune
                if not r or not r.skillLineAbilityID then return end
                P.Hide()
                if R.Runes and R.Runes.CastSkillLineOnSlot then
                    R.Runes.CastSkillLineOnSlot(self._slotID, r.skillLineAbilityID)
                end
                if onPicked then pcall(onPicked) end
                if R.UI and R.UI.Refresh then R.UI.Refresh() end
            end)
            btn:SetScript("OnEnter", function(self)
                P.CancelHideTimer()
                local r = self._rune
                if not r then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if r.skillLineAbilityID and GameTooltip.SetEngravingRune then
                    pcall(GameTooltip.SetEngravingRune, GameTooltip, r.skillLineAbilityID)
                elseif r.name then
                    GameTooltip:AddLine(r.name, 0.67, 0.85, 0.92)
                end
                GameTooltip:Show()
                RaiseGameTooltipAboveFlyout()
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            f.buttons[i] = btn
        end
        btn._rune = rune
        btn._slotID = slotID
        if btn.iconTex then
            btn.iconTex:SetTexture(rune.iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
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

    if anchor and anchor.IsMouseOver and anchor:IsMouseOver() and R.UI and R.UI.ShowRuneStripTooltip then
        R.UI.ShowRuneStripTooltip(anchor)
    end

    SyncRespecScrollPad()
end
