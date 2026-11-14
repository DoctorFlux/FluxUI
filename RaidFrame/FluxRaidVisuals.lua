local addonName, ns = ...

-- Flux raid visuals: tunables, compact-cell chrome, and private-aura slot counts.
-- Unit buttons are Flux-owned SecureUnitButtons. This file does not call CompactUnitFrame_Update*.

FluxRaidVisuals = {}

local floor = math.floor
local max = math.max
local min = math.min

local NATIVE_UNIT_FRAME_WIDTH = 72
local NATIVE_UNIT_FRAME_HEIGHT = 36
local POWER_BAR_HEIGHT_BASE = 8
local NATIVE_UNIT_FRAME_AURA_SIZE = 11
local AURA_ICON_BASE_WIDTH = 11
local AURA_ICON_BASE_HEIGHT = 11
local AURA_ICON_BASE_GAP = 0
local AURA_ICON_DEFAULT_SCALE = 1

local function ComputePowerBarHeightPx(scale)
    scale = tonumber(scale)
    if not scale then scale = 1 end
    return max(1, floor(POWER_BAR_HEIGHT_BASE * scale + 0.5))
end

local function AuraNumber(value, fallback)
    if issecretvalue and issecretvalue(value) then return fallback end
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then return fallback end
    return number
end

local function ScopedSizingOptions(options)
    if options == nil and FluxOptions and FluxOptions.GetRaidFrameDB then options = FluxOptions:GetRaidFrameDB() end
    if (issecretvalue and issecretvalue(options)) or type(options) ~= "table"
        or (canaccesstable and not canaccesstable(options)) then return {} end
    return options
end

local defaultSizingCache, defaultSizingManager, defaultSizingDisplayManager
function FluxRaidVisuals.GetBlizzardDefaultSizing()
    local manager, displayManager = EditModePresetLayoutManager, EditModeSettingDisplayInfoManager
    if defaultSizingCache and defaultSizingManager == manager and defaultSizingDisplayManager == displayManager
        and (defaultSizingCache.provenance == "native-default-preset" or not manager or not displayManager) then
        return defaultSizingCache
    end
    -- CompactUnitFrame's 72x36 constants are lower bounds. The source Modern
    -- preset stores offsets 26/8, which convert to 98x44. Ask the public DEFAULT
    -- preset manager so a client's native Classic/Gamepad default also applies;
    -- never read or overwrite its active Edit Mode profile.
    local width, height, provenance = 98, 44, "modern-source-fallback"
    local e = Enum
    if manager and manager.GetDefaultSettingForSystem and displayManager and displayManager.GetSystemSettingDisplayInfoMap
        and e and e.EditModeSystem and e.EditModeUnitFrameSystemIndices and e.EditModeUnitFrameSetting then
        local system, index = e.EditModeSystem.UnitFrame, e.EditModeUnitFrameSystemIndices.Raid
        local ok, resolvedWidth, resolvedHeight = pcall(function()
            local display = displayManager:GetSystemSettingDisplayInfoMap(system)
            local function value(setting)
                local raw = manager:GetDefaultSettingForSystem(system, index, setting)
                if issecretvalue and issecretvalue(raw) then return nil end
                local info = display and display[setting]
                if type(raw) ~= "number" or not info or not info.ConvertValueForDisplay then return nil end
                return AuraNumber(info:ConvertValueForDisplay(raw), nil)
            end
            return value(e.EditModeUnitFrameSetting.FrameWidth), value(e.EditModeUnitFrameSetting.FrameHeight)
        end)
        if ok and resolvedWidth and resolvedHeight then
            width, height = max(72, resolvedWidth), max(36, resolvedHeight)
            provenance = "native-default-preset"
        end
    end
    local componentScale = min(height / NATIVE_UNIT_FRAME_HEIGHT, width / NATIVE_UNIT_FRAME_WIDTH)
    defaultSizingCache = { width = width, height = height, powerBarHeight = 8,
        healthInset = 1, bottomInset = 1, joinOverlap = 1, componentScale = componentScale,
        roleIconSize = 17, readyCheckSize = 20 * componentScale, centerStatusSize = 22 * componentScale,
        miniHeight = height / 2, normalIconSize = 11, largeIconSize = 16.5, largeRoleEnabled = true,
        provenance = provenance, sourceDefaultOptions = { displayLargerRoleSpecificDebuffs = true } }
    defaultSizingManager, defaultSizingDisplayManager = manager, displayManager
    return defaultSizingCache
end

local initialSizing = FluxRaidVisuals.GetBlizzardDefaultSizing()
FluxRaidVisuals.FRAME_WIDTH = initialSizing.width
FluxRaidVisuals.FRAME_HEIGHT = initialSizing.height
FluxRaidVisuals.FRAME_HEIGHT_BASE = initialSizing.height
FluxRaidVisuals.FRAME_HEIGHT_SCALE = 1
FluxRaidVisuals.COMPONENT_SCALE = initialSizing.componentScale
FluxRaidVisuals.POWER_BAR_HEIGHT = initialSizing.powerBarHeight
FluxRaidVisuals.AURA_ICON_SCALE = 1
FluxRaidVisuals.AURA_ICON_HEIGHT = initialSizing.normalIconSize
FluxRaidVisuals.AURA_ICON_WIDTH = initialSizing.normalIconSize
FluxRaidVisuals.ROLE_ICON_SIZE = initialSizing.roleIconSize
FluxRaidVisuals.MINI_FRAME_HEIGHT = initialSizing.miniHeight
FluxRaidVisuals.CELL_JOIN_OVERLAP = initialSizing.joinOverlap
FluxRaidVisuals.BLIZZARD_RAID_MANAGER_SCALE = 0.7
FluxRaidVisuals.FRAME_BASE_ALPHA = 1
FluxRaidVisuals.RANGE_ALPHA_IN_RANGE = 0.9
FluxRaidVisuals.RANGE_ALPHA_OUT_OF_RANGE = 0.44
FluxRaidVisuals.AURA_ICON_ALPHA = 0.3
FluxRaidVisuals.AURA_SWIPE_ALPHA = 0.75
FluxRaidVisuals.AURA_DURATION_FONT_SIZE = 10
FluxRaidVisuals.HIGHLIGHT_COLOR_TARGET = { 1, 1, 1 }
FluxRaidVisuals.HIGHLIGHT_COLOR_MOUSEOVER = { 1, 1, 1 }
FluxRaidVisuals.CLASS_FILL_BRIGHTNESS = 0.72
FluxRaidVisuals.CELL_INSET = 1
FluxRaidVisuals.CELL_BOTTOM_INSET = initialSizing.bottomInset
FluxRaidVisuals.AURA_LAYER_OFFSET = 32

function FluxRaidVisuals.GetAuraLayout(availableWidth, availableHeight, options)
    options = ScopedSizingOptions(options)
    local sizing = FluxRaidVisuals.GetBlizzardDefaultSizing()
    -- Pending scope edits use their own requested frame bounds, independently
    -- of the dimensions last applied to visible secure buttons.
    local frameWidth = max(1, floor(sizing.width * AuraNumber(options.memberWidthScale, 1) + .5))
    local frameHeight = max(1, floor(sizing.height * AuraNumber(options.frameHeightScale, 1) + .5))
    local powerScale = max(.5, min(2.5, AuraNumber(options.powerBarHeightScale, 1)))
    local power = options.displayPowerBar == false and 0 or ComputePowerBarHeightPx(powerScale)
    availableWidth = max(1, AuraNumber(availableWidth, frameWidth - 2))
    availableHeight = max(1, AuraNumber(availableHeight, frameHeight - 2 - power))
    local requested = AuraNumber(options.auraIconScale, AURA_ICON_DEFAULT_SCALE)
    if requested <= 0 then requested = AURA_ICON_DEFAULT_SCALE end
    requested = max(0.5, min(2.5, requested))
    local widthScale = max(0.5, min(2.5, AuraNumber(options.auraWidthScale, 1)))
    local function side(value, slot)
        local count = max(1, min(6, floor(AuraNumber(value, 6))))
        local columns, rows = math.ceil(count / 2), min(2, count)
        return { count = count, columns = columns, rows = rows, baseSlotWidth = slot, baseSlotHeight = slot,
            baseBlockWidth = columns * slot * widthScale + (columns - 1)*AURA_ICON_BASE_GAP, baseBlockHeight = rows * slot + (rows - 1)*AURA_ICON_BASE_GAP }
    end
    local buffs = side(options.maxBuffs, sizing.normalIconSize)
    -- Packed columns use each icon's actual size. Reserving boss-sized slots
    -- around ordinary debuffs creates visible gaps even when spacing is zero.
    local debuffs = side(options.maxDebuffs, sizing.normalIconSize)
    local centerGutter = min(1, availableWidth / 2)
    local physicalFitScale = min((availableWidth - centerGutter) / (buffs.baseBlockWidth + debuffs.baseBlockWidth),
        availableHeight / max(buffs.baseBlockHeight, debuffs.baseBlockHeight))
    -- The user's aura slider controls glyph size independently of frame size.
    -- Keep the physical fit as diagnostic information, never as a hidden cap:
    -- larger blocks may extend beyond the fixed frame bounds.
    local fitScale = max(1, physicalFitScale)
    local scale = requested
    for _, block in ipairs({ buffs, debuffs }) do
        block.baseSlotWidth = block.baseSlotWidth * widthScale
        block.width, block.height, block.gap = sizing.normalIconSize * scale * widthScale, sizing.normalIconSize * scale, AURA_ICON_BASE_GAP * scale
        block.slotWidth, block.slotHeight = block.baseSlotWidth * scale, block.baseSlotHeight * scale
        block.blockWidth, block.blockHeight = block.baseBlockWidth * scale, block.baseBlockHeight * scale
        block.scale = scale
    end
    return { base = { width = AURA_ICON_BASE_WIDTH * widthScale, height = AURA_ICON_BASE_HEIGHT, widthScale = widthScale, durationFontScale = FluxRaidVisuals.GetAuraDurationFontScale(options), largeIconSize = sizing.largeIconSize, gap = AURA_ICON_BASE_GAP, columns = 3, rows = 2 },
        nativeDefaults = true, normalIconSize = sizing.normalIconSize * scale, largeIconSize = sizing.largeIconSize * scale,
        largeRoleEnabled = false, sourceDefaultOptions = sizing.sourceDefaultOptions,
        scale = scale, requestedHeight = sizing.normalIconSize * requested, requestedScale = requested,
        physicalFitScale = physicalFitScale, fitScale = fitScale, overlap = scale > physicalFitScale, capped = scale < requested,
        availableWidth = availableWidth, availableHeight = availableHeight, centerGutter = centerGutter,
        width = buffs.width, height = buffs.height, gap = buffs.gap, buffs = buffs, debuffs = debuffs }
end

function FluxRaidVisuals.GetAuraDurationFontScale(options)
    return max(0.5, min(2.5, AuraNumber(ScopedSizingOptions(options).auraDurationFontScale, 1)))
end

function FluxRaidVisuals.GetAuraScaleLimit(availableWidth, availableHeight, options)
    return 2.5
end

-- Both renderers use owned health bounds; native descendants are never read.
function FluxRaidVisuals.GetFrameAuraLayout(frame, options)
    local width = max(6, FluxRaidVisuals.FRAME_WIDTH - 2)
    local power = frame.powerBarUsedHeight or FluxRaidVisuals.POWER_BAR_HEIGHT
    local height = FluxRaidVisuals.FRAME_HEIGHT - 2 - power
    local health = frame.healthBar
    if health then
        if health.GetWidth then width = max(1, AuraNumber(health:GetWidth(), width)) end
        if health.GetHeight then height = max(1, AuraNumber(health:GetHeight(), height)) end
    end
    local layout = FluxRaidVisuals.GetAuraLayout(width, height, options)
    if frame._fluxPartyMember then
        local factor = max(.5, min(2.5, AuraNumber(ScopedSizingOptions(options).partyAuraScale, 1.5)))
        -- A party-only presentation factor; constructor geometry and saved
        -- sliders retain their existing raid-relative meaning on every client.
        for _, side in ipairs({layout.buffs, layout.debuffs}) do
            for _, key in ipairs({"width", "height", "gap", "slotWidth", "slotHeight", "blockWidth", "blockHeight", "scale"}) do
                side[key] = side[key] * factor
            end
        end
        for _, key in ipairs({"width", "height", "gap", "scale", "requestedScale", "requestedHeight", "normalIconSize", "largeIconSize"}) do
            layout[key] = layout[key] * factor
        end
        layout.overlap = layout.scale > layout.physicalFitScale
    end
    return layout
end

function FluxRaidVisuals.GetFrameAuraAnchor(frame, helpful)
    if not helpful and frame._fluxPartyMember and frame.PortraitFrame and not frame._fluxPortraitDisabled then
        return frame.PortraitFrame, "TOPRIGHT"
    end
    return frame.healthBar or frame, helpful and "TOPRIGHT" or "TOPLEFT"
end

-- Rectangular aura-panel chrome above the cooldown. Native owners tint only
-- registered Texture sinks; readable icons and previews use the same palette.
function FluxRaidVisuals.EnsurePartyDebuffBorder(button, frame)
    if not frame._fluxPartyMember then return end
    if button._fluxPartyDebuffBorder then return button._fluxPartyDebuffBorder end
    local parent = button.AuraTextLayer or button.textLayer or button
    local edges = {}
    for _, point in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local outline = parent:CreateTexture(nil, "ARTWORK", nil, 0)
        local edge = parent:CreateTexture(nil, "ARTWORK", nil, 1)
        outline:SetColorTexture(0, 0, 0, 1); edge:SetColorTexture(1, 1, 1, 1)
        if point == "TOP" or point == "BOTTOM" then
            local y = 0
            outline:SetHeight(3); edge:SetHeight(1.5)
            for _, texture in ipairs({outline, edge}) do
                texture:SetPoint(point .. "LEFT", button, point .. "LEFT", 0, y)
                texture:SetPoint(point .. "RIGHT", button, point .. "RIGHT", 0, y)
            end
        else
            local x = 0
            outline:SetWidth(3); edge:SetWidth(1.5)
            for _, texture in ipairs({outline, edge}) do
                texture:SetPoint("TOP" .. point, button, "TOP" .. point, x, 0)
                texture:SetPoint("BOTTOM" .. point, button, "BOTTOM" .. point, x, 0)
            end
        end
        edges[#edges + 1] = edge
    end
    button._fluxPartyDebuffBorders = edges
    button._fluxPartyDebuffBorder = edges[1]
    return edges[1]
end

function FluxRaidVisuals.SetPartyDebuffBorderType(button, kind, helpful)
    local edge = button._fluxPartyDebuffBorder
    if not edge then return end
    for _, texture in ipairs(button._fluxPartyDebuffBorders or {edge}) do
        if AuraUtil and AuraUtil.SetAuraBorderColor then AuraUtil.SetAuraBorderColor(texture, kind)
        else
            local color = DebuffTypeColor and (DebuffTypeColor[kind or "none"] or DebuffTypeColor.none)
            texture:SetVertexColor(color and color.r or .8, color and color.g or 0, color and color.b or 0, 1)
        end
        texture:SetShown(not helpful)
    end
end

-- Salvage's desaturated proc loop, with a pulse of the existing glow artwork
-- when the client has no proc atlas. Setup runs OOC before native adoption.
-- Native textures are never retained or inspected after registration.
function FluxRaidVisuals.CreatePartyDispelGlow(owner, frame, native, publicOwner)
    local texture = owner:CreateTexture(nil, "OVERLAY", nil, 6)
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT", -8, 8)
    texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 8, -8)
    local atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook"
    local getAtlas = C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo
    local available = getAtlas and getAtlas(atlas)
    local clock = native and owner.AddAuraShownAnimation and owner or publicOwner or owner
    local animation = clock:CreateAnimationGroup()
    animation:SetLooping("REPEAT")
    if available then
        texture:SetAtlas(atlas); texture:SetDesaturated(true)
        local flip = animation:CreateAnimation("FlipBook")
        flip:SetTarget(texture); flip:SetDuration(1)
        flip:SetFlipBookColumns(5); flip:SetFlipBookRows(6); flip:SetFlipBookFrames(30)
    else
        texture:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\borders\\glow-border")
        for index, alpha in ipairs({{.45, 1}, {1, .45}}) do
            local pulse = animation:CreateAnimation("Alpha")
            pulse:SetTarget(texture); pulse:SetOrder(index); pulse:SetDuration(.5)
            pulse:SetFromAlpha(alpha[1]); pulse:SetToAlpha(alpha[2])
        end
    end
    if native then
        owner:AddDispelTypeTexture(texture, {style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
            showWhenHarmful = true, showWhenHelpful = false, showWithoutDispelType = false})
        if owner.AddAuraShownAnimation then owner:AddAuraShownAnimation(animation)
        else
            -- Retail's current container lacks aura-shown animation bindings.
            -- A public owner drives this prepared engine loop only while the
            -- party highlight is enabled; no Lua aura polling or callbacks.
            publicOwner:HookScript("OnShow", function() animation:Play() end)
            publicOwner:HookScript("OnHide", function() animation:Stop() end)
        end
    else
        owner._fluxDispelGlowTexture = texture
        owner:HookScript("OnShow", function() animation:Play() end)
        owner:HookScript("OnHide", function() animation:Stop() end)
    end
end

local auraDurationProbe, auraDurationSizes = nil, {}
local AURA_DURATION_SAMPLES = { "59", "59m", "23h", "99d" }

function FluxRaidVisuals.GetAuraDurationFont()
    if GameFontNormalSmall and GameFontNormalSmall.GetFont then
        local font, size, flags = GameFontNormalSmall:GetFont()
        if not (issecretvalue and (issecretvalue(font) or issecretvalue(size) or issecretvalue(flags)))
            and type(font) == "string" and type(size) == "number" and size > 0 then
            return font, size, flags or ""
        end
    end
    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 10, ""
end

function FluxRaidVisuals.GetAuraDurationFontSize()
    local _, size = FluxRaidVisuals.GetAuraDurationFont()
    return size
end

function FluxRaidVisuals.GetAuraDurationTextScale(width, height)
    if (issecretvalue and issecretvalue(width)) or (issecretvalue and issecretvalue(height)) then return 0.1, false end
    width, height = tonumber(width), tonumber(height) or 15
    if not width or width <= 0 or height <= 0 then return 0.1, false end
    local font, preferred, flags = FluxRaidVisuals.GetAuraDurationFont()
    local key = font .. ":" .. flags .. ":" .. preferred .. ":" .. width .. ":" .. height
    local cached = auraDurationSizes[key]
    if cached then return cached.scale, cached.measured end
    if not auraDurationProbe then
        -- Measure public labels on one unanchored owned FontString. Native aura
        -- sinks and their restricted text/geometry are never used as probes.
        local host = CreateFrame("Frame", nil, UIParent)
        host:Hide()
        auraDurationProbe = host:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        auraDurationProbe:SetWordWrap(false)
    end
    local measure = auraDurationProbe.GetUnboundedStringWidth or auraDurationProbe.GetStringWidth
    local scale, measured = 0.5 * min(width / 12, height / 15), false
    if measure and auraDurationProbe.GetStringHeight and auraDurationProbe.SetFont and auraDurationProbe.SetTextScale then
        auraDurationProbe:SetTextScale(1)
        if auraDurationProbe:SetFont(font, preferred, flags) ~= false then
            local widest, tallest, readable = 0, 0, true
            for _, sample in ipairs(AURA_DURATION_SAMPLES) do
                auraDurationProbe:SetText(sample)
                local sampleWidth = measure(auraDurationProbe)
                local sampleHeight = auraDurationProbe:GetStringHeight()
                if (issecretvalue and (issecretvalue(sampleWidth) or issecretvalue(sampleHeight)))
                    or type(sampleWidth) ~= "number" or type(sampleHeight) ~= "number"
                    or sampleWidth <= 0 or sampleHeight <= 0 then
                    readable = false
                    break
                end
                widest, tallest = max(widest, sampleWidth), max(tallest, sampleHeight)
            end
            if readable then
                scale, measured = 0.95 * min(width / widest, height / tallest), true
            end
        end
    end
    auraDurationProbe:SetText("")
    scale = max(0.01, scale)
    auraDurationSizes[key] = { scale = scale, measured = measured }
    return scale, measured
end

-- Used by world preview (non-CUF) power bars.
FluxRaidVisuals.POWER_COLORS = {
    [0] = { r = 0.16, g = 0.33, b = 0.78 }, -- Mana
    [1] = { r = 1.00, g = 0.00, b = 0.00 }, -- Rage
    [2] = { r = 1.00, g = 0.50, b = 0.25 }, -- Focus
    [3] = { r = 1.00, g = 1.00, b = 0.00 }, -- Energy
    [6] = { r = 0.00, g = 0.82, b = 1.00 }, -- Runic Power
    [17] = { r = 0.79, g = 0.26, b = 0.99 }, -- Fury
}

local auraDurationFontObject, auraDurationFontSignature
local auraDurationFormatter, auraDurationUnderMinute
local partyDurationFormatter, partyDurationUnderMinute
function FluxRaidVisuals.GetAuraDurationFormatter(options, frame)
    if not (C_StringUtil and C_StringUtil.CreateNumericRuleFormatter and Enum and Enum.NumericRuleFormatRounding) then return nil end
    local party = frame and frame._fluxPartyMember
    local formatter = auraDurationFormatter
    if party then formatter = partyDurationFormatter end
    if InCombatLockdown and InCombatLockdown() then return formatter end
    local rounding = Enum.NumericRuleFormatRounding
    if rounding.Up == nil or rounding.Down == nil then return nil end
    local underMinute = ScopedSizingOptions(options).auraTimersUnderMinute == true
    local previous = auraDurationUnderMinute
    if party then
        local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
        underMinute = db and db.auraTimersUnderMinute == true or false
        previous = partyDurationUnderMinute
    end
    if not formatter then formatter = C_StringUtil.CreateNumericRuleFormatter() end
    if previous ~= underMinute then
        formatter:SetBreakpoints({
            {threshold=0,format="%d",step=1,rounding=rounding.Up},
            {threshold=60,format=underMinute and "" or "%dm",step=1,rounding=rounding.Down,components={{div=60}}},
            {threshold=3600,format=underMinute and "" or "%dh",step=1,rounding=rounding.Down,components={{div=3600}}},
            {threshold=86400,format=underMinute and "" or "%dd",step=1,rounding=rounding.Down,components={{div=86400}}},
        })
    end
    if party then partyDurationFormatter, partyDurationUnderMinute = formatter, underMinute
    else auraDurationFormatter, auraDurationUnderMinute = formatter, underMinute end
    return formatter
end

function FluxRaidVisuals.GetAuraDurationFontObject(options)
    if not CreateFont then return nil end
    if InCombatLockdown and InCombatLockdown() then return auraDurationFontObject end
    local font, size, flags = FluxRaidVisuals.GetAuraDurationFont(true)
    if not flags:find("OUTLINE", 1, true) then flags = flags == "" and "OUTLINE" or flags .. ",OUTLINE" end
    size = size * FluxRaidVisuals.GetAuraDurationFontScale(options)
    local signature = font .. ":" .. size .. ":" .. flags
    if not auraDurationFontObject then auraDurationFontObject = CreateFont("FluxRaidAuraDurationFont") end
    if signature ~= auraDurationFontSignature then
        auraDurationFontObject:SetFont(font, size, flags)
        auraDurationFontSignature = signature
    end
    return auraDurationFontObject
end

function FluxRaidVisuals.StyleAuraDuration(text, width, height, renderScale, fontScale)
    renderScale = renderScale or 1
    fontScale = fontScale or FluxRaidVisuals.GetAuraDurationFontScale()
    local font, size, flags = FluxRaidVisuals.GetAuraDurationFont(true)
    local fit = FluxRaidVisuals.GetAuraDurationTextScale(width / renderScale, height / renderScale)
    local fontObject = FluxRaidVisuals.GetAuraDurationFontObject()
    if fontObject then
        -- Attach once before native ownership. Later changes touch only this
        -- addon-owned font object, never a restricted FontString or aura button.
        text:SetFontObject(fontObject)
        text:SetTextScale(fit * renderScale)
    else
        text:SetFont(font, size, flags)
        text:SetTextScale(fit * renderScale * fontScale)
    end
    text:SetTextColor(1, 1, 1, 1)
    text:SetShadowColor(0, 0, 0, 1); text:SetShadowOffset(1, -1)
    text:SetWidth((width + 2 * renderScale) * (fontObject and 2.5 or max(1, fontScale)))
    text:SetWordWrap(false)
end

function FluxRaidVisuals.ApplyRaidFrameTunables(opts)
    opts = ScopedSizingOptions(opts)
    FluxRaidVisuals.GetAuraDurationFontObject(opts)
    FluxRaidVisuals.GetAuraDurationFormatter(opts)
    local wScale = tonumber(opts.memberWidthScale) or 1
    local hScale = tonumber(opts.frameHeightScale) or 1
    local pbScale = tonumber(opts.powerBarHeightScale)
    if pbScale == nil then pbScale = 1 end
    pbScale = max(0.5, min(2.5, pbScale))
    local auraScale = AuraNumber(opts.auraIconScale, AURA_ICON_DEFAULT_SCALE)
    if auraScale <= 0 then auraScale = AURA_ICON_DEFAULT_SCALE end
    local mgrScale = tonumber(opts.raidManagerScale)
    if mgrScale == nil then mgrScale = 1 end

    local baseA = tonumber(opts.frameBaseAlpha)
    if baseA == nil then baseA = 1 end
    FluxRaidVisuals.FRAME_BASE_ALPHA = max(0.1, min(1, baseA))

    local rIn = tonumber(opts.rangeAlphaInRange)
    if rIn == nil then rIn = 0.9 end
    FluxRaidVisuals.RANGE_ALPHA_IN_RANGE = max(0.05, min(1, rIn))

    local rOut = tonumber(opts.rangeAlphaOutOfRange)
    if rOut == nil then rOut = 0.44 end
    FluxRaidVisuals.RANGE_ALPHA_OUT_OF_RANGE = max(0.05, min(1, rOut))

    local auraA = tonumber(opts.auraIconAlpha)
    if auraA == nil then auraA = 1 end
    local transparency = tonumber(opts.auraTransparency)
    if transparency == nil then
        FluxRaidVisuals.AURA_ICON_ALPHA = max(0.1, min(1, auraA)) * 0.3
    else
        FluxRaidVisuals.AURA_ICON_ALPHA = max(0, min(1, 1 - transparency / 100))
    end

    local sizing = FluxRaidVisuals.GetBlizzardDefaultSizing()
    FluxRaidVisuals.FRAME_WIDTH = max(1, floor(sizing.width * wScale + .5))
    FluxRaidVisuals.FRAME_HEIGHT = max(1, floor(sizing.height * hScale + .5))
    FluxRaidVisuals.FRAME_HEIGHT_BASE = sizing.height
    FluxRaidVisuals.COMPONENT_SCALE = min(FluxRaidVisuals.FRAME_HEIGHT / NATIVE_UNIT_FRAME_HEIGHT,
        FluxRaidVisuals.FRAME_WIDTH / NATIVE_UNIT_FRAME_WIDTH)
    FluxRaidVisuals.POWER_BAR_HEIGHT = ComputePowerBarHeightPx(pbScale)
    FluxRaidVisuals.AURA_ICON_SCALE = auraScale
    FluxRaidVisuals.AURA_ICON_HEIGHT = sizing.normalIconSize * auraScale
    FluxRaidVisuals.AURA_ICON_WIDTH = sizing.normalIconSize * auraScale
    FluxRaidVisuals.ROLE_ICON_SIZE = sizing.roleIconSize
    FluxRaidVisuals.CELL_BOTTOM_INSET, FluxRaidVisuals.CELL_JOIN_OVERLAP = sizing.bottomInset, sizing.joinOverlap
    FluxRaidVisuals.MINI_FRAME_HEIGHT = FluxRaidVisuals.FRAME_HEIGHT / 2

    FluxRaidVisuals.BLIZZARD_RAID_MANAGER_SCALE = mgrScale * 0.7

    local ht = opts.highlightTarget
    if type(ht) == "table" then
        FluxRaidVisuals.HIGHLIGHT_COLOR_TARGET = {
            tonumber(ht.r) or 1,
            tonumber(ht.g) or 1,
            tonumber(ht.b) or 1,
        }
    end
    local hm = opts.highlightMouseover
    if type(hm) == "table" then
        FluxRaidVisuals.HIGHLIGHT_COLOR_MOUSEOVER = {
            tonumber(hm.r) or 1,
            tonumber(hm.g) or 1,
            tonumber(hm.b) or 1,
        }
    end
end

function FluxRaidVisuals.ApplyRaidHighlightVertexColors(frame)
    if not frame then return end
    local ct = FluxRaidVisuals.HIGHLIGHT_COLOR_TARGET
    local cm = FluxRaidVisuals.HIGHLIGHT_COLOR_MOUSEOVER
    if frame.selectionHighlight and frame.selectionHighlight.SetVertexColor then
        pcall(frame.selectionHighlight.SetVertexColor, frame.selectionHighlight, ct[1], ct[2], ct[3])
    end
    if frame.mouseOverHighlight and frame.mouseOverHighlight.SetVertexColor then
        pcall(frame.mouseOverHighlight.SetVertexColor, frame.mouseOverHighlight, cm[1], cm[2], cm[3])
    end
    if frame.targetHighlight and frame.targetHighlight.SetVertexColor then
        pcall(frame.targetHighlight.SetVertexColor, frame.targetHighlight, ct[1], ct[2], ct[3])
    end
end

--- Combat-safe SetSize for secure CUF unit buttons. Queues retry when locked.
function FluxRaidVisuals.SafeSetUnitFrameSize(frame, width, height)
    if not frame or not frame.SetSize then
        return false
    end
    width = tonumber(width) or FluxRaidVisuals.FRAME_WIDTH
    height = tonumber(height) or FluxRaidVisuals.FRAME_HEIGHT
    if InCombatLockdown and InCombatLockdown() then
        frame._fluxNeedsSizeRefresh = true
        if FluxRaid_QueueConfigureAndRefresh then
            FluxRaid_QueueConfigureAndRefresh()
        end
        return false
    end
    local ok = pcall(frame.SetSize, frame, width, height)
    if ok then
        frame._fluxNeedsSizeRefresh = nil
    else
        -- Out of combat but still blocked (taint): mark dirty; do not re-queue here
        -- (would recurse through ConfigureAndRefresh).
        frame._fluxNeedsSizeRefresh = true
    end
    return ok
end

--- Ensure Flux-only overlays exist on a CUF (mouseover ring + optional dispel tint).
function FluxRaidVisuals.EnsureFluxOverlays(frame)
    if not frame then return end

    if not frame.mouseOverHighlight then
        local tex = (frame._fluxHighlightLayer or frame):CreateTexture(nil, "OVERLAY", nil, 5)
        tex:SetAllPoints(frame)
        tex:SetAtlas("RaidFrame-TargetFrame")
        tex:SetIgnoreParentAlpha(true)
        tex:Hide()
        frame.mouseOverHighlight = tex
    end

    -- CompactUnitFrame.xml leaves aggro/selection shown; CUF Update* hides them.
    -- Flux owns those updates now â€” start hidden so they are not a white ring out of combat.
    if not frame._fluxOverlaysReady and frame.aggroHighlight and frame.aggroHighlight.Hide then
        pcall(frame.aggroHighlight.Hide, frame.aggroHighlight)
    end
    if not frame._fluxOverlaysReady and frame.selectionHighlight and frame.selectionHighlight.Hide then
        pcall(frame.selectionHighlight.Hide, frame.selectionHighlight)
    end

    -- raidframe-hp-bg-white is meant to be vertex-tinted. Untinted = white 1px ring.
    local function tintBg(tex, r, g, b)
        if tex and tex.SetVertexColor then
            pcall(tex.SetVertexColor, tex, r, g, b)
        end
    end
    tintBg(frame.background, 0.07, 0.07, 0.08)
    if frame.healthBar then
        tintBg(frame.healthBar.background, 0.07, 0.07, 0.08)
    end
    if frame.TotalAbsorbLeftShadow and frame.TotalAbsorbLeftShadow.Hide then
        pcall(frame.TotalAbsorbLeftShadow.Hide, frame.TotalAbsorbLeftShadow)
    end

    -- Migrate pre-fix texture-only highlight to Blizzard-style fill + border frame.
    if frame.dispelHighlight and not frame.dispelHighlight.fill then
        pcall(function()
            if frame.dispelHighlight.Hide then
                frame.dispelHighlight:Hide()
            end
        end)
        frame.dispelHighlight = nil
    end

    -- Type-colored dispel fallback (Blizzard DispelOverlay style fill + border).
    -- Used when native DispelOverlay is missing or not shown (esp. Classic PA gaps).
    if not frame.dispelHighlight then
        local overlay = CreateFrame("Frame", nil, frame)
        overlay:SetPoint("TOPLEFT",frame,"TOPLEFT",2,-2)
        overlay:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-2,6)
        overlay:Hide()
        if overlay.SetFrameLevel and frame.GetFrameLevel then overlay:SetFrameLevel(frame:GetFrameLevel() + 25) end
        if overlay.SetIgnoreParentAlpha then
            overlay:SetIgnoreParentAlpha(true)
        end

        local fill = overlay:CreateTexture(nil, "ARTWORK", nil, 0)
        fill:SetAllPoints(overlay)
        if not pcall(fill.SetAtlas, fill, "RaidFrame-Dispel-Fill") then
            fill:SetColorTexture(1, 1, 1, 0.2)
        else
            fill:SetAlpha(0.2)
        end
        overlay.fill = fill

        local border = overlay:CreateTexture(nil, "OVERLAY", nil, 1)
        border:SetAllPoints(overlay)
        if not pcall(border.SetAtlas, border, "RaidFrame-DispelHighlight") then
            pcall(border.SetAtlas, border, "RaidFrame-TargetFrame")
        end
        overlay.border = border

        frame.dispelHighlight = overlay
    end

    frame._fluxOverlaysReady = true
    FluxRaidVisuals.ApplyRaidHighlightVertexColors(frame)
end

local function GetFluxAuraIconScale()
    return max(0.5, min(2.5, (FluxRaidVisuals.AURA_ICON_HEIGHT or NATIVE_UNIT_FRAME_AURA_SIZE) / NATIVE_UNIT_FRAME_AURA_SIZE))
end

--- "debuff" (default) or "buff" from Raid Frame options.
function FluxRaidVisuals.GetAuraFocusMode()
    if FluxOptions and FluxOptions.GetRaidFrameDB then
        local db = FluxOptions:GetRaidFrameDB()
        if db and db.auraFocusMode == "buff" then
            return "buff"
        end
    end
    return "debuff"
end

--- Map focus mode to Blizzard Enum.RaidAuraOrganizationType (all clients).
--- Debuff focused â†’ Legacy (debuffs bottom-left). Buff focused â†’ BuffsTopDebuffsBottom.
function FluxRaidVisuals.GetAuraOrganizationType()
    local enum = Enum and Enum.RaidAuraOrganizationType
    local mode = FluxRaidVisuals.GetAuraFocusMode()
    if mode == "buff" then
        if enum and enum.BuffsTopDebuffsBottom ~= nil then
            return enum.BuffsTopDebuffsBottom
        end
        return 1
    end
    if enum and enum.Legacy ~= nil then
        return enum.Legacy
    end
    return 0
end

local function ApplyFluxAuraOrganization(frame)
    if not frame then return end
    local org = FluxRaidVisuals.GetAuraOrganizationType()
    frame.auraOrganizationType = org
    if frame.SetAuraOrganizationType then
        pcall(frame.SetAuraOrganizationType, frame, org)
    end
end

local function CVarBool(name, defaultIfMissing)
    if FluxRaid_GetCVarBool then
        return FluxRaid_GetCVarBool(name, defaultIfMissing)
    end
    return defaultIfMissing
end

function FluxRaidVisuals.UsesPrivateAuras(frame)
    if frame and frame._fluxPrivateAuraMixed then
        return true
    end
    return FluxRaidCompat and FluxRaidCompat.HasPrivateAuraContainer and FluxRaidCompat.HasPrivateAuraContainer()
end

local fluxRaidOptionTable

function FluxRaidVisuals.GetFluxRaidOptionTable()
    if not fluxRaidOptionTable then
        fluxRaidOptionTable = {}
    end
    FluxRaidVisuals.SyncAuraDisplayOptions(fluxRaidOptionTable)
    return fluxRaidOptionTable
end

local function RaidOptionFlag(db, key, defaultOn)
    if not db or db[key] == nil then
        return defaultOn and true or false
    end
    return db[key] and true or false
end

function FluxRaidVisuals.ShouldDisplayOnlyDispellableDebuffs(frame, partyPreview)
    local opt = frame and frame.optionTable or FluxRaidVisuals.GetFluxRaidOptionTable()
    if opt.displayOnlyDispellableDebuffs == true then return true end
    local unit = frame and (frame.displayedUnit or frame.unit)
    local party = partyPreview or frame and frame._fluxPartyMember or unit == "player"
        or type(unit) == "string" and unit:match("^party[1-4]$") ~= nil
    -- Read Blizzard's compact-party preference without writing CUF settings or
    -- changing the shared option table used by actual raid/focus cells.
    return party and CVarBool("raidFramesDisplayOnlyDispellableDebuffs", false) or false
end

-- Native CUF CVars stay owned by Blizzard on secret clients. Flux-owned
-- buttons and their preview use the independently scoped raid options there.
function FluxRaidVisuals.UseOwnRaidSettings()
    local write = ns.Flux and ns.Flux.BlizzardSettings and ns.Flux.BlizzardSettings.Write
    return write and write.IsSecretClient and write.IsSecretClient() and true or false
end

function FluxRaidVisuals.SyncAuraDisplayOptions(opt)
    if type(opt) ~= "table" then return end
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    opt.displayBuffs = RaidOptionFlag(db, "displayBuffs", true)
    opt.displayDebuffs = RaidOptionFlag(db, "displayDebuffs", true)
    opt.displayOnlyDispellableDebuffs = RaidOptionFlag(db, "displayOnlyDispellableDebuffs", false)
    opt.displayDispelDebuffs = true
    if opt.displayNonBossDebuffs == nil then
        opt.displayNonBossDebuffs = true
    end
    local showOverlay = true
    if FluxRaid_IsDispelHighlightEnabled then
        showOverlay = FluxRaid_IsDispelHighlightEnabled() and true or false
    end
    opt.showDispelIndicatorOverlay = showOverlay
    local dispelEnum = Enum and Enum.RaidDispelDisplayType
    if dispelEnum and dispelEnum.DispellableByMe ~= nil then
        opt.raidFramesDispelIndicatorType = dispelEnum.DispellableByMe
    elseif dispelEnum and dispelEnum.DisplayAll ~= nil then
        opt.raidFramesDispelIndicatorType = dispelEnum.DisplayAll
    end
    opt.useClassColors = RaidOptionFlag(db, "useClassColors", true)
    opt.displayHealPrediction = RaidOptionFlag(db, "showHealPrediction", true)
    opt.fadeOutOfRange = RaidOptionFlag(db, "showRangeFade", true)
    opt.displayInOtherPhase = CVarBool("raidFramesDisplayInOtherPhase", true)
    opt.displayPowerBar = RaidOptionFlag(db, "displayPowerBar", true)
    opt.showAggroHighlight = RaidOptionFlag(db, "showAggroHighlight", true)
    opt.showRoleIcon = RaidOptionFlag(db, "showRoleIcon", true)
    opt.showTargetHighlight = RaidOptionFlag(db, "showTargetHighlight", true)
    opt.showMouseoverHighlight = RaidOptionFlag(db, "showMouseoverHighlight", true)
    opt.showGroupLabels = RaidOptionFlag(db, "showGroupLabels", true)
    local ht = db and db.healthText
    if ht ~= "none" and ht ~= "health" and ht ~= "perc" and ht ~= "healthandpercent" and ht ~= "losthealth" then
        ht = "perc"
    end
    opt._fluxHealthText = ht
    opt.healthText = ht
    opt.displayStatusText = (ht ~= "none")
end

function FluxRaidVisuals.EnsureAuraMaxSlots(frame)
    if not frame then return end
    local focus = FluxRaidVisuals.GetAuraFocusMode()
    local usePrivate = FluxRaidVisuals.UsesPrivateAuras(frame)
    local maxBuffs, maxDebuffs
    if focus == "buff" then
        maxBuffs, maxDebuffs = 6, 3
    else
        maxBuffs = 3
        maxDebuffs = usePrivate and 5 or 3
    end
    frame.maxBuffs = maxBuffs
    frame.maxDebuffs = maxDebuffs
    frame.maxDispelDebuffs = 3
end

local function QueuePrivateAuraSync(frame)
    if not frame then return end
    frame._fluxNeedsPrivateAuraSync = true
    if FluxRaid_QueueConfigureAndRefresh then
        FluxRaid_QueueConfigureAndRefresh()
    end
end

local function SetFluxPrivateAuraAnchorSettings(host)
    host._fluxNativeSetPrivateAuraAnchorSettings(host)
    if host.optionTable and host.optionTable.displayOnlyDispellableDebuffs then
        -- Blizzard's normal debuff row keeps boss/role/priority exceptions.
        -- Restrict icons to its HARMFUL|RAID dispel row for Flux's strict toggle.
        host:SetAttribute("ignore-debuffs", true)
    end
end

function FluxRaidVisuals.ConfigurePrivateAuras(frame)
    if not frame or frame._fluxRaidMini then
        return false
    end
    if FluxRaidAuras and FluxRaidAuras.Setup then
        return FluxRaidAuras.Setup(frame)
    end
    if not (FluxRaidCompat and FluxRaidCompat.HasPrivateAuraContainer and FluxRaidCompat.HasPrivateAuraContainer()) then
        return false
    end
    local mixin = rawget(_G, "ContainerPrivateAuraBehaviorMixin")
    local host = frame._fluxPrivateAuraHost
    if not host then
        if not mixin or not Mixin then return false end
        if InCombatLockdown and InCombatLockdown() then
            QueuePrivateAuraSync(frame)
            return true
        end
        -- Blizzard owns this child's OnAttributeChanged. The secure unit button
        -- has Flux's unit hook, which cannot also be the private-aura handler.
        host = frame.auraHost or CreateFrame("Frame", nil, frame)
        host:SetAllPoints(frame)
        host:EnableMouse(false)
        if not pcall(Mixin, host, mixin) then return false end
        host._fluxNativeSetPrivateAuraAnchorSettings = host.SetPrivateAuraAnchorSettings
        host.SetPrivateAuraAnchorSettings = SetFluxPrivateAuraAnchorSettings
        frame._fluxPrivateAuraHost = host
        frame._fluxPrivateAuraMixed = true
    end
    local auraSize = FluxRaidVisuals.AURA_ICON_HEIGHT or NATIVE_UNIT_FRAME_AURA_SIZE
    local borderScale = GetFluxAuraIconScale()
    if host.SetAuraSize then pcall(host.SetAuraSize, host, auraSize) end
    if host.SetDebuffAuraSize then pcall(host.SetDebuffAuraSize, host, auraSize) end
    if host.SetBuffAuraSize then pcall(host.SetBuffAuraSize, host, auraSize) end
    if host.SetBorderScale then pcall(host.SetBorderScale, host, borderScale) end
    if host.SetDebuffBorderScale then pcall(host.SetDebuffBorderScale, host, borderScale) end
    if host.SetBuffBorderScale then pcall(host.SetBuffBorderScale, host, borderScale) end
    ApplyFluxAuraOrganization(frame)
    ApplyFluxAuraOrganization(host)
    FluxRaidVisuals.EnsureAuraMaxSlots(frame)
    host.maxBuffs, host.maxDebuffs, host.maxDispelDebuffs = frame.maxBuffs, frame.maxDebuffs, frame.maxDispelDebuffs
    if CompactRaidGroupTypeEnum then
        frame.groupType = frame.groupType or CompactRaidGroupTypeEnum.Raid
    end
    host.groupType = frame.groupType
    frame.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
    host.optionTable = frame.optionTable
    host.displayedUnit = frame.displayedUnit or frame.unit
    local pbh = frame.powerBar and frame.powerBar:IsShown() and (FluxRaidVisuals.POWER_BAR_HEIGHT or 0) or 0
    frame.powerBarUsedHeight = pbh
    if host.SetPowerBarUsedHeight then
        pcall(host.SetPowerBarUsedHeight, host, pbh)
    end
    return true
end

function FluxRaidVisuals.UpdatePrivateAuraUnit(frame)
    if not frame then return end
    if frame._fluxHealerAuras and FluxRaidAuras then
        FluxRaidAuras.Update(frame)
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        QueuePrivateAuraSync(frame)
        return
    end
    local host = frame._fluxPrivateAuraHost
    if not host then return end
    if frame._fluxNeedsPrivateAuraSync then
        FluxRaidVisuals.SyncPrivateAuraSettings(frame, false, true)
        return
    end
    local unit = frame.displayedUnit or frame.unit
    host.displayedUnit = unit
    -- Live/Forever use this field; Era/Anniversary use the third argument.
    -- Neither may preserve an anchor when its unit changes (including nil).
    host.avoidPrivateAuraAnchorChange = nil
    local ok = pcall(host.SetPrivateAuraAnchorUnit, host, unit, unit ~= nil and not host.anchorID, false)
    frame._fluxNeedsPrivateAuraSync = not ok or nil
end

--- Settings-only attribute push. avoidRebuild=true does not tear down an existing anchor.
function FluxRaidVisuals.SyncPrivateAuraSettings(frame, force, avoidRebuild)
    if frame and frame._fluxHealerAuras and FluxRaidAuras then
        FluxRaidAuras.Refresh(frame)
        return
    end
    if not frame or not frame._fluxPrivateAuraMixed then
        return
    end
    FluxRaidVisuals.ConfigurePrivateAuras(frame)
    if InCombatLockdown and InCombatLockdown() then
        QueuePrivateAuraSync(frame)
        return
    end
    local host = frame._fluxPrivateAuraHost
    if not host then return end
    local unit = frame.displayedUnit or frame.unit
    host.avoidPrivateAuraAnchorChange = nil
    local ok
    if avoidRebuild and host.anchorID and host.privateAuraUnit == unit then
        -- The public settings trigger preserves the anchor on every client.
        ok = pcall(host.TriggerPrivateAuraSettingsUpdate, host)
    else
        local forceUpdate = force or not avoidRebuild or (unit ~= nil and not host.anchorID)
        ok = pcall(host.SetPrivateAuraAnchorUnit, host, unit, forceUpdate, false)
    end
    frame._fluxNeedsPrivateAuraSync = not ok or nil
end

function FluxRaidVisuals.PushAuraDisplayToFrame(frame)
    if not frame or frame._fluxRaidMini then return end
    frame.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
    ApplyFluxAuraOrganization(frame)
    FluxRaidVisuals.EnsureAuraMaxSlots(frame)
    if frame._fluxPrivateAuraMixed or FluxRaidVisuals.ConfigurePrivateAuras(frame) then
        FluxRaidVisuals.SyncPrivateAuraSettings(frame, true, true)
    end
end

function FluxRaidVisuals.NeutralizeBlizzardSharedUpdateAllSetup()
end

function FluxRaidVisuals.ResealCompactUnitFrameOnUpdate(_frame)
end

-- Native Blizzard player-frame art (FileDataID 8036209, 2048x1024).
-- Pixel rectangles measured directly from the unchanged Blizzard image during
-- the 6 November visual audit. Nothing is loaded from the reference addon.
local nativeBronzeAvailable
local function NativeBronzeRegion(parent, x, y, width, height, mirror)
    local texture = parent:CreateTexture(nil, "BORDER")
    if texture:SetTexture(8036209) ~= true then texture:Hide() return nil end
    -- Texel centers exclude the neighboring baked-black atlas padding.
    local left, right = (x + 0.5) / 2048, (x + width - 0.5) / 2048
    texture:SetTexCoord(mirror and right or left, mirror and left or right,
        (y + 0.5) / 1024, (y + height - 0.5) / 1024)
    texture:SetVertexColor(0.85, 0.85, 0.85)
    texture:SetBlendMode("BLEND")
    texture:SetAlpha(1)
    texture:Hide()
    return texture
end

local function EnsureNativeBronze(parent)
    if nativeBronzeAvailable == false then return nil end
    local top = NativeBronzeRegion(parent, 1553, 24, 2, 4)
    nativeBronzeAvailable = top ~= nil
    if not top then return nil end
    local bronze = { top = top, corners = {}, parts = {}, bottomAnchors = {} }
    local bottom = FluxRaidVisuals.CELL_BOTTOM_INSET
    local function SetBronzePoint(texture, point, relativeTo, relativePoint, x, y)
        texture:SetPoint(point, relativeTo, relativePoint, x, y)
        if relativePoint:find("BOTTOM") then
            bronze.bottomAnchors[#bronze.bottomAnchors + 1] = { texture, point, relativeTo, relativePoint, x, y - bottom }
        end
    end
    local function piece(key, x, y, width, height, mirror)
        local texture = NativeBronzeRegion(parent, x, y, width, height, mirror)
        bronze[key] = texture
        bronze.parts[#bronze.parts + 1] = texture
        return texture
    end
    bronze.parts[1] = top
    piece("sharedTop", 1553, 60, 2, 4)
    piece("bottom", 1553, 115, 2, 4)
    piece("left", 1589, 71, 4, 2, true)
    piece("right", 1589, 71, 4, 2)
    piece("power", 1553, 60, 2, 4)
    for _, key in ipairs({ "top", "sharedTop", "bottom" }) do
        local texture = bronze[key]
        local anchor = key == "bottom" and "BOTTOM" or "TOP"
        local y = key == "bottom" and bottom or 0
        SetBronzePoint(texture, anchor .. "LEFT", parent, anchor .. "LEFT", 5.5, y)
        SetBronzePoint(texture, anchor .. "RIGHT", parent, anchor .. "RIGHT", -5.5, y)
        texture:SetHeight(2)
    end
    for _, side in ipairs({ "left", "right" }) do
        local anchor = side == "left" and "LEFT" or "RIGHT"
        bronze[side]:SetPoint("TOP" .. anchor, parent, "TOP" .. anchor, 0, -6)
        SetBronzePoint(bronze[side], "BOTTOM" .. anchor, parent, "BOTTOM" .. anchor, 0, bottom + 5)
        bronze[side]:SetWidth(2)
    end
    for _, edge in ipairs({ "top", "sharedTop", "bottom" }) do
        for _, side in ipairs({ "Left", "Right" }) do
            local isBottom = edge == "bottom"
            local texture = piece(edge .. side, 1553, isBottom and 115 or edge == "sharedTop" and 60 or 24, 2, 4)
            local anchor = (isBottom and "BOTTOM" or "TOP") .. side:upper()
            SetBronzePoint(texture, anchor, parent, anchor, 0, isBottom and bottom or 0)
            texture:SetSize(5.5, 2)
        end
    end
    for _, side in ipairs({ "left", "right" }) do
        for _, edge in ipairs({ "Top", "Bottom" }) do
            local texture = piece(side .. edge, 1589, 71, 4, 2, side == "left")
            local anchor = edge:upper() .. side:upper()
            SetBronzePoint(texture, anchor, parent, anchor, 0, edge == "Bottom" and bottom or 0)
            texture:SetSize(2, edge == "Top" and 6 or 5)
        end
    end
    -- These measured rectangles follow only the gold arc of Blizzard's original
    -- 12-by12 corner. Transparent/black interior and exterior padding is omitted.
    local upper = { {1582,24,8,4}, {1586,28,6,2}, {1588,30,5,1}, {1589,31,4,5} }
    local lower = { {1589,109,4,4}, {1587,113,6,1}, {1586,114,5,2}, {1582,116,7,3} }
    for _, key in ipairs({ "tl", "tr", "bl", "br" }) do
        local left = key == "tl" or key == "bl"
        local lowerCorner = key == "bl" or key == "br"
        local baseY = lowerCorner and 109 or 24
        local patches = lowerCorner and lower or upper
        local list = {}
        bronze.corners[key] = list
        for _, rectangle in ipairs(patches) do
            local x, y, width, height = rectangle[1], rectangle[2], rectangle[3], rectangle[4]
            local texture = NativeBronzeRegion(parent, x, y, width, height, left)
            local relativeX = (x - 1582) / 2
            if left then relativeX = 6 - relativeX - width / 2 end
            local anchor = (lowerCorner and "BOTTOM" or "TOP") .. (left and "LEFT" or "RIGHT")
            local baseX = left and -0.5 or -5.5
            SetBronzePoint(texture, "TOPLEFT", parent, anchor, baseX + relativeX,
                (lowerCorner and bottom + 5 or 0) - (y - baseY) / 2)
            texture:SetSize(width / 2, height / 2)
            list[#list + 1] = texture
            bronze.parts[#bronze.parts + 1] = texture
        end
    end
    return bronze
end

-- Independently drawn bronze bevel. These are plain Blizzard color textures;
-- no artwork, code or runtime dependency is taken from the reference addon.
local function BorderStrip(parent, point, opposite, thickness, r, g, b)
    local t = parent:CreateTexture(nil, "BORDER")
    t:SetColorTexture(r, g, b, 1)
    t:SetAlpha(1)
    if t.SetBlendMode then t:SetBlendMode("BLEND") end
    t:SetPoint(point, parent, point, 0, point:find("BOTTOM") and FluxRaidVisuals.CELL_BOTTOM_INSET or 0)
    t:SetPoint(opposite, parent, opposite, 0, opposite:find("BOTTOM") and FluxRaidVisuals.CELL_BOTTOM_INSET or 0)
    if point:find("TOP") and opposite:find("TOP") or point:find("BOTTOM") and opposite:find("BOTTOM") then
        t:SetHeight(thickness)
    else
        t:SetWidth(thickness)
    end
    return t
end

local function EnsureContent(frame)
    if frame._fluxContent then return frame._fluxContent end
    local content = CreateFrame("Frame", nil, frame)
    content:SetAllPoints(frame)
    if content.EnableMouse then content:EnableMouse(false) end
    if content.SetFrameLevel and frame.GetFrameLevel then content:SetFrameLevel(frame:GetFrameLevel() + 1) end
    frame._fluxContent, frame.visualContent = content, content
    local textLayer = CreateFrame("Frame", nil, content)
    textLayer:SetAllPoints(content)
    if textLayer.EnableMouse then textLayer:EnableMouse(false) end
    if textLayer.SetFrameLevel and frame.GetFrameLevel then textLayer:SetFrameLevel(frame:GetFrameLevel() + 12) end
    frame._fluxTextLayer = textLayer
    local auraLayer = CreateFrame("Frame", nil, content)
    auraLayer:SetAllPoints(content)
    if auraLayer.EnableMouse then auraLayer:EnableMouse(false) end
    if auraLayer.SetFrameLevel and frame.GetFrameLevel then auraLayer:SetFrameLevel(frame:GetFrameLevel() + FluxRaidVisuals.AURA_LAYER_OFFSET) end
    frame._fluxAuraLayer = auraLayer
    local indicatorLayer = CreateFrame("Frame", nil, frame)
    indicatorLayer:SetAllPoints(frame)
    if indicatorLayer.EnableMouse then indicatorLayer:EnableMouse(false) end
    if indicatorLayer.SetFrameLevel and frame.GetFrameLevel then indicatorLayer:SetFrameLevel(frame:GetFrameLevel() + 48) end
    frame._fluxIndicatorLayer = indicatorLayer
    for _, key in ipairs({ "leaderIcon", "masterLooterIcon", "raidTargetIcon" }) do
        local icon = frame[key]
        if icon then
            if icon.SetParent then icon:SetParent(indicatorLayer) end
            if icon.SetIgnoreParentAlpha then icon:SetIgnoreParentAlpha(true) end
        end
    end
    local highlightLayer = CreateFrame("Frame", nil, frame)
    highlightLayer:SetAllPoints(frame)
    if highlightLayer.EnableMouse then highlightLayer:EnableMouse(false) end
    if highlightLayer.SetFrameLevel and frame.GetFrameLevel then highlightLayer:SetFrameLevel(frame:GetFrameLevel() + 24) end
    frame._fluxHighlightLayer = highlightLayer
    for _, key in ipairs({ "aggroHighlight", "selectionHighlight", "mouseOverHighlight" }) do
        local child = frame[key]
        if child and child.SetParent then child:SetParent(highlightLayer) end
    end
    for _, key in ipairs({ "background", "healthBar", "powerBar" }) do
        local child = frame[key]
        if child and child.SetParent then child:SetParent(content) end
    end
    for _, key in ipairs({ "name", "statusText", "roleIcon", "auraHost" }) do
        local child = frame[key]
        if child and child.SetParent then child:SetParent(textLayer) end
    end
    local inset = FluxRaidVisuals.CELL_INSET
    local backing = content:CreateTexture(nil, "BACKGROUND")
    backing:SetPoint("TOPLEFT", content, "TOPLEFT", inset, -inset)
    backing:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, FluxRaidVisuals.CELL_BOTTOM_INSET)
    backing:SetColorTexture(0.035, 0.025, 0.015, 1)
    frame._fluxCellBacking = backing
    if frame.background then
        frame.background:ClearAllPoints()
        frame.background:SetPoint("TOPLEFT", content, "TOPLEFT", inset, -inset)
        frame.background:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, FluxRaidVisuals.CELL_BOTTOM_INSET)
    end
    -- A texture on the content's BORDER layer sits behind child StatusBars.
    -- Shared borders live above bars and text, below focus, aura icons and indicators.
    -- They are outside the range-faded content so a connected mesh stays visible.
    local trimLayer = CreateFrame("Frame", nil, frame)
    trimLayer:SetAllPoints(frame)
    if trimLayer.EnableMouse then trimLayer:EnableMouse(false) end
    if trimLayer.SetFrameLevel and frame.GetFrameLevel then trimLayer:SetFrameLevel(frame:GetFrameLevel() + 20) end
    frame._fluxTrimLayer = trimLayer
    for _, key in ipairs({ "healthBar", "powerBar" }) do
        if frame[key] and frame[key].SetFrameLevel then frame[key]:SetFrameLevel(content:GetFrameLevel() + 1) end
    end
    frame._fluxBronzeEdges = {
        BorderStrip(trimLayer, "TOPLEFT", "TOPRIGHT", 2, 0.55, 0.42, 0.25),
        BorderStrip(trimLayer, "TOPLEFT", "BOTTOMLEFT", 2, 0.55, 0.42, 0.25),
        BorderStrip(trimLayer, "BOTTOMLEFT", "BOTTOMRIGHT", 2, 0.55, 0.42, 0.25),
        BorderStrip(trimLayer, "TOPRIGHT", "BOTTOMRIGHT", 2, 0.55, 0.42, 0.25),
    }
    local divider = trimLayer:CreateTexture(nil, "BORDER")
    divider:SetColorTexture(0.45, 0.34, 0.20, 1)
    frame._fluxPowerDivider = divider
    frame._fluxNativeBronze = EnsureNativeBronze(trimLayer)
    -- Construction starts hidden; topology selects native arcs only at the
    -- exterior grid corners and native divider art at internal shared seams.
    if frame._fluxNativeBronze then
        for _, piece in ipairs(frame._fluxNativeBronze.parts) do piece:Hide() end
    end
    frame._fluxJoinedLines = {
        top = frame._fluxBronzeEdges[1], left = frame._fluxBronzeEdges[2],
        bottom = frame._fluxBronzeEdges[3], right = frame._fluxBronzeEdges[4],
    }
    for _, key in ipairs({ "healthBar", "powerBar" }) do
        local bar = frame[key]
        if bar and bar.CreateTexture then
            local sheen = bar:CreateTexture(nil, "OVERLAY")
            sheen:SetAllPoints(bar)
            sheen:SetColorTexture(1, 1, 1, 1)
            if sheen.SetGradient and CreateColor then
                sheen:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 0.04))
            elseif sheen.SetGradientAlpha then
                sheen:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.04)
            else
                sheen:SetAlpha(0.02)
            end
            bar._fluxSheen = sheen
        end
    end
    return content
end

local ROLE_COORDS = {
    TANK = "0:19:22:41", HEALER = "20:39:1:20", DAMAGER = "20:39:22:41",
}
local ROLE_ATLASES = { TANK = "icons_16x16_tank", HEALER = "icons_16x16_heal", DAMAGER = "icons_16x16_damage" }
local roleMarkup = {}
local function RolePrefix(role)
    if issecretvalue and issecretvalue(role) then return "" end
    if not ROLE_COORDS[role] then return "" end
    local size = FluxRaidVisuals.ROLE_ICON_SIZE or 12
    local key = role .. size
    if not roleMarkup[key] then
        local atlas = ROLE_ATLASES[role]
        local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
        if info then
            roleMarkup[key] = string.format("|A:%s:%d:%d|a ", atlas, size, size)
        else
            roleMarkup[key] = string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:%s|t ", size, size, ROLE_COORDS[role])
        end
    end
    return roleMarkup[key]
end

-- Names retain the entire text line. Native formatting consumes opaque names.
function FluxRaidVisuals.SetUnitName(frame, text, role)
    if not frame or not frame.name then return end
    if not (issecretvalue and issecretvalue(text)) and text == nil then text = "" end
    if frame.name.SetFormattedText then
        frame.name:SetFormattedText("%s", text)
    else
        frame.name:SetText(text)
    end
    if frame.roleIcon then frame.roleIcon:Hide() end
end
FluxRaidVisuals.SetName = FluxRaidVisuals.SetUnitName

function FluxRaidVisuals.SetHealthStatus(frame, mode, health, maximum, percent, connected, dead)
    local fs = frame.statusText
    if not fs then return end
    local function secret(v) return issecretvalue and issecretvalue(v) end
    local function formatted(format, ...) FluxRaidVisuals.SetUnitStatus(frame, format, ...) end
    if frame._fluxRaidMini and not frame._fluxExtraPet then
        if not secret(percent) and percent==nil then fs:Hide();return end
        formatted("%.0f%%",percent);fs:Show();return
    end
    if not secret(connected) and connected == false then fs:SetText(PLAYER_OFFLINE or "Offline")
    elseif not secret(dead) and dead then fs:SetText(DEAD or "Dead")
    elseif mode == "none" or frame.optionTable and frame.optionTable.displayStatusText == false then fs:Hide(); return
    elseif mode == "health" then
        if not secret(health) and health == nil then fs:Hide(); return end
        fs:SetText(health)
    elseif mode == "healthandpercent" then
        if not secret(percent) and percent == nil then fs:Hide(); return end
        if not secret(health) and health == nil then formatted("%.0f%%", percent)
        else formatted("%s / %.0f%%", health, percent) end
    elseif mode == "losthealth" and not secret(health) and not secret(maximum)
        and type(health) == "number" and type(maximum) == "number" then
        if maximum <= health then fs:Hide(); return end
        formatted("-%s", maximum - health)
    elseif secret(percent) or percent ~= nil then formatted("%.0f%%", percent)
    else fs:Hide(); return end
    fs:Show()
end

-- Role markup belongs immediately before the numeric status. Only the trusted
-- format string and public role markup are combined; values go straight to the
-- native formatter, including secret health/percent results.
function FluxRaidVisuals.SetUnitStatus(frame, format, ...)
    if not frame or not frame.statusText or type(format) ~= "string"
        or issecretvalue and issecretvalue(format) then return end
    local prefix = ""
    if not (frame._fluxRaidMini and not frame._fluxExtraPet) and (not frame.optionTable or frame.optionTable.showRoleIcon ~= false) then
        prefix = RolePrefix(frame._fluxRole)
    end
    frame.statusText:SetFormattedText("%s" .. format, prefix, ...)
end

-- Every shared horizontal seam belongs to the lower cell's top; every shared
-- vertical seam belongs to the right cell's left. Flags describe exterior edges.
-- Runtime roster callbacks may call this in combat: only owned texture visibility
-- changes, never protected dimensions, parenting, anchors or native data.
function FluxRaidVisuals.SetJoinedEdges(frame, edges)
    if not frame then return false end
    edges = edges or {}
    local function Flag(value, fallback)
        if issecretvalue and issecretvalue(value) then return fallback end
        if value == nil then return fallback end
        return value == true
    end
    local bottom = Flag(edges.bottom, true)
    local right = Flag(edges.right, true)
    if not (issecretvalue and issecretvalue(edges.below)) and edges.below ~= nil then bottom = not edges.below end
    if not (issecretvalue and issecretvalue(edges.rightNeighbor)) and edges.rightNeighbor ~= nil then right = not edges.rightNeighbor end
    local exteriorTop = Flag(edges.exteriorTop, Flag(edges.top, true))
    local exteriorLeft = Flag(edges.exteriorLeft, Flag(edges.left, true))
    frame._fluxJoinedEdges = { exteriorTop = exteriorTop, exteriorLeft = exteriorLeft, bottom = bottom, right = right }
    local lines = frame._fluxJoinedLines
    if not lines then return false end
    local bronze = frame._fluxNativeBronze
    if bronze then
        for _, line in ipairs(frame._fluxBronzeEdges) do line:Hide() end
        local tl, tr = not bronze.compact and exteriorTop and exteriorLeft, not bronze.compact and exteriorTop and right
        local bl, br = not bronze.compact and bottom and exteriorLeft, not bronze.compact and bottom and right
        bronze.top:SetShown(exteriorTop)
        bronze.sharedTop:SetShown(not exteriorTop)
        bronze.bottom:SetShown(bottom)
        bronze.left:Show()
        bronze.right:SetShown(right)
        for _, edge in ipairs({ "top", "sharedTop" }) do
            local visible = edge == "top" and exteriorTop or edge == "sharedTop" and not exteriorTop
            bronze[edge .. "Left"]:SetShown(visible and not tl)
            bronze[edge .. "Right"]:SetShown(visible and not tr)
        end
        bronze.bottomLeft:SetShown(bottom and not bl)
        bronze.bottomRight:SetShown(bottom and not br)
        bronze.leftTop:SetShown(not bronze.compact and not tl)
        bronze.leftBottom:SetShown(not bronze.compact and not bl)
        bronze.rightTop:SetShown(not bronze.compact and right and not tr)
        bronze.rightBottom:SetShown(not bronze.compact and right and not br)
        for key, visible in pairs({ tl = tl, tr = tr, bl = bl, br = br }) do
            for _, patch in ipairs(bronze.corners[key]) do patch:SetShown(visible) end
        end
        bronze.power:SetShown((frame.powerBarUsedHeight or 0) > 0)
    else
        lines.top:Show()
        lines.left:Show()
        lines.bottom:SetShown(bottom)
        lines.right:SetShown(right)
    end
    return true
end

--- Lay out the cell interior; outer dimensions and header placement stay owned by layout.
function FluxRaidVisuals.ApplyCellChrome(frame, opts)
    if not frame then return end
    if not frame._fluxRaidPreview and InCombatLockdown and InCombatLockdown() then
        frame._fluxNeedsChromeRefresh = true
        return
    end
    frame._fluxNeedsChromeRefresh = nil
    opts = opts or {}
    local fh = tonumber(opts.height) or (frame._fluxRaidMini and not frame._fluxExtraPet and FluxRaidVisuals.MINI_FRAME_HEIGHT or FluxRaidVisuals.FRAME_HEIGHT)
    local showPower = opts.showPower
    local targetMini=frame._fluxRaidMini and not frame._fluxExtraPet
    if targetMini then showPower=false end
    if showPower == nil then
        if FluxRaidVisuals.UseOwnRaidSettings() then
            showPower = not (frame.optionTable and frame.optionTable.displayPowerBar == false)
        else
            showPower = CVarBool("raidFramesDisplayPowerBars", true)
        end
    end
    local content = EnsureContent(frame)
    local inset = FluxRaidVisuals.CELL_INSET
    local componentScale = FluxRaidVisuals.COMPONENT_SCALE
    local pbh = showPower and (tonumber(FluxRaidVisuals.POWER_BAR_HEIGHT) or 0) or 0
    local divider = 0
    local bottom = FluxRaidVisuals.CELL_BOTTOM_INSET
    local rightInset = -inset
    frame.powerBarUsedHeight = pbh
    -- These are owned chrome regions. Re-anchor them when switching sizing
    -- modes; no restricted aura descendants or native profile fields are read.
    for _, backing in ipairs({ frame._fluxCellBacking, frame.background }) do
        if backing then
            backing:ClearAllPoints()
            backing:SetPoint("TOPLEFT", content, "TOPLEFT", inset, -inset)
            backing:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", rightInset, bottom)
        end
    end
    local edgePoints = { { "TOPLEFT", "TOPRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" },
        { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }
    for index, points in ipairs(edgePoints) do
        local edge = frame._fluxBronzeEdges[index]
        edge:ClearAllPoints()
        for _, point in ipairs(points) do edge:SetPoint(point, frame._fluxTrimLayer, point, 0, point:find("BOTTOM") and bottom or 0) end
    end
    if frame.background and frame.background.SetColorTexture then
        frame.background:SetColorTexture(0.035, 0.025, 0.015, 1)
    end
    if frame.healthBar then
        frame.healthBar:ClearAllPoints()
        frame.healthBar:SetPoint("TOPLEFT", content, "TOPLEFT", inset, -inset)
        frame.healthBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", rightInset, bottom + pbh + divider)
        frame.healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        if frame.healthBar.background then frame.healthBar.background:SetColorTexture(0.08, 0.08, 0.08, 0.9) end
    end
    if frame.powerBar then
        frame.powerBar:ClearAllPoints()
        frame.powerBar:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", inset, bottom)
        frame.powerBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", rightInset, bottom)
        frame.powerBar:SetHeight(max(1, pbh))
        frame.powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        if frame.powerBar.background then frame.powerBar.background:SetColorTexture(0.08, 0.08, 0.08, 0.9) end
        frame.powerBar:SetShown(showPower and true or false)
    end
    local line = frame._fluxPowerDivider
    line:ClearAllPoints()
    line:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, bottom + pbh)
    line:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, bottom + pbh)
    line:SetHeight(max(1, divider))
    line:Hide()
    if frame._fluxNativeBronze then
        local bronze = frame._fluxNativeBronze
        for _, anchor in ipairs(bronze.bottomAnchors) do
            anchor[1]:SetPoint(anchor[2], anchor[3], anchor[4], anchor[5], bottom + anchor[6])
        end
        -- Tiny MT/MA minis cannot fit two six-unit native corner arcs. Keep
        -- their native gold bands straight rather than collapsing the side.
        bronze.compact = fh - bottom < 12
        for _, side in ipairs({ "left", "right" }) do
            local anchor = side:upper()
            bronze[side]:ClearAllPoints()
            bronze[side]:SetPoint("TOP" .. anchor, frame._fluxTrimLayer, "TOP" .. anchor, 0, bronze.compact and 0 or -6)
            bronze[side]:SetPoint("BOTTOM" .. anchor, frame._fluxTrimLayer, "BOTTOM" .. anchor, 0, bottom + (bronze.compact and 0 or 5))
        end
        local power = bronze.power
        power:ClearAllPoints()
        power:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, bottom + pbh)
        power:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, bottom + pbh)
        power:SetHeight(1)
    end
    FluxRaidVisuals.SetJoinedEdges(frame, frame._fluxJoinedEdges)
    local health = frame.healthBar or content
    local mini = frame._fluxRaidMini or fh < 28
    if frame.name then
        frame.name:ClearAllPoints()
        frame.name:SetPoint("LEFT", health, "LEFT", 2, mini and 0 or 6)
        frame.name:SetPoint("RIGHT", health, "RIGHT", -2, mini and 0 or 6)
        frame.name:SetJustifyH("CENTER")
        frame.name:SetWordWrap(false)
        if frame.name.SetFontObject then
            local font = GameFontHighlightSmall
            if font then frame.name:SetFontObject(font) end
        end
        if frame.name.SetShadowOffset then frame.name:SetShadowOffset(1, -1) end
    end
    if frame.statusText then
        frame.statusText:ClearAllPoints()
        frame.statusText:SetPoint("LEFT", health, "LEFT", 2, -6)
        frame.statusText:SetPoint("RIGHT", health, "RIGHT", -2, -6)
        frame.statusText:SetJustifyH("CENTER")
        local statusFont = targetMini and GameFontHighlightSmall or GameFontDisable
        if frame.statusText.SetFontObject and statusFont then frame.statusText:SetFontObject(statusFont) end
        -- SetFontObject can retain a FontString-local height override. Read
        -- the immutable native Font, never our already-scaled FontString, so
        -- repeated layout refreshes cannot multiply its height again.
        local fontPath, baseSize, fontFlags
        if statusFont and statusFont.GetFont then
            fontPath, baseSize, fontFlags = statusFont:GetFont()
        elseif statusFont and statusFont.GetFontHeight then
            baseSize = statusFont:GetFontHeight()
        end
        local size = AuraNumber(baseSize, targetMini and 10 or 12) * (targetMini and 1 or componentScale)
        if issecretvalue and issecretvalue(fontPath) then fontPath = nil end
        if issecretvalue and issecretvalue(fontFlags) then fontFlags = nil end
        if frame.statusText.SetFont and type(fontPath) == "string" then
            frame.statusText:SetFont(fontPath, size, type(fontFlags) == "string" and fontFlags or "")
        elseif frame.statusText.SetFontHeight then
            frame.statusText:SetFontHeight(size)
        end
        frame.statusText:SetHeight(size)
        if frame.statusText.SetTextScale then frame.statusText:SetTextScale(1) end
        if frame.statusText.SetWordWrap then frame.statusText:SetWordWrap(false) end
        if frame.statusText.SetTextColor then frame.statusText:SetTextColor(0.86, 0.86, 0.86) end
        if targetMini then
            frame.statusText:ClearAllPoints()
            frame.statusText:SetPoint("RIGHT",health,"RIGHT",-2,0)
            frame.statusText:SetWidth(max(24,size*3.3))
            frame.statusText:SetJustifyH("RIGHT")
            if frame.name then
                frame.name:ClearAllPoints()
                frame.name:SetPoint("LEFT",health,"LEFT",2,0)
                frame.name:SetPoint("RIGHT",frame.statusText,"LEFT",-2,0)
                frame.name:SetJustifyH("LEFT")
            end
        end
    end
    if frame.roleIcon then
        frame.roleIcon:ClearAllPoints()
        frame.roleIcon:SetPoint("TOPLEFT", content, "TOPLEFT", inset, -inset)
        frame.roleIcon:SetSize(FluxRaidVisuals.ROLE_ICON_SIZE or 12, FluxRaidVisuals.ROLE_ICON_SIZE or 12)
    end
    if frame.centerStatusIcon then
        frame.centerStatusIcon:ClearAllPoints()
        frame.centerStatusIcon:SetPoint("CENTER", content, "CENTER")
        local size = 22 * componentScale
        frame.centerStatusIcon:SetSize(size, size)
        if frame.centerStatusIcon.SetIgnoreParentAlpha then frame.centerStatusIcon:SetIgnoreParentAlpha(true) end
        if frame.centerStatusIcon.SetFrameLevel and frame.GetFrameLevel then frame.centerStatusIcon:SetFrameLevel(frame:GetFrameLevel() + 50) end
    end
    if frame.readyCheckIcon then
        frame.readyCheckIcon:ClearAllPoints()
        frame.readyCheckIcon:SetPoint("CENTER", content, "CENTER")
        local size = 20 * componentScale
        frame.readyCheckIcon:SetSize(size, size)
        if frame.readyCheckIcon.SetIgnoreParentAlpha then frame.readyCheckIcon:SetIgnoreParentAlpha(true) end
        if frame.readyCheckIcon.SetFrameLevel and frame.GetFrameLevel then frame.readyCheckIcon:SetFrameLevel(frame:GetFrameLevel() + 51) end
    end
    local function atlas(tex, name)
        if tex and tex.SetAtlas then pcall(tex.SetAtlas, tex, name) end
    end
    atlas(frame.aggroHighlight, "RaidFrame-AggroFrame")
    atlas(frame.selectionHighlight, "RaidFrame-TargetFrame")
    atlas(frame.mouseOverHighlight, "RaidFrame-TargetFrame")
    FluxRaidVisuals.EnsureFluxOverlays(frame)
    FluxRaidVisuals.ApplyRaidHighlightVertexColors(frame)
    if not frame._fluxRaidPreview then
        if FluxRaidPrediction and FluxRaidPrediction.Setup then FluxRaidPrediction.Setup(frame) end
        if FluxRaidHoTs and FluxRaidHoTs.Setup then FluxRaidHoTs.Setup(frame) end
    end
end

function FluxRaidVisuals.ApplyVisuals(frame)
    FluxRaidVisuals.ApplyCellChrome(frame)
    FluxRaidVisuals.PushAuraDisplayToFrame(frame)
end

function FluxRaidVisuals.SetupHealAbsorbLayers(_frame)
end

function FluxRaidVisuals.SetupReadyCheckIcon(_frame)
end

function FluxRaidVisuals.RefreshNeutralBarTracks(_frame)
end

_G.FluxRaidVisuals = FluxRaidVisuals

