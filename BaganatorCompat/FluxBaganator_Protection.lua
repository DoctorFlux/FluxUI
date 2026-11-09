-- FluxBaganator_Protection.lua
-- Blocks Baganator item-button actions on gear-set protected slots via click guards.
-- Hooks every Baganator ItemButton via Skins.RegisterListener (frames are created on PLAYER_LOGIN).

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local protectionRefreshTimer
local protectionGeneration = 0
local REFRESH_DEBOUNCE_SEC = 0.2

local BAGANATOR_BUTTON_HOOKS = {
    onEnter = nil,
    onLeave = nil,
    highPriority = true,
}

local function GetGearSetLock()
    local R = _G.FluxRespec
    return R and R.GearSetLock
end

local function ResolveBagSlot(button)
    if Compat.ResolveBaganatorItemButtonSlot then
        return Compat.ResolveBaganatorItemButtonSlot(button)
    end
end

local function ForwardBaganatorTooltip(button)
    if not button then
        return
    end
    if button.OnEnter then
        button:OnEnter()
        return
    end
    if button.UpdateTooltip then
        button:UpdateTooltip()
    end
end

local function HideBaganatorTooltip(button)
    if button and button.OnLeave then
        button:OnLeave()
        return
    end
    if GameTooltip_Hide then
        GameTooltip_Hide()
    elseif GameTooltip and GameTooltip.Hide then
        GameTooltip:Hide()
    end
end

BAGANATOR_BUTTON_HOOKS.onEnter = ForwardBaganatorTooltip
BAGANATOR_BUTTON_HOOKS.onLeave = HideBaganatorTooltip

function Compat.InvalidateBaganatorProtectionCache()
    protectionGeneration = protectionGeneration + 1
end

local function RefreshClickGuardOnButton(button)
    if not button or (button.IsShown and not button:IsShown()) then
        return
    end
    local lock = GetGearSetLock()
    if not lock or not lock.UpdateItemButtonClickGuard then
        return
    end
    local bagID, slotID = ResolveBagSlot(button)
    if not bagID or not slotID then
        if lock.HideItemButtonClickGuard then
            lock.HideItemButtonClickGuard(button)
        end
        button._fluxProtectionGen = nil
        button._fluxLastSlotKey = nil
        return
    end
    lock.UpdateItemButtonClickGuard(button, bagID, slotID, BAGANATOR_BUTTON_HOOKS)
    button._fluxLastSlotKey = ("%d:%d"):format(bagID, slotID)
end

local function ProtectionCacheKey(button)
    local bagID, slotID = ResolveBagSlot(button)
    if not bagID or not slotID then
        return nil
    end
    local bgr = button.BGR
    local itemID = bgr and bgr.itemID or 0
    local guid = bgr and bgr.guid or ""
    return ("%d:%d:%s:%s"):format(bagID, slotID, tostring(itemID), tostring(guid))
end

local function RefreshProtectionOnButton(button)
    if button._fluxProtectionGen == protectionGeneration then
        return
    end
    if Compat.InstallBaganatorItemContextOverride then
        Compat.InstallBaganatorItemContextOverride(button)
    end
    RefreshClickGuardOnButton(button)
    if Compat.RefreshShieldOnBaganatorButton then
        Compat.RefreshShieldOnBaganatorButton(button)
    end
    button._fluxProtectionGen = protectionGeneration
    button._fluxProtectionCacheKey = ProtectionCacheKey(button)
end

local function RefreshProtectionOnButtonForced(button)
    button._fluxProtectionGen = nil
    button._fluxProtectionCacheKey = nil
    button._fluxLastSlotKey = nil
    RefreshProtectionOnButton(button)
end

--- Refresh when generation bumped or slot/item identity changed.
local function RefreshProtectionOnButtonIfNeeded(button)
    if not button or not button.IsShown or not button:IsShown() then
        return
    end
    local cacheKey = ProtectionCacheKey(button)
    if button._fluxProtectionGen == protectionGeneration
        and cacheKey ~= nil
        and button._fluxProtectionCacheKey == cacheKey then
        return
    end

    -- Junk/consumable slots: clear any stale guard/shield cheaply; skip context install.
    local bgr = button.BGR
    local itemID = bgr and tonumber(bgr.itemID)
    if itemID then
        local IsEquippableItem = C_Item and C_Item.IsEquippableItem or _G.IsEquippableItem
        if IsEquippableItem and not IsEquippableItem(itemID) then
            local lock = GetGearSetLock()
            if lock and lock.HideItemButtonClickGuard then
                lock.HideItemButtonClickGuard(button)
            end
            if Compat.RefreshShieldOnBaganatorButton then
                Compat.RefreshShieldOnBaganatorButton(button)
            end
            button._fluxProtectionGen = protectionGeneration
            button._fluxProtectionCacheKey = cacheKey
            button._fluxLastSlotKey = nil
            return
        end
    end

    if Compat.InstallBaganatorItemContextOverride then
        Compat.InstallBaganatorItemContextOverride(button)
    end
    RefreshClickGuardOnButton(button)
    if Compat.RefreshShieldOnBaganatorButton then
        Compat.RefreshShieldOnBaganatorButton(button)
    end
    button._fluxProtectionGen = protectionGeneration
    button._fluxProtectionCacheKey = cacheKey
end

local function ForEachVisibleProtectionButton(callback)
    if Compat.ForEachVisibleItemButton then
        Compat.ForEachVisibleItemButton(callback)
        return
    end
    if Compat.ForEachBaganatorItemButton then
        Compat.ForEachBaganatorItemButton(callback)
    end
end

function Compat.InstallBaganatorItemButtonProtection(button)
    if not button or button._fluxBagButtonProtectionInstalled then
        return
    end
    button._fluxBagButtonProtectionInstalled = true

    -- Install vendor context override once. Do NOT hook SetItemDetails — that
    -- runs on every Baganator slot update during transfers and stacks hard lag.
    -- Click guards / shields refresh via RequestBaganatorProtectionRefresh
    -- (GEAR_SET_LOCK_CHANGED, BagShow, merchant) and the corner-widget plugin.
    if Compat.InstallBaganatorItemContextOverride then
        Compat.InstallBaganatorItemContextOverride(button)
    end
    RefreshProtectionOnButtonForced(button)
end

function Compat.InstallBaganatorItemButtonListeners()
    if Compat._baganatorItemButtonListenersInstalled then
        return
    end
    local api = _G.Baganator and _G.Baganator.API
    if not api or not api.Skins or not api.Skins.RegisterListener then
        return
    end
    Compat._baganatorItemButtonListenersInstalled = true

    api.Skins.RegisterListener(function(details)
        if details and details.regionType == "ItemButton" and details.region then
            Compat.InstallBaganatorItemButtonProtection(details.region)
        end
    end)

    if api.Skins.GetAllFrames then
        local frames = api.Skins.GetAllFrames()
        if type(frames) == "table" then
            for i = 1, #frames do
                local entry = frames[i]
                if entry and entry.regionType == "ItemButton" and entry.region then
                    Compat.InstallBaganatorItemButtonProtection(entry.region)
                end
            end
        end
    end
end

local function WithGearSetContextSnapshot(fn)
    local lock = GetGearSetLock()
    if lock and lock.WithContextSnapshot then
        return lock.WithContextSnapshot(fn)
    end
    return fn()
end

function Compat.RefreshBaganatorClickGuards()
    WithGearSetContextSnapshot(function()
        ForEachVisibleProtectionButton(RefreshClickGuardOnButton)
    end)
end

function Compat.RefreshBaganatorGearSetProtection()
    Compat.InvalidateBaganatorProtectionCache()
    -- IfNeeded skips hidden / non-equippable slots; snapshot avoids N merchant/DE checks.
    WithGearSetContextSnapshot(function()
        ForEachVisibleProtectionButton(RefreshProtectionOnButtonIfNeeded)
    end)
end

function Compat.RequestBaganatorProtectionRefresh()
    if protectionRefreshTimer and protectionRefreshTimer.Cancel then
        protectionRefreshTimer:Cancel()
        protectionRefreshTimer = nil
    end
    if C_Timer and C_Timer.NewTimer then
        protectionRefreshTimer = C_Timer.NewTimer(REFRESH_DEBOUNCE_SEC, function()
            protectionRefreshTimer = nil
            Compat.RefreshBaganatorGearSetProtection()
        end)
        return
    end
    Compat.RefreshBaganatorGearSetProtection()
end

local function InstallSellCursorBlock()
    if Compat._sellCursorBlockInstalled or type(_G.SellCursorItem) ~= "function" then
        return
    end
    Compat._sellCursorBlockInstalled = true

    local origSellCursorItem = _G.SellCursorItem
    _G.SellCursorItem = function(...)
        local lock = GetGearSetLock()
        if lock and lock.IsSlotProtected and GetCursorInfo then
            local cursorType, _, _, _, bag, slot = GetCursorInfo()
            bag = tonumber(bag)
            slot = tonumber(slot)
            if cursorType == "item" and bag and slot and lock.IsSlotProtected(bag, slot) then
                local block = false
                if lock.IsMerchantSellContext and lock.IsMerchantSellContext() then
                    block = true
                elseif lock.IsDisenchantContext and lock.IsDisenchantContext() then
                    block = true
                end
                if block then
                    if ClearCursor then
                        ClearCursor()
                    end
                    if lock.NotifyBlocked then
                        lock.NotifyBlocked()
                    end
                    return
                end
            end
        end
        return origSellCursorItem(...)
    end
end

function Compat.FinalizeBaganatorIntegration()
    Compat.InstallBaganatorItemButtonListeners()
    if Compat.WrapExistingBaganatorViews then
        Compat.WrapExistingBaganatorViews()
    end
    if Compat.FinalizeBankRestock then
        Compat.FinalizeBankRestock()
    end
    Compat.RequestBaganatorProtectionRefresh()
end

function Compat.InitProtection()
    if Compat._protectionInitialized then
        return
    end
    Compat._protectionInitialized = true

    InstallSellCursorBlock()
    Compat.InstallBaganatorItemButtonListeners()

    if Compat.InitBaganatorViewTracking then
        Compat.InitBaganatorViewTracking()
    end

    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if registry and registry.RegisterCallback then
        -- Do not refresh protection on every ViewComplete (fires on each bag transfer
        -- rebuild). SetItemDetails IfNeeded + GEAR_SET_LOCK_CHANGED cover slot moves.
        registry:RegisterCallback("BagShow", function()
            if Compat.WrapExistingBaganatorViews then
                Compat.WrapExistingBaganatorViews()
            end
            Compat.RequestBaganatorProtectionRefresh()
        end)
    end

    local R = _G.FluxRespec
    if R and R.On then
        R.On("GEAR_SET_LOCK_CHANGED", Compat.RequestBaganatorProtectionRefresh)
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.25, Compat.FinalizeBaganatorIntegration)
            else
                Compat.FinalizeBaganatorIntegration()
            end
            return
        end
        Compat.RequestBaganatorProtectionRefresh()
    end)
end

