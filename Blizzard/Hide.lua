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
local hooked = setmetatable({}, { __mode = "k" })
local pending = setmetatable({}, { __mode = "k" })

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
	if frame:GetParent() ~= hiddenParent then
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
end)

--- Hide a Blizzard frame by reparenting it under a hidden Flux frame.
--- opts.keepEvents: leave the frame's events registered so Unhide restores it fully.
function Blizz.Hide(frame, opts)
	if type(frame) ~= "table" or not frame.SetParent or not frame.GetParent then
		return false
	end
	if not hidden[frame] then
		local parent = frame:GetParent()
		if parent ~= hiddenParent then
			originalParent[frame] = parent
		end
	end
	hidden[frame] = true
	keepEvents[frame] = opts and opts.keepEvents and true or nil
	ApplyHidden(frame)
	if not hooked[frame] and frame.HookScript then
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
