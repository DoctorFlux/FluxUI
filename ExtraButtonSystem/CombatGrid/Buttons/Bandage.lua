--[[ ExtraButtonSystem/CombatGrid/Buttons/Bandage.lua — Inventory-backed ]]

FluxCombatBandage = FluxCombatBandage or {}
local Module = FluxCombatBandage

local PLACEHOLDER = "Interface\\Icons\\INV_Misc_Bandage_01"

local function AppendTooltip(btn, tip)
    local Bridge = FluxEBSConsumableBridge
    local itemID = Module._trackedItemID or btn.ItemId
    Bridge.AppendCraftTooltipLines(tip, "bandage")
    Bridge.AppendTierStatusLines(tip, "bandage", itemID, btn)
end

local function ApplyRC(btn)
    FluxEBSConsumableBridge.ApplyCraftOrRestockRightClick(btn, "bandage")
end

local function ShouldShow()
    local EBV = _G.FluxExtraButtonVisibility
    if EBV and EBV.QuickGate then
        local gate = EBV.QuickGate("combat_bandage")
        if gate ~= nil then
            return gate
        end
    end
    local Bridge = FluxEBSConsumableBridge
    local smart = false
    if Bridge and Bridge.KeepConsumableSlot and Bridge.KeepConsumableSlot("bandage", Module) then
        smart = true
    elseif Bridge then
        local best = Bridge.GetBestOwned and Bridge.GetBestOwned("bandage")
        if best and best.itemID then
            smart = true
        elseif Bridge.CanCraft and Bridge.CanCraft("bandage") then
            smart = true
        end
    end
    if EBV and EBV.Apply then
        return EBV.Apply("combat_bandage", smart)
    end
    return smart
end

function Module.Create(grid)
    local btn = grid:CreateButton({
        columnGroup = "bandage",
        columnPriority = 100,
        order = 1,
        size = grid.ButtonSize,
    })
    if not btn then
        return
    end
    FluxEBSButtonRefresh.Attach({
        module = Module,
        btn = btn,
        kind = "bandage",
        kindFlag = "IsBandageButton",
        placeholderIcon = PLACEHOLDER,
        placeholderLabel = "Bandage",
        listenerKey = "FluxCombatBandage",
        bindingName = "FLUXCOMBAT_BANDAGE",
        listenerRegions = { "bags", "professions" },
        reapplyCraftOnBag = true,
        combatGridCoalesce = true,
        shouldShow = ShouldShow,
        showTooltipExtras = AppendTooltip,
        applyRightClick = ApplyRC,
    })
end

_G.FluxCombatBandage = Module
return Module
