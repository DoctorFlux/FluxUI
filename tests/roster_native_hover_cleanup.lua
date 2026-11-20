-- Actual native group discovery and classifier, with modeled hover registration.
-- Optional argument is archived Binding/Input/FluxMouseoverKeybind.lua.
local function read(path)
    local f = assert(io.open(path, "rb"))
    local source = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return source
end
local function slice(source, first, last)
    local start = assert(source:find(first, 1, true))
    return source:sub(start, assert(source:find(last, start + #first, true)) - 1)
end
local function run(source, cold, locked)
    local result = { reads = 0, removed = {} }
    local env = setmetatable({
        header = not cold and {}, registeredLookup = {}, FluxMouseoverKeybind = {},
        InCombatLockdown = function() return locked end,
    }, { __index = _G })
    env._G = env
    local function frame(name, registered, parent)
        local f = {
            GetName = function() result.reads = result.reads + 1; return name end,
            GetParent = function() return parent end,
            name = name,
        }
        if registered then env.registeredLookup[f] = true end
        return f
    end
    env.UnregisterFrame = function(f)
        if not env.header or not env.registeredLookup[f] then return end
        assert(not locked, "native unregister cannot run during lockdown")
        env.registeredLookup[f] = nil
        result.removed[#result.removed + 1] = f.name or "nameless pet"
    end
    for i = 1, 5 do
        for _, prefix in ipairs({"CompactPartyFrameMember", "CompactPartyFramePet", "PartyMemberFrame"}) do
            local name = prefix .. i
            env[name] = frame(name, false)
        end
    end
    for i = 1, 40 do
        local name = "CompactRaidFrame" .. i
        env[name] = frame(name, i == 7)
    end
    for group = 1, 8 do
        for member = 1, 5 do
            local name = "CompactRaidGroup" .. group .. "Member" .. member
            env[name] = frame(name, false)
        end
    end
    local party = frame("PartyFrame")
    local pooled = frame("CompactPartyFramePooled", true, party)
    pooled.PetFrame = frame(nil, true, pooled)
    local unrelated = frame("FluxUnitFrame_party1", true, party)
    env.CompactPartyFrameMember1 = unrelated
    -- The frame pool iterator yields values directly, as the native pool does.
    env.PartyFrame = { PartyMemberFramePool = { EnumerateActive = function()
        local pending = pooled
        return function()
            local frame = pending
            pending = nil
            return frame
        end
    end } }
    local classify = slice(source, "local function BlizzardUnitButtonName(", "local function IsBlizzardSecureUnitButton(")
    local cleanup = slice(source, "function FluxMouseoverKeybind:UnregisterBlizzardCompactRaidFrames()",
        "function FluxMouseoverKeybind:RefreshKeybinds()")
    assert(load(classify .. cleanup, "@actual-roster-native-cleanup", "t", env))()
    env.FluxMouseoverKeybind:UnregisterBlizzardCompactRaidFrames()
    result.registered = env.registeredLookup[unrelated]
    return result
end

local adopted = read("Binding/Input/FluxMouseoverKeybind.lua")
local reference = arg[1] and not arg[2] and read(arg[1]) or adopted:gsub(
    "if frame and registeredLookup%[frame%] and IsBlizzardCompactOrPartyButton%(frame%) then",
    "if frame and IsBlizzardCompactOrPartyButton(frame) then", 1)
local before, after = run(reference), run(adopted)
assert(after.registered and before.registered)
local expected = "CompactRaidFrame7,CompactPartyFramePooled,nameless pet"
assert(table.concat(before.removed, ",") == expected and table.concat(after.removed, ",") == expected)
assert(after.reads == 6 and before.reads == 99)
for _, scenario in ipairs({{true, false}, {false, true}}) do
    local r = run(adopted, table.unpack(scenario))
    assert(r.reads == 0 and #r.removed == 0 and r.registered)
end
print(("Roster native hover cleanup: name reads %d -> %d; identical unregister order and protected guards.")
    :format(before.reads, after.reads))

local function discovery(source, raidSource)
    local result = { options = 0, names = 0, forbidden = 0, admitted = {} }
    local env = setmetatable({ registeredLookup = {}, FluxMouseoverKeybind = {}, header = {},
        State = { frameArray = {} }, ownsCompact = true }, { __index = _G })
    env._G = env
    env.ns = { FluxMouseoverKeybind = env.FluxMouseoverKeybind }
    env.InCombatLockdown = function() return env.locked end
    env.IsClickedLoaded = function() return env.clicked end
    env.SyncNativePlayerSuppression = function() end
    env.RegisterFluxUnitFrames = function() end
    env.FluxRaid_IsFluxRaidEnabled = function()
        result.options = result.options + 1
        return env.ownsCompact
    end
    env.RegisterFrame = function(frame)
        assert(not env.locked, "discovery never registers protected buttons in combat")
        if not env.registeredLookup[frame] then
            env.registeredLookup[frame] = true
            result.admitted[#result.admitted + 1] = frame.name
        end
    end
    local function add(name, admitted, parent, isRaid)
        local frame = { name = name, RegisterForClicks = function() end,
            GetName = function() result.names = result.names + 1; return name end,
            GetParent = function() return parent end,
            IsForbidden = isRaid and function(self)
                result.forbidden = result.forbidden + 1
                return self.forbidden
            end }
        if admitted then env.registeredLookup[frame] = true end
        if name then env[name] = frame end
        if isRaid then env.State.frameArray[frame] = frame end
        return frame
    end
    for _, name in ipairs({"PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "TargetFrameToT", "FocusFrameToT"}) do
        add(name, true)
    end
    for i = 1, 4 do add("PartyMemberFrame" .. i) end
    for i = 1, 5 do
        add("CompactPartyFrameMember" .. i); add("CompactPartyFramePet" .. i)
        add("Boss" .. i .. "TargetFrame", true)
    end
    for i = 1, 3 do add("ArenaEnemyFrame" .. i, true) end
    for i = 1, 40 do add("CompactRaidFrame" .. i) end
    for group = 1, 8 do
        for member = 1, 5 do add("CompactRaidGroup" .. group .. "Member" .. member) end
    end
    local party = add("PartyFrame")
    local pooled = add("CompactPartyPooled", false, party)
    pooled.PetFrame = add("PooledPet", false, pooled)
    env.PartyFrame.PartyMemberFramePool = { EnumerateActive = function()
        local yielded = false
        return function() if not yielded then yielded = true; return pooled end end
    end }
    local alias = add("FluxAlias")
    env.CompactPartyFrameMember2 = alias
    for i = 1, 96 do add("FluxPrepared" .. i, true, nil, true) end
    local missed = add("FluxDeferred", false, nil, true)
    local forbidden = add("FluxForbidden", false, nil, true)
    forbidden.forbidden = true
    local definitions = slice(source, "local function BlizzardUnitButtonName(", "local function RequestHoverPeek(")
    local first = assert(source:find("local function RegisterBlizzardFrames()", 1, true))
    local legacy = source:find("\nlocal function RegisterBlizzardButton(", 1, true)
    if legacy then first = legacy end
    definitions = definitions .. source:sub(first,
        assert(source:find("local function RegisterAllHoverFrames()", first, true)) - 1)
    definitions = definitions .. slice(source, "function FluxMouseoverKeybind:RegisterFrame(frame)",
        "function FluxMouseoverKeybind:SyncNativePlayerSuppression()")
    local registerRaids = slice(raidSource, "function ns.FluxRaidRegisterAllMouseoverKeybindFrames()",
        "function FluxRaid_ForEachHeaderChild(")
    assert(load(registerRaids, "@actual-raid-hover-discovery", "t", env))()
    local scan = assert(load(definitions .. "\nreturn RegisterAllMouseoverFrames", "@actual-hover-discovery", "t", env))()
    local function snapshot()
        local names = {}
        for object in pairs(env.registeredLookup) do names[#names + 1] = object.name end
        table.sort(names)
        return table.concat(names, ";")
    end
    for _ = 1, 20 do scan() end
    assert(env.registeredLookup[missed] and env.registeredLookup[alias] and not env.registeredLookup[forbidden]
        and not env.registeredLookup[pooled])
    local worked = { options = result.options, names = result.names, forbidden = result.forbidden, signature = snapshot() }
    env.locked = true
    local late = add("Boss5TargetFrame")
    forbidden.forbidden = false
    scan()
    assert(not env.registeredLookup[late] and not env.registeredLookup[forbidden]
        and result.options == worked.options and result.forbidden == worked.forbidden)
    env.locked, env.clicked = false, true
    scan()
    assert(not env.registeredLookup[late] and env.registeredLookup[forbidden], "Clicked retains the native lane while Flux frames recover")
    env.clicked, env.ownsCompact = false, false
    scan()
    assert(env.registeredLookup[late] and env.registeredLookup[pooled] and env.registeredLookup[pooled.PetFrame]
        and env.registeredLookup[env.CompactRaidFrame1], "disabled Flux raid frames admit newly available native group buttons")
    env.FluxMouseoverKeybind.IsFrameRegistered = nil
    env.registeredLookup[missed] = nil
    scan()
    assert(env.registeredLookup[missed], "a provider without the lookup method retains normal registration")
    worked.recovered = snapshot()
    return worked
end

local raid = read("RaidFrame/FluxRaidUnit.lua")
local previousRaid = arg[2] and read(arg[2]) or raid
local priorDiscovery = arg[2] and discovery(read(arg[1]), previousRaid)
local currentDiscovery = discovery(adopted, raid)
assert(currentDiscovery.options == 20 and currentDiscovery.forbidden == 21)
if priorDiscovery then
    assert(priorDiscovery.signature == currentDiscovery.signature and priorDiscovery.recovered == currentDiscovery.recovered)
    print(("ROSTER_HOVER scans=20 optionReads=%d/%d nameReads=%d/%d forbiddenReads=%d/%d")
        :format(priorDiscovery.options, currentDiscovery.options, priorDiscovery.names, currentDiscovery.names,
            priorDiscovery.forbidden, currentDiscovery.forbidden))
end
print("Roster hover discovery preserves native and Flux admissions, Clicked ownership, and post-lockdown recovery.")
