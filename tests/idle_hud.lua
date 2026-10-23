-- Execute the current minimap HUD methods, counting work rather than inventing FPS.
local path = debug.getinfo(1, "S").source:sub(2)
local root = (path:match("^(.*)[/\\]") or ".") .. "/../"
local file = assert(io.open(root .. "Minimap/FluxMinimap.lua", "rb"))
local source = file:read("*a"):gsub("\r\n", "\n")
file:close()
local baseline = arg and (arg[1] == "--baseline" or arg[1] == "--capture-baseline")
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
local function section(first, last)
    local start = assert(source:find(first, 1, true), first)
    local finish = assert(source:find(last, start + #first, true), last)
    return source:sub(start, finish - 1)
end
local function replaceSection(text, first, last, body)
    local start = assert(text:find(first, 1, true), first)
    local finish = assert(text:find(last, start + #first, true), last)
    return text:sub(1, start - 1) .. body .. text:sub(finish)
end
local old
if baseline then
    local data = assert(io.open(root .. "tests/fixtures/idle_hud_before.txt", "rb"))
    old = assert(load(data:read("*a"), "@retained-idle-hud-baseline", "t", {}))()
    data:close()
    source = replaceSection(source, "    self._infoBarFrame = infoBar", '    infoBar:RegisterEvent("ZONE_CHANGED")', old.clock)
    source = replaceSection(source, "function FluxMinimap:ApplyInfoBarZoneTextFit", "--- Flux perf T2.7: legacy per-frame", old.marquee)
end
local methodsSource = section("function FluxMinimap:ApplyInfoBarZoneTextFit", "--- Flux perf T2.7: legacy per-frame")
local clockSource = section("    self._infoBarFrame = infoBar", '    infoBar:RegisterEvent("ZONE_CHANGED")')
local statsFile = assert(io.open(root .. "StatusBars/FluxInfoFrame.lua", "rb"))
local statsSource = statsFile:read("*a"):gsub("\r\n", "\n")
statsFile:close()
if baseline then
    statsSource = replaceSection(statsSource, "function _RebuildTooltipStatFrameCache()", "--- All Character / PaperDoll", old.statCache)
    statsSource = replaceSection(statsSource, "function InfoFrame.ResolveStatFramesForTooltip", "RefreshAllPinIndicators = function()", old.statResolver)
    statsSource = replaceSection(statsSource, "local function _GetSpellPowerTopSchoolColorNoTie", "--- Melee (physical) crit", old.colorHelper)
    statsSource = replaceSection(statsSource, "function InfoFrame._ClassicSpellDamageColorHex", 'STAT_REGISTRY["spellPower"]', old.color)
    statsSource = replaceSection(statsSource, 'STAT_REGISTRY["spellPower"]', 'STAT_REGISTRY["spellPowerOnly"]', old.spellLine)
end

local function statsFixture(client, replacement)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.Flux = { Client = { isCamelot = client == "forever" } }
    env.FLUX_API = { isCamelot = client == "forever", isRetail = client == "live" or client == "forever" }
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_WRATH_CLASSIC = 1, 2, 11
    env.WOW_PROJECT_ID = env.FLUX_API.isRetail and 1 or 2
    env.now, env.childReads = 10, 0
    env.GetTime = function() return env.now end
    env.InCombatLockdown = function() return false end
    env.C_Timer = { After = function() end }
    env.wipe = function(values) for key in pairs(values) do values[key] = nil end end
    local function noop() end
    local function frame()
        local f = { scripts = {}, events = {}, children = {}, shown = true }
        function f:RegisterEvent(key) self.events[key] = true end
        f.RegisterUnitEvent = f.RegisterEvent
        function f:SetScript(key, value) self.scripts[key] = value end
        function f:HookScript(key, value)
            local previous = self.scripts[key]
            self.scripts[key] = function(...)
                if previous then previous(...) end
                value(...)
            end
        end
        function f:GetScript(key) return self.scripts[key] end
        function f:GetChildren()
            env.childReads = env.childReads + 1
            return (unpack or table.unpack)(self.children)
        end
        function f:IsShown() return self.shown end
        f.EnableMouse, f.SetMouseClickEnabled = noop, noop
        function f:CreateTexture()
            return { SetTexture = noop, SetSize = noop, SetPoint = noop, ClearAllPoints = noop,
                SetVertexColor = noop, Show = noop, Hide = noop }
        end
        return f
    end
    env.CreateFrame = frame
    assert(load(replacement or statsSource, "@idle-info-frame", "t", env))()
    local info = env.FluxInfoFrame
    info.ForceRebuild = noop
    local function row(key, value)
        local f = frame()
        f._FluxInfoStatKey, f.numericValue = key, value
        f.Label = { GetText = function() return key end, SetText = noop }
        f.Value = { GetText = function() return tostring(f.numericValue) end }
        return f
    end
    local damage, heal, crit = row("spellPower", 70), row("healPower", 400), row("crit", 20)
    damage.bonusDamage = { [2] = 20, [3] = 30, [4] = 40, [5] = 50, [6] = 60, [7] = 70 }
    local character = frame()
    character.children = { damage, heal, crit }
    for i = 1, 120 do character.children[#character.children + 1] = frame() end
    env.CharacterFrame = character
    env.CharacterStatsPane = character.children[4]
    env.PaperDollFrame = character.children[5]
    env.UnitClass = function() return "Mage", "MAGE", 8 end
    env._FluxUI_CharSavedVars = { infoFrame = { spellDisplayMode = "both" } }
    return { env = env, info = info, damage = damage, heal = heal, crit = crit, row = row, frame = frame }
end

local function statsRun(client, replacement)
    local f = statsFixture(client, replacement)
    local info, env = f.info, f.env
    local registry = info.GetStatRegistry()
    local bonusCalls = 0
    local originalBonus = info._CamelotSpellBonus
    info._CamelotSpellBonus = function(...)
        bonusCalls = bonusCalls + 1
        return originalBonus(...)
    end
    for i = 1, 30 do
        env.now = 10 + i
        if client == "forever" then
            local line = registry.spellPower.getText()
            check(line == "Spell: |cff99ccff70|r / |cff20ff20400|r", "Forever spell line and school color retained")
        else
            local damage, heal = info._CamelotSpellBonus()
            check(damage == 70 and heal == 400, client .. ": row data retained")
            info._ClassicSpellDamageColorHex()
        end
        check(info.ResolveStatFramesForTooltip("crit", false)[1] == f.crit, client .. ": tooltip source retained")
    end
    local idleReads = env.childReads
    local idleBonusCalls = bonusCalls
    -- Values must remain live even inside the discovery-cache interval.
    f.damage.bonusDamage[7], f.heal.numericValue = 999, 777
    local damage, heal = info._CamelotSpellBonus()
    check(damage == 999 and heal == 777, client .. ": cached identities do not cache values")
    check(info._ClassicSpellDamageColorHex() == "99ccff", client .. ": color reads current school bonus")
    f.damage.bonusDamage[7], f.damage.bonusDamage[3] = 70, 1000
    check(info._ClassicSpellDamageColorHex() == "ff8000", client .. ": leading school changes immediately")
    if not baseline then
        check(idleReads <= 30 * 124, client .. ": one discovery traversal per refresh interval")
        if client == "forever" then
            check(idleBonusCalls == 30, "Forever color uses the same spell data as its text")
        end
    end
    -- Replacing a top-level character surface must not wait for cache expiry.
    local replacementRoot = f.frame()
    local newCrit = f.row("crit", 42)
    replacementRoot.children = { newCrit }
    env.CharacterFrame, env.CharacterStatsPane, env.PaperDollFrame = replacementRoot, nil, nil
    local replaced = info.ResolveStatFramesForTooltip("crit", false)
    if not baseline then
        check(#replaced == 1 and replaced[1] == newCrit, client .. ": root replacement invalidates")
    end
    if not baseline then
        -- A pooled row can change key without replacing the top-level surface.
        info.HookForeverScrollBoxStatFrame(newCrit, "haste")
        check(info.ResolveStatFramesForTooltip("haste", false)[1] == newCrit, client .. ": pooled reassignment invalidates")
        check(#info.ResolveStatFramesForTooltip("crit", false) == 0, client .. ": reassigned row leaves its old key")
        -- Discovery still works for addon rows that have not registered with Flux.
        local unannounced = f.row("crit", 51)
        replacementRoot.children[#replacementRoot.children + 1] = unannounced
        env.now = env.now + 0.26
        check(info.ResolveStatFramesForTooltip("crit", false)[1] == unannounced, client .. ": unannounced rows discovered")
        -- Reordering only visibility must take effect even inside the cache interval.
        local second = f.row("crit", 52)
        second.shown = false
        replacementRoot.children[#replacementRoot.children + 1] = second
        env.now = env.now + 0.26
        local both = info.ResolveStatFramesForTooltip("crit", false)
        check(#both == 2 and both[1] == unannounced, client .. ": duplicate rows retained and visible one preferred")
        unannounced.shown, second.shown = false, true
        check(info.ResolveStatFramesForTooltip("crit", false)[1] == second, client .. ": visibility sorting stays live")
        -- Cached arrays are private: consumer mutation cannot lose tooltip sources.
        both[1] = nil
        check(#info.ResolveStatFramesForTooltip("crit", false) == 2, client .. ": callers cannot mutate cached membership")
        -- An explicitly registered new row is available before the periodic discovery.
        local late = f.row(nil, 88)
        replacementRoot.children[#replacementRoot.children + 1] = late
        info.HookRetailPaperDollPoolStatFrame(late, "armor")
        check(info.ResolveStatFramesForTooltip("armor", false)[1] == late, client .. ": registering a new row invalidates")
        -- Some pooled/ScrollBox stat rows are not descendants of CharacterFrame.
        local pooled, scrolled = f.row("weaponSpeed", 2), f.row("weaponSpeed", 3)
        local pane = f.frame()
        pane.statsFramePool = { EnumerateActive = function()
            local values, i = { pooled }, 0
            return function() i = i + 1; return values[i] end
        end }
        env.CharacterStatsPane = pane
        local scroll = f.frame()
        scroll.ScrollBox = { GetView = function()
            return { GetFrames = function() return { pooled, scrolled } end }
        end }
        env.CharacterStatsPaneScrollBox = scroll
        -- Alias roots and repeated pool membership must not duplicate sources.
        env.PaperDollFrame = pane
        local sources = info.ResolveStatFramesForTooltip("weaponSpeed", false)
        local present = {}
        for _, candidate in ipairs(sources) do present[candidate] = true end
        check(#sources == 2 and present[pooled] and present[scrolled], client .. ": detached pools/ScrollBox and duplicate roots retained")
        -- A released row can keep its tag and later be acquired for the same key.
        local activePool, activeScroll = {}, {}
        pane.statsFramePool.EnumerateActive = function()
            local i = 0
            return function() i = i + 1; return activePool[i] end
        end
        scroll.ScrollBox.GetView = function() return { GetFrames = function() return activeScroll end } end
        env.now = env.now + 0.26
        check(#info.ResolveStatFramesForTooltip("weaponSpeed", false) == 0, client .. ": released rows leave cache")
        activePool[1] = pooled
        info.HookRetailPaperDollPoolStatFrame(pooled, "weaponSpeed")
        check(info.ResolveStatFramesForTooltip("weaponSpeed", false)[1] == pooled, client .. ": same-key pool reacquisition invalidates")
        activePool[1], activeScroll[1] = nil, nil
        env.now = env.now + 0.26
        check(#info.ResolveStatFramesForTooltip("weaponSpeed", false) == 0, client .. ": ScrollBox release empties membership")
        activeScroll[1] = scrolled
        info.HookForeverScrollBoxStatFrame(scrolled, "weaponSpeed")
        check(info.ResolveStatFramesForTooltip("weaponSpeed", false)[1] == scrolled, client .. ": same-key ScrollBox reacquisition invalidates")
        -- A CSC label-only row still resolves through the existing key parser.
        local csc = f.row(nil, 61)
        csc.Label.GetText = function() return "Item LvL" end
        replacementRoot.children[#replacementRoot.children + 1] = csc
        env.now = env.now + 0.26
        check(info.ResolveStatFramesForTooltip("itemLevel", false)[1] == csc, client .. ": unregistered CSC/label rows retained")
    end
    return idleReads
end

local function fixture(client, overrides)
    local counts = { text = 0, width = 0, measure = 0, color = 0, anchors = 0,
        clockWrites = 0, format = 0, calendar = 0, callbacks = 0 }
    local now, timers = 0, {}
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.Flux = { Client = { branch = client, isCamelot = client == "forever" } }
    local locked = false
    env.InCombatLockdown = function() return locked end
    local bar = { scripts = {}, shown = true, width = 220 }
    function bar:SetScript(event, callback) self.scripts[event] = callback end
    function bar:HookScript(event, callback)
        local previous = self.scripts[event]
        self.scripts[event] = function(...)
            if previous then previous(...) end
            callback(...)
        end
    end
    function bar:IsShown() return self.shown end
    function bar:Show()
        if self.shown then return end
        self.shown = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function bar:Hide()
        if not self.shown then return end
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function bar:GetWidth() return self.width end
    local clip = { width = 140 }
    function clip:GetWidth() return self.width end
    function clip:SetWidth(value) self.width = value end
    local text = { text = "", width = 140 }
    function text:SetText(value) self.text = value; counts.text = counts.text + 1 end
    function text:SetWidth(value) self.width = value; counts.width = counts.width + 1 end
    function text:GetStringWidth() counts.measure = counts.measure + 1; return #self.text * 9 end
    function text:ClearAllPoints() counts.anchors = counts.anchors + 1 end
    function text:SetPoint(_, _, _, x) self.x = x; counts.anchors = counts.anchors + 1 end
    function text:SetTextColor(r, g, b) self.color = { r, g, b }; counts.color = counts.color + 1 end
    local clock = { text = "" }
    function clock:SetText(value) self.text = value; counts.clockWrites = counts.clockWrites + 1 end
    bar.ZoneText, bar.ZoneScrollClip, bar.TimeText = text, clip, clock
    local minimap = { InfoBar = bar, _infoBarFrame = bar }
    env.FluxMinimap = minimap
    env.CONFIG = { Size = 220 }
    env.ZONE_TEXT_PAD_LEFT, env.ZONE_TEXT_PAD_RIGHT = 8, 68
    env.ZONE_SCROLL_PX_PER_SEC = 30
    env.GetZoneText = function() return "A very long unchanged zone name for the HUD marquee" end
    env.GetSubZoneText = function() return "" end
    env.TruncateFontStringToWidth = function(fs, value, width)
        local truncated = #value * 9 > width
        fs:SetText(truncated and value:sub(1, 10) .. "..." or value)
        return fs.text, truncated
    end
    env.string = setmetatable({ format = function(...)
        counts.format = counts.format + 1
        return string.format(...)
    end }, { __index = string })
    env.C_DateAndTime = { GetCurrentCalendarTime = function()
        counts.calendar = counts.calendar + 1
        return { hour = 12 + math.floor(now / 3600), minute = math.floor(now / 60) % 60 }
    end }
    env.C_Timer = { NewTicker = function(interval, callback)
        local timer = { interval = interval, due = now + interval, callback = callback }
        function timer:Cancel() self.cancelled = true end
        timers[#timers + 1] = timer
        return timer
    end }
    assert(load((overrides and overrides.methods) or methodsSource, "@minimap-hud-methods", "t", env))()
    assert(load("return function(self, infoBar)\n" .. ((overrides and overrides.clock) or clockSource) .. "\nend",
        "@minimap-hud-clock", "t", env))()(minimap, bar)
    local function advance(seconds)
        local stop = now + seconds
        while now < stop do
            now = now + 1
            for i = 1, #timers do
                local timer = timers[i]
                if not timer.cancelled and timer.due <= now then
                    timer.due = now + timer.interval
                    timer.callback(timer)
                end
            end
        end
    end
    local function frames(number)
        for _ = 1, number do
            if bar.shown and bar.scripts.OnUpdate then
                counts.callbacks = counts.callbacks + 1
                bar.scripts.OnUpdate(bar, 1 / 240)
            end
        end
    end
    return { env = env, bar = bar, text = text, clip = clip, counts = counts, minimap = minimap,
        advance = advance, frames = frames, lock = function(value) locked = value end, timers = timers }
end

local function run(client, overrides)
    local f = fixture(client, overrides)
    local m, bar, counts = f.minimap, f.bar, f.counts
    f.advance(600)
    local clockWrites, formats = counts.clockWrites, counts.format
    check(bar.TimeText.text == "12:10", client .. ": clock displays the latest minute")
    bar:Hide()
    local hiddenQueries = counts.calendar
    f.advance(120)
    hiddenQueries = counts.calendar - hiddenQueries
    if not baseline then check(hiddenQueries == 0, client .. ": hidden HUD performs no clock queries") end
    bar:Show()
    check(bar.TimeText.text == "12:12", client .. ": showing HUD immediately refreshes clock")
    local liveTimers = 0
    for _, timer in ipairs(f.timers) do if not timer.cancelled then liveTimers = liveTimers + 1 end end
    check(liveTimers == 1, client .. ": one live clock after hide/show")
    m:UpdateInfoBarZone()
    m:OnInfoBarZoneHitEnter()
    check(bar._zoneScrollActive, client .. ": long hovered zone scrolls")
    local beforeText, beforeWidth, beforeMeasure, beforeColor = counts.text, counts.width, counts.measure, counts.color
    f.frames(2400)
    local marquee = { text = counts.text - beforeText, width = counts.width - beforeWidth,
        measure = counts.measure - beforeMeasure, color = counts.color - beforeColor }
    check(type(f.text.x) == "number" and f.text.x < 0, client .. ": marquee moves at frame rate")
    check(bar.scripts.OnUpdate ~= nil, client .. ": active animation retains OnUpdate")
    f.lock(true)
    f.frames(240)
    f.lock(false)
    check(bar._zoneScrollActive, client .. ": combat does not pause nonprotected display animation")
    m:UpdateInfoBarZone() -- World/zone changes and layout refits can happen before OnLeave.
    local idleCallbacks = counts.callbacks
    f.frames(2400)
    idleCallbacks = counts.callbacks - idleCallbacks
    check(not bar._zoneScrollActive, client .. ": refit ends obsolete animation")
    if not baseline then
        check(clockWrites == 11 and formats == 11, client .. ": only changed minutes format/write text")
        check(marquee.text == 0 and marquee.width == 0 and marquee.measure == 0 and marquee.color == 0,
            client .. ": unchanged marquee performs only animation position work")
        check(idleCallbacks == 0 and not bar.scripts.OnUpdate, client .. ": refit detaches idle callback")
    end
    m:OnInfoBarZoneHitEnter()
    check(bar._zoneScrollActive, client .. ": reenter restarts scrolling after a refit")
    bar:Hide()
    if not baseline then
        check(not bar.scripts.OnUpdate and not bar._zoneScrollActive, client .. ": hiding during a marquee detaches animation")
    end
    bar:Show()
    m:OnInfoBarZoneHitEnter()
    m:OnInfoBarZoneHitLeave()
    check(not bar.scripts.OnUpdate, client .. ": mouse leave detaches animation")
    return { clockWrites = clockWrites, formats = formats, hiddenClockQueries = hiddenQueries,
        marquee = marquee, idleCallbacksAfterRefit = idleCallbacks }
end

local clients = { "live", "classic_era", "classic_anniversary", "classic", "forever" }
local result
local statReads
for _, client in ipairs(clients) do
    result = run(client)
    statReads = statsRun(client)
end
local mutants = 0
if not baseline then
    local function once(text, from, to)
        local start = assert(text:find(from, 1, true), "missing mutation target: " .. from)
        return text:sub(1, start - 1) .. to .. text:sub(start + #from)
    end
    local function rejected(name, expected, body)
        local ok, message = pcall(body)
        check(not ok and tostring(message):find(expected, 1, true), name .. " must fail its behavioral assertion: " .. tostring(message))
        mutants = mutants + 1
    end
    rejected("repeat unchanged clock", "only changed minutes format/write text", function()
        run("forever", { clock = once(clockSource, " and (hour ~= clockHour or minute ~= clockMinute)", "") })
    end)
    rejected("keep hidden clock alive", "hidden HUD performs no clock queries", function()
        run("forever", { clock = once(clockSource, "            self._clockTicker:Cancel()", "") })
    end)
    rejected("delay clock on show", "showing HUD immediately refreshes clock", function()
        run("forever", { clock = once(clockSource, "    local function StartClock()\n        _tickClock()", "    local function StartClock()") })
    end)
    rejected("leak marquee after refit", "refit detaches idle callback", function()
        local apply = methodsSource:sub(1, assert(methodsSource:find("function FluxMinimap:OnInfoBarZoneHitEnter", 1, true)) - 1)
        local rest = methodsSource:sub(#apply + 1)
        run("forever", { methods = once(apply, '        bar:SetScript("OnUpdate", nil)', "") .. rest })
    end)
    rejected("repeat marquee text work", "unchanged marquee performs only animation position work", function()
        local changed = once(methodsSource, "    local fullW = ib._zoneScrollWidth", "    local fullW = nil")
        run("forever", { methods = changed })
    end)
    rejected("retain animation after inherited hide", "hiding during a marquee detaches animation", function()
        run("forever", { clock = once(clockSource, '        infoBar:SetScript("OnUpdate", nil)', "") })
    end)
    rejected("recompute spell data for color", "color uses the same spell data as its text", function()
        statsRun("forever", once(statsSource, "_GetSpellPowerTopSchoolColorNoTie(maxD, bonus) or", "_GetSpellPowerTopSchoolColorNoTie() or"))
    end)
    rejected("scan cached character tree for every query", "one discovery traversal per refresh interval", function()
        statsRun("forever", once(statsSource, "    if not _tooltipKeyToStatFrameAt or (now - _tooltipKeyToStatFrameAt) > 0.25",
            "    if true or not _tooltipKeyToStatFrameAt or (now - _tooltipKeyToStatFrameAt) > 0.25"))
    end)
    rejected("ignore character surface replacement", "root replacement invalidates", function()
        local start = assert(statsSource:find("    local roots = InfoFrame._tooltipSourceRoots", 1, true))
        local finish = assert(statsSource:find("        _RebuildTooltipStatFrameCache()", start, true))
        local changed = statsSource:sub(1, start - 1) .. "    if not _tooltipKeyToStatFrameAt or (now - _tooltipKeyToStatFrameAt) > 0.25 then\n" ..
            statsSource:sub(finish)
        statsRun("forever", changed)
    end)
    rejected("ignore pooled row assignment", "pooled reassignment invalidates", function()
        local start = assert(statsSource:find("function InfoFrame.HookForeverScrollBoxStatFrame", 1, true))
        local changed = statsSource:sub(1, start - 1) .. once(statsSource:sub(start),
            "    if statFrame._FluxInfoStatKey ~= registryKey\n        or (InfoFrame._tooltipSourceMembers and InfoFrame._tooltipSourceMembers[statFrame] ~= registryKey) then\n        _InvalidateTooltipStatFrameCache()\n    end", "")
        statsRun("forever", changed)
    end)
    rejected("ignore same-key reacquisition", "same-key pool reacquisition invalidates", function()
        local changed = statsSource:gsub("\n        or %(InfoFrame%._tooltipSourceMembers and InfoFrame%._tooltipSourceMembers%[statFrame%] ~= registryKey%)", "")
        statsRun("forever", changed)
    end)
    rejected("freeze tooltip row visibility", "visibility sorting stays live", function()
        local start = assert(statsSource:find("    -- Visibility can change", 1, true))
        local finish = assert(statsSource:find("    if #out == 0", start, true))
        statsRun("forever", statsSource:sub(1, start - 1) .. statsSource:sub(finish))
    end)
    rejected("freeze native row numbers", "cached identities do not cache values", function()
        local changed = once(statsSource, "function InfoFrame._CamelotSpellBonus()\n",
            "function InfoFrame._CamelotSpellBonus()\n    if InfoFrame._mutantBonus then return table.unpack(InfoFrame._mutantBonus) end\n")
        changed = once(changed, "    return maxD or 0, heal or 0, minD or maxD or 0, bonus",
            "    InfoFrame._mutantBonus = { maxD or 0, heal or 0, minD or maxD or 0, bonus }\n    return table.unpack(InfoFrame._mutantBonus)")
        statsRun("forever", changed)
    end)
end
print((baseline and "idle HUD before" or "idle HUD after") .. ": 600s clock writes=" .. result.clockWrites ..
    ", formats=" .. result.formats .. ", hidden clock queries=" .. result.hiddenClockQueries ..
    "; 2400 marquee frames text/width/measure/color=" .. result.marquee.text .. "/" .. result.marquee.width ..
    "/" .. result.marquee.measure .. "/" .. result.marquee.color .. "; 2400 idle callbacks after refit=" .. result.idleCallbacksAfterRefit)
print("idle HUD stat discovery: " .. statReads .. " GetChildren calls in 30 refreshes of 124 nodes")
print("idle HUD: " .. checks .. " checks across five clients; " .. mutants .. " behavioral mutations rejected")
return { checks = checks, metrics = result, mutations = mutants }
