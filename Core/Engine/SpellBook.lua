-- SpellBook.lua — coalesced, signature-gated SPELLS_CHANGED bus.
--
-- Blizzard re-fires SPELLS_CHANGED on shapeshift, vehicle swaps and zone
-- edges with the book unchanged, and every consumer used to answer each fire
-- with a full spellbook rescan. Consumers subscribe here instead:
--
--   OnChanged(key, fn)  fn runs once per REAL book change, after a 0.25s
--                       trailing debounce (held past an open FormStorm
--                       window so it merges with the settle, capped at 1s)
--
-- Repeat fires carrying an unchanged book-shape signature dispatch nothing
-- at all, so the form/vehicle SPELLS_CHANGED spam costs one signature read.
local addonName, ns = ...
local Flux = ns.Flux

local SpellBook = {}
Flux.SpellBook = SpellBook
Flux.Engine = Flux.Engine or {}
Flux.Engine.SpellBook = SpellBook

local pcall = pcall
local type = type
local tonumber = tonumber
local tconcat = table.concat

--- Trailing debounce: each new event pushes the flush out again.
local DEBOUNCE = 0.25
--- Re-arm hop while a FormStorm window is still open at flush time.
local STORM_HOP = 0.1
--- Hard cap from the first held event; a busy storm can never starve a flush.
local MAX_HOLD = 1

local pending = false
local dueAt = 0
local heldSince = 0
local lastSignature

local handlers, order = {}, {}

local function Now()
	return (GetTime and GetTime()) or 0
end

function SpellBook.OnChanged(key, fn)
	if type(key) ~= "string" or type(fn) ~= "function" then
		return
	end
	if handlers[key] == nil then
		order[#order + 1] = key
	end
	handlers[key] = fn
end

-- ---------------------------------------------------------------------------
-- Signature: coarse "book shape" — skill-line offsets/counts plus form count.
-- A real learn/unlearn moves an offset or a count; Blizzard's repeat fires
-- keep both identical, which is all this filter needs.
-- ---------------------------------------------------------------------------

local function Num(fn)
	if type(fn) ~= "function" then
		return 0
	end
	local ok, value = pcall(fn)
	if not ok then
		return 0
	end
	return tonumber(value) or 0
end

local function Signature()
	local parts = {}
	local SB = C_SpellBook
	if SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo then
		-- Retail / post-DF spellbook.
		local lines = Num(SB.GetNumSpellBookSkillLines)
		parts[#parts + 1] = lines
		for i = 1, lines do
			local ok, info = pcall(SB.GetSpellBookSkillLineInfo, i)
			if ok and type(info) == "table" then
				parts[#parts + 1] = (info.itemIndexOffset or 0) .. ":" .. (info.numSpellBookItems or 0)
			end
		end
	elseif GetNumSpellTabs and GetSpellTabInfo then
		-- Classic-family spellbook tabs.
		local tabs = Num(GetNumSpellTabs)
		parts[#parts + 1] = tabs
		for i = 1, tabs do
			local ok, _, _, offset, count = pcall(GetSpellTabInfo, i)
			if ok then
				parts[#parts + 1] = (offset or 0) .. ":" .. (count or 0)
			end
		end
	end
	parts[#parts + 1] = Num(GetNumShapeshiftForms)
	return tconcat(parts, "|")
end

local function Dispatch()
	local sig = Signature()
	if sig == lastSignature then
		if Flux.Perf then
			Flux.Perf.Count("spellbook.ignored")
		end
		return
	end
	lastSignature = sig
	if Flux.Perf then
		Flux.Perf.Count("spellbook.changed")
	end
	for i = 1, #order do
		local fn = handlers[order[i]]
		if fn then
			Flux.Safecall(fn)
		end
	end
end

local function StormOpen()
	local FS = Flux.FormStorm
	if not FS then
		return false
	end
	if FS.IsBursting and FS.IsBursting() then
		return true
	end
	if FS.IsSettling and FS.IsSettling() then
		return true
	end
	return false
end

local function Flush()
	local now = Now()
	if now < dueAt then
		Flux.Timer.After(dueAt - now, Flush)
		return
	end
	-- Merge with the storm settle instead of stacking on the burst frame.
	if StormOpen() and now < heldSince + MAX_HOLD then
		Flux.Timer.After(STORM_HOP, Flush)
		return
	end
	pending = false
	Dispatch()
end

local function OnSpellsChanged()
	local now = Now()
	dueAt = now + DEBOUNCE
	if pending then
		return
	end
	pending = true
	heldSince = now
	Flux.Timer.After(DEBOUNCE, Flush)
end

--- Recompute the signature without dispatch (login / load-screen warm-up).
function SpellBook.Sync()
	lastSignature = Signature()
end

Flux.AfterLoad(function()
	local Ev = Flux.Events
	if not Ev or not Ev.Register then
		return
	end
	SpellBook.Sync()
	Ev.Register("SPELLS_CHANGED", OnSpellsChanged)
	Ev.Register("PLAYER_ENTERING_WORLD", SpellBook.Sync)
end)
