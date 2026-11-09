-- Actual raid option callbacks through production unit/aura refresh routing.
-- Desktop contracts only: public native-owner scaling is modeled, not rendered.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function read(path)
    local absolute = path:match("^%a:[/\\]") or path:sub(1, 1) == "/"
    local file = assert(io.open(absolute and path or root .. path, "rb"))
    local source = file:read("*a"):gsub("\r\n", "\n"); file:close(); return source
end
local function part(source, first, last)
    local a = assert(source:find(first, 1, true))
    local b = assert(source:find(last, a + #first, true))
    return source:sub(a, b - 1)
end
local function run(source, name, environment, ...)
    return assert(load(source, "@" .. name, "t", environment))(...)
end
local checks = 0
local function check(value, label) assert(value, label); checks = checks + 1 end
local function near(a, b) return math.abs(a - b) < 0.000001 end
local fixtureSource = read("tests/raid_healer_auras.lua")
local fixtureEnd = assert(fixtureSource:find('for _,client in ipairs({"retail","forever"})do', 1, true))
local fixture = run(fixtureSource:sub(1, fixtureEnd - 1) .. "\nreturn Fixture", "actual-aura-fixture", _G)
local optionsSource = read(os.getenv("FLUX_RAID_OPTIONS_SOURCE") or "AddonOptions/FluxOptionsRaidFrame.lua")
local frameSource = read("RaidFrame/FluxRaidFrame.lua")
local unitSource = read("RaidFrame/FluxRaidUnit.lua")
local coreSource = part(read("AddonOptions/FluxOptions.lua"), "local function CopyRaidFramesFields", "function FluxOptions:RefreshRaidFramesAfterProfileChange()")
local layoutSource = read("RaidFrame/FluxRaidLayout.lua")
local queueSource = "local State=FluxRaidState\nlocal pendingCombatWork=State.pendingCombatWork\n"
    .. part(layoutSource, "local function Queue(fn)", "local function GetBorderTop()")
    .. part(layoutSource, "function FluxRaid_RunPendingCombatWork()", "function FluxRaid_OnRosterOrPartyChanged()")

local function setup(client, mutation)
    local native = client == "live" or client == "forever"
    local e, auras, frame, objects, boxes = fixture(native, nil, nil, client)
    local api = getmetatable(frame).__index
    local scaleWrites, previewRefreshes = 0, 0
    local setScale = api.SetScale
    function api:SetScale(value)
        if self.kind == "AuraContainer" then scaleWrites = scaleWrites + 1 end
        return setScale(self, value)
    end
    function api:SetStatusBarTexture(value) self.barTexture = value end
    function api:SetIgnoreParentAlpha(value) self.ignoreParentAlpha = value end
    function api:SetAtlas(value) self.atlas = value end
    function api:SetFontObject(value) self.fontObject = value end
    function api:SetJustifyH(value) self.justify = value end
    function api:CreateFontString() return e.CreateFrame("FontString", nil, self) end
    local getHeight = api.GetHeight
    function api:GetHeight()
        local height = getHeight(self) -- retain the forbidden-descendant guard
        if self.height ~= nil then return height end
        if self.allpoints and self.allpoints ~= self then return self.allpoints:GetHeight() end
        local top, bottom
        for _, point in ipairs(self.points) do
            if point[1] == "TOPLEFT" and point[3] == "TOPLEFT" then top = point end
            if point[1] == "BOTTOMRIGHT" and point[3] == "BOTTOMRIGHT" then bottom = point end
        end
        if top and bottom and top[2] == bottom[2] then
            return math.max(1, top[2]:GetHeight() + (top[5] or 0) - (bottom[5] or 0))
        end
        return height
    end
    e.UIParent = e.CreateFrame("Frame")
    frame._fluxRaidUnit = true
    frame.powerBar = e.CreateFrame("StatusBar", nil, frame)
    local header = { attributes = { child1 = frame } }
    function header:GetAttribute(key) return self.attributes[key] end
    function header:SetAttribute(key, value) self.attributes[key] = value end
    e.FluxRaidState = { isInitialized = true, raidHeaders = { header }, pendingCombatWork = {}, frameArray = { [frame] = frame } }
    e.FluxRaidCompat.GROUP_COUNT = 8
    e.FluxRaidHealerExtras.RefreshLayout = function() end
    e.FluxRaidHealerExtras.Update = function() end
    e.FluxRaidPreview = { RefreshFromOptions = function() previewRefreshes = previewRefreshes + 1 end }
    local profile = e.raidDB
    e.FluxOptions.db = { profile = { raidFrames = profile }, char = { raidFrames = {}, raidFramesSettingsScope = "account" } }
    e.DeepCopyValue = function(value)
        if type(value) ~= "table" then return value end
        local copy = {}; for key, child in pairs(value) do copy[key] = e.DeepCopyValue(child) end; return copy
    end
    local ns = { Flux = {} }
    run(unitSource, "actual-raid-unit", e, "_FluxUI", ns)
    -- Health/name/threat painting is outside this regression. Retain the actual
    -- production aura painter; all setup, chrome, iteration and refresh bodies run.
    e.FluxRaid_PaintUnit = function(button) e.FluxRaid_UpdateAuras(button) end
    run(frameSource, "actual-raid-orchestrator", e, "_FluxUI", ns)
    run(queueSource, "actual-raid-combat-queue", e)
    run(read("AddonOptions/FluxOptionsDefaults.lua"), "actual-option-defaults", e, "_FluxUI", ns)
    run(coreSource, "actual-raid-scoped-refresh", e)
    local options = optionsSource
    if mutation == "missing-option-refresh" then
        options = options:gsub("FluxOptions:RefreshRaidFrameScopedModules%(%)", "-- missing scoped refresh", 1)
    end
    run(options, "actual-raid-option-controls", e, "_FluxUI", ns)
    if mutation == "missing-aura-refresh" then e.FluxRaidVisuals.SyncPrivateAuraSettings = function() end end
    local tab = ns.FluxOptionsBuildPartyRaidTab()
    local function snapshot()
        local geometry = assert(frame._fluxAuraRowMetrics, "the actual option callback must configure the live aura owner")
        if native then
            local owner = assert(frame._fluxAuraContainers.buffs)
            local base = assert(frame._fluxAuraNativeMetrics)
            return { width = base.width * owner.scale, height = base.height * owner.scale, scale = owner.scale,
                writes = scaleWrites, count = geometry.buffs.count }
        end
        local icon = assert(frame._fluxAuraCorners.buffs[1])
        return { width = icon:GetWidth(), height = icon:GetHeight(), scale = geometry.scale, count = geometry.buffs.count }
    end
    return e, tab, frame, snapshot, function() return previewRefreshes end, profile, objects, boxes
end

local function resizingCase(client, mutation)
    local e, tab, frame, snapshot, previewCount, profile = setup(client, mutation)
    tab.args.auraIconScale.set(nil, 0.5)
    check(frame._fluxHealerAuras and profile.auraIconScale == 0.5,
        client .. " actual option setter reaches first live aura setup")
    local small = snapshot()
    e.restricted = true -- production refresh must not inspect native descendants
    local control = tab.args.auraIconScale
    local maximum = type(control.max) == "function" and control.max() or control.max
    local previous
    for tick = 0, math.floor((maximum - control.min) / control.step + 0.000001) do
        control.set(nil, control.min + tick * control.step)
        local current = snapshot()
        if previous then
            check(current.width > previous.width + 0.000001 and current.height > previous.height + 0.000001,
                client .. " every selectable aura-slider step visibly grows the normal-aura geometry")
        end
        previous = current
    end
    tab.args.auraIconScale.set(nil, 1)
    local normal = snapshot()
    check(near(normal.width, small.width * 2) and near(normal.height, small.height * 2),
        client .. " normal auras double through the actual0.5to1.0 option callback")
    if client == "live" or client == "forever" then
        check(normal.writes > small.writes and near(normal.scale, small.scale * 2),
            client .. " production refresh writes the public native-container scale")
    end
    check(frame.height == e.FluxRaidVisuals.FRAME_HEIGHT and previewCount() > 0,
        client .. " production apply retains member sizing and preview refresh")
    return e, tab, frame, snapshot, profile
end

for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local e, tab, frame, snapshot, profile = resizingCase(client)
    tab.args.auraIconScale.set(nil, 1.4)
    local capped = snapshot()
    tab.args.auraIconScale.set(nil, 2.5)
    local higher = snapshot()
    check(near(higher.width / capped.width, 2.5 / 1.4) and near(higher.height / capped.height, 2.5 / 1.4),
        client .. " settings above one grow normal auras at six slots through the live option callback")
    tab.args.auraIconScale.set(nil, 0.5)
    local beforeCombat = snapshot()
    e.combat = true
    tab.args.auraIconScale.set(nil, 1)
    check(near(snapshot().width, beforeCombat.width) and next(e.FluxRaidState.pendingCombatWork),
        client .. " combat changes retain current geometry and queue the actual apply function")
    e.combat = false
    e.FluxRaid_RunPendingCombatWork()
    check(near(snapshot().width, beforeCombat.width * 2) and not next(e.FluxRaidState.pendingCombatWork),
        client .. " actual combat queue resumes the requested live aura size")
    tab.args.maxBuffs.set(nil, 4); tab.args.maxDebuffs.set(nil, 5)
    check(frame._fluxAuraRowMetrics.buffs.count == 4 and frame._fluxAuraRowMetrics.debuffs.count == 5,
        client .. " independent four/five limits reach the same live refresh bridge")
    e.FluxOptions:SetRaidFrameCharacterSpecific(true)
    tab.args.auraIconScale.set(nil, 0.5)
    check(e.FluxOptions.db.char.raidFrames.auraIconScale == 0.5 and profile.auraIconScale == 1,
        client .. " actual character-scoped callbacks preserve the account request")
    check(near(snapshot().width, beforeCombat.width),
        client .. " selected character settings resize the active live aura owner")
end

local sizeKeys = { "memberWidthScale", "frameHeightScale", "powerBarHeightScale", "auraIconScale", "raidManagerScale" }
local preset={memberWidthScale=.70,frameHeightScale=.95,powerBarHeightScale=1,auraIconScale=1.82,raidManagerScale=1.20,auraWidthScale=.50,auraDurationFontScale=1.72}
for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local e, tab, frame, snapshot, _, profile = setup(client)
    check(tab.args.useBlizzardDefaultSizes == nil, client .. " native-relative sizes require no mode toggle")
    local custom = { memberWidthScale = 1.1, frameHeightScale = 1.3, powerBarHeightScale = 0.85, auraIconScale = 0.8, raidManagerScale = 0.9 }
    for key, value in pairs(custom) do profile[key] = value end
    profile.maxBuffs, profile.maxDebuffs, profile.displayOnlyDispellableDebuffs, profile.auraTransparency = 4, 5, true, 37
    e.FluxOptions:RefreshRaidFrameScopedModules()
    check(frame:GetWidth() == 108 and frame:GetHeight() == 57 and frame.powerBarUsedHeight == 7,
        client .. " saved requests scale the native baseline without the former thirty-percent modifier")
    check(near(snapshot().width, 8.8) and near(snapshot().height, 8.8), client .. " saved aura requests scale native squares")
    for key, value in pairs(custom) do tab.args[key].get(); check(profile[key] == value, client .. " controls preserve saved " .. key) end
    e.restricted = false -- width defaults change; native access is available out of combat
    tab.args.resetSizes.func()
    for key,value in pairs(preset) do check(profile[key] == value, client .. " the size-only button restores " .. key) end
    check(profile.auraTimersUnderMinute==true,client.." reset restores screenshot timer visibility")
    check(frame:GetWidth() == 69 and frame:GetHeight() == 42 and frame.powerBarUsedHeight == 8
        and near(snapshot().width, 10.01) and near(snapshot().height, 20.02),
        client .. " size-only reset reaches the screenshot's actual unit and aura geometry")
    check(profile.maxBuffs == 4 and profile.maxDebuffs == 5 and profile.displayOnlyDispellableDebuffs and profile.auraTransparency == 37,
        client .. " size-only reset retains counts, strict filtering and transparency")
    profile.auraIconScale = 0.7
    e.FluxOptions:SetRaidFrameCharacterSpecific(true)
    local character = e.FluxOptions:GetRaidFrameDB()
    tab.args.frameHeightScale.set(nil, 1.3)
    e.combat = true
    tab.args.resetSizes.func()
    check(frame:GetHeight() == 57 and next(e.FluxRaidState.pendingCombatWork), client .. " size reset defers protected combat geometry")
    e.combat = false; e.FluxRaid_RunPendingCombatWork()
    check(frame:GetHeight() == 42 and near(snapshot().width, 10.01) and profile.auraIconScale == 0.7,
        client .. " the actual combat queue applies only the selected character size reset")
    for _, key in ipairs(sizeKeys) do character[key] = 1.3 end
    e.FluxOptions:ResetRaidFramesToDefaults()
    for key,value in pairs(preset) do check(character[key] == value, client .. " the standard raid reset restores " .. key) end
    check(frame:GetWidth() == 69 and frame:GetHeight() == 42 and near(snapshot().width, 10.01) and profile.auraIconScale == 0.7,
        client .. " the standard scoped raid reset also reaches stock native widgets")
end

for _, mutation in ipairs({ "missing-option-refresh", "missing-aura-refresh" }) do
    local ok = pcall(resizingCase, "forever", mutation)
    check(not ok, "the integrated live resizing case rejects " .. mutation)
end
for _,client in ipairs({"live","forever"})do
 local e,a,f=fixture(true,nil,nil,client)
 e.raidDB.auraWidthScale=1.5;e.raidDB.auraDurationFontScale=1.4
 check(a.Setup(f),client.." custom width/font initializes native owners")
 for _,button in ipairs(f._fluxNativeAuraButtons)do
  check(near(button:GetWidth()/button:GetHeight(),1.5),"native normal and large glyphs receive the selected X ratio")
  check(near(button.Duration.textScale,1.4),"native duration initializer receives independent font scale")
 end
 e.restricted=true
 e.raidDB.auraWidthScale=.5;e.raidDB.auraDurationFontScale=.5
 a.Refresh(f)
 check(near(f._fluxAuraRowMetrics.width,16.5),"pending width cannot mismatch existing native glyphs before reload")
end
do
 local e,tab,frame,snapshot,preview,profile=setup("forever")
 for _,key in ipairs({"auraWidthScale","auraDurationFontScale"})do
  local control=assert(tab.args[key]);local before=preview()
  check(control.get()==1 and control.min==.5 and control.max==2.5,"independent controls default to one")
  control.set(nil,1.6)
  check(profile[key]==1.6 and preview()>before and control.desc:find("live",1,true),"scoped control saves and refreshes the live display")
 end
 tab.args.resetSizes.func()
 check(profile.auraWidthScale==.50 and profile.auraDurationFontScale==1.72,"size reset restores screenshot width and timer font")
end
do
 local e,tab,frame,snapshot,preview,profile=setup("forever")
 local created=0
 local formatted=0
 e.Enum.NumericRuleFormatRounding={Up=1,Down=2}
 e.C_StringUtil={CreateNumericRuleFormatter=function()
  formatted=formatted+1;local formatter={}
  function formatter:SetBreakpoints(rules)self.rules=rules end
  function formatter:FormatNumber(seconds)
   local selected
   for _,rule in ipairs(self.rules)do if seconds>=rule.threshold then selected=rule end end
   if selected.format==""then return ""end
   local value=seconds/(selected.components and selected.components[1].div or 1)
   return string.format(selected.format,selected.rounding==1 and math.ceil(value)or math.floor(value))
  end
  return formatter
 end}
 e.CreateFont=function(name)
  created=created+1
  local font={name=name,writes=0}
  function font:SetFont(path,size,flags)self.path,self.size,self.flags=path,size,flags;self.writes=self.writes+1 end
  return font
 end
 tab.args.auraIconScale.set(nil,1)
 local label=frame._fluxNativeAuraButtons[1].Duration
 local font=assert(label.fontObject,"native duration inherits the addon-owned font before registration")
 local fit=label.textScale
 check(created==1 and font.size==10,"one shared duration font is allocated for all native sinks")
 check(font.flags=="OUTLINE" and label.shadowColor[1]==0 and label.shadowColor[4]==1,"live duration font has a black outline and opaque black shadow")
 local formatter=frame._fluxNativeAuraButtons[1].durationOptions.textFormatter
 check(formatter:FormatNumber(59)=="59" and formatter:FormatNumber(60)=="1m" and formatter:FormatNumber(3600)=="1h","default timers retain seconds/minutes/hours")
 e.restricted=true
 tab.args.auraTimersUnderMinute.set(nil,true)
 check(profile.auraTimersUnderMinute and formatter:FormatNumber(59)=="59" and formatter:FormatNumber(60)=="" and formatter:FormatNumber(61)=="" and formatter:FormatNumber(7200)=="",
  "under-minute toggle blanks exactly60 and above without changing the native binding")
 check(formatted==1 and frame._fluxNativeAuraButtons[1].Cooldown.drawSwipe,"threshold changes reuse one formatter and retain cooldown swipes")
 tab.args.auraTimersUnderMinute.set(nil,false)
 check(formatter:FormatNumber(90)=="1m","disabling the threshold restores long-duration numbers")
 tab.args.auraDurationFontScale.set(nil,.5)
 check(font.size==5 and label.textScale==fit and created==1,"duration slider shrinks existing native text by updating only its public font")
 tab.args.auraDurationFontScale.set(nil,2)
 check(font.size==20 and label.textScale==fit,"duration slider grows existing native text without revisiting restricted descendants")
 e.combat=true;tab.args.auraDurationFontScale.set(nil,1.5)
 check(font.size==20 and next(e.FluxRaidState.pendingCombatWork),"combat font changes retain the current font and queue refresh")
 e.combat=false;e.FluxRaid_RunPendingCombatWork()
 check(font.size==15 and created==1,"combat exit applies the saved font to all existing native sinks")
 tab.args.resetSizes.func()
 check(near(font.size,17.2),"size reset updates the shared live duration font to the screenshot preset")
end
do
 local e,tab,frame,snapshot,preview,profile=setup("forever")
 tab.args.auraIconScale.set(nil,1)
 local item=frame._fluxNativeAuraGeometry[1]
 e.restricted=false
 tab.args.auraWidthScale.set(nil,1.5)
 check(item.button.width==16.5 and item.button.height==11 and frame._fluxAuraRowMetrics.width==16.5,
  "accessible native frames and clipping geometry resize together")
 check(frame._fluxAuraContainers.dispel.groups.bossDebuffs.options.layout.elementWidth==16.5,"native flow keeps three columns at the new width")
 e.restricted=true
 tab.args.auraWidthScale.set(nil,.5)
 check(item.button.width==16.5 and frame._fluxPendingNativeWidth and frame._fluxAuraRowMetrics.width==16.5,
  "denied native access retains the last visible geometry without querying or mutating descendants")
 e.restricted=false;tab.args.auraWidthScale.set(nil,.5)
 check(item.button.width==5.5 and item.button.height==11 and not frame._fluxPendingNativeWidth,
  "the pending width applies once native access is available")
 e.combat=true;tab.args.auraWidthScale.set(nil,2)
 check(item.button.width==5.5 and next(e.FluxRaidState.pendingCombatWork),"combat width changes stay deferred")
 e.combat=false;e.FluxRaid_RunPendingCombatWork()
 check(item.button.width==22 and item.button.height==11,"combat exit updates the accessible native width")
end
print("Raid aura live options: " .. checks .. " checks; actual scoped options/orchestrator/unit/aura/queue bridge on five modeled clients; native pixels pending")
