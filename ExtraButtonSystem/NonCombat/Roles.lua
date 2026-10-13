-- ExtraButtonSystem/NonCombat/Roles.lua — hearth / mount / teleport / food / water / consumables.
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS

local Roles = {}
EBS.NonCombat = EBS.NonCombat or {}
EBS.NonCombat.Roles = Roles

local slots = {}

local function ConsumablesDB()
	_FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
	if type(_FluxUI_CharSavedVars.consumables) ~= "table" then
		_FluxUI_CharSavedVars.consumables = { presets = { default = { items = {} } }, activePreset = "default" }
	end
	local db = _FluxUI_CharSavedVars.consumables
	if type(db.presets) ~= "table" then
		db.presets = { default = { items = {} } }
	end
	if not db.activePreset or not db.presets[db.activePreset] then
		db.activePreset = "default"
		db.presets.default = db.presets.default or { items = {} }
	end
	return db
end

local function ConsumablesItems()
	local db = ConsumablesDB()
	local preset = db.presets[db.activePreset]
	return preset and preset.items or {}
end

local function PickConsumable()
	local items = ConsumablesItems()
	for i = 1, #items do
		local id = tonumber(items[i] and (items[i].itemID or items[i].id or items[i]))
		if id and Flux.Inventory then
			local n = Flux.Inventory.GetLiveCount(id, { bags = true, bank = false, warband = false, equipped = false })
			if n and n > 0 then
				return { type = "item", id = id, count = n }
			end
		end
	end
	return nil
end

function Roles.AddConsumableItem(itemID)
	itemID = tonumber(itemID)
	if not itemID then
		return
	end
	local items = ConsumablesItems()
	for i = 1, #items do
		local id = tonumber(items[i] and (items[i].itemID or items[i].id or items[i]))
		if id == itemID then
			return
		end
	end
	items[#items + 1] = { itemID = itemID }
	if EBS.Layout then
		EBS.Layout.Request("consumables")
	end
end

local function Make(host, cfg)
	local btn = EBS.Button.Create(host.Frame, {
		size = host.buttonSize,
		roleId = cfg.roleId,
		kind = cfg.kind,
		placeholder = cfg.icon,
		placeholderLabel = cfg.label,
	})
	btn:SetPlaceholder(cfg.icon, cfg.label)
	btn:SetLocked(cfg.locked ~= false)
	if cfg.binding then
		btn:BindClick(cfg.binding)
	end
	if cfg.flyout then
		btn.flyoutCategory = cfg.flyout
	end
	local slot = EBS.Layout.AttachButton(host, btn, {
		roleId = cfg.roleId,
		kind = cfg.kind,
		columnGroup = cfg.columnGroup,
		columnPriority = cfg.columnPriority,
		order = cfg.order,
		smartFn = function()
			return slot.smart
		end,
	})
	slot.refresh = cfg.refresh
	slots[#slots + 1] = slot
	return slot
end

function Roles.Register(host)
	wipe(slots)
	Make(host, {
		roleId = "nc_hearthstone",
		kind = "hearth",
		columnGroup = "hearth",
		columnPriority = 1,
		order = 1,
		icon = "Interface/Icons/INV_Misc_Rune_01",
		label = "Hearthstone",
		binding = "FLUXGRIDHEARTH",
		flyout = "hearth",
		refresh = function(slot)
			local pick = EBS.Kind.PickHearth()
			slot.smart = pick ~= nil
			if pick then
				slot.btn:SetAction(pick)
			else
				slot.btn:ClearAction()
			end
		end,
	})
	Make(host, {
		roleId = "nc_mount",
		kind = "mount",
		columnGroup = "mount",
		columnPriority = 2,
		order = 1,
		icon = "Interface/Icons/Ability_Mount_RidingHorse",
		label = "Mount",
		binding = "FLUXGRIDSMARTMOUNT",
		flyout = "mount",
		refresh = function(slot)
			local pick = EBS.Kind.PickMount(false)
			local vendor = EBS.Kind.PickMount(true)
			slot.smart = pick ~= nil
			if pick then
				if vendor and vendor.id ~= pick.id then
					pick.type2 = "spell"
					pick.spell2 = vendor.spell or vendor.id
					pick.id2 = vendor.id
				end
				slot.btn:SetAction(pick)
			else
				slot.btn:ClearAction()
			end
			if vendor then
				slot.btn.vendorMount = vendor
				local wname = slot.btn.Widget and slot.btn.Widget.GetName and slot.btn.Widget:GetName()
				if wname then
					Flux.Scheduler.Request("structural", "ebs.bind.vendor", function()
						ClearOverrideBindings(slot.btn.Widget)
						slot.btn:BindClick("FLUXGRIDSMARTMOUNT")
						for i = 1, 2 do
							local key = GetBindingKey("FLUXGRIDVENDORMOUNT", i)
							if key then
								SetOverrideBindingClick(slot.btn.Widget, true, key, wname, "RightButton")
							end
						end
					end, "ebs.vendorbind")
				end
			end
		end,
	})
	Make(host, {
		roleId = "nc_teleport",
		kind = "teleport",
		columnGroup = "teleport",
		columnPriority = 3,
		order = 1,
		icon = "Interface/Icons/Spell_Arcane_PortalIronforge",
		label = "Class Teleport",
		binding = "FLUXCLASS_TELEPORT",
		flyout = "teleport",
		refresh = function(slot)
			local tp = EBS.Kind.PickTeleport()
			local portal = EBS.Kind.PickPortal()
			slot.smart = tp ~= nil
			if tp then
				if portal then
					tp.type2 = "spell"
					tp.spell2 = Flux.Spell.FormatCastAttribute(portal.id)
					tp.id2 = portal.id
				end
				slot.btn:SetAction(tp)
			else
				slot.btn:ClearAction()
			end
		end,
	})
	Make(host, {
		roleId = "nc_food",
		kind = "food",
		columnGroup = "foodwater",
		columnPriority = 4,
		order = 2,
		icon = "Interface/Icons/INV_Misc_Food_15",
		label = "Food",
		binding = "FLUXGRID_FOOD_OR_RECUP",
		refresh = function(slot)
			local pick = EBS.Kind.Pick("food")
			local conj = EBS.Kind.PickConjure("food")
			slot.smart = pick ~= nil or conj ~= nil
			if pick then
				local spec = { type = "item", id = pick.itemID, count = pick.count }
				if conj then
					spec.type2 = "spell"
					spec.spell2 = Flux.Spell.FormatCastAttribute(conj.id)
					spec.id2 = conj.id
				end
				slot.btn:SetAction(spec)
			elseif conj then
				slot.btn:SetAction(conj)
			else
				slot.btn:ClearAction()
			end
		end,
	})
	Make(host, {
		roleId = "nc_water",
		kind = "water",
		columnGroup = "foodwater",
		columnPriority = 4,
		order = 1,
		icon = "Interface/Icons/INV_Drink_07",
		label = "Water",
		binding = "FLUXGRID_WATER_OR_COMBINED",
		refresh = function(slot)
			if not EBS.Visibility.PlayerUsesMana() then
				local food = EBS.Kind.Pick("food")
				slot.smart = food ~= nil
				if food then
					slot.btn:SetAction({ type = "item", id = food.itemID, count = food.count })
				else
					slot.btn:ClearAction()
				end
				return
			end
			local pick = EBS.Kind.Pick("water")
			local conj = EBS.Kind.PickConjure("water")
			slot.smart = pick ~= nil or conj ~= nil
			if pick then
				local spec = { type = "item", id = pick.itemID, count = pick.count }
				if conj then
					spec.type2 = "spell"
					spec.spell2 = Flux.Spell.FormatCastAttribute(conj.id)
					spec.id2 = conj.id
				end
				slot.btn:SetAction(spec)
			elseif conj then
				slot.btn:SetAction(conj)
			else
				slot.btn:ClearAction()
			end
		end,
	})
	local cons = Make(host, {
		roleId = "nc_consumables",
		kind = "consumables",
		columnGroup = "consumables",
		columnPriority = 5,
		order = 1,
		icon = "Interface/Icons/inv_potion_41",
		label = "Consumables",
		binding = "FLUXGRID_CONSUMABLES",
		flyout = "consumables",
		locked = false,
		refresh = function(slot)
			local pick = PickConsumable()
			slot.smart = pick ~= nil
			if pick then
				slot.btn:SetAction(pick)
			else
				slot.btn:ClearAction()
			end
		end,
	})
	cons.btn.OnReceiveDragCallback = function(ctype, id)
		if ctype == "item" then
			Roles.AddConsumableItem(id)
		end
	end
end

function Roles.Refresh()
	for i = 1, #slots do
		local slot = slots[i]
		if slot.refresh then
			Flux.Safecall(slot.refresh, slot)
		end
	end
end

function Roles.GetSlots()
	return slots
end
