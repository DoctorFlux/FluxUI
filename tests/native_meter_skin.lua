-- Production visual helpers with explicit widget mocks, not the native secret VM.
local source = arg[1] or "Battlezonemap/FluxMeterSkin.lua"
local checks, failures = 0, 0
local function check(value, message)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. message) end
end
local function forbidden() error("meter data/native ownership was accessed", 2) end

local function boot(withTheme)
    local h = { fonts = 0, textures = 0, hooks = 0, bars = 0, colors = 0,
        theme = { .2, .6, .8 }, callbacks = {}, frameCreates = 0, wrapSets = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    env.UnitClass = function(unit) assert(unit == "player"); return "Mage", "MAGE" end
    env.RAID_CLASS_COLORS = { MAGE = { r = .25, g = .5, b = .75 } }
    env.issecretvalue = function(value) return type(value) == "table" and rawget(value, "opaque") == true end
    env.CreateFrame = function() h.frameCreates = h.frameCreates + 1; forbidden() end
    env.C_Timer = { After = forbidden, NewTimer = forbidden, NewTicker = forbidden }
    if withTheme then
        env.FluxBorder = { GetThemedVertexRGB = function() return table.unpack(h.theme) end,
            RefreshAppearanceDependents = function() end }
    end
    env.hooksecurefunc = function(object, method, callback)
        assert(object == env.FluxBorder and method == "RefreshAppearanceDependents")
        h.hooks = h.hooks + 1; h.callbacks[#h.callbacks + 1] = callback
    end
    function h.font()
        local fs = { color = { .1, .9, .1, 1 }, text = "Mario Super", calls = 0, wordWrap = true, nonSpaceWrap = true }
        function fs:SetFont(path, size, flags)
            h.fonts = h.fonts + 1; self.calls = self.calls + 1
            if self.rejectArial and path == "Fonts\\ARIALN.TTF" then return false end
            self.path, self.size, self.flags = path, size, flags; return true
        end
        function fs:GetFont() return self.path, self.size, self.flags end
        function fs:CanWordWrap() return self.wordWrap end
        function fs:CanNonSpaceWrap() return self.nonSpaceWrap end
        function fs:SetWordWrap(value) self.wordWrap = value; h.wrapSets = h.wrapSets + 1 end
        function fs:SetNonSpaceWrap(value) self.nonSpaceWrap = value; h.wrapSets = h.wrapSets + 1 end
        function fs:SetShadowColor(...) self.shadow = { ... } end
        function fs:SetShadowOffset(...) self.offset = { ... } end
        function fs:SetTextColor(...) self.color = { ... } end
        fs.GetText, fs.GetFormattedText, fs.SetText = forbidden, forbidden, forbidden
        function fs:SetPoint(...) self.point = { ... } end
        return fs
    end
    function h.texture()
        h.textures = h.textures + 1
        local t = { shown = true, tintCalls = 0, points = {} }
        function t:SetTexture(path) self.path = path end
        function t:SetPoint(...) self.points[#self.points + 1] = { ... } end
        function t:SetWidth(width) self.width = width end
        function t:SetHeight(height) self.height = height end
        function t:SetAllPoints(parent) self.allPoints = parent end
        function t:SetVertexColor(...)
            h.colors = h.colors + 1; self.tintCalls = self.tintCalls + 1; self.tint = { ... }
        end
        function t:SetColorTexture(...) self.fill = { ... } end
        function t:SetAlpha(alpha) self.alpha = alpha end
        function t:Show() self.shown = true end
        function t:Hide() self.shown = false end
        t.GetTexture, t.GetAtlas, t.GetVertexColor = forbidden, forbidden, forbidden
        return t
    end
    function h.entry()
        local name, value, background, edge = h.font(), h.font(), h.texture(), h.texture()
        local bar = { SetValue = forbidden, SetMinMaxValues = forbidden, GetValue = forbidden }
        function bar:SetStatusBarTexture(path) h.bars = h.bars + 1; self.texture = path end
        local entry = { GetName = function() return name end, GetValue = function() return value end,
            GetStatusBar = function() return bar end, GetBackground = function() return background end,
            GetBackgroundEdge = function() return edge end, UpdateName = forbidden, UpdateValue = forbidden,
            UpdateStatusBar = forbidden, Init = forbidden, SetBarHeight = forbidden,
            GetNameText = forbidden, GetValueText = forbidden, GetStatusValue = forbidden,
            GetIcon = forbidden, HookScript = forbidden, SetScript = forbidden }
        setmetatable(entry, { __newindex = forbidden, __index = function(_, key)
            error("unexpected native entry field: " .. tostring(key), 2)
        end })
        return entry, name, value, bar, background, edge
    end
    function h.window(kind)
        local w = { geometry = "native", type = "native", session = "native", children = {} }
        function w:CreateTexture() local t = h.texture(); self.children[#self.children + 1] = t; return t end
        w.SetPoint, w.SetSize, w.SetScale, w.SetBarHeight = forbidden, forbidden, forbidden, forbidden
        w.SetVisibility, w.SetSession, w.Refresh, w.Show, w.Hide = forbidden, forbidden, forbidden, forbidden, forbidden
        w.HookScript, w.SetScript, w.RegisterEvent = forbidden, forbidden, forbidden
        w.GetCombatSession, w.GetSessionType, w.GetDamageMeterType = forbidden, forbidden, forbidden
        if kind == "session" then
            w.Header = h.texture()
            w.typeFont, w.sessionFont, w.timerFont = h.font(), h.font(), h.font()
            w.GetDamageMeterTypeName = function() return w.typeFont end
            w.GetSessionName = function() return w.sessionFont end
            w.GetSessionTimerFontString = function() return w.timerFont end
            w.MinimizeContainer = { NotActive = h.font(), Background = h.texture() }
            w.GetBackground = function() return w.MinimizeContainer.Background end
        else
            w.Background = h.texture()
            w.GetBackground = function() return w.Background end
        end
        return w
    end
    assert(loadfile(source, "t", env))()
    h.env, h.skin = env, env.FluxMeterSkin
    return h
end

local h = boot(true)
local skin = h.skin
check(h.frameCreates == 0 and h.hooks == 0 and h.textures == 0, "module load adds no frame or idle work")
local entry, name, value, bar, background, edge = h.entry()
local init, update, updateValue, updateBar = entry.Init, entry.UpdateName, entry.UpdateValue, entry.UpdateStatusBar
skin:ApplyToEntry(entry, .8)
check(name.path == "Fonts\\ARIALN.TTF" and name.size == 17.5 and name.flags == "OUTLINE", "native row font compensates root scale")
check(value.size == 17.5 and value.flags == "OUTLINE", "native value font matches row")
check(name.color[1] == .1 and name.color[2] == .9, "skin preserves integration's local-player name tint")
check(value.color[1] == 1 and value.color[2] == 1 and value.color[3] == 1, "value text is white")
check(name.shadow[4] == 1 and name.offset[1] == 1 and name.offset[2] == -1, "font outline has the shared readable shadow")
check(bar.texture == "Interface\\TargetingFrame\\UI-StatusBar", "bar uses Blizzard status-bar texture")
check(background.fill[1] == .619607 and background.fill[4] == .116164 and background.alpha == 1 and edge.alpha == 0,
    "row background shares the existing FluxDetails fill without multiplying native alpha")
check(not name.wordWrap and not name.nonSpaceWrap and name.text == "Mario Super",
    "multiword names stay on one line without inspecting or changing native text")
check(entry.Init == init and entry.UpdateName == update and entry.UpdateValue == updateValue
    and entry.UpdateStatusBar == updateBar, "entry methods remain native")
local fontCalls, textures, wrapSets = h.fonts, h.textures, h.wrapSets
for _ = 1, 500 do skin:ApplyToEntry(entry, .8) end
check(h.fonts == fontCalls and h.textures == textures and h.frameCreates == 0 and h.hooks == 0,
    "500 entry repaints reuse fonts and add no resources or callbacks")
check(h.wrapSets == wrapSets, "500 stable entry restyles issue no repeated wrap setters")
name.wordWrap, name.nonSpaceWrap = true, true
skin:ApplyToEntry(entry, .8)
check(not name.wordWrap and not name.nonSpaceWrap and h.wrapSets == wrapSets + 2,
    "pooled native name wrap resets are repaired without reading its contents")
name:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
skin:ApplyToEntry(entry, .8)
check(name.path == "Fonts\\ARIALN.TTF" and name.size == 17.5 and name.flags == "OUTLINE",
    "native row font reset is repaired on pooled entry reuse")
fontCalls = h.fonts
skin:ApplyToEntry(entry, 1)
check(name.size == 14 and value.size == 14 and h.fonts == fontCalls + 2, "font size follows a changed public root scale")

local session = h.window("session")
local refresh = session.Refresh
skin:ApplyToWindow(session, .8)
check(#session.children == 4 and h.hooks == 1, "native chrome creates four rails and one shared theme hook")
check(session.children[1].height == 2.5 and session.children[3].width == 2.5, "chrome width compensates root scale")
check(session.Header.path == "Interface\\TargetingFrame\\UI-StatusBar"
    and math.abs(session.Header.tint[1] - .08) < .00001, "native header uses Flux theme and Blizzard texture")
check(session.typeFont.size == 15 and session.sessionFont.size == 15 and session.timerFont.size == 15,
    "native title/session/timer fonts compensate root scale")
check(session.typeFont.path == "Fonts\\FRIZQT__.TTF" and session.sessionFont.path == session.typeFont.path,
    "native titles use the same stock Friz Quadrata font as FluxDetails")
check(session.typeFont.color[1] == 1 and session.typeFont.color[2] == .82 and session.timerFont.color[3] == 0,
    "native header and timer keep the shared gold title color")
check(session.typeFont.text == "Mario Super" and session.timerFont.text == "Mario Super",
    "native title and timer contents remain untouched")
local panel = session.MinimizeContainer.Background
check(panel.fill[1] == .0941 and panel.fill[2] == .0941 and panel.fill[3] == .0941 and panel.fill[4] == .70 and panel.alpha == 1,
    "actual nested native background receives the common panel fill")
panel:SetAlpha(.35)
skin:ApplyToWindow(session, .8)
check(panel.alpha == 1, "native background alpha reset is normalized on style reapplication")
check(session.Refresh == refresh and session.geometry == "native" and session.type == "native"
    and session.session == "native", "native layout, configuration and refresh stay unchanged")
local stableTextures, stableFonts, stableColors = h.textures, h.fonts, h.colors
for _ = 1, 500 do skin:ApplyToWindow(session, .8) end
check(h.textures == stableTextures and h.fonts == stableFonts and h.colors == stableColors and h.hooks == 1,
    "500 repeated native styles reuse chrome, fonts and theme colors")
session.typeFont:SetFont("Fonts\\ARIALN.TTF", 10, "")
skin:ApplyToWindow(session, .8)
check(session.typeFont.path == "Fonts\\FRIZQT__.TTF" and session.typeFont.size == 15,
    "native window font reset is repaired on reapplication")

local sourceWindow = h.window("source")
skin:ApplyToWindow(sourceWindow, .8)
check(#sourceWindow.children == 4 and sourceWindow.Background.fill[4] == .70 and sourceWindow.Background.alpha == 1,
    "source-window shape skins without a fabricated header")
check(sourceWindow.GetSessionTimerFontString == nil and sourceWindow.Refresh == forbidden,
    "source methods and missing native regions remain unchanged")
h.theme = { .8, .3, .1 }; h.callbacks[1]()
check(session.children[1].tint[1] == .8 and sourceWindow.children[1].tint[2] == .3,
    "existing appearance service recolors session and source rails")
check(math.abs(session.Header.tint[3] - .04) < .00001, "header follows a later accent")
session.Header = h.texture()
skin:ApplyToWindow(session, .8)
check(session.Header.path == "Interface\\TargetingFrame\\UI-StatusBar" and math.abs(session.Header.tint[1] - .32) < .00001,
    "a replaced native header receives the current accent")
local oldColors = h.colors
skin:ReleaseWindow(session)
check(not session.children[1].shown and not session.children[4].shown, "release hides addon-owned rails")
h.theme = { .4, .5, .6 }; h.callbacks[1]()
check(session.children[1].tint[1] == .8 and sourceWindow.children[1].tint[1] == .4,
    "released native window does no hidden accent work")
check(h.colors > oldColors, "other active native windows still refresh")
local beforeReuse = h.textures
skin:ApplyToWindow(session, .8)
check(h.textures == beforeReuse and session.children[1].shown and session.children[1].tint[1] == .4,
    "native re-embed reuses existing chrome")
skin:ReleaseAllNative(); oldColors = h.colors
h.theme = { .9, .8, .7 }; h.callbacks[1]()
check(h.colors == oldColors, "empty native registry makes permanent appearance hook idle")

local owned = h.window("source")
owned.Title = h.font(); function owned.Title:SetText(text) self.text = text end
owned.Header = { CreateTexture = function() return h.texture() end }
skin:ApplyToOwnedPane(owned, "Threat", .8)
check(owned.Title.text == "Threat" and owned.Title.size == 15 and owned.HeaderTitle == nil,
    "owned threat pane reuses its existing title")
check(owned.Title.color[1] == 1 and owned.Title.color[2] == .82 and owned.Title.color[3] == 0,
    "owned title matches the shared gold header")
check(owned.Title.path == session.typeFont.path and owned.Background.fill[1] == panel.fill[1]
    and owned.Background.fill[4] == panel.fill[4] and owned.Background.alpha == panel.alpha,
    "owned and native panes share the actual title font and panel fill")
local ownedTextures = h.textures
for _ = 1, 500 do skin:ApplyToOwnedPane(owned, "Threat", .8) end
check(h.textures == ownedTextures and h.hooks == 1, "owned pane styling does not duplicate headers or hooks")
h.theme = { .1, .2, .3 }; h.callbacks[1]()
check(owned.children[1].tint[1] == .1, "owned pane shares live accent refresh")
skin:ReleaseWindow(owned); oldColors = h.colors
h.theme = { .3, .2, .1 }; h.callbacks[1]()
check(h.colors == oldColors, "released owned pane stops accent work")

local bare = { CreateFontString = function() local fs = h.font(); function fs:SetText(text) self.text = text end; return fs end }
skin:ApplyToOwnedPane(bare, "Threat")
check(bare.HeaderTitle and bare.HeaderTitle.text == "Threat" and bare.HeaderTitle.size == 12,
    "owned title fallback is created only for an addon-owned pane")
local plain = { Title = h.font(), textures = {} }
function plain:CreateTexture() local tex = h.texture(); self.textures[#self.textures + 1] = tex; return tex end
function plain.Title:SetText(text) self.text = text end
skin:ApplyToOwnedPane(plain, "Threat", .8)
check(#plain.textures == 6 and plain.textures[5].height == 32 and plain.textures[6].allPoints == plain,
    "owned pane without header/background gets bounded shared chrome")
skin:ApplyToOwnedPane(plain, "Threat", 1)
check(#plain.textures == 6 and plain.textures[5].height == 25.6, "owned header follows scale without new textures")
skin:ReleaseWindow(plain)
check(not plain.textures[5].shown and not plain.textures[6].shown, "release hides all addon-created pane chrome")
skin:ApplyToOwnedPane(plain, "Threat", 1)
check(plain.textures[5].shown and plain.textures[6].shown and #plain.textures == 6,
    "owned chrome reactivation reuses existing textures")

local fallback = boot(false)
local fallbackWindow = fallback.window("session")
fallback.skin:ApplyToWindow(fallbackWindow, 1)
check(fallbackWindow.children[1].tint[1] == .25 and fallbackWindow.children[1].tint[2] == .5,
    "missing theme service uses public player class color")
check(fallback.hooks == 0, "missing appearance service installs no substitute event loop")
local fs = fallback.font(); fs.rejectArial = true
fallback.skin:StyleFont(fs, 14)
check(fs.path == "Fonts\\FRIZQT__.TTF", "unavailable Arial uses Blizzard's native font fallback")
local opaque = setmetatable({ opaque = true }, { __lt = forbidden, __le = forbidden,
    __div = forbidden, __tostring = forbidden })
fallback.skin:StyleFont(fs, opaque)
fallback.skin:ApplyToEntry(nil, opaque)
check(fs.size == 14, "secret size is never compared or used in arithmetic")
fallback.skin:ApplyToEntry({}, 0)
fallback.skin:ApplyToWindow({}, -1)
fallback.skin:ApplyToOwnedPane(nil, "Threat")
fallback.skin:ReleaseWindow(nil)
check(fallback.frameCreates == 0, "missing or partial native objects remain safe without a new framework")
fallback.env.UnitClass = function() return "Unknown", opaque end
fallback.env.RAID_CLASS_COLORS = setmetatable({}, { __index = forbidden })
local unknownClass = fallback.window("source")
fallback.skin:ApplyToWindow(unknownClass, 1)
check(unknownClass.children[1].tint[1] == .6, "an unreadable class token never becomes a class-table key")

print(string.format("native meter skin: %d checks, %d failures; no native secrets/rendering/taint emulated", checks, failures))
assert(failures == 0, "native meter skin regressions")
