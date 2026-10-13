-- FluxOptionsActionBars_Bindings.lua — Bindings sub-tab: Enter Binding Mode + reset Flux defaults.
local addonName, ns = ...
local AB = ns.FluxOptionsActionBars

function AB.GetBindingsGroup()
	return {
		type = "group",
		name = "Bindings",
		order = 2,
		args = {
			bindingHeader = {
				type = "header",
				name = "Key Bindings",
				order = 1,
			},
			bindingDesc = {
				type = "description",
				name = "Hover a button, press a key. ESC clears.\n",
				order = 2,
				fontSize = "medium",
			},
			enterBindingMode = {
				type = "execute",
				name = "Enter Binding Mode",
				desc = "Bind keys on your bars.",
				order = 3,
				width = "full",
				disabled = function()
					return InCombatLockdown()
				end,
				func = function()
					if not FluxBindingMode then
						return
					end
					if InCombatLockdown and InCombatLockdown() then
						return
					end
					-- Defer close: AceConfigDialog refreshes after execute and needs rootframe.
					C_Timer.After(0, function()
						if InCombatLockdown and InCombatLockdown() then
							return
						end
						if FluxOptions and FluxOptions.CloseConfig then
							FluxOptions:CloseConfig()
						end
						FluxBindingMode:Activate()
					end)
				end,
			},
			bindingCombatNote = {
				type = "description",
				name = "|cffff6666Cannot enter binding mode during combat.|r",
				order = 4,
				fontSize = "small",
				hidden = function()
					return not InCombatLockdown()
				end,
			},

			resetKeybindsHeader = {
				type = "header",
				name = "Reset keybindings",
				order = 5,
			},
			resetKeybindsDesc = {
				type = "description",
				name = "Reset all keys to Flux defaults.\n",
				order = 6,
				fontSize = "small",
			},
			resetKeybindsToFluxDefaults = {
				type = "execute",
				name = "Reset keybindings to Flux defaults",
				desc = "Clear binds and use Flux defaults.",
				order = 7,
				width = "full",
				confirm = true,
				confirmText = "Replace all key bindings with Flux defaults?",
				disabled = function()
					return InCombatLockdown()
				end,
				func = function()
					if FluxDefaultSettings and FluxDefaultSettings.ApplyKeybinds then
						FluxDefaultSettings.ApplyKeybinds()
					end
				end,
			},
			resetKeybindsCombatNote = {
				type = "description",
				name = "|cffff6666Cannot reset keybindings during combat.|r",
				order = 8,
				fontSize = "small",
				hidden = function()
					return not InCombatLockdown()
				end,
			},
		},
	}
end
