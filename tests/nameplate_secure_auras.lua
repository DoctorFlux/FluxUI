-- Exercise the real secure-row adapter against the public AuraContainer contract.
-- Secure assignment, rendered pixels and native frame protection require WoW.
local checks = 0
local auraMedia = [[Interface\AddOns\_FluxUI\Texture\NameplateAuras\]]
local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

local unpackValues = table.unpack or unpack

local function loadModule(path, env, ns)
    local chunk, reason
    if setfenv then
        chunk, reason = loadfile(path)
        if chunk then setfenv(chunk, env) end
    else
        chunk, reason = loadfile(path, "t", env)
    end
    return assert(chunk, reason)("_FluxUI", ns)
end

local function fixture(client, failure)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    local containers, frames = {}, {}
    local calls = { auraReads = 0, groups = 0, errors = 0, filterWrites = 0 }
    local props = {}
    local widget

    function props:GetParent() return self.parent end
    function props:SetParent(parent) self.parent = parent end
    function props:EnableMouse(enabled) self.mouse, self.mouseMotion, self.mouseClick = enabled, enabled, enabled end
    function props:EnableMouseMotion(enabled) self.mouseMotion = enabled end
    function props:SetMouseMotionEnabled(enabled) self.mouseMotion = enabled end
    function props:SetMouseClickEnabled(enabled) self.mouseClick = enabled end
    function props:GetObjectType() return self.kind end
    function props:IsObjectType(kind) return self.kind == kind end
    function props:RegisterEvent(event) self.events[event] = true end
    function props:SetScript(script, callback) self.scripts[script] = callback end
    function props:HookScript(script, callback)
        local previous = self.scripts[script]
        self.scripts[script] = function(...)
            if previous then previous(...) end
            callback(...)
        end
    end
    function props:IsForbidden() return self.forbidden == true end
    function props:CanBeAccessedInContext() return not self.forbidden end
    function props:GetFrameLevel() return self.level end
    function props:SetFrameLevel(level) self.level = level end
    function props:SetFrameStrata(strata) self.strata = strata end
    function props:GetFrameStrata() return self.strata end
    function props:Show()
        if self.shown then return end
        self.shown = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function props:Hide()
        if not self.shown then return end
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function props:SetShown(shown) self.shown = shown end
    function props:IsShown() return self.shown end
    function props:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function props:GetChildren()
        local children = {}
        for _, frame in ipairs(frames) do
            if frame.parent == self and frame.kind ~= "Texture" and frame.kind ~= "MaskTexture"
                and frame.kind ~= "FontString" then children[#children + 1] = frame end
        end
        return unpackValues(children)
    end
    function props:GetAlpha() return self.alpha end
    function props:SetAlpha(alpha)
        if self.rejectAlpha then error("native alpha write refused") end
        self.alpha = alpha
        self.alphaWrites = self.alphaWrites + 1
    end
    function props:GetEffectiveAlpha() return self.alpha * (self.parent and self.parent:GetEffectiveAlpha() or 1) end
    function props:SetScale(scale) self.scale = scale end
    function props:GetScale() return self.scale end
    function props:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
    function props:GetWidth() return self.width end
    function props:GetHeight() return self.height end
    function props:GetSize() return self.width, self.height end
    function props:SetWidth(width) self.width = width end
    function props:SetHeight(height) self.height = height end
    function props:SetSize(width, height) self.width, self.height = width, height end
    function props:GetPoint(index) return unpackValues(self.points[index or 1] or {}) end
    function props:GetNumPoints() return #self.points end
    function props:ClearAllPoints() self.points = {} end
    function props:SetPoint(point, relative, relativePoint, x, y)
        if type(relative) == "table" and relative.rejectAnchors then error("native anchor refused") end
        self.points[#self.points + 1] = { point, relative, relativePoint, x, y }
    end
    function props:SetAllPoints(relative)
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", relative, "TOPLEFT", 0, 0)
        self:SetPoint("BOTTOMRIGHT", relative, "BOTTOMRIGHT", 0, 0)
    end
    function props:CreateTexture(_, layer, template, sublevel)
        assert(template == nil or type(template) == "string", "texture template must be a string")
        assert(sublevel == nil or type(sublevel) == "number", "draw sublevel must be numeric")
        local texture = widget("Texture", self)
        texture.layer, texture.sublevel = layer, sublevel
        self.regions[#self.regions + 1] = texture
        return texture
    end
    function props:CreateMaskTexture() return widget("MaskTexture", self) end
    function props:AddMaskTexture(mask) self.mask = mask end
    function props:CreateFontString() return widget("FontString", self) end
    function props:SetTexture(texture, wrapX, wrapY) self.texture, self.wrapX, self.wrapY = texture, wrapX, wrapY end
    function props:SetAtlas(atlas) self.atlas = atlas end
    function props:SetTexCoord(...) self.texCoord = { ... } end
    function props:SetDrawLayer(layer, sublevel) self.layer, self.sublevel = layer, sublevel end
    function props:SetColorTexture(...) self.fill = { ... } end
    function props:SetVertexColor(...) self.color = { ... } end
    function props:SetFont(...) self.font = { ... } return true end
    function props:SetText(text) self.text = text end
    function props:GetText() return self.text end
    function props:SetJustifyH(justification) self.justifyH = justification end
    function props:SetJustifyV(justification) self.justifyV = justification end
    function props:SetTextColor(...) self.textColor = { ... } end
    function props:GetTextColor() return unpackValues(self.textColor or { 1, 1, 1, 1 }) end
    function props:GetCountdownFontString() return self.digits end
    function props:SetReverse(reverse) self.reverse = reverse end
    function props:SetSwipeTexture(texture) self.swipe = texture end
    function props:SetSwipeColor(...) self.swipeColor = { ... } end
    function props:SetDrawSwipe(show) self.drawSwipe = show end
    function props:SetEdgeTexture(texture) self.edge = texture end
    function props:SetEdgeScale(scale) self.edgeScale = scale end
    function props:SetDrawEdge(show) self.drawEdge = show end
    function props:SetHideCountdownNumbers(hidden) self.hideCountdown = hidden end
    function props:SetDrawBling(show) self.drawBling = show end
    function props:SetUseAuraDisplayTime(enabled) self.auraDisplayTime = enabled end
    function props:SetHideTooltipInCombat(hidden) self.hideTooltip = hidden end
    function props:SetIcon(icon) self.icon = icon end
    function props:SetDurationCooldown(cooldown) self.cooldown = cooldown end
    function props:SetDurationText(region, options) self.durationText, self.durationOptions = region, options end
    function props:ClearDurationText() self.durationText, self.durationOptions = nil, nil end
    function props:SetApplicationCount(count) self.applicationCount = count end
    function props:AddDispelTypeTexture(texture, options)
        assert(texture:IsObjectType("Texture"), "only textures are valid dispel sinks")
        local owner = texture:GetParent()
        while owner and owner ~= self do owner = owner:GetParent() end
        assert(owner == self, "the dispel texture must descend from its secure aura button")
        if failure == "dispel" then error("native dispel binding refused") end
        self.dispel[#self.dispel + 1] = { texture = texture, options = options }
    end
    function props:SetEditModePreviewEnabled(enabled) self.preview = enabled end
    function props:SetEnabled(enabled) self.enabled = enabled end
    function props:SetAuraProcessingPolicy(policy, options) self.policy = { policy, options } end
    function props:SetFlowLayoutAxis(axis) self.axis = axis end
    function props:SetFlowLayoutAnchorPoint(point) self.origin = point end
    function props:SetFlowLayoutGrowthDirection(x, y) self.growth = { x, y } end
    function props:SetFlowLayoutMaximumLineSize(size) self.lineSize = size end
    function props:SetFlowLayoutPadding(...) self.padding = { ... } end
    function props:SetUnit(unit)
        if failure == "unit" and unit and unit ~= "none" then error("native unit assignment refused") end
        self.unit = unit
        self.unitWrites = self.unitWrites + 1
    end
    function props:AddAuraGroup(key, filter, options)
        calls.groups = calls.groups + 1
        if failure == "ccGroup" and filter:find("|CROWD_CONTROL", 1, true) then error("native CC filter refused") end
        assert(not self.groups[key], "group added twice")
        local button = widget("AuraButton", self)
        local group = { filter = filter, options = options, button = button, enabled = true }
        self.groups[key] = group
        if options.initializeFrame then options.initializeFrame(button) end
        return true
    end
    function props:HasAuraGroup(key) return self.groups[key] ~= nil end
    function props:GetAuraGroupFrame(key) return self.groups[key] and self.groups[key].button end
    function props:GetAuraGroupFrameCount(key) return self.groups[key] and 1 or 0 end
    function props:SetAuraGroupEnabled(key, enabled) self.groups[key].enabled = enabled end
    function props:SetAuraGroupLayout(key, layout) self.groups[key].options.layout = layout end
    function props:SetAuraGroupMaxFrameCount(key, count) self.groups[key].options.maxFrameCount = count end
    function props:SetAuraGroupFilterString(key, filter)
        calls.filterWrites = calls.filterWrites + 1
        self.groups[key].filter = filter
        if self.rejectFilterChange then return false end
    end
    function props:SetAuraGroupCandidateFilters(key, filters) self.groups[key].options.candidateFilters = filters end
    function props:RemoveAuraGroup(key) self.groups[key] = nil end

    widget = function(kind, parent)
        local frame = setmetatable({ kind = kind, parent = parent, width = 25, height = 25, level = 1,
            alpha = 1, alphaWrites = 0, unitWrites = 0, shown = true, scale = 1, points = {}, groups = {},
            dispel = {}, regions = {}, scripts = {}, events = {} }, { __index = props })
        frames[#frames + 1] = frame
        return frame
    end
    env.UIParent = widget("Frame")
    env.CreateFrame = function(kind, _, parent, template)
        local frame = widget(kind, parent)
        if kind == "AuraContainer" then
            assert(template == "CustomAuraContainerTemplate", "secure rows use a Blizzard AuraContainer template")
            if failure == "template" then error("AuraContainer unavailable") end
            containers[#containers + 1] = frame
        end
        return frame
    end
    env.C_AddOns = { IsAddOnLoaded = function() return failure ~= "addon" end,
        DoesAddOnExist = function() return failure ~= "addon" end,
        LoadAddOn = function() return failure ~= "addon" end }
    env.C_CVar = { GetCVarBool = function() return env.showAll == true end }
    env.CVarCallbackRegistry = { GetCVarValueBool = function() return false end }
    env.CreateColor = function(red, green, blue, alpha)
        return { r = red, g = green, b = blue, a = alpha,
            GetRGBA = function() return red, green, blue, alpha end }
    end
    env.Enum = { CustomAuraButtonDispelTypeTextureStyle = { Icon = 2, PreserveAsset = 3 } }
    env.AnchorUtil = { FlowLayoutAxis = { Horizontal = 0 }, FlowDirection = { Left = 1, Right = 2, Up = 3, Down = 4 } }
    env.AuraContainerSortMethod = { Default = 0, Nameplate = 1, DefaultAura = 2 }
    env.AuraContainerSortDirection = { Normal = 0 }
    env.CustomAuraContainerAuraProcessingPolicy = { None = 0 }
    env.NamePlateConstants = { AURA_ITEM_HEIGHT = 25, PREVIEW_UNIT_TOKEN = "preview",
        SHOW_ALL_PERSONAL_AURAS_CVAR = "nameplateShowAllPersonalAuras" }
    env.FluxUI_DB = { nameplateThreat = { questOverlayEnabled = false } }
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC = 1, 2
    env.WOW_PROJECT_ID = client.isAnyClassic and env.WOW_PROJECT_CLASSIC or env.WOW_PROJECT_MAINLINE
    env.UnitIsFriend = function() return env.friendly == true end
    env.UnitCanAttack = function() return env.friendly ~= true end
    env.UnitIsPlayer = function() return env.player == true end
    env.UnitExists = function() return true end
    env.GetTime = function() return env.seconds or 1 end
    env.InCombatLockdown = function() return env.combat == true end
    env.geterrorhandler = function() return function() calls.errors = calls.errors + 1 end end
    env.issecretvalue = function(value) return type(value) == "table" and value.secret == true end
    env.canaccessvalue = function(value) return not env.issecretvalue(value) end
    local function prohibitedAuraRead()
        calls.auraReads = calls.auraReads + 1
        error("test does not expose any restricted aura fields to addon Lua")
    end
    env.C_UnitAuras = setmetatable({}, { __index = function() return prohibitedAuraRead end })
    env.UnitAura = prohibitedAuraRead

    local plate = widget("Frame", env.UIParent)
    local unitFrame = widget("Frame", plate)
    plate.UnitFrame = unitFrame
    unitFrame.AurasFrame = widget("Frame", unitFrame)
    local auras = unitFrame.AurasFrame
    auras.auraItemScale = 1.2
    auras.unitToken = "nameplate1"
    auras.DebuffListFrame = widget("Frame", auras)
    auras.DebuffListFrame.maxAuraItemsDisplayed = 12
    auras.DebuffListFrame.stride = 7
    auras.DebuffListFrame.requireSourceIsLocalPlayer = true
    auras.DebuffListFrame:SetPoint("BOTTOMLEFT", unitFrame, "TOPLEFT", 0, 6)
    auras.DebuffListFrame.alpha = .8
    auras.BuffListFrame = widget("Frame", auras)
    auras.CrowdControlListFrame = widget("Frame", auras)
    auras.CrowdControlListFrame.maxAuraItemsDisplayed = 2
    auras.CrowdControlListFrame:SetPoint("LEFT", unitFrame, "RIGHT", 5, 0)
    auras.LossOfControlFrame = widget("Frame", auras)
    auras.LossOfControlFrame:SetSize(30, 30)
    auras.LossOfControlFrame:SetPoint("LEFT", unitFrame, "RIGHT", 5, 0)
    auras.LossOfControlFrame:Hide()
    local function nativeAura(parent, label)
        local button = widget("Frame", parent)
        button.layoutIndex = 1
        button:SetAllPoints(parent)
        button.Icon = button:CreateTexture(nil, "ARTWORK")
        button.Cooldown = widget("Cooldown", button)
        local digits = button.Cooldown:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        digits:SetText(label)
        button.Cooldown.digits = digits
        return button
    end
    local debuffButton = nativeAura(auras.DebuffListFrame, "8")
    local ccButton = nativeAura(auras.CrowdControlListFrame, "5")
    local buffButton = nativeAura(auras.BuffListFrame, "9")
    auras.LossOfControlFrame.AuraItemFrame = nativeAura(auras.LossOfControlFrame, "4")

    local ns = { Flux = { Client = client, Cap = {} }, UnitFrames = {
        UseEngineAuras = function() return not client.isAnyClassic and failure ~= "addon" end,
    } }
    loadModule("Core/API/Aura.lua", env, ns)
    loadModule("NamePlates/Core.lua", env, ns)
    local np = ns.Flux.NamePlates
    np.activeUnits[auras.unitToken] = true
    env.C_NamePlate = { GetNamePlateForUnit = function() return plate end }
    loadModule("NamePlates/SecureAuras.lua", env, ns)
    local secure = assert(np.SecureAuras)
    return { env = env, np = np, secure = secure, plate = plate, auras = auras, containers = containers,
        calls = calls, ns = ns, frames = frames, sourceUnit = auras.unitToken,
        debuffButton = debuffButton, ccButton = ccButton, buffButton = buffButton }
end

local forever = { name = "Forever", isRetail = true, isForever = true, isCamelot = true, majorVersion = 1 }
local retail = { name = "Retail", isRetail = true, isLiveMidnight = true, majorVersion = 12 }
local classic = { name = "Era", isAnyClassic = true, isClassicEra = true, majorVersion = 1 }

local function update(setup, placement, pixels, onlyMine)
    return setup.secure.Update(setup.plate, setup.sourceUnit, setup.auras, placement or "middle", pixels or 12, onlyMine)
end

local function secureGroups(setup)
    local debuff, cc, debuffContainer, ccContainer
    for _, container in ipairs(setup.containers) do
        for _, group in pairs(container.groups) do
            if group.filter:find("|CROWD_CONTROL", 1, true) then
                cc, ccContainer = group, container
            elseif group.filter:find("HARMFUL", 1, true) then
                debuff, debuffContainer = group, container
            end
        end
    end
    return debuff, cc, debuffContainer, ccContainer
end

local function checkBindings(group, label)
    local button = group.button
    local border, glyph = 0, 0
    for _, binding in ipairs(button.dispel) do
        local options = binding.options
        if options.style == 3 and options.showWithoutDispelType
            and binding.texture.texture == auraMedia .. "IconBorder.tga" then
            local colors = options.customDispelColorMap
            if colors and colors.None.r == .95 and colors.None.g == .32
                and colors.Magic.r == .38 and colors.Magic.g == .65 and colors.Magic.b == 1 then
                border = border + 1
            end
        end
        if options.style == 2 and options.showWhenHarmful and not options.showWhenHelpful
            and not options.showWithoutDispelType and binding.texture:GetPoint() == "TOPRIGHT" then glyph = glyph + 1 end
    end
    check(border == 1 and glyph == 1 and #button.dispel == 2,
        label .. " registers one beveled type border and one exact top-right glyph with Blizzard")
    check(button.icon and button.cooldown and button.applicationCount and button.durationText,
        label .. " keeps the native icon, sweep, stacks and countdown bindings")
    local icon, cooldown = button.icon, button.cooldown
    local _, _, _, x, y = icon:GetPoint()
    local crop = icon.texCoord or {}
    check(icon.mask and icon.mask.texture == auraMedia .. "IconMask.tga"
        and icon.mask.wrapX == "CLAMPTOBLACKADDITIVE" and icon.mask.wrapY == "CLAMPTOBLACKADDITIVE"
        and x == button:GetWidth() * 6 / 128 and y == -x
        and crop[1] == .08 and crop[2] == .92 and crop[3] == .08 and crop[4] == .92,
        label .. " clips the cropped spell icon under the inset square bevel")
    check(cooldown.reverse and cooldown.swipe == auraMedia .. "IconMask.tga"
        and cooldown.edge == auraMedia .. "Edge.tga" and cooldown.edgeScale == 1.6,
        label .. " uses the same square mask for the reverse swipe and the matching edge artwork")
    check(button.mouseMotion and button.mouseClick == false and not button.scripts.OnEnter and not button.scripts.OnLeave,
        label .. " leaves aura tooltip motion to Blizzard and allows mouse clicks through")
end

for _, client in ipairs({ forever, retail }) do
    local setup = fixture(client)
    local auras = setup.auras
    local ownsDebuff, ownedCCLane = update(setup)
    check(ownsDebuff and ownedCCLane == auras.CrowdControlListFrame,
        client.name .. " activates secure harmful rows")
    local debuff, cc, debuffContainer, ccContainer = secureGroups(setup)
    check(debuff and cc and debuffContainer ~= ccContainer, client.name .. " creates independent debuff and CC groups")
    local localSource = debuff.filter:find("|PLAYER", 1, true)
        or (debuff.options.candidateFilters and debuff.options.candidateFilters.isFromPlayerOrPlayerPet)
    check(debuff.filter:find("|!CROWD_CONTROL", 1, true) and localSource,
        client.name .. " preserves the hostile regular debuff lane and local source filtering")
    check(debuff.options.maxFrameCount == 12 and cc.options.maxFrameCount == 2,
        client.name .. " copies native limits for both lanes")
    check(debuffContainer.unit == setup.sourceUnit and ccContainer.unit == setup.sourceUnit,
        client.name .. " assigns native containers to the exact world unit")
    local debuffHost, ccHost = debuffContainer:GetParent(), ccContainer:GetParent()
    local _, debuffAnchor = debuffHost:GetPoint()
    local _, ccAnchor = ccHost:GetPoint()
    check(debuffHost:GetParent() == setup.plate and ccHost:GetParent() == setup.plate
        and debuffAnchor == auras.DebuffListFrame and ccAnchor == auras.CrowdControlListFrame
        and debuffHost:GetScale() == auras.auraItemScale, client.name .. " follows and scales with the stock lanes from outside the UnitFrame")
    checkBindings(debuff, client.name .. " regular debuff")
    checkBindings(cc, client.name .. " CC")
    check(auras.DebuffListFrame:GetAlpha() == 0 and auras.CrowdControlListFrame:GetAlpha() == 0
        and auras.BuffListFrame:GetAlpha() == 1 and auras:GetAlpha() == 1,
        client.name .. " transfers harmful artwork only")
    local allocations = #setup.containers
    local unitWrites = debuffContainer.unitWrites + ccContainer.unitWrites
    setup.env.combat = true
    for _ = 1, 3 do check(update(setup), client.name .. " retains secure rows during restricted combat") end
    check(setup.calls.auraReads == 0 and #setup.containers == allocations
        and debuffContainer.unitWrites + ccContainer.unitWrites == unitWrites,
        client.name .. " repeats no setup, unit assignment or insecure aura queries while stable")

    local debuffFilter, ccFilter = debuff.filter, cc.filter
    local ownsMineDebuff, ownsMineCC = update(setup, nil, nil, true)
    check(ownsMineDebuff and ownsMineCC == auras.CrowdControlListFrame and setup.calls.filterWrites == 2
        and debuff.filter == debuffFilter .. "|PLAYER" and cc.filter == ccFilter .. "|PLAYER",
        client.name .. " applies engine ownership to both harmful rows")
    update(setup, nil, nil, true)
    check(setup.calls.filterWrites == 2 and setup.calls.auraReads == 0,
        client.name .. " leaves settled filters alone and does not read aura ownership in Lua")
    update(setup, nil, nil, false)
    check(setup.calls.filterWrites == 4 and debuff.filter == debuffFilter and cc.filter == ccFilter
        and #setup.containers == allocations and debuffContainer.unitWrites + ccContainer.unitWrites == unitWrites,
        client.name .. " turning the filter off restores both groups without starting them again")

    check(debuff.options.candidateFilters.nameplateShowPersonal == true and debuff.options.candidateFilters.nameplateShowAll == false,
        client.name .. " retains the stock personal-only regular debuff policy")
    setup.env.showAll = true
    auras.DebuffListFrame.requireSourceIsLocalPlayer = false
    check(update(setup, "none"), client.name .. " refreshes native aura settings while keeping secure ownership")
    check(debuff.options.candidateFilters.nameplateShowPersonal == nil and debuff.options.candidateFilters.isFromPlayerOrPlayerPet == nil
        and debuff.button.durationText == nil and #debuff.button.dispel == 2,
        client.name .. " updates aura filters and hides only the countdown when disabled")
    check(update(setup, "below", 16) and debuff.button.durationText:GetPoint() == "TOP",
        client.name .. " applies the current countdown placement to bound native text")

    setup.env.player = true
    auras.CrowdControlListFrame:Hide()
    auras.LossOfControlFrame:Show()
    ownsDebuff, ownedCCLane = update(setup, nil, nil, true)
    check(ownsDebuff and ownedCCLane == auras.LossOfControlFrame,
        client.name .. " switches to the side lane used by player control")
    local _, currentCC = secureGroups(setup)
    check(currentCC.filter == ccFilter .. "|PLAYER" and currentCC.options.maxFrameCount == 1 and auras.LossOfControlFrame:GetAlpha() == 0
        and auras.CrowdControlListFrame:GetAlpha() == 1,
        client.name .. " restores the previous CC lane and filters the player control slot")

    setup.secure.Release(setup.sourceUnit)
    check(auras.DebuffListFrame:GetAlpha() == .8 and auras.CrowdControlListFrame:GetAlpha() == 1
        and auras.LossOfControlFrame:GetAlpha() == 1, client.name .. " restores all native lane alpha on removal")
    check(not debuffContainer:IsVisible() and not ccContainer:IsVisible()
        and (not debuffContainer.unit or debuffContainer.unit == "none") and (not ccContainer.unit or ccContainer.unit == "none"),
        client.name .. " retires and unbinds pooled secure rows")
    setup.sourceUnit = "nameplate2"
    auras.unitToken = setup.sourceUnit
    local recyclesDebuff, recycledCCLane = update(setup)
    check(recyclesDebuff and recycledCCLane == auras.LossOfControlFrame and #setup.containers == allocations
        and debuffContainer.unit == "nameplate2" and ccContainer.unit == "nameplate2",
        client.name .. " safely reuses the same secure rows for a recycled nameplate")
    auras.unitToken = "nameplate3"
    local staleDebuff, staleCC = update(setup)
    check(not staleDebuff and not staleCC and auras.DebuffListFrame:GetAlpha() == .8
        and debuffContainer.unit == "none" and ccContainer.unit == "none",
        client.name .. " releases both secure rows until Blizzard's reused unit token matches")
    auras.unitToken = { secret = true }
    local opaqueDebuff, opaqueCC = update(setup)
    check(not opaqueDebuff and not opaqueCC and #setup.containers == allocations,
        client.name .. " defers secure ownership for an unreadable native owner")
    auras.unitToken = setup.sourceUnit
    local restoredDebuff, restoredCC = update(setup)
    check(restoredDebuff and restoredCC == auras.LossOfControlFrame and #setup.containers == allocations,
        client.name .. " can recover as soon as the native unit association is readable")
end

local freshFilter = fixture(forever)
check(update(freshFilter, nil, nil, true), "the saved filter can take effect on the first secure update")
local freshDebuff, freshCC, freshDebuffBox, freshCCBox = secureGroups(freshFilter)
check(freshDebuff.filter == "HARMFUL|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL|PLAYER"
    and freshCC.filter == "HARMFUL|CROWD_CONTROL|PLAYER" and freshFilter.calls.filterWrites == 0,
    "new groups are created with the saved engine filter")
freshDebuffBox.rejectFilterChange, freshCCBox.rejectFilterChange = true, true
local acceptedDebuff, acceptedCC = update(freshFilter, nil, nil, false)
check(not acceptedDebuff and not acceptedCC and freshFilter.auras.DebuffListFrame:GetAlpha() == .8
    and freshFilter.auras.CrowdControlListFrame:GetAlpha() == 1,
    "a refused filter write releases secure ownership and restores both stock lanes")
freshDebuffBox.rejectFilterChange, freshCCBox.rejectFilterChange = false, false
update(freshFilter, nil, nil, true)
check(freshDebuff.filter == "HARMFUL|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL|PLAYER"
    and freshCC.filter == "HARMFUL|CROWD_CONTROL|PLAYER" and freshFilter.calls.filterWrites == 4,
    "retry restores the requested filter after a partial native write")

for _, failure in ipairs({ "addon", "template", "unit", "dispel" }) do
    local setup = fixture(forever, failure)
    check(not update(setup) and setup.auras.DebuffListFrame:GetAlpha() == .8
        and setup.auras.CrowdControlListFrame:GetAlpha() == 1, failure .. " leaves the working native rows visible")
    for _, container in ipairs(setup.containers) do
        check(not container:IsVisible(), failure .. " leaves no duplicate partially prepared secure row")
    end
end

local rejectedCC = fixture(forever, "ccGroup")
local _, lostCCLane = update(rejectedCC)
check(not lostCCLane and rejectedCC.auras.CrowdControlListFrame:GetAlpha() == 1,
    "a rejected CC group leaves the original CC row visible")

local deniedAnchors = fixture(forever)
deniedAnchors.auras.DebuffListFrame.rejectAnchors = true
deniedAnchors.auras.CrowdControlListFrame.rejectAnchors = true
local orphanDebuff, orphanCC = update(deniedAnchors)
check(not orphanDebuff and not orphanCC and deniedAnchors.auras.DebuffListFrame:GetAlpha() == .8,
    "native geometry rejection leaves no detached artwork and preserves Blizzard's lane")

local deniedAlpha = fixture(forever)
deniedAlpha.auras.DebuffListFrame.rejectAlpha = true
deniedAlpha.auras.CrowdControlListFrame.rejectAlpha = true
local duplicateDebuff, duplicateCC = update(deniedAlpha)
check(not duplicateDebuff and not duplicateCC and deniedAlpha.auras.DebuffListFrame:GetAlpha() == .8,
    "native alpha rejection leaves the original icons and does not enable a duplicate row")
for _, container in ipairs(deniedAlpha.containers) do
    check(not container:IsVisible() and container.unit == "none", "alpha rejection unwinds native container assignment")
end

local idle = fixture(forever)
idle.debuffButton:Hide()
idle.ccButton:Hide()
local hiddenDebuff, hiddenCC = update(idle)
check(not hiddenDebuff and not hiddenCC and #idle.containers == 0,
    "hidden stock icons do not allocate any secure AuraContainer")

local setup = fixture(classic)
check(not update(setup) and #setup.containers == 0 and setup.auras.DebuffListFrame:GetAlpha() == .8,
    "clients without the secure aura engine keep the stock aura path")

local integrated = fixture(forever)
local tooltip = {}
function tooltip:IsForbidden() return false end
function tooltip:IsOwned(owner) return self.owner == owner end
function tooltip:SetOwner(owner) self.owner = owner end
function tooltip:SetSpellByID(spell) self.spell = spell end
function tooltip:Show() self.shown = true end
function tooltip:Hide() self.owner, self.shown = nil, false end
integrated.env.GameTooltip = tooltip
integrated.debuffButton.spellID = 589
integrated.buffButton.spellID = 1459
local canUseEngine = false
integrated.ns.UnitFrames.UseEngineAuras = function() return canUseEngine end
integrated.np.activeUnits[integrated.sourceUnit] = nil
loadModule("NamePlates/Countdown.lua", integrated.env, integrated.ns)
local nameplateEvents
for _, frame in ipairs(integrated.frames) do
    if frame.events.NAME_PLATE_UNIT_ADDED then nameplateEvents = frame break end
end
local function CountdownHost(button)
    for _, child in ipairs({ integrated.plate:GetChildren() }) do
        if child.text and child._fluxAnchor == button.Cooldown then return child end
    end
end
local function HoverHost(button)
    for _, child in ipairs({ integrated.plate:GetChildren() }) do
        if child.scripts.OnEnter and select(2, child:GetPoint()) == button then return child end
    end
end
nameplateEvents.scripts.OnEvent(nameplateEvents, "NAME_PLATE_UNIT_ADDED", integrated.sourceUnit)
local stockDebuffTimer = CountdownHost(integrated.debuffButton)
local stockCCTimer = CountdownHost(integrated.ccButton)
local stockBuffTimer = CountdownHost(integrated.buffButton)
check(stockDebuffTimer and stockDebuffTimer:IsShown() and stockCCTimer and stockCCTimer:IsShown()
    and stockBuffTimer and stockBuffTimer:IsShown(), "the actual countdown traverses all native lanes before secure takeover")
local stockDebuffTip, stockBuffTip = HoverHost(integrated.debuffButton), HoverHost(integrated.buffButton)
stockDebuffTip.scripts.OnEnter(stockDebuffTip)
check(tooltip:IsOwned(stockDebuffTip) and tooltip.shown and tooltip.spell == 589,
    "Forever stock hover can own the displayed debuff tooltip before secure takeover")
canUseEngine = true
integrated.np.RefreshUnit(integrated.sourceUnit)
check(integrated.auras.DebuffListFrame:GetAlpha() == 0 and integrated.auras.CrowdControlListFrame:GetAlpha() == 0
    and not stockDebuffTimer:IsShown() and not stockCCTimer:IsShown() and stockBuffTimer:IsShown(),
    "secure ownership suppresses duplicate legacy countdown hosts and retains the native buff countdown")
check(not tooltip.shown and not stockDebuffTip:IsShown() and stockBuffTip:IsShown(),
    "secure ownership closes the covered stock debuff tooltip while preserving buff hover")
stockBuffTip.scripts.OnEnter(stockBuffTip)
check(tooltip:IsOwned(stockBuffTip) and tooltip.spell == 1459,
    "stock buff mouseover still reflects the visible effect when secure debuff rows are active")
nameplateEvents.scripts.OnEvent(nameplateEvents, "NAME_PLATE_UNIT_REMOVED", integrated.sourceUnit)
check(integrated.auras.DebuffListFrame:GetAlpha() == .8 and integrated.auras.CrowdControlListFrame:GetAlpha() == 1,
    "native nameplate removal releases secure alpha leases through the actual countdown owner")
check(not tooltip.shown, "native removal closes the last hovered buff tooltip")
for _, container in ipairs(integrated.containers) do
    check(not container:IsVisible() and container.unit == "none", "countdown removal retires each secure AuraContainer")
end

local toc = assert(io.open("_FluxUI.toc", "r"))
local tocSource = toc:read("*a")
toc:close()
local coreLoad = tocSource:find("NamePlates\\Core.lua", 1, true)
local auraLoad = tocSource:find("Core\\API\\Aura.lua", 1, true)
local secureLoad = tocSource:find("NamePlates\\SecureAuras.lua [AllowLoadGameType camelot, mainline]", 1, true)
local countdownLoad = tocSource:find("NamePlates\\Countdown.lua", 1, true)
check(auraLoad and coreLoad and secureLoad and countdownLoad and auraLoad < secureLoad and coreLoad < secureLoad
    and secureLoad < countdownLoad, "the secure rows load only on supported clients after their owners and before the countdown driver")

print(("Secure nameplate auras: %d desktop checks; native assignment, rendering and taint pending"):format(checks))
