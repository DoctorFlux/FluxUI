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
    env.unpack = table.unpack
    env.InCombatLockdown = function() return h.combat == true end
    env.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    env.UnitClass = function(unit) assert(unit == "player"); return "Mage", "MAGE" end
    env.RAID_CLASS_COLORS = { MAGE = { r = .25, g = .5, b = .75 } }
    env.issecretvalue = function(value) return type(value) == "table" and rawget(value, "opaque") == true end
    env.CreateFrame = function() h.frameCreates = h.frameCreates + 1; forbidden() end
    env.GetFileIDFromPath = forbidden
    env.C_AddOns = { LoadAddOn = forbidden, IsAddOnLoaded = forbidden, GetAddOnInfo = forbidden }
    env.C_Timer = { After = forbidden, NewTimer = forbidden, NewTicker = forbidden }
    if withTheme then
        env.FluxBorder = { GetThemedVertexRGB = function() return table.unpack(h.theme) end,
            RefreshAppearanceDependents = function() end }
    end
    env.hooksecurefunc = function(object, method, callback)
        if object == env.FluxBorder then
            assert(method == "RefreshAppearanceDependents")
            h.hooks = h.hooks + 1; h.callbacks[#h.callbacks + 1] = callback
        else
            h.nativeHooks = h.nativeHooks or {}; h.nativeHooks[object] = h.nativeHooks[object] or {}
            local methods = h.nativeHooks[object]; methods[method] = methods[method] or {}
            methods[method][#methods[method] + 1] = callback
        end
    end
    function h.font()
        local fs = { color = { .1, .9, .1, 1 }, text = "Mario Super", calls = 0, wordWrap = true, nonSpaceWrap = true }
        function fs:SetFont(path, size, flags)
            h.fonts = h.fonts + 1; self.calls = self.calls + 1
            if h.rejectDetailsFont and path:find("Accidental", 1, true) then return false end
            if self.rejectArial and (path == "Fonts\\ARIALN.TTF" or path:find("Accidental", 1, true)) then return false end
            self.path, self.size, self.flags = path, size, flags; return true
        end
        function fs:GetFont() return self.path, self.size, self.flags end
        function fs:CanWordWrap() return self.wordWrap end
        function fs:CanNonSpaceWrap() return self.nonSpaceWrap end
        function fs:SetWordWrap(value) self.wordWrap = value; h.wrapSets = h.wrapSets + 1 end
        function fs:SetNonSpaceWrap(value) self.nonSpaceWrap = value; h.wrapSets = h.wrapSets + 1 end
        function fs:SetShadowColor(...) self.shadow = { ... } end
        function fs:SetShadowOffset(...) self.offset = { ... } end
        function fs:SetTextColor(...)
            self.color = { ... } -- Glyph color alpha is distinct from region alpha.
        end
        function fs:GetAlpha() return self.alpha or 1 end
        function fs:GetWidth() return self.width or 160 end
        function fs:SetWidth(width) self.width = width end
        function fs:SetAlpha(alpha) self.alpha = alpha end
        function fs:ClearAllPoints() self.points = {} end
        function fs:GetNumPoints() return #(self.points or {}) end
        function fs:GetPoint(i) return table.unpack(self.points[i]) end
        fs.GetText, fs.GetFormattedText, fs.SetText = forbidden, forbidden, forbidden
        function fs:SetPoint(...)
            self.point = { ... }; self.points = self.points or {}
            for i,p in ipairs(self.points) do if p[1] == self.point[1] then self.points[i] = self.point; return end end
            self.points[#self.points + 1] = self.point
        end
        return fs
    end
    function h.texture()
        h.textures = h.textures + 1
        local t = { shown = true, tintCalls = 0, points = {} }
        function t:SetTexture(path)
            h.textureSets = (h.textureSets or 0) + 1
            if h.rejectTGA and path:sub(-4) == ".tga" then return false end
            if h.rejectDetailsAssets and path:find("AddOns\\Details", 1, true) then return false end
            self.path = path; return true
        end
        function t:ClearAllPoints() self.points = {} end
        function t:SetTexCoord(...) self.uv = {...} end
        function t:SetDrawLayer(layer, sublevel) self.layer, self.sublevel = layer, sublevel or 0 end
        function t:GetAlpha() return self.alpha or 1 end
        function t:SetPoint(...) self.points[#self.points + 1] = { ... } end
        function t:SetWidth(width) self.width = width end
        function t:SetHeight(height) self.height = height end
        function t:GetHeight() return self.height or 32 end
        function t:SetAllPoints(parent) self.allPoints = parent end
        function t:SetVertexColor(...)
            h.colors = h.colors + 1; self.tintCalls = self.tintCalls + 1; self.tint = { ... }
            if select("#", ...) == 4 then self.alpha = self.tint[4] end
        end
        function t:SetColorTexture(...) self.fill = { ... } end
        function t:SetAlpha(alpha)
            self.alpha = alpha; if self.tint then self.tint[4] = alpha end
        end
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
        function w:CreateTexture() local t = h.texture(); t.owner = self; self.children[#self.children + 1] = t; return t end
        w.SetPoint, w.SetSize, w.SetScale, w.SetBarHeight = forbidden, forbidden, forbidden, forbidden
        w.SetVisibility, w.SetSession, w.Refresh, w.Show, w.Hide = forbidden, forbidden, forbidden, forbidden, forbidden
        w.SetScript, w.RegisterEvent = forbidden, forbidden
        w.scriptHooks = {}
        function w:HookScript(event, fn) self.scriptHooks[event] = self.scriptHooks[event] or {}; table.insert(self.scriptHooks[event],fn) end
        function w:IsMouseOver() return self.mouseOver or false end
        function w:GetLeft() return self.left or 100 end
        function w:GetEffectiveScale() return .8 end
        w.GetCombatSession, w.GetSessionType, w.GetDamageMeterType = forbidden, forbidden, forbidden
        if kind == "session" then
            w.Header = h.texture()
            w.typeFont, w.sessionFont, w.timerFont = h.font(), h.font(), h.font()
            w.GetDamageMeterTypeName = function() return w.typeFont end
            w.GetSessionName = function() return w.sessionFont end
            w.GetSessionTimerFontString = function() return w.timerFont end
            w.MinimizeContainer = { NotActive = h.font(), Background = h.texture() }
            w.MinimizeContainer.Background:SetDrawLayer("BACKGROUND",0)
            function w.MinimizeContainer:CreateTexture() local t = h.texture(); t.owner = self; w.children[#w.children + 1] = t; return t end
            local function button()
                local b = {scriptHooks = {}, open = false}
                b.SetScript, b.SetAlpha, b.Hide = forbidden, forbidden, forbidden
                function b:HookScript(event, fn) self.scriptHooks[event] = self.scriptHooks[event] or {}; table.insert(self.scriptHooks[event],fn) end
                function b:IsMenuOpen() return self.open end
                function b:GetLeft() return self.left or 250 end
                function b:GetEffectiveScale() return .8 end
                local function dispatch(self, method)
                    for _,fn in ipairs(h.nativeHooks and h.nativeHooks[self] and h.nativeHooks[self][method] or {}) do fn(self) end
                end
                function b:OnMenuOpened() self.open = true; dispatch(self,"OnMenuOpened") end
                function b:OnMenuClosed() self.open = false; dispatch(self,"OnMenuClosed") end
                return b
            end
            w.DamageMeterTypeDropdown, w.SessionDropdown, w.SettingsDropdown = button(), button(), button()
            w.DamageMeterTypeDropdown.Arrow = h.texture(); w.DamageMeterTypeDropdown.TypeName = w.typeFont
            w.SessionDropdown.Background, w.SessionDropdown.Arrow = h.texture(), h.texture()
            w.SessionDropdown.Text, w.SessionDropdown.SessionName = h.font(), w.sessionFont
            w.SettingsDropdown.Icon = h.texture()
            w.typeFont:SetPoint("LEFT", w.DamageMeterTypeDropdown.Arrow, "RIGHT", 0, 3)
            w.typeFont:SetPoint("RIGHT", w.SessionDropdown, "LEFT", -5, 0)
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
check(name.path == "Interface\\AddOns\\Details\\fonts\\Accidental Presidency.ttf" and name.size == 17.5 and name.flags == "OUTLINE", "native row font compensates root scale")
check(value.size == 17.5 and value.flags == "OUTLINE", "native value font matches row")
check(name.color[1] == .1 and name.color[2] == .9, "skin preserves integration's local-player name tint")
check(value.color[1] == 1 and value.color[2] == 1 and value.color[3] == 1, "value text is white")
check(name.shadow[4] == 1 and name.offset[1] == 1 and name.offset[2] == -1, "font outline has the shared readable shadow")
check(bar.texture == "Interface\\TargetingFrame\\UI-StatusBar", "bar uses Blizzard status-bar texture")
check(background.fill[1] == .619607 and background.fill[4] == 1 and background.alpha == .116164 and edge.alpha == 0,
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
check(name.path == "Interface\\AddOns\\Details\\fonts\\Accidental Presidency.ttf" and name.size == 17.5 and name.flags == "OUTLINE",
    "native row font reset is repaired on pooled entry reuse")
fontCalls = h.fonts
skin:ApplyToEntry(entry, 1)
check(name.size == 14 and value.size == 14 and h.fonts == fontCalls + 2, "font size follows a changed public root scale")

local session = h.window("session")
local originalTypeButton, originalTypeMenuOpened = session.DamageMeterTypeDropdown, session.DamageMeterTypeDropdown.OnMenuOpened
local originalTitleLeft, originalTitleRight = session.typeFont.points[1], session.typeFont.points[2]
local originalHeader = session.Header; originalHeader:SetAlpha(.37)
local refresh = session.Refresh
skin:ApplyToWindow(session, .8)
check(#session.children == 9 and h.hooks == 1, "native chrome creates nine reference pieces and one shared theme hook")
check(session.children[1].height == 160 and session.children[5].width == 80, "padded atlas regions preserve original density at root scale")
check(session.Header.alpha == 0 and session.children[1].path == "Interface\\AddOns\\Details\\images\\skins\\default_skin.tga"
    and session.children[1].tint[1] == .2, "actual installed artwork receives the full accent while native header bounds stay intact")
check(session.typeFont.size == 15 and session.sessionFont.size == 15 and session.timerFont.size == 15,
    "native title/session/timer fonts compensate root scale")
check(session.typeFont.path == "Fonts\\FRIZQT__.TTF" and session.sessionFont.path == session.typeFont.path,
    "native titles use the same stock Friz Quadrata font as FluxDetails")
check(session.typeFont.color[1] == 1 and session.typeFont.color[2] == .82 and session.timerFont.color[3] == 0,
    "native header and timer keep the shared gold title color")
check(session.typeFont.text == "Mario Super" and session.timerFont.text == "Mario Super",
    "native title and timer contents remain untouched")
local panel = session.MinimizeContainer.Background
check(panel.tint[1] == .0941 and panel.tint[2] == .0941 and panel.tint[3] == .0941 and math.abs(panel.tint[4] - .91) < 1e-12 and math.abs(panel.alpha - .91) < 1e-12,
    "actual nested native background receives the common panel fill")
panel:SetAlpha(.35)
skin:ApplyToWindow(session, .8)
check(math.abs(panel.alpha - .91) < 1e-12, "native background alpha reset is normalized on style reapplication")
check(session.Refresh == refresh and session.geometry == "native" and session.type == "native"
    and session.session == "native", "native layout, configuration and refresh stay unchanged")
local stableTextures, stableFonts, stableColors = h.textures, h.fonts, h.colors
h.combat = true
for _ = 1, 500 do skin:ApplyToWindow(session,.8) end
h.combat = false
check(h.textures == stableTextures and h.fonts == stableFonts and session.Header.height == 15.5
    and session.children[4].layer == "BORDER", "500 combat paints retain header order without allocation or native geometry changes")
for _ = 1, 500 do skin:ApplyToWindow(session, .8) end
check(h.textures == stableTextures and h.fonts == stableFonts and h.colors == stableColors and h.hooks == 1,
    "500 repeated native styles reuse chrome, fonts and theme colors")
session.typeFont:SetFont("Interface\\AddOns\\Details\\fonts\\Accidental Presidency.ttf", 10, "")
skin:ApplyToWindow(session, .8)
check(session.typeFont.path == "Fonts\\FRIZQT__.TTF" and session.typeFont.size == 15,
    "native window font reset is repaired on reapplication")

local sourceWindow = h.window("source")
skin:ApplyToWindow(sourceWindow, .8)
check(#sourceWindow.children == 9 and math.abs(sourceWindow.Background.tint[4] - .91) < 1e-12 and math.abs(sourceWindow.Background.alpha - .91) < 1e-12,
    "source-window shape skins without a fabricated header")
check(sourceWindow.GetSessionTimerFontString == nil and sourceWindow.Refresh == forbidden,
    "source methods and missing native regions remain unchanged")
h.theme = { .8, .3, .1 }; h.callbacks[1]()
check(session.children[1].tint[1] == .8 and sourceWindow.children[1].tint[2] == .3,
    "existing appearance service recolors session and source rails")
check(session.children[1].tint[3] == .1, "header follows a later accent")
session.Header = h.texture()
skin:ApplyToWindow(session, .8)
check(session.Header.alpha == 0 and session.children[1].tint[1] == .8,
    "a replaced native header is suppressed without changing native geometry")
check(originalHeader.alpha == .37, "replaced native header restores its original alpha")
check(session.children[1].points[1][5] == -17.5 and sourceWindow.children[1].points[1][5] == 0,
    "session header and headerless source keep their own body baselines")
local expectedUV = {
    {.44921875,.5732421875,.08203125,.2060546875},
    {.58837890625,.5947265625,.08203125,.2060546875},
    {.3154296875,.439453125,.08203125,.2060546875},
    {.15625,.6552734375,.22265625,.3466796875},
    {.765625,.828125,.001953125,.501953125},
    {.7001953125,.7626953125,.001953125,.501953125},
    {.32861328125,.82666015625,.50537109375,.56494140625},
    {.00146484375,.03076171875,.30126953125,.33056640625},
    {.03564453125,.06494140625,.30126953125,.33056640625},
}
local layers = {"OVERLAY","BORDER","BORDER","BORDER","ARTWORK","ARTWORK","ARTWORK","OVERLAY","OVERLAY"}
local actualUV = true
for i, uv in ipairs(expectedUV) do
    for j, value in ipairs(uv) do actualUV = actualUV and session.children[i].uv[j] == value end
    actualUV = actualUV and session.children[i].layer == layers[i]
end
check(actualUV, "all nine artwork roles retain verified UV coordinates and draw layers")
check(session.MinimizeContainer.Background.layer == "BACKGROUND" and session.MinimizeContainer.Background.sublevel == 0
    and session.children[2].layer == "BORDER" and session.children[2].sublevel == 0
    and session.children[3].layer == "BORDER" and session.children[4].layer == "BORDER",
    "native header strips have a guaranteed layer above the inline background")
check(sourceWindow.children[2].layer == "BACKGROUND" and sourceWindow.children[3].layer == "BACKGROUND"
    and sourceWindow.children[4].layer == "BACKGROUND",
    "headerless source chrome retains the original Details artwork layers")
check(panel.path == "Interface\\AddOns\\Details\\images\\background.tga", "panel paint uses the installed gray artwork")
local exactEntry, _, _, _, exactBackground = h.entry(); skin:ApplyToEntry(exactEntry,.8)
check(exactBackground.path == "Interface\\AddOns\\Details\\images\\bar_background.tga" and exactBackground.tint[4] == .116164,
    "row paint combines the actual DGround artwork with its original vertex overlay")
check(session.children[1].owner == session.MinimizeContainer and session.children[4].owner == session.MinimizeContainer
    and sourceWindow.children[1].owner == sourceWindow,
    "native chrome shares the actual background paint owner while source geometry stays native")
check(session.typeFont.points[1][1] == "BOTTOMLEFT" and session.typeFont.points[1][2] == session
    and session.typeFont.points[1][4] == 6.25 and session.typeFont.points[1][5] == -16.25
    and #session.typeFont.points == 1 and session.typeFont.width == 138.75,
    "title uses the Details body-top anchor and reserves the native menu width without vertical recentering")
check(session.Header.height == 15.5 and (session.Header.height + 2) * .8 == 14,
    "native minus-two ScrollBox offset places its first row at the shared fourteen-pixel body inset")
local titleWidth = session.typeFont.width
session.SessionDropdown.left = 300
for _,fn in ipairs(session.scriptHooks.OnSizeChanged or {}) do fn(session) end
check(session.typeFont.width == titleWidth + 50 and #session.scriptHooks.OnSizeChanged == 2,
    "native size changes reconcile title width and timer election without replacing scripts")
session.SessionDropdown.left = nil
for _,fn in ipairs(session.scriptHooks.OnSizeChanged or {}) do fn(session) end
local arrow, gear, label = session.DamageMeterTypeDropdown.Arrow, session.SettingsDropdown.Icon, session.SessionDropdown.SessionName
check(arrow.alpha == 0 and gear.alpha == 0 and label.alpha == 0 and session.typeFont:GetAlpha() == 1,
    "unhovered menu regions hide while main title text stays visible")
local function pointer(inside)
    session.mouseOver = inside
    for _,fn in ipairs(session.scriptHooks[inside and "OnEnter" or "OnLeave"] or {}) do fn(session) end
end
pointer(true)
check(arrow.alpha == 0 and gear.alpha == .92 and label.alpha == .92 and session.typeFont:GetAlpha() == 1,
    "hover reveals right menus while the left attribute icon stays suppressed and title stays visible")
pointer(false); session.SettingsDropdown:OnMenuOpened()
check(gear.alpha == .92 and arrow.alpha == 0, "an open native dropdown keeps menus visible after the pointer leaves")
check(session.DamageMeterTypeDropdown == originalTypeButton and session.DamageMeterTypeDropdown.OnMenuOpened == originalTypeMenuOpened,
    "attribute icon suppression retains the original native button and menu function")
session.SettingsDropdown:OnMenuClosed()
check(gear.alpha == 0 and arrow.alpha == 0, "closing the native menu restores the unhovered appearance")
skin:ApplyToWindow(session,.8)
check(label.alpha == 0 and session.typeFont:GetAlpha() == 1, "font repaint does not unhide the native session menu label")
local hoverTextures, hoverFonts = h.textures, h.fonts
for _ = 1,500 do pointer(true); pointer(false) end
check(h.textures == hoverTextures and h.fonts == hoverFonts
    and #session.scriptHooks.OnEnter == 1 and #h.nativeHooks[session.SettingsDropdown].OnMenuOpened == 1,
    "500 hover cycles reuse native controls with one guarded script and menu posthook")
local oldColors = h.colors
skin:ReleaseWindow(session)
check(session.typeFont.points[1][2] == originalTitleLeft[2] and session.typeFont.points[1][4] == originalTitleLeft[4]
    and session.typeFont.points[2][2] == originalTitleRight[2] and arrow.alpha == 1 and gear.alpha == 1,
    "release restores original title anchors and native menu-region alpha")
gear:SetAlpha(.25); pointer(true)
check(gear.alpha == .25, "released native window hover hooks remain idle")
check(not session.children[1].shown and not session.children[9].shown and session.Header.alpha == 1, "release hides addon-owned rails")
h.theme = { .4, .5, .6 }; h.callbacks[1]()
check(session.children[1].tint[1] == .8 and sourceWindow.children[1].tint[1] == .4,
    "released native window does no hidden accent work")
check(h.colors > oldColors, "other active native windows still refresh")
panel.path = "native-restored"
local beforeReuse = h.textures
skin:ApplyToWindow(session, .8)
check(panel.path == "Interface\\AddOns\\Details\\images\\background.tga", "re-embedding restores panel artwork after native ownership was released")
check(h.textures == beforeReuse and session.children[1].shown and session.children[1].tint[1] == .4,
    "native re-embed reuses existing chrome")
skin:ReleaseAllNative(); oldColors = h.colors
h.theme = { .9, .8, .7 }; h.callbacks[1]()
check(h.colors == oldColors, "empty native registry makes permanent appearance hook idle")

local owned = h.window("source")
owned.Title = h.font(); function owned.Title:SetText(text) self.text = text end
owned.Header = { CreateTexture = function() return h.texture() end }
skin:ApplyToOwnedPane(owned, "Threat", .8)
check(owned.children[2].layer == "BACKGROUND" and owned.children[3].layer == "BACKGROUND"
    and owned.children[4].layer == "BACKGROUND", "owned Threat retains the original Details header layers")
check(owned.Title.text == "Threat" and owned.Title.size == 15 and owned.HeaderTitle == nil,
    "owned threat pane reuses its existing title")
check(owned.Title.color[1] == 1 and owned.Title.color[2] == .82 and owned.Title.color[3] == 0,
    "owned title matches the shared gold header")
check(owned.Title.path == session.typeFont.path and owned.Background.tint[1] == panel.tint[1]
    and owned.Background.tint[4] == panel.tint[4] and owned.Background.alpha == panel.alpha,
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
check(#plain.textures == 10 and plain.textures[1].height == 160 and plain.textures[10].allPoints == plain,
    "owned pane without native regions gets nine reference pieces and one backdrop")
skin:ApplyToOwnedPane(plain, "Threat", 1)
check(#plain.textures == 10 and plain.textures[1].height == 128, "padded atlas density follows scale without new textures")
skin:ReleaseWindow(plain)
check(not plain.textures[1].shown and not plain.textures[10].shown, "release hides all addon-created pane chrome")
skin:ApplyToOwnedPane(plain, "Threat", 1)
check(plain.textures[1].shown and plain.textures[10].shown and #plain.textures == 10,
    "owned reference chrome reactivation reuses existing textures")

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

local alphaFixture = boot(true); local secretAlpha = setmetatable({opaque=true}, {
    __lt=forbidden, __le=forbidden, __tostring=forbidden, __add=forbidden })
local alphaWindow = alphaFixture.window("session"); alphaWindow.Header.alpha = secretAlpha
alphaWindow.typeFont.points[1][4] = secretAlpha
alphaFixture.skin:ApplyToWindow(alphaWindow,.8); alphaFixture.skin:ReleaseWindow(alphaWindow)
check(alphaWindow.typeFont.points[1][4] == secretAlpha, "opaque native title geometry is left unchanged")
check(alphaWindow.Header.alpha == secretAlpha, "release preserves an opaque native header alpha through display-only pass-through")
local alternate = boot(true); alternate.rejectTGA = true
local alternateWindow = alternate.window("session"); alternate.skin:ApplyToWindow(alternateWindow,.8)
check(alternateWindow.children[1].path == "Interface\\AddOns\\Details\\images\\skins\\default_skin.blp",
    "declared alternate extension is selected only after the owned texture confirms success")
local deferred = boot(true); local deferredWindow = deferred.window("session")
deferred.skin:ApplyToWindow(deferredWindow,.8)
deferred.combat = true; deferred.skin:ReleaseAllNative()
check(deferredWindow.Header.height == 15.5 and deferredWindow.typeFont.points[1][1] == "BOTTOMLEFT",
    "combat retirement defers native header and title geometry restoration")
local retiredColors = deferred.colors; deferredWindow.SettingsDropdown.Icon:SetAlpha(.23)
for _,fn in ipairs(deferredWindow.scriptHooks.OnEnter or {}) do fn(deferredWindow) end
check(deferredWindow.SettingsDropdown.Icon.alpha == .23 and deferred.colors == retiredColors,
    "retired callbacks stay idle while original geometry awaits combat exit")
deferred.combat = false; deferred.skin:ReleaseAllNative()
check(deferredWindow.Header.height == 32 and deferredWindow.typeFont.width == 160
    and deferredWindow.typeFont.points[1][1] == "LEFT",
    "existing out-of-combat cleanup restores geometry after active membership was retired")
local opaqueRect = boot(true); local opaqueRectWindow = opaqueRect.window("session")
opaqueRectWindow.SessionDropdown.left = secretAlpha
opaqueRect.skin:ApplyToWindow(opaqueRectWindow,.8)
check(opaqueRectWindow.typeFont.points[1][1] == "LEFT" and opaqueRectWindow.typeFont.width == nil,
    "opaque native configuration bounds are not compared or used in geometry arithmetic")
local missing = boot(false); missing.rejectDetailsAssets, missing.rejectDetailsFont = true, true
local missingWindow = missing.window("session"); missingWindow.Header:SetAlpha(.42)
missing.skin:ApplyToWindow(missingWindow,.8)
check(#missingWindow.children == 4 and missingWindow.Header.alpha == .42,
    "missing optional artwork retains stock chrome and original native header")
local missedProbes = missing.textureSets
for _ = 1,500 do missing.skin:ApplyToWindow(missingWindow,.8) end
check(missing.textureSets == missedProbes, "failed optional asset probes are cached without idle retries")
local missingFont = missing.font(); missing.skin:StyleFont(missingFont,14)
check(missingFont.path == "Fonts\\ARIALN.TTF", "missing optional row font uses the approved stock fallback")

-- Geometry-driven timer arbitration; no timer text, session data or native refresh.
local clock = boot(true)
clock.timerGeometry, clock.timerAlphaWrites = 0, 0
local function timerPane(top, left, effectiveScale, alpha)
    local w = clock.window("session")
    w.top, w.left, w.effectiveScale, w.visible = top, left, effectiveScale, true
    function w:GetTop() return self.top end
    function w:GetEffectiveScale() return self.effectiveScale end
    function w:IsVisible() return self.visible and clock.parentVisible ~= false end
    local timer, control = w.timerFont, w.DamageMeterTypeDropdown
    timer:SetAlpha(alpha)
    timer:SetPoint("TOPLEFT", w.Header, "TOPLEFT", 1, -9)
    local setPoint, setAlpha = timer.SetPoint, timer.SetAlpha
    function timer:SetPoint(...)
        assert(not clock.combat, "timer geometry changed in combat")
        clock.timerGeometry = clock.timerGeometry + 1; setPoint(self,...)
    end
    function timer:SetAlpha(value) clock.timerAlphaWrites = clock.timerAlphaWrites + 1; setAlpha(self,value) end
    control.points = {{"TOPLEFT",timer,"TOPRIGHT",0,6}}
    function control:GetNumPoints() return #self.points end
    function control:GetPoint(index) return table.unpack(self.points[index]) end
    function control:ClearAllPoints() assert(not clock.combat); self.points = {} end
    function control:SetPoint(...) assert(not clock.combat); self.points[#self.points + 1] = {...} end
    return w
end
local a, b, c = timerPane(1000,150,.8,.37), timerPane(1000,100,.8,.64), timerPane(1500,10,.5,.9)
local originalMenu = b.DamageMeterTypeDropdown.OnMenuOpened
local function elect() if clock.skin.SyncNativeTimer then clock.skin:SyncNativeTimer() end end
local function event(window,name) for _,fn in ipairs(window.scriptHooks[name] or {}) do fn(window) end end
clock.skin:ApplyToWindow(a,.8); clock.skin:ApplyToWindow(b,.8); clock.skin:ApplyToWindow(c,.5)
check(type(clock.skin.SyncNativeTimer) == "function", "single-timer presentation has an explicit layout reconciliation entry point")
check(a.timerFont:GetAlpha() == 0 and b.timerFont:GetAlpha() == .64 and c.timerFont:GetAlpha() == 0,
    "highest screen-space top wins before screen-space left, preserving the winner's original alpha")
check(a.typeFont.points[1][4] == 6.25 and a.typeFont.width > 0 and a.timerFont.width == 50,
    "fixed timer reservation preserves left title position and positive title space")
check(b.timerFont.points[1][1] == "BOTTOMLEFT" and b.timerFont.points[1][5] == -16.25,
    "timer and title share the compact header baseline without inspecting text metrics")
check(b.DamageMeterTypeDropdown.points[1][2] == b.Header
    and b.DamageMeterTypeDropdown.OnMenuOpened == originalMenu,
    "moving the timer does not drag its dependent native type-menu hitbox or replace its handler")
c.top = 1700; elect()
check(c.timerFont:GetAlpha() == .9 and a.timerFont:GetAlpha() == 0 and b.timerFont:GetAlpha() == 0,
    "a physically higher pane wins across different effective scales")
c.top = 1500; b.visible = false; event(b,"OnHide")
check(a.timerFont:GetAlpha() == .37 and c.timerFont:GetAlpha() == 0,
    "hiding the winner elects the next highest visible pane")
b.visible = true; event(b,"OnShow")
check(b.timerFont:GetAlpha() == .64 and a.timerFont:GetAlpha() == 0, "revealing the higher-priority pane restores its timer")
b.left, a.left = 250, 20; elect()
check(a.timerFont:GetAlpha() == .37 and b.timerFont:GetAlpha() == 0, "column reordering elects the leftmost pane on the same row")
b.top = 1001; event(b,"OnSizeChanged")
check(b.timerFont:GetAlpha() == .64 and a.timerFont:GetAlpha() == 0, "top priority precedes left priority even for a small top difference")
clock.parentVisible = false; event(b,"OnHide")
check(a.timerFont:GetAlpha() == 0 and b.timerFont:GetAlpha() == 0 and c.timerFont:GetAlpha() == 0,
    "an invisible host has no displayed timer")
clock.parentVisible = true; event(b,"OnShow")
clock.skin:ApplyToWindow(a,.8); clock.skin:ApplyToWindow(b,.8)
local beforeGeometry, beforeTextures = clock.timerGeometry, clock.textures
for _ = 1,500 do clock.skin:ApplyToWindow(a,.8); clock.skin:ApplyToWindow(b,.8); elect() end
check(clock.timerGeometry == beforeGeometry and clock.textures == beforeTextures,
    "500 repeated layouts reuse timer geometry and chrome without allocating resources")
check(#b.scriptHooks.OnShow == 1 and #b.scriptHooks.OnHide == 1 and #b.scriptHooks.OnSizeChanged == 2,
    "repeat application installs no duplicate visibility or geometry hooks")
clock.combat = true; b.visible = false; event(b,"OnHide")
check(a.timerFont:GetAlpha() == .37 and clock.timerGeometry == beforeGeometry,
    "combat winner changes touch presentation alpha only")
clock.skin:ReleaseAllNative()
check(a.timerFont:GetAlpha() == .37 and b.timerFont:GetAlpha() == .64 and c.timerFont:GetAlpha() == .9,
    "combat cleanup restores all native alpha snapshots immediately")
clock.combat = false; clock.skin:ReleaseAllNative()
check(a.timerFont.points[1][1] == "TOPLEFT" and a.timerFont.points[1][2] == a.Header and a.timerFont:GetWidth() == 160
    and a.DamageMeterTypeDropdown.points[1][2] == a.timerFont and a.DamageMeterTypeDropdown.points[1][5] == 6,
    "out-of-combat cleanup restores native timer and dependent control geometry")
local releasedWrites = clock.timerAlphaWrites; event(a,"OnShow"); elect()
check(clock.timerAlphaWrites == releasedWrites, "retired timer hooks perform no hidden work")
local zero = timerPane(1000,100,.8,0); clock.skin:ApplyToWindow(zero,.8)
check(zero.timerFont:GetAlpha() == 0, "a winner whose native alpha was zero stays zero")
clock.skin:ReleaseWindow(zero)
local unknown = timerPane(1000,100,.8,.5); unknown.top = secretAlpha
clock.skin:ApplyToWindow(unknown,.8)
check(unknown.timerFont:GetAlpha() == .5, "unreadable geometry gets a stable fallback without comparison or arithmetic")
local known = timerPane(10,100,.8,.7); clock.skin:ApplyToWindow(known,.8)
check(known.timerFont:GetAlpha() == .7 and unknown.timerFont:GetAlpha() == 0,
    "readable screen geometry takes precedence over an unreadable fallback")
local narrow = timerPane(1000,220,.8,.4); clock.skin:ApplyToWindow(narrow,.8)
check(narrow.typeFont.width > 0 and type(narrow.timerFont.width) == "number" and narrow.timerFont.width > 0 and narrow.timerFont.width < 50,
    "narrow panes keep positive title and timer bounds inside the native menu reserve")
local tiny = timerPane(1000,238.25,.8,.4); clock.skin:ApplyToWindow(tiny,.8)
check(tiny.typeFont.width > 0 and type(tiny.timerFont.width) == "number" and tiny.timerFont.width > 0
    and tiny.timerFont.points[1][4] + tiny.timerFont.width <= 6.75 + 1e-9,
    "sub-pixel available header space clamps the timer gap and box together")
clock.skin:ReleaseWindow(narrow); narrow.timerFont:SetAlpha(.23); clock.skin:ApplyToWindow(narrow,.8)
clock.skin:ReleaseWindow(narrow)
check(narrow.timerFont:GetAlpha() == .23 and #narrow.scriptHooks.OnShow == 1,
    "reactivation snapshots the latest native alpha without duplicating permanent hooks")
narrow.timerFont:SetAlpha(.41); clock.skin:ReleaseAllNative()
check(narrow.timerFont:GetAlpha() == .41, "repeated cleanup leaves a retired timer's newer native alpha untouched")
local opaqueTimer = timerPane(1000,100,.8,secretAlpha); clock.skin:ApplyToWindow(opaqueTimer,.8)
check(opaqueTimer.timerFont:GetAlpha() == secretAlpha, "opaque native timer alpha is neither compared nor overwritten")
check(a.timerFont.text == "Mario Super" and b.timerFont.text == "Mario Super",
    "election and cleanup never rewrite native timer content or session policy")
print(string.format("native meter skin: %d checks, %d failures; no native secrets/rendering/taint emulated", checks, failures))
assert(failures == 0, "native meter skin regressions")
