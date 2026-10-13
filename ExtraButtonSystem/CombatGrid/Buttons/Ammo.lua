--[[
    ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua
    Display-only ammo / thrown weapon count for Combat Grid.
    Shows when ammo is equipped in the ammo slot or a thrown weapon is in the ranged slot; hidden otherwise.
]]

FluxCombatAmmo = FluxCombatAmmo or {}
local Module = FluxCombatAmmo

local WEAPON_CLASS_ID = 2
local THROWN_SUBCLASS_ID = 16

local function GetInventorySlotIdSafe(slotToken)
    if not GetInventorySlotInfo then return nil end
    local ok, slot = pcall(GetInventorySlotInfo, slotToken)
    if not ok or type(slot) ~= "number" then return nil end
    return slot
end

local function ItemInstantEquipAndClass(itemID)
    if not itemID then return nil, nil, nil end
    if C_Item and C_Item.GetItemInfoInstant then
        local r1, r2, r3, r4, r5, r6, r7 = C_Item.GetItemInfoInstant(itemID)
        if type(r1) == "table" then
            local t = r1
            return t.itemEquipLoc or t.equipLoc, t.classID, t.subClassID
        end
        local _, _, _, equipLoc, _, classId, subclassId = r1, r2, r3, r4, r5, r6, r7
        return equipLoc, classId, subclassId
    end
    if GetItemInfoInstant then
        local _, _, _, equipLoc, _, classId, subclassId = GetItemInfoInstant(itemID)
        return equipLoc, classId, subclassId
    end
    return nil, nil, nil
end

local function IsThrownWeapon(itemID)
    if not itemID or itemID == 0 then return false end
    local equipLoc, classId, subclassId = ItemInstantEquipAndClass(itemID)
    if equipLoc == "INVTYPE_THROWN" then return true end
    if classId == WEAPON_CLASS_ID and subclassId == THROWN_SUBCLASS_ID then return true end
    if GetItemInfo then
        local el = select(9, GetItemInfo(itemID))
        if el == "INVTYPE_THROWN" then return true end
    end
    return false
end

local function GetTotalItemCount(itemID)
    if not itemID then return 0 end
    local opts = {
        charges = true,
        bags = true,
        equipped = true,
        bank = false,
        warband = false,
        includeBank = false,
    }
    local Flux = _G.Flux
    local inv = Flux and Flux.Inventory
    if inv and inv.GetLiveCount then
        return inv.GetLiveCount(itemID, opts) or 0
    end
    local legacy = _G.FluxInv
    if legacy and legacy.GetLiveCount then
        return legacy.GetLiveCount(itemID, opts) or 0
    end
    if legacy and legacy.GetCount then
        return legacy.GetCount(itemID, opts) or 0
    end
    return 0
end

local function ShouldHoldItemIdentity()
    local B = _G.FluxEBSConsumableBridge
    if B and B.ShouldHoldItemIdentity then
        return B.ShouldHoldItemIdentity() and true or false
    end
    local BestMod = _G.FluxConsumableBest
    if BestMod and BestMod.ShouldSoftHoldOwned then
        return BestMod.ShouldSoftHoldOwned() and true or false
    end
    return false
end

--- Resolve equipped ammo (ammo slot) or thrown in ranged; nil if neither applies.
local function GetDisplayItemID()
    local ammoSlot = GetInventorySlotIdSafe("AmmoSlot")
    local rangedSlot = GetInventorySlotIdSafe("RangedSlot")

    if ammoSlot then
        local id = GetInventoryItemID("player", ammoSlot)
        if id and id > 0 then
            return id
        end
    end

    if rangedSlot then
        local id = GetInventoryItemID("player", rangedSlot)
        if id and id > 0 and IsThrownWeapon(id) then
            return id
        end
    end

    return nil
end

local function ShouldShowAmmoButton()
    if GetDisplayItemID() ~= nil then
        return true
    end
    if Module._lastGoodAmmoID and ShouldHoldItemIdentity() then
        return true
    end
    return false
end

--- Remove secure use so the button does not consume ammo/thrown on click.
local function StripSecureItemUse(btn)
    if not btn or not btn.Widget then return true end
    if InCombatLockdown() then return false end
    local w = btn.Widget
    w:SetAttribute("type", nil)
    w:SetAttribute("typerelease", nil)
    w:SetAttribute("spell", nil)
    w:SetAttribute("spell2", nil)
    w:SetAttribute("item", nil)
    w:SetAttribute("macro", nil)
    w:SetAttribute("macrotext", nil)
    w:SetAttribute("macrotext2", nil)
    w:SetAttribute("macrotext3", nil)
    w:SetAttribute("action", nil)
    return true
end

local function ApplyCount(btn, count, itemID)
    if btn.SetCount then
        btn:SetCount(count or 0, itemID and { live = true, itemId = itemID } or nil)
        return
    end
    if btn.WCount then
        btn.WCount:SetText(tostring(count or 0))
        btn.WCount:Show()
    end
end

function Module.Create(grid)
    do
        local EBV = FluxExtraButtonVisibility
        local API = _G.FLUX_API
        local supports = true
        if EBV and type(EBV.ClientHasAmmoSlot) == "function" then
            supports = EBV.ClientHasAmmoSlot()
        elseif API and type(API.ClientSupportsCombatAmmoExtraButton) == "function" then
            supports = API.ClientSupportsCombatAmmoExtraButton()
        end
        if not supports then
            return
        end
    end
    -- Last column-group priority and last stack order within any shared column
    local btn = grid:CreateButton({
        columnGroup = "ammo",
        columnPriority = 999,
        order = 100,
        size = grid.ButtonSize,
    })
    if not btn then return end

    Module.Button = btn
    btn.IsAmmoDisplayButton = true
    -- Prefer SetItemByID tooltips (skip bag scan); display-only ammo has no Flux extras.
    btn._fluxPreferItemByIdTooltip = true
    -- Blizzard + FluxUI only (no other-addon TooltipDataProcessor / GameTooltip inject).
    btn._fluxIsolatedTooltip = true
    -- Display-only: never dim/desaturate like a real unusable item action
    btn.IgnoreUsabilityVisual = true
    -- Equipped ammo reads as "current item"; suppress checked/gold highlight
    btn.IgnoreCheckedVisual = true

    local function RefreshCountOnly()
        if not btn then return end
        local itemID = GetDisplayItemID()
        local count = 0
        if itemID then
            count = GetTotalItemCount(itemID)
        end
        ApplyCount(btn, count, itemID)
    end

    local function _CombatRefresh()
        if not btn then return end
        if not InCombatLockdown() then return end
        if not GetDisplayItemID() then return end
        RefreshCountOnly()
    end

    local function StopCombatRefreshTicker()
        if FluxCombatManager and FluxCombatManager.UnregisterCombatRefresh then
            FluxCombatManager:UnregisterCombatRefresh("Ammo")
        end
    end

    local function StartCombatRefreshTicker()
        if not InCombatLockdown() then return end
        local displayId = GetDisplayItemID()
        if not displayId then return end
        if FluxCombatManager and FluxCombatManager.RegisterCombatRefresh then
            FluxCombatManager:RegisterCombatRefresh("Ammo", _CombatRefresh)
        end
    end

    local function Update()
        if InCombatLockdown() then
            Module._pendingUpdate = true
            RefreshCountOnly()
            StartCombatRefreshTicker()
            return
        end

        local itemID = GetDisplayItemID()
        if not itemID and ShouldHoldItemIdentity() then
            itemID = Module._lastGoodAmmoID
        end
        if itemID then
            Module._lastGoodAmmoID = itemID
        end
        local smartAmmo = ShouldShowAmmoButton()
        local fbm = _G.FluxBindingMode
        local bindingForce = fbm and fbm.ShouldForceShowAllExtraSlots and fbm:ShouldForceShowAllExtraSlots()

        if not smartAmmo then
            if FluxExtraButtonVisibility and not FluxExtraButtonVisibility.Apply("combat_ammo", smartAmmo, bindingForce) then
                if btn.SlotFrame then btn.SlotFrame:Hide() end
                if grid and grid.Relayout then grid:ScheduleRelayout() end
                return
            end
            -- Without EBV: hide when nothing is equipped (auto behavior).
            if not FluxExtraButtonVisibility then
                if btn.SlotFrame then btn.SlotFrame:Hide() end
                if grid and grid.Relayout then grid:ScheduleRelayout() end
                return
            end
            if btn.SlotFrame then btn.SlotFrame:Show() end
            if grid and grid.Relayout then grid:ScheduleRelayout() end
            if btn.ClearAction then btn:ClearAction() end
            if btn.SetPlaceholder then
                btn:SetPlaceholder("Interface/Icons/INV_Misc_Ammo_Bullet_01", "Ammo")
            end
            Module._lastGoodAmmoID = nil
            ApplyCount(btn, 0, nil)
            if btn.FullRefresh then btn:FullRefresh() end
            if not StripSecureItemUse(btn) then
                Module._pendingStrip = true
            else
                Module._pendingStrip = nil
            end
            return true
        end

        if FluxExtraButtonVisibility and not FluxExtraButtonVisibility.Apply("combat_ammo", smartAmmo, bindingForce) then
            if btn.SlotFrame then btn.SlotFrame:Hide() end
            if grid and grid.Relayout then grid:ScheduleRelayout() end
            return
        end

        if btn.SlotFrame then btn.SlotFrame:Show() end
        if grid and grid.Relayout then grid:ScheduleRelayout() end

        if btn.ClearPlaceholder then btn:ClearPlaceholder() end
        if btn.SetAction then btn:SetAction("item", itemID) end
        if btn.SetLocked then btn:SetLocked(true) end

        ApplyCount(btn, GetTotalItemCount(itemID), itemID)

        if btn.FullRefresh then btn:FullRefresh() end

        if not StripSecureItemUse(btn) then
            Module._pendingStrip = true
        else
            Module._pendingStrip = nil
        end

        return true
    end

    Module.Update = Update
    Update()

    local function runPostLoginRefresh()
        local function doUpdate()
            if not InCombatLockdown() then
                Update()
            else
                Module._pendingUpdate = true
                RefreshCountOnly()
                StartCombatRefreshTicker()
            end
        end
        local pl = FluxEBS_PostLoginBagRefresh
        local loginBootstrap = pl and pl.IsFreshLoginBootstrap and pl.IsFreshLoginBootstrap()
        if loginBootstrap and pl then
            if pl.ScheduleLoginItemRefresh then
                pl.ScheduleLoginItemRefresh(doUpdate)
            elseif pl.Schedule then
                pl.Schedule(doUpdate, pl.LOGIN_ITEM_DELAYS)
            end
        else
            doUpdate()
        end
    end

    local eventFrame = CreateFrame("Frame")
    local equipDebounceTimer = nil
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            StopCombatRefreshTicker()
            local pu = Module._pendingUpdate
            local ps = Module._pendingStrip
            if pu then
                Module._pendingUpdate = nil
                if FluxCombatRegenDeferQueue then
                    FluxCombatRegenDeferQueue(function()
                        if InCombatLockdown() then
                            Module._pendingUpdate = true
                            return
                        end
                        Update()
                    end)
                else
                    Update()
                end
            elseif ps then
                if FluxCombatRegenDeferQueue then
                    FluxCombatRegenDeferQueue(function()
                        if InCombatLockdown() then
                            return
                        end
                        if StripSecureItemUse(btn) then
                            Module._pendingStrip = nil
                        end
                    end)
                else
                    if StripSecureItemUse(btn) then
                        Module._pendingStrip = nil
                    end
                end
            end
            return
        end

        if event == "PLAYER_REGEN_DISABLED" then
            if GetDisplayItemID() then
                StartCombatRefreshTicker()
            end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            runPostLoginRefresh()
            return
        end

        if not InCombatLockdown() then
            if equipDebounceTimer then equipDebounceTimer:Cancel() end
            equipDebounceTimer = C_Timer.NewTimer(0.15, function()
                equipDebounceTimer = nil
                if not InCombatLockdown() then
                    Update()
                else
                    Module._pendingUpdate = true
                end
            end)
        else
            Module._pendingUpdate = true
            RefreshCountOnly()
            StartCombatRefreshTicker()
        end
    end)

    local inv = _G.FluxInv
    if inv and inv.RegisterListener then
        inv.RegisterListener("FluxCombatAmmo", function(ctx)
            if ctx and ctx.changeKind == "countOnly" then
                RefreshCountOnly()
                return
            end
            if InCombatLockdown() then
                Module._pendingUpdate = true
                RefreshCountOnly()
                StartCombatRefreshTicker()
                return
            end
            local M = _G.FluxCombatManager
            if M and M.ScheduleAllUpdates then
                M:ScheduleAllUpdates(false)
            else
                Update()
            end
        end, { tier = "scan", regions = { "bags", "equip" }, deferHeavy = true })
    end

    if FluxEBS_PostLoginBagRefresh and FluxEBS_PostLoginBagRefresh.RegisterFirstBagDelayedCallback then
        FluxEBS_PostLoginBagRefresh.RegisterFirstBagDelayedCallback("CombatAmmo", function()
            if not InCombatLockdown() then
                Update()
            else
                Module._pendingUpdate = true
                RefreshCountOnly()
                StartCombatRefreshTicker()
            end
        end)
    end

    return btn
end

_G.FluxCombatAmmo = Module
return Module
