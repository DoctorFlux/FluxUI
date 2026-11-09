local _, ns = ...
local UF, Flux = ns.UnitFrames, ns.Flux
local Party = { members = {}, pets = {}, targets = {}, ready = false }
local ROLE_ATLAS = {TANK="roleicon-tiny-tank", HEALER="roleicon-tiny-healer", DAMAGER="roleicon-tiny-dps"}
local INDICATOR_EVENTS = {READY_CHECK=true, READY_CHECK_CONFIRM=true, READY_CHECK_FINISHED=true, RAID_TARGET_UPDATE=true,
    PARTY_LEADER_CHANGED=true, PARTY_LOOT_METHOD_CHANGED=true, PLAYER_ROLES_ASSIGNED=true, ROLE_CHANGED_INFORM=true,
    INCOMING_RESURRECT_CHANGED=true, INCOMING_SUMMON_CHANGED=true}
ns.PartyFrames = Party
_G.FluxPartyFrames = Party

local function DB()
    return FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
end

local function Scale(value, fallback)
    value = tonumber(value) or fallback
    if value ~= value then value = fallback end
    return math.max(0.35, math.min(1.5, value))
end

function Party.GetSizing(db)
    db = db or DB()
    return math.floor(325 * Scale(db.partyWidthScale, .8) + .5),
        math.floor(100 * Scale(db.partyHeightScale, .85) + .5)
end

function Party.GetScale(db)
    db = db or DB()
    local _, height = Party.GetSizing(db)
    local column = FluxRaid_GetColumnHeight and FluxRaid_GetColumnHeight()
        or 5 * FluxRaidVisuals.FRAME_HEIGHT - 4 * (FluxRaidVisuals.CELL_JOIN_OVERLAP or 4)
    -- Always budget all four slots, even in a one-member party. Roster changes
    -- never resize a cell; the complete stack stays within the raid column.
    return math.min(Scale(db.partyFrameScale, .55), math.max(.05, column / (4 * (height + 36))))
end

local function Secret(value)
    return ns.API and ns.API.IsSecretValue and ns.API.IsSecretValue(value)
        or issecretvalue and issecretvalue(value)
end

function Party.GetStatusText(unit)
    local function yes(fn)
        if not fn then return false end
        local value = fn(unit)
        return not Secret(value) and value == true
    end
    if UnitIsConnected then
        local connected = UnitIsConnected(unit)
        if not Secret(connected) and connected == false then return PLAYER_OFFLINE or "Offline" end
    end
    if yes(UnitIsDead) then return DEAD or "Dead" end
    if yes(UnitIsGhost) then return GHOST or "Ghost" end
    if yes(UnitIsAFK) then return CHAT_MSG_AFK or "AFK" end
end

function Party.StyleText(frame)
    local relative = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local factor = math.max(1.35, .7 / math.max(.05, relative)) * Scale(DB().partyTextScale, 1)
    frame._fluxPartyNameTextScale = factor * .85
    if frame.nameText and frame.nameText.SetTextScale then frame.nameText:SetTextScale(frame._fluxPartyNameTextScale) end
    if UF.FitNameText then UF.FitNameText(frame, frame._fluxLastRealName, 16, 8) end
    factor = factor * 1.15
    for _, label in pairs({frame.Health and frame.Health.Value, frame.Health and frame.Health.Percent,
        frame.Health and frame.Health.HealthStatusLabel, frame.Power and frame.Power.Value, frame.Power and frame.Power.Percent}) do
        if label.SetTextScale then label:SetTextScale(factor) end
    end
    frame._fluxPartyTextBandHeight = 12 * factor + 10
    if Party.LayoutIndicators then Party.LayoutIndicators(frame) end
end

function Party.LayoutIndicators(frame)
    if frame._fluxPartyPet then
        for _, key in ipairs({"classIcon", "specIcon", "nameText", "petNameText", "levelText", "groupText", "pvpIcon", "raidIcon", "leaderIcon", "assistantIcon", "mainTankIcon", "mainAssistIcon", "masterLooterIcon"}) do
            if frame[key] then frame[key]:Hide() end
        end
        return
    end
    local layer = frame._fluxPartyIndicatorLayer
    if not layer then return end
    local slot = 0
    for _, key in ipairs({"leaderIcon", "assistantIcon", "mainTankIcon", "mainAssistIcon", "masterLooterIcon"}) do
        local icon = frame[key]
        if icon and icon.IsShown then
            local shown = icon:IsShown()
            if not Secret(shown) and shown then
                icon:ClearAllPoints(); icon:SetPoint("TOPLEFT", frame.PortraitFrame or frame.Health, "TOPLEFT", 2 + (slot % 2) * 25, -1 - math.floor(slot / 2) * 18)
                icon:SetSize(22, 18); icon:SetDrawLayer("OVERLAY", 7)
                slot = slot + 1
            end
        end
    end
    local portrait = not frame._fluxPortraitDisabled and frame.PortraitFrame or frame.Health
    -- Class/spec anchors and visibility come from the same UF factory as player.
    for _, spec in ipairs({{"partyRoleIcon", "TOPRIGHT", -2, -2, 24}}) do
        local icon = frame[spec[1]]
        if icon then
            icon:ClearAllPoints(); icon:SetPoint(spec[2], portrait, spec[2], spec[3], spec[4])
            icon:SetSize(spec[5], spec[5]); icon:SetDrawLayer("OVERLAY", 7)
        end
    end
    if UF.LayoutRaidMarker then UF.LayoutRaidMarker(frame) end
    if frame.levelText then
        frame.levelText:ClearAllPoints(); frame.levelText:SetPoint("TOPRIGHT", layer, "TOPRIGHT", -3, -3)
        frame.levelText:SetWidth(40)
        if frame.levelText.SetTextScale then frame.levelText:SetTextScale(math.max(1, .6 / (frame:GetEffectiveScale() / UIParent:GetEffectiveScale()))) end
    end
    Party.UpdatePvpBadge(frame, true)
    local host = frame._fluxPartyNameTextAnchor
    if host and host.GetWidth then
        local width = host:GetWidth()
        if not Secret(width) and type(width) == "number" and width > 0 then
            local label = frame.nameText
            label:SetWidth(width)
            if label.SetWordWrap then label:SetWordWrap(false) end
            if label.SetMaxLines then label:SetMaxLines(1) end
            -- Shared fitting owns the font and uses this host's exact width.
        end
    end
    if Party.SyncCastCover then Party.SyncCastCover(frame) end
end

function Party.UpdatePvpBadge(frame, layoutOnly)
    return UF.UpdatePvpBadge(frame, layoutOnly)
end

function Party.SyncCastCover(frame)
    local bar = frame.CastBar
    if not bar then return end
    local visible = bar:IsVisible()
    local covered = not Secret(visible) and visible and not bar._fluxPetCastDisabled
    if covered then
        for _, key in ipairs({"nameText", "levelText"}) do
            local label = frame[key]
            if label then
                if not frame._fluxPartyCastCovered then
                    local alpha = label.GetAlpha and label:GetAlpha()
                    label._fluxPartyPreCastAlpha = not Secret(alpha) and type(alpha) == "number" and alpha or 1
                end
                label:SetAlpha(0)
            end
        end
    elseif frame._fluxPartyCastCovered then
        for _, key in ipairs({"nameText", "levelText"}) do
            local label = frame[key]
            if label then label:SetAlpha(label._fluxPartyPreCastAlpha or 1); label._fluxPartyPreCastAlpha = nil end
        end
    end
    frame._fluxPartyCastCovered = covered
end

function Party.LayoutCastOverlay(frame)
    local bar = frame.CastBar
    if not bar then return end
    -- Preserve the shared player cast art/size/icon, but put its whole row over
    -- the party header. Name and level live below this raised cast shell.
    bar:SetFrameLevel(frame:GetFrameLevel() + 110)
    bar:ClearAllPoints()
    local icon = bar.IconFrame
    if icon then
        icon:ClearAllPoints(); icon:SetPoint("TOPLEFT", frame.outerBorderFrame, "TOPLEFT", 0, 0)
        bar:SetPoint("TOPLEFT", icon, "TOPRIGHT", 0, 0)
    else bar:SetPoint("TOPLEFT", frame.outerBorderFrame, "TOPLEFT", 0, 0) end
    bar:SetPoint("TOPRIGHT", frame.outerBorderFrame, "TOPRIGHT", 0, 0)
    Party.SyncCastCover(frame)
end

function Party.SetThreatColor(frame, r, g, b)
    if ns.Border and frame._fluxPartyThreat then ns.Border:SetBorderColor(frame._fluxPartyThreat, r, g, b, 1) end
end

function Party.PaintStatus(frame, status)
    frame._fluxPartyStatusText = not frame._fluxPartyPet and status or nil
    local label = frame.Health and frame.Health.HealthStatusLabel
    if not label then return end
    if frame._fluxPartyPet then label:Hide(); return end
    label:SetText(status or "")
    label:SetShown(status ~= nil)
    label:ClearAllPoints()
    label:SetPoint("CENTER", frame._fluxPartyHealthTextAnchor or frame.Health, "CENTER", 0, 0)
end

function Party.ApplyTextModes(frame)
    if not frame._fluxPartyMember then return end
    local db = DB()
    local health, power = db.partyHealthText or "values", db.partyPowerText or "percent"
    local hasStatus = frame._fluxPartyStatusText ~= nil
    frame.Health.Value:SetShown(not hasStatus and (health == "values" or health == "both"))
    frame.Health.Percent:SetShown(not hasStatus and (health == "percent" or health == "both"))
    frame.Power.Value:SetShown(power == "values" or power == "both")
    frame.Power.Percent:SetShown(power == "percent" or power == "both")
    local label = power == "percent" and frame.Power.Percent or power == "values" and frame.Power.Value
    if label then
        label:ClearAllPoints(); label:SetPoint("CENTER", frame._fluxPartyPowerTextAnchor, "CENTER", 0, 0)
        label._fluxPartyTextMode = power
    elseif power == "both" then
        for _, item in ipairs({{frame.Power.Percent, "LEFT", 5}, {frame.Power.Value, "RIGHT", -5}}) do
            local text = item[1]
            if text._fluxPartyTextMode ~= power then
                text:ClearAllPoints(); text:SetPoint(item[2], frame._fluxPartyPowerTextAnchor, item[2], item[3], 0)
                text._fluxPartyTextMode = power
            end
        end
    end
end

function Party.UpdateIndicators(frame)
    if FluxRaid_UpdateCenterStatus then FluxRaid_UpdateCenterStatus(frame) end
    if frame.readyCheckIcon then
        if frame._fluxPartyReadyActive == false then frame.readyCheckIcon:Hide()
        elseif FluxRaid_UpdateReadyCheck then FluxRaid_UpdateReadyCheck(frame) end
    end
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(frame.unit)
    local atlas = not Secret(role) and ROLE_ATLAS[role]
    if frame.partyRoleIcon then
        if atlas and frame.partyRoleIcon.SetAtlas then frame.partyRoleIcon:SetAtlas(atlas); frame.partyRoleIcon:Show()
        else frame.partyRoleIcon:Hide() end
    end
    Party.LayoutIndicators(frame)
end

function Party.UpdateThreat(frame)
    local glow = frame._fluxPartyThreat
    if not glow then return end
    local opt = frame.optionTable or {}
    if DB().partyThreatHighlight == false or opt.showAggroHighlight == false then glow:Hide(); return end
    if IsThreatWarningEnabled then
        local enabled = IsThreatWarningEnabled()
        if Secret(enabled) or not enabled then glow:Hide(); return end
    end
    if UnitIsDead then
        local dead = UnitIsDead(frame.unit)
        if Secret(dead) or dead then glow:Hide(); return end
    end
    local threat, status = Flux and Flux.Threat
    if threat and threat.GetSituation then status = threat.GetSituation(frame.unit)
    elseif UnitThreatSituation then status = UnitThreatSituation(frame.unit) end
    -- Native UI executes untainted comparisons. Addon code must not branch on
    -- opaque threat status; match the raid adapter's unavailable-data policy.
    if Secret(status) or type(status) ~= "number" or status <= 0 then glow:Hide(); return end
    local r, g, b = 1, 0, 0
    if GetThreatStatusColor then r, g, b = GetThreatStatusColor(status)
    elseif threat and threat.GetStatusColor then r, g, b = threat.GetStatusColor(status) end
    if Secret(r) or Secret(g) or Secret(b) or r == nil then glow:Hide(); return end
    Party.SetThreatColor(frame, r, g, b); glow:Show()
end

local function CreateThreat(frame)
    local layer = CreateFrame("Frame", nil, UIParent)
    layer:EnableMouse(false)
    layer:SetFrameStrata(frame:GetFrameStrata())
    layer:SetFrameLevel(frame:GetFrameLevel() + 15)
    if ns.Border then
        ns.Border:ApplyTo(layer, 2, 2, 2, 6)
        ns.Border:SetBackdropColor(layer, 0, 0, 0, 0)
        local background = layer.FluxBorderFrame and layer.FluxBorderFrame.BackgroundFrame
        if background then background:SetAlpha(0) end
    end
    layer:Hide()
    frame._fluxPartyThreat = layer
    frame:HookScript("OnHide", function() layer:Hide() end)
end

function Party.PaintChrome(frame, only)
    if not ns.Border then return end
    local color
    if frame._fluxPartyClassChrome then
        local class = frame._fluxPartyPreviewClass
        if not class and UnitIsPlayer then
            local player = UnitIsPlayer(frame.unit)
            if not Secret(player) and player then
                local _, token = UnitClass(frame.unit)
                if not Secret(token) and type(token) == "string" then class = token end
            end
        end
        color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    end
    if frame._fluxPartyDivider then
        local r, g, b
        if color then r, g, b = color.r, color.g, color.b
        else r, g, b = ns.Border:GetAccentColor() end
        frame._fluxPartyDivider:SetVertexColor(r, g, b, 1)
    end
    local function paint(surface)
        if not surface then return end
        ns.Border:SetClassColor(surface, 1, true)
        if color then
            ns.Border:SetBorderColor(surface, color.r, color.g, color.b, 1)
            ns.Border:SetBackdropColor(surface, color.r * .4, color.g * .4, color.b * .4, .85)
        end
    end
    if only then paint(only); return end
    paint(frame); paint(frame.outerBorderFrame); paint(frame.atlasBorderFrame); paint(frame.PortraitFrame)
end

function Party.RefreshChrome()
    for _, frame in ipairs(Party.members) do Party.PaintChrome(frame) end
    if Party.preview then
        for _, frame in ipairs(Party.preview.members) do Party.PaintChrome(frame) end
    end
end

local function RegisterClickFrame(button)
    button._fluxRaidUnit = true
    if ClickCastFrames then ClickCastFrames[button] = true end
    local kb = ns.FluxMouseoverKeybind
    if kb and kb.RegisterFrame then kb:RegisterFrame(button) end
end

local function CreateTextHosts(frame, preview)
    for _, spec in ipairs({{"Health", "Health"}, {"Power", "Power"}, {"Name", "outerBorderFrame"}}) do
        local host = CreateFrame("Frame", nil, frame[spec[2]], not preview and "SecureHandlerStateTemplate" or nil)
        host:EnableMouse(false)
        frame["_fluxParty" .. spec[1] .. "TextAnchor"] = host
        host:SetFrameLevel(frame:GetFrameLevel() + 70)
        if spec[1] == "Name" and frame.nameText.SetParent then frame.nameText:SetParent(host) end
    end
    local layer = CreateFrame("Frame", nil, frame.outerBorderFrame)
    layer:EnableMouse(false); layer:SetAllPoints(frame.outerBorderFrame)
    layer:SetFrameLevel(frame:GetFrameLevel() + 80)
    frame._fluxPartyIndicatorLayer = layer
    for _, key in ipairs({"raidIcon", "levelText", "pvpTimer", "leaderIcon", "assistantIcon", "mainTankIcon", "mainAssistIcon", "masterLooterIcon"}) do
        if frame[key] and frame[key].SetParent then frame[key]:SetParent(layer) end
    end
    local pvpLayer = frame._fluxPvpLayer
    pvpLayer:EnableMouse(false); pvpLayer:SetAllPoints(frame.outerBorderFrame)
    pvpLayer:SetFrameLevel(frame:GetFrameLevel() + 20)
    frame._fluxPartyPvpLayer = pvpLayer
    if frame.pvpIcon and frame.pvpIcon.SetParent then frame.pvpIcon:SetParent(pvpLayer) end
    local prestigePortrait, prestigeBadge = frame._fluxPvpPrestigePortrait, frame._fluxPvpPrestigeBadge
    if prestigePortrait.SetParent then prestigePortrait:SetParent(pvpLayer) end
    if prestigeBadge.SetParent then prestigeBadge:SetParent(pvpLayer) end
    frame._fluxPartyPrestigePortrait, frame._fluxPartyPrestigeBadge = prestigePortrait, prestigeBadge
    frame._fluxPartyPvpElements = frame._fluxPvpElements
    for _, key in ipairs({"readyCheckIcon", "centerStatusIcon", "partyRoleIcon"}) do
        local icon = layer:CreateTexture(nil, "OVERLAY", nil, 7)
        icon:SetSize(32, 32); icon:SetPoint("CENTER", frame.PortraitFrame or frame.Health, "CENTER", 0, 0)
        icon:Hide(); frame[key] = icon
    end
    frame.raidTargetIcon = frame.raidIcon
    -- The normal factory's HUD separator can be transparent for zero power.
    -- Health extends behind power on HUD clients. Use power's fixed top edge,
    -- centered in the two-unit partition gap, rather than the health fill bottom.
    local divider = UF.CreateBarSeparator(layer)
    divider:SetPoint("LEFT", frame.Power, "TOPLEFT", 0, 1)
    divider:SetPoint("RIGHT", frame.Power, "TOPRIGHT", 0, 1)
    frame._fluxPartyDivider = divider
end

local function LayoutTextHosts(frame, petShown, petScale)
    -- Preview/OOC only. Live pet transitions move these prepared hosts inside
    -- the secure state handler; FontStrings retain the same anchors in combat.
    local left = petShown and 60 * petScale + 4 or 0
    for _, key in ipairs({"Health", "Power"}) do
        local host = frame["_fluxParty" .. key .. "TextAnchor"]
        host:ClearAllPoints(); host:SetPoint("TOPLEFT", frame[key], "TOPLEFT", left, 0)
        if key == "Health" and petShown then
            host:ClearAllPoints(); host:SetPoint("TOPLEFT", frame[key], "TOPLEFT", left, -2)
            host:SetPoint("TOPRIGHT", frame[key], "TOPRIGHT", -left, -2)
            host:SetHeight(frame._fluxPartyTextBandHeight or 30)
        else host:SetPoint("BOTTOMRIGHT", frame[key], "BOTTOMRIGHT", -left, 0) end
    end
    local host = frame._fluxPartyNameTextAnchor
    local height
    if UF.GetFramePublicDimensions then local ignored; ignored, height = UF.GetFramePublicDimensions(frame) end
    if Secret(height) or type(height) ~= "number" then height = frame:GetHeight() end
    if Secret(height) or type(height) ~= "number" then height = 85 end
    host:ClearAllPoints()
    host:SetPoint("TOPLEFT", frame.outerBorderFrame, "TOPLEFT", math.max(80, frame._fluxPortraitDisabled and 0 or height), -2)
    host:SetPoint("BOTTOMRIGHT", frame.outerBorderFrame, "TOPRIGHT", -44, -34)
end

-- Presentation only: focus keeps its watched-unit driver and external auras.
function Party.LayoutFocusPresentation(frame)
    if InCombatLockdown() then return end
    frame._fluxPartyClassChrome = DB().partyClassColor == true
    frame._fluxPartyPowerHeightScale = math.max(.5, math.min(1.5, tonumber(DB().partyPowerHeightScale) or .8))
    LayoutTextHosts(frame, false, 1)
    local relative = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if frame.atlasBorderFrame then frame.atlasBorderFrame:SetScale(relative) end
    if frame.SeparatorContainer then frame.SeparatorContainer:SetScale(relative) end
    -- Keep the existing external aura-panel size controls in screen units;
    -- only the body adopts the party member's smaller presentation scale.
    local base = Party.GetScale()
    frame._fluxFocusAuraPanelScale = 1 / base
    for _, key in ipairs({"BuffContainer", "DebuffContainer"}) do
        local panel = frame[key]
        if panel then
            panel:SetScale(frame._fluxFocusAuraPanelScale)
            panel:SetFrameLevel(frame:GetFrameLevel() + 90)
        end
    end
    Party.StyleText(frame)
    Party.PaintChrome(frame)
end

function Party.SetupFocusPresentation(frame)
    if frame._fluxPartyIndicatorLayer then return end
    CreateTextHosts(frame, true)
    frame.Power._fluxPartyBar = true
    Party.LayoutFocusPresentation(frame)
    for event in pairs(INDICATOR_EVENTS) do pcall(frame.RegisterEvent, frame, event) end
    frame:HookScript("OnEvent", function(self, event)
        if not self:IsVisible() then return end
        if event == "READY_CHECK" then self._fluxPartyReadyActive = true
        elseif event == "READY_CHECK_FINISHED" then self._fluxPartyReadyActive = false end
        if INDICATOR_EVENTS[event] or event == "PLAYER_FOCUS_CHANGED" then Party.UpdateIndicators(self) end
    end)
end

function Party.SetupCompactCastOverlay(frame)
    local bar = frame.CastBar
    if not bar or bar._fluxCompactOverlay then return end
    bar._fluxCompactOverlay = true
    local layout = bar.UpdateLayout
    bar.UpdateLayout = function(...)
        bar:SetFrameLevel(frame:GetFrameLevel() + 110)
        if layout then layout(...) end
        Party.LayoutCastOverlay(frame)
    end
    bar:HookScript("OnShow", function() Party.SyncCastCover(frame) end)
    bar:HookScript("OnHide", function() Party.SyncCastCover(frame) end)
    bar:UpdateLayout()
end

local function PaintTarget(frame)
    UF.UpdateVerticalTargetHealth(frame, frame.unit)
end

local function BuildTarget(owner, preview)
    local unit = owner.unit .. "target"
    local frame = CreateFrame("Button", (preview and "FluxPartyPreview_" or "FluxUnitFrame_") .. unit, owner,
        not preview and "SecureUnitButtonTemplate" or nil)
    frame.unit, frame._fluxPartyTarget = unit, true
    if not preview then
        SecureUnitButton_OnLoad(frame, unit)
        frame:SetAttribute("unit", unit)
        frame:SetAttribute("*type1", "target")
        UF.ConfigureUnitMenu(frame, unit)
        frame:RegisterForClicks("AnyUp")
    end
    frame:SetFrameLevel(owner:GetFrameLevel() + 5)
    if ns.Border then ns.Border:ApplyTo(frame, 2, 2, 2, 6); ns.Border:SetClassColor(frame, 1, true) end
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -3)
    bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    UF.ConfigureVerticalTargetHealth(frame, bar, preview)
    frame:EnableMouse(not preview)
    frame:Hide()
    if not preview then
        RegisterClickFrame(frame)
        for _, event in ipairs({"UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_CONNECTION", "UNIT_FLAGS", "UNIT_FACTION", "UNIT_NAME_UPDATE"}) do frame:RegisterUnitEvent(event, unit) end
        frame:RegisterUnitEvent("UNIT_TARGET", owner.unit)
        frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        frame:SetScript("OnEvent", function(self, event)
            if event == "UNIT_TARGET" or event == "GROUP_ROSTER_UPDATE" then UF.ResetVerticalTargetHealth(self) end
            if self:IsVisible() then PaintTarget(self) end
        end)
        frame:SetScript("OnShow", function(self) C_Timer.After(0, function() if self:IsVisible() then PaintTarget(self) end end) end)
        frame:SetScript("OnEnter", function(self) if UF.ShowUnitTooltip then UF.ShowUnitTooltip(self, self.unit) end end)
        frame:SetScript("OnLeave", function() if UF.HideUnitTooltip then UF.HideUnitTooltip() end end)
    end
    return frame
end

local function ApplyScale(frame, scale)
    frame:SetScale(scale)
    -- Shared UF chrome lives under UIParent so it can lay out in combat.
    -- Match the complete effective scale, including the pet's owner scale.
    local relative = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if frame.atlasBorderFrame then frame.atlasBorderFrame:SetScale(relative) end
    if frame.SeparatorContainer then frame.SeparatorContainer:SetScale(relative) end
end

local function Paint(frame)
    if not InCombatLockdown() and frame.needsPartitionRelayout then frame:UpdatePartition() end
    UF.UpdateHealth(frame, frame.unit)
    if not frame._fluxPartyPet then UF.UpdatePower(frame, frame.unit) end
    if frame.Portrait then UF.UpdatePortrait(frame, frame.unit) end
    frame:UpdateOuterBorder()
    Party.StyleText(frame)
    Party.ApplyTextModes(frame)
    if frame._fluxPartyPet then frame.nameText:SetAlpha(0) end
    if frame._fluxPartyMember and FluxRaidAuras then
        frame.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
        FluxRaidAuras.Update(frame)
        if FluxRaidCompat and FluxRaidCompat.ApplyRangeAlpha then FluxRaidCompat.ApplyRangeAlpha(frame) end
        Party.UpdateThreat(frame)
        Party.UpdateIndicators(frame)
    end
end

local rosterPaintPending, rosterPaintScheduled = {}, false
local function QueueRosterPaint(frame)
    rosterPaintPending[frame] = true
    if rosterPaintScheduled then return end
    rosterPaintScheduled = true
    C_Timer.After(0, function()
        rosterPaintScheduled = false
        local batch = rosterPaintPending; rosterPaintPending = {}
        for member in pairs(batch) do
            if member:IsVisible() then
                if member.CastBar and ns.CastBar then
                    if ns.CastBar.ResetCastForUnit then ns.CastBar.ResetCastForUnit(member.CastBar) end
                    ns.CastBar.RefreshCastForUnit(member.CastBar, member.unit)
                end
                if member.UpdateGroupText then member:UpdateGroupText() end
                Paint(member)
            end
        end
        if FluxRaid_EnsureRangePoll then FluxRaid_EnsureRangePoll() end
    end)
end

local function Build(unit, parent, pet, preview)
    -- Use the player/pet factories' visual components, with actual party tokens.
    -- No player-only class power, vehicle, swing or MP5 services are installed.
    local width, height = Party.GetSizing()
    local frame = UF.CreateBaseFrame(unit, parent, pet and 60 or width, pet and 28 or height, nil,
        preview and {preview = true, name = "FluxPartyPreview_" .. unit} or nil)
    frame._fluxPartyPet, frame._fluxPartyMember = pet or nil, not pet or nil
    frame.portraitPosition = not pet and "LEFT" or nil
    frame.outerBorderAlignment, frame.outerBorderPadding = "BOTTOM", pet and 0 or 36
    frame:Hide()
    UF.CreateHealthBar(frame)
    UF.CreatePowerBar(frame)
    frame.Power._fluxPartyBar = true
    if pet then
        frame._fluxHealthBarOnly = true
        frame._fluxHasMainPower = false
        for _, event in ipairs({"UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER"}) do frame:UnregisterEvent(event) end
    end
    if not pet then UF.CreatePortrait(frame) end
    UF.CreateAtlasBorder(frame)
    UF.CreateOuterBorder(frame)
    if not pet then CreateTextHosts(frame, preview); CreateThreat(frame) end
    frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_MODEL_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_CONNECTION", unit)
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterUnitEvent("UNIT_FLAGS", unit)
    frame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", unit)
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    if not pet then
        frame._fluxRangeEventSupported = pcall(frame.RegisterUnitEvent, frame, "UNIT_IN_RANGE_UPDATE", unit)
        frame.healthBar = frame.Health
        frame.displayedUnit = unit
        frame._fluxAuraLayer = CreateFrame("Frame", nil, frame)
        frame._fluxAuraLayer:SetAllPoints(frame)
        -- Aura artwork/clocks sit above portrait indicators (+80), below casts (+110).
        frame._fluxAuraLayer:SetFrameLevel(frame:GetFrameLevel() + 90)
        frame._fluxAuraLayer:EnableMouse(false)
        frame.optionTable = FluxRaidVisuals.GetFluxRaidOptionTable()
        for _, event in ipairs({"UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE"}) do
            if FluxSafeRegisterUnitEvent then FluxSafeRegisterUnitEvent(frame, event, unit)
            else pcall(frame.RegisterUnitEvent, frame, event, unit) end
        end
        frame:RegisterEvent("CVAR_UPDATE")
        if not preview then
            FluxRaidAuras.Setup(frame)
            frame:RegisterUnitEvent("UNIT_AURA", unit)
            if ns.CastBar and ns.CastBar.CreateCastBar then
                ns.CastBar.CreateCastBar(frame, unit)
                Party.SetupCompactCastOverlay(frame)
            end
        end
    end
    if preview then
        frame:UnregisterAllEvents()
        frame:SetScript("OnEvent", nil)
        frame.outerBorderFrame:UnregisterAllEvents()
        frame.outerBorderFrame:EnableMouse(false)
        frame.outerBorderFrame:SetMouseClickEnabled(false)
        return frame
    end
    local sharedEvent = frame:GetScript("OnEvent")
    for event in pairs(INDICATOR_EVENTS) do
        pcall(frame.RegisterEvent, frame, event)
    end
    frame:SetScript("OnEvent", function(self, event, ...)
        if not self:IsVisible() then return end
        if event == "GROUP_ROSTER_UPDATE" then QueueRosterPaint(self); return end
        if self._fluxPartyPet then Paint(self); return end
        if event == "READY_CHECK" then self._fluxPartyReadyActive = true
        elseif event == "READY_CHECK_FINISHED" then self._fluxPartyReadyActive = false end
        if INDICATOR_EVENTS[event] then Party.UpdateIndicators(self); return end
        if event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" or event == "CVAR_UPDATE" then
            Party.UpdateThreat(self); return
        end
        if event == "UNIT_IN_RANGE_UPDATE" then
            if FluxRaidCompat and FluxRaidCompat.ApplyRangeAlpha then FluxRaidCompat.ApplyRangeAlpha(self) end
            return
        end
        if sharedEvent then sharedEvent(self, event, ...) end
        Party.ApplyTextModes(self)
        Party.SyncCastCover(self)
        if event == "UNIT_AURA" then FluxRaidAuras.Update(self)
        elseif event == "UNIT_PET" or event == "UNIT_CONNECTION"
            or event == "UNIT_NAME_UPDATE" or event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED"
            or event == "UNIT_FLAGS" or event == "PLAYER_FLAGS_CHANGED" then
            Paint(self)
        end
    end)
    frame:HookScript("OnShow", function(self)
        -- Native state dispatch owns visibility; paint after its secure call.
        QueueRosterPaint(self)
    end)
    frame:HookScript("OnHide", function(self)
        if self.CastBar and ns.CastBar and ns.CastBar.ResetCastForUnit then ns.CastBar.ResetCastForUnit(self.CastBar) end
        if self._fluxPartyMember and FluxRaidAuras then FluxRaidAuras.Clear(self) end
        if FluxRaid_EnsureRangePoll then FluxRaid_EnsureRangePoll() end
    end)
    local button = frame.outerBorderFrame
    -- Reuse the owned party/raid click-cast path for primary mouse chords too.
    -- The hit rectangle, rather than the visual host, owns these attributes.
    RegisterClickFrame(button)
    return frame
end

local function LayoutVisuals(frame, pet, target, db, scale, petScale)
    local width, height = Party.GetSizing(db)
    if UF.RecordFrameDimensions then UF.RecordFrameDimensions(frame, width, height) end
    frame:SetSize(width, height)
    ApplyScale(frame, scale)
    frame._fluxPartyClassChrome = db.partyClassColor == true
    frame._fluxPartyPowerHeightScale = math.max(.5, math.min(1.5, tonumber(db.partyPowerHeightScale) or .8))
    frame._fluxPortraitDisabled = db.partyShowPortrait == false
    frame.PortraitFrame:SetShown(not frame._fluxPortraitDisabled)
    LayoutTextHosts(frame, false, petScale)
    frame:UpdatePartition(); frame:UpdateOuterBorder()
    Party.StyleText(frame)
    frame._fluxPartyThreat:SetScale(frame:GetEffectiveScale() / UIParent:GetEffectiveScale())
    frame._fluxPartyThreat:ClearAllPoints(); frame._fluxPartyThreat:SetAllPoints(frame.outerBorderFrame)
    if frame.CastBar then
        local wasDisabled = frame.CastBar._fluxPetCastDisabled
        frame.CastBar._fluxPetCastDisabled = db.partyShowCastBar == false
        if frame.CastBar._fluxPetCastDisabled then
            if ns.CastBar and ns.CastBar.ResetCastForUnit then ns.CastBar.ResetCastForUnit(frame.CastBar) else frame.CastBar:Hide() end
        end
        if frame.CastBar.UpdateLayout then frame.CastBar.UpdateLayout() end
        if not frame.CastBar._fluxPetCastDisabled and wasDisabled ~= false and ns.CastBar and ns.CastBar.RefreshCastForUnit then
            ns.CastBar.RefreshCastForUnit(frame.CastBar, frame.unit)
        end
        Party.SyncCastCover(frame)
    end
    ApplyScale(pet, petScale)
    pet._fluxPortraitDisabled = true
    pet:UpdatePartition(); pet:UpdateOuterBorder()
    Party.StyleText(pet)
    pet.nameText:SetAlpha(0)
    pet:ClearAllPoints(); pet:SetPoint("LEFT", frame, "LEFT", 0, 0)
    target:ClearAllPoints(); target:SetPoint("TOPLEFT", frame.outerBorderFrame, "TOPRIGHT", 0, 0)
    if UF.RecordFrameDimensions then UF.RecordFrameDimensions(target, tonumber(db.partyTargetWidth) or 30, height + 36) end
    target:SetSize(tonumber(db.partyTargetWidth) or 30, height + 36)
    if UF.LayoutVerticalTargetHealth then UF.LayoutVerticalTargetHealth(target) end
    frame._fluxRangeMirrors = { frame.atlasBorderFrame, frame.SeparatorContainer, pet.atlasBorderFrame, pet.SeparatorContainer, frame._fluxPartyThreat }
end

local function AnchorSlot(frame, index, dock, scale)
    local bottom = -(5 * FluxRaidVisuals.FRAME_HEIGHT - 4 * (FluxRaidVisuals.CELL_JOIN_OVERLAP or 4))
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMRIGHT", dock, "TOPRIGHT", frame._fluxPortraitDisabled and 2 or -2,
        (bottom + (4 - index) * ((frame:GetHeight() + 36) * scale)) / scale)
end

function Party.RefreshPreview(show)
    if not show then
        if Party.preview then Party.preview:Hide() end
        return
    end
    if InCombatLockdown() then return end
    if not Party.preview then
        Party.preview = CreateFrame("Frame", "FluxPartyPreview", UIParent)
        Party.preview:SetSize(1, 1)
        Party.preview:SetFrameStrata("DIALOG")
        Party.preview:SetFrameLevel(100)
        Party.preview.members, Party.preview.pets, Party.preview.targets = {}, {}, {}
        for i = 1, 4 do
            local member = Build("party" .. i, Party.preview, false, true)
            Party.preview.members[i] = member
            Party.preview.pets[i] = Build("partypet" .. i, member, true, true)
            Party.preview.targets[i] = BuildTarget(member, true)
        end
    end
    local db, root = DB(), Party.preview
    local scale, petScale = Party.GetScale(db), Scale(db.partyPetScale, 1)
    root:ClearAllPoints()
    root:SetPoint("TOPRIGHT", FluxRaidState.containerFrame, "TOPRIGHT", 0, 0)
    for i = 1, 4 do
        local frame, pet, target = root.members[i], root.pets[i], root.targets[i]
        LayoutVisuals(frame, pet, target, db, scale, petScale)
        local hasPet = db.partyShowPets ~= false and i % 2 == 1
        LayoutTextHosts(frame, hasPet, petScale)
        frame._fluxPartyPreviewClass = ({"WARRIOR", "PRIEST", "MAGE", "DRUID"})[i]
        Party.PaintChrome(frame)
        AnchorSlot(frame, i, root, scale)
        frame.nameText:SetText("Party member " .. i)
        frame.Health:SetMinMaxValues(0, 100); frame.Health:SetValue(100 - i * 8)
        frame.Health.Percent:SetText((100 - i * 8) .. "%")
        frame.Health.Value:SetText((100 - i * 8) * 100 .. " / 10000")
        if frame.Health.HealthStatusLabel then frame.Health.HealthStatusLabel:Hide() end
        local status = ({[2] = PLAYER_OFFLINE or "Offline", [3] = DEAD or "Dead", [4] = CHAT_MSG_AFK or "AFK"})[i]
        Party.PaintStatus(frame, status)
        frame.Power:SetMinMaxValues(0, 100); frame.Power:SetValue(75)
        if frame.Power.Value then frame.Power.Value:SetText("7500 / 10000") end
        if frame.Power.Percent then frame.Power.Percent:SetText("75%") end
        for _, key in ipairs({"Health", "Power"}) do
            local bar = frame[key]
            local texture = bar:GetStatusBarTexture()
            if texture and texture.SetDesaturated then texture:SetDesaturated(status ~= nil) end
            if status then bar:SetStatusBarColor(.5, .5, .5)
            elseif UF.UsesHudUnitBars and UF.UsesHudUnitBars() then bar:SetStatusBarColor(1, 1, 1)
            elseif key == "Health" then bar:SetStatusBarColor(0, 1, 0)
            else bar:SetStatusBarColor(0, 0, 1) end
        end
        if FluxRaidPreview and FluxRaidPreview.PaintPartyAuras then FluxRaidPreview.PaintPartyAuras(frame, i) end
        pet.Health:SetMinMaxValues(0, 100); pet.Health:SetValue(90)
        pet.Health.Percent:SetText("90%")
        pet.Health.Value:SetText("")
        if pet.Health.HealthStatusLabel then pet.Health.HealthStatusLabel:Hide() end
        pet:SetShown(hasPet)
        target.HealthBar:SetMinMaxValues(0, 100); target.HealthBar:SetValue(85 - i * 9)
        target.HealthBar:SetStatusBarColor(0, 1, 0)
        target:SetShown(db.partyShowTargets ~= false)
        Party.SetThreatColor(frame, 1, 0, 0)
        frame._fluxPartyThreat:SetShown(db.partyThreatHighlight ~= false and i == 1)
        local base = FluxRaidVisuals.FRAME_BASE_ALPHA or 1
        local alpha = base
        if db.showRangeFade ~= false and i ~= 2 then
            alpha = base * (i == 4 and (FluxRaidVisuals.RANGE_ALPHA_OUT_OF_RANGE or .44) or (FluxRaidVisuals.RANGE_ALPHA_IN_RANGE or .9))
        end
        frame:SetAlpha(alpha)
        for _, mirror in pairs(frame._fluxRangeMirrors or {}) do mirror:SetAlpha(alpha) end
        frame:Show()
        UF.UpdatePortrait(frame, "player")
        Party.StyleText(frame)
        Party.ApplyTextModes(frame)
    end
    root:Show()
end

function Party.ApplyOptions()
    if InCombatLockdown() then
        Flux.Combat.Defer("party.options", Party.ApplyOptions)
        return false
    end
    if ns.FocusFrame and ns.FocusFrame._fluxCompactFocus and FluxUnitFrames_ApplyFrameSizesFromDB then
        FluxUnitFrames_ApplyFrameSizesFromDB()
    end
    local db, state = DB(), FluxRaidState
    local enabled = db.useFluxRaidFrames ~= false and db.partyAsRaid == false
    if not enabled then
        Party.ready = false
        if FluxRaidSecure and FluxRaidSecure.DisablePartyFrames then FluxRaidSecure.DisablePartyFrames() end
        for _, frame in ipairs(Party.members) do
            if frame.CastBar then frame.CastBar._fluxPetCastDisabled = true; frame.CastBar:Hide() end
        end
        return true
    end
    if not state or not state.containerFrame or not Flux.securePhaseReady then return false end
    local scale = Party.GetScale(db)
    local petScale = Scale(db.partyPetScale, 1)
    for i = 1, 4 do
        local frame = Party.members[i]
        if not frame then
            frame = Build("party" .. i, state.containerFrame, false)
            Party.members[i] = frame
            Party.pets[i] = Build("partypet" .. i, frame, true)
            Party.targets[i] = BuildTarget(frame, false)
        end
        local pet, target = Party.pets[i], Party.targets[i]
        LayoutVisuals(frame, pet, target, db, scale, petScale)
        AnchorSlot(frame, i, state.containerFrame, scale)
        PaintTarget(target)
        Paint(frame)
        Paint(pet)
        FluxRaidAuras.Refresh(frame)
    end
    state.partyRangeFrames = state.partyRangeFrames or {}
    for _, frame in ipairs(Party.members) do state.partyRangeFrames[frame] = true end
    Party.ready = FluxRaidSecure.ConfigurePartyFrames(Party.members, Party.pets, scale, petScale,
        db.partyShowPets ~= false, db.partyShowPortrait ~= false, Party.targets,
        {showTargets = db.partyShowTargets ~= false, height = select(2, Party.GetSizing(db))})
    if FluxRaid_EnsureRangePoll then FluxRaid_EnsureRangePoll() end
    if UF.RefreshDebuffTint then UF.RefreshDebuffTint() end
    return Party.ready
end

function Party.Diagnostics()
    local function read(frame, method)
        if not frame or not frame[method] then return "missing" end
        local value = frame[method](frame)
        if Secret(value) then return "opaque" end
        return tostring(value)
    end
    local db, state = DB(), FluxRaidState or {}
    local group = IsInRaid and IsInRaid() and "raid" or IsInGroup and IsInGroup() and "party" or "solo"
    local parts = {"party-display-v7", "group=" .. group,
        "drivers=" .. (FluxRaidSecure.GetPartyStates and FluxRaidSecure.GetPartyStates() or "missing"),
        "raidStyle=" .. tostring(db.partyAsRaid ~= false), "ready=" .. tostring(Party.ready),
        "secure=" .. tostring(state.secureConfigured), "dock=" .. read(state.containerFrame,"IsVisible"),
        "dockAlpha=" .. read(state.containerFrame,"GetAlpha")}
    for i = 1, 4 do
        local frame = Party.members[i]
        parts[#parts + 1] = "p" .. i .. "=" .. read(frame,"IsShown") .. "/" .. read(frame,"IsVisible")
            .. "/a" .. read(frame,"GetAlpha") .. "/x" .. read(frame,"GetLeft") .. "/y" .. read(frame,"GetTop")
    end
    return table.concat(parts, " ")
end

Flux.Module.Register("UnitFrame.party", {
    phase = "secure", priority = 71, protected = true,
    OnEnable = function()
        Party.ApplyOptions()
        if FluxRaid_QueueConfigureAndRefresh then FluxRaid_QueueConfigureAndRefresh() end
    end,
})
