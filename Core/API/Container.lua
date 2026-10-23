-- Container.lua — C_Container vs GetContainer* bag APIs
local addonName, ns = ...
local Flux = ns.Flux

local Container = {}
Flux.Container = Container
Flux.API = Flux.API or {}
Flux.API.Container = Container

local function CoerceNum(n)
	n = tonumber(n)
	if n then
		return n
	end
	if Flux.Secrets and Flux.Secrets.SafeGetNumber then
		return Flux.Secrets.SafeGetNumber(n, 0)
	end
	return 0
end

local function TryNumSlots(fn, bag)
	if type(fn) ~= "function" then
		return 0
	end
	local ok, n = pcall(fn, bag)
	if not ok then
		return 0
	end
	return CoerceNum(n)
end

function Container.GetNumSlots(bag)
	local n = TryNumSlots(C_Container and C_Container.GetContainerNumSlots, bag)
	-- Classic bank (-1 / bank bags) can answer the legacy API when C_Container
	-- returns 0 on the open tick.
	if n <= 0 then
		n = TryNumSlots(GetContainerNumSlots, bag)
	end
	return n
end

-- Bag ids include backpack 0 and classic negatives (bank -1, keyring -2, reagent -3).
-- Slot is a luaIndex: integer >= 1. Slot 0 is truthy in Lua and C_Container rejects it.
local function AsBagSlotInteger(v)
	if v == nil then
		return nil
	end
	if Flux.Secrets and Flux.Secrets.IsSecretValue and Flux.Secrets.IsSecretValue(v) then
		return nil
	end
	local ok, n = pcall(tonumber, v)
	if not ok or type(n) ~= "number" then
		return nil
	end
	if n ~= n or n ~= math.floor(n) then
		return nil
	end
	return n
end

local function ValidBagAndSlot(bag, slot)
	bag = AsBagSlotInteger(bag)
	slot = AsBagSlotInteger(slot)
	if bag == nil or slot == nil or slot < 1 or slot > 4294967295 then
		return nil, nil
	end
	return bag, slot
end

local function CoerceItemID(v)
	if v == nil then
		return nil
	end
	local n = tonumber(v)
	if n and n > 0 then
		return n
	end
	if Flux.Secrets and Flux.Secrets.SafeGetNumber then
		n = Flux.Secrets.SafeGetNumber(v, 0)
		if n and n > 0 then
			return n
		end
	end
	return nil
end

function Container.GetItemInfo(bag, slot)
	bag, slot = ValidBagAndSlot(bag, slot)
	if bag == nil or slot == nil then
		return nil
	end
	local info
	if C_Container and C_Container.GetContainerItemInfo then
		local ok, result = pcall(C_Container.GetContainerItemInfo, bag, slot)
		if ok and type(result) == "table" then
			info = result
		end
	end
	local itemID = info and CoerceItemID(info.itemID)
	local stackCount = info and (info.stackCount or info.count)
	local hyperlink = info and (info.hyperlink or info.link)
	local noItemID = false
	if (not itemID or itemID == 0) and C_Container and C_Container.GetContainerItemID then
		local ok, raw = pcall(C_Container.GetContainerItemID, bag, slot)
		if ok then
			itemID = CoerceItemID(raw) or itemID
			noItemID = raw == nil
		end
	end
	if (not itemID or itemID == 0) and GetContainerItemInfo then
		local ok, icon, count, locked, quality, readable, lootable, itemLink, isFiltered, noValue, legacyID =
			pcall(GetContainerItemInfo, bag, slot)
		if ok and (legacyID or itemLink or icon) then
			return {
				iconFileID = icon or (info and info.iconFileID),
				stackCount = count or stackCount,
				isLocked = locked,
				quality = quality or (info and info.quality),
				isReadable = readable,
				hasLoot = lootable,
				hyperlink = itemLink or hyperlink,
				isFiltered = isFiltered,
				hasNoValue = noValue,
				itemID = CoerceItemID(legacyID) or itemID,
			}
		end
	end
	if info then
		if (not itemID or itemID == 0) and hyperlink then
			itemID = CoerceItemID(string.match(tostring(hyperlink), "item:(%d+)"))
		end
		if itemID and itemID ~= info.itemID then
			-- Copy so we never mutate Blizzard mixin tables.
			local copy = {}
			for k, v in pairs(info) do
				copy[k] = v
			end
			copy.itemID = itemID
			if stackCount and not copy.stackCount then
				copy.stackCount = stackCount
			end
			if hyperlink and not copy.hyperlink then
				copy.hyperlink = hyperlink
			end
			return copy
		end
		return info
	end
	-- Second return: no probe found an item, so the slot is empty rather than
	-- holding something whose data is not cached yet.
	return nil, noItemID
end

function Container.GetItemID(bag, slot)
	bag, slot = ValidBagAndSlot(bag, slot)
	if bag == nil or slot == nil then
		return nil
	end
	if C_Container and C_Container.GetContainerItemID then
		local ok, id = pcall(C_Container.GetContainerItemID, bag, slot)
		if ok and id ~= nil then
			return id
		end
	end
	local info = Container.GetItemInfo(bag, slot)
	return info and info.itemID or nil
end

function Container.GetItemLink(bag, slot)
	bag, slot = ValidBagAndSlot(bag, slot)
	if bag == nil or slot == nil then
		return nil
	end
	if C_Container and C_Container.GetContainerItemLink then
		local ok, link = pcall(C_Container.GetContainerItemLink, bag, slot)
		if ok then
			return link
		end
		return nil
	end
	local info = Container.GetItemInfo(bag, slot)
	if info then
		return info.hyperlink
	end
	if GetContainerItemLink then
		local ok, link = pcall(GetContainerItemLink, bag, slot)
		if ok then
			return link
		end
	end
	return nil
end

function Container.PickupItem(bag, slot)
	bag, slot = ValidBagAndSlot(bag, slot)
	if bag == nil or slot == nil then
		return
	end
	if C_Container and C_Container.PickupContainerItem then
		pcall(C_Container.PickupContainerItem, bag, slot)
		return
	end
	if PickupContainerItem then
		pcall(PickupContainerItem, bag, slot)
	end
end

function Container.UseItem(bag, slot, ...)
	bag, slot = ValidBagAndSlot(bag, slot)
	if bag == nil or slot == nil then
		return
	end
	if C_Container and C_Container.UseContainerItem then
		pcall(C_Container.UseContainerItem, bag, slot, ...)
		return
	end
	if UseContainerItem then
		pcall(UseContainerItem, bag, slot, ...)
	end
end

function Container.SplitItem(bag, slot, amount)
	bag, slot = ValidBagAndSlot(bag, slot)
	if bag == nil or slot == nil then
		return
	end
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then
		return
	end
	if C_Container and C_Container.SplitContainerItem then
		pcall(C_Container.SplitContainerItem, bag, slot, amount)
		return
	end
	if SplitContainerItem then
		pcall(SplitContainerItem, bag, slot, amount)
	end
end

function Container.GetNumFreeSlots(bag)
	if C_Container and C_Container.GetContainerNumFreeSlots then
		return C_Container.GetContainerNumFreeSlots(bag)
	end
	if GetContainerNumFreeSlots then
		return GetContainerNumFreeSlots(bag)
	end
	return 0
end

-- HUD counters use live native bag capacity, never the deferred item snapshot
-- or another button's cached FontString. Reagent, keyring and bank slots are
-- outside this ordinary carried-bag total.
local function FreeSlotNumber(value)
	if issecretvalue and issecretvalue(value) then return nil end
	if type(value) == "number" and value >= 0 and value == math.floor(value) then
		return value
	end
end

function Container.GetTotalFreeBagSlots()
	local native = C_Container and C_Container.CalculateTotalNumberOfFreeBagSlots
	if native then
		local ok, value = pcall(native)
		value = ok and FreeSlotNumber(value)
		if value then return value end
	end
	local total = 0
	local getFree = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
	if not getFree then return total end
	local reagent = REAGENTBAG_CONTAINER or (Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag)
	local last = math.min(NUM_BAG_SLOTS or 4, ITEM_INVENTORY_BANK_BAG_OFFSET or 4)
	for bag = 0, last do
		if bag ~= reagent then
			local ok, free = pcall(getFree, bag)
			if ok then total = total + (FreeSlotNumber(free) or 0) end
		end
	end
	return total
end

local freeSlotListeners = {}
local freeSlotFrame, freeSlotPending, freeSlotLast

local function PublishFreeBagSlots(total)
	total = total or Container.GetTotalFreeBagSlots()
	if total == freeSlotLast then return end
	freeSlotLast = total
	for _, callback in pairs(freeSlotListeners) do
		if Flux.Safecall then Flux.Safecall(callback, total) else callback(total) end
	end
end

local function FlushFreeBagSlots()
	freeSlotPending = false
	PublishFreeBagSlots()
end

function Container.RequestFreeBagSlotsRefresh()
	if freeSlotPending then return end
	if C_Timer and C_Timer.After then
		freeSlotPending = true
		C_Timer.After(0, FlushFreeBagSlots)
	else
		PublishFreeBagSlots()
	end
end

function Container.WatchFreeBagSlots(key, callback)
	if type(key) ~= "string" or type(callback) ~= "function" then return end
	freeSlotListeners[key] = callback
	if not freeSlotFrame then
		freeSlotFrame = CreateFrame("Frame")
		-- The login value can be backpack-only until the equipped bags arrive.
		-- Observe native readiness even when inventory scanning is deferred, and
		-- always reconcile BAG_UPDATE_DELAYED rather than waiting for a reload.
		for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE", "BAG_UPDATE_DELAYED",
			"PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED" }) do
			freeSlotFrame:RegisterEvent(event)
		end
		freeSlotFrame:SetScript("OnEvent", function(_, event, unit)
			if event ~= "UNIT_INVENTORY_CHANGED" or unit == "player" then
				Container.RequestFreeBagSlotsRefresh()
			end
		end)
	end
	-- New/replaced consumers receive a current value even if nothing changed.
	-- Updating the other subscribers here also handles late UI/addon creation.
	local total = Container.GetTotalFreeBagSlots()
	if total ~= freeSlotLast then
		PublishFreeBagSlots(total)
	else
		if Flux.Safecall then Flux.Safecall(callback, total) else callback(total) end
	end
end
