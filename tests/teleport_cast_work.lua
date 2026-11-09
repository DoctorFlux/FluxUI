-- Production teleport module replay. Native timing/input/security remain pending.
local source = "ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua"
local measure = false
for i = 1, #arg do
    if arg[i] == "--source" then source = arg[i + 1] end
    if arg[i] == "--measure" then measure = true end
end
local file = assert(io.open(source)); local code = file:read("*a"); file:close()
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function boot(modern, secret)
    local s = { scans = 0, rebuilds = 0, timers = {}, frames = {}, combat = false, display = "" }
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.SlashCmdList = {}; env.UIParent = {}; env.REAGENTS = "Reagents"
    env.GetTime = function() return 10 end
    env.InCombatLockdown = function() return s.combat end
    env.GetSpellTexture = function(id) return id end
    env.GetItemIcon = function(id) return id end
    env.GetSpellInfo = function(id) return "Teleport: Test", nil, id end
    env.C_Timer = { After = function(delay, fn) s.timers[#s.timers + 1] = { delay, fn } end }
    env.Flux = { Secrets = { SafeAccessibleString = function(v) if not secret then return v end end },
        Inventory = { GetCount = function() return 17 end } }
    if modern then env.C_Spell = { GetSpellDisplayCount = function(id) s.displayID = id; return s.display end } end
    env.CreateFrame = function(kind, name)
        local f = { events = {}, scripts = {} }
        function f:RegisterEvent(event) self.events[event] = true end
        f.RegisterUnitEvent = f.RegisterEvent
        function f:SetScript(k, v) self.scripts[k] = v end
        function f:SetOwner() end
        function f:ClearLines() end
        function f:SetSpellByID(id)
            s.scans = s.scans + 1
            env.FluxNCTeleportPortalSpellScannerTextLeft1 = { GetText = function()
                return s.reagent and "Reagents: Rune of Teleportation" or "Travel to a city"
            end }
        end
        function f:NumLines() return 1 end
        s.frames[#s.frames + 1] = f
        return f
    end
    env.C_Item = { GetItemInfoByName = function() return 17031 end }
    assert(load(code, "@" .. source, "t", env))()
    local m = env.FluxNCTeleportPortal
    local spells = { { name = "Teleport: A", spellID = 3561, icon = 1 },
        { name = "Teleport: B", spellID = 3562, icon = 2 } }
    m.GetKnownTeleportSpells = function() return spells end
    m.GetKnownPortalSpells = function() return spells end
    m.GetMode = function() return m.MODE_TELEPORT end
    local count = { SetText = function(self, v) self.text = v end, Show = function() end }
    local btn = { WCount = count, MacroMode = "spell", SpellNameRank = "Teleport: A", SpellId = 3561,
        UpdateTextCount = function(self) self.WCount:SetText(s.reagent and "17" or 0); s.baseCounts = (s.baseCounts or 0) + 1 end }
    -- Execute the exact override installed by CreateButton, with its real reagent resolver.
    local override = assert(code:match("(    btn.UpdateTextCount = function%(self%).-)    %-%- Apply styling"))
    env.Module = m; env.btn = btn
    env.GetRequiredReagentsForMode = m.GetRequiredReagentsForMode
    env.GetBagItemCount = function() return 17 end; env.NoteReagentItemID = function() end
    assert(load("local btn, Module = btn, Module\nlocal baseUpdateTextCount = btn.UpdateTextCount\n" .. override,
        "@count-override", "t", env))()
    s.btn, s.m, s.env = btn, m, env
    s.event = s.frames[1].scripts.OnEvent
    return s
end

for _, mode in ipairs({ "modern", "legacy" }) do
    local s = boot(mode == "modern", false); local m, btn = s.m, s.btn
    btn:UpdateTextCount()
    check(btn.WCount.text == "", mode .. " reagent-free count blank")
    if mode == "modern" then
        check(s.scans == 0, "modern count does not tooltip-scan")
        s.display = "3"; btn:UpdateTextCount()
        check(btn.WCount.text == "3" and s.displayID == 3561, "native display count and face identity")
        btn.PlaceholderHideCount = true; btn:UpdateTextCount()
        check(btn.WCount.text == "", "placeholder clears old count")
        btn.PlaceholderHideCount = nil; s.display = ""; btn:UpdateTextCount()
        check(btn.WCount.text == "", "native empty clears prior digits")
    else
        s.reagent = true; btn:UpdateTextCount()
        check(btn.WCount.text == "17", "legacy rune count preserved")
    end
    local scans = s.scans
    check(m.CountVisibleTeleportDestinations() == 2, mode .. " two destinations")
    check(s.scans == scans, mode .. " destination count skips reagent tooltips")
    s.env.FluxNCFlyoutOptions = { ApplyClassTeleportSpells = function(_, actions) return { actions[2] } end }
    check(m.CountVisibleTeleportDestinations() == 1 and not m.HasTeleportFlyout(), mode .. " hidden destinations respected")
    s.env.FluxNCFlyoutOptions = nil

    -- Real Update remains installed: count popup/arrow/key/tooltip work at its boundaries.
    m.HasAnyTeleportOrPortalSpell = function() return true end
    local calls = {}
    for _, name in ipairs({ "ApplyMacro", "SetupRightClick", "SetupMiddleClick", "UpdateTexture",
        "UpdateFlyoutArrow", "UpdateHotkeyText", "UpdateTeleportKeybinding", "RefreshTooltip", "UpdateIcon" }) do
        m[name] = function() calls[name] = (calls[name] or 0) + 1 end
    end
    m.SyncFlyoutEngine = function() s.rebuilds = s.rebuilds + 1 end
    m._button = btn
    for i = 1, 100 do
        m._isLocked = true; m._isCasting = true; m._lockedSpell = { spellID = 3562 }
        m._pendingLockSpell = { spellID = 3562 }; m._castLockSpellId = 3562
        s.event(nil, "UNIT_SPELLCAST_INTERRUPTED", "player", "Cast-test", 3562)
        s.event(nil, "UNIT_SPELLCAST_FAILED", "player", "Cast-test", 3562)
        check(not m._isLocked and not m._isCasting and not m._pendingLockSpell and not m._castLockSpellId,
            mode .. " interrupted cleanup " .. i)
    end
    check(s.rebuilds == 0, mode .. " 100 interruptions do not rebuild popup")
    check(calls.ApplyMacro == 100 and calls.UpdateIcon == 100, mode .. " restore macro and modifier face once")
    check(not calls.UpdateTeleportKeybinding and not calls.UpdateFlyoutArrow, mode .. " stable keys and arrow not rebuilt")
    s.combat = true; m._registered = true; m._isLocked = true
    s.event(nil, "UNIT_SPELLCAST_INTERRUPTED", "player", "Cast-test", 3562)
    check(m._isLocked and m._pendingUnlock, mode .. " combat unlock deferred")
    s.combat = false; s.event(nil, "PLAYER_REGEN_ENABLED")
    check(not m._isLocked and not m._pendingUnlock, mode .. " regen unlock restored")
    print(mode .. " scans=" .. s.scans .. " popup_rebuilds=" .. s.rebuilds)
end
local opaque = boot(true, true)
check(next(opaque.m.GetRequiredReagentsForMode("Teleport")) == nil, "opaque tooltip does not invent teleport rune")
check(next(opaque.m.GetRequiredReagentsForMode("Portal")) == nil, "opaque tooltip does not invent portal rune")
local nativeSecret = {}; opaque.display = nativeSecret; opaque.btn:UpdateTextCount()
check(opaque.btn.WCount.text == nativeSecret, "native opaque display passed directly to font string")

-- Keep production ApplyMacro/SetupClickHandlers/Lock/Unlock/count together. Only
-- surrounding UI services and action transport are replaced by counted boundaries.
local integrated = boot(true, true)
do
    local s, m, btn = integrated, integrated.m, integrated.btn
    local icon = { SetTexture = function() end, SetDesaturated = function() end,
        SetVertexColor = function() end, Show = function() end }
    btn.WIcon = icon
    btn.Widget = { attrs = {}, hooks = {} }
    function btn.Widget:Show() end
    function btn.Widget:SetAttribute(k, v) self.attrs[k] = v end
    function btn.Widget:HookScript(k, v) self.hooks[k] = v end
    function btn:SetAction(kind, value) self.action, self.body = kind, value; self:UpdateTextCount() end
    function btn:FullRefresh() self:UpdateTextCount() end
    function btn:UpdateUsable() self:UpdateTextCount() end
    m._button = btn
    m.HasAnyTeleportOrPortalSpell = function() return true end
    m.HasAnyTeleportSpell = function() return true end
    m.HasAnyPortalSpell = function() return true end
    m.GetSpellForModifier = function() return { name = "Teleport: A", spellID = 3561, icon = 1 } end
    m.BuildConditionalCastLine = function() return "/cast [mod:shift] Teleport: B; Teleport: A" end
    for _, name in ipairs({ "UpdateFlyoutArrow", "UpdateHotkeyText", "UpdateTeleportKeybinding", "RefreshTooltip" }) do
        m[name] = function() end
    end
    m.SyncFlyoutEngine = function() s.rebuilds = s.rebuilds + 1; m.BuildFlyoutActions() end
    for i = 1, 100 do
        m._pendingLockSpell = { name = "Teleport: B", spellID = 3562, icon = 2 }
        s.event(nil, "UNIT_SPELLCAST_START", "player", "Cast-test", 3562)
        check(m._isLocked and m._castLockSpellId == 3562, "integrated cast locks " .. i)
        s.event(nil, "UNIT_SPELLCAST_INTERRUPTED", "player", "Cast-test", 3562)
        check(btn.SpellId == 3561 and btn.body:find("%[mod:shift%]"), "integrated modifier macro restored " .. i)
        check(btn.Widget.attrs.type2 == "macro" and btn.Widget.attrs.type3 == "macro", "integrated right/middle click preserved " .. i)
    end
    check(s.scans == 0 and s.rebuilds == 0, "integrated 100 cast interruptions skip tooltip/layout rebuilds")
    print("integrated scans=" .. s.scans .. " popup_rebuilds=" .. s.rebuilds)
end
print(string.format("teleport cast: %d checks, %d failures", checks, failures))
if not measure then assert(failures == 0) end
