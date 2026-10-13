-- UnitFrames/FluxUnitFrames_PlayerSpecClick.lua
-- Class/spec icon click: dual talent group toggle or specialization / respec / rune flyout (player only, OOC).
-- Flyouts use ExtraButtonSystem FlyoutEngine (same TGA tube as transmog / mounts).
local addonName, ns = ...
ns.PlayerSpecClick = ns.PlayerSpecClick or {}

local API = ns.API
local PSC = ns.PlayerSpecClick

local SPEC_FLYOUT_PROXY_SIZE_MULT = 0.82
local SPEC_FLYOUT_PROXY_EXTRA_DOWN = 7

local SUBMENU_PAD = 5
local SUBMENU_MAX = 24

local state = {
    frame = nil,
    hitBtn = nil,
    flyoutAnchorProxy = nil,
    flyoutMode = nil,
    hooked = false,
    respecGlowHooked = false,
    inventoryBumpHooked = false,
}

local CloseSpecFlyoutIfOpen

local function GetFlyout()
    local Flux = ns.Flux
    return Flux and Flux.EBS and Flux.EBS.Flyout
end

local function HasRespecProfiles()
    local fr = _G.FluxRespec
    if not fr or not fr.GetProfileNames then
        return false
    end
    local names = fr.GetProfileNames()
    return type(names) == "table" and #names > 0
end

local function RetailPostDfSpecFlyoutUI()
    local fr = _G.FluxRespec
    if not (fr and fr.Compat and fr.Compat.HasTalentLoadouts and fr.Compat.HasTalentLoadouts()) then
        return false
    end
    local mode = API.GetPlayerSpecSwitchMode and API.GetPlayerSpecSwitchMode() or "none"
    return mode == "flyout"
end

local function GetProfileNamesForSpec(targetSpecId)
    local out = {}
    if type(targetSpecId) ~= "number" then
        return out
    end
    local fr = _G.FluxRespec
    if not fr or not fr.GetProfileNames or not fr.GetProfile then
        return out
    end
    for _, pname in ipairs(fr.GetProfileNames()) do
        local p = fr.GetProfile(pname)
        local t = p and p.talents
        if t and t.kind == "loadout" and t.specID == targetSpecId then
            out[#out + 1] = pname
        end
    end
    return out
end

local function IsSoDRunePresetAvailable()
    local fr = _G.FluxRespec
    return fr and fr.Compat and fr.Compat.IsSoD and fr.Compat.IsSoD()
        and fr.RunePresets ~= nil
end

-- ---------------------------------------------------------------------------
-- ExtraButtonSystem flyout host (same tube as transmog)
-- ---------------------------------------------------------------------------

local function SpecFlyoutOpts()
    return {
        direction = "UP",
        hideArrow = true,
        matchAnchorScale = true,
        adoptHostCast = false,
        anchorFrame = state.flyoutAnchorProxy,
    }
end

local function EnsureFlyoutAnchorProxy()
    if state.flyoutAnchorProxy then
        return state.flyoutAnchorProxy
    end
    local p = CreateFrame("Frame", "FluxPlayerSpecFlyoutAnchorProxy", UIParent)
    p:Hide()
    p:EnableMouse(false)
    p:SetFrameStrata("BACKGROUND")
    p:SetFrameLevel(0)
    state.flyoutAnchorProxy = p
    return p
end

local function FlyoutHost()
    return EnsureFlyoutAnchorProxy()
end

local function EnsureSpecFlyoutHost()
    local Flyout = GetFlyout()
    local host = FlyoutHost()
    if not Flyout or not host or not Flyout.BindHost then
        return nil
    end
    Flyout.BindHost(host, SpecFlyoutOpts())
    return Flyout
end

local function GetHitBtnUIParentRect(hitBtn)
    if not hitBtn or not hitBtn.GetScaledRect then
        return nil
    end
    local l, b, w, h = hitBtn:GetScaledRect()
    if not l or not b or not w or not h then
        return nil
    end
    local uiScale = UIParent:GetEffectiveScale() or 1
    if uiScale <= 0 then
        uiScale = 1
    end
    return l / uiScale, b / uiScale, w / uiScale, h / uiScale
end

local function GetSpecFlyoutLayoutRect(hitBtn)
    local l, b, w, h = GetHitBtnUIParentRect(hitBtn)
    if not l or not b or not w or not h then
        return nil
    end
    local nw = math.max(1, w * SPEC_FLYOUT_PROXY_SIZE_MULT)
    local nh = math.max(1, h * SPEC_FLYOUT_PROXY_SIZE_MULT)
    local left = l + (w - nw) / 2
    local bottom = b + (h - nh) / 2 - SPEC_FLYOUT_PROXY_EXTRA_DOWN
    return left, bottom, nw, nh
end

local function SyncFlyoutAnchorProxy(hitBtn)
    if not hitBtn then
        return false
    end
    EnsureFlyoutAnchorProxy()
    local p = state.flyoutAnchorProxy
    local left, bottom, width, height = GetSpecFlyoutLayoutRect(hitBtn)
    if left and bottom and width and height then
        p:ClearAllPoints()
        p:SetSize(width, height)
        p:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
        p:Show()
        return true
    end
    local ok = pcall(function()
        p:ClearAllPoints()
        p:SetPoint("CENTER", hitBtn, "CENTER", 0, 0)
        local w = tonumber(hitBtn:GetWidth()) or 24
        local h = tonumber(hitBtn:GetHeight()) or 24
        p:SetSize(math.max(16, w), math.max(16, h))
        p:Show()
    end)
    return ok == true
end

local function EnsureRowActiveBorder(row)
    if row._fluxSpecActiveBorder then
        return row._fluxSpecActiveBorder
    end
    local border = row:CreateTexture(nil, "OVERLAY")
    border:SetAtlas("bags-glow-white", true)
    border:SetVertexColor(0.18, 0.95, 0.28, 0.95)
    border:Hide()
    row._fluxSpecActiveBorder = border
    return border
end

local function RefreshFlyoutRowVisuals()
    local Flyout = GetFlyout()
    local host = FlyoutHost()
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
        elseif kid and kid._fluxSpecActiveBorder then
            kid._fluxSpecActiveBorder:Hide()
        end
    end
end

local function EnsurePopupHideHook()
    local Flyout = GetFlyout()
    local host = FlyoutHost()
    local popup = Flyout and host and Flyout.GetPopup and Flyout.GetPopup(host)
    if not popup or popup._fluxSpecProfileSubHideHooked then
        return
    end
    popup._fluxSpecProfileSubHideHooked = true
    popup:HookScript("OnHide", function()
        PSC.HideProfileSubmenu()
        state.flyoutMode = nil
    end)
end

-- ---------------------------------------------------------------------------
-- Retail: profile submenu to the right of a spec flyout cell
-- ---------------------------------------------------------------------------

local profileSubFrame = nil
local profileSubHideTimer = nil

local function CancelProfileSubmenuHideTimer()
    if profileSubHideTimer then
        profileSubHideTimer:Cancel()
        profileSubHideTimer = nil
    end
end

function PSC.HideProfileSubmenu()
    CancelProfileSubmenuHideTimer()
    if profileSubFrame then
        profileSubFrame:Hide()
    end
end

local function ScheduleProfileSubmenuHide()
    CancelProfileSubmenuHideTimer()
    profileSubHideTimer = C_Timer.NewTimer(0.2, function()
        profileSubHideTimer = nil
        local f = profileSubFrame
        if not f or not f:IsShown() then
            return
        end
        if f:IsMouseOver() then
            return
        end
        for _, b in ipairs(f._rows or {}) do
            if b:IsShown() and b:IsMouseOver() then
                return
            end
        end
        f:Hide()
    end)
end

local function ProfileSubmenuRow_OnEnter(self)
    CancelProfileSubmenuHideTimer()
    local pname = self.profileName
    if not pname then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if GameTooltip.ClearLines then
        GameTooltip:ClearLines()
    end
    GameTooltip:AddLine(pname, 1, 1, 1)
    local fr = _G.FluxRespec
    if fr and fr.GetProfile and fr.Equipment and fr.Equipment.GetProfileGearIssueKind then
        local prof = fr.GetProfile(pname)
        local k = prof and fr.Equipment.GetProfileGearIssueKind(prof)
        if k and k ~= "" then
            GameTooltip:AddLine(("Gear: %s"):format(tostring(k)), 0.78, 0.78, 0.78, true)
        end
    end
    GameTooltip:AddLine("Click to arm and load (same as Respec).", 0.65, 0.65, 0.65, true)
    GameTooltip:Show()
end

local function ProfileSubmenuRow_OnLeave()
    GameTooltip:Hide()
    ScheduleProfileSubmenuHide()
end

local function EnsureProfileSubmenuFrame()
    if profileSubFrame then
        return profileSubFrame
    end
    local f = CreateFrame("Frame", "FluxPlayerSpecProfileSubFlyout", UIParent, "BackdropTemplate")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(5600)
    f:EnableMouse(true)
    f:Hide()
    pcall(function()
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.96)
        f:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    end)
    f:SetScript("OnEnter", CancelProfileSubmenuHideTimer)
    f:SetScript("OnLeave", ScheduleProfileSubmenuHide)
    local rows = {}
    for i = 1, SUBMENU_MAX do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(32, 32)
        b:RegisterForClicks("LeftButtonUp")
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        local ht = b:GetHighlightTexture()
        if ht then
            ht:SetAlpha(0.25)
        end
        local tex = b:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        b.icon = tex
        b:SetScript("OnEnter", ProfileSubmenuRow_OnEnter)
        b:SetScript("OnLeave", ProfileSubmenuRow_OnLeave)
        b:SetScript("OnClick", function()
            if InCombatLockdown() then
                return
            end
            local pname = b.profileName
            local fr = _G.FluxRespec
            if not pname or not fr or not fr.SelectActiveProfileOnly then
                return
            end
            if not fr.SelectActiveProfileOnly(pname, true) then
                return
            end
            PSC.HideProfileSubmenu()
            CloseSpecFlyoutIfOpen()
            if fr.RunLoadProfileButtonAction then
                fr.RunLoadProfileButtonAction()
            end
        end)
        rows[i] = b
    end
    f._rows = rows
    profileSubFrame = f
    return f
end

local function ShowProfileSubmenuForAnchor(anchorBtn, _, profiles)
    if not anchorBtn or not profiles or #profiles < 1 then
        return
    end
    local res = _G.FluxRespec
    if not res then
        return
    end
    local f = EnsureProfileSubmenuFrame()
    CancelProfileSubmenuHideTimer()

    local cw, ch = 40, 40
    if anchorBtn.GetWidth and anchorBtn.GetHeight then
        local aw, ah = anchorBtn:GetWidth(), anchorBtn:GetHeight()
        if type(aw) == "number" and type(ah) == "number" and aw > 0 and ah > 0 then
            cw = math.floor(aw)
            ch = math.floor(ah)
        end
    end

    local gap = 4
    local n = math.min(#profiles, SUBMENU_MAX)
    local rows = f._rows
    local prev
    for i = 1, SUBMENU_MAX do
        local row = rows[i]
        if i <= n then
            local pname = profiles[i]
            row.profileName = pname
            row:SetSize(cw, ch)
            row.icon:SetTexture((res.GetIcon and res.GetIcon(pname)) or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row:ClearAllPoints()
            if not prev then
                row:SetPoint("TOPLEFT", f, "TOPLEFT", SUBMENU_PAD, -SUBMENU_PAD)
            else
                row:SetPoint("LEFT", prev, "RIGHT", gap, 0)
            end
            row:Show()
            prev = row
        else
            row:Hide()
            row.profileName = nil
        end
    end
    local w = SUBMENU_PAD * 2 + n * cw + math.max(0, n - 1) * gap
    local h = SUBMENU_PAD * 2 + ch
    f:SetSize(w, h)
    f:SetParent(UIParent)
    f:ClearAllPoints()
    f:SetScale((anchorBtn.GetEffectiveScale and anchorBtn:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1))
    f:SetPoint("TOPLEFT", anchorBtn, "TOPRIGHT", 4, 0)
    f:Show()
end

-- ---------------------------------------------------------------------------
-- Engine button lists
-- ---------------------------------------------------------------------------

local function CurrentSpecIndex()
    if not GetSpecialization then
        return nil
    end
    local ok, idx = pcall(GetSpecialization)
    if ok and type(idx) == "number" then
        return idx
    end
    return nil
end

local function BuildSpecFlyoutButtons()
    local buttons = {}
    local fr = _G.FluxRespec
    local entries
    if fr and fr.Compat and fr.Compat.HasTalentLoadouts and fr.Compat.HasTalentLoadouts()
        and HasRespecProfiles()
        and API.GetPlayerSpecFlyoutEntriesIncludingActive then
        entries = API.GetPlayerSpecFlyoutEntriesIncludingActive()
    else
        entries = API.GetPlayerSpecFlyoutEntries and API.GetPlayerSpecFlyoutEntries() or {}
    end
    entries = entries or {}
    local currentIdx = CurrentSpecIndex()
    local showSub = RetailPostDfSpecFlyoutUI() and HasRespecProfiles()
    for _, e in ipairs(entries) do
        if e and type(e.index) == "number" then
            local specIndex = e.index
            local specId = e.specId
            local name = e.name
            local icon = e.icon
            local profiles = (showSub and type(specId) == "number") and GetProfileNamesForSpec(specId) or {}
            buttons[#buttons + 1] = {
                icon = icon,
                name = name,
                skipFavorite = true,
                isActive = currentIdx ~= nil and currentIdx == specIndex,
                onClick = function(_, mouse)
                    if mouse and mouse ~= "LeftButton" then
                        return
                    end
                    if InCombatLockdown() then
                        return
                    end
                    if currentIdx and currentIdx == specIndex then
                        return
                    end
                    if API.TrySetPlayerSpecialization then
                        API.TrySetPlayerSpecialization(specIndex)
                    end
                end,
                onEnter = function(kid)
                    CancelProfileSubmenuHideTimer()
                    GameTooltip:SetOwner(kid, "ANCHOR_RIGHT", 4, 4)
                    if GameTooltip.ClearLines then
                        GameTooltip:ClearLines()
                    end
                    GameTooltip:SetText(name or "", 1, 1, 1)
                    if #profiles > 0 then
                        GameTooltip:AddLine("Saved profiles for this spec open in a row to the right.", 0.72, 0.72, 0.72, true)
                        ShowProfileSubmenuForAnchor(kid, specId, profiles)
                    else
                        GameTooltip:AddLine("Click to switch specialization.", 0.78, 0.78, 0.78, true)
                    end
                    GameTooltip:Show()
                end,
                onLeave = function()
                    ScheduleProfileSubmenuHide()
                end,
            }
        end
    end
    return buttons
end

local function BuildProfileFlyoutButtons()
    local buttons = {}
    local fr = _G.FluxRespec
    if not fr or not fr.GetProfileNames then
        return buttons
    end
    local active = fr.GetActiveName and fr.GetActiveName()
    for _, pname in ipairs(fr.GetProfileNames()) do
        local icon = (fr.GetIcon and fr.GetIcon(pname)) or "Interface\\Icons\\INV_Misc_QuestionMark"
        local issueKind
        if fr.GetProfile and fr.Equipment and fr.Equipment.GetProfileGearIssueKind then
            local prof = fr.GetProfile(pname)
            if prof then
                issueKind = fr.Equipment.GetProfileGearIssueKind(prof)
            end
        end
        local name = pname
        buttons[#buttons + 1] = {
            icon = icon,
            name = name,
            skipFavorite = true,
            isActive = active ~= nil and active == pname,
            onClick = function(_, mouse)
                if mouse and mouse ~= "LeftButton" then
                    return
                end
                if InCombatLockdown() then
                    return
                end
                if not fr.SelectActiveProfileOnly or not fr.SelectActiveProfileOnly(pname, true) then
                    return
                end
                CloseSpecFlyoutIfOpen()
                if fr.RunLoadProfileButtonAction then
                    fr.RunLoadProfileButtonAction()
                end
            end,
            onEnter = function(kid)
                GameTooltip:SetOwner(kid, "ANCHOR_RIGHT", 4, 4)
                if GameTooltip.ClearLines then
                    GameTooltip:ClearLines()
                end
                GameTooltip:SetText(name, 1, 1, 1)
                if issueKind and issueKind ~= "" then
                    GameTooltip:AddLine(("Gear: %s"):format(tostring(issueKind)), 0.78, 0.78, 0.78, true)
                end
                GameTooltip:AddLine("Click to arm and load (same as Respec).", 0.65, 0.65, 0.65, true)
                GameTooltip:Show()
            end,
        }
    end
    return buttons
end

local function FirstRuneIcon(preset)
    local runes = preset and preset.runes
    if type(runes) ~= "table" then
        return nil
    end
    local ENGRAVABLE = (_G.FluxRespec and _G.FluxRespec.Runes and _G.FluxRespec.Runes.ENGRAVABLE_SLOTS) or {}
    for i = 1, #ENGRAVABLE do
        local slotID = ENGRAVABLE[i]
        local rune = slotID and runes[slotID]
        if rune and rune.iconTexture then
            return rune.iconTexture
        end
    end
    for _, rune in pairs(runes) do
        if type(rune) == "table" and rune.iconTexture then
            return rune.iconTexture
        end
    end
    return nil
end

local function BuildRuneFlyoutButtons()
    local buttons = {}
    local RP = _G.FluxRespec and _G.FluxRespec.RunePresets
    if not RP or not RP.GetPresetNames then
        return buttons
    end
    local names = RP.GetPresetNames()
    local active = RP.GetActivePreset and RP.GetActivePreset() or "default"
    for _, n in ipairs(names) do
        local preset = RP.GetPreset and RP.GetPreset(n)
        local icon = FirstRuneIcon(preset) or "Interface\\Icons\\INV_Misc_Rune_01"
        buttons[#buttons + 1] = {
            icon = icon,
            name = n,
            skipFavorite = true,
            isActive = active ~= nil and active == n,
            onClick = function(_, mouse)
                if mouse and mouse ~= "LeftButton" then
                    return
                end
                if InCombatLockdown() then
                    return
                end
                CloseSpecFlyoutIfOpen()
                if RP.ApplyAndStartEngrave then
                    RP.ApplyAndStartEngrave(n)
                elseif RP.Apply then
                    RP.Apply(n)
                    local Runes = _G.FluxRespec and _G.FluxRespec.Runes
                    if Runes and Runes.HasActiveQueue and Runes.HasActiveQueue() and Runes.CastNext then
                        Runes.CastNext()
                    end
                end
            end,
            onEnter = function(kid)
                GameTooltip:SetOwner(kid, "ANCHOR_RIGHT", 4, 4)
                if GameTooltip.ClearLines then
                    GameTooltip:ClearLines()
                end
                GameTooltip:SetText(n, 1, 1, 1)
                GameTooltip:AddLine("Click to load this rune preset.", 0.72, 0.72, 0.72, true)
                GameTooltip:Show()
            end,
        }
    end
    return buttons
end

local function AfterFlyoutShown()
    EnsurePopupHideHook()
    RefreshFlyoutRowVisuals()
end

local function ToggleEngineFlyout(mode, buttons)
    if InCombatLockdown() then
        return
    end
    if type(buttons) ~= "table" or #buttons < 1 then
        return
    end
    local Flyout = EnsureSpecFlyoutHost()
    local host = FlyoutHost()
    if not Flyout or not host then
        return
    end
    local open = Flyout.IsOpen and Flyout.IsOpen(host)
    if open and state.flyoutMode == mode then
        if Flyout.Close then
            Flyout.Close(host)
        end
        PSC.HideProfileSubmenu()
        return
    end
    if not SyncFlyoutAnchorProxy(state.hitBtn) then
        return
    end
    Flyout.SetButtons(host, buttons, SpecFlyoutOpts())
    if not open and Flyout.Toggle then
        Flyout.Toggle(host)
    end
    state.flyoutMode = mode
    AfterFlyoutShown()
end

CloseSpecFlyoutIfOpen = function()
    PSC.HideProfileSubmenu()
    local Flyout = GetFlyout()
    local host = state.flyoutAnchorProxy
    if Flyout and host and Flyout.Close then
        Flyout.Close(host)
    end
    state.flyoutMode = nil
end

local function ToggleSpecFlyout()
    ToggleEngineFlyout("spec", BuildSpecFlyoutButtons())
end

local function ToggleProfileFlyout()
    ToggleEngineFlyout("profile", BuildProfileFlyoutButtons())
end

local function ToggleRunePresetFlyout()
    ToggleEngineFlyout("rune", BuildRuneFlyoutButtons())
end

--- Dual-talent toggle or retail specialization flyout (legacy left-click behavior).
local function HandleSpecClickOnly()
    if not API.GetPlayerSpecSwitchMode then
        return
    end
    local mode = API.GetPlayerSpecSwitchMode()
    if mode == "none" then
        return
    end
    if mode == "dual" then
        CloseSpecFlyoutIfOpen()
        if API.TogglePlayerDualTalentGroup then
            API.TogglePlayerDualTalentGroup()
        end
        return
    end
    if mode == "flyout" then
        ToggleSpecFlyout()
    end
end

--- Left-click when Respec profiles exist: load steps only after arming via this button's profile flyout; else open flyout.
local function OnRespecProfileLeftClick()
    local R = _G.FluxRespec
    if not R or not R.GetActiveName then
        return
    end
    local name = R.GetActiveName()
    if not name then
        ToggleProfileFlyout()
        return
    end
    local armed = R.IsUnitFrameRespecArmedForActiveProfile and R.IsUnitFrameRespecArmedForActiveProfile()
    if not armed then
        ToggleProfileFlyout()
        return
    end
    local applying = R.Apply and R.Apply.IsRunning and R.Apply.IsRunning()
    local engraveMode = R.Apply and R.Apply.IsEngraveButtonMode and R.Apply.IsEngraveButtonMode()
    if applying and not engraveMode then
        return
    end
    local cpName, cpStep
    if R.GetLoadCheckpoint then
        cpName, cpStep = R.GetLoadCheckpoint()
    end
    local hasCheckpoint = cpName and cpStep and name == cpName and not applying
    local _, kind = "Load Profile", "noop"
    if R.Apply and R.Apply.NextStepLabel then
        _, kind = R.Apply.NextStepLabel(name)
    end
    if not hasCheckpoint and kind == "noop" then
        ToggleProfileFlyout()
        return
    end
    if R.RunLoadProfileButtonAction then
        R.RunLoadProfileButtonAction()
    end
end

--- When glow is active, any click should advance the load/engrave.
local function TryGlowAction()
    local R = _G.FluxRespec
    if not R then return false end
    if R.IsUnitFrameRespecArmedForActiveProfile and R.IsUnitFrameRespecArmedForActiveProfile() then
        local name = R.GetActiveName and R.GetActiveName()
        if name then
            local applying = R.Apply and R.Apply.IsRunning and R.Apply.IsRunning()
            local engraveMode = R.Apply and R.Apply.IsEngraveButtonMode and R.Apply.IsEngraveButtonMode()
            if applying and not engraveMode then
                return true
            end
            if R.RunLoadProfileButtonAction then
                R.RunLoadProfileButtonAction()
                return true
            end
        end
    end
    if R.RunePresets and R.RunePresets.ShouldShowUnitFrameRuneGlow
        and R.RunePresets.ShouldShowUnitFrameRuneGlow() then
        if R.RunePresets.AdvanceEngrave then
            R.RunePresets.AdvanceEngrave()
            return true
        end
    end
    return false
end

local function OnIconClick(_, button)
    button = button or "LeftButton"
    if InCombatLockdown() then
        return
    end

    local glowActive = false
    local R = _G.FluxRespec
    if R then
        if R.IsUnitFrameRespecArmedForActiveProfile and R.IsUnitFrameRespecArmedForActiveProfile() then
            local name = R.GetActiveName and R.GetActiveName()
            if name then
                local applying = R.Apply and R.Apply.IsRunning and R.Apply.IsRunning()
                local cpName, cpStep
                if R.GetLoadCheckpoint then cpName, cpStep = R.GetLoadCheckpoint() end
                local hasCp = cpName and cpStep and cpName == name and not applying
                local _, kind = "Load Profile", "noop"
                if R.Apply and R.Apply.NextStepLabel then _, kind = R.Apply.NextStepLabel(name) end
                if applying or hasCp or kind ~= "noop" then
                    glowActive = true
                end
            end
        end
        if not glowActive and R.RunePresets and R.RunePresets.ShouldShowUnitFrameRuneGlow
            and R.RunePresets.ShouldShowUnitFrameRuneGlow() then
            glowActive = true
        end
    end

    if glowActive then
        TryGlowAction()
        return
    end

    if RetailPostDfSpecFlyoutUI() then
        if button == "LeftButton" or button == "RightButton" then
            HandleSpecClickOnly()
        end
        return
    end
    if HasRespecProfiles() then
        if button == "MiddleButton" and IsSoDRunePresetAvailable() then
            ToggleRunePresetFlyout()
            return
        end
        if button == "RightButton" then
            HandleSpecClickOnly()
            return
        end
        if button == "LeftButton" then
            OnRespecProfileLeftClick()
            return
        end
        return
    end
    if IsSoDRunePresetAvailable() and button == "LeftButton" then
        ToggleRunePresetFlyout()
        return
    end
    if button ~= "LeftButton" then
        return
    end
    HandleSpecClickOnly()
end

--- Tooltip body for the player spec hit button; call again while hovering to refresh next-step text.
local function ShowPlayerSpecHitTooltip(b)
    local mode = API.GetPlayerSpecSwitchMode and API.GetPlayerSpecSwitchMode() or "none"
    local prof = HasRespecProfiles()
    if mode == "none" and not prof then
        return
    end
    GameTooltip:SetOwner(b, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", b, "TOPRIGHT", 8, 0)
    if GameTooltip.ClearLines then
        GameTooltip:ClearLines()
    end
    if prof then
        GameTooltip:AddLine("Respec profiles", 1, 1, 1)
        local R = _G.FluxRespec
        local an = R and R.GetActiveName and R.GetActiveName()
        local armed = R and R.IsUnitFrameRespecArmedForActiveProfile and R.IsUnitFrameRespecArmedForActiveProfile()
        local applying = R and R.Apply and R.Apply.IsRunning and R.Apply.IsRunning()
        local engraveMode = R and R.Apply and R.Apply.IsEngraveButtonMode and R.Apply.IsEngraveButtonMode()
        local hasCp = false
        if an and R and R.GetLoadCheckpoint then
            local cpName, cpStep = R.GetLoadCheckpoint()
            hasCp = cpName and cpStep and cpName == an
        end
        local stepLine, stepKind
        if an and R and R.Apply and R.Apply.NextStepLabel then
            stepLine, stepKind = R.Apply.NextStepLabel(an)
        end
        if armed and an and stepLine and stepLine ~= "" then
            GameTooltip:AddLine(stepLine, 0.95, 0.92, 0.65, false)
        elseif not armed and an then
            GameTooltip:AddLine("Pick a profile here or in the Respec window to arm glow & load on this button.", 0.72, 0.72, 0.72, true)
        end
        if RetailPostDfSpecFlyoutUI() then
            if applying and not engraveMode then
                GameTooltip:AddLine("Automatic step in progress — updates when it finishes.", 0.75, 0.75, 0.75, true)
            elseif engraveMode and applying then
                GameTooltip:AddLine("Use the Respec window Load button to engrave / advance the queue.", 0.85, 0.85, 0.85, true)
            elseif hasCp then
                GameTooltip:AddLine("Use the Respec window Load button to resume saved load progress.", 0.85, 0.85, 0.85, true)
            end
            GameTooltip:AddLine("Left or right-click: specialization flyout. Hover a spec to list Respec profiles for that spec (if any).", 0.85, 0.85, 0.85, true)
        else
            if not an then
                GameTooltip:AddLine("Left-click: choose a profile.", 0.85, 0.85, 0.85, true)
            elseif not armed then
                GameTooltip:AddLine("Left-click: open profile list (or pick a profile in Respec to arm this button).", 0.85, 0.85, 0.85, true)
            elseif applying and not engraveMode then
                GameTooltip:AddLine("Automatic step in progress — updates when it finishes.", 0.75, 0.75, 0.75, true)
            elseif engraveMode and applying then
                GameTooltip:AddLine("Left-click: same as Respec Load (engrave / advance queue).", 0.85, 0.85, 0.85, true)
            elseif hasCp then
                GameTooltip:AddLine("Left-click: resume saved load progress.", 0.85, 0.85, 0.85, true)
            elseif stepKind == "noop" then
                GameTooltip:AddLine("Left-click: open profile list or switch profile.", 0.85, 0.85, 0.85, true)
            else
                GameTooltip:AddLine("Left-click: advance load (same as Respec Load).", 0.85, 0.85, 0.85, true)
            end
            if mode == "dual" then
                GameTooltip:AddLine("Right-click: switch dual talent specialization.", 0.85, 0.85, 0.85, true)
            elseif mode == "flyout" then
                GameTooltip:AddLine("Right-click: choose game specialization.", 0.85, 0.85, 0.85, true)
            end
            if IsSoDRunePresetAvailable() then
                GameTooltip:AddLine("Middle-click: rune presets.", 0.85, 0.85, 0.85, true)
            end
        end
    elseif mode == "dual" then
        GameTooltip:SetText("Switch talent specialization", 1, 1, 1)
    else
        GameTooltip:SetText("Choose specialization", 1, 1, 1)
    end
    GameTooltip:Show()
end

local function PlayerSpecHitTooltip_OnUpdate(self, elapsed)
    self._fluxTTAccum = (self._fluxTTAccum or 0) + elapsed
    if self._fluxTTAccum < 0.12 then
        return
    end
    self._fluxTTAccum = 0
    if not self:IsMouseOver() then
        return
    end
    if InCombatLockdown() then
        return
    end
    if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
        ShowPlayerSpecHitTooltip(self)
    end
end

local function SetupPlayerSpecHitButtonScripts(b)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    b:SetScript("OnClick", OnIconClick)
    b:SetScript("OnEnter", function(self)
        if InCombatLockdown() then
            return
        end
        local mode = API.GetPlayerSpecSwitchMode and API.GetPlayerSpecSwitchMode() or "none"
        local prof = HasRespecProfiles()
        if mode == "none" and not prof then
            return
        end
        self._fluxTTAccum = 0
        ShowPlayerSpecHitTooltip(self)
        self:SetScript("OnUpdate", PlayerSpecHitTooltip_OnUpdate)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetScript("OnUpdate", nil)
        self._fluxTTAccum = nil
        GameTooltip:Hide()
    end)
end

--- One hit target: spans class+spec when both visible (by screen left/right), else matches the single icon.
local function UpdateOverlayLayout(playerFrame)
    if not playerFrame or not state.hitBtn then
        return
    end
    local ob = playerFrame.outerBorderFrame
    local lvl = (ob and ob:GetFrameLevel() or 0) + 25
    state.hitBtn:SetFrameLevel(lvl)

    local c = playerFrame.classIcon
    local s = playerFrame.specIcon
    if not c or not s then
        return
    end

    state.hitBtn:ClearAllPoints()
    local cOk = c:IsShown()
    local sOk = s:IsShown()

    if cOk and sOk then
        local cl, cr = c:GetLeft(), c:GetRight()
        local sl, sr = s:GetLeft(), s:GetRight()
        if cl and cr and sl and sr then
            if cl <= sl then
                state.hitBtn:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
                state.hitBtn:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 0, 0)
            else
                state.hitBtn:SetPoint("TOPLEFT", s, "TOPLEFT", 0, 0)
                state.hitBtn:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, 0)
            end
            state.hitBtn:Show()
        else
            state.hitBtn:SetAllPoints(c)
            state.hitBtn:Show()
        end
    elseif cOk then
        state.hitBtn:SetAllPoints(c)
        state.hitBtn:Show()
    elseif sOk then
        state.hitBtn:SetAllPoints(s)
        state.hitBtn:Show()
    else
        state.hitBtn:Hide()
    end

    local Flyout = GetFlyout()
    local host = state.flyoutAnchorProxy
    if Flyout and host and Flyout.IsOpen and Flyout.IsOpen(host) then
        SyncFlyoutAnchorProxy(state.hitBtn)
        if Flyout.PlacePopup then
            Flyout.PlacePopup(host)
        end
    end
end

local function EnsureRespecGlowHooks()
    if state.respecGlowHooked or not _G.FluxRespec or not _G.FluxRespec.On then
        return
    end
    state.respecGlowHooked = true
    local R = _G.FluxRespec
    local function bump()
        if state.frame and state.frame.unit == "player" then
            PSC.UpdateInteractionState(state.frame)
        end
    end
    R.On("APPLY_START", bump)
    R.On("APPLY_DONE", bump)
    R.On("RUNE_QUEUE_CHANGED", bump)
    R.On("ACTIVE_CHANGED", bump)
    R.On("PROFILES_CHANGED", bump)
    R.On("PROFILE_SAVED", bump)
    R.On("RUNE_PRESET_CHANGED", bump)
    R.On("RUNE_PRESET_APPLIED", bump)
end

local function EnsureInventoryBumpHooks()
    if state.inventoryBumpHooked then
        return
    end
    state.inventoryBumpHooked = true
    local f = CreateFrame("Frame")
    f:RegisterEvent("BAG_UPDATE_DELAYED")
    f:RegisterEvent("BANKFRAME_OPENED")
    f:RegisterEvent("BANKFRAME_CLOSED")
    f:SetScript("OnEvent", function(_, event)
        if event == "BAG_UPDATE_DELAYED" then
            local disp = _G.FluxBagChangeDispatcher
            if disp and disp.IsEquipPulseActive and disp.IsEquipPulseActive() then
                return
            end
        end
        if state.frame and state.frame.unit == "player" then
            PSC.UpdateInteractionState(state.frame)
        end
    end)
end

local function TryClearUnitFrameArmedWhenFullyIdle()
    local R = _G.FluxRespec
    if not R or not R.IsUnitFrameRespecArmedForActiveProfile or not R.IsUnitFrameRespecArmedForActiveProfile() then
        return
    end
    local name = R.GetActiveName()
    if not name then
        return
    end
    if R.Apply and R.Apply.IsRunning and R.Apply.IsRunning() then
        return
    end
    local cpName, cpStep
    if R.GetLoadCheckpoint then
        cpName, cpStep = R.GetLoadCheckpoint()
    end
    if cpName and cpStep and cpName == name then
        return
    end
    if R.Apply and R.Apply.NextStepLabel then
        local _, kind = R.Apply.NextStepLabel(name)
        if kind == "noop" and R.ClearUnitFrameRespecArmed then
            R.ClearUnitFrameRespecArmed()
        end
    end
end

local function UpdateRespecPendingGlow()
    local btn = state.hitBtn
    if not btn then
        return
    end
    TryClearUnitFrameArmedWhenFullyIdle()
    local show = false
    local R = _G.FluxRespec
    if R and R.IsUnitFrameRespecArmedForActiveProfile and R.IsUnitFrameRespecArmedForActiveProfile() then
        local name = R.GetActiveName and R.GetActiveName()
        if name then
            local applying = R.Apply and R.Apply.IsRunning and R.Apply.IsRunning()
            if applying then
                show = true
            else
                local cpName, cpStep
                if R.GetLoadCheckpoint then
                    cpName, cpStep = R.GetLoadCheckpoint()
                end
                if cpName and cpStep and cpName == name then
                    show = true
                elseif R.Apply and R.Apply.NextStepLabel then
                    local _, kind = R.Apply.NextStepLabel(name)
                    if kind ~= "noop" then
                        show = true
                    end
                end
            end
        end
    end
    if not show and R and R.RunePresets and R.RunePresets.ShouldShowUnitFrameRuneGlow
        and R.RunePresets.ShouldShowUnitFrameRuneGlow() then
        show = true
    end
    local LBG = LibStub and LibStub("LibButtonGlow-1.0", true)
    if not LBG then
        return
    end
    if show and LBG.ShowOverlayGlow then
        pcall(LBG.ShowOverlayGlow, btn)
    elseif LBG.HideOverlayGlow then
        pcall(LBG.HideOverlayGlow, btn)
    end
end

function PSC.UpdateInteractionState(playerFrame)
    playerFrame = playerFrame or state.frame
    if not playerFrame or playerFrame.unit ~= "player" then
        return
    end
    EnsureRespecGlowHooks()
    EnsureInventoryBumpHooks()
    local mode = "none"
    if not InCombatLockdown() and API.GetPlayerSpecSwitchMode then
        mode = API.GetPlayerSpecSwitchMode()
    end
    if InCombatLockdown() then
        CloseSpecFlyoutIfOpen()
    end
    local enable = not InCombatLockdown() and ((mode ~= "none") or HasRespecProfiles() or IsSoDRunePresetAvailable())
    if state.hitBtn then
        state.hitBtn:EnableMouse(enable)
    end
    UpdateOverlayLayout(playerFrame)
    UpdateRespecPendingGlow()
end

local function OnTalentOrSpecChanged()
    CloseSpecFlyoutIfOpen()
end

local function OnCombatEvent()
    PSC.UpdateInteractionState(state.frame)
end

function PSC.Initialize(playerFrame)
    if not playerFrame or playerFrame.unit ~= "player" then
        return
    end
    EnsureRespecGlowHooks()
    if state.frame == playerFrame and state.hitBtn then
        SetupPlayerSpecHitButtonScripts(state.hitBtn)
        PSC.UpdateInteractionState(playerFrame)
        return
    end
    state.frame = playerFrame
    local outer = playerFrame.outerBorderFrame
    if not outer or not playerFrame.classIcon or not playerFrame.specIcon then
        return
    end

    local function makeBtn(name)
        local b = CreateFrame("Button", name, outer)
        b:SetFrameStrata(outer:GetFrameStrata())
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:GetHighlightTexture():SetAlpha(0.25)
        SetupPlayerSpecHitButtonScripts(b)
        return b
    end

    if not state.hitBtn then
        state.hitBtn = makeBtn("FluxPlayerClassSpecIconClick")
    else
        SetupPlayerSpecHitButtonScripts(state.hitBtn)
    end

    EnsureFlyoutAnchorProxy()
    EnsureSpecFlyoutHost()

    if not state.hooked then
        state.hooked = true
        local evt = CreateFrame("Frame", nil, playerFrame)
        evt:RegisterEvent("PLAYER_REGEN_DISABLED")
        evt:RegisterEvent("PLAYER_REGEN_ENABLED")
        evt:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        evt:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        evt:RegisterEvent("PLAYER_TALENT_UPDATE")
        evt:SetScript("OnEvent", function(_, event)
            if event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
                OnTalentOrSpecChanged()
            end
            OnCombatEvent()
        end)
    end

    local orig = playerFrame.UpdateOuterBorder
    if orig and not playerFrame._fluxSpecClickOuterHooked then
        playerFrame._fluxSpecClickOuterHooked = true
        playerFrame.UpdateOuterBorder = function(self, ...)
            orig(self, ...)
            UpdateOverlayLayout(self)
            PSC.UpdateInteractionState(self)
        end
    end

    local origPart = playerFrame.UpdatePartition
    if origPart and not playerFrame._fluxSpecClickPartitionHooked then
        playerFrame._fluxSpecClickPartitionHooked = true
        playerFrame.UpdatePartition = function(self, ...)
            origPart(self, ...)
            UpdateOverlayLayout(self)
            PSC.UpdateInteractionState(self)
        end
    end

    UpdateOverlayLayout(playerFrame)
    PSC.UpdateInteractionState(playerFrame)

    _G.FluxUnitFrames_PlayerSpecClick_Refresh = function()
        PSC.UpdateInteractionState(state.frame)
    end
end
