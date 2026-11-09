--[[
    Inventory/Restock/Vendor/FluxVendorSession.lua

    Thin facade restoring post-FluxInv deferral sites that still check
    _G.FluxVendorSession / FluxVendorSessionRefresh.
]]

local function Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

local function FV()
    return _G.FluxVendorAuto
end

local function After(delay, fn)
    if type(fn) ~= "function" then
        return
    end
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(delay, fn)
    elseif _G.FLUX_API and _G.FLUX_API.After then
        _G.FLUX_API.After(delay, fn)
    else
        fn()
    end
end

local sessionActive = false
local refreshPending = false
local refreshTimer = nil
local settleWait = false

local function IsAutomationQuiet()
    local inv = Inv()
    return inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() or false
end

FluxVendorSession = {
    IsOpen = function()
        local inv = Inv()
        if inv and inv.IsMerchantOpen then
            return inv.IsMerchantOpen()
        end
        return sessionActive
    end,
    IsBuyTabActive = function()
        if not FluxVendorSession.IsOpen() then
            return false
        end
        return MerchantFrame and MerchantFrame.selectedTab == 1
    end,
    IsBurstActive = function()
        local fv = FV()
        if fv and fv.IsVendorBurstActive then
            return fv.IsVendorBurstActive()
        end
        return IsAutomationQuiet()
    end,
    IsPurchaseStormActive = function()
        return IsAutomationQuiet()
    end,
    IsPipelineBusy = function()
        local fv = FV()
        return fv and fv.IsVendorBurstActive and fv.IsVendorBurstActive() or false
    end,
    IsMerchantBagStormActive = function()
        return FluxVendorSession.IsBurstActive()
    end,
    IsLoginBagStormActive = function()
        local pl = _G.FluxEBS_PostLoginBagRefresh
        return pl and pl.IsPulseActive and pl.IsPulseActive() or false
    end,
    ShouldDeferHeavyBagWork = function()
        local inv = Inv()
        if inv and inv.ShouldDeferHeavyWork then
            return inv.ShouldDeferHeavyWork()
        end
        return FluxVendorSession.IsBurstActive()
    end,
    ShouldDeferFullVisualRefresh = function()
        return FluxVendorSession.ShouldDeferBagVisuals()
    end,
    ShouldDeferHeavyScans = function()
        return FluxVendorSession.ShouldDeferHeavyBagWork()
    end,
    -- Heavy bag visuals can wait on buy/sell burst. Vendor *refresh* must not
    -- use this predicate or it re-enters OnPurchaseStormSettled forever.
    ShouldDeferBagVisuals = function()
        if FluxVendorSession.IsBurstActive() then
            return true
        end
        return IsAutomationQuiet()
    end,
    OnPurchaseStormSettled = function(fn)
        if type(fn) ~= "function" then
            return
        end
        -- Never run the caller on this stack. Immediate fn() here caused
        -- DoVendorRefresh → settle → fn → DoVendorRefresh overflow.
        local function run()
            After(0, fn)
        end
        local inv = Inv()
        if inv and inv.OnQuietSettled then
            inv.OnQuietSettled(run)
        else
            run()
        end
    end,
    OnBagStormSettled = function(fn)
        FluxVendorSession.OnPurchaseStormSettled(fn)
    end,
    OnLoginBagStormSettled = function(fn)
        local pl = _G.FluxEBS_PostLoginBagRefresh
        if pl and pl.RegisterPulseEndCallback then
            pl.RegisterPulseEndCallback("VendorSessionCompat" .. tostring(fn), fn)
        elseif type(fn) == "function" then
            After(0, fn)
        end
    end,
    BeginPurchaseStorm = function()
        local inv = Inv()
        if inv and inv.NotifyAutomationPulse then
            inv.NotifyAutomationPulse(0.35)
        end
    end,
    BeginLoginBagStorm = function() end,
    RecordDeferredHeavyWork = function() end,
    SetOpen = function(isOpen)
        sessionActive = not not isOpen
    end,
    WouldSkipMerchantOpenAllBags = function()
        return false
    end,
}

local function DoVendorRefresh(opts)
    refreshTimer = nil
    opts = opts or {}
    if not FluxVendorSession.IsOpen() then
        refreshPending = false
        settleWait = false
        return
    end
    -- Same predicate as OnQuietSettled. Burst/buy/sell still skip heavy UI
    -- via ShouldDeferBagVisuals elsewhere; they must not recurse here.
    if IsAutomationQuiet() then
        if settleWait then
            return
        end
        settleWait = true
        FluxVendorSession.OnPurchaseStormSettled(function()
            settleWait = false
            DoVendorRefresh(opts)
        end)
        return
    end
    refreshPending = false
    settleWait = false
    local ui = _G.FluxVendorAutoMerchantUI
    if opts.junk ~= false and ui then
        if ui.ScheduleJunkUIRefresh then
            ui.ScheduleJunkUIRefresh(false)
        end
    end
    if opts.restockData ~= false and ui then
        if ui.ScheduleMerchantUpdate then
            ui.ScheduleMerchantUpdate("data")
        elseif ui.UpdateMerchantUI then
            ui.UpdateMerchantUI("data")
        end
    end
end

--- Deliberate vendor UI refresh API (replaces dead _G.FluxVendorSessionRefresh).
FluxVendorSessionRefresh = {
    BeginVendorSession = function()
        sessionActive = true
        FluxVendorSession.SetOpen(true)
    end,
    EndVendorSession = function()
        sessionActive = false
        FluxVendorSession.SetOpen(false)
        refreshPending = false
        refreshTimer = nil
        settleWait = false
    end,
    RequestVendorRefresh = function(opts)
        if refreshPending then
            return
        end
        refreshPending = true
        refreshTimer = true
        After(0.15, function()
            DoVendorRefresh(opts)
        end)
    end,
}

_G.FluxVendorSession = FluxVendorSession
_G.FluxVendorSessionRefresh = FluxVendorSessionRefresh
