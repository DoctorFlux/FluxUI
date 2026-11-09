-- Actual integration plus widget mocks; no native secure VM, pixels or FPS claim.
local source = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
local originalArgs = arg; arg = { source, "--harness" }
local harness = assert(loadfile("tests/native_meter_ownership.lua"))(); arg = originalArgs
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local names = { "DamageDone", "Dps", "HealingDone", "Hps", "Absorbs", "Interrupts", "Dispels",
    "DamageTaken", "AvoidableDamageTaken", "Deaths", "EnemyDamageTaken" }
local function slot(value) return { kind = "blizzard", damageMeterType = value } end
local function layout(a,b,c)
    return { topSlots = {slot(a)}, bottomSlots = b and (c and {slot(b),slot(c)} or {slot(b)}) or {}, topRowFrac = .6 }
end
local function dispatch(s, object, method)
    for _, fn in ipairs(s.hooks[object] and s.hooks[object][method] or {}) do fn(object) end
end
for _, gamepad in ipairs({ false, true }) do
    local e, s = harness(gamepad)
    for i, name in ipairs(names) do e.Enum.DamageMeterType[name] = i - 1 end
    e.FluxMeterLayout.SlotShortLabel = function(value) return names[value.damageMeterType + 1] or "Future type" end
    local create = e.CreateFrame
    local notices = {}
    local function font()
        return { SetPoint = function() end, SetTextColor = function() end, SetWordWrap = function() end,
            SetText = function(self,text) self.text = text end }
    end
    function s.dm:CreateFontString() return font() end
    e.CreateFrame = function(kind, name, parent)
        local f = create(kind, name, parent)
        f.parent = parent
        function f:SetFrameLevel(value) self.level = value end
        function f:EnableMouse(value) self.mouse = value end
        function f:CreateTexture()
            return { SetAllPoints = function() end, SetColorTexture = function(self,...) self.color = {...} end,
                SetAlpha = function() end, Show = function() end }
        end
        function f:CreateFontString() return font() end
        if parent == s.dm then notices[#notices + 1] = f end
        return f
    end
    local paints, entries = {}, 0
    e.FluxMeterSkin = {
        ApplyToWindow = function(_,window) paints[window] = true end,
        ApplyToEntry = function() entries = entries + 1 end,
        ApplyToOwnedPane = function(_,window,title,scale,timer)
            window.skinTitle,window.skinScale,window.skinTimer = title,scale,timer
        end,
        ReleaseWindow = function(_,window) window.released = true end,
        ReleaseAllNative = function() end,
    }
    local meter = e.FluxBlizzardMeter
    -- Exact matches reserve the second slot's native window before setup fallback.
    meter:Embed(s.host, layout(7,0)); s.drain()
    local status = meter:GetLayoutStatus()
    check(s.windows[1]:IsShown() and s.windows[2]:IsShown(), "preset must keep native menus visible for Damage Taken setup")
    check(status.visibleNativePanes == 2 and status.setupPanes == 1, "one unmatched preset slot has one explicit setup cover")
    check(status.sessionChoices[1].damageMeterType == 2 and status.sessionChoices[2].damageMeterType == 0,
        "fallback cannot steal an exact Damage match needed later")
    check(status.sessionChoices[1].requestedDamageMeterType == 7 and status.sessionChoices[1].setupRequired,
        "status distinguishes requested and actual types")
    check(#notices == 1 and notices[1]:IsShown() and notices[1].mouse and notices[1].text.text:find("DamageTaken",1,true),
        "setup cover names requested type and blocks interaction with mismatched data")
    check(notices[1].points[1][5] == -25, "setup cover starts below the native header and its menus")
    local writes = s.typeCalls
    s.dm:SetSessionWindowDamageMeterType(s.windows[2],7) -- User selection, then the modeled secure posthook.
    dispatch(s,s.dm,"SetSessionWindowDamageMeterType"); s.drain()
    check(not meter:GetLayoutStatus().configurationRequired and not notices[1]:IsShown(), "native type choice removes setup cover automatically")
    check(s.typeCalls == writes + 1, "selection repair adds no addon type writes")
    -- Duplicate requests consume separate native windows, never one window twice.
    s.windows[1].meterType, s.windows[2].meterType = 6, 6
    meter:Embed(s.host,layout(6,6)); s.drain()
    check(meter:GetLayoutStatus().visibleNativePanes == 2 and not meter:GetLayoutStatus().configurationRequired,
        "duplicate custom Dispels slots use distinct matching native windows")
    -- All eleven enum types, including already configured Absorbs and future values.
    for value = 0, 11 do
        s.windows[1].meterType = value
        meter:Embed(s.host, layout(value)); s.drain()
        check(not meter:GetLayoutStatus().configurationRequired and s.windows[1]:IsShown(), "every existing native type docks")
        check(paints[s.windows[1]] and paints[s.windows[1].sourceWindow], "all types skin both session and source windows")
        local before = entries
        s.windows[1]:InitEntry(s.windows[1].entry,{isLocalPlayer=true})
        s.windows[1].sourceWindow:InitEntry(s.windows[1].sourceWindow.entry,{isLocalPlayer=false})
        check(entries == before + 2, "pooled rows keep skin after every meter type switch")
    end
    -- Three requested native slots with only two existing windows show a third setup pane.
    s.windows[1].meterType, s.windows[2].meterType = 0, 2
    meter:Embed(s.host,layout(0,2,6)); s.drain()
    status = meter:GetLayoutStatus()
    check(status.visibleNativePanes == 2 and status.setupPanes == 1 and #s.windows == 2, "missing native window has an explicit setup pane without addon creation")
    local active
    for _,notice in ipairs(notices) do if notice:IsShown() then active = notice end end
    check(active and active.text.text:find("add this Blizzard meter",1,true), "missing window explains its native creation action")
    check(active.skinTitle == "Dispels" and active.skinScale == .8 and active.skinTimer == false,
        "uncreated slot shares the Damage/Healing skin and scale without claiming a native timer")
    s.dm:ShowNewSecondarySessionWindow() -- User action; hook runs after native setup.
    dispatch(s,s.dm,"ShowNewSecondarySessionWindow"); s.drain()
    check(meter:GetLayoutStatus().visibleNativePanes == 3 and meter:GetLayoutStatus().setupPanes == 1,
        "new native pane becomes an accessible type-selection pane automatically")
    check(active.released, "native window arrival retires setup chrome instead of duplicating native borders")
    s.dm:SetSessionWindowDamageMeterType(s.windows[3],6)
    dispatch(s,s.dm,"SetSessionWindowDamageMeterType"); s.drain()
    check(not meter:GetLayoutStatus().configurationRequired, "Dispels preset becomes fully ready after native choice")
    -- Absorbs must disclose native dropdown omission, while preserving existing Absorbs.
    meter:Embed(s.host,layout(0,2,4)); s.drain()
    active = nil
    for _,notice in ipairs(notices) do if notice:IsShown() then active = notice end end
    check(active and active.text.text:find("does not offer Absorbs",1,true), "unavailable native menu option is explicit")
    local frames, timers = #s.frames, s.timerCreates
    local types, sessions, walks = s.typeCalls, s.sessionCalls, s.entryWalks
    for _ = 1, 100 do meter:RefreshEmbeddedLayout() end
    check(#s.frames == frames and s.timerCreates == timers and s.entryWalks == walks,
        "setup covers reuse frames and add no idle work or repeated row walks")
    check(s.typeCalls == types and s.sessionCalls == sessions, "all setup refreshes preserve native data/configuration")
    -- Combat selection does not rearrange frames until regeneration.
    s.combat = true
    s.windows[3].meterType = 4
    dispatch(s,s.dm,"SetSessionWindowDamageMeterType")
    check(meter:GetLayoutStatus().configurationRequired and s.timerCreates == timers, "native choice defers layout repair during combat")
    s.combat = false; s.event("PLAYER_REGEN_ENABLED"); s.drain()
    check(not meter:GetLayoutStatus().configurationRequired, "combat-exit repair reconciles selected type")
    -- Cleanup and permanently installed hooks have bounded ownership.
    meter:Embed(s.host,layout(7,6,5)); s.drain()
    meter:Cleanup()
    for _,notice in ipairs(notices) do check(not notice:IsShown(), "cleanup hides every pooled setup cover") end
    timers = s.timerCreates
    dispatch(s,s.dm,"SetSessionWindowDamageMeterType"); dispatch(s,s.dm,"ShowNewSecondarySessionWindow"); s.drain()
    check(s.timerCreates == timers, "native layout hooks do no work after cleanup")
    check(s.nativeMethodsIntact(), "all native configuration and entry functions remain intact")
end

-- Run the actual preset producer too, rather than copying its slot lists here.
do
    local e, s = harness(false)
    for i,name in ipairs(names) do e.Enum.DamageMeterType[name] = i - 1 end
    e.C_DamageMeter = { IsDamageMeterAvailable = function() return true end }
    e.C_AddOns = { IsAddOnLoaded = function() return false end,
        DoesAddOnExist = function(name) return name == "Blizzard_DamageMeter" end }
    e._FluxUI_CharSavedVars = {}
    assert(loadfile("Battlezonemap/FluxMeterLayout.lua","t",e))()
    local meter = e.FluxBlizzardMeter
    for id = 1, e.FluxMeterLayout.GetBuiltinCount() do
        e.FluxMeterLayout.ApplyBuiltin(id)
        local preset = e.FluxMeterLayout.GetWorkingLayout()
        local wanted = {}
        for _,row in ipairs({preset.topSlots,preset.bottomSlots}) do
            for _,value in ipairs(row) do
                if value.kind == "blizzard" then wanted[#wanted+1] = value.damageMeterType end
            end
        end
        local windows = s.windows
        while #windows < #wanted do s.dm:ShowNewSecondarySessionWindow() end
        for i,value in ipairs(wanted) do windows[i].meterType = value end
        meter:Embed(s.host,preset); s.drain()
        local status = meter:GetLayoutStatus()
        check(not status.configurationRequired and status.visibleNativePanes == #wanted,
            "every native slot in production preset " .. id .. " docks with its actual type")
    end
end
print(string.format("native meter all options: %d checks; native pixels/taint/FPS pending", checks))
