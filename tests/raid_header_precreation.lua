-- Production raid layout with effective visibility and native header allocation
-- modeled from Blizzard SecureGroupHeaders.lua, Retail 12.1.5.70783:
-- 297d7aaaa736f346b3e036f38ee088eaf7f8c07f. Native taint/secure VM pending.
local sourceRoot = arg[1] or "."
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function loadModule(path, env, ns)
    assert(loadfile(sourceRoot .. "/" .. path, "t", env))("_FluxUI", ns)
end
local noop = function() end

local function fixture(client, raid, enabled, ancestorVisible, containerShown)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local s = { combat = false, raid = raid, enabled = enabled, roster = 1,
        mtma = 1, children = 0, blocked = 0, timers = {}, headers = {}, frames = {}, writes = 0,
        nativeHidden = false, timersCreated = 0, headerShows = 0, nativeStateCallbacks = 0 }
    e.InCombatLockdown = function() return s.combat end
    e.IsInRaid = function() return s.raid end
    e.IsInGroup = function() return true end
    e.UnitInRaid = function() return s.raid and 1 or nil end
    e.UnitExists = function(unit) return tonumber(unit:match("%d+")) == 1 end
    e.GetRaidRosterInfo = function(index)
        if index ~= 1 then return end
        return "Member", 0, 1, 80, "Warrior", "WARRIOR", nil, nil, nil, "MAINTANK"
    end
    e.FluxRaid_IsFluxRaidEnabled = function() return s.enabled end
    e.FluxRaid_DisplayMainTankAndAssistCVarEnabled = function() return true end
    e.FluxOptions = { GetRaidFrameDB = function() return { useFluxRaidFrames = s.enabled } end }
    e.FluxRaidVisuals = { FRAME_WIDTH = 72, FRAME_HEIGHT = 43, ApplyRaidFrameTunables = noop }
    e.C_Timer = { After = function(_, fn)
        s.timersCreated = s.timersCreated + 1
        s.timers[#s.timers + 1] = fn
    end }
    local ns = { Flux = { Timer = e.C_Timer, Blizz = {
        Hide = function() s.nativeHidden = true end,
        Unhide = function() s.nativeHidden = false end,
    } } }
    local methods = {}
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:GetParent() return self.parent end
    function methods:GetName() return self.name end
    function methods:GetAttribute(key) return self.attributes[key] end
    function methods:SetFrameRef(key, value) self.references[key] = value end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:SetScript(key, fn) self.scripts[key] = fn end
    function methods:GetScript(key) return self.scripts[key] end
    function methods:HookScript(event, fn)
        self.hooks[event] = self.hooks[event] or {}
        self.hooks[event][#self.hooks[event] + 1] = fn
    end
    local function nativeUpdate(header)
        local attrs = header.attributes
        local count = 0
        if s.raid and attrs.showRaid then
            count = attrs.groupFilter == "MAINTANK,MAINASSIST" and s.mtma
                or (attrs.groupFilter == "1" and s.roster or 0)
        elseif not s.raid and attrs.showParty then count = s.roster end
        local capacity = (attrs.unitsPerColumn or math.max(count, 1)) * (attrs.maxColumns or 1)
        -- Negative startingIndex deliberately makes native blank slots allocate.
        local needed = math.max(1, math.min(capacity, count - (attrs.startingIndex or 1) + 1))
        for index = 1, needed do
            if not attrs["child" .. index] then
                if s.combat then s.blocked = s.blocked + 1; return end
                s.children = s.children + 1
                attrs["child" .. index] = { native = true }
            end
        end
    end
    local function synchronizeVisibility()
        for _, frame in ipairs(s.frames) do
            local visible = frame:IsVisible()
            if visible and not frame.effectiveVisible then
                frame.effectiveVisible = true
                if frame.isHeader then nativeUpdate(frame) end
                for _, fn in ipairs(frame.hooks.OnShow or {}) do fn(frame) end
            else
                frame.effectiveVisible = visible
            end
        end
    end
    function methods:SetAttribute(key, value)
        assert(not s.combat, "production writes protected attributes in combat")
        s.writes = s.writes + 1; self.attributes[key] = value
        if self.isHeader and self:IsVisible() then nativeUpdate(self) end
        if self.scripts.OnAttributeChanged then self.scripts.OnAttributeChanged(self, key, value) end
        for _, fn in ipairs(self.hooks.OnAttributeChanged or {}) do fn(self, key, value) end
    end
    function methods:Show()
        assert(not s.combat, "production shows protected frame in combat")
        if self.isHeader then s.headerShows = s.headerShows + 1 end
        self.shown = true; synchronizeVisibility()
    end
    function methods:Hide()
        assert(not s.combat, "production hides protected frame in combat")
        self.shown = false; synchronizeVisibility()
    end
    function methods:SetID(id) self.id = id end
    function methods:GetID() return self.id end
    function methods:GetWidth() return 72 end
    function methods:GetHeight() return 43 end
    function methods:GetTop() return 400 end
    function methods:GetBottom() return 200 end
    function methods:GetPoint() return "TOPLEFT", self.parent, "TOPLEFT", 0, 0 end
    for name in ("SetClipsChildren SetPoint ClearAllPoints SetSize SetWidth SetHeight SetFrameStrata SetFrameLevel SetText SetTextColor SetShadowOffset SetFont"):gmatch("%S+") do methods[name] = noop end
    local function frame(name, parent)
        local f = setmetatable({ name = name, parent = parent, shown = false, attributes = {}, hooks = {},
            scripts = {}, references = {}, events = {} }, { __index = methods })
        if name then e[name] = f end
        s.frames[#s.frames + 1] = f
        return f
    end
    function methods:CreateFontString() return frame(nil, self) end
    e.CreateFrame = function(_, name, parent, template)
        assert(not s.combat, "production creates headers in combat")
        local f = frame(name, parent)
        if template == "FluxRaidGroupHeaderTemplate" then f.isHeader = true; s.headers[#s.headers + 1] = f end
        if template == "SecureHandlerStateTemplate" then
            f.scripts.OnAttributeChanged = function() s.nativeStateCallbacks = s.nativeStateCallbacks + 1 end
            s.nativeStateHandler = f.scripts.OnAttributeChanged
        end
        return f
    end
    e.UIParent = frame("UIParent"); e.UIParent.shown = ancestorVisible ~= false
    e.FluxRaidContainer = frame("FluxRaidContainer", e.UIParent)
    e.FluxRaidContainer.shown = containerShown or false
    e.CompactRaidFrameContainer = frame("CompactRaidFrameContainer", e.UIParent)
    e.CompactRaidFrameContainer.shown = true
    loadModule("RaidFrame/FluxRaidCompat.lua", e, ns)
    loadModule("RaidFrame/FluxRaidLayout.lua", e, ns)
    loadModule("RaidFrame/FluxRaidFrame.lua", e, ns)
    e.FluxRaid_InitLayoutFrames()
    e.FluxRaidState.isInitialized = true
    function s:configure() e.FluxRaid_ApplyOptionsFromDB() end
    function s:flush()
        local timers = self.timers; self.timers = {}
        for _, fn in ipairs(timers) do fn() end
    end
    function s:growInCombat()
        self.combat, self.roster, self.mtma = true, 5, 40
        for _, header in ipairs(self.headers) do
            if header:IsVisible() then nativeUpdate(header) end
        end
    end
    function s:revealAncestor(inCombat)
        self.combat = inCombat
        -- Native/user UIParent reveal is not a Flux protected widget mutation.
        e.UIParent.shown = true
        synchronizeVisibility()
    end
    function s:registerEvents()
        self.eventFrame = e.CreateFrame("Frame", "FluxReadinessEventFrame", e.UIParent)
        e.FluxRaid_OnLoad(self.eventFrame)
        return self.eventFrame
    end
    function s:installPetBattle()
        e.C_PetBattles, e.SecureHandlerStateTemplate = {}, {}
        e.RegisterStateDriver = function(driver)
            self.driver = driver
            driver.attributes["state-groupupdate"] = "hide"
            for _, header in ipairs(self.headers) do header.shown = false end
            synchronizeVisibility()
        end
        assert(e.FluxRaid_InstallPetBattleDriver())
        self:registerEvents()
    end
    function s:petState(value)
        -- Native attribute-driver delivery is not a Flux protected mutation.
        self.driver.attributes["state-groupupdate"] = value
        if value == "hide" then
            for _, header in ipairs(self.headers) do header.shown = false end
            synchronizeVisibility()
        end
        self.driver.scripts.OnAttributeChanged(self.driver, "state-groupupdate", value)
        for _, fn in ipairs(self.driver.hooks.OnAttributeChanged or {}) do
            fn(self.driver, "state-groupupdate", value)
        end
    end
    function s:petClose() e.FluxRaid_OnEvent(self.eventFrame, "PET_BATTLE_CLOSE") end
    return e, s
end

for _, client in ipairs({ "retail", "forever", "era", "anniversary", "mists" }) do
    local e, s = fixture(client, true, true)
    s:configure(); s:flush()
    local initial = s.children
    check(e.FluxRaidState.secureConfigured and s.nativeHidden, "complete pools hand off native controls")
    check(not s:registerEvents().events.PET_BATTLE_CLOSE, "unsupported pet-battle capability registers no close event")
    check(#(e.FluxRaidContainer.hooks.OnShow or {}) == 1, "owned container installs one reveal retry hook")
    for index = 1, 8 do
        local header = e.FluxRaidState.raidHeaders[index]
        check(header:GetAttribute("child5") and not header:GetAttribute("child6"), client .. " group capacity is exactly five")
        check(header:GetAttribute("startingIndex") == 1, "group starting index restored")
    end
    local mtma = e.FluxRaidState.mtmaHeader
    check(mtma:GetAttribute("child40") and not mtma:GetAttribute("child41"), client .. " final MTMA capacity is forty")
    check(mtma:GetAttribute("unitsPerColumn") == 4 and mtma:GetAttribute("maxColumns") == 10
        and mtma:GetAttribute("startingIndex") == 1, "MTMA final layout preserved")
    s:configure(); s:flush()
    check(s.children == initial, "reconfiguration reuses complete native child pools")
    s:growInCombat()
    check(s.blocked == 0 and s.children == initial, client .. " roster growth requires no protected creation in combat")
    local writes = s.writes
    s:configure(); s:flush()
    check(s.writes == writes, "combat configuration defers protected mutations")
    print(string.format("raid precreation %s raid initialChildren=%d combatBlocked=%d", client, initial, s.blocked))

    -- This separates MTMA's final-capacity ordering from the hidden-parent bug.
    local shown, ss = fixture(client, true, true, true, true)
    ss:configure(); ss:flush()
    check(shown.FluxRaidState.mtmaHeader:GetAttribute("child40") ~= nil,
        "already-visible parent seeds MTMA after its final forty-slot layout")
    local shownInitial = ss.children
    ss:growInCombat()
    check(ss.blocked == 0 and ss.children == shownInitial, "MTMA growth does not create protected children")
    print(string.format("raid precreation %s visible-parent initialChildren=%d combatBlocked=%d", client, shownInitial, ss.blocked))

    local party, ps = fixture(client, false, true)
    ps:configure(); ps:flush()
    check(party.FluxRaidState.raidHeaders[1]:GetAttribute("child5") ~= nil, "party precreates five children under hidden startup container")
    check(ps.children == 5 and not party.FluxRaidState.mtmaHeader:GetAttribute("child1"), "party does not allocate unused raid/MTMA pools")
    ps:growInCombat()
    check(ps.blocked == 0, "party growth reuses precreated capacity")

    local disabled, ds = fixture(client, true, false)
    ds:configure(); ds:flush()
    check(ds.children == 0 and not disabled.FluxRaidContainer:IsShown(), "disabled raid painting never exposes or allocates headers")
    check(not ds.nativeHidden and ds.timersCreated == 0, "disabled profile does not schedule a readiness retry or hide native UI")

    local hidden, hs = fixture(client, true, true, false)
    hs:configure(); hs:flush()
    check(not hidden.FluxRaidState.raidHeaders[1]._fluxPrecreated
        and not hidden.FluxRaidState.mtmaHeader._fluxPrecreated, "hidden ancestor cannot falsely complete precreation")
    check(not hidden.UIParent:IsShown(), "precreation preserves an externally hidden UIParent")
    check(not hidden.FluxRaidState.secureConfigured and not hs.nativeHidden,
        "incomplete pools keep native fallback and readiness false")
    local shownHeaders = 0
    for _, header in ipairs(hs.headers) do if header:IsShown() then shownHeaders = shownHeaders + 1 end end
    check(shownHeaders == 0, "incomplete child pools keep every protected header hidden")
    hs:revealAncestor(false)
    check(#hs.timers <= 1, "ancestor reveal schedules at most one layout retry")
    hs:flush(); hs:flush()
    check(hidden.FluxRaidState.raidHeaders[1]:GetAttribute("child5")
        and hidden.FluxRaidState.mtmaHeader:GetAttribute("child40"), "incomplete hidden-ancestor pool retries when visible")
    check(hidden.FluxRaidState.secureConfigured and hs.nativeHidden,
        "OOC ancestor reveal automatically completes native handoff")

    local locked, ls = fixture(client, true, true, false)
    ls:configure(); ls:flush()
    local beforeRevealTimers = ls.timersCreated
    ls:revealAncestor(true); ls:flush()
    check(ls.blocked == 0 and ls.children == 0, "combat ancestor reveal never enters missing-child creation")
    check(not locked.FluxRaidState.secureConfigured and not ls.nativeHidden,
        "combat ancestor reveal retains native fallback")
    check(ls.timersCreated == beforeRevealTimers, "combat reveal uses deferred work without timers or polling")
    local queued = 0
    for _ in pairs(locked.FluxRaidState.pendingCombatWork) do queued = queued + 1 end
    check(queued == 1, "repeated readiness requests coalesce into one combat job")
    ls.combat = false
    locked.FluxRaid_OnEvent({}, "PLAYER_REGEN_ENABLED"); ls:flush(); ls:flush()
    check(locked.FluxRaidState.secureConfigured and ls.children == 80 and ls.nativeHidden,
        "regen creates the full pool then hands off native controls")
    local completedTimers = ls.timersCreated
    ls:flush(); ls:flush()
    check(#ls.timers == 0 and ls.timersCreated == completedTimers,
        "completed readiness leaves no self-scheduling retry")
    check(#(locked.FluxRaidContainer.hooks.OnShow or {}) == 1,
        "retries do not multiply reveal hooks")
    print(string.format("raid readiness %s ancestorCombatBlocked=%d recoveredChildren=%d", client, ls.blocked, ls.children))

    local battle, bs = fixture(client, true, true, false)
    bs:configure(); bs:flush(); bs:installPetBattle()
    check(bs.eventFrame.events.PET_BATTLE_CLOSE, "supported pet-battle capability registers the close event")
    local battleShows = bs.headerShows
    bs:revealAncestor(false); bs:flush()
    check(bs.headerShows == battleShows and bs.children == 0 and not bs.nativeHidden,
        "ancestor readiness reveal preserves the active battle hide state and native fallback")
    local timerCount = bs.timersCreated
    bs:petState("hide")
    check(bs.timersCreated == timerCount, "owned driver hide notifications do not schedule retries")
    bs:petClose(); bs:flush()
    check(bs.headerShows == battleShows and bs.children == 0 and not bs.nativeHidden,
        "close-event barrier cannot expose headers before the native state updates")
    local nativeCalls = bs.nativeStateCallbacks
    bs:petState("show")
    check(bs.nativeStateCallbacks == nativeCalls + 1
        and bs.driver:GetScript("OnAttributeChanged") == bs.nativeStateHandler,
        "readiness observer preserves the existing native state handler")
    check(bs.children == 0 and #bs.timers == 1, "delayed native show state queues one after-dispatch retry")
    bs:flush(); bs:flush()
    check(battle.FluxRaidState.secureConfigured and bs.children == 80 and bs.nativeHidden,
        "late native state update completes readiness and handoff after battle")
    check(#(bs.driver.hooks.OnAttributeChanged or {}) == 1,
        "owned state driver has one after-only readiness observer")

    local battleCombat, cs = fixture(client, true, true, false)
    cs:configure(); cs:flush(); cs:installPetBattle(); cs:revealAncestor(true)
    for _ = 1, 20 do cs:petClose() end
    cs:petState("show")
    check(#cs.timers == 1, "close/state-change burst shares the existing one pending timer")
    cs:flush()
    check(cs.children == 0 and cs.blocked == 0 and not cs.nativeHidden,
        "battle close in combat retains native fallback and defers construction")
    cs.combat = false
    battleCombat.FluxRaid_OnEvent(cs.eventFrame, "PLAYER_REGEN_ENABLED"); cs:flush(); cs:flush()
    check(battleCombat.FluxRaidState.secureConfigured and cs.children == 80 and cs.nativeHidden,
        "battle close in combat recovers automatically after regen")
    timerCount = cs.timersCreated
    cs:petClose(); cs:petState("show"); cs:flush()
    check(cs.timersCreated == timerCount and #cs.timers == 0, "completed battle readiness has no retry loop")

    local off, os = fixture(client, true, false, false)
    os:configure(); os:installPetBattle(); os:revealAncestor(false)
    timerCount = os.timersCreated
    os:petClose(); os:petState("show"); os:flush()
    check(not off.FluxRaidState.secureConfigured and os.children == 0 and os.headerShows == 0
        and not os.nativeHidden and os.timersCreated == timerCount,
        "disabled profile remains off through battle-close and native-state delivery")
end
print(string.format("raid header precreation: %d checks, %d failures", checks, failures))
if failures > 0 then os.exit(1) end
