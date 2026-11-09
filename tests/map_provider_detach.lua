-- Actual Flux provider owner; native lifecycle contracts are explicit fixtures.
-- Models retained callbacks/handlers, not native secure metadata, pixels or CPU.
local path = (arg and arg[1]) or "Battlezonemap/FluxBattlefieldMapProviders.lua"
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
local function fixture(secret)
	local env = setmetatable({}, { __index = _G }); env._G = env
	local s = { now = 1, timers = {}, fetches = 0, refreshes = 0, hides = 0 }
	env.Flux = { Client = {} }
	env.wipe = function(t) for k in pairs(t) do t[k] = nil end end
	env.InCombatLockdown = function() return s.combat or false end
	env.GetTime = function() return s.now end
	if secret then env.issecretvalue = function() return false end end
	env.C_Timer = { After = function(delay, callback)
		s.timers[#s.timers + 1] = { at = s.now + delay, callback = callback }
	end }
	env.C_Map = { GetMapInfo = function() return { mapType = 0 } end }
	env.C_TaskQuest = { GetQuestsOnMap = function() return {} end,
		DoesMapShowTaskQuestObjectives = function() return false end }
	env.QuestMapFrame = {}
	env.C_VignetteInfo = {}
	env.GetCVarBool = function() return true end
	env.GetQuestsOnMapCached = function() s.fetches = s.fetches + 1; return {} end
	local registry = { callbacks = {} }
	function registry:RegisterCallback(event, callback, owner)
		self.callbacks[event] = self.callbacks[event] or {}
		self.callbacks[event][owner] = callback
	end
	function registry:UnregisterCallback(event, owner)
		if self.callbacks[event] then self.callbacks[event][owner] = nil end
	end
	function registry:Count()
		local n = 0; for _, owners in pairs(self.callbacks) do n = n + count(owners) end; return n
	end
	function registry:Fire(event)
		for owner, callback in pairs(self.callbacks[event] or {}) do callback(owner) end
	end
	env.EventRegistry = registry
	local map = { dataProviders = {}, callbacks = {}, click = {}, pin = {}, cursor = {} }
	function map:IsShown() return true end
	function map:GetMapID() return 1 end
	function map:AddDataProvider(provider)
		self.dataProviders[provider] = true
		provider:OnAdded(self)
		if s.failAdd then error("controlled partial add failure") end
	end
	function map:RemoveDataProvider(provider)
		provider:RemoveAllData()
		self.dataProviders[provider] = nil
		provider:OnRemoved(self)
	end
	function map:RegisterCallback(event, callback, owner)
		self.callbacks[event] = self.callbacks[event] or {}
		self.callbacks[event][owner] = callback
	end
	function map:UnregisterCallback(event, owner)
		if self.callbacks[event] then self.callbacks[event][owner] = nil end
	end
	function map:AddCanvasClickHandler(fn) self.click[fn] = true end
	function map:AddGlobalPinMouseActionHandler(fn) self.pin[fn] = true end
	function map:AddCursorHandler(fn) self.cursor[fn] = true end
	function map:RemoveCanvasClickHandler(fn) self.click[fn] = nil end
	function map:RemoveGlobalPinMouseActionHandler(fn) self.pin[fn] = nil end
	function map:RemoveCursorHandler(fn) self.cursor[fn] = nil end
	function map:AcquirePin() return {} end
	env.BattlefieldMapFrame = map
	env.CreateFromMixins = function(...)
		local object = {}
		for i = 1, select("#", ...) do for k, v in pairs(select(i, ...)) do object[k] = v end end
		return object
	end
	-- Pinned native Add/Remove call OnAdded/OnRemoved only; Flux owns Show/Hide.
	-- Native Quest.OnHide omits Supertracking.OnChanged; native Waypoint.OnRemoved
	-- removes cursorHandler but retains its canvas/global input handlers.
	local names = { "QuestOffer", "BonusObjective", "Quest", "WaypointLocation",
		"SuperTrackWaypoint", "AreaPOI", "Vignette", "Gossip", "DigSite", "DungeonEntrance" }
	for _, prefix in ipairs(names) do
		local name = prefix .. "DataProviderMixin"
		local mixin = {}
		function mixin:GetMap() return self.owningMap end
		function mixin:OnAdded(owningMap)
			self.owningMap = owningMap
			if prefix == "WaypointLocation" then
				self.onCanvasClickHandler = function() return self end
				self.onPinMouseActionHandler = function() return self end
				self.cursorHandler = function() return self end
				owningMap:AddCanvasClickHandler(self.onCanvasClickHandler, 90)
				owningMap:AddGlobalPinMouseActionHandler(self.onPinMouseActionHandler, 90)
				owningMap:AddCursorHandler(self.cursorHandler, 90)
				owningMap:RegisterCallback("WaypointLocationToggleUpdate", function() return self end, self)
			end
		end
		function mixin:OnShow()
			if prefix == "Quest" or prefix == "Vignette" or prefix == "DungeonEntrance" then
				registry:RegisterCallback("Supertracking.OnChanged", function() self:RefreshAllData() end, self)
			elseif prefix == "WaypointLocation" then
				registry:RegisterCallback("MapCanvas.PingWaypointLocation", function() return self end, self)
			end
		end
		function mixin:OnHide()
			s.hides = s.hides + 1
			if prefix == "Vignette" or prefix == "DungeonEntrance" then
				registry:UnregisterCallback("Supertracking.OnChanged", self)
			elseif prefix == "WaypointLocation" then
				registry:UnregisterCallback("MapCanvas.PingWaypointLocation", self)
			end
		end
		function mixin:OnRemoved(owningMap)
			if prefix == "WaypointLocation" then owningMap:RemoveCursorHandler(self.cursorHandler) end
			if not s.keepMap then self.owningMap = nil end
		end
		function mixin:RemoveAllData() self.removes = (self.removes or 0) + 1 end
		function mixin:RefreshAllData() s.refreshes = s.refreshes + 1 end
		function mixin:OnMapChanged() self:RefreshAllData() end
		env[name] = mixin
	end
	local worldOwner = {}
	registry:RegisterCallback("Supertracking.OnChanged", function() end, worldOwner)
	s.worldOwner, s.registry, s.map = worldOwner, registry, map
	assert(loadfile(path, "t", env))("_FluxUI", { Flux = env.Flux })
	s.owner = env.FluxBattlefieldMapProviders
	function s:drain()
		local due, remaining = {}, {}
		for _, timer in ipairs(self.timers) do
			if timer.at <= self.now then due[#due + 1] = timer else remaining[#remaining + 1] = timer end
		end
		self.timers = remaining
		for _, timer in ipairs(due) do timer.callback() end
	end
	function s:quest()
		for provider in pairs(self.map.dataProviders) do
			if provider._fluxMixinName == "QuestDataProviderMixin" then return provider end
		end
	end
	return s
end

if arg and arg[2] == "--measure" then
	for _, cycles in ipairs({ 1, 10, 100, 1000 }) do
		local s = fixture(true)
		for _ = 1, cycles do s.owner:Attach(s.map); s.owner:Detach(s.map); s:drain() end
		local retained = s.registry:Count() - 1
		s.registry:Fire("Supertracking.OnChanged")
		print(cycles, s.registry:Count() - 1, count(s.map.click), count(s.map.pin),
			count(s.map.cursor), count(s.map.dataProviders), #s.timers, retained,
			count(s.map.callbacks.WaypointLocationToggleUpdate or {}))
	end
	local s = fixture(true)
	for _ = 1, 10 do s.owner:Attach(s.map); s.owner:Detach(s.map); s:drain() end
	local started = os.clock()
	for _ = 1, 1000 do s.owner:Attach(s.map); s.owner:Detach(s.map); s:drain() end
	print("HOST_CLOCK_MS", (os.clock() - started) * 1000)
else
	for _, secret in ipairs({ false, true }) do
		local s = fixture(secret)
		check(s.owner:Attach(s.map), "available quest and feature providers attach")
		check(count(s.map.dataProviders) == 10 and s.registry:Count() == 5,
			"all available owned providers and active callback features remain present")
		check(count(s.map.click) == 1 and count(s.map.pin) == 1 and count(s.map.cursor) == 1,
			"waypoint input handlers remain active")
		local quest = s:quest()
		check(s.owner:Detach(s.map) and not s.owner:IsAttached(), "detach completes")
		check(s.registry:Count() == 1 and s.registry.callbacks["Supertracking.OnChanged"][s.worldOwner],
			"discarded clone callbacks are released and native world owner remains")
		check(count(s.map.click) == 0 and count(s.map.pin) == 0 and count(s.map.cursor) == 0,
			"discarded waypoint input handlers are released")
		check(count(s.map.callbacks.WaypointLocationToggleUpdate) == 0,
			"discarded waypoint toggle callback is released")
		check(not quest._fluxBattlefieldProvider and count(s.map.dataProviders) == 0,
			"discarded providers lose ownership")
		for _ = 1, 100 do s.owner:Attach(s.map); s.owner:Detach(s.map); s:drain() end
		check(s.registry:Count() == 1 and count(s.map.click) == 0 and count(s.map.pin) == 0,
			"one hundred tab cycles retain no owned callbacks or input handlers")
		s.registry:Fire("Supertracking.OnChanged")
		check(#s.timers == 0, "supertracking cannot schedule discarded provider work")
		check(s.hides == 1010, "every owned provider receives its existing hide cleanup")
	end
	local s = fixture(true)
	s.keepMap = true
	s.owner:Attach(s.map)
	local old = s:quest()
	old:RefreshAllData()
	check(#s.timers >= 1, "secret quest refresh queues at its existing deadline")
	s.owner:Detach(s.map)
	check(old:GetMap() == s.map, "stale native-map reference fixture is meaningful")
	local before = s.fetches
	s.now = s.now + 1; s:drain()
	check(s.fetches == before, "queued discarded quest refresh cannot run with a stale map reference")
	old:RefreshAllData()
	check(#s.timers == 0 and s.fetches == before, "discarded callback cannot restart refresh work")
	s.owner:Attach(s.map)
	local current = s:quest()
	check(current ~= old and current._fluxBattlefieldProvider, "reattach owns a fresh provider")
	current:RefreshAllData()
	before = s.fetches
	s.now = s.now + 1; s:drain()
	check(s.fetches == before + 1, "current provider's queued refresh still runs")
	s.owner:Detach(s.map)
	local stopped = fixture(true)
	stopped.owner:Attach(stopped.map); stopped:drain()
	local stoppedQuest = stopped:quest()
	stopped.owner:Detach(stopped.map)
	stoppedQuest:RefreshAllData()
	check(#stopped.timers == 0, "discarded throttled callback cannot queue a new timer")
	local failed = fixture(true); failed.failAdd = true
	check(not failed.owner:Attach(failed.map) and count(failed.map.dataProviders) == 0,
		"partial add failure leaves no registered provider")
	check(count(failed.map.click) == 0 and count(failed.map.pin) == 0 and count(failed.map.cursor) == 0,
		"partial add failure also releases waypoint handlers")
	print("Map provider detach: " .. checks .. " checks passed")
end
