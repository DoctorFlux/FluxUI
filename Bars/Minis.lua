-- Bars/Minis.lua — 38 SHIFT/CTRL hosts at scale 0.5.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Minis = {}
Bars.Minis = Minis

local built = false

function Minis.Build()
	if built then
		return
	end
	built = true
	local State = Bars.State
	local Hosts = Bars.Hosts
	if not State or not Hosts then
		return
	end
	State.Create()

	for column = 1, Bars.NUM_COLUMNS do
		local col = Bars.hosts[column]
		if col then
			local secHeader = State.HeaderFor(column, "sec")
			local tertHeader = State.HeaderFor(column, "tert")

			local secWidget = Hosts.CreateSurface(column, "sec", "FluxActionStripSec" .. column, secHeader)
			if secWidget then
				State.Attach(secHeader, secWidget, column, "sec")
				local sec = {
					column = column,
					row = "sec",
					slot = State.GetSecondarySlot(column),
					widget = secWidget,
					pages = false,
					bindingCommand = col.bindingCommand,
				}
				Hosts.FinishSurface(sec, column, "sec", sec.slot)
				col.sec = sec
			end

			local tertWidget = Hosts.CreateSurface(column, "tert", "FluxActionStripTert" .. column, tertHeader)
			if tertWidget then
				State.Attach(tertHeader, tertWidget, column, "tert")
				local tert = {
					column = column,
					row = "tert",
					slot = State.GetTertiarySlot(column),
					widget = tertWidget,
					pages = false,
					bindingCommand = col.bindingCommand,
				}
				Hosts.FinishSurface(tert, column, "tert", tert.slot)
				col.tert = tert
			end
		end
	end
	if Flux.Action and Flux.Action.SweepFluxFromCollectors then
		Flux.Action.SweepFluxFromCollectors()
	end
end
