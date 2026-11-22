-- Desktop model of Blizzard nameplates and the published FluxUI overlays.
-- Native permissions, font metrics, layout and rendering require the clients.
local unpackValues = table.unpack or unpack
local checks = 0
local auraMedia = [[Interface\AddOns\_FluxUI\Texture\NameplateAuras\]]

local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

local clients = {
    { name = "Retail", isRetail = true, isLiveMidnight = true, majorVersion = 12 },
    { name = "Forever", isRetail = true, isForever = true, isCamelot = true, majorVersion = 1 },
    { name = "Mists", isAnyClassic = true, isClassic = true, majorVersion = 5 },
    { name = "Era", isAnyClassic = true, isClassicEra = true, majorVersion = 1 },
    { name = "Anniversary", isAnyClassic = true, isAnniversary = true, isTBC = true, majorVersion = 2 },
}

local function createFixture(client)
    local opaqueNumber, opaqueName = -40001, "opaque name sentinel"
    local function isOpaque(value) return value == opaqueNumber or value == opaqueName end
    local frames, units, calls = {}, {}, { worldQueries = 0, auraQueries = 0, healthQueries = 0, deniedWrites = 0 }
    local methods, widget = {}, nil

    function methods:GetParent() return self.parent end
    function methods:SetParent(parent) self.parent = parent end
    function methods:EnableMouse(enabled) self.mouse, self.mouseMotion, self.mouseClick = enabled, enabled, enabled end
    function methods:EnableMouseMotion(enabled) self.mouseMotion = enabled end
    function methods:SetMouseMotionEnabled(enabled) self.mouseMotion = enabled end
    function methods:SetMouseClickEnabled(enabled) self.mouseClick = enabled end
    function methods:IsObjectType(kind) return self.kind == kind end
    function methods:IsForbidden() return self.forbidden == true end
    function methods:IsProtected() return self.protected == true end
    function methods:CanBeAccessedInContext() return not self.forbidden end
    function methods:Show()
        if self.shown then return end
        self.shown = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:Hide()
        if not self.shown then return end
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:IsShown() return self.shown end
    function methods:IsVisible()
        return self.shown and (not self.parent or self.parent:IsVisible())
    end
    function methods:SetShown(shown)
        assert(type(shown) == "boolean", "show state must be a public boolean")
        if shown then self:Show() else self:Hide() end
    end
    function methods:SetAlpha(alpha)
        if self.forbidden then
            calls.deniedWrites = calls.deniedWrites + 1
            error("forbidden frame touched")
        end
        self.alpha = alpha
    end
    function methods:GetAlpha() return self.alpha end
    function methods:GetEffectiveAlpha()
        return self.alpha * (self.parent and self.parent:GetEffectiveAlpha() or 1)
    end
    function methods:SetScale(scale) self.scale = scale end
    function methods:GetScale() return self.scale end
    function methods:GetEffectiveScale() return self.scale end
    function methods:SetFrameLevel(level) self.frameLevel = level end
    function methods:GetFrameLevel() return self.frameLevel end
    function methods:GetName() return self.name end
    function methods:SetEnabled(enabled) self.enabled = enabled end
    function methods:SetSize(width, height) self.width, self.height = width, height end
    function methods:SetWidth(width) self.width = width end
    function methods:SetHeight(height) self.height = height end
    function methods:GetWidth() return self.width end
    function methods:GetHeight() return self.height end
    function methods:GetSize() return self.width, self.height end
    function methods:ClearAllPoints() self.points = {} end
    function methods:SetPoint(...)
        self.points[#self.points + 1] = { ... }
    end
    function methods:GetPoint(index)
        return unpackValues(self.points[index or 1] or {})
    end
    function methods:GetNumPoints() return #self.points end
    function methods:SetAllPoints(target)
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 0)
        self:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 0, 0)
    end

    function methods:CreateTexture(_, _, templateName, subLevel)
        assert(templateName == nil or type(templateName) == "string", "CreateTexture expects a template name in its third argument")
        assert(subLevel == nil or type(subLevel) == "number", "CreateTexture expects a numeric draw sublevel in its fourth argument")
        local region = widget("Texture", self)
        region.subLevel = subLevel
        self.regions[#self.regions + 1] = region
        return region
    end
    function methods:CreateLine()
        local region = widget("Line", self)
        self.regions[#self.regions + 1] = region
        return region
    end
    function methods:CreateFontString(_, _, template)
        local region = widget("FontString", self)
        if not template then region.font = nil end
        self.regions[#self.regions + 1] = region
        return region
    end
    function methods:GetRegions() return unpackValues(self.regions) end
    function methods:GetChildren()
        local children = {}
        for _, frame in ipairs(frames) do
            if frame.parent == self then children[#children + 1] = frame end
        end
        return unpackValues(children)
    end
    function methods:SetTexture(texture, wrapX, wrapY)
        self.texture, self.atlas, self.wrapX, self.wrapY = texture, nil, wrapX, wrapY
    end
    function methods:GetTexture() return self.texture end
    function methods:SetAtlas(atlas) self.texture, self.atlas = nil, atlas return true end
    function methods:GetAtlas() return self.atlas end
    methods.CreateMaskTexture = methods.CreateTexture
    function methods:AddMaskTexture(mask) self.mask = mask end
    function methods:SetBackdrop(backdrop) self.backdrop = backdrop end
    function methods:GetBackdrop() return self.backdrop end
    function methods:SetBackdropBorderColor(...) self.backdropBorderColor = { ... } end
    function methods:Clear() self.cooldown = nil end
    function methods:CreateAnimationGroup() return widget("AnimationGroup", self) end
    function methods:CreateAnimation() return widget("Animation", self) end
    function methods:Play() self.playing = true end
    function methods:Stop() self.playing = false end
    function methods:IsPlaying() return self.playing == true end
    function methods:SetColorTexture(...)
        self.flatColor = { ... }
        self.color = { ... }
    end
    function methods:SetVertexColor(red, green, blue, alpha) self.color = { red, green, blue, alpha or 1 } end
    function methods:GetVertexColor() return unpackValues(self.color) end
    function methods:SetTexCoord(...) self.texCoord = { ... } end
    function methods:GetTexCoord() return unpackValues(self.texCoord or {}) end
    function methods:SetTextColor(...) self.color = { ... } end
    function methods:GetTextColor() return unpackValues(self.color) end
    function methods:SetText(text)
        if self.kind == "FontString" and not self.font then error("FontString:SetText(): Font not set", 2) end
        self.text = text
    end
    function methods:GetText() return self.text end
    function methods:SetFormattedText(format, ...)
        local value = ...
        if isOpaque(value) then
            self.opaqueFormat = format
            self:SetText(value)
        else
            self:SetText(string.format(format, ...))
        end
    end
    function methods:GetStringWidth() return #(self.text or "") * (self.font[2] or 10) / 2 end
    function methods:SetFont(...) self.font = { ... } return true end
    function methods:GetFont() return unpackValues(self.font) end
    function methods:SetFontObject(font)
        self.font = font and font.font or { "Fonts\\FRIZQT__.TTF", 12, "OUTLINE" }
    end
    function methods:SetStatusBarTexture(texture) self.fill:SetTexture(texture) return true end
    function methods:GetStatusBarTexture() return self.fill end
    function methods:SetStatusBarColor(...) self.fill:SetVertexColor(...) end
    function methods:GetStatusBarColor() return self.fill:GetVertexColor() end
    function methods:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
    function methods:GetMinMaxValues() return self.minimum, self.maximum end
    function methods:SetValue(value) self.value = value end
    function methods:GetValue() return self.value end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:UnregisterEvent(event) self.events[event] = nil end
    function methods:UnregisterAllEvents() self.events = {} end
    function methods:RegisterUnitEvent(event, ...) self.events[event] = { ... } end
    function methods:SetScript(script, fn) self.scripts[script] = fn end
    function methods:GetScript(script) return self.scripts[script] end
    function methods:HookScript(script, callback)
        local previous = self.scripts[script]
        self.scripts[script] = function(...)
            if previous then previous(...) end
            callback(...)
        end
    end
    for _, name in ipairs({ "RegisterForClicks", "SetBlendMode", "SetClipsChildren", "SetDrawLayer", "SetFrameStrata", "SetHorizTile",
        "SetIgnoreParentAlpha", "SetJustifyH", "SetJustifyV", "SetRotation", "SetShadowColor",
        "SetShadowOffset", "SetTextHeight", "SetVertTile", "SetWordWrap",
        "SetBackdropColor", "SetDuration", "SetFromAlpha", "SetToAlpha", "SetOrder", "SetLooping",
        "SetOffset", "SetReverseFill", "SetSmoothing", "SetSwipeColor", "SetSwipeTexture", "SetDrawEdge", "SetDrawSwipe",
        "SetDrawBling", "SetHideCountdownNumbers", "SetCooldown", "SetScaleFactor", "SetIgnoreParentScale",
        "DisableDrawLayer", "EnableDrawLayer", "SetMaxLines", "SetSpacing", "SetDesaturated",
        "SetSnapToPixelGrid", "SetTexelSnappingBias", "SetThickness", "SetStartPoint", "SetEndPoint",
        "SetAlphaFromBoolean", "SetVertexColorFromBoolean",
        "SetReverse", "SetUseCircularEdge", "SetEdgeTexture", "SetEdgeScale" }) do
        methods[name] = function() end
    end

    widget = function(kind, parent)
        local object = setmetatable({ kind = kind, parent = parent, shown = true, text = "",
            color = { 1, 1, 1, 1 }, font = { "Fonts\\FRIZQT__.TTF", 12, "OUTLINE" },
            alpha = 1, scale = 1, frameLevel = 1, width = 0, height = 0, points = {}, regions = {},
            events = {}, scripts = {}, minimum = 0, maximum = 1, value = 1 }, { __index = methods })
        if kind == "StatusBar" then object.fill = object:CreateTexture() end
        if kind ~= "Texture" and kind ~= "FontString" and kind ~= "Line" then frames[#frames + 1] = object end
        return object
    end

    local ui, combat, target, now = widget("Frame"), false, nil, 100
    local saved = { nameplateThreat = { questOverlayEnabled = false, visibilityMode = "always" } }
    local env = setmetatable({ UIParent = ui, FluxUI_DB = saved, unpack = unpackValues }, { __index = _G })
    env._G = env
    env.issecretvalue = isOpaque
    env.canaccessvalue = function(v) return not isOpaque(v) end
    env.InCombatLockdown = function() return combat end
    env.GetTime = function() return now end
    env.geterrorhandler = function() return function(err) error(err, 0) end end
    env.strsplit = function(_, text) return text end
    env.wipe = function(t) for key in pairs(t) do t[key] = nil end end
    env.CreateFrame = function(kind, name, parent)
        local frame = widget(kind, parent)
        frame.name = name
        return frame
    end
    env.UnitExists = function(unit)
        if unit == "target" then unit = target end
        return units[unit] ~= nil
    end
    env.UnitName = function(unit) return units[unit] and units[unit].name end
    env.UnitHealth = function(unit)
        calls.healthQueries = calls.healthQueries + 1
        return units[unit].health
    end
    env.UnitHealthMax = function(unit) return units[unit].maximum end
    env.UnitHealthPercent = function(unit)
        local health, maximum = units[unit].health, units[unit].maximum
        if isOpaque(health) or isOpaque(maximum) then return opaqueNumber end
        return health / maximum
    end
    env.UnitGUID = function(unit) return units[unit] and units[unit].guid end
    env.UnitCanAttack = function(_, unit) return units[unit] and units[unit].enemy end
    env.UnitIsFriend = function(_, unit) return units[unit] and not units[unit].enemy end
    env.UnitReaction = function(_, unit) return units[unit] and (units[unit].enemy and 3 or 5) end
    env.UnitIsPlayer = function(unit) return units[unit] and units[unit].isPlayer == true end
    env.UnitPlayerControlled = env.UnitIsPlayer
    env.UnitInRaid = function() return nil end
    env.UnitIsTapDenied = function() return false end
    env.UnitClassification = function(unit) return units[unit] and units[unit].classification end
    env.UnitLevel = function(unit) return units[unit] and units[unit].level or 60 end
    env.IsInInstance = function() return false, "none" end
    env.UnitCastingInfo = function(unit)
        local cast = units[unit] and units[unit].casting
        if not cast then return end
        return cast, cast, 123456, 99500, 102500, false, 1, false, 133
    end
    env.C_UnitAuras = { GetAuraDataByIndex = function(unit, index, filter)
        calls.auraQueries = calls.auraQueries + 1
        local auras = units[unit] and units[unit].auras
        local lane = auras and auras[filter]
        return lane and lane[index]
    end }
    env.UnitIsUnit = function(left, right)
        if left == "target" then left = target end
        if right == "target" then right = target end
        return left == right
    end
    env.C_NamePlate = {
        GetNamePlateForUnit = function(unit, includeForbidden)
            assert(not includeForbidden, "addon asked for forbidden plates")
            calls.worldQueries = calls.worldQueries + 1
            if unit == "target" then unit = target end
            return units[unit] and units[unit].plate
        end,
        GetNamePlates = function()
            calls.worldQueries = calls.worldQueries + 1
            local result = {}
            for _, unit in pairs(units) do result[#result + 1] = unit.plate end
            return result
        end,
        SetNamePlateSize = function() error("nameplate painter changed the native click box") end,
    }
    local function makePlate(token, data)
        local plate = widget("Frame", ui)
        local unitFrame = widget("Button", plate)
        local healthRoot, castRoot = widget("Frame", unitFrame), widget("Frame", unitFrame)
        local healthBar, castBar = widget("StatusBar", healthRoot), widget("StatusBar", castRoot)
        unitFrame.name = unitFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        unitFrame.name:SetText(data.name)
        healthRoot.healthBar, castRoot.castBar = healthBar, castBar
        unitFrame.HealthBarsContainer, unitFrame.CastBarsContainer = healthRoot, castRoot
        unitFrame.AurasFrame, unitFrame.RaidTargetFrame = widget("Frame", unitFrame), widget("Frame", unitFrame)
        unitFrame.ClassificationFrame = widget("Frame", unitFrame)
        unitFrame.unit, plate.UnitFrame = token, unitFrame
        plate:SetSize(150, 30)
        healthRoot:SetSize(150, 14)
        healthBar:SetSize(150, 14)
        healthBar:SetMinMaxValues(0, data.maximum)
        healthBar:SetValue(data.health)
        unitFrame:SetAlpha(0.8)
        healthRoot:SetAlpha(0.7)
        unitFrame.name:SetAlpha(0.65)
        castBar:SetSize(150, 10)
        castBar:Hide()
        data.plate, units[token] = plate, data
        return plate, unitFrame, healthRoot, healthBar, castRoot, castBar
    end

    local function event(name, ...)
        for _, frame in ipairs(frames) do
            if frame.events[name] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, name, ...) end
        end
    end
    local function tick(elapsed)
        now = now + elapsed
        for _, frame in ipairs(frames) do
            if frame:IsVisible() and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, elapsed) end
        end
    end

    local ns = { Flux = { Client = client } }
    local function loadModule(path)
        if setfenv then
            setfenv(assert(loadfile(path)), env)("_FluxUI", ns)
        else
            assert(loadfile(path, "t", env))("_FluxUI", ns)
        end
    end
    return { env = env, ui = ui, ns = ns, calls = calls, frames = frames, saved = saved, units = units, widget = widget,
        opaqueNumber = opaqueNumber, opaqueName = opaqueName, event = event, tick = tick, makePlate = makePlate, loadModule = loadModule,
        setTarget = function(unit) target = unit end, setCombat = function(value) combat = value end }
end

local function checkPublishedRuntime(client)
    local fixture = createFixture(client)
    local env, ns = fixture.env, fixture.ns
    local token = "nameplate1"
    local auraID = 25
    local spellID = 589
    local nativeDebuff = { auraInstanceID = auraID, spellId = spellID, icon = 136207, sourceUnit = "pet", dispelName = "Magic" }
    local nativeCC = { auraInstanceID = 27, spellId = 118, sourceUnit = "player", dispelName = "Poison" }
    local nativeLOC = { auraInstanceID = 28, spellId = 408, sourceUnit = "party1", dispelName = "Bleed" }
    local nativeAuraReads = 0
    local publicAuraReady = false
    local canRead = env.canaccessvalue
    env.canaccessvalue = function(value)
        assert(value ~= nil, "native canaccessvalue requires a non-nil LuaValueReference")
        return canRead(value)
    end
    ns.Flux.Cap = { hasC_UnitAuras_GetAuraDataByAuraInstanceID = true }
    ns.Flux.Secrets = { CanAccessSecrets = function() return false end }
    env.C_UnitAuras.GetAuraDataByAuraInstanceID = function(unit, id)
        assert(unit == token)
        if id == nativeCC.auraInstanceID then return nativeCC end
        if id == nativeLOC.auraInstanceID then return nativeLOC end
        assert(id == auraID)
        nativeAuraReads = nativeAuraReads + 1
        return publicAuraReady and nativeDebuff or nil
    end
    env.hooksecurefunc = function(object, method, hook)
        local original = object[method]
        object[method] = function(...)
            original(...)
            hook(...)
        end
    end
    env.NamePlateAuraItemMixin = { SetAura = function(self, data)
        self.spellID = data.spellId
        self.Icon:SetTexture(data.icon or 136207)
        if not client.isForever then self.auraInstanceID = data.auraInstanceID end
    end }
    env.NamePlateAurasMixin = { RefreshList = function() end }
    fixture.loadModule("Core/API/Aura.lua")
    fixture.saved.nameplateAppearance = { width = 230, texture = "obsolete custom texture", enabled = true }
    fixture.saved.nameplateThreat.questOverlayEnabled = true
    env.NamePlateSetupOptions = { useClassicHealthBar = not client.isRetail }
    env.Enum = { TooltipDataLineType = { QuestTitle = 1, QuestObjective = 2 } }
    env.C_QuestLog = { GetQuestObjectives = function()
        return {
            { type = "monster", text = "Wolves slain", numFulfilled = 2, numRequired = 8 },
            { type = "item", text = "Wolf pelts", numFulfilled = 1, numRequired = 5 },
        }
    end }
    env.C_TooltipInfo = { GetUnit = function(unit)
        assert(unit == token)
        return { lines = {
            { type = 1, id = 100 },
            { type = 2, leftText = "Wolves slain" },
            { type = 2, leftText = "Wolf pelts" },
        } }
    end }
    local function readThreat() return 84, 1, false end
    ns.Flux.Threat = {
        IsVisibilityAllowed = function() return true end,
        GetNumericDisplay = readThreat,
        GetForeverFrameDisplay = readThreat,
        GetTintColor = function() return 1, .35, .25 end,
    }
    local plate, native, health, bar, castRoot, cast = fixture.makePlate(token, {
        name = "Forest Wolf", enemy = true, classification = "normal", level = 52,
        health = 1700, maximum = 2000, guid = "Creature-0-1-2-3-42-000A",
    })
    bar:SetStatusBarTexture("fixture-blizzard-health")
    cast:SetStatusBarTexture("fixture-blizzard-cast")
    cast:Show()
    native.selectionHighlight = native:CreateTexture()
    native.selectionHighlight:SetAlpha(.25)

    local auras = native.AurasFrame
    local auraList = fixture.widget("Frame", auras)
    local buffList = fixture.widget("Frame", auras)
    local ccList = fixture.widget("Frame", auras)
    local locLane = fixture.widget("Frame", auras)
    local function MakeAuraButton(lane, data)
        local button = fixture.widget("Frame", lane)
        button:SetSize(18, 18)
        button.Icon = button:CreateTexture()
        button.Icon:SetAllPoints(button)
        button.stockRim = button:CreateTexture()
        button.stockRim:SetAtlas("UI-HUD-CoolDownManager-IconOverlay")
        button.stockRim:SetAlpha(.55)
        button.otherRim = button:CreateTexture()
        button.otherRim:SetAtlas("fixture-third-party-overlay")
        button.otherRim:SetAlpha(.41)
        button.Icon:SetAlpha(.64)
        -- XML has already mixed these methods into the native frames before FluxUI's hooks ran.
        button.SetAura = env.NamePlateAuraItemMixin.SetAura
        button:SetAura(data)
        return button
    end
    local aura = MakeAuraButton(auraList, nativeDebuff)
    local ccAura = MakeAuraButton(ccList, nativeCC)
    local locAura = MakeAuraButton(locLane, nativeLOC)
    local buffAura = MakeAuraButton(buffList, { spellId = 1459, auraInstanceID = 35, isHelpful = true })
    local nativeHover = 0
    if not client.isForever then
        buffAura:SetScript("OnEnter", function() nativeHover = nativeHover + 1 end)
    end
    local gameTooltip = { shown = false, forbiddenAccesses = 0 }
    function gameTooltip:IsForbidden() return self.forbidden == true end
    function gameTooltip:IsShown() return self.shown end
    function gameTooltip:IsOwned(owner)
        if self.forbidden then self.forbiddenAccesses = self.forbiddenAccesses + 1 end
        return self.owner == owner
    end
    function gameTooltip:SetOwner(owner)
        if self.forbidden then self.forbiddenAccesses = self.forbiddenAccesses + 1 end
        self.owner = owner
    end
    function gameTooltip:GetOwner() return self.owner end
    function gameTooltip:SetSpellByID(spell) self.spell, self.shown = spell, true end
    function gameTooltip:Show() self.shown = true end
    function gameTooltip:Hide()
        if self.forbidden then self.forbiddenAccesses = self.forbiddenAccesses + 1 end
        self.owner, self.shown = nil, false
    end
    env.GameTooltip = gameTooltip
    local cooldown = fixture.widget("Cooldown", aura)
    local digits = cooldown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    digits:SetText("8")
    cooldown.GetCountdownFontString = function() return digits end
    auras.DebuffListFrame, auras.BuffListFrame, auras.CrowdControlListFrame = auraList, buffList, ccList
    auras.LossOfControlFrame, locLane.AuraItemFrame = locLane, locAura
    auras.unitToken, aura.Cooldown = token, cooldown
    auras.RefreshList = env.NamePlateAurasMixin.RefreshList
    auras.GetLossOfControlAura = function() return nativeLOC end
    locAura.Cooldown = fixture.widget("Cooldown", locAura)
    locAura.Cooldown.forbidden = true
    ccAura.GetParent = function() return fixture.opaqueName end
    ccAura.layoutIndex, ccList.maxAuraItemsDisplayed = 1, 2
    auras.crowdControlList = { Iterate = function(_, visit) visit(nativeCC.auraInstanceID, nativeCC) end }
    local filtered, firstAura
    local iterated = 0
    if client.isForever then
        filtered = { auraInstanceID = 23, spellId = spellID, sourceUnit = "party1", dispelName = "Poison" }
        local earlier = { auraInstanceID = 24, spellId = spellID, sourceUnit = "player", dispelName = "Curse" }
        local beyondLimit = { auraInstanceID = 26, spellId = spellID, sourceUnit = "player", dispelName = "Bleed" }
        firstAura = MakeAuraButton(auraList, earlier)
        firstAura.layoutIndex, firstAura.Cooldown = 1, fixture.widget("Cooldown", firstAura)
        auraList.requireSourceIsLocalPlayer, auraList.maxAuraItemsDisplayed = true, 2
        aura.layoutIndex = 2
        auras.debuffList = { Iterate = function(_, visit)
            for _, row in ipairs({ filtered, earlier, nativeDebuff, beyondLimit }) do
                iterated = iterated + 1
                if visit(row.auraInstanceID, row) then break end
            end
        end }
    end
    for _, file in ipairs({ "Core", "Threat", "Level", "Countdown" }) do
        fixture.loadModule("NamePlates/" .. file .. ".lua")
    end
    local plates = ns.Flux.NamePlates

    fixture.event("PLAYER_LOGIN")
    fixture.event("NAME_PLATE_UNIT_ADDED", token)
    local boundUnitFrame, boundPlate, boundHealth, boundBar = plates.GetParts(token)
    check(boundUnitFrame == native and boundPlate == plate and boundHealth == health and boundBar == bar
        and native:GetParent() == plate and health:GetAlpha() == .7 and native.name:GetAlpha() == .65,
        client.name .. " the published overlay path leaves Blizzard in charge of the native nameplate")
    check(plate:GetWidth() == 150 and bar:GetStatusBarTexture():GetTexture() == "fixture-blizzard-health"
        and cast:GetStatusBarTexture():GetTexture() == "fixture-blizzard-cast"
        and cast:GetParent() == castRoot and cast:IsShown() and cast:GetAlpha() == 1
        and native.AurasFrame:GetAlpha() == 1 and native.selectionHighlight:GetAlpha() == .25,
        client.name .. " restores native health, cast, selection and aura art without applying older custom settings")
    local function Artwork(atlas)
        for _, child in ipairs({ plate:GetChildren() }) do
            for _, texture in ipairs({ child:GetRegions() }) do
                if texture:GetAtlas() == atlas then return child, texture end
            end
        end
    end
    local function AnchoredTo(button)
        for _, child in ipairs({ plate:GetChildren() }) do
            local point, relative = child:GetPoint()
            if point == "TOPLEFT" and relative == button and select(2, child:GetPoint(2)) == button then
                for _, texture in ipairs({ child:GetRegions() }) do
                    if texture:GetTexture() == auraMedia .. "IconBorder.tga" then return child end
                end
            end
        end
    end
    local function BeveledBorder(host, red, green, blue)
        if not host or not host:IsShown() then return false end
        local count = 0
        for _, texture in ipairs({ host:GetRegions() }) do
            if texture:GetTexture() == auraMedia .. "IconBorder.tga" and texture:IsShown() then
                local r, g, b, alpha = texture:GetVertexColor()
                if r ~= red or g ~= green or b ~= blue or alpha ~= 1 then return false end
                if select(2, texture:GetPoint(1)) ~= host or select(2, texture:GetPoint(2)) ~= host then return false end
                count = count + 1
            end
        end
        return count == 1
    end
    local function CroppedStockImage(button)
        for _, child in ipairs({ plate:GetChildren() }) do
            if select(2, child:GetPoint()) == button then
                for _, texture in ipairs({ child:GetRegions() }) do
                    if texture.mask and texture.mask:GetTexture() == auraMedia .. "IconMask.tga" then
                        return texture, child
                    end
                end
            end
        end
    end
    local ccHost = Artwork("RaidFrame-Icon-DebuffPoison")
    check(ccHost and ccHost == AnchoredTo(ccAura) and BeveledBorder(ccHost, .45, .85, .38),
        client.name .. " decorates an enumerated native crowd-control icon with opaque parent access and no cooldown widget")
    local locHost = Artwork("RaidFrame-Icon-DebuffBleed")
    check(locHost and locHost == AnchoredTo(locAura) and BeveledBorder(locHost, .95, .32, .28),
        client.name .. " decorates the native loss-of-control icon even when cooldown access is denied")
    check(BeveledBorder(AnchoredTo(buffAura), .8, .6, .34),
        client.name .. " uses a bronze bevel on native helpful auras")
    ccList:Hide()
    locLane:Hide()
    plates.RefreshUnit(token)
    check(not ccHost:IsShown() and not locHost:IsShown(), client.name .. " hides borders when either native CC lane is hidden")
    if client.isForever then
        local magic, curse = Artwork("RaidFrame-Icon-DebuffMagic"), Artwork("RaidFrame-Icon-DebuffCurse")
        check(magic and curse and magic == AnchoredTo(aura) and curse == AnchoredTo(firstAura)
            and not ccHost:IsShown() and not locHost:IsShown() and iterated == 3,
            "Forever matches the exact visible rows and stops at the native display limit even when spell IDs repeat")
    else
        check(not Artwork("RaidFrame-Icon-DebuffMagic") and nativeAuraReads == 1,
            client.name .. " withholds the type glyph while the first public lookup is unavailable")
        check(BeveledBorder(AnchoredTo(aura), .95, .32, .28),
            client.name .. " draws a red border on a native debuff while the public type lookup is unavailable")
        publicAuraReady = true
        fixture.tick(.1)
        check(nativeAuraReads == 1, client.name .. " does not immediately repeat the failed query")
        fixture.tick(.31)
    end
    local dispelHost, glyph = Artwork("RaidFrame-Icon-DebuffMagic")
    local anchor, relative = glyph:GetPoint()
    check(anchor == "TOPRIGHT" and relative == dispelHost and dispelHost == AnchoredTo(aura)
        and BeveledBorder(dispelHost, .38, .65, 1) and aura:GetParent() == auraList,
        client.name .. " adds the corner type and colored border through a host outside the native aura")
    local stockImage, stockImageHost = CroppedStockImage(aura)
    local x, y = select(4, stockImage:GetPoint())
    local left, right, top, bottom = stockImage:GetTexCoord()
    check(stockImageHost:IsShown() and stockImageHost:GetFrameLevel() < dispelHost:GetFrameLevel()
        and x == aura:GetWidth() * 6 / 128 and y == -x
        and left == .08 and right == .92 and top == .08 and bottom == .92
        and stockImage:GetTexture() == nativeDebuff.icon,
        client.name .. " leases the visible native spell art under the new square mask and bezel")
    check(aura.Icon:GetAlpha() == 0 and aura.stockRim:GetAlpha() == 0 and aura.otherRim:GetAlpha() == .41
        and cooldown:GetAlpha() == 1 and cooldown:IsShown(),
        client.name .. " masks the native icon and known HUD rim while preserving the cooldown and foreign rim")
    fixture.tick(.1)
    check(nativeAuraReads == (client.isForever and 0 or 2), client.name .. " settles without repeated type lookups")
    if client.isForever then
        filtered.sourceUnit = fixture.opaqueName
        native.AurasFrame:RefreshList(auraList, native.AurasFrame.debuffList)
        fixture.tick(.31)
        check(BeveledBorder(dispelHost, .95, .32, .28) and not glyph:IsShown(),
            "Forever preserves the native harmful border without guessing when source eligibility becomes opaque")
        filtered.sourceUnit = "party1"
        native.AurasFrame:RefreshList(auraList, native.AurasFrame.debuffList)
        fixture.tick(.31)
        check(BeveledBorder(dispelHost, .38, .65, 1) and glyph:IsShown(),
            "Forever restores the typed decoration when the exact source order becomes readable")
    end
    local function ApplyAura(kind, helpful)
        nativeDebuff.dispelName = kind
        nativeDebuff.isHelpful = helpful
        aura:SetAura(nativeDebuff)
        local lane = helpful and buffList or auraList
        aura:SetParent(lane)
        native.AurasFrame:RefreshList(lane, native.AurasFrame.debuffList)
        plates.RefreshUnit(token)
    end
    ApplyAura(fixture.opaqueName, false)
    check(BeveledBorder(dispelHost, .95, .32, .28) and not glyph:IsShown(),
        client.name .. " replaces stale type art with a red border when the next debuff type is opaque")
    ApplyAura("Magic", true)
    check(BeveledBorder(AnchoredTo(aura), .8, .6, .34) and not glyph:IsShown(),
        client.name .. " a pooled helpful aura replaces its type border with the bronze bevel and clears the glyph")
    env.C_Texture = { GetAtlasInfo = function() return nil end }
    ApplyAura("Disease", false)
    check(dispelHost:IsShown() and glyph:GetTexture() == [[Interface\Icons\Spell_Nature_NullifyDisease]],
        client.name .. " a pooled aura reuses its host and a missing atlas uses the stock spell icon")
    ApplyAura(nil, false)
    check(BeveledBorder(dispelHost, .95, .32, .28) and not glyph:IsShown(),
        client.name .. " known harmful auras without a dispel type get only the red border")
    ApplyAura("Disease", false)
    aura:Hide()
    fixture.tick(.11)
    check(not dispelHost:IsShown(), client.name .. " the decoration hides with its native aura")
    check(aura.Icon:GetAlpha() == .64 and aura.stockRim:GetAlpha() == .55 and aura.otherRim:GetAlpha() == .41
        and not stockImageHost:IsShown(), client.name .. " restores both owned alpha leases on stock aura hide")
    aura:Show()
    nativeDebuff.icon = 135940
    ApplyAura("Disease", false)
    check(CroppedStockImage(aura) == stockImage and stockImage:GetTexture() == 135940,
        client.name .. " the reused icon stencil follows a newly assigned native texture")
    nativeDebuff.icon = fixture.opaqueName
    aura.Icon.GetTextureFileID = function() return 133676 end
    ApplyAura("Disease", false)
    check(stockImage:GetTexture() == 133676 and aura.Icon:GetAlpha() == 0,
        client.name .. " the stock mask uses a readable file ID when the texture query is opaque")
    nativeDebuff.icon = 135940
    ApplyAura("Disease", false)

    local function HoverProxy(button)
        for _, child in ipairs({ plate:GetChildren() }) do
            local _, relative = child:GetPoint()
            if (relative == button or relative == button.Icon) and child:GetScript("OnEnter") then
                return child
            end
        end
    end
    if client.isForever then
        local buffHover, debuffHover = HoverProxy(buffAura), HoverProxy(aura)
        check(buffHover and debuffHover and buffHover.mouseMotion and debuffHover.mouseMotion
            and buffHover.mouseClick == false and debuffHover.mouseClick == false,
            "Forever gives both stock aura rows owned hover targets that let clicks through")
        buffHover:GetScript("OnEnter")(buffHover)
        check(gameTooltip:IsOwned(buffHover) and gameTooltip:IsShown() and gameTooltip.spell == 1459,
            "Forever uses the displayed buff's readable spell for its tooltip")
        gameTooltip.forbidden = true
        buffHover:GetScript("OnLeave")(buffHover)
        debuffHover:GetScript("OnEnter")(debuffHover)
        check(gameTooltip.forbiddenAccesses == 0 and gameTooltip.owner == buffHover and gameTooltip.spell == 1459,
            "Forever skips ownership and visibility changes on a forbidden tooltip during hover and cleanup")
        gameTooltip.forbidden = false
        buffHover:GetScript("OnLeave")(buffHover)
        check(not gameTooltip:IsShown(), "Forever aura mouse leave closes its own tooltip")
        debuffHover:GetScript("OnEnter")(debuffHover)
        check(gameTooltip:IsOwned(debuffHover) and gameTooltip.spell == spellID,
            "Forever uses the displayed debuff's readable spell for its tooltip")
        gameTooltip:SetOwner(native)
        debuffHover:GetScript("OnLeave")(debuffHover)
        check(gameTooltip:IsOwned(native) and gameTooltip:IsShown(),
            "Forever aura mouse leave respects another tooltip owner")
        buffAura:SetAura({ spellId = fixture.opaqueNumber, auraInstanceID = 37, isHelpful = true })
        buffHover:GetScript("OnEnter")(buffHover)
        check(gameTooltip:IsOwned(native) and gameTooltip.spell == spellID,
            "Forever does not replace another tooltip with an unreadable aura assignment")
        buffAura:SetAura({ spellId = 133, auraInstanceID = 38, isHelpful = true })
        buffHover:GetScript("OnEnter")(buffHover)
        check(gameTooltip:IsOwned(buffHover) and gameTooltip.spell == 133,
            "Forever pooled hover reacquires the current readable spell")
        buffAura:Hide()
        fixture.tick(.11)
        check(not gameTooltip:IsShown(), "Forever a hidden native aura retires its hovered tooltip")
        buffAura:Show()
        fixture.tick(.11)
        buffHover:GetScript("OnEnter")(buffHover)
    else
        check(not HoverProxy(buffAura) and not HoverProxy(aura),
            client.name .. " does not overlay Blizzard's existing aura tooltip targets")
        buffAura:GetScript("OnEnter")(buffAura)
        check(nativeHover == 1, client.name .. " native aura mouseover scripts remain intact")
    end

    local threatBadge, threatText, auraText
    local questBadges = {}
    for _, child in ipairs({ plate:GetChildren() }) do
        if child:IsShown() then
            if child._fluxRole == "threat" then
                threatBadge = child
                for _, region in ipairs({ child:GetRegions() }) do
                    if region:IsObjectType("FontString") then threatText = region end
                end
            elseif child._fluxRole == "quest" then
                questBadges[child.text:GetText()] = child
            elseif type(child.text) == "table" and child.text:GetText() == "8" then
                auraText = child
            end
        end
    end
    check(threatText and threatText:GetText() == "84%" and select(2, threatBadge:GetPoint()) == health
        and questBadges["2/8"] and questBadges["1/5"] and select(2, questBadges["2/8"]:GetPoint()) == health,
        client.name .. " published threat, kill and loot overlays attach to the native health container")
    check(questBadges["2/8"].icon:GetTexture() == "Interface\\AddOns\\_FluxUI\\Texture\\QuestSlay.blp"
        and questBadges["1/5"].icon:GetTexture() == "Interface\\AddOns\\_FluxUI\\Texture\\QuestLoot.blp",
        client.name .. " quest badges keep the published FluxUI artwork")
    check(auraText and select(2, auraText:GetPoint()) == cooldown and select(3, auraText:GetPoint()) == "CENTER"
        and select(2, auraText.text:GetFont()) == 12 and select(4, digits:GetTextColor()) == 0,
        client.name .. " published native aura countdown defaults to centered 12 px text")
    local appearance = fixture.saved.nameplateAppearance
    appearance.auraCountdown, appearance.countdownSize = "below", 15
    plates.RefreshAll()
    check(auraText:IsShown() and auraText:GetPoint() == "TOP"
        and select(3, auraText:GetPoint()) == "BOTTOM" and select(2, auraText.text:GetFont()) == 15,
        client.name .. " explicit Flux options can move and resize the native countdown")
    appearance.auraCountdown = "bottom"
    plates.RefreshAll()
    local timerPoint, _, timerAnchor, _, timerY = auraText:GetPoint()
    check(timerPoint == "CENTER" and timerAnchor == "BOTTOM" and timerY == 8,
        client.name .. " bottom countdown placement uses the selected text size")
    appearance.auraCountdown = "none"
    plates.RefreshAll()
    check(not auraText:IsShown() and select(4, digits:GetTextColor()) == 0 and aura:IsShown()
        and dispelHost:IsShown() and glyph:IsShown(),
        client.name .. " turning off countdown numbers retains the native aura")
    aura.Icon:SetAlpha(.39)
    aura.stockRim:SetAlpha(.73)
    aura:Hide()
    fixture.event("NAME_PLATE_UNIT_REMOVED", token)
    check(not plates.activeUnits[token] and not threatBadge:IsShown() and not questBadges["2/8"]:IsShown(),
        client.name .. " native removal retires the attached Flux badges")
    check(aura.Icon:GetAlpha() == .39 and aura.stockRim:GetAlpha() == .73 and aura.otherRim:GetAlpha() == .41,
        client.name .. " ending an alpha lease preserves a newer write made by another owner")
    if client.isForever then
        check(not gameTooltip:IsShown(), "Forever plate removal closes a hovered stock aura tooltip")
    end
end

local function checkPreview(client)
    local fixture = createFixture(client)
    local env, ns = fixture.env, fixture.ns
    fixture.loadModule("Core/API/Aura.lua")
    local dropdowns, visits = {}, {}
    local native = { nameplateStyle = "2", nameplateSize = "2", nameplateShowEnemies = "1",
        nameplateOccludedAlphaMult = ".45" }
    env.GetCVar = function(key) return native[key] end
    env.SetCVar = function() error("preview changed a game setting") end
    env.C_Texture = { GetAtlasInfo = function() return {} end }
    env.UISpecialFrames = {}
    local nativeWidth, selectionAtlas = 206, "UI-HUD-Nameplates-Selected"
    if client.isForever then
        nativeWidth, selectionAtlas = 166, "UI-HUD-CoolDownManager-Selected-yellow"
        env.NamePlateConstants = { NAME_PLATE_WIDTH = 190, HORIZONTAL_INSET = 12,
            SELECTED_BORDER_ATLAS = selectionAtlas,
            SELECTED_BORDER_OFFSETS = { topLeftX = -3, topLeftY = 2, bottomRightX = 0, bottomRightY = 2 } }
    end
    ns.FluxOptionsWidgets = {
        Accent = function() return 1, .8, 0 end,
        Solid = function(texture, ...) texture:SetColorTexture(...) end,
        ShowTooltip = function() end,
        HideTooltip = function() end,
        CreateDropdown = function(parent)
            local item = fixture.widget("Button", parent)
            function item:SetLabel(label) self.label = label end
            function item:SetGetter(getter) self.getter = getter end
            function item:SetOnChange(apply) self.change = apply end
            dropdowns[#dropdowns + 1] = item
            return item
        end,
    }
    fixture.saved.nameplateThreat.questOverlayEnabled = true
    fixture.loadModule("NamePlates/Core.lua")
    local nameplateOptions, auraRefreshes = nil, 0
    env.FluxOptions = { RegisterModuleOptions = function(_, module, build)
        if module == "nameplates" then nameplateOptions = build().args end
    end }
    ns.FluxOptionsThreatVisibilityOption = function() return {} end
    local RefreshNameplates = env.FluxNamePlates_RefreshFromDB
    env.FluxNamePlates_RefreshFromDB = function()
        auraRefreshes = auraRefreshes + 1
        RefreshNameplates()
    end
    fixture.loadModule("AddonOptions/FluxOptionsNameplates.lua")
    fixture.loadModule("AddonOptions/FluxOptionsNameplatePreview.lua")
    fixture.event("ADDON_LOADED", "_FluxUI")
    local preview = ns.FluxOptionsNameplatePreview.Create(fixture.ui, function(part)
        visits[#visits + 1] = part
    end)
    preview:Update("ufNameplates", "style", "style")
    local sample, labels = assert(preview.sample), ns.FluxOptionsLocale
    check(sample.view.dimmer.subLevel == 1, client.name .. " the dimmer uses the texture draw sublevel")
    local debuff, buff = sample.view.auras[1], sample.view.auras[3]
    local function CheckPreviewAura(frame, red, green, blue)
        local image = frame.image
        local _, _, _, x, y = image:GetPoint()
        local left, right, top, bottom = image:GetTexCoord()
        check(image.mask and image.mask:GetTexture() == auraMedia .. "IconMask.tga"
            and x == frame:GetWidth() * 6 / 128 and y == -x
            and left == .08 and right == .92 and top == .08 and bottom == .92,
            client.name .. " preview crops and clips the spell art under the same aura bezel")
        for _, texture in ipairs({ frame:GetRegions() }) do
            if texture:GetTexture() == auraMedia .. "IconBorder.tga" and texture:IsShown() then
                local r, g, b = texture:GetVertexColor()
                check(r == red and g == green and b == blue,
                    client.name .. " preview tints the same border asset as the live aura row")
                return
            end
        end
        error(client.name .. " preview has no visible beveled aura border")
    end
    CheckPreviewAura(debuff, .38, .65, 1)
    CheckPreviewAura(buff, .8, .6, .34)
    check(debuff.dispelIcon:GetAtlas() == "RaidFrame-Icon-DebuffMagic" and not buff.dispelIcon,
        client.name .. " preview shows type details on debuffs only")
    check(sample.view:IsShown() and sample.view.cast:IsShown()
        and sample.holder:GetWidth() == nativeWidth and sample.holder:GetHeight() == 20,
        client.name .. " the Block Medium sample shows the Blizzard dimensions and a cast")
    check(sample.view.health:GetStatusBarTexture():GetAtlas() == "UI-HUD-CoolDownManager-Bar"
        and sample.view.cast:GetStatusBarTexture():GetAtlas() == "ui-castingbar-filling-standard"
        and sample.view.selection:GetAtlas() == selectionAtlas,
        client.name .. " modern preview paints Blizzard's health, selection and cast art")
    if client.isForever then
        local _, _, _, x, y = sample.view.selection:GetPoint(1)
        check(x == -3 and y == 2, client.name .. " the preview also uses Camelot's own selection offsets")
    end
    check(sample.quest:IsShown() and sample.loot:IsShown() and sample.view.auras[1]:IsShown(),
        client.name .. " the overview includes quest, loot and aura samples")
    sample.styleHit:GetScript("OnClick")(sample.styleHit)
    sample.castHit:GetScript("OnClick")(sample.castHit)
    sample.aurasHit:GetScript("OnClick")(sample.aurasHit)
    check(table.concat(visits, ",") == "style,cast,auras", client.name .. " preview parts link to their settings tabs")

    dropdowns[2].change("threat")
    check(sample.threat:IsShown() and not sample.view.cast:IsShown(),
        client.name .. " threat samples show the Flux badge on Blizzard chrome")
    preview:HoverSetting("questOverlayEnabled")
    check(sample.quest:IsShown() and not sample.threat:IsShown(), client.name .. " option hover can preview its overlay")
    preview:HoverSetting(nil)
    check(sample.threat:IsShown(), client.name .. " leaving a hovered option restores the selected preview state")
    preview:HoverSetting("target_occluded")
    check(sample.view:GetAlpha() == .45, client.name .. " the preview reads Blizzard's out-of-sight opacity")
    preview:HoverSetting(nil)
    dropdowns[2].change("overview")
    fixture.saved.nameplateAppearance = { auraCountdown = "below", countdownSize = 15 }
    preview:Update("ufNameplates", "auras", "auras")
    local timer = sample.view.auras[1].timer
    check(timer:IsShown() and timer:GetPoint() == "TOP" and select(3, timer:GetPoint()) == "BOTTOM"
        and select(2, timer:GetFont()) == 15, client.name .. " preview and world countdown settings share the saved placement and size")
    fixture.saved.nameplateAppearance.auraCountdown = "none"
    preview:Update("ufNameplates", "auras", "auras")
    check(not timer:IsShown() and sample.view.auras[1]:IsShown(), client.name .. " preview hides a disabled countdown without hiding its aura")
    local filter = assert(nameplateOptions.aura_onlyMine)
    local otherDebuff, crowdControl = sample.view.auras[2], sample.view.auras[4]
    check(filter.type == "toggle" and filter.get() == false and otherDebuff:IsShown()
        and fixture.saved.nameplateAppearance.onlyMyDebuffs == nil,
        client.name .. " caster filtering defaults to off and the sample shows another player's debuff")
    filter.set(nil, true)
    preview:Update("ufNameplates", "auras", "auras")
    check(filter.get() and fixture.saved.nameplateAppearance.onlyMyDebuffs == true and auraRefreshes == 1
        and debuff:IsShown() and not otherDebuff:IsShown() and buff:IsShown() and crowdControl:IsShown(),
        client.name .. " enabling caster filtering saves and refreshes while preserving own debuffs, buffs and own crowd control")
    filter.set(nil, false)
    preview:Update("ufNameplates", "auras", "auras")
    check(filter.get() == false and fixture.saved.nameplateAppearance.auraCountdown == "none" and auraRefreshes == 2
        and otherDebuff:IsShown(),
        client.name .. " disabling caster filtering restores the sample without changing the countdown preference")
    native.nameplateStyle = "6"
    preview:Update("ufNameplates", "style", "style")
    check(sample.view.health:GetStatusBarTexture():GetTexture() == "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill"
        and sample.view.healthArt:GetTexture() == "Interface\\Tooltips\\Nameplate-Border",
        client.name .. " Classic native style uses its own Blizzard art in the preview")

    local function click(parent, label)
        for _, child in ipairs({ parent:GetChildren() }) do
            if child:GetText() == label then
                child:GetScript("OnClick")(child)
                return
            end
        end
        error("Missing preview action: " .. label)
    end
    click(preview, labels.npPreviewAnimate)
    check(preview:GetScript("OnUpdate") ~= nil, client.name .. " appearance preview can animate the sample")
    click(preview, labels.npPreviewPause)
    check(preview:GetScript("OnUpdate") == nil, client.name .. " pausing retires the animation callback")
    fixture.setCombat(true)
    click(preview, labels.npPreviewWorld)
    local world = assert(preview.world)
    check(world:IsShown() and world.sample.holder:GetWidth() == sample.holder:GetWidth()
        and world.sample.view.cast:IsShown() and world:GetScript("OnUpdate"),
        client.name .. " Test in Game uses the same sample while leaving live world nameplates alone")
    check(fixture.calls.worldQueries == 0, client.name .. " the preview never reads live nameplate frames")
    fixture.event("PLAYER_ENTERING_WORLD")
    check(not world:IsShown() and not world.events.PLAYER_ENTERING_WORLD and world:GetScript("OnUpdate") == nil,
        client.name .. " a zone change closes the world-scale sample and retires its animation")
end

for _, client in ipairs(clients) do
    checkPublishedRuntime(client)
    checkPreview(client)
end

local toc = assert(io.open("_FluxUI.toc", "r"))
local contents = toc:read("*a")
toc:close()
for _, module in ipairs({ "Core", "CastBarSchools", "ComboPoints", "Threat", "Level", "Countdown" }) do
    check(contents:find("NamePlates\\" .. module .. ".lua", 1, true), module .. " stays on the published live plate path")
end
check(not contents:find("NamePlates\\AppearanceWorld.lua", 1, true), "the addon does not load a separate appearance renderer")
check(not contents:find("NamePlates\\Flare", 1, true) and not contents:find("AddonOptions\\FlareNameplate", 1, true),
    "the packaged addon has no reference addon nameplate runtime or options dependency")
print(("PASS nameplate appearance: %d checks across five client models; native rendering pending"):format(checks))
