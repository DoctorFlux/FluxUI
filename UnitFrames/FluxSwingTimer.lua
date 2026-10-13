local addonName, ns = ...
ns.SwingTimer = {}
local ST = ns.SwingTimer
local API = ns.API
local Border = ns.Border

local function FluxCap()
    return ns.Flux and ns.Flux.Cap
end

local function SwingTimerClientSupported()
    local cap = FluxCap()
    if cap and cap.disableSwingTimer ~= nil then
        return not cap.disableSwingTimer
    end
    if FLUX_API and FLUX_API.disableSwingTimer ~= nil then
        return not FLUX_API.disableSwingTimer
    end
    return true
end

local function HasCombatLogUnfiltered()
    local cap = FluxCap()
    if cap and cap.hasCombatLogUnfiltered ~= nil then
        return cap.hasCombatLogUnfiltered and true or false
    end
    if FLUX_API and FLUX_API.hasCombatLogUnfiltered ~= nil then
        return FLUX_API.hasCombatLogUnfiltered and true or false
    end
    return true
end

-- Forever/camelot: C_SwingTimer + PLAYER_SWING(duration, Enum.PlayerSwingType).
local function UseNativePlayerSwing()
    local cap = FluxCap()
    if cap and cap.hasNativePlayerSwing ~= nil then
        return cap.hasNativePlayerSwing and true or false
    end
    if FLUX_API and FLUX_API.hasNativePlayerSwing ~= nil then
        return FLUX_API.hasNativePlayerSwing and true or false
    end
    return false
end

local function UseEngineSwingTimer()
    if UseNativePlayerSwing() then
        return false
    end
    local cap = FluxCap()
    if not (cap and cap.hasDurationUtil and cap.hasStatusBarTimerDuration) then
        return false
    end
    return not HasCombatLogUnfiltered()
end

local function IsSecret(value)
    if API and API.IsSecretValue then
        return API.IsSecretValue(value) and true or false
    end
    local fn = issecretvalue or IsSecretValue
    if fn then
        local ok, res = pcall(fn, value)
        return ok and res and true or false
    end
    return false
end

local function KeepLastNumber(value, last, fallback)
    if API and API.KeepLastNumber then
        return API.KeepLastNumber(value, last, fallback)
    end
    local S = ns.Flux and ns.Flux.Secrets
    if S and S.KeepLastNumber then
        return S.KeepLastNumber(value, last, fallback)
    end
    fallback = fallback or 0
    if value == nil then
        return type(last) == "number" and last or fallback
    end
    if IsSecret(value) then
        return type(last) == "number" and last or fallback
    end
    local n = tonumber(value)
    if n == nil then
        return type(last) == "number" and last or fallback
    end
    return n
end

local function AccessibleEqual(a, b)
    if IsSecret(a) or IsSecret(b) then
        return false
    end
    return a == b
end

local function AccessibleGreater(a, b)
    if a == nil or b == nil then
        return false
    end
    if IsSecret(a) or IsSecret(b) then
        return false
    end
    return a > b
end

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local playerGUID
local mainSpeed, prevMainSpeed = 2, 2
local offSpeed, prevOffSpeed = 2, 2
local mainTimer, offTimer = 0, 0
local hasOffhand = false
local inCombat = false
local meleeAutoAttacking = false
local mainSwingStart, offSwingStart = 0, 0

local isAutoShotActive = false -- autorepeat on (Auto Shot / Shoot)
local rangedSpeed, prevRangedSpeed = 0, 0
local rangedTimer = 0
local hasRangedWeapon = false
local rangedSwingStart = 0
local lastRangedShotTime = 0 -- anchor for ranged countdown (WeaponSwingTimer hunter pattern)
local lastRangedShotFiredAt = 0 -- dedupe: SUCCEEDED + combat log can both fire for one shot
local prevEffRangedSpd = 0    -- effective ranged speed last frame (haste scaling)

-- Forever C_SwingTimer range: dim the one overlay when the shown swing type is OOR.
-- nil from IsTargetWithinSwingRange must not be treated as out of range.
local NATIVE_SWING_OOR_ALPHA = 0.4
local nativeShownTypeOutOfRange = false
local nativeRangeCheckOn = { mainHand = false, offHand = false, ranged = false }

-- WeaponSwingTimer default_settings.one_bar: false = single strip (two_bar visuals); true = cooldown + right clip segment.
local RANGED_WST_ONE_BAR = false

-- WeaponSwingTimer hunter default_settings one_bar colors (cooldown + auto_cast clip segment)
local WST_RANGED_COOLDOWN_RGBA = { 1.0, 1.0, 1.0, 1.0 }
local WST_RANGED_AUTO_CAST_RGBA = { 1.0, 0.0, 0.0, 1.0 }

local SPARK_RATIO_EPS = 0.002 -- hide at empty/full fill (matches WST spark at endpoints)

local swingFrame
local castBar
local mainBar, offBar
local mainSparkFrame, offSparkFrame
local rangedWSTFrame -- one_bar: shot_bar + auto_shot_cast_bar (WeaponSwingTimer_Hunter.lua)
local iconFrame, iconTexture
local swingText, swingTime
local barBorder, iconBorder
local swingVisible = false

-- Hold + fade when swing timer reaches "ready" (same idea as cast bar finish)
local swingHoldRemain = nil
local swingFadeOut = false
local swingFadeTimer = nil

local SWING_HOLD_AFTER_READY = 0.35  -- pause at full bar before fading (melee / hunter Auto Shot)
-- Wand "Shoot": brief hold at full bar when timer hits ready (while still autorepeating).
local SWING_HOLD_WAND_SHOOT_READY = 1.0
local SWING_FADE_DURATION = 1.0    -- match FluxCastBar CastStop fade

-- After STOP_AUTOREPEAT: keep ranged bar visible this long (timer keeps counting from preserved anchor), or until FluxCastBar needs the slot.
local SWING_RANGED_LINGER_AFTER_STOP = 5.0
local rangedSwingLingerRemain = nil

-- Melee: after swing completes, keep empty bar (0 fill) visible this long before fading — not full-bar flash / quick fade like ranged ready.
local SWING_MELEE_READY_EMPTY_LINGER = 5.0
local meleeReadyLingerRemain = nil

-- ---------------------------------------------------------------------------
-- Constants (icons resolved from spell data so they match spellbook / UI)
-- ---------------------------------------------------------------------------
local ATTACK_SPELL_ID = 6603   -- Attack (auto-attack toggle) — same icon as in-game "Attack"
local AUTO_SHOT_SPELL_ID = 75  -- Auto Shot (hunter)
local THROW_SPELL_ID = 2764    -- Throw
local BOW_SHOOT_SPELL_ID = 2480
local GUN_SHOOT_SPELL_ID = 7918
local CROSSBOW_SHOOT_SPELL_ID = 7919
local WAND_SHOOT_SPELL_ID = 5019
local SHOOT_SPELL_NAME = "Shoot"

-- HostileTargetingActionBar: ranged slot subclass → auto-attack spell. Numeric
-- fallbacks match Enum.ItemWeaponSubclass (Bows=2, Guns=3, Thrown=16, Crossbow=18, Wand=19).
local SHOOT_RANGED_WEAPON_SPELL_ID_MAPPING = {
    [2] = BOW_SHOOT_SPELL_ID,
    [3] = GUN_SHOOT_SPELL_ID,
    [16] = THROW_SPELL_ID,
    [18] = CROSSBOW_SHOOT_SPELL_ID,
    [19] = WAND_SHOOT_SPELL_ID,
}
do
    local sub = Enum and Enum.ItemWeaponSubclass
    if sub then
        if sub.Bows then SHOOT_RANGED_WEAPON_SPELL_ID_MAPPING[sub.Bows] = BOW_SHOOT_SPELL_ID end
        if sub.Guns then SHOOT_RANGED_WEAPON_SPELL_ID_MAPPING[sub.Guns] = GUN_SHOOT_SPELL_ID end
        if sub.Thrown then SHOOT_RANGED_WEAPON_SPELL_ID_MAPPING[sub.Thrown] = THROW_SPELL_ID end
        if sub.Crossbow then SHOOT_RANGED_WEAPON_SPELL_ID_MAPPING[sub.Crossbow] = CROSSBOW_SHOOT_SPELL_ID end
        if sub.Wand then SHOOT_RANGED_WEAPON_SPELL_ID_MAPPING[sub.Wand] = WAND_SHOOT_SPELL_ID end
    end
end

local wandShootSpellId -- resolved once from C_Spell (Retail Shoot spell id)
local function GetWandShootSpellID()
    if wandShootSpellId then return wandShootSpellId end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(SHOOT_SPELL_NAME)
        if info and info.spellID and not IsSecret(info.spellID) and info.spellID ~= 0 then
            wandShootSpellId = info.spellID
            return wandShootSpellId
        end
    end
    wandShootSpellId = 5019
    return wandShootSpellId
end

-- Fallback file IDs if spell APIs are unavailable
local FALLBACK_ATTACK_ICON = 132355
local FALLBACK_AUTOSHOT_ICON = 132208

--- Texture path or file ID for a spell's icon (matches action bar / spellbook).
local function GetSpellIconTexture(spellID)
    if not spellID then return nil end
    local _, _, iconID = API.GetSpellInfo(spellID)
    if iconID then
        return iconID
    end
    if C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex then return tex end
    end
    if GetSpellTexture then
        return GetSpellTexture(spellID)
    end
    return nil
end

local function ApplySpellIcon(texture, spellID, fallbackFileID)
    if not texture then return end
    local tex = GetSpellIconTexture(spellID)
    if tex then
        texture:SetTexture(tex)
    elseif fallbackFileID then
        texture:SetTexture(fallbackFileID)
    end
end

local SWING_COLOR_MAIN   = { 0.85, 0.85, 0.85 }
local SWING_COLOR_OFF    = { 0.65, 0.65, 0.85 }

-- Legacy / atlas compat (mirrors FluxCastBar)
local isLegacyClient = IsWoWLegacyClient and IsWoWLegacyClient() or false
local hasAtlasSupport = false
if C_Texture and C_Texture.GetAtlasInfo then
    hasAtlasSupport = C_Texture.GetAtlasInfo("ui-castingbar-filling-standard") ~= nil
end

local function SetAtlasLegacy(texture, atlasName)
    if isLegacyClient or not hasAtlasSupport then
        texture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        texture:SetTexCoord(0, 1, 0, 1)
        return
    end
    if texture.SetAtlas then
        texture:SetTexture(nil)
        local info = C_Texture.GetAtlasInfo(atlasName)
        if info then
            texture:SetAtlas(atlasName)
        else
            texture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
            texture:SetTexCoord(0, 1, 0, 1)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Speed helpers (KeepLastNumber: live speed when accessible, else last plain cache)
-- ---------------------------------------------------------------------------
local OFFHAND_SLOT = 17
local MAINHAND_SLOT = 16
local RANGED_SLOT = (INVSLOT_RANGED ~= nil) and INVSLOT_RANGED or 18

local function InventoryHasOffhandWeapon()
    if not GetInventoryItemID then
        return nil
    end
    local id = GetInventoryItemID("player", OFFHAND_SLOT)
    if id == nil then
        return false
    end
    if IsSecret(id) then
        return nil
    end
    if id == 0 then
        return false
    end
    local class, sub
    if GetItemInfo then
        local ok, _, _, _, _, _, _, _, _, _, _, _, itemClass, itemSub = pcall(GetItemInfo, id)
        if ok then
            class, sub = itemClass, itemSub
        end
    end
    if class == nil then
        return nil
    end
    if IsSecret(class) or IsSecret(sub) then
        return nil
    end
    -- 2 = Weapon. Shields / off-hand frills are armor / misc, not a swinging weapon.
    if class ~= 2 then
        return false
    end
    return true
end

local function UpdateMainSpeed()
    prevMainSpeed = mainSpeed
    local mh = UnitAttackSpeed and UnitAttackSpeed("player") or nil
    if mh ~= nil and not IsSecret(mh) then
        local n = tonumber(mh)
        if n == 0 then
            mainSpeed = 2
            return
        end
    end
    mainSpeed = KeepLastNumber(mh, mainSpeed, 2)
    if mainSpeed == 0 then
        mainSpeed = 2
    end
end

local function UpdateOffSpeed()
    prevOffSpeed = offSpeed
    local _, off
    if UnitAttackSpeed then
        _, off = UnitAttackSpeed("player")
    end
    if off == nil then
        local inv = InventoryHasOffhandWeapon()
        if inv == true then
            hasOffhand = true
            offSpeed = KeepLastNumber(nil, offSpeed, 2)
        elseif inv == false then
            hasOffhand = false
            offSpeed = 2
        end
        return
    end
    if IsSecret(off) then
        local inv = InventoryHasOffhandWeapon()
        if inv == true then
            hasOffhand = true
            offSpeed = KeepLastNumber(nil, offSpeed, 2)
        elseif inv == false then
            hasOffhand = false
            offSpeed = 2
        end
        -- inv nil: keep last hasOffhand / offSpeed
        return
    end
    if off == 0 then
        hasOffhand = false
        offSpeed = 2
    else
        hasOffhand = true
        offSpeed = KeepLastNumber(off, offSpeed, 2)
        if offSpeed == 0 then
            offSpeed = 2
        end
    end
end

local function UpdateRangedSpeed()
    prevRangedSpeed = rangedSpeed
    -- Forever: UnitAttackSpeed third return is whether wand/bow/gun/throw exists.
    if UseNativePlayerSwing() then
        local ranged
        if UnitAttackSpeed then
            _, _, ranged = UnitAttackSpeed("player")
        end
        if ranged == nil then
            hasRangedWeapon = false
            rangedSpeed = 0
            return
        end
        if IsSecret(ranged) then
            return
        end
        if ranged == 0 then
            hasRangedWeapon = false
            rangedSpeed = 0
            return
        end
        hasRangedWeapon = true
        rangedSpeed = KeepLastNumber(ranged, rangedSpeed, 0)
        return
    end
    if not UnitRangedDamage then
        return
    end
    local spd = UnitRangedDamage("player")
    if spd ~= nil and not IsSecret(spd) then
        local n = tonumber(spd)
        if n == 0 then
            rangedSpeed = 0
            hasRangedWeapon = false
            return
        end
    end
    rangedSpeed = KeepLastNumber(spd, rangedSpeed, 0)
    hasRangedWeapon = type(rangedSpeed) == "number" and rangedSpeed > 0
end

--- Ranged attack interval: Forever uses UnitAttackSpeed ranged; Classic bow/gun use
--- UnitRangedDamage and wand falls back to main-hand swing speed.
local function GetEffectiveRangedWeaponSpeed()
    UpdateRangedSpeed()
    if rangedSpeed and rangedSpeed > 0 then
        return rangedSpeed
    end
    if UseNativePlayerSwing() then
        return 0
    end
    UpdateMainSpeed()
    return (mainSpeed and mainSpeed > 0) and mainSpeed or 1
end

local function PlayerMainHandIsWand()
    if not GetInventoryItemID then
        return false
    end
    local id = GetInventoryItemID("player", MAINHAND_SLOT)
    if not id or IsSecret(id) or id == 0 then
        return false
    end
    local class, sub
    if GetItemInfo then
        local ok, _, _, _, _, _, _, _, _, _, _, _, itemClass, itemSub = pcall(GetItemInfo, id)
        if ok then
            class, sub = itemClass, itemSub
        end
    end
    if class == nil or IsSecret(class) or IsSecret(sub) then
        return false
    end
    return class == 2 and sub == 19 -- Weapon, Wand
end

local function GetPlayerClassFile()
    local class
    if UnitClassBase then
        class = UnitClassBase("player")
    else
        _, class = UnitClass("player")
    end
    if class == nil or IsSecret(class) then
        return nil
    end
    return class
end

--- Forever ranged weapons live in INVSLOT_RANGED (not main hand).
local function GetRangedSlotWeaponSubclass()
    if not GetInventoryItemID then
        return nil
    end
    local id = GetInventoryItemID("player", RANGED_SLOT)
    if not id or IsSecret(id) or id == 0 then
        return nil
    end
    if C_Item and C_Item.GetItemInfoInstant then
        local ok, _, _, _, _, _, itemClassID, itemSubclassID = pcall(C_Item.GetItemInfoInstant, id)
        if ok and itemClassID ~= nil and not IsSecret(itemClassID) and not IsSecret(itemSubclassID) then
            if itemClassID == (Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2) then
                return itemSubclassID
            end
            return nil
        end
    end
    if GetItemInfo then
        local ok, _, _, _, _, _, _, _, _, _, _, _, itemClass, itemSub = pcall(GetItemInfo, id)
        if ok and itemClass ~= nil and not IsSecret(itemClass) and not IsSecret(itemSub) then
            if itemClass == 2 then
                return itemSub
            end
        end
    end
    return nil
end

--- Forever Shoot / Auto Shot / Throw id from the ranged slot (HostileTargetingActionBar).
local function GetNativeRangedAutoAttackSpellID()
    if GetPlayerClassFile() == "HUNTER" then
        return AUTO_SHOT_SPELL_ID
    end
    local sub = GetRangedSlotWeaponSubclass()
    if sub == nil then
        return nil
    end
    return SHOOT_RANGED_WEAPON_SPELL_ID_MAPPING[sub]
end

local function PlayerRangedSlotIsWand()
    local sid = GetNativeRangedAutoAttackSpellID()
    return sid == WAND_SHOOT_SPELL_ID or sid == GetWandShootSpellID()
end

-- Wind-up before a shot fires.
-- TBC WeaponSwingTimer_Hunter: MAGE/PRIEST/WARLOCK use fixed 0.52; hunter uses 0.52 * haste modifier.
-- Retail Flux: wand matches caster branch (fixed 0.52); hunter uses 0.65.
local function GetEffectiveAutoCastTime()
    if PlayerMainHandIsWand() then
        return 0.52
    end
    return 0.65
end

--- Localized spell name for ID (Retail C_Spell vs legacy API).
local function GetSpellNameByID(spellID)
    if not spellID or spellID == 0 then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then return info.name end
    end
    return API.GetSpellInfo(spellID)
end

--- Auto Shot / Shoot (wand): spell id first (secret-safe); names only when accessible.
local function IsShootRangedSpell(spellID, spellName)
    if spellID ~= nil and not IsSecret(spellID) then
        if spellID == AUTO_SHOT_SPELL_ID then
            return true
        end
        local wandSid = GetWandShootSpellID()
        if wandSid and spellID == wandSid then
            return true
        end
    end
    if spellName ~= nil and spellName ~= "" and not IsSecret(spellName) then
        if spellName == "Auto Shot" or spellName == SHOOT_SPELL_NAME then
            return true
        end
        local autoLoc = GetSpellNameByID(AUTO_SHOT_SPELL_ID)
        if autoLoc and not IsSecret(autoLoc) and spellName == autoLoc then
            return true
        end
        local shootLoc = GetSpellNameByID(GetWandShootSpellID())
        if shootLoc and not IsSecret(shootLoc) and spellName == shootLoc then
            return true
        end
    end
    return false
end

--- Player cast/channel spell id + name (9th/8th returns match FluxCastBar).
local function GetPlayerCastOrChannelSpellIDAndName()
    local n, _, _, _, _, _, _, _, sid = UnitCastingInfo("player")
    if n then return sid, n end
    n, _, _, _, _, _, _, sid = UnitChannelInfo("player")
    if n then return sid, n end
    return nil, nil
end

--- Matches WeaponSwingTimer hunter UpdateAutoShotTimer: clip resets when moving OR casting (non Auto Shot / Shoot).
--- Movement: ignore tiny GetUnitSpeed noise while standing still (Retail often reports ~1e-9 or brief jitter).
local RANGED_CLIP_MOVEMENT_SPEED_EPS = 0.05

--- Must not treat missing spellID as "always clip" — Retail can omit id while Shoot is active (localized name still set).
--- Midnight: skip movement clip when GetUnitSpeed is secret (cannot compare combat stats).
local function IsRangedClipResetFromWSTMovementOrCast()
    if GetUnitSpeed then
        local move = GetUnitSpeed("player")
        if AccessibleGreater(move, RANGED_CLIP_MOVEMENT_SPEED_EPS) then
            return true
        end
    end
    local sid, sname = GetPlayerCastOrChannelSpellIDAndName()
    if IsSecret(sname) then
        return false
    end
    if not sname then return false end
    return not IsShootRangedSpell(sid, sname)
end

--- One shot can trigger UNIT_SPELLCAST_SUCCEEDED and COMBAT_LOG; only advance anchor once (WST uses one last_shot_time).
local RANGED_SHOT_FIRED_DEDUPE_SEC = 0.08

local function MarkRangedShotFired(durationOverride)
    local t = GetTime()
    if t - lastRangedShotFiredAt < RANGED_SHOT_FIRED_DEDUPE_SEC then
        return
    end
    lastRangedShotFiredAt = t
    lastRangedShotTime = t
    -- WST: refresh ranged speed from UnitRangedDamage after each shot (wand + hunter). Do not rewrite
    -- lastRangedShotTime elsewhere from per-frame speed jitter — that was skipping the white bar to 0.
    UpdateRangedSpeed()
    local fromEvent = KeepLastNumber(durationOverride, nil, 0)
    if fromEvent > 0 then
        rangedSpeed = fromEvent
    end
    prevEffRangedSpd = (rangedSpeed and rangedSpeed > 0) and rangedSpeed or 0
end

local function GetRangedSwingLabelAndSpellID()
    if UseNativePlayerSwing() then
        local sid = GetNativeRangedAutoAttackSpellID()
        if not sid then
            return "Auto Shot", AUTO_SHOT_SPELL_ID
        end
        local name = GetSpellNameByID(sid)
        if name and not IsSecret(name) then
            return name, sid
        end
        if sid == AUTO_SHOT_SPELL_ID then
            return "Auto Shot", sid
        end
        if sid == THROW_SPELL_ID then
            return "Throw", sid
        end
        return SHOOT_SPELL_NAME, sid
    end
    if PlayerMainHandIsWand() then
        return SHOOT_SPELL_NAME, GetWandShootSpellID()
    end
    return "Auto Shot", AUTO_SHOT_SPELL_ID
end

--- WeaponSwingTimer hunter ResetShotTimer — maps to lastRangedShotTime (remaining = spd - (now - last))
--- TBC WST uses 0.05 margin in the first branch; retail hunter keeps 0.01.
local function ResetRangedShotTimer()
    local curr_time = GetTime()
    local range_speed = GetEffectiveRangedWeaponSpeed()
    if range_speed <= 0 then range_speed = 0.001 end
    local act = GetEffectiveAutoCastTime()
    local margin = PlayerMainHandIsWand() and 0.05 or 0.01
    if (curr_time + margin - lastRangedShotTime) > (range_speed - act) then
        lastRangedShotTime = curr_time - range_speed + act
    elseif curr_time ~= lastRangedShotTime then
        lastRangedShotTime = curr_time - range_speed + (curr_time - lastRangedShotTime)
    else
        lastRangedShotTime = curr_time - range_speed + range_speed
    end
end

--- Progress spark at fill edge (WeaponSwingTimer player + FluxCastBar-style ratio).
local function PositionSwingSpark(sparkLayerFrame, sparkTex, curVal, maxVal)
    if not sparkLayerFrame or not sparkTex then return end
    if IsSecret(curVal) or IsSecret(maxVal) then
        sparkTex:Hide()
        return
    end
    if not maxVal or maxVal <= 0 then
        sparkTex:Hide()
        return
    end
    local ratio = curVal / maxVal
    ratio = math.max(0, math.min(1, ratio))
    if ratio <= SPARK_RATIO_EPS or ratio >= 1 - SPARK_RATIO_EPS then
        sparkTex:Hide()
        return
    end
    local w = sparkLayerFrame:GetWidth()
    if IsSecret(w) or not w or w <= 0 then
        sparkTex:Hide()
        return
    end
    sparkTex:ClearAllPoints()
    sparkTex:SetPoint("CENTER", sparkLayerFrame, "LEFT", ratio * w, 0)
    sparkTex:Show()
end

local function HideMeleeSparks()
    if mainSparkFrame and mainSparkFrame.spark then mainSparkFrame.spark:Hide() end
    if offSparkFrame and offSparkFrame.spark then offSparkFrame.spark:Hide() end
end

-- Forward declaration: UpdateSwingLayout / SwingTimer_OnUpdate run before these are assigned.
local ResizeSparkTexturesForBars
local UpdateRangedWSTVisuals

local function ApplyEngineSwingDuration(bar, startTime, durationSec)
    if not bar or not UseEngineSwingTimer() then
        return false
    end
    if not bar.SetTimerDuration or not C_DurationUtil or not C_DurationUtil.CreateDuration then
        return false
    end
    if type(startTime) ~= "number" or type(durationSec) ~= "number" or durationSec <= 0 then
        return false
    end
    local dur = bar._fluxSwingDuration
    if not dur then
        local ok, obj = pcall(C_DurationUtil.CreateDuration)
        if not ok or not obj then
            return false
        end
        dur = obj
        bar._fluxSwingDuration = dur
    end
    local setOk = pcall(dur.SetTimeFromStart, dur, startTime, durationSec)
    if not setOk then
        return false
    end
    local direction = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime
    local interpolation = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or 0
    local ok = pcall(bar.SetTimerDuration, bar, dur, interpolation, direction)
    return ok and true or false
end

-- ---------------------------------------------------------------------------
-- Timer resets
-- ---------------------------------------------------------------------------
local function ResetMainTimer(duration)
    UpdateMainSpeed()
    local speed = KeepLastNumber(duration, mainSpeed, 2)
    if speed <= 0 then
        speed = (type(mainSpeed) == "number" and mainSpeed > 0) and mainSpeed or 2
    end
    if duration ~= nil then
        mainSpeed = speed
    end
    mainSwingStart = GetTime()
    mainTimer = speed
    ApplyEngineSwingDuration(mainBar, mainSwingStart, speed)
end

local function ResetOffTimer(duration)
    UpdateOffSpeed()
    local speed = KeepLastNumber(duration, offSpeed, 2)
    if duration ~= nil and speed > 0 then
        hasOffhand = true
        offSpeed = speed
    end
    if hasOffhand then
        offSwingStart = GetTime()
        offTimer = offSpeed
        ApplyEngineSwingDuration(offBar, offSwingStart, offSpeed)
    end
end

--- Forever PLAYER_SWING Ranged: duration is the next period (wand/bow/gun/throw/Auto Shot).
local function ResetRangedTimer(duration)
    UpdateRangedSpeed()
    local speed = KeepLastNumber(duration, rangedSpeed, 0)
    if speed <= 0 then
        speed = (type(rangedSpeed) == "number" and rangedSpeed > 0) and rangedSpeed or 0
    end
    if speed <= 0 then
        return
    end
    if duration ~= nil then
        rangedSpeed = speed
    end
    hasRangedWeapon = true
    rangedSwingStart = GetTime()
    rangedTimer = speed
end

local function ZeroTimers()
    mainTimer = 0
    offTimer = 0
    rangedTimer = 0
    lastRangedShotTime = 0
    lastRangedShotFiredAt = 0
    prevEffRangedSpd = 0
    meleeReadyLingerRemain = nil
    mainSwingStart = 0
    offSwingStart = 0
    rangedSwingStart = 0
end

-- ---------------------------------------------------------------------------
-- Swing-reset spells (next-melee-swing abilities that reset the MH timer)
-- Names: CLEU path only, and only when the name is not secret.
-- IDs: Midnight UNIT_SPELLCAST_SUCCEEDED (rankless / current spell IDs).
-- ---------------------------------------------------------------------------
local swingResetSpells = {
    ["Heroic Strike"] = true,
    ["Cleave"]        = true,
    ["Maul"]          = true,
    ["Raptor Strike"] = true,
    ["Slam"]          = true,
}

local swingResetSpellIDs = {
    [78] = true,   -- Heroic Strike
    [845] = true,  -- Cleave
    [6807] = true, -- Maul
    [2973] = true, -- Raptor Strike
    [1464] = true, -- Slam
}

local function IsSwingResetSpell(spellID, spellName)
    if spellID ~= nil and not IsSecret(spellID) and swingResetSpellIDs[spellID] then
        return true
    end
    if spellName ~= nil and not IsSecret(spellName) and swingResetSpells[spellName] then
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Cast bar has priority over swing timer: hide swing only while an active cast
-- (or pre-interrupt grace) uses the bar. After cast ends or interrupt, swing can
-- show immediately; swing is layered above the cast bar during fade/hold so it is
-- not hidden underneath a still-visible cast bar texture.
-- ---------------------------------------------------------------------------
local function CastBarIsBusy()
    if not castBar then return false end
    if castBar.casting or castBar.channeling then return true end
    if castBar.customTimer then return true end
    if castBar.preInterrupt then return true end
    if castBar.holdTime and castBar.holdTime > 0 then return true end
    if castBar.fadeOut then return true end
    -- Only block when the cast bar is actually on-screen.
    if not castBar:IsShown() or castBar:GetAlpha() <= 0.01 then
        return false
    end
    return false
end

local function SwingTimerFeatureWanted()
    if not SwingTimerClientSupported() then
        return false
    end
    if FluxUnitFrames_IsFeatureEnabled then
        return FluxUnitFrames_IsFeatureEnabled("swingTimer")
    end
    return true
end

--- Events (autorepeat, combat log) can run before player cast bar init; create overlay on first need.
local function EnsureSwingFrameAttached()
    if swingFrame then
        return true
    end
    if not SwingTimerFeatureWanted() then
        return false
    end
    local cb = castBar
    if not cb and ns.PlayerFrame and ns.PlayerFrame.CastBar then
        cb = ns.PlayerFrame.CastBar
    end
    if not cb or not ST.AttachToCastBar then
        return false
    end
    ST.AttachToCastBar(cb, "player")
    return swingFrame ~= nil
end

local function SyncSwingFrameLevel()
    if not swingFrame or not castBar then return end
    local cl = castBar:GetFrameLevel() or 0
    if castBar.casting or castBar.channeling or castBar.preInterrupt
        or (castBar.holdTime and castBar.holdTime > 0) or castBar.fadeOut then
        swingFrame:SetFrameLevel(math.max(0, cl - 1))
    else
        swingFrame:SetFrameLevel(cl + 1)
    end
end

local function ClearRangedSwingLinger()
    rangedSwingLingerRemain = nil
end

--- White bar phase: time until wind-up (can move). Red/wind-up phase: time until shot while standing still.
--- Forever native: remaining seconds from PLAYER_SWING duration (no clip phases).
local function SetRangedSwingTimeDisplay(timeFont, shotTimerRemaining)
    if not timeFont then return end
    if UseNativePlayerSwing() then
        if shotTimerRemaining > 0.05 then
            timeFont:SetFormattedText("%.1f", shotTimerRemaining)
        else
            timeFont:SetText("")
        end
        timeFont:Show()
        return
    end
    local act = GetEffectiveAutoCastTime()
    if shotTimerRemaining > 0.05 then
        if shotTimerRemaining > act + 0.01 then
            timeFont:SetFormattedText("%.1f move", shotTimerRemaining - act)
        else
            timeFont:SetFormattedText("%.1f still", shotTimerRemaining)
        end
        timeFont:Show()
    else
        timeFont:SetText("")
        timeFont:Show()
    end
end

local function HasMeleeSwingActive()
    return (mainTimer > 0) or (hasOffhand and offTimer > 0)
end

-- Ranged strip: Forever = PLAYER_SWING remaining, autorepeat, or post-stop linger.
-- Classic: autorepeat always; post-stop linger only while no melee swing is ticking.
local function ShouldShowRangedOverlay()
    if UseNativePlayerSwing() then
        if rangedTimer > 0 then return true end
        if isAutoShotActive then return true end
        if rangedSwingLingerRemain and rangedSwingLingerRemain > 0 then
            return not HasMeleeSwingActive()
        end
        return false
    end
    if isAutoShotActive then return true end
    if rangedSwingLingerRemain and rangedSwingLingerRemain > 0 then
        return not HasMeleeSwingActive()
    end
    return false
end

local function HasActiveTimer()
    if UseNativePlayerSwing() and rangedTimer > 0 then return true end
    if isAutoShotActive then return true end
    if rangedSwingLingerRemain and rangedSwingLingerRemain > 0 and not HasMeleeSwingActive() then return true end
    if mainTimer > 0 then return true end
    if hasOffhand and offTimer > 0 then return true end
    return false
end

local function NativePlayerSwingTypes()
    return Enum and Enum.PlayerSwingType
end

local function GetNativeShownSwingType()
    local types = NativePlayerSwingTypes()
    if not types then
        return nil
    end
    if ShouldShowRangedOverlay() then
        return types.Ranged
    end
    return types.MainHand
end

local function NativeOORTextColor()
    if RED_FONT_COLOR and RED_FONT_COLOR.GetRGB then
        return RED_FONT_COLOR:GetRGB()
    end
    return 1, 0.1, 0.1
end

local function ApplyNativeRangePresentation()
    if not UseNativePlayerSwing() or not swingFrame then
        return
    end
    if swingFadeOut or not swingVisible then
        return
    end
    local oor = nativeShownTypeOutOfRange == true
    swingFrame:SetAlpha(oor and NATIVE_SWING_OOR_ALPHA or 1)
    local r, g, b = 1, 1, 1
    if oor then
        r, g, b = NativeOORTextColor()
    end
    if swingText then swingText:SetTextColor(r, g, b) end
    if swingTime then swingTime:SetTextColor(r, g, b) end
end

local function SetNativeShownOutOfRange(isOutOfRange)
    nativeShownTypeOutOfRange = isOutOfRange == true
    ApplyNativeRangePresentation()
end

local function NativeIsTargetWithinSwingRange(swingType)
    if swingType == nil or not C_SwingTimer or not C_SwingTimer.IsTargetWithinSwingRange then
        return nil
    end
    local ok, isInRange = pcall(C_SwingTimer.IsTargetWithinSwingRange, swingType)
    if not ok or isInRange == nil or IsSecret(isInRange) then
        return nil
    end
    return isInRange
end

local function UpdateNativeRangeState()
    if not UseNativePlayerSwing() then
        SetNativeShownOutOfRange(false)
        return
    end
    local swingType = GetNativeShownSwingType()
    if swingType == nil then
        SetNativeShownOutOfRange(false)
        return
    end
    local isInRange = NativeIsTargetWithinSwingRange(swingType)
    -- nil must not be treated as out of range.
    SetNativeShownOutOfRange(isInRange == false)
end

local function SetNativeRangeCheck(key, swingType, enable)
    enable = enable and true or false
    if nativeRangeCheckOn[key] == enable then
        return
    end
    nativeRangeCheckOn[key] = enable
    if swingType == nil or not C_SwingTimer or not C_SwingTimer.EnableRangeCheck then
        return
    end
    pcall(C_SwingTimer.EnableRangeCheck, swingType, enable)
end

local function UpdateNativeRangeCheckRegistration()
    local types = NativePlayerSwingTypes()
    local wanted = UseNativePlayerSwing() and SwingTimerFeatureWanted()
    if not types or not wanted then
        SetNativeRangeCheck("mainHand", types and types.MainHand, false)
        SetNativeRangeCheck("offHand", types and types.OffHand, false)
        SetNativeRangeCheck("ranged", types and types.Ranged, false)
        SetNativeShownOutOfRange(false)
        return
    end
    SetNativeRangeCheck("mainHand", types.MainHand, true)
    SetNativeRangeCheck("offHand", types.OffHand, hasOffhand and true or false)
    SetNativeRangeCheck("ranged", types.Ranged, hasRangedWeapon and true or false)
    UpdateNativeRangeState()
end

-- ---------------------------------------------------------------------------
-- Visibility
-- Flux perf T2.4: previously the frame used SetAlpha(0) as "hidden" so the
-- OnUpdate would keep firing every frame even when the player had no swings
-- to track. We now Hide() the frame in idle states, which stops OnUpdate at
-- the engine level, and Show() from the existing event-driven paths
-- (ShowSwing is called from combat-log swing-start, autorepeat, UNIT_AURA-ish
-- transitions, and the ready-linger re-entry inside OnUpdate). When a swing
-- fires while hidden, ShowSwing re-shows the frame so OnUpdate resumes.
-- ---------------------------------------------------------------------------
local function CancelSwingFade()
    if swingFadeTimer then
        swingFadeTimer:Cancel()
        swingFadeTimer = nil
    end
    if swingFrame and swingFadeOut then
        UIFrameFadeRemoveFrame(swingFrame)
        swingFrame:SetAlpha(1)
        swingFadeOut = false
    end
end

local function FinishSwingFade()
    swingFadeOut = false
    swingFadeTimer = nil
    swingVisible = false
    if swingFrame then
        UIFrameFadeRemoveFrame(swingFrame)
        -- Flux perf T2.4: Hide() stops OnUpdate; alpha reset for the next show.
        swingFrame:SetAlpha(0)
        swingFrame:Hide()
    end
    if swingText then swingText:Hide() end
    if swingTime then swingTime:Hide() end
end

local function StartSwingFadeOut()
    if not swingFrame then return end
    if swingFadeTimer then
        swingFadeTimer:Cancel()
        swingFadeTimer = nil
    end
    UIFrameFadeRemoveFrame(swingFrame)
    swingFadeOut = true
    UIFrameFadeOut(swingFrame, SWING_FADE_DURATION, swingFrame:GetAlpha(), 0)
    swingFadeTimer = C_Timer.NewTimer(SWING_FADE_DURATION, function()
        if swingFadeOut then
            FinishSwingFade()
        end
    end)
end

local function ShowSwing()
    if not EnsureSwingFrameAttached() or not swingFrame then
        return
    end
    swingVisible = true
    SyncSwingFrameLevel()
    -- Flux perf T2.4: ensure Show() so OnUpdate resumes if previously hidden.
    swingFrame:SetAlpha(1)
    if not swingFrame:IsShown() then
        swingFrame:Show()
    end
    ApplyNativeRangePresentation()
end

--- Ranged ↔ melee: cancel ready-hold / fade immediately so the bar swaps modes on the same event frame.
local function ApplyInstantSwingVisibility()
    swingHoldRemain = nil
    CancelSwingFade()
    if not CastBarIsBusy() then
        ShowSwing()
    end
end

--- Instant hide (cast started, leaving world, etc.)
local function HideSwingImmediate()
    swingHoldRemain = nil
    meleeReadyLingerRemain = nil
    ClearRangedSwingLinger()
    CancelSwingFade()
    swingVisible = false
    if swingFrame then
        UIFrameFadeRemoveFrame(swingFrame)
        -- Flux perf T2.4: Hide() stops the OnUpdate ticker.
        swingFrame:SetAlpha(0)
        swingFrame:Hide()
    end
    if swingText then swingText:Hide() end
    if swingTime then swingTime:Hide() end
end

--- Same frame as cast start: cancel swing fade and hide (cast bar loads before this file; safe at runtime).
function ST.HideForCastBarClaim()
    HideSwingImmediate()
end

--- Cast bar finished hold/fade; reclaim slot if a swing timer is active.
function ST.OnCastBarSlotReleased()
    if CastBarIsBusy() then
        return
    end
    if HasActiveTimer() then
        ApplyInstantSwingVisibility()
    end
end

-- ---------------------------------------------------------------------------
-- Layout
-- ---------------------------------------------------------------------------
local function UpdateSwingLayout()
    EnsureSwingFrameAttached()
    if not swingFrame or not castBar then return end

    -- Cast bar can report invalid sizes before layout (e.g. width still icon-only); avoid negative inner sizes.
    local barWidth  = math.max(1, castBar:GetWidth() or 1)
    local barHeight = math.max(1, castBar:GetHeight() or 1)

    swingFrame:SetSize(barWidth, barHeight)
    swingFrame:ClearAllPoints()
    swingFrame:SetAllPoints(castBar)

    -- Icon sits to the LEFT of the bar, mirroring the cast bar icon position
    local iconSize = barHeight
    iconFrame:SetSize(iconSize, iconSize)
    iconFrame:ClearAllPoints()
    iconFrame:SetPoint("TOPRIGHT", swingFrame, "TOPLEFT", 0, 0)

    local innerWidth  = math.max(0, barWidth - 4)
    local innerHeight = math.max(0, barHeight - 4)

    if ShouldShowRangedOverlay() then
        mainBar:Hide()
        if rangedWSTFrame then
            rangedWSTFrame:ClearAllPoints()
            rangedWSTFrame:SetPoint("TOPLEFT", swingFrame, "TOPLEFT", 2, -2)
            rangedWSTFrame:SetPoint("BOTTOMRIGHT", swingFrame, "BOTTOMRIGHT", -2, 2)
            rangedWSTFrame:Show()
        end
        offBar:Hide()
    elseif hasOffhand then
        if rangedWSTFrame then rangedWSTFrame:Hide() end
        mainBar:Show()
        local halfH = math.floor(innerHeight / 2)
        local topH  = halfH
        local botH  = innerHeight - halfH

        mainBar:ClearAllPoints()
        mainBar:SetPoint("TOPLEFT", swingFrame, "TOPLEFT", 2, -2)
        mainBar:SetPoint("TOPRIGHT", swingFrame, "TOPRIGHT", -2, -2)
        mainBar:SetHeight(topH)
        if mainBar.fillTexture then mainBar.fillTexture:SetSize(innerWidth, topH) end
        if mainBar.bg then mainBar.bg:SetSize(innerWidth, topH) end
        mainBar:SetStatusBarColor(unpack(SWING_COLOR_MAIN))

        offBar:ClearAllPoints()
        offBar:SetPoint("BOTTOMLEFT", swingFrame, "BOTTOMLEFT", 2, 2)
        offBar:SetPoint("BOTTOMRIGHT", swingFrame, "BOTTOMRIGHT", -2, 2)
        offBar:SetHeight(botH)
        if offBar.fillTexture then offBar.fillTexture:SetSize(innerWidth, botH) end
        if offBar.bg then offBar.bg:SetSize(innerWidth, botH) end
        offBar:SetStatusBarColor(unpack(SWING_COLOR_OFF))
        offBar:Show()
    else
        if rangedWSTFrame then rangedWSTFrame:Hide() end
        mainBar:Show()
        mainBar:ClearAllPoints()
        mainBar:SetPoint("TOPLEFT", swingFrame, "TOPLEFT", 2, -2)
        mainBar:SetPoint("BOTTOMRIGHT", swingFrame, "BOTTOMRIGHT", -2, 2)
        if mainBar.fillTexture then mainBar.fillTexture:SetSize(innerWidth, innerHeight) end
        if mainBar.bg then mainBar.bg:SetSize(innerWidth, innerHeight) end
        mainBar:SetStatusBarColor(unpack(SWING_COLOR_MAIN))
        offBar:Hide()
    end

    ResizeSparkTexturesForBars()
    if ShouldShowRangedOverlay() then
        HideMeleeSparks()
    end
    if UseNativePlayerSwing() then
        UpdateNativeRangeState()
    end
end

local function UpdateIcon()
    if not iconTexture then return end
    if ShouldShowRangedOverlay() then
        local _, sid = GetRangedSwingLabelAndSpellID()
        ApplySpellIcon(iconTexture, sid, FALLBACK_AUTOSHOT_ICON)
    else
        ApplySpellIcon(iconTexture, ATTACK_SPELL_ID, FALLBACK_ATTACK_ICON)
    end
end

--- Melee swing ready (no next swing yet): empty fill at 0, not full bar.
local function PaintMeleeReadyEmptyAtZero()
    if not mainBar then return end
    if mainBar._fluxMeleeReadyPainted then
        return
    end
    mainBar._fluxMeleeReadyPainted = true
    local speed = (mainSpeed > 0) and mainSpeed or 1
    mainBar:SetMinMaxValues(0, speed)
    mainBar:SetValue(0)
    mainBar._fluxLastSwingValue = 0
    if hasOffhand and offBar and offBar:IsShown() then
        local oSpeed = (offSpeed > 0) and offSpeed or 1
        offBar:SetMinMaxValues(0, oSpeed)
        offBar:SetValue(0)
        offBar._fluxLastSwingValue = 0
    end
    HideMeleeSparks()
    if swingText then swingText:SetText("Attack"); swingText:Show() end
    if swingTime then swingTime:SetText(""); swingTime:Show() end
end

local function PaintMeleeActiveBars()
    local speed = (mainSpeed > 0) and mainSpeed or 1
    if mainBar then mainBar._fluxMeleeReadyPainted = nil end
    local engine = UseEngineSwingTimer()
    if not engine then
        mainBar:SetMinMaxValues(0, speed)
        if mainBar._fluxLastSwingValue ~= mainTimer then
            mainBar._fluxLastSwingValue = mainTimer
            mainBar:SetValue(mainTimer)
        end
        if hasOffhand and offBar and offBar:IsShown() then
            local oSpeed = (offSpeed > 0) and offSpeed or 1
            offBar:SetMinMaxValues(0, oSpeed)
            if offBar._fluxLastSwingValue ~= offTimer then
                offBar._fluxLastSwingValue = offTimer
                offBar:SetValue(offTimer)
            end
        end
    end

    PositionSwingSpark(mainSparkFrame, mainSparkFrame and mainSparkFrame.spark, mainTimer, speed)
    if hasOffhand and offBar and offBar:IsShown() then
        local oSpeed = (offSpeed > 0) and offSpeed or 1
        PositionSwingSpark(offSparkFrame, offSparkFrame and offSparkFrame.spark, offTimer, oSpeed)
    elseif offSparkFrame and offSparkFrame.spark then
        offSparkFrame.spark:Hide()
    end

    if swingText then swingText:SetText("Attack"); swingText:Show() end
    if swingTime then
        local t = hasOffhand and math.max(mainTimer, offTimer) or mainTimer
        if not IsSecret(t) and t > 0.05 then
            swingTime:SetFormattedText("%.1f", t)
        else
            swingTime:SetText("")
        end
        swingTime:Show()
    end
end

-- Auto-attack toggle (red sword). Does not mean a swing happened — OOR still
-- leaves this true. Real swing timers only start/reset on a swing.
local function BeginMeleeAutoAttack()
    meleeAutoAttacking = true
end

local function EndMeleeAutoAttack()
    meleeAutoAttacking = false
end

local ENGINE_MELEE_COMBAT_EVENTS = {
    WOUND = true,
    MISS = true,
    DODGE = true,
    PARRY = true,
    BLOCK = true,
    EVADE = true,
    ABSORB = true,
}

local function IsPhysicalCombatSchool(school)
    if school == nil or IsSecret(school) then
        return true
    end
    if Enum and Enum.Damageclass and Enum.Damageclass.MaskPhysical ~= nil then
        return school == Enum.Damageclass.MaskPhysical
    end
    if SCHOOL_MASK_PHYSICAL then
        return school == SCHOOL_MASK_PHYSICAL
    end
    return school == 1
end

-- Midnight has no CLEU. Target UNIT_COMBAT is the closest swing signal: it
-- fires on a real hit/miss, and does not fire while you stand OOR with
-- auto-attack still toggled on.
local function ResetMeleeHandFromCombatHit()
    if hasOffhand then
        if mainTimer <= 0.05 and offTimer > 0.05 then
            ResetMainTimer()
        elseif offTimer <= 0.05 and mainTimer > 0.05 then
            ResetOffTimer()
        elseif offTimer < mainTimer then
            ResetOffTimer()
        else
            ResetMainTimer()
        end
    else
        ResetMainTimer()
    end
end

local function OnEngineTargetCombat(unit, combatEvent, _, _, school)
    if not UseEngineSwingTimer() then
        return
    end
    if not meleeAutoAttacking or isAutoShotActive then
        return
    end
    if IsSecret(unit) or unit ~= "target" then
        return
    end
    if IsSecret(combatEvent) or not combatEvent then
        return
    end
    if not ENGINE_MELEE_COMBAT_EVENTS[combatEvent] then
        return
    end
    if not IsPhysicalCombatSchool(school) then
        return
    end
    ResetMeleeHandFromCombatHit()
    meleeReadyLingerRemain = nil
    ClearRangedSwingLinger()
    ApplyInstantSwingVisibility()
    UpdateSwingLayout()
    UpdateIcon()
end

-- ---------------------------------------------------------------------------
-- OnUpdate
-- ---------------------------------------------------------------------------
local function SwingTimer_OnUpdate(self, elapsed)
    -- Cast bar has priority: hide swing only while an active cast (or pre-interrupt) holds the slot.
    if CastBarIsBusy() then
        swingHoldRemain = nil
        HideSwingImmediate()
        return
    end

    SyncSwingFrameLevel()

    -- Fading after "swing ready": allow cancel if a new swing started (e.g. combat log) before fade ends
    if swingFadeOut then
        if HasActiveTimer() then
            CancelSwingFade()
            swingHoldRemain = nil
            -- continue into normal update below
        else
            return
        end
    end

    -- Transition detection for "ready" hold (exclude post-stop linger — it is not the same as timer emptying).
    -- hadMeleeSwingBefore: pre-decrement main/off timers (same frame swing completes to 0).
    local hadMeleeSwingBefore = (mainTimer > 0) or (hasOffhand and offTimer > 0)
    local hadRangedTimerBefore = rangedTimer > 0
    local hadActiveBefore
    if UseNativePlayerSwing() then
        hadActiveBefore = hadRangedTimerBefore or hadMeleeSwingBefore
    else
        hadActiveBefore = (isAutoShotActive and rangedTimer > 0) or hadMeleeSwingBefore
    end

    -- Haste scaling: adjust remaining timer when speed changes between frames.
    -- Forever PLAYER_SWING already carries haste-adjusted duration; do not rescale remaining.
    local oldMain, oldOff = mainSpeed, offSpeed
    UpdateMainSpeed()
    UpdateOffSpeed()

    if not UseNativePlayerSwing() then
        if mainTimer > 0 and oldMain > 0 and mainSpeed ~= oldMain then
            mainTimer = mainTimer * (mainSpeed / oldMain)
            if UseEngineSwingTimer() then
                ApplyEngineSwingDuration(mainBar, GetTime() - (mainSpeed - mainTimer), mainSpeed)
            end
        end
        if hasOffhand and offTimer > 0 and oldOff > 0 and offSpeed ~= oldOff then
            offTimer = offTimer * (offSpeed / oldOff)
            if UseEngineSwingTimer() then
                ApplyEngineSwingDuration(offBar, GetTime() - (offSpeed - offTimer), offSpeed)
            end
        end
    end

    -- Stop showing post-shoot linger once melee swing is active (wand → melee); anchor stays for next ranged session.
    if not isAutoShotActive and rangedSwingLingerRemain and HasMeleeSwingActive() then
        ClearRangedSwingLinger()
    end

    -- Ranged: Forever decrements PLAYER_SWING duration. Classic uses WST remaining + clip.
    local lingerExpiredFade = false
    if UseNativePlayerSwing() then
        if not isAutoShotActive and rangedSwingLingerRemain and rangedSwingLingerRemain > 0 and rangedTimer <= 0 then
            rangedSwingLingerRemain = rangedSwingLingerRemain - elapsed
            if rangedSwingLingerRemain <= 0 then
                rangedSwingLingerRemain = nil
                lingerExpiredFade = true
            end
        end
    elseif isAutoShotActive or (rangedSwingLingerRemain and rangedSwingLingerRemain > 0) then
        local spd = GetEffectiveRangedWeaponSpeed()
        local act = GetEffectiveAutoCastTime()
        -- Do NOT rewrite lastRangedShotTime every frame when UnitRangedDamage jitters by float noise — that
        -- jumps the white cooldown bar before it reaches 0. WST TBC only scales remaining time when ranged
        -- speed changes on Auto Shot success (see MarkRangedShotFired / hunter branch), not per OnUpdate.
        prevEffRangedSpd = spd
        rangedTimer = math.max(0, spd - (GetTime() - lastRangedShotTime))
        if isAutoShotActive and IsRangedClipResetFromWSTMovementOrCast() then
            if rangedTimer > 0 and rangedTimer <= act then
                ResetRangedShotTimer()
                spd = GetEffectiveRangedWeaponSpeed()
                rangedTimer = math.max(0, spd - (GetTime() - lastRangedShotTime))
            end
        end
        if not isAutoShotActive and rangedSwingLingerRemain and rangedSwingLingerRemain > 0 then
            rangedSwingLingerRemain = rangedSwingLingerRemain - elapsed
            if rangedSwingLingerRemain <= 0 then
                rangedSwingLingerRemain = nil
                lingerExpiredFade = true
            end
        end
    else
        prevEffRangedSpd = 0
    end

    if lingerExpiredFade then
        CancelSwingFade()
        ShowSwing()
        local speed = GetEffectiveRangedWeaponSpeed()
        if speed <= 0 then speed = 1 end
        if rangedWSTFrame then
            UpdateRangedWSTVisuals(speed, 0, true)
        end
        local rngLabel = select(1, GetRangedSwingLabelAndSpellID())
        if swingText then swingText:SetText(rngLabel); swingText:Show() end
        if swingTime then swingTime:SetText(""); swingTime:Show() end
        HideMeleeSparks()
        StartSwingFadeOut()
        return
    end

    -- Decrement swing timers (plain cached speeds — never secret arithmetic)
    if mainTimer > 0 then
        mainTimer = mainTimer - elapsed
        if mainTimer < 0 then mainTimer = 0 end
    end
    if hasOffhand and offTimer > 0 then
        offTimer = offTimer - elapsed
        if offTimer < 0 then offTimer = 0 end
    end
    if UseNativePlayerSwing() and rangedTimer > 0 then
        rangedTimer = rangedTimer - elapsed
        if rangedTimer < 0 then rangedTimer = 0 end
    end

    -- New swing / timer activity: cancel ready-state hold so bar can show again
    if HasActiveTimer() then
        swingHoldRemain = nil
        meleeReadyLingerRemain = nil
        ShowSwing()

        if ShouldShowRangedOverlay() then
            local speed = GetEffectiveRangedWeaponSpeed()
            if speed <= 0 then speed = 1 end
            if rangedTimer > 0.05 then
                UpdateRangedWSTVisuals(speed, rangedTimer, false)
                SetRangedSwingTimeDisplay(swingTime, rangedTimer)
            else
                UpdateRangedWSTVisuals(speed, 0, true)
                if swingTime then swingTime:SetText(""); swingTime:Show() end
            end
            local rngLabel = select(1, GetRangedSwingLabelAndSpellID())
            if swingText then swingText:SetText(rngLabel); swingText:Show() end
            HideMeleeSparks()
        else
            PaintMeleeActiveBars()
        end
        return
    end

    -- After a real swing completes, sit empty at 0 then fade. Auto-attack still
    -- being toggled on (including OOR) must not skip this — that was the
    -- Midnight metronome sitting on a fake next swing.
    if meleeReadyLingerRemain == nil and hadMeleeSwingBefore then
        meleeReadyLingerRemain = SWING_MELEE_READY_EMPTY_LINGER
        if mainBar then mainBar._fluxMeleeReadyPainted = nil end
    end

    if meleeReadyLingerRemain ~= nil then
        meleeReadyLingerRemain = meleeReadyLingerRemain - elapsed
        if meleeReadyLingerRemain <= 0 then
            meleeReadyLingerRemain = nil
            ShowSwing()
            PaintMeleeReadyEmptyAtZero()
            StartSwingFadeOut()
            return
        end
        ShowSwing()
        PaintMeleeReadyEmptyAtZero()
        return
    end

    -- Ranged / wand: brief hold at full ready, then fade (melee uses empty linger above)
    if hadActiveBefore and not hadMeleeSwingBefore then
        local wandHold = false
        if isAutoShotActive then
            if UseNativePlayerSwing() then
                wandHold = PlayerRangedSlotIsWand()
            else
                wandHold = PlayerMainHandIsWand()
            end
        end
        if wandHold then
            swingHoldRemain = SWING_HOLD_WAND_SHOOT_READY
        else
            swingHoldRemain = SWING_HOLD_AFTER_READY
        end
    end

    if swingHoldRemain ~= nil then
        swingHoldRemain = swingHoldRemain - elapsed
        if swingHoldRemain <= 0 then
            swingHoldRemain = nil
            ShowSwing()
            -- Full bar = ready to swing
            if isAutoShotActive then
                local speed = GetEffectiveRangedWeaponSpeed()
                if speed <= 0 then speed = 1 end
                UpdateRangedWSTVisuals(speed, 0, true)
                local rngLabel = select(1, GetRangedSwingLabelAndSpellID())
                if swingText then swingText:SetText(rngLabel); swingText:Show() end
                if swingTime then swingTime:SetText(""); swingTime:Show() end
                HideMeleeSparks()
            else
                local speed = (mainSpeed > 0) and mainSpeed or 1
                mainBar:SetMinMaxValues(0, speed)
                mainBar:SetValue(speed)
                if hasOffhand and offBar:IsShown() then
                    local oSpeed = (offSpeed > 0) and offSpeed or 1
                    offBar:SetMinMaxValues(0, oSpeed)
                    offBar:SetValue(oSpeed)
                end
                PositionSwingSpark(mainSparkFrame, mainSparkFrame and mainSparkFrame.spark, speed, speed)
                if hasOffhand and offBar:IsShown() then
                    local oSpeed = (offSpeed > 0) and offSpeed or 1
                    PositionSwingSpark(offSparkFrame, offSparkFrame and offSparkFrame.spark, oSpeed, oSpeed)
                elseif offSparkFrame and offSparkFrame.spark then
                    offSparkFrame.spark:Hide()
                end
                if swingText then swingText:SetText("Attack"); swingText:Show() end
                if swingTime then swingTime:SetText(""); swingTime:Show() end
            end
            StartSwingFadeOut()
            return
        end

        ShowSwing()
        if isAutoShotActive then
            local speed = GetEffectiveRangedWeaponSpeed()
            if speed <= 0 then speed = 1 end
            UpdateRangedWSTVisuals(speed, 0, true)
            local rngLabel = select(1, GetRangedSwingLabelAndSpellID())
            if swingText then swingText:SetText(rngLabel); swingText:Show() end
            if swingTime then swingTime:SetText(""); swingTime:Show() end
            HideMeleeSparks()
        else
            local speed = (mainSpeed > 0) and mainSpeed or 1
            mainBar:SetMinMaxValues(0, speed)
            mainBar:SetValue(speed)
            if hasOffhand and offBar:IsShown() then
                local oSpeed = (offSpeed > 0) and offSpeed or 1
                offBar:SetMinMaxValues(0, oSpeed)
                offBar:SetValue(oSpeed)
            end
            PositionSwingSpark(mainSparkFrame, mainSparkFrame and mainSparkFrame.spark, speed, speed)
            if hasOffhand and offBar:IsShown() then
                local oSpeed = (offSpeed > 0) and offSpeed or 1
                PositionSwingSpark(offSparkFrame, offSparkFrame and offSparkFrame.spark, oSpeed, oSpeed)
            elseif offSparkFrame and offSparkFrame.spark then
                offSparkFrame.spark:Hide()
            end
            if swingText then swingText:SetText("Attack"); swingText:Show() end
            if swingTime then swingTime:SetText(""); swingTime:Show() end
        end
        return
    end

    HideSwingImmediate()
end

-- ---------------------------------------------------------------------------
-- Combat log
-- ---------------------------------------------------------------------------
local function OnCombatLogEvent()
    if not HasCombatLogUnfiltered() then
        return
    end
    if not CombatLogGetCurrentEventInfo then
        return
    end
    local _, subevent, _, sourceGUID, _, _, _, _, _, _, _,
          arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21 = CombatLogGetCurrentEventInfo()

    if IsSecret(sourceGUID) or IsSecret(playerGUID) then
        return
    end
    if sourceGUID ~= playerGUID then return end
    if IsSecret(subevent) then
        return
    end

    -- Forever PLAYER_SWING already reset MH/OH; CLEU would double-reset.
    if UseNativePlayerSwing() and (subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED") then
        return
    end
    if UseNativePlayerSwing() and (subevent == "RANGE_DAMAGE" or subevent == "RANGE_MISSED") then
        return
    end

    if subevent == "SWING_DAMAGE" then
        -- arg21 = isOffHand
        if IsSecret(arg21) then
            ResetMainTimer()
        elseif arg21 then
            ResetOffTimer()
        else
            ResetMainTimer()
        end
        meleeReadyLingerRemain = nil
        ClearRangedSwingLinger()
        ApplyInstantSwingVisibility()
        UpdateSwingLayout()
        UpdateIcon()

    elseif subevent == "SWING_MISSED" then
        -- arg12 = missType, arg13 = isOffHand
        if IsSecret(arg13) then
            ResetMainTimer()
        elseif arg13 then
            ResetOffTimer()
        else
            ResetMainTimer()
        end
        meleeReadyLingerRemain = nil
        ClearRangedSwingLinger()
        ApplyInstantSwingVisibility()
        UpdateSwingLayout()
        UpdateIcon()

    elseif subevent == "RANGE_DAMAGE" or subevent == "RANGE_MISSED" then
        if isAutoShotActive then
            MarkRangedShotFired()
            UpdateSwingLayout()
        end

    elseif subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED" then
        local spellId, spellName = arg12, arg13
        if IsSwingResetSpell(spellId, spellName) then
            ResetMainTimer()
            meleeReadyLingerRemain = nil
            ClearRangedSwingLinger()
            ApplyInstantSwingVisibility()
            UpdateSwingLayout()
            UpdateIcon()
        elseif isAutoShotActive and IsShootRangedSpell(spellId, spellName) then
            MarkRangedShotFired()
            UpdateSwingLayout()
            UpdateIcon()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Event registration frame + combat-only CLEU (must be declared before OnEvent).
-- ---------------------------------------------------------------------------
local swingTimerEventFrame = CreateFrame("Frame", nil, UIParent)
local swingTimerEventsRegistered = false
local swingTimerCleuRegistered = false

local function RegisterSwingTimerCombatLog()
    if swingTimerCleuRegistered then return end
    if UseNativePlayerSwing() then return end
    if not HasCombatLogUnfiltered() then return end
    -- Flux perf T3.9: register CLEU only while in combat (highest event-rate subscription).
    pcall(function()
        swingTimerEventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        swingTimerCleuRegistered = true
    end)
end

local function UnregisterSwingTimerCombatLog()
    if not swingTimerCleuRegistered then return end
    pcall(function()
        swingTimerEventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        swingTimerCleuRegistered = false
    end)
end

function FluxSwingTimer_IsCleuRegistered()
    return swingTimerCleuRegistered
end

-- ---------------------------------------------------------------------------
-- Event handler
-- ---------------------------------------------------------------------------
local function FluxOverlayOwnsSwingTimer()
    if not SwingTimerClientSupported() or not UseNativePlayerSwing() then
        return false
    end
    local db = FluxOptions and FluxOptions.GetUnitFrameDB and FluxOptions:GetUnitFrameDB()
    if db and db.enableSwingTimer == false then
        return false
    end
    return true
end

local BLIZZARD_SWING_HUD_FRAMES = {
    "SwingTimerMainHandFrame",
    "SwingTimerOffHandFrame",
    "SwingTimerRangedFrame",
}

local function ParkBlizzardSwingTimerHud()
    if not FluxOverlayOwnsSwingTimer() then
        return
    end
    for i = 1, #BLIZZARD_SWING_HUD_FRAMES do
        local frame = _G[BLIZZARD_SWING_HUD_FRAMES[i]]
        if frame and not frame._fluxSwingHudParked then
            frame._fluxSwingHudParked = true
            pcall(function()
                if frame.UnregisterAllEvents then
                    frame:UnregisterAllEvents()
                end
            end)
            pcall(function()
                frame:Hide()
            end)
            if frame.HookScript then
                pcall(frame.HookScript, frame, "OnShow", function(self)
                    if self._fluxSwingHudParked then
                        self:Hide()
                    end
                end)
            end
        elseif frame and frame._fluxSwingHudParked then
            pcall(function()
                frame:Hide()
            end)
        end
    end
end

local function OnNativePlayerSwing(swingDuration, swingType)
    if not UseNativePlayerSwing() then
        return
    end
    if IsSecret(swingType) then
        return
    end
    local types = Enum and Enum.PlayerSwingType
    if not types then
        return
    end
    local duration = KeepLastNumber(swingDuration, nil, 0)
    if swingType == types.MainHand then
        ResetMainTimer(duration > 0 and duration or nil)
        meleeReadyLingerRemain = nil
        ClearRangedSwingLinger()
        ApplyInstantSwingVisibility()
        UpdateSwingLayout()
        UpdateIcon()
    elseif swingType == types.OffHand then
        ResetOffTimer(duration > 0 and duration or nil)
        meleeReadyLingerRemain = nil
        ClearRangedSwingLinger()
        ApplyInstantSwingVisibility()
        UpdateSwingLayout()
        UpdateIcon()
    elseif swingType == types.Ranged then
        ResetRangedTimer(duration > 0 and duration or nil)
        meleeReadyLingerRemain = nil
        ClearRangedSwingLinger()
        ApplyInstantSwingVisibility()
        UpdateSwingLayout()
        UpdateIcon()
    end
end

local function OnEvent(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLogEvent()

    elseif event == "PLAYER_SWING" then
        local swingDuration, swingType = ...
        OnNativePlayerSwing(swingDuration, swingType)

    elseif event == "PLAYER_SWING_RANGE_UPDATE" then
        local swingType, isInRange, checksRange = ...
        if not UseNativePlayerSwing() then
            return
        end
        if IsSecret(swingType) then
            return
        end
        if GetNativeShownSwingType() ~= swingType then
            return
        end
        if checksRange == false or IsSecret(checksRange) or IsSecret(isInRange) then
            if checksRange == false then
                SetNativeShownOutOfRange(false)
            end
            return
        end
        SetNativeShownOutOfRange(checksRange and not isInRange)

    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateNativeRangeState()

    elseif event == "WEAPON_SLOT_CHANGED" then
        local oldHasOff = hasOffhand
        local oldHasRanged = hasRangedWeapon
        UpdateMainSpeed()
        UpdateOffSpeed()
        UpdateRangedSpeed()
        UpdateNativeRangeCheckRegistration()
        if hasOffhand ~= oldHasOff or hasRangedWeapon ~= oldHasRanged then
            UpdateSwingLayout()
        end
        UpdateIcon()

    elseif event == "ADDON_LOADED" then
        local addonLoaded = ...
        if addonLoaded == "Blizzard_SwingTimer" then
            ParkBlizzardSwingTimerHud()
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        RegisterSwingTimerCombatLog()
        UpdateMainSpeed()
        UpdateOffSpeed()
        UpdateRangedSpeed()
        UpdateSwingLayout()
        UpdateIcon()
        if UseEngineSwingTimer() and not meleeAutoAttacking then
            local attacking = false
            if IsCurrentSpell then
                local ok, cur = pcall(IsCurrentSpell, ATTACK_SPELL_ID)
                if ok and cur ~= nil and not IsSecret(cur) and cur then
                    attacking = true
                end
            elseif C_Spell and C_Spell.IsCurrentSpell then
                local ok, cur = pcall(C_Spell.IsCurrentSpell, ATTACK_SPELL_ID)
                if ok and cur ~= nil and not IsSecret(cur) and cur then
                    attacking = true
                end
            end
            if attacking then
                BeginMeleeAutoAttack()
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        meleeAutoAttacking = false
        UnregisterSwingTimerCombatLog()
        ZeroTimers()
        isAutoShotActive = false
        HideSwingImmediate()

    elseif event == "PLAYER_ENTER_COMBAT" then
        BeginMeleeAutoAttack()

    elseif event == "PLAYER_LEAVE_COMBAT" then
        EndMeleeAutoAttack()

    elseif event == "UNIT_COMBAT" then
        local unit, combatEvent, flags, amount, school = ...
        OnEngineTargetCombat(unit, combatEvent, flags, amount, school)

    elseif event == "UNIT_ATTACK_SPEED" then
        local unit = ...
        if unit == "player" then
            local oldHasOff = hasOffhand
            local oldHasRanged = hasRangedWeapon
            UpdateMainSpeed()
            UpdateOffSpeed()
            UpdateRangedSpeed()
            if UseNativePlayerSwing() then
                UpdateNativeRangeCheckRegistration()
            end
            if hasOffhand ~= oldHasOff or hasRangedWeapon ~= oldHasRanged then
                UpdateSwingLayout()
            end
        end

    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit == "player" then
            local oldHasOff = hasOffhand
            local oldHasRanged = hasRangedWeapon
            UpdateMainSpeed()
            UpdateOffSpeed()
            UpdateRangedSpeed()
            if hasOffhand ~= oldHasOff or hasRangedWeapon ~= oldHasRanged then
                UpdateSwingLayout()
            end
            UpdateIcon()
        end

    elseif event == "START_AUTOREPEAT_SPELL" then
        ClearRangedSwingLinger()
        meleeReadyLingerRemain = nil
        isAutoShotActive = true
        ApplyInstantSwingVisibility()
        UpdateRangedSpeed()
        UpdateMainSpeed()
        if lastRangedShotTime == 0 then
            -- Classic CLEU path: first Auto Shot wind-up. Midnight must not
            -- start a fake period on autorepeat toggle (OOR still fires this).
            -- Forever PLAYER_SWING owns the first ranged reset.
            if not UseEngineSwingTimer() and not UseNativePlayerSwing() then
                ResetRangedShotTimer()
            end
        elseif not UseNativePlayerSwing() then
            local spd = GetEffectiveRangedWeaponSpeed()
            local remaining = math.max(0, spd - (GetTime() - lastRangedShotTime))
            if remaining <= GetEffectiveAutoCastTime() then
                ResetRangedShotTimer()
            end
        end
        UpdateSwingLayout()
        UpdateIcon()

    elseif event == "STOP_AUTOREPEAT_SPELL" then
        ApplyInstantSwingVisibility()
        rangedSwingLingerRemain = SWING_RANGED_LINGER_AFTER_STOP
        isAutoShotActive = false
        -- Keep lastRangedShotTime / prevEffRangedSpd so countdown continues after autorepeat stops (linger display).
        UpdateSwingLayout()
        UpdateIcon()

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit ~= "player" then
            return
        end
        -- Forever PLAYER_SWING owns melee/ranged resets; SUCCEEDED would double-fire.
        if UseNativePlayerSwing() then
            return
        end
        if isAutoShotActive then
            if IsShootRangedSpell(spellID, nil) then
                MarkRangedShotFired()
            end
        elseif IsSwingResetSpell(spellID, nil) then
            ResetMainTimer()
            meleeReadyLingerRemain = nil
            ClearRangedSwingLinger()
            ApplyInstantSwingVisibility()
            UpdateSwingLayout()
            UpdateIcon()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        playerGUID = UnitGUID("player")
        meleeAutoAttacking = false
        ZeroTimers()
        isAutoShotActive = false
        UpdateMainSpeed()
        UpdateOffSpeed()
        UpdateRangedSpeed()
        UpdateNativeRangeCheckRegistration()
        UpdateSwingLayout()
        UpdateIcon()
        HideSwingImmediate()
        ParkBlizzardSwingTimerHud()
    end
end

-- Bootstrapped on module load (never from AttachToCastBar).
-- Midnight (12.0+): addon restriction / taint can block RegisterEvent from unit-frame init paths;
-- use C_RestrictedActions + ADDON_RESTRICTION_STATE_CHANGED when needed.
local function ApplySwingTimerEventRegistration()
    swingTimerEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    swingTimerEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    pcall(function()
        swingTimerEventFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
    end)
    pcall(function()
        swingTimerEventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
    end)
    swingTimerEventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    swingTimerEventFrame:RegisterEvent("START_AUTOREPEAT_SPELL")
    swingTimerEventFrame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    swingTimerEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    swingTimerEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    pcall(function()
        swingTimerEventFrame:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player")
    end)
    pcall(function()
        swingTimerEventFrame:RegisterUnitEvent("UNIT_COMBAT", "target")
    end)
    if UseNativePlayerSwing() then
        pcall(function()
            swingTimerEventFrame:RegisterEvent("PLAYER_SWING")
        end)
        pcall(function()
            swingTimerEventFrame:RegisterEvent("PLAYER_SWING_RANGE_UPDATE")
        end)
        pcall(function()
            swingTimerEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        end)
        pcall(function()
            swingTimerEventFrame:RegisterEvent("WEAPON_SLOT_CHANGED")
        end)
        pcall(function()
            swingTimerEventFrame:RegisterEvent("ADDON_LOADED")
        end)
        ParkBlizzardSwingTimerHud()
        UpdateNativeRangeCheckRegistration()
    end
    swingTimerEventFrame:SetScript("OnEvent", OnEvent)
    if HasCombatLogUnfiltered() and InCombatLockdown and InCombatLockdown() then
        RegisterSwingTimerCombatLog()
    end
end

local function TryRegisterSwingTimerEvents()
    if swingTimerEventsRegistered then return end
    local RA = C_RestrictedActions
    -- 12.0+: CheckAllowProtectedFunctions(object [, silent]) — pass the frame that will call RegisterEvent.
    if RA and RA.CheckAllowProtectedFunctions and not RA.CheckAllowProtectedFunctions(swingTimerEventFrame) then
        swingTimerEventFrame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
        swingTimerEventFrame:SetScript("OnEvent", function(self, event, ...)
            if event == "ADDON_RESTRICTION_STATE_CHANGED" and RA.CheckAllowProtectedFunctions(self) then
                self:UnregisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
                ApplySwingTimerEventRegistration()
                swingTimerEventsRegistered = true
            end
        end)
        return
    end
    ApplySwingTimerEventRegistration()
    swingTimerEventsRegistered = true
end

local function BootstrapSwingTimerEvents()
    if not SwingTimerClientSupported() then
        return
    end
    -- Post-DF retail: avoid running RegisterEvent from this file's main chunk (restriction/taint).
    if FLUX_API and FLUX_API.isPostDF and FLUX_API.isRetail and C_Timer and C_Timer.After then
        C_Timer.After(0, TryRegisterSwingTimerEvents)
    else
        TryRegisterSwingTimerEvents()
    end
end

-- ---------------------------------------------------------------------------
-- Ranged: WeaponSwingTimer hunter one_bar (shot_bar + auto_shot_cast_bar widths; UpdateVisualsOnUpdate)
-- Uses same casting-bar atlas as melee; colors match WST default_settings cooldown / auto_cast.
-- ---------------------------------------------------------------------------
local function CreateRangedWSTOneBar(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetFrameLevel((parent:GetFrameLevel() or 0) + 3)
    f:Hide()
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.15, 0.15, 0.15, 1)
    f.bg = bg
    local cooldown = f:CreateTexture(nil, "ARTWORK")
    cooldown:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    cooldown:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    SetAtlasLegacy(cooldown, "ui-castingbar-filling-standard")
    cooldown:SetVertexColor(unpack(WST_RANGED_COOLDOWN_RGBA))
    f.cooldownTex = cooldown
    local clip = f:CreateTexture(nil, "OVERLAY", nil, 1)
    clip:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    clip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    SetAtlasLegacy(clip, "ui-castingbar-filling-standard")
    clip:SetVertexColor(unpack(WST_RANGED_AUTO_CAST_RGBA))
    f.clipTex = clip
    return f
end

--- Mirrors addon_data.hunter.UpdateVisualsOnUpdate: RANGED_WST_ONE_BAR false = !one_bar strip; true = one_bar dual segment (no multishot_clip_bar).
--- Forever native: remaining countdown from PLAYER_SWING (no WST clip / auto-cast wind-up).
UpdateRangedWSTVisuals = function(speed, rangedTimer, fullFlashHold)
    if not rangedWSTFrame or not rangedWSTFrame.cooldownTex then return end
    if speed <= 0 then speed = 1 end
    local W = rangedWSTFrame:GetWidth()
    local H = rangedWSTFrame:GetHeight()
    if IsSecret(W) or IsSecret(H) or W <= 0 or H <= 0 then return end
    local range_speed = speed
    local shot_timer = rangedTimer

    if UseNativePlayerSwing() then
        if rangedWSTFrame.clipTex then rangedWSTFrame.clipTex:Hide() end
        if fullFlashHold then
            rangedWSTFrame.cooldownTex:SetVertexColor(unpack(WST_RANGED_COOLDOWN_RGBA))
            rangedWSTFrame.cooldownTex:SetWidth(W)
            rangedWSTFrame.cooldownTex:SetHeight(H)
            return
        end
        local new_width = W * (shot_timer / range_speed)
        if new_width < 2 then new_width = 2 end
        new_width = math.min(new_width, W)
        rangedWSTFrame.cooldownTex:SetVertexColor(unpack(WST_RANGED_COOLDOWN_RGBA))
        rangedWSTFrame.cooldownTex:SetWidth(new_width)
        rangedWSTFrame.cooldownTex:SetHeight(H)
        return
    end

    local auto_cast_time = GetEffectiveAutoCastTime()

    if not RANGED_WST_ONE_BAR then
        if rangedWSTFrame.clipTex then rangedWSTFrame.clipTex:Hide() end
        if fullFlashHold then
            rangedWSTFrame.cooldownTex:SetVertexColor(unpack(WST_RANGED_AUTO_CAST_RGBA))
            rangedWSTFrame.cooldownTex:SetWidth(W)
            rangedWSTFrame.cooldownTex:SetHeight(H)
            return
        end
        local auto_shot_ready = shot_timer <= auto_cast_time
        local new_width
        if auto_shot_ready then
            new_width = W * (auto_cast_time - shot_timer) / auto_cast_time
            rangedWSTFrame.cooldownTex:SetVertexColor(unpack(WST_RANGED_AUTO_CAST_RGBA))
        else
            local denom = math.max(0.001, range_speed - auto_cast_time)
            new_width = W * ((shot_timer - auto_cast_time) / denom)
            rangedWSTFrame.cooldownTex:SetVertexColor(unpack(WST_RANGED_COOLDOWN_RGBA))
        end
        if new_width < 2 then new_width = 2 end
        new_width = math.min(new_width, W)
        rangedWSTFrame.cooldownTex:SetWidth(new_width)
        rangedWSTFrame.cooldownTex:SetHeight(H)
        return
    end

    if not rangedWSTFrame.clipTex then return end

    local timer_width
    local clip_w
    rangedWSTFrame.clipTex:Show()
    if fullFlashHold then
        timer_width = W
        clip_w = W * (auto_cast_time / range_speed)
    else
        timer_width = W * ((range_speed - shot_timer) / range_speed)
        if timer_width < 2 then timer_width = 2 end
        timer_width = math.min(timer_width, W)
        local auto_shot_ready = shot_timer <= auto_cast_time
        if auto_shot_ready then
            clip_w = W * (shot_timer / range_speed)
        else
            clip_w = W * (auto_cast_time / range_speed)
        end
        clip_w = math.max(0.001, math.min(clip_w, W))
    end

    rangedWSTFrame.cooldownTex:SetWidth(timer_width)
    rangedWSTFrame.cooldownTex:SetHeight(H)
    rangedWSTFrame.clipTex:SetWidth(clip_w)
    rangedWSTFrame.clipTex:SetHeight(H)
    rangedWSTFrame.cooldownTex:SetVertexColor(unpack(WST_RANGED_COOLDOWN_RGBA))
    rangedWSTFrame.clipTex:SetVertexColor(unpack(WST_RANGED_AUTO_CAST_RGBA))
end

-- ---------------------------------------------------------------------------
-- Bar factory
-- ---------------------------------------------------------------------------
local function CreateSwingBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    local fill = bar:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", bar, "LEFT", 0, 0)
    SetAtlasLegacy(fill, "ui-castingbar-filling-standard")
    bar:SetStatusBarTexture(fill)
    bar.fillTexture = fill

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.15, 0.15, 0.15, 1)
    bar.bg = bg

    return bar
end

--- Spark overlay matching FluxCastBar (ui-castingbar-pip / UI-CastingBar-Spark fallback).
local function CreateSwingSparkLayer(parentBar)
    local layer = CreateFrame("Frame", nil, parentBar)
    layer:SetFrameLevel((parentBar:GetFrameLevel() or 0) + 4)
    layer:SetAllPoints(parentBar)
    local spark = layer:CreateTexture(nil, "OVERLAY", nil, 1)
    local h = math.max(parentBar:GetHeight() or 12, 4)
    if hasAtlasSupport then
        spark:SetTexture(nil)
        SetAtlasLegacy(spark, "ui-castingbar-pip")
        spark:SetVertexColor(1, 1, 1, 1)
        spark:SetSize(8, h * 1.1)
    else
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetBlendMode("ADD")
        spark:SetTexCoord(0, 1, 0, 1)
        spark:SetVertexColor(1, 1, 1, 1)
        local sz = math.max(h * 1.1, 8)
        spark:SetSize(sz, sz)
    end
    spark:SetPoint("CENTER", layer, "LEFT", 0, 0)
    spark:Hide()
    layer.spark = spark
    return layer
end

ResizeSparkTexturesForBars = function()
    if mainSparkFrame and mainSparkFrame.spark and mainBar then
        local h = math.max(mainBar:GetHeight() or 12, 4)
        if hasAtlasSupport then
            mainSparkFrame.spark:SetSize(8, h * 1.1)
        else
            local sz = math.max(h * 1.1, 8)
            mainSparkFrame.spark:SetSize(sz, sz)
        end
    end
    if offSparkFrame and offSparkFrame.spark and offBar and offBar:IsShown() then
        local h = math.max(offBar:GetHeight() or 12, 4)
        if hasAtlasSupport then
            offSparkFrame.spark:SetSize(8, h * 1.1)
        else
            local sz = math.max(h * 1.1, 8)
            offSparkFrame.spark:SetSize(sz, sz)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Public: attach to the player cast bar
-- ---------------------------------------------------------------------------
function ST.AttachToCastBar(playerCastBar, unit)
    if unit ~= "player" then return end
    if swingFrame then
        return
    end
    castBar = playerCastBar

    local parentFrame = castBar:GetParent()

    -- Overlay container: same parent and position as castBar.
    -- Flux perf T2.4: frame starts Hide()d so OnUpdate stays dormant until a
    -- swing event (via ShowSwing) drives it visible.
    swingFrame = CreateFrame("Frame", nil, parentFrame)
    -- Draw below the cast bar so cast textures win if both were visible same slot.
    SyncSwingFrameLevel()
    swingFrame:SetAllPoints(castBar)
    swingFrame:SetAlpha(0)
    swingFrame:Hide()

    -- Status bars
    mainBar = CreateSwingBar(swingFrame)
    mainBar:SetStatusBarColor(unpack(SWING_COLOR_MAIN))

    offBar = CreateSwingBar(swingFrame)
    offBar:SetStatusBarColor(unpack(SWING_COLOR_OFF))
    offBar:Hide()

    mainSparkFrame = CreateSwingSparkLayer(mainBar)
    offSparkFrame = CreateSwingSparkLayer(offBar)
    rangedWSTFrame = CreateRangedWSTOneBar(swingFrame)

    -- Text (child of swingFrame so alpha propagates)
    local textHolder = CreateFrame("Frame", nil, swingFrame)
    textHolder:SetPoint("TOPLEFT", swingFrame, "TOPLEFT", 2, -2)
    textHolder:SetPoint("BOTTOMRIGHT", swingFrame, "BOTTOMRIGHT", -2, 2)
    textHolder:SetFrameLevel(swingFrame:GetFrameLevel() + 50)

    swingText = textHolder:CreateFontString(nil, "OVERLAY")
    swingText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    swingText:SetPoint("LEFT", textHolder, "LEFT", 4, 0)
    swingText:SetJustifyH("LEFT")
    swingText:SetTextColor(1, 1, 1)
    swingText:Hide()

    swingTime = textHolder:CreateFontString(nil, "OVERLAY")
    swingTime:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    swingTime:SetPoint("RIGHT", textHolder, "RIGHT", -4, 0)
    swingTime:SetJustifyH("RIGHT")
    swingTime:SetTextColor(1, 1, 1)
    swingTime:Hide()

    -- Icon: child of swingFrame so parent alpha hides it automatically.
    -- Positioned to the LEFT of the bar, mirroring the cast bar icon layout.
    iconFrame = CreateFrame("Frame", nil, swingFrame)
    iconFrame:SetFrameLevel(swingFrame:GetFrameLevel())

    iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
    iconTexture:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
    iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    ApplySpellIcon(iconTexture, ATTACK_SPELL_ID, FALLBACK_ATTACK_ICON)

    iconBorder = CreateFrame("Frame", nil, iconFrame)
    iconBorder:SetFrameLevel(iconFrame:GetFrameLevel() + 1)
    iconBorder:SetAllPoints()
    if Border then
        Border:ApplyTo(iconBorder, 2, 2, 2, 2)
        Border:SetClassColor(iconBorder, 1, true)
    end

    -- Bar border
    barBorder = CreateFrame("Frame", nil, swingFrame)
    barBorder:SetFrameLevel(swingFrame:GetFrameLevel() + 1)
    barBorder:SetAllPoints()
    if Border then
        Border:ApplyTo(barBorder, 2, 2, 2, 2)
        Border:SetClassColor(barBorder, 1, true)
    end

    -- OnUpdate drives the timer
    swingFrame:SetScript("OnUpdate", SwingTimer_OnUpdate)

    -- Events: registered once at module load (swingTimerEventFrame), not here — avoids protected
    -- RegisterEvent when this runs from tainted unit-frame init (Midnight / 12.0+).

    -- Re-anchor when cast bar relays out
    if castBar.UpdateLayout then
        hooksecurefunc(castBar, "UpdateLayout", function()
            SyncSwingFrameLevel()
            UpdateSwingLayout()
        end)
    end

    -- Initial state
    playerGUID = UnitGUID("player")
    UpdateMainSpeed()
    UpdateOffSpeed()
    UpdateRangedSpeed()
    UpdateNativeRangeCheckRegistration()
    UpdateSwingLayout()
    UpdateIcon()
end

--- Show/hide or attach swing UI when options change (cast bar must exist for first attach).
function ST.SetPlayerSwingTimerEnabled(enabled)
    local cb = castBar
    if not cb and ns.PlayerFrame and ns.PlayerFrame.CastBar then
        cb = ns.PlayerFrame.CastBar
    end
    if enabled then
        ParkBlizzardSwingTimerHud()
        if not swingFrame then
            if cb then
                ST.AttachToCastBar(cb, "player")
            end
        else
            -- Flux perf T2.4: stay Hide()d; ShowSwing from the next swing event re-Shows the frame.
            swingFrame:Hide()
            swingFrame:SetAlpha(0)
        end
        UpdateNativeRangeCheckRegistration()
    else
        local types = NativePlayerSwingTypes()
        SetNativeRangeCheck("mainHand", types and types.MainHand, false)
        SetNativeRangeCheck("offHand", types and types.OffHand, false)
        SetNativeRangeCheck("ranged", types and types.Ranged, false)
        SetNativeShownOutOfRange(false)
        if swingFrame then
            swingFrame:Hide()
        end
    end
end

BootstrapSwingTimerEvents()

