-- lua ExtraButtonSystem/NonCombatGrid/Buttons/_tmp_mountitemsmoke.lua
-- Real mount-item bag list, favorites cache, async wakeup and secure deferral.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../../../"
local checks = 0
local function eq(a, b, label)
    checks = checks + 1
    assert(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local function boot(modern)
    local s = { now = 10, frames = {}, timers = {}, loaded = {}, static = {}, loads = 0, updates = 0, combat = false }
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.GetTime = function() return s.now end
    env.InCombatLockdown = function() return s.combat end
    env.CreateFrame = function()
        local f = { events = {} }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:SetScript(_, fn) self.onEvent = fn end
        s.frames[#s.frames + 1] = f; return f
    end
    env.C_Timer = { After = function(delay, fn) s.timers[#s.timers + 1] = { at = s.now + delay, fn = fn } end }
    function s:advance(seconds)
        self.now = self.now + seconds
        local due = self.timers; self.timers = {}
        for _, t in ipairs(due) do
            if t.at <= self.now then t.fn() else self.timers[#self.timers + 1] = t end
        end
    end
    function s:event(event, id, success)
        for _, f in ipairs(self.frames) do if f.events[event] then f.onEvent(f, event, id, success) end end
    end
    local unique = { [5656] = { bag = 0, slot = 1 }, [5655] = { bag = 0, slot = 2 }, [123] = { bag = 0, slot = 3 } }
    env.Flux = { Inventory = { GetUniqueItems = function() return unique end, GetBagGeneration = function() return 1 end } }
    env.FluxNCMount = { _registered = true, Update = function() assert(not s.combat); s.updates = s.updates + 1 end }
    local function instant(id)
        if id == 123 then return id, "Trade Goods", "Cloth", "", 1, 7, 0 end
        if s.static[id] then return id, "Miscellaneous", "Mount", "", 2, 15, 5 end
    end
    local function info(id)
        if s.loaded[id] then return "Mount " .. id, "item:" .. id, 1, 1, 1, "Miscellaneous", "Mount", 1, "", 2 end
    end
    env.GetItemInfo = info; env.GetItemIcon = function() return 2 end
    if modern then env.C_Item = { GetItemInfoInstant = instant, GetItemInfo = info }
    else env.GetItemInfoInstant = instant end
    env.FluxItemClass = { RequestLoad = function() s.loads = s.loads + 1 end,
        GetTooltipText = function(id) assert(id ~= 123, "known trade goods should not need tooltips"); return "" end }
    local f = assert(io.open(root .. "ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua"))
    local source = f:read("*a"); f:close()
    local chunk
    if setfenv then chunk = assert(loadstring(source)); setfenv(chunk, env)
    else chunk = assert(load(source, "MountItems", "t", env)) end
    s.items = chunk(); s.module = env.FluxNCMount; s.env = env; return s
end
for _, modern in ipairs({ false, true }) do
    local s = boot(modern)
    eq(s.items.GetBestAvailableMount(), nil, "cold bag does not invent mounts")
    eq(s.loads, 2, "unknown bag items request data once")
    s.items.InvalidateCache(); s.items.GetBagMountItems()
    eq(s.loads, 2, "repeated scans coalesce requests")
    s:event("ITEM_DATA_LOAD_RESULT", 5656, false); s:advance(0.2)
    eq(s.updates, 0, "failed load does not wake refresh")
    s.static[5656], s.static[5655] = true, true
    s.loaded[5656], s.loaded[5655] = true, true
    s:event("GET_ITEM_INFO_RECEIVED", 5656, true)
    s:event("ITEM_DATA_LOAD_RESULT", 5656, true)
    s:event("GET_ITEM_INFO_RECEIVED", 5655, true)
    s:advance(0.2)
    eq(s.updates, 1, "late item data coalesces to one mount refresh")
    eq(#s.items.GetBagMountItems(), 2, "late data invalidates empty mount list")
    eq(s.items.GetBestAvailableMount() ~= nil, true, "late data invalidates empty favorites")
    s:event("GET_ITEM_INFO_RECEIVED", 123, true); s:advance(0.2)
    eq(s.updates, 1, "unrelated data does no mount work")
    -- Static mount ID is usable before its display name has arrived.
    local c = boot(modern); c.static[5656], c.static[5655] = true, true
    eq(#c.items.GetBagMountItems(), 2, "known mounts retained during cold name lookup")
    c.combat = true; c.loaded[5656], c.loaded[5655] = true, true
    c:event("ITEM_DATA_LOAD_RESULT", 5656, true); c:advance(0.2)
    eq(c.updates, 0, "no secure update in combat")
    eq(c.module._pendingUpdate, true, "combat recovery owed on regen")
    eq(c.items.GetBagMountItems()[1]["$name"]:match("^Mount ") ~= nil, true, "name cache refreshed in combat")
end
-- Execute the real riding-skill cache and inventory listener together. A cold
-- skill scan must not conceal an owned mount for the 60-second cache lifetime.
do
    local s = boot(false); local env = s.env
    local file = assert(io.open(root .. "ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua"))
    local source = file:read("*a"); file:close()
    local function slice(first, last)
        local a = assert(source:find(first, 1, true))
        local b = assert(source:find(last, a + #first, true))
        return source:sub(a, b - 1)
    end
    local function run(body)
        local chunk
        if setfenv then chunk = assert(loadstring(body)); setfenv(chunk, env)
        else chunk = assert(load(body, "mount login", "t", env)) end
        chunk()
    end
    env.Module = s.module
    env.UnitClass = function() return "Mage", "MAGE" end
    env.GetNumSkillLines = function() return s.ridingReady and 1 or 0 end
    env.GetSkillLineInfo = function() return "Riding" end
    run(slice("local ridingSkillCache = nil", "-- Get collected mount by name"))
    eq(s.module.HasRidingSkill(), false, "cold skill table initially empty")
    s.ridingReady = true
    eq(s.module.HasRidingSkill(), false, "fixture reproduces cached negative riding result")
    env.FluxInv = { RegisterListener = function(_, fn) s.listener = fn end }
    env.InvalidateAllMountItemCaches = function() s.items.InvalidateCache() end
    env.HasMountUI = function() return false end
    s.module.InvalidateCollectedMountCache = function() end
    s.module.Update = function() s.updates = s.updates + 1; s.visible = s.module.HasRidingSkill() end
    run(slice("-- FluxInv is the bag SoT", "if FluxBagChangeDispatcher and FluxBagChangeDispatcher.Register then"))
    s.listener({ changeKind = "countOnly", tier = "scan", recovery = true })
    s:advance(0.2)
    eq(s.updates, 1, "unchanged bags still refresh mount after readiness")
    eq(s.visible, true, "ready skill data restores real mount button immediately")
    s.combat = true
    s.listener({ changeKind = "countOnly", tier = "scan", recovery = true })
    s:advance(0.2)
    eq(s.updates, 1, "mount recovery respects combat lockdown")
    eq(s.module._pendingUpdate, true, "mount refresh remains owed after combat")
end
print("Mount item smoke passed: " .. checks .. " checks")
