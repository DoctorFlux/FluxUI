-- FluxBaganator_Junk.lua
-- Registers FluxUI junk rules with Baganator (coin icon, grey highlight, junk category).

FluxBaganatorCompat = FluxBaganatorCompat or {}
local Compat = FluxBaganatorCompat

local REFRESH_REASONS

local function GetRefreshReasons()
    if REFRESH_REASONS then
        return REFRESH_REASONS
    end
    local constants = _G.Baganator and _G.Baganator.Constants
    if constants and constants.RefreshReason then
        REFRESH_REASONS = {
            constants.RefreshReason.ItemWidgets,
            constants.RefreshReason.Searches,
        }
    else
        REFRESH_REASONS = { "item_widgets", "searches" }
    end
    return REFRESH_REASONS
end

function Compat.RequestBaganatorRefresh(includeLayout)
    local api = _G.Baganator and _G.Baganator.API
    if not api or not api.RequestItemButtonsRefresh then
        return
    end
    local base = GetRefreshReasons()
    if not includeLayout then
        api.RequestItemButtonsRefresh(base)
        return
    end
    -- Copy so Layout is never permanently appended to the cached base table.
    local reasons = {}
    for i = 1, #base do
        reasons[i] = base[i]
    end
    local constants = _G.Baganator and _G.Baganator.Constants
    local layoutReason = constants and constants.RefreshReason and constants.RefreshReason.Layout
    reasons[#reasons + 1] = layoutReason or 32
    api.RequestItemButtonsRefresh(reasons)
end

local refreshTimer

local function ScheduleRefresh()
    if refreshTimer and refreshTimer.Cancel then
        refreshTimer:Cancel()
        refreshTimer = nil
    end
    if C_Timer and C_Timer.NewTimer then
        refreshTimer = C_Timer.NewTimer(0.12, function()
            refreshTimer = nil
            Compat.RequestBaganatorRefresh()
        end)
        return
    end
    Compat.RequestBaganatorRefresh()
end

function Compat.InitJunk()
    local api = _G.Baganator and _G.Baganator.API
    if not api or not api.RegisterJunkPlugin or Compat._junkInitialized then
        return
    end
    Compat._junkInitialized = true

    api.RegisterJunkPlugin("FluxUI", "fluxui", function(bagID, slotID, itemID)
        local fj = _G.FluxJunk
        if not fj then
            return false
        end
        if fj.IsSlotProtectedFromSell and fj.IsSlotProtectedFromSell(bagID, slotID) then
            return false
        end
        -- Item id only. A container read here runs once per item while
        -- Baganator rebuilds the open bank.
        if fj.IsJunkForDisplay then
            return fj.IsJunkForDisplay(itemID) == true
        end
        if fj.IsJunk and fj.IsJunk(itemID) then
            return true
        end
        return false
    end)

    -- Only re-request Baganator widgets when Flux junk verdicts change.
    -- Bag moves already refresh via Syndicator → Baganator (plugin runs there).
    local fj = _G.FluxJunk
    if fj and fj.RegisterListChanged then
        fj.RegisterListChanged(ScheduleRefresh)
    end
end
