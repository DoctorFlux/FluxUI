local _, ns = ...
local UF = ns.UnitFrames

local units = {
    player = { portrait = "LEFT", padding = 36, width = 325, height = 100, health = 1527, power = 3024 },
    target = { portrait = "RIGHT", padding = 36, width = 325, height = 100, health = 8727, npc = true },
    focus = { portrait = "RIGHT", padding = 25, width = 119, height = 50, health = 4100, power = 2700, class = "PRIEST" },
    pet = { portrait = "RIGHT", padding = 0, width = 100, height = 50, health = 1610, power = 100 },
    targettarget = { padding = 20, width = 70, height = 26, health = 2700, power = 100, class = "WARRIOR" },
    focustarget = { width = 30, height = 85, health = 1800, class = "PRIEST" },
    pettarget = { width = 23, height = 50, health = 1700, npc = true },
}

local attachedUnits = {
    player = { unit = "pet", option = "useFluxPet" },
    target = { unit = "targettarget", option = "useFluxTargetOfTarget" },
    focus = { unit = "focustarget", option = "useFluxFocusTarget" },
    pet = { unit = "pettarget", option = "useFluxPetTarget" },
}

local fallbackNames = {
    target = "Target", focus = "Focus", pet = "Pet",
    targettarget = "Target of Target", focustarget = "Focus Target", pettarget = "Pet Target",
}

local scenarioStyles = {
    friendlyNPC = {
        name = "Quartermaster", color = { r = .13, g = 1, b = .13 },
        displayId = 49, texture = "Interface\\Icons\\INV_Misc_Head_Human_01",
    },
    hostileNPC = {
        name = "Hostile Guard", color = { r = 1, g = .15, b = .15 },
        displayId = 51, texture = "Interface\\Icons\\INV_Misc_Head_Orc_01",
    },
}

local function PortraitEnabled(unit)
    return units[unit].portrait and (not FluxUnitFrames_ShouldShowPortrait or FluxUnitFrames_ShouldShowPortrait(unit))
end

local function SizeForUnit(unit, compactFocus, raidDB)
    local spec = units[unit]
    local width, height = FluxUnitFrames_GetConfiguredFrameSize(unit)
    if unit == "pettarget" then
        local _, petHeight = FluxUnitFrames_GetConfiguredFrameSize("pet")
        width, height = FluxUnitFrames_GetConfiguredPetTargetBarWidth(), petHeight or units.pet.height
    elseif unit == "focustarget" then
        local focusWidth, focusHeight = FluxUnitFrames_GetConfiguredFrameSize("focus")
        focusWidth, focusHeight = focusWidth or units.focus.width, focusHeight or units.focus.height
        if compactFocus then
            width, height = tonumber(raidDB.partyTargetWidth) or 30, focusHeight + 36
        else
            width = focusWidth + (PortraitEnabled("focus") and focusHeight + 2 or 0)
            height = UF.GetFluxStylePartitionHealthHeight(focusHeight, "focus") + 4
        end
    end
    return width or spec.width, height or spec.height
end

local function ScaleForUnit(unit, compactFocus)
    local owner = unit == "pet" or unit == "pettarget"
    local scale = FluxUnitFrames_GetWholeFrameScale(owner and "player" or unit)
    if compactFocus and (unit == "focus" or unit == "focustarget") then
        scale = scale * FluxUnitFrames_GetFocusPresentationScale()
    end
    return scale
end

local function SampleForUnit(unit, scenario)
    local spec, api = units[unit], ns.API
    local label = api and api.SafeAccessibleString and UnitName and api.SafeAccessibleString(UnitName(unit))
    local level = api and api.SafeGetNumber and UnitLevel and api.SafeGetNumber(UnitLevel(unit), 42) or 42
    local colors = RAID_CLASS_COLORS
    local color = spec.class and colors and colors[spec.class]
    local powerType, powerToken = 0, "MANA"
    if unit == "player" and UnitPowerType and api and api.SafeGetNumber and api.SafeAccessibleString then
        local currentType, currentToken = UnitPowerType("player")
        powerType = api.SafeGetNumber(currentType, 0)
        powerToken = api.SafeAccessibleString(currentToken) or "MANA"
    elseif unit == "pet" then
        powerType, powerToken = 2, "FOCUS"
    elseif unit == "targettarget" then
        powerType, powerToken = 1, "RAGE"
    end
    local sample = {
        name = label or fallbackNames[unit],
        portraitUnit = unit,
        npc = spec.npc,
        classColor = color,
        classToken = spec.class,
        nameColor = unit == "target" and { r = 0.13, g = 1, b = .13 } or nil,
        maxHealth = spec.health,
        health = unit == "pettarget" and 1450 or spec.health,
        maxPower = spec.power or 0,
        power = spec.power or 0,
        powerType = powerType,
        powerToken = powerToken,
        level = level > 0 and level or 42,
    }
    local npc = scenarioStyles[scenario]
    if npc then
        sample.name, sample.nameColor, sample.npc = npc.name, npc.color, true
        sample.portraitUnit, sample.portraitDisplayId, sample.portraitTexture = nil, npc.displayId, npc.texture
        sample.classColor, sample.classToken = nil, nil
        sample.maxPower, sample.power = 0, 0
    elseif scenario == "player" then
        local class = UnitClass and api.SafeAccessibleString(select(2, UnitClass("player"))) or "MAGE"
        sample.name = UnitName and api.SafeAccessibleString(UnitName("player")) or PLAYER or "Player"
        sample.nameColor, sample.classColor, sample.classToken = nil, colors and colors[class], class
        sample.portraitUnit, sample.npc = "player", false
        sample.level = UnitLevel and api.SafeGetNumber(UnitLevel("player"), 42) or 42
        sample.powerType, sample.powerToken = 0, "MANA"
        sample.maxPower = spec.power or 3100
        sample.power = sample.maxPower
    end
    if unit == "player" and IsResting and api then
        local resting = IsResting()
        sample.resting = not api.IsSecretValue(resting) and api.CanAccessValue(resting) and resting or false
    end
    return sample
end

local function CreateBody(parent, content, unit, context, sample)
    local vertical = unit == "pettarget" or (unit == "focustarget" and context.compactFocus)
    local frame = UF.CreateBaseFrame(unit, parent, context.width, context.height, unit == "focustarget" and 2 or nil, {
        individualPreview = true,
        previewLayerParent = content,
        previewColor = sample.classColor,
        previewNpc = sample.npc,
        previewPortraitUnit = sample.portraitUnit,
    })
    frame._fluxHealthBarOnly = unit == "focustarget" or unit == "pettarget"
    frame._fluxCompactFocus = unit == "focus" and context.compactFocus
    frame._fluxVerticalFocusTarget = unit == "focustarget" and context.compactFocus
    frame.portraitPosition = (unit == "focus" and context.compactFocus) and "LEFT" or units[unit].portrait
    if unit == "focustarget" then frame.barAreaLeft, frame.barAreaRight = 2, -2 end
    if unit == "pettarget" then
        local health = CreateFrame("StatusBar", nil, frame)
        UF.ConfigureVerticalTargetHealth(frame, health, true)
    else
        UF.CreateHealthBar(frame)
        if vertical then UF.ConfigureVerticalTargetHealth(frame, frame.Health, true) end
        UF.CreatePowerBar(frame)
        if frame.portraitPosition and context.portrait then UF.CreatePortrait(frame) end
        if not vertical then UF.CreateAtlasBorder(frame, unit == "focustarget" and 2 or nil) end
        if units[unit].padding then UF.CreateOuterBorder(frame) end
        if frame._fluxCompactFocus and ns.PartyFrames.SetupFocusPresentation then
            ns.PartyFrames.SetupFocusPresentation(frame)
        end
    end
    return frame
end

local function LayoutBody(frame, context)
    local unit = frame.unit
    local alignment = unit == "target" and not context.sideBySide and "TOP" or "BOTTOM"
    local padding = (unit == "focus" and context.compactFocus) and 36 or units[unit].padding
    if context.nested and unit == "targettarget" then padding = 0 end
    local powerHeight = unit == "focus" and context.powerHeight or nil
    local textScaleChanged = frame._fluxCompactFocus and frame._fluxOptionsPartyTextScale ~= context.partyTextScale
    local changed = frame:GetScale() ~= context.scale
        or frame._fluxLayoutBaseWidth ~= context.width or frame._fluxOptionsHeight ~= context.height
        or frame._fluxPortraitDisabled ~= (not context.portrait) or frame.outerBorderAlignment ~= alignment
        or frame.outerBorderPadding ~= padding or frame._fluxPartyPowerHeightScale ~= powerHeight
        or frame._fluxOptionsPartition ~= context.partition

    frame._fluxCompactFocus = unit == "focus" and context.compactFocus
    frame._fluxFocusAuraPanelScale = frame._fluxCompactFocus and (1 / context.focusScale) or nil
    frame.auraFrameAboveUnit = unit == "focus" or (unit == "target" and context.sideBySide)
    frame.outerBorderAlignment, frame.outerBorderPadding = alignment, padding
    frame._fluxPreviewHideUnitName = context.nested and unit == "targettarget"
    frame._fluxPartyPowerHeightScale = powerHeight
    frame._fluxPortraitDisabled = not context.portrait
    frame._fluxOptionsPartition = context.partition
    frame._fluxOptionsPartyTextScale = context.partyTextScale
    if context.portrait and not frame.PortraitFrame then UF.CreatePortrait(frame) end
    if frame.PortraitFrame then frame.PortraitFrame:SetShown(context.portrait) end

    if changed then
        frame:SetScale(context.scale)
        frame._fluxLayoutBaseWidth, frame._fluxOptionsHeight = context.width, context.height
        UF.RecordFrameDimensions(frame, context.width, context.height)
        frame:SetSize(context.width, context.height)
        frame:UpdatePartition()
    end
    if frame._fluxPartyIndicatorLayer and (changed or textScaleChanged) then
        ns.PartyFrames.LayoutFocusPresentation(frame)
    end
    local contentScale = frame._fluxPreviewLayerParent:GetEffectiveScale()
    if contentScale > 0 then
        local relativeScale = frame:GetEffectiveScale() / contentScale
        if frame.atlasBorderFrame and frame.atlasBorderFrame:GetScale() ~= relativeScale then
            frame.atlasBorderFrame:SetScale(relativeScale)
        end
        if frame.SeparatorContainer and frame.SeparatorContainer:GetScale() ~= relativeScale then
            frame.SeparatorContainer:SetScale(relativeScale)
        end
    end
end

local function ConfigureBody(frame, content, parent, unit, context, sample)
    if not frame then frame = CreateBody(parent, content, unit, context, sample) end
    frame:Show()
    LayoutBody(frame, context)
    UF.PaintIndividualPreview(frame, sample)
    return frame
end

local function NewContext(unit, db, raidDB, placement)
    local compactFocus = ns.PartyFrames ~= nil
    local width, height = SizeForUnit(unit, compactFocus, raidDB)
    local sideBySide = placement == 2 and db.useFluxPlayer ~= false and db.useFluxTarget ~= false
    local partition = FluxUnitFrames_GetHealthPartitionPct and FluxUnitFrames_GetHealthPartitionPct(unit)
    return {
        width = width,
        height = height,
        scale = ScaleForUnit(unit, compactFocus),
        portrait = not not PortraitEnabled(unit),
        sideBySide = sideBySide,
        compactFocus = compactFocus,
        focusScale = FluxUnitFrames_GetFocusPresentationScale(),
        powerHeight = math.max(.5, math.min(1.5, tonumber(raidDB.partyPowerHeightScale) or .8)),
        partyTextScale = tonumber(raidDB.partyTextScale) or 1,
        partition = partition,
    }
end

local function AnchorAttached(frame, owner, context)
    local unit = frame.unit
    local chrome = owner.outerBorderFrame or owner
    frame:ClearAllPoints()
    if unit == "pet" or (unit == "targettarget" and context.nested) then
        local side = unit == "pet" and "Left" or "Right"
        local point = "TOP" .. string.upper(side)
        local y = -2 - math.max(10, owner:GetHeight() - 8) / 2 + context.height / 2
        frame:SetPoint(point, owner, point, 0, y)
        UF.FitPortraitOverlay(frame, owner, side)
    elseif unit == "targettarget" then
        frame:SetPoint("TOPLEFT", chrome, "BOTTOMRIGHT", 0, -12)
        UF.FitPortraitOverlay(frame, owner, false)
    elseif unit == "focustarget" and not context.compactFocus then
        frame:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, 6)
    else
        frame:SetPoint("TOPLEFT", chrome, "TOPRIGHT")
    end
end

local function GetAttachedSpec(unit, db, selectedPart)
    local spec = attachedUnits[unit]
    if not spec or db[spec.option] == false then return end
    local selected = selectedPart == "attached" or (unit == "player" and selectedPart == "extras")
    if selected then return spec end
    local exists = UnitExists(spec.unit)
    if ns.API.IsSecretValue(exists) or not ns.API.CanAccessValue(exists) then return end
    if exists then return spec end
end

local function RenderAttached(scene, owner, db, raidDB, placement, spec)
    local old = owner._fluxOptionsAttached
    if not spec then
        if old then old:Hide() end
        return
    end
    local unit = spec.unit
    local context = NewContext(unit, db, raidDB, placement)
    context.nested = unit == "pet" or (unit == "targettarget" and context.sideBySide)
    context.scale = context.nested and 1 or context.scale / owner:GetScale()
    local sample = SampleForUnit(unit)
    local frame = ConfigureBody(old, scene.content, owner, unit, context, sample)
    owner._fluxOptionsAttached = frame
    AnchorAttached(frame, owner, context)
    return frame, sample
end

local function AddBounds(bounds, region, originX, originY, rootScale)
    if not region or not region:IsShown() then return end
    local scale = region:GetEffectiveScale() / rootScale
    local left, bottom, width, height = region:GetRect()
    if not left or not bottom or not width or not height then return end
    bounds.left = math.min(bounds.left, left * scale - originX)
    bounds.right = math.max(bounds.right, (left + width) * scale - originX)
    bounds.bottom = math.min(bounds.bottom, bottom * scale - originY)
    bounds.top = math.max(bounds.top, (bottom + height) * scale - originY)
end

local function PaintClassResource(frame, shown)
    if frame.unit ~= "player" then return end
    local row = frame._fluxOptionsClassResource
    if not shown or (FluxUnitFrames_ShouldShowClassPower and not FluxUnitFrames_ShouldShowClassPower()) then
        if row then row:Hide() end
        return
    end
    if not row then
        row = CreateFrame("Frame", nil, frame)
        row:SetSize(94, 18)
        row:SetPoint("BOTTOM", frame.outerBorderFrame or frame, "TOP", 0, 4)
        row:SetFrameLevel(frame:GetFrameLevel() + 36)
        local getAtlasInfo = C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo
        local comboAtlas = getAtlasInfo and getAtlasInfo("uf-roguecp-icon-red")
        row.resourcePoints = {}
        for i = 1, 5 do
            local point = row:CreateTexture(nil, "ARTWORK")
            point:SetSize(18, 18)
            point:SetPoint("LEFT", row, "LEFT", (i - 1) * 19, 0)
            if comboAtlas then point:SetAtlas("uf-roguecp-icon-red", false)
            else point:SetTexture("Interface\\Icons\\Ability_Rogue_Eviscerate") end
            point:SetAlpha(i <= 3 and 1 or .30)
            row.resourcePoints[i] = point
        end
        frame._fluxOptionsClassResource = row
    end
    local scale = FluxUnitFrames_GetClassPowerScale and FluxUnitFrames_GetClassPowerScale() or 1
    if row:GetScale() ~= scale then row:SetScale(scale) end
    row:Show()
    return row
end

local function FitScene(scene)
    local content, root, body = scene.content, scene.frame, scene.body
    local x, y = content:GetCenter()
    if not x or not y then return end
    local scale = content:GetEffectiveScale()
    local bounds = { left = math.huge, right = -math.huge, bottom = math.huge, top = -math.huge }
    AddBounds(bounds, body.outerBorderFrame or body, x, y, scale)
    AddBounds(bounds, body.BuffContainer, x, y, scale)
    AddBounds(bounds, body.DebuffContainer, x, y, scale)
    AddBounds(bounds, scene.parts.auras, x, y, scale)
    AddBounds(bounds, scene.parts.classResource, x, y, scale)
    local child = scene.attached
    if child then AddBounds(bounds, child.outerBorderFrame or child, x, y, scale) end
    if scene.cast then
        AddBounds(bounds, scene.cast, x, y, scale)
        AddBounds(bounds, scene.cast.IconFrame, x, y, scale)
    end
    local width, height = bounds.right - bounds.left, bounds.top - bounds.bottom
    if width <= 0 or height <= 0 then return end
    local padding = 14
    local fit = math.min(1, (scene.width - 2 * padding) / width, (scene.height - 2 * padding) / height)
    fit = math.max(.05, fit)
    local offsetX, offsetY = -(bounds.left + bounds.right) / 2, -padding / fit - bounds.top
    if math.abs(content:GetScale() - fit) > .001 then content:SetScale(fit) end
    if not scene.offsetX or math.abs(scene.offsetX - offsetX) > .05 or math.abs(scene.offsetY - offsetY) > .05 then
        scene.offsetX, scene.offsetY = offsetX, offsetY
        content:ClearAllPoints()
        content:SetPoint("CENTER", root, "TOP", offsetX, offsetY)
    end
end

local function GetParts(body, child)
    return {
        layout = body.outerBorderFrame or body,
        name = body.nameText and { body.nameText, body.levelText, body.petNameText } or nil,
        health = body.Health,
        power = body._fluxHasMainPower ~= false and body.Power or nil,
        portrait = body.PortraitFrame,
        absorbs = { body.totalAbsorbBar, body.myHealPredictionBar, body.healAbsorbBar, body.verticalAbsorbBar,
            body.verticalHealAbsorbBar },
        indicators = { body.classIcon, body.specIcon, body.restIcon, body.combatIcon, body.raidIcon },
        buffs = body.BuffContainer,
        debuffs = body.DebuffContainer,
        attached = child and (child.outerBorderFrame or child) or nil,
    }
end

local Scene = {}

local function VisualMode(part)
    if part == "buffs" or part == "debuffs" then return "auras" end
    if part == "cast" or part == "health" or part == "power" or part == "absorbs" or part == "auras" or part == "attached"
        or part == "classResource" or part == "extras" or part == "indicators" then return part end
    return false
end

local function PaintClassResourceValues(row, progress)
    if not row then return end
    local charged = progress and math.min(5, 1 + math.floor(progress * 6)) or 3
    if charged == row._fluxOptionsCharged then return end
    row._fluxOptionsCharged = charged
    for i, point in ipairs(row.resourcePoints) do point:SetAlpha(i <= charged and 1 or .30) end
end

local function AnimateAll(scene)
    return scene.animationActive and (scene.scenario == "effects" or (not scene.mode and scene.scenario ~= "auras"))
end

local function SetEffectValues(sample, progress)
    local maxHealth = sample.maxHealth
    sample.heal = math.floor(maxHealth * (.06 + .05 * progress))
    sample.otherHeal = math.floor(maxHealth * .04)
    sample.absorb = math.floor(maxHealth * (.14 - .05 * progress))
    sample.healAbsorb = math.floor(maxHealth * .06)
end

local function SetIndicatorValues(unit, sample, progress)
    local secondHalf = progress and progress >= .5
    sample.inCombat, sample.resting = not secondHalf, secondHalf and unit == "player"
    sample.raidMarker = secondHalf and 4 or 8
end

local function PaintAnimation(scene, progress, elapsed)
    scene.animationProgress, scene.animationElapsed = progress, elapsed
    local body, sample, mode = scene.body, scene.sample, scene.mode
    local all = AnimateAll(scene)
    local impact = math.sin(progress * math.pi) ^ 2
    if all or mode == "health" or mode == "power" or mode == "absorbs" then
        if all or mode == "health" or mode == "absorbs" then
            sample.health = math.floor(sample.maxHealth * (.83 - .32 * impact))
        end
        if (all or mode == "power") and sample.maxPower > 0 then
            sample.power = math.floor(sample.maxPower * (.90 - .53 * impact))
        end
        if all or mode == "absorbs" then SetEffectValues(sample, impact) end
        UF.PaintIndividualPreviewValues(body, sample)
    end
    if scene.attached and (all or mode == "attached" or mode == "extras") then
        local childSample = scene.attachedSample
        childSample.health = math.floor(childSample.maxHealth * (.90 - .35 * impact))
        UF.PaintIndividualPreviewValues(scene.attached, childSample)
    end
    if (all or mode == "indicators") and sample.raidMarker == 8 and progress >= .5 then
        SetIndicatorValues(body.unit, sample, progress)
        UF.PaintIndividualPreview(body, sample)
    end
    local cast = scene.cast
    if cast and ns.CastBar.SetOptionsSampleProgress then
        ns.CastBar.SetOptionsSampleProgress(cast, progress)
    end
    if UF.PaintIndividualPreviewAuraValues then UF.PaintIndividualPreviewAuraValues(body, elapsed) end
    if UF.PaintOptionsPetAuraValues then UF.PaintOptionsPetAuraValues(body, elapsed) end
    PaintClassResourceValues(scene.parts.classResource, progress)
end

function Scene:PaintSelectedPart(part, bodyChanged)
    local body = self.body
    if not body then return end
    local mode = VisualMode(part)
    if not bodyChanged and self.mode == mode then return self.parts end
    self.mode, self.part = mode, part
    local unit, context, db = body.unit, self.context, self.db
    local sample = SampleForUnit(unit, self.scenario)
    self.sample = sample
    local all = AnimateAll(self)
    local attached = GetAttachedSpec(unit, db, part)
    sample.nested = attached and (unit == "player" or (unit == "target" and context.sideBySide))
    sample.secondaryName = sample.nested and SampleForUnit(attached.unit).name or nil
    local showPower = mode == "power" or (all and (self.scenario == "default" or self.scenario == "effects"))
    if showPower and sample.maxPower == 0 and not body._fluxHealthBarOnly then
        sample.maxPower, sample.power = 3100, 2387
    end
    if self.scenario == "effects" or mode == "absorbs" or all then
        sample.health = math.floor(sample.maxHealth * .63)
        SetEffectValues(sample, 0)
    end
    if all or self.scenario == "effects" or mode == "indicators" then
        SetIndicatorValues(unit, sample, self.animationProgress)
    end
    local showAuras = self.scenario == "auras" or mode == "auras" or all
    UF.PaintIndividualPreview(body, sample)
    self.attached, self.attachedSample = RenderAttached(self, body, db, self.raidDB, self.placement, attached)
    if UF.PaintIndividualPreviewAuras then
        local auraSettings = unit == "focus" and db.auraFocus or (unit == "target" and db.auraTarget)
        UF.PaintIndividualPreviewAuras(body, auraSettings, showAuras)
    end
    self.parts = GetParts(body, self.attached)
    self.parts.classResource = PaintClassResource(body, mode == "classResource" or all)
    PaintClassResourceValues(self.parts.classResource)
    if UF.PaintOptionsPetAuras then
        self.parts.auras = UF.PaintOptionsPetAuras(body, showAuras)
    end
    if ns.CastBar and ns.CastBar.PaintOptionsSample then
        local showCast = mode == "cast" or all
        if showCast or self.cast then
            self.cast = ns.CastBar.PaintOptionsSample(body, showCast, "Healing Wave")
        end
        self.parts.cast = self.cast and { self.cast, self.cast.IconFrame } or nil
    end
    if self.animationActive and self.animationProgress then
        PaintAnimation(self, self.animationProgress, self.animationElapsed)
    end
    FitScene(self)
    return self.parts
end

function Scene:SelectPart(part)
    if self.mode ~= VisualMode(part) then self:StopAnimation(true) end
    return self:PaintSelectedPart(part, false)
end

function Scene:Render(unit, width, height, db, placement, selectedPart, scenario)
    if not units[unit] then return end
    db = db or {}
    scenario = scenario or "default"
    placement = placement or FluxUnitFrames_GetPlayerTargetPlacement()
    local raidDB = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
    local context = NewContext(unit, db, raidDB, placement)
    self.frame:Show()
    self.width, self.height = width, height
    local previous = self.body
    if not previous or previous.unit ~= unit or self.scenario ~= scenario or self.mode ~= VisualMode(selectedPart) then
        self:StopAnimation(true)
    end
    if previous and previous.unit ~= unit then
        if self.cast then ns.CastBar.PaintOptionsSample(previous, false) end
        previous:Hide()
    end

    local body = self.bodies[unit]
    if not self.bodies[unit] then
        body = CreateBody(self.content, self.content, unit, context, SampleForUnit(unit, scenario))
        body:SetPoint("CENTER", self.content, "CENTER")
        self.bodies[unit] = body
    end
    body:Show()
    LayoutBody(body, context)
    self.body, self.scenario, self.context = body, scenario, context
    self.db, self.raidDB, self.placement = db, raidDB, placement
    return self:PaintSelectedPart(selectedPart, true)
end

function Scene:IsAnimating()
    return self.animationActive == true and self.frame:IsVisible()
end

function Scene:StopAnimation(skipPaint)
    if not self.animationActive then return self.parts end
    if UF.StopOptionsPreviewAnimation then UF.StopOptionsPreviewAnimation(self.frame) end
    self.animationActive, self.animationProgress, self.animationElapsed = nil, nil, nil
    if not skipPaint then return self:PaintSelectedPart(self.part, true) end
end

function Scene:PlayAnimation(onFinish)
    if not self.body or not self.frame:IsVisible() or not UF.PlayOptionsPreviewAnimation
        or not UF.PaintIndividualPreviewValues then return self.parts end
    self:StopAnimation(true)
    self.animationActive = true
    local parts = self:PaintSelectedPart(self.part, true)
    local started = UF.PlayOptionsPreviewAnimation(self.frame, function(progress, elapsed)
        PaintAnimation(self, progress, elapsed)
    end, function()
        local restored = self:StopAnimation()
        if onFinish then onFinish(restored) end
    end)
    if not started then return self:StopAnimation() end
    return parts
end

function Scene:Hide()
    self:StopAnimation(true)
    self.frame:Hide()
end

function UF.CreateOptionsPreview(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame:EnableMouse(false)
    local content = CreateFrame("Frame", nil, frame)
    content:SetSize(1, 1)
    content:SetPoint("CENTER", frame, "TOP")
    content:EnableMouse(false)
    local scene = setmetatable({ frame = frame, content = content, bodies = {} }, { __index = Scene })
    frame:SetScript("OnHide", function() scene:StopAnimation(true) end)
    return scene
end
