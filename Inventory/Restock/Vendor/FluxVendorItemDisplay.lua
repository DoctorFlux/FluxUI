-- FluxVendorItemDisplay.lua
-- Shared item name / tooltip quality coloring for vendor junk, useful, and restock UIs.

FluxVendorItemDisplay = FluxVendorItemDisplay or {}

local FVID = FluxVendorItemDisplay

local function CoerceItemQuality(quality)
    if type(quality) == "number" then
        return quality
    end
    return nil
end

function FVID.IsPostDragonflight()
    if FLUX_API and FLUX_API.isPreDF ~= nil then
        return not FLUX_API.isPreDF
    end
    return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
        and LE_EXPANSION_LEVEL_CURRENT
        and LE_EXPANSION_LEVEL_CURRENT >= 9
end

function FVID.GetItemFields(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end

    local name, link, quality, icon

    if C_Item and C_Item.GetItemInfo then
        local info = C_Item.GetItemInfo(itemID)
        if type(info) == "table" then
            name = info.itemName or info.name
            link = info.hyperlink or info.itemLink
            quality = CoerceItemQuality(info.itemQuality) or CoerceItemQuality(info.quality)
            icon = info.iconFileID or info.itemIcon or info.iconID
        elseif info ~= nil then
            name = info
        end
    end

    if GetItemInfo and (not name or not link) then
        local n, l, q, _, _, _, _, _, _, tex = GetItemInfo(itemID)
        name = name or n
        link = link or l
        if quality == nil then
            quality = CoerceItemQuality(q)
        end
        icon = icon or tex
    end

    if C_Item then
        if not link and C_Item.GetItemLinkByID then
            link = C_Item.GetItemLinkByID(itemID)
        end
        if not icon and C_Item.GetItemIconByID then
            icon = C_Item.GetItemIconByID(itemID)
        end
        if quality == nil and C_Item.GetItemInfoInstant then
            local instant = C_Item.GetItemInfoInstant(itemID)
            if type(instant) == "table" then
                quality = CoerceItemQuality(instant.quality) or CoerceItemQuality(instant.itemQuality)
            else
                quality = CoerceItemQuality(select(3, C_Item.GetItemInfoInstant(itemID)))
            end
        end
    end

    return name, link, CoerceItemQuality(quality), icon
end

function FVID.GetQualityRGB(quality, itemID)
    if quality == nil and itemID then
        local _, _, q = FVID.GetItemFields(itemID)
        quality = q
    end
    quality = CoerceItemQuality(quality)
    if quality ~= nil then
        if C_Item and C_Item.GetItemQualityColor then
            local r, g, b = C_Item.GetItemQualityColor(quality)
            if r then
                return r, g, b
            end
        end
        if GetItemQualityColor then
            local r, g, b = GetItemQualityColor(quality)
            if r then
                return r, g, b
            end
        end
    end
    if quality ~= nil and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].color then
        return ITEM_QUALITY_COLORS[quality].color:GetRGB()
    end
    return 1, 1, 1
end

function FVID.GetDisplayText(itemID, name, link, quality)
    if name == nil or link == nil or quality == nil then
        local n, l, q = FVID.GetItemFields(itemID)
        name = name or n
        link = link or l
        if quality == nil then
            quality = CoerceItemQuality(q)
        end
    end
    quality = CoerceItemQuality(quality)
    if link and link ~= "" then
        return link
    end
    name = name or ("Item " .. tostring(itemID))
    local r, g, b = FVID.GetQualityRGB(quality, itemID)
    return string.format(
        "|cff%02x%02x%02x%s|r",
        math.floor(r * 255),
        math.floor(g * 255),
        math.floor(b * 255),
        name
    )
end

function FVID.ApplyNameFontString(fontString, itemID, fallbackName)
    if not fontString then
        return
    end
    fontString:SetText(FVID.GetDisplayText(itemID, fallbackName))
end

function FVID.ShowTooltip(owner, itemID, link, appendFn)
    itemID = tonumber(itemID)
    if not owner or not GameTooltip then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local name, itemLink = FVID.GetItemFields(itemID)
    link = link or itemLink
    if link and link ~= "" then
        GameTooltip:SetHyperlink(link)
    elseif itemID and GameTooltip.SetItemByID then
        local ok = pcall(GameTooltip.SetItemByID, GameTooltip, itemID)
        if not ok then
            local r, g, b = FVID.GetQualityRGB(nil, itemID)
            GameTooltip:SetText(name or ("Item " .. itemID), r, g, b)
        end
    else
        local r, g, b = FVID.GetQualityRGB(nil, itemID)
        GameTooltip:SetText(name or "", r, g, b)
    end
    if appendFn then
        appendFn()
    end
    GameTooltip:Show()
end

function FVID.IsPreDragonflight()
    return not FVID.IsPostDragonflight()
end

function FVID.ApplyPreDFMerchantSecureTabLayers(merchantFrame)
    if FVID.IsPostDragonflight() or not merchantFrame then
        return
    end
    local lib = LibStub("SecureTabs-2.0", true)
    if not lib or not lib.tabs then
        return
    end
    local secureTabs = lib.tabs[merchantFrame]
    if not secureTabs then
        return
    end

    local base = merchantFrame:GetFrameLevel()
    local tabStrata = "HIGH"
    for i, tab in ipairs(secureTabs) do
        tab:SetFrameStrata(tabStrata)
        tab:SetFrameLevel(base + 615 + i)
        local frame = tab.frame
        if frame then
            frame:SetFrameStrata(tabStrata)
            if frame:IsShown() then
                frame:SetFrameLevel(base + 605)
            end
        end
    end

    local cover = lib.covers and lib.covers[merchantFrame]
    if cover then
        cover:SetFrameStrata(tabStrata)
        cover:SetFrameLevel(base + 630)
    end
end

function FVID.GetJunkSubTabLayout()
    if FVID.IsPostDragonflight() then
        return {
            anchorX = 70,
            anchorY = -20,
            spacing = -4,
        }
    end
    return {
        anchorX = 70,
        anchorY = -20,
        spacing = -16,
    }
end

return FVID
