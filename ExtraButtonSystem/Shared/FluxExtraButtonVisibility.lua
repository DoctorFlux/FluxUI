--[[
    Central visibility policy for Combat Grid, Non-Combat Grid, and Trinket Menu buttons.
    Stored in FluxOptions:GetActionbarsDB().extraButtonVisibility (Action Bars tab scope).
]]

FluxExtraButtonVisibility = FluxExtraButtonVisibility or {}
local EBV = FluxExtraButtonVisibility

EBV.MODE_OFF = "off"
EBV.MODE_AUTO = "auto"
EBV.MODE_ALWAYS = "always"
EBV.MODE_HIDDEN = "hidden"

--- @type table<string,string> default mode per button id
EBV.Defaults = {
    combat_assistedCombat = "off",
    combat_bandage = "auto",
    combat_healPotion = "auto",
    combat_manaPotion = "auto",
    combat_manaGem = "auto",
    combat_healthstone = "auto",
    combat_ammo = "auto",
    nc_hearthstone = "always",
    nc_mount = "auto",
    nc_teleport = "auto",
    nc_food = "always",
    nc_water = "always",
    nc_consumables = "always",
    trinket_menu = "auto",
}

--- Which modes appear in UI cycle (order)
EBV.ModeLists = {
    combat_assistedCombat = { "off", "auto", "always" },
    combat_bandage = { "off", "auto", "always" },
    combat_healPotion = { "off", "auto", "always" },
    combat_manaPotion = { "off", "auto", "always" },
    combat_manaGem = { "off", "auto" },
    combat_healthstone = { "off", "auto", "always" },
    combat_ammo = { "off", "auto", "always" },
    nc_hearthstone = { "off", "auto", "always" },
    nc_mount = { "off", "auto", "always" },
    nc_teleport = { "off", "auto" },
    nc_food = { "off", "auto", "always" },
    nc_water = { "off", "auto", "always" },
    nc_consumables = { "hidden", "always" },
    trinket_menu = { "off", "auto", "always" },
}

EBV.Labels = {
    combat_assistedCombat = "Single-Button Assistant",
    combat_bandage = "Bandage",
    combat_healPotion = "Healing Potion",
    combat_manaPotion = "Mana Potion",
    combat_manaGem = "Mana Gem",
    combat_healthstone = "Healthstone",
    combat_ammo = "Ammo",
    nc_hearthstone = "Hearthstone / Teleport",
    nc_mount = "Mount",
    nc_teleport = "Class Teleport",
    nc_food = "Food",
    nc_water = "Water",
    nc_consumables = "Consumables",
    trinket_menu = "Trinket Menu",
}

EBV.Icons = {
    combat_assistedCombat = "Interface/Icons/Spell_Nature_Lightning",
    combat_bandage = "Interface/Icons/INV_Misc_Bandage_12",
    combat_healPotion = "Interface/Icons/INV_Potion_54",
    combat_manaPotion = "Interface/Icons/INV_Potion_76",
    combat_manaGem = "Interface/Icons/INV_Misc_Gem_Sapphire_02",
    combat_healthstone = "Interface/Icons/INV_Stone_04",
    combat_ammo = "Interface/Icons/INV_Misc_Ammo_Bullet_01",
    nc_hearthstone = "Interface/Icons/INV_Misc_Rune_01",
    nc_mount = "Interface/Icons/Ability_Mount_RidingHorse",
    nc_teleport = "Interface/Icons/Spell_Arcane_PortalIronforge",
    nc_food = "Interface/Icons/INV_Misc_Food_15",
    nc_water = "Interface/Icons/INV_Drink_07",
    nc_consumables = "Interface/Icons/inv_potion_41",
    trinket_menu = "Interface/Icons/INV_Jewelry_TrinketPVP_01",
}

local orderIdsAll = {
    "combat_assistedCombat",
    "combat_bandage",
    "combat_healPotion",
    "combat_manaPotion",
    "combat_manaGem",
    "combat_healthstone",
    "combat_ammo",
    "nc_hearthstone",
    "nc_mount",
    "nc_teleport",
    "nc_food",
    "nc_water",
    "nc_consumables",
    "trinket_menu",
}

function EBV.ClientHasAssistedCombat()
    local API = _G.FLUX_API
    if API and type(API.ClientSupportsSingleButtonAssistant) == "function" then
        return API.ClientSupportsSingleButtonAssistant() and true or false
    end
    return false
end

function EBV.GetOrderedIds()
    local hasAmmo = EBV.ClientHasAmmoSlot and EBV.ClientHasAmmoSlot()
    local hasAssisted = EBV.ClientHasAssistedCombat()
    if hasAmmo and hasAssisted then
        return orderIdsAll
    end
    local out = {}
    for _, id in ipairs(orderIdsAll) do
        if id == "combat_ammo" and not hasAmmo then
            -- skip
        elseif id == "combat_assistedCombat" and not hasAssisted then
            -- skip
        else
            out[#out + 1] = id
        end
    end
    return out
end

-- Live Extra hosts: combat HUD, NC HUD, Trinket Menu. Assisted combat stays unused.
function EBV.GetOptionsIds()
    local out = {}
    local ordered = EBV.GetOrderedIds()
    for i = 1, #ordered do
        local id = ordered[i]
        if id ~= "combat_assistedCombat" then
            out[#out + 1] = id
        end
    end
    return out
end

function EBV.GetBindingForce()
    local fbm = _G.FluxBindingMode
    return fbm and fbm.ShouldForceShowAllExtraSlots and fbm:ShouldForceShowAllExtraSlots() or false
end

function EBV.PlayerUsesMana()
    -- Prefer pool-based API (sticky GetPlayerHasMana). Not display-power / form-aware —
    -- Druids keep mana in cat/bear; Always/Auto mana slots must stay consistent.
    local API = _G.FluxAPICompat
    if API and type(API.GetPlayerHasMana) == "function" then
        return API.GetPlayerHasMana() and true or false
    end
    local fluxApi = _G.FLUX_API
    if fluxApi and type(fluxApi.hasPlayerMana) == "function" then
        return fluxApi.hasPlayerMana() and true or false
    end
    if FluxItemDetection and FluxItemDetection.PlayerSpecUsesMana then
        return FluxItemDetection.PlayerSpecUsesMana()
    end
    if FluxNCItemDetection and FluxNCItemDetection.PlayerSpecUsesMana then
        return FluxNCItemDetection.PlayerSpecUsesMana()
    end
    return true
end

--- True when the character sheet supports ranged/ammo equipment (see FLUX_API.ClientSupportsCombatAmmoExtraButton).
function EBV.ClientHasAmmoSlot()
    local API = _G.FLUX_API
    if API and type(API.ClientSupportsCombatAmmoExtraButton) == "function" then
        return API.ClientSupportsCombatAmmoExtraButton() and true or false
    end
    if not _G.GetInventorySlotInfo then
        return false
    end
    local function slotNumber(token)
        local ok, slot = pcall(GetInventorySlotInfo, token)
        return ok and type(slot) == "number"
    end
    return slotNumber("AmmoSlot") or slotNumber("RangedSlot")
end

local function ensureTable()
    local t = FluxOptions and FluxOptions.GetActionbarsDB and FluxOptions:GetActionbarsDB()
    if not t then
        return nil
    end
    if not t.extraButtonVisibility then
        t.extraButtonVisibility = {}
    end
    return t
end

function EBV.GetRawMode(id)
    local t = ensureTable()
    if not t then
        return EBV.Defaults[id] or "auto"
    end
    local v = t.extraButtonVisibility[id]
    if v == nil or v == "" then
        return EBV.Defaults[id] or "auto"
    end
    -- Legacy: Auto was removed from Food/Water cycle; treat saved "auto" as Always.
    if (id == "nc_food" or id == "nc_water") and v == "auto" then
        return "always"
    end
    return v
end

function EBV.SetRawMode(id, mode)
    local t = ensureTable()
    if not t then
        return
    end
    t.extraButtonVisibility[id] = mode
    EBV.NotifyChanged()
end

--- Resolves stored mode with hard rules (mana gem / teleport never effectively "always").
function EBV.GetEffectiveMode(id)
    local m = EBV.GetRawMode(id)
    if id == "combat_manaGem" or id == "nc_teleport" then
        if m == "always" then
            m = "auto"
        end
    end
    if (id == "nc_food" or id == "nc_water" or id == "combat_manaPotion") and m == "always" then
        if not EBV.PlayerUsesMana() then
            m = "auto"
        end
    end
    return m
end

--- Early gate for ShouldShow paths: skip GetBestOwned/CanCraft when mode is off/always.
--- @return boolean|nil showOrNil  false=hide, true=show, nil=need smart check (auto)
function EBV.QuickGate(id, bindingForce)
    if bindingForce == nil then
        bindingForce = EBV.GetBindingForce()
    end
    if id == "combat_ammo" and not EBV.ClientHasAmmoSlot() then
        return false
    end
    if id == "combat_assistedCombat" and not EBV.ClientHasAssistedCombat() then
        return false
    end
    if id == "combat_ammo" and bindingForce then
        return false
    end
    if id == "combat_manaGem" then
        local Bridge = _G.FluxEBSConsumableBridge
        if not (Bridge and Bridge.KnowsManaGemConjureSpell and Bridge.KnowsManaGemConjureSpell()) then
            return false
        end
    end
    if bindingForce then
        return true
    end
    local mode = EBV.GetEffectiveMode(id)
    if mode == "off" or mode == "hidden" then
        return false
    end
    if mode == "always" then
        return true
    end
    return nil
end

--- Standard tri-state + consumables hidden.
--- @return boolean showSlot
function EBV.Apply(id, smartWouldShow, bindingForce)
    local gate = EBV.QuickGate(id, bindingForce)
    if gate ~= nil then
        return gate
    end
    return smartWouldShow and true or false
end

function EBV.ApplyConsumables(bindingForce)
    if bindingForce == nil then
        bindingForce = EBV.GetBindingForce()
    end
    if bindingForce then
        return true
    end
    local mode = EBV.GetEffectiveMode("nc_consumables")
    if mode == "hidden" then
        return false
    end
    return true
end

function EBV.ModeDisplayName(mode)
    if mode == "off" then
        return "Off"
    end
    if mode == "auto" then
        return "Auto"
    end
    if mode == "always" then
        return "Always"
    end
    if mode == "hidden" then
        return "Hidden"
    end
    return tostring(mode or "?")
end

--- Short one-line hints for Action Bars extra visibility tooltips (ASCII).
EBV.OptionsModeHelpDefault = {
    off = "Never show.",
    auto = "Show when Flux would show it.",
    always = "Always show.",
    hidden = "Never show.",
}

--- Per-button overrides ([id][mode] = line). Falls back to OptionsModeHelpDefault.
EBV.OptionsModeHelp = {
    combat_assistedCombat = {
        off = "Off.",
        auto = "Show when not on your bars.",
        always = "Always show.",
    },
    combat_bandage = {
        off = "Off.",
        auto = "Only with bandages.",
        always = "Always show.",
    },
    combat_healPotion = {
        off = "Off.",
        auto = "Only with heal pots.",
        always = "Always show.",
    },
    combat_manaPotion = {
        off = "Off.",
        auto = "Only with mana pots.",
        always = "Always show.",
    },
    combat_manaGem = {
        off = "Off.",
        auto = "Only with a conjure gem spell.",
    },
    combat_healthstone = {
        off = "Off.",
        auto = "Only when available.",
        always = "Always show.",
    },
    combat_ammo = {
        off = "Off.",
        auto = "Only when ammo applies.",
        always = "Always show.",
    },
    nc_hearthstone = {
        off = "Off.",
        auto = "Only with hearth or teleport.",
        always = "Always show.",
    },
    nc_mount = {
        off = "Off.",
        auto = "When you can ride.",
        always = "Always show.",
    },
    nc_teleport = {
        off = "Off.",
        auto = "Only when your class has them.",
    },
    nc_food = {
        off = "Off.",
        auto = "Normal food rules.",
        always = "Always show.",
    },
    nc_water = {
        off = "Off.",
        auto = "Normal water rules.",
        always = "Always show.",
    },
    nc_consumables = {
        hidden = "Hide button.",
        always = "Show with tracked items.",
    },
    trinket_menu = {
        off = "Off.",
        auto = "Only with trinkets.",
        always = "Always show.",
    },
}

function EBV.GetOptionsModeHelpLine(id, mode)
    local byId = EBV.OptionsModeHelp[id]
    if byId and byId[mode] then
        return byId[mode]
    end
    return EBV.OptionsModeHelpDefault[mode] or ""
end

--- Optional footnote for the options tooltip (effective-mode quirks).
function EBV.GetOptionsTooltipNote(id)
    if id == "nc_food" or id == "nc_water" or id == "combat_manaPotion" then
        return "No mana bar: Always acts like Auto."
    end
    return nil
end

function EBV.Cycle(id)
    local list = EBV.ModeLists[id]
    if not list or #list == 0 then
        return
    end
    local cur = EBV.GetRawMode(id)
    local idx = 1
    for i, v in ipairs(list) do
        if v == cur then
            idx = i
            break
        end
    end
    local nxt = list[(idx % #list) + 1]
    EBV.SetRawMode(id, nxt)
end

--- Weak refs to open Action Bars option panels (AceGUI widgets) for row label refresh.
local optionPanelWidgets = setmetatable({}, { __mode = "k" })

function EBV._RegisterOptionPanelWidget(widget)
    if widget then
        optionPanelWidgets[widget] = true
    end
end

function EBV._UnregisterOptionPanelWidget(widget)
    if widget then
        optionPanelWidgets[widget] = nil
    end
end

function EBV._ClearOptionPanelWidgets()
    for w in pairs(optionPanelWidgets) do
        optionPanelWidgets[w] = nil
    end
end

--- Updates mode labels on any open Extra button visibility option panel (after reset).
function EBV.RefreshOptionPanelRows()
    for w in pairs(optionPanelWidgets) do
        if w._fluxReleased then
            optionPanelWidgets[w] = nil
        else
            local rows = w._rows
            if rows then
                for _, row in ipairs(rows) do
                    if row and row._fluxRefreshMode then
                        row._fluxRefreshMode()
                    end
                end
            end
        end
    end
end

--- Restores every extra button visibility mode to EBV.Defaults for the current Action Bars DB scope.
function EBV.ResetToDefaults()
    local t = FluxOptions and FluxOptions.GetActionbarsDB and FluxOptions:GetActionbarsDB()
    if not t then
        return
    end
    t.extraButtonVisibility = {}
    -- Apply defaults in panel order first so saved tables with stale keys are fully replaced.
    if EBV.GetOrderedIds then
        for _, id in ipairs(EBV.GetOrderedIds()) do
            local mode = EBV.Defaults[id]
            if mode ~= nil then
                t.extraButtonVisibility[id] = mode
            end
        end
    end
    for id, mode in pairs(EBV.Defaults) do
        if t.extraButtonVisibility[id] == nil then
            t.extraButtonVisibility[id] = mode
        end
    end
    EBV.RefreshOptionPanelRows()
    EBV.NotifyChanged()
end

-- Debounce: Cycle can fire often; Mount/Teleport/Consumables updates are very expensive.
local notifyPending
local notifyHeavyPending
local function run(fn)
    if type(fn) == "function" then
        pcall(fn)
    end
end

local function runNotifyLight()
    if FluxCombatAssistedCombat and FluxCombatAssistedCombat.Update then
        run(FluxCombatAssistedCombat.Update)
    end
    if FluxCombatBandage and FluxCombatBandage.Update then
        run(FluxCombatBandage.Update)
    end
    if FluxCombatHealPotion and FluxCombatHealPotion.Update then
        run(FluxCombatHealPotion.Update)
    end
    if FluxCombatManaPotion and FluxCombatManaPotion.Update then
        run(FluxCombatManaPotion.Update)
    end
    if FluxCombatManaGem and FluxCombatManaGem.Update then
        run(FluxCombatManaGem.Update)
    end
    if FluxCombatHealthstone and FluxCombatHealthstone.Update then
        run(FluxCombatHealthstone.Update)
    end
    if FluxCombatAmmo and FluxCombatAmmo.Update then
        run(FluxCombatAmmo.Update)
    end
    if FluxNCFood and FluxNCFood.Update then
        run(FluxNCFood.Update)
    end
    if FluxNCWater and FluxNCWater.Update then
        run(FluxNCWater.Update)
    end
    if FluxTrinketMenu and FluxTrinketMenu.UpdateTrinketVisibility then
        run(FluxTrinketMenu.UpdateTrinketVisibility)
    end
    -- Pack columns as soon as light buttons have applied Show/Hide.
    EBV.RequestLayoutNow()
end

local function runNotifyHeavy()
    notifyHeavyPending = nil
    if FluxNCHearthstone and FluxNCHearthstone.Update then
        run(FluxNCHearthstone.Update)
    end
    if FluxNCMount and FluxNCMount.Update then
        run(FluxNCMount.Update)
    end
    if FluxNCTeleportPortal and FluxNCTeleportPortal.Update then
        run(FluxNCTeleportPortal.Update)
    end
    if FluxNCConsumables and FluxNCConsumables.UpdateButtonState then
        run(function()
            FluxNCConsumables.UpdateButtonState(true)
        end)
    end
    EBV.RequestLayoutNow()
end

local relayoutPending
local function scheduleGridRelayout()
    if relayoutPending then
        return
    end
    relayoutPending = true
    local T = C_Timer
    local function doRelayout()
        relayoutPending = nil
        EBV.RequestLayoutNow()
    end
    if T and T.After then
        -- Shortly after light Updates (0.05) so mode flips pack without waiting for heavy.
        T.After(0.06, doRelayout)
    else
        doRelayout()
    end
end

--- Instant grid packing after any Extra Button SlotFrame visibility flip.
--- Coalesces via each grid's ScheduleRelayout (Combat + NonCombat).
function EBV.RequestLayoutNow()
    local function ask(g)
        if not g then
            return
        end
        if g.ScheduleRelayout then
            g:ScheduleRelayout()
        elseif g.Relayout and not (InCombatLockdown and InCombatLockdown()) then
            g:Relayout()
        end
    end
    local M = _G.FluxCombatManager
    ask(M and M.Grid)
    local API = _G.FluxNonCombatAPI
    ask(API and API.DefaultGrid)
end

-- SlotFrame parents secure action buttons; Show/Hide is protected in combat.
local pendingSlotShown = {}
local slotShownRegenFrame

local function ApplySlotShownNow(btn, shown)
    local slot = btn and btn.SlotFrame
    if not slot then
        return false
    end
    local was = slot:IsShown() and true or false
    if shown then
        slot:Show()
    else
        slot:Hide()
    end
    local now = slot:IsShown() and true or false
    if was ~= now then
        EBV.RequestLayoutNow()
        return true
    end
    return false
end

local function FlushPendingSlotShown()
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local queued = pendingSlotShown
    pendingSlotShown = {}
    for btn, shown in pairs(queued) do
        if btn and btn.SlotFrame then
            ApplySlotShownNow(btn, shown)
        end
    end
end

local function EnsureSlotShownRegenWatcher()
    if slotShownRegenFrame then
        return
    end
    slotShownRegenFrame = CreateFrame("Frame")
    slotShownRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    slotShownRegenFrame:SetScript("OnEvent", function()
        FlushPendingSlotShown()
    end)
end

--- Show/hide SlotFrame; request layout immediately when shown-state changes.
--- Defers during combat lockdown (parent of secure FluxButton widgets).
--- @return boolean true if visibility changed
function EBV.SetSlotShown(btn, shown)
    if not btn or not btn.SlotFrame then
        return false
    end
    shown = shown and true or false
    if InCombatLockdown and InCombatLockdown() then
        pendingSlotShown[btn] = shown
        EnsureSlotShownRegenWatcher()
        return false
    end
    pendingSlotShown[btn] = nil
    return ApplySlotShownNow(btn, shown)
end

function EBV.NotifyChanged()
    if not notifyPending then
        notifyPending = true
        local T = C_Timer
        if T and T.After then
            T.After(0.05, function()
                notifyPending = nil
                runNotifyLight()
            end)
        else
            notifyPending = nil
            runNotifyLight()
        end
    end
    if not notifyHeavyPending then
        notifyHeavyPending = true
        local T = C_Timer
        if T and T.After then
            T.After(0.2, function()
                runNotifyHeavy()
            end)
        else
            runNotifyHeavy()
        end
    end
    scheduleGridRelayout()
end
