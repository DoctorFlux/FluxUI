-- FluxRespec_GearSetTooltip.lua
-- Replaces sell-price / enchant-requirement tooltip lines for protected gear set slots.

FluxRespec = FluxRespec or {}
local R = FluxRespec
local GearSetLock = R.GearSetLock

if not GearSetLock then
    return
end

local ERR_COLOR = CreateColor(1, 32 / 255, 32 / 255)
local hooksInstalled = false

local pendingBagSlot = {}

local function ResetTooltipDecorationState(tooltip)
    if tooltip then
        tooltip.fluxGearSetProtectionDecorated = nil
        tooltip.fluxGearSetProtectionShown = nil
    end
end

local function IsEnchantRequirementLine(text)
    if not text or text == "" then
        return false
    end
    if text == GearSetLock.MESSAGE then
        return false
    end

    local globals = {
        _G.ITEM_ENCHANT_DISENCHANT,
        _G.ITEM_DISENCHANT_NOT_DISENCHANTABLE,
        _G.ERR_USE_LOCKED_WITH_SPELL_S,
    }
    for i = 1, #globals do
        local pattern = globals[i]
        if type(pattern) == "string" and pattern ~= "" and text:find(pattern, 1, true) then
            return true
        end
    end

    local lower = text:lower()
    if lower:find("disenchant", 1, true) and lower:find("enchant", 1, true) then
        return true
    end
    if lower:find("requires", 1, true) and lower:find("enchant", 1, true) then
        return true
    end

    return false
end

local function TooltipLineText(tooltip, index)
    local left = _G["GameTooltipTextLeft" .. index]
    if left and left.GetText then
        return left:GetText()
    end
end

local function HideTooltipLine(tooltip, index)
    local left = _G["GameTooltipTextLeft" .. index]
    local right = _G["GameTooltipTextRight" .. index]
    if left then
        left:SetText(nil)
        left:Hide()
    end
    if right then
        right:SetText(nil)
        right:Hide()
    end
    if tooltip and tooltip.HideLine then
        pcall(tooltip.HideLine, tooltip, index)
    end
end

local function ShowProtectionLine(tooltip)
    if tooltip.fluxGearSetProtectionShown then
        return true
    end
    tooltip:AddLine(GearSetLock.MESSAGE, ERR_COLOR:GetRGB())
    tooltip.fluxGearSetProtectionShown = true
    tooltip:Show()
    return true
end

local function ReplaceLineWithProtection(tooltip, index)
    local left = _G["GameTooltipTextLeft" .. index]
    if not left then
        return ShowProtectionLine(tooltip)
    end
    left:SetText(GearSetLock.MESSAGE)
    left:SetTextColor(ERR_COLOR:GetRGB())
    left:Show()
    local right = _G["GameTooltipTextRight" .. index]
    if right then
        right:SetText(nil)
        right:Hide()
    end
    tooltip.fluxGearSetProtectionShown = true
    tooltip:Show()
    return true
end

local function StripSellPriceMoney(tooltip)
    if not tooltip then
        return
    end
    if GameTooltip_ClearMoney then
        pcall(GameTooltip_ClearMoney, tooltip)
    end
end

function GearSetLock.DecorateProtectedInventoryTooltip(tooltip, invSlot)
    if not tooltip or tooltip:IsForbidden() then
        return
    end
    invSlot = tonumber(invSlot)
    if not invSlot or not GearSetLock.IsInventorySlotProtected(invSlot) then
        return
    end
    if tooltip.fluxGearSetProtectionDecorated then
        return
    end
    tooltip.fluxGearSetProtectionDecorated = true

    local numLines = tooltip:NumLines() or 0
    for i = numLines, 2, -1 do
        local text = TooltipLineText(tooltip, i)
        if text and IsEnchantRequirementLine(text) then
            if tooltip.fluxGearSetProtectionShown then
                HideTooltipLine(tooltip, i)
            else
                ReplaceLineWithProtection(tooltip, i)
            end
        end
    end

    if not tooltip.fluxGearSetProtectionShown and GearSetLock.IsDisenchantContext() then
        ShowProtectionLine(tooltip)
    end
end

function GearSetLock.DecorateProtectedTooltip(tooltip, bag, slot)
    if not tooltip or tooltip:IsForbidden() then
        return
    end
    bag = tonumber(bag)
    slot = tonumber(slot)
    if not bag or not slot or not GearSetLock.IsSlotProtected(bag, slot) then
        return
    end
    if tooltip.fluxGearSetProtectionDecorated then
        return
    end
    tooltip.fluxGearSetProtectionDecorated = true

    local atMerchant = GearSetLock.IsMerchantSellContext()
    local numLines = tooltip:NumLines() or 0

    for i = numLines, 2, -1 do
        local text = TooltipLineText(tooltip, i)
        if text then
            local isSellPrice = false
            if atMerchant then
                local sellLabel = _G.SELL_PRICE
                if sellLabel and text:find(sellLabel, 1, true) then
                    isSellPrice = true
                end
                if _G.GameTooltip_OnTooltipAddMoney and text:find("Sell Price", 1, true) then
                    isSellPrice = true
                end
            end

            if isSellPrice or IsEnchantRequirementLine(text) then
                if tooltip.fluxGearSetProtectionShown then
                    HideTooltipLine(tooltip, i)
                else
                    ReplaceLineWithProtection(tooltip, i)
                end
            end
        end
    end

    if atMerchant then
        StripSellPriceMoney(tooltip)
    end

    if not tooltip.fluxGearSetProtectionShown and (atMerchant or GearSetLock.IsDisenchantContext()) then
        ShowProtectionLine(tooltip)
    end
end

local function OnSellPriceLine(tooltip, lineData)
    if tooltip.isShopping then
        return false
    end

    local bag, slot = GearSetLock.ResolveBagSlotFromTooltip(tooltip, lineData)
    if not bag or not GearSetLock.IsSlotProtected(bag, slot) then
        return false
    end
    if not GearSetLock.IsMerchantSellContext() then
        return false
    end

    ShowProtectionLine(tooltip)
    return true
end

local function OnItemTooltipPost(tooltip, tooltipData)
    if not tooltip or tooltip:IsForbidden() or tooltip ~= GameTooltip then
        return
    end

    local bag, slot = GearSetLock.ResolveBagSlotFromTooltip(tooltip, tooltipData)
    if bag and slot then
        GearSetLock.DecorateProtectedTooltip(tooltip, bag, slot)
    end
end

local function OnSetBagItem(tooltip, bagID, slotID)
    if not tooltip or tooltip:IsForbidden() or tooltip ~= GameTooltip then
        return
    end
    pendingBagSlot[tooltip] = { bag = bagID, slot = slotID }
end

local function OnSetBagItemAfter(tooltip)
    if not tooltip or tooltip:IsForbidden() or tooltip ~= GameTooltip then
        return
    end
    local pending = pendingBagSlot[tooltip]
    pendingBagSlot[tooltip] = nil
    if pending then
        GearSetLock.DecorateProtectedTooltip(tooltip, pending.bag, pending.slot)
    end
end

local pendingInvSlot = {}

local function OnSetInventoryItem(tooltip, unit, invSlot)
    if not tooltip or tooltip:IsForbidden() or tooltip ~= GameTooltip then
        return
    end
    if unit ~= "player" then
        return
    end
    pendingInvSlot[tooltip] = invSlot
end

local function OnSetInventoryItemAfter(tooltip)
    if not tooltip or tooltip:IsForbidden() or tooltip ~= GameTooltip then
        return
    end
    local invSlot = pendingInvSlot[tooltip]
    pendingInvSlot[tooltip] = nil
    if invSlot then
        GearSetLock.DecorateProtectedInventoryTooltip(tooltip, invSlot)
    end
end

local origGameTooltip_OnTooltipAddMoney

local function FluxGearSet_OnTooltipAddMoney(tooltip, cost, maxcost)
    if not tooltip or tooltip:IsForbidden() then
        if origGameTooltip_OnTooltipAddMoney then
            return origGameTooltip_OnTooltipAddMoney(tooltip, cost, maxcost)
        end
        return
    end

    local bag, slot = GearSetLock.ResolveBagSlotFromTooltip(tooltip)
    if bag and GearSetLock.IsSlotProtected(bag, slot) and GearSetLock.IsMerchantSellContext() then
        if not tooltip.fluxGearSetProtectionShown then
            ShowProtectionLine(tooltip)
        end
        return
    end

    if origGameTooltip_OnTooltipAddMoney then
        return origGameTooltip_OnTooltipAddMoney(tooltip, cost, maxcost)
    end
end

function GearSetLock.InstallTooltipHooks()
    if hooksInstalled then
        return
    end
    hooksInstalled = true

    if TooltipDataProcessor and TooltipDataProcessor.AddLinePreCall and Enum and Enum.TooltipDataLineType then
        TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.SellPrice, OnSellPriceLine)
    end

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltipPost)
    end

    if GameTooltip and GameTooltip.SetBagItem then
        hooksecurefunc(GameTooltip, "SetBagItem", function(tooltip, bagID, slotID)
            OnSetBagItem(tooltip, bagID, slotID)
            OnSetBagItemAfter(tooltip)
        end)
    end

    if GameTooltip and GameTooltip.SetInventoryItem then
        hooksecurefunc(GameTooltip, "SetInventoryItem", function(tooltip, unit, invSlot)
            OnSetInventoryItem(tooltip, unit, invSlot)
            OnSetInventoryItemAfter(tooltip)
        end)
    end

    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipCleared", ResetTooltipDecorationState)
    end

    if _G.GameTooltip_OnTooltipAddMoney and _G.GameTooltip_OnTooltipAddMoney ~= FluxGearSet_OnTooltipAddMoney then
        origGameTooltip_OnTooltipAddMoney = _G.GameTooltip_OnTooltipAddMoney
        _G.GameTooltip_OnTooltipAddMoney = FluxGearSet_OnTooltipAddMoney
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    GearSetLock.InstallTooltipHooks()
end)

