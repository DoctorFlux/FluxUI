-- FluxVendorJunkPanel.lua
-- Merchant Junk tab: Useful / Junk sub-lists with drag/drop (Scrap-style)
local addonName, ns = ...

FluxVendorJunkPanel = FluxVendorJunkPanel or {}

local Panel = FluxVendorJunkPanel
local FJ = _G.FluxVendorJunk
local FVID = _G.FluxVendorItemDisplay

local panelFrame
local scrollFrame
local scrollChild
local listButtons = {}
local subTab1
local subTab2
local selectedSubTab = 2
local selectedItemID
local spinner
local merchantTab
local QueryItems

local ROW_HEIGHT = 20
local VISIBLE_ROWS = 17
local FOOTER_RESERVE = 36

local function UsesClassicTabTemplate()
    local id = WOW_PROJECT_ID
    if not id then
        return false
    end
    return id == WOW_PROJECT_CLASSIC
        or id == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
        or id == WOW_PROJECT_WRATH_CLASSIC
        or id == WOW_PROJECT_CATACLYSM_CLASSIC
        or (WOW_PROJECT_MISTS_CLASSIC ~= nil and id == WOW_PROJECT_MISTS_CLASSIC)
end

-- Forever is WOW_PROJECT_CAMELOT, Live is mainline. Both ship PanelTabButtonTemplate.
-- Era and Anniversary ship TabButtonTemplate.
local TAB_TEMPLATE = UsesClassicTabTemplate() and "TabButtonTemplate" or "PanelTabButtonTemplate"

local function GetSubTabLayout()
    if FVID and FVID.GetJunkSubTabLayout then
        return FVID.GetJunkSubTabLayout()
    end
    return { anchorX = 70, anchorY = -28, spacing = -16 }
end

local function GetItemInfoCompat(id)
    if C_Item and C_Item.GetItemInfo then
        local info = C_Item.GetItemInfo(id)
        if type(info) == "table" then
            return info.itemName or info.name, info.itemLink, info.itemQuality or info.quality
        end
        return info
    end
    return GetItemInfo(id)
end

local function RequestItemDataIfNeeded(itemID)
    itemID = tonumber(itemID)
    if not itemID or not (C_Item and C_Item.RequestLoadItemDataByID) then
        return
    end
    if C_Item.IsItemDataCachedByID then
        if C_Item.IsItemDataCachedByID(itemID) then
            return
        end
    elseif select(2, GetItemInfoCompat(itemID)) then
        return
    end
    C_Item.RequestLoadItemDataByID(itemID)
end

local function GetActiveList()
    if not FJ then
        return {}
    end
    if selectedSubTab == 1 then
        return FJ.GetUsefulList()
    end
    if FJ.GetJunkTabList then
        return FJ.GetJunkTabList()
    end
    return FJ.GetExplicitJunkList()
end

local function GetAllListedIds()
    if not FJ then
        return {}
    end
    local seen = {}
    local ids = {}
    for _, id in ipairs(FJ.GetUsefulList()) do
        if not seen[id] then
            seen[id] = true
            ids[#ids + 1] = id
        end
    end
    local junkIds = FJ.GetJunkTabList and FJ.GetJunkTabList() or FJ.GetExplicitJunkList()
    for _, id in ipairs(junkIds) do
        if not seen[id] then
            seen[id] = true
            ids[#ids + 1] = id
        end
    end
    return ids
end

local function ToggleListItem(itemID)
    if not FJ or not itemID then
        return
    end
    if selectedSubTab == 1 then
        FJ.AddJunk(itemID)
        Panel:FocusItem(itemID, 2)
    else
        FJ.MarkUseful(itemID)
        Panel:FocusItem(itemID, 1)
    end
end

local function ForgetListItem(itemID)
    if not FJ or not itemID then
        return
    end
    if FJ.IsExplicitJunk and FJ.IsExplicitJunk(itemID) then
        FJ.ForgetJunk(itemID)
    elseif FJ.IsAutoJunk and FJ.IsAutoJunk(itemID) then
        FJ.MarkUseful(itemID)
    else
        FJ.ForgetJunk(itemID)
    end
    selectedItemID = nil
    QueryItems()
end

local function ShowJunkRowTooltip(row)
    if not row.itemID then
        return
    end
    if FVID and FVID.ShowTooltip then
        FVID.ShowTooltip(row, row.itemID, row.link, function()
            GameTooltip:AddLine(" ")
            if selectedSubTab == 1 then
                GameTooltip:AddLine("Left-click: Set as Junk", 0.7, 0.7, 0.7)
            else
                if FJ and FJ.IsExplicitJunk and FJ.IsExplicitJunk(row.itemID) then
                    GameTooltip:AddLine("Manually added to junk.", 0.85, 0.75, 0.45)
                elseif FJ and FJ.IsAutoJunk and FJ.IsAutoJunk(row.itemID) then
                    GameTooltip:AddLine("Auto-marked junk (inferior tier / conjure filter).", 0.65, 0.65, 0.65)
                end
                GameTooltip:AddLine("Left-click: Set as Useful", 0.7, 0.7, 0.7)
            end
            GameTooltip:AddLine("Right-click: Forget", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Drag items here to add.", 0.7, 0.7, 0.7)
        end)
        return
    end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if row.link then
        GameTooltip:SetHyperlink(row.link)
    elseif GameTooltip.SetItemByID then
        pcall(GameTooltip.SetItemByID, GameTooltip, row.itemID)
    end
    GameTooltip:AddLine(" ")
    if selectedSubTab == 1 then
        GameTooltip:AddLine("Left-click: Set as Junk", 0.7, 0.7, 0.7)
    else
        if FJ and FJ.IsExplicitJunk and FJ.IsExplicitJunk(row.itemID) then
            GameTooltip:AddLine("Manually added to junk.", 0.85, 0.75, 0.45)
        elseif FJ and FJ.IsAutoJunk and FJ.IsAutoJunk(row.itemID) then
            GameTooltip:AddLine("Auto-marked junk (inferior tier / conjure filter).", 0.65, 0.65, 0.65)
        end
        GameTooltip:AddLine("Left-click: Set as Useful", 0.7, 0.7, 0.7)
    end
    GameTooltip:AddLine("Right-click: Forget", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Drag items here to add.", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

local function CreateListButton(parent, index)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(ROW_HEIGHT)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    btn:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    btn.stripe = btn:CreateTexture(nil, "BACKGROUND")
    btn.stripe:SetAllPoints()
    btn.stripe:SetColorTexture(1, 1, 1, 0.08)
    btn.stripe:Hide()

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(15, 15)
    btn.icon:SetPoint("LEFT", btn, "LEFT", 6, 0)

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
    btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 4, 0)
    btn.text:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    btn.text:SetJustifyH("LEFT")

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.4)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, button)
        if not self.itemID then
            return
        end
        if button == "RightButton" then
            ForgetListItem(self.itemID)
        else
            ToggleListItem(self.itemID)
        end
    end)
    btn:SetScript("OnEnter", ShowJunkRowTooltip)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    return btn
end

local function EnsureListButtons(count)
    for i = 1, count do
        if not listButtons[i] then
            listButtons[i] = CreateListButton(scrollChild, i)
        end
        listButtons[i]:Show()
    end
    for i = count + 1, #listButtons do
        listButtons[i]:Hide()
    end
end

local panelListHooked = false
local pendingJunkRefresh = false

local function TabForItemID(itemID)
    itemID = tonumber(itemID)
    if not itemID or not FJ then
        return nil
    end
    if FJ.IsExplicitUseful(itemID) then
        return 1
    end
    if FJ.IsExplicitJunk and FJ.IsExplicitJunk(itemID) then
        return 2
    end
    if FJ.IsAutoJunk and FJ.IsAutoJunk(itemID) then
        return 2
    end
    local settings = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
    if settings and settings.junkList then
        local val = settings.junkList[itemID] or settings.junkList[tostring(itemID)]
        if val == true then
            return 2
        end
        if val == false then
            return 1
        end
    end
    return nil
end

local function OnPanelListChanged(itemID)
    if not panelFrame then
        return
    end
    if FJ and FJ.InvalidateJunkTabListCache then
        FJ.InvalidateJunkTabListCache()
    end
    if not panelFrame:IsShown() then
        pendingJunkRefresh = true
        return
    end
    Panel:RefreshList()
    if itemID then
        Panel:FocusItem(itemID, nil)
    end
end

function Panel:FocusItem(itemID, preferredTab)
    if not panelFrame then
        return
    end
    itemID = tonumber(itemID)
    if not itemID then
        if panelFrame:IsShown() then
            QueryItems()
        end
        return
    end

    local tab = preferredTab or TabForItemID(itemID) or selectedSubTab
    if tab ~= selectedSubTab then
        selectedSubTab = tab
        if panelFrame and PanelTemplates_SetTab then
            panelFrame.selectedTab = tab
            PanelTemplates_SetTab(panelFrame, tab)
        end
    end

    selectedItemID = itemID

    local list = GetActiveList()
    for i, id in ipairs(list) do
        if tonumber(id) == itemID then
            if scrollFrame then
                local scrollPos = math.max(0, (i - 1) * ROW_HEIGHT)
                local maxScroll = math.max(0, (#list * ROW_HEIGHT) - scrollFrame:GetHeight())
                scrollFrame:SetVerticalScroll(math.min(scrollPos, maxScroll))
            end
            break
        end
    end

    RequestItemDataIfNeeded(itemID)

    if panelFrame:IsShown() then
        QueryItems()
    else
        Panel:RefreshList()
    end
end

function Panel:NotifyListChanged(itemID)
    Panel:FocusItem(itemID, nil)
end

local function RefreshScrollList()
    if not scrollFrame or not scrollChild then
        return
    end
    local list = GetActiveList()
    local frameWidth = scrollFrame:GetWidth()
    if frameWidth and frameWidth > 0 then
        scrollChild:SetWidth(frameWidth)
    end
    local offset = math.floor((scrollFrame:GetVerticalScroll() or 0) / ROW_HEIGHT + 0.5)
    local childHeight = math.max(#list * ROW_HEIGHT, ROW_HEIGHT)
    scrollChild:SetHeight(childHeight)

    EnsureListButtons(VISIBLE_ROWS)
    for i = 1, VISIBLE_ROWS do
        local index = i + offset
        local id = list[index]
        local btn = listButtons[i]
        if id then
            local name, link, quality, icon
            if FVID and FVID.GetItemFields then
                name, link, quality, icon = FVID.GetItemFields(id)
            else
                name, link, quality = GetItemInfoCompat(id)
            end
            btn.itemID = id
            btn.link = link
            if FVID and FVID.ApplyNameFontString then
                FVID.ApplyNameFontString(btn.text, id, name)
            else
                btn.text:SetText(name or ("Item " .. id))
            end
            if selectedSubTab == 2 and FJ then
                local suffix
                if FJ.IsExplicitJunk and FJ.IsExplicitJunk(id) then
                    suffix = " |cffcc9933(manual)|r"
                elseif FJ.IsAutoJunk and FJ.IsAutoJunk(id) then
                    suffix = " |cff808080(auto)|r"
                end
                if suffix then
                    btn.text:SetText((btn.text:GetText() or "") .. suffix)
                end
            end
            if C_Item and C_Item.GetItemIconByID then
                btn.icon:SetTexture(icon or C_Item.GetItemIconByID(id) or "Interface\\Icons\\INV_Misc_QuestionMark")
            else
                btn.icon:SetTexture(icon or select(10, GetItemInfoCompat(id)) or "Interface\\Icons\\INV_Misc_QuestionMark")
            end
            if selectedItemID == id then
                btn:LockHighlight()
            else
                btn:UnlockHighlight()
            end
            if index % 2 == 0 then
                btn.stripe:Show()
            else
                btn.stripe:Hide()
            end
            btn:Show()
        else
            btn.itemID = nil
            btn.link = nil
            btn:Hide()
        end
    end
end

function Panel:RefreshList()
    RefreshScrollList()
end

function Panel:SetSubTab(tabIndex, keepSelection)
    if tabIndex ~= 1 and tabIndex ~= 2 then
        return
    end
    selectedSubTab = tabIndex
    if not keepSelection then
        selectedItemID = nil
    end
    if panelFrame and PanelTemplates_SetTab then
        panelFrame.selectedTab = tabIndex
        PanelTemplates_SetTab(panelFrame, tabIndex)
    end
    if scrollFrame then
        scrollFrame:SetVerticalScroll(0)
    end
    QueryItems()
end

QueryItems = function()
    if not panelFrame or not panelFrame:IsShown() then
        return
    end
    local pendingLoad = false
    local list = GetActiveList()
    for _, id in ipairs(list) do
        if not GetItemInfoCompat(id) then
            RequestItemDataIfNeeded(id)
            pendingLoad = true
        end
    end
    if spinner then
        spinner:Hide()
    end
    Panel:RefreshList()
    if pendingLoad and C_Timer and C_Timer.After then
        C_Timer.After(0.2, QueryItems)
    end
end

local function ScrollListToItem(itemID)
    if not scrollFrame or not itemID then
        return
    end
    local list = GetActiveList()
    for i, id in ipairs(list) do
        if tonumber(id) == tonumber(itemID) then
            local scrollPos = math.max(0, (i - 1) * ROW_HEIGHT)
            local maxScroll = math.max(0, (#list * ROW_HEIGHT) - scrollFrame:GetHeight())
            scrollFrame:SetVerticalScroll(math.min(scrollPos, maxScroll))
            return
        end
    end
end

local function OnItemDrop()
    if not FJ then
        return
    end
    local itemID = FJ.GetItemIdFromCursor and FJ.GetItemIdFromCursor()
    if not itemID then
        return
    end
    ClearCursor()
    if selectedSubTab == 1 then
        if not FJ.IsExplicitUseful(itemID) then
            FJ.MarkUseful(itemID)
        end
    else
        local settings = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
        local val = settings and settings.junkList and (settings.junkList[itemID] or settings.junkList[tostring(itemID)])
        if val ~= true then
            FJ.AddJunk(itemID)
        end
    end
    selectedItemID = itemID
    RequestItemDataIfNeeded(itemID)
    ScrollListToItem(itemID)
    QueryItems()
end

local function SetupDragDrop(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnReceiveDrag", function()
        OnItemDrop()
    end)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and select(1, GetCursorInfo()) == "item" then
            OnItemDrop()
        end
    end)
end

local function ApplySubTabLayout()
    if not panelFrame or not subTab1 or not subTab2 then
        return
    end
    local layout = GetSubTabLayout()
    subTab1:ClearAllPoints()
    subTab1:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", layout.anchorX, layout.anchorY)
    subTab2:ClearAllPoints()
    subTab2:SetPoint("LEFT", subTab1, "RIGHT", layout.spacing, 0)
    if FVID and FVID.IsPreDragonflight and FVID.IsPreDragonflight() then
        local level = panelFrame:GetFrameLevel() + 25
        subTab1:SetFrameStrata("HIGH")
        subTab1:SetFrameLevel(level)
        subTab2:SetFrameStrata("HIGH")
        subTab2:SetFrameLevel(level)
    end
end

local function CreateSubTab(parent, id, label)
    local layout = GetSubTabLayout()
    local tabName = parent:GetName() .. "Tab" .. id
    local tab = CreateFrame("Button", tabName, parent, TAB_TEMPLATE)
    tab:SetID(id)
    tab:SetText(label)
    if PanelTemplates_TabResize then
        PanelTemplates_TabResize(tab, 0)
    end
    tab:SetScript("OnClick", function()
        Panel:SetSubTab(id)
    end)
    if id == 1 then
        tab:SetPoint("TOPLEFT", parent, "TOPLEFT", layout.anchorX, layout.anchorY)
    else
        tab:SetPoint("LEFT", parent:GetName() .. "Tab1", "RIGHT", layout.spacing, 0)
    end
    if FVID and FVID.IsPreDragonflight and FVID.IsPreDragonflight() then
        tab:SetFrameStrata("HIGH")
        tab:SetFrameLevel(parent:GetFrameLevel() + 25)
    end
    return tab
end

local function CreatePanelFrame()
    if panelFrame then
        return panelFrame
    end

    panelFrame = CreateFrame("Frame", "FluxVendorJunkPanelFrame", MerchantFrame, "ButtonFrameTemplate")
    if FVID and FVID.IsPostDragonflight and FVID.IsPostDragonflight() then
        panelFrame:SetFrameStrata("HIGH")
    end
    panelFrame:Hide()
    local merchantUI = _G.FluxVendorAutoMerchantUI
    if merchantUI and merchantUI.HookPanelCloseButton then
        merchantUI.HookPanelCloseButton(panelFrame)
    end
    panelFrame.numTabs = 2
    panelFrame.selectedTab = selectedSubTab

    if panelFrame.TitleText then
        panelFrame.TitleText:SetText("JunkList")
    elseif panelFrame.TitleContainer and panelFrame.TitleContainer.TitleText then
        panelFrame.TitleContainer.TitleText:SetText("JunkList")
    end

    local portrait
    local portraitContainer
    if panelFrame.PortraitContainer and panelFrame.PortraitContainer.portrait then
        portraitContainer = panelFrame.PortraitContainer
        portrait = panelFrame.PortraitContainer.portrait
    elseif panelFrame.portrait then
        portrait = panelFrame.portrait
        portraitContainer = panelFrame
    end
    if portrait then
        local merchantUI = _G.FluxVendorAutoMerchantUI
        if merchantUI and merchantUI.ApplyJunkPortraitIcon then
            merchantUI.ApplyJunkPortraitIcon(portrait, portraitContainer or panelFrame)
        else
            portrait:SetTexture("Interface/Icons/INV_Misc_Bag_10")
        end
    end

    local inset = panelFrame.Inset or panelFrame
    subTab1 = CreateSubTab(panelFrame, 1, "Useful")
    subTab2 = CreateSubTab(panelFrame, 2, "Junk")

    local scrollTopInset = -4
    if FVID and FVID.IsPostDragonflight and FVID.IsPostDragonflight() then
        scrollTopInset = -6
    end

    scrollFrame = CreateFrame("ScrollFrame", nil, panelFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, scrollTopInset)
    scrollFrame:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -28, FOOTER_RESERVE)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() or 300)
    scrollChild:SetHeight(ROW_HEIGHT * VISIBLE_ROWS)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local step = ROW_HEIGHT * 3
        local list = GetActiveList()
        local maxScroll = math.max(0, (#list * ROW_HEIGHT) - self:GetHeight())
        local newScroll = math.min(maxScroll, math.max(0, current - delta * step))
        self:SetVerticalScroll(newScroll)
        RefreshScrollList()
    end)

    scrollFrame:SetScript("OnScrollRangeChanged", function()
        RefreshScrollList()
    end)

    local hint = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", inset, "BOTTOMLEFT", 8, 10)
    hint:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -8, 10)
    hint:SetWordWrap(true)
    hint:SetNonSpaceWrap(false)
    hint:SetJustifyH("CENTER")
    hint:SetText("Drag to add. Left-click toggles. Right-click forgets.")

    if LoadingSpinnerTemplate then
        spinner = CreateFrame("Frame", nil, panelFrame, "LoadingSpinnerTemplate")
        spinner:SetPoint("CENTER", inset, "CENTER", 0, 0)
        if spinner.Anim then
            spinner.Anim:Play()
        end
        spinner:Hide()
    end

    SetupDragDrop(panelFrame)
    SetupDragDrop(scrollFrame)
    SetupDragDrop(scrollChild)

    PanelTemplates_SetTab(panelFrame, selectedSubTab)

    if FJ and not panelListHooked then
        panelListHooked = true
        FJ.RegisterListChanged(OnPanelListChanged)
        -- Also refresh on visual-only notifications (e.g. inferior marks applied
        -- asynchronously after the merchant scan completes) so auto-marked junk
        -- appears the first time the Junk tab is viewed, without a tab switch.
        if FJ.RegisterVisualRefresh then
            FJ.RegisterVisualRefresh(function()
                if not panelFrame or not panelFrame:IsShown() then
                    return
                end
                if FJ.InvalidateJunkTabListCache then
                    FJ.InvalidateJunkTabListCache()
                end
                Panel:RefreshList()
            end)
        end
    end

    panelFrame:SetScript("OnShow", function()
        selectedItemID = nil
        if scrollChild and scrollFrame then
            scrollChild:SetWidth(scrollFrame:GetWidth())
        end
        ApplySubTabLayout()
        if pendingJunkRefresh and FJ and FJ.InvalidateJunkTabListCache then
            FJ.InvalidateJunkTabListCache()
        end
        pendingJunkRefresh = false
        if panelFrame and PanelTemplates_SetTab then
            panelFrame.selectedTab = selectedSubTab
            PanelTemplates_SetTab(panelFrame, selectedSubTab)
        end
        if scrollFrame then
            scrollFrame:SetVerticalScroll(0)
        end
        Panel:RefreshList()
        QueryItems()
    end)

    panelFrame:SetScript("OnHide", function()
        selectedItemID = nil
    end)

    if not panelFrame.fluxItemDataHooked then
        panelFrame.fluxItemDataHooked = true
        local itemDataRefreshPending = false
        panelFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
        panelFrame:SetScript("OnEvent", function(_, event)
            if event == "ITEM_DATA_LOAD_RESULT" and panelFrame:IsShown() then
                if itemDataRefreshPending then return end
                itemDataRefreshPending = true
                local function run()
                    itemDataRefreshPending = false
                    if panelFrame:IsShown() then
                        Panel:RefreshList()
                    end
                end
                if C_Timer and C_Timer.After then
                    C_Timer.After(0.2, run)
                else
                    run()
                end
            end
        end)
    end

    return panelFrame
end

function Panel:Init()
    if not MerchantFrame or not FJ then
        return
    end
    FJ.Init()
    CreatePanelFrame()

    if panelFrame and FVID and FVID.IsPreDragonflight and FVID.IsPreDragonflight() then
        panelFrame:SetFrameStrata(MerchantFrame:GetFrameStrata())
    end

    if panelFrame then
        if panelFrame.TitleText then
            panelFrame.TitleText:SetText("JunkList")
        elseif panelFrame.TitleContainer and panelFrame.TitleContainer.TitleText then
            panelFrame.TitleContainer.TitleText:SetText("JunkList")
        end
    end

    if not merchantTab then
        merchantTab = LibStub("SecureTabs-2.0"):Add(MerchantFrame)
        merchantTab.frame = panelFrame
    end
    merchantTab.OnSelect = function()
        if FluxVendorAutoMerchantUI and FluxVendorAutoMerchantUI.OnBuyTabHidden then
            FluxVendorAutoMerchantUI.OnBuyTabHidden()
        end
    end
    merchantTab:SetText("Junk")
    if FVID and FVID.ApplyPreDFMerchantSecureTabLayers then
        FVID.ApplyPreDFMerchantSecureTabLayers(MerchantFrame)
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if MerchantFrame then
            Panel:Init()
        end
    end
end)

