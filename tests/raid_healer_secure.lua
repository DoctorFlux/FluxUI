-- Run with FLUX_RAID_UPSTREAM_CACHE pointing at the commit-pinned task cache
-- for exact current-source evidence; sibling supplied snapshots are the fallback.
-- Executes native wrap/state/unit-click handlers and group roster implementation.
-- Desktop secure mocks cannot certify native hardware input, taint or frame time.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local cache = os.getenv("FLUX_RAID_UPSTREAM_CACHE")
local function read(path)
    local f = assert(io.open(path, "rb"), path); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local checks = 0
local function check(value, why) assert(value, why) checks = checks + 1 end
local function nativePath(client, file)
    return (cache and cache .. "/" .. client .. "/" or root .. "../__AddonsForRef/wow-ui-source-" .. client .. "/") .. "Interface/AddOns/" .. file
end
local function fixture(client, options)
    options = options or {}
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.combat, e.depth, e.mode, e.partyCount, e.raidRoster = false, 0, "solo", 0, {}
    e.writes, e.created, e.drivers, e.parentCalls = 0, 0, {}, 0
    e.targetDrivers, e.missingTargets, e.targetDriverRegistrations = {}, {}, 0
    e.InCombatLockdown = function() return e.combat end
    local function legal() assert(not e.combat or e.depth > 0, "insecure protected mutation in combat"); e.writes = e.writes + 1 end
    local function secure(fn, ...)
        local previous = e.depth; e.depth = previous + 1
        local result = { pcall(fn, ...) }; e.depth = previous
        assert(result[1], result[2]); return table.unpack(result, 2)
    end
    local function execute(header, frame, signature, body, ...)
        local env = setmetatable({ control = header, newtable = function() return {} end }, { __index = e })
        local fn = assert(load("return function(" .. signature .. ")\n" .. body .. "\nend", "@restricted-" .. client, "t", env))()
        return secure(fn, frame, ...)
    end
    e.SecureHandler_Other_Execute = function(header, frame, signature, body, ...) return execute(header, frame, signature, body, ...) end
    e.SecureHandler_Self_Execute = function(frame, signature, body, ...) return execute(frame, frame, signature, body, ...) end
    e.IsWrapEligible = function() return true end
    e.securecall = function(fn, ...) return fn(...) end
    e.SafeCallWrappedHandler = function(frame, old, ...)
        if not old then return end
        local previous = e.depth; e.depth = 0
        local result = { pcall(old, frame, ...) }; e.depth = previous
        assert(result[1], result[2])
    end
    local native = read(nativePath(client, "Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua"))
    local wrap = assert(native:match("local function Wrapped_Attribute%(.-\nend"))
    local nativeWrap = assert(load(wrap .. "\nreturn Wrapped_Attribute", "@native-attribute-wrapper-" .. client, "t", e))()
    local nativeShowHide = assert(load(assert(native:match("local function CreateSimpleWrapper%(.-\nend")) .. "\nreturn CreateSimpleWrapper(\"self\", \"self,message\")", "@native-showhide-wrapper-" .. client, "t", e))()
    assert(load(assert(native:match("function SecureHandler_StateOnAttributeChanged%(.-\nend")), "@native-state-handler-" .. client, "t", e))()
    local stateSource = read(nativePath(client, "Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua"))
    local resolveDriver = assert(load(assert(stateSource:match("local function resolveDriver%(.-\nend"))
        .. "\nreturn resolveDriver", "@native-state-resolver-" .. client, "t", e))()
    e.SecureCmdOptionParse = function(condition)
        local unit = condition:match("%[@(raid%d+target),exists%]")
        if unit then return e.missingTargets[unit] and "hide" or "show" end
        return "hide"
    end
    e.RefreshTargetExistence = function()
        secure(function()
            for frame, drivers in pairs(e.targetDrivers) do
                for state, condition in pairs(drivers) do resolveDriver(frame, "state-" .. state, condition) end
            end
        end)
    end
    local methods = {}
    function methods:GetAttribute(key) return self.attrs[key] end
    function methods:SetAttribute(key, value)
        legal(); self.attrs[key] = value
        if self.scripts.OnAttributeChanged then self.scripts.OnAttributeChanged(self, key, value) end
    end
    function methods:SetFrameRef(key, frame) assert(not e.combat and frame and frame.protected, "invalid secure frame reference"); self.refs[key] = frame end
    function methods:GetFrameRef(key) return self.refs[key] end
    function methods:RunAttribute(key, ...) return execute(self, self, "self,...", assert(self.attrs[key]), ...) end
    function methods:Execute(body) return execute(self, self, "self", body) end
    function methods:WrapScript(frame, event, body)
        assert(not e.combat)
        if options.wrapError then error("unsupported wrapper") end
        if options.inert then return end
        local old = frame.scripts[event]
        local dispatch = event == "OnAttributeChanged" and nativeWrap or nativeShowHide
        frame.scripts[event] = function(f, ...) return dispatch(f, self, body, nil, old, ...) end
        frame.wrapCount = (frame.wrapCount or 0) + 1
    end
    function methods:SetScript(event, fn) self.scripts[event] = fn end
    function methods:GetScript(event) return self.scripts[event] end
    function methods:GetName() return self.name end
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:IsProtected() return true, true end
    function methods:SetAlpha(value) legal(); self.alpha = value end
    function methods:Show()
        legal(); local was = self.shown; self.shown = true
        if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:Hide()
        legal(); local was = self.shown; self.shown = false
        if was and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:EnableMouse(value) legal(); self.mouse = value end
    function methods:SetPoint(...) legal(); self.point = { ... }; if self.point[2]=="$parent" then self.point[2]=self.parent end end
    function methods:ClearAllPoints() legal(); self.point = nil end
    function methods:GetWidth() return self.width or 72 end
    function methods:GetHeight() return self.height or 43 end
    function methods:SetWidth(value) legal(); self.width = value end
    function methods:SetHeight(value) legal(); self.height = value end
    e.CreateFrame = function(_, name, parent, template)
        assert(not e.combat, "combat allocated a frame"); e.created = e.created + 1
        local f = setmetatable({ name = name, parent = parent, attrs = {}, refs = {}, scripts = {}, protected = true, shown = false }, { __index = methods })
        if template == "SecureHandlerStateTemplate" then f.scripts.OnAttributeChanged = e.SecureHandler_StateOnAttributeChanged end
        return f
    end
    local ns = { Flux = {} }
    ns.Flux.Restricted = {
        Works = function() return client ~= "forever" end,
        PagingWorks = function() return not options.unsupported end,
        WrapScript = function(h, f, event, body)
            if client == "forever" then return false end
            return pcall(h.WrapScript, h, f, event, body)
        end,
        SetPagingSnippet = function(h, key, body) h:SetAttribute(key, body); return true end,
        ExecutePaging = function(h, body) return pcall(h.Execute, h, body) end,
        RegisterPagingDriver = function(h, state, condition)
            if state:match("^mt%-target%d+$") then
                assert(not e.combat)
                if options.targetDriverFailure and state=="mt-target7" then return false end
                local drivers = e.targetDrivers[h] or {}; e.targetDrivers[h] = drivers
                drivers[state] = condition
                e.targetDriverRegistrations = e.targetDriverRegistrations + 1
                secure(resolveDriver, h, "state-" .. state, condition)
                return true
            end
            assert(not e.combat); e.drivers[h] = { state = state, condition = condition }; return true
        end,
        UnregisterPagingDriver = function(h,state)
            assert(not e.combat)
            if state and state:match("^mt%-target%d+$") then
                if e.targetDrivers[h] then e.targetDrivers[h][state]=nil end
            else e.drivers[h] = nil end
            return true
        end,
    }
    assert(loadfile(root .. "RaidFrame/FluxRaidSecure.lua", "t", e))("_FluxUI", ns)
    e.resolveDriver = resolveDriver
    return e, secure, execute
end

local function exercise(client)
    local e, secure = fixture(client)
    local S = e.FluxRaidSecure
    local parent, target = e.CreateFrame("Button", "MT"), e.CreateFrame("Button", "MTTarget")
    local observations = {}
    parent:Show()
    parent.attrs.unit = "raid2"
    parent.scripts.OnAttributeChanged = function(self, name)
        if name == "unit" then
            e.parentCalls = e.parentCalls + 1
            observations[#observations + 1] = target:GetAttribute("unit")
        end
    end
    target.attrs["*type1"], target.attrs.type2 = "target", "togglemenu"
    local hides = 0
    target.scripts.OnHide = function() hides = hides + 1 end
    target.scripts.OnAttributeChanged = function(self, name, value) if name == "unit" then self.unit = value end end
    check(S.AttachTarget(parent, target), client .. ": operational secure target attachment")
    check(e.targetDriverRegistrations==40,client..": target-existence conditions are prepared once per raid token")
    check(target.attrs.unit == "raid2target" and target.unit == "raid2target", client .. ": initial secure and presentation units agree")
    local wraps = parent.wrapCount
    check(S.AttachTarget(parent, target) and parent.wrapCount == wraps, client .. ": idempotent target attachment")
    e.combat = true
    local created = e.created
    secure(parent.SetAttribute, parent, "unit", "raid7")
    check(target.attrs.unit == "raid7target" and target.unit == "raid7target" and observations[1] == "raid7target", client .. ": secure unit moves before ordinary parent callback")
    secure(parent.SetAttribute, parent, "unrelated", "raid9")
    check(target.attrs.unit == "raid7target" and e.parentCalls == 1, client .. ": unrelated attributes preserve target identity and old callback")
    -- Exercise this client's actual native click handler.
    local native = read(nativePath(client, "Blizzard_FrameXML/SecureTemplates.lua"))
    local first = assert(native:find("function SecureUnitButton_OnClick", 1, true))
    local actions = {}
    e.SecureButton_GetModifiedAttribute = function(f, key, button)
        local suffix = button == "LeftButton" and "1" or "2"
        return f.attrs[key .. suffix] or f.attrs["*" .. key .. suffix]
    end
    e.SecureButton_GetModifiedUnit = function(f) return f.attrs.unit end
    e.SpellIsTargeting = function() return false end
    e.OnActionButtonClick = function(f, button)
        actions[#actions + 1] = { kind = e.SecureButton_GetModifiedAttribute(f, "type", button), unit = f.attrs.unit, macro = f.attrs.macrotext1 }
    end
    e.Enum = { ClickBindingType = { None = 0, Spell = 1, Macro = 2, Interaction = 3, PetAction = 4 } }
    e.MakeModifiers = function() return 0 end
    e.C_ClickBindings = { GetBindingType = function() return 3 end, GetEffectiveInteractionButton = function(button) return button end }
    assert(load(native:sub(first), "@native-unit-click-" .. client, "t", e))()
    e.SecureUnitButton_OnClick(target, "LeftButton", false)
    e.SecureUnitButton_OnClick(target, "RightButton", false)
    check(actions[1].kind == "target" and actions[1].unit == "raid7target" and actions[2].kind == "togglemenu" and actions[2].unit == "raid7target", client .. ": native target and menu use reassigned mini unit")
    local hideBefore=hides
    e.missingTargets.raid7target=true;e.RefreshTargetExistence()
    check(not target.shown and hides==hideBefore+1,client..": disappearing combat target hides its actual secure input rectangle")
    e.missingTargets.raid7target=nil;e.RefreshTargetExistence()
    check(target.shown,client..": reappearing combat target restores prepared input without allocation")
    e.combat = false
    target:SetAttribute("type1", "macro"); target:SetAttribute("macrotext1", "/cast [@mouseover,help,nodead] Heal")
    e.combat = true
    secure(parent.SetAttribute, parent, "unit", "raid8")
    e.SecureUnitButton_OnClick(target, "LeftButton", false)
    check(actions[3].kind == "macro" and actions[3].unit == "raid8target" and actions[3].macro == "/cast [@mouseover,help,nodead] Heal", client .. ": secure rebind preserves Flux macro program and current identity")
    secure(parent.SetAttribute, parent, "unit", nil)
    check(target.attrs.unit == nil and not target.shown and hides == hideBefore+2 and target.unit == nil, client .. ": combat unbind clears identity and hides mini for hover cleanup")
    secure(parent.SetAttribute, parent, "unit", "raid3")
    check(target.attrs.unit == "raid3target" and target.shown and e.created == created, client .. ": combat reassignment reuses the prepared button")
    secure(parent.Hide, parent)
    check(not target.shown, client .. ": hidden MTMA source hides its sibling mini securely")
    secure(parent.Show, parent)
    check(target.shown and target.attrs.unit == "raid3target", client .. ": shown source restores mini on its current unit")
    local writes = e.writes
    check(not S.AttachTarget({}, {}) and e.writes == writes, client .. ": unprepared combat attachment makes no protected writes")

    e.combat = false
    local extraTargets,extraParents={},{}
    for index=1,40 do
        local p,t=e.CreateFrame("Button","ReuseParent"..index),e.CreateFrame("Button","ReuseTarget"..index)
        p.attrs.unit="raid"..index;p:Show()
        check(S.AttachTarget(p,t),client..": preallocated target uses shared existence states")
        extraParents[index],extraTargets[index]=p,t
    end
    check(e.targetDriverRegistrations==40,client..": forty minis reuse40 conditions rather than1600 subscriptions")
    e.combat=true
    e.missingTargets.raid6target=true;e.RefreshTargetExistence()
    check(not extraTargets[6].shown and extraTargets[5].shown,client..": existence callback only hides matching target tokens")
    secure(extraParents[6].Hide,extraParents[6])
    e.missingTargets.raid6target=nil;e.RefreshTargetExistence()
    check(not extraTargets[6].shown,client..": target appearance cannot expose a hidden source mini")
    secure(extraParents[6].Show,extraParents[6])
    check(extraTargets[6].shown,client..": parent reveal reads the prepared native existence state")
    e.missingTargets.raid6target=true;e.RefreshTargetExistence()
    secure(extraParents[5].SetAttribute,extraParents[5],"unit","raid6")
    check(not extraTargets[5].shown,client..": secure reassignment to a missing target stays hidden")
    e.missingTargets.raid6target=nil;e.RefreshTargetExistence()
    check(extraTargets[5].shown and extraTargets[6].shown,client..": reappearance restores all views of one target identity")
    secure(extraParents[5].SetAttribute,extraParents[5],"unit","party1")
    check(not extraTargets[5].shown,client..": MTMA-only watch rejects non-raid source tokens safely")
    e.combat=false
    local function split(delimiter, text)
        local result = {}; for part in (text .. delimiter):gmatch("(.-)" .. delimiter) do result[#result + 1] = part end
        return table.unpack(result)
    end
    e.strsplit, e.unpack = split, table.unpack
    e.table = setmetatable({ wipe = function(t) for k in pairs(t) do t[k] = nil end return t end }, { __index = table })
    e.string = setmetatable({ trim = function(s) return s:match("^%s*(.-)%s*$") end }, { __index = string })
    e.IsInRaid = function() return e.mode == "raid" end
    e.IsInGroup = function() return e.mode ~= "solo" end
    e.GetNumGroupMembers = function() return e.mode == "raid" and #e.raidRoster or e.partyCount + 1 end
    e.GetNumSubgroupMembers = function() return e.partyCount end
    e.UnitExists = function(unit)
        if unit:match("^raid%d+target$") then return not e.missingTargets[unit] end
        local raid = tonumber(unit:match("^raid(%d+)$"))
        if raid then return e.mode == "raid" and (e.raidRoster[raid] ~= nil or raid == 1) end
        return unit == "player" or unit:match("^party%d$") and tonumber(unit:match("%d")) <= e.partyCount
    end
    e.SecureCmdOptionParse = assert(loadfile(root .. "tests/support/group_condition_parser.lua"))()({
        exists = function(unit) return e.UnitExists(unit) end,
        petbattle = function() return e.petbattle end,
        group = function() return e.mode end,
    })
    e.UnitName = function(unit)
        local index=type(unit)=="string" and tonumber(unit:match("^raid(%d+)$"))
        local row=index and e.raidRoster[index]
        if row then return row.name or("Member"..index),"" end
        return unit=="player" and "ZuluPlayer" or(unit=="party1"and "AlphaParty" or unit),""
    end
    e.UnitClass = function() return "Warrior", "WARRIOR" end
    e.UnitGroupRolesAssigned = function() return "DAMAGER" end
    e.GetPartyAssignment = function() return false end
    e.GetRaidRosterInfo = function(i)
        local r = e.raidRoster[i]; if not r then return nil end
        return r.name or("Member" .. i), nil, r.group, nil, nil, "WARRIOR", nil, nil, nil, r.mt and "MAINTANK", nil, "DAMAGER"
    end
    assert(load(read(nativePath(client, "Blizzard_RestrictedAddOnEnvironment/SecureGroupHeaders.lua")), "@native-group-header-" .. client, "t", e))()
    local container, groups = e.CreateFrame("Frame", "Container"), {}
    local function group(name, capacity)
        local h = e.CreateFrame("Frame", name)
        h.attrs.unitsPerColumn, h.attrs.maxColumns = capacity == 40 and 4 or 5, capacity == 40 and 10 or 1
        h.attrs.columnAnchorPoint, h.attrs.columnSpacing = "LEFT", 2
        h.attrs.sortMethod, h.attrs.sortDir, h.attrs.yOffset = "INDEX", "ASC", capacity == 40 and -1 or 4
        for i = 1, capacity do
            local child = e.CreateFrame("Button", name .. "Child" .. i, h)
            h.attrs["child" .. i], h.refs["child" .. i] = child, child
            check(S.AttachHeaderChild(child), client .. ": precreated native child wraps")
        end
        h.scripts.OnShow = e.SecureGroupHeader_Update
        return h
    end
    for i = 1, 8 do groups[i] = group("Group" .. i, 5); check(S.ConfigureHeader(groups[i], i, false), client .. ": static group driver prepared") end
    local mt = group("MTMA", 40)
    check(S.ConfigureHeader(mt, nil, true), client .. ": MTMA raid-only driver prepared")
    check(S.RefreshRosterLayout(container, groups, mt, { colStep = 74, columnHeight = 215, mtChildStep = 66 }), client .. ": secure dynamic reverse layout prepared")
    local function roster(mode, partyCount, rows, petbattle)
        e.mode, e.partyCount, e.raidRoster, e.petbattle = mode, partyCount or 0, rows or {}, petbattle
        secure(function()
            for controller, driver in pairs(e.drivers) do
                e.resolveDriver(controller, "state-" .. driver.state, driver.condition)
            end
            for _, h in ipairs(groups) do e.SecureGroupHeader_OnEvent(h, "GROUP_ROSTER_UPDATE") end
            e.SecureGroupHeader_OnEvent(mt, "GROUP_ROSTER_UPDATE")
        end)
    end
    e.combat = true; created = e.created
    roster("solo")
    check(not groups[1].shown and not mt.shown, client .. ": solo hides all prepared headers")
    secure(function() container:Hide() end)
    roster("party", 4)
    check(container:IsShown(), client .. ": native group driver reveals the owned hidden parent during combat")
    check(groups[1].shown and groups[1].attrs.child1.attrs.unit == "player" and groups[1].attrs.child5.attrs.unit == "party4", client .. ": joining party mid-combat reveals native five-member roster")
    local firstChild, secondChild = groups[1].attrs.child1, groups[1].attrs.child2
    local firstTop = firstChild.point[3] == "TOP" and 0 or nil
    local secondTop = firstTop - firstChild:GetHeight() + secondChild.point[5]
    check(secondChild.point[2] == firstChild and secondChild.point[3] == "BOTTOM" and secondTop == -39,
        client .. ": native header offsets resolve to39pixel member steps and4pixel overlap")
    check(not groups[2].shown and not mt.shown and groups[1].point[4] == 592, client .. ": party keeps group1 at existing rightmost dock")
    roster("raid", 0, { { group = 1, mt = true }, { group = 3 }, { group = 3 } })
    check(groups[1].attrs.child1.attrs.unit == "raid1" and groups[3].attrs.child1.attrs.unit == "raid2" and mt.attrs.child1.attrs.unit == "raid1", client .. ": party-to-raid native roster and tank membership update in combat")
    check(groups[1].point[4] == 592 and groups[3].point[4] == 518 and mt.point[4] == 444, client .. ": sparse groups pack in original reverse order with MTMA to left")
    roster("raid", 0, { { group = 2 }, { group = 8, mt = true }, { group = 8, mt = true } })
    check(groups[1].alpha == 0 and groups[2].point[4] == 592 and groups[8].point[4] == 518 and mt.point[4] == 444, client .. ": combat subgroup switch compacts gaps and keeps finite occupied positions")
    roster("party", 2)
    check(groups[1].attrs.child3.attrs.unit == "party2" and groups[1].attrs.child4.attrs.unit == nil and not groups[8].shown, client .. ": raid-to-party in combat clears surplus native cells")
    check(groups[2].alpha == 0 and groups[8].alpha == 0 and mt.alpha == 0, client .. ": hidden raid-only headers cannot contribute stale unit attributes to party packing")
    roster("solo")
    check(not groups[1].shown and not groups[8].shown and not mt.shown and e.created == created, client .. ": leaving mid-combat hides frames without allocation")
    roster("party", 1, nil, true)
    check(not groups[1].shown, client .. ": pet battle visibility remains native secure state")
    local originalRows={
        {name="Zulu",group=1,mt=true},{name="Alpha",group=1},
        {name="Tango",group=2},{name="Bravo",group=2},{name="Echo",group=2},
        {name="Delta",group=8},{name="Charlie",group=8},
    }
    local movedRows={
        {name="Zulu",group=1,mt=true},{name="Alpha",group=2},
        {name="Tango",group=2},{name="Bravo",group=4},{name="Echo",group=2},
        {name="Delta",group=8},{name="Charlie",group=8},
    }
    local deletedRows={
        {name="Zulu",group=1,mt=true},{name="Alpha",group=2},{name="Bravo",group=4},
        {name="Echo",group=2},{name="Delta",group=8},{name="Charlie",group=8},
    }
    local newGroupRows={
        {name="Zulu",group=1,mt=true},{name="Alpha",group=2},{name="Bravo",group=4},
        {name="Echo",group=2},{name="Delta",group=7},{name="Charlie",group=7},
    }
    roster("raid",0,originalRows)
    check(groups[1].attrs.child1.attrs.unit=="raid1"and groups[1].attrs.child2.attrs.unit=="raid2"
        and e.UnitName(groups[1].attrs.child1.attrs.unit)=="Zulu"
        and e.UnitName(groups[1].attrs.child2.attrs.unit)=="Alpha",
        client..": nonalphabetical raid-slot names retain Blizzard member order")
    roster("raid",0,movedRows)
    check(groups[1].attrs.child2.attrs.unit==nil and not groups[1].attrs.child2.shown
        and groups[2].attrs.child1.attrs.unit=="raid2"and groups[2].attrs.child2.attrs.unit=="raid3"
        and groups[2].attrs.child3.attrs.unit=="raid5"and groups[4].attrs.child1.attrs.unit=="raid4",
        client..": two members move into existing and previously empty groups during combat")
    check(groups[1].point[4]==592 and groups[2].point[4]==518 and groups[4].point[4]==444
        and groups[8].point[4]==370,client..": newly occupied group participates in original reverse packing")
    roster("raid",0,deletedRows)
    check(e.UnitName("raid1")=="Zulu"and groups[1].attrs.child1.attrs.unit=="raid1"
        and groups[2].attrs.child1.attrs.unit=="raid2"and groups[2].attrs.child2.attrs.unit=="raid4"
        and groups[2].attrs.child3.attrs.unit==nil and not groups[2].attrs.child3.shown,
        client..": another middle member leaving compacts slots without changing the first/self member")
    roster("raid",0,newGroupRows)
    check(groups[8].alpha==0 and groups[8].attrs.child1.attrs.unit==nil and not groups[8].attrs.child1.shown
        and groups[7].attrs.child1.attrs.unit=="raid5"and groups[7].attrs.child2.attrs.unit=="raid6",
        client..": old subgroup disappears and new subgroup appears without a self reassignment")
    check(groups[1].point[4]==592 and groups[2].point[4]==518 and groups[4].point[4]==444
        and groups[7].point[4]==370,client..": subgroup replacement preserves reverse occupied-column packing")
    local pools={}
    for _,header in ipairs(groups)do
        pools[header]={}
        for i=1,5 do pools[header][i]=header.attrs["child"..i]end
    end
    pools[mt]={};for i=1,40 do pools[mt][i]=mt.attrs["child"..i]end
    local fullRows={}
    for i=1,40 do fullRows[i]={name="ReverseName"..(41-i),group=math.ceil(i/5),mt=i<=4}end
    local scenarios={{"party",4},{"party",2},{"raid",0,originalRows},{"raid",0,movedRows},
        {"raid",0,deletedRows},{"raid",0,newGroupRows},{"solo",0},{"raid",0,fullRows}}
    local stressCreated,stressSubscriptions=e.created,e.targetDriverRegistrations
    for iteration=1,400 do
        local scenario=scenarios[(iteration-1)%#scenarios+1]
        roster(scenario[1],scenario[2],scenario[3])
        for header,children in pairs(pools)do
            for index,child in ipairs(children)do
                check(header.attrs["child"..index]==child,client..": roster churn reuses every prepared child")
            end
        end
        if scenario[1]=="raid"then
            local expected={};for i=1,8 do expected[i]={}end
            for index,row in ipairs(scenario[3])do expected[row.group][#expected[row.group]+1]="raid"..index end
            local priorX
            for group=1,8 do
                for index=1,5 do
                    local child=groups[group].attrs["child"..index]
                    check(child.attrs.unit==expected[group][index],client..": repeated raid churn preserves current native slot membership")
                    if not expected[group][index]then check(not child.shown,client..": surplus cell cannot retain an invisible input rectangle")end
                end
                if #expected[group]>0 then
                    local x=groups[group].point[4]
                    if priorX then check(x<priorX,client..": repeated subgroup changes preserve reversed occupied columns")end
                    priorX=x
                else check(groups[group].alpha==0,client..": empty groups contribute no visible ghost column")end
            end
        elseif scenario[1]=="party"then
            check(groups[1].attrs.child1.attrs.unit=="player",client..": party churn keeps player first despite alphabetical names")
            for index=1,4 do
                local expected=index<=scenario[2]and("party"..index)or nil
                local child=groups[1].attrs["child"..(index+1)]
                check(child.attrs.unit==expected,client..": party join/leave churn preserves current native slots")
            end
        else check(not groups[1].shown and not mt.shown,client..": repeated self leave hides prepared roster")end
    end
    check(e.created==stressCreated and e.targetDriverRegistrations==stressSubscriptions,
        client..":400 combat roster transitions allocate no frames and add no target subscriptions")
    writes = e.writes
    check(not S.RefreshRosterLayout(container, groups, mt) and not S.ConfigureHeader(groups[1], 1, false) and e.writes == writes, client .. ": layout configuration defers protected combat writes")
    e.combat = false
    check(S.DisableHeader(groups[1]) and not groups[1]._fluxSecureRosterDriver, client .. ": disable unregisters secure visibility ownership")
    check(S.DisableHeader(mt),client..": MTMA ownership can be disabled out of combat")
    local watchCount=0
    for _,drivers in pairs(e.targetDrivers)do for _ in pairs(drivers)do watchCount=watchCount+1 end end
    check(watchCount==0 and not target.shown,client..": disabling MTMA releases all shared target subscriptions and hit regions")
    local registrations=e.targetDriverRegistrations
    local hiddenParent,hiddenTarget=e.CreateFrame("Button","PreparedInactive"),e.CreateFrame("Button","PreparedInactiveTarget")
    hiddenParent.attrs.unit="raid9";hiddenParent:Show()
    check(S.AttachTarget(hiddenParent,hiddenTarget)and not hiddenTarget.shown,client..": inactive MTMA wrappers can be prepared without revealing targets")
    check(e.targetDriverRegistrations==registrations,client..": inactive preparation does not restart native conditions")
    check(S.ConfigureHeader(mt,nil,true),client..": enabling MTMA restores prepared native existence policy")
    watchCount=0
    for _,drivers in pairs(e.targetDrivers)do for _ in pairs(drivers)do watchCount=watchCount+1 end end
    check(watchCount==40 and e.targetDriverRegistrations==registrations+40,client..": reenable restores exactly40 shared subscriptions")
    check(hiddenTarget.shown,client..": reenable reapplies current native target existence to existing wrappers")
end
for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do exercise(client) end
for _, failure in ipairs({ { unsupported = true }, { inert = true }, { wrapError = true }, {targetDriverFailure=true} }) do
    local e = fixture("forever", failure)
    local p, t = e.CreateFrame("Button", "P"), e.CreateFrame("Button", "T")
    p.attrs.unit, t.attrs.unit = "raid9", "raid1target"
    check(not e.FluxRaidSecure.AttachTarget(p, t) and not t.shown and not t.mouse and t.attrs.unit == nil, "unsupported/inert target wrapper fails closed before exposure")
    local subscriptions=0
    for _,drivers in pairs(e.targetDrivers)do for _ in pairs(drivers)do subscriptions=subscriptions+1 end end
    check(subscriptions==0,"failed target setup retires every partially registered existence condition")
end
print("Raid healer secure: " .. checks .. " checks; five native wrap/state/roster/click source implementations; desktop only")
