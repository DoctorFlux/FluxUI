-- Production layout/backend replay; native UI, skin and owned threat APIs are mocked.
-- This does not certify native rendering, secret values, combat taint or FPS.
-- Optional args: alternate backend, layout and FluxWindowFrame source paths.
local meterSource = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
local layoutSource = arg[2] or "Battlezonemap/FluxMeterLayout.lua"
local windowSource = arg[3] or "Battlezonemap/FluxWindowFrame.lua"
local arguments = arg; arg = { meterSource, "--harness" }
local harness = assert(loadfile("tests/native_meter_ownership.lua"))()
arg = arguments
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function near(a, b) return type(a) == "number" and math.abs(a - b) < .00001 end
local THREAT = "DETAILS_PLUGIN_FLUX_THREAT"
local function threat() return { kind = "plugin", plugin = THREAT } end
local function native(id) return { kind = "blizzard", damageMeterType = id or 0 } end
local function isThreat(slot) return slot and slot.kind == "plugin" and slot.plugin == THREAT end
local function counts(lay)
    local n, t = 0, 0
    for _, row in ipairs({ lay.topSlots, lay.bottomSlots }) do
        for _, slot in ipairs(row or {}) do if isThreat(slot) then t = t + 1 else n = n + 1 end end
    end
    return n, t
end
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for k, v in pairs(value) do out[k] = copy(v) end; return out
end
local function boot(available, gamepad, saved)
    local e, s = harness(gamepad)
    s.threatAvailable = available
    e.Enum.DamageMeterType = { DamageDone = 0, Dps = 1, HealingDone = 2, Hps = 3, Absorbs = 4,
        Interrupts = 5, Dispels = 6, DamageTaken = 7, AvoidableDamageTaken = 8, Deaths = 9, EnemyDamageTaken = 10 }
    e.C_DamageMeter = { IsDamageMeterAvailable = function() return s.available end }
    e.C_AddOns = { IsAddOnLoaded = function(name) return name == "Details" and s.details end,
        DoesAddOnExist = function(name) return name == "Blizzard_DamageMeter" and s.available end }
    e._FluxUI_CharSavedVars = saved or {}
    local skin = { windows = {}, resources = 0, entries = 0, release = 0 }
    function skin:ApplyToWindow(win, scale)
        if not self.windows[win] then self.resources = self.resources + 1 end
        self.windows[win] = (self.windows[win] or 0) + 1; self.scale = scale
    end
    function skin:ApplyToEntry(entry, scale)
        self.entries = self.entries + 1; self.entryScale = scale
        self.localTint = entry.font and entry.font.g == 1 and entry.font.r == 0
    end
    function skin:ReleaseAllNative() self.release = self.release + 1 end
    e.FluxMeterSkin = skin
    local owned = { embeds = 0, shows = 0, hides = 0, cleanups = 0, layouts = 0 }
    function owned:IsAvailable() return s.threatAvailable and not s.details end
    function owned:GetFrame() return self.frame end
    function owned:Embed(parent, scale)
        self.embeds = self.embeds + 1
        if not self:IsAvailable() then return end
        if not self.frame then self.frame = e.CreateFrame("Frame", nil, parent) end
        self.frame:SetParent(parent); self.frame:SetScale(scale or 1); self:Show()
        return self.frame
    end
    function owned:Show()
        self.shows = self.shows + 1
        if not self.frame then return end
        self.frame:SetShown(self:IsAvailable() and s.activeTab == "Meter" and self.frame:GetParent():IsVisible())
    end
    function owned:Hide() self.hides = self.hides + 1; if self.frame then self.frame:Hide() end end
    function owned:Cleanup() self.cleanups = self.cleanups + 1; self:Hide() end
    function owned:RefreshLayout() self.layouts = self.layouts + 1 end
    e.FluxThreatMeter = owned
    assert(loadfile(layoutSource, "t", e))("_FluxUI", { Flux = e.Flux })
    e.FluxMeterLayout.Init()
    return e, s, owned, skin
end

local e, s, owned, skin = boot(true, false)
local lib, meter = e.FluxMeterLayout, e.FluxBlizzardMeter
check(lib.GetActiveLayoutId() == "builtin:1", "original active default remains builtin1")
check(lib.GetMaxPanes() == 4 and lib.GetBuiltinCount() == 10, "available owned pane adds one slot and appended presets")
local expected = {
    {{0}, {2}}, {{0}, {}}, {{5, 0}, {2}}, {{0}, {6, 2}}, {{0}, {2, 3}}, {{7}, {0, 2}},
}
for id, rows in ipairs(expected) do
    local lay = lib.ApplyBuiltin(id)
    local ok = lay.id == "builtin:" .. id and #lay.topSlots == #rows[1] and #lay.bottomSlots == #rows[2]
    for r, row in ipairs({ lay.topSlots, lay.bottomSlots }) do
        for i, slot in ipairs(row) do ok = ok and slot.kind == "blizzard" and slot.damageMeterType == rows[r][i] end
    end
    check(ok, "original preset" .. id .. " retains its exact native slot IDs")
end
local catalog = lib.BuildCatalog(); local catalogThreat = 0
for _, group in ipairs(catalog) do
    for _, item in ipairs(group.items or {}) do if isThreat(item.slot) then catalogThreat = catalogThreat + 1 end end
end
check(catalogThreat == 1, "native catalog includes the available owned threat provider once")
check(lib.SlotShortLabel(threat()) == "Threat", "existing threat plugin identity keeps its label")

lib.ApplyBuiltin(1); lib.SetTopColCount(2); lib.SetBottomColCount(2)
local edited = lib.GetWorkingLayout(); local n, t = counts(edited)
check(n == 3 and t == 1 and isThreat(edited.bottomSlots[2]), "editor makes the added fourth slot owned threat")
check(not lib.CanSetTopColCount(3) and not lib.CanSetBottomColCount(3), "editor refuses five total slots")
check(lib.SetSlot("bottom", 2, native(0)) == false and isThreat(lib.GetWorkingLayout().bottomSlots[2]),
    "editor refuses replacing the fourth owned pane with a fourth native pane")
lib.SetSlot("top", 1, threat()); edited = lib.GetWorkingLayout(); n, t = counts(edited)
check(n == 3 and t == 1 and isThreat(edited.topSlots[1]) and not isThreat(edited.bottomSlots[2]),
    "moving the unique threat slot preserves three native panes")
local saved = lib.SaveWorkingAsNew("Four panes")
check(saved.id == "user:1" and #e._FluxUI_CharSavedVars.fluxWindowBlizzardMeterLayouts == 1,
    "custom layouts retain the existing Blizzard saved root")
local snapshot = copy(e._FluxUI_CharSavedVars)
local re, rs = boot(true, false, copy(snapshot)); local roundtrip = re.FluxMeterLayout.GetWorkingLayout()
local rn, rt = counts(roundtrip)
check(re.FluxMeterLayout.GetActiveLayoutId() == "user:1" and rn == 3 and rt == 1,
    "saved four-pane layout restores without replacing its ID or slots")
local public = lib.GetWorkingLayout(); public.topSlots[1].plugin = "changed"
check(isThreat(lib.GetWorkingLayout().topSlots[1]), "public layout copies do not alias saved threat facts")

local lay = lib.ApplyBuiltin(8)
s.dm:ShowNewSecondarySessionWindow()
s.windows[2].meterType, s.windows[3].meterType = 6, 2 -- Native UI configuration.
s.dm:SetSessionWindowSessionID(s.windows[1], e.Enum.DamageMeterSessionType.Current, nil)
s.dm:SetSessionWindowSessionID(s.windows[2], nil, 42)
local sessionWrites = s.sessionCalls
check(meter:Embed(s.host, lay), "four-pane layout embeds")
local pane = owned:GetFrame()
check(pane and pane:GetParent() == s.host and near(pane.scale, .8), "owned pane is a scaled Content child")
check(#s.windows == 3 and s.windows[1].meterType == 0 and s.windows[2].meterType == 6
    and s.windows[3].meterType == 2, "three native windows follow their own types without mapping threat to damage")
check(s.windows[1].sessionType == e.Enum.DamageMeterSessionType.Current and s.windows[1].sessionID == nil
    and s.windows[2].sessionType == nil and s.windows[2].sessionID == 42
    and s.windows[3].sessionType == e.Enum.DamageMeterSessionType.Overall and s.windows[3].sessionID == nil
    and s.sessionCalls == sessionWrites, "four-pane embed retains Current and historical choices plus the new native Overall default")
local tp = pane and pane.points[1] or {}; local tb = pane and pane.points[2] or {}
check(tp[1] == "TOPLEFT" and tp[2] == s.dm and near(tp[4], -1.25) and near(tp[5], -7.5),
    "owned top-left converts the Details body inset and separate title into native coordinates")
check(tb[1] == "BOTTOMRIGHT" and tb[2] == s.dm and near(tb[4], -207.5) and near(tb[5], 137),
    "owned top-right pane uses the Details fractional width and body-row height")
check(near(s.windows[1].points[1][4], 167.5) and near(s.windows[3].points[1][4], 167.5),
    "native panes start after the owned column at coherent scale")
check(s.nativeMethodsIntact() and s.policyWrites == 0, "integration preserves native methods and visibility ownership")
check(skin.windows[s.windows[1]] > 0 and skin.windows[s.windows[1].sourceWindow] > 0
    and near(skin.scale, .8) and near(skin.entryScale, .8), "native window and entry skin runs at accepted scale")
local frameCount, timerCount, hooks = #s.frames, s.timerCreates, #s.hooks[s.windows[1]].InitEntry
local skinResources = skin.resources
for _ = 1, 500 do meter:RefreshEmbeddedLayout() end
check(#s.frames == frameCount and s.timerCreates == timerCount and #s.windows == 3,
    "repeated four-pane reconciliation adds no frames timers or native windows")
check(skin.windows[s.windows[1]] > 1 and skin.resources == skinResources
    and #s.hooks[s.windows[1]].InitEntry == hooks,
    "post-configuration paint reuses skin resources and permanent entry hooks on relayout")
check(owned.embeds == 1, "geometry reuses the existing owned pane without re-embedding")
check(s.sessionCalls == sessionWrites and s.savedSessions[s.windows[1]].sessionType == e.Enum.DamageMeterSessionType.Current
    and s.savedSessions[s.windows[2]].sessionID == 42, "500 four-pane layouts never overwrite saved native session choices")
s.windows[1]:InitEntry(s.windows[1].entry, { isLocalPlayer = true })
check(skin.localTint, "entry skin follows existing green local-player paint")

lay = lib.ApplyBuiltin(9); meter:Embed(s.host, lay)
check(not s.dm:IsShown() and pane and pane:IsVisible(), "threat-only layout hides native root but keeps the owned pane visible")
check(pane and near(pane.points[1][4], -1.25) and near(pane.points[1][5], -7.5)
    and near(pane.points[2][4], 1.25) and pane.points[2][5] == 0,
    "threat-only pane retains the Details single-body bounds and title offset")
s.dm:UpdateShownState()
check(not s.dm:IsShown() and pane and pane:IsVisible(), "native visibility events cannot reveal unused native panes")
s.combat = true; s.activeTab = "Map"; meter:Hide(); s.activeTab = "Meter"; meter:Show()
check(not s.dm:IsShown() and pane and pane:IsVisible(), "combat reopen preserves threat-only ownership")
s.host.shown = false; meter:Show()
check(pane and not pane:IsShown(), "hidden host suppresses owned threat")
s.host.shown = true; meter:Show()
check(pane and pane:IsShown(), "combat host reveal can restore owned threat")
s.combat = false; meter:Embed(s.host, lib.ApplyBuiltin(8)); s.visibility = 2; s.dm:UpdateShownState()
check(not s.dm:IsShown() and pane and pane:IsVisible(), "native Hidden policy does not hide independent owned threat")
s.visibility = 0
meter:Cleanup()
check(owned.cleanups > 0 and pane and not pane:IsShown() and skin.release > 0,
    "cleanup releases owned lifecycle and active native skin owners")
meter:Embed(s.host, lib.ApplyBuiltin(8))
check(s.sessionCalls == sessionWrites and s.windows[1].sessionType == e.Enum.DamageMeterSessionType.Current
    and s.windows[2].sessionID == 42, "threat-only layout and cleanup preserve native session choices on return")
check(#s.hooks[s.windows[1]].InitEntry == hooks and skin.resources == skinResources
    and skin.windows[s.windows[1]] > 1,
    "re-embed reactivates existing skin resources without another permanent entry hook")
s.details = true; e.Details = {}; s.dm:UpdateShownState(); meter:Hide()
check(lib.GetMeterBackend() == "Details" and lib.GetBuiltinCount() == 11 and not s.dm:IsShown()
    and pane and not pane:IsShown(), "Details handoff stops native and owned presentation")

local ue, us, unavailable = boot(false, false, copy(snapshot))
local ul = ue.FluxMeterLayout
check(ul.GetMaxPanes() == 3 and ul.GetBuiltinCount() == 6, "unsupported client keeps the original native limits")
local unavailableThreat = 0
for _, group in ipairs(ul.BuildCatalog()) do
    for _, item in ipairs(group.items or {}) do if isThreat(item.slot) then unavailableThreat = unavailableThreat + 1 end end
end
check(unavailableThreat == 0, "unavailable provider is absent from the native catalog")
local un, ut = counts(ul.GetWorkingLayout())
check(un == 3 and ut == 1 and ul.GetActiveLayoutId() == "user:1", "unavailable provider does not erase saved four-pane facts")
ue.FluxBlizzardMeter:Embed(us.host, ul.GetWorkingLayout())
check(not unavailable:GetFrame() and us.windows[1].meterType == 0 and us.windows[2].meterType == 2,
    "unavailable owned slot is omitted while native saved types remain")
local presetSaved = copy(snapshot); presetSaved.fluxWindowBlizzardMeterActiveLayoutId = "builtin:9"
local pe, ps = boot(false, false, presetSaved)
check(pe.FluxMeterLayout.GetActiveLayoutId() == "builtin:9"
    and isThreat(pe.FluxMeterLayout.GetWorkingLayout().topSlots[1]), "unavailable saved threat preset retains its stable ID")
pe.FluxBlizzardMeter:Embed(ps.host, pe.FluxMeterLayout.GetWorkingLayout())
check(not ps.dm:IsShown() and ps.windows[1].meterType == 0, "unavailable threat-only slot never silently becomes Damage")

local ge, gs, gamepadOwned = boot(true, true)
gs.host.scale = 1.25; gs.dm:ShowNewSecondarySessionWindow()
gs.windows[2].meterType, gs.windows[3].meterType = 6, 2
ge.FluxBlizzardMeter:Embed(gs.host, ge.FluxMeterLayout.ApplyBuiltin(8))
check(gs.dm:GetParent() == ge.UIParent and gamepadOwned:GetFrame()
    and gamepadOwned:GetFrame():GetParent() == gs.host, "gamepad retains native parent while owned pane stays a Content child")
check(near(gs.dm.scale, 1) and near(gamepadOwned:GetFrame() and gamepadOwned:GetFrame().scale, .8),
    "gamepad native and owned panes compensate the same host scale")
check(gs.nativeMethodsIntact() and gs.policyWrites == 0, "gamepad layout preserves native data and visibility ownership")
local function attachCVar(env, state, value, locked, secure, readOnly)
    local cv = { value = value, writes = 0, reads = 0, nativeUpdates = 0, loads = 0 }
    env.C_CVar = {
        GetCVar = function(name)
            assert(name == "damageMeterEnabled", "only the requested feature CVar is read")
            cv.reads = cv.reads + 1; return cv.value
        end,
        GetCVarInfo = function(name)
            assert(name == "damageMeterEnabled")
            return cv.value, "0", false, false, locked, secure, readOnly
        end,
        SetCVar = function(name, nextValue)
            assert(name == "damageMeterEnabled" and nextValue == "1", "only enable the native feature")
            assert(not state.combat and not locked and not secure and not readOnly, "CVar write preconditions")
            cv.writes = cv.writes + 1; cv.value = nextValue
            -- Native CVAR_UPDATE is deliberately a later fixture action. Flux
            -- must not mutate or force-refresh that native visibility cache.
        end,
    }
    state.enabled = value == "1"
    env.C_AddOns.LoadAddOn = function() cv.loads = cv.loads + 1; error("addon must not bootstrap native UI") end
    function cv:nativeUpdate()
        self.nativeUpdates = self.nativeUpdates + 1
        state.enabled = self.value == "1"; state.dm:OnEvent("PLAYER_LEVEL_CHANGED")
    end
    return cv
end
local ce, cs = boot(true, false); local cm = ce.FluxBlizzardMeter
local cv = attachCVar(ce, cs, "0")
check(cm:Embed(cs.host, ce.FluxMeterLayout.ApplyBuiltin(1)) and cv.writes == 1 and cv.value == "1",
    "requesting the native backend enables its public feature setting once")
check(not cs.enabled and not cs.dm:IsShown() and cs.timerDispatches == 0 and cs.policyWrites == 0,
    "enabling leaves native cached policy and timer dispatch to the native event")
cv:nativeUpdate()
check(cs.dm:IsShown() and cs.timerDispatches == 1, "native setting update can reveal the requested meter")
for _ = 1, 500 do cm:Show() end
check(cv.writes == 1 and cv.loads == 0, "enabled feature is not rewritten and Flux never loads native UI directly")
cs.combat = true; cv.value = "0"; cs.enabled = false; cm:Show()
check(cv.writes == 1 and cv.value == "0", "combat Show defers a disabled feature write")
cs.combat = false; cs.event("PLAYER_REGEN_ENABLED")
check(cv.writes == 2 and cv.value == "1" and not cs.enabled,
    "existing combat-exit queue enables without changing the native cache")
cv:nativeUpdate(); check(cs.dm:IsShown(), "native visibility resumes after deferred feature enable")
cs.combat = true; cv.value = "0"; cs.enabled = false; cm:Show(); cm:Hide()
cs.combat = false; cs.event("PLAYER_REGEN_ENABLED")
check(cv.writes == 2 and cv.value == "0", "leaving the Meter tab cancels deferred feature enable")

for _, flags in ipairs({ {true, false, false}, {false, true, false}, {false, false, true} }) do
    local fe, fs = boot(true, false); local fc = attachCVar(fe, fs, "0", flags[1], flags[2], flags[3])
    fe.FluxBlizzardMeter:Embed(fs.host, fe.FluxMeterLayout.ApplyBuiltin(1))
    check(fc.writes == 0 and fc.value == "0", "locked secure or read-only CVar remains native-owned")
end
local ne, ns = boot(true, false); local nc = attachCVar(ne, ns, nil)
ne.FluxBlizzardMeter:Embed(ns.host, ne.FluxMeterLayout.ApplyBuiltin(1))
check(nc.writes == 0, "unknown feature CVar is not invented")
local me, ms = boot(true, false); ms.enabled = false; me.C_CVar = nil
check(me.FluxBlizzardMeter:Embed(ms.host, me.FluxMeterLayout.ApplyBuiltin(1)) and not ms.dm:IsShown(),
    "missing CVar API preserves native policy without an invented replacement")
local de, ds = boot(true, false); local dc = attachCVar(de, ds, "0")
ds.details = true; de.Details = {}; de.FluxBlizzardMeter:Embed(ds.host, {})
de.FluxBlizzardMeter:Show()
check(dc.writes == 0, "Details backend never changes the Blizzard feature setting")
local ae, ass = boot(true, false); local ac = attachCVar(ae, ass, "0"); ae.C_DamageMeter = nil
ae.FluxBlizzardMeter:Embed(ass.host, {})
check(ac.writes == 0, "unsupported native client never changes the feature setting")
local be, bs = boot(true, false); local bc = attachCVar(be, bs, "0")
be.DamageMeter = nil; bs.activeTab = "Map"
local file = assert(io.open(windowSource, "r")); local windowCode = file:read("*a"); file:close()
local register = assert(windowCode:match("(local function RegisterMeterTab%(%)%s.-)\n%-%- Function to initialize the window frame and tabs"))
local prefix = [[
local tabs = {}
local windowFrame = FluxWindowFrame.frame
local Flux = nil
local ResolveMeterSystem = function() return "BlizzardMeter" end
local TabAfter = function(_, _, delay, callback) C_Timer.After(delay, callback) end
local GetTabStatusText = function() return { SetText = function() end, SetTextColor = function() end } end
function FluxWindowFrame:AddTab(name, onShow)
    local tab = { content = CreateFrame("Frame", nil, windowFrame.Content) }
    tabs[name] = tab; TestMeterTab, TestMeterTabShow = tab, onShow
end
function FluxWindowFrame:GetMeterLayoutConfig() return FluxMeterLayout.GetWorkingLayout() end
]]
assert(load(prefix .. register .. "\nRegisterMeterTab()", "@actual Meter tab registration", "t", be))()
check(bc.writes == 0, "Map startup does not enable a native feature before Meter is requested")
bs.activeTab = "Meter"; be._FluxUI_CharSavedVars.fluxWindowActiveTab = 2
be.TestMeterTabShow(be.TestMeterTab)
check(bc.writes == 1 and not be.FluxBlizzardMeter:IsEmbedded(),
    "actual first Meter tab selection enables before checking unloaded native readiness")
be.DamageMeter = bs.dm; bc:nativeUpdate(); bs.event("ADDON_LOADED", "Blizzard_DamageMeter"); bs.drain()
check(be.FluxBlizzardMeter:IsEmbedded() and bc.writes == 1 and bc.loads == 0,
    "native bootstrap and the existing Meter retry recover without addon LoadAddOn")
local qe, qs = boot(true, false); local qc = attachCVar(qe, qs, "0"); qs.combat = true
check(not qe.FluxBlizzardMeter:Embed(qs.host, qe.FluxMeterLayout.ApplyBuiltin(1)) and qc.writes == 0,
    "first combat embed defers feature enable with its existing layout request")
qs.combat = false; qs.event("PLAYER_REGEN_ENABLED")
check(qe.FluxBlizzardMeter:IsEmbedded() and qc.writes == 1, "deferred first embed enables on combat exit")

print(string.format("native threat layout: %d checks, %d failures; nativeMax=%d ownedFrames=%d permanentEntryHooks=%d",
    checks, failures, #s.windows, owned:GetFrame() and 1 or 0, #s.hooks[s.windows[1]].InitEntry))
assert(failures == 0, "native threat layout regressions")
