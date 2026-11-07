-- Actual provider owner and Combat service. Native lifecycle/API sinks are fixtures;
-- write/access counts do not establish native taint, rendering, CPU or frame time.
local function read(path)
	local file = assert(io.open(path, "rb")); local source = file:read("*a"):gsub("\r\n", "\n")
	file:close(); return source
end
local providerPath = (arg and arg[1]) or "Battlezonemap/FluxBattlefieldMapProviders.lua"
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
local function noop() end

-- Reuse the explicit native detach lifecycle from its focused regression. Load
-- only that fixture definition; neither its test body nor its measurements run.
local base = read("tests/map_provider_detach.lua")
local boundary = assert(base:find('if arg and arg[2] == "--measure" then', 1, true))
base = base:sub(1, boundary - 1)
local anchor = 'assert(loadfile(path, "t", env))("_FluxUI", { Flux = env.Flux })'
local a, b = assert(base:find(anchor, 1, true))
base = base:sub(1, a - 1) .. "setup(env, s)\n\t" .. base:sub(a)
a, b = assert(base:find("s.owner = env.FluxBattlefieldMapProviders", 1, true))
base = base:sub(1, a - 1) .. "s.env = env\n\t" .. base:sub(a)

local function fixture(modern, secret)
	local setup = function(env, s)
		s.globalWrites, s.acquires, s.nativeChecks, s.forbidden = 0, 0, 0, 0
		s.trace, s.pings, s.async, s.frames, s.errors = {}, {}, {}, {}, {}
		local function nativeCheck()
			s.nativeChecks = s.nativeChecks + 1
			if s.combat and not s.nativeSecure then s.forbidden = s.forbidden + 1; error("protected native pin acquisition") end
		end
		local function nativeMixin()
			local methods = modern and { CheckMouseButtonPassthrough = nativeCheck,
				UpdateMousePropagation = nativeCheck } or {}
			return setmetatable({}, {
				__index = methods, __pairs = function() return next, methods, nil end,
				__newindex = function(_, key, value) s.globalWrites = s.globalWrites + 1; methods[key] = value end,
			})
		end
		env.MapCanvasPinMixin, env.QuestPinMixin, env.BaseMapPoiPinMixin = nativeMixin(), nativeMixin(), nativeMixin()
		local originalAcquire = function(map, template, provider)
			s.acquires = s.acquires + 1; s.trace[#s.trace + 1] = template
			local pin = { GetMap = function() return map end }
			for key, value in pairs(env.MapCanvasPinMixin) do pin[key] = value end
			if pin.CheckMouseButtonPassthrough then pin:CheckMouseButtonPassthrough("RightButton") end
			return pin
		end
		s.originalAcquire = originalAcquire
		s.map.AcquirePin = originalAcquire
		env.Flux.Safecall = function(fn, ...)
			local ok, err = pcall(fn, ...)
			if not ok then s.errors[#s.errors + 1] = err end
			return ok
		end
		env.Flux.Timer = { After = env.C_Timer.After }
		env.Flux.Startup = { CheckLayout = noop, Count = noop }
		env.CreateFrame = function()
			local frame = { scripts = {}, events = {} }
			function frame:RegisterEvent(event) self.events[event] = true end
			function frame:UnregisterEvent(event) self.events[event] = nil end
			function frame:SetScript(key, callback) self.scripts[key] = callback end
			s.frames[#s.frames + 1] = frame
			return frame
		end
		assert(loadfile("Core/Engine/Combat.lua", "t", env))("_FluxUI", { Flux = env.Flux })
		-- Enable every listed feature mixin, including the Mainline-only flight layer.
		env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_ID = 1, 1
		env.FlightPointDataProviderMixin = env.CreateFromMixins(env.AreaPOIDataProviderMixin)
		local names = { "QuestOffer", "BonusObjective", "Quest", "WaypointLocation",
			"SuperTrackWaypoint", "AreaPOI", "Vignette", "FlightPoint", "Gossip", "DigSite", "DungeonEntrance" }
		for _, prefix in ipairs(names) do
			local mixin = env[prefix .. "DataProviderMixin"]
			function mixin:GetPinTemplate() return prefix .. "PinTemplate" end
			function mixin:RefreshAllData()
				s.refreshes = s.refreshes + 1
				if s.failNextRefresh then
					s.failNextRefresh = false
					error("controlled provider refresh failure")
				end
				if prefix == "BonusObjective" then
					-- Native Refresh cancels its prior quest-data callbacks first.
					s.async = { function()
						local template = self:GetPinTemplateFromTask({})
						if template then self:GetMap():AcquirePin(template, self) end
					end }
				else
					self:GetMap():AcquirePin(self:GetPinTemplate(), self)
				end
				if s.reenterNextRefresh then
					s.reenterNextRefresh = false
					s.combat = true
				end
			end
			function mixin:PingPin(idKey, id, frameLevelType, numLoops)
				self:GetMap():AcquirePin("MapPinPingTemplate", self)
				s.pings[#s.pings + 1] = { idKey, id, frameLevelType, numLoops }
				return true
			end
			if prefix == "BonusObjective" then
				function mixin:GetPinTemplateFromTask() return "BonusObjectivePinTemplate" end
			elseif prefix == "SuperTrackWaypoint" then
				local added = mixin.OnAdded
				function mixin:OnAdded(map)
					added(self, map)
					self.dirtyMethod = self.RefreshAllData
				end
			end
		end
		env.GetQuestsOnMapCached = function()
			s.fetches = s.fetches + 1
			return { { questID = 42, x = 0.5, y = 0.5 } }
		end
	end
	local context = setmetatable({ arg = { [1] = providerPath } }, { __index = _G })
	local make = assert(load("local setup=...\n" .. base .. "\nreturn fixture", "@map-provider-lifecycle-fixture", "t", context))(setup)
	local s = make(secret)
	function s:provider(name)
		for provider in pairs(self.map.dataProviders) do
			if provider._fluxMixinName == name .. "DataProviderMixin" then return provider end
		end
	end
	function s:regen()
		self.combat = false
		for _, frame in ipairs(self.frames) do
			if frame.events.PLAYER_REGEN_ENABLED then frame.scripts.OnEvent(frame, "PLAYER_REGEN_ENABLED") end
		end
	end
	return s
end

local function exercise()
	for _, secret in ipairs({ false, true }) do
		local s = fixture(true, secret)
		check(s.owner:Attach(s.map), "modern providers attach")
		check(count(s.map.dataProviders) == 11, "all eleven available provider features remain")
		check(s.map.AcquirePin == s.originalAcquire and s.globalWrites == 0,
			"native acquire and global pin mixins remain untouched")
		local q, super = s:provider("Quest"), s:provider("SuperTrackWaypoint")
		local before = s.acquires
		s.now = s.now + 1
		q:RefreshAllData()
		check(s.acquires == before + 1, "normal out-of-combat quest refresh remains immediate")
		s.combat = true
		before = s.acquires
		for _ = 1, 100 do
			for provider in pairs(s.map.dataProviders) do provider:RefreshAllData() end
			s.registry:Fire("Supertracking.OnChanged")
		end
		super.dirtyMethod(super)
		check(s.acquires == before and s.forbidden == 0, "combat callbacks never attempt native acquisition")
		check(s.env.Flux.Combat.PendingCount() == 1, "all blocked owners share one existing combat job")
		local bonus = s:provider("BonusObjective")
		local callback = assert(s.async[1])
		callback()
		check(s.acquires == before and s.forbidden == 0, "previously queued bonus callback rechecks combat")
		check(q:PingPin("questID", 41, "QUEST", 1) == false
			and q:PingPin("questID", 42, "QUEST", 3) == false,
			"blocked ping preserves a bounded latest request")
		s.now = s.now + 1
		s:regen()
		check(s.env.Flux.Combat.PendingCount() == 0 and s.forbidden == 0, "regen drains the shared job")
		check(s.acquires == before + 11 and #s.pings == 1 and s.pings[1][2] == 42 and s.pings[1][4] == 3,
			"each owner refreshes once, latest ping replays, and bonus remains asynchronous")
		check(s.globalWrites == 0 and s.map.AcquirePin == s.originalAcquire, "no native rewrites during recovery")
		-- A later native World Map pin inherits the original method and still
		-- performs the normal mouse-passthrough check rather than a Flux no-op.
		local later = {}
		for key, value in pairs(s.env.QuestPinMixin) do later[key] = value end
		local checksBefore = s.nativeChecks
		later:CheckMouseButtonPassthrough("RightButton")
		check(s.nativeChecks == checksBefore + 1, "later native pin inheritance remains intact")
	end

	local throttled = fixture(true, true)
	throttled.owner:Attach(throttled.map)
	local quest = throttled:provider("Quest")
	quest:RefreshAllData() -- queues the existing quarter-second secret refresh
	throttled.combat = true
	local before = throttled.acquires
	throttled.now = throttled.now + 0.3; throttled:drain()
	check(throttled.acquires == before and throttled.forbidden == 0,
		"secret refresh timer rechecks combat at execution")
	throttled:regen()
	check(throttled.acquires == before + 1, "blocked secret timer refreshes after regen")
	throttled.combat = true
	quest:PingPin("questID", 42, "QUEST", 2)
	before = throttled.acquires
	throttled:regen() -- same time; secret refresh must retain its current deadline
	check(throttled.acquires == before and #throttled.pings == 0,
		"ping waits when its required refresh is still throttled")
	throttled.now = throttled.now + 0.3; throttled:drain()
	check(throttled.acquires == before + 2 and #throttled.pings == 1
		and throttled.trace[#throttled.trace - 1] == "QuestPinTemplate"
		and throttled.trace[#throttled.trace] == "MapPinPingTemplate",
		"actual secret refresh completes before the pending ping")

	local removed = fixture(true, true)
	removed.owner:Attach(removed.map)
	local old = removed:provider("Quest")
	local oldBonus = assert(removed.async[1])
	removed.combat = true
	old:RefreshAllData(); old:PingPin("questID", 42, "QUEST", 2)
	removed.combat = false
	removed.owner:Detach(removed.map)
	before = removed.acquires
	oldBonus(); removed:regen(); removed.now = removed.now + 1; removed:drain()
	check(removed.acquires == before and removed.forbidden == 0 and #removed.pings == 0,
		"detached owners discard bonus, refresh and ping work")
	removed.owner:Attach(removed.map)
	check(count(removed.map.dataProviders) == 11, "fresh attach keeps every feature after cancellation")

	local isolated = fixture(true, false)
	isolated.owner:Attach(isolated.map); isolated.combat = true
	for provider in pairs(isolated.map.dataProviders) do provider:RefreshAllData() end
	isolated.failNextRefresh = true
	before = isolated.refreshes
	isolated:regen()
	check(#isolated.errors == 1 and isolated.errors[1]:find("controlled provider refresh failure", 1, true),
		"deferred provider failure is reported by the existing safe-call contract")
	check(isolated.refreshes == before + 11 and not isolated.env.Flux.Combat.HasPending(),
		"one failed owner cannot discard the other ten deferred refreshes")

	local reentrant = fixture(true, false)
	reentrant.owner:Attach(reentrant.map); reentrant.combat = true
	for provider in pairs(reentrant.map.dataProviders) do provider:RefreshAllData() end
	reentrant.reenterNextRefresh = true
	before = reentrant.refreshes
	reentrant:regen()
	check(reentrant.combat and reentrant.refreshes == before + 1
		and reentrant.env.Flux.Combat.PendingCount() == 1 and reentrant.forbidden == 0,
		"lockdown during a flush retains the other owners in one combat job")
	reentrant:regen()
	check(reentrant.refreshes == before + 11 and not reentrant.env.Flux.Combat.HasPending()
		and reentrant.forbidden == 0, "the next regen completes all retained owners")

	local classic = fixture(false, false)
	classic.owner:Attach(classic.map); classic.combat = true
	before = classic.acquires
	for provider in pairs(classic.map.dataProviders) do provider:RefreshAllData() end
	check(classic.acquires == before + 10 and not classic.env.Flux.Combat.HasPending(),
		"older Classic native acquisition keeps its in-combat cadence")
	local ping = classic:provider("Quest"):PingPin("questID", 42, "QUEST", 2)
	check(ping == true and #classic.pings == 1, "older Classic ping still runs immediately")
end

if arg and arg[2] == "--measure" then
	local s = fixture(true, false)
	s.owner:Attach(s.map)
	for _ = 1, 10 do for provider in pairs(s.map.dataProviders) do provider:RefreshAllData() end end
	local started = os.clock()
	for _ = 1, 1000 do for provider in pairs(s.map.dataProviders) do provider:RefreshAllData() end end
	local elapsed = (os.clock() - started) * 1000
	print("COUNTS", s.acquires, s.globalWrites, s.nativeChecks, #s.frames, #s.timers)
	print("HOST_CLOCK_MS", elapsed)
else
	exercise()
	print("Map provider combat: " .. checks .. " checks passed")
end
