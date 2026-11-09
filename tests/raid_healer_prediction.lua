-- Executes the production painter with readable and opaque native results.
-- This verifies data flow and geometry ownership; native pixels/taint stay pending.
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function loadModule(environment)
    local fn, message
    if _VERSION == "Lua 5.1" then
        fn, message = loadfile(os.getenv("FLUX_RAID_PREDICTION_SOURCE") or "RaidFrame/FluxRaidPrediction.lua")
        if fn then setfenv(fn, environment) end
    else
        fn, message = loadfile(os.getenv("FLUX_RAID_PREDICTION_SOURCE") or "RaidFrame/FluxRaidPrediction.lua", "t", environment)
    end
    assert(fn, message)("_FluxUI", {})
    return environment.FluxRaidPrediction
end

local function Fixture(native)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local creations, layouts = 0, 0
    local secrets = setmetatable({}, { __mode = "k" })
    local function opaque(label)
        local value = setmetatable({}, {
            __add = function() error("secret arithmetic: " .. label) end,
            __sub = function() error("secret arithmetic: " .. label) end,
            __div = function() error("secret arithmetic: " .. label) end,
            __lt = function() error("secret comparison: " .. label) end,
            __le = function() error("secret comparison: " .. label) end,
            __eq = function() error("secret comparison: " .. label) end,
        })
        secrets[value] = true
        return value
    end
    e.issecretvalue = function(value) return type(value) == "table" and secrets[value] or false end
    e.FluxRaidCompat = { IsSecret = e.issecretvalue }
    e.InCombatLockdown = function() return e.combat or false end
    e.FluxRaidVisuals = { FRAME_WIDTH = 72 }
    e.Enum = {
        UnitIncomingHealClampMode = { MissingHealth = 0 },
        UnitDamageAbsorbClampMode = { MissingHealth = 0 },
        UnitHealAbsorbClampMode = { CurrentHealth = 0 },
        UnitHealAbsorbMode = { ReducedByIncomingHeals = 0 },
    }
    local methods = {}
    local function layout()
        assert(not e.combat, "combat must not change prediction geometry")
        layouts = layouts + 1
    end
    function methods:SetParent(parent) layout(); self.parent = parent end
    function methods:SetAllPoints(other) layout(); self.allpoints = other end
    function methods:SetClipsChildren(value) layout(); self.clips = value end
    function methods:EnableMouse(value) layout(); self.mouse = value end
    function methods:SetFrameLevel(value) layout(); self.level = value end
    function methods:GetFrameLevel() return self.level or 2 end
    function methods:SetStatusBarTexture(value)
        layout(); self.textureName = value
        self.fill = self.fill or e.CreateFrame("Texture", nil, self)
    end
    function methods:SetStatusBarColor(...) layout(); self.color = { ... } end
    function methods:SetColorTexture(...) layout(); self.color = { ... } end
    function methods:SetTexture(value)layout();self.textureName=value end
    function methods:SetAtlas(value, useSize)layout();self.atlas,self.useAtlasSize=value,useSize end
    function methods:SetVertexColor(...)layout();self.vertexColor={...}end
    function methods:SetBlendMode(value)layout();self.blendMode=value end
    function methods:GetStatusBarTexture() return self.fill end
    function methods:ClearAllPoints() layout(); self.points = {} end
    function methods:SetPoint(...) layout(); self.points[#self.points + 1] = { ... } end
    function methods:SetWidth(value) layout(); self.width = value end
    function methods:GetWidth() assert(not e.combat, "combat must not read layout widths"); return self.width or 66 end
    function methods:SetReverseFill(value) layout(); self.reverse = value end
    function methods:SetMinMaxValues(low, high) self.low, self.high = low, high end
    function methods:SetValue(value) self.value = value end
    function methods:SetAlphaFromBoolean(value, yes, no) self.boolean, self.yes, self.no = value, yes, no end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:CreateTexture() return e.CreateFrame("Texture", nil, self) end
    e.CreateFrame = function(kind, name, parent)
        layout(); creations = creations + 1
        return setmetatable({kind = kind, parent = parent, points = {}}, { __index = methods })
    end
    local frame = e.CreateFrame("Button")
    frame.healthBar = e.CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetStatusBarTexture("health")
    frame.powerBar = e.CreateFrame("StatusBar", nil, frame)
    frame.powerBar:SetStatusBarTexture("power")
    frame.unit, frame.unitExists, frame.optionTable = "party1", true, {}
    local values = { current = 60, maximum = 100, mine = 20, total = 50, absorb = 30, healAbsorb = 10 }
    e.UnitHealth = function() return values.current end
    e.UnitHealthMax = function() return values.maximum end
    e.UnitGetIncomingHeals = function(_, healer) return healer and values.mine or values.total end
    e.UnitGetTotalAbsorbs = function() return values.absorb end
    e.UnitGetTotalHealAbsorbs = function() return values.healAbsorb end
    e.UnitPowerType = function() return 0 end
    e.UnitPowerMax = function() return 200 end
    if native then
        e.calculators = {}
        e.CreateUnitHealPredictionCalculator = function()
            local calculator = { config = {} }
            for _, key in ipairs({"IncomingHealClampMode", "IncomingHealOverflowPercent", "DamageAbsorbClampMode", "HealAbsorbClampMode", "HealAbsorbMode"}) do
                calculator["Set" .. key] = function(self, value) self.config[key] = value end
            end
            function calculator:GetMaximumHealth() return values.maximum end
            function calculator:GetIncomingHeals()
                local index = ({[1]=1,[1.10]=2,[1.25]=3,[1.50]=4})[self.config.IncomingHealOverflowPercent]
                local overflow = values.nativeOverheal and values.nativeOverheal[index] or values.overheal
                return values.total, values.mine, values.others, overflow
            end
            function calculator:GetDamageAbsorbs() return values.absorb, values.overAbsorb end
            function calculator:GetHealAbsorbs() return values.healAbsorb, values.overHealAbsorb end
            e.calculators[#e.calculators+1] = calculator
            e.calculator = e.calculator or calculator
            return calculator
        end
        e.UnitGetDetailedHealPrediction = function(unit, healer, cal)
            local owned = false
            for _, candidate in ipairs(e.calculators) do if cal == candidate then owned = true end end
            check(unit == frame.unit and healer == "player" and owned, "native calculation follows bound unit")
        end
    else
        -- Explicit nil prevents a host-provided API from changing this fixture.
        e.CreateUnitHealPredictionCalculator = false
    end
    local prediction = loadModule(e)
    return e, prediction, frame, values, opaque, function() return creations, layouts end
end

for _, client in ipairs({"retail", "forever", "era", "anniversary", "classic"}) do
    local e, prediction, frame, values, opaque, metrics = Fixture(true)
    check(prediction.Setup(frame), client .. " setup succeeds")
    local state = frame._fluxPrediction
    check(state.host.clips == true and state.host.allpoints == frame.healthBar, "prediction clips at health bounds")
    check(frame.healthBar.myHealPrediction == state.mine and frame.healthBar.otherHealPrediction == state.others, "heal aliases survive")
    check(frame.healthBar.totalAbsorb == state.absorb and frame.healthBar.healAbsorb == state.healAbsorb, "absorb aliases survive")
    check(state.absorbPattern.textureName=="Interface\\RaidFrame\\Shield-Overlay"
        and state.absorbPattern.allpoints==state.absorb:GetStatusBarTexture(),"absorb stripes track only the native absorb fill")
    check(state.overAbsorb.width==16 and state.overHealAbsorb.width==16,
        "overflow indicators use Blizzard's sixteen-pixel sizing")
    check(state.overAbsorb.points[1][1]=="TOPLEFT" and state.overAbsorb.points[1][2]==frame.healthBar
        and state.overAbsorb.points[1][3]=="TOPRIGHT" and state.overAbsorb.points[1][4]==-7,
        "damage overflow straddles the right health edge at the native minus-seven offset")
    check(state.overHealAbsorb.points[1][1]=="TOPRIGHT" and state.overHealAbsorb.points[1][3]=="TOPLEFT"
        and state.overHealAbsorb.points[1][4]==7,"heal overflow uses the mirrored native plus-seven offset")
    check(state.overAbsorb.atlas=="RaidFrame-Shield-Overshield" and state.overHealAbsorb.atlas=="RaidFrame-Absorb-Overabsorb"
        and state.overAbsorb.blendMode=="ADD" and state.overAbsorb.useAtlasSize==false,
        "native overflow art uses explicit geometry without stretching a solid strip")
    check(state.mine.color[1]==.35 and state.mine.color[2]==1 and state.cost.color[1]==1 and state.cost.color[4]==.3,
        "healer feedback retains green incoming healing and lighter resource cost")
    check(state.mine.points[1][2] == frame.healthBar.fill, "own heals start at current health edge")
    check(state.others.points[1][2] == state.mine.fill and state.absorb.points[1][2] == state.others.fill, "segments follow previous native fill")
    check(state.healAbsorb.reverse and state.healAbsorb.points[1][1] == "TOPRIGHT", "heal absorb consumes health backwards")
    check(e.calculator.config.IncomingHealOverflowPercent == 1, "calculator clamps to frame")
    check(state.overhealLevels[1].color[1]==0.80 and state.overhealLevels[1].color[4]==0.45
        and state.overhealLevels[4].color[1]==0.80 and state.overhealLevels[4].color[4]==0.75,"four warning layers retain bronze/gold/copper intensity")
    check(#e.calculators==4 and e.calculators[2].config.IncomingHealOverflowPercent==1.10
        and e.calculators[3].config.IncomingHealOverflowPercent==1.25
        and e.calculators[4].config.IncomingHealOverflowPercent==1.50,"four native severity boundaries use owned calculators")
    local creates = metrics()
    prediction.Setup(frame)
    check(metrics() == creates, "reapplying geometry reuses every widget")
    values.maximum, values.mine, values.others = opaque("maximum"), opaque("mine"), opaque("others")
    values.absorb, values.healAbsorb = opaque("absorb"), opaque("healAbsorb")
    values.overheal, values.overAbsorb, values.overHealAbsorb = opaque("overheal"), opaque("overAbsorb"), opaque("overHealAbsorb")
    values.nativeOverheal={values.overheal,opaque("overheal10"),opaque("overheal25"),opaque("overheal50")}
    e.combat = true
    local _, beforeLayouts = metrics()
    prediction.Update(frame)
    local _, afterLayouts = metrics()
    check(afterLayouts == beforeLayouts, "combat updates do not mutate geometry")
    check(rawequal(state.mine.high, values.maximum) and rawequal(state.mine.value, values.mine), "opaque own healing passes directly to native sinks")
    check(rawequal(state.others.value, values.others) and rawequal(state.absorb.value, values.absorb), "opaque other heals and absorbs remain distinct")
    check(rawequal(state.healAbsorb.value, values.healAbsorb), "opaque heal absorb reaches native sink")
    check(rawequal(state.overheal.boolean, values.overheal) and rawequal(state.overAbsorb.boolean, values.overAbsorb), "opaque overflow booleans reach alpha sinks")
    check(rawequal(state.overHealAbsorb.boolean, values.overHealAbsorb), "opaque heal absorb overflow reaches alpha sink")
    for i=1,4 do check(rawequal(state.overhealLevels[i].boolean,values.nativeOverheal[i]),"opaque severity has an independent alpha sink") end
    check(not prediction.Setup(frame), "combat setup is refused")
    frame.optionTable.displayHealPrediction = false
    prediction.Update(frame)
    check(not state.mine.shown and not state.overAbsorb.shown, "disabled predictions stop displaying")
    frame.optionTable.displayHealPrediction = true
    frame.unitExists = false
    prediction.Update(frame)
    check(not state.absorb.shown, "disappeared units clear stale prediction")
    frame.unitExists = true
    e.UnitCastingInfo = function() return "Heal", nil, nil, nil, nil, nil, nil, nil, 123 end
    local cost = opaque("spell cost")
    e.C_Spell = { GetSpellPowerCost = function() return {{type = 1, cost = 99}, {type = 0, cost = cost}} end }
    prediction.UpdatePowerCost(frame)
    check(rawequal(state.cost.value, cost) and state.cost.high == 200, "cast cost selects active resource and passes opaque amount")
    e.UnitCastingInfo = function() return nil end
    prediction.UpdatePowerCost(frame)
    check(not state.cost.shown, "cast finish clears power cost")
    e.UnitCastingInfo = function() return "Heal", nil, nil, nil, nil, nil, nil, nil, opaque("spellID") end
    prediction.UpdatePowerCost(frame)
    check(not state.cost.shown, "unreadable spell identity is not classified")
    prediction.Clear(frame)
    check(not state.mine.shown and not state.cost.shown, "clear releases all displayed feedback")
end

do
    local e, prediction, frame, values, opaque = Fixture(false)
    prediction.Setup(frame)
    prediction.Update(frame)
    local state = frame._fluxPrediction
    check(state.mine.value == 20 and state.others.value == 20, "readable healing accounts for absorb reductions")
    check(state.absorb.value == 0 and state.overAbsorb.boolean == true, "readable damage absorbs clamp after healing")
    check(state.healAbsorb.value == 0 and state.overheal.boolean == false, "incoming healing removes heal absorb first")
    values.total, values.mine = 70, 40
    prediction.Update(frame)
    check(state.overheal.boolean == true and state.mine.value == 40 and state.others.value == 0, "readable overhealing is clipped")
    values.current, values.healAbsorb, values.total, values.mine = 30, 60, 20, 20
    prediction.Update(frame)
    check(state.healAbsorb.value == 30 and state.overHealAbsorb.boolean == true, "readable excessive heal absorb is clamped")
    values.mine = opaque("legacy restricted healing")
    prediction.Update(frame)
    check(not state.mine.shown and not state.others.shown and not state.absorb.shown, "legacy restricted healing is unavailable rather than fabricated")
    values.mine, values.maximum = 0, 0
    prediction.Update(frame)
    check(not state.mine.shown, "zero maximum cannot divide by zero")
end

do
    local e,prediction,frame,values=Fixture(false)
    prediction.Setup(frame)
    values.current,values.maximum,values.healAbsorb=60,100,0
    for _,case in ipairs({{40,0},{41,1},{51,2},{66,3},{91,4}})do
        values.total,values.mine=case[1],case[1]
        prediction.Update(frame)
        local regions=frame._fluxPrediction.overhealLevels
        for level=1,4 do check(regions[level].boolean==(level<=case[2]),"readable 0/10/25/50 percent severity threshold")end
    end
end

do
    local e, prediction, frame = Fixture(true)
    e.combat = true
    prediction.Update(frame)
    check(frame._fluxPrediction == nil, "new combat unit does not allocate prediction widgets")
end

print("Raid healer prediction: " .. checks .. " checks; five clients, native opaque sinks, readable fallback, combat geometry, cast cost")
