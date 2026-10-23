-- Scheduler.lua — shared tiered refresh bus.
-- Tiers are orthogonal: a modifier/layout edge must not escalate into eval or inventory.
-- Coalesce to the next frame. One flush per tier per frame.
-- Combat defers structural work.
--
-- Order: layout → display → eval → structural → inventory.
-- layout    = secure paging / CHILDUPDATE only
-- display   = fingerprint-gated icon / usable / badge paint (never Binding Apply)
-- eval      = TranslateMacro / occupancy apply / Binding plan
-- Display never escalates into eval: requesting display does not request eval.
--
-- Eval (and display) requested while layout is paging is DEFERRED, never dropped:
-- the flush runs those buckets immediately after layout in the same frame.
-- Dropping eval is what forced every module to grow a private 50ms OnUpdate
-- settle driver to repaint what the scheduler had thrown away (form-change hitch).
-- No settle re-pass.
local addonName, ns = ...
local Flux = ns.Flux

local Scheduler = {}
Flux.Scheduler = Scheduler
Flux.Engine = Flux.Engine or {}
Flux.Engine.Scheduler = Scheduler

local type = type

Scheduler.TIERS = {
	layout = 1,
	display = 2,
	eval = 3,
	structural = 4,
	inventory = 5,
}

local TIERS = Scheduler.TIERS
local ORDER = { "layout", "display", "eval", "structural", "inventory" }

local listeners = {
	layout = {},
	display = {},
	eval = {},
	structural = {},
	inventory = {},
}

local pending = {
	layout = nil,
	display = nil,
	eval = nil,
	structural = nil,
	inventory = nil,
}

local stats = {
	flushes = 0,
	tierFlushes = { layout = 0, display = 0, eval = 0, structural = 0, inventory = 0 },
	deferredEval = 0,
	deferredDisplay = 0,
	deferredStructural = 0,
	requests = { layout = 0, display = 0, eval = 0, structural = 0, inventory = 0 },
}

Scheduler.stats = stats

local flushScheduled = false
local paging = false
local INVENTORY_MAX_PER_FLUSH = 8

local function NewBucket()
	return { tokens = {}, fns = {}, reasons = {} }
end

local function Merge(tier, token, fn, reason)
	local bucket = pending[tier]
	if not bucket then
		bucket = NewBucket()
		pending[tier] = bucket
	end
	if token ~= nil then
		bucket.tokens[token] = true
	end
	if type(fn) == "function" then
		bucket.fns[#bucket.fns + 1] = fn
	end
	if reason then
		bucket.reasons[reason] = true
	end
end

function Scheduler.Register(tier, fn)
	if not TIERS[tier] or type(fn) ~= "function" then
		return
	end
	local list = listeners[tier]
	list[#list + 1] = fn
end

function Scheduler.BeginPaging()
	paging = true
end

function Scheduler.EndPaging()
	paging = false
end

function Scheduler.IsPaging()
	return paging
end

--- Request work on a tier. token is a merge key (column, region, ...). fn runs at flush.
function Scheduler.Request(tier, token, fn, reason)
	if not TIERS[tier] then
		return
	end
	stats.requests[tier] = (stats.requests[tier] or 0) + 1

	if paging then
		if tier == "eval" then
			-- Keep it. Flush runs eval after layout (and display) in this frame.
			stats.deferredEval = stats.deferredEval + 1
		elseif tier == "display" then
			stats.deferredDisplay = stats.deferredDisplay + 1
		end
	end

	if tier == "layout" then
		paging = true
	end

	-- Retain every request in the shared bucket; a named combat callback must
	-- wake the bucket rather than replace the previous caller's closure.
	Merge(tier, token, fn, reason)
	if tier == "structural" and Flux.Combat and Flux.Combat.InLockdown() then
		stats.deferredStructural = stats.deferredStructural + 1
		Flux.Combat.Defer("scheduler.structural.flush", Scheduler.Flush)
		return
	end

	if not flushScheduled then
		flushScheduled = true
		Flux.Timer.After(0, Scheduler.Flush)
	end
end

function Scheduler.HasPending(tier)
	if tier then return pending[tier] ~= nil end
	for i = 1, #ORDER do
		if pending[ORDER[i]] then
			return true
		end
	end
	return false
end

local RunBucket
local function PauseStructural(tier, bucket)
	if tier ~= "structural" or not (Flux.Combat and Flux.Combat.InLockdown()) then return false end
	Flux.Combat.Defer("scheduler.structural.resume." .. tostring(bucket), function() RunBucket(tier, bucket) end)
	return true
end

RunBucket = function(tier, bucket)
	if not bucket then
		return
	end
	stats.tierFlushes[tier] = (stats.tierFlushes[tier] or 0) + 1

	local fns = bucket.fns
	for i = bucket.nextFn or 1, #fns do
		if PauseStructural(tier, bucket) then return end
		Flux.Safecall(fns[i], bucket.tokens, bucket.reasons)
		if tier == "structural" then bucket.nextFn = i + 1 end
	end

	local list = listeners[tier]
	for i = bucket.nextListener or 1, #list do
		if PauseStructural(tier, bucket) then return end
		Flux.Safecall(list[i], bucket.tokens, bucket.reasons)
		if tier == "structural" then bucket.nextListener = i + 1 end
	end
end

local function RunInventory(bucket)
	if not bucket then
		return
	end
	stats.tierFlushes.inventory = stats.tierFlushes.inventory + 1

	local n = 0
	local fns = bucket.fns
	local remain = {}
	for i = 1, #fns do
		if n < INVENTORY_MAX_PER_FLUSH then
			Flux.Safecall(fns[i], bucket.tokens, bucket.reasons)
			n = n + 1
		else
			remain[#remain + 1] = fns[i]
		end
	end

	local list = listeners.inventory
	for i = 1, #list do
		Flux.Safecall(list[i], bucket.tokens, bucket.reasons)
	end

	if #remain > 0 then
		local leftover = NewBucket()
		leftover.tokens = bucket.tokens
		leftover.reasons = bucket.reasons
		leftover.fns = remain
		pending.inventory = leftover
		if not flushScheduled then
			flushScheduled = true
			Flux.Timer.After(0, Scheduler.Flush)
		end
		return true
	end
	return false
end

function Scheduler.Flush()
	flushScheduled = false
	stats.flushes = stats.flushes + 1

	local layout = pending.layout
	pending.layout = nil
	RunBucket("layout", layout)
	if layout then
		paging = false
	end

	-- Display is icon/usable/badge paint. It must not become eval.
	local display = pending.display
	pending.display = nil
	RunBucket("display", display)

	-- Layout may dirty hosts as it runs; those land in pending.eval and are
	-- picked up here, so one form change is one layout plus one paint.
	local eval = pending.eval
	pending.eval = nil
	RunBucket("eval", eval)

	local structural = pending.structural
	if structural then
		if Flux.Combat and Flux.Combat.InLockdown() then
			stats.deferredStructural = stats.deferredStructural + 1
			Flux.Combat.Defer("scheduler.structural.flush", Scheduler.Flush)
		else
			pending.structural = nil
			RunBucket("structural", structural)
		end
	end

	local inventory = pending.inventory
	pending.inventory = nil
	if inventory then
		RunInventory(inventory)
	end
end

function Scheduler.Stats()
	return stats
end
