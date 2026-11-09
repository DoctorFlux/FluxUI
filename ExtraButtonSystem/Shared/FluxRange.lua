--[[
  FluxRange — shared out-of-range unit resolve + tri-state flag for LAB,
  ExtraButtons, Binding badges, and minimap FluxButtons.

  Contract: outOfRange = (inRange == false). nil / true clear the red tint.
]]

FluxRange = FluxRange or {}
local M = FluxRange

local function API()
    return FluxAPICompat and FluxAPICompat.API
end

function M.Normalize(val)
    local a = API()
    if a and a.NormalizeRangeResult then
        return a.NormalizeRangeResult(val)
    end
    if val == true or val == 1 then return true end
    if val == false or val == 0 then return false end
    return nil
end

local function UnitExistsSafe(unit)
    local a = API()
    if a and a.UnitExistsSafe then
        return a.UnitExistsSafe(unit)
    end
    if not unit or not UnitExists then return false end
    local ok, result = pcall(UnitExists, unit)
    return ok and result and true or false
end

local function SanitizeUnit(unit)
    if not unit or unit == "" or unit == "player" or unit == "cursor" or unit == "nil" then
        return nil
    end
    return unit
end

local function UnitMatchesHelpHarm(unit, helpful, harmful)
    if not unit then return false end
    if not helpful and not harmful then return true end
    local canHelp, canHarm = false, false
    if UnitIsFriend then
        local ok, r = pcall(UnitIsFriend, "player", unit)
        if ok then canHelp = r and true or false end
    end
    if UnitCanAttack then
        local ok, r = pcall(UnitCanAttack, "player", unit)
        if ok then canHarm = r and true or false end
    end
    if helpful and not harmful then return canHelp end
    if harmful and not helpful then return canHarm end
    return canHelp or canHarm
end

--- Prefer aspect / displayed spell for colorless lower-rank surfaces.
function M.ResolveSpellIdentifier(button, fallback)
    if not button then return fallback end
    local aspect = button._fluxAspectDisplaySpellId
    if type(aspect) ~= "number" or aspect <= 0 then
        local w = button.Widget
        aspect = w and w._fluxAspectDisplaySpellId
    end
    if type(aspect) == "number" and aspect > 0 then
        return aspect
    end
    if button.SpellNameRank then
        return button.SpellNameRank
    end
    if type(button.SpellId) == "number" and button.SpellId > 0 then
        return button.SpellId
    end
    return fallback
end

local function ReadSecureUnit(button)
    if not button or not button.GetAttribute then return nil end
    local ok, unit = pcall(button.GetAttribute, button, "unit")
    if not ok then return nil end
    return SanitizeUnit(unit)
end

local function ResolveHovercastMouseover(button)
    if not button then return nil end
    -- Binding badges: hover body present means UF hovercast is configured.
    local hasHover = (type(button._fluxHoverMacroBody) == "string" and button._fluxHoverMacroBody ~= "")
        or (button.GetAttribute and (function()
            local ok, v = pcall(button.GetAttribute, button, "flux-macrotext-hovercast")
            return ok and type(v) == "string" and v ~= ""
        end)())
    if not hasHover then return nil end
    if not UnitExistsSafe("mouseover") then return nil end

    local spellId = M.ResolveSpellIdentifier(button, button.SpellId)
    local resolveFn = _G.FluxSpellBindingProfile_ResolveSpellHelpHarm
    if type(resolveFn) == "function" and spellId then
        local helpful, harmful = resolveFn(spellId)
        if not UnitMatchesHelpHarm("mouseover", helpful, harmful) then
            return nil
        end
    end
    return "mouseover"
end

--- Unit resolution for range tint (not cast targeting).
--- Order: secure unit → Binding hovercast mouseover → macro Target → target/nil.
function M.ResolveUnit(button, opts)
    opts = opts or {}
    local unit = SanitizeUnit(opts.unit)
    if unit then
        return UnitExistsSafe(unit) and unit or nil
    end

    unit = ReadSecureUnit(button)
    if unit then
        return UnitExistsSafe(unit) and unit or nil
    end

    unit = ResolveHovercastMouseover(button)
    if unit then
        return unit
    end

    if button then
        if type(button.Target) == "string" and button.Target ~= "" then
            unit = SanitizeUnit(button.Target)
            if unit and UnitExistsSafe(unit) then
                return unit
            end
            if unit then
                return nil
            end
        end
    end

    if UnitExistsSafe("target") then
        return "target"
    end
    return nil
end

function M.CheckSpell(spellIdentifier, unit)
    if not spellIdentifier or not unit then return nil end
    local a = API()
    if a and a.IsSpellInRange then
        return a.IsSpellInRange(spellIdentifier, unit)
    end
    return nil
end

function M.CheckItem(itemId, unit)
    if not itemId or not unit then return nil end
    local a = API()
    if a and a.IsItemInRange then
        return a.IsItemInRange(itemId, unit)
    end
    return nil
end

function M.CheckAction(actionSlot, unit)
    if not actionSlot then return nil end
    local a = API()
    if a and a.IsActionInRange then
        return a.IsActionInRange(actionSlot, unit)
    end
    return nil
end

--- Apply tri-state flag to LAB (`outOfRange`) and Extra/badge (`_outOfRange`).
--- Returns true if the flag changed.
function M.ApplyFlag(button, inRange)
    if not button then return false end
    local oor = (inRange == false)
    local changed = false
    if button.outOfRange ~= oor then
        button.outOfRange = oor
        changed = true
    end
    if button._outOfRange ~= oor then
        button._outOfRange = oor
        changed = true
    end
    return changed
end

function M.ClearFlag(button)
    if not button then return false end
    local changed = (button.outOfRange == true) or (button._outOfRange == true)
    button.outOfRange = false
    button._outOfRange = false
    return changed
end

--- Clear OOR and request a paint/usable refresh when the surface supports it.
function M.Invalidate(button)
    if not button then return end
    M.ClearFlag(button)
    if button.UpdateUsable then
        pcall(button.UpdateUsable, button)
    elseif button.config and button.config.outOfRangeColoring == "button" then
        -- LAB surfaces paint via library UpdateUsable; callers should sample after.
    end
end

function M.InvalidateSet(set)
    if type(set) ~= "table" then return end
    if set[1] ~= nil then
        for i = 1, #set do
            M.Invalidate(set[i])
        end
        return
    end
    for button in next, set do
        M.Invalidate(button)
    end
end

--- Sample range for an Extra/badge FluxButton and return inRange tri-state.
function M.SampleFluxButton(button, rangeUnit)
    if not button then return nil end
    local unit = M.ResolveUnit(button, { unit = rangeUnit })
    if not unit then return nil end

    local barLegSlot = button._fluxSyncedActionSlot
    local isBarLeg = button._fluxBadgeIconLeg == "bar"
        and type(barLegSlot) == "number" and barLegSlot >= 1
    if isBarLeg then
        return M.CheckAction(barLegSlot, unit)
    end

    local Usability = _G.FluxButtonUsability
    if Usability and Usability.CheckButtonRange then
        return M.Normalize(Usability:CheckButtonRange(button, unit))
    end

    local actionType = button.ActionType
    if actionType == "spell" then
        return M.CheckSpell(M.ResolveSpellIdentifier(button, button.SpellId), unit)
    elseif actionType == "item" then
        return M.CheckItem(button.ItemId, unit)
    elseif actionType == "macro" then
        if button.MacroMode == "spell" then
            return M.CheckSpell(M.ResolveSpellIdentifier(button, button.SpellId), unit)
        elseif button.MacroMode == "item" then
            return M.CheckItem(button.ItemId, unit)
        end
    end
    return nil
end

_G.FluxRange = M
