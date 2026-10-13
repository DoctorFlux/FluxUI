-- MicroMenuHooks.lua
-- Disables ConsolePort micromenu takeover while preserving other ConsolePort systems.

local addonName, ns = ...

ns.ConsolePortCompat = ns.ConsolePortCompat or {}
local Compat = ns.ConsolePortCompat

local function IsInCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function EnsureHiddenParent()
    if Compat.cpMenuHiddenParent and Compat.cpMenuHiddenParent.GetObjectType then
        return Compat.cpMenuHiddenParent
    end
    local f = CreateFrame("Frame", "FluxConsolePortCompatMenuHiddenParent", UIParent)
    f:Hide()
    f:SetSize(1, 1)
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -9000, -9000)
    Compat.cpMenuHiddenParent = f
    return f
end

local function HideConsolePortMenuFrame(frame)
    if not frame or frame._fluxCPMenuSuppressed then
        return
    end

    local hiddenParent = EnsureHiddenParent()
    frame._fluxCPMenuSuppressed = true

    if frame.EnableMouse then
        pcall(frame.EnableMouse, frame, false)
    end
    local function applyHide()
        if IsInCombat() then
            return
        end
        pcall(frame.SetParent, frame, hiddenParent)
        pcall(frame.Hide, frame)
    end

    if Compat.RunOrDefer then
        Compat.RunOrDefer("cp-menu-hide-" .. tostring(frame), applyHide)
    else
        applyHide()
    end

    if frame.HookScript and not frame._fluxCPShowHooked then
        frame._fluxCPShowHooked = true
        frame:HookScript("OnShow", function(self)
            if IsInCombat() then
                return
            end
            if self:GetParent() ~= hiddenParent then
                self:SetParent(hiddenParent)
            end
            self:Hide()
        end)
    end
end

local function SanitizeProps(props)
    if type(props) ~= "table" then
        return props
    end
    props.micromenu = false
    props.eye = false
    return props
end

local function ReparentButtonsToMicroMenu()
    if IsInCombat() then
        return
    end
    local target = _G.MicroMenu
    if not target then
        return
    end
    local movedAny = false

    if MICRO_BUTTONS then
        for i = 1, #MICRO_BUTTONS do
            local button = _G[MICRO_BUTTONS[i]]
            if button and button:GetParent() ~= target then
                local parent = button:GetParent()
                local parentName = parent and parent.GetName and parent:GetName() or ""
                if type(parentName) == "string" and parentName:find("ConsolePort", 1, true) then
                    button:SetParent(target)
                    movedAny = true
                end
            end
        end
    end

    if movedAny then
        if target.Layout then
            pcall(target.Layout, target)
        end
        if UpdateMicroButtonsParent then
            pcall(UpdateMicroButtonsParent)
        end
        if UpdateMicroButtons then
            pcall(UpdateMicroButtons)
        end
    end
end

local function ReparentButtonsToMicroMenuSafe()
    local fn = ReparentButtonsToMicroMenu
    if Compat.RunOrDefer then
        Compat.RunOrDefer("cp-reparent-microbuttons", fn)
    else
        fn()
    end
end

local function DisablePopoutMicromenu(popoutFrame)
    if not popoutFrame then
        return
    end

    if popoutFrame.props then
        SanitizeProps(popoutFrame.props)
    end

    if popoutFrame.Divider1 then
        popoutFrame.Divider1:SetShown(false)
    end

    -- Hard override (not post-hook) so ConsolePort never enables micromenu path.
    if popoutFrame.SetProps and not popoutFrame._fluxCPSetPropsOverridden then
        popoutFrame._fluxCPSetPropsOverridden = true
        local originalSetProps = popoutFrame.SetProps
        popoutFrame.SetProps = function(self, props, inverted)
            SanitizeProps(props)
            if self.props then
                SanitizeProps(self.props)
            end
            if self.Divider1 then
                self.Divider1:SetShown(false)
            end
            local result = originalSetProps(self, props, inverted)
            ReparentButtonsToMicroMenuSafe()
            return result
        end
    end

    if popoutFrame.MoveMicroButtons and not popoutFrame._fluxCPMoveMicroButtonsOverridden then
        popoutFrame._fluxCPMoveMicroButtonsOverridden = true
        popoutFrame.MoveMicroButtons = function(self)
            if self.props then
                SanitizeProps(self.props)
            end
            if self.Divider1 then
                self.Divider1:SetShown(false)
            end
            ReparentButtonsToMicroMenuSafe()
            -- Intentionally skip original MoveMicroButtons to prevent CP reparent takeover.
        end
    end

    if popoutFrame.OnUpdateMicroButtonsParent and not popoutFrame._fluxCPUpdateParentHooked then
        popoutFrame._fluxCPUpdateParentHooked = true
        hooksecurefunc(popoutFrame, "OnUpdateMicroButtonsParent", function(self)
            if self.props then
                SanitizeProps(self.props)
            end
            ReparentButtonsToMicroMenuSafe()
        end)
    end
end

local function ApplyToolbarMicromenuIsolation()
    local toolbar = _G.ConsolePortToolbar
    if not toolbar or not toolbar.PopoutContainer then
        return
    end

    local popoutFrame = toolbar.PopoutContainer.PopoutFrame
    DisablePopoutMicromenu(popoutFrame)

    local function HideToolbarMicroButton(btn)
        if not btn then
            return
        end
        btn._fluxCPMicroButtonHidden = true
        if btn.EnableMouse then
            pcall(btn.EnableMouse, btn, false)
        end
        pcall(btn.SetAlpha, btn, 0)
        pcall(btn.Hide, btn)
        if btn.HookScript and not btn._fluxCPMicroShowHooked then
            btn._fluxCPMicroShowHooked = true
            btn:HookScript("OnShow", function(self)
                if IsInCombat() then
                    return
                end
                self:SetAlpha(0)
                self:Hide()
            end)
        end
    end

    HideToolbarMicroButton(popoutFrame and popoutFrame.Eye)
    HideToolbarMicroButton(popoutFrame and popoutFrame.Config)
    HideToolbarMicroButton(popoutFrame and popoutFrame.ExitVehicle)
    ReparentButtonsToMicroMenuSafe()
end

local function EnsureGlobalReapplyHooks()
    if Compat._fluxCPGlobalMicroHooksInstalled then
        return
    end
    Compat._fluxCPGlobalMicroHooksInstalled = true

    -- Same GameMenuFrame:OnShow path as FluxMicroMenu: hooking UpdateMicroButtons
    -- taints SetPreferredGamepadInteractTarget() on Forever.
    local foreverClient = (Flux and Flux.Client and (Flux.Client.isCamelot or Flux.Client.isForever))
        or (FLUX_API and (FLUX_API.isCamelot or FLUX_API.isForever))
    if not foreverClient and UpdateMicroButtonsParent then
        hooksecurefunc("UpdateMicroButtonsParent", function()
            if Compat.ApplyMicroMenuSuppression then
                Compat.ApplyMicroMenuSuppression()
            end
        end)
    end
    if not foreverClient and UpdateMicroButtons then
        hooksecurefunc("UpdateMicroButtons", function()
            if Compat.ApplyMicroMenuSuppression then
                Compat.ApplyMicroMenuSuppression()
            end
        end)
    end
end

function Compat.ApplyMicroMenuSuppression()
    -- Keep ConsolePort action/ring systems, disable only micromenu takeover.
    EnsureGlobalReapplyHooks()
    ApplyToolbarMicromenuIsolation()

    -- Menu trigger/ring are part of ConsolePort's micromenu presentation.
    HideConsolePortMenuFrame(_G.ConsolePortMenuTrigger)
    HideConsolePortMenuFrame(_G.ConsolePortMenu)
    HideConsolePortMenuFrame(_G.ConsolePortMenuRing)
end
