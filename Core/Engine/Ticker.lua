-- Ticker.lua — self-disarming OnUpdate. Idle UI runs zero per-frame code.
-- Frame is created at file scope so CPU bills this addon.
local addonName, ns = ...
local Flux = ns.Flux

local Ticker = {}
Flux.Ticker = Ticker
Flux.Engine = Flux.Engine or {}
Flux.Engine.Ticker = Ticker

local frame = CreateFrame("Frame")
frame:Hide()

local keys = {}
local fns = {}
local index = {}
local count = 0
local ticks = 0
local traceFn
local profilestop = debugprofilestop
local timingObserver, timingToken

local function Clock()
	local value = profilestop and profilestop()
	if type(value) == "number" and not (issecretvalue and issecretvalue(value))
		and value == value and value ~= math.huge and value ~= -math.huge then return value end
end

function Ticker.ObserveTiming(fn)
	if type(fn) ~= "function" then return nil, "timing observer must be a function" end
	if timingObserver then return nil, "timing observer already registered" end
	local token = {}
	timingObserver, timingToken = fn, token
	return function()
		if timingToken == token then timingObserver, timingToken = nil, nil end
	end
end

local function NotifyTiming(observer, token, key, fn, ms, failed)
	local ok, err = pcall(observer, key, fn, ms, failed)
	if not ok then
		if timingObserver == observer and timingToken == token then timingObserver, timingToken = nil, nil end
		local geh = geterrorhandler
		if geh then geh()(tostring(err)) end
	end
end

frame:SetScript("OnUpdate", function(_, elapsed)
	local trace, t0 = traceFn
	if trace then
		t0 = profilestop and profilestop() or 0
	end
	ticks = ticks + 1
	local i = 1
	while i <= count do
		local key = keys[i]
		local fn = fns[i]
		local observer, token, began = timingObserver
		if observer then token, began = timingToken, Clock() end
		local ok, err = pcall(fn, elapsed)
		if not ok then
			local geh = geterrorhandler
			if geh then
				geh()(tostring(err))
			end
		end
		if began and observer == timingObserver and token == timingToken then
			local ended = Clock()
			if ended and ended >= began then NotifyTiming(observer, token, key, fn, ended - began, not ok) end
		end
		-- Subscriber may Remove itself (swap-remove). Re-test this slot.
		if keys[i] == key then
			i = i + 1
		end
	end
	if trace and trace == traceFn then
		trace((profilestop and profilestop() or 0) - t0, count)
	end
end)

--- fn(ms, subscriberCount) after each armed OnUpdate. Nil to disarm.
function Ticker.SetTrace(fn)
	traceFn = (type(fn) == "function") and fn or nil
end

local function Arm()
	if count > 0 then
		frame:Show()
	end
end

local function DisarmIfIdle()
	if count <= 0 then
		count = 0
		frame:Hide()
	end
end

--- Add is idempotent: same key replaces the function.
function Ticker.Add(key, fn)
	if type(key) ~= "string" and type(key) ~= "number" then
		return
	end
	if type(fn) ~= "function" then
		return
	end
	local pos = index[key]
	if pos then
		fns[pos] = fn
		return
	end
	count = count + 1
	keys[count] = key
	fns[count] = fn
	index[key] = count
	Arm()
end

function Ticker.Remove(key)
	local pos = index[key]
	if not pos then
		return
	end
	local last = count
	keys[pos] = keys[last]
	fns[pos] = fns[last]
	if keys[pos] then
		index[keys[pos]] = pos
	end
	keys[last] = nil
	fns[last] = nil
	index[key] = nil
	count = count - 1
	DisarmIfIdle()
end

function Ticker.IsArmed()
	return count > 0 and frame:IsShown()
end

function Ticker.Count()
	return count
end

function Ticker.Ticks()
	return ticks
end

-- On-demand diagnostics only; copy so callers cannot mutate the live registry.
function Ticker.GetSubscribers()
	local out = {}
	for i = 1, count do
		out[keys[i]] = fns[i]
	end
	return out
end
