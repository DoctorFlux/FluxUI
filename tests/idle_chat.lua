-- Actual chat-button handlers, with native-like uncancellable After callbacks.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function read(path)
    local f = assert(io.open(root .. path, "rb"))
    local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local source = read("Other/FluxChatColumnMicros.lua")
local checks, mutants = 0, 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function section(text, first, last)
    local a = assert(text:find(first, 1, true), first)
    return text:sub(a, assert(text:find(last, a + #first, true), last) - 1)
end
local function replace(text, old, new)
    local a = assert(text:find(old, 1, true), old)
    return text:sub(1, a - 1) .. new .. text:sub(a + #old)
end
local function bags(body, nativeTimer)
    local now, queue, reads, created, maximum, sourceValue, copied = 0, {}, 0, 0, 0, 0, 0
    local events
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.GetTime = function() return now end
    env.CreateFrame = function()
        events = { RegisterEvent = function() end, SetScript = function(self, _, fn) self.event = fn end }
        return events
    end
    if nativeTimer ~= false then
        env.C_Timer = { After = function(delay, callback)
            created = created + 1; queue[#queue + 1] = { at = now + delay, fn = callback }
            maximum = math.max(maximum, #queue)
            -- Native C_Timer.After intentionally returns nil.
        end }
    else env.C_Timer = false end
    env.SyncCount = function() reads = reads + 1; copied = sourceValue end
    assert(load(body, "@actual-chat-bag-handler", "t", env))()
    local function advance(to)
        while true do
            local index, soon
            for i, timer in ipairs(queue) do if timer.at <= to and (not soon or timer.at < soon) then index, soon = i, timer.at end end
            if not index then break end
            local timer = table.remove(queue, index); now = soon; timer.fn()
        end
        now = to
    end
    return { event = function() events.event() end, advance = advance,
        source = function(value) sourceValue = value end, copied = function() return copied end,
        stats = function() return reads, created, maximum, #queue end }
end
local bagBody = section(source, "    -- C_Timer.After has no cancellation handle.", "    SyncCount()\n    return btn")
local function bagChecks(body)
    local b = bags(body)
    for i = 0, 199 do b.advance(i * .001); b.event() end
    local reads, _, maximum = b.stats()
    check(reads == 0, "burst does not refresh before its scheduled update")
    check(maximum == 1, "only one outstanding bag callback")
    b.advance(.201)
    local result, callbacks, _, pending = b.stats()
    check(result == 1, "one bag refresh within 0.2s of the first event")
    b.advance(.35); b.source(77); b.advance(.401)
    result, callbacks, _, pending = b.stats()
    check(result == 2 and callbacks == 2 and pending == 0 and b.copied() == 77,
        "trailing refresh includes the source counter's delayed update")
    b.advance(60)
    check(b.stats() == 2, "no idle bag callbacks")
    b.event(); b.advance(60.201)
    check(b.stats() == 3, "subsequent bag burst remains usable")
    for i = 1, 1000 do b.advance(61 + i * .001); b.event() end
    b.advance(62.201)
    check(b.stats() >= 8 and b.stats() <= 10, "continuous events keep bag count responsive")
    local immediate = bags(body, false); immediate.event()
    check(immediate.stats() == 1, "timerless bag updates remain immediate")
    return callbacks
end
local callbacks = bagChecks(bagBody)
local old = bags(read("tests/fixtures/idle_chat_bag_before.txt"))
for i = 0, 199 do old.advance(i * .001); old.event() end
old.advance(1)
local oldReads, oldCallbacks = old.stats()
check(oldReads == 200 and oldCallbacks == 200, "retained handler reproduces uncancellable callback accumulation")

local pressBody = section(source, "local function CharacterPanelShown()", "local function WatchCharacterFrame(btn)")
local portraitBody = section(source, "local function ApplyPortrait(btn)", "local function CharacterPanelShown()")
local function pressChecks(body, portrait, baseline, legacy)
    local writes, shown, held, over, combat, watch = 0, false, false, false, false
    local visible, created = true, 0
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.InCombatLockdown = function() return combat end
    env.CharacterFrame = { IsShown = function() return shown end }
    env.IsMouseButtonDown = function() return held end
    env.CreateFrame = function()
        created = created + 1
        watch = { SetScript = function(self, _, fn) self.update = fn end }; return watch
    end
    env.SetPortraitTexture = function() end
    local function region()
        return {
            SetAlpha = function(self, value) assert(not combat, "protected alpha write"); writes = writes + 1; self.alpha = value end,
            ClearAllPoints = function() assert(not combat, "protected anchor write"); writes = writes + 1 end,
            SetPoint = function() writes = writes + 1 end,
            SetAllPoints = function() writes = writes + 1 end,
            SetShown = function(self, value) writes = writes + 1; self.shown = value end,
            SetDrawLayer = function() writes = writes + 1 end,
            SetTexCoord = function(self, ...) self.coords = { ... }; writes = writes + 1 end,
        }
    end
    local btn = { icon = region(), _fluxBg = region(), _fluxDownLatch = region(),
        _fluxPortraitMask = region(), _fluxPushedShadow = region(), _fluxPortraitGlow = region(),
        IsProtected = function() return true end, IsShown = function() return visible end,
        IsMouseOver = function() return over end }
    if legacy then
        btn._fluxBg, btn._fluxDownLatch = nil, nil
        btn._fluxPortraitMask, btn._fluxPushedShadow, btn._fluxPortraitGlow = nil, nil, nil
    end
    local track, refresh = assert(load(portrait .. body .. "\nreturn TrackCharacterPress, ApplyPortrait", "@actual-chat-press-handler", "t", env))()
    track(btn); track(btn)
    check(created == 1, "press tracking registers only once")
    watch.update(); check(btn._fluxPlatePushed == false, "initial resting appearance reconciles")
    local hiddenWrites = writes
    visible = false; shown = true; watch.update()
    check(writes == hiddenWrites, "hidden button does no layout work")
    visible = true
    shown = true; watch.update()
    if legacy then
        check(btn.icon.coords[1] == .2666 and btn.icon.alpha == .5, "legacy shell retains pressed crop and alpha")
    else
        check(btn._fluxDownLatch.alpha == 1 and btn._fluxPushedShadow.shown, "open panel keeps pressed appearance")
    end
    local before = writes
    for _ = 1, 2400 do watch.update() end
    local steady = writes - before
    if not baseline then check(steady == 0, "unchanged open panel performs no repeated layout writes") end
    shown = false; held = true; over = true; watch.update()
    check(btn._fluxPlatePushed == true, "held secure-child press remains down")
    over = false; watch.update(); check(btn._fluxPlatePushed == false, "dragging outside immediately releases appearance")
    held = false; shown = true; combat = true; watch.update()
    check(btn._fluxPlatePushed == false, "combat does not mark failed protected repaint complete")
    combat = false; watch.update(); check(btn._fluxPlatePushed == true, "combat end retries unfinished repaint")
    before = writes; refresh(btn); local afterRefresh = writes; watch.update()
    if not baseline then check(writes > afterRefresh and afterRefresh >= before, "portrait refresh invalidates pressed appearance") end
    shown = false; watch.update(); check(btn._fluxPlatePushed == false, "closing panel immediately restores resting appearance")
    env.CharacterFrame = nil
    env.WoWHackCharacterUI = { IsShown = function() return true end }; watch.update()
    check(btn._fluxPlatePushed == true, "alternate character panel retains pressed appearance")
    env.IsMouseButtonDown = nil; env.WoWHackCharacterUI = nil; watch.update()
    check(btn._fluxPlatePushed == false, "missing optional mouse API remains safe")
    return steady
end
local steady = pressChecks(pressBody, portraitBody)
pressChecks(pressBody, portraitBody, false, true)
local oldSteady = pressChecks(replace(pressBody, "if btn._fluxPlatePushed ~= pushed then", "if pushed or btn._fluxPlatePushed ~= pushed then"), portraitBody, true)
local function rejected(label, expected, fn)
    local ok, message = pcall(fn)
    check(not ok and tostring(message):find(expected, 1, true), label .. " must fail intended assertion: " .. tostring(message))
    mutants = mutants + 1
end
rejected("repeat layout", "unchanged open panel performs no repeated layout writes", function()
    pressChecks(replace(pressBody, "if btn._fluxPlatePushed ~= pushed then", "if pushed or btn._fluxPlatePushed ~= pushed then"), portraitBody)
end)
rejected("lose portrait invalidation", "portrait refresh invalidates pressed appearance", function()
    pressChecks(pressBody, replace(portraitBody, "    btn._fluxPlatePushed = nil\n", ""))
end)
rejected("postpone refresh", "one bag refresh within 0.2s of the first event", function()
    bagChecks(replace(bagBody, "                C_Timer.After(0.2, FlushBagCount)", "                C_Timer.After(0.4, FlushBagCount)"))
end)
rejected("accumulate bag callbacks", "only one outstanding bag callback", function()
    bagChecks(replace(bagBody, "            if not bagCountPending then", "            if true then"))
end)
rejected("lose delayed source reconciliation", "trailing refresh includes the source counter's delayed update", function()
    bagChecks(replace(bagBody, "        if remaining > 0 then", "        if false then"))
end)
print(string.format("idle chat: %d checks; %d mutations rejected; open-panel writes/2400frames %d -> %d; 200-event bag callbacks %d -> %d", checks, mutants, oldSteady, steady, oldCallbacks, callbacks))
