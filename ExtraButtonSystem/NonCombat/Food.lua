-- ExtraButtonSystem/NonCombat/Food.lua
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS
local NC = EBS.NonCombat or {}
EBS.NonCombat = NC

local Food = NC.Food or {}
NC.Food = Food

local slot, btn

local function PreferRecuperate()
	local db = _G._FluxUI_CharSavedVars
	return db and db.food and db.food.preferRecuperate and true or false
end

local function RecuperateSpell()
	local C = Flux.Inventory and Flux.Inventory.CreateSpells
	if C and C.IsKnownByName then
		local known, id = C.IsKnownByName("Recuperate")
		if known then
			return id
		end
	end
	return nil
end

local function BestFood()
	local Bind = EBS.ConsumableBind
	return Bind and Bind.GetBestOwned and Bind.GetBestOwned("food")
end

function Food.Refresh()
	if not slot then
		return
	end
	local rec = BestFood()
	local conjName, conjID = nil, nil
	local Bind = EBS.ConsumableBind
	if Bind and Bind.GetFoodConjureSpell then
		conjName, conjID = Bind.GetFoodConjureSpell()
	end
	local recup = PreferRecuperate() and RecuperateSpell()
	slot.smart = (rec and rec.itemID) or conjID or recup
	if recup then
		EBS.ExtraSlot.SetAction(btn, {
			type = "spell",
			id = recup,
			spell = recup,
			type2 = conjID and "spell" or "macro",
			spell2 = conjID,
			macrotext2 = (not conjID) and "/stopmacro" or nil,
			type3 = "macro",
			macrotext3 = "/stopmacro",
		})
	elseif rec and rec.itemID then
		local spec = Bind.UseItemSpec(rec.itemID, {
			spell2 = conjID and Bind.SpellAttr(conjID, conjName) or nil,
		})
		if not conjID then
			spec.type2 = "macro"
			spec.macrotext2 = "/stopmacro"
		end
		EBS.ExtraSlot.SetAction(btn, spec)
	elseif conjID then
		EBS.ExtraSlot.SetAction(btn, {
			type = "spell",
			id = conjID,
			spell = conjID,
			type3 = "macro",
			macrotext3 = "/stopmacro",
		})
	else
		EBS.ExtraSlot.Clear(btn)
	end
end

function Food.Register(host)
	local Bind = EBS.ConsumableBind
	local created
	created, btn = EBS.ExtraSlot.Create(host, {
		name = "FluxNCFood",
		roleId = "nc_food",
		kind = "food",
		columnGroup = "foodwater",
		columnPriority = 4,
		order = 2,
		placeholder = "Interface/Icons/INV_Misc_Food_15",
		label = "Food",
		binding = "FLUXGRID_FOOD_OR_RECUP",
		smartFn = function()
			return slot and slot.smart
		end,
	})
	slot = created
	if btn and Bind and Bind.WireMiddleDelete then
		Bind.WireMiddleDelete(btn, function()
			local rec = BestFood()
			if rec and rec.isConjured then
				return rec.itemID
			end
			return nil
		end)
	end
	if btn and btn.Widget then
		btn.Widget:HookScript("PostClick", function(_, mouse, down)
			if down or mouse ~= "RightButton" then
				return
			end
			local Bind2 = EBS.ConsumableBind
			local _, conjID = Bind2 and Bind2.GetFoodConjureSpell and Bind2.GetFoodConjureSpell()
			if not conjID and Bind2 and Bind2.OpenQty then
				Bind2.OpenQty("food", btn.Widget)
			end
		end)
	end
end
