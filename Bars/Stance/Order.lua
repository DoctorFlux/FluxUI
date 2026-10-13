-- Bars/Stance/Order.lua — per-character slot order, hide keys, and added slots.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Stance = Bars.Stance or {}
Bars.Stance = Stance

local function CharDB()
	if FluxOptions and FluxOptions.db and FluxOptions.db.char then
		if not FluxOptions.db.char.actionbars then
			FluxOptions.db.char.actionbars = {}
		end
		return FluxOptions.db.char.actionbars
	end
	return nil
end

function Stance.MakeSlotKey(i, numForms, extras, customs)
	numForms = numForms or 0
	if i <= numForms then
		return "stance:" .. tostring(i)
	end
	local extraCount = type(extras) == "table" and #extras or 0
	if i <= numForms + extraCount then
		local data = extras[i - numForms]
		if not data then
			return "spell:0"
		end
		if data.isMageArmor then
			return "magearmor:" .. tostring(data.name or "")
		end
		return "spell:" .. tostring(data.spellID or 0)
	end
	if type(customs) ~= "table" then
		customs = Stance.GetCustomEntries and Stance.GetCustomEntries() or {}
	end
	local data = customs[i - numForms - extraCount]
	if data and data.key then
		return data.key
	end
	return "custom:none"
end

function Stance.GetSavedOrder()
	local cab = CharDB()
	return cab and cab.stanceBarSlotOrder
end

function Stance.SetSavedOrder(order)
	local cab = CharDB()
	if not cab then
		return
	end
	cab.stanceBarSlotOrder = order
end

function Stance.GetHiddenSlots()
	local cab = CharDB()
	return cab and cab.stanceBarHiddenSlots
end

function Stance.IsSlotHidden(key)
	if type(key) ~= "string" or key == "" then
		return false
	end
	local hidden = Stance.GetHiddenSlots()
	return hidden and hidden[key] and true or false
end

function Stance.SetSlotHidden(key, hidden)
	if type(key) ~= "string" or key == "" then
		return false
	end
	local cab = CharDB()
	if not cab then
		return false
	end
	if not cab.stanceBarHiddenSlots then
		cab.stanceBarHiddenSlots = {}
	end
	if hidden then
		cab.stanceBarHiddenSlots[key] = true
	else
		cab.stanceBarHiddenSlots[key] = nil
	end
	if Stance.RequestLayout then
		Stance.RequestLayout("hide")
	end
	if _G.FluxStanceBarOrderPanel_RequestRefresh then
		pcall(_G.FluxStanceBarOrderPanel_RequestRefresh)
	end
	return true
end

function Stance.BuildPermutation(total, numForms, extras, saved, customs)
	if type(customs) ~= "table" then
		customs = Stance.GetCustomEntries and Stance.GetCustomEntries() or {}
	end
	local keyToIndex = {}
	for i = 1, total do
		keyToIndex[Stance.MakeSlotKey(i, numForms, extras, customs)] = i
	end
	local seen, seenKey, perm = {}, {}, {}
	if type(saved) == "table" then
		for _, k in ipairs(saved) do
			if type(k) == "string" and not seenKey[k] then
				seenKey[k] = true
				local idx = keyToIndex[k]
				if idx and not seen[idx] then
					seen[idx] = true
					perm[#perm + 1] = idx
				end
			end
		end
	end
	for i = 1, total do
		if not seen[i] then
			perm[#perm + 1] = i
		end
	end
	return perm
end

function Stance.ReorderKey(fromKey, toKey)
	if type(fromKey) ~= "string" or type(toKey) ~= "string" or fromKey == toKey then
		return
	end
	local numForms, extras, customs, total = Stance.Catalog()
	local perm = Stance.BuildPermutation(total, numForms, extras, Stance.GetSavedOrder(), customs)
	local keys = {}
	for i = 1, #perm do
		keys[i] = Stance.MakeSlotKey(perm[i], numForms, extras, customs)
	end
	local ia, ib
	for i = 1, #keys do
		if keys[i] == fromKey then
			ia = i
		end
		if keys[i] == toKey then
			ib = i
		end
	end
	if not ia or not ib then
		return
	end
	keys[ia], keys[ib] = keys[ib], keys[ia]
	Stance.SetSavedOrder(keys)
	if Stance.RequestLayout then
		Stance.RequestLayout("reorder")
	end
end

function Stance.ApplyHiddenToShouldShow(shouldShow, total, numForms, extras, customs)
	local hidden = Stance.GetHiddenSlots()
	if not hidden or not shouldShow then
		return shouldShow
	end
	if type(customs) ~= "table" then
		customs = Stance.GetCustomEntries and Stance.GetCustomEntries() or {}
	end
	for i = 1, total do
		if shouldShow[i] then
			local key = Stance.MakeSlotKey(i, numForms, extras, customs)
			if hidden[key] then
				shouldShow[i] = false
			end
		end
	end
	return shouldShow
end

local CUSTOM_TYPES = {
	spell = true,
	item = true,
	macro = true,
	mount = true,
	toy = true,
	battlepet = true,
}

local function CustomStorageKey(entry)
	if type(entry) ~= "table" or not entry.type or entry.id == nil or entry.id == "" then
		return nil
	end
	return "custom:" .. tostring(entry.type) .. ":" .. tostring(entry.id)
end

local function NormalizeCustom(entry)
	if type(entry) ~= "table" then
		return nil
	end
	local kind = entry.type
	if not CUSTOM_TYPES[kind] then
		return nil
	end
	local name = entry.name
	local id = entry.id
	if kind == "macro" then
		if type(name) ~= "string" or name == "" then
			if type(id) == "string" and id ~= "" then
				name = id
			else
				return nil
			end
		end
		id = name
	else
		if id == nil or id == "" then
			return nil
		end
		if kind ~= "battlepet" then
			local n = tonumber(id)
			if n then
				id = n
			end
		end
	end
	if type(name) ~= "string" or name == "" then
		name = nil
	end
	return {
		type = kind,
		id = id,
		name = name,
	}
end

local function RefreshCustomList()
	if Stance.RequestLayout then
		Stance.RequestLayout("custom")
	end
	if _G.FluxStanceBarOrderPanel_RequestRefresh then
		pcall(_G.FluxStanceBarOrderPanel_RequestRefresh)
	end
end

function Stance.CustomIcon(entry)
	if type(entry) ~= "table" then
		return nil
	end
	local kind = entry.type or entry.actionType
	local id = entry.id
	if kind == "spell" then
		return Flux.Spell and Flux.Spell.GetIcon and Flux.Spell.GetIcon(id)
	end
	if kind == "item" or kind == "toy" then
		return Flux.Item and Flux.Item.GetIcon and Flux.Item.GetIcon(id)
	end
	if kind == "mount" and C_MountJournal and C_MountJournal.GetMountInfoByID then
		local ok, _, _, icon = pcall(C_MountJournal.GetMountInfoByID, tonumber(id))
		if ok then
			return icon
		end
	end
	if kind == "macro" and GetMacroIndexByName and GetMacroInfo then
		local idx = GetMacroIndexByName(id)
		if idx and idx > 0 then
			local _, icon = GetMacroInfo(idx)
			return icon
		end
	end
	if kind == "battlepet" and C_PetJournal and C_PetJournal.GetPetInfoByPetID then
		local ok, _, _, _, _, _, _, _, _, icon = pcall(C_PetJournal.GetPetInfoByPetID, id)
		if ok then
			return icon
		end
	end
	return nil
end

local function CustomDisplayName(entry)
	if type(entry.name) == "string" and entry.name ~= "" then
		return entry.name
	end
	local kind = entry.type
	local id = entry.id
	if kind == "spell" and Flux.Spell and Flux.Spell.GetName then
		return Flux.Spell.GetName(id) or tostring(id)
	end
	if (kind == "item" or kind == "toy") and Flux.Item and Flux.Item.GetInfo then
		local name = Flux.Item.GetInfo(id)
		if type(name) == "string" and name ~= "" then
			return name
		end
	end
	if kind == "mount" and C_MountJournal and C_MountJournal.GetMountInfoByID then
		local ok, name = pcall(C_MountJournal.GetMountInfoByID, tonumber(id))
		if ok and type(name) == "string" and name ~= "" then
			return name
		end
	end
	return tostring(id)
end

function Stance.GetSavedCustomSlots()
	local cab = CharDB()
	local raw = cab and cab.stanceBarCustomSlots
	local out = {}
	if type(raw) ~= "table" then
		return out
	end
	local seen = {}
	for i = 1, #raw do
		local entry = NormalizeCustom(raw[i])
		local key = entry and CustomStorageKey(entry)
		if key and not seen[key] then
			seen[key] = true
			out[#out + 1] = entry
		end
	end
	return out
end

function Stance.SetSavedCustomSlots(list)
	local cab = CharDB()
	if not cab then
		return false
	end
	local out = {}
	local seen = {}
	if type(list) == "table" then
		for i = 1, #list do
			local entry = NormalizeCustom(list[i])
			local key = entry and CustomStorageKey(entry)
			if key and not seen[key] then
				seen[key] = true
				out[#out + 1] = entry
			end
		end
	end
	cab.stanceBarCustomSlots = out
	return true
end

function Stance.HasCustomSlots()
	return #Stance.GetSavedCustomSlots() > 0
end

function Stance.GetCustomEntries()
	local saved = Stance.GetSavedCustomSlots()
	local out = {}
	for i = 1, #saved do
		local entry = saved[i]
		local key = CustomStorageKey(entry)
		local name = CustomDisplayName(entry)
		local actionValue = entry.id
		if entry.type == "macro" then
			actionValue = { name = entry.name or entry.id }
		end
		out[i] = {
			custom = true,
			removable = true,
			type = entry.type,
			actionType = entry.type,
			id = entry.id,
			actionValue = actionValue,
			name = name,
			spellName = name,
			spellID = (entry.type == "spell") and tonumber(entry.id) or nil,
			itemID = (entry.type == "item" or entry.type == "toy") and tonumber(entry.id) or nil,
			key = key,
			texture = Stance.CustomIcon(entry),
		}
	end
	return out
end

function Stance.Catalog()
	local S = Flux.Shapeshift
	local numForms = S and S.GetNumForms and S.GetNumForms() or 0
	local extras = Stance.GetAvailableSpells and Stance.GetAvailableSpells() or {}
	local customs = Stance.GetCustomEntries()
	return numForms, extras, customs, numForms + #extras + #customs
end

function Stance.BuiltinHasSpell(spellID, spellName)
	local function Same(a, b)
		if a == nil or b == nil then
			return false
		end
		if Flux.Spell and Flux.Spell.IdsMatch then
			return Flux.Spell.IdsMatch(a, b) and true or false
		end
		return a == b
	end
	local S = Flux.Shapeshift
	local num = S and S.GetNumForms and S.GetNumForms() or 0
	for i = 1, num do
		local sid
		if S.GetFormInfo then
			local _, _, _, formSpell = S.GetFormInfo(i)
			sid = formSpell
		end
		if Same(sid, spellID) then
			return true
		end
		if spellName and sid and Flux.Spell and Flux.Spell.GetName then
			local n = Flux.Spell.GetName(sid)
			if n and n == spellName then
				return true
			end
		end
	end
	local extras = Stance.GetAvailableSpells and Stance.GetAvailableSpells() or {}
	for i = 1, #extras do
		local data = extras[i]
		if data then
			if Same(data.spellID, spellID) then
				return true
			end
			local n = data.name or data.spellName
			if spellName and n and n == spellName then
				return true
			end
		end
	end
	return false
end

local function CustomConflicts(entry)
	local key = CustomStorageKey(entry)
	local saved = Stance.GetSavedCustomSlots()
	for i = 1, #saved do
		if CustomStorageKey(saved[i]) == key then
			return true
		end
	end
	if entry.type == "spell" then
		if Stance.BuiltinHasSpell(entry.id, entry.name) then
			return true
		end
	elseif entry.type == "item" or entry.type == "toy" or entry.type == "mount" then
		if Stance.CustomTrackSpell then
			local sid = Stance.CustomTrackSpell(entry)
			if sid and Stance.BuiltinHasSpell(sid) then
				return true
			end
		end
	end
	return false
end

function Stance.AddCustomSlot(entry)
	entry = NormalizeCustom(entry)
	if not entry or CustomConflicts(entry) then
		return false
	end
	local cab = CharDB()
	if not cab then
		return false
	end
	if type(cab.stanceBarCustomSlots) ~= "table" then
		cab.stanceBarCustomSlots = {}
	end
	cab.stanceBarCustomSlots[#cab.stanceBarCustomSlots + 1] = entry
	if ClearCursor then
		ClearCursor()
	end
	RefreshCustomList()
	return true
end

function Stance.AddCustomFromCursor()
	local Assign = _G.FluxNCUtilitySlots
	if not Assign or not Assign.ParseCursor then
		return false
	end
	local parsed = Assign.ParseCursor()
	if not parsed then
		return false
	end
	return Stance.AddCustomSlot(parsed)
end

function Stance.ReplaceCustomSpellId(oldId, newId, newName)
	oldId = tonumber(oldId)
	newId = tonumber(newId)
	if not oldId or not newId or oldId == newId then
		return false
	end
	local cab = CharDB()
	if not cab then
		return false
	end
	local oldKey = "custom:spell:" .. tostring(oldId)
	local newKey = "custom:spell:" .. tostring(newId)
	local changed = false
	local newExists = false
	local list = cab.stanceBarCustomSlots
	if type(list) == "table" then
		for i = 1, #list do
			local entry = list[i]
			if type(entry) == "table" and entry.type == "spell" and tonumber(entry.id) == newId then
				newExists = true
				break
			end
		end
		if newExists then
			for i = #list, 1, -1 do
				local entry = list[i]
				if type(entry) == "table" and entry.type == "spell" and tonumber(entry.id) == oldId then
					table.remove(list, i)
					changed = true
				end
			end
		else
			for i = 1, #list do
				local entry = list[i]
				if type(entry) == "table" and entry.type == "spell" and tonumber(entry.id) == oldId then
					entry.id = newId
					if type(newName) == "string" and newName ~= "" then
						entry.name = newName
					end
					changed = true
				end
			end
		end
	end
	local order = cab.stanceBarSlotOrder
	if type(order) == "table" then
		local out = {}
		local seen = {}
		for i = 1, #order do
			local key = order[i]
			if key == oldKey then
				changed = true
				key = newExists and nil or newKey
			end
			if type(key) == "string" and key ~= "" and not seen[key] then
				seen[key] = true
				out[#out + 1] = key
			end
		end
		cab.stanceBarSlotOrder = out
	end
	local hidden = cab.stanceBarHiddenSlots
	if type(hidden) == "table" and hidden[oldKey] then
		if not newExists then
			hidden[newKey] = true
		end
		hidden[oldKey] = nil
		changed = true
	end
	return changed
end

function Stance.RemoveCustomSlot(key)
	if type(key) ~= "string" or key == "" then
		return false
	end
	local cab = CharDB()
	if not cab then
		return false
	end
	local list = cab.stanceBarCustomSlots
	local removed = false
	if type(list) == "table" then
		for i = #list, 1, -1 do
			if CustomStorageKey(NormalizeCustom(list[i])) == key then
				table.remove(list, i)
				removed = true
			end
		end
	end
	local order = cab.stanceBarSlotOrder
	if type(order) == "table" then
		for i = #order, 1, -1 do
			if order[i] == key then
				table.remove(order, i)
			end
		end
	end
	if type(cab.stanceBarHiddenSlots) == "table" then
		cab.stanceBarHiddenSlots[key] = nil
	end
	if removed then
		RefreshCustomList()
	end
	return removed
end
