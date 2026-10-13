--[[ ExtraButtonSystem/CombatGrid/Buttons/Healthstone.lua — Inventory-backed ]]

FluxCombatHealthstone = FluxCombatHealthstone or {}
local Module = FluxCombatHealthstone

local PLACEHOLDER = "Interface\\Icons\\INV_Stone_04"
local USE_BINDING = "FLUXCOMBAT_HEALTHSTONE"
local CONJURE_BINDING = "FLUXMAGE_CONJURE_MANAGEM"

local function GetCreateSpell()
    local Bridge = FluxEBSConsumableBridge
    return Bridge.GetPreferredCreateSpell("healthstone")
end

local function CanCreate()
    local Bridge = FluxEBSConsumableBridge
    return Bridge.CanCreate("healthstone")
end
Module.CanCreateHealthstone = CanCreate

--- Shared conjure key goes to Mana Gem when the mage knows a conjure spell.
local function MageOwnsConjureBinding()
    local mg = _G.FluxCombatManaGem
    return mg and mg.KnowsAnyConjureSpell and mg.KnowsAnyConjureSpell()
end

local function ShouldBindConjure()
    if MageOwnsConjureBinding() then
        return false
    end
    -- Bind whenever we know the create spell (or CanCreate), even before spell
    -- scan has fully warmed — name fallbacks cover Classic ranks.
    local spellID, spellName = GetCreateSpell()
    if spellID or spellName then
        return true
    end
    return CanCreate()
end

local function AppendTooltip(btn, tip)
    local Bridge = FluxEBSConsumableBridge
    local spellID, spellName = GetCreateSpell()
    if spellID or spellName then
        Bridge.AppendConjureSpellLines(tip, spellID or spellName, nil, {
            bindingName = "FLUXMAGE_CONJURE_MANAGEM",
        })
    end
    local itemID = Module._trackedItemID or btn.ItemId
    if Bridge.AppendDeleteStackHint then
        Bridge.AppendDeleteStackHint(tip, btn, itemID)
    end
    btn._fluxTooltipNeedsLiveRefresh = true
end

local function ApplyRC(btn)
    local Bridge = FluxEBSConsumableBridge
    local spellID, spellName = GetCreateSpell()
    -- Prefer spell name for Classic /cast macro reliability.
    if spellName or spellID then
        Bridge.ApplyRightClickSpell(btn, spellName or spellID)
    else
        Bridge.ApplyRightClickMacro(btn, nil)
    end
end

local function ApplyKeybinds(btn)
    local Bridge = FluxEBSConsumableBridge
    Bridge.ApplyUseAndConjureBindings(btn, USE_BINDING, {
        conjureBindingName = CONJURE_BINDING,
        canConjure = ShouldBindConjure,
    })
end

local function ShouldShow()
    local EBV = _G.FluxExtraButtonVisibility
    if EBV and EBV.QuickGate then
        local gate = EBV.QuickGate("combat_healthstone")
        if gate ~= nil then
            return gate
        end
    end
    local Bridge = FluxEBSConsumableBridge
    local smart = false
    if Bridge.KeepConsumableSlot and Bridge.KeepConsumableSlot("healthstone", Module) then
        smart = true
    else
        local best = Bridge.GetBestOwned("healthstone", { charges = true })
        if best and best.itemID then
            smart = true
        else
            smart = CanCreate() and true or false
        end
    end
    if EBV and EBV.Apply then
        return EBV.Apply("combat_healthstone", smart)
    end
    return smart
end

local function SoftHoldOwned()
    local BestMod = _G.FluxConsumableBest
    if BestMod and BestMod.ShouldSoftHoldOwned then
        return BestMod.ShouldSoftHoldOwned() and true or false
    end
    local api = _G.Flux and _G.Flux.Inventory
    if api and api.IsReliable then
        return not api.IsReliable()
    end
    local inv = _G.FluxInv
    if inv and inv.Bags and inv.Bags.IsReliable then
        return not inv.Bags.IsReliable()
    end
    return false
end

local function StoneUses(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local Bridge = FluxEBSConsumableBridge
    return Bridge.BagCount(itemID, { charges = true }) or 0
end

local function StoneDisplay(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local Bridge = FluxEBSConsumableBridge
    if Bridge.DisplayItemCount then
        return Bridge.DisplayItemCount(itemID, { preferCopies = true }) or 0
    end
    return StoneUses(itemID)
end

local function ApplyStoneCount(btn, itemID, opts)
    opts = opts or {}
    local count = StoneDisplay(itemID)
    local freeze = opts.freeze or SoftHoldOwned()
    if freeze and itemID then
        local held = count > 0 and count or (tonumber(btn._fluxLastCount) or tonumber(Module._latchCount) or 0)
        if held > 0 then
            count = held
        end
    end
    if itemID and count > 0 then
        btn._fluxLastCount = count
        Module._latchCount = count
        Module._latchItemID = itemID
    end
    if btn.SetCount then
        -- Soft-hold snapshot must not use live APIs (they read 0 on zone load).
        if freeze and count > 0 then
            btn:SetCount(count, nil)
        elseif itemID then
            btn:SetCount(count, { live = true, itemId = itemID })
        else
            btn:SetCount(0)
        end
    end
    if btn.WCount then
        btn.WCount:SetText(tostring(count))
        btn.WCount:Show()
        btn.WCount:SetAlpha(1)
    end
    btn._lastIconR, btn._lastIconG, btn._lastIconB = nil, nil, nil
    if btn.UpdateUsable then
        btn:UpdateUsable()
    end
end

local function AttachHealthstone(btn)
    local Bridge = FluxEBSConsumableBridge
    local Refresh = FluxEBSButtonRefresh

    Refresh.Attach({
        module = Module,
        btn = btn,
        kind = "healthstone",
        charges = true,
        kindFlag = "IsHealthstoneButton",
        placeholderIcon = PLACEHOLDER,
        placeholderLabel = "Healthstone",
        listenerKey = "FluxCombatHealthstone",
        bindingName = USE_BINDING,
        middleClickDelete = true,
        combatGridCoalesce = true,
        shouldShow = ShouldShow,
        showTooltipExtras = AppendTooltip,
        applyRightClick = ApplyRC,
    })

    -- Keep remaining charges visible after Extra paint (unique stones report stack 1).
    do
        local originalUpdateTextCount = btn.UpdateTextCount
        btn.UpdateTextCount = function(self)
            local bestId = self.ItemId or Module._trackedItemID
            self._forcedCount = StoneDisplay(bestId)
            if bestId then
                self._forcedCountLive = true
                self._liveCountItemId = bestId
            end
            if originalUpdateTextCount then
                originalUpdateTextCount(self)
            end
        end
    end

    function Module.UpdateKeybinding()
        ApplyKeybinds(btn)
    end

    -- Attach's sync AfterSecureWrites ran before we overrode UpdateKeybinding.
    ApplyRC(btn)
    ApplyKeybinds(btn)

    local bindEvents = CreateFrame("Frame")
    bindEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    bindEvents:RegisterEvent("UPDATE_BINDINGS")
    -- Shared by the frame events and the Core SpellBook bus (conjure rebind).
    local function OnBindEvent()
        if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
            and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
            return
        end
        if bindEvents._bindRefreshPending then
            return
        end
        bindEvents._bindRefreshPending = true
        C_Timer.After(0.15, function()
            bindEvents._bindRefreshPending = false
            if _G.FluxDefaultSettings and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
                and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
                return
            end
            if InCombatLockdown and InCombatLockdown() then
                btn._pendingKeybindUpdate = true
                return
            end
            ApplyRC(btn)
            ApplyKeybinds(btn)
        end)
    end
    bindEvents:SetScript("OnEvent", OnBindEvent)
    -- SPELLS_CHANGED rides the debounced, signature-gated Core bus; the direct
    -- frame registration stays only as fallback when the bus is missing.
    do
        local SpellBook = _G.Flux and _G.Flux.SpellBook
        if SpellBook and SpellBook.OnChanged then
            SpellBook.OnChanged("cgrid.healthstone", OnBindEvent)
        else
            bindEvents:RegisterEvent("SPELLS_CHANGED")
        end
    end

    function Module.RefreshCountOnly()
        ApplyStoneCount(btn, Module._trackedItemID or btn.ItemId)
    end

    function Module.Update(force)
        if not ShouldShow() then
            local EBV = _G.FluxExtraButtonVisibility
            if EBV and EBV.SetSlotShown then
                EBV.SetSlotShown(btn, false)
            elseif btn.SlotFrame then
                btn.SlotFrame:Hide()
            end
            return
        end
        do
            local EBV = _G.FluxExtraButtonVisibility
            if EBV and EBV.SetSlotShown then
                EBV.SetSlotShown(btn, true)
            elseif btn.SlotFrame then
                btn.SlotFrame:Show()
            end
        end
        if InCombatLockdown and InCombatLockdown() then
            Module._pendingUpdate = true
            Module.RefreshCountOnly()
            return
        end

        local best = Bridge.GetBestOwned("healthstone", { charges = true })
        if best and best.itemID then
            local n = Bridge.BagCount(best.itemID, { charges = true }) or 0
            if n <= 0 then
                best = nil
                local ladder = Bridge.GetOwnedLadder and Bridge.GetOwnedLadder("healthstone", { charges = true })
                if type(ladder) == "table" then
                    for i = 1, #ladder do
                        local rec = ladder[i]
                        local id = rec and tonumber(rec.itemID)
                        local bagN = id and Bridge.BagCount(id, { charges = true }) or 0
                        if bagN > 0 then
                            best = rec
                            best.count = bagN
                            break
                        end
                    end
                end
            else
                best.count = n
            end
        end
        local softHold = SoftHoldOwned()
        if softHold then
            local keepID = Module._latchItemID or Module._trackedItemID
                or (best and best.itemID) or nil
            if keepID then
                Module._trackedItemID = keepID
                Module._latchItemID = keepID
                btn.ItemId = keepID
                if btn.ClearPlaceholder then
                    btn:ClearPlaceholder()
                end
                btn.PlaceholderTexture = nil
                if btn.SetAction and (not btn.ActionType or btn.ActionType == "placeholder") then
                    btn:SetAction("item", keepID)
                end
                ApplyStoneCount(btn, keepID, { freeze = true })
            else
                ApplyStoneCount(btn, nil)
            end
        elseif best and best.itemID then
            local bestID = best.itemID
            local bagN = Bridge.BagCount(bestID, { charges = true }) or 0
            if bagN > 0 then
                local changed = force or bestID ~= Module._trackedItemID
                Module._trackedItemID = bestID
                Module._latchItemID = bestID
                Module._latchCount = bagN
                btn.ItemId = bestID
                if btn.ClearPlaceholder then
                    btn:ClearPlaceholder()
                end
                btn.PlaceholderTexture = nil
                if changed or force then
                    btn:SetAction("item", bestID)
                    if btn.FullRefresh then
                        btn:FullRefresh()
                    end
                end
                ApplyStoneCount(btn, bestID)
            else
                Module._trackedItemID = nil
                Module._latchItemID = nil
                Module._latchCount = nil
                btn.ItemId = nil
                if btn.SetPlaceholder then
                    btn:SetPlaceholder(PLACEHOLDER, "Healthstone")
                elseif btn.ClearAction then
                    btn:ClearAction()
                end
                ApplyStoneCount(btn, nil)
            end
        else
            Module._trackedItemID = nil
            Module._latchItemID = nil
            Module._latchCount = nil
            btn.ItemId = nil
            if btn.SetPlaceholder then
                btn:SetPlaceholder(PLACEHOLDER, "Healthstone")
            elseif btn.ClearAction then
                btn:ClearAction()
            end
            ApplyStoneCount(btn, nil)
        end

        -- Always re-apply after SetAction/ClearAction (they wipe type2).
        ApplyRC(btn)
        if Bridge.ApplyMiddleClickNoUse then
            Bridge.ApplyMiddleClickNoUse(btn)
        end
        ApplyKeybinds(btn)
        btn.ButtonLocked = true
        if btn.SetLocked then
            btn:SetLocked(true)
        end
        Module._pendingUpdate = false
    end
end

function Module.Create(grid)
    local btn = grid:CreateButton({
        columnGroup = "healing",
        columnPriority = 10,
        order = 1,
        size = grid.ButtonSize,
    })
    if not btn then
        return
    end
    AttachHealthstone(btn)
end

_G.FluxCombatHealthstone = Module
return Module
