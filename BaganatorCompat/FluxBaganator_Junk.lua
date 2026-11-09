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

-- Registration alone leaves an existing detector (for example RXPGuides)
-- active. Adopt FluxUI once per profile, then respect later manual choices.
function Compat.ConfigureBaganatorJunkDetector()
    local config = _G.BAGANATOR_CONFIG
    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if type(config) ~= "table" or not registry or not registry.TriggerEvent then
        return false
    end
    local profile = config
    if type(config.Profiles) == "table" then
        profile = config.Profiles[_G.BAGANATOR_CURRENT_PROFILE or "DEFAULT"]
            or config.Profiles.DEFAULT
    end
    if type(profile) ~= "table" then
        return false
    end
    local migration = profile.fluxui_junk_detector
    if type(migration) == "table" and (tonumber(migration.version) or 0) >= 1 then
        return false
    end
    local previous = profile.junk_plugin
    profile.fluxui_junk_detector = { version = 1, previousPlugin = previous }
    if previous == "fluxui" then
        return false
    end
    profile.junk_plugin = "fluxui"
    -- Match Baganator's setting notification so cached icon callbacks and its
    -- ignored-plugin list agree with the saved profile before rebuilding bags.
    registry:TriggerEvent("SettingChanged", "junk_plugin")
    Compat.RequestBaganatorRefresh(true)
    return true
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

    Compat.ConfigureBaganatorJunkDetector()
    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if registry and registry.RegisterCallback then
        -- Also cover profiles selected later and configuration not ready at init.
        registry:RegisterCallback("BagShow", Compat.ConfigureBaganatorJunkDetector)
    end

    -- Only re-request Baganator widgets when Flux junk verdicts change.
    -- Bag moves already refresh via Syndicator → Baganator (plugin runs there).
    local fj = _G.FluxJunk
    if fj and fj.RegisterListChanged then
        fj.RegisterListChanged(ScheduleRefresh)
    end
    if fj and fj.RegisterVisualRefresh then
        -- Item data arriving can turn a previously unknown gray into junk
        -- without changing a manual list or moving any bag slots.
        fj.RegisterVisualRefresh(ScheduleRefresh)
    end
end
