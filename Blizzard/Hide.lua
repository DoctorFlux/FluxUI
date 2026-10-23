-- Hide.lua — hide Blizzard frames without writing into Blizzard code.
-- Only widget calls on the frame (SetParent, UnregisterAllEvents, HookScript).
-- Never assign fields or methods on a Blizzard frame and never SetScript it:
-- a slot written by addon code stays tainted even after the original is put back.
local addonName, ns = ...
local Flux = ns.Flux

local Blizz = Flux.Blizz or {}
Flux.Blizz = Blizz

local hiddenParent = CreateFrame("Frame", nil, UIParent)
hiddenParent:SetAllPoints()
hiddenParent:Hide()
Blizz.HiddenParent = hiddenParent

local hidden = setmetatable({}, { __mode = "k" })
local originalParent = setmetatable({}, { __mode = "k" })
local keepEvents = setmetatable({}, { __mode = "k" })
local keepParent = setmetatable({}, { __mode = "k" })
local originalAlpha = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local pending = setmetatable({}, { __mode = "k" })
local pendingMouse = setmetatable({}, { __mode = "k" })
local mouseRoots = setmetatable({}, { __mode = "k" })
local mouseStates = setmetatable({}, { __mode = "k" })
local mouseEditKeys = setmetatable({}, { __mode = "k" })
local mouseEditRequests = setmetatable({}, { __mode = "k" })

local waiter = CreateFrame("Frame")

local function InCombat()
	return InCombatLockdown and InCombatLockdown() and true or false
end

local function IsProtectedFrame(frame)
	if not frame.IsProtected then
		return false
	end
	local ok, protected = pcall(frame.IsProtected, frame)
	return ok and protected and true or false
end

local function Defer(frame)
	pending[frame] = true
	waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
end

-- Edit Mode refreshes party, raid, and unit systems while it is open. Reparenting
-- one then runs its OnShow / OnHide inside Edit Mode's pass; wait until it closes.
local function EditModeBusy()
	return FluxEditModeBusy ~= nil and FluxEditModeBusy() or false
end

local ApplyAfterEditMode

local function ApplyHidden(frame)
	if not hidden[frame] then
		return
	end
	if EditModeBusy() then
		ApplyAfterEditMode(frame)
		return
	end
	if InCombat() and IsProtectedFrame(frame) then
		Defer(frame)
		return
	end
	if keepParent[frame] then
		-- Native compact-frame setup reads ancestor visibility during Edit Mode.
		-- Keep that state and all native scripts untouched, including OnShow.
		if frame.SetAlpha then frame:SetAlpha(0) end
		Blizz.SetMouseSuppressed(frame, true)
	elseif frame:GetParent() ~= hiddenParent then
		pcall(frame.SetParent, frame, hiddenParent)
	end
	if not keepEvents[frame] and frame.UnregisterAllEvents then
		pcall(frame.UnregisterAllEvents, frame)
	end
end

local function ApplyShown(frame)
	if hidden[frame] then
		return
	end
	if EditModeBusy() then
		ApplyAfterEditMode(frame)
		return
	end
	if InCombat() and IsProtectedFrame(frame) then
		Defer(frame)
		return
	end
	local parent = originalParent[frame] or UIParent
	if keepParent[frame] then
		if frame.SetAlpha then frame:SetAlpha(originalAlpha[frame] or 1) end
		Blizz.SetMouseSuppressed(frame, false)
		keepParent[frame], originalAlpha[frame] = nil, nil
		return
	end
	if frame:GetParent() == hiddenParent then
		pcall(frame.SetParent, frame, parent)
	end
end

ApplyAfterEditMode = function(frame)
	FluxAfterEditMode(function()
		if hidden[frame] then
			ApplyHidden(frame)
		else
			ApplyShown(frame)
		end
	end, frame)
end

waiter:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	for frame in pairs(pending) do
		pending[frame] = nil
		if hidden[frame] then
			ApplyHidden(frame)
		else
			ApplyShown(frame)
		end
	end
	for frame, request in pairs(pendingMouse) do
		pendingMouse[frame] = nil
		Blizz.SetMouseSuppressed(frame, request.suppressed, request.skipChild)
	end
end)

local mouseMethods = {
	{ "IsMouseClickEnabled", "SetMouseClickEnabled" },
	{ "IsMouseMotionEnabled", "SetMouseMotionEnabled" },
	{ "IsMouseWheelEnabled", "EnableMouseWheel" },
}

local function SetMouseValue(frame, getter, setter, value)
	local ok, current = pcall(frame[getter], frame)
	if ok and current ~= value then pcall(frame[setter], frame, value) end
end

local function SaveMouse(frame)
	local saved = { owners = {} }
	for _, methods in ipairs(mouseMethods) do
		local getter, setter = methods[1], methods[2]
		if type(frame[getter]) == "function" and type(frame[setter]) == "function" then
			local ok, value = pcall(frame[getter], frame)
			if ok and type(value) == "boolean" then saved[getter] = { setter, value } end
		end
	end
	-- Older frames expose only the combined mouse switch. Never guess its
	-- original value: restoring native controls must preserve their input policy.
	if not saved.IsMouseClickEnabled and not saved.IsMouseMotionEnabled
		and type(frame.IsMouseEnabled) == "function" and type(frame.EnableMouse) == "function" then
		local ok, value = pcall(frame.IsMouseEnabled, frame)
		if ok and type(value) == "boolean" then saved.IsMouseEnabled = { "EnableMouse", value } end
	end
	return saved
end

local function ReleaseMouse(root, frame)
	local saved = mouseStates[frame]
	if not saved then return end
	saved.owners[root] = nil
	if next(saved.owners) then return end
	for getter, setting in pairs(saved) do
		if getter ~= "owners" then SetMouseValue(frame, getter, setting[1], setting[2]) end
	end
	mouseStates[frame] = nil
end

--- Alpha-zero native frames still hit-test. Suspend input without changing
--- native scripts, visibility, parents or unit/vehicle state. Event-time only.
--- skipChild preserves independently owned unit/class-resource subtrees.
function Blizz.SetMouseSuppressed(frame, suppressed, skipChild)
	if not frame then return false end
	if EditModeBusy() then
		-- OnHide still runs native ResetPartyFrames before EditMode.Exit.
		-- Even input changes can invoke native OnLeave on that same stack.
		mouseEditKeys[frame] = mouseEditKeys[frame] or {}
		mouseEditRequests[frame] = { suppressed = suppressed, skipChild = skipChild }
		FluxAfterEditMode(function()
			local request = mouseEditRequests[frame]
			if request then
				mouseEditRequests[frame] = nil
				Blizz.SetMouseSuppressed(frame, request.suppressed, request.skipChild)
			end
		end, mouseEditKeys[frame])
		return false
	end
	mouseEditRequests[frame] = nil
	if InCombat() then
		pendingMouse[frame] = { suppressed = suppressed, skipChild = skipChild }
		waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
		return false
	end
	pendingMouse[frame] = nil
	local previous = mouseRoots[frame]
	if not suppressed then
		if previous then
			for widget in pairs(previous) do ReleaseMouse(frame, widget) end
			mouseRoots[frame] = nil
		end
		return true
	end
	local visited = {}
	local function visit(widget)
		if visited[widget] then return end
		visited[widget] = true
		local saved = mouseStates[widget] or SaveMouse(widget)
		mouseStates[widget] = saved
		saved.owners[frame] = true
		for getter, setting in pairs(saved) do
			if getter ~= "owners" then SetMouseValue(widget, getter, setting[1], false) end
		end
		if widget.GetChildren then
			for _, child in ipairs({ widget:GetChildren() }) do
				if not skipChild or not skipChild(child) then visit(child) end
			end
		end
	end
	visit(frame)
	if previous then
		for widget in pairs(previous) do
			if not visited[widget] then ReleaseMouse(frame, widget) end
		end
	end
	mouseRoots[frame] = visited
	return true
end

--- Hide a Blizzard frame by reparenting it under a hidden Flux frame.
--- opts.keepEvents: leave the frame's events registered so Unhide restores it fully.
--- opts.keepParent: hide artwork/input in place; preserve native Edit Mode state.
function Blizz.Hide(frame, opts)
	if type(frame) ~= "table" or not frame.SetParent or not frame.GetParent then
		return false
	end
	if not hidden[frame] then
		local parent = frame:GetParent()
		if parent ~= hiddenParent then
			originalParent[frame] = parent
		end
		if opts and opts.keepParent and not keepParent[frame] then
			keepParent[frame] = true
			originalAlpha[frame] = frame.GetAlpha and frame:GetAlpha() or 1
		end
	end
	hidden[frame] = true
	keepEvents[frame] = opts and opts.keepEvents and true or nil
	ApplyHidden(frame)
	if not keepParent[frame] and not hooked[frame] and frame.HookScript then
		hooked[frame] = true
		frame:HookScript("OnShow", function(self)
			if hidden[self] and self:GetParent() ~= hiddenParent then
				C_Timer.After(0, function()
					ApplyHidden(self)
				end)
			end
		end)
	end
	return true
end

--- Undo Blizz.Hide: reparent back to the frame's original parent.
--- Events removed by Hide (without keepEvents) come back only after /reload.
function Blizz.Unhide(frame)
	if type(frame) ~= "table" or not hidden[frame] then
		return false
	end
	hidden[frame] = nil
	ApplyShown(frame)
	return true
end

function Blizz.IsHidden(frame)
	return frame ~= nil and hidden[frame] == true
end
