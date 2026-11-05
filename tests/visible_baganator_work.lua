-- Real ItemViews, Protection and GearSetShield modules; native frames/timers mocked.
-- Optional argument: baseline FluxBaganator_ItemViews.lua path. Client/provider
-- labels exercise this shared path; they do not emulate or certify native clients.
local source = arg[1] or "BaganatorCompat/FluxBaganator_ItemViews.lua"
local checks, failures = 0, 0
local totals = {guards = 0, shields = 0, itemReads = 0}
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function region(parent, shown)
    local r = {parent = parent, shown = shown, hooks = {}}
    function r:IsShown() return self.shown end
    function r:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function r:HookScript(event, fn)
        self.hooks[event] = self.hooks[event] or {}
        table.insert(self.hooks[event], fn)
    end
    function r:Show()
        if self.shown then return end
        self.shown = true
        for _, fn in ipairs(self.hooks.OnShow or {}) do fn(self) end
    end
    function r:Hide() self.shown = false end
    return r
end

for _, client in ipairs({"retail", "forever", "era", "anniversary", "mists"}) do
 for _, provider in ipairs({"baganator", "baganator+syndicator"}) do
    local label = client .. "/" .. provider
    local e = setmetatable({}, {__index = _G}); e._G = e
    e.FluxInventoryProvider = provider
    local s = {guards = 0, shields = 0, itemReads = 0, context = true,
        scheduled = {}, timers = 0, afters = 0, frames = {}, listeners = {}, entries = {}}
    local registry = {callbacks = {}}
    function registry:RegisterCallback(event, fn)
        self.callbacks[event] = self.callbacks[event] or {}
        table.insert(self.callbacks[event], fn)
    end
    function registry:TriggerEvent(event)
        for _, fn in ipairs(self.callbacks[event] or {}) do fn(self) end
    end
    e.Baganator = {CallbackRegistry = registry, API = {Skins = {
        GetAllFrames = function() return s.entries end,
        RegisterListener = function(fn) table.insert(s.listeners, fn) end,
    }}}
    e.C_Timer = {
        NewTimer = function(delay, fn)
            s.timers = s.timers + 1
            local timer = {delay = delay, fn = fn}
            function timer:Cancel() self.cancelled = true end
            table.insert(s.scheduled, timer)
            return timer
        end,
        After = function(delay, fn)
            s.afters = s.afters + 1
            table.insert(s.scheduled, {delay = delay, fn = fn})
        end,
    }
    local function flush()
        local pending = s.scheduled; s.scheduled = {}
        for _, timer in ipairs(pending) do if not timer.cancelled then timer.fn() end end
    end
    e.CreateFrame = function()
        local frame = {scripts = {}}
        function frame:RegisterEvent() end
        function frame:SetScript(event, fn) self.scripts[event] = fn end
        table.insert(s.frames, frame)
        return frame
    end
    e.C_Item = {IsEquippableItem = function()
        s.itemReads = s.itemReads + 1
        return true
    end}
    e.FluxRespec = {On = function() end, GearSetLock = {
        WithContextSnapshot = function(fn) return fn() end,
        UpdateItemButtonClickGuard = function(button, _, slotID)
            s.guards = s.guards + 1
            button.guard = s.context
            button.guardWrites = button.guardWrites + 1
            button.guardSlot = slotID
        end,
        ShouldShowShieldVisual = function() return true end,
        IsMerchantSellContext = function() return s.context end,
        IsDisenchantContext = function() return false end,
    }}
    local backpack, bank = region(nil, true), region(nil, false)
    local cached, oldSkin = region(backpack, false), region(nil, false)
    e.Baganator_SingleViewBackpackViewFrameblizzard = backpack
    -- These are the actual names created by Baganator's ViewManagement.
    e.Baganator_CategoryViewBankViewFrameblizzard = bank
    table.insert(s.entries, {regionType = "ButtonFrame", region = backpack, tags = {"backpack"}})
    table.insert(s.entries, {regionType = "ButtonFrame", region = bank, tags = {"bank"}})
    local rows, hidden = {}, {}
    local function item(parent, slot)
        local button = region(parent, true)
        button.guardWrites = 0
        button.BGR = {itemID = 100, guid = "G" .. slot, bagID = 0, slotID = slot,
            itemLocation = {bagID = 0, slotIndex = slot}}
        local shield = {}
        function shield:SetShown(shown) s.shields = s.shields + 1; self.shown = shown end
        button.cornerPlugins = {flux_gear_set_shield = shield}
        table.insert(s.entries, {regionType = "ItemButton", region = button})
        table.insert(rows, button)
        return button
    end
    local first, second = item(backpack, 1), item(backpack, 2)
    for i = 1, 1000 do
        local parent = i <= 400 and bank or (i <= 800 and cached or oldSkin)
        hidden[i] = item(parent, i + 2)
    end
    local ownHidden = item(backpack, 1003); ownHidden:Hide()
    table.insert(s.entries, {regionType = "ItemButton", region = first})
    table.insert(s.entries, {regionType = "CornerWidget", region = region(nil, true)})
    -- The same button can be found in active layouts, live/cached layouts and
    -- registered skins. Hidden cached children must be skipped in every path.
    backpack.activeLayouts = {{buttons = {first, second, {isDummy = true}}}}
    backpack.LiveLayouts = {{buttons = {first}}}
    backpack.Container = {BagLive = {buttonsByBag = {[0] = {first, second}}},
        BagCached = {buttonsByBag = {[0] = {hidden[401]}}}}
    assert(loadfile(source, "t", e))()
    local compat = e.FluxBaganatorCompat
    compat.InstallBaganatorItemContextOverride = function() end
    assert(loadfile("BaganatorCompat/FluxBaganator_Protection.lua", "t", e))()
    assert(loadfile("BaganatorCompat/FluxBaganator_GearSetShield.lua", "t", e))()
    compat.InitProtection()
    check(#s.listeners >= 1 and hidden[1]._fluxBagButtonProtectionInstalled,
        label .. " durable listeners still install for hidden pools")
    local installed = 0
    compat.ForEachBaganatorItemButton(function() installed = installed + 1 end)
    check(installed == #rows, "all-button traversal retains hidden rows and deduplicates")
    local visible = 0
    compat.ForEachVisibleItemButton(function() visible = visible + 1 end)
    check(visible == 2, label .. " shown children of hidden parents are excluded")
    check(hidden[1]:IsShown() and not hidden[1]:IsVisible(), "fixture models native ancestor visibility")
    for _, button in ipairs(rows) do button.guardWrites = 0 end
    s.guards, s.shields, s.itemReads = 0, 0, 0
    for i = 1, 40 do compat.RefreshBaganatorGearSetProtection() end
    check(s.guards == 80 and s.shields == 80 and s.itemReads == 80,
        label .. " repeated protection work scales with two visible rows")
    check(hidden[1].guardWrites == 0 and hidden[401].guardWrites == 0 and hidden[801].guardWrites == 0,
        "bank, cached and previous-skin pools remain dormant")
    check(first.guard and first.cornerPlugins.flux_gear_set_shield.shown,
        "visible guards and shields remain enabled in vendor context")
    for key in pairs(totals) do totals[key] = totals[key] + s[key] end

    s.shields = 0
    compat.RefreshVisibleGearSetShields()
    check(s.shields == 2, "standalone shield painter also excludes hidden ancestor pools")
    s.context = false
    s.frames[1].scripts.OnEvent(nil, "MERCHANT_CLOSED")
    check(s.scheduled[#s.scheduled].delay == .2, "existing merchant debounce retained")
    flush()
    check(not first.guard and not first.cornerPlugins.flux_gear_set_shield.shown,
        "visible merchant close clears current guards and shields")
    local timers = s.timers
    bank:Show() -- Direct root reveal; native toggle does not emit BagShow.
    -- Native ToggleBackpackView shows the root before UpdateForCharacter can
    -- change row identities. The reveal callback must observe the final slot.
    hidden[1].BGR.itemLocation.slotIndex = 2001
    hidden[1].BGR.slotID = 2001
    flush()
    check(not hidden[1].guard and not hidden[1].cornerPlugins.flux_gear_set_shield.shown,
        label .. " direct bank-root reveal repaints on the next timer turn")
    check(hidden[1].guardSlot == 2001, "reveal refresh observes slot reassignment after OnShow")
    check(s.timers == timers, "direct reveal adds no debounce timer")
    check(#(bank.hooks.OnShow or {}) == 1, "tagged blizzard skin bank is discovered and hooked once")
    bank:Hide()

    -- CharacterSelect callbacks may precede Baganator's layout swap. A single
    -- zero-delay barrier must observe the final live/cached child visibility.
    s.context = true
    registry:TriggerEvent("BagShow"); flush()
    cached.shown = true
    registry:TriggerEvent("BankViewChanged")
    flush()
    check(hidden[401].guard and hidden[401].cornerPlugins.flux_gear_set_shield.shown,
        "bank child/tab reveal refreshes after the final layout")
    cached:Hide()
    s.context = false
    registry:TriggerEvent("BagShow"); flush()
    local afters = s.afters
    for i = 1, 20 do registry:TriggerEvent("CharacterSelect") end
    check(s.afters == afters + 1 and #s.scheduled == 1 and s.scheduled[1].delay == 0,
        "character-select burst coalesces one layout barrier")
    cached.shown = true -- Native handler swaps children later in that dispatch.
    flush()
    check(not hidden[401].guard and not hidden[401].cornerPlugins.flux_gear_set_shield.shown,
        "same-root character change paints newly visible cached/live rows")
    registry:TriggerEvent("CharacterSelect"); flush()
    check(s.afters == afters + 2, "layout barrier rearms after completing")
    cached:Hide()

    local replacement = region(nil, false)
    e.Baganator_CategoryViewBackpackViewFramedark = replacement
    local replacementDetails = {regionType = "ButtonFrame", region = replacement, tags = {"backpack"}}
    table.insert(s.entries, replacementDetails)
    for _, listener in ipairs(s.listeners) do listener(replacementDetails) end
    local replacementItem = item(replacement, 1004)
    s.listeners[1]({regionType = "ItemButton", region = replacementItem})
    replacementItem.guard = true
    registry:TriggerEvent("BackpackFrameChanged")
    replacement:Show()
    replacementItem.BGR.itemLocation.slotIndex = 2002
    replacementItem.BGR.slotID = 2002
    flush()
    check(not replacementItem.guard, "replacement hidden view is tracked before direct reveal")
    check(replacementItem.guardSlot == 2002, "replacement-view refresh reads final slot identity")
    registry:TriggerEvent("BackpackFrameChanged")
    check(#(replacement.hooks.OnShow or {}) == 1, "repeated discovery does not multiply hooks")
    local numeric = region(nil, false)
    e.Baganator_SingleViewBackpackViewFrame1 = numeric
    registry:TriggerEvent("BackpackFrameChanged")
    check(#(numeric.hooks.OnShow or {}) == 1, "legacy numeric frame-name fallback stays supported")
    check(not registry.callbacks.ViewComplete, "item-update ViewComplete has no refresh listener")

    -- Legacy adapters without IsVisible retain their prior IsShown contract.
    local legacy = item(backpack, 1005); legacy.IsVisible = false
    local legacySeen = false
    compat.ForEachVisibleItemButton(function(button) if button == legacy then legacySeen = true end end)
    check(legacySeen, "IsShown fallback retained when IsVisible is unavailable")
    legacy:Hide(); legacySeen = false
    compat.ForEachVisibleItemButton(function(button) if button == legacy then legacySeen = true end end)
    check(not legacySeen, "legacy hidden buttons remain excluded")
 end
 for _, provider in ipairs({"builtin", "syndicator"}) do
    local e = setmetatable({}, {__index = _G}); e._G = e
    e.FluxInventoryProvider = provider
    assert(loadfile(source, "t", e))()
    e.FluxBaganatorCompat.InitBaganatorViewTracking()
    local visits = 0
    e.FluxBaganatorCompat.ForEachVisibleItemButton(function() visits = visits + 1 end)
    check(visits == 0, client .. "/" .. provider .. " absent Baganator stays inert")
 end
end
print(string.format("visible Baganator work: %d checks, %d failures; burst guards=%d shields=%d itemReads=%d",
    checks, failures, totals.guards, totals.shields, totals.itemReads))
if failures > 0 then os.exit(1) end
