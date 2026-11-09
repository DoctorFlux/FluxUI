-- Bars/Minis.lua — 38 SHIFT/CTRL hosts at scale 0.5.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Minis = {}
Bars.Minis = Minis

local built = false

function Minis.Build()
	if built then
		return true
	end
	if InCombatLockdown and InCombatLockdown() then return false end
	local State = Bars.State
	local Hosts = Bars.Hosts
	if not State or not Hosts then
		return false
	end
	State.Create()

	for column = 1, Bars.NUM_COLUMNS do
		local col = Bars.hosts[column]
		if col then
			local secHeader = State.HeaderFor(column, "sec")
			local tertHeader = State.HeaderFor(column, "tert")

			if not (col.sec and col.sec._fluxReady) then
				local secWidget = Hosts.CreateSurface(column, "sec", "FluxActionStripSec" .. column, secHeader)
				if secWidget then
					State.Attach(secHeader, secWidget, column, "sec")
					local sec = col.sec or {
						column = column,
						row = "sec",
						slot = State.GetSecondarySlot(column),
						widget = secWidget,
						pages = false,
						bindingCommand = col.bindingCommand,
					}
					col.sec = sec
					sec.widget = secWidget
					Hosts.FinishSurface(sec, column, "sec", sec.slot)
					sec._fluxReady = true
				end
			end

			if not (col.tert and col.tert._fluxReady) then
				local tertWidget = Hosts.CreateSurface(column, "tert", "FluxActionStripTert" .. column, tertHeader)
				if tertWidget then
					State.Attach(tertHeader, tertWidget, column, "tert")
					local tert = col.tert or {
						column = column,
						row = "tert",
						slot = State.GetTertiarySlot(column),
						widget = tertWidget,
						pages = false,
						bindingCommand = col.bindingCommand,
					}
					col.tert = tert
					tert.widget = tertWidget
					Hosts.FinishSurface(tert, column, "tert", tert.slot)
					tert._fluxReady = true
				end
			end
		end
	end
	if Flux.Action and Flux.Action.SweepFluxFromCollectors then
		Flux.Action.SweepFluxFromCollectors()
	end
	for column = 1, Bars.NUM_COLUMNS do
		local col = Bars.hosts[column]
		if not (col and col.sec and col.sec._fluxReady and col.tert and col.tert._fluxReady) then return false end
	end
	built = true
	return true
end
