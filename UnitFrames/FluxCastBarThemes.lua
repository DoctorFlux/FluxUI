-- School palettes and particle motion adapted from SiegeUI_CastBar 0.28 (Siege).
-- Flux owns every frame and cast lifecycle; this module only paints visuals.
local _, ns = ...
local FX = {}
ns.CastBarThemes = FX
local Schools = ns.CastBarSchools
local SpellVisuals = ns.CastBarVisuals
local MEDIA = 'Interface\\AddOns\\_FluxUI\\Texture\\CastBarSchools\\'
local function rnd(a, b) return a + math.random() * (b - a) end
local THEMES = {
  fire = { dark = { 0.70, 0.16, 0.02 }, bright = { 1, 0.62, 0.12 }, glow = { 1, 0.45, 0.08 }, fx = 'flames' },
  frost = { dark = { 0.10, 0.34, 0.72 }, bright = { 0.55, 0.86, 1 }, glow = { 0.45, 0.78, 1 }, fx = 'snow' },
  arcane = { dark = { 0.43, 0.28, 0.69 }, bright = { 0.80, 0.62, 0.96 }, glow = { 0.70, 0.48, 0.95 }, fx = 'shimmer' },
  shadow = { dark = { 0.09, 0.03, 0.13 }, bright = { 0.42, 0.20, 0.55 }, glow = { 0.38, 0.14, 0.52 }, fx = 'skulls' },
  holy = { dark = { 0.78, 0.56, 0.16 }, bright = { 1, 0.95, 0.66 }, glow = { 1, 0.84, 0.42 }, fx = 'motes' },
  nature = { dark = { 0.10, 0.42, 0.08 }, bright = { 0.56, 0.95, 0.30 }, glow = { 0.45, 0.90, 0.28 }, fx = 'leaves' },
  lightning = {dark={0.08,0.22,0.60},bright={0.65,0.90,1},glow={0.25,0.65,1},fx='lightning',backdropSchool='nature',backdropArt='shaman'},
  rock = {dark={0.20,0.12,0.07},bright={0.58,0.37,0.20},glow={0.52,0.28,0.10},fx='rocks',backdropSchool='fire'},
}

for school, theme in pairs(THEMES) do theme.school = school end

local EMITTERS = {
  rocks = {tex='volcanic_rock',blend='BLEND',rate=5,spawn=function(p,w)
    p.x,p.y=rnd(0,w),rnd(-2,3);p.vx,p.vy=rnd(-4,4),rnd(8,14)
    p.life=rnd(0.9,1.4);p.size0,p.size1=rnd(7,11),5
    p.spin=rnd(-1.3,1.3);p.peak=0.95
  end},
  lightning = {tex='lightning_bolt',blend='ADD',rate=14,spawn=function(p,w)
    p.x,p.y=rnd(0,w),rnd(-3,3);p.vx,p.vy=rnd(-12,12),rnd(-4,10)
    p.life=rnd(0.12,0.28);p.size0,p.size1,p.aspect=rnd(18,28),12,0.75
    p.spin,p.twinkle=rnd(-0.3,0.3),rnd(0,6)
    p.peak = 1
  end},
  flames = {
    tex = 'cast_flame', blend = 'ADD', rate = 10,
    spawn = function(p, w)
      p.x, p.y = rnd(0, w), rnd(-3, 2)
      p.vx, p.vy = rnd(-4, 4), rnd(18, 34)
      p.life = rnd(0.45, 0.8)
      p.size0, p.size1, p.aspect = rnd(9, 12), 3, 1.2
      p.peak = 0.9
    end,
  },
  -- Snow: drifting down past the bar, swaying and turning.
  snow = {
    tex = 'cast_snow', blend = 'ADD', rate = 7,
    spawn = function(p, w)
      p.x, p.y = rnd(0, w), rnd(6, 12)
      p.vx, p.vy = rnd(-3, 3), rnd(-9, -4)
      p.life = rnd(1.2, 1.8)
      p.size0 = rnd(5, 8)
      p.size1 = p.size0
      p.spin, p.sway = rnd(-1.5, 1.5), rnd(2, 4)
      p.peak = 0.9
    end,
  },
  -- Small violet energy sparks rise gently above Arcane's fill.
  shimmer = {
    tex = 'cast_spark', blend = 'ADD', rate = 5,
    spawn = function(p, w)
      p.x, p.y = rnd(0, w), rnd(-3, 3)
      p.vx, p.vy = rnd(-3, 3), rnd(6, 12)
      p.life = rnd(0.7, 1.2)
      p.size0, p.size1 = rnd(5, 8), 2
      p.spin = rnd(-0.4, 0.4)
      p.peak = 0.8
    end,
  },
  -- Skulls: the Death Knight's blood rune skull, in Shadow's violet,
  -- rising slowly off the fill with a slight sway. (Soft dots, should the
  -- client not have it.)
  skulls = {
    atlases = { 'UF-DKRunes-Blood-SkullActive' },
    tex = 'shadow_skull', blend = 'ADD', rate = 3,
    spawn = function(p, w)
      p.x, p.y = rnd(0, w), rnd(-3, 3)
      p.vx, p.vy = rnd(-2, 2), rnd(5, 10)
      p.life = rnd(1, 1.5)
      p.size0 = rnd(10, 13)
      p.size1 = p.size0 * 1.1
      p.sway = rnd(1, 2)
      p.peak = 0.9
    end,
  },
  -- Wisps: dark smoke rising slowly and spreading.
  motes = {
    tex = 'cast_dot', blend = 'ADD', rate = 10,
    spawn = function(p, w)
      p.x, p.y = rnd(0, w), rnd(-4, 4)
      p.vx, p.vy = rnd(-2, 2), rnd(7, 14)
      p.life = rnd(1, 1.5)
      p.size0, p.size1 = 4, 2
      p.twinkle = rnd(0, 6)
      p.peak = 1
    end,
  },
  -- Leaves: lifting off and tumbling away on a breeze.
  leaves = {
    tex = 'cast_leaf', blend = 'BLEND', rate = 6,
    spawn = function(p, w)
      p.x, p.y = rnd(0, w), rnd(-2, 4)
      p.vx, p.vy = rnd(-2, 6), rnd(4, 9)
      p.life = rnd(1.2, 1.8)
      p.size0 = rnd(7, 9)
      p.size1 = p.size0
      p.spin, p.sway = rnd(-2, 2), rnd(3, 5)
      p.peak = 0.9
    end,
  },
}

-- Immutable shared palettes avoid new color tables on every particle reuse.
local PARTICLE_COLORS = {
  rocks = {{0.66,0.46,0.28},{0.38,0.23,0.13}},
  lightning = {{0.75,0.95,1}, {0.20,0.55,1}},
  flames = {{ 1, 0.85, 0.45 }, { 1, 0.2, 0.03 }},
  snow = {{ 0.85, 0.95, 1 }, { 0.85, 0.95, 1 }},
  shimmer = {{ 0.86, 0.70, 1 }, { 0.56, 0.37, 0.86 }},
  skulls = {{ 0.62, 0.38, 0.80 }, { 0.32, 0.12, 0.46 }},
  motes = {{ 1, 0.95, 0.7 }, { 1, 0.8, 0.4 }},
  leaves = {{ 0.55, 0.9, 0.3 }, { 0.3, 0.65, 0.15 }},
}
for name,colors in pairs(PARTICLE_COLORS) do
    EMITTERS[name].c0,EMITTERS[name].c1=colors[1],colors[2]
    EMITTERS[name].path=MEDIA..EMITTERS[name].tex
end

local colorObjects=setmetatable({},{__mode="k"})
local function nativeColor(rgb)
    local color=colorObjects[rgb]
    if not color then color=CreateColor(rgb[1],rgb[2],rgb[3],1);colorObjects[rgb]=color end
    return color
end

local nativeParticles
local function createNativeParticle(v,p)
    if nativeParticles==false or not p.tex.CreateAnimationGroup then return end
    local group
    local ok=pcall(function()
        group=p.tex:CreateAnimationGroup()
        local move=group:CreateAnimation("Translation")
        local fadeIn=group:CreateAnimation("Alpha")
        local fadeOut=group:CreateAnimation("Alpha")
        local function requireMethods(object,methods)
            for _,name in ipairs(methods) do
                if type(object[name])~="function" then error("animation API unavailable") end
            end
        end
        requireMethods(group,{"SetScript","Play","Stop"})
        requireMethods(move,{"SetOrder","SetDuration","SetOffset"})
        requireMethods(fadeIn,{"SetOrder","SetDuration","SetFromAlpha","SetToAlpha"})
        requireMethods(fadeOut,{"SetOrder","SetDuration","SetStartDelay","SetFromAlpha","SetToAlpha"})
        move:SetOrder(1);fadeIn:SetOrder(1);fadeOut:SetOrder(1)
        p.move,p.fadeIn,p.fadeOut=move,fadeIn,fadeOut
        local function optional(kind,required,second)
            local success,animation=pcall(group.CreateAnimation,group,kind)
            if success and animation then
                requireMethods(animation,{"SetOrder","SetDuration",required})
                if second then requireMethods(animation,{second}) end
                animation:SetOrder(1);return animation
            end
        end
        p.resize=optional("Scale","SetScaleFrom","SetScaleTo")
        p.turn=optional("Rotation","SetRadians")
        if type(CreateColor)=="function" then p.colorAnimation=optional("VertexColor","SetStartColor","SetEndColor") end
        if group.SetToFinalAlpha then group:SetToFinalAlpha(true) end
        group:SetScript("OnFinished",function()
            if p.alive then p.alive=false;v.liveParticles=v.liveParticles-1;p.tex:Hide() end
        end)
    end)
    if ok then p.group=group;nativeParticles=true
    else
        if group and group.Stop then pcall(group.Stop,group) end
        nativeParticles=false
    end
end

local function playNativeParticle(v,p)
    local life=p.life
    p.tex:SetSize(p.size0,p.size0*p.aspect)
    p.tex:SetPoint("CENTER",v.particles,"LEFT",p.x,p.y)
    p.tex:SetRotation(p.spin and p.rot or 0)
    p.tex:SetAlpha(1)
    p.move:SetDuration(life);p.move:SetOffset(p.vx*life,p.vy*life)
    p.fadeIn:SetDuration(life*0.15);p.fadeIn:SetFromAlpha(0);p.fadeIn:SetToAlpha(p.peak)
    p.fadeOut:SetStartDelay(life*0.6);p.fadeOut:SetDuration(life*0.4)
    p.fadeOut:SetFromAlpha(p.peak);p.fadeOut:SetToAlpha(0)
    if p.resize then
        p.resize:SetDuration(life);p.resize:SetScaleFrom(1,1)
        local ratio=math.max(0.05,p.size1/p.size0)
        p.resize:SetScaleTo(ratio,ratio)
    end
    if p.turn then p.turn:SetDuration(life);p.turn:SetRadians((p.spin or 0)*life) end
    if p.colorAnimation then
        p.tex:SetVertexColor(1,1,1)
        p.colorAnimation:SetDuration(life)
        p.colorAnimation:SetStartColor(nativeColor(p.c0));p.colorAnimation:SetEndColor(nativeColor(p.c1))
    else p.tex:SetVertexColor(unpack(p.c0)) end
    p.tex:Show();p.group:Play()
end

local function lerp(a, b, t) return a + (b - a) * t end

local function stepParticles(v, dt)
  for _, p in ipairs(v.pool) do
    if p.alive and not p.group then
      p.age = p.age + dt
      local t = p.age / p.life
      if t >= 1 then
        p.alive = false
        v.liveParticles = v.liveParticles - 1
        v.luaParticles = v.luaParticles - 1
        p.tex:Hide()
      else
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        local x = p.x + (p.sway and math.sin(p.age * 3 + p.rot) * p.sway or 0)
        local size = p.pulse and p.size0 * math.sin(math.pi * t) or lerp(p.size0, p.size1, t)
        size = math.max(size, 0.5)
        if p.drawSize ~= size then
          p.drawSize = size
          p.tex:SetSize(size, size * p.aspect)
        end
        p.tex:SetPoint('CENTER', v.particles, 'LEFT', x, p.y)
        if p.spin then p.tex:SetRotation(p.rot + p.spin * p.age) end
        local c0, c1 = p.c0, p.c1 or p.c0
        p.tex:SetVertexColor(lerp(c0[1], c1[1], t), lerp(c0[2], c1[2], t), lerp(c0[3], c1[3], t))
        local alpha = p.peak * math.min(t / 0.15, 1) * math.min((1 - t) / 0.4, 1)
        if p.twinkle then alpha = alpha * (0.6 + 0.4 * math.sin(p.age * 18 + p.twinkle)) end
        p.tex:SetAlpha(alpha)
      end
    end
  end
end

local DEFAULTS = {
    enabled = true, player = true, target = true, focus = true, pet = true,
    colors = true, gradient = true, particles = true, halo = true, edge = true, backdrop = true,
    spellVisuals = true, inferVisuals = true,
    density = 100, glowOpacity = 100, backdropOpacity = 100,
}
FX.Defaults = DEFAULTS
local visuals, active, attached = {}, {}, {}
local driver, events
local animationElapsed = 0
local combatLogRegistered = false
local function settings()
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    return db and db.castBarThemes or DEFAULTS
end
local function enabled(db, key) return db[key] ~= false end
local function percent(db, key, maximum)
    return math.max(0, math.min(maximum, tonumber(db[key]) or DEFAULTS[key])) / 100
end

local ordered = {{4,"fire"}, {16,"frost"}, {64,"arcane"}, {32,"shadow"}, {2,"holy"}, {8,"nature"}}
local mixed = {}
function FX.ThemeForMask(mask,profile)
    mask=Schools.Plain(mask)
    if type(mask)~="number" or mask<1 or mask>127 or mask%1~=0 then return nil end
    -- Physical is not a magic theme. Chaos is deliberately a six-school
    -- appearance; its reported/estimated school mask stays separate.
    local displayMask=profile=="chaos" and 126 or mask-mask%2
    if displayMask==0 then return nil end
    local lightning=displayMask==8 and profile=="lightning"
    local volcanic=displayMask==12 and profile=="volcanic"
    local key=tostring(displayMask)..(lightning and ":lightning" or volcanic and ":volcanic" or ":school")
    if mixed[key] then return mixed[key] end
    if volcanic then
        local fire,rock=THEMES.fire,THEMES.rock
        local path=MEDIA.."Fills\\fill_base_fire_rock"
        local result={mask=displayMask,school="volcanic",fx=fire.fx,dark=fire.dark,bright=rock.bright,glow=fire.glow,
            components={fire,rock},rate=EMITTERS.flames.rate*1.5,fillPath=path,flatFillPath=path.."_flat"}
        mixed[key]=result
        return result
    end
    local components,names={},{}
    local rate=0
    for _,entry in ipairs(ordered) do
        if math.floor(displayMask/entry[1])%2==1 then
            local theme=THEMES[lightning and "lightning" or entry[2]]
            components[#components+1]=theme
            names[#names+1]=theme.school
            rate=math.max(rate,EMITTERS[theme.fx].rate)
        end
    end
    local first,last=components[1],components[#components]
    local result={mask=displayMask,school=first.school,fx=first.fx,dark=first.dark,bright=last.bright,glow=first.glow,
        backdropSchool=first.backdropSchool,components=components,rate=rate*(#components>1 and 1.5 or 1)}
    if #components>1 then
        result.fillPath=MEDIA.."Fills\\fill_base_"..table.concat(names,"_")
        result.flatFillPath=result.fillPath.."_flat"
    end
    mixed[key]=result
    return result
end

function FX.ResolveTheme(record,options)
    local info=SpellVisuals and SpellVisuals.Resolve(record,options)
    if not info then return nil end
    local theme=FX.ThemeForMask(info.mask,info.profile)
    if theme then info.displayMask=theme.mask end
    return theme,info
end

local paintGradient
local WHITE = {1,1,1}
local function paintFill(v, gradient)
    local components=v.theme.components
    local count=#components
    for _,tex in ipairs(v.layers) do tex:Hide() end
    if count==1 then
        if v.fill.SetDrawLayer then v.fill:SetDrawLayer("ARTWORK",7) end
        v.fill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        paintGradient(v.fill,components[1].dark,components[1].bright,gradient)
        v.fill:Show()
        return
    end
    -- One opaque color texture avoids alpha-layer ordering/batching faults
    -- and seven overlaid geometry updates on engine-owned secret fills.
    if v.fill:SetTexture(gradient and v.theme.fillPath or v.theme.flatFillPath)~=false then
        if v.fill.SetDrawLayer then v.fill:SetDrawLayer("ARTWORK",7) end
        paintGradient(v.fill,WHITE,WHITE,false)
        v.fill:Show()
        return
    end
    -- Each layer covers the *current* engine-owned fill. Soft curved masks
    -- include every school in its current area, including at the start/end of a
    -- cast or channel. There are no fixed-width sections or progress reads.
    for i,component in ipairs(components) do
        local tex=v.layers[i]
        if not tex then
            tex=v.bar.TimerBar:CreateTexture(nil,"ARTWORK",nil,7)
            tex:SetAllPoints(v.source)
            v.layers[i]=tex
        end
        tex:SetTexture(MEDIA..(i==1 and "hybrid_base" or "hybrid_"..count.."_"..i))
        if tex.SetDrawLayer then tex:SetDrawLayer("ARTWORK",i-1) end
        tex:SetBlendMode("BLEND")
        paintGradient(tex,component.dark,component.bright,gradient)
        tex:Show()
    end
end

local function clearParticles(v)
    if v.liveParticles > 0 then
        for _, p in ipairs(v.pool) do
            if p.alive then
                p.alive = false
                if p.group then p.group:Stop() end
                p.tex:Hide()
            end
        end
    end
    v.liveParticles = 0
    v.luaParticles = 0
    v.carry = 0
end

paintGradient = function(tex, dark, bright, gradient)
    tex:SetVertexColor(1, 1, 1)
    if tex.SetGradient and CreateColor then
        local d = gradient and dark or bright
        tex:SetGradient("HORIZONTAL", nativeColor(d), nativeColor(bright))
    elseif tex.SetGradientAlpha then
        local d = gradient and dark or bright
        tex:SetGradientAlpha("HORIZONTAL", d[1], d[2], d[3], 1, bright[1], bright[2], bright[3], 1)
    else
        tex:SetVertexColor(bright[1], bright[2], bright[3])
    end
end

-- Portable crops of the same artifact headers used by Siege. The texture's
-- dimensions differ from the full atlas, so keep the original visual aspect.
local BACKDROPS = {
    arcane = { default = "magearcane", DRUID = "druid" },
    fire = { default = "paladin" },
    frost = { default = "frost" },
    shadow = { default = "priestshadow", WARLOCK = "warlock" },
    holy = { default = "priest", PALADIN = "paladin" },
    nature = { default = "druid", SHAMAN = "shaman", HUNTER = "hunter" },
}
local BACKDROP_STYLES = {
    magearcane = {18,30,95, {0.8,0.3,0.75}, true},
    paladin = {50,-4,101, {0.75,0.5,0.5}, false, -2},
    frost = {32,23,77, {0.2,0.35,0.5}, true},
    priestshadow = {20,24,100, {0.6,0.5,0.6}, true},
    warlock = {30,16,65, {0.85,0.5,0.85}, true},
    priest = {12,18,75, {1,0.7,0.15}, true},
    druid = {2,31,75, {0.75,1,0.5}, true},
    shaman = {30,-6,100, {1,1,0.35}},
    hunter = {30,17,195, {0.5,0.8,0.25}},
}

local function backdropStyle(v, theme, texture)
    if not v.theme then return end
    theme=theme or v.theme.components[1]
    texture=texture or v.backdrop
    local school = theme.backdropSchool or theme.school
    local choices = BACKDROPS[school]
    local class = v.bar._fluxSchoolCast and v.bar._fluxSchoolCast.class
    local art = theme.backdropArt or (choices and (choices[class] or choices.default))
    local spec = art and BACKDROP_STYLES[art]
    if not spec then return end
    local color = spec[4]
    local height = spec[3]
    if school == "holy" and art == "paladin" then color, height = {0.75,0.85,0.6}, 75 end
    if school == "arcane" and art == "druid" then color = {1,1,1} end
    if theme.backdropArt then color=theme.glow end
    texture:SetTexture(MEDIA .. "backdrop_" .. art)
    texture:SetTexCoord(0, 1, spec[5] and 1 or 0, spec[5] and 0 or 1)
    texture:SetVertexColor(unpack(color))
    texture:ClearAllPoints()
    texture:SetPoint("CENTER", v.bar.TimerBar, "CENTER", (spec[6] or 0) * v.scale, spec[2] * v.scale)
    texture:SetSize(v.bar.TimerBar:GetWidth() + 2 * spec[1] * v.scale, height * v.scale)
    return art
end

local bindFill
function FX.Layout(bar)
    local v = visuals[bar]
    if not v then return end
    local timer = bar.TimerBar
    local h = math.max(1, timer:GetHeight())
    v.layoutWidth,v.layoutHeight=timer:GetWidth(),timer:GetHeight()
    local scale = math.min(1.5, math.max(0.35, h / 22))
    v.scale = scale
    v.halo:ClearAllPoints()
    v.halo:SetPoint("TOPLEFT", timer, "TOPLEFT", -(v.haloPadX or 14) * scale, (v.haloPadY or 10) * scale)
    v.halo:SetPoint("BOTTOMRIGHT", timer, "BOTTOMRIGHT", (v.haloPadX or 14) * scale, -(v.haloPadY or 10) * scale)
    if v.theme then
        for i,texture in ipairs(v.backdrops) do
            if v.theme.components[i] then backdropStyle(v,v.theme.components[i],texture) end
        end
    end
    v.edge:SetSize(26 * scale, 18 * scale)
    if v.boundSource then bindFill(v) end
    -- Below text (+50) and native interrupt shield, above bar chrome.
    v.fx:SetFrameLevel((bar.SparkFrame and bar.SparkFrame:GetFrameLevel() or bar:GetFrameLevel() + 12) + 1)
end

local function build(bar)
    local v = {bar = bar, pool = {}, liveParticles = 0, luaParticles=0, clock = 0, carry = 0, scale = 1,emitterIndex=0}
    local timer = bar.TimerBar
    v.fill = timer:CreateTexture(nil, "ARTWORK", nil, 7)
    v.fill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    v.fill:Hide()
    v.layers={v.fill}
    v.halo = bar:CreateTexture(nil, "BACKGROUND", nil, -6)
    v.halo:SetTexture(MEDIA .. "cast_dot")
    if C_Texture and C_Texture.GetAtlasInfo and v.halo.SetAtlas then
        local info = C_Texture.GetAtlasInfo("cast_interrupt_outerglow")
        if type(info) == "table" and info.width and info.height then
            v.halo:SetAtlas("cast_interrupt_outerglow")
            v.haloPadX = math.max(0, (info.width * 0.5 - 208) / 2)
            v.haloPadY = math.max(0, (info.height * 0.5 - 11) / 2)
        end
    end
    v.halo:SetDesaturated(true)
    v.halo:SetBlendMode("ADD")
    v.halo:Hide()
    v.backdrop = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
    v.backdrop:SetBlendMode("ADD")
    v.backdrop:Hide()
    v.backdrops={v.backdrop}
    v.fx = CreateFrame("Frame", nil, bar)
    v.fx:SetAllPoints(timer)
    v.fx:EnableMouse(false)
    v.edge = v.fx:CreateTexture(nil, "OVERLAY")
    v.edge:SetTexture(MEDIA .. "cast_dot")
    v.edge:SetBlendMode("ADD")
    v.edge:Hide()
    -- Native clipping follows secret fill geometry without Lua reading width.
    v.clip = CreateFrame("Frame", nil, v.fx)
    v.clip:EnableMouse(false)
    if v.clip.SetClipsChildren then v.clip:SetClipsChildren(true) end
    v.particles = CreateFrame("Frame", nil, v.clip)
    v.particles:SetAllPoints(timer)
    v.particles:EnableMouse(false)
    visuals[bar] = v
    return v
end

local function restoreFill(v)
    for _,tex in ipairs(v.layers) do tex:Hide() end
    if v.source then
        v.source:SetAlpha(v.sourceAlpha or 1)
        v.source = nil
    end
end

local function tintTiers(v, color)
    for i, tier in ipairs(v.bar.StageTiers or {}) do
        local components=v.theme and v.theme.components
        local tint=color and components and components[(i-1)%#components+1].bright or color
        for _, key in ipairs({"Normal", "Disabled"}) do
            local tex = tier[key]
            if tex then
                tex:SetDesaturated(color ~= nil)
                local shade = key == "Disabled" and 0.35 or 1
                tex:SetVertexColor(tint and tint[1] * shade or 1, tint and tint[2] * shade or 1, tint and tint[3] * shade or 1)
            end
        end
    end
    v.tiersTinted = color ~= nil
end

local function sleepIfIdle()
    if not next(active) and driver then driver:Hide(); animationElapsed=0 end
end

function FX.Reset(bar, forget)
    local v = visuals[bar]
    if v and v.theme then
        restoreFill(v)
        if v.tiersTinted then tintTiers(v, nil) end
        v.halo:Hide(); v.edge:Hide()
        for _,texture in ipairs(v.backdrops) do texture:Hide() end
        clearParticles(v)
        v.theme = nil
        active[bar] = nil
    end
    if forget then bar._fluxSchoolCast = nil end
    sleepIfIdle()
end

bindFill = function(v)
    local source = v.bar.TimerBar:GetStatusBarTexture()
    if not source then return false end
    if v.boundSource==source and v.boundScale==v.scale then return true end
    v.boundSource=source
    v.boundScale=v.scale
    for _,tex in ipairs(v.layers) do
        tex:ClearAllPoints()
        tex:SetAllPoints(source)
    end
    -- Edge and clipping are engine anchored, including on restricted clients.
    v.edge:ClearAllPoints()
    v.edge:SetPoint("CENTER", source, "RIGHT", 0, 0)
    v.clip:ClearAllPoints()
    v.clip:SetPoint("TOPLEFT", source, "TOPLEFT", 0, 40 * v.scale)
    v.clip:SetPoint("BOTTOMRIGHT", source, "BOTTOMRIGHT", 0, -40 * v.scale)
    return true
end

local function finishAppearance(v,db)
    v.edge:Hide()
    v.halo:SetAlpha(0.3*percent(db,"glowOpacity",100))
    for _,texture in ipairs(v.backdrops) do
        texture:SetAlpha(0.6*percent(db,"backdropOpacity",100)/#v.theme.components)
    end
end

local function style(v)
    local db, theme = settings(), v.theme
    bindFill(v)
    if enabled(db, "colors") then
        local source = v.bar.TimerBar:GetStatusBarTexture()
        if source and v.source ~= source then
            if v.source then v.source:SetAlpha(v.sourceAlpha or 1) end
            v.source, v.sourceAlpha = source, source:GetAlpha()
        end
        if source then source:SetAlpha(0) end
        paintFill(v,enabled(db,"gradient"))
        tintTiers(v, theme.bright)
    else
        restoreFill(v)
        if v.tiersTinted then tintTiers(v, nil) end
    end
    v.halo:SetVertexColor(unpack(theme.glow))
    v.edge:SetVertexColor(unpack(theme.bright))
    v.glowIndex=nil
    v.halo:SetShown(enabled(db, "halo") and percent(db, "glowOpacity", 100) > 0)
    v.edge:SetShown(enabled(db, "edge") and percent(db, "glowOpacity", 100) > 0 and not v.finished)
    for _,texture in ipairs(v.backdrops) do texture:Hide() end
    for i,component in ipairs(theme.components) do
        local texture=v.backdrops[i]
        if not texture then
            texture=v.bar:CreateTexture(nil,"BACKGROUND",nil,-7)
            texture:SetBlendMode("ADD")
            v.backdrops[i]=texture
        end
        local art=backdropStyle(v,component,texture)
        texture:SetShown(art~=nil and enabled(db,"backdrop") and percent(db,"backdropOpacity",100)>0)
        texture:SetAlpha(0.8*percent(db,"backdropOpacity",100)/#theme.components)
    end
    if not enabled(db, "particles") or percent(db, "density", 200) == 0 then clearParticles(v) end
end

local function spawn(v, width)
    local p
    for _, candidate in ipairs(v.pool) do if not candidate.alive then p = candidate; break end end
    if not p then
        if #v.pool >= 48 then return end
        p = {tex = v.particles:CreateTexture(nil, "ARTWORK")}
        createNativeParticle(v,p)
        v.pool[#v.pool + 1] = p
    end
    -- Pool members cross schools; remove optional motion/color state first.
    p.spin, p.sway, p.pulse, p.twinkle, p.c1 = nil, nil, nil, nil, nil
    -- Only flames override this. Reset on every reuse so other schools stay
    -- square, including when their first particle did not come from Fire.
    p.aspect = 1
    p.rot, p.age, p.alive, p.drawSize = rnd(0, math.pi * 2), 0, true, nil
    v.liveParticles = v.liveParticles + 1
    local components=v.theme.components
    v.emitterIndex=v.emitterIndex%#components+1
    local component=components[v.emitterIndex]
    local emitter = EMITTERS[component.fx]
    emitter.spawn(p, width / v.scale)
    if component.particleTint then p.c0,p.c1=component.bright,component.glow
    else p.c0,p.c1=emitter.c0,emitter.c1 end
    p.x, p.y, p.vx, p.vy = p.x * v.scale, p.y * v.scale, p.vx * v.scale, p.vy * v.scale
    p.size0, p.size1 = p.size0 * v.scale, p.size1 * v.scale
    if p.sway then p.sway = p.sway * v.scale end
    if p.emitter~=emitter then
        p.emitter=emitter
        p.tex:SetTexture(emitter.path)
        p.tex:SetBlendMode(emitter.blend)
        p.tex:SetDesaturated(component.fx == "runes" or component.fx == "skulls")
    end
    if p.group then playNativeParticle(v,p)
    else
        v.luaParticles=v.luaParticles+1
        p.tex:SetRotation(p.spin and p.rot or 0)
        p.tex:SetAlpha(0)
        p.tex:Show()
    end
end

local function needsUpdates(v, db)
    -- Finished bars keep their painted appearance under the cast bar's own
    -- hold/fade. Only the existing particles still need our animation driver.
    if v.finished then return v.luaParticles > 0 end
    local glow = percent(db, "glowOpacity", 100) > 0
    if (enabled(db, "halo") or (enabled(db, "edge") and not v.finished)) and glow then return true end
    if enabled(db, "particles") and percent(db, "density", 200) > 0 then
        return true
    end
    return false
end

function FX.Update(bar, dt)
    local v = visuals[bar]
    if not v or not v.theme then return end
    if not bar:IsVisible() or bar.customTimer or bar.interrupted or bar._fluxPetCastDisabled then
        FX.Reset(bar, true)
        return
    end
    dt = math.min(math.max(dt, 0), 0.1)
    v.clock = v.clock + dt
    local db = settings()
    if not v.finished then
        local glow = percent(db, "glowOpacity", 100)
        local components=v.theme.components
        local index=math.floor(v.clock*2)%#components+1
        if v.glowIndex~=index then
            v.halo:SetVertexColor(unpack(components[index].glow))
            v.edge:SetVertexColor(unpack(components[index%#components+1].bright))
            v.glowIndex=index
        end
        v.edge:SetAlpha((0.65 + 0.25 * math.sin(v.clock * 6)) * glow)
        v.halo:SetAlpha((0.45 + 0.15 * math.sin(v.clock * 3)) * glow)
    end
    if not v.finished and enabled(db, "particles") then
        local width = bar.TimerBar:GetWidth()
        -- Accessible progress narrows the spawn region; otherwise native clipping
        -- handles the full-width distribution. Never derive geometry from secrets.
        local low, high = bar:GetMinMaxValues()
        local value = Schools.Plain(bar:GetValue())
        low, high = Schools.Plain(low), Schools.Plain(high)
        if type(low) == "number" and type(high) == "number" and type(value) == "number" and high > low then
            width = width * math.max(0, math.min(1, (value - low) / (high - low)))
        end
        v.carry = math.min(48, v.carry + v.theme.rate * percent(db, "density", 200) * dt)
        while v.carry >= 1 do
            v.carry = v.carry - 1
            if width > 2 then spawn(v, width) end
        end
    end
    if v.luaParticles>0 then stepParticles(v, dt) end
    if not needsUpdates(v, db) then active[bar] = nil; sleepIfIdle() end
end

local function drive()
    if not driver then
        driver = CreateFrame("Frame")
        driver:SetScript("OnUpdate", function(_, dt)
            animationElapsed=animationElapsed+dt
            if animationElapsed<1/30 then return end
            local elapsed=animationElapsed
            animationElapsed=0
            for bar in pairs(active) do FX.Update(bar, elapsed) end
            sleepIfIdle()
        end)
    end
    driver:Show()
end

local STYLE_KEYS={"colors","gradient","particles","halo","edge","backdrop","density","glowOpacity","backdropOpacity"}
local function changedStyle(v,db)
    local snapshot=v.settingsSnapshot
    if not snapshot then snapshot={};v.settingsSnapshot=snapshot end
    local changed=false
    for i,key in ipairs(STYLE_KEYS) do
        local value=db[key]
        if value==nil then value=DEFAULTS[key] end
        if snapshot[i]~=value then changed=true;snapshot[i]=value end
    end
    return changed
end

function FX.Apply(bar)
    local record, db = bar._fluxSchoolCast, settings()
    local unit = record and record.unit
    if unit == "vehicle" then unit = "player" end
    if not record or not enabled(db, "enabled") or not DEFAULTS[unit] or not enabled(db, unit)
        or bar.customTimer or bar.interrupted or bar._fluxPetCastDisabled then
        FX.Reset(bar)
        return
    end
    local theme,info = FX.ResolveTheme(record,db)
    if not theme then FX.Reset(bar); return end
    record.schoolMask,record.visualMask,record.resolvedMask,record.inferred=info.schoolMask,theme.mask,info.mask,info.inferred
    local v = visuals[bar] or build(bar)
    local themeChanged=v.theme~=theme
    local settingsChanged=changedStyle(v,db)
    local finishChanged=(v.finished and true or false)~=(record.finished and true or false)
    if themeChanged then clearParticles(v) end
    v.theme, v.finished = theme, record.finished
    local timer=bar.TimerBar
    local repaint=themeChanged or settingsChanged or v.styledClass~=record.class
        or v.boundSource~=timer:GetStatusBarTexture() or v.layoutWidth~=timer:GetWidth() or v.layoutHeight~=timer:GetHeight()
    if repaint then
        v.styledClass=record.class
        FX.Layout(bar)
        style(v)
    end
    if v.finished and (repaint or finishChanged) then finishAppearance(v,db) end
    if needsUpdates(v, db) then
        if not active[bar] then active[bar] = true; drive() end
    else active[bar] = nil; sleepIfIdle() end
end

function FX.Begin(bar, unit, spellID, name, tradeSkill, eventSpellID)
    FX.Reset(bar, true)
    local class
    if UnitClass then local _, token = UnitClass(unit); class = Schools.Plain(token) end
    -- Keep only accessible cast identity. Never retain a secret as a lookup key.
    bar._fluxSchoolCast = {unit = unit, id = Schools.Plain(spellID) or Schools.Plain(eventSpellID), name = Schools.Plain(name),
        trade=Schools.Plain(tradeSkill),tradeUnknown=tradeSkill~=nil and Schools.Plain(tradeSkill)==nil, class = class}
    FX.Apply(bar)
end

function FX.Finish(bar)
    local record=bar._fluxSchoolCast
    if not record or record.finished then return end
    record.finished=true
    local v=visuals[bar]
    if not v or not v.theme then return end
    v.finished=true
    -- Native completion may replace the source texture or reset its alpha.
    -- Rebind existing artwork without resolving schools or rebuilding styles.
    bindFill(v)
    local db=settings()
    if enabled(db,"colors") then
        local source=bar.TimerBar:GetStatusBarTexture()
        if source and source~=v.source then
            if v.source then v.source:SetAlpha(v.sourceAlpha or 1) end
            v.source,v.sourceAlpha=source,source:GetAlpha()
        end
        if source then source:SetAlpha(0) end
    end
    finishAppearance(v,db)
    if not needsUpdates(v,db) then active[bar]=nil;sleepIfIdle() end
end

function FX.Attach(bar)
    if bar._fluxSchoolAttached then return end
    bar._fluxSchoolAttached = true
    attached[bar]=true
    bar:HookScript("OnHide", function(self) FX.Reset(self, true) end)
    FX.SyncEvents()
end

function FX.Refresh()
    -- Include default/unmapped casts awaiting data and newly constructed bars.
    for bar in pairs(attached) do
        if bar:IsVisible() then FX.Apply(bar) else FX.Reset(bar, true) end
    end
    FX.SyncEvents()
end

-- Public only inside the addon namespace; also exercised by the Lua harness.
function FX.ObserveCast(sourceGUID, spellID, mask, event)
    event = Schools.Plain(event)
    if event ~= "SPELL_CAST_START" and event ~= "SPELL_CAST_SUCCESS" then return end
    sourceGUID, spellID = Schools.Plain(sourceGUID), Schools.Plain(spellID)
    if type(sourceGUID) ~= "string" or type(spellID) ~= "number" then return end
    -- CLEU may precede UNIT_SPELLCAST_START. Cache accessible schools first;
    -- repaint only the matching current source/cast, never a completed bar.
    if not Schools.Learn(spellID, mask) then return end
    for bar in pairs(attached) do
        local record = bar._fluxSchoolCast
        if record and record.id == spellID and not record.finished and (bar.casting or bar.channeling) then
            local guid = UnitGUID and Schools.Plain(UnitGUID(record.unit))
            if guid == sourceGUID and (record.schoolMask~=mask or record.resolvedMask~=mask) then FX.Apply(bar) end
        end
    end
end

local function combatLogAvailable()
    local client = ns.Flux and ns.Flux.Client or FLUX_API
    if client and client.isLiveMidnight then return false end
    local cap = ns.Flux and ns.Flux.Cap
    if not cap or not cap.hasCombatLogUnfiltered or type(CombatLogGetCurrentEventInfo) ~= "function" then return false end
    if C_CombatLog and type(C_CombatLog.IsCombatLogRestricted) == "function" then
        local ok, restricted = pcall(C_CombatLog.IsCombatLogRestricted)
        -- An inaccessible/failed restriction query is insufficient permission.
        if not ok or Schools.Plain(restricted) ~= false then return false end
    end
    return true
end

local function wantsCombatLog()
    local db = settings()
    if not enabled(db, "enabled") then return false end
    for _, unit in ipairs({"player", "target", "focus", "pet"}) do
        if enabled(db, unit) then return true end
    end
    return false
end

local refreshPending=false
local refreshAll=false
local pendingBars={}
local function refreshSpellMetadata(bar)
    if bar then pendingBars[bar]=true else refreshAll=true end
    if refreshPending then return end
    refreshPending=true
    C_Timer.After(0,function()
        refreshPending=false
        if refreshAll then
            refreshAll=false
            for pending in pairs(pendingBars) do pendingBars[pending]=nil end
            Schools.InvalidateAliases()
            if SpellVisuals then SpellVisuals.Invalidate() end
            for pending in pairs(attached) do
                local record=pending._fluxSchoolCast
                if record and not record.finished and pending:IsVisible() then FX.Apply(pending) end
            end
            FX.SyncEvents()
        else
            for pending in pairs(pendingBars) do
                pendingBars[pending]=nil
                local record=pending._fluxSchoolCast
                if record and not record.finished and pending:IsVisible() then FX.Apply(pending) end
            end
        end
    end)
end

function FX.SyncEvents()
    if not events then
        events = CreateFrame("Frame")
        events:SetScript("OnEvent", function(_, event, spellID)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                if not combatLogAvailable() or not wantsCombatLog() then return end
                local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, id, _, mask = CombatLogGetCurrentEventInfo()
                FX.ObserveCast(sourceGUID, id, mask, subevent)
            elseif event=="SPELL_DATA_LOAD_RESULT" then
                spellID=Schools.Plain(spellID)
                if type(spellID)~="number" then return end
                local cached=SpellVisuals and SpellVisuals.Invalidate(spellID)
                local name,old=Schools.InvalidateAliases(spellID)
                -- Other addons/tooltips can load thousands of unrelated IDs.
                -- Never flush all caches or restyle all bars for those loads.
                if cached or name or old then
                    for bar in pairs(attached) do
                        local record=bar._fluxSchoolCast
                        if record and not record.finished and bar:IsVisible()
                            and (record.id==spellID or (name and record.name==name) or (old and record.name==old)) then
                            refreshSpellMetadata(bar)
                        end
                    end
                end
            else
                refreshSpellMetadata()
            end
        end)
        events:RegisterEvent("SPELLS_CHANGED")
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        pcall(events.RegisterEvent,events,"PLAYER_SPECIALIZATION_CHANGED")
        pcall(events.RegisterEvent, events, "PLAYER_TALENT_UPDATE")
        pcall(events.RegisterEvent, events, "SPELL_DATA_LOAD_RESULT")
    end
    -- Even UnregisterEvent is forbidden on restricted clients, including for
    -- an event this frame never registered. Do not probe either frame method.
    -- If restrictions change while subscribed, leave it dormant; the callback
    -- checks availability again before reading the combat log.
    if not combatLogAvailable() then return end
    if wantsCombatLog() then
        if not combatLogRegistered then
            local ok, result = pcall(events.RegisterEvent, events, "COMBAT_LOG_EVENT_UNFILTERED")
            combatLogRegistered = ok and result ~= false
        end
    elseif combatLogRegistered then
        events:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        combatLogRegistered = false
    end
end
