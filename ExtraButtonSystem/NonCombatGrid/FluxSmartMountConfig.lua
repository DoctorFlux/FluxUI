--[[
    ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua
    Mount Configuration System for NonCombatGrid
    
    SavedVariables Structure (uses FluxNonCombatGridDB from TOC):
    FluxNonCombatGridDB = {
        global = {
            mountConfig = {
                ground = "Mount Name",
                flying = "Mount Name",
                groundMulti = "Mount Name",
                flyingMulti = "Mount Name"
            }
        },
        ["CharName-Realm"] = {
            useCharacterSpecific = false,  -- Separate key (top level)
            mountConfig = {                 -- Separate key for character mounts
                ground = "Mount Name",
                flying = "Mount Name",
                groundMulti = "Mount Name",
                flyingMulti = "Mount Name"
            },
            mount = {                       -- Separate key for mode only
                mode = "SmartMount"
            }
        }
    }
    
    Features:
    - Account-wide or character-specific mount settings
    - Ground, Flying, Multi-seat mount configuration
    - Config UI panel next to CollectionsJournal
    - Drag-and-drop mount configuration
    - First load: if all four slots empty, picks first eligible flying then ground mounts from the top of the journal list
      (non–faction-exclusive, shouldHideOnChar=false, non–profession/tradeskill); multi slots mirror those picks
]]

-- Create namespace
FluxSmartMountConfig = FluxSmartMountConfig or {}
local Config = FluxSmartMountConfig

-- Local references
local C_MountJournal = C_MountJournal
local C_Spell = C_Spell

-- Journal: IsFlyableArea / [flyable]. Bag items: continent+outdoors when that API is missing.
local function IsFlyableAreaFixed()
    local Flux = _G.Flux
    local F = Flux and Flux.Inventory and Flux.Inventory.Flyable
    if not F then
        F = _G.FluxInv and _G.FluxInv.Spells
    end
    if F and F.PreferFlying then
        return F.PreferFlying()
    end
    if F and F.IsFlyableHere then
        return F.IsFlyableHere()
    end
    if FluxItemDetection and FluxItemDetection.IsFlyableHere then
        return FluxItemDetection.IsFlyableHere()
    end
    if IsFlyableArea and IsFlyableArea() then
        return true
    end
    return false
end

-- Forward-declared (assigned after changeListeners / NotifyChange definition)
local NotifyChange

-- Get player's class color
local function GetClassColor()
    local _, classFilename = UnitClass("player")
    return RAID_CLASS_COLORS[classFilename] or { r = 0.6, g = 0.6, b = 0.6 }
end

-- UI state
local configFrame = nil
local configuringMount = nil
local mountConfigUICreated = false
local mountConfigHooked = false

-- Timer shim for legacy clients
local Timer = C_Timer or {}
if not Timer.After then
    function Timer.After(delay, cb)
        local f = CreateFrame("Frame")
        local t = 0
        f:SetScript("OnUpdate", function(self, dt)
            t = t + dt
            if t >= (tonumber(delay) or 0) then
                self:SetScript("OnUpdate", nil)
                pcall(cb)
                self:Hide()
            end
        end)
        return f
    end
end

-- ============================================================================
-- CHARACTER KEY HELPER
-- ============================================================================

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

-- ============================================================================
-- SAVED VARIABLES INITIALIZATION
-- ============================================================================

-- Initialize the saved variables structure
-- Account-wide: FluxNonCombatGridDB.global.mountConfig
-- Character-specific: _FluxUI_CharSavedVars.mountConfig, useCharacterSpecific, mode
local function InitializeDB()
    -- Account-wide mount config (FluxNonCombatGridDB)
    if not FluxNonCombatGridDB then
        FluxNonCombatGridDB = {}
    end
    if not FluxNonCombatGridDB.global then
        FluxNonCombatGridDB.global = {}
    end
    if not FluxNonCombatGridDB.global.mountConfig then
        FluxNonCombatGridDB.global.mountConfig = {}
    end

    -- Character-specific mount settings (_FluxUI_CharSavedVars)
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end

    -- Character-specific mount config
    if not _FluxUI_CharSavedVars.mountConfig then
        _FluxUI_CharSavedVars.mountConfig = {}
    end

    -- Character-specific settings
    if _FluxUI_CharSavedVars.useCharacterSpecific == nil then
        _FluxUI_CharSavedVars.useCharacterSpecific = false
    end

    -- Mount mode
    if not _FluxUI_CharSavedVars.mountMode then
        _FluxUI_CharSavedVars.mountMode = "SmartMount"
    end
end

-- ============================================================================
-- AUTOMATIC DEFAULT MOUNTS (first-time empty config)
-- ============================================================================

-- Mount type IDs from journal (aligned with ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua & common community tables)
local MOUNT_TYPE_GROUND_ONLY = {
    [230] = true, -- ground
    [269] = true,
    [408] = true,
    [412] = true,
}
local MOUNT_TYPE_GROUND_DUAL = {
    [248] = true, -- flying + ground
}
local MOUNT_TYPE_CHAUFFEUR = {
    [284] = true,
}
local MOUNT_TYPE_FLYING = {
    [229] = true,
    [247] = true,
    [248] = true,
    [270] = true,
    [398] = true,
    [402] = true,
    [407] = true,
    [424] = true,
    [428] = true,
    [429] = true,
}
local MOUNT_TYPE_SKIP_DEFAULT = {
    [231] = true, -- aquatic
    [232] = true, -- zone / special
    [241] = true,
    [242] = true,
    [254] = true, -- aquatic
}

local function GetMountTypeID(mountID)
    if not C_MountJournal or not C_MountJournal.GetMountInfoExtraByID then
        return nil
    end
    local _, _, _, _, mt = C_MountJournal.GetMountInfoExtraByID(mountID)
    if type(mt) == "number" then
        return mt
    end
    return nil
end

local function SpellNameForMountSpell(spellID, journalName)
    if spellID and C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo and spellInfo.name then
            return spellInfo.name
        end
    end
    return journalName
end

-- Mount journal sourceType: 4 = Profession (engineering mounts, etc.) — see wiki/API docs
local MOUNT_SOURCE_PROFESSION = (Enum.MountJournalMountSource and Enum.MountJournalMountSource.Profession) or 4

-- Fallback when Blizzard leaves profession mounts as sourceType 0 ("uncategorized")
local SPELL_MOUNT_DEFAULT_BLOCKLIST = {
    [44151] = true, -- Turbo-Charged Flying Machine
    [44153] = true, -- Flying Machine
    [61451] = true, -- Flying Carpet (Tailoring)
    [75596] = true, -- Frosty Flying Carpet
    [61309] = true, -- Magnificent Flying Carpet
    [89363] = true, -- Crimson Flying Carpet
}

--- Non–faction-exclusive, non–class-exclusive (shouldHideOnChar), non–profession / trade-skill requirement.
local function MountPassesDefaultFilters(spellID, sourceType, isFactionSpecific, shouldHideOnChar, isUsable, isCollected)
    if not isCollected or not spellID or not isUsable then
        return false
    end
    if isFactionSpecific then
        return false
    end
    if shouldHideOnChar then
        return false
    end
    if SPELL_MOUNT_DEFAULT_BLOCKLIST[spellID] then
        return false
    end
    if sourceType == MOUNT_SOURCE_PROFESSION then
        return false
    end
    if C_Spell and C_Spell.GetSpellTradeSkillLink then
        local ok, link = pcall(C_Spell.GetSpellTradeSkillLink, spellID)
        if ok and link and link ~= "" then
            return false
        end
    end
    return true
end

--- Walk mounts in Mount Journal list order (top to bottom). Falls back to GetMountIDs order if display list not ready.
local function ForEachMountJournalDisplayOrder(callback)
    if not C_MountJournal then
        return
    end
    if C_MountJournal.GetNumDisplayedMounts and C_MountJournal.GetDisplayedMountID then
        local n = C_MountJournal.GetNumDisplayedMounts()
        if type(n) == "number" and n > 0 then
            for i = 1, n do
                local mountID = C_MountJournal.GetDisplayedMountID(i)
                if mountID then
                    callback(mountID)
                end
            end
            return
        end
    end
    if C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, mountID in ipairs(ids) do
                callback(mountID)
            end
        end
    end
end

local function FindFirstMountSpellName()
    local bestFly = nil
    local bestGroundStrict = nil
    local bestGroundDual = nil

    ForEachMountJournalDisplayOrder(function(mountID)
        local name, spellID, _, _, isUsable, sourceType, _, isFactionSpecific, _, shouldHideOnChar, isCollected =
            C_MountJournal.GetMountInfoByID(mountID)
        if not MountPassesDefaultFilters(spellID, sourceType, isFactionSpecific, shouldHideOnChar, isUsable, isCollected) then
            return
        end
        local mt = GetMountTypeID(mountID)
        if not mt or MOUNT_TYPE_SKIP_DEFAULT[mt] then
            return
        end
        if MOUNT_TYPE_FLYING[mt] and not bestFly then
            bestFly = SpellNameForMountSpell(spellID, name)
        end
        if MOUNT_TYPE_GROUND_ONLY[mt] or MOUNT_TYPE_CHAUFFEUR[mt] then
            if not bestGroundStrict then
                bestGroundStrict = SpellNameForMountSpell(spellID, name)
            end
        elseif MOUNT_TYPE_GROUND_DUAL[mt] and not bestGroundDual then
            bestGroundDual = SpellNameForMountSpell(spellID, name)
        end
    end)

    local groundPick = bestGroundStrict or bestGroundDual
    return groundPick, bestFly
end

local function MountConfigIsTotallyEmpty(cfg)
    if not cfg then return true end
    local function empty(v)
        return v == nil or v == ""
    end
    return empty(cfg.ground) and empty(cfg.flying) and empty(cfg.groundMulti) and empty(cfg.flyingMulti)
end

local function MountConfigHasAny(cfg)
    if not cfg then return false end
    return (cfg.ground and cfg.ground ~= "") or (cfg.flying and cfg.flying ~= "")
        or (cfg.groundMulti and cfg.groundMulti ~= "") or (cfg.flyingMulti and cfg.flyingMulti ~= "")
end

--- Fill global.mountConfig when unset; multi slots mirror ground/flying picks. Copies account → empty character slots.
local function ApplyAutomaticMountDefaultsIfNeeded()
    InitializeDB()
    if not C_MountJournal or not C_MountJournal.GetMountIDs then
        return
    end

    local globalCfg = FluxNonCombatGridDB.global.mountConfig
    local changed = false

    if MountConfigIsTotallyEmpty(globalCfg) then
        local groundName, flyingName = FindFirstMountSpellName()
        if groundName or flyingName then
            globalCfg.ground = groundName
            globalCfg.flying = flyingName
            globalCfg.groundMulti = groundName
            globalCfg.flyingMulti = flyingName
            changed = true
        end
    end

    if _FluxUI_CharSavedVars.useCharacterSpecific then
        local charCfg = _FluxUI_CharSavedVars.mountConfig
        if MountConfigIsTotallyEmpty(charCfg) and MountConfigHasAny(globalCfg) then
            charCfg.ground = globalCfg.ground
            charCfg.flying = globalCfg.flying
            charCfg.groundMulti = globalCfg.groundMulti
            charCfg.flyingMulti = globalCfg.flyingMulti
            changed = true
        end
    end

    if changed then
        NotifyChange()
    end
end

-- ============================================================================
-- CHANGE LISTENERS
-- ============================================================================

local changeListeners = {}

NotifyChange = function()
    for _, fn in ipairs(changeListeners) do
        if type(fn) == "function" then
            pcall(fn)
        end
    end
    
    -- Direct fallback for mount button
    if _G.FluxNCMount and _G.FluxNCMount.Update then
        pcall(_G.FluxNCMount.Update)
    end
end

function Config.RegisterListener(fn)
    if type(fn) ~= "function" then return end
    table.insert(changeListeners, fn)
end

function Config.UnregisterListener(fn)
    for i = #changeListeners, 1, -1 do
        if changeListeners[i] == fn then
            table.remove(changeListeners, i)
        end
    end
end

-- ============================================================================
-- CORE CONFIGURATION FUNCTIONS
-- ============================================================================

-- Check if using character-specific mount settings
function Config.IsUsingCharacterSpecific()
    InitializeDB()

    return _FluxUI_CharSavedVars.useCharacterSpecific == true
end

-- Get mount mode (SmartMount or VendorMount)
function Config.GetMountMode()
    InitializeDB()

    return _FluxUI_CharSavedVars.mountMode or "SmartMount"
end

-- Set mount mode
function Config.SetMountMode(mode)
    InitializeDB()

    _FluxUI_CharSavedVars.mountMode = mode
    NotifyChange()
end

-- Get current mount config (returns the appropriate table based on mode)
function Config.GetCurrentMountConfig()
    InitializeDB()

    -- Check if using character-specific settings
    if _FluxUI_CharSavedVars.useCharacterSpecific then
        -- Return character-specific mount config
        return _FluxUI_CharSavedVars.mountConfig
    end

    -- Return account-wide mount config
    return FluxNonCombatGridDB.global.mountConfig
end

-- Toggle between account-wide and character-specific mode
function Config.ToggleCharacterSpecific()
    InitializeDB()

    local newMode = not _FluxUI_CharSavedVars.useCharacterSpecific
    _FluxUI_CharSavedVars.useCharacterSpecific = newMode

    -- If switching TO character mode AND character has no mounts set, copy from account
    if newMode then
        local charCfg = _FluxUI_CharSavedVars.mountConfig
        local hasAnyCharMounts = (charCfg.ground and charCfg.ground ~= "")
            or (charCfg.flying and charCfg.flying ~= "")
            or (charCfg.groundMulti and charCfg.groundMulti ~= "")
            or (charCfg.flyingMulti and charCfg.flyingMulti ~= "")

        if not hasAnyCharMounts then
            local acc = FluxNonCombatGridDB.global.mountConfig or {}
            charCfg.ground = acc.ground
            charCfg.flying = acc.flying
            charCfg.groundMulti = acc.groundMulti or acc.ground or acc.flying
            charCfg.flyingMulti = acc.flyingMulti or acc.flying or acc.ground
        end
    end

    -- Update UI
    if configFrame and configFrame.UpdateDisplay then
        configFrame:UpdateDisplay()
    end

    NotifyChange()
    return newMode
end

-- Save a mount to the appropriate config
function Config.SaveMountConfig(slotKey, mountName)
    InitializeDB()

    if _FluxUI_CharSavedVars.useCharacterSpecific then
        -- Save to character-specific mount config
        _FluxUI_CharSavedVars.mountConfig[slotKey] = mountName
        print("|cFF00FF00[FluxUI]|r Saved " .. tostring(mountName) .. " to character mount config")
    else
        -- Save to account-wide mount config
        FluxNonCombatGridDB.global.mountConfig[slotKey] = mountName
        print("|cFF00FF00[FluxUI]|r Saved " .. tostring(mountName) .. " to account mount config")
    end

    -- Update UI
    if configFrame and configFrame.UpdateDisplay then
        configFrame:UpdateDisplay()
    end

    NotifyChange()
end

-- ============================================================================
-- MOUNT GETTERS
-- ============================================================================

function Config.GetGroundMount()
    local config = Config.GetCurrentMountConfig()
    return config and config.ground
end

function Config.GetFlyingMount()
    local config = Config.GetCurrentMountConfig()
    return config and config.flying
end

function Config.GetGroundMultiMount()
    local config = Config.GetCurrentMountConfig()
    if not config then return nil end
    return config.groundMulti or config.ground or config.flying
end

function Config.GetFlyingMultiMount()
    local config = Config.GetCurrentMountConfig()
    if not config then return nil end
    return config.flyingMulti or config.flying or config.ground
end

function Config.GetMultiMount()
    local isFlyable = IsFlyableAreaFixed()
    if isFlyable then
        return Config.GetFlyingMultiMount()
    else
        return Config.GetGroundMultiMount()
    end
end

function Config.GetUtilityMount()
    return Config.GetMultiMount()
end

function Config.GetSmartMount()
    local isFlyable = IsFlyableAreaFixed()
    if isFlyable then
        return Config.GetFlyingMount()
    else
        return Config.GetGroundMount()
    end
end

-- ============================================================================
-- VENDOR MOUNT DETECTION
-- ============================================================================

function Config.GetVendorMount()
    local vendorMounts = {
        "Trader's Gilded Brutosaur",
        "Grand Expedition Yak",
        "Traveler's Tundra Mammoth",
    }
    
    if C_MountJournal and C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, vendorName in ipairs(vendorMounts) do
                for _, id in ipairs(ids) do
                    local name, spellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(id)
                    if isCollected and name and name:lower() == vendorName:lower() then
                        if C_Spell and C_Spell.GetSpellInfo then
                            local spellInfo = C_Spell.GetSpellInfo(spellID)
                            if spellInfo and spellInfo.name then
                                return spellInfo.name
                            end
                        end
                        return name
                    end
                end
            end
        end
    end
    
    return nil
end

function Config.GetVendorMountTexture()
    local vendorMount = Config.GetVendorMount()
    if vendorMount then
        if C_Spell and C_Spell.GetSpellTexture then
            return C_Spell.GetSpellTexture(vendorMount)
        elseif GetSpellTexture then
            return GetSpellTexture(vendorMount)
        end
    end
    return nil
end

function Config.HasAnyVendorMount()
    return Config.GetVendorMount() ~= nil
end

-- ============================================================================
-- TEXTURE HELPER
-- ============================================================================

function Config.GetMountIconTexture(mountName)
    if not mountName then return nil end
    
    if C_Spell and C_Spell.GetSpellTexture then
        local texture = C_Spell.GetSpellTexture(mountName)
        if texture then return texture end
    end
    
    if GetSpellTexture then
        local texture = GetSpellTexture(mountName)
        if texture then return texture end
    end
    
    if C_MountJournal and C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, id in ipairs(ids) do
                local name, _, icon = C_MountJournal.GetMountInfoByID(id)
                if name and name:lower() == mountName:lower() then
                    return icon
                end
            end
        end
    end
    
    return nil
end

-- ============================================================================
-- MOUNT JOURNAL HOOKS
-- ============================================================================

local function SetupMountJournalHook()
    if mountConfigHooked then return end
    mountConfigHooked = true
    
    if not C_MountJournal then return end
    
    local collectionsJournal = _G["CollectionsJournal"]
    if collectionsJournal and collectionsJournal.MountsTab then
        local mountsTab = collectionsJournal.MountsTab
        local summonButton = mountsTab.SummonRandomFavoriteButton or mountsTab.SummonButton
        if summonButton then
            local originalOnClick = summonButton:GetScript("OnClick")
            summonButton:SetScript("OnClick", function(self, ...)
                if configuringMount then
                    local selectedMountID = _G.MountJournal and _G.MountJournal.selectedMountID
                    if selectedMountID and C_MountJournal.GetMountInfoByID then
                        local mountName, mountSpellID = C_MountJournal.GetMountInfoByID(selectedMountID)
                        if mountName and mountSpellID then
                            local spellName = mountName
                            if C_Spell and C_Spell.GetSpellInfo then
                                local spellInfo = C_Spell.GetSpellInfo(mountSpellID)
                                if spellInfo and spellInfo.name then
                                    spellName = spellInfo.name
                                end
                            end
                            Config.SaveMountConfig(configuringMount, spellName)
                            configuringMount = nil
                            return
                        end
                    end
                end
                
                if originalOnClick then
                    originalOnClick(self, ...)
                end
            end)
        end
    end
end

function Config.OpenMountJournal()
    if not CollectionsJournal then
        if LoadAddOn then
            LoadAddOn("Blizzard_Collections")
        elseif C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_Collections")
        end
    end
    
    if CollectionsJournal then
        if not CollectionsJournal:IsShown() then
            ToggleCollectionsJournal(1)
        elseif CollectionsJournal_SetTab then
            CollectionsJournal_SetTab(CollectionsJournal, 1)
        end
    end
    
    SetupMountJournalHook()
end

-- ============================================================================
-- CONFIG UI
-- ============================================================================

function Config.CreateMountConfigUI()
    if mountConfigUICreated then return end
    mountConfigUICreated = true
    
    local function CreateConfigFrame()
        local parentFrame = _G["CollectionsJournal"]
        if not parentFrame then return false end
        
        local classColor = GetClassColor()
        
        configFrame = CreateFrame("Frame", "FluxSmartMountConfigFrame", UIParent)
        configFrame:SetSize(120, 360)
        configFrame:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 130, -25)
        configFrame:SetFrameStrata("MEDIUM")
        configFrame:SetFrameLevel(100)
        configFrame:Hide()
        
        if FluxBorder and FluxBorder.ApplyTo then
            FluxBorder:ApplyTo(configFrame, 0, 0, 0, 0)
            FluxBorder:SetClassColor(configFrame, 1, true)
        end
        
        local function ApplyBorderColor()
            local useCharacter = Config.IsUsingCharacterSpecific()
            
            if FluxBorder then
                if useCharacter then
                    FluxBorder:SetClassColor(configFrame, 1, true)
                else
                    if FluxBorder.SetBorderColor then
                        FluxBorder:SetBorderColor(configFrame, 0.5, 0.5, 0.5, 1)
                    end
                    if FluxBorder.SetBackdropColor then
                        FluxBorder:SetBackdropColor(configFrame, 0.1, 0.1, 0.1, 0.85)
                    end
                end
            end
            
            if configFrame.mountSlotBorders then
                local r, g, b = useCharacter and classColor.r or 0.5, useCharacter and classColor.g or 0.5, useCharacter and classColor.b or 0.5
                for _, border in ipairs(configFrame.mountSlotBorders) do
                    if border and border.SetVertexColor then
                        border:SetVertexColor(r, g, b, 1)
                    end
                end
            end
        end
        
        local toggleButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
        toggleButton:SetSize(100, 22)
        toggleButton:SetPoint("TOP", configFrame, "TOP", 0, -8)
        toggleButton:SetText("Account")
        
        local function UpdateToggleText()
            if Config.IsUsingCharacterSpecific() then
                toggleButton:SetText("Character")
            else
                toggleButton:SetText("Account")
            end
        end
        
        toggleButton:SetScript("OnClick", function()
            if toggleButton.clickCooldown then return end
            toggleButton.clickCooldown = true
            
            Config.ToggleCharacterSpecific()
            UpdateToggleText()
            ApplyBorderColor()
            
            Timer.After(0.3, function()
                toggleButton.clickCooldown = false
            end)
        end)
        
        local slots = {
            { name = "Ground", key = "ground", y = -40 },
            { name = "Flying", key = "flying", y = -118 },
            { name = "Ground Multi", key = "groundMulti", y = -196 },
            { name = "Flying Multi", key = "flyingMulti", y = -274 },
        }
        
        configFrame.slots = {}
        configFrame.mountSlotBorders = {}
        
        for _, slotInfo in ipairs(slots) do
            local label = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOP", configFrame, "TOP", 0, slotInfo.y)
            label:SetText(slotInfo.name)
            label:SetTextColor(1, 1, 1)
            
            local button = CreateFrame("Button", nil, configFrame)
            button:SetSize(48, 48)
            button:SetPoint("TOP", label, "BOTTOM", 0, -2)
            
            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetSize(40, 40)
            icon:SetPoint("CENTER")
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            button.icon = icon
            
            local border = button:CreateTexture(nil, "OVERLAY")
            border:SetSize(64, 64)
            border:SetPoint("CENTER")
            border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
            border:SetVertexColor(0.5, 0.5, 0.5, 1)
            button.border = border
            
            table.insert(configFrame.mountSlotBorders, border)
            
            local highlight = button:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetSize(64, 64)
            highlight:SetPoint("CENTER")
            highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            highlight:SetVertexColor(1, 1, 0, 0.8)
            highlight:SetBlendMode("ADD")
            button:SetHighlightTexture(highlight)
            
            button.mountSpell = nil
            button.key = slotInfo.key
            
            button:SetScript("OnEnter", function(self)
                local mountName = self.mountSpell
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if mountName then
                    GameTooltip:SetText(mountName, 1, 1, 1)
                    GameTooltip:AddLine(slotInfo.name .. " Mount Slot", 0.7, 0.7, 0.7)
                else
                    GameTooltip:SetText(slotInfo.name .. " Mount", 1, 1, 1)
                    GameTooltip:AddLine("Not set", 1, 0.5, 0)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Drag mounts here to set", 0.5, 1, 0.5)
                GameTooltip:AddLine("Click to open Mount Journal", 0.6, 0.8, 1)
                GameTooltip:Show()
            end)
            
            button:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            button:RegisterForDrag("LeftButton")
            
            button:SetScript("OnReceiveDrag", function(self)
                local itemType, itemID = GetCursorInfo()
                
                if itemType == "spell" then
                    local spellName = GetSpellInfo(itemID)
                    if spellName then
                        Config.SaveMountConfig(slotInfo.key, spellName)
                    end
                    ClearCursor()
                elseif itemType == "mount" and C_MountJournal then
                    local mountName, mountSpellID = C_MountJournal.GetMountInfoByID(itemID)
                    if mountName and mountSpellID then
                        local spellInfo = nil
                        if C_Spell and C_Spell.GetSpellInfo then
                            spellInfo = C_Spell.GetSpellInfo(mountSpellID)
                        end
                        local spellName = spellInfo and spellInfo.name or mountName
                        if spellName then
                            Config.SaveMountConfig(slotInfo.key, spellName)
                        end
                    end
                    ClearCursor()
                else
                    ClearCursor()
                end
            end)
            
            button:SetScript("OnMouseUp", function(self, mouseButton)
                local itemType = GetCursorInfo()
                if itemType then
                    self:GetScript("OnReceiveDrag")(self)
                end
            end)
            
            local setButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
            setButton:SetSize(48, 16)
            setButton:SetPoint("TOP", button, "BOTTOM", 0, -1)
            setButton:SetText("Set")
            setButton:SetNormalFontObject("GameFontNormalSmall")
            button.setButton = setButton
            
            setButton:SetScript("OnClick", function()
                local selectedMountID = nil
                local mountJournal = _G["MountJournal"]
                if mountJournal and mountJournal.selectedMountID then
                    selectedMountID = mountJournal.selectedMountID
                end
                
                if selectedMountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
                    local mountName, mountSpellID = C_MountJournal.GetMountInfoByID(selectedMountID)
                    local spellName = mountName
                    if mountSpellID and C_Spell and C_Spell.GetSpellInfo then
                        local spellInfo = C_Spell.GetSpellInfo(mountSpellID)
                        spellName = spellInfo and spellInfo.name or mountName
                    end
                    if mountName and spellName then
                        Config.SaveMountConfig(slotInfo.key, spellName)
                    end
                end
            end)
            
            button:SetScript("OnClick", function(self)
                configuringMount = self.key
                Config.OpenMountJournal()
            end)
            
            configFrame.slots[slotInfo.key] = button
        end
        
        function configFrame:UpdateDisplay()
            local config = Config.GetCurrentMountConfig()
            if not config then return end
            
            for key, button in pairs(self.slots) do
                local mountName = config[key]
                if mountName and mountName ~= "" then
                    local mountTexture = Config.GetMountIconTexture(mountName)
                    if mountTexture then
                        button.icon:SetTexture(mountTexture)
                    else
                        button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    end
                    button.mountSpell = mountName
                else
                    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    button.mountSpell = nil
                end
            end
            UpdateToggleText()
            ApplyBorderColor()
        end
        
        local collectionsJournal = parentFrame
        
        -- Visibility function: only show when CollectionsJournal is open AND on Mounts tab (tab 1)
        local function UpdateFrameVisibility()
            if not configFrame or not collectionsJournal then return end
            if collectionsJournal:IsShown() and collectionsJournal.selectedTab == 1 then
                configFrame:Show()
                configFrame:UpdateDisplay()
            else
                configFrame:Hide()
            end
        end
        
        collectionsJournal:HookScript("OnShow", function()
            UpdateFrameVisibility()
        end)
        
        collectionsJournal:HookScript("OnHide", function()
            if configFrame then configFrame:Hide() end
        end)
        
        local mountsTab = collectionsJournal.MountsTab
        if mountsTab then
            mountsTab:HookScript("OnClick", function()
                C_Timer.After(0.1, UpdateFrameVisibility)
            end)
        end
        
        local otherTabs = { collectionsJournal.PetsTab, collectionsJournal.ToysTab, collectionsJournal.HeirloomsTab, collectionsJournal.WardrobeTab, collectionsJournal.WarbandScenesTab }
        for _, tab in ipairs(otherTabs) do
            if tab then
                tab:HookScript("OnClick", function()
                    if configFrame then configFrame:Hide() end
                end)
            end
        end
        
        if hooksecurefunc and CollectionsJournal_SetTab then
            hooksecurefunc("CollectionsJournal_SetTab", function(journal, tabID)
                if journal == collectionsJournal and configFrame then
                    C_Timer.After(0.1, UpdateFrameVisibility)
                end
            end)
        end
        
        -- Initial state: always hidden
        configFrame:Hide()
        UpdateToggleText()
        configFrame:UpdateDisplay()
        ApplyBorderColor()
        
        -- Check visibility after a delay to catch cases where CollectionsJournal is already open
        Timer.After(0.2, UpdateFrameVisibility)
        
        return true
    end
    
    if CreateConfigFrame() then return end
    
    local waitFrame = CreateFrame("Frame")
    waitFrame:RegisterEvent("ADDON_LOADED")
    waitFrame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "Blizzard_Collections" then
            if CreateConfigFrame() then
                self:UnregisterEvent("ADDON_LOADED")
            end
        end
    end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local dbInitialized = false

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("NEW_MOUNT_ADDED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "NEW_MOUNT_ADDED" then
        Timer.After(0.2, ApplyAutomaticMountDefaultsIfNeeded)
        return
    end
    if event == "ADDON_LOADED" and addonName == "_FluxUI" then
        -- SavedVariables are now loaded
        -- Initialize account-wide structure
        if not FluxNonCombatGridDB then
            FluxNonCombatGridDB = {}
        end
        if not FluxNonCombatGridDB.global then
            FluxNonCombatGridDB.global = {}
        end
        if not FluxNonCombatGridDB.global.mountConfig then
            FluxNonCombatGridDB.global.mountConfig = {}
        end

        Timer.After(1, function()
            Config.CreateMountConfigUI()
        end)
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Character data is now available
        if not dbInitialized then
            dbInitialized = true
            InitializeDB()
        end

        ApplyAutomaticMountDefaultsIfNeeded()
        Timer.After(1.5, ApplyAutomaticMountDefaultsIfNeeded)

        if not mountConfigUICreated then
            Timer.After(1, function()
                Config.CreateMountConfigUI()
            end)
        end

        -- Notify listeners that config is ready
        Timer.After(0.2, function()
            NotifyChange()
        end)

        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

-- ============================================================================
-- DEBUG HELPER
-- ============================================================================

function Config.DebugPrint()
    InitializeDB()

    print("=== FluxSmartMountConfig Debug ===")

    -- Account-wide data
    print("FluxNonCombatGridDB.global.mountConfig:")
    if FluxNonCombatGridDB and FluxNonCombatGridDB.global and FluxNonCombatGridDB.global.mountConfig then
        local acc = FluxNonCombatGridDB.global.mountConfig
        print("  ground: " .. tostring(acc.ground))
        print("  flying: " .. tostring(acc.flying))
        print("  groundMulti: " .. tostring(acc.groundMulti))
        print("  flyingMulti: " .. tostring(acc.flyingMulti))
    else
        print("  (nil)")
    end

    -- Character-specific data
    print("_FluxUI_CharSavedVars:")
    if _FluxUI_CharSavedVars then
        print("  useCharacterSpecific: " .. tostring(_FluxUI_CharSavedVars.useCharacterSpecific))
        print("  mountMode: " .. tostring(_FluxUI_CharSavedVars.mountMode))

        if _FluxUI_CharSavedVars.mountConfig then
            print("  mountConfig:")
            local char = _FluxUI_CharSavedVars.mountConfig
            print("    ground: " .. tostring(char.ground))
            print("    flying: " .. tostring(char.flying))
            print("    groundMulti: " .. tostring(char.groundMulti))
            print("    flyingMulti: " .. tostring(char.flyingMulti))
        else
            print("  mountConfig: (nil)")
        end
    else
        print("  (nil)")
    end

    print("Current config (GetCurrentMountConfig):")
    local current = Config.GetCurrentMountConfig()
    if current then
        print("  ground: " .. tostring(current.ground))
        print("  flying: " .. tostring(current.flying))
        print("  groundMulti: " .. tostring(current.groundMulti))
        print("  flyingMulti: " .. tostring(current.flyingMulti))
    else
        print("  (nil)")
    end

    print("IsUsingCharacterSpecific: " .. tostring(Config.IsUsingCharacterSpecific()))
    print("GetMountMode: " .. tostring(Config.GetMountMode()))
    print("================================")
end

-- Export
_G.FluxSmartMountConfig = Config

