-- FluxHUDTooltip.lua
-- Repositions the default GameTooltip to be above FluxWindowFrame
-- Removes HUD Tooltip from Edit Mode control
-- ---------------------------------------------------------------------------

local addonName, ns = ...

-- Store the reference to our anchor frame
local anchorFrame = nil

-- Function to get the anchor frame (FluxWindowFrame), initializing it if needed
local function GetAnchorFrame()
    if anchorFrame then return anchorFrame end
    
    if FluxWindowFrame and FluxWindowFrame.GetFrame then
        anchorFrame = FluxWindowFrame:GetFrame()
    end
    
    return anchorFrame
end

--- Same placement as the HUD tooltip hook: above FluxWindowFrame TOPLEFT (+30y).
--- @param tooltip? GameTooltip or default container; defaults to GameTooltipDefaultContainer or GameTooltip
--- @return boolean true if points were applied
function ns.ApplyHUDTooltipPosition(tooltip)
    local t = tooltip or GameTooltipDefaultContainer or GameTooltip
    if not t then return false end
    local frame = GetAnchorFrame()
    if not frame then return false end
    t:ClearAllPoints()
    t:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 30)
    return true
end

--- SetOwner(owner) for hide-on-leave / IsOwned, then place like the HUD tooltip.
--- Mirror Blizzard GameTooltip_SetDefaultAnchor: SetOwner(ANCHOR_NONE) then SetPoint the
--- actual tooltip. GameTooltip is parented to UIParent — moving only GameTooltipDefaultContainer
--- leaves the tip unanchored on post-DF retail.
--- @return boolean true if HUD position was applied to the tooltip
function ns.SetHUDTooltipOwner(tooltip, owner)
    local t = tooltip or GameTooltip
    if not t or not owner then return false end
    if t.IsForbidden and t:IsForbidden() then return false end
    t:SetOwner(owner, "ANCHOR_NONE")
    -- Sync container so UberTooltips / default-anchor paths stay consistent.
    if GameTooltipDefaultContainer and t ~= GameTooltipDefaultContainer then
        ns.ApplyHUDTooltipPosition(GameTooltipDefaultContainer)
    end
    return ns.ApplyHUDTooltipPosition(t)
end

-- LibActionButton and other non-ns chunks resolve via globals.
_G.FluxApplyHUDTooltipPosition = ns.ApplyHUDTooltipPosition
_G.FluxSetHUDTooltipOwner = ns.SetHUDTooltipOwner

local function ApplyTooltipPosition(tooltip)
    ns.ApplyHUDTooltipPosition(tooltip)
end

-- ---------------------------------------------------------------------------
-- 1. Immediate Hook (Don't wait for LOGIN)
-- ---------------------------------------------------------------------------

-- Hook default anchor to redirect to our position
-- We hook this immediately so it catches even the earliest tooltips
-- Flux compat: guard so Classic Era builds without GameTooltip_SetDefaultAnchor
-- (very old Wrath/Vanilla clients) don't raise on addon load.
if _G.GameTooltip_SetDefaultAnchor then
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if not tooltip then return end

        -- Check if this is one of the main tooltips
        local isMainTooltip = (tooltip == GameTooltip) or (tooltip == GameTooltipDefaultContainer)

        -- If it's a main tooltip and anchored to World/UIParent (default behavior), override it
        if isMainTooltip and (parent == UIParent or parent == nil) then
            ApplyTooltipPosition(tooltip)
        end
    end)
end

-- ---------------------------------------------------------------------------
-- 2. Edit Mode & Initialization (On LOGIN)
-- ---------------------------------------------------------------------------

local function SetupEditModeOverride()
    local tooltipFrame = GameTooltipDefaultContainer or GameTooltip
    if not tooltipFrame then return end

    -- Remove from Edit Mode (Retail only)
    if FLUX_API and FLUX_API.hasEditMode and FluxRemoveFrameFromEditMode then
        FluxRemoveFrameFromEditMode(tooltipFrame)
        
        -- Aggressive opt-out
        if tooltipFrame.SetMovable then tooltipFrame:SetMovable(true) end
        
        if tooltipFrame.SetUserPlaced then
             if not tooltipFrame:IsMovable() and tooltipFrame.SetMovable then
                 tooltipFrame:SetMovable(true)
             end
             
             if tooltipFrame:IsMovable() then
                 tooltipFrame:SetUserPlaced(true)
             end
        end
        
        -- Restore position if Edit Mode tries to mess with it
        if EventRegistry and EventRegistry.RegisterCallback then
            local function Reapply()
                ApplyTooltipPosition(tooltipFrame)
            end
            
            EventRegistry:RegisterCallback("EditMode.Enter", Reapply)
            EventRegistry:RegisterCallback("EditMode.Exit", Reapply)
        end
    end
    
    -- Initial application
    ApplyTooltipPosition(tooltipFrame)
end

-- Startup event
local startupFrame = CreateFrame("Frame")
startupFrame:RegisterEvent("PLAYER_LOGIN")
startupFrame:SetScript("OnEvent", function()
    -- Ensure FluxWindowFrame is initialized
    if FluxWindowFrame and FluxWindowFrame.GetFrame then
        FluxWindowFrame:GetFrame() -- Force create if not created
    end
    
    -- Setup Edit Mode overrides
    SetupEditModeOverride()
    
    -- Re-apply one more time after a short delay to fight other addons
    C_Timer.After(2, function()
        local tooltipFrame = GameTooltipDefaultContainer or GameTooltip
        if tooltipFrame then
            ApplyTooltipPosition(tooltipFrame)
        end
    end)
end)

