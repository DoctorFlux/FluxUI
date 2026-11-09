local addonName, ns = ...

-- Non-secure sample data, rendered with the live cell template and visual rules.

local max = math.max
local min = math.min
local floor = math.floor
local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end
local function PreviewUnitExists(unit)
    if type(unit) ~= "string" then return false end
    local exists = UnitExists(unit)
    return not IsSecret(exists) and exists and true or false
end

local GROUP_COUNT = 8
local GRP_SPACING = 0
local UNITS_PER_COLUMN = 5
local GROUP_LABEL_EXTRA = 14
local MTMA_UNITS_PER_COLUMN = 4
local MTMA_EXTRA_Y_FOR_FOUR_PLUS = 60
local PREVIEW_AURA_SLOTS = 6

local unitPool = {}
local labelPool = {}
local previewContainer = nil
local previewSessionVisible = false

local FAKE_ROSTER = {
    { name = "Aldric", class = "WARRIOR", role = "TANK", power = 1 },
    { name = "Brienna", class = "PRIEST", role = "HEALER", power = 0 },
    { name = "Cedric", class = "MAGE", role = "DAMAGER", power = 0 },
    { name = "Dara", class = "HUNTER", role = "DAMAGER", power = 0 },
    { name = "Eldon", class = "ROGUE", role = "DAMAGER", power = 3 },
    { name = "Fiona", class = "PALADIN", role = "HEALER", power = 0 },
    { name = "Gareth", class = "DEATHKNIGHT", role = "TANK", power = 6 },
    { name = "Helia", class = "SHAMAN", role = "HEALER", power = 0 },
    { name = "Ivor", class = "WARLOCK", role = "DAMAGER", power = 0 },
    { name = "Jessa", class = "MONK", role = "DAMAGER", power = 3 },
    { name = "Kael", class = "DEMONHUNTER", role = "DAMAGER", power = 17 },
    { name = "Liora", class = "DRUID", role = "HEALER", power = 0 },
    { name = "Merrick", class = "EVOKER", role = "DAMAGER", power = 0 },
    { name = "Nadia", class = "PRIEST", role = "HEALER", power = 0 },
    { name = "Orin", class = "MAGE", role = "DAMAGER", power = 0 },
    { name = "Petra", class = "HUNTER", role = "DAMAGER", power = 0 },
    { name = "Quinn", class = "WARRIOR", role = "DAMAGER", power = 1 },
    { name = "Rhea", class = "SHAMAN", role = "DAMAGER", power = 0 },
    { name = "Sten", class = "PALADIN", role = "TANK", power = 0 },
    { name = "Talia", class = "ROGUE", role = "DAMAGER", power = 3 },
    { name = "Ulric", class = "DEATHKNIGHT", role = "DAMAGER", power = 6 },
    { name = "Vera", class = "WARLOCK", role = "DAMAGER", power = 0 },
    { name = "Willem", class = "MONK", role = "HEALER", power = 3 },
    { name = "Xara", class = "DRUID", role = "DAMAGER", power = 0 },
    { name = "Yorick", class = "DEMONHUNTER", role = "TANK", power = 17 },
    { name = "Zola", class = "EVOKER", role = "HEALER", power = 0 },
    { name = "Astra", class = "PRIEST", role = "HEALER", power = 0 },
    { name = "Brock", class = "MAGE", role = "DAMAGER", power = 0 },
    { name = "Cora", class = "HUNTER", role = "DAMAGER", power = 0 },
    { name = "Drake", class = "SHAMAN", role = "DAMAGER", power = 0 },
    { name = "Elara", class = "PALADIN", role = "HEALER", power = 0 },
    { name = "Finn", class = "WARRIOR", role = "DAMAGER", power = 1 },
    { name = "Gwen", class = "ROGUE", role = "DAMAGER", power = 3 },
    { name = "Hugo", class = "WARLOCK", role = "DAMAGER", power = 0 },
    { name = "Iris", class = "MONK", role = "DAMAGER", power = 3 },
    { name = "Jace", class = "DEATHKNIGHT", role = "DAMAGER", power = 6 },
    { name = "Kira", class = "DRUID", role = "HEALER", power = 0 },
    { name = "Lorne", class = "HUNTER", role = "DAMAGER", power = 0 },
    { name = "Mira", class = "PRIEST", role = "DAMAGER", power = 0 },
    { name = "Nolan", class = "MAGE", role = "DAMAGER", power = 0 },
}


local DEMO_DEBUFFS = {
    { spellId = 589, name = "Shadow Word: Pain", dispelType = "Magic", previewDispellable = true },
    { spellId = 172, name = "Corruption", dispelType = "Magic", previewDispellable = true },
    { spellId = 55095, name = "Frost Fever", dispelType = "Disease", previewDispellable = true },
    { spellId = 3409, name = "Crippling Poison", dispelType = "Poison", previewDispellable = true },
    { spellId = 1079, name = "Rip", dispelType = "Bleed", previewDispellable = false },
    -- Synthetic sizing category; this does not classify a live spell as boss.
    { spellId = 589, name = "Large role debuff (preview)", previewBossOrRole = true },
}
-- These are curated synthetic examples, not a claim about the player's spells
-- or any member's actual auras. Strict demos never include the bleed example.
local DISPELLABLE_DEMO_DEBUFFS = {}
for _, example in ipairs(DEMO_DEBUFFS) do
    if example.previewDispellable then DISPELLABLE_DEMO_DEBUFFS[#DISPELLABLE_DEMO_DEBUFFS + 1] = example end
end
local DEMO_BUFFS = {
    { spellId = 139, name = "Renew" },
    { spellId = 10060, name = "Power Infusion" },
    { spellId = 774, name = "Rejuvenation" },
}

local function GetSpellIcon(spellId)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, tex = pcall(C_Spell.GetSpellTexture, spellId)
        if ok and tex and tex ~= "" then return tex end
    end
    if GetSpellTexture then
        local tex = GetSpellTexture(spellId)
        if tex and tex ~= "" then return tex end
    end
    return 136243
end

local function GetClassColor(classFile)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if c then return c.r, c.g, c.b end
    return 0.6, 0.6, 0.6
end

local function ApplyPreviewVisualLayout(frame, showPower)
    local height=frame._fluxRaidMini and FluxRaidVisuals.MINI_FRAME_HEIGHT or FluxRaidVisuals.FRAME_HEIGHT
    frame:SetSize(FluxRaidVisuals.FRAME_WIDTH,height)
    FluxRaidVisuals.ApplyCellChrome(frame, { showPower = showPower, height = height })
end

local function EnsurePreviewAuraIcons(frame)
    if frame._fluxRaidMini then return end
    if frame._fluxPreviewAuras then return end
    frame._fluxPreviewAuras = true
    frame._fluxAuraBuff, frame._fluxAuraDebuff = {}, {}
    local root = CreateFrame("Frame", nil, frame._fluxAuraLayer or frame._fluxTextLayer or frame._fluxContent or frame)
    root:SetAllPoints(frame._fluxAuraLayer or frame._fluxTextLayer or frame._fluxContent or frame)
    root:SetFrameLevel((frame:GetFrameLevel() or 0) + (FluxRaidVisuals.AURA_LAYER_OFFSET or 32))
    frame._fluxAuraRoot = root
    frame._fluxPreviewAuraRows = {}
    for _, key in ipairs({"buffs", "debuffs"}) do
        local row = CreateFrame("Frame", nil, root)
        row:EnableMouse(false); row:SetClipsChildren(true)
        frame._fluxPreviewAuraRows[key] = row
    end
    for i = 1, PREVIEW_AURA_SLOTS do
        local function make(side)
            local button = CreateFrame("Frame", nil, frame._fluxPreviewAuraRows[side])
            local icon = button:CreateTexture(nil, "ARTWORK")
            local backing = button:CreateTexture(nil, "BACKGROUND")
            backing:SetAllPoints(button); backing:SetColorTexture(.05, .04, .03, 1)
            icon:SetAllPoints(button)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            button.icon = icon
            local clock = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
            clock:SetAllPoints(button)
            if clock.EnableMouse then clock:EnableMouse(false) end
            if clock.SetDrawSwipe then clock:SetDrawSwipe(true) end
            if clock.SetSwipeTexture then clock:SetSwipeTexture("Interface\\Buttons\\WHITE8X8",0,0,0,1) end
            if clock.SetSwipeColor then clock:SetSwipeColor(0, 0, 0, FluxRaidVisuals.AURA_SWIPE_ALPHA or 0.75) end
            if clock.SetDrawEdge then clock:SetDrawEdge(false) end
            if clock.SetDrawBling then clock:SetDrawBling(false) end
            if clock.SetReverse then clock:SetReverse(true) end
            button.clock = clock
            local textLayer = CreateFrame("Frame", nil, button)
            textLayer:SetAllPoints(button)
            textLayer:EnableMouse(false)
            textLayer:SetFrameLevel(clock:GetFrameLevel() + 2)
            button.textLayer = textLayer
            if side == "debuffs" then FluxRaidVisuals.EnsurePartyDebuffBorder(button, frame) end
            local count = textLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
            button.count = count
            button:Hide()
            return button
        end
        frame._fluxAuraDebuff[i], frame._fluxAuraBuff[i] = make("debuffs"), make("buffs")
    end
end

local function LayoutPreviewAuraIcons(frame)
    local visual = FluxRaidVisuals
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
    local layout = visual.GetFrameAuraLayout(frame, db)
    local health = frame.healthBar or frame
    frame._fluxPreviewAuraMetrics = {
        width = layout.buffs.width, height = layout.buffs.height, gap = layout.buffs.gap,
        columns = layout.buffs.columns, rows = layout.buffs.rows,
        scale = layout.scale, requestedScale = layout.requestedScale,
        buffs = layout.buffs, debuffs = layout.debuffs,
        nativeDefaults = layout.nativeDefaults, largeIconSize = layout.largeIconSize,
    }
    for sideIndex = 1, 2 do
        local right = sideIndex == 1
        local side = right and layout.buffs or layout.debuffs
        local icons = right and frame._fluxAuraBuff or frame._fluxAuraDebuff
        local rowHost = frame._fluxPreviewAuraRows[right and "buffs" or "debuffs"]
        local auraParent, rowAnchor = visual.GetFrameAuraAnchor(frame, right)
        rowHost:ClearAllPoints(); rowHost:SetPoint(rowAnchor, auraParent, rowAnchor, 0, 0)
        rowHost:SetSize(side.blockWidth, side.blockHeight)
        for i = 1, PREVIEW_AURA_SLOTS do
            local button = icons[i]
            local index = min(i, side.count) - 1
            local column, row = floor(index / side.rows), index % side.rows
            local anchor = rowAnchor
            button:SetSize(side.width, side.height)
            button._fluxAuraRenderScale = layout.scale
            local count = button.count
            count:ClearAllPoints()
            if count.SetFontObject and NumberFontNormal then count:SetFontObject(NumberFontNormal)
            elseif count.SetFont then count:SetFont("Fonts\\ARIALN.TTF", 14, "") end
            if count.SetTextScale then count:SetTextScale(layout.scale) end
            count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2 * layout.scale, 2 * layout.scale)
            button:ClearAllPoints()
            button:SetPoint(anchor, rowHost, anchor, (anchor=="TOPRIGHT" and -1 or 1) * column * ((side.slotWidth or side.width) + side.gap), -row * ((side.slotHeight or side.height) + side.gap))
            if i > side.count then button:Hide() end
        end
    end
    return layout
end

local function DemoAuraDuration(button, index, member, frame)
    local duration = 9 + ((index * 7 + (member or 1) * 3) % 35)
    local clock = button.clock
    if clock.SetCountdownFormatter and FluxRaidVisuals.GetAuraDurationFormatter then clock:SetCountdownFormatter(FluxRaidVisuals.GetAuraDurationFormatter(nil, frame)) end
    if clock.SetCooldown then clock:SetCooldown(GetTime and GetTime() or 0, duration) end
    local text = clock.GetCountdownFontString and clock:GetCountdownFontString()
    if clock.SetHideCountdownNumbers then clock:SetHideCountdownNumbers(not text) end
    if not text then
        -- A plain synthetic label remains useful on a client lacking that native
        -- countdown accessor; the game still owns its visible cooldown swipe.
        if not button.duration then button.duration = button.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") end
        text = button.duration
        text:SetText(tostring(duration))
    end
    button.duration = text
    if text.SetParent and not button._fluxDurationLifted then
        text:SetParent(button.textLayer)
        button._fluxDurationLifted = true
    end
    local textWidth = (button.GetWidth and button:GetWidth() or 10) + 2
    local textHeight = button.GetHeight and button:GetHeight() or 15
    FluxRaidVisuals.StyleAuraDuration(text, textWidth - 2, textHeight, button._fluxAuraRenderScale or 1)
    text:ClearAllPoints()
    text:SetPoint("CENTER", button, "CENTER")
    button._fluxPreviewDuration = duration
    local applications = 1 + ((index + (member or 1)) % 3)
    button.count:SetText(applications > 1 and tostring(applications) or "")
    clock:Show()
end

local function GetPreviewAuraSettings()
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
    local flags = FluxRaidVisuals.GetFluxRaidOptionTable and FluxRaidVisuals.GetFluxRaidOptionTable() or db
    local focus = (FluxRaidVisuals and FluxRaidVisuals.GetAuraFocusMode and FluxRaidVisuals.GetAuraFocusMode())
        or db.auraFocusMode or "debuff"
    local defaultBuff = 6
    local defaultDebuff = 6
    return {
        demoBuffs = db.previewDemoBuffsEnabled ~= false,
        demoDebuffs = db.previewDemoDebuffsEnabled ~= false,
        displayBuffs = flags.displayBuffs ~= false,
        displayDebuffs = flags.displayDebuffs ~= false,
        onlyDispellable = flags.displayOnlyDispellableDebuffs == true,
        nBuff = max(0, min(tonumber(db.previewBuffCount) or defaultBuff, 6)),
        nDebuff = max(0, min(tonumber(db.previewDebuffCount) or defaultDebuff, 6)),
        focus = focus,
    }
end

local function PreviewRaidSetting(optionKey, cvar, fallback)
    if FluxRaidVisuals and FluxRaidVisuals.UseOwnRaidSettings
        and FluxRaidVisuals.UseOwnRaidSettings() then
        local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
        if db and db[optionKey] ~= nil then return db[optionKey] end
        return fallback
    end
    if type(fallback) == "string" then
        local value = C_CVar and C_CVar.GetCVar and C_CVar.GetCVar(cvar)
        return value ~= nil and value ~= "" and value or fallback
    end
    return not FluxRaid_GetCVarBool or FluxRaid_GetCVarBool(cvar, fallback)
end

local function ApplyDemoAuras(frame, idx)
    if frame._fluxRaidMini then return end
    EnsurePreviewAuraIcons(frame)
    local layout = LayoutPreviewAuraIcons(frame)
    local aur = GetPreviewAuraSettings()
    local alpha = FluxRaidVisuals.AURA_ICON_ALPHA or 1
    for i = 1, PREVIEW_AURA_SLOTS do
        if frame._fluxAuraDebuff[i] then frame._fluxAuraDebuff[i]:Hide() end
        if frame._fluxAuraBuff[i] then frame._fluxAuraBuff[i]:Hide() end
    end
    local showDebuffs = aur.demoDebuffs and aur.nDebuff > 0 and aur.displayDebuffs
    local showBuffs = aur.demoBuffs and aur.nBuff > 0 and aur.displayBuffs
    if showDebuffs then
        local examples = aur.onlyDispellable and DISPELLABLE_DEMO_DEBUFFS or DEMO_DEBUFFS
        for i = 1, min(layout.debuffs.count, aur.nDebuff) do
            local d = examples[((i - 1) % #examples) + 1]
            local btn = frame._fluxAuraDebuff[i]
            if btn then
                local size = layout.largeRoleEnabled and d.previewBossOrRole and layout.largeIconSize
                btn:SetSize(size and size * (layout.base.widthScale or 1) or layout.debuffs.width, size or layout.debuffs.height)
                btn.icon:SetTexture(GetSpellIcon(d.spellId))
                if btn._fluxPartyDebuffBorder then
                    FluxRaidVisuals.SetPartyDebuffBorderType(btn,d.dispelType)
                end
                DemoAuraDuration(btn, i, idx, frame)
                btn:SetAlpha(alpha)
                btn:Show()
            end
        end
    end
    if showBuffs then
        local rot = (idx or 1) * 2
        for i = 1, min(layout.buffs.count, aur.nBuff) do
            local b = DEMO_BUFFS[((i - 1 + rot) % #DEMO_BUFFS) + 1]
            local btn = frame._fluxAuraBuff[i]
            if btn then
                btn.icon:SetTexture(GetSpellIcon(b.spellId))
                DemoAuraDuration(btn, i, idx, frame)
                btn:SetAlpha(alpha)
                btn:Show()
            end
        end
    end
end

local function ApplyPreviewAlpha(frame, outOfRange)
    local base = FluxRaidVisuals.FRAME_BASE_ALPHA or 1
    if frame._fluxRaidMini and not frame._fluxExtraPet then (frame._fluxContent or frame):SetAlpha(base);return end
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    if db and db.showRangeFade == false then outOfRange = false end
    if outOfRange then
        (frame._fluxContent or frame):SetAlpha(base * (FluxRaidVisuals.RANGE_ALPHA_OUT_OF_RANGE or 0.44))
    else
        (frame._fluxContent or frame):SetAlpha(base * (FluxRaidVisuals.RANGE_ALPHA_IN_RANGE or 0.9))
    end
end

function FluxRaidPreviewUnit_OnLoad(self)
    self._fluxRaidPreview = true
    self._previewHover = false
    ApplyPreviewVisualLayout(self)
    EnsurePreviewAuraIcons(self)
    self:EnableMouse(true)
    self:RegisterForClicks()
end

local function AcquireUnit(i)
    local f = unitPool[i]
    if not f then
        f = CreateFrame("Button", "FluxRaidPreviewUnit" .. i, previewContainer, "FluxRaidPreviewUnitTemplate")
        unitPool[i] = f
    end
    f:SetParent(previewContainer)
    if f._fluxPreviewTarget then f._fluxPreviewTarget:Hide() end
    return f
end

local function AcquireLabel(i)
    local fs = labelPool[i]
    if not fs then
        fs = previewContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetShadowOffset(1, -1)
        labelPool[i] = fs
    end
    fs:ClearAllPoints()
    return fs
end

local function HideUnusedPool(usedUnits, usedLabels)
    for i = usedUnits + 1, #unitPool do
        local f = unitPool[i]
        if f and f.Hide then f:Hide() end
    end
    for i = usedLabels + 1, #labelPool do
        local fs = labelPool[i]
        if fs and fs.Hide then fs:Hide() end
    end
end

local function BuildPreviewRealUnitList()
    local list = {}
    if not IsInGroup() then return list end
    if IsInRaid() then
        for i = 1, 40 do
            local name = GetRaidRosterInfo(i)
            if IsSecret(name) or name and name ~= "" then
                list[#list + 1] = "raid" .. i
            end
        end
    else
        list[#list + 1] = "player"
        for i = 1, GetNumSubgroupMembers() do
            list[#list + 1] = "party" .. i
        end
    end
    return list
end

local function SyncPreviewTargetHighlight(frame)
    if not frame or not frame.selectionHighlight then return end
    local unit = frame._previewUnit
    if not unit or not PreviewUnitExists(unit) or not PreviewUnitExists("target") then
        frame.selectionHighlight:SetShown(not unit and frame._fluxPreviewState == 2
            and PreviewRaidSetting("showTargetHighlight", "raidFramesDisplayTargetHighlight", true) or false)
        return
    end
    local show = false
    if UnitIsUnit then
        local ok, v = pcall(UnitIsUnit, unit, "target")
        if ok and IsSecret(v) then
            frame.selectionHighlight:Show()
            if frame.selectionHighlight.SetAlphaFromBoolean then frame.selectionHighlight:SetAlphaFromBoolean(v, 1, 0) end
            return
        end
        show = ok and v
    end
    frame.selectionHighlight:SetAlpha(1)
    frame.selectionHighlight:SetShown(show)
end

function FluxRaidPreview_ApplyIdleHighlights(frame)
    if not frame or not frame._fluxRaidPreview then return end
    SyncPreviewTargetHighlight(frame)
    if frame.mouseOverHighlight then
        if frame._previewHover then
            frame.mouseOverHighlight:Show()
            frame.mouseOverHighlight:SetAlpha(1)
        elseif frame._previewIsPlayer then
            frame.mouseOverHighlight:Show()
            frame.mouseOverHighlight:SetAlpha(0.35)
        else
            frame.mouseOverHighlight:Hide()
        end
    end
end

local function ApplyCommonStatus(frame, classFile, nameText, hpPct, powerType, powerPct, role, idx, outOfRange)
    local showPower = PreviewRaidSetting("displayPowerBar", "raidFramesDisplayPowerBars", true)
    if frame._fluxRaidMini then showPower=false end
    ApplyPreviewVisualLayout(frame, showPower)
    local classColor = PreviewRaidSetting("useClassColors", "raidFramesDisplayClassColor", true)
    local r, g, b = 0, 1, 0
    if classColor and classFile then
        r, g, b = GetClassColor(classFile)
    end
    if frame.name then
        if not PreviewRaidSetting("showRoleIcon", "raidFramesDisplayRoleIcons", true) then role = nil end
        frame._fluxRole = role
        FluxRaidVisuals.SetUnitName(frame, nameText, role)
        if FluxRaid_ShouldClassColorNames and FluxRaid_ShouldClassColorNames() and classFile then
            local nr, ng, nb = GetClassColor(classFile)
            frame.name:SetVertexColor(nr, ng, nb)
        else
            frame.name:SetVertexColor(1, 1, 1)
        end
    end
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, 100)
        frame.healthBar:SetValue((hpPct or 1) * 100)
        local dim = FluxRaidVisuals.CLASS_FILL_BRIGHTNESS or 0.72
        frame.healthBar:SetStatusBarColor(r * dim, g * dim, b * dim)
    end
    local ht = PreviewRaidSetting("healthText", "raidFramesHealthText", "perc")
    FluxRaidVisuals.SetHealthStatus(frame, ht, math.floor((hpPct or 1)*100000), 100000, (hpPct or 1)*100, true, false)
    local pc = FluxRaidVisuals.POWER_COLORS and FluxRaidVisuals.POWER_COLORS[powerType or 0]
    if frame.powerBar then
        if showPower and pc then
            frame.powerBar:SetMinMaxValues(0, 100)
            frame.powerBar:SetValue((powerPct or 0.5) * 100)
            frame.powerBar:SetStatusBarColor(pc.r, pc.g, pc.b)
            frame.powerBar:Show()
        else
            frame.powerBar:Hide()
        end
    end
    ApplyPreviewAlpha(frame, outOfRange)
    ApplyDemoAuras(frame, idx)
    FluxRaidPreview_ApplyIdleHighlights(frame)
end

local function ClearDetailSamples(frame)
    if frame._fluxPreviewPrediction then
        for _, bar in pairs(frame._fluxPreviewPrediction) do bar:SetValue(0) bar:Hide() end
    end
    if frame._fluxPreviewCenter then frame._fluxPreviewCenter:Hide() end
    if frame._fluxPreviewDispel then frame._fluxPreviewDispel:Hide() end
    if frame._fluxPreviewOverflow then frame._fluxPreviewOverflow:Hide() end
    if frame.aggroHighlight then frame.aggroHighlight:Hide() end
end

local function EnsureDetailSamples(frame)
    if frame._fluxPreviewPrediction then return end
    local bars, health = {}, frame.healthBar
    local previous = health
    for _, spec in ipairs({ { "incoming", 0.35, 1, 0.35, 0.55 }, { "hot", 0.35, 1, 0.35, 0.55 }, { "absorb", 0.8, 0.9, 1, 0.8 } }) do
        local bar = CreateFrame("StatusBar", nil, health)
        bar:SetStatusBarTexture(spec[1] == "absorb" and "Interface\\RaidFrame\\Shield-Fill" or "Interface\\Buttons\\WHITE8X8")
        bar:SetStatusBarColor(spec[2], spec[3], spec[4], spec[5])
        bar:SetMinMaxValues(0, 100)
        bar:SetPoint("TOPLEFT", previous:GetStatusBarTexture(), "TOPRIGHT")
        bar:SetPoint("BOTTOMLEFT", previous:GetStatusBarTexture(), "BOTTOMRIGHT")
        bars[spec[1]], previous = bar, bar
    end
    local stripes = bars.absorb:CreateTexture(nil, "ARTWORK")
    stripes:SetAllPoints(bars.absorb:GetStatusBarTexture())
    stripes:SetTexture("Interface\\RaidFrame\\Shield-Overlay")
    if stripes.SetHorizTile then stripes:SetHorizTile(true) end
    if stripes.SetVertTile then stripes:SetVertTile(true) end
    if health.SetClipsChildren then health:SetClipsChildren(true) end
    frame._fluxPreviewPrediction = bars
    local root = frame._fluxTextLayer or frame._fluxContent or frame
    local centerHost = frame.centerStatusIcon or root
    local center = centerHost.texture or centerHost:CreateTexture(nil, "OVERLAY")
    center:ClearAllPoints()
    center:SetPoint("CENTER", frame._fluxContent or frame, "CENTER")
    center:SetSize(22 * (FluxRaidVisuals.COMPONENT_SCALE or 1), 22 * (FluxRaidVisuals.COMPONENT_SCALE or 1))
    if center.SetIgnoreParentAlpha then center:SetIgnoreParentAlpha(true) end
    frame._fluxPreviewCenter = center
    local dispel = CreateFrame("Frame", nil, root)
    dispel:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", 1, 1)
    dispel.icon = dispel:CreateTexture(nil, "ARTWORK")
    dispel.icon:SetAllPoints()
    dispel.icon:SetTexture("Interface\\Icons\\Spell_Frost_FrostNova")
    dispel.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame._fluxPreviewDispel = dispel
    local overflow = root:CreateTexture(nil, "OVERLAY")
    overflow:SetPoint("TOPRIGHT", health, "TOPRIGHT")
    overflow:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT")
    overflow:ClearAllPoints()
    overflow:SetPoint("TOPLEFT", health, "TOPRIGHT", -7, 0)
    overflow:SetPoint("BOTTOMLEFT", health, "BOTTOMRIGHT", -7, 0)
    overflow:SetWidth(16)
    if overflow.SetAtlas then overflow:SetAtlas("RaidFrame-Shield-Overshield", false) end
    if overflow.SetBlendMode then overflow:SetBlendMode("ADD") end
    frame._fluxPreviewOverflow = overflow
end

local function ApplyPreviewUnitFromToken(frame, unit, idx)
    if not frame or not PreviewUnitExists(unit) then return end
    ClearDetailSamples(frame)
    frame._fluxPreviewState = nil
    frame._previewHover, frame._previewUnit = false, unit
    local same = UnitIsUnit(unit, "player")
    frame._previewIsPlayer = not IsSecret(same) and same or nil
    local _, classFile = UnitClass(unit)
    if IsSecret(classFile) then classFile = nil end
    local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
    local hpPct = 1
    if not IsSecret(hp) and not IsSecret(hpMax) and type(hp) == "number" and type(hpMax) == "number" and hpMax > 0 then hpPct = hp / hpMax end
    local powerType = UnitPowerType(unit)
    if IsSecret(powerType) then powerType = 0 end
    local cur, maximum = UnitPower(unit), UnitPowerMax(unit)
    local powerPct = 0
    if not IsSecret(cur) and not IsSecret(maximum) and type(cur) == "number" and type(maximum) == "number" and maximum > 0 then powerPct = cur / maximum end
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
    if IsSecret(role) then role = nil end
    local previewName = UnitName(unit)
    local out = false
    if FluxRaidCompat and FluxRaidCompat.GetOutOfRange then
        out = FluxRaidCompat.GetOutOfRange({ unit = unit, displayedUnit = unit, optionTable = { fadeOutOfRange = true } })
        if IsSecret(out) then out = false end
    end
    ApplyCommonStatus(frame, classFile, previewName, hpPct, powerType, powerPct, role, idx, out)
    -- When values are opaque, the real widgets still consume them directly.
    frame.healthBar:SetMinMaxValues(0, hpMax)
    frame.healthBar:SetValue(hp)
    frame.powerBar:SetMinMaxValues(0, maximum)
    frame.powerBar:SetValue(cur)
    local connected = UnitIsConnected and UnitIsConnected(unit)
    local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)
    FluxRaidVisuals.SetHealthStatus(frame, PreviewRaidSetting("healthText", "raidFramesHealthText", "perc"), hp, hpMax,
        FluxRaidCompat and FluxRaidCompat.GetHealthPercent and FluxRaidCompat.GetHealthPercent(unit),
        connected, dead)
    if not IsSecret(connected) and connected == false then
        frame.name:SetTextColor(.55, .55, .55)
        frame.powerBar:SetStatusBarColor(.4, .4, .4)
    end
    if not IsSecret(connected) and connected == false or not IsSecret(dead) and dead then
        frame.healthBar:SetStatusBarColor(.22, .22, .22)
    end
end

local function ApplyFakeUnit(frame, data, idx)
    if not frame or not data then return end
    frame._previewUnit, frame._previewIsPlayer, frame._previewHover = nil, nil, false
    local state = ((idx or 1) - 1) % 10 + 1
    local pct = 0.42 + (idx % 5) * 0.10
    if state == 6 or state == 8 then pct = 0 end
    ApplyCommonStatus(frame, data.class, data.name .. "-" .. (idx or 1), pct, data.power or 0,
        0.4 + (idx % 5) * 0.1, data.role, idx, state == 5)
    EnsureDetailSamples(frame)
    ClearDetailSamples(frame)
    frame._fluxPreviewState = state
    local enabledPrediction = PreviewRaidSetting("showHealPrediction", "raidFramesDisplayHealPrediction", true)
    local samples = frame._fluxPreviewPrediction
    for _, bar in pairs(samples) do bar:SetWidth(FluxRaidVisuals.FRAME_WIDTH - 2 * FluxRaidVisuals.CELL_INSET) end
    if enabledPrediction and state == 1 then samples.incoming:SetValue(22) samples.incoming:Show() end
    if enabledPrediction and state == 2 then samples.hot:SetValue(18) samples.hot:Show() end
    if enabledPrediction and state == 3 then samples.absorb:SetValue(15) samples.absorb:Show() frame._fluxPreviewOverflow:Show() end
    if enabledPrediction and state == 10 then
        samples.incoming:SetValue(80) samples.incoming:Show()
        frame._fluxPreviewOverflow:SetVertexColor(1, 1, 1, 1)
        frame._fluxPreviewOverflow:Show()
    else
        frame._fluxPreviewOverflow:SetVertexColor(1, 1, 1, 1)
    end
    if state == 1 and frame.aggroHighlight and PreviewRaidSetting("showAggroHighlight", "raidFramesDisplayAggroHighlight", true) then frame.aggroHighlight:Show() end
    if state == 2 and frame.selectionHighlight and PreviewRaidSetting("showTargetHighlight", "raidFramesDisplayTargetHighlight", true) then frame.selectionHighlight:Show() end
    if state == 4 and GetPreviewAuraSettings().displayDebuffs then
        local side = frame._fluxPreviewAuraMetrics.debuffs
        frame._fluxPreviewDispel:SetSize(side.width, side.height)
        frame._fluxPreviewDispel:Show()
    end
    if state == 6 or state == 8 then frame.statusText:SetText(DEAD or "Dead") frame.statusText:Show() end
    if state == 7 then
        frame.statusText:SetText(PLAYER_OFFLINE or "Offline") frame.statusText:Show()
        frame.healthBar:SetStatusBarColor(0.22, 0.22, 0.22)
        frame.powerBar:SetStatusBarColor(.4, .4, .4)
        frame.name:SetTextColor(0.55, 0.55, 0.55)
    end
    if state == 8 or state == 9 then
        frame._fluxPreviewCenter:SetTexture(state == 8 and "Interface\\RaidFrame\\Raid-Icon-Rez" or "Interface\\RaidFrame\\Raid-Icon-SummonPending")
        frame._fluxPreviewCenter:Show()
    end
end

local function EnsureContainer()
    if previewContainer then return previewContainer end
    previewContainer = CreateFrame("Frame", "FluxRaidPreviewContainer", UIParent)
    previewContainer:Hide()
    return previewContainer
end

local function DistributeRaidMembers(n)
    local counts = { 0, 0, 0, 0, 0, 0, 0, 0 }
    local left = n
    for g = 1, GROUP_COUNT do
        local c = min(UNITS_PER_COLUMN, left)
        if c > 0 then
            counts[g] = c
            left = left - c
        end
        if left <= 0 then break end
    end
    return counts
end

local function LayoutPreview(n, showMT, mainTankCount)
    EnsureContainer()
    if not previewContainer then return 0, 0 end

    local Compat = FluxRaidCompat or {}
    local fw = FluxRaidVisuals.FRAME_WIDTH
    local fh = FluxRaidVisuals.FRAME_HEIGHT
    local colStep = fw + GRP_SPACING
    local counts = DistributeRaidMembers(n)
    local realUnits = BuildPreviewRealUnitList()
    local groupSlot = 0

    local visible = Compat.BuildVisibleGroupsReverse and Compat.BuildVisibleGroupsReverse(function(g)
        return (counts[g] or 0) > 0
    end)
    if not visible or #visible == 0 then
        visible = {}
        for g = GROUP_COUNT, 1, -1 do
            if counts[g] > 0 then
                visible[#visible + 1] = g
            end
        end
    end
    local k = #visible

    local mtCount = 0
    if showMT then
        local m = tonumber(mainTankCount) or 2
        mtCount = max(1, min(8, floor(m)))
    end

    local mtStackHeight = 0
    if showMT and mtCount >= 1 then
        mtStackHeight = min(4, mtCount) * FluxRaid_GetMTMAChildStep()
    end

    local colH = FluxRaid_GetColumnHeight()
    local yAlignMT = 0
    if showMT and mtCount >= 4 then
        yAlignMT = max(0, colH - mtStackHeight) + MTMA_EXTRA_Y_FOR_FOUR_PLUS
    end

    local layout = Compat.ComputeReverseColumnLayout and Compat.ComputeReverseColumnLayout(visible, showMT, mtCount, colStep, {
        groupCount = GROUP_COUNT,
        mtUnitsPerColumn = MTMA_UNITS_PER_COLUMN,
    })
    local totalSlots, x_lo, xMT
    if layout then
        totalSlots = layout.totalSlots
        x_lo = layout.x_lo
        xMT = layout.xMT
    else
        local mtSlotWidth = showMT and max(1, math.ceil(mtCount / MTMA_UNITS_PER_COLUMN)) or 0
        local mtColSlots = showMT and mtSlotWidth or 0
        local baseSlots = GROUP_COUNT + 1
        local usedSlots = mtColSlots + k
        totalSlots = max(baseSlots, usedSlots)
        local padSlots = max(0, totalSlots - usedSlots)
        x_lo = (k >= 1) and ((totalSlots - 1) * colStep) or nil
        xMT = (showMT and x_lo and k >= 1) and (padSlots * colStep) or 0
    end

    local u = 0
    local lb = 0

    if showMT and mtCount > 0 and x_lo and k >= 1 then
        for m = 1, mtCount do
            u = u + 1
            local fr = AcquireUnit(u)
            fr:ClearAllPoints()
            local col = floor((m - 1) / MTMA_UNITS_PER_COLUMN)
            local row = (m - 1) % MTMA_UNITS_PER_COLUMN
            local xCell = xMT + col * colStep
            local yCell = yAlignMT - row * FluxRaid_GetMTMAChildStep()
            fr:SetPoint("TOPLEFT", previewContainer, "TOPLEFT", xCell, yCell)
            ApplyFakeUnit(fr, { name = "MT" .. m, class = "WARRIOR", role = "TANK", power = 1 }, m)
            FluxRaidVisuals.SetJoinedEdges(fr, { bottom = false, right = true })
            local target=fr._fluxPreviewTarget
            if not target then
                target=CreateFrame("Button",nil,fr,"FluxRaidMiniPreviewTemplate")
                fr._fluxPreviewTarget=target
            end
            target:ClearAllPoints()
            target:SetPoint("TOPLEFT",fr,"BOTTOMLEFT",0,FluxRaidVisuals.CELL_JOIN_OVERLAP or 1)
            ApplyCommonStatus(target,nil,"Target "..m,.55+m*.03,0,0,nil,m,false)
            FluxRaidVisuals.SetJoinedEdges(target,{exteriorTop=false,exteriorLeft=true,bottom=m==mtCount or row==3,right=true})
            target:Show()
            fr:Show()
        end
        lb = lb + 1
        local lab = AcquireLabel(lb)
        lab:SetText("MT")
        lab:SetPoint("BOTTOM", previewContainer, "TOPLEFT", xMT + fw * 0.5, 4 + yAlignMT)
        lab:Show()
    end

    for gi = 1, GROUP_COUNT do
        local cnt = counts[gi]
        if cnt > 0 and x_lo and k >= 1 then
            local x = (layout and layout.groupX and layout.groupX[gi]) or nil
            if not x then
                x = x_lo
                for j = 1, k do
                    if visible[j] == gi then
                        x = x_lo - (k - j) * colStep
                        break
                    end
                end
            end
            lb = lb + 1
            local lab = AcquireLabel(lb)
            lab:SetText(tostring(gi))
            lab:SetPoint("BOTTOM", previewContainer, "TOPLEFT", x + fw * 0.5, 4)
            lab:Show()
            for row = 1, cnt do
                u = u + 1
                local fr = AcquireUnit(u)
                fr:ClearAllPoints()
                local y = -((row - 1) * (fh - (FluxRaidVisuals.CELL_JOIN_OVERLAP or FluxRaidCompat.HEADER_UNIT_YOFFSET or 4)))
                fr:SetPoint("TOPLEFT", previewContainer, "TOPLEFT", x, y)
                local idx = 0
                for gg = 1, gi - 1 do
                    idx = idx + counts[gg]
                end
                idx = idx + row
                local data = FAKE_ROSTER[((idx - 1) % #FAKE_ROSTER) + 1]
                groupSlot = groupSlot + 1
                local tok = realUnits[groupSlot]
                if tok and PreviewUnitExists(tok) then
                    ApplyPreviewUnitFromToken(fr, tok, idx)
                else
                    ApplyFakeUnit(fr, data, idx)
                end
                local rightGroup, leftGroup
                for previous = gi - 1, 1, -1 do
                    if counts[previous] > 0 then rightGroup = previous break end
                end
                for following = gi + 1, GROUP_COUNT do
                    if counts[following] > 0 then leftGroup = following break end
                end
                FluxRaidVisuals.SetJoinedEdges(fr, {
                    exteriorTop = row == 1,
                    exteriorLeft = not (leftGroup and counts[leftGroup] >= row),
                    bottom = row == cnt,
                    right = not (rightGroup and counts[rightGroup] >= row),
                })
                fr:Show()
            end
        end
    end

    previewContainer:SetWidth(totalSlots * colStep)
    previewContainer:SetHeight(colH + GROUP_LABEL_EXTRA)
    return u, lb
end

function FluxRaidPreview_RefreshLayout()
    EnsureContainer()
    if not FluxOptions or not FluxOptions.GetRaidFrameDB then return end
    if not previewSessionVisible then
        previewContainer:Hide()
        return
    end
    local db = FluxOptions:GetRaidFrameDB()
    if FluxRaidVisuals and FluxRaidVisuals.ApplyRaidFrameTunables then
        FluxRaidVisuals.ApplyRaidFrameTunables(db)
    end
    local n = tonumber(db.previewRosterSize) or 40
    n = max(5, min(40, floor(n / 5) * 5))
    db.previewRosterSize = n
    if ns.PartyFrames and ns.PartyFrames.RefreshPreview then
        local party = db.partyAsRaid == false and n == 5
        ns.PartyFrames.RefreshPreview(party)
        if party then previewContainer:Hide(); return end
    end
    local showMT = db.previewShowMTColumn ~= false
    local mtN = tonumber(db.previewMainTankCount)
    if not mtN or mtN < 1 then mtN = 2 end
    db.previewMainTankCount = max(1, min(8, floor(mtN)))

    local u, lb = LayoutPreview(n, showMT, showMT and db.previewMainTankCount or 0)
    HideUnusedPool(u, lb)

    local yBottom = FluxRaid_GetPreviewStackVerticalPosition and FluxRaid_GetPreviewStackVerticalPosition() or 120
    previewContainer:SetFrameStrata("MEDIUM")
    previewContainer:SetFrameLevel(25)
    previewContainer:ClearAllPoints()
    previewContainer:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, yBottom)
    previewContainer:Show()
end

FluxRaidPreview = FluxRaidPreview or {}

function FluxRaidPreview.PaintPartyAuras(frame, index)
    EnsurePreviewAuraIcons(frame)
    ApplyDemoAuras(frame, index)
    if ns and ns.UnitFrames and ns.UnitFrames.PreviewDebuffTint then
        local icon = frame._fluxAuraDebuff and frame._fluxAuraDebuff[1]
        ns.UnitFrames.PreviewDebuffTint(frame, icon and icon:IsShown() and "Magic" or nil)
    end
end

function FluxRaidPreview.Show()
    EnsureContainer()
    if InCombatLockdown() then
        print("|cffff8800[FluxUI]|r Raid preview cannot be shown during combat.|r")
        return
    end
    previewSessionVisible = true
    FluxRaidPreview_RefreshLayout()
end

function FluxRaidPreview.Hide()
    previewSessionVisible = false
    if ns.PartyFrames and ns.PartyFrames.RefreshPreview then ns.PartyFrames.RefreshPreview(false) end
    if previewContainer then
        previewContainer:Hide()
    end
end

function FluxRaidPreview.Toggle()
    if previewSessionVisible then
        FluxRaidPreview.Hide()
    else
        FluxRaidPreview.Show()
    end
end

function FluxRaidPreview.IsPartyShown()
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    return previewSessionVisible and db and tonumber(db.previewRosterSize) == 5 or false
end

function FluxRaidPreview.ToggleParty()
    if FluxRaidPreview.IsPartyShown() then FluxRaidPreview.Hide(); return end
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    if db then db.previewRosterSize = 5 end
    FluxRaidPreview.Show()
end

function FluxRaidPreview.RefreshFromOptions()
    EnsureContainer()
    if previewSessionVisible then
        FluxRaidPreview_RefreshLayout()
    end
end

_G.FluxRaidPreview = FluxRaidPreview

function FluxRaidPreviewUnit_OnEnter(self)
    self._previewHover = true
    if self.mouseOverHighlight then
        self.mouseOverHighlight:Show()
        self.mouseOverHighlight:SetAlpha(1)
    end
    if self._previewUnit and PreviewUnitExists(self._previewUnit) then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetUnit(self._previewUnit)
        GameTooltip:Show()
    else
        GameTooltip:Hide()
    end
end

function FluxRaidPreviewUnit_OnLeave(self)
    self._previewHover = false
    GameTooltip:Hide()
    FluxRaidPreview_ApplyIdleHighlights(self)
end

local previewCvarListener = CreateFrame("Frame")
previewCvarListener:RegisterEvent("CVAR_UPDATE")
previewCvarListener:SetScript("OnEvent", function(_, _, cvarName)
    if not cvarName or type(cvarName) ~= "string" then return end
    if not previewSessionVisible then return end
    if cvarName:match("^raidFrames") or cvarName:match("^raidOption") then
        -- Defer past Blizzard CUF CVar â†’ ApplyCurrentSettings (same CVAR_UPDATE wave).
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if previewContainer and previewContainer:IsShown() then
                    FluxRaidPreview_RefreshLayout()
                end
            end)
        else
            FluxRaidPreview_RefreshLayout()
        end
    end
end)

local previewSessionListener = CreateFrame("Frame")
previewSessionListener:RegisterEvent("PLAYER_LOGIN")
previewSessionListener:RegisterEvent("PLAYER_REGEN_DISABLED")
previewSessionListener:RegisterEvent("PLAYER_TARGET_CHANGED")
previewSessionListener:RegisterEvent("GROUP_ROSTER_UPDATE")
previewSessionListener:SetScript("OnEvent", function(_, ev)
    if ev == "PLAYER_REGEN_DISABLED" then
        FluxRaidPreview.Hide()
    elseif ev == "PLAYER_LOGIN" then
        FluxRaidPreview.Hide()
        previewSessionVisible = false
        if previewContainer then previewContainer:Hide() end
        local d = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
        if d then
            if d.previewVisible ~= nil then d.previewVisible = nil end
            if d.bigDebuffsEnabled ~= nil then d.bigDebuffsEnabled = nil end
        end
    elseif ev == "PLAYER_TARGET_CHANGED" then
        for i = 1, #unitPool do
            local f = unitPool[i]
            if f and f:IsShown() and f._fluxRaidPreview then
                FluxRaidPreview_ApplyIdleHighlights(f)
            end
        end
    elseif ev == "GROUP_ROSTER_UPDATE" then
        if previewSessionVisible then
            FluxRaidPreview_RefreshLayout()
        end
    end
end)

