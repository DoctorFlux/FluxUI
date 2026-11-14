-- Actual scoped raid controls, size/default resets and synthetic preview widgets.
-- Native restricted classification/rendering is a separate acceptance check.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function read(path)
    local file = assert(io.open(root .. path, "rb")); local source = file:read("*a"):gsub("\r\n", "\n"); file:close(); return source
end
local function part(source, first, last)
    local a = assert(source:find(first, 1, true)); local b = assert(source:find(last, a + #first, true)); return source:sub(a, b - 1)
end
local checks = 0
local function check(value, label) assert(value, label); checks = checks + 1 end
local function near(a, b) return math.abs(a - b) < 0.000001 end
local e = setmetatable({}, { __index = _G }); e._G = e
local ns = { Flux = {} }
local live, preview = 0, 0
local sizeKeys = { "memberWidthScale", "frameHeightScale", "powerBarHeightScale", "auraIconScale", "raidManagerScale", "auraWidthScale", "auraDurationFontScale" }
local preset={memberWidthScale=.70,frameHeightScale=.95,powerBarHeightScale=1,auraIconScale=1.82,raidManagerScale=1.20,auraWidthScale=.50,auraDurationFontScale=1.72}
local account = { auraIconAlpha = 0.6, memberWidthScale = 1.1, nested = { keep = true } }
local character = { auraIconAlpha = 0.4, marker = "character" }
e.FluxOptions = { db = { profile = { raidFrames = account }, char = { raidFrames = character, raidFramesSettingsScope = "account" } } }
e.DeepCopyValue = function(value)
    if type(value) ~= "table" then return value end
    local copy = {}; for key, child in pairs(value) do copy[key] = e.DeepCopyValue(child) end; return copy
end
assert(loadfile(root .. "RaidFrame/FluxRaidVisuals.lua", "t", e))("_FluxUI", ns)
assert(loadfile(root .. "AddonOptions/FluxOptionsDefaults.lua", "t", e))("_FluxUI", ns)
e.FluxRaid_ApplyOptionsFromDB = function()
    live = live + 1; e.FluxRaidVisuals.ApplyRaidFrameTunables(e.FluxOptions:GetRaidFrameDB())
end
e.FluxRaidPreview = { RefreshFromOptions = function() preview = preview + 1 end }
local scoped = part(read("AddonOptions/FluxOptions.lua"), "local function CopyRaidFramesFields", "function FluxOptions:RefreshRaidFramesAfterProfileChange()")
assert(load(scoped, "@actual-raid-scope-and-reset", "t", e))()
assert(loadfile(os.getenv("FLUX_RAID_OPTIONS_SOURCE") or (root .. "AddonOptions/FluxOptionsRaidFrame.lua"), "t", e))("_FluxUI", ns)
local tab = ns.FluxOptionsBuildPartyRaidTab()
local roster=tab.args.previewGroup.args.rosterSize
check(roster.values["5"]==nil and roster.sorting[1]=="10" and roster.values["40"]=="40","raid preview choices start at ten")
local savedRosterScope=e.FluxOptions.db.char.raidFramesSettingsScope
for _,scope in ipairs({"account","character"})do
    e.FluxOptions.db.char.raidFramesSettingsScope=scope
    local db=e.FluxOptions:GetRaidFrameDB();local saved=db.previewRosterSize;db.previewRosterSize=5
    check(roster.get()=="10"and db.previewRosterSize==5,"reading minimum does not rewrite saved party preview size")
    for _,case in ipairs({{5,10},{7,10},{17,15},{99,40},{"invalid",40}})do
        roster.set(nil,case[1]);check(db.previewRosterSize==case[2],"raid preview setter clamps in selected scope")
    end
    db.previewRosterSize=saved
end
e.FluxOptions.db.char.raidFramesSettingsScope=savedRosterScope
check(tab.args.useBlizzardDefaultSizes == nil, "native size baselines require no mode toggle")
for _, key in ipairs(sizeKeys) do
    check(not tab.args[key].disabled and tab.args[key].get() == (key == "memberWidthScale" and 1.1 or 1),
        "all size controls stay enabled with a one-point-zero fallback: " .. key)
end
for _, defaults in ipairs({ e.FluxOptionsDefaults.profile.raidFrames, e.FluxOptionsDefaults.char.raidFrames }) do
    check(defaults.useBlizzardDefaultSizes == nil, "reset defaults contain no sizing mode flag")
    for _, key in ipairs(sizeKeys) do check(defaults[key] == preset[key], "both default scopes match the screenshot: " .. key) end
    check(defaults.auraTimersUnderMinute==true,"both scopes default to under-one-minute aura timers")
    check(defaults.maxBuffs == 6 and defaults.maxDebuffs == 6 and defaults.previewBuffCount == 3 and defaults.previewDebuffCount == 5,
        "live six-icon capacities remain separate from demo defaults")
end
local existing = { memberWidthScale = 1.1, frameHeightScale = 1.2, powerBarHeightScale = 1.25, auraIconScale = 1.4, raidManagerScale = 0.9 }
for key, value in pairs(existing) do account[key] = value end
account.useBlizzardDefaultSizes = false
e.FluxOptions:RefreshRaidFrameScopedModules()
check(e.FluxRaidVisuals.FRAME_WIDTH == 108 and e.FluxRaidVisuals.FRAME_HEIGHT == 53 and e.FluxRaidVisuals.POWER_BAR_HEIGHT == 10,
    "existing requests apply to native stock dimensions without the old height modifiers")
for key, value in pairs(existing) do tab.args[key].get(); check(account[key] == value, "opening controls never rewrites saved " .. key) end
check(account.useBlizzardDefaultSizes == false, "unused historical sizing data is not deleted automatically")
account.frameHeightScale, account.powerBarHeightScale, account.auraIconScale, account.raidManagerScale = nil, nil, nil, nil

local opacity = tab.args.auraIconAlpha
check(opacity.type == "range" and opacity.min == 0 and opacity.max == 100 and opacity.step == 1 and near(opacity.get(), 82),
    "actual transparency control preserves legacy opacity interpretation")
for _, item in ipairs({ { 0, 1 }, { 70, 0.3 }, { 100, 0 } }) do
    local beforeLive, beforePreview = live, preview
    opacity.set(nil, item[1])
    check(account.auraTransparency == item[1] and near(opacity.get(), item[1]) and near(e.FluxRaidVisuals.AURA_ICON_ALPHA, item[2]),
        "transparency setting reaches live tunables at " .. item[1])
    check(live == beforeLive + 1 and preview == beforePreview + 1 and account.auraIconAlpha == 0.6 and account.nested.keep,
        "existing callbacks preserve unrelated saved data")
end
opacity.set(nil, -1); check(account.auraTransparency == 0, "transparency clamps below zero")
opacity.set(nil, 101); check(account.auraTransparency == 100, "transparency clamps above one hundred")
opacity.set(nil, "invalid"); check(account.auraTransparency == 70, "invalid transparency uses its display default")
local scopeText = part(read("AddonOptions/FluxOptionsUnitFrames.lua"), "    general.raidSettingsScope = {", "    general.useFluxRaidFrames = {")
local scope = assert(load("local general={}\n" .. scopeText .. "\nreturn general.raidSettingsScope", "@actual-raid-scope-selector", "t", e))()
scope.set(nil, "character")
tab.args.frameHeightScale.set(nil, 1.3); opacity.set(nil, 25)
check(e.FluxOptions:GetRaidFrameDB() == character and character.frameHeightScale == 1.3 and account.frameHeightScale == nil
    and character.auraTransparency == 25 and account.auraTransparency == 70,
    "size and opacity setters target only the selected character scope")
scope.set(nil, "account")
check(account.frameHeightScale == 1.3 and account.auraTransparency == 25, "scope switching retains established copy behavior")
account.frameHeightScale = nil; opacity.set(nil, 70)

local buffLimit, debuffLimit, iconScale = tab.args.maxBuffs, tab.args.maxDebuffs, tab.args.auraIconScale
for _, control in ipairs({ buffLimit, debuffLimit }) do
    check(control.type == "range" and control.min == 1 and control.max == 6 and control.step == 1 and control.get() == 6,
        "independent live capacities accept every integer from one to six")
end
for limit = 1, 6 do
    local other, beforeLive, beforePreview = account.maxDebuffs, live, preview
    buffLimit.set(nil, limit)
    check(account.maxBuffs == limit and account.maxDebuffs == other and live == beforeLive + 1 and preview == beforePreview + 1,
        "buff count changes independently through the scoped callback")
    debuffLimit.set(nil, 7 - limit)
    check(account.maxDebuffs == 7 - limit and account.maxBuffs == limit, "debuff count changes independently")
end
for _, control in ipairs({ buffLimit, debuffLimit }) do
    control.set(nil, 0); check(control.get() == 1, "live aura limits clamp below one")
    control.set(nil, 9); check(control.get() == 6, "live aura limits clamp above six")
    control.set(nil, 4.8); check(control.get() == 4, "live aura limits store integers")
    control.set(nil, "invalid"); check(control.get() == 6, "invalid limits retain the six-icon default")
end
local beforeDemoLive, beforeDemoPreview = live, preview
tab.args.previewGroup.args.buffCount.set(nil, 4); tab.args.previewGroup.args.debuffCount.set(nil, 5)
check(live == beforeDemoLive and preview == beforeDemoPreview + 2 and account.maxBuffs == 6 and account.maxDebuffs == 6,
    "demo count controls remain preview-only")
check(iconScale.min == 0.5 and type(iconScale.max) == "number" and iconScale.step == 0.01 and not iconScale.disabled,
    "the responsive native-relative aura slider stays enabled and Ace-compatible")
check(iconScale.desc():find("1.00 uses Blizzard", 1, true) and iconScale.desc():find("Current icons:", 1, true),
    "the aura control identifies the native baseline and current fitted size")
account.auraIconScale = 2.5
check(iconScale.get() == iconScale.max and account.auraIconScale == 2.5, "displaying a capped request never changes saved data")
iconScale.set(nil, 9); check(account.auraIconScale == iconScale.max, "user selections clamp to the responsive maximum")
local originalWidth, originalHeight, originalPower = account.memberWidthScale, account.frameHeightScale, account.powerBarHeightScale
account.memberWidthScale, account.frameHeightScale, account.powerBarHeightScale = 0.2, 0.8, 2.5; iconScale.get()
check(iconScale.max == 2.5 and iconScale.desc():find("extend beyond", 1, true),
    "tiny saved frames retain a valid range and explicitly report native-layout overlap")
account.memberWidthScale, account.frameHeightScale, account.powerBarHeightScale = originalWidth, originalHeight, originalPower
iconScale.get(); local sixMaximum = iconScale.max
account.maxBuffs, account.maxDebuffs = 1, 1; iconScale.get()
check(iconScale.max == sixMaximum and sixMaximum == 2.5, "counts cannot cap the selectable aura scale")
for _, key in ipairs(sizeKeys) do account[key] = 1 end
account.maxBuffs, account.maxDebuffs = 6, 6; e.FluxOptions:RefreshRaidFrameScopedModules()

-- Production preview helpers with ordinary public widget doubles.
local W = {}
local function widget(parent, kind) return setmetatable({ parent = parent, kind = kind, points = {}, level = parent and parent.level + 1 or 1 }, { __index = W }) end
function W:SetAllPoints(v) self.allPoints = v end
function W:SetParent(v) self.parent = v end
function W:SetFrameLevel(v) self.level = v end
function W:GetFrameLevel() return self.level end
function W:SetSize(w, h) self.width, self.height = w, h end
function W:GetWidth() return self.width or 98 end
function W:GetHeight() return self.height or 34 end
function W:SetWidth(v) self.width = v end
function W:SetPoint(...) self.points[#self.points + 1] = { ... } end
function W:ClearAllPoints() self.points = {} end
function W:CreateTexture() return widget(self, "Texture") end
function W:CreateFontString() return widget(self, "FontString") end
function W:SetTexCoord(...) self.texcoord = { ... } end
function W:SetTexture(v) self.texture = v end
function W:SetColorTexture(...) self.colorTexture = {...} end
function W:SetAlpha(v) self.alpha = v end
function W:SetText(v) self.text = v end
function W:SetFont(...) self.font = { ... } end
function W:SetFontObject(v) self.fontObject = v; self.font = { v:GetFont() } end
function W:SetTextScale(v) self.textScale = v end
function W:SetWordWrap(v) self.wordWrap = v end
function W:GetUnboundedStringWidth() return (#self.text == 2 and 15.2 or 20) * self.font[2] / 7 * (self.textScale or 1) end
function W:GetStringHeight() return self.font[2] * (self.textScale or 1) end
function W:EnableMouse(v) self.mouse = v end
function W:SetClipsChildren(v) self.clipsChildren = v end
function W:SetTextColor(...) self.textColor = {...} end
function W:SetShadowColor(...) self.shadowColor = {...} end
function W:SetShadowOffset(...) self.shadowOffset = {...} end
function W:SetDrawSwipe(v) self.swipe = v end
function W:SetSwipeTexture(...) self.swipeTexture = { ... } end
function W:SetSwipeColor(...) self.swipeColor = { ... } end
function W:SetDrawEdge(v) self.drawEdge = v end
function W:SetDrawBling(v) self.bling = v end
function W:SetReverse(v) self.reverse = v end
function W:SetCooldown(start, duration) self.start, self.duration = start, duration end
function W:SetHideCountdownNumbers(v) self.hideNumbers = v end
function W:GetCountdownFontString() self.countdownText = self.countdownText or widget(self, "FontString"); return self.countdownText end
function W:Show() self.shown = true end
function W:Hide() self.shown = false end
e.CreateFrame = function(kind, _, parent) return widget(parent, kind) end
e.GetTime = function() return 100 end
e.GetSpellTexture = function(id) return id end
e.NumberFontNormal = { GetFont = function() return "Fonts\\ARIALN.TTF", 14, "" end }
e.GameFontNormalSmall = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
e.issecretvalue = function() return false end
e.FluxRaid_GetCVarBool = function(_, fallback) return fallback end
account.previewBuffCount, account.previewDebuffCount = 6, 6
account.displayBuffs, account.displayDebuffs = true, true
local source = read(os.getenv("FLUX_RAID_PREVIEW_SOURCE") or "RaidFrame/FluxRaidPreview.lua")
local prefix = "local max,min,floor=math.max,math.min,math.floor\nlocal PREVIEW_AURA_SLOTS=6\nlocal IsSecret=issecretvalue\n"
local helpers = assert(load(prefix .. part(source, "local DEMO_DEBUFFS =", "local function GetClassColor")
    .. part(source, "local function EnsurePreviewAuraIcons", "local function ApplyPreviewAlpha")
    .. "\nreturn {Apply=ApplyDemoAuras,Layout=LayoutPreviewAuraIcons}", "@actual-preview-aura-helpers", "t", e))()
local cell = widget()
cell.healthBar, cell._fluxAuraLayer, cell._fluxTextLayer = widget(cell), widget(cell), widget(cell)
cell.healthBar.height, cell.powerBarUsedHeight, cell._fluxTextLayer.level = 34, 8, 13
local function shownCount(list) local n = 0; for _, b in ipairs(list) do if b.shown then n = n + 1 end end; return n end
for _,scale in ipairs({.5,1,1.5,2.5})do for _,x in ipairs({.5,1,1.8})do for _,font in ipairs({.5,1,1.7})do
 account.auraIconScale,account.auraWidthScale,account.auraDurationFontScale=scale,x,font
 helpers.Apply(cell,1)
 local b=cell._fluxAuraBuff[1]
 local native=widget()
 e.FluxRaidVisuals.StyleAuraDuration(native,11*x,11,1,font)
 check(near(b.duration.textScale,native.textScale*scale),"preview duration projects the exact native canonical font at every overall/X/font scale")
 check(near(b.duration.width,native.width*scale),"preview and native duration clipping widths scale identically")
 local g=e.FluxRaidVisuals.GetFrameAuraLayout(cell,account)
 check(cell._fluxPreviewAuraRows.buffs.clipsChildren and near(cell._fluxPreviewAuraRows.buffs.width,g.buffs.blockWidth)
  and near(cell._fluxPreviewAuraRows.debuffs.height,g.debuffs.blockHeight),"preview clips both blocks with the same owned health geometry as live")
end end end
account.auraIconScale,account.auraWidthScale,account.auraDurationFontScale=1,1,1
helpers.Apply(cell, 1)
check(e.FluxRaidVisuals.FRAME_WIDTH == 98 and e.FluxRaidVisuals.FRAME_HEIGHT == 44 and e.FluxRaidVisuals.POWER_BAR_HEIGHT == 8,
    "all five scales at one produce stock outer and resource dimensions")
check(shownCount(cell._fluxAuraBuff) == 6 and shownCount(cell._fluxAuraDebuff) == 6, "stock sizing retains both selected six-icon blocks")
for i, b in ipairs(cell._fluxAuraBuff) do
    local p = b.points[1]
    check(b.width == 11 and b.height == 11 and p[4] == -math.floor((i - 1) / 2) * 11 and p[5] == -((i - 1) % 2) * 11,
        "normal squares and three-by-two positions match source default sizing")
    check(b.clock.swipe and b.clock.reverse and b.clock.allPoints == b and b.clock.swipeColor[4] == 0.75 and b.clock.duration > 0,
        "full-icon countdown swipes retain the accepted overlay behavior")
    check(b.duration.font[2] == 10 and b.duration.font[3] == "" and b.count.fontObject == e.NumberFontNormal
        and b.count.font[2] == 14 and b.count.points[1][1] == "BOTTOMRIGHT" and near(b.alpha, 0.3),
        "native font objects coexist with selected transparency")
    check(b.duration.parent == b.textLayer and b.textLayer.level > b.clock.level
        and 20 * 10 / 7 * b.duration.textScale < b.width and b.duration:GetStringHeight() < b.height,
        "remaining time fits the actual square and renders above its swipe")
end
check(cell._fluxAuraDebuff[1].width == 11 and cell._fluxAuraDebuff[6].width == 11 and cell._fluxAuraDebuff[6].height == 11
    and cell._fluxAuraDebuff[2].points[1][4] == 0 and cell._fluxAuraDebuff[4].points[1][5] == -11,
    "normal and large-role examples retain native sizes inside reserved slots")
buffLimit.set(nil, 4); debuffLimit.set(nil, 5); tab.args.displayOnlyDispellableDebuffs.set(nil, true); helpers.Apply(cell, 1)
check(shownCount(cell._fluxAuraBuff) == 4 and shownCount(cell._fluxAuraDebuff) == 5, "exact four/five capacities work in strict preview mode")
for i = 1, 5 do check(cell._fluxAuraDebuff[i].icon.texture ~= 1079 and cell._fluxAuraDebuff[i].width == 11,
    "strict examples exclude bleed and unclassified large-role effects") end
account.previewBuffCount, account.previewDebuffCount = 2, 3; helpers.Apply(cell, 1)
check(shownCount(cell._fluxAuraBuff) == 2 and shownCount(cell._fluxAuraDebuff) == 3, "demo counts do not change live capacities")
account.previewBuffCount, account.previewDebuffCount = 6, 6
account.displayBuffs = false; helpers.Apply(cell, 1)
check(shownCount(cell._fluxAuraBuff) == 0 and shownCount(cell._fluxAuraDebuff) == 5, "live buff visibility independently controls preview")
account.displayBuffs, account.displayDebuffs = true, false; helpers.Apply(cell, 1)
check(shownCount(cell._fluxAuraBuff) == 4 and shownCount(cell._fluxAuraDebuff) == 0, "live debuff visibility independently controls preview")
account.displayDebuffs, account.displayOnlyDispellableDebuffs = true, false
buffLimit.set(nil, 6); debuffLimit.set(nil, 6); iconScale.set(nil, 0.5); helpers.Apply(cell, 1)
check(near(cell._fluxAuraBuff[1].width, 5.5) and near(cell._fluxAuraBuff[1].height, 5.5) and near(cell._fluxAuraBuff[1].count.textScale, 0.5),
    "half-scale requests resize squares and stack text together")
buffLimit.set(nil, 1); debuffLimit.set(nil, 1); iconScale.set(nil, 1.5); helpers.Apply(cell, 1)
local large = cell._fluxPreviewAuraMetrics
check(near(cell._fluxAuraBuff[1].width, 16.5) and near(cell._fluxAuraBuff[1].height, 16.5)
    and large.buffs.blockHeight <= 34 and large.debuffs.blockHeight <= 34 and large.buffs.blockWidth + large.debuffs.blockWidth <= 96,
    "larger requested squares stay inside the member frame")
buffLimit.set(nil, 6); debuffLimit.set(nil, 6); iconScale.set(nil, 1)
opacity.set(nil, 100); helpers.Apply(cell, 1)
check(cell._fluxAuraBuff[6].alpha == 0 and cell._fluxAuraDebuff[6].alpha == 0, "full transparency includes timers and counts")

-- Size-only reset uses the existing active scope and preserves every other key.
local sizeReset = assert(tab.args.resetSizes)
for _, target in ipairs({ "account", "character" }) do
    scope.set(nil, target)
    local db = e.FluxOptions:GetRaidFrameDB()
    for _, key in ipairs(sizeKeys) do db[key] = 1.3 end
    db.maxBuffs, db.maxDebuffs, db.displayOnlyDispellableDebuffs, db.auraTransparency = 4, 5, true, 37
    local nested = { keep = target }; db.preserved = nested
    local beforeLive, beforePreview = live, preview
    sizeReset.func()
    for _, key in ipairs(sizeKeys) do check(db[key] == preset[key], "size-only reset restores the screenshot preset " .. key) end
    check(db.auraTimersUnderMinute==true,"size reset restores the screenshot timer toggle")
    check(db.maxBuffs == 4 and db.maxDebuffs == 5 and db.displayOnlyDispellableDebuffs and db.auraTransparency == 37 and db.preserved == nested,
        "size-only reset preserves filters, counts, opacity and unrelated data in " .. target)
    check(live == beforeLive + 1 and preview == beforePreview + 1, "size-only reset refreshes existing live and preview owners")
end
-- Complete raid reset and size-only reset agree on the preset.
for _, target in ipairs({ "account", "character" }) do
    scope.set(nil, target)
    local db = e.FluxOptions:GetRaidFrameDB()
    for _, key in ipairs(sizeKeys) do db[key] = 1.3 end
    local untouched = target == "account" and character or account
    untouched.auraIconScale = 0.7
    e.FluxOptions:ResetRaidFramesToDefaults()
    check(e.FluxOptions:GetRaidFrameDB() == db and untouched.auraIconScale == 0.7, "full reset preserves target-table identity and the unselected scope")
    for _, key in ipairs(sizeKeys) do check(db[key] == preset[key], "full raid reset restores the screenshot preset " .. key) end
    check(e.FluxRaidVisuals.FRAME_WIDTH == 69 and e.FluxRaidVisuals.FRAME_HEIGHT == 42 and e.FluxRaidVisuals.POWER_BAR_HEIGHT == 8,
        "full reset applies screenshot-relative outer and resource dimensions")
end
-- Exercise the real session entry points: raid >=10, explicit party stays5.
local previewSource=read(os.getenv("FLUX_RAID_PREVIEW_SOURCE") or "RaidFrame/FluxRaidPreview.lua")
local previewDB={previewRosterSize=5};local combat=false;local shown={}
local pe=setmetatable({FluxRaidPreview={},FluxOptions={GetRaidFrameDB=function()return previewDB end},
    InCombatLockdown=function()return combat end,print=function()end},{__index=_G});pe._G=pe
pe.FluxRaidPreview_RefreshLayout=function()shown[#shown+1]=previewDB.previewRosterSize end
local prelude="local max,min,floor=math.max,math.min,math.floor\nlocal previewSessionVisible=false\nlocal previewContainer={Hide=function()end}\nlocal ns={}\nlocal function EnsureContainer()end\n"
local visible=assert(load(prelude..part(previewSource,"function FluxRaidPreview.Show(","function FluxRaidPreview.RefreshFromOptions()").."\nreturn function()return previewSessionVisible end","@actual raid/party preview entry points","t",pe))()
pe.FluxRaidPreview.Show();check(visible()and shown[#shown]==10 and not pe.FluxRaidPreview.IsPartyShown(),"raid Show promotes old five-member requests to ten")
pe.FluxRaidPreview.Toggle();check(not visible(),"raid preview toggles off")
pe.FluxRaidPreview.ToggleParty();check(visible()and shown[#shown]==5 and pe.FluxRaidPreview.IsPartyShown(),"explicit party preview keeps five members")
pe.FluxRaidPreview.Toggle();check(visible()and shown[#shown]==10 and not pe.FluxRaidPreview.IsPartyShown(),"raid toggle switches active party preview to ten-member raid")
pe.FluxRaidPreview.Hide();previewDB.previewRosterSize=5;combat=true;pe.FluxRaidPreview.Show()
check(not visible()and previewDB.previewRosterSize==5,"combat guard prevents preview entry and saved-size changes")
combat=false;previewDB.previewRosterSize=40;pe.FluxRaidPreview.Show();check(shown[#shown]==40,"valid raid preview size stays unchanged")
print("Raid aura options/preview: " .. checks .. " checks; actual scopes/resets and synthetic native-relative widgets; desktop only")
