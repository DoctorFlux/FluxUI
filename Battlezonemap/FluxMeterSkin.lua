-- Shared Flux meter presentation. Native meter data, layout and scripts stay native.
FluxMeterSkin = FluxMeterSkin or {}
local Skin = FluxMeterSkin

local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local FONT = "Interface\\AddOns\\Details\\fonts\\Accidental Presidency.ttf"
local ROW_FALLBACK_FONT = "Fonts\\ARIALN.TTF"
local TITLE_FONT = "Fonts\\FRIZQT__.TTF"
local FALLBACK_FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local TITLE_COLOR = { r = 1, g = .82, b = 0 }
-- Details paints Ground twice at .70 opacity; one identical-gray layer is equivalent.
local PANEL_ALPHA = 1 - (1 - .70) ^ 2
Skin.HEADER_HEIGHT = 14
local HEADER_HEIGHT = Skin.HEADER_HEIGHT
local NATIVE_SCROLL_TOP_OFFSET = 2 -- Native ScrollBox TOPLEFT is Header.BOTTOMLEFT y=-2.
local fontStyles = setmetatable({}, { __mode = "k" })
local chrome = setmetatable({}, { __mode = "k" })
local nativeWindows = setmetatable({}, { __mode = "k" })
local ownedPanes = setmetatable({}, { __mode = "k" })
local panelPainted = setmetatable({}, { __mode = "k" })
local themeHooked = false
local timerOrder = 0
local TIMER_RESERVE = 45 -- Display units; leave native timer text and updates alone.
local DETAILS_ATLAS = "Interface\\AddOns\\Details\\images\\skins\\default_skin"
local PANEL_TEXTURE = "Interface\\AddOns\\Details\\images\\background"
local ROW_TEXTURE = "Interface\\AddOns\\Details\\images\\bar_background"
local assetsChecked, atlasPath, panelPath, rowPath = false, nil, nil, nil

local function ResolveAssets(texture)
    if assetsChecked then return end
    assetsChecked = true
    local function find(path)
        for _, suffix in ipairs({".tga", ".blp", ""}) do
            if texture:SetTexture(path .. suffix) == true then return path .. suffix end
        end
    end
    atlasPath, panelPath, rowPath = find(DETAILS_ATLAS), find(PANEL_TEXTURE), find(ROW_TEXTURE)
end

local function PublicNumber(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "number"
end

local function Scale(value)
    return PublicNumber(value) and value > 0 and value < math.huge and value or 1
end

local function ThemeColor()
    if FluxBorder and FluxBorder.GetThemedVertexRGB then
        local r, g, b = FluxBorder:GetThemedVertexRGB()
        if PublicNumber(r) and PublicNumber(g) and PublicNumber(b) then return r, g, b end
    end
    local class
    if UnitClass then local _, filename = UnitClass("player"); class = filename end
    if issecretvalue and issecretvalue(class) then class = nil end
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return .6, .6, .6
end

local function SingleLine(fontString)
    -- These public widget flags do not inspect secret text or its dimensions.
    if fontString.SetWordWrap and (not fontString.CanWordWrap or fontString:CanWordWrap()) then
        fontString:SetWordWrap(false)
    end
    if fontString.SetNonSpaceWrap and (not fontString.CanNonSpaceWrap or fontString:CanNonSpaceWrap()) then
        fontString:SetNonSpaceWrap(false)
    end
end

local function ApplyFont(fontString, size, preferred)
    if not fontString or not fontString.SetFont then return end
    SingleLine(fontString)
    size = PublicNumber(size) and size > 0 and size or 14
    local previous = fontStyles[fontString]
    if previous and previous.size == size and previous.preferred == preferred and fontString.GetFont then
        local file, currentSize, flags = fontString:GetFont()
        if not (issecretvalue and (issecretvalue(file) or issecretvalue(flags)))
            and PublicNumber(currentSize) and file == previous.file and currentSize == size and flags == "OUTLINE" then
            return
        end
    end
    local file = preferred
    if fontString:SetFont(file, size, "OUTLINE") == false then
        file = preferred == FONT and ROW_FALLBACK_FONT or FALLBACK_FONT
        if fontString:SetFont(file, size, "OUTLINE") == false and file ~= FALLBACK_FONT then
            file = FALLBACK_FONT
            fontString:SetFont(file, size, "OUTLINE")
        end
    end
    if fontString.SetShadowColor then fontString:SetShadowColor(0, 0, 0, 1) end
    if fontString.SetShadowOffset then fontString:SetShadowOffset(1, -1) end
    if not previous then previous = {}; fontStyles[fontString] = previous end
    previous.file, previous.size, previous.preferred = file, size, preferred
end

function Skin:StyleFont(fontString, size)
    ApplyFont(fontString, size, FONT)
end

local function StyleTitle(fontString, size)
    ApplyFont(fontString, size, TITLE_FONT)
    local color = NORMAL_FONT_COLOR or TITLE_COLOR
    if fontString and fontString.SetTextColor then fontString:SetTextColor(color.r, color.g, color.b, 1) end
end

function Skin:StyleTitleFont(fontString, size)
    StyleTitle(fontString, size)
end

function Skin:StyleRowBackground(texture)
    if not texture or not texture.SetColorTexture then return end
    if rowPath then
        texture:SetTexture(rowPath)
        texture:SetVertexColor(.619607, .619607, .619607)
    else
        texture:SetColorTexture(.619607, .619607, .619607, 1)
    end
    if texture.SetAlpha then texture:SetAlpha(.116164) end
end

function Skin:ApplyToEntry(entry, scale)
    if not entry then return end
    local size = 14 / Scale(scale)
    local name = entry.GetName and entry:GetName()
    local value = entry.GetValue and entry:GetValue()
    self:StyleFont(name, size)
    self:StyleFont(value, size)
    -- Existing integration owns local-player name tint; leave that color alone.
    if value and value.SetTextColor then value:SetTextColor(1, 1, 1, 1) end
    local bar = entry.GetStatusBar and entry:GetStatusBar()
    if bar and bar.SetStatusBarTexture then bar:SetStatusBarTexture(BAR_TEXTURE) end
    local background = entry.GetBackground and entry:GetBackground()
    self:StyleRowBackground(background)
    local edge = entry.GetBackgroundEdge and entry:GetBackgroundEdge()
    if edge and edge.SetAlpha then edge:SetAlpha(0) end
end

-- Details' WoW Interface atlas includes transparent padding. Keep its source
-- density and body-relative anchors; shrinking a 128-unit region crushes the art.
local PIECES = {
    {"headerLeft", "OVERLAY", {.44921875, .5732421875, .08203125, .2060546875}, 128, 128},
    {"headerConnector", "BACKGROUND", {.58837890625, .5947265625, .08203125, .2060546875}, 8, 128},
    {"headerRight", "BACKGROUND", {.3154296875, .439453125, .08203125, .2060546875}, 128, 128},
    {"headerStrip", "BACKGROUND", {.15625, .6552734375, .22265625, .3466796875}, nil, 128},
    {"left", "ARTWORK", {.765625, .828125, .001953125, .501953125}, 64},
    {"right", "ARTWORK", {.7001953125, .7626953125, .001953125, .501953125}, 64},
    {"bottom", "ARTWORK", {.32861328125, .82666015625, .50537109375, .56494140625}, nil, 64},
    {"footerLeft", "OVERLAY", {.00146484375, .03076171875, .30126953125, .33056640625}, 32, 32},
    {"footerRight", "OVERLAY", {.03564453125, .06494140625, .30126953125, .33056640625}, 32, 32},
}

local function InCombat()
    return InCombatLockdown and InCombatLockdown() or false
end

local function FiniteNumber(value)
    return PublicNumber(value) and value == value and value > -math.huge and value < math.huge
end

local function RestoreHeader(state)
    if state.nativeHeader then
        state.nativeHeader:SetAlpha(state.headerAlpha)
        if state.headerHeight then
            if InCombat() then return false end
            state.nativeHeader:SetHeight(state.headerHeight)
        end
    end
    state.nativeHeader, state.headerAlpha, state.headerHeight = nil, nil, nil
    return true
end

local function StyleNativeHeader(frame, state, scale, suppress)
    local header = frame.Header
    if header and header.SetTexture and header.SetAlpha then
        if state.nativeHeader ~= header then
            if not RestoreHeader(state) then return end
            -- Preserve even an opaque alpha by passing it back to the native
            -- display setter on release, without inspecting or comparing it.
            if header.GetAlpha then state.headerAlpha = header:GetAlpha()
            else state.headerAlpha = 1 end
            state.nativeHeader = header
        end
        if suppress then header:SetAlpha(0) end
        if not InCombat() and header.GetHeight and header.SetHeight then
            if not state.headerHeight then
                local height = header:GetHeight()
                if FiniteNumber(height) and height > 0 then state.headerHeight = height end
            end
            local target = HEADER_HEIGHT / scale - NATIVE_SCROLL_TOP_OFFSET
            if state.headerHeight and target > 0 then
                local current = header:GetHeight()
                if FiniteNumber(current) and current ~= target then header:SetHeight(target) end
            end
        end
    end
end

local function LayoutChrome(frame, state, scale, hasHeader)
    if state.scale == scale and state.hasHeader == hasHeader then return end
    state.scale, state.hasHeader = scale, hasHeader
    local u, p = 1 / scale, state.parts
    if #p == 0 then return end
    for _, part in ipairs(p) do part:ClearAllPoints() end
    if state.details then
        for i, spec in ipairs(PIECES) do
            if spec[4] then p[i]:SetWidth(spec[4] * u) end
            if spec[5] then p[i]:SetHeight(spec[5] * u) end
        end
        local top = hasHeader and -HEADER_HEIGHT * u or 0
        p[1]:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -107 * u, top)
        p[2]:SetPoint("BOTTOMLEFT", p[1], "BOTTOMRIGHT", 0, 0)
        p[3]:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 96 * u, top)
        p[4]:SetPoint("LEFT", p[2], "RIGHT", 0, 0); p[4]:SetPoint("RIGHT", p[3], "LEFT", 0, 0)
        p[5]:SetPoint("TOPLEFT", frame, "TOPLEFT", -56 * u, top)
        p[5]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -56 * u, 0)
        p[6]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 56 * u, top)
        p[6]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 56 * u, 0)
        p[7]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, -56 * u)
        p[7]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -u, -56 * u)
        p[8]:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", 16 * u, 14 * u)
        p[9]:SetPoint("TOPLEFT", frame, "BOTTOMRIGHT", -16 * u, 14 * u)
    else
        local points = {{"TOPLEFT", "TOPRIGHT"}, {"BOTTOMLEFT", "BOTTOMRIGHT"},
            {"TOPLEFT", "BOTTOMLEFT"}, {"TOPRIGHT", "BOTTOMRIGHT"}}
        for i, anchors in ipairs(points) do
            p[i]:SetPoint(anchors[1], frame, anchors[1], 0, 0)
            p[i]:SetPoint(anchors[2], frame, anchors[2], 0, 0)
            if i < 3 then p[i]:SetHeight(2 * u) else p[i]:SetWidth(2 * u) end
        end
    end
end

local function EnsureChrome(frame, scale, owned)
    local state = chrome[frame]
    if not state then
        state = {parts = {}}
        local paintOwner = not owned and frame.MinimizeContainer or frame
        if paintOwner and paintOwner.CreateTexture then
            local first = paintOwner:CreateTexture(nil, "OVERLAY")
            ResolveAssets(first)
            state.details = atlasPath ~= nil
            state.parts[1] = first
            local count = state.details and #PIECES or 4
            for i = 1, count do
                local spec = state.details and PIECES[i]
                local layer = spec and spec[2] or "BORDER"
                -- Native inline Background is BACKGROUND0; its header art needs
                -- a distinct higher layer. Owned/source Details roles stay intact.
                if paintOwner ~= frame and layer == "BACKGROUND" then layer = "BORDER" end
                local part = state.parts[i] or paintOwner:CreateTexture(nil, layer, nil, 0)
                state.parts[i] = part
                if part.SetDrawLayer then part:SetDrawLayer(layer, 0) end
                part:SetTexture(state.details and atlasPath or BAR_TEXTURE)
                if spec then part:SetTexCoord(unpack(spec[3])) end
            end
        end
        chrome[frame] = state
    end
    LayoutChrome(frame, state, scale, owned or frame.Header ~= nil)
    StyleNativeHeader(frame, state, scale, state.details)
    return state
end

local function TintChrome(frame, state)
    local r, g, b = ThemeColor()
    if state.r ~= r or state.g ~= g or state.b ~= b then
        for _, part in ipairs(state.parts) do part:SetVertexColor(r, g, b, 1) end
        state.r, state.g, state.b = r, g, b
    end
    for _, part in ipairs(state.parts) do part:Show() end
    if state.background then state.background:Show() end
    local background = state.background or (frame.GetBackground and frame:GetBackground() or frame.Background)
    if background then
        if not panelPainted[background] then
            if panelPath then
                background:SetTexture(panelPath)
                background:SetVertexColor(.0941, .0941, .0941)
            elseif background.SetColorTexture then background:SetColorTexture(.0941, .0941, .0941, 1) end
            panelPainted[background] = true
        end
        if background.SetAlpha then background:SetAlpha(PANEL_ALPHA) end
    end
end

local function PlainTrue(value)
    return not (issecretvalue and issecretvalue(value)) and value == true
end

local function RestoreTitle(state)
    if state.titlePoints then
        if InCombat() then return false end
        state.titleApplying = true
        state.titleFont:ClearAllPoints()
        state.titleFont:SetWidth(state.titleOriginalWidth)
        for _, point in ipairs(state.titlePoints) do
            state.titleFont:SetPoint(point[1], point[2], point[3], point[4], point[5])
        end
        state.titleApplying = false
    end
    state.titleFont, state.titlePoints, state.titleOriginalWidth = nil, nil, nil
    state.titleScale, state.titleWidth, state.titleHeader = nil, nil, nil
    return true
end

local function RestoreTimerLayout(state)
    if not state.timerPoints then return true end
    if InCombat() then return false end
    state.timerFont:ClearAllPoints()
    state.timerFont:SetWidth(state.timerWidth)
    for _, point in ipairs(state.timerPoints) do
        state.timerFont:SetPoint(point[1], point[2], point[3], point[4], point[5])
    end
    if state.timerControlPoints then
        state.timerControl:ClearAllPoints()
        for _, point in ipairs(state.timerControlPoints) do
            state.timerControl:SetPoint(point[1], point[2], point[3], point[4], point[5])
        end
    end
    state.timerPoints, state.timerWidth = nil, nil
    state.timerControl, state.timerControlPoints = nil, nil
    state.timerLayoutWidth, state.timerLayoutScale, state.timerLayoutHeader = nil, nil, nil
    state.timerBoxWidth = nil
    return true
end

local function PublicPoints(region)
    if not (region and region.GetNumPoints and region.GetPoint and region.ClearAllPoints and region.SetPoint) then return end
    local count = region:GetNumPoints()
    if not FiniteNumber(count) or count < 1 or count > 8 then return end
    local points = {}
    for i = 1, count do
        local point = {region:GetPoint(i)}
        for j = 1, 5 do if issecretvalue and issecretvalue(point[j]) then return end end
        if type(point[1]) ~= "string" or type(point[3]) ~= "string"
            or not FiniteNumber(point[4]) or not FiniteNumber(point[5]) then return end
        points[i] = point
    end
    return points
end

local function AlignTitle(frame, state, scale)
    if InCombat() then return end
    local text = frame.GetDamageMeterTypeName and frame:GetDamageMeterTypeName()
    if not (text and frame.Header and text.GetNumPoints and text.GetPoint and text.GetWidth
        and text.SetWidth and text.ClearAllPoints and text.SetPoint and frame.GetLeft and frame.GetEffectiveScale) then return end
    if frame.HookScript and not state.titleHooked then
        state.titleHooked = true
        frame:HookScript("OnSizeChanged", function()
            if nativeWindows[frame] and not state.titleApplying then AlignTitle(frame, state, state.scale) end
        end)
    end
    local points, originalWidth = state.titlePoints, state.titleOriginalWidth
    if state.titleFont ~= text then
        if not RestoreTitle(state) then return end
        local count = text:GetNumPoints()
        originalWidth = text:GetWidth()
        if not FiniteNumber(count) or count < 1 or count > 8 or not FiniteNumber(originalWidth) or originalWidth <= 0 then return end
        points = {}
        for i = 1, count do
            local point = {text:GetPoint(i)}
            for j = 1, 5 do
                if issecretvalue and issecretvalue(point[j]) then return end
            end
            if type(point[1]) ~= "string" or type(point[3]) ~= "string"
                or (type(point[2]) ~= "table" and type(point[2]) ~= "userdata")
                or not FiniteNumber(point[4]) or not FiniteNumber(point[5]) then return end
            points[i] = point
        end
    end
    local right
    for _, point in ipairs(points) do
        if point[1] == "RIGHT" and point[3] == "LEFT" then right = point end
    end
    local relative = right and right[2]
    if not (relative and relative.GetLeft and relative.GetEffectiveScale) then return end
    local left, frameScale = frame:GetLeft(), frame:GetEffectiveScale()
    local rightLeft, rightScale = relative:GetLeft(), relative:GetEffectiveScale()
    if not FiniteNumber(left) or not FiniteNumber(rightLeft) or not FiniteNumber(frameScale)
        or not FiniteNumber(rightScale) or frameScale <= 0 or rightScale <= 0 then return end
    local width = (rightLeft * rightScale - left * frameScale) / frameScale + right[4] - 5 / scale
    if not FiniteNumber(width) or width <= 0 then return end
    local timer = state.timerTracked and state.timerFont
    if timer and timer.GetWidth and timer.SetWidth then
        if not state.timerPoints then
            local saved, controlPoints = PublicPoints(timer), PublicPoints(frame.DamageMeterTypeDropdown)
            local timerWidth = timer:GetWidth()
            if saved and controlPoints and FiniteNumber(timerWidth) then
                state.timerPoints, state.timerWidth = saved, timerWidth
                state.timerControl, state.timerControlPoints = frame.DamageMeterTypeDropdown, controlPoints
            end
        end
        if state.timerPoints then
            local reserve = math.min(TIMER_RESERVE / scale, width * .8)
            width = width - reserve
            local gap = math.min(5 / scale, reserve * .25)
            local boxWidth = reserve - gap
            if state.timerLayoutWidth ~= width or state.timerLayoutScale ~= scale
                or state.timerLayoutHeader ~= frame.Header or state.timerBoxWidth ~= boxWidth then
                state.timerLayoutWidth, state.timerLayoutScale, state.timerLayoutHeader = width, scale, frame.Header
                state.timerBoxWidth = boxWidth
                -- A fixed box on every header keeps combat-time election paint-only.
                -- Native type-dropdown hit geometry must not follow the moved timer.
                state.timerControl:ClearAllPoints()
                state.timerControl:SetPoint("TOPLEFT", frame.Header, "TOPLEFT", 1, -3)
                timer:ClearAllPoints()
                timer:SetWidth(boxWidth)
                timer:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", width + 5 / scale + gap, -(HEADER_HEIGHT - 1) / scale)
            end
        end
    end
    state.titleFont, state.titlePoints, state.titleOriginalWidth = text, points, originalWidth
    if state.titleScale == scale and state.titleWidth == width and state.titleHeader == frame.Header then return end
    state.titleScale, state.titleWidth, state.titleHeader = scale, width, frame.Header
    state.titleApplying = true
    text:ClearAllPoints()
    text:SetWidth(width)
    -- One vertical anchor prevents the native RIGHT point from recentering text.
    text:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 5 / scale, -(HEADER_HEIGHT - 1) / scale)
    state.titleApplying = false
end

local function SetMenuVisible(state, shown)
    if state.menuVisible == shown then return end
    state.menuVisible = shown
    for _, item in ipairs(state.menuRegions or {}) do
        local alpha = 0
        if shown and not item.alwaysHidden then alpha = PublicNumber(item.alpha) and item.alpha * .92 or item.alpha end
        item.region:SetAlpha(alpha)
    end
end

local function InstallMenuHover(frame, state)
    if not state.menuRegions then
        state.menuRegions, state.menuControls = {}, {}
        state.hoverHooked = state.hoverHooked or {}
        local seen = {}
        local function region(texture, alwaysHidden)
            if not texture or not texture.SetAlpha or seen[texture] then return end
            seen[texture] = true
            local alpha = 1
            if texture.GetAlpha then alpha = texture:GetAlpha() end
            state.menuRegions[#state.menuRegions + 1] = {region = texture, alpha = alpha, alwaysHidden = alwaysHidden}
        end
        local function sync()
            if not nativeWindows[frame] then return end
            local over = frame.IsMouseOver and PlainTrue(frame:IsMouseOver()) or false
            for _, button in ipairs(state.menuControls) do
                if button.IsMenuOpen and PlainTrue(button:IsMenuOpen()) then over = true end
            end
            SetMenuVisible(state, over)
        end
        local function control(button)
            if not button then return end
            state.menuControls[#state.menuControls + 1] = button
            if state.hoverHooked[button] then return end
            state.hoverHooked[button] = true
            if button.HookScript then button:HookScript("OnEnter", sync); button:HookScript("OnLeave", sync) end
            for _, method in ipairs({"OnMenuOpened", "OnMenuClosed"}) do
                if type(button[method]) == "function" then hooksecurefunc(button, method, sync) end
            end
        end
        if frame.HookScript and not state.hoverHooked[frame] then
            state.hoverHooked[frame] = true
            frame:HookScript("OnEnter", sync); frame:HookScript("OnLeave", sync)
        end
        local kind, session, settings = frame.DamageMeterTypeDropdown, frame.SessionDropdown, frame.SettingsDropdown
        control(kind); if kind then region(kind.Arrow, true) end
        control(session)
        if session then region(session.Background); region(session.Arrow); region(session.Text); region(session.SessionName) end
        control(settings); if settings then region(settings.Icon) end
        for _, name in ipairs({"MinimizeButton", "CloseButton", "ResizeButton"}) do
            local button = frame[name]; control(button)
            if button then
                for _, method in ipairs({"GetNormalTexture", "GetPushedTexture", "GetHighlightTexture"}) do
                    if button[method] then region(button[method](button)) end
                end
            end
        end
        state.syncMenu = sync
    end
    state.menuVisible = nil -- Font repaint may have restored a menu label alpha.
    state.syncMenu()
end

local function RestoreMenu(state)
    for _, item in ipairs(state.menuRegions or {}) do item.region:SetAlpha(item.alpha) end
    state.menuRegions, state.menuControls, state.menuVisible = nil, nil, nil
end

local function EnsureThemeHook()
    if themeHooked or not (FluxBorder and FluxBorder.RefreshAppearanceDependents and hooksecurefunc) then return end
    themeHooked = true
    -- One shared appearance hook; no native entry hooks, frame events or timers.
    hooksecurefunc(FluxBorder, "RefreshAppearanceDependents", function() Skin:RefreshTheme() end)
end

function Skin:SyncNativeTimer()
    local winner, winnerTop, winnerLeft
    for window in pairs(nativeWindows) do
        local state = chrome[window]
        if state.timerTracked and window.IsVisible and PlainTrue(window:IsVisible()) then
            local top = window.GetTop and window:GetTop()
            local left = window.GetLeft and window:GetLeft()
            local scale = window.GetEffectiveScale and window:GetEffectiveScale()
            local readable = FiniteNumber(top) and FiniteNumber(left) and FiniteNumber(scale) and scale > 0
            top, left = readable and top * scale or -math.huge, readable and left * scale or math.huge
            if not winner or top > winnerTop or (top == winnerTop and (left < winnerLeft
                or (left == winnerLeft and state.timerOrder < chrome[winner].timerOrder))) then
                winner, winnerTop, winnerLeft = window, top, left
            end
        end
    end
    for window in pairs(nativeWindows) do
        local state = chrome[window]
        if state.timerTracked then state.timerFont:SetAlpha(window == winner and state.timerAlpha or 0) end
    end
end

local function TrackTimer(window, state)
    if state.timerTracked or not window.GetSessionTimerFontString then return end
    local timer = window:GetSessionTimerFontString()
    if not (timer and timer.GetAlpha and timer.SetAlpha) then return end
    local alpha = timer:GetAlpha()
    if not FiniteNumber(alpha) then return end
    timerOrder = timerOrder + 1
    state.timerFont, state.timerAlpha, state.timerOrder = timer, alpha, timerOrder
    state.timerTracked = true
    if window.HookScript and not state.timerHooked then
        state.timerHooked = true
        for _, event in ipairs({"OnShow", "OnHide", "OnSizeChanged"}) do
            window:HookScript(event, function() if nativeWindows[window] then Skin:SyncNativeTimer() end end)
        end
    end
end

function Skin:ApplyToWindow(window, scale)
    if not window then return end
    scale = Scale(scale)
    local state = EnsureChrome(window, scale)
    state.nativeWindow = true
    nativeWindows[window] = true
    TrackTimer(window, state)
    TintChrome(window, state)
    AlignTitle(window, state, scale)
    StyleTitle(window.GetDamageMeterTypeName and window:GetDamageMeterTypeName(), 12 / scale)
    StyleTitle(window.GetSessionName and window:GetSessionName(), 12 / scale)
    StyleTitle(window.GetSessionTimerFontString and window:GetSessionTimerFontString(), 12 / scale)
    local container = window.MinimizeContainer
    self:StyleFont(container and container.NotActive, 12 / scale)
    InstallMenuHover(window, state)
    EnsureThemeHook()
    self:SyncNativeTimer()
end

function Skin:ApplyToOwnedPane(frame, title, scale)
    if not frame then return end
    scale = Scale(scale)
    local state = EnsureChrome(frame, scale, true)
    if not state.background and not frame.GetBackground and not frame.Background and frame.CreateTexture then
        state.background = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
        state.background:SetAllPoints(frame)
    end
    ownedPanes[frame] = true
    TintChrome(frame, state)
    local text = frame.Title or frame.HeaderTitle
    if not text and frame.CreateFontString then
        text = frame:CreateFontString(nil, "OVERLAY")
        text:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 5 / scale, -(HEADER_HEIGHT - 1) / scale)
        frame.HeaderTitle = text
    end
    StyleTitle(text, 12 / scale)
    if text then
        if title and state.title ~= title and text.SetText then text:SetText(title); state.title = title end
    end
    EnsureThemeHook()
end

function Skin:RefreshTheme()
    for frame in pairs(nativeWindows) do TintChrome(frame, chrome[frame]) end
    for frame in pairs(ownedPanes) do TintChrome(frame, chrome[frame]) end
end

function Skin:ReleaseWindow(window)
    if not window then return end
    nativeWindows[window], ownedPanes[window] = nil, nil
    local state = chrome[window]
    if state then
        for _, part in ipairs(state.parts) do part:Hide() end
        RestoreHeader(state)
        RestoreTitle(state)
        RestoreTimerLayout(state)
        if state.timerTracked then
            state.timerFont:SetAlpha(state.timerAlpha)
            state.timerTracked = false
        end
        RestoreMenu(state)
    end
    if state and state.background then state.background:Hide() end
    local background = state and state.background or (window.GetBackground and window:GetBackground() or window.Background)
    if background then panelPainted[background] = nil end
    self:SyncNativeTimer()
    -- Native initialization/reload restores native paint; never rewrite its scripts.
end

function Skin:ReleaseAllNative()
    -- Combat cleanup retires callbacks immediately; the existing out-of-combat
    -- cleanup pass revisits saved geometry even after active membership is gone.
    for window, state in pairs(chrome) do
        if state.nativeWindow then self:ReleaseWindow(window) end
    end
end
