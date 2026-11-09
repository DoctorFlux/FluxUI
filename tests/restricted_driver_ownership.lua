-- Production adapter and caller bindings; no native secure VM is simulated.
local root = arg[1] or ((arg[0]:match("^(.*)[/\\]") or ".") .. "/../")
if not root:match("[/\\]$") then root = root .. "/" end
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function read(path)
    local f = assert(io.open(root .. path, "rb")); local s = f:read("*a"); f:close()
    return s:gsub("\r\n", "\n")
end
local names = { "RegisterAttributeDriver", "UnregisterAttributeDriver", "RegisterStateDriver",
    "UnregisterStateDriver", "RegisterUnitWatch", "UnregisterUnitWatch", "UnitWatchRegistered" }
local callers = {
    ["Bars/State.lua"] = { "RegisterStateDriver", "UnregisterStateDriver" },
    ["Bars/Pet/Init.lua"] = { "RegisterStateDriver", "UnregisterStateDriver" },
    ["Binding/Core/SecurePool.lua"] = { "UnregisterStateDriver" },
    ["Binding/Input/FluxMouseoverKeybind.lua"] = { "RegisterAttributeDriver", "UnregisterAttributeDriver" },
    ["Core/Engine/MouseoverCast.lua"] = { "UnregisterStateDriver" },
    ["RaidFrame/FluxRaidLayout.lua"] = { "RegisterStateDriver" },
    ["UnitFrames/FluxClassPower.lua"] = { "RegisterStateDriver", "UnregisterStateDriver" },
    ["UnitFrames/FluxUnitFrames_Shared.lua"] = { "RegisterUnitWatch" },
    ["UnitFrames/FluxUnitFrames_Pet.lua"] = { "RegisterStateDriver", "UnregisterStateDriver", "UnregisterUnitWatch", "UnitWatchRegistered" },
    ["UnitFrames/FluxUnitFrames_PetTarget.lua"] = { "RegisterStateDriver", "UnregisterStateDriver", "UnregisterUnitWatch", "UnitWatchRegistered" },
    ["UnitFrames/FluxUnitFrames_Target.lua"] = { "RegisterUnitWatch", "UnregisterUnitWatch" },
    ["UnitFrames/FluxUnitFrames_TargetOfTarget.lua"] = { "RegisterUnitWatch", "UnregisterUnitWatch" },
    ["UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua"] = { "RegisterStateDriver" },
    ["Salvage/FluxSalvage_Overlay.lua"] = { "RegisterAttributeDriver" },
}
for _, client in ipairs({ "forever", "live", "classic_era", "classic_anniversary", "classic" }) do
    local forever = client == "forever"
    local state = { combat = false, value = "show", calls = {}, frames = {} }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local originals = {}
    for _, name in ipairs(names) do
        local key = name
        originals[key] = function(frame)
            state.calls[key] = (state.calls[key] or 0) + 1
            return frame
        end
        env[key] = originals[key]
    end
    function env.InCombatLockdown() return state.combat end
    function env.SecureCmdOptionParse() return state.value end
    function env.UnitExists() return true end
    function env.CreateFrame(_, name)
        local f = { name = name, attributes = {}, scripts = {}, events = {} }
        function f:GetName() return self.name end
        function f:IsShown() return self.shown end
        function f:Show() check(not state.combat, "fallback Show must remain out of combat"); self.shown = true end
        function f:Hide() check(not state.combat, "fallback Hide must remain out of combat"); self.shown = false end
        function f:SetAttribute(k, v) check(not state.combat, "fallback attributes must remain out of combat"); self.attributes[k] = v end
        function f:GetAttribute(k) return self.attributes[k] end
        function f:SetScript(k, v) self.scripts[k] = v end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:Execute() self:SetAttribute("flux-paging-probe", 1) end
        state.frames[#state.frames + 1] = f
        return f
    end
    local flux = { Cap = { hasRestrictedClosures = not forever }, Client = { isForever = forever, isCamelot = forever } }
    env.Flux = flux
    assert(load(read("Core/Engine/Restricted.lua"), "@Core/Engine/Restricted.lua", "t", env))("_FluxUI", { Flux = flux })
    local adapter = flux.Restricted
    for _, name in ipairs(names) do check(env[name] == originals[name], client .. " preserves global " .. name) end
    for _, foreign in ipairs({ env.CreateFrame("Frame", "OtherAddonButton"), env.CreateFrame("Frame") }) do
        for _, name in ipairs(names) do
            check(env[name](foreign, "visibility", "show") == foreign, client .. " forwards foreign/unnamed " .. name)
        end
    end
    -- Execute each actual local alias declaration in its owning module's scope.
    -- This checks the migration without pretending to load that module's UI.
    for path, apis in pairs(callers) do
        local source = read(path)
        local first = source:find("local FluxDrivers =", 1, true) or source:find("local Restricted = ns.Flux", 1, true)
        first = assert(first, path .. " needs its owned adapter")
        local last = assert(source:find("\nlocal " .. apis[#apis] .. " =", first, true))
        last = source:find("\n", last + 1, true) or (#source + 1)
        local aliases = assert(load("local ns, Flux = ...\n" .. source:sub(first, last - 1) .. "\nreturn {" .. table.concat(apis, ",") .. "}", "@" .. path .. ":driver-aliases", "t", env))({ Flux = flux }, flux)
        for i, name in ipairs(apis) do
            check(aliases[i] == (forever and adapter[name] or originals[name]), client .. " caller binding " .. path .. ":" .. name)
        end
    end
    local own = env.CreateFrame("Frame", "FluxOwnershipTest")
    own.attributes.unit = "target"
    if forever then
        local before = state.calls.RegisterStateDriver
        check(adapter.RegisterStateDriver(own, "visibility", "show"), "owned fallback state accepted")
        check(own.shown and state.calls.RegisterStateDriver == before, "owned fallback avoids native manager")
        check(adapter.RegisterUnitWatch(own), "owned fallback watch accepted")
        check(adapter.UnitWatchRegistered(own), "owned fallback watch lookup")
        state.combat = true; state.value = "hide"
        local fallback = state.frames[4] -- two foreign frames, own, then fallback
        check(fallback.name == "FluxInsecureStateDriver", "fallback frame is demand-created")
        fallback.scripts.OnEvent(fallback, "MODIFIER_STATE_CHANGED")
        check(own.shown, "combat fallback preserves legally configured visibility")
        state.combat = false
        adapter.UnregisterUnitWatch(own)
        fallback.scripts.OnEvent(fallback, "PLAYER_REGEN_ENABLED")
        check(not own.shown, "regen reconciles owned visibility")
        adapter.UnregisterStateDriver(own, "visibility")
        check(not fallback.shown, "empty fallback stops its update driver")
        check(adapter.PagingWorks(), "repaired restricted paging probe retained")
        local nativeBefore = state.calls.RegisterAttributeDriver or 0
        check(adapter.RegisterPagingDriver(own, "native", "1"), "repaired paging uses captured native function")
        check(state.calls.RegisterAttributeDriver == nativeBefore + 1, "paging bypasses legacy fallback only after successful probe")
        check(not adapter.RegisterStateDriver(env.CreateFrame("Frame", "OtherAddonButton"), "visibility", "show"), "local fallback still rejects foreign ownership")
    else
        check(adapter.RegisterUnitWatch(own), client .. " adapter native watch works")
        check(adapter.RegisterStateDriver(own, "visibility", "show"), client .. " adapter native state works")
    end
end
print("restricted driver ownership: " .. checks .. " checks passed (five client models; native taint pending)")
