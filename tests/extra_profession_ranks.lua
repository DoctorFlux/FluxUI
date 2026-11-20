-- Actual EBS assignment/watch, flyout normalization and utility macro builder.
-- Native metadata, frame sinks and combat delivery are models, not native proof.
local root = arg[1] or "."
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end
local fixture = read("tests/passive_ebs_visibility.lua")
fixture = fixture:sub(1, assert(fixture:find("\nlocal summary = {}", 1, true)) - 1)
local boot = assert(load(fixture .. "\nreturn boot", "@profession-fixture", "t",
    setmetatable({ arg = { [0] = "tests/extra_profession_ranks.lua", root } }, { __index = _G })))()
local anchors = { 2259, 2018, 7411, 4036, 2108, 3908, 2575, 2656, 2366, 8613,
    25229, 31252, 45357, 51005, 78670, 7620, 2550, 3273 }
local names = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Leatherworking",
    "Tailoring", "Mining", "Smelting", "Herbalism", "Skinning", "Jewelcrafting", "Prospecting",
    "Inscription", "Milling", "Archaeology", "Fishing", "Cooking", "First Aid" }
for _, family in ipairs({ "retail", "forever", "era", "anniversary", "mists" }) do
    local s = boot(family)
    local F, env = s.flux, s.env
    env.Flux = F
    local modern = family == "retail" or family == "forever"
    local metadata, book, deferred, slots = {}, {}, {}, {}
    local queries, layouts, utilityRefreshes = 0, 0, 0
    local function id(p, rank) return 900000 - p * 100 - rank end -- IDs decrease as ranks rise.
    for p, anchor in ipairs(anchors) do
        local name = family == "forever" and ("Métier " .. names[p]) or names[p]
        metadata[anchor] = { name = name }
        for rank = 1, 9 do
            metadata[id(p, rank)] = { name = name, subtext = "Tier " .. rank }
        end
        book[p] = id(p, 1)
    end
    metadata[101], metadata[102] = { name = "Fireball", subtext = "Rank 1" }, { name = "Fireball", subtext = "Rank 9" }
    metadata[103] = { name = "Alchemy Explosion" }
    metadata[104] = { name = "Alchemy Explosion" }
    book[19], book[20] = 102, 104
    env.C_Spell = { GetSpellInfo = function(token)
        local m = metadata[token]
        return m and { name = m.name, spellID = token, iconID = token }
    end }
    F.Spell.GetName = function(token) return metadata[token] and metadata[token].name end
    F.Spell.GetBaseSpell = function(token) return token end
    F.Spell.FormatCastAttribute = function(token)
        local m = metadata[token]; return m and (m.name .. "(" .. (m.subtext or "") .. ")") or token
    end
    F.Spell.GetTexture = function(token) return token end
    F.Combat = { InLockdown = function() return s.combat end,
        Defer = function(key, fn) deferred[key] = fn end }
    env.Enum = { SpellBookSpellBank = { Player = 0 }, SpellBookItemType = { Spell = 1, FutureSpell = 2 } }
    if modern then
        env.C_SpellBook = {
            GetNumSpellBookSkillLines = function() return 1 end,
            GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #book } end,
            GetSpellBookItemInfo = function(slot, bank)
                check(bank == 0, "modern player bank")
                queries = queries + 1
                local token = book[slot]; local m = metadata[token]
                return m and { itemType = s.future == slot and 2 or 1, spellID = token, name = m.name,
                    isPassive = s.passive == slot, isOffSpec = s.offspec == slot }
            end,
            IsSpellBookItemLowRank = function(slot) return s.lowrank == slot end,
        }
        -- Secondary skills with missing primary returns, plus an opener outside
        -- the ordinary spellbook lines. Never iterate this tuple with ipairs.
        env.GetProfessions = function() return nil, nil, nil, nil, 7, 8 end
        env.GetProfessionInfo = function(index)
            return metadata[anchors[index == 7 and 17 or 18]].name, nil, 1, 75, 1, index == 7 and 16 or 17, index
        end
    else
        env.C_SpellBook = nil
        env.GetSpellInfo = function(token)
            local m = metadata[token]; if m then return m.name, m.subtext, token, nil, nil, nil, token end
        end
        env.GetNumSpellTabs = function() return 1 end
        env.GetSpellTabInfo = function() return "General", nil, 0, #book end
        env.GetSpellBookItemInfo = function(slot)
            queries = queries + 1; return s.future == slot and "FUTURESPELL" or "SPELL", book[slot]
        end
        env.GetSpellBookItemName = function(slot) return metadata[book[slot]].name end
    end
    local ns = { Flux = F }
    local function loadSource(path) assert(load(read(root .. "/" .. path), "@" .. path, "t", env))("_FluxUI", ns) end
    loadSource("ExtraButtonSystem/Engine/Action.lua")
    local A = F.EBS.Action
    check(type(A.ResolveProfessionSpell) == "function", "profession resolver exists")
    F.EBS.Flyout = { attached = {}, MAX_BUTTONS = 36,
        Popup = { Layout = function() check(not s.combat, "flyout refresh outside combat"); layouts = layouts + 1 end } }
    loadSource("ExtraButtonSystem/FlyoutEngine/Def.lua")
    F.PlayerName = { GetCharKey = function() return "Tester-Realm" end }
    env.FluxFlyoutFavorites_Data = { ["Tester-Realm"] = { Profession = { nomod = id(18, 1) } } }
    loadSource("ExtraButtonSystem/FlyoutEngine/Favorites.lua")
    env.CreateFrame = function()
        return { RegisterEvent = function() end, RegisterUnitEvent = function() end, SetScript = function() end }
    end
    env.GetCursorInfo = function() end
    env.FluxNCUtilitySlots = { GetSlots = function() return slots end }
    loadSource("ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua")
    local M = env.FluxNCUtilitySlotsManager
    M.UpdateAllSlots = function() check(not s.combat, "utility refresh outside combat"); utilityRefreshes = utilityRefreshes + 1 end
    slots[1] = { [""] = { type = "spell", id = id(1, 1) }, SHIFT = { type = "spell", id = id(18, 1) } }
    local buttons, badges, savedFlyout = {}, {}, {}
    local function newButton(p, badge)
        local b = s:button("spell", false, badge)
        b.Widget.attrs = {}
        b.Widget.SetAttribute = function(w, key, value)
            check(not s.combat, "protected attribute outside combat"); w.attrs[key] = value
        end
        A.SetAction(b, "spell", id(p, 1))
        return b
    end
    for p = 1, #anchors do
        buttons[p], badges[p] = newButton(p), newButton(p, true)
        savedFlyout[p] = { type = "spell", spell = id(p, 1) }
    end
    local host = {}
    local rec = { buttons = F.EBS.Flyout.Def.NormalizeList(savedFlyout) }
    F.EBS.Flyout.attached[host] = rec
    local fireball = newButton(1); A.SetAction(fireball, "spell", 101)
    for rank = 2, 9 do
        for p = 1, #anchors do book[p] = id(p, rank) end
        -- Exactly the same count/offset as before, so the coarse bus need not fire.
        local before = queries
        for _ = 1, 40 do s.events.SKILL_LINES_CHANGED("SKILL_LINES_CHANGED") end
        check(queries == before, "skill burst waits for one bounded refresh")
        s:advance(0.25)
        check(queries - before <= #book + 2, "one book scan per skill burst")
        for p = 1, #anchors do
            for _, b in ipairs({ buttons[p], badges[p] }) do
                check(b.SpellId == id(p, rank), names[p] .. " current spell rank " .. rank)
                check(b.Widget.attrs.spell == F.Spell.FormatCastAttribute(id(p, rank)), "current secure cast token")
            end
            check(rec.buttons[p].spell == id(p, rank), "existing flyout rank updates")
            check(savedFlyout[p].spell == id(p, 1), "saved flyout assignment preserved")
            local normalized = F.EBS.Flyout.Def.NormalizeList(savedFlyout)
            check(normalized[p].spell == id(p, rank), "fresh/reloaded flyout resolves saved old rank")
        end
        local macro = M.BuildMacroText(slots[1])
        check(macro:find(F.Spell.FormatCastAttribute(id(1, rank)), 1, true), "base utility rank updates")
        check(macro:find(F.Spell.FormatCastAttribute(id(18, rank)), 1, true), "modifier utility rank updates")
        check(slots[1][""].id == id(1, 1), "saved utility entry unchanged")
        check(fireball.SpellId == 101, "explicit low combat spell rank retained")
        local promoted = F.EBS.Flyout.Favorites.PromoteAvailable(rec.buttons, "Profession")
        check(promoted[1] == rec.buttons[18], "old-rank favorite still promotes the profession")
        check(env.FluxFlyoutFavorites_Data["Tester-Realm"].Profession.nomod == id(18, 1), "favorite saved ID unchanged")
        local kid = { _fluxFlyoutDef = rec.buttons[18], CreateTexture = function()
            return { SetAtlas = function() end, SetPoint = function() end,
                Show = function(star) star.shown = true end, Hide = function(star) star.shown = false end }
        end }
        F.EBS.Flyout.Favorites.PaintKidStar(kid, "Profession")
        check(kid.FluxFlyoutFavStar_Custom.shown, "favorite star retained after rank change")
    end
    check(layouts == 8 and utilityRefreshes == 8, "one affected flyout and utility refresh per burst")
    check(A.ResolveProfessionSpell(103) == 103, "profession name prefix is not a profession")
    book[1] = id(1, 2); s.combat = true
    s.events.SKILL_LINES_CHANGED("SKILL_LINES_CHANGED"); s:advance(0.25)
    check(buttons[1].SpellId == id(1, 9), "combat keeps prepared action")
    check(deferred["ebs.professions"] ~= nil, "combat work deferred")
    -- Slot reused before combat ends: the delayed update must inspect live state.
    buttons[2].ActionType, buttons[2].ActionValue, buttons[2].SpellId = "item", 42, nil
    s.combat = false; for _, fn in pairs(deferred) do fn() end; deferred = {}
    check(buttons[1].SpellId == id(1, 2), "current learned rank used after combat")
    check(buttons[2].ActionType == "item", "reused slot remains an item")
    -- Unlearned/future entries must never become executable profession ranks.
    book[1], s.future = id(1, 9), 1
    A.InvalidateProfessionSpells()
    check(A.ResolveProfessionSpell(id(1, 2)) == id(1, 2), "future rank excluded")
    s.future = nil
    if modern then
        s.passive = 1; A.InvalidateProfessionSpells()
        check(A.ResolveProfessionSpell(id(1, 2)) == id(1, 9), "passive gathering profession ranks included")
        s.passive = nil
        for _, key in ipairs({ "offspec", "lowrank" }) do
            s[key] = 1; A.InvalidateProfessionSpells()
            check(A.ResolveProfessionSpell(id(1, 2)) == id(1, 2), key .. " excluded")
            s[key] = nil
        end
    end
    A.InvalidateProfessionSpells(); local start = queries
    for _ = 1, 100 do A.ResolveProfessionSpell(id(1, 1)) end
    check(queries - start <= #book + 2, "warm resolution does not rescan")
    check(A.IsProfessionSpellData(2259), "cold name anchor schedules recovery")
    check(not A.IsProfessionSpellData(101), "unrelated spell data ignored")
    local seed = metadata[2259]; metadata[2259] = nil
    A.InvalidateProfessionSpells()
    check(A.ResolveProfessionSpell(id(1, 2)) == id(1, 2), "cold anchor preserves assignment")
    metadata[2259] = seed
    s.events.SPELL_DATA_LOAD_RESULT("SPELL_DATA_LOAD_RESULT", 2259, true); s:advance(0.25)
    check(buttons[1].SpellId == id(1, 9), "data completion repairs cold profession detection")
    local queued = #s.timers
    s.events.SPELL_DATA_LOAD_RESULT("SPELL_DATA_LOAD_RESULT", 101, true)
    check(#s.timers == queued, "unrelated spell completion adds no refresh")
    if modern then
        -- A localized/new profession supplied by the client needs no seed ID.
        metadata[201], metadata[208] = { name = "Savoir" }, { name = "Savoir" }
        book[21] = 208
        env.GetProfessions = function() return nil, nil, nil, nil, nil, 9 end
        env.GetProfessionInfo = function() return "Savoir", nil, 1, 75, 1, 20, 999 end
        A.InvalidateProfessionSpells()
        check(A.ResolveProfessionSpell(201) == 208, "sparse sixth profession and localized client name")
    end
end
print("Extra profession ranks: " .. checks .. " checks; 18 action families / 9 ranks / five client models PASS")
