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
        mtma = 1, children = 0, blocked = 0, timers = {}, headers = {}, writes = 0 }
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
    e.FluxOptions = { GetRaidFrameDB = function() return {} end }
    e.FluxRaidVisuals = { FRAME_WIDTH = 72, FRAME_HEIGHT = 43 }
    e.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    local ns = { Flux = { Timer = e.C_Timer } }
    local methods = {}
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:GetParent() return self.parent end
    function methods:GetName() return self.name end
    function methods:GetAttribute(key) return self.attributes[key] end
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
        for _, header in ipairs(s.headers) do
            local visible = header:IsVisible()
            if visible and not header.effectiveVisible then nativeUpdate(header) end
            header.effectiveVisible = visible
        end
    end
    function methods:SetAttribute(key, value)
        assert(not s.combat, "production writes protected attributes in combat")
        s.writes = s.writes + 1; self.attributes[key] = value
        if self.isHeader and self:IsVisible() then nativeUpdate(self) end
    end
    function methods:Show()
        assert(not s.combat, "production shows protected frame in combat")
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
        local f = setmetatable({ name = name, parent = parent, shown = false, attributes = {} }, { __index = methods })
        if name then e[name] = f end
        return f
    end
    function methods:CreateFontString() return frame(nil, self) end
    e.CreateFrame = function(_, name, parent, template)
        assert(not s.combat, "production creates headers in combat")
        local f = frame(name, parent)
        if template == "FluxRaidGroupHeaderTemplate" then f.isHeader = true; s.headers[#s.headers + 1] = f end
        return f
    end
    e.UIParent = frame("UIParent"); e.UIParent.shown = ancestorVisible ~= false
    e.FluxRaidContainer = frame("FluxRaidContainer", e.UIParent)
    e.FluxRaidContainer.shown = containerShown or false
    loadModule("RaidFrame/FluxRaidCompat.lua", e, ns)
    loadModule("RaidFrame/FluxRaidLayout.lua", e, ns)
    e.FluxRaid_InitLayoutFrames()
    e.FluxRaidState.isInitialized = true
    function s:configure() e.FluxRaid_QueueConfigureAndRefresh() end
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
    return e, s
end

for _, client in ipairs({ "retail", "forever", "era", "anniversary", "mists" }) do
    local e, s = fixture(client, true, true)
    s:configure(); s:flush()
    local initial = s.children
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

    local hidden, hs = fixture(client, true, true, false)
    hs:configure(); hs:flush()
    check(not hidden.FluxRaidState.raidHeaders[1]._fluxPrecreated
        and not hidden.FluxRaidState.mtmaHeader._fluxPrecreated, "hidden ancestor cannot falsely complete precreation")
    check(not hidden.UIParent:IsShown(), "precreation preserves an externally hidden UIParent")
    hidden.UIParent.shown = true
    hs:configure(); hs:flush()
    check(hidden.FluxRaidState.raidHeaders[1]:GetAttribute("child5")
        and hidden.FluxRaidState.mtmaHeader:GetAttribute("child40"), "incomplete hidden-ancestor pool retries when visible")
end
print(string.format("raid header precreation: %d checks, %d failures", checks, failures))
if failures > 0 then os.exit(1) end
