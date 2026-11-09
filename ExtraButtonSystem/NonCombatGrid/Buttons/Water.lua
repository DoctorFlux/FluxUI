--[[ ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua — Inventory-backed ]]

FluxNCWater = FluxNCWater or {}
local Module = FluxNCWater

local PLACEHOLDER = "Interface\\Icons\\INV_Drink_07"
local USE_BINDING = "FLUXGRID_WATER_OR_COMBINED"
local CONJURE_BINDING = "FLUXMAGE_CONJURE_WATER"

local function AppendTooltip(btn, tip)
    local Bridge = FluxEBSConsumableBridge
    local face = Bridge.CombatSwapTooltipKind and Bridge.CombatSwapTooltipKind(btn, "water") or "water"
    if face == "manaPotion" then
        Bridge.AppendTierStatusLines(tip, "manaPotion", btn and btn.ItemId, btn)
        tip:AddLine("Out of combat: Water", 0.65, 0.65, 0.65)
        return
    end
    local primary, primaryID = Bridge.GetWaterConjureSpell()
    local secondary, secondaryID = Bridge.GetWaterSecondaryConjureSpell()
    Bridge.AppendConjureSpellLines(tip, primaryID or primary, secondaryID or secondary, {
        bindingName = "FLUXMAGE_CONJURE_WATER",
        ritualBindingName = "FLUXMAGE_RITUAL_OF_REFRESHMENT",
        -- Conjure owns right; Shift+Right is restock; Ritual moves to Ctrl+Right.
        secondaryModifier = (primaryID or primary) and "ctrl" or nil,
    })
    local itemID = Module._trackedItemID or btn.ItemId
    Bridge.AppendTierStatusLines(tip, "water", itemID, btn)
    if btn and btn._fluxCombatSwapBody then
        tip:AddLine("In combat: Mana potion", 0.65, 0.65, 0.65)
    end
end

local function ApplyRC(btn)
    local Bridge = FluxEBSConsumableBridge
    local primary, primaryID = Bridge.GetWaterConjureSpell()
    local secondary, secondaryID = Bridge.GetWaterSecondaryConjureSpell()
    local w = btn and btn.Widget
    if not w or (InCombatLockdown and InCombatLockdown()) then
        return
    end
    local hasPrimary = (primaryID or primary) and true or false
    if hasPrimary then
        Bridge.ApplyRightClickSpell(btn, primaryID or primary)
        Bridge.ApplyShiftRightClickSpell(btn, nil)
        if secondaryID or secondary then
            Bridge.ApplyCtrlRightClickSpell(btn, secondaryID or secondary)
        else
            Bridge.ApplyCtrlRightClickSpell(btn, nil)
        end
        -- Conjure owns right-click; restock on Shift+Right. Middle stays free for conjured delete.
        Bridge.WireRestockEdit(btn, "water", { mode = "shift-right" })
        local isConjured = Bridge.IsConjured and Bridge.IsConjured(Module._trackedItemID or btn.ItemId)
        if isConjured and Bridge.ApplyMiddleClickNoUse then
            Bridge.ApplyMiddleClickNoUse(btn)
        end
    else
        Bridge.ApplyRightClickSpell(btn, nil)
        Bridge.ApplyShiftRightClickSpell(btn, nil)
        Bridge.ApplyCtrlRightClickSpell(btn, nil)
        Bridge.WireRestockEdit(btn, "water", { mode = "right" })
    end
end

local function ApplyKeybinds(btn)
    local Bridge = FluxEBSConsumableBridge
    if not Bridge or not Bridge.ApplyUseAndConjureBindings then
        return
    end
    Bridge.ApplyUseAndConjureBindings(btn, USE_BINDING, {
        conjureBindingName = CONJURE_BINDING,
        canConjure = function()
            local name, id = Bridge.GetWaterConjureSpell()
            return (id or name) and true or false
        end,
    })
end

local function ShouldShow()
    local smart = true
    local B = _G.FluxConsumableBest
    -- Pool-based mana relevance (GetPlayerHasMana), not display power / shapeshift form.
    if B and B.IsManaKindRelevant then
        smart = B.IsManaKindRelevant("water") and true or false
    end
    local Food = _G.FluxNCFood
    local allowCombo = Food
        and Food.HasRecuperate and Food.HasRecuperate()
        and Food.GetPreferRecuperate and Food.GetPreferRecuperate()
    -- Hide until pure water is owned (combo food stays on the food button only),
    -- unless Recuperate is preferred — then combo drinks may fill this button.
    -- While portal bags are unreliable, keep showing if we still have a latched/tracked ID.
    if smart then
        local hasWater = false
        if Module._latchItemID or Module._trackedItemID then
            hasWater = true
        end
        if not hasWater then
            local Bridge = FluxEBSConsumableBridge
            if Bridge and Bridge.KeepConsumableSlot and Bridge.KeepConsumableSlot("water", Module) then
                hasWater = true
            end
        end
        if not hasWater then
            local Bridge = FluxEBSConsumableBridge
            local holding = B and B.ShouldSoftHoldOwned and B.ShouldSoftHoldOwned()
            if Bridge and Bridge.GetBestOwned then
                local best = Bridge.GetBestOwned("water")
                if best and best.itemID and ((best.count or 0) > 0 or holding) then
                    hasWater = true
                end
            elseif B and B.GetBest then
                local best = B.GetBest("water")
                if best and best.itemID and ((best.count or 0) > 0 or holding) then
                    hasWater = true
                end
            end
        end
        -- Prefer-Recuperate: also show when any combo food is owned even if ladder is empty yet.
        if not hasWater and allowCombo then
            local Bridge = FluxEBSConsumableBridge
            if Bridge and Bridge.GetOwnedLadder then
                local ladder = Bridge.GetOwnedLadder("water", { allowComboDrinks = true })
                if ladder and ladder[1] and (ladder[1].count or 0) > 0 then
                    hasWater = true
                end
            end
        end
        if not hasWater then
            smart = false
        end
    end
    local EBV = _G.FluxExtraButtonVisibility
    if EBV and EBV.Apply then
        return EBV.Apply("nc_water", smart)
    end
    return smart
end

function Module.Create(grid)
    local btn = grid:CreateButton({
        columnPriority = 4,
        columnGroup = "foodwater",
        order = 1,
        size = grid.ButtonSize,
    })
    if not btn then
        return
    end
    Module._waterButton = btn
    btn.IsWaterButton = true
    FluxEBSButtonRefresh.Attach({
        module = Module,
        btn = btn,
        kind = "water",
        kindFlag = "IsWaterButton",
        placeholderIcon = PLACEHOLDER,
        placeholderLabel = "Water",
        listenerKey = "FluxNCWater",
        bindingName = USE_BINDING,
        middleClickDeleteConjured = true,
        shouldShow = ShouldShow,
        showTooltipExtras = AppendTooltip,
        applyRightClick = ApplyRC,
    })

    function Module.UpdateKeybinding()
        ApplyKeybinds(btn)
    end

    ApplyRC(btn)
    ApplyKeybinds(btn)

    local bindEvents = CreateFrame("Frame")
    bindEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    bindEvents:RegisterEvent("UPDATE_BINDINGS")
    bindEvents:RegisterEvent("GROUP_ROSTER_UPDATE")
    -- Shared by the frame events and the Core SpellBook bus.
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
            SpellBook.OnChanged("ncgrid.water", OnBindEvent)
        else
            bindEvents:RegisterEvent("SPELLS_CHANGED")
        end
    end

    local function RetryConjureBind()
        if InCombatLockdown and InCombatLockdown() then
            btn._pendingKeybindUpdate = true
            return
        end
        ApplyRC(btn)
        ApplyKeybinds(btn)
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, RetryConjureBind)
        C_Timer.After(2.0, RetryConjureBind)
    end
    local inv = _G.FluxInv
    if inv and inv.RegisterListener then
        inv.RegisterListener("FluxNCWaterConjure", function(ctx)
            local regions = ctx and ctx.regions
            if regions and regions.spells then
                RetryConjureBind()
            end
        end, {
            tier = "light",
            regions = { "spells" },
            deferHeavy = true,
        })
    end
end

_G.FluxNCWater = Module
return Module
