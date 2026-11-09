-- Actual ProgramFace entrypoints with explicit public/opaque API boundaries.
-- Opaque objects model forbidden inspection; this is not WoW's secret-value VM.
local path = (arg and arg[1]) or "Bars/ProgramFace.lua"
local checks = 0
local function check(value, message)
	checks = checks + 1
	assert(value, "ProgramFace name boundary: " .. message)
end
local function fixture(predicate)
	local f = { now = 1, timers = {}, frames = {}, peek = true, class = "help",
		name = "Public Friend", translations = 0, requests = 0, secretChecks = 0,
		secretTypeReads = 0, secretFormats = 0, paints = 0, names = {} }
	local env = setmetatable({}, { __index = _G }); env._G = env
	local opaque = {}
	function f.secret()
		local value = {}; opaque[value] = true; return value
	end
	local function isSecret(value)
		f.secretChecks = f.secretChecks + 1
		return opaque[value] == true
	end
	if predicate == "alias" then env.IsSecretValue = isSecret
	elseif predicate ~= "absent" then env.issecretvalue = isSecret end
	-- A secret surrogate must never reach either inspection/formatting sink.
	env.type = function(value)
		if opaque[value] then f.secretTypeReads = f.secretTypeReads + 1; return "string" end
		return type(value)
	end
	env.tostring = function(value)
		if opaque[value] then
			f.secretFormats = f.secretFormats + 1
			error("opaque name reached formatting")
		end
		f.names[value] = true
		return tostring(value)
	end
	env.canaccessvalue = function() return true end -- Access alone is insufficient.
	env.GetTime = function() return f.now end
	env.GetActionInfo = function() return "spell", 5176 end
	env.UnitName = function()
		if f.nameError then error("controlled UnitName failure") end
		return f.name
	end
	env.UnitChannelInfo = function()
		if f.channelError then error("controlled UnitChannelInfo failure") end
		return f.channel
	end
	env.FluxMouseoverKeybindModule = { IsHovercastPeekMouseContext = function() return f.peek end }
	local function after(delay, callback)
		f.timers[#f.timers + 1] = { at = f.now + delay, callback = callback }
	end
	function f.advance(delta)
		local untilTime, visits = f.now + delta, 0
		while true do
			local index, earliest
			for i, timer in ipairs(f.timers) do
				if timer.at <= untilTime and (not earliest or timer.at < earliest) then
					index, earliest = i, timer.at
				end
			end
			if not index then break end
			local timer = table.remove(f.timers, index); f.now = timer.at
			timer.callback(); visits = visits + 1; assert(visits < 100, "bounded fixture timers")
		end
		f.now = untilTime
	end
	env.CreateFrame = function()
		local frame = { scripts = {} }
		function frame:SetScript(kind, callback) self.scripts[kind] = callback end
		function frame:Show() self.shown = true end
		function frame:Hide() self.shown = false end
		f.frames[#f.frames + 1] = frame; return frame
	end
	local normal = "/cast [combat] Wrath; Healing Touch"
	local hover = "/cast [@mouseover,help] Healing Touch; Wrath"
	local host = { slot = 1, widget = {}, WIcon = {}, WCount = {} }
	local B = {
		ForEachHost = function(callback) callback(host) end,
		SlotProgram = {
			HasHover = function() return true end,
			GetHover = function() return hover end,
			GetAllHover = function() return { [1] = hover } end,
			Get = function() return normal end,
			GetAll = function() return { [1] = normal } end,
			ApplyStripDisplayOverrides = function(peek) f.override = peek end,
		},
		RequestPaint = function() f.paints = f.paints + 1 end,
	}
	local published = {}
	local flux = { Bars = B, Timer = { After = after },
		Scheduler = { Request = function() f.requests = f.requests + 1 end },
		Range = { MouseoverReactionClass = function() return f.class end,
			UnitReactionClass = function() return "harm" end },
		Identity = {
			SlotKey = function(slot) return slot end,
			Has = function() return true end,
			Publish = function(slot, kind, id) published[slot] = { kind, id } end,
		},
		EBS = { Action = { TranslateMacro = function(face)
			f.translations = f.translations + 1
			face.MacroMode, face.SpellId, face.MacroTexture = "spell", f.peek and 5185 or 5176, 136006
		end } },
	}
	assert(loadfile(path, "t", env))("_FluxUI", { Flux = flux })
	f.PF, f.env, f.host, f.published = B.ProgramFace, env, host, published
	function f.hover()
		f.PF.OnContext({ ufPeekChanged = true, ufPeek = f.peek })
		f.advance(0.08)
	end
	return f
end

for _, predicate in ipairs({ "native", "alias" }) do
	local f = fixture(predicate)
	f.name = f.secret(); f.hover()
	check(f.secretTypeReads == 0 and f.secretFormats == 0, predicate .. " opaque unit name is not inspected/formatted")
	check(f.secretChecks > 0 and f.translations == 1, "opaque name does not abort hover translation")
	check(f.host._fluxFace.MacroBody:find("@mouseover", 1, true) and f.host._fluxFace.SpellId == 5185,
		"hover macro body and shown spell are retained")
	check(f.published[1][1] == "spell" and f.published[1][2] == 5185
		and f.host._fluxFace.WIcon == f.host.WIcon, "icon target and published action identity remain")
	f.name = f.secret(); f.hover()
	check(f.translations == 1, "different opaque names do not enter the fingerprint cache")
	f.peek = false; f.hover()
	check(f.translations == 2 and f.host._fluxFace.SpellId == 5176 and f.override == false,
		"hover leave still restores normal body and identity")
	f.name = "Readable One"; f.hover()
	check(f.translations == 3 and f.names["Readable One"], "public name remains part of fingerprint")
	f.name = "Readable Two"; f.hover()
	check(f.translations == 4 and f.names["Readable Two"], "public same-class unit change still refreshes")
	f.hover(); check(f.translations == 4, "unchanged public fingerprint remains coalesced")
	f.channel = f.secret(); f.PF.Request("combat")
	check(f.secretTypeReads == 0 and f.requests == 1, "opaque channel name is excluded from signature")
	f.channel = nil; f.PF.Request("combat")
	check(f.requests == 1, "unavailable channel and opaque channel share the inactive signature")
	f.channel = "Mind Flay"; f.PF.Request("combat")
	check(f.requests == 2, "readable channel start still refreshes combat-conditioned faces")
	f.channel = "Another Channel"; f.PF.Request("combat")
	check(f.requests == 2, "channel spell rename retains the active channel bit")
	f.channelError = true; f.PF.Request("combat")
	check(f.requests == 3, "channel getter failure retains the previous inactive fallback")
end

local old = fixture("absent")
old.hover(); check(old.translations == 1, "clients without secret APIs retain public hover behavior")
old.nameError = true; old.hover()
check(old.translations == 2, "unit-name getter failure retains the empty fingerprint fallback")
old.nameError = false; old.name = ""; old.hover()
check(old.translations == 2, "empty name remains the same unavailable fingerprint")
old.name = 42; old.hover()
check(old.translations == 2, "non-string unit names remain unavailable")
old.channel = "Arcane Missiles"; old.PF.Request("combat")
check(old.requests == 1, "clients without secret APIs retain public channel behavior")
old.channel = ""; old.PF.Request("combat")
check(old.requests == 2, "empty channel is inactive")
old.channel = {}; old.PF.Request("combat")
check(old.requests == 2, "non-string channel remains inactive")
old.env.UnitName = false; old.name = "Ignored"; old.hover()
check(old.translations == 2, "missing UnitName retains the unavailable fallback")
old.env.UnitChannelInfo = false; old.PF.Request("combat")
check(old.requests == 2, "missing UnitChannelInfo retains the inactive signature")
print("ProgramFace secret names: " .. checks .. " checks passed")
