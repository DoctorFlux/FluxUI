-- Actual Blizzard secure dispatch + production EBS action/pool/click/manager.
-- Frame access, hardware events and macro commands are models, not native taint proof.
local managerPath = arg[1] or "ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua"
local sourceRoot = arg[2]
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function read(path)
    local f = sourceRoot and io.open(sourceRoot .. "/" .. path, "rb")
    f = f or assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end
local chords = { "", "SHIFT", "CTRL", "ALT", "SHIFT-CTRL", "SHIFT-ALT", "CTRL-ALT", "SHIFT-CTRL-ALT" }
for _, branch in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local s = { mod = "", combat = false, timers = {}, frames = {}, overrides = {}, actions = {}, keyDown = true, writes = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local function run(body, ...) return assert(load(body, "@utility-native-input", "t", env))(...) end
    local function held(key)
        local chord = s.maskedDispatch and "" or s.mod
        return ("-" .. chord .. "-"):find("-" .. key .. "-", 1, true) ~= nil
    end
    env.IsShiftKeyDown = function() return held("SHIFT") end
    env.IsControlKeyDown = function() return held("CTRL") end
    env.IsAltKeyDown = function() return held("ALT") end
    env.InCombatLockdown = function() return s.combat end
    env.GetTime = function() return 100 end
    env.GetCursorInfo = function() end
    env.UnitClass = function() return "Mage", "MAGE" end
    env.UnitExists = function(unit) return unit == "mouseover" and s.moExists or false end
    env.UnitCanAssist = function(_, unit) return unit == "mouseover" and s.moExists and s.moFriend end
    env.UnitCanAttack = function(_, unit) return unit == "mouseover" and s.moExists and not s.moFriend end
    env.UnitHasVehicleUI = function() return false end
    env.GetModifiedClick = function() return s.moModifier or "NONE" end
    env.IsModifiedClick = function() return s.moModifier and held(s.moModifier) or false end
    env.GetCVarBool = function(key) return key == "ActionButtonUseKeyDown" and s.keyDown end
    env.GetCVar = function(key) if key == "enableMouseoverCast" then return s.moEnabled and "1" or "0" end end
    env.IsMouseoverCastSupported = function() return branch == "live" or branch == "forever" end
    env.FluxOptions = { GetActionbarsDB = function() return { mouseoverCast = s.moEnabled == true } end }
    env.SpellCanTargetItem = function() return false end
    env.SpellCanTargetItemID = function() return false end
    env.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    env.securecallfunction = function(fn, ...) return fn(...) end
    env.CopyTable = function(t) local c = {}; for k, v in pairs(t) do c[k] = v end; return c end
    env.C_PaperDollInfo = { GetInventorySlotInfo = function() return 16 end, IsRangedSlotShown = function() return false end }
    env.GetInventorySlotInfo = env.C_PaperDollInfo.GetInventorySlotInfo
    env.Enum = { ForbiddenAspect = { ScriptedInput = 1 } }
    env.SecureCmdOptionParse = function(tail)
        for fragment in (tail .. ";"):gmatch("(.-);") do
            local value = fragment:gsub("%b[]", ""):match("^%s*(.-)%s*$")
            local any, matched = false, false
            for cond in fragment:gmatch("%[(.-)%]") do
                any = true; local ok = true
                for term in cond:gmatch("[^,]+") do
                    local yes, no = term:match("^mod:(.+)$"), term:match("^nomod:(.+)$")
                    if yes and not held(yes:upper()) or no and held(no:upper()) then ok = false end
                    if term == "exists" and not s.moExists then ok = false end
                    if term == "help" and not (s.moExists and s.moFriend) then ok = false end
                    if term == "harm" and not (s.moExists and not s.moFriend) then ok = false end
                end
                matched = matched or ok
            end
            if value ~= "" and (not any or matched) then return value end
        end
    end
    local Frame = {}
    function Frame:GetAttribute(a, b, c)
        if not b then return self.attrs[a] end
        for _, k in ipairs({ a..b..c, "*"..b..c, a..b.."*", "*"..b.."*", a..b, b..c, b.."*", b }) do
            if self.attrs[k] ~= nil then return self.attrs[k] end
        end
    end
    function Frame:SetAttribute(k, v)
        check(not s.combat or s.secure, "no insecure combat attribute write: " .. k)
        self.attrs[k] = v
        if not s.secure then s.writes = s.writes + 1 end
    end
    function Frame:GetName() return self.name end
    function Frame:GetParent() return self.parent end
    function Frame:SetScript(k, fn) self.scripts[k] = fn end
    function Frame:HookScript(k, fn)
        local before = self.scripts[k]
        self.scripts[k] = function(...) if before then before(...) end; fn(...) end
    end
    function Frame:RegisterEvent(e) self.events[e] = true end
    function Frame:RegisterUnitEvent(e) self.events[e] = true end
    function Frame:RegisterForClicks(...) check(not s.combat, "no combat click registration"); self.clicks = {}; for _, edge in ipairs({...}) do self.clicks[edge] = true end end
    function Frame:HasAccessConstraints() return false end
    function Frame:HasAnyForbiddenAspects() return false end
    function Frame:IsForbidden() return false end
    function Frame:Hide() check(not s.combat, "no combat protected hide"); self.shown = false end
    function Frame:Show() check(not s.combat, "no combat protected show"); self.shown = true end
    function Frame:SetSize() check(not s.combat, "no combat size write") end
    function Frame:EnableMouse() end
    function Frame:Execute(body) env.owner = self; run(body) end
    function Frame:WrapScript(w, script, body)
        if script == "OnClick" then w.wrap = body else w.secureScripts = w.secureScripts or {}; w.secureScripts[script] = body end
    end
    function Frame:UnwrapScript(w, script)
        if script == "OnClick" then w.wrap = nil elseif w.secureScripts then w.secureScripts[script] = nil end
    end
    function Frame:Click(button, down)
        local edge = down and "AnyDown" or "AnyUp"
        if self.clicks and not self.clicks[edge] then return end
        if self.wrap then
            local fn = run("return function(self, button, down)\n" .. self.wrap .. "\nend")
            local remap = fn(self, button, down)
            if remap == false then return end
            if type(remap) == "string" then button = remap end
        end
        local previous = s.executing; s.executing = self
        local function wrapped(script)
            local body = self.secureScripts and self.secureScripts[script]
            if body then
                s.secure = true
                run("local self, button = ...\n" .. body, self, button)
                s.secure = false
            end
        end
        wrapped("PreClick")
        if self.scripts.PreClick then self.scripts.PreClick(self, button, down) end
        env.SecureActionButton_OnClick(self, button, down)
        wrapped("PostClick")
        if self.scripts.PostClick then self.scripts.PostClick(self, button, down) end
        s.executing = previous
    end
    env.GetFrameMetatable = function() return { __index = Frame } end
    env.CreateFrame = function(_, name, parent)
        check(not s.combat, "no combat frame creation")
        local f = setmetatable({ attrs = {}, scripts = {}, events = {}, name = name, parent = parent, shown = true }, { __index = Frame })
        if name then env[name] = f end; s.frames[#s.frames + 1] = f; return f
    end
    env.UIParent = env.CreateFrame("Frame", "UIParent")
    local nativePath = "../__AddonsForRef/wow-ui-source-" .. branch .. "/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua"
    run(read(nativePath))
    -- Dispatch /cast and /use through Blizzard's actual handlers, including
    -- /cast item:ID. Do not infer the action kind from the slash word.
    local commands = {}
    env.SLASH_COMMAND = { CAST = "cast", USE = "use" }
    env.SLASH_COMMAND_CATEGORY = { COMBAT = 1 }
    env.SlashCommandUtil = { CheckAddSecureSlashCommand = function(command, _, fn) commands[command] = fn end }
    -- A spell-info lookup can reject the ranked cast string even though the
    -- protected cast function accepts it. Do not assume these APIs agree.
    env.C_Spell = { DoesSpellExist = function(token) return token:match("^Spell%d+$") ~= nil end,
        IsSpellHelpful = function(id) return id ~= 102 end, IsSpellHarmful = function(id) return id == 102 end }
    env.C_Item = { GetItemInfo = function(token) if token:match("^item:%d+$") then return token end end,
        IsEquippableItem = function() return false end, IsEquippedItem = function() return false end,
        IsHelpfulItem = function(id) return id ~= 202 end, IsHarmfulItem = function(id) return id == 202 end }
    env.SecureCmdItemParse = function(token) return token end
    env.CastSpellByName = function(token, unit) s.actions[#s.actions + 1] = { "cast", token, unit } end
    env.CastSpellByID = function(id, unit) s.actions[#s.actions + 1] = { "cast", id, unit } end
    env.SecureCmdUseItem = function(token, _, _, unit) s.actions[#s.actions + 1] = { "use", token, unit } end
    local slashSource = read("../__AddonsForRef/wow-ui-source-" .. branch .. "/Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommands.lua")
    local first = assert(slashSource:find("SlashCommandUtil.CheckAddSecureSlashCommand(SLASH_COMMAND.CAST,", 1, true))
    local last = assert(slashSource:find("SlashCommandUtil.CheckAddSecureSlashCommand(SLASH_COMMAND.STOPCASTING,", first, true))
    run(slashSource:sub(first, last - 1))
    env.C_Macro = { RunMacroText = function() error("ordinary utility must work without RunMacroText") end }
    env.RunMacro = function(id) s.actions[#s.actions + 1] = { "macro", id } end
    local flux = { EBS = { buttons = {} }, Combat = { InLockdown = env.InCombatLockdown },
        Spell = { FormatCastAttribute = function(id) return "Spell" .. id end } }
    env.Flux, env.FluxButton = flux, {}; local ns = { Flux = flux }
    flux.Restricted = { Works = function() return branch ~= "forever" end, PagingWorks = function() return true end }
    flux.Restricted.WrapScript = function(header, frame, script, body)
        if branch == "forever" then return false end
        header:WrapScript(frame, script, body); return true
    end
    flux.Restricted.UnwrapScript = function(header, frame, script)
        if branch == "forever" then return false end
        header:UnwrapScript(frame, script); return true
    end
    run(read("Core/ButtonFX/Click.lua"), "_FluxUI", ns)
    run(read("Binding/Core/SecurePool.lua"), "_FluxUI", ns)
    run(read("Binding/Core/ChordMap.lua"), "_FluxUI", ns)
    run(read("ExtraButtonSystem/Engine/Action.lua"), "_FluxUI", ns)
    run(read("Core/Engine/MouseoverCast.lua"), "_FluxUI", ns)
    run(read("ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua"), "_FluxUI", ns)
    run(read(managerPath))
    local manager, assign, action = env.FluxNCUtilitySlotsManager, env.FluxNCUtilitySlots, flux.EBS.Action
    local w = env.CreateFrame("CheckButton", "UtilityInputHost")
    local b = { Widget = w, slotIndex = 1 }
    function b:SetAction(t, v) action.SetAction(self, t, v) end
    function b:ClearAction() action.Clear(self) end
    function b:TranslateMacro() action.TranslateMacro(self) end
    manager.buttons[1] = b; flux.EBS.buttons[1] = b
    local modifier; env.FluxModifierTracker = { Register = function(_, fn) modifier = fn end }
    local pending = s.timers; s.timers = {}; for _, fn in ipairs(pending) do fn() end
    env.GetBindingKey = function(command) if command == "FLUXSPELLBOOKSLOT1" then return "Q", "E" end end
    env.ClearOverrideBindings = function() check(not s.combat, "no combat binding clear"); s.overrides = {} end
    env.SetOverrideBindingClick = function(_, _, key, name, button)
        check(not s.combat, "no combat binding writes"); s.overrides[key] = { name, button }
    end
    local function press(frame, button) frame:Click(button, true); frame:Click(button, false) end
    local function configure(reverse)
        local map = {}
        for i, chord in ipairs(chords) do
            map[chord] = { type = ((i + (reverse and 1 or 0)) % 2 == 0) and "item" or "spell", id = 100 + i }
        end
        env.FluxNCUtilitySlotsDB = { slots = { map, {}, {}, {} } }
        s.combat = false; manager._DoUpdateAllSlots()
        flux.ButtonFX.Click.Apply(w)
        check(w.attrs.clickbutton == nil and w.attrs.clickbutton1 == nil and w.attrs.macrotext == nil,
            "ordinary utility has no macro/delegate execution dependency")
        check(w.attrs.type1 == map[""].type and w.attrs["shift-type1"] == map.SHIFT.type,
            "native modifier action types are independently prepared")
        s.mod = "SHIFT"
        local binding = assert(s.overrides["SHIFT-Q"]); local n = #s.actions
        s.maskedDispatch = true
        env[binding[1]]:Click(binding[2], true)
        check(#s.actions == n + ((branch == "forever" or s.keyDown) and 1 or 0),
            "encoded utility keys preserve the configured down/up edge")
        env[binding[1]]:Click(binding[2], false)
        s.maskedDispatch = false
        local expected, got = map.SHIFT, s.actions[#s.actions]
        check(#s.actions == n + 1 and got[1] == (expected.type == "spell" and "cast" or "use")
            and got[2] == (expected.type == "spell" and "Spell" or "item:") .. expected.id,
            "first slot-update pass installs chord-specific bindings after preparing native actions")
        s.mod = ""
        return map
    end
    for _, reverse in ipairs({ false, true }) do
        local map = configure(reverse)
        for _, keyDown in ipairs({ true, false }) do
            s.keyDown = keyDown; flux.ButtonFX.Click.SyncCVars()
            for _, combat in ipairs({ false, true }) do
                s.combat = combat
                local writes, frames = s.writes, #s.frames
                for _, chord in ipairs(chords) do
                    s.mod = chord
                    if modifier then modifier() end
                    local expected = map[chord]
                    for _, input in ipairs({ "mouse", "primary", "secondary" }) do
                        local n = #s.actions
                        if input == "mouse" then press(w, "LeftButton") else
                            local key = (chord ~= "" and chord .. "-" or "") .. (input == "primary" and "Q" or "E")
                            key = env.FluxBindingChordMap3.Normalize(key)
                            local binding = s.overrides[key]
                            check(binding ~= nil, "explicit item/spell modifier binding " .. key)
                            press(env[binding[1]], binding[2])
                        end
                        check(#s.actions == n + 1, branch .. " one action per press/release " .. input .. " " .. chord)
                        local got = s.actions[#s.actions]
                        check(got[1] == (expected.type == "spell" and "cast" or "use"), "correct action kind")
                        check(got[2] == (expected.type == "spell" and "Spell" or "item:") .. expected.id, "correct exact item/spell identity")
                        -- Secure action selection must return immediately on
                        -- modifier release, before the visual bus even runs.
                        s.mod = ""
                        n = #s.actions; press(w, "LeftButton")
                        local base = map[""]
                        check(#s.actions == n + 1, "release still executes exactly one normal action")
                        got = s.actions[#s.actions]
                        check(got[1] == (base.type == "spell" and "cast" or "use")
                            and got[2] == (base.type == "spell" and "Spell" or "item:") .. base.id,
                            "combat release restores the normal action without visual callback or action rewrite")
                        s.mod = chord
                    end
                end
                if combat then
                    manager.UpdateButton(b, {}); manager.UpdateBindings()
                    check(manager._pendingUpdate and manager._pendingBindings, "combat edits/bindings defer")
                    check(s.writes == writes and #s.frames == frames, "combat modifiers do not rewrite/recreate actions")
                end
                s.combat = false
            end
        end
    end
    if branch == "forever" then
        s.combat = false; configure(false); s.keyDown = true
        flux.ButtonFX.Click.SyncCVars()
        s.combat = true; s.mod = "SHIFT"
        local bind = assert(s.overrides["SHIFT-Q"]); local n = #s.actions
        env[bind[1]]:Click(bind[2], true)
        check(#s.actions == n + 1 and s.actions[#s.actions][1] == "use", "modifier item executes on key-down before Shift can be released")
        s.mod = ""
        env[bind[1]]:Click(bind[2], false)
        check(#s.actions == n + 1, "releasing Shift before key-up cannot cast the normal spell or double-use")
    end
    -- Native spell actions preserve exact ranked tokens without macro commands.
    -- Test normal/modifier/release and mixed ranked/bare/item assignments.
    s.combat = false; s.mod = ""
    local formatted = { [1460] = "Arcane Intellect(Rank 2)", [1459] = "Arcane Intellect(Rank 1)",
        [1472] = "Intelligence des Arcanes(Rang 2)" }
    flux.Spell.FormatCastAttribute = function(id) return formatted[id] or "Spell" .. id end
    local rank2, rank1 = { type = "spell", id = 1460 }, { type = "spell", id = 1459 }
    local item, bare = { type = "item", id = 201 }, { type = "spell", id = 101 }
    local originalItemInfo = env.C_Item.GetItemInfo
    env.C_Item.GetItemInfo = function(token)
        -- Bare spell/item name collisions must retain CAST spell priority.
        if token == "Spell101" then return token end
        return originalItemInfo(token)
    end
    for _, map in ipairs({ { [""] = rank2, SHIFT = item }, { [""] = item, SHIFT = rank1 },
        { [""] = rank2, SHIFT = bare, CTRL = item, ALT = rank1,
            ["SHIFT-CTRL"] = { type = "spell", id = 1472 } } }) do
        s.combat = false; s.mod = ""
        env.FluxNCUtilitySlotsDB = { slots = { map, {}, {}, {} } }
        manager.UpdateButton(b, map); manager.UpdateBindings()
        for _, keyDown in ipairs({ true, false }) do
            s.keyDown = keyDown; flux.ButtonFX.Click.SyncCVars()
            for _, combat in ipairs({ false, true }) do
                s.combat = combat; local writes = s.writes
                for _, chord in ipairs(chords) do
                    s.mod = chord
                    local entry = map[chord] or map[""]
                    check(env.SecureButton_GetModifiedAttribute(w, "type", "LeftButton") == entry.type,
                        "native ranked/bare/item selection has the exact action kind")
                    for _, input in ipairs({ "mouse", "Q", "E" }) do
                      if input == "mouse" or chord == "" or map[chord] then
                        local frame, button = w, "LeftButton"
                        if input ~= "mouse" then
                            local key = env.FluxBindingChordMap3.Normalize((chord ~= "" and chord .. "-" or "") .. input)
                            local bind = assert(s.overrides[key]); frame, button = env[bind[1]], bind[2]
                        end
                        local n = #s.actions; press(frame, button)
                        local got = s.actions[#s.actions]
                        local token = entry.type == "item" and "item:" .. entry.id or flux.Spell.FormatCastAttribute(entry.id)
                        check(#s.actions == n + 1 and got[1] == (entry.type == "item" and "use" or "cast") and got[2] == token,
                            branch .. " ranked/bare/item exact action " .. input .. " " .. chord)
                      end
                    end
                end
                s.mod = ""; local n = #s.actions; press(w, "LeftButton")
                local base = map[""]; local got = s.actions[#s.actions]
                local token = base.type == "item" and "item:" .. base.id or flux.Spell.FormatCastAttribute(base.id)
                check(#s.actions == n + 1 and got[2] == token, "ranked/item normal action restored immediately on combat release")
                check(s.writes == writes, "ranked modifier use adds no protected action writes")
            end
        end
    end
    env.C_Item.GetItemInfo = originalItemInfo
    -- Read-only saved setup reported in this task: Study on U, water on Shift-U.
    s.combat = false; s.mod = ""
    flux.Spell.FormatCastAttribute = function(id) return id == 1302508 and "Study(Comprehension)" or "Spell" .. id end
    env.GetBindingKey = function(command) if command == "FLUXSPELLBOOKSLOT1" then return "U", "E" end end
    local savedMap = { [""] = { type = "spell", id = 1302508 }, SHIFT = { type = "item", id = 2136 } }
    env.FluxNCUtilitySlotsDB = { slots = { savedMap, {}, {}, {} } }
    manager.UpdateButton(b, savedMap); manager.UpdateBindings()
    for _, combat in ipairs({ false, true }) do
        s.combat = combat
        for _, step in ipairs({ { "", "U", "cast", "Study(Comprehension)" }, { "SHIFT", "SHIFT-U", "use", "item:2136" },
            { "", "U", "cast", "Study(Comprehension)" } }) do
            s.mod = step[1]
            local bind = assert(s.overrides[step[2]]); local n = #s.actions
            press(env[bind[1]], bind[2])
            local got = s.actions[#s.actions]
            check(#s.actions == n + 1 and got[1] == step[3] and got[2] == step[4],
                "saved Study/Shift-water key path chooses exactly the requested action")
        end
    end
    s.mod = "SHIFT"
    local info = env.C_Item.GetItemInfo; env.C_Item.GetItemInfo = function() end
    local bind = assert(s.overrides["SHIFT-U"]); local count = #s.actions
    press(env[bind[1]], bind[2])
    check(#s.actions == count + 1 and s.actions[#s.actions][2] == "item:2136",
        "cold item metadata only attempts the selected item token; never the normal spell")
    env.C_Item.GetItemInfo = info
    -- A native item action must remain an item even with cold metadata.
    check(s.actions[#s.actions][1] == "use", "cold item never enters the spell cast handler")
    s.combat = false; s.mod = ""
    flux.Spell.FormatCastAttribute = function(id) return id end
    local coldMap = { [""] = { type = "spell", id = 1460 }, SHIFT = { type = "item", id = 2136 } }
    env.FluxNCUtilitySlotsDB = { slots = { coldMap, {}, {}, {} } }
    manager.UpdateButton(b, coldMap); manager.UpdateBindings()
    for _, combat in ipairs({ false, true }) do
        s.combat = combat; s.mod = ""
        local bind = assert(s.overrides.U); local n = #s.actions
        press(env[bind[1]], bind[2])
        check(#s.actions == n + 1 and s.actions[#s.actions][1] == "cast" and s.actions[#s.actions][2] == 1460,
            "cold spell metadata retains numeric native spell identity")
    end
    flux.Spell.FormatCastAttribute = function(id) return "Spell" .. id end
    -- End-to-end: manager prepares both action and mouseover metadata; actual
    -- secure target selection and action handlers receive the selected unit.
    s.combat = false; s.mod = ""
    local moMap = { [""] = { type = "spell", id = 1460 }, SHIFT = { type = "item", id = 202 },
        CTRL = { type = "spell", id = 102 }, ALT = { type = "item", id = 201 } }
    env.FluxNCUtilitySlotsDB = { slots = { moMap, {}, {}, {} } }
    flux.Spell.FormatCastAttribute = function(id) return id == 1460 and "Arcane Intellect(Rank 2)" or "Spell" .. id end
    manager.UpdateButton(b, moMap); manager.UpdateBindings()
    for _, enabled in ipairs({ false, true, false }) do
        s.combat = false; s.moEnabled = enabled; flux.MouseoverCast.Apply()
        for _, keyDown in ipairs({ true, false }) do
            s.keyDown = keyDown; flux.ButtonFX.Click.SyncCVars()
            for _, combat in ipairs({ false, true }) do
                s.combat = combat; local writes = s.writes
                for _, chord in ipairs(chords) do
                    s.mod = chord; local entry = moMap[chord] or moMap[""]
                    for _, target in ipairs({ "friendly", "hostile", "missing" }) do
                        s.moExists, s.moFriend = target ~= "missing", target == "friendly"
                        local helpful = entry.id ~= 102 and entry.id ~= 202
                        local want = enabled and s.moExists and (helpful == s.moFriend)
                        for _, input in ipairs({ "mouse", "U", "E" }) do
                            if input == "mouse" or chord == "" or moMap[chord] then
                                local frame, button = w, "LeftButton"
                                if input ~= "mouse" then
                                    local key = env.FluxBindingChordMap3.Normalize((chord ~= "" and chord .. "-" or "") .. input)
                                    local bind = assert(s.overrides[key]); frame, button = env[bind[1]], bind[2]
                                end
                                local n = #s.actions; press(frame, button); local got = s.actions[#s.actions]
                                check(#s.actions == n + 1 and got[3] == (want and "mouseover" or nil),
                                    branch .. " actual utility handler target " .. input .. " " .. chord .. " " .. target)
                                check(got[1] == (entry.type == "spell" and "cast" or "use"), "mouseover retains selected action kind")
                                check(frame.attrs.unit == nil and w.attrs.unit == nil, "mouseover unit is cleared after hardware action")
                            end
                        end
                    end
                end
                check(s.writes == writes, "mouseover combat input only writes unit from the secure click wrapper")
            end
        end
    end
    s.combat = false; s.moExists = false; s.moEnabled = false; flux.MouseoverCast.Apply()
    -- Binding lookup knows the triggering chord even if modifier queries are
    -- masked during action dispatch. Native attribute lookup must not turn it
    -- into the normal action, including mouseover target classification.
    for _, map in ipairs({
        { [""] = { type = "spell", id = 1302508 }, SHIFT = { type = "item", id = 2136 } },
        { [""] = { type = "spell", id = 1460 }, SHIFT = { type = "spell", id = 604 }, CTRL = { type = "spell", id = 1008 } },
        { [""] = { type = "item", id = 201 }, SHIFT = { type = "spell", id = 102 }, ["SHIFT-CTRL"] = { type = "item", id = 202 } }
    }) do
        s.combat = false; s.mod = ""
        env.FluxNCUtilitySlotsDB = { slots = { map, {}, {}, {} } }
        manager._DoUpdateAllSlots()
        for _, enabled in ipairs({ false, true }) do
            s.moEnabled = enabled; flux.MouseoverCast.Apply()
            for _, keyDown in ipairs({ true, false }) do
                s.keyDown = keyDown; flux.ButtonFX.Click.SyncCVars()
                for _, combat in ipairs({ false, true }) do
                    s.combat = combat; local writes = s.writes
                    for _, chord in ipairs(chords) do
                        local entry = map[chord]
                        if entry then
                            s.mod = chord
                            for _, target in ipairs({ "friendly", "hostile" }) do
                                s.moExists, s.moFriend = true, target == "friendly"
                                local helpful = entry.id ~= 102 and entry.id ~= 202
                                for _, key in ipairs({ "U", "E" }) do
                                    local bindKey = env.FluxBindingChordMap3.Normalize((chord ~= "" and chord .. "-" or "") .. key)
                                    local bind = assert(s.overrides[bindKey]); local n = #s.actions
                                    s.maskedDispatch = true
                                    press(env[bind[1]], bind[2])
                                    s.maskedDispatch = false
                                    local got = s.actions[#s.actions]
                                    local token = entry.type == "spell" and flux.Spell.FormatCastAttribute(entry.id) or "item:" .. entry.id
                                    check(#s.actions == n + 1 and got[1] == (entry.type == "spell" and "cast" or "use") and got[2] == token,
                                        branch .. " binding carries the triggering modifier independently: " .. bindKey)
                                    check(got[3] == (enabled and helpful == s.moFriend and "mouseover" or nil),
                                        "encoded utility chord also selects its own mouseover target gate")
                                end
                            end
                        end
                    end
                    check(s.writes == writes, "encoded modifier input does not rewrite protected actions")
                    s.combat = false
                end
            end
        end
    end
    s.combat = false; s.mod = ""; s.moExists = false; s.moEnabled = false; flux.MouseoverCast.Apply()
    if branch == "live" or branch == "forever" then
        s.moEnabled, s.moModifier = true, "SHIFT"
        local gated = { [""] = { type = "spell", id = 1460 }, SHIFT = { type = "spell", id = 604 }, CTRL = { type = "spell", id = 1008 } }
        env.FluxNCUtilitySlotsDB = { slots = { gated, {}, {}, {} } }
        manager._DoUpdateAllSlots(); flux.MouseoverCast.Apply()
        s.combat = true; s.moExists, s.moFriend = true, true
        for _, key in ipairs({ "U", "SHIFT-U", "CTRL-U" }) do
            local bind = assert(s.overrides[key]); local n = #s.actions
            s.maskedDispatch = true; press(env[bind[1]], bind[2]); s.maskedDispatch = false
            check(#s.actions == n + 1 and s.actions[#s.actions][3] == (key == "SHIFT-U" and "mouseover" or nil),
                "encoded key chord retains the native mouseover modifier gate during masked dispatch")
        end
        s.combat = false; s.moModifier = nil; s.moEnabled = false; flux.MouseoverCast.Apply()
    end
    env.GetBindingKey = function(command) if command == "FLUXSPELLBOOKSLOT1" then return "SHIFT-U", "CTRL-E" end end
    local modifiedKeys = { [""] = { type = "spell", id = 1460 }, SHIFT = { type = "spell", id = 604 },
        CTRL = { type = "spell", id = 1008 }, ["SHIFT-CTRL"] = { type = "item", id = 202 } }
    env.FluxNCUtilitySlotsDB = { slots = { modifiedKeys, {}, {}, {} } }
    manager._DoUpdateAllSlots()
    s.combat = true
    for _, step in ipairs({ { "SHIFT-U", "cast", "Spell604" }, { "CTRL-E", "cast", "Spell1008" },
        { "CTRL-SHIFT-U", "use", "item:202" }, { "CTRL-SHIFT-E", "use", "item:202" } }) do
        local bind = assert(s.overrides[step[1]]); local n = #s.actions
        s.maskedDispatch = true; press(env[bind[1]], bind[2]); s.maskedDispatch = false
        local got = s.actions[#s.actions]
        check(#s.actions == n + 1 and got[1] == step[2] and got[2] == step[3],
            "already modified primary/secondary bindings preserve their full triggering chord")
    end
    s.combat = false
    env.GetBindingKey = function(command) if command == "FLUXSPELLBOOKSLOT1" then return "U", "E" end end
    flux.Spell.FormatCastAttribute = function(id) return "Spell" .. id end
    -- Use the production widget cursor suppression scripts as well as native
    -- dispatch. Dropping onto any modifier must not use its prepared action.
    if branch ~= "forever" then
        s.combat = false; s.mod = ""
        local widgetSource = read("ExtraButtonSystem/Engine/Widget.lua")
        local first = assert(widgetSource:find("local function ApplyExtraScripts", 1, true))
        local last = assert(widgetSource:find("\n--- Extra PostClick paint", first, true))
        local install = run("local Flux, EBS, Widget = ...\n" .. widgetSource:sub(first, last - 1) .. "\nreturn ApplyExtraScripts",
            flux, flux.EBS, { AfterClickPaint = function() end })
        install(b)
        local receive = action.OnReceiveDrag; local drops = 0
        action.OnReceiveDrag = function() drops = drops + 1 end
        env.GetCursorInfo = function() return "item", 201 end
        for _, chord in ipairs(chords) do
            s.mod = chord; local n = #s.actions
            press(w, "LeftButton")
            check(#s.actions == n, "cursor drop suppresses native modifier action " .. chord)
        end
        check(drops == #chords, "cursor assignment runs once per drop after restoring native types")
        env.GetCursorInfo = function() end; action.OnReceiveDrag = receive
    end
    s.combat = false
    env.GetBindingKey = function(command) if command == "FLUXSPELLBOOKSLOT1" then return "Q", "E" end end
    manager.UpdateButton(b, { SHIFT = { type = "spell", id = 777 } })
    s.mod = "CTRL-ALT"; s.combat = true
    local n = #s.actions; press(w, "LeftButton")
    check(#s.actions == n + 1 and s.actions[#s.actions][2] == "Spell777", "modifier-only preferred mirror executes in combat")
    n = #s.actions; press(w, "RightButton")
    check(#s.actions == n, "unmapped mouse button cannot run the visual macro body")
    s.combat = false
    env.FluxNCUtilitySlotsDB = { slots = { { SHIFT = { type = "spell", id = 777 } }, {}, {}, {} } }
    manager.UpdateBindings()
    check(s.overrides["SHIFT-Q"] and s.overrides["SHIFT-E"], "modifier-only assignment keeps both keys")
    check(not s.overrides["CTRL-Q"] and not s.overrides["ALT-Q"], "unassigned chords remain available to other bindings")
    action.Clear(b)
    for _, bind in pairs(s.overrides) do
        local n = #s.actions; press(env[bind[1]], bind[2])
        check(#s.actions == n, "generic clear also removes encoded utility key actions")
    end
    for _, chord in ipairs(chords) do
        s.mod = chord; local n = #s.actions; press(w, "LeftButton")
        check(#s.actions == n, "generic clear removes every native modifier action " .. chord)
    end
    check(b._fluxUtilityGetEntry == nil and w._fluxUtilityNative == nil,
        "generic clear retires native display and execution ownership")
    manager.UpdateButton(b, nil)
    s.combat = true; n = #s.actions; press(w, "LeftButton")
    check(#s.actions == n, "cleared utility cannot execute a stale delegated action")
end
print(("Utility secure input: %d checks; five Blizzard dispatchers; mouse + both keys; all chords; combat; both CVar edges PASS"):format(checks))
