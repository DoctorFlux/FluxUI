local _, ns = ...
local W = ns.FluxOptionsWidgets
local Aura = ns.Flux and ns.Flux.Aura
local Preview = {}
ns.FluxOptionsNameplatePreview = Preview
ns.FluxOptionsNameplateEditor = ns.FluxOptionsNameplateEditor or { kind = "enemyNpc" }
local editor = ns.FluxOptionsNameplateEditor

ns.FluxOptionsLocale = ns.FluxOptionsLocale or {}
local L = ns.FluxOptionsLocale
local english = {
    npPreviewTitle = "Live Preview",
    npPreviewHint = "Click the sample to edit its settings.",
    npPreviewUnit = "Unit type",
    npPreviewState = "State",
    npPreviewEnemyNpc = "Enemy NPC",
    npPreviewEnemyPlayer = "Enemy player",
    npPreviewFriendlyNpc = "Friendly NPC",
    npPreviewFriendlyPlayer = "Friendly player",
    npPreviewMinor = "Minor unit",
    npPreviewOverview = "Overview",
    npPreviewTarget = "Targeted",
    npPreviewNonTarget = "Non-targeted",
    npPreviewRange = "Out of sight",
    npPreviewFocus = "Focus",
    npPreviewThreat = "Threat",
    npPreviewCast = "Casting",
    npPreviewProtected = "Uninterruptible",
    npPreviewImportant = "Important cast",
    npPreviewTargetedCast = "Cast targeting you",
    npPreviewQuest = "Quest progress",
    npPreviewAuras = "Auras / CC",
    npPreviewResource = "Combo points",
    npPreviewNameOnly = "Name only",
    npPreviewAnimate = "Animate",
    npPreviewPause = "Pause",
    npPreviewWorld = "Test in Game",
    npPreviewWorldStop = "Stop Testing",
    npPreviewWorldHint = "Shows this sample at game scale. You can close it with Escape.",
    npPreviewHidden = "This plate is hidden by its settings.",
    npPreviewSpider = "Forest Spider",
    npPreviewRival = "Veyra",
    npPreviewAlly = "Marik",
    npPreviewMerchant = "Field Provisioner",
    npPreviewImp = "Wild Imp",
    npPreviewShadowBolt = "Shadow Bolt",
    npPreviewCastTarget = "You",
    npPreviewStyleTab = "Plate",
    npPreviewExtrasTab = "Extras",
    npPreviewTargetingTab = "Targeting",
    npPreviewCastTab = "Cast Bar",
    npPreviewAurasTab = "Auras",
}
for key, value in pairs(english) do
    if not L[key] then L[key] = value end
end

local kinds = {
    enemyNpc = { name = "npPreviewSpider", color = { .87, .27, .27 }, level = 12 },
    enemyPlayer = { name = "npPreviewRival", color = { .87, .27, .27 }, level = 60, player = true },
    friendlyNpc = { name = "npPreviewMerchant", color = { .30, .78, .30 }, level = 18, friendly = true },
    friendlyPlayer = { name = "npPreviewAlly", color = { .30, .78, .30 }, level = 60, player = true, friendly = true },
    minor = { name = "npPreviewImp", color = { .87, .27, .27 }, level = 9 },
}
local function Choices(entries)
    local items = {}
    for i, entry in ipairs(entries) do
        items[i] = { value = entry[1], text = L[entry[2]] }
    end
    return items
end

local kindChoices = Choices({
    { "enemyNpc", "npPreviewEnemyNpc" }, { "enemyPlayer", "npPreviewEnemyPlayer" },
    { "friendlyNpc", "npPreviewFriendlyNpc" }, { "friendlyPlayer", "npPreviewFriendlyPlayer" },
    { "minor", "npPreviewMinor" },
})
local stateChoices = Choices({
    { "overview", "npPreviewOverview" }, { "target", "npPreviewTarget" }, { "nonTarget", "npPreviewNonTarget" },
    { "focus", "npPreviewFocus" }, { "range", "npPreviewRange" }, { "threat", "npPreviewThreat" }, { "cast", "npPreviewCast" },
    { "protected", "npPreviewProtected" },
    { "important", "npPreviewImportant" }, { "targeted", "npPreviewTargetedCast" },
    { "quest", "npPreviewQuest" }, { "auras", "npPreviewAuras" },
    { "resource", "npPreviewResource" }, { "nameOnly", "npPreviewNameOnly" },
})
local castStates = { overview = true, cast = true, protected = true, important = true, targeted = true }
local icon = "Interface\\Icons\\"
local auras = {
    { icon = icon .. "Spell_Shadow_ShadowWordPain", filter = "Debuffs", mine = true, dispelType = "Magic", count = 2, time = 9 },
    { icon = icon .. "Ability_Rogue_Rupture", filter = "Debuffs", dispelType = "Bleed", time = 6 },
    { icon = icon .. "Spell_Holy_PowerWordShield", filter = "Buffs", time = 18 },
    { icon = icon .. "Spell_Frost_Polymorph", filter = "CrowdControl", mine = true, dispelType = "Magic", time = 8 },
}
local tabLabels = { style = "npPreviewStyleTab", extras = "npPreviewExtrasTab", targeting = "npPreviewTargetingTab",
    cast = "npPreviewCastTab", auras = "npPreviewAurasTab" }
local hoverStates = {
    target_scale = "target", target_occluded = "range",
    cast_HighlightImportantCasts = "important", cast_HighlightWhenCastTarget = "targeted",
    cast_SpellTarget = "targeted", cast_SpellName = "cast", cast_SpellIcon = "cast",
    npcThreatBorder = "threat", showNumericThreat = "threat", visibilityMode = "threat",
    blizzardProgressive = "threat", blizzardFlash = "threat", blizzardHealthBarColor = "threat",
    enemyPlayerTarget = "targeted", visible_friendlyNames = "nameOnly",
    questOverlayEnabled = "quest", font_countdownSize = "auras",
}

local function Text(parent, font)
    local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    text:SetWordWrap(false)
    return text
end

local function Button(parent, label, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(100, 22)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

local function Hotspot(parent, part, callback)
    local hit = CreateFrame("Button", nil, parent)
    hit:EnableMouse(true)
    hit:RegisterForClicks("LeftButtonUp")
    local highlight = hit:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    local r, g, b = W.Accent()
    W.Solid(highlight, r, g, b, .23)
    hit:SetScript("OnClick", function()
        W.HideTooltip()
        callback(part)
    end)
    hit:SetScript("OnEnter", function(self) W.ShowTooltip(self, L[tabLabels[part]], L.npPreviewHint) end)
    hit:SetScript("OnLeave", W.HideTooltip)
    hit:SetScript("OnHide", function(self)
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then W.HideTooltip() end
    end)
    return hit
end

local function AttachHotspot(hit, region)
    if not hit then return end
    hit:ClearAllPoints()
    if not region or not region:IsShown() then hit:Hide(); return end
    hit:SetAllPoints(region)
    hit:Show()
end

local function ShownRegion(regions)
    for _, region in ipairs(regions or {}) do
        if region:IsShown() then return region end
    end
end

local function SelectHotspot(hit, selected)
    if not hit then return end
    local border = hit.selection
    if selected and not border then
        border = hit:CreateTexture(nil, "OVERLAY")
        border:SetPoint("BOTTOMLEFT")
        border:SetPoint("BOTTOMRIGHT")
        border:SetHeight(1)
        hit.selection = border
    end
    if border then
        if selected then W.Solid(border, W.Accent()) end
        border:SetShown(selected)
    end
end

-- Draw the Blizzard artwork on a standalone sample. Blizzard's Settings
-- preview template registers a shared script nameplate and refreshes the
-- world driver, which would make it unsafe to instantiate here.
local FILL = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill"
local CLASSIC_BORDER = "Interface\\Tooltips\\Nameplate-Border"
local CLASSIC_CAST_BORDER = "Interface\\Tooltips\\Nameplate-Border-Castbar"
local HEALTH_FILL = "UI-HUD-CoolDownManager-Bar"
local HEALTH_BG = "UI-HUD-CoolDownManager-Bar-BG"
local FONT = "Fonts\\FRIZQT__.TTF"
local VISIBILITY = {
    enemyNpc = "nameplateShowEnemies", enemyPlayer = "nameplateShowEnemies",
    friendlyNpc = "nameplateShowFriendlyNpcs", friendlyPlayer = "nameplateShowFriendlyPlayers",
    minor = "nameplateShowEnemyMinions",
}
local AURA_SETTINGS = {
    enemyNpc = { "nameplateEnemyNpcAuraDisplay", "NamePlateEnemyNpcAuraDisplay" },
    enemyPlayer = { "nameplateEnemyPlayerAuraDisplay", "NamePlateEnemyPlayerAuraDisplay" },
    friendlyPlayer = { "nameplateFriendlyPlayerAuraDisplay", "NamePlateFriendlyPlayerAuraDisplay" },
}
local DEFAULT_STYLES = { Modern = 0, Thin = 1, Block = 2, HealthFocus = 3, CastFocus = 4, Legacy = 5, Classic = 6 }
local SIZE_SCALES = { .75, 1, 1.25, 1.4, 1.6 }
local SELECTED_OFFSETS = { topLeftX = -1, topLeftY = 1, bottomRightX = -3, bottomRightY = 3 }
local infoCVar, infoEnum = "nameplateInfoDisplay", "NamePlateInfoDisplay"
local castCVar, castEnum = "nameplateCastBarDisplay", "NamePlateCastBarDisplay"

local function ReadCVar(cvar)
    local settings = ns.Flux and ns.Flux.BlizzardSettings
    local get = (settings and settings.Write and settings.Write.Get) or (C_CVar and C_CVar.GetCVar) or GetCVar
    if not get then return nil end
    local ok, value = pcall(get, cvar)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
end

local function Enabled(cvar, fallback)
    local value = ReadCVar(cvar)
    if value == nil then return fallback end
    return value == true or value == "1" or value == 1
end

local function BitEnabled(cvar, enum, flag, fallback)
    local group = Enum and Enum[enum]
    local index = group and group[flag]
    local get = (C_CVar and C_CVar.GetCVarBitfield) or GetCVarBitfield
    if not (type(index) == "number" and index > 0 and get) then return fallback end
    local ok, enabled = pcall(get, cvar, index)
    if ok and not (issecretvalue and issecretvalue(enabled)) and type(enabled) == "boolean" then return enabled end
    return fallback
end

local function Atlas(texture, atlas, fallback)
    if atlas and texture.SetAtlas and (not C_Texture or not C_Texture.GetAtlasInfo or C_Texture.GetAtlasInfo(atlas)) then
        texture:SetAtlas(atlas, false)
    else
        texture:SetTexture(fallback)
    end
end

local function SetBarArt(bar, atlas)
    bar:SetStatusBarTexture(FILL)
    local texture = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if texture and atlas then Atlas(texture, atlas, FILL) end
end

local function ComboClient()
    local client = ns.Flux and ns.Flux.Client or {}
    local _, class
    if UnitClass then _, class = UnitClass("player") end
    if class ~= "ROGUE" and class ~= "DRUID" then return end
    if client.isEra or client.isClassicEra or client.isAnniversary then return "classic" end
    if (client.isForever or client.isCamelot) and ns.ForeverComboPoints then return "forever" end
end

local function CreatePoints(view, health)
    local points = CreateFrame("Frame", nil, view)
    points:SetPoint("CENTER", health, "TOP", 0, 4)
    local comboClient = ComboClient()
    if comboClient == "forever" then
        local combo = ns.ForeverComboPoints
        combo.CreatePoints(points)
        combo.UpdatePoints(points, 3, 5, true)
        points:SetScale(.675)
    elseif comboClient == "classic" then
        points:SetSize(68, 12)
        points:SetScale(1.5)
        for i = 1, 5 do
            local point = CreateFrame("Frame", nil, points, "ComboPointTemplate")
            point:SetPoint("CENTER", points, "CENTER", (i - 3) * 14, -4)
            point.Highlight:SetAlpha(i <= 3 and 1 or 0)
            point.Shine:SetAlpha(0)
        end
    end
    return points, comboClient ~= nil
end

local function Span(region, parent, left, top, right, bottom)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
    region:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", right, bottom)
end

local function Font(text, size)
    text:SetFont(FONT, math.max(8, math.floor(size + .5)), "OUTLINE")
end

local function Badge(parent, label, texture)
    local badge = CreateFrame("Frame", nil, parent)
    badge.art = badge:CreateTexture(nil, "BACKGROUND")
    Span(badge.art, badge, -2, 2, 2, -2)
    badge.text = Text(badge)
    Font(badge.text, 10)
    badge.text:SetText(label)
    if texture then
        badge.icon = badge:CreateTexture(nil, "ARTWORK")
        badge.icon:SetSize(10, 10)
        badge.icon:SetPoint("LEFT", 2, 0)
        badge.icon:SetTexture(texture)
        badge.text:SetPoint("LEFT", badge.icon, "RIGHT", 2, 0)
        badge.text:SetTextColor(1, .82, 0)
    else
        badge.text:SetPoint("CENTER")
    end
    badge:SetSize(badge.text:GetStringWidth() + (texture and 17 or 8), 14)
    return badge
end

local function CreateAura(parent, record)
    local aura = CreateFrame("Frame", nil, parent)
    if Aura then
        aura.image = Aura.CreateNameplateAuraArt(aura)
        local rim = Aura.CreateNameplateAuraBorder(aura)
        local kind = record.dispelType or (record.filter == "Buffs" and "Buff" or "None")
        local r, g, b = Aura.GetNameplateAuraColor(kind)
        rim:SetVertexColor(r, g, b, 1)
    else
        aura.image = aura:CreateTexture(nil, "ARTWORK")
        aura.image:SetAllPoints()
    end
    aura.image:SetTexture(record.icon)
    if Aura and record.dispelType then
        aura.dispelIcon = Aura.CreateDispelTypeIcon(aura)
        Aura.SetDispelTypeIcon(aura.dispelIcon, record.dispelType)
    end
    aura.count = Text(aura, "NumberFontNormalSmall")
    aura.count:SetPoint("BOTTOMRIGHT", 2, -1)
    if record.count then aura.count:SetText(record.count) end
    aura.timer = Text(aura)
    return aura
end

local function CreateSample(canvas, onPart)
    local holder = CreateFrame("Frame", nil, canvas)
    holder:SetPoint("CENTER", 0, -4)
    holder:SetSize(150, 15)
    local view = CreateFrame("Frame", nil, holder)
    view:SetAllPoints()
    local health = CreateFrame("StatusBar", nil, view)
    health:SetMinMaxValues(0, 100)
    local healthArt = health:CreateTexture(nil, "BACKGROUND")
    local selection = health:CreateTexture(nil, "OVERLAY")
    Atlas(selection, NamePlateConstants and NamePlateConstants.SELECTED_BORDER_ATLAS or "UI-HUD-Nameplates-Selected")
    local aggro = health:CreateTexture(nil, "ARTWORK")
    aggro:SetPoint("BOTTOMLEFT", health, "TOPLEFT")
    aggro:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT")
    aggro:SetHeight(6)
    Atlas(aggro, "UI-HUD-Nameplates-Aggro-Flare")
    aggro:SetVertexColor(1, .33, .10)
    local name, healthText = Text(health), Text(health)
    local rarity = health:CreateTexture(nil, "OVERLAY")
    rarity:SetPoint("LEFT", health, "RIGHT", 5, 0)
    rarity:SetSize(18, 18)
    Atlas(rarity, "nameplates-icon-elite-gold")
    local dimmer = health:CreateTexture(nil, "ARTWORK", nil, 1)
    dimmer:SetAllPoints()
    Atlas(dimmer, "ui-hud-nameplates-deselected-overlay")

    local cast = CreateFrame("StatusBar", nil, view)
    cast:SetMinMaxValues(0, 1)
    local castArt, castHighlight = cast:CreateTexture(nil, "BACKGROUND"), cast:CreateTexture(nil, "OVERLAY")
    local castRim, castSpark = cast:CreateTexture(nil, "OVERLAY"), cast:CreateTexture(nil, "OVERLAY")
    castRim:SetTexture(CLASSIC_CAST_BORDER)
    local castIcon, castShield = cast:CreateTexture(nil, "ARTWORK"), cast:CreateTexture(nil, "OVERLAY")
    castIcon:SetTexture(icon .. "Spell_Shadow_ShadowBolt")
    Atlas(castShield, "nameplates-InterruptShield", "Interface\\CastingBar\\UI-CastingBar-Small-Shield")
    castShield:SetAllPoints(castIcon)
    castSpark:SetSize(4, 12)
    Atlas(castSpark, "ui-castingbar-pip", "Interface\\CastingBar\\UI-CastingBar-Spark")
    local castText = Text(cast)
    castText:SetJustifyH("LEFT")

    local quest = Badge(view, "3/8", "Interface\\AddOns\\_FluxUI\\Texture\\QuestSlay.blp")
    local loot = Badge(view, "2/5", "Interface\\AddOns\\_FluxUI\\Texture\\QuestLoot.blp")
    loot:SetPoint("LEFT", quest, "RIGHT", 4, 0)
    local threat, level = Badge(view, "2  84%"), Badge(view, "Lvl. 12")
    quest:SetFrameLevel(health:GetFrameLevel() + 5)
    loot:SetFrameLevel(quest:GetFrameLevel())
    threat:SetFrameLevel(quest:GetFrameLevel())
    level:SetFrameLevel(quest:GetFrameLevel())

    local points, comboAvailable = CreatePoints(view, health)
    view.auras = {}
    for i, record in ipairs(auras) do view.auras[i] = CreateAura(view, record) end
    view.health, view.healthArt, view.healthText, view.name, view.rarity = health, healthArt, healthText, name, rarity
    view.selection, view.aggro, view.dimmer = selection, aggro, dimmer
    view.cast, view.castArt, view.castRim, view.castHighlight = cast, castArt, castRim, castHighlight
    view.castIcon, view.castShield, view.castText, view.castSpark = castIcon, castShield, castText, castSpark

    local sample = { holder = holder, view = view, quest = quest, loot = loot,
        threat = threat, level = level, points = points, comboAvailable = comboAvailable }
    if onPart then
        local buttons = CreateFrame("Frame", nil, holder)
        buttons:SetAllPoints()
        buttons:SetFrameLevel(quest:GetFrameLevel() + 1)
        sample.styleHit = Hotspot(buttons, "style", onPart)
        sample.levelHit = Hotspot(buttons, "extras", onPart)
        sample.questHit = Hotspot(buttons, "extras", onPart)
        sample.lootHit = Hotspot(buttons, "extras", onPart)
        sample.threatHit = Hotspot(buttons, "extras", onPart)
        sample.targetHit = Hotspot(buttons, "targeting", onPart)
        sample.comboHit = Hotspot(buttons, "extras", onPart)
        sample.castHit = Hotspot(buttons, "cast", onPart)
        sample.aurasHit = Hotspot(buttons, "auras", onPart)
    end
    return sample
end

local function LayoutSample(sample, kind, state, canvasWidth, nativeScale)
    local view = sample.view
    local constants = NamePlateConstants or {}
    local styles = Enum and Enum.NamePlateStyle or DEFAULT_STYLES
    local style = tonumber(ReadCVar("nameplateStyle")) or styles.Block or DEFAULT_STYLES.Block
    local size = tonumber(ReadCVar("nameplateSize")) or 2
    local classic = styles.Classic ~= nil and style == styles.Classic
    local inside = style == styles.Block or style == styles.Modern
    local castInside = style == styles.Block or style == styles.CastFocus or classic
    local scales = classic and constants.NAME_PLATE_SCALES_CLASSIC_STYLE or constants.NAME_PLATE_SCALES
    local scale = scales and scales[size]
    local x = scale and scale.horizontal or SIZE_SCALES[size] or 1
    local y = scale and scale.vertical or (size == 1 and .8 or x)
    local target = state == "target" or state == "overview"
    local shown = Enabled(VISIBILITY[kind], true)
    local nameOnly = state == "nameOnly" or (kind == "friendlyPlayer" and Enabled("nameplateShowOnlyNameForFriendlyPlayerUnits", false))
    local width = (classic and (constants.CLASSIC_BORDER_WIDTH or 128)
        or (constants.NAME_PLATE_WIDTH or 230) - 2 * (constants.HORIZONTAL_INSET or 12)) * x
    local height = (classic and (constants.CLASSIC_HEALTH_BAR_HEIGHT or 10)
        or (inside or style == styles.HealthFocus) and (constants.LARGE_HEALTH_BAR_HEIGHT or 20)
        or (constants.SMALL_HEALTH_BAR_HEIGHT or 10)) * y
    local castHeight = (classic and (constants.CLASSIC_CAST_BAR_HEIGHT or 10)
        or (style == styles.Block or style == styles.CastFocus) and (constants.LARGE_CAST_BAR_HEIGHT or 16)
        or (constants.SMALL_CAST_BAR_HEIGHT or 10)) * y
    local castGap = (classic and (constants.CLASSIC_CAST_BAR_TO_HEALTH_BAR_SPACING or 4)
        or (constants.CAST_BAR_TO_HEALTH_BAR_SPACING or 2)) * y
    local nameGap = (classic and (constants.CLASSIC_HEALTH_BAR_TO_NAME_ABOVE_SPACING or 4)
        or (constants.HEALTH_BAR_TO_NAME_ABOVE_SPACING or 2)) * y
    local fontSize = (classic and (constants.CLASSIC_HEALTH_BAR_FONT_HEIGHT or 10)
        or (constants.HEALTH_BAR_FONT_HEIGHT or 12)) * y
    local targetScale = target and (tonumber(ReadCVar("nameplateSelectedScale")) or 1) or 1
    sample.holder:SetSize(width, height)
    sample.holder:SetScale(nativeScale and targetScale
        or math.min(targetScale, math.max(.2, ((canvasWidth or width) - 34) / width)))
    local alpha = state == "range" and tonumber(ReadCVar("nameplateOccludedAlphaMult"))
    view:SetAlpha(alpha or 1)
    view:SetShown(shown)
    if not shown then return false end

    SetBarArt(view.health, not classic and HEALTH_FILL or nil)
    if classic then
        view.health:ClearAllPoints()
        view.health:SetPoint("TOPLEFT", view, "TOPLEFT", 3.5 * x, .5 * y)
        view.health:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -20.75 * x, .5 * y)
        view.healthArt:SetTexture(CLASSIC_BORDER)
        view.healthArt:SetTexCoord(0, 1, .5, 1)
        if view.healthArt.SetDrawLayer then view.healthArt:SetDrawLayer("ARTWORK", 1) end
        local inset = ((constants.CLASSIC_BORDER_HEIGHT or 16) * y - height) / 2
        Span(view.healthArt, view, 0, inset, 0, -inset)
    else
        view.health:ClearAllPoints()
        view.health:SetAllPoints()
        Atlas(view.healthArt, HEALTH_BG, CLASSIC_BORDER)
        view.healthArt:SetTexCoord(0, 1, 0, 1)
        if view.healthArt.SetDrawLayer then view.healthArt:SetDrawLayer("BACKGROUND") end
        Span(view.healthArt, view.health, -2, 3, 6, -6)
    end
    local offsets = constants.SELECTED_BORDER_OFFSETS or SELECTED_OFFSETS
    Span(view.selection, view.healthArt, offsets.topLeftX, offsets.topLeftY, offsets.bottomRightX, offsets.bottomRightY)
    view.healthArt:SetShown(not nameOnly)
    view.selection:SetShown(not nameOnly and not classic and (target or state == "focus"))
    view.dimmer:SetShown(not nameOnly and not classic and not target and state ~= "focus")
    local border = state == "focus" and (constants.FOCUS_TARGET_BORDER_COLOR or NAMEPLATE_BORDER_FOCUS_TARGET_COLOR)
        or (constants.TARGET_BORDER_COLOR or NAMEPLATE_BORDER_TARGET_COLOR)
    if border then view.selection:SetVertexColor(border.r, border.g, border.b)
    else view.selection:SetVertexColor(1, 1, 1) end
    view.name:SetText(L[kinds[kind].name])
    Font(view.name, fontSize)
    view.name:ClearAllPoints()
    view.healthText:ClearAllPoints()
    Font(view.healthText, fontSize)
    if inside and not nameOnly then
        view.name:SetPoint("LEFT", view.health, "LEFT", 4, 0)
        view.name:SetPoint("RIGHT", view.healthText, "LEFT", -4, 0)
        view.healthText:SetPoint("RIGHT", view.health, "RIGHT", -4, 0)
        view.name:SetJustifyH("LEFT")
    elseif classic or nameOnly then
        view.name:SetPoint("BOTTOM", view, "TOP", 0, nameGap)
        view.healthText:SetPoint("RIGHT", view.health, "RIGHT", -4, 0)
        view.name:SetJustifyH("CENTER")
    else
        view.name:SetPoint("BOTTOMLEFT", view, "TOPLEFT", 0, nameGap)
        view.healthText:SetPoint("BOTTOMRIGHT", view, "TOPRIGHT", -4, nameGap)
        view.name:SetPoint("RIGHT", view.healthText, "LEFT", -4, 0)
        view.name:SetJustifyH("LEFT")
    end

    local np = ns.Flux and ns.Flux.NamePlates
    local db = np and np.GetDB and np.GetDB() or {}
    local threatAPI = ns.Flux and ns.Flux.Threat
    local threatCase = not nameOnly and state == "threat" and kind == "enemyNpc"
        and db.npcThreatBorder ~= false and db.visibilityMode ~= "never"
    local urgent = not nameOnly and state == "targeted" and kind == "enemyPlayer" and db.enemyPlayerTarget ~= false
    local threatR, threatG, threatB = 1, .39, .16
    if threatCase and threatAPI and threatAPI.GetTintColor then
        local r, g, b = threatAPI.GetTintColor(84, 1, false, 2)
        if r then threatR, threatG, threatB = r, g, b end
    end
    local record = kinds[kind]
    local classColored = record.player and Enabled(record.friendly and "nameplateShowFriendlyClassColor" or "nameplateShowClassColor",
        not record.friendly)
    local r, g, b = unpack(record.color)
    if classColored then r, g, b = .41, .80, .94 end
    local coloredName = style == styles.Legacy or (record.friendly and record.player
        and Enabled("nameplateUseClassColorForFriendlyPlayerUnitNames", false))
    local nameR, nameG, nameB = 1, 1, 1
    if coloredName then
        nameR, nameG, nameB = r, g, b
        if record.friendly and record.player then nameR, nameG, nameB = .41, .80, .94 end
    end
    view.name:SetTextColor(nameR, nameG, nameB)
    if threatCase and BitEnabled("nameplateThreatDisplay", "NamePlateThreatDisplay", "HealthBarColor", true) then
        r, g, b = threatR, threatG, threatB
    end
    view.health:SetStatusBarColor(r, g, b, nameOnly and 0 or 1)
    if urgent then
        view.healthArt:SetVertexColor(1, 0, 0)
    elseif threatCase then
        view.healthArt:SetVertexColor(threatR, threatG, threatB)
    else
        view.healthArt:SetVertexColor(1, 1, 1)
    end
    local nativeThreat = not nameOnly and state == "threat" and kind == "enemyNpc"
    sample.threatFlash = nativeThreat and BitEnabled("nameplateThreatDisplay", "NamePlateThreatDisplay", "Flash", true)
    view.aggro:SetShown(nativeThreat and BitEnabled("nameplateThreatDisplay", "NamePlateThreatDisplay", "Progressive", true))
    view.rarity:SetShown(kind == "enemyNpc" and not nameOnly and BitEnabled(infoCVar, infoEnum, "RarityIcon", true))
    sample.showHealthValue = not nameOnly and BitEnabled(infoCVar, infoEnum, "CurrentHealthValue", true)
    sample.showHealthPercent = not nameOnly and BitEnabled(infoCVar, infoEnum, "CurrentHealthPercent", true)
    view.healthText:SetShown(sample.showHealthValue or sample.showHealthPercent)

    local castShown = not nameOnly and castStates[state] and not record.friendly
    local cast = view.cast
    cast:SetShown(castShown and true or false)
    cast:ClearAllPoints()
    cast:SetPoint("TOPLEFT", view, "BOTTOMLEFT", 0, -castGap)
    cast:SetPoint("TOPRIGHT", view, "BOTTOMRIGHT", classic and -8 or 0, -castGap)
    cast:SetHeight(castHeight)
    SetBarArt(cast, not classic and (state == "protected" and "ui-castingbar-uninterruptable" or "ui-castingbar-filling-standard"))
    if classic then
        if state == "protected" then cast:SetStatusBarColor(.65, .65, .65)
        else cast:SetStatusBarColor(1, .70, 0) end
    else
        cast:SetStatusBarColor(1, 1, 1)
    end
    view.castSpark:SetShown(state ~= "protected")
    sample.castWidth = width - (classic and 8 or 0)
    if classic then W.Solid(view.castArt, .08, .07, .05, 1)
    else Atlas(view.castArt, "ui-castingbar-background", FILL) end
    Span(view.castArt, cast, 0, 0, 0, 0)
    Span(view.castRim, cast, -4, 4, 4, -4)
    view.castRim:SetShown(classic)
    local important = state == "important" and BitEnabled(castCVar, castEnum, "HighlightImportantCasts", true)
    local targeted = state == "targeted" and BitEnabled(castCVar, castEnum, "HighlightWhenCastTarget", true)
    Atlas(view.castHighlight, targeted and "ui-hud-nameplates-targetedbyenemy" or "ui-hud-nameplates-importantcast")
    Span(view.castHighlight, cast, important and -18 or -4, 4, important and 18 or 4, -4)
    view.castHighlight:SetShown(important or targeted)
    view.castIcon:ClearAllPoints()
    local iconSize = (classic and (constants.CLASSIC_CAST_BAR_ICON_HEIGHT or 14) or (constants.CAST_BAR_ICON_HEIGHT or 12)) * y
    view.castIcon:SetSize(iconSize, iconSize)
    local castIconShown = BitEnabled(castCVar, castEnum, "SpellIcon", true)
    view.castIcon:SetShown(castIconShown and (state ~= "protected" or classic))
    view.castShield:SetShown(state == "protected")
    view.castText:ClearAllPoints()
    Font(view.castText, (constants.CAST_BAR_FONT_HEIGHT or 10) * y)
    if castInside and not classic then
        view.castIcon:SetPoint("LEFT", cast, "LEFT", 1, 0)
        view.castText:SetPoint("LEFT", cast, "LEFT", castIconShown and iconSize + 3 or 3, 0)
        view.castText:SetPoint("RIGHT", cast, "RIGHT", -3, 0)
    elseif castInside then
        view.castIcon:SetPoint("RIGHT", cast, "LEFT", -3, 0)
        view.castText:SetPoint("LEFT", cast, "LEFT", 3, 0)
        view.castText:SetPoint("RIGHT", cast, "RIGHT", -3, 0)
    else
        view.castIcon:SetPoint("TOPLEFT", cast, "BOTTOMLEFT", 0, -2)
        view.castText:SetPoint("TOPLEFT", cast, "BOTTOMLEFT", castIconShown and iconSize + 3 or 0, -2)
        view.castText:SetPoint("RIGHT", cast, "RIGHT", 0, 0)
    end
    local castName = BitEnabled(castCVar, castEnum, "SpellName", true) and L.npPreviewShadowBolt or ""
    local castTarget = state == "targeted" and BitEnabled(castCVar, castEnum, "SpellTarget", true)
    view.castText:SetText(castTarget and (castName ~= "" and castName .. " > " or "") .. L.npPreviewCastTarget or castName)

    local questShown = not nameOnly and kind == "enemyNpc" and (state == "quest" or state == "overview")
        and db.questOverlayEnabled ~= false
    local numeric = threatCase and (not threatAPI or not threatAPI.ShowNumeric or threatAPI.ShowNumeric())
    local showNativeLevel = classic and kind ~= "minor"
    local showFluxLevel = not classic and np and np.IsLevelSupported and np.IsLevelSupported() and db.levelOverlayEnabled ~= false
    local levelShown = not nameOnly and (showNativeLevel or showFluxLevel and kind ~= "minor")
    local badges = { sample.quest, sample.loot, sample.threat, sample.level }
    for _, badge in ipairs(badges) do
        Atlas(badge.art, not classic and HEALTH_BG or nil, CLASSIC_BORDER)
        badge.art:SetTexCoord(0, 1, classic and .5 or 0, 1)
    end
    sample.quest:ClearAllPoints()
    sample.quest:SetPoint("TOPLEFT", castShown and cast or view, "BOTTOMLEFT", 0, castShown and (castInside and -2 or -14) or 3)
    sample.threat:ClearAllPoints()
    sample.threat:SetPoint("CENTER", view, "BOTTOM", 0, -3)
    sample.level:ClearAllPoints()
    sample.level:SetPoint("RIGHT", view, showNativeLevel and "RIGHT" or "BOTTOMRIGHT", -2, 0)
    sample.level.text:SetText((showNativeLevel and "" or "Lvl. ") .. record.level)
    sample.level:SetWidth(sample.level.text:GetStringWidth() + 8)
    sample.quest:SetShown(questShown)
    sample.loot:SetShown(questShown)
    sample.threat:SetShown(numeric)
    sample.level:SetShown(levelShown and true or false)
    sample.level.art:SetShown(not showNativeLevel)
    sample.level.art:SetVertexColor(threatCase and threatR or 1, threatCase and threatG or 1, threatCase and threatB or 1)
    if numeric then
        sample.threat.art:SetVertexColor(threatR, threatG, threatB)
        sample.threat.text:SetTextColor(threatR, threatG, threatB)
        if threatAPI and threatAPI.SetRankPercentText then threatAPI.SetRankPercentText(sample.threat.text, 2, 84) end
    end

    sample.points:SetShown(not nameOnly and state == "resource" and sample.comboAvailable)

    local auraOptions = AURA_SETTINGS[kind == "minor" and "enemyNpc" or kind]
    local auraSettings = type(FluxUI_DB) == "table" and FluxUI_DB.nameplateAppearance
    local position, digits, onlyMyDebuffs = "middle", 12, false
    if type(auraSettings) == "table" then
        position = rawget(auraSettings, "auraCountdown") or position
        digits = tonumber(rawget(auraSettings, "countdownSize")) or digits
        digits = digits == digits and math.max(8, math.min(24, digits)) or 12
        onlyMyDebuffs = rawget(auraSettings, "onlyMyDebuffs") == true
    end
    local auraSize = math.max(10, (constants.AURA_ITEM_HEIGHT or 25)
        * (scale and scale.aura or x) * (tonumber(ReadCVar("nameplateAuraScale")) or 1))
    local padding = tonumber(ReadCVar("nameplateDebuffPadding")) or 1
    local minGap = position == "below" and digits + 1 or 1
    local showAuraState = not nameOnly and (state == "auras" or state == "overview")
        and not (kind == "minor" and BitEnabled("nameplateSimplifiedTypes", "NamePlateSimplifiedType", "Minion", false))
    local previous
    for i, aura in ipairs(view.auras) do
        local auraRecord = auras[i]
        local flag = auraRecord.filter
        if flag == "CrowdControl" and record.player then flag = "LossOfControl" end
        local show = showAuraState and (not onlyMyDebuffs or flag == "Buffs" or auraRecord.mine)
            and (auraOptions and BitEnabled(auraOptions[1], auraOptions[2], flag, true)
            or kind == "friendlyNpc" and flag == "Debuffs" and Enabled("nameplateShowDebuffsOnFriendly", false))
        aura:SetShown(show and true or false)
        if show then
            aura:SetSize(auraSize, auraSize)
            if Aura and aura.artSize ~= auraSize then
                Aura.LayoutNameplateAuraArt(aura.image, aura, auraSize)
                if aura.dispelIcon then Aura.LayoutDispelTypeIcon(aura.dispelIcon, aura, auraSize) end
                aura.artSize = auraSize
            end
            aura:ClearAllPoints()
            if previous then
                aura:SetPoint("LEFT", previous, "RIGHT", 1, 0)
            else
                local nameAbove = not inside and not nameOnly
                aura:SetPoint("BOTTOMLEFT", view, "TOPLEFT", 0, math.max(minGap, padding) + (nameAbove and fontSize + nameGap or 0))
            end
            aura.timer:ClearAllPoints()
            if position == "below" then
                aura.timer:SetPoint("TOP", aura, "BOTTOM", 0, -1)
            elseif position == "bottom" then
                aura.timer:SetPoint("BOTTOM", aura, "BOTTOM", 0, 1)
            else
                aura.timer:SetPoint("CENTER")
            end
            aura.timer:SetShown(position ~= "none")
            Font(aura.timer, digits)
            previous = aura
        end
    end

    AttachHotspot(sample.styleHit, nameOnly and view.name or view.health)
    AttachHotspot(sample.levelHit, sample.level)
    AttachHotspot(sample.questHit, sample.quest)
    AttachHotspot(sample.lootHit, sample.loot)
    AttachHotspot(sample.threatHit, sample.threat)
    AttachHotspot(sample.comboHit, sample.points)
    if sample.targetHit then
        sample.targetHit:ClearAllPoints()
        sample.targetHit:SetPoint("TOPLEFT", view.health, "TOPRIGHT", 0, 2)
        sample.targetHit:SetPoint("BOTTOMLEFT", view.health, "BOTTOMRIGHT", 0, -2)
        sample.targetHit:SetWidth(5)
        sample.targetHit:SetShown(view.selection:IsShown())
    end
    AttachHotspot(sample.castHit, view.cast)
    AttachHotspot(sample.aurasHit, ShownRegion(view.auras))
    return true
end

local function PaintSample(sample, kind, state, elapsed, relayout, canvasWidth, nativeScale)
    if relayout then LayoutSample(sample, kind, state, canvasWidth, nativeScale) end
    local view = sample.view
    if not view:IsShown() then return false end
    local ratio = elapsed and .72 - (elapsed % 5) * .09 or .72
    local health = math.floor(1840 * ratio)
    local percent = math.floor(ratio * 100 + .5) .. "%"
    view.health:SetValue(ratio * 100)
    if sample.showHealthValue then
        view.healthText:SetText(health .. (sample.showHealthPercent and "  " .. percent or ""))
    elseif sample.showHealthPercent then
        view.healthText:SetText(percent)
    else
        view.healthText:SetText("")
    end
    local cast = elapsed and (elapsed % 2.5) / 2.5 or .55
    if view.cast:IsShown() then
        view.cast:SetValue(cast)
        view.castSpark:ClearAllPoints()
        view.castSpark:SetPoint("CENTER", view.cast, "LEFT", sample.castWidth * cast, 0)
    end
    local flashing = sample.threatFlash and elapsed and (elapsed % 1) < .22
    view.aggro:SetAlpha(flashing and 1 or .72)
    for i, aura in ipairs(view.auras) do
        if aura:IsShown() and aura.timer:IsShown() then
            local duration = auras[i].time
            local time = elapsed and duration - elapsed % duration or duration
            aura.timer:SetText(time >= 10 and string.format("%d", math.floor(time)) or string.format("%.1f", time))
        end
    end
    return true
end

local function SetAnimation(frame, on, draw)
    frame.elapsed, frame.nextPaint = 0, 0
    frame:SetScript("OnUpdate", on and function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= self.nextPaint then
            self.nextPaint = self.elapsed + .10
            draw(self.elapsed)
        end
    end or nil)
end

local function StartWorldTest(ui)
    local world = ui.world
    if not world then
        world = CreateFrame("Frame", "FluxOptionsNameplateWorldSample", UIParent)
        world:SetSize(240, 190)
        world:SetPoint("CENTER", UIParent, "CENTER", 0, 105)
        world:SetFrameStrata("DIALOG")
        world.sample = CreateSample(world)
        world:Hide()
        if UISpecialFrames then UISpecialFrames[#UISpecialFrames + 1] = world:GetName() end
        local stop = Button(world, L.npPreviewWorldStop, function()
            world:Hide()
            local shell = ns.FluxOptionsShell
            if shell then shell:Show(ui.pageId, ui.subKey) end
        end)
        stop:SetWidth(132)
        stop:SetPoint("BOTTOM")
        world:SetScript("OnHide", function(self)
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            SetAnimation(self, false)
        end)
        world:SetScript("OnEvent", function(self) self:Hide() end)
        ui.world = world
    end
    local kind, state = ui.hoverKind or editor.kind, ui.hoverState or ui.state
    if not PaintSample(world.sample, kind, state, nil, true, nil, true) then return end
    local shell = ns.FluxOptionsShell
    if shell then shell:Hide() end
    world:Show()
    world:RegisterEvent("PLAYER_ENTERING_WORLD")
    SetAnimation(world, true, function(elapsed)
        PaintSample(world.sample, kind, state, elapsed, false)
    end)
end

local function Dropdown(parent, label, items, onChange)
    local dropdown = W.CreateDropdown(parent)
    dropdown:SetLabel(label)
    dropdown:SetGetter(function() return items end)
    dropdown:SetOnChange(onChange)
    return dropdown
end

function Preview.Create(parent, onPart)
    local ui = CreateFrame("Frame", nil, parent)
    ui:SetAllPoints()
    ui.state = "overview"
    local title = Text(ui, "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText(L.npPreviewTitle)
    local hint = Text(ui, "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    hint:SetPoint("RIGHT", -8, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.npPreviewHint)
    hint:SetWordWrap(true)
    local canvas = CreateFrame("Frame", nil, ui)
    canvas:SetPoint("TOPLEFT", 4, -132)
    canvas:SetPoint("TOPRIGHT", -4, -132)
    local function SizeCanvas()
        canvas:SetHeight(math.max(105, math.min(162, ui:GetHeight() - 166)))
    end
    SizeCanvas()
    local message = Text(canvas)
    message:SetPoint("CENTER")
    ui.sample = CreateSample(canvas, onPart)

    local function Draw(elapsed, relayout)
        local kind = ui.hoverKind or editor.kind
        local visible = PaintSample(ui.sample, kind, ui.hoverState or ui.state, elapsed, relayout, canvas:GetWidth())
        message:SetText(L.npPreviewHidden)
        message:SetShown(not visible)
    end
    local kind = Dropdown(ui, L.npPreviewUnit, kindChoices, function(value)
        editor.kind = value
        Draw(nil, true)
        if FluxOptions and FluxOptions.RefreshOpenPage then FluxOptions:RefreshOpenPage() end
    end)
    kind:SetPoint("TOPLEFT", 0, -42)
    kind:SetPoint("RIGHT", 0, 0)
    local state = Dropdown(ui, L.npPreviewState, stateChoices, function(value)
        ui.state = value
        Draw(nil, true)
    end)
    state:SetPoint("TOPLEFT", kind, "BOTTOMLEFT", 0, -2)
    state:SetPoint("RIGHT", 0, 0)
    state:SetValue(ui.state)

    local animate = Button(ui, L.npPreviewAnimate)
    animate:SetPoint("TOPLEFT", canvas, "BOTTOMLEFT", 4, -6)
    animate:SetScript("OnClick", function(self)
        ui.animating = not ui.animating
        self:SetText(ui.animating and L.npPreviewPause or L.npPreviewAnimate)
        SetAnimation(ui, ui.animating, function(elapsed) Draw(elapsed, false) end)
        if not ui.animating then Draw(nil, true) end
    end)
    local test = Button(ui, L.npPreviewWorld, function() StartWorldTest(ui) end)
    test:SetPoint("TOPRIGHT", canvas, "BOTTOMRIGHT", -4, -6)
    test:SetScript("OnEnter", function(self) W.ShowTooltip(self, L.npPreviewWorld, L.npPreviewWorldHint) end)
    test:SetScript("OnLeave", W.HideTooltip)
    ui:SetScript("OnHide", function(self)
        self.animating, self.hoverState, self.hoverKind = false, nil, nil
        animate:SetText(L.npPreviewAnimate)
        SetAnimation(self, false)
    end)
    ui:SetScript("OnSizeChanged", function(self)
        SizeCanvas()
        if self.pageId and self:IsVisible() then Draw(nil, true) end
    end)
    function ui:Update(pageId, subKey, selectedPart)
        if self.world and self.world:IsShown() then self.world:Hide() end
        if self.subKey ~= subKey then self.hoverState, self.hoverKind = nil, nil end
        self.pageId, self.subKey = pageId, subKey
        kind:SetValue(editor.kind)
        self:SelectPart(selectedPart or subKey)
    end
    function ui:SelectPart(part)
        self.selectedPart = part
        SelectHotspot(self.sample.styleHit, part == "style")
        SelectHotspot(self.sample.levelHit, part == "extras")
        SelectHotspot(self.sample.questHit, part == "extras")
        SelectHotspot(self.sample.lootHit, part == "extras")
        SelectHotspot(self.sample.threatHit, part == "extras")
        SelectHotspot(self.sample.comboHit, part == "extras")
        SelectHotspot(self.sample.targetHit, part == "targeting")
        SelectHotspot(self.sample.castHit, part == "cast")
        SelectHotspot(self.sample.aurasHit, part == "auras")
        Draw(nil, true)
    end
    function ui:HoverSetting(key)
        local hover = key and hoverStates[key] or nil
        local kind
        if key and key:find("^aura_") then
            hover = "auras"
            if key:find("^aura_npc%u") then kind = "enemyNpc"
            elseif key:find("^aura_enemy%u") then kind = "enemyPlayer"
            elseif key:find("^aura_friendly%u") then kind = "friendlyPlayer" end
        elseif key == "questOverlayEnabled" or key == "npcThreatBorder" or key == "showNumericThreat" then
            kind = "enemyNpc"
        elseif key == "enemyPlayerTarget" then
            kind = "enemyPlayer"
        elseif key == "visible_friendlyNames" then
            kind = "friendlyPlayer"
        end
        if self.hoverState == hover and self.hoverKind == kind then return end
        self.hoverState, self.hoverKind = hover, kind
        Draw(nil, true)
    end
    return ui
end
