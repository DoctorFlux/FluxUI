-- Execute production school lookup, renderer, options, and cast lifecycle with
-- desktop WoW mocks. These checks cannot emulate native secret geometry/taint.
math.randomseed(20261031)
local checks = 0
local function check(ok, message) checks = checks + 1; assert(ok, message) end
local function loadAddon(path, env, ns)
    local fn, err
    if _VERSION == "Lua 5.1" then fn, err = loadfile(path); if fn then setfenv(fn, env) end
    else fn, err = loadfile(path, "t", env) end
    assert(fn, err)("_FluxUI", ns)
end
local function fixture(branch, capabilities)
    capabilities = capabilities or {}
    local state = {frames = {}, textures = {}, casts = {}, metadata={},cold={},loadRequests={},timers={},
        work={metadata=0,textures=0,gradients=0,positions=0,sizes=0,spriteWrites=0},animations={},clock = 1, released = 0, claimed = 0,
        combatLogCalls = {register = 0, unregister = 0, read = 0},
        combatLogRestricted = capabilities.combatLogRestricted or branch == "live" or branch == "forever"}
    local secret = setmetatable({}, {__tostring = function() error("secret tostring") end,
        __add = function() error("secret arithmetic") end, __sub = function() error("secret arithmetic") end})
    state.secret = secret
    local env = setmetatable({}, {__index = _G}); env._G = env
    env.unpack = unpack or table.unpack
    local methods = {}
    local function spriteWrite(self)
        if state.spriteParent and self.parent==state.spriteParent then state.work.spriteWrites=state.work.spriteWrites+1 end
    end
    local function object(kind, parent)
        return setmetatable({kind = kind, parent = parent, scripts = {}, events = {}, hooks = {},
            shown = true, alpha = 1, width = 300, height = 22, level = parent and parent.level + 1 or 1,
            low = 0, high = 5, value = 2, points = {}, color = {1,1,1,1}}, {__index = methods})
    end
    function methods:SetScript(key, value) self.scripts[key] = value end
    function methods:HookScript(key, callback)
        self.hooks[key] = self.hooks[key] or {}; table.insert(self.hooks[key], callback)
    end
    function methods:Show() self.shown = true end
    function methods:Hide()
        local was = self.shown; self.shown = false
        if was then for _, fn in ipairs(self.hooks.OnHide or {}) do fn(self) end end
    end
    function methods:SetShown(value) if value then self:Show() else self:Hide() end end
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:GetParent() return self.parent end
    function methods:SetParent(parent) self.parent = parent end
    function methods:SetFrameLevel(value) self.level = value end
    function methods:GetFrameLevel() return self.level end
    function methods:SetAlpha(value) spriteWrite(self);self.alpha = value end
    function methods:GetAlpha() return self.alpha end
    function methods:SetSize(w,h)
        state.work.sizes=state.work.sizes+1
        spriteWrite(self)
        assert(type(w)=="number" and type(h)=="number" and w==w and h==h,"numeric, finite dimensions")
        self.width,self.height = w,h
    end
    function methods:GetSize() return self.width,self.height end
    function methods:SetWidth(w) self.width = w end
    function methods:GetWidth() return self.width end
    function methods:SetHeight(h) self.height = h end
    function methods:GetHeight() return self.height end
    function methods:GetLeft() return 0 end
    function methods:GetRight() return self.width end
    function methods:ClearAllPoints() self.points = {} end
    function methods:SetPoint(...) spriteWrite(self);state.work.positions=state.work.positions+1;self.points[#self.points+1] = {...} end
    function methods:SetAllPoints(target) self.allPoints = target end
    function methods:EnableMouse(value) self.mouse = value end
    function methods:SetClipsChildren(value) self.clipped = value end
    function methods:SetTexture(path)
        state.work.textures=state.work.textures+1
        if capabilities.noCompositeFills and type(path)=="string" and path:find("Fills\\fill_",1,true) then self.path=nil;return false end
        self.path=path;return true
    end
    function methods:SetDrawLayer(layer,sublevel)self.drawLayer,self.sublevel=layer,sublevel end
    function methods:SetAtlas(path) self.atlas = path end
    function methods:SetTexCoord(...) self.uv = {...} end
    function methods:SetBlendMode(value) self.blend = value end
    function methods:SetRotation(value) spriteWrite(self);self.rotation = value end
    function methods:SetVertexColor(...) spriteWrite(self);self.color = {...} end
    function methods:GetVertexColor() return env.unpack(self.color) end
    function methods:SetDesaturated(value) self.desaturated = value end
    function methods:SetGradient(...) self.gradient = {...};state.work.gradients=state.work.gradients+1 end
    function methods:SetGradientAlpha(...) self.gradient = {...};state.work.gradients=state.work.gradients+1 end
    function methods:CreateTexture()
        local tex = object("Texture",self); state.textures[#state.textures+1] = tex; return tex
    end
    function methods:CreateFontString() return object("FontString", self) end
    function methods:SetStatusBarTexture(path)
        if not self.texture then self.texture = self:CreateTexture() end
        self.texture:SetTexture(path); return true
    end
    function methods:GetStatusBarTexture() return self.texture end
    function methods:SetStatusBarColor(...) self.color = {...} end
    function methods:SetMinMaxValues(low, high) self.low,self.high = low,high; self.manualWrites = (self.manualWrites or 0)+1 end
    function methods:GetMinMaxValues() return self.low,self.high end
    function methods:SetValue(value) self.value = value; self.valueWrites = (self.valueWrites or 0)+1 end
    function methods:GetValue() return self.value end
    function methods:SetColorFill(...) self.colorFill = {...} end
    function methods:RegisterEvent(event)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            state.combatLogCalls.register = state.combatLogCalls.register + 1
            assert(not state.combatLogRestricted, "ADDON FORBIDDEN: Frame:RegisterEvent()")
            assert(not capabilities.rejectCombatLogRegistration, "unsupported combat-log event")
        end
        self.events[event] = true
    end
    function methods:RegisterUnitEvent(event, unit) self.events[event] = unit end
    function methods:UnregisterEvent(event)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            state.combatLogCalls.unregister = state.combatLogCalls.unregister + 1
            assert(not state.combatLogRestricted, "ADDON FORBIDDEN: Frame:UnregisterEvent()")
        end
        self.events[event] = nil
    end
    function methods:UnregisterAllEvents() self.events = {} end
    function methods:SetFont() end
    function methods:SetTextColor() end
    function methods:SetWordWrap() end
    function methods:SetMaxLines() end
    function methods:SetJustifyH() end
    function methods:SetFrameStrata() end
    function methods:SetText(text) self.text = text end
    function methods:SetFormattedText(fmt, ...) self.text = string.format(fmt, ...) end
    function methods:GetStringWidth() return 28 end
    function methods:CreateAnimationGroup()
        if capabilities.nativeParticles then
            local group={animations={},scripts={},texture=self}
            function group:CreateAnimation(kind)
                if capabilities.badNativeAnimation then error("unavailable animation") end
                local animation={kind=kind,delay=0,duration=0}
                function animation:SetOrder(value)self.order=value end
                function animation:SetSmoothing()end
                function animation:SetDuration(value)self.duration=value end
                function animation:SetStartDelay(value)self.delay=value end
                function animation:SetOffset(x,y)self.offset={x,y}end
                function animation:SetFromAlpha(value)self.from=value end
                function animation:SetToAlpha(value)self.to=value end
                function animation:SetScaleFrom(x,y)self.scaleFrom={x,y}end
                function animation:SetScaleTo(x,y)self.scaleTo={x,y}end
                function animation:SetRadians(value)self.radians=value end
                function animation:SetStartColor(value)self.startColor=value end
                function animation:SetEndColor(value)self.endColor=value end
                if capabilities.partialNativeAnimation and kind=="Alpha" then animation.SetToAlpha=nil end
                group.animations[#group.animations+1]=animation;return animation
            end
            function group:SetScript(key,fn)self.scripts[key]=fn end
            function group:SetToFinalAlpha(value)self.finalAlpha=value end
            function group:Stop()self.playing=false end
            function group:Play()
                self.elapsed,self.duration,self.playing=0,0,true
                for _,animation in ipairs(self.animations)do self.duration=math.max(self.duration,animation.duration+animation.delay)end
            end
            state.animations[#state.animations+1]=group;return group
        end
        return {CreateAnimation = function() return {SetOrder=function()end,SetDuration=function()end,
            SetFromAlpha=function()end,SetToAlpha=function()end,SetSmoothing=function()end,SetStartDelay=function()end} end,
            SetScript=function()end,Stop=function()end,Play=function()end}
    end
    env.CreateFrame = function(kind, _, parent)
        local frame = object(kind, parent); state.frames[#state.frames+1] = frame; return frame
    end
    env.CreateColor = function(...) return {...} end
    env.GetTime = function() return state.clock end
    env.GetLocale=function()return state.locale or "enUS"end
    -- Test-client metadata only. Production has no spell-ID catalog.
    for id,school in pairs({[133]="Fire",[143]="Fire",[116]="Frost",[585]="Holy",[686]="Shadow",[2061]="Holy",
        [5176]="Nature",[403]="Nature",[5143]="Arcane",[44614]="Frostfire",[356995]="Spellfrost",[264178]="Shadowflame",
        [191837]="Nature",[355936]="Nature",[382731]="Nature",[357211]="Fire",[357208]="Fire",[408490]="Fire",
        [2823]="Nature",[19434]="Physical",[56641]="Physical",[1510]=(branch=="live" or branch=="classic") and "Physical" or "Arcane"}) do
        state.metadata[id]={name="Client spell "..id,description="Deals 100 "..school.." damage.",harmful=true}
    end
    state.metadata[133].name="Boule de feu";state.metadata[143].name="Boule de feu"
    state.metadata[585].name="Ambiguous";state.metadata[686].name="Ambiguous"
    env.UnitClass = function(unit) return "Mage", unit == "pet" and "WARLOCK" or "MAGE" end
    env.UnitIsPlayer = function() return false end
    env.UnitGUID = function(unit) return "guid-" .. unit end
    env.UnitExists = function() return true end
    env.C_Spell = {GetSpellName = function(id)
        state.work.metadata=state.work.metadata+1
        if state.metadata[id] then return state.metadata[id].name end
        if id == 133 or id == 143 then return "Boule de feu" end
        if id == 116 then return "Eclair de givre" end
        if id == 585 or id == 686 then return "Ambiguous" end
    end, GetSpellInfo = function(id) return {castTime = 5000, name = "Spell", spellID = id} end,
    GetSpellDescription=function(id)state.work.metadata=state.work.metadata+1;return state.metadata[id] and state.metadata[id].description end,
    IsSpellHelpful=function(id)return state.metadata[id] and state.metadata[id].helpful or false end,
    IsSpellHarmful=function(id)return state.metadata[id] and state.metadata[id].harmful or false end,
    GetBaseSpell=function(id)return state.metadata[id] and state.metadata[id].base end}
    env.C_Spell.GetSchoolString=function(mask)return state.schoolNames and state.schoolNames[mask] end
    env.C_Spell.IsSpellDataCached=function(id)return not state.cold[id]end
    env.C_Spell.RequestLoadSpellData=function(id)state.loadRequests[id]=(state.loadRequests[id] or 0)+1 end
    env.C_Texture = {GetAtlasInfo = function() if branch == "forever" or branch == "live" then return {} end end}
    env.C_Timer = {NewTimer = function(_, fn) return {Cancel=function()end, callback=fn} end,
        After = function(_,fn)if capabilities.deferTimers then state.timers[#state.timers+1]=fn else fn() end end}
    function state.FlushTimers()
        local timers=state.timers;state.timers={}
        for _,fn in ipairs(timers) do fn() end
    end
    env.UIFrameFadeRemoveFrame = function() end
    env.UIFrameFadeOut = function() end
    env.hooksecurefunc = function() end
    env.IsWoWLegacyClient = function() return branch ~= "forever" and branch ~= "live" end
    env.Enum = {StatusBarTimerDirection = {}, StatusBarInterpolation = {}}
    env.UnitCastingInfo = function(unit)
        local cast = state.casts[unit]
        if cast and not cast.channel then return cast.name or "Spell", cast.name or "Spell", 12345, 0, 5000, cast.trade, "cast-1", cast.locked, cast.id end
    end
    env.UnitChannelInfo = function(unit)
        local cast = state.casts[unit]
        if cast and cast.channel then return cast.name or "Spell", cast.name or "Spell", 12345, 0, 5000, cast.trade, cast.locked, cast.id, nil, cast.stages or 0 end
    end
    env.GetUnitEmpowerStageDuration = function() return 1000 end
    env.GetUnitEmpowerHoldAtMaxTime = function() return 1000 end
    env.FluxUnitFrames_ShouldShowCastBar = function() return true end
    env.FluxUnitFrames_ShouldShowCastTime = function() return true end
    env.FluxUnitFrames_ShouldUseFlux = function() return true end
    env.UIParent = object("Frame")
    local db = {castBarThemes = {}}
    env.FluxOptions = {GetUnitFrameDB = function() return db end}
    local ns = {API = {}, UnitFrames = {}, Border = {ApplyTo=function()end,SetBorderColor=function()end,
        SetBackdropColor=function()end,HideBackground=function()end,ShowBackground=function()end}}
    ns.API.IsSecretValue = function(value) return rawequal(value, secret) end
    ns.API.CanAccessValue = function(value) return not rawequal(value, secret) end
    ns.API.SafeAccessibleString = function(value) if not rawequal(value, secret) and type(value)=="string" then return value end end
    ns.Flux = {Client = {isEra = branch == "classic_era", isAnniversary = branch == "classic_anniversary",
        isLiveMidnight = branch == "live",
        isMists = branch == "classic", isAnyClassic = branch ~= "live" and branch ~= "forever", isForever = branch == "forever"},
        Cap = {hasCombatLogUnfiltered = branch ~= "live" and branch ~= "forever"}}
    env.FLUX_API = ns.Flux.Client
    env.C_CombatLog = {IsCombatLogRestricted = function()
        if capabilities.restrictionQueryFails then error("restriction unavailable") end
        if capabilities.restrictionQuerySecret then return secret end
        return state.combatLogRestricted
    end}
    env.CombatLogGetCurrentEventInfo = function()
        state.combatLogCalls.read = state.combatLogCalls.read + 1
        assert(not state.combatLogRestricted,"ADDON FORBIDDEN: CombatLogGetCurrentEventInfo()")
        if state.combatLogPayload then return env.unpack(state.combatLogPayload) end
    end
    if capabilities.gradient == "legacy" or capabilities.gradient == "solid" then
        methods.SetGradient = nil
        env.CreateColor = false
    end
    if capabilities.gradient == "solid" then methods.SetGradientAlpha = nil end
    if capabilities.noAtlas then env.C_Texture = false; methods.SetAtlas = nil end
    if capabilities.noClip then methods.SetClipsChildren = nil end
    ns.SwingTimer = {HideForCastBarClaim=function()state.claimed=state.claimed+1 end,
        OnCastBarSlotReleased=function()state.released=state.released+1 end}
    function state.SetDB(nextDB) db = nextDB end
    function state.GetDB() return db end
    function state.Tick(dt)
        for _,group in ipairs(state.animations) do
            if group.playing then
                group.elapsed=group.elapsed+dt
                if group.elapsed>=group.duration then group.playing=false;if group.scripts.OnFinished then group.scripts.OnFinished(group)end end
            end
        end
        for _, frame in ipairs(state.frames) do if frame:IsVisible() and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, dt) end end
    end
    function state.Cast(unit, id, channel, trade, stages)
        state.casts[unit] = {id=id,channel=channel,trade=trade,stages=stages}
        local bar = ns[({player="PlayerFrame",target="TargetFrame",focus="FocusFrame",pet="PetFrame"})[unit]].CastBar
        bar:CastStart(unit, channel, "cast-1")
        return bar
    end
    function state.Event(bar, event, unit, ...)
        bar.scripts.OnEvent(bar, event, unit, ...)
    end
    function state.NewBar(unit)
        local frame = object("Frame"); frame.unit = unit
        ns[({player="PlayerFrame",target="TargetFrame",focus="FocusFrame",pet="PetFrame"})[unit]] = frame
        return ns.CastBar.CreateCastBar(frame, unit)
    end
    function state.LiveParticles()
        local n=0
        for _, tex in ipairs(state.textures) do
            if tex:IsShown() and tex.rotation and tex.parent.kind == "Frame" then n=n+1 end
        end
        return n
    end
    function state.VisibleDrivers()
        local n=0
        for _, frame in ipairs(state.frames) do
            if frame.scripts.OnUpdate and frame:IsShown() and not frame.TimerBar then n=n+1 end
        end
        return n
    end
    loadAddon("UnitFrames/FluxCastBarSchools.lua",env,ns)
    loadAddon("UnitFrames/FluxCastBarVisuals.lua",env,ns)
    loadAddon("UnitFrames/FluxCastBarThemes.lua",env,ns)
    loadAddon("UnitFrames/FluxCastBar.lua",env,ns)
    return state,env,ns
end

local function checkParticleGeometry(s, aspect, label)
    local count=0
    for _,tex in ipairs(s.textures) do
        if tex.rotation and tex:IsShown() then
            count=count+1
            check(type(tex.width)=="number" and type(tex.height)=="number" and tex.width>0 and tex.height>0,
                label.." finite particle geometry")
            local expected=type(aspect)=="table" and (aspect[tex.path:match("[^\\]+$")] or 1) or aspect
            check(math.abs(tex.height/tex.width-expected)<0.00001,label.." expected particle aspect")
        end
    end
    check(count>0,label.." actually emitted particles")
end

-- Dynamic client metadata, not per-spell implementation cases, supplies the
-- same resolver for every class and all five runtime branches.
for _,branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"}) do
    for _,case in ipairs({
        {"SHAMAN",188196,"Lightning Bolt","Deals 100 Nature damage.","lightning",8,403},
        {"SHAMAN",990001,"Storm Needle","Deals 100 Nature damage.",nil,8},
        {"SHAMAN",990003,"Stone Shock","Deals 100 Nature damage.",nil,8},
        {"MAGE",990004,"Prismatic Beam","Deals 100 Fire, Frost, and Arcane damage.",nil,84},
        {"WARLOCK",264178,"Demonbolt","Deals 100 Shadowflame damage.",nil,36},
        {"PRIEST",14914,"Holy Fire","Deals 100 Holy damage.",nil,2},
        {"PALADIN",990005,"Radiant Beam","Deals 100 Radiant damage.",nil,6},
        {"DRUID",78674,"Starsurge","Deals 100 Astral damage.",nil,72},
        {"DRUID",5176,"Wrath","Deals 100 Nature damage.",nil,8},
        {"DRUID",2912,"Starfire","Deals 100 Arcane damage.",nil,64},
        {"MONK",117952,"Crackling Jade Lightning","Deals 100 Nature damage.","lightning",8},
        {"DEATHKNIGHT",990006,"Blood Siphon","Deals 100 Shadow damage.",nil,32},
        {"DEMONHUNTER",198013,"Eye Beam","Deals 100 Chaos damage.","chaos",124},
        {"EVOKER",356995,"Disintegrate","Deals 100 Spellfrost damage.",nil,80},
        {"HUNTER",990007,"Cobra Shot","Deals 100 Nature damage.",nil,8},
        {"ROGUE",2823,"Deadly Poison","Deals 100 Nature damage.",nil,8},
    }) do
        local s,e,ns=fixture(branch)
        e.UnitClass=function()return case[1],case[1]end
        s.metadata[case[2]]={name=case[3],description=case[4],base=case[7],helpful=case[8],harmful=not case[8]}
        local bar=s.NewBar("player")
        s.Cast("player",case[2])
        local theme,info=ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)
        check(theme and info.mask==case[6] and info.profile==case[5],branch.." "..case[1].." metadata theme: "..case[3])
        for i=1,90 do s.Tick(1/60) end
        check(s.LiveParticles()>0,branch.." "..case[3].." emits its visuals")
        if case[2]>=990000 then
            check(info.inferred and ns.CastBarSchools.Resolve(case[2])==nil,branch.." inferred appearance does not become verified school data")
        end
        if info.profile=="lightning" then
            s.GetDB().castBarThemes.spellVisuals=false;ns.CastBarThemes.Refresh()
            local schoolTheme=ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)
            check(schoolTheme.components[1].school=="nature",branch.." unified spell-specific toggle restores generic Nature")
        end
        s.GetDB().castBarThemes.spellVisuals=false;ns.CastBarThemes.Refresh()
        local _,schoolInfo=ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)
        check(schoolInfo.profile==(info.profile=="chaos" and "chaos" or nil) and schoolInfo.schoolMask==info.schoolMask,branch.." visual mode never changes mechanical school")
        bar:Hide()
    end

    local s,e,ns=fixture(branch)
    local bar=s.NewBar("player")
    s.metadata[990008]={name="Adaptive Magic",description="Deals 100 Fire damage.",harmful=true}
    s.Cast("player",990008)
    check(bar._fluxSchoolCast.visualMask==4 and bar._fluxSchoolCast.schoolMask==nil,branch.." new spell infers Fire without an ID entry")
    s.metadata[990008].description="Deals 100 Frost damage."
    for _,f in ipairs(s.frames) do if f.events.SPELLS_CHANGED then f.scripts.OnEvent(f,"SPELLS_CHANGED") end end
    check(bar._fluxSchoolCast.visualMask==16,branch.." spell changes invalidate inferred metadata")
    s.GetDB().castBarThemes.inferVisuals=false;ns.CastBarThemes.Refresh()
    check(bar:GetStatusBarTexture():GetAlpha()==1,branch.." inference toggle restores default for unmapped spells")
    s.GetDB().castBarThemes.inferVisuals=true
    e.UnitClass=function()return "Shaman","SHAMAN"end
    s.metadata[990009]={name="New Lightning",description="Deals 100 Nature damage.",harmful=true}
    s.casts.player={name=s.secret,id=s.secret,trade=s.secret}
    s.Event(bar,"UNIT_SPELLCAST_START","player","cast-1",990009)
    check(bar._fluxSchoolCast.id==990009 and bar._fluxSchoolCast.visualMask==8,branch.." accessible event identity rescues wrapped cast fields")
    s.metadata[990010]={name="Stone Draft",description="Deals 100 Nature damage.",harmful=true}
    s.Cast("player",990010,nil,true)
    check(bar:GetStatusBarTexture():GetAlpha()==1,branch.." profession flag still blocks inferred visuals")
    s.locale="frFR";s.schoolNames={[4]="Feu",[8]="Nature"};ns.CastBarVisuals.Invalidate()
    s.metadata[990011]={name="Nouvelle magie",description="Inflige 100 points de dégâts de Feu.",harmful=true}
    s.Cast("player",990011)
    check(bar._fluxSchoolCast.visualMask==4,branch.." localized school label infers new spell")
    s.metadata[990012]={name="Nouvelle nature",description="Inflige 100 points de dégâts de Nature.",harmful=true}
    s.Cast("player",990012)
    check(bar._fluxSchoolCast.visualMask==8,branch.." shared English/localized Nature label still resolves")
    s.metadata[990013]={name="New Strike",description="Deals 100 Physical damage.",harmful=true}
    s.Cast("player",990013)
    check(bar:GetStatusBarTexture():GetAlpha()==1,branch.." unmapped physical spells remain default")
    s.locale="enUS";s.schoolNames=nil;ns.CastBarVisuals.Invalidate()
    s.metadata[990014]={name="Cold Spell",harmful=true};s.cold[990014]=true
    s.Cast("player",990014)
    check(s.loadRequests[990014]==1 and bar:GetStatusBarTexture():GetAlpha()==1,branch.." missing metadata requests spell data once")
    for _,f in ipairs(s.frames) do if f.events.SPELL_DATA_LOAD_RESULT then f.scripts.OnEvent(f,"SPELL_DATA_LOAD_RESULT",990014,false) end end
    check(s.loadRequests[990014]==1,branch.." failed spell-data load cannot loop")
    s.cold[990014]=nil;s.metadata[990014].description="Deals 100 Fire damage and 100 Frost damage."
    for _,f in ipairs(s.frames) do if f.events.SPELL_DATA_LOAD_RESULT then f.scripts.OnEvent(f,"SPELL_DATA_LOAD_RESULT",990014,true) end end
    check(bar._fluxSchoolCast.visualMask==20,branch.." data arrival updates hybrid appearance on current cast")
    s.metadata[403]={name="Changed Spell",description="Deals 100 Frost damage.",harmful=true}
    ns.CastBarVisuals.Invalidate();s.Cast("player",403)
    check(bar._fluxSchoolCast.visualMask==16 and bar._fluxSchoolCast.schoolMask==nil and bar._fluxSchoolCast.inferred,
        branch.." current description supplies school without a spell list")
    ns.CastBarSchools.Learn(403,8);ns.CastBarThemes.Refresh()
    check(bar._fluxSchoolCast.visualMask==8,branch.." observed combat-log school outranks inferred description")
    s.metadata[990015]={name="Shadow Mend",description="Heals a friendly ally.",helpful=true}
    s.Cast("player",990015)
    check(bar:GetStatusBarTexture():GetAlpha()==1 and s.LiveParticles()==0,branch.." helpful cast without school evidence retains default")
    ns.CastBarSchools.Learn(990015,32);ns.CastBarThemes.Refresh()
    check(bar._fluxSchoolCast.visualMask==32,branch.." reported school still themes helpful spells")
    bar:Hide()
end

-- Mount/item utility spells must not inherit the caster's class or a word in
-- their display name. Check both metadata-rich and uncached tooltip paths.
for _,branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"}) do
    for _,class in ipairs({"MAGE","PRIEST","PALADIN","SHAMAN","DRUID","MONK","EVOKER"}) do
        local s,e,ns=fixture(branch)
        e.UnitClass=function()return class,class end
        local bar=s.NewBar("player")
        for i,case in ipairs({
            {"Mount Journal Steed","Summons and dismisses this mount."},
            {"Item Mount","Summons a rideable mount."},
            {"Arcane Hippogryph","Summons a rideable mount."},
            {"Lightning Steed","Summons a rideable mount."},
            {"Arcane Hippogryph"},{"Lightning Steed"},
            {"Use Item","Restores health and mana."},
            {"Use Item"},
        }) do
            local id=4200000+i
            s.metadata[id]={name=case[1],description=case[2],helpful=true,harmful=false}
            s.Cast("player",id)
            check(ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)==nil,
                branch.." "..class.." utility cast has no inferred school: "..case[1])
            check(bar:GetStatusBarTexture():GetAlpha()==1 and s.LiveParticles()==0,
                branch.." "..class.." utility cast preserves default appearance")
        end
        bar:Hide()
    end
end

-- All valid school combinations, including three-way and six-way hybrids,
-- retain every base palette. The renderer must also emit every component.
for _,branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"}) do
    local s,e,ns=fixture(branch)
    local bar=s.NewBar("player")
    local paths={flames="cast_flame",snow="cast_snow",shimmer="cast_spark",skulls="shadow_skull",motes="cast_dot",leaves="cast_leaf",impact="cast_spark"}
    s.GetDB().castBarThemes.spellVisuals=false
    for mask=2,127 do
        local count=0
        for _,bit in ipairs({2,4,8,16,32,64}) do if math.floor(mask/bit)%2==1 then count=count+1 end end
        local theme=ns.CastBarThemes.ThemeForMask(mask)
        check(theme and #theme.components==count,branch.." mask "..mask.." retains every magic component")
        ns.CastBarSchools.Learn(990100,mask)
        s.Cast("player",990100)
        for i=1,120 do s.Tick(1/60) end
        local emitted={}
        for _,tex in ipairs(s.textures) do
            if tex.rotation and tex:IsVisible() then emitted[tex.path:match("[^\\]+$")]=true end
        end
        for _,component in ipairs(theme.components) do
            check(emitted[paths[component.fx]],branch.." mask "..mask.." emits "..component.fx)
        end
        local layers={}
        for _,tex in ipairs(s.textures) do if tex.gradient and tex:IsVisible() then layers[#layers+1]=tex end end
        check(#layers==1,branch.." mask "..mask.." uses one fill draw")
        if count>1 then
            local rendered=ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)
            check(layers[1].path==rendered.fillPath and layers[1].allPoints==bar:GetStatusBarTexture(),
                branch.." mask "..mask.." scales complete composite to current fill")
        end
    end
    ns.CastBarSchools.Learn(990100,28);s.Cast("player",990100)
    s.GetDB().castBarThemes.gradient=false;ns.CastBarThemes.Refresh()
    local solid=0
    for _,tex in ipairs(s.textures) do if tex.gradient and tex:IsVisible() then solid=solid+1 end end
    check(solid==1,branch.." gradient off keeps the same single composite draw")
    bar:Hide();check(s.VisibleDrivers()==0,branch.." exhaustive hybrids stop their driver")
end

-- Completion and spell-load storms must not redo discovery/layout or leave a
-- live animation driver behind. Count real mock API work, not wall-clock FPS.
for _,branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"}) do
    local s,e,ns=fixture(branch,{deferTimers=true})
    local fx=ns.CastBarThemes
    local bar=s.NewBar("player")
    local data=s.GetDB().castBarThemes
    ns.CastBarSchools.Learn(990500,28)
    data.particles=false
    s.Cast("player",990500)
    local resolve,layout,apply,update=fx.ResolveTheme,fx.Layout,fx.Apply,fx.Update
    local calls={resolve=0,layout=0,apply=0,update=0}
    fx.ResolveTheme=function(...)calls.resolve=calls.resolve+1;return resolve(...)end
    fx.Layout=function(...)calls.layout=calls.layout+1;return layout(...)end
    fx.Apply=function(...)calls.apply=calls.apply+1;return apply(...)end
    fx.Update=function(...)calls.update=calls.update+1;return update(...)end
    local beforeTextures,beforeFrames=#s.textures,#s.frames
    local beforeWrites,beforeGradients=s.work.textures,s.work.gradients
    fx.Finish(bar)
    check(calls.resolve==0 and calls.layout==0 and calls.apply==0,branch.." finish never re-resolves/re-lays out/reapplies the theme")
    check(#s.textures==beforeTextures and #s.frames==beforeFrames and s.work.textures==beforeWrites
        and s.work.gradients==beforeGradients,branch.." finish creates and repaints no artwork")
    check(bar:IsVisible() and s.VisibleDrivers()==0,branch.." finished static appearance sleeps during hold/fade")
    fx.Finish(bar)
    check(calls.resolve==0 and s.work.textures==beforeWrites,branch.." repeated completion is idle")

    s.Cast("player",990500)
    local old=bar:GetStatusBarTexture()
    local replacement=bar.TimerBar:CreateTexture();replacement:SetTexture("replacement")
    bar.TimerBar.texture=replacement
    beforeWrites=s.work.textures;beforeGradients=s.work.gradients
    fx.Finish(bar)
    check(old:GetAlpha()==1 and replacement:GetAlpha()==0,branch.." completion restores replaced source and captures new source")
    local layerCount=0
    for _,tex in ipairs(s.textures) do
        if tex:IsVisible() and type(tex.path)=="string" and tex.path:find("Fills\\fill_",1,true) then
            layerCount=layerCount+1
            check(tex.allPoints==replacement,branch.." completion reanchors existing hybrid layer")
        end
    end
    check(layerCount==1 and s.work.textures==beforeWrites and s.work.gradients==beforeGradients,
        branch.." replacement preserves all three palettes without repainting")

    data.particles=true;s.Cast("player",990500)
    local beforeUpdates=calls.update
    for i=1,120 do s.Tick(1/120) end
    check(calls.update-beforeUpdates>=29 and calls.update-beforeUpdates<=31,branch.." high frame rates run only 30 particle updates/second")
    check(s.LiveParticles()>0,branch.." performance cap still produces particles")
    fx.Finish(bar)
    beforeWrites=s.work.textures;beforeGradients=s.work.gradients
    for i=1,240 do s.Tick(1/120) end
    check(s.VisibleDrivers()==0 and s.LiveParticles()==0,branch.." particle tail drains and stops driver with glows enabled")
    check(s.work.textures==beforeWrites and s.work.gradients==beforeGradients,branch.." particle tail never repaints the fill")

    s.Cast("player",133)
    local eventFrame
    for _,frame in ipairs(s.frames) do if frame.events.SPELL_DATA_LOAD_RESULT then eventFrame=frame end end
    local beforeMetadata=s.work.metadata
    local beforeApply=calls.apply
    for id=900000,900999 do eventFrame.scripts.OnEvent(eventFrame,"SPELL_DATA_LOAD_RESULT",id,true) end
    check(s.work.metadata==beforeMetadata and calls.apply==beforeApply and #s.timers==0,
        branch.." 1000 unrelated spell loads perform no discovery or repaint")
    fx.ResolveTheme(bar._fluxSchoolCast,data)
    check(s.work.metadata==beforeMetadata,branch.." unrelated loads preserve current metadata cache")
    eventFrame.scripts.OnEvent(eventFrame,"SPELL_DATA_LOAD_RESULT",133,true)
    eventFrame.scripts.OnEvent(eventFrame,"SPELL_DATA_LOAD_RESULT",133,true)
    check(calls.apply==beforeApply and #s.timers==1,branch.." related load repaints are deferred/coalesced")
    s.FlushTimers()
    check(calls.apply==beforeApply+1,branch.." related load refreshes only the matching cast once")
    beforeApply=calls.apply
    for i=1,50 do eventFrame.scripts.OnEvent(eventFrame,"SPELLS_CHANGED") end
    check(#s.timers==1 and calls.apply==beforeApply,branch.." 50 spellbook changes share one deferred refresh")
    s.FlushTimers()
    check(calls.apply==beforeApply+1,branch.." spellbook burst repaints a visible cast once")
    fx.Finish(bar);beforeApply=calls.apply
    eventFrame.scripts.OnEvent(eventFrame,"SPELLS_CHANGED");s.FlushTimers()
    check(calls.apply==beforeApply,branch.." metadata changes never re-style a finished cast")

    ns.CastBarSchools.Learn(585,2);ns.CastBarSchools.Learn(686,32)
    check(ns.CastBarSchools.Resolve(nil,"Ambiguous")==nil,branch.." ambiguous aliases remain guarded")
    s.metadata[585]={name="Clear Holy Name"}
    beforeMetadata=s.work.metadata
    eventFrame.scripts.OnEvent(eventFrame,"SPELL_DATA_LOAD_RESULT",585,true)
    check(s.work.metadata-beforeMetadata==1,branch.." loaded alias updates one ID rather than rescanning catalog")
    check(ns.CastBarSchools.Resolve(nil,"Clear Holy Name")==2 and ns.CastBarSchools.Resolve(nil,"Ambiguous")==32,
        branch.." incremental alias updates preserve and resolve ambiguity")
    bar:Hide()

    -- First cast can be unmapped/cold, with no renderer allocated yet.
    local cold,ce,cn=fixture(branch,{deferTimers=true})
    local cb=cold.NewBar("player")
    cold.metadata[990501]={name="Unfamiliar Spell",harmful=true};cold.cold[990501]=true
    cold.Cast("player",990501)
    check(cb:GetStatusBarTexture():GetAlpha()==1,branch.." first cold cast uses default before metadata")
    cold.metadata[990501].description="Deals 100 Fire and Frost damage."
    for _,frame in ipairs(cold.frames) do
        if frame.events.SPELL_DATA_LOAD_RESULT then frame.scripts.OnEvent(frame,"SPELL_DATA_LOAD_RESULT",990501,true) end
    end
    cold.FlushTimers()
    check(cb._fluxSchoolCast.visualMask==20 and cb:GetStatusBarTexture():GetAlpha()==0,
        branch.." data arrival themes first cold cast without an existing visual")
    cb:Hide()
end

-- Named combinations and future spells have no production ID prerequisites.
for _,branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"}) do
    local s,e,ns=fixture(branch)
    local bar=s.NewBar("player")
    for _,entry in ipairs({{3,"Holystrike"},{5,"Flamestrike"},{6,"Radiant"},{9,"Stormstrike"},
        {10,"Holystorm"},{12,"Volcanic"},{17,"Froststrike"},{18,"Holyfrost"},{20,"Frostfire"},{24,"Froststorm"},
        {33,"Shadowstrike"},{34,"Twilight"},{36,"Shadowflame"},{40,"Plague"},{48,"Shadowfrost"},
        {65,"Spellstrike"},{66,"Divine"},{68,"Spellfire"},{72,"Astral"},{80,"Spellfrost"},{96,"Spellshadow"},
        {28,"Elemental"},{84,"Chimeric"},{106,"Cosmic"},{62,"Chromatic"},{124,"Chaos"},
        {126,"all magic schools"},{127,"all seven schools"}}) do
        local id=1000000+entry[1]
        s.metadata[id]={name="Future ability",description="Deals 100 "..entry[2].." damage.",harmful=true}
        s.Cast("player",id)
        local theme,info=ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)
        check(info and info.mask==entry[1] and info.schoolMask==nil,branch.." school vocabulary: "..entry[2])
        local count=0
        for _,bit in ipairs({2,4,8,16,32,64}) do if math.floor(info.displayMask/bit)%2==1 then count=count+1 end end
        check(#theme.components==count,branch.." school composition retained for "..entry[2])
    end
    s.metadata[1100000]={name="New Chain Lightning",description="Deals 100 Nature damage.",harmful=true}
    local volcanic=ns.CastBarVisuals.Resolve({id=1000012,class="SHAMAN"},{})
    check(volcanic.profile=="volcanic" and volcanic.mask==12,branch.." Fire/Nature selects Volcanic without a spell list")
    s.metadata[1000012].name="Volcanic Test Cast";ns.CastBarVisuals.Invalidate(1000012)
    ns.CastBarSchools.Learn(1000012,12);s.Cast("player",1000012)
    local lava,school=ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)
    check(lava.school=="volcanic" and #lava.components==2 and lava.components[1].fx=="flames" and lava.components[2].fx=="rocks"
        and school.schoolMask==12 and school.mask==12,branch.." lava appearance preserves reported Fire/Nature school")
    for i=1,90 do s.Tick(1/60) end
    check(s.LiveParticles()>0 and s.LiveParticles()<=48,branch.." Volcanic emits bounded particles")
    local fire,rocks=false,false
    for _,tex in ipairs(s.textures) do
        if tex.rotation and tex:IsVisible() then
            fire=fire or tex.path:match("cast_flame$")~=nil
            rocks=rocks or tex.path:match("volcanic_rock$")~=nil
        end
    end
    check(fire and rocks,branch.." Volcanic displays both flames and rock fragments")
    s.GetDB().castBarThemes.spellVisuals=false;ns.CastBarThemes.Refresh()
    local base=ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)
    check(#base.components==2 and base.components[1].fx=="flames" and base.components[2].fx=="leaves",
        branch.." disabling spell-specific themes restores Fire/Nature base effects")
    s.GetDB().castBarThemes.spellVisuals=true
    s.Cast("player",1100000)
    local theme=ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)
    check(theme.components[1].fx=="lightning",branch.." new lightning ability needs no spell ID entry")
    s.GetDB().castBarThemes.lightningVisuals=false -- obsolete settings have no effect
    ns.CastBarThemes.Refresh()
    theme=ns.CastBarThemes.ResolveTheme(bar._fluxSchoolCast,s.GetDB().castBarThemes)
    check(theme.components[1].fx=="lightning",branch.." unified spell-specific setting keeps lightning")
    s.metadata[1100000].description="Deals 100 Cosmic damage."
    for _,f in ipairs(s.frames) do if f.events.SPELL_DATA_LOAD_RESULT then f.scripts.OnEvent(f,"SPELL_DATA_LOAD_RESULT",1100000,true) end end
    check(bar._fluxSchoolCast.visualMask==106,branch.." same ID adapts to changed client school metadata")
    s.metadata[1100001]={name="Flamestrike",description="Deals 100 Fire damage.",harmful=true}
    s.Cast("player",1100001)
    check(bar._fluxSchoolCast.visualMask==4,branch.." damage clause outranks a hybrid-like spell name")
    s.metadata[1100002]={name="Future ability",description="Absorbs damage from all magic schools.",helpful=true}
    check(ns.CastBarVisuals.Resolve({id=1100002,class="UNKNOWN"},{})==nil,branch.." all-school absorption is not offensive damage")
    s.metadata[1100003]={name="Observed Chaos Beam",description="Deals 100 Chaos damage.",harmful=true}
    ns.CastBarSchools.Learn(1100003,127);s.Cast("player",1100003)
    check(bar._fluxSchoolCast.visualMask==126 and bar._fluxSchoolCast.schoolMask==127 and bar._fluxSchoolCast.resolvedMask==127,branch.." Chaos shows six magic schools without changing reported school data")
    for i=1,90 do s.Tick(1/30) end
    check(s.LiveParticles()>0 and s.LiveParticles()<=48,branch.." six-school rainbow shares one particle pool")
    bar:Hide();check(s.VisibleDrivers()==0 and s.LiveParticles()==0,branch.." all-school cleanup sleeps")
    s.schoolNames={[124]="Chaos",[127]="Chaos",[126]="Magic"};ns.CastBarVisuals.Invalidate()
    s.metadata[1100004]={name="Future ability",description="Deals 100 Chaos damage.",harmful=true}
    s.Cast("player",1100004)
    check(bar._fluxSchoolCast.visualMask==126 and bar._fluxSchoolCast.resolvedMask==124,branch.." Chaos rainbow is an appearance separate from resolved school data")
    s.locale="frFR";s.metadata[1100005]={name="Nouvelle magie",description="Inflige 100 dégâts de Chaos.",harmful=true}
    ns.CastBarVisuals.Invalidate();s.Cast("player",1100005)
    check(bar._fluxSchoolCast.visualMask==126 and bar._fluxSchoolCast.resolvedMask==124,branch.." localized Chaos gets the same six-school appearance")
    s.locale="enUS";s.schoolNames={[124]="Chromatic"};ns.CastBarVisuals.Invalidate()
    s.metadata[1100006]={name="Future ability",description="Deals 100 Chromatic damage.",harmful=true}
    s.Cast("player",1100006)
    check(bar._fluxSchoolCast.visualMask==124,branch.." native legacy Chromatic label needs no client spell exception")
    s.schoolNames=nil;ns.CastBarVisuals.Invalidate();s.Cast("player",133)
    local visuals
    for i=1,30 do
        local name,value=debug.getupvalue(ns.CastBarThemes.Update,i)
        if name=="visuals" then visuals=value;break end
        if not name then break end
    end
    ns.CastBarThemes.Update(bar,0.1)
    local first=visuals[bar].pool[1]
    local c0,c1=first.c0,first.c1
    for i=1,100 do ns.CastBarThemes.Update(bar,0.1) end
    check(first.c0==c0 and first.c1==c1,branch.." pooled particles reuse immutable color tables")
    bar:Hide()
    s.Cast("player",1510)
    local expected
    if branch~="live" and branch~="classic" then expected=64 end
    check(bar._fluxSchoolCast.visualMask==expected,branch.." client differences come from current metadata")
    bar:Hide()
    local learned=ns.CastBarSchools
    for i=1,2050 do learned.Learn(2000000+i,4) end
    check(learned.Resolve(2000001)==nil and learned.Resolve(2002050)==4,branch.." observed cache evicts old entries incrementally")
end

-- Native animations and a single composite fill must remain lazy, bounded,
-- independent of secret progress, and much cheaper in Lua than per-frame moves.
local lastNativeWrites,lastFallbackWrites
local function getVisuals(fx)
    for i=1,30 do local key,value=debug.getupvalue(fx.Update,i);if key=="visuals" then return value end;if not key then break end end
    error("renderer state not found")
end
for _,branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"}) do
    local costs={}
    for _,native in ipairs({false,true}) do
        local s,e,ns=fixture(branch,{nativeParticles=native})
        check(#s.animations==0,branch.." login loads no particle animation groups")
        local bar=s.NewBar("player")
        local data=s.GetDB().castBarThemes
        data.halo=false;data.edge=false;data.backdrop=false;data.density=200
        s.metadata[3100000]={name="Future destruction beam",description="Deals 100 Chaos damage.",harmful=true}
        s.Cast("player",3100000)
        local v=getVisuals(ns.CastBarThemes)[bar]
        s.spriteParent=v.particles
        check(#v.pool==0,branch.." cast setup allocates no particle pool up front")
        check(v.fill.path:find("Fills\\fill_",1,true) and #v.layers==1,branch.." Chaos uses one fill region")
        bar.TimerBar.value=s.secret
        for i=1,240 do s.Tick(1/120) end
        costs[native and "native" or "fallback"]=s.work.spriteWrites
        check(v.liveParticles>0 and #v.pool<=48,branch.." animation path stays within pool budget")
        local textureWrites,gradients=s.work.textures,s.work.gradients
        for i=1,50 do ns.CastBarThemes.Apply(bar) end
        check(s.work.textures==textureWrites and s.work.gradients==gradients,branch.." unchanged refreshes do not rebuild/repaint artwork")
        if native then
            check(v.luaParticles==0 and v.pool[1].group,branch.." native engine owns particle motion/color/fading")
            local writes=s.work.spriteWrites
            ns.CastBarThemes.Finish(bar)
            check(s.VisibleDrivers()==0 and v.liveParticles>0,branch.." native particle tail needs no Lua driver")
            for i=1,240 do s.Tick(1/120) end
            check(v.liveParticles==0 and s.work.spriteWrites==writes,branch.." native tail finishes without Lua texture updates")
        end
        bar:Hide()
        check(s.VisibleDrivers()==0 and v.liveParticles==0,branch.." animation cleanup stops immediately")
        for _,group in ipairs(s.animations) do check(not group.playing,branch.." hidden particles leave no running native group")end
    end
    check(costs.native<costs.fallback*0.25,branch.." native particles cut Lua texture writes by over 75 percent")
    lastNativeWrites,lastFallbackWrites=costs.native,costs.fallback

    for _,unsupported in ipairs({{nativeParticles=true,badNativeAnimation=true},{nativeParticles=true,partialNativeAnimation=true}}) do
        local s,e,ns=fixture(branch,unsupported)
        local bar=s.NewBar("player")
        s.Cast("player",133)
        for i=1,60 do s.Tick(1/60) end
        local v=getVisuals(ns.CastBarThemes)[bar]
        check(v.liveParticles>0 and v.luaParticles>0,branch.." missing/failed animation setup falls back without interrupting casting/login")
        bar:Hide()
    end

    -- Missing composite artwork retains the old portable masks, now in strict
    -- sublayer order. No same-priority alpha batching can discard later colors.
    local s,e,ns=fixture(branch,{noCompositeFills=true})
    local bar=s.NewBar("player")
    for _,mask in ipairs({106,124,126,127}) do
        ns.CastBarSchools.Learn(3100001,mask);s.Cast("player",3100001)
        local v=getVisuals(ns.CastBarThemes)[bar]
        for i=1,#v.theme.components do check(v.layers[i].sublevel==i-1 and v.layers[i]:IsVisible(),branch.." fallback composite has explicit draw order")end
    end
    bar:Hide()
    local s,e,ns=fixture(branch,{nativeParticles=true})
    local bar=s.NewBar("player")
    local data=s.GetDB().castBarThemes
    data.particles=false;data.halo=false;data.edge=false
    s.Cast("player",133)
    check(s.VisibleDrivers()==0,branch.." static backdrop alone has no animation driver")
    bar:Hide()
    local s,e,ns=fixture(branch,{nativeParticles=true})
    local bars={}
    for i,unit in ipairs({"player","target","focus","pet"}) do
        bars[i]=s.NewBar(unit)
        ns.CastBarSchools.Learn(3200000+i,({124,106,126,127})[i]);s.Cast(unit,3200000+i)
    end
    for i=1,120 do s.Tick(1/120) end
    check(s.VisibleDrivers()==1,branch.." simultaneous native bars share one birth/glow driver")
    local visuals=getVisuals(ns.CastBarThemes)
    for _,bar in ipairs(bars) do check(visuals[bar].luaParticles==0 and visuals[bar].liveParticles>0,branch.." simultaneous composites use native particle motion")end
    bars[1]:Hide()
    check(visuals[bars[1]].liveParticles==0 and visuals[bars[2]].liveParticles>0,branch.." one bar cleanup does not stop another bar")
    for i=2,4 do ns.CastBarThemes.Finish(bars[i]) end
    check(s.VisibleDrivers()==0,branch.." all native tails release the Lua driver immediately")
    for i=1,240 do s.Tick(1/120) end
    for _,bar in ipairs(bars) do check(visuals[bar].liveParticles==0,branch.." simultaneous native tails drain fully")end
end
print("Particle Lua texture writes over 2s: native="..lastNativeWrites..", fallback="..lastFallbackWrites.." (mock call counts, not native FPS)")

-- A forbidden call can be reported by WoW even when pcall catches it. Count
-- attempted calls as well as errors so a wrapper cannot hide a regression.
for _,branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"}) do
    local s,e,ns=fixture(branch)
    local fx=ns.CastBarThemes
    for _,unit in ipairs({"player","target","focus","pet"}) do s.NewBar(unit) end
    local restricted=s.combatLogRestricted
    check(s.combatLogCalls.register==(restricted and 0 or 1),branch.." startup subscribes only once when allowed")
    check(s.combatLogCalls.unregister==0,branch.." startup never unregisters an absent subscription")
    for i=1,3 do fx.Refresh() end
    check(s.combatLogCalls.register==(restricted and 0 or 1),branch.." repeated refresh does not resubscribe")
    local themeOptions=s.GetDB().castBarThemes
    themeOptions.enabled=false
    for i=1,3 do fx.Refresh() end
    check(s.combatLogCalls.unregister==(restricted and 0 or 1),branch.." disable cleans up only a permitted owned subscription")
    themeOptions.enabled=true;fx.Refresh()
    check(s.combatLogCalls.register==(restricted and 0 or 2),branch.." re-enable respects combat-log permission")
    for _,unit in ipairs({"player","target","focus","pet"}) do themeOptions[unit]=false end
    themeOptions.nameplates=false
    fx.Refresh();fx.Refresh()
    check(s.combatLogCalls.unregister==(restricted and 0 or 2),branch.." all unit toggles disabled detach once")
end

-- Capability snapshots can be stale or incomplete. A runtime restriction,
-- failed query, missing API, or inaccessible result must skip both methods.
for _,capabilities in ipairs({{combatLogRestricted=true},{restrictionQueryFails=true},{restrictionQuerySecret=true}}) do
    local s,e,ns=fixture("classic_era",capabilities)
    s.NewBar("player")
    ns.CastBarThemes.Refresh()
    s.GetDB().castBarThemes.enabled=false
    ns.CastBarThemes.Refresh()
    check(s.combatLogCalls.register==0 and s.combatLogCalls.unregister==0,"unavailable combat log never touches the restricted event")
end
do
    local s,e,ns=fixture("live")
    ns.Flux.Cap.hasCombatLogUnfiltered=true
    s.combatLogRestricted=false
    s.NewBar("player")
    s.GetDB().castBarThemes.enabled=false;ns.CastBarThemes.Refresh()
    check(s.combatLogCalls.register==0 and s.combatLogCalls.unregister==0,
        "Live skips event methods even with stale capability and false runtime restriction")
end
do
    local s,e,ns=fixture("classic_era",{rejectCombatLogRegistration=true})
    s.NewBar("player")
    s.GetDB().castBarThemes.enabled=false
    ns.CastBarThemes.Refresh()
    check(s.combatLogCalls.register==1 and s.combatLogCalls.unregister==0,"failed registration never produces an owned subscription")
end
do
    local s,e,ns=fixture("classic_era")
    s.NewBar("player")
    local eventFrame
    for _,frame in ipairs(s.frames) do if frame.events.COMBAT_LOG_EVENT_UNFILTERED then eventFrame=frame;break end end
    check(eventFrame~=nil,"unrestricted combat-log listener attached")
    eventFrame.scripts.OnEvent(eventFrame,"COMBAT_LOG_EVENT_UNFILTERED")
    check(s.combatLogCalls.read==1,"permitted combat-log callback reads its payload")
    s.combatLogRestricted=true
    s.GetDB().castBarThemes.enabled=false
    ns.CastBarThemes.Refresh()
    eventFrame.scripts.OnEvent(eventFrame,"COMBAT_LOG_EVENT_UNFILTERED")
    check(s.combatLogCalls.unregister==0 and s.combatLogCalls.read==1,"new restrictions skip cleanup and queued data reads")
    s.combatLogRestricted=false
    ns.CastBarThemes.Refresh()
    check(s.combatLogCalls.unregister==1,"deferred cleanup runs once permission returns")
    s.GetDB().castBarThemes.enabled=true
    ns.CastBarThemes.Refresh()
    ns.Flux.Cap.hasCombatLogUnfiltered=false
    s.GetDB().castBarThemes.enabled=false
    ns.CastBarThemes.Refresh()
    eventFrame.scripts.OnEvent(eventFrame,"COMBAT_LOG_EVENT_UNFILTERED")
    check(s.combatLogCalls.unregister==1 and s.combatLogCalls.read==1,"capability loss skips cleanup and queued reads")
    ns.Flux.Cap.hasCombatLogUnfiltered=true
    ns.CastBarThemes.Refresh()
    check(s.combatLogCalls.unregister==2,"capability restoration allows owned cleanup")
end
for _,missing in ipairs({"capability","reader"}) do
    local s,e,ns=fixture("classic_era")
    if missing=="capability" then ns.Flux.Cap=nil else e.CombatLogGetCurrentEventInfo=false end
    s.NewBar("player")
    s.GetDB().castBarThemes.enabled=false;ns.CastBarThemes.Refresh()
    check(s.combatLogCalls.register==0 and s.combatLogCalls.unregister==0,"missing "..missing.." skips event methods")
end
do
    local s,e,ns=fixture("classic_era")
    e.C_CombatLog=false -- Older clients have no restriction-query namespace.
    s.NewBar("player")
    s.GetDB().castBarThemes.enabled=false;ns.CastBarThemes.Refresh()
    check(s.combatLogCalls.register==1 and s.combatLogCalls.unregister==1,"legacy capability supports ordinary subscription cleanup")
end

-- Start each school with a fresh particle pool. Animating only Fire first can
-- hide uninitialized fields that other emitters inherit from reused flames.
for _, branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"}) do
    for _, school in ipairs({
        {"arcane",5143}, {"shadow",686}, {"holy",2061}, {"nature",5176},
        {"frost",116}, {"frostfire",44614}, {"fire",133}, {"spellfrost",356995}, {"shadowflame",264178},
    }) do
        local s,e,ns=fixture(branch)
        for _,unit in ipairs({"player","target","focus","pet"}) do
            s.NewBar(unit)
            s.Cast(unit,school[2])
        end
        for i=1,60 do s.Tick(1/60) end
        local expectedAspect=school[1]=="fire" and 1.2 or
            ((school[1]=="frostfire" or school[1]=="shadowflame") and {cast_flame=1.2} or 1)
        checkParticleGeometry(s,expectedAspect,branch.." "..school[1].." fresh pools on all four bars")
        for _,frame in ipairs({ns.PlayerFrame,ns.TargetFrame,ns.FocusFrame,ns.PetFrame}) do frame.CastBar:Hide() end
        check(s.LiveParticles()==0 and s.VisibleDrivers()==0,branch.." "..school[1].." particle cleanup")
    end

    -- Exercise the same production driver through recasts, channels and pool
    -- reuse; a fresh-allocation-only check would miss stale flame aspect.
    local s,e,ns=fixture(branch)
    local bar=s.NewBar("player")
    for _,school in ipairs({{133,1.2},{116,1},{133,1.2},{686,1},{133,1.2},{2061,1},
        {133,1.2},{5176,1},{133,1.2},{5143,1},{133,1.2},{44614,{cast_flame=1.2}}}) do
        s.Cast("player",school[1],school[1]==5143)
        for i=1,60 do s.Tick(1/60) end
        checkParticleGeometry(s,school[2],branch.." pooled switch to "..school[1])
    end
    bar:Hide()
    check(s.VisibleDrivers()==0,branch.." reused pool stops after hide")

    -- Capability fallbacks are independent of the product/version flags.
    for _,capabilities in ipairs({{gradient="legacy",noAtlas=true,noCompositeFills=true},{gradient="solid",noAtlas=true,noClip=true,noCompositeFills=true}}) do
        local s,e,ns=fixture(branch,capabilities)
        local bar=s.NewBar("player")
        s.Cast("player",686)
        for i=1,60 do s.Tick(1/60) end
        checkParticleGeometry(s,1,branch.." "..capabilities.gradient.." API fallback")
        check(bar:GetStatusBarTexture():GetAlpha()==0,branch.." fallback themed fill")
        ns.CastBarSchools.Learn(990200,28);s.Cast("player",990200)
        local painted={}
        for _,tex in ipairs(s.textures) do
            if tex:IsVisible() and type(tex.path)=="string" and tex.path:find("hybrid_",1,true) then
                if tex.gradient then
                    local c=tex.gradient
                    painted[tostring(c[2])..":"..tostring(c[3])..":"..tostring(c[4])]=true
                    painted[tostring(c[6])..":"..tostring(c[7])..":"..tostring(c[8])]=true
                else
                    local c=tex.color
                    painted[tostring(c[1])..":"..tostring(c[2])..":"..tostring(c[3])]=true
                end
            end
        end
        local count=0;for _ in pairs(painted) do count=count+1 end
        check(count>=3,branch.." "..capabilities.gradient.." fallback preserves all three school colors")
        bar:Hide()
        check(s.VisibleDrivers()==0 and s.LiveParticles()==0,branch.." fallback cleanup")
    end
end

for _, branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"}) do
    local s,e,ns = fixture(branch)
    local schools,fx = ns.CastBarSchools,ns.CastBarThemes
    check(schools.Resolve(133)==nil and schools.Resolve(356995)==nil and schools.Resolve(1510)==nil,
        branch.." no spell ID has a built-in school")
    schools.Learn(133,4);schools.Learn(143,4);schools.Learn(585,2);schools.Learn(686,32)
    check(schools.Resolve(nil,"Boule de feu")==4, branch.." localized rank alias")
    check(schools.Resolve(nil,"Ambiguous")==nil, branch.." ambiguous aliases fail closed")
    check(schools.Resolve(133,nil,true)==nil and schools.Resolve(8690)==nil, branch.." profession and hearth fallback")
    check(schools.Resolve(s.secret,s.secret)==nil and schools.Resolve(133,nil,s.secret)==nil, branch.." secret identity fallback")
    local frostfire=fx.ThemeForMask(20)
    check(#frostfire.components==2 and frostfire.components[1].fx=="flames" and frostfire.components[2].fx=="snow","Frostfire combines fire and frost effects")
    check(#fx.ThemeForMask(80).components==2 and fx.ThemeForMask(1)==nil,"all hybrid components / physical fallback")
    check(fx.ThemeForMask(72).components[1].dark[1]==0.43 and fx.ThemeForMask(72).components[2].dark[1]==0.10,"hybrid colors retain their base palettes")
    local player=s.NewBar("player"); local target=s.NewBar("target"); local focus=s.NewBar("focus"); local pet=s.NewBar("pet")
    local function reset() for _,bar in ipairs({player,target,focus,pet}) do bar:Hide() end end
    s.Cast("player",133)
    check(player:GetStatusBarTexture():GetAlpha()==0 and s.claimed>0, "themed fill / swing slot claim")
    local playerVisual=getVisuals(fx)[player]
    check(playerVisual.fill.parent==player.TimerBar,
        branch.." school fill shares the actual unit-frame progress bar")
    check(player.Spark.color[1]==playerVisual.theme.bright[1]
        and player.Spark.color[2]==playerVisual.theme.bright[2]
        and player.Spark.color[3]==playerVisual.theme.bright[3],
        branch.." native unit-frame tip spark matches school color")
    check(s.VisibleDrivers()==1, "one animation driver")
    local writes=player.TimerBar.manualWrites; local values=player.TimerBar.valueWrites
    fx.Update(player,0.1)
    check(player.TimerBar.manualWrites==writes and player.TimerBar.valueWrites==values, "visuals never change timers")
    local data=s.GetDB().castBarThemes
    data.colors=false; fx.Refresh()
    check(player:GetStatusBarTexture():GetAlpha()==1 and s.VisibleDrivers()==1,
        "fill toggle independent of particles/glow")
    check(player.Spark.color[1]==1 and player.Spark.color[2]==1 and player.Spark.color[3]==1,
        branch.." disabling fill colors restores native tip spark")
    data.particles=false; data.halo=false; data.edge=false; data.backdrop=false; fx.Refresh()
    check(s.VisibleDrivers()==0, "static/disabled effects have no animation driver")
    data.colors=true; fx.Refresh()
    check(player:GetStatusBarTexture():GetAlpha()==0 and s.VisibleDrivers()==0, "colors alone remain engine anchored")
    data.enabled=false; fx.Refresh()
    check(player:GetStatusBarTexture():GetAlpha()==1, "master toggle restores fill")
    data.enabled=true; data.particles=true; data.halo=true; data.edge=true; data.backdrop=true
    data.player=false; fx.Refresh()
    check(player:GetStatusBarTexture():GetAlpha()==1, "per-unit toggle")
    data.player=true; fx.Refresh()
    check(player:GetStatusBarTexture():GetAlpha()==0, "live re-enable")
    s.SetDB({castBarThemes={enabled=false}}); fx.Refresh()
    check(player:GetStatusBarTexture():GetAlpha()==1, "scope switch restores baseline")
    s.SetDB({castBarThemes={}}); fx.Refresh()
    s.Cast("target",116,true); s.Cast("focus",5143,true); s.Cast("pet",686)
    for _, bar in ipairs({player,target,focus,pet}) do check(bar:GetStatusBarTexture():GetAlpha()==0,"simultaneous unit themes") end
    s.Cast("player",133,nil,true)
    check(player:GetStatusBarTexture():GetAlpha()==1, "profession replacement clears previous theme")
    s.Cast("player",133); s.Cast("player",987654321)
    check(player:GetStatusBarTexture():GetAlpha()==1, "unknown replacement clears previous theme")
    fx.ObserveCast("wrong-guid",987654321,4,"SPELL_CAST_START")
    check(player:GetStatusBarTexture():GetAlpha()==1,"unmatched source cannot repaint")
    fx.ObserveCast("guid-player",987654321,16,"SPELL_CAST_START")
    check(player:GetStatusBarTexture():GetAlpha()==0,"matching combat log themes unknown current spell")
    fx.ObserveCast("guid-target",987654322,32,"SPELL_CAST_START")
    s.Cast("target",987654322)
    check(target:GetStatusBarTexture():GetAlpha()==0,"CLEU before UNIT start is learned")
    fx.ObserveCast("guid-player",987654321,s.secret,"SPELL_CAST_START")
    check(schools.Resolve(987654321)==16,"secret learned mask rejected")
    s.Cast("player",133)
    s.Event(player,"UNIT_SPELLCAST_INTERRUPTED","player","cast-1",133)
    check(player._fluxSchoolCast==nil and player:GetStatusBarTexture():GetAlpha()==1,"interrupt restores default red feedback")
    s.Cast("player",133)
    s.Event(player,"UNIT_SPELLCAST_STOP","player","cast-1",133)
    check(player._fluxSchoolCast and player._fluxSchoolCast.finished and player:GetStatusBarTexture():GetAlpha()==0,"successful hold remains themed")
    s.Cast("player",133)
    ns.CastBar.StartCustomTimer(player,{duration=5,kind="flight"})
    check(player._fluxSchoolCast==nil and player.customTimer and player:GetStatusBarTexture():GetAlpha()==1,"flight timer clears school")
    ns.CastBar.StopCustomTimer(player)
    check(s.released>0,"custom timer releases swing slot")
    s.Cast("pet",686); pet:DisablePetCastBar()
    check(pet._fluxSchoolCast==nil and pet:GetStatusBarTexture():GetAlpha()==1,"pet disable cleanup")
    pet:RegisterPetCastEvents()
    s.Cast("player",357208,true,false,3)
    check(player.isEmpowered and player.StageTiers[1].Normal.desaturated,"empowered stages retain geometry with school tint")
    fx.Reset(player,true)
    check(not player.StageTiers[1].Normal.desaturated,"empower tier tint restored")
    s.Cast("player",133)
    local castState=player._fluxSchoolCast
    local min,max,val=player.TimerBar.low,player.TimerBar.high,player.TimerBar.value
    player.TimerBar.low=s.secret; player.TimerBar.high=s.secret; player.TimerBar.value=s.secret
    fx.Update(player,0.1)
    check(player._fluxSchoolCast==castState,"secret progress keeps identity and uses native clipping")
    player.TimerBar.low,player.TimerBar.high,player.TimerBar.value=min,max,val
    s.GetDB().castBarThemes.density=200
    for i=1,180 do fx.Update(player,0.1) end
    check(s.LiveParticles()<=48*4,"bounded particle pool")
    reset()
    check(s.VisibleDrivers()==0 and s.LiveParticles()==0,"all hidden means zero active animation work")
    check(player:GetStatusBarTexture():GetAlpha()==1,"hidden bar restores native texture alpha")

    local optionsBuilder
    e.FluxOptions.RegisterModuleOptions = function(_, key, builder)
        if key == "unitframes" then optionsBuilder = builder end
    end
    loadAddon("AddonOptions/FluxOptionsUnitFrames.lua",e,ns)
    local loader=s.frames[#s.frames]
    loader.scripts.OnEvent(loader,"ADDON_LOADED","_FluxUI")
    local options=optionsBuilder().args.castBarThemes.args
    options.enabled.set(nil,true)
    options.colors.set(nil,false)
    check(options.gradient.disabled() and not options.particles.disabled(),"gradient depends on colors without disabling other effects")
    options.density.set(nil,175)
    check(s.GetDB().castBarThemes.density==175,"intensity saved in current unit-frame scope")
    options.player.set(nil,false)
    options.reset.func()
    check(options.player.get() and options.nameplates.get() and options.colors.get() and options.density.get()==100,
        "school-theme reset restores unit and Blizzard-nameplate defaults")
    options.enabled.set(nil,false)
    check(options.pet.disabled() and not options.enabled.disabled(),"master disables subordinate controls")
    loadAddon("AddonOptions/FluxOptionsDefaults.lua",e,ns)
    local defaults=e.FluxOptionsDefaults
    check(defaults.profile.unitFrames.castBarThemes.nameplates and defaults.char.unitFrames.castBarThemes.nameplates,
        "Blizzard nameplates enabled in both settings scopes")
    check(defaults.profile.unitFrames.castBarThemes.enabled and defaults.char.unitFrames.castBarThemes.enabled,"defaults in both settings scopes")
    check(defaults.profile.unitFrames.castBarThemes~=defaults.char.unitFrames.castBarThemes,"settings scopes do not share a theme table")
    options.reset.func()
    check(options.lightningVisuals==nil and options.spellVisuals.get(),"lightning is part of spell-specific themes")
    options.spellVisuals.set(nil,false)
    check(not options.spellVisuals.get(),"single toggle controls spell-specific effects")
    options.inferVisuals.set(nil,false)
    check(not options.inferVisuals.get(),"inference is independently optional")
    options.reset.func()
    check(options.spellVisuals.get() and options.inferVisuals.get(),"reset restores visual detection defaults")
end

-- Every emitted texture is available locally, including on atlas-free clients.
for _,branch in ipairs({"live","forever","classic_era","classic_anniversary"}) do
    local s,e,ns=fixture(branch)
    local native=e.CreateFrame("StatusBar",nil,e.UIParent)
    native:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    native.Spark=native:CreateTexture()
    native.Spark:SetVertexColor(0.2,0.3,0.4,0.8)
    local proxy=e.CreateFrame("Frame",nil,e.UIParent)
    proxy.TimerBar=native
    proxy._fluxNativeCast=native
    proxy._fluxSchoolNameplate=true
    proxy.casting=true
    proxy:SetAllPoints(native)
    local fx=ns.CastBarThemes
    fx.Attach(proxy)
    fx.Begin(proxy,"nameplate1",133,"Boule de feu",false,nil,true)
    local v=getVisuals(fx)[proxy]
    check(v and v.theme and v.fill.parent==native,branch.." nameplate paints native bar with shared theme")
    check(native:GetStatusBarTexture():GetAlpha()==0,branch.." nameplate hides native fill under school fill")
    check(native.Spark.color[1]==v.theme.bright[1] and native.Spark.color[2]==v.theme.bright[2]
        and native.Spark.color[3]==v.theme.bright[3],branch.." nameplate tip spark matches school color")
    fx.Update(proxy,0.1)
    check(proxy._fluxSchoolCast and proxy._fluxSchoolCast.nameplate,branch.." nameplate animation uses native progress")
    s.GetDB().castBarThemes.nameplates=false;fx.Refresh()
    check(not v.fill:IsShown() and native:GetStatusBarTexture():GetAlpha()==1
        and native.Spark.color[1]==0.2 and native.Spark.color[2]==0.3
        and native.Spark.color[3]==0.4 and native.Spark.color[4]==0.8,
        branch.." nameplate toggle restores native appearance")
    s.GetDB().castBarThemes.nameplates=true;fx.Refresh()
    check(v.fill:IsShown() and native:GetStatusBarTexture():GetAlpha()==0,
        branch.." nameplate toggle restores school appearance")
    native:Hide();fx.Update(proxy,0.1)
    check(proxy._fluxSchoolCast==nil and not v.fill:IsShown()
        and native:GetStatusBarTexture():GetAlpha()==1 and native.Spark.color[1]==0.2
        and native.Spark.color[4]==0.8,
        branch.." hidden native bar restores Blizzard fill and tip")
end

local files={"cast_dot","cast_flame","cast_leaf","cast_snow","cast_spark","arcane_rune","shadow_skull",
    "lightning_bolt","volcanic_rock",
    "backdrop_magearcane","backdrop_paladin","backdrop_frost","backdrop_warlock","backdrop_priestshadow",
    "backdrop_priest","backdrop_druid","backdrop_shaman","backdrop_hunter"}
files[#files+1]="hybrid_base"
for count=2,6 do for layer=2,count do files[#files+1]="hybrid_"..count.."_"..layer end end
local masks={}
for _,name in ipairs(files) do
    local file=assert(io.open("Texture/CastBarSchools/"..name..".tga","rb"))
    local raw=file:read("*a");file:close()
    local format=raw:byte(3);local width=raw:byte(13)+raw:byte(14)*256
    local height=raw:byte(15)+raw:byte(16)*256;local depth=raw:byte(17)
    check((format==2 or format==10) and depth==32,"portable 32-bit TGA: "..name)
    local function powerOfTwo(value) while value>1 and value%2==0 do value=value/2 end;return value==1 end
    check(powerOfTwo(width) and powerOfTwo(height),"power-of-two dimensions: "..name)
    if format==2 then check(#raw>=18+width*height*4,"complete TGA pixels: "..name) end
    if name:find("hybrid_",1,true) then masks[name]={raw=raw,width=width,height=height} end
end
-- Composite packaged masks at actual pixel sizes, through all six magic schools.
for count=2,6 do
    for _,width in ipairs({8,24,64,360}) do for _,height in ipairs({8,14,22,40}) do
        local peaks,soft={},false
        for y=0,height-1 do for x=0,width-1 do
            local weights={1}
            for layer=2,count do
                local mask=masks["hybrid_"..count.."_"..layer]
                local mx=math.min(mask.width-1,math.floor((x+0.5)/width*mask.width))
                local my=math.min(mask.height-1,math.floor((y+0.5)/height*mask.height))
                local alpha=mask.raw:byte(18+(my*mask.width+mx)*4+4)/255
                for previous=1,layer-1 do weights[previous]=weights[previous]*(1-alpha) end
                weights[layer]=alpha
                if alpha>0.1 and alpha<0.9 then soft=true end
            end
            for school,value in ipairs(weights) do peaks[school]=math.max(peaks[school] or 0,value) end
        end end
        for school=1,count do check(peaks[school]>0.65,"hybrid "..count.." keeps school "..school.." at "..width.."x"..height) end
        check(soft,"soft transitions at "..width.."x"..height)
    end end
end
-- Six unchanged base palettes/emitters, with only Lightning as an exception.
do
    local s,e,ns=fixture("live")
    local fx=ns.CastBarThemes
    local original={
        fire={{.70,.16,.02},{1,.62,.12},"flames"},frost={{.10,.34,.72},{.55,.86,1},"snow"},
        arcane={{.43,.28,.69},{.80,.62,.96},"shimmer"},shadow={{.09,.03,.13},{.42,.20,.55},"skulls"},
        holy={{.78,.56,.16},{1,.95,.66},"motes"},nature={{.10,.42,.08},{.56,.95,.30},"leaves"},
    }
    local rainbow=fx.ThemeForMask(124,"chaos")
    check(rainbow.mask==126 and #rainbow.components==6,"Chaos is the six-base-school rainbow")
    for _,component in ipairs(rainbow.components) do
        local expected=assert(original[component.school],"unexpected derived Chaos theme")
        check(component.fx==expected[3],"Chaos retains base "..component.school.." particles")
        for i=1,3 do check(component.dark[i]==expected[1][i] and component.bright[i]==expected[2][i],"original "..component.school.." fill colors retained")end
    end
    for _,profile in ipairs({"school","storm","cosmic","prismatic","fel","blood","water","earth","poison","solar","lunar","jade","holyfire","lightning"}) do
        local mixed=fx.ThemeForMask(12,profile)
        check(#mixed.components==2 and mixed.components[1].school=="fire" and mixed.components[2].school=="nature"
            and mixed.components[1].fx=="flames" and mixed.components[2].fx=="leaves","Fire/Nature always combines its two base themes")
    end
    check(fx.ThemeForMask(8,"lightning").components[1].fx=="lightning","single-school lightning keeps its electric effect")
    check(fx.ThemeForMask(3).components[1].school=="holy" and #fx.ThemeForMask(3).components==1 and fx.ThemeForMask(1)==nil,
        "Physical adds no new colors or particles")
    ns.CastBarSchools.Learn(4100000,124)
    s.metadata[4100000]={name="Future ability",description="Deals 100 Chaos damage.",harmful=true}
    local theme,info=fx.ResolveTheme({id=4100000,class="WARLOCK"},{})
    check(theme.mask==126 and info.mask==124 and info.schoolMask==124,"Chaos appearance does not modify actual school data")
end

-- Compare both baked variants with the original palette/mask compositing.
do
    local s,e,ns=fixture("live")
    local seen,count={},0
    for mask=2,127 do for _,profile in ipairs({"school","lightning","chaos","volcanic"}) do
        local theme=ns.CastBarThemes.ThemeForMask(mask,profile~="school" and profile or nil)
        if theme.fillPath then
            for _,flat in ipairs({false,true}) do
                local path=flat and theme.flatFillPath or theme.fillPath
                if not seen[path] then
                    seen[path]=true;count=count+1
                    local relative=path:sub(#"Interface\\AddOns\\_FluxUI\\"+1):gsub("\\","/")..".tga"
                    local file=assert(io.open(relative,"rb"),"missing original-palette fill: "..relative)
                    local raw=file:read("*a");file:close()
                    check(raw:byte(3)==2 and raw:byte(17)==32 and #raw==18+128*32*4,"complete original-palette fill")
                    for _,y in ipairs({0,8,16,24,31}) do for _,x in ipairs({0,17,43,79,108,127}) do
                        local expected={0,0,0}
                        local my=math.floor((y+.5)*128/32)
                        local offset=18+(my*128+x)*4+1
                        local progress=flat and 1 or (x+.5)/128
                        for i,component in ipairs(theme.components) do
                            local reference=masks[i==1 and "hybrid_base" or "hybrid_"..#theme.components.."_"..i].raw
                            local shade=reference:byte(offset)/255
                            local alpha=reference:byte(offset+3)/255
                            for channel=1,3 do
                                local original=component.dark[channel]+(component.bright[channel]-component.dark[channel])*progress
                                expected[channel]=expected[channel]*(1-alpha)+original*shade*alpha
                            end
                        end
                        local pixel=18+(y*128+x)*4+1
                        local b,g,r=raw:byte(pixel,pixel+2)
                        check(math.max(math.abs(r/255-expected[1]),math.abs(g/255-expected[2]),math.abs(b/255-expected[3]))<.015,
                            "baked colors match original "..(flat and "flat" or "gradient").." school palettes")
                    end end
                end
            end
        end
    end end
    check(count==116,"57 base-school blends plus fire/rock, with gradient and flat variants, are bundled")
    print("Validated "..count.." fills against original base-school palette compositing")
end
print("PASS cast-bar school themes: "..checks.." checks across five client families (native rendering/taint unverified)")
