-- UnitFrames/FluxUnitFrames_BigDebuffs.lua
-- Bridge to integrate BigDebuffs with FluxUI unit frames.
-- With portrait: debuff covers the portrait. Without portrait: same size/position as the class icon (or NPC corner slot).

local _, ns = ...
local UF = ns and ns.UnitFrames

if not BigDebuffs or not UF then
    return
end

--- Returns (anchor, parent[, noPortrait]) for BigDebuffs:AttachUnitFrame auto anchor.
-- noPortrait must be false/nil so BigDebuffs uses SetAllPoints(anchor) (cover portrait or class slot).
local function GetAnchorFluxUI(frameName)
    local frame = _G[frameName]
    if not frame then
        return
    end

    if UF.FrameUsesPortraitLayout(frame) and frame.PortraitFrame and frame.PortraitFrame:IsShown() then
        return frame.PortraitFrame, frame.PortraitFrame
    end

    if UF.LayoutBigDebuffsCornerPlaceholder then
        UF.LayoutBigDebuffsCornerPlaceholder(frame)
    end

    if frame.classIcon and frame.classIcon:IsShown() then
        return frame.classIcon, frame
    end

    if frame.specIcon and frame.specIcon:IsShown() then
        return frame.specIcon, frame
    end

    if frame._fluxBDCornerAnchor then
        return frame._fluxBDCornerAnchor, frame
    end

    return frame, frame, true
end

BigDebuffs.anchors["FluxUI"] = {
    func = GetAnchorFluxUI,
    units = {
        player = "FluxUnitFrame_player",
        target = "FluxUnitFrame_target",
        focus = "FluxUnitFrame_focus",
        pet = "FluxUnitFrame_pet",
    },
}

--- BigDebuffs sets parent to PortraitFrame (unnamed) or the Flux unit root (named). Walk up to FluxUnitFrame_*.
local function GetFluxUnitRootFromBigDebuffFrame(f)
    local p = f and f:GetParent()
    local depth = 0
    while p and depth < 12 do
        depth = depth + 1
        local n = p.GetName and p:GetName()
        if n and n:match("^FluxUnitFrame_") then
            return p
        end
        p = p:GetParent()
    end
end

-- BigDebuffsUnitFrameTemplate puts the icon on BACKGROUND; Flux cast bar fill uses ARTWORK, so the bar can paint over the
-- icon while stack/count (ARTWORK/OVERLAY) still show — "only the number" on top. Lift the icon when anchoring without portrait.
local function Flux_ApplyBigDebuffsIconDrawLayer(f, noPortraitLayout)
    local icon = f.icon
    if not icon or not icon.SetDrawLayer then
        return
    end
    if noPortraitLayout then
        icon:SetDrawLayer("ARTWORK", 0)
    else
        icon:SetDrawLayer("BACKGROUND", 7)
    end
end

--- Max frame level among Flux cast bar chrome (FluxBorder on bar + icon, spark, shield) — above castBar base, not spell name text.
local function Flux_GetFluxCastBarChromeTopFrameLevel(cb)
    if not cb or not cb.GetFrameLevel then
        return 0
    end
    local m = cb:GetFrameLevel()
    local function bump(fr)
        if fr and fr.GetFrameLevel then
            m = math.max(m, fr:GetFrameLevel())
        end
    end
    bump(cb.BorderFrame)
    if cb.BorderFrame and cb.BorderFrame.FluxBorderFrame then
        bump(cb.BorderFrame.FluxBorderFrame)
    end
    bump(cb.SparkFrame)
    bump(cb.IconFrame)
    bump(cb.IconBorder)
    if cb.IconBorder and cb.IconBorder.FluxBorderFrame then
        bump(cb.IconBorder.FluxBorderFrame)
    end
    bump(cb.ShieldOverlay)
    bump(cb.StagePipHolder)
    return m
end

-- BigDebuffs sets SetFrameLevel(99) for non-Blizzard anchors; tune stacking vs Flux chrome and cast bar.
local function Flux_AdjustBigDebuffsPortraitLevel(unit)
    local f = BigDebuffs.UnitFrames and BigDebuffs.UnitFrames[unit]
    if not f or f.blizzard or not f.anchor then
        return
    end
    local root = GetFluxUnitRootFromBigDebuffFrame(f)
    if not root then
        return
    end

    -- Portrait: parent is PortraitFrame; sit just under Flux portrait border, above the 3D model, under threat when shown.
    if UF.FrameUsesPortraitLayout(root) and root.PortraitFrame and root.PortraitFrame:IsShown() then
        local pf = root.PortraitFrame
        local bf = pf.FluxBorderFrame
        local lv
        if bf then
            lv = bf:GetFrameLevel() - 1
        else
            lv = pf:GetFrameLevel() + 9
        end
        if root.ThreatBar and root._fluxThreatBarMode ~= "between" and root.ThreatBar:IsShown() then
            lv = math.min(lv, root.ThreatBar:GetFrameLevel() - 1)
        end
        lv = math.max(pf:GetFrameLevel() + 3, lv)
        f:SetFrameLevel(lv)
        Flux_ApplyBigDebuffsIconDrawLayer(f, false)
        return
    end

    -- No portrait: BigDebuffs parents to the unit root; above outer chrome, and above the cast bar when present.
    local ob = root.outerBorderFrame
    if not ob then
        local al = f.anchor.GetFrameLevel and f.anchor:GetFrameLevel()
        if not al then
            al = 0
        end
        f:SetFrameLevel(al + 6)
        Flux_ApplyBigDebuffsIconDrawLayer(f, true)
        return
    end

    local obLv = ob:GetFrameLevel()
    -- LayoutBigDebuffsCornerPlaceholder uses ob+35; combat icon frame uses ob+22 — stay above that whole subtree as a root sibling.
    local highChrome = obLv + 35
    local lv = highChrome
    local cb = root.CastBar
    if cb then
        -- Cast bar BorderFrame matches castBar+1; FluxBorder atlas sits higher — use measured chrome top + margin (not textHolder+50).
        local castChromeTop = Flux_GetFluxCastBarChromeTopFrameLevel(cb)
        lv = math.max(highChrome, castChromeTop + 2)
    end
    lv = math.max(obLv + 1, lv)
    f:SetFrameLevel(lv)
    Flux_ApplyBigDebuffsIconDrawLayer(f, true)
end

function UF.SyncBigDebuffsFrameLevelForUnitFrame(frame)
    if not frame or not frame.GetName then
        return
    end
    local n = frame:GetName()
    if not n then
        return
    end
    local unit = n:match("^FluxUnitFrame_(.+)$")
    if not unit then
        return
    end
    Flux_AdjustBigDebuffsPortraitLevel(unit)
end

hooksecurefunc(BigDebuffs, "AttachUnitFrame", function(_, unit)
    Flux_AdjustBigDebuffsPortraitLevel(unit)
end)

-- Enable all aura categories so defensive, CC, offensive, roots, etc. can all display
-- (BigDebuffs shows the highest-priority one at a time; this ensures none are filtered out)
local CATEGORIES = {
    "cc", "interrupts", "immunities", "immunities_spells",
    "buffs_defensive", "buffs_offensive", "buffs_other",
    "debuffs_offensive", "roots", "buffs_speed_boost",
}
local uf = BigDebuffs.db.profile.unitFrames
for i = 1, #CATEGORIES do
    if uf[CATEGORIES[i]] ~= nil then
        uf[CATEGORIES[i]] = true
    end
end

-- Defer Refresh to next frame to avoid blocking addon load
C_Timer.After(0, function()
    if BigDebuffs and BigDebuffs.Refresh then
        BigDebuffs:Refresh()
    end
end)
