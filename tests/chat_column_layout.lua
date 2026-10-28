-- Run production Classic native-strip and modern-holder paths on all five clients.
local f = assert(io.open("Other/FluxChatCopyPaste.lua", "rb"))
local source = f:read("*a"):gsub("\r\n", "\n"); f:close()
local a = assert(source:find("local COLUMN_BUTTON_NAMES =", 1, true))
local b = assert(source:find("function FluxCCP:UpdateColumnButtons()", a, true))
local production = source:sub(a, b - 1)
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function fixture(branch, side, body)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local state = { combat = false, writes = 0, illegal = 0, created = 0, frames = {} }
    env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_BURNING_CRUSADE_CLASSIC, env.WOW_PROJECT_MAINLINE = 2, 5, 1
    env.WOW_PROJECT_ID = branch == "classic_era" and 2 or branch == "classic_anniversary" and 5 or branch == "classic" and 19 or 1
    local client = { isEra = branch == "classic_era", isAnniversary = branch == "classic_anniversary", isForever = branch == "forever",
        isPreDF = branch == "classic_era" or branch == "classic_anniversary" or branch == "classic" }
    env.Flux = { Client = client }; env.FluxCCP = {}
    env.FLUX_API = { isPreDF = branch ~= "live" } -- A stale legacy flag must not opt Forever into Classic fitting.
    env.InCombatLockdown = function() return state.combat end
    env.FCF_GetButtonSide = function() return side end
    env.hooksecurefunc = function() end
    env.NUM_CHAT_WINDOWS = 1
    local function mutate()
        state.writes = state.writes + 1
        if state.combat then state.illegal = state.illegal + 1; error("combat layout attempted") end
    end
    local function frame(name, parent, height)
        local r = { name = name, parent = parent, height = height or 27, top = 0, children = {}, events = {}, scripts = {} }
        if parent and parent.children then parent.children[#parent.children + 1] = r end
        function r:GetName() return self.name end
        function r:GetID() return self.id or 1 end
        function r:IsVisible()
            if self.hidden then return false end
            return not self.parent or not self.parent.IsVisible or self.parent:IsVisible()
        end
        function r:GetParent() return self.parent end
        function r:SetParent(value) mutate(); self.parent = value; value.children[#value.children + 1] = self end
        function r:GetTop()
            if self.anchor then
                local p = self.anchor
                return (p.relative == "BOTTOM" and p.target:GetBottom() or p.target:GetTop()) + p.y
            end
            return self.top
        end
        function r:GetBottom() return self:GetTop() - self.height end
        function r:GetHeight() return self.height end
        function r:GetLeft() return 100 end
        function r:GetRight() return 500 end
        function r:GetObjectType() return "Frame" end
        function r:IsProtected() return true end
        function r:ClearAllPoints() mutate(); self.top = self:GetTop(); self.anchor = nil end
        function r:SetPoint(point, target, relative, x, y)
            mutate(); self.point = point; self.target = target
            self.anchor = { target = target, relative = relative, y = y }
        end
        function r:SetSize(_, h) mutate(); self.height = h end
        function r:SetFrameStrata() mutate() end
        function r:SetAlpha() mutate() end
        function r:Hide() mutate(); self.hidden = true end
        function r:Show() mutate(); self.hidden = false end
        function r:HookScript() end
        function r:RegisterEvent(event) self.events[event] = true end
        function r:UnregisterEvent(event) self.events[event] = nil end
        function r:SetScript(event, fn) self.scripts[event] = fn end
        state.frames[#state.frames + 1] = r
        return r
    end
    env.CreateFrame = function(_, name, parent)
        state.created = state.created + 1
        local r = frame(name, parent)
        if name then env[name] = r end
        return r
    end
    env.UIParent = frame("UIParent")
    function env.UIParent:IsVisible() return true end
    local chat = frame("ChatFrame1", env.UIParent, 240); chat.top = 370
    env.ChatFrame1EditBox = { GetHeight = function() return 32 end }
    local bg = frame("Background"); bg.top = 373
    function bg:GetObjectType() return "Texture" end
    chat.Background = bg
    local bf = frame("ChatFrame1ButtonFrame", chat)
    chat.buttonFrame = bf; env.ChatFrame1 = chat
    bf.upButton, bf.downButton, bf.bottomButton = frame("up", bf), frame("down", bf), frame("bottom", bf)
    function bf:Layout()
        mutate()
        local list, seen = {}, {}
        for _, child in ipairs(self.children) do
            if not seen[child] and child.parent == self and not child.ignoreInLayout then
                list[#list + 1] = child; seen[child] = true
            end
        end
        table.sort(list, function(x, y) return (x.layoutIndex or 100) < (y.layoutIndex or 100) end)
        local top = self:GetTop()
        for _, child in ipairs(list) do
            child:SetPoint("TOP", self, "TOP", 0, top - self:GetTop())
            top = top - child.height - (child.bottomPadding or 0)
        end
        self.height = self:GetTop() - top
    end
    local names = { "FriendsMicroButton", "ChatFrameChannelButton", "FluxCCPChatGuildButton", "FluxCCPChatBagButton",
        "FluxCCPChatDurabilityButton", "FluxCCPChatCopyButton", "ChatFrameMenuButton", "FluxCCPChatSettingsButton" }
    for i, name in ipairs(names) do
        env[name] = frame(name, bf, name == "FluxCCPChatBagButton" and 37 or 27)
        env[name].layoutIndex = i + 3
        env[name].click = function() return name end
    end
    env.GENERAL_CHAT_DOCK = { selected = chat }
    env.FCFDock_GetSelectedWindow = function(dock) return dock.selected end
    local windows = { chat }
    for i = 2, 3 do
        local cf = frame("ChatFrame" .. i, env.UIParent, 240); cf.top, cf.hidden, cf.id = 370, true, i
        cf.buttonFrame = frame("ChatFrame" .. i .. "ButtonFrame", cf)
        env[cf.name] = cf; windows[i] = cf
    end
    function state.select(index)
        env.GENERAL_CHAT_DOCK.selected = windows[index]
        -- Native FCFDock_UpdateTabs may hide/show windows in combat. This
        -- changes inherited visibility without an addon protected-frame write.
        for i, cf in ipairs(windows) do cf.hidden = i ~= index end
    end
    assert(load("local _, ns = ...\n" .. (body or production), "@production-chat-column", "t", env))("_FluxUI", { Flux = env.Flux })
    function state.regen()
        for _, r in ipairs(state.frames) do
            if r.events.PLAYER_REGEN_ENABLED then r.scripts.OnEvent(r, "PLAYER_REGEN_ENABLED") end
        end
    end
    return state, chat, bf, env, names
end
local function exercise(branch, side, body)
    local state, chat, bf, env, names = fixture(branch, side, body)
    env.FluxCCP.PlaceColumnButtons()
    check(env.FriendsMicroButton:GetTop() == 369, branch .. ": first button matches modern background-top alignment")
    for _, name in ipairs(names) do
        local button = env[name]
        check(button.click() == name and not button.hidden, branch .. ": button action and visibility retained: " .. name)
        check(button:GetParent() == ((branch == "classic_era" or branch == "classic_anniversary") and bf or env.FluxCCPChatColumn),
            branch .. ": native strip or holder ownership retained: " .. name)
    end
    chat.top, chat.Background.top = 400, 403
    env.FluxCCP.PlaceColumnButtons()
    check(env.FriendsMicroButton:GetTop() == 399, branch .. ": column follows chat after layout change")
    local before = state.created
    for _ = 1, 100 do env.FluxCCP.PlaceColumnButtons() end
    check(state.created == before, branch .. ": repeated layouts reuse holder")
    for _ = 1, 3 do
        state.combat = true
        local writes = state.writes
        for _ = 1, 20 do env.FluxCCP.PlaceColumnButtons(); env.FluxCCP.PinClassicButtonFrame(chat) end
        check(state.writes == writes and state.illegal == 0, branch .. ": combat layout performs no protected writes")
        state.combat = false; state.regen()
        local after = state.writes; state.regen()
        check(state.writes == after, branch .. ": combat reconciliation runs once")
    end
    check(state.created == before + 1, branch .. ": combat cycles reuse one waiter")
    chat.Background = nil
    env.FluxCCP.PlaceColumnButtons()
    check(env.FriendsMicroButton:GetTop() == 399, branch .. ": missing background has matching safe fallback")
    check((branch ~= "classic_era" and branch ~= "classic_anniversary") or bf.target == chat,
        branch .. ": secure strip is anchored through a frame, never a texture")
    env.FluxCCPChatBagButton.height = 100
    env.FluxCCP.PlaceColumnButtons()
    if branch == "classic_era" or branch == "classic_anniversary" or branch == "classic" then
        check(env.FluxCCPChatSettingsButton:GetBottom() >= chat:GetBottom() - 32 - .01,
            branch .. ": tall Classic stack keeps every button above edit-box floor")
    else
        check(env.FriendsMicroButton:GetTop() == 399, branch .. ": modern layout stays unchanged despite stale legacy flag")
    end
    env.FluxCCPChatBagButton.height = 37
    env.FluxCCP.PlaceColumnButtons()
    check(env.FriendsMicroButton:GetTop() == 399, branch .. ": shorter stack returns to shared top alignment")
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    exercise(branch, "left"); exercise(branch, "right")
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    for _, side in ipairs({ "left", "right" }) do
        local s, chat, bf, env, names = fixture(branch, side)
        -- Modern Social uses QuickJoin, whose original parent is General's
        -- button frame even though its anchor already follows Channel.
        if branch == "live" or branch == "forever" then
            env.FriendsMicroButton = nil
            names[1] = "QuickJoinToastButton"
            local qj = env.CreateFrame("Button", "QuickJoinToastButton", bf)
            function qj:IsVisible() return not self.hidden and self.parent:IsVisible() end
        end
        env.FluxCCP.PlaceColumnButtons()
        local start = assert(source:find("local function SelectedChatWindowId()", 1, true))
        local selected = source:sub(start)
        selected = selected:sub(1, assert(selected:find("\nlocal function SetStateArt", 1, true)) - 1)
        local getCopyWindow = assert(load(selected .. "\nreturn SelectedChatWindowId", "@copy-chat-selection", "t", env))()
        for _, combat in ipairs({ false, true }) do
            s.combat = combat
            for _, tab in ipairs({ 2, 3, 1, 3, 2 }) do
                s.select(tab)
                local writes = s.writes
                env.FluxCCP.PlaceColumnButtons()
                if combat then check(s.writes == writes, "combat tab selection needs no protected reparent or show") end
                for _, name in ipairs(names) do
                    check(env[name]:IsVisible(), branch .. ": " .. name .. " stays visible on tab " .. tab)
                end
                check(getCopyWindow() == tab, "Copy still reads the selected tab")
            end
        end
        s.combat = false; s.regen()
        env.FluxCCPChatCopyButton._fluxChatOptHidden = true
        env.FluxCCPChatCopyButton:Hide()
        s.select(1); env.FluxCCP.PlaceColumnButtons()
        check(not env.FluxCCPChatCopyButton:IsVisible(), "persistent column respects disabled button settings")
    end
end
local function replace(old, new)
    local at = assert(production:find(old, 1, true))
    return production:sub(1, at - 1) .. new .. production:sub(at + #old)
end
local mutations = {
    { replace("offset = bgTop - top - 4", "offset = 55"), "classic_era", "first button matches modern" },
    { replace("local x, y = 0, ColumnTopOffset(chat)", "local x, y = 0, 32"), "classic", "first button matches modern" },
    { production:gsub('if InCombatLockdown%(%) then', 'if false then'), "classic_era", "combat layout" },
    { replace("offset = math.max(offset, bottom - editHeight + contentHeight - top)", "offset = offset"),
        "classic_era", "tall Classic stack keeps every button above edit-box floor" },
}
for _, mutation in ipairs(mutations) do
    local ok, err = pcall(exercise, mutation[2], "left", mutation[1])
    check(not ok and tostring(err):find(mutation[3], 1, true), "column regression rejected: " .. mutation[3])
end
print("chat column: " .. checks .. " checks across five branches, both sides; " .. #mutations .. " regressions rejected")
