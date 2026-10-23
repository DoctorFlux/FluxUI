-- ExtraButtonSystem/FlyoutEngine/Def.lua — in-memory flyout button lists.
local addonName, ns = ...
local Flux = ns.Flux
local Flyout = Flux.EBS and Flux.EBS.Flyout
if not Flyout then
	return
end

local Def = {}
Flyout.Def = Def

local function ResolveItemRef(src)
	if type(src) ~= "table" then
		return nil
	end
	local id = tonumber(src.itemId or src.ItemId or src.id or src["$itemId"] or src["$reagentItemId"])
	if id then
		return id
	end
	local item = src.item
	if type(item) == "number" then
		return item
	end
	if type(item) == "string" then
		local fromLink = item:match("item:(%d+)")
		if fromLink then
			return tonumber(fromLink)
		end
		local asNum = tonumber(item)
		if asNum then
			return asNum
		end
		return item
	end
	return nil
end

local function CopyBtn(src)
	if type(src) ~= "table" then
		return nil
	end
	local dst = {
		type = src.type,
		spell = src.spell or src.spellId or src.SpellId,
		item = ResolveItemRef(src),
		macro = src.macro or src.macroId,
		macrotext = src.macrotext or src.macroText,
		macrotext2 = src.macrotext2 or src.macroText2,
		icon = src.icon or src.texture,
		name = src.name,
		count = src.count,
		bag = src.bag,
		slot = src.slot,
		onClick = src.onClick,
		onEnter = src.onEnter,
		onLeave = src.onLeave,
		isClear = src.isClear,
		outfitID = src.outfitID,
		onDragStart = src.onDragStart,
		tooltip = src.tooltip,
		skipFavorite = src.skipFavorite,
		skipUse = src.skipUse,
		isActive = src.isActive,
		isReagent = src.isReagent or src["$isReagent"],
		currentCount = src.currentCount or src["$currentCount"],
		targetCount = src.targetCount or src["$targetCount"],
	}
	return dst
end

function Def.NormalizeList(buttons)
	local list = {}
	if type(buttons) ~= "table" then
		return list
	end
	local maxN = Flyout.MAX_BUTTONS or 36
	local n = 0
	for i = 1, maxN do
		local src = buttons[i]
		if src then
			local row = CopyBtn(src)
			if row then
				n = n + 1
				list[n] = row
			end
		end
	end
	return list
end

function Def.ItemAttr(item)
	if item == nil then
		return nil
	end
	if type(item) == "number" then
		return "item:" .. tostring(item)
	end
	if type(item) == "string" then
		if item:match("^item:") or item:match("^%d+$") then
			if item:match("^%d+$") then
				return "item:" .. item
			end
			return item
		end
		return item
	end
	return nil
end
