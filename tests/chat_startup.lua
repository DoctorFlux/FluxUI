-- Execute chat's real startup transaction and event routing without a client.
local checks = 0
local function check(value, message) assert(value, message); checks = checks + 1 end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s:gsub("\r\n", "\n")
end
local function section(source, first, last)
    local a = assert(source:find(first, 1, true))
    local b = last and assert(source:find(last, a + #first, true)) or (#source + 1)
    return source:sub(a, b - 1)
end
local source = read("Other/FluxChatFrame.lua")
local config = section(source, "local configurationPending = false", "-- EVENT HANDLING")
local events = section(source, 'local eventFrame = CreateFrame("Frame")')
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    for _, saved in ipairs({ false, true }) do
        for _, locked in ipairs({ false, true }) do
            local env = setmetatable({}, { __index = _G }); env._G = env
            local combat, positioned, column, configured = locked, 0, 0, 0
            local frames, timers, callbacks = {}, {}, {}
            env._FluxUI_CharSavedVars = { fluxChatConfigured = saved }
            env.InCombatLockdown = function() return combat end
            env.CreateFrame = function()
                local f = { events = {} }
                function f:RegisterEvent(event) self.events[event] = true end
                function f:SetScript(_, fn) self.onEvent = fn end
                frames[#frames + 1] = f; return f
            end
            env.C_Timer = { After = function(delay, fn) timers[#timers + 1] = { delay, fn } end }
            env.ChatFrame1 = {}
            env.FLUX_API = { isPreDF = branch ~= "live" and branch ~= "forever" }
            env.FindGlobalChatFrame = function() return {} end
            env.ConfigureGeneral = function() configured = configured + 1 end
            env.ConfigureGlobalChat = function() configured = configured + 1 end
            env.ApplyPositionWithRetries = function()
                assert(not combat, "chat structure changed in combat"); positioned = positioned + 1
            end
            env.InitSocialButtonPositioning = function() column = column + 1 end
            env.print = function() end
            for _, name in ipairs({ "ReorderDockGeneralGlobalCombat", "ConfigureGlobalChannels", "ScheduleGlobalChannelRetries",
                "DisableGlobalChannelsOnGeneral", "HookEditModeRestore", "WatchChatPinDrift", "EnableAllClassColors", "SelectGeneralTab" }) do
                env[name] = function() end
            end
            local layoutSpec
            local flux = { AfterLogin = function(fn) callbacks[#callbacks + 1] = fn end,
                Module = { Register = function(name, spec)
                    check(name == "ChatLayout", "chat registers its final geometry pass")
                    layoutSpec = spec
                end } }
            assert(load("local ns = ...\n" .. config .. events, "@chat-startup", "t", env))({ Flux = flux })
            for _, fn in ipairs(callbacks) do fn() end
            local function fire(event)
                for _, f in ipairs(frames) do if f.events[event] and f.onEvent then f.onEvent(f, event) end end
            end
            if locked then
                check(positioned == 0 and #timers == 0, "already locked startup waits for regen without polling")
                combat = false; fire("PLAYER_REGEN_ENABLED")
            end
            check(positioned == 1 and column == 1 and env._FluxUI_CharSavedVars.fluxChatConfigured,
                branch .. " chat and social column configured synchronously at login")
            check(configured == (saved and 0 or 2), "first configuration and saved configuration preserved")
            fire("PLAYER_LOGIN"); fire("PLAYER_ENTERING_WORLD")
            check(positioned == 1, "repeated login/world events do not redo setup")
            combat = true
            -- First world entry may already be in combat; no startup timer is needed.
            fire("PLAYER_ENTERING_WORLD")
            check(positioned == 1, "combat world entry retains initialized chat")
            check(layoutSpec.phase == "hud" and layoutSpec.priority > 90 and layoutSpec.protected,
                "chat sizing follows menu, status and unified-border setup in the same login")
            local order = {}
            env.FluxMicroMenu = { _startupReady = true, RefreshLayout = function() order[#order + 1] = "menu" end }
            env.ApplyPositionWithRetries = function() order[#order + 1] = "chat" end
            env.FluxCCP = { InstallColumnButtons = function() order[#order + 1] = "buttons" end }
            check(layoutSpec.OnEnable() == false and #order == 0, "final sizing never mutates protected geometry in combat")
            combat = false
            check(layoutSpec.OnEnable() == true and table.concat(order, ",") == "menu,chat,buttons",
                "menu and chat dimensions settle together before button-column alignment")
            env.FluxMicroMenu._startupReady = false
            check(layoutSpec.OnEnable() == false and #order == 3, "unready menu cannot commit a provisional chat rectangle")
        end
    end
end
print("Chat startup: " .. checks .. " checks across five client models; native rendering/taint unverified")
