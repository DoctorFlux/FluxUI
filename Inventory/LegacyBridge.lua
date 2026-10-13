-- Inventory/LegacyBridge.lua — old HUD talks to FluxInv / FluxInventory; rewrite facts live on Flux.Inventory.
local addonName, ns = ...
local Flux = ns.Flux

local function Inv()
	return Flux and Flux.Inventory
end

local FluxInv = _G.FluxInv or {}
_G.FluxInv = FluxInv

--- opts carries tier / regions / deferHeavy / sync. Dropping them made every
--- consumer run inline on every pulse regardless of what it asked for.
function FluxInv.RegisterListener(key, fn, opts)
	local api = Inv()
	if api and api.Register then
		api.Register(key, fn, opts)
	end
end

function FluxInv.UnregisterListener(key)
	local api = Inv()
	if api and api.Unregister then
		api.Unregister(key)
	end
end

function FluxInv.OnChanged(fn, opts)
	if type(fn) ~= "function" then
		return
	end
	local key = opts and opts.key or ("FluxInv_anon_" .. tostring(fn))
	FluxInv.RegisterListener(key, fn, opts)
end

function FluxInv.IsBagStorm()
	local api = Inv()
	return api and api.IsBagStorm and api.IsBagStorm() or false
end

function FluxInv.IsLoginHold()
	local api = Inv()
	return api and api.IsLoginHold and api.IsLoginHold() or false
end

--- Read by FluxConsumableBest / Scan to hold their tooltip classify pass.
function FluxInv.ShouldDeferHeavyWork()
	local api = Inv()
	return api and api.ShouldDeferHeavyWork and api.ShouldDeferHeavyWork() or false
end

function FluxInv.OnStormSettled(fn)
	local api = Inv()
	if api and api.OnStormSettled then
		api.OnStormSettled(fn)
	elseif type(fn) == "function" then
		fn()
	end
end

function FluxInv.RegisterStormSettled(key, fn)
	local api = Inv()
	if api and api.RegisterStormSettled then
		api.RegisterStormSettled(key, fn)
	end
end

function FluxInv.UnregisterStormSettled(key)
	local api = Inv()
	if api and api.UnregisterStormSettled then
		api.UnregisterStormSettled(key)
	end
end

function FluxInv.IsMerchantOpen()
	local api = Inv()
	return api and api.IsMerchantOpen and api.IsMerchantOpen() or false
end

function FluxInv.IsMailboxOpen()
	local api = Inv()
	return api and api.IsMailboxOpen and api.IsMailboxOpen() or false
end

function FluxInv.GetCount(itemID, opts)
	local api = Inv()
	if api and api.GetCount then
		return api.GetCount(itemID, opts)
	end
	return 0
end

function FluxInv.GetLiveCount(itemID, opts)
	local api = Inv()
	if api and api.GetLiveCount then
		return api.GetLiveCount(itemID, opts)
	end
	return FluxInv.GetCount(itemID, opts)
end

function FluxInv.FindItem(itemID, opts)
	local api = Inv()
	if api and api.Find then
		return api.Find(itemID, opts)
	end
	return {}
end

function FluxInv.GetFirst(itemID, opts)
	local api = Inv()
	if api and api.GetFirst then
		return api.GetFirst(itemID, opts)
	end
	return nil
end

function FluxInv.IsBankOpen()
	local api = Inv()
	return api and api.IsBankOpen and api.IsBankOpen() or false
end

function FluxInv.HasWarbandBank()
	local api = Inv()
	return api and api.HasWarband and api.HasWarband() or false
end

FluxInv.Bags = {
	GetCount = function(itemID)
		return FluxInv.GetCount(itemID, { bags = true, bank = false, warband = false })
	end,
	IsReady = function()
		local api = Inv()
		return api and api.IsReady and api.IsReady() or false
	end,
	IsReliable = function()
		local api = Inv()
		if api and api.IsReliable then
			return api.IsReliable()
		end
		return api and api.IsReady and api.IsReady() or false
	end,
	MarkUnreliable = function(reason)
		local api = Inv()
		if api and api.MarkUnreliable then
			api.MarkUnreliable(reason)
		end
	end,
	NoteRefreshSettling = function()
		local api = Inv()
		if api and api.NoteRefreshSettling then
			api.NoteRefreshSettling()
		end
	end,
	GetGeneration = function()
		local api = Inv()
		if api and api.GetBagGeneration then
			return api.GetBagGeneration()
		end
		local snap = api and api.snapshots and api.snapshots.bags
		return snap and (tonumber(snap.generation) or 0) or 0
	end,
	GetLastAddedItemIDs = function()
		local api = Inv()
		if api and api.GetLastAddedItemIDs then
			return api.GetLastAddedItemIDs()
		end
		return nil
	end,
	GetUniqueItems = function(opts)
		local api = Inv()
		if api and api.GetUniqueItems then
			return api.GetUniqueItems(opts or { bags = true, bank = false, warband = false })
		end
		return {}
	end,
	FindStacks = function(itemID)
		local api = Inv()
		if api and api.Find then
			return api.Find(itemID, { bags = true, bank = false, warband = false, equipped = false })
		end
		return {}
	end,
	FindFirst = function(itemID)
		local api = Inv()
		local loc = api and api.GetFirst and api.GetFirst(itemID, { bags = true, bank = false, warband = false })
		if loc then
			return loc.bag, loc.slot
		end
		return nil, nil
	end,
}

FluxInv.Bank = {
	GetCount = function(itemID, opts)
		local ri = _G.FluxRestock and _G.FluxRestock.Inv
		if ri and ri.Bank and ri.Bank.GetCount then
			return ri.Bank.GetCount(itemID, opts)
		end
		local o = opts or {}
		return FluxInv.GetCount(itemID, { bags = false, bank = true, warband = o.warband ~= false })
	end,
	IsOpen = function()
		return FluxInv.IsBankOpen()
	end,
}

FluxInv.Equip = {
	GetCount = function(itemID)
		return FluxInv.GetCount(itemID, { bags = false, bank = false, warband = false, equipped = true })
	end,
}

function FluxInv.GetCarriedBagIDs()
	local C = Inv() and Inv().Containers
	if C and C.GetCarriedBagIDs then
		return C.GetCarriedBagIDs()
	end
	return { 0, 1, 2, 3, 4 }
end

function FluxInv.GetCharacterBankIDs()
	local C = Inv() and Inv().Containers
	if C and C.GetCharacterBankIDs then
		return C.GetCharacterBankIDs()
	end
	return {}
end

function FluxInv.GetWarbandBankIDs()
	local C = Inv() and Inv().Containers
	if C and C.GetWarbandBankIDs then
		return C.GetWarbandBankIDs()
	end
	return {}
end

function FluxInv.CountFreeSlotsInBag(bag)
	if Flux.Container and Flux.Container.GetNumFreeSlots then
		return Flux.Container.GetNumFreeSlots(bag) or 0
	end
	return 0
end

function FluxInv.GetTotalFreeBagSlots(opts)
	opts = opts or {}
	local total = 0
	local C = Inv() and Inv().Containers
	for _, bag in ipairs(FluxInv.GetCarriedBagIDs()) do
		local isKeyring = C and C.IsKeyringBag and C.IsKeyringBag(bag)
		if opts.includeKeyring or not isKeyring then
			total = total + (FluxInv.CountFreeSlotsInBag(bag) or 0)
		end
	end
	return total
end

local FluxInventory = _G.FluxInventory or {}
_G.FluxInventory = FluxInventory

function FluxInventory.RegisterCountListener(key, fn, opts)
	FluxInv.RegisterListener(key, fn, opts)
end

function FluxInventory.UnregisterCountListener(key)
	FluxInv.UnregisterListener(key)
end
