-- Shared production counter and actual display subscriptions. Native secure VM,
-- rendering and the server's real bag-readiness timing require WoW verification.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local function slice(text, first, last)
    local a = assert(text:find(first, 1, true), first)
    return text:sub(a, assert(text:find(last, a + #first, true), last) - 1)
end
local core = read("Core/API/Container.lua")
local chat = slice(read("Other/FluxChatColumnMicros.lua"),
    "    local container = ns.Flux and ns.Flux.Container", "    -- Compatibility fallback")
local micro = slice(read("MicroMenu/FluxBagMicroButton.lua"),
    "    local function UpdateBagCount(totalFree)", "\nend\n\n-- Custom Styling for Bag Icon")
local header = slice(read("MicroMenu/FluxCombinedBagHeader.lua"),
    "if Flux and Flux.Container and Flux.Container.WatchFreeBagSlots then", 'watcher:RegisterEvent("ADDON_LOADED")')
local classic = slice(read("Inventory/Builtin/FluxClassicCombinedBag.lua"),
    "if Flux.Container and Flux.Container.WatchFreeBagSlots then", 'watcher:RegisterEvent("ADDON_LOADED")')
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function fixture(branch, body, timerless)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local state = { frames = {}, queue = {}, queries = 0, total = 3,
        free = { [0] = 3, 20, 21, 22, 23, 1000 }, combat = true }
    env.issecretvalue = function(v) return v == "secret" end
    env.NUM_BAG_SLOTS, env.ITEM_INVENTORY_BANK_BAG_OFFSET, env.REAGENTBAG_CONTAINER = 5, 4, 5
    env.C_Container = {
        CalculateTotalNumberOfFreeBagSlots = function()
            state.queries = state.queries + 1
            if state.total == "error" then error("temporary count API error") end
            return state.total
        end,
        GetContainerNumFreeSlots = function(bag)
            check(bag >= 0 and bag <= 4, branch .. ": count never touches bank/reagent/keyring")
            return state.free[bag]
        end,
    }
    local nativeTotal, nativeFree = env.C_Container.CalculateTotalNumberOfFreeBagSlots, env.C_Container.GetContainerNumFreeSlots
    env.Flux = { Client = { branch = branch }, Safecall = function(fn, ...) return pcall(fn, ...) end }
    env.InCombatLockdown = function() return state.combat end
    env.FluxInv = { RegisterListener = function() error("live HUD count waited on inventory snapshot") end }
    env.Inv = function() return env.FluxInv end
    env.HideBlizzardBags = function() end
    env.CreateFrame = function(kind)
        check(kind == "Frame", branch .. ": counter creates only an unprotected event frame")
        local r = { events = {}, scripts = {} }; state.frames[#state.frames + 1] = r
        function r:RegisterEvent(event) self.events[event] = true end
        function r:SetScript(event, callback)
            check(event ~= "OnUpdate", branch .. ": no idle polling")
            self.scripts[event] = callback
        end
        return r
    end
    if not timerless then env.C_Timer = { After = function(delay, callback)
        check(delay == 0, branch .. ": no arbitrary count delay")
        state.queue[#state.queue + 1] = callback
    end } else env.C_Timer = false end
    assert(load(body or core, "@production-container-api", "t", env))("_FluxUI", { Flux = env.Flux })
    local api = env.Flux.Container
    local function region()
        return { SetText = function(self, text) self.text = text; self.writes = (self.writes or 0) + 1 end,
            SetTextColor = function(self, r, g, b) self.color = { r, g, b } end }
    end
    local counters = { chat = region(), micro = region(), header = region(), classic = region() }
    env.FluxBagMicroButton = { count = { GetText = function() error("stale button text was copied") end } }
    env.count, env.btn = counters.chat, {}
    assert(load("local ns, count = ...\n" .. chat, "@actual-chat-counter-subscription", "t", env))({ Flux = env.Flux }, counters.chat)
    env.count = counters.micro
    env.GetTotalFreeBagSlots = api.GetTotalFreeBagSlots
    assert(load("local count = ...\n" .. micro, "@actual-micro-counter-subscription", "t", env))(counters.micro)
    env.liveButtons = { { kind = "backpack", Count = counters.header } }
    env.Off = function() return false end
    assert(load(header, "@actual-header-counter-subscription", "t", env))()
    env.ownedSlots = { { kind = "backpack", count = counters.classic } }
    env.UsesAltBag = function() return false end
    assert(load(classic, "@actual-classic-counter-subscription", "t", env))()
    function state.fire(event, unit)
        for _, frame in ipairs(state.frames) do
            if frame.events[event] then frame.scripts.OnEvent(frame, event, unit) end
        end
    end
    function state.flush()
        local queue = state.queue; state.queue = {}
        for _, callback in ipairs(queue) do callback() end
    end
    function state.equal(expected, message)
        for name, count in pairs(counters) do check(count.text == expected, branch .. ": " .. name .. " " .. message) end
    end
    return state, api, env, counters, nativeTotal, nativeFree
end
local function exercise(branch, body, timerless)
    local s, api, env, counters, nativeTotal, nativeFree = fixture(branch, body, timerless)
    s.equal(3, "can display the initial provisional backpack value")
    -- No inventory snapshot pulse, source-button refresh, reopened window or reload.
    s.total = 89
    s.fire("BAG_UPDATE_DELAYED"); s.flush()
    s.equal(89, "corrects backpack-only login when all ordinary bags arrive")
    check(counters.chat.color[1] == 1 and counters.chat.color[2] == 1, branch .. ": normal count color")
    local created, queries = #s.frames, s.queries
    s.fire("UNIT_INVENTORY_CHANGED", "target"); s.flush()
    check(s.queries == queries, branch .. ": unrelated unit inventory does not refresh")
    local writes = counters.chat.writes
    if not timerless then
        for _ = 1, 200 do s.fire("BAG_UPDATE") end
        check(#s.queue == 1, branch .. ": one pending callback for a bag event burst")
    end
    s.flush()
    check(counters.chat.writes == writes, branch .. ": unchanged total causes no display writes")
    check(#s.frames == created and #s.queue == 0, branch .. ": no accumulating frames or callbacks")
    for _, event in ipairs({ "BAG_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_ENTERING_WORLD", "UNIT_INVENTORY_CHANGED" }) do
        s.total = s.total - 1; s.fire(event, "player"); s.flush()
        s.equal(s.total, "updates after " .. event)
    end
    s.total = 4; s.fire("BAG_UPDATE_DELAYED"); s.flush(); s.equal(4, "reflects slot changes in combat")
    check(counters.chat.color[2] == .1 and counters.micro.color[2] == .1, branch .. ": low-space colors agree")
    s.total = 0; s.fire("BAG_UPDATE_DELAYED"); s.flush(); s.equal(0, "preserves a genuinely full bag total")
    local calls = 0
    api.WatchFreeBagSlots("late", function(total) calls = calls + 1; check(total == s.total, branch .. ": late view reads live total") end)
    check(calls == 1, branch .. ": late view initializes without waiting for an event")
    api.WatchFreeBagSlots("late", function() calls = calls + 10 end)
    s.total = 12; s.fire("BAG_UPDATE_DELAYED"); s.flush()
    check(calls == 21, branch .. ": duplicate registration replaces the prior callback")
    if not timerless then
        s.fire("BAG_UPDATE")
        api.WatchFreeBagSlots("late-ui", function() end)
        s.fire("BAG_UPDATE")
        check(#s.queue == 1, branch .. ": subscribing during a pending refresh does not duplicate callbacks")
        s.flush()
    end
    api.WatchFreeBagSlots("faulty-optional-consumer", function() error("isolated observer failure") end)
    s.total = 30; s.fire("BAG_UPDATE_DELAYED"); s.flush()
    s.equal(30, "still refreshes when another observer fails")
    check(env.C_Container.CalculateTotalNumberOfFreeBagSlots == nativeTotal and env.C_Container.GetContainerNumFreeSlots == nativeFree,
        branch .. ": native API ownership retained")
    env.C_Container.CalculateTotalNumberOfFreeBagSlots = nil
    check(api.GetTotalFreeBagSlots() == 89, branch .. ": fallback includes every ordinary bag, excludes reagent and bank")
    env.GetContainerNumFreeSlots = nativeFree; env.C_Container.GetContainerNumFreeSlots = nil
    check(api.GetTotalFreeBagSlots() == 89, branch .. ": legacy container API fallback agrees")
    env.C_Container.CalculateTotalNumberOfFreeBagSlots = nativeTotal
    for _, unavailable in ipairs({ "secret", "error" }) do
        s.total = unavailable
        check(api.GetTotalFreeBagSlots() == 89, branch .. ": unavailable native total uses readable carried counts")
    end
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    exercise(branch); exercise(branch, nil, true)
end
local function replace(old, new)
    local at = assert(core:find(old, 1, true), old)
    return core:sub(1, at - 1) .. new .. core:sub(at + #old)
end
local mutations = {
    { replace('"BAG_UPDATE_DELAYED",', '"UNUSED_EVENT",'), "corrects backpack-only login" },
    { replace('for bag = 0, last do', 'for bag = 0, 0 do'), "fallback includes every ordinary bag" },
    { replace('if freeSlotPending then return end', 'if false then return end'), "one pending callback" },
    { replace('if total == freeSlotLast then return end', 'if false then return end'), "unchanged total causes no display writes" },
}
for _, mutation in ipairs(mutations) do
    local ok, err = pcall(exercise, "classic_era", mutation[1])
    check(not ok and tostring(err):find(mutation[2], 1, true), "count regression rejected: " .. mutation[2])
end
print("shared bag counts: " .. checks .. " checks across five branches, native/legacy/timerless APIs; " .. #mutations .. " regressions rejected")
