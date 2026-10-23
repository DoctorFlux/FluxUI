-- Coordinator: apply Flux vs Blizzard unit frame toggles without /reload.
local addonName, ns = ...
local UF = ns.UnitFrames

local function wantFlux(unit)
    return FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ShouldUseFlux(unit)
end

local function workBlocked()
    return InCombatLockdown()
end

local function blizzardFrameForUnit(unit)
    if unit == "player" then
        return _G.PlayerFrame
    elseif unit == "target" then
        return _G.TargetFrame
    elseif unit == "focus" then
        return _G.FocusFrame
    elseif unit == "pet" then
        return _G.PetFrame
    elseif unit == "targettarget" then
        local tf = _G.TargetFrame
        return tf and tf.totFrame
    elseif unit == "focustarget" then
        return _G.FocusFrameToT
    end
    return nil
end

local function objectType(obj)
    if not obj or not obj.GetObjectType then
        return nil
    end
    local ok, t = pcall(obj.GetObjectType, obj)
    if ok then
        return t
    end
    return nil
end

local function MuteWidgetScripts(widget)
    if not widget then
        return
    end
    widget._fluxUnitFrameMuted = true
    if widget.UnregisterAllEvents then
        pcall(widget.UnregisterAllEvents, widget)
    end
end

local function MutePortraitWidget(widget)
    if not widget then
        return
    end
    MuteWidgetScripts(widget)
    if widget.ClearModel then
        pcall(widget.ClearModel, widget)
    end
end

local function MuteStatusBarWidget(widget)
    if not widget then
        return
    end
    MuteWidgetScripts(widget)
    -- Do not replace UpdateTextStringWithValues. UnitFrameHealthBar_OnUpdate and
    -- UnitFrameHealthBar_Update call it, then UnitFrameHealPredictionBars_Update.
    -- A Flux wrapper taints that rest of the call. On Midnight (12.x) the heal
    -- absorb compare (health < UnitGetTotalHealAbsorbs) is a secret and errors
    -- when the stack is tainted. Blizzard's own text update can read secrets
    -- as long as we leave the function untainted. Keep OnUpdate/events off instead.
    if widget.EnableMouse and widget.IsMouseEnabled and widget:IsMouseEnabled() and not widget._fluxSecretTextMouse then
        widget._fluxSecretTextMouse = true
        widget:EnableMouse(false)
    end
    if widget.GetScript and widget.SetScript then
        -- OnUpdate must stay clear. UnitFrameHealthBar_OnUpdate calls UpdateTextString
        -- and then compares secret heal absorbs. SetUnit puts OnUpdate back later;
        -- drop it again on every mute pass.
        local saved = widget._fluxMutedScripts
        if not saved then
            saved = {}
            widget._fluxMutedScripts = saved
            local scripts = { "OnValueChanged", "OnMinMaxChanged", "OnSizeChanged", "OnUpdate" }
            for i = 1, #scripts do
                local name = scripts[i]
                local fn = widget:GetScript(name)
                if type(fn) == "function" then
                    saved[name] = fn
                    pcall(widget.SetScript, widget, name, nil)
                end
            end
        else
            local onUpdate = widget:GetScript("OnUpdate")
            if type(onUpdate) == "function" then
                if not saved.OnUpdate then
                    saved.OnUpdate = onUpdate
                end
                pcall(widget.SetScript, widget, "OnUpdate", nil)
            end
        end
    end
    local loss = widget.AnimatedLossBar
    if loss then
        MuteWidgetScripts(loss)
    end
end

local function ShouldSkipMuteChild(child)
    local name = child and child.GetName and child:GetName()
    if type(name) ~= "string" then
        return false
    end
    if name == "PetFrame" or name == "TargetFrame" or name == "FocusFrame"
        or name == "FocusFrameToT" then
        return true
    end
    if name:find("^PartyMemberFrame", 1) or name:find("^CompactRaid", 1) then
        return true
    end
    return false
end

local function CollectMuteVisuals(frame, list, depth)
    if not frame or depth > 5 then
        return
    end
    local t = objectType(frame)
    if t == "StatusBar" then
        list[#list + 1] = frame
    elseif t == "PlayerModel" or t == "CinematicModel" or t == "DressUpModel" then
        list[#list + 1] = frame
    end
    if frame.GetChildren then
        local ok, children = pcall(function()
            return { frame:GetChildren() }
        end)
        if ok then
            for i = 1, #children do
                local child = children[i]
                if not ShouldSkipMuteChild(child) then
                    CollectMuteVisuals(child, list, depth + 1)
                end
            end
        end
    end
end

local function muteBlizzardUnitFrameVisuals(frame)
    frame._fluxUnitFrameMuted = true
    local list = frame._fluxMutedVisuals
    if not list then
        list = {}
        frame._fluxMutedVisuals = list
        CollectMuteVisuals(frame, list, 0)
        -- Named classic / nested retail portraits (textures or models).
        if frame.portrait then
            list[#list + 1] = frame.portrait
        end
        if frame.Portrait then
            list[#list + 1] = frame.Portrait
        end
    end
    for i = 1, #list do
        local widget = list[i]
        local t = objectType(widget)
        if t == "StatusBar" then
            MuteStatusBarWidget(widget)
        else
            MutePortraitWidget(widget)
        end
    end
end

local function unmuteBlizzardUnitFrameVisuals(frame)
    frame._fluxUnitFrameMuted = nil
    local list = frame._fluxMutedVisuals
    if not list then
        return
    end
    for i = 1, #list do
        local widget = list[i]
        if widget then
            widget._fluxUnitFrameMuted = nil
            if type(widget._fluxSecretTextOrig) == "function" then
                widget.UpdateTextStringWithValues = widget._fluxSecretTextOrig
                widget._fluxSecretTextOrig = nil
            end
            if widget._fluxSecretTextMouse and widget.EnableMouse then
                widget._fluxSecretTextMouse = nil
                widget:EnableMouse(true)
            end
            if widget._fluxMutedScripts and widget.SetScript then
                local saved = widget._fluxMutedScripts
                widget._fluxMutedScripts = nil
                for name, fn in pairs(saved) do
                    pcall(widget.SetScript, widget, name, fn)
                end
            end
            if widget.Show then
                pcall(widget.Show, widget)
            end
        end
    end
    frame._fluxMutedVisuals = nil
end

-- Hidden player overlays still receive cast/health events at alpha 0. Their Lua
-- fill calculation divides by secret max power/health. Suspend only these unused
-- overlays, retaining the native vehicle/art events and the original handlers.
-- Registration snapshots live outside the Blizzard frame and preserve unit filters.
local playerOverlayEvents = {
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_MAXHEALTH", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED",
    "UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "UNIT_MAX_HEALTH_MODIFIERS_CHANGED",
}
local savedPlayerOverlayEvents
local savedPlayerVisuals = {}
local playerVisualKeys = { "PlayerFrameContent", "PlayerFrameContainer" }
local function KeepIndependentMouseChild(child)
    return ShouldSkipMuteChild(child)
        or child == _G.PlayerBottomManagedFrameContainer
        or child == _G.PlayerFrameBottomManagedFramesContainer
        or child == _G.TotemFrame
        or child == _G.PlayerCastingBarFrame
        or child == _G.CastingBarFrame
        or child == ns.PlayerFrame
end

function FluxUnitFrames_SetBlizzardPlayerPredictionMuted(muted)
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(function() FluxUnitFrames_SetBlizzardPlayerPredictionMuted(muted) end,
            "unitframes.player.prediction")
        return
    end
    local frame = _G.PlayerFrame
    if not frame or not frame.IsEventRegistered then return end
    local blizz = ns.Flux and ns.Flux.Blizz
    if blizz and blizz.SetMouseSuppressed then
        blizz.SetMouseSuppressed(frame, muted, KeepIndependentMouseChild)
    end
    -- Alpha 0 still runs both bars' OnUpdate secret comparisons. The stock
    -- visual containers have no show/hide scripts, and native player art never
    -- shows them explicitly. Hide those ancestors to stop unused art and bars while
    -- preserving every original script and the root's player/vehicle events.
    -- In particular, do not detach and later reattach native OnUpdate scripts.
    if not workBlocked() then
        if muted then
            for _, key in ipairs(playerVisualKeys) do
                local content = frame[key]
                if content then
                    if savedPlayerVisuals[content] == nil then
                        savedPlayerVisuals[content] = content:IsShown()
                    end
                    if content:IsShown() then content:Hide() end
                end
            end
        else
            for content, shown in pairs(savedPlayerVisuals) do
                if shown then content:Show() end
                savedPlayerVisuals[content] = nil
            end
        end
    end
    if muted then
        savedPlayerOverlayEvents = savedPlayerOverlayEvents or {}
        for _, event in ipairs(playerOverlayEvents) do
            local registration = { frame:IsEventRegistered(event) }
            if registration[1] then
                -- Native vehicle changes may re-register a different unit.
                savedPlayerOverlayEvents[event] = registration
                frame:UnregisterEvent(event)
            end
        end
    elseif savedPlayerOverlayEvents then
        for event, registration in pairs(savedPlayerOverlayEvents) do
            if #registration > 1 then
                frame:RegisterUnitEvent(event, unpack(registration, 2))
            else
                frame:RegisterEvent(event)
            end
        end
        savedPlayerOverlayEvents = nil
    end
end

-- PlayerFrame (and other unit frames) are Edit Mode systems. Hide() taints
-- shown-state; wrapping SetParent taints ApplySystemAnchor → SetClampRectInsets
-- on spec/level (PLAYER_SPECIALIZATION_CHANGED → UpdateLayoutInfo).
-- Keep the parent shown at alpha 0. Other unit frames also mute child visuals;
-- the native player frame must keep its events and child scripts intact for auras.
local function muteBlizzardUnitFrame(frame)
    if not frame then
        return
    end
    if frame == _G.PlayerFrame then
        -- Native auras depend on this frame's unit, including vehicle changes.
        -- Keep native vehicle/art events and child scripts. Cast/health overlays
        -- belong to the visible Flux frame while the Blizzard artwork is hidden.
        FluxUnitFrames_SetBlizzardPlayerPredictionMuted(true)
        if not workBlocked() and frame.SetAlpha then
            frame:SetAlpha(0)
        end
        return
    end
    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end
    -- Child bar/portrait Hide + SetScript nil is not the Edit Mode shown-state taint.
    muteBlizzardUnitFrameVisuals(frame)
    if workBlocked() then
        return
    end
    if frame.SetAlpha then
        frame:SetAlpha(0)
    end
end

local function unmuteBlizzardUnitFrame(frame)
    if not frame or not frame.SetAlpha then
        return
    end
    if workBlocked() then
        return
    end
    if frame == _G.PlayerFrame then
        FluxUnitFrames_SetBlizzardPlayerPredictionMuted(false)
        frame:SetAlpha(1)
        return
    end
    unmuteBlizzardUnitFrameVisuals(frame)
    frame:SetAlpha(1)
end

local healthRefreshHooked = false
local function EnsureMutedHealthBarStaysQuiet()
    if healthRefreshHooked or type(hooksecurefunc) ~= "function" then
        return
    end
    if type(_G.UnitFrameHealthBar_RefreshUpdateEvent) ~= "function" then
        return
    end
    healthRefreshHooked = true
    -- SetUnit / VARIABLES_LOADED put UnitFrameHealthBar_OnUpdate back. That
    -- function ends in UnitFrameHealPredictionBars_Update, which compares a
    -- secret heal absorb. Leaving OnUpdate off keeps that compare on Blizzard's
    -- untainted path (it never runs while the Flux frame is the one shown).
    hooksecurefunc("UnitFrameHealthBar_RefreshUpdateEvent", function(self)
        if not self or not self._fluxUnitFrameMuted or not self.SetScript or not self.GetScript then
            return
        end
        if self.UnregisterAllEvents then
            pcall(self.UnregisterAllEvents, self)
        end
        local onUpdate = self:GetScript("OnUpdate")
        if type(onUpdate) ~= "function" then
            return
        end
        local saved = self._fluxMutedScripts
        if saved and not saved.OnUpdate then
            saved.OnUpdate = onUpdate
        end
        pcall(self.SetScript, self, "OnUpdate", nil)
    end)
end

local resuppressFrame
local function ensureResuppressWatch()
    if resuppressFrame then
        return
    end
    resuppressFrame = CreateFrame("Frame")
    resuppressFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    resuppressFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
    resuppressFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
    pcall(resuppressFrame.RegisterEvent, resuppressFrame, "PLAYER_SPECIALIZATION_CHANGED")
    resuppressFrame:SetScript("OnEvent", function()
        local function reassert()
            if FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled then
                FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled()
            end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, reassert)
        else
            reassert()
        end
    end)
end

--- Hide / mute a Blizzard unit frame while the Flux replacement is active.
function FluxUnitFrames_SuppressBlizzardUnitFrame(unit)
    -- Keep native controls and displays until the replacement finished setup.
    if not UF or not UF.IsInitialized or not UF.IsInitialized(unit) then return end
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(function() FluxUnitFrames_SuppressBlizzardUnitFrame(unit) end,
            "unitframes.suppress." .. unit)
        return
    end
    if workBlocked() then
        UF.DeferProtected("suppress." .. unit, function() FluxUnitFrames_SuppressBlizzardUnitFrame(unit) end)
        return
    end
    local frame = blizzardFrameForUnit(unit)
    if not frame or not wantFlux(unit) then
        return
    end

    ensureResuppressWatch()
    EnsureMutedHealthBarStaysQuiet()
    muteBlizzardUnitFrame(frame)
end

function FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled()
    local units = {
        "player", "target", "targettarget", "focus", "focustarget", "pet",
    }
    for i = 1, #units do
        if wantFlux(units[i]) then
            FluxUnitFrames_SuppressBlizzardUnitFrame(units[i])
        end
    end
    local CB = ns.CastBar
    if CB and CB.SyncBlizzardCastBars then
        CB.SyncBlizzardCastBars()
    end
end

local function refreshBlizzardPlayerSide()
    if wantFlux("player") then
        FluxUnitFrames_SuppressBlizzardUnitFrame("player")
        return
    end
    unmuteBlizzardUnitFrame(_G.PlayerFrame)
end

local function refreshBlizzardFocusSide()
    if wantFlux("focus") then
        FluxUnitFrames_SuppressBlizzardUnitFrame("focus")
    else
        unmuteBlizzardUnitFrame(_G.FocusFrame)
        local ff = _G.FocusFrame
        if ff and ff.Update then
            pcall(function()
                ff:Update()
            end)
        end
    end
    if wantFlux("focustarget") then
        FluxUnitFrames_SuppressBlizzardUnitFrame("focustarget")
    else
        unmuteBlizzardUnitFrame(_G.FocusFrameToT)
        local fft = _G.FocusFrameToT
        if fft and fft.Update then
            pcall(function()
                fft:Update()
            end)
        end
    end
end

local function refreshBlizzardPetSide()
    if wantFlux("pet") then
        FluxUnitFrames_SuppressBlizzardUnitFrame("pet")
        return
    end
    local pf = _G.PetFrame
    unmuteBlizzardUnitFrame(pf)
    if pf then
        if pf.Update then
            pcall(function()
                pf:Update()
            end)
        end
        pcall(function()
            if _G.PetFrame_Update then
                PetFrame_Update(pf)
            end
        end)
    end
end

--- Refresh Blizzard default unit frames and Flux replacement frames after a Flux vs Blizzard toggle
--- so visibility, layout, and unit data stay in sync (immediate + next-frame pass).
function FluxUnitFrames_RefreshBothSidesAfterToggle()
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(FluxUnitFrames_RefreshBothSidesAfterToggle)
        return
    end
    refreshBlizzardPlayerSide()

    if FluxUnitFrames_RefreshTargetAndTotTogether then
        FluxUnitFrames_RefreshTargetAndTotTogether()
    else
        local tf = _G.TargetFrame
        if wantFlux("target") then
            FluxUnitFrames_SuppressBlizzardUnitFrame("target")
        elseif tf then
            unmuteBlizzardUnitFrame(tf)
            if tf.Update then
                pcall(function()
                    tf:Update()
                end)
            end
        end
        if wantFlux("targettarget") then
            FluxUnitFrames_SuppressBlizzardUnitFrame("targettarget")
        elseif tf and tf.totFrame then
            unmuteBlizzardUnitFrame(tf.totFrame)
            if tf.totFrame.Update then
                pcall(function()
                    tf.totFrame:Update()
                end)
            end
        end
    end

    refreshBlizzardFocusSide()
    refreshBlizzardPetSide()

    pcall(function()
        if UIParent_ManageFramePositions then
            UIParent_ManageFramePositions()
        end
    end)

    -- Edit Mode / layout managers can re-show Blizzard frames after the manage pass.
    FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled()

    if not UF then
        return
    end

    local function refreshFlux(fr, unit)
        if not fr or not unit or not wantFlux(unit) then
            return
        end
        if UF.UpdateHealth then
            pcall(UF.UpdateHealth, fr, unit)
        end
        if UF.UpdatePower then
            pcall(UF.UpdatePower, fr, unit)
        end
        if UF.UpdatePortrait then
            pcall(UF.UpdatePortrait, fr, unit)
        end
        if fr.UpdatePartition then
            pcall(fr.UpdatePartition, fr)
        end
        if fr.UpdateOuterBorder then
            pcall(fr.UpdateOuterBorder, fr)
        end
        if UF.UpdateAuras and (unit == "target" or unit == "focus") then
            pcall(UF.UpdateAuras, fr)
        end
    end

    refreshFlux(ns.PlayerFrame, "player")
    if not FluxUnitFrames_RefreshTargetAndTotTogether then
        refreshFlux(ns.TargetFrame, "target")
        refreshFlux(ns.TargetOfTargetFrame, "targettarget")
    end
    refreshFlux(ns.FocusFrame, "focus")
    refreshFlux(ns.FocusTargetFrame, "focustarget")
    refreshFlux(ns.PetFrame, "pet")

    if ns.PetTargetFrame and wantFlux("pettarget") then
        if UF.UpdateHealth then
            pcall(UF.UpdateHealth, ns.PetTargetFrame, "pettarget")
        end
        if ns.PetTargetFrame.UpdatePartition then
            pcall(ns.PetTargetFrame.UpdatePartition, ns.PetTargetFrame)
        end
        if ns.PetTargetFrame.UpdateOuterBorder then
            pcall(ns.PetTargetFrame.UpdateOuterBorder, ns.PetTargetFrame)
        end
    end
end

function FluxUnitFrames_ApplyFluxVsBlizzardRuntime()
    if not FluxUnitFrames_ShouldUseFlux then
        return
    end
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(FluxUnitFrames_ApplyFluxVsBlizzardRuntime)
        return
    end
    if workBlocked() then
        UF.DeferProtected("runtime.all", FluxUnitFrames_ApplyFluxVsBlizzardRuntime)
        return
    end

    local function want(unit)
        return FluxUnitFrames_ShouldUseFlux(unit)
    end

    if FluxUnitFrames_ApplyRuntimePlayer then
        FluxUnitFrames_ApplyRuntimePlayer(want("player"))
    end
    if FluxUnitFrames_ApplyRuntimeTarget then
        FluxUnitFrames_ApplyRuntimeTarget(want("target"))
    end
    if FluxUnitFrames_ApplyRuntimeFocus then
        FluxUnitFrames_ApplyRuntimeFocus(want("focus"))
    end
    if FluxUnitFrames_ApplyRuntimeToT then
        FluxUnitFrames_ApplyRuntimeToT(want("targettarget"))
    end
    if FluxUnitFrames_ApplyRuntimeFocusTarget then
        FluxUnitFrames_ApplyRuntimeFocusTarget(want("focustarget"))
    end
    if FluxUnitFrames_ApplyRuntimePet then
        FluxUnitFrames_ApplyRuntimePet(want("pet"))
    end
    if FluxUnitFrames_ApplyRuntimePetTarget then
        FluxUnitFrames_ApplyRuntimePetTarget(want("pettarget"))
    end

    FluxUnitFrames_RefreshBothSidesAfterToggle()
    if ns.ForeverComboPoints then
        ns.ForeverComboPoints.RefreshAll(true)
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, FluxUnitFrames_RefreshBothSidesAfterToggle)
        C_Timer.After(0.5, FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled)
    end
end

-- Re-mute Blizzard frames when the default UI re-applies layout (common on DF+ / Midnight Edit Mode).
local guardFrame = CreateFrame("Frame")
guardFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
guardFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
guardFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
guardFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
guardFrame:RegisterEvent("UNIT_PET")
pcall(guardFrame.RegisterEvent, guardFrame, "EDIT_MODE_LAYOUT_APPLIED")
if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("EditMode.Exit", function()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled)
        else
            FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled()
        end
    end)
end
guardFrame:SetScript("OnEvent", function(_, event, arg1)
    if workBlocked() then
        return
    end
    if event == "UNIT_PET" and arg1 ~= "player" then
        return
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled)
    else
        FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled()
    end
end)

if C_Timer and C_Timer.After then
    C_Timer.After(1, FluxUnitFrames_SuppressAllBlizzardUnitFramesWhenFluxEnabled)
end
