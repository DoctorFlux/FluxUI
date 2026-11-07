-- Actual Paint/Glow integration; desktop Lua does not model native taint or art.
-- Grid startup owners are real; inventory selection and grid geometry are fixtures.
local checks = 0
local function check(value, message)
	checks = checks + 1
	assert(value, message)
end
local noop = function() end
local paintPath = (arg and arg[1]) or "ExtraButtonSystem/Engine/Paint.lua"
local glowPath = (arg and arg[2]) or "Core/ButtonFX/Glow.lua"

local function fixture(profile)
	local env = setmetatable({}, { __index = _G })
	env._G, env.FluxButton = env, {}
	env.combat, env.proc, env.aura = false, false, false
	env.frames, env.handlers, env.modules, env.login = {}, {}, {}, {}
	env.writes = { births = 0, slots = 0, alpha = 0, animations = 0, forbidden = 0 }
	env.InCombatLockdown = function() return env.combat end
	local secret = {}
	env.issecretvalue = function(value) return value == secret end
	env.secret = secret
	env.C_Texture = { GetAtlasInfo = function()
		return profile.secure and {} or nil
	end }
	if not profile.classic then
		env.C_SpellActivationOverlay = { IsSpellOverlayed = function(id)
			return env.proc and id == 5143
		end }
	end
	if profile.forever then
		env.C_UnitAuras = { GetPlayerAuraBySpellID = function(id)
			assert(id == 400589, "unexpected aura fallback query")
			return env.aura and { spellId = 400589 } or nil
		end }
	end
	if profile.community then
		env.SpellActivationOverlayLABBinder = {}
		env.SpellActivationOverlayDB = { glow = { enabled = true } }
	end
	if profile.secure then
		env.C_Secrets = { GetSpellAuraSecrecy = function() return 1 end }
		env.C_AddOns = { IsAddOnLoaded = function(name)
			return name == "Blizzard_AuraContainer" or
				(profile.community and name == "SpellActivationOverlay")
		end }
	end
	local function animation()
		return {
			Play = function(self) self.playing = true end,
			Stop = function(self) self.playing = false end,
			IsPlaying = function(self) return self.playing or false end,
			SetScript = function(self, key, fn) self[key] = fn end,
			GetScript = function(self, key) return self[key] end,
		}
	end
	local function outsideCombat(message)
		if env.combat then
			env.writes.forbidden = env.writes.forbidden + 1
			error(message or "protected operation in combat")
		end
	end
	local function frame(kind, name, parent, template)
		if template or kind == "AuraContainer" then
			outsideCombat("native descendant created in combat")
		end
		local f = { parent = parent, shown = true, alpha = 1, scripts = {}, events = {} }
		function f:SetAllPoints() outsideCombat("anchor written in combat") end
		function f:SetPoint() outsideCombat("anchor written in combat") end
		function f:ClearAllPoints() outsideCombat("anchor cleared in combat") end
		function f:SetParent(value) outsideCombat(); self.parent = value end
		function f:GetParent() return self.parent end
		function f:SetSize(w, h) outsideCombat(); self.w, self.h = w, h end
		function f:GetSize() return self.w or 36, self.h or 36 end
		function f:GetWidth() return self.w or 36 end
		function f:GetHeight() return self.h or 36 end
		function f:SetAlpha(value) self.alpha = value; env.writes.alpha = env.writes.alpha + 1 end
		function f:IsShown() return self.shown end
		function f:Show() self.shown = true end
		function f:Hide() self.shown = false end
		function f:SetShown(value) outsideCombat(); self.shown = value end
		function f:SetUnit(value) outsideCombat("aura unit written in combat"); self.unit = value end
		function f:SetEnabled(value) outsideCombat(); self.enabled = value end
		function f:RegisterEvent(event) self.events[event] = true end
		function f:SetScript(key, fn) self.scripts[key] = fn end
		function f:GetScript(key) return self.scripts[key] end
		function f:GetEffectiveScale() return 1 end
		f.EnableMouse, f.SetEditModePreviewEnabled = noop, noop
		if kind == "AuraContainer" then
			env.writes.slots = env.writes.slots + 1
			function f:AddAuraSlot(key, filter, options)
				assert(key == "missileBarrage" and filter == "HELPFUL")
				assert(options.candidateFilters.includeSpellIDs[400589])
				local auraButton = frame("Button", nil, self)
				function auraButton:AddAuraShownAnimation(value)
					self.animation = value
					env.writes.animations = env.writes.animations + 1
				end
				-- Eager initialization matches the production setup's current contract.
				-- Real secure aura assignment/animation behavior needs a client check.
				options.initializeFrame(auraButton)
				self.auraButton = auraButton
			end
		elseif template == "ActionButtonSpellAlertTemplate" then
			f.ProcLoop, f.ProcStartAnim = animation(), animation()
			f.ProcLoopAnim = f.ProcLoop
		elseif template == "AutoCastShineTemplate" then
			f.shown = false
		end
		env.frames[#env.frames + 1] = f
		env.writes.births = env.writes.births + 1
		if name then env[name] = f end
		return f
	end
	env.CreateFrame, env.UIParent = frame, frame("Frame")
	env.hooksecurefunc = function(tbl, key, hook)
		local original = assert(tbl[key])
		tbl[key] = function(...) original(...); hook(...) end
	end
	local lbg = {
		ShowOverlayGlow = function(widget)
			widget.__LBGoverlay = widget.__LBGoverlay or frame("Frame", nil, widget)
			widget.__LBGoverlay.shown = true
		end,
		HideOverlayGlow = function(widget)
			if widget.__LBGoverlay then widget.__LBGoverlay.shown = false end
		end,
	}
	env.LibStub = function(name)
		if name == "LibButtonGlow-1.0" then return lbg end
	end
	local Flux = {
		Client = { isForever = profile.forever or false,
			isPreDF = profile.classic or false, isAnyClassic = profile.classic or false },
		EBS = {}, ButtonFX = {}, securePhaseReady = true,
		Spell = {
			GetName = function(id) return id == 5143 and "Arcane Missiles" or "Frostbolt" end,
			GetTexture = function(id) return id and id + 10000 end,
		},
		Item = { GetSpell = function(id)
			if id == 123 then return "Arcane Missiles", 5143 end
		end },
		Events = { Register = function(event, fn) env.handlers[event] = fn end },
		Module = { Register = function(name, spec) env.modules[name] = spec end },
		AfterLogin = function(fn) env.login[#env.login + 1] = fn end,
	}
	env.Flux = Flux
	env.load = function(path) return assert(loadfile(path, "t", env))("_FluxUI", { Flux = Flux }) end
	env.load(glowPath)
	env.load(paintPath)
	env.glow, env.paint = Flux.ButtonFX.Glow, Flux.EBS.Paint
	env.glow.Start()
	env.setProc = function(value)
		env.proc = value
		local event = value and "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE"
		assert(env.handlers[event])(nil, 5143)
	end
	env.button = function(kind)
		local btn = { ActionType = kind, Texture = 15143, MacroMode = "" }
		if kind == "spell" then btn.SpellId, btn.ActionValue = 5143, 5143 end
		if kind == "item" then btn.ItemId, btn.ActionValue = 123, 123 end
		if kind == "macrotext" then
			btn.MacroMode, btn.SpellId, btn.MacroBody = "spell", 5143, "/cast Arcane Missiles"
		end
		btn.Widget = frame("Button")
		btn.Widget.FluxButton = btn
		return btn
	end
	return env
end

local profiles = {
	{ name = "Retail" },
	{ name = "Forever without community SAO", forever = true },
	{ name = "Forever with SAO, no secure capability", forever = true, community = true },
	{ name = "Forever with secure aura slot", forever = true, community = true, secure = true },
	{ name = "Classic Era capability set", classic = true },
	{ name = "Classic progression capability set", classic = true },
	{ name = "original Wrath capability set", classic = true },
}

for _, profile in ipairs(profiles) do
	local env = fixture(profile)
	local buttons = {}
	for _, kind in ipairs({ "", "spell", "item", "macrotext" }) do
		local btn = env.button(kind)
		buttons[#buttons + 1] = btn
		env.paint.UpdateGlow(btn)
		check(not btn._glowing, profile.name .. ": inactive " .. kind .. " startup")
	end
	check(env.writes.slots == (profile.secure and 3 or 0), profile.name .. ": slots only on eligible spell/item/macro")
	env.setProc(true)
	for _, combat in ipairs({ false, true }) do
		env.combat = combat
		for index, btn in ipairs(buttons) do
			env.paint.UpdateGlow(btn)
			check(btn._glowing == (index > 1), profile.name .. ": native proc preserved")
			if index > 1 then check(env.glow.IsLive(btn.Widget), profile.name .. ": requested glow rendered")
			end
		end
	end
	env.setProc(false)
	for _, btn in ipairs(buttons) do
		env.paint.UpdateGlow(btn)
		check(not btn._glowing and not env.glow.IsLive(btn.Widget), profile.name .. ": proc clears")
	end
	local births = env.writes.births
	for _ = 1, 20 do
		for _, btn in ipairs(buttons) do env.paint.UpdateGlow(btn) end
	end
	check(env.writes.births == births, profile.name .. ": settled combat refresh creates no frames")
	check(env.writes.forbidden == 0, profile.name .. ": no protected attempts concealed by pcall")
	env.combat = false
	-- Each real startup owner invokes real Paint/Glow via the inventory-module
	-- fixture. This catches failures previously hidden by a mocked Paint.Flush.
	local created = 0
	local function create()
		for _, kind in ipairs({ "", "spell", "item", "macrotext" }) do
			env.paint.UpdateGlow(env.button(kind))
		end
		created = created + 1
	end
	for _, name in ipairs({ "FluxCombatBandage", "FluxCombatHealPotion", "FluxCombatManaPotion",
		"FluxCombatManaGem", "FluxCombatHealthstone", "FluxCombatAmmo", "FluxNCHearthstone",
		"FluxNCMount", "FluxNCTeleportPortal", "FluxNCWater", "FluxNCFood", "FluxNCConsumables",
		"FluxNCUtilitySlotsManager" }) do
		env[name] = { Create = create, Register = create, OnNonCombatGridReady = create }
	end
	local function grid()
		return { Frame = env.CreateFrame("Frame"), BeginLayout = noop, EndLayout = noop,
			Relayout = noop, Show = noop }
	end
	env.FluxCombatGrid, env.FluxNonCombatGrid = { New = grid }, { New = grid }
	env.load("ExtraButtonSystem/CombatGrid/GridManager.lua")
	env.load("ExtraButtonSystem/NonCombatGrid/GridInit.lua")
	env.combat = true
	check(env.modules.CombatGrid.OnEnable() == false and env.modules.NonCombatGrid.OnEnable() == false,
		profile.name .. ": startup waits for combat end")
	check(created == 0, profile.name .. ": combat startup creates no buttons")
	env.combat = false
	check(env.modules.CombatGrid.OnEnable() and env.modules.NonCombatGrid.OnEnable(),
		profile.name .. ": both grid owners finish real Paint/Glow startup")
	check(created == 13, profile.name .. ": all combat/noncombat modules registered")
	check(env.FluxCombatManager._startupReady and env.FluxNonCombatAPI._startupReady,
		profile.name .. ": readiness published only after registrations")
	env.modules.CombatGrid.OnEnable(); env.modules.NonCombatGrid.OnEnable()
	check(created == 13, profile.name .. ": repeated enable does not register twice")
	if profile.forever then
		env.aura = true
		env.paint.UpdateGlow(buttons[2])
		check(buttons[2]._glowing == (profile.community == true and not profile.secure),
			profile.name .. ": readable fallback remains only without prepared secure slot")
		env.aura = false
		env.paint.UpdateGlow(buttons[2])
		check(not buttons[2]._glowing, profile.name .. ": readable fallback clears")
	end
	-- Paint accepts older implementations with no bridge. A prepared secure
	-- container still belongs to its own Glow module, so retain that module's
	-- internal Sync dependency while exercising optional Paint hooks.
	local ensureSecureAura = env.glow.EnsureSecureAura
	env.glow.EnsureSecureAura = nil
	env.glow.IsSecureAuraSpell, env.glow.MayShowSecureAuraText = nil, nil
	if not profile.secure then env.glow.SyncSecureAura = nil end
	env.setProc(true)
	for _, btn in ipairs(buttons) do env.paint.UpdateGlow(btn) end
	check(buttons[2]._glowing and env.glow.IsLive(buttons[2].Widget),
		profile.name .. ": optional bridge absence preserves glow")
	env.setProc(false)
	for _, btn in ipairs(buttons) do env.paint.UpdateGlow(btn) end
	-- Isolated early-load capability absence must also short-circuit safely.
	env.InCombatLockdown = nil
	env.glow.EnsureSecureAura = ensureSecureAura
	env.paint.UpdateGlow(env.button(""))
	check(true, profile.name .. ": absent combat API does not call nil")
end

print("EBS Paint/Glow startup: " .. checks .. " checks passed")
