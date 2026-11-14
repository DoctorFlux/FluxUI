-- lua tests/unit_debuff_group_overlap.lua [engine source] [native source root]
-- The screenshot/user establish a duplicate effect, not its instance IDs or
-- native filter results. Model an overlapping system-aura result explicitly;
-- this is a regression for that case, not a reproduction of Blizzard's C code.
local function read(path)
    local f = assert(io.open(path, "rb"))
    local text = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return text
end
local engineSource = read(arg[1] or "UnitFrames/FluxUnitFrames_AurasEngine.lua")
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end
local function setup(client, unit, rejectSplit, kind)
    local frames = {}
    local e = setmetatable({
        WOW_PROJECT_ID = 1, WOW_PROJECT_MAINLINE = 1,
        C_AddOns = {IsAddOnLoaded = function() return true end},
        InCombatLockdown = function() return false end,
        AuraUtil = {
            AuraFilterNegationPrefix = "!",
            AuraFilters = {Harmful = "HARMFUL", Player = "PLAYER", IncludeNameplateOnly = "INCLUDE_NAME_PLATE_ONLY"},
            CreateFilterString = function(...) return table.concat({...}, "|") end,
        },
        AuraContainerSortMethod = {Default = 0, UnitFrameDebuff = 1},
        AuraContainerSortDirection = {Normal = 0},
        AnchorUtil = {FlowDirection = {Right = 1, Left = 2, Up = 3, Down = 4}},
        -- Production must leave enumeration and aura-data access with Blizzard.
        C_UnitAuras = setmetatable({}, {__index = function() error("addon aura-data query") end}),
    }, {__index = _G})
    local ns = {Flux = {Client = {majorVersion = 12, isForever = client == "forever"}}}
    local function loadModule(text, name) return assert(load(text, name, "t", e))("_FluxUI", ns) end
    loadModule(read("UnitFrames/FluxUnitFrames_AurasOwn.lua"), "@actual-own-debuff-policy")
    local frame = {unit = unit}
    local container = {containerType = kind or "Debuff", maxAuras = 16, buttons = {}, _fluxAuraBaseSize = 22}
    function container:GetName() return "TestDebuffs" end
    function container:GetParent() return frame end
    function container:GetFrameLevel() return 1 end
    function container:GetWidth() return 150 end
    function container:SetClipsChildren() end
    e.CreateFrame = function(kind, name, parent, template)
        check(kind == "AuraContainer" and template == "CustomAuraContainerTemplate", "native widget retained")
        local box = {groups = {}, parent = parent}
        function box:AddAuraGroup(key, filter, options)
            if rejectSplit and key == "other" then error("unsupported negation") end
            self.groups[key] = {filter = filter, options = options}
        end
        function box:HasAuraGroup(key) return self.groups[key] ~= nil end
        function box:SetUnit(token) self.unit = token end
        function box:SetEnabled(value) self.enabled = value end
        function box:UpdateAllAuras() self.refreshes = (self.refreshes or 0) + 1 end
        function box:SetAuraGroupLayout(key, layout) self.groups[key].options.layout = layout end
        function box:SetAuraGroupMaxFrameCount(key, count) self.groups[key].options.maxFrameCount = count end
        function box:GetAuraGroupFrameCount() return 0 end
        function box:SetParent(value) self.parent = value end
        function box:Hide() self.shown = false end
        function box:Show() self.shown = true end
        function box:SetPoint() end
        function box:SetClipsChildren() end
        function box:SetFrameLevel() end
        function box:SetFlowLayoutAnchorPoint() end
        function box:SetFlowLayoutGrowthDirection() end
        function box:SetFlowLayoutPadding() end
        function box:SetFlowLayoutMaximumLineSize() end
        frames[#frames + 1] = box
        return box
    end
    loadModule(engineSource, "@actual-unit-aura-engine")
    -- Execute Blizzard's actual candidate predicate. It runs inside the native
    -- widget; the addon only submits options, including under aura restrictions.
    local base = arg[2] and (arg[2] .. "/" .. client) or ("../__AddonsForRef/wow-ui-source-" .. client)
    local path = base .. "/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua"
    local native = read(path)
    e.AuraContainerUtil = {CanApplyIdentityCandidateFilters = function() return false end}
    local fn = assert(native:match("function AuraContainerUtil%.DoesAuraPassCandidateFilters%b().-\nend"))
    assert(load(fn, "@native-candidate-predicate-" .. client, "t", e))()
    local uf = ns.UnitFrames
    check(uf.AttachEngineAuras(container, frame), "engine attachment succeeds")
    return uf, container, frame, frames, e.AuraContainerUtil.DoesAuraPassCandidateFilters
end
for _, client in ipairs({"live", "forever"}) do
    for _, unit in ipairs({"target", "focus"}) do
        local uf, panel, frame, frames, nativeAccepts = setup(client, unit)
        local box, groups = panel._fluxEngine, panel._fluxEngine.groups
        check(groups.own and groups.other and not groups.all, "two normal groups retained")
        check(groups.own.filter == "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY", "exact self/pet/vehicle filter retained")
        check(groups.other.filter == "HARMFUL|!PLAYER|INCLUDE_NAME_PLATE_ONLY", "other players remain in other group")
        check(groups.own.options.layout.elementHeight > groups.other.options.layout.elementHeight, "own size emphasis retained")
        local function displayed(id, fromPlayer, ownMatch, otherMatch)
            local aura = {auraInstanceID = id, spellId = 100, icon = 200, isFromPlayerOrPlayerPet = fromPlayer}
            local count = 0
            if ownMatch and nativeAccepts(unit, aura, groups.own.options.candidateFilters) then count = count + 1 end
            if otherMatch and nativeAccepts(unit, aura, groups.other.options.candidateFilters) then count = count + 1 end
            return count
        end
        -- Same instance returned for both ownership queries: a non-player system
        -- effect must have only its ordinary icon. No spell/icon deduplication.
        check(displayed(1, false, true, true) == 1, "overlapping system effect appears once")
        check(displayed(2, nil, true, true) == 1, "missing system caster cannot enter own group")
        for _, caster in ipairs({"player", "pet", "vehicle"}) do
            check(displayed(3, true, true, false) == 1, caster .. " retains its larger own icon")
        end
        check(displayed(4, true, false, true) == 1, "another player's debuff remains visible")
        check(displayed(5, false, false, true) == 1, "NPC debuff remains visible")
        check(displayed(6, true, true, false) + displayed(7, true, false, true) == 2,
            "separate same-spell/same-icon instances from different casters survive")
        check(groups.other.options.candidateFilters == nil, "other group does not exclude player-cast auras")
        local allocations = #frames
        uf.SyncEngineAuras(panel, frame)
        check(#frames == allocations and panel._fluxEngine == box, "refresh reuses native widget/groups")
        frame.unit = "target"
        uf.PokeEngineAuras(panel, frame)
        check(box.unit == "target", "existing unit rebinding retained")
        local _, fallback, _, oldFrames = setup(client, unit, true)
        check(fallback._fluxEngine.groups.all and not fallback._fluxEngine.groups.own, "unsupported split keeps full harmful fallback")
        check(#oldFrames == 2 and oldFrames[1].shown == false, "partial native engine stays hidden")
        local _, buffs = setup(client, unit, false, "Buff")
        check(buffs._fluxEngine.groups.buffs.filter == "HELPFUL" and buffs._fluxEngine.groups.buffs.options.candidateFilters == nil,
            "buffs retain every caster and their existing native group")
    end
end
print("Unit debuff group overlap: " .. checks .. " checks passed; simulated filter overlap; native acceptance pending")
