-- Shapeshift.lua — form count / info / cooldown pass-through. No secret compares.
local addonName, ns = ...
local Flux = ns.Flux

local Shapeshift = {}
Flux.Shapeshift = Shapeshift
Flux.API = Flux.API or {}
Flux.API.Shapeshift = Shapeshift

local function UnpackInfo(a, b, c, d)
	if type(a) == "table" then
		local t = a
		return t.icon or t.texture, t.isActive, t.isCastable, t.spellID or t.spellId
	end
	return a, b, c, d
end

local function UnpackCooldown(a, b, c)
	if type(a) == "table" then
		return a.startTime or a.start, a.duration, a.isEnabled or a.enable
	end
	return a, b, c
end

function Shapeshift.GetNumForms()
	if GetNumShapeshiftForms then
		local ok, n = pcall(GetNumShapeshiftForms)
		if ok then
			n = tonumber(n) or 0
			if n < 0 then
				return 0
			end
			return n
		end
	end
	return 0
end

function Shapeshift.GetForm()
	if GetShapeshiftForm then
		local ok, n = pcall(GetShapeshiftForm)
		if ok then
			return tonumber(n) or n
		end
	end
	return 0
end

function Shapeshift.GetFormInfo(index)
	if not index or not GetShapeshiftFormInfo then
		return nil
	end
	local ok, a, b, c, d = pcall(GetShapeshiftFormInfo, index)
	if not ok then
		return nil
	end
	return UnpackInfo(a, b, c, d)
end

function Shapeshift.GetFormCooldown(index)
	if not index or not GetShapeshiftFormCooldown then
		return 0, 0, 0
	end
	local ok, a, b, c = pcall(GetShapeshiftFormCooldown, index)
	if not ok then
		return 0, 0, 0
	end
	return UnpackCooldown(a, b, c)
end

-- True when spellId is the stance/form currently on (Bear while in bear).
-- Compare ids via GetBaseSpell / GetOverrideSpell, not names or an id list.
function Shapeshift.MatchesActiveForm(spellId)
	if not spellId then
		return false
	end
	local Spell = Flux.Spell
	local n = Shapeshift.GetNumForms()
	for i = 1, n do
		local _, isActive, _, formSpell = Shapeshift.GetFormInfo(i)
		if isActive and formSpell then
			if Spell and Spell.IdsMatch then
				if Spell.IdsMatch(spellId, formSpell) then
					return true
				end
			elseif spellId == formSpell then
				return true
			end
		end
	end
	return false
end

function Shapeshift.ActiveSpellId()
	local n = Shapeshift.GetNumForms()
	for i = 1, n do
		local _, isActive, _, formSpell = Shapeshift.GetFormInfo(i)
		if isActive and formSpell then
			return formSpell
		end
	end
	return nil
end
