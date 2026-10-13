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

frame:SetScript("OnUpdate", function(_, elapsed)
	local t0
	if traceFn then
		t0 = profilestop and profilestop() or 0
	end
	ticks = ticks + 1
	local i = 1
	while i <= count do
		local key = keys[i]
		local fn = fns[i]
		local ok, err = pcall(fn, elapsed)
		if not ok then
			local geh = geterrorhandler
			if geh then
				geh()(tostring(err))
			end
		end
		-- Subscriber may Remove itself (swap-remove). Re-test this slot.
		if keys[i] == key then
			i = i + 1
		end
	end
	if traceFn then
		traceFn((profilestop and profilestop() or 0) - t0, count)
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
