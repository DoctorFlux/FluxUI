--[[
    ExtraButtonSystem/Engine/Util.lua
    Utility functions for FluxButton System
    Ring border management, class color handling, button styling
    Based on FluxButtonUtil.lua
]]

local FluxButtonUtil = {}

-- Default settings
FluxButtonUtil.ClassColorSettings = {
    enabled = true,
    defaultColor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
    accountScopeColor = {r = 0.8, g = 0.8, b = 0.8, a = 1.0},
    scope = "character",
}

-- Force enable class colors on legacy clients
local function IsLegacyClient()
    return FLUX_API and FLUX_API.isLegacyClient
end

if IsLegacyClient() then
    FluxButtonUtil.ClassColorSettings.enabled = true
end

-- Get current player's class color (using Blizzard's RAID_CLASS_COLORS like FluxBorder.lua)
function FluxButtonUtil:GetClassColor()
    local _, classFilename = UnitClass("player")
    return RAID_CLASS_COLORS[classFilename] or { r = 0.6, g = 0.6, b = 0.6 }
end

-- Return the effective class color for ring/empty-slot styling (follows General → Appearance accent when enabled).
function FluxButtonUtil.GetEffectiveClassColor()
    local self = FluxButtonUtil
    if self.ClassColorSettings and self.ClassColorSettings.enabled then
        if FluxBorder and FluxBorder.GetThemedVertexRGB then
            return FluxBorder:GetThemedVertexRGB()
        end
        local c = self:GetClassColor()
        return c.r, c.g, c.b
    end
    local d = self.ClassColorSettings.defaultColor or { r=1, g=1, b=1 }
    return d.r, d.g, d.b
end

-- Themed RGB for a given scope: class/character → General → Appearance accent; account/realm/nil → settings colors.
-- ExtraButtons category windows pass forceClassColor=true on ApplyExtraButtonRingBorder to keep raw class for class/character.
function FluxButtonUtil:GetThemedScopeVertexRGB(scope)
    if scope and (scope == "class" or scope == "character") then
        if FluxBorder and FluxBorder.GetThemedVertexRGB then
            return FluxBorder:GetThemedVertexRGB()
        end
        local c = self:GetClassColor()
        return c.r, c.g, c.b
    elseif scope == "account" or scope == "realm" then
        local color = self.ClassColorSettings.accountScopeColor
        return color.r, color.g, color.b
    end
    local color = self.ClassColorSettings.defaultColor
    return color.r, color.g, color.b
end

-- Update class color settings
function FluxButtonUtil.UpdateClassColorSettings(settings)
    if type(settings) ~= "table" then return end
    if settings.enabled ~= nil then FluxButtonUtil.ClassColorSettings.enabled = not not settings.enabled end
    if type(settings.scope) == "string" then FluxButtonUtil.ClassColorSettings.scope = settings.scope end
    if type(settings.defaultColor) == "table" then FluxButtonUtil.ClassColorSettings.defaultColor = settings.defaultColor end
    if type(settings.accountScopeColor) == "table" then FluxButtonUtil.ClassColorSettings.accountScopeColor = settings.accountScopeColor end
end

-- =====================================================================
-- Item ID Helper Functions
-- =====================================================================

-- Helper function to get item ID from various item identifiers
-- Supports: number (direct ID), item link ("item:12345"), item name
function FluxButtonUtil.GetItemIDFromIdentifier(itemIdentifier)
    if not itemIdentifier then return nil end
    
    if type(itemIdentifier) == "number" then
        return itemIdentifier
    elseif type(itemIdentifier) == "string" then
        -- Try to extract item ID from item link
        local itemIdFromLink = itemIdentifier:match("item:(%d+)")
        if itemIdFromLink then
            return tonumber(itemIdFromLink)
        end
        
        -- Try to get item ID from name using GetItemInfo
        if GetItemInfo then
            local name, link = GetItemInfo(itemIdentifier)
            if link then
                local itemId = link:match("item:(%d+)")
                if itemId then
                    return tonumber(itemId)
                end
            end
        end
        
        -- Try C_Item.GetItemIDForItemInfo for retail
        if C_Item and C_Item.GetItemIDForItemInfo then
            local ok, itemId = pcall(C_Item.GetItemIDForItemInfo, itemIdentifier)
            if ok and itemId then
                return itemId
            end
        end
    end
    
    return nil
end

-- Get item info safely (works on both retail and classic)
function FluxButtonUtil.SafeGetItemInfo(itemIdentifier)
    if not itemIdentifier then return nil end
    
    -- Modern Retail API
    if C_Item and C_Item.GetItemInfo then
        local ok, result = pcall(C_Item.GetItemInfo, itemIdentifier)
        if ok and result then
            return result.name, result.itemLink, result.quality, result.itemLevel, 
                   result.minLevel, result.itemType, result.itemSubType, result.stackCount,
                   result.invType, result.iconFileID, result.sellPrice
        end
    end
    
    -- Fallback to global GetItemInfo
    if GetItemInfo then
        return GetItemInfo(itemIdentifier)
    end
    
    return nil
end

-- Get item icon safely
function FluxButtonUtil.SafeGetItemIcon(itemIdentifier)
    -- Modern Retail API
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, itemIdentifier)
        if ok and icon then return icon end
    end
    
    -- Fallback to global GetItemIcon
    if GetItemIcon then
        local ok, icon = pcall(GetItemIcon, itemIdentifier)
        if ok and icon then return icon end
    end
    
    -- Try GetItemInfo as last resort
    local _, _, _, _, _, _, _, _, _, iconFileID = FluxButtonUtil.SafeGetItemInfo(itemIdentifier)
    if iconFileID then return iconFileID end
    
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Apply ring border to a button
function FluxButtonUtil:ApplyRingBorder(button, scope, useClassColor)
    if not button or not button.WNormalTexture then
        return
    end
    
    local normalTexture = button.WNormalTexture
    normalTexture:SetAlpha(1)
    
    -- Apply proper sizing for pre-Dragonflight clients
    self:AdjustRingBorderSizeForClient(button)
    
    if scope == "account" or scope == "realm" then
        local color = self.ClassColorSettings.accountScopeColor
        normalTexture:SetVertexColor(color.r, color.g, color.b, color.a)
    elseif useClassColor and self.ClassColorSettings.enabled then
        local r, g, b = self:GetThemedScopeVertexRGB("class")
        normalTexture:SetVertexColor(r, g, b, 1.0)
    else
        local color = self.ClassColorSettings.defaultColor
        normalTexture:SetVertexColor(color.r, color.g, color.b, color.a)
    end
end

-- =====================================================================
-- PRE-DRAGONFLIGHT RING BORDER SIZING
-- Gate on FLUX_API.isPreDF / isPostDF (Forever is 1.x but post-DF).
-- Style.SizeRing is the owner; leftover sizing below is a fallback only.
-- =====================================================================

-- Forever is camelot / isPostDF even on a 1.x build; never use majorVersion alone.
-- Era/Anni are isAnyClassic even if a camelot probe misfires.
local function IsPreDragonflight()
	local C = _G.Flux and _G.Flux.Client
	if C then
		if C.isAnyClassic then
			return true
		end
		if C.isForever or C.isCamelot then
			return false
		end
		if C.isPreDF ~= nil then
			return C.isPreDF and true or false
		end
		if C.isPostDF ~= nil then
			return not C.isPostDF
		end
	end
	if FLUX_API then
		if FLUX_API.isAnyClassic then
			return true
		end
		if FLUX_API.isForever or FLUX_API.isCamelot then
			return false
		end
		if FLUX_API.isPreDF ~= nil then
			return FLUX_API.isPreDF and true or false
		end
		if FLUX_API.isPostDF ~= nil then
			return not FLUX_API.isPostDF
		end
	end
	return false
end

-- Ring border scale factor for pre-Dragonflight clients (legacy ring art; not used on retail DF+)
local PRE_DF_RING_BORDER_SCALE = 1.65
-- Matches Actionbars/_FluxActionBar_aniso_helpers BASE_BUTTON_W/H — proportional ring vs slot
local FLUX_ACTION_SLOT_REF = 44
-- DF+ ActionButtonTemplate default ring vs slot (fallback if native size not cached yet)
local DF_RING_W_MULT = 46 / 44
local DF_RING_H_MULT = 45 / 44
-- DF+: ignore GetWidth/GetHeight on normal texture until sane; tiny values cache as a pin-sized ring.
local DF_RING_NATIVE_MIN_DIM = 8
local function IsValidDFRingNativeDims(nw, nh)
    return type(nw) == "number" and type(nh) == "number"
        and nw >= DF_RING_NATIVE_MIN_DIM and nh >= DF_RING_NATIVE_MIN_DIM
end

-- Per-edge icon inset for flyout slot buttons; must match FluxFlyoutFrame icon anchoring.
FluxButtonUtil.FLYOUT_ICON_INSET_FRAC = 0.1125

-- Interpolates flyout quickslot ring between icon-tight (0) and full-button grid style (1).
-- innerFactor = 1 - 2*FLYOUT_ICON_INSET_FRAC; ring uses innerFactor + blend*(1-innerFactor).
FluxButtonUtil.FLYOUT_RING_VS_ICON_BLEND = 0.42
-- Post-DF only: quickslot normal reads slightly small vs the slot; pre-DF path ignores this.
FluxButtonUtil.DF_FLYOUT_NORMAL_RING_SCALE = 1.65

-- Adjust ring border size for pre-Dragonflight clients
-- Dragonflight+: same path as action bar (native ring scaled to slot); do NOT use PRE_DF_RING_BORDER_SCALE (1.65).
function FluxButtonUtil:AdjustRingBorderSizeForClient(button)
    if not button then return end

    local Flux = _G.Flux
    local Style = Flux and Flux.EBS and Flux.EBS.Style
    if Style and Style.SizeRing then
        Style.SizeRing(button)
        return
    end

    if not button.WNormalTexture then return end

    local widget = button.Widget
    if not widget then return end

    local w = math.max(0.5, widget:GetWidth() or 32)
    local h = math.max(0.5, widget:GetHeight() or 32)

    if not IsPreDragonflight() then
        if FluxActionBarAnisoHelpers and FluxActionBarAnisoHelpers.ScaleButtonTextures then
            widget._fluxScaleApplied = nil
            FluxActionBarAnisoHelpers.ScaleButtonTextures(widget, w, h)
        else
            local nt = button.WNormalTexture
            if button._fluxDFRingNative then
                local c = button._fluxDFRingNative
                if not IsValidDFRingNativeDims(c.w, c.h) then
                    button._fluxDFRingNative = nil
                end
            end
            if not button._fluxDFRingNative and nt then
                local nw, nh = nt:GetWidth(), nt:GetHeight()
                if IsValidDFRingNativeDims(nw, nh) then
                    button._fluxDFRingNative = { w = nw, h = nh }
                end
            end
            if button._fluxDFRingNative then
                nt:SetSize(
                    button._fluxDFRingNative.w * (w / FLUX_ACTION_SLOT_REF),
                    button._fluxDFRingNative.h * (h / FLUX_ACTION_SLOT_REF)
                )
            else
                nt:SetSize(w * DF_RING_W_MULT, h * DF_RING_H_MULT)
            end
            nt:ClearAllPoints()
            nt:SetPoint("CENTER", widget, "CENTER", 0, 0)
        end
        return
    end

    -- Pre-Dragonflight: explicit sizing (template defaults are unreliable).
    -- Always 1.65 — do not use hasEditMode 1.025 (that slot-sizes Extra rings).
    local scale = PRE_DF_RING_BORDER_SCALE

    button.WNormalTexture:SetSize(w * scale, h * scale)
    button.WNormalTexture:ClearAllPoints()
    button.WNormalTexture:SetPoint("CENTER", widget, "CENTER", 0, 0)
end

-- Equip border: capture each client's template size once at FluxButton create
-- (Classic XML 62×62, retail atlas useAtlasSize). ButtonForge never resizes
-- WBorder; we scale that captured native size with the widget.
-- IMPORTANT: Flux Extra slots are Core.BUTTON_SIZE (32), not action-bar 44/45 —
-- using 45 as ref made the glow too small on Extra buttons / badges.
function FluxButtonUtil:CaptureEquipBorderNative(button)
    if not button then return end
    local widget = button.Widget or button
    local border = button.WBorder or (widget and widget.Border)
    if not widget or not border then return end
    if button._fluxEquipBorderNative and button._fluxEquipBorderNative.w then
        return button._fluxEquipBorderNative
    end

    -- Restore template art so GetWidth reflects design size, not a prior SetSize.
    if IsPreDragonflight() then
        if border.SetTexture then
            border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        end
        if border.SetBlendMode then
            pcall(border.SetBlendMode, border, "ADD")
        end
        -- Classic ActionButtonTemplate explicit size.
        border:SetSize(62, 62)
        border:ClearAllPoints()
        border:SetPoint("CENTER", widget, "CENTER", 0, 0)
    else
        if border.SetAtlas then
            -- useAtlasSize=true — same as ActionButtonTemplate on DF+.
            pcall(border.SetAtlas, border, "UI-HUD-ActionBar-IconFrame-Border", true)
        elseif border.SetTexture then
            border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            border:SetSize(62, 62)
        end
        border:ClearAllPoints()
        -- Retail template anchors TOPLEFT; CENTER is fine once we scale explicitly.
        border:SetPoint("CENTER", widget, "CENTER", 0, 0)
    end

    local nw = border.GetWidth and border:GetWidth() or 0
    local nh = border.GetHeight and border:GetHeight() or 0
    if not nw or nw < 8 then nw = 62 end
    if not nh or nh < 8 then nh = 62 end

    local rw = widget.GetWidth and widget:GetWidth() or 0
    local rh = widget.GetHeight and widget:GetHeight() or 0
    local fallback = (FluxButtonCore and FluxButtonCore.BUTTON_SIZE) or 32
    if not rw or rw < 8 then rw = fallback end
    if not rh or rh < 8 then rh = fallback end

    local native = { w = nw, h = nh, refW = rw, refH = rh }
    button._fluxEquipBorderNative = native
    if widget then
        widget._fluxEquipBorderNative = native
    end
    if border then
        border._fluxEquipBorderNative = native
    end
    return native
end

function FluxButtonUtil:AdjustEquipBorderSizeForClient(button)
    if not button then return end
    local widget = button.Widget or button
    if not widget then return end
    local border = button.WBorder or widget.Border
    if not border or not border.SetSize then return end

    local native = button._fluxEquipBorderNative
        or widget._fluxEquipBorderNative
        or self:CaptureEquipBorderNative(button)
    if not native or not native.w or not native.refW or native.refW <= 0 then
        return
    end

    local w = widget._fluxLayoutW or (widget.GetWidth and widget:GetWidth()) or native.refW
    local h = widget._fluxLayoutH or (widget.GetHeight and widget:GetHeight()) or native.refH
    w = math.max(0.5, w)
    h = math.max(0.5, h)
    -- Raw template×(slot/create) reads a touch large on 32px Extra slots / badges.
    local trim = 0.92
    local bw = native.w * (w / native.refW) * trim
    local bh = native.h * (h / native.refH) * trim

    local function apply(tex)
        if not tex or not tex.SetSize then return end
        tex:SetSize(bw, bh)
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", widget, "CENTER", 0, 0)
    end
    apply(border)
    if button.WBorder and button.WBorder ~= border then
        apply(button.WBorder)
    end
    if widget.Border and widget.Border ~= border then
        apply(widget.Border)
    end
end

--- Flyout slot buttons (SecureActionButtonTemplate): ring ~grid scale × blended inner factor; pushed/highlight track it.
function FluxButtonUtil:SyncFlyoutButtonLayerSizes(btn)
    if not btn then return end

    -- Lua: (0 or 32) == 0 — GetWidth() can be 0 before layout; without a floor the DF+ ring shrinks to a pin.
    local rw = btn:GetWidth()
    local rh = btn:GetHeight()
    if not rw or rw < 1 then rw = btn._fluxFlyoutCellW end
    if not rh or rh < 1 then rh = btn._fluxFlyoutCellH end
    local w = math.max(8, rw or 32)
    local h = math.max(8, rh or 32)
    local minDim = math.min(w, h)

    local insetFrac = self.FLYOUT_ICON_INSET_FRAC or 0.1125
    local innerFactor = math.max(0.1, 1 - 2 * insetFrac)
    local blend = tonumber(self.FLYOUT_RING_VS_ICON_BLEND) or 0.42
    if blend < 0 then blend = 0 elseif blend > 1 then blend = 1 end
    local ringDimFactor = innerFactor + (1 - innerFactor) * blend
    local iconInset = math.max(1, minDim * insetFrac)
    -- Slightly less inset when ring is blended toward full-button so highlight/pushed stay proportional.
    local layerInset = iconInset * innerFactor / ringDimFactor

    local normalTex = btn.GetNormalTexture and btn:GetNormalTexture()
    if normalTex then
        if not IsPreDragonflight() then
            -- DF+: always size from slot rect × mults; optional post-DF nudge so the ring matches perceived slot chrome.
            local boost = tonumber(self.DF_FLYOUT_NORMAL_RING_SCALE) or 1.0
            if boost < 1 then boost = 1 end
            normalTex:SetSize(
                w * DF_RING_W_MULT * ringDimFactor * boost,
                h * DF_RING_H_MULT * ringDimFactor * boost
            )
        else
            -- Pre-DF flyouts: SecureActionButtonTemplate — full 1.65 ring scale.
            local scale = PRE_DF_RING_BORDER_SCALE
            normalTex:SetSize(w * scale * ringDimFactor, h * scale * ringDimFactor)
        end
        normalTex:ClearAllPoints()
        normalTex:SetPoint("CENTER", btn, "CENTER", 0, 0)
        normalTex:SetDrawLayer("OVERLAY", 0)
    end

    local pushedTex = btn.GetPushedTexture and btn:GetPushedTexture()
    if pushedTex then
        pushedTex:ClearAllPoints()
        pushedTex:SetPoint("TOPLEFT", btn, "TOPLEFT", layerInset, -layerInset)
        pushedTex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -layerInset, layerInset)
        pushedTex:SetDrawLayer("OVERLAY", 0)
    end

    local highlightTex = btn.GetHighlightTexture and btn:GetHighlightTexture()
    if highlightTex then
        highlightTex:ClearAllPoints()
        highlightTex:SetPoint("TOPLEFT", btn, "TOPLEFT", layerInset, -layerInset)
        highlightTex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -layerInset, layerInset)
    end

    -- Rarity / equipped glow: same 62-on-create-slot ratio as FluxButton WBorder.
    local function sizeFlyoutBorderOverlay(tex)
        if not tex then return end
        local nativeW, nativeH = 62, 62
        local ref = (FluxButtonCore and FluxButtonCore.BUTTON_SIZE) or 32
        if not IsPreDragonflight() and C_Texture and C_Texture.GetAtlasInfo then
            local ok, info = pcall(C_Texture.GetAtlasInfo, "UI-HUD-ActionBar-IconFrame-Border")
            if ok and type(info) == "table" then
                local aw = info.width or info.w or info.sizeX
                local ah = info.height or info.h or info.sizeY
                if type(aw) == "number" and type(ah) == "number" and aw >= 40 and ah >= 40 then
                    nativeW, nativeH = aw, ah
                    -- Atlas is authored for ~45 action slots; map through Extra create size.
                    ref = 45
                end
            end
        end
        tex:SetSize(nativeW * (w / ref) * 0.92, nativeH * (h / ref) * 0.92)
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", btn, "CENTER", 0, 0)
    end

    sizeFlyoutBorderOverlay(btn.QualityBorder)
    sizeFlyoutBorderOverlay(btn.EquippedBorder)

    -- Cooldown swipe/countdown: same rectangle as the icon (ring inset), not the full slot.
    local iw = math.max(1, w - 2 * iconInset)
    local ih = math.max(1, h - 2 * iconInset)
    btn._fluxFlyoutCooldownLogicalW = iw
    btn._fluxFlyoutCooldownLogicalH = ih
    if btn.cooldown and btn.icon then
        btn.cooldown:ClearAllPoints()
        btn.cooldown:SetAllPoints(btn.icon)
        self:EnsureCooldownAboveCount(btn)
        self:ApplyCooldownCountdownHorizontalScale(btn.cooldown, btn, iw, ih)
    elseif btn.cooldown then
        self:EnsureCooldownAboveCount(btn)
        self:ApplyCooldownCountdownHorizontalScale(btn.cooldown, btn, iw, ih)
    end
end

-- Countdown text: API font string, else first FontString region (some builds / timing).
local function FluxCooldown_FindCountdownFontString(cooldownFrame)
    if not cooldownFrame then return nil end
    if cooldownFrame.GetCountdownFontString then
        local ok, fs = pcall(function() return cooldownFrame:GetCountdownFontString() end)
        if ok and fs then return fs end
    end
    local regions = { cooldownFrame:GetRegions() }
    for i = 1, #regions do
        local r = regions[i]
        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
            return r
        end
    end
    return nil
end

-- Extra buttons are ~30-32px; Blizzard CD digits are authored for 36-45px bars.
-- SetScale on that FontString is ignored on several clients, so set pixel font.
local COUNTDOWN_FONT_RATIO = 0.26
local COUNTDOWN_FONT_MIN = 7
local COUNTDOWN_FONT_MAX = 11

local function FluxCooldown_CountdownFontPx(w, h)
    local dim = math.min(tonumber(w) or 0, tonumber(h) or 0)
    if dim < 1 then
        return nil
    end
    local px = dim * COUNTDOWN_FONT_RATIO
    if px < COUNTDOWN_FONT_MIN then
        px = COUNTDOWN_FONT_MIN
    elseif px > COUNTDOWN_FONT_MAX then
        px = COUNTDOWN_FONT_MAX
    end
    return px
end

local function FluxCooldown_ApplyDigitVisual(cooldownFrame)
    if not cooldownFrame then
        return false
    end
    if cooldownFrame._fluxHideCountdownNumbers then
        if cooldownFrame.SetHideCountdownNumbers then
            pcall(cooldownFrame.SetHideCountdownNumbers, cooldownFrame, true)
        end
        return true
    end
    if cooldownFrame.SetHideCountdownNumbers then
        pcall(cooldownFrame.SetHideCountdownNumbers, cooldownFrame, false)
    end
    local abbrev = cooldownFrame._fluxCountdownAbbrevThreshold
    if abbrev and cooldownFrame.SetCountdownAbbrevThreshold then
        pcall(cooldownFrame.SetCountdownAbbrevThreshold, cooldownFrame, abbrev)
    end
    local fontObj = cooldownFrame._fluxCountdownFontObject
    if fontObj and cooldownFrame.SetCountdownFont then
        pcall(cooldownFrame.SetCountdownFont, cooldownFrame, fontObj)
    end
    local fs = FluxCooldown_FindCountdownFontString(cooldownFrame)
    if not fs then
        return false
    end
    local px = tonumber(cooldownFrame._fluxCountdownFontPx)
    if px and px >= 6 then
        if fontObj and fs.SetFontObject and _G[fontObj] then
            pcall(fs.SetFontObject, fs, _G[fontObj])
        end
        local font, flags
        if fs.GetFont then
            local ok, f, _, fl = pcall(fs.GetFont, fs)
            if ok then
                font, flags = f, fl
            end
        end
        font = font or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
        flags = flags or "OUTLINE"
        if fs.SetFont then
            pcall(fs.SetFont, fs, font, px, flags)
        end
    end
    local w = cooldownFrame._fluxCooldownLogicalW
    local h = cooldownFrame._fluxCooldownLogicalH
    if (not w or not h) and cooldownFrame._fluxCooldownSqueezeRef then
        local ref = cooldownFrame._fluxCooldownSqueezeRef
        w = ref.GetWidth and ref:GetWidth() or 0
        h = ref.GetHeight and ref:GetHeight() or 0
    end
    local aspect = 1
    if w and h and w > 0 and h > 0 then
        aspect = w / h
        if aspect ~= aspect or aspect <= 0 then
            aspect = 1
        else
            aspect = math.max(0.25, math.min(3, aspect))
        end
    end
    -- Pixel font already matches the button; only squeeze non-square slots.
    local scale = aspect
    if not px then
        local digit = tonumber(cooldownFrame._fluxCooldownDigitScale) or 1
        if digit < 0.25 then digit = 0.25 elseif digit > 3 then digit = 3 end
        scale = math.max(0.25, math.min(3, aspect * digit))
    end
    if fs.SetScale then
        pcall(function() fs:SetScale(scale) end)
    elseif fs.SetTextScale then
        pcall(function() fs:SetTextScale(scale) end)
    end
    return true
end

-- LAB uses CooldownFrame_Set; FluxButton grids call Cooldown:SetCooldown directly.
-- NEVER hooksecurefunc SetCooldown / CooldownFrame_Set — even "per-frame" hooks can
-- bind the shared Cooldown widget method and taint nameplate aura Layout
-- (GetScaledRect restricted regions, Lua Taint: _FluxUI). Reapply squeeze via a
-- shared throttled watcher instead of one OnUpdate per cooldown.
local FLUX_CD_SQUEEZE_INTERVAL = 0.15
local fluxCdSqueezeActive = {} -- [cooldownFrame] = true
local fluxCdSqueezeCount = 0
local fluxCdSqueezeDriver = nil
local fluxCdSqueezeElapsed = 0

local function FluxCooldown_GetRemaining(cooldownFrame)
    if not cooldownFrame then return 0 end
    local function SafeNum(v)
        if v == nil then return nil end
        if issecretvalue and issecretvalue(v) then return nil end
        if canaccessvalue and not canaccessvalue(v) then return nil end
        if type(v) ~= "number" then return nil end
        return v
    end
    -- Prefer end-time math; GetCooldownDuration is often milliseconds remaining.
    if cooldownFrame.GetCooldownTimes then
        local ok, start, duration = pcall(cooldownFrame.GetCooldownTimes, cooldownFrame)
        start = ok and SafeNum(start) or nil
        duration = ok and SafeNum(duration) or nil
        if start and duration and duration > 0 then
            -- Some clients return ms; normalize to seconds if huge.
            if duration > 10000 or start > 1e10 then
                duration = duration / 1000
                start = start / 1000
            end
            local now = GetTime and GetTime() or 0
            local rem = (start + duration) - now
            if rem > 0 then
                return rem
            end
            return 0
        end
    end
    if cooldownFrame.GetCooldownDuration then
        local ok, dur = pcall(cooldownFrame.GetCooldownDuration, cooldownFrame)
        dur = ok and SafeNum(dur) or nil
        if dur and dur > 0 then
            -- Retail CooldownMixin returns ms; Classic-era builds often return seconds.
            local mainline = (WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
                or (not WOW_PROJECT_ID)
            if mainline then
                return dur / 1000
            end
            return dur
        end
    end
    return 0
end

local function FluxCooldown_UnregisterSqueeze(cooldownFrame)
    if not cooldownFrame or not fluxCdSqueezeActive[cooldownFrame] then
        return
    end
    fluxCdSqueezeActive[cooldownFrame] = nil
    fluxCdSqueezeCount = math.max(0, (fluxCdSqueezeCount or 1) - 1)
    cooldownFrame._fluxCooldownSqueezeWatcher = nil
end

local function FluxCooldown_SqueezeTick()
    for cooldownFrame in pairs(fluxCdSqueezeActive) do
        local ref = cooldownFrame._fluxCooldownSqueezeRef
        if not ref or (ref.IsForbidden and ref:IsForbidden()) then
            FluxCooldown_UnregisterSqueeze(cooldownFrame)
        elseif not cooldownFrame:IsShown() then
            FluxCooldown_UnregisterSqueeze(cooldownFrame)
        elseif FluxCooldown_GetRemaining(cooldownFrame) <= 0.05 and not cooldownFrame._fluxForceDigitScale then
            -- CD ended or hidden: drop (re-arm on next Apply with live CD).
            -- Near-square is gated at StartSqueezeWatcher (NeedsSqueeze) — do not call it
            -- here: that local is defined later and was nil → error spam.
            FluxCooldown_UnregisterSqueeze(cooldownFrame)
        else
            -- Font only — do not call ApplyCooldownCountdownHorizontalScale (re-enters watcher).
            FluxCooldown_ApplyDigitVisual(cooldownFrame)
        end
    end
    _G.FluxPerfEBSCooldownSqueezeCount = fluxCdSqueezeCount
    if fluxCdSqueezeCount <= 0 and fluxCdSqueezeDriver then
        fluxCdSqueezeDriver:SetScript("OnUpdate", nil)
        fluxCdSqueezeDriver:Hide()
        _G.FluxPerfEBSCooldownSqueezeArmed = false
    end
end

local function FluxCooldown_EnsureSqueezeDriver()
    if not fluxCdSqueezeDriver then
        fluxCdSqueezeDriver = CreateFrame("Frame")
        fluxCdSqueezeDriver:Hide()
        _G.FluxEBSCooldownSqueezeDriver = fluxCdSqueezeDriver
    end
    if fluxCdSqueezeDriver:GetScript("OnUpdate") then
        return
    end
    fluxCdSqueezeElapsed = 0
    fluxCdSqueezeDriver:SetScript("OnUpdate", function(_, dt)
        fluxCdSqueezeElapsed = fluxCdSqueezeElapsed + (dt or 0)
        if fluxCdSqueezeElapsed < FLUX_CD_SQUEEZE_INTERVAL then
            return
        end
        fluxCdSqueezeElapsed = 0
        FluxCooldown_SqueezeTick()
    end)
    fluxCdSqueezeDriver:Show()
    _G.FluxPerfEBSCooldownSqueezeArmed = true
end

--- Only register when horizontal squeeze is actually needed (non-square).
local function FluxCooldown_NeedsSqueeze(cooldownFrame, sizeRefFrame, logicalW, logicalH)
    local w, h
    if type(logicalW) == "number" and type(logicalH) == "number" and logicalW > 0 and logicalH > 0 then
        w, h = logicalW, logicalH
    elseif sizeRefFrame then
        w = sizeRefFrame.GetWidth and sizeRefFrame:GetWidth() or 0
        h = sizeRefFrame.GetHeight and sizeRefFrame:GetHeight() or 0
    end
    if not w or not h or w <= 0 or h <= 0 then
        return false
    end
	if cooldownFrame._fluxForceDigitScale then
		return true
	end
	if tonumber(cooldownFrame._fluxCountdownFontPx) then
		return true
	end
	local digit = tonumber(cooldownFrame and cooldownFrame._fluxCooldownDigitScale) or 1
	if digit < 0.25 then digit = 0.25 elseif digit > 3 then digit = 3 end
	-- Custom digit scale must keep the watcher even on square buttons; CooldownFrame_Set
	-- resets Blizzard numbers (stance mage-armor remaining was the wrong size).
	if math.abs(digit - 1) > 0.03 then
		return true
	end
	local r = w / h
	if r ~= r then return false end
	-- Near-square: Blizzard height-based digits are fine when scale is 1.
	return math.abs(r - 1) > 0.03
end

local function FluxCooldown_StartSqueezeWatcher(cooldownFrame, sizeRefFrame, logicalW, logicalH)
    if not cooldownFrame then
        return
    end
    if not FluxCooldown_NeedsSqueeze(cooldownFrame, sizeRefFrame, logicalW, logicalH) then
        FluxCooldown_UnregisterSqueeze(cooldownFrame)
        return
    end
    -- Never arm the shared OnUpdate solely from layout — require an active countdown
    -- unless a stance/managed digit scale must survive CooldownFrame_Set resets.
    if not cooldownFrame:IsShown() then
        FluxCooldown_UnregisterSqueeze(cooldownFrame)
        return
    end
    if not cooldownFrame._fluxForceDigitScale and FluxCooldown_GetRemaining(cooldownFrame) <= 0.05 then
        FluxCooldown_UnregisterSqueeze(cooldownFrame)
        return
    end
    if fluxCdSqueezeActive[cooldownFrame] then
        return
    end
    fluxCdSqueezeActive[cooldownFrame] = true
    fluxCdSqueezeCount = (fluxCdSqueezeCount or 0) + 1
    cooldownFrame._fluxCooldownSqueezeWatcher = true
    _G.FluxPerfEBSCooldownSqueezeCount = fluxCdSqueezeCount
    -- Raise count layer once when CD actually starts (not every squeeze tick).
    local owner = sizeRefFrame and (sizeRefFrame.FluxButton or sizeRefFrame.ParentButton or sizeRefFrame)
    if owner then
        FluxButtonUtil:EnsureCooldownAboveCount(owner)
    end
    FluxCooldown_EnsureSqueezeDriver()
end

local function FluxCooldown_EnsurePerFrameHook(cooldownFrame, sizeRefFrame, logicalW, logicalH)
    FluxCooldown_StartSqueezeWatcher(cooldownFrame, sizeRefFrame, logicalW, logicalH)
end

--- Keep cooldown swipe + countdown digits above stack/charge count text.
--- Retail ActionButton Count lives in TextOverlayContainer (often above default CD).
--- Reparent Count into a low holder frame so CD frame-level wins reliably.
function FluxButtonUtil:EnsureCooldownAboveCount(button)
    if not button then return end
    -- SetFrameLevel / SetParent on secure action-button children is protected in combat.
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local widget = button.Widget or button
    if not widget or not widget.GetFrameLevel then return end
    local base = widget:GetFrameLevel() or 0

    local count = button.WCount or widget.Count

    -- Dedicated band under cooldown: Count leaves TextOverlayContainer when present.
    local holder = widget._fluxCountHolder
    if not holder then
        holder = CreateFrame("Frame", nil, widget)
        holder:SetAllPoints(widget)
        holder:EnableMouse(false)
        widget._fluxCountHolder = holder
    end
    if holder.SetFrameLevel then
        pcall(holder.SetFrameLevel, holder, base + 1)
    end

    if count and holder and count.SetParent then
        local parent = count.GetParent and count:GetParent()
        if parent ~= holder then
            pcall(function()
                local pts = {}
                local n = count.GetNumPoints and count:GetNumPoints() or 0
                for i = 1, n do
                    local point, rel, relPoint, x, y = count:GetPoint(i)
                    pts[i] = { point, rel, relPoint, x, y }
                end
                count:SetParent(holder)
                count:ClearAllPoints()
                if #pts == 0 then
                    count:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -2, 2)
                else
                    for i = 1, #pts do
                        local p = pts[i]
                        local rel = p[2]
                        if not rel or rel == widget or rel == widget.TextOverlayContainer
                            or rel == parent then
                            rel = holder
                        end
                        count:SetPoint(p[1], rel, p[3], p[4] or 0, p[5] or 0)
                    end
                end
            end)
        end
        if count.SetDrawLayer then
            pcall(count.SetDrawLayer, count, "ARTWORK", 0)
        end
    elseif count then
        if count.SetDrawLayer then
            pcall(count.SetDrawLayer, count, "ARTWORK", 0)
        end
        if count.SetFrameLevel then
            pcall(count.SetFrameLevel, count, base + 1)
        end
    end

    -- HotKey/Name stay in TextOverlayContainer, still under CD.
    if widget.TextOverlayContainer and widget.TextOverlayContainer.SetFrameLevel then
        pcall(widget.TextOverlayContainer.SetFrameLevel, widget.TextOverlayContainer, base + 2)
    end

    local cdLevel = base + 20
    local function raiseCd(cd)
        if not cd then return end
        -- Cooldown often tracks parent level; turn that off so our raise sticks.
        if cd.SetUsingParentLevel then
            pcall(cd.SetUsingParentLevel, cd, false)
        elseif cd.SetUseParentLevel then
            pcall(cd.SetUseParentLevel, cd, false)
        end
        if cd.SetFrameLevel then
            pcall(cd.SetFrameLevel, cd, cdLevel)
        end
        local fs = FluxCooldown_FindCountdownFontString(cd)
        if fs then
            if fs.SetDrawLayer then
                pcall(fs.SetDrawLayer, fs, "OVERLAY", 7)
            end
            if fs.GetParent and fs.SetParent and fs:GetParent() ~= cd then
                local p = fs:GetParent()
                if p == widget or p == widget.TextOverlayContainer or p == holder
                    or (count and p == count:GetParent()) then
                    pcall(function()
                        fs:SetParent(cd)
                        fs:ClearAllPoints()
                        fs:SetPoint("CENTER", cd, "CENTER", 0, 0)
                    end)
                end
            end
            if fs.SetFrameLevel then
                pcall(fs.SetFrameLevel, fs, cdLevel + 1)
            end
        end
    end
    raiseCd(button.WCooldown or widget.cooldown)
    raiseCd(widget.chargeCooldown)
    raiseCd(button.chargeCooldown)
end

--- Scale cooldown countdown digits to the widget. Extra buttons are ~30px; the
--- default Cooldown font is authored for 36-45px action bars, and SetScale on
--- that FontString is ignored on several clients — set pixel font instead.
--- Blizzard resets countdown styling when CooldownFrame_Set runs; the watcher
--- reapplies (never hooksecurefunc SetCooldown / CooldownFrame_Set).
--- @param logicalW number|nil optional logical width (e.g. LAB row when GetWidth() is wrong)
--- @param logicalH number|nil optional logical height
function FluxButtonUtil:ApplyCooldownCountdownHorizontalScale(cooldownFrame, sizeRefFrame, logicalW, logicalH)
    if not cooldownFrame or not sizeRefFrame then return end
    cooldownFrame._fluxCooldownSqueezeRef = sizeRefFrame
    if type(logicalW) == "number" and type(logicalH) == "number" and logicalW > 0 and logicalH > 0 then
        cooldownFrame._fluxCooldownLogicalW = logicalW
        cooldownFrame._fluxCooldownLogicalH = logicalH
    else
        cooldownFrame._fluxCooldownLogicalW = nil
        cooldownFrame._fluxCooldownLogicalH = nil
    end

    local w, h
    if cooldownFrame._fluxCooldownLogicalW and cooldownFrame._fluxCooldownLogicalH then
        w, h = cooldownFrame._fluxCooldownLogicalW, cooldownFrame._fluxCooldownLogicalH
    else
        w = sizeRefFrame.GetWidth and sizeRefFrame:GetWidth() or 0
        h = sizeRefFrame.GetHeight and sizeRefFrame:GetHeight() or 0
    end
    if not w or not h or w <= 0 or h <= 0 then return end

    if not cooldownFrame._fluxHideCountdownNumbers then
        local px = FluxCooldown_CountdownFontPx(w, h)
        if px then
            cooldownFrame._fluxCountdownFontPx = px
            cooldownFrame._fluxCountdownFontObject = (math.min(w, h) < 40)
                and "GameFontHighlightSmallOutline"
                or "GameFontHighlightOutline"
            cooldownFrame._fluxForceDigitScale = true
            if not cooldownFrame._fluxCountdownAbbrevThreshold then
                cooldownFrame._fluxCountdownAbbrevThreshold = 60
            end
        end
    end

    -- Watcher must see font-px / force flags so square extras still reapply after CooldownFrame_Set.
    FluxCooldown_EnsurePerFrameHook(cooldownFrame, sizeRefFrame, logicalW, logicalH)

    if cooldownFrame._fluxHideCountdownNumbers and cooldownFrame.SetHideCountdownNumbers then
        pcall(cooldownFrame.SetHideCountdownNumbers, cooldownFrame, true)
    end

    local fs = FluxCooldown_FindCountdownFontString(cooldownFrame)
    if not fs then
        local n = (cooldownFrame._fluxCooldownFontRetryCount or 0) + 1
        if C_Timer and C_Timer.After and n <= 3 then
            cooldownFrame._fluxCooldownFontRetryCount = n
            C_Timer.After(0, function()
                if cooldownFrame._fluxCooldownSqueezeRef == sizeRefFrame then
                    FluxButtonUtil:ApplyCooldownCountdownHorizontalScale(cooldownFrame, sizeRefFrame, logicalW, logicalH)
                end
            end)
        end
        return
    end
    cooldownFrame._fluxCooldownFontRetryCount = 0

    FluxCooldown_ApplyDigitVisual(cooldownFrame)

    -- CooldownFrame_Set often rebuilds the FontString after this call; reapply next frame.
    if cooldownFrame._fluxCountdownFontPx and C_Timer and C_Timer.After and not cooldownFrame._fluxCountdownFontDeferred then
        cooldownFrame._fluxCountdownFontDeferred = true
        C_Timer.After(0, function()
            cooldownFrame._fluxCountdownFontDeferred = nil
            if cooldownFrame._fluxCooldownSqueezeRef == sizeRefFrame then
                FluxCooldown_ApplyDigitVisual(cooldownFrame)
            end
        end)
    end

    -- Optional digit nudge (e.g. shift right so corner badges don't cover host CD text).
    local ox = tonumber(cooldownFrame._fluxCountdownOffsetX) or 0
    local oy = tonumber(cooldownFrame._fluxCountdownOffsetY) or 0
    if (ox ~= 0 or oy ~= 0 or cooldownFrame._fluxCountdownOffsetApplied) and fs.ClearAllPoints and fs.SetPoint then
        pcall(function()
            fs:ClearAllPoints()
            fs:SetPoint("CENTER", cooldownFrame, "CENTER", ox, oy)
        end)
        cooldownFrame._fluxCountdownOffsetApplied = (ox ~= 0 or oy ~= 0) and true or nil
    end

    -- Re-assert CD above stack count after digit restyle.
    local owner = sizeRefFrame and (sizeRefFrame.FluxButton or sizeRefFrame.ParentButton or sizeRefFrame)
    if owner then
        self:EnsureCooldownAboveCount(owner)
        -- EnsureCooldownAboveCount may reset CENTER 0,0 — re-apply nudge.
        if (ox ~= 0 or oy ~= 0) and fs.ClearAllPoints and fs.SetPoint then
            pcall(function()
                fs:ClearAllPoints()
                fs:SetPoint("CENTER", cooldownFrame, "CENTER", ox, oy)
            end)
        end
    end
end

--- After changing FluxButton.Widget width (horizontal squeeze), resync ring, equip border, and empty-slot art.
function FluxButtonUtil:SyncFluxButtonLayerSizesToWidget(button)
    if not button or not button.Widget then return end
    -- Ring: AdjustRingBorderSizeForClient delegates to ScaleButtonTextures on DF+ (correct native ring, squeeze).
    self:AdjustRingBorderSizeForClient(button)
    self:AdjustEquipBorderSizeForClient(button)
    if button.UpdateEmptyBackground then
        button:UpdateEmptyBackground()
    end
    if button.WCooldown then
        self:EnsureCooldownAboveCount(button)
        local widget = button.Widget
        self:ApplyCooldownCountdownHorizontalScale(
            button.WCooldown,
            widget,
            widget and widget._fluxLayoutW,
            widget and widget._fluxLayoutH
        )
    end
end

-- Apply ring border for extra buttons
-- @param forceClassColor If true, always use raw class RGB (for ExtraButtons category windows)
function FluxButtonUtil:ApplyExtraButtonRingBorder(button, scope, forceClassColor)
    if not button or not button.WNormalTexture then
        return
    end
    
    local normalTexture = button.WNormalTexture
    normalTexture:SetAlpha(1)
    
    -- Apply proper sizing for pre-Dragonflight clients
    self:AdjustRingBorderSizeForClient(button)
    
    if scope and (scope == "class" or scope == "character") then
        if forceClassColor then
            local classColor = self:GetClassColor()
            normalTexture:SetVertexColor(classColor.r, classColor.g, classColor.b, 1.0)
        else
            local r, g, b = self:GetThemedScopeVertexRGB(scope)
            normalTexture:SetVertexColor(r, g, b, 1.0)
        end
    elseif scope == "account" or scope == "realm" then
        local color = self.ClassColorSettings.accountScopeColor
        normalTexture:SetVertexColor(color.r, color.g, color.b, color.a)
    else
        local color = self.ClassColorSettings.defaultColor
        normalTexture:SetVertexColor(color.r, color.g, color.b, color.a)
    end
end

-- Mount + Hearth grid buttons on clients with toy + mount collections:
-- Character-wide smart config: raw class ring + class empty tint.
-- Account-wide: match other grid buttons (themed "class" ring / empty) unless ClassColorSettings.enabled (class-color mode) — then no tint (white).
function FluxButtonUtil:ApplyNonCombatSmartCollectionButtonStyle(button, useCharacterTint)
    if not button then return end
    button._fluxSmartCollectionStyle = true
    button._fluxSmartCollectionCharacterTint = not not useCharacterTint
    button._fluxSmartCollectionAccountNeutralTint = nil

    local classColorAppearance = self.ClassColorSettings and self.ClassColorSettings.enabled

    if not button.WNormalTexture then
        if useCharacterTint then
            button.categoryScope = "character"
        elseif classColorAppearance then
            button.categoryScope = "account"
            button._fluxSmartCollectionAccountNeutralTint = true
        else
            button.categoryScope = "class"
        end
        if button.UpdateEmptyBackground then
            button:UpdateEmptyBackground()
        end
        return
    end

    self:AdjustRingBorderSizeForClient(button)
    button.WNormalTexture:SetAlpha(1)

    if useCharacterTint then
        local c = self:GetClassColor()
        button.WNormalTexture:SetVertexColor(c.r, c.g, c.b, 1.0)
        button.categoryScope = "character"
    elseif classColorAppearance then
        button.WNormalTexture:SetVertexColor(1, 1, 1, 1.0)
        button.categoryScope = "account"
        button._fluxSmartCollectionAccountNeutralTint = true
    else
        self:ApplyExtraButtonRingBorder(button, "class", false)
        button.categoryScope = "class"
    end

    if button.UpdateEmptyBackground then
        button:UpdateEmptyBackground()
    end
end

-- =====================================================================
-- CENTRALIZED BUTTON STYLING (single entry point for all button systems)
-- =====================================================================

--- Apply complete button styling based on scope
-- This is the single entry point for all button styling across the addon
-- @param button The FluxButton instance to style
-- @param scope The scope: "class", "character", "account", "realm", or nil (defaults to "class")
function FluxButtonUtil:ApplyButtonStyle(button, scope)
    if not button then return end
    button._fluxSmartCollectionStyle = nil
    button._fluxSmartCollectionCharacterTint = nil
    button._fluxSmartCollectionAccountNeutralTint = nil

    -- Store scope on button for future reference (used by UpdateEmptyBackground, ApplyVisualFeedback, etc.)
    button.categoryScope = scope or "class"
    
    -- Apply ring border color based on scope
    self:ApplyExtraButtonRingBorder(button, button.categoryScope)
    
    -- Update empty background color based on scope
    if button.UpdateEmptyBackground then
        button:UpdateEmptyBackground()
    end
end

-- Update button appearance based on usability
function FluxButtonUtil:UpdateButtonUsability(button, isUsable, notEnoughMana, useClassColor)
    if not button or not button.WNormalTexture then
        return
    end
    
    local normalTexture = button.WNormalTexture
    local classColorActive = useClassColor and self.ClassColorSettings.enabled
    
    if isUsable then
        if not classColorActive then
            normalTexture:SetVertexColor(1, 1, 1, 1)
        end
    elseif notEnoughMana then
        if not classColorActive then
            normalTexture:SetVertexColor(0.5, 0.5, 1, 1)
        end
    else
        if not classColorActive then
            normalTexture:SetVertexColor(1, 1, 1, 1)
        end
    end
end

-- Hide ring border
function FluxButtonUtil:HideRingBorder(button)
    if not button or not button.WNormalTexture then
        return
    end
    button.WNormalTexture:SetAlpha(0)
end

-- Show ring border
function FluxButtonUtil:ShowRingBorder(button)
    if not button or not button.WNormalTexture then
        return
    end
    -- Apply proper sizing for pre-Dragonflight clients
    self:AdjustRingBorderSizeForClient(button)
    button.WNormalTexture:SetAlpha(1)
end

-- Set ring border color directly
function FluxButtonUtil:SetRingBorderColor(button, r, g, b, a)
    if not button or not button.WNormalTexture then
        return
    end
    a = a or 1.0
    button.WNormalTexture:SetVertexColor(r, g, b, a)
end

-- Initialize button with proper ring border
function FluxButtonUtil:InitializeButtonRingBorder(button, buttonType, scope, category)
    if not button then
        return
    end
    
    if buttonType == "extra" then
        self:ApplyExtraButtonRingBorder(button, scope)
    else
        self:ApplyRingBorder(button, scope, true)
    end
end

-- Configuration functions
function FluxButtonUtil:SetClassColorEnabled(enabled)
    self.ClassColorSettings.enabled = enabled
end

function FluxButtonUtil:SetDefaultColor(r, g, b, a)
    self.ClassColorSettings.defaultColor = {r = r, g = g, b = b, a = a or 1.0}
end

function FluxButtonUtil:SetAccountScopeColor(r, g, b, a)
    self.ClassColorSettings.accountScopeColor = {r = r, g = g, b = b, a = a or 1.0}
end

-- Get safe spell info (modern + legacy compatible)
function FluxButtonUtil.SafeGetSpellInfo(spellIdentifier)
    if not spellIdentifier then return nil end
    
    if FLUX_API and FLUX_API.hasC_Spell and C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)
        if spellInfo then
            return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID
        end
    elseif GetSpellInfo then
        return GetSpellInfo(spellIdentifier)
    end
    return nil
end

-- Get safe spell texture (modern + legacy compatible)
function FluxButtonUtil.SafeGetSpellTexture(spellIdentifier)
    if not spellIdentifier then return nil end
    
    if FLUX_API and FLUX_API.hasC_Spell and C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellIdentifier)
    elseif GetSpellInfo then
        local _, _, icon = GetSpellInfo(spellIdentifier)
        return icon
    end
    return nil
end

-- Get safe item info (modern + legacy compatible)
function FluxButtonUtil.SafeGetItemInfo(itemIdentifier)
    if not itemIdentifier then return nil end

    if C_Item and C_Item.GetItemInfo then
        local ok, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10 = pcall(C_Item.GetItemInfo, itemIdentifier)
        if ok then
            if type(r1) == "table" then
                local t = r1
                return t.itemName or t.name, t.itemLink or t.hyperlink, t.itemQuality or t.quality,
                    t.itemLevel, t.itemMinLevel or t.minLevel, t.itemType, t.itemSubType,
                    t.itemStackCount or t.stackCount, t.itemEquipLoc or t.invType,
                    t.itemTexture or t.iconFileID
            end
            if r1 ~= nil or r2 ~= nil then
                return r1, r2, r3, r4, r5, r6, r7, r8, r9, r10
            end
        end
    end
    if GetItemInfo then
        return GetItemInfo(itemIdentifier)
    end
    return nil
end

-- Get safe item icon (modern + legacy compatible)
function FluxButtonUtil.SafeGetItemIcon(itemIdentifier)
    if not itemIdentifier then return nil end
    
    if GetItemIcon then
        return GetItemIcon(itemIdentifier)
    elseif GetItemInfo then
        local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemIdentifier)
        return icon
    end
    return nil
end

-- Get safe item count via FluxInv (Extra Buttons SoT; fail closed without FluxInv).
function FluxButtonUtil.SafeGetItemCount(itemIdentifier, includeBank, includeCharges)
    if not itemIdentifier then return 0 end

    local inv = _G.FluxInv
    if not inv then
        return 0
    end
    if inv.GetLiveCount then
        return inv.GetLiveCount(itemIdentifier, {
            includeBank = includeBank and true or false,
            charges = includeCharges ~= false,
            bags = true,
            equipped = true,
        }) or 0
    end
    if inv.GetCount then
        return inv.GetCount(itemIdentifier, {
            bank = includeBank and true or false,
            charges = includeCharges and true or false,
            bags = true,
            equipped = true,
        }) or 0
    end
    if inv.Bags and inv.Bags.GetCount and not includeBank then
        return inv.Bags.GetCount(itemIdentifier) or 0
    end
    return 0
end

-- Get class defaults
function FluxButtonUtil.GetClassDefaults()
    local _, class = UnitClass("player")
    if class then
        return {
            size = 45,
            clickBehavior = "AnyUp",
            class = class
        }
    end
    return {
        size = 45,
        clickBehavior = "AnyUp",
        class = "Unknown"
    }
end

-- Export the utility
_G.FluxButtonUtil = FluxButtonUtil

return FluxButtonUtil
