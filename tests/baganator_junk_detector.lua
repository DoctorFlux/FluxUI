-- Exercise provider selection, persisted profiles and Baganator's cached routing.
-- Native items/rendering are not supplied by this desktop contract fixture.
local source = arg[1] or "BaganatorCompat/FluxBaganator_Junk.lua"
local checks, failures = 0, 0
local function check(value, message)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. message) end
end

local function boot(config, current, registryReady)
    local callbacks, plugins, events, refreshes = {}, {}, {}, {}
    local e = setmetatable({}, { __index = _G })
    e._G = e
    e.BAGANATOR_CONFIG, e.BAGANATOR_CURRENT_PROFILE = config, current
    local function profile()
        local data = e.BAGANATOR_CONFIG
        if not data then return nil end
        if data.Profiles then return data.Profiles[e.BAGANATOR_CURRENT_PROFILE or "DEFAULT"] or data.Profiles.DEFAULT end
        return data
    end
    local activeCallback
    local registry = {}
    function registry:RegisterCallback(event, fn)
        callbacks[event] = callbacks[event] or {}
        table.insert(callbacks[event], fn)
    end
    function registry:TriggerEvent(event, name)
        events[#events + 1] = { event, name }
        for _, fn in ipairs(callbacks[event] or {}) do fn(nil, name) end
    end
    -- Like Baganator ItemButtonUtil, hold the selected callback until notified.
    registry:RegisterCallback("SettingChanged", function(_, name)
        if name == "junk_plugin" then activeCallback = plugins[profile().junk_plugin] end
    end)
    local api = {
        RegisterJunkPlugin = function(_, id, fn) plugins[id] = fn end,
        RequestItemButtonsRefresh = function(reasons) refreshes[#refreshes + 1] = reasons end,
    }
    plugins.RXPGuides = function() return false end
    plugins.none = function() return false end
    plugins.poor_quality = function() return false end
    e.Baganator = { API = api, CallbackRegistry = registryReady ~= false and registry or nil,
        Constants = { RefreshReason = { ItemWidgets = 1, Searches = 2, Layout = 32 } } }
    local junk, protected = {}, {}
    e.FluxJunk = {
        IsJunkForDisplay = function(id) return junk[id] == true end,
        IsSlotProtectedFromSell = function(bag, slot) return protected[bag .. ":" .. slot] end,
        RegisterListChanged = function(fn) callbacks.listChanged = { fn } end,
        RegisterVisualRefresh = function(fn) callbacks.visualRefresh = { fn } end,
    }
    -- The selected detector may already have been cached before FluxUI loads.
    activeCallback = profile() and plugins[profile().junk_plugin]
    assert(loadfile(source, "t", e))()
    e.FluxBaganatorCompat.InitJunk()
    return { env = e, compat = e.FluxBaganatorCompat, registry = registry,
        plugins = plugins, events = events, refreshes = refreshes, junk = junk, protected = protected,
        display = function(id) return activeCallback and activeCallback(0, 1, id) == true or false end }
end

for _, client in ipairs({ "retail", "forever", "era", "anniversary", "mists" }) do
    for _, previous in ipairs({ "RXPGuides", "poor_quality", "none", "fluxui" }) do
        local saved = { junk_plugin = previous, icon_grey_junk = false, custom = { retained = true } }
        local other = { junk_plugin = "RXPGuides" }
        local config = { Profiles = { DEFAULT = saved, Other = other } }
        local t = boot(config, "DEFAULT")
        local label = client .. " " .. previous
        check(saved.junk_plugin == "fluxui", label .. " adopts FluxUI even with a valid selected detector")
        check(saved.fluxui_junk_detector and saved.fluxui_junk_detector.previousPlugin == previous,
            label .. " retains previous detector for recovery")
        check(not saved.icon_grey_junk and saved.custom.retained and not other.fluxui_junk_detector,
            label .. " keeps appearance, unrelated settings and inactive profiles")
        if previous ~= "fluxui" then
            check(#t.events == 1 and t.events[1][1] == "SettingChanged" and t.events[1][2] == "junk_plugin",
                label .. " invalidates Baganator cached detector through its setting event")
            local reasons = t.refreshes[1] or {}
            check(#t.refreshes == 1 and reasons[1] == 1 and reasons[2] == 2 and reasons[3] == 32,
                label .. " requests widgets, searches and category layout")
        else
            check(#t.events == 0 and #t.refreshes == 0, label .. " avoids rebuilding already-selected detector")
            -- Registration normally refreshes this through Baganator PluginsUpdated.
            t.registry:TriggerEvent("SettingChanged", "junk_plugin")
        end
        for i, kind in ipairs({ "food", "water", "bandage", "healPotion", "manaPotion" }) do
            t.junk[i] = true
            check(t.display(i), label .. " selected cached route displays inferior " .. kind)
            check(not t.display(i + 10), label .. " selected route retains best " .. kind)
        end
        t.protected["0:1"] = true
        check(not t.display(1), label .. " preserves slot protection")
        t.protected["0:1"] = nil
        local before = #t.refreshes
        for _ = 1, 100 do t.registry:TriggerEvent("BagShow") end
        t.compat.InitJunk()
        check(#t.refreshes == before, label .. " repeat opens/init do not rebuild or re-register")
        check(t.compat._junkInitialized == true, label .. " initialization is retained")
        -- A manual choice after migration must survive bag reopen and reload.
        saved.junk_plugin = "RXPGuides"
        t.registry:TriggerEvent("SettingChanged", "junk_plugin")
        t.registry:TriggerEvent("BagShow")
        local reloaded = boot(config, "DEFAULT")
        check(saved.junk_plugin == "RXPGuides" and not reloaded.display(1) and #reloaded.refreshes == 0,
            label .. " later manual choice survives reload without being forced back")
        -- Profiles selected later adopt independently through the existing BagShow.
        t.env.BAGANATOR_CURRENT_PROFILE = "Other"
        t.registry:TriggerEvent("BagShow")
        check(other.junk_plugin == "fluxui" and saved.junk_plugin == "RXPGuides",
            label .. " profile switch migrates only the newly active profile")
    end
end

do
    local t = boot(nil)
    check(#t.refreshes == 0, "missing config is deferred without creating saved roots")
    t.env.BAGANATOR_CONFIG = { Profiles = { DEFAULT = { junk_plugin = "RXPGuides" } } }
    t.registry:TriggerEvent("BagShow")
    check(t.env.BAGANATOR_CONFIG.Profiles.DEFAULT.junk_plugin == "fluxui", "late config retries on bag open")
end
do
    local config = { junk_plugin = "poor_quality" }
    local t = boot(config)
    check(config.junk_plugin == "fluxui", "legacy flat profile is supported")
    local before = #t.refreshes
    t.compat.RequestBaganatorRefresh()
    check(#t.refreshes == before + 1 and #t.refreshes[#t.refreshes] == 2, "layout migration does not contaminate ordinary refresh reasons")
end
do
    local config = { Profiles = {} }
    local t = boot(config)
    check(next(config.Profiles) == nil and #t.refreshes == 0, "missing active/default profile stays deferred")
end
do
    local saved = { junk_plugin = "RXPGuides" }
    local t = boot({ Profiles = { DEFAULT = saved } }, "DEFAULT", false)
    check(saved.junk_plugin == "RXPGuides" and not saved.fluxui_junk_detector,
        "unavailable setting notifications cannot leave a silently stale migrated detector")
end
do
    local saved = { junk_plugin = "none", fluxui_junk_detector = { version = 2, previousPlugin = "RXPGuides" } }
    local t = boot({ Profiles = { DEFAULT = saved } }, "missing")
    check(saved.junk_plugin == "none" and saved.fluxui_junk_detector.version == 2 and #t.refreshes == 0,
        "future migration versions and fallback DEFAULT preserve subsequent user choices")
end
do
    local e = { _G = {} }
    assert(loadfile(source, "t", e))()
    e.FluxBaganatorCompat.InitJunk()
    check(not e.FluxBaganatorCompat._junkInitialized, "absent optional Baganator does not initialize")
end

print(("Baganator junk detector: %d checks, %d failures; native icons/categories pending"):format(checks, failures))
if failures > 0 then os.exit(1) end
