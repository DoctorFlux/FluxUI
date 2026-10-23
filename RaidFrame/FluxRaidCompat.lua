local addonName, ns = ...

-- Shared raid-frame compat: safe CUF/range helpers + reverse column math.
-- Capability-gated for Retail / Classic Era / Anniversary equally (no client favorites).

FluxRaidCompat = FluxRaidCompat or {}

local max = math.max
local min = math.min
local ceil = math.ceil
local floor = math.floor
local type = type
local pcall = pcall
local pairs = pairs

local GROUP_COUNT = 8
local GRP_SPACING = 2
local MTMA_UNITS_PER_COLUMN = 4

FluxRaidCompat.GROUP_COUNT = GROUP_COUNT
FluxRaidCompat.GRP_SPACING = GRP_SPACING
FluxRaidCompat.MTMA_UNITS_PER_COLUMN = MTMA_UNITS_PER_COLUMN
FluxRaidCompat.CHAT_TAB_LIFT = 28
FluxRaidCompat.UNITS_PER_COLUMN = 5
FluxRaidCompat.GROUP_LABEL_EXTRA = 14
FluxRaidCompat.MTMA_TARGET_HEIGHT = 18
FluxRaidCompat.MTMA_TARGET_GAP = 2
FluxRaidCompat.MTMA_MAX_COLUMNS = 10
FluxRaidCompat.MTMA_EXTRA_Y_FOR_FOUR_PLUS = 60
FluxRaidCompat.HEADER_UNIT_YOFFSET = -1

FluxRaidState = FluxRaidState or {
    pendingCombatWork = {},
    raidHeaders = {},
    frameArray = {},
    isInitialized = false,
}

local function API()
    return (ns and ns.API) or {}
end

local function FluxAPI()
    return rawget(_G, "FLUX_API")
end

local function IsSecretValue(v)
    if v == nil then
        return false
    end
    local a = API()
    if a.IsSecretValue then
        local ok, res = pcall(a.IsSecretValue, v)
        return ok and res and true or false
    end
    local S = ns and ns.Flux and ns.Flux.Secrets
    if S and S.IsSecretValue then
        local ok, res = pcall(S.IsSecretValue, v)
        return ok and res and true or false
    end
    local fn = rawget(_G, "issecretvalue") or rawget(_G, "IsSecretValue")
    if fn then
        local ok, res = pcall(fn, v)
        return ok and res and true or false
    end
    return false
end

--- Non-empty unit token. Secret UnitExists is treated as valid (do not boolean-test it).
function FluxRaidCompat.UnitTokenValid(unit)
    if type(unit) ~= "string" or unit == "" then
        return false
    end
    if not UnitExists then
        return true
    end
    local ok, exists = pcall(UnitExists, unit)
    if not ok then
        return false
    end
    if IsSecretValue(exists) then
        return true
    end
    return exists and true or false
end

--- Invoke a Blizzard CUF API. Does NOT destaint: secret compares still throw under _FluxUI.
--- Flux raid buttons must not use this for SetUnit / UpdateAll / UpdateHealth / UpdateInRange.
function FluxRaidCompat.CallCUF(fn, ...)
    if not fn then
        return
    end
    if securecallfunction then
        return securecallfunction(fn, ...)
    end
    if securecall then
        return securecall(fn, ...)
    end
    return pcall(fn, ...)
end

--- Edit Mode display border for discrete raid/party groups. False when Edit Mode absent.
function FluxRaidCompat.ShouldDisplayBorder(groupType)
    local fa = FluxAPI()
    if fa and fa.hasEditMode == false then
        return false
    end
    local em = rawget(_G, "EditModeManagerFrame")
    if not em or type(em.ShouldRaidFrameDisplayBorder) ~= "function" then
        return false
    end
    local ok, v = pcall(em.ShouldRaidFrameDisplayBorder, em, groupType)
    return ok and v and true or false
end

function FluxRaidCompat.HasCompactRaidFrameManager()
    local fa = FluxAPI()
    if fa and fa.HasCompactRaidFrameManager then
        return fa.HasCompactRaidFrameManager() and true or false
    end
    return rawget(_G, "CompactRaidFrameManager") ~= nil
end

--- Reposition Blizzard raid manager scale/left-edge when the frame exists.
function FluxRaidCompat.CanPositionRaidManager()
    return FluxRaidCompat.HasCompactRaidFrameManager()
end

--- Pet-battle secure hide when both the state driver and pet-battle API exist.
function FluxRaidCompat.CanUsePetBattleStateDriver()
    return (RegisterStateDriver ~= nil)
        and (rawget(_G, "C_PetBattles") ~= nil)
        and (rawget(_G, "SecureHandlerStateTemplate") ~= nil)
end

function FluxRaidCompat.GetChatTabLift()
    return FluxRaidCompat.CHAT_TAB_LIFT
end

--- Classic PrivateAura mixin when present and frame has no Lua buff children.
function FluxRaidCompat.ApplyPrivateAuraMixin(frame)
    local mixin = rawget(_G, "ContainerPrivateAuraBehaviorMixin")
    if not mixin or not Mixin or not frame then
        return
    end
    if frame.IsContainer then
        return
    end
    if frame.buffFrames and frame.buffFrames[1] then
        return
    end
    pcall(Mixin, frame, mixin)
end

local function SafeBooleanTest(value, default)
    local a = API()
    if a.SafeBooleanTest then
        return a.SafeBooleanTest(value, default)
    end
    if IsSecretValue(value) then
        return default
    end
    if value == nil then
        return default
    end
    local ok, truthy = pcall(function()
        if value then
            return true
        end
        return false
    end)
    if not ok then
        return default
    end
    return truthy
end

--- Raw UnitInRange. Do not use UnitInRangeSafe: it boolean-tests secret checkedRange.
local function ReadUnitInRange(unit)
    if not UnitInRange then
        return nil, nil
    end
    local ok, inRange, checked = pcall(UnitInRange, unit)
    if not ok then
        return nil, nil
    end
    return inRange, checked
end

--- Returns outOfRange bool and updates frame.outOfRange when both returns are plain.
--- Never writes a secret boolean onto frame.outOfRange (CUF if-tests that field).
--- Never calls CompactUnitFrame_UpdateInRange / raw UnitInRange without a valid token.
function FluxRaidCompat.GetOutOfRange(frame)
    if not frame then
        return false
    end
    local opt = frame.optionTable
    if not opt or not opt.fadeOutOfRange then
        frame.outOfRange = false
        return false
    end
    local unit = frame.displayedUnit or frame.unit
    if not FluxRaidCompat.UnitTokenValid(unit) then
        frame.outOfRange = false
        return false
    end
    local inRange, checked = ReadUnitInRange(unit)
    if IsSecretValue(inRange) or IsSecretValue(checked) then
        return false
    end
    local checkedOk = SafeBooleanTest(checked, inRange ~= nil)
    local out = checkedOk and (inRange == false)
    frame.outOfRange = out and true or false
    return frame.outOfRange
end

--- Apply Flux option alphas for out-of-range fade on Flux raid/mini CUFs only.
--- Midnight: SetAlphaFromBoolean accepts secret booleans (AllowedWhenTainted).
function FluxRaidCompat.ApplyRangeAlpha(frame)
    if not frame or not frame.SetAlpha then
        return
    end
    local opt = frame.optionTable
    if not opt or not opt.fadeOutOfRange then
        return
    end
    local unit = frame.displayedUnit or frame.unit
    if not FluxRaidCompat.UnitTokenValid(unit) then
        return
    end
    local visuals = rawget(_G, "FluxRaidVisuals") or {}
    local base = visuals.FRAME_BASE_ALPHA or 1
    local inAlpha = base * (visuals.RANGE_ALPHA_IN_RANGE or 0.9)
    local outAlpha = base * (visuals.RANGE_ALPHA_OUT_OF_RANGE or 0.44)
    local inRange = ReadUnitInRange(unit)
    -- issecretvalue first so a later nil check never touches a secret boolean.
    if frame.SetAlphaFromBoolean then
        if IsSecretValue(inRange) or inRange ~= nil then
            pcall(frame.SetAlphaFromBoolean, frame, inRange, inAlpha, outAlpha)
        else
            frame:SetAlpha(inAlpha)
        end
        return
    end
    if FluxRaidCompat.GetOutOfRange(frame) then
        frame:SetAlpha(outAlpha)
    else
        frame:SetAlpha(inAlpha)
    end
end

--- Build visible group index list scanning 8 → 1 (feeds reverse column placement).
--- predicate(g) → true when group g should appear as a column.
function FluxRaidCompat.BuildVisibleGroupsReverse(predicate)
    local visible = {}
    for g = GROUP_COUNT, 1, -1 do
        if predicate(g) then
            visible[#visible + 1] = g
        end
    end
    return visible
end

--- Reverse horizontal columns: group 1 rightmost, higher groups left, MT/MA further left.
--- visible: group indices already ordered from BuildVisibleGroupsReverse.
--- Returns { totalSlots, padSlots, x_lo, xMT, mtSlotWidth, groupX = {[g]=x}, k }.
function FluxRaidCompat.ComputeReverseColumnLayout(visible, mtShown, mtCount, colStep, opts)
    opts = opts or {}
    local groupCount = opts.groupCount or GROUP_COUNT
    local mtUpc = opts.mtUnitsPerColumn or MTMA_UNITS_PER_COLUMN
    local k = visible and #visible or 0
    mtCount = tonumber(mtCount) or 0
    colStep = tonumber(colStep) or 1

    local mtSlotWidth = 0
    if mtShown then
        mtSlotWidth = max(1, ceil(mtCount / mtUpc))
    end
    local mtColSlots = mtShown and mtSlotWidth or 0
    local baseSlots = groupCount + 1
    local usedSlots = mtColSlots + k
    local totalSlots = max(baseSlots, usedSlots)
    local padSlots = max(0, totalSlots - usedSlots)
    local x_lo = (k >= 1) and ((totalSlots - 1) * colStep) or nil
    local xMT = (mtShown and x_lo and k >= 1) and (padSlots * colStep) or 0

    local groupX = {}
    if x_lo and k >= 1 and visible then
        for j = 1, k do
            local g = visible[j]
            if g then
                groupX[g] = x_lo - (k - j) * colStep
            end
        end
    end

    return {
        totalSlots = totalSlots,
        padSlots = padSlots,
        x_lo = x_lo,
        xMT = xMT,
        mtSlotWidth = mtSlotWidth,
        groupX = groupX,
        k = k,
    }
end

function FluxRaidCompat.IsSecret(v)
    return IsSecretValue(v)
end

function FluxRaidCompat.PlainBool(value, default)
    return SafeBooleanTest(value, default)
end

function FluxRaidCompat.HasHealthPercent()
    return type(UnitHealthPercent) == "function"
        and CurveConstants
        and CurveConstants.ScaleTo100 ~= nil
end

function FluxRaidCompat.HasPowerPercent()
    return type(UnitPowerPercent) == "function"
        and CurveConstants
        and CurveConstants.ScaleTo100 ~= nil
end

function FluxRaidCompat.HasPrivateAuraContainer()
    return rawget(_G, "ContainerPrivateAuraBehaviorMixin") ~= nil
        and rawget(_G, "CompactRaidGroupTypeEnum") ~= nil
        and C_UnitAuras
        and type(C_UnitAuras.AddPrivateAuraAnchor) == "function"
        and type(C_UnitAuras.RemovePrivateAuraAnchor) == "function"
end

function FluxRaidCompat.HasRangeAlphaBoolean(frame)
    return frame and type(frame.SetAlphaFromBoolean) == "function"
end

--- 0–100 health for StatusBar:SetValue. Secret values are returned untouched.
--- Classic fallback divides only when both ends are plain numbers.
function FluxRaidCompat.GetHealthPercent(unit)
    if type(unit) ~= "string" or unit == "" then
        return nil
    end
    local a = API()
    if a.GetHealthPercent100 then
        local ok, v = pcall(a.GetHealthPercent100, unit)
        if ok and v ~= nil then
            return v
        end
    end
    if GetHealthPercent100 then
        local ok, v = pcall(GetHealthPercent100, unit)
        if ok and v ~= nil then
            return v
        end
    end
    if FluxRaidCompat.HasHealthPercent() then
        local ok, v = pcall(UnitHealthPercent, unit, true, CurveConstants.ScaleTo100)
        if ok then
            return v
        end
    end
    if not UnitHealth or not UnitHealthMax then
        return nil
    end
    local okH, h = pcall(UnitHealth, unit)
    local okM, m = pcall(UnitHealthMax, unit)
    if not okH or not okM or IsSecretValue(h) or IsSecretValue(m) then
        return nil
    end
    if type(h) ~= "number" or type(m) ~= "number" or m <= 0 then
        return nil
    end
    return (h / m) * 100
end

function FluxRaidCompat.GetPowerPercent(unit, powerType)
    if type(unit) ~= "string" or unit == "" then
        return nil
    end
    local a = API()
    if a.GetPowerPercent100 then
        local ok, v = pcall(a.GetPowerPercent100, unit, powerType)
        if ok and v ~= nil then
            return v
        end
    end
    if GetPowerPercent100 then
        local ok, v = pcall(GetPowerPercent100, unit, powerType)
        if ok and v ~= nil then
            return v
        end
    end
    if FluxRaidCompat.HasPowerPercent() then
        local ok, v = pcall(UnitPowerPercent, unit, powerType, true, CurveConstants.ScaleTo100)
        if ok then
            return v
        end
    end
    if not UnitPower or not UnitPowerMax then
        return nil
    end
    local okP, p = pcall(UnitPower, unit, powerType)
    local okM, m = pcall(UnitPowerMax, unit, powerType)
    if not okP or not okM or IsSecretValue(p) or IsSecretValue(m) then
        return nil
    end
    if type(p) ~= "number" or type(m) ~= "number" or m <= 0 then
        return nil
    end
    return (p / m) * 100
end

_G.FluxRaidCompat = FluxRaidCompat
_G.FluxRaidState = FluxRaidState
