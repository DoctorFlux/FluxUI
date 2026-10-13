-- ExtraButtonSystem/Engine/Range.lua — Extra/badge side of the shared range pass.
-- The ticker moved to Flux.Range (Core/Engine/Range.lua) so the strip, the Extra
-- buttons and every corner badge resolve a given spell once per frame instead of
-- once per button on two loops that were 50ms out of phase. What stays here is
-- the "does anything need range" test over EBS.buttons and the flag bookkeeping
-- Watch.lua already calls.
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS

local Range = {}
EBS.Range = Range

local registered = false

local function RangeableType(t)
	return t == "spell" or t == "item" or t == "macro" or t == "macrotext" or t == "toy"
end

local function RangeUnit(btn)
	local macroUnit
	local widget
	if btn.ActionType == "macro" or btn.ActionType == "macrotext" then
		macroUnit = btn.MacroTarget
	else
		widget = btn.Widget
	end
	local R = Flux.Range
	if R and R.ResolveUnit then
		return R.ResolveUnit(widget, macroUnit)
	end
	return macroUnit or "target"
end

local function NeedsRange(btn)
	if not btn or not RangeableType(btn.ActionType) then
		return false
	end
	if btn.ActionType == "macro" or btn.ActionType == "macrotext" then
		if btn.MacroMode ~= "spell" and btn.MacroMode ~= "item" then
			return false
		end
	end
	if UnitExists then
		local ok, exists = pcall(UnitExists, RangeUnit(btn))
		if not ok or not exists then
			return false
		end
	end
	return true
end

local function AnyNeedsRangeOn(list)
	local IsParked = EBS.Paint and EBS.Paint.IsParked
	if not list then
		return false
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and not (IsParked and IsParked(btn)) and NeedsRange(btn) then
			return true
		end
	end
	return false
end

local function AnyNeedsRange()
	return AnyNeedsRangeOn(EBS.buttons) or AnyNeedsRangeOn(EBS.badges)
end

local function Sweep()
	if Flux.Scheduler and Flux.Scheduler.Request then
		Flux.Scheduler.Request("eval", "ebs.range")
	elseif EBS.Paint and EBS.Paint.FlushEval then
		EBS.Paint.FlushEval({ ["ebs.range"] = true })
	end
end

function Range.IsArmed()
	local R = Flux.Range
	return (R and R.IsArmed and R.IsArmed()) and true or false
end

function Range.RefreshButton(btn)
	if not btn then
		return
	end
	local t = btn.ActionType
	if t == "spell" or t == "item" or t == "toy" then
		btn.needsRange = true
	elseif t == "macro" or t == "macrotext" then
		btn.needsRange = (btn.MacroMode == "spell" or btn.MacroMode == "item") and true or false
	else
		btn.needsRange = false
	end
end

function Range.RefreshFlags()
	local list = EBS.buttons
	for i = 1, #list do
		Range.RefreshButton(list[i])
	end
	local badges = EBS.badges
	if badges then
		for i = 1, #badges do
			Range.RefreshButton(badges[i])
		end
	end
	Range.Sync()
end

-- Older host name used by Layout.
function Range.RefreshItemFlags()
	Range.RefreshFlags()
end

function Range.Sync()
	local R = Flux.Range
	if not R then
		return
	end
	if not registered then
		registered = true
		R.RegisterSweep("ebs", AnyNeedsRange, Sweep)
		if R.Start then
			R.Start()
		end
		return
	end
	R.Sync()
end

function Range.SyncDemand()
	Range.Sync()
end

function Range.Start()
	Range.RefreshFlags()
end
