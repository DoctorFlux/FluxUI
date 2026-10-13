-- Timer.lua — After / ticker. Never assign into _G.C_Timer.
local addonName, ns = ...
local Flux = ns.Flux

local Timer = {}
Flux.Timer = Timer
Flux.Engine = Flux.Engine or {}
Flux.Engine.Timer = Timer

local type = type
local tonumber = tonumber
local tinsert = table.insert
local tremove = table.remove
local pcall = pcall
local geterrorhandler = geterrorhandler

local _After = C_Timer and C_Timer.After
local _NewTicker = C_Timer and C_Timer.NewTicker

-- Local polyfill only when C_Timer is missing. Self-disarming; never touches _G.C_Timer.
local waits = {}
local waitFrame = CreateFrame("Frame")
waitFrame:Hide()
waitFrame:SetScript("OnUpdate", function(self, elapsed)
	local i = 1
	while i <= #waits do
		local w = waits[i]
		w[1] = w[1] - elapsed
		if w[1] <= 0 then
			tremove(waits, i)
			local fn = w[2]
			if fn then
				local ok, err = pcall(fn)
				if not ok then
					local geh = geterrorhandler
					if geh then
						geh()(tostring(err))
					end
				end
			end
		else
			i = i + 1
		end
	end
	if #waits == 0 then
		self:Hide()
	end
end)

local function PolyAfter(duration, callback)
	if type(callback) ~= "function" then
		return
	end
	local d = tonumber(duration) or 0
	if d < 0 then
		d = 0
	end
	tinsert(waits, { d, callback })
	waitFrame:Show()
end

local function PolyNewTicker(duration, callback, iterations)
	if type(callback) ~= "function" then
		return { Cancel = function() end }
	end
	local d = tonumber(duration) or 0
	if d <= 0 then
		d = 0.01
	end
	local remaining = iterations
	local cancelled = false
	local handle = {}
	local function tick()
		if cancelled then
			return
		end
		callback()
		if remaining then
			remaining = remaining - 1
			if remaining <= 0 then
				cancelled = true
				return
			end
		end
		PolyAfter(d, tick)
	end
	function handle.Cancel()
		cancelled = true
	end
	PolyAfter(d, tick)
	return handle
end

if not _After then
	_After = PolyAfter
end
if not _NewTicker then
	_NewTicker = PolyNewTicker
end

function Timer.After(duration, callback)
	if type(callback) ~= "function" then
		return
	end
	return _After(duration, callback)
end

function Timer.NewTicker(duration, callback, iterations)
	if type(callback) ~= "function" then
		return { Cancel = function() end }
	end
	return _NewTicker(duration, callback, iterations)
end

function Timer.Defer(callback)
	return Timer.After(0, callback)
end

function Timer.HasPendingPolyfill()
	return #waits > 0 and waitFrame:IsShown()
end
