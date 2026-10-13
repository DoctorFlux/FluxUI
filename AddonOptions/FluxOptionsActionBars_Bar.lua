-- FluxOptionsActionBars_Bar.lua — Bar sub-tab: scope, minirow, VFX, mouseover, rank-up, performance.
local addonName, ns = ...
local Flux = ns.Flux
local AB = ns.FluxOptionsActionBars

local function NativeMouseoverCast()
	return C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("enableMouseoverCast") ~= nil
end

local function UsesNativeCVar()
	local MC = AB.MouseoverCast and AB.MouseoverCast()
	if MC and MC.UsesNativeCVar then
		return MC.UsesNativeCVar()
	end
	return false
end

local function ApplyPerformance()
	if Flux and Flux.Bars and Flux.Bars.ApplyPerformanceSettings then
		Flux.Bars.ApplyPerformanceSettings()
	end
end

function AB.GetBarGroup()
	return {
		type = "group",
		name = "Bar",
		order = 1,
		args = {
			scopeHeader = {
				type = "header",
				name = "Scope",
				order = 0,
			},
			settingsScope = {
				type = "select",
				name = "Action bar scope",
				desc = "Same settings for all chars, or just this one.",
				order = 0.5,
				width = "full",
				values = {
					account = "Account-wide",
					character = "Character-specific",
				},
				sorting = { "account", "character" },
				get = function()
					if FluxOptions and FluxOptions.IsActionbarsCharacterSpecific
						and FluxOptions:IsActionbarsCharacterSpecific() then
						return "character"
					end
					return "account"
				end,
				set = function(_, val)
					if FluxOptions and FluxOptions.SetActionbarsCharacterSpecific then
						FluxOptions:SetActionbarsCharacterSpecific(val == "character")
					end
					AB.Notify()
				end,
			},

			layoutHeader = {
				type = "header",
				name = "Layout",
				order = 10,
			},
			minirowPosition = {
				type = "select",
				name = "Minirow position",
				desc = "Shift/ctrl rows above or below the main bar.",
				order = 11,
				width = "full",
				values = {
					top = "Top (default)",
					bottom = "Bottom",
				},
				sorting = { "top", "bottom" },
				get = function()
					local t = AB.ActionbarsDB()
					if t then
						return t.minirowPosition or "top"
					end
					return "top"
				end,
				set = function(_, val)
					local t = AB.ActionbarsDB()
					if t then
						t.minirowPosition = val
					end
					if Flux and Flux.Bars and Flux.Bars.RequestLayout then
						Flux.Bars.RequestLayout("minirow")
					end
				end,
			},

			vfxHeader = {
				type = "header",
				name = "Action Bar VFX",
				order = 11.05,
				hidden = function()
					return not AB.IsPreDF()
				end,
			},
			vfxDesc = {
				type = "description",
				name = "Cast and target effects on buttons. Older clients only.\n",
				order = 11.06,
				fontSize = "small",
				hidden = function()
					return not AB.IsPreDF()
				end,
			},
			spellCastVFX = {
				type = "toggle",
				name = "Enable action bar VFX",
				desc = "Show cast and target effects on action buttons.",
				order = 11.1,
				width = "full",
				hidden = function()
					return not AB.IsPreDF()
				end,
				get = function()
					local t = AB.ActionbarsDB()
					if t and t.spellCastVFX == false then
						return false
					end
					return true
				end,
				set = function(_, val)
					local t = AB.ActionbarsDB()
					if t then
						t.spellCastVFX = val and true or false
					end
					if Flux and Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.RefreshFromOptions then
						Flux.ButtonFX.Cast.RefreshFromOptions()
					end
				end,
			},

			mouseoverCastHeader = {
				type = "header",
				name = "Mouseover casting",
				order = 11.2,
			},
			mouseoverCastDesc = {
				type = "description",
				name = "Matches the spell book setting.\n",
				order = 11.25,
				fontSize = "small",
			},
			mouseoverCast = {
				type = "toggle",
				name = "Mouseover cast",
				desc = "Cast on the unit under your cursor. On Forever this drives Blizzard's enableMouseoverCast CVar. On other clients, plain action slots use click-time targeting and Flux keybind macros get an [@mouseover] clause baked into their macro text.\n\nA keybind that already picks its own target (Targets tab in the binding editor) keeps that target and ignores this.",
				order = 11.3,
				width = "full",
				get = function()
					local MC = AB.MouseoverCast()
					if MC and MC.IsEnabled then
						return MC.IsEnabled()
					end
					local t = AB.ActionbarsDB()
					return not t or t.mouseoverCast ~= false
				end,
				set = function(_, val)
					local MC = AB.MouseoverCast()
					if MC and MC.SetEnabled then
						MC.SetEnabled(val and true or false)
						return
					end
					local t = AB.ActionbarsDB()
					if t then
						t.mouseoverCast = val and true or false
					end
					if MC and MC.Apply then
						MC.Apply()
					end
				end,
			},
			mouseoverCastNative = {
				type = "description",
				name = "Flux mouseover-cast uses click-time targeting. Blizzard's enableMouseoverCast CVar stays off so world nameplate sweeps do not retarget every action slot.",
				order = 11.32,
				fontSize = "small",
				width = "full",
				hidden = function()
					return not NativeMouseoverCast() or UsesNativeCVar()
				end,
			},
			mouseoverCastNativeForever = {
				type = "description",
				name = "This client uses Blizzard mouseover-cast. The Action Bars toggle drives enableMouseoverCast.",
				order = 11.321,
				fontSize = "small",
				width = "full",
				hidden = function()
					return not UsesNativeCVar()
				end,
			},
			mouseoverCastCombat = {
				type = "description",
				name = "|cffffcc00Changing this in combat applies when you leave combat.|r",
				order = 11.33,
				fontSize = "small",
				width = "full",
				hidden = function()
					return not (InCombatLockdown and InCombatLockdown())
				end,
			},

			spellbookHeader = {
				type = "header",
				name = "Auto Rank up",
				order = 12,
				hidden = function()
					return not AB.RankSupported()
				end,
			},
			spellbookDesc = {
				type = "description",
				name = "Forever, Classic Era, and Anniversary. Not on live Midnight.\n",
				order = 13,
				fontSize = "small",
				hidden = function()
					return not AB.RankSupported()
				end,
			},
			autoRankUp = {
				type = "toggle",
				name = "Auto rank up",
				desc = "Upgrade spells when you learn a higher rank.",
				order = 14,
				width = "full",
				hidden = function()
					return not AB.RankSupported()
				end,
				get = function()
					if FluxSpellRankManagerModule and FluxSpellRankManagerModule.GetAutoRankUpEnabled then
						return FluxSpellRankManagerModule:GetAutoRankUpEnabled()
					end
					return false
				end,
				set = function(_, val)
					if FluxSpellRankManagerModule and FluxSpellRankManagerModule.SetAutoRankUpEnabled then
						FluxSpellRankManagerModule:SetAutoRankUpEnabled(val)
					end
				end,
			},
			rankUpAllSpells = {
				type = "execute",
				name = "Rank up all spells",
				desc = "Replace lower ranks with your highest rank now.",
				order = 15,
				width = "full",
				hidden = function()
					return not AB.RankSupported()
				end,
				disabled = function()
					return InCombatLockdown()
				end,
				func = function()
					if FluxSpellRankManagerModule and FluxSpellRankManagerModule.RankUpAllSpells then
						FluxSpellRankManagerModule:RankUpAllSpells()
					end
				end,
			},
			blacklistHelp = {
				type = "description",
				name = "Blacklisted spells:\n",
				order = 16,
				fontSize = "small",
				hidden = function()
					return not AB.RankSupported()
				end,
			},
			blacklistPanel = {
				type = "description",
				name = " ",
				order = 17,
				width = "full",
				hidden = function()
					return not AB.RankSupported()
				end,
				dialogControl = "FluxSpellBlacklistPanel",
			},

			perfHeader = {
				type = "header",
				name = "Performance",
				order = 17.4,
			},
			perfDesc = {
				type = "description",
				name = "Lower = faster updates, more CPU.\n",
				order = 17.41,
				fontSize = "small",
			},
			rangeCheckInterval = {
				type = "range",
				name = "Range check interval",
				desc = "How often action bar buttons check range.",
				order = 17.42,
				min = 0.1,
				max = 1.0,
				step = 0.05,
				get = function()
					local t = AB.ActionbarsDB()
					if t and t.rangeCheckInterval then
						return t.rangeCheckInterval
					end
					return 0.25
				end,
				set = function(_, val)
					local t = AB.ActionbarsDB()
					if t then
						t.rangeCheckInterval = val
					end
					ApplyPerformance()
				end,
			},
			extraButtonRangeCheckInterval = {
				type = "range",
				name = "Extra button range interval",
				desc = "How often extra grid buttons check range.",
				order = 17.43,
				min = 0.1,
				max = 1.0,
				step = 0.05,
				get = function()
					local t = AB.ActionbarsDB()
					if t and t.extraButtonRangeCheckInterval then
						return t.extraButtonRangeCheckInterval
					end
					return 0.18
				end,
				set = function(_, val)
					local t = AB.ActionbarsDB()
					if t then
						t.extraButtonRangeCheckInterval = val
					end
					ApplyPerformance()
				end,
			},
			mouseoverUpdateInterval = {
				type = "range",
				name = "Mouseover update interval",
				desc = "How often mouseover macros refresh their tint.",
				order = 17.435,
				min = 0.04,
				max = 0.2,
				step = 0.01,
				get = function()
					local t = AB.ActionbarsDB()
					if t and t.mouseoverUpdateInterval then
						return t.mouseoverUpdateInterval
					end
					return 0.07
				end,
				set = function(_, val)
					local t = AB.ActionbarsDB()
					if t then
						t.mouseoverUpdateInterval = val
					end
					ApplyPerformance()
				end,
			},
			macroUsableMinInterval = {
				type = "range",
				name = "Macro usable interval",
				desc = "Delay between macro usability updates. 0 = off.",
				order = 17.44,
				min = 0,
				max = 0.5,
				step = 0.01,
				get = function()
					local t = AB.ActionbarsDB()
					if t and t.macroUsableMinInterval ~= nil then
						return t.macroUsableMinInterval
					end
					return 0.05
				end,
				set = function(_, val)
					local t = AB.ActionbarsDB()
					if t then
						t.macroUsableMinInterval = val
					end
					ApplyPerformance()
				end,
			},
			actionUsableMinInterval = {
				type = "range",
				name = "Action usable interval",
				desc = "Delay between button usability updates. 0 = off.",
				order = 17.45,
				min = 0,
				max = 0.5,
				step = 0.01,
				get = function()
					local t = AB.ActionbarsDB()
					if t and t.actionUsableMinInterval ~= nil then
						return t.actionUsableMinInterval
					end
					return 0
				end,
				set = function(_, val)
					local t = AB.ActionbarsDB()
					if t then
						t.actionUsableMinInterval = val
					end
					ApplyPerformance()
				end,
			},
			macroSmartLayoutPerfDesc = {
				type = "description",
				name = "Macro buttons won't move minirows unless needed.\n",
				order = 17.5,
				fontSize = "small",
			},
		},
	}
end
