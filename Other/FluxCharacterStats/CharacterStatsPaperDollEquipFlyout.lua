-- Paperdoll slot flyout on every client. Uses Flux inventory candidates.
-- Suppresses Blizzard's paperdoll flyout except while the equipment-set editor is open.
local addonName, ns = ...
local Flux = ns.Flux

local Candidates = _G.FluxEquipSlotCandidates
local Flyout = _G.FluxEquipSlotFlyout

local SLOT_MIN = 1
local SLOT_MAX = 19

local started = false
local hookedEnter = false
local hookedLeave = false
local wrappedUpdateFlyout = false
local wrappedShowFlyout = false
local wrappedClassicShow = false
local hookedPaperDoll = false
local hookedCharacterFrame = false
local hookedManagerShow = false
local hookedManagerHide = false
local hookedGearManager = false
local activeSlotButton = nil
local mouseoverTimer = nil
local enterGuardButton = nil
local enterGuardTime = nil

local function IsShown(frame)
    return frame and frame.IsShown and frame:IsShown()
end

local function IsEquipmentManagerOpen()
    local pd = _G.PaperDollFrame
    if pd then
        local pane = pd.EquipmentManagerPane
        if IsShown(pane) then
            return true
        end
    end
    if IsShown(_G.GearManagerDialog) then
        return true
    end
    if IsShown(_G.GearManagerPopupFrame) then
        return true
    end
    return false
end

local function IsPaperDollSlotButton(button)
    if not button then
        return false
    end
    local name = button.GetName and button:GetName()
    if type(name) == "string" and name:find("^Character") and name:find("Slot$") then
        return true
    end
    local parent = button.GetParent and button:GetParent()
    if not parent then
        return false
    end
    if parent == _G.PaperDollItemsFrame or parent == _G.PaperDollFrame then
        return true
    end
    local fs = parent.flyoutSettings
    if fs and fs.parent == _G.PaperDollFrame then
        return true
    end
    return false
end

local function HideIfShown(frame)
    if IsShown(frame) then
        frame:Hide()
    end
end

local function StopMouseoverTimer()
    if mouseoverTimer and mouseoverTimer.Cancel then
        mouseoverTimer:Cancel()
    end
    mouseoverTimer = nil
end

local function MouseIsOverPaperDollFlyoutContext()
    local fly = Flyout and Flyout._frame
    if fly and fly:IsShown() and fly:IsMouseOver() then
        return true
    end
    if activeSlotButton and activeSlotButton.IsMouseOver and activeSlotButton:IsMouseOver() then
        return true
    end
    return false
end

local function StartMouseoverTimer()
    StopMouseoverTimer()
    if not C_Timer or not C_Timer.NewTicker then
        return
    end
    mouseoverTimer = C_Timer.NewTicker(0.25, function()
        if not Flyout or not Flyout._frame or not Flyout._frame:IsShown() then
            StopMouseoverTimer()
            return
        end
        if MouseIsOverPaperDollFlyoutContext() then
            return
        end
        Flyout.Hide()
        activeSlotButton = nil
        StopMouseoverTimer()
    end)
end

local SLOT_BUTTON_NAMES = {
    "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot",
    "CharacterShirtSlot", "CharacterChestSlot", "CharacterWaistSlot",
    "CharacterLegsSlot", "CharacterFeetSlot", "CharacterWristSlot",
    "CharacterHandsSlot", "CharacterFinger0Slot", "CharacterFinger1Slot",
    "CharacterTrinket0Slot", "CharacterTrinket1Slot", "CharacterBackSlot",
    "CharacterMainHandSlot", "CharacterSecondaryHandSlot",
    "CharacterRangedSlot", "CharacterTabardSlot",
}

local function OnSlotEnter(self)
    if not self then
        return
    end
    local now = (GetTime and GetTime()) or 0
    if enterGuardButton == self and enterGuardTime == now then
        return
    end
    enterGuardButton = self
    enterGuardTime = now
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if IsEquipmentManagerOpen() then
        return
    end
    if type(self.GetID) ~= "function" then
        return
    end
    local slotID = self:GetID()
    if not slotID or slotID < SLOT_MIN or slotID > SLOT_MAX then
        return
    end
    if not Flyout or not Flyout.NotifyEnter then
        return
    end
    activeSlotButton = self
    Flyout.NotifyEnter(self, slotID, { placement = "auto" })
    StartMouseoverTimer()
end

local function OnSlotLeave()
    if IsEquipmentManagerOpen() then
        return
    end
    if Flyout and Flyout.NotifyLeave then
        Flyout.NotifyLeave({ mouseoverFrames = { activeSlotButton, Flyout._frame } })
    end
end

local function WrapGlobal(name, wrapper)
    local orig = _G[name]
    if type(orig) ~= "function" then
        return false
    end
    _G[name] = function(...)
        return wrapper(orig, ...)
    end
    return true
end

local function SuppressBlizzardPaperDollFlyout(button)
    if IsEquipmentManagerOpen() then
        return false
    end
    return IsPaperDollSlotButton(button)
end

local function InstallBlizzardSuppress()
    if not wrappedUpdateFlyout then
        wrappedUpdateFlyout = WrapGlobal("EquipmentFlyout_UpdateFlyout", function(orig, button, ...)
            if SuppressBlizzardPaperDollFlyout(button) then
                return
            end
            return orig(button, ...)
        end)
    end
    if not wrappedShowFlyout then
        wrappedShowFlyout = WrapGlobal("EquipmentFlyout_Show", function(orig, button, ...)
            if SuppressBlizzardPaperDollFlyout(button) then
                local f = _G.EquipmentFlyoutFrame
                if f and IsPaperDollSlotButton(f.button) then
                    HideIfShown(f)
                end
                return
            end
            return orig(button, ...)
        end)
    end
    if not wrappedClassicShow then
        wrappedClassicShow = WrapGlobal("PaperDollFrameItemFlyout_Show", function(orig, button, ...)
            if SuppressBlizzardPaperDollFlyout(button) then
                local f = _G.PaperDollFrameItemFlyout
                if f and IsPaperDollSlotButton(f.button) then
                    HideIfShown(f)
                end
                return
            end
            return orig(button, ...)
        end)
    end
end

local function HidePaperDollPopouts()
    if IsEquipmentManagerOpen() then
        return
    end
    for i = 1, #SLOT_BUTTON_NAMES do
        local slot = _G[SLOT_BUTTON_NAMES[i]]
        local pop = slot and slot.popoutButton
        if pop and pop.Hide then
            pop:Hide()
        end
    end
end

local function HookSlotButtons()
    for i = 1, #SLOT_BUTTON_NAMES do
        local slot = _G[SLOT_BUTTON_NAMES[i]]
        if slot and slot.HookScript and not slot._fluxEquipFlyout then
            slot._fluxEquipFlyout = true
            slot:HookScript("OnEnter", OnSlotEnter)
            slot:HookScript("OnLeave", OnSlotLeave)
        end
    end
end

local function HookNamed(name, fn)
    local target = _G[name]
    if type(target) ~= "function" or type(hooksecurefunc) ~= "function" then
        return false
    end
    hooksecurefunc(name, fn)
    return true
end

local function InstallEnterLeave()
    if not hookedEnter and type(_G.PaperDollItemSlotButton_OnEnter) == "function" then
        if type(hooksecurefunc) == "function" then
            hooksecurefunc("PaperDollItemSlotButton_OnEnter", OnSlotEnter)
            hookedEnter = true
        end
    end
    if not hookedLeave and type(_G.PaperDollItemSlotButton_OnLeave) == "function" then
        if type(hooksecurefunc) == "function" then
            hooksecurefunc("PaperDollItemSlotButton_OnLeave", OnSlotLeave)
            hookedLeave = true
        end
    end
end

local function HideFluxFlyout()
    if Flyout and Flyout.Hide then
        Flyout.Hide()
    end
    activeSlotButton = nil
    StopMouseoverTimer()
end

local function InstallPanelHooks()
    local pd = _G.PaperDollFrame
    if not hookedPaperDoll and pd and pd.HookScript then
        hookedPaperDoll = true
        pd:HookScript("OnHide", HideFluxFlyout)
        pd:HookScript("OnShow", function()
            HidePaperDollPopouts()
            HookSlotButtons()
        end)
    end
    local cf = _G.CharacterFrame
    if not hookedCharacterFrame and cf and cf.HookScript then
        hookedCharacterFrame = true
        cf:HookScript("OnHide", HideFluxFlyout)
    end
    if not hookedManagerShow then
        hookedManagerShow = HookNamed("PaperDollEquipmentManagerPane_OnShow", HideFluxFlyout)
    end
    if not hookedManagerHide then
        hookedManagerHide = HookNamed("PaperDollEquipmentManagerPane_OnHide", HidePaperDollPopouts)
    end
    local gm = _G.GearManagerDialog
    if not hookedGearManager and gm and gm.HookScript then
        hookedGearManager = true
        gm:HookScript("OnShow", HideFluxFlyout)
        gm:HookScript("OnHide", HidePaperDollPopouts)
    end
end

local equippedHooked = false

local function TryInstall()
    Candidates = _G.FluxEquipSlotCandidates
    Flyout = _G.FluxEquipSlotFlyout
    if not Candidates or not Flyout then
        return
    end
    if not equippedHooked and Flyout.SetOnEquipped then
        equippedHooked = true
        Flyout.SetOnEquipped(function()
            if Candidates and Candidates.Invalidate then
                Candidates.Invalidate()
            end
            activeSlotButton = nil
            StopMouseoverTimer()
        end)
    end
    InstallEnterLeave()
    HookSlotButtons()
    InstallBlizzardSuppress()
    InstallPanelHooks()
    HidePaperDollPopouts()
end

local function Start()
    if started then
        return
    end
    started = true

    TryInstall()

    if Flux and Flux.Events and Flux.Events.Register then
        Flux.Events.Register("ADDON_LOADED", function()
            TryInstall()
        end)
        Flux.Events.Register("PLAYER_LOGIN", function()
            TryInstall()
        end)
        Flux.Events.Register("PLAYER_ENTERING_WORLD", function()
            TryInstall()
        end)
        Flux.Events.Register("PLAYER_REGEN_DISABLED", function()
            HideFluxFlyout()
        end)
    end
end

if Flux and Flux.Module then
    Flux.Module.Register("EquipSlotFlyout", {
        clients = { era = true, anniversary = true, classic = true, midnight = true },
        OnEnable = Start,
    })
else
    Start()
end
