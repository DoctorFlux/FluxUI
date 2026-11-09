-- Item.lua — C_Item vs GetItemInfo
local addonName, ns = ...
local Flux = ns.Flux

local Item = {}
Flux.Item = Item
Flux.API = Flux.API or {}
Flux.API.Item = Item

function Item.GetInfo(item)
	if C_Item and C_Item.GetItemInfo then
		return C_Item.GetItemInfo(item)
	end
	if GetItemInfo then
		return GetItemInfo(item)
	end
	return nil
end

function Item.GetIcon(item)
	if C_Item and C_Item.GetItemIconByID then
		return C_Item.GetItemIconByID(item)
	end
	if GetItemIcon then
		return GetItemIcon(item)
	end
	local _, _, _, _, _, _, _, _, _, icon = Item.GetInfo(item)
	return icon
end

function Item.GetCount(itemID, includeBank, includeCharges, includeReagent, includeAccount)
	includeBank = includeBank and true or false
	includeCharges = includeCharges and true or false
	includeReagent = includeReagent and true or false
	includeAccount = includeAccount and true or false
	local function asCount(n)
		local num = tonumber(n)
		if num then
			return num
		end
		if Flux.Secrets and Flux.Secrets.SafeGetNumber then
			return Flux.Secrets.SafeGetNumber(n, 0)
		end
		return 0
	end
	local function tryCount(...)
		local api = C_Item and C_Item.GetItemCount
		if api then
			local ok, n = pcall(api, ...)
			if ok then
				local num = asCount(n)
				if num > 0 then
					return num
				end
			end
		end
		if GetItemCount then
			local ok, n = pcall(GetItemCount, ...)
			if ok then
				return asCount(n)
			end
		end
		return 0
	end
	-- Classic GetItemCount is 2–3 args. 5-arg C_Item.GetItemCount can ignore
	-- includeBank and return bags-only (>0), which would hide bank stacks if
	-- we returned it first. Prefer 3-arg whenever includeBank is set, and
	-- only keep a 5-arg result when it is actually larger.
	local three = tryCount(itemID, includeBank, includeCharges)
	if not includeBank and not includeReagent and not includeAccount then
		return three
	end
	local four = tryCount(itemID, includeBank, includeCharges, includeReagent)
	local five = tryCount(itemID, includeBank, includeCharges, includeReagent, includeAccount)
	local n = three
	if four > n then
		n = four
	end
	if five > n then
		n = five
	end
	return n
end

function Item.IsUsable(item)
	if not item then
		return nil, nil
	end
	local a, b
	if C_Item and C_Item.IsUsableItem then
		local ok, u, m = pcall(C_Item.IsUsableItem, item)
		if ok then
			a, b = u, m
		end
	elseif IsUsableItem then
		local ok, u, m = pcall(IsUsableItem, item)
		if ok then
			a, b = u, m
		end
	end
	if Flux.Secrets and Flux.Secrets.CanAccessValue then
		if a ~= nil then
			local ok, accessible = pcall(Flux.Secrets.CanAccessValue, a)
			if not ok or not accessible then
				return nil, nil
			end
		end
		if b ~= nil then
			local ok, accessible = pcall(Flux.Secrets.CanAccessValue, b)
			if not ok or not accessible then
				return nil, nil
			end
		end
	end
	if a == nil and b == nil then
		return nil, nil
	end
	local usable = Flux.Secrets and Flux.Secrets.SafeBooleanTest and Flux.Secrets.SafeBooleanTest(a, nil)
	local noMana = Flux.Secrets and Flux.Secrets.SafeBooleanTest and Flux.Secrets.SafeBooleanTest(b, false)
	if usable == nil then
		if a == nil then
			return nil, nil
		end
		usable = a and true or false
	end
	return usable, noMana and true or false
end

function Item.IsEquipped(item)
	if not item then
		return false
	end
	if C_Item and C_Item.IsEquippedItem then
		local ok, v = pcall(C_Item.IsEquippedItem, item)
		if ok and v then
			return true
		end
	end
	if IsEquippedItem then
		local ok, v = pcall(IsEquippedItem, item)
		if ok and v then
			return true
		end
	end
	return false
end

-- Classic ruby → WotLK sapphire / emerald → Cata+ Mana Gem. Unique charged
-- gems are often not IsConsumableItem; they still gray at 0 charges.
local MANA_GEM_IDS = {
	[36799] = true,
	[33312] = true,
	[22044] = true,
	[8008] = true,
	[8007] = true,
	[5513] = true,
	[5514] = true,
}

local CHARGED_MANA_GEM_IDS = { [36799] = true, [33312] = true, [22044] = true }
local STACK_CONSUMABLE_KINDS = { food = true, water = true, bandage = true, healPotion = true, manaPotion = true }

-- nil leaves other item types on their normal use-count policy. Kind context
-- also works before item data is cached, when GetItemInfo cannot identify food.
function Item.UsesConsumableCharges(itemID, kind)
	itemID = tonumber(itemID)
	if not itemID then
		return nil
	end
	if MANA_GEM_IDS[itemID] then
		return CHARGED_MANA_GEM_IDS[itemID] == true
	end
	local Best = _G.FluxConsumableBest
	local Score = Best and Best.Score
	local stone = kind == "healthstone" or (Score and Score.HealthstoneRank and Score.HealthstoneRank(itemID) > 0)
	if stone then
		local client = Flux.Client or {}
		-- Forever uses the original single-use ranks on a modern engine.
		return not (client.isCamelot or client.isEra or client.isAnniversary or client.isWrath or client.isCata)
	end
	if STACK_CONSUMABLE_KINDS[kind] then
		return false
	end
	local name, _, _, _, _, _, _, maxStack, _, _, _, classID, subclassID = Item.GetInfo(itemID)
	local consumableClass = (Enum and Enum.ItemClass and Enum.ItemClass.Consumable) or 0
	if name and classID == consumableClass and (
		(tonumber(maxStack) or 0) > 1 or subclassID == 1 or subclassID == 5 or subclassID == 7
	) then
		return false
	end
	return nil
end

-- Mana gem / emerald / potion: IsConsumableItem plus item class 0, so unique
-- charged gems still count as consumable when the API says they are not.
function Item.IsConsumable(item)
	if not item then
		return false
	end
	local id = tonumber(item)
	if id and MANA_GEM_IDS[id] then
		return true
	end
	if C_Item and C_Item.IsConsumableItem then
		local ok, v = pcall(C_Item.IsConsumableItem, item)
		if ok and v then
			return true
		end
	elseif IsConsumableItem then
		local ok, v = pcall(IsConsumableItem, item)
		if ok and v then
			return true
		end
	end
	local classId
	if C_Item and C_Item.GetItemInfoInstant then
		local ok, cid = pcall(function()
			return select(6, C_Item.GetItemInfoInstant(item))
		end)
		if ok then
			classId = cid
		end
	elseif GetItemInfoInstant then
		local ok, cid = pcall(function()
			return select(6, GetItemInfoInstant(item))
		end)
		if ok then
			classId = cid
		end
	end
	local consumableClass = (Enum and Enum.ItemClass and Enum.ItemClass.Consumable) or 0
	return classId == consumableClass
end

function Item.IsCurrent(itemId)
	if not itemId then
		return false
	end
	local function hit(fn)
		if type(fn) ~= "function" then
			return false
		end
		local ok, v = pcall(fn, itemId)
		if not ok then
			return false
		end
		if Flux.Secrets and Flux.Secrets.SafeBooleanTest then
			return Flux.Secrets.SafeBooleanTest(v, false) and true or false
		end
		return v and true or false
	end
	if hit(C_Item and C_Item.IsCurrentItem) then
		return true
	end
	return hit(IsCurrentItem)
end

function Item.CanCheckRange(unit)
	unit = unit or "target"
	if not InCombatLockdown or not InCombatLockdown() then
		return true
	end
	if not UnitCanAttack then
		return false
	end
	local ok, canAttack = pcall(UnitCanAttack, "player", unit)
	return ok and canAttack and true or false
end

function Item.IsInRange(itemId, unit)
	unit = unit or "target"
	if not itemId or not unit then
		return nil
	end
	if not Item.CanCheckRange(unit) then
		return nil
	end
	local r
	if C_Item and C_Item.IsItemInRange then
		local ok, v = pcall(C_Item.IsItemInRange, itemId, unit)
		if ok then
			r = v
		end
	end
	if r == nil and IsItemInRange then
		local ok, v = pcall(IsItemInRange, itemId, unit)
		if ok then
			r = v
		end
	end
	if r == nil then
		return nil
	end
	if Flux.Secrets and Flux.Secrets.NormalizeTriBool then
		return Flux.Secrets.NormalizeTriBool(r)
	end
	if r == true or r == 1 then
		return true
	end
	if r == false or r == 0 then
		return false
	end
	return nil
end

function Item.GetSpell(item)
	if not item then
		return nil
	end
	if C_Item and C_Item.GetItemSpell then
		local ok, name, spellID = pcall(C_Item.GetItemSpell, item)
		if ok and (name or spellID) then
			if type(spellID) == "number" and spellID > 0 then
				return name, spellID
			end
			if type(name) == "number" and name > 0 then
				return nil, name
			end
			return name, spellID
		end
	end
	if GetItemSpell then
		-- Classic: name, rank, spellID. Some clients: name, spellID.
		local ok, name, rankOrId, spellID = pcall(GetItemSpell, item)
		if ok then
			if type(spellID) == "number" and spellID > 0 then
				return name, spellID
			end
			if type(rankOrId) == "number" and rankOrId > 0 then
				return name, rankOrId
			end
			return name, spellID or rankOrId
		end
	end
	return nil
end

function Item.GetQuality(item)
	if C_Item and C_Item.GetItemQualityByID then
		return C_Item.GetItemQualityByID(item)
	end
	local _, _, quality = Item.GetInfo(item)
	return quality
end

function Item.DoesExist(item)
	if C_Item and C_Item.DoesItemExistByID then
		return C_Item.DoesItemExistByID(item)
	end
	local name = Item.GetInfo(item)
	return name ~= nil
end

-- ButtonForge: C_Item on post-DF, C_Container on Classic/TBC. Table or start,duration,enable.
-- Some clients expose a stub of the other API that always returns 0; pick the
-- longest remaining timer so unique item CDs are not lost to a GCD stub.
function Item.GetCooldown(itemId)
	if not itemId then
		return 0, 0, 0
	end
	if type(itemId) == "string" then
		itemId = tonumber(itemId) or tonumber(itemId:match("(%d+)")) or itemId
	end
	local function unpackCd(a, b, c)
		if a == nil then
			return nil
		end
		if type(a) == "table" then
			local enable = a.isEnabled
			if enable == nil then
				enable = a.enable
			end
			return a.startTime or a.start, a.duration, enable
		end
		return a, b, c
	end
	local function isSecret(v)
		local S = Flux.Secrets
		if S and S.IsSecretValue then
			local ok, secret = pcall(S.IsSecretValue, v)
			return ok and secret or false
		end
		return false
	end
	local function remain(start, duration)
		if start == nil or duration == nil then
			return nil
		end
		if isSecret(start) or isSecret(duration) then
			return nil
		end
		local s = tonumber(start) or 0
		local d = tonumber(duration) or 0
		if s <= 0 or d <= 0 then
			return 0
		end
		local now = GetTime and GetTime() or 0
		local rem = d - (now - s)
		if rem < 0 then
			return 0
		end
		return rem
	end
	local bestStart, bestDur, bestEnable, bestRemain
	local secretStart, secretDur, secretEnable
	local function consider(a, b, c)
		local start, duration, enable = unpackCd(a, b, c)
		if start == nil then
			return
		end
		local rem = remain(start, duration)
		if rem == nil then
			secretStart, secretDur, secretEnable = start, duration, enable
			return
		end
		if not bestRemain or rem > bestRemain then
			bestRemain = rem
			bestStart, bestDur, bestEnable = start, duration, enable
		end
	end
	local function try(fn)
		if not fn then
			return
		end
		local ok, a, b, c = pcall(fn, itemId)
		if ok then
			consider(a, b, c)
		end
	end
	local postDF = Flux.Client and Flux.Client.isPostDF
	if postDF then
		try(C_Item and C_Item.GetItemCooldown)
		try(C_Container and C_Container.GetItemCooldown)
		try(GetItemCooldown)
	else
		try(C_Container and C_Container.GetItemCooldown)
		try(GetItemCooldown)
		try(C_Item and C_Item.GetItemCooldown)
	end
	if bestRemain and bestRemain > 0 then
		return bestStart, bestDur, bestEnable
	end
	if secretStart ~= nil then
		return secretStart, secretDur, secretEnable
	end
	if bestStart ~= nil then
		return bestStart, bestDur, bestEnable
	end
	return 0, 0, 0
end
