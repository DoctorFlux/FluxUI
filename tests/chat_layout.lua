-- Execute the production layout path with late HUD dependencies on every branch.
local f = assert(io.open("Other/FluxChatFrame.lua", "rb"))
local source = f:read("*a"):gsub("\r\n", "\n"); f:close()
local function section(text, first, last)
    local a = assert(text:find(first, 1, true))
    return text:sub(a, assert(text:find(last, a + #first, true)) - 1)
end
local production = section(source, "local function GetChatWidth()", "-- CLASS COLORS")
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function fixture(branch, body)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local state = { xFactor = .55, floor = 100, pos = 2, combat = false, writes = 0, illegal = 0, timers = {} }
    env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 2, 5
    env.WOW_PROJECT_ID = branch == "classic_era" and 2 or branch == "classic_anniversary" and 5 or 1
    local client = { branch = branch, isEra = branch == "classic_era", isAnniversary = branch == "classic_anniversary" }
    env.Flux = { Client = client }
    env.InCombatLockdown = function() return state.combat end
    env.FluxWindowFrame = { WINDOW_WIDTH = 405, WINDOW_HEIGHT = 270 }
    env.FluxUILayoutSqueeze = { GetEffectiveEmulatedDependentXFactorForUnitFrames = function() return state.xFactor end }
    env.FluxOptions = { GetMicroMenuLayoutPosition = function() return state.pos end }
    env.UIParent = { GetWidth = function() return 1920 end, GetHeight = function() return 1080 end,
        GetEffectiveScale = function() return .7 end }
    env.FluxUnifiedBorder = { GetActionGridBorderTop = function() return state.floor end }
    env.FluxActionStrip = { IsShown = function() return true end, GetTop = function() return state.floor end }
    local menu = { w = 52, h = 224, bottom = 103 }
    function menu:GetWidth() return self.w end
    function menu:GetHeight() return self.h end
    function menu:GetBottom() return self.bottom end
    env.FluxMicroMenu = menu
    env.ChatFrame1EditBox = { GetHeight = function() return 32 end }
    env.ChatFrame1Tab = { GetHeight = function() return 22 end, GetEffectiveScale = function() return .7 end }
    local chat = { x = 0, y = 0, w = 296, h = 120, systemInfo = {}, protected = true }
    function chat:GetName() return "ChatFrame1" end
    function chat:GetID() return 1 end
    function chat:GetScale() return 1 end
    function chat:GetLeft() return self.x end
    function chat:GetBottom() return self.y end
    function chat:GetWidth() return self.w end
    function chat:GetHeight() return self.h end
    function chat:IsShown() return true end
    function chat:IsProtected() return self.protected end
    local function mutation()
        if state.combat and chat.protected then state.illegal = state.illegal + 1 end
        assert(not (state.combat and chat.protected), "protected chat mutation during combat")
        state.writes = state.writes + 1
    end
    function chat:ClearAllPoints() mutation() end
    function chat:SetMovable() mutation() end
    function chat:SetUserPlaced() mutation() end
    function chat:SetSize(w, h) mutation(); self.w, self.h = w, h end
    function chat:SetPoint(_, _, _, x, y) mutation(); self.x, self.y = x, y end
    env.ChatFrame1 = chat
    env.C_Timer = { After = function(_, callback) state.timers[#state.timers + 1] = callback end }
    local eventBody = section(source, 'eventFrame:SetScript("OnEvent", function(self, event)', '\n    if event == "PLAYER_REGEN_DISABLED" then')
    eventBody = eventBody .. "\nend)"
    env.eventFrame = { SetScript = function(_, _, fn) state.event = fn end }
    local apply, restore, drift = assert(load("local _, ns = ...\n" .. (body or production) .. eventBody ..
        "\nreturn ApplyPosition, RestoreLastChatPin, RepinChatIfDrifted", "@production-chat-layout", "t", env))("_FluxUI", { Flux = env.Flux })
    return state, chat, menu, env, apply, restore, drift
end
local function exercise(branch, body)
    local s, chat, menu, env, apply, restore, drift = fixture(branch, body)
    apply(chat)
    check(math.abs(chat.w - 222.75) < .01 and chat.h == 170, branch .. ": initial squeezed rectangle")
    -- Secure/HUD startup now completes before the older delayed chat configuration.
    -- Subsequent menu layout must reconcile the transient first measurements.
    s.xFactor, s.floor = 1, 140
    menu.w, menu.bottom, menu.h = 58, 143, 244
    apply(chat)
    check(chat.w == 405 and chat.x == 94, branch .. ": late width and column position reconcile")
    check(chat.y == 175 and chat.h == 190, branch .. ": log and tab align with final menu rectangle")
    check(chat.y + chat.h + 22 == menu.bottom + menu.h, branch .. ": tab top matches menu top")
    local writes = s.writes
    for _ = 1, 2400 do apply(chat); drift() end
    check(s.writes == writes, branch .. ": unchanged layout performs no frame writes")
    -- Saved options and scale changes smaller than the former 24px deadband still apply.
    s.xFactor = .98; menu.w = 60; menu.h = 252
    apply(chat, true)
    check(math.abs(chat.w - 396.9) < .01 and chat.x == 96 and chat.h == 198,
        branch .. ": explicit small layout change is honored")
    chat.x, chat.w = 1, 200
    apply(chat, true)
    check(chat.x == 96 and math.abs(chat.w - 396.9) < .01, branch .. ": explicit force restores native layout drift")
    chat.x, chat.y, chat.w, chat.h = 1, 1, 200, 120
    restore(chat)
    check(chat.x == 96 and chat.y == 175 and chat.h == 198, branch .. ": native drift restores cached rectangle")
    env.FluxChatFrame_SetDragHold(true)
    menu.w = 80; apply(chat, true)
    check(chat.x == 96, branch .. ": bag drag holds the last rectangle")
    env.FluxChatFrame_SetDragHold(false, true); apply(chat)
    check(chat.x == 116, branch .. ": bag drag release permits reconciliation")
    s.pos = 1; apply(chat, true)
    check(chat.x == 34 and chat.y == 175 and chat.h == 170, branch .. ": horizontal menu layout preserved")
    s.pos = 3; apply(chat, true)
    check(chat.x == 34 and chat.y == 175, branch .. ": minimap menu layout preserved")
    s.pos = 2; apply(chat, true)
    local savedY, savedH = chat.y, chat.h
    menu.h = 0; apply(chat)
    check(chat.y == savedY and chat.h == savedH, branch .. ": unavailable menu keeps the last good rectangle")
    menu.h = 252
    s.combat = true
    local beforeCombat = s.writes
    apply(chat, true)
    chat.x = 1 -- Native code can move chat while its protected descendants are active.
    restore(chat)
    check(s.writes == beforeCombat and s.illegal == 0, branch .. ": no protected frame mutation during combat")
    menu.w = 90; s.xFactor = .9
    for _ = 1, 20 do apply(chat, true) end
    s.combat = false
    s.event(nil, "PLAYER_REGEN_ENABLED")
    check(chat.x == 126 and math.abs(chat.w - 364.5) < .01, branch .. ": combat end applies latest layout")
    local afterCombat = s.writes
    s.event(nil, "PLAYER_REGEN_ENABLED")
    check(s.writes == afterCombat, branch .. ": deferred reconciliation runs once")
    local fresh, first, _, _, firstApply = fixture(branch, body)
    fresh.combat = true; firstApply(first)
    check(fresh.writes == 0, branch .. ": combat login waits for legal structural initialization")
    fresh.combat = false; fresh.event(nil, "PLAYER_REGEN_ENABLED")
    check(first.h == 170 and math.abs(first.w - 222.75) < .01, branch .. ": combat login completes after regen")
    return s, chat, menu, env, apply, restore
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do exercise(branch) end
local mutants = 0
local function reject(old, replacement, message)
    local a = assert(production:find(old, 1, true), old)
    local changed = production:sub(1, a - 1) .. replacement .. production:sub(a + #old)
    local ok, err = pcall(exercise, "classic_era", changed)
    check(not ok and tostring(err):find(message, 1, true), "mutation rejected: " .. message)
    mutants = mutants + 1
end
reject("if GetMicroMenuLayoutPos() ~= 2 then", "if GetMicroMenuLayoutPos() ~= 2 or ns.Flux.Client.isEra then",
    "late width and column position reconcile")
reject("local w = GetChatWidth()", "if lastChatPin and ns.Flux.Client.isEra then chatPinApplying = false; return end\n    local w = GetChatWidth()",
    "late width and column position reconcile")
reject("if not force and ChatMetricsClose", "if ChatMetricsClose", "explicit force restores native layout drift")
reject("if InCombatLockdown() and chatFrame.IsProtected and chatFrame:IsProtected() then", "if false then",
    "no protected frame mutation during combat")
print("chat layout: " .. checks .. " checks across five branches; " .. mutants .. " regressions rejected")
