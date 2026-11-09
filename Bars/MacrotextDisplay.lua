-- Bars/MacrotextDisplay.lua — Request alias onto Flux.Context.
-- Hop / target / mod / combat display is owned by Context + ProgramFace.
-- This file must not register UPDATE_MOUSEOVER_UNIT (dual-run hitch).
local addonName, ns = ...
local Flux = ns.Flux
local Bars = Flux.Bars

local Display = {}
Bars.MacrotextDisplay = Display
ns.FluxMacrotextDisplay = Display
_G.FluxMacrotextDisplay = Display

local function Ctx()
	return Flux.Context
end

function Display.Request(force, opts)
	local C = Ctx()
	if C and C.Request then
		C.Request(force, opts)
	end
end

function Display.RequestMouseover()
	local C = Ctx()
	if C and C.RequestMouseover then
		C.RequestMouseover()
	end
end

function Display.RefreshForColumns(cols, ufPeek)
	Display.Request(true)
end

function Display.GetStats()
	local C = Ctx()
	if C and C.GetStats then
		return C.GetStats()
	end
	return {}
end

function Display.ResetStats()
	local C = Ctx()
	if C and C.ResetStats then
		C.ResetStats()
	end
end

function Display.HookUnitFramePeek(frame)
	local C = Ctx()
	if C and C.HookUnitFramePeek then
		C.HookUnitFramePeek(frame)
	end
end

function Display.MouseoverReactionClass()
	local C = Ctx()
	if C and C.MouseoverReactionClass then
		return C.MouseoverReactionClass()
	end
	return "-"
end
