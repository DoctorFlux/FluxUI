-- Actual countdown implementation with explicit native/owned display sinks.
-- Desktop counts do not establish native CPU, frame time, taint or pixel parity.
local function read(path)
	local file = assert(io.open(path, "rb"))
	local source = file:read("*a"):gsub("\r\n", "\n")
	file:close()
	return source
end
local source = read((arg and arg[1]) or "Bars/Stance/Extras.lua")
local function section(body, first, last)
	local a = assert(body:find(first, 1, true))
	local b = assert(body:find(last, a + #first, true))
	return body:sub(a, b - 1)
end
local checks = 0
local function check(value, message)
	checks = checks + 1
	assert(value, message)
end
local function fixture(body)
	local env = setmetatable({}, { __index = _G })
	env._G = env
	local s = { now = 0, frames = {}, shows = 0, hides = 0, native = 0,
		regions = 0, clocks = 0, fonts = 0, text = 0 }
	local secret = {}
	env.Flux = { Bars = { Stance = {} }, Secrets = {
		IsSecretValue = function(value) return value == secret end,
		CanAccessValue = function(value) return value ~= secret end,
	} }
	env.GetTime = function() s.clocks = s.clocks + 1; return s.now end
	env.InCombatLockdown = function() return s.combat end
	env.CreateFrame = function()
		local frame = { scripts = {} }
		function frame:Hide() self.shown = false end
		function frame:Show() self.shown = true end
		function frame:GetScript(key) return self.scripts[key] end
		function frame:SetScript(key, value) self.scripts[key] = value end
		s.frames[#s.frames + 1] = frame
		return frame
	end
	local public = section(body, "local function PublicNumber(value)", "local function PublicString(value)")
	local helpers = section(body, "local function ExtraAuraTimerOwned(btn)", "local function FormArmorIsActive(btn)")
	local chunk = "local Flux=Flux\nlocal Stance=Flux.Bars.Stance\n" .. public .. helpers ..
		"\nreturn Stance.SyncAuraCountdown,AuraCountdownTick,auraCountdownActive"
	s.sync, s.tick, s.active = assert(load(chunk, "@production-stance-sync", "t", env))()
	function s:button(options)
		options = options or {}
		local fs = { _fluxFontReady = not options.unready, writes = 0, attempts = 0,
			fontAttempts = 0 }
		function fs:SetFont()
			self.fontAttempts = self.fontAttempts + 1
			s.fonts = s.fonts + 1
			if self.fontAttempts <= (options.fontFailures or 0) then error("font not ready") end
		end
		function fs:SetText(value)
			self.attempts = self.attempts + 1
			if self.attempts <= (options.textFailures or 0) then error("write not ready") end
			self.displayed = value
			self.writes = self.writes + 1
			s.text = s.text + 1
		end
		local native = { SetTextColor = function() end, SetAlpha = function() end,
			GetObjectType = function() return "FontString" end }
		local cd = { SetHideCountdownNumbers = function(_, hidden)
			assert(hidden == true); s.native = s.native + 1
		end }
		if options.legacy then
			cd.GetRegions = function()
				s.regions = s.regions + 1
				return { GetObjectType = function() return "Texture" end }, native
			end
		else
			cd.GetCountdownFontString = function() return native end
		end
		local holder = { shows = 0, hides = 0,
			SetFrameLevel = function() assert(not s.combat, "protected anchor change") end }
		function holder:Show() self.shown = true; self.shows = self.shows + 1; s.shows = s.shows + 1 end
		function holder:Hide() self.shown = false; self.hides = self.hides + 1; s.hides = s.hides + 1 end
		local widget = { shown = true, IsShown = function(self) return self.shown end,
			GetWidth = function() return 30 end, GetFrameLevel = function() return 1 end }
		return { Widget = widget, WCooldown = cd, FluxStanceManagedCooldown = true,
			StanceBuffExpirationTime = 600, StanceBuffTimeMod = 1,
			_fluxStanceAuraText = fs, _fluxStanceAuraHolder = holder }, fs, holder
	end
	s.secret = secret
	return s
end

local function exercise(body)
	local s = fixture(body)
	local one, text, holder = s:button()
	s.sync(one)
	check(text.displayed == "10m" and holder.shown and s.active[one],
		"own first display is immediate without waiting for a frame")
	check(#s.frames == 1 and type(s.frames[1].scripts.OnUpdate) == "function",
		"one existing driver is armed")
	local two, second = s:button()
	two.StanceBuffTimeMod = 2
	local before = holder.shows
	s.sync(two)
	check(second.displayed == "5m" and holder.shows == before,
		"sync paints its own time-modified display without sweeping other buttons")
	s.now = 1
	s.frames[1].scripts.OnUpdate()
	check(holder.shows == before + 1 and text.displayed == "10m" and second.displayed == "5m",
		"normal driver still reconciles all active countdowns every frame")
	local oldShows, oldNative, oldClocks = s.shows, s.native, s.clocks
	for _ = 1, 20 do s.frames[1].scripts.OnUpdate() end
	check(s.shows - oldShows == 40 and s.native - oldNative == 40 and s.clocks - oldClocks == 20,
		"steady clock, native digits and holder cadence remain per frame")

	-- Another button's silently changed state is still reconciled by the
	-- existing driver; individual Sync calls no longer perform incidental sweeps.
	one.Widget.shown = false
	s.sync(two)
	check(s.active[one] and holder.shown, "unrelated change waits for its normal frame")
	s.frames[1].scripts.OnUpdate()
	check(not s.active[one] and not holder.shown and text.displayed == "",
		"normal driver clears another hidden button on that frame")
	two.FluxStanceManagedCooldown = nil
	s.sync(two)
	check(not s.active[two] and second.displayed == "",
		"own ownership loss clears immediately")
	s.frames[1].scripts.OnUpdate()
	check(not s.frames[1].scripts.OnUpdate and not s.frames[1].shown,
		"last removal still shuts down the driver")

	local expiry = fixture(body)
	local exp, expText, expHolder = expiry:button()
	exp.StanceBuffExpirationTime = 0.05
	expiry.sync(exp)
	check(not expiry.active[exp] and expText.displayed == "" and not expHolder.shown,
		"exact expiry cutoff is removed on its own immediate sync")
	check(not expiry.frames[1].scripts.OnUpdate and not expiry.frames[1].shown,
		"invalid first timer leaves no running empty driver")
	exp.StanceBuffExpirationTime = 90
	expiry.sync(exp)
	check(expText.displayed == "2m" and #expiry.frames == 1, "reactivation reuses the driver")
	expiry.now = 0.001
	expiry.frames[1].scripts.OnUpdate()
	check(expText.displayed == "89", "format boundary changes on the same normal frame")
	exp.StanceBuffExpirationTime = expiry.secret
	expiry.sync(exp)
	check(not expiry.active[exp] and expText.displayed == "", "unreadable own duration clears safely")
	expiry.tick()
	check(not expiry.frames[1].scripts.OnUpdate, "unreadable duration leaves no active work")

	local retry = fixture(body)
	local delayed, delayedText = retry:button({ unready = true, fontFailures = 4 })
	retry.sync(delayed)
	check(delayedText.displayed == nil and retry.active[delayed], "font failure preserves retry eligibility")
	retry.tick(); retry.tick()
	check(delayedText.displayed == "10m", "font readiness retries on unchanged frame cadence")
	local failed, failedText = retry:button({ textFailures = 1, legacy = true })
	retry.sync(failed)
	check(failedText.displayed == nil and failedText.attempts == 1, "failed immediate text is not cached")
	retry.combat = true
	retry.tick()
	check(failedText.displayed == "10m" and retry.regions == 3,
		"next combat frame retries text and retains legacy native-digit reconciliation")
	local missing = retry:button()
	missing._fluxStanceAuraText.SetText = nil
	retry.sync(missing)
	check(retry.active[missing], "temporary absent text setter does not lose timer ownership")

	local burst = fixture(body)
	local buttons = {}
	for i = 1, 16 do buttons[i] = burst:button(); burst.sync(buttons[i]) end
	oldShows, oldNative, oldClocks = burst.shows, burst.native, burst.clocks
	for _, btn in ipairs(buttons) do burst.sync(btn) end
	check(burst.shows - oldShows == 16 and burst.native - oldNative == 32,
		"sixteen matched refreshes paint sixteen buttons instead of 256")
	check(burst.clocks - oldClocks == 16 and #burst.frames == 1,
		"burst keeps one clock read per sync and one existing frame")
end

if arg and arg[2] == "--measure" then
	for _, n in ipairs({ 1, 4, 16, 64, 256 }) do
		local s, buttons = fixture(source), {}
		for i = 1, n do buttons[i] = s:button(); s.sync(buttons[i]) end
		local startup = { s.shows, s.native }
		s.shows, s.native, s.text, s.fonts, s.clocks = 0, 0, 0, 0, 0
		for _, btn in ipairs(buttons) do s.sync(btn) end
		print(n, startup[1], startup[2], s.shows, s.native, s.fonts, s.text, #s.frames)
	end
	local s, buttons = fixture(source), {}
	for i = 1, 16 do buttons[i] = s:button(); s.sync(buttons[i]) end
	for _ = 1, 10 do for _, btn in ipairs(buttons) do s.sync(btn) end end
	local started = os.clock()
	for _ = 1, 2000 do for _, btn in ipairs(buttons) do s.sync(btn) end end
	print("HOST_CLOCK_MS", (os.clock() - started) * 1000)
else
	exercise(source)
	local a, b = source:find("UpdateAuraCountdown(btn, (GetTime and GetTime()) or 0)", 1, true)
	assert(a, "candidate sync anchor missing")
	local mutant = source:sub(1, a - 1) .. "AuraCountdownTick()" .. source:sub(b + 1)
	check(not pcall(exercise, mutant), "regression rejects a restored global sync sweep")
	print("Stance aura sync: " .. checks .. " checks passed; duplicate-sweep mutation rejected")
end
