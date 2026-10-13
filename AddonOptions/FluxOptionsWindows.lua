local addonName, ns = ...

local function NotifyFluxUIConfig()
	local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
	if ACR then
		ACR:NotifyChange("FluxUI")
	end
end

local function WM()
	return _G.Flux and _G.Flux.WindowMover
end

local function GetDB()
	if FluxOptions and FluxOptions.GetWindowMoverDB then
		return FluxOptions:GetWindowMoverDB()
	end
	return nil
end

local function RefreshMover()
	local mover = WM()
	if mover and mover.Refresh then
		mover.Refresh()
	end
end

local function BuildWindowsOptions()
	return {
		name = "Windows",
		type = "group",
		order = 3,
		args = {
			intro = {
				type = "description",
				name = "Drag Blizzard windows (Character, bags, map, auction, popups). Left-drag moves, right-drag scales, middle-click resets. Flux HUD (bars, unit frames, minimap, chat) stays on the Layout tab.\n",
				order = 0,
				fontSize = "medium",
				width = "full",
			},
			scopeHeader = {
				type = "header",
				name = "Scope",
				order = 1,
			},
			settingsScope = {
				type = "select",
				name = "Windows scope",
				desc = "Account-wide or per character. Windows tab only.",
				order = 2,
				width = "full",
				values = {
					account = "Account-wide",
					character = "Character-specific",
				},
				sorting = { "account", "character" },
				get = function()
					return FluxOptions:IsWindowMoverCharacterSpecific() and "character" or "account"
				end,
				set = function(_, val)
					FluxOptions:SetWindowMoverCharacterSpecific(val == "character")
					NotifyFluxUIConfig()
				end,
			},
			behaviorHeader = {
				type = "header",
				name = "Behavior",
				order = 10,
			},
			enabled = {
				type = "toggle",
				name = "Enable window mover",
				desc = "Allow dragging and scaling Blizzard windows.",
				order = 11,
				width = "full",
				get = function()
					local db = GetDB()
					return not db or db.enabled ~= false
				end,
				set = function(_, val)
					local db = GetDB()
					if not db then
						return
					end
					db.enabled = val and true or false
					RefreshMover()
				end,
			},
			lock = {
				type = "toggle",
				name = "Lock windows",
				desc = "Keep saved positions but ignore drag, scale, and reset. /fluxwindows lock",
				order = 12,
				width = "full",
				get = function()
					local db = GetDB()
					return db and db.lock and true or false
				end,
				set = function(_, val)
					local db = GetDB()
					if not db then
						return
					end
					db.lock = val and true or false
				end,
			},
			scaleEnabled = {
				type = "toggle",
				name = "Allow scaling",
				desc = "Right-drag a window to scale it (50%–250%).",
				order = 13,
				width = "full",
				get = function()
					local db = GetDB()
					return not db or db.scaleEnabled ~= false
				end,
				set = function(_, val)
					local db = GetDB()
					if not db then
						return
					end
					db.scaleEnabled = val and true or false
				end,
			},
			savePosition = {
				type = "toggle",
				name = "Save positions",
				desc = "Remember window positions across reloads.",
				order = 14,
				width = "full",
				get = function()
					local db = GetDB()
					return not db or db.savePosition ~= false
				end,
				set = function(_, val)
					local db = GetDB()
					if not db then
						return
					end
					db.savePosition = val and true or false
				end,
			},
			saveScale = {
				type = "toggle",
				name = "Save scale",
				desc = "Remember window scale across reloads.",
				order = 15,
				width = "full",
				get = function()
					local db = GetDB()
					return not db or db.saveScale ~= false
				end,
				set = function(_, val)
					local db = GetDB()
					if not db then
						return
					end
					db.saveScale = val and true or false
				end,
			},
			clampToScreen = {
				type = "toggle",
				name = "Clamp to screen",
				desc = "Keep moved windows on screen.",
				order = 16,
				width = "full",
				get = function()
					local db = GetDB()
					return not db or db.clampToScreen ~= false
				end,
				set = function(_, val)
					local db = GetDB()
					if not db then
						return
					end
					db.clampToScreen = val and true or false
					RefreshMover()
				end,
			},
			modifierHeader = {
				type = "header",
				name = "Modifier",
				order = 20,
			},
			requireModifier = {
				type = "toggle",
				name = "Require modifier to drag",
				desc = "Only move/scale/reset while holding the key below. Useful so Merchant and auction clicks are never stolen.",
				order = 21,
				width = "full",
				get = function()
					local db = GetDB()
					return db and db.requireModifier and true or false
				end,
				set = function(_, val)
					local db = GetDB()
					if not db then
						return
					end
					db.requireModifier = val and true or false
				end,
			},
			modifier = {
				type = "select",
				name = "Modifier key",
				order = 22,
				width = "full",
				values = {
					SHIFT = SHIFT_KEY or "Shift",
					CTRL = CTRL_KEY or "Ctrl",
					ALT = ALT_KEY or "Alt",
				},
				sorting = { "SHIFT", "CTRL", "ALT" },
				disabled = function()
					local db = GetDB()
					return not (db and db.requireModifier)
				end,
				get = function()
					local db = GetDB()
					return (db and db.modifier) or "SHIFT"
				end,
				set = function(_, val)
					local db = GetDB()
					if not db then
						return
					end
					db.modifier = val
				end,
			},
			snap = {
				type = "range",
				name = "Snap size",
				desc = "0 = no snap. Pixel grid for window positions.",
				order = 23,
				width = "full",
				min = 0,
				max = 64,
				step = 1,
				get = function()
					local db = GetDB()
					return db and db.snap or 0
				end,
				set = function(_, val)
					local db = GetDB()
					if not db then
						return
					end
					db.snap = val
				end,
			},
			reset = {
				type = "execute",
				name = "Reset all window positions",
				desc = "Clear saved positions and scales. Reopen windows to restore Blizzard layout.",
				order = 30,
				width = "full",
				confirm = true,
				confirmText = "Reset all saved window positions?",
				func = function()
					local mover = WM()
					if mover and mover.ResetAll then
						mover.ResetAll()
					elseif FluxOptions and FluxOptions.ResetWindowMoverToDefaults then
						FluxOptions:ResetWindowMoverToDefaults()
					end
					NotifyFluxUIConfig()
				end,
			},
		},
	}
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, _, loadedAddon)
	if loadedAddon ~= addonName then
		return
	end
	self:UnregisterEvent("ADDON_LOADED")
	if FluxOptions and FluxOptions.RegisterModuleOptions then
		FluxOptions:RegisterModuleOptions("windows", BuildWindowsOptions)
	end
end)

