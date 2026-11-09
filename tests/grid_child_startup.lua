-- lua tests/grid_child_startup.lua (Lua 5.4).
-- Actual registration and startup-refresh functions, isolated from game data.
local checks = 0
local function check(v, message) assert(v, message); checks = checks + 1 end
local function read(path)
    local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s
end
local function slice(s, first, last)
    local a = assert(s:find(first, 1, true))
    local b = assert(s:find(last, a + #first, true))
    return s:sub(a, b - 1)
end
local function fixture()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.combat = false
    env.InCombatLockdown = function() return env.combat end
    env.compile = function(s) return assert(load(s, "grid child startup", "t", env))() end
    return env
end
local teleport = read("ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua")
local consumables = read("ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua")

do
    local env = fixture()
    local creates, updates, favorites = 0, 0, 0
    env.Module = {
        CreateButton = function(allowEmpty)
            check(allowEmpty == true, "cold teleport precreates secure infrastructure")
            creates = creates + 1
            env.Module._button = {}
        end,
        Update = function() updates = updates + 1 end,
    }
    env.FluxFlyoutFavorites = { RegisterListener = function() favorites = favorites + 1 end }
    env.compile(slice(teleport, "function Module.Register(grid)", "-- Lazily create grid button"))
    env.combat = true
    check(env.Module.Register({}) == false and creates == 0, "teleport registration does no protected work in combat")
    env.combat = false
    check(env.Module.Register({}) == true and creates == 1 and updates == 1, "cold spellbook registration completes without data wait")
    env.Module.Register({})
    check(creates == 1 and favorites == 1, "teleport registration and favorite listener idempotent")
end

do
    local env = fixture()
    local hides, clears = 0, 0
    local frame = { Hide = function() hides = hides + 1 end }
    env.Module = {
        _button = { SlotFrame = frame, Widget = frame }, _startupEmpty = true,
        HasAnyTeleportOrPortalSpell = function() return false end,
        ClearTeleportKeybinding = function() clears = clears + 1 end,
    }
    env.compile(slice(teleport, "function Module.Update()", '        if FluxExtraButtonVisibility and not FluxExtraButtonVisibility.Apply("nc_teleport"')
        .. "\nend end")
    env.Module.Update()
    check(hides == 2 and clears == 1 and env.Module._startupEmpty, "empty reserved teleport stays hidden and captures no key")
    env.combat = true
    env.Module.Update()
    check(hides == 2 and clears == 1 and env.Module._pendingUpdate, "reserved teleport cannot change visibility or bindings in combat")
end

do
    local env = fixture()
    env.Module = {
        _grid = {},
        HasAnyTeleportOrPortalSpell = function() return false end,
    }
    env.compile(slice(teleport, "function Module.CreateButton(allowEmpty)", "    local grid = Module._grid")
        .. "\nModule.permittedEmpty = allowEmpty; return true end")
    env.Module.CreateButton()
    check(env.Module.permittedEmpty == nil, "ordinary creation still requires known spells")
    check(env.Module.CreateButton(true) == true and env.Module.permittedEmpty,
        "startup can reserve unknown-spell infrastructure without guessing a spell")
end

do
    local env = fixture()
    local events, binds, updates, queued = 0, 0, 0, nil
    env.LoadSavedVars = function() end
    env.Module = {
        CreateButton = function() env.Module._button = {} end,
        RegisterEvents = function() events = events + 1 end,
        UpdateKeybindings = function() binds = binds + 1 end,
        UpdateButtonState = function(force)
            check(force == true, "startup uses current preset facts immediately")
            updates = updates + 1
        end,
    }
    env.Timer = { After = function() error("secure consumable binding was delayed") end }
    env.FluxEBS_PostLoginBagRefresh = { Schedule = function(fn)
        check(updates > 0, "inventory settling follows immediate secure selection")
        queued = fn
    end }
    env.compile(slice(consumables, "function Module.RunPostLoginConsumablesRefresh()", "-- Coalesce frequent UNIT_AURA")
        .. slice(consumables, "function Module.Register(grid)", "function Module.CreateButton()"))
    env.combat = true
    check(env.Module.Register({}) == false and binds == 0, "consumables registration waits out combat")
    env.combat = false
    check(env.Module.Register({}) == true and binds == 1 and updates == 1,
        "consumable input binding and candidate selection do not wait for a timer or scan")
    env.Module.Register({})
    check(events == 1 and binds == 1, "consumables registration is idempotent")
    check(type(queued) == "function", "later inventory settle reconciliation retained")
    queued()
    check(updates == 2, "new inventory facts reconcile through existing refresh path")
    env.combat = true
    env.Module.RunPostLoginConsumablesRefresh()
    check(updates == 2 and env.Module._pendingUpdate, "combat startup refresh queues restricted item selection")
end

print(("PASS: %d grid-child startup checks; unknown data is never claimed as configured input"):format(checks))
