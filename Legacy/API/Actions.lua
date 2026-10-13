-- Actions.lua — spell book and action bar APIs (modern clients only)
local addonName, ns = ...
local H = ns._FluxAPICompat
local _type = H.type
local _pcall = H.pcall
local _strfind = H.strfind
local _strlower = H.strlower
local _tostring = H.tostring

local isRetail = FLUX_API.isRetail
local FluxSafeRegisterEvent = H.FluxSafeRegisterEvent

local _GetSpellInfoRaw
if C_Spell and C_Spell.GetSpellInfo then
    local _cGetSpellInfo = C_Spell.GetSpellInfo
    _GetSpellInfoRaw = function(spellId)
        local info = _cGetSpellInfo(spellId)
        if info then
            local rank
            if FLUX_API.isCamelot and C_Spell.GetSpellSubtext then
                local ok, sub = _pcall(C_Spell.GetSpellSubtext, spellId)
                if ok and _type(sub) == "string" and sub ~= "" then
                    rank = sub
                end
            end
            return info.name, rank, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
        end
        return nil
    end
elseif GetSpellInfo then
    _GetSpellInfoRaw = GetSpellInfo
else
    _GetSpellInfoRaw = function() return nil end
end

local _spellInfoCache = {}
local function _FluxAPICompat_ClearSpellCache()
    _spellInfoCache = {}
end

local _GetSpellInfoImpl = function(spellId)
    if _type(spellId) == "number" then
        local hit = _spellInfoCache[spellId]
        if hit ~= nil then
            if hit == false then return nil end
            return hit[1], hit[2], hit[3], hit[4], hit[5], hit[6], hit[7], hit[8]
        end
        local n, r, ic, ct, mn, mx, sid, oic = _GetSpellInfoRaw(spellId)
        if n == nil then
            _spellInfoCache[spellId] = false
            return nil
        end
        _spellInfoCache[spellId] = { n, r, ic, ct, mn, mx, sid, oic }
        return n, r, ic, ct, mn, mx, sid, oic
    end
    return _GetSpellInfoRaw(spellId)
end

local _GetSpellCooldownImpl
if C_Spell and C_Spell.GetSpellCooldown then
    local _cGetSpellCooldown = C_Spell.GetSpellCooldown
    _GetSpellCooldownImpl = function(spellId)
        if not spellId then return 0, 0, 0 end
        local cd = _cGetSpellCooldown(spellId)
        if cd then
            return cd.startTime, cd.duration, cd.isEnabled, cd.modRate
        end
        return 0, 0, 0
    end
elseif GetSpellCooldown then
    local _gscd = GetSpellCooldown
    _GetSpellCooldownImpl = function(spellId)
        if not spellId then return 0, 0, 0 end
        return _gscd(spellId)
    end
else
    _GetSpellCooldownImpl = function() return 0, 0, 0 end
end

local _cab = C_ActionBar
local _GetActionTextureImpl = (_cab and _cab.GetActionTexture) or GetActionTexture
local _IsUsableActionImpl = (_cab and _cab.IsUsableAction) or IsUsableAction
local _IsConsumableActionImpl = (_cab and _cab.IsConsumableAction) or IsConsumableAction
local _IsStackableActionImpl = (_cab and _cab.IsStackableAction) or IsStackableAction
local _IsItemActionImpl = (_cab and _cab.IsItemAction) or IsItemAction
local _IsEquippedActionImpl = (_cab and _cab.IsEquippedAction) or IsEquippedAction
local _GetActionChargesImpl = (_cab and _cab.GetActionCharges) or GetActionCharges
local _GetActionCountImpl = (_cab and _cab.GetActionCount) or GetActionCount
local _GetActionCooldownImpl = (_cab and _cab.GetActionCooldown) or GetActionCooldown
local _GetActionLoCImpl = (_cab and _cab.GetActionLossOfControlCooldown) or GetActionLossOfControlCooldown
local _IsActionInRangeImpl = (_cab and _cab.IsActionInRange) or IsActionInRange
local _IsAttackActionImpl = (_cab and _cab.IsAttackAction) or IsAttackAction
local _IsAutoRepeatActionImpl = (_cab and _cab.IsAutoRepeatAction) or IsAutoRepeatAction
local _IsCurrentActionImpl = (_cab and _cab.IsCurrentAction) or IsCurrentAction
local _HasActionImpl = (_cab and _cab.HasAction) or HasAction

ns.API.GetSpellInfo = _GetSpellInfoImpl
ns.API.GetSpellCooldown = _GetSpellCooldownImpl

do
    local spellCacheInvalidator = CreateFrame("Frame")
    FluxSafeRegisterEvent(spellCacheInvalidator, "SPELLS_CHANGED")
    FluxSafeRegisterEvent(spellCacheInvalidator, "LEARNED_SPELL_IN_TAB")
    FluxSafeRegisterEvent(spellCacheInvalidator, "LEARNED_SPELL_IN_SKILL_LINE")
    if isRetail then
        FluxSafeRegisterEvent(spellCacheInvalidator, "PLAYER_SPECIALIZATION_CHANGED")
        if C_ClassTalents then
            FluxSafeRegisterEvent(spellCacheInvalidator, "TRAIT_CONFIG_UPDATED")
        end
    end
    spellCacheInvalidator:SetScript("OnEvent", _FluxAPICompat_ClearSpellCache)
    FluxAPICompat._ClearSpellInfoCache = _FluxAPICompat_ClearSpellCache
end

function ns.API.GetNumSpellTabs()
    if GetNumSpellTabs then return GetNumSpellTabs() end
    return 0
end

function ns.API.GetSpellTabInfo(tabIndex)
    if GetSpellTabInfo then return GetSpellTabInfo(tabIndex) end
    return nil, nil, 0, 0
end

function ns.API.GetSpellBookItemName(index, bookType)
    if GetSpellBookItemName then return GetSpellBookItemName(index, bookType) end
    return nil
end

function ns.API.GetSpellBookItemInfo(index, bookType)
    if GetSpellBookItemInfo then return GetSpellBookItemInfo(index, bookType) end
    return nil, nil
end

function ns.API.GetSpellBookItemTexture(index, bookType)
    if GetSpellBookItemTexture then return GetSpellBookItemTexture(index, bookType) end
    return nil
end

function ns.API.IsSpellKnown(spellId)
    if IsSpellKnown then return IsSpellKnown(spellId) end
    return false
end

function ns.API.GetFlyoutInfo(flyoutId)
    if GetFlyoutInfo then return GetFlyoutInfo(flyoutId) end
    return nil, nil, 0
end

function ns.API.GetFlyoutSlotInfo(flyoutId, slotIndex)
    if GetFlyoutSlotInfo then return GetFlyoutSlotInfo(flyoutId, slotIndex) end
    return nil, nil, false, nil, nil
end

local _QUESTION_MARK_FILE_ID = 134400
local function _fluxTextureLooksLikePlaceholder(tex)
    if tex == nil or tex == "" then return true end
    if _type(tex) == "number" then
        return tex == 0 or tex == _QUESTION_MARK_FILE_ID
    end
    local s = _strlower(_tostring(tex))
    if _strfind(s, "inv_misc_questionmark", 1, true) then return true end
    if _strfind(s, "questionmark", 1, true) then return true end
    return false
end

function ns.API.GetSpellDisplayTexture(spellIdentifier)
    if spellIdentifier == nil then return nil end
    local tex = nil
    if C_Spell and C_Spell.GetSpellTexture then
        tex = C_Spell.GetSpellTexture(spellIdentifier)
    elseif GetSpellTexture then
        tex = GetSpellTexture(spellIdentifier)
    end
    if not _fluxTextureLooksLikePlaceholder(tex) then
        return tex
    end
    local csb = C_SpellBook
    if csb and csb.FindSpellBookSlotForSpell and csb.GetSpellBookItemTexture then
        local okSlot, slot, bank = _pcall(function()
            return csb.FindSpellBookSlotForSpell(spellIdentifier, false, true, false, false)
        end)
        if okSlot and slot and bank ~= nil then
            local okIcon, iconID = _pcall(function()
                return csb.GetSpellBookItemTexture(slot, bank)
            end)
            if okIcon and iconID and not _fluxTextureLooksLikePlaceholder(iconID) then
                return iconID
            end
        end
    end
    local _n, _r, ic, _ct, _mn, _mx, _sid, oic = ns.API.GetSpellInfo(spellIdentifier)
    if oic and not _fluxTextureLooksLikePlaceholder(oic) then return oic end
    if ic and not _fluxTextureLooksLikePlaceholder(ic) then return ic end
    return tex
end

function ns.API.GetItemInfo(itemId)
    if GetItemInfo then return GetItemInfo(itemId) end
    return nil
end

function ns.API.GetAtlasInfo(atlasName)
    if C_Texture and C_Texture.GetAtlasInfo then
        return C_Texture.GetAtlasInfo(atlasName)
    end
    if GetAtlasInfo then return GetAtlasInfo(atlasName) end
    return nil
end

function ns.API.HasAtlas(atlasName)
    return ns.API.GetAtlasInfo(atlasName) ~= nil
end

function ns.API.GetCurrentTime()
    if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
        return C_DateAndTime.GetCurrentCalendarTime()
    end
    return nil
end

function FluxHasAtlas(atlasName)
    return ns.API.HasAtlas(atlasName)
end

function FluxGetCurrentTime()
    return ns.API.GetCurrentTime()
end

function ns.API.GetActionTexture(action)
    if _GetActionTextureImpl then return _GetActionTextureImpl(action) end
    return nil
end

function ns.API.IsUsableAction(action)
    if _IsUsableActionImpl then return _IsUsableActionImpl(action) end
    return false, false
end

function ns.API.IsConsumableAction(action)
    if _IsConsumableActionImpl then return _IsConsumableActionImpl(action) end
    return false
end

function ns.API.IsStackableAction(action)
    if _IsStackableActionImpl then return _IsStackableActionImpl(action) end
    return false
end

function ns.API.IsItemAction(action)
    if _IsItemActionImpl then return _IsItemActionImpl(action) end
    return false
end

function ns.API.IsEquippedAction(action)
    if _IsEquippedActionImpl then return _IsEquippedActionImpl(action) end
    return false
end

function ns.API.GetActionCharges(action)
    if _GetActionChargesImpl then return _GetActionChargesImpl(action) end
    return 0, 0, 0, 0, 0
end

function ns.API.GetActionCount(action)
    if _GetActionCountImpl then return _GetActionCountImpl(action) end
    return 0
end

function ns.API.GetActionCooldown(action)
    if _GetActionCooldownImpl then return _GetActionCooldownImpl(action) end
    return 0, 0, 0
end

function ns.API.GetActionLossOfControlCooldown(action)
    if _GetActionLoCImpl then return _GetActionLoCImpl(action) end
    return 0, 0
end

function ns.API.IsActionInRange(action, unit)
    if not action or not _IsActionInRangeImpl then return nil end
    local ok, result = pcall(_IsActionInRangeImpl, action, unit)
    if not ok then return nil end
    return ns.API.NormalizeRangeResult(result)
end

function ns.API.NormalizeRangeResult(val)
    if val == true or val == 1 then return true end
    if val == false or val == 0 then return false end
    return nil
end

function ns.API.IsSpellUsable(spellIdentifier)
    if not spellIdentifier then return false, false end
    local key = spellIdentifier
    local numericId = tonumber(spellIdentifier)
    if numericId and numericId > 0 and C_Spell and C_Spell.GetOverrideSpell then
        local okO, override = pcall(C_Spell.GetOverrideSpell, numericId)
        if okO and type(override) == "number" and override > 0 then
            key = override
            numericId = override
        else
            key = numericId
        end
    elseif numericId and numericId > 0 then
        local fmt = _G.FluxFormatSpellCastAttribute
            or (_G.FluxButtonCore and _G.FluxButtonCore.FormatSpellCastAttribute)
        if fmt then
            local attr = fmt(numericId)
            if type(attr) == "string" and attr ~= "" then
                key = attr
            else
                key = numericId
            end
        else
            key = numericId
        end
    end
    local isUsable, notEnoughMana
    if C_Spell and C_Spell.IsSpellUsable then
        local ok, a, b = pcall(C_Spell.IsSpellUsable, key)
        if ok then isUsable, notEnoughMana = a, b end
        if isUsable == nil and notEnoughMana == nil and numericId and key ~= numericId then
            ok, a, b = pcall(C_Spell.IsSpellUsable, numericId)
            if ok then isUsable, notEnoughMana = a, b end
        end
    elseif IsUsableSpell then
        local ok, a, b = pcall(IsUsableSpell, key)
        if ok then isUsable, notEnoughMana = a, b end
        if isUsable == nil and notEnoughMana == nil and numericId and key ~= numericId then
            ok, a, b = pcall(IsUsableSpell, numericId)
            if ok then isUsable, notEnoughMana = a, b end
        end
    else
        return false, false
    end
    if ns.API.CanAccessValue then
        if not ns.API.CanAccessValue(isUsable) or not ns.API.CanAccessValue(notEnoughMana) then
            return nil, nil
        end
    end
    if isUsable == nil and notEnoughMana == nil then return nil, nil end
    if isUsable == nil then isUsable = false end
    if notEnoughMana == nil then notEnoughMana = false end
    return isUsable and true or false, notEnoughMana and true or false
end

function FluxGetSpellUsable(spellIdentifier)
    if not spellIdentifier then return false, false end
    if ns.API and ns.API.IsSpellUsable then
        local isUsable, notEnoughMana = ns.API.IsSpellUsable(spellIdentifier)
        if isUsable == nil and notEnoughMana == nil then return nil, nil end
        return isUsable and true or false, notEnoughMana and true or false
    end
    if FluxButtonUsability and FluxButtonUsability.CheckSpellUsability then
        local state, notEnoughMana = FluxButtonUsability:CheckSpellUsability(spellIdentifier)
        if state == FluxButtonUsability.STATE_USABLE or state == FluxButtonUsability.STATE_UNKNOWN then
            return true, false
        elseif state == FluxButtonUsability.STATE_NOT_ENOUGH_MANA then
            return false, true
        end
        return false, false
    end
    if C_Spell and C_Spell.IsSpellUsable then
        local isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellIdentifier)
        return isUsable, notEnoughMana
    end
    if IsUsableSpell then return IsUsableSpell(spellIdentifier), false end
    return false, false
end

function ns.API.IsSpellInRange(spellIdentifier, unit)
    if not spellIdentifier or not unit then return nil end
    local id = spellIdentifier
    if type(id) == "number" and C_Spell and C_Spell.GetOverrideSpell then
        local okO, override = pcall(C_Spell.GetOverrideSpell, id)
        if okO and type(override) == "number" and override > 0 then
            id = override
        end
    end
    if C_Spell and C_Spell.IsSpellInRange then
        local ok, result = pcall(C_Spell.IsSpellInRange, id, unit)
        if ok then return ns.API.NormalizeRangeResult(result) end
    end
    if _G.IsSpellInRange then
        local ok, result = pcall(_G.IsSpellInRange, id, unit)
        if ok then return ns.API.NormalizeRangeResult(result) end
    end
    return nil
end

function ns.API.CanCheckItemInRange(unit)
    if not unit then return false end
    if not InCombatLockdown or not InCombatLockdown() then return true end
    if not UnitCanAttack then return false end
    local ok, canAttack = pcall(UnitCanAttack, "player", unit)
    return ok and canAttack and true or false
end

function ns.API.IsItemInRange(itemId, unit)
    if not itemId or not unit then return nil end
    if not ns.API.CanCheckItemInRange(unit) then return nil end
    if C_Item and C_Item.IsItemInRange then
        local ok, result = pcall(C_Item.IsItemInRange, itemId, unit)
        if ok then return ns.API.NormalizeRangeResult(result) end
    end
    if _G.IsItemInRange then
        local ok, result = pcall(_G.IsItemInRange, itemId, unit)
        if ok then return ns.API.NormalizeRangeResult(result) end
    end
    return nil
end

function ns.API.UnitExistsSafe(unit)
    if not unit or not UnitExists then return false end
    local ok, result = pcall(UnitExists, unit)
    return ok and result and true or false
end

function ns.API.UnitInRangeSafe(unit)
    if type(unit) ~= "string" or unit == "" then return nil, false end
    if not ns.API.UnitExistsSafe(unit) then return nil, false end
    if not UnitInRange then return nil, false end
    local ok, inRange, checkedRange = pcall(UnitInRange, unit)
    if not ok then return nil, false end
    if ns.API.CanAccessValue then
        if not ns.API.CanAccessValue(inRange) then return nil, false end
        if checkedRange ~= nil and not ns.API.CanAccessValue(checkedRange) then return nil, false end
    end
    local normalized = ns.API.NormalizeRangeResult(inRange)
    local checked
    if checkedRange == nil then
        checked = normalized ~= nil
    else
        checked = checkedRange and true or false
    end
    return normalized, checked
end

function ns.API.IsAttackAction(action)
    if _IsAttackActionImpl then return _IsAttackActionImpl(action) end
    return false
end

function ns.API.IsAutoRepeatAction(action)
    if _IsAutoRepeatActionImpl then return _IsAutoRepeatActionImpl(action) end
    return false
end

function ns.API.IsCurrentAction(action)
    if _IsCurrentActionImpl then return _IsCurrentActionImpl(action) end
    return false
end

function ns.API.HasAction(action)
    if _HasActionImpl then return _HasActionImpl(action) end
    return false
end

function ns.API.GetNumShapeshiftForms()
    if GetNumShapeshiftForms then return GetNumShapeshiftForms() end
    return 0
end

function ns.API.GetShapeshiftFormInfo(formIndex)
    if GetShapeshiftFormInfo then return GetShapeshiftFormInfo(formIndex) end
    return nil, false, false, nil
end

function ns.API.GetShapeshiftFormCooldown(formIndex)
    if GetShapeshiftFormCooldown then return GetShapeshiftFormCooldown(formIndex) end
    return 0, 0, 0
end

function ns.API.HasValidStanceTexture(formIndex)
    local texture = ns.API.GetShapeshiftFormInfo(formIndex)
    if texture and ns.API.CanAccessValue(texture) then
        return texture ~= ""
    elseif texture then
        return true
    end
    return false
end

function ns.API.HasValidStances()
    local numForms = ns.API.GetNumShapeshiftForms()
    if not ns.API.CanAccessValue(numForms) or numForms == 0 then return false end
    for i = 1, numForms do
        if ns.API.HasValidStanceTexture(i) then return true end
    end
    return false
end

function ns.API.ShouldUseLegacyComboFrameUI()
    -- Forever/camelot: ComboFrame_Update compares secret GetComboPoints and
    -- errors once Flux has tainted the frame. Use the DF+ combo bar instead.
    -- Era and Anniversary keep ComboFrame even though the old managed container exists.
    if FLUX_API.isCamelot or FLUX_API.isForever then
        return false
    end
    if not _G.ComboFrame or not _G.ComboPoint1 then return false end
    if _G.RogueComboPointBarFrame or _G.DruidComboPointBarFrame then
        return false
    end
    return true
end

function ns.API.GetClassPowerInfo(classFilename, specID)
    if not classFilename then _, classFilename = UnitClass("player") end
    if not specID and GetSpecialization then specID = GetSpecialization() end
    if FLUX_API.isModernClient then
        if classFilename == "ROGUE" then return true, "COMBO_POINTS", "RogueComboPointBarFrame"
        elseif classFilename == "DRUID" then return true, "COMBO_POINTS", "DruidComboPointBarFrame"
        elseif classFilename == "MAGE" and specID == 1 then return true, "ARCANE_CHARGES", "MageArcaneChargesFrame"
        elseif classFilename == "MONK" and specID == 3 then return true, "CHI", "MonkHarmonyBarFrame"
        elseif classFilename == "PALADIN" then return true, "HOLY_POWER", "PaladinPowerBarFrame"
        elseif classFilename == "WARLOCK" then return true, "SOUL_SHARDS", "WarlockPowerFrame"
        elseif classFilename == "EVOKER" then return true, "ESSENCE", "EssencePlayerFrame"
        elseif classFilename == "DEATHKNIGHT" then return true, "RUNES", "RuneFrame"
        end
    end
    if FLUX_API.isWrath or FLUX_API.isCata then
        if classFilename == "ROGUE" or (classFilename == "DRUID" and GetShapeshiftFormID() == 1) then
            if classFilename == "DEATHKNIGHT" then return true, "RUNES", "RuneFrame" end
            if classFilename == "PALADIN" and FLUX_API.isCata then return true, "HOLY_POWER", "PaladinPowerBar" end
            if classFilename == "WARLOCK" and FLUX_API.isCata then return true, "SOUL_SHARDS", "ShardBarFrame" end
        end
    end
    return false, nil, nil
end

function ns.API.IsUnitPvP(unit)
    if UnitIsPVP then return UnitIsPVP(unit) end
    return false
end

function ns.API.GetUnitFactionGroup(unit)
    if UnitFactionGroup then return UnitFactionGroup(unit) end
    return nil
end

function ns.API.IsWarModeActive()
    if C_PvP and C_PvP.IsWarModeActive then return C_PvP.IsWarModeActive() end
    return false
end

function ns.API.GetWarModeAsset()
    if C_PvP and C_PvP.GetWarModeAsset then return C_PvP.GetWarModeAsset() end
    return nil
end

function ns.API.IsUnitInWarMode(unit)
    if not UnitIsUnit(unit, "player") then return false end
    return ns.API.IsWarModeActive()
end
