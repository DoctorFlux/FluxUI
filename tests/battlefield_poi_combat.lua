-- Full Flux battlefield owner with modeled Blizzard frame and POI event delivery.
-- Counts verify ownership and replay. They do not represent the native taint VM.
local source = arg[1] or "Battlezonemap/FluxBattlefieldMap.lua"
local poiEvent = "AREA_POIS_UPDATED"
local restrictionEvent = "ADDON_RESTRICTION_STATE_CHANGED"
local combatType, inactive, activating, active = 0, 0, 1, 2
local checks = 0

local function check(ok, message)
    checks = checks + 1
    assert(ok, message)
end

local function fixture(client)
    local modern = client ~= "Classic"
    local s = {
        frames = {}, timers = {}, lockdown = false, restriction = inactive,
        mapID = 37, blocked = 0, acquisitions = 0, cvarEnables = 0, mapWrites = 0, restrictedShows = 0,
    }
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.SlashCmdList = {}
    env.InCombatLockdown = function() return s.lockdown end
    env.UnitAffectingCombat = function() return s.lockdown end
    env.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    env.C_AddOns = modern and { IsAddOnLoaded = function() return true end } or nil
    env.IsAddOnLoaded = function() return true end
    env.Enum = modern and {
        AddOnRestrictionType = { Combat = combatType },
        AddOnRestrictionState = { Inactive = inactive, Activating = activating, Active = active },
    } or nil
    env.C_RestrictedActions = modern and {
        GetAddOnRestrictionState = function() return s.restriction end,
        IsAddOnRestrictionActive = function() return s.restriction == active end,
    } or nil
    env.C_Map = { GetBestMapForUnit = function() return s.mapID end }
    env.SetCVar = function(key, value)
        if key == "showBattlefieldMinimap" and value == "1" then s.cvarEnables = s.cvarEnables + 1 end
    end
    env.table = setmetatable({ wipe = function(t) for k in pairs(t) do t[k] = nil end end }, { __index = table })
    env.wipe = env.table.wipe
    env.MapCanvasMixin = { OnShow = function() end }
    env.MapCanvasPinMixin = modern and { CheckMouseButtonPassthrough = function() end } or nil

    local frame = {}
    function frame:Show()
        if self.shown then return end
        self.shown = true
        if self.OnShow then self:OnShow() end
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function frame:Hide()
        if not self.shown then return end
        self.shown = false
        if self.OnHide then self:OnHide() end
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function frame:IsShown() return self.shown end
    frame.IsVisible = frame.IsShown
    function frame:GetParent() return self.parent end
    function frame:SetParent(parent) self.parent = parent end
    function frame:GetScale() return self.scale end
    function frame:SetScale(scale) self.scale = scale end
    function frame:GetFrameStrata() return self.strata end
    function frame:SetFrameStrata(strata) self.strata = strata end
    function frame:GetFrameLevel() return self.level end
    function frame:SetFrameLevel(level) self.level = level end
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:UnregisterEvent(event) self.events[event] = nil end
    function frame:UnregisterAllEvents() self.events = {} end
    function frame:IsEventRegistered(event) return self.events[event] == true end
    function frame:SetScript(key, fn) self.scripts[key] = fn end
    function frame:GetScript(key) return self.scripts[key] end
    local function hook(previous, callback)
        return function(...)
            if previous then previous(...) end
            callback(...)
        end
    end
    function frame:HookScript(key, fn) self.scripts[key] = hook(self.scripts[key], fn) end
    env.hooksecurefunc = function(owner, key, fn) owner[key] = hook(owner[key], fn) end
    local function noop() end
    frame.EnableMouse, frame.SetPropagateMouseClicks, frame.SetPropagateMouseMotion = noop, noop, noop
    frame.ClearAllPoints, frame.SetPoint, frame.SetAlpha = noop, noop, noop
    env.CreateFrame = function(_, _, parent)
        local object = setmetatable({ shown = false, events = {}, scripts = {}, scale = 1, parent = parent }, { __index = frame })
        s.frames[#s.frames + 1] = object
        return object
    end
    local parent = env.CreateFrame("Frame")
    env.UIParent = parent
    local map = env.CreateFrame("Frame", "BattlefieldMapFrame", parent)
    env.BattlefieldMapFrame = map
    map.mapID, map.dataProviderEventsCount = 37, {}
    map.dataProviders = { area = {}, timedArea = {} }
    function map:GetMapID() return self.mapID end
    function map:SetMapID(id)
        s.mapWrites = s.mapWrites + 1
        self.mapID = id
    end
    function env.MapCanvasMixin.OnShow(self)
        if modern and s.restriction ~= inactive then s.restrictedShows = s.restrictedShows + 1 end
        self.dataProviderEventsCount[poiEvent] = 2
        self:RegisterEvent(poiEvent)
    end
    function map:OnShow() env.MapCanvasMixin.OnShow(self) end
    function map:OnHide()
        self.dataProviderEventsCount[poiEvent] = nil
        self:UnregisterEvent(poiEvent)
    end
    function map:AcquirePin()
        s.acquisitions = s.acquisitions + 1
        if modern and s.restriction ~= inactive then
            -- Native pin acquisition runs propagation, then right-click passthrough.
            s.blocked = s.blocked + 2
        end
    end
    local deliveries, unrelated = 0, 0
    function map:OnEvent(event)
        if event == poiEvent then
            deliveries = deliveries + 1
            for _ in pairs(self.dataProviders) do self:AcquirePin() end
        else
            unrelated = unrelated + 1
        end
    end
    map:SetScript("OnEvent", function(self, event, ...) self:OnEvent(event, ...) end)
    map:RegisterEvent("UNRELATED_MAP_EVENT")
    local nativeEvent, nativeAcquire = map.OnEvent, map.AcquirePin
    local world = env.CreateFrame("Frame", "WorldMapFrame", parent)
    env.WorldMapFrame = world
    world:RegisterEvent(poiEvent)
    local worldEvents = 0
    world:SetScript("OnEvent", function() worldEvents = worldEvents + 1 end)

    local chunk
    if setfenv then
        chunk = setfenv(assert(loadfile(source)), env)
    else
        chunk = assert(loadfile(source, "t", env))
    end
    chunk("_FluxUI", {
        API = { isPostDF = modern, isV12 = modern },
        Flux = { Client = { isForever = client == "Forever", isRetail = client == "Retail" } },
    })
    local owner = env.FluxBattlefieldMap
    function s:Fire(event, ...)
        for _, object in ipairs(self.frames) do
            local fn = object:GetScript("OnEvent")
            if fn and object:IsEventRegistered(event) then fn(object, event, ...) end
        end
    end
    function s:Restriction(value)
        self.restriction = value
        self:Fire(restrictionEvent, combatType, value)
    end
    function s:Flush()
        for _ = 1, 20 do
            if #self.timers == 0 then return end
            local pending = self.timers
            self.timers = {}
            for _, fn in ipairs(pending) do fn() end
        end
        error("timer queue failed to settle")
    end
    function s:Embed()
        check(owner:Initialize(parent), client .. " initializes the existing native map")
        owner:Show()
        self:Flush()
    end
    function s:Counts() return deliveries, unrelated, worldEvents end
    function s:NativeMethodsRetained() return map.OnEvent == nativeEvent and map.AcquirePin == nativeAcquire end
    function s:ReplaceNativeFrame()
        local replacement = env.CreateFrame("Frame", "ReplacementBattlefieldMapFrame", env.UIParent)
        env.BattlefieldMapFrame = replacement
        replacement:RegisterEvent(poiEvent)
        return replacement
    end
    return s, map, owner
end

for _, client in ipairs({ "Retail", "Forever" }) do
    local s, map, owner = fixture(client)
    s:Embed()
    local nativeProviders = map.dataProviders
    check(map:IsEventRegistered(poiEvent) and map.dataProviderEventsCount[poiEvent] == 2,
        "ordinary native subscriptions are live")
    s:Fire(poiEvent)
    check(s:Counts() == 1, "normal POIs refresh immediately")

    s:Fire(restrictionEvent, 12, activating)
    check(map:IsEventRegistered(poiEvent), "unrelated restrictions leave the POI subscription")
    s:Restriction(activating)
    local heldBeforeLockdown = not s.lockdown and not map:IsEventRegistered(poiEvent) and map:IsShown()
    check(map.dataProviderEventsCount[poiEvent] == 2 and map.dataProviders == nativeProviders,
        "holding leaves both providers and their subscription counts")
    s.lockdown = true
    s:Restriction(active)
    s:Fire("PLAYER_REGEN_DISABLED")
    for _ = 1, 20 do s:Fire(poiEvent) end
    s:Fire("UNRELATED_MAP_EVENT")
    local count, unrelated, world = s:Counts()
    check(s.blocked == 0, ("restricted Area POI event attempted %d native mouse setter calls"):format(s.blocked))
    check(heldBeforeLockdown, "combat activation holds the embedded POI event before lockdown")
    check(count == 1 and unrelated == 1 and world == 21,
        "event bursts bypass native input setters on this map and still reach other handlers")

    s.lockdown = false
    s:Fire("PLAYER_REGEN_ENABLED")
    s:Flush()
    check(s:Counts() == 1 and not map:IsEventRegistered(poiEvent),
        "regen cannot replay while native combat restriction is active")
    s:Restriction(inactive)
    s:Fire("PLAYER_REGEN_ENABLED")
    s:Flush()
    check(map:IsEventRegistered(poiEvent) and s:Counts() == 2 and s.acquisitions == 4,
        "restriction release restores one native subscription and replays one missed event")
    check(s:NativeMethodsRetained(), "native event and acquisition methods remain owned by Blizzard")

    s:Restriction(activating)
    s:Restriction(inactive)
    s:Flush()
    check(s:Counts() == 2 and map:IsEventRegistered(poiEvent), "no missed update adds no replay")

    s:Restriction(activating)
    s:Fire(poiEvent)
    s:Restriction(inactive)
    s:Restriction(activating)
    s:Flush()
    check(s:Counts() == 2 and not map:IsEventRegistered(poiEvent) and s.blocked == 0,
        "combat reentry prevents a scheduled replay")
    s:Fire(poiEvent)
    s:Restriction(inactive)
    s:Flush()
    check(s:Counts() == 3 and map:IsEventRegistered(poiEvent),
        "the next release replays accumulated updates only once")

    s:Restriction(activating)
    s.lockdown = true
    s:Fire(poiEvent)
    owner:Hide()
    s.lockdown = false
    s:Restriction(inactive)
    s:Fire("PLAYER_REGEN_ENABLED")
    s:Flush()
    check(s:Counts() == 3 and not map:IsShown() and not map:IsEventRegistered(poiEvent),
        "hide drops pending work and lets native OnHide release both subscriptions")
    s:Embed()
    s:Fire(poiEvent)
    check(s:Counts() == 4 and map.dataProviderEventsCount[poiEvent] == 2,
        "a later embed receives its own native events without stale replay")

    s:Restriction(activating)
    s.mapID = 38
    local writes = s.mapWrites
    s:Fire("ZONE_CHANGED_NEW_AREA")
    s:Flush()
    check(map:GetMapID() == 37 and s.mapWrites == writes,
        "zone callbacks cannot request addon-driven native geometry before restriction release")
    s:Restriction(inactive)
    s:Flush()
    check(map:GetMapID() == 38, "restriction release applies the current display map")

    s:Restriction(activating)
    s:Fire(poiEvent)
    local replacement = s:ReplaceNativeFrame()
    s:Restriction(inactive)
    s:Flush()
    check(s:Counts() == 4 and not map:IsEventRegistered(poiEvent) and replacement:IsEventRegistered(poiEvent),
        "a pending event neither reattaches a replaced map nor changes the replacement")

    local late, hidden = fixture(client)
    late:Restriction(activating)
    late:Embed()
    check(not hidden:IsVisible() and late.restrictedShows == 0 and late.cvarEnables == 0,
        "an explicit embed during restriction holds the native show and enable CVar")
    late:Fire("PLAYER_REGEN_ENABLED")
    late:Flush()
    check(not hidden:IsVisible() and late.cvarEnables == 0,
        "early regen alone cannot expose a deferred map")
    late:Restriction(inactive)
    late:Flush()
    check(hidden:IsVisible() and hidden:IsEventRegistered(poiEvent) and late.cvarEnables == 1,
        "the first safe wake completes the deferred embed once")
end

local classic, oldMap = fixture("Classic")
classic:Embed()
classic.lockdown = true
classic:Fire("PLAYER_REGEN_DISABLED")
classic:Fire(poiEvent)
check(oldMap:IsEventRegistered(poiEvent) and classic:Counts() == 1,
    "legacy map receives native POI updates during combat")

print(("Battlefield POI combat: %d checks passed"):format(checks))
