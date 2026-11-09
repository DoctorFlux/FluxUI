--[[ ExtraButtonSystem/CombatGrid/Buttons/ManaPotion.lua — Inventory-backed ]]

FluxCombatManaPotion = FluxCombatManaPotion or {}
local Module = FluxCombatManaPotion

local PLACEHOLDER = "Interface\\Icons\\INV_Potion_76"

local function AppendTooltip(btn, tip)
    local Bridge = FluxEBSConsumableBridge
    local face = Bridge.CombatSwapTooltipKind and Bridge.CombatSwapTooltipKind(btn, "manaPotion") or "manaPotion"
    if face == "water" then
        Bridge.AppendTierStatusLines(tip, "water", btn and btn.ItemId, btn)
        tip:AddLine("In combat: Mana potion", 0.65, 0.65, 0.65)
        return
    end
    local itemID = Module._trackedItemID or btn.ItemId
    Bridge.AppendCraftTooltipLines(tip, "manaPotion")
    Bridge.AppendTierStatusLines(tip, "manaPotion", itemID, btn)
    if btn and btn._fluxCombatSwapBody then
        tip:AddLine("Out of combat: Water", 0.65, 0.65, 0.65)
    end
end

local function ApplyRC(btn)
    FluxEBSConsumableBridge.ApplyCraftOrRestockRightClick(btn, "manaPotion")
end

local function ShouldShow()
    local EBV = _G.FluxExtraButtonVisibility
    if EBV and EBV.QuickGate then
        local gate = EBV.QuickGate("combat_manaPotion")
        if gate ~= nil then
            return gate
        end
    end
    local smart = false
    local B = _G.FluxConsumableBest
    -- Pool-based mana relevance (GetPlayerHasMana), not display power / shapeshift form.
    -- Druids keep a mana pool in cat/bear — do not hide on form change.
    if not (B and B.IsManaKindRelevant and not B.IsManaKindRelevant("manaPotion")) then
        local Bridge = FluxEBSConsumableBridge
        if Bridge and Bridge.KeepConsumableSlot and Bridge.KeepConsumableSlot("manaPotion", Module) then
            smart = true
        elseif Bridge then
            local best = Bridge.GetBestOwned and Bridge.GetBestOwned("manaPotion")
            if best and best.itemID then
                smart = true
            elseif Bridge.CanCraft and Bridge.CanCraft("manaPotion") then
                smart = true
            end
        end
    end
    if EBV and EBV.Apply then
        return EBV.Apply("combat_manaPotion", smart)
    end
    return smart
end

function Module.Create(grid)
    local btn = grid:CreateButton({
        columnGroup = "mana",
        columnPriority = 20,
        order = 2,
        size = grid.ButtonSize,
    })
    if not btn then
        return
    end
    FluxEBSButtonRefresh.Attach({
        module = Module,
        btn = btn,
        kind = "manaPotion",
        kindFlag = "IsManaPotionButton",
        placeholderIcon = PLACEHOLDER,
        placeholderLabel = "Mana potions",
        listenerKey = "FluxCombatManaPotion",
        bindingName = "FLUXCOMBAT_MANAPOT",
        listenerRegions = { "bags", "professions" },
        reapplyCraftOnBag = true,
        combatGridCoalesce = true,
        shouldShow = ShouldShow,
        showTooltipExtras = AppendTooltip,
        applyRightClick = ApplyRC,
    })
end

_G.FluxCombatManaPotion = Module
return Module
