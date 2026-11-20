-- Execute the owned fallback adapter with and without a native ticker.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local contents = file:read("*a")
    file:close()
    return (contents:gsub("\r\n", "\n"))
end

local current = read("Core/Engine/Restricted.lua")
local baseline = arg[1] and read(arg[1] .. "/Core-Engine-Restricted.lua")

local function fixture(source, ticker)
    local state = {group = false, exists = false, parses = 0, alpha = 0, attributes = 0}
    local env = setmetatable({}, {__index = _G})
    env._G = env
    local flux = {Cap = {hasRestrictedClosures = false}, Client = {isForever = true}}
    env.InCombatLockdown = function() return state.locked end
    env.UnitExists = function() return state.exists end
    env.SecureCmdOptionParse = function(rule)
        state.parses = state.parses + 1
        if rule == "page" then return state.page or "1" end
        assert(rule == "group")
        return state.group and "show" or "hide"
    end
    env.RegisterAttributeDriver = function() error("fallback used the native manager") end
    env.RegisterUnitWatch = function() error("fallback used the native watch") end
    if ticker then
        flux.Timer = {NewTicker = function(interval, callback)
            assert(interval == .2)
            local timer = {run = callback}
            function timer:Cancel() self.cancelled = true end
            state.ticker = timer
            return timer
        end}
    end

    local function frame(name)
        local f = {name = name, shown = false, alpha = 1, attributes = {}, scripts = {}}
        function f:GetName() return self.name end
        function f:IsShown() return self.shown end
        function f:Show()
            assert(not state.locked or self == state.driver)
            self.shown = true
        end
        function f:Hide()
            assert(not state.locked or self == state.driver)
            self.shown = false
        end
        function f:SetAttribute(key, value)
            assert(not state.locked)
            self.attributes[key] = value
            if key == "state-unitexists" then state.attributes = state.attributes + 1 end
        end
        function f:GetAttribute(key) return self.attributes[key] end
        function f:SetAlpha(value)
            assert(not state.locked)
            self.alpha = value
            state.alpha = state.alpha + 1
        end
        function f:GetAlpha() return self.alpha end
        function f:RegisterEvent() end
        function f:SetScript(script, fn) self.scripts[script] = fn end
        return f
    end
    env.CreateFrame = function(_, name)
        local f = frame(name)
        if name == "FluxInsecureStateDriver" then state.driver = f end
        return f
    end
    env.issecretvalue = function(value) return state.opaque and rawequal(value, state.opaque) or false end
    assert(load(source, "@actual-fallback-driver", "t", env))("_FluxUI", {Flux = flux})
    local adapter = flux.Restricted
    local pet, petTarget = frame("FluxUnitFrame_pet"), frame("FluxUnitFrame_pettarget")
    local page = frame("FluxRosterPage")
    local member = frame("FluxRosterMember")
    member.attributes.unit = "party1"
    assert(adapter.RegisterStateDriver(pet, "visibility", "group"))
    assert(adapter.RegisterStateDriver(petTarget, "visibility", "group"))
    assert(adapter.RegisterStateDriver(page, "page", "page"))
    assert(adapter.RegisterUnitWatch(member, true))
    local driver = assert(state.driver)
    function state:send(event)
        driver.scripts.OnEvent(driver, event or "GROUP_ROSTER_UPDATE")
    end
    function state:update()
        if driver.shown and driver.scripts.OnUpdate then driver.scripts.OnUpdate(driver, .016) end
    end
    function state:reset()
        self.parses, self.alpha, self.attributes = 0, 0, 0
    end
    function state:setActive(active)
        self.group, self.exists = active, active
        self.page = active and "2" or "1"
    end
    function state:signature()
        return table.concat({tostring(pet.shown), tostring(petTarget.shown), tostring(member.attributes["state-unitexists"]),
            tostring(page.attributes["state-page"]), pet.alpha, petTarget.alpha}, "|")
    end
    function state:clear()
        adapter.UnregisterUnitWatch(member)
        adapter.UnregisterStateDriver(page, "page")
        adapter.UnregisterStateDriver(pet, "visibility")
        adapter.UnregisterStateDriver(petTarget, "visibility")
        assert(not driver.shown and not driver.scripts.OnUpdate)
    end
    state.member, state.pet, state.petTarget, state.pageFrame = member, pet, petTarget, page
    state:update()
    state:reset()
    return state
end

for _, ticker in ipairs({true, false}) do
    local after = fixture(current, ticker)
    local before = baseline and fixture(baseline, ticker)
    for _, joining in ipairs({true, false, true, false}) do
        local function burst(model)
            model:reset()
            for i = 1, 20 do
                -- The first and final values differ, representing a changing
                -- native roster within the same rendered turn.
                local active = i == 20 and joining or i < 20 and not joining
                model:setActive(active)
                model:send()
                if i == 1 then assert(model.pet.shown == active, "first roster edge remains synchronous") end
            end
            model:update()
            assert(model.pet.shown == joining and model.member.attributes["state-unitexists"] == joining,
                "the follow-up uses the last roster state")
            return model.parses, model.alpha, model.attributes
        end
        local parses, alpha, attributes = burst(after)
        assert(parses == 4 and alpha == 0 and attributes == 1,
            "two sweeps, no matching alpha writes and one actual attribute change")
        if before then
            local oldParses, oldAlpha, oldAttributes = burst(before)
            assert(oldParses == 42 and oldAlpha == 42 and oldAttributes == 21)
            assert(before:signature() == after:signature(), "same final presentation")
            print(("FALLBACK_ROSTER ticker=%s join=%s parse=%d/%d alpha=%d/%d attributes=%d/%d")
                :format(tostring(ticker), tostring(joining), oldParses, parses, oldAlpha, alpha, oldAttributes, attributes))
        end
    end
    after:setActive(true)
    after:send()
    after:setActive(false)
    after:send("UNIT_PET")
    assert(not after.pet.shown, "other events still reconcile immediately")
    after:update()

    after.locked = true
    after:reset()
    after:setActive(true)
    after:send()
    after:send()
    after:update()
    assert(after.alpha == 0 and after.attributes == 0 and not after.pet.shown)
    after.locked = false
    after.pet.alpha = 0
    after:send("PLAYER_REGEN_ENABLED")
    assert(after.pet.shown and after.pet.alpha == 1 and after.attributes == 1, "regen restores visibility and alpha")
    after:update()

    local forbidden = setmetatable({}, {__eq = function() error("secret comparison") end})
    after.opaque = forbidden
    after.exists = forbidden
    after.pet.GetAlpha = function() return forbidden end
    after:reset()
    after:send()
    assert(after.attributes == 0 and after.alpha == 1, "unknown existence is left alone and private alpha still restores")
    after:update()
    after:send()
    after:clear()
    assert(not after.ticker or after.ticker.cancelled, "removing the last owner cancels idle work")
end
print("Fallback roster passes final-state reconciliation, direct events, combat release, private values and cleanup.")
