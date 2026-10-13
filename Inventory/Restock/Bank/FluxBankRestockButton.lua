--[[
    Restock/Bank/FluxBankRestockButton.lua

    Bank restock button anchored to the bottom-left of the bank frame.
    Uses the same merchant-style chrome as the vendor Restock button.
    Withdraw-only: dragging an item onto the button sets a withdraw target
    for it, there is no stash/deposit affordance here.
]]

FluxBankRestockButton = FluxBankRestockButton or {}
local Button = FluxBankRestockButton

local function Bank()
    local inv = _G.FluxRestock and _G.FluxRestock.Inv
    return inv and inv.Bank
end
local function BR() return _G.FluxBankRestock end
local function MUI() return _G.FluxVendorAutoMerchantUI end

local btn
local autoToggle
local editBox
local lastClickFailReason

-- ---------------------------------------------------------------------------
-- SETTINGS HELPERS
-- ---------------------------------------------------------------------------

local function GetFV()
    return _G.FluxVendorAuto
end

local function GetSettings()
    local FV = GetFV()
    if FV and FV.EnsureSettings then
        return FV.EnsureSettings()
    end
    return _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.Restock
end

local function GetCursorItemID()
    if not GetCursorInfo then
        return nil
    end
    local infoType, arg1, arg2 = GetCursorInfo()
    if infoType ~= "item" then
        return nil
    end
    local itemID = tonumber(arg1)
    if not itemID and arg2 then
        itemID = tonumber(string.match(tostring(arg2), "item:(%d+)"))
    end
    return itemID
end

local function AddBankRestockItem(itemID, quantity)
    local s = GetSettings()
    if not s then
        return
    end
    s.restockItems = s.restockItems or {}
    local entry = s.restockItems[itemID]
    if type(entry) ~= "table" then
        entry = { targetQuantity = quantity or 1 }
        s.restockItems[itemID] = entry
    end
    entry.bankRestock = true
    entry.dismissed = nil
    if quantity then
        entry.targetQuantity = math.max(0, math.min(999, quantity))
    end
    local FV = GetFV()
    if FV and FV.NotifyVendorSettingsChanged then
        pcall(FV.NotifyVendorSettingsChanged)
    end
end

local function GetItemTarget(itemID)
    local s = GetSettings()
    if s and s.restockItems and s.restockItems[itemID] then
        return tonumber(s.restockItems[itemID].targetQuantity) or 0
    end
    return 0
end

local function SetButtonEnabled(enabled)
    local ui = MUI()
    if ui and ui.SetRestockButtonEnabled and btn then
        ui.SetRestockButtonEnabled(btn, enabled)
    elseif btn then
        if btn.Icon and btn.Icon.SetDesaturated then
            btn.Icon:SetDesaturated(not enabled)
        end
        if enabled then
            btn:Enable()
        else
            btn:Disable()
        end
    end
end

-- ---------------------------------------------------------------------------
-- INLINE TARGET EDIT BOX
-- ---------------------------------------------------------------------------

local function HideEditBox()
    if editBox then
        editBox:Hide()
        editBox.itemID = nil
    end
end

local function CommitEditBox()
    if not editBox or not editBox.itemID then
        return
    end
    local value = tonumber(editBox:GetText()) or 0
    AddBankRestockItem(editBox.itemID, value)
    HideEditBox()
end

local function EnsureEditBox()
    if editBox then
        return editBox
    end
    editBox = CreateFrame("EditBox", nil, btn, "InputBoxTemplate")
    editBox:SetSize(40, 20)
    editBox:SetPoint("LEFT", btn, "RIGHT", 6, 0)
    editBox:SetAutoFocus(true)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(3)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:Hide()
    editBox:SetScript("OnEnterPressed", function(self)
        CommitEditBox()
        self:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        HideEditBox()
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusLost", function()
        CommitEditBox()
    end)
    return editBox
end

local function ShowEditBox(itemID)
    EnsureEditBox()
    editBox.itemID = itemID
    editBox:SetText(tostring(GetItemTarget(itemID)))
    editBox:Show()
    editBox:HighlightText()
    editBox:SetFocus()
end

-- ---------------------------------------------------------------------------
-- DROP / CLICK HANDLERS
-- ---------------------------------------------------------------------------

local function HandleDrop()
    local itemID = GetCursorItemID()
    if not itemID then
        return false
    end
    ClearCursor()
    if GameTooltip then
        GameTooltip:Hide()
    end
    AddBankRestockItem(itemID, GetItemTarget(itemID) > 0 and GetItemTarget(itemID) or 1)
    ShowEditBox(itemID)
    Button.Refresh()
    return true
end

local function HandleClick()
    if GetCursorItemID() then
        if HandleDrop() then
            return
        end
    end
    if editBox and editBox:IsShown() then
        CommitEditBox()
        return
    end
    local br = BR()
    if not br then
        lastClickFailReason = "Bank restock unavailable."
        return
    end
    if br.IsRunning and br.IsRunning() then
        if br.Stop then
            br.Stop()
        end
        lastClickFailReason = nil
        Button.Refresh()
        return
    end
    if br.CanRunNow and not br.CanRunNow() then
        local bank = Bank()
        local open = bank and bank.IsOpen and bank.IsOpen()
        if not open then
            lastClickFailReason = "Open the bank to restock."
        else
            local pull = br.GetPendingSummary and br.GetPendingSummary() or 0
            if pull <= 0 then
                lastClickFailReason = "Nothing to restock from the bank."
            else
                lastClickFailReason = "Could not start bank restock."
            end
        end
        Button.Refresh()
        return
    end
    if br.RunManual and br.RunManual() then
        lastClickFailReason = nil
    else
        lastClickFailReason = "Could not start bank restock."
    end
    Button.Refresh()
end

-- ---------------------------------------------------------------------------
-- TOOLTIP
-- ---------------------------------------------------------------------------

local function ShowTooltip(self)
    local ui = MUI()
    if not GameTooltip or not ui or not ui.PrepareRestockTooltip then
        return
    end
    ui.PrepareRestockTooltip(self, "Bank Restock")

    local br = BR()
    local items = br and br.GetTooltipItems and br.GetTooltipItems() or {}
    local shown = 0

    for _, entry in ipairs(items) do
        local pull = entry.pull or 0
        local needed = entry.needed or 0
        if entry.restock ~= false and (pull > 0 or needed > 0) then
            if pull > 0 then
                ui.AddRestockTooltipEntry(entry, { r = 0.35, g = 1, b = 0.35 })
            else
                ui.AddRestockTooltipEntry(entry, { r = 1, g = 0.82, b = 0.35 })
            end
            shown = shown + 1
        end
    end

    if shown == 0 then
        GameTooltip:AddLine("Nothing to restock from bank.", 0.6, 0.6, 0.6, true)
    end

    if br and br.IsRunning and br.IsRunning() then
        local progress = br.GetProgress and br.GetProgress()
        if progress and progress.total and progress.total > 0 then
            GameTooltip:AddLine(string.format(
                "Restocking... %d / %d moves",
                progress.current or 0, progress.total), 0.4, 0.8, 1)
        else
            GameTooltip:AddLine("Restocking...", 0.4, 0.8, 1)
        end
        GameTooltip:AddLine("Left-click again to cancel.", 0.5, 0.5, 0.5, true)
    elseif lastClickFailReason then
        GameTooltip:AddLine(lastClickFailReason, 1, 0.35, 0.35, true)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: restock from bank now.", 0.5, 0.5, 0.5, true)
    GameTooltip:AddLine("Drag an item here to add it.", 0.5, 0.5, 0.5, true)
    ui.FinishRestockTooltip()
end

-- ---------------------------------------------------------------------------
-- AUTO TOGGLE CHECKBOX
-- ---------------------------------------------------------------------------

local function EnsureAutoToggle()
    if autoToggle then
        return autoToggle
    end
    local ui = MUI()
    if ui and ui.CreateRestockAutoToggle then
        autoToggle = ui.CreateRestockAutoToggle(btn)
        if ui.ApplyRestockAutoToggleChrome then
            ui.ApplyRestockAutoToggleChrome(autoToggle)
        end
    else
        autoToggle = CreateFrame("CheckButton", nil, btn)
        autoToggle:SetSize(18, 18)
        autoToggle:SetPoint("TOPLEFT", btn, "TOPLEFT", -3, 3)
        autoToggle:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        autoToggle:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        autoToggle:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        autoToggle:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        autoToggle:SetFrameLevel(btn:GetFrameLevel() + 5)
    end
    autoToggle:SetScript("OnClick", function(self)
        local br = BR()
        if br then
            br.SetAutoEnabled(self:GetChecked() and true or false)
            local bank = Bank()
            if self:GetChecked() and bank and bank.IsOpen() then
                br.Start(false)
            end
        end
        Button.Refresh()
    end)
    autoToggle:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Auto Bank Restock")
        GameTooltip:AddLine("Automatically restock from your bank when you open it.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    autoToggle:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return autoToggle
end

-- ---------------------------------------------------------------------------
-- BUTTON CREATION & ANCHORING
-- ---------------------------------------------------------------------------

local function MatchRepairButtonSize(targetBtn)
    if not targetBtn then
        return
    end
    local ref = _G.MerchantRepairAllButton or _G.MerchantRepairItemButton
    if ref and ref.GetSize then
        local w, h = ref:GetSize()
        if w and h and w > 0 and h > 0 then
            targetBtn:SetSize(w, h)
            return
        end
    end
    local cw, ch = targetBtn:GetSize()
    if not cw or not ch or cw < 8 or ch < 8 then
        targetBtn:SetSize(36, 36)
    end
end

local function EnsureButton()
    if btn then
        return btn
    end
    local ui = MUI()
    if ui and ui.CreateRestockStyleButton then
        btn = ui.CreateRestockStyleButton(UIParent, "FluxBankRestockButton")
    else
        btn = CreateFrame("Button", "FluxBankRestockButton", UIParent)
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(btn)
        icon:SetTexture("Interface/Icons/INV_Misc_Bag_08")
        btn.Icon = icon
    end
    btn:SetFrameStrata("HIGH")
    MatchRepairButtonSize(btn)

    btn:RegisterForClicks("LeftButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnClick", HandleClick)
    btn:SetScript("OnReceiveDrag", function()
        HandleDrop()
    end)
    btn:SetScript("OnMouseUp", function(_, mb)
        if mb == "LeftButton" and GetCursorItemID() then
            HandleDrop()
        end
    end)
    btn:SetScript("OnEnter", ShowTooltip)
    btn:SetScript("OnLeave", function()
        local ui = MUI()
        if ui and ui.HideRestockTooltip then
            ui.HideRestockTooltip()
        elseif GameTooltip then
            GameTooltip:Hide()
        end
    end)

    EnsureAutoToggle()
    btn:Hide()
    return btn
end

function Button.Refresh()
    if not btn then
        return
    end
    EnsureAutoToggle()
    local br = BR()
    if br and autoToggle then
        autoToggle:SetChecked(br.IsAutoEnabled())
    end
    -- Prefer cached CanRunNow on attach/open; miss schedules async fill.
    local canRun = false
    if br and br.GetCachedCanRunNow then
        canRun = br.GetCachedCanRunNow() and true or false
    elseif br and br.CanRunNow then
        canRun = br.CanRunNow() and true or false
    end
    local running = br and br.IsRunning and br.IsRunning() or false
    if canRun then
        lastClickFailReason = nil
    end
    SetButtonEnabled(canRun or running)
end

function Button.RefreshIdle()
    if not btn then
        return
    end
    EnsureAutoToggle()
    local br = BR()
    if br and autoToggle then
        autoToggle:SetChecked(br.IsAutoEnabled())
    end
    local canRun = br and br.GetCachedCanRunNow and br.GetCachedCanRunNow() or false
    local running = br and br.IsRunning and br.IsRunning() or false
    if canRun then
        lastClickFailReason = nil
    end
    SetButtonEnabled(canRun or running)
end

-- Lightweight live refresh used while a restock is running: updates the
-- button state and, if the tooltip is currently shown over this button,
-- re-renders it so counts tick down in place without a mouse re-enter.
function Button.RefreshLive()
    local br = BR()
    if br and br.IsRunning and br.IsRunning() then
        if btn then
            EnsureAutoToggle()
            SetButtonEnabled(true)
        end
        if btn and GameTooltip and GameTooltip:IsShown()
            and GameTooltip.GetOwner and GameTooltip:GetOwner() == btn then
            ShowTooltip(btn)
        end
        return
    end
    Button.Refresh()
    if btn and GameTooltip and GameTooltip:IsShown()
        and GameTooltip.GetOwner and GameTooltip:GetOwner() == btn then
        ShowTooltip(btn)
    end
end

-- Bank-frame UI anchoring. Supports Blizzard BankFrame and Baganator bank views.
-- Baganator names views as Prefix .. skinKey (e.g. ...Frameblizzard), not ...Frame1.
-- Public Baganator has no ViewManagement (that table is private).
function Button.FindBaganatorBankView()
    local Compat = _G.FluxBaganatorCompat
    if Compat and Compat.ForEachBaganatorBankView then
        local shown
        Compat.ForEachBaganatorBankView(function(view)
            if view.IsShown and view:IsShown() then
                shown = view
            end
        end)
        return shown
    end

    -- Fallback if compat module is not loaded yet.
    local prefixes = {
        "Baganator_SingleViewBankViewFrame",
        "Baganator_CategoryViewBankViewFrame",
    }
    local suffixes = {
        "1", "2",
        "blizzard", "blizzard_black", "dark", "elvui", "gw2_ui", "ndui",
    }
    local api = _G.Baganator and _G.Baganator.API
    local currentSkin = api and api.Skins and api.Skins.GetCurrentSkin and api.Skins.GetCurrentSkin()
    if currentSkin then
        for p = 1, #prefixes do
            local view = _G[prefixes[p] .. currentSkin]
            if view and view.IsShown and view:IsShown() then
                return view
            end
        end
    end
    for s = 1, #suffixes do
        for p = 1, #prefixes do
            local view = _G[prefixes[p] .. suffixes[s]]
            if view and view.IsShown and view:IsShown() then
                return view
            end
        end
    end
end

local function UsesAlternativeBagUI()
    return _G.FluxUI_UsesAlternativeBagUI and _G.FluxUI_UsesAlternativeBagUI() and true or false
end

local function GetBaganatorBankView()
    if not UsesAlternativeBagUI() then
        return nil
    end
    local Compat = _G.FluxBaganatorCompat
    if Compat and Compat.GetActiveBaganatorBankView then
        return Compat.GetActiveBaganatorBankView()
    end
    return Button.FindBaganatorBankView()
end

local function IsVisibleFrame(frame)
    return frame and frame.IsShown and frame:IsShown()
        and (not frame.IsVisible or frame:IsVisible())
end

local function GetBankAnchorFrame()
    local baganatorView = GetBaganatorBankView()
    if baganatorView then
        return baganatorView
    end
    local bankFrame = _G.BankFrame
    if UsesAlternativeBagUI() then
        if IsVisibleFrame(bankFrame) then
            return bankFrame
        end
        return nil
    end
    if bankFrame and bankFrame.IsShown and bankFrame:IsShown() then
        return bankFrame
    end
    return nil
end

local function UsesPlayerBagsInBank()
    local api = _G.FLUX_API
    if api and api.UsesPlayerBagsInBank then
        return api.UsesPlayerBagsInBank() and true or false
    end
    local Cap = _G.Flux and _G.Flux.Cap
    if Cap and Cap.UsesPlayerBagsInBank then
        return Cap.UsesPlayerBagsInBank() and true or false
    end
    return false
end

local function UsesPreDFBankButtonLayout()
    local api = _G.FLUX_API
    if api and api.UseLegacyBankSlotsUI then
        return api.UseLegacyBankSlotsUI()
    end
    if api and api.HasUnifiedBankUI then
        return not api.HasUnifiedBankUI()
    end
    return not (api and api.isPostDF)
end

local function GetBagsInBankButtonPlacement(bankFrame)
    if not bankFrame or not bankFrame.IsShown or not bankFrame:IsShown() then
        return nil
    end
    local search = bankFrame.BankItemSearchBox or _G.BankItemSearchBox
    if IsVisibleFrame(search) then
        return {
            parent = bankFrame,
            point = "RIGHT",
            relativeTo = search,
            relativePoint = "LEFT",
            x = -4,
            y = 0,
        }
    end
    local panel = bankFrame.BankPanel
    local sortBtn = panel and panel.AutoSortButton
    if IsVisibleFrame(sortBtn) then
        return {
            parent = bankFrame,
            point = "RIGHT",
            relativeTo = sortBtn,
            relativePoint = "LEFT",
            x = -4,
            y = 0,
        }
    end
    -- Keep off the Camelot bag-slot / purchase row at the bottom of BankFrame.
    return {
        parent = bankFrame,
        point = "TOPLEFT",
        relativeTo = bankFrame,
        relativePoint = "TOPLEFT",
        x = 60,
        y = -32,
    }
end

local function GetPreDFButtonPlacement(bankFrame)
    if not bankFrame or not bankFrame.IsShown or not bankFrame:IsShown() then
        return nil
    end
    local moneyFrame = _G.BankFrameMoneyFrame
    if moneyFrame and moneyFrame.IsShown and moneyFrame:IsShown() then
        return {
            parent = bankFrame,
            point = "BOTTOMLEFT",
            relativeTo = moneyFrame,
            relativePoint = "TOPLEFT",
            x = 14,
            y = 8,
        }
    end
    return {
        parent = bankFrame,
        point = "BOTTOMLEFT",
        relativeTo = bankFrame,
        relativePoint = "BOTTOMLEFT",
        x = 14,
        y = 118,
    }
end

function Button.AttachToBaganatorBank(bankView)
    EnsureButton()
    if not bankView then
        return false
    end
    if bankView.IsShown and not bankView:IsShown() then
        return false
    end

    local tab = bankView.currentTab
    if tab and tab.isLocked then
        if btn:GetParent() == bankView then
            btn:Hide()
        end
        return false
    end

    local transfer = bankView.TransferButton
    local anchorLevel = transfer or bankView.SortButton or bankView.CustomiseButton or bankView

    btn:SetParent(bankView)
    btn:SetFrameStrata(bankView:GetFrameStrata() or "HIGH")
    btn:SetFrameLevel((anchorLevel.GetFrameLevel and anchorLevel:GetFrameLevel() or 700) + 5)
    btn:ClearAllPoints()

    -- Prefer visible anchors. Baganator Alt-hide reparents Transfer/Sort to a
    -- hidden parent; IsVisible() catches that so we fall back to Customise.
    if IsVisibleFrame(transfer) then
        btn:SetPoint("RIGHT", transfer, "LEFT", -4, 0)
    elseif IsVisibleFrame(bankView.SortButton) then
        btn:SetPoint("RIGHT", bankView.SortButton, "LEFT", -4, 0)
    elseif IsVisibleFrame(bankView.CustomiseButton) then
        btn:SetPoint("RIGHT", bankView.CustomiseButton, "LEFT", -4, 0)
    else
        btn:SetPoint("TOPRIGHT", bankView, "TOPRIGHT", -120, -4)
    end

    local sized = false
    if transfer and transfer.GetSize then
        local w, h = transfer:GetSize()
        if w and h and w > 0 and h > 0 then
            btn:SetSize(w, h)
            sized = true
        end
    end
    if not sized then
        MatchRepairButtonSize(btn)
    end

    btn:Show()
    if autoToggle then
        autoToggle:SetFrameLevel(btn:GetFrameLevel() + 5)
    end
    local Inv = _G.Flux and _G.Flux.Inventory
    if Inv and Inv.SetBaganatorBankLive then
        Inv.SetBaganatorBankLive(true)
    end
    local Compat = _G.FluxBaganatorCompat
    if Compat and Compat.SyncBaganatorBankLive then
        Compat.SyncBaganatorBankLive()
    end
    return true
end

local function AttachToBlizzardBank(anchor)
    if not anchor then
        return false
    end
    local placement
    if UsesPlayerBagsInBank() then
        placement = GetBagsInBankButtonPlacement(anchor)
    elseif UsesPreDFBankButtonLayout() then
        placement = GetPreDFButtonPlacement(anchor)
    end
    if placement then
        local parent = placement.parent or anchor
        btn:SetParent(parent)
        btn:SetFrameStrata(parent:GetFrameStrata() or "HIGH")
        btn:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
        btn:ClearAllPoints()
        btn:SetPoint(
            placement.point or "BOTTOMLEFT",
            placement.relativeTo or anchor,
            placement.relativePoint or "TOPLEFT",
            placement.x or 14,
            placement.y or 8
        )
    else
        btn:SetParent(anchor)
        btn:SetFrameStrata(anchor:GetFrameStrata() or "HIGH")
        btn:SetFrameLevel((anchor:GetFrameLevel() or 1) + 20)
        btn:ClearAllPoints()
        btn:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 14, 14)
    end
    MatchRepairButtonSize(btn)
    btn:Show()
    if autoToggle then
        autoToggle:SetFrameLevel(btn:GetFrameLevel() + 5)
    end
    return true
end

function Button.AttachToBank()
    EnsureButton()
    if UsesAlternativeBagUI() then
        local baganatorView = GetBaganatorBankView()
        if baganatorView and Button.AttachToBaganatorBank(baganatorView) then
            Button.RefreshIdle()
            return
        end
        local Compat = _G.FluxBaganatorCompat
        if Compat and Compat.AttachBankRestockButton then
            Compat.AttachBankRestockButton()
            if btn and btn:IsShown() and IsVisibleFrame(btn) then
                Button.RefreshIdle()
                return
            end
        end
        -- Baganator loaded but no shown view: Blizzard BankFrame only if actually
        -- visible. Baganator reparents BankFrame under a hidden parent.
        local hiddenDefault = _G.BankFrame
        if IsVisibleFrame(hiddenDefault) then
            AttachToBlizzardBank(hiddenDefault)
            Button.RefreshIdle()
        end
        return
    end

    local anchor = _G.BankFrame
    if not anchor or not anchor.IsShown or not anchor:IsShown() then
        return
    end
    AttachToBlizzardBank(anchor)
    Button.RefreshIdle()
end

-- ---------------------------------------------------------------------------
-- LIFECYCLE
-- ---------------------------------------------------------------------------

local function OnBankOpen()
    -- Backup: two delayed attaches. Extra BANKFRAME/PIM/OnShow hooks plus
    -- RefreshIfOpen on every attach re-scanned the bank and froze the client.
    local After = (FluxAPICompat and FluxAPICompat.After) or (C_Timer and C_Timer.After)
    if After then
        After(0.2, Button.AttachToBank)
        After(0.6, Button.AttachToBank)
    else
        Button.AttachToBank()
    end
end

local function OnBankClose()
    local Inv = _G.Flux and _G.Flux.Inventory
    if Inv and Inv.IsBaganatorBankViewShown and Inv.IsBaganatorBankViewShown() then
        return
    end
    HideEditBox()
    lastClickFailReason = nil
    if btn then
        btn:Hide()
    end
end

EnsureButton()

local function RegisterBankCallbacks()
    local bank = Bank()
    if not bank or not bank.RegisterBankOpen then
        return false
    end
    bank.RegisterBankOpen("FluxBankRestockButton", OnBankOpen)
    bank.RegisterBankClose("FluxBankRestockButton", OnBankClose)
    return true
end

if not RegisterBankCallbacks() then
    local After = (FluxAPICompat and FluxAPICompat.After) or (C_Timer and C_Timer.After)
    if After then
        After(0, RegisterBankCallbacks)
        After(1, RegisterBankCallbacks)
    end
end

_G.FluxBankRestockButton = Button
return Button
