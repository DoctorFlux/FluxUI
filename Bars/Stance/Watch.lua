-- Bars/Stance/Watch.lua — form visual vs extras visual vs rediscover. Player auras never rebuild layout.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Stance = Bars.Stance

local Watch = {}
Stance.Watch = Watch

local started = false
local lastPetExists

function Watch.Start()
	if started then
		return
	end
	local Ev = Flux.Events
	if not Ev or not Ev.Register then
		return
	end
	started = true

	local function Discover()
		if Stance.RequestDiscover then
			Stance.RequestDiscover()
		elseif Stance.RequestLayout then
			Stance.RequestLayout("discover")
		end
	end

	local function Layout()
		if Stance.RequestLayout then
			Stance.RequestLayout("watch")
		end
	end

	Ev.Register("PLAYER_ENTERING_WORLD", Discover)
	Ev.Register("UPDATE_SHAPESHIFT_FORMS", Discover)
	if Ev.RegisterLearnedSpell then
		Ev.RegisterLearnedSpell(Discover)
	else
		Ev.Register("SPELLS_CHANGED", Discover)
	end
	Ev.Register("PLAYER_SPECIALIZATION_CHANGED", Discover)
	Ev.Register("PLAYER_TALENT_UPDATE", Discover)
	Ev.Register("TRAIT_CONFIG_UPDATED", Discover)

	local function FormsVisual()
		if Stance.RequestFormsVisual then
			Stance.RequestFormsVisual()
		end
	end
	local FormStorm = Flux.FormStorm
	if FormStorm and FormStorm.OnBurst then
		FormStorm.OnBurst("stance.forms", FormsVisual)
	else
		Ev.Register("UPDATE_SHAPESHIFT_FORM", FormsVisual)
	end
	Ev.Register("UPDATE_SHAPESHIFT_USABLE", FormsVisual)
	Ev.Register("UPDATE_SHAPESHIFT_COOLDOWN", FormsVisual)

	Ev.Register("UNIT_PET", function(_, unit)
		if unit ~= "player" then
			return
		end
		local exists = UnitExists and UnitExists("pet") or false
		if lastPetExists == nil or lastPetExists ~= exists then
			lastPetExists = exists
			Layout()
		elseif Stance.RequestExtrasVisual then
			Stance.RequestExtrasVisual()
		end
	end)

	local function ArmorVisual()
		if Stance.RequestExtrasVisual then
			Stance.RequestExtrasVisual()
		end
		if Stance.RequestFormsVisual then
			Stance.RequestFormsVisual()
		end
	end

	if Ev.RegisterUnit then
		Ev.RegisterUnit("UNIT_AURA", "player", ArmorVisual)
	else
		Ev.Register("UNIT_AURA", function(_, unit)
			if unit == "player" then
				ArmorVisual()
			end
		end)
	end

	-- Combat on Forever/Midnight nils GetPlayerAuraBySpellID. Cast success is a
	-- public presence signal; regen only re-paints (no layout rebuild).
	local function OnPlayerCast(spellId)
		local refresh = false
		if Stance.IsMageArmorSpell and Stance.IsMageArmorSpell(spellId) then
			if Stance.NoteMageArmorCast then
				Stance.NoteMageArmorCast(spellId)
			end
			refresh = true
		end
		if Stance.NoteCustomCast and Stance.NoteCustomCast(spellId) then
			refresh = true
		elseif Stance.IsTrackedCustomSpell and Stance.IsTrackedCustomSpell(spellId) then
			refresh = true
		end
		if refresh then
			ArmorVisual()
		end
	end
	if Ev.RegisterUnit then
		Ev.RegisterUnit("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, _, spellId)
			OnPlayerCast(spellId)
		end)
	else
		Ev.Register("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellId)
			if unit and unit ~= "player" then
				return
			end
			OnPlayerCast(spellId)
		end)
	end

	Ev.Register("ACTIONBAR_UPDATE_STATE", function()
		if Stance.HasCustomSlots and not Stance.HasCustomSlots() then
			return
		end
		if Stance.RequestExtrasVisual then
			Stance.RequestExtrasVisual()
		end
	end)

	Ev.Register("PLAYER_REGEN_DISABLED", ArmorVisual)
	Ev.Register("PLAYER_REGEN_ENABLED", ArmorVisual)

	Ev.Register("UPDATE_BINDINGS", function()
		if Stance.ReassignBindings then
			Stance.ReassignBindings()
		end
	end)
end
