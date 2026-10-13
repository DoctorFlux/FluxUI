-- FluxSmartHearthConfig.lua - Standalone Hearthstone Configuration System
-- Mirrors FluxSmartMountConfig structure for account/character-specific settings

-- Only load if Toy Box is available (Retail only)
if not FLUX_API or not FLUX_API.hasToyBox then
    return
end

-- Player class colour for border theming
local _, playerClass = UnitClass("player")
local CLASS_COLOUR = RAID_CLASS_COLORS[playerClass] or { r = 1, g = 1, b = 1 }

-- ============================
-- Character Key Helper
-- ============================

local function GetCharKey()
    local PN = _G.Flux and _G.Flux.PlayerName
    if PN and PN.GetCharKey then
        return PN.GetCharKey("hyphen")
    end
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    if playerName and realmName then
        return playerName .. "-" .. realmName
    end
    return nil
end

-- Retail/Midnight/Forever dropped the MouseIsOver global; Classic still has it.
local function FrameMouseOver(frame)
    if not frame then
        return false
    end
    if frame.IsForbidden and frame:IsForbidden() then
        return false
    end
    if frame.IsMouseOver then
        local ok, over = pcall(frame.IsMouseOver, frame)
        if ok then
            return over and true or false
        end
    end
    if MouseIsOver then
        local ok, over = pcall(MouseIsOver, frame)
        if ok and over then
            return true
        end
    end
    return false
end

-- ============================
-- Saved Variables
-- ============================

-- Initialize the saved variables structure
-- Account-wide: FluxNonCombatGridDB.global.hearthConfig
-- Character-specific: _FluxUI_CharSavedVars.hearthConfig and _FluxUI_CharSavedVars.useCharacterSpecific
local function InitializeHearthConfig()
    -- Account-wide hearth config (FluxNonCombatGridDB)
    if not FluxNonCombatGridDB then
        FluxNonCombatGridDB = {}
    end
    if not FluxNonCombatGridDB.global then
        FluxNonCombatGridDB.global = {}
    end
    if not FluxNonCombatGridDB.global.hearthConfig then
        FluxNonCombatGridDB.global.hearthConfig = {}
    end

    -- Character-specific hearth settings (_FluxUI_CharSavedVars)
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end

    -- Character-specific hearth config
    if not _FluxUI_CharSavedVars.hearthConfig then
        _FluxUI_CharSavedVars.hearthConfig = {}
    end

    -- Character-specific settings
    if _FluxUI_CharSavedVars.useCharacterSpecific == nil then
        _FluxUI_CharSavedVars.useCharacterSpecific = false
    end
end

-- ============================
-- Change Listeners
-- ============================

local changeListeners = {}

local function NotifyChange()
    for _, fn in ipairs(changeListeners) do
        if type(fn) == "function" then
            pcall(fn)
        end
    end
end

local function RegisterListener(fn)
    if type(fn) ~= "function" then return end
    table.insert(changeListeners, fn)
end

local function UnregisterListener(fn)
    for i = #changeListeners, 1, -1 do
        if changeListeners[i] == fn then table.remove(changeListeners, i) end
    end
end

-- ============================
-- Helpers
-- ============================

local DEFAULT_HEARTH_ITEMID = 6948 -- Hearthstone

local function IsUsingCharacterSpecific()
    InitializeHearthConfig()
    return _FluxUI_CharSavedVars.useCharacterSpecific == true
end

local function GetActiveHearthContainer()
    InitializeHearthConfig()
    if IsUsingCharacterSpecific() then
        return _FluxUI_CharSavedVars.hearthConfig
    else
        return FluxNonCombatGridDB.global.hearthConfig
    end
end

local function ToggleCharacterSpecific()
    InitializeHearthConfig()
    _FluxUI_CharSavedVars.useCharacterSpecific = not _FluxUI_CharSavedVars.useCharacterSpecific

    -- If switching to character mode and empty, copy account-wide
    if _FluxUI_CharSavedVars.useCharacterSpecific then
        local c = _FluxUI_CharSavedVars.hearthConfig or {}
        _FluxUI_CharSavedVars.hearthConfig = c
        if not c.itemID and not c.mode then
            local g = FluxNonCombatGridDB.global.hearthConfig or {}
            c.mode = g.mode or "default"
            c.itemID = g.itemID or 0
        end
    end

    NotifyChange()
    return _FluxUI_CharSavedVars.useCharacterSpecific
end

-- ============================
-- Tooltip Scan (validate hearthstone)
-- ============================

local scanTooltip = CreateFrame("GameTooltip", "FluxHearthScanTooltip", UIParent, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local function GetTooltipTextForItem(itemID)
    if not itemID then return "" end
    scanTooltip:ClearLines()
    pcall(scanTooltip.SetHyperlink, scanTooltip, "item:" .. tostring(itemID))
    local text = ""
    local numLines = scanTooltip:NumLines() or 0
    for i = 1, numLines do
        local left = _G["FluxHearthScanTooltipTextLeft" .. i]
        if left then
            local line = left:GetText()
            if line and line ~= "" then
                text = text .. "\n" .. string.lower(line)
            end
        end
    end
    return text
end

local function IsHearthstoneLikeItem(itemID)
    if not itemID then return false end
    local body = GetTooltipTextForItem(itemID)
    -- Look for classic hearthstone wording
    if body:find("returns you to", 1, true) or body:find("return you to", 1, true) then
        return true
    end
    if body:find("set your hearthstone", 1, true) then
        return true
    end
    -- Many hearthstones are toys
    if PlayerHasToy and PlayerHasToy(itemID) then
        return true
    end
    return false
end

-- ============================
-- Persistence
-- ============================

-- Hearthstone toy database (subset; extend as needed)
local covenantsMaxed = nil
local function GetCovenantData(id)
    if covenantsMaxed then return covenantsMaxed[id] end
    covenantsMaxed = {}
    for i = 1, 4 do
        local _, _, completed = GetAchievementCriteriaInfo(15646, i)
        covenantsMaxed[i] = completed
    end
    return covenantsMaxed[id]
end

local HEARTHSTONE_TOYS = {
    [54452] = true,   -- Ethereal Portal
    [64488] = true,   -- The Innkeeper's Daughter
    [93672] = true,   -- Dark Portal
    [142542] = true,  -- Tome of Town Portal
    [162973] = true,  -- Greatfather Winter's Hearthstone
    [163045] = true,  -- Headless Horseman's Hearthstone
    [163206] = true,  -- Weary Spirit Binding
    [165669] = true,  -- Lunar Elder's Hearthstone
    [165670] = true,  -- Peddlefeet's Lovely Hearthstone
    [165802] = true,  -- Noble Gardener's Hearthstone
    [166746] = true,  -- Fire Eater's Hearthstone
    [166747] = true,  -- Brewfest Reveler's Hearthstone
    [168907] = true,  -- Holographic Digitalization Hearthstone
    [172179] = true,  -- Eternal Traveler's Hearthstone
    [180290] = function()
        if GetCovenantData(3) then return true end
        local covenantID = C_Covenants and C_Covenants.GetActiveCovenantID and C_Covenants.GetActiveCovenantID()
        return covenantID == 3
    end,            -- Night Fae Hearthstone
    [182773] = function()
        if GetCovenantData(2) then return true end
        local covenantID = C_Covenants and C_Covenants.GetActiveCovenantID and C_Covenants.GetActiveCovenantID()
        return covenantID == 4
    end,            -- Necrolord Hearthstone
    [183716] = function()
        if GetCovenantData(4) then return true end
        local covenantID = C_Covenants and C_Covenants.GetActiveCovenantID and C_Covenants.GetActiveCovenantID()
        return covenantID == 2
    end,            -- Venthyr Sinstone
    [184353] = function()
        if GetCovenantData(1) then return true end
        local covenantID = C_Covenants and C_Covenants.GetActiveCovenantID and C_Covenants.GetActiveCovenantID()
        return covenantID == 1
    end,            -- Kyrian Hearthstone
    [188952] = true,  -- Dominated Hearthstone
    [190196] = true,  -- Enlightened Hearthstone
    [190237] = true,  -- Broker Translocation Matrix
    [193588] = true,  -- Timewalker's Hearthstone
    [200630] = true,  -- Ohn'ir Windsage's Hearthstone
    [206195] = true,  -- Path of the Naaru
    [208704] = true,  -- Deepdweller's Earthen Hearthstone
    [209035] = true,  -- Hearthstone of the Flame
    [210455] = function()
        local _, _, raceId = UnitRace("player")
        return (raceId == 11 or raceId == 30) -- Draenei or Lightforged Draenei
    end,            -- Draenic Hologem
    [212337] = true,  -- Stone of the Hearth
    [228940] = true,  -- Notorious Thread's Hearthstone
    [236687] = true,  -- Explosive Hearthstone
    [235016] = true,  -- Redeployment Module
    [245970] = true,  -- P.O.S.T. Master's Express Hearthstone
    [246565] = true,  -- Cosmic Hearthstone
}

local function GetOwnedHearthstoneToys()
    local owned = {}
    for toyId, usable in pairs(HEARTHSTONE_TOYS) do
        if PlayerHasToy and PlayerHasToy(toyId) then
            if type(usable) == "function" then
                local ok = usable()
                if ok then table.insert(owned, toyId) end
            else
                table.insert(owned, toyId)
            end
        end
    end
    table.sort(owned)
    return owned
end

local RANDOM_ICON = 1669494 -- misc_rune_pvp_random

local function SaveHearthChoice(choice)
    local container = GetActiveHearthContainer()
    if choice == "default" then
        container.mode = "default"
        container.itemID = 0
        print("|cFF00FF00[FluxHearthConfig]|r Using default Hearthstone")
    elseif choice == "random" then
        local owned = GetOwnedHearthstoneToys()
        if #owned == 0 then
            print("|cFFFF9900[FluxHearthConfig]|r No hearthstone toys owned; defaulting to basic Hearthstone.")
            container.mode = "default"
            container.itemID = 0
        else
            container.mode = "random"
            container.itemID = 0
        end
    else
        local itemID = tonumber(choice)
        if not itemID then return end
        if not IsHearthstoneLikeItem(itemID) then
            print("|cFFFF0000[FluxHearthConfig]|r That item does not appear to be a hearthstone.")
            return
        end
        container.mode = "explicit"
        container.itemID = itemID
    end
    if FluxHearthConfigFrame and FluxHearthConfigFrame.UpdateDisplay then
        FluxHearthConfigFrame:UpdateDisplay()
    end
    NotifyChange()
end

local function SaveHearthItem(itemID)
    SaveHearthChoice(itemID)
end

local function GetConfiguredHearthItem()
    local container = GetActiveHearthContainer()
    local mode = container.mode or (container.itemID and container.itemID ~= 0 and "explicit" or "default")
    if mode == "random" then
        local owned = GetOwnedHearthstoneToys()
        if #owned > 0 then
            return owned[math.random(#owned)]
        end
        return DEFAULT_HEARTH_ITEMID
    elseif mode == "default" then
        return DEFAULT_HEARTH_ITEMID
    elseif mode == "explicit" and container.itemID and container.itemID ~= 0 then
        return container.itemID
    end
    return DEFAULT_HEARTH_ITEMID
end

local function AutoPopulateDefaultIfEmpty()
    local container = GetActiveHearthContainer()
    if (not container.itemID or container.itemID == 0) and not container.mode then
        container.mode = "default"
        container.itemID = 0
    end
end

-- ============================
-- Collections Journal Hook (Toy Box)
-- ============================

local hearthUIInitialized = false

local function OpenToyBox()
    if not CollectionsJournal then
        LoadAddOn("Blizzard_Collections")
    end
    if CollectionsJournal then
        if not CollectionsJournal:IsShown() then
            ToggleCollectionsJournal(3) -- Toy Box tab
        else
            CollectionsJournal_SetTab(CollectionsJournal, 3)
        end
    end
end

-- ============================
-- UI
-- ============================

local function CreateHearthConfigUI()
    if hearthUIInitialized then return end
    
    -- Ensure Blizzard_Collections is loaded
    if not CollectionsJournal then
        if LoadAddOn then
            LoadAddOn("Blizzard_Collections")
        elseif C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_Collections")
        end
    end
    
    local collectionsJournal = _G["CollectionsJournal"]
    if not collectionsJournal then
        -- Wait for Blizzard_Collections to load
        local f = CreateFrame("Frame")
        f:RegisterEvent("ADDON_LOADED")
        f:SetScript("OnEvent", function(self, event, addonName)
            if addonName == "Blizzard_Collections" then
                CreateHearthConfigUI()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
        return
    end
    
    hearthUIInitialized = true

    local function CreateFrameInternal()
        local frame = CreateFrame("Frame", "FluxHearthConfigFrame", UIParent)
        frame:SetSize(140, 160)
        frame:SetPoint("TOPRIGHT", collectionsJournal, "TOPRIGHT", 100, -40)
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(collectionsJournal:GetFrameLevel() + 10)
        frame:Hide()

        -- Apply FluxBorder (same as mount config)
        if FluxBorder and FluxBorder.ApplyTo then
            FluxBorder:ApplyTo(frame, 0, 0, 0, 0)
            FluxBorder:SetClassColor(frame, 1, true)
        end

        local function ApplyBorderColor()
            local useCharacter = IsUsingCharacterSpecific()
            
            if FluxBorder then
                if useCharacter then
                    FluxBorder:SetClassColor(frame, 1, true)
                else
                    if FluxBorder.SetBorderColor then
                        FluxBorder:SetBorderColor(frame, 0.5, 0.5, 0.5, 1)
                    end
                    if FluxBorder.SetBackdropColor then
                        FluxBorder:SetBackdropColor(frame, 0.1, 0.1, 0.1, 0.85)
                    end
                end
            end
            
            if frame.slotBorder and frame.slotBorder.SetVertexColor then
                local r, g, b = useCharacter and CLASS_COLOUR.r or 0.4, useCharacter and CLASS_COLOUR.g or 0.4, useCharacter and CLASS_COLOUR.b or 0.4
                frame.slotBorder:SetVertexColor(r, g, b, 0.8)
            end
        end

        local toggleButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        toggleButton:SetSize(100, 24)
        toggleButton:SetPoint("TOP", frame, "TOP", 0, -6)
        toggleButton:SetText("Account")
        local function UpdateToggleText()
            if IsUsingCharacterSpecific() then
                toggleButton:SetText("Character")
            else
                toggleButton:SetText("Account")
            end
        end
        toggleButton:SetScript("OnClick", function()
            if toggleButton.clickCooldown then return end
            toggleButton.clickCooldown = true
            ToggleCharacterSpecific()
            UpdateToggleText()
            frame:UpdateDisplay()
            ApplyBorderColor()
            C_Timer.After(0.3, function() toggleButton.clickCooldown = false end)
        end)

        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOP", frame, "TOP", 0, -36)
        label:SetText("Hearthstone")

        local button = CreateFrame("Button", nil, frame)
        button:SetSize(50, 50)
        button:SetPoint("TOP", label, "BOTTOM", 0, -2)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(42, 42)
        icon:SetPoint("CENTER")
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        button.icon = icon

        local border = button:CreateTexture(nil, "OVERLAY")
        border:SetSize(72, 72)
        border:SetPoint("CENTER")
        border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        border:SetVertexColor(0.4, 0.4, 0.4, 0.8)
        frame.slotBorder = border

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetSize(70, 70)
        highlight:SetPoint("CENTER")
        highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        highlight:SetVertexColor(1, 1, 0, 0.8)
        highlight:SetBlendMode("ADD")
        button:SetHighlightTexture(highlight)

        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local itemID = GetConfiguredHearthItem()
            local name = GetItemInfo(itemID) or "Hearthstone"
            GameTooltip:SetText(name, 1, 1, 1)
            GameTooltip:AddLine("Left-click: choose hearthstone", 0.6, 0.8, 1)
            GameTooltip:AddLine("Right-click: use default", 0.6, 0.8, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Flyout menu: left-click opens list, right-click sets default
        button:RegisterForClicks("AnyUp")
        local function ResolveHearthIcon(itemID)
            if not itemID or itemID == 0 then return 134400 end
            local iconT = nil
            -- Try ToyBox first (returns: itemID, name, icon, ...)
            if C_ToyBox and C_ToyBox.GetToyInfo then
                local _, _, toyIcon = C_ToyBox.GetToyInfo(itemID)
                if toyIcon then iconT = toyIcon end
            end
            -- Item API fallbacks
            if not iconT and GetItemIcon then
                iconT = GetItemIcon(itemID)
            end
            if not iconT and GetItemInfoInstant then
                local _, _, _, _, instantIcon = GetItemInfoInstant(itemID)
                iconT = instantIcon
            end
            -- Ask client to load item data if still missing
            if not iconT and C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(itemID)
            end
            return iconT or 134400
        end
        local function ToggleHearthFlyout(ownerButton)
            if ownerButton.flyout and ownerButton.flyout:IsShown() then
                ownerButton.flyout:Hide()
                return
            end
            if not ownerButton.flyout then
                ownerButton.flyout = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                ownerButton.flyout:SetFrameStrata("DIALOG")
                ownerButton.flyout:SetPoint("TOP", ownerButton, "BOTTOM", 0, 0)
                ownerButton.flyout:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
                ownerButton.flyout:SetBackdropColor(0, 0, 0, 0.9)
                ownerButton.flyout:EnableMouse(true)
                ownerButton.flyout:SetClampedToScreen(true)
                ownerButton.flyout.items = {}
                ownerButton.flyout.ownerButton = ownerButton
                ownerButton.flyout:SetScript("OnLeave", function(self)
                    local overSelf = FrameMouseOver(self)
                    local overOwner = self.ownerButton and FrameMouseOver(self.ownerButton)
                    if not overSelf and not overOwner then
                        self:Hide()
                    end
                end)
                ownerButton:HookScript("OnLeave", function(btn)
                    local f = btn.flyout
                    if f and f:IsShown() then
                        C_Timer.After(0, function()
                            if not FrameMouseOver(btn) and (not f or not FrameMouseOver(f)) then
                                if f and f:IsShown() then f:Hide() end
                            end
                        end)
                    end
                end)
            end
            for _, b in ipairs(ownerButton.flyout.items) do b:Hide() end
            wipe(ownerButton.flyout.items)

            local ICON_SIZE = 28
            local ICON_PAD = 8
            local ICON_SPACING = 6
            local COLUMNS = 6

            local entries = {}
            local owned = GetOwnedHearthstoneToys()
            if #owned > 0 then
                table.insert(entries, { toyId = 0, icon = RANDOM_ICON, isRandom = true })
            end
            for _, toyId in ipairs(owned) do
                table.insert(entries, { toyId = toyId, icon = ResolveHearthIcon(toyId), isRandom = false })
            end

            local function addGridEntry(index, data)
                local col = (index - 1) % COLUMNS
                local row = math.floor((index - 1) / COLUMNS)
                local x = ICON_PAD + col * (ICON_SIZE + ICON_SPACING)
                local y = -(ICON_PAD + row * (ICON_SIZE + ICON_SPACING))

                local entry = CreateFrame("Button", nil, ownerButton.flyout)
                entry:SetSize(ICON_SIZE, ICON_SIZE)
                entry:SetPoint("TOPLEFT", ownerButton.flyout, "TOPLEFT", x, y)

                local tex = entry:CreateTexture(nil, "ARTWORK")
                tex:SetAllPoints(entry)
                tex:SetTexture(data.icon or 134400)
                tex:SetAlpha(1)
                tex:SetDrawLayer("ARTWORK", 1)
                entry._icon = tex
                entry._toyId = data.toyId

                entry:EnableMouse(true)
                entry:SetScript("OnClick", function()
                    if data.isRandom then
                        SaveHearthChoice("random")
                    elseif data.toyId and data.toyId > 0 then
                        SaveHearthChoice(tostring(data.toyId))
                    end
                    ownerButton.flyout:Hide()
                end)
                -- Preload item to improve icon availability
                if data.toyId and data.toyId > 0 and C_Item and C_Item.RequestLoadItemDataByID then
                    C_Item.RequestLoadItemDataByID(data.toyId)
                end
                entry:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(entry, "ANCHOR_RIGHT")
                    if data.isRandom then
                        GameTooltip:SetText("Random Hearthstone Toy")
                        GameTooltip:AddLine("Use a random owned Hearthstone toy.", 0.8, 0.8, 0.8)
                    else
                        if GameTooltip.SetToyByItemID then
                            GameTooltip:SetToyByItemID(data.toyId)
                        else
                            GameTooltip:SetHyperlink("item:" .. tostring(data.toyId))
                        end
                    end
                    GameTooltip:Show()
                end)
                entry:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    local f = ownerButton.flyout
                    if f then f:GetScript("OnLeave")(f) end
                end)

                table.insert(ownerButton.flyout.items, entry)
            end

            for i, data in ipairs(entries) do
                addGridEntry(i, data)
            end

            -- Size the flyout for the grid
            local numEntries = #entries
            local rows = math.max(1, math.ceil(numEntries / COLUMNS))
            local cols = math.min(COLUMNS, numEntries)
            local width = ICON_PAD * 2 + cols * ICON_SIZE + (cols - 1) * ICON_SPACING
            local height = ICON_PAD * 2 + rows * ICON_SIZE + (rows - 1) * ICON_SPACING
            ownerButton.flyout:SetSize(width, height)

            -- Late refresh to populate icons if they weren't cached yet (multiple retries)
            local function refreshIcons()
                local f = ownerButton.flyout
                if not f or not f:IsShown() then return end
                for _, e in ipairs(f.items) do
                    if e._toyId and e._toyId > 0 and e._icon then
                        local tex = ResolveHearthIcon(e._toyId)
                        if tex then e._icon:SetTexture(tex) end
                    end
                end
            end
            C_Timer.After(0.05, refreshIcons)
            C_Timer.After(0.25, refreshIcons)
            C_Timer.After(0.75, refreshIcons)

            ownerButton.flyout:ClearAllPoints()
            ownerButton.flyout:SetPoint("TOP", ownerButton, "BOTTOM", 0, 0)
            ownerButton.flyout:Show()
        end

        button:SetScript("OnMouseUp", function(self, mouseButton)
            if mouseButton == "RightButton" then
                SaveHearthChoice("default")
            else
                ToggleHearthFlyout(self)
                -- Move mouse focus tolerance: if the flyout opens directly under the button,
                -- ensure cursor is not considered "leaving" instantly.
                local f = self.flyout
                if f then
                    f:Raise()
                end
            end
        end)

        function frame:UpdateDisplay()
            AutoPopulateDefaultIfEmpty()
            local container = GetActiveHearthContainer()
            local mode = container.mode or "default"
            if mode == "random" then
                icon:SetTexture(RANDOM_ICON)
            else
                local itemID = GetConfiguredHearthItem()
                local iconFile = GetItemIcon(itemID) or 134400
                icon:SetTexture(iconFile)
            end
            ApplyBorderColor()
        end

        -- Visibility function: only show when CollectionsJournal is open AND on Toys tab (tab 3)
        local function UpdateFrameVisibility()
            if not frame or not collectionsJournal then return end
            if collectionsJournal:IsShown() and collectionsJournal.selectedTab == 3 then
                frame:Show()
                frame:UpdateDisplay()
            else
                frame:Hide()
            end
        end
        
        collectionsJournal:HookScript("OnShow", function()
            UpdateFrameVisibility()
        end)
        collectionsJournal:HookScript("OnHide", function()
            if frame then frame:Hide() end
        end)

        local toysTab = collectionsJournal.ToysTab
        if toysTab then
            toysTab:HookScript("OnClick", function()
                C_Timer.After(0.1, UpdateFrameVisibility)
            end)
        end

        -- Hide on other tabs (like mount config does)
        local otherTabs = { collectionsJournal.MountsTab, collectionsJournal.PetsTab, collectionsJournal.HeirloomsTab, collectionsJournal.WardrobeTab }
        if collectionsJournal.WarbandScenesTab then
            table.insert(otherTabs, collectionsJournal.WarbandScenesTab)
        end
        for _, tab in ipairs(otherTabs) do
            if tab then
                tab:HookScript("OnClick", function()
                    if frame then frame:Hide() end
                end)
            end
        end

        if hooksecurefunc and CollectionsJournal_SetTab then
            hooksecurefunc("CollectionsJournal_SetTab", function(journal, tabID)
                if journal == collectionsJournal and frame then
                    C_Timer.After(0.1, UpdateFrameVisibility)
                end
            end)
        end
        
        -- Store reference for external access
        _G.FluxHearthConfigFrame = frame
        
        -- Initial state: always hidden
        frame:Hide()
        frame:EnableMouse(true)
        frame:UpdateDisplay()
        ApplyBorderColor()
        
        -- Check visibility after a delay to catch cases where CollectionsJournal is already open
        C_Timer.After(0.2, UpdateFrameVisibility)
        
        return true
    end

    CreateFrameInternal()
end

-- ============================
-- API
-- ============================

FluxHearthConfig = {}
FluxHearthConfig.Initialize = InitializeHearthConfig
FluxHearthConfig.IsUsingCharacterSpecific = IsUsingCharacterSpecific
FluxHearthConfig.ToggleCharacterSpecific = ToggleCharacterSpecific
FluxHearthConfig.SaveHearthItem = SaveHearthItem
FluxHearthConfig.GetHearthItem = GetConfiguredHearthItem
FluxHearthConfig.CreateHearthConfigUI = CreateHearthConfigUI
FluxHearthConfig.OpenToyBox = OpenToyBox
FluxHearthConfig.RegisterListener = RegisterListener
FluxHearthConfig.UnregisterListener = UnregisterListener
FluxHearthConfig.IsHearthstoneToy = function(itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end
    return HEARTHSTONE_TOYS[itemID] ~= nil
end
FluxHearthConfig.IsHearthstoneLikeItem = IsHearthstoneLikeItem

_G.FluxHearthConfig = FluxHearthConfig

-- ============================
-- Initialization
-- ============================

local function OnAddonLoaded()
    InitializeHearthConfig()
    CreateHearthConfigUI()
    C_Timer.After(0.5, function()
        AutoPopulateDefaultIfEmpty()
        if FluxHearthConfigFrame and FluxHearthConfigFrame.UpdateDisplay then
            FluxHearthConfigFrame:UpdateDisplay()
        end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "_FluxUI" then
        OnAddonLoaded()
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1.0, function()
            if not hearthUIInitialized then
                CreateHearthConfigUI()
            end
            AutoPopulateDefaultIfEmpty()
            if FluxHearthConfigFrame and FluxHearthConfigFrame.UpdateDisplay then
                FluxHearthConfigFrame:UpdateDisplay()
            end
        end)
    end
end)

-- ============================
-- Slash Commands
-- ============================

SLASH_FLUXHEARTH1 = "/fluxhearth"
SLASH_FLUXHEARTH2 = "/fhc"

function SlashCmdList.FLUXHEARTH(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end

    if #args == 0 or args[1] == "help" then
        print("|cFF00FF00[FluxHearthConfig] Commands:|r")
        print("  /fluxhearth config - Open Toy Box (Collections)")
        print("  /fluxhearth toggle - Toggle character-specific mode")
        print("  /fluxhearth show - Show Hearth config panel")
        print("  /fluxhearth default - Set to basic Hearthstone")
        print("  /fluxhearth item - Print current itemID")
    elseif args[1] == "config" then
        OpenToyBox()
    elseif args[1] == "toggle" then
        local useChar = ToggleCharacterSpecific()
        print("|cFF00FF00[FluxHearthConfig]|r Switched to " .. (useChar and "character-specific" or "account-wide") .. " mode")
        if FluxHearthConfigFrame and FluxHearthConfigFrame.UpdateDisplay then FluxHearthConfigFrame:UpdateDisplay() end
    elseif args[1] == "show" then
        OpenToyBox()
        C_Timer.After(0.5, function()
            if FluxHearthConfigFrame then
                FluxHearthConfigFrame:Show()
                if FluxHearthConfigFrame.UpdateDisplay then
                    FluxHearthConfigFrame:UpdateDisplay()
                end
                print("|cFF00FF00[FluxHearthConfig]|r Frame shown")
            else
                print("|cFFFF0000[FluxHearthConfig]|r Frame not created. Try /fluxhearth config first.")
            end
        end)
    elseif args[1] == "default" then
        SaveHearthItem(DEFAULT_HEARTH_ITEMID)
    elseif args[1] == "item" then
        print("|cFF00FF00[FluxHearthConfig]|r Hearth itemID: " .. tostring(GetConfiguredHearthItem()))
    else
        print("|cFFFF0000[FluxHearthConfig]|r Unknown command. Use '/fluxhearth help'.")
    end
end




