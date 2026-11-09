-- Identity.lua — shown-face publisher for glow / checked / range.
-- Surfaces publish { kind, id } of what is *shown* after TranslateMacro, not
-- the underlying action occupancy. Soft sync on display-tier flips.
-- No Binding Apply. This step is API + last-sig skip only.
local addonName, ns = ...
local Flux = ns.Flux

local Identity = {}
Flux.Identity = Identity
Flux.Engine = Flux.Engine or {}
Flux.Engine.Identity = Identity

local surfaces = {}
local shown = {}
local lastSig = {}
local changeListeners = {}
local stats = {
	publishes = 0,
	skipped = 0,
	changes = 0,
}

local function Sig(kind, id)
	if kind == nil and id == nil then
		return ""
	end
	return tostring(kind or "") .. ":" .. tostring(id or "")
end

function Identity.SlotKey(slot)
	return "slot:" .. tostring(slot)
end

function Identity.BadgeKey(slot, index)
	return "badge:" .. tostring(slot) .. ":" .. tostring(index or 1)
end

function Identity.ParseSlotKey(key)
	if type(key) ~= "string" then
		return nil
	end
	local slot = string.match(key, "^slot:(%d+)$")
	return slot and tonumber(slot) or nil
end

function Identity.ParseBadgeKey(key)
	if type(key) ~= "string" then
		return nil
	end
	local slot, index = string.match(key, "^badge:(%d+):(%d+)$")
	if not slot then
		return nil
	end
	return tonumber(slot), tonumber(index)
end

--- Register a surface. key is a stable id (slot, extra button name, ...).
--- surface is an optional widget/host table later steps attach glow to.
function Identity.Register(key, surface)
	if key == nil then
		return
	end
	surfaces[key] = surface or true
end

function Identity.Unregister(key)
	if key == nil then
		return
	end
	surfaces[key] = nil
	shown[key] = nil
	lastSig[key] = nil
end

function Identity.Has(key)
	return surfaces[key] ~= nil
end

--- Publish the live shown face. Returns true when the identity actually changed.
function Identity.Publish(key, kind, id)
	if key == nil then
		return false
	end
	stats.publishes = stats.publishes + 1
	local sig = Sig(kind, id)
	if lastSig[key] == sig then
		stats.skipped = stats.skipped + 1
		return false
	end
	lastSig[key] = sig
	if kind == nil and id == nil then
		shown[key] = nil
	else
		shown[key] = { kind = kind, id = id }
	end
	stats.changes = stats.changes + 1
	for i = 1, #changeListeners do
		Flux.Safecall(changeListeners[i], key, kind, id)
	end
	return true
end

function Identity.Get(key)
	local rec = shown[key]
	if not rec then
		return nil
	end
	return rec.kind, rec.id
end

function Identity.GetRecord(key)
	return shown[key]
end

--- Notify change listeners of current identities. Display-tier only — no Apply.
function Identity.SoftSync()
	for key, rec in pairs(shown) do
		local kind, id = rec.kind, rec.id
		for i = 1, #changeListeners do
			Flux.Safecall(changeListeners[i], key, kind, id)
		end
	end
end

function Identity.OnChange(fn)
	if type(fn) ~= "function" then
		return
	end
	changeListeners[#changeListeners + 1] = fn
end

function Identity.GetStats()
	return stats
end

function Identity.ResetStats()
	for k in pairs(stats) do
		stats[k] = 0
	end
end
