-- Modifier.lua — demand-driven MODIFIER_STATE_CHANGED coalescing.
-- OnUpdate runs only while a subscriber is active or a modifier event is pending.
-- Binding, Extra Buttons, and bars share this bus instead of private OnUpdates.
local addonName, ns = ...
local Flux = ns.Flux

local Modifier = {}
Flux.Modifier = Modifier
Flux.Engine = Flux.Engine or {}
Flux.Engine.Modifier = Modifier
_G.FluxModifierTracker = Modifier

local subscribers = {}
local frame = CreateFrame("Frame")
local modDirty = false
local elapsedAcc = 0
local onUpdateArmed = false
local traceFn
local profilestop = debugprofilestop

local function RunCallbacks()
	local t0
	if traceFn then
		t0 = profilestop and profilestop() or 0
	end
	for _, sub in pairs(subscribers) do
		if sub.callback then
			Flux.Safecall(sub.callback)
		end
	end
	if traceFn then
		traceFn("callbacks", (profilestop and profilestop() or 0) - t0)
	end
end

local function MinFallbackInterval()
	local interval
	for _, sub in pairs(subscribers) do
		local fi = sub.fallbackInterval
		if fi and fi > 0 and (not sub.isActive or sub.isActive()) then
			if not interval or fi < interval then
				interval = fi
			end
		end
	end
	return interval
end

local function AnyNeedsFallback()
	return MinFallbackInterval() ~= nil
end

local function UpdateOnUpdateState()
	if modDirty or AnyNeedsFallback() then
		if not onUpdateArmed then
			onUpdateArmed = true
			frame:SetScript("OnUpdate", frame._onUpdate)
		end
	else
		onUpdateArmed = false
		elapsedAcc = 0
		frame:SetScript("OnUpdate", nil)
	end
end

--- key: unique subscriber id. opts: { fallbackInterval, isActive }.
function Modifier.Register(key, callback, opts)
	if type(key) ~= "string" or type(callback) ~= "function" then
		return
	end
	opts = opts or {}
	subscribers[key] = {
		callback = callback,
		fallbackInterval = opts.fallbackInterval,
		isActive = opts.isActive,
	}
	UpdateOnUpdateState()
end

function Modifier.Unregister(key)
	subscribers[key] = nil
	UpdateOnUpdateState()
end

--- Call when a subscriber's active state may have changed (shown/hidden, items).
function Modifier.NotifyActiveChanged()
	UpdateOnUpdateState()
end

function Modifier.IsArmed()
	return onUpdateArmed
end

frame:RegisterEvent("MODIFIER_STATE_CHANGED")
frame:SetScript("OnEvent", function()
	local t0
	if traceFn then
		t0 = profilestop and profilestop() or 0
	end
	modDirty = true
	UpdateOnUpdateState()
	if traceFn then
		traceFn("event", (profilestop and profilestop() or 0) - t0)
	end
end)

--- fn(kind, ms) with kind "event" or "callbacks". Nil to disarm.
function Modifier.SetTrace(fn)
	traceFn = (type(fn) == "function") and fn or nil
end

frame._onUpdate = function(_, elapsed)
	if modDirty then
		modDirty = false
		elapsedAcc = 0
		RunCallbacks()
		UpdateOnUpdateState()
		return
	end

	local interval = MinFallbackInterval()
	if not interval then
		UpdateOnUpdateState()
		return
	end

	elapsedAcc = elapsedAcc + (elapsed or 0)
	if elapsedAcc >= interval then
		elapsedAcc = 0
		RunCallbacks()
	end

	UpdateOnUpdateState()
end
