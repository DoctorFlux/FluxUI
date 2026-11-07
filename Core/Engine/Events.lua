-- Events.lua — validated RegisterEvent / RegisterUnitEvent + central dispatch
local addonName, ns = ...
local Flux = ns.Flux
local Client = Flux.Client

local Events = {}
Flux.Events = Events
Flux.Engine = Flux.Engine or {}
Flux.Engine.Events = Events

local pcall = pcall
local type = type

local validated = {}
local probeFrame = CreateFrame("Frame")

local OPTIONAL_EVENT_HINTS = {
	-- Retail 11.0+ removed this (LEARNED_SPELL_IN_SKILL_LINE). Do not
	-- probe-register: unknown events still hit BugSack inside pcall.
	LEARNED_SPELL_IN_TAB = function()
		if Client.isRetail or Client.isMidnight or (Client.majorVersion or 0) >= 11 then
			return false
		end
		return nil
	end,
	LEARNED_SPELL_IN_SKILL_LINE = function()
		if Client.isEra then
			return false
		end
		return nil
	end,
}

local function Probe(eventName)
	if C_EventUtils and C_EventUtils.IsEventValid then
		local ok, valid = pcall(C_EventUtils.IsEventValid, eventName)
		if ok then
			-- nil/false must not fall through to RegisterEvent (BugSack).
			return valid == true
		end
	end
	local ok = pcall(probeFrame.RegisterEvent, probeFrame, eventName)
	if ok then
		pcall(probeFrame.UnregisterEvent, probeFrame, eventName)
	end
	return ok
end

local function Resolve(eventName)
	if validated[eventName] ~= nil then
		return validated[eventName]
	end
	local hintFn = OPTIONAL_EVENT_HINTS[eventName]
	if hintFn then
		local hinted = hintFn()
		if hinted ~= nil then
			validated[eventName] = hinted
			return hinted
		end
	end
	validated[eventName] = Probe(eventName)
	return validated[eventName]
end

function Events.IsValid(eventName)
	if type(eventName) ~= "string" then
		return false
	end
	return Resolve(eventName)
end

-- Central dispatcher. Frame created at file scope.
local handlers = {} -- event -> { fn, ... }
local dispatchDepth, dirtyHandlers = {}, {}
local dispatch = CreateFrame("Frame")
dispatch:Hide()
local eventTrace
local profilestop = debugprofilestop
local timingObserver, timingToken

local function Clock()
	local value = profilestop and profilestop()
	if type(value) == "number" and not (issecretvalue and issecretvalue(value))
		and value == value and value ~= math.huge and value ~= -math.huge then return value end
end

-- Observe owned callbacks only. Tokens prevent an old cleanup from detaching a
-- later owner, including a later registration of the same observer function.
function Events.ObserveTiming(fn)
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

local function CompactHandlers(event, list)
	if not dirtyHandlers[event] then return end
	dirtyHandlers[event] = nil
	local nextIndex = 1
	for i = 1, #list do
		if list[i] then list[nextIndex] = list[i]; nextIndex = nextIndex + 1 end
	end
	for i = #list, nextIndex, -1 do list[i] = nil end
	if nextIndex == 1 and handlers[event] == list then
		handlers[event] = nil
		pcall(dispatch.UnregisterEvent, dispatch, event)
	end
end

dispatch:SetScript("OnEvent", function(_, event, ...)
	local list = handlers[event]
	if not list then
		return
	end
	dispatchDepth[event] = (dispatchDepth[event] or 0) + 1
	local trace, t0 = eventTrace
	if trace then
		t0 = profilestop and profilestop() or 0
	end
	for i = 1, #list do
		local fn = list[i]
		if fn then
			local observer, token, began = timingObserver
			if observer then token, began = timingToken, Clock() end
			local ok, err = pcall(fn, event, ...)
			if not ok then
				local geh = geterrorhandler
				if geh then
					geh()(tostring(err))
				end
			end
			if began and observer == timingObserver and token == timingToken then
				local ended = Clock()
				if ended and ended >= began then NotifyTiming(observer, token, event, fn, ended - began, not ok) end
			end
		end
	end
	dispatchDepth[event] = dispatchDepth[event] - 1
	if dispatchDepth[event] == 0 then
		dispatchDepth[event] = nil
		CompactHandlers(event, list)
	end
	if trace and trace == eventTrace then
		trace(event, (profilestop and profilestop() or 0) - t0)
	end
end)

--- fn(event, ms) while hop/mod debug is on. Nil to disarm. One extra nil check per event.
function Events.SetTrace(fn)
	eventTrace = (type(fn) == "function") and fn or nil
end

function Events.Register(eventName, fn)
	if type(eventName) ~= "string" or type(fn) ~= "function" then
		return false
	end
	if not Resolve(eventName) then
		return false
	end
	local list = handlers[eventName]
	if not list then
		list = {}
		handlers[eventName] = list
		local ok = pcall(dispatch.RegisterEvent, dispatch, eventName)
		if not ok then
			validated[eventName] = false
			handlers[eventName] = nil
			return false
		end
	end
	list[#list + 1] = fn
	return true
end

function Events.Unregister(eventName, fn)
	local list = handlers[eventName]
	if not list then
		return
	end
	if fn then
		for i = #list, 1, -1 do
			if list[i] == fn then
				if dispatchDepth[eventName] then
					list[i] = false
					dirtyHandlers[eventName] = true
				else table.remove(list, i) end
			end
		end
	else
		if dispatchDepth[eventName] then
			for i = 1, #list do list[i] = false end
			dirtyHandlers[eventName] = true
		else wipe(list) end
	end
	if #list == 0 then
		handlers[eventName] = nil
		pcall(dispatch.UnregisterEvent, dispatch, eventName)
	end
end

function Events.RegisterUnit(eventName, unit, fn)
	if type(eventName) ~= "string" or type(fn) ~= "function" then
		return false
	end
	if not Resolve(eventName) then
		return false
	end
	-- Unit events use a dedicated frame so RegisterUnitEvent is not mixed with the bus.
	local f = CreateFrame("Frame")
	local ok = pcall(f.RegisterUnitEvent, f, eventName, unit)
	if not ok then
		validated[eventName] = false
		return false
	end
	f:SetScript("OnEvent", function(_, ev, ...)
		local observer, token, began = timingObserver
		if observer then token, began = timingToken, Clock() end
		-- Unit handlers retain their original direct error propagation. A failed
		-- handler unwinds before observation; this is not a complete error census.
		fn(ev, ...)
		if began and observer == timingObserver and token == timingToken then
			local ended = Clock()
			if ended and ended >= began then NotifyTiming(observer, token, ev, fn, ended - began, false) end
		end
	end)
	return f
end

--- Safe register on an arbitrary frame (modules that own their frame).
function Events.SafeRegister(frame, eventName)
	if not frame or not eventName then
		return false
	end
	if not Resolve(eventName) then
		return false
	end
	local ok = pcall(frame.RegisterEvent, frame, eventName)
	if not ok then
		validated[eventName] = false
	end
	return ok
end

function Events.SafeRegisterUnit(frame, eventName, ...)
	if not frame or not eventName or not frame.RegisterUnitEvent then
		return false
	end
	if not Resolve(eventName) then
		return false
	end
	local ok = pcall(frame.RegisterUnitEvent, frame, eventName, ...)
	if not ok then
		validated[eventName] = false
	end
	return ok
end

function Events.RegisterLearnedSpell(fn)
	Events.Register("SPELLS_CHANGED", fn)
	Events.Register("LEARNED_SPELL_IN_TAB", fn)
	Events.Register("LEARNED_SPELL_IN_SKILL_LINE", fn)
end
