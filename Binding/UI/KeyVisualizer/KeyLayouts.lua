-- Binding/UI/KeyVisualizer/KeyLayouts.lua
-- Keyboard layout data for Flux KeyVisualizer (ported from Clicked KeyLayouts).

local addonName, ns = ...

--- @class KeyButton
--- @field private id? string
--- @field public key? string
--- @field public abbreviation? string
--- @field public x? integer
--- @field public y? integer
--- @field public xOffset? integer
--- @field public yOffset? integer
--- @field public width? integer
--- @field public height? integer
--- @field public relativeTo? string
--- @field public overrides? table<KeyboardSize,KeyButton>
--- @field public disabled? boolean

--- @class KeyboardButtonLayout
--- @field public keys KeyButton[]
--- @field public sizes table<KeyboardSize,string[]>

--- @enum KeyboardLayout
ns.FluxKeyboardLayouts = {
	QWERTY = "QWERTY",
	QWERTZ = "QWERTZ",
	AZERTY = "AZERTY"
}

--- @enum KeyboardSize
ns.FluxKeyboardSizes = {
	SIZE_100 = 100,
	SIZE_80 = 80,
	SIZE_60 = 60
}

--- @class KeyButton
local KeyButtonMixin = {}

--- @return string?
function KeyButtonMixin:GetId()
	return self.id or self.key
end

--- @return string?
function KeyButtonMixin:GetAbbreviation()
	return self.abbreviation or self.key
end

--- @type KeyboardButtonLayout
local KeyboardLayoutQwerty = {
	keys = {
		{ key="ESC", x=0, disabled=true },

		{ key="F1", xOffset=1, relativeTo="ESC" },
		{ key="F2" },
		{ key="F3" },
		{ key="F4" },
		{ key="F5", xOffset=0.5 },
		{ key="F6" },
		{ key="F7" },
		{ key="F8" },
		{ key="F9", xOffset=0.5 },
		{ key="F10" },
		{ key="F11" },
		{ key="F12" },

		{ key="`", x=0, yOffset=1.3, relativeTo="ESC" },
		{ key="1", overrides = { [ns.FluxKeyboardSizes.SIZE_60] = { relativeTo="ESC" } } },
		{ key="2" },
		{ key="3" },
		{ key="4" },
		{ key="5" },
		{ key="6" },
		{ key="7" },
		{ key="8" },
		{ key="9" },
		{ key="0" },
		{ key="-" },
		{ key="=" },
		{ key="BACKSPACE", abbreviation="BACKSPACE", width=2 },

		{ key="TAB", x=0, yOffset=1, width=1.5, relativeTo="`", overrides = { [ns.FluxKeyboardSizes.SIZE_60] = { relativeTo = "ESC" }} },
		{ key="Q" },
		{ key="W" },
		{ key="E" },
		{ key="R" },
		{ key="T" },
		{ key="Y" },
		{ key="U" },
		{ key="I" },
		{ key="O" },
		{ key="P" },
		{ key="[" },
		{ key="]" },
		{ key="\\", width=1.5 },

		{ key="CAPSLOCK", abbreviation="CAPS", x=0, yOffset=1, width=1.65, relativeTo="TAB" },
		{ key="A" },
		{ key="S" },
		{ key="D" },
		{ key="F" },
		{ key="G" },
		{ key="H" },
		{ key="J" },
		{ key="K" },
		{ key="L" },
		{ key=";" },
		{ key="'" },
		{ key="ENTER", width=2.35 },

		{ key="LSHIFT", abbreviation="SHIFT", x=0, yOffset=1, width=2.25, relativeTo="CAPSLOCK", disabled=true },
		{ key="Z" },
		{ key="X" },
		{ key="C" },
		{ key="V" },
		{ key="B" },
		{ key="N" },
		{ key="M" },
		{ key="," },
		{ key="." },
		{ key="/" },
		{ key="RSHIFT", abbreviation="SHIFT", width=2.75, disabled=true },

		{ key="LCTRL", abbreviation="CTRL", x=0, yOffset=1, width=1.2857, relativeTo="LSHIFT", disabled=true },
		{ key="LMETA", abbreviation="META", width=1.2857, disabled=true },
		{ key="LALT", abbreviation="ALT", width=1.2857, disabled=true },
		{ key="SPACE", width=6 },
		{ key="RALT", abbreviation="ALT", width=1.28, disabled=true },
		{ key="RMETA", abbreviation="META", width=1.2857, xOffset=1.2857, disabled=true },
		{ key="RCTRL", abbreviation="CTRL", width=1.2857, disabled=true },

		{ key="PRINTSCREEN", abbreviation="PRTSC", xOffset=0.3, relativeTo="F12" },
		{ key="SCROLLLOCK", abbreviation="SCRLK", disabled=true },
		{ key="PAUSE", disabled=true },

		{ key="INSERT", abbreviation="INS", xOffset=0.3, relativeTo="BACKSPACE" },
		{ key="HOME" },
		{ key="PAGEUP", abbreviation="PG UP" },

		{ key="DELETE", abbreviation="DEL", xOffset=0.3, relativeTo="\\" },
		{ key="END" },
		{ key="PAGEDOWN", abbreviation="PG DN" },

		{ key="UP", abbreviation="^", xOffset=1.3, relativeTo="RSHIFT" },

		{ key="LEFT", abbreviation="<", xOffset=0.3, relativeTo="RCTRL" },
		{ key="DOWN", abbreviation="v" },
		{ key="RIGHT", abbreviation=">" },

		{ key="NUMLOCK", abbreviation="NUM", xOffset=0.3, relativeTo="PAGEUP" },
		{ key="NUMPADDIVIDE", abbreviation="/" },
		{ key="NUMPADMULTIPLY", abbreviation="*" },
		{ key="NUMPADMINUS", abbreviation="-" },

		{ key="NUMPAD7", abbreviation="7", xOffset=0.3, relativeTo="PAGEDOWN" },
		{ key="NUMPAD8", abbreviation="8" },
		{ key="NUMPAD9", abbreviation="9" },
		{ key="NUMPADPLUS", abbreviation="+", height=2 },

		{ key="NUMPAD4", abbreviation="4", xOffset=3.6, relativeTo="ENTER" },
		{ key="NUMPAD5", abbreviation="5" },
		{ key="NUMPAD6", abbreviation="6" },

		{ key="NUMPAD1", abbreviation="1", xOffset=1.3, relativeTo="UP" },
		{ key="NUMPAD2", abbreviation="2" },
		{ key="NUMPAD3", abbreviation="3" },
		{ id="NUMPADENTER", key="ENTER", height=2 },

		{ key="NUMPAD0", abbreviation="0", xOffset=0.3, width=2, relativeTo="RIGHT" },
		{ key="NUMPADDECIMAL", abbreviation="." },
	},
	sizes = {
		[ns.FluxKeyboardSizes.SIZE_100] = {
			"NUMLOCK", "NUMPADDIVIDE", "NUMPADMULTIPLY", "NUMPADMINUS",
			"NUMPAD7", "NUMPAD8", "NUMPAD9", "NUMPADPLUS",
			"NUMPAD4", "NUMPAD5", "NUMPAD6",
			"NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPADENTER",
			"NUMPAD0", "NUMPADDECIMAL"
		},
		[ns.FluxKeyboardSizes.SIZE_80] = {
			"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
			"`",
			"PRINTSCREEN", "SCROLLLOCK", "PAUSE",
			"INSERT", "HOME", "PAGEUP",
			"DELETE", "END", "PAGEDOWN",
			"UP", "LEFT", "DOWN", "RIGHT"
		},
		[ns.FluxKeyboardSizes.SIZE_60] = {
			"ESC",
			"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BACKSPACE",
			"TAB", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]", "\\",
			"CAPSLOCK", "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "ENTER",
			"LSHIFT", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/", "RSHIFT",
			"LCTRL", "LMETA", "LALT", "SPACE", "RALT", "RMETA", "RCTRL"
		}
	}
}

--- @type KeyboardButtonLayout
local KeyboardLayoutQwertz = {
	keys = {
		{ key="ESC", x=0, disabled=true },

		{ key="F1", xOffset=1, relativeTo="ESC" },
		{ key="F2" },
		{ key="F3" },
		{ key="F4" },
		{ key="F5", xOffset=0.5 },
		{ key="F6" },
		{ key="F7" },
		{ key="F8" },
		{ key="F9", xOffset=0.5 },
		{ key="F10" },
		{ key="F11" },
		{ key="F12" },

		{ key="^", x=0, yOffset=1.3, relativeTo="ESC" },
		{ key="1", overrides = { [ns.FluxKeyboardSizes.SIZE_60] = { relativeTo="ESC" } } },
		{ key="2" },
		{ key="3" },
		{ key="4" },
		{ key="5" },
		{ key="6" },
		{ key="7" },
		{ key="8" },
		{ key="9" },
		{ key="0" },
		{ key="ß" },
		{ key="´" },
		{ key="BACKSPACE", width=2 },

		{ key="TAB", x=0, yOffset=1, width=1.5, relativeTo="^", overrides = { [ns.FluxKeyboardSizes.SIZE_60] = { relativeTo = "ESC" }} },
		{ key="Q" },
		{ key="W" },
		{ key="E" },
		{ key="R" },
		{ key="T" },
		{ key="Z" },
		{ key="U" },
		{ key="I" },
		{ key="O" },
		{ key="P" },
		{ key="ü" },
		{ key="+" },
		{ key="ENTER", xOffset=0.15, width=1.35, height=2 },

		{ key="CAPSLOCK", abbreviation="CAPS", x=0, yOffset=1, width=1.65, relativeTo="TAB" },
		{ key="A" },
		{ key="S" },
		{ key="D" },
		{ key="F" },
		{ key="G" },
		{ key="H" },
		{ key="J" },
		{ key="K" },
		{ key="L" },
		{ key="ö" },
		{ key="ä" },
		{ key="#" },

		{ key="LSHIFT", abbreviation="SHIFT", x=0, yOffset=1, width=1.25, relativeTo="CAPSLOCK", disabled=true },
		{ key="<" },
		{ key="Y" },
		{ key="X" },
		{ key="C" },
		{ key="V" },
		{ key="B" },
		{ key="N" },
		{ key="M" },
		{ key="," },
		{ key="." },
		{ key="-" },
		{ key="RSHIFT", abbreviation="SHIFT", width=2.75, disabled=true },

		{ key="LCTRL", abbreviation="CTRL", x=0, yOffset=1, width=1.75, relativeTo="LSHIFT", disabled=true },
		{ key="LMETA", abbreviation="META", width=1.15, disabled=true },
		{ key="LALT", abbreviation="ALT", width=1.15, disabled=true },
		{ key="SPACE", width=6.15 },
		{ key="RALT", abbreviation="ALT", width=1.15, disabled=true },
		{ key="RMETA", abbreviation="META", width=1.15, xOffset=1.15, disabled=true },
		{ key="RCTRL", abbreviation="CTRL", width=1.35, disabled=true },

		{ key="PRINTSCREEN", abbreviation="PRTSC", xOffset=0.3, relativeTo="F12" },
		{ key="SCROLLLOCK", abbreviation="SCRLK", disabled=true },
		{ key="PAUSE", disabled=true },

		{ key="INSERT", abbreviation="INS", xOffset=0.3, relativeTo="BACKSPACE" },
		{ key="HOME" },
		{ key="PAGEUP", abbreviation="PG UP" },

		{ key="DELETE", abbreviation="DEL", xOffset=0.3, relativeTo="ENTER" },
		{ key="END" },
		{ key="PAGEDOWN", abbreviation="PG DN" },

		{ key="UP", abbreviation="^", xOffset=1.3, relativeTo="RSHIFT" },

		{ key="LEFT", abbreviation="<", xOffset=0.3, relativeTo="RCTRL" },
		{ key="DOWN", abbreviation="v" },
		{ key="RIGHT", abbreviation=">" },

		{ key="NUMLOCK", abbreviation="NUM", xOffset=0.3, relativeTo="PAGEUP" },
		{ key="NUMPADDIVIDE", abbreviation="/" },
		{ key="NUMPADMULTIPLY", abbreviation="*" },
		{ key="NUMPADMINUS", abbreviation="-" },

		{ key="NUMPAD7", abbreviation="7", xOffset=0.3, relativeTo="PAGEDOWN" },
		{ key="NUMPAD8", abbreviation="8" },
		{ key="NUMPAD9", abbreviation="9" },
		{ key="NUMPADPLUS", abbreviation="+", height=2 },

		{ key="NUMPAD4", abbreviation="4", xOffset=4.95, relativeTo="#" },
		{ key="NUMPAD5", abbreviation="5" },
		{ key="NUMPAD6", abbreviation="6" },

		{ key="NUMPAD1", abbreviation="1", xOffset=1.3, relativeTo="UP" },
		{ key="NUMPAD2", abbreviation="2" },
		{ key="NUMPAD3", abbreviation="3" },
		{ id="NUMPADENTER", key="ENTER", height=2 },

		{ key="NUMPAD0", abbreviation="0", xOffset=0.3, width=2, relativeTo="RIGHT" },
		{ key="NUMPADDECIMAL", abbreviation="." },
	},
	sizes = {
		[ns.FluxKeyboardSizes.SIZE_100] = {
			"NUMLOCK", "NUMPADDIVIDE", "NUMPADMULTIPLY", "NUMPADMINUS",
			"NUMPAD7", "NUMPAD8", "NUMPAD9", "NUMPADPLUS",
			"NUMPAD4", "NUMPAD5", "NUMPAD6",
			"NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPADENTER",
			"NUMPAD0", "NUMPADDECIMAL"
		},
		[ns.FluxKeyboardSizes.SIZE_80] = {
			"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
			"^",
			"PRINTSCREEN", "SCROLLLOCK", "PAUSE",
			"INSERT", "HOME", "PAGEUP",
			"DELETE", "END", "PAGEDOWN",
			"UP", "LEFT", "DOWN", "RIGHT"
		},
		[ns.FluxKeyboardSizes.SIZE_60] = {
			"ESC",
			"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "ß", "´", "BACKSPACE",
			"TAB", "Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "ü", "+", "ENTER",
			"CAPSLOCK", "A", "S", "D", "F", "G", "H", "J", "K", "L", "ö", "ä", "#",
			"LSHIFT", "<", "Y", "X", "C", "V", "B", "N", "M", ",", ".", "-", "RSHIFT",
			"LCTRL", "LMETA", "LALT", "SPACE", "RALT", "RMETA", "RCTRL"
		}
	}
}

--- @type KeyboardButtonLayout
local KeyboardLayoutAzerty = {
	keys = {
		{ key="ESC", x=0, disabled=true },

		{ key="F1", xOffset=1, relativeTo="ESC" },
		{ key="F2" },
		{ key="F3" },
		{ key="F4" },
		{ key="F5", xOffset=0.5 },
		{ key="F6" },
		{ key="F7" },
		{ key="F8" },
		{ key="F9", xOffset=0.5 },
		{ key="F10" },
		{ key="F11" },
		{ key="F12" },

		{ key="²", x=0, yOffset=1.3, relativeTo="ESC" },
		{ key="1", overrides = { [ns.FluxKeyboardSizes.SIZE_60] = { relativeTo="ESC" } } },
		{ key="2" },
		{ key="3" },
		{ key="4" },
		{ key="5" },
		{ key="6" },
		{ key="7" },
		{ key="8" },
		{ key="9" },
		{ key="0" },
		{ key=")" },
		{ key="=" },
		{ key="BACKSPACE", width=2 },

		{ key="TAB", x=0, yOffset=1, width=1.5, relativeTo="²", overrides = { [ns.FluxKeyboardSizes.SIZE_60] = { relativeTo = "ESC" }} },
		{ key="A" },
		{ key="Z" },
		{ key="E" },
		{ key="R" },
		{ key="T" },
		{ key="Y" },
		{ key="U" },
		{ key="I" },
		{ key="O" },
		{ key="P" },
		{ key="^" },
		{ key="$" },
		{ key="ENTER", xOffset=0.15, width=1.35, height=2 },

		{ key="CAPSLOCK", abbreviation="CAPS", x=0, yOffset=1, width=1.65, relativeTo="TAB" },
		{ key="Q" },
		{ key="S" },
		{ key="D" },
		{ key="F" },
		{ key="G" },
		{ key="H" },
		{ key="J" },
		{ key="K" },
		{ key="L" },
		{ key="M" },
		{ key="ù" },
		{ key="*" },

		{ key="LSHIFT", abbreviation="SHIFT", x=0, yOffset=1, width=1.25, relativeTo="CAPSLOCK", disabled=true },
		{ key="<" },
		{ key="W" },
		{ key="X" },
		{ key="C" },
		{ key="V" },
		{ key="B" },
		{ key="N" },
		{ key="," },
		{ key=";" },
		{ key=":" },
		{ key="!" },
		{ key="RSHIFT", abbreviation="SHIFT", width=2.75, disabled=true },

		{ key="LCTRL", abbreviation="CTRL", x=0, yOffset=1, width=1.2857, relativeTo="LSHIFT", disabled=true },
		{ key="LMETA", abbreviation="META", width=1.2857, disabled=true },
		{ key="LALT", abbreviation="ALT", width=1.2857, disabled=true },
		{ key="SPACE", width=6 },
		{ key="RALT", abbreviation="ALT", width=1.28, disabled=true },
		{ key="RMETA", abbreviation="META", width=1.2857, xOffset=1.2857, disabled=true },
		{ key="RCTRL", abbreviation="CTRL", width=1.2857, disabled=true },

		{ key="PRINTSCREEN", abbreviation="PRTSC", xOffset=0.3, relativeTo="F12" },
		{ key="SCROLLLOCK", abbreviation="SCRLK", disabled=true },
		{ key="PAUSE", disabled=true },

		{ key="INSERT", abbreviation="INS", xOffset=0.3, relativeTo="BACKSPACE" },
		{ key="HOME" },
		{ key="PAGEUP", abbreviation="PG UP" },

		{ key="DELETE", abbreviation="DEL", xOffset=0.3, relativeTo="ENTER" },
		{ key="END" },
		{ key="PAGEDOWN", abbreviation="PG DN" },

		{ key="UP", abbreviation="^", xOffset=1.3, relativeTo="RSHIFT" },

		{ key="LEFT", abbreviation="<", xOffset=0.3, relativeTo="RCTRL" },
		{ key="DOWN", abbreviation="v" },
		{ key="RIGHT", abbreviation=">" },

		{ key="NUMLOCK", abbreviation="NUM", xOffset=0.3, relativeTo="PAGEUP" },
		{ key="NUMPADDIVIDE", abbreviation="/" },
		{ key="NUMPADMULTIPLY", abbreviation="*" },
		{ key="NUMPADMINUS", abbreviation="-" },

		{ key="NUMPAD7", abbreviation="7", xOffset=0.3, relativeTo="PAGEDOWN" },
		{ key="NUMPAD8", abbreviation="8" },
		{ key="NUMPAD9", abbreviation="9" },
		{ key="NUMPADPLUS", abbreviation="+", height=2 },

		{ key="NUMPAD4", abbreviation="4", xOffset=4.95, relativeTo="*" },
		{ key="NUMPAD5", abbreviation="5" },
		{ key="NUMPAD6", abbreviation="6" },

		{ key="NUMPAD1", abbreviation="1", xOffset=1.3, relativeTo="UP" },
		{ key="NUMPAD2", abbreviation="2" },
		{ key="NUMPAD3", abbreviation="3" },
		{ id="NUMPADENTER", key="ENTER", height=2 },

		{ key="NUMPAD0", abbreviation="0", xOffset=0.3, width=2, relativeTo="RIGHT" },
		{ key="NUMPADDECIMAL", abbreviation="." },
	},
	sizes = {
		[ns.FluxKeyboardSizes.SIZE_100] = {
			"NUMLOCK", "NUMPADDIVIDE", "NUMPADMULTIPLY", "NUMPADMINUS",
			"NUMPAD7", "NUMPAD8", "NUMPAD9", "NUMPADPLUS",
			"NUMPAD4", "NUMPAD5", "NUMPAD6",
			"NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPADENTER",
			"NUMPAD0", "NUMPADDECIMAL"
		},
		[ns.FluxKeyboardSizes.SIZE_80] = {
			"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
			"²",
			"PRINTSCREEN", "SCROLLLOCK", "PAUSE",
			"INSERT", "HOME", "PAGEUP",
			"DELETE", "END", "PAGEDOWN",
			"UP", "LEFT", "DOWN", "RIGHT"
		},
		[ns.FluxKeyboardSizes.SIZE_60] = {
			"ESC",
			"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ")", "=", "BACKSPACE",
			"TAB", "A", "Z", "E", "R", "T", "Y", "U", "I", "O", "P", "^", "$", "ENTER",
			"CAPSLOCK", "Q", "S", "D", "F", "G", "H", "J", "K", "L", "M", "ù", "*",
			"LSHIFT", "<", "W", "X", "C", "V", "B", "N", ",", ";", ":", "!", "RSHIFT",
			"LCTRL", "LMETA", "LALT", "SPACE", "RALT", "RMETA", "RCTRL"
		}
	}
}

local layouts = {
	[ns.FluxKeyboardLayouts.QWERTY] = KeyboardLayoutQwerty,
	[ns.FluxKeyboardLayouts.QWERTZ] = KeyboardLayoutQwertz,
	[ns.FluxKeyboardLayouts.AZERTY] = KeyboardLayoutAzerty
}

for _, layout in pairs(layouts) do
	for i, key in ipairs(layout.keys) do
		layout.keys[i] = Mixin(key, KeyButtonMixin)
	end
end

--- @class KeyLayout
local KeyLayouts = {}

--- @return string[]
function KeyLayouts:GetKeyboardLayouts()
	local result = {}

	for key in pairs(layouts) do
		table.insert(result, key)
	end

	local function SortFunc(l, r)
		return l < r
	end

	table.sort(result, SortFunc)
	return result
end

--- @param layout KeyboardLayout
--- @return string[]
function KeyLayouts:GetKeyboardSizes(layout)
	local result = {}

	for size in pairs(layouts[layout].sizes) do
		table.insert(result, size)
	end

	local function SortFunc(l, r)
		return l > r
	end

	table.sort(result, SortFunc)
	return result
end

--- Mouse buttons shown beside the keyboard (same binding chord pipeline).
--- Always visible; positioned to the right of the active keyboard size.
local MouseLayoutKeys = {
	{
		id = "MOUSEWHEELUP",
		key = "MOUSEWHEELUP",
		abbreviation = "WU",
		width = 1.2,
		relativeTo = "F12",
		xOffset = 2.4,
		overrides = {
			[ns.FluxKeyboardSizes.SIZE_60] = { relativeTo = "BACKSPACE", xOffset = 1.4 },
			[ns.FluxKeyboardSizes.SIZE_80] = { relativeTo = "F12", xOffset = 2.4 },
			[ns.FluxKeyboardSizes.SIZE_100] = { relativeTo = "NUMPADPLUS", xOffset = 1.6 },
		},
	},
	{
		id = "BUTTON4",
		key = "BUTTON4",
		abbreviation = "M4",
		relativeTo = "MOUSEWHEELUP",
		xOffset = -1.2,
		yOffset = 1.05,
	},
	{
		id = "BUTTON3",
		key = "BUTTON3",
		abbreviation = "MMB",
		relativeTo = "MOUSEWHEELUP",
		yOffset = 1.05,
	},
	{
		id = "BUTTON5",
		key = "BUTTON5",
		abbreviation = "M5",
		relativeTo = "MOUSEWHEELUP",
		xOffset = 1.2,
		yOffset = 1.05,
	},
	{
		id = "BUTTON1",
		key = "BUTTON1",
		abbreviation = "LMB",
		width = 1.55,
		height = 1.45,
		relativeTo = "BUTTON4",
		yOffset = 1.05,
	},
	{
		id = "BUTTON2",
		key = "BUTTON2",
		abbreviation = "RMB",
		width = 1.55,
		height = 1.45,
		relativeTo = "BUTTON5",
		yOffset = 1.05,
	},
	{
		id = "MOUSEWHEELDOWN",
		key = "MOUSEWHEELDOWN",
		abbreviation = "WD",
		width = 1.2,
		relativeTo = "BUTTON3",
		yOffset = 1.55,
	},
}

for i, key in ipairs(MouseLayoutKeys) do
	MouseLayoutKeys[i] = Mixin(key, KeyButtonMixin)
end

--- @param layout KeyboardLayout
--- @param size KeyboardSize
--- @return KeyButton[]
--- @return string[]
function KeyLayouts:GetKeyboardLayout(layout, size)
	local keys = {}
	local visible = {}

	for _, data in ipairs(layouts[layout].keys) do
		table.insert(keys, data)
	end

	for s, enabledKeys in pairs(layouts[layout].sizes) do
		if s <= size then
			for _, key in ipairs(enabledKeys) do
				table.insert(visible, key)
			end
		end
	end

	-- Mouse cluster is added separately via GetMouseLayout (bound keys only).
	return keys, visible
end

--- Mouse buttons laid out as a top-down mouse silhouette (grid units).
--- `active` optional set { [keyId]=true }; when provided, only those buttons are
--- included and positions pack compactly (no empty holes for unbound buttons).
--- @param active table<string,boolean>?
--- @return KeyButton[]
--- @return string[]
function KeyLayouts:GetMouseLayout(active)
	local function on(id)
		return not active or active[id]
	end

	local hasL = on("BUTTON1")
	local hasR = on("BUTTON2")
	local hasM5 = on("BUTTON5")
	local hasM4 = on("BUTTON4")
	local hasWU = on("MOUSEWHEELUP")
	local hasMM = on("BUTTON3")
	local hasWD = on("MOUSEWHEELDOWN")
	local hasSide = hasM5 or hasM4
	local hasWheel = hasWU or hasMM or hasWD

	if not (hasL or hasR or hasSide or hasWheel) then
		return {}, {}
	end

	local keys = {}
	local function add(def)
		keys[#keys + 1] = def
	end

	local mainX = hasSide and 1.0 or 0.0
	local lmbW, lmbH = 1.35, 1.7
	local sideW, sideH = 0.9, 0.95
	local wheelW, wheelH = 0.95, 0.7
	local gap = 0.1

	if hasM5 then
		add({ key = "BUTTON5", abbreviation = "M5", width = sideW, height = sideH, x = 0.0, y = 0.1, mousePanel = true })
	end
	if hasM4 then
		local y4 = hasM5 and 1.15 or 0.1
		add({ key = "BUTTON4", abbreviation = "M4", width = sideW, height = sideH, x = 0.0, y = y4, mousePanel = true })
	end
	if hasL then
		add({ key = "BUTTON1", abbreviation = "LMB", width = lmbW, height = lmbH, x = mainX, y = 0.1, mousePanel = true })
	end

	local cursorX = mainX
	if hasL then
		cursorX = mainX + lmbW + gap
	elseif hasSide then
		cursorX = mainX
	end

	if hasWheel then
		local wy = 0.15
		if hasWU then
			add({ key = "MOUSEWHEELUP", abbreviation = "WhU", width = wheelW, height = wheelH, x = cursorX, y = wy, mousePanel = true })
			wy = wy + wheelH + 0.05
		end
		if hasMM then
			add({ key = "BUTTON3", abbreviation = "MMB", width = wheelW, height = wheelH, x = cursorX, y = wy, mousePanel = true })
			wy = wy + wheelH + 0.05
		end
		if hasWD then
			add({ key = "MOUSEWHEELDOWN", abbreviation = "WhD", width = wheelW, height = wheelH, x = cursorX, y = wy, mousePanel = true })
		end
		cursorX = cursorX + wheelW + gap
	end

	if hasR then
		local rx = cursorX
		if not hasL and not hasWheel then
			rx = mainX
		end
		add({ key = "BUTTON2", abbreviation = "RMB", width = lmbW, height = lmbH, x = rx, y = 0.1, mousePanel = true })
	end

	local visible = {}
	for i, key in ipairs(keys) do
		keys[i] = Mixin(key, KeyButtonMixin)
		visible[#visible + 1] = keys[i]:GetId()
	end
	return keys, visible
end

--- @return KeyButton[]
function KeyLayouts:GetMouseLayoutKeys()
	return MouseLayoutKeys
end

ns.FluxKeyLayouts = KeyLayouts
_G.FluxKeyLayouts = KeyLayouts
