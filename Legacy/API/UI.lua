-- UI.lua — Edit Mode, micro menu, portrait, bags, tooltips, bank defer (modern clients only)
local addonName, ns = ...
local H = ns._FluxAPICompat
local _tonumber = H.tonumber
local _issecretvalue = H.issecretvalue

local isRetail = FLUX_API.isRetail
local isClassicEra = FLUX_API.isClassicEra
local isPreDF = FLUX_API.isPreDF
local isPostDF = FLUX_API.isPostDF
local majorVersion = FLUX_API.majorVersion
local isLegacyClient = FLUX_API.isLegacyClient
local hasModernAPIs = FLUX_API.hasModernAPIs
local hasEditMode = FLUX_API.hasEditMode
local FluxSafeRegisterEvent = H.FluxSafeRegisterEvent

local useTooltipMoneySafe = isRetail and isPostDF

-- ---------------------------------------------------------------------------
-- PowerBarColor ensure
-- ---------------------------------------------------------------------------
if not PowerBarColor or not PowerBarColor["MANA"] then
    PowerBarColor = PowerBarColor or {}
    PowerBarColor["MANA"] = { r = 0.00, g = 0.00, b = 1.00 }
    PowerBarColor["RAGE"] = { r = 1.00, g = 0.00, b = 0.00 }
    PowerBarColor["FOCUS"] = { r = 1.00, g = 0.50, b = 0.25 }
    PowerBarColor["ENERGY"] = { r = 1.00, g = 1.00, b = 0.00 }
    PowerBarColor["RUNIC_POWER"] = { r = 0.00, g = 0.82, b = 1.00 }
    PowerBarColor["RUNES"] = { r = 0.50, g = 0.50, b = 0.50 }
    PowerBarColor["SOUL_SHARDS"] = { r = 0.50, g = 0.32, b = 0.55 }
    PowerBarColor["LUNAR_POWER"] = { r = 0.30, g = 0.52, b = 0.90 }
    PowerBarColor["HOLY_POWER"] = { r = 0.95, g = 0.90, b = 0.60 }
    PowerBarColor["CHI"] = { r = 0.71, g = 1.00, b = 0.92 }
    PowerBarColor["ARCANE_CHARGES"] = { r = 0.10, g = 0.10, b = 0.98 }
    PowerBarColor["MAELSTROM"] = { r = 0.00, g = 0.50, b = 1.00 }
    PowerBarColor["INSANITY"] = { r = 0.40, g = 0.00, b = 0.80 }
    PowerBarColor["FURY"] = { r = 0.788, g = 0.259, b = 0.992 }
    PowerBarColor["PAIN"] = { r = 255/255, g = 156/255, b = 0 }
    PowerBarColor["COMBO_POINTS"] = { r = 1.00, g = 0.96, b = 0.41 }
    PowerBarColor["HAPPINESS"] = { r = 1.00, g = 0.41, b = 0.96 }
    PowerBarColor["AMMOSLOT"] = { r = 0.80, g = 0.60, b = 0.00 }
    PowerBarColor["FUEL"] = { r = 0.0, g = 0.55, b = 0.5 }
    PowerBarColor[0] = PowerBarColor["MANA"]
    PowerBarColor[1] = PowerBarColor["RAGE"]
    PowerBarColor[2] = PowerBarColor["FOCUS"]
    PowerBarColor[3] = PowerBarColor["ENERGY"]
    PowerBarColor[4] = PowerBarColor["CHI"] or PowerBarColor["HAPPINESS"]
    PowerBarColor[5] = PowerBarColor["RUNES"]
    PowerBarColor[6] = PowerBarColor["RUNIC_POWER"]
    PowerBarColor[7] = PowerBarColor["SOUL_SHARDS"]
    PowerBarColor[8] = PowerBarColor["LUNAR_POWER"]
    PowerBarColor[9] = PowerBarColor["HOLY_POWER"]
    PowerBarColor[11] = PowerBarColor["MAELSTROM"]
    PowerBarColor[13] = PowerBarColor["INSANITY"]
    PowerBarColor[17] = PowerBarColor["FURY"]
    PowerBarColor[18] = PowerBarColor["PAIN"]
end

-- ---------------------------------------------------------------------------
-- Container / item / spell helpers
-- ---------------------------------------------------------------------------
function FluxGetContainerItemID(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        return info and info.itemID or nil
    end
    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bag, slot)
    end
    if GetContainerItemID then return GetContainerItemID(bag, slot) end
    return nil
end

function FluxGetContainerItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        return info and info.hyperlink or nil
    end
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if GetContainerItemLink then return GetContainerItemLink(bag, slot) end
    return nil
end

function FluxGetItemCount(itemID, opts)
    itemID = _tonumber(itemID)
    if not itemID then return 0 end
    opts = opts or {}
    local includeBank = opts.includeBank == true
    local includeReagent = opts.includeReagent ~= false
    local includeCharges = opts.charges ~= false
    local inv = _G.FluxInv
    if inv then
        if includeCharges and inv.GetLiveCount then
            return inv.GetLiveCount(itemID, { includeBank = includeBank, bank = includeBank, charges = true }) or 0
        end
        if inv.GetCount then
            return inv.GetCount(itemID, { bags = true, bank = includeBank, warband = includeBank, charges = includeCharges }) or 0
        end
        if inv.Bags and inv.Bags.GetCount and not includeBank then
            return inv.Bags.GetCount(itemID) or 0
        end
    end
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, includeBank, includeCharges, includeReagent, includeBank) or 0
    end
    if GetItemCount then
        return GetItemCount(itemID, includeBank or nil, includeCharges, includeReagent) or 0
    end
    return 0
end

function FluxIsItemUsable(itemID)
    itemID = _tonumber(itemID)
    if not itemID then return false, false end
    if C_Item and C_Item.IsUsableItem then
        return C_Item.IsUsableItem(itemID)
    end
    if IsUsableItem then return IsUsableItem(itemID), false end
    return false, false
end

local function FluxTooltipSetItemFallback(tooltip, itemId)
    if not tooltip or not itemId or type(itemId) ~= "number" then return false end
    if PlayerHasToy and PlayerHasToy(itemId) and tooltip.SetToyByItemID then
        if pcall(tooltip.SetToyByItemID, tooltip, itemId) then return true end
    end
    if tooltip.SetItemByID then
        if pcall(tooltip.SetItemByID, tooltip, itemId) then return true end
    end
    if GetItemInfo then
        local _, link = GetItemInfo(itemId)
        if link and tooltip.SetHyperlink then
            if pcall(tooltip.SetHyperlink, tooltip, link) then return true end
        end
        local name = select(1, GetItemInfo(itemId))
        if name and name ~= "" and tooltip.SetText then
            return pcall(tooltip.SetText, tooltip, name, 1, 1, 1)
        end
    end
    return false
end

function FluxSafeTooltipSetBagItem(tooltip, bag, slot, itemId)
    if not tooltip or not tooltip.SetBagItem then return false end
    if not useTooltipMoneySafe then
        tooltip:SetBagItem(bag, slot)
        return true
    end
    if itemId and type(itemId) == "number" then
        if FluxTooltipSetItemFallback(tooltip, itemId) then return true end
    end
    local ok = pcall(function() tooltip:SetBagItem(bag, slot) end)
    if ok then return true end
    return FluxTooltipSetItemFallback(tooltip, itemId)
end

function FluxSafeTooltipSetInventoryItem(tooltip, unit, invSlot, itemId)
    if not tooltip or not tooltip.SetInventoryItem then return false end
    if not useTooltipMoneySafe then
        tooltip:SetInventoryItem(unit, invSlot)
        return true
    end
    if itemId and type(itemId) == "number" then
        if FluxTooltipSetItemFallback(tooltip, itemId) then return true end
    end
    local ok = pcall(function() tooltip:SetInventoryItem(unit, invSlot) end)
    if ok then return true end
    return FluxTooltipSetItemFallback(tooltip, itemId)
end

function FluxSafeGameTooltipShow(tooltip)
    if not tooltip or not tooltip.Show then return end
    if not useTooltipMoneySafe then tooltip:Show(); return end
    local ok = pcall(tooltip.Show, tooltip)
    if not ok then tooltip:Hide() end
end

function FluxSafeTooltipSetItemCombatMinimal(tooltip, itemId)
    if not tooltip or not itemId or type(itemId) ~= "number" or not tooltip.SetText then return false end
    local name = GetItemInfo and select(1, GetItemInfo(itemId))
    if not name or name == "" then return false end
    tooltip:SetText(name, 1, 1, 1)
    return true
end

function FluxSafeSetTooltipOwner(tooltip, owner, anchor)
    if not tooltip or not tooltip.SetOwner then return false end
    if not owner then return false end
    if FLUX_API and FLUX_API.isPostDF then
        if not owner.IsVisible or not owner:IsVisible() then return false end
    end
    tooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
    return true
end

function FluxFormatPortraitCombatNumber(amount)
    if amount == nil then return "" end
    if _issecretvalue and _issecretvalue(amount) then return amount end
    local n = tonumber(amount)
    if not n then return tostring(amount) end
    if n >= 10000 then
        if AbbreviateLargeNumbers then return AbbreviateLargeNumbers(n) end
        if AbbreviateNumbers then return AbbreviateNumbers(n) end
        if n >= 1000000000 then return string.format("%.1fb", n / 1000000000)
        elseif n >= 1000000 then return string.format("%.1fm", n / 1000000)
        elseif n >= 1000 then return string.format("%.1fk", n / 1000) end
        return tostring(n)
    end
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
    return tostring(n)
end
_G.FluxFormatPortraitCombatNumber = FluxFormatPortraitCombatNumber

-- ---------------------------------------------------------------------------
-- Mount collection openers
-- ---------------------------------------------------------------------------
local MOUNTS_TAB_INDEX = 1

function FluxOpenMountCollection()
    if not C_MountJournal then return false end
    if LoadAddOn then LoadAddOn("Blizzard_Collections") end
    if ToggleCollectionsJournal and type(ToggleCollectionsJournal) == "function" then
        pcall(ToggleCollectionsJournal, MOUNTS_TAB_INDEX)
        return true
    end
    return false
end

function FluxOpenCompanionMounts()
    if not (GetNumCompanions and type(GetNumCompanions) == "function") then return false end
    if LoadAddOn then LoadAddOn("Blizzard_PetJournal") end
    if TogglePetJournal and type(TogglePetJournal) == "function" then
        pcall(TogglePetJournal)
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Edit Mode helpers
-- ---------------------------------------------------------------------------
function FluxSecureUIPanelsBlockInsecureWork()
    local gm = _G.GameMenuFrame
    if gm then
        if gm.IsShown and gm:IsShown() then return true end
        if gm.IsVisible and gm:IsVisible() then return true end
    end
    local em = _G.EditModeManagerFrame
    if em then
        if em.IsShown and em:IsShown() then return true end
        if em.IsVisible and em:IsVisible() then return true end
        if em.IsEditModeActive then
            local ok, active = pcall(em.IsEditModeActive, em)
            if ok and active then return true end
        end
    end
    local vis = _G.StaticPopup_Visible
    if type(vis) == "function" then
        if vis("CAMP") or vis("QUIT") or vis("PLUNDERSTORM_LEAVE") then return true end
    end
    return false
end
FLUX_API.SecureUIPanelsBlockInsecureWork = FluxSecureUIPanelsBlockInsecureWork

function FluxRemoveFrameFromEditMode(frame)
    if not FLUX_API.hasEditMode or not frame then return false end
    -- C_EditMode has no RemoveFrame. Do not UnregisterSystem / write
    -- systemInfo.isInDefaultPosition: InitSystemAnchors reads that flag, and a
    -- Flux value taints the rest of the range → MainActionBar:SetPointBase on
    -- spec/level (PLAYER_SPECIALIZATION_CHANGED → UpdateLayoutInfo).
    frame.ignoreFramePositionManager = true
    return true
end

function FluxRemoveFramesFromEditMode(frameList)
    if not FLUX_API.hasEditMode or not frameList then return end
    for _, frame in ipairs(frameList) do FluxRemoveFrameFromEditMode(frame) end
end

-- Forever dings fire PLAYER_SPECIALIZATION_CHANGED (same event as a real spec
-- swap). EditModeManagerFrame OnEvent then UpdateLayoutInfo → InitSystemAnchors
-- → MainActionBar:SetPointBase, which is ADDON_ACTION_BLOCKED in combat when
-- any Flux touch has tainted that range. Flux owns HUD layout on every client
-- that ships Edit Mode (live, Forever, anniversary, era stub). Drop only that
-- unit event; never replace OnEvent / InitSystemAnchors (that taints worse).
local editModeSpecLayoutSilenced = false

function FluxSilenceEditModeSpecLayoutRefresh()
    if editModeSpecLayoutSilenced then
        return true
    end
    if not FLUX_API.hasEditMode then
        return false
    end
    local em = _G.EditModeManagerFrame
    if not em or type(em.UnregisterEvent) ~= "function" then
        return false
    end
    pcall(em.UnregisterEvent, em, "PLAYER_SPECIALIZATION_CHANGED")
    editModeSpecLayoutSilenced = true
    return true
end

-- Edit Mode reads Blizzard frame state on the same pass as its own TargetUnit /
-- ClearTarget and the party health-color compare. Flux must not move, show,
-- hide, or lay out Blizzard frames, or run Blizzard layout code, while Edit Mode
-- is open. The open pass runs with EditModeManagerFrame shown; the close pass
-- runs in OnHide, so EditMode.Enter / EditMode.Exit (fired at the end of each
-- pass) bracket the rest.
local editModeOpen = false
local afterEditMode = {}
local afterEditModeScheduled = false

function FluxEditModeBusy()
    if editModeOpen then
        return true
    end
    local em = _G.EditModeManagerFrame
    return (em and em.IsShown and em:IsShown()) and true or false
end
FLUX_API.EditModeBusy = FluxEditModeBusy

local function RunAfterEditMode()
    afterEditModeScheduled = false
    if FluxEditModeBusy() then
        return
    end
    local pending = afterEditMode
    afterEditMode = {}
    for _, fn in pairs(pending) do
        local ok, err = pcall(fn)
        if not ok and geterrorhandler then
            geterrorhandler()(err)
        end
    end
end

local function ScheduleAfterEditMode()
    if afterEditModeScheduled or not (C_Timer and C_Timer.After) then
        return
    end
    afterEditModeScheduled = true
    C_Timer.After(0, RunAfterEditMode)
end

--- Run fn on a later frame once Edit Mode is closed. Repeat calls with the same
--- key (default: fn itself) collapse into one run.
function FluxAfterEditMode(fn, key)
    if type(fn) ~= "function" then
        return
    end
    afterEditMode[key or fn] = fn
    if not FluxEditModeBusy() then
        ScheduleAfterEditMode()
    end
end
FLUX_API.AfterEditMode = FluxAfterEditMode

-- Flux owns these HUD systems. Their Edit Mode selection box and resize handle
-- go alpha 0 with no mouse, in place. Never Hide / ClearHighlight / hook
-- HighlightSystem / FCF_SetLocked: those run Blizzard code inside Edit Mode's
-- pass. Selection frames carry no scripts, so alpha and mouse are widget state.
local EDIT_MODE_HIDDEN_FRAME_NAMES = {
    "PlayerFrame",
    "PetFrame",
    "MainMenuBarVehicleLeaveButton",
    "MainStatusTrackingBarContainer",
    "SecondaryStatusTrackingBarContainer",
    "MicroMenuContainer",
    "BagsBar",
    "QueueStatusButton",
    "GameTooltipDefaultContainer",
    "ChatFrame1",
    "DurabilityFrame",
}

local function MuteEditModeChild(child)
    if not child then
        return
    end
    if child.SetAlpha then
        child:SetAlpha(0)
    end
    if child.EnableMouse then
        child:EnableMouse(false)
    end
end

local function SuppressOwnedEditModeChrome()
    if not FLUX_API.hasEditMode or (InCombatLockdown and InCombatLockdown()) then
        return
    end
    for i = 1, #EDIT_MODE_HIDDEN_FRAME_NAMES do
        local frame = _G[EDIT_MODE_HIDDEN_FRAME_NAMES[i]]
        if frame then
            MuteEditModeChild(frame.Selection)
            MuteEditModeChild(frame.EditModeResizeButton)
        end
    end
    local castBar = _G.PlayerCastingBarFrame or _G.CastingBarFrame
    if castBar then
        MuteEditModeChild(castBar.Selection)
    end
end

local editModeCallbacksInstalled = false

local function InstallEditModeCallbacks()
    if editModeCallbacksInstalled or not FLUX_API.hasEditMode then
        return editModeCallbacksInstalled
    end
    if not (EventRegistry and EventRegistry.RegisterCallback) then
        return false
    end
    EventRegistry:RegisterCallback("EditMode.Enter", function()
        editModeOpen = true
        if C_Timer and C_Timer.After then
            C_Timer.After(0, SuppressOwnedEditModeChrome)
        end
    end)
    EventRegistry:RegisterCallback("EditMode.Exit", function()
        editModeOpen = false
        ScheduleAfterEditMode()
    end)
    editModeCallbacksInstalled = true
    return true
end

local function WatchEditModeSpecLayoutSilence()
    local function ApplyEditModeGuards()
        FluxSilenceEditModeSpecLayoutRefresh()
        InstallEditModeCallbacks()
        SuppressOwnedEditModeChrome()
    end
    ApplyEditModeGuards()
    if EventUtil and EventUtil.ContinueOnAddOnLoaded then
        EventUtil.ContinueOnAddOnLoaded("Blizzard_EditMode", ApplyEditModeGuards)
        local hideAddons = {
            "Blizzard_UnitFrame",
            "Blizzard_ActionBar",
            "Blizzard_ChatFrame",
            "Blizzard_ChatFrameBase",
            "Blizzard_MicroMenu",
            "Blizzard_MainMenuBarBagButtons",
            "Blizzard_QueueStatusFrame",
            "Blizzard_GameTooltip",
            "Blizzard_UIPanels_Game",
            "Blizzard_StatusTrackingBar",
            "Blizzard_DurabilityFrame",
        }
        for i = 1, #hideAddons do
            EventUtil.ContinueOnAddOnLoaded(hideAddons[i], ApplyEditModeGuards)
        end
    end
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("ADDON_LOADED")
    watcher:RegisterEvent("PLAYER_LOGIN")
    watcher:SetScript("OnEvent", function(self)
        ApplyEditModeGuards()
        if editModeSpecLayoutSilenced and editModeCallbacksInstalled then
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, ApplyEditModeGuards)
        C_Timer.After(1, ApplyEditModeGuards)
    end
end

WatchEditModeSpecLayoutSilence()

-- ---------------------------------------------------------------------------
-- Micro menu helpers
-- ---------------------------------------------------------------------------
local function FluxIsBlizzardAddOnLoadable(addon)
    if type(addon) ~= "string" or addon == "" then return false end
    if C_AddOns and C_AddOns.IsAddOnLoadable then
        local ok, loadable = pcall(C_AddOns.IsAddOnLoadable, addon)
        if ok then
            if loadable == true or loadable == 1 then return true end
            if type(loadable) == "string" and loadable == "DEMAND_LOADED" then return true end
        end
    end
    if IsAddOnLoadable then
        local ok, loadable = pcall(IsAddOnLoadable, addon)
        if ok and (loadable == true or loadable == 1 or loadable == "DEMAND_LOADED") then return true end
    end
    return false
end

local function FluxClientHasAchievementMicroFeature()
    if AchievementFrame then return true end
    if FluxIsBlizzardAddOnLoadable("Blizzard_AchievementUI") then return true end
    if type(CanShowAchievementUI) == "function" then
        local ok, canShow = pcall(CanShowAchievementUI)
        if ok and canShow == true then return true end
    end
    return false
end

local function FluxClientHasRetailGroupFinderMicroFeature()
    return GroupFinderFrame ~= nil or ToggleGroupFinderFrame ~= nil
end

local function FluxClientIsForever()
    return FLUX_API.isCamelot or FLUX_API.isForever
end

--- Forever Camelot ships LFDMicroButton (ToggleGroupFinderFrame → Vanilla LFGParentFrame).
--- wow-ui-source-forever Blizzard_GroupFinder is ExcludeLoadGameType camelot, so LFDParentFrame
--- never exists there. Live still keys off LFDParentFrame so this does not change Midnight.
local function FluxClientHasLFDMicroFeature()
    if FluxClientIsForever() then
        return ToggleGroupFinderFrame ~= nil or LFGVanilla_ToggleFrame ~= nil
    end
    return LFDParentFrame ~= nil
end

--- Camelot's menu is Spellbook + Talent. Live retail never creates those frames;
--- its spellbook/talents control is PlayerSpellsMicroButton (TOGGLETALENTS).
local function FluxClientUsesSplitTalentSpellbookMicros()
    local function exists(name)
        local f = _G[name]
        return f and f.IsObjectType and f:IsObjectType("Frame") and true or false
    end
    return exists("TalentMicroButton") or exists("SpellbookMicroButton")
end

local OPTIONAL_MICRO_MENU_FEATURES = {
    -- Forever still creates the live combined frame. Hide it only when the split buttons exist.
    PlayerSpellsMicroButton = function()
        if FluxClientUsesSplitTalentSpellbookMicros() then return false end
        return true
    end,
    HousingMicroButton = function()
        if FluxClientIsForever() then return false end
        return true
    end,
    AchievementMicroButton = function()
        if FluxClientIsForever() then return false end
        return FluxClientHasAchievementMicroFeature()
    end,
    CollectionsMicroButton = function()
        if ToggleCollectionsJournal or CollectionsJournal then return true end
        if FLUX_API.hasToyBox or FLUX_API.hasToggleCollectionsJournal then return true end
        return FluxIsBlizzardAddOnLoadable("Blizzard_Collections")
    end,
    PVPMicroButton = function()
        if not PVPFrame then return false end
        return TogglePVPFrame ~= nil or TogglePVPUI ~= nil
    end,
    EJMicroButton = function()
        if EncounterJournal or ToggleEncounterJournal then return true end
        return FluxIsBlizzardAddOnLoadable("Blizzard_EncounterJournal")
    end,
    LFDMicroButton = FluxClientHasLFDMicroFeature,
    LFGMicroButton = FluxClientHasRetailGroupFinderMicroFeature,
    SearchLFGButton = FluxClientHasRetailGroupFinderMicroFeature,
}

function FLUX_API.ClientHasMicroMenuFeature(rowId)
    if type(rowId) ~= "string" or rowId == "" then return false end
    local checker = OPTIONAL_MICRO_MENU_FEATURES[rowId]
    if not checker then return true end
    local ok, result = pcall(checker)
    return ok and result == true
end

function FLUX_API.ClientHasMinimapGroupFinder()
    return _G.LFGMinimapFrame ~= nil or _G.LFGMinimapFrameIcon ~= nil
        or _G.QueueStatusMinimapButton ~= nil or _G.LFG_MinimapEye ~= nil
end

function FLUX_API.ClientHasBlizzardMicroGroupFinder()
    local lfdBtn = _G.LFDMicroButton
    if lfdBtn and lfdBtn.IsObjectType and lfdBtn:IsObjectType("Frame")
        and FLUX_API.ClientHasMicroMenuFeature("LFDMicroButton") then return true end
    local lfgBtn = _G.LFGMicroButton
    if lfgBtn and lfgBtn.IsObjectType and lfgBtn:IsObjectType("Frame")
        and FLUX_API.ClientHasMicroMenuFeature("LFGMicroButton") then return true end
    local searchBtn = _G.SearchLFGButton
    if searchBtn and searchBtn.IsObjectType and searchBtn:IsObjectType("Frame")
        and FLUX_API.ClientHasMicroMenuFeature("SearchLFGButton") then return true end
    return false
end

function FluxClientHasMicroMenuFeature(rowId) return FLUX_API.ClientHasMicroMenuFeature(rowId) end
function FluxClientHasMinimapGroupFinder() return FLUX_API.ClientHasMinimapGroupFinder() end
function FluxClientHasBlizzardMicroGroupFinder() return FLUX_API.ClientHasBlizzardMicroGroupFinder() end
ns.API.ClientHasMicroMenuFeature = FLUX_API.ClientHasMicroMenuFeature
ns.API.ClientHasMinimapGroupFinder = FLUX_API.ClientHasMinimapGroupFinder
ns.API.ClientHasBlizzardMicroGroupFinder = FLUX_API.ClientHasBlizzardMicroGroupFinder

function FluxGetStandardMicroButtonSize()
    if isRetail and isPostDF and FluxHasAtlas("UI-HUD-MicroMenu-ButtonBG-Up") then return 32, 40 end
    return 29, 37
end

function FluxStandardizeMicroButton(btn)
    if not btn then return 29, 37 end
    local stdWidth, stdHeight = FluxGetStandardMicroButtonSize()
    local currentWidth, currentHeight = btn:GetSize()
    if not currentWidth or currentWidth == 0 then currentWidth = stdWidth end
    if not currentHeight or currentHeight == 0 then currentHeight = stdHeight end
    if isRetail and isPostDF and FluxHasAtlas("UI-HUD-MicroMenu-ButtonBG-Up") then
        btn:SetSize(stdWidth, stdHeight)
        return stdWidth, stdHeight
    end
    return currentWidth or stdWidth, currentHeight or stdHeight
end

function FluxGetMicroButtonSpacing() return isRetail and -3 or -2 end

function FluxDetectMicroButtonTopGap(btn)
    if not btn then return 0 end
    local _l, _r, top = btn:GetHitRectInsets()
    if top and top > 0 then return top end
    return 0
end

function FluxGetMicroButtonTopGap()
    local refBtn = _G["CharacterMicroButton"] or _G["MainMenuMicroButton"]
    if refBtn then return FluxDetectMicroButtonTopGap(refBtn) end
    return 0
end

function FluxShouldApplyMicroButtonTopGapLayout()
    if not isRetail or not isPostDF then return false end
    return FluxHasAtlas("UI-HUD-MicroMenu-ButtonBG-Up")
end

function FluxShouldUseDfStyleVerticalMicroMenuGrid()
    if FluxShouldApplyMicroButtonTopGapLayout() then return true end
    if isPreDF and hasEditMode then return true end
    return false
end

function FluxGetMicroMenuLayoutTopGap()
    if not FluxShouldApplyMicroButtonTopGapLayout() then return 0 end
    return FluxGetMicroButtonTopGap()
end

function FluxGetMicroMenuLegacyBarHeightExtra() return 0 end

function FluxGetMicroButtonLayoutInfo()
    local stdWidth, stdHeight = FluxGetStandardMicroButtonSize()
    local spacing = FluxGetMicroButtonSpacing()
    local topGap = FluxGetMicroButtonTopGap()
    local nativeWidth, nativeHeight = 29, 37
    local refBtn = _G["CharacterMicroButton"]
    if refBtn then nativeWidth, nativeHeight = refBtn:GetSize() end
    return {
        standardWidth = stdWidth, standardHeight = stdHeight,
        nativeWidth = nativeWidth, nativeHeight = nativeHeight,
        spacing = spacing, topGap = topGap, majorVersion = majorVersion,
        isClassicEra = isClassicEra, isRetail = isRetail,
        isLegacyClient = isLegacyClient, hasModernAPIs = hasModernAPIs, hasEditMode = hasEditMode,
    }
end

function FluxPlayerCanUseTalentMicroButton()
    if isPostDF then return true end
    local level = UnitLevel("player") or 0
    if C_SpecializationInfo and C_SpecializationInfo.CanPlayerUseTalentSpecUI then
        local ok, can = pcall(C_SpecializationInfo.CanPlayerUseTalentSpecUI)
        if ok and type(can) == "boolean" then
            if can then return true end
            return level >= 10
        end
    end
    return level >= 10
end

local function FluxGetTalentMicroButtonDisabledTooltip()
    if C_SpecializationInfo and C_SpecializationInfo.CanPlayerUseTalentSpecUI then
        local ok, can, reason = pcall(C_SpecializationInfo.CanPlayerUseTalentSpecUI)
        if ok and can == false and type(reason) == "string" and reason ~= "" then return reason end
    end
    if type(_G.SPELL_FAILED_LOWLEVEL) == "string" and _G.SPELL_FAILED_LOWLEVEL ~= "" then return _G.SPELL_FAILED_LOWLEVEL end
    if type(_G.TALENTS) == "string" and _G.TALENTS ~= "" then return _G.TALENTS end
    return nil
end

function FluxUpdateTalentMicroButtonPreDF()
    if isPostDF then return end
    local btn = _G.TalentMicroButton
    if not btn or not btn.IsObjectType or not btn:IsObjectType("Button") then return end
    if InCombatLockdown() then return end
    local canUse = FluxPlayerCanUseTalentMicroButton()
    if canUse then
        btn.disabledTooltip = nil
        btn:Show()
        if not btn:IsEnabled() then btn:Enable() end
        if btn.SetAlpha then btn:SetAlpha(1) end
        if btn.GetNormalTexture then
            local nt = btn:GetNormalTexture()
            if nt and nt.SetAlpha then nt:SetAlpha(1) end
        end
        if btn.icon and btn.icon.SetDesaturated then btn.icon:SetDesaturated(false) end
    else
        btn:Show()
        btn.disabledTooltip = FluxGetTalentMicroButtonDisabledTooltip()
        btn:Disable()
        if btn.icon and btn.icon.SetDesaturated then btn.icon:SetDesaturated(true) end
        local layoutPos = 1
        if _G.FluxOptions and FluxOptions.GetMicroMenuLayoutPosition then
            local ok, p = pcall(function() return FluxOptions:GetMicroMenuLayoutPosition() end)
            if ok and type(p) == "number" then layoutPos = p end
        end
        if layoutPos ~= 2 and layoutPos ~= 3 then
            if _G.AchievementMicroButton then
                AchievementMicroButton:SetPoint("BOTTOMLEFT", btn, "BOTTOMRIGHT", -3, 0)
            elseif _G.QuestLogMicroButton then
                QuestLogMicroButton:SetPoint("BOTTOMLEFT", btn, "BOTTOMRIGHT", -3, 0)
            end
        end
    end
end

ns.API.PlayerCanUseTalentMicroButton = FluxPlayerCanUseTalentMicroButton
ns.API.UpdateTalentMicroButtonPreDF = FluxUpdateTalentMicroButtonPreDF
ns.API.ShouldUseDfStyleVerticalMicroMenuGrid = FluxShouldUseDfStyleVerticalMicroMenuGrid

-- ---------------------------------------------------------------------------
-- Portrait model setup
-- ---------------------------------------------------------------------------
function FluxSetupPortraitModel(model, unit)
    if not model then return false end
    local originalSetUnit = model.SetUnit

    local function resetCamera(self)
        if self.SetCamera then
            self:SetCamera(0)
            if self.SetModelScale then self:SetModelScale(1.0) end
            if self.SetPosition then self:SetPosition(0, 0, 0) end
            C_Timer.After(0.01, function()
                if self.SetCamera then self:SetCamera(0) end
            end)
        end
    end

    model:SetScript("OnShow", resetCamera)
    resetCamera(model)
    if model.SetModelScale then model:SetModelScale(1.0) end
    if model.SetPosition then model:SetPosition(0, 0, 0) end

    C_Timer.After(0.1, function()
        if originalSetUnit and unit then
            originalSetUnit(model, unit)
            if model.SetModelScale then model:SetModelScale(1.0) end
            if model.SetPosition then model:SetPosition(0, 0, 0) end
            if model.SetCamera then model:SetCamera(0) end
        end
    end)

    model.guid = nil
    model.intendedUnit = unit
    model.SetUnit = function(self, requestedUnit)
        if originalSetUnit and self.intendedUnit then
            originalSetUnit(self, self.intendedUnit)
        elseif originalSetUnit then
            originalSetUnit(self, requestedUnit)
        end
    end

    local originalOnEvent = model:GetScript("OnEvent")
    model:SetScript("OnEvent", function(self, event, arg1)
        -- originalOnEvent (CreatePortrait) owns UpdatePortrait / question-mark fallback
        if originalOnEvent then originalOnEvent(self, event, arg1) end
        if event == "UNIT_PORTRAIT_UPDATE" and arg1 == unit then
            local currentGUID = UnitGUID(unit)
            if self.guid ~= currentGUID then
                if originalSetUnit then
                    originalSetUnit(self, unit)
                    if self.SetCamera then self:SetCamera(0) end
                    if self.SetPortraitZoom then self:SetPortraitZoom(1.0) end
                    if self.SetCamDistanceScale then self:SetCamDistanceScale(1) end
                end
                self.guid = currentGUID
            end
        elseif event == "PORTRAITS_UPDATED" then
            self:SetUnit(unit)
        end
    end)

    FluxSafeRegisterEvent(model, "PORTRAITS_UPDATED")
    FluxSafeRegisterUnitEvent(model, "UNIT_MODEL_CHANGED", unit)
    FluxSafeRegisterUnitEvent(model, "UNIT_PORTRAIT_UPDATE", unit)
    return true
end

function FluxNeedsPortraitCompat()
    -- Forever uses FluxUnitFrames_Shared ApplyPortraitCamera (engine zoom).
    -- The pre-DF SetUnit wrap would overwrite OnShow and fight that head crop.
    if FLUX_API.isCamelot or FLUX_API.isForever then
        return false
    end
    return FLUX_API.isModernClient and FLUX_API.majorVersion < 10
end

FluxAPICompat.SetupPortraitModel = FluxSetupPortraitModel
FluxAPICompat.NeedsPortraitCompat = FluxNeedsPortraitCompat
ns.API.SetupPortraitModel = FluxSetupPortraitModel
ns.API.NeedsPortraitCompat = FluxNeedsPortraitCompat

-- ---------------------------------------------------------------------------
-- Atlas / legacy border
-- ---------------------------------------------------------------------------
function ns.API.SafeSetAtlas(texture, atlasName, useAtlasSize)
    if not texture or not atlasName then return false end
    if texture.SetAtlas then
        local success = pcall(function() texture:SetAtlas(atlasName, useAtlasSize) end)
        if success then
            if C_Texture and C_Texture.GetAtlasInfo then
                local ok, info = pcall(function() return C_Texture.GetAtlasInfo(atlasName) end)
                if ok and info ~= nil then return true end
                return false
            elseif GetAtlasInfo then
                local ok, info = pcall(function() return GetAtlasInfo(atlasName) end)
                if ok and info ~= nil then return true end
                return false
            end
            return true
        end
    end
    return false
end
SafeSetAtlas = ns.API.SafeSetAtlas

local LEGACY_BORDER_COORDS = {
    TL = { left = 0.824, right = 0.887, top = 0.004, bottom = 0.070, width = 16, height = 17 },
    TR = { left = 0.895, right = 0.957, top = 0.004, bottom = 0.070, width = 16, height = 17 },
    BL = { left = 0.824, right = 0.887, top = 0.078, bottom = 0.141, width = 16, height = 16 },
    BR = { left = 0.895, right = 0.957, top = 0.078, bottom = 0.141, width = 16, height = 16 },
    Top = { left = 0.004, right = 0.816, top = 0.004, bottom = 0.070, width = 208, height = 17 },
    Bottom = { left = 0.004, right = 0.816, top = 0.078, bottom = 0.141, width = 208, height = 16 },
    Left = { left = 0.004, right = 0.066, top = 0.148, bottom = 0.672, width = 16, height = 134 },
    Right = { left = 0.074, right = 0.137, top = 0.148, bottom = 0.672, width = 16, height = 134 },
}

function CreateLegacyBattlefieldBorderPiece(parent, layer, useAtlasSize, pieceType)
    if not parent then return nil end
    local texture = parent:CreateTexture(nil, layer or "ARTWORK")
    if not texture then return nil end
    texture:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga")
    local coords = LEGACY_BORDER_COORDS[pieceType]
    if coords then
        texture:SetTexCoord(coords.left, coords.right, coords.top, coords.bottom)
        if useAtlasSize then texture:SetSize(coords.width, coords.height) end
    end
    return texture
end

-- ---------------------------------------------------------------------------
-- Alternative bag UI detection + InterfaceOptions polyfill
-- ---------------------------------------------------------------------------
function FluxUI_UsesAlternativeBagUI()
    if _G.Bagnon or _G.Bagnonium then return true end
    if IsAddOnLoaded and IsAddOnLoaded("Baganator") then return true end
    return _G.Baganator and _G.Baganator.API ~= nil
end
_G.FluxUI_UsesAlternativeBagUI = FluxUI_UsesAlternativeBagUI
FluxAPICompat.UsesAlternativeBagUI = FluxUI_UsesAlternativeBagUI

-- Explicit helper for Classic / pre-Settings clients. Do NOT assign this to
-- _G.InterfaceOptions_AddCategory on retail: a Flux-owned global that calls
-- Settings.Register* captures _FluxUI taint into SettingsInbound closures when
-- Blizzard_SettingsDefinitions_Frame loads, poisoning nameplate preview
-- SimulateCast / CastingBarTypeInfo forever.
function FluxRegisterSettingsCategory(frame, name)
    if not frame then
        return nil
    end
    name = name or frame.name or "Unknown"
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return nil
    end
    -- Post-DF retail: never register into Blizzard Settings from addon code.
    if FLUX_API and FLUX_API.isRetail and FLUX_API.isPostDF then
        return nil
    end
    local category = Settings.RegisterCanvasLayoutCategory(frame, name)
    Settings.RegisterAddOnCategory(category)
    frame._fluxSettingsCategoryID = category:GetID()
    return category
end
_G.FluxRegisterSettingsCategory = FluxRegisterSettingsCategory

if not InterfaceOptions_AddCategory then
    -- Post-DF retail: do not assign _G.InterfaceOptions_AddCategory at all (even a no-op
    -- Flux global can interfere with Blizzard's later Settings shim / taint capture).
    if not (FLUX_API and FLUX_API.isRetail and FLUX_API.isPostDF) then
        if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
            InterfaceOptions_AddCategory = function(frame, _addOn, _position)
                FluxRegisterSettingsCategory(frame, frame and frame.name)
            end
        else
            InterfaceOptions_AddCategory = function() end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Mana cache
-- ---------------------------------------------------------------------------
local cachedHasMana = nil

local function CheckPlayerHasMana()
    if not UnitPowerMax then return false end
    local maxMana = UnitPowerMax("player", 0) or 0
    if maxMana > 0 then return true end
    if Enum and Enum.PowerType and Enum.PowerType.Mana then
        if (UnitPowerMax("player", Enum.PowerType.Mana) or 0) > 0 then return true end
    end
    return false
end

function FluxAPICompat.GetPlayerHasMana()
    if cachedHasMana == true then return true end
    local has = CheckPlayerHasMana()
    if has then cachedHasMana = true; return true end
    cachedHasMana = nil
    return false
end

function FluxAPICompat.ResetManaCache() cachedHasMana = nil end

local function NotifyManaConsumableButtons()
    for _, mod in ipairs({ _G.FluxCombatManaPotion, _G.FluxCombatManaGem, _G.FluxNCWater }) do
        if mod and mod.Update then pcall(mod.Update) end
    end
end

local function ScheduleManaCacheWarm()
    for _, d in ipairs({ 0, 0.5, 1.5, 3.0 }) do
        FluxAPICompat.After(d, function()
            local before = cachedHasMana
            FluxAPICompat.ResetManaCache()
            if FluxAPICompat.GetPlayerHasMana() and before ~= true then NotifyManaConsumableButtons() end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Bank open / transfer defer
-- ---------------------------------------------------------------------------
local bankOpenWorkGen = 0
local bankTransferWorkGen = 0
local unifiedBankPaintReady = true
local BANK_OPEN_HEAVY_DELAY = 0.2

local function IsBankFrameVisible()
    local fluxBank = _G.FluxBank
    if fluxBank and fluxBank.IsOpen and fluxBank.IsOpen() then return true end
    local bank = _G.BankFrame
    return bank and bank.IsShown and bank:IsShown()
end

function FluxAPICompat.CancelBankOpenWork()
    bankOpenWorkGen = bankOpenWorkGen + 1
    unifiedBankPaintReady = true
    bankTransferWorkGen = bankTransferWorkGen + 1
end
function FluxCancelBankOpenWork() FluxAPICompat.CancelBankOpenWork() end

function FluxAPICompat.DeferBankOpenWork(fn)
    if type(fn) ~= "function" then return end
    if not (FLUX_API and FLUX_API.HasUnifiedBankUI and FLUX_API.HasUnifiedBankUI()) then fn(); return end
    unifiedBankPaintReady = false
    bankOpenWorkGen = bankOpenWorkGen + 1
    local gen = bankOpenWorkGen
    FluxAPICompat.After(0, function()
        if gen ~= bankOpenWorkGen then return end
        FluxAPICompat.After(BANK_OPEN_HEAVY_DELAY, function()
            if gen ~= bankOpenWorkGen or not IsBankFrameVisible() then return end
            unifiedBankPaintReady = true
            fn()
        end)
    end)
end
function FluxDeferBankOpenWork(fn) FluxAPICompat.DeferBankOpenWork(fn) end

function FluxAPICompat.IsUnifiedBankPaintReady()
    if not (FLUX_API and FLUX_API.HasUnifiedBankUI and FLUX_API.HasUnifiedBankUI()) then return true end
    return unifiedBankPaintReady
end
function FluxIsUnifiedBankPaintReady() return FluxAPICompat.IsUnifiedBankPaintReady() end

FLUX_API.DeferBankOpenWork = FluxAPICompat.DeferBankOpenWork
FLUX_API.CancelBankOpenWork = FluxAPICompat.CancelBankOpenWork
FLUX_API.IsUnifiedBankPaintReady = FluxAPICompat.IsUnifiedBankPaintReady
ns.API.DeferBankOpenWork = FluxAPICompat.DeferBankOpenWork
ns.API.CancelBankOpenWork = FluxAPICompat.CancelBankOpenWork
ns.API.IsUnifiedBankPaintReady = FluxAPICompat.IsUnifiedBankPaintReady

function FluxAPICompat.DeferBankTransferWork(fn)
    if type(fn) ~= "function" then return end
    if not (FLUX_API and FLUX_API.HasUnifiedBankUI and FLUX_API.HasUnifiedBankUI()) then fn(); return end
    bankTransferWorkGen = bankTransferWorkGen + 1
    local gen = bankTransferWorkGen
    FluxAPICompat.After(0.05, function()
        if gen ~= bankTransferWorkGen then return end
        fn()
    end)
end
function FluxDeferBankTransferWork(fn) FluxAPICompat.DeferBankTransferWork(fn) end
FLUX_API.DeferBankTransferWork = FluxAPICompat.DeferBankTransferWork
ns.API.DeferBankTransferWork = FluxAPICompat.DeferBankTransferWork

-- ---------------------------------------------------------------------------
-- Dual talent / spec flyout APIs
-- ---------------------------------------------------------------------------
function ns.API.GetNumPlayerTalentGroups()
    if GetNumSpecGroups then
        local ok, n = pcall(GetNumSpecGroups, false)
        if ok and type(n) == "number" and n >= 1 then return n end
    end
    if GetNumTalentGroups then
        local ok, n = pcall(GetNumTalentGroups, false, false)
        if ok and type(n) == "number" and n >= 1 then return n end
    end
    return 1
end

function ns.API.GetActivePlayerTalentGroup()
    if C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup then
        local ok, g = pcall(C_SpecializationInfo.GetActiveSpecGroup, false, false)
        if ok and type(g) == "number" and g >= 1 then return g end
    end
    if GetActiveTalentGroup then
        local ok, g = pcall(GetActiveTalentGroup, false, false)
        if ok and type(g) == "number" and g >= 1 then return g end
    end
    return 1
end

function ns.API.SetActivePlayerTalentGroup(groupIndex)
    if type(groupIndex) ~= "number" or groupIndex < 1 then return false end
    if C_SpecializationInfo and C_SpecializationInfo.SetActiveSpecGroup then
        local ok, ret = pcall(C_SpecializationInfo.SetActiveSpecGroup, groupIndex)
        return ok and ret ~= false
    end
    if SetActiveTalentGroup then return pcall(SetActiveTalentGroup, groupIndex) end
    return false
end

function ns.API.TogglePlayerDualTalentGroup()
    local n = ns.API.GetNumPlayerTalentGroups()
    if n < 2 then return false end
    local active = ns.API.GetActivePlayerTalentGroup()
    local target = (active == 1) and 2 or 1
    if target > n then target = 1 end
    return ns.API.SetActivePlayerTalentGroup(target)
end

function ns.API.GetPlayerSpecFlyoutEntries()
    local entries = {}
    if not GetNumSpecializations then return entries end
    local okNum, numSpecs = pcall(GetNumSpecializations, false, false)
    if not okNum or type(numSpecs) ~= "number" or numSpecs < 2 then return entries end
    local currentIdx = nil
    if GetSpecialization then
        local okCur, idx = pcall(GetSpecialization)
        if okCur and type(idx) == "number" and idx >= 1 then currentIdx = idx end
    end
    local sex = UnitSex and UnitSex("player") or 2
    for i = 1, numSpecs do
        if not currentIdx or i ~= currentIdx then
            local ok, specId, name, _desc, icon = pcall(GetSpecializationInfo, i, false, false, nil, sex)
            if ok and type(name) == "string" and name ~= "" and icon then
                entries[#entries + 1] = { index = i, name = name, icon = icon, specId = specId }
            end
        end
    end
    return entries
end

function ns.API.GetPlayerSpecFlyoutEntriesIncludingActive()
    local entries = {}
    if not GetNumSpecializations then return entries end
    local okNum, numSpecs = pcall(GetNumSpecializations, false, false)
    if not okNum or type(numSpecs) ~= "number" or numSpecs < 1 then return entries end
    local sex = UnitSex and UnitSex("player") or 2
    for i = 1, numSpecs do
        local ok, specId, name, _desc, icon = pcall(GetSpecializationInfo, i, false, false, nil, sex)
        if ok and type(name) == "string" and name ~= "" and icon then
            entries[#entries + 1] = { index = i, name = name, icon = icon, specId = specId }
        end
    end
    return entries
end

function ns.API.TrySetPlayerSpecialization(specIndex)
    if type(specIndex) ~= "number" or specIndex < 1 then return false end
    if C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
        local ok, success = pcall(C_SpecializationInfo.SetSpecialization, specIndex)
        return ok and success == true
    end
    return false
end

function ns.API.CanPlayerUseTalentSpecUI()
    if C_SpecializationInfo and C_SpecializationInfo.CanPlayerUseTalentSpecUI then
        local ok, can = pcall(C_SpecializationInfo.CanPlayerUseTalentSpecUI)
        return ok and can == true
    end
    return false
end

function ns.API.GetPlayerSpecSwitchMode()
    if ns.API.GetNumPlayerTalentGroups() >= 2 then return "dual" end
    if not ns.API.CanPlayerUseTalentSpecUI() then return "none" end
    if not (C_SpecializationInfo and C_SpecializationInfo.SetSpecialization) then return "none" end
    local entries = ns.API.GetPlayerSpecFlyoutEntries()
    if entries and #entries >= 1 then return "flyout" end
    return "none"
end

function ns.API.HasPlayerTransmogOutfitAPI()
    return isRetail and C_TransmogOutfitInfo ~= nil
        and type(C_TransmogOutfitInfo.GetOutfitsInfo) == "function"
        and type(C_TransmogOutfitInfo.ChangeToOutfit) == "function"
end

function ns.API.GetPlayerTransmogOutfitEntries()
    local out = {}
    if not ns.API.HasPlayerTransmogOutfitAPI() then return out end
    local okList, outfits = pcall(C_TransmogOutfitInfo.GetOutfitsInfo)
    if not okList or type(outfits) ~= "table" then return out end
    local activeID = nil
    if type(C_TransmogOutfitInfo.GetActiveOutfitID) == "function" then
        local okActive, id = pcall(C_TransmogOutfitInfo.GetActiveOutfitID)
        if okActive and type(id) == "number" and id > 0 then activeID = id end
    end
    local function addEntry(info, fallbackIndex)
        if type(info) ~= "table" then
            return
        end
        local name = info.name
        if type(name) ~= "string" then
            name = name ~= nil and tostring(name) or ""
        end
        local id = tonumber(info.outfitID or info.outfitId)
        local idx = tonumber(info.playerFacingOutfitIndex or info.outfitIndex or info.index or fallbackIndex)
        if name == "" or idx == nil then
            return
        end
        if not id then
            id = idx
        end
        out[#out + 1] = {
            id = id, index = idx, name = name, icon = info.icon,
            isActive = (activeID ~= nil and activeID == id) or false,
            isDisabled = info.isDisabled == true,
        }
    end
    local n = 0
    for i, info in ipairs(outfits) do
        n = n + 1
        addEntry(info, i)
    end
    if n == 0 then
        for k, info in pairs(outfits) do
            addEntry(info, tonumber(k))
        end
    end
    table.sort(out, function(a, b)
        if a.index == b.index then return a.name < b.name end
        return a.index < b.index
    end)
    return out
end

function ns.API.TryApplyPlayerTransmogOutfit(playerFacingOutfitIndex)
    if type(playerFacingOutfitIndex) ~= "number" or playerFacingOutfitIndex < 1 then return false end
    if not ns.API.HasPlayerTransmogOutfitAPI() then return false end
    if ns.API.isV12 then return false end
    local ok, ret = pcall(C_TransmogOutfitInfo.ChangeToOutfit, playerFacingOutfitIndex, false)
    return ok and ret ~= false
end

function ns.API.TryPickupPlayerTransmogOutfit(outfitID)
    if type(outfitID) ~= "number" or not ns.API.HasPlayerTransmogOutfitAPI() then return false end
    if InCombatLockdown() then return false end
    if type(C_TransmogOutfitInfo.PickupOutfit) ~= "function" then return false end
    return pcall(C_TransmogOutfitInfo.PickupOutfit, outfitID) == true
end

-- ---------------------------------------------------------------------------
-- Details! identity helpers
-- ---------------------------------------------------------------------------
function FluxIsDetailsActorLocalPlayer(actor)
    if type(actor) ~= "table" then return false end
    local serial = actor.serial
    if serial ~= nil and UnitGUID then
        local pguid = UnitGUID("player")
        if pguid then
            local ok, matched = pcall(function()
                return type(serial) == "string" and serial ~= "" and serial == pguid
            end)
            if ok and matched then return true end
        end
    end
    local nome = actor.nome
    if nome == nil then return false end
    if not ns.API.CanAccessValue(nome) or ns.API.IsSecretValue(nome) then return false end
    if type(nome) ~= "string" or nome == "" then return false end
    local D = _G.Details
    if D and type(D.playername) == "string" and D.playername ~= "" and nome == D.playername then return true end
    return false
end
FLUX_API.IsDetailsActorLocalPlayer = FluxIsDetailsActorLocalPlayer

function FluxIsDetailsMeterSourceLocalPlayer(source)
    if type(source) ~= "table" then return false end
    local pg = UnitGUID and UnitGUID("player")
    local sguid = source.sourceGUID
    if type(pg) == "string" and pg ~= "" and sguid ~= nil then
        local cmp = ns.API.SafeCompare(sguid, pg, "==")
        if cmp == true then return true end
        if cmp == false then return false end
    end
    return source.isLocalPlayer == true or source.isLocalPlayer == 1
end
FLUX_API.IsDetailsMeterSourceLocalPlayer = FluxIsDetailsMeterSourceLocalPlayer

-- ---------------------------------------------------------------------------
-- Login / mana cache events
-- ---------------------------------------------------------------------------
local manaCacheFrame = CreateFrame("Frame")
manaCacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
manaCacheFrame:RegisterEvent("PLAYER_LOGIN")
manaCacheFrame:RegisterEvent("ADDON_LOADED")
manaCacheFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
manaCacheFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
manaCacheFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
pcall(function() manaCacheFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player") end)
manaCacheFrame:SetScript("OnEvent", function(_self, event, loadedAddon)
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and loadedAddon == "Blizzard_UIPanels_Game") then
        H.RefreshUnifiedBankUIFlags()
    end
    if event == "PLAYER_ENTERING_WORLD" then
        FluxAPICompat.ResetManaCache()
        ScheduleManaCacheWarm()
        if FLUX_API and FLUX_API.RefreshKeyringContainerState then FLUX_API.RefreshKeyringContainerState() end
    elseif event == "UNIT_MAXPOWER" then
        local before = cachedHasMana
        FluxAPICompat.ResetManaCache()
        if FluxAPICompat.GetPlayerHasMana() and before ~= true then NotifyManaConsumableButtons() end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        FluxAPICompat.ResetManaCache()
        ScheduleManaCacheWarm()
    end
end)

FLUX_API.hasPlayerMana = FluxAPICompat.GetPlayerHasMana


