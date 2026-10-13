-- UnitFrames/FluxUnitFrames_Auras.lua
local addonName, ns = ...
ns.UnitFrames = ns.UnitFrames or {}
local UF = ns.UnitFrames

-- Local copy of FluxAPI for speed (ensure it's available)
local API = ns.API or {}
local FLUX_API = FLUX_API or {}
local Border = ns.Border
local AuraOwn = UF.AuraOwn

-- Local IsSecretValue function for safety checks
local function IsSecretValue(value)
    if AuraOwn and AuraOwn.IsSecretValue then
        return AuraOwn.IsSecretValue(value)
    end
    return API and API.IsSecretValue and API.IsSecretValue(value)
end

local playerDebuffInstanceIDs = {}
local scratchDebuffCollected = {}

local function UsePackedAuraAPI()
    if AuraOwn and AuraOwn.HasPackedAuraAPI then
        return AuraOwn.HasPackedAuraAPI()
    end
    return C_UnitAuras ~= nil and C_UnitAuras.GetAuraDataByIndex ~= nil
end

local function OwnDebuffInstanceSet(unit)
    return unit and playerDebuffInstanceIDs[unit] or nil
end

--- Player/pet/vehicle debuffs first, then others; stable order within each group.
local function SortDebuffDataListPlayerFirst(unit, list)
    if AuraOwn and AuraOwn.SortDebuffsOwnFirst then
        AuraOwn.SortDebuffsOwnFirst(unit, list, OwnDebuffInstanceSet(unit))
        return
    end
end

-- Compatibility functions for battlefield borders (from old version)
local function SafeSetAtlas(texture, atlas, useAtlasSize)
    if texture and atlas then
        local success = pcall(function() texture:SetAtlas(atlas, useAtlasSize) end)
        return success
    end
    return false
end

local function CreateLegacyBattlefieldBorderPiece(parent, layer, isCorner, key, edgeType)
    -- Simplified fallback for legacy clients
    local texture = parent:CreateTexture(nil, layer)

    if isCorner then
        -- Corner piece
        texture:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga")

        if key == "TL" then
            texture:SetTexCoord(0.004, 0.066, 0.148, 0.211)
        elseif key == "TR" then
            texture:SetTexCoord(0.066, 0.129, 0.148, 0.211)
        elseif key == "BL" then
            texture:SetTexCoord(0.004, 0.066, 0.211, 0.273)
        elseif key == "BR" then
            texture:SetTexCoord(0.066, 0.129, 0.211, 0.273)
        end

        texture:SetSize(17, 17)
    else
        -- Edge piece
        texture:SetTexture("Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga")

        if edgeType == "Top" then
            texture:SetTexCoord(0.004, 0.816, 0.004, 0.070)
            texture:SetHeight(17)
        elseif edgeType == "Bottom" then
            texture:SetTexCoord(0.004, 0.816, 0.070, 0.136)
            texture:SetHeight(17)
        elseif edgeType == "Left" then
            texture:SetTexCoord(0.004, 0.066, 0.148, 0.672)
            texture:SetWidth(17)
        elseif edgeType == "Right" then
            texture:SetTexCoord(0.004, 0.066, 0.148, 0.672)
            texture:SetWidth(17)
        end
    end

    return texture
end

-- Function to find the duration text region in a cooldown frame
local function FetchAuraDurationRegion(cooldown)
    if not cooldown then return end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then return region end
    end
end

-- Single cooldown duration text update (used by global sweep; no per-icon ticker)
local function UpdateCooldownDurationText(cooldown)
    if not cooldown or not cooldown:IsShown() then return end
    local textRegion = cooldown.durationText
    if not textRegion then return end

    local startTime, durationTime = cooldown:GetCooldownTimes()
    local safeStartTime = ns.API.SafeGetNumber(startTime, 0)
    local safeDurationTime = ns.API.SafeGetNumber(durationTime, 0)
    if safeStartTime > 0 and safeDurationTime > 0 then
        local remaining = (safeStartTime + safeDurationTime) - GetTime()
        if remaining > 0 then
            if remaining >= 3600 then
                textRegion:SetText(string.format("%.0fh", remaining / 3600))
            elseif remaining >= 60 then
                textRegion:SetText(string.format("%.0fm", remaining / 60))
            elseif remaining >= 10 then
                textRegion:SetText(string.format("%.0f", remaining))
            else
                textRegion:SetText(string.format("%.1f", remaining))
            end
            textRegion:Show()
        else
            textRegion:Hide()
        end
    else
        textRegion:Hide()
    end
end

-- Function to apply duration text styling (similar to UnhaltedUnitFrames)
-- Forward decl: re-armed when duration texts appear after ticker parked idle.
local StartAuraUpdates

-- Apply custom duration text styling; register for global sweep ticker.
local function ApplyAuraDuration(cooldown, unit)
    if not cooldown then return end

    if cooldown.updateTimer then
        cooldown.updateTimer:Cancel()
        cooldown.updateTimer = nil
    end

    -- Find and modify the existing cooldown text region immediately
    local textRegion = FetchAuraDurationRegion(cooldown)
    if textRegion then
        local durFont = (unit == "focus") and 7 or 10 -- focus: ~30% smaller
        textRegion:SetFont("Fonts\\FRIZQT__.TTF", durFont, "OUTLINE")
        textRegion:SetTextColor(1, 1, 1, 1)
        textRegion:ClearAllPoints()
        textRegion:SetPoint("CENTER", cooldown, "CENTER", 0, 0)
        textRegion:SetShadowColor(0, 0, 0, 1)
        textRegion:SetShadowOffset(1, -1)

        cooldown.durationText = textRegion
        cooldown._fluxAuraDurationTracked = true
        UpdateCooldownDurationText(cooldown)
        if StartAuraUpdates then
            StartAuraUpdates()
        end
    else
        C_Timer.After(0.01, function()
            ApplyAuraDuration(cooldown, unit)
        end)
    end
end

-- Constants
-- Interval for sweeping cooldown duration text only (no full aura rescans)
-- Flux perf T2.2: the cooldown duration text only needs integer-second
-- precision, so 4Hz (0.25s) is indistinguishable from 10Hz (0.1s) to the eye
-- but does 2.5x less work when many aura icons are visible (player, target,
-- focus, pet, boss1-5). The 1s-text threshold logic keeps the UI responsive.
local AURA_DURATION_SWEEP_INTERVAL = 0.5 -- was 0.25; duration text does not need 4Hz
local auraDurationSweepTimer = nil
-- Coalesce burst UNIT_AURA fires into one full refresh per frame
local UNIT_AURA_DEBOUNCE_SEC = 0.075
-- Flux perf T2.2: cached at load so we can use Retail's unitAuraUpdateInfo
-- payload on UNIT_AURA to short-circuit empty payloads.
local HAS_UNIT_AURA_DIFF_PAYLOAD = (ns.API and ns.API.UnitAuraHasDiffPayload) or false
local DEFAULT_AURA_SIZE = 35  -- Bigger than old version
local DEFAULT_AURA_SPACING = 2
-- Bordered panel: horizontal border padding (8+8), vertical insets matching PositionAurasInBorderedContainer
local AURA_BORDER_INSET_X = 8
local AURA_BORDER_INSET_X2 = 16
local AURA_BORDER_INSET_Y_TOP = 10
local AURA_BORDER_INSET_Y_BOTTOM = 10
-- Smallest allowed icon height after fit scale (configurable via buffConfig.minAuraPx / debuffConfig.minAuraPx)
local DEFAULT_MIN_AURA_PX = 10
local AURA_FIT_MIN_SCALE = 0.18

-- Match FluxUILayoutSqueeze emulated full-bar dependent X (independent of live bar button count).
local function GetFluxAuraLayoutXSqueezeMult()
    local g = FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetEffectiveEmulatedDependentXFactorForUnitFrames
    local m = g and g()
    if type(m) ~= "number" or m ~= m or m <= 0 then
        return 1
    end
    return m
end

--- Pixel width/height for one aura at fit=1 (before _fluxAuraFitMult); mirrors UpdateAuraButton sizing rules.
local function GetAuraButtonBaseDimensions(container, usePlayerDebuffUpscale)
    local xF = GetFluxAuraLayoutXSqueezeMult()
    local baseNominal = container._fluxAuraBaseSize or DEFAULT_AURA_SIZE
    if usePlayerDebuffUpscale and container.containerType == "Debuff" then
        local boost = (AuraOwn and AuraOwn.BOOST) or ((42 / 35) * 1.15)
        local boosted = baseNominal * boost
        return boosted * xF, boosted
    end
    return baseNominal * xF, baseNominal
end

--- Inner layout box for fit + wrap (shared with PositionAurasInBorderedContainer).
local function GetBorderedAuraInnerMetrics(container)
    local w = container:GetWidth()
    local h = container:GetHeight()
    local maxRowWidth = w - AURA_BORDER_INSET_X2
    local maxContentH = h - AURA_BORDER_INSET_Y_TOP - AURA_BORDER_INSET_Y_BOTTOM
    if maxRowWidth < 1 then maxRowWidth = 1 end
    if maxContentH < 1 then maxContentH = 1 end
    return maxRowWidth, maxContentH, AURA_BORDER_INSET_X
end

--- Row advance (Y) using the same rules as the bordered positioner; effNominal = baseNominal * fitMult.
local function GetAuraRowStepY(container, effNominal, fitMult)
    local baseSp = container._fluxAuraBaseSpacing or DEFAULT_AURA_SPACING
    local sp = baseSp * fitMult
    if container.containerType == "Debuff" then
        -- Target and focus both reserve tall rows for player/pet own-debuff upscale.
        local boost = (AuraOwn and AuraOwn.BOOST) or ((42 / 35) * 1.15)
        return effNominal * boost + sp
    end
    return effNominal + sp
end

local function GetOwnDebuffMinScale(container)
    if AuraOwn and AuraOwn.ClampMinScale then
        return AuraOwn.ClampMinScale(container and container._fluxOwnDebuffMinScale)
    end
    local minS = container and container._fluxOwnDebuffMinScale
    if type(minS) ~= "number" or minS ~= minS then
        minS = 1
    end
    if minS > 1 then
        minS = 1
    elseif minS < 0.5 then
        minS = 0.5
    end
    return minS
end

--- Own player/pet debuffs: lock => scale 1; otherwise floor at ownDebuffMinScale.
local function GetOwnDebuffFitScale(container, fitMult)
    local lockOwn = container and container._fluxLockOwnDebuffSize
    if AuraOwn and AuraOwn.GetOwnFitScale then
        return AuraOwn.GetOwnFitScale(lockOwn, container and container._fluxOwnDebuffMinScale, fitMult)
    end
    if lockOwn then
        return 1
    end
    local minS = GetOwnDebuffMinScale(container)
    if fitMult < minS then
        return minS
    end
    return fitMult
end

local function GetAuraButtonFitScale(container, btn, fitMult)
    if btn and btn._fluxIsPlayerDebuff and container and container.containerType == "Debuff" then
        return GetOwnDebuffFitScale(container, fitMult)
    end
    return fitMult
end

--- Row step uses own scale when any own debuff is present (lock or min-scale floor).
local function GetAuraLayoutRowStepY(container, fitMult, visibleCount)
    local baseNominal = container._fluxAuraBaseSize or DEFAULT_AURA_SIZE
    if container.containerType == "Debuff" then
        local n = visibleCount or (container.buttons and #container.buttons) or 0
        for i = 1, n do
            local btn = container.buttons[i]
            if btn and btn._fluxIsPlayerDebuff then
                local ownScale = GetOwnDebuffFitScale(container, fitMult)
                return GetAuraRowStepY(container, baseNominal * ownScale, ownScale)
            end
        end
    end
    return GetAuraRowStepY(container, baseNominal * fitMult, fitMult)
end

--- Simulates bordered wrap/row stacking; returns extent to compare with inner height (both grow directions).
--- Own debuffs use lock/min-scale; other icons use trial fitMult.
local function MeasureAuraLayoutExtent(container, fitMult, visibleCount)
    if visibleCount < 1 then
        return 0
    end
    local xF = GetFluxAuraLayoutXSqueezeMult()
    local baseSp = container._fluxAuraBaseSpacing or DEFAULT_AURA_SPACING
    local spacingX = baseSp * xF * fitMult
    local rowStepY = GetAuraLayoutRowStepY(container, fitMult, visibleCount)
    local maxRowWidth = select(1, GetBorderedAuraInnerMetrics(container))
    local leftInset = AURA_BORDER_INSET_X

    if container._fluxAuraGrowUpward then
        local currentX, currentY = leftInset, 10
        local maxFromBottom = 0
        for i = 1, visibleCount do
            local btn = container.buttons[i]
            if not btn then
                break
            end
            local s = GetAuraButtonFitScale(container, btn, fitMult)
            local bw = (btn._fluxAuraBaseW or 0) * s
            local bh = (btn._fluxAuraBaseH or 0) * s
            if currentX + bw > maxRowWidth then
                currentX = leftInset
                currentY = currentY + rowStepY
            end
            local topFromBottom = currentY + bh
            if topFromBottom > maxFromBottom then
                maxFromBottom = topFromBottom
            end
            currentX = currentX + bw + spacingX
        end
        return maxFromBottom
    end

    local currentX, currentY = leftInset, -10
    local maxDepth = 0
    for i = 1, visibleCount do
        local btn = container.buttons[i]
        if not btn then
            break
        end
        local s = GetAuraButtonFitScale(container, btn, fitMult)
        local bw = (btn._fluxAuraBaseW or 0) * s
        local bh = (btn._fluxAuraBaseH or 0) * s
        if currentX + bw > maxRowWidth then
            currentX = leftInset
            currentY = currentY - rowStepY
        end
        local depth = -currentY + bh
        if depth > maxDepth then
            maxDepth = depth
        end
        currentX = currentX + bw + spacingX
    end
    return maxDepth
end

local function ComputeAuraFitMultiplier(container, visibleCount, minAuraPx)
    if visibleCount < 1 then
        return 1
    end
    minAuraPx = minAuraPx or DEFAULT_MIN_AURA_PX
    local maxRowWidth = select(1, GetBorderedAuraInnerMetrics(container))
    local _, maxContentH = GetBorderedAuraInnerMetrics(container)

    local lockOwn = container._fluxLockOwnDebuffSize and container.containerType == "Debuff"
    local maxShrinkBaseW, maxShrinkBaseH = 0, 0
    local hasShrinkable = false
    for i = 1, visibleCount do
        local b = container.buttons[i]
        if b and b._fluxAuraBaseW and b._fluxAuraBaseH then
            if lockOwn and b._fluxIsPlayerDebuff then
                -- Locked own icons stay at base size; exclude from shrink floor/cap.
            else
                hasShrinkable = true
                maxShrinkBaseW = math.max(maxShrinkBaseW, b._fluxAuraBaseW)
                maxShrinkBaseH = math.max(maxShrinkBaseH, b._fluxAuraBaseH)
            end
        end
    end
    if not hasShrinkable or maxShrinkBaseW <= 0 or maxShrinkBaseH <= 0 then
        return 1
    end

    local widthCap = maxRowWidth / maxShrinkBaseW
    if widthCap > 1 then
        widthCap = 1
    end

    local minFromPixel = minAuraPx / maxShrinkBaseH
    if minFromPixel > 1 then
        minFromPixel = 1
    end
    local minF = math.max(AURA_FIT_MIN_SCALE, minFromPixel)
    if widthCap < 1 then
        minF = math.max(minF, widthCap)
    end

    local hi = math.min(1, widthCap)
    if minF > hi then
        return hi
    end

    local function extentOk(f)
        return MeasureAuraLayoutExtent(container, f, visibleCount) <= maxContentH
    end

    if extentOk(hi) then
        return hi
    end
    if not extentOk(minF) then
        return minF
    end

    local best = minF
    local upper = hi
    for _ = 1, 28 do
        local mid = (best + upper) / 2
        if extentOk(mid) then
            best = mid
        else
            upper = mid
        end
    end
    return best
end

--- Apply deferred sizes after fit multiplier (bordered containers only).
--- Own player/pet debuffs: locked at full size, or floored by ownDebuffMinScale; others shrink by fit.
local function ApplyAuraFitToBorderedContainer(container, visibleCount)
    if not container or not container.containerType then
        return
    end
    local minPx = container._fluxAuraMinPx or DEFAULT_MIN_AURA_PX
    local fit = ComputeAuraFitMultiplier(container, visibleCount, minPx)
    container._fluxAuraFitMult = fit
    for i = 1, visibleCount do
        local btn = container.buttons[i]
        if btn and btn._fluxAuraBaseW and btn._fluxAuraBaseH then
            local s = GetAuraButtonFitScale(container, btn, fit)
            btn:SetSize(btn._fluxAuraBaseW * s, btn._fluxAuraBaseH * s)
        end
    end
end

-- Forward-declared: defined after CreateBorderedAuraContainer; callers above must see the local binding.
local PositionAurasInBorderedContainer
local DEFAULT_MAX_BUFFS = 32
local DEFAULT_MAX_DEBUFFS = 16
local DEFAULT_BUFFS_PER_ROW = 8
local DEFAULT_DEBUFFS_PER_ROW = 6

-- Valid dispel types for border coloring (strict allowlist to prevent wrong colors)
local VALID_DISPEL_TYPES = {
    Magic = true, Curse = true, Disease = true, Poison = true,
    Bleed = true, Physical = true,
}

-- Dispel colors (matches Blizzard DEBUFF_DISPLAY_INFO)
local DISPEL_COLORS = {
    Magic = {0.20, 0.60, 1.00, 1},    -- Blue
    Curse = {0.60, 0.00, 1.00, 1},    -- Purple
    Disease = {0.60, 0.40, 0.00, 1},   -- Orange
    Poison = {0.00, 0.60, 0.00, 1},   -- Green
    Bleed = {0.80, 0.00, 0.00, 1},    -- Red
    Physical = {1.00, 1.00, 1.00, 1},  -- White
}

-- Normalize dispel name to PascalCase for table lookup
local function NormalizeDispelName(value)
    if not value or type(value) ~= "string" then return nil end
    local s = (strtrim and strtrim(value)) or value:match("^%s*(.-)%s*$") or value
    if s == "" then return nil end
    local lower = s:lower()
    if lower == "none" then return nil end
    return lower:sub(1, 1):upper() .. lower:sub(2)
end

-- Returns validated dispel name for border coloring, or nil if non-dispellable/secret
local function GetSafeDispelNameForColor(dispelName)
    if not dispelName then return nil end
    if IsSecretValue and IsSecretValue(dispelName) then return nil end
    if canaccessvalue and not canaccessvalue(dispelName) then return nil end
    local normalized = NormalizeDispelName(dispelName)
    if not normalized then return nil end
    return VALID_DISPEL_TYPES[normalized] and normalized or nil
end

-- Singleton color curve for C_UnitAuras.GetAuraDispelTypeColor (Enum.AuraDispelType, not DispelType)
local fluxDispelColorCurve = nil

local function GetFluxDispelColorCurve()
    if fluxDispelColorCurve then return fluxDispelColorCurve end
    if not (FLUX_API.hasC_CurveUtil_CreateColorCurve and C_CurveUtil and C_CurveUtil.CreateColorCurve) then
        return nil
    end
    local createColor = CreateColor
    if not createColor and CreateColorFromRGBA then
        createColor = function(r, g, b, a)
            return CreateColorFromRGBA(r, g, b, a or 1)
        end
    end
    if not createColor then return nil end

    local ok, curve = pcall(C_CurveUtil.CreateColorCurve)
    if not ok or not curve then return nil end

    local curveTypeStep = (Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step) or 2
    if curve.SetType then
        pcall(curve.SetType, curve, curveTypeStep)
    elseif curve.SetCurveType then
        pcall(curve.SetCurveType, curve, curveTypeStep)
    end

    local dispel = (Enum and Enum.AuraDispelType) or { None = 0, Magic = 1, Curse = 2, Disease = 3, Poison = 4 }
    local addPoint = curve.AddPoint
    if not addPoint then return nil end

    local function safeAddPoint(k, r, g, b, a)
        local col
        local okc, c = pcall(createColor, r, g, b, a)
        if okc and c then
            col = c
        else
            local okc2, c2 = pcall(createColor, r, g, b)
            if okc2 and c2 then col = c2 end
        end
        if col then
            pcall(addPoint, curve, k, col)
        end
    end

    safeAddPoint(dispel.None or 0, 0, 0, 0, 0)
    safeAddPoint(dispel.Magic or 1, 0.20, 0.60, 1.00, 1)
    safeAddPoint(dispel.Curse or 2, 0.60, 0.00, 1.00, 1)
    safeAddPoint(dispel.Disease or 3, 0.60, 0.40, 0.00, 1)
    safeAddPoint(dispel.Poison or 4, 0.00, 0.60, 0.00, 1)
    if dispel.Physical then safeAddPoint(dispel.Physical, 1, 1, 1, 1) end
    if dispel.Bleed then safeAddPoint(dispel.Bleed, 0.80, 0.00, 0.00, 1) end

    fluxDispelColorCurve = curve
    return fluxDispelColorCurve
end

-- Never compare secret RGB(A) to literals — causes "tainted by _FluxUI" errors on +12.
local function IsDispelNoneRGB(r, g, b)
    if r == nil or g == nil or b == nil then return true end
    if IsSecretValue(r) or IsSecretValue(g) or IsSecretValue(b) then return false end
    if canaccessvalue and (not canaccessvalue(r) or not canaccessvalue(g) or not canaccessvalue(b)) then
        return false
    end
    local sr = ns.API.SafeGetNumber(r, -1)
    local sg = ns.API.SafeGetNumber(g, -1)
    local sb = ns.API.SafeGetNumber(b, -1)
    if sr < 0 or sg < 0 or sb < 0 then return false end
    return sr == 0 and sg == 0 and sb == 0
end

local function IsEffectiveAlphaVisible(a)
    if IsSecretValue(a) then return true end
    if a == nil then return true end
    if canaccessvalue and not canaccessvalue(a) then return true end
    return ns.API.SafeGetNumber(a, 1) > 0
end

-- Avoid `a ~= nil` / `a or 1` on secret alpha (can error on +12).
local function PickAlphaForVertex(a)
    if IsSecretValue(a) then return a end
    if a == nil then return 1 end
    return a
end

-- SetBackdropBorderColor / sticky cache need plain numbers; secret components do not paint a border on +12.
local function ToPlainRGBAForBackdrop(r, g, b, a)
    if r == nil or g == nil or b == nil then return nil end
    if IsSecretValue(r) or IsSecretValue(g) or IsSecretValue(b) then return nil end
    if canaccessvalue and (not canaccessvalue(r) or not canaccessvalue(g) or not canaccessvalue(b)) then
        return nil
    end
    local aa = 1
    if a ~= nil and not IsSecretValue(a) and (not canaccessvalue or canaccessvalue(a)) then
        aa = ns.API.SafeGetNumber(a, 1)
    end
    return ns.API.SafeGetNumber(r, 0), ns.API.SafeGetNumber(g, 0), ns.API.SafeGetNumber(b, 0), aa
end

local function PlainColorFromDispelData(data)
    local name = GetSafeDispelNameForColor(data and data.dispelName)
    if name and DISPEL_COLORS[name] then
        local c = DISPEL_COLORS[name]
        return c[1], c[2], c[3], c[4]
    end
    return nil
end

local function PlainColorFromSpellId(spellId)
    if spellId == nil or IsSecretValue(spellId) then return nil end
    local sid = ns.API.SafeGetNumber(spellId, 0)
    if sid <= 0 or not C_Spell or not C_Spell.GetSpellInfo then return nil end
    local ok, info = pcall(C_Spell.GetSpellInfo, sid)
    if not ok or type(info) ~= "table" then return nil end
    for _, key in ipairs({ "dispelName", "dispelType", "dispelClassification", "auraDispelType" }) do
        local v = info[key]
        if type(v) == "string" then
            local n = GetSafeDispelNameForColor(v)
            if n and DISPEL_COLORS[n] then
                local c = DISPEL_COLORS[n]
                return c[1], c[2], c[3], c[4]
            end
        end
    end
    return nil
end

local function ExtractRGBAColor(first, second, third, fourth)
    if first == nil then return nil end
    if type(first) == "userdata" or type(first) == "table" then
        if type(first) == "table" and first.GetRGBA then
            local ok, r, g, b, a = pcall(function() return first:GetRGBA() end)
            if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then
                if type(a) ~= "number" then a = 1 end
                return r, g, b, a
            end
        end
        -- GetAuraDispelTypeColor may return a plain color table (components may be secret)
        if type(first) == "table" then
            local okf, r, g, b, a = pcall(function()
                return first.r, first.g, first.b, first.a
            end)
            if okf and r ~= nil and g ~= nil and b ~= nil then
                if a == nil then a = 1 end
                return r, g, b, a
            end
        end
        if type(first) == "userdata" then
            return nil
        end
    end
    if type(first) == "number" and type(second) == "number" and type(third) == "number" then
        local a = (type(fourth) == "number" and fourth) or 1
        return first, second, third, a
    end
    return nil
end

-- Returns r, g, b, a or nil (pcall + fallbacks; TPerl-style)
local function ResolveAuraDispelColor(unit, auraData, curve)
    if not auraData or not unit then return nil end
    local auraId = auraData.auraInstanceID or auraData.auraInstanceId

    if FLUX_API.hasC_UnitAuras_GetAuraDispelTypeColor and curve and C_UnitAuras and C_UnitAuras.GetAuraDispelTypeColor then
        if type(unit) == "string" and auraId ~= nil then
            local ok, a, b, c, d = pcall(C_UnitAuras.GetAuraDispelTypeColor, unit, auraId, curve)
            if ok then
                local r, g, b, a = ExtractRGBAColor(a, b, c, d)
                if r and not IsDispelNoneRGB(r, g, b) and IsEffectiveAlphaVisible(a) then
                    return r, g, b, PickAlphaForVertex(a)
                end
            end
        end
        local ok2, x, y, z, w = pcall(C_UnitAuras.GetAuraDispelTypeColor, auraData, curve)
        if ok2 then
            local r, g, b, a = ExtractRGBAColor(x, y, z, w)
            if r and not IsDispelNoneRGB(r, g, b) and IsEffectiveAlphaVisible(a) then
                return r, g, b, PickAlphaForVertex(a)
            end
        end
        local dtObj = auraData.dispelType
        if type(dtObj) == "table" then
            local fn = dtObj.GetColorFromCurve
            if type(fn) == "function" then
                local ok3, col = pcall(fn, dtObj, curve)
                if ok3 and col then
                    local r, g, b, a = ExtractRGBAColor(col)
                    if r and not IsDispelNoneRGB(r, g, b) and IsEffectiveAlphaVisible(a) then
                        return r, g, b, PickAlphaForVertex(a)
                    end
                end
            end
        end
    end

    local safeDispel = GetSafeDispelNameForColor(auraData.dispelName)
    if safeDispel and DISPEL_COLORS[safeDispel] then
        local c = DISPEL_COLORS[safeDispel]
        return c[1], c[2], c[3], c[4]
    end
    return nil
end

local function ApplyDebuffDispelVisuals(button, unit, data, container)
    if not button or container.containerType ~= "Debuff" then return end
    if button._dispelStickyKey ~= data.auraInstanceID then
        button._dispelStickyKey = data.auraInstanceID
        button._lastDispelBorderRGBA = nil
        button._lastOverlayRGBA = nil
    end
    local curve = GetFluxDispelColorCurve()
    local r, g, b, a = ResolveAuraDispelColor(unit, data, curve)

    local br, bg, bb, ba = ToPlainRGBAForBackdrop(r, g, b, a)
    if not br then
        br, bg, bb, ba = PlainColorFromDispelData(data)
    end
    if not br then
        br, bg, bb, ba = PlainColorFromSpellId(data and data.spellId)
    end

    local resolvedSecretVertex = r and not IsDispelNoneRGB(r, g, b) and IsEffectiveAlphaVisible(a)

    -- Backdrop borders only accept plain RGBA on +12; prefer unified plain path when we have it.
    if br then
        if button.Overlay then
            button.Overlay:SetVertexColor(br, bg, bb, ba)
            button.Overlay:Show()
        end
        button._lastOverlayRGBA = { br, bg, bb, ba }
        if button.Border then
            button.Border:SetBackdropBorderColor(br, bg, bb, ba)
            button._lastDispelBorderRGBA = { br, bg, bb, ba }
        end
        return
    end

    if resolvedSecretVertex and button.Overlay then
        local aa = PickAlphaForVertex(a)
        local ok = pcall(function()
            button.Overlay:SetVertexColor(r, g, b, aa)
        end)
        if ok then
            button.Overlay:Show()
        else
            button.Overlay:Hide()
        end
    elseif button._lastOverlayRGBA and button.Overlay then
        button.Overlay:SetVertexColor(unpack(button._lastOverlayRGBA))
        button.Overlay:Show()
    elseif button.Overlay then
        button.Overlay:Hide()
    end

    if button.Border then
        if button._lastDispelBorderRGBA then
            button.Border:SetBackdropBorderColor(unpack(button._lastDispelBorderRGBA))
        else
            button.Border:SetBackdropBorderColor(0, 0, 0, 1)
        end
    end
end

local function GetIsPreDF()
    -- Packed C_UnitAuras path whenever GetAuraDataByIndex exists (Era/Anniversary included).
    -- UnitAura remains only when that API is missing.
    return not UsePackedAuraAPI()
end

-- Aura frames with buff/debuff UI enabled (for duration sweep)
local auraCache = {}

-- Aura button creation and management
local function CreateAuraButton(parent, index)
    local button = CreateFrame("Button", parent:GetName() .. "AuraButton" .. index, parent, "BackdropTemplate")
    button:SetSize(DEFAULT_AURA_SIZE, DEFAULT_AURA_SIZE)
    button:SetFrameLevel(parent:GetFrameLevel() + 1) -- Ensure button is clickable

    -- Icon texture
    button.Icon = button:CreateTexture(nil, "BORDER")
    button.Icon:SetAllPoints()
    button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Cooldown frame (for duration)
    button.Cooldown = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
    button.Cooldown:SetAllPoints()
    button.Cooldown:SetDrawEdge(false)
    button.Cooldown:SetReverse(true)
    -- Don't hide countdown numbers here - we'll style them instead

    -- Stack count text
    local countFrame = CreateFrame("Frame", nil, button)
    countFrame:SetAllPoints(button)
    countFrame:SetFrameLevel(button:GetFrameLevel() + 2) -- Above cooldown but button still clickable

    button.Count = countFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.Count:SetPoint("BOTTOMRIGHT", countFrame, "BOTTOMRIGHT", -1, 0)
    -- Style the count text for better visibility
    local countFont = (parent.unit == "focus") and 8 or 12
    button.Count:SetFont("Fonts\\FRIZQT__.TTF", countFont, "OUTLINE")
    button.Count:SetTextColor(1, 1, 1, 1)
    button.Count:SetShadowColor(0, 0, 0, 1)
    button.Count:SetShadowOffset(1, -1)

    -- Overlay for dispel types (poison, magic, etc.)
    button.Overlay = button:CreateTexture(nil, "OVERLAY")
    button.Overlay:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    button.Overlay:SetAllPoints()
    button.Overlay:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)

    -- Stealable texture
    button.Stealable = button:CreateTexture(nil, "OVERLAY")
    button.Stealable:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
    button.Stealable:SetPoint("TOPLEFT", -3, 3)
    button.Stealable:SetPoint("BOTTOMRIGHT", 3, -3)
    button.Stealable:SetBlendMode("ADD")
    button.Stealable:SetAlpha(0) -- Initialize as hidden to prevent first-target glow

    -- Border frame
    button.Border = CreateFrame("Frame", nil, button, "BackdropTemplate")
    button.Border:SetAllPoints()
    button.Border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    button.Border:SetBackdropBorderColor(0, 0, 0, 1)

    -- Tooltip - Use the same priority system as Blizzard for maximum compatibility
    button:SetScript("OnEnter", function(self)
        if GameTooltip:IsForbidden() or not self:IsVisible() then return end

        if self.auraType == "TempEnchant" then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
            GameTooltip:SetInventoryItem("player", self:GetID())
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetFrameLevel(self:GetFrameLevel() + 2)

        -- Midnight/Forever: SetUnitAuraByAuraInstanceID / SetUnitDebuff taint secret wrapText.
        -- Classic: SetUnitDebuff still shows unit-specific remaining time.
        local useSpellIdTooltip = false
        local Client = ns.Flux and ns.Flux.Client
        if Client and (Client.isMidnight or Client.isCamelot or Client.isForever) then
            useSpellIdTooltip = true
        elseif API.isV12 then
            useSpellIdTooltip = true
        elseif GetIsPreDF() then
            useSpellIdTooltip = false
        end

        if not useSpellIdTooltip then
            if not UnitAura then
                useSpellIdTooltip = true
            end
        end

        if not useSpellIdTooltip then
            -- Pre-DF / Classic clients: Always use classic UnitBuff/UnitDebuff approach
            if self.auraType == "Debuff" or self.auraType == "DeadlyDebuff" then
                GameTooltip:SetUnitDebuff(self.unit, self.auraIndex)
            else
                GameTooltip:SetUnitBuff(self.unit, self.auraIndex)
            end
        else
            -- Post-DF/12.0: SetUnitAuraByAuraInstanceID and SetUnitDebuff/SetUnitBuff cause "secret boolean
            -- tainted by _FluxUI" in Blizzard TooltipDataHandler when wrapText is a secret value.
            -- Use only SetSpellByID to avoid taint; skip tooltip when spellId is secret/unavailable.
            local safeSpellId = self.spellId and ns.API.SafeGetNumber and ns.API.SafeGetNumber(self.spellId, 0) or 0
            if safeSpellId and safeSpellId > 0 and GameTooltip.SetSpellByID then
                GameTooltip:SetSpellByID(safeSpellId)
            end
        end
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip:IsForbidden() then return end
        GameTooltip:Hide()
    end)

    -- Add GetFilter function like Blizzard's implementation
    button.GetFilter = function(self)
        if self.auraType == "Buff" or self.auraType == "TempEnchant" then
            return "HELPFUL"
        elseif self.auraType == "Debuff" or self.auraType == "DeadlyDebuff" then
            return "HARMFUL"
        end
        return nil
    end

    -- Enable mouse for tooltips by default
    button:EnableMouse(true)

    return button
end

-- Aura container creation
local function CreateAuraContainer(frame, containerType, maxAuras, aurasPerRow, size, spacing)
    local containerName = frame:GetName() .. containerType .. "Container"
    local container = CreateFrame("Frame", containerName, frame)

    -- Calculate dimensions
    local rows = math.ceil(maxAuras / aurasPerRow)
    local containerWidth = (size + spacing) * aurasPerRow - spacing
    local containerHeight = (size + spacing) * rows - spacing

    container:SetSize(containerWidth, containerHeight)
    container:SetFrameStrata("MEDIUM")
    container:EnableMouse(false) -- Don't intercept mouse events, let buttons handle them

    -- Container properties
    container.buttons = {}
    container.maxAuras = maxAuras
    container.aurasPerRow = aurasPerRow
    container.size = size
    container.spacing = spacing
    container.filter = (containerType == "Buff") and "HELPFUL" or "HARMFUL"
    container.unit = frame.unit

    -- Create buttons
    for i = 1, maxAuras do
        local button = CreateAuraButton(container, i)
        button:SetSize(size, size)
        container.buttons[i] = button
    end

    return container
end

-- Position aura buttons in grid layout
local function PositionAuraButtons(container)
    PositionAurasInBorderedContainer(container)
end

-- Update individual aura button
local function UpdateAuraButton(button, data, unit, container)
    if not data or not data.auraInstanceID then
        if button.Cooldown then
            if button.Cooldown.updateTimer then
                button.Cooldown.updateTimer:Cancel()
                button.Cooldown.updateTimer = nil
            end
            button.Cooldown._fluxAuraDurationTracked = nil
            button.Cooldown.durationText = nil
        end
        -- Reset border color to black when hiding
        if button.Border then
            button.Border:SetBackdropBorderColor(0, 0, 0, 1)
        end
        if button.Overlay then
            button.Overlay:Hide()
        end
        button._dispelStickyKey = nil
        button._lastDispelBorderRGBA = nil
        button._lastOverlayRGBA = nil
        button._fluxAuraBaseW = nil
        button._fluxAuraBaseH = nil
        button._fluxIsPlayerDebuff = nil
        button:Hide()
        return
    end

    -- Always start with stealable texture hidden to prevent glow artifacts
    if button.Stealable then
        button.Stealable:SetAlpha(0)
    end

    -- Set icon. Do not boolean-test data.icon: on Midnight it can be a secret value,
    -- and that test would abort the button before it is shown.
    if button.Icon then
        pcall(button.Icon.SetTexture, button.Icon, data.icon)
        button.Icon:Show()
    end

    -- Set cooldown
    if button.Cooldown then
        if API.isV12 and API.SafeGetAuraDuration and button.Cooldown.SetCooldownFromDurationObject then
            local durationObject = API.SafeGetAuraDuration(unit, data.auraInstanceID)

            if durationObject then
                -- Use the duration object directly (12.0+)
                button.Cooldown:SetCooldownFromDurationObject(durationObject)
                button.Cooldown:SetDrawEdge(false)
                button.Cooldown:SetReverse(true)
                ApplyAuraDuration(button.Cooldown, unit)
                button.Cooldown:Show()
            else
                button.Cooldown:Hide()
                if button.Cooldown.updateTimer then
                    button.Cooldown.updateTimer:Cancel()
                    button.Cooldown.updateTimer = nil
                end
                button.Cooldown._fluxAuraDurationTracked = nil
                button.Cooldown.durationText = nil
            end
        else
            -- Pre-12.0 fallback: Use traditional SetCooldown approach
            -- Use SafeGetNumber to handle secret values in 12.0+
            local duration = ns.API.SafeGetNumber(data.duration, 0)
            local expirationTime = ns.API.SafeGetNumber(data.expirationTime, 0)
            if duration > 0 and expirationTime > 0 then
                local startTime = expirationTime - duration
                button.Cooldown:SetCooldown(startTime, duration)
                button.Cooldown:SetDrawEdge(false)
                button.Cooldown:SetReverse(true)
                ApplyAuraDuration(button.Cooldown, unit)
                button.Cooldown:Show()
            else
                button.Cooldown:Hide()
                if button.Cooldown.updateTimer then
                    button.Cooldown.updateTimer:Cancel()
                    button.Cooldown.updateTimer = nil
                end
                button.Cooldown._fluxAuraDurationTracked = nil
                button.Cooldown.durationText = nil
            end
        end
    end

    -- Set stack count
    if button.Count then
        -- Use C_StringUtil.TruncateWhenZero for 12.0+ (handles secret values properly, like NephUI)
        -- TruncateWhenZero returns empty string for values < 2, so we can always set it
        local TruncateWhenZero = C_StringUtil and C_StringUtil.TruncateWhenZero
        if TruncateWhenZero and data.applications ~= nil then
            -- TruncateWhenZero handles secret values and returns empty string for < 2
            button.Count:SetText(TruncateWhenZero(data.applications))
            -- FontString:SetText accepts secret values, so this is safe
        elseif data.applications ~= nil then
            -- Fallback for older clients: use SafeGetNumber
            local applications = ns.API.SafeGetNumber(data.applications, 0)
            if applications >= 2 then
                if applications > 999 then
                    button.Count:SetText("*")
                else
                    button.Count:SetText(tostring(applications))
                end
            else
                button.Count:SetText("")
            end
        else
            button.Count:SetText("")
        end
        -- Always show the count text frame - FontString will handle empty strings correctly
        -- TruncateWhenZero returns empty string for < 2, which displays as nothing
        button.Count:Show()
    end

    -- Dispel overlay + border (debuffs only); sticky RGBA when APIs omit data in combat
    if container.containerType == "Buff" then
        if button.Overlay then
            button.Overlay:Hide()
        end
        if button.Border then
            button.Border:SetBackdropBorderColor(0, 0, 0, 1)
        end
        button._dispelStickyKey = nil
        button._lastDispelBorderRGBA = nil
        button._lastOverlayRGBA = nil
    else
        ApplyDebuffDispelVisuals(button, unit, data, container)
    end

    -- Set stealable texture (ONLY for buffs on enemy targets)
    if button.Stealable then
        -- Only show stealable texture for buffs on enemy targets
        if container.containerType == "Buff" then
            local isStealable = data.isStealable
            local isEnemy = not UnitCanCooperate("player", unit) -- Check if target is enemy
            if not IsSecretValue(isStealable) and isStealable and isEnemy then
                button.Stealable:SetAlpha(1)
            else
                button.Stealable:SetAlpha(0)
            end
        else
            -- Hide stealable texture for debuffs
            button.Stealable:SetAlpha(0)
        end
    end

    -- Resize for player debuffs (larger than other debuffs on target; see AuraOwn.BOOST)
    local isPlayerDebuff = false
    if container.containerType == "Debuff" then
        if AuraOwn and AuraOwn.IsOwnHarmful then
            isPlayerDebuff = AuraOwn.IsOwnHarmful(unit, data, OwnDebuffInstanceSet(unit))
        end
    end

    -- Base pixel size at fit=1; ApplyAuraFitToBorderedContainer applies _fluxAuraFitMult
    -- (own debuffs may stay at base when _fluxLockOwnDebuffSize is set).
    button._fluxIsPlayerDebuff = (container.containerType == "Debuff" and isPlayerDebuff) or nil
    local finalW, finalH = GetAuraButtonBaseDimensions(container, isPlayerDebuff)
    button._fluxAuraBaseW = finalW
    button._fluxAuraBaseH = finalH

    -- Store aura data for tooltips (matching Blizzard's approach)
    button.auraIndex = data.auraIndex
    button.auraInstanceID = data.auraInstanceID
    button.auraType = container.containerType == "Buff" and "Buff" or "Debuff"
    button.unit = unit
    -- Store spellId for 12.0 tooltip fallback (SetSpellByID avoids secret-value taint in SetUnitAuraByAuraInstanceID)
    button.spellId = data.spellId

    button:Show()
end

-- Update aura container
-- playerDebuffCacheFresh: when true, skip BuildPlayerDebuffInstanceSet (caller refreshed once for this unit)
local function UpdateAuraContainer(container, unit, playerDebuffCacheFresh)
    if container and container._fluxEngine then
        if UF.SyncEngineAuras then
            UF.SyncEngineAuras(container, container:GetParent())
        end
        return
    end
    if not container or not unit or not UnitExists(unit) then
        -- Hide all buttons and reset border colors
        for _, button in ipairs(container.buttons) do
            if button.Border then
                button.Border:SetBackdropBorderColor(0, 0, 0, 1)
            end
            if button.Overlay then
                button.Overlay:Hide()
            end
            button._dispelStickyKey = nil
            button._lastDispelBorderRGBA = nil
            button._lastOverlayRGBA = nil
            button._fluxAuraBaseW = nil
            button._fluxAuraBaseH = nil
            button._fluxIsPlayerDebuff = nil
            button:Hide()
        end
        container._fluxAuraFitMult = 1
        return
    end

    local maxAuras = container.maxAuras or DEFAULT_MAX_BUFFS
    local visibleCount = 0
    local isDebuffPanel = container.containerType == "Debuff"
    local filter = container.filter
    if isDebuffPanel and AuraOwn and AuraOwn.GetHarmfulFilter then
        filter = AuraOwn.GetHarmfulFilter()
    end

    local isPreDF = GetIsPreDF()

    if not isPreDF and isDebuffPanel and not playerDebuffCacheFresh then
        if AuraOwn and AuraOwn.BuildPlayerDebuffInstanceSet then
            playerDebuffInstanceIDs[unit] = AuraOwn.BuildPlayerDebuffInstanceSet(unit, maxAuras)
        end
    end
    -- Gather enough debuffs to sort mine-first (TPerl-style); then trim to maxAuras for display.
    local debuffGatherLimit = isDebuffPanel and math.max(maxAuras, 40) or maxAuras

    if isPreDF then
        if not UnitAura then
            return
        end
        if isDebuffPanel then
            local collected = scratchDebuffCollected
            wipe(collected)
            local order = 0
            local auraIndex = 0
            while auraIndex < 40 do
                local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura =
                    UnitAura(unit, auraIndex + 1, filter)
                if not name then
                    break
                end
                local dispelName = (dispelType and dispelType ~= "") and dispelType or nil
                order = order + 1
                local data = {
                    name = name,
                    icon = icon,
                    applications = count or 0,
                    dispelName = dispelName,
                    duration = duration or 0,
                    expirationTime = expirationTime or 0,
                    sourceUnit = source,
                    isStealable = isStealable,
                    nameplateShowPersonal = nameplateShowPersonal,
                    spellId = spellId,
                    canApplyAura = canApplyAura,
                    auraInstanceID = auraIndex + 1,
                    auraIndex = auraIndex + 1,
                    _fluxCollectOrder = order,
                }
                collected[#collected + 1] = data
                auraIndex = auraIndex + 1
            end
            SortDebuffDataListPlayerFirst(unit, collected)
            visibleCount = math.min(#collected, maxAuras)
            for i = 1, visibleCount do
                collected[i]._fluxCollectOrder = nil
                UpdateAuraButton(container.buttons[i], collected[i], unit, container)
            end
        else
            -- Pre-DF: buffs — original order, cap at maxAuras
            local auraIndex = 0
            while auraIndex < 40 and visibleCount < maxAuras do
                local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId =
                    UnitAura(unit, auraIndex + 1, filter)

                if name then
                    local dispelName = (dispelType and dispelType ~= "") and dispelType or nil
                    local data = {
                        name = name,
                        icon = icon,
                        applications = count or 0,
                        dispelName = dispelName,
                        duration = duration or 0,
                        expirationTime = expirationTime or 0,
                        sourceUnit = source,
                        isStealable = isStealable,
                        spellId = spellId,
                        auraInstanceID = auraIndex + 1,
                        auraIndex = auraIndex + 1,
                    }

                    visibleCount = visibleCount + 1
                    local button = container.buttons[visibleCount]
                    if button then
                        UpdateAuraButton(button, data, unit, container)
                    end
                    auraIndex = auraIndex + 1
                else
                    break
                end
            end
        end
    else
        if isDebuffPanel then
            -- Target/focus debuffs: index 1..N, never GetAuraSlots.
            -- Slot lists put a continuation token in the first return; starting at
            -- index 2 drops the lead debuff whenever more than one is present.
            local collected = scratchDebuffCollected
            wipe(collected)
            local order = 0
            local function pushDebuffData(data, auraIndexField)
                if not data then
                    return
                end
                if not data.auraInstanceID then
                    data.auraInstanceID = auraIndexField
                end
                order = order + 1
                data._fluxCollectOrder = order
                data.auraIndex = auraIndexField
                collected[#collected + 1] = data
            end

            if API.SafeGetAuraDataByIndex then
                for auraIndex = 1, debuffGatherLimit do
                    local data = API.SafeGetAuraDataByIndex(unit, auraIndex, filter)
                    if not data then
                        break
                    end
                    pushDebuffData(data, auraIndex)
                end
            elseif UnitAura then
                for auraIndex = 1, debuffGatherLimit do
                    local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura =
                        UnitAura(unit, auraIndex, filter)
                    if not name then
                        break
                    end
                    local dispelName = (dispelType and dispelType ~= "") and dispelType or nil
                    pushDebuffData({
                        name = name,
                        icon = icon,
                        applications = count or 0,
                        dispelName = dispelName,
                        duration = duration or 0,
                        expirationTime = expirationTime or 0,
                        sourceUnit = source,
                        isStealable = isStealable,
                        nameplateShowPersonal = nameplateShowPersonal,
                        spellId = spellId,
                        canApplyAura = canApplyAura,
                        auraInstanceID = auraIndex,
                    }, auraIndex)
                end
            end

            SortDebuffDataListPlayerFirst(unit, collected)
            visibleCount = math.min(#collected, maxAuras)
            for i = 1, visibleCount do
                collected[i]._fluxCollectOrder = nil
                UpdateAuraButton(container.buttons[i], collected[i], unit, container)
            end
        else
            -- Buffs keep the slot list. Debuffs must not: index 1 of that list is a continuation token.
            local slots, accessible = {}, true
            if API.SafeGetAuraSlots then
                slots, accessible = API.SafeGetAuraSlots(unit, filter)
            end
            if accessible == false then
                return
            end
            if type(slots) ~= "table" then
                slots = {}
            end

            local useIndexFallback = false
            if #slots < 2 and API.SafeGetAuraDataByIndex then
                local probe = API.SafeGetAuraDataByIndex(unit, 1, filter)
                if probe and probe.auraInstanceID then
                    useIndexFallback = true
                end
            end

            if useIndexFallback then
                for auraIndex = 1, maxAuras do
                    if visibleCount >= maxAuras then
                        break
                    end
                    local data = API.SafeGetAuraDataByIndex(unit, auraIndex, filter)
                    if not data or not data.auraInstanceID then
                        break
                    end
                    data.auraIndex = auraIndex
                    visibleCount = visibleCount + 1
                    local button = container.buttons[visibleCount]
                    if button then
                        UpdateAuraButton(button, data, unit, container)
                    end
                end
            else
                for i = 2, #slots do
                    if visibleCount >= maxAuras then
                        break
                    end

                    local slot = slots[i]
                    local data = nil
                    if API.SafeGetAuraDataBySlot then
                        data = API.SafeGetAuraDataBySlot(unit, slot, filter)
                    end

                    if data and data.auraInstanceID then
                        data.auraIndex = slot
                        visibleCount = visibleCount + 1
                        local button = container.buttons[visibleCount]
                        if button then
                            UpdateAuraButton(button, data, unit, container)
                        end
                    end
                end
            end

            if visibleCount == 0 and UnitExists(unit) and API.SafeGetAuraDataByIndex then
                local probe = API.SafeGetAuraDataByIndex(unit, 1, filter)
                if probe and probe.auraInstanceID then
                    for auraIndex = 1, maxAuras do
                        if visibleCount >= maxAuras then
                            break
                        end
                        local data = API.SafeGetAuraDataByIndex(unit, auraIndex, filter)
                        if not data or not data.auraInstanceID then
                            break
                        end
                        data.auraIndex = auraIndex
                        visibleCount = visibleCount + 1
                        local button = container.buttons[visibleCount]
                        if button then
                            UpdateAuraButton(button, data, unit, container)
                        end
                    end
                end
            end
        end
    end

    -- Hide unused buttons and reset border colors
    for i = visibleCount + 1, #container.buttons do
        local button = container.buttons[i]
        if button then
            if button.Border then
                button.Border:SetBackdropBorderColor(0, 0, 0, 1)
            end
            if button.Overlay then
                button.Overlay:Hide()
            end
            button._dispelStickyKey = nil
            button._lastDispelBorderRGBA = nil
            button._lastOverlayRGBA = nil
            button._fluxAuraBaseW = nil
            button._fluxAuraBaseH = nil
            button._fluxIsPlayerDebuff = nil
            button:Hide()
        end
    end

    if container.containerType then
        ApplyAuraFitToBorderedContainer(container, visibleCount)
        PositionAurasInBorderedContainer(container)
    end
end

-- Side-by-side player+target (placement 2): target auras sit above the chrome like focus/player, not below.
local function ShouldAurasAnchorAboveUnit(frame)
    if not frame then
        return false
    end
    if frame.unit == "focus" or frame.auraFrameAboveUnit == true then
        return true
    end
    if frame.unit ~= "target" then
        return false
    end
    if not FluxUnitFrames_GetPlayerTargetPlacement or not FluxUnitFrames_ShouldUseFlux then
        return false
    end
    return FluxUnitFrames_GetPlayerTargetPlacement() == 2
        and FluxUnitFrames_ShouldUseFlux("player")
        and FluxUnitFrames_ShouldUseFlux("target")
end

-- Buff/debuff panel width tracks half of (bars + portrait) width when a side portrait exists; else half of bar column only.
local function ComputeAuraContainerWidthHeight(frame, baseSizeForMin, container)
    local unitFrameWidth = frame:GetWidth()
    local portraitSize = frame:GetHeight()
    local combinedWidth = unitFrameWidth
    if UF.FrameUsesPortraitLayout and UF.FrameUsesPortraitLayout(frame) then
        combinedWidth = unitFrameWidth + portraitSize
    end
    local containerWidth = combinedWidth / 2 + 13
    local fh = frame:GetHeight() or 100
    local bs = (container and container._fluxAuraBaseSize) or baseSizeForMin or DEFAULT_AURA_SIZE
    local containerHeight = 90
    if frame.unit == "focus" then
        local compactMin = math.max(44, bs * 2 + 24)
        containerHeight = math.max(compactMin, math.min(140, math.floor(fh * 0.65 + 34)))
    elseif frame.unit == "target" then
        containerHeight = math.max(56, math.min(200, math.floor(fh * 0.72 + 24)))
    end
    return containerWidth, containerHeight
end

-- Resize bordered buff/debuff panel to match squeezed unit frame + scaled icon row metrics
local function RefreshBorderedAuraContainerDimensions(container)
    if not container or not container.borderFrame then return end
    local frame = container:GetParent()
    if not frame or not frame.GetWidth or not frame.GetHeight then return end

    local containerWidth, containerHeight = ComputeAuraContainerWidthHeight(frame, nil, container)
    local baseSize = container._fluxAuraBaseSize or DEFAULT_AURA_SIZE

    container:SetSize(containerWidth, containerHeight)
    container.borderFrame:SetSize(containerWidth, containerHeight)

    local xF = GetFluxAuraLayoutXSqueezeMult()
    local baseSpacing = container._fluxAuraBaseSpacing or DEFAULT_AURA_SPACING
    -- Logical width for layout (X scaled); height stays nominal on buttons
    container.size = baseSize * xF
    container.spacing = baseSpacing * xF
end

local function RefreshBorderedAuraLayoutsForFrame(frame)
    if not frame then return end
    if frame.BuffContainer then
        RefreshBorderedAuraContainerDimensions(frame.BuffContainer)
    end
    if frame.DebuffContainer then
        RefreshBorderedAuraContainerDimensions(frame.DebuffContainer)
    end
end

--- Re-anchor and resize Flux aura panels after unit frame / outer border layout changes (target & focus).
function UF.UpdateAuraPosition(frame)
    if not frame or not frame.unit then
        return
    end
    if frame.unit ~= "target" and frame.unit ~= "focus" then
        return
    end
    if not frame.BuffContainer and not frame.DebuffContainer then
        return
    end

    RefreshBorderedAuraLayoutsForFrame(frame)

    local auraFrameAbove = ShouldAurasAnchorAboveUnit(frame)
    -- Between-mode: pin to threat shell with the same nest as outer chrome (visual flush, not frame-edge 0,0).
    local betweenThreat = frame.ThreatBar
        and (frame._fluxThreatBarMode == "between"
            or (UF.GetThreatBarPosition and UF.GetThreatBarPosition(frame) == "between"))
    local anchorFrame = (betweenThreat and frame.ThreatBar) or frame.outerBorderFrame or frame
    -- Nest into chrome/threat so battlefield aura borders meet with no visual gap (same as pre-threat layout).
    local nestY = 10
    local buffNestX = -10
    local debuffNestX = 0

    if frame.BuffContainer then
        frame.BuffContainer._fluxAuraGrowUpward = auraFrameAbove
        frame.BuffContainer:ClearAllPoints()
        if auraFrameAbove then
            frame.BuffContainer:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", buffNestX, -nestY)
        else
            frame.BuffContainer:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", buffNestX, nestY)
        end
        PositionAurasInBorderedContainer(frame.BuffContainer)
    end
    if frame.DebuffContainer then
        frame.DebuffContainer._fluxAuraGrowUpward = auraFrameAbove
        frame.DebuffContainer:ClearAllPoints()
        if auraFrameAbove then
            frame.DebuffContainer:SetPoint("BOTTOMRIGHT", anchorFrame, "TOPRIGHT", debuffNestX, -nestY)
        else
            frame.DebuffContainer:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", debuffNestX, nestY)
        end
        PositionAurasInBorderedContainer(frame.DebuffContainer)
    end

    if UF.UpdateAuras then
        UF.UpdateAuras(frame)
    end
end

--- Called when Flux raid repositions or roster changes; refreshes focus aura anchors vs. group column.
function _G.FluxUnitFrames_UpdateFocusAuraLayoutForRaidStack()
    if InCombatLockdown() then
        return
    end
    local fr = ns.FocusFrame
    if fr and UF.UpdateAuraPosition then
        UF.UpdateAuraPosition(fr)
    end
end

-- One HARMFUL|PLAYER scan per refresh tick, then both containers (buff + debuff) reuse it
local function RefreshFrameAuras(frame, unit)
    if not frame or not unit then return end

    RefreshBorderedAuraLayoutsForFrame(frame)

    if UF.FrameUsesEngineAuras and UF.FrameUsesEngineAuras(frame) then
        if frame.BuffContainer and UF.SyncEngineAuras then
            UF.SyncEngineAuras(frame.BuffContainer, frame)
        end
        if frame.DebuffContainer and UF.SyncEngineAuras then
            UF.SyncEngineAuras(frame.DebuffContainer, frame)
        end
        return
    end

    if not UnitExists(unit) then
        if frame.BuffContainer then
            UpdateAuraContainer(frame.BuffContainer, unit)
        end
        if frame.DebuffContainer then
            UpdateAuraContainer(frame.DebuffContainer, unit)
        end
        return
    end

    local isPreDF = GetIsPreDF()
    if not isPreDF and frame.DebuffContainer then
        local maxD = frame.DebuffContainer.maxAuras or DEFAULT_MAX_DEBUFFS
        if AuraOwn and AuraOwn.BuildPlayerDebuffInstanceSet then
            playerDebuffInstanceIDs[unit] = AuraOwn.BuildPlayerDebuffInstanceSet(unit, maxD)
        end
    end

    if frame.BuffContainer then
        UpdateAuraContainer(frame.BuffContainer, unit, true)
    end
    if frame.DebuffContainer then
        UpdateAuraContainer(frame.DebuffContainer, unit, true)
    end
end

local function SweepContainerCooldownDurations(container)
    if not container or not container:IsVisible() or container._fluxEngine then return end
    if not container.buttons then return end
    for _, button in ipairs(container.buttons) do
        local cd = button.Cooldown
        if cd and cd._fluxAuraDurationTracked and button:IsShown() then
            UpdateCooldownDurationText(cd)
        end
    end
end

local function SweepAuraCooldownDurationTexts()
    local any = false
    for frame in pairs(auraCache) do
        if frame:IsVisible() and frame.unit then
            local buff = frame.BuffContainer
            local debuff = frame.DebuffContainer
            local had = false
            if buff and buff:IsVisible() and not buff._fluxEngine and buff.buttons then
                for _, button in ipairs(buff.buttons) do
                    local cd = button.Cooldown
                    if cd and cd._fluxAuraDurationTracked and button:IsShown() then
                        had = true
                        UpdateCooldownDurationText(cd)
                    end
                end
            end
            if debuff and debuff:IsVisible() and not debuff._fluxEngine and debuff.buttons then
                for _, button in ipairs(debuff.buttons) do
                    local cd = button.Cooldown
                    if cd and cd._fluxAuraDurationTracked and button:IsShown() then
                        had = true
                        UpdateCooldownDurationText(cd)
                    end
                end
            end
            if had then
                any = true
            end
        end
    end
    -- No tracked duration texts: park the ticker until auras reappear.
    if not any and auraDurationSweepTimer then
        auraDurationSweepTimer:Cancel()
        auraDurationSweepTimer = nil
        _G.FluxUFAuraDurationTicker = nil
    end
end

local function CancelAuraDebounce(frame)
    if frame._fluxAuraDebounceHandle then
        frame._fluxAuraDebounceHandle:Cancel()
        frame._fluxAuraDebounceHandle = nil
    end
    frame._fluxAuraDebounceUnit = nil
end

-- Leading throttle + one trailing refresh. After returns no cancel handle on
-- any supported client; NewTimer lets target changes/disable cancel stale work.
local function RequestAuraRefreshThrottled(frame, unit)
    if not unit or unit ~= frame.unit or not UnitExists(unit) then return end
    local now = GetTime()
    local last = frame._fluxAuraLastRefresh or 0
    if (now - last) >= UNIT_AURA_DEBOUNCE_SEC then
        CancelAuraDebounce(frame)
        frame._fluxAuraLastRefresh = now
        RefreshFrameAuras(frame, unit)
        return
    end
    frame._fluxAuraDebounceUnit = unit
    if frame._fluxAuraDebounceHandle then return end
    frame._fluxAuraDebounceHandle = C_Timer.NewTimer(UNIT_AURA_DEBOUNCE_SEC - (now - last), function()
        frame._fluxAuraDebounceHandle = nil
        local u = frame._fluxAuraDebounceUnit
        frame._fluxAuraDebounceUnit = nil
        if u and frame.unit == u and UnitExists(u) then
            frame._fluxAuraLastRefresh = GetTime()
            RefreshFrameAuras(frame, u)
        end
    end)
end

-- Refresh dispel overlays and border colors for visible buttons (called when combat state changes)
local function RefreshDispelOverlays(container, unit)
    if not container or container.containerType ~= "Debuff" or container._fluxEngine then return end
    if not container.buttons then return end
    for _, button in ipairs(container.buttons) do
        if button:IsShown() and button.auraInstanceID then
            local data = API.SafeGetAuraDataByAuraInstanceID and API.SafeGetAuraDataByAuraInstanceID(unit, button.auraInstanceID)
            if data then
                ApplyDebuffDispelVisuals(button, unit, data, container)
            end
        end
    end
end

-- Single ticker: cooldown duration text only (full rescans via debounced UNIT_AURA + combat hooks)
StartAuraUpdates = function()
    if auraDurationSweepTimer then return end

    if not C_Timer or not C_Timer.NewTicker then
        print("|cFFFF0000[FluxUI]|r ERROR: C_Timer.NewTicker not available for aura duration sweep")
        return
    end

    auraDurationSweepTimer = C_Timer.NewTicker(AURA_DURATION_SWEEP_INTERVAL, SweepAuraCooldownDurationTexts)
    _G.FluxUFAuraDurationTicker = auraDurationSweepTimer
end

local function StopAuraUpdates()
    if auraDurationSweepTimer then
        auraDurationSweepTimer:Cancel()
        auraDurationSweepTimer = nil
    end
    _G.FluxUFAuraDurationTicker = nil
end

-- Create bordered aura container (exactly like old version)
local function CreateBorderedAuraContainer(frame, containerType, maxAuras, aurasPerRow, size, spacing, extra)
    extra = extra or {}
    -- Create main container
    local containerName = frame:GetName() .. containerType .. "Container"
    local container = CreateFrame("Frame", containerName, frame)

    local containerWidth, containerHeight = ComputeAuraContainerWidthHeight(frame, size, nil)

    container:SetSize(containerWidth, containerHeight)
    container:SetFrameStrata("MEDIUM")

    -- Container properties
    container.buttons = {}
    container.maxAuras = maxAuras
    container.aurasPerRow = aurasPerRow
    container.size = size
    container.spacing = spacing
    container.filter = (containerType == "Buff") and "HELPFUL" or "HARMFUL"
    container.unit = frame.unit
    container.containerType = containerType
    container._fluxAuraBaseSize = size
    container._fluxAuraBaseSpacing = spacing
    container._fluxAuraGrowUpward = extra.growUpward
    container._fluxLockOwnDebuffSize = extra.lockOwnDebuffSize
    container._fluxOwnDebuffMinScale = extra.ownDebuffMinScale
    container._fluxAuraMinPx = extra.minAuraPx

    -- Create border frame (battlefield style) - exactly like old version
    local borderFrame = CreateFrame("Frame", containerName .. "Border", container)
    borderFrame:SetSize(containerWidth, containerHeight)
    borderFrame:SetPoint("CENTER", container, "CENTER", 0, 0)
    borderFrame:SetFrameStrata("BACKGROUND")
    borderFrame:SetFrameLevel(0)
    borderFrame:EnableMouse(false) -- Don't intercept mouse events from aura buttons

    -- Add battlefield-style border textures - exactly like old version
    local function addCorner(parent, key, point, xOfs, yOfs, atlas)
        local t = parent:CreateTexture(nil, "ARTWORK")

        -- Check if atlas is available and use it, otherwise use fallback
        if not SafeSetAtlas(t, atlas, true) then
            -- Fallback for legacy clients - use the same atlas system as other files
            t = CreateLegacyBattlefieldBorderPiece(parent, "ARTWORK", true, key)
        end

        if t then
            t:SetPoint(point, xOfs, yOfs)
            t:SetVertexColor(0.6, 0.6, 0.6, 0.4)
            parent[key] = t
        end
        return t
    end

    local function addEdge(parent, key, atlas)
        local t = parent:CreateTexture(nil, "ARTWORK")

        -- Check if atlas is available and use it, otherwise use fallback
        if not SafeSetAtlas(t, atlas) then
            -- Fallback for legacy clients - use the same atlas system as other files
            local edgeType = "Top" -- Default edge type

            -- Determine edge type from atlas name
            if string.find(atlas, "top") then
                edgeType = "Top"
            elseif string.find(atlas, "bottom") then
                edgeType = "Bottom"
            elseif string.find(atlas, "left") then
                edgeType = "Left"
            elseif string.find(atlas, "right") then
                edgeType = "Right"
            end

            t = CreateLegacyBattlefieldBorderPiece(parent, "ARTWORK", false, nil, edgeType)
        end

        if t then
            t:SetVertexColor(0.6, 0.6, 0.6, 0.4)
            parent[key] = t
        end
        return t
    end

    -- Corner textures for buff/debuff area
    local TL = addCorner(borderFrame, "TL", "TOPLEFT", 0, 0, "battlefieldminimap-border-topleft")
    local TR = addCorner(borderFrame, "TR", "TOPRIGHT", 0, 0, "battlefieldminimap-border-topright")
    local BL = addCorner(borderFrame, "BL", "BOTTOMLEFT", 0, 0, "battlefieldminimap-border-bottomleft")
    local BR = addCorner(borderFrame, "BR", "BOTTOMRIGHT", 0, 0, "battlefieldminimap-border-bottomright")

    -- Edge textures
    local Top = addEdge(borderFrame, "Top", "battlefieldminimap-border-top")
    local Bottom = addEdge(borderFrame, "Bottom", "battlefieldminimap-border-bottom")
    local Left = addEdge(borderFrame, "Left", "battlefieldminimap-border-left")
    local Right = addEdge(borderFrame, "Right", "battlefieldminimap-border-right")

    Top:SetPoint("TOPLEFT", TL, "TOPRIGHT")
    Top:SetPoint("BOTTOMRIGHT", TR, "BOTTOMLEFT")

    Bottom:SetPoint("TOPLEFT", BL, "TOPRIGHT")
    Bottom:SetPoint("BOTTOMRIGHT", BR, "BOTTOMLEFT")

    Left:SetPoint("TOPLEFT", TL, "BOTTOMLEFT")
    Left:SetPoint("BOTTOMRIGHT", BL, "TOPRIGHT")

    Right:SetPoint("TOPLEFT", TR, "BOTTOMLEFT")
    Right:SetPoint("BOTTOMRIGHT", BR, "TOPRIGHT")

    -- Semi-transparent fill for area
    local Fill = borderFrame:CreateTexture(nil, "BACKGROUND")
    Fill:SetPoint("TOPLEFT", TL, "BOTTOMRIGHT", -8, 8)
    Fill:SetPoint("TOPRIGHT", TR, "BOTTOMLEFT", 8, 8)
    Fill:SetPoint("BOTTOMLEFT", BL, "TOPRIGHT", -8, -8)
    Fill:SetPoint("BOTTOMRIGHT", BR, "TOPLEFT", 8, -8)
    Fill:SetColorTexture(0.6, 0.6, 0.6, 0.08)
    borderFrame.Fill = Fill

    -- Add label
    local label = borderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", borderFrame, "BOTTOM", 0, 8)
    if containerType == "Buff" then
        label:SetText("Buffs")
        label:SetTextColor(0.2, 0.8, 0.2, 0.7) -- Green for buffs
    else
        label:SetText("Debuffs")
        label:SetTextColor(0.8, 0.2, 0.2, 0.7) -- Red for debuffs
    end
    if frame.unit == "focus" then
        label:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    end

    -- Create buttons (Classic / Lua path). Midnight uses Blizzard AuraContainer.
    if UF.UseEngineAuras and UF.UseEngineAuras() and UF.AttachEngineAuras then
        if not UF.AttachEngineAuras(container, frame) then
            for i = 1, maxAuras do
                local button = CreateAuraButton(container, i)
                button:SetSize(size, size)
                container.buttons[i] = button
            end
        end
    else
        for i = 1, maxAuras do
            local button = CreateAuraButton(container, i)
            button:SetSize(size, size)
            container.buttons[i] = button
        end
    end

    container.borderFrame = borderFrame
    return container
end

-- Position auras within bordered container (handling variable sizes for player debuffs)
PositionAurasInBorderedContainer = function(container)
    if container and container._fluxEngine then
        if UF.SyncEngineAuras then
            UF.SyncEngineAuras(container, container:GetParent())
        end
        return
    end
    local fitMult = container._fluxAuraFitMult or 1
    local xF = GetFluxAuraLayoutXSqueezeMult()
    local baseSp = container._fluxAuraBaseSpacing or DEFAULT_AURA_SPACING
    local spacingX = baseSp * xF * fitMult
    -- Use packed slot count (shown icons fill 1..N after UpdateAuraContainer).
    local packedCount = 0
    for i = 1, #container.buttons do
        if container.buttons[i] and container.buttons[i]:IsShown() then
            packedCount = i
        else
            break
        end
    end
    local rowStepY = GetAuraLayoutRowStepY(container, fitMult, packedCount)

    local maxRowWidth = select(1, GetBorderedAuraInnerMetrics(container))
    local leftInset = AURA_BORDER_INSET_X

    -- Auras anchored above the unit frame: fill bottom row left→right, wrap to next row upward
    if container._fluxAuraGrowUpward then
        local bottomInset = 10
        local currentX = leftInset
        local currentY = bottomInset

        for i = 1, #container.buttons do
            local button = container.buttons[i]
            if button and button:IsShown() then
                local buttonSize = button:GetWidth()

                if currentX + buttonSize > maxRowWidth then
                    currentX = leftInset
                    currentY = currentY + rowStepY
                end

                button:ClearAllPoints()
                button:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", currentX, currentY)

                currentX = currentX + buttonSize + spacingX
            end
        end
        return
    end

    -- Default: top-left origin, rows grow downward
    local currentX = leftInset
    local currentY = -10  -- Start with border offset
    local row = 0

    for i = 1, #container.buttons do
        local button = container.buttons[i]
        if button and button:IsShown() then
            local buttonSize = button:GetWidth()

            -- Check if we need to wrap to next row
            if currentX + buttonSize > maxRowWidth then
                row = row + 1
                currentX = leftInset
                currentY = currentY - rowStepY
            end

            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", container, "TOPLEFT", currentX, currentY)

            currentX = currentX + buttonSize + spacingX
        end
    end
end

--- Rebuild aura panels when icon caps increase; otherwise UF.EnableAuras updates sizes/spacing on existing containers.
function UF.ApplyAuraOptionsToFrame(frame, enableBuffs, enableDebuffs, buffConfig, debuffConfig)
    if not frame then
        return
    end
    buffConfig = buffConfig or {}
    debuffConfig = debuffConfig or {}
    local buffMax = buffConfig.max or DEFAULT_MAX_BUFFS
    local debuffMax = debuffConfig.max or DEFAULT_MAX_DEBUFFS

    if frame.BuffContainer and not frame.BuffContainer._fluxEngine and buffMax > #frame.BuffContainer.buttons then
        frame.BuffContainer:Hide()
        frame.BuffContainer:SetParent(nil)
        frame.BuffContainer = nil
    end
    if frame.DebuffContainer and not frame.DebuffContainer._fluxEngine and debuffMax > #frame.DebuffContainer.buttons then
        frame.DebuffContainer:Hide()
        frame.DebuffContainer:SetParent(nil)
        frame.DebuffContainer = nil
    end

    UF.EnableAuras(frame, enableBuffs, enableDebuffs, buffConfig, debuffConfig)
    UF.UpdateAuraPosition(frame)
end

-- Main aura enable function
function UF.EnableAuras(frame, enableBuffs, enableDebuffs, buffConfig, debuffConfig)
    if not frame then return end

    -- Default configs
    buffConfig = buffConfig or {}
    debuffConfig = debuffConfig or {}

    local buffSize = buffConfig.size or DEFAULT_AURA_SIZE
    local buffMax = buffConfig.max or DEFAULT_MAX_BUFFS
    local buffPerRow = buffConfig.perRow or DEFAULT_BUFFS_PER_ROW
    local buffSpacing = buffConfig.spacing or DEFAULT_AURA_SPACING

    local debuffSize = debuffConfig.size or DEFAULT_AURA_SIZE
    local debuffMax = debuffConfig.max or DEFAULT_MAX_DEBUFFS
    local debuffPerRow = debuffConfig.perRow or DEFAULT_DEBUFFS_PER_ROW
    local debuffSpacing = debuffConfig.spacing or DEFAULT_AURA_SPACING
    local lockOwnDebuffSize = debuffConfig.lockOwnDebuffSize
    if lockOwnDebuffSize == nil then
        lockOwnDebuffSize = true
    end
    local ownDebuffMinScale = tonumber(debuffConfig.ownDebuffMinScale)
    if not ownDebuffMinScale then
        ownDebuffMinScale = 1
    end
    if ownDebuffMinScale > 1 then
        ownDebuffMinScale = 1
    elseif ownDebuffMinScale < 0.5 then
        ownDebuffMinScale = 0.5
    end

    -- Aura panels anchored above the unit frame use bottom→up row growth (see PositionAurasInBorderedContainer)
    local auraFrameAbove = ShouldAurasAnchorAboveUnit(frame)
    local betweenThreat = frame.ThreatBar
        and (frame._fluxThreatBarMode == "between"
            or (UF.GetThreatBarPosition and UF.GetThreatBarPosition(frame) == "between"))
    local auraAnchor = (betweenThreat and frame.ThreatBar) or frame.outerBorderFrame or frame
    -- Same nest as outer chrome so aura borders stay visually flush (0,0 frame edges leave a gap).
    local nestY = 10
    local buffNestX = -10

    -- Create buff container (left half; default: below outer border — focus: above)
    if enableBuffs ~= false then
        if not frame.BuffContainer then
            frame.BuffContainer = CreateBorderedAuraContainer(frame, "Buff", buffMax, buffPerRow, buffSize, buffSpacing, {
                growUpward = auraFrameAbove,
                lockOwnDebuffSize = false,
                minAuraPx = buffConfig.minAuraPx or DEFAULT_MIN_AURA_PX,
            })
            if auraFrameAbove then
                -- Flush to threat strip when between-mode; else nest into outer chrome
                frame.BuffContainer:SetPoint("BOTTOMLEFT", auraAnchor, "TOPLEFT", buffNestX, -nestY)
            else
                frame.BuffContainer:SetPoint("TOPLEFT", auraAnchor, "BOTTOMLEFT", buffNestX, nestY)
            end
        end
        if frame.BuffContainer then
            frame.BuffContainer._fluxAuraGrowUpward = auraFrameAbove
            local n = #frame.BuffContainer.buttons
            if n > 0 then
                frame.BuffContainer.maxAuras = math.min(buffMax, n)
            else
                frame.BuffContainer.maxAuras = buffMax
            end
            frame.BuffContainer._fluxAuraBaseSize = buffSize
            frame.BuffContainer._fluxAuraBaseSpacing = buffSpacing
            frame.BuffContainer.aurasPerRow = buffPerRow
            frame.BuffContainer._fluxAuraMinPx = buffConfig.minAuraPx or DEFAULT_MIN_AURA_PX
            frame.BuffContainer._fluxLockOwnDebuffSize = false
            frame.BuffContainer._fluxOwnDebuffMinScale = 1
        end
        RefreshBorderedAuraContainerDimensions(frame.BuffContainer)
        PositionAurasInBorderedContainer(frame.BuffContainer)
        frame.BuffContainer:Show()
    elseif frame.BuffContainer then
        -- Ensure all buttons are hidden when container is disabled
        if frame.BuffContainer.buttons then
            for _, button in ipairs(frame.BuffContainer.buttons) do
                button:Hide()
            end
        end
        if frame.BuffContainer._fluxEngine then
            pcall(frame.BuffContainer._fluxEngine.Hide, frame.BuffContainer._fluxEngine)
        end
        frame.BuffContainer:Hide()
    end

    -- Create debuff container (right half; default: below outer border — focus: above)
    if enableDebuffs ~= false then
        if not frame.DebuffContainer then
            frame.DebuffContainer = CreateBorderedAuraContainer(frame, "Debuff", debuffMax, debuffPerRow, debuffSize, debuffSpacing, {
                growUpward = auraFrameAbove,
                lockOwnDebuffSize = lockOwnDebuffSize,
                ownDebuffMinScale = ownDebuffMinScale,
                minAuraPx = debuffConfig.minAuraPx or DEFAULT_MIN_AURA_PX,
            })
            if auraFrameAbove then
                frame.DebuffContainer:SetPoint("BOTTOMRIGHT", auraAnchor, "TOPRIGHT", 0, -nestY)
            else
                frame.DebuffContainer:SetPoint("TOPRIGHT", auraAnchor, "BOTTOMRIGHT", 0, nestY)
            end
        end
        if frame.DebuffContainer then
            frame.DebuffContainer._fluxAuraGrowUpward = auraFrameAbove
            local n = #frame.DebuffContainer.buttons
            if n > 0 then
                frame.DebuffContainer.maxAuras = math.min(debuffMax, n)
            else
                frame.DebuffContainer.maxAuras = debuffMax
            end
            frame.DebuffContainer._fluxAuraBaseSize = debuffSize
            frame.DebuffContainer._fluxAuraBaseSpacing = debuffSpacing
            frame.DebuffContainer.aurasPerRow = debuffPerRow
            frame.DebuffContainer._fluxAuraMinPx = debuffConfig.minAuraPx or DEFAULT_MIN_AURA_PX
            frame.DebuffContainer._fluxLockOwnDebuffSize = lockOwnDebuffSize and true or false
            frame.DebuffContainer._fluxOwnDebuffMinScale = ownDebuffMinScale
        end
        RefreshBorderedAuraContainerDimensions(frame.DebuffContainer)
        PositionAurasInBorderedContainer(frame.DebuffContainer)
        frame.DebuffContainer:Show()
    elseif frame.DebuffContainer then
        -- Ensure all buttons are hidden when container is disabled
        if frame.DebuffContainer.buttons then
            for _, button in ipairs(frame.DebuffContainer.buttons) do
                button:Hide()
            end
        end
        if frame.DebuffContainer._fluxEngine then
            pcall(frame.DebuffContainer._fluxEngine.Hide, frame.DebuffContainer._fluxEngine)
        end
        frame.DebuffContainer:Hide()
    end

    -- Re-anchor when containers already existed (reload / toggle)
    if frame.BuffContainer or frame.DebuffContainer then
        if frame.BuffContainer then
            frame.BuffContainer._fluxAuraGrowUpward = auraFrameAbove
            frame.BuffContainer:ClearAllPoints()
            if auraFrameAbove then
                frame.BuffContainer:SetPoint("BOTTOMLEFT", auraAnchor, "TOPLEFT", buffNestX, -nestY)
            else
                frame.BuffContainer:SetPoint("TOPLEFT", auraAnchor, "BOTTOMLEFT", buffNestX, nestY)
            end
        end
        if frame.DebuffContainer then
            frame.DebuffContainer._fluxAuraGrowUpward = auraFrameAbove
            frame.DebuffContainer:ClearAllPoints()
            if auraFrameAbove then
                frame.DebuffContainer:SetPoint("BOTTOMRIGHT", auraAnchor, "TOPRIGHT", 0, -nestY)
            else
                frame.DebuffContainer:SetPoint("TOPRIGHT", auraAnchor, "BOTTOMRIGHT", 0, nestY)
            end
        end
    end

    if enableBuffs ~= false or enableDebuffs ~= false then
        RefreshFrameAuras(frame, frame.unit)
        -- Next frame + short delay: catches slot API being briefly empty after reload while unit already exists.
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if frame.BuffContainer or frame.DebuffContainer then
                    UF.UpdateAuras(frame)
                end
            end)
            C_Timer.After(0.2, function()
                if frame.BuffContainer or frame.DebuffContainer then
                    UF.UpdateAuras(frame)
                end
            end)
        end
    end

    -- Register for aura updates
    if enableBuffs ~= false or enableDebuffs ~= false then
        auraCache[frame] = true
        if not (UF.FrameUsesEngineAuras and UF.FrameUsesEngineAuras(frame)) then
            StartAuraUpdates()
        end

        -- Register unit aura events
        if not frame.auraEventFrame then
            frame.auraEventFrame = CreateFrame("Frame")
            frame.auraEventFrame:SetScript("OnEvent", function(self, event, unit, unitAuraUpdateInfo)
                -- CRITICAL: Only process events for the frame's specific unit
                -- Do NOT process events for other units (like raid/party pets) as they're handled by CompactUnitFrames
                if event == "PLAYER_ENTERING_WORLD" then
                    -- After login/reload, C_UnitAuras slot batching can be empty until the next UNIT_AURA;
                    -- force full refresh + staggered retries when our unit exists (e.g. target already selected).
                    local u = frame.unit
                    if u and UnitExists(u) then
                        local function doRefresh()
                            CancelAuraDebounce(frame)
                            frame._fluxAuraLastRefresh = GetTime()
                            RefreshFrameAuras(frame, u)
                        end
                        doRefresh()
                        if C_Timer and C_Timer.After then
                            for _, delay in ipairs({ 0.1, 0.5 }) do
                                C_Timer.After(delay, function()
                                    if frame.unit == u and UnitExists(u) then
                                        doRefresh()
                                    end
                                end)
                            end
                        end
                    end
                elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
                    local u = frame.unit
                    if UF.FrameUsesEngineAuras and UF.FrameUsesEngineAuras(frame) then
                        if frame.BuffContainer and UF.PokeEngineAuras then
                            UF.PokeEngineAuras(frame.BuffContainer, frame)
                        end
                        if frame.DebuffContainer and UF.PokeEngineAuras then
                            UF.PokeEngineAuras(frame.DebuffContainer, frame)
                        end
                    elseif u and UnitExists(u) then
                        RequestAuraRefreshThrottled(frame, u)
                    end
                elseif event == "UNIT_AURA" then
                    if UF.FrameUsesEngineAuras and UF.FrameUsesEngineAuras(frame) then
                        if unit and unit == frame.unit then
                            if frame.BuffContainer and UF.PokeEngineAuras then
                                UF.PokeEngineAuras(frame.BuffContainer, frame)
                            end
                            if frame.DebuffContainer and UF.PokeEngineAuras then
                                UF.PokeEngineAuras(frame.DebuffContainer, frame)
                            end
                        end
                        return
                    end
                    if unit and unit == frame.unit and UnitExists(unit) then
                        -- Skip empty non-full payloads when the diff is readable.
                        -- Secret isFullUpdate / addedAuras cannot be if-tested or #-measured.
                        local Secrets = ns.Flux and ns.Flux.Secrets
                        if HAS_UNIT_AURA_DIFF_PAYLOAD
                            and Secrets
                            and Secrets.AuraUpdateInfoIsNoop
                            and Secrets.AuraUpdateInfoIsNoop(unitAuraUpdateInfo)
                        then
                            return
                        end
                        RequestAuraRefreshThrottled(frame, unit)
                    end
                elseif event == "PLAYER_REGEN_ENABLED" then
                    C_Timer.After(0.5, function()
                        local u = frame.unit
                        if not u or not UnitExists(u) then return end
                        CancelAuraDebounce(frame)
                        frame._fluxAuraLastRefresh = GetTime()
                        RefreshFrameAuras(frame, u)
                    end)
                elseif event == "PLAYER_REGEN_DISABLED" then
                    C_Timer.After(0.05, function()
                        local u = frame.unit
                        if not u or not UnitExists(u) then return end
                        CancelAuraDebounce(frame)
                        frame._fluxAuraLastRefresh = GetTime()
                        RefreshFrameAuras(frame, u)
                    end)
                end
            end)
        end

        frame.auraEventFrame:RegisterUnitEvent("UNIT_AURA", frame.unit)
        frame.auraEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame.auraEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Left combat
        frame.auraEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entered combat
        if frame.unit == "target" then
            frame.auraEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        elseif frame.unit == "focus" then
            frame.auraEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
        end
    else
        auraCache[frame] = nil
        CancelAuraDebounce(frame)
        frame._fluxAuraLastRefresh = nil
        if frame.auraEventFrame then
            frame.auraEventFrame:UnregisterEvent("UNIT_AURA")
            frame.auraEventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
            frame.auraEventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
            frame.auraEventFrame:UnregisterEvent("PLAYER_REGEN_DISABLED")
            frame.auraEventFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
            frame.auraEventFrame:UnregisterEvent("PLAYER_FOCUS_CHANGED")
        end
        if not next(auraCache) then
            StopAuraUpdates()
        end
    end
end

-- Disable auras function
function UF.DisableAuras(frame)
    UF.EnableAuras(frame, false, false)
end

-- Force aura update
function UF.UpdateAuras(frame)
    if frame and frame.unit then
        CancelAuraDebounce(frame)
        frame._fluxAuraLastRefresh = GetTime()
        RefreshFrameAuras(frame, frame.unit)
    end
end

-- Cleanup function (call on logout/reload)
function UF.CleanupAuras()
    for fr in pairs(auraCache) do
        CancelAuraDebounce(fr)
    end
    StopAuraUpdates()
    auraCache = {}
end

-- Register cleanup on logout
local cleanupFrame = CreateFrame("Frame")
cleanupFrame:RegisterEvent("PLAYER_LOGOUT")
cleanupFrame:SetScript("OnEvent", function()
    UF.CleanupAuras()
end)

-- Login/reload: C_UnitAuras is often stale on first paint; refresh all frames that use Flux auras (target, etc.).
local function FluxRefreshAllEnabledUnitAuras()
    for fr in pairs(auraCache) do
        if fr and fr.unit and UF.UpdateAuras then
            UF.UpdateAuras(fr)
        end
    end
    if ns.TargetFrame and UF.UpdateAuras then
        UF.UpdateAuras(ns.TargetFrame)
    end
    if ns.FocusFrame and UF.UpdateAuras then
        UF.UpdateAuras(ns.FocusFrame)
    end
end

local function FluxRefreshAuraLayoutsAfterScaleChange()
    if InCombatLockdown and InCombatLockdown() then
        if _G.Flux and _G.Flux.Combat and _G.Flux.Combat.Defer then
            _G.Flux.Combat.Defer("layout.aura.squeeze", FluxRefreshAuraLayoutsAfterScaleChange)
        end
        return
    end
    if FluxUILayoutSqueeze and FluxUILayoutSqueeze.InvalidateEmulatedDependentCache then
        FluxUILayoutSqueeze.InvalidateEmulatedDependentCache()
    end
    for fr in pairs(auraCache) do
        if fr and fr.unit then
            RefreshBorderedAuraLayoutsForFrame(fr)
            UF.UpdateAuras(fr)
        end
    end
    if ns.TargetFrame and ns.TargetFrame.unit then
        RefreshBorderedAuraLayoutsForFrame(ns.TargetFrame)
        UF.UpdateAuras(ns.TargetFrame)
    end
    if ns.FocusFrame and ns.FocusFrame.unit then
        RefreshBorderedAuraLayoutsForFrame(ns.FocusFrame)
        if UF.UpdateAuraPosition then
            UF.UpdateAuraPosition(ns.FocusFrame)
        else
            UF.UpdateAuras(ns.FocusFrame)
        end
    end
    if _G.FluxUIPositionFocusFrameDefault and FluxUnitFrames_GetPlayerTargetPlacement
        and FluxUnitFrames_GetPlayerTargetPlacement() == 2 then
        _G.FluxUIPositionFocusFrameDefault()
    end
end

_G.FluxUnitFrames_RefreshAuraLayoutsAfterSqueeze = FluxRefreshAuraLayoutsAfterScaleChange

local fluxAuraWorldRefresh = CreateFrame("Frame")
fluxAuraWorldRefresh:RegisterEvent("PLAYER_LOGIN")
fluxAuraWorldRefresh:RegisterEvent("PLAYER_ENTERING_WORLD")
fluxAuraWorldRefresh:RegisterEvent("UI_SCALE_CHANGED")
fluxAuraWorldRefresh:RegisterEvent("DISPLAY_SIZE_CHANGED")
fluxAuraWorldRefresh:SetScript("OnEvent", function(_, event)
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        FluxRefreshAuraLayoutsAfterScaleChange()
        return
    end
    FluxRefreshAllEnabledUnitAuras()
    if C_Timer and C_Timer.After then
        for _, delay in ipairs({ 0.1, 0.5 }) do
            C_Timer.After(delay, FluxRefreshAllEnabledUnitAuras)
        end
        C_Timer.After(0, FluxRefreshAuraLayoutsAfterScaleChange)
        C_Timer.After(0.05, FluxRefreshAuraLayoutsAfterScaleChange)
    end
end)

