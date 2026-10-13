-- FluxVendorAutoMerchantUI.lua
-- Integrates FluxVendorAuto toggles into Blizzard MerchantFrame buttons
local addonName, ns = ...

FluxVendorAutoMerchantUI = FluxVendorAutoMerchantUI or {}

local FV = _G.FluxVendorAuto
local RepairUI = _G.FluxVendorRepairUI

local function VendorAutomationEnabled()
    local settings = FluxRestockSettings and FluxRestockSettings.Get and FluxRestockSettings.Get()
    if not settings then
        return false
    end
    return settings.autoRepair or settings.autoSellGray or settings.autoRestock
end

local uiState = {
    initialized = false,
    hooksRegistered = false,
    cachedRestockItems = {},
    cachedRestockTooltipItems = {},
    cachedRestockTotal = 0,
    cachedSellJunkTotal = 0,
    cachedSellJunkQualities = nil,
    lastMerchantNumItems = 0,
    secureTabHooksRegistered = false,
    junkStatsDirty = true,
    restockSettingsDirty = false,
    lastRepairClusterVisible = nil,
    lastGuildRepairVisible = nil,
    cachedRestockCanBuy = nil,
    cachedJunkSlotCount = 0,
    junkCountFreshThisPulse = false,
    tabReturnPending = false,
    repairHiddenThisOpen = false,
    layoutRetryCount = 0,
    pendingRestockDataAfterStorm = false,
    purchaseStormDataHooked = false,
    postOpenDataHooked = false,
    nativeRepairLayoutTimer = nil,
    nativeRepairLayoutRetryGen = 0,
    merchantFrameUpdateTimer = nil,
    merchantUpdateTimer = nil,
    merchantUpdateMode = nil,
    junkUIRefreshTimer = nil,
    junkCountListenerRegistered = false,
    pipelineLayoutGen = 0,
    debounce = {
        merchantUI = 0.2,
        merchantUIBurst = 0.35,
        merchantFrameUpdate = 0.15,
        junkUI = 0.12,
        junkUIBurst = 0.2,
    },
    postDFClusterLayoutKey = nil,
}

local toggles = {}

local ScheduleMerchantUpdate
local RefreshCheapJunkSlotCount
local ApplyNativeSellJunkButtonState
local LayoutPostDFActionCluster
local UpdateSellJunkButton

local function IsVendorOpenStormSilence()
    local P = _G.FluxVendorOpenPipeline
    return P and P.IsVendorStormSilenceActive and P.IsVendorStormSilenceActive()
end

local function ShouldDeferRestockDataRefresh()
    return IsVendorOpenStormSilence()
end

local function FlushPendingRestockDataRefresh()
    if not uiState.pendingRestockDataAfterStorm then
        return
    end
    uiState.pendingRestockDataAfterStorm = false
    ScheduleMerchantUpdate("data")
end

local function EnsurePurchaseStormDataHook()
    if uiState.purchaseStormDataHooked then
        return
    end
    local VS = FluxVendorSession
    if not VS or not VS.OnPurchaseStormSettled then
        return
    end
    uiState.purchaseStormDataHooked = true
    VS.OnPurchaseStormSettled(function()
        uiState.purchaseStormDataHooked = false
        if not uiState.pendingRestockDataAfterStorm then
            return
        end
        if IsVendorOpenStormSilence() then
            local After = C_Timer and C_Timer.After
            if After then
                After(0.15, EnsurePurchaseStormDataHook)
            else
                EnsurePurchaseStormDataHook()
            end
            return
        end
        FlushPendingRestockDataRefresh()
    end)
end

local function EnsurePostOpenRestockDataHook()
    if uiState.postOpenDataHooked then
        return
    end
    local P = _G.FluxVendorOpenPipeline
    if not P or not P.WhenPostOpenSettled then
        return
    end
    uiState.postOpenDataHooked = true
    P.WhenPostOpenSettled(function()
        if uiState.pendingRestockDataAfterStorm and not IsVendorOpenStormSilence() then
            FlushPendingRestockDataRefresh()
        end
    end)
end

local function DeferRestockDataRefresh()
    uiState.pendingRestockDataAfterStorm = true
    local VS = FluxVendorSession
    if VS and VS.RecordDeferredHeavyWork then
        VS.RecordDeferredHeavyWork()
    end
    EnsurePurchaseStormDataHook()
    EnsurePostOpenRestockDataHook()
end

function FluxVendorAutoMerchantUI.FlushDeferredRestockDataRefresh()
    FlushPendingRestockDataRefresh()
end

function FluxVendorAutoMerchantUI.DeferRestockDataRefreshForOpen()
    DeferRestockDataRefresh()
end

local UPDATE_MODE_RANK = {
    layout = 0,
    data = 1,
    full = 2,
}

local function MergeUpdateMode(current, incoming)
    incoming = incoming or "data"
    if not current or (UPDATE_MODE_RANK[incoming] or 0) > (UPDATE_MODE_RANK[current] or 0) then
        return incoming
    end
    return current
end

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

local function GetSettings()
    return FV and FV.EnsureSettings and FV.EnsureSettings() or nil
end

local function IsSecureMerchantTabShown()
    local lib = LibStub("SecureTabs-2.0", true)
    if not lib or not lib.tabs or not MerchantFrame then
        return false
    end
    local secureTabs = lib.tabs[MerchantFrame]
    if not secureTabs then
        return false
    end
    for i = 1, #secureTabs do
        local frame = secureTabs[i].frame
        if frame and frame.IsShown and frame:IsShown() then
            return true
        end
    end
    return false
end

local function IsMerchantBuyTabActive()
    if not MerchantFrame or not MerchantFrame.IsShown or not MerchantFrame:IsShown() then
        return false
    end
    if IsSecureMerchantTabShown() then
        return false
    end
    local tab = MerchantFrame.selectedTab or 1
    return tab == 1
end

local function HasNativeSellJunkButton()
    return _G.MerchantSellAllJunkButton
        and C_MerchantFrame
        and C_MerchantFrame.SellAllJunkItems
end

local function IsPreDragonflight()
    return FLUX_API and FLUX_API.isPreDF or false
end

-- Custom merchant action buttons mirror Blizzard repair-button chrome per client era.
local function UseClassicMerchantButtonStyle()
    return IsPreDragonflight()
end

local function IsGuildRepairButtonShown()
    local guildRepair = _G.MerchantGuildBankRepairButton
    return guildRepair and guildRepair.IsShown and guildRepair:IsShown() or false
end

local function GetRepairClusterVisible()
    local canRepair = CanMerchantRepair and CanMerchantRepair()
    return canRepair and _G.MerchantRepairAllButton and _G.MerchantRepairAllButton:IsShown()
end

local CLASSIC_GUILD_BUTTON_SIZE = 36
local CLASSIC_GUILD_BUTTON_GAP = 4
local CLASSIC_GUILD_CLUSTER_ANCHOR_Y = 32

local function UsesClassicGuildRepairClusterLayout(repairClusterVisible)
    return UseClassicMerchantButtonStyle()
        and repairClusterVisible
        and CanGuildBankRepair
        and CanGuildBankRepair()
end

local function TrySetTexturePath(texture, paths)
    if not texture or type(paths) ~= "table" then
        return false
    end
    for i = 1, #paths do
        texture:SetTexture(paths[i])
        if texture.GetTexture and texture:GetTexture() then
            return true
        end
    end
    return false
end

local function HasAtlas(atlasName)
    if C_Texture and C_Texture.GetAtlasInfo then
        return C_Texture.GetAtlasInfo(atlasName) ~= nil
    end
    return false
end

local function GetItemIconPath(itemID)
    if not itemID then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    if C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(itemID)
        if icon then
            return icon
        end
    end
    local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function FormatTooltipIcon(icon)
    if type(icon) == "number" then
        return tostring(icon)
    end
    if type(icon) == "string" and icon ~= "" and not icon:find("^|") then
        return icon:gsub("\\", "/")
    end
    return nil
end

local MERCHANT_BUTTON_SIZE = 36
local MIN_NATIVE_REPAIR_BUTTON_SIZE = 32
local MERCHANT_EMPTY_SLOT_TEXTURE = "Interface\\Buttons\\UI-EmptySlot"
local MERCHANT_EMPTY_SLOT_SIZE = 64
local MERCHANT_EMPTY_SLOT_OFFSET_X = -13
local MERCHANT_EMPTY_SLOT_OFFSET_Y = 14
local MERCHANT_PUSHED_TEXTURE = "Interface\\Buttons\\UI-Quickslot-Depress"
local MERCHANT_HIGHLIGHT_TEXTURE = "Interface\\Buttons\\ButtonHilight-Square"

local function GetRepairButtonReference()
    return _G.MerchantRepairAllButton or _G.MerchantRepairItemButton
end

local function GetRepairButtonIconTexture()
    local ref = GetRepairButtonReference()
    if ref and ref.Icon then
        return ref.Icon
    end
    return _G.MerchantRepairAllIcon
end

local function TextureLooksLikeEmptySlot(texture)
    if not texture or not texture.GetTexture then
        return false
    end
    local file = texture:GetTexture()
    if not file then
        return false
    end
    if type(file) == "string" then
        return file:find("EmptySlot", 1, true) ~= nil
    end
    return false
end

local function FindRepairButtonEmptySlotTexture()
    local ref = GetRepairButtonReference()
    if not ref or not ref.GetRegions then
        return nil
    end
    for i = 1, select("#", ref:GetRegions()) do
        local region = select(i, ref:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            if region ~= ref.Icon and TextureLooksLikeEmptySlot(region) then
                return region
            end
        end
    end
    return nil
end

local MERCHANT_CLASSIC_REPAIR_ICONS = "Interface\\MerchantFrame\\UI-Merchant-RepairIcons"
local MERCHANT_CLASSIC_REPAIR_SLOT_COORDS = { 0, 0.28125, 0, 0.5625 }
local MERCHANT_CLASSIC_ICON_SIZE = 36
local CLASSIC_ICON_EDGE_INSET = 1
local CLASSIC_ICON_MIN_SIZE = 24
local SELL_JUNK_BASE_ICON = "Interface/Icons/INV_Misc_Bag_10"
local RESTOCK_BUTTON_ICON = "Interface/Icons/INV_Misc_Bag_08"

local function TextureLooksLikeRepairIcons(texture)
    if not texture or not texture.GetTexture then
        return false
    end
    local file = texture:GetTexture()
    if type(file) == "string" then
        return file:find("RepairIcons", 1, true) ~= nil
    end
    return false
end

local function GetClassicRepairItemSlotReference()
    local repairItem = _G.MerchantRepairItemButton
    if not repairItem or not repairItem.GetRegions then
        return nil
    end
    for i = 1, select("#", repairItem:GetRegions()) do
        local region = select(i, repairItem:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            if region ~= _G.MerchantRepairAllIcon and region ~= _G.MerchantGuildBankRepairButtonIcon then
                if TextureLooksLikeRepairIcons(region) then
                    return region
                end
            end
        end
    end
    return nil
end

local function GetClassicButtonSize(btn)
    if btn and btn.GetSize then
        local w = btn:GetSize()
        if w and w >= MIN_NATIVE_REPAIR_BUTTON_SIZE then
            return w
        end
    end
    local repairAll = _G.MerchantRepairAllButton
    if repairAll and repairAll.GetSize then
        local w = repairAll:GetSize()
        if w and w >= MIN_NATIVE_REPAIR_BUTTON_SIZE then
            return w
        end
    end
    return MERCHANT_CLASSIC_ICON_SIZE
end

local function GetClassicMerchantIconSize(btn)
    local btnSize = GetClassicButtonSize(btn)
    return math.max(CLASSIC_ICON_MIN_SIZE, btnSize - (CLASSIC_ICON_EDGE_INSET * 2))
end

local function ApplyClassicMerchantIcon(iconTexture, texturePath, texCoords)
    if not iconTexture then
        return
    end
    iconTexture:SetTexture(texturePath)
    if texCoords then
        iconTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
    else
        iconTexture:SetTexCoord(0, 1, 0, 1)
    end
end

local function ApplyClassicRepairSlotFrame(btn, frameTexture)
    frameTexture:ClearAllPoints()
    frameTexture:SetAllPoints(btn)

    local ref = GetClassicRepairItemSlotReference()
    if ref and ref.GetTexture then
        local file = ref:GetTexture()
        if file then
            frameTexture:SetTexture(file)
            frameTexture:SetTexCoord(ref:GetTexCoord())
            frameTexture:Show()
            return
        end
    end
    ApplyClassicMerchantIcon(frameTexture, MERCHANT_CLASSIC_REPAIR_ICONS, MERCHANT_CLASSIC_REPAIR_SLOT_COORDS)
    frameTexture:Show()
end

local function ApplyMerchantEmptySlotBackground(btn, emptySlot)
    emptySlot:ClearAllPoints()
    local refSlot = FindRepairButtonEmptySlotTexture()
    if refSlot then
        emptySlot:SetTexture(refSlot:GetTexture())
        local w, h = refSlot:GetSize()
        if w and h and w > 0 and h > 0 then
            emptySlot:SetSize(w, h)
        else
            emptySlot:SetSize(MERCHANT_EMPTY_SLOT_SIZE, MERCHANT_EMPTY_SLOT_SIZE)
        end
        local point, _, relativePoint, x, y = refSlot:GetPoint(1)
        emptySlot:SetPoint(point or "TOPLEFT", btn, relativePoint or "TOPLEFT", x or MERCHANT_EMPTY_SLOT_OFFSET_X, y or MERCHANT_EMPTY_SLOT_OFFSET_Y)
    else
        emptySlot:SetTexture(MERCHANT_EMPTY_SLOT_TEXTURE)
        emptySlot:SetSize(MERCHANT_EMPTY_SLOT_SIZE, MERCHANT_EMPTY_SLOT_SIZE)
        emptySlot:SetPoint("TOPLEFT", btn, "TOPLEFT", MERCHANT_EMPTY_SLOT_OFFSET_X, MERCHANT_EMPTY_SLOT_OFFSET_Y)
    end
    emptySlot:Show()
end

local function LayoutMerchantButtonIcon(iconTexture, btn)
    if not iconTexture or not btn then
        return
    end
    iconTexture:ClearAllPoints()

    if UseClassicMerchantButtonStyle() then
        local iconSize = GetClassicMerchantIconSize(btn)
        iconTexture:SetSize(iconSize, iconSize)
        iconTexture:SetPoint("CENTER", btn, "CENTER", 0, 0)
        return
    end

    local refIcon = GetRepairButtonIconTexture()
    if refIcon and refIcon.GetNumPoints then
        local numPoints = refIcon:GetNumPoints()
        if numPoints and numPoints > 0 then
            for i = 1, numPoints do
                local point, relativeTo, relativePoint, x, y = refIcon:GetPoint(i)
                if relativeTo == refIcon:GetParent() then
                    relativeTo = btn
                end
                iconTexture:SetPoint(point, relativeTo or btn, relativePoint or point, x or 0, y or 0)
            end
            local w, h = refIcon:GetSize()
            if w and h and w > 0 and h > 0 then
                iconTexture:SetSize(w, h)
            end
            return
        end
    end
    iconTexture:SetAllPoints(btn)
end

local SCRAP_JUNK_ICON_PATHS = {
    "Interface/Addons/_FluxUI/Media/Vendor/FluxJunk-Coin",
    "Interface/Buttons/UI-GroupLoot-Coin-Up",
}
local FALLBACK_SELL_JUNK_ICON = "Interface/Buttons/UI-GroupLoot-Coin-Up"

local function EnsureSellJunkCoinOverlay(btn)
    if not btn or not UseClassicMerchantButtonStyle() then
        return nil
    end
    if not btn.fluxCoinIcon then
        btn.fluxCoinIcon = btn:CreateTexture(nil, "OVERLAY")
    end
    return btn.fluxCoinIcon
end

local function ApplySellJunkCoinOverlay(btn)
    local overlay = EnsureSellJunkCoinOverlay(btn)
    if not overlay then
        if btn and btn.fluxCoinIcon then
            btn.fluxCoinIcon:Hide()
        end
        return
    end
    overlay:ClearAllPoints()
    local iconSize = GetClassicMerchantIconSize(btn)
    local overlaySize = math.max(14, iconSize - 2)
    overlay:SetSize(overlaySize, overlaySize)
    overlay:SetPoint("CENTER", btn, "CENTER", 0, 0)
    if TrySetTexturePath(overlay, SCRAP_JUNK_ICON_PATHS) then
        overlay:SetTexCoord(0, 1, 0, 1)
    else
        ApplyClassicMerchantIcon(overlay, FALLBACK_SELL_JUNK_ICON)
    end
    overlay:Show()
end

local function SetIconTexture(texture, atlasName, fallbackPath, texCoords)
    if texture.SetAtlas and HasAtlas(atlasName) then
        texture:SetAtlas(atlasName)
    else
        texture:SetTexture(fallbackPath)
        if texCoords then
            texture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
        else
            texture:SetTexCoord(0, 1, 0, 1)
        end
    end
end

local function SetIconTextureFromAtlases(texture, atlasNames, fallbackPath, texCoords)
    if not texture then
        return false
    end

    if type(atlasNames) == "table" then
        for i = 1, #atlasNames do
            local atlasName = atlasNames[i]
            if C_Texture and C_Texture.GetAtlasInfo then
                local info = C_Texture.GetAtlasInfo(atlasName)
                if info then
                    local file = info.file or info.filename
                    if file and info.leftTexCoord and info.rightTexCoord and info.topTexCoord and info.bottomTexCoord then
                        texture:SetTexture(file)
                        texture:SetTexCoord(
                            info.leftTexCoord, info.rightTexCoord,
                            info.topTexCoord, info.bottomTexCoord
                        )
                        return true
                    end
                end
            end
            if texture.SetAtlas and HasAtlas(atlasName) then
                texture:SetAtlas(atlasName)
                texture:SetTexCoord(0, 1, 0, 1)
                return true
            end
            if texture.SetAtlas then
                local ok = pcall(texture.SetAtlas, texture, atlasName)
                if ok then
                    texture:SetTexCoord(0, 1, 0, 1)
                    return true
                end
            end
        end
    end

    texture:SetTexture(fallbackPath or "Interface\\Icons\\INV_Misc_QuestionMark")
    if texCoords then
        texture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
    else
        texture:SetTexCoord(0, 1, 0, 1)
    end
    return false
end

local SELL_JUNK_ICON_ATLASES = {
    "SpellIcon-256x256-SellJunk",
}

local function ApplySellJunkButtonIcon(iconTexture, btn)
    if not iconTexture then
        return
    end
    LayoutMerchantButtonIcon(iconTexture, btn or iconTexture:GetParent())

    if UseClassicMerchantButtonStyle() then
        ApplyClassicMerchantIcon(iconTexture, SELL_JUNK_BASE_ICON)
        ApplySellJunkCoinOverlay(btn)
        return
    end

    if btn and btn.fluxCoinIcon then
        btn.fluxCoinIcon:Hide()
    end

    if SetIconTextureFromAtlases(iconTexture, SELL_JUNK_ICON_ATLASES, FALLBACK_SELL_JUNK_ICON) then
        return
    end

    local nativeIcon = _G.MerchantSellAllJunkButton and _G.MerchantSellAllJunkButton.Icon
    if nativeIcon and nativeIcon.GetTexture then
        local file = nativeIcon:GetTexture()
        if file then
            iconTexture:SetTexture(file)
            iconTexture:SetTexCoord(nativeIcon:GetTexCoord())
        end
    end
end

local function ApplyRestockButtonIcon(iconTexture, btn)
    if not iconTexture then
        return
    end
    LayoutMerchantButtonIcon(iconTexture, btn or iconTexture:GetParent())
    ApplyClassicMerchantIcon(iconTexture, RESTOCK_BUTTON_ICON)
    if btn and btn.fluxCoinIcon then
        btn.fluxCoinIcon:Hide()
    end
end

local function SetMerchantButtonIcon(iconTexture, atlasName, fallbackPath, itemID, btn)
    LayoutMerchantButtonIcon(iconTexture, btn or (iconTexture and iconTexture:GetParent()))
    if itemID then
        iconTexture:SetTexture(GetItemIconPath(itemID))
        iconTexture:SetTexCoord(0, 1, 0, 1)
        return
    end
    SetIconTexture(iconTexture, atlasName, fallbackPath)
end

local function GetRestockCountColor(bagCount, target)
    if bagCount >= target then
        return 0.1, 1, 0.1
    elseif bagCount == 0 then
        return 1, 0.2, 0.2
    end
    return 1, 0.82, 0
end

local function FormatRestockCountText(bagCount, target)
    local r, g, b = GetRestockCountColor(bagCount, target)
    return string.format(
        "|cff%02x%02x%02x%d / %d|r",
        math.floor(r * 255),
        math.floor(g * 255),
        math.floor(b * 255),
        bagCount,
        target
    )
end

local function FormatRestockCountTextWithBank(entry, bagCount, target)
    if not entry or not entry.countBank then
        return FormatRestockCountText(bagCount, target)
    end
    local bankCount = entry.bankCount or 0
    local combined = bagCount + bankCount
    local r, g, b = GetRestockCountColor(combined, target)
    if bankCount > 0 then
        return string.format(
            "|cff%02x%02x%02x%d|r|cff7fbfff+%d|r / %d",
            math.floor(r * 255),
            math.floor(g * 255),
            math.floor(b * 255),
            bagCount,
            bankCount,
            target
        )
    end
    return string.format(
        "|cff%02x%02x%02x%d|r / %d",
        math.floor(r * 255),
        math.floor(g * 255),
        math.floor(b * 255),
        bagCount,
        target
    )
end

local RESTOCK_LIST_FONT = GameFontHighlightSmall
local TOOLTIP_HEADER_FONT = GameTooltipHeaderText
local TOOLTIP_BODY_FONT = GameTooltipText
local fluxStyledTooltipLines = {}

local function GetTooltipIconTag(itemID, texture)
    local icon = FormatTooltipIcon(texture)
    if not icon then
        icon = FormatTooltipIcon(GetItemIconPath(itemID))
    end
    icon = icon or "Interface/Icons/INV_Misc_QuestionMark"
    return "|T" .. icon .. ":14:14|t"
end

local AUTO_TOGGLE_SIZE = 18

local function SetToggleChecked(toggle, checked)
    if not toggle then
        return
    end
    checked = checked and true or false
    toggle:SetChecked(checked)
end

local function RefreshAutoToggle(hostButton)
    if not hostButton or not hostButton.fluxAutoToggle then
        return
    end
    local toggle = hostButton.fluxAutoToggle
    local cfg = toggle.fluxConfig
    if not cfg or not cfg.get then
        return
    end
    SetToggleChecked(toggle, cfg.get() and true or false)
end

local function UpdateSellJunkAutoToggle()
    if not IsMerchantBuyTabActive() then
        return
    end
    local junkBtn = toggles.sellGray or _G.MerchantSellAllJunkButton or uiState.classicJunkButton
    if not junkBtn or not junkBtn.fluxAutoToggle then
        return
    end
    if junkBtn:IsShown() then
        junkBtn.fluxAutoToggle:Show()
        RefreshAutoToggle(junkBtn)
    else
        junkBtn.fluxAutoToggle:Hide()
    end
end

local function NormalizeAutoToggleChrome(toggle)
    if not toggle then
        return
    end

    local text = toggle.Text or toggle.text
    if not text and toggle.GetName then
        local name = toggle:GetName()
        if name then
            text = _G[name .. "Text"]
        end
    end
    if text then
        text:Hide()
        text:SetText("")
        text:SetWidth(1)
        text:SetHeight(1)
    end
end

local function ApplyAutoToggleChrome(toggle)
    if not toggle then
        return
    end

    local function sizeTexture(texture)
        if texture then
            texture:ClearAllPoints()
            texture:SetAllPoints(toggle)
        end
    end

    toggle:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    toggle:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    toggle:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    toggle:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    toggle:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")

    sizeTexture(toggle:GetNormalTexture())
    sizeTexture(toggle:GetHighlightTexture())
    sizeTexture(toggle:GetPushedTexture())
    sizeTexture(toggle:GetCheckedTexture())
    sizeTexture(toggle:GetDisabledCheckedTexture())
end

local function ShowAutoToggleTooltip(toggle)
    local cfg = toggle and toggle.fluxConfig
    if not cfg then
        return
    end
    GameTooltip:SetOwner(toggle, "ANCHOR_RIGHT")
    GameTooltip:SetText(cfg.tooltipTitle or "Auto")
    if cfg.tooltipBody then
        local r, g, b = 1, 0.82, 0
        if HIGHLIGHT_FONT_COLOR and HIGHLIGHT_FONT_COLOR.GetRGB then
            r, g, b = HIGHLIGHT_FONT_COLOR:GetRGB()
        end
        GameTooltip:AddLine(cfg.tooltipBody, r, g, b, true)
    end
    GameTooltip:Show()
end

local function CreateCompactAutoToggle(hostButton)
    local parent = hostButton
    if hostButton == _G.MerchantSellAllJunkButton
        and HasNativeSellJunkButton()
        and not UseClassicMerchantButtonStyle()
        and MerchantFrame then
        parent = MerchantFrame
    end
    local toggle = CreateFrame("CheckButton", nil, parent)
    toggle:SetSize(AUTO_TOGGLE_SIZE, AUTO_TOGGLE_SIZE)
    toggle:SetPoint("TOPLEFT", hostButton, "TOPLEFT", -3, 3)
    if parent == hostButton then
        toggle:SetFrameLevel(hostButton:GetFrameLevel() + 2)
    else
        toggle:SetFrameStrata(hostButton:GetFrameStrata())
        toggle:SetFrameLevel(hostButton:GetFrameLevel() + 10)
    end
    if toggle.SetPropagateMouseClicks then
        toggle:SetPropagateMouseClicks(false)
    end
    if toggle.SetPropagateMouseMotion then
        toggle:SetPropagateMouseMotion(false)
    end

    ApplyAutoToggleChrome(toggle)
    toggle.fluxIsCompactToggle = true

    return toggle
end

local function AttachAutoToggle(hostButton, config)
    if not hostButton then
        return nil
    end

    local toggle = hostButton.fluxAutoToggle
    if toggle and not toggle.fluxIsCompactToggle then
        toggle:Hide()
        toggle:SetParent(nil)
        hostButton.fluxAutoToggle = nil
        toggle = nil
    end
    if not toggle then
        toggle = CreateCompactAutoToggle(hostButton)
        hostButton.fluxAutoToggle = toggle

        toggle:SetScript("OnClick", function(self, button)
            if button and button ~= "LeftButton" then
                return
            end
            local cfg = self.fluxConfig
            if not cfg or not cfg.set then
                return
            end
            cfg.set(self:GetChecked() and true or false)
            if FV and FV.NotifyVendorSettingsChanged then
                FV.NotifyVendorSettingsChanged()
            elseif FV and FV.RefreshMerchantOptionsCheckboxes then
                FV.RefreshMerchantOptionsCheckboxes()
            end
            PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        end)

        toggle:SetScript("OnEnter", function(self)
            ShowAutoToggleTooltip(self)
        end)
        toggle:SetScript("OnLeave", GameTooltip_Hide)
    else
        ApplyAutoToggleChrome(toggle)
        toggle:SetSize(AUTO_TOGGLE_SIZE, AUTO_TOGGLE_SIZE)
    end

    if hostButton == _G.MerchantSellAllJunkButton
        and HasNativeSellJunkButton()
        and not UseClassicMerchantButtonStyle()
        and MerchantFrame
        and toggle:GetParent() ~= MerchantFrame then
        toggle:SetParent(MerchantFrame)
        toggle:ClearAllPoints()
        toggle:SetPoint("TOPLEFT", hostButton, "TOPLEFT", -3, 3)
        toggle:SetFrameStrata(hostButton:GetFrameStrata())
        toggle:SetFrameLevel(hostButton:GetFrameLevel() + 10)
    end

    toggle.fluxConfig = config
    NormalizeAutoToggleChrome(toggle)
    RefreshAutoToggle(hostButton)
    return toggle
end

local function CancelMerchantUpdateTimer()
    if uiState.merchantUpdateTimer then
        pcall(function()
            uiState.merchantUpdateTimer:Cancel()
        end)
        uiState.merchantUpdateTimer = nil
    end
end

local function RunScheduledMerchantUpdate()
    local mode = uiState.merchantUpdateMode or "data"
    uiState.merchantUpdateMode = nil
    if FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive() and mode == "data" then
        mode = "layout"
    end
    if mode == "data" and ShouldDeferRestockDataRefresh() then
        mode = "layout"
        DeferRestockDataRefresh()
    end
    FluxVendorAutoMerchantUI.UpdateMerchantUI(mode)
end

local function ScheduleMerchantUpdateImmediate(mode)
    CancelMerchantUpdateTimer()
    uiState.merchantUpdateMode = nil
    FluxVendorAutoMerchantUI.UpdateMerchantUI(mode or "full")
end

ScheduleMerchantUpdate = function(mode)
    if not MerchantFrame or not MerchantFrame:IsShown() then
        return
    end
    if not IsMerchantBuyTabActive() then
        FluxVendorAutoMerchantUI.OnBuyTabHidden()
        return
    end
    if mode == "data" and ShouldDeferRestockDataRefresh() then
        mode = "layout"
        DeferRestockDataRefresh()
    end
    uiState.merchantUpdateMode = MergeUpdateMode(uiState.merchantUpdateMode, mode)
    CancelMerchantUpdateTimer()
    local debounce = uiState.debounce.merchantUI
    if FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive() then
        debounce = uiState.debounce.merchantUIBurst
    end
    if C_Timer and C_Timer.NewTimer then
        uiState.merchantUpdateTimer = C_Timer.NewTimer(debounce, function()
            uiState.merchantUpdateTimer = nil
            RunScheduledMerchantUpdate()
        end)
    else
        RunScheduledMerchantUpdate()
    end
end

local function ScheduleThrottledMerchantFrameUpdate()
    if FluxVendorSession and FluxVendorSession.ShouldDeferHeavyBagWork
        and FluxVendorSession.ShouldDeferHeavyBagWork() then
        return
    end
    if uiState.merchantFrameUpdateTimer and uiState.merchantFrameUpdateTimer.Cancel then
        uiState.merchantFrameUpdateTimer:Cancel()
    end
    if not C_Timer or not C_Timer.NewTimer then
        if not MerchantFrame or not MerchantFrame:IsShown() or not IsMerchantBuyTabActive() then
            return
        end
        if FV and FV.IsJunkSellActive and FV.IsJunkSellActive() then
            return
        end
        ApplyNativeSellJunkButtonState()
        if not UseClassicMerchantButtonStyle() then
            LayoutPostDFActionCluster(GetRepairClusterVisible())
        end
        return
    end
    uiState.merchantFrameUpdateTimer = C_Timer.NewTimer(uiState.debounce.merchantFrameUpdate, function()
        uiState.merchantFrameUpdateTimer = nil
        if not MerchantFrame or not MerchantFrame:IsShown() or not IsMerchantBuyTabActive() then
            return
        end
        if FV and FV.IsJunkSellActive and FV.IsJunkSellActive() then
            return
        end
        if not uiState.junkCountFreshThisPulse and not uiState.junkStatsDirty then
            ApplyNativeSellJunkButtonState()
        elseif (uiState.junkStatsDirty or not uiState.junkCountFreshThisPulse)
            and FV and FV.IsVendorBurstActive and not FV.IsVendorBurstActive()
            and VendorAutomationEnabled() then
            RefreshCheapJunkSlotCount()
            ApplyNativeSellJunkButtonState()
        end
        if not UseClassicMerchantButtonStyle() then
            LayoutPostDFActionCluster(GetRepairClusterVisible())
        end
    end)
end

local function CancelMerchantFrameUpdateTimer()
    if uiState.merchantFrameUpdateTimer and uiState.merchantFrameUpdateTimer.Cancel then
        uiState.merchantFrameUpdateTimer:Cancel()
        uiState.merchantFrameUpdateTimer = nil
    end
end

local function DeferMerchantUpdate()
    ScheduleMerchantUpdate("data")
end

function FluxVendorAutoMerchantUI.MarkRestockSettingsDirty()
    uiState.restockSettingsDirty = true
end

function FluxVendorAutoMerchantUI.IsRestockDataDirty()
    return uiState.restockSettingsDirty == true
end

function FluxVendorAutoMerchantUI.MarkJunkStatsDirty()
    uiState.junkStatsDirty = true
end

function FluxVendorAutoMerchantUI.IsJunkStatsDirty()
    return uiState.junkStatsDirty == true
end

local function CancelJunkUIRefreshTimer()
    if uiState.junkUIRefreshTimer and uiState.junkUIRefreshTimer.Cancel then
        uiState.junkUIRefreshTimer:Cancel()
        uiState.junkUIRefreshTimer = nil
    end
end

local function GetSellJunkButton()
    if HasNativeSellJunkButton() then
        return _G.MerchantSellAllJunkButton
    end
    return uiState.classicJunkButton
end

local function ClearMerchantButtonPushState(btn)
    if not btn or not btn.SetButtonState then
        return
    end
    btn:SetButtonState("NORMAL")
end

local function FinishMerchantButtonClick(btn, actionFn)
    GameTooltip:Hide()
    if actionFn then
        actionFn(btn)
    end
    ClearMerchantButtonPushState(btn)
    DeferMerchantUpdate()
end

local function BindMerchantActionButtonClick(btn, actionFn)
    btn:SetScript("OnClick", function(self)
        FinishMerchantButtonClick(self, actionFn)
    end)
end

local function SyncMerchantButtonToRepair(btn)
    local ref = _G.MerchantRepairAllButton or _G.MerchantRepairItemButton
    if not btn or not ref then
        return
    end
    local w, h = ref:GetSize()
    if w and h and w >= MIN_NATIVE_REPAIR_BUTTON_SIZE and h >= MIN_NATIVE_REPAIR_BUTTON_SIZE then
        btn:SetSize(w, h)
    elseif not UseClassicMerchantButtonStyle() then
        btn:SetSize(MERCHANT_BUTTON_SIZE, MERCHANT_BUTTON_SIZE)
    end
end

local function HideButtonNormalTexture(btn)
    local normal = btn.GetNormalTexture and btn:GetNormalTexture()
    if normal then
        normal:Hide()
    end
end

local function ApplyMerchantRepairButtonChrome(btn)
    if not btn then
        return
    end

    btn:SetPushedTexture(MERCHANT_PUSHED_TEXTURE)
    btn:SetHighlightTexture(MERCHANT_HIGHLIGHT_TEXTURE, "ADD")
    HideButtonNormalTexture(btn)
    if not UseClassicMerchantButtonStyle() then
        SyncMerchantButtonToRepair(btn)
    end

    if UseClassicMerchantButtonStyle() then
        if btn.fluxEmptySlot then
            btn.fluxEmptySlot:Hide()
        end
        if btn.fluxRepairChrome then
            btn.fluxRepairChrome:Hide()
        end
        if not btn.fluxClassicFrame then
            btn.fluxClassicFrame = btn:CreateTexture(nil, "BORDER")
        elseif btn.fluxClassicFrame.GetDrawLayer and btn.fluxClassicFrame:GetDrawLayer() ~= "BORDER" then
            btn.fluxClassicFrame:Hide()
            btn.fluxClassicFrame:SetParent(nil)
            btn.fluxClassicFrame = btn:CreateTexture(nil, "BORDER")
        end
        ApplyClassicRepairSlotFrame(btn, btn.fluxClassicFrame)
        if not btn.Icon then
            btn.Icon = btn:CreateTexture(nil, "ARTWORK")
        elseif btn.Icon.GetDrawLayer and btn.Icon:GetDrawLayer() ~= "ARTWORK" then
            btn.Icon:Hide()
            btn.Icon:SetParent(nil)
            btn.Icon = btn:CreateTexture(nil, "ARTWORK")
        end
    else
        if btn.fluxClassicFrame then
            btn.fluxClassicFrame:Hide()
        end
        if btn.fluxRepairChrome then
            btn.fluxRepairChrome:Hide()
        end
        if not btn.fluxEmptySlot then
            btn.fluxEmptySlot = btn:CreateTexture(nil, "BACKGROUND")
        end
        ApplyMerchantEmptySlotBackground(btn, btn.fluxEmptySlot)
        btn.fluxEmptySlot:Show()
        if not btn.Icon then
            btn.Icon = btn:CreateTexture(nil, "BORDER")
        elseif btn.Icon.GetDrawLayer and btn.Icon:GetDrawLayer() ~= "BORDER" then
            btn.Icon:Hide()
            btn.Icon:SetParent(nil)
            btn.Icon = btn:CreateTexture(nil, "BORDER")
        end
    end
    LayoutMerchantButtonIcon(btn.Icon, btn)
end

local function CreateMerchantStyleButton(name, parent)
    local btn = CreateFrame("Button", name, parent)
    ApplyMerchantRepairButtonChrome(btn)
    return btn
end

local function ApplyMerchantButtonLayer(btn)
    if not btn or not MerchantFrame then
        return
    end
    btn:SetFrameStrata("HIGH")
    local refLevel = MerchantFrame:GetFrameLevel()
    if _G.MerchantRepairAllButton then
        refLevel = math.max(refLevel, _G.MerchantRepairAllButton:GetFrameLevel())
    end
    btn:SetFrameLevel(refLevel + 2)
end

local function SetButtonIconDesaturated(btn, desaturated)
    if not btn then
        return
    end
    if btn.Icon then
        if btn.Icon.SetDesaturated then
            btn.Icon:SetDesaturated(desaturated)
        elseif SetDesaturation then
            SetDesaturation(btn.Icon, desaturated)
        end
    end
    if btn.fluxClassicFrame then
        if btn.fluxClassicFrame.SetDesaturated then
            btn.fluxClassicFrame:SetDesaturated(desaturated)
        elseif SetDesaturation then
            SetDesaturation(btn.fluxClassicFrame, desaturated)
        end
    end
    if btn.fluxCoinIcon then
        if btn.fluxCoinIcon.SetDesaturated then
            btn.fluxCoinIcon:SetDesaturated(desaturated)
        elseif SetDesaturation then
            SetDesaturation(btn.fluxCoinIcon, desaturated)
        end
    end
end

local function SetMerchantActionButtonEnabled(btn, enabled)
    if not btn then
        return
    end
    enabled = enabled and true or false
    local isEnabled = btn:IsEnabled()
    SetButtonIconDesaturated(btn, not enabled)
    if enabled == isEnabled then
        return
    end
    if enabled then
        btn:Enable()
    else
        btn:Enable()
        ClearMerchantButtonPushState(btn)
        btn:Disable()
    end
end

local function MatchButtonSize(btn, referenceButton)
    if not btn then
        return
    end
    local ref = referenceButton or _G.MerchantRepairAllButton or _G.MerchantRepairItemButton
    if not ref then
        return
    end
    local w, h = ref:GetSize()
    if w and h and w >= MIN_NATIVE_REPAIR_BUTTON_SIZE and h >= MIN_NATIVE_REPAIR_BUTTON_SIZE then
        btn:SetSize(w, h)
    elseif UseClassicMerchantButtonStyle() then
        btn:SetSize(MERCHANT_CLASSIC_ICON_SIZE, MERCHANT_CLASSIC_ICON_SIZE)
    else
        btn:SetSize(MERCHANT_BUTTON_SIZE, MERCHANT_BUTTON_SIZE)
    end
end

local function FinalizeClassicMerchantButton(btn, sizeReference, iconApplyFn)
    if not btn then
        return
    end
    if UseClassicMerchantButtonStyle() then
        if UsesClassicGuildRepairClusterLayout(GetRepairClusterVisible()) then
            btn:SetSize(CLASSIC_GUILD_BUTTON_SIZE, CLASSIC_GUILD_BUTTON_SIZE)
        else
            MatchButtonSize(btn, sizeReference or _G.MerchantRepairAllButton)
        end
    end
    ApplyMerchantRepairButtonChrome(btn)
    if iconApplyFn then
        iconApplyFn()
    end
    if btn.fluxClassicFrame then
        btn.fluxClassicFrame:Show()
    end
end

-- ---------------------------------------------------------------------------
-- SELL JUNK / RESTOCK TOOLTIPS
-- ---------------------------------------------------------------------------

local function AddTooltipMoneyLine(copper)
    copper = tonumber(copper) or 0
    if copper <= 0 then
        return
    end
    if SetTooltipMoney then
        SetTooltipMoney(GameTooltip, copper)
    elseif GetCoinTextureString then
        GameTooltip:AddLine(GetCoinTextureString(copper), 1, 1, 1)
    end
end

local function SaveAndSetSmallTooltipFont(fontString)
    if not fontString or not RESTOCK_LIST_FONT then
        return
    end
    if not fontString.fluxSavedTooltipFont then
        fontString.fluxSavedTooltipFont = fontString:GetFontObject()
    end
    fontString:SetFontObject(RESTOCK_LIST_FONT)
end

local function RestoreGameTooltipFonts()
    for lineIndex in pairs(fluxStyledTooltipLines) do
        local left = _G["GameTooltipTextLeft" .. lineIndex]
        local right = _G["GameTooltipTextRight" .. lineIndex]
        local defaultFont = lineIndex == 1 and TOOLTIP_HEADER_FONT or TOOLTIP_BODY_FONT
        for _, fontString in ipairs({ left, right }) do
            if fontString then
                if fontString.fluxSavedTooltipFont then
                    fontString:SetFontObject(fontString.fluxSavedTooltipFont)
                    fontString.fluxSavedTooltipFont = nil
                else
                    fontString:SetFontObject(defaultFont)
                end
            end
        end
    end
    wipe(fluxStyledTooltipLines)
end

local function StyleRestockListLine(lineIndex)
    if not lineIndex or lineIndex <= 1 or not RESTOCK_LIST_FONT then
        return
    end
    fluxStyledTooltipLines[lineIndex] = true
    SaveAndSetSmallTooltipFont(_G["GameTooltipTextLeft" .. lineIndex])
end

local function HideRestockGameTooltip()
    RestoreGameTooltipFonts()
    GameTooltip:Hide()
end

local function EnsureGameTooltipFontRestoreHook()
    if uiState.gameTooltipFontRestoreHooked or not GameTooltip then
        return
    end
    uiState.gameTooltipFontRestoreHooked = true
    GameTooltip:HookScript("OnHide", RestoreGameTooltipFonts)
end

local function PrepareRestockTooltip(owner, title)
    EnsureGameTooltipFontRestoreHook()
    RestoreGameTooltipFonts()
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title or "Restock")
end

local function AddRestockTooltipEntry(entry, opts)
    if not entry or not GameTooltip then
        return
    end
    opts = opts or {}
    local FVID = _G.FluxVendorItemDisplay
    local iconTag = GetTooltipIconTag(entry.itemID, entry.texture)
    local nameText = entry.name or ("Item " .. tostring(entry.itemID))
    if FVID and FVID.GetDisplayText and entry.itemID and not entry.isTierRestock then
        nameText = FVID.GetDisplayText(entry.itemID, entry.name)
    end
    local displayTarget = opts.displayTarget
    if displayTarget == nil then
        displayTarget = (entry.isTierRestock and (entry.comboTarget or entry.target)) or entry.target or 0
    end
    local lineText = iconTag .. " " .. nameText .. "  "
        .. FormatRestockCountTextWithBank(entry, entry.bagCount or 0, displayTarget)
    if opts.suffix then
        lineText = lineText .. opts.suffix
    end
    GameTooltip:AddLine(lineText, opts.r or 1, opts.g or 1, opts.b or 1, true)
    StyleRestockListLine(GameTooltip:NumLines())
end

local function FinishRestockTooltip(moneyCopper)
    if moneyCopper ~= nil then
        AddTooltipMoneyLine(moneyCopper)
    end
    GameTooltip:Show()
end

local function RefreshSellJunkTooltipStats(force)
    local FJ = _G.FluxVendorJunk
    if not FJ or not FJ.GetSellButtonStats then
        return
    end

    if force then
        RefreshCheapJunkSlotCount()
    end

    local hasJunk = (uiState.cachedJunkSlotCount or 0) > 0
    if not hasJunk and FJ.HasSellableJunkForButton then
        hasJunk = FJ.HasSellableJunkForButton(false)
    end

    if not hasJunk then
        if force or uiState.junkStatsDirty then
            uiState.cachedSellJunkTotal = 0
            uiState.cachedSellJunkQualities = nil
            uiState.junkStatsDirty = false
        end
        return
    end

    if not force and not uiState.junkStatsDirty and (uiState.cachedSellJunkTotal or 0) > 0 then
        return
    end

    local stats = FJ.GetSellButtonStats()
    if stats then
        uiState.cachedSellJunkTotal = stats.total or 0
        uiState.cachedSellJunkQualities = stats.qualities
        uiState.cachedJunkSlotCount = stats.slotCount or uiState.cachedJunkSlotCount or 0
    end
    uiState.junkStatsDirty = false
end

local function ShowSellJunkTooltip(button)
    local FJ = _G.FluxVendorJunk
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if select(1, GetCursorInfo()) == "item" and FJ then
        local itemID = FJ.GetItemIdFromCursor and FJ.GetItemIdFromCursor()
        if itemID then
            local isJunk = FJ.IsJunk(itemID)
            GameTooltip:SetText(isJunk and "Remove from junk" or "Add to junk", 1, 1, 1)
        end
    else
        RefreshSellJunkTooltipStats(true)

        GameTooltip:SetText(SELL_ALL_JUNK_ITEMS or "Sell All Junk Items")
        local qualities = uiState.cachedSellJunkQualities
        if qualities then
            for quality, count in pairs(qualities) do
                local r, g, b = 1, 1, 1
                if GetItemQualityColor then
                    r, g, b = GetItemQualityColor(quality)
                end
                local qualName = _G["ITEM_QUALITY" .. quality .. "_DESC"]
                if qualName then
                    GameTooltip:AddDoubleLine(qualName, count, r, g, b, r, g, b)
                end
            end
        end
        AddTooltipMoneyLine(uiState.cachedSellJunkTotal)
    end
    GameTooltip:Show()
end

local function ShowRestockTooltip(button)
    PrepareRestockTooltip(button, "Restock")

    local items = uiState.cachedRestockTooltipItems
    local isSoldAtVendor = FV and FV.IsRestockEntrySoldAtVendor
    for i = 1, #items do
        local entry = items[i]
        if entry and (not isSoldAtVendor or isSoldAtVendor(entry)) then
            local suffix
            local r, g, b = 1, 1, 1
            if entry.isTierRestock and entry.vendorLowerTierOnly then
                r, g, b = 1, 0.82, 0.35
                suffix = "  |cffd9d066(lower tier only)|r"
            elseif entry.isTierRestock and entry.vendorHasStock then
                r, g, b = 0.35, 1, 0.35
            elseif not entry.isTierRestock and entry.vendorSold then
                r, g, b = 0.35, 1, 0.35
            end
            AddRestockTooltipEntry(entry, { r = r, g = g, b = b, suffix = suffix })
        end
    end

    FinishRestockTooltip(uiState.cachedRestockTotal)
end

local function IsSellJunkTooltipShowing()
    local junkBtn = GetSellJunkButton()
    return junkBtn and GameTooltip and GameTooltip:IsShown() and GameTooltip:GetOwner() == junkBtn
end

local function RefreshSellJunkTooltipIfShowing()
    if IsSellJunkTooltipShowing() then
        local junkBtn = GetSellJunkButton()
        if junkBtn then
            ShowSellJunkTooltip(junkBtn)
        end
    end
end

local function IsRestockTooltipShowing()
    local restockBtn = uiState.restockButton
    return restockBtn and GameTooltip and GameTooltip:IsShown() and GameTooltip:GetOwner() == restockBtn
end

local function RefreshRestockTooltipIfShowing()
    if IsRestockTooltipShowing() then
        local restockBtn = uiState.restockButton
        if restockBtn then
            ShowRestockTooltip(restockBtn)
        end
    end
end

local function RunJunkUIRefresh()
    uiState.junkUIRefreshTimer = nil
    if not MerchantFrame or not MerchantFrame:IsShown() or not IsMerchantBuyTabActive() then
        return
    end

    local burstActive = FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive()
    local vendorOpen = FluxVendorSession and FluxVendorSession.IsOpen and FluxVendorSession.IsOpen()
    if not burstActive and (not vendorOpen or uiState.junkStatsDirty) then
        RefreshCheapJunkSlotCount()
    end

    local selling = FV and FV.IsJunkSellActive and FV.IsJunkSellActive()
    if selling then
        ApplyNativeSellJunkButtonState()
        FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState()
        if not burstActive and (uiState.junkStatsDirty or IsSellJunkTooltipShowing()) then
            RefreshSellJunkTooltipStats(true)
            RefreshSellJunkTooltipIfShowing()
        end
        return
    end

    if not burstActive and (uiState.junkStatsDirty or IsSellJunkTooltipShowing()) then
        RefreshSellJunkTooltipStats(true)
    end
    ApplyNativeSellJunkButtonState()
    FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState()
    RefreshSellJunkTooltipIfShowing()
end

local function ScheduleJunkUIRefresh(immediate)
    if not MerchantFrame or not MerchantFrame:IsShown() then
        return
    end
    local sj = _G.FluxSellJunk
    if not immediate and sj and sj.IsSelling and sj.IsSelling() then
        -- Defer full junk button stats until sell batch ends.
        uiState.junkStatsDirty = true
        return
    end
    if not immediate
        and FluxVendorSession and FluxVendorSession.ShouldDeferBagVisuals
        and FluxVendorSession.ShouldDeferBagVisuals() then
        return
    end
    CancelJunkUIRefreshTimer()
    if immediate then
        RunJunkUIRefresh()
        return
    end
    local debounce = uiState.debounce.junkUI
    if FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive() then
        debounce = uiState.debounce.junkUIBurst
    end
    if C_Timer and C_Timer.NewTimer then
        uiState.junkUIRefreshTimer = C_Timer.NewTimer(debounce, RunJunkUIRefresh)
    else
        RunJunkUIRefresh()
    end
end

local junkListChangePending = false

function FluxVendorAutoMerchantUI.OnJunkListChanged()
    uiState.junkStatsDirty = true
    if junkListChangePending then
        return
    end
    junkListChangePending = true
    local debounce = uiState.debounce.junkUI
    if FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive() then
        debounce = uiState.debounce.junkUIBurst
    end
    local function run()
        junkListChangePending = false
        if FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive() then
            return
        end
        ScheduleJunkUIRefresh(false)
        ScheduleMerchantUpdate("data")
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(debounce, run)
    else
        run()
    end
end

function FluxVendorAutoMerchantUI.ScheduleJunkUIRefresh(immediate)
    ScheduleJunkUIRefresh(immediate == true)
end

local function HandleJunkButtonClick()
    local FJ = _G.FluxVendorJunk
    if select(1, GetCursorInfo()) and FJ and FJ.HandleItemDrop and FJ.HandleItemDrop(false) then
        GameTooltip:Hide()
        DeferMerchantUpdate()
        return true
    end
    GameTooltip:Hide()
    -- Flux junk (marks / inferior / rules) plus Blizzard junk-coin greys
    -- sell in this click. Retail also mops remaining greys via SellAllJunkItems.
    if FV and FV.SellGrayManual then
        FV.SellGrayManual()
    end
    return false
end

local function SetupSellJunkDragDrop(junkBtn)
    if not junkBtn or junkBtn.fluxDragHooked then
        return
    end
    junkBtn.fluxDragHooked = true
    junkBtn:RegisterForDrag("LeftButton")
    junkBtn:SetScript("OnReceiveDrag", function()
        local FJ = _G.FluxVendorJunk
        if FJ and FJ.HandleItemDrop and FJ.HandleItemDrop(false) then
            GameTooltip:Hide()
            DeferMerchantUpdate()
        end
    end)
end

local function SetupSellJunkTooltip(junkBtn)
    if not junkBtn or junkBtn.fluxTooltipHooked then
        return
    end
    junkBtn.fluxTooltipHooked = true
    junkBtn:SetScript("OnEnter", function(self)
        ShowSellJunkTooltip(self)
    end)
    junkBtn:SetScript("OnLeave", GameTooltip_Hide)
end

local function GetRestockItemIdFromCursor()
    local cursorType, arg = GetCursorInfo()
    if cursorType == "item" then
        return tonumber(arg)
    end
    if cursorType == "merchant" then
        local slot = tonumber(arg)
        if slot then
            if GetMerchantItemID then
                local id = GetMerchantItemID(slot)
                if id then
                    return id
                end
            end
            local link = GetMerchantItemLink and GetMerchantItemLink(slot)
            if link then
                return tonumber(link:match("item:(%d+)"))
            end
        end
    end
    local FJ = _G.FluxVendorJunk
    if FJ and FJ.GetItemIdFromCursor then
        return FJ.GetItemIdFromCursor()
    end
end

local function RestockCursorHasDropItem()
    local cursorType = select(1, GetCursorInfo())
    return cursorType == "item" or cursorType == "merchant"
end

local function GetRestockDefaultTarget(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 1
    end
    local s = GetSettings()
    local existing = s and s.restockItems and s.restockItems[itemID]
    if existing and existing.targetQuantity and existing.targetQuantity > 0 then
        return existing.targetQuantity
    end
    return 1
end

local function GetSavedRestockTarget(itemID)
    return GetRestockDefaultTarget(itemID)
end

local function IsRestockItemListed(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local s = GetSettings()
    local existing = s and s.restockItems and s.restockItems[itemID]
    return existing and existing.targetQuantity and existing.targetQuantity > 0
end

local function HideRestockButtonTargetEdit(btn)
    if not btn or not btn.fluxRestockTargetEdit then
        return
    end
    btn.fluxRestockTargetEdit:Hide()
    btn.fluxRestockTargetEdit:ClearFocus()
    btn.fluxPendingRestockItemId = nil
    btn.fluxPendingRestockWasListed = nil
end

local function CommitRestockButtonTarget(btn)
    if not btn or not btn.fluxRestockTargetEdit then
        return
    end
    local itemID = btn.fluxPendingRestockItemId
    if not itemID or not FV then
        HideRestockButtonTargetEdit(btn)
        return
    end
    local qty = tonumber(btn.fluxRestockTargetEdit:GetText()) or 0
    qty = math.max(0, math.min(999, qty))
    if qty > 0 then
        FV.AddRestockItem(itemID, qty)
    elseif btn.fluxPendingRestockWasListed and FV.SetRestockTarget then
        FV.SetRestockTarget(itemID, 0)
    end
    HideRestockButtonTargetEdit(btn)
    DeferMerchantUpdate()
    if FluxVendorRestockPanel and FluxVendorRestockPanel.RefreshList then
        FluxVendorRestockPanel:RefreshList()
    end
end

local function CommitRestockEditIfOpen()
    local btn = uiState.restockButton
    if btn and btn.fluxRestockTargetEdit and btn.fluxRestockTargetEdit:IsShown() then
        CommitRestockButtonTarget(btn)
    end
end

local function EnsureRestockTargetEditBox(btn)
    if not btn or btn.fluxRestockTargetEdit then
        return btn and btn.fluxRestockTargetEdit
    end

    local editBox = CreateFrame("EditBox", nil, btn, "InputBoxTemplate")
    editBox:SetSize(28, 16)
    editBox:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    editBox:SetFontObject("GameFontNormalSmall")
    editBox:SetJustifyH("RIGHT")
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(3)
    editBox:Hide()
    editBox:SetFrameLevel(btn:GetFrameLevel() + 8)

    editBox:SetScript("OnEnterPressed", function(box)
        local host = box:GetParent()
        box._fluxRestockEnterCommit = true
        CommitRestockButtonTarget(host)
        box:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(box)
        box._fluxRestockEscapeCancel = true
        local host = box:GetParent()
        local itemID = host and host.fluxPendingRestockItemId
        if itemID then
            box:SetText(tostring(GetSavedRestockTarget(itemID)))
        end
        box:ClearFocus()
        HideRestockButtonTargetEdit(host)
        box._fluxRestockEscapeCancel = nil
    end)

    editBox:SetScript("OnEditFocusLost", function(box)
        if box._fluxRestockEnterCommit then
            box._fluxRestockEnterCommit = nil
            return
        end
        if box._fluxRestockEscapeCancel then
            return
        end
        if not box:IsShown() then
            return
        end
        CommitRestockButtonTarget(box:GetParent())
    end)

    btn.fluxRestockTargetEdit = editBox
    return editBox
end

local function ShowRestockButtonTargetEdit(btn, itemID)
    if not btn or not itemID then
        return false
    end
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end

    local editBox = EnsureRestockTargetEditBox(btn)
    if not editBox then
        return false
    end

    btn.fluxPendingRestockItemId = itemID
    btn.fluxPendingRestockWasListed = IsRestockItemListed(itemID)

    editBox:SetText(tostring(GetSavedRestockTarget(itemID)))
    editBox:Show()
    editBox:SetFocus()
    editBox:HighlightText()
    return true
end

local function HandleRestockItemDrop(btn)
    local itemID = GetRestockItemIdFromCursor()
    if not itemID or not btn or not FV then
        return false
    end

    if btn.fluxRestockTargetEdit and btn.fluxRestockTargetEdit:IsShown() then
        local pending = btn.fluxPendingRestockItemId
        if pending and pending ~= itemID then
            CommitRestockButtonTarget(btn)
        end
    end

    ClearCursor()
    GameTooltip:Hide()

    if not IsRestockItemListed(itemID) then
        FV.AddRestockItem(itemID, 1)
        btn.fluxPendingRestockWasListed = true
    end

    DeferMerchantUpdate()
    if FluxVendorRestockPanel and FluxVendorRestockPanel.RefreshList then
        FluxVendorRestockPanel:RefreshList()
    end

    return ShowRestockButtonTargetEdit(btn, itemID)
end

local function HandleRestockButtonClick(btn)
    if RestockCursorHasDropItem() then
        if HandleRestockItemDrop(btn) then
            return true
        end
    end
    if btn and btn.fluxRestockTargetEdit and btn.fluxRestockTargetEdit:IsShown() then
        CommitRestockButtonTarget(btn)
        return true
    end
    if btn and btn.IsEnabled and not btn:IsEnabled() then
        return false
    end
    if FV and FV.DoRestockManual then
        FV.DoRestockManual()
    end
    return false
end

local function SetupRestockDragDrop(restockBtn)
    if not restockBtn or restockBtn.fluxRestockDragHooked then
        return
    end
    restockBtn.fluxRestockDragHooked = true
    restockBtn:RegisterForDrag("LeftButton")
    restockBtn:SetScript("OnReceiveDrag", function()
        if HandleRestockItemDrop(restockBtn) then
            GameTooltip:Hide()
        end
    end)
    restockBtn:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and RestockCursorHasDropItem() then
            HandleRestockItemDrop(restockBtn)
        end
    end)
end

local function SetupRestockTooltip(restockBtn)
    if not restockBtn or restockBtn.fluxTooltipHooked then
        return
    end
    EnsureGameTooltipFontRestoreHook()
    restockBtn.fluxTooltipHooked = true
    restockBtn:SetScript("OnEnter", function(self)
        ShowRestockTooltip(self)
    end)
    restockBtn:SetScript("OnLeave", HideRestockGameTooltip)
end

-- ---------------------------------------------------------------------------
-- BUTTON CREATION
-- ---------------------------------------------------------------------------

local function EnsureClassicJunkButton()
    if uiState.classicJunkButton or HasNativeSellJunkButton() then
        return uiState.classicJunkButton
    end
    if not MerchantFrame then
        return nil
    end

    local btn = CreateMerchantStyleButton("FluxMerchantSellAllJunkButton", MerchantFrame)
    ApplySellJunkButtonIcon(btn.Icon, btn)
    ApplyMerchantButtonLayer(btn)

    BindMerchantActionButtonClick(btn, function()
        HandleJunkButtonClick()
    end)

    SetupSellJunkDragDrop(btn)
    SetupSellJunkTooltip(btn)

    AttachAutoToggle(btn, {
        get = function()
            local s = GetSettings()
            return s and s.autoSellGray
        end,
        set = function(val)
            local s = GetSettings()
            if s then
                s.autoSellGray = val and true or false
            end
            if val and FV and FV.TriggerAutoSellGray and MerchantFrame and MerchantFrame:IsShown() then
                FV.TriggerAutoSellGray()
            end
        end,
        tooltipTitle = "Auto Sell",
        tooltipBody = "Automatically sell all junk items when you open a vendor.",
    })

    uiState.classicJunkButton = btn
    toggles.sellGray = btn
    return btn
end

local function EnsureRestockButton()
    if uiState.restockButton then
        return uiState.restockButton
    end
    if not MerchantFrame then
        return nil
    end

    local btn = CreateMerchantStyleButton("FluxMerchantRestockButton", MerchantFrame)
    ApplyRestockButtonIcon(btn.Icon, btn)
    ApplyMerchantButtonLayer(btn)

    BindMerchantActionButtonClick(btn, function(self)
        HandleRestockButtonClick(self)
    end)

    SetupRestockDragDrop(btn)
    SetupRestockTooltip(btn)

    AttachAutoToggle(btn, {
        get = function()
            local s = GetSettings()
            return s and s.autoRestock
        end,
        set = function(val)
            local s = GetSettings()
            if s then
                s.autoRestock = val and true or false
            end
            if val and FV and FV.TriggerAutoRestock and MerchantFrame and MerchantFrame:IsShown() then
                FV.TriggerAutoRestock()
            end
        end,
        tooltipTitle = "Auto Restock",
        tooltipBody = "Automatically buy listed items up to target counts when you open a vendor.",
    })

    uiState.restockButton = btn
    toggles.restock = btn
    return btn
end

local function JunkButtonHasSellableJunkCheap()
    local FJ = _G.FluxVendorJunk
    if FJ and FJ.NativeJunkCount and FJ.NativeJunkCount() > 0 then
        return true
    end
    if (uiState.cachedJunkSlotCount or 0) > 0 then
        return true
    end
    local VS = FluxVendorSession
    if VS and VS.ShouldDeferBagVisuals and VS.ShouldDeferBagVisuals() then
        return false
    end
    if FJ and FJ.HasSellableJunkForButton then
        return FJ.HasSellableJunkForButton(false)
    end
    return false
end

local function SetupRetailSellJunkBypass()
    local junkBtn = _G.MerchantSellAllJunkButton
    if not junkBtn then
        return
    end
    SetupSellJunkTooltip(junkBtn)
    SetupSellJunkDragDrop(junkBtn)
    if hooksecurefunc and not uiState.merchantUpdateJunkHooked then
        uiState.merchantUpdateJunkHooked = true
        hooksecurefunc("MerchantFrame_Update", function()
            if HasNativeSellJunkButton() then
                ApplyNativeSellJunkButtonState()
            end
        end)
    end
    junkBtn:SetScript("OnClick", HandleJunkButtonClick)
    if hooksecurefunc and not uiState.sellAllJunkConfirmedHooked
        and _G.MerchantFrame_OnSellAllJunkButtonConfirmed then
        uiState.sellAllJunkConfirmedHooked = true
        hooksecurefunc("MerchantFrame_OnSellAllJunkButtonConfirmed", function()
            -- XML confirm path still only sells Blizzard greys; Flux marks
            -- need the leftover sell loop (hardware event is this confirm).
            if FV and FV.SellGrayManual then
                FV.SellGrayManual()
            end
        end)
    end
    if junkBtn.fluxClickHooked then
        return
    end
    junkBtn.fluxClickHooked = true
    if hooksecurefunc and not junkBtn.fluxEnableHooked then
        junkBtn.fluxEnableHooked = true
        hooksecurefunc(junkBtn, "SetEnabled", function(self, enabled)
            if enabled or junkBtn.fluxEnableOverride then
                return
            end
            if _G.FRAME_THAT_OPENED_BAGS == "MerchantFrame" then
                return
            end
            if FluxVendorSession and FluxVendorSession.ShouldDeferBagVisuals
                and FluxVendorSession.ShouldDeferBagVisuals() then
                return
            end
            if not IsMerchantBuyTabActive() then
                return
            end
            local fluxHasJunk = false
            if FV and FV.IsJunkSellActive and FV.IsJunkSellActive() then
                if (uiState.cachedJunkSlotCount or 0) > 0 then
                    fluxHasJunk = true
                else
                    local FJ = _G.FluxVendorJunk
                    fluxHasJunk = FJ and FJ.NativeJunkCount and FJ.NativeJunkCount() > 0
                end
            else
                fluxHasJunk = JunkButtonHasSellableJunkCheap()
            end
            if fluxHasJunk then
                junkBtn.fluxEnableOverride = true
                self:Enable()
                if self.Icon then
                    self.Icon:SetDesaturated(false)
                end
                junkBtn.fluxEnableOverride = false
            end
        end)
    end
end

local function SetupRepairManualReport()
    local repairAll = _G.MerchantRepairAllButton
    if not repairAll or repairAll.fluxRepairReportHooked then
        return
    end
    repairAll.fluxRepairReportHooked = true

    local prevClick = repairAll:GetScript("OnClick")
    repairAll:SetScript("OnClick", function(self, button)
        local moneyBefore = GetMoney()
        if prevClick then
            prevClick(self, button)
        end
        if FV and FV.ReportManualRepairDelta then
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    FV.ReportManualRepairDelta(moneyBefore)
                end)
            else
                FV.ReportManualRepairDelta(moneyBefore)
            end
        end
    end)
end

local function EnsureBlizzardJunkToggleReady()
    local junkBtn = _G.MerchantSellAllJunkButton
    if not junkBtn or toggles.sellGray then
        return
    end
    SetupRetailSellJunkBypass()
    AttachAutoToggle(junkBtn, {
        get = function()
            local s = GetSettings()
            return s and s.autoSellGray
        end,
        set = function(val)
            local s = GetSettings()
            if s then
                s.autoSellGray = val and true or false
            end
            if val and FV and FV.TriggerAutoSellGray and MerchantFrame and MerchantFrame:IsShown() then
                FV.TriggerAutoSellGray()
            end
        end,
        tooltipTitle = "Auto Sell",
        tooltipBody = "Automatically sell all junk items when you open a vendor.",
    })
    toggles.sellGray = junkBtn
end

local function SetupBlizzardToggles()
    SetupRepairManualReport()
    if RepairUI and RepairUI.EnsureTogglesReady then
        RepairUI.EnsureTogglesReady()
    end
    EnsureBlizzardJunkToggleReady()
end

-- ---------------------------------------------------------------------------
-- LAYOUT / VISIBILITY
-- ---------------------------------------------------------------------------

local function GetClassicButtonGap()
    if CanGuildBankRepair and CanGuildBankRepair() then
        return 4
    end
    return 2
end

local function GetClassicLeftSectionCenterX()
    local frameWidth = MerchantFrame and MerchantFrame:GetWidth() or 336
    return frameWidth / 4
end

local function GetSellJunkButtonForLayout()
    if HasNativeSellJunkButton() then
        return _G.MerchantSellAllJunkButton
    end
    return uiState.classicJunkButton
end

local function ApplyClassicGuildClusterButtonChrome(btn, iconApplyFn)
    if not btn then
        return
    end
    btn:SetSize(CLASSIC_GUILD_BUTTON_SIZE, CLASSIC_GUILD_BUTTON_SIZE)
    if btn == _G.MerchantRepairAllButton or btn == _G.MerchantGuildBankRepairButton then
        if RepairUI and RepairUI.NormalizeButton then
            RepairUI.NormalizeButton(btn)
        end
        return
    end
    ApplyMerchantRepairButtonChrome(btn)
    if iconApplyFn then
        iconApplyFn()
    end
    if btn.fluxClassicFrame then
        btn.fluxClassicFrame:Show()
    end
end

local function ApplyClassicGuildRepairClusterLayout(repairClusterVisible)
    if not UsesClassicGuildRepairClusterLayout(repairClusterVisible) then
        return false
    end

    local buttons = {}
    local junkBtn = GetSellJunkButtonForLayout()
    local restockBtn = uiState.restockButton
    local repairAll = _G.MerchantRepairAllButton
    local guildRepair = _G.MerchantGuildBankRepairButton

    if junkBtn and junkBtn:IsShown() then
        buttons[#buttons + 1] = junkBtn
    end
    if restockBtn and restockBtn:IsShown() then
        buttons[#buttons + 1] = restockBtn
    end
    if repairAll and repairAll:IsShown() then
        buttons[#buttons + 1] = repairAll
    end
    if guildRepair and guildRepair:IsShown() then
        buttons[#buttons + 1] = guildRepair
    end

    local count = #buttons
    if count == 0 then
        return false
    end

    local buttonSize = CLASSIC_GUILD_BUTTON_SIZE
    local gap = CLASSIC_GUILD_BUTTON_GAP
    local clusterWidth = (count * buttonSize) + ((count - 1) * gap)
    local startX = math.floor(GetClassicLeftSectionCenterX() - (clusterWidth / 2) + 0.5)

    for i, btn in ipairs(buttons) do
        btn:ClearAllPoints()
        btn:SetPoint(
            "BOTTOMLEFT",
            MerchantFrame,
            "BOTTOMLEFT",
            startX + ((i - 1) * (buttonSize + gap)),
            CLASSIC_GUILD_CLUSTER_ANCHOR_Y
        )
        if btn == junkBtn then
            ApplyClassicGuildClusterButtonChrome(btn, function()
                ApplySellJunkButtonIcon(btn.Icon, btn)
            end)
        elseif btn == restockBtn then
            ApplyClassicGuildClusterButtonChrome(btn, function()
                ApplyRestockButtonIcon(btn.Icon, btn)
            end)
        else
            ApplyClassicGuildClusterButtonChrome(btn)
        end
    end

    return true
end

local function RelayoutClassicCustomMerchantIcons()
    if uiState.restockButton and uiState.restockButton:IsShown() and uiState.restockButton.Icon then
        ApplyRestockButtonIcon(uiState.restockButton.Icon, uiState.restockButton)
    end

    local junkBtn = GetSellJunkButtonForLayout()
    if junkBtn and junkBtn:IsShown() and junkBtn.Icon then
        ApplySellJunkButtonIcon(junkBtn.Icon, junkBtn)
    end
end

local function HidePreDFRepairLabel()
    if not IsPreDragonflight() then
        return
    end
    local repairText = _G.MerchantRepairText
    if not repairText then
        return
    end
    if repairText.SetText then
        repairText:SetText("")
    end
    if repairText.SetAlpha then
        repairText:SetAlpha(0)
    end
    repairText:Hide()
end

local function HideMerchantRepairItemButton()
    local repairItem = _G.MerchantRepairItemButton
    if repairItem and repairItem.IsShown and repairItem:IsShown() then
        repairItem:Hide()
    end
    if InRepairMode and InRepairMode() then
        if HideRepairCursor then
            HideRepairCursor()
        end
        if MerchantFrame and MerchantFrame.UnregisterEvent then
            MerchantFrame:UnregisterEvent("PLAYER_MONEY")
        end
    end
    HidePreDFRepairLabel()
end

local function HideFluxControls()
    uiState.layoutRetryCount = 0
    if RepairUI and RepairUI.CancelRetry then
        RepairUI.CancelRetry()
    end
    if uiState.classicJunkButton then
        uiState.classicJunkButton:Hide()
    end
    if uiState.restockButton then
        uiState.restockButton:Hide()
    end

    for _, host in pairs(toggles) do
        if host and host.fluxAutoToggle then
            host.fluxAutoToggle:Hide()
        end
    end
end

local function CloseMerchantFrame()
    if not MerchantFrame or not MerchantFrame.IsShown or not MerchantFrame:IsShown() then
        return
    end
    if HideUIPanel then
        HideUIPanel(MerchantFrame)
    else
        MerchantFrame:Hide()
    end
end

--- ButtonFrameTemplate CloseButton only hides the overlay panel; close the whole vendor.
function FluxVendorAutoMerchantUI.HookPanelCloseButton(panelFrame)
    if not panelFrame then
        return
    end
    local closeBtn = panelFrame.CloseButton
    if not closeBtn or closeBtn.fluxClosesMerchantHooked then
        return
    end
    closeBtn.fluxClosesMerchantHooked = true
    closeBtn:SetScript("OnClick", function()
        CloseMerchantFrame()
    end)
end

local function EnsureSecureTabHooks()
    local lib = LibStub("SecureTabs-2.0", true)
    if not lib or not MerchantFrame or not lib.tabs then
        return
    end
    local secureTabs = lib.tabs[MerchantFrame]
    if not secureTabs then
        return
    end

    for i = 1, #secureTabs do
        local frame = secureTabs[i].frame
        if frame then
            FluxVendorAutoMerchantUI.HookPanelCloseButton(frame)
        end
        if frame and not frame.fluxSecureTabHooked then
            frame.fluxSecureTabHooked = true
            frame:HookScript("OnShow", function()
                FluxVendorAutoMerchantUI.OnBuyTabHidden()
            end)
            frame:HookScript("OnHide", function()
                if MerchantFrame and MerchantFrame:IsShown() then
                    FluxVendorAutoMerchantUI.OnBuyTabShown()
                end
            end)
        end
    end

    local cover = lib.covers and lib.covers[MerchantFrame]
    if cover and not cover.fluxCoverHooked then
        cover.fluxCoverHooked = true
        cover:HookScript("OnClick", function()
            if MerchantFrame and MerchantFrame:IsShown() then
                FluxVendorAutoMerchantUI.OnBuyTabShown()
            end
        end)
    end

    uiState.secureTabHooksRegistered = true

    if IsPreDragonflight() and _G.FluxVendorItemDisplay and _G.FluxVendorItemDisplay.ApplyPreDFMerchantSecureTabLayers then
        _G.FluxVendorItemDisplay.ApplyPreDFMerchantSecureTabLayers(MerchantFrame)
        if not lib.fluxPreDFLayerHooked then
            lib.fluxPreDFLayerHooked = true
            hooksecurefunc(lib, "Update", function(_, panel)
                if panel == MerchantFrame then
                    _G.FluxVendorItemDisplay.ApplyPreDFMerchantSecureTabLayers(MerchantFrame)
                end
            end)
        end
    end
end

function FluxVendorAutoMerchantUI.OnBuyTabHidden()
    CancelMerchantUpdateTimer()
    uiState.merchantUpdateMode = nil
    HideFluxControls()
end

function FluxVendorAutoMerchantUI.OnBuyTabShown()
    if not MerchantFrame or not MerchantFrame:IsShown() then
        return
    end
    if IsSecureMerchantTabShown() then
        return
    end
    if not IsMerchantBuyTabActive() then
        FluxVendorAutoMerchantUI.OnBuyTabHidden()
        return
    end
    if uiState.tabReturnPending then
        return
    end
    uiState.tabReturnPending = true
    CancelMerchantUpdateTimer()
    uiState.merchantUpdateMode = nil
    FluxVendorAutoMerchantUI.UpdateMerchantUI("full")
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, function()
            uiState.tabReturnPending = false
        end)
    else
        uiState.tabReturnPending = false
    end
end

local function GetActionAnchorButton(repairClusterVisible)
    if uiState.restockButton and uiState.restockButton:IsShown() then
        return uiState.restockButton
    end
    if repairClusterVisible and _G.MerchantRepairAllButton and _G.MerchantRepairAllButton:IsShown() then
        return _G.MerchantRepairAllButton
    end
    return nil
end

local function PositionJunkButton(junkBtn, repairClusterVisible)
    if not junkBtn then
        return
    end

    junkBtn:ClearAllPoints()
    if UsesClassicGuildRepairClusterLayout(repairClusterVisible) then
        return
    end

    local anchor = GetActionAnchorButton(repairClusterVisible)
    if anchor then
        local gap = UseClassicMerchantButtonStyle() and GetClassicButtonGap() or 2
        junkBtn:SetPoint("RIGHT", anchor, "LEFT", -gap, 0)
    else
        junkBtn:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -148, 33)
    end
end

local POST_DF_REPAIR_ALL_Y = 33
local POST_DF_JUNK_OFFSET_NO_GUILD = 80
local POST_DF_JUNK_OFFSET_GUILD = 128

local function GetPostDFJunkOffsetFromRepairAll()
    if CanGuildBankRepair and CanGuildBankRepair() then
        return POST_DF_JUNK_OFFSET_GUILD
    end
    return POST_DF_JUNK_OFFSET_NO_GUILD
end

local function GetRestockToRepairAllOffsetX()
    if UseClassicMerchantButtonStyle() then
        return -GetClassicButtonGap()
    end
    if CanGuildBankRepair and CanGuildBankRepair() then
        return -9
    end
    return -8
end

local function GetPostDFActionButtonGap()
    if CanGuildBankRepair and CanGuildBankRepair() then
        return 9
    end
    return 8
end

local function PinNativeSellJunkButton(junkBtn)
    if not junkBtn or junkBtn.fluxNativePinned then
        return
    end
    junkBtn.fluxNativePinned = true
    junkBtn:SetSize(MERCHANT_BUTTON_SIZE, MERCHANT_BUTTON_SIZE)
    local icon = junkBtn.Icon
    if icon then
        icon:ClearAllPoints()
        icon:SetAllPoints(junkBtn)
    end
end

function LayoutPostDFActionCluster(repairClusterVisible)
    if UseClassicMerchantButtonStyle() or not IsMerchantBuyTabActive() then
        return
    end

    local junkBtn = HasNativeSellJunkButton() and _G.MerchantSellAllJunkButton
    local restockBtn = uiState.restockButton
    local repairAll = _G.MerchantRepairAllButton
    local canRepair = CanMerchantRepair and CanMerchantRepair() and true or false
    local canGuild = CanGuildBankRepair and CanGuildBankRepair() and true or false
    local restockShown = restockBtn and restockBtn:IsShown() and true or false
    local layoutKey = (canRepair and "1" or "0")
        .. (canGuild and "1" or "0")
        .. (restockShown and "1" or "0")

    if junkBtn then
        PinNativeSellJunkButton(junkBtn)
        junkBtn:Show()
    end

    if uiState.postDFClusterLayoutKey == layoutKey then
        return
    end
    uiState.postDFClusterLayoutKey = layoutKey

    if restockShown then
        restockBtn:ClearAllPoints()
        if canRepair and repairAll then
            restockBtn:SetPoint("RIGHT", repairAll, "LEFT", GetRestockToRepairAllOffsetX(), 0)
        else
            restockBtn:SetPoint(
                "BOTTOMRIGHT",
                MerchantFrame,
                "BOTTOMRIGHT",
                -148 - MERCHANT_BUTTON_SIZE - GetPostDFActionButtonGap(),
                POST_DF_REPAIR_ALL_Y
            )
        end
    end

    if junkBtn then
        junkBtn:ClearAllPoints()
        if canRepair and repairAll then
            junkBtn:SetPoint("RIGHT", repairAll, "LEFT", GetPostDFJunkOffsetFromRepairAll(), 0)
        else
            junkBtn:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -148, 33)
        end
        junkBtn:Show()
    end
end

local function EnsurePostDFSellJunkButtonVisible(junkBtn, repairClusterVisible)
    if not junkBtn or UseClassicMerchantButtonStyle() or not IsMerchantBuyTabActive() then
        return
    end
    PinNativeSellJunkButton(junkBtn)
    LayoutPostDFActionCluster(repairClusterVisible)
end

local function PositionRestockButton(restockBtn, repairClusterVisible)
    if not restockBtn then
        return
    end

    -- Retail restock lives in LayoutPostDFActionCluster so it does not
    -- ClearAllPoints before the repair cluster exists.
    if not UseClassicMerchantButtonStyle() then
        return
    end

    restockBtn:ClearAllPoints()
    if UsesClassicGuildRepairClusterLayout(repairClusterVisible) then
        return
    end

    if repairClusterVisible and _G.MerchantRepairAllButton then
        restockBtn:SetPoint("RIGHT", MerchantRepairAllButton, "LEFT", GetRestockToRepairAllOffsetX(), 0)
    else
        restockBtn:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMLEFT", 160, 32)
    end
end

local function RefreshCachedRestockCounts(items)
    if not items or #items == 0 then
        return
    end
    local merchantIndex = (FV.EnsureMerchantIndex and FV.EnsureMerchantIndex(false))
        or (FV.GetMerchantItemIndex and FV.GetMerchantItemIndex(false))
        or {}
    if FV.RefreshRestockCacheEntries then
        FV.RefreshRestockCacheEntries(items, merchantIndex)
    end
end

function RefreshCheapJunkSlotCount()
    if FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive() then
        return
    end
    local FJ = _G.FluxVendorJunk
    if FJ and FJ.GetJunkSlotCountFast then
        uiState.cachedJunkSlotCount = FJ.GetJunkSlotCountFast() or 0
    elseif FJ and FJ.GetJunkSlotCount then
        uiState.cachedJunkSlotCount = FJ.GetJunkSlotCount()
    else
        uiState.cachedJunkSlotCount = 0
    end
    uiState.junkCountFreshThisPulse = true
    uiState.junkStatsDirty = false
end

function FluxVendorAutoMerchantUI.GetCachedSellJunkTotal()
    return uiState.cachedSellJunkTotal or 0
end

function FluxVendorAutoMerchantUI.GetCachedJunkSlotCount()
    return uiState.cachedJunkSlotCount or 0
end

local function FluxHasSellableJunkForButton()
    local burstActive = FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive()
    local vendorOpen = FluxVendorSession and FluxVendorSession.IsOpen and FluxVendorSession.IsOpen()
    local selling = FV and FV.IsJunkSellActive and FV.IsJunkSellActive()
    local FJ = _G.FluxVendorJunk
    local nativeJunk = FJ and FJ.NativeJunkCount and FJ.NativeJunkCount() or 0
    if selling then
        if (uiState.cachedJunkSlotCount or 0) > 0 then
            return true
        end
        return nativeJunk > 0
    end
    if vendorOpen and not burstActive and not uiState.junkStatsDirty then
        if (uiState.cachedJunkSlotCount or 0) > 0 then
            return true
        end
        if nativeJunk > 0 then
            return true
        end
        if FJ and FJ.AnyUpgradeInferiorInBags and FJ.AnyUpgradeInferiorInBags() then
            return true
        end
        if FJ and FJ.AnyExplicitJunkInBags and FJ.AnyExplicitJunkInBags() then
            return true
        end
        if FJ and FJ.AnyBlizzardVendorJunkInBags and FJ.AnyBlizzardVendorJunkInBags() then
            return true
        end
        return false
    end
    if FJ and FJ.HasSellableJunkForButton then
        return FJ.HasSellableJunkForButton(false)
    end
    return (uiState.cachedJunkSlotCount or 0) > 0
end

function FluxVendorAutoMerchantUI.MarkVendorBagPulseDone()
    uiState.junkCountFreshThisPulse = false
end

function FluxVendorAutoMerchantUI.IsMerchantBuyTabActive()
    return IsMerchantBuyTabActive()
end

function ApplyNativeSellJunkButtonState()
    if not HasNativeSellJunkButton() or not IsMerchantBuyTabActive() then
        return
    end
    local junkBtn = _G.MerchantSellAllJunkButton
    if not junkBtn then
        return
    end
    local repairClusterVisible = GetRepairClusterVisible()
    local FJ = _G.FluxVendorJunk
    local blizzHasJunk = FJ and FJ.NativeJunkCount and FJ.NativeJunkCount() > 0
    local fluxHasJunk = FluxHasSellableJunkForButton()
    EnsurePostDFSellJunkButtonVisible(junkBtn, repairClusterVisible)
    junkBtn:SetScript("OnClick", HandleJunkButtonClick)
    -- IsSellAllJunkEnabled only gates Blizzard's engine, not Flux selling.
    local enabled = blizzHasJunk or fluxHasJunk
    junkBtn:SetEnabled(enabled)
    if junkBtn.Icon then
        junkBtn.Icon:SetDesaturated(not enabled)
    end
    if not FV or not FV.IsJunkSellActive or not FV.IsJunkSellActive() then
        UpdateSellJunkAutoToggle()
    end
end

FluxVendorAutoMerchantUI.RefreshCheapJunkSlotCount = RefreshCheapJunkSlotCount
FluxVendorAutoMerchantUI.ApplyNativeSellJunkButtonState = ApplyNativeSellJunkButtonState

function FluxVendorAutoMerchantUI.GetCachedRestockItems()
    return uiState.cachedRestockItems
end

function FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState()
    if HasNativeSellJunkButton() then
        return
    end
    local junkBtn = uiState.classicJunkButton or EnsureClassicJunkButton()
    if not junkBtn or not IsMerchantBuyTabActive() then
        return
    end
    local enabled = FluxHasSellableJunkForButton()
    SetMerchantActionButtonEnabled(junkBtn, enabled)
    UpdateSellJunkAutoToggle()
end

local function UpdateSellJunkButton(repairClusterVisible, mode)
    mode = mode or "full"
    local layoutMode = mode == "layout"
    local dataMode = mode == "data"
    local fullMode = mode == "full"
    local burstActive = FV and FV.IsVendorBurstActive and FV.IsVendorBurstActive()
    local wantTooltipStats = uiState.junkStatsDirty or IsSellJunkTooltipShowing()
    -- Full sell-value stats iterate every junk slot; only needed when the
    -- tooltip is actually visible. Otherwise a cheap slot count is enough
    -- for button enable/disable on vendor open.
    local scanJunk = IsSellJunkTooltipShowing()
        and wantTooltipStats
        and not burstActive
    if dataMode and burstActive and not uiState.junkStatsDirty then
        scanJunk = false
    end

    local junkBtn
    if HasNativeSellJunkButton() then
        junkBtn = _G.MerchantSellAllJunkButton
    else
        junkBtn = EnsureClassicJunkButton()
    end
    if not junkBtn then
        return
    end

    local FJ = _G.FluxVendorJunk
    local junkCount = uiState.cachedJunkSlotCount or 0
    if scanJunk then
        RefreshSellJunkTooltipStats(true)
        junkCount = uiState.cachedJunkSlotCount or 0
        uiState.junkStatsDirty = false
    elseif not layoutMode and not uiState.junkCountFreshThisPulse and not burstActive then
        RefreshCheapJunkSlotCount()
    end

    if not dataMode then
        if HasNativeSellJunkButton() then
            if UseClassicMerchantButtonStyle() then
                ApplyMerchantButtonLayer(junkBtn)
                PositionJunkButton(junkBtn, repairClusterVisible)
                FinalizeClassicMerchantButton(
                    junkBtn,
                    GetActionAnchorButton(repairClusterVisible) or _G.MerchantRepairAllButton,
                    function()
                        if not junkBtn.Icon then
                            junkBtn.Icon = junkBtn:CreateTexture(nil, "ARTWORK")
                        end
                        ApplySellJunkButtonIcon(junkBtn.Icon, junkBtn)
                    end
                )
            else
                EnsurePostDFSellJunkButtonVisible(junkBtn, repairClusterVisible)
            end
            UpdateSellJunkAutoToggle()
        else
            ApplyMerchantButtonLayer(junkBtn)
            PositionJunkButton(junkBtn, repairClusterVisible)
            FinalizeClassicMerchantButton(
                junkBtn,
                GetActionAnchorButton(repairClusterVisible) or _G.MerchantRepairAllButton,
                function()
                    ApplySellJunkButtonIcon(junkBtn.Icon, junkBtn)
                end
            )
            junkBtn:Show()
            UpdateSellJunkAutoToggle()
        end
    end

    if not layoutMode then
        if HasNativeSellJunkButton() then
            ApplyNativeSellJunkButtonState()
        else
            FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState()
        end
    end
end

function FluxVendorAutoMerchantUI.RefreshVendorJunkDisplay()
    FluxVendorAutoMerchantUI.OnJunkListChanged()
end

local function UpdateRestockButton(repairClusterVisible, mode)
    mode = mode or "full"
    local layoutMode = mode == "layout"
    local dataMode = mode == "data"
    local fullMode = mode == "full"
    local forceFullRebuild = fullMode or uiState.restockSettingsDirty

    local restockBtn = EnsureRestockButton()
    if not restockBtn or not FV then
        return
    end

    if not layoutMode and (forceFullRebuild or not uiState.cachedRestockItems or #uiState.cachedRestockItems == 0) then
        if ShouldDeferRestockDataRefresh() then
            DeferRestockDataRefresh()
        else
            local FFWR = _G.FluxVendorFoodWaterRestock
            local hasTierTargets = FFWR and FFWR.NeedsTierRestockTargets and FFWR.NeedsTierRestockTargets()
            local hasItemTargets = FV.HasAnyRestockTargets and FV.HasAnyRestockTargets()
            if not hasTierTargets and not hasItemTargets then
                uiState.cachedRestockItems = {}
                uiState.cachedRestockTooltipItems = {}
                uiState.cachedRestockTotal = 0
            else
                local merchantIndex = (FV.EnsureMerchantIndex and FV.EnsureMerchantIndex(false))
                    or (FV.GetMerchantItemIndex and FV.GetMerchantItemIndex(false))
                    or {}
                uiState.cachedRestockItems = FV.GetRestockVendorItems and FV.GetRestockVendorItems(merchantIndex) or {}
                uiState.cachedRestockTooltipItems = uiState.cachedRestockItems
                if FV.GetRestockTotalCost then
                    uiState.cachedRestockTotal = FV.GetRestockTotalCost(uiState.cachedRestockItems)
                else
                    uiState.cachedRestockTotal = 0
                end
            end
        end
        uiState.restockSettingsDirty = false
    elseif dataMode and uiState.cachedRestockItems and #uiState.cachedRestockItems > 0 then
        if ShouldDeferRestockDataRefresh() then
            DeferRestockDataRefresh()
        else
            RefreshCachedRestockCounts(uiState.cachedRestockItems)
        end
        uiState.cachedRestockTooltipItems = uiState.cachedRestockItems
        local skipCost = FV.IsVendorBurstActive and FV.IsVendorBurstActive()
        if not skipCost and FV.GetRestockTotalCost then
            uiState.cachedRestockTotal = FV.GetRestockTotalCost(uiState.cachedRestockItems)
        end
    end

    if not dataMode then
        ApplyMerchantButtonLayer(restockBtn)
        PositionRestockButton(restockBtn, repairClusterVisible)
        FinalizeClassicMerchantButton(
            restockBtn,
            _G.MerchantRepairAllButton,
            function()
                ApplyRestockButtonIcon(restockBtn.Icon, restockBtn)
            end
        )
        restockBtn:Show()
        if restockBtn.fluxAutoToggle then
            restockBtn.fluxAutoToggle:Show()
            RefreshAutoToggle(restockBtn)
        end
    elseif restockBtn.fluxAutoToggle then
        RefreshAutoToggle(restockBtn)
    end

    local canBuy = #uiState.cachedRestockItems > 0
        and FV.HasRestockNeeded
        and FV.HasRestockNeeded(uiState.cachedRestockItems)
    local indexPending = FV.IsMerchantIndexBuildPending and FV.IsMerchantIndexBuildPending()
    local FFWR = _G.FluxVendorFoodWaterRestock
    local hasTierTargets = FFWR and FFWR.NeedsTierRestockTargets and FFWR.NeedsTierRestockTargets()
    local tierStale = hasTierTargets and FFWR and FFWR.IsMerchantScanStale and FFWR.IsMerchantScanStale()
    if indexPending or tierStale then
        canBuy = false
    end
    uiState.cachedRestockCanBuy = canBuy
    if not layoutMode then
        SetMerchantActionButtonEnabled(restockBtn, canBuy)
    elseif uiState.cachedRestockCanBuy ~= nil then
        SetMerchantActionButtonEnabled(restockBtn, uiState.cachedRestockCanBuy)
    end
    RefreshRestockTooltipIfShowing()
end

function FluxVendorAutoMerchantUI.UpdateMerchantUI(mode)
    if not MerchantFrame or not FV then
        return
    end

    if not IsMerchantBuyTabActive() then
        HideFluxControls()
        return
    end

    mode = mode or "full"
    local layoutMode = mode == "layout"
    local dataMode = mode == "data"
    local fullMode = mode == "full"

    local repairClusterVisible = GetRepairClusterVisible()
    local guildRepairVisible = IsGuildRepairButtonShown()
    local repairChanged = uiState.lastRepairClusterVisible ~= repairClusterVisible
    local guildRepairChanged = uiState.lastGuildRepairVisible ~= guildRepairVisible

    if fullMode then
        HideMerchantRepairItemButton()
        if FV.EnsureMerchantIndex then
            FV.EnsureMerchantIndex(false)
        end
    elseif layoutMode then
        HideMerchantRepairItemButton()
    end

    if layoutMode or fullMode then
        RepairUI.UpdateToggles(repairClusterVisible)
        RepairUI.EnsureClusterReady(repairClusterVisible)
    end

    local skipRestockData = dataMode
        and FV.IsJunkSellActive and FV.IsJunkSellActive()
        and FV.IsRestockBuyActive and not FV.IsRestockBuyActive()
    if not skipRestockData then
        UpdateRestockButton(repairClusterVisible, mode)
    end
    UpdateSellJunkButton(repairClusterVisible, mode)

    if (layoutMode or fullMode) and not UseClassicMerchantButtonStyle() then
        LayoutPostDFActionCluster(repairClusterVisible)
    end

    local doRelayout = layoutMode or fullMode or (dataMode and (repairChanged or guildRepairChanged))
    if doRelayout and ApplyClassicGuildRepairClusterLayout(repairClusterVisible) then
        RelayoutClassicCustomMerchantIcons()
    end
    uiState.lastRepairClusterVisible = repairClusterVisible
    uiState.lastGuildRepairVisible = guildRepairVisible

    if (layoutMode or fullMode) and (repairClusterVisible or guildRepairVisible) then
        RepairUI.ScheduleRetry()
    end
end

local function RefreshAllToggles()
    if not IsMerchantBuyTabActive() then
        return
    end
    for _, host in pairs(toggles) do
        RefreshAutoToggle(host)
    end
end

-- ---------------------------------------------------------------------------
-- INIT / EVENTS
-- ---------------------------------------------------------------------------

FluxVendorAutoMerchantUI.ScheduleMerchantUpdate = ScheduleMerchantUpdate
FluxVendorAutoMerchantUI.ScheduleMerchantUpdateImmediate = ScheduleMerchantUpdateImmediate

function FluxVendorAutoMerchantUI.NeedsMerchantUIDataRefresh(caps)
    caps = caps or {}
    if caps.needsUIFullData then
        return true
    end
    if IsSellJunkTooltipShowing() and uiState.junkStatsDirty then
        return true
    end
    if FV and FV.HasAnyRestockTargets and FV.HasAnyRestockTargets() then
        if uiState.restockSettingsDirty
            or not uiState.cachedRestockItems
            or #uiState.cachedRestockItems == 0 then
            return true
        end
    end
    if caps.needsFullTier then
        if caps.deferHeavyOnOpen then
            return false
        end
        return true
    end
    return false
end

local function RegisterMerchantFrameHooks()
    if uiState.hooksRegistered or not hooksecurefunc then
        return
    end
    uiState.hooksRegistered = true
    if MerchantFrame_UpdateRepairButtons then
        hooksecurefunc("MerchantFrame_UpdateRepairButtons", function()
            if IsVendorOpenStormSilence() then
                return
            end
            if not uiState.repairHiddenThisOpen then
                HideMerchantRepairItemButton()
                uiState.repairHiddenThisOpen = true
            end
            if FluxVendorSession and FluxVendorSession.IsPipelineBusy and FluxVendorSession.IsPipelineBusy() then
                return
            end
            if not IsMerchantBuyTabActive() then
                return
            end
            local repairVisible = GetRepairClusterVisible()
            local guildVisible = IsGuildRepairButtonShown()
            local needsLayout = RepairUI.NeedsLayout()
            if not needsLayout
                and repairVisible == uiState.lastRepairClusterVisible
                and guildVisible == uiState.lastGuildRepairVisible then
                return
            end
            ScheduleMerchantUpdate("layout")
            RepairUI.ScheduleRetry()
        end)
    end
    if MerchantFrame_Update then
        hooksecurefunc("MerchantFrame_Update", function()
            if IsVendorOpenStormSilence() then
                if not uiState.repairHiddenThisOpen then
                    HideMerchantRepairItemButton()
                    uiState.repairHiddenThisOpen = true
                end
                return
            end
            if not uiState.repairHiddenThisOpen then
                HideMerchantRepairItemButton()
                uiState.repairHiddenThisOpen = true
            end
            if FluxVendorSession and FluxVendorSession.ShouldDeferBagVisuals
                and FluxVendorSession.ShouldDeferBagVisuals() then
                return
            end
            if FluxVendorSession and FluxVendorSession.IsPipelineBusy and FluxVendorSession.IsPipelineBusy() then
                return
            end
            if FV and FV.IsJunkSellActive and FV.IsJunkSellActive() then
                return
            end
            ScheduleThrottledMerchantFrameUpdate()
        end)
    end
    hooksecurefunc("PanelTemplates_SetTab", function(panel, index)
        if panel ~= MerchantFrame or not MerchantFrame:IsShown() then
            return
        end
        if index == 1 and not IsSecureMerchantTabShown() then
            if uiState.tabReturnPending then
                return
            end
            CancelMerchantUpdateTimer()
            uiState.merchantUpdateMode = nil
            uiState.tabReturnPending = true
            FluxVendorAutoMerchantUI.UpdateMerchantUI("full")
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function()
                    uiState.tabReturnPending = false
                end)
            else
                uiState.tabReturnPending = false
            end
        else
            FluxVendorAutoMerchantUI.OnBuyTabHidden()
        end
    end)
end

local function InitMerchantUIOnce()
    if not MerchantFrame then
        return false
    end
    if uiState.initialized then
        return true
    end

    EnsureGameTooltipFontRestoreHook()
    SetupBlizzardToggles()
    HideMerchantRepairItemButton()
    EnsureClassicJunkButton()
    EnsureRestockButton()
    EnsureSecureTabHooks()
    RegisterMerchantFrameHooks()

    local FJ = _G.FluxVendorJunk
    if FJ and FJ.RegisterJunkCountListener and not uiState.junkCountListenerRegistered then
        uiState.junkCountListenerRegistered = true
        FJ.RegisterJunkCountListener(function(count)
            uiState.cachedJunkSlotCount = count or 0
        end)
    end

    uiState.initialized = true
    return true
end

local function InitMerchantUI()
    return InitMerchantUIOnce()
end

local prewarmAttempts = 0
local MAX_PREWARM_ATTEMPTS = 40

function FluxVendorAutoMerchantUI.IsMerchantUIInitialized()
    return uiState.initialized == true
end

function FluxVendorAutoMerchantUI.PrewarmForVendorOpen()
    if not MerchantFrame then
        return false
    end
    -- Init is staggered via RunPipelineLayout; avoid sync InitMerchantUIOnce here.
    return uiState.initialized == true
end

function FluxVendorAutoMerchantUI.WarmJunkDisplayCacheIfNeeded()
    if uiState.junkCacheWarmed then
        return
    end
    local VS = FluxVendorSession
    if VS and VS.IsMerchantBagStormActive and VS.IsMerchantBagStormActive() then
        return
    end
    local FJ = _G.FluxVendorJunk
    if FJ and FJ.WarmJunkDisplayCacheForBags then
        FJ.WarmJunkDisplayCacheForBags()
        uiState.junkCacheWarmed = true
    end
end

local function TryPrewarmMerchantUI()
    if not MerchantFrame then
        return false
    end
    local VS = FluxVendorSession
    if uiState.initialized then
        return true
    end
    if VS and VS.IsLoginBagStormActive and VS.IsLoginBagStormActive() then
        InitMerchantUIOnce()
        return uiState.initialized == true
    end
    InitMerchantUIOnce()
    local FJ = _G.FluxVendorJunk
    if FJ and FJ.Init then
        FJ.Init()
    end
    local deferJunkWarm = VS and (
        (VS.IsMerchantBagStormActive and VS.IsMerchantBagStormActive())
        or (VS.IsPipelineBusy and VS.IsPipelineBusy())
    )
    if FJ and FJ.WarmJunkDisplayCacheForBags and not uiState.junkCacheWarmed and not deferJunkWarm then
        FJ.WarmJunkDisplayCacheForBags()
        uiState.junkCacheWarmed = true
    end
    return uiState.initialized
end

local function SchedulePrewarmMerchantUI()
    if TryPrewarmMerchantUI() then
        prewarmAttempts = 0
        return
    end
    prewarmAttempts = prewarmAttempts + 1
    if prewarmAttempts >= MAX_PREWARM_ATTEMPTS then
        return
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.25, SchedulePrewarmMerchantUI)
    end
end

local MAX_IDLE_LAYOUT_RETRIES = 12

function FluxVendorAutoMerchantUI.RunPipelineLayoutLight()
    if not MerchantFrame or not uiState.initialized then
        return
    end
    if not IsMerchantBuyTabActive() then
        return
    end
    HideMerchantRepairItemButton()
    if uiState.classicJunkButton then
        uiState.classicJunkButton:Show()
    end
    if uiState.restockButton then
        uiState.restockButton:Show()
    end
    for _, host in pairs(toggles) do
        if host and host.fluxAutoToggle then
            host.fluxAutoToggle:Show()
        end
    end
    local repairClusterVisible = GetRepairClusterVisible()
    uiState.lastRepairClusterVisible = repairClusterVisible
    uiState.lastGuildRepairVisible = IsGuildRepairButtonShown()
    if not UseClassicMerchantButtonStyle() then
        LayoutPostDFActionCluster(repairClusterVisible)
    end
    if ApplyClassicGuildRepairClusterLayout(repairClusterVisible) then
        RelayoutClassicCustomMerchantIcons()
    end
    RepairUI.EnsureClusterReady(repairClusterVisible)
    RepairUI.UpdateToggles(repairClusterVisible)
end

function FluxVendorAutoMerchantUI.RunIdleOpenLayout()
    if not MerchantFrame then
        return
    end
    if not uiState.initialized then
        InitMerchantUIOnce()
    end
    EnsureBlizzardJunkToggleReady()
    local frameShown = MerchantFrame.IsShown and MerchantFrame:IsShown()
    if not frameShown or not IsMerchantBuyTabActive() then
        uiState.layoutRetryCount = (uiState.layoutRetryCount or 0) + 1
        if uiState.layoutRetryCount < MAX_IDLE_LAYOUT_RETRIES then
            local After = (C_Timer and C_Timer.After) or function(_, fn) fn() end
            After(0, function()
                if MerchantFrame and (MerchantFrame.IsShown and MerchantFrame:IsShown()) then
                    FluxVendorAutoMerchantUI.RunIdleOpenLayout()
                end
            end)
        end
        return
    end
    uiState.layoutRetryCount = 0
    HideMerchantRepairItemButton()
    if uiState.classicJunkButton then
        uiState.classicJunkButton:Show()
    end
    if uiState.restockButton then
        uiState.restockButton:Show()
    end
    for _, host in pairs(toggles) do
        if host and host.fluxAutoToggle then
            host.fluxAutoToggle:Show()
        end
    end
    local repairClusterVisible = GetRepairClusterVisible()
    uiState.lastRepairClusterVisible = repairClusterVisible
    uiState.lastGuildRepairVisible = IsGuildRepairButtonShown()
    if not UseClassicMerchantButtonStyle() then
        LayoutPostDFActionCluster(repairClusterVisible)
    end
    ApplyNativeSellJunkButtonState()
    FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState()
    RepairUI.EnsureClusterReady(repairClusterVisible)
    RepairUI.UpdateToggles(repairClusterVisible)
    RepairUI.ScheduleRetry()
end

function FluxVendorAutoMerchantUI.RunPipelineLayoutStep(step)
    if not MerchantFrame then
        return
    end
    if step == "layout_tooltip_hook" then
        if not uiState.initialized then
            EnsureGameTooltipFontRestoreHook()
        end
    elseif step == "layout_blizzard_toggles" then
        if not uiState.initialized then
            SetupBlizzardToggles()
            HideMerchantRepairItemButton()
        end
    elseif step == "layout_junk_button" then
        if not uiState.initialized then
            EnsureClassicJunkButton()
        end
    elseif step == "layout_restock_button" then
        if not uiState.initialized then
            EnsureRestockButton()
        end
    elseif step == "layout_secure_tabs" then
        if not uiState.initialized then
            EnsureSecureTabHooks()
        end
    elseif step == "layout_register_hooks" then
        RegisterMerchantFrameHooks()
        local FJ = _G.FluxVendorJunk
        if FJ and FJ.RegisterJunkCountListener and not uiState.junkCountListenerRegistered then
            uiState.junkCountListenerRegistered = true
            FJ.RegisterJunkCountListener(function(count)
                uiState.cachedJunkSlotCount = count or 0
            end)
        end
        if not uiState.initialized then
            uiState.initialized = true
        end
        uiState.lastMerchantNumItems = GetMerchantNumItems and GetMerchantNumItems() or 0
    elseif step == "layout_position_repair" then
        if IsMerchantBuyTabActive() then
            local repairClusterVisible = GetRepairClusterVisible()
            RepairUI.UpdateToggles(repairClusterVisible)
            uiState.lastRepairClusterVisible = repairClusterVisible
            uiState.lastGuildRepairVisible = IsGuildRepairButtonShown()
        end
    elseif step == "layout_position_junk" then
        if IsMerchantBuyTabActive() then
            local repairClusterVisible = GetRepairClusterVisible()
            UpdateSellJunkButton(repairClusterVisible, "layout")
        end
    elseif step == "layout_position_restock" then
        if IsMerchantBuyTabActive() then
            local repairClusterVisible = GetRepairClusterVisible()
            UpdateRestockButton(repairClusterVisible, "layout")
        end
    elseif step == "layout_position_cluster" then
        if IsMerchantBuyTabActive() then
            local repairClusterVisible = GetRepairClusterVisible()
            if not UseClassicMerchantButtonStyle() then
                LayoutPostDFActionCluster(repairClusterVisible)
            end
            if ApplyClassicGuildRepairClusterLayout(repairClusterVisible) then
                RelayoutClassicCustomMerchantIcons()
            end
            uiState.lastRepairClusterVisible = repairClusterVisible
            uiState.lastGuildRepairVisible = IsGuildRepairButtonShown()
        end
    end
end

function FluxVendorAutoMerchantUI.OnVendorOpenStormSettled()
    if not MerchantFrame or not MerchantFrame:IsShown() then
        return
    end
    if not IsMerchantBuyTabActive() then
        return
    end
    if uiState.pendingRestockDataAfterStorm then
        FlushPendingRestockDataRefresh()
        return
    end
    RefreshCheapJunkSlotCount()
    ApplyNativeSellJunkButtonState()
    FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState()
    if VendorAutomationEnabled() then
        ScheduleMerchantUpdate("data")
    end
end

function FluxVendorAutoMerchantUI.RunPipelineLayout(mode)
    mode = mode or "idle"
    if not MerchantFrame then
        return
    end

    local steps = FluxVendorAutoMerchantUI._pipelineLayoutSteps
    if not steps then
        steps = {
            "layout_tooltip_hook",
            "layout_blizzard_toggles",
            "layout_junk_button",
            "layout_restock_button",
            "layout_secure_tabs",
            "layout_register_hooks",
            "layout_position_repair",
            "layout_position_junk",
            "layout_position_restock",
            "layout_position_cluster",
        }
        FluxVendorAutoMerchantUI._pipelineLayoutSteps = steps
    end

    uiState.pipelineLayoutGen = uiState.pipelineLayoutGen + 1
    local gen = uiState.pipelineLayoutGen
    local retryCount = 0

    local function scheduleNext(fn)
        local After = (C_Timer and C_Timer.After) or (_G.FluxAPICompat and _G.FluxAPICompat.After)
        if After then
            After(0, fn)
        else
            fn()
        end
    end

    local function finishLayout()
        if gen ~= uiState.pipelineLayoutGen then
            return
        end
        if IsMerchantBuyTabActive() then
            RepairUI.ScheduleRetry()
        end
        if mode == "full" and VendorAutomationEnabled() then
            uiState.pendingRestockDataAfterStorm = true
        end
    end

    local function runStep(idx)
        if gen ~= uiState.pipelineLayoutGen or not MerchantFrame then
            return
        end
        local frameShown = MerchantFrame.IsShown and MerchantFrame:IsShown()
        if not frameShown or not IsMerchantBuyTabActive() then
            retryCount = retryCount + 1
            if retryCount < 16 then
                scheduleNext(function()
                    runStep(idx)
                end)
            end
            return
        end
        retryCount = 0

        local step = steps[idx]
        if step then
            FluxVendorAutoMerchantUI.RunPipelineLayoutStep(step)
            scheduleNext(function()
                runStep(idx + 1)
            end)
            return
        end
        finishLayout()
    end

    if uiState.initialized then
        FluxVendorAutoMerchantUI.RunPipelineLayoutLight()
        if mode == "full" then
            finishLayout()
        end
        return
    end

    runStep(1)
end

function FluxVendorAutoMerchantUI.ApplyRestockPortraitIcon(portraitTexture, hostFrame)
    if not portraitTexture then
        return
    end
    ApplyClassicMerchantIcon(portraitTexture, RESTOCK_BUTTON_ICON)
    if hostFrame and hostFrame.fluxPortraitCoin then
        hostFrame.fluxPortraitCoin:Hide()
    end
end

function FluxVendorAutoMerchantUI.ApplyJunkPortraitIcon(portraitTexture, hostFrame)
    if not portraitTexture then
        return
    end

    if UseClassicMerchantButtonStyle() then
        ApplyClassicMerchantIcon(portraitTexture, SELL_JUNK_BASE_ICON)
        if hostFrame then
            if not hostFrame.fluxPortraitCoin then
                hostFrame.fluxPortraitCoin = hostFrame:CreateTexture(nil, "OVERLAY")
                hostFrame.fluxPortraitCoin:SetPoint("CENTER", portraitTexture, "CENTER", 0, 0)
                hostFrame.fluxPortraitCoin:SetSize(28, 28)
            end
            local overlay = hostFrame.fluxPortraitCoin
            if TrySetTexturePath(overlay, SCRAP_JUNK_ICON_PATHS) then
                overlay:SetTexCoord(0, 1, 0, 1)
            else
                ApplyClassicMerchantIcon(overlay, FALLBACK_SELL_JUNK_ICON)
            end
            overlay:Show()
        end
        return
    end

    if hostFrame and hostFrame.fluxPortraitCoin then
        hostFrame.fluxPortraitCoin:Hide()
    end

    if SetIconTextureFromAtlases(portraitTexture, SELL_JUNK_ICON_ATLASES, FALLBACK_SELL_JUNK_ICON) then
        return
    end

    ApplyClassicMerchantIcon(portraitTexture, SELL_JUNK_BASE_ICON)
    if hostFrame then
        if not hostFrame.fluxPortraitCoin then
            hostFrame.fluxPortraitCoin = hostFrame:CreateTexture(nil, "OVERLAY")
            hostFrame.fluxPortraitCoin:SetPoint("CENTER", portraitTexture, "CENTER", 0, 0)
            hostFrame.fluxPortraitCoin:SetSize(28, 28)
        end
        local overlay = hostFrame.fluxPortraitCoin
        if TrySetTexturePath(overlay, SCRAP_JUNK_ICON_PATHS) then
            overlay:SetTexCoord(0, 1, 0, 1)
        else
            ApplyClassicMerchantIcon(overlay, FALLBACK_SELL_JUNK_ICON)
        end
        overlay:Show()
    end
end

FluxVendorAutoMerchantUI.RefreshAllToggles = RefreshAllToggles
FluxVendorAutoMerchantUI.UpdateSellJunkAutoToggle = UpdateSellJunkAutoToggle
FluxVendorAutoMerchantUI.OnMerchantClosed = HideFluxControls

function FluxVendorAutoMerchantUI.CreateRestockStyleButton(parent, name)
    local btn = CreateMerchantStyleButton(name or "FluxBankRestockButton", parent)
    ApplyRestockButtonIcon(btn.Icon, btn)
    return btn
end

function FluxVendorAutoMerchantUI.SetRestockButtonEnabled(btn, enabled)
    SetMerchantActionButtonEnabled(btn, enabled)
end

function FluxVendorAutoMerchantUI.ApplyRestockAutoToggleChrome(toggle)
    ApplyAutoToggleChrome(toggle)
end

function FluxVendorAutoMerchantUI.CreateRestockAutoToggle(hostButton)
    return CreateCompactAutoToggle(hostButton)
end

FluxVendorAutoMerchantUI.PrepareRestockTooltip = PrepareRestockTooltip
FluxVendorAutoMerchantUI.AddRestockTooltipEntry = AddRestockTooltipEntry
FluxVendorAutoMerchantUI.FinishRestockTooltip = FinishRestockTooltip
FluxVendorAutoMerchantUI.HideRestockTooltip = HideRestockGameTooltip

if RepairUI and RepairUI.Register then
    RepairUI.Register({
        uiState = uiState,
        toggles = toggles,
        fv = FV,
        getSettings = GetSettings,
        attachAutoToggle = AttachAutoToggle,
        refreshAutoToggle = RefreshAutoToggle,
        useClassicMerchantButtonStyle = UseClassicMerchantButtonStyle,
        usesClassicGuildRepairClusterLayout = UsesClassicGuildRepairClusterLayout,
        applyClassicGuildRepairClusterLayout = ApplyClassicGuildRepairClusterLayout,
        isMerchantBuyTabActive = IsMerchantBuyTabActive,
        getRepairClusterVisible = GetRepairClusterVisible,
        isGuildRepairButtonShown = IsGuildRepairButtonShown,
    })
end

local uiEventFrame = CreateFrame("Frame")
do
    local FJ = _G.FluxVendorJunk
    if FJ and FJ.RegisterListChanged and not uiState.junkListHooked then
        uiState.junkListHooked = true
        FJ.RegisterListChanged(function()
            FluxVendorAutoMerchantUI.OnJunkListChanged()
        end)
    end
end

uiEventFrame:RegisterEvent("ADDON_LOADED")
uiEventFrame:RegisterEvent("MERCHANT_SHOW")
uiEventFrame:RegisterEvent("MERCHANT_CLOSED")

uiEventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "Blizzard_UIPanels_Game") then
        if MerchantFrame and not uiState.initialized then
            local schedule = (C_Timer and C_Timer.After) or (_G.FluxAPICompat and _G.FluxAPICompat.After)
            if schedule then
                schedule(0, function()
                    if MerchantFrame and not uiState.initialized then
                        InitMerchantUIOnce()
                    end
                end)
            end
        end
    elseif event == "MERCHANT_SHOW" then
        -- Layout/init driven by FluxVendorBuy MERCHANT_SHOW handler (RunPipelineLayout).
    elseif event == "MERCHANT_CLOSED" then
        uiState.pipelineLayoutGen = uiState.pipelineLayoutGen + 1
        CancelMerchantFrameUpdateTimer()
        CancelMerchantUpdateTimer()
        CancelJunkUIRefreshTimer()
        uiState.merchantUpdateMode = nil
        CommitRestockEditIfOpen()
        HideFluxControls()
        uiState.cachedRestockItems = {}
        uiState.cachedRestockTooltipItems = {}
        uiState.cachedRestockTotal = 0
        uiState.cachedSellJunkTotal = 0
        uiState.cachedSellJunkQualities = nil
        uiState.cachedRestockCanBuy = nil
        uiState.restockSettingsDirty = false
        uiState.junkStatsDirty = true
        uiState.lastRepairClusterVisible = nil
        uiState.lastGuildRepairVisible = nil
        uiState.postDFClusterLayoutKey = nil
        uiState.repairHiddenThisOpen = false
        if RepairUI and RepairUI.CancelRetry then
        RepairUI.CancelRetry()
    end
    end
end)

