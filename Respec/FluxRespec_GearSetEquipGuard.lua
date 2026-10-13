-- FluxRespec_GearSetEquipGuard.lua
-- Blocks manual disenchant clicks on equipped gear-set items (paper doll slots).

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.GearSetEquipGuard = R.GearSetEquipGuard or {}
local EquipGuard = R.GearSetEquipGuard

local ClickGuards = {}

local INV_SLOT_BUTTON = {
    [1] = "CharacterHeadSlot",
    [2] = "CharacterNeckSlot",
    [3] = "CharacterShoulderSlot",
    [4] = "CharacterShirtSlot",
    [5] = "CharacterChestSlot",
    [6] = "CharacterWaistSlot",
    [7] = "CharacterLegsSlot",
    [8] = "CharacterFeetSlot",
    [9] = "CharacterWristSlot",
    [10] = "CharacterHandsSlot",
    [11] = "CharacterFinger0Slot",
    [12] = "CharacterFinger1Slot",
    [13] = "CharacterTrinket0Slot",
    [14] = "CharacterTrinket1Slot",
    [15] = "CharacterBackSlot",
    [16] = "CharacterMainHandSlot",
    [17] = "CharacterSecondaryHandSlot",
    [18] = "CharacterRangedSlot",
    [19] = "CharacterTabardSlot",
    [20] = "CharacterSecondaryShoulderSlot",
}

local function GetGearSetLock()
    return R.GearSetLock
end

local function SlotMax()
    local equip = R.Equipment
    if equip and equip.GetSlotMax then
        return equip.GetSlotMax()
    end
    local compat = R.Compat
    if compat and compat.EquipmentSlotMax then
        return compat.EquipmentSlotMax()
    end
    return 19
end

local function ResolvePaperDollButton(invSlot)
    local name = INV_SLOT_BUTTON[invSlot]
    if not name then
        return
    end
    local button = _G[name]
    if button and button.GetID then
        local id = button:GetID()
        if id and id == invSlot then
            return button
        end
    end
    if button then
        return button
    end
end

local function ForwardPaperDollTooltip(button)
    if not button then
        return
    end
    if button.UpdateTooltip then
        button:UpdateTooltip()
        return
    end
    if _G.PaperDollItemSlotButton_OnEnter then
        _G.PaperDollItemSlotButton_OnEnter(button)
        return
    end
    local onEnter = button:GetScript("OnEnter")
    if onEnter then
        onEnter(button)
    end
end

local function ForwardPaperDollTooltipHide(button)
    if button and button.UpdateTooltip then
        button:UpdateTooltip()
    elseif _G.PaperDollItemSlotButton_OnLeave then
        _G.PaperDollItemSlotButton_OnLeave(button)
    elseif GameTooltip_Hide then
        GameTooltip_Hide()
    end
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function ApplyMousePropagateOnce(guard)
    if guard._fluxMousePropagateSet or InCombat() then
        return
    end
    if guard.SetPropagateMouseMotion then
        guard:SetPropagateMouseMotion(true)
    end
    if guard.SetPropagateMouseClicks then
        guard:SetPropagateMouseClicks(false)
    end
    guard._fluxMousePropagateSet = true
end

local function ConfigureClickGuard(guard, button, mode)
    -- Protected APIs — skip in combat to avoid ADDON_ACTION_BLOCKED.
    ApplyMousePropagateOnce(guard)
    if guard.SetPassThroughButtons and not InCombat() then
        guard:SetPassThroughButtons()
    end
    guard.ShouldButtonPassThrough = nil

    guard:SetScript("OnEnter", function()
        ForwardPaperDollTooltip(button)
    end)
    guard:SetScript("OnLeave", function()
        ForwardPaperDollTooltipHide(button)
    end)

    if mode ~= "de" then
        return false
    end

    if guard.ShouldButtonPassThrough then
        guard.ShouldButtonPassThrough = function(_, mouseButton)
            if mouseButton == "LeftButtonDown" then
                return true
            end
            if mouseButton == "LeftButtonUp" or mouseButton == "LeftButton" then
                return false
            end
            return true
        end
        guard:RegisterForClicks("LeftButtonUp")
        return true
    end

    return false
end

local function UpdateClickGuard(button, invSlot)
    local lock = GetGearSetLock()
    if not lock or not lock.ShouldShowManualInventoryClickGuard then
        local guard = ClickGuards[button]
        if guard then
            guard:Hide()
        end
        return
    end

    if not lock.ShouldShowManualInventoryClickGuard(invSlot) then
        local guard = ClickGuards[button]
        if guard then
            guard:Hide()
        end
        return
    end

    local mode = lock.GetManualInventoryClickGuardMode and lock.GetManualInventoryClickGuardMode() or "de"
    local guard = ClickGuards[button]
    if not guard then
        guard = CreateFrame("Button", nil, button)
        guard:SetAllPoints(button)
        guard:SetFrameStrata(button:GetFrameStrata())
        guard:SetFrameLevel(button:GetFrameLevel() + 20)
        guard:EnableMouse(true)
        guard:SetScript("OnClick", function()
            if CursorHasItem and CursorHasItem() then
                return
            end
            if GetCursorInfo then
                local cursorType = GetCursorInfo()
                if cursorType == "item" then
                    return
                end
            end
            if lock.NotifyBlocked then
                lock.NotifyBlocked()
            end
        end)
        ClickGuards[button] = guard
    end

    if guard.clickMode ~= mode or not guard.clickConfigured then
        guard.clickMode = mode
        guard.clickConfigured = ConfigureClickGuard(guard, button, mode)
        if not guard.clickConfigured then
            guard:Hide()
            return
        end
    end
    guard:Show()
end

function EquipGuard.RefreshAll()
    local maxSlot = SlotMax()
    for invSlot = 1, maxSlot do
        local button = ResolvePaperDollButton(invSlot)
        if button then
            UpdateClickGuard(button, invSlot)
        end
    end
end

local function IsCamelotClient()
    local client = _G.Flux and _G.Flux.Client
    if client then
        return client.isCamelot == true
    end
    return _G.FLUX_API and _G.FLUX_API.isCamelot == true or false
end

local characterShowHooked = false

local function InstallCharacterShowHook()
    if characterShowHooked then
        return
    end
    -- HookScript OnShow taints Forever's secret health compare in
    -- CharacterFrame:OnShow. Refresh after ToggleCharacter has returned.
    if IsCamelotClient() then
        local info = rawget(_G, "FluxInfoFrame")
        if not (info and info.AfterCharacterShown) then
            return
        end
        characterShowHooked = true
        info.AfterCharacterShown(function()
            EquipGuard.RefreshAll()
        end)
        return
    end
    local frame = _G.CharacterFrame
    if not frame or not frame.HookScript then
        return
    end
    characterShowHooked = true
    frame:HookScript("OnShow", function()
        EquipGuard.RefreshAll()
    end)
end

InstallCharacterShowHook()

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    InstallCharacterShowHook()
    EquipGuard.RefreshAll()
    R.On("GEAR_SET_LOCK_CHANGED", EquipGuard.RefreshAll)
end)

_G.FluxRespecGearSetEquipGuard = EquipGuard
return EquipGuard

