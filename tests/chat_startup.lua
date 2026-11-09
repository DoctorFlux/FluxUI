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
local visibility = section(source, "CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1", "-- CROSS-VERSION HELPERS")
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
            assert(load("local ns = ...\n" .. visibility .. config .. events, "@chat-startup", "t", env))({ Flux = flux })
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
-- Run the actual reference-client fade code, including Forever's private
-- alpha cache. Message-text fading is deliberately outside this tab policy.
local references = {
    { "live", "Mainline" }, { "classic_era", "Classic" },
    { "classic_anniversary", "Classic" }, { "classic", "Classic" }, { "forever", "Mainline" },
    { "wrath", false },
}
for _, ref in ipairs(references) do
    local root = "../__AddonsForRef/"
    local nativePath = ref[2] and ("wow-ui-source-" .. ref[1] .. "/Interface/AddOns/Blizzard_ChatFrameBase/" .. ref[2] .. "/FloatingChatFrame.lua")
        or "WoTLK-3.3.5-UI-Source-master/Interface/FrameXML/FloatingChatFrame.lua"
    local native = read(root .. nativePath)
    for _, useList in ipairs({ false, true }) do
        local env = setmetatable({}, { __index = _G }); env._G = env
        env.max = math.max
        env.CHAT_FRAME_TEXTURES, env.NUM_CHAT_WINDOWS = {}, 3
        env.CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA, env.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 1, 0
        env.CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA, env.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = .6, 0
        env.CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA, env.CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 1, 1
        env.UIFrameFadeRemoveFrame = function(tab) tab.fading = nil end
        env.UIFrameFadeOut = function(tab, _, _, target) tab:SetAlpha(target) end
        env.FCF_FadeOutScrollbar = function() end
        env.GENERAL_CHAT_DOCK = { overflowButton = { IsShown = function() return false end } }
        env.FCFDock_GetSelectedWindow = function(dock) return dock.selected end
        local frames, tabs = {}, {}
        env.FCFDock_GetChatFrames = function() return frames end
        env.InCombatLockdown = function() return true end
        env.hooksecurefunc = function() error("tab visibility must not wrap native handlers") end
        env.ChatFrameUtil = {}
        env.securecallfunction = function(fn, ...) return fn(...) end
        if ref[1] == "forever" then
            local util = read(root .. "wow-ui-source-forever/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua")
            assert(load(section(util, "local alertingTabs = {}", "function ChatFrameUtil.ForEachChatFrame"), "@native-tab-cache", "t", env))()
        end
        local function addWindow(i)
            local name = "ChatFrame" .. i
            local frame = { isDocked = true, GetName = function() return name end }
            local tab = { alpha = 0, fading = true }
            function tab:SetAlpha(alpha) self.alpha = alpha end
            function tab:GetAlpha() return self.alpha end
            env[name], env[name .. "Tab"], frames[i], tabs[i] = frame, tab, frame, tab
            return frame, tab
        end
        for i = 1, 3 do addWindow(i) end
        env.GENERAL_CHAT_DOCK.selected = frames[1]
        if useList then env.CHAT_FRAMES = { "ChatFrame1", "ChatFrame2", "ChatFrame3" } end
        assert(load(section(native, "function FCFTab_UpdateAlpha(chatFrame)", "function FCF_HideOnFadeFinished"), "@native-tab-alpha", "t", env))()
        assert(load(section(native, "function FCF_FadeOutChatFrame(chatFrame)", "local LAST_CURSOR_X, LAST_CURSOR_Y"), "@native-tab-fade", "t", env))()
        env.FCFTab_UpdateAlpha(frames[1])
        check(tabs[1].alpha == 0, ref[1] .. " reproduces hidden idle tab")
        local original = env.FCFTab_UpdateAlpha
        local refresh = assert(load(visibility .. "\nreturn RefreshChatTabVisibility", "@production-tab-visibility", "t", env))()
        refresh()
        for _, tab in ipairs(tabs) do check(tab.alpha == 1 and not tab.fading, "login clears old fade and reveals cached tabs") end
        for _, frame in ipairs(frames) do
            env.GENERAL_CHAT_DOCK.selected = frame
            for _, hovered in ipairs({ false, true }) do
                for _, cf in ipairs(frames) do cf.hasBeenFaded = hovered; env.FCFTab_UpdateAlpha(cf) end
                env.FCF_FadeOutChatFrame(frame)
                for _, tab in ipairs(tabs) do check(tab.alpha == 1, ref[1] .. " selected/inactive tabs remain visible after mouse leave") end
            end
        end
        local late, tab = addWindow(4)
        env.FCFTab_UpdateAlpha(late)
        check(tab.alpha == 1, "new tabs inherit visible idle targets")
        check(env.FCFTab_UpdateAlpha == original, "native tab handler retains its identity")
    end
end
print("Chat startup/tabs: " .. checks .. " checks; reference-client fades exercised; native rendering/taint unverified")
