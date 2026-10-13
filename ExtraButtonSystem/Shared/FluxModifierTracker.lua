--[[
	ExtraButtonSystem/Shared/FluxModifierTracker.lua
	Shared MODIFIER_STATE_CHANGED coalescing with demand-driven fallback polling.
	Subscribers register a callback; OnUpdate runs only while at least one subscriber
	is active (isActive) or a modifier event is pending.
]]

FluxModifierTracker = FluxModifierTracker or {}
local M = FluxModifierTracker

local subscribers = {}
local frame = CreateFrame("Frame")
local modDirty = false
local elapsedAcc = 0
local onUpdateArmed = false

local function runCallbacks()
	for _, sub in pairs(subscribers) do
		if sub.callback then
			pcall(sub.callback)
		end
	end
end

local function minFallbackInterval()
	local interval = nil
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

local function anyNeedsFallback()
	return minFallbackInterval() ~= nil
end

local function updateOnUpdateState()
	if modDirty or anyNeedsFallback() then
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

--- @param key string Unique subscriber id (e.g. "NCHearthstone")
--- @param callback function Invoked on modifier change or fallback tick
--- @param opts table|nil { fallbackInterval = number|nil, isActive = function|nil }
function M.Register(key, callback, opts)
	if type(key) ~= "string" or type(callback) ~= "function" then return end
	opts = opts or {}
	subscribers[key] = {
		callback = callback,
		fallbackInterval = opts.fallbackInterval,
		isActive = opts.isActive,
	}
	updateOnUpdateState()
end

function M.Unregister(key)
	subscribers[key] = nil
	updateOnUpdateState()
end

--- Call when a subscriber's active state may have changed (button shown/hidden, items gained/lost).
function M.NotifyActiveChanged()
	updateOnUpdateState()
end

frame:RegisterEvent("MODIFIER_STATE_CHANGED")
frame:SetScript("OnEvent", function()
	modDirty = true
	updateOnUpdateState()
end)

frame._onUpdate = function(_, elapsed)
	if modDirty then
		modDirty = false
		elapsedAcc = 0
		runCallbacks()
		updateOnUpdateState()
		return
	end

	local interval = minFallbackInterval()
	if not interval then
		updateOnUpdateState()
		return
	end

	elapsedAcc = elapsedAcc + (elapsed or 0)
	if elapsedAcc >= interval then
		elapsedAcc = 0
		runCallbacks()
	end

	updateOnUpdateState()
end

return M
