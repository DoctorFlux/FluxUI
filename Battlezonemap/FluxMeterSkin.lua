-- Shared Flux meter presentation. Native meter data, layout and scripts stay native.
FluxMeterSkin = FluxMeterSkin or {}
local Skin = FluxMeterSkin

local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local FONT = "Fonts\\ARIALN.TTF"
local TITLE_FONT = "Fonts\\FRIZQT__.TTF"
local FALLBACK_FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local TITLE_COLOR = { r = 1, g = .82, b = 0 }
local HEADER_HEIGHT = 25.6 -- Native 32-unit header at the embedded root's .8 scale.
local fontStyles = setmetatable({}, { __mode = "k" })
local chrome = setmetatable({}, { __mode = "k" })
local nativeWindows = setmetatable({}, { __mode = "k" })
local ownedPanes = setmetatable({}, { __mode = "k" })
local themeHooked = false

local function PublicNumber(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "number"
end

local function Scale(value)
    return PublicNumber(value) and value > 0 and value or 1
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
        file = FALLBACK_FONT
        fontString:SetFont(file, size, "OUTLINE")
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

function Skin:StyleRowBackground(texture)
    if not texture or not texture.SetColorTexture then return end
    texture:SetColorTexture(.619607, .619607, .619607, .116164)
    if texture.SetAlpha then texture:SetAlpha(1) end
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

local function MakeRail(frame, first, second, vertical, width)
    local rail = frame:CreateTexture(nil, "BORDER")
    rail:SetTexture(BAR_TEXTURE)
    rail:SetPoint(first, frame, first, 0, 0)
    rail:SetPoint(second, frame, second, 0, 0)
    if vertical then rail:SetWidth(width) else rail:SetHeight(width) end
    return rail
end

local function EnsureChrome(frame, scale)
    local state = chrome[frame]
    if not state then
        state = {}
        if frame.CreateTexture then
            local width = 2 / scale
            state.rails = {
                MakeRail(frame, "TOPLEFT", "TOPRIGHT", false, width),
                MakeRail(frame, "BOTTOMLEFT", "BOTTOMRIGHT", false, width),
                MakeRail(frame, "TOPLEFT", "BOTTOMLEFT", true, width),
                MakeRail(frame, "TOPRIGHT", "BOTTOMRIGHT", true, width),
            }
        end
        chrome[frame] = state
    end
    if state.scale ~= scale and state.rails then
        state.rails[1]:SetHeight(2 / scale); state.rails[2]:SetHeight(2 / scale)
        state.rails[3]:SetWidth(2 / scale); state.rails[4]:SetWidth(2 / scale)
    end
    state.scale = scale
    local header = frame.Header
    if header and header.SetTexture then
        if state.header ~= header then state.header = header; state.r = nil end
    elseif header and header.CreateTexture and not state.header then
        state.header = header:CreateTexture(nil, "BACKGROUND")
        state.header:SetAllPoints(header)
    end
    return state
end

local function TintChrome(frame, state)
    local r, g, b = ThemeColor()
    if state.r ~= r or state.g ~= g or state.b ~= b then
        if state.rails then
            for _, rail in ipairs(state.rails) do rail:SetVertexColor(r, g, b, .95) end
        end
        if state.header then
            state.header:SetTexture(BAR_TEXTURE)
            state.header:SetVertexColor(r * .4, g * .4, b * .4, .95)
        end
        state.r, state.g, state.b = r, g, b
    end
    if state.rails then for _, rail in ipairs(state.rails) do rail:Show() end end
    if state.ownedHeader then state.header:Show() end
    if state.background then state.background:Show() end
    local background = state.background or (frame.GetBackground and frame:GetBackground() or frame.Background)
    if background and background.SetColorTexture then
        background:SetColorTexture(.0941, .0941, .0941, .70)
        -- Native UpdateBackground changes this separate multiplier. Keep the
        -- embedded paint consistent without changing its saved preference.
        if background.SetAlpha then background:SetAlpha(1) end
    end
end

local function EnsureThemeHook()
    if themeHooked or not (FluxBorder and FluxBorder.RefreshAppearanceDependents and hooksecurefunc) then return end
    themeHooked = true
    -- One shared appearance hook; no native entry hooks, frame events or timers.
    hooksecurefunc(FluxBorder, "RefreshAppearanceDependents", function() Skin:RefreshTheme() end)
end

function Skin:ApplyToWindow(window, scale)
    if not window then return end
    scale = Scale(scale)
    local state = EnsureChrome(window, scale)
    nativeWindows[window] = true
    TintChrome(window, state)
    StyleTitle(window.GetDamageMeterTypeName and window:GetDamageMeterTypeName(), 12 / scale)
    StyleTitle(window.GetSessionName and window:GetSessionName(), 12 / scale)
    StyleTitle(window.GetSessionTimerFontString and window:GetSessionTimerFontString(), 12 / scale)
    local container = window.MinimizeContainer
    self:StyleFont(container and container.NotActive, 12 / scale)
    EnsureThemeHook()
end

function Skin:ApplyToOwnedPane(frame, title, scale)
    if not frame then return end
    scale = Scale(scale)
    local state = EnsureChrome(frame, scale)
    if not state.header and frame.CreateTexture then
        state.header = frame:CreateTexture(nil, "BACKGROUND")
        state.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        state.header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        state.ownedHeader = true
        state.r = nil
    end
    if state.ownedHeader then state.header:SetHeight(HEADER_HEIGHT / scale) end
    if not state.background and not frame.GetBackground and not frame.Background and frame.CreateTexture then
        state.background = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
        state.background:SetAllPoints(frame)
    end
    ownedPanes[frame] = true
    TintChrome(frame, state)
    local text = frame.Title or frame.HeaderTitle
    if not text and frame.CreateFontString then
        text = frame:CreateFontString(nil, "OVERLAY")
        text:SetPoint("LEFT", frame, "TOPLEFT", 6 / scale, -HEADER_HEIGHT / (2 * scale))
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
    if state and state.rails then for _, rail in ipairs(state.rails) do rail:Hide() end end
    if state and state.ownedHeader then state.header:Hide() end
    if state and state.background then state.background:Hide() end
    -- Native initialization/reload restores native paint; never rewrite its scripts.
end

function Skin:ReleaseAllNative()
    for window in pairs(nativeWindows) do self:ReleaseWindow(window) end
end
