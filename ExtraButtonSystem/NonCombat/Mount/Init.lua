-- ExtraButtonSystem/NonCombat/Mount/Init.lua — journal or bag-item mount button.
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS
local NC = EBS.NonCombat or {}
EBS.NonCombat = NC

local Mount = NC.Mount or {}
NC.Mount = Mount

local slot, btn

local function Fav()
	return Flux.EBS and Flux.EBS.Flyout and Flux.EBS.Flyout.Favorites
end

local function Mode()
	local db = NC.CharDB and NC.CharDB() or {}
	db.mount = db.mount or {}
	if not db.mount.mode then
		db.mount.mode = "SmartMount"
	end
	return db.mount.mode
end

local function SetMode(mode)
	local db = NC.CharDB and NC.CharDB() or {}
	db.mount = db.mount or {}
	db.mount.mode = mode
end

local function UseJournal()
	return Mount.Journal and Mount.Journal.Available and Mount.Journal.Available()
end

local function BuildList()
	if UseJournal() and Mount.Journal and Mount.Journal.List then
		return Mount.Journal.List()
	end
	if Mount.Items and Mount.Items.List then
		return Mount.Items.List()
	end
	return {}
end

local function Pick(list)
	local F = Fav()
	local favId = F and F.GetFavorite and F.GetFavorite("Mount")
	if favId then
		for i = 1, #list do
			local row = list[i]
			if tostring(row.item or row.spell or row.mountId) == tostring(favId) then
				return row
			end
		end
	end
	return list[1]
end

local function HasRiding()
	if UnitLevel and UnitLevel("player") >= 10 and Flux.Client and Flux.Client.isRetail then
		return true
	end
	if IsPlayerSpell then
		-- Apprentice Riding / Journeyman
		if IsPlayerSpell(33388) or IsPlayerSpell(33391) or IsPlayerSpell(34090) or IsPlayerSpell(90265) then
			return true
		end
	end
	return UseJournal() or (#BuildList() > 0)
end

function Mount.Refresh()
	if not slot then
		return
	end
	local list = BuildList()
	slot.smart = HasRiding() and #list > 0
	if btn and Flux.EBS.Flyout then
		Flux.EBS.Flyout.SetButtons(btn.Widget, list, {
			direction = "UP",
			favoriteCategory = "Mount",
			skipFavorites = false,
		})
	end
	local pick = Pick(list)
	if pick then
		if pick.type == "item" then
			EBS.ExtraSlot.SetAction(btn, {
				type = "item",
				id = pick.item,
				type2 = "macro",
				macrotext2 = "/stopmacro",
				type3 = "macro",
				macrotext3 = "/stopmacro",
			})
		elseif pick.mountId and Mount.Journal then
			EBS.ExtraSlot.SetAction(btn, {
				type = "macrotext",
				macrotext = Mount.Journal.SummonMacro(pick.mountId, pick.spell, pick.name),
				id = pick.mountId,
				type2 = "macro",
				macrotext2 = "/stopmacro",
				type3 = "macro",
				macrotext3 = "/stopmacro",
			})
		else
			EBS.ExtraSlot.SetAction(btn, {
				type = "spell",
				id = pick.spell,
				spell = pick.spell,
				type2 = "macro",
				macrotext2 = "/stopmacro",
				type3 = "macro",
				macrotext3 = "/stopmacro",
			})
		end
	else
		EBS.ExtraSlot.Clear(btn)
	end
end

function Mount.Register(host)
	local created
	created, btn = EBS.ExtraSlot.Create(host, {
		name = "FluxNCMount",
		roleId = "nc_mount",
		kind = "mount",
		columnGroup = "mount",
		columnPriority = 2,
		order = 1,
		placeholder = "Interface/Icons/Ability_Mount_RidingHorse",
		label = "Mount",
		binding = "FLUXGRIDSMARTMOUNT",
		smartFn = function()
			return slot and slot.smart
		end,
	})
	slot = created
	if btn and btn.Widget then
		btn.Widget:HookScript("PostClick", function(_, mouse, down)
			if down then
				return
			end
			if mouse == "RightButton" then
				if Flux.EBS.Flyout and Flux.EBS.Flyout.Toggle then
					Flux.EBS.Flyout.Toggle(btn.Widget)
				end
			elseif mouse == "MiddleButton" then
				if Mode() == "SmartMount" then
					SetMode("VendorMount")
				else
					SetMode("SmartMount")
				end
				Mount.Refresh()
			end
		end)
	end
end
