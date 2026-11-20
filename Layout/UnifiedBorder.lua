--[[
    Layout/UnifiedBorder.lua
    Unified border system that dynamically covers all UI elements based on minirow visibility
    
    Features:
    - Atlas border without backdrop covering all elements
    -     Action Bar Area Border:
      - Border: NonCombatGrid → ActionBar → CombatGrid → TrinketMenu (stops at TrinketMenu)
      - Gap backdrop: Fills TrinketMenu right → FluxWindowFrame left when window shown (matches grid style)
    - StatusBar/MicroMenu Border:
      - Covers FluxMicroMenu → FluxStatusBarContainer
    - Automatically updates when components move or resize
]]

FluxUnifiedBorder = FluxUnifiedBorder or {}
local UnifiedBorder = FluxUnifiedBorder

-- Local references
local borderFrame = nil
local statusBarBorderFrame = nil
local gapBackdropFrame = nil -- Fills TrinketMenu→WindowFrame gap (backdrop only, matches grid style)
local actionStripInfoGapBackdropFrame = nil -- Fills NonCombat→Combat gap when Info is placed off the action strip
local updateElapsed = 0
local UPDATE_INTERVAL = 0.2 -- Update every 0.2 seconds
local initialized = false

-- ============================================================================
-- COMPONENT DETECTION
-- ============================================================================

local function NamedFrame(...)
    for i = 1, select("#", ...) do
        local frame = _G[select(i, ...)]
        if frame then
            return frame
        end
    end
    return nil
end

local function MiniFaceVisible(btn)
    if not btn or btn._fluxParked then
        return false
    end
    if not btn.IsShown or not btn:IsShown() then
        return false
    end
    if btn.HasAction and btn:HasAction() then
        return true
    end
    return false
end

-- Get references to all UI components
local function GetComponents()
    local components = {
        actionBar = NamedFrame("FluxActionStrip", "FluxMainActionBar"),
        combatGrid = FluxCombatManager and FluxCombatManager.Grid,
        nonCombatGrid = FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid,
        trinketMenu = FluxTrinketMenu,
        infoFrame = FluxInfoFrame and FluxInfoFrame.GetFrame and FluxInfoFrame.GetFrame(),
        windowFrame = FluxWindowFrame and FluxWindowFrame.GetFrame and FluxWindowFrame:GetFrame(),
    }
    
    -- Get frames from grid objects
    if components.combatGrid then
        components.combatGridFrame = components.combatGrid.Frame
    end
    
    if components.nonCombatGrid then
        components.nonCombatGridFrame = components.nonCombatGrid.Frame
    end
    
    if components.trinketMenu then
        components.trinketMenuFrame = components.trinketMenu.Frame
    end
    
    return components
end

-- Get references to StatusBar and MicroMenu components
local function GetStatusBarComponents()
    local components = {
        microMenu = _G["FluxMicroMenu"],
        statusBarContainer = _G["FluxStatusBarContainer"],
    }
    
    return components
end

-- ============================================================================
-- MINIROW VISIBILITY DETECTION
-- ============================================================================

-- Check if minirow buttons are visible (either have content OR being dragged over)
local function IsMinirowVisible()
    local actionBar = NamedFrame("FluxActionStrip", "FluxMainActionBar")
    
    -- If action bar doesn't exist or isn't shown, minirows can't be visible
    if not actionBar or not actionBar:IsShown() then
        return false
    end
    
    -- Check if dragging over ActionBar sensing frame (minirows expand during drag even without content)
    local hasCursor = GetCursorInfo()
    if hasCursor then
        local sensingFrame = NamedFrame("FluxActionStripSensing", "FluxActionBarSensing")
        if sensingFrame then
            local isOver = sensingFrame:IsMouseOver() or MouseIsOver(sensingFrame)
            if isOver then
                return true -- Minirows are visible during drag/hover
            end
        end
        -- Fallback: Check main action bar frame
        if actionBar then
            local isOver = actionBar:IsMouseOver() or MouseIsOver(actionBar)
            if isOver then
                return true -- Minirows are visible during drag/hover
            end
        end
    end
    
    -- Parked minis stay Shown off-screen; skip _fluxParked so promote-single
    -- does not count as a visible minirow.
    for i = 1, 19 do
        local secButton = NamedFrame("FluxActionStripSec" .. i, "FluxSecondaryButton" .. i)
        local tertButton = NamedFrame("FluxActionStripTert" .. i, "FluxTertiaryButton" .. i)
        if MiniFaceVisible(secButton) or MiniFaceVisible(tertButton) then
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- BORDER POSITIONING
-- ============================================================================

local function GamepadHudOn()
    local Cap = _G.Flux and _G.Flux.Cap
    return Cap and Cap.IsGamepadUIEnabled and Cap.IsGamepadUIEnabled() and true or false
end

--- Left and right frames of the grid row that replaces the 19-button bar.
--- Nil when the gamepad HUD is off or the non-combat grid is hidden.
local function GamepadStripFrames()
    if not GamepadHudOn() then
        return nil, nil
    end
    local components = GetComponents()
    local leftFrame = components.nonCombatGridFrame
    if not leftFrame or not leftFrame:IsShown() then
        return nil, nil
    end
    local rightFrame = leftFrame
    if components.combatGridFrame and components.combatGridFrame:IsShown() then
        rightFrame = components.combatGridFrame
    end
    if components.trinketMenuFrame and components.trinketMenuFrame:IsShown() then
        rightFrame = components.trinketMenuFrame
    end
    local infoFrame = components.infoFrame
    local infoOnStrip = FluxOptions and FluxOptions.GetInfoFramePlacement and FluxOptions:GetInfoFramePlacement() == "actionStrip"
    if infoOnStrip and infoFrame and infoFrame:IsShown() then
        rightFrame = infoFrame
    end
    return leftFrame, rightFrame
end

function UnifiedBorder.GamepadStripFrames()
    return GamepadStripFrames()
end

local function ScreenEdge(frame, method)
    if not frame or not frame[method] or (frame.IsShown and not frame:IsShown()) then
        return nil
    end
    local value = frame[method](frame)
    if type(value) ~= "number" or value ~= value then
        return nil
    end
    local fes = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    local ues = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    if type(fes) ~= "number" or fes <= 0 then
        fes = 1
    end
    if type(ues) ~= "number" or ues <= 0 then
        ues = 1
    end
    return value * fes / ues
end

local function TallerFrame(a, b)
    local ta = ScreenEdge(a, "GetTop")
    local tb = ScreenEdge(b, "GetTop")
    if ta and tb then
        return (tb > ta) and b or a
    end
    return ta and a or (tb and b) or a or b
end

-- Get anchor points for border positioning
local function GetBorderAnchors()
    local components = GetComponents()
    local actionBarExists = components.actionBar and components.actionBar:IsShown()
    
    -- Check if required grids exist
    local nonCombatGrid = components.nonCombatGridFrame
    local combatGrid = components.combatGridFrame
    local trinketMenu = components.trinketMenuFrame
    
    if not nonCombatGrid or not nonCombatGrid:IsShown() then
        return nil
    end
    
    local combatGridShown = combatGrid and combatGrid:IsShown()
    local windowFrame = components.windowFrame
    
    -- Determine right anchor: extend to FluxWindowFrame's left when shown, else TrinketMenu etc.
    -- Gamepad HUD has no 19-button span, so the border stops at the grid row (through Info).
    local rightAnchor = nil
    local rightPoint = "RIGHT"
    local rightOffsetX = 0
    local topAnchor = nil
    local gpLeft, gpRight = GamepadStripFrames()

    if gpLeft and gpRight then
        rightAnchor = gpRight
        topAnchor = TallerFrame(nonCombatGrid, gpRight)
        if components.combatGridFrame then
            topAnchor = TallerFrame(topAnchor, components.combatGridFrame)
        end
        if components.trinketMenuFrame then
            topAnchor = TallerFrame(topAnchor, components.trinketMenuFrame)
        end
    elseif windowFrame and windowFrame:IsShown() then
        rightAnchor = windowFrame
        rightPoint = "LEFT" -- Border's right meets WindowFrame's left
        rightOffsetX = -6 -- Pull border further left (was -4)
    elseif trinketMenu and trinketMenu:IsShown() then
        rightAnchor = trinketMenu
    elseif combatGridShown then
        rightAnchor = combatGrid
        rightOffsetX = -2
    elseif actionBarExists then
        --- Only anchor the unified border to FluxInfoFrame when Info actually occupies the strip; otherwise its screen position breaks the envelope.
        local infoFrame = components.infoFrame
        local infoOnStrip = FluxOptions and FluxOptions.GetInfoFramePlacement and FluxOptions:GetInfoFramePlacement() == "actionStrip"
        local useInfo = infoOnStrip and infoFrame and infoFrame:IsShown()
        rightAnchor = useInfo and infoFrame or components.actionBar
        rightOffsetX = -4
    else
        rightAnchor = nonCombatGrid
    end
    
    if not rightAnchor then
        return nil
    end
    
    --- Left: NonCombatGrid.
    local leftAnchor = nonCombatGrid
    local leftPoint = "LEFT"
    
    -- Y axis: Use bottom of grids (Y=0 relative to bottom of screen)
    -- We'll anchor to BOTTOM of the grids
    local bottomAnchor = nonCombatGrid
    local bottomPoint = "BOTTOM"
    
    -- Top anchor: Use top of grids. Gamepad path may already have picked a taller frame.
    if not topAnchor then
        topAnchor = nonCombatGrid
    end
    local topPoint = "TOP"
    
    return {
        leftAnchor = leftAnchor,
        leftPoint = leftPoint,
        rightAnchor = rightAnchor,
        rightPoint = rightPoint,
        rightOffsetX = rightOffsetX,
        bottomAnchor = bottomAnchor,
        bottomPoint = bottomPoint,
        topAnchor = topAnchor,
        topPoint = topPoint,
    }
end

-- Get anchor points for StatusBar/MicroMenu border positioning
local function GetStatusBarBorderAnchors()
    local components = GetStatusBarComponents()
    
    local microMenu = components.microMenu
    local statusBarContainer = components.statusBarContainer

    if FluxOptions and FluxOptions.GetStatusBarPosition then
        local sp = FluxOptions:GetStatusBarPosition()
        if sp == 2 or sp == 3 then
            return nil
        end
    end

    if not microMenu or not microMenu:IsShown() then
        return nil
    end
    
    if not statusBarContainer or not statusBarContainer:IsShown() then
        return nil
    end
    
    local microMenuRight = microMenu:GetRight()
    local statusBarRight = statusBarContainer:GetRight()
    local infoRight = nil
    if FluxInfoFrame and FluxInfoFrame.GetFrame and FluxOptions and FluxOptions.GetInfoFramePlacement
        and FluxOptions:GetInfoFramePlacement() == "statusIntegrated" then
        local inf = FluxInfoFrame:GetFrame()
        if inf and inf:IsShown() and inf.GetRight then
            infoRight = inf:GetRight()
        end
    end

    local bestRight = microMenuRight or 0
    local rightAnchor = microMenu
    local rightPoint = "RIGHT"
    if statusBarRight and statusBarRight > bestRight then
        bestRight = statusBarRight
        rightAnchor = statusBarContainer
    end
    if infoRight and infoRight > bestRight then
        rightAnchor = FluxInfoFrame:GetFrame()
    end

    -- Left anchor: MicroMenu's left border
    local leftAnchor = microMenu
    local leftPoint = "LEFT"
    
    -- Top anchor: MicroMenu's top border
    local topAnchor = microMenu
    local topPoint = "TOP"
    
    -- Bottom anchor: StatusBarContainer's bottom border
    local bottomAnchor = statusBarContainer
    local bottomPoint = "BOTTOM"
    
    return {
        leftAnchor = leftAnchor,
        leftPoint = leftPoint,
        rightAnchor = rightAnchor,
        rightPoint = rightPoint,
        bottomAnchor = bottomAnchor,
        bottomPoint = bottomPoint,
        topAnchor = topAnchor,
        topPoint = topPoint,
    }
end

-- ============================================================================
-- BORDER FRAME CREATION
-- ============================================================================

local function RefreshBorderArrows()
    if FluxFlyoutFrame and FluxFlyoutFrame.OnUnifiedBorderFrameShow then
        FluxFlyoutFrame.OnUnifiedBorderFrameShow()
    end
    local Flyout = _G.Flux and (_G.Flux.Flyout or (_G.Flux.EBS and _G.Flux.EBS.Flyout))
    local refresh = Flyout and Flyout.RefreshArrowLayers
    if refresh then refresh() end
    if FluxTrinketMenu and FluxTrinketMenu.RefreshArrowLayersOnBorder then
        FluxTrinketMenu.RefreshArrowLayersOnBorder(refresh)
    end
end

local function CreateBorderFrame()
    if borderFrame then return borderFrame end
    
    -- Create main border frame
    borderFrame = CreateFrame("Frame", "FluxUnifiedBorderFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    borderFrame:SetClampedToScreen(true)
    borderFrame:SetFrameStrata("MEDIUM")
    borderFrame:SetFrameLevel(8) -- Lower than FluxWindowFrame (10) but higher than ActionBars (5) and grids
    borderFrame:EnableMouse(false) -- Don't block mouse interaction
    
    -- Apply FluxBorder without backdrop
    if FluxBorder then
        FluxBorder:ApplyTo(borderFrame, -4, -4, -5, -4) -- Match existing grid padding
        FluxBorder:SetClassColor(borderFrame, 1, false) -- No backdrop
    end
    
    -- Initial hide
    borderFrame:Hide()
    
    borderFrame:SetScript("OnShow", RefreshBorderArrows)
    
    return borderFrame
end

local function CreateStatusBarBorderFrame()
    if statusBarBorderFrame then return statusBarBorderFrame end
    
    -- Create StatusBar/MicroMenu border frame
    statusBarBorderFrame = CreateFrame("Frame", "FluxStatusBarUnifiedBorderFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    statusBarBorderFrame:SetClampedToScreen(true)
    statusBarBorderFrame:SetFrameStrata("MEDIUM")
    statusBarBorderFrame:SetFrameLevel(7) -- Below FluxAddonMicroButton popup (DIALOG 100) but above StatusBar/MicroMenu borders
    statusBarBorderFrame:EnableMouse(false) -- Don't block mouse interaction
    
    -- Apply FluxBorder without backdrop (0 padding, 0x 0y)
    if FluxBorder then
        FluxBorder:ApplyTo(statusBarBorderFrame, 0, 0, 0, 0) -- 0 padding
        FluxBorder:SetClassColor(statusBarBorderFrame, 1, false) -- No backdrop
    end
    
    -- Initial hide
    statusBarBorderFrame:Hide()
    
    return statusBarBorderFrame
end

-- Create gap backdrop frame (TrinketMenu right → WindowFrame left) - backdrop only, matches grid style
local function CreateGapBackdropFrame()
    if gapBackdropFrame then return gapBackdropFrame end
    
    -- Parent to FluxUIBackgroundLayer (created in FluxBorder before TrinketMenu loads) so we draw BEHIND
    local parent = FluxUIBackgroundLayer or UIParent
    gapBackdropFrame = CreateFrame("Frame", "FluxUnifiedBorderGapBackdrop", parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    gapBackdropFrame:SetFrameStrata("BACKGROUND")
    gapBackdropFrame:SetFrameLevel(0)
    gapBackdropFrame:EnableMouse(false)
    
    -- Backdrop only (no border) - match FluxBorder grid style: classColor * 0.4, alpha 0.85
    if gapBackdropFrame.SetBackdrop then
        gapBackdropFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            tile = true, tileSize = 1,
        })
    end
    
    local function UpdateGapColor()
        local r, g, b = 0.15, 0.15, 0.15
        if FluxBorder and FluxBorder.GetThemedBackdropFillRGB then
            r, g, b = FluxBorder:GetThemedBackdropFillRGB()
        else
            local _, classFilename = UnitClass("player")
            local color = RAID_CLASS_COLORS[classFilename] or { r = 0.6, g = 0.6, b = 0.6 }
            r, g, b = color.r * 0.4, color.g * 0.4, color.b * 0.4
        end
        if gapBackdropFrame.SetBackdropColor then
            gapBackdropFrame:SetBackdropColor(r, g, b, 0.85)
        end
    end
    gapBackdropFrame.UpdateClassColor = UpdateGapColor
    UpdateGapColor()
    
    gapBackdropFrame:Hide()
    return gapBackdropFrame
end

local function CreateActionStripInfoGapBackdropFrame()
    if actionStripInfoGapBackdropFrame then return actionStripInfoGapBackdropFrame end

    local parent = FluxUIBackgroundLayer or UIParent
    actionStripInfoGapBackdropFrame = CreateFrame("Frame", "FluxUnifiedBorderActionStripInfoGapBackdrop", parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    actionStripInfoGapBackdropFrame:SetFrameStrata("BACKGROUND")
    actionStripInfoGapBackdropFrame:SetFrameLevel(0)
    actionStripInfoGapBackdropFrame:EnableMouse(false)

    if actionStripInfoGapBackdropFrame.SetBackdrop then
        actionStripInfoGapBackdropFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            tile = true, tileSize = 1,
        })
    end

    local function UpdateSlotColor()
        local r, g, b = 0.15, 0.15, 0.15
        if FluxBorder and FluxBorder.GetThemedBackdropFillRGB then
            r, g, b = FluxBorder:GetThemedBackdropFillRGB()
        else
            local _, classFilename = UnitClass("player")
            local color = RAID_CLASS_COLORS[classFilename] or { r = 0.6, g = 0.6, b = 0.6 }
            r, g, b = color.r * 0.4, color.g * 0.4, color.b * 0.4
        end
        if actionStripInfoGapBackdropFrame.SetBackdropColor then
            actionStripInfoGapBackdropFrame:SetBackdropColor(r, g, b, 0.85)
        end
    end
    actionStripInfoGapBackdropFrame.UpdateClassColor = UpdateSlotColor
    UpdateSlotColor()

    actionStripInfoGapBackdropFrame:Hide()
    return actionStripInfoGapBackdropFrame
end

-- ============================================================================
-- BORDER UPDATE
-- ============================================================================

local function UpdateActionStripInfoGapBackdrop(stripCrossing)
    if InCombatLockdown() then return end
    if not actionStripInfoGapBackdropFrame then
        CreateActionStripInfoGapBackdropFrame()
    end
    if not actionStripInfoGapBackdropFrame then return end

    if FluxOptions and FluxOptions.GetInfoFramePlacement and FluxOptions:GetInfoFramePlacement() == "actionStrip" then
        actionStripInfoGapBackdropFrame:Hide()
        return
    end

    if FluxInfoFrame and FluxInfoFrame.PositionActionStripSlotFrame then
        if FluxInfoFrame.PositionActionStripSlotFrame(actionStripInfoGapBackdropFrame, stripCrossing) then
            actionStripInfoGapBackdropFrame:Show()
        else
            actionStripInfoGapBackdropFrame:Hide()
        end
    else
        actionStripInfoGapBackdropFrame:Hide()
    end
end

local function GapPointMatches(frame, index, point, anchor, relativePoint, x, y)
    local p, relative, rp, ox, oy = frame:GetPoint(index)
    if issecretvalue and (issecretvalue(p) or issecretvalue(relative) or issecretvalue(rp)
        or issecretvalue(ox) or issecretvalue(oy)) then return false end
    return p == point and relative == anchor and rp == relativePoint and ox == x and oy == y
end

local function GapAnchorsMatch(frame, left, window, grid, leftX, insetY)
    local n = frame:GetNumPoints()
    if (issecretvalue and issecretvalue(n)) or n ~= 4 then return false end
    return GapPointMatches(frame, 1, "LEFT", left, "RIGHT", leftX, 0)
        and GapPointMatches(frame, 2, "RIGHT", window, "LEFT", 0, 0)
        and GapPointMatches(frame, 3, "TOP", grid, "TOP", 0, insetY)
        and GapPointMatches(frame, 4, "BOTTOM", grid, "BOTTOM", 0, -insetY)
end

local function UpdateGapBackdrop(stripCrossing)
    if not gapBackdropFrame or InCombatLockdown() then return end

    -- The trinket-to-window fill bridges the old button span. That span is gone.
    if GamepadHudOn() then
        gapBackdropFrame:Hide()
        return
    end

    local components = GetComponents()
    local trinketMenu = components.trinketMenuFrame
    local windowFrame = components.windowFrame
    local nonCombatGrid = components.nonCombatGridFrame
    local combatGrid = components.combatGridFrame
    local actionBar = components.actionBar

    if not windowFrame or not windowFrame:IsShown() or not nonCombatGrid or not nonCombatGrid:IsShown() then
        gapBackdropFrame:Hide()
        return
    end

    -- Choose left anchor: TrinketMenu if shown, else ActionBar (rightmost bar when TrinketMenu hidden)
    -- Use ActionBar before CombatGrid: TrinketMenu sits to the right of ActionBar; CombatGrid is left of ActionBar
    local leftAnchor = nil
    local leftOffsetX = 0
    if trinketMenu and trinketMenu:IsShown() then
        leftAnchor = trinketMenu
    elseif actionBar and actionBar:IsShown() then
        leftAnchor = actionBar
        leftOffsetX = -6 -- Extend backdrop left to cover spacing/border gap when TrinketMenu absent
    elseif combatGrid and combatGrid:IsShown() then
        leftAnchor = combatGrid
        leftOffsetX = -4 -- Slight overlap when using CombatGrid fallback
    else
        gapBackdropFrame:Hide()
        return
    end

    -- Extend 4px beyond grid top/bottom to match border extent (FluxBorder ApplyTo uses -4 inset)
    local insetY = 4
    if stripCrossing == true then
        local ok, matches = pcall(GapAnchorsMatch, gapBackdropFrame, leftAnchor, windowFrame, nonCombatGrid, leftOffsetX, insetY)
        if ok and matches then
            local shown = gapBackdropFrame:IsShown()
            if (issecretvalue and issecretvalue(shown)) or not shown then gapBackdropFrame:Show() end
            return
        end
    end
    gapBackdropFrame:ClearAllPoints()
    gapBackdropFrame:SetPoint("LEFT", leftAnchor, "RIGHT", leftOffsetX, 0)
    gapBackdropFrame:SetPoint("RIGHT", windowFrame, "LEFT", 0, 0)
    gapBackdropFrame:SetPoint("TOP", nonCombatGrid, "TOP", 0, insetY)
    gapBackdropFrame:SetPoint("BOTTOM", nonCombatGrid, "BOTTOM", 0, -insetY)
    gapBackdropFrame:Show()
end

local lastBorderLayoutHash, lastBorderAnchors

local function BorderAnchorGeometry(frame)
    if not frame or not frame.GetLeft then return "nil" end
    return string.format("%.1f:%.1f:%.1f:%.1f", frame:GetLeft() or 0, frame:GetBottom() or 0,
        frame:GetWidth() or 0, frame:GetHeight() or 0)
end

local function ComputeBorderLayoutHash(anchors)
    if not anchors then return "none" end
    local l, r, b, t = anchors.leftAnchor, anchors.rightAnchor, anchors.bottomAnchor, anchors.topAnchor
    local left = BorderAnchorGeometry(l)
    local right = r == l and left or BorderAnchorGeometry(r)
    local bottom = b == l and left or b == r and right or BorderAnchorGeometry(b)
    local top = t == l and left or t == r and right or t == b and bottom or BorderAnchorGeometry(t)
    return "L:" .. left .. "|R:" .. right .. "|B:" .. bottom .. "|T:" .. top
        .. "|rx:" .. tostring(anchors.rightOffsetX or 0) .. "|rp:" .. tostring(anchors.rightPoint or "RIGHT")
end

local function SameBorderAnchors(a, b)
    if not a or not b then return a == b end
    return a.leftAnchor == b.leftAnchor and a.rightAnchor == b.rightAnchor
        and a.bottomAnchor == b.bottomAnchor and a.topAnchor == b.topAnchor
        and a.rightPoint == b.rightPoint and a.rightOffsetX == b.rightOffsetX
end

local function BorderPointsMatch(frame, anchors)
    local n = frame:GetNumPoints()
    if (issecretvalue and issecretvalue(n)) or n ~= 4 then return false end
    return GapPointMatches(frame, 1, "LEFT", anchors.leftAnchor, "LEFT", 0, 0)
        and GapPointMatches(frame, 2, "RIGHT", anchors.rightAnchor, anchors.rightPoint or "RIGHT", anchors.rightOffsetX or 0, 0)
        and GapPointMatches(frame, 3, "BOTTOM", anchors.bottomAnchor, "BOTTOM", 0, 0)
        and GapPointMatches(frame, 4, "TOP", anchors.topAnchor, "TOP", 0, 0)
end

local function UpdateBorder(stripCrossing)
    if InCombatLockdown() then return end

    local anchors = GetBorderAnchors()
    local layoutHash = ComputeBorderLayoutHash(anchors)
    local keepPoints
    if stripCrossing == true and anchors and borderFrame and borderFrame.GetNumPoints and borderFrame.GetPoint then
        local ok, matches = pcall(BorderPointsMatch, borderFrame, anchors)
        keepPoints = ok and matches
    end
    if layoutHash == lastBorderLayoutHash and SameBorderAnchors(lastBorderAnchors, anchors)
        and borderFrame and borderFrame:IsShown() and (stripCrossing ~= true or keepPoints) then
        if stripCrossing == true then
            -- The Info slot and trinket gap have their own owners. Their
            -- contacts can move while the outer envelope stays in place.
            UpdateActionStripInfoGapBackdrop(true)
            UpdateGapBackdrop(true)
        end
        return
    end
    lastBorderLayoutHash, lastBorderAnchors = layoutHash, anchors
    if _G.Flux and Flux.Startup then Flux.Startup.Layout("unified_border_layout_passes") end

    --- Same themed fill as gap backdrop when FPS/durability strip lives elsewhere (top-left / status stack).
    UpdateActionStripInfoGapBackdrop(stripCrossing)

    if not borderFrame then return end
    
    -- If we don't have valid anchors, hide the border
    if not anchors then
        borderFrame:Hide()
        if gapBackdropFrame then gapBackdropFrame:Hide() end
        lastBorderLayoutHash = layoutHash
        return
    end
    
    -- Update gap backdrop (TrinketMenu → WindowFrame) when both shown
    UpdateGapBackdrop(stripCrossing)
    
    -- Native anchors already follow moving grids and windows. Rebind only
    -- when the attachment changed or the current points need repair.
    if not keepPoints then
        borderFrame:ClearAllPoints()
        borderFrame:SetPoint("LEFT", anchors.leftAnchor, "LEFT", 0, 0)
        borderFrame:SetPoint("RIGHT", anchors.rightAnchor, anchors.rightPoint or "RIGHT", anchors.rightOffsetX or 0, 0)
        borderFrame:SetPoint("BOTTOM", anchors.bottomAnchor, "BOTTOM", 0, 0)
        borderFrame:SetPoint("TOP", anchors.topAnchor, "TOP", 0, 0)
    end
    
    borderFrame:Show()
    RefreshBorderArrows()
end

-- Both extra grids can finish in the same action-strip transaction. Info
-- reads their settled bounds before the envelope selects its final anchors.
local gridLayoutPending, gridLayoutQueued = false, false

function UnifiedBorder.UpdateAfterGridLayout(stripCrossing)
    if InCombatLockdown() then
        local combat = _G.Flux and Flux.Combat
        if gridLayoutPending and combat and combat.Defer then
            combat.Defer("layout.grid.envelope", UnifiedBorder.UpdateAfterGridLayout)
        end
        return
    end
    local infoOK, infoError = true
    if gridLayoutPending then
        gridLayoutPending = false
        local info = FluxInfoFrame
        local updateInfo = info and ((stripCrossing == true and info.UpdateAfterStripLayout) or info.UpdatePosition)
        if updateInfo then
            infoOK, infoError = pcall(updateInfo)
        end
    end
    if stripCrossing == true then UnifiedBorder.UpdateBorder(true)
    else UnifiedBorder.UpdateBorder() end
    if not infoOK then
        if geterrorhandler then geterrorhandler()(infoError)
        else error(infoError, 0) end
    end
end

local function RunGridLayoutUpdate()
    gridLayoutQueued = false
    if gridLayoutPending then UnifiedBorder.UpdateAfterGridLayout() end
end

function UnifiedBorder.RequestGridLayoutUpdate()
    gridLayoutPending = true
    if gridLayoutQueued then return end
    gridLayoutQueued = true
    C_Timer.After(0, RunGridLayoutUpdate)
end

--- Unified micro+status chrome is only meaningful when the micro bar is horizontal above the status stack.
local function ShouldHideMicroStatusUnifiedBorder()
    if FluxOptions and FluxOptions.GetStatusBarPosition then
        local sp = FluxOptions:GetStatusBarPosition()
        if sp == 2 or sp == 3 then
            return true
        end
    end
    if FluxOptions and FluxOptions.IsMicroMenuDetachedVerticalLayout then
        return FluxOptions:IsMicroMenuDetachedVerticalLayout()
    end
    if FluxOptions and FluxOptions.GetMicroMenuLayoutPosition then
        return FluxOptions:GetMicroMenuLayoutPosition() == 2
    end
    return false
end

local function UpdateStatusBarBorder()
    if not statusBarBorderFrame or InCombatLockdown() then return end

    if ShouldHideMicroStatusUnifiedBorder() then
        statusBarBorderFrame:Hide()
        return
    end

    local anchors = GetStatusBarBorderAnchors()
    
    -- If we don't have valid anchors, hide the border
    if not anchors then
        statusBarBorderFrame:Hide()
        return
    end
    
    -- 0 padding, 0x 0y offset - border aligns directly with component edges
    local totalOffset = 0
    
    -- Position unified border frame using anchor points
    statusBarBorderFrame:ClearAllPoints()
    
    -- Left edge: MicroMenu's left edge (0 offset)
    statusBarBorderFrame:SetPoint("LEFT", anchors.leftAnchor, "LEFT", totalOffset, 0)
    
    -- Right edge: MicroMenu's or StatusBarContainer's right (whichever is wider, 0 offset)
    statusBarBorderFrame:SetPoint("RIGHT", anchors.rightAnchor, "RIGHT", totalOffset, 0)
    
    -- Bottom edge: StatusBarContainer's bottom edge (0 offset)
    statusBarBorderFrame:SetPoint("BOTTOM", anchors.bottomAnchor, "BOTTOM", 0, totalOffset)
    
    -- Top edge: MicroMenu's top edge (0 offset)
    statusBarBorderFrame:SetPoint("TOP", anchors.topAnchor, "TOP", 0, totalOffset)
    
    statusBarBorderFrame:Show()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function Initialize()
    if InCombatLockdown() then return false end
    
    -- Create border frame if not exists
    if not borderFrame then
        CreateBorderFrame()
    end
    
    -- Create gap backdrop frame if not exists
    if not gapBackdropFrame then
        CreateGapBackdropFrame()
    end

    if not actionStripInfoGapBackdropFrame then
        CreateActionStripInfoGapBackdropFrame()
    end
    
    -- Create StatusBar border frame if not exists
    if not statusBarBorderFrame then
        CreateStatusBarBorderFrame()
    end
    
    -- Try to update borders
    UpdateBorder()
    UpdateStatusBarBorder()
    
    return true
end

-- ============================================================================
-- WATCHER PATTERN (similar to InfoFrame.lua)
-- ============================================================================

local watcherFrame = CreateFrame("Frame")
local checkCount = 0
local MAX_CHECKS = 30 -- Safety limit: ~0.5 seconds at 60fps

local function TryInitialize(force)
    if InCombatLockdown() then return false end
    if initialized then return true end
    
    -- Check if required components are available
    local components = GetComponents()
    local hasNonCombatGrid = components.nonCombatGridFrame ~= nil
    local hasCombatGrid = components.combatGridFrame ~= nil
    
    -- Both grids are required to create the border.
    if force or (hasNonCombatGrid and hasCombatGrid) then
        if Initialize() then
            initialized = true
            watcherFrame:SetScript("OnUpdate", nil) -- Stop watching
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- ACTIONBAR HOOKS FOR INSTANT UPDATES
-- ============================================================================

-- Hook into ActionBar's UpdateSmartLayout for instant updates when minirows expand/collapse
local updateSmartLayoutHooked = false
local function HookUpdateSmartLayout()
    if updateSmartLayoutHooked then return end
    
    -- Try to hook UpdateSmartLayout if it's available globally or through FluxActionBarModule
    if UpdateSmartLayout then
        hooksecurefunc("UpdateSmartLayout", function()
            if initialized and borderFrame then
                -- Instant update when ActionBar layout changes (includes minirow visibility changes)
                UpdateBorder()
            end
        end)
        updateSmartLayoutHooked = true
    end
    
    -- Also try hooking through FluxActionBarModule if available
    if FluxActionBarModule and FluxActionBarModule.UpdateButtonLayout then
        hooksecurefunc(FluxActionBarModule, "UpdateButtonLayout", function()
            if initialized and borderFrame then
                -- Instant update when ActionBar button layout changes
                UpdateBorder()
            end
        end)
    end
end

local function GetActiveActionStripLayout()
    local bars = _G.Flux and Flux.Bars
    local strip = bars and bars.Strip and bars.Strip.frame
    if bars and bars.started and bars.secureReady and strip and strip:IsShown()
        and bars.Layout and bars.Layout.OnDragHover then
        return bars.Layout
    end
end

local function ActionStripHoverChanged()
    local layout = GetActiveActionStripLayout()
    if layout then
        -- Expansion/collapse owns the resulting panel geometry. The hover
        -- signal requests that layout, which finishes the envelope once.
        layout.OnDragHover()
    elseif initialized and borderFrame then
        UpdateBorder()
    end
end

-- Native hover scripts can resolve an edge before the drag check sees it.
local function SetupActionBarHooks()
    local sensingFrame = NamedFrame("FluxActionStripSensing", "FluxActionBarSensing")
    local mainBarFrame = NamedFrame("FluxActionStrip", "FluxMainActionBar")
    
    if sensingFrame and not sensingFrame._borderHooked then
        sensingFrame:HookScript("OnEnter", ActionStripHoverChanged)
        sensingFrame:HookScript("OnLeave", ActionStripHoverChanged)
        sensingFrame._borderHooked = true
    end
    
    if mainBarFrame and not mainBarFrame._borderHooked then
        mainBarFrame:HookScript("OnEnter", ActionStripHoverChanged)
        mainBarFrame:HookScript("OnLeave", ActionStripHoverChanged)
        mainBarFrame._borderHooked = true
    end
    
    -- Try to hook UpdateSmartLayout
    HookUpdateSmartLayout()
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED") -- Instant update when actions change
eventFrame:RegisterEvent("CURSOR_CHANGED") -- Instant update when drag starts/stops
eventFrame._fluxFormBorderPending = false

local function EnsureBorderFormStormSettledHook()
    local FE = _G.FluxButtonEvents
    if not FE or not FE.RegisterFormStormSettled or eventFrame._fluxFormBorderSettledHooked then
        return
    end
    eventFrame._fluxFormBorderSettledHooked = true
    FE.RegisterFormStormSettled("UnifiedBorderAsc", function()
        if not eventFrame._fluxFormBorderPending then
            return
        end
        eventFrame._fluxFormBorderPending = false
        if initialized and borderFrame then
            UpdateBorder()
        end
    end)
end
if C_Timer and C_Timer.After then
    C_Timer.After(0, EnsureBorderFormStormSettledHook)
end

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Try to initialize immediately
        if TryInitialize(false) then
            return
        end
        
        -- If not initialized, watch every frame until components are available
        checkCount = 0
        watcherFrame:SetScript("OnUpdate", function(self, elapsed)
            checkCount = checkCount + 1
            if TryInitialize(false) or checkCount >= MAX_CHECKS then
                -- If we hit the limit, force initialization
                if checkCount >= MAX_CHECKS and not initialized then
                    TryInitialize(true)
                end
                self:SetScript("OnUpdate", nil)
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Update borders after loading screen
        if initialized then
            UpdateBorder()
            UpdateStatusBarBorder()
            -- Setup ActionBar hooks for instant updates
            SetupActionBarHooks()
        else
            -- Try to initialize if not already done
            TryInitialize(false)
        end
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "CURSOR_CHANGED" then
        local activeLayout = GetActiveActionStripLayout()
        if event == "CURSOR_CHANGED" and activeLayout then return end
        if event == "ACTIONBAR_SLOT_CHANGED"
            and _G.FluxButtonEvents and _G.FluxButtonEvents.IsFormStormActive
            and _G.FluxButtonEvents.IsFormStormActive() then
            EnsureBorderFormStormSettledHook()
            eventFrame._fluxFormBorderPending = true
            return
        end
        -- Watch batches native slot notifications. Layout settles the strips,
        -- grids and Info before publishing the envelope for a geometry change.
        local watch = activeLayout and Flux.Bars.Watch
        if event == "ACTIONBAR_SLOT_CHANGED" and watch and watch.slotEvents and watch.slotEvents == Flux.Events then return end
        if initialized and borderFrame then
            UpdateBorder()
        end
    end
end)

-- Try to setup hooks immediately if ActionBar is already available
if NamedFrame("FluxActionStrip", "FluxMainActionBar") or NamedFrame("FluxActionStripSensing", "FluxActionBarSensing") then
    SetupActionBarHooks()
end

-- EVENT-BASED: Setup hooks once after initialization (no continuous checking needed)
-- Try to setup hooks immediately if ActionBar is available, otherwise try once after a short delay
if not (_G.Flux and Flux.Module) then
if NamedFrame("FluxActionStrip", "FluxMainActionBar") or NamedFrame("FluxActionStripSensing", "FluxActionBarSensing") then
    SetupActionBarHooks()
else
    -- Try once after a short delay
    C_Timer.After(0.5, function()
        SetupActionBarHooks()
    end)
end
end

-- EVENT-BASED: Drag state tracking via CURSOR_CHANGED event and mouse hooks (no OnUpdate needed)
-- CURSOR_CHANGED event is already registered in eventFrame and mouse enter/leave hooks are already set up
-- The dragWatcher OnUpdate is no longer needed - updates happen via events and hooks

-- Try to hook UpdateSmartLayout immediately if available
HookUpdateSmartLayout()

-- EVENT-BASED: Component position/size changes handled via event hooks and grid relayout hooks
-- No continuous OnUpdate timer needed - updates happen when:
-- 1. ActionBar layout changes (UpdateSmartLayout hook)
-- 2. Mouse enters/leaves ActionBar during drag (OnEnter/OnLeave hooks)
-- 3. CURSOR_CHANGED event (drag start/stop)
-- 4. ACTIONBAR_SLOT_CHANGED event (action changes)
-- Fallback timer removed - rely on event-based updates only

-- Export UpdateBorder for external refresh (e.g. when Combat Grid hides)
UnifiedBorder.UpdateBorder = UpdateBorder
UnifiedBorder.UpdateStatusBarBorder = UpdateStatusBarBorder

--- Top edge Y of the main action/grid unified border (FluxUnifiedBorderFrame), or nil if unavailable.
--- Returned in UIParent units (GetTop is frame-scale / screen space).
function UnifiedBorder.GetActionGridBorderTop()
    local f = _G.FluxUnifiedBorderFrame
    if f and f:IsShown() and f.GetTop then
        local top = f:GetTop()
        if type(top) ~= "number" or top ~= top then
            return nil
        end
        local fes = (f.GetEffectiveScale and f:GetEffectiveScale()) or 1
        local ues = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
        if type(fes) == "number" and fes > 0 and type(ues) == "number" and ues > 0 then
            return top * fes / ues
        end
        return top
    end
    return nil
end

function UnifiedBorder.RefreshGapAppearance()
    if gapBackdropFrame and gapBackdropFrame.UpdateClassColor then
        gapBackdropFrame.UpdateClassColor()
    end
    if actionStripInfoGapBackdropFrame and actionStripInfoGapBackdropFrame.UpdateClassColor then
        actionStripInfoGapBackdropFrame.UpdateClassColor()
    end
end

UnifiedBorder.UpdateActionStripInfoGapBackdrop = UpdateActionStripInfoGapBackdrop

-- Export
_G.FluxUnifiedBorder = UnifiedBorder

-- Components are produced in secure priority order before this HUD phase.
-- No frame-count watcher or speculative half-second delay is needed for boot.
if _G.Flux and Flux.Module then
    Flux.Module.Register("UnifiedBorder", {
        phase = "hud", priority = 90, protected = true,
        OnEnable = function()
            if not TryInitialize(true) then return false end
            SetupActionBarHooks()
            EnsureBorderFormStormSettledHook()
            if Flux.Startup then Flux.Startup.Mark("bottom_hud_layout_applied") end
            return true
        end,
    })
end


