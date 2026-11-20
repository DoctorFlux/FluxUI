-- Complete Events owner in explicit frame mocks; no native or timing claim.
local owner = arg[1] or "ExtraButtonSystem/Engine/Events.lua"
local checks = 0
local function check(ok, message)
    checks = checks + 1
    assert(ok, message)
end

local methods = { "UpdateTexture", "UpdateChecked", "UpdateEquipped", "UpdateCooldown", "UpdateTextCount", "RefreshSpell" }
local flags = { "RefChecked", "RefEquipped", "RefCooldown", "RefText", "RefSpells" }
local keys = { "tex", "chk", "eq", "cd", "txt", "spl" }

local function boot(legacy)
    local s = { frames = {}, trace = {}, timers = {}, listeners = {} }
    local env = setmetatable({}, { __index = _G })
    env._G, env.FLUX_API = env, { isLegacyClient = legacy }
    env.GetTime = function() return 10 end
    env.GetBuildInfo = function() return "3.4.0", "12340", "", 30400 end
    env.InCombatLockdown = function() return false end
    env.UnitExists = function() return false end
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end; return t end
    env.C_Timer = {
        After = function(delay, fn) s.timers[#s.timers + 1] = { delay, fn } end,
        NewTimer = function(delay, fn)
            local timer = { delay, fn }
            function timer:Cancel() self.cancelled = true end
            s.timers[#s.timers + 1] = timer
            return timer
        end,
    }
    env.FluxInv = { RegisterListener = function(key, fn) s.listeners[key] = fn end }
    env.CreateFrame = function(kind)
        assert(kind == "Frame" or kind == "FRAME", "unexpected frame type")
        local f = { scripts = {}, events = {}, shown = true }
        function f:SetScript(key, fn) self.scripts[key] = fn end
        function f:GetScript(key) return self.scripts[key] end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:RegisterUnitEvent(event, unit) self.events[event] = unit end
        function f:SetFrameStrata(value) self.strata = value end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        s.frames[#s.frames + 1] = f
        return f
    end
    local chunk
    if setfenv then chunk = assert(loadfile(owner)); setfenv(chunk, env)
    else chunk = assert(loadfile(owner, "t", env)) end
    chunk("_FluxUI", {})
    s.env, s.events = env, assert(env.FluxButtonEvents)
    function s:emit(event, unit)
        for _, frame in ipairs(self.frames) do
            local registration = frame.events[event]
            if registration and (registration == true or registration == unit) and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame, event, unit)
            end
        end
    end
    function s:runTimers()
        local timers = self.timers; self.timers = {}
        for _, timer in ipairs(timers) do if not timer.cancelled then timer[2]() end end
    end
    return s
end

local function button(s, id)
    local b = { ActionType = "spell", ActionValue = id, Widget = { IsShown = function() return true end } }
    for _, name in ipairs(methods) do
        local method = name
        b[method] = function(self)
            assert(self == b, "method receiver")
            s.trace[#s.trace + 1] = method .. ":" .. id
        end
    end
    b.UpdateUsable = function(self)
        assert(self == b, "usable method receiver")
        s.trace[#s.trace + 1] = "UpdateUsable:" .. id
    end
    return b
end

local function arm(full)
    full.RefreshButtons = true
    for _, flag in ipairs(flags) do full[flag] = true end
    full:SetScript("OnUpdate", full.OnUpdate)
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    s.events.ActiveButtons = { button(s, 1) }
    s.listeners.EngineBagRefresh({ changeKind = "countOnly" }); s:emit("SPELLS_CHANGED")
    assert(full:GetScript("OnUpdate"))(full, 0.01)
    check(table.concat(s.trace, ",") == "UpdateTexture:1,UpdateUsable:1,UpdateTextCount:1,RefreshSpell:1", "later spell request must restore the general texture pass; actual=" .. table.concat(s.trace, ","))
    check(not full.RefreshButtons, "promoted spell request completes")
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    s.events.ActiveButtons = { button(s, 1) }
    s.listeners.EngineBagRefresh({ changeKind = "countOnly" }); s:emit("PLAYER_EQUIPMENT_CHANGED")
    check(#s.timers == 1 and s.timers[1][1] == 0.15, "actual equipment event retains its debounce")
    s:runTimers(); assert(full:GetScript("OnUpdate"))(full, 0.01)
    check(table.concat(s.trace, ",") == "UpdateEquipped:1,UpdateUsable:1,UpdateTextCount:1", "equipment-only refresh retains its existing intentional texture skip")
    check(not full.RefreshButtons, "merged equipment request completes")
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    s.events.ActiveButtons = { button(s, 1) }
    s.listeners.EngineBagRefresh({ changeKind = "countOnly" })
    s.listeners.EngineBagRefresh({ changeKind = "identityChanged" })
    assert(full:GetScript("OnUpdate"))(full, 0.01)
    check(table.concat(s.trace, ",") == "UpdateTexture:1,UpdateChecked:1,UpdateUsable:1,UpdateTextCount:1", "later inventory identity refresh restores textures")
    check(not full.RefreshButtons, "promoted identity request completes")
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    s.events.ActiveButtons = { button(s, 1) }
    s.listeners.EngineBagRefresh({ changeKind = "countOnly" }); s.events.ForceRefresh()
    assert(full:GetScript("OnUpdate"))(full, 0.01)
    check(table.concat(s.trace, ",") == "UpdateTexture:1,UpdateChecked:1,UpdateEquipped:1,UpdateUsable:1,UpdateCooldown:1,UpdateTextCount:1", "explicit full refresh restores textures and its actual requested flags; actual=" .. table.concat(s.trace, ","))
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    s.events.ActiveButtons = { button(s, 1) }
    s.listeners.EngineBagRefresh({ changeKind = "countOnly" })
    s.events.BeginFormStorm(0.55); s:emit("SPELLS_CHANGED")
    assert(full:GetScript("OnUpdate"))(full, 0.01)
    check(table.concat(s.trace, ",") == "UpdateUsable:1,UpdateTextCount:1", "form-storm rejected spell request retains intentional texture skip")
end

for _, sessionClose in ipairs({ false, true }) do
    local s = boot(false); local full = s.events.EventFrames.Full
    s.events.ActiveButtons = { button(s, 1) }
    assert(s.listeners.EngineBagRefresh)({ changeKind = "countOnly", sessionClose = sessionClose })
    local flush = assert(full:GetScript("OnUpdate"), "dispatcher scheduled update")
    flush(full, 0.01)
    check(table.concat(s.trace, ",") == "UpdateUsable:1,UpdateTextCount:1", "inactive count-only dispatcher must actually refresh usable/text without textures; actual=" .. table.concat(s.trace, ","))
    check(not full.RefreshButtons and full:GetScript("OnUpdate") == nil, "count-only dispatcher completes and disarms")
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    s.events.ActiveButtons = { button(s, 1) }
    full.RefreshButtons, full.RefEquipped = true, true
    s.listeners.EngineBagRefresh({ changeKind = "countOnly" })
    assert(full:GetScript("OnUpdate"))(full, 0.01)
    check(table.concat(s.trace, ",") == "UpdateTexture:1,UpdateEquipped:1,UpdateUsable:1,UpdateTextCount:1", "count-only merge preserves wider pending texture/equipment work")
    check(not full.RefreshButtons and full:GetScript("OnUpdate") == nil, "merged wider dispatcher finishes and disarms")
end

do
    local s = boot(false)
    local full = assert(s.events.EventFrames.Full)
    for i = 1, 35 do s.events.ActiveButtons[i] = button(s, i) end
    local hidden = button(s, 36); hidden.Widget.IsShown = function() return false end
    s.events.ActiveButtons[36], s.events.ActiveButtons[37] = hidden, {}
    arm(full)
    full:OnUpdate(0.01)
    check(#s.trace == 32 * 6, "each stateless pass keeps its 32 eligible button budget")
    for i, key in ipairs(keys) do
        check(full._batchCursor[key] == 33, "cursor retained for " .. key)
        check(s.trace[(i - 1) * 32 + 1] == methods[i] .. ":1", "pass order begins " .. key)
        check(s.trace[i * 32] == methods[i] .. ":32", "pass order ends " .. key)
    end
    check(full.RefreshButtons and full:GetScript("OnUpdate") ~= nil, "incomplete work remains armed")
    full:OnUpdate(0.01)
    check(#s.trace == 35 * 6, "remaining three buttons finish without hidden or empty work")
    for i = 1, 6 do
        check(s.trace[192 + (i - 1) * 3 + 1] == methods[i] .. ":33", "second tick resumes pass order")
    end
    check(not full.RefreshButtons and full:GetScript("OnUpdate") == nil, "completed flush disarms")
    check(next(full._batchCursor) == nil and not full.RefSkipTexture, "completed cursors and texture flag clear")
    for _, flag in ipairs(flags) do check(not full[flag], "completed " .. flag .. " clears") end
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    local bad, good = button(s, 1), button(s, 2)
    local opaque = {}
    for _, name in ipairs(methods) do
        local method = name
        bad[method] = function() s.trace[#s.trace + 1] = method .. ":1"; error(opaque, 0) end
    end
    s.events.ActiveButtons = { bad, good }; arm(full); full:OnUpdate(0.01)
    check(#s.trace == 12, "protected errors do not prevent later methods/buttons")
    for i, method in ipairs(methods) do
        check(s.trace[i * 2 - 1] == method .. ":1" and s.trace[i * 2] == method .. ":2", "error continuation order")
    end
    check(not full.RefreshButtons, "error-containing flush still completes")
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    local lookups, calls = {}, {}
    local known = {}; for _, method in ipairs(methods) do known[method] = true end
    local b = { ActionType = "spell", ActionValue = 1, Widget = { IsShown = function() return true end } }
    setmetatable(b, { __index = function(_, key)
        if not known[key] then return nil end
        lookups[key] = (lookups[key] or 0) + 1
        local selected = lookups[key]
        return function(self) assert(self == b); calls[#calls + 1] = key .. ":" .. selected end
    end })
    s.events.ActiveButtons = { b }; arm(full); full:OnUpdate(0.01)
    for i, method in ipairs(methods) do
        check(lookups[method] == 2 and calls[i] == method .. ":2", "dynamic second method lookup retained")
    end
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    local first, second = button(s, 1), button(s, 2)
    local nested = false
    first.UpdateTexture = function()
        s.trace[#s.trace + 1] = "UpdateTexture:1"
        if not nested then nested = true; full.RefChecked = true; full:OnUpdate(0.01) end
    end
    s.events.ActiveButtons = { first, second }; full.RefreshButtons = true
    full:SetScript("OnUpdate", full.OnUpdate); full:OnUpdate(0.01)
    check(table.concat(s.trace, ",") == "UpdateTexture:1,UpdateTexture:1,UpdateTexture:2,UpdateChecked:1,UpdateChecked:2,UpdateTexture:2", "nested refresh keeps established call order")
    check(not full.RefreshButtons and next(full._batchCursor) == nil, "nested refresh leaves no cursor backlog")
end

do
    local s = boot(false); local full = s.events.EventFrames.Full
    local item, spell = button(s, 1), button(s, 2); item.ActionType = "item"
    s.events.ActiveButtons = { item, spell }; s.events._deferredUsablePowerSettle = true
    full.RefreshButtons, full.RefSkipTexture, full.RefUsable = true, true, true
    full:OnUpdate(0.01)
    check(table.concat(s.trace, ",") == "UpdateUsable:2", "captured power-settle callback still skips item usable work")
    s.trace = {}; s.events.ActiveButtons = { spell }; s:emit("UNIT_SPELLCAST_INTERRUPTED", "player")
    check(full.RefreshButtons and full.RefChecked, "actual interrupt event arms checked refresh")
    full:OnUpdate(0.01)
    check(table.concat(s.trace, ",") == "UpdateTexture:2,UpdateChecked:2", "interrupt event preserves texture/checked order")
end

do
    local s = boot(true); local legacy = assert(s.env.FluxButtonLegacySystem)
    legacy.ActiveButtons[1] = button(s, 1)
    s:emit("BAG_UPDATE_DELAYED")
    local updater
    for _, frame in ipairs(s.frames) do if frame:GetScript("OnUpdate") then assert(not updater); updater = frame end end
    check(updater ~= nil, "actual legacy bag event arms one updater")
    local first = updater:GetScript("OnUpdate")
    s:emit("BAG_UPDATE_DELAYED")
    check(updater:GetScript("OnUpdate") == first, "legacy requests coalesce while armed")
    first(updater, 0.01)
    check(table.concat(s.trace, ",") == "UpdateTexture:1,UpdateUsable:1,UpdateTextCount:1", "legacy delayed-bag branch retains existing lookup/effect order")
    check(updater:GetScript("OnUpdate") == nil, "legacy processing disarms")
    s:emit("TRADE_SKILL_CLOSE")
    check(updater:GetScript("OnUpdate") == first, "later legacy activation reuses the same private Process")
    s.trace = {}; first(updater, 0.01)
    check(table.concat(s.trace, ",") == "UpdateTexture:1,UpdateChecked:1,UpdateTextCount:1", "legacy craft-close flags retain method order")
end

print("EBS event batch workers: " .. checks .. " checks PASS; full owner, frame mocks; no native/FPS claim")
