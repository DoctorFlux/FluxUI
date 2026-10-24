-- Bars/State.lua — numeric page driver + restricted slot math (no 90-attr bake).
-- Six headers (main/sec/tert × dynamic 1-12 and static 13-19) plus one mod hub.
--
-- Two independent axes:
--   native page — form / stealth / vehicle / override / bar page. Needs a secure
--     evaluator, so it stays on RegisterStateDriver + _onstate-native and the
--     restricted ChildUpdate below.
--   modifier swap — SHIFT / CTRL main-row <-> minirow. Resolved at *press time*
--     from shift-action* / ctrl-action* (and their type / typerelease /
--     macrotext / clickbutton twins), which Blizzard's
--     SecureButton_GetModifiedAttribute reads against the live modifier state.
--     Those attributes are stamped ahead of the press, so the click never waits
--     on the [mod:] state driver, the mod hub, or ChildUpdate — which is what
--     used to leave clicks frozen on the modifier state a fight was entered
--     with while the icon still swapped. The hub/ChildUpdate now only keep the
--     visible face and host.slot in step.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local State = {}
Bars.State = State

local NATIVE = 12
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
	self:SetAttribute("flux-applied", nil)
	self:SetAttribute("flux-applied-mods", nil)
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
		mainRest = (page - 1) * 12 + col
		sec = 60 + col
		tert = 24 + col
	end

	-- Layout.ApplyMappings cannot stamp occupancy while structural work is
	-- locked down, so a fight entered before the first stamp left hasSec 0 and
	-- SHIFT never left the main row for the whole fight. Read it live instead.
	-- sec/tert do not depend on the page, so the probe is cached until the
	-- slot-changed flush or a ForceApply clears it: HasAction stays off the
	-- modifier edge, which ChildUpdates all 57 surfaces.
	local liveSec = tonumber(self:GetAttribute("flux-live-sec"))
	local liveTert = tonumber(self:GetAttribute("flux-live-tert"))
	if not liveSec and HasAction then
		if HasAction(sec) then liveSec = 1 else liveSec = 0 end
		if HasAction(tert) then liveTert = 1 else liveTert = 0 end
		self:SetAttribute("flux-live-sec", liveSec)
		self:SetAttribute("flux-live-tert", liveTert)
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

	self:SetAttribute("state", packed)

	-- The three click sets. These are what a press actually resolves, and they
	-- only move when the native page, promotion or occupancy moves -- never on a
	-- modifier edge, where nomod/sec/tert are all already correct. Guarding them
	-- separately keeps holding SHIFT at the old cost while a form flip still
	-- repoints all three. flux-applied-mods is cleared by _childupdate-fluxreset
	-- before a ForceApply and by the slot-changed flush.
	local mods = slotNomod * 1000000 + slotShift * 1000 + slotCtrl
	if tonumber(self:GetAttribute("flux-applied-mods")) ~= mods then
		self:SetAttribute("flux-applied-mods", mods)
		for i = 1, 3 do
			local pfx, s
			if i == 1 then
				pfx = ""
				s = slotNomod
			elseif i == 2 then
				pfx = "shift-"
				s = slotShift
			else
				pfx = "ctrl-"
				s = slotCtrl
			end
			self:SetAttribute(pfx .. "action*", s)
			local body = self:GetAttribute("flux-p-" .. s)
			local clicker = self:GetAttribute("flux-click-" .. s)
			local mode = self:GetAttribute("flux-m-" .. s)
			if static == 0 and page >= 11 and row == 1 then body, clicker = nil, nil end
			-- Every branch writes all four. Leaving one nil falls through to the
			-- bare live attribute, which under SHIFT would fire whatever body
			-- the main row happens to be showing.
			if clicker then
				self:SetAttribute(pfx .. "type*", "click")
				self:SetAttribute(pfx .. "typerelease*", "click")
				self:SetAttribute(pfx .. "clickbutton*", clicker)
				self:SetAttribute(pfx .. "macrotext*", nil)
			elseif body and body ~= "" and mode ~= "d" then
				self:SetAttribute(pfx .. "type*", "macro")
				self:SetAttribute(pfx .. "typerelease*", "macro")
				self:SetAttribute(pfx .. "clickbutton*", nil)
				self:SetAttribute(pfx .. "macrotext*", body)
			else
				self:SetAttribute(pfx .. "type*", "action")
				self:SetAttribute(pfx .. "typerelease*", "action")
				self:SetAttribute(pfx .. "clickbutton*", nil)
				self:SetAttribute(pfx .. "macrotext*", nil)
			end
			-- ButtonFX CLICK_SNIPPET resolves these by modifier so an empowered
			-- spell on a mini row still gates on down instead of release.
			if IsPressHoldReleaseSpell then
				local aType, id, subType = GetActionInfo(s)
				local spellID = nil
				if aType == "spell" then
					spellID = id
				elseif aType == "macro" and subType == "spell" then
					spellID = id
				end
				if spellID and IsPressHoldReleaseSpell(spellID) then
					self:SetAttribute(pfx .. "IsEmpowerSpell*", true)
				else
					self:SetAttribute(pfx .. "IsEmpowerSpell*", false)
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

--- Lua twin of the CHILDUPDATE click-set block, for create time and for Forever
--- (where no snippet ever installs). prefix is "" (nomod), "shift-" or "ctrl-".
--- The "*" suffix makes one write cover keys, left, right and middle click:
--- SecureButton_GetButtonSuffix gives "1" for the LeftButton every strip key is
--- remapped to, so bare "shift-action" would never be looked up.
--- IsEmpowerSpell is left to CHILDUPDATE -- the wrap that reads it only exists
--- on clients where snippets work.
local function StampSwapClick(widget, prefix, slot)
	widget:SetAttribute(prefix .. "action*", slot)
	local body = slot and widget:GetAttribute("flux-p-" .. slot)
	local clicker = slot and widget:GetAttribute("flux-click-" .. slot)
	local mode = slot and widget:GetAttribute("flux-m-" .. slot)
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

--- Forever clicks a hidden LeftButton proxy (no KeyBind wrap, no ChildUpdate).
--- Star attributes are not enough: the proxy resolves type1 / macrotext1, then
--- the bare type which Attach left as "action". Write those too.
local function StampLiveClick(widget, slot)
	if not widget or not slot then
		return
	end
	local body = widget:GetAttribute("flux-p-" .. slot)
	local clicker = widget:GetAttribute("flux-click-" .. slot)
	local mode = widget:GetAttribute("flux-m-" .. slot)
	local function write(prefix, typ, text, button)
		widget:SetAttribute(prefix .. "type", typ)
		widget:SetAttribute(prefix .. "type1", typ)
		widget:SetAttribute(prefix .. "typerelease", typ)
		widget:SetAttribute(prefix .. "typerelease1", typ)
		widget:SetAttribute(prefix .. "clickbutton", button)
		widget:SetAttribute(prefix .. "clickbutton1", button)
		widget:SetAttribute(prefix .. "macrotext", text)
		widget:SetAttribute(prefix .. "macrotext1", text)
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
	if not keyer then
		return
	end
	if clicker then
		keyer:SetAttribute("type", "click")
		keyer:SetAttribute("type1", "click")
		keyer:SetAttribute("clickbutton", clicker)
		keyer:SetAttribute("clickbutton1", clicker)
		keyer:SetAttribute("macrotext", nil)
		keyer:SetAttribute("macrotext1", nil)
	elseif type(body) == "string" and body ~= "" and mode ~= "d" then
		keyer:SetAttribute("type", "macro")
		keyer:SetAttribute("type1", "macro")
		keyer:SetAttribute("typerelease", "macro")
		keyer:SetAttribute("typerelease1", "macro")
		keyer:SetAttribute("clickbutton", nil)
		keyer:SetAttribute("macro", nil)
		keyer:SetAttribute("macrotext", body)
		keyer:SetAttribute("macrotext1", body)
		keyer:SetAttribute("unit", nil)
		keyer:SetAttribute("useOnKeyDown", true)
		keyer:SetAttribute("pressAndHoldAction", false)
		if keyer.RegisterForClicks then
			keyer:RegisterForClicks("AnyDown", "AnyUp")
		end
	else
		keyer:SetAttribute("type", nil)
		keyer:SetAttribute("type1", nil)
		keyer:SetAttribute("macrotext", nil)
		keyer:SetAttribute("macrotext1", nil)
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
local PACK = RESOLVE_PAGE .. [[
	self:SetAttribute("actionpage", page)
	local packed = page + swap * 100
	self:SetAttribute("state", packed)
	control:ChildUpdate("state", packed)
]]

-- SHIFT/CTRL minis must keep the live bonus/override page so a swap uses
-- cat/bear/vehicle 1-12, not noform. Resting minis stay on sec/tert slots,
-- so a native flip must not ChildUpdate (backup skipped LAB state 21/22).
local PACK_MINI = RESOLVE_PAGE .. [[
	self:SetAttribute("actionpage", page)
	local packed = page + swap * 100
	if swap == 0 then
		local prev = tonumber(self:GetAttribute("state"))
		self:SetAttribute("state", packed)
		if prev and prev < 11 and page < 11 then
			return
		end
		control:ChildUpdate("state", packed)
		return
	end
	self:SetAttribute("state", packed)
	control:ChildUpdate("state", packed)
]]

-- Drop every child's applied-slot stamp so the restamp below is a full pass.
local FORCE_RESET = [[
	control:ChildUpdate("fluxreset", 1)
]]

local FORCE_HEAD = FORCE_RESET .. [[
	local stateid = "native"
	local newstate = self:GetAttribute("state-native")
]]

local STATIC_PACK = [[
	local swap = tonumber(newstate)
	if not swap then swap = tonumber(self:GetAttribute("state-page")) or 0 end
	local packed = 1 + swap * 100
	self:SetAttribute("state", packed)
	control:ChildUpdate("state", packed)
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
	Drive(headers.main, "native", native)

	-- Native stance/bonusbar drivers stay per dynamic header (3), same as backup.
	Drive(headers.sec, "native")
	Drive(headers.sec, "swap")
	SetSnippet(headers.sec, "_onstate-native", PACK_MINI)
	SetSnippet(headers.sec, "_onstate-swap", PACK_MINI)
	SetSnippet(headers.sec, "_fluxForceApply", FORCE_HEAD .. PACK_MINI)
	Drive(headers.sec, "native", native)

	Drive(headers.tert, "native")
	Drive(headers.tert, "swap")
	SetSnippet(headers.tert, "_onstate-native", PACK_MINI)
	SetSnippet(headers.tert, "_onstate-swap", PACK_MINI)
	SetSnippet(headers.tert, "_fluxForceApply", FORCE_HEAD .. PACK_MINI)
	Drive(headers.tert, "native", native)

	local STATIC_FORCE = FORCE_RESET .. [[
		local newstate = self:GetAttribute("state-page") or 0
	]] .. STATIC_PACK

	Drive(headers.staticMain, "page")
	SetSnippet(headers.staticMain, "_onstate-page", STATIC_PACK)
	SetSnippet(headers.staticMain, "_fluxForceApply", STATIC_FORCE)

	Drive(headers.staticSec, "page")
	SetSnippet(headers.staticSec, "_onstate-page", STATIC_PACK)
	SetSnippet(headers.staticSec, "_fluxForceApply", STATIC_FORCE)

	Drive(headers.staticTert, "page")
	SetSnippet(headers.staticTert, "_onstate-page", STATIC_PACK)
	SetSnippet(headers.staticTert, "_fluxForceApply", STATIC_FORCE)

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
	local page = State.GetCurrentPage and State.GetCurrentPage() or 1
	local swap = State.CurrentSwap()
	Bars.ForEachHost(function(host)
		local widget = host.widget
		if not widget then
			return
		end
		local column = host.column or tonumber(widget:GetAttribute("flux-column"))
		local row = host.row or "main"
		local slot = SlotMath.Resolve(column, row, page, swap, HostResolveOpts(widget, column))
		local prev = host.slot
		Hosts.IndexSlot(host, slot)
		if prev == slot then
			return
		end
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

--- Forever: no ChildUpdate. Stamp all three click sets plus the live face.
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
		StampSwapClick(widget, "", nomod)
		StampSwapClick(widget, "shift-", shift)
		StampSwapClick(widget, "ctrl-", ctrl)
		StampLiveClick(widget, live)
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

function State.ForceApply()
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
	local function run(header)
		if header and header.Execute and header:GetAttribute("_fluxForceApply") then
			local Restricted = Flux.Restricted
			if Restricted and Restricted.ExecutePaging then
				Restricted.ExecutePaging(header, [[ self:RunAttribute("_fluxForceApply") ]])
			elseif Restricted and Restricted.Execute then
				Restricted.Execute(header, [[ self:RunAttribute("_fluxForceApply") ]])
			else
				header:Execute([[ self:RunAttribute("_fluxForceApply") ]])
			end
		end
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
