local addonName, ns = ...

-- World preview of Flux raid layout (non-secure). Sizing matches live headers; demo auras are simple icons.

local max = math.max
local min = math.min
local floor = math.floor

local GROUP_COUNT = 8
local GRP_SPACING = 2
local HEADER_UNIT_YOFFSET = -1
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

local ROLE_ATLAS = {
    TANK = "roleicon-tiny-tank",
    HEALER = "roleicon-tiny-healer",
    DAMAGER = "roleicon-tiny-dps",
}

local DEMO_DEBUFFS = {
    { spellId = 589, name = "Shadow Word: Pain" },
    { spellId = 172, name = "Corruption" },
    { spellId = 55095, name = "Frost Fever" },
    { spellId = 3409, name = "Crippling Poison" },
    { spellId = 1079, name = "Rip" },
}
local DEMO_BUFFS = {
    { spellId = 21562, name = "Power Word: Fortitude" },
    { spellId = 1459, name = "Arcane Intellect" },
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

local function ApplyPreviewVisualLayout(frame)
    if FluxRaidVisuals.ApplyCellChrome then
        FluxRaidVisuals.ApplyCellChrome(frame, { showPower = true })
    end
    local fw = FluxRaidVisuals.FRAME_WIDTH
    local fh = FluxRaidVisuals.FRAME_HEIGHT
    local pbh = tonumber(FluxRaidVisuals.POWER_BAR_HEIGHT) or 6
    frame:SetSize(fw, fh)
    if frame.background then
        frame.background:SetColorTexture(0.1, 0.1, 0.12, 1)
    end
    if frame.healthBar then
        frame.healthBar:ClearAllPoints()
        frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1 + pbh)
        if frame.healthBar.SetStatusBarTexture then
            pcall(frame.healthBar.SetStatusBarTexture, frame.healthBar, "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
        end
        if frame.healthBar.background then
            frame.healthBar.background:SetColorTexture(0.15, 0.15, 0.17, 1)
        end
    end
    if frame.powerBar then
        frame.powerBar:ClearAllPoints()
        frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, 0)
        frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        frame.powerBar:SetHeight(pbh)
        if frame.powerBar.SetStatusBarTexture then
            pcall(frame.powerBar.SetStatusBarTexture, frame.powerBar, "Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
        end
    end
    if frame.name then
        frame.name:ClearAllPoints()
        frame.name:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -2)
        frame.name:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -2)
        frame.name:SetJustifyH("LEFT")
    end
    if frame.statusText then
        frame.statusText:ClearAllPoints()
        frame.statusText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, fh / 3 - 2)
        frame.statusText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, fh / 3 - 2)
    end
    if frame.roleIcon then
        frame.roleIcon:ClearAllPoints()
        frame.roleIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        frame.roleIcon:SetSize(FluxRaidVisuals.ROLE_ICON_SIZE or 14, FluxRaidVisuals.ROLE_ICON_SIZE or 14)
    end
    if frame.selectionHighlight then
        pcall(frame.selectionHighlight.SetAtlas, frame.selectionHighlight, "RaidFrame-TargetFrame")
    end
    if frame.mouseOverHighlight then
        pcall(frame.mouseOverHighlight.SetAtlas, frame.mouseOverHighlight, "RaidFrame-TargetFrame")
    end
    if FluxRaidVisuals.ApplyRaidHighlightVertexColors then
        FluxRaidVisuals.ApplyRaidHighlightVertexColors(frame)
    end
end

local function EnsurePreviewAuraIcons(frame)
    if frame._fluxPreviewAuras then return end
    frame._fluxPreviewAuras = true
    frame._fluxAuraBuff = {}
    frame._fluxAuraDebuff = {}
    local root = CreateFrame("Frame", nil, frame)
    root:SetAllPoints()
    root:SetFrameLevel((frame:GetFrameLevel() or 0) + 20)
    frame._fluxAuraRoot = root
    local aw = FluxRaidVisuals.AURA_ICON_WIDTH or 10
    local ah = FluxRaidVisuals.AURA_ICON_HEIGHT or 15
    for i = 1, PREVIEW_AURA_SLOTS do
        local function make(isDebuff)
            local b = CreateFrame("Frame", nil, root)
            b:SetSize(aw, ah)
            local icon = b:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints()
            b.icon = icon
            b:Hide()
            return b
        end
        frame._fluxAuraDebuff[i] = make(true)
        frame._fluxAuraBuff[i] = make(false)
    end
end

local function LayoutPreviewAuraIcons(frame)
    local aw = FluxRaidVisuals.AURA_ICON_WIDTH or 10
    local ah = FluxRaidVisuals.AURA_ICON_HEIGHT or 15
    local gap = 1
    local focus = (FluxRaidVisuals and FluxRaidVisuals.GetAuraFocusMode and FluxRaidVisuals.GetAuraFocusMode()) or "debuff"
    for i = 1, PREVIEW_AURA_SLOTS do
        local row = floor((i - 1) / 3)
        local col = (i - 1) % 3
        local d = frame._fluxAuraDebuff[i]
        local b = frame._fluxAuraBuff[i]
        if d then
            d:SetSize(aw, ah)
            d:ClearAllPoints()
            if focus == "buff" then
                -- BuffsTopDebuffsBottom: debuffs bottom-right
                d:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(col * (aw + gap) + 1), row * (ah + gap) + 2)
            else
                -- Legacy debuff-focused: debuffs bottom-left
                d:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", col * (aw + gap) + 1, row * (ah + gap) + 2)
            end
        end
        if b then
            b:SetSize(aw, ah)
            b:ClearAllPoints()
            if focus == "buff" then
                -- Buffs along top-right
                b:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(col * (aw + gap) + 1), -(row * (ah + gap) + 2))
            else
                -- Legacy: buffs bottom-right
                b:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(col * (aw + gap) + 1), row * (ah + gap) + 2)
            end
        end
    end
end

local function GetPreviewAuraSettings()
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
    local focus = (FluxRaidVisuals and FluxRaidVisuals.GetAuraFocusMode and FluxRaidVisuals.GetAuraFocusMode())
        or db.auraFocusMode or "debuff"
    local defaultBuff = (focus == "buff") and 6 or 3
    local defaultDebuff = (focus == "buff") and 3 or 5
    return {
        demoBuffs = db.previewDemoBuffsEnabled ~= false,
        demoDebuffs = db.previewDemoDebuffsEnabled ~= false,
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
    EnsurePreviewAuraIcons(frame)
    LayoutPreviewAuraIcons(frame)
    local aur = GetPreviewAuraSettings()
    local alpha = FluxRaidVisuals.AURA_ICON_ALPHA or 1
    for i = 1, PREVIEW_AURA_SLOTS do
        if frame._fluxAuraDebuff[i] then frame._fluxAuraDebuff[i]:Hide() end
        if frame._fluxAuraBuff[i] then frame._fluxAuraBuff[i]:Hide() end
    end
    local showDebuffs = aur.demoDebuffs and aur.nDebuff > 0
        and PreviewRaidSetting("displayDebuffs", "raidFramesDisplayDebuffs", true)
    local showBuffs = aur.demoBuffs and aur.nBuff > 0
        and PreviewRaidSetting("displayBuffs", "raidFramesDisplayBuffs", true)
    if showDebuffs then
        for i = 1, min(PREVIEW_AURA_SLOTS, aur.nDebuff) do
            local d = DEMO_DEBUFFS[((i - 1) % #DEMO_DEBUFFS) + 1]
            local btn = frame._fluxAuraDebuff[i]
            if btn then
                btn.icon:SetTexture(GetSpellIcon(d.spellId))
                btn:SetAlpha(alpha)
                btn:Show()
            end
        end
    end
    if showBuffs then
        local rot = (idx or 1) * 2
        for i = 1, min(PREVIEW_AURA_SLOTS, aur.nBuff) do
            local b = DEMO_BUFFS[((i - 1 + rot) % #DEMO_BUFFS) + 1]
            local btn = frame._fluxAuraBuff[i]
            if btn then
                btn.icon:SetTexture(GetSpellIcon(b.spellId))
                btn:SetAlpha(alpha)
                btn:Show()
            end
        end
    end
end

local function ApplyPreviewAlpha(frame, outOfRange)
    local base = FluxRaidVisuals.FRAME_BASE_ALPHA or 1
    if outOfRange then
        frame:SetAlpha(base * (FluxRaidVisuals.RANGE_ALPHA_OUT_OF_RANGE or 0.44))
    else
        frame:SetAlpha(base * (FluxRaidVisuals.RANGE_ALPHA_IN_RANGE or 0.9))
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
            if name and name ~= "" then
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
    if not unit or not UnitExists(unit) or not UnitExists("target") then
        frame.selectionHighlight:Hide()
        return
    end
    local show = false
    if UnitIsUnit then
        local ok, v = pcall(UnitIsUnit, unit, "target")
        show = ok and v
    end
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
    ApplyPreviewVisualLayout(frame)
    local classColor = PreviewRaidSetting("useClassColors", "raidFramesDisplayClassColor", true)
    local r, g, b = 0, 1, 0
    if classColor and classFile then
        r, g, b = GetClassColor(classFile)
    end
    if frame.name then
        frame.name:SetText(nameText or "")
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
        frame.healthBar:SetStatusBarColor(r, g, b)
    end
    local ht = PreviewRaidSetting("healthText", "raidFramesHealthText", "perc")
    if frame.statusText then
        if ht == "none" then
            frame.statusText:SetText("")
            frame.statusText:Hide()
        else
            frame.statusText:Show()
            frame.statusText:SetText(string.format("%.0f%%", (hpPct or 1) * 100))
        end
    end
    local showPower = PreviewRaidSetting("displayPowerBar", "raidFramesDisplayPowerBars", true)
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
    local atlas = role and ROLE_ATLAS[role]
    if frame.roleIcon then
        if atlas then
            frame.roleIcon:Show()
            pcall(frame.roleIcon.SetAtlas, frame.roleIcon, atlas)
        else
            frame.roleIcon:Hide()
        end
    end
    ApplyPreviewAlpha(frame, outOfRange)
    ApplyDemoAuras(frame, idx)
    FluxRaidPreview_ApplyIdleHighlights(frame)
end

local function ApplyPreviewUnitFromToken(frame, unit, idx)
    if not frame or not unit or not UnitExists(unit) then return end
    frame._previewHover = false
    frame._previewUnit = unit
    frame._previewIsPlayer = UnitIsUnit(unit, "player") and true or nil
    local _, classFile = UnitClass(unit)
    local hpMax = max(1, UnitHealthMax(unit))
    local hp = UnitHealth(unit)
    local out = false
    local a = ns and ns.API
    if a and a.UnitInRangeSafe then
        local inRange, checked = a.UnitInRangeSafe(unit)
        out = checked and (inRange == false)
    elseif FluxRaidCompat and FluxRaidCompat.GetOutOfRange then
        -- Frame-shaped probe for shared helper
        local probe = { unit = unit, displayedUnit = unit, optionTable = { fadeOutOfRange = true } }
        out = FluxRaidCompat.GetOutOfRange(probe)
    elseif UnitInRange then
        local ok, inRange, checked = pcall(UnitInRange, unit)
        out = ok and checked and (inRange == false)
    end
    local powerType = UnitPowerType and UnitPowerType(unit) or 0
    local cur = UnitPower(unit) or 0
    local maxp = max(1, UnitPowerMax(unit) or 1)
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
    local previewName = UnitName(unit)
    local PN = _G.Flux and _G.Flux.PlayerName
    if PN and PN.GetDisplayName then
        previewName = PN.GetDisplayName(unit, true) or previewName
    end
    ApplyCommonStatus(frame, classFile, previewName, hp / hpMax, powerType, cur / maxp, role, idx, out)
end

local function ApplyFakeUnit(frame, data, idx)
    if not frame or not data then return end
    frame._previewUnit = nil
    frame._previewIsPlayer = nil
    frame._previewHover = false
    local pct = 0.55 + (idx % 7) * 0.06
    local out = (idx % 9 == 0)
    ApplyCommonStatus(frame, data.class, data.name .. "-" .. (idx or 1), pct, data.power or 0, 0.4 + (idx % 5) * 0.1, data.role, idx, out)
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
                local y = -((row - 1) * (fh + HEADER_UNIT_YOFFSET))
                fr:SetPoint("TOPLEFT", previewContainer, "TOPLEFT", x, y)
                local idx = 0
                for gg = 1, gi - 1 do
                    idx = idx + counts[gg]
                end
                idx = idx + row
                local data = FAKE_ROSTER[((idx - 1) % #FAKE_ROSTER) + 1]
                groupSlot = groupSlot + 1
                local tok = realUnits[groupSlot]
                if tok and UnitExists(tok) then
                    ApplyPreviewUnitFromToken(fr, tok, idx)
                else
                    ApplyFakeUnit(fr, data, idx)
                end
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
    if self._previewUnit and UnitExists(self._previewUnit) then
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
    if not previewContainer or not previewContainer:IsShown() then return end
    if cvarName:match("^raidFrames") or cvarName:match("^raidOption") then
        -- Defer past Blizzard CUF CVar → ApplyCurrentSettings (same CVAR_UPDATE wave).
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
previewSessionListener:RegisterEvent("PLAYER_TARGET_CHANGED")
previewSessionListener:RegisterEvent("GROUP_ROSTER_UPDATE")
previewSessionListener:SetScript("OnEvent", function(_, ev)
    if ev == "PLAYER_LOGIN" then
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

