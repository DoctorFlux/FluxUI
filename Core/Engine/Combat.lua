-- Combat.lua — lockdown queue. Flush on PLAYER_REGEN_ENABLED.
-- Named Defer keys replace. RegenDefer is a list (mount/teleport/ammo) drained
-- next frame so icon scans do not pile onto the same-tick Relayout/Flush.
local addonName, ns = ...
local Flux = ns.Flux

local Combat = {}
Flux.Combat = Combat
Flux.Engine = Flux.Engine or {}
Flux.Engine.Combat = Combat

local pending = {}
local pendingOrder = {}

local lightQ = {}
local heavyQ = {}
local drainArmed = false

function Combat.InLockdown()
	return InCombatLockdown and InCombatLockdown() and true or false
end

local function After0(fn)
	if Flux.Timer and Flux.Timer.After then
		Flux.Timer.After(0, fn)
	elseif C_Timer and C_Timer.After then
		C_Timer.After(0, fn)
	else
		fn()
	end
end

local function DrainRegenQueues()
	drainArmed = false
	if Combat.InLockdown() then
		return
	end
	local light = lightQ
	local heavy = heavyQ
	lightQ = {}
	heavyQ = {}
	local function run()
		for i = 1, #light do
			Flux.Safecall(light[i])
		end
		for i = 1, #heavy do
			Flux.Safecall(heavy[i])
		end
	end
	local Regen = Flux.Perf and Flux.Perf.Regen
	if Regen and Regen.Time then
		Regen.Time("regen.deferDrain", run)
	else
		run()
	end
end

function Combat.ScheduleRegenQueues()
	if drainArmed then
		return
	end
	if #lightQ == 0 and #heavyQ == 0 then
		return
	end
	drainArmed = true
	After0(DrainRegenQueues)
end

--- Queue work off the regen tick. Same-key Defer cannot hold multiple fns.
-- heavy=true increments FluxNCRegenDeferHeavy (mount icon scans).
function Combat.RegenDefer(fn, heavy)
	if type(fn) ~= "function" then
		return
	end
	if heavy then
		_G.FluxNCRegenDeferHeavy = (_G.FluxNCRegenDeferHeavy or 0) + 1
		heavyQ[#heavyQ + 1] = fn
	else
		_G.FluxNCRegenDeferLight = (_G.FluxNCRegenDeferLight or 0) + 1
		lightQ[#lightQ + 1] = fn
	end
	if not Combat.InLockdown() then
		Combat.ScheduleRegenQueues()
	end
end

_G.FluxCombatRegenDeferQueue = function(fn)
	Combat.RegenDefer(fn, false)
end

_G.FluxRegenDeferHeavyQueue = function(fn)
	Combat.RegenDefer(fn, true)
end

--- Defer a named job until regen. Same key replaces the previous fn.
function Combat.Defer(key, fn)
	if type(fn) ~= "function" then
		return
	end
	key = key or tostring(fn)
	if not pending[key] then
		pendingOrder[#pendingOrder + 1] = key
	end
	pending[key] = fn
	if not Combat.InLockdown() then
		Combat.Flush()
	end
end

function Combat.Flush()
	if Combat.InLockdown() then
		return false
	end
	local Regen = Flux.Perf and Flux.Perf.Regen
	local order = pendingOrder
	local map = pending
	pending = {}
	pendingOrder = {}
	local keysRan = {}
	for i = 1, #order do
		local key = order[i]
		local fn = map[key]
		if fn then
			keysRan[#keysRan + 1] = key
			if Regen and Regen.Time then
				Regen.Time("flush." .. key, function()
					Flux.Safecall(fn)
				end)
			else
				Flux.Safecall(fn)
			end
		end
	end
	if Regen and Regen.NoteFlushKeys then
		Regen.NoteFlushKeys(keysRan)
	end
	return true
end

function Combat.HasPending()
	return #pendingOrder > 0
end

function Combat.PendingCount()
	return #pendingOrder
end

-- File-scope frame.
local regen = CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")
regen:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_ENABLED" then
		local Regen = Flux.Perf and Flux.Perf.Regen
		if Regen and Regen.OnRegen then
			Regen.OnRegen()
		end
		Combat.Flush()
		Combat.ScheduleRegenQueues()
	end
end)
