--[[
    Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua
    Bulk vendor purchase UI (Shift+click). Ported from BuyEmAllClassic.
]]

FluxBuyEmAll = FluxBuyEmAll or {}
local M = FluxBuyEmAll
local Compat = FluxBuyEmAllCompat

BUYEMALL_LOCALS = BUYEMALL_LOCALS or {
    MAX = "Max",
    STACK = "Stack",
    CONFIRM = "Are you sure you want to buy\n %d × %s?",
    STACK_PURCH = "Stack Purchase",
    STACK_SIZE = "Stack size",
    PARTIAL = "Partial stack",
    MAX_PURCH = "Maximum purchase",
    FIT = "You can fit",
    AFFORD = "You can afford",
    AVAILABLE = "Vendor has",
}
local L = BUYEMALL_LOCALS
local strfind = string.find
local strmatch = string.match

local function GetMerchantSlotInfo(slotIndex)
    local Buy = _G.FluxVendorBuy
    if Buy and Buy.GetMerchantSlotInfo then
        return Buy.GetMerchantSlotInfo(slotIndex)
    end
    if GetMerchantItemInfo then
        return GetMerchantItemInfo(slotIndex)
    end
    return nil
end

BUYEMALL_MAX = L.MAX
BUYEMALL_STACK = L.STACK

local function EnsureCharSettings()
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}

    if _FluxUI_CharSavedVars.buyEmAllEnabled == nil then
        _FluxUI_CharSavedVars.buyEmAllEnabled = true
    end

    if _FluxUI_CharSavedVars.buyEmAllConfirmLarge == nil then
        if _G.BEAConfirmToggle == false or _G.BEAConfirmToggle == 0 then
            _FluxUI_CharSavedVars.buyEmAllConfirmLarge = false
        elseif _G.BEAConfirmToggle == true or _G.BEAConfirmToggle == 1 then
            _FluxUI_CharSavedVars.buyEmAllConfirmLarge = true
        else
            _FluxUI_CharSavedVars.buyEmAllConfirmLarge = true
        end
    end

    return _FluxUI_CharSavedVars
end

function M:IsEnabled()
    local s = EnsureCharSettings()
    return s.buyEmAllEnabled ~= false
end

function M:IsConfirmLargeEnabled()
    local s = EnsureCharSettings()
    return s.buyEmAllConfirmLarge ~= false
end

function M:SetConfirmLargeEnabled(enabled)
    local s = EnsureCharSettings()
    s.buyEmAllConfirmLarge = enabled and true or false
end

local function GetItemCountCompat(itemID, includeBank)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    if _G.FluxGetItemCount then
        return _G.FluxGetItemCount(itemID, { includeBank = includeBank }) or 0
    end
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, includeBank) or 0
    end
    if GetItemCount then
        return GetItemCount(itemID, includeBank) or 0
    end
    return 0
end

function M:OnLoad()
    StaticPopupDialogs["BUYEMALL_CONFIRM"] = {
        preferredIndex = 3,
        text = L.CONFIRM,
        button1 = YES,
        button2 = NO,
        OnAccept = function(dialog) self:DoPurchase(dialog.data) end,
        timeout = 0,
        hideOnEscape = true,
    }
    self.ConfirmNoItemLink = 0
    StaticPopupDialogs["BUYEMALL_CONFIRM2"] = {
        preferredIndex = 3,
        text = L.CONFIRM,
        button1 = YES,
        button2 = NO,
        OnAccept = function(dialog) BuyMerchantItem(self.ConfirmNoItemLink) end,
        timeout = 0,
        hideOnEscape = true,
    }

    BuyEmAllCurrency1:SetTexture()
    BuyEmAllCurrency2:SetTexture()
    BuyEmAllCurrency3:SetTexture()
    BuyEmAllCurrencyAmt1:SetText()
    BuyEmAllCurrencyAmt2:SetText()
    BuyEmAllCurrencyAmt3:SetText()

    if MerchantItemButton_OnModifiedClick and MerchantFrame then
        self.OrigMerchantItemButton_OnModifiedClick = MerchantItemButton_OnModifiedClick
        MerchantItemButton_OnModifiedClick = function(frame, button)
            self:MerchantItemButton_OnModifiedClick(frame, button)
        end

        self.OrigMerchantFrame_OnHide = MerchantFrame:GetScript("OnHide")
        MerchantFrame:SetScript("OnHide", function(...)
            return self:MerchantFrame_OnHide(...)
        end)
    end

    SLASH_BUYEMALL1 = "/buyemall"
    SlashCmdList["BUYEMALL"] = function(message, editbox)
        M:SlashHandler(message)
    end
end

function M:SlashHandler(message)
    if message == "" then
        print("BuyEmAll: Use /buyemall confirm to enable/disable the large purchase confirm.")
    elseif message == "confirm" then
        if self:IsConfirmLargeEnabled() then
            self:SetConfirmLargeEnabled(false)
            print("BuyEmAll: Large purchase confirm window disabled.")
        else
            self:SetConfirmLargeEnabled(true)
            print("BuyEmAll: Large purchase confirm window enabled.")
        end
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == "_FluxUI" then
        EnsureCharSettings()
    end
end)

function M:MerchantFrame_OnHide(...)
    BuyEmAllFrame:Hide()
    if self.OrigMerchantFrame_OnHide then
        return self.OrigMerchantFrame_OnHide(...)
    end
end

function M:CogsFreeBagSpace(itemID)
    if Compat and Compat.GetPurchasableBagSpace then
        return Compat.GetPurchasableBagSpace(itemID)
    end
    return 0, 20
end

function M:MerchantItemButton_OnModifiedClick(frame, button)
    if not self:IsEnabled() then
        if self.OrigMerchantItemButton_OnModifiedClick then
            self.OrigMerchantItemButton_OnModifiedClick(frame, button)
        end
        return
    end

    self.itemIndex = frame:GetID()

    if (MerchantFrame.selectedTab == 1)
            and IsShiftKeyDown()
            and not IsControlKeyDown()
            and not ChatFrame1EditBox:HasFocus() then
        self.NPCName = UnitName("npc")

        self.AltCurrencyMode = false
        self.AtVendor = true

        local name, texture, price, quantity, numAvailable = GetMerchantSlotInfo(self.itemIndex)
        self.itemName = name
        self.price = price
        self.preset = quantity
        self.available = numAvailable
        self.itemLink = GetMerchantItemLink(self.itemIndex)

        if self.itemLink == nil then
            self.ConfirmNoItemLink = self.itemIndex
            StaticPopup_Show("BUYEMALL_CONFIRM2", quantity, self.itemName)
            return
        end

        if strmatch(self.itemLink, "currency") and self.price == 0 then
            local totalMax = select(6, GetCurrencyInfo(self.itemLink))
            if totalMax == 0 then
                self.fit = 10000000
            elseif totalMax > 0 then
                self.fit = totalMax
            end
            self.stack = self.preset
            self:AltCurrencyHandling(self.itemIndex, frame)
            return
        end

        if strmatch(self.itemLink, "item") then
            self.itemID = tonumber(strmatch(self.itemLink, "item:(%d+):"))
            local bagMax, stack = self:CogsFreeBagSpace(self.itemID)
            self.stack = stack
            self.fit = bagMax
            self.partialFit = self.fit % stack
        elseif strmatch(self.itemLink, "currency") then
            self.stack = self.preset
            local currencyMax = select(6, GetCurrencyInfo(self.itemLink))
            if currencyMax == 0 then
                self.fit = 10000000
                self.partialFit = 0
            else
                self.fit = currencyMax
                self.partialFit = currencyMax - select(2, GetCurrencyInfo(self.itemLink))
            end
        end

        if select(8, GetMerchantSlotInfo(self.itemIndex)) == true and self.price == 0 then
            self:AltCurrencyHandling(self.itemIndex, frame)
            return
        end

        BuyEmAllCurrency1:SetTexture("Interface\\MONEYFRAME\\UI-GoldIcon")
        BuyEmAllCurrency2:SetTexture("Interface\\MONEYFRAME\\UI-SilverIcon")
        BuyEmAllCurrency3:SetTexture("Interface\\MONEYFRAME\\UI-CopperIcon")

        if self.price == 0 then
            self.afford = self.fit
        else
            self.afford = floor(GetMoney() / ceil(self.price / self.preset))
        end

        self.max = min(self.fit, self.afford)
        if numAvailable > -1 then
            self.max = min(self.max, numAvailable)
        end
        if self.max == 0 then
            return
        elseif self.max == 1 then
            MerchantItemButton_OnClick(frame, "LeftButton")
            return
        end

        self.defaultStack = quantity
        self.split = 1

        self:SetStackClick()
        self:Show(frame)
    elseif self.OrigMerchantItemButton_OnModifiedClick then
        self.OrigMerchantItemButton_OnModifiedClick(frame, button)
    end
end

function M:AltCurrencyHandling(itemIndex, frame)
    self.AltCurrencyMode = true

    self.NumAltCurrency = GetMerchantItemCostInfo(itemIndex)

    self.AltCurrTex = {}
    self.AltCurrPrice = {}
    self.AltCurrAfford = {}

    for i = 1, self.NumAltCurrency do
        self.AltCurrPrice[i] = select(2, GetMerchantItemCostItem(itemIndex, i))
        local Link = select(3, GetMerchantItemCostItem(itemIndex, i))
        if strmatch(Link, "currency") then
            self.AltCurrTex[i] = select(1, GetMerchantItemCostItem(itemIndex, i))
            self.AltCurrAfford[i] = floor(select(2, GetCurrencyInfo(Link)) / self.AltCurrPrice[i]) * self.preset
        else
            self.AltCurrTex[i] = select(1, GetMerchantItemCostItem(itemIndex, i))
            self.AltCurrAfford[i] = floor(GetItemCountCompat(tonumber(strmatch(Link, "item:(%d+):")), true) / self.AltCurrPrice[i]) * self.preset
        end
    end

    if self.NumAltCurrency == 1 then
        self.afford = self.AltCurrAfford[1]
    else
        self.afford = min(self.AltCurrAfford[1], self.AltCurrAfford[2] or 999999, self.AltCurrAfford[3] or 999999)
    end

    self.max = min(self.fit, self.afford)

    if self.available > -1 then
        self.max = min(self.max, self.available * self.preset)
    end

    if self.max == 0 then
        return
    elseif self.max == 1 then
        MerchantItemButton_OnClick(frame, "LeftButton")
        return
    end

    self.defaultStack = self.preset
    self.split = self.defaultStack

    self.partialFit = self.fit % self.stack
    self:SetStackClick()

    self.NPCName = UnitName("npc")
    self.ItemName = select(1, GetMerchantSlotInfo(self.itemIndex))

    self:Show(frame)
end

function M:Show(frame)
    self.typing = false
    BuyEmAllLeftButton:Disable()
    BuyEmAllRightButton:Enable()

    BuyEmAllStackButton:Enable()
    if self.max < self.stackClick then
        BuyEmAllStackButton:Disable()
    end

    BuyEmAllFrame:ClearAllPoints()
    BuyEmAllFrame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)

    BuyEmAllFrame:Show()
    self:UpdateDisplay()
end

function M:VerifyPurchase(amount)
    amount = amount or self.split

    if self.AltCurrencyMode == true then
        amount = self:AltCurrRounding(amount)
    end

    if amount > 0 then
        if amount > self.stack and amount > self.defaultStack then
            if self:IsConfirmLargeEnabled() then
                self:DoConfirmation(amount)
            else
                self:DoPurchase(amount)
            end
        else
            self:DoPurchase(amount)
        end
    end
end

local framePurchAmount, frameNumLoops, frameLeftover = 0, 0, 0
local frameItemIndex

local PurchaseLoopFrame = CreateFrame("Frame")
function M:onUpdate(sinceLastUpdate)
    self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate
    if self.sinceLastUpdate >= 0.5 then
        if frameNumLoops == 0 and frameLeftover == 0 then
            PurchaseLoopFrame:SetScript("OnUpdate", nil)
            return
        end
        if frameNumLoops == 0 and frameLeftover ~= 0 then
            BuyMerchantItem(frameItemIndex, frameLeftover)
            frameLeftover = 0
        elseif frameNumLoops > 0 then
            BuyMerchantItem(frameItemIndex, framePurchAmount)
            frameNumLoops = frameNumLoops - 1
        end
        self.sinceLastUpdate = 0
    end
end

function M:DoPurchase(amount)
    BuyEmAllFrame:Hide()
    local numLoops, purchAmount, leftover

    if amount <= self.stack then
        purchAmount = amount
        numLoops = 1
        leftover = 0
    else
        if amount % self.stack > 0 then
            purchAmount = self.stack
            numLoops = floor(amount / self.stack)
            leftover = amount % self.stack
        else
            purchAmount = self.stack
            numLoops = floor(amount / self.stack)
            leftover = 0
        end
    end

    framePurchAmount = purchAmount
    frameNumLoops = numLoops
    frameLeftover = leftover == 0 and 0 or leftover
    frameItemIndex = self.itemIndex

    PurchaseLoopFrame:SetScript("OnUpdate", M.onUpdate)
end

function M:AltCurrRounding(purchase)
    local singleCost = 0
    local amount = purchase
    for i = 1, self.NumAltCurrency do
        if self.AltCurrPrice[i] == 1 then
            singleCost = 1
        end
    end
    if singleCost then
        if (purchase % self.preset) < (self.preset / 2) then
            amount = purchase - (purchase % self.preset)
            return amount
        elseif (purchase % self.preset) >= (self.preset / 2) then
            amount = purchase + (self.preset - (purchase % self.preset))
            return amount
        end
    else
        return amount
    end
end

function M:UpdateDisplay()
    BuyEmAllLeftButton:Enable()
    BuyEmAllRightButton:Enable()
    BuyEmAllMaxButton:Enable()
    if self.split == self.max then
        BuyEmAllRightButton:Disable()
        BuyEmAllMaxButton:Disable()
    end
    if self.AltCurrencyMode == false and self.split == 1 then
        BuyEmAllLeftButton:Disable()
    end
    if self.AltCurrencyMode == true and self.split == self.preset then
        BuyEmAllLeftButton:Disable()
    end

    self:SetStackClick()
    BuyEmAllStackButton:Enable()
    if self.max < self.stackClick then
        BuyEmAllStackButton:Disable()
    end

    local purchase = self.split

    if self.AltCurrencyMode == false then
        local cost = 0
        if self.defaultStack > 1 then
            cost = purchase * (self.price / self.defaultStack)
        else
            cost = purchase * self.price
        end
        cost = ceil(cost)
        local gold = floor(abs(cost / 10000))
        local silver = floor(abs(mod(cost / 100, 100)))
        local copper = floor(abs(mod(cost, 100)))

        BuyEmAllCurrencyAmt1:SetText(gold)
        BuyEmAllCurrencyAmt2:SetText(silver)
        BuyEmAllCurrencyAmt3:SetText(copper)
    elseif self.AltCurrencyMode == true then
        local amount = self:AltCurrRounding(purchase)
        self.AltNumPurchases = amount / self.preset

        BuyEmAllCurrencyAmt1:SetText(self.AltNumPurchases * self.AltCurrPrice[1])
        BuyEmAllCurrency1:SetTexture(self.AltCurrTex[1])
        BuyEmAllCurrencyAmt2:SetText(self.AltNumPurchases * (self.AltCurrPrice[2] or 0))
        BuyEmAllCurrency2:SetTexture(self.AltCurrTex[2])
        if self.AltCurrPrice[2] == nil then BuyEmAllCurrencyAmt2:SetText() end
        BuyEmAllCurrencyAmt3:SetText(self.AltNumPurchases * (self.AltCurrPrice[3] or 0))
        BuyEmAllCurrency3:SetTexture(self.AltCurrTex[3])
        if self.AltCurrPrice[2] == nil then BuyEmAllCurrencyAmt3:SetText() end
    end

    BuyEmAllText:SetText(self.split)
end

function M:DoConfirmation(amount)
    local dialog = StaticPopup_Show("BUYEMALL_CONFIRM", amount, self.itemName)
    dialog.data = amount
end

function M:SetStackClick()
    local increase = (self.partialFit == 0 and self.stack or self.partialFit) - (self.split % self.stack)
    self.stackClick = self.split + (increase == 0 and self.stack or increase)
end

function M:DeStackClick()
    local decrease = tonumber(BuyEmAllText:GetText())
    if decrease <= self.stack then
        self.split = 1
        self:UpdateDisplay()
    else
        self.split = decrease - self.stack
        self:UpdateDisplay()
    end
end

function M:OnClick(frame, button)
    if frame == BuyEmAllOkayButton then
        local amount = tonumber(BuyEmAllText:GetText())
        self:VerifyPurchase(amount)
    elseif frame == BuyEmAllCancelButton then
        BuyEmAllFrame:Hide()
    elseif frame == BuyEmAllStackButton then
        if button == "LeftButton" then
            self.split = self.stackClick
            self:UpdateDisplay()
            if frame:IsEnabled() == true then
                self:OnEnter(frame)
            else
                GameTooltip:Hide()
            end
        elseif button == "RightButton" then
            self:DeStackClick()
            self:UpdateDisplay()
            if frame:IsEnabled() == true then
                self:OnEnter(frame)
            else
                GameTooltip:Hide()
            end
        end
    elseif frame == BuyEmAllMaxButton then
        self.split = self.max
        self:UpdateDisplay()
    end
end

function M:OnChar(text)
    if text < "0" or text > "9" then
        return
    end

    if self.typing == false then
        self.typing = true
        self.split = 0
    end

    local input = (self.split * 10) + text

    if input == self.split then
        if self.split == 0 then
            self.split = 1
        end
        self:UpdateDisplay()
        return
    end
    if input <= self.max then
        self.split = input
    elseif input > self.max then
        self.split = self.max
    elseif input <= 0 then
        self.split = 1
    end
    self:UpdateDisplay()
end

function M:OnKeyDown(key)
    if key == "BACKSPACE" or key == "DELETE" then
        if self.typing == false or self.split == 1 then
            return
        end

        self.split = floor(self.split / 10)
        if self.split <= 1 then
            self.split = 1
            self.typing = false
        end

        self:UpdateDisplay()
    elseif key == "ENTER" then
        self:VerifyPurchase()
    elseif key == "ESCAPE" then
        BuyEmAllFrame:Hide()
    elseif key == "LEFT" or key == "DOWN" then
        M:Left_Click()
    elseif key == "RIGHT" or key == "UP" then
        M:Right_Click()
    elseif key == "PRINTSCREEN" then
        Screenshot()
    end
end

function M:Left_Click()
    if self.AltCurrencyMode == false then
        self.split = self.split - 1
        self:UpdateDisplay()
    else
        self.split = self.split - self.preset
        self:UpdateDisplay()
    end
end

function M:Right_Click()
    if self.AltCurrencyMode == false then
        self.split = self.split + 1
        self:UpdateDisplay()
    else
        self.split = self.split + self.preset
        self:UpdateDisplay()
    end
end

M.lines = {
    stack = {
        label = L.STACK_PURCH,
        field = "stackClick",
        { label = L.STACK_SIZE, field = "stack" },
        { label = L.PARTIAL, field = "partialFit" },
    },
    max = {
        label = L.MAX_PURCH,
        field = "max",
        { label = L.AFFORD, field = "afford" },
        { label = L.FIT, field = "fit" },
        {
            label = L.AVAILABLE,
            field = "available",
            Hide = function()
                return M.available <= 1
            end
        },
    },
}

function M:OnEnter(frame)
    local lines = self.lines[frame == BuyEmAllMaxButton and "max" or "stack"]

    lines.amount = self[lines.field]
    for i, line in ipairs(lines) do
        line.amount = self[line.field]
    end

    self:CreateTooltip(frame, lines)
end

function M:CreateTooltip(frame, lines)
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetText(lines.label .. "|cFFFFFFFF - |r" .. GREEN_FONT_COLOR_CODE .. lines.amount .. "|r")

    for _, line in ipairs(lines) do
        if not (line.Hide and line.Hide()) then
            local color = line.amount == lines.amount and GREEN_FONT_COLOR or HIGHLIGHT_FONT_COLOR
            GameTooltip:AddDoubleLine(line.label, line.amount, 1, 1, 1, color.r, color.g, color.b)
        end
    end

    GameTooltip:Show()
end

function M:OnLeave()
    GameTooltip:Hide()
end

function M:OnHide()
    BuyEmAllCurrency1:SetTexture()
    BuyEmAllCurrency2:SetTexture()
    BuyEmAllCurrency3:SetTexture()
    BuyEmAllCurrencyAmt1:SetText()
    BuyEmAllCurrencyAmt2:SetText()
    BuyEmAllCurrencyAmt3:SetText()
    StaticPopup_Hide("BUYEMALL_CONFIRM")
end

_G.FluxBuyEmAll = M

