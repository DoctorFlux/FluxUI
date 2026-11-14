-- Actual picker/backend/tab routes with immutable, natively prepared menu caches.
-- Caller/provenance model only: no native secure VM, taint, controller or pixel claim.
local source = arg[1] or "Battlezonemap/FluxBlizzardMeter.lua"
local layoutSource = arg[2] or "Battlezonemap/FluxMeterLayout.lua"
local menuSource = arg[3] -- Optional externally pinned Blizzard_Menu/Menu.lua.
local originalArgs = arg; arg = {source, "--harness"}
local harness = assert(loadfile("tests/native_meter_ownership.lua"))(); arg = originalArgs
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function read(path)
    local f = assert(io.open(path)); local text = f:read("*a"); f:close(); return text
end
local names = {"DamageDone", "Dps", "HealingDone", "Hps", "Absorbs", "Interrupts", "Dispels", "DamageTaken", "AvoidableDamageTaken", "Deaths", "EnemyDamageTaken"}
for _, gamepad in ipairs({false, true}) do
    local e, s = harness(gamepad)
    for i, name in ipairs(names) do e.Enum.DamageMeterType[name] = i - 1 end
    e.C_DamageMeter = {IsDamageMeterAvailable = function() return s.available end}
    e.C_AddOns = {IsAddOnLoaded = function(name) return name == "Details" and s.details end,
        DoesAddOnExist = function(name) return name == "Blizzard_DamageMeter" end}
    e._FluxUI_CharSavedVars = {}
    e.FluxWindowFrame.GetFrame = function() return {Content = s.host} end
    e.FluxWindowFrame.SwitchToTab = function(_, name) s.activeTab = name end
    local counts = {generate = 0, open = 0, register = 0, dropdownPick = 0, pick = 0, writers = 0, cacheWrites = 0}
    local trusted = setmetatable({}, {__mode = "k"})
    local caches = setmetatable({}, {__mode = "k"})
    local choices = setmetatable({}, {__mode = "k"})
    local internals = setmetatable({}, {__mode = "k"})
    local descriptionSnapshots = {}
    local function trust(object, fields)
        local values = trusted[object] or {}; for _, field in ipairs(fields) do values[field] = true end
        trusted[object] = values; return object
    end
    e.issecurevariable = function(object, field)
        return trusted[object] and trusted[object][field] == true or false, "test-writer"
    end
    local nativeResponder = false
    local native, methodRefs = {}, {}
    local function after(method, ...)
        for _, fn in ipairs(s.hooks[s.dm] and s.hooks[s.dm][method] or {}) do fn(s.dm, ...) end
    end
    for _, method in ipairs({"SetSessionWindowDamageMeterType", "SetSessionWindowSessionID", "ShowNewSecondarySessionWindow"}) do
        native[method] = s.dm[method]
        s.dm[method] = function(self, ...)
            if not nativeResponder then counts.writers = counts.writers + 1; error("addon private native setter: " .. method) end
            return native[method](self, ...)
        end
        methodRefs[method] = s.dm[method]
    end
    local function nativeChoice(method, ...)
        nativeResponder = true
        local result = s.dm[method](s.dm, ...); after(method, ...)
        nativeResponder = false; return result
    end
    e.MenuInputContext = trust({MouseButton = 1}, {"MouseButton"})
    e.DAMAGE_METER_SHOW_NEW_WINDOW = "New Window"
    trust(e, {"DAMAGE_METER_SHOW_NEW_WINDOW"})
    e.MenuUtil = trust({GetElementText = function(description) return internals[description].label end}, {"GetElementText"})
    -- Blizzard's actual proxy classes are local tables used as metatables.
    -- No global MenuElementDescriptionProxyMixin is supplied by this fixture.
    local proxyMethods = {}
    proxyMethods.__index = proxyMethods
    function proxyMethods:EnumerateElementDescriptions() return ipairs(internals[self].children or {}) end
    function proxyMethods:GetData() return self.data end
    function proxyMethods:IsRadio() return internals[self].radio end
    function proxyMethods:IsEnabled() return true end
    function proxyMethods:GetDefaultResponse() return true end
    function proxyMethods:HasResponder() return self.responder ~= nil end
    function proxyMethods:CanSelect() local enabled = internals[self].enabled; return not enabled or enabled() end
    function proxyMethods:Pick(context, button)
        check(context == e.MenuInputContext.MouseButton and (button == "LeftButton" or button == "RightButton"),
            "original proxy Pick receives the native input context and button")
        check(trusted[self].data and trusted[self].responder, "only original trusted native data/responders reach Pick")
        if not self:CanSelect() then return false end
        counts.pick = counts.pick + 1; nativeResponder = true
        self.responder(self.data)
        nativeResponder = false; return true
    end
    proxyMethods.__newindex = function(t, key, value)
        if key == "data" or key == "responder" then counts.cacheWrites = counts.cacheWrites + 1; error("native description write") end
        rawset(t, key, value)
    end
    trust(proxyMethods, {"EnumerateElementDescriptions", "GetData", "IsRadio", "Pick", "CanSelect", "IsEnabled", "GetDefaultResponse", "HasResponder"})
    if menuSource then
        local text = read(menuSource):gsub("\r\n", "\n")
        local chunk = "local MenuElementDescriptionProxyMixin,Proxies=...\n"
        for _, method in ipairs({"CanSelect", "IsEnabled", "GetData", "HasResponder", "GetDefaultResponse"}) do
            local start = assert(text:find("\tfunction MenuElementDescriptionProxyMixin:" .. method .. "(", 1, true))
            local finish = assert(text:find("\n\tend", start, true)) + 4
            chunk = chunk .. text:sub(start, finish) .. "\n"
        end
        local start = assert(text:find("\tlocal function SecureCallResponder(", 1, true))
        local finish = assert(text:find("\nend\n\n--[[\nA single shared factory", start, true))
        chunk = chunk .. text:sub(start, finish - 1) .. "\nreturn SecureCallResponder"
        local private = {ToPrivate = function(_, proxy) return internals[proxy] end}
        local nativeCallback = assert(load(chunk, "@pinned original native menu Pick", "t", e))(proxyMethods, private)
        e.securecallfunction = function(fn, ...)
            local previous = nativeResponder
            if fn == nativeCallback then
                local description, _, context, button = ...
                check(context == e.MenuInputContext.MouseButton and (button == "LeftButton" or button == "RightButton"),
                    "pinned Pick supplies original input context and button")
                check(trusted[description].data and trusted[description].responder, "pinned Pick receives trusted native data/responder")
                counts.pick = counts.pick + 1; nativeResponder = true
            end
            local result = fn(...); nativeResponder = previous; return result
        end
    end
    local function description(label, data, responder, children, radio, enabled)
        local d = {data = data, responder = responder, canSelect = enabled}
        descriptionSnapshots[#descriptionSnapshots + 1] = {description = d, data = data, responder = responder,
            sessionType = type(data) == "table" and data.type or nil, sessionID = type(data) == "table" and data.sessionID or nil}
        internals[d] = {label = label, children = children, radio = radio, enabled = enabled, SendResponseToMenu = function() end}
        setmetatable(d, proxyMethods)
        return trust(d, {"data", "responder", "text", "isRadio", "isEnabled", "canSelect", "defaultResponse", "EnumerateElementDescriptions", "GetData", "IsRadio", "Pick", "CanSelect", "IsEnabled", "GetDefaultResponse", "HasResponder"})
    end
    local menus
    menus = function(window)
        choices[window] = {types = {}, sessions = {}}
        for _, kind in ipairs({"type", "session", "settings"}) do
            local categories = {}
            if kind == "type" then
                for _, category in ipairs({{"Damage", {0, 1, 7, 8, 10}}, {"Healing", {2, 3}}, {"Actions", {5, 6, 9}}}) do
                    local children = {}
                    for _, value in ipairs(category[2]) do
                        local d = description(names[value + 1], value, function(data)
                            s.dm:SetSessionWindowDamageMeterType(window, data); after("SetSessionWindowDamageMeterType", window, data)
                        end, nil, true)
                        choices[window].types[value] = d; children[#children + 1] = d
                    end
                    categories[#categories + 1] = description(category[1], nil, nil, children)
                end
            elseif kind == "session" then
                for _, option in ipairs({{sessionID = 42}, {type = e.Enum.DamageMeterSessionType.Current}, {type = e.Enum.DamageMeterSessionType.Overall}}) do
                    trust(option, {"type", "sessionID"})
                    local d = description("Session", option, function(data)
                        s.dm:SetSessionWindowSessionID(window, data.type, data.sessionID)
                    end, nil, true)
                    categories[#categories + 1] = d; choices[window].sessions[#choices[window].sessions + 1] = d
                end
            else
                categories[1] = description("New Window", nil, function()
                    s.dm:ShowNewSecondarySessionWindow(); menus(s.windows[#s.windows]); after("ShowNewSecondarySessionWindow")
                end, nil, false, function() return #s.windows < 3 end)
                choices[window].newWindow = categories[1]
            end
            local button = trust({}, {"menuDescription"})
            caches[button] = description("root", nil, nil, categories)
            setmetatable(button, {__index = function(_, key) if key == "menuDescription" then return caches[button] end end,
                __newindex = function(t, key, value)
                    if key == "menuDescription" then counts.cacheWrites = counts.cacheWrites + 1; error("native dropdown cache write") end
                    rawset(t, key, value)
                end})
            function button:GenerateMenu() counts.generate = counts.generate + 1; error("addon generated native menu") end
            function button:OpenMenu() counts.open = counts.open + 1; error("addon opened native dropdown") end
            function button:RegisterMenu() counts.register = counts.register + 1; error("addon registered native menu") end
            function button:Pick() counts.dropdownPick = counts.dropdownPick + 1; error("dropdown Pick rebuilds selection cache") end
            function button:GetMenuDescription() error("native dropdown accessor must not be invoked") end
            window[({type = "DamageMeterTypeDropdown", session = "SessionDropdown", settings = "SettingsDropdown"})[kind]] = button
        end
    end
    for _, window in ipairs(s.windows) do menus(window) end
    local create = e.CreateFrame
    function s.dm:CreateFontString() end
    e.CreateFrame = function(kind, name, parent)
        local f = create(kind, name, parent); f.parent = parent
        function f:EnableMouse() end
        function f:SetFrameLevel() end
        function f:SetBackdrop() end
        function f:SetBackdropColor() end
        function f:SetBackdropBorderColor() end
        function f:SetWidth(value) self.width = value end
        function f:SetHeight(value) self.height = value end
        function f:CreateTexture()
            return {SetAllPoints=function() end, SetColorTexture=function() end, SetAlpha=function() end,
                SetSize=function() end, SetPoint=function() end, SetTexture=function() end, SetTexCoord=function() end,
                Hide=function() end, Show=function() end}
        end
        function f:CreateFontString()
            return {SetPoint=function() end, SetTextColor=function() end, SetWordWrap=function() end, SetJustifyH=function() end,
                SetText=function(self, text) self.text = text end}
        end
        return f
    end
    assert(loadfile(layoutSource, "t", e))()
    local lib, meter = e.FluxMeterLayout, e.FluxBlizzardMeter
    lib.ApplyBuiltin(1); check(meter:Embed(s.host, lib.GetWorkingLayout()), "startup geometry embeds"); s.drain()
    check(counts.pick == 0 and s.typeCalls == 0 and s.sessionCalls == 0, "startup never applies native types or segment defaults")
    local groups = lib.GetPickerGroups("bottom", 1)
    local available = {}
    for _, group in ipairs(groups) do for _, item in ipairs(group.items or {}) do
        if item.nativeType ~= nil then available[item.nativeType] = true end
    end end
    for value = 0, 10 do check(available[value] == (value ~= 4 and true or nil), "cached catalog preserves type availability " .. value) end
    local layoutText = read(layoutSource)
    local first = assert(layoutText:find("    function f:RefreshPicker()", 1, true))
    local last = assert(layoutText:find("\n    function f:", first + 1, true))
    local refresh = assert(load("local f={}\n" .. layoutText:sub(first, last - 1) .. "\nreturn f.RefreshPicker", "@actual cached native picker", "t", e))()
    local child = e.CreateFrame("Frame")
    refresh({pickerChild = child, selectedRow = "bottom", selectedIndex = 1})
    local direct
    for _, row in ipairs(child._rows) do if row.label.text == "Dispels" then direct = row end end
    check(direct and direct.scripts.OnClick, "actual editor exposes direct Dispels action")
    direct.scripts.OnClick(direct, "LeftButton"); s.drain()
    check(s.windows[2].meterType == 6 and lib.GetWorkingLayout().bottomSlots[1].damageMeterType == 6,
        "actual editor changes the native window and matching layout label")
    check(not meter:GetLayoutStatus().configurationRequired and not meter:GetLayoutStatus().perFightSetupRequired,
        "type choice resolves covers and defaults both displayed windows to Current")
    lib.SaveWorkingOverActive()
    check(e._FluxUI_CharSavedVars.fluxWindowBlizzardMeterLayouts[1].bottomSlots[1].damageMeterType == 6, "existing Save persists direct native choice")
    for _, kind in ipairs({"type", "session", "settings"}) do
        local ok, reason = lib.OpenNativeMenu("bottom", 1, kind)
        check(not ok and type(reason) == "string", "native dropdown opening remains a physical native control: " .. kind)
    end
    local target = s.windows[2]
    for _, case in ipairs({{target.DamageMeterTypeDropdown, "menuDescription"}, {choices[target].types[5], "data"},
        {choices[target].types[5], "responder"}, {choices[target].types[5], "Pick"}, {proxyMethods, "Pick"},
        {choices[target].types[5], "GetData"}, {proxyMethods, "EnumerateElementDescriptions"}, {e.MenuInputContext, "MouseButton"}}) do
        trusted[case[1]][case[2]] = false
        local picks = counts.pick
        local ok, reason = meter:SelectNativeType("bottom", 1, 5)
        check(not ok and type(reason) == "string" and counts.pick == picks and target.meterType == 6,
            "tainted " .. case[2] .. " cannot select native configuration")
        trusted[case[1]][case[2]] = true
    end
    local cache = caches[target.DamageMeterTypeDropdown]; caches[target.DamageMeterTypeDropdown] = nil
    local picks = counts.pick
    check(not meter:SelectNativeType("bottom", 1, 5) and counts.pick == picks, "missing native cache is not regenerated")
    caches[target.DamageMeterTypeDropdown] = cache
    local security = e.issecurevariable; e.issecurevariable = nil
    check(not meter:SelectNativeType("bottom", 1, 5) and counts.pick == picks, "missing provenance API cannot dispatch")
    e.issecurevariable = security
    check(not meter:SelectNativeType("bottom", 1, 4) and counts.pick == picks, "unavailable Absorbs never dispatches or creates a window")
    nativeChoice("SetSessionWindowSessionID", s.windows[1], e.Enum.DamageMeterSessionType.Overall, nil)
    local currentData = choices[s.windows[1]].sessions[2].data
    for _, key in ipairs({"type", "sessionID"}) do
        trusted[currentData][key] = false
        picks = counts.pick
        check(not meter:ApplyCurrentSegments() and counts.pick == picks and s.windows[1].sessionType == 0,
            "tainted Current data field " .. key .. " cannot select a native segment")
        trusted[currentData][key] = true
    end
    check(meter:ApplyCurrentSegments(), "clean original Current metadata remains selectable after provenance failures")
    -- A tainted settings label must not misroute New Window to Reset's responder.
    lib.ApplyBuiltin(3); meter:Embed(s.host, lib.GetWorkingLayout()); s.drain()
    local settingsRoots, settingsChildren = {}, {}
    for _, window in ipairs(s.windows) do
        local root = caches[window.SettingsDropdown]
        settingsRoots[#settingsRoots + 1] = root; settingsChildren[root] = internals[root].children
    end
    local resets = 0
    local falseNewWindow = description("New Window", nil, function() resets = resets + 1 end)
    trusted[falseNewWindow].text = false
    for _, root in ipairs(settingsRoots) do internals[root].children = {falseNewWindow} end
    local windows = #s.windows
    check(not meter:ApplyRequestedTypes() and resets == 0 and #s.windows == windows,
        "tainted New Window label cannot select a relabelled Reset responder")
    for _, root in ipairs(settingsRoots) do internals[root].children = settingsChildren[root] end
    trusted[e].DAMAGE_METER_SHOW_NEW_WINDOW = false
    check(not meter:ApplyRequestedTypes() and resets == 0 and #s.windows == windows,
        "tainted native New Window text constant cannot authorize creation")
    trusted[e].DAMAGE_METER_SHOW_NEW_WINDOW = true
    lib.ApplyBuiltin(3); check(lib.CommitUserLayout(), "one preset creates and configures the third native window"); s.drain()
    check(#s.windows == 3 and not meter:GetLayoutStatus().configurationRequired, "new native window resolves requested types without manual setup")
    local threatFrame = e.CreateFrame("Frame", nil, s.host)
    e.FluxThreatMeter = {IsAvailable = function() return true end, GetFrame = function() return threatFrame end,
        Embed = function() return threatFrame end, RefreshLayout = function() end,
        Show = function() threatFrame:Show() end, Hide = function() threatFrame:Hide() end, Cleanup = function() threatFrame:Hide() end}
    for id = 1, lib.GetBuiltinCount() do
        for i, window in ipairs(s.windows) do
            window.sessionType = i == 3 and e.Enum.DamageMeterSessionType.Current or e.Enum.DamageMeterSessionType.Overall
            window.sessionID = i > 1 and 42 or nil
        end
        lib.ApplyBuiltin(id)
        local before = s.sessionCalls
        check(lib.CommitUserLayout(), "production preset applies requested types: " .. id); s.drain()
        local status = meter:GetLayoutStatus()
        check(not status.configurationRequired and not status.perFightSetupRequired, "every preset has matching types and Current: " .. id)
        check(s.sessionCalls == before + status.visibleNativePanes, "every displayed pane receives canonical Current: " .. id)
        for _, pane in ipairs(status.sessionChoices) do check(pane.selection == "Current", "Current entry replaces historical selection") end
        for _, window in ipairs(s.windows) do if window:IsShown() then check(window.sessionID == nil, "canonical Current clears historical ID") end end
    end
    check(#s.windows == 3 and threatFrame ~= s.windows[1] and threatFrame ~= s.windows[2] and threatFrame ~= s.windows[3],
        "ten presets retain three native windows and independent owned Threat")
    lib.ApplyBuiltin(1); check(lib.CommitUserLayout(), "prepare two-pane layout")
    nativeChoice("SetSessionWindowSessionID", s.windows[1], e.Enum.DamageMeterSessionType.Overall, nil)
    local sessions, types = s.sessionCalls, s.typeCalls
    for _ = 1, 50 do meter:RefreshEmbeddedLayout() end
    meter:Hide(); meter:Show(); s.drain()
    check(s.sessionCalls == sessions and s.typeCalls == types and s.windows[1].sessionType == 0,
        "geometry and ordinary show preserve later manual Overall selection")
    check(lib.CommitUserLayout() and s.sessionCalls == sessions + 1 and s.windows[1].sessionType == 1,
        "reselecting same layout defaults the overridden pane to Current")
    sessions = s.sessionCalls
    check(lib.CommitUserLayout() and s.sessionCalls == sessions, "already-Current panes skip redundant selection")
    local windowText = read("Battlezonemap/FluxWindowFrame.lua")
    first = assert(windowText:find("local function GetMeterPresetCount()", 1, true))
    last = assert(windowText:find("\n--- Save tab state", first, true))
    local setterStart = assert(windowText:find("function FluxWindowFrame:SetMeterPresetIndex(", 1, true))
    local setterEnd = assert(windowText:find("\nend", setterStart, true)) + 4
    local clickStart = assert(windowText:find('    tab.button:SetScript("OnClick", function(self, button)', 1, true))
    local clickEnd = assert(windowText:find("\n    -- Mouseover effects", clickStart, true))
    local prefix = [[
local activeTab="Meter"
local name="Meter"
local click
local tab={button={SetScript=function(_,_,fn)click=fn end}}
local ResolveMeterSystem=function()return FluxMeterLayout.GetMeterBackend()=="Blizzard" and "BlizzardMeter" or "Details" end
]]
    local route = prefix .. windowText:sub(first, last - 1) .. "\n" .. windowText:sub(setterStart, setterEnd)
        .. "\n" .. windowText:sub(clickStart, clickEnd - 1) .. "\nreturn click,function(value)activeTab=value end"
    local click, setActive = assert(load(route, "@actual native tab routes", "t", e))()
    lib.ApplyBuiltin(5); check(lib.CommitUserLayout(), "prepare HPS before cycle")
    click({}, "LeftButton"); s.drain()
    local status = meter:GetLayoutStatus()
    check(lib.GetActiveLayoutId() == "builtin:6" and not status.configurationRequired and not status.perFightSetupRequired
        and status.sessionChoices[1].damageMeterType == 7, "actual tab cycle changes HPS to Damage Taken immediately")
    e.FluxWindowFrame:SetMeterPresetIndex(8, true); s.drain()
    check(lib.GetActiveLayoutId() == "builtin:8" and not meter:GetLayoutStatus().configurationRequired, "actual setter applies Dispels without setup cover")
    picks = counts.pick; e.FluxWindowFrame:SetMeterPresetIndex(10, false)
    check(counts.pick == picks, "planning-only setter does not select native configuration")
    s.activeTab = "Map"; setActive("Map"); meter:Hide()
    click({}, "LeftButton"); s.drain()
    check(s.activeTab == "Meter" and not meter:GetLayoutStatus().configurationRequired, "inactive tab entry applies its current layout")
    s.activeTab = "Map"; meter:Hide(); lib.ApplyBuiltin(6)
    check(lib.CommitUserLayout() and s.activeTab == "Meter" and meter:GetLayoutStatus().sessionChoices[1].damageMeterType == 7,
        "options on Map switch to Meter before applying latest request")
    s.combat = true; picks = counts.pick; sessions = s.sessionCalls
    click({}, "LeftButton")
    check(not meter:ApplyRequestedTypes() and not meter:ApplyCurrentSegments() and counts.pick == picks and s.sessionCalls == sessions,
        "tab, type and segment application stay blocked in combat")
    s.combat = false
    meter:Cleanup(); e.DamageMeter = nil; s.activeTab = "Map"
    lib.ApplyBuiltin(5); check(lib.CommitUserLayout(), "explicit choice queues while native UI unavailable")
    lib.ApplyBuiltin(6); picks = counts.pick
    check(lib.CommitUserLayout() and counts.pick == picks, "latest delayed choice wins without premature selection")
    for i, window in ipairs(s.windows) do window.meterType = ({0, 2, 3})[i]; window.sessionType = 0; window.sessionID = nil end
    e.DamageMeter = s.dm; meter:Embed(s.host, lib.GetWorkingLayout()); s.drain()
    status = meter:GetLayoutStatus()
    check(not status.configurationRequired and not status.perFightSetupRequired and status.sessionChoices[1].damageMeterType == 7,
        "existing readiness retry consumes latest explicit type and Current request")
    s.windows[1].sessionType = 0; sessions = s.sessionCalls
    meter:Embed(s.host, lib.GetWorkingLayout()); s.drain()
    check(s.sessionCalls == sessions and s.windows[1].sessionType == 0, "delayed intent consumes once; later embed preserves manual segment")
    for _, cancel in ipairs({"Hide", "Cleanup"}) do
        e.DamageMeter = nil; lib.ApplyBuiltin(6); lib.CommitUserLayout(); meter[cancel](meter)
        e.DamageMeter = s.dm
        for i, window in ipairs(s.windows) do window.meterType = ({0, 2, 3})[i] end
        picks = counts.pick; meter:Embed(s.host, lib.GetWorkingLayout()); s.drain()
        check(counts.pick == picks and meter:GetLayoutStatus().configurationRequired, cancel .. " cancels stale delayed selection")
    end
    check(lib.CommitUserLayout(), "restore explicit layout after cancellation")
    local quiet, commits, preset = 0, 0, 11
    local de = setmetatable({FluxWindowFrame = {}}, {__index = e})
    de.FluxMeterLayout = {GetMeterBackend = function() return "Details" end, GetBuiltinCount = function() return 11 end,
        GetActiveLayoutId = function() return "builtin:" .. preset end, ApplyBuiltin = function(id) preset = id end,
        ReembedQuiet = function() quiet = quiet + 1 end, CommitUserLayout = function() commits = commits + 1 end}
    local detailsClick = assert(load(route, "@actual Details routes", "t", de))()
    detailsClick({}, "LeftButton")
    check(preset == 1 and quiet == 1 and commits == 0, "Details cycle keeps quiet re-embed and eleven-preset wrap")
    de.FluxWindowFrame:SetMeterPresetIndex(3, true)
    check(preset == 3 and quiet == 2 and commits == 0, "Details setter keeps original re-embed route")
    s.details = true; e.Details = {}; picks = counts.pick
    check(not meter:ApplyRequestedTypes() and not meter:ApplyCurrentSegments() and counts.pick == picks, "Details takeover retires native selection")
    s.details = false; e.Details = nil; meter:Cleanup()
    check(not meter:ApplyRequestedTypes() and not meter:ApplyCurrentSegments(), "cleanup retires stale native selection")
    for name, fn in pairs(methodRefs) do check(s.dm[name] == fn, "native method identity remains unchanged: " .. name) end
    local unchanged = true
    for _, snapshot in ipairs(descriptionSnapshots) do
        local data = snapshot.data
        unchanged = unchanged and snapshot.description.data == data and snapshot.description.responder == snapshot.responder
        if type(data) == "table" then unchanged = unchanged and data.type == snapshot.sessionType and data.sessionID == snapshot.sessionID end
    end
    check(unchanged, "all original native descriptions, responder identities and session metadata remain unchanged")
    check(counts.generate == 0 and counts.open == 0 and counts.register == 0 and counts.dropdownPick == 0
        and counts.writers == 0 and counts.cacheWrites == 0, "all routes avoid native cache writes/generation/opening and private setters")
end
print("native_meter_controls: " .. checks .. " checks passed; pinned Pick=" .. tostring(menuSource ~= nil) .. "; native taint/controller/pixels pending")
