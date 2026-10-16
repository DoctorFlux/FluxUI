-- FluxBagMicroButton.lua
if not FluxMicroMenu or not FluxMicroMenu.CreateMicroButton then return end

-- Compatibility helpers
local function GetContainerItemInfo_Compat(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        return C_Container.GetContainerItemInfo(bag, slot)
    elseif _G.GetContainerItemInfo then
        return _G.GetContainerItemInfo(bag, slot)
    end
    return nil
end

local function Inv()
    return _G.FluxInv
end

--- Prefer FluxInv (handles carried-bag IDs + backpack-full under-count). Local fallback.
local function GetFreeSlotsSafe(bag)
    local inv = Inv()
    if inv and inv.CountFreeSlotsInBag then
        return inv.CountFreeSlotsInBag(bag) or 0
    end
    if C_Container and C_Container.GetContainerNumFreeSlots then
        return C_Container.GetContainerNumFreeSlots(bag) or 0
    elseif GetContainerNumFreeSlots then
        return GetContainerNumFreeSlots(bag) or 0
    elseif GetContainerNumSlots then
        local slots = GetContainerNumSlots(bag) or 0
        local used = 0
        for i = 1, slots do
            if GetContainerItemInfo_Compat(bag, i) then used = used + 1 end
        end
        return slots - used
    end
    return 0
end

local function GetCarriedBagIDs()
    local inv = Inv()
    if inv and inv.GetCarriedBagIDs then
        return inv.GetCarriedBagIDs()
    end
    local ids = { _G.BACKPACK_CONTAINER or 0 }
    local numBags = _G.NUM_BAG_SLOTS or 4
    for i = 1, numBags do
        ids[#ids + 1] = i
    end
    if (_G.NUM_REAGENTBAG_SLOTS or 0) > 0 then
        local reagent = _G.REAGENTBAG_CONTAINER
            or (Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag)
            or 5
        ids[#ids + 1] = reagent
    end
    return ids
end

local function GetTotalFreeBagSlots()
    -- Use the same count as Blizzard's bag window/header. The inventory total
    -- includes reagent storage, which cannot hold ordinary backpack items.
    if C_Container and C_Container.CalculateTotalNumberOfFreeBagSlots then
        return C_Container.CalculateTotalNumberOfFreeBagSlots() or 0
    end
    local keyring = _G.KEYRING_CONTAINER or (Enum and Enum.BagIndex and Enum.BagIndex.Keyring) or -2
    local reagent = _G.REAGENTBAG_CONTAINER or (Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag) or 5
    local total = 0
    for _, bag in ipairs(GetCarriedBagIDs()) do
        if bag ~= keyring and bag ~= reagent then
            total = total + GetFreeSlotsSafe(bag)
        end
    end
    return total
end

local function GetBagName_Compat(bagID)
    if C_Container and C_Container.GetBagName then
        return C_Container.GetBagName(bagID) or ""
    elseif GetBagName then
        return GetBagName(bagID) or ""
    end
    return ""
end

local function GetContainerNumSlots_Compat(bagID)
    local inv = Inv()
    if inv and inv.GetContainerNumSlots then
        return inv.GetContainerNumSlots(bagID) or 0
    end
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bagID) or 0
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bagID) or 0
    end
    return 0
end

-- Rarity Coloring Helpers
local function GetBagQualityColor(bagID)
    if bagID == 0 then return 1, 1, 1 end
    local invID
    if C_Container and C_Container.ContainerIDToInventoryID then
        invID = C_Container.ContainerIDToInventoryID(bagID)
    elseif ContainerIDToInventoryID then
        invID = ContainerIDToInventoryID(bagID)
    end
    if invID then
        local quality
        if GetInventoryItemQuality then
            quality = GetInventoryItemQuality("player", invID)
        end
        -- Retail exposes this under C_Item; older clients keep the global.
        local getQualityColor = C_Item and C_Item.GetItemQualityColor or GetItemQualityColor
        if quality ~= nil and getQualityColor then
            local r, g, b = getQualityColor(quality)
            if r and g and b then return r, g, b end
        end
    end
    return 1, 1, 1
end

-- ---------------------------------------------------------------------------
-- FluxBagSlotsWindow (The separate window for bag slots)
-- ---------------------------------------------------------------------------
local bagSlotsWindow = CreateFrame("Frame", "FluxBagSlotsWindow", UIParent, BackDropTemplateMixin and "BackdropTemplate" or nil)
bagSlotsWindow:SetFrameStrata("HIGH")
bagSlotsWindow:SetFrameLevel(100)
bagSlotsWindow:SetSize(200, 45)
bagSlotsWindow:EnableMouse(true)
bagSlotsWindow:Hide()

if bagSlotsWindow.SetBackdrop then
    bagSlotsWindow:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    bagSlotsWindow:SetBackdropColor(0, 0, 0, 0.8)
    bagSlotsWindow:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
end

local function CursorHasBagEquipItem()
    if GetCursorInfo then
        local cursorType = GetCursorInfo()
        if cursorType == "item" then
            return true
        end
    end
    if CursorHasItem and CursorHasItem() then
        return true
    end
    return false
end

-- Close on movement, but not while placing/equipping a bag (cursor holds an item).
bagSlotsWindow:RegisterEvent("PLAYER_STARTED_MOVING")
bagSlotsWindow:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_STARTED_MOVING" and not CursorHasBagEquipItem() then
        self:Hide()
    end
end)

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

-- Live, Forever, Era, and Anniversary draw bag slots inside the bag. The
-- detached equip popup would steal those same buttons back out.
local function BagSlotsLiveInBag()
    if _G.FluxUI_UsesAlternativeBagUI and _G.FluxUI_UsesAlternativeBagUI() then
        return false
    end
    local client = _G.Flux and _G.Flux.Client
    if not client then
        return false
    end
    if client.isEra or client.isAnniversary then
        return true
    end
    if client.isClassic then
        return false
    end
    return client.isMidnight or client.isCamelot or client.isRetail
end

local function SlotHostedInBag(frame)
    return frame and frame.FluxBagSlotHosted
end

local SetupBagSlots -- forward decl (hooks call it)

local function CollectBagSlotButtons()
    local slots = {}
    local numSlots = NUM_BAG_SLOTS or 4

    if _G["KeyRingButton"] then
        slots[#slots + 1] = _G["KeyRingButton"]
    end

    for i = 0, (numSlots - 1) do
        local slot = _G["CharacterBag" .. i .. "Slot"]
        if slot then
            slots[#slots + 1] = slot
        end
    end

    if CharacterReagentBag0Slot then
        slots[#slots + 1] = CharacterReagentBag0Slot
    end

    return slots
end

-- BagsBar is an Edit Mode system. Hide / SetParent / EnableMouse on THAT frame
-- taint InitSystemAnchors → MainActionBar:SetPointBase on spec and level.
-- The slot buttons are not the system frame. Detach those so they are not an
-- invisible click target sitting on the HUD.
local bagChromeLoadWatcher

local function GetBagChromeHiddenParent()
    local parent = _G.FluxHiddenParent
    if not parent then
        parent = CreateFrame("Frame", "FluxHiddenParent", UIParent)
        parent:Hide()
    end
    return parent
end

local function IsEquipPopupChild(frame)
    return bagSlotsWindow and frame and frame.GetParent and frame:GetParent() == bagSlotsWindow
end

local function IsBagsBarSelection(frame)
    local bar = _G.BagsBar
    return bar and frame and frame == bar.Selection
end

local function ParkBagChromeFrame(frame)
    if not frame or frame == _G.BagsBar or IsBagsBarSelection(frame) or IsEquipPopupChild(frame) or SlotHostedInBag(frame) then
        return
    end
    local hidden = GetBagChromeHiddenParent()
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
    if frame.SetParent and frame:GetParent() ~= hidden then
        pcall(frame.SetParent, frame, hidden)
    end
    if frame.ClearAllPoints then
        frame:ClearAllPoints()
    end
    if frame.Hide then
        frame:Hide()
    end
    if frame.HookScript and not frame.FluxBagChromeParked then
        frame.FluxBagChromeParked = true
        frame:HookScript("OnShow", function(self)
            if IsEquipPopupChild(self) or SlotHostedInBag(self) then
                return
            end
            if self.EnableMouse then
                self:EnableMouse(false)
            end
            self:Hide()
        end)
    end
end

local BAG_CHROME_NAMES = {
    "MainMenuBarBackpackButton",
    "BagBarExpandToggle",
    "CharacterBag0Slot",
    "CharacterBag1Slot",
    "CharacterBag2Slot",
    "CharacterBag3Slot",
    "CharacterReagentBag0Slot",
    "KeyRingButton",
    "BagSlotCluster",
}

local function ParkBagsBarDescendants(frame)
    if not frame or not frame.GetChildren or IsBagsBarSelection(frame) then
        return
    end
    local kids = { frame:GetChildren() }
    for i = 1, #kids do
        local kid = kids[i]
        if kid and not IsBagsBarSelection(kid) and not IsEquipPopupChild(kid) then
            local objType = kid.GetObjectType and kid:GetObjectType()
            if objType == "Frame" then
                ParkBagsBarDescendants(kid)
            end
            ParkBagChromeFrame(kid)
        end
    end
end

local function ParkBlizzardBagChrome()
    ParkBagsBarDescendants(_G.BagsBar)
    for i = 1, #BAG_CHROME_NAMES do
        ParkBagChromeFrame(_G[BAG_CHROME_NAMES[i]])
    end
    local manager = _G.MainMenuBarBagManager
    if manager and manager.EnumerateBagButtons then
        for _, button in manager:EnumerateBagButtons() do
            ParkBagChromeFrame(button)
        end
    end
end

-- The system frame has to keep existing for Edit Mode. Collapse it to a 1px
-- shell with no slot children so it is not a bag bar on the HUD.
local function CollapseBagsBarShell()
    local bar = _G.BagsBar
    if not bar then
        return
    end
    if bar.UnregisterAllEvents and not bar.FluxBagEventsCleared then
        bar.FluxBagEventsCleared = true
        bar:UnregisterAllEvents()
    end
    if bar.SetAlpha then
        bar:SetAlpha(0)
    end
    if bar.BorderArt and bar.BorderArt.Hide then
        bar.BorderArt:Hide()
    end
    if bar.SetSize then
        bar:SetSize(1, 1)
    end
end

-- Retail BagsBar collapses CharacterBagNSlot via SetBarExpanded(false) when the
-- cursor clears (CURSOR_CHANGED → expandBagBarAuto). Keep claimed slots shown
-- while the equip popup is open, and put them back in the hidden parent when it is not.
local function KeepSlotShownIfPopupOpen(self)
    if SlotHostedInBag(self) then
        self:Show()
        if self.EnableMouse then
            self:EnableMouse(true)
        end
        return
    end
    if bagSlotsWindow:IsShown() and self:GetParent() == bagSlotsWindow then
        self:Show()
        if self.EnableMouse then
            self:EnableMouse(true)
        end
        return
    end
    if not bagSlotsWindow:IsShown() then
        ParkBagChromeFrame(self)
    end
end

local function HookBagSlotExpandGuard(slot)
    if not slot or slot.FluxKeepShownHooked then
        return
    end
    slot.FluxKeepShownHooked = true
    if slot.SetBarExpanded then
        hooksecurefunc(slot, "SetBarExpanded", KeepSlotShownIfPopupOpen)
    end
end

local function ReclaimBagSlotsIfPopupOpen()
    if bagSlotsWindow:IsShown() then
        SetupBagSlots()
    end
end

-- Main Setup Function (Unified Logic - Using Classic Style for Consistency)
SetupBagSlots = function()
    local slots = CollectBagSlotButtons()

    local SPACING = 4
    local SCALE = 1.0
    local prev = nil

    for i, slot in ipairs(slots) do
        HookBagSlotExpandGuard(slot)

        if slot:GetParent() ~= bagSlotsWindow then
            slot:SetParent(bagSlotsWindow)
        end
        slot:ClearAllPoints()
        slot:SetScale(SCALE)
        slot:Show()
        slot:SetAlpha(1)
        slot:EnableMouse(true)
        if slot.SetFrameLevel then
            slot:SetFrameLevel(bagSlotsWindow:GetFrameLevel() + 10)
        end

        local normal = slot:GetNormalTexture()
        if normal then normal:SetAlpha(1) end
        local pushed = slot:GetPushedTexture()
        if pushed then pushed:SetAlpha(1) end

        if i == 1 then
            slot:SetPoint("RIGHT", bagSlotsWindow, "RIGHT", -SPACING, 0)
        else
            slot:SetPoint("RIGHT", prev, "LEFT", -SPACING, 0)
        end
        prev = slot
    end

    if #slots > 0 then
        local slotWidth = 37 * SCALE
        local totalWidth = (#slots * slotWidth) + ((#slots + 1) * SPACING)
        local totalHeight = (37 * SCALE) + (SPACING * 2)
        bagSlotsWindow:SetSize(totalWidth, totalHeight)
    end
end

-- Classic KeyringMixin:OnShow() calls self:GetParent():Layout(); BagsBar provides Layout, our host must too.
function bagSlotsWindow:Layout()
    SetupBagSlots()
end

-- After Blizzard auto-expand toggles (item on/off cursor), reclaim slots into our popup.
if MainMenuBarBagManager and MainMenuBarBagManager.OnExpandBarChanged then
    hooksecurefunc(MainMenuBarBagManager, "OnExpandBarChanged", ReclaimBagSlotsIfPopupOpen)
end
if BaseBagSlotButtonMixin and BaseBagSlotButtonMixin.SetBarExpanded then
    hooksecurefunc(BaseBagSlotButtonMixin, "SetBarExpanded", KeepSlotShownIfPopupOpen)
end

-- Edit Mode lays out and re-anchors BagsBar inside its pass. Bag chrome waits
-- until it closes.
local function ReapplyBagsBarChrome()
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(ReapplyBagsBarChrome)
        return
    end
    if bagSlotsWindow:IsShown() then
        SetupBagSlots()
    else
        ParkBlizzardBagChrome()
    end
    if _G.FluxRefreshInBagSlots then
        _G.FluxRefreshInBagSlots()
    end
    CollapseBagsBarShell()
end

local function OnBagsBarLayout()
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(ReapplyBagsBarChrome)
        return
    end
    if bagSlotsWindow and bagSlotsWindow:IsShown() then
        SetupBagSlots()
        local mb = _G.FluxBagMicroButton
        if mb and FluxAddonSystem and FluxAddonSystem.ClampPopupToScreenAndMicroMenu then
            C_Timer.After(0, function()
                if bagSlotsWindow:IsShown() then
                    FluxAddonSystem.ClampPopupToScreenAndMicroMenu(bagSlotsWindow, mb)
                end
            end)
        end
    else
        ParkBlizzardBagChrome()
    end
    if _G.FluxRefreshInBagSlots then
        _G.FluxRefreshInBagSlots()
    end
    CollapseBagsBarShell()
end

-- Detach Blizzard bag slots from the HUD. Do not Hide, SetParent, or
-- EnableMouse BagsBar itself (Edit Mode taint). The buttons are removed.
local function HideBlizzardBags()
    -- BagsBar:Layout is a ContinueOnVariablesLoaded callback, in the same
    -- secureexecuterange as GamepadMainActionBarFrame:PostVariableSetUp.
    -- hooksecurefunc here taints SetPreferredGamepadInteractTarget.
    if _G.FluxUI_IsForeverGamepadUI and _G.FluxUI_IsForeverGamepadUI() then
        return
    end
    local bar = _G.BagsBar
    if bar and not bar.FluxHooked then
        hooksecurefunc(bar, "Layout", OnBagsBarLayout)
        if not bar.FluxReparentHooked then
            bar.FluxReparentHooked = true
            hooksecurefunc(bar, "SetParent", function()
                C_Timer.After(0, ReapplyBagsBarChrome)
            end)
        end
        bar.FluxHooked = true
    end

    if bagSlotsWindow:IsShown() then
        SetupBagSlots()
    else
        ParkBlizzardBagChrome()
    end
    CollapseBagsBarShell()

    if not bagChromeLoadWatcher then
        bagChromeLoadWatcher = CreateFrame("Frame")
        bagChromeLoadWatcher:RegisterEvent("ADDON_LOADED")
        bagChromeLoadWatcher:SetScript("OnEvent", function(_, _, name)
            if name == "Blizzard_MainMenuBarBagButtons"
                or name == "Blizzard_EditMode"
                or name == "Blizzard_UIPanels_Game" then
                HideBlizzardBags()
            end
        end)
    end
end

-- Call immediately
HideBlizzardBags()

-- ---------------------------------------------------------------------------
-- Button Handlers
-- ---------------------------------------------------------------------------

local function AnchorBagSlots(anchor, beside)
    if not anchor then
        return
    end
    bagSlotsWindow:ClearAllPoints()
    if beside then
        local gap = 4
        if FLUX_API and (FLUX_API.isCamelot or FLUX_API.isForever) then
            gap = 22
        end
        bagSlotsWindow:SetPoint("TOPLEFT", anchor, "TOPRIGHT", gap, 0)
        return
    end
    bagSlotsWindow:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
end

local function KeepBagSlotsOnScreen(anchor)
    if not bagSlotsWindow:IsShown() or not anchor then
        return
    end
    local right = bagSlotsWindow:GetRight()
    local screenRight = UIParent and UIParent:GetRight()
    if right and screenRight and right > screenRight - 8 then
        bagSlotsWindow:ClearAllPoints()
        bagSlotsWindow:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -4, 0)
    end
end

local function ForeverGamepadUI()
    return _G.FluxUI_IsForeverGamepadUI and _G.FluxUI_IsForeverGamepadUI() or false
end

local function BackpackButton()
    return _G.MainMenuBarBackpackButton
end

local function ToggleOpenBags()
    -- Opening Forever's gamepad bag from addon code taints the protected
    -- SetPreferredGamepadInteractTarget(). The secure click proxy opens it there.
    if ForeverGamepadUI() then
        return
    end
    if ToggleAllBags then
        ToggleAllBags()
    elseif OpenAllBags then
        OpenAllBags()
    elseif ToggleBackpack then
        ToggleBackpack()
    end
end

local function ToggleBagSlots(anchor, beside)
    -- Chat-column right-click calls this too. Slots live in the bag there.
    if BagSlotsLiveInBag() then
        bagSlotsWindow:Hide()
        ToggleOpenBags()
        return
    end
    if bagSlotsWindow:IsShown() then
        bagSlotsWindow:Hide()
        return
    end
    SetupBagSlots()
    local host = anchor or _G.FluxBagMicroButton
    AnchorBagSlots(host, beside)
    bagSlotsWindow:Show()
    if beside then
        KeepBagSlotsOnScreen(host)
        return
    end
    if host and FluxAddonSystem and FluxAddonSystem.ClampPopupToScreenAndMicroMenu then
        C_Timer.After(0, function()
            if bagSlotsWindow:IsShown() then
                FluxAddonSystem.ClampPopupToScreenAndMicroMenu(bagSlotsWindow, host)
            end
        end)
    end
end

local clickHandler = {
    OnClick = function(self, button)
        if button == "RightButton" and not BagSlotsLiveInBag() then
            ToggleBagSlots(self, false)
        else
            ToggleOpenBags()
        end
    end,
    
    OnTooltip = function(tooltip)
        tooltip:AddLine(" ")
        tooltip:AddLine("Backpack", 1, 1, 1)
        tooltip:AddLine("<Left Click> Toggle All Bags", 0.6, 0.6, 0.6)
        if not BagSlotsLiveInBag() then
            tooltip:AddLine("<Right Click> Equip Bags", 0.6, 0.6, 0.6)
        end
        
        -- Match the bag window's ordinary storage count (excludes reagent/keyring).
        local totalFree = GetTotalFreeBagSlots()
        
        tooltip:AddLine(" ")
        tooltip:AddLine("Free Space: |cffffffff" .. totalFree .. "|r", 1, 0.82, 0)
        tooltip:AddLine(" ")
        
        -- Detailed Breakdown
        tooltip:AddLine("Equipped Bags:", 1, 1, 1)
        
        local keyring = _G.KEYRING_CONTAINER or -2
        local function AddBagLine(bagID, namePrefix)
             local free = GetFreeSlotsSafe(bagID)
             local total = GetContainerNumSlots_Compat(bagID)
             local name = GetBagName_Compat(bagID)
             if name ~= "" then
                 name = name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
             end
             if name == "" then name = namePrefix or "Bag " .. bagID end
             
             local r, g, b = GetBagQualityColor(bagID)

             if total > 0 then
                 local sr, sg, sb = 0, 1, 0
                 if free == 0 then sr, sg, sb = 1, 0, 0
                 elseif free < 5 then sr, sg, sb = 1, 0.93, 0.63 end
                 
                 tooltip:AddDoubleLine(name, free .. " / " .. total, r, g, b, sr, sg, sb)
             end
        end
        
        for _, bagID in ipairs(GetCarriedBagIDs()) do
            if bagID ~= keyring then
                local prefix
                if bagID == (_G.BACKPACK_CONTAINER or 0) then
                    prefix = "Backpack"
                elseif bagID == (_G.REAGENTBAG_CONTAINER or (Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag) or 5) then
                    prefix = "Reagent Bag"
                end
                AddBagLine(bagID, prefix)
            end
        end
    end
}

local btn = FluxMicroMenu:CreateMicroButton(
    "FluxBagMicroButton", 
    "Interface\\Buttons\\UI-MicroButton-Character-Up", -- Placeholder
    "Backpack", 
    "OPENALLBAGS", 
    clickHandler
)
if btn then
    btn.FluxFillTooltip = clickHandler.OnTooltip
    btn.FluxToggleBagSlots = ToggleBagSlots
    local flux = _G.Flux
    if flux and flux.SecureClickProxy and flux.Client and flux.Client.isCamelot then
        flux.SecureClickProxy.Attach(btn, { target = BackpackButton, enabled = ForeverGamepadUI })
    end
end

-- Anchor Window to the button
if btn then
    bagSlotsWindow:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -2)
    btn:RegisterForClicks("AnyUp")
    
    -- Free space sits on the button's bottom-right, not the inset icon.
    local count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    count:SetJustifyH("RIGHT")
    count:SetText("")
    btn.count = count
    
    local function UpdateBagCount()
        local totalFree = GetTotalFreeBagSlots()
        
        if count then
            count:SetText(totalFree)
            if totalFree < 5 then
                count:SetTextColor(1, 0.1, 0.1) -- Red prompt
            else
                count:SetTextColor(1, 1, 1)
            end
        end
    end
    
    local bagCountDebounce = nil
    local function ScheduleUpdateBagCount()
        if bagCountDebounce then
            return
        end
        if C_Timer and C_Timer.After then
            bagCountDebounce = true
            C_Timer.After(0.15, function()
                bagCountDebounce = false
                UpdateBagCount()
            end)
        else
            UpdateBagCount()
        end
    end

    local bagCountListenerHooked = false
    local function EnsureBagCountListener()
        if bagCountListenerHooked then
            return
        end
        local inv = Inv()
        if inv and inv.RegisterListener then
            bagCountListenerHooked = true
            inv.RegisterListener("FluxBagMicroButton", ScheduleUpdateBagCount, {
                tier = "instant",
                regions = { "bags" },
                sync = true,
            })
            return
        end
        -- Legacy alias (pre-FluxInv)
        if inv and inv.RegisterCountListener then
            bagCountListenerHooked = true
            inv.RegisterCountListener("FluxBagMicroButton", ScheduleUpdateBagCount)
        end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("BAG_UPDATE")
    eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            EnsureBagCountListener()
            UpdateBagCount()
            HideBlizzardBags()
        elseif event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
            -- Fallback only when FluxInv listener is unavailable
            if not bagCountListenerHooked then
                EnsureBagCountListener()
                ScheduleUpdateBagCount()
            end
        end
    end)
    EnsureBagCountListener()
    UpdateBagCount()
end

-- Custom Styling for Bag Icon
if btn then
    local bagTexture = "Interface\\ICONS\\INV_Misc_Bag_08"
    if btn.icon then
        btn.icon:SetTexture(bagTexture)
    end
end
