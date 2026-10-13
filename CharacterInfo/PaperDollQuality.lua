-- Retail-style item quality icon borders on Classic paper doll slots (Blizzard disables them there).
local _, ns = ...
local module = ns.CharacterStats
if not (module and module.useClassicPaperDollChrome) then return end

local function HasPaperDollQualitySupport()
    if module.isRetail or not module.useClassicPaperDollChrome then
        return false
    end

    local sample = _G.CharacterHeadSlot
    return sample and sample.IconBorder ~= nil
end

local ICON_BORDER_TEXTURE = [[Interface\Common\WhiteIconFrame]]
local MIN_QUALITY = LE_ITEM_QUALITY_COMMON or 1

local function GetSlotItemQuality(unit, slot)
    if type(GetInventoryItemQuality) == "function" then
        local quality = GetInventoryItemQuality(unit, slot)
        if quality ~= nil then
            return quality
        end
    end

    local link = GetInventoryItemLink(unit, slot)
    if not link then
        return nil
    end

    if type(C_Item) == "table" and type(C_Item.GetItemQualityByID) == "function" then
        local itemID = GetInventoryItemID(unit, slot)
        if itemID then
            local ok, quality = pcall(C_Item.GetItemQualityByID, itemID)
            if ok and quality ~= nil then
                return quality
            end
        end
    end

    local quality = select(3, GetItemInfo(link))
    if quality ~= nil then
        return quality
    end

    return nil
end

local function SlotHasEquippedItem(button, slot)
    if button.hasItem then
        return true
    end
    return GetInventoryItemTexture("player", slot) ~= nil
end

local function ApplySlotQualityBorder(button)
    if not button or not button.IconBorder or type(button.GetID) ~= "function" then
        return
    end

    local slot = button:GetID()
    if not slot then
        button.IconBorder:Hide()
        return
    end

    if not SlotHasEquippedItem(button, slot) then
        button.IconBorder:Hide()
        return
    end

    local quality = GetSlotItemQuality("player", slot)
    local qualityColors = _G.BAG_ITEM_QUALITY_COLORS

    if quality and quality >= MIN_QUALITY and qualityColors and qualityColors[quality] then
        local color = qualityColors[quality]
        button.IconBorder:SetTexture(ICON_BORDER_TEXTURE)
        button.IconBorder:SetVertexColor(color.r, color.g, color.b)
        button.IconBorder:Show()
        return
    end

    button.IconBorder:Hide()
end

local function RefreshAllPaperDollSlots()
    if type(PaperDollItemSlotButton_Update) ~= "function" then
        return
    end

    local function RefreshButton(button)
        if button and type(button.GetID) == "function" and button.IconBorder then
            ApplySlotQualityBorder(button)
        end
    end

    local paperDollItems = _G.PaperDollItemsFrame
    if paperDollItems then
        if paperDollItems.EquipmentSlots then
            for _, button in ipairs(paperDollItems.EquipmentSlots) do
                RefreshButton(button)
            end
        end
        if paperDollItems.WeaponSlots then
            for _, button in ipairs(paperDollItems.WeaponSlots) do
                RefreshButton(button)
            end
        end
    end

    local slotNames = {
        "CharacterHeadSlot",
        "CharacterNeckSlot",
        "CharacterShoulderSlot",
        "CharacterBackSlot",
        "CharacterChestSlot",
        "CharacterShirtSlot",
        "CharacterTabardSlot",
        "CharacterWristSlot",
        "CharacterHandsSlot",
        "CharacterWaistSlot",
        "CharacterLegsSlot",
        "CharacterFeetSlot",
        "CharacterFinger0Slot",
        "CharacterFinger1Slot",
        "CharacterTrinket0Slot",
        "CharacterTrinket1Slot",
        "CharacterMainHandSlot",
        "CharacterSecondaryHandSlot",
        "CharacterRangedSlot",
        "CharacterAmmoSlot",
    }

    for i = 1, #slotNames do
        RefreshButton(_G[slotNames[i]])
    end
end

local function Install()
    if not HasPaperDollQualitySupport() then
        return false
    end
    if type(hooksecurefunc) ~= "function" or type(PaperDollItemSlotButton_Update) ~= "function" then
        return false
    end
    if _G.FluxPaperDollQualityInstalled then
        return true
    end
    _G.FluxPaperDollQualityInstalled = true

    hooksecurefunc("PaperDollItemSlotButton_Update", ApplySlotQualityBorder)
    local paperDollFrame = _G.PaperDollFrame
    if paperDollFrame and paperDollFrame.HookScript and not paperDollFrame._fluxQualityOnShow then
        paperDollFrame._fluxQualityOnShow = true
        paperDollFrame:HookScript("OnShow", RefreshAllPaperDollSlots)
    end
    return true
end

function module.InstallQuality()
    return Install()
end

local syncFrame = CreateFrame("Frame")
syncFrame:RegisterEvent("PLAYER_LOGIN")
syncFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
syncFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        Install()
    end
    if event == "UNIT_INVENTORY_CHANGED" then
        if unit ~= "player" then
            return
        end
        -- Bag and bank moves fire this too. A hidden paper doll repaints on OnShow.
        local paperDoll = _G.PaperDollFrame
        if paperDoll and paperDoll._fluxQualityOnShow and not paperDoll:IsVisible() then
            return
        end
    end
    RefreshAllPaperDollSlots()
end)

Install()

