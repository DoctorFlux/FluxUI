-- Binding/Core/Engraving.lua
-- SoD (Season of Discovery): map spellbook placeholder rune rows
-- ("Chest Rune Ability", "Bracer Rune Ability", …) to the real engraved
-- learnedAbilitySpellIDs via C_Engraving — V10/Clicked parity.

local addonName, ns = ...

local Engraving = {}
ns.FluxBindingEngraving = Engraving
_G.FluxBindingEngraving = Engraving

local SOD_ENGRAVING_INVSLOTS = {
    INVSLOT_HEAD or 1,
    INVSLOT_NECK or 2,
    INVSLOT_SHOULDER or 3,
    INVSLOT_BACK or 15,
    INVSLOT_CHEST or 5,
    INVSLOT_WRIST or 9,
    INVSLOT_HAND or 10,
    INVSLOT_WAIST or 6,
    INVSLOT_LEGS or 7,
    INVSLOT_FEET or 8,
    INVSLOT_FINGER1 or 11,
    INVSLOT_FINGER2 or 12,
}

local engravingSkillLineToLearnedId = {}
local engravingLearnedSet = {}
local engravingIconToLearnedId = {}
--- Spell / skill-line ids for runes currently engraved on the player.
--- IsSpellKnown often returns false for these; bindings must still treat them as usable.
local engravingEquippedLearnedIds = {}
local engravingCacheStamp = 0

local function Invalidate()
    wipe(engravingSkillLineToLearnedId)
    wipe(engravingLearnedSet)
    wipe(engravingIconToLearnedId)
    wipe(engravingEquippedLearnedIds)
    engravingCacheStamp = 0
end

local function PickBestLearnedFrom(lids)
    if type(lids) ~= "table" or #lids == 0 then return nil end
    if IsSpellKnown then
        for _, lid in ipairs(lids) do
            if lid then
                local ok, known = pcall(IsSpellKnown, lid)
                if ok and known then return lid end
            end
        end
    end
    return lids[1]
end

local function Rebuild()
    local E = _G.C_Engraving
    if not E or not E.GetRuneCategories or not E.GetRunesForCategory then return end
    pcall(function()
        if E.ClearAllCategoryFilters then E.ClearAllCategoryFilters() end
        if E.RefreshRunesList then E.RefreshRunesList() end
    end)
    wipe(engravingSkillLineToLearnedId)
    wipe(engravingLearnedSet)
    wipe(engravingIconToLearnedId)
    wipe(engravingEquippedLearnedIds)

    -- ownedOnly=true: only collected runes (skip the full unlearned dump).
    local okCats, cats = pcall(E.GetRuneCategories, false, true)
    if okCats and type(cats) == "table" then
        for _, category in ipairs(cats) do
            local okRunes, runes = pcall(E.GetRunesForCategory, category, true)
            if okRunes and type(runes) == "table" then
                for _, eng in ipairs(runes) do
                    local lids = eng and eng.learnedAbilitySpellIDs
                    if type(lids) == "table" and #lids > 0 then
                        local best = PickBestLearnedFrom(lids)
                        if best then
                            for _, lid in ipairs(lids) do
                                if lid then engravingLearnedSet[lid] = best end
                            end
                            local skillId = eng.skillLineAbilityID
                            if skillId then engravingSkillLineToLearnedId[skillId] = best end
                        end
                    end
                end
            end
        end
    end

    -- Pass C: spellbook rune-row icon matches the icon of the rune currently
    -- engraved on a known equipment slot.
    if E.GetRuneForEquipmentSlot then
        for _, slot in ipairs(SOD_ENGRAVING_INVSLOTS) do
            local okR, rune = pcall(E.GetRuneForEquipmentSlot, slot)
            if okR and type(rune) == "table" then
                local lids = rune.learnedAbilitySpellIDs
                local sk = rune.skillLineAbilityID
                if sk then engravingEquippedLearnedIds[sk] = true end
                if type(lids) == "table" then
                    for _, lid in ipairs(lids) do
                        if lid then engravingEquippedLearnedIds[lid] = true end
                    end
                end
                local best = PickBestLearnedFrom(lids)
                if best and rune.iconTexture then
                    engravingIconToLearnedId[rune.iconTexture] = best
                end
            end
        end
    end

    engravingCacheStamp = (GetTime and GetTime()) or 1
end

--- Rebuild after RUNE_UPDATED / SPELLS_CHANGED settle (C_Engraving lags the event).
function Engraving.Refresh()
    if not _G.C_Engraving then return end
    Invalidate()
    Rebuild()
end

_G.FluxSpellBindingProfile_RefreshEngravingCache = Engraving.Refresh

--- @param spellID integer|nil
--- @param actionID integer|nil
--- @param iconID integer|string|nil row icon (SoD placeholder rune rows)
--- @return integer|nil learnedAbilitySpellID
function Engraving.ResolveLearnedSpellId(spellID, actionID, iconID)
    if not _G.C_Engraving then return nil end
    if engravingCacheStamp == 0 then
        Rebuild()
    end
    -- A. identity
    if spellID and engravingLearnedSet[spellID] then return engravingLearnedSet[spellID] end
    if actionID and engravingLearnedSet[actionID] then return engravingLearnedSet[actionID] end
    -- B. skill-line
    local order = {}
    if actionID then order[#order + 1] = actionID end
    if spellID and spellID ~= actionID then order[#order + 1] = spellID end
    if #order == 0 and spellID then order[1] = spellID end
    for _, id in ipairs(order) do
        local L = engravingSkillLineToLearnedId[id]
        if L then return L end
    end
    -- C. icon match against currently engraved runes
    if iconID then
        local L = engravingIconToLearnedId[iconID]
        if L then return L end
    end
    return nil
end

_G.FluxSpellBindingProfile_ResolveRuneLearnedSpellId = Engraving.ResolveLearnedSpellId

--- Remap a saved/placeholder id using its current texture for pass C.
function Engraving.MapSavedRuneId(oldId)
    if type(oldId) ~= "number" then return nil end
    local icon
    if C_Spell and C_Spell.GetSpellTexture then
        icon = C_Spell.GetSpellTexture(oldId)
    elseif GetSpellTexture then
        local ok, tex = pcall(GetSpellTexture, oldId)
        if ok then icon = tex end
    end
    local learned = Engraving.ResolveLearnedSpellId(oldId, oldId, icon)
    if learned and learned ~= oldId then return learned end
    return nil
end

--- True when this spell/skill-line id is granted by an equipped engraving
--- (IsSpellKnown often lies for these).
function Engraving.IsEquippedRuneAbility(spellID)
    if not spellID or not _G.C_Engraving then return false end
    if engravingCacheStamp == 0 then Rebuild() end
    return engravingEquippedLearnedIds[spellID] and true or false
end

--- True when this id belongs to an owned (collected) SoD rune ability.
function Engraving.IsOwnedRuneAbility(spellID)
    if not spellID or not _G.C_Engraving then return false end
    if engravingCacheStamp == 0 then Rebuild() end
    spellID = tonumber(spellID)
    if not spellID then return false end
    return engravingLearnedSet[spellID] ~= nil
        or engravingSkillLineToLearnedId[spellID] ~= nil
        or engravingEquippedLearnedIds[spellID] ~= nil
end

--- Alias: any owned/equipped rune ability spell id.
function Engraving.IsRuneAbilitySpell(spellID)
    return Engraving.IsOwnedRuneAbility(spellID)
end

--- Resolve cast id + display name for macros / UI.
--- @return integer castId, string|nil name
function Engraving.ResolveCastIdAndName(spellID, actionID, iconID)
    local eff = actionID or spellID
    local learned = Engraving.ResolveLearnedSpellId(spellID, actionID, iconID)
    local castId = learned or eff
    local name
    if C_Spell and C_Spell.GetSpellInfo then
        local si = C_Spell.GetSpellInfo(castId)
        name = si and si.name
    elseif GetSpellInfo then
        name = GetSpellInfo(castId)
    end
    if (not name or name == "") and castId ~= eff and GetSpellInfo then
        name = GetSpellInfo(eff)
    end
    return castId, name
end

--- Rewrite FluxBindingDB3 spell actions that still store placeholder ids.
--- @return number count remapped
function Engraving.MigrateBindingDB()
    local DB = ns.FluxBindingDB3
    if not DB or not DB.All then return 0 end
    local count = 0
    for _, b in pairs(DB.All()) do
        local act = b.action
        if type(act) == "table" and act.type == "spell" and act.id then
            local newId = Engraving.MapSavedRuneId(act.id)
            if newId then
                act.id = newId
                act.name = nil
                count = count + 1
            end
        end
    end
    return count
end

-- Debounced RUNE_UPDATED / SPELLS_CHANGED → refresh + re-apply
local RUNE_COALESCE = 0.5
local RUNE_DEBOUNCE = 0.2
local runeUntil = 0
local pending = false

local function FlushRuneRefresh()
    pending = false
    Engraving.Refresh()
    Engraving.MigrateBindingDB()
    if _G.FluxBinding and _G.FluxBinding.RequestApplyAll then
        _G.FluxBinding.RequestApplyAll("engraving")
    end
end

local function ScheduleRuneRefresh(reason)
    local now = (GetTime and GetTime()) or 0
    if reason == "RUNE_UPDATED" then
        runeUntil = now + RUNE_COALESCE
    end
    if pending then return end
    pending = true
    local delay = RUNE_DEBOUNCE
    if reason == "SPELLS_CHANGED" and now < runeUntil then
        delay = RUNE_DEBOUNCE
    elseif reason == "RUNE_UPDATED" then
        delay = RUNE_DEBOUNCE
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, FlushRuneRefresh)
    else
        FlushRuneRefresh()
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "RUNE_UPDATED")
ev:RegisterEvent("SPELLS_CHANGED")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if _G.C_Engraving then
            Engraving.Refresh()
            -- DB migrate runs from Binding Boot after FluxBindingDB3.Ensure
        end
        return
    end
    if not _G.C_Engraving then return end
    if event == "RUNE_UPDATED" or (event == "SPELLS_CHANGED" and ((GetTime and GetTime()) or 0) < runeUntil) then
        ScheduleRuneRefresh(event)
    end
end)

