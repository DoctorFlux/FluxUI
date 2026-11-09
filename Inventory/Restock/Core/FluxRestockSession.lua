--[[
    Restock/Core/FluxRestockSession.lua

    Vendor/bank session lifecycle (Scrap + Restocker model).
    Close handlers are teardown-only: no tier recompute, no overlay UpdateAll.
]]

FluxRestockSession = FluxRestockSession or {}
local Session = FluxRestockSession

local function Inv() return _G.FluxRestock and _G.FluxRestock.Inv end
local function FJ() return _G.FluxVendorJunk end

--- Incremental inferior cleanup when items leave bags (sell / bank deposit).
function Session.NotifyItemsRemoved(idSet)
    if type(idSet) ~= "table" or not next(idSet) then
        return
    end
    local inv = Inv()
    local actuallyRemoved = {}
    for itemID in pairs(idSet) do
        itemID = tonumber(itemID)
        if itemID then
            if inv and inv.ItemExistsInInventory and inv.ItemExistsInInventory(itemID) then
                -- Item still in bags (failed sell, session-close noise): keep inferior mark.
            else
                actuallyRemoved[itemID] = true
            end
        end
    end
    if inv and inv.NotifyItemsRemoved and next(actuallyRemoved) then
        inv.NotifyItemsRemoved(actuallyRemoved)
    end
    local fj = FJ()
    if fj and fj.UnmarkUpgradeInferior then
        for itemID in pairs(actuallyRemoved) do
            fj.UnmarkUpgradeInferior(itemID)
        end
    end
end

function Session.OnMerchantOpen()
    -- Session state reset is handled by FluxInv session tracking.
end

function Session.OnMerchantClose()
end

function Session.OnBankOpen()
    -- Bank mover auto-start is handled by FluxBankRestock RegisterBankOpen.
end

function Session.OnBankClose()
    local br = _G.FluxBankRestock
    if br and br.Stop and br.IsRunning and br.IsRunning() then
        pcall(br.Stop)
    end
end

--- Removal-only close with no deferred inventory listeners (junk sell / deposit).
function Session.ApplyRemovalOnlyClose(removed)
    if removed and next(removed) then
        Session.NotifyItemsRemoved(removed)
    end
end

_G.FluxRestockSession = Session
return Session
