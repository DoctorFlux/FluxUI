--[[ ExtraButtonSystem/CombatGrid/Buttons/HealPotion.lua — Inventory-backed ]]

FluxCombatHealPotion = FluxCombatHealPotion or {}
local Module = FluxCombatHealPotion

local PLACEHOLDER = "Interface\\Icons\\INV_Potion_54"

local function AppendTooltip(btn, tip)
    local Bridge = FluxEBSConsumableBridge
    local face = Bridge.CombatSwapTooltipKind and Bridge.CombatSwapTooltipKind(btn, "healPotion") or "healPotion"
    if face == "food" then
        Bridge.AppendTierStatusLines(tip, "food", btn and btn.ItemId, btn)
        tip:AddLine("In combat: Healing potion", 0.65, 0.65, 0.65)
        return
    end
    local itemID = Module._trackedItemID or btn.ItemId
    Bridge.AppendCraftTooltipLines(tip, "healPotion")
    Bridge.AppendTierStatusLines(tip, "healPotion", itemID, btn)
    if btn and btn._fluxCombatSwapBody then
        tip:AddLine("Out of combat: Food", 0.65, 0.65, 0.65)
    end
end

local function ApplyRC(btn)
    FluxEBSConsumableBridge.ApplyCraftOrRestockRightClick(btn, "healPotion")
end

local function ShouldShow()
    local EBV = _G.FluxExtraButtonVisibility
    if EBV and EBV.QuickGate then
        local gate = EBV.QuickGate("combat_healPotion")
        if gate ~= nil then
            return gate
        end
    end
    local Bridge = FluxEBSConsumableBridge
    local smart = false
    if Bridge and Bridge.KeepConsumableSlot and Bridge.KeepConsumableSlot("healPotion", Module) then
        smart = true
    elseif Bridge then
        local best = Bridge.GetBestOwned and Bridge.GetBestOwned("healPotion")
        if best and best.itemID then
            smart = true
        elseif Bridge.CanCraft and Bridge.CanCraft("healPotion") then
            smart = true
        end
    end
    if EBV and EBV.Apply then
        return EBV.Apply("combat_healPotion", smart)
    end
    return smart
end

function Module.Create(grid)
    local btn = grid:CreateButton({
        columnGroup = "healing",
        columnPriority = 10,
        order = 2,
        size = grid.ButtonSize,
    })
    if not btn then
        return
    end
    FluxEBSButtonRefresh.Attach({
        module = Module,
        btn = btn,
        kind = "healPotion",
        kindFlag = "IsHealPotionButton",
        placeholderIcon = PLACEHOLDER,
        placeholderLabel = "Healing potions",
        listenerKey = "FluxCombatHealPotion",
        bindingName = "FLUXCOMBAT_HEALPOT",
        listenerRegions = { "bags", "professions" },
        reapplyCraftOnBag = true,
        combatGridCoalesce = true,
        shouldShow = ShouldShow,
        showTooltipExtras = AppendTooltip,
        applyRightClick = ApplyRC,
    })
end

_G.FluxCombatHealPotion = Module
return Module
