-- Inventory/CreateSpells.lua — known max-rank conjure / create-item spells (food, water, gem, HS).
-- Scan once per real spellbook-shape change; query path is map lookups until Invalidate.
local addonName, ns = ...
local Flux = ns.Flux
local Inv = Flux.Inventory

local Spells = {}
Inv.CreateSpells = Spells

local CREATE_KIND_PATTERNS = {
	{ pattern = "^conjure food", kind = "food" },
	{ pattern = "^conjure water", kind = "water" },
	{ pattern = "^conjure refreshment", kind = "refreshment" },
	{ pattern = "^ritual of refreshment", kind = "refreshment" },
	{ pattern = "create.*healthstone", kind = "healthstone" },
	{ pattern = "^conjure mana gem", kind = "managem" },
	{ pattern = "^conjure mana sapphire", kind = "managem" },
	{ pattern = "^conjure mana emerald", kind = "managem" },
	{ pattern = "^conjure mana ruby", kind = "managem" },
	{ pattern = "^conjure mana citrine", kind = "managem" },
	{ pattern = "^conjure mana jade", kind = "managem" },
	{ pattern = "^conjure mana agate", kind = "managem" },
}

local RANK_SUFFIX = "%s*%(%s*[Rr]ank%s*%d+%s*%)%s*$"

local createItemSpells = {}
local createBySpell = {}
local createByKind = {}
local knownCache = {}
local knownByLowerName = {}
local preferredByKind = {}
local nameKnownCache = {}
local boolCache = {}
local emptyList = {}
local dirty = true
local wipe = wipe or function(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

local function SpellName(spellID)
	spellID = tonumber(spellID)
	if not spellID then
		return nil
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		if type(info) == "table" and info.name then
			return info.name
		end
	end
	if GetSpellInfo then
		return GetSpellInfo(spellID)
	end
	return nil
end

local function StripRankLower(name)
	if type(name) ~= "string" then
		return nil
	end
	return name:lower():gsub(RANK_SUFFIX, "")
end

local function RankFromSubtextAndName(spellID, name)
	spellID = tonumber(spellID) or 0
	local subtext
	if C_Spell and C_Spell.GetSpellSubtext then
		subtext = C_Spell.GetSpellSubtext(spellID)
	elseif GetSpellSubtext then
		subtext = GetSpellSubtext(spellID)
	end
	if type(subtext) == "string" and subtext ~= "" then
		local rankNum = tonumber(subtext:match("[Rr]ank%s*(%d+)"))
		if rankNum then
			return rankNum * 1000000 + spellID
		end
	end
	if type(name) == "string" then
		local rankNum = tonumber(name:match("%(%s*[Rr]ank%s*(%d+)%s*%)"))
		if rankNum then
			return rankNum * 1000000 + spellID
		end
	end
	return spellID
end

local function KindForName(name)
	local lower = StripRankLower(name)
	if not lower then
		return nil
	end
	for i = 1, #CREATE_KIND_PATTERNS do
		local rec = CREATE_KIND_PATTERNS[i]
		if lower:find(rec.pattern) then
			return rec.kind
		end
	end
	return nil
end

local function IndexKnownName(spellID, name, rankScore)
	local rec = { spellID = spellID, rankScore = rankScore, name = name }
	local exact = name:lower()
	local base = exact:gsub(RANK_SUFFIX, "")
	local prev = knownByLowerName[base]
	if not prev or rankScore > prev.rankScore then
		knownByLowerName[base] = rec
	end
	if exact ~= base then
		local prevExact = knownByLowerName[exact]
		if not prevExact or rankScore > prevExact.rankScore then
			knownByLowerName[exact] = rec
		end
	end
end

local function ConsiderSpell(spellID, name)
	spellID = tonumber(spellID)
	if not spellID or not name then
		return
	end
	knownCache[spellID] = true
	local rankScore = RankFromSubtextAndName(spellID, name)
	IndexKnownName(spellID, name, rankScore)
	local kind = KindForName(name)
	if not kind or createBySpell[spellID] then
		return
	end
	local entry = { spellID = spellID, name = name, kind = kind, rankScore = rankScore }
	createBySpell[spellID] = entry
	createItemSpells[#createItemSpells + 1] = entry
	local list = createByKind[kind]
	if not list then
		list = {}
		createByKind[kind] = list
	end
	list[#list + 1] = entry
end

local function WipeQueryCaches()
	wipe(preferredByKind)
	wipe(nameKnownCache)
	wipe(boolCache)
end

local function ScanSpellbook()
	wipe(createItemSpells)
	wipe(createBySpell)
	wipe(createByKind)
	wipe(knownCache)
	wipe(knownByLowerName)
	WipeQueryCaches()
	if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo then
		local num = C_SpellBook.GetNumSpellBookSkillLines() or 0
		local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
		for i = 1, num do
			local line = C_SpellBook.GetSpellBookSkillLineInfo(i)
			if line and line.itemIndexOffset and line.numSpellBookItems then
				for slot = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
					local info = C_SpellBook.GetSpellBookItemInfo and C_SpellBook.GetSpellBookItemInfo(slot, bank)
					if info and info.spellID then
						ConsiderSpell(info.spellID, info.name or SpellName(info.spellID))
					end
				end
			end
		end
	elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
		local tabs = GetNumSpellTabs() or 0
		for t = 1, tabs do
			local _, _, offset, numSpells = GetSpellTabInfo(t)
			offset = offset or 0
			numSpells = numSpells or 0
			for slot = offset + 1, offset + numSpells do
				local name, _, spellID = GetSpellBookItemName(slot, BOOKTYPE_SPELL or "spell")
				ConsiderSpell(spellID, name)
			end
		end
	end
	dirty = false
end

function Spells.Refresh()
	if dirty then
		ScanSpellbook()
		return true
	end
	return false
end

function Spells.Invalidate()
	dirty = true
	WipeQueryCaches()
end

function Spells.IsKnown(spellID)
	spellID = tonumber(spellID)
	if not spellID then
		return false
	end
	Spells.Refresh()
	return knownCache[spellID] == true
end

function Spells.IsKnownByName(name)
	if type(name) ~= "string" or name == "" then
		return false
	end
	Spells.Refresh()
	local lower = name:lower()
	local cached = nameKnownCache[lower]
	if cached ~= nil then
		if cached then
			return true, cached
		end
		return false
	end
	local rec = knownByLowerName[lower] or knownByLowerName[lower:gsub(RANK_SUFFIX, "")]
	if rec then
		nameKnownCache[lower] = rec.spellID
		return true, rec.spellID
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local ok, info = pcall(C_Spell.GetSpellInfo, name)
		if ok and type(info) == "table" and info.spellID then
			if knownCache[info.spellID] then
				nameKnownCache[lower] = info.spellID
				return true, info.spellID
			end
			if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
				local okKnown, known = pcall(C_SpellBook.IsSpellInSpellBook, info.spellID)
				if okKnown and known then
					nameKnownCache[lower] = info.spellID
					return true, info.spellID
				end
			end
		end
	end
	nameKnownCache[lower] = false
	return false
end

function Spells.GetCreateItemSpells(kindFilter)
	Spells.Refresh()
	if not kindFilter then
		return createItemSpells
	end
	return createByKind[kindFilter] or emptyList
end

function Spells.GetPreferredCreateSpell(kind)
	Spells.Refresh()
	local cached = preferredByKind[kind]
	if cached then
		return cached.spellID, cached.name
	end
	if cached == false then
		return nil, nil
	end
	local list = createByKind[kind]
	local bestID, bestName, bestRank = nil, nil, -1
	if list then
		for i = 1, #list do
			local entry = list[i]
			local spellID = entry.spellID
			if spellID and knownCache[spellID] then
				local name = entry.name or SpellName(spellID)
				local rank = entry.rankScore or spellID
				if kind == "refreshment" and name and name:lower():find("ritual", 1, true) then
					rank = -1
				end
				if rank > bestRank then
					bestRank = rank
					bestID = spellID
					bestName = name
				end
			end
		end
	end
	if bestID then
		preferredByKind[kind] = { spellID = bestID, name = bestName }
	else
		preferredByKind[kind] = false
	end
	return bestID, bestName
end

function Spells.HasCreateKind(kind)
	local spellID = Spells.GetPreferredCreateSpell(kind)
	return spellID ~= nil, spellID
end

--- Create-item kind for a known conjure/create spell, or nil.
function Spells.GetKindForSpell(spellID)
	spellID = tonumber(spellID)
	if not spellID then
		return nil
	end
	Spells.Refresh()
	local entry = createBySpell[spellID]
	if entry and entry.kind then
		return entry.kind
	end
	local name = SpellName(spellID)
	return KindForName(name)
end

local function ResolveKnownConjure(englishName)
	local known, spellID = Spells.IsKnownByName(englishName)
	if known then
		return SpellName(spellID) or englishName, spellID
	end
	return nil, nil
end

function Spells.GetPreferredGroupConjureSpell()
	local spellID, name = Spells.GetPreferredCreateSpell("refreshment")
	if spellID then
		return name or SpellName(spellID), spellID
	end
	return ResolveKnownConjure("Conjure Refreshment")
end

function Spells.GetPreferredFoodConjureSpell()
	local spellID, name = Spells.GetPreferredCreateSpell("food")
	if spellID then
		return name or SpellName(spellID), spellID
	end
	local foodName, foodID = ResolveKnownConjure("Conjure Food")
	if foodName or foodID then
		return foodName, foodID
	end
	return Spells.GetPreferredGroupConjureSpell()
end

function Spells.GetPreferredWaterConjureSpell()
	local spellID, name = Spells.GetPreferredCreateSpell("water")
	if spellID then
		return name or SpellName(spellID), spellID
	end
	local waterName, waterID = ResolveKnownConjure("Conjure Water")
	if waterName or waterID then
		return waterName, waterID
	end
	return Spells.GetPreferredGroupConjureSpell()
end

function Spells.GetSecondaryFoodConjureSpell()
	local ritualName, ritualID = ResolveKnownConjure("Ritual of Refreshment")
	if ritualName or ritualID then
		return ritualName, ritualID
	end
	local primary = Spells.GetPreferredFoodConjureSpell()
	local primaryLower = type(primary) == "string" and primary:lower() or ""
	if primaryLower:find("food", 1, true) and not primaryLower:find("refreshment", 1, true) then
		return Spells.GetPreferredGroupConjureSpell()
	end
	if primaryLower:find("refreshment", 1, true) then
		return ResolveKnownConjure("Conjure Food")
	end
	return nil, nil
end

function Spells.GetSecondaryWaterConjureSpell()
	local ritualName, ritualID = ResolveKnownConjure("Ritual of Refreshment")
	if ritualName or ritualID then
		return ritualName, ritualID
	end
	local primary = Spells.GetPreferredWaterConjureSpell()
	local primaryLower = type(primary) == "string" and primary:lower() or ""
	if primaryLower:find("water", 1, true) and not primaryLower:find("refreshment", 1, true) then
		return Spells.GetPreferredGroupConjureSpell()
	end
	if primaryLower:find("refreshment", 1, true) then
		return ResolveKnownConjure("Conjure Water")
	end
	return nil, nil
end

function Spells.HasConjureFood()
	Spells.Refresh()
	if boolCache.food ~= nil then
		return boolCache.food
	end
	boolCache.food = Spells.IsKnownByName("Conjure Food") and true or false
	return boolCache.food
end

function Spells.HasConjureWater()
	Spells.Refresh()
	if boolCache.water ~= nil then
		return boolCache.water
	end
	boolCache.water = Spells.IsKnownByName("Conjure Water") and true or false
	return boolCache.water
end

function Spells.HasConjureRefreshment()
	Spells.Refresh()
	if boolCache.refreshment ~= nil then
		return boolCache.refreshment
	end
	boolCache.refreshment = Spells.IsKnownByName("Conjure Refreshment") and true or false
	return boolCache.refreshment
end

function Spells.HasRitualOfRefreshment()
	Spells.Refresh()
	if boolCache.ritual ~= nil then
		return boolCache.ritual
	end
	boolCache.ritual = Spells.IsKnownByName("Ritual of Refreshment") and true or false
	return boolCache.ritual
end

function Spells.HasAnyConjureSpell()
	Spells.Refresh()
	if boolCache.any ~= nil then
		return boolCache.any
	end
	boolCache.any = Spells.HasConjureFood()
		or Spells.HasConjureWater()
		or Spells.HasConjureRefreshment()
		or Spells.HasRitualOfRefreshment()
		or Spells.HasCreateKind("food")
		or Spells.HasCreateKind("water")
		or Spells.HasCreateKind("refreshment")
		or false
	return boolCache.any
end

local FluxInv = _G.FluxInv or {}
_G.FluxInv = FluxInv
FluxInv.Spells = Spells

do
	local pewDone = false
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnEvent", function(self)
		if pewDone then
			return
		end
		pewDone = true
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		Spells.Invalidate()
		if Spells.ScheduleWarm then
			Spells.ScheduleWarm()
		end
	end)
	local SpellBook = Flux and Flux.SpellBook
	if SpellBook and SpellBook.OnChanged then
		SpellBook.OnChanged("inventory.createspells", Spells.Invalidate)
	else
		f:RegisterEvent("SPELLS_CHANGED")
		f:SetScript("OnEvent", function(self, event)
			if event == "PLAYER_ENTERING_WORLD" then
				if pewDone then
					return
				end
				pewDone = true
				self:UnregisterEvent("PLAYER_ENTERING_WORLD")
			end
			Spells.Invalidate()
			if Spells.ScheduleWarm then
				Spells.ScheduleWarm()
			end
		end)
	end
end

return Spells
