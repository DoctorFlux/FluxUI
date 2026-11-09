--[[ ExtraButtonSystem/CombatGrid/Buttons/ManaGem.lua — Inventory-backed ]]

FluxCombatManaGem = FluxCombatManaGem or {}
local Module = FluxCombatManaGem

local PLACEHOLDER = "Interface\\Icons\\INV_Misc_Gem_Sapphire_02"
local USE_BINDING = "FLUXCOMBAT_MANAGEM"
local CONJURE_BINDING = "FLUXMAGE_CONJURE_MANAGEM"

local function GetCreateSpell()
    local Bridge = FluxEBSConsumableBridge
    if Bridge.GetNextManaGemConjureSpell then
        return Bridge.GetNextManaGemConjureSpell()
    end
    return Bridge.GetPreferredCreateSpell("managem")
end

function Module.KnowsAnyConjureSpell()
    local Bridge = FluxEBSConsumableBridge
    if Bridge.KnowsManaGemConjureSpell then
        return Bridge.KnowsManaGemConjureSpell() and true or false
    end
    local spellID, spellName = GetCreateSpell()
    return (spellID or spellName) and true or false
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
        canConjure = function()
            return Module.KnowsAnyConjureSpell()
        end,
    })
end

local function SoftHoldOwned()
    local BestMod = _G.FluxConsumableBest
    return BestMod and BestMod.ShouldSoftHoldOwned and BestMod.ShouldSoftHoldOwned() and true or false
end

local function ShouldShow()
    local EBV = _G.FluxExtraButtonVisibility
    if EBV and EBV.QuickGate then
        local gate = EBV.QuickGate("combat_manaGem")
        if gate == false then
            return false
        end
    end
    -- Combat-grid gem is a conjure slot, not a bag-gem slot.
    if not Module.KnowsAnyConjureSpell() then
        return false
    end
    if EBV and EBV.Apply then
        return EBV.Apply("combat_manaGem", true)
    end
    return true
end

local function GemUses(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local Bridge = FluxEBSConsumableBridge
    return Bridge.BagCount(itemID, { charges = true, kind = "managem" }) or 0
end

local function GemDisplay(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local Bridge = FluxEBSConsumableBridge
    if Bridge.DisplayItemCount then
        return Bridge.DisplayItemCount(itemID, { preferCopies = true, kind = "managem" }) or 0
    end
    return GemUses(itemID)
end

local function ApplyGemCount(btn, itemID)
    local count = GemDisplay(itemID)
    if SoftHoldOwned() and itemID then
        local held = count > 0 and count or (tonumber(btn._lastGemCount) or tonumber(Module._latchCount) or 0)
        if held > 0 then
            count = held
        end
    end
    if itemID and count > 0 then
        Module._latchItemID = itemID
        Module._latchCount = count
        btn._fluxLastCount = count
    end
    if btn.SetCount then
        -- Soft-hold snapshot must not use live APIs (they read 0 on zone load).
        if SoftHoldOwned() and count > 0 then
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
    btn._lastGemCount = count
    btn._lastIconR, btn._lastIconG, btn._lastIconB = nil, nil, nil
    if btn.UpdateUsable then
        btn:UpdateUsable()
    end
end

local function StickyGemMode()
    local Bridge = FluxEBSConsumableBridge
    return Bridge.ShouldStickyManaGemItem and Bridge.ShouldStickyManaGemItem() and true or false
end

--- Charge-based gem or 0-mana conjure: last owned, else the best known conjure product.
local function LatestGemItemID()
    local Bridge = FluxEBSConsumableBridge
    return tonumber(Module._latchItemID)
        or tonumber(Module._trackedItemID)
        or (Bridge.GetPreferredManaGemItemID and tonumber(Bridge.GetPreferredManaGemItemID()))
end

--- Keep the real gem item on the face (never the generic placeholder icon).
local function BindGemFace(btn, itemID, force)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local changed = force
        or itemID ~= Module._trackedItemID
        or btn.PlaceholderTexture
        or btn.ActionType ~= "item"
        or tonumber(btn.ItemId or btn.ActionValue) ~= itemID
    Module._trackedItemID = itemID
    Module._latchItemID = itemID
    btn.ItemId = itemID
    if btn.ClearPlaceholder then
        btn:ClearPlaceholder()
    end
    btn.PlaceholderTexture = nil
    btn.PlaceholderLabel = nil
    if changed and btn.SetAction then
        btn:SetAction("item", itemID)
        if btn.FullRefresh then
            btn:FullRefresh()
        end
    end
    ApplyGemCount(btn, itemID)
    return true
end

--- Override Update to use castsequence of owned gems (best first).
local function AttachManaGem(btn)
    local Bridge = FluxEBSConsumableBridge
    local Refresh = FluxEBSButtonRefresh

    Refresh.Attach({
        module = Module,
        btn = btn,
        kind = "managem",
        charges = true,
        kindFlag = "IsManaGemButton",
        placeholderIcon = PLACEHOLDER,
        placeholderLabel = "Mana Gem",
        listenerKey = "FluxCombatManaGem",
        bindingName = USE_BINDING,
        middleClickDelete = true,
        combatGridCoalesce = true,
        shouldShow = ShouldShow,
        showTooltipExtras = AppendTooltip,
        applyRightClick = ApplyRC,
    })

    -- Keep charge count visible for item + castsequence macro binds (and placeholder 0).
    do
        local originalUpdateTextCount = btn.UpdateTextCount
        if originalUpdateTextCount then
            btn.UpdateTextCount = function(self)
                local bestId = self.ItemId or Module._trackedItemID
                self._forcedCount = GemDisplay(bestId)
                if bestId then
                    self._forcedCountLive = true
                    self._liveCountItemId = bestId
                end
                originalUpdateTextCount(self)
            end
        end
    end

    function Module.UpdateKeybinding()
        ApplyKeybinds(btn)
    end

    ApplyRC(btn)
    ApplyKeybinds(btn)

    -- Best-generation coalescer skips when bags did not change; learning the
    -- conjure spell must still show (or hide) this slot.
    local bindEvents = CreateFrame("Frame")
    bindEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    bindEvents:RegisterEvent("UPDATE_BINDINGS")
    -- Shared by the frame events and the Core SpellBook bus (conjure rebind).
    local function OnBindEvent(event)
        if bindEvents._refreshPending then
            return
        end
        bindEvents._refreshPending = true
        local ev = event
        C_Timer.After(0.15, function()
            bindEvents._refreshPending = false
            if ev == "SPELLS_CHANGED" then
                if Module.Update then
                    Module.Update()
                end
            end
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
    bindEvents:SetScript("OnEvent", function(_, event)
        OnBindEvent(event)
    end)
    -- SPELLS_CHANGED rides the debounced, signature-gated Core bus; the direct
    -- frame registration stays only as fallback when the bus is missing.
    do
        local SpellBook = _G.Flux and _G.Flux.SpellBook
        if SpellBook and SpellBook.OnChanged then
            SpellBook.OnChanged("cgrid.managem", function()
                OnBindEvent("SPELLS_CHANGED")
            end)
        else
            bindEvents:RegisterEvent("SPELLS_CHANGED")
        end
    end

    function Module.RefreshCountOnly()
        ApplyGemCount(btn, Module._trackedItemID or btn.ItemId)
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

        -- Load-screen bag flicker: keep the last gem; do not SetPlaceholder.
        if SoftHoldOwned() then
            local keepID = Module._latchItemID or Module._trackedItemID
            if keepID then
                if StickyGemMode() then
                    BindGemFace(btn, keepID, force)
                else
                    Module._trackedItemID = keepID
                    Module._latchItemID = keepID
                    btn.ItemId = keepID
                    ApplyGemCount(btn, keepID)
                end
                Module._pendingUpdate = true
                return
            end
        end

        local ladder = Bridge.GetOwnedLadder("managem", { charges = true })
        if type(ladder) == "table" and #ladder > 0 then
            local live = {}
            for i = 1, #ladder do
                local entry = ladder[i]
                local itemID = entry and tonumber(entry.itemID)
                local uses = itemID and GemUses(itemID) or 0
                if uses > 0 then
                    live[#live + 1] = {
                        itemID = itemID,
                        count = uses,
                        source = "owned",
                        kind = "managem",
                    }
                end
            end
            ladder = live
        end
        local softHold = SoftHoldOwned()
        if (not ladder or #ladder == 0) then
            local keepID = Module._latchItemID or Module._trackedItemID
            if not keepID and softHold then
                keepID = Bridge.GetPreferredManaGemItemID and Bridge.GetPreferredManaGemItemID()
            end
            if keepID and softHold then
                ladder = {
                    {
                        itemID = keepID,
                        count = math.max(1, tonumber(Module._latchCount) or GemUses(keepID) or 1),
                        source = "owned",
                        kind = "managem",
                    },
                }
            end
        end
        if ladder and #ladder > 0 then
            -- Expand by bag uses (V9): Ruby×2 + Citrine → Ruby, Ruby, Citrine.
            local ids = {}
            for i = 1, #ladder do
                local entry = ladder[i]
                local itemID = entry.itemID
                local uses = tonumber(entry.count) or 0
                if uses < 1 then
                    uses = 1
                end
                for _ = 1, uses do
                    ids[#ids + 1] = itemID
                end
            end
            local bestID = ladder[1].itemID
            local bestIsCharge = Bridge.IsManaGemChargeBased and Bridge.IsManaGemChargeBased(bestID)
            local stickyBest = StickyGemMode()
            -- Charge-based / free conjure: stay on best item (no multi-tier castsequence).
            -- Vanilla paid: castsequence reset=combat, one entry per use.
            if bestIsCharge or stickyBest or #ids <= 1 then
                BindGemFace(btn, bestID, force)
            else
                local changed = force or bestID ~= Module._trackedItemID
                Module._trackedItemID = bestID
                Module._latchItemID = bestID
                btn.ItemId = bestID
                if btn.ClearPlaceholder then
                    btn:ClearPlaceholder()
                end
                btn.PlaceholderTexture = nil
                if changed then
                    local macro = Bridge.BuildCastSequenceMacro(ids)
                    if macro then
                        btn:SetAction("macrotext", macro)
                    else
                        btn:SetAction("item", bestID)
                    end
                    if btn.FullRefresh then
                        btn:FullRefresh()
                    end
                end
                -- Count after paint so UpdateTextCount / FlushCounts do not wipe a latched use.
                ApplyGemCount(btn, bestID)
            end
        else
            -- Charge-based / 0-mana conjure: latest item, not the generic placeholder.
            -- Vanilla paid / no sticky id: placeholder.
            local stickyID = StickyGemMode() and LatestGemItemID() or nil
            if SoftHoldOwned() then
                local keepID = stickyID or Module._latchItemID or Module._trackedItemID
                    or (Bridge.GetPreferredManaGemItemID and Bridge.GetPreferredManaGemItemID())
                if keepID then
                    if stickyID then
                        BindGemFace(btn, keepID, force)
                    else
                        Module._trackedItemID = keepID
                        Module._latchItemID = keepID
                        btn.ItemId = keepID
                        ApplyGemCount(btn, keepID)
                    end
                    Module._pendingUpdate = true
                    ApplyRC(btn)
                    if Bridge.ApplyMiddleClickNoUse then
                        Bridge.ApplyMiddleClickNoUse(btn)
                    end
                    ApplyKeybinds(btn)
                    btn.ButtonLocked = true
                    if btn.SetLocked then
                        btn:SetLocked(true)
                    end
                    return
                end
            end
            if stickyID and BindGemFace(btn, stickyID, force) then
                -- Keep the latest gem bound at count 0 so left-click stays the item.
            else
                Module._trackedItemID = nil
                Module._latchItemID = nil
                Module._latchCount = nil
                btn.ItemId = nil
                if btn.SetPlaceholder then
                    btn:SetPlaceholder(PLACEHOLDER, "Mana Gem")
                elseif btn.ClearAction then
                    btn:ClearAction()
                end
                ApplyGemCount(btn, nil) -- show "0" on placeholder
            end
        end

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
        columnGroup = "mana",
        columnPriority = 20,
        order = 1,
        size = grid.ButtonSize,
    })
    if not btn then
        return
    end
    AttachManaGem(btn)
end

_G.FluxCombatManaGem = Module
return Module
