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
        function fs:SetJustifyH(value) self.justifyH = value end
        function fs:GetJustifyH() return self.justifyH or "CENTER" end
        function fs:SetAlpha(alpha) self.alpha = alpha end
        function fs:ClearAllPoints() self.points = {} end
        function fs:GetNumPoints() return #(self.points or {}) end
        function fs:GetPoint(i) return table.unpack(self.points[i]) end
        fs.GetText, fs.GetFormattedText, fs.GetStringWidth, fs.SetText = forbidden, forbidden, forbidden, forbidden
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
            w.typeFont:SetJustifyH("LEFT")
            function w.typeFont:GetStringWidth() return self.headingWidth end
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
check(b.timerFont.points[1][1] == "BOTTOMLEFT" and b.timerFont.points[1][2] == b.typeFont
    and b.timerFont.points[1][3] == "BOTTOMRIGHT" and b.timerFont.points[1][5] == 0,
    "timer follows the heading's right edge on its unchanged compact baseline")
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
    and 6.25 + tiny.typeFont.width + tiny.timerFont.points[1][4] + tiny.timerFont.width <= 6.75 + 1e-9,
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

local mirror = boot(true)
local function positioned(kind, top, left, scale)
    local w = mirror.window(kind)
    w.top, w.left, w.scale, w.visible = top, left, scale, true
    function w:GetTop() return self.top end
    function w:GetEffectiveScale() return self.scale end
    function w:IsVisible() return self.visible end
    function w:GetWidth() return 200 end
    return w
end
local first, second = positioned("session",500,100,1), positioned("session",500,300,1)
first.timerFont:SetAlpha(.37); second.timerFont:SetAlpha(.64)
local originalNativeTextSetter = first.timerFont.SetText
mirror.skin:ApplyToWindow(first,1); mirror.skin:ApplyToWindow(second,1)
local threat = positioned("owned",500,0,1); threat.Title = mirror.font()
function threat.Title:SetText(value) self.text = value end
function threat.Title:GetStringWidth() return self.headingWidth end
function threat:CreateFontString()
    local fs = mirror.font(); self.clock = fs
    function fs:SetText(value) self.text = value; self.textWrites = (self.textWrites or 0) + 1 end
    return fs
end
local function emit(window, payload)
    local hooks = mirror.nativeHooks and mirror.nativeHooks[window.timerFont]
    for _,fn in ipairs(hooks and hooks.SetText or {}) do fn(window.timerFont,payload) end
end
local function sync() if mirror.skin.SyncNativeTimer then mirror.skin:SyncNativeTimer() end end
mirror.skin:ApplyToOwnedPane(threat,"Threat",1,true)
check(threat.clock and threat.clock.path == "Fonts\\FRIZQT__.TTF" and threat.clock.size == 12,
    "explicitly enabled Threat clock initializes its header font before text")
if threat.clock then
    check(threat.clock:GetAlpha() == .37 and first.timerFont:GetAlpha() == 0 and second.timerFont:GetAlpha() == 0,
        "Threat takes the single timer when it is leftmost on the highest row")
    emit(first,"[0:12] ")
    check(threat.clock.text == "[0:12] ", "native formatted timer text is forwarded to Threat")
    emit(second,"[9:99] ")
    check(threat.clock.text == "[0:12] ", "a lower-priority native donor cannot replace the selected clock")
    local opaqueText = setmetatable({opaque=true},{__tostring=forbidden,__concat=forbidden,__lt=forbidden,__le=forbidden})
    emit(first,opaqueText)
    check(threat.clock.text == opaqueText, "opaque native text reaches only the owned display sink without inspection")
    threat.top = 400; sync()
    check(first.timerFont:GetAlpha() == .37 and threat.clock:GetAlpha() == 0,
        "a lower Threat pane yields the timer to the highest native pane")
    threat.top, threat.left = 600, 500; sync()
    check(threat.clock:GetAlpha() == .37 and first.timerFont:GetAlpha() == 0,
        "Threat above native panes wins even when positioned farther right")
    first.top = 600; sync()
    check(first.timerFont:GetAlpha() == .37 and threat.clock:GetAlpha() == 0,
        "native pane left of Threat wins when their physical tops match")
    threat.top, threat.left, threat.scale = 1200, 0, .5; sync()
    check(threat.clock:GetAlpha() == .37 and threat.clock.text == opaqueText,
        "Threat priority accounts for physical scale and reuses an opaque cached native payload")
    if mirror.skin.SetOwnedTimerText then mirror.skin:SetOwnedTimerText(threat,"[0:03] ") end
    check(threat.clock.text == opaqueText, "ordinary fallback never overwrites a visible native donor")
    first.visible, second.visible = false, false; sync()
    check(threat.clock.text == "[0:03] ", "Threat-only presentation uses its separately supplied ordinary-combat clock")
    first.visible = true; emit(first,"[0:15] "); sync()
    check(threat.clock.text == "[0:15] ", "restoring a native donor immediately replaces the fallback")
    local titlePoints = threat.clock:GetNumPoints(); mirror.combat = true
    threat.visible = false; sync()
    check(first.timerFont:GetAlpha() == .37 and threat.clock:GetAlpha() == 0
        and threat.clock:GetNumPoints() == titlePoints, "combat hide election changes alpha without moving either timer")
    threat.visible = true; sync(); mirror.combat = false
    local nativeHooks, ownedClock = #mirror.nativeHooks[first.timerFont].SetText, threat.clock
    for _=1,500 do mirror.skin:ApplyToOwnedPane(threat,"Threat",1,true); mirror.skin:ApplyToWindow(first,1) end
    check(threat.clock == ownedClock and #mirror.nativeHooks[first.timerFont].SetText == nativeHooks and #threat.scriptHooks.OnShow == 1,
        "500 reapplications reuse the owned clock and permanent native/visibility hooks")
    mirror.skin:ReleaseWindow(threat)
    local releasedTextWrites = threat.clock.textWrites; emit(first,"[0:16] ")
    check(threat.clock:GetAlpha() == 0 and threat.clock.textWrites == releasedTextWrites,
        "released Threat receives no native timer writes")
    mirror.skin:ReleaseAllNative(); local count = threat.clock.textWrites; emit(first,opaqueText)
    check(first.timerFont:GetAlpha() == .37 and second.timerFont:GetAlpha() == .64 and threat.clock.textWrites == count,
        "Details cleanup restores native alphas and retires native text forwarding")
    check(first.timerFont.SetText == originalNativeTextSetter, "native text setter identity remains unchanged")
    mirror.skin:ApplyToWindow(first,1); mirror.skin:ApplyToOwnedPane(threat,"Threat",1,true)
    check(threat.clock.text == "", "retired native hooks cannot seed a later embedding with stale cached text")
    mirror.skin:ReleaseWindow(first); first.timerFont:SetAlpha(0); mirror.skin:ApplyToWindow(first,1); sync()
    check(threat.clock:GetAlpha() == 0, "a zero-alpha native donor does not become visible through Threat's mirror")
    mirror.skin:ReleaseWindow(first); first.timerFont:SetAlpha(.37); mirror.skin:ApplyToWindow(first,1); sync()
    local other = positioned("owned",2000,0,1); other.Title = mirror.font()
    function other.Title:SetText(value) self.text = value end
    mirror.skin:ApplyToOwnedPane(other,"Other",1)
    check(threat.clock:GetAlpha() == .37, "unregistered owned panes do not compete with the explicit Threat timer")
    mirror.skin:ReleaseWindow(threat)
    check(threat.Title:GetWidth() == 160, "owned timer cleanup restores the title's original width")
else check(false,"Threat clock creation is required") end

local heading = boot(true); local nativeHeading = heading.window("session")
nativeHeading.timerFont:SetPoint("TOPLEFT",nativeHeading.Header,"TOPLEFT",1,-9)
local headingControl = nativeHeading.DamageMeterTypeDropdown
headingControl.points = {{"TOPLEFT",nativeHeading.timerFont,"TOPRIGHT",0,6}}
function headingControl:GetNumPoints() return #self.points end
function headingControl:GetPoint(index) return table.unpack(self.points[index]) end
function headingControl:ClearAllPoints() self.points = {} end
function headingControl:SetPoint(...) self.points[#self.points + 1] = {...} end
nativeHeading.typeFont.headingWidth = 40
nativeHeading.typeFont:SetFont("old-native-font",9,"")
function nativeHeading.typeFont:GetStringWidth()
    assert(self.path == "Fonts\\FRIZQT__.TTF" and self.size == 15, "heading measured before presentation font")
    return self.headingWidth
end
heading.skin:ApplyToWindow(nativeHeading,.8)
check(nativeHeading.typeFont.width == 40 and nativeHeading.typeFont.points[1][4] == 6.25
    and nativeHeading.typeFont.points[1][5] == -16.25 and nativeHeading.typeFont:GetJustifyH() == "LEFT",
    "native heading keeps its original left display position and baseline while using its public intrinsic width")
check(nativeHeading.timerFont.point[1] == "BOTTOMLEFT" and nativeHeading.timerFont.point[2] == nativeHeading.typeFont
    and nativeHeading.timerFont.point[3] == "BOTTOMRIGHT" and nativeHeading.timerFont.point[4] == 6.25
    and nativeHeading.timerFont.point[5] == 0 and nativeHeading.timerFont:GetJustifyH() == "LEFT",
    "native timer starts immediately after the heading rather than at the pane's far edge")
check(nativeHeading.timerFont.width == 92.5 and nativeHeading.timerFont.width * .8 > 40,
    "native timer uses all remaining header space rather than the old forty-pixel box")
nativeHeading.typeFont.headingWidth = 1000; heading.skin:ApplyToWindow(nativeHeading,.8)
check(nativeHeading.typeFont.width == 82.5 and nativeHeading.timerFont.width == 50
    and nativeHeading.typeFont.points[1][4] == 6.25, "long localized headings clip within available space without moving their left edge")
nativeHeading.typeFont.headingWidth = secretAlpha; heading.skin:ApplyToWindow(nativeHeading,.8)
check(nativeHeading.typeFont.width == 82.5 and nativeHeading.timerFont.point[2] == nativeHeading.typeFont,
    "an opaque heading metric is never compared and falls back to the existing bounded heading box")
nativeHeading.typeFont.GetStringWidth = nil; heading.skin:ApplyToWindow(nativeHeading,.8)
check(nativeHeading.typeFont.width == 82.5, "an unavailable heading metric preserves the bounded box fallback")
nativeHeading.SessionDropdown.left = 150; heading.skin:ApplyToWindow(nativeHeading,.8)
check(nativeHeading.typeFont.width > 0 and nativeHeading.timerFont.width > 0
    and 6.25 + nativeHeading.typeFont.width + nativeHeading.timerFont.point[4] + nativeHeading.timerFont.width <= 45 + 1e-9,
    "narrow native headers keep title and adjacent timer within the menu boundary")
heading.skin:ReleaseWindow(nativeHeading)
check(nativeHeading.timerFont:GetJustifyH() == "CENTER" and nativeHeading.typeFont:GetWidth() == 160,
    "native cleanup restores original timer justification and heading width")
check(threat.Title:GetJustifyH() == "LEFT", "owned Threat heading is left-justified instead of centered within its widened box")
local drawnLeft = 5 + (threat.Title:GetJustifyH() == "LEFT" and 0 or (threat.Title:GetWidth() - 42) / 2)
check(drawnLeft == 5, "Threat's visible name starts at the original five-pixel left offset")

local packed = boot(true); packed.geometryWrites = 0
local panel = packed.window("session")
function panel:GetWidth() return 300 end
function panel:GetTop() return 600 end
local function geometry(object,width,height,points,atlas)
    object.gwidth, object.gheight, object.points = width,height,points or {}
    function object:GetWidth()
        if #self.points == 2 then local a,b=self.points[1],self.points[2]; return a[2]:GetWidth()-a[4]+b[4] end
        return self.gwidth
    end
    function object:GetHeight()
        if #self.points == 2 then local a,b=self.points[1],self.points[2]; return a[2]:GetHeight()+a[5]-b[5] end
        return self.gheight
    end
    local function offsets(o,p)
        local x=p:find("LEFT",1,true) and 0 or p:find("RIGHT",1,true) and o:GetWidth() or o:GetWidth()/2
        local y=p:find("TOP",1,true) and 0 or p:find("BOTTOM",1,true) and -o:GetHeight() or -o:GetHeight()/2
        return x,y
    end
    function object:GetLeft()
        local a=self.points[1]; if not a then return 0 end
        local px=offsets(a[2],a[3]); local sx=offsets(self,a[1]); return a[2]:GetLeft()+px+a[4]-sx
    end
    function object:GetTop()
        local a=self.points[1]; if not a then return 0 end
        local _,py=offsets(a[2],a[3]); local _,sy=offsets(self,a[1]); return a[2]:GetTop()+py+a[5]-sy
    end
    function object:GetNumPoints() return #self.points end
    function object:GetPoint(i) return table.unpack(self.points[i]) end
    function object:ClearAllPoints() assert(not packed.combat); packed.geometryWrites=packed.geometryWrites+1; self.points={} end
    function object:SetPoint(...) assert(not packed.combat); packed.geometryWrites=packed.geometryWrites+1; self.points[#self.points+1]={...} end
    function object:SetSize(w,h) assert(not packed.combat); packed.geometryWrites=packed.geometryWrites+1; self.gwidth,self.gheight=w,h end
    function object:SetWidth(w)
        assert(not packed.combat); packed.geometryWrites=packed.geometryWrites+1; self.gwidth=w
        for _,fn in ipairs(packed.nativeHooks and packed.nativeHooks[self] and packed.nativeHooks[self].SetWidth or {}) do fn(self,w) end
    end
    function object:SetHeight(h) assert(not packed.combat); packed.geometryWrites=packed.geometryWrites+1; self.gheight=h end
    object.SetParent=forbidden
    if atlas then
        function object:SetAtlas(value)
            self.gwidth,self.gheight=90,90
            for _,fn in ipairs(packed.nativeHooks and packed.nativeHooks[self] and packed.nativeHooks[self].SetAtlas or {}) do fn(self,value,true) end
        end
    end
    return object
end
geometry(panel.Header,300,32,{{"TOPLEFT",panel,"TOPLEFT",0,0}})
local function button(object,width,height,point,relative,rpoint,x,y)
    object=geometry(object or {},width,height,{{point,relative,rpoint,x,y}})
    object.shown=true; object.scriptHooks=object.scriptHooks or {}
    function object:IsShown() return self.shown end
    if not object.HookScript then function object:HookScript(event,fn) self.scriptHooks[event]=self.scriptHooks[event] or {}; table.insert(self.scriptHooks[event],fn) end end
    object.OnClick=function() end
    function object:IsProtected() return self.protected == true end
    function object:Hide()
        self.shown=false
        for _,fn in ipairs(self.scriptHooks.OnHide or {}) do fn(self) end
    end
    function object:Show()
        self.shown=true
        for _,fn in ipairs(self.scriptHooks.OnShow or {}) do fn(self) end
        for _,fn in ipairs(packed.nativeHooks and packed.nativeHooks[self] and packed.nativeHooks[self].Show or {}) do fn(self) end
    end
    return object
end
panel.CloseButton=button(nil,32,32,"TOPRIGHT",panel.Header,"TOPRIGHT",-1,-1); panel.CloseButton.shown=false
panel.MinimizeButton=button(nil,18,19,"TOPRIGHT",panel.Header,"TOPRIGHT",-3,-5)
button(panel.SettingsDropdown,27,27,"RIGHT",panel.MinimizeButton,"LEFT",-2,-2)
button(panel.SessionDropdown,18,18,"RIGHT",panel.SettingsDropdown,"LEFT",-2,3)
panel.timerFont:SetPoint("TOPLEFT",panel.Header,"TOPLEFT",1,-9)
button(panel.DamageMeterTypeDropdown,25,25,"TOPLEFT",panel.timerFont,"TOPRIGHT",0,6)
local function artwork(texture,parent,width,height,points)
    return geometry(texture or packed.texture(),width,height,points,true)
end
artwork(panel.SettingsDropdown.Icon,panel.SettingsDropdown,27,27,{{"TOPLEFT",panel.SettingsDropdown,"TOPLEFT",0,0},{"BOTTOMRIGHT",panel.SettingsDropdown,"BOTTOMRIGHT",0,0}})
artwork(panel.SessionDropdown.Background,panel.SessionDropdown,32,32,{{"TOPLEFT",panel.SessionDropdown,"TOPLEFT",-7,7},{"BOTTOMRIGHT",panel.SessionDropdown,"BOTTOMRIGHT",7,-7}})
artwork(panel.SessionDropdown.Arrow,panel.SessionDropdown,12,12,{{"BOTTOM",panel.SessionDropdown,"BOTTOM",0,-5}})
geometry(panel.SessionDropdown.SessionName,18,18,{{"TOPLEFT",panel.SessionDropdown,"TOPLEFT",0,0},{"BOTTOMRIGHT",panel.SessionDropdown,"BOTTOMRIGHT",0,0}})
geometry(panel.SessionDropdown.Text,20,20,{{"LEFT",panel.SessionDropdown,"LEFT",13,0},{"RIGHT",panel.SessionDropdown,"RIGHT",-13,0}})
artwork(panel.DamageMeterTypeDropdown.Arrow,panel.DamageMeterTypeDropdown,25,25,{{"CENTER",panel.DamageMeterTypeDropdown,"CENTER",0,-2}})
local normal=artwork(nil,panel.MinimizeButton,18,19,{})
local pushed=artwork(nil,panel.MinimizeButton,18,19,{})
local highlight=artwork(nil,panel.MinimizeButton,18,19,{})
function panel.MinimizeButton:GetNormalTexture() return normal end
function panel.MinimizeButton:GetPushedTexture() return pushed end
function panel.MinimizeButton:GetHighlightTexture() return highlight end
local closeNormal=artwork(nil,panel.CloseButton,32,32,{})
function panel.CloseButton:GetNormalTexture() return closeNormal end
panel.SetMinimized,panel.SetSessionWindowMinimized=forbidden,forbidden
panel.ResizeButton=geometry({},20,20,{{"BOTTOMRIGHT",panel,"BOTTOMRIGHT",0,0}})
local oldClick,oldMenu,oldNormalCount=panel.MinimizeButton.OnClick,panel.SettingsDropdown.OnMenuOpened,normal:GetNumPoints()
panel.typeFont.headingWidth=50
packed.skin:ApplyToWindow(panel,.8)
local function refreshPacked()
    if packed.skin.RefreshHeaderControls then packed.skin:RefreshHeaderControls() end
end
local function atlasHookCount(object)
    return #(packed.nativeHooks and packed.nativeHooks[object] and packed.nativeHooks[object].SetAtlas or {})
end
check(type(packed.skin.RefreshHeaderControls)=="function","header deferral reuses an explicit existing-service entry point")
local function inside(object)
    local left=(object:GetLeft()-panel:GetLeft())*.8
    local right=left+object:GetWidth()*.8
    local top=(panel:GetTop()-object:GetTop())*.8
    return left>=-1e-8 and right<=240+1e-8 and top>=-1e-8 and top+object:GetHeight()*.8<=14+1e-8
end
for _,name in ipairs({"SettingsDropdown","SessionDropdown","DamageMeterTypeDropdown"}) do
    check(inside(panel[name]) and panel[name]:GetHeight()*.8==12,"native header control fits within fourteen display pixels: "..name)
end
for _,object in ipairs({closeNormal,panel.SettingsDropdown.Icon,panel.SessionDropdown.Background,panel.SessionDropdown.Arrow,panel.DamageMeterTypeDropdown.Arrow}) do
    check(inside(object),"native atlas artwork remains inside the compact header")
end
check(not panel.MinimizeButton:IsShown() and panel.SettingsDropdown:GetLeft()+panel.SettingsDropdown:GetWidth()==panel:GetLeft()+panel:GetWidth()-2/.8,
    "Minimize is absent and hidden Close consumes no gap beside the rightmost control")
panel.MinimizeButton:Show()
check(not panel.MinimizeButton:IsShown(),"native attempts to re-show Minimize are hidden without changing its minimization setting")
check(panel.typeFont.point[4]==6.25 and panel.typeFont.point[5]==-16.25 and panel.timerFont.point[2]==panel.typeFont,
    "packing native controls preserves the heading position and adjacent timer")
check(panel.MinimizeButton.OnClick==oldClick and panel.SettingsDropdown.OnMenuOpened==oldMenu,
    "header packing preserves original native click and menu functions")
local writes=packed.geometryWrites;local atlasHooks=atlasHookCount(panel.SettingsDropdown.Icon)
for _=1,500 do packed.skin:ApplyToWindow(panel,.8) end
check(packed.geometryWrites==writes and atlasHookCount(panel.SettingsDropdown.Icon)==atlasHooks,
    "500 stable header paints issue no geometry setters or duplicate atlas hooks")
panel.SettingsDropdown.Icon:SetAtlas("native-hover")
check(inside(panel.SettingsDropdown.Icon),"native hover atlas sizing cannot extend the fitted icon outside the header")
panel.SessionDropdown:SetWidth(80)
check(panel.SessionDropdown:GetWidth()==18 and inside(panel.SessionDropdown),"native session width resets are repaired through a guarded widget posthook")
panel.CloseButton.shown=true; for _,fn in ipairs(panel.CloseButton.scriptHooks.OnShow or {}) do fn(panel.CloseButton) end
check(inside(panel.CloseButton) and panel.SettingsDropdown:GetLeft()+panel.SettingsDropdown:GetWidth()<=panel.CloseButton:GetLeft()-1/.8+1e-8,
    "a newly shown native Close button is packed without overlap")
packed.combat=true; writes=packed.geometryWrites; panel.SettingsDropdown.Icon:SetAtlas("combat-hover"); packed.skin:ApplyToWindow(panel,.8)
check(packed.geometryWrites==writes,"combat native art changes defer all header geometry setters")
panel.MinimizeButton:Show()
check(not panel.MinimizeButton:IsShown(),"an unprotected Minimize widget stays hidden when native code shows it in combat")
panel.MinimizeButton.protected=true;panel.MinimizeButton:Show()
check(panel.MinimizeButton:IsShown(),"protected combat visibility changes defer instead of attempting a forbidden hide")
packed.combat=false; refreshPacked()
check(inside(panel.SettingsDropdown.Icon) and not panel.MinimizeButton:IsShown(),"the existing combat-end service repairs pending art and protected visibility")
packed.combat=true;packed.skin:ReleaseAllNative()
check(not panel.MinimizeButton:IsShown(),"combat retirement defers restoring original Minimize visibility")
packed.combat=false;packed.skin:ReleaseAllNative()
check(panel.MinimizeButton:IsShown() and panel.MinimizeButton:GetWidth()==18 and panel.MinimizeButton:GetHeight()==19 and panel.SettingsDropdown:GetWidth()==27
    and panel.SessionDropdown:GetWidth()==18 and panel.DamageMeterTypeDropdown:GetWidth()==25,
    "out-of-combat cleanup restores original native button sizes")
panel.MinimizeButton:Hide();packed.skin:ApplyToWindow(panel,.8);packed.skin:ReleaseWindow(panel)
check(not panel.MinimizeButton:IsShown(),"cleanup preserves an originally hidden Minimize button")
check(normal:GetNumPoints()==oldNormalCount and normal:GetWidth()==18 and normal:GetHeight()==19
    and closeNormal:GetNumPoints()==0 and closeNormal:GetWidth()==32 and closeNormal:GetHeight()==32
    and panel.SessionDropdown.Background.points[1][4]==-7 and panel.SessionDropdown.Background.points[1][5]==7
    and panel.SessionDropdown.Arrow.points[1][5]==-5,
    "cleanup restores zero-point atlas regions and original padded/arrow anchors")
local retiredWrites=packed.geometryWrites; panel.SettingsDropdown.Icon:SetAtlas("retired-hover");refreshPacked()
check(packed.geometryWrites==retiredWrites,"retired atlas callbacks and header refresh perform no hidden geometry work")
check(panel.ResizeButton:GetWidth()==20 and panel.ResizeButton.points[1][1]=="BOTTOMRIGHT",
    "native body resize handle remains unchanged")
local sourcePanel=packed.window("source")
sourcePanel.CloseButton=button(nil,32,32,"TOPRIGHT",sourcePanel,"TOPRIGHT",-8,-8)
sourcePanel.MinimizeButton=button(nil,18,19,"TOPRIGHT",sourcePanel,"TOPRIGHT",-3,-5)
packed.skin:ApplyToWindow(sourcePanel,.8)
check(sourcePanel.CloseButton:GetWidth()==32 and sourcePanel.CloseButton.points[1][4]==-8
    and sourcePanel.MinimizeButton:IsShown(),"source drilldowns without a native Header retain their original controls")
print(string.format("native meter skin: %d checks, %d failures; no native secrets/rendering/taint emulated", checks, failures))
assert(failures == 0, "native meter skin regressions")
