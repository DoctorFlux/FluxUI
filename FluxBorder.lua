-- FluxBorder.lua
-- Atlas-based border system for FluxUI (matching Blizzard BattlefieldMap style)
-- Provides consistent borders across Retail and Legacy clients
local addonName, ns = ...

local Border = {}
ns.Border = Border

-- Create global reference for other modules
FluxBorder = Border

-- Early BACKGROUND layer for addon frames that must draw behind grids/TrinketMenu (UnifiedBorder gap)
-- Created at load so it exists before TrinketMenu; children draw in this layer first
FluxUIBackgroundLayer = FluxUIBackgroundLayer or CreateFrame("Frame", "FluxUIBackgroundLayer", UIParent)
FluxUIBackgroundLayer:SetFrameStrata("BACKGROUND")
FluxUIBackgroundLayer:SetFrameLevel(0)
FluxUIBackgroundLayer:EnableMouse(false) -- Container only; children use explicit anchors

-- Get player class color (raw; for gameplay / explicit use)
-- Flux perf T3.3: cached per session; class doesn't change at runtime. Invalidated
-- on PLAYER_ENTERING_WORLD (covers login/reload) just in case the token changes.
local _classAccentCache
local function GetClassColor()
    if _classAccentCache then return _classAccentCache end
    local _, classFilename = UnitClass("player")
    local c = RAID_CLASS_COLORS[classFilename] or { r = 0.6, g = 0.6, b = 0.6 }
    _classAccentCache = { r = c.r, g = c.g, b = c.b }
    return _classAccentCache
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        _classAccentCache = nil
    end)
end

-- Weak registry of frames that received FluxBorder (for live accent refresh from options)
Border._accentFrames = Border._accentFrames or setmetatable({}, { __mode = "k" })

-- Blizzard StatusTrackingBar underlay on Interface\TargetingFrame\UI-StatusBar.
-- wow-ui-source-forever StatusTrackingBarTemplate.xml: <Color r=".502" g=".443" b=".278" />
local FOREVER_DEFAULT_ATLAS_R = 0.502
local FOREVER_DEFAULT_ATLAS_G = 0.443
local FOREVER_DEFAULT_ATLAS_B = 0.278
-- Currency strip draws that gold through the shaded UI-StatusBar texture at 0.8 alpha.
-- A flat backdrop at the raw gold is much lighter, so the fill is pulled toward the bar.
local FOREVER_BACKDROP_SHADE = 0.5

local function IsForeverClient()
    local client = _G.Flux and _G.Flux.Client
    if client and (client.isCamelot or client.isForever) then
        return true
    end
    local api = _G.FLUX_API
    if api and (api.isCamelot or api.isForever) then
        return true
    end
    return false
end

--- True when Default atlas stays untinted. Forever uses Blizzard's status-bar gold instead.
function Border:IsUntintedAtlasAccent()
    return self:GetAccentMode() == "atlas" and not IsForeverClient()
end

--- Blizzard Forever chrome gold, or nil on every other client.
function Border:GetForeverClientChromeRGB()
    if not IsForeverClient() then
        return nil
    end
    return FOREVER_DEFAULT_ATLAS_R, FOREVER_DEFAULT_ATLAS_G, FOREVER_DEFAULT_ATLAS_B
end

--- Shaded panel fill that matches the Forever currency bar. Nil on every other client.
function Border:GetForeverClientBackdropRGB()
    local r, g, b = self:GetForeverClientChromeRGB()
    if not r then
        return nil
    end
    return r * FOREVER_BACKDROP_SHADE, g * FOREVER_BACKDROP_SHADE, b * FOREVER_BACKDROP_SHADE
end

--- Resolve themed accent RGB + mode string ("class"|"atlas"|"custom") from FluxOptions when loaded.
function Border:GetAccentColor()
    local db = FluxOptions and FluxOptions.db and FluxOptions.db.profile and FluxOptions.db.profile.appearance
    if not db then
        local c = GetClassColor()
        return c.r, c.g, c.b, "class"
    end
    local mode = db.borderAccent or "class"
    if mode == "atlas" then
        if IsForeverClient() then
            return FOREVER_DEFAULT_ATLAS_R, FOREVER_DEFAULT_ATLAS_G, FOREVER_DEFAULT_ATLAS_B, "atlas"
        end
        return 1, 1, 1, "atlas"
    elseif mode == "custom" then
        local ca = db.customAccent or {}
        local r = tonumber(ca.r) or 1
        local g = tonumber(ca.g) or 1
        local b = tonumber(ca.b) or 1
        return r, g, b, "custom"
    end
    local c = GetClassColor()
    return c.r, c.g, c.b, "class"
end

function Border:RefreshAllAccentedFrames()
    if not self._accentFrames then return end
    for frame in pairs(self._accentFrames) do
        if frame and frame.GetObjectType then
            local opts = frame._FluxBorderTintOpts
            if opts then
                self:SetClassColor(frame, opts.alpha, opts.tintBackdrop)
            else
                local r, g, b = self:GetAccentColor()
                self:SetBorderColor(frame, r, g, b, 1)
            end
        end
    end
end

--- @return string "class"|"atlas"|"custom"
function Border:GetAccentMode()
    local _, _, _, mode = self:GetAccentColor()
    return mode
end

--- Vertex RGB for texture tinting: untinted atlas → (1,1,1); Forever default atlas → Blizzard gold; else accent.
function Border:GetThemedVertexRGB()
    local r, g, b, mode = self:GetAccentColor()
    if mode == "atlas" and not IsForeverClient() then
        return 1, 1, 1
    end
    return r, g, b
end

--- Backdrop fill RGB (e.g. class*0.4 style): untinted atlas → neutral dark; Forever default atlas → shaded status-bar gold; else accent scaled.
function Border:GetThemedBackdropFillRGB()
    local r, g, b, mode = self:GetAccentColor()
    if mode == "atlas" then
        if IsForeverClient() then
            return r * FOREVER_BACKDROP_SHADE, g * FOREVER_BACKDROP_SHADE, b * FOREVER_BACKDROP_SHADE
        end
        return 0.15, 0.15, 0.15
    end
    return r * 0.4, g * 0.4, b * 0.4
end

--- Reapply border accent and all registered appearance dependents (options / profile change).
function Border:RefreshAppearanceDependents()
    if FluxOptions_ApplyConfigWindowAppearance then
        FluxOptions_ApplyConfigWindowAppearance()
    end
    self:RefreshAllAccentedFrames()
    if FluxDetailsWoWSkinTint and FluxDetailsWoWSkinTint.RefreshAllEmbeddedInstances then
        FluxDetailsWoWSkinTint.RefreshAllEmbeddedInstances()
    end
    if FluxUnifiedBorder and FluxUnifiedBorder.RefreshGapAppearance then
        FluxUnifiedBorder.RefreshGapAppearance()
    end
    if FluxStatusBarUpdateLayout then
        FluxStatusBarUpdateLayout()
    end
    if FluxInfoFrame and FluxInfoFrame.RefreshIntegratedStripBackdrop then
        pcall(FluxInfoFrame.RefreshIntegratedStripBackdrop)
    end
    if UpdateGoldBar then
        UpdateGoldBar()
    end
    if FluxActionBar_ApplyAppearanceAccent then
        FluxActionBar_ApplyAppearanceAccent()
    end
    if FluxNonCombatGrid_ApplyAppearanceAccent then
        FluxNonCombatGrid_ApplyAppearanceAccent()
    end
    if FluxCombatGrid_ApplyAppearanceAccent then
        FluxCombatGrid_ApplyAppearanceAccent()
    end
    if FluxTrinketMenu_ApplyAppearanceAccent then
        FluxTrinketMenu_ApplyAppearanceAccent()
    end
    local Flux = _G.Flux or ns.Flux
    if Flux and Flux.Flyout and Flux.Flyout.ApplyAppearanceAccent then
        Flux.Flyout.ApplyAppearanceAccent()
    elseif Flux and Flux.EBS and Flux.EBS.Flyout and Flux.EBS.Flyout.ApplyAppearanceAccent then
        Flux.EBS.Flyout.ApplyAppearanceAccent()
    end
    if FluxUnitFrames_RefreshAppearanceChrome then
        FluxUnitFrames_RefreshAppearanceChrome()
    end
    if FluxWindowFrame_RefreshTabAccent then
        FluxWindowFrame_RefreshTabAccent()
    end
    if FluxAddonPopup_RefreshAccent then
        FluxAddonPopup_RefreshAccent()
    end
    if FluxMinimapToMicro_RefreshPopupAccent then
        FluxMinimapToMicro_RefreshPopupAccent()
    end
    if FluxMinimap_ApplyAppearanceAccent then
        FluxMinimap_ApplyAppearanceAccent()
    end
    if FluxCastBar_ApplyAppearanceAccent then
        FluxCastBar_ApplyAppearanceAccent()
    end
end

function FluxUI_RefreshAppearance()
    Border:RefreshAppearanceDependents()
end

-- Compatibility function for SetColorTexture
local function SetColorTexture_Compat(texture, r, g, b, a)
    if not texture then return end
    if texture.SetColorTexture then
        texture:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
    else
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    end
end

-- Check if modern atlas textures are available.
-- Flux perf T3.3: atlas availability is a client capability and cannot change
-- at runtime. Resolve once at load and keep the cached boolean; ApplyTo is a
-- hot path during nested border creation at login.
local _useAtlasResolved = nil
local function _ResolveUseAtlas()
    if C_Texture and C_Texture.GetAtlasInfo then
        return C_Texture.GetAtlasInfo("battlefieldminimap-border-topleft") ~= nil
    elseif GetAtlasInfo then
        return GetAtlasInfo("battlefieldminimap-border-topleft") ~= nil
    end
    return false
end
_useAtlasResolved = _ResolveUseAtlas()
Border._useAtlas = _useAtlasResolved

function Border:CanUseAtlases()
    return _useAtlasResolved
end

-- Adjusted corner positions (reduced top padding from 13 to 6)
local atlasCorners = {
    TL = { atlas = "battlefieldminimap-border-topleft",     ox = -11, oy = 6 },
    TR = { atlas = "battlefieldminimap-border-topright",    ox = 7,   oy = 6 },
    BL = { atlas = "battlefieldminimap-border-bottomleft",  ox = -11, oy = -7 },
    BR = { atlas = "battlefieldminimap-border-bottomright", ox = 7,   oy = -7 },
}

local atlasEdges = {
    Top    = "battlefieldminimap-border-top",
    Bottom = "battlefieldminimap-border-bottom",
    Left   = "battlefieldminimap-border-left",
    Right  = "battlefieldminimap-border-right",
}

-- Legacy texture coordinates for BattlefieldMinimap.tga
local LEGACY_COORDS = {
    TL = { left = 0.824, right = 0.887, top = 0.004, bottom = 0.070, width = 16, height = 17 },
    TR = { left = 0.895, right = 0.957, top = 0.004, bottom = 0.070, width = 16, height = 17 },
    BL = { left = 0.824, right = 0.887, top = 0.078, bottom = 0.141, width = 16, height = 16 },
    BR = { left = 0.895, right = 0.957, top = 0.078, bottom = 0.141, width = 16, height = 16 },
    Top = { left = 0.004, right = 0.816, top = 0.004, bottom = 0.070, width = 208, height = 17 },
    Bottom = { left = 0.004, right = 0.816, top = 0.078, bottom = 0.141, width = 208, height = 17 },
    Left = { left = 0.004, right = 0.066, top = 0.148, bottom = 0.672, width = 16, height = 134 },
    Right = { left = 0.074, right = 0.137, top = 0.148, bottom = 0.672, width = 16, height = 134 },
}

-- Create legacy border piece using BattlefieldMinimap.tga texture
local function CreateLegacyBorderPiece(parent, layer, pieceType)
    if not parent then return nil end
    
    local texture = parent:CreateTexture(nil, layer or "ARTWORK")
    if not texture then return nil end
    
    local texturePath = "Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga"
    texture:SetTexture(texturePath)
    
    local coords = LEGACY_COORDS[pieceType]
    if coords then
        texture:SetTexCoord(coords.left, coords.right, coords.top, coords.bottom)
        texture:SetSize(coords.width, coords.height)
    end
    
    return texture
end

--- Apply atlas border to a frame (Blizzard BattlefieldMap style)
-- @param frame The frame to apply border to
-- @param padX Padding X (horizontal). Negative expands outward.
-- @param padY Padding Y (vertical). Negative expands outward. Optional, defaults to padX.
-- @param insetX Backdrop Inset X. Negative expands background outward. Optional, defaults to 0.
-- @param insetY Backdrop Inset Y. Negative expands background outward. Optional, defaults to insetX.
function Border:ApplyTo(frame, padX, padY, insetX, insetY)
    if not frame then return nil end
    if frame.FluxBorderFrame then return frame.FluxBorderFrame end -- Already has border

    -- Handle overload/defaults
    -- If called as (frame, padding, inset), map accordingly
    -- Handle overload/defaults
    -- If called as (frame, padding, inset), map accordingly
    if insetX == nil and insetY == nil then
        -- Default defaults
        padX = padX or 0
        
        -- Logic: if padY is nil, default to padX
        if padY == nil then padY = padX end
        
        insetX = insetX or 0
        insetY = insetY or insetX
    else
        -- Full signature usage
        padX = padX or 0
        padY = padY or padX
        insetX = insetX or 0
        insetY = insetY or insetX
    end

    local useAtlas = self:CanUseAtlases()
    local ar, ag, ab = self:GetAccentColor()

    -- Create a SEPARATE background frame at BACKGROUND strata
    -- This ensures backdrop is always behind everything
    local bgFrame = CreateFrame("Frame", nil, frame)
    bgFrame:SetFrameStrata("BACKGROUND")
    bgFrame:SetFrameLevel(0)
    -- Position with independent X/Y insets
    bgFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", insetX, -insetY)
    bgFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetX, insetY)

    local bg = bgFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints(bgFrame)
    SetColorTexture_Compat(bg, 0, 0, 0, 0)
    bg:Hide()

    -- Create border container frame at higher level for border pieces
    local borderFrame = CreateFrame("Frame", nil, frame)
    borderFrame:SetAllPoints()
    borderFrame:SetFrameStrata(frame:GetFrameStrata())
    borderFrame:SetFrameLevel(math.min(frame:GetFrameLevel() + 10, 65535))

    frame.FluxBorderFrame = borderFrame
    borderFrame.BackgroundFrame = bgFrame
    borderFrame.Background = bg
    
    -- Create corners at OVERLAY layer
    for key, info in pairs(atlasCorners) do
        local t
        if useAtlas then
            t = borderFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            local success = pcall(function() t:SetAtlas(info.atlas, true) end)
            if not success then
                t:SetTexture("Interface\\Buttons\\WHITE8X8")
                t:SetSize(8, 8)
            end
        else
            t = CreateLegacyBorderPiece(borderFrame, "OVERLAY", key)
        end
        
        if t then
            local point = (key == "TL" and "TOPLEFT") or (key == "TR" and "TOPRIGHT") or (key == "BL" and "BOTTOMLEFT") or "BOTTOMRIGHT"
            
            -- Padding Logic for Symmetric Inset (Positive Padding = Inward)
            -- Negative Padding = Outward Expansion
            
            local x, y = padX, -padY
            
            if key == "TR" or key == "BR" then
                x = -padX
            end
            
            if key == "BL" or key == "BR" then
                y = padY
            end
            
            t:SetPoint(point, borderFrame, point, x + info.ox, y + info.oy)
            t:SetVertexColor(ar, ag, ab, 1)
        end
        borderFrame[key] = t
    end
    
    -- Create edges helper
    local function CreateEdge(atlasName, pieceType)
        local t
        if useAtlas then
            t = borderFrame:CreateTexture(nil, "OVERLAY", nil, 7)
            local success = pcall(function() t:SetAtlas(atlasName) end)
            if not success then
                t:SetTexture("Interface\\Buttons\\WHITE8X8")
                t:SetSize(2, 2)
            end
        else
            t = CreateLegacyBorderPiece(borderFrame, "OVERLAY", pieceType)
        end
        if t then
            t:SetVertexColor(ar, ag, ab, 1)
        end
        return t
    end
    
    -- Create and position edges
    local TL, TR, BL, BR = borderFrame.TL, borderFrame.TR, borderFrame.BL, borderFrame.BR
    
    local Top = CreateEdge(atlasEdges.Top, "Top")
    local Bottom = CreateEdge(atlasEdges.Bottom, "Bottom")
    local Left = CreateEdge(atlasEdges.Left, "Left")
    local Right = CreateEdge(atlasEdges.Right, "Right")
    
    if Top and TL and TR then
        Top:SetPoint("TOPLEFT", TL, "TOPRIGHT")
        Top:SetPoint("BOTTOMRIGHT", TR, "BOTTOMLEFT")
    end
    
    if Bottom and BL and BR then
        Bottom:SetPoint("TOPLEFT", BL, "TOPRIGHT")
        Bottom:SetPoint("BOTTOMRIGHT", BR, "BOTTOMLEFT")
    end
    
    if Left and TL and BL then
        Left:SetPoint("TOPLEFT", TL, "BOTTOMLEFT")
        Left:SetPoint("BOTTOMRIGHT", BL, "TOPRIGHT")
    end
    
    if Right and TR and BR then
        Right:SetPoint("TOPLEFT", TR, "BOTTOMLEFT")
        Right:SetPoint("BOTTOMRIGHT", BR, "TOPRIGHT")
    end
    
    borderFrame.Top = Top
    borderFrame.Bottom = Bottom
    borderFrame.Left = Left
    borderFrame.Right = Right

    return borderFrame
end

--- Remove FluxBorder from a frame so ApplyTo can be called again with different padding.
function Border:RemoveFrom(frame)
    if not frame or not frame.FluxBorderFrame then
        return
    end
    local bf = frame.FluxBorderFrame
    frame.FluxBorderFrame = nil
    frame._FluxBorderTintOpts = nil
    if self._accentFrames then
        self._accentFrames[frame] = nil
    end
    if bf.BackgroundFrame then
        bf.BackgroundFrame:SetParent(nil)
        bf.BackgroundFrame:Hide()
    end
    bf:SetParent(nil)
    bf:Hide()
end

--- Set border color for all pieces
function Border:SetBorderColor(frame, r, g, b, a)
    if not frame then return end
    
    local borderFrame = frame.FluxBorderFrame
    if not borderFrame then return end
    
    a = a or 1
    
    local pieces = { "TL", "TR", "BL", "BR", "Top", "Bottom", "Left", "Right" }
    for _, key in ipairs(pieces) do
        local piece = borderFrame[key]
        if piece and piece.SetVertexColor then
            piece:SetVertexColor(r, g, b, a)
        end
    end
end

--- Set backdrop/background color (also shows the background)
function Border:SetBackdropColor(frame, r, g, b, a)
    if not frame then return end

    local borderFrame = frame.FluxBorderFrame
    if not borderFrame or not borderFrame.Background then return end

    a = a or 1
    SetColorTexture_Compat(borderFrame.Background, r, g, b, a)
    borderFrame.Background:Show()
end

--- Set backdrop alpha (convenience method)
function Border:SetBackdropAlpha(frame, alpha)
    if not frame then return end

    local borderFrame = frame.FluxBorderFrame
    if not borderFrame or not borderFrame.Background then return end

    -- Get current color and just change alpha
    local r, g, b = borderFrame.Background:GetVertexColor()
    SetColorTexture_Compat(borderFrame.Background, r, g, b, alpha)
    borderFrame.Background:Show()
end

--- Set themed accent for border (class / atlas / custom from options) and optionally backdrop
-- @param frame The frame with FluxBorder applied
-- @param alpha Optional alpha value (default 1)
-- @param tintBackdrop Optional boolean to also color backdrop (DEFAULT TRUE if not specified)
function Border:SetClassColor(frame, alpha, tintBackdrop)
    if not frame then return end

    local r, g, b = self:GetAccentColor()
    alpha = alpha or 1

    if tintBackdrop == nil then
        tintBackdrop = true
    end

    frame._FluxBorderTintOpts = { alpha = alpha, tintBackdrop = tintBackdrop }
    self._accentFrames[frame] = true

    self:SetBorderColor(frame, r, g, b, alpha)

    if tintBackdrop then
        local dr, dg, db = self:GetThemedBackdropFillRGB()
        self:SetBackdropColor(frame, dr, dg, db, 0.85)
    end
end

--- Hide the background
function Border:HideBackground(frame)
    if not frame then return end
    local borderFrame = frame.FluxBorderFrame
    if borderFrame and borderFrame.Background then
        borderFrame.Background:Hide()
    end
end

--- Show the background
function Border:ShowBackground(frame)
    if not frame then return end
    local borderFrame = frame.FluxBorderFrame
    if borderFrame and borderFrame.Background then
        borderFrame.Background:Show()
    end
end

--- The straight border edge, already bent into one circle. A live frame can
--- only draw straight pieces, so the bend is in this single texture.
local PORTRAIT_RING = "Interface\\AddOns\\_FluxUI\\Texture\\BagPortraitRing.tga"

--- @param parent Frame the ring is parented to and centered on
--- @param diameter Outer size of the ring
--- @param r number Vertex red, 0-1. Not the options accent.
--- @param g number
--- @param b number
function Border:ApplyCircle(parent, diameter, r, g, b)
    if not parent then
        return nil
    end
    diameter = tonumber(diameter) or 64
    r, g, b = r or 1, g or 1, b or 1
    local ring = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    ring:SetTexture(PORTRAIT_RING)
    ring:SetSize(diameter, diameter)
    ring:SetPoint("CENTER", parent, "CENTER", 0, 0)
    ring:SetVertexColor(r, g, b, 1)
    return ring
end

--- Update border to current themed accent (respects last SetClassColor tint options when present)
function Border:RefreshClassColor(frame)
    if not frame then return end
    local opts = frame._FluxBorderTintOpts
    if opts then
        self:SetClassColor(frame, opts.alpha, opts.tintBackdrop)
    else
        self:SetClassColor(frame, 1, true)
    end
end
