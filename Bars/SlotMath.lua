-- Bars/SlotMath.lua — page + swap → action slot. No WoW APIs.
-- Restricted ChildUpdate in State.lua must match Resolve().
local addonName, ns = ...

local M = {}

function M.Pack(page, swap)
	page = tonumber(page) or 1
	swap = tonumber(swap) or 0
	if page < 1 then
		page = 1
	end
	return page + swap * 100
end

function M.Unpack(packed)
	packed = tonumber(packed) or 1
	local swap = 0
	local page = packed
	if packed >= 200 then
		swap = 2
		page = packed - 200
	elseif packed >= 100 then
		swap = 1
		page = packed - 100
	end
	if page < 1 then
		page = 1
	end
	return page, swap
end

local function RowId(row)
	if row == "sec" or row == 2 then
		return 2
	end
	if row == "tert" or row == 3 then
		return 3
	end
	return 1
end

--- column 1-19, row "main"|"sec"|"tert" or 1|2|3, page 1-18, swap 0|1|2
-- opts.promoted: 0 none, 1 sec, 2 tert, 3 both
-- opts.hasSec / opts.hasTert: booleans (default false)
function M.Resolve(column, row, page, swap, opts)
	column = tonumber(column) or 1
	page = tonumber(page) or 1
	swap = tonumber(swap) or 0
	if page < 1 then
		page = 1
	end
	opts = opts or {}
	local promoted = tonumber(opts.promoted) or 0
	local hasSec = opts.hasSec and 1 or 0
	local hasTert = opts.hasTert and 1 or 0
	local static = column > 12 and 1 or 0
	local rowId = RowId(row)

	local mainRest, sec, tert
	if static == 1 then
		local off = column - 12
		mainRest = 12 + off
		sec = 48 + off
		tert = 36 + off
	else
		mainRest = (page - 1) * 12 + column
		sec = 60 + column
		tert = 24 + column
	end

	local slot = mainRest
	if static == 0 and page >= 11 then
		if rowId == 2 then slot = sec elseif rowId == 3 then slot = tert end
	elseif rowId == 1 then
		if promoted == 1 then
			slot = sec
		elseif promoted == 2 then
			slot = tert
		elseif promoted == 3 then
			if swap == 0 then
				slot = sec
			else
				slot = tert
			end
		else
			if swap == 1 then
				if hasSec == 1 then
					slot = sec
				elseif hasTert == 1 then
					slot = tert
				else
					slot = mainRest
				end
			elseif swap == 2 then
				if hasTert == 1 then
					slot = tert
				elseif hasSec == 1 then
					slot = sec
				else
					slot = mainRest
				end
			else
				slot = mainRest
			end
		end
	elseif rowId == 2 then
		if promoted == 3 then
			slot = sec
		elseif hasSec == 1 and hasTert == 0 then
			if swap ~= 0 then
				slot = mainRest
			else
				slot = sec
			end
		elseif swap == 1 then
			slot = mainRest
		else
			slot = sec
		end
	else
		if promoted == 3 then
			-- Leftover mini is the tert widget: tert at rest, invert to sec under any modifier.
			if swap == 0 then
				slot = tert
			else
				slot = sec
			end
		elseif hasTert == 1 and hasSec == 0 then
			if swap ~= 0 then
				slot = mainRest
			else
				slot = tert
			end
		elseif swap == 2 then
			slot = mainRest
		else
			slot = tert
		end
	end
	return slot
end

function M.MainSlot(column, page)
	page = tonumber(page) or 0
	column = tonumber(column) or 1
	if column > 12 then
		return 12 + (column - 12)
	end
	if page == 0 then
		return column
	end
	return (page - 1) * 12 + column
end

function M.SecondarySlot(column)
	column = tonumber(column) or 1
	if column <= 12 then
		return 60 + column
	end
	return 48 + (column - 12)
end

function M.TertiarySlot(column)
	column = tonumber(column) or 1
	if column <= 12 then
		return 24 + column
	end
	return 36 + (column - 12)
end

local function Expect(failures, got, want, label)
	if got ~= want then
		failures[#failures + 1] = string.format("%s: got %s want %s", label, tostring(got), tostring(want))
	end
end

function M.SelfTest()
	local failures = {}
	local R = M.Resolve
	Expect(failures, M.MainSlot(1, 0), 1, "main 1 page0")
	Expect(failures, M.MainSlot(1, 7), 73, "cat col1")
	Expect(failures, M.MainSlot(1, 9), 97, "bear col1")
	Expect(failures, M.MainSlot(1, 12), 133, "vehicle col1")
	Expect(failures, M.MainSlot(13, 0), 13, "static 13")
	Expect(failures, M.SecondarySlot(1), 61, "shift 1")
	Expect(failures, M.SecondarySlot(13), 49, "shift 13")
	Expect(failures, M.TertiarySlot(1), 25, "ctrl 1")
	Expect(failures, M.TertiarySlot(13), 37, "ctrl 13")

	Expect(failures, R(1, "main", 1, 0), 1, "rest main 1")
	Expect(failures, R(1, "main", 7, 0), 73, "cat main 1")
	Expect(failures, R(1, "main", 9, 0), 97, "bear main 1")
	Expect(failures, R(1, "main", 12, 0), 133, "vehicle main 1")
	Expect(failures, R(1, "sec", 1, 0), 61, "rest sec 1")
	Expect(failures, R(1, "tert", 1, 0), 25, "rest tert 1")

	local filled = { hasSec = true, hasTert = true }
	Expect(failures, R(1, "main", 7, 1, filled), 61, "shift+cat main stays shift")
	Expect(failures, R(1, "sec", 7, 1, filled), 73, "shift+cat sec shows cat")
	Expect(failures, R(1, "tert", 7, 1, filled), 25, "shift+cat tert stays ctrl")
	Expect(failures, R(1, "main", 7, 2, filled), 25, "ctrl+cat main stays ctrl")
	Expect(failures, R(1, "tert", 7, 2, filled), 73, "ctrl+cat tert shows cat")
	Expect(failures, R(1, "sec", 7, 2, filled), 61, "ctrl+cat sec stays shift")

	Expect(failures, R(13, "main", 1, 0), 13, "static rest main")
	Expect(failures, R(13, "main", 7, 1, filled), 49, "static shift main")
	Expect(failures, R(13, "sec", 7, 1, filled), 13, "static shift sec invert")
	Expect(failures, R(13, "main", 1, 2, filled), 37, "static ctrl main")
	Expect(failures, R(13, "tert", 7, 2, filled), 13, "static ctrl tert invert")

	Expect(failures, R(1, "main", 1, 0, { promoted = 1, hasSec = true }), 61, "promote sec")
	Expect(failures, R(1, "main", 1, 0, { promoted = 2, hasTert = true }), 25, "promote tert")
	Expect(failures, R(1, "main", 1, 0, { promoted = 3, hasSec = true, hasTert = true }), 61, "promote both rest")
	Expect(failures, R(1, "main", 1, 1, { promoted = 3, hasSec = true, hasTert = true }), 25, "promote both shift")
	Expect(failures, R(1, "tert", 1, 0, { promoted = 3, hasSec = true, hasTert = true }), 25, "promote both leftover tert at rest")
	Expect(failures, R(1, "tert", 1, 1, { promoted = 3, hasSec = true, hasTert = true }), 61, "promote both leftover inverts on shift")
	Expect(failures, R(1, "tert", 1, 2, { promoted = 3, hasSec = true, hasTert = true }), 61, "promote both leftover inverts on ctrl")
	Expect(failures, R(1, "sec", 1, 0, { promoted = 3, hasSec = true, hasTert = true }), 61, "promote both parked sec stays sec")

	Expect(failures, R(5, "main", 1, 1, { hasTert = true }), 29, "shift empty-sec falls to tert")
	Expect(failures, R(5, "main", 1, 2, { hasTert = true }), 29, "ctrl empty-sec falls to tert")
	Expect(failures, R(5, "tert", 1, 1, { hasTert = true }), 5, "lone tert inverts on shift")
	Expect(failures, R(5, "tert", 1, 2, { hasTert = true }), 5, "lone tert inverts on ctrl")
	Expect(failures, R(5, "main", 1, 1, { hasSec = true }), 65, "shift empty-tert falls to sec")
	Expect(failures, R(5, "main", 1, 2, { hasSec = true }), 65, "ctrl empty-tert falls to sec")
	Expect(failures, R(5, "sec", 1, 1, { hasSec = true }), 5, "lone sec inverts on shift")
	Expect(failures, R(5, "sec", 1, 2, { hasSec = true }), 5, "lone sec inverts on ctrl")
	Expect(failures, R(5, "main", 8, 1, {}), 89, "shift empty minis stays form")

	Expect(failures, M.Pack(7, 1), 107, "pack shift cat")
	local page, swap = M.Unpack(107)
	Expect(failures, page, 7, "unpack page")
	Expect(failures, swap, 1, "unpack swap")
	return failures
end

if ns and ns.Flux then
	ns.Flux.Bars = ns.Flux.Bars or {}
	ns.Flux.Bars.SlotMath = M
end

return M
