-- Settings-only samples. These buttons open editors and have no unit attributes.
local _, ns = ...
local W = ns.FluxOptionsWidgets
local Preview = {}
ns.FluxOptionsFramePreview = Preview

ns.FluxOptionsLocale = ns.FluxOptionsLocale or {}
local L = ns.FluxOptionsLocale
local english = {
    framePreviewTitle = "Frame Preview",
    framePreviewHint = "Click a frame part to edit it.",
    framePreviewNormalParty = "Player-style party",
    framePreviewCompactParty = "Compact party",
    framePreviewRaidSize = "%d raid members",
    framePreviewDefaultFrames = "Flux frames disabled",
    framePreviewSample = "%s sample",
    framePreviewPet = "Pet",
    framePreviewTargetOfTarget = "Target of target",
    framePreviewFocusTarget = "Focus target",
    framePreviewPetTarget = "Pet target",
    framePreviewPlayer = "Player",
    framePreviewTarget = "Target",
    framePreviewFocus = "Focus",
    framePreviewLayout = "Layout",
    framePreviewName = "Name",
    framePreviewHealth = "Health",
    framePreviewPower = "Power",
    framePreviewPortrait = "Portrait",
    framePreviewBuffs = "Buffs",
    framePreviewDebuffs = "Debuffs",
    framePreviewAuras = "Auras",
    framePreviewCast = "Cast bar",
    framePreviewIndicators = "Indicators",
    framePreviewAttached = "Pet / Target",
    framePreviewScope = "Scope",
    framePreviewOpacity = "Opacity",
    framePreviewExtras = "Extras",
    framePreviewPreview = "Preview setup",
    framePreviewAbsorbs = "Heals and absorbs",
    framePreviewClassResource = "Class resource",
    framePreviewUnavailable = "Preview unavailable",
    framePreviewAfterCombat = "Frame preview resumes after combat.",
    framePreviewCaseDefault = "Default",
    framePreviewCasePlayer = "Player",
    framePreviewCaseFriendly = "Friendly NPC",
    framePreviewCaseHostile = "Hostile NPC",
    framePreviewCaseAuras = "Buffs and debuffs",
    framePreviewCaseEffects = "Combat effects",
    framePreviewPlay = "Play",
    framePreviewPlayTip = "Play the effects for this sample.",
}
for key, value in pairs(english) do
    if not L[key] then L[key] = value end
end

local units = {
    unitPlayer = { unit = "player", label = "Player" },
    unitTarget = { unit = "target", label = "Target" },
    unitFocus = { unit = "focus", label = "Focus" },
    unitPet = { unit = "pet", label = "Pet", owner = "Player" },
    unitTargetOfTarget = { unit = "targettarget", label = "TargetOfTarget", owner = "Target" },
    unitFocusTarget = { unit = "focustarget", label = "FocusTarget", owner = "Focus" },
    unitPetTarget = { unit = "pettarget", label = "PetTarget", owner = "Player" },
}
local partLabels = {
    layout = "Layout", name = "Name", health = "Health", power = "Power", portrait = "Portrait",
    buffs = "Buffs", debuffs = "Debuffs", auras = "Auras", cast = "Cast", indicators = "Indicators",
    attached = "Attached", scope = "Scope", opacity = "Opacity", extras = "Extras", preview = "Preview",
    absorbs = "Absorbs", classResource = "ClassResource",
}
local miniParts = { "layout", "health", "power", "absorbs", "indicators" }
local unitParts = {
    unitPlayer = { "layout", "portrait", "name", "health", "power", "classResource", "absorbs", "cast", "indicators", "extras" },
    unitTarget = { "layout", "portrait", "name", "health", "power", "absorbs", "cast", "indicators", "buffs", "debuffs", "attached" },
    unitFocus = { "layout", "portrait", "name", "health", "power", "absorbs", "cast", "indicators", "buffs", "debuffs", "attached" },
    unitPet = { "layout", "portrait", "health", "power", "absorbs", "cast", "indicators", "auras", "attached" },
    unitTargetOfTarget = miniParts, unitFocusTarget = miniParts, unitPetTarget = miniParts,
}
local generalParts = { "scope", "layout", "portrait", "health", "power", "auras", "indicators" }
local partyParts = { "layout", "portrait", "name", "health", "power", "cast", "auras", "indicators", "attached", "preview" }
local compactParts = { "layout", "name", "health", "power", "absorbs", "buffs", "debuffs", "auras", "indicators", "attached", "opacity" }
local raidParts = { "layout", "name", "health", "power", "absorbs", "buffs", "debuffs", "auras", "indicators", "attached", "opacity", "preview" }
local defaultCase = { value = "default", text = L.framePreviewCaseDefault }
local auraCase = { value = "auras", text = L.framePreviewCaseAuras }
local combatCase = { value = "effects", text = L.framePreviewCaseEffects }
local playerCase = { value = "player", text = L.framePreviewCasePlayer }
local friendlyCase = { value = "friendlyNPC", text = L.framePreviewCaseFriendly }
local hostileCase = { value = "hostileNPC", text = L.framePreviewCaseHostile }
local targetCases = { defaultCase, playerCase, friendlyCase, hostileCase, auraCase, combatCase }
local attachmentCases = { defaultCase, playerCase, friendlyCase, hostileCase, combatCase }
local previewCases = {
    player = { defaultCase, combatCase },
    target = targetCases,
    focus = targetCases,
    pet = { defaultCase, auraCase, combatCase },
}

local function Limit(value, low, high, fallback)
    value = tonumber(value) or fallback
    if value ~= value then value = fallback end
    return math.max(low, math.min(high, value))
end

local function Label(part)
    if units[part] then return L["framePreview" .. units[part].label] end
    return L["framePreview" .. partLabels[part]]
end

local function Position(region, relative, x, y, width, height)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", relative, "TOPLEFT", x, -y)
    region:SetSize(width, height)
end

local function Fill(parent, layer)
    local texture = parent:CreateTexture(nil, layer)
    texture:SetAllPoints(parent)
    return texture
end

local function Text(parent, font)
    local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    text:SetWordWrap(false)
    return text
end

local function PaintButton(button, selected)
    local r, g, b = W.Accent()
    local alpha = selected and .6 or button.hovered and .32 or 0
    if button.previewHit then alpha = button.hovered and .20 or 0 end
    W.Solid(button.overlay, r, g, b, alpha)
    if button.label then
        button.label:SetTextColor(selected and r or .91, selected and g or .90, selected and b or .86)
    end
end

local function NewButton(ui, parent)
    local button = CreateFrame("Button", nil, parent)
    button.overlay = Fill(button, "OVERLAY")
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", function(self)
        W.HideTooltip()
        if units[self.part] then
            ui.onUnit(self.part, "layout")
        elseif self.part then
            ui.onPart(self.part, self.destination)
        end
    end)
    button:SetScript("OnEnter", function(self)
        self.hovered = true
        PaintButton(self, self.selected)
        if self.part then W.ShowTooltip(self, Label(self.part), L.framePreviewHint) end
    end)
    button:SetScript("OnLeave", function(self)
        self.hovered = false
        PaintButton(self, self.selected)
        W.HideTooltip()
    end)
    button:SetScript("OnHide", function(self)
        self.hovered = nil
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then W.HideTooltip() end
    end)
    return button
end

local function SetPart(ui, button, part, destination)
    button.part, button.destination = part, destination
    button.selected = ui.selectedPart == part and not destination
    PaintButton(button, button.selected)
    button:Show()
end

local function CurrentSettings()
    local options = FluxOptions
    local db = options and options.GetUnitFrameDB and options:GetUnitFrameDB() or {}
    local group = options and options.GetRaidFrameDB and options:GetRaidFrameDB() or {}
    local placement = options and options.GetPlayerTargetPlacement and options:GetPlayerTargetPlacement() or 1
    return db, group, placement
end

local function AnchorPartButton(ui, group, region, part, level)
    if not region or not region:IsShown() then return end
    group.hitCount = group.hitCount + 1
    local hit = group.hits[group.hitCount]
    if not hit then
        hit = NewButton(ui, group.frame)
        hit.previewHit = true
        group.hits[group.hitCount] = hit
    end
    hit:ClearAllPoints()
    hit:SetAllPoints(region)
    hit:SetFrameLevel((group.frame:GetFrameLevel() or 0) + 224 + level)
    SetPart(ui, hit, part, group.destination)
end

local unitHitLayers = {
    layout = 0, health = 1, power = 2, name = 2, portrait = 2, cast = 3,
    classResource = 3, absorbs = 4, indicators = 4, buffs = 5, debuffs = 5,
    auras = 5, attached = 6,
}
local generalHitParts = {
    layout = "layout", health = "health", power = "power", name = "layout", portrait = "portrait",
    absorbs = "health", classResource = "power", indicators = "indicators",
    buffs = "auras", debuffs = "auras", auras = "auras",
}

local function BindUnitHits(ui, drawing, parts)
    drawing.parts = parts
    drawing.hitCount = 0
    for key, region in pairs(parts) do
        local level = unitHitLayers[key]
        local part = key
        if ui.pageId == "ufGeneral" then
            part = generalHitParts[key]
        elseif ui.subKey == "unitPet" and (key == "buffs" or key == "debuffs") then
            part = "auras"
        end
        if level and part then
            if region.IsShown then
                AnchorPartButton(ui, drawing, region, part, level)
            else
                for _, item in pairs(region) do AnchorPartButton(ui, drawing, item, part, level) end
            end
        end
    end
    for i = drawing.hitCount + 1, #drawing.hits do drawing.hits[i]:Hide() end
end

local function PaintUnit(ui, unit, db, placement, width, height)
    if not ui.unitDrawing and ns.UnitFrames and ns.UnitFrames.CreateOptionsPreview then
        local scene = ns.UnitFrames.CreateOptionsPreview(ui.canvas)
        if scene then ui.unitDrawing = { scene = scene, frame = scene.frame, hits = {} } end
    end
    local drawing = ui.unitDrawing
    if not drawing then return end
    local parts = drawing.scene:Render(unit, width, height, db, placement, ui.selectedPart, ui.cases[unit])
    if not parts then
        drawing.scene:Hide()
        return
    end
    BindUnitHits(ui, drawing, parts)
    return true
end

local function GroupAuraHit(ui, group, frame, field, side, compact)
    local icons, rows = frame[field], frame._fluxPreviewAuraRows
    if rows and icons and icons[1] and icons[1]:IsShown() then
        AnchorPartButton(ui, group, rows[side], compact and side or "auras", 5)
    end
end

local function GroupMemberHits(ui, group, frame, compact)
    if not frame or not frame:IsShown() then return end
    AnchorPartButton(ui, group, frame.outerBorderFrame or frame, "layout", 0)
    AnchorPartButton(ui, group, compact and frame.healthBar or frame.Health, "health", 1)
    AnchorPartButton(ui, group, compact and frame.powerBar or frame.Power, "power", 1)
    AnchorPartButton(ui, group, compact and frame.name or frame._fluxPartyNameTextAnchor or frame.nameText, "name", 2)
    if not compact then
        AnchorPartButton(ui, group, frame.PortraitFrame, "portrait", 2)
        if frame.CastBar and frame.CastBar:IsShown() then
            AnchorPartButton(ui, group, frame.CastBar, "cast", 3)
            AnchorPartButton(ui, group, frame.CastBar.IconFrame, "cast", 3)
        end
    end
    AnchorPartButton(ui, group, frame.roleIcon or frame.partyRoleIcon, "indicators", 4)
    AnchorPartButton(ui, group, frame._fluxPreviewDispel, "indicators", 4)
    for _, bar in pairs(frame._fluxPreviewPrediction or {}) do
        AnchorPartButton(ui, group, bar, "absorbs", 4)
    end
    GroupAuraHit(ui, group, frame, "_fluxAuraBuff", "buffs", compact)
    GroupAuraHit(ui, group, frame, "_fluxAuraDebuff", "debuffs", compact)
    AnchorPartButton(ui, group, frame._fluxPreviewTarget, "attached", 3)
end

local function BindGroupHits(ui, drawing)
    local pets, targets = drawing.pets, drawing.targets
    drawing.hitCount = 0
    for i = 1, drawing.count do
        GroupMemberHits(ui, drawing, drawing.members[i], drawing.compact)
        if pets then AnchorPartButton(ui, drawing, pets[i], "attached", 3) end
        if targets then AnchorPartButton(ui, drawing, targets[i], "attached", 3) end
    end
    for i = drawing.hitCount + 1, #drawing.hits do drawing.hits[i]:Hide() end
end

local function PaintGroup(ui, width, height, party, compact)
    local drawing, members, pets, targets, count
    if compact then
        if ui.partyDrawing then ui.partyDrawing.frame:Hide() end
        if not ui.raidDrawing and FluxRaidPreview and FluxRaidPreview.CreateOptionsPreview then
            local scene = FluxRaidPreview.CreateOptionsPreview(ui.canvas)
            if scene then ui.raidDrawing = { scene = scene, frame = scene.frame, hits = {} } end
        end
        drawing = ui.raidDrawing
        if not drawing then return end
        local nativeWidth, nativeHeight
        nativeWidth, nativeHeight, members, count = drawing.scene:Render(party)
        if not nativeWidth or not nativeHeight then return end
        local root = drawing.frame
        local scale = math.min(1, width / math.max(1, nativeWidth), (height - 4) / math.max(1, nativeHeight))
        root:SetScale(scale)
        root:ClearAllPoints()
        root:SetPoint("TOP", ui.canvas, "TOP", 0, -3 / scale)
        root:Show()
    else
        if ui.raidDrawing then ui.raidDrawing.frame:Hide() end
        if not ui.partyDrawing and ns.PartyFrames and ns.PartyFrames.CreateOptionsPreview then
            local frame = ns.PartyFrames.CreateOptionsPreview(ui.canvas)
            if frame then ui.partyDrawing = { frame = frame, hits = {} } end
        end
        drawing = ui.partyDrawing
        if not drawing then return end
        if not drawing.frame:Refresh(width, height) then
            drawing.frame:Hide()
            return
        end
        members, pets, targets = drawing.frame.members, drawing.frame.pets, drawing.frame.targets
        if not members or not drawing.frame:IsShown() then return end
        count = #members
    end
    drawing.destination = compact and party and "ufRaid" or nil
    ui.activeGroup = drawing
    drawing.members, drawing.count, drawing.compact = members, count, compact
    drawing.pets, drawing.targets = pets, targets
    BindGroupHits(ui, drawing)
    return true
end

local function PlaceShortcuts(ui, buttons, keys, width, height, columns, destination)
    local rows = math.ceil(#keys / columns)
    local gap, rowHeight = 4, 20
    local buttonWidth = (width - (columns - 1) * gap) / columns
    local top = height - rows * (rowHeight + gap) - 7
    for index, part in ipairs(keys) do
        local button = buttons[index]
        if not button then
            button = NewButton(ui, ui)
            button.background = Fill(button, "BACKGROUND")
            W.Solid(button.background, .16, .16, .15, .95)
            button.label = Text(button)
            button.label:SetPoint("LEFT", button, "LEFT", 2, 0)
            button.label:SetPoint("RIGHT", button, "RIGHT", -2, 0)
            buttons[index] = button
        end
        button.label:SetText(Label(part))
        Position(button, ui, 10 + ((index - 1) % columns) * (buttonWidth + gap), top + math.floor((index - 1) / columns) * (rowHeight + gap), buttonWidth, rowHeight)
        SetPart(ui, button, part, part ~= "layout" and destination or nil)
    end
    for index = #keys + 1, #buttons do buttons[index]:Hide() end
    return top
end

local function StopGroupAnimation(ui)
    local group = ui.activeGroup
    if group and ns.UnitFrames.StopOptionsPreviewAnimation then
        ns.UnitFrames.StopOptionsPreviewAnimation(group.frame)
    end
    ui.activeGroup = nil
end

local function Draw(ui)
    local width, height = ui:GetWidth() - 20, ui:GetHeight()
    if width < 110 or height < 220 then return end
    local db, group, placement = CurrentSettings()
    local page = ui.pageId
    local groupPage = page == "ufPartyRaid"
    local showCases = page == "ufUnits"
    local party = groupPage and ui.subKey == "party"
    local raid = groupPage and ui.subKey == "raid"
    local compactParty = party and group.partyAsRaid ~= false
    local unit = units[ui.subKey] or units.unitTarget
    local keys = page == "ufGeneral" and generalParts or raid and raidParts
        or compactParty and compactParts or party and partyParts or unitParts[ui.subKey] or unitParts.unitTarget
    local bottom = height
    if page == "ufGeneral" then
        local types = FLUX_API and FLUX_API.hasFocusUnit
            and { "unitPlayer", "unitTarget", "unitFocus", "unitPet" } or { "unitPlayer", "unitTarget", "unitPet" }
        bottom = PlaceShortcuts(ui, ui.unitShortcuts, types, width, bottom, #types)
    else
        for _, button in ipairs(ui.unitShortcuts) do button:Hide() end
    end
    local top = PlaceShortcuts(ui, ui.shortcuts, keys, width, bottom, width >= 195 and 3 or 2, compactParty and "ufRaid" or nil)
    if showCases then
        local newUnit = ui.caseUnit ~= unit.unit
        ui.caseUnit = unit.unit
        ui.caseItems = previewCases[unit.unit] or attachmentCases
        if ui.caseMenu:GetWidth() ~= width - 60 then ui.caseMenu:SetWidth(width - 60) end
        if newUnit then ui.caseMenu:SetValue(ui.cases[unit.unit] or "default") end
    else
        ui.caseUnit = nil
    end
    ui.caseMenu:SetShown(showCases)
    local controls = showCases or groupPage
    local canvasTop = controls and 94 or 62
    local canvasHeight = math.max(70, top - canvasTop - 2)
    if ui.canvasTop ~= canvasTop then
        ui.canvasTop = canvasTop
        ui.canvas:ClearAllPoints()
        ui.canvas:SetPoint("TOPLEFT", ui, "TOPLEFT", 10, -canvasTop)
    end
    ui.canvas:SetSize(width, canvasHeight)
    local heading, available
    StopGroupAnimation(ui)
    if groupPage then
        if ui.unitDrawing then ui.unitDrawing.scene:Hide() end
        available = PaintGroup(ui, width, canvasHeight, party, raid or compactParty)
        local count = math.floor(Limit(group.previewRosterSize, 10, 40, 40))
        heading = raid and L.framePreviewRaidSize:format(count)
            or compactParty and L.framePreviewCompactParty or L.framePreviewNormalParty
    else
        if ui.partyDrawing then ui.partyDrawing.frame:Hide() end
        if ui.raidDrawing then ui.raidDrawing.frame:Hide() end
        available = PaintUnit(ui, unit.unit, db, placement, width, canvasHeight)
        heading = L.framePreviewSample:format(L["framePreview" .. unit.label])
        if db["useFlux" .. unit.label] == false or unit.owner and db["useFlux" .. unit.owner] == false then
            heading = heading .. "   ·   " .. L.framePreviewDefaultFrames
        end
    end
    if not available then
        heading = L.framePreviewUnavailable
        if InCombatLockdown and InCombatLockdown() then
            heading = L.framePreviewAfterCombat
            local combat = ns.Flux and ns.Flux.Combat
            if combat and combat.Defer then combat.Defer("options.framePreview", ui.retryPreview) end
        end
    end
    ui.mode:SetText(heading)
    ui.play:SetShown(controls and not not available)
end

function Preview.Create(parent, onPart, onUnit)
    local ui = CreateFrame("Frame", nil, parent)
    ui:SetAllPoints(parent)
    ui.onPart, ui.onUnit = onPart, onUnit
    ui.shortcuts, ui.unitShortcuts, ui.cases = {}, {}, {}
    ui.retryPreview = function()
        if ui:IsVisible() then Draw(ui) end
    end
    local backdrop = Fill(ui, "BACKGROUND")
    W.Solid(backdrop, .04, .05, .06, .72)
    local title = Text(ui, "GameFontNormal")
    title:SetPoint("TOPLEFT", ui, "TOPLEFT", 10, -9)
    title:SetText(L.framePreviewTitle)
    local hint = Text(ui, "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    hint:SetText(L.framePreviewHint)
    ui.mode = Text(ui, "GameFontNormalSmall")
    ui.mode:SetPoint("TOPLEFT", ui, "TOPLEFT", 10, -44)
    ui.mode:SetPoint("RIGHT", ui, "RIGHT", -8, 0)
    ui.mode:SetJustifyH("LEFT")
    ui.caseMenu = W.CreateDropdown(ui)
    ui.caseMenu:SetPoint("TOPLEFT", ui, "TOPLEFT", 10, -59)
    ui.caseMenu:SetHeight(28)
    ui.caseMenu:SetGetter(function() return ui.caseItems end)
    ui.caseMenu:SetOnChange(function(value)
        if not ui.caseUnit or ui.cases[ui.caseUnit] == value then return end
        ui.cases[ui.caseUnit] = value
        Draw(ui)
    end)
    ui.play = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    ui.play:SetSize(55, 22)
    ui.play:SetPoint("TOPRIGHT", ui, "TOPRIGHT", -10, -62)
    ui.play:SetText(L.framePreviewPlay)
    ui.play:SetScript("OnEnter", function(self) W.ShowTooltip(self, L.framePreviewPlay, L.framePreviewPlayTip) end)
    ui.play:SetScript("OnLeave", W.HideTooltip)
    ui.play:SetScript("OnClick", function()
        local group = ui.activeGroup
        if group then
            local play = ns.UnitFrames.PlayOptionsGroupAnimation
            if play and play(group.frame, group.members, group.count, group.compact, function()
                if group == ui.activeGroup and group.frame:IsVisible() then BindGroupHits(ui, group) end
            end) then
                BindGroupHits(ui, group)
            end
            return
        end
        local drawing = ui.unitDrawing
        if not drawing or not drawing.frame:IsVisible() or not drawing.scene.PlayAnimation then return end
        local parts = drawing.scene:PlayAnimation(function(restored)
            if restored and drawing.frame:IsVisible() then BindUnitHits(ui, drawing, restored) end
        end)
        if parts then BindUnitHits(ui, drawing, parts) end
    end)
    ui.canvas = CreateFrame("Frame", nil, ui)
    if ui.canvas.SetClipsChildren then ui.canvas:SetClipsChildren(true) end
    ui:SetScript("OnHide", function()
        StopGroupAnimation(ui)
        local drawing = ui.unitDrawing
        if drawing and drawing.scene.StopAnimation then drawing.scene:StopAnimation(true) end
    end)
    ui:SetScript("OnSizeChanged", function(self)
        if self.pageId and self:IsVisible() then Draw(self) end
    end)
    function ui:Update(pageId, subKey, selectedPart)
        self.pageId, self.subKey, self.selectedPart = pageId, subKey, selectedPart
        Draw(self)
    end
    function ui:SelectPart(part)
        self.selectedPart = part
        local function selectButton(button)
            if button:IsShown() then
                button.selected = part == button.part and not button.destination
                PaintButton(button, button.selected)
            end
        end
        for _, button in ipairs(self.shortcuts) do selectButton(button) end
        local drawing = self.unitDrawing
        if drawing and drawing.frame:IsShown() then
            local parts = drawing.scene.SelectPart and drawing.scene:SelectPart(part)
            if parts and parts ~= drawing.parts then
                BindUnitHits(self, drawing, parts)
            else
                for index = 1, drawing.hitCount do selectButton(drawing.hits[index]) end
            end
        end
    end
    return ui
end
