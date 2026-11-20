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
-- Art changes include borders with explicit gameplay colors, independently of tint refresh.
Border._frames = setmetatable({}, { __mode = "k" })

local STYLE_ART

function Border:GetBorderType()
    local appearance = FluxOptions and FluxOptions.db and FluxOptions.db.profile and FluxOptions.db.profile.appearance
    local borderType = appearance and appearance.borderType
    return STYLE_ART and STYLE_ART[borderType] and borderType or 1
end

function Border:GetBorderThickness(borderType)
    local art = STYLE_ART and STYLE_ART[borderType or self:GetBorderType()]
    return art and art.thickness or 100
end

local function UsesForeverBronze(borderType)
    return (borderType or Border:GetBorderType()) == 1
end

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
    return self:GetAccentMode() == "atlas" and not (IsForeverClient() and UsesForeverBronze())
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

-- Default NPC material/palette is independent of Appearance.
function Border:GetDefaultAccentRGB()
    if IsForeverClient() and UsesForeverBronze() then
        return FOREVER_DEFAULT_ATLAS_R, FOREVER_DEFAULT_ATLAS_G, FOREVER_DEFAULT_ATLAS_B
    end
    return 1,1,1
end
function Border:GetDefaultBackdropRGB()
    if IsForeverClient() and UsesForeverBronze() then
        return FOREVER_DEFAULT_ATLAS_R*FOREVER_BACKDROP_SHADE,
            FOREVER_DEFAULT_ATLAS_G*FOREVER_BACKDROP_SHADE,FOREVER_DEFAULT_ATLAS_B*FOREVER_BACKDROP_SHADE
    end
    return .15,.15,.15
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
        if IsForeverClient() and UsesForeverBronze() then
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
    if mode == "atlas" and not (IsForeverClient() and UsesForeverBronze()) then
        return 1, 1, 1
    end
    return r, g, b
end

--- Backdrop fill RGB (e.g. class*0.4 style): untinted atlas → neutral dark; Forever default atlas → shaded status-bar gold; else accent scaled.
function Border:GetThemedBackdropFillRGB()
    local r, g, b, mode = self:GetAccentColor()
    if mode == "atlas" then
        if IsForeverClient() and UsesForeverBronze() then
            return r * FOREVER_BACKDROP_SHADE, g * FOREVER_BACKDROP_SHADE, b * FOREVER_BACKDROP_SHADE
        end
        return 0.15, 0.15, 0.15
    end
    return r * 0.4, g * 0.4, b * 0.4
end

--- Reapply border accent and all registered appearance dependents (options / profile change).
function Border:RefreshAppearanceDependents()
    self:RefreshAllBorderTypes()
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

local PIECES = { "TL", "TR", "BL", "BR", "Top", "Bottom", "Left", "Right" }
-- Every added style supplies art in the same eight-piece canvas. Consumers own
-- geometry; neither registration nor live style changes touch anchors or sizes.
local NORMALIZED_COORDS = {
    TL = {211/256,227/256,1/256,18/256}, TR = {229/256,245/256,1/256,18/256},
    BL = {211/256,227/256,20/256,36/256}, BR = {229/256,245/256,20/256,36/256},
    Top = {1/256,209/256,1/256,18/256}, Bottom = {1/256,209/256,20/256,36/256},
    Left = {1/256,17/256,38/256,172/256}, Right = {19/256,35/256,38/256,172/256},
}
STYLE_ART = {
    [1] = { texture = "Interface\\AddOns\\_FluxUI\\Texture\\borders\\Battlefield100.tga", thickness = 100,
        tracks = {Top=8,Bottom=8,Left=9,Right=9.5}, coords = NORMALIZED_COORDS },
    [2] = { texture = "Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150.tga", thickness = 150, tracks = {Top=9,Bottom=7,Left=9.5,Right=9},
        accentTexture = "Interface\\AddOns\\_FluxUI\\Texture\\borders\\ForeverMetal150Tint.tga", coords = NORMALIZED_COORDS },
}
Border._pieces = setmetatable({}, { __mode = "k" })

local DEFAULT_JOIN_TRACKS={Top=8,Bottom=8,Left=9,Right=9.5}
function Border:GetJoinTracks()
    local art=STYLE_ART[self:GetBorderType()]
    return art and art.tracks or DEFAULT_JOIN_TRACKS
end

-- Core position relative to the container's left/right edge, including the
-- authored corner overhang. Both styles retain the same sixteen-unit canvas.
local function BorderGeometryScale(profile)
    if issecretvalue and issecretvalue(profile) then return 1 end
    if type(profile)=="table" or type(profile)=="userdata" then profile=profile._fluxBorderGeometryScale end
    if issecretvalue and issecretvalue(profile) then return 1 end
    if type(profile)~="number" or profile~=profile or profile<=0 or profile==math.huge then return 1 end
    return profile
end
function Border:GetSideTrackOffset(side, padding, profile)
    local tracks, scale = self:GetJoinTracks(), BorderGeometryScale(profile)
    if side == "Left" then return padding + (atlasCorners.TL.ox + tracks.Left) * scale end
    return -padding + (atlasCorners.TR.ox - 16 + tracks.Right) * scale
end

local function PieceArt(borderType, thickness, mode)
    local art = STYLE_ART[borderType]
    if not art then return nil end
    return art, mode ~= "atlas" and art.accentTexture or art.texture
end

local function RestorePiece(texture, record)
    if record.atlas then
        if pcall(texture.SetAtlas, texture, record.atlas, false) then
            if record.uv then texture:SetTexCoord(unpack(record.uv)) end
            return
        end
    end
    texture:SetTexture(record.texture or "Interface\\Buttons\\WHITE8X8")
    if record.uv then texture:SetTexCoord(unpack(record.uv)) end
end

local function NaturalArtOwner(parent)
    local p,natural,unitColor=parent,nil,nil
    while p and p~=UIParent do
        if natural==nil and p._FluxBorderNatural~=nil then natural=p._FluxBorderNatural end
        if unitColor==nil then unitColor=p._FluxBorderUnitColor end
        local owner=p._FluxBorderOwner
        if owner then
            if natural==nil and owner._FluxBorderNatural~=nil then natural=owner._FluxBorderNatural end
            if unitColor==nil then unitColor=owner._FluxBorderUnitColor end
        end
        p=p.GetParent and p:GetParent()
    end
    return natural or false,unitColor or nil
end

-- Class/NPC transitions repaint only their registered presentation owners.
-- This index contains public frame/texture references, never unit/GUID data.
local paintOwners=setmetatable({}, {__mode="k"})
local function RemovePaintOwners(texture,record)
    for _,owner in ipairs(record.paintOwners or {}) do
        local bucket=paintOwners[owner]
        if bucket then bucket[texture]=nil end
    end
    record.paintOwners=nil
end
local function IndexPaintOwners(texture,record)
    RemovePaintOwners(texture,record)
    local owners,seen={},{}
    local function Add(owner)
        if not owner or seen[owner] then return end
        seen[owner]=true;owners[#owners+1]=owner
        local bucket=paintOwners[owner]
        if not bucket then bucket=setmetatable({}, {__mode="k"});paintOwners[owner]=bucket end
        bucket[texture]=record
    end
    local parent=texture.GetParent and texture:GetParent()
    while parent and parent~=UIParent do
        Add(parent);Add(parent._FluxBorderOwner)
        parent=parent.GetParent and parent:GetParent()
    end
    record.paintOwners=owners
end
function Border:RefreshPaintOwners(object)
    local record=self._pieces[object]
    if record then IndexPaintOwners(object,record);return end
    -- Reparenting a container changes only the indexed descendants/aliases.
    local bucket=paintOwners[object]
    if not bucket then return end
    local batch={}
    for texture,r in pairs(bucket) do if self._pieces[texture]==r then batch[#batch+1]={texture,r} end end
    for _,item in ipairs(batch) do IndexPaintOwners(item[1],item[2]) end
end
local function PaintPiece(texture, record, borderType)
    record.naturalArt,record.unitColor=NaturalArtOwner(texture.GetParent and texture:GetParent())
    local mode=record.naturalArt and "atlas" or record.unitColor and "class" or Border:GetAccentMode()
    local art, texturePath = PieceArt(borderType, Border:GetBorderThickness(), mode)
    if record.current ~= borderType or record.art ~= texturePath then
        if art then
            local uv = art.coords[record.key]
            texture:SetTexture(texturePath)
            texture:SetTexCoord(uv[1], uv[2], uv[3], uv[4])
        else
            RestorePiece(texture, record)
        end
        record.current = borderType
        record.art = texturePath
        -- Capture our current native handle only after assigning authored art.
        -- Recoloring never refreshes this trust if another owner replaces it.
        local handle=texture:GetTexture()
        record.artHandle=not (issecretvalue and issecretvalue(handle)) and handle or nil
    end
    -- Aura panel outlines keep their historical faint type-1 treatment; new
    -- styles use the selected accent/natural colors with the same alpha.
    if record.themed then
        if record.naturalArt then
            texture:SetVertexColor(1,1,1,record.alpha)
        elseif record.unitColor then
            local c=record.unitColor
            texture:SetVertexColor(c.r,c.g,c.b,record.alpha)
        elseif borderType ~= 1 then
            local r, g, b = Border:GetAccentColor()
            texture:SetVertexColor(r, g, b, record.alpha)
        else
            texture:SetVertexColor(unpack(record.color))
        end
    end
end

local function RepaintOwner(frame)
    if Border.Junctions and hooksecurefunc then
        for texture,record in pairs(paintOwners[frame] or {}) do
            if Border._pieces[texture]==record then PaintPiece(texture,record,Border:GetBorderType()) end
        end
        return
    end
    -- Border can also be used without the topology observer. Preserve its
    -- historical live-parent behavior when no reparent observer is available.
    for texture,record in pairs(Border._pieces) do
        local parent=texture.GetParent and texture:GetParent()
        while parent and parent~=UIParent do
            if parent==frame or parent._FluxBorderOwner==frame then PaintPiece(texture,record,Border:GetBorderType());break end
            parent=parent.GetParent and parent:GetParent()
        end
    end
end

--- Adopt an existing corner or edge after its type-1 art/geometry are initialized.
--- The native texture itself stays the render/color owner, including secure tinting.
function Border:RegisterPiece(texture, key, themed, alpha)
    if not texture or not NORMALIZED_COORDS[key] then return end
    local record = self._pieces[texture]
    if not record then
        record = { key = key, current = 1, themed = themed, alpha = alpha or 1 }
        if texture.GetAtlas then record.atlas = texture:GetAtlas() end
        if texture.GetTexture then record.texture = texture:GetTexture() end
        if texture.GetTexCoord then record.uv = { texture:GetTexCoord() } end
        if themed then
            record.color = texture.GetVertexColor and {texture:GetVertexColor()} or {.6,.6,.6,alpha or 1}
        end
        if not record.atlas and not record.texture then
            if self:CanUseAtlases() then
                record.atlas = atlasCorners[key] and atlasCorners[key].atlas or atlasEdges[key]
            else
                local c = LEGACY_COORDS[key]
                record.texture = "Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga"
                record.uv = { c.left, c.right, c.top, c.bottom }
            end
        end
        self._pieces[texture] = record
    else
        -- Some pooled separators reset their base art during ordinary layout.
        -- Reapply the selected style even when the setting itself did not change.
        record.current = nil
    end
    IndexPaintOwners(texture,record)
    PaintPiece(texture, record, self:GetBorderType())
    if self.Junctions then self.Junctions:Adopt(texture,record) end
end

-- Unit chrome can keep its native artwork independently of the global accent.
-- Repaint only on a classification boundary (NPC/player), not every unit update.
function Border:SetUntinted(frame,enabled)
    if not frame then return end
    enabled=enabled and true or false
    if frame._FluxBorderNatural==enabled then return end
    local unchanged=frame._FluxBorderNatural==nil and NaturalArtOwner(frame)==enabled
    frame._FluxBorderNatural=enabled
    if unchanged then return end
    RepaintOwner(frame)
end

-- Explicit per-unit class chrome uses neutral material even under global
-- Default atlas, so gold artwork cannot shift the unit's class hue.
function Border:SetUnitColor(frame,color)
    if not frame then return end
    -- False is an explicit no-unit-color boundary; nil still inherits.
    local wanted=color or false
    local old=frame._FluxBorderUnitColor
    if old==wanted or old and color and old.r==color.r and old.g==color.g and old.b==color.b then return end
    frame._FluxBorderUnitColor=wanted
    RepaintOwner(frame)
end

function Border:RefreshBorderType(frame)
    local bf = frame and frame.FluxBorderFrame
    if not bf then return end
    local borderType = self:GetBorderType()
    local thickness = self:GetBorderThickness()
    if bf._borderType == borderType and bf._borderThickness == thickness then return end
    for _, key in ipairs(PIECES) do
        local piece = bf[key]
        local record = piece and self._pieces[piece]
        if record then PaintPiece(piece, record, borderType) end
    end
    bf._borderType = borderType
    bf._borderThickness = thickness
    if bf._usesAccent then
        local r, g, b = self:GetAccentColor()
        for _, key in ipairs(PIECES) do
            local piece = bf[key]
            if piece then
                piece:SetVertexColor(r, g, b, bf._accentAlpha or 1)
            end
        end
    end
end

function Border:RefreshAllBorderTypes()
    local borderType = self:GetBorderType()
    for texture, record in pairs(self._pieces) do PaintPiece(texture, record, borderType) end
    for frame in pairs(self._frames) do self:RefreshBorderType(frame) end
    if self.Junctions then self.Junctions:Invalidate(true) end
end

-- English fallback catalog; native options controls retain the existing locale/input path.
local TYPE_TEXT = {
    name = "Border type",
    desc = "Changes shared Flux Borders, dividers and aura panels. Border type 2 uses gold artwork extracted from the WoW Forever options window and fitted to the same border canvas as type 1, on every client. Thickness is fixed by type: type 1 is 100%; type 2 is 150%. Full-frame previews follow your accent. No tint keeps the original artwork colors; the extra Forever bronze tint applies only to type 1.",
    [1] = "Border type 1", [2] = "Border type 2",
}

local function BorderTypeKeys()
    local keys = { 1 }
    for key in pairs(STYLE_ART) do if key~=1 then keys[#keys + 1] = key end end
    table.sort(keys)
    return keys
end

function Border:GetBorderPreview(borderType, width, height)
    local r, g, b, mode = self:GetAccentColor()
    if mode == "atlas" then
        if IsForeverClient() and UsesForeverBronze(borderType) then
            r, g, b = FOREVER_DEFAULT_ATLAS_R, FOREVER_DEFAULT_ATLAS_G, FOREVER_DEFAULT_ATLAS_B
        else r, g, b = 1, 1, 1 end
    end
    local file = "Interface\\AddOns\\_FluxUI\\Texture\\borders\\Preview" .. tostring(borderType)
    if borderType ~= 1 and mode ~= "atlas" then file = file .. "Tint" end
    return ("|T%s.tga:%d:%d:0:0:256:64:0:256:0:64:%d:%d:%d|t"):format(file, height or 20, width or 80,
        math.floor(r*255+.5), math.floor(g*255+.5), math.floor(b*255+.5))
end

function Border:GetBorderTypeChoices()
    local values = {}
    for _, borderType in ipairs(BorderTypeKeys()) do
        values[borderType] = (TYPE_TEXT[borderType] or ("Border type %d"):format(borderType)) .. "  " .. self:GetBorderPreview(borderType)
    end
    return values
end

function Border:CreateTypeOption(order)
    return {
        type = "select", name = TYPE_TEXT.name, desc = function()
            local previews={TYPE_TEXT.desc}
            for _,key in ipairs(BorderTypeKeys()) do
                previews[#previews+1]=(TYPE_TEXT[key] or ("Border type %d"):format(key)) .. "\n" .. self:GetBorderPreview(key,192,48)
            end
            return table.concat(previews,"\n\n")
        end, order = order, width = "full",
        values = function() return self:GetBorderTypeChoices() end, sorting = BorderTypeKeys(),
        get = function() return self:GetBorderType() end,
        set = function(_, value)
            FluxOptions.db.profile.appearance.borderType = STYLE_ART[value] and value or 1
            self:RefreshAppearanceDependents()
        end,
    }
end

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
-- @param geometryScale Optional fixed geometry factor; artwork/UVs, pads and content scale are unchanged.
function Border:ApplyTo(frame, padX, padY, insetX, insetY, geometryScale)
    if not frame then return nil end
    if frame.FluxBorderFrame then return frame.FluxBorderFrame end -- Already has border
    geometryScale = BorderGeometryScale(geometryScale)

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
    -- Nominal consumer insets are immutable. Nearby border alignment must
    -- derive its targets from the content root, not its own adjusted textures.
    borderFrame._fluxBorderInsets = {padX, padY}
    borderFrame._fluxBorderGeometryScale = geometryScale
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
            
            if geometryScale ~= 1 then
                local coords = LEGACY_COORDS[key]
                t:SetSize(coords.width * geometryScale, coords.height * geometryScale)
            end
            t:SetPoint(point, borderFrame, point, x + info.ox * geometryScale, y + info.oy * geometryScale)
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

    self._frames[frame] = true
    for _, key in ipairs(PIECES) do self:RegisterPiece(borderFrame[key], key) end
    borderFrame._usesAccent = true
    borderFrame._accentAlpha = 1
    borderFrame._borderType = 1
    borderFrame._borderThickness = 100
    -- Art swaps deliberately leave all existing anchors, dimensions and layers alone.
    self:RefreshBorderType(frame)

    return borderFrame
end

--- Open only a mini overlay's portrait-facing end. The parent's continuous
--- portrait stroke stays untouched, so hiding the mini never leaves a hole.
function Border:SetPortraitAttachment(frame, child, side, offset)
    local bf = frame and frame.FluxBorderFrame
    if not bf then return false end
    if side ~= "Left" and side ~= "Right" then side, child, offset = nil, nil, nil end
    if bf._fluxAttachmentSide == side and bf._fluxAttachmentChild == child
        and bf._fluxAttachmentOffset == offset then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    local old = bf._fluxAttachmentSide
    if old ~= side then
        for _, key in ipairs(PIECES) do
            local omitted = side == "Left" and (key == "Left" or key == "TL" or key == "BL")
                or side == "Right" and (key == "Right" or key == "TR" or key == "BR")
            local piece = bf[key]
            if piece and omitted and not piece._fluxPortraitOmitted then
                if self.Junctions then self.Junctions:Forget(piece) end
                piece._fluxPortraitOmitted = true
                piece:Hide()
            elseif piece and not omitted and piece._fluxPortraitOmitted then
                piece._fluxPortraitOmitted = nil
                self:RegisterPiece(piece, key)
                piece:Show()
            end
        end
    end
    local pad = bf._fluxBorderInsets and bf._fluxBorderInsets[1] or 0
    local scale = BorderGeometryScale(bf)
    bf:ClearAllPoints()
    if side == "Left" then
        bf:SetPoint("TOPLEFT", child, "TOPLEFT", offset - pad - atlasCorners.TL.ox * scale, 0)
        bf:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    elseif side == "Right" then
        bf:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        bf:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", offset + pad - atlasCorners.TR.ox * scale, 0)
    else bf:SetAllPoints(frame) end
    -- Hidden corner anchors still define the unchanged source height. Extend
    -- the straight artwork through their width only at the attached end.
    for _, row in ipairs({{"Top", "TL", "TR"}, {"Bottom", "BL", "BR"}}) do
        local edge, left, right = bf[row[1]], bf[row[2]], bf[row[3]]
        if edge and left and right then
            edge:ClearAllPoints()
            edge:SetPoint("TOPLEFT", left, side == "Left" and "TOPLEFT" or "TOPRIGHT", 0, 0)
            edge:SetPoint("BOTTOMRIGHT", right, side == "Right" and "BOTTOMRIGHT" or "BOTTOMLEFT", 0, 0)
        end
    end
    bf._fluxAttachmentSide, bf._fluxAttachmentChild, bf._fluxAttachmentOffset = side, child, offset
    if self.Junctions then self.Junctions:Invalidate(nil, bf, "portrait attachment") end
    return true
end

--- Remove FluxBorder from a frame so ApplyTo can be called again with different padding.
function Border:RemoveFrom(frame)
    if not frame or not frame.FluxBorderFrame then
        return
    end
    local bf = frame.FluxBorderFrame
    self._frames[frame] = nil
    for _, key in ipairs(PIECES) do
        if bf[key] then
            if self.Junctions then self.Junctions:Forget(bf[key]) end
            local record=self._pieces[bf[key]]
            if record then RemovePaintOwners(bf[key],record) end
            self._pieces[bf[key]] = nil
        end
    end
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

--- Explicitly preserve an intentional overlay (combat portrait/cast/compact unit).
function Border:SetOverlayLayer(frame,enabled)
    if not frame then return end
    if self.Junctions then self.Junctions:SetOverlay(frame,enabled)
    else frame._FluxBorderOverlay=enabled and true or nil end
end

-- Portrait fills start two units inside their host while the left stroke lies
-- on its edge. Fill that complete straight interior inset, leaving
-- the native rounded corners and every registered border piece untouched.
function Border:PreparePortraitBackdrop(frame)
    local bf=frame and frame.FluxBorderFrame
    local host=bf and bf.BackgroundFrame
    if not host or bf.PortraitBackdropFill then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    local fill=host:CreateTexture(nil,"BACKGROUND",nil,-8)
    fill:SetPoint("TOPLEFT",frame,"TOPLEFT",0,-7)
    fill:SetPoint("BOTTOMRIGHT",host,"BOTTOMLEFT",0,5)
    SetColorTexture_Compat(fill,0,0,0,0)
    fill:Hide()
    -- Both adjacent flat fills must use the border's continuous sampling at
    -- fractional HUD scales, rather than snap their common boundary apart.
    for _,texture in ipairs({bf.Background,fill}) do
        if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
        if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
    end
    bf.PortraitBackdropFill=fill
    return true
end

--- Set border color for all pieces
function Border:SetBorderColor(frame, r, g, b, a)
    if not frame then return end
    
    local borderFrame = frame.FluxBorderFrame
    if not borderFrame then return end
    borderFrame._usesAccent = false
    if self.Junctions then self.Junctions:Recolor(borderFrame,r,g,b,a or 1) end
    
    a = a or 1
    
    local pieces = { "TL", "TR", "BL", "BR", "Top", "Bottom", "Left", "Right" }
    for _, key in ipairs(pieces) do
        local piece = borderFrame[key]
        if piece and piece.SetVertexColor then
            piece:SetVertexColor(r, g, b, a)
        end
    end
end

-- Only class-color results approved for native presentation use this stream.
-- Unit ownership and public geometry remain with the existing border renderer.
function Border:SetNativeUnitColor(frame,r,g,b)
    local bf=frame and frame.FluxBorderFrame
    if not bf then return end
    for _,key in ipairs(PIECES) do
        local piece=bf[key]
        if piece then piece._FluxBorderNativeUnitRGB=true end
    end
    self:SetBorderColor(frame,r,g,b,1)
end

-- The class provider supplies RGB directly; its opacity is authored/public.
function Border:SetNativeUnitBackdrop(frame,r,g,b)
    local bf=frame and frame.FluxBorderFrame
    local bg=bf and bf.Background
    if not bg then return end
    if bg.SetColorTexture then bg:SetColorTexture(r,g,b,.85)
    else bg:SetTexture("Interface\\Buttons\\WHITE8X8");bg:SetVertexColor(r,g,b,.85) end
    bg:Show()
    local fill=bf.PortraitBackdropFill
    if fill then
        if fill.SetColorTexture then fill:SetColorTexture(r,g,b,.85)
        else fill:SetTexture("Interface\\Buttons\\WHITE8X8");fill:SetVertexColor(r,g,b,.85) end
        fill:Show()
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
    local fill=borderFrame.PortraitBackdropFill
    if fill then SetColorTexture_Compat(fill,r,g,b,a);fill:Show() end
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
    local fill=borderFrame.PortraitBackdropFill
    if fill then SetColorTexture_Compat(fill,r,g,b,alpha);fill:Show() end
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
    if frame.FluxBorderFrame then
        frame.FluxBorderFrame._usesAccent = true
        frame.FluxBorderFrame._accentAlpha = alpha
    end

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
        if borderFrame.PortraitBackdropFill then borderFrame.PortraitBackdropFill:Hide() end
    end
end

--- Show the background
function Border:ShowBackground(frame)
    if not frame then return end
    local borderFrame = frame.FluxBorderFrame
    if borderFrame and borderFrame.Background then
        borderFrame.Background:Show()
        if borderFrame.PortraitBackdropFill then borderFrame.PortraitBackdropFill:Show() end
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
