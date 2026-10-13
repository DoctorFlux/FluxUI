--[[
    Hidden named Button frames for /click ... macros.
    Avoids /run in SecureActionButton macrotext (retail "Allow custom script" dialog).
]]

FluxMacroClickProxies = FluxMacroClickProxies or {}
local P = FluxMacroClickProxies

local function makeClickProxy(name, onClick, opts)
    local b = CreateFrame("Button", name, UIParent)
    b:SetSize(1, 1)
    -- Hidden frames often ignore /click. Off-screen + shown keeps a click target.
    b:ClearAllPoints()
    b:SetPoint("CENTER", UIParent, "TOPLEFT", -2500, 2500)
    b:SetAlpha(0)
    b:EnableMouse(false)
    if opts and opts.keepHidden then
        b:Hide()
    else
        b:Show()
    end
    -- AnyDown+AnyUp: CombatGrid SecureActionButtons use AnyDown; Up-only proxies
    -- miss /click when ActionButtonUseKeyDown is set (same pattern as flyouts).
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetScript("OnClick", onClick)
    return b
end

local function CraftClickMacro(name)
    -- HUD type2 can arrive as down or up; fire both. ExecuteCraft locks to one item.
    return "/click " .. name .. " LeftButton 1\n/click " .. name .. " LeftButton 0"
end

-- Macro strings (use in SetAttribute macrotext*; no /run)
P.MACRO_CRAFT_BANDAGE = CraftClickMacro("FluxMacroProxy_CraftBandage")
P.MACRO_CRAFT_HEAL_POTION = CraftClickMacro("FluxMacroProxy_CraftHealPotion")
P.MACRO_CRAFT_MANA_POTION = CraftClickMacro("FluxMacroProxy_CraftManaPotion")
P.MACRO_CONSUMABLES_CONFIG = "/click FluxMacroProxy_ConsumablesConfig"
P.MACRO_COLLECTIONS_TAB1 = "/click FluxMacroProxy_CollectionsTab1"
P.MACRO_COLLECTIONS_TAB3 = "/click FluxMacroProxy_CollectionsTab3"
P.MACRO_HEARTH_TOYBOX = "/click FluxMacroProxy_HearthToyBox"
P.MACRO_HEARTH_TELEPORT_FLYOUT = "/click FluxMacroProxy_HearthTeleportFlyout"
P.MACRO_MOUNT_ITEM_FLYOUT = "/click FluxMacroProxy_MountItemFlyout"
P.MACRO_MOUNT_OPEN_UI = "/click FluxMacroProxy_MountOpenUI"
P.MACRO_MOUNT_TOGGLE_MODE = "/click FluxMacroProxy_MountToggleMode"
P.MACRO_TELEPORT_TOGGLE_MODE = "/click FluxMacroProxy_TeleportToggleMode"
P.MACRO_TELEPORT_SHOW_FLYOUT = "/click FluxMacroProxy_TeleportShowFlyout"
P.MACRO_FOOD_TOGGLE_RECUPERATE = "/click FluxMacroProxy_FoodToggleRecuperate"
P.MACRO_FOOD_DELETE_STACK = "/click FluxMacroProxy_FoodDeleteStack"
P.MACRO_FOOD_RESTOCK_TOGGLE = "/click FluxMacroProxy_FoodRestockToggle"
P.MACRO_WATER_DELETE_STACK = "/click FluxMacroProxy_WaterDeleteStack"
P.MACRO_WATER_RESTOCK_TOGGLE = "/click FluxMacroProxy_WaterRestockToggle"
P.MACRO_GRID_TOGGLE_MOUNT_KIND = "/click FluxMacroProxy_GridToggleMountKind"
P.MACRO_GRID_TOGGLE_MAGE_HEADER = "/click FluxMacroProxy_GridToggleMageHeader"

-- Open Mount UI macro block (replaces #showtooltip + /run in GetOpenMountUIMacro)
P.MACRO_MOUNT_OPEN_UI_BLOCK = [[#showtooltip
/click FluxMacroProxy_MountOpenUI]]

local function CraftApi()
    local Flux = _G.Flux
    local inv = Flux and Flux.Inventory
    if inv and inv.Craft then
        return inv.Craft
    end
    return _G.FluxInv and _G.FluxInv.Craft
end

local function SuppressCombatCraftChecked(module)
    local btn = module and module.Button
    local Bridge = _G.FluxEBSConsumableBridge
    if not btn or not Bridge then
        return
    end
    if Bridge.SuppressCheckedVisualSettle then
        Bridge.SuppressCheckedVisualSettle(btn)
        return
    end
    if not Bridge.SuppressCheckedVisual then
        return
    end
    Bridge.SuppressCheckedVisual(btn)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if Bridge.SuppressCheckedVisual then
                Bridge.SuppressCheckedVisual(btn)
            end
        end)
    end
end

-- Do not skip mouse-up here. HUD type2 /click (and ActionButtonUseKeyDown)
-- often delivers only down == false; ignoring up makes craft never run.
-- ExecuteCraft still blocks a second kind (heal vs mana) in the same press.
makeClickProxy("FluxMacroProxy_CraftBandage", function()
    local Craft = CraftApi()
    if Craft and Craft.ExecuteBandageCraft then
        Craft.ExecuteBandageCraft()
    end
    SuppressCombatCraftChecked(_G.FluxCombatBandage)
end)

makeClickProxy("FluxMacroProxy_CraftHealPotion", function()
    local Craft = CraftApi()
    if Craft and Craft.ExecuteHealPotionCraft then
        Craft.ExecuteHealPotionCraft()
    end
    SuppressCombatCraftChecked(_G.FluxCombatHealPotion)
end)

makeClickProxy("FluxMacroProxy_CraftManaPotion", function()
    local Craft = CraftApi()
    if Craft and Craft.ExecuteManaPotionCraft then
        Craft.ExecuteManaPotionCraft()
    end
    SuppressCombatCraftChecked(_G.FluxCombatManaPotion)
end)

makeClickProxy("FluxMacroProxy_ConsumablesConfig", function()
    if FluxNCConsumables_OpenConfig then
        FluxNCConsumables_OpenConfig()
    end
end)

makeClickProxy("FluxMacroProxy_CollectionsTab1", function()
    if ToggleCollectionsJournal then
        pcall(ToggleCollectionsJournal, 1)
    end
end)

makeClickProxy("FluxMacroProxy_CollectionsTab3", function()
    if ToggleCollectionsJournal then
        pcall(ToggleCollectionsJournal, 3)
    end
end)

-- Hearth button → Toy Box: open Collections tab 3 and clear CheckButton highlight
makeClickProxy("FluxMacroProxy_HearthToyBox", function()
    local clear = FluxNCHearthstone and FluxNCHearthstone.ClearHearthButtonCheckedState
    if clear then
        clear()
    end
    if ToggleCollectionsJournal then
        pcall(ToggleCollectionsJournal, 3)
    end
    -- CheckButton can re-toggle on mouse-up after the proxy runs
    if clear and C_Timer and C_Timer.After then
        C_Timer.After(0, clear)
        C_Timer.After(0.05, clear)
        C_Timer.After(0.15, clear)
    end
end)

makeClickProxy("FluxMacroProxy_HearthTeleportFlyout", function()
    if FluxNCHearthstone and FluxNCHearthstone.ShowTeleportFlyout then
        FluxNCHearthstone.ShowTeleportFlyout()
    end
end)

makeClickProxy("FluxMacroProxy_MountItemFlyout", function()
    if FluxNCMount and FluxNCMount.ShowMountItemFlyout then
        FluxNCMount.ShowMountItemFlyout()
    end
end)

makeClickProxy("FluxMacroProxy_MountOpenUI", function()
    local ok = pcall(function()
        if FluxNCMount and FluxNCMount.OpenMountUI then
            return FluxNCMount.OpenMountUI()
        end
    end)
    if not ok then
        print("|cff00ffffFluxUI:|r Error opening mount UI")
    end
end)

makeClickProxy("FluxMacroProxy_MountToggleMode", function()
    if FluxNCMount and FluxNCMount.ToggleMode then
        FluxNCMount.ToggleMode()
    end
end)

makeClickProxy("FluxMacroProxy_TeleportToggleMode", function()
    -- Press-and-hold swallows mouse-down; /click and override binds often arrive
    -- on release. ToggleMode already debounces a matching down+up pair.
    if FluxNCTeleportPortal and FluxNCTeleportPortal.ToggleMode then
        FluxNCTeleportPortal.ToggleMode()
    end
end)

makeClickProxy("FluxMacroProxy_TeleportShowFlyout", function()
    if FluxNCTeleportPortal and FluxNCTeleportPortal.ShowFlyout then
        FluxNCTeleportPortal.ShowFlyout()
    end
end)

makeClickProxy("FluxMacroProxy_FoodToggleRecuperate", function()
    if FluxNCFood and FluxNCFood.ToggleRecuperate then
        FluxNCFood.ToggleRecuperate()
    end
end)

makeClickProxy("FluxMacroProxy_FoodDeleteStack", function()
    if FluxNCFood and FluxNCFood._foodButton and FluxNCFood.DeleteOneStackForButton then
        FluxNCFood.DeleteOneStackForButton(FluxNCFood._foodButton)
    end
end)

makeClickProxy("FluxMacroProxy_FoodRestockToggle", function()
    local UI = _G.FluxNCFoodWaterRestockUI
    if UI and UI.ToggleEditBox and FluxNCFood and FluxNCFood._foodButton then
        UI.ToggleEditBox(FluxNCFood._foodButton, "food")
        UI.SuppressCheckedVisual(FluxNCFood._foodButton)
        if C_Timer and C_Timer.After then
            C_Timer.After(0.02, function()
                if UI and FluxNCFood and FluxNCFood._foodButton then
                    UI.SuppressCheckedVisual(FluxNCFood._foodButton)
                end
            end)
        end
    end
end)

makeClickProxy("FluxMacroProxy_WaterDeleteStack", function()
    if FluxNCWater and FluxNCWater._waterButton and FluxNCWater.DeleteOneStackForButton then
        FluxNCWater.DeleteOneStackForButton(FluxNCWater._waterButton)
    end
end)

makeClickProxy("FluxMacroProxy_WaterRestockToggle", function()
    local UI = _G.FluxNCFoodWaterRestockUI
    if UI and UI.ToggleEditBox and FluxNCWater and FluxNCWater._waterButton then
        UI.ToggleEditBox(FluxNCWater._waterButton, "water")
        UI.SuppressCheckedVisual(FluxNCWater._waterButton)
        if C_Timer and C_Timer.After then
            C_Timer.After(0.02, function()
                if UI and FluxNCWater and FluxNCWater._waterButton then
                    UI.SuppressCheckedVisual(FluxNCWater._waterButton)
                end
            end)
        end
    end
end)

P.MACRO_BANDAGE_RESTOCK_TOGGLE = "/click FluxMacroProxy_BandageRestockToggle"
P.MACRO_HEAL_POTION_RESTOCK_TOGGLE = "/click FluxMacroProxy_HealPotionRestockToggle"
P.MACRO_MANA_POTION_RESTOCK_TOGGLE = "/click FluxMacroProxy_ManaPotionRestockToggle"

makeClickProxy("FluxMacroProxy_BandageRestockToggle", function()
    local FCIR = _G.FluxCombatItemRestock
    local M = _G.FluxCombatBandage
    if FCIR and FCIR.ToggleEditBox and M and M.Button then
        FCIR.ToggleEditBox(M.Button, "bandage")
    end
end)

makeClickProxy("FluxMacroProxy_HealPotionRestockToggle", function()
    local FCIR = _G.FluxCombatItemRestock
    local M = _G.FluxCombatHealPotion
    if FCIR and FCIR.ToggleEditBox and M and M.Button then
        FCIR.ToggleEditBox(M.Button, "healPotion")
    end
end)

makeClickProxy("FluxMacroProxy_ManaPotionRestockToggle", function()
    local FCIR = _G.FluxCombatItemRestock
    local M = _G.FluxCombatManaPotion
    if FCIR and FCIR.ToggleEditBox and M and M.Button then
        FCIR.ToggleEditBox(M.Button, "manaPotion")
    end
end)

makeClickProxy("FluxMacroProxy_GridToggleMountKind", function()
    local g = _G.FluxButtonAPI and _G.FluxButtonAPI.DefaultGrid
    if g and g.ToggleMountButtonKind then
        g:ToggleMountButtonKind()
    end
end)

makeClickProxy("FluxMacroProxy_GridToggleMageHeader", function()
    local g = _G.FluxButtonAPI and _G.FluxButtonAPI.DefaultGrid
    if g and g.ToggleMageHeaderKind then
        g:ToggleMageHeaderKind()
    end
end)
