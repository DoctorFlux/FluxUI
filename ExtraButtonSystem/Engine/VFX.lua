--[[
    ExtraButtonSystem/Engine/VFX.lua
    Thin helpers for FluxButtons. Glow / cast / checked ownership lives in
    Actionbars EffectRouter + FluxEffectGlow / Cast / Checked / Refresh.
]]

FluxButtonVFX = FluxButtonVFX or {}
local VFX = FluxButtonVFX

local function EffectRefresh()
    return _G.FluxEffectRefresh
end

local function EffectCast()
    return _G.FluxEffectCast
end

local function EffectGlow()
    return _G.FluxEffectGlow
end

-- Shared cast-state mirror for legacy callers (engines own FluxBarCastState).
local FluxCastState = {
    activeReticle = nil,
    activeCast = nil,
    recentFinish = nil,
    recentInterrupt = nil,
}
VFX.CastState = FluxCastState
VFX.ProcGlowState = {}

local function SyncCastStateMirror()
    local bar = _G.FluxBarCastState
    if not bar then return end
    FluxCastState.activeCast = bar.activeCast
    FluxCastState.activeReticle = bar.activeReticle
    FluxCastState.recentFinish = bar.recentFinish
    FluxCastState.recentInterrupt = bar.recentInterrupt
end

function VFX.GetSpellIDForAction(action)
    if not action or action <= 0 then return nil end
    local actionType, id, subType = GetActionInfo(action)
    if actionType == "macro" then
        if subType == "spell" then return id end
        if subType == "item" then
            if id and C_Item and C_Item.GetItemSpell then
                local _, spellID = C_Item.GetItemSpell(id)
                if spellID then return spellID end
            end
            if GetItemSpell then
                local _, _, spellID = GetItemSpell(id)
                if spellID then return spellID end
            end
        end
        if C_ActionBar and C_ActionBar.GetSpell then
            return C_ActionBar.GetSpell(action)
        end
        if GetMacroSpell then
            local ok, sid = pcall(GetMacroSpell, id)
            if ok and sid then return sid end
        end
    elseif actionType == "spell" then
        return id
    elseif actionType == "item" then
        if C_ActionBar and C_ActionBar.GetSpell then
            return C_ActionBar.GetSpell(action)
        end
        if id and C_Item and C_Item.GetItemSpell then
            local _, spellID = C_Item.GetItemSpell(id)
            if spellID then return spellID end
        end
    end
    return nil
end

function VFX.IsSpellMatch(actionSpellID, targetSpellID)
    if not actionSpellID or not targetSpellID then return false end
    if actionSpellID == targetSpellID then return true end
    if _G.FluxAreSpellsEquivalent then
        return _G.FluxAreSpellsEquivalent(actionSpellID, targetSpellID)
    end
    local R = _G.FluxEffectRouter or _G.FluxSurfaceRouter
    if R and R.SameSpellFamily then
        return R.SameSpellFamily(actionSpellID, targetSpellID)
    end
    if FindBaseSpellByID then
        local baseAction = FindBaseSpellByID(actionSpellID)
        local baseTarget = FindBaseSpellByID(targetSpellID)
        if baseAction and baseAction == targetSpellID then return true end
        if baseTarget and baseTarget == actionSpellID then return true end
    end
    return false
end

function VFX.ShowOverlayGlow(widget)
    local G = EffectGlow()
    if G and G.RefreshFrame then
        G.RefreshFrame(widget, { forceShow = true, skipAnim = true })
        return
    end
    if ActionButtonSpellAlertManager and ActionButtonSpellAlertManager.ShowAlert then
        pcall(ActionButtonSpellAlertManager.ShowAlert, ActionButtonSpellAlertManager, widget)
    elseif ActionButton_ShowOverlayGlow then
        ActionButton_ShowOverlayGlow(widget)
    end
end

function VFX.HideOverlayGlow(widget)
    local G = EffectGlow()
    if G and G.ForceHide then
        G.ForceHide(widget)
        return
    end
    if ActionButtonSpellAlertManager and ActionButtonSpellAlertManager.HideAlert then
        pcall(ActionButtonSpellAlertManager.HideAlert, ActionButtonSpellAlertManager, widget)
    elseif ActionButton_HideOverlayGlow then
        ActionButton_HideOverlayGlow(widget)
    end
end

function VFX.FluxButtonMatchesSpellID(btn, targetSpellID)
    if not btn or not targetSpellID then return false end
    local sid = btn.SpellId
    if not sid and btn.GetSpellId then
        local ok, v = pcall(btn.GetSpellId, btn)
        if ok then sid = v end
    end
    if not sid and btn.Widget then
        if btn.Widget.GetSpellId then
            local ok, v = pcall(btn.Widget.GetSpellId, btn.Widget)
            if ok then sid = v end
        end
        sid = sid or btn.Widget.SpellId
    end
    if sid and VFX.IsSpellMatch(sid, targetSpellID) then return true end
    if btn.ItemId and C_Item and C_Item.GetItemSpell then
        local _, itemSpell = C_Item.GetItemSpell(btn.ItemId)
        if itemSpell and VFX.IsSpellMatch(itemSpell, targetSpellID) then return true end
    end
    return false
end

function VFX.GetCurrentDisplayedSpellID(widget)
    if not widget then return nil end
    if widget.GetSpellId then
        local ok, sid = pcall(widget.GetSpellId, widget)
        if ok and type(sid) == "number" and sid > 0 then return sid end
    end
    if type(widget.SpellId) == "number" and widget.SpellId > 0 then return widget.SpellId end
    local fb = widget.FluxButton or widget.ParentButton
    if fb then
        if type(fb.SpellId) == "number" and fb.SpellId > 0 then return fb.SpellId end
        if fb.ItemId and C_Item and C_Item.GetItemSpell then
            local _, sid = C_Item.GetItemSpell(fb.ItemId)
            if sid then return sid end
        end
    end
    return nil
end

function VFX.GetFluxButtonSpellID(actionButton)
    if not actionButton then return nil end
    return VFX.GetCurrentDisplayedSpellID(actionButton)
        or VFX.GetCurrentDisplayedSpellID(actionButton.FluxButton)
end

function VFX.ClearCastOverlay(widget)
    if not widget then return end
    widget._fluxCastLockSpellId = nil
    widget._fluxCastMigrateUntil = nil
    if _G.FluxPreDFForceClearOverlayVFX then
        pcall(_G.FluxPreDFForceClearOverlayVFX, widget)
    elseif _G.FluxPreDFSilentHideCast then
        pcall(_G.FluxPreDFSilentHideCast, widget)
    end
    if _G.FluxPostDFForceClearOverlayVFX then
        pcall(_G.FluxPostDFForceClearOverlayVFX, widget)
    end
    if widget.SpellCastAnimFrame and widget.SpellCastAnimFrame.Hide then
        pcall(widget.SpellCastAnimFrame.Hide, widget.SpellCastAnimFrame)
    end
    if widget.InterruptDisplay and widget.InterruptDisplay.Hide then
        pcall(widget.InterruptDisplay.Hide, widget.InterruptDisplay)
    end
    if widget.TargetReticleAnimFrame and widget.TargetReticleAnimFrame.Hide then
        pcall(widget.TargetReticleAnimFrame.Hide, widget.TargetReticleAnimFrame)
    end
end

--- Membership paint for standalone EBS widgets; ActionBars use EffectCast Exclusive.
function VFX.UpdateCastOverlay(widget)
    if not widget then return end
    -- Pre-DF injected fill: driven by FluxPreDFButtonVFX / EffectCast.
    if widget._fluxSpellCastAnimSlotFill then
        local Ca = EffectCast()
        if Ca and Ca.RefreshButton then
            local fb = widget.FluxButton or widget.ParentButton
            Ca.RefreshButton(fb or widget)
        end
        return
    end
    SyncCastStateMirror()
    local Ca = EffectCast()
    if Ca and Ca.RefreshButton then
        local fb = widget.FluxButton or widget.ParentButton
        Ca.RefreshButton(fb or widget)
        return
    end
    -- Fallback: clear if live spell no longer matches active cast.
    local sid = VFX.GetCurrentDisplayedSpellID(widget)
    local bar = _G.FluxBarCastState
    local active = bar and bar.activeCast
    if active and sid and VFX.IsSpellMatch(sid, active.spellID) then
        return
    end
    VFX.ClearCastOverlay(widget)
end

function VFX.UpdateAllButtonsCastOverlay()
    local Ca = EffectCast()
    if Ca and Ca.RefreshAll then
        Ca.RefreshAll()
        return
    end
    if FluxButtonCore and FluxButtonCore.GetActiveButtons then
        for _, btn in ipairs(FluxButtonCore.GetActiveButtons()) do
            if btn and btn.Widget then
                VFX.UpdateCastOverlay(btn.Widget)
            end
        end
    end
end

function VFX.InitProcGlowSystem()
    -- Glow events owned by FluxEffectGlow.
end

function VFX.UpdateAllFluxButtonGlows()
    local Refresh = EffectRefresh()
    if Refresh and Refresh.RefreshAll then
        Refresh.RefreshAll({ glow = true, checked = true, cast = false })
        return
    end
    local G = EffectGlow()
    if G and G.RefreshAll then
        G.RefreshAll()
    end
end

function VFX.InitCastingSystem()
    -- Cast state + UNIT_SPELLCAST owned by Pre/Post DF engines + EffectCast.
    -- Keep a light mirror so legacy VFX.CastState readers stay consistent.
    if VFX._castMirrorFrame then return end
    local f = CreateFrame("Frame")
    VFX._castMirrorFrame = f
    local function reg(ev)
        if f.RegisterUnitEvent then
            pcall(f.RegisterUnitEvent, f, ev, "player")
        else
            pcall(f.RegisterEvent, f, ev)
        end
    end
    reg("UNIT_SPELLCAST_START")
    reg("UNIT_SPELLCAST_STOP")
    reg("UNIT_SPELLCAST_CHANNEL_START")
    reg("UNIT_SPELLCAST_CHANNEL_STOP")
    reg("UNIT_SPELLCAST_SUCCEEDED")
    reg("UNIT_SPELLCAST_FAILED")
    reg("UNIT_SPELLCAST_INTERRUPTED")
    f:SetScript("OnEvent", function()
        SyncCastStateMirror()
        local Refresh = EffectRefresh()
        if Refresh and Refresh.RefreshCastAll then
            Refresh.RefreshCastAll()
        elseif EffectCast() and EffectCast().RefreshAll then
            EffectCast().RefreshAll()
        end
    end)
end

function VFX.SetupGlobalHooks()
    -- Intentionally empty: global mixin hooks taint Blizzard buttons.
end

function VFX.Initialize()
    VFX.InitProcGlowSystem()
    VFX.InitCastingSystem()
    VFX.SetupGlobalHooks()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, function()
                VFX.Initialize()
            end)
        else
            VFX.Initialize()
        end
    end
end)

FluxButtonGlobal = FluxButtonGlobal or {}
FluxButtonGlobal.UpdateAllFluxButtonGlows = VFX.UpdateAllFluxButtonGlows

