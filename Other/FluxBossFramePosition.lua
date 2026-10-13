-- FluxBossFramePosition.lua
-- Dock Blizzard boss frames under the debuff row and left of the objective tracker.
-- Default place only. No Edit Mode layout, no UnregisterSystem, no SetPoint hook.

local GAP_Y = -8
local CLEAR_X = 8

local function BossAnchor()
    if _G.BossTargetFrameContainer then
        return _G.BossTargetFrameContainer, true
    end
    if _G.Boss1TargetFrame then
        return _G.Boss1TargetFrame, false
    end
    return nil, false
end

local function DebuffAnchor()
    local buffs = _G.FluxBuffDebuffFrames
    if buffs and buffs._engineDebuffHost then
        return buffs._engineDebuffHost
    end
    return _G.DebuffFrame or _G.BuffFrame
end

local function ObjectiveAnchor()
    return _G.ObjectiveTrackerFrame or _G.QuestWatchFrame or _G.WatchFrame
end

local function EditModeOpen()
    local em = _G.EditModeManagerFrame
    if not em or not em.IsEditModeActive then
        return false
    end
    local ok, active = pcall(em.IsEditModeActive, em)
    return ok and active and true or false
end

local function Place(frame, point, relativeTo, relativePoint, x, y)
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    -- Anchoring to BuffFrame or DebuffFrame taints them. Combat UNIT_AURA then
    -- blocks DebuffFrame:SetSize on every client.
    if relativeTo == _G.DebuffFrame or relativeTo == _G.BuffFrame then
        return
    end
    if frame.ClearAllPointsBase then
        frame:ClearAllPointsBase()
    else
        frame:ClearAllPoints()
    end
    if frame.SetPointBase then
        frame:SetPointBase(point, relativeTo, relativePoint, x, y)
    else
        frame:SetPoint(point, relativeTo, relativePoint, x, y)
    end
end

local function UnderAuraOffsets(aura)
    local parent = _G.UIParent
    if not aura or not parent or not aura.GetRight or not aura.GetBottom then
        return nil
    end
    local auraRight, auraBottom = aura:GetRight(), aura:GetBottom()
    local parentRight, parentTop = parent:GetRight(), parent:GetTop()
    local scale = parent.GetEffectiveScale and parent:GetEffectiveScale() or 1
    if not auraRight or not auraBottom or not parentRight or not parentTop or not scale or scale == 0 then
        return nil
    end
    return (auraRight - parentRight) / scale, (auraBottom - parentTop) / scale + GAP_Y
end

local pendingCombat = false

local function Apply()
    local boss, isContainer = BossAnchor()
    if not boss then
        return
    end
    if EditModeOpen() then
        return
    end
    if InCombatLockdown() then
        pendingCombat = true
        return
    end
    local debuff = DebuffAnchor()
    if not debuff then
        return
    end

    if isContainer then
        boss.ignoreFramePositionManager = true
        boss.ignoreInLayout = true
    end

    local x, y = UnderAuraOffsets(debuff)
    if not x or not y then
        return
    end
    Place(boss, "TOPRIGHT", UIParent, "TOPRIGHT", x, y)

    local objective = ObjectiveAnchor()
    local bossRight = boss:GetRight()
    local objLeft = objective and objective:GetLeft()
    if bossRight and objLeft and bossRight > (objLeft - CLEAR_X) then
        local scale = UIParent:GetEffectiveScale() or 1
        if scale ~= 0 then
            x = x - ((bossRight - (objLeft - CLEAR_X)) / scale)
            Place(boss, "TOPRIGHT", UIParent, "TOPRIGHT", x, y)
        end
    end
end

local function ApplyNext()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, Apply)
    else
        Apply()
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if not pendingCombat then
            return
        end
        pendingCombat = false
    end
    ApplyNext()
end)

if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("EditMode.Exit", ApplyNext)
end

