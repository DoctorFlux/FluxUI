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
local dispatch = CreateFrame("Frame")
dispatch:Hide()
local eventTrace
local profilestop = debugprofilestop

dispatch:SetScript("OnEvent", function(_, event, ...)
	local list = handlers[event]
	if not list then
		return
	end
	local t0
	if eventTrace then
		t0 = profilestop and profilestop() or 0
	end
	for i = 1, #list do
		local fn = list[i]
		if fn then
			local ok, err = pcall(fn, event, ...)
			if not ok then
				local geh = geterrorhandler
				if geh then
					geh()(tostring(err))
				end
			end
		end
	end
	if eventTrace then
		eventTrace(event, (profilestop and profilestop() or 0) - t0)
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
				table.remove(list, i)
			end
		end
	else
		wipe(list)
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
		fn(ev, ...)
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
