-- Exact production collector replay; native discovery/cadence/FPS are not simulated.
local sourcePath = arg[1] or "MicroMenu/FluxAddonMicroButton.lua"
local expectBaseline = arg[2] == "--baseline"
local checks, failures = 0, 0
local unpack = table.unpack or unpack
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local function read(path)
    local file = assert(io.open(path, "rb")); local text = file:read("*a"); file:close(); return text
end
local source = read(sourcePath)
local function boot()
    local s = { frames = {}, timers = {}, errors = 0, patterns = 0, names = 0, enumerations = 0, callbacks = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.string = setmetatable({ match = function(...)
        s.patterns = s.patterns + 1; return string.match(...)
    end }, { __index = string })
    env.geterrorhandler = function() return function() s.errors = s.errors + 1 end end
    env.C_Timer = { After = function(delay, fn) s.timers[#s.timers + 1] = { delay = delay, fn = fn } end }
    local methods = {}
    function methods:IsObjectType() return true end
    function methods:IsForbidden() return self.forbidden == true end
    function methods:GetName() s.names = s.names + 1; if self.nameThrows then error("temporary name failure") end; return self.name end
    function methods:GetParent() return self.parent end
    function methods:SetParent(parent)
        if self.parent then
            for i, child in ipairs(self.parent.children) do
                if child == self then table.remove(self.parent.children, i); break end
            end
        end
        self.parent = parent
        if parent then parent.children[#parent.children + 1] = self end
        if self.onParent then self.onParent(self) end
    end
    function methods:GetChildren()
        s.enumerations = s.enumerations + 1
        if self.enumerationThrows then error("temporary enumeration failure") end
        return unpack(self.children)
    end
    function methods:SetScript(event, callback) self.scripts[event] = callback end
    function methods:HookScript(event, callback) self.hooks[event] = callback end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:IsShown() return self.shown end
    function methods:SetSize(w, h) self.width, self.height = w, h end
    function methods:GetWidth() return self.width or 32 end
    function methods:GetHeight() return self.height or 32 end
    function methods:GetFrameLevel() return self.level or 1 end
    function methods:SetFrameLevel(v) self.level = v end
    function methods:SetFrameStrata(v) self.strata = v end
    function methods:ClearAllPoints() self.point = nil end
    function methods:SetPoint(...) self.point = { ... } end
    function methods:SetScale(v) self.scale = v end
    for _, key in ipairs({ "SetAllPoints", "EnableMouse", "SetFixedFrameStrata", "SetFixedFrameLevel", "SetMovable",
        "SetAlpha", "SetIgnoreParentScale", "RegisterForClicks", "SetTexture", "SetTexCoord", "SetVertexColor" }) do
        methods[key] = function() end
    end
    function s.frame(name, parent)
        local frame = setmetatable({ name = name, children = {}, scripts = {}, hooks = {}, events = {}, shown = true }, { __index = methods })
        s.frames[#s.frames + 1] = frame
        if parent then frame:SetParent(parent) end
        return frame
    end
    env.CreateFrame = function(_, name, parent) return s.frame(name, parent) end
    env.UIParent = s.frame("UIParent")
    env.Minimap = s.frame("Minimap")
    env.MinimapCluster = s.frame("MinimapCluster")
    env.MinimapCluster.MinimapContainer = env.Minimap
    env.MinimapCluster.Minimap = env.Minimap
    env.MinimapBackdrop = env.Minimap
    env.FluxMicroMenu = {
        CreateMicroButton = function()
            local button = s.frame("FluxAddonMicroButton"); button.icon = s.frame("icon"); return button
        end,
    }
    local file
    if setfenv then file = assert(loadstring(source, "@" .. sourcePath)); setfenv(file, env)
    else file = assert(load(source, "@" .. sourcePath, "t", env)) end
    file()
    s.env, s.system = env, env.FluxAddonSystem
    function s:event(event)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event) end
        end
    end
    return s
end

do
    local s = boot(); local e = s.env
    local oldRoot, nextRoot = s.frame("OldBackdrop"), s.frame("NewBackdrop")
    local oldButton = s.frame("OldMinimapButton", oldRoot)
    local nextButton = s.frame("NewMinimapButton", nextRoot)
    e.MinimapBackdrop = oldRoot
    local first = s.frame("RebindMinimapButton", e.Minimap)
    first.onParent = function() e.MinimapBackdrop = nextRoot end
    s.system:Scan()
    check(s.system.buttonMap[oldButton] and not s.system.buttonMap[nextButton], "root snapshot survives reentrant global backdrop replacement")
    s.system:Scan()
    check(s.system.buttonMap[nextButton], "next scan observes a rebound backdrop")
end

do
    local s = boot(); local e = s.env
    local container = s.frame("MinimapContainer"); local inner = s.frame("InnerMinimap"); local other = s.frame("ClusterMap")
    e.MinimapCluster.MinimapContainer, container.Minimap, e.MinimapCluster.Minimap, e.MinimapBackdrop = container, inner, other, inner
    local roots = s.system.GetMinimapScanRoots()
    check(#roots == 5 and roots[1] == e.Minimap and roots[2] == e.MinimapCluster and roots[3] == container
        and roots[4] == inner and roots[5] == other, "root order and aliases preserved")
    roots[1] = false
    check(s.system.GetMinimapScanRoots()[1] == e.Minimap, "public root snapshots remain independent")
    for _, root in ipairs(s.system.GetMinimapScanRoots()) do s.frame("LibDBIcon10_" .. root.name, root) end
    s.system:Scan()
    check(#s.system.collectedButtons == 5, "every unique current root discovers new buttons")
    local added = s.frame("LateMinimapButton", e.Minimap)
    s.system:Scan()
    check(s.system.buttonMap[added] and #s.system.collectedButtons == 6, "later child is discovered next scan")
    s.system:Scan()
    check(#s.system.collectedButtons == 6, "collected identities do not duplicate")
    local replacement = s.frame("Replacement"); local custom = s.frame("CustomMinimapButton", replacement)
    s.system.GetMinimapScanRoots = function() return { replacement } end
    s.system:Scan()
    check(s.system.buttonMap[custom], "replaced public root provider is honored")
    local fallback = s.frame("FallbackMinimapButton", e.Minimap)
    s.system.GetMinimapScanRoots = nil; s.system:Scan()
    check(s.system.buttonMap[fallback], "missing provider retains original Minimap fallback")
end

do
    local s = boot(); local e = s.env
    local exclude = { "Minimap", "MinimapCluster", "MinimapBackdrop", "MinimapContainer", "LFG_MinimapEye",
        "QueueStatusMinimapButton", "MiniMapTracking", "MiniMapTrackingButton", "MiniMapVoiceChatFrame",
        "TimeManagerClockButton", "GameTimeFrame", "GarrisonLandingPageMinimapButton", "ExpansionLandingPageMinimapButton",
        "MiniMapMailFrame", "MiniMapBattlefieldFrame", "FeedbackUIButton", "HelpOpenTicketButton", "COHCMinimapButton",
        "MinimapZoomIn", "MinimapZoomOut", "LFGCustomMinimapButton" }
    for _, name in ipairs(exclude) do check(not s.system.NameLooksLikeMinimapButton(name), "excluded " .. name) end
    for _, name in ipairs({ "LibDBIcon10_X", "ThingMinimapButton", "ThingMinimapFrame", "ThingMinimapIcon", "X-Minimap-Y",
        "X_Minimap_Y", "ThingMinimap", "TomCats-Z" }) do
        check(s.system.NameLooksLikeMinimapButton(name), "original pattern accepted " .. name)
    end
    for _, name in ipairs({ "native", "", false, 17 }) do check(not s.system.NameLooksLikeMinimapButton(name), "invalid/nonmatching name rejected") end
    local forbidden = s.frame("ForbiddenMinimapButton", e.Minimap); forbidden.forbidden = true
    s.system:Scan(); check(not s.system.buttonMap[forbidden], "forbidden frames are untouched")
    local children = {}
    for i = 1, 30 do
        local button = s.frame("Burst" .. i .. "MinimapButton", e.Minimap)
        button.onParent = function() s.system:Scan() end
        children[i] = button
    end
    s.system:Scan()
    for _, button in ipairs(children) do check(s.system.buttonMap[button], "enumeration snapshot survives sibling reparenting") end
    check(#s.system.collectedButtons == 30 and not s.system._scanInProgress, "recursive collection keeps exactly one pass and releases lock")
end

do
    local s = boot(); local e = s.env
    e.Minimap.enumerationThrows = true
    local good = s.frame("ClusterMinimapButton", e.MinimapCluster)
    s.system:Scan()
    check(s.system.buttonMap[good] and s.errors == 0, "failed root enumeration skips only that root")
    e.Minimap.enumerationThrows = nil
    local bad = s.frame("NameMinimapButton", e.Minimap); bad.nameThrows = true
    local late = s.frame("NextMinimapButton", e.Minimap)
    s.system:Scan()
    check(s.system.buttonMap[late] and s.errors == 0, "individual name failure preserves later children")
    bad.nameThrows = nil; s.system:Scan()
    check(s.system.buttonMap[bad] and not s.system._scanInProgress, "failed name retries on the next scan")
    local libraries, callbacks = {}, {}
    e.LibStub = { GetLibrary = function(_, key) return libraries[key] end }
    local dbButton, mapButton = s.frame("LibDBButton"), s.frame("LibMapButton")
    libraries["LibDBIcon-1.0"] = {
        GetButtonList = function() return { "one" } end, GetMinimapButton = function() return dbButton end,
        RegisterCallback = function(owner, key, callback) callbacks[#callbacks + 1] = callback; check(owner == "FluxUI" and key == "LibDBIcon_IconCreated", "original callback identity") end,
    }
    libraries["LibMapButton-1.1"] = { buttons = { x = mapButton } }
    s.system:Scan(); s.system:Scan()
    check(s.system.buttonMap[dbButton] and s.system.buttonMap[mapButton] and #callbacks == 1, "late libraries collect identities and register once")
    local newButton = s.frame("NewDBButton"); callbacks[1](nil, newButton)
    check(s.system.buttonMap[newButton], "library creation callback remains immediate")
    local lib = libraries["LibDBIcon-1.0"]
    lib.GetButtonList = function() error("temporary library failure") end
    s.system:Scan()
    check(s.errors == 1 and not s.system._scanInProgress, "unexpected scan errors still report and release lock")
    lib.GetButtonList = function() return {} end; s.system:Scan()
    check(s.errors == 1 and not s.system._scanInProgress, "scan resumes after a transient library error")
end

do
    local s = boot(); local e = s.env
    s:event("PLAYER_LOGIN")
    check(#s.timers == 1 and s.timers[1].delay == 10, "login begins original ten-second scan chain")
    local first = table.remove(s.timers, 1); first.fn()
    check(#s.timers == 1 and s.timers[1].delay == 10, "periodic scan rearms at unchanged ten-second delay")
    s:event("PLAYER_ENTERING_WORLD")
    check(#s.timers == 1, "world entry adds an immediate scan without another periodic chain")
    for i = 1, 100 do
        s.frame(i % 2 == 0 and "MinimapZoomIn" or "NativeDecoration" .. i, e.Minimap)
        s.frame(i % 2 == 0 and "MinimapZoomIn" or "NativeDecoration" .. i, e.MinimapCluster)
    end
    s.names, s.patterns, s.enumerations = 0, 0, 0
    collectgarbage("collect"); collectgarbage("stop"); local before = collectgarbage("count")
    for _ = 1, 360 do s.system:Scan() end
    local heap = collectgarbage("count") - before; collectgarbage("restart")
    check(s.names == 72000 and s.enumerations == 720, "settled scans retain every root and child read")
    check(s.errors == 0 and #s.system.collectedButtons == 0, "settled scans keep discovery results")
    if not expectBaseline then
        check(s.patterns == 252000, "settled scan pattern budget")
        check(heap < 1250, "settled scans avoid root tables and callback captures while retaining linear child snapshots")
    end
    print(("SAMPLE scans=360 names=%d enumerations=%d patternMatches=%d uncollectedHeapKB=%.3f"):format(s.names, s.enumerations, s.patterns, heap))
    local protected = {}
    e.pcall = function(fn, ...) protected[fn] = true; return pcall(fn, ...) end
    for _ = 1, 360 do s.system:Scan() end
    local identities = 0
    for _ in pairs(protected) do identities = identities + 1 end
    if not expectBaseline then check(identities == 5, "settled scan protected callbacks use constant identities") end
    print(("IDENTITIES protectedFunctions=%d"):format(identities))
end
print(("passive world pass2: %d checks, %d failures"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
