-- Preserve an owned grid face across craft-time item-data gaps. Native APIs mocked.
local function read(path)
    local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
local fixture = read("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")
local stop = assert(fixture:find("-- PLAYER_LOGIN bag priming", 1, true))
local fixtureEnv = setmetatable({ arg = { [0] = "ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua" } }, { __index = _G })
if arg[1] or arg[2] or arg[3] then
    fixtureEnv.io = { open = function(path, ...)
        local normalized = path:gsub("\\", "/")
        local class, score = "Inventory/FluxConsumableClassify.lua", "Inventory/FluxConsumableBest/Score.lua"
        if arg[1] and normalized:sub(-#class) == class then path = arg[1] end
        if arg[2] and normalized:sub(-#score) == score then path = arg[2] end
        local bind = "ExtraButtonSystem/Engine/ConsumableBind.lua"
        if arg[3] and normalized:sub(-#bind) == bind then path = arg[3] end
        return io.open(path, ...)
    end }
end
local boot, items = assert(load(fixture:sub(1, stop - 1) .. "return boot, items", "@craft-identity-fixture", "t", fixtureEnv))()
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function provider(s)
    local char, callbacks = { bags = {} }, {}
    s.env.Syndicator = {
        Constants = { AllBagIndexes = { 0, 1 }, AllBankIndexes = {} },
        API = { IsReady = function() return true end, GetCurrentCharacter = function() return "Fixture-Realm" end,
            GetCharacter = function() return char end },
        CallbackRegistry = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end },
    }
    s.load("Inventory/Syndicator/Adapter.lua")
    s.inv.Syndicator.RebuildAll = function() s.inv.Syndicator.RebuildBags() end
    s.inv.Syndicator.Start()
    function s:publish()
        for i, bag in ipairs({ 0, 1 }) do
            char.bags[i] = {}
            for slot, rec in pairs(self.slots[bag]) do
                char.bags[i][slot] = { itemID = rec.itemID, itemCount = rec.stackCount, itemLink = rec.hyperlink }
            end
        end
        callbacks.BagCacheUpdate(nil, "Fixture-Realm", { bags = { [0] = true, [1] = true } })
        self:advance(0.5)
    end
end
local specs = {
    { kind = "healPotion", id = 118, name = "Minor Healing Potion", text = "Use: Restores 80 health.", subclass = 1,
        module = "FluxCombatHealPotion", path = "HealPotion.lua" },
    { kind = "manaPotion", id = 2455, name = "Minor Mana Potion", text = "Use: Restores 120 mana.", subclass = 1,
        module = "FluxCombatManaPotion", path = "ManaPotion.lua" },
    { kind = "bandage", id = 1251, name = "Linen Bandage", text = "Use: Heals 66 damage over 6 sec.", subclass = 7,
        module = "FluxCombatBandage", path = "Bandage.lua" },
}
for _, family in ipairs({ "forever", "retail", "era", "anniversary", "mists" }) do
    for _, sourceName in ipairs({ "builtin", "syndicator" }) do
        for _, spec in ipairs(specs) do
            local s = boot(family, family == "era" or family == "anniversary")
            local create = s.env.CreateFrame
            local function completeFrame(frame)
                function frame:UnregisterEvent(event) self.events[event] = nil end
                function frame:SetOwner() end
                function frame:ClearLines() end
                function frame:SetHyperlink() end
                function frame:SetBagItem() end
                function frame:NumLines() return 1 end
                return frame
            end
            for _, frame in ipairs(s.frames) do completeFrame(frame) end
            s.env.CreateFrame = function(...) return completeFrame(create(...)) end
            if sourceName == "syndicator" then provider(s) end
            local ready = true
            local other = spec.kind == "bandage" and specs[1] or specs[3]
            local function info(id)
                if id == spec.id then return spec.name, "item:" .. id, 1, 1, 1, "Consumable", "Other", 20, "", 1, 0, 0, spec.subclass end
                if id == other.id then return other.name, "item:" .. id, 1, 1, 1, "Consumable", "Other", 20, "", 1, 0, 0, other.subclass end
                if id == 70001 then return "Material", "item:70001", 1, 1, 1, "Trade Goods", "Other", 200, "", 1, 0, 7, 0 end
            end
            s.env.C_Item.GetItemInfo, s.env.GetItemInfo = info, info
            s.env.C_Item.GetItemInfoInstant = function(id)
                return id, "Consumable", "Other", "", 1, id == 70001 and 7 or 0, id == other.id and other.subclass or spec.subclass
            end
            s.env.C_Item.RequestLoadItemDataByID = function() end
            local count = s.env.C_Item.GetItemCount or s.env.GetItemCount
            local function nativeCount(id, bank, uses, ...) return count(id, bank, false, ...) end
            if s.env.C_Item.GetItemCount then s.env.C_Item.GetItemCount = nativeCount else s.env.GetItemCount = nativeCount end
            local function tooltip(id)
                local data = id == other.id and other or spec
                if ready or data == other then return { lines = { { leftText = data.name }, { leftText = data.text } } } end
            end
            s.env.C_TooltipInfo = {
                GetBagItem = function(bag, slot) local rec = s.slots[bag][slot]; return tooltip(rec and rec.itemID) end,
                GetHyperlink = function(link) return tooltip(tonumber(link:match("item:(%d+)"))) end,
            }
            s.env.FluxConsumableClassify = nil
            s.load("Inventory/FluxConsumableClassify.lua")
            s.load("Inventory/FluxItemClass.lua")
            local classify, itemClass = s.env.FluxConsumableClassify, s.env.FluxItemClass
            local skill = spec.kind == "bandage" and (family == "retail" and 197 or 129)
                or (family == "forever" and spec.kind == "healPotion" and 129 or 171)
            s.inv.Professions = { ListAllCachedRecipes = function() return {
                { recipeID = 9001, outputItemID = spec.id, skillLineID = skill, reagents = { { itemID = 70001, count = 2 } } },
            } end, HasProfessionName = function() return true end }
            s:set(0, 1, spec.id, 3); s:set(0, 2, 70001, 20)
            if s.publish then s:publish() else s:bags() end
            s:advance(10)
            s.load("ExtraButtonSystem/Shared/FluxExtraButtonVisibility.lua")
            local visibility, mode = s.env.FluxExtraButtonVisibility, "auto"
            visibility.GetRawMode = function() return mode end
            visibility.GetBindingForce = function() return false end
            local btn, module = s:button(spec.kind, true, "ExtraButtonSystem/CombatGrid/Buttons/" .. spec.path)
            s.env[spec.module] = module
            local transitions = 0
            btn.SlotFrame = { shown = true, IsShown = function(self) return self.shown end,
                Show = function(self)
                    assert(not s.combat, "protected show in combat")
                    if not self.shown then transitions = transitions + 1 end
                    self.shown = true
                end,
                Hide = function(self)
                    assert(not s.combat, "protected hide in combat")
                    if self.shown then transitions = transitions + 1 end
                    self.shown = false
                end }
            local function shown() return btn.SlotFrame:IsShown() end
            s:advance(1)
            local label = family .. " " .. sourceName .. " " .. spec.kind
            check(btn.ItemId == spec.id and shown(), label .. " starts owned and visible")
            local placeholders, original = 0, btn.SetPlaceholder
            btn.SetPlaceholder = function(self, ...)
                placeholders = placeholders + 1
                return original(self, ...)
            end
            local binds, frames = s.writes, #s.frames
            -- A metadata completion invalidates classification before a profession
            -- refresh. The native bag copies remain positive throughout crafting.
            ready = false
            itemClass.OnItemDataLoaded(spec.id)
            s.inv.Notify({ professions = true })
            s:advance(0.1)
            check(placeholders == 0 and btn.ItemId == spec.id and not btn.PlaceholderTexture,
                label .. " no transient placeholder while tooltip is unavailable")
            local unresolved = classify.Classify(spec.id)
            check(unresolved == nil and (not classify.IsRejected or not classify.IsRejected(spec.id)), label .. " missing tooltip remains unresolved")
            check(not s.best.Score.IsBlockedForBest(spec.id, spec.kind), label .. " unresolved metadata does not reject owned item")
            s:set(0, 1, spec.id, 4); s:set(0, 2, 70001, 18)
            if s.publish then s:publish() else s:bags() end
            check(placeholders == 0 and btn.ItemId == spec.id, label .. " crafted same item retains identity")
            local gapScans = s.scans
            s:advance(30)
            local drainedScans, drainedTimers = s.scans, #s.timers
            s:advance(30)
            local quietExtraScans = s.scans - drainedScans
            check(s.scans <= gapScans + 4 and s.scans == drainedScans and #s.timers == drainedTimers,
                label .. " prolonged metadata gap uses bounded followups")
            check(placeholders == 0 and btn.ItemId == spec.id, label .. " prolonged metadata gap retains confirmed ownership")
            -- Last-material craft: selection metadata is still unavailable but
            -- four carried outputs are real. Auto must not hide before latch recovery.
            s:set(0, 2, 70001, 0)
            s:set(0, 3, other.id, 1) -- Loot of a different kind legitimately refreshes Best.
            if s.publish then s:publish() else s:bags() end
            s.inv.Notify({ professions = true }); s:advance(0.5)
            check(shown() and transitions == 0 and placeholders == 0 and btn.ItemId == spec.id,
                label .. " spent last material keeps positive owned slot shown throughout")
            ready = true
            itemClass.OnItemDataEvent(spec.id, true)
            s:advance(1)
            check(btn.ItemId == spec.id and btn.WCount.value == "4" and shown(), label .. " metadata settles to crafted count")
            check(placeholders == 0, label .. " entire craft transition never clears action to placeholder")
            check(s.writes == binds, label .. " same-item craft adds no main action rebind")
            check(#s.frames <= frames + 1, label .. " no unbounded frame creation") -- First fallback tooltip is lazy.
            local settledScans = s.scans
            for n = 5, 9 do
                s:set(0, 1, spec.id, n); s:set(0, 2, 70001, 26 - n * 2)
                if s.publish then s:publish() else s:bags() end
                s.inv.Notify({ professions = true }); s:advance(0.2)
            end
            check(placeholders == 0 and s.writes == binds and s.scans == settledScans,
                label .. " ordinary repeated crafting adds no placeholders/rebinds/selector scans")
            check(transitions == 0, label .. " owned loot/craft never hides or shows slot again")
            local craftPlaceholders, craftBinds = placeholders, s.writes - binds
            local craftTransitions, craftScans = transitions, s.scans
            local craftFrameDelta = #s.frames - frames
            local combatWrites = s.writes
            s.combat = true
            s:set(0, 1, spec.id, 10)
            if s.publish then s:publish() else s:bags() end
            s.inv.Notify({ professions = true }); s:advance(0.5)
            check(shown() and transitions == 0 and s.writes == combatWrites,
                label .. " positive loot in combat leaves protected action and visibility intact")
            s.combat = false; s:event("PLAYER_REGEN_ENABLED"); s:advance(0.5)
            check(shown() and btn.ItemId == spec.id and btn.WCount.value == "10", label .. " combat exit retains owned face")
            mode = "off"; module.Update(false)
            check(not shown(), label .. " explicit Off still hides a positive owned stack")
            mode = "auto"; module.Update(false)
            check(shown(), label .. " Auto restores a positive owned stack after explicit Off")
            transitions = 0 -- Exclude those requested mode changes from the zero-count check.
            s.inv.snapshots.bank.counts[spec.id], s.inv.snapshots.warband.counts[spec.id] = 80, 90
            s:set(0, 1, spec.id, 0); s:set(0, 2, 70001, 0)
            if s.publish then s:publish() else s:bags() end
            s:advance(0.6)
            check(not shown() and transitions == 1, label .. " true bag zero without materials hides Auto once")
            mode = "always"; module.Update(false)
            check(shown() and btn.PlaceholderTexture and not btn.ActionType, label .. " explicit Always retains empty placeholder")
            if spec.kind ~= "bandage" then
                classify.InvalidateCache(spec.id)
                for _ = 1, 6 do
                    classify.ResetParseBudget()
                    classify.Classify(spec.id, "item:" .. spec.id,
                        "Use: Absorbs 1000 fire damage and increases your maximum health by 100 for a limited time.", spec.name)
                end
                check((not classify.IsRejected or classify.IsRejected(spec.id)) and s.best.Score.IsBlockedForBest(spec.id, spec.kind),
                    label .. " actual negative utility-potion classification remains rejected")
            end
            print(("SAMPLE %s %s %s craftPlaceholders=%d craftBinds=%d craftVisibilityChanges=%d craftScans=%d quietSecond30Scans=%d craftFrameDelta=%d"):format(
                family, sourceName, spec.kind, craftPlaceholders, craftBinds, craftTransitions, craftScans,
                quietExtraScans, craftFrameDelta))
        end
    end
end
print(("Consumable craft identity: %d checks, %d failures; native acceptance pending"):format(checks, failures))
assert(failures == 0, "consumable craft identity regression")
