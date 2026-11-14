-- Real shared preference, option callbacks and both production render gates.
-- Native rendering, persistence, controller and protected execution remain separate.
local checks = 0
local function check(value, why) checks = checks + 1; assert(value, why) end
local function read(path)
    local f = assert(io.open(path, "rb")); local body = f:read("*a"):gsub("\r\n", "\n"); f:close(); return body
end
local function gate(path, first, last, env, ns, preamble, name)
    local body = read(path)
    local a = assert(body:find(first, 1, true)); local b = assert(body:find(last, a, true))
    return assert(load((preamble or "") .. body:sub(a, b - 1) .. "\nreturn " .. name, "@" .. path, "t", env))("_FluxUI", ns)
end
for _, client in ipairs({"live", "forever", "classic", "classic_era", "classic_anniversary"}) do
    local db, party, raid, native = {}, false, false, true
    local writes, unitRefresh, plateRefresh, frames, modules = 0, 0, 0, {}, {}
    local ns = {Flux = {Client = {isForever = client == "forever", isAnyClassic = client:find("classic") ~= nil}}}
    local env = setmetatable({}, {__index = _G}); env._G = env
    env.FluxUI_DB = {nameplateThreat = {visibilityMode = "never"}}
    ns.Flux.CVar = {
        Get = function(key) if key == "threatWarning" and native then return "3" end end,
        Set = function(key, value) check(key == "threatWarning", "only native warning CVar changes"); writes = writes + 1; env.nativeValue = value; return true end,
    }
    env.FluxOptions = {
        GetUnitFrameDB = function() return db end,
        RegisterModuleOptions = function(_, key, builder) modules[key] = builder end,
    }
    env.IsInGroup = function() return party or raid end
    env.IsInRaid = function() return raid end
    env.FluxUnitFrames_ApplyThreatBarOptionsFromDB = function() unitRefresh = unitRefresh + 1 end
    env.FluxNamePlates_RefreshFromDB = function() plateRefresh = plateRefresh + 1 end
    env.CreateFrame = function()
        local f = {}; function f:RegisterEvent() end; function f:UnregisterEvent() end
        function f:SetScript(_, fn) self.event = fn end; frames[#frames + 1] = f; return f
    end
    local function run(path) assert(load(read(path), "@" .. path, "t", env))("_FluxUI", ns) end
    run("Core/API/Threat.lua")
    run("AddonOptions/FluxOptionsUnitFrames.lua")
    run("AddonOptions/FluxOptionsNameplates.lua")
    for _, frame in ipairs(frames) do frame.event(frame, "ADDON_LOADED", "_FluxUI") end
    local uf = ns.FluxOptionsThreatVisibilityOption(27)
    local np = modules.nameplates().args.visibilityMode
    check(not modules.nameplates().args.threatWarning, client .. ": no independent native warning selector")
    check(uf.name == "Threat warning visibility" and np.name == uf.name, client .. ": renamed shared setting")
    check(table.concat(uf.sorting, "|") == "always|raid|group|never" and uf.values.group == "In party" and uf.values.never == "Off", client .. ": four requested choices in order")
    local targetGate = gate("UnitFrames/FluxUnitFrames_Shared.lua", "local function ThreatBarAllowedByGroup(", "\n--- Vertical left/right", env, ns, "local _, ns = ...\n", "ThreatBarAllowedByGroup")
    local plateGate = gate("NamePlates/Threat.lua", "local function IsVisibilityAllowed()", "\nlocal function IsNpcThreatEnabled", env, ns, "local _, ns = ...; local Flux = ns.Flux\n", "IsVisibilityAllowed")
    local api = ns.Flux.Threat
    for _, legacy in ipairs({{nil, nil, "group"}, {nil, false, "always"}, {"bad", true, "group"}, {"never", false, "never"}, {"always", true, "always"}, {"group", false, "group"}}) do
        db = {threatBarVisibility = legacy[1], threatBarGroupOnly = legacy[2]}
        local before = writes
        check(uf.get() == legacy[3] and np.get() == legacy[3], client .. ": saved key and legacy fallback agree")
        check(writes == before and db.threatBarVisibility == legacy[1], client .. ": reads preserve saved/native values")
    end
    for _, mode in ipairs({"always", "raid", "group", "never"}) do
        for _, control in ipairs({uf, np}) do
            local before = writes; local oldUnit, oldPlate = unitRefresh, plateRefresh
            control.set(nil, mode)
            check(db.threatBarVisibility == mode and uf.get() == mode and np.get() == mode, client .. ": either selector updates both pages")
            check(writes == before + 1 and unitRefresh == oldUnit + 1 and plateRefresh == oldPlate + 1, client .. ": one explicit native write and one refresh per owner")
            check(env.nativeValue == tostring(({always = 3, raid = 2, group = 1, never = 0})[mode]), client .. ": existing native warning mapping retained")
            for _, context in ipairs({"solo", "party", "raid"}) do
                party, raid = context == "party", context == "raid"
                local expected = mode == "always" or mode == "group" and context ~= "solo" or mode == "raid" and context == "raid"
                check(plateGate() == expected, client .. ": nameplate warning gate " .. mode .. "/" .. context)
                for _, position in ipairs({"portrait", "left", "right", "between"}) do
                    check(targetGate(position) == expected, client .. ": target/focus " .. position .. " shares " .. mode .. "/" .. context)
                end
            end
        end
    end
    check(env.FluxUI_DB.nameplateThreat.visibilityMode == "never", client .. ": old separate nameplate data preserved but no longer gates warnings")
    local saved = db
    db = {threatBarVisibility = "raid"}; check(np.get() == "raid", client .. ": active scope switch follows existing accessor")
    np.set(nil, "always"); check(saved.threatBarVisibility == "never", client .. ": editing another scope preserves previous scope")
    native = false
    local before = writes
    uf.set(nil, "raid"); check(writes == before and db.threatBarVisibility == "raid", client .. ": missing native CVar still supports shared Flux warnings")
    uf.set(nil, "invalid"); check(db.threatBarVisibility == "group", client .. ": invalid selection normalizes to existing grouped default")
    env.IsInGroup, env.IsInRaid = nil, nil
    check(not api.IsVisibilityAllowed(), client .. ": missing optional group queries do not imply a party")
end
print("Shared threat warning visibility: " .. checks .. " checks across five client models; native acceptance pending")
