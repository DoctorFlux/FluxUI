-- Hotkey.lua — mouse / scroll / space glyphs (backup Texture\*.tga) + S-/C- paging prefix.
local addonName, ns = ...
local Flux = ns.Flux

local Hotkey = {}
Flux.Hotkey = Hotkey

Hotkey.ICON_SIZE = 14
local TEX = "Interface\\AddOns\\" .. addonName .. "\\Texture\\"

local PATHS = {
	BUTTON3 = TEX .. "MouseButton3.tga",
	BUTTON4 = TEX .. "MouseButton4.tga",
	BUTTON5 = TEX .. "MouseButton5.tga",
	MOUSEWHEELUP = TEX .. "MouseScrollUp.tga",
	MOUSEWHEELDOWN = TEX .. "MouseScrollDown.tga",
	WU = TEX .. "MouseScrollUp.tga",
	WD = TEX .. "MouseScrollDown.tga",
	SPACE = TEX .. "SpaceBarButton.tga",
	SP = TEX .. "SpaceBarButton.tga",
}

-- Full TGA dimensions are required before inline-texture RGB fields. Keep the
-- original uncropped artwork and geometry; multiplication preserves black ink.
local SOURCE_SIZE = {
	[PATHS.BUTTON3] = { 32, 80 }, [PATHS.BUTTON4] = { 32, 80 }, [PATHS.BUTTON5] = { 32, 80 },
	[PATHS.MOUSEWHEELUP] = { 8, 20 }, [PATHS.MOUSEWHEELDOWN] = { 8, 20 }, [PATHS.SPACE] = { 48, 48 },
}
local RANGE_R, RANGE_G, RANGE_B = 1, 0.1, 0.1

local ABBREV = {
	NUMPAD0 = "N0", NUMPAD1 = "N1", NUMPAD2 = "N2", NUMPAD3 = "N3",
	NUMPAD4 = "N4", NUMPAD5 = "N5", NUMPAD6 = "N6", NUMPAD7 = "N7",
	NUMPAD8 = "N8", NUMPAD9 = "N9", NUMPADPLUS = "N+", NUMPADMINUS = "N-",
	NUMPADMULTIPLY = "N*", NUMPADDIVIDE = "N/", NUMPADPERIOD = "N.",
	PAGEUP = "PU", PAGEDOWN = "PD", INSERT = "INS", HOME = "HM", DELETE = "DEL",
}

function Hotkey.Path(token)
	if not token then
		return nil
	end
	return PATHS[string.upper(token)]
end

function Hotkey.Markup(path, size, width, r, g, b)
	if not path then
		return ""
	end
	size = size or Hotkey.ICON_SIZE
	width = width or size
	size = math.max(1, math.floor(size + 0.5))
	width = math.max(1, math.floor(width + 0.5))
	local source = SOURCE_SIZE[path]
	if source and type(r) == "number" and type(g) == "number" and type(b) == "number" then
		return ("|T%s:%d:%d:0:-1:%d:%d:0:%d:0:%d:%d:%d:%d|t"):format(path, size, width,
			source[1], source[2], source[1], source[2], r, g, b)
	end
	return ("|T%s:%d:%d:0:-1|t"):format(path, size, width)
end

-- Tint only our known key glyphs, leaving unrelated texture markup alone.
-- Base strings remain unmodified so returning in range restores white art.
local function RedGlyphs(text)
	return (text:gsub("|T([^|]+)|t", function(body)
		local path, height, width, x, y = body:match("^([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
		local source = path and SOURCE_SIZE[path]
		if not source then return "|T" .. body .. "|t" end
		return ("|T%s:%s:%s:%s:%s:%d:%d:0:%d:0:%d:255:26:26|t"):format(path,
			height, width, x, y, source[1], source[2], source[1], source[2])
	end))
end

function Hotkey.IsOutOfRange(fontString)
	return fontString and fontString._fluxHotkeyOutOfRange == true or false
end

function Hotkey.SetText(fontString, text)
	if not fontString then return end
	if issecretvalue and issecretvalue(text) then return end
	text = text == nil and "" or tostring(text)
	fontString._fluxHotkeyBaseText = text
	local shown = Hotkey.IsOutOfRange(fontString) and RedGlyphs(text) or text
	if fontString._fluxHotkeyRendered ~= shown then
		fontString._fluxHotkeyRendered = shown
		fontString:SetText(shown)
	end
end

-- Callers reuse their existing public range decision; no range probe or timer.
-- Font preparation may reset text color, so it can explicitly force a refresh.
function Hotkey.SetRange(fontString, outOfRange, forceColor)
	if not fontString then return end
	if issecretvalue and issecretvalue(outOfRange) then return end
	outOfRange = outOfRange == true
	local changed = fontString._fluxHotkeyOutOfRange ~= outOfRange
	if not changed and not forceColor then return end
	fontString._fluxHotkeyOutOfRange = outOfRange
	if outOfRange then
		fontString:SetTextColor(RANGE_R, RANGE_G, RANGE_B)
	else
		fontString:SetTextColor(0.75, 0.75, 0.75)
	end
	local base = fontString._fluxHotkeyBaseText
	if base == nil and fontString.GetText then
		local value = fontString:GetText()
		if not issecretvalue or not issecretvalue(value) then base = value end
	end
	Hotkey.SetText(fontString, base or "")
end

function Hotkey.IconFor(token, size, width)
	return Hotkey.Markup(Hotkey.Path(token), size, width)
end

-- Backup paging: Shift alone when both held, else Ctrl. Alt does not prefix.
function Hotkey.LivePrefix()
	if IsShiftKeyDown and IsShiftKeyDown() then
		return "S-"
	end
	if IsControlKeyDown and IsControlKeyDown() then
		return "C-"
	end
	return ""
end

-- display, isIcon, bindPrefix (S-/C-/A- already on the chord).
function Hotkey.Format(key, size, width)
	if not key or key == "" then
		return "", false, ""
	end
	local parts = {}
	for part in string.gmatch(key, "[^-]+") do
		parts[#parts + 1] = string.upper(part)
	end
	if #parts == 0 then
		return "", false, ""
	end
	local base = parts[#parts]
	local bindPrefix = ""
	for i = 1, #parts - 1 do
		local p = parts[i]
		if p == "SHIFT" then
			bindPrefix = bindPrefix .. "S-"
		elseif p == "CTRL" or p == "STRG" then
			bindPrefix = bindPrefix .. "C-"
		elseif p == "ALT" then
			bindPrefix = bindPrefix .. "A-"
		end
	end
	local icon = Hotkey.IconFor(base, size, width)
	if icon and icon ~= "" then
		return icon, true, bindPrefix
	end
	if ABBREV[base] then
		return bindPrefix .. ABBREV[base], false, ""
	end
	local text = (GetBindingText and GetBindingText(key)) or key
	text = text:gsub("CTRL%-", "C-"):gsub("STRG%-", "C-")
	text = text:gsub("ALT%-", "A-"):gsub("SHIFT%-", "S-")
	text = text:gsub("NUMPAD", "N"):gsub("BUTTON", "M")
	text = text:gsub("MOUSEWHEELUP", "MWU"):gsub("MOUSEWHEELDOWN", "MWD")
	return text, false, ""
end
