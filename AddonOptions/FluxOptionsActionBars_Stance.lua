-- FluxOptionsActionBars_Stance.lua — Stance sub-tab: always per-character reorder / hide.
local addonName, ns = ...
local AB = ns.FluxOptionsActionBars

function AB.GetStanceGroup()
	return {
		type = "group",
		name = "Stance",
		order = 4,
		args = {
			stanceBarOrderHeader = {
				type = "header",
				name = "Stance bar slot order",
				order = 18,
			},
			stanceBarOrderDesc = {
				type = "description",
				name = "Drag to reorder. Right-click hide/show built-in slots. Right-click remove added spells and items. Drag a spell, item, macro, mount, toy, or pet onto the empty slot. Per character only.\n",
				order = 18.5,
				fontSize = "small",
			},
			stanceBarOrderReset = {
				type = "execute",
				name = "Reset stance bar order to default",
				desc = "Back to default order and show all built-in slots. Added spells and items stay.",
				order = 18.7,
				width = "full",
				func = function()
					if FluxOptions and FluxOptions.db and FluxOptions.db.char then
						local cab = FluxOptions.db.char.actionbars
						if cab then
							if cab.stanceBarSlotOrder then
								wipe(cab.stanceBarSlotOrder)
							else
								cab.stanceBarSlotOrder = {}
							end
							if cab.stanceBarHiddenSlots then
								wipe(cab.stanceBarHiddenSlots)
							else
								cab.stanceBarHiddenSlots = {}
							end
						end
					end
					local sb = _G.FluxStanceBar
					if sb and sb.ApplySavedSlotOrderAndRefresh then
						sb:ApplySavedSlotOrderAndRefresh()
					elseif ns.Flux and ns.Flux.Bars and ns.Flux.Bars.Stance and ns.Flux.Bars.Stance.RequestLayout then
						ns.Flux.Bars.Stance.RequestLayout("order")
					end
					if _G.FluxStanceBarOrderPanel_RequestRefresh then
						_G.FluxStanceBarOrderPanel_RequestRefresh()
					end
					AB.Notify()
				end,
			},
			stanceBarOrderPanel = {
				type = "description",
				name = " ",
				order = 19,
				width = "full",
				dialogControl = "FluxStanceBarOrderPanel",
			},
		},
	}
end
