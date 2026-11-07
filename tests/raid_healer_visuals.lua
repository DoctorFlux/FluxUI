-- Desktop contracts for independently drawn healer cells and the shared world preview.
-- Real rendering, restricted values and secure hit testing need native acceptance.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local checks = 0
local function check(value, message) assert(value, message) checks = checks + 1 end
local combat, mutations, nativeAsset = false, 0, false
local named, secrets = {}, {}
local methods = {}
local function widget(parent)
    return setmetatable({ parent = parent, points = {}, shown = true, level = parent and parent.level + 1 or 1 }, { __index = methods })
end
function methods:SetParent(parent) mutations = mutations + 1 self.parent = parent end
function methods:SetAllPoints(parent) self.allPoints = parent end
function methods:EnableMouse(value) self.mouse = value end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(value) self.level = value end
function methods:CreateTexture() return widget(self) end
function methods:CreateFontString() return widget(self) end
function methods:SetColorTexture(...) self.colorTexture = { ... } end
function methods:SetGradient(direction, low, high) self.gradient = { direction, low, high } end
function methods:SetGradientAlpha(...) self.gradientAlpha = { ... } end
function methods:SetVertexColor(...) self.vertex = { ... } end
function methods:SetPoint(...) self.points[#self.points + 1] = { ... } end
function methods:ClearAllPoints() mutations = mutations + 1 self.points = {} self.allPoints = nil end
function methods:SetHeight(value) self.height = value end
function methods:SetWidth(value) self.width = value end
function methods:GetWidth() return self.width or 72 end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetStatusBarTexture(value) self.barTexture = value self.fill = self.fill or widget(self) end
function methods:GetStatusBarTexture() self.fill = self.fill or widget(self) return self.fill end
function methods:SetStatusBarColor(...) self.barColor = { ... } end
function methods:SetMinMaxValues(a, b) self.minimum, self.maximum = a, b end
function methods:SetValue(value) self.value = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetAlphaFromBoolean(value, yes, no) self.booleanAlpha = { value, yes, no } end
function methods:SetShown(value) self.shown = value end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetAtlas(value) self.atlas = value end
function methods:SetTexture(value) self.texture = value return nativeAsset and value == 8036209 or false end
function methods:SetBlendMode(value) self.blendMode = value end
function methods:SetTexCoord(...) self.texcoord = { ... } end
function methods:SetIgnoreParentAlpha(value) self.ignoreAlpha = value end
function methods:SetJustifyH(value) self.justify = value end
function methods:SetWordWrap(value) self.wrap = value end
function methods:SetFontObject(value) self.font = value end
function methods:SetFont(...) self.font = {...}; return true end
function methods:SetTextScale(value) self.textScale = value end
function methods:SetShadowColor(...) self.shadowColor = {...} end
function methods:SetShadowOffset(...) self.shadow = { ... } end
function methods:SetTextColor(...) self.textColor = { ... } end
function methods:SetText(value) self.text = value end
function methods:SetFormattedText(format, ...) self.format, self.formatValues = format, { ... } end
function methods:SetClipsChildren(value) self.clips = value end
function methods:RegisterForClicks() end
function methods:RegisterEvent() end
function methods:SetScript(key, fn) self[key] = fn end
function methods:SetFrameStrata(value) self.strata = value end
local function cell()
    local f = widget()
    for _, key in ipairs({ "background", "name", "statusText", "roleIcon", "leaderIcon", "masterLooterIcon", "raidTargetIcon", "selectionHighlight", "mouseOverHighlight", "aggroHighlight", "centerStatusIcon", "readyCheckIcon", "healthBar", "powerBar" }) do f[key] = widget(f) end
    f.healthBar.background, f.powerBar.background = widget(f.healthBar), widget(f.powerBar)
    f.centerStatusIcon.texture = widget(f.centerStatusIcon)
    f.readyCheckIcon.texture = widget(f.readyCheckIcon)
    return f
end
local db = { previewRosterSize = 10, previewShowMTColumn = false, healthText = "perc" }
local visualsSource = os.getenv("FLUX_RAID_VISUALS_SOURCE") or root .. "RaidFrame/FluxRaidVisuals.lua"
local env = {
    InCombatLockdown = function() return combat end,
    issecretvalue = function(v) return secrets[v] or false end,
    GameFontHighlightSmall = {}, UIParent = widget(),
    FluxOptions = { GetRaidFrameDB = function() return db end },
    FluxRaid_GetCVarBool = function(_, fallback) return fallback end,
    FluxRaid_GetColumnHeight = function() return 215 end,
    FluxRaid_GetMTMAChildStep = function() return 66 end,
    FluxRaid_GetPreviewStackVerticalPosition = function() return 120 end,
    IsInGroup = function() return false end,
    IsInRaid = function() return false end,
    UnitExists = function() return true end,
    UnitIsUnit = function() return false end,
    RAID_CLASS_COLORS = { WARRIOR = { r = 0.8, g = 0.6, b = 0.4 }, PRIEST = { r = 1, g = 1, b = 1 } },
}
setmetatable(env, { __index = _G })
env._G = env
-- The factory above closes over this local environment after construction.
env.CreateFrame = function(_, name, parent, template)
    local preview=template == "FluxRaidPreviewUnitTemplate" or template == "FluxRaidMiniPreviewTemplate"
    local f = preview and cell() or widget(parent)
    if template == "FluxRaidMiniPreviewTemplate" then f._fluxRaidMini=true end
    if name then named[name] = f end
    if preview then env.FluxRaidPreviewUnit_OnLoad(f) end
    return f
end
local ns = { Flux = { BlizzardSettings = { Write = { IsSecretClient = function() return true end } } } }
assert(loadfile(visualsSource, "t", env))("_FluxUI", ns)
local visuals = env.FluxRaidVisuals
visuals.ApplyRaidFrameTunables({})
-- This stub exercises the fit decision and ownership boundary, not real Friz
-- glyph metrics. Native rendering remains an independent acceptance check.
local probeFrames, probeReads, probeText, probeHost, unreadableProbe = 0, 0
local measuredLabels, opaqueProbe = {}, {}
secrets[opaqueProbe] = true
local probeEnv = setmetatable({}, { __index = env })
probeEnv._G = probeEnv
local function measurePublicLabel(self)
    check(self == probeText and self.parent == probeHost and probeHost.parent == env.UIParent
        and not probeHost.shown and #self.points == 0 and not self.allPoints,
        "fit measurements use an unanchored public probe outside native aura sinks")
    check(self.text == "59" or self.text == "59m" or self.text == "23h" or self.text == "99d",
        "the probe measures only fixed public compact-duration labels")
    probeReads = probeReads + 1
    measuredLabels[self.text] = true
    check(self.textScale == 1, "public sample metrics reset inherited text scaling before fitting")
    if unreadableProbe then return opaqueProbe end
    return (#self.text == 2 and 15.2 or 20) * self.font[2] / 7
end
probeEnv.CreateFrame = function(kind, _, parent)
    check(kind == "Frame", "font fitting creates a plain owned measuring frame")
    probeFrames = probeFrames + 1
    probeHost = widget(parent)
    function probeHost:CreateFontString(_, _, template)
        check(template == "GameFontHighlightSmall", "the probe shares the native duration font inheritance")
        probeText = widget(self)
        function probeText:SetFont(...) self.font = { ... } end
        function probeText:SetTextScale(value) self.textScale = value end
        function probeText:GetStringHeight() return self.font[2] * self.textScale end
        probeText.GetUnboundedStringWidth = measurePublicLabel
        return probeText
    end
    return probeHost
end
assert(loadfile(visualsSource, "t", probeEnv))("_FluxUI", ns)
local fontSize = assert(probeEnv.FluxRaidVisuals.GetAuraDurationFontSize)
local textScale = assert(probeEnv.FluxRaidVisuals.GetAuraDurationTextScale)
check(probeEnv.FluxRaidVisuals.AURA_DURATION_FONT_SIZE == 10 and fontSize(12) == 10,
    "duration font retains a valid base height while text scale controls fitting")
local fittedScale, measured = textScale(12, 15)
check(measured and math.abs(fittedScale - 0.399) < 0.000001
    and 20 * fittedScale < 12 and 7 * fittedScale < 15,
    "native-sized two-digit and unit labels fit without an incorrect six-pixel floor")
check(measuredLabels["59"] and measuredLabels["59m"] and measuredLabels["23h"] and measuredLabels["99d"],
    "the fit includes seconds, minutes, hours and bounded days")
local cachedReads = probeReads
check(textScale(12, 15) == fittedScale and probeReads == cachedReads and probeFrames == 1,
    "a cached width avoids repeated glyph measurements and widget allocation")
check(math.abs(textScale(24, 30) - fittedScale * 2) < 0.000001 and probeFrames == 1 and probeText.text == "",
    "larger aura icons proportionally grow text using the same empty hidden probe")
local shortScale = textScale(12, 3)
check(shortScale < fittedScale and 7 * shortScale < 3,
    "icon height is part of the cache key and bounds text in short aura cells")
probeText.GetUnboundedStringWidth, probeText.GetStringWidth = false, measurePublicLabel
check(textScale(11, 15) < fittedScale, "older string-width measurement remains supported")
unreadableProbe = true
local fallbackScale, fallbackMeasured = textScale(10, 15)
check(fallbackScale > 0 and not fallbackMeasured and textScale(opaqueProbe) == 0.1,
    "unreadable metrics use an explicitly unverified fallback without secret arithmetic")
unreadableProbe = false
visuals.ApplyRaidFrameTunables({ memberWidthScale = 1.5, frameHeightScale = 1.4, powerBarHeightScale = 2 })
check(visuals.FRAME_WIDTH == 147 and visuals.FRAME_HEIGHT == 62 and visuals.POWER_BAR_HEIGHT == 16,
    "saved scales multiply the stock default cell and power dimensions")
visuals.ApplyRaidFrameTunables({ })
visuals.ApplyRaidFrameTunables({ auraIconAlpha = 0.6 })
check(math.abs(visuals.AURA_ICON_ALPHA - 0.18) < 0.00001, "requested70percent aura transparency multiplies the saved opacity preference")
visuals.ApplyRaidFrameTunables({ })
check(visuals.AURA_ICON_ALPHA == 0.3, "default aura opacity is thirtypercent")
local f = cell()
visuals.ApplyCellChrome(f, { showPower = true })
check(not f.width and not f.height, "chrome never resizes the outer secure hit region")
check(f.healthBar.parent == f._fluxContent and f.powerBar.parent == f._fluxContent, "range-fadable content owns bars")
check(f.visualContent == f._fluxContent and f.name.parent == f._fluxTextLayer, "shared content aliases and text layer remain stable")
check(f.selectionHighlight.parent == f._fluxHighlightLayer and f._fluxHighlightLayer.parent == f, "target highlights stay outside fading content and above bars")
check(f.name.justify == "CENTER" and f.statusText.justify == "CENTER", "name and status form a centered block")
check(f.healthBar.barTexture == "Interface\\Buttons\\WHITE8X8" and #f._fluxBronzeEdges == 4, "flat native fills and independent bronze bevel exist")
check(f.powerBarUsedHeight == 8 and not f._fluxPowerDivider.shown, "power occupies the native eight-unit strip without an extra divider row")
check(f._fluxAuraLayer.level > f._fluxTextLayer.level and f._fluxAuraLayer.level > f._fluxTrimLayer.level
    and f._fluxAuraLayer.level > f._fluxHighlightLayer.level and f._fluxIndicatorLayer.level > f._fluxAuraLayer.level + 6,
    "complete aura content is above bars, names, borders and highlights while indicators keep headroom")
check(f._fluxTrimLayer.parent == f and f._fluxAuraLayer.parent == f._fluxContent,
    "border opacity is separate from fading body and aura containers")
check(f.background.points[1][4] == visuals.CELL_INSET and f._fluxCellBacking.points[1][4] == visuals.CELL_INSET, "dark backings stay inside the trim and leave exterior corners transparent")
local fittedAuras = visuals.GetAuraLayout(65, 31, {})
check(fittedAuras.width==11 and fittedAuras.height==11 and fittedAuras.overlap,
    "stock icon sizes remain exact and explicitly report overlap inside narrower synthetic bounds")
local content = f._fluxContent
visuals.ApplyCellChrome(f, { showPower = false })
check(f._fluxContent == content and not f.powerBar.shown and not f._fluxPowerDivider.shown, "power toggle reuses chrome and reclaims its space")
for _, key in ipairs({ "leaderIcon", "masterLooterIcon", "raidTargetIcon" }) do
    check(f[key].parent == f._fluxIndicatorLayer and f[key].ignoreAlpha, key .. " retains its alias on an unfaded indicator layer")
end
check(f._fluxIndicatorLayer.level > f._fluxTextLayer.level and f._fluxIndicatorLayer.level < f.centerStatusIcon.level
    and f._fluxIndicatorLayer.level < f.readyCheckIcon.level and not f._fluxIndicatorLayer.colorTexture,
    "leadership/loot/raid marks sit above text and below rez/ready without a black backdrop")
local predictionRefresh, hotRefresh = 0, 0
local previewSetups = 0
env.FluxRaidPrediction = { Setup = function(frame) if frame == f then predictionRefresh = predictionRefresh + 1 elseif frame._fluxRaidPreview then previewSetups = previewSetups + 1 end end }
env.FluxRaidHoTs = { Setup = function(frame) if frame == f then hotRefresh = hotRefresh + 1 elseif frame._fluxRaidPreview then previewSetups = previewSetups + 1 end end }
visuals.ApplyCellChrome(f, { showPower = true })
check(predictionRefresh == 1 and hotRefresh == 1, "OOC chrome changes refresh existing prediction and HoT fixed widths")
local opaque = setmetatable({}, { __concat = function() error("secret concatenated") end, __tostring = function() error("secret formatted in Lua") end })
secrets[opaque] = true
visuals.SetUnitName(f, opaque, "HEALER")
check(f.name.format == "%s" and f.name.formatValues[1] == opaque and not f.roleIcon.shown, "opaque names keep the full line without role markup")
visuals.SetUnitName(f, "Tank", opaque)
f._fluxRole = opaque
visuals.SetUnitStatus(f, "%.0f%%", opaque)
check(f.statusText.formatValues[1] == "" and f.statusText.formatValues[2] == opaque, "opaque roles cannot index the cache while percent goes directly to its native sink")
f._fluxRole = "HEALER"
visuals.SetUnitStatus(f, "%.0f%%", opaque)
check(f.statusText.format == "%s%.0f%%" and f.statusText.formatValues[1]:find(":17:17:", 1, true)
    and f.statusText.formatValues[2] == opaque, "native seventeen-unit role icon precedes the percent without formatting its secret value in Lua")
f.optionTable = { showRoleIcon = false }
visuals.SetUnitStatus(f, "%s", opaque)
check(f.statusText.formatValues[1] == "", "status formatter respects the existing role toggle")
f.optionTable = nil
check(f.name.font == env.GameFontHighlightSmall and f.name.points[1][4] == 2,
    "smaller native name font and full width leave more room for names")
check(f.name.points[1][5] - f.statusText.points[1][5] == 12, "compact name/status line spacing follows the requested two-line design")
local before = mutations
combat = true
visuals.ApplyCellChrome(f, { showPower = true })
check(mutations == before and f._fluxNeedsChromeRefresh and predictionRefresh == 1 and hotRefresh == 1, "combat chrome updates defer geometry, parenting and fixed-width refreshes")
combat = false
visuals.ApplyCellChrome(f, { showPower = true })
check(not f._fluxNeedsChromeRefresh, "out-of-combat layout clears deferred chrome")
assert(loadfile(root .. "RaidFrame/FluxRaidPreview.lua", "t", env))("_FluxUI", ns)
env.FluxRaidPreview.Show()
local first, second, third = named.FluxRaidPreviewUnit1, named.FluxRaidPreviewUnit2, named.FluxRaidPreviewUnit3
check(first._fluxAuraBuff[6].width == first._fluxPreviewAuraMetrics.width and first._fluxAuraBuff[6].height == first._fluxPreviewAuraMetrics.height
    and first._fluxAuraBuff[6].points[1][5] < 0 and first._fluxAuraBuff[3].points[1][5] == 0, "preview keeps bounded rectangular three-column two-row sizing")
check(second.points[#second.points][5] == -(visuals.FRAME_HEIGHT - 1), "preview members share one pixel without changing their hit-region size")
check(first.width == visuals.FRAME_WIDTH and first.height == visuals.FRAME_HEIGHT, "preview keeps live outer dimensions")
check(first.healthBar.barTexture == f.healthBar.barTexture and first.name.justify == f.name.justify, "preview and live share chrome without old style overrides")
check(first._fluxPreviewPrediction.incoming.shown and second._fluxPreviewPrediction.hot.shown and third._fluxPreviewPrediction.absorb.shown, "preview distinguishes incoming heal, HoT and absorb states")
check(named.FluxRaidPreviewUnit4._fluxPreviewDispel.shown, "preview includes a dispellable debuff")
check(named.FluxRaidPreviewUnit5._fluxContent.alpha == visuals.FRAME_BASE_ALPHA * visuals.RANGE_ALPHA_OUT_OF_RANGE, "preview range fade targets content only")
check(named.FluxRaidPreviewUnit6.statusText.text == "Dead" and named.FluxRaidPreviewUnit7.statusText.text == "Offline", "preview includes distinct dead and offline states")
check(named.FluxRaidPreviewUnit8._fluxPreviewCenter.shown and named.FluxRaidPreviewUnit9._fluxPreviewCenter.shown, "preview includes resurrection and summon indicators")
check(named.FluxRaidPreviewUnit10._fluxPreviewOverflow.shown, "preview includes overheal overflow")
for _,mode in ipairs({"health","healthandpercent","losthealth","none","perc"})do
 db.healthText=mode;env.FluxRaidPreview.RefreshFromOptions()
 if mode=="none"then check(not first.statusText.shown,"preview hides numeric status in hidden mode")
 elseif mode=="health"then check(type(first.statusText.text)=="number","preview values mode paints health instead of percent")
 else
  local expected=mode=="healthandpercent"and"%s%s / %.0f%%"or mode=="losthealth"and"%s-%s"or"%s%.0f%%"
  check(first.statusText.format==expected,"preview uses the live formatter for "..mode)
 end
end
check(first._fluxPreviewOverflow.width==16 and first._fluxPreviewOverflow.atlas=="RaidFrame-Shield-Overshield",
 "preview overflow uses native width and atlas")
check(first._fluxPreviewCenter.parent==first.centerStatusIcon,"preview center indicators use the shared live host/layer")
db.previewShowMTColumn,db.previewMainTankCount=true,2
env.FluxRaidPreview.RefreshFromOptions()
local mt=named.FluxRaidPreviewUnit1
local target=assert(mt._fluxPreviewTarget)
check(target._fluxRaidMini and target.height==visuals.MINI_FRAME_HEIGHT and target.shown,"MT preview includes the actual reserved target strip")
check(not target.powerBar.shown and target.powerBarUsedHeight==0 and not target._fluxAuraBuff,"target preview contains HP only, without resource bar or auras")
check(target._fluxContent.alpha==visuals.FRAME_BASE_ALPHA,"target preview uses full configured base opacity")
check(target.name.justify=="LEFT" and target.statusText.justify=="RIGHT" and target.statusText.format=="%s%.0f%%" and target.statusText.formatValues[1]=="",
 "target preview reserves separate space for name and plain percentage")
db.previewShowMTColumn=false;env.FluxRaidPreview.RefreshFromOptions()
check(not target.shown,"reusing an MT sample as a raid member retires its target strip")
local targetCell=cell();targetCell._fluxRaidMini=true;targetCell._fluxRole="TANK"
visuals.ApplyCellChrome(targetCell,{showPower=true})
check(not targetCell.powerBar.shown and targetCell.powerBarUsedHeight==0,"live mini chrome overrides an enabled resource option")
check(targetCell.name.justify=="LEFT" and targetCell.name.points[2][2]==targetCell.statusText
 and targetCell.statusText.justify=="RIGHT" and targetCell.statusText.points[1][5]==0,
 "live target name and percent occupy one centered row with separate bounds")
visuals.SetHealthStatus(targetCell,"none",80,100,80,true,false)
check(targetCell.statusText.shown and targetCell.statusText.formatValues[1]=="" and targetCell.statusText.formatValues[2]==80,
 "target percent remains visible without role markup even when main member text is hidden")
db.showHealPrediction = false
env.FluxRaidPreview.RefreshFromOptions()
check(not first._fluxPreviewPrediction.incoming.shown and first._fluxPreviewPrediction.incoming.value == 0, "pool refresh clears stale prediction values when disabled")
db.showRangeFade, db.showRoleIcon = false, false
env.FluxRaidPreview.RefreshFromOptions()
check(named.FluxRaidPreviewUnit5._fluxContent.alpha == visuals.FRAME_BASE_ALPHA * visuals.RANGE_ALPHA_IN_RANGE, "preview respects disabled range fading")
check(first.statusText.formatValues[1] == "", "preview respects disabled role icons beside the percent")
env.IsInGroup = function() return true end
env.GetNumSubgroupMembers = function() return 4 end
env.UnitClass = function() return "Mage", "MAGE" end
env.UnitHealth, env.UnitHealthMax = function() return opaque end, function() return opaque end
env.UnitPower, env.UnitPowerMax = function() return opaque end, function() return opaque end
env.UnitPowerType, env.UnitGroupRolesAssigned = function() return opaque end, function() return opaque end
env.UnitName = function() return opaque end
env.FluxRaidCompat = { GetHealthPercent = function() return opaque end, GetOutOfRange = function() return opaque end }
env.FluxRaidPreview.RefreshFromOptions()
check(first.healthBar.value == opaque and first.healthBar.maximum == opaque, "real-unit preview sends opaque raw health directly to native bars")
check(first.powerBar.value == opaque and first.powerBar.maximum == opaque, "real-unit preview sends opaque power directly to native bars")
check(first.statusText.formatValues[2] == opaque and first.name.formatValues[1] == opaque, "real-unit preview formats opaque percentage and name only in native sinks")
check(previewSetups == 0, "synthetic preview never constructs live prediction or HoT services")
env.FluxRaidPreview.Hide()
check(not named.FluxRaidPreviewContainer.shown, "session-only preview hides completely")
-- Construct actual readable and native aura owners with the existing detailed
-- ownership fixture; do not reproduce aura setup or sink registration here.
local function readSource(path)
    local file=assert(io.open(root..path,"rb"));local source=file:read("*a"):gsub("\r\n","\n");file:close();return source
end
local fixtureSource=readSource("tests/raid_healer_auras.lua")
local endFixture=assert(fixtureSource:find('for _,client in ipairs({"retail","forever"})do',1,true))
local nativeFixture=assert(load(fixtureSource:sub(1,endFixture-1).."\nreturn Fixture","@aura-layer-fixture","t",_G))()
for _,native in ipairs({true,false})do
    local layerEnv,auraModule,unit,objects=nativeFixture(native)
    local api=getmetatable(unit).__index
    local existingLevel=api.GetFrameLevel
    -- Frame descendants inherit one level; textures/fontstrings render at the
    -- containing frame's level. Explicit production SetFrameLevel wins.
    function api:GetFrameLevel()
        existingLevel(self) -- preserve the fixture's forbidden-descendant guard
        if self.level~=nil then return self.level end
        if not self.parent then return 0 end
        return self.parent:GetFrameLevel()+((self.kind=="Texture"or self.kind=="FontString")and 0 or 1)
    end
    api.SetParent=api.SetParent or function(self,parent)
        existingLevel(self) -- retain the forbidden-descendant guard in old fixtures
        self.parent=parent
    end
    function api:SetStatusBarTexture(value)self.barTexture=value end
    function api:SetAtlas(value)self.atlas=value end
    function api:SetIgnoreParentAlpha(value)self.ignoreParentAlpha=value end
    function api:SetJustifyH(value)self.justify=value end
    function api:SetFontObject(value)self.fontObject=value end
    function api:CreateFontString()return layerEnv.CreateFrame("FontString",nil,self)end
    local create=layerEnv.CreateFrame
    layerEnv.CreateFrame=function(kind,name,parent,template)
        local frame=create(kind,name,parent,template)
        if template=="FluxRaidAuraIconTemplate"and not frame.AuraTextLayer then
            frame.AuraTextLayer=create("Frame",nil,frame);frame.AuraTextLayer:SetAllPoints(frame)
        end
        return frame
    end
    for _,key in ipairs({"name","statusText","roleIcon","leaderIcon","masterLooterIcon","raidTargetIcon","centerStatusIcon","readyCheckIcon"})do
        unit[key]=layerEnv.CreateFrame((key=="name"or key=="statusText")and"FontString"or(key=="centerStatusIcon"or key=="readyCheckIcon")and"Frame"or"Texture",nil,unit)
    end
    assert(loadfile(visualsSource,"t",layerEnv))("_FluxUI",{Flux={}})
    layerEnv.FluxRaidVisuals.ApplyRaidFrameTunables({})
    layerEnv.FluxRaidVisuals.ApplyCellChrome(unit,{showPower=true})
    check(auraModule.Setup(unit),"actual native/readable aura construction succeeds with raised presentation layers")
    local icons=0
    for _,button in ipairs(objects)do
        if button.template=="FluxRaidAuraIconTemplate"then
            icons=icons+1
            local buttonLevel=button:GetFrameLevel()
            check(button.Icon:GetParent():GetFrameLevel()>unit._fluxHighlightLayer:GetFrameLevel()
                and button.Cooldown:GetFrameLevel()>unit._fluxTrimLayer:GetFrameLevel(),
                "actual icon and cooldown descendants paint above highlight/border layers")
            check(button.Count:GetParent():GetFrameLevel()>button.Cooldown:GetFrameLevel()
                and button.Duration:GetParent():GetFrameLevel()>button.Cooldown:GetFrameLevel(),
                "actual count/duration host paints above the swipe rather than underneath it")
            check(unit.leaderIcon:GetParent():GetFrameLevel()>button.Count:GetParent():GetFrameLevel()
                and unit.masterLooterIcon:GetParent():GetFrameLevel()>button.Duration:GetParent():GetFrameLevel()
                and unit.raidTargetIcon:GetParent():GetFrameLevel()>buttonLevel
                and unit.centerStatusIcon:GetFrameLevel()>button.Cooldown:GetFrameLevel()
                and unit.readyCheckIcon:GetFrameLevel()>button.Cooldown:GetFrameLevel(),
                "actual leadership/loot/mark/rez/ready layers remain above every aura sink")
        end
    end
    check(icons>0,"the layer regression inspects actual constructed icon/cooldown/count/duration objects")
    check(unit._fluxAuraRows.top.alpha==.3 and unit._fluxAuraRows.bottom.alpha==.3,
        "raising the full aura subtree preserves configured transparency")
    layerEnv.restricted=true
    check(pcall(layerEnv.FluxRaidVisuals.ApplyCellChrome,unit,{showPower=true}),
        "later chrome refresh does not inspect or mutate native forbidden descendants")
end
nativeAsset = true
local nativeEnv = setmetatable({}, { __index = env })
nativeEnv._G = nativeEnv
nativeEnv.CreateColor = function(...) return { ... } end
assert(loadfile(visualsSource, "t", nativeEnv))("_FluxUI", ns)
nativeEnv.FluxRaidVisuals.ApplyRaidFrameTunables({})
local nativeFrame = cell()
nativeEnv.FluxRaidVisuals.ApplyCellChrome(nativeFrame, { showPower = true })
local bronze = nativeFrame._fluxNativeBronze
check(bronze.top.texture == 8036209 and bronze.top.shown and not nativeFrame._fluxBronzeEdges[1].shown,
    "available Blizzard bronze artwork replaces the plain fallback")
check(bronze.power.height == 1 and bronze.power.shown and not nativeFrame._fluxPowerDivider.shown,
    "power divider uses the matching native gold strip")
check(bronze.top.texcoord[3] == 24.5/1024 and bronze.top.texcoord[4] == 27.5/1024
    and bronze.right.texcoord[1] == 1589.5/2048 and bronze.right.texcoord[2] == 1592.5/2048,
    "native UVs select gold texel centers and exclude baked-black atlas padding")
for _, piece in ipairs(bronze.parts) do
    check(piece.blendMode == "BLEND" and piece.vertex[1] == 0.85 and piece.alpha == 1,
        "native gold preserves its original bevel with ordinary blend and85percent brightness")
end
local function anchorFraction(point)
    return point:find("LEFT") and 0 or point:find("RIGHT") and 1 or 0.5,
        point:find("TOP") and 1 or point:find("BOTTOM") and 0 or 0.5
end
local function rect(object)
    if object._testRect then return table.unpack(object._testRect) end
    if object == nativeFrame then return 0, 0, 72, 43 end
    if object.allPoints then return rect(object.allPoints) end
    local anchors = {}
    for _, point in ipairs(object.points) do
        local x,y,w,h = rect(point[2]); local rx,ry = anchorFraction(point[3]); local ownX,ownY = anchorFraction(point[1])
        anchors[#anchors+1] = { x=x+rx*w+(point[4] or 0), y=y+ry*h+(point[5] or 0), ownX=ownX, ownY=ownY }
    end
    local width,height = object.width,object.height
    for _,one in ipairs(anchors) do for _,two in ipairs(anchors) do
        if not width and one.ownX~=two.ownX then width=(two.x-one.x)/(two.ownX-one.ownX) end
        if not height and one.ownY~=two.ownY then height=(two.y-one.y)/(two.ownY-one.ownY) end
    end end
    assert(width and height and anchors[1], "unresolved geometry")
    return anchors[1].x-anchors[1].ownX*width,anchors[1].y-anchors[1].ownY*height,width,height
end
local function gridCell(x,y,edges)
    local result=cell(); result._fluxRaidPreview=true; result._testRect={x,y,72,43}
    nativeEnv.FluxRaidVisuals.ApplyCellChrome(result,{showPower=true})
    nativeEnv.FluxRaidVisuals.SetJoinedEdges(result,edges)
    return result
end
local upperLeft=gridCell(0,0,{exteriorTop=true,exteriorLeft=true,bottom=false,right=false})
local upperRight=gridCell(72,0,{exteriorTop=true,exteriorLeft=false,bottom=false,right=true})
local lowerLeft=gridCell(0,-42,{exteriorTop=false,exteriorLeft=true,bottom=true,right=false})
local lowerRight=gridCell(72,-42,{exteriorTop=false,exteriorLeft=false,bottom=true,right=true})
for _,entry in ipairs({{upperLeft,"tl"},{upperRight,"tr"},{lowerLeft,"bl"},{lowerRight,"br"}}) do
    for corner,patches in pairs(entry[1]._fluxNativeBronze.corners) do
        for _,patch in ipairs(patches) do check(patch.shown==(corner==entry[2]),"only the actual exterior grid corner draws its native arc") end
    end
end
check(not upperLeft._fluxNativeBronze.bottom.shown and lowerLeft._fluxNativeBronze.sharedTop.shown
    and not lowerLeft._fluxNativeBronze.top.shown,
    "lower cell exclusively paints the shared horizontal seam with native divider art")
check(not upperLeft._fluxNativeBronze.right.shown and upperRight._fluxNativeBronze.left.shown,
    "right cell exclusively paints the shared vertical native gold seam")
check(lowerLeft._fluxNativeBronze.sharedTopLeft.shown and lowerLeft._fluxNativeBronze.sharedTopRight.shown
    and not lowerLeft._fluxNativeBronze.corners.tl[1].shown,
    "internal horizontal joins remain straight without repeated rounded caps")
local side=upperRight._fluxNativeBronze
local _,aY,aW,aH=rect(side.leftTop); local _,bY,bW,bH=rect(side.left); local _,cY,cW,cH=rect(side.leftBottom)
check(aW==2 and bW==2 and cW==2 and aY==bY+bH and bY==cY+cH and aH+bH+cH==42,
    "native vertical band segments resolve to a continuous two-unit shared edge")
local seam=lowerLeft._fluxNativeBronze
local _,_,startWidth=rect(seam.sharedTopLeft); local _,_,middleWidth=rect(seam.sharedTop); local _,_,endWidth=rect(seam.sharedTopRight)
check(startWidth+middleWidth+endWidth==72,"native shared horizontal segments cover the full cell width without gaps")
local compact=cell(); compact._fluxRaidPreview=true; compact._testRect={0,0,72,10}
nativeEnv.FluxRaidVisuals.ApplyCellChrome(compact,{height=10,showPower=false})
local _,_,compactWidth,compactHeight=rect(compact._fluxNativeBronze.left)
check(compact._fluxNativeBronze.compact and compactWidth==2 and compactHeight==9,
    "smallest target minis retain positive native gold side geometry")
check(not compact._fluxNativeBronze.corners.tl[1].shown and compact._fluxNativeBronze.topLeft.shown,
    "tiny minis use straight native bands when original corner arcs cannot fit")
for _,piece in ipairs(upperLeft._fluxNativeBronze.parts) do
    local _,_,width,height=rect(piece)
    check(width>0 and height>0,"every prepared native edge/corner patch has positive resolved dimensions")
end
local _,_,bodyWidth=rect(upperLeft.healthBar)
local powerX,powerY,powerWidth,powerHeight=rect(upperLeft.powerBar)
check(bodyWidth==70 and powerX==1 and powerY==1 and powerWidth==70 and powerHeight==8,
    "native trim preserves connected fills and full native eight-unit resource geometry")
upperLeft._fluxContent:SetAlpha(.44)
visuals.ApplyRaidFrameTunables({ auraTransparency=100})
check(upperLeft._fluxTrimLayer.parent==upperLeft and upperLeft._fluxNativeBronze.top.alpha==1 and visuals.AURA_ICON_ALPHA==0,
    "aura transparency and range fade cannot erase the textured grid border")
local beforeJoinedMutation,beforePoints=mutations,#upperLeft.points
combat=true
nativeEnv.FluxRaidVisuals.SetJoinedEdges(upperLeft,{exteriorTop=false,exteriorLeft=false,bottom=true,right=true})
check(mutations==beforeJoinedMutation and #upperLeft.points==beforePoints and upperLeft._fluxNativeBronze.bottom.shown
    and upperLeft._fluxNativeBronze.right.shown and upperLeft._fluxNativeBronze.sharedTop.shown,
    "combat topology updates only owned texture visibility, preserving all geometry")
combat=false
nativeEnv.FluxRaidVisuals.SetJoinedEdges(upperLeft,{exteriorTop=true,exteriorLeft=true,bottom=false,right=false})
check(not named.FluxRaidPreviewUnit1._fluxJoinedLines.bottom.shown and named.FluxRaidPreviewUnit5._fluxJoinedLines.bottom.shown,
    "fallback preview retains one owner per horizontal seam")
check(not named.FluxRaidPreviewUnit6._fluxJoinedLines.right.shown and named.FluxRaidPreviewUnit1._fluxJoinedLines.right.shown,
    "fallback preview neighboring reverse columns share one border")
check(named.FluxRaidPreviewUnit1._fluxJoinedEdges.exteriorTop and not named.FluxRaidPreviewUnit1._fluxJoinedEdges.exteriorLeft
    and named.FluxRaidPreviewUnit6._fluxJoinedEdges.exteriorLeft,
    "preview supplies real exterior top/left topology for native corner selection")
for _,item in ipairs({{0,1},{70,.3},{100,0}}) do
    visuals.ApplyRaidFrameTunables({ auraTransparency=item[1]})
    check(math.abs(visuals.AURA_ICON_ALPHA-item[2])<.00001,"transparency control endpoints remain preserved")
end
visuals.ApplyRaidFrameTunables({ })
local gradient=nativeFrame.healthBar._fluxSheen.gradient
check(gradient[2][4]==0 and gradient[3][4]==.04,"health sheen still has no dark overlay")
-- Optional external static model: export production-created widget geometry and
-- native UVs, rather than reimplementing its layout in the rasterizer.
local modelPath=os.getenv("FLUX_RAID_NATIVE_BORDER_MODEL")
if modelPath then
    local rows={}
    for _,frame in ipairs({upperLeft,upperRight,lowerLeft,lowerRight}) do
        for _,texture in ipairs(frame._fluxNativeBronze.parts) do
            if texture.shown then
                local x,y,w,h=rect(texture); local uv=texture.texcoord
                rows[#rows+1]=string.format('{"x":%.4f,"y":%.4f,"w":%.4f,"h":%.4f,"uv":[%.12f,%.12f,%.12f,%.12f]}',x,y,w,h,uv[1],uv[2],uv[3],uv[4])
            end
        end
    end
    local file=assert(io.open(modelPath,"wb")); file:write('{"scope":"Static geometry/native-art model, not a WoW capture.","parts":[',table.concat(rows,","),']}');file:close()
end
print("raid healer visuals: "..checks.." checks passed (desktop only)")
