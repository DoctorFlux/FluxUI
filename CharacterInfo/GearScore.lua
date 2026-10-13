-- Player GearScore: prefer TacoTip's TT_GS when loaded; otherwise same formula as TacoTip/GearScoreLite.
local _, ns = ...
local module = ns.CharacterStats
if not (module and module.useClassicPaperDollChrome) then return end

local function GetBracketSize()
    local pid = _G.WOW_PROJECT_ID
    if _G.WOW_PROJECT_WRATH_CLASSIC and pid == _G.WOW_PROJECT_WRATH_CLASSIC then
        return 1000
    end
    if _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC and pid == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        return 400
    end
    return 200
end

local BRACKET_SIZE = GetBracketSize()
local MAX_SCORE = BRACKET_SIZE * 6 - 1

local GS_ItemTypes = {
    ["INVTYPE_RELIC"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
    ["INVTYPE_TRINKET"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 33, ["Enchantable"] = false },
    ["INVTYPE_2HWEAPON"] = { ["SlotMOD"] = 2.000, ["ItemSlot"] = 16, ["Enchantable"] = true },
    ["INVTYPE_WEAPONMAINHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 16, ["Enchantable"] = true },
    ["INVTYPE_WEAPONOFFHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
    ["INVTYPE_RANGED"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = true },
    ["INVTYPE_THROWN"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
    ["INVTYPE_RANGEDRIGHT"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
    ["INVTYPE_SHIELD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
    ["INVTYPE_WEAPON"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 36, ["Enchantable"] = true },
    ["INVTYPE_HOLDABLE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = false },
    ["INVTYPE_HEAD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 1, ["Enchantable"] = true },
    ["INVTYPE_NECK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 2, ["Enchantable"] = false },
    ["INVTYPE_SHOULDER"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 3, ["Enchantable"] = true },
    ["INVTYPE_CHEST"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
    ["INVTYPE_ROBE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
    ["INVTYPE_WAIST"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 6, ["Enchantable"] = false },
    ["INVTYPE_LEGS"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 7, ["Enchantable"] = true },
    ["INVTYPE_FEET"] = { ["SlotMOD"] = 0.75, ["ItemSlot"] = 8, ["Enchantable"] = true },
    ["INVTYPE_WRIST"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 9, ["Enchantable"] = true },
    ["INVTYPE_HAND"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 10, ["Enchantable"] = true },
    ["INVTYPE_FINGER"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 31, ["Enchantable"] = false },
    ["INVTYPE_CLOAK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 15, ["Enchantable"] = true },
    ["INVTYPE_BODY"] = { ["SlotMOD"] = 0, ["ItemSlot"] = 4, ["Enchantable"] = false },
}

local GS_Formula = {
    ["A"] = {
        [4] = { ["A"] = 91.4500, ["B"] = 0.6500 },
        [3] = { ["A"] = 81.3750, ["B"] = 0.8125 },
        [2] = { ["A"] = 73.0000, ["B"] = 1.0000 },
    },
    ["B"] = {
        [4] = { ["A"] = 26.0000, ["B"] = 1.2000 },
        [3] = { ["A"] = 0.7500, ["B"] = 1.8000 },
        [2] = { ["A"] = 8.0000, ["B"] = 2.0000 },
        [1] = { ["A"] = 0.0000, ["B"] = 2.2500 },
    },
    ["C"] = {
        [4] = { ["A"] = 0.2500, ["B"] = 1.6275 },
    },
}

local GS_Quality = {
    [BRACKET_SIZE * 6] = {
        ["Red"] = { ["A"] = 0.94, ["B"] = BRACKET_SIZE * 5, ["C"] = 0.00006, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.47, ["B"] = BRACKET_SIZE * 5, ["C"] = 0.00047, ["D"] = -1 },
        ["Green"] = { ["A"] = 0, ["B"] = 0, ["C"] = 0, ["D"] = 0 },
        ["Description"] = "Legendary",
    },
    [BRACKET_SIZE * 5] = {
        ["Red"] = { ["A"] = 0.69, ["B"] = BRACKET_SIZE * 4, ["C"] = 0.00025, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.28, ["B"] = BRACKET_SIZE * 4, ["C"] = 0.00019, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.97, ["B"] = BRACKET_SIZE * 4, ["C"] = 0.00096, ["D"] = -1 },
        ["Description"] = "Epic",
    },
    [BRACKET_SIZE * 4] = {
        ["Red"] = { ["A"] = 0.0, ["B"] = BRACKET_SIZE * 3, ["C"] = 0.00069, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.5, ["B"] = BRACKET_SIZE * 3, ["C"] = 0.00022, ["D"] = -1 },
        ["Green"] = { ["A"] = 1, ["B"] = BRACKET_SIZE * 3, ["C"] = 0.00003, ["D"] = -1 },
        ["Description"] = "Superior",
    },
    [BRACKET_SIZE * 3] = {
        ["Red"] = { ["A"] = 0.12, ["B"] = BRACKET_SIZE * 2, ["C"] = 0.00012, ["D"] = -1 },
        ["Blue"] = { ["A"] = 1, ["B"] = BRACKET_SIZE * 2, ["C"] = 0.00050, ["D"] = -1 },
        ["Green"] = { ["A"] = 0, ["B"] = BRACKET_SIZE * 2, ["C"] = 0.001, ["D"] = 1 },
        ["Description"] = "Uncommon",
    },
    [BRACKET_SIZE * 2] = {
        ["Red"] = { ["A"] = 1, ["B"] = BRACKET_SIZE, ["C"] = 0.00088, ["D"] = -1 },
        ["Blue"] = { ["A"] = 1, ["B"] = 000, ["C"] = 0.00000, ["D"] = 0 },
        ["Green"] = { ["A"] = 1, ["B"] = BRACKET_SIZE, ["C"] = 0.001, ["D"] = -1 },
        ["Description"] = "Common",
    },
    [BRACKET_SIZE] = {
        ["Red"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Description"] = "Trash",
    },
}

local function GetQuality(ItemScore)
    ItemScore = tonumber(ItemScore)
    if not ItemScore then
        return 0, 0, 0, "Trash"
    end
    if ItemScore > MAX_SCORE then
        ItemScore = MAX_SCORE
    end
    for i = 0, 6 do
        if (ItemScore > i * BRACKET_SIZE) and (ItemScore <= ((i + 1) * BRACKET_SIZE)) then
            local Red = GS_Quality[(i + 1) * BRACKET_SIZE].Red["A"]
                + (((ItemScore - GS_Quality[(i + 1) * BRACKET_SIZE].Red["B"]) * GS_Quality[(i + 1) * BRACKET_SIZE].Red["C"]) * GS_Quality[(i + 1) * BRACKET_SIZE].Red["D"])
            local Blue = GS_Quality[(i + 1) * BRACKET_SIZE].Green["A"]
                + (((ItemScore - GS_Quality[(i + 1) * BRACKET_SIZE].Green["B"]) * GS_Quality[(i + 1) * BRACKET_SIZE].Green["C"]) * GS_Quality[(i + 1) * BRACKET_SIZE].Green["D"])
            local Green = GS_Quality[(i + 1) * BRACKET_SIZE].Blue["A"]
                + (((ItemScore - GS_Quality[(i + 1) * BRACKET_SIZE].Blue["B"]) * GS_Quality[(i + 1) * BRACKET_SIZE].Blue["C"]) * GS_Quality[(i + 1) * BRACKET_SIZE].Blue["D"])
            return Red, Green, Blue, GS_Quality[(i + 1) * BRACKET_SIZE].Description
        end
    end
    return 0.1, 0.1, 0.1, "Trash"
end

local function GetItemScore(ItemLink)
    if not ItemLink then
        return 0, nil
    end
    local _name, _link, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(ItemLink)
    if ItemLink and ItemRarity and ItemLevel and ItemEquipLoc and GS_ItemTypes[ItemEquipLoc] then
        local Table
        local QualityScale = 1
        local GearScore = 0
        local Scale = 1.8618
        if ItemRarity == 5 then
            QualityScale = 1.3
            ItemRarity = 4
        elseif ItemRarity == 1 then
            QualityScale = 0.005
            ItemRarity = 2
        elseif ItemRarity == 0 then
            QualityScale = 0.005
            ItemRarity = 2
        elseif ItemRarity == 7 then
            ItemRarity = 3
            ItemLevel = 187.05
        end
        if ItemLevel < 100 and ItemRarity == 4 then
            Table = GS_Formula["C"]
        elseif ItemLevel < 168 and ItemRarity == 4 then
            Table = GS_Formula["B"]
        elseif ItemLevel < 148 and ItemRarity == 3 then
            Table = GS_Formula["B"]
        elseif ItemLevel < 138 and ItemRarity == 2 then
            Table = GS_Formula["B"]
        elseif ItemLevel <= 120 then
            Table = GS_Formula["B"]
        else
            Table = GS_Formula["A"]
        end
        if ItemRarity >= 2 and ItemRarity <= 4 then
            local Red, Green, Blue = GetQuality((math.floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * 1 * Scale)) * 11.25)
            GearScore = math.floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * GS_ItemTypes[ItemEquipLoc].SlotMOD * Scale * QualityScale)
            if ItemLevel == 187.05 then
                ItemLevel = 0
            end
            if GearScore < 0 then
                GearScore = 0
                Red, Green, Blue = GetQuality(1)
            end
            return GearScore, ItemEquipLoc
        end
    end
    return 0, nil
end

local function TryTacoTipGearScore()
    local TT = _G.TT_GS
    if TT and type(TT.GetScore) == "function" then
        local ok, gs = pcall(TT.GetScore, TT, "player", false)
        if ok and type(gs) == "number" and gs > 0 then
            return gs
        end
    end
    return nil
end

local function ComputeGearScorePlayerInternal()
    local _, classToken = UnitClass("player")
    local PlayerEnglishClass = classToken

    local GearScore = 0
    local ItemCount = 0
    local LevelTotal = 0
    local TitanGrip = 1

    local mainHandLink = GetInventoryItemLink("player", 16)
    local offHandLink = GetInventoryItemLink("player", 17)

    if mainHandLink and offHandLink then
        local _n, _l, _r, _il, _ml, _t, _st, _sc, ItemEquipLoc = GetItemInfo(mainHandLink)
        if ItemEquipLoc == "INVTYPE_2HWEAPON" then
            TitanGrip = 0.5
        end
    end

    if offHandLink then
        local _n, _l, _r, _il, _ml, _t, _st, _sc, ItemEquipLoc = GetItemInfo(offHandLink)
        if ItemEquipLoc == "INVTYPE_2HWEAPON" then
            TitanGrip = 0.5
        end
        local TempScore, _loc = GetItemScore(offHandLink)
        if PlayerEnglishClass == "HUNTER" then
            TempScore = TempScore * 0.3164
        end
        GearScore = GearScore + TempScore * TitanGrip
        ItemCount = ItemCount + 1
        local _n2, _l2, _r2, ilvl = GetItemInfo(offHandLink)
        if ilvl then LevelTotal = LevelTotal + ilvl end
    end

    for i = 1, 18 do
        if i ~= 4 and i ~= 17 then
            local link = GetInventoryItemLink("player", i)
            if link then
                local TempScore, ItemEquipLoc = GetItemScore(link)
                local _n, _l, _r, ItemLevel = GetItemInfo(link)
                if PlayerEnglishClass == "HUNTER" then
                    if i == 16 then
                        TempScore = TempScore * 0.3164
                    elseif i == 18 then
                        TempScore = TempScore * 5.3224
                    end
                end
                if i == 16 then
                    TempScore = TempScore * TitanGrip
                end
                GearScore = GearScore + TempScore
                ItemCount = ItemCount + 1
                if ItemLevel then LevelTotal = LevelTotal + ItemLevel end
            end
        end
    end

    if GearScore > 0 and ItemCount > 0 then
        return math.floor(GearScore)
    end
    return nil
end

--- @return number|nil total GearScore (TacoTip when available + agrees, else Flux internal).
function _G.FluxCSC_GetPlayerGearScore()
    local tt = TryTacoTipGearScore()
    if tt then
        return tt
    end
    return ComputeGearScorePlayerInternal()
end

--- RGB 0–1 for GearScore tier (TacoTip character sheet: same tint for GS and avg iLvl). Uses TT_GS:GetQuality when present.
function _G.FluxCSC_GetGearScoreQualityRGB(gs)
    local n = tonumber(gs)
    if not n or n <= 0 then
        return 0.53, 0.53, 0.53
    end
    local TT = _G.TT_GS
    if TT and type(TT.GetQuality) == "function" then
        local ok, r, g, b = pcall(TT.GetQuality, TT, n)
        if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then
            return r, g, b
        end
    end
    local r, g, b = GetQuality(n)
    return r, g, b
end
