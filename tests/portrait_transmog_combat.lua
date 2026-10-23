-- Executes the complete portrait module. The restricted snippet is evaluated
-- separately; desktop Lua cannot emulate native taint or hardware input.
local f = assert(io.open("UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua", "rb"))
local source = f:read("*a"); f:close()
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function exercise(branch, code)
    local combat, restricted, writes = false, false, 0
    local frames, jobs, drivers = {}, {}, {}
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.InCombatLockdown = function() return combat end
    local function widget(kind, name, parent, template)
        check(not combat, "no frame creation in combat")
        local w = { scripts = {}, attributes = {}, refs = {}, parent = parent, shown = true, explicit = template ~= nil }
        frames[#frames + 1] = w; if name then env[name] = w end
        local function mutate() check(not combat or restricted, "no protected mutation in combat"); writes = writes + 1 end
        for _, method in ipairs({ "SetParent", "ClearAllPoints", "SetPoint", "SetAllPoints", "SetSize",
            "SetFrameStrata", "SetFrameLevel", "EnableMouse", "SetMouseClickEnabled", "SetAttribute", "SetFrameRef" }) do
            w[method] = function(self, key, value)
                mutate()
                if method == "SetAttribute" then self.attributes[key] = value end
                if method == "SetFrameRef" then self.refs[key] = value end
            end
        end
        function w:GetFrameRef(key) return self.refs[key] end
        function w:GetParent() return self.parent end
        function w:GetFrameStrata() return "MEDIUM" end
        function w:GetFrameLevel() return 40 end
        function w:GetWidth() return 48 end
        function w:GetHeight() return 48 end
        function w:Show() mutate(); self.shown = true end
        function w:Hide()
            if combat and restricted then check(self.explicit, "combat handle target explicitly protected") end
            mutate(); self.shown = false
        end
        function w:IsShown() return self.shown end
        function w:IsMouseOver() return self.hovered end
        function w:SetScript(event, callback) self.scripts[event] = callback end
        function w:GetScript(event) return self.scripts[event] end
        function w:HookScript(event, callback) self.scripts[event] = callback end
        function w:RegisterEvent() end
        function w:RegisterForClicks() mutate() end
        function w:GetNormalTexture() end
        function w:GetPushedTexture() end
        for _, method in ipairs({ "SetHighlightTexture", "SetNormalTexture", "SetPushedTexture" }) do
            w[method] = function() mutate() end
        end
        return w
    end
    env.CreateFrame = widget; env.UIParent = widget("Frame")
    env.GameTooltip = { Hide = function() end }
    env.RegisterStateDriver = function(frame, state, condition)
        check(not combat, "state driver configured before combat")
        drivers[#drivers + 1] = { frame = frame, state = state, condition = condition }
    end
    local ns = { API = { HasPlayerTransmogOutfitAPI = function() return true end,
        GetPlayerTransmogOutfitEntries = function() return { { id = 4, index = 1 } } end },
        Flux = { Client = { branch = branch }, Combat = { Defer = function(key, fn) jobs[key] = fn end } } }
    assert(load(code or source, "@portrait-transmog", "t", env))("_FluxUI", ns)
    local player = widget("Button"); player.unit = "player"
    player.outerBorderFrame, player.PortraitFrame = widget("Button"), widget("Frame")
    local ptc = ns.PlayerTransmogClick
    combat = true; local before = writes
    ptc.Initialize(player); ptc.Initialize(player)
    check(writes == before and next(jobs), "combat login queues initial setup")
    local count = 0; for _ in pairs(jobs) do count = count + 1 end
    check(count == 1, "initialization coalesces under one key")
    combat = false; for _, fn in pairs(jobs) do fn() end
    local button, catcher = env.FluxPlayerPortraitTransmogClick, env.FluxPlayerPortraitHoverCatcher
    check(button and catcher and #drivers == 1, "full control and combat driver initialized")
    player.PortraitFrame.hovered = true
    player.outerBorderFrame.scripts.OnEnter()
    check(button.shown and catcher.shown, "hover remains responsive out of combat")
    combat = true; before = writes
    ptc.UpdateInteractionState(player)
    button.scripts.OnLeave()
    for _, frame in ipairs(frames) do
        if frame.scripts.OnEvent then frame.scripts.OnEvent(frame, "PLAYER_REGEN_DISABLED") end
    end
    check(writes == before, "layout, events and hover do not mutate protected controls in combat")
    local driver = drivers[1]
    check(driver.condition == "[combat] hide; show", "combat condition retained")
    restricted = true
    assert(load(driver.frame.attributes["_onstate-" .. driver.state], "@restricted-combat-hide", "t",
        { self = driver.frame, newstate = "hide" }))()
    restricted = false
    check(not button.shown and not catcher.shown, "restricted handler hides both portrait controls")
    combat = false
    for _, frame in ipairs(frames) do
        if frame.scripts.OnEvent then frame.scripts.OnEvent(frame, "PLAYER_REGEN_ENABLED") end
    end
    check(button.shown and catcher.shown, "hover presentation restored after combat")
    local n = #frames; ptc.Initialize(player)
    check(#frames == n and #drivers == 1, "reinitialization reuses frames and driver")
end
for _, branch in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do exercise(branch) end
local mutant, n = source:gsub('function PTC.UpdateInteractionState%(playerFrame%)%s+if InCombatLockdown%(%) then return end',
    'function PTC.UpdateInteractionState(playerFrame)', 1)
check(n == 1 and not pcall(exercise, "live", mutant), "negative control rejects in-combat layout mutation")
mutant, n = source:gsub(', "SecureFrameTemplate"%)', ')')
check(n == 2 and not pcall(exercise, "live", mutant), "negative control rejects unprotected combat-handle targets")
print("Portrait transmog combat: " .. checks .. " checks; five capability models; negative control passed")
