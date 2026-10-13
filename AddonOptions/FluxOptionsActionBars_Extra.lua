-- FluxOptionsActionBars_Extra.lua — Extra sub-tab: visibility, NC flyout, utility slots.
local addonName, ns = ...
local AB = ns.FluxOptionsActionBars

function AB.GetExtraGroup()
	return {
		type = "group",
		name = "Extra",
		order = 3,
		args = {
			extraButtonsHeader = {
				type = "header",
				name = "Extra buttons (visibility)",
				order = 20,
			},
			extraButtonsDesc = {
				type = "description",
				name = "Click to change visibility. O=Off, A=Auto, +=Always, H=Hidden.\n",
				order = 21,
				fontSize = "small",
			},
			extraButtonVisibilityReset = {
				type = "execute",
				name = "Reset extra button visibility to defaults",
				desc = "Reset all extra buttons for this scope.",
				order = 22,
				width = "full",
				confirm = true,
				confirmText = "Reset extra button visibility to defaults?",
				func = function()
					if FluxExtraButtonVisibility and FluxExtraButtonVisibility.ResetToDefaults then
						FluxExtraButtonVisibility.ResetToDefaults()
					end
				end,
			},
			extraButtonVisibilityPanel = {
				type = "description",
				name = " ",
				order = 23,
				width = "full",
				dialogControl = "FluxExtraButtonVisibilityPanel",
			},

			consumableSwapHeader = {
				type = "header",
				name = "Food, water, and potions",
				order = 23.05,
			},
			consumableSwapDesc = {
				type = "description",
				name = "Off for both is the starting setup, so food, water, and potions stay on their own buttons. Turn on one side, the other, or both. Each option puts a [combat] / [nocombat] use on that button. Right-click still conjures or crafts for that button.\n",
				order = 23.06,
				fontSize = "small",
			},
			consumableSwapFoodWater = {
				type = "toggle",
				name = "Food and water become potions in combat",
				desc = "Food uses your healing potion in combat. Water uses your mana potion in combat. Out of combat they stay food and water, or Recuperate if the food button is showing that. Both sides need to be available.",
				order = 23.07,
				width = "full",
				get = function()
					local Bridge = _G.FluxEBSConsumableBridge
					if Bridge and Bridge.GetConsumableCombatSwap then
						return Bridge.GetConsumableCombatSwap("foodWater")
					end
					local t = AB.ActionbarsDB()
					return t and t.consumableCombatSwap and t.consumableCombatSwap.foodWater == true
				end,
				set = function(_, val)
					local Bridge = _G.FluxEBSConsumableBridge
					if Bridge and Bridge.SetConsumableCombatSwap then
						Bridge.SetConsumableCombatSwap("foodWater", val)
						return
					end
					local t = AB.ActionbarsDB()
					if not t then
						return
					end
					t.consumableCombatSwap = t.consumableCombatSwap or {}
					t.consumableCombatSwap.foodWater = val and true or false
				end,
			},
			consumableSwapPotions = {
				type = "toggle",
				name = "Potions become food and water out of combat",
				desc = "The healing potion button uses food out of combat. The mana potion button uses water out of combat. In combat they stay potions. Both items need to be in your bags.",
				order = 23.08,
				width = "full",
				get = function()
					local Bridge = _G.FluxEBSConsumableBridge
					if Bridge and Bridge.GetConsumableCombatSwap then
						return Bridge.GetConsumableCombatSwap("potions")
					end
					local t = AB.ActionbarsDB()
					return t and t.consumableCombatSwap and t.consumableCombatSwap.potions == true
				end,
				set = function(_, val)
					local Bridge = _G.FluxEBSConsumableBridge
					if Bridge and Bridge.SetConsumableCombatSwap then
						Bridge.SetConsumableCombatSwap("potions", val)
						return
					end
					local t = AB.ActionbarsDB()
					if not t then
						return
					end
					t.consumableCombatSwap = t.consumableCombatSwap or {}
					t.consumableCombatSwap.potions = val and true or false
				end,
			},

			ncFlyoutPanel = {
				type = "description",
				name = "Per character. Click hide, drag reorder, right-click favorite.\n",
				order = 23.35,
				width = "full",
				fontSize = "small",
				dialogControl = "FluxNCFlyoutPanel",
			},

			spellbookSlotsHeader = {
				type = "header",
				name = "Utility slots",
				order = 24,
			},
			spellbookSlotsDesc = {
				type = "description",
				name = "Drag spell/item/macro/mount/toy. Hold Shift/Ctrl/Alt for that modifier. Drag off to clear, or clear in options.\n",
				order = 25,
				fontSize = "small",
			},
			spellbookSlotsPanel = {
				type = "description",
				name = " ",
				order = 26,
				width = "full",
				dialogControl = "FluxSpellBookSlotsPanel",
			},
		},
	}
end
