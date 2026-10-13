-- UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua
-- Player portrait transmog trigger (post-DF/Midnight): hover-revealed icon + ExtraButtonSystem outfit flyout.
local addonName, ns = ...
ns.PlayerTransmogClick = ns.PlayerTransmogClick or {}

local API = ns.API
local PTC = ns.PlayerTransmogClick

local ICON_SIZE = 28
local FLYOUT_PROXY_SIZE_MULT = 0.88
local WATCHER_INTERVAL = 0.25 -- was 0.05; hover/flyout still feels instant via events
local OUTFIT_EQUIP_SPELL_ID = 1247613
local TRANSMOG_HELMET_FALLBACK_ICON = "Interface\\Icons\\INV_Helmet_134"
local TRANSMOG_PRIMARY_ATLAS = "transmog-icon-ui"
local TRANSMOG_BUTTON_ATLASES = {
    "transmog-outfit-spellframe",
    "transmog-wardrobe-border-collected",
}

local state = {
    frame = nil,
    btn = nil,
    portraitHoverCatcher = nil,
    flyoutAnchorProxy = nil,
    characterFlyoutProxy = nil,
    characterFlyoutAnchor = nil,
    characterFlyoutDirection = nil,
    characterFlyoutFollow = nil,
    characterFlyoutWatcher = nil,
    characterFlyoutCombatHider = nil,
    eventFrame = nil,
    hooked = false,
    hoverAccum = 0,
}

local function GetFlyout()
    local Flux = ns.Flux
    return Flux and Flux.EBS and Flux.EBS.Flyout
end

local function IsTransmogOutfitFeatureAvailable()
    return API
        and API.HasPlayerTransmogOutfitAPI
        and API.HasPlayerTransmogOutfitAPI() == true
end

local function SafeRegisterEvent(frame, event)
    if not frame or not event then
        return false
    end
    local ok = pcall(frame.RegisterEvent, frame, event)
    return ok == true
end

local function EnsureFlyoutAnchorProxy()
    if state.flyoutAnchorProxy then
        return state.flyoutAnchorProxy
    end
    local p = CreateFrame("Frame", "FluxPlayerTransmogFlyoutAnchor", UIParent)
    p:SetSize(24, 24)
    p:Hide()
    state.flyoutAnchorProxy = p
    return p
end

local function SyncFlyoutAnchorProxy(anchor)
    if not anchor then
        return false
    end
    local proxy = EnsureFlyoutAnchorProxy()
    local ok = pcall(function()
        proxy:ClearAllPoints()
        proxy:SetPoint("CENTER", anchor, "CENTER", 0, 0)
        local w = tonumber(anchor:GetWidth()) or 24
        local h = tonumber(anchor:GetHeight()) or 24
        local size = math.max(16, math.floor(math.min(w, h) * FLYOUT_PROXY_SIZE_MULT))
        proxy:SetSize(size, size)
        proxy:Show()
    end)
    return ok == true
end

local function TransmogFlyoutOpts()
    return {
        direction = "UP",
        hideArrow = true,
        matchAnchorScale = true,
        adoptHostCast = false,
        anchorFrame = state.flyoutAnchorProxy,
    }
end

local function FlyoutHost()
    return EnsureFlyoutAnchorProxy()
end

local function EnsureTransmogFlyoutHost()
    local Flyout = GetFlyout()
    local host = FlyoutHost()
    if not Flyout or not host or not Flyout.BindHost then
        return nil
    end
    Flyout.BindHost(host, TransmogFlyoutOpts())
    return Flyout
end

local function OutfitKidOnEnter(kid)
    local def = kid and kid._fluxFlyoutDef
    if not GameTooltip then
        return
    end
    GameTooltip:SetOwner(kid, "ANCHOR_RIGHT", 4, 4)
    if GameTooltip.ClearLines then
        GameTooltip:ClearLines()
    end
    GameTooltip:SetText((def and def.name) or "", 1, 1, 1)
    if def and def.isActive then
        GameTooltip:AddLine("Currently active.", 0.18, 0.95, 0.28)
    else
        GameTooltip:AddLine("Click to activate this outfit.", 0.78, 0.78, 0.78, true)
    end
    GameTooltip:Show()
end

local function BuildTransmogFlyoutButtons()
    local buttons = {}
    local entries = (API.GetPlayerTransmogOutfitEntries and API.GetPlayerTransmogOutfitEntries()) or {}
    for _, e in ipairs(entries) do
        if e and not e.isDisabled and type(e.index) == "number" then
            buttons[#buttons + 1] = {
                type = "macrotext",
                macrotext = "/outfit !" .. tostring(e.index),
                icon = e.icon,
                name = e.name,
                isActive = e.isActive and true or false,
                spell = OUTFIT_EQUIP_SPELL_ID,
                onEnter = OutfitKidOnEnter,
            }
        end
    end
    return buttons
end

local function EnsureRowActiveBorder(row)
    if row._fluxTransmogActiveBorder then
        return row._fluxTransmogActiveBorder
    end
    local border = row:CreateTexture(nil, "OVERLAY")
    border:SetAtlas("bags-glow-white", true)
    border:SetVertexColor(0.18, 0.95, 0.28, 0.95)
    border:Hide()
    row._fluxTransmogActiveBorder = border
    return border
end

local function RefreshFlyoutRowVisuals(host)
    local Flyout = GetFlyout()
    if not host then
        host = FlyoutHost()
    end
    if not Flyout or not host or not Flyout.GetPopup then
        return
    end
    local popup = Flyout.GetPopup(host)
    if not popup or type(popup.kids) ~= "table" then
        return
    end
    for _, kid in ipairs(popup.kids) do
        if kid and kid:IsShown() then
            local def = kid._fluxFlyoutDef
            local active = def and def.isActive == true
            local border = EnsureRowActiveBorder(kid)
            local icon = kid.icon or kid.Icon
            border:ClearAllPoints()
            if icon then
                border:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
                border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
            else
                border:SetPoint("TOPLEFT", kid, "TOPLEFT", -2, 2)
                border:SetPoint("BOTTOMRIGHT", kid, "BOTTOMRIGHT", 2, -2)
            end
            if active then
                border:Show()
            else
                border:Hide()
            end
        elseif kid and kid._fluxTransmogActiveBorder then
            kid._fluxTransmogActiveBorder:Hide()
        end
    end
end

local function IsTransmogFlyoutOpenFor()
    local Flyout = GetFlyout()
    local host = state.flyoutAnchorProxy
    return Flyout and host and Flyout.IsOpen and Flyout.IsOpen(host) or false
end

local function CloseTransmogFlyoutIfOpen()
    local Flyout = GetFlyout()
    local host = state.flyoutAnchorProxy
    if Flyout and host and Flyout.Close then
        Flyout.Close(host)
    end
end

local function ToggleTransmogFlyout(anchor)
    if InCombatLockdown() then
        return
    end
    local Flyout = EnsureTransmogFlyoutHost()
    local host = FlyoutHost()
    if not Flyout or not host then
        return
    end
    if Flyout.IsOpen and Flyout.IsOpen(host) then
        if Flyout.Close then
            Flyout.Close(host)
        end
        return
    end
    local buttons = BuildTransmogFlyoutButtons()
    if #buttons < 1 then
        return
    end
    if not SyncFlyoutAnchorProxy(anchor or state.btn) then
        return
    end
    Flyout.SetButtons(host, buttons, TransmogFlyoutOpts())
    if Flyout.Toggle then
        Flyout.Toggle(host)
    end
    RefreshFlyoutRowVisuals()
end

local function EnsureCharacterFlyoutProxy()
    if state.characterFlyoutProxy then
        return state.characterFlyoutProxy
    end
    local p = CreateFrame("Frame", "FluxCharacterOutfitFlyoutAnchor", UIParent)
    p:SetSize(24, 24)
    p:EnableMouse(false)
    p:Hide()
    state.characterFlyoutProxy = p
    return p
end

local function SyncCharacterFlyoutProxy(anchor)
    if not anchor then
        return false
    end
    local proxy = EnsureCharacterFlyoutProxy()
    local ok = pcall(function()
        proxy:ClearAllPoints()
        proxy:SetPoint("CENTER", anchor, "CENTER", 0, 0)
        local w = tonumber(anchor:GetWidth()) or 24
        local h = tonumber(anchor:GetHeight()) or 24
        local size = math.max(16, math.floor(math.min(w, h) * FLYOUT_PROXY_SIZE_MULT))
        proxy:SetSize(size, size)
        proxy:Show()
    end)
    return ok == true
end

local function CharacterFlyoutOpts(direction)
    return {
        direction = direction or "RIGHT",
        hideArrow = true,
        matchAnchorScale = true,
        adoptHostCast = false,
        anchorFrame = state.characterFlyoutProxy,
    }
end

local function IsCharacterFlyoutOpen()
    local Flyout = GetFlyout()
    local host = state.characterFlyoutProxy
    return Flyout and host and Flyout.IsOpen and Flyout.IsOpen(host) or false
end

local function CloseCharacterFlyout()
    if state.characterFlyoutFollow then
        state.characterFlyoutFollow:Hide()
    end
    state.characterFlyoutAnchor = nil
    local Flyout = GetFlyout()
    local host = state.characterFlyoutProxy
    if Flyout and host and Flyout.Close then
        Flyout.Close(host)
    end
end

local function EnsureCharacterFlyoutFollow()
    if state.characterFlyoutFollow then
        return state.characterFlyoutFollow
    end
    local follow = CreateFrame("Frame")
    follow:Hide()
    follow:SetScript("OnUpdate", function(self)
        if not IsCharacterFlyoutOpen() then
            state.characterFlyoutAnchor = nil
            self:Hide()
            return
        end
        local anchor = state.characterFlyoutAnchor
        if not anchor or (anchor.IsShown and not anchor:IsShown()) then
            CloseCharacterFlyout()
            return
        end
        if not SyncCharacterFlyoutProxy(anchor) then
            return
        end
        local Flyout = GetFlyout()
        local host = state.characterFlyoutProxy
        if Flyout and host and Flyout.PlacePopup then
            Flyout.PlacePopup(host)
        end
    end)
    state.characterFlyoutFollow = follow
    return follow
end

--- Popup is a SecureFrameTemplate, so addon Hide() cannot run once combat locks.
--- A state-template frame keeps the Blizzard OnAttributeChanged path and hides it.
local function ArmCharacterFlyoutCombatHide()
    if InCombatLockdown() then
        return
    end
    local Flyout = GetFlyout()
    local host = state.characterFlyoutProxy
    local popup = Flyout and host and Flyout.GetPopup and Flyout.GetPopup(host)
    if not popup or not RegisterStateDriver then
        return
    end
    local hider = state.characterFlyoutCombatHider
    if not hider then
        local ok, created = pcall(CreateFrame, "Frame", "FluxCharacterOutfitFlyoutCombatHider", UIParent, "SecureHandlerStateTemplate")
        if not ok or not created or not created.SetAttribute or not created.SetFrameRef then
            return
        end
        hider = created
        hider:Hide()
        hider:SetAttribute("_onstate-fluxoutfitcombat", [[
            if newstate == "hide" then
                local popup = self:GetFrameRef("popup")
                if popup then
                    popup:Hide()
                end
            end
        ]])
        RegisterStateDriver(hider, "fluxoutfitcombat", "[combat] hide; show")
        state.characterFlyoutCombatHider = hider
    end
    if hider._fluxOutfitPopup ~= popup then
        hider:SetFrameRef("popup", popup)
        hider._fluxOutfitPopup = popup
    end
end

local function RefreshOpenCharacterFlyout()
    if not IsCharacterFlyoutOpen() then
        return
    end
    local Flyout = GetFlyout()
    local host = state.characterFlyoutProxy
    local anchor = state.characterFlyoutAnchor
    if not Flyout or not host or not anchor or not Flyout.SetButtons then
        return
    end
    local buttons = BuildTransmogFlyoutButtons()
    if #buttons < 1 then
        CloseCharacterFlyout()
        return
    end
    if not SyncCharacterFlyoutProxy(anchor) then
        return
    end
    Flyout.SetButtons(host, buttons, CharacterFlyoutOpts(state.characterFlyoutDirection))
    if Flyout.PlacePopup then
        Flyout.PlacePopup(host)
    end
    RefreshFlyoutRowVisuals(host)
end

local function EnsureCharacterFlyoutWatcher()
    if state.characterFlyoutWatcher then
        return
    end
    local evt = CreateFrame("Frame")
    SafeRegisterEvent(evt, "PLAYER_REGEN_DISABLED")
    SafeRegisterEvent(evt, "TRANSMOG_OUTFITS_CHANGED")
    SafeRegisterEvent(evt, "TRANSMOG_DISPLAYED_OUTFIT_CHANGED")
    SafeRegisterEvent(evt, "TRANSMOG_COLLECTION_UPDATED")
    evt:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            CloseCharacterFlyout()
            return
        end
        RefreshOpenCharacterFlyout()
    end)
    state.characterFlyoutWatcher = evt
end

function PTC.ToggleOutfitFlyout(anchor, direction)
    if not IsTransmogOutfitFeatureAvailable() or InCombatLockdown() or not anchor then
        return false
    end
    if direction ~= "UP" and direction ~= "DOWN" and direction ~= "LEFT" and direction ~= "RIGHT" then
        direction = "RIGHT"
    end
    EnsureCharacterFlyoutWatcher()
    local host = EnsureCharacterFlyoutProxy()
    local Flyout = GetFlyout()
    if not host or not Flyout or not Flyout.SetButtons then
        return false
    end
    if IsCharacterFlyoutOpen() and state.characterFlyoutAnchor == anchor then
        CloseCharacterFlyout()
        return true
    end
    local buttons = BuildTransmogFlyoutButtons()
    if #buttons < 1 then
        return false
    end
    if not SyncCharacterFlyoutProxy(anchor) then
        return false
    end
    state.characterFlyoutAnchor = anchor
    state.characterFlyoutDirection = direction
    Flyout.SetButtons(host, buttons, CharacterFlyoutOpts(direction))
    if Flyout.IsOpen and Flyout.IsOpen(host) then
        if Flyout.PlacePopup then
            Flyout.PlacePopup(host)
        end
    elseif Flyout.Toggle then
        Flyout.Toggle(host)
    end
    ArmCharacterFlyoutCombatHide()
    RefreshFlyoutRowVisuals(host)
    EnsureCharacterFlyoutFollow():Show()
    return true
end

local function CanShowTransmogControl(playerFrame)
    if not IsTransmogOutfitFeatureAvailable() then
        return false
    end
    if not playerFrame or playerFrame.unit ~= "player" then
        return false
    end
    if InCombatLockdown() then
        return false
    end
    if not playerFrame.PortraitFrame then
        return false
    end
    local buttons = BuildTransmogFlyoutButtons()
    return #buttons >= 1
end

local function RefreshOpenTransmogFlyout()
    if not IsTransmogFlyoutOpenFor() then
        return
    end
    local Flyout = GetFlyout()
    local host = FlyoutHost()
    if not Flyout or not host or not Flyout.SetButtons then
        return
    end
    local buttons = BuildTransmogFlyoutButtons()
    if #buttons < 1 then
        CloseTransmogFlyoutIfOpen()
        return
    end
    if not SyncFlyoutAnchorProxy(state.btn) then
        return
    end
    Flyout.SetButtons(host, buttons, TransmogFlyoutOpts())
    RefreshFlyoutRowVisuals()
end

local function ArmAndRefresh()
    if state.ArmTransmogWatcher then
        state.ArmTransmogWatcher()
    end
    if state.frame and PTC.UpdateInteractionState then
        PTC.UpdateInteractionState(state.frame)
    end
end

-- Outer border sits at playerFrame+5 and eats portrait mouse. Spec click parents
-- its hit target to that border at +25; transmog must do the same or hover never fires.
local function EnsureOuterHoverHook(playerFrame)
    local outer = playerFrame and playerFrame.outerBorderFrame
    if not outer or outer._fluxTransmogHoverHooked then
        return
    end
    outer._fluxTransmogHoverHooked = true
    outer:HookScript("OnEnter", ArmAndRefresh)
    outer:HookScript("OnLeave", ArmAndRefresh)
end

local function EnsurePortraitHoverCatcher(playerFrame)
    local portrait = playerFrame and playerFrame.PortraitFrame
    if not portrait then
        return nil
    end
    local outer = playerFrame.outerBorderFrame
    local parent = outer or portrait
    local catcher = state.portraitHoverCatcher
    if not catcher or catcher:GetParent() ~= parent then
        catcher = CreateFrame("Frame", "FluxPlayerPortraitHoverCatcher", parent)
        catcher:EnableMouse(true)
        catcher:SetMouseClickEnabled(false)
        catcher:SetScript("OnEnter", ArmAndRefresh)
        catcher:SetScript("OnLeave", ArmAndRefresh)
        state.portraitHoverCatcher = catcher
    end
    catcher:ClearAllPoints()
    catcher:SetAllPoints(portrait)
    catcher:SetFrameStrata(parent:GetFrameStrata())
    local base = (outer and outer:GetFrameLevel() or portrait:GetFrameLevel() or 0)
    catcher:SetFrameLevel(base + 24)
    return catcher
end

local function ApplyButtonLayout(playerFrame)
    local btn = state.btn
    local portrait = playerFrame and playerFrame.PortraitFrame
    if not btn or not portrait then
        return
    end
    local outer = playerFrame.outerBorderFrame
    local parent = outer or portrait
    if btn:GetParent() ~= parent then
        btn:SetParent(parent)
    end
    EnsureOuterHoverHook(playerFrame)
    local catcher = EnsurePortraitHoverCatcher(playerFrame)
    local base = (outer and outer:GetFrameLevel() or portrait:GetFrameLevel() or 0)
    if catcher then
        catcher:SetFrameStrata(parent:GetFrameStrata())
        catcher:SetFrameLevel(base + 24)
    end
    btn:ClearAllPoints()
    btn:SetPoint("BOTTOMLEFT", portrait, "BOTTOMLEFT", 4, 4)
    btn:SetSize(ICON_SIZE, ICON_SIZE)
    btn:SetFrameStrata(parent:GetFrameStrata())
    btn:SetFrameLevel(base + 26)
end

local function SetButtonIconFromAtlas(tex, atlasName)
    if not tex or not atlasName then
        return false
    end
    local ok = pcall(tex.SetAtlas, tex, atlasName, false)
    if ok then
        tex:SetAllPoints()
        tex:SetTexCoord(0, 1, 0, 1)
        tex:SetVertexColor(1, 1, 1, 1)
        return true
    end
    return false
end

local function UpdateButtonVisual()
    local b = state.btn
    if not b then
        return
    end

    b:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    local normal = b:GetNormalTexture()
    local pushed = b:GetPushedTexture()
    local applied = false

    if normal and SetButtonIconFromAtlas(normal, TRANSMOG_PRIMARY_ATLAS) then
        applied = true
        if pushed then
            SetButtonIconFromAtlas(pushed, TRANSMOG_PRIMARY_ATLAS)
            pushed:SetVertexColor(0.85, 0.85, 0.85, 1)
        end
    end

    if not applied then
        for _, atlasName in ipairs(TRANSMOG_BUTTON_ATLASES) do
            if normal and SetButtonIconFromAtlas(normal, atlasName) then
                applied = true
                if pushed then
                    SetButtonIconFromAtlas(pushed, atlasName)
                    pushed:SetVertexColor(0.85, 0.85, 0.85, 1)
                end
                break
            end
        end
    end

    if not applied then
        b:SetNormalTexture(TRANSMOG_HELMET_FALLBACK_ICON)
        b:SetPushedTexture(TRANSMOG_HELMET_FALLBACK_ICON)
        normal = b:GetNormalTexture()
        pushed = b:GetPushedTexture()
        if normal then
            normal:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            normal:SetVertexColor(0.92, 0.78, 1, 1)
        end
        if pushed then
            pushed:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            pushed:SetVertexColor(0.80, 0.66, 0.92, 1)
        end
    end
end

local function FrameHasMouse(frame)
    if not frame or not frame.IsMouseOver then
        return false
    end
    local ok, hovered = pcall(frame.IsMouseOver, frame)
    return ok and hovered == true
end

local function IsHoveringPortrait(playerFrame)
    if FrameHasMouse(state.btn) then
        return true
    end
    if FrameHasMouse(state.portraitHoverCatcher) then
        return true
    end
    if not playerFrame then
        return false
    end
    return FrameHasMouse(playerFrame.PortraitFrame) or FrameHasMouse(playerFrame.Portrait)
end

local function ShowButtonIfWanted(playerFrame, enabled)
    local b = state.btn
    if not b then
        return
    end
    if not enabled then
        b:Hide()
        if state.portraitHoverCatcher then
            state.portraitHoverCatcher:Hide()
        end
        return
    end
    local keepVisible = IsHoveringPortrait(playerFrame)
        or b:IsMouseOver()
        or IsTransmogFlyoutOpenFor()
    if keepVisible then
        b:Show()
    else
        b:Hide()
    end
end

local function SetupButtonScripts(b)
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnClick", function(self)
        if InCombatLockdown() then
            return
        end
        if not IsHoveringPortrait(state.frame) then
            return
        end
        ToggleTransmogFlyout(self)
    end)
    b:SetScript("OnEnter", function(self)
        if state.ArmTransmogWatcher then
            state.ArmTransmogWatcher()
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.ClearLines then
            GameTooltip:ClearLines()
        end
        GameTooltip:AddLine("Transmog Outfits", 1, 1, 1)
        GameTooltip:AddLine("Out of combat only. Hover the player portrait.", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("Click to activate an outfit.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function()
        GameTooltip:Hide()
        if state.ArmTransmogWatcher then
            state.ArmTransmogWatcher()
        end
        if state.frame and PTC.UpdateInteractionState then
            PTC.UpdateInteractionState(state.frame)
        end
    end)
end

function PTC.UpdateInteractionState(playerFrame)
    playerFrame = playerFrame or state.frame
    if not playerFrame or playerFrame.unit ~= "player" then
        return
    end
    if not state.btn then
        return
    end
    ApplyButtonLayout(playerFrame)
    local enabled = CanShowTransmogControl(playerFrame)
    local catcher = state.portraitHoverCatcher
    if catcher then
        if enabled then
            catcher:Show()
        else
            catcher:Hide()
        end
    end
    state.btn:EnableMouse(enabled)
    if not enabled then
        CloseTransmogFlyoutIfOpen()
    end
    ShowButtonIfWanted(playerFrame, enabled)
end

local function EnsureWatcher(playerFrame)
    if state.eventFrame then
        return
    end
    local evt = CreateFrame("Frame", nil, playerFrame)
    SafeRegisterEvent(evt, "PLAYER_REGEN_DISABLED")
    SafeRegisterEvent(evt, "PLAYER_REGEN_ENABLED")
    SafeRegisterEvent(evt, "PLAYER_ENTERING_WORLD")
    SafeRegisterEvent(evt, "TRANSMOG_COLLECTION_UPDATED")
    SafeRegisterEvent(evt, "TRANSMOG_OUTFITS_CHANGED")
    SafeRegisterEvent(evt, "TRANSMOG_DISPLAYED_OUTFIT_CHANGED")
    SafeRegisterEvent(evt, "SPELL_UPDATE_COOLDOWN")
    evt:SetScript("OnEvent", function(_, event)
        if not state.btn and state.frame then
            PTC.Initialize(state.frame)
        end
        if event == "SPELL_UPDATE_COOLDOWN" then
            if IsTransmogFlyoutOpenFor() then
                RefreshFlyoutRowVisuals()
            end
            return
        end
        if event == "TRANSMOG_OUTFITS_CHANGED"
            or event == "TRANSMOG_DISPLAYED_OUTFIT_CHANGED"
            or event == "TRANSMOG_COLLECTION_UPDATED" then
            RefreshOpenTransmogFlyout()
        end
        if state.frame and PTC.UpdateInteractionState then
            PTC.UpdateInteractionState(state.frame)
        end
    end)
    -- Demand-arm OnUpdate only while portrait hover or flyout is open.
    local function TransmogWatcher_OnUpdate(_, elapsed)
        state.hoverAccum = (state.hoverAccum or 0) + (elapsed or 0)
        if state.hoverAccum < WATCHER_INTERVAL then
            return
        end
        state.hoverAccum = 0
        local flyoutOpen = IsTransmogFlyoutOpenFor()
        local hovering = IsHoveringPortrait(state.frame)
        if state.frame and PTC.UpdateInteractionState then
            PTC.UpdateInteractionState(state.frame)
        end
        if not flyoutOpen and not hovering then
            evt:SetScript("OnUpdate", nil)
        end
    end
    state._transmogWatcherOnUpdate = TransmogWatcher_OnUpdate
    state.ArmTransmogWatcher = function()
        if evt:GetScript("OnUpdate") ~= TransmogWatcher_OnUpdate then
            state.hoverAccum = 0
            evt:SetScript("OnUpdate", TransmogWatcher_OnUpdate)
        end
    end
    -- Start disarmed; hover/enter scripts re-arm.
    evt:SetScript("OnUpdate", nil)
    state.eventFrame = evt
end

function PTC.Initialize(playerFrame)
    if not playerFrame or playerFrame.unit ~= "player" then
        return
    end
    state.frame = playerFrame
    EnsureWatcher(playerFrame)
    if not IsTransmogOutfitFeatureAvailable() then
        return
    end

    if not state.btn then
        local parent = playerFrame.outerBorderFrame or playerFrame.PortraitFrame or playerFrame
        local b = CreateFrame("Button", "FluxPlayerPortraitTransmogClick", parent)
        b:Hide()
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        if b.GetHighlightTexture then
            b:GetHighlightTexture():SetAlpha(0.22)
        end
        state.btn = b
    end

    UpdateButtonVisual()
    SetupButtonScripts(state.btn)
    EnsureFlyoutAnchorProxy()
    EnsureTransmogFlyoutHost()
    EnsureWatcher(playerFrame)

    if not state.hooked then
        state.hooked = true
        local origOuter = playerFrame.UpdateOuterBorder
        if origOuter and not playerFrame._fluxTransmogClickOuterHooked then
            playerFrame._fluxTransmogClickOuterHooked = true
            playerFrame.UpdateOuterBorder = function(self, ...)
                origOuter(self, ...)
                PTC.UpdateInteractionState(self)
            end
        end

        local origPart = playerFrame.UpdatePartition
        if origPart and not playerFrame._fluxTransmogClickPartitionHooked then
            playerFrame._fluxTransmogClickPartitionHooked = true
            playerFrame.UpdatePartition = function(self, ...)
                origPart(self, ...)
                PTC.UpdateInteractionState(self)
            end
        end
    end

    PTC.UpdateInteractionState(playerFrame)
end
