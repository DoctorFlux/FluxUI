-- Bars/State.lua — numeric page driver + restricted slot math (no 90-attr bake).
-- Six headers (main/sec/tert × dynamic 1-12 and static 13-19) plus one mod hub.
--
-- Two independent axes:
--   native page — form / stealth / vehicle / override / bar page. Needs a secure
--     evaluator, so it stays on RegisterStateDriver + _onstate-native and the
--     restricted ChildUpdate below.
--   modifier swap - SHIFT / CTRL main/mini selection follows the secure hub.
--     The main child publishes its current action/program to its keyboard
--     proxy. Bound click dispatch can consume modifier globals, so keys do not
--     reconstruct the row at that point. The same live state drives the face.
--     Mouse clicks retain all eight prepared modified-attribute sets through
--     SecureButton_GetModifiedAttribute; those do not wait for display updates.
--     The hub/ChildUpdate also keeps the visible native action synchronized,
--     with read-only display indexing handling delayed callbacks.
local addonName, ns = ...

-- Keep the Forever compatibility fallback local to Flux-owned frames.
local FluxDrivers = ((ns and ns.Flux) or _G.Flux or {}).Restricted
local useFluxDrivers = FluxDrivers and FluxDrivers.Works and not FluxDrivers.Works()
local RegisterStateDriver = (useFluxDrivers and FluxDrivers.RegisterStateDriver) or RegisterStateDriver
local UnregisterStateDriver = (useFluxDrivers and FluxDrivers.UnregisterStateDriver) or UnregisterStateDriver
local Flux = ns.Flux

local Bars = Flux.Bars
local State = {}
Bars.State = State

local NATIVE = 12
local CLICK_PREFIXES = { "", "alt-", "ctrl-", "alt-ctrl-", "shift-", "alt-shift-", "ctrl-shift-", "alt-ctrl-shift-" }
local SlotMath = Bars.SlotMath
local CAB = C_ActionBar or {}
local HasVehicleActionBar = CAB.HasVehicleActionBar or _G.HasVehicleActionBar
local HasOverrideActionBar = CAB.HasOverrideActionBar or _G.HasOverrideActionBar
local HasTempShapeshiftActionBar = CAB.HasTempShapeshiftActionBar or _G.HasTempShapeshiftActionBar
local HasBonusActionBar = CAB.HasBonusActionBar or _G.HasBonusActionBar
local GetVehicleBarIndex = CAB.GetVehicleBarIndex or _G.GetVehicleBarIndex
local GetOverrideBarIndex = CAB.GetOverrideBarIndex or _G.GetOverrideBarIndex
local GetTempShapeshiftBarIndex = CAB.GetTempShapeshiftBarIndex or _G.GetTempShapeshiftBarIndex
local GetBonusBarIndex = CAB.GetBonusBarIndex or _G.GetBonusBarIndex

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function SnippetsWork()
	local Restricted = Flux.Restricted
	if Restricted and Restricted.PagingWorks then return Restricted.PagingWorks() end
	if Restricted and Restricted.Works then
		return Restricted.Works()
	end
	local Cap = Flux.Cap
	if Cap and Cap.hasRestrictedClosures == false then
		return false
	end
	return true
end
State.UsesSecurePaging = SnippetsWork

local function SetSnippet(frame, name, body)
	local Restricted = Flux.Restricted
	if Restricted and Restricted.SetPagingSnippet then
		return Restricted.SetPagingSnippet(frame, name, body)
	end
	if Restricted and Restricted.SetSnippet then
		return Restricted.SetSnippet(frame, name, body)
	end
	if not SnippetsWork() then
		return false
	end
	if frame and frame.SetAttribute then
		frame:SetAttribute(name, body)
		return true
	end
	return false
end

function State.GetSecondarySlot(i)
	return SlotMath.SecondarySlot(i)
end

function State.GetTertiarySlot(i)
	return SlotMath.TertiarySlot(i)
end

function State.GetMainSlot(i, page)
	return SlotMath.MainSlot(i, page)
end

function State.ResolveSlot(column, row, page, swap, opts)
	return SlotMath.Resolve(column, row, page, swap, opts)
end

local function ResolvePossessPage()
	local page
	if HasVehicleActionBar and HasVehicleActionBar() then
		page = GetVehicleBarIndex and GetVehicleBarIndex()
	elseif HasOverrideActionBar and HasOverrideActionBar() then
		page = GetOverrideBarIndex and GetOverrideBarIndex()
	elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
		page = GetTempShapeshiftBarIndex and GetTempShapeshiftBarIndex()
	elseif HasBonusActionBar and HasBonusActionBar() then
		page = GetBonusBarIndex and GetBonusBarIndex()
	end
	page = tonumber(page)
	if not page or page < 1 then
		-- Match RESOLVE_PAGE when a possess/shapeshift token has no index API.
		return 11
	end
	return page
end

function State.GetCurrentPage()
	local headers = State.headers
	local native = headers and headers.main and headers.main:GetAttribute("state-native")
	if native == "possess" or native == "dragon" or native == "shapeshift" then
		return ResolvePossessPage()
	end
	local page = headers and headers.main and tonumber(headers.main:GetAttribute("actionpage"))
	if not page or page < 1 then
		page = tonumber(native)
	end
	if not page or page < 1 then
		if (HasVehicleActionBar and HasVehicleActionBar())
			or (HasOverrideActionBar and HasOverrideActionBar()) then
			return ResolvePossessPage()
		end
		return 1
	end
	return page
end

function State.GetMinirowPosition()
	local fo = _G.FluxOptions
	if fo and fo.GetActionbarsDB then
		local t = fo:GetActionbarsDB()
		if t and t.minirowPosition == "bottom" then
			return "bottom"
		end
	end
	return "top"
end

-- ---------------------------------------------------------------------------
-- Native driver: numeric pages (Ellesmere), class maps from backup Flux
-- ---------------------------------------------------------------------------

local function PlayerClass()
	local _, class = UnitClass("player")
	return class
end

local function StanceMap()
	local class = PlayerClass()
	local postDF = Flux.Client and Flux.Client.isPostDF
	local maps
	if postDF then
		maps = {
			DRUID = {
				{ id = "bear", name = "Bear Form", index = 3, state = 9 },
				{ id = "cat", name = "Cat Form", index = 1, state = 7 },
				{ id = "prowl", name = "Cat Form (Prowl)", index = false, state = 8, virtual = true },
				{ id = "moonkin", name = "Moonkin Form", index = 4, state = 0 },
			},
			ROGUE = {
				{ id = "stealth", name = "Stealth", index = 1, state = 7 },
			},
			EVOKER = {
				{ id = "soar", name = "Soar", index = 1, state = 7 },
			},
		}
	else
		maps = {
			DRUID = {
				{ id = "bear", name = "Bear Form", index = 3, state = 9 },
				{ id = "cat", name = "Cat Form", index = 1, state = 7 },
				{ id = "prowl", name = "Cat Form (Prowl)", index = false, state = 8, virtual = true },
				{ id = "moonkin", name = "Moonkin Form", index = 4, state = 0 },
				{ id = "treeoflife", name = "Tree of Life", index = 2, state = 0 },
			},
			ROGUE = {
				{ id = "stealth", name = "Stealth", index = 1, state = 7 },
				{ id = "shadowdance", name = "Shadow Dance", index = 2, state = 8 },
			},
			WARRIOR = {
				{ id = "battle", name = "Battle Stance", index = 1, state = 7 },
				{ id = "def", name = "Defensive Stance", index = 2, state = 8 },
				{ id = "berserker", name = "Berserker Stance", index = 3, state = 9 },
			},
			PRIEST = {
				{ id = "shadowform", name = "Shadowform", index = 1, state = 7 },
			},
			MONK = {
				{ id = "tiger", name = "Stance of the Fierce Tiger", index = 1, state = 7 },
				{ id = "ox", name = "Stance of the Sturdy Ox", index = 2, state = 8 },
				{ id = "serpent", name = "Stance of the Wise Serpent", index = 3, state = 9 },
			},
		}
	end
	return maps[class]
end

function State.BuildNativeDriver()
	local parts = {}
	-- Ellesmere: distinct numeric clauses so vehicle/override/possess exit
	-- changes the driver result in combat. Get*BarIndex() are stable bar IDs
	-- (usually 14 / 12), not "are we in a vehicle". Do not lump those states
	-- into one possess token — _onstate-native only runs when the result
	-- string changes, and a leftover possess token left SHIFT/CTRL on page 12.
	local overrideIndex = (GetOverrideBarIndex and GetOverrideBarIndex()) or 14
	local vehicleIndex = (GetVehicleBarIndex and GetVehicleBarIndex()) or 12
	overrideIndex = tonumber(overrideIndex) or 14
	vehicleIndex = tonumber(vehicleIndex) or 12
	if overrideIndex < 1 then
		overrideIndex = 14
	end
	if vehicleIndex < 1 then
		vehicleIndex = 12
	end
	local C = Flux.Client
	if not (C and (C.isCamelot or C.isForever)) then
		parts[#parts + 1] = "[overridebar] " .. overrideIndex
		parts[#parts + 1] = "[vehicleui] " .. vehicleIndex
		parts[#parts + 1] = "[possessbar]possess"
		parts[#parts + 1] = "[shapeshift]shapeshift"
	end
	-- Legacy Mind Control / Chess uses bonus page 5 (action slots 121-132).
	-- Forever rejects the modern macro options despite exposing their APIs.
	parts[#parts + 1] = "[bonusbar:5] 11"

	local maxPage = NUM_ACTIONBAR_PAGES or 6
	if maxPage > 18 then
		maxPage = 18
	end
	for i = 2, maxPage do
		parts[#parts + 1] = "[bar:" .. i .. "] " .. i
	end

	local stances = StanceMap()
	if stances then
		local byId = {}
		for i = 1, #stances do
			byId[stances[i].id] = stances[i]
		end
		for i = 1, #stances do
			local stance = stances[i]
			if stance.state and stance.state ~= 0 and stance.index then
				if PlayerClass() == "DRUID" and stance.id == "cat" then
					local prowl = byId.prowl
					if prowl and prowl.state and prowl.state ~= 0 then
						parts[#parts + 1] = string.format("[bonusbar:%d,stealth:1] %d", stance.index, prowl.state)
					end
				end
				parts[#parts + 1] = string.format("[bonusbar:%d] %d", stance.index, stance.state)
			end
		end
	end

	parts[#parts + 1] = "1"
	return table.concat(parts, "; ")
end

-- Clears the applied-slot stamps CHILDUPDATE uses to skip an unchanged surface,
-- plus its cached minirow occupancy probe.
local CHILDRESET = [[
	if message ~= 0 then
		self:SetAttribute("flux-applied", nil)
		self:SetAttribute("flux-applied-mods", nil)
	end
	self:SetAttribute("flux-live-sec", nil)
	self:SetAttribute("flux-live-tert", nil)
]]

-- Keep in sync with SlotMath.Resolve. Restricted env: no nested functions.
-- IsPressHoldReleaseSpell / HasAction / GetActionInfo all exist there.
--
-- Click-time paging. Blizzard_FrameXML/SecureTemplates.lua documents the
-- modified-attribute form as "modifier-name-button", where "*" wildcards either
-- half and "Setting the attribute by itself is equivalent to *attribute*".
-- So bare "action" matches every modifier -- which is why it used to swallow
-- SHIFT presses -- and bare "shift-action" is not a form the game ever reads.
-- The documented spelling is "shift-action*".
--
-- Hence three explicit sets, each with the "*" button wildcard so one write
-- covers keys plus left/right/middle click (a strip key arrives as LeftButton,
-- suffix "1", because that is what the KeyBind wrap remaps it to):
--   action*       / type* / typerelease* / macrotext* / clickbutton*  -> nomod
--   shift-action* / shift-type* / ...                                 -> SHIFT
--   ctrl-action*  / ctrl-type*  / ...                                 -> CTRL
-- Blizzard picks between them from the live modifier state at press time, so a
-- press never waits on this snippet, the [mod:] state driver, or the mod hub.
-- That is the whole point: insecure Lua cannot SetAttribute a protected frame in
-- combat (ADDON_ACTION_BLOCKED), so on clients without restricted closures
-- nothing can restamp mid fight and these sets have to be pre-baked.
--
-- The bare action / type / macrotext / clickbutton attributes stay the *live*
-- face for the display side (host.slot, paint, tooltips, drag). They no longer
-- decide what a click casts, so a stale one cannot fire the wrong spell.
local CHILDUPDATE = [[
	local packed = tonumber(message)
	if not packed then packed = 1 end
	-- Only the out-of-combat hover broadcast uses a negative state message.
	-- Keep the published state identical to the native positive page/swap value.
	local hover = packed < 0
	if hover then packed = -packed end
	local swap = 0
	local page = packed
	if packed >= 200 then
		swap = 2
		page = packed - 200
	elseif packed >= 100 then
		swap = 1
		page = packed - 100
	end
	if page < 1 then page = 1 end

	local col = tonumber(self:GetAttribute("flux-column"))
	if not col then return end
	local row = tonumber(self:GetAttribute("flux-row")) or 1
	local static = tonumber(self:GetAttribute("flux-static")) or 0
	local promoted = tonumber(self:GetAttribute("flux-promoted")) or 0
	local hasSec = tonumber(self:GetAttribute("flux-has-sec")) or 0
	local hasTert = tonumber(self:GetAttribute("flux-has-tert")) or 0

	local mainRest
	local sec
	local tert
	if static == 1 then
		local off = col - 12
		mainRest = 12 + off
		sec = 48 + off
		tert = 36 + off
	else
		-- Match SlotMath: fixed columns own slots 13–19 on page two.
		if page == 2 and col <= 7 then
			mainRest = col
		else
			mainRest = (page - 1) * 12 + col
		end
		sec = 60 + col
		tert = 24 + col
	end

	-- Layout.ApplyMappings cannot stamp occupancy while structural work is
	-- locked down, so a fight entered before the first stamp left hasSec 0 and
	-- SHIFT never left the main row for the whole fight. Read it live instead.
	-- Normal modifier edges keep the slot-changed cache. A pure hover
	-- resamples inside this same child update, including an action change
	-- whose slot event has not arrived yet.
	local oldSec = self:GetAttribute("flux-live-sec")
	local oldTert = self:GetAttribute("flux-live-tert")
	local liveSec, liveTert = tonumber(oldSec), tonumber(oldTert)
	if hover or (not liveSec and HasAction) then
		liveSec, liveTert = nil, nil
		if HasAction then
			if HasAction(sec) then liveSec = 1 else liveSec = 0 end
			if HasAction(tert) then liveTert = 1 else liveTert = 0 end
		end
		if oldSec ~= liveSec then self:SetAttribute("flux-live-sec", liveSec) end
		if oldTert ~= liveTert then self:SetAttribute("flux-live-tert", liveTert) end
	end
	-- Drag-expand already forces the flags to 1, so this only promotes 0 to 1.
	if liveSec == 1 then hasSec = 1 end
	if liveTert == 1 then hasTert = 1 end

	-- Nomod / SHIFT / CTRL slots, all three resolved every pass so the
	-- prefixed twins below can be stamped without a second slot walk.
	local slotNomod, slotShift, slotCtrl
	for sw = 0, 2 do
		local slot = mainRest
		if static == 0 and page >= 11 then
			if row == 2 then slot = sec elseif row == 3 then slot = tert end
		elseif row == 1 then
			if promoted == 1 then
				slot = sec
			elseif promoted == 2 then
				slot = tert
			elseif promoted == 3 then
				if sw == 0 then slot = sec else slot = tert end
			else
				if sw == 1 then
					if hasSec == 1 then
						slot = sec
					elseif hasTert == 1 then
						slot = tert
					else
						slot = mainRest
					end
				elseif sw == 2 then
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
		elseif row == 2 then
			if promoted == 3 then
				slot = sec
			elseif hasSec == 1 and hasTert == 0 then
				if sw ~= 0 then slot = mainRest else slot = sec end
			elseif sw == 1 then
				slot = mainRest
			else
				slot = sec
			end
		else
			if promoted == 3 then
				if sw == 0 then slot = tert else slot = sec end
			elseif hasTert == 1 and hasSec == 0 then
				if sw ~= 0 then slot = mainRest else slot = tert end
			elseif sw == 2 then
				slot = mainRest
			else
				slot = tert
			end
		end
		if sw == 0 then
			slotNomod = slot
		elseif sw == 1 then
			slotShift = slot
		else
			slotCtrl = slot
		end
	end
	local slot = slotNomod
	if swap == 1 then
		slot = slotShift
	elseif swap == 2 then
		slot = slotCtrl
	end

	local sameState = hover and self:GetAttribute("state") == packed
	if not sameState then self:SetAttribute("state", packed) end

	-- Three slot choices cover all eight native modifier prefixes. Native
	-- modified-attribute lookup does not partially match "shift-" when Alt or
	-- Ctrl is also held, so every combination needs its own prepared selectors.
	-- These are what a press actually resolves, and they
	-- only move when the native page, promotion or occupancy moves -- never on a
	-- modifier edge, where nomod/sec/tert are all already correct. Guarding them
	-- separately keeps holding SHIFT at the old cost while a form flip still
	-- repoints all three. flux-applied-mods is cleared by _childupdate-fluxreset
	-- before a ForceApply and by the slot-changed flush.
	local mods = slotNomod * 1000000 + slotShift * 1000 + slotCtrl
	local oldMods = tonumber(self:GetAttribute("flux-applied-mods"))
	if oldMods ~= mods then
		self:SetAttribute("flux-applied-mods", mods)
		local updateNomod, updateShift, updateCtrl = true, true, true
		if sameState and oldMods then
			-- Unchanged lanes keep their prepared aliases during a hover.
			-- A real edit clears oldMods and gets all aliases refreshed.
			updateCtrl = oldMods % 1000 ~= slotCtrl
			updateShift = math.floor(oldMods / 1000) % 1000 ~= slotShift
			updateNomod = math.floor(oldMods / 1000000) ~= slotNomod
		end
		local typeNomod, textNomod, clickNomod, empowerNomod
		local typeShift, textShift, clickShift, empowerShift
		local typeCtrl, textCtrl, clickCtrl, empowerCtrl
		-- Resolve programs and spell capability once per slot choice, before
		-- fanning out aliases. A compound prefix adds no native spell probes.
		for sw = 0, 2 do
			if (sw == 0 and updateNomod) or (sw == 1 and updateShift) or (sw == 2 and updateCtrl) then
				local s = slotNomod
				if sw == 1 then s = slotShift elseif sw == 2 then s = slotCtrl end
				local body = self:GetAttribute("flux-p-" .. s)
				local clicker = self:GetAttribute("flux-click-" .. s)
				local mode = self:GetAttribute("flux-m-" .. s)
				if static == 0 and page >= 11 and row == 1 then body, clicker = nil, nil end
				local typ = "action"
				if clicker then
					typ, body = "click", nil
				elseif body and body ~= "" and mode ~= "d" then
					typ = "macro"
				else
					body = nil
				end
				local empower = false
				if IsPressHoldReleaseSpell then
					local aType, id, subType = GetActionInfo(s)
					local spellID = nil
					if aType == "spell" then
						spellID = id
					elseif aType == "macro" and subType == "spell" then
						spellID = id
					end
					if spellID and IsPressHoldReleaseSpell(spellID) then
						empower = true
					end
				end
				if sw == 0 then
					typeNomod, textNomod, clickNomod, empowerNomod = typ, body, clicker, empower
				elseif sw == 1 then
					typeShift, textShift, clickShift, empowerShift = typ, body, clicker, empower
				else
					typeCtrl, textCtrl, clickCtrl, empowerCtrl = typ, body, clicker, empower
				end
			end
		end
		for i = 1, 8 do
			local pfx, s, typ, body, clicker, empower
			local update
			if i <= 2 then
				update = updateNomod
				pfx = ""
				if i == 2 then pfx = "alt-" end
				s, typ, body, clicker, empower = slotNomod, typeNomod, textNomod, clickNomod, empowerNomod
			elseif i <= 4 then
				update = updateCtrl
				pfx = "ctrl-"
				if i == 4 then pfx = "alt-ctrl-" end
				s, typ, body, clicker, empower = slotCtrl, typeCtrl, textCtrl, clickCtrl, empowerCtrl
			else
				update = updateShift
				pfx = "shift-"
				if i == 6 then pfx = "alt-shift-"
				elseif i == 7 then pfx = "ctrl-shift-"
				elseif i == 8 then pfx = "alt-ctrl-shift-" end
				s, typ, body, clicker, empower = slotShift, typeShift, textShift, clickShift, empowerShift
			end
			if update then
				self:SetAttribute(pfx .. "action*", s)
				self:SetAttribute(pfx .. "type*", typ)
				self:SetAttribute(pfx .. "typerelease*", typ)
				self:SetAttribute(pfx .. "clickbutton*", clicker)
				self:SetAttribute(pfx .. "macrotext*", body)
				if IsPressHoldReleaseSpell then
					self:SetAttribute(pfx .. "IsEmpowerSpell*", empower)
				end
			end
		end
	end

	-- A modifier edge ChildUpdates all 57 surfaces, but most land on the slot
	-- they already show: static columns never page, and a mini only moves on
	-- its own swap. Re-stamping action / type / macrotext / empower for an
	-- unchanged slot was ~7 restricted writes per button for no change.
	-- flux-applied is cleared by _childupdate-fluxreset before a ForceApply and
	-- by the slot-changed flush, so a real edit still gets the full pass.
	local applied = tonumber(self:GetAttribute("flux-applied"))
	if applied == slot then
		return
	end
	self:SetAttribute("flux-applied", slot)

	self:SetAttribute("action", slot)
	-- Surface overlay: ephemeral macrotext on this host. Hidden overlay: type=click
	-- onto a pre-stamped flux-click-<slot> frame reference.
	local body = slot and self:GetAttribute("flux-p-" .. slot)
	local clicker = slot and self:GetAttribute("flux-click-" .. slot)
	local mode = slot and self:GetAttribute("flux-m-" .. slot)
	if static == 0 and page >= 11 and row == 1 then body, clicker = nil, nil end
	self:SetAttribute("unit", nil)
	if clicker then
		self:SetAttribute("macrotext", nil)
		self:SetAttribute("macro", nil)
		self:SetAttribute("type", "click")
		self:SetAttribute("typerelease", "click")
		self:SetAttribute("clickbutton", clicker)
	elseif body and body ~= "" and mode ~= "d" then
		self:SetAttribute("type", "macro")
		self:SetAttribute("typerelease", "macro")
		self:SetAttribute("clickbutton", nil)
		self:SetAttribute("macro", nil)
		self:SetAttribute("macrotext", body)
		self:SetAttribute("checkmouseovercast", false)
	else
		self:SetAttribute("macrotext", nil)
		self:SetAttribute("macro", nil)
		self:SetAttribute("type", "action")
		self:SetAttribute("typerelease", "action")
		self:SetAttribute("clickbutton", nil)
	end

	-- Bound-click dispatch can consume its chord modifiers before the native
	-- action handler runs. The main's secure state, already used for its live
	-- face, owns keyboard execution too. Mini children never publish here.
	if row == 1 then
		local keyer = control:GetFrameRef("keyer-" .. col)
		if keyer then
			keyer:SetAttribute("type", self:GetAttribute("type"))
			keyer:SetAttribute("typerelease", self:GetAttribute("typerelease"))
			keyer:SetAttribute("action", slot)
			keyer:SetAttribute("macro", nil)
			keyer:SetAttribute("macrotext", self:GetAttribute("macrotext"))
			keyer:SetAttribute("clickbutton", self:GetAttribute("clickbutton"))
			keyer:SetAttribute("unit", nil)
		end
	end

	-- Preserve v8 Forever's AnyUp mouse path. A hold flag would suppress the
	-- release click, even though paging itself now runs in secure snippets.
	self:SetAttribute("pressAndHoldAction", self:GetAttribute("flux-native-click") ~= 1)
	if slot and IsPressHoldReleaseSpell then
		local actionType, id, subType = GetActionInfo(slot)
		local spellID = nil
		if actionType == "spell" then
			spellID = id
		elseif actionType == "macro" and subType == "spell" then
			spellID = id
		end
		if spellID and IsPressHoldReleaseSpell(spellID) then
			self:SetAttribute("IsEmpowerSpell", true)
		else
			self:SetAttribute("IsEmpowerSpell", false)
		end
	end

	-- Paging changed the slot, so the mouseover-cast unit has to be resolved
	-- against the new spell. Installed by Flux.MouseoverCast.AttachHost.
	if self:GetAttribute("flux-mo-apply") then
		self:RunAttribute("flux-mo-apply")
	end
]]

local function RowId(row)
	if row == "sec" then
		return 2
	end
	if row == "tert" then
		return 3
	end
	return 1
end

--- Lua twin of the CHILDUPDATE click-set block, for create time and fallback
--- when secure snippets are unavailable. Prefixes cover all eight modifier masks.
--- The "*" suffix makes one write cover keys, left, right and middle click:
--- SecureButton_GetButtonSuffix gives "1" for the LeftButton every strip key is
--- remapped to, so bare "shift-action" would never be looked up.
--- IsEmpowerSpell is left to CHILDUPDATE -- the wrap that reads it only exists
--- on clients where snippets work.
local function StampSwapClick(widget, prefix, slot, nativeOnly)
	widget:SetAttribute(prefix .. "action*", slot)
	local body = slot and widget:GetAttribute("flux-p-" .. slot)
	local clicker = slot and widget:GetAttribute("flux-click-" .. slot)
	local mode = slot and widget:GetAttribute("flux-m-" .. slot)
	if nativeOnly then body, clicker = nil, nil end
	-- Every branch writes all four. Leaving one nil falls through to the nomod
	-- attribute, which would fire the nomod macro body under the modifier.
	if clicker then
		widget:SetAttribute(prefix .. "type*", "click")
		widget:SetAttribute(prefix .. "typerelease*", "click")
		widget:SetAttribute(prefix .. "clickbutton*", clicker)
		widget:SetAttribute(prefix .. "macrotext*", nil)
	elseif body and body ~= "" and mode ~= "d" then
		widget:SetAttribute(prefix .. "type*", "macro")
		widget:SetAttribute(prefix .. "typerelease*", "macro")
		widget:SetAttribute(prefix .. "clickbutton*", nil)
		widget:SetAttribute(prefix .. "macrotext*", body)
	else
		widget:SetAttribute(prefix .. "type*", "action")
		widget:SetAttribute(prefix .. "typerelease*", "action")
		widget:SetAttribute(prefix .. "clickbutton*", nil)
		widget:SetAttribute(prefix .. "macrotext*", nil)
	end
end

State.StampSwapClick = StampSwapClick

--- OOC twin of the main child's keyboard publication. Native input may hide
--- held modifiers during its bound click, so the proxy executes the secure
--- main selection rather than repeating modifier resolution in the handler.
function State.SyncMainKeyer(widget, keyer, slot, nativeOnly)
	if not widget or not keyer or InLockdown()
		or tonumber(widget:GetAttribute("flux-row")) ~= 1 then return false end
	local column = tonumber(widget:GetAttribute("flux-column"))
	if not column then return false end
	if not slot then
		local host = Bars.GetMain and Bars.GetMain(column) or widget._fluxHost
		if host and host.widget == widget and State.ResolveCurrentSlot then
			slot = State.ResolveCurrentSlot(host)
		end
		slot = slot or tonumber(widget:GetAttribute("action"))
	end
	if not slot then return false end
	if nativeOnly == nil then
		local header = widget.GetParent and widget:GetParent()
		local page = header and header.GetAttribute and tonumber(header:GetAttribute("actionpage"))
		if not page or page < 1 then page = State.GetCurrentPage() end
		nativeOnly = column <= NATIVE and page >= 11
	end
	local body = widget:GetAttribute("flux-p-" .. slot)
	local clicker = widget:GetAttribute("flux-click-" .. slot)
	local mode = widget:GetAttribute("flux-m-" .. slot)
	if nativeOnly then body, clicker = nil, nil end
	local typ = "action"
	if clicker then
		typ, body = "click", nil
	elseif type(body) == "string" and body ~= "" and mode ~= "d" then
		typ = "macro"
	else
		body = nil
	end
	keyer:SetAttribute("type", typ)
	keyer:SetAttribute("typerelease", typ)
	keyer:SetAttribute("action", slot)
	keyer:SetAttribute("macro", nil)
	keyer:SetAttribute("macrotext", body)
	keyer:SetAttribute("clickbutton", clicker)
	-- Preserve the existing live-parent unit/mouseover policy. The proxy owns
	-- no parked unit token that could suppress a macro for a missing unit.
	keyer:SetAttribute("unit", nil)
	return true
end

--- The fallback keeps the visible host's live display selectors synchronized.
--- Its main row alone also publishes the current keyboard selection.
local LIVE_BUTTON_SELECTORS = { "type1", "typerelease1", "clickbutton1", "macrotext1" }
local function StampLiveClick(widget, slot, nativeOnly)
	if not widget or not slot then
		return
	end
	local body = widget:GetAttribute("flux-p-" .. slot)
	local clicker = widget:GetAttribute("flux-click-" .. slot)
	local mode = widget:GetAttribute("flux-m-" .. slot)
	if nativeOnly then body, clicker = nil, nil end
	local function write(prefix, typ, text, button)
		widget:SetAttribute(prefix .. "type", typ)
		widget:SetAttribute(prefix .. "typerelease", typ)
		widget:SetAttribute(prefix .. "clickbutton", button)
		widget:SetAttribute(prefix .. "macrotext", text)
	end
	-- An old live LeftButton selector wins over the nomod '*' click set after
	-- releasing Shift/Ctrl, before the display driver catches up. Only the
	-- pre-stamped click sets own button-specific routing.
	for _, name in ipairs(LIVE_BUTTON_SELECTORS) do
		if widget:GetAttribute(name) ~= nil then widget:SetAttribute(name, nil) end
	end
	if clicker then
		write("", "click", nil, clicker)
	elseif type(body) == "string" and body ~= "" and mode ~= "d" then
		write("", "macro", body, nil)
		widget:SetAttribute("macro", nil)
		widget:SetAttribute("checkmouseovercast", false)
	else
		write("", "action", nil, nil)
	end
	local column = tonumber(widget:GetAttribute("flux-column"))
	local keyer = column and _G["FluxActionStripKey" .. column]
	if keyer and tonumber(widget:GetAttribute("flux-row")) == 1 then
		State.SyncMainKeyer(widget, keyer, slot, nativeOnly)
	end
end

State.StampLiveClick = StampLiveClick

function State.Attach(header, widget, column, row)
	if not header or not widget then
		return
	end
	if widget.SetParent then
		widget:SetParent(header)
	end
	-- Do not set widget.bar. Mixin UpdateFlyout calls
	-- bar:GetSpellFlyoutDirection(); a Flux header is not an ActionBar and
	-- that nil call taints UseAction. SetID(0)+shift-action* does not need it.
	if not InLockdown() then
		if widget.SetID then
			widget:SetID(0)
		end
		widget:SetAttribute("useparent-actionpage", false)
	end
	widget:SetAttribute("flux-column", column)
	widget:SetAttribute("flux-row", RowId(row))
	widget:SetAttribute("flux-static", column > NATIVE and 1 or 0)
	local C = Flux.Client
	widget:SetAttribute("flux-native-click", C and (C.isCamelot or C.isForever) and 1 or 0)
	widget:SetAttribute("flux-promoted", 0)
	widget:SetAttribute("flux-has-sec", 0)
	widget:SetAttribute("flux-has-tert", 0)
	SetSnippet(widget, "_childupdate-state", CHILDUPDATE)
	SetSnippet(widget, "_childupdate-fluxreset", CHILDRESET)
	widget:SetAttribute("type", "action")
	widget:SetAttribute("typerelease", "action")
	widget:SetAttribute("action", SlotMath.Resolve(column, row, 1, 0, {}))
	StampSwapClick(widget, "", SlotMath.Resolve(column, row, 1, 0, {}))
	StampSwapClick(widget, "shift-", SlotMath.Resolve(column, row, 1, 1, {}))
	StampSwapClick(widget, "ctrl-", SlotMath.Resolve(column, row, 1, 2, {}))
	local MC = Flux.MouseoverCast
	if MC and MC.AttachHost then
		MC.AttachHost(widget)
	end
end

function State.HeaderFor(column, row)
	local headers = State.headers
	if not headers then
		return nil
	end
	local dynamic = column <= NATIVE
	if row == "main" then
		return dynamic and headers.main or headers.staticMain
	end
	if row == "sec" then
		return dynamic and headers.sec or headers.staticSec
	end
	return dynamic and headers.tert or headers.staticTert
end

-- ---------------------------------------------------------------------------
-- Headers: pack page+swap*100, ChildUpdate computes the slot
-- ---------------------------------------------------------------------------

-- Same possess/dragon resolution as backup FluxStateDriver / Bartender StateBar.
-- Restricted env: HasVehicleActionBar / GetVehicleBarIndex are available.
local RESOLVE_PAGE = [[
	local swap = tonumber(self:GetAttribute("state-swap")) or 0
	local native = self:GetAttribute("state-native")
	if stateid == "swap" then
		swap = tonumber(newstate) or 0
	elseif stateid == "native" then
		native = newstate
	end
	local page
	if native == "possess" or native == "dragon" or native == "shapeshift" then
		if HasVehicleActionBar and HasVehicleActionBar() then
			page = GetVehicleBarIndex()
		elseif HasOverrideActionBar and HasOverrideActionBar() then
			page = GetOverrideBarIndex()
		elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
			page = GetTempShapeshiftBarIndex()
		elseif HasBonusActionBar and HasBonusActionBar() then
			page = GetBonusBarIndex()
		end
		page = tonumber(page)
		if not page or page < 1 then page = 11 end
	else
		page = tonumber(native)
		if not page or page < 1 then page = 1 end
	end
]]

-- actionpage is read back by State.GetCurrentPage for the insecure paint path.
-- No shift-/ctrl-actionpage twins: hosts are SetID(0) + useparent-actionpage
-- false, so CalculateAction never reaches the page math and those writes were
-- dead. The modifier axis lives on the hosts' own shift-action* / ctrl-action*.
local PACK_HEAD = RESOLVE_PAGE .. [[
	self:SetAttribute("actionpage", page)
	local packed = page + swap * 100
	self:SetAttribute("state", packed)
]]
local PACK = PACK_HEAD .. [[
	control:ChildUpdate("state", packed)
]]
local HOVER_PACK = PACK_HEAD .. [[
	control:ChildUpdate("state", -packed)
]]

-- SHIFT/CTRL minis keep the current page in their inverse click sets even
-- while their resting face stays on sec/tert. The child guards skip unchanged
-- live-face writes; skipping ChildUpdate here would leave a prepared inverse
-- route on the previous form/page until the modifier driver caught up.
local PACK_MINI = RESOLVE_PAGE .. [[
	self:SetAttribute("actionpage", page)
	local packed = page + swap * 100
	self:SetAttribute("state", packed)
	control:ChildUpdate("state", packed)
]]

-- Drop every child's applied-slot stamp so the restamp below is a full pass.
local FORCE_RESET = [[
	control:ChildUpdate("fluxreset", 1)
]]
local REFRESH_HEAD = [[
	local stateid = "native"
	local newstate = self:GetAttribute("state-native")
]]
local FORCE_HEAD = FORCE_RESET .. REFRESH_HEAD

local STATIC_PACK_HEAD = [[
	local swap = tonumber(newstate)
	if not swap then swap = tonumber(self:GetAttribute("state-page")) or 0 end
	local packed = 1 + swap * 100
	self:SetAttribute("state", packed)
]]
local STATIC_PACK = STATIC_PACK_HEAD .. [[
	control:ChildUpdate("state", packed)
]]
local STATIC_HOVER_PACK = STATIC_PACK_HEAD .. [[
	control:ChildUpdate("state", -packed)
]]

local function MakeHeader(name, parent)
	local header = _G[name] or CreateFrame("Frame", name, parent, "SecureHandlerStateTemplate")
	header:SetSize(1, 1)
	header:Show()
	return header
end

function State.Create()
	if State.headers then
		return State.headers
	end
	local inner = Bars.Strip and Bars.Strip.inner
	if not inner then
		return nil
	end
	local headers = {
		main = MakeHeader("FluxActionStripHeaderMain", inner),
		sec = MakeHeader("FluxActionStripHeaderSec", inner),
		tert = MakeHeader("FluxActionStripHeaderTert", inner),
		staticMain = MakeHeader("FluxActionStripHeaderStaticMain", inner),
		staticSec = MakeHeader("FluxActionStripHeaderStaticSec", inner),
		staticTert = MakeHeader("FluxActionStripHeaderStaticTert", inner),
	}

	local base = (inner.GetFrameLevel and inner:GetFrameLevel()) or 1
	headers.main:SetFrameLevel(base + 1)
	headers.staticMain:SetFrameLevel(base + 1)
	headers.sec:SetFrameLevel(base + 4)
	headers.tert:SetFrameLevel(base + 4)
	headers.staticSec:SetFrameLevel(base + 4)
	headers.staticTert:SetFrameLevel(base + 4)

	State.headers = headers
	return headers
end

function State.RegisterDrivers()
	if InLockdown() then
		return false
	end
	local headers = State.Create()
	if not headers then
		return false
	end
	local complete = true
	local writeSnippet = SetSnippet
	local function SetSnippet(frame, name, body)
		local ok = writeSnippet(frame, name, body)
		if ok == false and SnippetsWork() then complete = false end
		return ok
	end
	local function Drive(header, attr, driver)
		local R = Flux.Restricted
		if R and R.RegisterPagingDriver and R.UnregisterPagingDriver then
			if R.UnregisterPagingDriver(header, attr) == false then complete = false end
			if driver and R.RegisterPagingDriver(header, attr, driver) == false then complete = false end
			return
		end
		if UnregisterStateDriver then
			if not pcall(UnregisterStateDriver, header, attr) then complete = false end
		end
		if driver and RegisterStateDriver then
			if not pcall(RegisterStateDriver, header, attr, driver) then complete = false end
		elseif driver then
			complete = false
		end
	end
	local native = State.BuildNativeDriver()

	Drive(headers.main, "native")
	Drive(headers.main, "swap")
	SetSnippet(headers.main, "_onstate-native", PACK)
	SetSnippet(headers.main, "_onstate-swap", PACK)
	SetSnippet(headers.main, "_fluxForceApply", FORCE_HEAD .. PACK)
	writeSnippet(headers.main, "_fluxHoverApply", REFRESH_HEAD .. HOVER_PACK)
	Drive(headers.main, "native", native)

	-- Native stance/bonusbar drivers stay per dynamic header (3), same as backup.
	Drive(headers.sec, "native")
	Drive(headers.sec, "swap")
	SetSnippet(headers.sec, "_onstate-native", PACK_MINI)
	SetSnippet(headers.sec, "_onstate-swap", PACK_MINI)
	SetSnippet(headers.sec, "_fluxForceApply", FORCE_HEAD .. PACK_MINI)
	writeSnippet(headers.sec, "_fluxHoverApply", REFRESH_HEAD .. HOVER_PACK)
	Drive(headers.sec, "native", native)

	Drive(headers.tert, "native")
	Drive(headers.tert, "swap")
	SetSnippet(headers.tert, "_onstate-native", PACK_MINI)
	SetSnippet(headers.tert, "_onstate-swap", PACK_MINI)
	SetSnippet(headers.tert, "_fluxForceApply", FORCE_HEAD .. PACK_MINI)
	writeSnippet(headers.tert, "_fluxHoverApply", REFRESH_HEAD .. HOVER_PACK)
	Drive(headers.tert, "native", native)

	local STATIC_REFRESH = [[
		local newstate = self:GetAttribute("state-page") or 0
	]]
	local STATIC_FORCE = FORCE_RESET .. STATIC_REFRESH .. STATIC_PACK
	local STATIC_HOVER = STATIC_REFRESH .. STATIC_HOVER_PACK

	Drive(headers.staticMain, "page")
	SetSnippet(headers.staticMain, "_onstate-page", STATIC_PACK)
	SetSnippet(headers.staticMain, "_fluxForceApply", STATIC_FORCE)
	writeSnippet(headers.staticMain, "_fluxHoverApply", STATIC_HOVER)

	Drive(headers.staticSec, "page")
	SetSnippet(headers.staticSec, "_onstate-page", STATIC_PACK)
	SetSnippet(headers.staticSec, "_fluxForceApply", STATIC_FORCE)
	writeSnippet(headers.staticSec, "_fluxHoverApply", STATIC_HOVER)

	Drive(headers.staticTert, "page")
	SetSnippet(headers.staticTert, "_onstate-page", STATIC_PACK)
	SetSnippet(headers.staticTert, "_fluxForceApply", STATIC_FORCE)
	writeSnippet(headers.staticTert, "_fluxHoverApply", STATIC_HOVER)

	local hub = State.hub
	if not hub then
		hub = CreateFrame("Frame", "FluxActionStripModHub", nil, "SecureHandlerStateTemplate")
		State.hub = hub
	end
	Drive(hub, "mod")
	hub:SetFrameRef("main", headers.main)
	hub:SetFrameRef("sec", headers.sec)
	hub:SetFrameRef("tert", headers.tert)
	hub:SetFrameRef("staticMain", headers.staticMain)
	hub:SetFrameRef("staticSec", headers.staticSec)
	hub:SetFrameRef("staticTert", headers.staticTert)
	SetSnippet(hub, "_onstate-mod", [[
		local v = newstate
		local main = self:GetFrameRef("main")
		if main then main:SetAttribute("state-swap", v) end
		local sec = self:GetFrameRef("sec")
		if sec then sec:SetAttribute("state-swap", v) end
		local tert = self:GetFrameRef("tert")
		if tert then tert:SetAttribute("state-swap", v) end
		local sm = self:GetFrameRef("staticMain")
		if sm then sm:SetAttribute("state-page", v) end
		local ss = self:GetFrameRef("staticSec")
		if ss then ss:SetAttribute("state-page", v) end
		local st = self:GetFrameRef("staticTert")
		if st then st:SetAttribute("state-page", v) end
	]])
	Drive(hub, "mod", "[mod:shift]1;[mod:ctrl]2;0")

	-- Mouseover cast fans out through the same six headers: its own hub flips
	-- their state-target-* attributes, and each header ChildUpdates its hosts.
	local MC = Flux.MouseoverCast
	if MC and MC.RegisterHeader then
		MC.RegisterHeader(headers.main)
		MC.RegisterHeader(headers.sec)
		MC.RegisterHeader(headers.tert)
		MC.RegisterHeader(headers.staticMain)
		MC.RegisterHeader(headers.staticSec)
		MC.RegisterHeader(headers.staticTert)
		if MC.Start then
			MC.Start()
		end
	end
	return complete
end

--- Mirrors the CHILDUPDATE occupancy rule: the Lua flags are frozen while
--- Layout.ApplyMappings is locked down, so OR in live occupancy. Drag-expand
--- already forces both flags to 1, so this only ever promotes 0 to 1.
--- Layout.SlotHasAction is the secret-safe, overlay-aware test the flags
--- themselves are stamped from; raw HasAction would disagree with them.
local function HostResolveOpts(widget, column)
	if not widget or not widget.GetAttribute then
		return { promoted = 0, hasSec = false, hasTert = false }
	end
	local hasSec = (tonumber(widget:GetAttribute("flux-has-sec")) or 0) == 1
	local hasTert = (tonumber(widget:GetAttribute("flux-has-tert")) or 0) == 1
	column = column or tonumber(widget:GetAttribute("flux-column"))
	local Occupied = Bars.Layout and Bars.Layout.SlotHasAction
	if column and Occupied then
		if not hasSec and Occupied(SlotMath.SecondarySlot(column)) then
			hasSec = true
		end
		if not hasTert and Occupied(SlotMath.TertiarySlot(column)) then
			hasTert = true
		end
	end
	return {
		promoted = tonumber(widget:GetAttribute("flux-promoted")) or 0,
		hasSec = hasSec,
		hasTert = hasTert,
	}
end

function State.CurrentSwap()
	if IsShiftKeyDown and IsShiftKeyDown() then
		return 1
	end
	if IsControlKeyDown and IsControlKeyDown() then
		return 2
	end
	return 0
end

--- Display identity follows the current page and physical modifiers even if
--- an older native action-attribute notification arrives after a newer edge.
--- Optional page/swap let a whole-host pass take one shared input snapshot.
function State.ResolveCurrentSlot(host, page, swap)
	local widget = host and host.widget
	if not widget then return nil end
	local column = host.column or tonumber(widget:GetAttribute("flux-column"))
	if not column then return nil end
	if page == nil then
		local header = widget.GetParent and widget:GetParent()
		page = header and header.GetAttribute and tonumber(header:GetAttribute("actionpage"))
		if not page or page < 1 then page = State.GetCurrentPage() end
	end
	if swap == nil then swap = State.CurrentSwap() end
	return SlotMath.Resolve(column, host.row or "main", page, swap, HostResolveOpts(widget, column))
end

--- Paint-only: host.slot follows SlotMath without SetAttribute (combat-safe).
--- Also rehomes corner badges and queues identity VFX so fill/reticle/interrupt
--- /burst follow the spell that just moved, even when the action attribute is
--- frozen for the rest of the fight.
function State.IndexLiveSlots()
	if not Bars.ForEachHost then
		return
	end
	local Hosts = Bars.Hosts
	local Paint = Bars.Paint
	if not (Hosts and Hosts.IndexSlot) then
		return
	end
	local BadgeHost = Bars.BadgeHost or _G.FluxBadgeHost
	local swap = State.CurrentSwap()
	Bars.ForEachHost(function(host)
		local widget = host.widget
		if not widget then
			return
		end
		local slot = State.ResolveCurrentSlot(host, nil, swap)
		local prev = host.slot
		Hosts.IndexSlot(host, slot)
		if prev == slot then
			return
		end
		-- Rebind overlay/plain-macro identity before badges and effects read
		-- the moved host. Context only reparses condition kinds present in
		-- the macro; a plain program has no [mod] subscription to do this.
		local PF = Bars.ProgramFace
		if PF and PF.TranslateHost then PF.TranslateHost(host, true) end
		if BadgeHost and BadgeHost.NotifyDisplay then
			BadgeHost.NotifyDisplay(host)
		end
		if Paint and Paint.Dirty then
			Paint.Dirty(host)
		elseif Paint and Paint.MarkDirty then
			Paint.MarkDirty(host)
		end
		if Bars.Effects and Bars.Effects.Refresh then
			Bars.Effects.Refresh(host)
		end
	end)
end

--- Without ChildUpdate, stamp all modifier sets plus the live face.
---
--- OOC only. SetAttribute on a protected frame from insecure Lua is blocked in
--- combat (ADDON_ACTION_BLOCKED on FluxActionStripButtonN), which also aborts
--- the rest of the walk. That is exactly why the three sets are pre-stamped:
--- once they are in place a modifier press resolves correctly for the whole
--- fight without anything having to run.
function State.ApplySlotsInsecure()
	if InLockdown() then
		State.IndexLiveSlots()
		return false
	end
	if not Bars.ForEachHost then
		return false
	end
	local Hosts = Bars.Hosts
	local page = State.GetCurrentPage and State.GetCurrentPage() or 1
	local swap = State.CurrentSwap()
	Bars.ForEachHost(function(host)
		local widget = host.widget
		if not widget then
			return
		end
		local column = host.column or tonumber(widget:GetAttribute("flux-column"))
		local row = host.row or "main"
		local opts = HostResolveOpts(widget, column)
		local nomod = SlotMath.Resolve(column, row, page, 0, opts)
		local shift = SlotMath.Resolve(column, row, page, 1, opts)
		local ctrl = SlotMath.Resolve(column, row, page, 2, opts)
		local live = nomod
		if swap == 1 then
			live = shift
		elseif swap == 2 then
			live = ctrl
		end
		widget:SetAttribute("action", live)
		local nativeOnly = column <= NATIVE and page >= 11 and row == "main"
		for i, prefix in ipairs(CLICK_PREFIXES) do
			local slot = i >= 5 and shift or i >= 3 and ctrl or nomod
			StampSwapClick(widget, prefix, slot, nativeOnly)
		end
		StampLiveClick(widget, live, nativeOnly)
		widget:SetAttribute("flux-applied", live)
		widget:SetAttribute("flux-applied-mods", nomod * 1000000 + shift * 1000 + ctrl)
		if Hosts and Hosts.IndexSlot then
			Hosts.IndexSlot(host, live)
		end
	end)
	return true
end

--- Restricted fallback wrote hub state-mod; snippets never ran.
--- In combat this can only reindex for paint: the three click sets were already
--- stamped out of combat and a modifier press resolves against them directly.
function State.OnModFallback()
	if InLockdown() then
		State.IndexLiveSlots()
		return
	end
	State.ApplySlotsInsecure()
end

function State.ForceApply(hoverOnly)
	if not State.headers then
		return false
	end
	if InLockdown() then
		-- Neither Execute nor an insecure SetAttribute is available here, so all
		-- this can do is keep host.slot and paint following the live swap.
		State.IndexLiveSlots()
		return false
	end
	if not SnippetsWork() then
		return State.ApplySlotsInsecure()
	end
	-- Execute from insecure Lua in combat blocks SecureHandlersUpdateFrame:SetAttribute
	-- and taints later SHIFT/CTRL _onstate-swap ChildUpdate (main stays on Spell-A).
	local Restricted = Flux.Restricted
	local function execute(header, body)
		if Restricted and Restricted.ExecutePaging then
			return Restricted.ExecutePaging(header, body)
		elseif Restricted and Restricted.Execute then
			return Restricted.Execute(header, body)
		else
			header:Execute(body)
			return true
		end
	end
	local function run(header)
		if not (header and header.Execute and header:GetAttribute("_fluxForceApply")) then return end
		if hoverOnly == true and header:GetAttribute("_fluxHoverApply")
			and execute(header, [[ self:RunAttribute("_fluxHoverApply") ]]) then return end
		execute(header, [[ self:RunAttribute("_fluxForceApply") ]])
	end
	local h = State.headers
	run(h.main)
	run(h.sec)
	run(h.tert)
	run(h.staticMain)
	run(h.staticSec)
	run(h.staticTert)
	return true
end

function State.GetClassStances()
	return StanceMap()
end

-- Binding catalog / ChordMap aliases (no LAB registry).
ns.FluxActionBarState = State
_G.FluxActionBarState = State
ns.FluxStateDriver = State
_G.FluxStateDriverModule = State
