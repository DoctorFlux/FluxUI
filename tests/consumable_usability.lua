-- Loaded consumable manager + shared EBS paint/translation; native APIs and frames are models.
local sourceRoot = arg[1]
local function read(path)
    local f = sourceRoot and io.open(sourceRoot .. "/" .. path, "rb")
    f = f or assert(io.open(path, "rb")); local body = f:read("*a"); f:close(); return body
end
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
for _, family in ipairs({ "retail", "forever", "era", "anniversary", "mists" }) do
    local s = { usable = true, effect = false, count = 2, reliable = true, spellQueries = 0, combat = false }
    local noop = function() end
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.FluxButton, env.SlashCmdList = {}, {}
    env.GetTime = function() return 100 end
    env.InCombatLockdown = function() return s.combat end
    env.UnitExists = function() return true end
    env.C_Timer = { After = noop }
    env.CreateFrame = function() return { RegisterEvent = noop, RegisterUnitEvent = noop, SetScript = noop } end
    env.SecureCmdOptionParse = function(text) return text:gsub("%b[]", ""):match("^%s*(.-)%s*$"), "target" end
    env.C_Spell = { GetSpellInfo = function(token)
        return { name = "Parsed target spell", spellID = type(token) == "number" and token or 900 }
    end }
    local flux = { Client = { isForever = family == "forever" }, EBS = { buttons = {}, badges = {} },
        Inventory = { IsReliable = function() return s.reliable end,
            GetCount = function() return s.count end, GetLiveCount = function() return s.count end },
        Item = { IsUsable = function() return s.usable, s.mana end,
            GetSpell = function(id) return "Item effect", id + 100 end,
            GetCount = function() return s.count end, IsConsumable = function() return true end,
            UsesConsumableCharges = function() return false end, GetIcon = function(id) return 1000 + id end,
            GetCooldown = function() return 90, 60, true end },
        Spell = { IsUsable = function() s.spellQueries = s.spellQueries + 1; return s.effect, false end,
            GetCharges = function(id) if id == 900 then return 0, 3 end end,
            GetTexture = function(id) return 2000 + id end,
            GetCooldown = function() return 10, 600, true end },
        Range = { ResolveUnit = function() return "target" end,
            CheckSpell = function() return s.spellRange end, CheckItem = function() return s.itemRange end },
        ButtonFX = { Charges = { Apply = function(_, data) s.cooldown = data end, ClearCache = noop } } }
    env.Flux = flux
    local ns = { Flux = flux }
    for _, path in ipairs({ "ExtraButtonSystem/Engine/Paint.lua", "ExtraButtonSystem/Engine/Action.lua",
        "ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua" }) do
        assert(load(read(path), "@" .. path, "t", env))("_FluxUI", ns)
    end
    local paint, action, cons = flux.EBS.Paint, flux.EBS.Action, env.FluxNCConsumables
    local function button(consumable)
        local icon = { SetDesaturated = noop, SetTexture = noop, Show = noop, Hide = noop, SetTexCoord = noop }
        function icon:SetVertexColor(r, g, b) self.r, self.g, self.b = r, g, b end
        return { ActionType = "item", ActionValue = 501, ItemId = 501, ConsumablesItemID = consumable and 501 or nil,
            IsConsumableButton = consumable, WIcon = icon, Widget = {}, categoryScope = "account",
            WCooldown = { ClearAllPoints = noop, SetPoint = noop }, WNormalTexture = { SetVertexColor = noop } }
    end
    local btn, ordinary = button(true), button(false)
    cons.RefreshConsumablesUsability(btn); paint.UpdateUsable(ordinary)
    check(btn.WIcon.r == 1 and ordinary.WIcon.r == 1,
        family .. " native usable item stays bright even when its effect spell is not independently usable")
    s.spellQueries = 0; paint.UpdateUsable(btn)
    check(s.spellQueries == 0, "ready item usability does not query a non-action effect spell")
    s.usable = nil; cons.RefreshConsumablesUsability(btn)
    check(btn.WIcon.r == 1, "temporarily unknown item state does not inherit an unusable effect-spell result")
    s.usable, s.effect = false, true
    cons.RefreshConsumablesUsability(btn)
    check(btn.WIcon.r == 0.4, "reliable native item restriction still darkens consumable")
    s.mana = true; cons.RefreshConsumablesUsability(btn); paint.UpdateUsable(ordinary)
    check(btn.WIcon.r == ordinary.WIcon.r and btn.WIcon.b == ordinary.WIcon.b,
        "consumable retains shared missing-mana color")
    -- The next face must not inherit a confirmed false/mana state while its
    -- metadata is unknown. No secure action changes are needed for the repaint.
    s.usable, s.effect, s.mana = nil, false, nil
    btn.ConsumablesItemID = 502; s.combat = true
    cons.RefreshConsumablesUsability(btn)
    check(btn.WIcon.r == 1 and btn.WIcon.g == 1, "new item does not inherit previous item dark/mana cache in combat")
    s.usable, s.effect = true, false
    s.itemRange, s.spellRange = nil, false
    cons.RefreshConsumablesUsability(btn)
    check(not btn._outOfRange and btn.WIcon.r == 1,
        "self-use item is not dimmed by effect-spell range against an unrelated target")
    s.itemRange, s.spellRange = false, true
    cons.RefreshConsumablesUsability(btn)
    check(btn._outOfRange and btn.WIcon.g < btn.WIcon.r, "actual item out-of-range retains shared range tint")
    s.itemRange = true; cons.RefreshConsumablesUsability(btn)
    check(not btn._outOfRange and btn.WIcon.r == 1 and btn.WIcon.g == 1, "native item range recovery restores brightness")
    s.count = 0; cons.RefreshConsumablesUsability(btn)
    check(btn.WIcon.r == 0.4, "genuinely empty consumable remains dark")
    s.count = 2
    -- Weapon-target macros may parse to a spell/weapon instead of their bag
    -- item. The manager's saved item face must survive both macro cache lanes.
    btn.ActionType, btn.ActionValue = "macrotext", "/use [btn:1] 0 1\n/use [btn:1] 16"
    btn.MacroBody, btn.MacroMode, btn.SpellId = btn.ActionValue, "spell", 900
    cons.RefreshConsumablesUsability(btn)
    check(btn.SpellId == nil and btn.MacroMode == "item" and btn.ItemId == 502 and btn.WIcon.r == 1,
        "consumable refresh clears unrelated parsed spell/charge identity")
    action.TranslateMacro(btn)
    check(btn.SpellId == nil and btn.MacroMode == "item" and btn.ItemId == 502 and btn.WIcon.r == 1,
        "changed macro evaluation preserves managed item face and shared tint")
    btn.MacroMode, btn.SpellId, btn.ItemId = "spell", 900, nil
    action.TranslateMacro(btn); paint.UpdateUsable(btn)
    check(btn.SpellId == nil and btn.MacroMode == "item" and btn.ItemId == 502 and btn.WIcon.r == 1,
        "cached macro evaluation also restores item identity")
    -- Aura countdowns stay separate from usability tint and remain supported.
    btn.FluxConsumableAuraCooldown = true
    btn.StanceBuffCooldownStart, btn.StanceBuffCooldownDuration, btn.StanceBuffExpirationTime = 100, 300, 400
    cons.RefreshConsumablesUsability(btn)
    check(s.cooldown.expirationTime == 400 and s.cooldown.duration == 300 and btn.WIcon.r == 1,
        "buff countdown does not become an unusable-item tint")
    btn.FluxConsumableAuraCooldown = nil
    btn.PlaceholderTexture, btn.IsWispLockPlaceholder = "wisp", true
    local prior = btn.WIcon.r; s.usable = false
    cons.RefreshConsumablesUsability(btn)
    check(btn.WIcon.r == prior, "wisp lock keeps its separate visual policy")
end
print(("Consumable usability: %d checks, %d failures"):format(checks, failures))
os.exit(failures > 0 and 1 or 0)
