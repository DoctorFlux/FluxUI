-- Inventory/Builtin/Void.lua — void storage while the vault is open.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory
local Builtin = Inv.Builtin
local Store = Inv.Store
local Cap = Flux.Cap

local Void = {}
Builtin.Void = Void

local started = false
local vaultOpen = false
local PAGES = 2
local SLOTS = 80

local function Request()
	Flux.Scheduler.Request("inventory", "void")
end

local function NumericID(value)
	local n = tonumber(value)
	if n and n > 0 then
		return n
	end
	if Flux.Secrets and Flux.Secrets.SafeGetNumber then
		n = Flux.Secrets.SafeGetNumber(value, 0)
		if n and n > 0 then
			return n
		end
	end
	return nil
end

function Void.Refresh()
	if Store.UsesSyndicator() or not Cap.hasVoidStorage then
		return
	end
	if not vaultOpen then
		return
	end
	if CanUseVoidStorage and not CanUseVoidStorage() then
		return
	end
	local snap = Inv.snapshots.void
	if not snap then
		return
	end
	if wipe then
		wipe(snap.byBag)
	else
		for k in pairs(snap.byBag) do
			snap.byBag[k] = nil
		end
	end
	local counts = {}
	local stored = {}
	for page = 1, PAGES do
		local dest = {}
		stored[page] = dest
		snap.byBag[page] = dest
		for slot = 1, SLOTS do
			local itemID, icon, _, _, _, quality = GetVoidItemInfo(page, slot)
			itemID = NumericID(itemID)
			if itemID then
				local link
				if GetVoidItemHyperlinkString then
					link = GetVoidItemHyperlinkString((page - 1) * SLOTS + slot)
				end
				dest[slot] = { itemID = itemID, count = 1, link = link }
				counts[itemID] = (counts[itemID] or 0) + 1
			end
		end
	end
	snap.counts = counts
	snap.generation = (snap.generation or 0) + 1
	local char = Store.EnsureCurrentCharacter()
	if char then
		char.void = stored
		Store.MarkPending(nil, "all")
	end
end

function Void.Start()
	if started or Store.UsesSyndicator() or not Cap.hasVoidStorage then
		return
	end
	started = true
	Flux.Events.Register("VOID_TRANSFER_DONE", function()
		vaultOpen = true
		Request()
	end)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
		local e = Enum and Enum.PlayerInteractionType
		if e and kind == e.VoidStorageBanker then
			vaultOpen = true
			Request()
		end
	end)
	Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
		local e = Enum and Enum.PlayerInteractionType
		if e and kind == e.VoidStorageBanker then
			vaultOpen = false
		end
	end)
end
