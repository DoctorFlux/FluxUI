-- Actual HBD router + tooltip bridge; native frame/security behavior is modeled.
-- Lifecycle and operation counts do not establish native taint, pixels or FPS.
local fixtureEnv = setmetatable({
    arg = { [0] = "Battlezonemap/_tmp_questiepinsmoke.lua", [1] = "--fixture" },
}, { __index = _G })
local Runtime = assert(loadfile("Battlezonemap/_tmp_questiepinsmoke.lua", "t", fixtureEnv))()
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end

for _, client in ipairs({ "retail", "forever", "classic", "legacy" }) do
    local r = Runtime(client == "forever", client ~= "legacy")
    local q, stock = r.questie, r.stock
    local acquire, register = r.battlefield.AcquirePin, r.battlefield.RegisterPin
    check(r.router:Install(), client .. ": optional HBD bridge installs")
    r.Drain()
    local nativeRegister = r.battlefield.RegisterPin
    for visit = 1, 50 do
        check(r.router:IsHBDAvailable(), client .. ": known libraries discovered")
        local icons = {}
        for _, lib in ipairs({ q, stock }) do
            local icon = r.Frame(r.env.UIParent)
            lib:AddWorldMapIconMap(r, icon, 10, .25, .75)
            check(icon:IsVisible() and icon:GetParent().owningMap == r.battlefield,
                client .. ": each library owns its visible battlefield pin")
            icons[#icons + 1] = icon
        end
        local calls = r.metrics.removalHookCalls
        q:RemoveWorldMapIcon(r, icons[1]); stock:RemoveWorldMapIcon(r, icons[2])
        check(r.metrics.removalHooks == 2 and r.metrics.removalHookCalls == calls + 2,
            client .. ": removal stays one callback per library across map visits")
        check(not icons[1]:IsShown() and not icons[2]:IsShown(), client .. ": removal releases current route")
        r.SetEnabled(false); r.router:Uninstall(); r.Drain()
        check(count(r.battlefield.dataProviders) == 0, client .. ": inactive map retains no HBD providers")
        check(r.battlefield.AcquirePin == acquire and r.battlefield.RegisterPin == nativeRegister,
            client .. ": acquisition/registration never acquire extra hooks")
        if client ~= "legacy" then check(nativeRegister == register, client .. ": native registration untouched") end
        local inactive = r.Frame(r.env.UIParent)
        stock:AddWorldMapIconMap(r, inactive, 10, .1, .2)
        stock:RemoveWorldMapIcon(r, inactive)
        check(count(r.battlefield.pins) == 0, client .. ": parked hooks do not revive old pins")
        r.SetEnabled(true); check(r.router:Install(), client .. ": map route reinstalls"); r.Drain()
    end
    -- Invalidated next-frame callbacks cannot paint a hidden/toggled-off map.
    r.router:RequestRefresh(); r.router:ScheduleKickstart()
    local before = r.metrics.acquisitions
    r.SetEnabled(false); r.router:Uninstall(); r.Drain()
    check(r.metrics.acquisitions == before, client .. ": queued work cancels on disable")
end

-- No optional addon or library becomes a hard dependency, and an independently
-- late standard HBD library is discovered while Questie already has a route.
local empty = Runtime(false, true)
empty.SetAvailable(false); empty.SetStockAvailable(false)
check(empty.router:Install(), "no-library client still installs without a dependency")
empty.router:ScheduleKickstart(); empty.Drain()
check(not empty.router:IsHBDAvailable() and count(empty.battlefield.dataProviders) == 0,
    "absent addons leave the battlefield providers alone")
empty.SetStockAvailable(true); empty.Event("ADDON_LOADED", "SomeFutureMapAddon"); empty.Drain()
local icon = empty.Frame(empty.env.UIParent)
empty.stock:AddWorldMapIconMap(empty, icon, 10, .3, .4)
check(icon:IsVisible() and icon:GetParent().owningMap == empty.battlefield,
    "discovery uses the library contract rather than addon names")

-- Each new icon is O(1): no full-pool enumeration, full-library redraw, or
-- timer follows incremental inserts even at the larger synthetic load.
for _, size in ipairs({ 1000, 2000 }) do
    local r = Runtime(false, true); check(r.router:Install(), "modern performance route installs"); r.Drain()
    local before = { visits = r.metrics.visits, refreshes = r.metrics.refreshes, acquired = r.metrics.acquisitions }
    for i = 1, size do
        local lib = i % 2 == 0 and r.questie or r.stock
        lib:AddWorldMapIconMap(r, r.Frame(r.env.UIParent), 10, .2, .7)
    end
    check(r.metrics.visits == before.visits and r.metrics.refreshes == before.refreshes
        and r.metrics.acquisitions - before.acquired == size, "linear incremental work at " .. size .. " pins")
    local refreshes = r.metrics.refreshes
    for _ = 1, 100 do r.router:RequestRefresh() end
    check(r.metrics.refreshes == refreshes, "refresh bursts stay asynchronous")
    r.Drain(); check(r.metrics.refreshes == refreshes + 2, "one coalesced redraw per library")
end
print("HBD all-client bridge: " .. checks .. " checks PASS; 50 toggles retain 2 hooks; 1000/2000 inserts have zero scans/redraws")
