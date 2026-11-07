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

local function fixture(client, raid, enabled, ancestorVisible, containerShown, secureRoster)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local s = { combat = false, raid = raid, enabled = enabled, roster = 1,
        mtma = 1, children = 0, blocked = 0, timers = {}, headers = {}, frames = {}, writes = 0,
        nativeHidden = false, timersCreated = 0, headerShows = 0, nativeStateCallbacks = 0,
        group = true, secureSupported = true, secureLayoutSupported = true, secureCalls = {}, secureChildren = {}, secureLayoutCalls = 0, secureDisables = 0 }
    e.InCombatLockdown = function() return s.combat end
    e.IsInRaid = function() return s.raid end
    e.IsInGroup = function() return s.group end
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
        elseif not s.raid and s.group and attrs.showParty then count = s.roster end
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
    if secureRoster then
        function methods:SetPoint(...) self.point = { ... } end
        function methods:ClearAllPoints() self.point = nil end
        function methods:SetSize(w,h) self.width,self.height = w,h end
        function methods:SetWidth(value) self.width = value end
        function methods:SetHeight(value) self.height = value end
        function methods:SetAlpha(value) self.alpha = value end
    end
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
    if secureRoster then
        -- Dependency contract only. The separate secure module suite executes
        -- its actual wrappers and supplied native source. This fixture proves
        -- production Layout prepares/calls that service in the right order.
        e.FluxRaidSecure = {
            ConfigureHeader = function(header,index,isMTMA)
                assert(not s.combat, "secure header installation must defer in combat")
                if not s.secureSupported or s.secureFailIndex==index then header._fluxSecureRosterDriver=nil;header:Hide();return false end
                s.secureCalls[header] = { index=index, isMTMA=isMTMA }
                header:SetAttribute("showRaid",true)
                header:SetAttribute("showParty",not isMTMA and index==1)
                header:SetAttribute("showPlayer",true)
                header:SetAttribute("showSolo",false)
                header:SetAttribute("groupFilter",isMTMA and "MAINTANK,MAINASSIST" or tostring(index))
                header._fluxSecureRosterDriver = true
                if s.raid or (s.group and not isMTMA and index==1) then header:Show() else header:Hide() end
                return true
            end,
            AttachHeaderChild = function(child)
                assert(not s.combat,"secure child installation must defer in combat")
                if not s.secureSupported then return false end
                s.secureChildren[child] = true
                return true
            end,
            RefreshRosterLayout = function(container,groups,mt,options)
                assert(not s.combat,"secure roster layout installation must defer in combat")
                s.secureLayoutCalls = s.secureLayoutCalls+1
                if not s.secureLayoutSupported then return false end
                s.secureLayout = {container=container,groups=groups,mt=mt,options=options}
                return true
            end,
            DisableHeader = function(header)
                assert(not s.combat,"secure header disable must defer in combat")
                s.secureDisables = s.secureDisables+1
                header._fluxSecureRosterDriver = nil
                header:Hide()
                return true
            end,
        }
    end
    -- Native driver functions exist before addons load and may be captured in
    -- module locals. Pet-battle availability is toggled separately below.
    e.RegisterStateDriver = function(driver)
        s.driver = driver
        driver.attributes["state-groupupdate"] = "hide"
        for _, header in ipairs(s.headers) do header.shown = false end
        synchronizeVisibility()
    end
    local nativeDriver = e.RegisterStateDriver
    loadModule("RaidFrame/FluxRaidCompat.lua", e, ns)
    loadModule("RaidFrame/FluxRaidLayout.lua", e, ns)
    loadModule("RaidFrame/FluxRaidFrame.lua", e, ns)
    check(e.RegisterStateDriver == nativeDriver, "raid modules preserve native state-driver identity")
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

-- Universal roster ownership: production Layout plus the secure service's
-- explicit dependency contract. All earlier fallback cases remain unchanged.
for _,client in ipairs({"retail","forever","era","anniversary","mists"}) do
    for _,mode in ipairs({"raid","party","solo"}) do
        local e,s=fixture(client,mode=="raid",true,true,false,true)
        s.group=mode~="solo"
        s:configure();s:flush();s:flush()
        check(e.FluxRaidState.secureConfigured and s.children==80,
            client.." "..mode..": all forty member and forty MT/MA children prepare OOC")
        check(e.FluxRaidContainer:IsShown(),client.." "..mode..": enabled parent remains shown for secure future roster transitions")
        local attached=0
        for _ in pairs(s.secureChildren) do attached=attached+1 end
        check(attached==80,client.." "..mode..": every allocated child joins secure roster updates")
        for index=1,8 do
            local header=e.FluxRaidState.raidHeaders[index]
            local call=s.secureCalls[header]
            check(call and call.index==index and not call.isMTMA,
                client.." "..mode..": secure group controller receives stable group identity")
            check(header:GetAttribute("child5") and not header:GetAttribute("child6"),"universal member columns retain five-cell capacity")
            check(header:GetAttribute("showRaid")==true and header:GetAttribute("showParty")== (index==1)
                and header:GetAttribute("showPlayer")==true and header:GetAttribute("showSolo")==false,
                "all group roster modes are prepared without later Lua rewrites")
            check(header:GetAttribute("groupFilter")==tostring(index)
                and header:GetAttribute("unitsPerColumn")==5 and header:GetAttribute("maxColumns")==1
                and header:GetAttribute("sortMethod")=="INDEX" and header:GetAttribute("sortDir")=="ASC"
                and header:GetAttribute("minWidth")==72 and header:GetAttribute("yOffset")==4,
                "secure ownership preserves grouping/order/size and applies requested four-pixel member overlap")
            check(header._fluxSecureRosterDriver==true,"ordinary visibility refresh preserves secure controller ownership")
        end
        local mt=e.FluxRaidState.mtmaHeader
        check(s.secureCalls[mt]and s.secureCalls[mt].isMTMA and mt:GetAttribute("child40")and not mt:GetAttribute("child41"),
            "MT/MA controller owns its full forty-cell pool in every startup roster mode")
        check(mt:GetAttribute("unitsPerColumn")==4 and mt:GetAttribute("maxColumns")==10
            and mt:GetAttribute("yOffset")==-10 and mt:GetAttribute("groupFilter")=="MAINTANK,MAINASSIST"
            and mt._fluxSecureRosterDriver==true,"MT/MA geometry and controller ownership survive normal refresh")
        local layout=s.secureLayout
        check(layout and layout.container==e.FluxRaidContainer and layout.groups==e.FluxRaidState.raidHeaders and layout.mt==mt,
            "production integration passes the existing container and all real headers to secure layout")
        if layout and layout.options then
            check(layout.options.colStep==72 and layout.options.columnHeight==199 and layout.options.mtChildStep==53,
                "secure layout receives requested overlap while retaining current member and target heights")
        end
        local reverse=e.FluxRaidCompat.BuildVisibleGroupsReverse(function(g)return g==1 or g==4 or g==8 end)
        local geometry=e.FluxRaidCompat.ComputeReverseColumnLayout(reverse,true,5,74)
        check(reverse[1]==8 and reverse[2]==4 and reverse[3]==1 and geometry.groupX[1]>geometry.groupX[4]
            and geometry.groupX[4]>geometry.groupX[8] and geometry.xMT<geometry.groupX[8],
            "universal ownership retains reverse group columns and MT/MA placement")
        local initial=s.children
        s:configure();s:flush()
        check(s.children==initial and e.FluxRaidContainer:IsShown(),"reconfiguration reuses the universal pool and preserves the active parent")
        local writes=s.writes
        s:growInCombat();s:configure();s:flush()
        check(s.children==initial and s.blocked==0 and s.writes==writes,
            "combat roster/configuration growth neither allocates nor rewrites protected header attributes")
        s.combat=false;s.enabled=false;s:configure();s:flush()
        local active=0
        for _,header in ipairs(s.headers) do if header._fluxSecureRosterDriver or header:IsShown()then active=active+1 end end
        check(s.children==initial and active==0 and not e.FluxRaidContainer:IsShown()and s.secureDisables>=9,
            "disabling Flux retires every secure header controller and preserves allocated pools")
    end
    local off,os=fixture(client,true,false,true,false,true)
    os:configure();os:flush()
    check(os.children==0 and next(os.secureCalls)==nil and os.secureLayoutCalls==0 and not off.FluxRaidContainer:IsShown(),
        client..": disabled startup installs no secure roster ownership or child pools")
    local unsupported,us=fixture(client,false,true,true,false,true)
    us.secureSupported=false;us:configure();us:flush();us:flush()
    local visible=0
    for _,header in ipairs(us.headers)do if header._fluxSecureRosterDriver or header:IsShown()then visible=visible+1 end end
    check(not unsupported.FluxRaidState.secureRosterPrepared and not unsupported.FluxRaidState.secureConfigured
        and not us.nativeHidden and visible==0,
        client..": unavailable secure service retains native fallback and hides unowned headers")
    local prepared=us.children
    us.secureSupported=true;us:configure();us:flush();us:flush()
    check(unsupported.FluxRaidState.secureRosterPrepared and unsupported.FluxRaidState.secureConfigured
        and us.nativeHidden and us.children==prepared,
        client..": OOC capability recovery installs controllers without reallocating prepared pools")
    local partial,fs=fixture(client,false,true,true,false,true)
    fs.secureFailIndex=8;fs:configure();fs:flush();fs:flush()
    local armed=0
    for _,header in ipairs(fs.headers)do if header._fluxSecureRosterDriver then armed=armed+1 end end
    check(not partial.FluxRaidState.secureConfigured and not fs.nativeHidden and armed==0,
        client..": partial controller failure retires successful peers before retaining native fallback")
    local noLayout,ns=fixture(client,false,true,true,false,true)
    ns.secureLayoutSupported=false;ns:configure();ns:flush();ns:flush()
    armed=0
    for _,header in ipairs(ns.headers)do if header._fluxSecureRosterDriver then armed=armed+1 end end
    check(ns.secureLayoutCalls>0 and not noLayout.FluxRaidState.secureConfigured and not ns.nativeHidden and armed==0,
        client..": failed secure roster layout cannot claim readiness or replace native UI")
end
print(string.format("raid header precreation: %d checks, %d failures", checks, failures))
if failures > 0 then os.exit(1) end
