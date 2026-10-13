-- FluxRespec_UI.lua
-- Full-window Respec tab UI. Mirrors the ExtraButtons / Buttons-tab pattern:
-- our persistent mainFrame is parented to UIParent and anchored to the
-- FluxWindowFrame border (the "windowFrame"), not to tab.content. Visibility is
-- driven by the tab's onShow / onHide callbacks, so FluxWindowFrame's
-- CleanupTabContent cannot destroy our children when switching tabs.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.UI = R.UI or {}
local UI = R.UI
local Compat = R.Compat

local function EquipSetNameMax()
    if R.EquipmentSets and R.EquipmentSets.NameMaxLetters then
        return R.EquipmentSets.NameMaxLetters()
    end
    return 40
end

-- -----------------------------------------------------------------------------
-- Theme helpers
-- -----------------------------------------------------------------------------

local function ThemeRGB()
    if _G.FluxBorder and _G.FluxBorder.GetThemedVertexRGB then
        local ok, r, g, b = pcall(_G.FluxBorder.GetThemedVertexRGB, _G.FluxBorder)
        if ok and r then return r, g, b end
    end
    local _, cls = UnitClass("player")
    local c = _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[cls]
    if c then return c.r, c.g, c.b end
    return 0.6, 0.8, 1.0
end

--- Blizzard default gold/yellow for UIPanelButton labels (not class-themed UI tint).
local function SetBlizzardPanelButtonTextColor(fontString)
    if not fontString then
        return
    end
    local c = _G.NORMAL_FONT_COLOR
    if c then
        if c.GetRGB then
            fontString:SetTextColor(c:GetRGB())
        elseif type(c.r) == "number" then
            fontString:SetTextColor(c.r, c.g, c.b)
        end
    else
        fontString:SetTextColor(1, 0.82, 0)
    end
end

-- -----------------------------------------------------------------------------
-- Summary helpers
-- -----------------------------------------------------------------------------

local function FilterTargetEquipment(profile, targetEquip)
    local Inc = R.Includes
    if not Inc or type(targetEquip) ~= "table" then
        return targetEquip
    end
    local preset = Inc.ActiveEquipmentPreset and select(1, Inc.ActiveEquipmentPreset())
    if preset and Inc.CopyEnabledPresetEquipment then
        return Inc.CopyEnabledPresetEquipment(targetEquip, preset) or targetEquip
    end
    if type(profile) == "table" and Inc.CopyEnabledEquipment then
        return Inc.CopyEnabledEquipment(targetEquip, profile) or targetEquip
    end
    return targetEquip
end

local function TagIfSectionOn(profile, section, tag)
    if type(profile) ~= "table" or not R.Includes or not R.Includes.SectionEnabled then
        return tag
    end
    if R.Includes.SectionEnabled(profile, section) == false then
        return nil
    end
    return tag
end

local function GearSummary(profile)
    local EP = R.EquipmentPresets
    local presetEquip = EP and EP.GetActivePresetEquipment and EP.GetActivePresetEquipment()

    if not profile or not profile.equipment then
        if not (R.GetActiveName and R.GetActiveName()) then
            local n = 0
            local smax = (R.Equipment and R.Equipment.GetSlotMax and R.Equipment.GetSlotMax()) or 19
            for slotID = 1, smax do
                local id = GetInventoryItemID and GetInventoryItemID("player", slotID)
                if id and id ~= 0 then n = n + 1 end
            end
            local targetEquip = EP and EP.GetTargetEquipmentSnapshot and EP.GetTargetEquipmentSnapshot(nil)
            targetEquip = FilterTargetEquipment(nil, targetEquip)
            if targetEquip then
                local tags = {}
                local diff = EP.GetTargetEquipmentDiffCount and EP.GetTargetEquipmentDiffCount(nil) or 0
                local gearNeed = R.Equipment and R.Equipment.AnyGearChangeNeeded and R.Equipment.AnyGearChangeNeeded(targetEquip)
                if not gearNeed and diff == 0 then
                    tags[#tags + 1] = "[matches]"
                elseif diff > 0 then
                    tags[#tags + 1] = "[" .. diff .. " diff]"
                else
                    tags[#tags + 1] = "[gear]"
                end
                local Eq = R.Equipment
                if Eq and Eq.GetProfileGearAvailability then
                    local synthProfile = { equipment = targetEquip }
                    local miss, bank, unk = 0, 0, 0
                    for _, row in ipairs(Eq.GetProfileGearAvailability(synthProfile)) do
                        if row.status == "missing" then miss = miss + 1
                        elseif row.status == "bank" then bank = bank + 1
                        elseif row.status == "unknown" then unk = unk + 1 end
                    end
                    local bits = {}
                    if miss > 0 then bits[#bits + 1] = string.format("|cffff3030[%d missing]|r", miss) end
                    if bank > 0 then bits[#bits + 1] = string.format("|cffffaa40[%d in bank]|r", bank) end
                    if unk > 0 then bits[#bits + 1] = string.format("|cffffaa40[%d not in bags — open bank]|r", unk) end
                    if #bits > 0 then
                        return string.format("Equipped (%d)", n), table.concat(tags, " ") .. "  " .. table.concat(bits, " ")
                    end
                end
                return string.format("Equipped (%d)", n), table.concat(tags, " ")
            end
            return string.format("Equipped (%d)", n), nil
        end
        return "—", nil
    end

    local targetEquip = (EP and EP.GetTargetEquipmentSnapshot and EP.GetTargetEquipmentSnapshot(profile)) or profile.equipment
    targetEquip = FilterTargetEquipment(profile, targetEquip)
    local n = 0
    local smax = (R.Equipment and R.Equipment.GetSlotMax and R.Equipment.GetSlotMax()) or 19
    for slotID = 1, smax do
        local e = targetEquip and targetEquip[slotID]
        if e and (e.itemID or e.empty) then n = n + 1 end
    end

    local tags = {}
    local diff = (R.Equipment and R.Equipment.DiffCount and R.Equipment.DiffCount(targetEquip)) or 0
    local gearNeed = (R.Equipment and R.Equipment.AnyGearChangeNeeded and R.Equipment.AnyGearChangeNeeded(targetEquip)) or false
    if not gearNeed and diff == 0 then
        tags[#tags + 1] = "[matches]"
    elseif diff > 0 then
        tags[#tags + 1] = "[" .. diff .. " diff]"
    else
        tags[#tags + 1] = "[gear]"
    end

    local tag = table.concat(tags, " ")
    local Eq = R.Equipment
    if Eq and Eq.GetProfileGearAvailability then
        local synthProfile = { equipment = targetEquip }
        local miss, bank, unk = 0, 0, 0
        for _, row in ipairs(Eq.GetProfileGearAvailability(synthProfile)) do
            if row.status == "missing" then
                miss = miss + 1
            elseif row.status == "bank" then
                bank = bank + 1
            elseif row.status == "unknown" then
                unk = unk + 1
            end
        end
        local bits = {}
        if miss > 0 then
            bits[#bits + 1] = string.format("|cffff3030[%d missing]|r", miss)
        end
        if bank > 0 then
            bits[#bits + 1] = string.format("|cffffaa40[%d in bank]|r", bank)
        end
        if unk > 0 then
            bits[#bits + 1] = string.format("|cffffaa40[%d not in bags — open bank]|r", unk)
        end
        if #bits > 0 then
            tag = tag .. "  " .. table.concat(bits, " ")
        end
    end
    return string.format("%d items saved", n), tag
end

--- Gear row tag only (DiffCount / AnyGearChangeNeeded) — no bag availability scan.
local function GearSummaryTagsOnly(profile)
    local EP = R.EquipmentPresets
    if not profile or not profile.equipment then
        if not (R.GetActiveName and R.GetActiveName()) then
            local targetEquip = EP and EP.GetTargetEquipmentSnapshot and EP.GetTargetEquipmentSnapshot(nil)
            targetEquip = FilterTargetEquipment(nil, targetEquip)
            if targetEquip then
                local tags = {}
                local diff = EP.GetTargetEquipmentDiffCount and EP.GetTargetEquipmentDiffCount(nil) or 0
                local gearNeed = R.Equipment and R.Equipment.AnyGearChangeNeeded and R.Equipment.AnyGearChangeNeeded(targetEquip)
                if not gearNeed and diff == 0 then
                    tags[#tags + 1] = "[matches]"
                elseif diff > 0 then
                    tags[#tags + 1] = "[" .. diff .. " diff]"
                else
                    tags[#tags + 1] = "[gear]"
                end
                return nil, table.concat(tags, " ")
            end
        end
        return "—", nil
    end
    local targetEquip = (EP and EP.GetTargetEquipmentSnapshot and EP.GetTargetEquipmentSnapshot(profile)) or profile.equipment
    targetEquip = FilterTargetEquipment(profile, targetEquip)
    local tags = {}
    local diff = (R.Equipment and R.Equipment.DiffCount and R.Equipment.DiffCount(targetEquip)) or 0
    local gearNeed = (R.Equipment and R.Equipment.AnyGearChangeNeeded and R.Equipment.AnyGearChangeNeeded(targetEquip)) or false
    if not gearNeed and diff == 0 then
        tags[#tags + 1] = "[matches]"
    elseif diff > 0 then
        tags[#tags + 1] = "[" .. diff .. " diff]"
    else
        tags[#tags + 1] = "[gear]"
    end
    return nil, table.concat(tags, " ")
end

local function TalentSummary(profile)
    if not profile or not profile.talents then
        return "—", nil, nil
    end
    -- Retail (post-Dragonflight): profile stores a spec + Blizzard loadout reference.
    -- Row shows "<SpecName> — <LoadoutName>" instead of the classic X/Y/Z tab totals.
    if profile.talents.kind == "loadout" and R.TalentsRetail and R.TalentsRetail.Summary then
        local text, tag, icon = R.TalentsRetail.Summary(profile.talents)
        if not text then return "—", nil, nil end
        return text, TagIfSectionOn(profile, "talents", tag), icon
    end
    if Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts() then
        -- Classic-format snapshot viewed on retail: re-capture to migrate to a loadout profile.
        return "(save to migrate)", TagIfSectionOn(profile, "talents", "[re-save]"), nil
    end
    if not profile.talents.points then
        return "—", nil, nil
    end
    local totals = {}
    for tab, tree in pairs(profile.talents.points) do
        local s = 0
        for _, rank in pairs(tree) do s = s + (tonumber(rank) or 0) end
        totals[tab] = s
    end
    local t1, t2, t3 = totals[1] or 0, totals[2] or 0, totals[3] or 0
    local text = string.format("%d/%d/%d", t1, t2, t3)
    -- Saved-at-capture spec icon (see Talents.Capture); do not use live GetSpecIcon("player") after dual-spec swap.
    local specIcon = profile.talents.specIcon
    if (not specIcon or specIcon == "" or specIcon == 0) and R.Talents and R.Talents.SpecIconFromSnapshot then
        specIcon = R.Talents.SpecIconFromSnapshot(profile.talents)
    end
    -- Last resort: current player-frame spec (old profiles / edge cases); saved path above stays preferred.
    if (not specIcon or specIcon == "" or specIcon == 0) and _G.FluxUnitFrames_GetPlayerSpecIcon then
        specIcon = _G.FluxUnitFrames_GetPlayerSpecIcon()
    end

    -- Tags: use FindMatchingGroupIndex (same idea as Talents.Apply) so SoD / any client with 2+ groups
    -- still shows [other spec] when the inactive build matches — HasDualSpec() alone excludes Era/SoD.
    -- [needs trainer] only when Classic Era requires a reset and no group can apply via match or spend-only swap.
    local tag
    if R.Talents and R.Talents.FindMatchingGroupIndex then
        local matchG = R.Talents.FindMatchingGroupIndex(profile.talents)
        local ag = (Compat and Compat.GetActiveGroup and Compat.GetActiveGroup()) or 1
        if matchG and matchG == ag then
            tag = "[matches]"
        elseif matchG then
            tag = "[other spec]"
        elseif Compat and Compat.NeedsTrainerReset and Compat.NeedsTrainerReset()
            and R.Talents.CanApplyWithoutTrainerReset and not R.Talents.CanApplyWithoutTrainerReset(profile.talents) then
            tag = "[needs trainer]"
        else
            tag = "[needs learn]"
        end
    elseif R.Talents and R.Talents.Matches then
        local ag = (Compat and Compat.GetActiveGroup and Compat.GetActiveGroup()) or 1
        if R.Talents.Matches(profile.talents, ag) then
            tag = "[matches]"
        elseif Compat and Compat.NeedsTrainerReset and Compat.NeedsTrainerReset()
            and R.Talents.CanApplyWithoutTrainerReset and not R.Talents.CanApplyWithoutTrainerReset(profile.talents) then
            tag = "[needs trainer]"
        else
            tag = "[needs learn]"
        end
    end
    return text, TagIfSectionOn(profile, "talents", tag), specIcon
end

--- Talents row: crosshair / precision (target-adjacent), not TalentMicroButton / spellbook art. Classic-safe path.
local TALENTS_CATEGORY_ICON = "Interface\\Icons\\Ability_Marksmanship"

local function ApplyTalentRowCategoryIcon(tex)
    if not tex then
        return
    end
    tex:SetTexture(TALENTS_CATEGORY_ICON)
    tex:SetSize(22, 22)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

local function SetTalentRowSpecIconTexture(tex, icon)
    if not tex then return end
    if not icon then
        tex:Hide()
        return
    end
    tex:Show()
    tex:SetTexture(icon)
    if not tex:GetTexture() and type(icon) == "number" and icon > 0 and _G.C_Texture and _G.C_Texture.SetTextureWithFileID then
        pcall(_G.C_Texture.SetTextureWithFileID, tex, icon)
    end
    -- Same fallback as FluxUnitFrames_Shared UpdateOuterBorder (spec icon next to class icon).
    if not tex:GetTexture() and type(icon) == "string" then
        local altPath = icon:gsub("Interface\\Icons\\", "")
        if altPath ~= icon then
            tex:SetTexture("Interface\\Icons\\" .. altPath)
        end
    end
    tex:SetTexCoord(0, 1, 0, 1)
    tex:SetSize(22, 22)
end

local function ResolveProfileUtilitySnap(profile)
    if not profile then return nil end
    if type(profile.utilitySlots) == "table" then
        return profile.utilitySlots
    end
    if type(profile.spellBookSlots) == "table" then
        return profile.spellBookSlots
    end
    return nil
end

local function UtilitySlotsAPI()
    if _G.FluxNCUtilitySlots_MatchesSnapshot and _G.FluxNCUtilitySlots_CaptureSnapshot then
        return true
    end
    if _G.FluxSpellBookSlots_MatchesSnapshot and _G.FluxSpellBookSlots_CaptureSnapshot then
        return true
    end
    return false
end

local function UtilityMatches(snap)
    if _G.FluxNCUtilitySlots_MatchesSnapshot then
        return _G.FluxNCUtilitySlots_MatchesSnapshot(snap)
    end
    if _G.FluxSpellBookSlots_MatchesSnapshot then
        return _G.FluxSpellBookSlots_MatchesSnapshot(snap)
    end
    return false
end

local function UtilityApply(snap)
    if _G.FluxNCUtilitySlots_ApplySnapshot then
        return _G.FluxNCUtilitySlots_ApplySnapshot(snap)
    end
    if _G.FluxSpellBookSlots_ApplySnapshot then
        return _G.FluxSpellBookSlots_ApplySnapshot(snap)
    end
    return false, "NO_API"
end

local function UtilitySlotsSummary(profile)
    if not UtilitySlotsAPI() then
        return "—", nil
    end
    local snap = ResolveProfileUtilitySnap(profile)
    if not snap then return "—", nil end
    local n = 0
    local slots = snap.slots
    if type(slots) == "table" then
        for i = 1, 4 do
            local m = slots[i]
            if type(m) == "table" then
                for _, e in pairs(m) do
                    if type(e) == "table" and ((e.type and e.id ~= nil) or e.spellID) then
                        n = n + 1
                    end
                end
            end
        end
    end
    local tag
    if UtilityMatches(snap) then
        tag = "[matches]"
    else
        tag = "[diff]"
    end
    return string.format("%d bindings", n), TagIfSectionOn(profile, "utilitySlots", tag)
end

-- Back-compat name used by older call sites in this file.
local function SpellBookSummary(profile)
    return UtilitySlotsSummary(profile)
end

local function BindingsSummary(profile)
    if not (_G.FluxSpellBindings_MatchesSnapshot and _G.FluxSpellBindings_CaptureSnapshot) then
        return "—", nil
    end
    -- Live editor instances (includes unbound action-bar profiles).
    local liveSnap = _G.FluxSpellBindings_CaptureSnapshot and _G.FluxSpellBindings_CaptureSnapshot()
    local liveN = (_G.FluxSpellBindings_CountBoundSpells and liveSnap
        and _G.FluxSpellBindings_CountBoundSpells(liveSnap)) or 0
    local liveCustom = (_G.FluxSpellBindings_CountCustomizedBindings and liveSnap
        and _G.FluxSpellBindings_CountCustomizedBindings(liveSnap)) or liveN

    if not profile then
        if liveN <= 0 then return "none", nil end
        if liveCustom == liveN then
            return string.format("%d customized", liveN), nil
        end
        return string.format("%d (%d customized)", liveN, liveCustom), nil
    end

    local snap = profile.spellBindings
    if type(snap) ~= "table" then
        if liveN > 0 then
            return string.format("%d live — not saved", liveN), "[save]"
        end
        return "not saved", nil
    end
    if _G.FluxSpellBindings_IsLegacySnapshot and _G.FluxSpellBindings_IsLegacySnapshot(snap) then
        local n = (_G.FluxSpellBindings_CountBoundSpells and _G.FluxSpellBindings_CountBoundSpells(snap)) or 0
        return string.format("%d customized", n), "[legacy — re-save]"
    end
    if _G.FluxSpellBindings_IsV3Snapshot and not _G.FluxSpellBindings_IsV3Snapshot(snap) then
        return "invalid", "[re-save]"
    end
    local n = (_G.FluxSpellBindings_CountBoundSpells and _G.FluxSpellBindings_CountBoundSpells(snap)) or 0
    local custom = (_G.FluxSpellBindings_CountCustomizedBindings and _G.FluxSpellBindings_CountCustomizedBindings(snap)) or n
    local tag
    if _G.FluxSpellBindings_MatchesSnapshot(snap) then
        tag = "[matches]"
    else
        tag = "[diff]"
    end
    if custom == n then
        return string.format("%d customized", n), TagIfSectionOn(profile, "spellBindings", tag)
    end
    return string.format("%d (%d customized)", n, custom), TagIfSectionOn(profile, "spellBindings", tag)
end

local function BarsSummary(profile)
    if not profile or not profile.bars then return "—", nil end
    local retailLayoutOnly = Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts()
        and profile.bars.slots == nil
    local tag
    if R.ActionBars and R.ActionBars.MatchesSnapshot then
        tag = R.ActionBars.MatchesSnapshot(profile.bars) and "[matches]" or "[diff]"
    end
    tag = TagIfSectionOn(profile, "bars", tag)
    if retailLayoutOnly then
        local nOrder = 0
        if type(profile.bars.stanceSlotOrder) == "table" then
            for _ in pairs(profile.bars.stanceSlotOrder) do nOrder = nOrder + 1 end
        end
        local nHidden = 0
        if type(profile.bars.stanceHiddenSlots) == "table" then
            for _, v in pairs(profile.bars.stanceHiddenSlots) do
                if v then nHidden = nHidden + 1 end
            end
        end
        local nCustom = 0
        if type(profile.bars.stanceCustomSlots) == "table" then
            nCustom = #profile.bars.stanceCustomSlots
        end
        if nOrder == 0 and nHidden == 0 and nCustom == 0 then
            return "Stance default", tag
        end
        if nCustom > 0 and nHidden > 0 then
            return string.format("Stance order (%d added, %d hidden)", nCustom, nHidden), tag
        end
        if nCustom > 0 then
            return string.format("Stance order (%d added)", nCustom), tag
        end
        if nHidden > 0 then
            return string.format("Stance order (%d hidden)", nHidden), tag
        end
        return "Stance order", tag
    end
    local n = (R.ActionBars and R.ActionBars.FilledCount and R.ActionBars.FilledCount(profile.bars)) or 0
    if n == 0 then
        local slots = profile.bars.slots or {}
        for _ in pairs(slots) do n = n + 1 end
    end
    return string.format("%d slots", n), tag
end

local function RunesSummary(profile)
    local RP = R.RunePresets

    if not profile or not profile.runes then
        if not (R.GetActiveName and R.GetActiveName()) and Compat and Compat.IsSoD and Compat.IsSoD()
            and R.Runes and R.Runes.Capture then
            local cap = R.Runes.Capture()
            local n = 0
            if type(cap) == "table" then
                for _ in pairs(cap) do n = n + 1 end
            end
            local targetRunes = RP and RP.GetActivePresetRunes and RP.GetActivePresetRunes()
            if not targetRunes or not R.Runes or not R.Runes.DiffCount then
                return string.format("%d engraved", n), nil
            end
            local diff = (RP.GetActivePresetRuneDiffCount and RP.GetActivePresetRuneDiffCount()) or 0
            if diff == 0 then
                return string.format("%d engraved", n), "[matches]"
            elseif R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
                return string.format("%d engraved", n), "[" .. diff .. " queued]"
            end
            return string.format("%d engraved", n), "[" .. diff .. " diff]"
        end
        return "—", nil
    end

    local matchTarget = RP and RP.GetTargetRunesSnapshotForStrip and RP.GetTargetRunesSnapshotForStrip(profile) or profile.runes
    local Inc = R.Includes
    if Inc then
        local preset = Inc.ActiveRunePreset and select(1, Inc.ActiveRunePreset())
        if preset and Inc.CopyEnabledPresetRunes then
            matchTarget = Inc.CopyEnabledPresetRunes(matchTarget, preset) or matchTarget
        elseif type(profile) == "table" and Inc.CopyEnabledRunes then
            matchTarget = Inc.CopyEnabledRunes(matchTarget, profile) or matchTarget
        end
    end
    local n = 0
    if R.Runes and R.Runes.ENGRAVABLE_SLOTS then
        for _, slotID in ipairs(R.Runes.ENGRAVABLE_SLOTS) do
            local e = matchTarget and matchTarget[slotID]
            if e and e.skillLineAbilityID then n = n + 1 end
        end
    else
        for _ in pairs(matchTarget or {}) do n = n + 1 end
    end

    if not matchTarget or not R.Runes or not R.Runes.DiffCount then
        return string.format("%d engraved", n), nil
    end
    local diff = R.Runes.DiffCount(matchTarget) or 0
    if diff == 0 then
        return string.format("%d engraved", n), "[matches]"
    elseif R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
        return string.format("%d engraved", n), "[" .. diff .. " queued]"
    end
    return string.format("%d engraved", n), "[" .. diff .. " diff]"
end

local function ConsumablesSummary(profile)
    if not profile or not profile.consumables then
        if not (R.GetActiveName and R.GetActiveName()) and R.Consumables and R.Consumables.Capture then
            local cap = R.Consumables.Capture()
            if cap and cap ~= "" then
                return tostring(cap), "[active]"
            end
        end
        return "—", nil
    end
    local tag
    if R.Consumables and R.Consumables.IsDifferent then
        tag = R.Consumables.IsDifferent(profile.consumables) and "[switch]" or "[matches]"
    end
    return tostring(profile.consumables), TagIfSectionOn(profile, "consumables", tag)
end

-- Inventory slot order 1..19. Matches Equipment.GetSlotMax() (secondary shoulder / slot 20 excluded from Respec gear).
local GEAR_SLOT_LABELS = {
    "Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
    "Finger 1", "Finger 2", "Trinket 1", "Trinket 2", "Back", "Main Hand", "Off Hand", "Ranged", "Tabard",
}

-- Slot names for GetInventorySlotInfo (empty paperdoll texture per slot, same as character panel).
local INVENTORY_SLOT_NAME_BY_ID = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "ShirtSlot", "ChestSlot", "WaistSlot", "LegsSlot", "FeetSlot", "WristSlot", "HandsSlot",
    "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "BackSlot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot", "TabardSlot",
}

local FALLBACK_EMPTY_SLOT_TEX = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"

--- Empty paperdoll art for a slot. Retail returns a FileDataID (number); Classic often returns a path string.
local function GetPaperdollEmptyTextureForInventorySlot(slotID)
    local name = INVENTORY_SLOT_NAME_BY_ID[slotID]
    if name and _G.GetInventorySlotInfo then
        local ok, _, tex = pcall(_G.GetInventorySlotInfo, name)
        -- pcall: ok, invSlotId, emptyTexture, checkRelic — Texture:SetTexture accepts fileID or path
        if ok and tex ~= nil and tex ~= "" then
            if type(tex) == "number" and tex ~= 0 then
                return tex
            end
            if type(tex) == "string" then
                return tex
            end
        end
    end
    return FALLBACK_EMPTY_SLOT_TEX
end

local function GetGearSlotItemIcon(itemID, itemLink)
    local id = itemID
    if (not id or id == 0) and itemLink and Compat and Compat.ParseItemID then
        id = Compat.ParseItemID(itemLink)
    end
    if not id or id == 0 then return nil end
    if _G.GetItemInfo then
        local tex = select(10, _G.GetItemInfo(itemLink or id))
        if tex then return tex end
    end
    if _G.C_Item and _G.C_Item.GetItemInfoInstant then
        local ok, r = pcall(_G.C_Item.GetItemInfoInstant, id)
        if ok and type(r) == "table" and r.iconFileID then
            return r.iconFileID
        end
    end
    return nil
end

-- Gear strip: omit off-hand (slot 17) when main hand is two-handed (paperdoll-style).
local function GetGearStripSlotOrder(profile)
    local smax = (R.Equipment and R.Equipment.GetSlotMax and R.Equipment.GetSlotMax()) or 19
    local equip = profile and profile.equipment
    local hideOH = R.Equipment and R.Equipment.ShouldIgnoreOffHandSlot
        and R.Equipment.ShouldIgnoreOffHandSlot(equip or nil)
    local order = {}
    for i = 1, smax do
        if not (hideOH and i == 17) then
            order[#order + 1] = i
        end
    end
    return order
end

local PRESET_STRIP_BTN = 26
local PRESET_STRIP_GAP = 2
local PRESET_FOOTER_H = 18
local PRESET_FOOTER_PAD = 2
local PRESET_FOOTER_BTN_GAP = 2
local PRESET_FOOTER_TAG_GAP = 4
local GEAR_PROTECT_ROW_H = 18
local GEAR_PROTECT_PAD = 2

local function GearSectionFooterExtraH()
    return PRESET_FOOTER_PAD + GEAR_PROTECT_ROW_H + GEAR_PROTECT_PAD
end

local function LayoutGearSlotStrip(profile)
    local w = UI._widgets
    local gear = w and w.rows and w.rows.gear
    if not gear or not gear.gearSlotButtons or not gear.slotStrip then return end
    local cols = gear.gearSlotCols or 10
    local slotSize = gear.gearSlotSize or 30
    local gap = gear.gearSlotGap or 2
    local slotStrip = gear.slotStrip
    local smax = (R.Equipment and R.Equipment.GetSlotMax and R.Equipment.GetSlotMax()) or 19
    for sid = 1, smax do
        local btn = gear.gearSlotButtons[sid]
        if btn then btn:Hide() end
    end
    local order = GetGearStripSlotOrder(profile)
    for idx, sid in ipairs(order) do
        local btn = gear.gearSlotButtons[sid]
        if btn then
            btn:Show()
            local row = math.floor((idx - 1) / cols)
            local col = (idx - 1) % cols
            btn:SetPoint("TOPLEFT", slotStrip, "TOPLEFT", col * (slotSize + gap), -row * (slotSize + gap))
        end
    end
    local numRows = math.max(1, math.ceil(math.max(1, #order) / cols))
    slotStrip:SetHeight(numRows * slotSize + math.max(0, numRows - 1) * gap)
    local headerH = 24
    gear:SetHeight(headerH + slotStrip:GetHeight() + PRESET_FOOTER_PAD + PRESET_FOOTER_H + GearSectionFooterExtraH() + 1)
end

-- -----------------------------------------------------------------------------
-- Widget factories
-- -----------------------------------------------------------------------------

local function MakeButton(parent, text, width, height)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 56, height or 20)
    b:SetText(text)
    local fs = b:GetFontString()
    if fs then fs:SetFont(fs:GetFont(), 10, "OUTLINE") end
    return b
end

local function MakeRow(parent, iconSize)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(26)

    local iconBg = row:CreateTexture(nil, "BACKGROUND")
    iconBg:SetSize(iconSize or 22, iconSize or 22)
    iconBg:SetPoint("LEFT", row, "LEFT", 6, 0)
    iconBg:SetColorTexture(0, 0, 0, 0.4)
    row.iconBg = iconBg

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(iconSize or 22, iconSize or 22)
    icon:SetPoint("CENTER", iconBg, "CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", iconBg, "RIGHT", 8, 0)
    label:SetWidth(100)
    label:SetJustifyH("LEFT")
    row.label = label

    local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("LEFT", label, "RIGHT", 0, 0)
    value:SetJustifyH("LEFT")
    value:SetWordWrap(false)
    row.value = value

    local tag = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tag:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    tag:SetJustifyH("RIGHT")
    tag:SetWordWrap(false)
    row.tag = tag

    return row
end

local FluxDropDownListMinButtonWidth -- forward declaration; body defined later.

-- Static popup dialogs for rune/equipment preset CRUD.
StaticPopupDialogs["FLUX_RUNE_PRESET_NEW"] = {
    text = "Enter new rune preset name:",
    button1 = OKAY or "Okay",
    button2 = CANCEL or "Cancel",
    hasEditBox = true,
    maxLetters = 40,
    OnAccept = function(self)
        local eb = self.editBox or self.EditBox
        if eb then
            local n = (eb:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if n ~= "" and R.RunePresets and R.RunePresets.CreatePreset then
                if R.RunePresets.CreatePreset(n) and R.RunePresets.SaveActivePresetFromLive then
                    R.RunePresets.SaveActivePresetFromLive()
                end
                if UI.Refresh then UI.Refresh() end
            end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["FLUX_RUNE_PRESET_DELETE"] = {
    text = "Delete rune preset '%s'?",
    button1 = OKAY or "Okay",
    button2 = CANCEL or "Cancel",
    OnAccept = function()
        local name = R.RunePresets and R.RunePresets.GetActivePreset and R.RunePresets.GetActivePreset()
        if name and name ~= "default" and R.RunePresets.DeletePreset then
            R.RunePresets.DeletePreset(name)
            if UI.Refresh then UI.Refresh() end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["FLUX_EQUIP_PRESET_NEW"] = {
    text = "Enter new equipment preset name:",
    button1 = OKAY or "Okay",
    button2 = CANCEL or "Cancel",
    hasEditBox = true,
    maxLetters = 40,
    OnShow = function(self)
        local dlg = StaticPopupDialogs["FLUX_EQUIP_PRESET_NEW"]
        if dlg then
            dlg.maxLetters = EquipSetNameMax()
        end
        local eb = self.editBox or self.EditBox
        if eb and eb.SetMaxLetters then
            eb:SetMaxLetters(EquipSetNameMax())
        end
    end,
    OnAccept = function(self)
        local eb = self.editBox or self.EditBox
        if eb then
            local n = (eb:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if n ~= "" and R.EquipmentPresets and R.EquipmentPresets.CreatePreset then
                if R.EquipmentPresets.CreatePreset(n) and R.EquipmentPresets.SaveActivePresetFromLive then
                    R.EquipmentPresets.SaveActivePresetFromLive()
                end
                if UI.Refresh then UI.Refresh() end
            end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["FLUX_EQUIP_PRESET_RENAME"] = {
    text = "Rename equipment preset '%s' to:",
    button1 = OKAY or "Okay",
    button2 = CANCEL or "Cancel",
    hasEditBox = true,
    maxLetters = 40,
    OnShow = function(self)
        local dlg = StaticPopupDialogs["FLUX_EQUIP_PRESET_RENAME"]
        if dlg then
            dlg.maxLetters = EquipSetNameMax()
        end
        local eb = self.editBox or self.EditBox
        if eb and eb.SetMaxLetters then
            eb:SetMaxLetters(EquipSetNameMax())
        end
        local active = R.EquipmentPresets and R.EquipmentPresets.GetActivePreset and R.EquipmentPresets.GetActivePreset()
        if eb and active and active ~= "default" then
            eb:SetText(active)
            eb:HighlightText()
        end
    end,
    OnAccept = function(self)
        local active = R.EquipmentPresets and R.EquipmentPresets.GetActivePreset and R.EquipmentPresets.GetActivePreset()
        local eb = self.editBox or self.EditBox
        if not eb or not active or active == "default" then
            return
        end
        local n = (eb:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if n ~= "" and n ~= active and R.EquipmentPresets and R.EquipmentPresets.RenamePreset then
            R.EquipmentPresets.RenamePreset(active, n)
            if UI.Refresh then UI.Refresh() end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["FLUX_EQUIP_PRESET_DELETE"] = {
    text = "Delete equipment preset '%s'?",
    button1 = OKAY or "Okay",
    button2 = CANCEL or "Cancel",
    OnAccept = function()
        local name = R.EquipmentPresets and R.EquipmentPresets.GetActivePreset and R.EquipmentPresets.GetActivePreset()
        if name and name ~= "default" and R.EquipmentPresets.DeletePreset then
            R.EquipmentPresets.DeletePreset(name)
            if UI.Refresh then UI.Refresh() end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function MakePresetFooterButtons(section, strip, loadLabel)
    local footer = CreateFrame("Frame", nil, section)
    footer:SetHeight(PRESET_FOOTER_H)
    footer:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", 0, -PRESET_FOOTER_PAD)
    footer:SetPoint("TOPRIGHT", section, "TOPRIGHT", -6, 0)

    local saveBtn = MakeButton(footer, "Save Preset", 88, PRESET_FOOTER_H - 2)
    saveBtn:SetPoint("LEFT", footer, "LEFT", 0, 0)

    local loadBtn = MakeButton(footer, loadLabel or "Load Preset", 92, PRESET_FOOTER_H - 2)
    loadBtn:SetPoint("LEFT", saveBtn, "RIGHT", PRESET_FOOTER_BTN_GAP, 0)

    local tag = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tag:SetPoint("LEFT", loadBtn, "RIGHT", PRESET_FOOTER_TAG_GAP, 0)
    tag:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
    tag:SetJustifyH("LEFT")
    tag:SetWordWrap(false)

    section.presetFooter = footer
    section.presetFooterTag = tag
    return footer, saveBtn, loadBtn, tag
end

local function LayoutPresetFooterTag(footer, saveBtn, loadBtn, tag)
    if not tag or not footer then return end
    tag:ClearAllPoints()
    if loadBtn and loadBtn:IsShown() then
        tag:SetPoint("LEFT", loadBtn, "RIGHT", PRESET_FOOTER_TAG_GAP, 0)
    elseif saveBtn and saveBtn:IsShown() then
        tag:SetPoint("LEFT", saveBtn, "RIGHT", PRESET_FOOTER_TAG_GAP, 0)
    else
        tag:SetPoint("LEFT", footer, "LEFT", 0, 0)
    end
    tag:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
    tag:SetJustifyH("LEFT")
end

local function SetBarsConfirmButtonVisual(btn, selected)
    if not btn then return end
    btn:SetAlpha(selected and 1 or 0.55)
end

local function LayoutRunePresetFooter(section, saveBtn, loadBtn, tag, barsLabel, barsYes, barsNo)
    if not section or not tag then return end
    tag:ClearAllPoints()
    local leftAnchor = loadBtn
    if leftAnchor and not leftAnchor:IsShown() then
        leftAnchor = saveBtn
    end
    if barsYes and barsYes:IsShown() and barsNo and barsNo:IsShown() then
        if barsLabel and barsLabel:IsShown() then
            barsLabel:ClearAllPoints()
            barsLabel:SetPoint("LEFT", leftAnchor, "RIGHT", PRESET_FOOTER_BTN_GAP, 0)
            barsYes:ClearAllPoints()
            barsYes:SetPoint("LEFT", barsLabel, "RIGHT", 2, 0)
        else
            barsYes:ClearAllPoints()
            barsYes:SetPoint("LEFT", leftAnchor, "RIGHT", PRESET_FOOTER_BTN_GAP, 0)
        end
        barsNo:ClearAllPoints()
        barsNo:SetPoint("LEFT", barsYes, "RIGHT", 2, 0)
        tag:SetPoint("LEFT", barsNo, "RIGHT", PRESET_FOOTER_TAG_GAP, 0)
    elseif leftAnchor and leftAnchor:IsShown() then
        tag:SetPoint("LEFT", leftAnchor, "RIGHT", PRESET_FOOTER_TAG_GAP, 0)
    elseif saveBtn and saveBtn:IsShown() then
        tag:SetPoint("LEFT", saveBtn, "RIGHT", PRESET_FOOTER_TAG_GAP, 0)
    else
        tag:SetPoint("LEFT", section.presetFooter or section, "LEFT", 0, 0)
    end
    tag:SetPoint("RIGHT", section.presetFooter or section, "RIGHT", 0, 0)
    tag:SetJustifyH("LEFT")
end

local function RefreshRuneBarsConfirmControls(section, saveBtn, loadBtn)
    local RP = R.RunePresets
    if not RP or not section then return end
    local barsLabel = section.runeBarsLabel
    local barsYes = section.runeBarsYes
    local barsNo = section.runeBarsNo
    if not barsYes or not barsNo then return end

    local queueActive = R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue()
    local needsSave = RP.NeedsBarsConfirm and RP.NeedsBarsConfirm("save")
    local needsLoad = not queueActive and RP.NeedsBarsConfirm and RP.NeedsBarsConfirm("load")
    local show = needsSave or needsLoad

    if show then
        if RP.GetBarsApplyChoice and RP.GetBarsApplyChoice() == nil and RP.SetBarsApplyChoice then
            RP.SetBarsApplyChoice(false)
        end
        if barsLabel then barsLabel:Show() end
        barsYes:Show()
        barsNo:Show()
        local choice = RP.GetBarsApplyChoice and RP.GetBarsApplyChoice()
        SetBarsConfirmButtonVisual(barsYes, choice == true)
        SetBarsConfirmButtonVisual(barsNo, choice ~= true)
    else
        if barsLabel then barsLabel:Hide() end
        barsYes:Hide()
        barsNo:Hide()
        if RP.SetBarsApplyChoice then
            RP.SetBarsApplyChoice(nil)
        end
    end

    LayoutRunePresetFooter(section, saveBtn, loadBtn, section.presetFooterTag or section.tag, barsLabel, barsYes, barsNo)
end

--- Gear row: summary line + strip of paperdoll slot icons (saved profile items; empty slots show empty texture).
local STRIP_TOOLTIP_AWAY_FROM_FLYOUT = "ANCHOR_LEFT"

local function ShowGearStripTooltip(btn)
    if not btn then return end
    local pname = R.GetActiveName and R.GetActiveName()
    local slotID = btn.slotID
    local Eq = R.Equipment
    GameTooltip:SetOwner(btn, STRIP_TOOLTIP_AWAY_FROM_FLYOUT)
    if not pname then
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slotID)
        if link then
            GameTooltip:SetInventoryItem("player", slotID)
        else
            GameTooltip:AddLine(btn.slotLabel or "Empty", 1, 1, 1)
            GameTooltip:AddLine("No item equipped.", 0.7, 0.7, 0.7, true)
        end
        GameTooltip:Show()
        return
    end
    local prof = pname and R.GetProfile and R.GetProfile(pname)
    local EP = R.EquipmentPresets
    local targetEquip = EP and EP.GetTargetEquipmentSnapshot and EP.GetTargetEquipmentSnapshot(prof)
    local targetEntry = targetEquip and targetEquip[slotID]
    local link = GetInventoryItemLink and GetInventoryItemLink("player", slotID)
    if link then
        GameTooltip:SetInventoryItem("player", slotID)
        if targetEntry and Eq and Eq.SlotMatchesEntry and not Eq.SlotMatchesEntry(slotID, targetEntry, targetEquip) then
            GameTooltip:AddLine("Saved target differs.", 0.95, 0.78, 0.45, true)
        end
    elseif targetEntry and targetEntry.empty then
        if link then
            GameTooltip:SetInventoryItem("player", slotID)
            GameTooltip:AddLine("Preset saves this slot empty.", 0.95, 0.78, 0.45, true)
        else
            GameTooltip:AddLine(btn.slotLabel or "Empty", 1, 1, 1)
            GameTooltip:AddLine("Preset saves this slot empty.", 0.7, 0.85, 0.7, true)
        end
    elseif targetEntry and targetEntry.itemLink and targetEntry.itemLink ~= "" then
        local bag, bslot = Eq and Eq.FindBagSlotByItemLink and Eq.FindBagSlotByItemLink(targetEntry.itemLink)
        if bag ~= nil and bslot then
            GameTooltip:SetBagItem(bag, bslot)
        else
            GameTooltip:SetHyperlink(targetEntry.itemLink)
        end
    else
        GameTooltip:AddLine(btn.slotLabel or "Empty", 1, 1, 1)
        GameTooltip:AddLine("No item saved for this slot.", 0.7, 0.7, 0.7, true)
    end
    if pname and Eq and Eq.GetProfileGearAvailability and targetEquip then
        local synthProfile = { equipment = targetEquip }
        for _, row in ipairs(Eq.GetProfileGearAvailability(synthProfile)) do
            if row.slotID == slotID then
                if row.status == "missing" then
                    GameTooltip:AddLine("Not in bags or bank.", 1, 0.28, 0.2, true)
                elseif row.status == "bank" then
                    GameTooltip:AddLine("In bank: open bank, then Load moves it to bags and equips.", 1, 0.72, 0.38, true)
                elseif row.status == "unknown" then
                    GameTooltip:AddLine("Not in bags — open bank to see if it is stored there.", 0.95, 0.78, 0.45, true)
                elseif row.status == "bags" and targetEntry and targetEntry.empty then
                    GameTooltip:AddLine("Unequip to match preset.", 0.95, 0.78, 0.45, true)
                end
                break
            end
        end
    end
    if R.Includes and R.Includes.GearStripSlotEnabled then
        local included = R.Includes.GearStripSlotEnabled(prof, slotID)
        if included == false then
            GameTooltip:AddLine("Excluded from Save and Load — this slot will not change.", 0.72, 0.72, 0.72, true)
        else
            GameTooltip:AddLine("Right-click to exclude this slot from Save and Load.", 0.55, 0.55, 0.55, true)
        end
    end
    GameTooltip:Show()
end

local function ShowRuneStripTooltip(btn)
    if not btn then return end
    local sid = btn.slotID
    local slotName = GEAR_SLOT_LABELS[sid] or ("Slot " .. tostring(sid))
    local pname = R.GetActiveName and R.GetActiveName()
    GameTooltip:SetOwner(btn, STRIP_TOOLTIP_AWAY_FROM_FLYOUT)
    local liveEnt = btn._fluxLiveRuneEntry
    local targetEnt = btn._fluxRuneEntry
    if not pname then
        if liveEnt and liveEnt.skillLineAbilityID and GameTooltip.SetEngravingRune then
            pcall(GameTooltip.SetEngravingRune, GameTooltip, liveEnt.skillLineAbilityID)
        elseif liveEnt and liveEnt.name then
            GameTooltip:AddLine(slotName, 1, 1, 1)
            GameTooltip:AddLine(liveEnt.name, 0.6, 0.85, 0.95)
        else
            GameTooltip:AddLine(slotName, 1, 1, 1)
            GameTooltip:AddLine("No rune on this slot.", 0.7, 0.7, 0.7, true)
        end
        GameTooltip:Show()
        return
    end
    if liveEnt and liveEnt.skillLineAbilityID and GameTooltip.SetEngravingRune then
        local ok = pcall(GameTooltip.SetEngravingRune, GameTooltip, liveEnt.skillLineAbilityID)
        if not ok and liveEnt.name then
            GameTooltip:AddLine(slotName, 1, 1, 1)
            GameTooltip:AddLine(liveEnt.name, 0.6, 0.85, 0.95)
        end
    elseif liveEnt and liveEnt.name then
        GameTooltip:AddLine(slotName, 1, 1, 1)
        GameTooltip:AddLine(liveEnt.name, 0.6, 0.85, 0.95)
    elseif targetEnt and targetEnt.skillLineAbilityID and GameTooltip.SetEngravingRune then
        pcall(GameTooltip.SetEngravingRune, GameTooltip, targetEnt.skillLineAbilityID)
    elseif targetEnt and targetEnt.name then
        GameTooltip:AddLine(slotName, 1, 1, 1)
        GameTooltip:AddLine(targetEnt.name, 0.6, 0.85, 0.95)
        GameTooltip:AddLine("No rune engraved on this slot.", 0.7, 0.7, 0.7, true)
    else
        GameTooltip:AddLine(slotName, 1, 1, 1)
        GameTooltip:AddLine("No rune saved for this slot.", 0.7, 0.7, 0.7, true)
    end
    if targetEnt and R.Runes and R.Runes.SlotMatchesSnapshot and R.Runes.SlotMatchesSnapshot(sid, targetEnt) then
        GameTooltip:AddLine("Matches saved target.", 0.2, 0.85, 0.25)
    elseif targetEnt and targetEnt.skillLineAbilityID then
        GameTooltip:AddLine("Saved target differs.", 0.95, 0.78, 0.45, true)
    end
    if R.Includes and R.Includes.RuneStripSlotEnabled then
        local included = R.Includes.RuneStripSlotEnabled(pname and R.GetProfile and R.GetProfile(pname), sid)
        if included == false then
            GameTooltip:AddLine("Excluded from Save and Load — this rune will not change.", 0.72, 0.72, 0.72, true)
        else
            GameTooltip:AddLine("Right-click to exclude this rune from Save and Load.", 0.55, 0.55, 0.55, true)
        end
    end
    GameTooltip:Show()
end

UI.ShowGearStripTooltip = ShowGearStripTooltip
UI.ShowRuneStripTooltip = ShowRuneStripTooltip

local function MakeGearSection(parent)
    local section = CreateFrame("Frame", nil, parent)

    local iconBg = section:CreateTexture(nil, "BACKGROUND")
    iconBg:SetSize(22, 22)
    iconBg:SetPoint("TOPLEFT", section, "TOPLEFT", 6, -2)
    iconBg:SetColorTexture(0, 0, 0, 0.4)

    local categoryIcon = section:CreateTexture(nil, "ARTWORK")
    categoryIcon:SetSize(22, 22)
    categoryIcon:SetPoint("CENTER", iconBg, "CENTER")
    categoryIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    categoryIcon:SetTexture("Interface\\Icons\\INV_Chest_Chain")

    local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", iconBg, "RIGHT", 8, 0)
    label:SetWidth(72)
    label:SetJustifyH("LEFT")
    label:SetText("Gear:")

    local value = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("LEFT", label, "RIGHT", 4, 0)
    value:SetPoint("RIGHT", section, "RIGHT", -120, 0)
    value:SetJustifyH("LEFT")
    value:SetWordWrap(false)
    value:Hide()

    local slotStrip = CreateFrame("Frame", nil, section)
    slotStrip:SetPoint("TOPLEFT", iconBg, "BOTTOMLEFT", 0, -2)
    slotStrip:SetPoint("TOPRIGHT", section, "TOPRIGHT", -6, 0)
    local slotSize, gap, cols = PRESET_STRIP_BTN, PRESET_STRIP_GAP, 10
    local slotMax = (R.Equipment and R.Equipment.GetSlotMax and R.Equipment.GetSlotMax()) or 19
    local numRows = math.ceil(slotMax / cols)
    slotStrip:SetHeight(numRows * slotSize + math.max(0, numRows - 1) * gap)
    section.gearSlotCols = cols
    section.gearSlotSize = slotSize
    section.gearSlotGap = gap

    local buttons = {}
    for i = 1, slotMax do
        local btn = CreateFrame("Button", nil, slotStrip)
        btn:SetSize(slotSize, slotSize)
        btn.slotID = i
        btn.slotLabel = GEAR_SLOT_LABELS[i] or ("Slot " .. i)
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        btn:SetPoint("TOPLEFT", slotStrip, "TOPLEFT", col * (slotSize + gap), -row * (slotSize + gap))

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(GetPaperdollEmptyTextureForInventorySlot(i))

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn.iconTex = icon

        -- Green “equipped” frame when the saved item matches what you are wearing (same logic as DiffCount).
        local eqBorder = btn:CreateTexture(nil, "OVERLAY", nil, 1)
        eqBorder:SetTexture("Interface\\COMMON\\WhiteIconFrame")
        eqBorder:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
        eqBorder:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
        eqBorder:SetVertexColor(0.15, 0.92, 0.30, 0.85)
        eqBorder:Hide()
        btn.equippedBorder = eqBorder

        local stBorder = btn:CreateTexture(nil, "OVERLAY", nil, 2)
        stBorder:SetTexture("Interface\\COMMON\\WhiteIconFrame")
        stBorder:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
        stBorder:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
        stBorder:SetVertexColor(0.95, 0.2, 0.15, 1)
        stBorder:Hide()
        btn.gearStatusBorder = stBorder

        btn.itemLink = nil
        btn:SetScript("OnEnter", function(self)
            local slotID = self.slotID
            if not (R.GetActiveName and R.GetActiveName()) and R.GearPicker and R.GearPicker.NotifyStripEnter then
                R.GearPicker.NotifyStripEnter(self, slotID)
            end
            ShowGearStripTooltip(self)
        end)
        btn:SetScript("OnLeave", function()
            if R.GearPicker and R.GearPicker.NotifyStripLeave then
                R.GearPicker.NotifyStripLeave()
            end
            GameTooltip:Hide()
        end)

        buttons[i] = btn
    end

    local headerH = 24
    local margin = 0

    local footer, equipPresetSave, equipPresetLoad, tag = MakePresetFooterButtons(section, slotStrip, "Equip Preset")
    equipPresetSave:SetScript("OnClick", function()
        local EP = R.EquipmentPresets
        if not EP then return end
        local active = EP.GetActivePreset and EP.GetActivePreset() or "default"
        if active == "default" then
            if Compat.SecureUIPanelsBlockRespecWork() then return end
            StaticPopupDialogs["FLUX_EQUIP_PRESET_NEW"].maxLetters = EquipSetNameMax()
            StaticPopup_Show("FLUX_EQUIP_PRESET_NEW")
            return
        end
        if EP.SaveActivePresetFromLive then
            EP.SaveActivePresetFromLive()
            if UI.Refresh then UI.Refresh() end
        end
    end)
    equipPresetSave:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Save Preset")
        local EP = R.EquipmentPresets
        local active = EP and EP.GetActivePreset and EP.GetActivePreset() or "default"
        if active == "default" then
            GameTooltip:AddLine("Save current gear as a new equipment preset.", 1, 1, 1, true)
        else
            GameTooltip:AddLine("Saves checked slots into the active equipment preset. Unchecked slots keep their last saved items.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    equipPresetSave:SetScript("OnLeave", function() GameTooltip:Hide() end)

    equipPresetLoad:Hide()
    equipPresetLoad:SetScript("OnClick", function()
        local EP = R.EquipmentPresets
        if EP and EP.Apply then
            local epName = EP.GetActivePreset and EP.GetActivePreset() or "default"
            if epName ~= "default" then
                EP.Apply(epName)
            end
            if UI.Refresh then UI.Refresh() end
        end
    end)
    equipPresetLoad:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Equip Preset")
        GameTooltip:AddLine("Equips gear from the active equipment preset.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    equipPresetLoad:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local protectRow = CreateFrame("Frame", nil, section)
    protectRow:SetHeight(GEAR_PROTECT_ROW_H)
    protectRow:SetPoint("TOPLEFT", footer, "BOTTOMLEFT", 0, -GEAR_PROTECT_PAD)
    protectRow:SetPoint("TOPRIGHT", section, "TOPRIGHT", -6, 0)

    local protectCheck = CreateFrame("CheckButton", nil, protectRow, "UICheckButtonTemplate")
    protectCheck:SetSize(20, 20)
    protectCheck:SetPoint("LEFT", protectRow, "LEFT", 0, 0)
    local protectLabel = protectCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    protectLabel:SetPoint("LEFT", protectCheck, "RIGHT", 2, 0)
    protectLabel:SetText("Protect gear set items")
    protectCheck:SetScript("OnClick", function(self)
        local lock = R.GearSetLock
        if lock and lock.SetEnabled then
            lock.SetEnabled(self:GetChecked() == true)
        end
        if UI.Refresh then UI.Refresh() end
    end)
    protectCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Protect gear set items", 1, 1, 1)
        GameTooltip:AddLine(
            "Blocks vendor sell, Sell Junk, and disenchant on bag items needed for saved profiles and equipment presets. "
                .. "Exact enchant/gem matches protect one copy per gear slot; item-ID-only entries protect a single copy.",
            0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    protectCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    do
        local lock = R.GearSetLock
        local enabled = lock and lock.IsEnabled and lock.IsEnabled() or true
        protectCheck:SetChecked(enabled)
    end

    section:SetHeight(headerH + margin + slotStrip:GetHeight() + PRESET_FOOTER_PAD + PRESET_FOOTER_H + GearSectionFooterExtraH() + 1)

    -- Equipment preset dropdown.
    local equipPresetDD = _G.FluxBlizzardDropdown.Create(section, "FluxRespecEquipPresetDropdown", 180)
    equipPresetDD:SetPoint("LEFT", label, "RIGHT", 4, 0)
    equipPresetDD:FluxSetMenu(function()
        local EP = R.EquipmentPresets
        if not EP then
            return {}
        end
        local active = EP.GetActivePreset and EP.GetActivePreset() or "default"
        local entries = {
            {
                text = "Default (no preset)",
                checked = (active == "default"),
                func = function()
                    if EP.SetActivePreset then
                        EP.SetActivePreset("default")
                    end
                    if UI.Refresh then
                        UI.Refresh()
                    end
                end,
            },
            {
                text = "Manage",
                submenuId = "FluxEquipPresetManage",
                submenu = {
                    {
                        text = "New...",
                        func = function()
                            if Compat.SecureUIPanelsBlockRespecWork() then return end
                            StaticPopupDialogs["FLUX_EQUIP_PRESET_NEW"].maxLetters = EquipSetNameMax()
                            StaticPopup_Show("FLUX_EQUIP_PRESET_NEW")
                        end,
                    },
                    {
                        text = "Rename...",
                        disabled = (active == "default"),
                        func = function()
                            if active == "default" then return end
                            if Compat.SecureUIPanelsBlockRespecWork() then return end
                            StaticPopupDialogs["FLUX_EQUIP_PRESET_RENAME"].maxLetters = EquipSetNameMax()
                            StaticPopup_Show("FLUX_EQUIP_PRESET_RENAME", active)
                        end,
                    },
                    {
                        text = "Delete...",
                        disabled = (active == "default"),
                        func = function()
                            if active == "default" then return end
                            if Compat.SecureUIPanelsBlockRespecWork() then return end
                            StaticPopup_Show("FLUX_EQUIP_PRESET_DELETE", active)
                        end,
                    },
                },
            },
        }
        local names = EP.GetPresetNames and EP.GetPresetNames() or {}
        for _, pname in ipairs(names) do
            local preset = EP.GetPreset and EP.GetPreset(pname)
            local text = pname
            if R.EquipmentSets and R.EquipmentSets.DisplayName and preset then
                text = R.EquipmentSets.DisplayName(preset, pname) or pname
            end
            local tex
            if R.EquipmentSets and R.EquipmentSets.DisplayIcon and preset then
                tex = R.EquipmentSets.DisplayIcon(preset, pname)
            elseif preset then
                tex = preset.icon
            end
            entries[#entries + 1] = {
                text = text,
                checked = (pname == active),
                icon = tex,
                func = function()
                    if EP.SetActivePreset then
                        EP.SetActivePreset(pname)
                    end
                    if UI.Refresh then
                        UI.Refresh()
                    end
                end,
            }
        end
        return entries
    end)
    section.equipPresetDD = equipPresetDD

    local setIcon = section:CreateTexture(nil, "ARTWORK")
    setIcon:SetSize(18, 18)
    setIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    setIcon:Hide()
    section.equipPresetIcon = setIcon

    local function EquipPresetQuotaTip(self)
        if not R.EquipmentSets or not R.EquipmentSets.QuotaTooltip then
            return
        end
        local EP = R.EquipmentPresets
        local ap = EP and EP.GetActivePreset and EP.GetActivePreset() or "default"
        local preset = (ap ~= "default") and EP.GetPreset and EP.GetPreset(ap) or nil
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Equipment preset")
        GameTooltip:AddLine(R.EquipmentSets.QuotaTooltip(preset, ap ~= "default" and ap or nil), 1, 1, 1, true)
        GameTooltip:Show()
    end
    equipPresetDD:HookScript("OnEnter", EquipPresetQuotaTip)
    equipPresetDD:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    section.iconBg = iconBg
    section.icon = categoryIcon
    section.label = label
    section.value = value
    section.tag = tag
    section.slotStrip = slotStrip
    section.gearSlotButtons = buttons
    section.equipPresetSave = equipPresetSave
    section.equipPresetLoad = equipPresetLoad
    section.protectCheck = protectCheck
    section.protectRow = protectRow
    if UI.AttachSectionCheck then
        UI.AttachSectionCheck(section, "equipment",
            "When checked, Save records included gear slots and Load equips them. Uncheck the Gear row or individual slots to leave the rest of your outfit (and the last saved items) alone.",
            true)
        if section.label then
            section.label:ClearAllPoints()
            section.label:SetPoint("LEFT", section.iconBg or iconBg, "RIGHT", 8, 0)
        end
    end
    if UI.Gear and UI.Gear.AttachSlotChecks then
        UI.Gear.AttachSlotChecks(section)
    end
    return section
end

-- Rune of Teleportation (mage reagent) — same item icon as ExtraButton / restock (item 17031).
local ITEM_RUNE_OF_TELEPORTATION = 17031
local RUNES_CATEGORY_ICON_FALLBACK = "Interface\\Icons\\INV_Misc_Rune_06"

local function GetItemIconForRespec(itemID)
    if not itemID then return nil end
    if _G.C_Item and _G.C_Item.GetItemIconByID then
        local ok, fid = pcall(_G.C_Item.GetItemIconByID, itemID)
        if ok and fid and fid ~= 0 then return fid end
    end
    if _G.GetItemIcon then
        local ok, ico = pcall(_G.GetItemIcon, itemID)
        if ok and ico and ico ~= 0 then return ico end
    end
    if _G.GetItemInfo then
        local tex = select(10, _G.GetItemInfo(itemID))
        if type(tex) == "number" and tex ~= 0 then return tex end
        if type(tex) == "string" and tex ~= "" then return tex end
    end
    return nil
end

--- Action bars row: key / hotkey cue (reads as bar slots; Classic-safe). Not a random combat spell icon.
local ACTION_BARS_CATEGORY_ICON = "Interface\\Icons\\INV_Misc_Key_01"
local RUNE_STRIP_BTN = PRESET_STRIP_BTN
local RUNE_STRIP_GAP = PRESET_STRIP_GAP
local RUNE_STRIP_TOP_PAD = 2

--- Runes row: summary line + strip of engraved-rune icons (SoD). Green border = profile rune matches current engraving.
local function MakeRunesSection(parent)
    local section = CreateFrame("Frame", nil, parent)
    local headerH = 26

    local headerRow = CreateFrame("Frame", nil, section)
    headerRow:SetHeight(headerH)
    headerRow:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
    headerRow:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, 0)

    local iconBg = headerRow:CreateTexture(nil, "BACKGROUND")
    iconBg:SetSize(22, 22)
    iconBg:SetPoint("LEFT", headerRow, "LEFT", 6, 0)
    iconBg:SetColorTexture(0, 0, 0, 0.4)

    local categoryIcon = headerRow:CreateTexture(nil, "ARTWORK")
    categoryIcon:SetSize(22, 22)
    categoryIcon:SetPoint("CENTER", iconBg, "CENTER")
    categoryIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    do
        local tex = GetItemIconForRespec(ITEM_RUNE_OF_TELEPORTATION) or RUNES_CATEGORY_ICON_FALLBACK
        categoryIcon:SetTexture(tex)
    end

    local label = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", iconBg, "RIGHT", 8, 0)
    label:SetWidth(72)
    label:SetJustifyH("LEFT")
    label:SetText("Runes:")

    local value = headerRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("LEFT", label, "RIGHT", 0, 0)
    value:SetJustifyH("LEFT")
    value:SetWordWrap(false)
    value:Hide()

    -- Rune preset dropdown.
    local runePresetDD = _G.FluxBlizzardDropdown.Create(headerRow, "FluxRespecRunePresetDropdown", 180)
    runePresetDD:SetPoint("LEFT", label, "RIGHT", 4, 0)
    runePresetDD:FluxSetMenu(function()
        local RP = R.RunePresets
        if not RP then
            return {}
        end
        local active = RP.GetActivePreset and RP.GetActivePreset() or "default"
        local entries = {
            {
                text = "Default (no preset)",
                checked = (active == "default"),
                func = function()
                    if RP.SetActivePreset then
                        RP.SetActivePreset("default")
                    end
                    if UI.Refresh then
                        UI.Refresh()
                    end
                end,
            },
            {
                text = "Manage",
                submenuId = "FluxRunePresetManage",
                submenu = {
                    {
                        text = "New...",
                        func = function()
                            if Compat.SecureUIPanelsBlockRespecWork() then return end
                            StaticPopup_Show("FLUX_RUNE_PRESET_NEW")
                        end,
                    },
                    {
                        text = "Delete...",
                        disabled = (active == "default"),
                        func = function()
                            if active == "default" then return end
                            if Compat.SecureUIPanelsBlockRespecWork() then return end
                            StaticPopup_Show("FLUX_RUNE_PRESET_DELETE", active)
                        end,
                    },
                },
            },
        }
        local names = RP.GetPresetNames and RP.GetPresetNames() or {}
        for _, pname in ipairs(names) do
            entries[#entries + 1] = {
                text = pname,
                checked = (pname == active),
                func = function()
                    if RP.SetActivePreset then
                        RP.SetActivePreset(pname)
                    end
                    if UI.Refresh then
                        UI.Refresh()
                    end
                end,
            }
        end
        return entries
    end)
    section.runePresetDD = runePresetDD

    local strip = CreateFrame("Frame", nil, section)
    strip:SetPoint("TOPLEFT", headerRow, "BOTTOMLEFT", 0, -RUNE_STRIP_TOP_PAD)
    strip:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, 0)

    local slotList = (R.Runes and R.Runes.ENGRAVABLE_SLOTS) or {}
    local n = #slotList
    local stripH = (n > 0) and RUNE_STRIP_BTN or 1
    strip:SetHeight(stripH)

    local buttons = {}
    for i, slotID in ipairs(slotList) do
        local btn = CreateFrame("Button", nil, strip)
        btn:SetSize(RUNE_STRIP_BTN, RUNE_STRIP_BTN)
        btn.slotID = slotID
        btn:SetPoint("TOPLEFT", strip, "TOPLEFT", (i - 1) * (RUNE_STRIP_BTN + RUNE_STRIP_GAP), 0)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(GetPaperdollEmptyTextureForInventorySlot(slotID))

        local iconTex = btn:CreateTexture(nil, "ARTWORK")
        iconTex:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        iconTex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn.iconTex = iconTex

        local eqBr = btn:CreateTexture(nil, "OVERLAY", nil, 1)
        eqBr:SetTexture("Interface\\COMMON\\WhiteIconFrame")
        eqBr:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
        eqBr:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
        eqBr:SetVertexColor(0.15, 0.92, 0.30, 0.85)
        eqBr:Hide()
        btn.equippedBorder = eqBr

        btn._fluxLiveRuneEntry = nil
        btn._fluxRuneEntry = nil
        btn:SetScript("OnEnter", function(self)
            local sid = self.slotID
            if Compat and Compat.IsSoD and Compat.IsSoD() and R.RunePicker and R.RunePicker.NotifyStripEnter then
                R.RunePicker.NotifyStripEnter(self, sid)
            end
            ShowRuneStripTooltip(self)
        end)
        btn:SetScript("OnLeave", function()
            if R.RunePicker and R.RunePicker.NotifyStripLeave then
                R.RunePicker.NotifyStripLeave()
            end
            GameTooltip:Hide()
        end)

        buttons[slotID] = btn
    end

    section:SetHeight(headerH + RUNE_STRIP_TOP_PAD + stripH + PRESET_FOOTER_PAD + PRESET_FOOTER_H + 1)

    local footer, runePresetSave, runePresetLoad, tag = MakePresetFooterButtons(section, strip, "Load Preset")
    runePresetSave:SetScript("OnClick", function()
        local RP = R.RunePresets
        if not RP then return end
        local active = RP.GetActivePreset and RP.GetActivePreset() or "default"
        if active == "default" then
            if Compat.SecureUIPanelsBlockRespecWork() then return end
            StaticPopup_Show("FLUX_RUNE_PRESET_NEW")
            return
        end
        if RP.SaveActivePresetFromLive then
            RP.SaveActivePresetFromLive()
            if UI.Refresh then UI.Refresh() end
        end
    end)
    runePresetSave:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Save Preset")
        local RP = R.RunePresets
        local active = RP and RP.GetActivePreset and RP.GetActivePreset() or "default"
        if active == "default" then
            GameTooltip:AddLine("Save current runes, utility slots, and action bars as a new rune preset.", 1, 1, 1, true)
        else
            GameTooltip:AddLine("Saves checked rune slots and utility slots. Unchecked runes keep their last saved data. Action bars save when your talent tree matches, or when Bars: Yes is selected.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    runePresetSave:SetScript("OnLeave", function() GameTooltip:Hide() end)

    runePresetLoad:Hide()
    runePresetLoad:SetScript("OnClick", function()
        if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
            if R.Runes.CastNext then R.Runes.CastNext() end
        else
            local RP = R.RunePresets
            if RP and RP.ApplyAndStartEngrave then
                local rpName = RP.GetActivePreset and RP.GetActivePreset() or "default"
                if rpName ~= "default" then
                    RP.ApplyAndStartEngrave(rpName)
                end
            end
        end
        if UI.Refresh then UI.Refresh() end
    end)
    runePresetLoad:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue() then
            GameTooltip:AddLine("Engrave Rune")
            GameTooltip:AddLine("Click to engrave the next rune in the queue.", 1, 1, 1, true)
        else
            GameTooltip:AddLine("Load Preset")
            GameTooltip:AddLine("Switches to the matching dual spec when needed, then applies runes and utility slots.", 1, 1, 1, true)
            GameTooltip:AddLine("Action bars load when the saved talent tree matches spec 1 or 2, or when Bars: Yes is selected.", 0.72, 0.72, 0.72, true)
        end
        GameTooltip:Show()
    end)
    runePresetLoad:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local barsLabel = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    barsLabel:SetText("Bars:")
    barsLabel:Hide()

    local barsYes = MakeButton(footer, "Yes", 34, PRESET_FOOTER_H - 2)
    barsYes:Hide()
    barsYes:SetScript("OnClick", function()
        if R.RunePresets and R.RunePresets.SetBarsApplyChoice then
            R.RunePresets.SetBarsApplyChoice(true)
        end
        if UI.Refresh then UI.Refresh() end
    end)
    barsYes:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Include action bars")
        GameTooltip:AddLine("Preset bars do not match either talent spec on this character.", 1, 1, 1, true)
        GameTooltip:AddLine("Yes: save or load action bars with this preset.", 0.72, 0.72, 0.72, true)
        GameTooltip:Show()
    end)
    barsYes:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local barsNo = MakeButton(footer, "No", 34, PRESET_FOOTER_H - 2)
    barsNo:Hide()
    barsNo:SetScript("OnClick", function()
        if R.RunePresets and R.RunePresets.SetBarsApplyChoice then
            R.RunePresets.SetBarsApplyChoice(false)
        end
        if UI.Refresh then UI.Refresh() end
    end)
    barsNo:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Skip action bars")
        GameTooltip:AddLine("Preset bars do not match either talent spec on this character.", 1, 1, 1, true)
        GameTooltip:AddLine("No: only runes and utility slots; leave action bars unchanged.", 0.72, 0.72, 0.72, true)
        GameTooltip:Show()
    end)
    barsNo:SetScript("OnLeave", function() GameTooltip:Hide() end)

    section.iconBg = iconBg
    section.icon = categoryIcon
    section.label = label
    section.value = value
    section.tag = tag
    section.headerRow = headerRow
    section.runeStrip = strip
    section.runeSlotButtons = buttons
    section.runePresetSave = runePresetSave
    section.runePresetLoad = runePresetLoad
    section.runeBarsLabel = barsLabel
    section.runeBarsYes = barsYes
    section.runeBarsNo = barsNo
    headerRow.iconBg = iconBg
    if UI.AttachSectionCheck then
        UI.AttachSectionCheck(headerRow, "runes",
            "When checked, Save records included rune slots and Load engraves them. Uncheck the Runes row or individual runes to leave the rest.")
        section.includeCheck = headerRow.includeCheck
        section.iconBg = iconBg
        if label then
            label:ClearAllPoints()
            label:SetPoint("LEFT", iconBg, "RIGHT", 8, 0)
        end
    end
    if UI.RunesUI and UI.RunesUI.AttachSlotChecks then
        UI.RunesUI.AttachSlotChecks(section)
    end
    return section
end

local function RefreshRunesStrip(profile)
    local w = UI._widgets
    if not w or not w.rows or not w.rows.runes or not w.rows.runes.runeSlotButtons then return end
    local RP = R.RunePresets
    local targetRunes = RP and RP.GetTargetRunesSnapshotForStrip and RP.GetTargetRunesSnapshotForStrip(profile)
    local Rn = R.Runes
    local liveRunes = (Rn and Rn.Capture and Rn.Capture()) or {}
    for slotID, btn in pairs(w.rows.runes.runeSlotButtons) do
        local liveEntry = liveRunes and liveRunes[slotID]
        local targetEntry = targetRunes and targetRunes[slotID]
        btn._fluxLiveRuneEntry = liveEntry
        btn._fluxRuneEntry = targetEntry
        local tex = liveEntry and liveEntry.iconTexture
        if tex and tex ~= "" then
            btn.iconTex:SetTexture(tex)
            btn.iconTex:Show()
        else
            btn.iconTex:Hide()
        end
        if btn.equippedBorder then
            local show = targetEntry and Rn and Rn.SlotMatchesSnapshot and Rn.SlotMatchesSnapshot(slotID, targetEntry)
            btn.equippedBorder:SetShown(show == true)
        end
    end
end

local function ApplyGearStripButtonVisual(btn, slotID, want, targetEquip, Eq, skipOH, availBySlot)
    local link = GetInventoryItemLink and GetInventoryItemLink("player", slotID)
    local id = (link and GetInventoryItemID) and GetInventoryItemID("player", slotID) or nil
    btn.itemLink = link

    if want and want.empty then
        if id then
            local iconFile = GetGearSlotItemIcon(id, link)
            if iconFile then
                btn.iconTex:SetTexture(iconFile)
                btn.iconTex:SetDesaturated(false)
                btn.iconTex:SetAlpha(1)
                btn.iconTex:Show()
            else
                btn.iconTex:Hide()
            end
        else
            btn.iconTex:SetTexture(GetPaperdollEmptyTextureForInventorySlot(slotID))
            btn.iconTex:SetDesaturated(true)
            btn.iconTex:SetAlpha(0.55)
            btn.iconTex:Show()
        end
    else
        btn.iconTex:SetDesaturated(false)
        btn.iconTex:SetAlpha(1)
        local iconFile = GetGearSlotItemIcon(id, link)
        if iconFile then
            btn.iconTex:SetTexture(iconFile)
            btn.iconTex:Show()
        else
            btn.iconTex:SetTexture(nil)
            btn.iconTex:Hide()
        end
    end

    local showEq = want and Eq and Eq.SlotMatchesEntry and Eq.SlotMatchesEntry(slotID, want, targetEquip)
    if skipOH and slotID == 17 then
        showEq = false
    end
    if btn.equippedBorder then
        btn.equippedBorder:SetShown(showEq == true)
    end
    if btn.gearStatusBorder then
        if showEq then
            btn.gearStatusBorder:Hide()
        elseif want and want.empty then
            btn.gearStatusBorder:SetVertexColor(0.95, 0.65, 0.2, 1)
            btn.gearStatusBorder:Show()
        else
            local st = availBySlot and availBySlot[slotID]
            if not st or st == "equipped" or st == "bags" then
                btn.gearStatusBorder:Hide()
            else
                if st == "missing" then
                    btn.gearStatusBorder:SetVertexColor(0.95, 0.18, 0.12, 1)
                else
                    btn.gearStatusBorder:SetVertexColor(0.95, 0.65, 0.2, 1)
                end
                btn.gearStatusBorder:Show()
            end
        end
    end
end

local function RefreshGearSlotStrip(profile)
    local w = UI._widgets
    if not w or not w.rows or not w.rows.gear or not w.rows.gear.gearSlotButtons then return end
    local EP = R.EquipmentPresets
    local targetEquip = EP and EP.GetTargetEquipmentSnapshot and EP.GetTargetEquipmentSnapshot(profile)
    local Eq = R.Equipment
    local slotMax = (Eq and Eq.GetSlotMax and Eq.GetSlotMax()) or 19
    local skipOH = Eq and Eq.ShouldIgnoreOffHandSlot and Eq.ShouldIgnoreOffHandSlot(targetEquip or nil)
    local availBySlot = {}
    if targetEquip and Eq and Eq.GetProfileGearAvailability then
        local synthProfile = { equipment = targetEquip }
        local I = R.Includes
        if I and I.GearStripOwner then
            local owner, kind = I.GearStripOwner(profile)
            if kind == "preset" and owner then
                synthProfile.equipmentSlots = owner.equipmentSlots
            elseif owner and owner.includes then
                synthProfile.includes = owner.includes
            end
        end
        for _, row in ipairs(Eq.GetProfileGearAvailability(synthProfile)) do
            availBySlot[row.slotID] = row.status
        end
    end
    for slotID = 1, slotMax do
        local btn = w.rows.gear.gearSlotButtons[slotID]
        if btn then
            local want = targetEquip and targetEquip[slotID]
            ApplyGearStripButtonVisual(btn, slotID, want, targetEquip, Eq, skipOH, availBySlot)
        end
    end
    LayoutGearSlotStrip(profile)
end

local function RefreshGearSlotButton(profile, slotID)
    local w = UI._widgets
    if not w or not w.rows or not w.rows.gear or not w.rows.gear.gearSlotButtons then return end
    local btn = w.rows.gear.gearSlotButtons[slotID]
    if not btn then return end
    local EP = R.EquipmentPresets
    local targetEquip = EP and EP.GetTargetEquipmentSnapshot and EP.GetTargetEquipmentSnapshot(profile)
    local Eq = R.Equipment
    local skipOH = Eq and Eq.ShouldIgnoreOffHandSlot and Eq.ShouldIgnoreOffHandSlot(targetEquip or nil)
    local availBySlot = {}
    if targetEquip and Eq and Eq.GetSlotGearStatus then
        local st = Eq.GetSlotGearStatus({ equipment = targetEquip }, slotID)
        if st then
            availBySlot[slotID] = st
        end
    end
    local want = targetEquip and targetEquip[slotID]
    ApplyGearStripButtonVisual(btn, slotID, want, targetEquip, Eq, skipOH, availBySlot)
end

local function RefreshGearSlotsForEquipChange(profile, changedSlotID)
    if not changedSlotID then
        RefreshGearSlotStrip(profile)
        return
    end
    RefreshGearSlotButton(profile, changedSlotID)
    if R.Equipment and R.Equipment.GetJewelryPeerSlot then
        local peer = R.Equipment.GetJewelryPeerSlot(changedSlotID)
        if peer then
            RefreshGearSlotButton(profile, peer)
        end
    end
end

local equipUiDebounceTimer = nil

function UI.RefreshOnEquipChange(changedSlotID)
    if Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    if not UI._mainFrame or not UI._mainFrame:IsShown() or not UI._widgets then
        return
    end
    local name = R.GetActiveName()
    local profile = name and R.GetProfile(name) or nil
    local w = UI._widgets
    local _, gearTag = GearSummaryTagsOnly(profile)
    if w.rows.gear and w.rows.gear.tag then
        w.rows.gear.tag:SetText(gearTag or "")
        w.rows.gear.tag:SetShown(gearTag and gearTag ~= "")
    end
    RefreshGearSlotsForEquipChange(profile, changedSlotID)
    if R.RefreshPlayerSpecIconDecor then
        R.RefreshPlayerSpecIconDecor()
    end
end

local function ScheduleEquipUiRefresh(changedSlotID)
    if equipUiDebounceTimer and equipUiDebounceTimer.Cancel then
        equipUiDebounceTimer:Cancel()
    end
    if C_Timer and C_Timer.NewTimer then
        equipUiDebounceTimer = C_Timer.NewTimer(0.15, function()
            equipUiDebounceTimer = nil
            UI.RefreshOnEquipChange(changedSlotID)
        end)
    else
        UI.RefreshOnEquipChange(changedSlotID)
    end
end

-- Blizzard UIDropDownMenu_SetWidth(width) sizes the *middle* segment; outer width is width + 2*UIDROPDOWNMENU_DEFAULT_WIDTH_PADDING.
local function FluxDropDownMiddleFromOuter(outerW)
    local pad = (_G.UIDROPDOWNMENU_DEFAULT_WIDTH_PADDING or 25) * 2
    return math.max(8, math.floor((outerW or 0) - pad + 0.5))
end

-- Open list width is maxButtonWidth + 25; keep rows at least this wide so the menu matches the bar when labels are short.
FluxDropDownListMinButtonWidth = function(dropdown)
    local w = dropdown:GetWidth() or 0
    if w <= 48 then return 0 end
    return math.max(0, math.floor(w + 0.5) - 25)
end

--- Color profile labels when gear is missing, in bank only, or unknown until bank is opened.
local function ProfileMenuLabelForGear(name)
    local prof = R.GetProfile and R.GetProfile(name)
    local Eq = R.Equipment
    if not name or not prof or not Eq or not Eq.GetProfileGearIssueKind then
        return name
    end
    local kind = Eq.GetProfileGearIssueKind(prof)
    if not kind then
        return name
    end
    if kind == "missing" then
        return "|cffff2020" .. name .. "  [!]|r"
    end
    return "|cffffaa33" .. name .. "  [!]|r"
end

-- Static popups: Blizzard GENERIC_* tokens + runtime data only (no FLUXRESPEC_* in global StaticPopupDialogs).
local function FluxRespecShowNewProfilePopup()
    if Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    StaticPopup_Show("GENERIC_INPUT_BOX", nil, nil, {
        text = "New Respec profile name:",
        maxLetters = EquipSetNameMax(),
        acceptText = OKAY or "Okay",
        cancelText = CANCEL or "Cancel",
        callback = function(name)
            name = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if name ~= "" and R.CaptureInto then
                R.CaptureInto(name)
                if UI and UI.Refresh then
                    UI.Refresh()
                end
            end
        end,
    })
end

local function FluxRespecShowRenameProfilePopup(active)
    if not active or Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    local popup = StaticPopup_Show("GENERIC_INPUT_BOX", nil, nil, {
        text = "Rename profile '%s' to:",
        text_arg1 = active,
        maxLetters = EquipSetNameMax(),
        acceptText = OKAY or "Okay",
        cancelText = CANCEL or "Cancel",
        callback = function(newName)
            newName = (newName or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if active and newName ~= "" and newName ~= active and R.RenameProfile then
                R.RenameProfile(active, newName)
                if UI and UI.Refresh then
                    UI.Refresh()
                end
            end
        end,
    })
    if popup and popup.GetEditBox then
        local eb = popup:GetEditBox()
        if eb then
            eb:SetText(active)
            eb:HighlightText()
        end
    end
end

local function FluxRespecShowDeleteProfilePopup(active)
    if not active or Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    StaticPopup_Show("GENERIC_CONFIRMATION", nil, nil, {
        text = "Delete Respec profile '%s'?",
        text_arg1 = active,
        acceptText = OKAY or "Okay",
        cancelText = CANCEL or "Cancel",
        callback = function()
            if active and R.DeleteProfile then
                R.DeleteProfile(active)
                if UI and UI.Refresh then
                    UI.Refresh()
                end
            end
        end,
    })
end

local function MakeDropdown(parent)
    local DD = _G.FluxBlizzardDropdown
    local dd = DD.Create(parent, "FluxRespecProfileDropdown", 180, { stretch = true })

    dd.Refresh = function(self)
        local n = R.GetActiveName()
        if not n then
            self:FluxSetText("No profile")
        else
            self:FluxSetText(ProfileMenuLabelForGear(n))
        end
    end

    dd:FluxSetMenu(function()
        local active = R.GetActiveName()
        local entries = {
            {
                text = "No profile",
                checked = (active == nil),
                func = function()
                    R.SetActiveName(nil)
                    if R.Apply and R.Apply.Cancel then
                        R.Apply.Cancel()
                    end
                    if R.ClearLoadCheckpoint then
                        R.ClearLoadCheckpoint()
                    end
                    UI.Refresh()
                    if R.RefreshPlayerSpecIconDecor then
                        R.RefreshPlayerSpecIconDecor()
                    end
                end,
            },
            {
                text = "Manage",
                submenuId = "FluxRespecManage",
                submenu = {
                    { text = "New profile", func = FluxRespecShowNewProfilePopup },
                    {
                        text = "Rename…",
                        disabled = not active,
                        func = function()
                            if active then
                                FluxRespecShowRenameProfilePopup(active)
                            end
                        end,
                    },
                    {
                        text = "Delete…",
                        disabled = not active,
                        func = function()
                            if active then
                                FluxRespecShowDeleteProfilePopup(active)
                            end
                        end,
                    },
                },
            },
        }
        local names = R.GetProfileNames()
        if #names == 0 then
            entries[#entries + 1] = { text = "<no profiles>", disabled = true }
            return entries
        end
        for _, name in ipairs(names) do
            local tex = R.GetIcon and R.GetIcon(name)
            entries[#entries + 1] = {
                text = ProfileMenuLabelForGear(name),
                checked = (name == active),
                icon = tex,
                func = function()
                    if not R.SelectActiveProfileOnly or not R.SelectActiveProfileOnly(name) then
                        return
                    end
                end,
            }
        end
        return entries
    end)
    return dd
end

-- -----------------------------------------------------------------------------
-- Build mainFrame (once, persistent, parented to UIParent)
-- -----------------------------------------------------------------------------

UI._mainFrame = nil
UI._widgets = nil
UI._tabContentRef = nil
UI._windowFrameRef = nil

local ROW_GAP = 1
local SUMMARY_ROW_H = 26

--- Gear → Runes (SoD) → Consumables → Talents → Utility slots → Spell bindings → Action bars → Info Frame. Non-SoD: collapsed Runes; Consumables anchor under Gear.
local function LayoutRespecRowChain(w, isSoD)
    if not w.rows or not w.rows.gear or not w.rows.talents or not w.rows.consumables then return end
    local gear, runes = w.rows.gear, w.rows.runes
    local tal, bars, cons = w.rows.talents, w.rows.bars, w.rows.consumables
    local sb = w.rows.spellbook
    local bind = w.rows.bindings
    local info = w.rows.infoFrame

    runes:ClearAllPoints()
    tal:ClearAllPoints()
    if sb then sb:ClearAllPoints() end
    if bind then bind:ClearAllPoints() end
    if info then info:ClearAllPoints() end
    bars:ClearAllPoints()
    cons:ClearAllPoints()

    if isSoD then
        runes:Show()
        -- Height set by MakeRunesSection (summary + rune icon strip).
        runes:SetPoint("TOPLEFT", gear, "BOTTOMLEFT", 0, -ROW_GAP)
        runes:SetPoint("TOPRIGHT", gear, "BOTTOMRIGHT", 0, -ROW_GAP)
        cons:SetPoint("TOPLEFT", runes, "BOTTOMLEFT", 0, -ROW_GAP)
        cons:SetPoint("TOPRIGHT", runes, "BOTTOMRIGHT", 0, -ROW_GAP)
    else
        runes:Hide()
        runes:SetHeight(0.01)
        runes:SetPoint("TOPLEFT", gear, "BOTTOMLEFT", 0, -ROW_GAP)
        runes:SetPoint("TOPRIGHT", gear, "BOTTOMRIGHT", 0, -ROW_GAP)
        cons:SetPoint("TOPLEFT", gear, "BOTTOMLEFT", 0, -ROW_GAP)
        cons:SetPoint("TOPRIGHT", gear, "BOTTOMRIGHT", 0, -ROW_GAP)
    end

    tal:SetPoint("TOPLEFT", cons, "BOTTOMLEFT", 0, -ROW_GAP)
    tal:SetPoint("TOPRIGHT", cons, "BOTTOMRIGHT", 0, -ROW_GAP)
    if sb and sb:IsShown() then
        sb:SetPoint("TOPLEFT", tal, "BOTTOMLEFT", 0, -ROW_GAP)
        sb:SetPoint("TOPRIGHT", tal, "BOTTOMRIGHT", 0, -ROW_GAP)
        if bind and bind:IsShown() then
            bind:SetPoint("TOPLEFT", sb, "BOTTOMLEFT", 0, -ROW_GAP)
            bind:SetPoint("TOPRIGHT", sb, "BOTTOMRIGHT", 0, -ROW_GAP)
            bars:SetPoint("TOPLEFT", bind, "BOTTOMLEFT", 0, -ROW_GAP)
            bars:SetPoint("TOPRIGHT", bind, "BOTTOMRIGHT", 0, -ROW_GAP)
        else
            bars:SetPoint("TOPLEFT", sb, "BOTTOMLEFT", 0, -ROW_GAP)
            bars:SetPoint("TOPRIGHT", sb, "BOTTOMRIGHT", 0, -ROW_GAP)
        end
    elseif bind and bind:IsShown() then
        bind:SetPoint("TOPLEFT", tal, "BOTTOMLEFT", 0, -ROW_GAP)
        bind:SetPoint("TOPRIGHT", tal, "BOTTOMRIGHT", 0, -ROW_GAP)
        bars:SetPoint("TOPLEFT", bind, "BOTTOMLEFT", 0, -ROW_GAP)
        bars:SetPoint("TOPRIGHT", bind, "BOTTOMRIGHT", 0, -ROW_GAP)
    else
        bars:SetPoint("TOPLEFT", tal, "BOTTOMLEFT", 0, -ROW_GAP)
        bars:SetPoint("TOPRIGHT", tal, "BOTTOMRIGHT", 0, -ROW_GAP)
    end
    if info then
        info:SetPoint("TOPLEFT", bars, "BOTTOMLEFT", 0, -ROW_GAP)
        info:SetPoint("TOPRIGHT", bars, "BOTTOMRIGHT", 0, -ROW_GAP)
        if bars and bars.IsShown and not bars:IsShown() then
            local prev = bind
            if not (prev and prev:IsShown()) then
                prev = sb
            end
            if not (prev and prev:IsShown()) then
                prev = tal
            end
            info:ClearAllPoints()
            info:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -ROW_GAP)
            info:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -ROW_GAP)
        end
    end
end

local function SyncScrollContentHeight(w, isSoD)
    local sc = w.scrollChild
    local sf = w.scrollFrame
    if not sc or not w.rows or not w.rows.gear or not w.rows.bars then return end
    local prevScroll = (sf and sf.GetVerticalScroll and sf:GetVerticalScroll()) or 0
    local gh = w.rows.gear:GetHeight() or 96
    local rh = 0
    if isSoD and w.rows.runes and w.rows.runes.GetHeight then
        rh = w.rows.runes:GetHeight() or 0
    end
    local link = ROW_GAP + (isSoD and (rh + ROW_GAP) or 0)
    local summaryRows = 3
    if w.rows.spellbook and w.rows.spellbook.IsShown and w.rows.spellbook:IsShown() then
        summaryRows = summaryRows + 1
    end
    if w.rows.bindings and w.rows.bindings.IsShown and w.rows.bindings:IsShown() then
        summaryRows = summaryRows + 1
    end
    if w.rows.infoFrame and w.rows.infoFrame.IsShown and w.rows.infoFrame:IsShown() then
        summaryRows = summaryRows + 1
    end
    local rest = SUMMARY_ROW_H * summaryRows + ROW_GAP * (summaryRows - 1)
    local bottomPad = 10
    local flyPad = 0
    if R.RunePicker and R.RunePicker.GetExtraScrollBottom then
        flyPad = math.max(flyPad, R.RunePicker.GetExtraScrollBottom() or 0)
    end
    if R.GearPicker and R.GearPicker.GetExtraScrollBottom then
        flyPad = math.max(flyPad, R.GearPicker.GetExtraScrollBottom() or 0)
    end
    -- Extra pad so the last row can scroll fully into view (UIPanelScrollFrame
    -- max scroll is contentHeight - frameHeight; measured bottom can clip).
    bottomPad = bottomPad + 24
    local computed = gh + link + rest + bottomPad + flyPad

    -- Must use bottom-most row; on retail the Action Bars row is hidden (loadouts own bar layout),
    -- so fall back to Spellbook slots (if shown) or Talents.
    local last = w.rows.bars
    if last and last.IsShown and not last:IsShown() then
        if w.rows.bindings and w.rows.bindings.IsShown and w.rows.bindings:IsShown() then
            last = w.rows.bindings
        elseif w.rows.spellbook and w.rows.spellbook.IsShown and w.rows.spellbook:IsShown() then
            last = w.rows.spellbook
        elseif w.rows.talents then
            last = w.rows.talents
        end
    end
    -- Prefer consumables as last visible summary row when bars are hidden.
    if last and last.IsShown and not last:IsShown() and w.rows.consumables
        and w.rows.consumables.IsShown and w.rows.consumables:IsShown() then
        last = w.rows.consumables
    end
    -- Walk visible summary rows for true bottom-most.
    do
        local order = { w.rows.consumables, w.rows.talents, w.rows.spellbook, w.rows.bindings, w.rows.bars, w.rows.infoFrame }
        for i = 1, #order do
            local row = order[i]
            if row and (not row.IsShown or row:IsShown()) then
                last = row
            end
        end
    end
    local measured = 0
    local st, lb = sc:GetTop(), last and last.GetBottom and last:GetBottom()
    if st and lb then
        measured = (st - lb) + bottomPad + flyPad
    end

    sc:SetHeight(math.max(100, math.max(computed, measured)))
    -- Preserve scroll position across refresh/layout (do not yank to top).
    if sf and sf.SetVerticalScroll then
        local viewH = sf:GetHeight() or 0
        local contentH = sc:GetHeight() or 0
        local maxScroll = math.max(0, contentH - viewH)
        if prevScroll > maxScroll then
            prevScroll = maxScroll
        end
        sf:SetVerticalScroll(prevScroll)
    end
end

local function ResetRespecScroll(w)
    local sf = w and w.scrollFrame
    if sf and sf.SetVerticalScroll then
        sf:SetVerticalScroll(0)
    end
end

local function ApplyScrollChildWidth(scrollFrame, scrollChild)
    if not scrollFrame or not scrollChild then return end
    local fw = scrollFrame:GetWidth()
    if not fw or fw <= 40 then return end
    local bar = 28
    if scrollFrame.ScrollBar and scrollFrame.ScrollBar.GetWidth then
        bar = scrollFrame.ScrollBar:GetWidth() + 10
    end
    scrollChild:SetWidth(math.max(120, fw - bar))
end

--- Rune flyout (UIParent) is tall: add bottom scroll range without resetting scroll (see FluxRespec_RunePicker).
function UI.SyncRespecScrollForFlyout()
    if Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    local w = UI._widgets
    if not w or not w.scrollChild or not w.scrollFrame then return end
    local isSoD = Compat and Compat.IsSoD and Compat.IsSoD()
    SyncScrollContentHeight(w, isSoD)
    ApplyScrollChildWidth(w.scrollFrame, w.scrollChild)
end

local function SetupScrollFrameSizing(scrollFrame, scrollChild, bodyFrame)
    local function apply()
        ApplyScrollChildWidth(scrollFrame, scrollChild)
    end
    scrollFrame:SetScript("OnSizeChanged", apply)
    if bodyFrame then
        bodyFrame:SetScript("OnSizeChanged", apply)
    end
    apply()
end

local function BuildMainFrame()
    if UI._mainFrame then return UI._mainFrame end

    local f = CreateFrame("Frame", "FluxRespecMainFrame", UIParent, "BackdropTemplate")
    f:SetFrameStrata("MEDIUM")
    f:Hide()
    UI._mainFrame = f

    f:HookScript("OnShow", function()
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0, function()
                if UI._mainFrame and UI._mainFrame:IsShown() then
                    UI.Refresh()
                end
            end)
        end
    end)

    -- Header strip (class-tinted stripe).
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(36)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -6)

    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(header)
    headerBg:SetColorTexture(1, 1, 1, 0.08)
    header.bg = headerBg

    -- Spec icon (left of profile dropdown); click opens icon picker when a profile is selected.
    local specIconBtn = CreateFrame("Button", nil, header)
    specIconBtn:SetSize(32, 32)
    specIconBtn:SetPoint("LEFT", header, "LEFT", 4, 0)
    local specIconBg = specIconBtn:CreateTexture(nil, "BACKGROUND")
    specIconBg:SetAllPoints(specIconBtn)
    specIconBg:SetColorTexture(0, 0, 0, 0.45)
    local specIconTex = specIconBtn:CreateTexture(nil, "ARTWORK")
    specIconTex:SetPoint("TOPLEFT", specIconBtn, "TOPLEFT", 2, -2)
    specIconTex:SetPoint("BOTTOMRIGHT", specIconBtn, "BOTTOMRIGHT", -2, 2)
    specIconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    specIconBtn.iconTex = specIconTex
    specIconBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    specIconBtn:SetScript("OnClick", function()
        local name = R.GetActiveName()
        if name and R.IconPicker and R.IconPicker.Open then
            R.IconPicker.Open(name, specIconBtn)
        end
    end)
    specIconBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Spec icon")
        if R.GetActiveName() then
            GameTooltip:AddLine("Click to change this profile's icon. New / Rename / Delete are under Profile → Manage.", 1, 1, 1, true)
        else
            GameTooltip:AddLine("Select a profile (not “No profile”) to edit its icon.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    specIconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Load + Save on the right; New / Rename / Delete live under Profile → Manage.
    local btnLoad = MakeButton(header, "Load Profile", 118)
    btnLoad:SetPoint("RIGHT", header, "RIGHT", -4, 0)
    btnLoad:SetScript("OnClick", function()
        if R.RunLoadProfileButtonAction then
            R.RunLoadProfileButtonAction()
        end
    end)
    btnLoad:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local active = R.GetActiveName()
        if not active then
            GameTooltip:AddLine("Load Profile")
            GameTooltip:AddLine("Choose a profile in the dropdown first. “No profile” clears Respec targeting.", 1, 1, 1, true)
            GameTooltip:Show()
            return
        end

        local cpName, cpStep
        if R.GetLoadCheckpoint then
            cpName, cpStep = R.GetLoadCheckpoint()
        end
        local hasCheckpoint = cpName and cpStep and active == cpName
            and not (R.Apply and R.Apply.IsRunning and R.Apply.IsRunning())

        if hasCheckpoint then
            GameTooltip:AddLine((cpStep == "parallel") and "Resume setup" or "Resume load")
            GameTooltip:AddLine((cpStep == "parallel")
                and "Saved progress from an interrupted setup phase. Click to resume talents, gear, and runes."
                or "Saved progress from bars / consumables. Click to resume the remaining steps.", 1, 1, 1, true)
            GameTooltip:Show()
            return
        end

        local label, kind = "Load Profile", "noop"
        if R.Apply and R.Apply.NextStepLabel then
            label, kind = R.Apply.NextStepLabel(active)
        end

        GameTooltip:AddLine(label)
        if kind == "engrave" then
            GameTooltip:AddLine("One click casts one engrave (secure). Bars and consumables continue automatically after the queue.", 1, 1, 1, true)
        elseif kind == "spec" then
            GameTooltip:AddLine("Switches to the dual-spec that already matches this profile. Gear and runes start together; engrave with later clicks on this button.", 1, 1, 1, true)
        elseif kind == "talents" then
            GameTooltip:AddLine("Spends the missing talent points on the active spec. Gear and runes (if any) start together.", 1, 1, 1, true)
        elseif kind == "gear" then
            GameTooltip:AddLine("Equips the profile's gear set. Runs in parallel with talents / rune queue when those also differ.", 1, 1, 1, true)
        elseif kind == "bars" then
            GameTooltip:AddLine("Resets and re-applies the saved action bar layout.", 1, 1, 1, true)
        elseif kind == "consumables" then
            GameTooltip:AddLine("Switches the FluxNC consumables preset to match this profile.", 1, 1, 1, true)
        elseif kind == "spellbook" then
            GameTooltip:AddLine("Restores Extra Button utility slot assignments.", 1, 1, 1, true)
        elseif kind == "bindings" then
            GameTooltip:AddLine("Restores Flux spell bindings. Sticky-across-Respec rows still survive.", 1, 1, 1, true)
        elseif kind == "infoframe" then
            GameTooltip:AddLine("Restores Info Frame pins and FPS / durability / ping toggles. Pinning is still done on the character panel.", 1, 1, 1, true)
        elseif kind == "parallel-running" or kind == "bars-running" or kind == "consumables-running" then
            GameTooltip:AddLine("A load is in progress. The button updates as each step finishes.", 1, 1, 1, true)
        elseif kind == "noop" then
            GameTooltip:AddLine("Included parts already match this profile. Unchecked sections and slots are left as they are.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    btnLoad:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local btnSave = MakeButton(header, "Save", 48)
    btnSave:SetPoint("RIGHT", btnLoad, "LEFT", -2, 0)
    btnSave:SetScript("OnClick", function()
        local name = R.GetActiveName()
        if not name then
            FluxRespecShowNewProfilePopup()
            return
        end
        R.CaptureInto(name)
        UI.Refresh()
    end)
    btnSave:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Save")
        GameTooltip:AddLine("Records checked sections and slots from what you are wearing now. Unchecked parts keep their last saved data.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    btnSave:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Profile dropdown: between spec icon and Save; vertically centered with icon + buttons (not top-aligned).
    local dropdown = MakeDropdown(header)
    dropdown:SetPoint("LEFT", specIconBtn, "RIGHT", 4, 0)
    dropdown:SetPoint("RIGHT", btnSave, "LEFT", -10, 0)

    local function SyncDropdownMenuWidth(self)
        if self._fluxModern then
            return
        end
        local w = self:GetWidth()
        if w and w > 48 then
            local nw = FluxDropDownMiddleFromOuter(w)
            if self._fluxMenuWidth ~= nw then
                self._fluxMenuWidth = nw
                UIDropDownMenu_SetWidth(self, nw)
            end
        end
    end
    dropdown:SetScript("OnSizeChanged", SyncDropdownMenuWidth)
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, function()
            if dropdown then SyncDropdownMenuWidth(dropdown) end
        end)
    else
        SyncDropdownMenuWidth(dropdown)
    end
    dropdown._fluxSyncWidth = SyncDropdownMenuWidth

    -- Body: scrollable content below header to window bottom (no footer strip).
    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    body:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
    body:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 6)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)

    local scrollFrame = CreateFrame("ScrollFrame", "FluxRespecBodyScroll", body, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints(body)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(400)
    scrollChild:SetHeight(400)
    scrollFrame:SetScrollChild(scrollChild)
    SetupScrollFrameSizing(scrollFrame, scrollChild, body)

    local rows = {}
    rows.gear = MakeGearSection(scrollChild)
    rows.gear:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, 0)
    rows.gear:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, 0)

    rows.runes = MakeRunesSection(scrollChild)

    rows.consumables = MakeRow(scrollChild, 22)
    rows.consumables.icon:SetTexture("Interface\\Icons\\INV_Potion_93")
    rows.consumables.label:SetText("Consumables:")
    do
        local dd = _G.FluxBlizzardDropdown.Create(rows.consumables, "FluxRespecConsumablesPresetDropdown", 200)
        dd:SetPoint("LEFT", rows.consumables.label, "RIGHT", 4, 0)
        dd:FluxSetMenu(function()
            local nc = _G.FluxNCConsumables
            local names = {}
            if nc and nc.GetPresetNames then
                local ok, t = pcall(nc.GetPresetNames)
                if ok and type(t) == "table" then
                    names = t
                end
            end
            local active = ""
            if nc and nc.GetActivePreset then
                local ok2, a = pcall(nc.GetActivePreset)
                if ok2 and type(a) == "string" then
                    active = a
                end
            end
            local entries = {}
            for _, pname in ipairs(names) do
                entries[#entries + 1] = {
                    text = pname,
                    checked = (pname == active),
                    func = function()
                        if nc and nc.SetActivePreset then
                            pcall(nc.SetActivePreset, pname)
                        elseif R.Consumables and R.Consumables.Apply then
                            R.Consumables.Apply(pname)
                        end
                        if UI.Refresh then
                            UI.Refresh()
                        end
                    end,
                }
            end
            if #entries == 0 then
                entries[1] = { text = "No presets", disabled = true }
            end
            return entries
        end)
        rows.consumables.presetDD = dd
        rows.consumables.value:Hide()
    end

    rows.talents = MakeRow(scrollChild, 22)
    ApplyTalentRowCategoryIcon(rows.talents.icon)
    rows.talents.label:SetText("Talents:")
    local talSpec = rows.talents:CreateTexture(nil, "OVERLAY")
    talSpec:SetSize(22, 22)
    talSpec:SetDrawLayer("OVERLAY", 2)
    talSpec:SetPoint("RIGHT", rows.talents.tag, "LEFT", -6, 0)
    talSpec:Hide()
    rows.talents.valueSpecIcon = talSpec
    rows.talents.value:ClearAllPoints()
    rows.talents.value:SetPoint("LEFT", rows.talents.label, "RIGHT", 0, 0)
    rows.talents.value:SetPoint("RIGHT", talSpec, "LEFT", -4, 0)
    rows.talents.value:SetJustifyH("LEFT")

    do
        local specBtn = CreateFrame("Button", nil, rows.talents)
        specBtn:SetFrameLevel((rows.talents:GetFrameLevel() or 0) + 5)
        specBtn:SetPoint("TOPLEFT", rows.talents.value, "TOPLEFT", -4, 3)
        specBtn:SetPoint("BOTTOMRIGHT", talSpec, "BOTTOMRIGHT", 4, -3)
        specBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        specBtn:SetScript("OnClick", function()
            if R.GetActiveName and R.GetActiveName() then return end
            local n = Compat.GetNumGroups and Compat.GetNumGroups() or 1
            if n < 2 then return end
            if R.Talents and R.Talents.ToggleDualSpecGroup then
                R.Talents.ToggleDualSpecGroup()
            end
            if UI.Refresh then UI.Refresh() end
        end)
        specBtn:SetScript("OnEnter", function(self)
            if R.GetActiveName and R.GetActiveName() then return end
            local n = Compat.GetNumGroups and Compat.GetNumGroups() or 1
            if n < 2 then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Dual specialization", 1, 1, 1)
            GameTooltip:AddLine("Click to switch to your other talent group.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        specBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rows.talents._specClick = specBtn
    end

    rows.spellbook = MakeRow(scrollChild, 22)
    rows.spellbook.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    rows.spellbook.label:SetText("Utility slots:")
    if not UtilitySlotsAPI() then
        rows.spellbook:Hide()
        rows.spellbook:SetHeight(0.01)
    end

    rows.bindings = MakeRow(scrollChild, 22)
    rows.bindings.icon:SetTexture("Interface\\Icons\\Ability_Warrior_Revenge")
    rows.bindings.label:SetText("Spell bindings:")
    if not (_G.FluxSpellBindings_MatchesSnapshot and _G.FluxSpellBindings_CaptureSnapshot) then
        rows.bindings:Hide()
        rows.bindings:SetHeight(0.01)
    end

    rows.bars = MakeRow(scrollChild, 22)
    rows.bars.icon:SetTexture(ACTION_BARS_CATEGORY_ICON)
    rows.bars.label:SetText("Action Bars:")
    -- Retail: Blizzard owns action slots; row still shows Flux stance bar layout.

    rows.infoFrame = MakeRow(scrollChild, 22)
    rows.infoFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    rows.infoFrame.label:SetText("Info Frame:")

    if UI.Rows and UI.Rows.AttachAll then
        UI.Rows.AttachAll(rows)
    end

    LayoutRespecRowChain({ rows = rows }, Compat and Compat.IsSoD and Compat.IsSoD())
    SyncScrollContentHeight({ rows = rows, scrollChild = scrollChild }, Compat and Compat.IsSoD and Compat.IsSoD())

    -- Legacy header engrave button (profile-load engrave mode only).
    local runeBtn = MakeButton(scrollChild, "Engrave next rune", 140, 22)
    runeBtn:SetPoint("RIGHT", rows.runes.headerRow, "RIGHT", -4, 0)
    runeBtn:Hide()
    runeBtn:SetScript("OnClick", function()
        if R.Runes and R.Runes.CastNext then R.Runes.CastNext() end
    end)

    UI._widgets = {
        header = header,
        specIconBtn = specIconBtn,
        dropdown = dropdown,
        btnSave = btnSave,
        btnLoad = btnLoad,
        runeBtn = runeBtn,
        runePresetSave = rows.runes and rows.runes.runePresetSave,
        runePresetLoad = rows.runes and rows.runes.runePresetLoad,
        equipPresetSave = rows.gear and rows.gear.equipPresetSave,
        equipPresetLoad = rows.gear and rows.gear.equipPresetLoad,
        body = body,
        scrollFrame = scrollFrame,
        scrollChild = scrollChild,
        rows = rows,
    }

    return f
end

-- -----------------------------------------------------------------------------
-- Anchor mainFrame to the FluxWindowFrame border
-- -----------------------------------------------------------------------------

local function AnchorToWindow(tabContent)
    if not UI._mainFrame or not tabContent then return end
    local windowContent = tabContent:GetParent()
    local windowFrame = windowContent and windowContent:GetParent()
    if not windowFrame then return end

    UI._windowFrameRef = windowFrame
    UI._mainFrame:SetParent(UIParent)
    UI._mainFrame:ClearAllPoints()
    UI._mainFrame:SetPoint("TOPLEFT",     windowFrame, "TOPLEFT",     -2, 0)
    -- Align to Flux window bottom (no positive Y inset) so content can use full height.
    UI._mainFrame:SetPoint("BOTTOMRIGHT", windowFrame, "BOTTOMRIGHT", -4, 0)
    -- Above window frame so we can overlay its content area.
    local strata = windowFrame:GetFrameStrata() or "MEDIUM"
    UI._mainFrame:SetFrameStrata(strata)
    UI._mainFrame:SetFrameLevel((windowFrame:GetFrameLevel() or 0) + 5)
end

-- -----------------------------------------------------------------------------
-- Refresh
-- -----------------------------------------------------------------------------

function UI.Refresh()
    if Compat.SecureUIPanelsBlockRespecWork() then
        return
    end
    if not UI._mainFrame or not UI._mainFrame:IsShown() or not UI._widgets then return end
    local w = UI._widgets

    if w.dropdown and w.dropdown.Refresh then w.dropdown:Refresh() end
    if w.dropdown and w.dropdown._fluxSyncWidth then
        w.dropdown._fluxSyncWidth(w.dropdown)
    end

    local name = R.GetActiveName()
    local profile = name and R.GetProfile(name) or nil
    if name then
        if R.GearPicker and R.GearPicker.Hide then R.GearPicker.Hide() end
        if R.RunePicker and R.RunePicker.Hide then R.RunePicker.Hide() end
    end
    local isSoD = Compat and Compat.IsSoD and Compat.IsSoD()

    -- Spec icon (beside profile dropdown).
    local sit = w.specIconBtn and w.specIconBtn.iconTex
    if sit then
        local tex
        if name and R.GetIcon then
            tex = R.GetIcon(name)
        end
        if tex then
            sit:SetTexture(tex)
            sit:SetDesaturated(false)
        else
            sit:SetTexture(R.DefaultIcon and R.DefaultIcon() or "Interface\\Icons\\INV_Misc_QuestionMark")
            sit:SetDesaturated(true)
        end
    end

    -- Rows.
    local gearText, gearTag       = GearSummary(profile)
    local talText, talTag, talSpecIcon
    if not profile and R.Talents and R.Talents.LiveSummaryForUI then
        talText, talTag, talSpecIcon = R.Talents.LiveSummaryForUI()
    else
        talText, talTag, talSpecIcon = TalentSummary(profile)
    end
    local barText, barTag         = BarsSummary(profile)
    local sbText, sbTag           = SpellBookSummary(profile)
    local bindText, bindTag       = BindingsSummary(profile)
    local runeText, runeTag       = RunesSummary(profile)
    local consText, consTag       = ConsumablesSummary(profile)

    w.rows.gear.tag:SetText(gearTag or "")
    if w.rows.gear.tag then
        w.rows.gear.tag:SetShown(gearTag and gearTag ~= "")
    end
    -- Equipment preset dropdown text + Blizzard set icon.
    if w.rows.gear and w.rows.gear.equipPresetDD then
        local dd = w.rows.gear.equipPresetDD
        local ic = w.rows.gear.equipPresetIcon
        local epName = "Default"
        local tex
        if R.EquipmentPresets and R.EquipmentPresets.GetActivePreset then
            local ap = R.EquipmentPresets.GetActivePreset()
            if ap and ap ~= "default" then
                epName = ap
                local preset = R.EquipmentPresets.GetPreset and R.EquipmentPresets.GetPreset(ap)
                if R.EquipmentSets then
                    if preset and R.EquipmentSets.DisplayName then
                        epName = R.EquipmentSets.DisplayName(preset, ap) or ap
                    end
                    if preset and R.EquipmentSets.DisplayIcon then
                        tex = R.EquipmentSets.DisplayIcon(preset, ap)
                    end
                elseif preset then
                    tex = preset.icon
                end
            end
        end
        if dd.FluxSetText then
            dd:FluxSetText(epName)
        end
        local labelFS = w.rows.gear.label
        if ic and labelFS then
            if tex then
                ic:SetTexture(tex)
                ic:Show()
                ic:ClearAllPoints()
                ic:SetPoint("LEFT", labelFS, "RIGHT", 4, 0)
                dd:ClearAllPoints()
                dd:SetPoint("LEFT", ic, "RIGHT", 0, -1)
            else
                ic:Hide()
                dd:ClearAllPoints()
                dd:SetPoint("LEFT", labelFS, "RIGHT", 4, -1)
            end
        end
    end
    -- Equipment preset Save / Equip buttons (footer inside gear section).
    local epSave = w.equipPresetSave or (w.rows.gear and w.rows.gear.equipPresetSave)
    local epLoad = w.equipPresetLoad or (w.rows.gear and w.rows.gear.equipPresetLoad)
    w.equipPresetSave = epSave
    w.equipPresetLoad = epLoad
    if epSave and epLoad then
        local epActive = R.EquipmentPresets and R.EquipmentPresets.GetActivePreset and R.EquipmentPresets.GetActivePreset() or "default"
        local epIsDefault = (epActive == "default")
        epSave:Show()
        epSave:Enable()
        epLoad:SetShown(not epIsDefault)
        epLoad:SetText("Equip Preset")
        if w.rows.gear and w.rows.gear.presetFooter then
            w.rows.gear.presetFooter:Show()
            LayoutPresetFooterTag(w.rows.gear.presetFooter, epSave, epLoad, w.rows.gear.tag)
        end
    end
    if w.rows.gear and w.rows.gear.protectCheck then
        local lock = R.GearSetLock
        local enabled = lock and lock.IsEnabled and lock.IsEnabled() or true
        w.rows.gear.protectCheck:SetChecked(enabled)
    end
    ApplyTalentRowCategoryIcon(w.rows.talents.icon)
    w.rows.talents.value:SetText(talText)
    w.rows.talents.tag:SetText(talTag or "")
    do
        local val, vs, ttag = w.rows.talents.value, w.rows.talents.valueSpecIcon, w.rows.talents.tag
        local lab = w.rows.talents.label
        if vs and val and ttag and lab then
            val:ClearAllPoints()
            val:SetPoint("LEFT", lab, "RIGHT", 0, 0)
            val:SetJustifyH("LEFT")
            if talText ~= "—" and talSpecIcon then
                SetTalentRowSpecIconTexture(vs, talSpecIcon)
                val:SetPoint("RIGHT", vs, "LEFT", -4, 0)
            else
                vs:Hide()
                val:SetPoint("RIGHT", ttag, "LEFT", -6, 0)
            end
        end
    end
    if w.rows.talents._specClick then
        local ng = (Compat.GetNumGroups and Compat.GetNumGroups()) or 1
        w.rows.talents._specClick:SetShown(not name and ng > 1)
    end
    w.rows.bars.value:SetText(barText)
    w.rows.bars.tag:SetText(barTag or "")
    if w.rows.spellbook and w.rows.spellbook.value then
        w.rows.spellbook.value:SetText(sbText)
        w.rows.spellbook.tag:SetText(sbTag or "")
    end
    if w.rows.bindings and w.rows.bindings.value then
        w.rows.bindings.value:SetText(bindText)
        w.rows.bindings.tag:SetText(bindTag or "")
        if w.rows.bindings.tag then
            w.rows.bindings.tag:SetShown(bindTag and bindTag ~= "")
        end
    end
    w.rows.consumables.value:SetText(consText)
    w.rows.consumables.tag:SetText(consTag or "")
    if w.rows.consumables.presetDD then
        local cap = ""
        local nc = _G.FluxNCConsumables
        if nc and nc.GetActivePreset then
            local ok, a = pcall(nc.GetActivePreset)
            if ok and type(a) == "string" then cap = a end
        end
        local presetLabel = (cap ~= "") and cap or "Preset"
        if name and profile and type(profile.consumables) == "string" and profile.consumables ~= "" then
            presetLabel = profile.consumables
        end
        if w.rows.consumables.presetDD.FluxSetText then
            w.rows.consumables.presetDD:FluxSetText(presetLabel)
        end
    end

    w.rows.runes.tag:SetText(runeTag or "")
    if w.rows.runes.tag then
        w.rows.runes.tag:SetShown(isSoD and runeTag and runeTag ~= "")
    end
    if w.rows.runes.icon then
        local rtex = GetItemIconForRespec(ITEM_RUNE_OF_TELEPORTATION) or RUNES_CATEGORY_ICON_FALLBACK
        w.rows.runes.icon:SetTexture(rtex)
    end
    -- Rune preset dropdown text.
    if w.rows.runes.runePresetDD then
        local rpName = "Default"
        if R.RunePresets and R.RunePresets.GetActivePreset then
            local ap = R.RunePresets.GetActivePreset()
            if ap and ap ~= "default" then rpName = ap end
        end
        if w.rows.runes.runePresetDD.FluxSetText then
            w.rows.runes.runePresetDD:FluxSetText(rpName)
        end
    end
    -- Rune preset Save / Load (Load morphs to Engrave Rune while queue is active).
    local rpSave = w.runePresetSave or (w.rows.runes and w.rows.runes.runePresetSave)
    local rpLoad = w.runePresetLoad or (w.rows.runes and w.rows.runes.runePresetLoad)
    w.runePresetSave = rpSave
    w.runePresetLoad = rpLoad
    if isSoD and rpSave and rpLoad then
        local rpActive = R.RunePresets and R.RunePresets.GetActivePreset and R.RunePresets.GetActivePreset() or "default"
        local rpIsDefault = (rpActive == "default")
        local queueActive = R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue()
        rpSave:Show()
        rpSave:Enable()
        rpLoad:SetShown(not rpIsDefault or queueActive)
        if queueActive then
            local q = R.Runes.GetActiveQueue() or {}
            rpLoad:SetText(("Engrave Rune (%d)"):format(#q))
        else
            rpLoad:SetText("Load Preset")
        end
        if w.rows.runes and w.rows.runes.presetFooter then
            w.rows.runes.presetFooter:Show()
            RefreshRuneBarsConfirmControls(w.rows.runes, rpSave, rpLoad)
        end
    elseif rpSave then
        rpSave:Hide()
        rpLoad:Hide()
        if w.rows.runes and w.rows.runes.presetFooter then
            w.rows.runes.presetFooter:Hide()
        end
        if w.rows.runes and w.rows.runes.tag then
            w.rows.runes.tag:Hide()
        end
    end

    LayoutRespecRowChain(w, isSoD)
    RefreshGearSlotStrip(profile)
    RefreshRunesStrip(profile)
    if UI.Gear and UI.Gear.RefreshSlotChecks and w.rows.gear then
        UI.Gear.RefreshSlotChecks(w.rows.gear, profile)
    end
    if UI.RunesUI and UI.RunesUI.RefreshSlotChecks and w.rows.runes then
        UI.RunesUI.RefreshSlotChecks(w.rows.runes, profile)
    end
    if UI.Rows and UI.Rows.RefreshAll then
        UI.Rows.RefreshAll(w.rows, profile)
    end
    if UI.Rows and UI.Rows.RefreshInfoFrame then
        UI.Rows.RefreshInfoFrame(w.rows.infoFrame, profile)
    end
    local profileChanged = (UI._scrollProfileName ~= name)
    UI._scrollProfileName = name
    SyncScrollContentHeight(w, isSoD)
    -- Only jump to top when the selected profile changes — not on every refresh
    -- (BAG_UPDATE / ticker / After(0) was yanking scroll back up).
    if profileChanged then
        ResetRespecScroll(w)
    end
    if _G.C_Timer and _G.C_Timer.After then
        local wref, sref, resetScroll = w, isSoD, profileChanged
        _G.C_Timer.After(0, function()
            if Compat.SecureUIPanelsBlockRespecWork() then
                return
            end
            if UI._widgets == wref then
                SyncScrollContentHeight(wref, sref)
                ApplyScrollChildWidth(wref.scrollFrame, wref.scrollChild)
                if resetScroll then
                    ResetRespecScroll(wref)
                end
                if wref.dropdown and wref.dropdown._fluxSyncWidth then
                    -- Force re-apply: clear cache so a stale width from pre-layout GetWidth() is corrected.
                    wref.dropdown._fluxMenuWidth = nil
                    wref.dropdown._fluxSyncWidth(wref.dropdown)
                end
            end
        end)
    end

    -- Legacy header engrave button: profile-load only when footer Load/Engrave morph is not shown.
    do
        local queueActive = R.Runes and R.Runes.HasActiveQueue and R.Runes.HasActiveQueue()
        local engraveMode = R.Apply and R.Apply.IsEngraveButtonMode and R.Apply.IsEngraveButtonMode()
        local footerEngrave = w.runePresetLoad and w.runePresetLoad:IsShown() and queueActive
        if isSoD and w.runeBtn and engraveMode and queueActive and not footerEngrave then
            local q = R.Runes.GetActiveQueue() or {}
            w.runeBtn:SetText(("Engrave next rune (%d)"):format(#q))
            w.runeBtn:Show()
        elseif w.runeBtn then
            w.runeBtn:Hide()
        end
    end

    -- Main button label: next specific step (never "Apply profile"). Checkpoint resume takes priority
    -- when a saved load exists for this profile and nothing is currently running.
    local engraveMode = R.Apply and R.Apply.IsEngraveButtonMode and R.Apply.IsEngraveButtonMode()
    local applying = R.Apply and R.Apply.IsRunning and R.Apply.IsRunning()
    local cpName, cpStep
    if R.GetLoadCheckpoint then
        cpName, cpStep = R.GetLoadCheckpoint()
    end
    local hasCheckpoint = cpName and cpStep and name and cpName == name and not applying

    local label, kind = "Load Profile", "none"
    if name and R.Apply and R.Apply.NextStepLabel then
        label, kind = R.Apply.NextStepLabel(name)
    end

    if hasCheckpoint and not engraveMode then
        w.btnLoad:SetText((cpStep == "parallel") and "Resume setup…" or "Resume load…")
        w.btnLoad:SetWidth(math.max(124, 110))
    else
        w.btnLoad:SetText(label)
        w.btnLoad:SetWidth(math.max(118, 110))
    end

    do
        -- Clickable whenever a profile is selected; during a running load, only engrave mode accepts clicks.
        local canUseLoad = name ~= nil and (engraveMode or not applying)
        if canUseLoad then
            w.btnLoad:Enable()
        else
            w.btnLoad:Disable()
        end
    end

    -- Tint class-themed elements.
    local r, g, b = ThemeRGB()
    if w.header and w.header.bg then
        w.header.bg:SetColorTexture(r, g, b, 0.16)
    end
    for _, btn in ipairs({ w.btnSave, w.btnLoad }) do
        if btn and btn.GetFontString then
            SetBlizzardPanelButtonTextColor(btn:GetFontString())
        end
    end
    if w.runeBtn and w.runeBtn.GetFontString then
        local fs = w.runeBtn:GetFontString()
        if fs then
            fs:SetTextColor(r, g, b)
        end
    end
    for _, btn in ipairs({ w.runePresetSave, w.runePresetLoad, w.equipPresetSave, w.equipPresetLoad }) do
        if btn and btn.GetFontString then
            local fs = btn:GetFontString()
            if fs then
                fs:SetTextColor(r, g, b)
            end
        end
    end
end

-- -----------------------------------------------------------------------------
-- Tab onShow / onHide
-- -----------------------------------------------------------------------------

function UI.Show(tab)
    if not tab or not tab.content then return end
    local isFirstBuild = (UI._mainFrame == nil)
    BuildMainFrame()
    UI._tabContentRef = tab.content
    AnchorToWindow(tab.content)
    UI._mainFrame:Show()
    UI.Refresh()

    local function refreshWithWidthResync()
        if UI._mainFrame and UI._mainFrame:IsShown() then
            if UI._widgets and UI._widgets.dropdown then
                UI._widgets.dropdown._fluxMenuWidth = nil
            end
            UI.Refresh()
        end
    end

    if _G.C_Timer and _G.C_Timer.After then
        -- First-time open after login/reload can race layout; run a short
        -- refresh burst so dropdown width is corrected without tab re-entry.
        if isFirstBuild then
            _G.C_Timer.After(0,    refreshWithWidthResync)
            _G.C_Timer.After(0.05, refreshWithWidthResync)
            _G.C_Timer.After(0.18, refreshWithWidthResync)
        else
            _G.C_Timer.After(0.1, refreshWithWidthResync)
        end
    end
end

function UI.Hide(tab)
    if R.IconPicker and R.IconPicker.Close then pcall(R.IconPicker.Close) end
    if R.GearPicker and R.GearPicker.Hide then R.GearPicker.Hide() end
    if R.RunePicker and R.RunePicker.Hide then R.RunePicker.Hide() end
    if UI._mainFrame then UI._mainFrame:Hide() end
end

-- -----------------------------------------------------------------------------
-- Listeners
-- -----------------------------------------------------------------------------

R.On("PROFILES_CHANGED",   function() UI.Refresh() end)
R.On("PROFILE_CREATED",    function() UI.Refresh() end)
R.On("PROFILE_SAVED",      function() UI.Refresh() end)
R.On("PROFILE_UPDATED",    function() UI.Refresh() end)
R.On("PROFILE_DELETED",    function() UI.Refresh() end)
R.On("RUNE_PRESET_CHANGED", function() UI.Refresh() end)
R.On("RUNE_PRESET_SAVED",  function() UI.Refresh() end)
R.On("RUNE_PRESET_APPLIED", function() UI.Refresh() end)
R.On("EQUIPMENT_PRESET_CHANGED", function() UI.Refresh() end)
R.On("EQUIPMENT_PRESET_SAVED", function() UI.Refresh() end)
R.On("EQUIPMENT_PRESET_APPLIED", function() UI.Refresh() end)
R.On("EQUIPMENT_SETS_SYNCED", function() UI.Refresh() end)
R.On("PROFILE_RENAMED",    function() UI.Refresh() end)
R.On("ACTIVE_CHANGED",     function() UI.Refresh() end)
R.On("RUNE_QUEUE_CHANGED", function() UI.Refresh() end)
R.On("CONSUMABLES_CONFIG_CHANGED", function() UI.Refresh() end)

R.On("APPLY_START", function() UI.Refresh() end)
R.On("APPLY_DONE", function()
    UI.Refresh()
end)
-- After talent apply callback runs, Apply._state is current — refresh button label (Retail loadout path).
R.On("TALENTS_APPLIED", function()
    UI.Refresh()
end)

-- Live refresh: profile vs current talents/gear/bars/runes when the player changes setup.
do
    if not UI._liveFrame then
        UI._liveFrame = CreateFrame("Frame")
        local due = 0
        local function scheduleRefresh(_, event)
            if Compat.SecureUIPanelsBlockRespecWork() then
                return
            end
            local delay = 0.08
            -- TRAIT_CONFIG_UPDATED fires in a tight loop during talent changes; debounce harder on Retail.
            if Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts() and event == "TRAIT_CONFIG_UPDATED" then
                -- Pipeline already refreshes on TALENTS_APPLIED / APPLY_DONE; skip redundant work mid-load.
                if R.Apply and R.Apply.IsRunning and R.Apply.IsRunning() then
                    return
                end
                delay = 0.5
            end
            due = (GetTime and GetTime() or 0) + delay
            if UI._liveFrame:GetScript("OnUpdate") then return end
            UI._liveFrame:SetScript("OnUpdate", function(self)
                if (GetTime and GetTime() or 0) < due then
                    return
                end
                self:SetScript("OnUpdate", nil)
                if Compat.SecureUIPanelsBlockRespecWork() then
                    return
                end
                if UI._mainFrame and UI._mainFrame:IsShown() then
                    UI.Refresh()
                end
            end)
        end
        UI._liveFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        UI._liveFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
        UI._liveFrame:RegisterEvent("BAG_UPDATE_DELAYED")
        UI._liveFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        UI._liveFrame:RegisterEvent("PET_BAR_UPDATE")
        UI._liveFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        UI._liveFrame:RegisterEvent("UPDATE_BINDINGS")
        -- RUNE_UPDATED: only on engraving-capable clients; see FluxSafeRegisterEvent in FluxAPICompat.lua
        if _G.FluxSafeRegisterEvent then
            FluxSafeRegisterEvent(UI._liveFrame, "RUNE_UPDATED")
        else
            pcall(function()
                UI._liveFrame:RegisterEvent("RUNE_UPDATED")
            end)
        end
        UI._liveFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        pcall(function() UI._liveFrame:RegisterEvent("BANKFRAME_OPENED") end)
        pcall(function() UI._liveFrame:RegisterEvent("BANKFRAME_CLOSED") end)
        pcall(function() UI._liveFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED") end)
        pcall(function() UI._liveFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED") end)
        pcall(function() UI._liveFrame:RegisterEvent("TRAIT_CONFIG_UPDATED") end)
        UI._liveFrame:SetScript("OnEvent", scheduleRefresh)
    end
    if not UI._equipFrame then
        UI._equipFrame = CreateFrame("Frame")
        UI._equipFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        UI._equipFrame:SetScript("OnEvent", function(_, _, changedSlotID)
            ScheduleEquipUiRefresh(changedSlotID)
        end)
    end
end

R.UI = UI
