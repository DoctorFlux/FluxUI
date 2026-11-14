-- Actual Flux module; optional full pinned Blizzard tracking-menu generator replay.
-- Native rendering, secret values, combat taint and controller input are not mocked evidence.
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local mainPath = os.getenv("FLUX_MINIMAP_TRACKING_SOURCE") or "Minimap/FluxMinimap.lua"
local source = read(mainPath)
source = assert(source:match("%-%- BEGIN FLUX MINIMAP TRACKING(.-)%-%- END FLUX MINIMAP TRACKING"),
    "tracking must be present in the existing minimap Lua file")
local compatibility = read("Minimap/FluxMinimapTracking.lua")
local cache = os.getenv("FLUX_MINIMAP_TRACKING_NATIVE_CACHE")
local noop = function() end
local function description()
    local d = {children = {}}
    function d:EnumerateElementDescriptions() return ipairs(self.children) end
    function d:GetData() return self.data end
    function d:SetTag(tag) self.tag = tag end
    function d:CreateButton(name, responder)
        local child = description(); child.name, child.responder = name, responder
        self.children[#self.children + 1] = child; return child
    end
    function d:CreateCheckbox(name, selected, responder, data)
        local child = self:CreateButton(name, responder)
        child.selected, child.data = selected, data; return child
    end
    function d:CreateDivider() self.dividers = (self.dividers or 0) + 1 end
    function d:AddInitializer(fn) self.initializer = fn end
    return d
end

local function boot(flavor, character, change)
    local e = setmetatable({}, {__index = _G}); e._G = e
    local t = {data = {
        {id = 64, name = "Mail", active = true, texture = 101},
        {id = 16384, name = "Localized Target", active = false, texture = 102},
        {id = 32768, name = "Localized Focus", active = false, texture = 103},
    }, writes = {}, timers = {}, events = {}, start = {}, character = character or {}, showAll = false}
    e.Enum = {MinimapTrackingFilter = setmetatable({Target = 16384, Focus = 32768, Mailbox = 64}, {__index = function(_, k) return #k + 200 end}), GameRule = {IngameTrackingDisabled = 0}}
    e.C_CVar = {GetCVarBool = function(name) check(name == "minimapTrackingShowAll", "only tracking CVar read"); return t.showAll end}
    e.GetCVarBool = e.C_CVar.GetCVarBool
    e.C_Minimap = {
        GetNumTrackingTypes = function() return #t.data end,
        GetTrackingFilter = function(i) local row = t.data[i]; return row and {filterID = row.id, spellID = row.spellID} end,
        GetTrackingInfo = function(i)
            local row = t.data[i]
            if not row or row.noInfo then return end
            return {name = row.name, active = row.active, texture = row.texture}
        end,
        SetTracking = function(i, on)
            check(type(on) == "boolean", "native bool setter")
            local row = assert(t.data[i]); check(row.id == 16384 or row.id == 32768, "other tracking untouched")
            t.writes[#t.writes + 1] = {id = row.id, on = on}; row.active = on
        end,
    }
    if flavor:find("classic") then e.C_Minimap.GetTrackingFilter = nil end
    e.Menu = {ModifyMenu = function(tag, fn)
        check(tag == "MENU_MINIMAP_TRACKING", "native menu tag"); t.modify = fn
        if t.cached then fn(nil, t.cached) end
    end}
    e.MinimapConstants = {OPTIONAL_FILTERS = {}}
    local flux = {
        DB = {GetChar = function() t.dbReads = (t.dbReads or 0) + 1; return t.character end},
        AddOn = {IsLoaded = function(name) check(name == "ForeverMinimapTarget", "only reference owner checked"); return t.external end},
        AfterLogin = function(fn) t.start[#t.start + 1] = fn end,
        Timer = {After = function(delay, fn) check(delay == 3, "bounded original settle delay"); t.timers[#t.timers + 1] = fn end},
        Events = {Register = function(event, fn)
            check(event == "PLAYER_ENTERING_WORLD", "only shared world event"); t.events[event] = fn
        end},
    }
    if change then change(t, e) end
    assert(load(source, "@FluxMinimapTracking", "t", e))("_FluxUI", {Flux = flux})
    check(#t.start == 1, "existing minimap Lua initializes tracking without new TOC entry")
    assert(load(compatibility, "@trackingCompatibilityEntry", "t", e))("_FluxUI", {Flux = flux})
    check(#t.start == 1, "new TOC compatibility entry cannot register twice")
    check(not t.modify and #t.timers == 0 and not t.dbReads, "wait for shared login")
    for _, fn in ipairs(t.start) do fn() end
    t.api, t.env, t.flux = flux.MinimapTracking, e, flux
    function t:menu(root) root = root or description(); if self.modify then self.modify(nil, root) end; return root end
    function t:flush() local timers = self.timers; self.timers = {}; for _, fn in ipairs(timers) do fn() end end
    function t:world() self.events.PLAYER_ENTERING_WORLD() end
    return t
end

for _, flavor in ipairs({"forever", "live"}) do
    local t = boot(flavor)
    check(t.character.minimapTracking.Target == true and t.character.minimapTracking.Focus == nil, "target default; focus preserved")
    check(#t.writes == 1 and t.data[2].active and not t.data[3].active, "apply only target")
    t:flush(); check(#t.writes == 1, "settled unchanged state writes nothing")
    local root = t:menu()
    check(#root.children == 2 and root.dividers == 1, "two hidden choices; one divider")
    check(root.children[1].name == "Localized Target" and root.children[2].name == "Localized Focus", "native localization")
    local row = root.children[1]
    check(row.selected(row.data), "native checked state")
    local texture = {SetTexture = function(self, v) self.value = v end, SetSize = noop, SetPoint = noop}
    local label = {SetPoint = noop, GetUnboundedStringWidth = function() return 90 end}
    local w, h = row.initializer({AttachTexture = function() return texture end, fontString = label})
    check(texture.value == 102 and w == 154 and h == 20, "native icon; text width accommodates localization")
    row.responder(row.data)
    check(not t.data[2].active and t.character.minimapTracking.Target == false, "target off persists")
    root.children[2].responder("Focus")
    check(t.data[3].active and t.character.minimapTracking.Focus == true, "focus on persists")
    t.data[2].active, t.data[3].active = true, false
    t:world(); check(not t.data[2].active and t.data[3].active, "world transition restores choices")
    -- A newer user choice while a retry is queued must win.
    t.api.SetActive("Focus", false); t:flush()
    check(not t.data[3].active, "delayed retry uses latest preference")
    t.data[1], t.data[2], t.data[3] = t.data[3], t.data[1], t.data[2]
    t.api.SetActive("Target", true)
    check(t.data[3].active and t.writes[#t.writes].id == 16384, "spell changes cannot reuse stale index")
    local again = boot(flavor, t.character)
    check(again.data[2].active and not again.data[3].active, "reload persists both explicit values")
    local off = boot(flavor, {minimapTracking = {Target = false, Focus = false}, unrelated = {saved = 7}})
    check(#off.writes == 0 and off.character.unrelated.saved == 7, "explicit false and other saved data preserved")
    off.showAll = true; off.data[2].active = true; off:world(); off:flush()
    check(#off:menu().children == 0 and #off.writes == 0, "show-all delegates native menu and state")
    off.showAll = false; off:world(); check(not off.data[2].active, "normal mode restores preference")
    local native = description():CreateButton("nested")
    native:CreateCheckbox("native target", noop, noop, {index = 2})
    native:CreateCheckbox("native focus", noop, noop, {index = 3})
    local outer = description(); outer.children[1] = native
    off:menu(outer)
    check(#outer.children == 1 and not outer.dividers, "native nested choices never duplicated")
    off.data[2].active = true; off:world(); check(off.data[2].active, "native owned filter not overridden")
    local future = boot(flavor, nil, function(_, e) e.MinimapConstants.OPTIONAL_FILTERS[16384] = true end)
    check(#future.writes == 0 and #future:menu().children == 1, "future optional native target stays native")
    local external = boot(flavor, nil, function(t) t.external = true end)
    check(not external.modify and not external.dbReads and #external.timers == 0, "standalone owns all resources when loaded")
    local late = boot(flavor); late.external = true; late.data[2].active = false; late:flush()
    check(not late.data[2].active and #late:menu().children == 0, "late standalone avoids writes and duplicate menu")
    local malformed = boot(flavor, {minimapTracking = "keep me"})
    check(malformed.character.minimapTracking == "keep me" and not malformed.modify, "malformed recoverable data retained")
    local missing = boot(flavor, nil, function(t) t.data = {t.data[1]} end)
    check(#missing.writes == 0 and #missing:menu().children == 0 and not missing:menu().dividers, "enum alone cannot create a filter")
    local incomplete = boot(flavor, nil, function(t) t.data[2].noInfo = true end)
    check(#incomplete.writes == 0 and #incomplete:menu().children == 1, "nil tracking metadata is skipped")
    local partial = boot(flavor, nil, function(t) table.remove(t.data, 3) end)
    check(#partial:menu().children == 1 and partial.character.minimapTracking.Focus == nil, "target-only runtime never fabricates focus")
    local cached = boot(flavor, nil, function(t) t.cached = description() end)
    check(#cached.cached.children == 2, "previously generated native menu may extend immediately at registration")
    local epochs = boot(flavor)
    epochs:world(); local writes = #epochs.writes; epochs.data[2].active = false
    table.remove(epochs.timers, 1)()
    check(#epochs.writes == writes, "stale world retry invalidated")
    epochs:flush(); check(epochs.data[2].active, "latest world retry restores engine reset")
end

for _, flavor in ipairs({"classic", "classic_era", "classic_anniversary"}) do
    local t = boot(flavor)
    check(not t.modify and not t.dbReads and not next(t.events) and #t.timers == 0, "unsupported client inert: " .. flavor)
end
for _, absent in ipairs({"GetNumTrackingTypes", "GetTrackingInfo", "SetTracking"}) do
    local t = boot("forever", nil, function(_, e) e.C_Minimap[absent] = nil end)
    check(not t.modify and not t.dbReads, "partial API inert: " .. absent)
end
local disabled = boot("forever", nil, function(_, e)
    e.C_GameRules = {IsGameRuleActive = function() return true end}
end)
check(not disabled.modify and not disabled.dbReads, "native no-tracking game rule respected")

-- Execute the complete upstream OnLoad/menu generator, not a rewritten predicate.
if cache then
    for _, flavor in ipairs({"forever", "live"}) do
        local t = boot(flavor)
        local e = t.env
        local native = read(cache .. "/" .. flavor .. "/Interface/AddOns/Blizzard_Minimap/Mainline/Minimap.lua")
        local tables = flavor == "live" and assert(native:match("(local OPTIONAL_FILTERS = %b{})")) or ""
        if flavor == "forever" then
            assert(load(read(cache .. "/forever/Interface/AddOns/Blizzard_Minimap/Camelot/MinimapConstants.lua"), "@nativeConstants", "t", e))()
        end
        local predicate = assert(native:match("(local function CanDisplayTrackingInfo%(index%).-\nend)"))
        local onload = assert(native:match("(function MiniMapTrackingButtonMixin:OnLoad%(%).-)\nfunction MiniMapTrackingButtonMixin:RegisterSettingEntryCallbacks"))
        e.MiniMapTrackingButtonMixin = {}; e.ButtonStateBehaviorMixin = {OnLoad = noop}
        e.C_GameRules = {IsGameRuleActive = function() return false end}
        e.MinimapCluster = {Tracking = {SetShown = noop}}
        e.InputUtil = {IsGamepadUIEnabled = function() return false end}
        e.UnitClass = function() return "Warrior", "WARRIOR" end
        e.TableUtil = {Execute = function(groups, fn) for _, group in ipairs(groups) do fn(group) end end}
        e.HUNTER_TRACKING, e.TOWNSFOLK_TRACKING = 1, 2
        e.UNCHECK_ALL = "None"; e.MenuResponse = {Refresh = 1}
        -- Only providers irrelevant to generation/check state are placeholders.
        local preamble = "local LOW_PRIORITY_TRACKING_SPELLS = {}; local TRACKING_SPELL_OVERRIDE_ATLAS = {}; local trackingState = {}; local function IsTrackingActive() return false end; local function ToggleTrackingSelected() end; "
        assert(load(tables .. "\n" .. predicate .. "\n" .. preamble .. onload, "@pinnedNativeMenu", "t", e))()
        local button = {RegisterEvent = noop, RegisterSettingEntryCallbacks = noop,
            SetupMenu = function(_, fn) t.nativeGenerator = fn end}
        e.MiniMapTrackingButtonMixin.OnLoad(button)
        local root = description(); t.nativeGenerator(button, root)
        local count = #root.children
        check(count == 2, "real normal menu contains None and Mail; target/focus hidden")
        t:menu(root)
        check(#root.children == count + 2, "real native hidden filters restored: " .. flavor)
        t.showAll = true; root = description(); t.nativeGenerator(button, root)
        count = #root.children; t:menu(root)
        check(#root.children == count and count == 3, "real show-all menu left intact: " .. flavor)
        print("Pinned native full tracking generator replay PASS: " .. flavor)
    end
end
print("Minimap tracking PASS: " .. checks .. " checks; native pixels/input/controller/taint/FPS NOT RUN")
