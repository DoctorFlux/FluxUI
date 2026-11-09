-- ExtraButtonSystem/Combat/Kind.lua — shared bandage / potion bind.
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS
local Combat = EBS.Combat or {}
EBS.Combat = Combat

local Kind = {}
Combat.Kind = Kind

function Kind.Make(host, cfg)
	local mod = {}
	local slot, btn
	local Bind = EBS.ConsumableBind

	function mod.Refresh()
		if not slot then
			return
		end
		local rec = Bind and Bind.GetBestOwned and Bind.GetBestOwned(cfg.kind)
		local createID
		if Bind and Bind.GetPreferredCreateSpell then
			createID = select(1, Bind.GetPreferredCreateSpell(cfg.kind))
		end
		slot.smart = (rec and rec.itemID) or (cfg.canCreate and createID) or (Bind and Bind.CanCraft and Bind.CanCraft(cfg.kind))
		if rec and rec.itemID then
			local spec = Bind.UseItemSpec(rec.itemID, {
				spell2 = createID and Bind.SpellAttr(createID) or nil,
			})
			if not createID then
				spec.type2 = "macro"
				spec.macrotext2 = "/stopmacro"
			end
			EBS.ExtraSlot.SetAction(btn, spec)
		elseif createID then
			EBS.ExtraSlot.SetAction(btn, {
				type = "spell",
				id = createID,
				spell = createID,
				type3 = "macro",
				macrotext3 = "/stopmacro",
			})
		else
			EBS.ExtraSlot.Clear(btn)
		end
	end

	function mod.Register()
		local created
		created, btn = EBS.ExtraSlot.Create(host, {
			name = cfg.name,
			roleId = cfg.roleId,
			kind = cfg.kind,
			columnGroup = cfg.columnGroup,
			columnPriority = cfg.columnPriority,
			order = cfg.order or 1,
			placeholder = cfg.icon,
			label = cfg.label,
			binding = cfg.binding,
			smartFn = function()
				return slot and slot.smart
			end,
		})
		slot = created
		if cfg.middleDelete and btn and Bind and Bind.WireMiddleDelete then
			Bind.WireMiddleDelete(btn, function()
				local rec = Bind.GetBestOwned(cfg.kind)
				return rec and rec.itemID
			end)
		end
		if btn and btn.Widget then
			btn.Widget:HookScript("PostClick", function(_, mouse, down)
				if down or mouse ~= "RightButton" then
					return
				end
				local createID = Bind and Bind.GetPreferredCreateSpell and select(1, Bind.GetPreferredCreateSpell(cfg.kind))
				if not createID and Bind and Bind.OpenQty then
					Bind.OpenQty(cfg.kind, btn.Widget)
				end
			end)
		end
	end

	return mod
end
