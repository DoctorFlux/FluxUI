-- Init.lua — WindowMover module boot + /fluxwindows
--
-- In-game checks (Era / Anniversary / MoP / Retail 12.1):
--   Character drag persists across reload; Merchant restock tab still clicks;
--   map title-drag (not pan); bags (Blizzard or Baganator); lock; reset; combat
--   with no taint spam. Retail: Settings, Player Spells, Combined Bags, housing.
--   Action strip / unit frames / minimap must not get mover overlays.
local addonName, ns = ...
local Flux = ns.Flux

local WindowMover = Flux.WindowMover or {}
Flux.WindowMover = WindowMover

function WindowMover.SetEnabled(enabled)
	local db = _G.FluxOptions and FluxOptions.GetWindowMoverDB and FluxOptions:GetWindowMoverDB()
	if db then
		db.enabled = enabled and true or false
	end
	if enabled then
		WindowMover.Start()
	end
	WindowMover.Refresh()
end

Flux.Module.Register("WindowMover", {
	phase = "deferred",
	clients = { era = true, anniversary = true, classic = true, midnight = true },
	OnEnable = function()
		WindowMover.Start()
	end,
})

local function PrintStatus()
	local db = WindowMover.Settings and WindowMover.Settings() or {}
	local yn = function(v)
		return v and "yes" or "no"
	end
	if Flux.Print then
		Flux.Print("Window mover")
	end
	print("  enabled=" .. yn(db.enabled)
		.. " lock=" .. yn(db.lock)
		.. " scale=" .. yn(db.scaleEnabled)
		.. " savePos=" .. yn(db.savePosition)
		.. " saveScale=" .. yn(db.saveScale)
		.. " modifier=" .. (db.requireModifier and tostring(db.modifier or "SHIFT") or "off")
		.. " snap=" .. tostring(db.snap or 0)
		.. " attached=" .. tostring(WindowMover.AttachedCount and WindowMover.AttachedCount() or 0))
end

SLASH_FLUXWINDOWS1 = "/fluxwindows"
SlashCmdList["FLUXWINDOWS"] = function(msg)
	msg = msg and msg:match("^%s*(.-)%s*$") or ""
	msg = msg:lower()
	if msg == "lock" then
		WindowMover.SetLocked(true)
		if Flux.Print then
			Flux.Print("Windows locked")
		end
		return
	end
	if msg == "unlock" then
		WindowMover.SetLocked(false)
		if Flux.Print then
			Flux.Print("Windows unlocked")
		end
		return
	end
	if msg == "reset" then
		WindowMover.ResetAll()
		return
	end
	if msg == "scan" then
		local n = WindowMover.Scan and WindowMover.Scan() or 0
		if Flux.Print then
			Flux.Print("Window scan attached " .. tostring(n) .. " (total live " .. tostring(WindowMover.AttachedCount()) .. ")")
		end
		return
	end
	if msg == "smoke" then
		local failures = WindowMover.Smoke and WindowMover.Smoke() or { "Smoke missing" }
		if #failures == 0 then
			if Flux.Print then
				Flux.Print("Window mover smoke: OK")
			end
		else
			if Flux.Print then
				Flux.Print("Window mover smoke: " .. tostring(#failures) .. " failures")
			end
			for i = 1, math.min(#failures, 12) do
				print("  " .. failures[i])
			end
		end
		return
	end
	if msg == "help" then
		if Flux.Print then
			Flux.Print("/fluxwindows — left-drag move, right-drag scale, middle-click reset")
		end
		print("  /fluxwindows lock | unlock | reset | scan | smoke")
		print("  Optional Shift/Ctrl/Alt modifier is on the /fluxui Windows tab.")
		print("  HUD (bars, unit frames, minimap, chat) is not moved here.")
		return
	end
	PrintStatus()
end
