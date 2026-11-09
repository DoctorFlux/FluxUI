-- Exercises production cursor, secure-attribute, persistence and flyout paths.
-- Native protected execution and actual dragging still require WoW testing.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local function slice(s, first, last)
    local a = assert(s:find(first, 1, true), first)
    return s:sub(a, assert(s:find(last, a + #first, true), last) - 1)
end
local apiSource = slice(read("Core/FluxAPI/UI.lua"), "function ns.API.HasPlayerTransmogOutfitAPI()", "-- Details! identity helpers")
local flyoutSource = slice(read("UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua"), "local function OutfitKidOnEnter", "local function EnsureRowActiveBorder")
local actionSource = read("ExtraButtonSystem/Engine/Action.lua")
local assignSource = read("ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua")
local managerSource = slice(read("ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua"), "local function ClearModMacroAttrs", "--- Midnight cast/charge")
local popupSource = slice(read("ExtraButtonSystem/FlyoutEngine/Popup.lua"), '\tkid:SetScript("OnDragStart",', '\tkid:SetScript("PostClick",')
local checks = 0
local function check(value, message) assert(value, message); checks = checks + 1 end
local function fixture(branch, supported, sources)
    sources = sources or {}
    local env = setmetatable({}, { __index = _G }); env._G = env
    local s = { combat = false, cursor = {}, frames = {}, deferred = {}, writes = 0, clearCursor = 0,
        active = 17, outfits = { { outfitID = 48, playerFacingOutfitIndex = 7, name = "Second", icon = 48 },
            { outfitID = 17, playerFacingOutfitIndex = 1, name = "First", icon = 17 } } }
    local ns = { API = {}, Flux = { EBS = { buttons = {}, Flyout = {} }, Client = { branch = branch } } }
    env.Flux, env.FluxButton = ns.Flux, {}
    env.InCombatLockdown = function() return s.combat end
    env.GetCursorInfo = function() return table.unpack(s.cursor) end
    env.ClearCursor = function() s.clearCursor = s.clearCursor + 1; s.cursor = {} end
    env.Constants = { TransmogOutfitDataConsts = {
        EQUIP_TRANSMOG_OUTFIT_MANUAL_SPELL_ID = 100, CLEAR_TRANSMOG_OUTFIT_MANUAL_SPELL_ID = 101 } }
    env.C_Spell = {
        GetSpellInfo = function(id) return { name = "Spell" .. id, iconID = id } end,
        PickupSpell = function(id)
            s.spellPickups = (s.spellPickups or 0) + 1
            -- Clear is a synthetic spell face. The native spellbook uses
            -- PickupOutfit(0), not PickupSpell(clearSpellID), to drag it.
            if id ~= 101 then s.cursor = { "spell", id } end
        end,
    }
    env.CreateFrame = function()
        local f = { events = {}, scripts = {} }; s.frames[#s.frames + 1] = f
        function f:RegisterEvent(event) self.events[event] = true end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        return f
    end
    ns.Flux.Safecall = function(fn, ...) return fn(...) end
    ns.Flux.Combat = { InLockdown = env.InCombatLockdown, Defer = function(key, fn) s.deferred[key] = fn end }
    if supported then
        env.C_TransmogOutfitInfo = {
            GetOutfitsInfo = function() if s.dataError then error("journal not ready") end; return s.outfits end,
            ChangeToOutfit = function() error("insecure outfit activation") end,
            ClearOutfit = function() error("insecure clear activation") end,
            IsTransmogEnabled = function() return not s.disabled end,
            GetActiveOutfitID = function() return s.active end,
            PickupOutfit = function(id)
                check(not s.combat, "native pickup never called under lockdown")
                if s.failPickup then return false end
                if id == 0 and s.clearPickupCursor then
                    s.cursor = s.clearPickupCursor
                else
                    s.cursor = { "outfit", id }
                end
            end,
        }
    end
    local function run(body, suffix, ...)
        return assert(load(body, "@production-" .. suffix, "t", env))(...)
    end
    run("local _, ns = ...\n" .. (sources.api or apiSource), "outfit-api", "_FluxUI", ns)
    run(sources.action or actionSource, "ebs-action", "_FluxUI", ns)
    run(assignSource, "utility-assign", "_FluxUI", ns)
    env.Manager, env.Assign = {}, function() return env.FluxNCUtilitySlots end
    s.applyAttributes = run(managerSource .. "\nreturn ApplyMacroAttributes", "utility-attributes")
    run(read("ExtraButtonSystem/FlyoutEngine/Def.lua"), "flyout-normalization", "_FluxUI", ns)
    ns.Flux.EBS.Flyout.InLockdown = env.InCombatLockdown
    s.build = run("local API, OUTFIT_EQUIP_SPELL_ID = ...\n" .. (sources.flyout or flyoutSource) .. "\nreturn BuildTransmogFlyoutButtons", "transmog-flyout", ns.API, 100)
    function s.button()
        local w = { attrs = {}, scripts = {} }
        function w:GetName() return nil end
        function w:SetAttribute(key, value)
            check(not s.combat, "no protected attribute writes in combat")
            s.writes = s.writes + 1; self.attrs[key] = value
        end
        function w:GetAttribute(key) return self.attrs[key] end
        function w:SetScript(event, fn) self.scripts[event] = fn end
        function w:RegisterForDrag(...) self.dragButtons = { ... } end
        function w:EnableMouse(enabled) self.mouseEnabled = enabled end
        local b = { Widget = w }
        b.OnReceiveDragCallback = function(t, id) b.saved = { type = t, id = id } end
        b.OnDelete = function() b.saved = nil end
        ns.Flux.EBS.buttons[#ns.Flux.EBS.buttons + 1] = b
        return b
    end
    function s.flush()
        local pending = s.deferred; s.deferred = {}
        for _, fn in pairs(pending) do fn() end
    end
    function s.dragFromFlyout(row)
        local kid = { _fluxFlyoutDef = row, SetScript = function(self, event, fn) self[event] = fn end }
        run("local kid, Flyout = ...\n" .. popupSource, "popup-drag-handler", kid, ns.Flux.EBS.Flyout)
        kid:OnDragStart()
    end
    return s, ns.API, ns.Flux.EBS.Action, env.FluxNCUtilitySlots, env, ns
end
local function exercise(branch, supported, sources)
    local s, api, action, assign, env, ns = fixture(branch, supported, sources)
    local rows = s.build()
    local ordinary = s.button(); action.SetAction(ordinary, "spell", 55)
    action.OnDragStart(ordinary)
    check(s.cursor[1] == "spell" and s.cursor[2] == 55 and ordinary.ActionType == nil,
        branch .. ": ordinary spell drag-off retains its original pickup path")
    s.cursor = { "spell", 55, "flyout", 999 }; action.OnReceiveDrag(ordinary)
    check(ordinary.ActionType == "spell" and ordinary.saved.type == "spell" and ordinary.saved.id == 55,
        branch .. ": normal flyout-subtype spell cursor retains inner spell identity")
    action.NoteFlyoutPopupSpell(66); s.cursor = { "spell", 77, "flyout", 999 }
    action.OnReceiveDrag(ordinary)
    check(ordinary.saved.type == "spell" and ordinary.saved.id == 66,
        branch .. ": actual popup spell stash still takes precedence")
    action.Clear(ordinary)
    env.ClearCursor()
    if not supported then
        check(not api.HasPlayerTransmogOutfitAPI() and #rows == 0, branch .. ": unsupported outfit API stays unavailable")
        local clears = s.clearCursor
        s.cursor = { "outfit", 0 }; local b = s.button(); action.OnReceiveDrag(b)
        check(b.ActionType == nil and s.clearCursor == clears, branch .. ": unsupported cursor is preserved")
        check(assign.ParseCursor() == nil and not api.TryPickupPlayerTransmogOutfit(0), "unsupported utility and pickup")
        check(api.GetPlayerTransmogOutfitIDForSpell(101) == nil, "matching ID on an unsupported client is not reclassified")
        return
    end
    check(api.HasPlayerTransmogOutfitAPI(), branch .. ": actual capabilities enable outfits")
    check(#rows == 3 and rows[1].isClear and rows[1].outfitID == 0, "clear is FIRST; every saved outfit retained")
    check(rows[1].macrotext == "/outfit" and rows[1].name == "Clear Current Transmogrifications", "clear secure macro and label")
    check(rows[2].outfitID == 17 and rows[3].outfitID == 48, "saved outfits preserve index order after clear")
    check(api.GetPlayerTransmogOutfitAction(48).macrotext == "/outfit !7", "sparse ID resolves player-facing index")
    check(api.GetPlayerTransmogOutfitAction(-1) == nil and api.GetPlayerTransmogOutfitAction(0.5) == nil, "invalid identities rejected")
    rows = ns.Flux.EBS.Flyout.Def.NormalizeList(rows)
    check(rows[1].isClear and rows[1].outfitID == 0 and rows[1].onDragStart, "normalization preserves clear drag definition")
    local a, b = s.button(), s.button()
    s.dragFromFlyout(rows[1]); check(s.cursor[1] == "outfit" and s.cursor[2] == 0, "clear flyout uses native outfit cursor ID zero")
    action.OnReceiveDrag(a)
    check(a.ActionType == "outfit" and a.ActionValue == 0 and a.saved.id == 0, "clear drop persists identity zero")
    check(a.Widget.attrs.type == "macro" and a.Widget.attrs.macrotext == "/outfit", "clear input is securely configured")
    action.OnDragStart(a)
    check(a.ActionType == nil and a.saved == nil and s.cursor[2] == 0, "drag clear off removes assignment after successful pickup")
    action.OnReceiveDrag(b)
    check(b.saved.id == 0 and b.Widget.attrs.macrotext == "/outfit", "clear moves between extra buttons")
    -- Restore persisted data without losing zero to false/nil coercion.
    action.SetAction(a, b.saved.type, b.saved.id)
    check(a.ActionValue == 0 and a.Widget.attrs.macrotext == "/outfit", "saved clear restores after reload")
    s.cursor = { "outfit", 48 }; action.OnReceiveDrag(b)
    check(b.saved.id == 48 and s.cursor[1] == "outfit" and s.cursor[2] == 0, "outfit swap returns previous clear onto cursor")
    check(b.Widget.attrs.macrotext == "/outfit !7", "normal outfit applies index, never sparse identity")
    s.cursor = { "outfit", 999 }; local clears = s.clearCursor
    action.OnReceiveDrag(b)
    check(b.saved.id == 48 and s.clearCursor == clears, "unknown outfit cannot destroy button or cursor")
    s.failPickup = true; s.cursor = { "item", 123 }; action.OnDragStart(a)
    check(a.ActionValue == 0 and a.saved == nil, "failed pickup retains restored clear even with another cursor item")
    s.failPickup = false; a.locked = true; s.cursor = {}; action.OnDragStart(a)
    check(a.ActionValue == 0 and s.cursor[1] == nil, "locked buttons refuse drag-off")
    a.locked = nil
    local writes = s.writes; s.combat = true; s.cursor = { "outfit", 0 }
    action.OnDragStart(b); action.OnReceiveDrag(b); s.dragFromFlyout(rows[1])
    check(s.writes == writes and b.ActionValue == 48, "combat drag paths leave protected attributes and assignments untouched")
    s.outfits[1].playerFacingOutfitIndex = 4
    action.RefreshOutfits(); action.RefreshOutfits()
    check(s.writes == writes, "outfit refresh is deferred under lockdown")
    local pending = 0; for _ in pairs(s.deferred) do pending = pending + 1 end
    check(pending == 2, "repeated combat refresh coalesces once per button")
    s.combat = false; s.flush()
    check(b.Widget.attrs.macrotext == "/outfit !4", "postcombat refresh reconciles changed outfit index")
    writes = s.writes; s.flush(); check(s.writes == writes, "deferred work applies once")
    s.dataError = true; action.SetAction(b, "outfit", 48)
    check(b.ActionValue == 48 and b.Widget.attrs.type == nil, "late journal preserves saved identity with inert input")
    s.dataError = false; action.RefreshOutfits()
    check(b.Widget.attrs.macrotext == "/outfit !4", "late journal refresh restores usable input")
    s.cursor = { "outfit", 0 }
    check(assign.AssignFromCursor(1, "SHIFT"), "utility slot accepts clear cursor")
    check(assign.GetSlots()[1].SHIFT.id == 0 and s.cursor[1] == nil, "utility persists clear and consumes valid cursor")
    local snapshot = assign.CaptureSnapshot()
    assign.ClearModifier(1, "SHIFT"); check(assign.ApplySnapshot(snapshot), "utility clear profile restores")
    check(assign.MatchesSnapshot(snapshot) and assign.GetSlots()[1].SHIFT.id == 0, "utility snapshot round trip retains zero")
    local clear, outfit = { type = "outfit", id = 0 }, { type = "outfit", id = 48 }
    local slots = { [""] = { type = "spell", id = 55, name = "Heal" }, SHIFT = clear, CTRL = outfit,
        ALT = { type = "macro", id = 3, name = "My macro" }, ["SHIFT-CTRL"] = { type = "item", id = 77 } }
    s.applyAttributes(a, slots)
    local attrs = a.Widget.attrs
    check(attrs["shift-macrotext1"]:match("/outfit%s+%[@mouseover,exists,nodead%]%[%]%s*$"), "clear assigned only to chosen chord")
    check(attrs["ctrl-macrotext1"]:find("!4", 1, true), "utility outfit uses current index")
    check(attrs["alt-macro1"] == "My macro" and attrs["alt-macrotext1"] == nil, "mixed user macro preserved")
    check(attrs["ctrl-shift-macrotext1"]:find("/use", 1, true) and not attrs["ctrl-shift-macrotext1"]:find("/outfit", 1, true), "more-specific item chord cannot clear outfit")
    for _, prefix in ipairs({ "", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
        check(attrs[prefix .. "macrotext1"]:find("/cast", 1, true) and not attrs[prefix .. "macrotext1"]:find("/outfit", 1, true), "unassigned chord retains base spell")
    end
    s.applyAttributes(a, { SHIFT = clear })
    check(attrs.macrotext1:find("/outfit", 1, true) and attrs["alt-macro1"] == nil, "clear-only utility mirrors base and clears stale macro attributes")
    check(assign.PickupOutfit(0) and s.cursor[2] == 0, "utility pickup uses clear cursor zero")
    -- Existing Forever assignments can be saved as spell=clearSpellID, unlike
    -- newly created outfit=0 assignments. Reproduce both cursor representations.
    local legacy = s.button()
    ns.Flux.Spell = { GetBaseSpell = function(id)
        check(id ~= 101, "synthetic clear face is never normalized as a ranked spell")
        return id
    end }
    action.SetAction(legacy, "spell", 101)
    legacy.saved = { type = "spell", id = 101 }
    s.cursor = {}; local spellPickups = s.spellPickups or 0
    action.OnDragStart(legacy)
    check(s.cursor[1] == "outfit" and s.cursor[2] == 0 and legacy.ActionType == nil and legacy.saved == nil,
        "saved spell-form clear drags off through native outfit zero")
    check((s.spellPickups or 0) == spellPickups, "clear never uses unavailable ordinary spell pickup")
    action.SetAction(legacy, "spell", 101); legacy.saved = { type = "spell", id = 101 }
    s.failPickup = true; s.cursor = { "item", 88 }; action.OnDragStart(legacy)
    check(legacy.ActionType == "spell" and legacy.ActionValue == 101 and legacy.saved.id == 101,
        "failed clear pickup retains original spell-form saved assignment")
    s.failPickup = false; s.cursor = { "spell", 4, "spell", 101 }
    s.combat = true; writes = s.writes
    action.OnDragStart(legacy)
    check(s.writes == writes and legacy.saved.type == "spell" and legacy.saved.id == 101,
        "legacy spell-form clear also refuses drag changes in combat")
    s.combat = false
    action.OnReceiveDrag(legacy)
    check(legacy.ActionType == "outfit" and legacy.saved.type == "outfit" and legacy.saved.id == 0,
        "spell-form clear cursor drops as native outfit identity zero")
    s.cursor = { "spell", 101, "flyout" }; action.OnReceiveDrag(legacy)
    check(legacy.saved.type == "outfit" and legacy.saved.id == 0, "flyout-subtype clear spell cursor resolves native zero identity")
    action.NoteFlyoutPopupSpell(101); s.cursor = { "spell", 55, "flyout" }
    action.OnReceiveDrag(legacy)
    check(legacy.saved.type == "outfit" and legacy.saved.id == 0, "stashed clear popup spell resolves native zero identity")
    s.cursor = { "spell", 4, "spell", 101 }
    check(assign.AssignFromCursor(2, "") and assign.GetSlots()[2][""].type == "outfit"
        and assign.GetSlots()[2][""].id == 0, "utility accepts spell-form clear cursor")
    -- Load the complete manager and expose its local wiring only to this fixture.
    -- Timer callbacks are held so assignment notifications cannot build unrelated UI.
    local timers = {}
    env.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    local managerBody, exposed = read("ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua")
        :gsub("\nreturn Manager\n$", "\nreturn Manager, WireSlotInteractions\n")
    check(exposed == 1, "utility fixture exposes actual interaction wiring")
    local manager, wire = assert(load(managerBody, "@production-complete-utility-manager", "t", env))()
    local utility = s.button(); utility.slotIndex = 1; wire(utility)
    local uw = utility.Widget
    check(uw.dragButtons[1] == "LeftButton", "utility slot registers native dragging")
    assign.Assign(1, { type = "spell", id = 101, name = "Clear" }, "SHIFT")
    s.failPickup = true; s.cursor = { "item", 88 }; uw.scripts.OnDragStart()
    check(assign.GetSlots()[1].SHIFT.type == "spell" and assign.GetSlots()[1].SHIFT.id == 101,
        "failed utility spell-form clear pickup retains its original assignment")
    s.failPickup = false
    s.cursor = {}; uw.scripts.OnDragStart()
    check(s.cursor[2] == 0 and assign.GetSlots()[1].SHIFT == nil, "utility drag-off clears the displayed mirrored zero-ID assignment")
    uw.scripts.OnReceiveDrag()
    check(assign.GetSlots()[1][""].id == 0 and s.cursor[1] == nil, "utility drag-in restores clear onto current chord")
    s.failPickup = true; s.cursor = { "item", 88 }; uw.scripts.OnDragStart()
    check(assign.GetSlots()[1][""].id == 0 and s.cursor[1] == "item", "utility failed pickup cannot erase clear")
    s.failPickup = false; s.combat = true; writes = s.writes
    uw.scripts.OnDragStart(); uw.scripts.OnReceiveDrag(); manager.UpdateButton(utility, slots)
    check(assign.GetSlots()[1][""].id == 0 and s.writes == writes and manager._pendingUpdate, "utility combat drag and configuration remain deferred")
    s.combat = false
    -- PickupOutfit(0) may expose the synthetic clear spell on the cursor.
    -- Success must validate that identity, not insist on cursor kind="outfit".
    for _, cursor in ipairs({ { "spell", 4, "spell", 101 }, { "spell", 101 } }) do
        s.clearPickupCursor = cursor
        for _, savedType in ipairs({ "spell", "outfit" }) do
            local id = savedType == "spell" and 101 or 0
            action.SetAction(legacy, savedType, id); legacy.saved = { type = savedType, id = id }
            s.cursor = {}; action.OnDragStart(legacy)
            check(s.cursor[1] == "spell" and legacy.ActionType == nil and legacy.saved == nil,
                "successful clear-spell cursor pickup removes runtime AND persisted source assignment")
            action.OnReceiveDrag(legacy)
            check(legacy.ActionType == "outfit" and legacy.saved.id == 0,
                "clear spell cursor moves to a destination as outfit zero")
            assign.Assign(1, { type = savedType, id = id }, "")
            s.cursor = {}; uw.scripts.OnDragStart()
            check(s.cursor[1] == "spell" and assign.GetSlots()[1][""] == nil,
                "clear spell cursor pickup removes the actual utility assignment")
        end
    end
    -- Actual minimap persistence must stay empty after pickup, including reload.
    local storage = slice(read("Minimap/FluxMinimapButtons.lua"), "local function LoadSavedVars", "local function ApplyStyle")
    local save, clearSaved, get, restore = assert(load("local CONFIG = { NumButtons = 15 }\n" .. storage
        .. "\nreturn SaveButtonData, ClearButtonData, GetButtonData, ApplySavedAction", "@production-minimap-storage", "t", env))()
    local persisted = s.button()
    persisted.OnReceiveDragCallback = function(t, id) save(1, t, id, persisted) end
    persisted.OnDelete = function() clearSaved(1) end
    s.clearPickupCursor = { "spell", 4, "spell", 101 }
    for _, savedType in ipairs({ "spell", "outfit" }) do
        local id = savedType == "spell" and 101 or 0
        save(1, savedType, id, persisted); check(restore(persisted, get(1)), "actual minimap restores existing clear")
        s.cursor = {}; action.OnDragStart(persisted)
        check(persisted.ActionType == nil and get(1).dataType == nil and get(1).actionType == nil,
            "clear drag-off clears actual minimap runtime and BOTH saved aliases")
        check(not restore(persisted, get(1)), "removed clear cannot reappear from actual minimap reload restoration")
    end
    for _, cursor in ipairs({ { "spell", 55 }, { "spell", 101, "spell", 55 }, { "outfit", 17 } }) do
        s.clearPickupCursor = cursor
        action.SetAction(legacy, "outfit", 0); legacy.saved = { type = "outfit", id = 0 }
        s.cursor = {}; action.OnDragStart(legacy)
        check(legacy.ActionType == "outfit" and legacy.saved.id == 0, "unrelated cursor never counts as successful clear pickup")
    end
    s.clearPickupCursor = nil
    s.active = nil; check(api.IsPlayerTransmogOutfitActive(0), "clear checks active when native outfit absent")
    s.active = 48; check(api.IsPlayerTransmogOutfitActive(48) and not api.IsPlayerTransmogOutfitActive(0), "normal and clear checked state distinguish outfits")
    s.outfits = {}; rows = s.build(); check(#rows == 1 and rows[1].isClear, "clear available even without saved outfits")
    env.C_TransmogOutfitInfo.ClearOutfit = nil; check(#s.build() == 0, "no invented clear action on clients lacking native clear")
    s.disabled = true; check(not api.HasPlayerTransmogOutfitAPI(), "character without enabled feature stays gated")
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    exercise(branch, branch == "live" or branch == "forever")
    -- Capability detection also supports characters on another branch if its API arrives.
    if branch ~= "live" and branch ~= "forever" then exercise(branch, true) end
end
-- Negative controls demonstrate that the behavioral assertions reject regressions.
local mutants = {
    { api = apiSource:gsub('if outfitID == 0 then', 'if outfitID == -1 then', 1) },
    { api = apiSource:gsub('tostring%(entry.index%)', 'tostring(entry.id)', 1) },
    { action = actionSource:gsub('return ns.API and ns.API.TryPickupPlayerTransmogOutfit', 'local ignored = ns.API and ns.API.TryPickupPlayerTransmogOutfit', 1) },
    { flyout = flyoutSource:gsub('return buttons\nend', 'buttons[1], buttons[2] = buttons[2], buttons[1]\n    return buttons\nend', 1) },
    { api = apiSource:gsub('then return 0 end', 'then return nil end', 1) },
    { api = apiSource:gsub('if outfitID == 0 and kind == "spell" then', 'if false then', 1) },
}
for i, mutant in ipairs(mutants) do
    check(not pcall(exercise, "forever", true, mutant), "negative control " .. i .. " rejected")
end
print(("Transmog actions: %d checks; five branches, capability adapters, six negative controls passed"):format(checks))
