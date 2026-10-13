-- Resolve.lua — dotted global paths to frames (HouseEditorFrame.StoragePanel).
local addonName, ns = ...
local Flux = ns.Flux

local WindowMover = Flux.WindowMover or {}
Flux.WindowMover = WindowMover

local function IsFrame(obj)
	if type(obj) ~= "table" then
		return false
	end
	if C_Widget and C_Widget.IsWidget then
		local ok, yes = pcall(C_Widget.IsWidget, obj)
		if ok then
			return yes and true or false
		end
	end
	return obj.GetObjectType ~= nil and obj.SetPoint ~= nil
end

function WindowMover.IsFrame(obj)
	return IsFrame(obj)
end

function WindowMover.Resolve(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local frame = _G[name]
	if IsFrame(frame) then
		return frame
	end
	if not name:find(".", 1, true) then
		return nil
	end
	local parts = { strsplit(".", name) }
	frame = _G[parts[1]]
	for i = 2, #parts do
		if type(frame) ~= "table" then
			return nil
		end
		frame = frame[parts[i]]
	end
	if IsFrame(frame) then
		return frame
	end
	return nil
end

-- Title-bar only. NineSlice / Bg / the window itself are full-size hit
-- targets; enabling mouse on them sits on top of the window's buttons.
local TITLE_KEYS = {
	"TitleContainer",
	"Header",
	"TitleBg",
	"TitleBar",
}

local TITLE_NESTED = {
	"BorderFrame.TitleContainer",
}

local function IsCompactTitle(handle, parent)
	if not IsFrame(handle) or handle == parent then
		return false
	end
	local okh, hh = pcall(function()
		return handle:GetHeight()
	end)
	local okp, ph = pcall(function()
		return parent:GetHeight()
	end)
	if not okh or not okp or type(hh) ~= "number" or type(ph) ~= "number" or ph <= 0 then
		return true
	end
	return hh <= math.max(40, ph * 0.28)
end

function WindowMover.FindDragHandles(frame, spec)
	if not IsFrame(frame) then
		return nil
	end
	local drag = spec and spec.drag or "title"
	-- Whole-frame hooks never EnableMouse; Engine also ignores clicks on buttons.
	if drag == "frame" then
		return { frame }
	end

	local handles = {}
	local seen = {}

	local function Add(obj)
		if IsFrame(obj) and not seen[obj] and IsCompactTitle(obj, frame) then
			seen[obj] = true
			handles[#handles + 1] = obj
		end
	end

	for i = 1, #TITLE_KEYS do
		Add(frame[TITLE_KEYS[i]])
	end
	for i = 1, #TITLE_NESTED do
		local obj = frame
		local parts = { strsplit(".", TITLE_NESTED[i]) }
		for p = 1, #parts do
			if type(obj) ~= "table" then
				obj = nil
				break
			end
			obj = obj[parts[p]]
		end
		Add(obj)
	end

	local fname = frame.GetName and frame:GetName()
	if fname then
		Add(_G[fname .. "Header"])
		Add(_G[fname .. "Title"])
	end
	if frame == _G.CharacterFrame then
		Add(frame.TitleContainer)
		Add(_G.CharacterNameText)
	end
	if frame == _G.WorldMapFrame then
		Add(_G.WorldMapTitleButton)
		if frame.BorderFrame then
			Add(frame.BorderFrame.TitleContainer)
		end
	end

	return handles
end
