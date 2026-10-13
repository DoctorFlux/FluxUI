--[[
Copyright (c) 2010-2022, Hendrik "nevcairiel" Leppkes <h.leppkes@gmail.com>

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Neither the name of the developer nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]
local MAJOR_VERSION = "LibActionButton-1.0"
local MINOR_VERSION = 167

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

-- Lua functions
local type, error, tostring, tonumber, assert, select = type, error, tostring, tonumber, assert, select
local setmetatable, wipe, unpack, pairs, next = setmetatable, wipe, unpack, pairs, next
local str_match, format = string.match, format

local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local WoWClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local WoWBCC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local Midnight = (select(4, GetBuildInfo())) >= 120000

local DisableOverlayGlow = (WoWClassic or WoWBCC or WoWWrath) and not (_G.FluxProcGlowCompatEnableLabOverlay == true)

-- Version detection for AnyDown support (Dragonflight+ supports keybind presses properly)
local majorVersion = 11
if GetBuildInfo then
    local version = GetBuildInfo()
    if version then
        majorVersion = tonumber(version:match("^(%d+)")) or 11
    end
end
local supportsAnyDown = true -- All modern WoW clients support AnyDown for keybind presses

-- Enable custom flyouts for WoW Retail
local UseCustomFlyout = WoWRetail or (FlyoutButtonMixin and not ActionButton_UpdateFlyout)

local KeyBound = LibStub("LibKeyBound-1.0", true)
-- FLUX: Only KeyBound actually owns GameTooltip for binding UI. Do not use FluxBindingMode:IsActive()
-- here — it can stay true while KeyBound is off (ordering/combat), which would suppress LAB tooltips forever.
local function IsBindingModeTooltipOwned()
	if KeyBound and KeyBound.IsShown and KeyBound:IsShown() then return true end
	return false
end
local CBH = LibStub("CallbackHandler-1.0")
local LBG = LibStub("LibButtonGlow-1.0", true)
local Masque = LibStub("Masque", true)

lib.eventFrame = lib.eventFrame or CreateFrame("Frame")
lib.eventFrame:UnregisterAllEvents()

lib.buttonRegistry = lib.buttonRegistry or {}
lib.activeButtons = lib.activeButtons or {}
lib.actionButtons = lib.actionButtons or {}
lib.nonActionButtons = lib.nonActionButtons or {}
lib.actionButtonsNonUI = lib.actionButtonsNonUI or {}

lib.NumChargeCooldowns = lib.NumChargeCooldowns or 0

lib.FlyoutInfo = lib.FlyoutInfo or {}
lib.FlyoutButtons = lib.FlyoutButtons or {}

lib.ACTION_HIGHLIGHT_MARKS = lib.ACTION_HIGHLIGHT_MARKS or setmetatable({}, { __index = ACTION_HIGHLIGHT_MARKS })

lib.callbacks = lib.callbacks or CBH:New(lib)

local Generic = CreateFrame("CheckButton")
local Generic_MT = {__index = Generic}

local Action = setmetatable({}, {__index = Generic})
local Action_MT = {__index = Action}

--local PetAction = setmetatable({}, {__index = Generic})
--local PetAction_MT = {__index = PetAction}

local Spell = setmetatable({}, {__index = Generic})
local Spell_MT = {__index = Spell}

local Item = setmetatable({}, {__index = Generic})
local Item_MT = {__index = Item}

local Macro = setmetatable({}, {__index = Generic})
local Macro_MT = {__index = Macro}

local Custom = setmetatable({}, {__index = Generic})
local Custom_MT = {__index = Custom}

-- Flux: free-form macrotext state kind. The Binding module installs generated
-- macro text on exactly the (button, state) pairs that display a given action
-- slot; the underlying slot is kept in labmacrotextslot-<state> for drag/drop.
-- (single chunk-level local; the display class body lives near the other classes)
local Macrotext = setmetatable({}, {__index = Generic})

local type_meta_map = {
	empty  = Generic_MT,
	action = Action_MT,
	--pet    = PetAction_MT,
	spell  = Spell_MT,
	item   = Item_MT,
	macro  = Macro_MT,
	custom = Custom_MT,
	macrotext = {__index = Macrotext},
}

local ButtonRegistry, ActiveButtons, ActionButtons, NonActionButtons, ActionButtonsNonUI = lib.buttonRegistry, lib.activeButtons, lib.actionButtons, lib.nonActionButtons, lib.actionButtonsNonUI

-- Bartended perf: subset of activeButtons that need IsInRange() polling in OnUpdate.
lib.rangeButtons = lib.rangeButtons or {}

-- Flux perf: buttons whose action slot is the Single-Button Assistant / assisted combat rotation.
lib.assistedCombatButtons = lib.assistedCombatButtons or {}

-- Flux perf T1.1: narrow sets so the shared OnUpdate can skip iterating all
-- ActiveButtons every frame when nothing is actively flashing or running a
-- manual spell-cast VFX. Populated/cleared next to each vfxCastData/flashing
-- state change below so iteration stays authoritative.
lib.fluxVFXButtons = lib.fluxVFXButtons or {}
lib.fluxFlashingButtons = lib.fluxFlashingButtons or {}

-- Flux LAB: granular usable + broadcast dedupe (see Interface/MACRO_CONDITIONAL_LAG_FIXES_TRIED.txt)
lib.slotToActionButtons = lib.slotToActionButtons or {}

-- Flux perf T2.1: spellId -> buttons index used by SPELL_ACTIVATION_OVERLAY_GLOW_*
-- and any other event that keys by spellId. Avoids scanning ActiveButtons (up
-- to ~100 buttons) on every glow event by resolving directly to the subset
-- that currently exposes that spellId. lib.fluxFlyoutActionButtons tracks the small
-- set of action buttons whose current slot is a flyout, so FlyoutHasSpell is
-- only consulted against that subset.
lib.fluxSpellIdToButtons = lib.fluxSpellIdToButtons or {}
lib.fluxFlyoutActionButtons = lib.fluxFlyoutActionButtons or {}
-- Bartended perf: spellID -> { [button] = true } for O(1) flyout proc glow dispatch.
lib.fluxFlyoutSpellButtons = lib.fluxFlyoutSpellButtons or {}
-- Flux perf: action buttons whose macro body contains @mouseover (mouseover coalesced usable flush).
lib.fluxMouseoverMacroButtons = lib.fluxMouseoverMacroButtons or {}
-- Flux Binding: buttons whose CURRENT state is a macrotext override (display re-eval set).
lib.fluxMacrotextButtons = lib.fluxMacrotextButtons or {}
-- Chunk-local budget: batch defer/coalesce flags (Lua 5.1 max 200 locals per function).
lib.fluxDefer = {}
lib.fluxDefer.granularUsableSlotsThisTick = {}
lib.fluxDefer.pendingBroadcastUsable = false
lib.fluxDefer.fluxBroadcastUsableDeferTimer = false
lib.fluxDefer.pendingActionBarUpdateState = false
lib.fluxDefer.fluxActionBarUpdateStateDeferTimer = false
lib.fluxDefer.pendingSpellUsable = false
lib.fluxDefer.pendingSpellHighlightFlush = false
lib.fluxDefer.pendingActionBarSlotChangedAll = false
lib.fluxDefer.actionBarSlotChangedAllScheduled = false
lib.fluxDefer.pendingActionBarSlotChangedSlots = {}
lib.fluxDefer.actionBarSlotChangedSlotsScheduled = false
lib.fluxDefer.pendingActionBarCooldownFlush = false
lib.fluxDefer.actionBarCooldownFlushScheduled = false
lib.fluxDefer.pendingEquipItemRefresh = false
lib.fluxDefer.equipItemRefreshScheduled = false
lib.fluxDefer.levelLinkCache = {}
lib.fluxDefer.levelLinkCacheGen = 0
-- Forward-declared: assigned after helpers are defined (OnEvent is earlier in file; bare names would be nil globals)
local FluxLABBeginUsableBatch, ScheduleFlushBroadcastUsable, NormalizeActionUsableChanges
lib._fluxActionUsableChangedRegistered = false
lib._fluxDbgGranularUsableEv = 0
lib._fluxDbgBroadcastUsable = 0
lib._fluxDbgSkippedBroadcast = 0
lib._fluxDbgUpdateUsableCalls = 0
lib._fluxDbgSkippedGranularDup = 0

local Update, UpdateButtonState, UpdateUsable, UpdateCount, UpdateCooldown, UpdateCooldownNumberHidden, UpdateTooltip, UpdateNewAction, UpdateSpellHighlight, ClearNewActionHighlight, UpdateAssistedCombatRotationFrame, UpdatedAssistedHighlightFrame
local StartFlash, StopFlash, UpdateFlash, UpdateHotkeys, UpdateRangeTimer, UpdateOverlayGlow
local UpdateFlyout, ShowGrid, HideGrid, UpdateGrid, SetupSecureSnippets, WrapOnClick
local ShowOverlayGlow, HideOverlayGlow
local ClearChargeCooldown

local SpellVFX_ClearReticle, SpellVFX_ClearInterruptDisplay, SpellVFX_PlaySpellCastAnim, SpellVFX_PlayTargettingReticleAnim, SpellVFX_StopTargettingReticleAnim, SpellVFX_StopSpellCastAnim, SpellVFX_PlaySpellInterruptedAnim
local SpellVFX_CastingAnim_OnHide, SpellVFX_CastingAnim_Finish_OnFinished

local GetFlyoutHandler

local InitializeEventHandler, OnEvent, ForAllButtons, ForAllButtonsWithSpell, OnUpdate
local FlushActionBarSlotChangedAll, FlushActionBarSlotChangedSlots
local FluxLABSyncSlotButtonMap, FluxLABSyncSpellIdIndex, FluxLABSyncFlyoutActionIndex, FluxLABSyncAssistedCombatIndex, FluxLABSyncMouseoverMacroIndex
local FlushMouseoverActionUsable
local AreSpellsEquivalent

local function GameTooltip_GetOwnerForbidden()
	if GameTooltip:IsForbidden() then
		return nil
	end
	return GameTooltip:GetOwner()
end

local DefaultConfig = {
	outOfRangeColoring = "button",
	tooltip = "enabled",
	showGrid = false,
	colors = {
		range = { 0.8, 0.1, 0.1 },
		mana = { 0.5, 0.5, 1.0 }
	},
	hideElements = {
		macro = false,
		hotkey = false,
		equipped = false,
		border = false,
		borderIfEmpty = false,
	},
	keyBoundTarget = false,
	keyBoundClickButton = "LeftButton",
	clickOnDown = false,
	cooldownCount = nil, -- nil: use cvar, true/false: enable/disable
	lossOfControlCooldown = true,
	flyoutDirection = "UP",
	actionButtonUI = false, -- register the button with SetActionUIButton, this has some side-effects if the button changes from action type to another type, but is required for certain UI integrations. Recommended to only set on pure type=action buttons
	-- Next-cast blue ants (Blizzard ActionBarButtonAssistedCombatHighlightTemplate + AssistedCombatManager); independent of actionButtonUI / SetActionUIButton.
	assistedHighlight = true,
	spellCastVFX = false, -- enable cast vfx
	text = {
		hotkey = {
			font = {
				font = false, -- "Fonts\\ARIALN.TTF",
				size = WoWRetail and 14 or 13,
				flags = "OUTLINE",
			},
			color = { 0.75, 0.75, 0.75 },
			position = {
				anchor = "TOPRIGHT",
				relAnchor = "TOPRIGHT",
				offsetX = -2,
				offsetY = -4,
			},
			justifyH = "RIGHT",
		},
		count = {
			font = {
				font = false, -- "Fonts\\ARIALN.TTF",
				size = 16,
				flags = "OUTLINE",
			},
			color = { 1, 1, 1 },
			position = {
				anchor = "BOTTOMRIGHT",
				relAnchor = "BOTTOMRIGHT",
				offsetX = -2,
				offsetY = 4,
			},
			justifyH = "RIGHT",
		},
		macro = {
			font = {
				font = false, -- "Fonts\\FRIZQT__.TTF",
				size = 10,
				flags = "OUTLINE",
			},
			color = { 1, 1, 1 },
			position = {
				anchor = "BOTTOM",
				relAnchor = "BOTTOM",
				offsetX = 0,
				offsetY = 2,
			},
			justifyH = "CENTER",
		},
	},
}

local ActionButtonCastType =
{
	Cast = 1,
	Channel = 2,
	Empowered = 3,
}

-- Single-slot sync for assisted combat rotation (Blizzard template calls ForceUpdateAction each tick).
-- Returns true if this button is the assisted slot and ForceUpdateAction was applied.
function lib.FluxForceUpdateAssistedActionSlotIfNeeded(button)
	if not (C_ActionBar and C_ActionBar.ForceUpdateAction and C_ActionBar.IsAssistedCombatAction) then
		return false
	end
	if not button or button._state_type ~= "action" then
		return false
	end
	local slot = button._state_action
	if type(slot) ~= "number" then
		return false
	end
	if not C_ActionBar.IsAssistedCombatAction(slot) then
		return false
	end
	-- Phase 2: ForceUpdateAction fires slot-0 (full-bar churn). Pre-schedule a narrow
	-- single-slot flush and skip the registry-wide slot-0 handler below.
	lib._fluxAssistForceUpdateBurst = true
	lib._fluxAssistForceUpdateSlot = slot
	_G.FluxAssistRotationSlotBurst = true
	lib.fluxDefer.pendingActionBarSlotChangedSlots[slot] = true
	if not lib.fluxDefer.actionBarSlotChangedSlotsScheduled then
		lib.fluxDefer.actionBarSlotChangedSlotsScheduled = true
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				lib.fluxDefer.actionBarSlotChangedSlotsScheduled = false
				lib._fluxAssistForceUpdateBurst = nil
				lib._fluxAssistForceUpdateSlot = nil
				_G.FluxAssistRotationSlotBurst = nil
				FlushActionBarSlotChangedSlots()
			end)
		else
			lib.fluxDefer.actionBarSlotChangedSlotsScheduled = false
			lib._fluxAssistForceUpdateBurst = nil
			lib._fluxAssistForceUpdateSlot = nil
			_G.FluxAssistRotationSlotBurst = nil
			FlushActionBarSlotChangedSlots()
		end
	end
	C_ActionBar.ForceUpdateAction(slot)
	return true
end

-- Matches FluxActionBar assistedCombatMinIconUpdateRate floor; CVar assistedCombatIconUpdateRate can be 0 (every frame).
function lib.FluxGetAssistedRotationMinInterval()
	local g = rawget(_G, "FluxAssistedCombatMinIconUpdateRate")
	if type(g) == "number" and g > 0 then
		return g
	end
	return 0.05
end

-- Floor AssistedCombatManager:GetUpdateRate() for rotation + highlight scheduling in LAB.
function lib.FluxGetAssistedUpdateInterval()
	local rate = 0.1
	if AssistedCombatManager and AssistedCombatManager.GetUpdateRate then
		rate = AssistedCombatManager:GetUpdateRate()
	end
	return math.max(rate or 0, lib.FluxGetAssistedRotationMinInterval())
end

-- Query assisted-highlight spell without leaving button.action mutated (mutating .action during
-- Blizzard's secure click path taints UseAction / SpellFlyout:Hide).
function lib.FluxAssistedHighlightSpellForButton(mgr, button, slot)
	if not (mgr and button and type(slot) == "number") then
		return nil
	end
	local query = function()
		local saved = button.action
		button.action = slot
		local spellID = mgr:GetActionButtonSpellForAssistedHighlight(button)
		button.action = saved
		return spellID
	end
	if securecall then
		return securecall(query)
	end
	return query()
end

function lib.FluxMergeLabButtonsIntoAssistedHighlightCandidates(self)
	if not self or not self.assistedHighlightCandidateActionButtons then
		return
	end
	for b in next, ActiveButtons do
		if b._state_type == "action" and type(b._state_action) == "number" then
			local spellID = lib.FluxAssistedHighlightSpellForButton(self, b, b._state_action)
			if spellID then
				self.assistedHighlightCandidateActionButtons[b] = spellID
			end
		end
	end
end

function lib.FluxScheduleLabAssistedHighlightMerge(mgr)
	if not mgr then return end
	if mgr._fluxLabHighlightMergePending then return end
	mgr._fluxLabHighlightMergePending = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			mgr._fluxLabHighlightMergePending = nil
			lib.FluxMergeLabButtonsIntoAssistedHighlightCandidates(mgr)
		end)
	else
		mgr._fluxLabHighlightMergePending = nil
		lib.FluxMergeLabButtonsIntoAssistedHighlightCandidates(mgr)
	end
end

function lib.FluxRegisterLabButtonAssistedHighlightCandidate(button)
	if not (AssistedCombatManager and AssistedCombatManager.assistedHighlightCandidateActionButtons) then
		return
	end
	if not button or button._state_type ~= "action" or type(button._state_action) ~= "number" then
		return
	end
	local spellID = lib.FluxAssistedHighlightSpellForButton(
		AssistedCombatManager, button, button._state_action)
	if spellID then
		AssistedCombatManager.assistedHighlightCandidateActionButtons[button] = spellID
	else
		AssistedCombatManager.assistedHighlightCandidateActionButtons[button] = nil
	end
end

--- Create a new action button.
-- @param id Internal id of the button (not used by LibActionButton-1.0, only for tracking inside the calling addon)
-- @param name Name of the button frame to be created (not used by LibActionButton-1.0 aside from naming the frame)
-- @param header Header that drives these action buttons (if any)
function lib:CreateButton(id, name, header, config)
	if type(name) ~= "string" then
		error("Usage: CreateButton(id, name. header): Buttons must have a valid name!", 2)
	end
	if not header then
		error("Usage: CreateButton(id, name, header): Buttons without a secure header are not yet supported!", 2)
	end

	if not KeyBound then
		KeyBound = LibStub("LibKeyBound-1.0", true)
	end

	local button = setmetatable(CreateFrame("CheckButton", name, header, "ActionButtonTemplate, SecureActionButtonTemplate"), Generic_MT)
	button:RegisterForDrag("LeftButton", "RightButton")
	if supportsAnyDown then
		button:RegisterForClicks("AnyDown", "AnyUp")
	else
		button:RegisterForClicks("AnyUp")
	end

	-- Frame Scripts
	button:SetScript("OnEnter", Generic.OnEnter)
	button:SetScript("OnLeave", Generic.OnLeave)
	button:SetScript("PreClick", Generic.PreClick)
	button:SetScript("PostClick", Generic.PostClick)
	button:SetScript("OnEvent", Generic.OnButtonEvent)

	button.id = id
	button.header = header
	-- Mapping of state -> action
	button.state_types = {}
	button.state_actions = {}

	-- Store the LAB Version that created this button for debugging
	button.__LAB_Version = MINOR_VERSION

	-- just in case we're not run by a header, default to state 0
	button:SetAttribute("state", 0)

	SetupSecureSnippets(button)
	WrapOnClick(button)

	-- update animation scripts
	if button.SpellCastAnimFrame then
		button.SpellCastAnimFrame:SetScript("OnHide", SpellVFX_CastingAnim_OnHide)
		button.SpellCastAnimFrame.EndBurst.FinishCastAnim:SetScript("OnFinished", SpellVFX_CastingAnim_Finish_OnFinished)
	end

	-- if there is no button yet, initialize events later
	local InitializeEvents = not next(ButtonRegistry)

	-- Store the button in the registry, needed for event and OnUpdate handling
	ButtonRegistry[button] = true

	-- setup button configuration
	button:UpdateConfig(config)

	-- run an initial update
	button:UpdateAction()
	UpdateHotkeys(button)

	button:SetAttribute("LABUseCustomFlyout", UseCustomFlyout)

	-- nil out inherited functions from the flyout mixin, we override these in a metatable
	if UseCustomFlyout then
		button.GetPopupDirection = nil
		button.IsPopupOpen = nil
	end

	-- initialize events
	if InitializeEvents then
		InitializeEventHandler()
	end

	-- somewhat of a hack for the Flyout buttons to not error.
	button.action = 0

	lib.FluxRegisterLabButtonAssistedHighlightCandidate(button)

	lib.callbacks:Fire("OnButtonCreated", button)

	return button
end

function lib:GetSpellFlyoutFrame()
	return lib.flyoutHandler
end

function SetupSecureSnippets(button)
	button:SetAttribute("_custom", Custom.RunCustom)
	-- secure UpdateState(self, state)
	-- update the type and action of the button based on the state
	button:SetAttribute("UpdateState", [[
		local state = ...
		self:SetAttribute("state", state)
		local type, action = (self:GetAttribute(format("labtype-%s", state)) or "empty"), self:GetAttribute(format("labaction-%s", state))

		if type == "macrotext" then
			-- Flux Binding: fire generated macro text through the native macro handler.
			self:SetAttribute("type", "macro")
			self:SetAttribute("macro", nil)
			self:SetAttribute("macrotext", action)
			self:SetAttribute("action_field", "macrotext")
		else
			self:SetAttribute("type", type)
			if type == "macro" then
				-- never let stale generated macrotext shadow a real macro index
				self:SetAttribute("macrotext", nil)
			end
			if type ~= "empty" and type ~= "custom" then
				local action_field = (type == "pet") and "action" or type
				self:SetAttribute(action_field, action)
				self:SetAttribute("action_field", action_field)
			end
		end
		if IsPressHoldReleaseSpell then
			local pressAndHold = false
			if type == "action" then
				self:SetAttribute("typerelease", "actionrelease")
				local actionType, id, subType = GetActionInfo(action)
				if actionType == "spell" then
					pressAndHold = IsPressHoldReleaseSpell(id)
				elseif actionType == "macro" then
					if subType == "spell" then
						pressAndHold = IsPressHoldReleaseSpell(id)
					end
					-- GetMacroSpell is not in the restricted environment
					--[=[
						local spellID = GetMacroSpell(id)
						if spellID then
							pressAndHold = IsPressHoldReleaseSpell(spellID)
						end
					]=]
				end
			elseif type == "spell" then
				self:SetAttribute("typerelease", nil)
				-- XXX: while we can query this attribute, there is no corresponding action to release a spell button, only "actionrelease" exists
				pressAndHold = IsPressHoldReleaseSpell(action)
			else
				self:SetAttribute("typerelease", nil)
			end

			self:SetAttribute("pressAndHoldAction", pressAndHold)
		end
		local onStateChanged = self:GetAttribute("OnStateChanged")
		if onStateChanged then
			self:Run(onStateChanged, state, type, action)
		end
	]])

	-- this function is invoked by the header when the state changes
	button:SetAttribute("_childupdate-state", [[
		self:RunAttribute("UpdateState", message)
		self:CallMethod("UpdateAction")
	]])

	-- secure PickupButton(self, kind, value, ...)
	-- utility function to place a object on the cursor
	button:SetAttribute("PickupButton", [[
		local kind, value = ...
		if kind == "empty" then
			return "clear"
		elseif kind == "action" or kind == "pet" then
			local actionType = (kind == "pet") and "petaction" or kind
			return actionType, value
		elseif kind == "spell" or kind == "item" or kind == "macro" then
			return "clear", kind, value
		else
			print("LibActionButton-1.0: Unknown type: " .. tostring(kind))
			return false
		end
	]])

	button:SetAttribute("OnDragStart", [[
		if (self:GetAttribute("buttonlock") and not IsModifiedClick("PICKUPACTION")) or self:GetAttribute("LABdisableDragNDrop") then return false end
		local state = self:GetAttribute("state")
		local type = self:GetAttribute("type")
		-- Flux Binding: macrotext overrides drag the UNDERLYING action slot
		if (self:GetAttribute(format("labtype-%s", state)) or "empty") == "macrotext" then
			local slot = self:GetAttribute(format("labmacrotextslot-%s", state))
			if slot then
				return "action", slot
			end
			return false
		end
		-- if the button is empty, we can't drag anything off it
		if type == "empty" or type == "custom" then
			return false
		end
		-- Get the value for the action attribute
		local action_field = self:GetAttribute("action_field")
		local action = self:GetAttribute(action_field)

		-- non-action fields need to change their type to empty
		if type ~= "action" and type ~= "pet" then
			self:SetAttribute(format("labtype-%s", state), "empty")
			self:SetAttribute(format("labaction-%s", state), nil)
			-- update internal state
			self:RunAttribute("UpdateState", state)
			-- send a notification to the insecure code
			self:CallMethod("ButtonContentsChanged", state, "empty", nil)
		end
		-- return the button contents for pickup
		return self:RunAttribute("PickupButton", type, action)
	]])

	button:SetAttribute("OnReceiveDrag", [[
		if self:GetAttribute("LABdisableDragNDrop") then return false end
		local kind, value, subtype, extra = ...
		if not kind or not value then return false end
		local state = self:GetAttribute("state")
		-- Flux Binding: drops onto macrotext overrides go into the UNDERLYING action slot
		if (self:GetAttribute(format("labtype-%s", state)) or "empty") == "macrotext" then
			local slot = self:GetAttribute(format("labmacrotextslot-%s", state))
			if slot then
				return "action", slot
			end
			return false
		end
		local buttonType, buttonAction = self:GetAttribute("type"), nil
		if buttonType == "custom" then return false end
		-- action buttons can do their magic themself
		-- for all other buttons, we'll need to update the content now
		if buttonType ~= "action" and buttonType ~= "pet" then
			-- with "spell" types, the 4th value contains the actual spell id
			if kind == "spell" then
				if extra then
					value = extra
				else
					print("no spell id?", ...)
				end
			elseif kind == "item" and value then
				value = format("item:%d", value)
			end

			-- Get the action that was on the button before
			if buttonType ~= "empty" then
				buttonAction = self:GetAttribute(self:GetAttribute("action_field"))
			end

			-- TODO: validate what kind of action is being fed in here
			-- We can only use a handful of the possible things on the cursor
			-- return false for all those we can't put on buttons

			self:SetAttribute(format("labtype-%s", state), kind)
			self:SetAttribute(format("labaction-%s", state), value)
			-- update internal state
			self:RunAttribute("UpdateState", state)
			-- send a notification to the insecure code
			self:CallMethod("ButtonContentsChanged", state, kind, value)
		else
			-- get the action for (pet-)action buttons
			buttonAction = self:GetAttribute("action")
		end
		return self:RunAttribute("PickupButton", buttonType, buttonAction)
	]])

	button:SetScript("OnDragStart", nil)
	-- Wrapped OnDragStart(self, button, kind, value, ...)
	button.header:WrapScript(button, "OnDragStart", [[
		return self:RunAttribute("OnDragStart")
	]])
	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	button.header:WrapScript(button, "OnDragStart", [[
		return "message", "update"
	]], [[
		self:RunAttribute("UpdateState", self:GetAttribute("state"))
	]])

	button:SetScript("OnReceiveDrag", nil)
	-- Wrapped OnReceiveDrag(self, button, kind, value, ...)
	button.header:WrapScript(button, "OnReceiveDrag", [[
		return self:RunAttribute("OnReceiveDrag", kind, value, ...)
	]])
	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	button.header:WrapScript(button, "OnReceiveDrag", [[
		return "message", "update"
	]], [[
		self:RunAttribute("UpdateState", self:GetAttribute("state"))
	]])

	if UseCustomFlyout then
		button.header:SetFrameRef("flyoutHandler", GetFlyoutHandler())
	end
end

function WrapOnClick(button, unwrapheader)
	-- unwrap OnClick until we got our old script out
	if unwrapheader and unwrapheader.UnwrapScript then
		local wrapheader
		repeat
			wrapheader = unwrapheader:UnwrapScript(button, "OnClick")
		until (not wrapheader or wrapheader == unwrapheader)
	end

	-- Wrap OnClick, to catch changes to actions that are applied with a click on the button.
	button.header:WrapScript(button, "OnClick", [[
		-- Handle mouse button vs keyboard keybind behavior
		-- Mouse buttons (LeftButton, RightButton) should only trigger on release (down = false)
		-- Keyboard keybinds should trigger on press (down = true)
		if button == "LeftButton" or button == "RightButton" then
			if down then
				-- Mouse button press - don't trigger action yet
				return false
			end
			self:SetAttribute("useOnKeyDown", false)
		elseif button == "Keybind" then
			if not down then
				-- Keyboard keybind release - don't trigger (we only want press)
				return false
			end
			self:SetAttribute("useOnKeyDown", true)
		end

		if self:GetAttribute("type") == "action" then
			local type, action = GetActionInfo(self:GetAttribute("action"))

			if type == "flyout" and self:GetAttribute("LABUseCustomFlyout") then
				local flyoutHandler = owner:GetFrameRef("flyoutHandler")
				if not down and flyoutHandler then
					flyoutHandler:SetAttribute("flyoutParentHandle", self)
					flyoutHandler:RunAttribute("HandleFlyout", action)
				end

				-- UpdateFlyout runs via post-script UpdateState / button Update().
				return false
			end

			-- hide the flyout
			local flyoutHandler = owner:GetFrameRef("flyoutHandler")
			if flyoutHandler and flyoutHandler.IsShown and flyoutHandler:IsShown() then
				flyoutHandler:Hide()
			end

			-- if this is a pickup click, disable on-down casting
			-- it should get re-enabled in the post handler, or the OnDragStart handler, whichever occurs
			if button ~= "Keybind" and ((self:GetAttribute("unlockedpreventdrag") and not self:GetAttribute("buttonlock")) or IsModifiedClick("PICKUPACTION")) and not self:GetAttribute("LABdisableDragNDrop") then
				local useOnkeyDown = self:GetAttribute("useOnKeyDown")
				if useOnkeyDown ~= false then
					self:SetAttribute("LABToggledOnDown", true)
					self:SetAttribute("LABToggledOnDownBackup", useOnkeyDown)
					self:SetAttribute("useOnKeyDown", false)
				end
			end
			return (button == "Keybind") and "LeftButton" or nil, format("%s|%s", tostring(type), tostring(action))
		end

		-- hide the flyout, the extra down/ownership check is needed to not hide the button we're currently pressing too early
		local flyoutHandler = owner:GetFrameRef("flyoutHandler")
		if flyoutHandler and flyoutHandler.IsShown and flyoutHandler:IsShown()
			and (not down or self:GetParent() ~= flyoutHandler) then
			flyoutHandler:Hide()
		end

		if button == "Keybind" then
			return "LeftButton"
		end
	]], [[
		local type, action = GetActionInfo(self:GetAttribute("action"))
		if message ~= format("%s|%s", tostring(type), tostring(action)) then
			self:RunAttribute("UpdateState", self:GetAttribute("state"))
		end

		-- re-enable ondown casting if needed
		if self:GetAttribute("LABToggledOnDown") then
			self:SetAttribute("useOnKeyDown", self:GetAttribute("LABToggledOnDownBackup"))
			self:SetAttribute("LABToggledOnDown", nil)
			self:SetAttribute("LABToggledOnDownBackup", nil)
		end
	]])
end

function Generic:OnButtonEvent(event, ...)
	if event == "GLOBAL_MOUSE_UP" then
		self:SetButtonState("NORMAL")
		self:UnregisterEvent(event)

		UpdateFlyout(self)
	end
end

-----------------------------------------------------------
--- utility

function lib:GetAllButtons()
	local buttons = {}
	for button in next, ButtonRegistry do
		buttons[button] = true
	end
	return buttons
end

function Generic:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end

function Generic:NewHeader(header)
	local oldheader = self.header
	self.header = header
	self:SetParent(header)
	SetupSecureSnippets(self)
	WrapOnClick(self, oldheader)
end


-----------------------------------------------------------
--- state management

function Generic:ClearStates()
	for state in pairs(self.state_types) do
		self:SetAttribute(format("labtype-%s", state), nil)
		self:SetAttribute(format("labaction-%s", state), nil)
	end
	if self.state_macrotext_slots then
		for state in pairs(self.state_macrotext_slots) do
			self:SetAttribute(format("labmacrotextslot-%s", state), nil)
		end
		wipe(self.state_macrotext_slots)
	end
	wipe(self.state_types)
	wipe(self.state_actions)
end

function Generic:SetStateFromHandlerInsecure(state, kind, action)
	state = tostring(state)
	-- we allow a nil kind for setting a empty state
	if not kind then kind = "empty" end
	if not type_meta_map[kind] then
		error("SetStateAction: unknown action type: " .. tostring(kind), 2)
	end
	if kind ~= "empty" and action == nil then
		error("SetStateAction: an action is required for non-empty states", 2)
	end
	if kind ~= "custom" and action ~= nil and type(action) ~= "number" and type(action) ~= "string" or (kind == "custom" and type(action) ~= "table") then
		error("SetStateAction: invalid action data type, only strings and numbers allowed", 2)
	end

	if kind == "item" then
		if tonumber(action) then
			action = format("item:%s", action)
		else
			local itemString = str_match(action, "^|c[^|]+|H(item[%d:]+)|h%[")
			if itemString then
				action = itemString
			end
		end
	end

	self.state_types[state] = kind
	self.state_actions[state] = action
end

function Generic:SetState(state, kind, action)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)

	self:SetStateFromHandlerInsecure(state, kind, action)
	self:UpdateState(state)
end

--- Flux Binding: install generated macro text on one state, remembering the
--- underlying action slot so drag/drop and slot queries keep working.
--- Not usable in combat (writes secure attributes) — callers must queue.
function Generic:SetStateMacrotext(state, macrotext, underlyingSlot)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	self.state_macrotext_slots = self.state_macrotext_slots or {}
	self.state_macrotext_slots[state] = underlyingSlot
	self:SetAttribute(format("labmacrotextslot-%s", state), underlyingSlot)
	self:SetState(state, "macrotext", macrotext)
end

--- Flux Binding: restore a state to a plain action-slot mapping (undo SetStateMacrotext).
function Generic:ClearStateMacrotext(state, kind, action)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	if self.state_macrotext_slots then
		self.state_macrotext_slots[state] = nil
	end
	self:SetAttribute(format("labmacrotextslot-%s", state), nil)
	self:SetState(state, kind, action)
end

--- Underlying action slot for a macrotext state (current state when nil).
function Generic:GetMacrotextSlot(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	return self.state_macrotext_slots and self.state_macrotext_slots[state]
end

--- Flux Binding: slot the button state is showing, looking through macrotext overrides.
function Generic:GetEffectiveActionSlot(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	local kind = self.state_types and self.state_types[state]
	if kind == "action" then
		return tonumber(self.state_actions and self.state_actions[state])
	elseif kind == "macrotext" then
		return tonumber(self.state_macrotext_slots and self.state_macrotext_slots[state])
	end
	return nil
end

function Generic:UpdateState(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	self:SetAttribute(format("labtype-%s", state), self.state_types[state])
	self:SetAttribute(format("labaction-%s", state), self.state_actions[state])
	if state ~= tostring(self:GetAttribute("state")) then return end
	if self.header then
		self.header:SetFrameRef("updateButton", self)
		self.header:Execute([[
			local frame = self:GetFrameRef("updateButton")
			control:RunFor(frame, frame:GetAttribute("UpdateState"), frame:GetAttribute("state"))
		]])
	else
	-- TODO
	end
	self:UpdateAction()
end

function Generic:GetAction(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	return self.state_types[state] or "empty", self.state_actions[state]
end

function Generic:UpdateAllStates()
	for state in pairs(self.state_types) do
		self:UpdateState(state)
	end
end

function Generic:ButtonContentsChanged(state, kind, value)
	state = tostring(state)
	self.state_types[state] = kind or "empty"
	self.state_actions[state] = value
	lib.callbacks:Fire("OnButtonContentsChanged", self, state, self.state_types[state], self.state_actions[state])
	self:UpdateAction(self)
end

function Generic:DisableDragNDrop(flag)
	if InCombatLockdown() then
		error("LibActionButton-1.0: You can only toggle DragNDrop out of combat!", 2)
	end
	if flag then
		self:SetAttribute("LABdisableDragNDrop", true)
	else
		self:SetAttribute("LABdisableDragNDrop", nil)
	end
end

function Generic:AddToButtonFacade(group)
	if type(group) ~= "table" or type(group.AddButton) ~= "function" then
		error("LibActionButton-1.0:AddToButtonFacade: You need to supply a proper group to use!", 2)
	end
	group:AddButton(self)
	self.LBFSkinned = true
end

function Generic:AddToMasque(group)
	if type(group) ~= "table" or type(group.AddButton) ~= "function" then
		error("LibActionButton-1.0:AddToMasque: You need to supply a proper group to use!", 2)
	end
	group:AddButton(self, nil, "Action")
	self.MasqueSkinned = true
end

function Generic:UpdateAlpha()
	UpdateCooldown(self)
end

-----------------------------------------------------------
--- flyouts

local DiscoverFlyoutSpells, UpdateFlyoutSpells, UpdateFlyoutHandlerScripts, FlyoutUpdateQueued

if UseCustomFlyout then
	-- params: self, flyoutID
	local FlyoutHandleFunc = [[
		local SPELLFLYOUT_DEFAULT_SPACING = 4
		local SPELLFLYOUT_INITIAL_SPACING = 7
		local SPELLFLYOUT_FINAL_SPACING = 9

		local parent = self:GetAttribute("flyoutParentHandle")
		if not parent then return end

		if self:IsShown() and self:GetParent() == parent then
			self:Hide()
			return
		end

		local flyoutID = ...
		local info = LAB_FlyoutInfo[flyoutID]
		if not info then print("LAB: Flyout missing with ID " .. flyoutID) return end

		local oldParent = self:GetParent()
		self:SetParent(parent)

		local direction = parent:GetAttribute("flyoutDirection") or "UP"

		local usedSlots = 0
		local prevButton
		for slotID, slotInfo in ipairs(info.slots) do
			if slotInfo.isKnown then
				usedSlots = usedSlots + 1
				local slotButton = self:GetFrameRef("flyoutButton" .. usedSlots)

				-- set secure action attributes
				slotButton:SetAttribute("type", "spell")
				slotButton:SetAttribute("spell", slotInfo.spellID)

				-- set LAB attributes
				slotButton:SetAttribute("labtype-0", "spell")
				slotButton:SetAttribute("labaction-0", slotInfo.spellID)

				-- run LAB updates
				slotButton:CallMethod("SetStateFromHandlerInsecure", 0, "spell", slotInfo.spellID)
				slotButton:CallMethod("UpdateAction")

				slotButton:ClearAllPoints()

				if direction == "UP" then
					if prevButton then
						slotButton:SetPoint("BOTTOM", prevButton, "TOP", 0, SPELLFLYOUT_DEFAULT_SPACING)
					else
						slotButton:SetPoint("BOTTOM", self, "BOTTOM", 0, SPELLFLYOUT_INITIAL_SPACING)
					end
				elseif direction == "DOWN" then
					if prevButton then
						slotButton:SetPoint("TOP", prevButton, "BOTTOM", 0, -SPELLFLYOUT_DEFAULT_SPACING)
					else
						slotButton:SetPoint("TOP", self, "TOP", 0, -SPELLFLYOUT_INITIAL_SPACING)
					end
				elseif direction == "LEFT" then
					if prevButton then
						slotButton:SetPoint("RIGHT", prevButton, "LEFT", -SPELLFLYOUT_DEFAULT_SPACING, 0)
					else
						slotButton:SetPoint("RIGHT", self, "RIGHT", -SPELLFLYOUT_INITIAL_SPACING, 0)
					end
				elseif direction == "RIGHT" then
					if prevButton then
						slotButton:SetPoint("LEFT", prevButton, "RIGHT", SPELLFLYOUT_DEFAULT_SPACING, 0)
					else
						slotButton:SetPoint("LEFT", self, "LEFT", SPELLFLYOUT_INITIAL_SPACING, 0)
					end
				end

				slotButton:Show()
				prevButton = slotButton
			end
		end

		-- hide excess buttons
		for i = usedSlots + 1, self:GetAttribute("numFlyoutButtons") do
			local slotButton = self:GetFrameRef("flyoutButton" .. i)
			if slotButton then
				slotButton:Hide()

				-- unset its action, so it stops updating
				slotButton:SetAttribute("labtype-0", "empty")
				slotButton:SetAttribute("labaction-0", nil)

				slotButton:CallMethod("SetStateFromHandlerInsecure", 0, "empty")
				slotButton:CallMethod("UpdateAction")
			end
		end

		if usedSlots == 0 then
			self:Hide()
			return
		end

		-- calculate extent for the long dimension
		-- 3 pixel extra initial padding, button size + padding, and everything at 0.8 scale
		local extent = (3 + (45 + 4) * usedSlots) * 0.8

		self:ClearAllPoints()

		if direction == "UP" then
			self:SetPoint("BOTTOM", parent, "TOP")
			self:SetWidth(45)
			self:SetHeight(extent)
		elseif direction == "DOWN" then
			self:SetPoint("TOP", parent, "BOTTOM")
			self:SetWidth(45)
			self:SetHeight(extent)
		elseif direction == "LEFT" then
			self:SetPoint("RIGHT", parent, "LEFT")
			self:SetWidth(extent)
			self:SetHeight(45)
		elseif direction == "RIGHT" then
			self:SetPoint("LEFT", parent, "RIGHT")
			self:SetWidth(extent)
			self:SetHeight(45)
		end

		self:SetFrameStrata("DIALOG")
		self:Show()

		self:CallMethod("ShowFlyoutInsecure", direction)

		if oldParent and oldParent:GetAttribute("LABUseCustomFlyout") then
			oldParent:CallMethod("UpdateFlyout")
		end
	]]

	local SPELLFLYOUT_INITIAL_SPACING = 7
	local function ShowFlyoutInsecure(self, direction)
		self.Background.End:ClearAllPoints()
		self.Background.Start:ClearAllPoints()
		if direction == "UP" then
			self.Background.End:SetPoint("TOP", 0, SPELLFLYOUT_INITIAL_SPACING)
			SetClampedTextureRotation(self.Background.End, 0)
			SetClampedTextureRotation(self.Background.VerticalMiddle, 0)
			self.Background.Start:SetPoint("TOP", self.Background.VerticalMiddle, "BOTTOM")
			SetClampedTextureRotation(self.Background.Start, 0)
			self.Background.HorizontalMiddle:Hide()
			self.Background.VerticalMiddle:Show()
			self.Background.VerticalMiddle:ClearAllPoints()
			self.Background.VerticalMiddle:SetPoint("TOP", self.Background.End, "BOTTOM")
			self.Background.VerticalMiddle:SetPoint("BOTTOM", 0, 0)
		elseif direction == "DOWN" then
			self.Background.End:SetPoint("BOTTOM", 0, -SPELLFLYOUT_INITIAL_SPACING)
			SetClampedTextureRotation(self.Background.End, 180)
			SetClampedTextureRotation(self.Background.VerticalMiddle, 180)
			self.Background.Start:SetPoint("BOTTOM", self.Background.VerticalMiddle, "TOP")
			SetClampedTextureRotation(self.Background.Start, 180)
			self.Background.HorizontalMiddle:Hide()
			self.Background.VerticalMiddle:Show()
			self.Background.VerticalMiddle:ClearAllPoints()
			self.Background.VerticalMiddle:SetPoint("BOTTOM", self.Background.End, "TOP")
			self.Background.VerticalMiddle:SetPoint("TOP", 0, -0)
		elseif direction == "LEFT" then
			self.Background.End:SetPoint("LEFT", -SPELLFLYOUT_INITIAL_SPACING, 0)
			SetClampedTextureRotation(self.Background.End, 270)
			SetClampedTextureRotation(self.Background.HorizontalMiddle, 180)
			self.Background.Start:SetPoint("LEFT", self.Background.HorizontalMiddle, "RIGHT")
			SetClampedTextureRotation(self.Background.Start, 270)
			self.Background.VerticalMiddle:Hide()
			self.Background.HorizontalMiddle:Show()
			self.Background.HorizontalMiddle:ClearAllPoints()
			self.Background.HorizontalMiddle:SetPoint("LEFT", self.Background.End, "RIGHT")
			self.Background.HorizontalMiddle:SetPoint("RIGHT", -0, 0)
		elseif direction == "RIGHT" then
			self.Background.End:SetPoint("RIGHT", SPELLFLYOUT_INITIAL_SPACING, 0)
			SetClampedTextureRotation(self.Background.End, 90)
			SetClampedTextureRotation(self.Background.HorizontalMiddle, 0)
			self.Background.Start:SetPoint("RIGHT", self.Background.HorizontalMiddle, "LEFT")
			SetClampedTextureRotation(self.Background.Start, 90)
			self.Background.VerticalMiddle:Hide()
			self.Background.HorizontalMiddle:Show()
			self.Background.HorizontalMiddle:ClearAllPoints()
			self.Background.HorizontalMiddle:SetPoint("RIGHT", self.Background.End, "LEFT")
			self.Background.HorizontalMiddle:SetPoint("LEFT", 0, 0)
		end

		if direction == "UP" or direction == "DOWN" then
			self.Background.Start:SetWidth(47)
			self.Background.HorizontalMiddle:SetWidth(47)
			self.Background.VerticalMiddle:SetWidth(47)
			self.Background.End:SetWidth(47)
		else
			self.Background.Start:SetHeight(47)
			self.Background.HorizontalMiddle:SetHeight(47)
			self.Background.VerticalMiddle:SetHeight(47)
			self.Background.End:SetHeight(47)
		end
	end

	function UpdateFlyoutHandlerScripts()
		lib.flyoutHandler:SetAttribute("HandleFlyout", FlyoutHandleFunc)
		lib.flyoutHandler.ShowFlyoutInsecure = ShowFlyoutInsecure
	end

	function GetFlyoutHandler()
		if not lib.flyoutHandler then
			lib.flyoutHandler = CreateFrame("Frame", "LABFlyoutHandlerFrame", UIParent, "SecureHandlerBaseTemplate")
			lib.flyoutHandler.Background = CreateFrame("Frame", nil, lib.flyoutHandler)
			lib.flyoutHandler.Background:SetAllPoints()
			lib.flyoutHandler.Background.End = lib.flyoutHandler.Background:CreateTexture(nil, "BACKGROUND")
			lib.flyoutHandler.Background.End:SetAtlas("UI-HUD-ActionBar-IconFrame-FlyoutButton", true)
			lib.flyoutHandler.Background.HorizontalMiddle = lib.flyoutHandler.Background:CreateTexture(nil, "BACKGROUND")
			lib.flyoutHandler.Background.HorizontalMiddle:SetAtlas("_UI-HUD-ActionBar-IconFrame-FlyoutMidLeft", true)
			lib.flyoutHandler.Background.HorizontalMiddle:SetHorizTile(true)
			lib.flyoutHandler.Background.VerticalMiddle = lib.flyoutHandler.Background:CreateTexture(nil, "BACKGROUND")
			lib.flyoutHandler.Background.VerticalMiddle:SetAtlas("!UI-HUD-ActionBar-IconFrame-FlyoutMid", true)
			lib.flyoutHandler.Background.VerticalMiddle:SetVertTile(true)
			lib.flyoutHandler.Background.Start = lib.flyoutHandler.Background:CreateTexture(nil, "BACKGROUND")
			lib.flyoutHandler.Background.Start:SetAtlas("UI-HUD-ActionBar-IconFrame-FlyoutBottom", true)

			lib.flyoutHandler.Background.Start:SetVertexColor(0.7, 0.7, 0.7)
			lib.flyoutHandler.Background.HorizontalMiddle:SetVertexColor(0.7, 0.7, 0.7)
			lib.flyoutHandler.Background.VerticalMiddle:SetVertexColor(0.7, 0.7, 0.7)
			lib.flyoutHandler.Background.End:SetVertexColor(0.7, 0.7, 0.7)

			lib.flyoutHandler:Hide()

			-- No OnShow/OnHide scripts: any addon script here runs during the secure
			-- OnClick pre-script (flyoutHandler:Hide) and taints SpellFlyout:Hide().

			lib.flyoutHandler:SetAttribute("numFlyoutButtons", 0)
			UpdateFlyoutHandlerScripts()
		end

		return lib.flyoutHandler
	end

	-- sync flyout information to the restricted environment
	local InSync = false
	local function SyncFlyoutInfoToHandler()
		if InCombatLockdown() or InSync then return end
		InSync = true

		local maxNumSlots = 0

		local data = "LAB_FlyoutInfo = newtable();\n"
		for flyoutID, info in pairs(lib.FlyoutInfo) do
			if info.isKnown then
				local numSlots = 0
				data = data .. ("LAB_FlyoutInfo[%d] = newtable();LAB_FlyoutInfo[%d].slots = newtable();\n"):format(flyoutID, flyoutID)
				for slotID, slotInfo in ipairs(info.slots) do
					data = data .. ("LAB_FlyoutInfo[%d].slots[%d] = newtable();LAB_FlyoutInfo[%d].slots[%d].spellID = %d;LAB_FlyoutInfo[%d].slots[%d].isKnown = %s;\n"):format(flyoutID, slotID, flyoutID, slotID, slotInfo.spellID, flyoutID, slotID, slotInfo.isKnown and "true" or "nil")
					numSlots = numSlots + 1
				end

				if numSlots > maxNumSlots then
					maxNumSlots = numSlots
				end
			end
		end

		-- load generated data into the restricted environment
		GetFlyoutHandler():Execute(data)

		if maxNumSlots > #lib.FlyoutButtons then
			for i = #lib.FlyoutButtons + 1, maxNumSlots do
				local button = lib:CreateButton(i, "LABFlyoutButton" .. i, lib.flyoutHandler, nil)
				button:SetScale(0.8)
				button:Hide()

				-- disable drag and drop
				button:SetAttribute("LABdisableDragNDrop", true)

				-- link the button to the header
				lib.flyoutHandler:SetFrameRef("flyoutButton" .. i, button)
				table.insert(lib.FlyoutButtons, button)

				lib.callbacks:Fire("OnFlyoutButtonCreated", button)
			end

			lib.flyoutHandler:SetAttribute("numFlyoutButtons", #lib.FlyoutButtons)
		end

		-- hide flyout frame
		GetFlyoutHandler():Hide()

		-- ensure buttons are cleared, they will be filled when the flyout is shown
		for i = 1, #lib.FlyoutButtons do
			lib.FlyoutButtons[i]:SetState(0, "empty")
		end

		InSync = false
	end

	-- discover all possible flyouts
	function DiscoverFlyoutSpells()
		-- 300 is a safe upper limit in 10.0.2, the highest known spell is 229
		for flyoutID = 1, 300 do
			local success, _, _, numSlots, isKnown = pcall(GetFlyoutInfo, flyoutID)
			if success then
				lib.FlyoutInfo[flyoutID] = { numSlots = numSlots, isKnown = isKnown, slots = {} }
				for slotID = 1, numSlots do
					local spellID, overrideSpellID, isKnownSlot = GetFlyoutSlotInfo(flyoutID, slotID)

					-- hide empty pet slots from the flyout
					local petIndex, petName = GetCallPetSpellInfo(spellID)
					if petIndex and (not petName or petName == "") then
						isKnownSlot = false
					end

					lib.FlyoutInfo[flyoutID].slots[slotID] = { spellID = spellID, overrideSpellID = overrideSpellID, isKnown = isKnownSlot }
				end
			end
		end

		SyncFlyoutInfoToHandler()
	end

	-- update flyout information (mostly the isKnown flag)
	function UpdateFlyoutSpells()
		if InCombatLockdown() then
			FlyoutUpdateQueued = true
			return
		end

		for flyoutID, data in pairs(lib.FlyoutInfo) do
			local success, _, _, numSlots, isKnown = pcall(GetFlyoutInfo, flyoutID)
			if success then
				data.isKnown = isKnown
				for slotID = 1, numSlots do
					local spellID, overrideSpellID, isKnownSlot = GetFlyoutSlotInfo(flyoutID, slotID)

					-- hide empty pet slots from the flyout
					local petIndex, petName = GetCallPetSpellInfo(spellID)
					if petIndex and (not petName or petName == "") then
						isKnownSlot = false
					end

					data.slots[slotID].spellID = spellID
					data.slots[slotID].overrideSpellID = overrideSpellID
					data.slots[slotID].isKnown = isKnownSlot
				end
			end
		end

		SyncFlyoutInfoToHandler()
	end
end

-----------------------------------------------------------
--- frame scripts

-- copied (and adjusted) from SecureHandlers.lua
local function PickupAny(kind, target, detail, ...)
	if kind == "clear" then
		ClearCursor()
		kind, target, detail = target, detail, ...
	end

	if kind == 'action' then
		PickupAction(target)
	elseif kind == 'item' then
		C_Item.PickupItem(target)
	elseif kind == 'macro' then
		PickupMacro(target)
	elseif kind == 'petaction' then
		PickupPetAction(target)
	elseif kind == 'spell' then
		if C_Spell and C_Spell.PickupSpell then
			C_Spell.PickupSpell(target)
		else
			PickupSpell(target)
		end
	elseif kind == 'companion' then
		PickupCompanion(target, detail)
	elseif kind == 'equipmentset' then
		C_EquipmentSet.PickupEquipmentSet(target)
	end
end

function Generic:OnEnter()
	if self.config.tooltip ~= "disabled" and (self.config.tooltip ~= "nocombat" or not InCombatLockdown()) then
		UpdateTooltip(self)
	end
	if KeyBound then
		KeyBound:Set(self)
	end

	if self._state_type == "action" and self.NewActionTexture then
		ClearNewActionHighlight(self._state_action, false, false)
		UpdateNewAction(self)
	end

	if FlyoutButtonMixin and UseCustomFlyout then
		FlyoutButtonMixin.OnEnter(self)
	else
		UpdateFlyout(self)
	end
end

function Generic:OnLeave()
	if FlyoutButtonMixin and UseCustomFlyout then
		FlyoutButtonMixin.OnLeave(self)
	else
		UpdateFlyout(self)
	end

	if GameTooltip:IsForbidden() then return end
	-- Binder sits on top of the button in LibKeyBound mode; this frame gets OnLeave while tooltip is still valid.
	if IsBindingModeTooltipOwned() then return end
	GameTooltip:Hide()
end

-- Insecure drag handler to allow clicking on the button with an action on the cursor
-- to place it on the button. Like action buttons work.
function Generic:PreClick()
	if self._state_type == "action" or self._state_type == "pet"
	   or InCombatLockdown() or self:GetAttribute("LABdisableDragNDrop")
	then
		return
	end
	-- check if there is actually something on the cursor
	local kind, value, _subtype = GetCursorInfo()
	if not (kind and value) then return end
	self._old_type = self._state_type
	if self._state_type and self._state_type ~= "empty" then
		self._old_type = self._state_type
		self:SetAttribute("type", "empty")
		--self:SetState(nil, "empty", nil)
	end
	self._receiving_drag = true
end

local function formatHelper(input)
	if type(input) == "string" then
		return format("%q", input)
	else
		return tostring(input)
	end
end

function Generic:PostClick(button, down)
	UpdateButtonState(self)
	UpdateFlyout(self, down)
	if self._receiving_drag and not InCombatLockdown() then
		if self._old_type then
			self:SetAttribute("type", self._old_type)
			self._old_type = nil
		end
		local oldType, oldAction = self._state_type, self._state_action
		local kind, data, subtype, extra = GetCursorInfo()
		self.header:SetFrameRef("updateButton", self)
		self.header:Execute(format([[
			local frame = self:GetFrameRef("updateButton")
			control:RunFor(frame, frame:GetAttribute("OnReceiveDrag"), %s, %s, %s, %s)
			control:RunFor(frame, frame:GetAttribute("UpdateState"), %s)
		]], formatHelper(kind), formatHelper(data), formatHelper(subtype), formatHelper(extra), formatHelper(self:GetAttribute("state"))))
		PickupAny("clear", oldType, oldAction)
	end
	self._receiving_drag = nil

	if self._state_type == "action" and lib.ACTION_HIGHLIGHT_MARKS[self._state_action] then
		ClearNewActionHighlight(self._state_action, false, false)
	end

	if down and IsMouseButtonDown() then
		self:RegisterEvent("GLOBAL_MOUSE_UP")
	end
end

-----------------------------------------------------------
--- configuration

local function merge(target, source, default)
	for k,v in pairs(default) do
		if type(v) ~= "table" then
			if source and source[k] ~= nil then
				target[k] = source[k]
			else
				target[k] = v
			end
		else
			if type(target[k]) ~= "table" then target[k] = {} else wipe(target[k]) end
			merge(target[k], type(source) == "table" and source[k], v)
		end
	end
	return target
end

local function UpdateTextElement(element, config, defaultFont)
	element:SetFont(config.font.font or defaultFont, config.font.size, config.font.flags or "")
	element:SetJustifyH(config.justifyH)
	element:ClearAllPoints()
	element:SetPoint(config.position.anchor, element:GetParent(), config.position.relAnchor or config.position.anchor, config.position.offsetX or 0, config.position.offsetY or 0)

	element:SetVertexColor(unpack(config.color))
end

local function UpdateTextElements(button)
	UpdateTextElement(button.HotKey, button.config.text.hotkey, NumberFontNormalSmallGray:GetFont())
	UpdateTextElement(button.Count, button.config.text.count, NumberFontNormal:GetFont())
	UpdateTextElement(button.Name, button.config.text.macro, GameFontHighlightSmallOutline:GetFont())
end

function Generic:UpdateConfig(config)
	if config and type(config) ~= "table" then
		error("LibActionButton-1.0: UpdateConfig requires a valid configuration!", 2)
	end
	local oldconfig = self.config
	self.config = {}
	-- merge the two configs
	merge(self.config, config, DefaultConfig)

	if self.config.outOfRangeColoring == "button" or (oldconfig and oldconfig.outOfRangeColoring == "button") then
		UpdateUsable(self, true)
	end
	if self.config.outOfRangeColoring == "hotkey" then
		self.outOfRange = nil
	end

	if self.config.hideElements.macro then
		self.Name:Hide()
	else
		self.Name:Show()
	end

	self:SetAttribute("flyoutDirection", self.config.flyoutDirection)

	UpdateCooldownNumberHidden(self)
	UpdateTextElements(self)
	UpdateHotkeys(self)
	UpdateGrid(self)
	self:UpdateAction(true)
	if not supportsAnyDown then
		self:RegisterForClicks(self.config.clickOnDown and "AnyDown" or "AnyUp")
	end
end

-----------------------------------------------------------
--- event handler

function ForAllButtons(method, onlyWithAction)
	assert(type(method) == "function")
	for button in next, (onlyWithAction and ActiveButtons or ButtonRegistry) do
		method(button)
	end
end

function ForAllButtonsWithSpell(spellID, method, ...)
	assert(type(method) == "function")
	-- Full ActiveButtons scan (not fluxSpellIdToButtons index): paging can leave the index
	-- pointing at a hidden minirow while the visible main/mini row shows the casting spell.
	for button in next, ActiveButtons do
		local sid = button.GetSpellId and button:GetSpellId()
		if sid and AreSpellsEquivalent(sid, spellID) then
			method(button, ...)
		end
	end
end

function InitializeEventHandler()
	lib.eventFrame:SetScript("OnEvent", OnEvent)
	lib.eventFrame:RegisterEvent("CVAR_UPDATE")
	lib.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	lib.eventFrame:RegisterEvent("ACTIONBAR_SHOWGRID")
	lib.eventFrame:RegisterEvent("ACTIONBAR_HIDEGRID")
	--lib.eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	--lib.eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	lib.eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	lib.eventFrame:RegisterEvent("UPDATE_BINDINGS")
	lib.eventFrame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
	lib.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	-- Open form storm early (bonus bar remaps often precede shapeshift form event).
	pcall(lib.eventFrame.RegisterEvent, lib.eventFrame, "UPDATE_BONUS_ACTIONBAR")
	pcall(lib.eventFrame.RegisterEvent, lib.eventFrame, "ACTIONBAR_PAGE_CHANGED")
	lib.eventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	if not WoWClassic and not WoWBCC then
		lib.eventFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
	end

	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	lib.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	lib.eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	lib.eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
	lib.eventFrame:RegisterEvent("TRADE_SKILL_CLOSE")

	lib.eventFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
	lib.eventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
	lib.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	lib.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	lib.eventFrame:RegisterEvent("START_AUTOREPEAT_SPELL")
	lib.eventFrame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	lib.eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

	lib.eventFrame:RegisterEvent("PET_STABLE_UPDATE")
	lib.eventFrame:RegisterEvent("PET_STABLE_SHOW")
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_ICON")
	if not WoWClassic and not WoWBCC then
		if not WoWWrath then
			lib.eventFrame:RegisterEvent("ARCHAEOLOGY_CLOSED")
			lib.eventFrame:RegisterEvent("UPDATE_SUMMONPETS_ACTION")
			lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
			lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
		end
		lib.eventFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
		lib.eventFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
		lib.eventFrame:RegisterEvent("COMPANION_UPDATE")
	end

	-- FLUX MODIFICATION: spell-learn notification event name differs by client.
	-- Retail 11.0+ deprecated LEARNED_SPELL_IN_TAB in favor of LEARNED_SPELL_IN_SKILL_LINE.
	-- Classic / Anniversary still use LEARNED_SPELL_IN_TAB. Do not gate on Midnight/TW
	-- TOC alone — register whichever exists (FluxSafeRegisterEvent probes each).
	if FluxSafeRegisterEvent then
		FluxSafeRegisterEvent(lib.eventFrame, "LEARNED_SPELL_IN_SKILL_LINE")
		FluxSafeRegisterEvent(lib.eventFrame, "LEARNED_SPELL_IN_TAB")
	else
		pcall(function() lib.eventFrame:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE") end)
		pcall(function() lib.eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB") end)
	end

	-- With those two, do we still need the ACTIONBAR equivalents of them?
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
	lib.eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

	-- Binding macrotext hosts are not action-typed, so ACTIONBAR_SLOT_CHANGED alone
	-- can miss bag-stack changes; refresh their Count on delayed bag updates.
	if FluxSafeRegisterEvent then
		FluxSafeRegisterEvent(lib.eventFrame, "BAG_UPDATE_DELAYED")
	else
		pcall(function() lib.eventFrame:RegisterEvent("BAG_UPDATE_DELAYED") end)
	end

	lib.eventFrame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
	lib.eventFrame:RegisterEvent("LOSS_OF_CONTROL_UPDATE")

	if WoWRetail then
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
		-- Reticle events are DF-era; pre-DF clients may not define them (pcall: do not use
		-- FluxSafeRegisterUnitEvent here — it validates via RegisterEvent, which fails for unit events).
		pcall(function()
			lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_TARGET", "player")
		end)
		pcall(function()
			lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_CLEAR", "player")
		end)
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
		lib.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
	end

	if UseCustomFlyout then
		lib.eventFrame:RegisterEvent("PLAYER_LOGIN")
		lib.eventFrame:RegisterEvent("SPELLS_CHANGED")
		lib.eventFrame:RegisterEvent("SPELL_FLYOUT_UPDATE")
	end

	do
		local reg = _G.FluxSafeRegisterEvent
		if reg then
			lib._fluxActionUsableChangedRegistered = reg(lib.eventFrame, "ACTION_USABLE_CHANGED")
		else
			lib._fluxActionUsableChangedRegistered = pcall(function()
				lib.eventFrame:RegisterEvent("ACTION_USABLE_CHANGED")
			end)
		end
	end

	lib.eventFrame:Show()
	-- Demand-drive OnUpdate: start disarmed; ClassifyRange / flash / target events re-arm.
	lib._fluxOnUpdateArmed = false
	lib.eventFrame:SetScript("OnUpdate", nil)

	if UseCustomFlyout and IsLoggedIn() then
		DiscoverFlyoutSpells()
	end

	if EventRegistry and AssistedCombatManager then
		local fluxAPI = rawget(_G, "FLUX_API")
		if fluxAPI and type(fluxAPI.ApplyAssistedCombatCustomActionBarCompat) == "function" then
			fluxAPI.ApplyAssistedCombatCustomActionBarCompat()
		end

		EventRegistry:RegisterCallback("AssistedCombatManager.OnSetActionSpell", function(o)
			-- May not be the best way, but it is a unique string which is what the event system cares about
			OnEvent(lib.eventFrame, "AssistedCombatManager.OnSetActionSpell")
		end, lib.eventFrame)

		EventRegistry:RegisterCallback("AssistedCombatManager.OnAssistedHighlightSpellChange", function(o)
			OnEvent(lib.eventFrame, "AssistedCombatManager.OnAssistedHighlightSpellChange")
		end, lib.eventFrame)

		EventRegistry:RegisterCallback("AssistedCombatManager.OnSetUseAssistedHighlight", function(o)
			OnEvent(lib.eventFrame, "AssistedCombatManager.OnAssistedHighlightSpellChange")
		end, lib.eventFrame)

		if hooksecurefunc and not AssistedCombatManager._fluxLabHighlightBuildHooked then
			AssistedCombatManager._fluxLabHighlightBuildHooked = true
			-- Defer merge: BuildAssistedHighlight runs during secure action-button clicks;
			-- merging synchronously (even restoring button.action) blocked UseAction().
			hooksecurefunc(AssistedCombatManager, "BuildAssistedHighlightCandidateActionButtonsList", function(mgr)
				lib.FluxScheduleLabAssistedHighlightMerge(mgr)
			end)
		end
	end
end

local _lastFormUpdate = GetTime()

-- Bartended perf: skip full Update when slot content unchanged (texture/action);
-- still refresh stack counts for consumables looted into an existing slot.
function lib.FluxAssistLightweightRefresh(button)
	ClearNewActionHighlight(button._state_action, true, false)
	local texture = button:GetTexture()
	if texture then
		button.icon:SetTexture(texture)
		button.icon:Show()
	else
		button.icon:Hide()
	end
	UpdateUsable(button, true)
	UpdateCooldown(button)
	UpdateCount(button)
	UpdateAssistedCombatRotationFrame(button)
	if button.config.assistedHighlight and AssistedCombatManager then
		UpdatedAssistedHighlightFrame(button)
	end
end

function lib.FluxLABApplySlotChangedButton(button)
	local highlightSlot = (button._state_type == "action") and button._state_action
		or (button.GetMacrotextSlot and button:GetMacrotextSlot())
	if highlightSlot then
		ClearNewActionHighlight(highlightSlot, true, false)
	end
	local oldTex = button.icon and button.icon:GetTexture()
	local newTex = button:GetTexture()
	local hadAction = (ActiveButtons[button] ~= nil)
	local hasAction = button:HasAction()
	if oldTex ~= newTex or hadAction ~= hasAction then
		if lib.assistedCombatButtons[button] and hadAction and hasAction and oldTex ~= newTex then
			lib.FluxAssistLightweightRefresh(button)
			FluxLABSyncSlotButtonMap(button)
			FluxLABSyncSpellIdIndex(button)
			FluxLABSyncFlyoutActionIndex(button)
			FluxLABSyncAssistedCombatIndex(button)
		else
			Update(button)
		end
	else
		UpdateCount(button)
	end
end

-- Flux: ACTIONBAR_SLOT_CHANGED with arg1==0 updates every registered LAB action button. Assisted combat
-- rotation (Blizzard template OnUpdate -> C_ActionBar.ForceUpdateAction) can fire slot-0 bursts in one frame.
-- Coalesce to a single full refresh per tick via After(0). If lag remains, try raising CVar assistedCombatIconUpdateRate.
function FlushActionBarSlotChangedAll()
	lib.fluxDefer.actionBarSlotChangedAllScheduled = false
	if not lib.fluxDefer.pendingActionBarSlotChangedAll then
		return
	end
	lib.fluxDefer.pendingActionBarSlotChangedAll = false
	for button in next, ButtonRegistry do
		local st = button._state_type
		if st == "action" or st == "macrotext" then
			lib.FluxLABApplySlotChangedButton(button)
		end
	end
end

-- Flux: Single-slot ACTIONBAR_SLOT_CHANGED can spam (e.g. macro conditional churn). Without coalescing, each
-- firing runs a full Update(button) for that slot. Merge pending slots to one deferred flush per tick.
-- Disable immediate per-event behavior: _G.FluxLABDeferActionBarSlotChangedSingle = false
-- During ExtraButton form/power storm (Druid shapeshift): texture-only mid-storm; full Apply after settle.
function FlushActionBarSlotChangedSlots()
	lib.fluxDefer.actionBarSlotChangedSlotsScheduled = false
	if not next(lib.fluxDefer.pendingActionBarSlotChangedSlots) then
		return
	end
	local slots = lib.fluxDefer.pendingActionBarSlotChangedSlots
	lib.fluxDefer.pendingActionBarSlotChangedSlots = {}
	local FE = _G.FluxButtonEvents
	local formStorm = FE and FE.IsFormStormActive and FE.IsFormStormActive()
	for slotKey in pairs(slots) do
		local slot = tonumber(slotKey)
		if slot then
			-- Remember for one full Apply after form storm ends.
			if formStorm then
				lib.fluxDefer.pendingFormStormSlots = lib.fluxDefer.pendingFormStormSlots or {}
				lib.fluxDefer.pendingFormStormSlots[slot] = true
			end
			local t = lib.slotToActionButtons[slot]
			local function touch(button)
				if not button then return end
				local st = button._state_type
				if st ~= "action" and st ~= "macrotext" then return end
				if formStorm then
					local texture = button.GetTexture and button:GetTexture()
					if texture and button.icon then
						button.icon:SetTexture(texture)
					end
				else
					lib.FluxLABApplySlotChangedButton(button)
				end
			end
			local function buttonMatchesSlot(button)
				if not button then return false end
				if button._state_type == "action" then
					return tonumber(button._state_action) == slot
				elseif button._state_type == "macrotext" and button.GetMacrotextSlot then
					return tonumber(button:GetMacrotextSlot()) == slot
				end
				return false
			end
			if t and next(t) then
				for button in next, t do
					if buttonMatchesSlot(button) then
						touch(button)
					end
				end
			else
				for button in next, ButtonRegistry do
					if buttonMatchesSlot(button) then
						touch(button)
					end
				end
			end
		end
	end
end

local function FlushFormStormPendingSlotsFull()
	local pending = lib.fluxDefer.pendingFormStormSlots
	if not pending or not next(pending) then
		return
	end
	lib.fluxDefer.pendingFormStormSlots = {}
	for slotKey in pairs(pending) do
		lib.fluxDefer.pendingActionBarSlotChangedSlots[tonumber(slotKey) or slotKey] = true
	end
	FlushActionBarSlotChangedSlots()
end

local function LABBeginFormStormIfAvailable(duration)
	local FE = _G.FluxButtonEvents
	if FE and FE.BeginFormStorm then
		FE.BeginFormStorm(duration or 0.55)
	end
end

local function LABIsFormStormActive()
	local FE = _G.FluxButtonEvents
	return FE and FE.IsFormStormActive and FE.IsFormStormActive()
end

local function LABNoteBonusBarOffset()
	local bonus = (GetBonusBarOffset and GetBonusBarOffset()) or 0
	if bonus ~= (lib._fluxLastBonusOffset or -999) then
		lib._fluxLastBonusOffset = bonus
		LABBeginFormStormIfAvailable(0.55)
		return true
	end
	return false
end

local function LABNoteShapeshiftForm()
	local form = (GetShapeshiftForm and GetShapeshiftForm()) or 0
	if form ~= (lib._fluxLastShapeshiftForm or -999) then
		lib._fluxLastShapeshiftForm = form
		LABBeginFormStormIfAvailable(0.55)
		return true
	end
	return false
end

local function FlushEquipItemRefreshDeferred()
	lib.fluxDefer.equipItemRefreshScheduled = false
	if not lib.fluxDefer.pendingEquipItemRefresh then
		return
	end
	lib.fluxDefer.pendingEquipItemRefresh = false
	for button in next, ActiveButtons do
		if button._state_type == "item" then
			Update(button)
		end
	end
end

local function ScheduleEquipItemRefresh()
	lib.fluxDefer.pendingEquipItemRefresh = true
	if lib.fluxDefer.equipItemRefreshScheduled then
		return
	end
	lib.fluxDefer.equipItemRefreshScheduled = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0.15, FlushEquipItemRefreshDeferred)
	else
		FlushEquipItemRefreshDeferred()
	end
end

-- Flux: ACTIONBAR_UPDATE_COOLDOWN often pairs with slot/usable churn (macro conditionals). Each firing
-- updated every action button; coalesce to one deferred pass per tick. Disable: _G.FluxLABDeferActionBarUpdateCooldown = false
local function FlushActionBarCooldownDeferred()
	lib.fluxDefer.actionBarCooldownFlushScheduled = false
	if not lib.fluxDefer.pendingActionBarCooldownFlush then
		return
	end
	lib.fluxDefer.pendingActionBarCooldownFlush = false
	for button in next, ActionButtons do
		UpdateCooldown(button)
		if GameTooltip_GetOwnerForbidden() == button then
			UpdateTooltip(button)
		end
	end
end

local function ScheduleActionBarCooldownFlush()
	if _G.FluxLABDeferActionBarUpdateCooldown == false then
		for button in next, ActionButtons do
			UpdateCooldown(button)
			if GameTooltip_GetOwnerForbidden() == button then
				UpdateTooltip(button)
			end
		end
		return
	end
	lib.fluxDefer.pendingActionBarCooldownFlush = true
	if lib.fluxDefer.actionBarCooldownFlushScheduled then
		return
	end
	lib.fluxDefer.actionBarCooldownFlushScheduled = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0, FlushActionBarCooldownDeferred)
	else
		FlushActionBarCooldownDeferred()
	end
end

-- Bartended perf: coalesce burst SPELL_UPDATE_USABLE / SPELL_UPDATE_COOLDOWN /
-- LOSS_OF_CONTROL / SPELL_UPDATE_CHARGES to one deferred pass per frame.
local function FlushSpellUsableDeferred()
	lib._spellUsablePending = nil
	for button in next, NonActionButtons do
		UpdateUsable(button, true)
	end
end

local function ScheduleSpellUsableFlush()
	if lib._spellUsablePending then
		return
	end
	lib._spellUsablePending = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0, FlushSpellUsableDeferred)
	else
		FlushSpellUsableDeferred()
	end
end

local function FlushSpellCooldownDeferred()
	lib._spellCooldownPending = nil
	for button in next, NonActionButtons do
		UpdateCooldown(button)
		if GameTooltip_GetOwnerForbidden() == button then
			UpdateTooltip(button)
		end
	end
end

local function ScheduleSpellCooldownFlush()
	if lib._spellCooldownPending then
		return
	end
	lib._spellCooldownPending = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0, FlushSpellCooldownDeferred)
	else
		FlushSpellCooldownDeferred()
	end
end

local function FlushLossOfControlDeferred()
	lib._locUpdatePending = nil
	for button in next, ActiveButtons do
		UpdateCooldown(button)
		if GameTooltip_GetOwnerForbidden() == button then
			UpdateTooltip(button)
		end
	end
end

local function ScheduleLossOfControlFlush()
	if lib._locUpdatePending then
		return
	end
	lib._locUpdatePending = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0, FlushLossOfControlDeferred)
	else
		FlushLossOfControlDeferred()
	end
end

local function FlushChargeUpdateDeferred()
	lib._chargeUpdatePending = nil
	ForAllButtons(UpdateCount, true)
end

local function ScheduleChargeUpdateFlush()
	if lib._chargeUpdatePending then
		return
	end
	lib._chargeUpdatePending = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0, FlushChargeUpdateDeferred)
	else
		FlushChargeUpdateDeferred()
	end
end

-- Binding macrotext hosts: bag stack changes do not always retarget ACTIONBAR_SLOT_CHANGED
-- onto the override button; coalesce UpdateCount for the live macrotext set.
local function FlushMacrotextCountDeferred()
	lib._macrotextCountPending = nil
	for button in next, lib.fluxMacrotextButtons do
		if button and ActiveButtons[button] then
			UpdateCount(button)
		end
	end
end

local function ScheduleMacrotextCountFlush()
	if lib._macrotextCountPending then
		return
	end
	if not next(lib.fluxMacrotextButtons) then
		return
	end
	lib._macrotextCountPending = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0, FlushMacrotextCountDeferred)
	else
		FlushMacrotextCountDeferred()
	end
end

local function FlushAssistedHighlightDeferred()
	lib._assistHighlightPending = nil
	local mgr = AssistedCombatManager
	local candidates = mgr and mgr.assistedHighlightCandidateActionButtons
	if candidates then
		for button in next, candidates do
			if button and ActiveButtons[button] then
				UpdatedAssistedHighlightFrame(button)
			end
		end
		return
	end
	local spellID = mgr and mgr.lastNextCastSpellID
	if spellID then
		local direct = lib.fluxSpellIdToButtons[spellID]
		if direct then
			for button in next, direct do
				UpdatedAssistedHighlightFrame(button)
			end
		end
	end
end

local function ScheduleAssistedHighlightFlush()
	if lib._assistHighlightPending then
		return
	end
	lib._assistHighlightPending = true
	_G.FluxLABAssistHighlightFiredThisTick = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			_G.FluxLABAssistHighlightFiredThisTick = false
			FlushAssistedHighlightDeferred()
		end)
	else
		_G.FluxLABAssistHighlightFiredThisTick = false
		FlushAssistedHighlightDeferred()
	end
end

function OnEvent(frame, event, arg1, ...)
	if event == "PLAYER_LOGIN" then
		if UseCustomFlyout then
			DiscoverFlyoutSpells()
		end
	elseif event == "CVAR_UPDATE" then
		if arg1 == "countdownForCooldowns" then
			ForAllButtons(UpdateCooldownNumberHidden)
		end
	elseif event == "SPELLS_CHANGED" or event == "SPELL_FLYOUT_UPDATE" then
		if UseCustomFlyout then
			UpdateFlyoutSpells()
		end
	elseif (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player")
		or event == "LEARNED_SPELL_IN_TAB"
		or event == "LEARNED_SPELL_IN_SKILL_LINE" then
		local tooltipOwner = GameTooltip_GetOwnerForbidden()
		if tooltipOwner and ButtonRegistry[tooltipOwner] then
			tooltipOwner:SetTooltip()
		end
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		-- Open form storm as soon as bonus-bar / form remaps begin (often before UPDATE_SHAPESHIFT_FORM).
		LABNoteBonusBarOffset()
		LABNoteShapeshiftForm()
		if arg1 == 0 then
			if lib._fluxAssistForceUpdateBurst then
				-- Assist rotation ForceUpdateAction; narrow single-slot flush already scheduled.
			elseif LABIsFormStormActive() then
				-- Full-bar slot-0 during shapeshift: defer to post-storm settle.
				lib.fluxDefer.pendingActionBarSlotChangedAll = true
			else
				lib.fluxDefer.pendingActionBarSlotChangedAll = true
				if not lib.fluxDefer.actionBarSlotChangedAllScheduled then
					lib.fluxDefer.actionBarSlotChangedAllScheduled = true
					if C_Timer and C_Timer.After then
						C_Timer.After(0, FlushActionBarSlotChangedAll)
					else
						FlushActionBarSlotChangedAll()
					end
				end
			end
		else
			if _G.FluxLABDeferActionBarSlotChangedSingle == false then
				if not LABIsFormStormActive() then
					for button in next, ButtonRegistry do
						local matches = false
						if button._state_type == "action" then
							matches = arg1 == tonumber(button._state_action)
						elseif button._state_type == "macrotext" and button.GetMacrotextSlot then
							matches = arg1 == tonumber(button:GetMacrotextSlot())
						end
						if matches then
							if button._state_type == "action" then
								ClearNewActionHighlight(button._state_action, true, false)
							end
							Update(button)
						end
					end
				else
					local s = tonumber(arg1)
					if s then
						lib.fluxDefer.pendingActionBarSlotChangedSlots[s] = true
					end
				end
			else
				local s = tonumber(arg1)
				if s then
					lib.fluxDefer.pendingActionBarSlotChangedSlots[s] = true
					if lib._fluxAssistForceUpdateBurst
						and C_ActionBar and C_ActionBar.IsAssistedCombatAction
						and C_ActionBar.IsAssistedCombatAction(s) then
						-- Flush already scheduled by lib.FluxForceUpdateAssistedActionSlotIfNeeded.
					elseif LABIsFormStormActive() then
						-- Accumulate only; texture flush once per frame via After(0) still OK (light path).
						if not lib.fluxDefer.actionBarSlotChangedSlotsScheduled then
							lib.fluxDefer.actionBarSlotChangedSlotsScheduled = true
							if C_Timer and C_Timer.After then
								C_Timer.After(0, function()
									lib.fluxDefer.actionBarSlotChangedSlotsScheduled = false
									FlushActionBarSlotChangedSlots()
								end)
							else
								lib.fluxDefer.actionBarSlotChangedSlotsScheduled = false
								FlushActionBarSlotChangedSlots()
							end
						end
					elseif not lib.fluxDefer.actionBarSlotChangedSlotsScheduled then
						lib.fluxDefer.actionBarSlotChangedSlotsScheduled = true
						if C_Timer and C_Timer.After then
							C_Timer.After(0, function()
								lib.fluxDefer.actionBarSlotChangedSlotsScheduled = false
								FlushActionBarSlotChangedSlots()
							end)
						else
							lib.fluxDefer.actionBarSlotChangedSlotsScheduled = false
							FlushActionBarSlotChangedSlots()
						end
					end
				end
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_VEHICLE_ACTIONBAR" then
		ForAllButtons(Update)
	elseif event == "UPDATE_SHAPESHIFT_FORM" then
		LABBeginFormStormIfAvailable(0.55)
		-- XXX: throttle these updates since Blizzard broke the event and its now extremely spammy in some clients
		local _time = GetTime()
		if (_time - _lastFormUpdate) < 1 then
			return
		end
		_lastFormUpdate = _time

		-- the attack icon can change when shapeshift form changes, so need to do a quick update here
		-- for performance reasons don't run full updates here, though
		for button in next, ActiveButtons do
			local texture = button:GetTexture()
			if texture then
				button.icon:SetTexture(texture)
			end
		end
	elseif event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" then
		LABBeginFormStormIfAvailable(0.55)
		LABNoteBonusBarOffset()
	elseif event == "ACTIONBAR_SHOWGRID" then
		ShowGrid()
	elseif event == "ACTIONBAR_HIDEGRID" then
		HideGrid()
	elseif event == "UPDATE_BINDINGS" or event == "GAME_PAD_ACTIVE_CHANGED" then
		if event == "UPDATE_BINDINGS"
			and _G.FluxDefaultSettings
			and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
			and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
			lib._fluxDeferredHotkeyUpdate = true
			return
		end
		if event == "UPDATE_BINDINGS" then
			-- Coalesce single-key Settings edits (ForAllButtons is costly with many LAB buttons).
			if lib._fluxHotkeyRefreshPending then
				return
			end
			lib._fluxHotkeyRefreshPending = true
			if C_Timer and C_Timer.After then
				C_Timer.After(0.12, function()
					lib._fluxHotkeyRefreshPending = nil
					if _G.FluxDefaultSettings
						and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh
						and _G.FluxDefaultSettings.ShouldSuppressBindingRefresh() then
						lib._fluxDeferredHotkeyUpdate = true
						return
					end
					lib._fluxDeferredHotkeyUpdate = nil
					ForAllButtons(UpdateHotkeys)
				end)
				return
			end
		end
		lib._fluxDeferredHotkeyUpdate = nil
		ForAllButtons(UpdateHotkeys)
	elseif event == "PLAYER_TARGET_CHANGED"
		or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
		UpdateRangeTimer()
		if lib.FluxLABSyncOnUpdateArm then lib.FluxLABSyncOnUpdateArm() end
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		-- Coalesce range sampling across rapid mouseover sweeps.
		if lib.UpdateRangeTimerCoalesced then
			lib.UpdateRangeTimerCoalesced()
		else
			UpdateRangeTimer()
		end
		if lib.FluxLABSyncOnUpdateArm then lib.FluxLABSyncOnUpdateArm() end
	elseif event == "ACTIONBAR_UPDATE_STATE" then
		-- Coalesce with paging / condition-flip latch (target/macro storms).
		-- Also suppress during ExtraButton form/power storm (Druid mana↔energy).
		local FE = _G.FluxButtonEvents
		if (FE and FE.IsFormStormActive and FE.IsFormStormActive()) or _G._fluxPagingInProgress then
			-- Keep pending so CatchUpUsableRange / form-storm settle can sync after.
			lib.fluxDefer.pendingActionBarUpdateState = true
			return
		end
		if _G.FluxLABDeferActionBarUpdateState == false then
			for button in next, ActionButtonsNonUI do
				UpdateButtonState(button)
			end
		else
			lib.fluxDefer.pendingActionBarUpdateState = true
			if not lib.fluxDefer.fluxActionBarUpdateStateDeferTimer and C_Timer and C_Timer.After then
				lib.fluxDefer.fluxActionBarUpdateStateDeferTimer = true
				C_Timer.After(0, function()
					lib.fluxDefer.fluxActionBarUpdateStateDeferTimer = false
					if not lib.fluxDefer.pendingActionBarUpdateState then
						return
					end
					local FE2 = _G.FluxButtonEvents
					if (FE2 and FE2.IsFormStormActive and FE2.IsFormStormActive()) or _G._fluxPagingInProgress then
						-- Leave pending true; form-storm / CatchUp flushes after latch clear.
						return
					end
					lib.fluxDefer.pendingActionBarUpdateState = false
					for button in next, ActionButtonsNonUI do
						UpdateButtonState(button)
					end
				end)
			else
				for button in next, ActionButtonsNonUI do
					UpdateButtonState(button)
				end
			end
		end
	elseif event == "ACTION_USABLE_CHANGED" then
		lib._fluxDbgGranularUsableEv = lib._fluxDbgGranularUsableEv + 1
		FluxLABBeginUsableBatch()
		local changes = NormalizeActionUsableChanges(arg1, ...)
		local bySlot = {}
		for i = 1, #changes do
			local ch = changes[i]
			local slot = tonumber(ch.slot or ch.actionSlot or ch.actionBarSlot or ch.action)
			if slot then
				bySlot[slot] = ch
			end
		end
		for slot, ch in pairs(bySlot) do
			lib.fluxDefer.granularUsableSlotsThisTick[slot] = true
			local usable = ch.usable
			if usable == nil and ch.isUsable ~= nil then
				usable = ch.isUsable
			end
			local noMana = ch.noMana or ch.notEnoughMana
			local ginfo = { usable = usable, noMana = noMana }
			local t = lib.slotToActionButtons[slot]
			if t then
				for button in next, t do
					UpdateUsable(button, true, ginfo)
				end
			end
		end
	elseif ((event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and (arg1 == "player")) or
		((event == "COMPANION_UPDATE") and (arg1 == "MOUNT")) then
		ForAllButtons(UpdateButtonState, true)
	elseif event == "ACTIONBAR_UPDATE_USABLE" then
		-- Always refresh all ActionButtons (Presence of Mind etc.). Do not replace
		-- the full flush with mouseover-macro-only when UnitExists("mouseover").
		-- Druid form/power storms: defer full-bar UpdateUsable to form-storm settle.
		local FE = _G.FluxButtonEvents
		if FE and FE.IsFormStormActive and FE.IsFormStormActive() then
			lib.fluxDefer.pendingBroadcastUsable = true
			return
		end
		ScheduleFlushBroadcastUsable()
		if FlushMouseoverActionUsable
			and UnitExists("mouseover")
			and lib.fluxMouseoverMacroButtons
			and next(lib.fluxMouseoverMacroButtons) then
			if FluxMouseoverRefresh and FluxMouseoverRefresh.Request then
				FluxMouseoverRefresh.Request("LAB", FlushMouseoverActionUsable)
			else
				FlushMouseoverActionUsable()
			end
		end
	elseif event == "SPELL_UPDATE_USABLE" then
		local FE = _G.FluxButtonEvents
		if FE and FE.IsFormStormActive and FE.IsFormStormActive() then
			-- Non-action spell buttons only; still skip during form storm.
			lib.fluxDefer.pendingSpellUsable = true
			return
		end
		ScheduleSpellUsableFlush()
	elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
		-- Flux perf T2.1: coalesce a burst of PLAYER_MOUNT_DISPLAY_CHANGED
		-- events (mount / dismount can fire several in quick succession, and
		-- every one used to scan ActiveButtons). Schedule a single flush per
		-- frame that runs through all ActiveButtons once.
		if not lib._fluxMountPending then
			lib._fluxMountPending = true
			C_Timer.After(0, function()
				lib._fluxMountPending = false
				for button in next, ActiveButtons do
					UpdateUsable(button, true)
				end
			end)
		end
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
		ScheduleActionBarCooldownFlush()
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		ScheduleSpellCooldownFlush()
	elseif event == "LOSS_OF_CONTROL_ADDED" or event == "LOSS_OF_CONTROL_UPDATE" then
		ScheduleLossOfControlFlush()
	elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE"  or event == "ARCHAEOLOGY_CLOSED" then
		ForAllButtons(UpdateButtonState, true)
	elseif event == "PLAYER_ENTER_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				StartFlash(button)
			end
		end
	elseif event == "PLAYER_LEAVE_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				StopFlash(button)
			end
		end

		if UseCustomFlyout and FlyoutUpdateQueued then
			UpdateFlyoutSpells()
			FlyoutUpdateQueued = nil
		end
	elseif event == "START_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button:IsAutoRepeat() then
				StartFlash(button)
			end
		end
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button.flashing == 1 and not button:IsAttack() then
				StopFlash(button)
			end
		end
	elseif event == "PET_STABLE_UPDATE" or event == "PET_STABLE_SHOW" then
		ForAllButtons(Update)

		if event == "PET_STABLE_UPDATE" and UseCustomFlyout then
			UpdateFlyoutSpells()
		end
	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
		-- Flux perf T2.1: use spellId -> buttons index + flyout spell map instead
		-- of scanning every ActiveButton.
		local direct = lib.fluxSpellIdToButtons[arg1]
		if direct then
			for button in next, direct do
				ShowOverlayGlow(button)
			end
		end
		local flyoutDirect = lib.fluxFlyoutSpellButtons[arg1]
		if flyoutDirect then
			for button in next, flyoutDirect do
				ShowOverlayGlow(button)
			end
		end
	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
		local direct = lib.fluxSpellIdToButtons[arg1]
		if direct then
			for button in next, direct do
				HideOverlayGlow(button)
			end
		end
		local flyoutDirect = lib.fluxFlyoutSpellButtons[arg1]
		if flyoutDirect then
			for button in next, flyoutDirect do
				HideOverlayGlow(button)
			end
		end
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		ScheduleEquipItemRefresh()
	elseif event == "BAG_UPDATE_DELAYED" then
		ScheduleMacrotextCountFlush()
	elseif event == "SPELL_UPDATE_CHARGES" then
		-- Do not ForceUpdateAction here: it can trigger ACTIONBAR_SLOT_CHANGED(0) and a full-bar Update via
		-- FlushActionBarSlotChangedAll; SPELL_UPDATE_CHARGES is too frequent during combat.
		ScheduleChargeUpdateFlush()
		ScheduleMacrotextCountFlush()
	elseif event == "UPDATE_SUMMONPETS_ACTION" then
		for button in next, ActiveButtons do
			if button._state_type == "action" then
				local actionType, _id = GetActionInfo(button._state_action)
				if actionType == "summonpet" then
					local texture = GetActionTexture(button._state_action)
					if texture then
						button.icon:SetTexture(texture)
					end
				end
			end
		end
	elseif event == "SPELL_UPDATE_ICON" then
		ForAllButtons(Update, true)
	elseif event == "AssistedCombatManager.OnSetActionSpell" then
		for button in next, lib.assistedCombatButtons do
			UpdateAssistedCombatRotationFrame(button)
		end
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		local _, spellID = ...
		lib.CurrentInterruptedSpellID = spellID
		lib.InterruptTime = GetTime()
		ForAllButtonsWithSpell(spellID, SpellVFX_PlaySpellInterruptedAnim)
	elseif event == "UNIT_SPELLCAST_START" then
		local _, spellID = ...
		ForAllButtonsWithSpell(spellID, SpellVFX_PlaySpellCastAnim, ActionButtonCastType.Cast)
	elseif event == "UNIT_SPELLCAST_STOP" then
		local _, spellID = ...
		lib.CurrentReticleSpellID = nil
		ForAllButtonsWithSpell(spellID, SpellVFX_StopSpellCastAnim, true, ActionButtonCastType.Cast)
		ForAllButtonsWithSpell(spellID, SpellVFX_StopTargettingReticleAnim)
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local _, spellID = ...
		ForAllButtonsWithSpell(spellID, SpellVFX_StopSpellCastAnim, false, ActionButtonCastType.Cast)
		ForAllButtonsWithSpell(spellID, SpellVFX_StopTargettingReticleAnim)
	elseif event == "UNIT_SPELLCAST_SENT" then
		local _, _, spellID = ...
		lib.CurrentReticleSpellID = nil
		ForAllButtonsWithSpell(spellID, SpellVFX_StopTargettingReticleAnim)
	elseif event == "UNIT_SPELLCAST_FAILED" then
		local _, spellID = ...
		lib.CurrentReticleSpellID = nil
		ForAllButtonsWithSpell(spellID, SpellVFX_StopTargettingReticleAnim)
	elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
		local _, spellID = ...
		ForAllButtonsWithSpell(spellID, SpellVFX_PlaySpellCastAnim, ActionButtonCastType.Empowered)
	elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
		local _, spellID, castComplete = ...
		local interrupted = not castComplete
		if interrupted then
			ForAllButtonsWithSpell(spellID, SpellVFX_PlaySpellInterruptedAnim)
		else
			ForAllButtonsWithSpell(spellID, SpellVFX_StopSpellCastAnim, interrupted, ActionButtonCastType.Empowered)
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		local _, spellID = ...
		ForAllButtonsWithSpell(spellID, SpellVFX_PlaySpellCastAnim, ActionButtonCastType.Channel)
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		local _, spellID = ...
		local wasInterrupted = false
		for button in next, ActiveButtons do
			local d = button.vfxCastData
			if d and d.type == ActionButtonCastType.Channel then
				if GetTime() < (d.start + d.duration - 0.25) then
					wasInterrupted = true
				end
				break
			end
		end
		if wasInterrupted then
			lib.CurrentInterruptedSpellID = spellID
			lib.InterruptTime = GetTime()
			ForAllButtonsWithSpell(spellID, SpellVFX_PlaySpellInterruptedAnim)
		else
			ForAllButtonsWithSpell(spellID, SpellVFX_StopSpellCastAnim, false, ActionButtonCastType.Channel)
		end
	elseif event == "UNIT_SPELLCAST_RETICLE_TARGET" then
		local _, spellID = ...
		lib.CurrentReticleSpellID = spellID
		ForAllButtonsWithSpell(spellID, SpellVFX_PlayTargettingReticleAnim)
	elseif event == "UNIT_SPELLCAST_RETICLE_CLEAR" then
		local _, spellID = ...
		lib.CurrentReticleSpellID = nil
		ForAllButtonsWithSpell(spellID, SpellVFX_StopTargettingReticleAnim)
	elseif event == "AssistedCombatManager.OnAssistedHighlightSpellChange" then
		ScheduleAssistedHighlightFlush()
	end
end

AreSpellsEquivalent = function(id1, id2)
	-- Prefer Flux canonical matcher (exact ID / override — never name; ranks stay distinct).
	if type(_G.FluxAreSpellsEquivalent) == "function" then
		return _G.FluxAreSpellsEquivalent(id1, id2)
	end
	if not id1 or not id2 then return false end
	if id1 == id2 then return true end

	if C_Spell and C_Spell.GetOverrideSpell then
		local ok, oa = pcall(C_Spell.GetOverrideSpell, id1)
		if ok and type(oa) == "number" and oa > 0 and oa == id2 then return true end
		ok, oa = pcall(C_Spell.GetOverrideSpell, id2)
		if ok and type(oa) == "number" and oa > 0 and oa == id1 then return true end
	end

	if FindBaseSpellByID then
		local ba, bb = FindBaseSpellByID(id1), FindBaseSpellByID(id2)
		if ba and ba == id2 then return true end
		if bb and bb == id1 then return true end
	end

	return false
end

--- Resolve spell id for LAB VFX (action buttons + ExtraButton widgets without GetSpellId).
local function ResolveVFXSpellId(self)
	if not self then return nil end
	if type(self.GetSpellId) == "function" then
		local ok, sid = pcall(self.GetSpellId, self)
		if ok and type(sid) == "number" and sid > 0 then return sid end
	end
	if type(self.spellID) == "number" and self.spellID > 0 then return self.spellID end
	local fb = self.ParentButton or self.FluxButton
	if fb then
		if type(fb.spellID) == "number" and fb.spellID > 0 then return fb.spellID end
		if type(fb.GetSpellId) == "function" then
			local ok, sid = pcall(fb.GetSpellId, fb)
			if ok and type(sid) == "number" and sid > 0 then return sid end
		end
	end
	return nil
end

	--- Flux action-bar / badge / pet surfaces: PostDF Exclusive owns cast/reticle/interrupt/burst.
local function FluxPostDFOwnsButtonVFX(self)
	if not self or not WoWRetail then return false end
	if _G.FluxPostDFLoadStatus ~= "ok" then return false end
	if self._fluxBarSlotIndex or self._fluxIsActionBarBadge or self._fluxIsBadgeCornerProxy
		or self._fluxSpellCastAnimSlotFill or self._fluxIsPetButton then
		return true
	end
	local fb = self.ParentButton or self.FluxButton
	if fb and (fb._fluxIsActionBarBadge or fb._fluxBarSlotIndex or fb._fluxIsPetButton) then
		return true
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Retail (post-DF): SpellCastAnimFrame cast fill — one module, manual progress only.
-- Blizzard Setup() plays CastFillTranslation from t=0; we never rely on that timeline.
-- Progress is always derived from UnitCastingInfo / UnitChannelInfo vs this button's spell id.
-- CastFill CENTER X matches __Backup/_FluxUI Backup2: (-45 + 43*progress) * _fluxOverlayXRatio
-- (same squeeze factor _FluxActionBar_aniso_helpers uses on Setup post-hook CastFill).
-- ---------------------------------------------------------------------------
lib.FluxRetailCastVFX = {}

function lib.FluxRetailCastVFX.GetCastFillOffsetX(progress, button, _forPreSetup)
	local xR = button._fluxOverlayXRatio
	if type(xR) ~= "number" or xR <= 0 or xR > 100 then
		xR = 1
	end
	return (-45 + 43 * progress) * xR
end

function lib.FluxRetailCastVFX.StopTranslationAnims(self)
	local scaf = self.SpellCastAnimFrame
	if not scaf then return end
	local fill = scaf.Fill
	if fill and fill.CastingAnim then
		fill.CastingAnim:Stop()
	end
	if scaf.EndBurst and scaf.EndBurst.FinishCastAnim then
		scaf.EndBurst.FinishCastAnim:Stop()
	end
end

function lib.FluxRetailCastVFX.ApplyFillProgress(self, progress)
	local scaf = self.SpellCastAnimFrame
	if not scaf then return end
	if scaf.ApplyCastBarLayoutFromButton then
		scaf:ApplyCastBarLayoutFromButton(progress)
	elseif scaf.Fill and scaf.Fill.CastFill then
		local ox = lib.FluxRetailCastVFX.GetCastFillOffsetX(progress, self, false)
		scaf.Fill.CastFill:ClearAllPoints()
		scaf.Fill.CastFill:SetPoint("CENTER", ox, 0)
		scaf.Fill.CastFill:SetAlpha(1)
	end
end

-- Manual CastFill is not driven by CastingAnim; FinishAnimAndPlayBurst does not clear a full bar texture.
function lib.FluxRetailCastVFX.ClearCastBarVisualForBurst(button, scaf)
	if not scaf then return end
	if scaf.ApplyCastBarLayoutFromButton then
		scaf:ApplyCastBarLayoutFromButton(0)
		return
	end
	local fill = scaf.Fill
	if not fill then return end
	if fill.CastFill then
		local ox = lib.FluxRetailCastVFX.GetCastFillOffsetX(0, button, true)
		fill.CastFill:ClearAllPoints()
		fill.CastFill:SetPoint("CENTER", ox, 0)
		fill.CastFill:SetAlpha(0)
	end
	if fill.CastDim then fill.CastDim:SetAlpha(0) end
	if fill.CastSpark then fill.CastSpark:Hide() end
end

function lib.FluxRetailCastVFX.Tick(self)
	local data = self.vfxCastData
	if not data or not self.SpellCastAnimFrame then return end

	local spellId = ResolveVFXSpellId(self)
	local isValid = false
	local sTimeMs, eTimeMs

	if data.type == ActionButtonCastType.Cast then
		local _, _, _, st, et, _, _, _, cID = UnitCastingInfo("player")
		if cID and spellId and AreSpellsEquivalent(cID, spellId) then
			isValid = true
			sTimeMs, eTimeMs = st, et
		end
	elseif data.type == ActionButtonCastType.Channel or data.type == ActionButtonCastType.Empowered then
		local _, _, _, st, et, _, _, cID = UnitChannelInfo("player")
		if cID and spellId and AreSpellsEquivalent(cID, spellId) then
			isValid = true
			sTimeMs, eTimeMs = st, et
		end
	end

	if not isValid then
		-- Unit APIs can clear before UNIT_SPELLCAST_* fires; keep actionButtonCastType so
		-- Stop(false) can run FinishAnimAndPlayBurst. UpdateSpellVFX force-stops if no event.
		self.vfxCastData = nil
		lib.fluxVFXButtons[self] = nil
		return
	end

	local durSec = ((eTimeMs or 0) - (sTimeMs or 0)) / 1000
	if durSec <= 0 then durSec = 0.0001 end
	local startSec = (sTimeMs or 0) / 1000
	data.start = startSec
	data.duration = durSec

	local now = GetTime()
	local progress = (now - startSec) / durSec
	if progress > 1 then progress = 1 end
	if progress < 0 then progress = 0 end
	if data.type == ActionButtonCastType.Channel then
		progress = 1 - progress
	end

	lib.FluxRetailCastVFX.ApplyFillProgress(self, progress)
end

function lib.FluxRetailCastVFX.Play(self, actionButtonCastType)
	if not self.config.spellCastVFX or not self.SpellCastAnimFrame then return end

	self.cooldown.__Swipe_Hook = true
	self.cooldown:SetSwipeColor(0, 0, 0, 0)
	self.cooldown.__Swipe_Hook = nil

	SpellVFX_ClearInterruptDisplay(self)
	SpellVFX_ClearReticle(self)

	local scaf = self.SpellCastAnimFrame
	lib.FluxRetailCastVFX.StopTranslationAnims(self)

	if scaf.ApplyCastBarLayoutFromButton then
		local initP = 0
		if actionButtonCastType == ActionButtonCastType.Channel then
			initP = 1
		end
		scaf:ApplyCastBarLayoutFromButton(initP)
	elseif scaf.Fill and scaf.Fill.CastFill then
		local ox = lib.FluxRetailCastVFX.GetCastFillOffsetX(0, self, true)
		scaf.Fill.CastFill:ClearAllPoints()
		scaf.Fill.CastFill:SetPoint("CENTER", ox, 0)
		scaf.Fill.CastFill:SetAlpha(1)
	end

	scaf:Setup(actionButtonCastType)
	self.actionButtonCastType = actionButtonCastType

	-- UNIT_SPELLCAST_* can call Play before the next Update(); seed timing from the unit APIs.
	if not self.vfxCastData then
		local spellId = ResolveVFXSpellId(self)
		if spellId then
			if actionButtonCastType == ActionButtonCastType.Cast and UnitCastingInfo then
				local _, _, _, st, et, _, _, _, cID = UnitCastingInfo("player")
				if cID and AreSpellsEquivalent(cID, spellId) then
					self.vfxCastData = {
						start = st / 1000,
						duration = math.max(0.0001, (et - st) / 1000),
						type = actionButtonCastType,
					}
					lib.fluxVFXButtons[self] = true
				end
			elseif (actionButtonCastType == ActionButtonCastType.Channel or actionButtonCastType == ActionButtonCastType.Empowered)
					and UnitChannelInfo then
				local _, _, _, st, et, _, _, cID = UnitChannelInfo("player")
				if cID and AreSpellsEquivalent(cID, spellId) then
					self.vfxCastData = {
						start = st / 1000,
						duration = math.max(0.0001, (et - st) / 1000),
						type = actionButtonCastType,
					}
					lib.fluxVFXButtons[self] = true
				end
			end
		end
	end

	lib.FluxRetailCastVFX.StopTranslationAnims(self)
	if self.vfxCastData then
		lib.FluxRetailCastVFX.Tick(self)
	end
end

function lib.FluxRetailCastVFX.Stop(self, forceStop, actionButtonCastType)
	if not self.actionButtonCastType then return end
	if self.actionButtonCastType ~= actionButtonCastType then return end

	self.actionButtonCastType = nil
	self.vfxCastData = nil
	lib.fluxVFXButtons[self] = nil
	local scaf = self.SpellCastAnimFrame

	if forceStop then
		if scaf and scaf.ApplyCastBarLayoutFromButton then
			scaf:ApplyCastBarLayoutFromButton(0)
		elseif scaf and scaf.Fill and scaf.Fill.CastFill then
			local ox = lib.FluxRetailCastVFX.GetCastFillOffsetX(0, self, true)
			scaf.Fill.CastFill:ClearAllPoints()
			scaf.Fill.CastFill:SetPoint("CENTER", ox, 0)
		end
		if scaf then scaf:Hide() end
		else
			-- Play/StopTranslationAnims keeps CastingAnim stopped while we drive CastFill manually,
			-- so IsPlaying() is never true here — still need FinishAnimAndPlayBurst for end VFX.
			if scaf and scaf.FinishAnimAndPlayBurst then
				if scaf.Fill and scaf.Fill.CastingAnim and scaf.Fill.CastingAnim:IsPlaying() then
					scaf:FinishAnimAndPlayBurst()
				else
					lib.FluxRetailCastVFX.ClearCastBarVisualForBurst(self, scaf)
					scaf:FinishAnimAndPlayBurst()
				end
			elseif scaf then
				scaf:Hide()
			end
		end
end

local function UpdateManualCastVFX(self)
	if WoWRetail then
		lib.FluxRetailCastVFX.Tick(self)
		return
	end
	local data = self.vfxCastData
	if not data or not self.SpellCastAnimFrame or not self.SpellCastAnimFrame.Fill or not self.SpellCastAnimFrame.Fill.CastFill then
		return
	end
	local spellId = ResolveVFXSpellId(self)
	local isValid = false
	local sTimeMs, eTimeMs
	if data.type == ActionButtonCastType.Cast then
		local _, _, _, st, et, _, _, _, cID = UnitCastingInfo("player")
		if cID and spellId and AreSpellsEquivalent(cID, spellId) then
			isValid = true
			sTimeMs, eTimeMs = st, et
		end
	elseif data.type == ActionButtonCastType.Channel or data.type == ActionButtonCastType.Empowered then
		local _, _, _, st, et, _, _, cID = UnitChannelInfo("player")
		if cID and spellId and AreSpellsEquivalent(cID, spellId) then
			isValid = true
			sTimeMs, eTimeMs = st, et
		end
	end
	if not isValid then
		self.vfxCastData = nil
		lib.fluxVFXButtons[self] = nil
		if self.SpellCastAnimFrame then self.SpellCastAnimFrame:Hide() end
		return
	end
	-- Live Unit*Info times (pushback / channel updates) — same as lib.FluxRetailCastVFX.Tick.
	if sTimeMs and eTimeMs then
		local durSec = (eTimeMs - sTimeMs) / 1000
		if durSec <= 0 then durSec = 0.0001 end
		data.start = sTimeMs / 1000
		data.duration = durSec
	end
	local now = GetTime()
	local progress = (now - data.start) / data.duration
	if progress > 1 then progress = 1 end
	if progress < 0 then progress = 0 end
	if data.type == ActionButtonCastType.Channel then
		progress = 1 - progress
	end
	if self.SpellCastAnimFrame.ApplyCastBarLayoutFromButton then
		self.SpellCastAnimFrame:ApplyCastBarLayoutFromButton(progress)
	else
		local ox = lib.FluxRetailCastVFX.GetCastFillOffsetX(progress, self, false)
		self.SpellCastAnimFrame.Fill.CastFill:ClearAllPoints()
		self.SpellCastAnimFrame.Fill.CastFill:SetPoint("CENTER", ox, 0)
		self.SpellCastAnimFrame.Fill.CastFill:SetAlpha(1)
	end
end

_G.FluxLABSyncManualCastVFXProgress = function(btn)
	if WoWRetail and btn then
		lib.FluxRetailCastVFX.Tick(btn)
	end
end

local flashTime = 0
local rangeTimer = -1
-- Demand-drive arm helpers live in FluxLABExtensions.lua (LAB main chunk is at the 200-local limit).

function OnUpdate(_, elapsed)
	flashTime = flashTime - elapsed
	rangeTimer = rangeTimer - elapsed

	-- Flux perf T1.1: iterate only buttons with active manual cast VFX instead of
	-- scanning all ActiveButtons every frame. On most frames this set is empty.
	if next(lib.fluxVFXButtons) then
		for button in next, lib.fluxVFXButtons do
			if button.vfxCastData then
				UpdateManualCastVFX(button)
			else
				lib.fluxVFXButtons[button] = nil
			end
		end
	end

	-- Flux perf T1.1: flash tick runs only against the narrow lib.fluxFlashingButtons set.
	if flashTime <= 0 and next(lib.fluxFlashingButtons) then
		for button in next, lib.fluxFlashingButtons do
			if button.flashing == 1 then
				if button.Flash:IsShown() then
					button.Flash:Hide()
				else
					button.Flash:Show()
				end
			else
				lib.fluxFlashingButtons[button] = nil
			end
		end
	end

	-- Bartended perf: range polling only on buttons classified as range-relevant
	-- (spells, spell-macros, items, Binding macrotext) — not empty slots, mounts, toys, or flyouts.
	if rangeTimer <= 0 then
		local skipBgRange = FluxMouseoverRefresh
			and FluxMouseoverRefresh.ShouldSkipBackgroundRangePoll
			and FluxMouseoverRefresh.ShouldSkipBackgroundRangePoll()
		if skipBgRange then
			rangeTimer = FluxMouseoverRefresh.GetInterval()
		else
		-- Poll in combat, or whenever a target/mouseover exists (friendly heals included).
		local runRange = InCombatLockdown()
			or UnitExists("mouseover")
			or UnitExists("target")
		if runRange then
			lib._fluxAnyOutOfRange = false
			for button in next, lib.rangeButtons do
				-- Hidden / parked minirows leave the poll set (re-ClassifyRange on show / paging).
				if (button.IsShown and not button:IsShown()) or button._fluxParkedOffscreen then
					if button.outOfRange then
						button.outOfRange = false
					end
					lib.rangeButtons[button] = nil
				else
					local inRange = button:IsInRange()
					local oldRange = button.outOfRange
					button.outOfRange = (inRange == false)
					if button.outOfRange then
						lib._fluxAnyOutOfRange = true
					end
					if oldRange ~= button.outOfRange then
						if button.config.outOfRangeColoring == "button" then
							if not _G._fluxPagingInProgress then
								UpdateUsable(button, true)
							elseif button.icon then
								-- Must clear red when in-range / no-range — previously only set OOR tint.
								if button.outOfRange then
									button.icon:SetVertexColor(unpack(button.config.colors.range))
								else
									button.icon:SetVertexColor(1.0, 1.0, 1.0)
								end
								button._fluxUsablePaintKey = nil
							end
						elseif button.config.outOfRangeColoring == "hotkey" then
							local hotkey = button.HotKey
							if hotkey:GetText() == RANGE_INDICATOR then
								if inRange == false then
									hotkey:Show()
								else
									hotkey:Hide()
								end
							end
							if inRange == false then
								hotkey:SetVertexColor(unpack(button.config.colors.range))
							else
								hotkey:SetVertexColor(unpack(button.config.text.hotkey.color))
							end
						end
					end
				end
			end
		else
			-- No unit: clear stale OOR so icons do not stay red; drop hidden from set.
			-- Skip the sweep when nothing is currently OOR (idle FPS).
			if lib._fluxAnyOutOfRange then
				for button in next, lib.rangeButtons do
					if button.IsShown and not button:IsShown() then
						lib.rangeButtons[button] = nil
					elseif button.outOfRange then
						button.outOfRange = false
						if button.IsShown and button:IsShown()
							and button.config and button.config.outOfRangeColoring == "button" then
							UpdateUsable(button, true)
						elseif button.config and button.config.outOfRangeColoring == "hotkey" then
							local hotkey = button.HotKey
							if hotkey then
								hotkey:SetVertexColor(unpack(button.config.text.hotkey.color))
							end
						end
					end
				end
				lib._fluxAnyOutOfRange = false
			end
		end
		end
	end

	-- Update values
	if flashTime <= 0 then
		flashTime = flashTime + ATTACK_BUTTON_FLASH_TIME
	end
	if rangeTimer <= 0 then
		rangeTimer = tonumber(_G.FluxLABRangeCheckInterval) or TOOLTIP_UPDATE_TIME
	end

	-- Self-disarm when idle (arm helpers in FluxLABExtensions).
	if lib.FluxLABNeedsOnUpdate and not lib.FluxLABNeedsOnUpdate() then
		lib._fluxOnUpdateArmed = false
		lib.eventFrame:SetScript("OnUpdate", nil)
	end
end
lib._fluxOnUpdate = OnUpdate
lib._fluxBumpRangeTimer = function()
	rangeTimer = -1
end

local gridCounter = 0
function ShowGrid()
	gridCounter = gridCounter + 1
	if gridCounter >= 1 then
		for button in next, ButtonRegistry do
			if button:IsShown() then
				button:SetAlpha(1.0)
			end
		end
	end
end

function HideGrid()
	if gridCounter > 0 then
		gridCounter = gridCounter - 1
	end
	if gridCounter == 0 then
		for button in next, ButtonRegistry do
			if button:IsShown() and not button:HasAction() and not button.config.showGrid then
				button:SetAlpha(0.0)
			end
		end
	end
end

function UpdateGrid(self)
	if self.config.showGrid then
		self:SetAlpha(1.0)
	elseif gridCounter == 0 and self:IsShown() and not self:HasAction() then
		self:SetAlpha(0.0)
	end
end

-----------------------------------------------------------
--- KeyBound integration

function Generic:GetBindingAction()
	return self.config.keyBoundTarget or ("CLICK %s:%s"):format(self:GetName(), self.config.keyBoundClickButton)
end

function Generic:GetHotkey()
	local name = ("CLICK %s:%s"):format(self:GetName(), self.config.keyBoundClickButton)
	local key = GetBindingKey(self.config.keyBoundTarget or name)
	if not key and self.config.keyBoundTarget then
		key = GetBindingKey(name)
	end
	if key then
		return KeyBound and KeyBound:ToShortKey(key) or key
	end
end

local function getKeys(binding, keys)
	keys = keys or ""
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ", "
		end
		keys = keys .. GetBindingText(hotKey)
	end
	return keys
end

function Generic:GetBindings()
	local keys

	if self.config.keyBoundTarget then
		keys = getKeys(self.config.keyBoundTarget)
	end

	keys = getKeys(("CLICK %s:%s"):format(self:GetName(), self.config.keyBoundClickButton), keys)

	return keys
end

function Generic:SetKey(key)
	if self.config.keyBoundTarget then
		SetBinding(key, self.config.keyBoundTarget)
	else
		SetBindingClick(key, self:GetName(), self.config.keyBoundClickButton)
	end
	lib.callbacks:Fire("OnKeybindingChanged", self, key)
end

local function clearBindings(binding)
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

function Generic:ClearBindings()
	if self.config.keyBoundTarget then
		clearBindings(self.config.keyBoundTarget)
	end
	clearBindings(("CLICK %s:%s"):format(self:GetName(), self.config.keyBoundClickButton))
	lib.callbacks:Fire("OnKeybindingChanged", self, nil)
end

-----------------------------------------------------------
--- button management



-- Helper to sync SpellVFX animation with current player cast state
-- This ensures animations persist when buttons are swapped (paging)
-- Pre-DF without UNIT_SPELLCAST_RETICLE_* : FluxPreDFButtonVFX drives ground-target reticle via SpellIsTargeting +
-- IsCurrentAction; LAB Play/Stop here fights that during paging (minirows / modifier bars).
function lib.FluxPreDFOwnsGroundTargetReticleUX()
	local api = _G.FLUX_API
	return api and api.isPreDF and not api.hasUnitSpellcastReticleEvents
end

function lib.FluxLABRefreshCastBarGeometry(button)
	if not button then return end
	local scaf = button.SpellCastAnimFrame
	if scaf and scaf._fluxRefreshCastBarGeometry then
		scaf:_fluxRefreshCastBarGeometry()
	end
end

local function UpdateSpellVFX(self)
	if not self.config.spellCastVFX then return end

	-- Post-DF Flux action-bar / badge: Exclusive owns paint (bar↔badge + main↔mini).
	-- Do not drive FluxRetailCastVFX independently or fills fight Exclusive / wrong row.
	if FluxPostDFOwnsButtonVFX(self) and _G.FluxPostDFUpdateButtonSpellVFX then
		_G.FluxPostDFUpdateButtonSpellVFX(self)
		return
	end

	local spellId = ResolveVFXSpellId(self)
	local fluxOwnsReticle = lib.FluxPreDFOwnsGroundTargetReticleUX()
	if not spellId then 
		if self.actionButtonCastType then
			SpellVFX_StopSpellCastAnim(self, true, self.actionButtonCastType)
		end
		if not fluxOwnsReticle then
			SpellVFX_StopTargettingReticleAnim(self)
		end
		SpellVFX_ClearInterruptDisplay(self)
		return 
	end

	local castType
	local currentSpellId
	local startTimeMs
	local endTimeMs

	if UnitCastingInfo then
		local _, _, _, sTime, eTime, _, _, _, cSpellId = UnitCastingInfo("player")
		if cSpellId and AreSpellsEquivalent(cSpellId, spellId) then
			currentSpellId = cSpellId
			startTimeMs = sTime
			endTimeMs = eTime
			castType = ActionButtonCastType.Cast
		end
	end

	if not currentSpellId and UnitChannelInfo then
		local _, _, _, sTime, eTime, _, _, cSpellId = UnitChannelInfo("player")
		if cSpellId and AreSpellsEquivalent(cSpellId, spellId) then
			currentSpellId = cSpellId
			startTimeMs = sTime
			endTimeMs = eTime
			local isEmpower = C_Spell and C_Spell.IsPressHoldReleaseSpell
				and C_Spell.IsPressHoldReleaseSpell(cSpellId)
			castType = isEmpower and ActionButtonCastType.Empowered or ActionButtonCastType.Channel
		end
	end

	if currentSpellId then
		local pagingResync = self._fluxPagingOverlayResync
		if pagingResync then
			self._fluxPagingOverlayResync = nil
		end
		local function tryPreDFSync()
			return _G.FluxPreDFSyncCastProgress
				and lib.FluxBarCastState
				and lib.FluxBarCastState.activeCast
				and _G.FluxPreDFSyncCastProgress(self, lib.FluxBarCastState.activeCast)
		end
		local function tryPostDFSync()
			return _G.FluxPostDFSyncCastProgress
				and lib.FluxBarCastState
				and lib.FluxBarCastState.activeCast
				and _G.FluxPostDFSyncCastProgress(self, lib.FluxBarCastState.activeCast)
		end
		if WoWRetail and self.SpellCastAnimFrame then
			if (pagingResync or not self.actionButtonCastType) and (tryPostDFSync() or tryPreDFSync()) then
				-- synced at current progress
			elseif self.actionButtonCastType ~= castType and startTimeMs and endTimeMs then
				self.vfxCastData = {
					start = startTimeMs / 1000,
					duration = (endTimeMs - startTimeMs) / 1000,
					type = castType,
				}
				lib.fluxVFXButtons[self] = true
				lib.FluxRetailCastVFX.Play(self, castType)
			elseif self.actionButtonCastType ~= castType then
				lib.FluxRetailCastVFX.Play(self, castType)
			elseif startTimeMs and endTimeMs then
				self.vfxCastData = {
					start = startTimeMs / 1000,
					duration = (endTimeMs - startTimeMs) / 1000,
					type = castType,
				}
				lib.fluxVFXButtons[self] = true
				lib.FluxRetailCastVFX.StopTranslationAnims(self)
				lib.FluxRetailCastVFX.Tick(self)
			end
		else
			if (pagingResync or not self.actionButtonCastType) and tryPreDFSync() then
				-- synced at current progress
			elseif self.actionButtonCastType == castType then
				if startTimeMs and endTimeMs and not self.vfxCastData then
					self.vfxCastData = {
						start = startTimeMs / 1000,
						duration = (endTimeMs - startTimeMs) / 1000,
						type = castType,
					}
					lib.fluxVFXButtons[self] = true
					if self.SpellCastAnimFrame and self.SpellCastAnimFrame.Fill and self.SpellCastAnimFrame.Fill.CastingAnim then
						self.SpellCastAnimFrame.Fill.CastingAnim:Stop()
					end
				end
				UpdateManualCastVFX(self)
			elseif self.actionButtonCastType ~= castType and startTimeMs and endTimeMs then
				self.vfxCastData = {
					start = startTimeMs / 1000,
					duration = (endTimeMs - startTimeMs) / 1000,
					type = castType,
				}
				lib.fluxVFXButtons[self] = true
				self.actionButtonCastType = castType
				if self.SpellCastAnimFrame then
					self.SpellCastAnimFrame:Setup(castType)
				end
			elseif self.actionButtonCastType ~= castType then
				self.actionButtonCastType = castType
				if self.SpellCastAnimFrame then
					self.SpellCastAnimFrame:Setup(castType)
				end
			end
		end
		lib.FluxLABRefreshCastBarGeometry(self)
	else
		if self.actionButtonCastType then
			local ebPlaying = self.SpellCastAnimFrame
				and self.SpellCastAnimFrame.EndBurst
				and self.SpellCastAnimFrame.EndBurst:IsShown()
			local intPlaying = self.InterruptDisplay and self.InterruptDisplay:IsShown()
			if not ebPlaying and not intPlaying then
				SpellVFX_StopSpellCastAnim(self, true, self.actionButtonCastType)
			end
		end
	end

	-- Check Reticle (see lib.FluxPreDFOwnsGroundTargetReticleUX)
	if not fluxOwnsReticle then
		if lib.CurrentReticleSpellID and lib.CurrentReticleSpellID == spellId then
			SpellVFX_PlayTargettingReticleAnim(self)
		else
			SpellVFX_StopTargettingReticleAnim(self)
		end
	end

	-- Check Interrupt
	if lib.CurrentInterruptedSpellID and AreSpellsEquivalent(lib.CurrentInterruptedSpellID, spellId) and lib.InterruptTime then
		if (GetTime() - lib.InterruptTime) < 1.5 then
			if self.InterruptDisplay then
				self.InterruptDisplay:Show()
			end
		else
			SpellVFX_ClearInterruptDisplay(self)
		end
	else
		SpellVFX_ClearInterruptDisplay(self)
	end

	-- Check EndBurst (pre-DF cast-complete flash surviving paging)
	if not currentSpellId and lib.CurrentBurstSpellID and AreSpellsEquivalent(lib.CurrentBurstSpellID, spellId) and lib.BurstStartTime then
		local burstElapsed = GetTime() - lib.BurstStartTime
		if burstElapsed < 0.55 and self.SpellCastAnimFrame and self.SpellCastAnimFrame.EndBurst then
			local eb = self.SpellCastAnimFrame.EndBurst
			if not eb:IsShown() then
				self.SpellCastAnimFrame:Show()
				eb._resumeElapsed = burstElapsed
				eb:Show()
			end
		end
	end
end

function lib:FluxRefreshCastVFXAfterLayout()
	local seen = {}
	local function refresh(btn)
		if not btn or seen[btn] then return end
		seen[btn] = true
		if btn.config and btn.config.spellCastVFX then
			UpdateSpellVFX(btn)
		end
	end
	local castingOrChanneling = false
	if UnitCastingInfo and UnitCastingInfo("player") then
		castingOrChanneling = true
	elseif UnitChannelInfo and UnitChannelInfo("player") then
		castingOrChanneling = true
	elseif lib.FluxBarCastState and lib.FluxBarCastState.activeCast then
		castingOrChanneling = true
	end
	if castingOrChanneling then
		for slot = 1, 19 do
			for _, prefix in ipairs({ "FluxActionButton", "FluxSecondaryButton", "FluxTertiaryButton" }) do
				refresh(_G[prefix .. slot])
			end
		end
	end
	local watch = lib.fluxPreDFCastWatchButtons
	if watch then
		for button in next, watch do
			refresh(button)
		end
	end
	for button in next, ActiveButtons do
		if button.config and button.config.spellCastVFX then
			if button.actionButtonCastType
				or (button.InterruptDisplay and button.InterruptDisplay:IsShown())
				or (button.TargetReticleAnimFrame and button.TargetReticleAnimFrame:IsShown())
				or (button.SpellCastAnimFrame and button.SpellCastAnimFrame.EndBurst and button.SpellCastAnimFrame.EndBurst:IsShown()) then
				refresh(button)
			end
		end
	end
end
lib.RefreshSpellCastVFXForAllButtons = lib.FluxRefreshCastVFXAfterLayout

function Generic:UpdateAction(force)
	local action_type, action = self:GetAction()
	if force or action_type ~= self._state_type or action ~= self._state_action then
		-- type changed, update the metatable
		if force or self._state_type ~= action_type then
			local meta = type_meta_map[action_type] or type_meta_map.empty
			setmetatable(self, meta)
			self._state_type = action_type
		end
		self._state_action = action

		-- Flux Binding: track buttons currently displaying a macrotext override
		if action_type == "macrotext" then
			lib.fluxMacrotextButtons[self] = true
		elseif lib.fluxMacrotextButtons[self] then
			lib.fluxMacrotextButtons[self] = nil
		end

		-- set action attribute for action buttons
		self.action = self._state_type == "action" and action or 0
		if self.config.actionButtonUI then
			SetActionUIButton(self, self.action, self.cooldown)
		end

		Update(self, true)

		if EventRegistry and EventRegistry.TriggerEvent then
			EventRegistry:TriggerEvent("ActionButton.OnActionChanged", self)
		end
	end
end

-- Flux LAB: slot map + usable batch helpers
FluxLABBeginUsableBatch = function()
	lib.fluxDefer.levelLinkCacheGen = lib.fluxDefer.levelLinkCacheGen + 1
	if lib.fluxDefer.levelLinkCacheGen > 1000000 then
		lib.fluxDefer.levelLinkCacheGen = 1
		wipe(lib.fluxDefer.levelLinkCache)
	end
end

function lib.LABShouldSkipFullBroadcastUsable()
	if _G.FluxLABForceBroadcastUsable then return false end
	-- Full-bar skip is opt-in only: if granular never fires (granularEv stays 0), skipping
	-- broadcast would leave slots stale; slot-level dedupe in FlushBroadcastUsableNow handles overlap.
	if _G.FluxLABSkipBroadcastWhenGranular ~= true then return false end
	return lib._fluxActionUsableChangedRegistered
end

function lib.LABBroadcastShouldSkipButton(button)
	if not button or button._state_type ~= "action" then return false end
	local slot = tonumber(button._state_action)
	if not slot then return false end
	return lib.fluxDefer.granularUsableSlotsThisTick[slot] == true
end

NormalizeActionUsableChanges = function(arg1, ...)
	local out, n = {}, 0
	if arg1 == nil then return out end
	if type(arg1) == "table" then
		if arg1.slot ~= nil or arg1.actionSlot ~= nil or arg1.actionBarSlot ~= nil then
			out[1] = arg1
			return out
		end
		for i = 1, #arg1 do
			local ch = arg1[i]
			if type(ch) == "table" then
				n = n + 1
				out[n] = ch
			end
		end
		if n > 0 then return out end
	elseif type(arg1) == "number" then
		out[1] = { slot = arg1, usable = select(1, ...), noMana = select(2, ...) }
		return out
	end
	return out
end

function FluxLABSyncSlotButtonMap(self)
	local prev = self._fluxLabMappedSlot
	-- Include Binding macrotext overrides via underlying action slot.
	local newSlot
	if self.GetEffectiveActionSlot then
		newSlot = self:GetEffectiveActionSlot()
	elseif self._state_type == "action" and self:HasAction() then
		newSlot = tonumber(self._state_action)
	elseif self._state_type == "macrotext" and self.GetMacrotextSlot then
		newSlot = tonumber(self:GetMacrotextSlot())
	end
	if not newSlot then
		newSlot = nil
	end
	if prev == newSlot then return end
	if prev and lib.slotToActionButtons[prev] then
		lib.slotToActionButtons[prev][self] = nil
	end
	self._fluxLabMappedSlot = newSlot
	if newSlot then
		local t = lib.slotToActionButtons[newSlot]
		if not t then
			t = {}
			lib.slotToActionButtons[newSlot] = t
		end
		t[self] = true
	else
		self._fluxLabMappedSlot = nil
	end
end

function FluxLABSyncMouseoverMacroIndex(self)
	local wasMouseover = lib.fluxMouseoverMacroButtons[self] ~= nil
	local isMouseover = false
	if ActiveButtons[self] and self._state_type == "action" and self:HasAction() then
		local actionType, id = GetActionInfo(self._state_action)
		if actionType == "macro" and id and GetMacroInfo then
			local _, _, body = GetMacroInfo(id)
			if body and body:lower():find("@mouseover", 1, true) then
				isMouseover = true
			end
		end
	end
	self._fluxMacroUsesMouseover = isMouseover
	if isMouseover then
		lib.fluxMouseoverMacroButtons[self] = true
	else
		lib.fluxMouseoverMacroButtons[self] = nil
	end
	if wasMouseover ~= isMouseover and FluxMouseoverRefresh and FluxMouseoverRefresh.RefreshGlobalPresence then
		FluxMouseoverRefresh.RefreshGlobalPresence()
	end
end

function lib:ReindexMouseoverMacroButtons()
	if not lib.fluxMouseoverMacroButtons then
		lib.fluxMouseoverMacroButtons = {}
	end
	for button in next, lib.fluxMouseoverMacroButtons do
		lib.fluxMouseoverMacroButtons[button] = nil
	end
	for button in next, ActiveButtons do
		FluxLABSyncMouseoverMacroIndex(button)
	end
	if FluxMouseoverRefresh and FluxMouseoverRefresh.RefreshGlobalPresence then
		FluxMouseoverRefresh.RefreshGlobalPresence()
	end
end

-- Flux perf T2.1: keep the spellId -> buttons index coherent with the button's
-- current action. Called from Update() after every state transition so that
-- glow events (SPELL_ACTIVATION_OVERLAY_GLOW_SHOW/HIDE) can skip the full
-- ActiveButtons scan.
function FluxLABSyncSpellIdIndex(self)
	local prev = self._fluxIndexedSpellId
	local new = nil
	if ActiveButtons[self] and type(self.GetSpellId) == "function" then
		local ok, sid = pcall(self.GetSpellId, self)
		if ok and type(sid) == "number" and sid > 0 then
			new = sid
		end
	end
	if prev == new then return end
	if prev then
		local t = lib.fluxSpellIdToButtons[prev]
		if t then
			t[self] = nil
			if not next(t) then
				lib.fluxSpellIdToButtons[prev] = nil
			end
		end
	end
	self._fluxIndexedSpellId = new
	if new then
		local t = lib.fluxSpellIdToButtons[new]
		if not t then
			t = setmetatable({}, { __mode = "k" })
			lib.fluxSpellIdToButtons[new] = t
		end
		t[self] = true
	end
end

-- Flux perf T2.1: track flyout buttons and pre-index flyout spell IDs for O(1)
-- proc glow dispatch (Bartended lib.fluxFlyoutSpellButtons pattern).
function lib.FluxLABClearFlyoutSpellIndexForButton(button)
	for spellID, buttons in pairs(lib.fluxFlyoutSpellButtons) do
		buttons[button] = nil
		if not next(buttons) then
			lib.fluxFlyoutSpellButtons[spellID] = nil
		end
	end
end

function FluxLABSyncFlyoutActionIndex(self)
	local wasFlyout = lib.fluxFlyoutActionButtons[self] ~= nil
	local isFlyout = false

	lib.FluxLABClearFlyoutSpellIndexForButton(self)

	if ActiveButtons[self] and self._state_type == "action" and self._state_action then
		local actionType, id = GetActionInfo(self._state_action)
		if actionType == "flyout" and id then
			isFlyout = true
			local success, _, _, numSlots = pcall(GetFlyoutInfo, id)
			if success and numSlots then
				for i = 1, numSlots do
					local flySpellID, _, flyIsKnown = GetFlyoutSlotInfo(id, i)
					if flySpellID and flyIsKnown then
						local t = lib.fluxFlyoutSpellButtons[flySpellID]
						if not t then
							t = setmetatable({}, { __mode = "k" })
							lib.fluxFlyoutSpellButtons[flySpellID] = t
						end
						t[self] = true
					end
				end
			end
		end
	end

	if isFlyout and not wasFlyout then
		lib.fluxFlyoutActionButtons[self] = true
	elseif (not isFlyout) and wasFlyout then
		lib.fluxFlyoutActionButtons[self] = nil
	end
end

-- Bartended perf: classify whether a button needs IsInRange() polling in OnUpdate.
-- Called once per action change, not per frame.
local function ClassifyRange(button)
	lib.rangeButtons[button] = nil
	if not button or not button:HasAction() then return end
	-- Hidden surfaces stay out of the poll set until shown again.
	if button.IsShown and not button:IsShown() then return end
	-- SmartLayout parks unused minis off-screen while still :Show()'n — do not poll them.
	if button._fluxParkedOffscreen then return end

	if button._state_type == "action" then
		local actionType, id, subType = GetActionInfo(button._state_action)
		if actionType == "spell" then
			lib.rangeButtons[button] = true
		elseif actionType == "macro" then
			local spellID = nil
			if subType == "spell" then
				spellID = id
			elseif id then
				pcall(function() spellID = GetMacroSpell(id) end)
			end
			if spellID then lib.rangeButtons[button] = true end
		elseif actionType == "item" then
			lib.rangeButtons[button] = true
		end
	elseif button._state_type == "spell" then
		lib.rangeButtons[button] = true
	elseif button._state_type == "item" then
		lib.rangeButtons[button] = true
	elseif button._state_type == "macrotext" then
		-- Binding overlays: Macrotext.IsUnitInRange resolves spell/item; keep in poll set.
		lib.rangeButtons[button] = true
	end
	if lib.FluxLABSyncOnUpdateArm then lib.FluxLABSyncOnUpdateArm() end
end
lib.ClassifyRange = ClassifyRange

--- Drop parked/hidden leftovers after target/macro Update storms re-ClassifyRange.
function lib.FluxLABScrubParkedRangeButtons()
	local changed = false
	for button in next, lib.rangeButtons do
		if not button
			or (button.IsShown and not button:IsShown())
			or button._fluxParkedOffscreen
		then
			lib.rangeButtons[button] = nil
			changed = true
		end
	end
	if changed and lib.FluxLABSyncOnUpdateArm then
		lib.FluxLABSyncOnUpdateArm()
	end
end

-- Immediate range sample + paint (paging / target / mouseover). Avoids waiting
-- for the next OnUpdate tick so Main↔mini and Bar↔badge never leave stale red.
local function SampleButtonRange(button)
	if not button then return end
	if button._fluxParkedOffscreen
		or (button.IsShown and not button:IsShown()) then
		local FR = _G.FluxRange
		if FR and FR.ClearFlag then FR.ClearFlag(button) else
			button.outOfRange = false
		end
		lib.rangeButtons[button] = nil
		return
	end
	-- Ensure membership before sampling (paging show path).
	if not lib.rangeButtons[button] then
		ClassifyRange(button)
	end
	if not lib.rangeButtons[button] then
		local wasOOR = button.outOfRange
		local FR = _G.FluxRange
		if FR and FR.ClearFlag then FR.ClearFlag(button) else
			button.outOfRange = false
		end
		if wasOOR and button.config and button.config.outOfRangeColoring == "button"
			and not _G._fluxPagingInProgress then
			UpdateUsable(button, true)
		end
		return
	end
	local inRange = button:IsInRange()
	local oldRange = button.outOfRange
	button.outOfRange = (inRange == false)
	if button.outOfRange then
		lib._fluxAnyOutOfRange = true
	end
	if oldRange ~= button.outOfRange then
		if button.config and button.config.outOfRangeColoring == "button" then
			if not _G._fluxPagingInProgress then
				UpdateUsable(button, true)
			elseif button.icon then
				-- Paging: tint without IsUsableAction. Must also clear stale red.
				if button.outOfRange then
					button.icon:SetVertexColor(unpack(button.config.colors.range))
				else
					button.icon:SetVertexColor(1.0, 1.0, 1.0)
				end
				button._fluxUsablePaintKey = nil -- force full usable after paging clears
			end
		elseif button.config and button.config.outOfRangeColoring == "hotkey" then
			local hotkey = button.HotKey
			if hotkey then
				if hotkey:GetText() == RANGE_INDICATOR then
					if inRange == false then
						hotkey:Show()
					else
						hotkey:Hide()
					end
				end
				if inRange == false then
					hotkey:SetVertexColor(unpack(button.config.colors.range))
				else
					hotkey:SetVertexColor(unpack(button.config.text.hotkey.color))
				end
			end
		end
	end
end

local function SampleAllRangeButtons()
	for button in next, lib.rangeButtons do
		SampleButtonRange(button)
	end
	if lib.FluxLABScrubParkedRangeButtons then
		lib.FluxLABScrubParkedRangeButtons()
	end
end

function lib.ForceRangeSample()
	rangeTimer = -1
	SampleAllRangeButtons()
	-- Range ticker owns continuous polls; do not arm OnUpdate for range alone.
	if lib.FluxLABEnsureRangeTicker then
		lib.FluxLABEnsureRangeTicker()
	elseif lib.FluxLABSyncOnUpdateArm then
		lib.FluxLABSyncOnUpdateArm()
	end
end

--- Flush deferred ACTIONBAR_UPDATE_STATE → UpdateButtonState, or keep pending
--- while paging is latched (CatchUpUsableRange calls this after latch clear).
function lib.FluxFlushPendingActionBarUpdateState()
	if _G._fluxPagingInProgress then
		lib.fluxDefer.pendingActionBarUpdateState = true
		return
	end
	lib.fluxDefer.pendingActionBarUpdateState = false
	for button in next, ActionButtonsNonUI do
		UpdateButtonState(button)
	end
end

lib.SampleButtonRange = SampleButtonRange
lib.InvalidateRange = function(button)
	if not button then return end
	local FR = _G.FluxRange
	if FR and FR.ClearFlag then
		FR.ClearFlag(button)
	else
		button.outOfRange = false
	end
	if lib.rangeButtons[button] then
		SampleButtonRange(button)
	elseif button.config and button.config.outOfRangeColoring == "button"
		and not _G._fluxPagingInProgress then
		UpdateUsable(button, true)
	end
end

function FluxLABSyncAssistedCombatIndex(self)
	local isAssist = false
	if ActiveButtons[self] and self._state_type == "action" and type(self._state_action) == "number"
			and C_ActionBar and C_ActionBar.IsAssistedCombatAction then
		isAssist = C_ActionBar.IsAssistedCombatAction(self._state_action)
	end
	if isAssist then
		lib.assistedCombatButtons[self] = true
	else
		lib.assistedCombatButtons[self] = nil
	end
end

function lib.FluxShouldRefreshAssistedHighlightOnUpdate(self)
	if not self.config.assistedHighlight or not AssistedCombatManager then
		return false
	end
	local spellID = AssistedCombatManager.lastNextCastSpellID
	if not spellID then
		return self.AssistedCombatHighlightFrame ~= nil
	end
	local candidates = AssistedCombatManager.assistedHighlightCandidateActionButtons
	if candidates and candidates[self] then
		return true
	end
	return self:GetSpellId() == spellID
end

function Update(self, instant)
	if self:HasAction() then
		ActiveButtons[self] = true
		if self._state_type == "action" then
			ActionButtons[self] = true
			NonActionButtons[self] = nil
			if not self.config.actionButtonUI then
				ActionButtonsNonUI[self] = true
			end
		else
			ActionButtons[self] = nil
			NonActionButtons[self] = true
			ActionButtonsNonUI[self] = nil
		end
		ClassifyRange(self)
		self:SetAlpha(1.0)
		UpdateButtonState(self)
		-- During main↔mini paging / mod hold: skip usable entirely (paint transferred /
		-- icon already correct). This is the bulk of UpdateUsable spam while holding SHIFT.
		if not _G._fluxPagingInProgress then
			UpdateUsable(self, true)
		end
		-- Immediate range sample so Main↔mini / Binding overlay swaps never leave stale red.
		SampleButtonRange(self)
		UpdateCooldown(self)
		UpdateFlash(self)
	else
		ActiveButtons[self] = nil
		ActionButtons[self] = nil
		NonActionButtons[self] = nil
		ActionButtonsNonUI[self] = nil
		lib.rangeButtons[self] = nil
		lib.assistedCombatButtons[self] = nil
		self.outOfRange = false
		-- Flux perf T1.1: also clear narrow helper sets so a deactivated button
		-- cannot leak into the per-frame OnUpdate iteration.
		lib.fluxVFXButtons[self] = nil
		lib.fluxFlashingButtons[self] = nil
		if gridCounter == 0 and not self.config.showGrid then
			self:SetAlpha(0.0)
		end
		self.cooldown:Hide()
		self:SetChecked(false)

		if ClearActionButtonCooldowns then
			ClearActionButtonCooldowns(self.cooldown, self.chargeCooldown, self.lossOfControlCooldown)
		else
			ClearChargeCooldown(self)
		end

		if self.LevelLinkLockIcon then
			self.LevelLinkLockIcon:SetShown(false)
		end
	end

	-- Add a green border if button is an equipped item
	if self:IsEquipped() and not self.config.hideElements.equipped then
		self.Border:SetVertexColor(0, 1.0, 0, 0.35)
		self.Border:Show()
	else
		self.Border:Hide()
	end

	-- Update Action Text
	if not self:IsConsumableOrStackable() then
		self.Name:SetText(self:GetActionText())
	else
		self.Name:SetText("")
	end

	-- Update icon and hotkey
	local texture = self:GetTexture()

	-- Zone ability button handling
	self.zoneAbilityDisabled = false
	self.icon:SetDesaturated(false)
	-- Preserve lower-rank colorless when UpdateUsable is gated (paging latch).
	if self._fluxRankDesaturated then
		self.icon:SetDesaturated(true)
	end

	if texture then
		self.icon:SetTexture(texture)
		self.icon:Show()
		self.rangeTimer = - 1
		if WoWRetail then
			if not self.MasqueSkinned then
				self.SlotBackground:Hide()
				if self.config.hideElements.border then
					self.NormalTexture:SetTexture()
					self.icon:RemoveMaskTexture(self.IconMask)
					self.HighlightTexture:SetSize(52, 51)
					self.HighlightTexture:SetPoint("TOPLEFT", self, "TOPLEFT", -2.5, 2.5)
					self.CheckedTexture:SetSize(52, 51)
					self.CheckedTexture:SetPoint("TOPLEFT", self, "TOPLEFT", -2.5, 2.5)
					self.cooldown:ClearAllPoints()
					self.cooldown:SetAllPoints()
				else
					self:SetNormalAtlas("UI-HUD-ActionBar-IconFrame-AddRow")
					self.icon:AddMaskTexture(self.IconMask)
					self.HighlightTexture:SetSize(46, 45)
					self.HighlightTexture:SetPoint("TOPLEFT")
					self.CheckedTexture:SetSize(46, 45)
					self.CheckedTexture:SetPoint("TOPLEFT")
					self.cooldown:ClearAllPoints()
					self.cooldown:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -2)
					self.cooldown:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, 3)
				end
			end
		else
			self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
			if not self.LBFSkinned and not self.MasqueSkinned then
				-- Set proper texture coordinates to show the full texture
				self.NormalTexture:SetTexCoord(0, 1, 0, 1)
			end
		end
	else
		self.icon:Hide()
		if ClearActionButtonCooldowns then
			ClearActionButtonCooldowns(self.cooldown, self.chargeCooldown, self.lossOfControlCooldown)
		else
			self.cooldown:Hide()
		end
		self.rangeTimer = nil
		if self.HotKey:GetText() == RANGE_INDICATOR then
			self.HotKey:Hide()
		else
			self.HotKey:SetVertexColor(unpack(self.config.text.hotkey.color))
		end
		if WoWRetail then
			if not self.MasqueSkinned then
				self.SlotBackground:Show()
				if self.config.hideElements.borderIfEmpty then
					self.NormalTexture:SetTexture()
				else
					self:SetNormalAtlas("UI-HUD-ActionBar-IconFrame-AddRow")
				end
			end
		else
			-- FLUX MODIFICATION: Use UI-Quickslot2 (ring border) instead of UI-Quickslot (flat)
			-- This ensures universal styling across all clients matching the classic ring border look
			self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
			if not self.LBFSkinned and not self.MasqueSkinned then
				-- Set proper texture coordinates to show the full texture
				self.NormalTexture:SetTexCoord(0, 1, 0, 1)
			end
		end
	end

	self:UpdateLocal()

	UpdateCount(self)

	UpdateFlyout(self)

	UpdateOverlayGlow(self, instant)

	UpdateNewAction(self)

	UpdateSpellHighlight(self)

	UpdateAssistedCombatRotationFrame(self)

	if lib.FluxShouldRefreshAssistedHighlightOnUpdate(self) then
		UpdatedAssistedHighlightFrame(self)
	end

	UpdateSpellVFX(self)

	if GameTooltip_GetOwnerForbidden() == self then
		UpdateTooltip(self)
	end

	-- this could've been a spec change, need to call OnStateChanged for action buttons, if present
	if not InCombatLockdown() and self._state_type == "action" then
		local onStateChanged = self:GetAttribute("OnStateChanged")
		if onStateChanged then
			self.header:SetFrameRef("updateButton", self)
			self.header:Execute(([[
				local frame = self:GetFrameRef("updateButton")
				control:RunFor(frame, frame:GetAttribute("OnStateChanged"), %s, %s, %s)
			]]):format(formatHelper(self:GetAttribute("state")), formatHelper(self._state_type), formatHelper(self._state_action)))
		end
	end
	-- Flux: LAB resets Highlight/Checked to 46×45 (or 52×51) on mainline; Classic never hits that branch but still needs reapply.
	-- Empty slots skip the texture path above — reapply for all clients (not WoWRetail-gated).
	if not self.MasqueSkinned then
		local h = _G.FluxActionBarAnisoHelpers
		if h and h.ReapplyHighlightCheckedAfterLabUpdate then
			local n = self:GetName() or ""
			if n:match("^Flux") then
				h.ReapplyHighlightCheckedAfterLabUpdate(self)
			end
		end
	end
	FluxLABSyncSlotButtonMap(self)
	FluxLABSyncMouseoverMacroIndex(self)
	-- Flux perf T2.1: keep spellId + flyout indexes synced with the latest state.
	FluxLABSyncSpellIdIndex(self)
	FluxLABSyncFlyoutActionIndex(self)
	FluxLABSyncAssistedCombatIndex(self)
	if AssistedCombatManager and AssistedCombatManager.IsAssistedHighlightActive
		and AssistedCombatManager:IsAssistedHighlightActive() then
		lib.FluxRegisterLabButtonAssistedHighlightCandidate(self)
	end
	lib.callbacks:Fire("OnButtonUpdate", self)
end

function Generic:UpdateLocal()
-- dummy function the other button types can override for special updating
end

function UpdateButtonState(self)
	-- Dual-split: Exclusive owns checked. Stock IsCurrentAction / Action.GetSpellId
	-- would light Summon on the Freeze icon forever — never trust slot GetSpellId.
	if self._fluxExclusiveCheckedManaged then
		local function clearLabChecked()
			self._fluxIsCheckedOwner = nil
			if self.SetChecked then
				self._fluxSuppressCheckedHook = true
				self:SetChecked(false)
				self._fluxSuppressCheckedHook = nil
			end
			local tex = self.GetCheckedTexture and self:GetCheckedTexture()
			if tex and tex.Hide then
				tex:Hide()
			end
		end

		if self._fluxIsCheckedOwner then
			-- Display spell only: macrotext parse or aspect — NEVER Action.GetSpellId.
			local sid = nil
			if self._state_type == "macrotext" and self.GetSpellId then
				local ok, s = pcall(self.GetSpellId, self)
				if ok and type(s) == "number" and s > 0 then sid = s end
			end
			if not sid then
				sid = tonumber(self._fluxAspectDisplaySpellId)
			end
			local stillCurrent = false
			if sid and sid > 0 then
				if C_Spell and C_Spell.IsCurrentSpell then
					local ok, r = pcall(C_Spell.IsCurrentSpell, sid)
					stillCurrent = ok and r
				elseif IsCurrentSpell then
					local ok, r = pcall(IsCurrentSpell, sid)
					stillCurrent = ok and r
				end
			end
			if stillCurrent then
				return
			end
			clearLabChecked()
			local col = self._fluxBarSlotIndex
			if type(col) == "number" and C_Timer and C_Timer.After then
				C_Timer.After(0, function()
					local Ck = _G.FluxEffectChecked or _G.FluxBadgeCheckedDrive
					if Ck and Ck.SettleColumn then
						pcall(Ck.SettleColumn, col, { discover = true })
					end
				end)
			end
			return
		end

		clearLabChecked()
		return
	end
	if self:IsCurrentlyActive() or self:IsAutoRepeat() then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end
end

function UpdateUsable(self, force, granularInfo)
	if _G.FluxLABUsableEventDebug then
		lib._fluxDbgUpdateUsableCalls = lib._fluxDbgUpdateUsableCalls + 1
	end
	-- FMacLag (Actionbars/FluxMacroConditionalLagDebug): granular ACTION_USABLE_CHANGED often skips IsUsableAction
	if _G.FMacLag and _G.FMacLag.enabled then
		_G.FMacLag.updateUsableTotal = (_G.FMacLag.updateUsableTotal or 0) + 1
		if granularInfo then
			_G.FMacLag.updateUsableGranular = (_G.FMacLag.updateUsableGranular or 0) + 1
		end
	end

	if not self:HasAction() then return end

	local slotForLock = self._state_type == "action" and tonumber(self._state_action)

	if not force and not granularInfo then
		local now = GetTime()
		local minI = tonumber(_G.FluxActionUsableMinInterval) or 0
		if self._state_type == "action" and slotForLock then
			local atype = select(1, GetActionInfo(self._state_action))
			if atype == "macro" then
				minI = math.max(minI, tonumber(_G.FluxLABMacroUsableMinInterval) or 0)
				if _G.FluxLABMouseoverFlushActive then
					minI = math.max(minI, tonumber(_G.FluxLABMouseoverUsableMinInterval) or tonumber(_G.FluxMouseoverUpdateInterval) or 0.07)
				end
			end
		end
		if minI > 0 then
			local last = self._fluxUsableThrottleT or 0
			if (now - last) < minI then
				return
			end
			self._fluxUsableThrottleT = now
		end
	end

	local isLevelLinkLocked
	if WoWRetail and self._state_type == "action" then
		if slotForLock then
			local ent = lib.fluxDefer.levelLinkCache[slotForLock]
			if ent and ent.gen == lib.fluxDefer.levelLinkCacheGen then
				isLevelLinkLocked = ent.v
			else
				isLevelLinkLocked = C_LevelLink.IsActionLocked(self._state_action)
				lib.fluxDefer.levelLinkCache[slotForLock] = { gen = lib.fluxDefer.levelLinkCacheGen, v = isLevelLinkLocked }
			end
		else
			isLevelLinkLocked = C_LevelLink.IsActionLocked(self._state_action)
		end
	end

	local isUsable, notEnoughMana
	if self.config.outOfRangeColoring == "button" and self.outOfRange then
		if _G.FluxLABUsablePaintCache ~= false and not force then
			local pkey = "R|" .. tostring(isLevelLinkLocked or false)
			if self._fluxUsablePaintKey == pkey then
				return
			end
			self._fluxUsablePaintKey = pkey
		end
		self.icon:SetVertexColor(unpack(self.config.colors.range))
	else
		if granularInfo then
			isUsable = granularInfo.usable
			notEnoughMana = granularInfo.noMana
			if isUsable == nil and notEnoughMana == nil then
				isUsable, notEnoughMana = self:IsUsable()
			elseif isUsable == nil then
				isUsable, notEnoughMana = self:IsUsable()
			end
		else
			isUsable, notEnoughMana = self:IsUsable()
		end

		-- Secret / inaccessible (Midnight): keep last vertex tint, do not force white.
		if isUsable == nil and notEnoughMana == nil then
			if self._fluxRankDesaturated and self.icon and self.icon.SetDesaturated then
				self.icon:SetDesaturated(true)
			end
			return
		end

		if _G.FluxLABUsablePaintCache ~= false and not force then
			local pkey = string.format("U|%s|%s|%s", tostring(isUsable), tostring(notEnoughMana), tostring(isLevelLinkLocked or false))
			if self._fluxUsablePaintKey == pkey then
				if WoWRetail and self._state_type == "action" then
					if self._fluxRankDesaturated then
						self.icon:SetDesaturated(true)
					elseif not self.icon:IsDesaturated() then
						self.icon:SetDesaturated(isLevelLinkLocked)
					end
					if self.LevelLinkLockIcon then
						self.LevelLinkLockIcon:SetShown(isLevelLinkLocked)
					end
				elseif self._fluxRankDesaturated and self.icon and self.icon.SetDesaturated then
					self.icon:SetDesaturated(true)
				end
				return
			end
			self._fluxUsablePaintKey = pkey
		end

		if slotForLock and _G.FluxCacheUsableActionForMacroHook then
			_G.FluxCacheUsableActionForMacroHook(slotForLock, isUsable, notEnoughMana)
		end

		if isUsable then
			self.icon:SetVertexColor(1.0, 1.0, 1.0)
		elseif notEnoughMana then
			self.icon:SetVertexColor(unpack(self.config.colors.mana))
		else
			self.icon:SetVertexColor(0.4, 0.4, 0.4)
		end
	end

	if WoWRetail and self._state_type == "action" then
		-- Level-link lock only. Never clear lower-rank colorless (_fluxRankDesaturated).
		if self._fluxRankDesaturated then
			self.icon:SetDesaturated(true)
		elseif not self.icon:IsDesaturated() then
			self.icon:SetDesaturated(isLevelLinkLocked)
		elseif isLevelLinkLocked then
			self.icon:SetDesaturated(true)
		end

		if self.LevelLinkLockIcon then
			self.LevelLinkLockIcon:SetShown(isLevelLinkLocked)
		end
	end
end

local function FlushBroadcastUsableNow()
	FluxLABBeginUsableBatch()

	if lib.LABShouldSkipFullBroadcastUsable() then
		lib._fluxDbgSkippedBroadcast = lib._fluxDbgSkippedBroadcast + 1
		wipe(lib.fluxDefer.granularUsableSlotsThisTick)
		return
	end

	lib._fluxDbgBroadcastUsable = lib._fluxDbgBroadcastUsable + 1

	for button in next, ActionButtons do
		if not lib.LABBroadcastShouldSkipButton(button) then
			UpdateUsable(button, true)
		end
	end
	wipe(lib.fluxDefer.granularUsableSlotsThisTick)
end

FlushMouseoverActionUsable = function()
	FluxLABBeginUsableBatch()
	lib._fluxDbgBroadcastUsable = lib._fluxDbgBroadcastUsable + 1
	local set = lib.fluxMouseoverMacroButtons
	if set then
		for button in next, set do
			UpdateUsable(button, true)
		end
	end
	wipe(lib.fluxDefer.granularUsableSlotsThisTick)
end

if FluxMouseoverRefresh and FluxMouseoverRefresh.Register then
	FluxMouseoverRefresh.Register("LAB", FlushMouseoverActionUsable)
end

ScheduleFlushBroadcastUsable = function()
	if _G.FluxLABDeferBroadcastUsable == false then
		FlushBroadcastUsableNow()
		return
	end
	local FE = _G.FluxButtonEvents
	if FE and FE.IsFormStormActive and FE.IsFormStormActive() then
		lib.fluxDefer.pendingBroadcastUsable = true
		return
	end
	lib.fluxDefer.pendingBroadcastUsable = true
	if lib.fluxDefer.fluxBroadcastUsableDeferTimer then
		return
	end
	if C_Timer and C_Timer.After then
		lib.fluxDefer.fluxBroadcastUsableDeferTimer = true
		C_Timer.After(0, function()
			lib.fluxDefer.fluxBroadcastUsableDeferTimer = false
			local FE2 = _G.FluxButtonEvents
			if FE2 and FE2.IsFormStormActive and FE2.IsFormStormActive() then
				-- Leave pending; form-storm settle flushes.
				return
			end
			if lib.fluxDefer.pendingBroadcastUsable then
				lib.fluxDefer.pendingBroadcastUsable = false
				FlushBroadcastUsableNow()
			end
		end)
	else
		lib.fluxDefer.pendingBroadcastUsable = false
		FlushBroadcastUsableNow()
	end
end

-- After ExtraButton form/power storm: one LAB usable + state flush.
do
	local function FlushLABAfterFormStorm()
		-- Slot-0 full pending already covers every action button; skip per-slot redo.
		if lib.fluxDefer.pendingActionBarSlotChangedAll then
			lib.fluxDefer.pendingFormStormSlots = nil
			lib.fluxDefer.pendingActionBarSlotChangedSlots = {}
			FlushActionBarSlotChangedAll()
		else
			FlushFormStormPendingSlotsFull()
			if next(lib.fluxDefer.pendingActionBarSlotChangedSlots) then
				FlushActionBarSlotChangedSlots()
			end
		end
		if lib.fluxDefer.pendingBroadcastUsable then
			lib.fluxDefer.pendingBroadcastUsable = false
			FlushBroadcastUsableNow()
		end
		if lib.fluxDefer.pendingActionBarUpdateState then
			lib.fluxDefer.pendingActionBarUpdateState = false
			for button in next, ActionButtonsNonUI do
				UpdateButtonState(button)
			end
		end
		if lib.fluxDefer.pendingSpellUsable and ScheduleSpellUsableFlush then
			lib.fluxDefer.pendingSpellUsable = false
			ScheduleSpellUsableFlush()
		end
	end
	local function HookFormStormSettled()
		local FE = _G.FluxButtonEvents
		if FE and FE.RegisterFormStormSettled and not lib._fluxFormStormSettledHooked then
			lib._fluxFormStormSettledHooked = true
			FE.RegisterFormStormSettled("LAB_usable_state", FlushLABAfterFormStorm)
		end
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, HookFormStormSettled)
		C_Timer.After(1, HookFormStormSettled)
	else
		HookFormStormSettled()
	end
end

function UpdateCount(self)
	if not self:HasAction() then
		self.Count:SetText("")
		return
	end
	if C_ActionBar and C_ActionBar.GetActionDisplayCount and self._state_type == "action" then
		self.Count:SetText(C_ActionBar.GetActionDisplayCount(self._state_action, self.maxDisplayCount or 9999))
		return
	end
	-- Binding macrotext: fall back to underlying slot display when the body has not
	-- resolved to an item/spell yet (parity with native GetActionDisplayCount).
	if self._state_type == "macrotext"
		and C_ActionBar and C_ActionBar.GetActionDisplayCount
		and self.GetMacrotextSlot then
		local resolved = self.GetMacrotextDisplay and self:GetMacrotextDisplay()
		local hasResolved = resolved and (resolved.itemID or resolved.spellID)
		if not hasResolved then
			local slot = tonumber(self:GetMacrotextSlot())
			if slot then
				self.Count:SetText(C_ActionBar.GetActionDisplayCount(slot, self.maxDisplayCount or 9999))
				return
			end
		end
	end
	if self:IsConsumableOrStackable() then
		local count = self:GetCount()
		if count > (self.maxDisplayCount or 9999) then
			self.Count:SetText("*")
		else
			self.Count:SetText(count)
		end
	else
		local charges, maxCharges, _chargeStart, _chargeDuration = self:GetCharges()
		if charges and maxCharges and maxCharges > 1 then
			self.Count:SetText(charges)
		else
			self.Count:SetText("")
		end
	end
end

function ClearChargeCooldown(self)
	if self.chargeCooldown then
		CooldownFrame_Clear(self.chargeCooldown)
	end
end

local function CreateChargeCooldownFrame(parent)
	lib.NumChargeCooldowns = lib.NumChargeCooldowns + 1
	local cooldown = CreateFrame("Cooldown", "LAB10ChargeCooldown"..lib.NumChargeCooldowns, parent, "CooldownFrameTemplate");
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawSwipe(false)
	cooldown:SetPoint("TOPLEFT", parent.icon, "TOPLEFT", 2, -2)
	cooldown:SetPoint("BOTTOMRIGHT", parent.icon, "BOTTOMRIGHT", -2, 2)
	cooldown:SetFrameLevel(parent:GetFrameLevel())
	return cooldown
end

local function StartChargeCooldown(parent, chargeStart, chargeDuration, chargeModRate)
	if chargeStart == 0 then
		ClearChargeCooldown(parent)
		return
	end

	parent.chargeCooldown = parent.chargeCooldown or CreateChargeCooldownFrame(parent)

	CooldownFrame_Set(parent.chargeCooldown, chargeStart, chargeDuration, true, true, chargeModRate)

	-- update charge cooldown skin when masque is used
	if Masque and Masque.UpdateCharge then
		Masque:UpdateCharge(parent)
	end
end

local function OnCooldownDone(self, requireCooldownUpdate)
	self:SetScript("OnCooldownDone", nil)
	if requireCooldownUpdate then
		UpdateCooldown(self:GetParent())
	end
end

function UpdateCooldownNumberHidden(self)
	local shouldBeHidden
	if self.config.cooldownCount == nil then
		shouldBeHidden = GetCVarBool("countdownForCooldowns") ~= true
	else
		shouldBeHidden = not self.config.cooldownCount
	end
	self.cooldown:SetHideCountdownNumbers(shouldBeHidden)
end

local defaultCooldownInfo = { startTime = 0; duration = 0; isEnabled = false; isActive = false; modRate = 0 }
local defaultChargeInfo = { currentCharges = 0; maxCharges = 0; cooldownStartTime = 0; cooldownDuration = 0; chargeModRate = 0; isActive = false }
local defaultLossOfControlInfo = { startTime = 0; duration = 0; modRate = 0; isActive = false; shouldReplaceNormalCooldown = false; }

local _, buildNumber = GetBuildInfo()
local SecretCooldownsUseDuration = WoWRetail and tonumber(buildNumber) >= 66562
if SecretCooldownsUseDuration then
	local function SetOrClearCooldown(cooldown, shouldShow, durationObject)
		if not cooldown then return end
		if not shouldShow or not durationObject then
			cooldown:Clear()
			return
		end
		cooldown:SetCooldownFromDurationObject(durationObject)
	end

	function UpdateCooldown(self)
		local cooldownInfo = self:GetCooldownInfo() or defaultCooldownInfo
		local chargeInfo = self:GetChargeInfo() or defaultChargeInfo
		local locInfo = self:GetLoCCooldownInfo() or defaultLossOfControlInfo

		local showLoC = locInfo.isActive
		local showCharge = not locInfo.shouldReplaceNormalCooldown and chargeInfo.isActive
		local showNormal = not locInfo.shouldReplaceNormalCooldown and cooldownInfo.isActive

		SetOrClearCooldown(self.cooldown, showNormal, self:GetCooldownDuration())
		SetOrClearCooldown(self.chargeCooldown, showCharge, self:GetChargeDuration())
		SetOrClearCooldown(self.lossOfControlCooldown, showLoC, self:GetLoCCooldownDuration())
	end
else
	function UpdateCooldown(self)
		local chargeInfo
		local cooldownInfo
		local lossOfControlInfo = {}

		local auraData

		local passiveCooldownSpellID = self:GetPassiveCooldownSpellID()
		if passiveCooldownSpellID and passiveCooldownSpellID ~= 0 then
			auraData = C_UnitAuras.GetPlayerAuraBySpellID(passiveCooldownSpellID)
		end

		if auraData then
			local currentTime = GetTime()
			local timeUntilExpire = auraData.expirationTime - currentTime
			local howMuchTimeHasPassed = auraData.duration - timeUntilExpire

			lossOfControlInfo.startTime = currentTime - howMuchTimeHasPassed
			lossOfControlInfo.duration = auraData.expirationTime - currentTime
			lossOfControlInfo.modRate = auraData.timeMod
			cooldownInfo = {}
			cooldownInfo.startTime = currentTime - howMuchTimeHasPassed
			cooldownInfo.duration = auraData.duration
			cooldownInfo.modRate = auraData.timeMod
			cooldownInfo.isEnabled = 1
			chargeInfo = {}
			chargeInfo.currentCharges = auraData.charges
			chargeInfo.maxCharges = auraData.maxCharges
			chargeInfo.cooldownStartTime = currentTime * 0.001
			chargeInfo.cooldownDuration = auraData.duration * 0.001
			chargeInfo.chargeModRate = auraData.timeMod
		else
			cooldownInfo = self:GetCooldownInfo() or defaultCooldownInfo
			chargeInfo = self:GetChargeInfo() or defaultChargeInfo

			local locStart, locDuration = self:GetLossOfControlCooldown()
			lossOfControlInfo.startTime = locStart
			lossOfControlInfo.duration = locDuration
			lossOfControlInfo.modRate = cooldownInfo.modRate
		end

		if not self.config.lossOfControlCooldown or not lossOfControlInfo or not lossOfControlInfo.startTime or not lossOfControlInfo.duration then
			lossOfControlInfo = defaultLossOfControlInfo
		end

		if not cooldownInfo or not cooldownInfo.startTime or not cooldownInfo.duration then
			cooldownInfo = defaultCooldownInfo
		end

		if not chargeInfo or not chargeInfo.maxCharges or not chargeInfo.currentCharges or not chargeInfo.cooldownStartTime or not chargeInfo.cooldownDuration then
			chargeInfo = defaultChargeInfo
		end

		self.cooldown:SetDrawBling(self.cooldown:GetEffectiveAlpha() > 0.5)

		-- 12.0 helper function
		if ActionButton_ApplyCooldown then
			ActionButton_ApplyCooldown(self.cooldown, cooldownInfo, self.chargeCooldown, chargeInfo, self.lossOfControlCooldown, lossOfControlInfo)
			-- Ensure overlay is visible: SpellVFX or other code may have set SetSwipeColor(0,0,0,0)
			-- Use pcall to avoid "secret boolean" taint error when cooldownInfo.isEnabled was tainted by addon code
			local hasCooldown
			do
				local ok, v = pcall(function()
					return cooldownInfo.isEnabled and cooldownInfo.startTime and cooldownInfo.duration and cooldownInfo.startTime > 0 and cooldownInfo.duration > 0
				end)
				hasCooldown = ok and v
			end
			if hasCooldown and self.cooldown.SetDrawSwipe then
				self.cooldown:SetDrawSwipe(true)
			end
			if hasCooldown then
				self.cooldown:Show()
				self.cooldown:SetSwipeColor(0, 0, 0, 1)
			end
		else
			local locStart, locDuration = lossOfControlInfo.startTime, lossOfControlInfo.duration
			-- Use pcall to avoid "secret boolean" taint error when cooldownInfo.isEnabled was tainted by addon code
			local start, duration, enable, modRate
			do
				local ok, s, d, e, m = pcall(function()
					return cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnabled, cooldownInfo.modRate
				end)
				if ok then
					start, duration, enable, modRate = s, d, e, m
				else
					start, duration, enable, modRate = 0, 0, false, 1
				end
			end
			local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = chargeInfo.currentCharges, chargeInfo.maxCharges, chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration, chargeInfo.chargeModRate

			local hasLocCooldown = locStart and locDuration and locStart > 0 and locDuration > 0
			local hasCooldown = enable and start and duration and start > 0 and duration > 0
			if hasLocCooldown and ((not hasCooldown) or ((locStart + locDuration) > (start + duration))) then
				if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_LOSS_OF_CONTROL then
					self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge-LoC")
					self.cooldown:SetSwipeColor(0.17, 0, 0, 1)
					self.cooldown.currentCooldownType = COOLDOWN_TYPE_LOSS_OF_CONTROL
					UpdateCooldownNumberHidden(self)
				else
					-- Always ensure swipe is visible (SpellVFX may have set it transparent)
					self.cooldown:SetSwipeColor(0.17, 0, 0, 1)
				end
				if self.cooldown.SetDrawSwipe then self.cooldown:SetDrawSwipe(true) end
				self.cooldown:Show()
				CooldownFrame_Set(self.cooldown, locStart, locDuration, true, true, modRate)
				self.cooldown:SetScript("OnCooldownDone", OnCooldownDone, false)
				ClearChargeCooldown(self)
			else
				if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL then
					self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
					self.cooldown:SetSwipeColor(0, 0, 0, 1)
					self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
					UpdateCooldownNumberHidden(self)
				else
					-- Always ensure swipe is visible (SpellVFX may have set it transparent)
					self.cooldown:SetSwipeColor(0, 0, 0, 1)
				end
				if self.cooldown.SetDrawSwipe then self.cooldown:SetDrawSwipe(true) end
				self.cooldown:Show()
				self.cooldown:SetScript("OnCooldownDone", OnCooldownDone, hasLocCooldown)

				if charges and maxCharges and maxCharges > 1 and charges < maxCharges then
					StartChargeCooldown(self, chargeStart, chargeDuration, chargeModRate)
				else
					ClearChargeCooldown(self)
				end
				CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate)
			end
		end
	end
end

function StartFlash(self)
	self.flashing = 1
	lib.fluxFlashingButtons[self] = true
	flashTime = 0
	UpdateButtonState(self)
	if lib.FluxLABSyncOnUpdateArm then lib.FluxLABSyncOnUpdateArm() end
end

function StopFlash(self)
	self.flashing = 0
	lib.fluxFlashingButtons[self] = nil
	self.Flash:Hide()
	UpdateButtonState(self)
	if lib.FluxLABSyncOnUpdateArm then lib.FluxLABSyncOnUpdateArm() end
end

function UpdateFlash(self)
	if (self:IsAttack() and self:IsCurrentlyActive()) or self:IsAutoRepeat() then
		StartFlash(self)
	else
		StopFlash(self)
	end
end

-- FLUX MODIFICATION: FluxTooltipGuard may replace GameTooltip:AddLine with a noop while ExtraButton
-- tooltips are built; Unblock before SetAction/SetSpell so TooltipDataHandler can add lines.
-- Sync path matches Bartender4 / Blizzard (SetOwner then SetAction); no first-show deferral.
-- pcall around SetTooltip: tainted OnEnter + secret tooltip colors can error from GetRGB.
function UpdateTooltip(self)
	if GameTooltip:IsForbidden() then return end
	-- LibKeyBound owns GameTooltip from Binder:OnEnter; do not refresh the action tooltip on top of it.
	if IsBindingModeTooltipOwned() then
		return
	end
	-- FLUX: keep button as owner; place like Other/FluxHUDTooltip.lua (FluxWindowFrame TOPLEFT + 30).
	if FluxSetHUDTooltipOwner and FluxSetHUDTooltipOwner(GameTooltip, self) then
		-- HUD owner + point applied
	elseif (GetCVar("UberTooltips") == "1") then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	if FluxTooltipGuard and FluxTooltipGuard.Reset then
		FluxTooltipGuard.Reset(GameTooltip)
	elseif FluxTooltipGuard and FluxTooltipGuard.Unblock then
		FluxTooltipGuard.Unblock(GameTooltip)
	end
	local tipOk = false
	local ok, result = pcall(self.SetTooltip, self)
	if ok then
		tipOk = result and true or false
	end
	-- Retail SetSpellByID/SetAction often return nil even when the tip shows.
	if tipOk or (GameTooltip and GameTooltip:IsShown()) then
		self.UpdateTooltip = UpdateTooltip
		if FluxBindingTooltip and FluxBindingTooltip.OnLabTooltip then
			FluxBindingTooltip.OnLabTooltip(self)
		elseif FluxBindingTooltip and FluxBindingTooltip.AppendForButton then
			FluxBindingTooltip.AppendForButton(self)
		end
	else
		self.UpdateTooltip = nil
	end
end

function UpdateHotkeys(self)
	local key = self:GetHotkey()
	if not key or key == "" or self.config.hideElements.hotkey then
		self.HotKey:SetText(RANGE_INDICATOR)
		self.HotKey:Hide()
	else
		self.HotKey:SetText(key)
		self.HotKey:Show()
	end
end

--- Flux: one-shot hotkey refresh after bulk SetBinding (UPDATE_BINDINGS was suppressed).
function lib.FluxFlushHotkeys()
	lib._fluxDeferredHotkeyUpdate = nil
	ForAllButtons(UpdateHotkeys)
end

function ShowOverlayGlow(self, skipAnim)
	-- Post-DF retail: EffectGlow owns paint via LibCustomGlow ProcGlow.
	-- Do not call LBG (classic ants) or we double-paint the old look.
	local api = _G.FLUX_API
	if api and not api.isPreDF and not api.isAnyClassic then
		return
	end
	-- Pre-DF/classic: EffectGlow is paint authority. LAB only signals membership;
	-- never recreate ants on a non-owner row after main↔mini / badge↔bar paging.
	local G = _G.FluxEffectGlow
	local R = _G.FluxEffectRouter
	local col = self and self._fluxBarSlotIndex
	local sid = self and self.GetSpellId and self:GetSpellId()
	-- Under paging latch: refuse paint unless this button's ACTION SLOT holds the
	-- glowing spell. Stale GetSpellId on mainrow was re-forcing glow onto main.
	if _G._fluxPagingInProgress and type(col) == "number" and sid and G then
		local slot = self._state_action or self.action
		if type(slot) ~= "number" and self.GetAttribute then
			slot = self:GetAttribute("action")
		end
		local slotMatches = false
		if type(slot) == "number" and slot > 0 and GetActionInfo then
			local atype, aid = GetActionInfo(slot)
			if atype == "spell" and aid and R and R.SameSpellFamily and R.SameSpellFamily(aid, sid) then
				slotMatches = true
				sid = aid
			elseif atype == "spell" and aid and aid == sid then
				slotMatches = true
			elseif atype == "macro" and aid and GetMacroSpell then
				local ms = GetMacroSpell(aid)
				if ms and ((R and R.SameSpellFamily and R.SameSpellFamily(ms, sid)) or ms == sid) then
					slotMatches = true
					sid = ms
				end
			end
		end
		if not slotMatches then
			if G.ForceHide then pcall(G.ForceHide, self) end
			if LBG and LBG.HideOverlayGlow then pcall(LBG.HideOverlayGlow, self, true) end
			return
		end
	end
	if G and R and type(col) == "number" and sid then
		local owner = R.ResolveProcOwner and R.ResolveProcOwner(col, sid)
		if not owner and R.FindLabShowingSpell then
			owner = R.FindLabShowingSpell(col, sid)
		end
		if owner and owner ~= self then
			local ow = owner.Widget or owner
			local oh = owner._fluxGlowAnchor or (owner.Widget and owner.Widget._fluxGlowAnchor)
			if ow ~= self and oh ~= self then
				if G.ForceHide then pcall(G.ForceHide, self) end
				if LBG and LBG.HideOverlayGlow then pcall(LBG.HideOverlayGlow, self, true) end
				return
			end
		end
		-- Route paint through EffectGlow (glow-anchor for badges, skipAnim continuity).
		if G.RefreshFrame then
			if sid and G.GlowSpells then
				G.GlowSpells[sid] = true
			end
			G.RefreshFrame(self, {
				col = col,
				spellId = sid,
				skipAnim = skipAnim and true or nil,
				forceShow = true,
			})
			return
		end
	end
	if LBG then
		LBG.ShowOverlayGlow(self, skipAnim)
	end
end

function HideOverlayGlow(self, instant)
	local api = _G.FLUX_API
	if api and not api.isPreDF and not api.isAnyClassic then
		return
	end
	if LBG then
		LBG.HideOverlayGlow(self, instant)
	end
end

local function IsSpellOverlayedForButton(spellId)
	if not spellId then
		return false
	end
	if C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed then
		return C_SpellActivationOverlay.IsSpellOverlayed(spellId)
	end
	if type(IsSpellOverlayed) == "function" then
		return IsSpellOverlayed(spellId)
	end
	if type(_G.FluxProcGlowCompat_IsSpellOverlayed) == "function" then
		return _G.FluxProcGlowCompat_IsSpellOverlayed(spellId)
	end
	return false
end

function UpdateOverlayGlow(self, instant)
	local spellId = self:GetSpellId()
	if spellId and IsSpellOverlayedForButton(spellId) then
		if not lib.SpellGlowState then lib.SpellGlowState = {} end
		if not lib.SpellGlowState[spellId] then lib.SpellGlowState[spellId] = GetTime() end
		
		local elapsed = GetTime() - lib.SpellGlowState[spellId]
		ShowOverlayGlow(self, elapsed > 0.2) -- Skip start anim if > 0.2s
	else
		-- Clear state if it exists (and we're sure it's gone)
		-- Since IsSpellOverlayed is false, it's gone for good.
		if lib.SpellGlowState and spellId and lib.SpellGlowState[spellId] then
			lib.SpellGlowState[spellId] = nil
		end
		HideOverlayGlow(self, instant)
	end
end

function SpellVFX_CastingAnim_OnHide(self)
	local parent = self:GetParent()
	SpellVFX_ClearReticle(parent)
	-- Restore swipe overlay (was set transparent during cast anim)
	parent.cooldown:SetSwipeColor(0, 0, 0, 1)
	if parent.cooldown.SetDrawSwipe then parent.cooldown:SetDrawSwipe(true) end
	UpdateCooldown(parent)
	-- ClearCastBarVisualForBurst uses alpha 0 on manual CastFill; reset for next cast.
	local fill = self.Fill
	if fill and fill.CastFill then fill.CastFill:SetAlpha(1) end
	if fill and fill.CastDim then fill.CastDim:SetAlpha(1) end
end

function SpellVFX_CastingAnim_Finish_OnFinished(self)
	self:GetParent():GetParent():Hide()
	local parentButton = self:GetParent():GetParent():GetParent()
	SpellVFX_StopSpellCastAnim(parentButton, false, parentButton.actionButtonCastType)
end

function SpellVFX_ClearReticle(self)
	if self.TargetReticleAnimFrame and self.TargetReticleAnimFrame:IsShown() then
		self.TargetReticleAnimFrame:Hide()
	end
end

function SpellVFX_ClearInterruptDisplay(self)
	if self.InterruptDisplay and self.InterruptDisplay:IsShown() then
		self.InterruptDisplay:Hide()
	end
end

--- Clear interrupt flash + lib tracking when the player re-enters ground targeting (or equivalent) for the same spell.
function lib:ClearInterruptedVFXIfMatchingSpell(spellId)
	if not spellId or not self.CurrentInterruptedSpellID then return end
	if not AreSpellsEquivalent(self.CurrentInterruptedSpellID, spellId) then return end
	self.CurrentInterruptedSpellID = nil
	self.InterruptTime = nil
	for button in next, ActiveButtons do
		local bid = button.GetSpellId and button:GetSpellId()
		if bid and AreSpellsEquivalent(bid, spellId) then
			SpellVFX_ClearInterruptDisplay(button)
		end
	end
end

--- Clear interrupt flash + lib tracking when the player re-enters ground targeting (or equivalent) for the same spell.
function lib:ClearInterruptedVFXIfMatchingSpell(spellId)
	if not spellId or not self.CurrentInterruptedSpellID then return end
	if not AreSpellsEquivalent(self.CurrentInterruptedSpellID, spellId) then return end
	self.CurrentInterruptedSpellID = nil
	self.InterruptTime = nil
	for button in next, ActiveButtons do
		local bid = button.GetSpellId and button:GetSpellId()
		if bid and AreSpellsEquivalent(bid, spellId) then
			SpellVFX_ClearInterruptDisplay(button)
		end
	end
end

--- Clear interrupt flash + lib tracking when the player re-enters ground targeting (or equivalent) for the same spell.
function lib:ClearInterruptedVFXIfMatchingSpell(spellId)
	if not spellId or not self.CurrentInterruptedSpellID then return end
	if not AreSpellsEquivalent(self.CurrentInterruptedSpellID, spellId) then return end
	self.CurrentInterruptedSpellID = nil
	self.InterruptTime = nil
	for button in next, ActiveButtons do
		local bid = button.GetSpellId and button:GetSpellId()
		if bid and AreSpellsEquivalent(bid, spellId) then
			SpellVFX_ClearInterruptDisplay(button)
		end
	end
end

--- Clear interrupt flash + lib tracking when the player re-enters ground targeting (or equivalent) for the same spell.
function lib:ClearInterruptedVFXIfMatchingSpell(spellId)
	if not spellId or not self.CurrentInterruptedSpellID then return end
	if not AreSpellsEquivalent(self.CurrentInterruptedSpellID, spellId) then return end
	self.CurrentInterruptedSpellID = nil
	self.InterruptTime = nil
	for button in next, ActiveButtons do
		local bid = button.GetSpellId and button:GetSpellId()
		if bid and AreSpellsEquivalent(bid, spellId) then
			SpellVFX_ClearInterruptDisplay(button)
		end
	end
end

--- Clear interrupt flash + lib tracking when the player re-enters ground targeting (or equivalent) for the same spell.
function lib:ClearInterruptedVFXIfMatchingSpell(spellId)
	if not spellId or not self.CurrentInterruptedSpellID then return end
	if not AreSpellsEquivalent(self.CurrentInterruptedSpellID, spellId) then return end
	self.CurrentInterruptedSpellID = nil
	self.InterruptTime = nil
	for button in next, ActiveButtons do
		local bid = button.GetSpellId and button:GetSpellId()
		if bid and AreSpellsEquivalent(bid, spellId) then
			SpellVFX_ClearInterruptDisplay(button)
		end
	end
end

function SpellVFX_PlaySpellCastAnim(self, actionButtonCastType)
	if not self.config.spellCastVFX then return end
	-- Post-DF Flux Exclusive owns cast paint on action-bar / badge surfaces.
	if FluxPostDFOwnsButtonVFX(self) then
		if _G.FluxPostDFUpdateButtonSpellVFX then
			_G.FluxPostDFUpdateButtonSpellVFX(self)
		end
		return
	end
	if WoWRetail then
		lib.FluxRetailCastVFX.Play(self, actionButtonCastType)
		return
	end
	-- Non-mainline: minimal cast overlay if template exists.
	self.cooldown.__Swipe_Hook = true
	self.cooldown:SetSwipeColor(0, 0, 0, 0)
	self.cooldown.__Swipe_Hook = nil
	SpellVFX_ClearInterruptDisplay(self)
	SpellVFX_ClearReticle(self)
	if not self.SpellCastAnimFrame then return end
	self.SpellCastAnimFrame:Setup(actionButtonCastType)
	self.actionButtonCastType = actionButtonCastType
end

function SpellVFX_PlayTargettingReticleAnim(self)
	if not self.config.spellCastVFX then return end
	if FluxPostDFOwnsButtonVFX(self) then
		if _G.FluxPostDFUpdateButtonSpellVFX then
			_G.FluxPostDFUpdateButtonSpellVFX(self)
		end
		return
	end

	-- Ensure InterruptDisplay check is safe
	if self.InterruptDisplay and self.InterruptDisplay:IsShown() then
		self.InterruptDisplay:Hide()
	end
	
	-- Match Blizzard ActionBarActionButtonMixin:PlayTargettingReticleAnim — skip reticle on assisted combat slot.
	if self.TargetReticleAnimFrame then
		local isAssisted = false
		if self._state_type == "action" and C_ActionBar and C_ActionBar.IsAssistedCombatAction and type(self._state_action) == "number" then
			isAssisted = C_ActionBar.IsAssistedCombatAction(self._state_action)
		end
		if not isAssisted then
			self.TargetReticleAnimFrame:Setup()
		end
	end
end

function SpellVFX_StopTargettingReticleAnim(self)
	if FluxPostDFOwnsButtonVFX(self) then
		-- PostDF Exclusive / ForceClear owns reticle hide.
		return
	end
	if self.TargetReticleAnimFrame and self.TargetReticleAnimFrame:IsShown() then
		self.TargetReticleAnimFrame:Hide()
	end
end

function SpellVFX_StopSpellCastAnim(self, forceStop, actionButtonCastType)
	if FluxPostDFOwnsButtonVFX(self) then
		if _G.FluxPostDFUpdateButtonSpellVFX then
			_G.FluxPostDFUpdateButtonSpellVFX(self)
		end
		return
	end
	SpellVFX_StopTargettingReticleAnim(self)
	if WoWRetail then
		lib.FluxRetailCastVFX.Stop(self, forceStop, actionButtonCastType)
		return
	end
	if self.actionButtonCastType == actionButtonCastType then
		self.vfxCastData = nil
		lib.fluxVFXButtons[self] = nil
		if self.SpellCastAnimFrame and self.SpellCastAnimFrame.ApplyCastBarLayoutFromButton then
			self.SpellCastAnimFrame:ApplyCastBarLayoutFromButton(0)
		elseif self.SpellCastAnimFrame and self.SpellCastAnimFrame.Fill and self.SpellCastAnimFrame.Fill.CastFill then
			local ox = lib.FluxRetailCastVFX.GetCastFillOffsetX(0, self, true)
			self.SpellCastAnimFrame.Fill.CastFill:ClearAllPoints()
			self.SpellCastAnimFrame.Fill.CastFill:SetPoint("CENTER", ox, 0)
		end
		if forceStop then
			if self.SpellCastAnimFrame then self.SpellCastAnimFrame:Hide() end
		elseif self.SpellCastAnimFrame and self.SpellCastAnimFrame.Fill and self.SpellCastAnimFrame.Fill.CastingAnim
				and self.SpellCastAnimFrame.Fill.CastingAnim:IsPlaying() then
			self.SpellCastAnimFrame:FinishAnimAndPlayBurst()
		end
		self.actionButtonCastType = nil
	end
end

function SpellVFX_PlaySpellInterruptedAnim(self)
	if not self.config.spellCastVFX then return end
	-- Flux PreDF/PostDF owns interrupt Exclusive on action-bar surfaces.
	if self._fluxSpellCastAnimSlotFill or self._fluxIsBadgeCornerProxy or self._fluxIsActionBarBadge
		or FluxPostDFOwnsButtonVFX(self) then
		if FluxPostDFOwnsButtonVFX(self) and _G.FluxPostDFUpdateButtonSpellVFX then
			_G.FluxPostDFUpdateButtonSpellVFX(self)
		end
		return
	end

	SpellVFX_StopSpellCastAnim(self, true, self.actionButtonCastType)
	-- Idempotent: Exclusive / identity resync must not Hide→Show restart.
	if self.InterruptDisplay and self.InterruptDisplay:IsShown() then
		return
	end
	if self.InterruptDisplay then
		self.InterruptDisplay:Show()
	end
end

function ClearNewActionHighlight(action, preventIdenticalActionsFromClearing, value)
	lib.ACTION_HIGHLIGHT_MARKS[action] = value

	for button in next, ButtonRegistry do
		if button._state_type == "action" and action == tonumber(button._state_action) then
			UpdateNewAction(button)
		end
	end

	if preventIdenticalActionsFromClearing then
		return
	end

	-- iterate through actions and unmark all that are the same type
	local unmarkedType, unmarkedID = GetActionInfo(action)
	for actionKey, markValue in pairs(lib.ACTION_HIGHLIGHT_MARKS) do
		if markValue then
			local actionType, actionID = GetActionInfo(actionKey)
			if actionType == unmarkedType and actionID == unmarkedID then
				ClearNewActionHighlight(actionKey, true, value)
			end
		end
	end
end

-- Flux compat: guard retail-only highlight hooks so classic_era clients that
-- lack these globals don't raise "attempt to hook nil" on load.
if _G.MarkNewActionHighlight then
	hooksecurefunc("MarkNewActionHighlight", function(action)
		lib.ACTION_HIGHLIGHT_MARKS[action] = true
		for button in next, ButtonRegistry do
			if button._state_type == "action" and action == tonumber(button._state_action) then
				UpdateNewAction(button)
			end
		end
	end)
end

if _G.ClearNewActionHighlight then
	hooksecurefunc("ClearNewActionHighlight", function(action, preventIdenticalActionsFromClearing)
		ClearNewActionHighlight(action, preventIdenticalActionsFromClearing, nil)
	end)
end

function UpdateNewAction(self)
	-- special handling for "New Action" markers
	if self.NewActionTexture then
		if self._state_type == "action" and lib.ACTION_HIGHLIGHT_MARKS[self._state_action] then
			self.NewActionTexture:Show()
		else
			self.NewActionTexture:Hide()
		end
	end
end

-- Flux compat: these three globals are retail additions (Blizzard
-- action-bar spell/flyout highlight marks). Classic/Anniversary clients omit
-- them; guard accordingly.
if _G.UpdateOnBarHighlightMarksBySpell then
	hooksecurefunc("UpdateOnBarHighlightMarksBySpell", function(spellID)
		lib.ON_BAR_HIGHLIGHT_MARK_TYPE = "spell"
		lib.ON_BAR_HIGHLIGHT_MARK_ID = tonumber(spellID)
	end)
end

if _G.UpdateOnBarHighlightMarksByFlyout then
	hooksecurefunc("UpdateOnBarHighlightMarksByFlyout", function(flyoutID)
		lib.ON_BAR_HIGHLIGHT_MARK_TYPE = "flyout"
		lib.ON_BAR_HIGHLIGHT_MARK_ID = tonumber(flyoutID)
	end)
end

if _G.ClearOnBarHighlightMarks then
	hooksecurefunc("ClearOnBarHighlightMarks", function()
		lib.ON_BAR_HIGHLIGHT_MARK_TYPE = nil
	end)
end

if ActionBarController_UpdateAllSpellHighlights then
	local function FluxLABFlushSpellHighlights()
		for button in next, ButtonRegistry do
			UpdateSpellHighlight(button)
		end
	end
	local function FluxLABScheduleSpellHighlights()
		if _G.FluxLABDeferSpellHighlights == false then
			FluxLABFlushSpellHighlights()
			return
		end
		if lib.fluxDefer.pendingSpellHighlightFlush then
			return
		end
		lib.fluxDefer.pendingSpellHighlightFlush = true
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				lib.fluxDefer.pendingSpellHighlightFlush = false
				FluxLABFlushSpellHighlights()
			end)
		else
			lib.fluxDefer.pendingSpellHighlightFlush = false
			FluxLABFlushSpellHighlights()
		end
	end
	hooksecurefunc("ActionBarController_UpdateAllSpellHighlights", function()
		FluxLABScheduleSpellHighlights()
	end)
end

function UpdateSpellHighlight(self)
	local shown = false

	local highlightType, id = lib.ON_BAR_HIGHLIGHT_MARK_TYPE, lib.ON_BAR_HIGHLIGHT_MARK_ID
	if highlightType == "spell" and self:GetSpellId() == id then
		shown = true
	elseif highlightType == "flyout" and self._state_type == "action" then
		local actionType, actionId = GetActionInfo(self._state_action)
		if actionType == "flyout" and actionId == id then
			shown = true
		end
	end

	if shown then
		self.SpellHighlightTexture:Show()
		self.SpellHighlightAnim:Play()
	else
		self.SpellHighlightTexture:Hide()
		self.SpellHighlightAnim:Stop()
	end
end

function UpdateAssistedCombatRotationFrame(self)
	if not (C_ActionBar and C_ActionBar.IsAssistedCombatAction) then return end
	local show = self._state_type == "action" and C_ActionBar.IsAssistedCombatAction(self._state_action)
	local assistedCombatRotationFrame = self.AssistedCombatRotationFrame
	-- create frame if needed
	if show and not assistedCombatRotationFrame then
		assistedCombatRotationFrame = CreateFrame("Frame", nil, self, "ActionBarButtonAssistedCombatRotationTemplate")
		self.AssistedCombatRotationFrame = assistedCombatRotationFrame
	end

	-- Blizzard template OnUpdate calls C_ActionBar.ForceUpdateAction(slot) each tick; that often fires
	-- ACTIONBAR_SLOT_CHANGED(0). LAB coalesces slot-0 into lib.FluxLABApplySlotChangedButton (dirty check) so
	-- only buttons whose icon/action changed get a full Update — do not call Update(parent) here (Bartended model).
	if assistedCombatRotationFrame and show and not assistedCombatRotationFrame._fluxAssistRotationOnUpdate then
		assistedCombatRotationFrame._fluxAssistRotationOnUpdate = true
		assistedCombatRotationFrame:SetScript("OnUpdate", function(f, elapsed)
			if not f:IsShown() then
				return
			end
			f._fluxAssistTimeLeft = (f._fluxAssistTimeLeft or 0) - elapsed
			if f._fluxAssistTimeLeft > 0 then
				return
			end
			f._fluxAssistTimeLeft = lib.FluxGetAssistedUpdateInterval()
			local parent = f:GetParent()
			if parent then
				lib.FluxForceUpdateAssistedActionSlotIfNeeded(parent)
			end
		end)
	end

	if assistedCombatRotationFrame then
		assistedCombatRotationFrame:UpdateState()
	end
end

function UpdatedAssistedHighlightFrame(self)
	if not AssistedCombatManager then return end
	if not self.config.assistedHighlight then return end
	local spellID = AssistedCombatManager.lastNextCastSpellID
	local candidates = AssistedCombatManager.assistedHighlightCandidateActionButtons
	if candidates then
		if not candidates[self] and self:GetSpellId() ~= spellID then
			local highlightFrame = self.AssistedCombatHighlightFrame
			if highlightFrame then
				highlightFrame:Hide()
			end
			return
		end
	elseif spellID and self:GetSpellId() ~= spellID then
		local highlightFrame = self.AssistedCombatHighlightFrame
		if highlightFrame then
			highlightFrame:Hide()
		end
		return
	end
	local shown = spellID and self:GetSpellId() == spellID

	local highlightFrame = self.AssistedCombatHighlightFrame
	if shown then
		if not highlightFrame then
			highlightFrame = CreateFrame("FRAME", nil, self, "ActionBarButtonAssistedCombatHighlightTemplate")
			self.AssistedCombatHighlightFrame = highlightFrame
			highlightFrame:SetPoint("CENTER")
			-- increase frame level so that its above other overlays (eg. proc highlight)
			highlightFrame:SetFrameLevel(self:GetFrameLevel() + 10)
			-- have to do this to get a single frame of the flipbook instead of the whole texture
			highlightFrame.Flipbook.Anim:Play()
			highlightFrame.Flipbook.Anim:Stop()
		end
		highlightFrame:Show()
		if FluxActionBarAnisoHelpers and FluxActionBarAnisoHelpers.RefreshAssistedHighlightSqueeze then
			FluxActionBarAnisoHelpers.RefreshAssistedHighlightSqueeze(self)
		end
		if AssistedCombatManager.affectingCombat then
			highlightFrame.Flipbook.Anim:Play()
		else
			highlightFrame.Flipbook.Anim:Stop()
		end
	elseif highlightFrame then
		highlightFrame:Hide()
	end
end

-- Hook UpdateFlyout so we can use the blizzy templates (classic only; retail uses custom flyout).
if ActionButton_UpdateFlyout and not UseCustomFlyout then
	hooksecurefunc("ActionButton_UpdateFlyout", function(self, ...)
		if ButtonRegistry[self] then
			UpdateFlyout(self)
		end
	end)

	function UpdateFlyout(self)
		-- disabled FlyoutBorder/BorderShadow, those are not handled by LBF and look terrible
		if self.FlyoutBorder then
			self.FlyoutBorder:Hide()
		end
		self.FlyoutBorderShadow:Hide()
		if self._state_type == "action" then
			-- based on ActionButton_UpdateFlyout in ActionButton.lua
			local actionType = GetActionInfo(self._state_action)
			if actionType == "flyout" then

				local isFlyoutShown = SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == self
				local arrowDistance = isFlyoutShown and 1 or 4

				-- Update arrow
				self.FlyoutArrow:Show()
				self.FlyoutArrow:ClearAllPoints()
				local direction = self:GetAttribute("flyoutDirection")
				if direction == "LEFT" then
					self.FlyoutArrow:SetPoint("LEFT", self, "LEFT", -arrowDistance, 0)
					SetClampedTextureRotation(self.FlyoutArrow, isFlyoutShown and 90 or 270)
				elseif direction == "RIGHT" then
					self.FlyoutArrow:SetPoint("RIGHT", self, "RIGHT", arrowDistance, 0)
					SetClampedTextureRotation(self.FlyoutArrow, isFlyoutShown and 270 or 90)
				elseif direction == "DOWN" then
					self.FlyoutArrow:SetPoint("BOTTOM", self, "BOTTOM", 0, -arrowDistance)
					SetClampedTextureRotation(self.FlyoutArrow, isFlyoutShown and 0 or 180)
				else
					self.FlyoutArrow:SetPoint("TOP", self, "TOP", 0, arrowDistance)
					SetClampedTextureRotation(self.FlyoutArrow, isFlyoutShown and 180 or 0)
				end

				-- return here, otherwise flyout is hidden
				return
			end
		end
		self.FlyoutArrow:Hide()
	end
elseif FlyoutButtonMixin and UseCustomFlyout then
	function Generic:GetPopupDirection()
		return self:GetAttribute("flyoutDirection") or "UP"
	end

	function Generic:IsPopupOpen()
		return (lib.flyoutHandler and lib.flyoutHandler:IsShown() and lib.flyoutHandler:GetParent() == self)
	end

	function UpdateFlyout(self, isButtonDownOverride)
		self.BorderShadow:Hide()
		if self._state_type == "action" then
			-- based on ActionButton_UpdateFlyout in ActionButton.lua
			local actionType = GetActionInfo(self._state_action)
			if actionType == "flyout" then
				self.Arrow:Show()
				self:UpdateArrowTexture()
				self:UpdateArrowRotation()
				self:UpdateArrowPosition()
				-- return here, otherwise flyout is hidden
				return
			end
		end

		self.Arrow:Hide()
	end
else
	function UpdateFlyout(self, isButtonDownOverride)
		self.FlyoutBorderShadow:Hide()
		if self._state_type == "action" then
			-- based on ActionButton_UpdateFlyout in ActionButton.lua
			local actionType = GetActionInfo(self._state_action)
			if actionType == "flyout" then
				local isMouseOverButton = self:IsMouseOver()

				local isButtonDown
				if (isButtonDownOverride ~= nil) then
					isButtonDown = isButtonDownOverride
				else
					isButtonDown = self:GetButtonState() == "PUSHED"
				end

				local flyoutArrowTexture = self.FlyoutArrowContainer.FlyoutArrowNormal

				if (isButtonDown) then
					flyoutArrowTexture = self.FlyoutArrowContainer.FlyoutArrowPushed

					self.FlyoutArrowContainer.FlyoutArrowNormal:Hide()
					self.FlyoutArrowContainer.FlyoutArrowHighlight:Hide()
				elseif (isMouseOverButton) then
					flyoutArrowTexture = self.FlyoutArrowContainer.FlyoutArrowHighlight

					self.FlyoutArrowContainer.FlyoutArrowNormal:Hide()
					self.FlyoutArrowContainer.FlyoutArrowPushed:Hide()
				else
					self.FlyoutArrowContainer.FlyoutArrowHighlight:Hide()
					self.FlyoutArrowContainer.FlyoutArrowPushed:Hide()
				end

				local isFlyoutShown = (SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == self) or (lib.flyoutHandler and lib.flyoutHandler:IsShown() and lib.flyoutHandler:GetParent() == self)
				local arrowDistance = isFlyoutShown and 1 or 4

				-- Update arrow
				self.FlyoutArrowContainer:Show()
				flyoutArrowTexture:Show()
				flyoutArrowTexture:ClearAllPoints()

				local direction = self:GetAttribute("flyoutDirection")
				if direction == "LEFT" then
					SetClampedTextureRotation(flyoutArrowTexture, isFlyoutShown and 90 or 270)
					flyoutArrowTexture:SetPoint("LEFT", self, "LEFT", -arrowDistance, 0)
				elseif direction == "RIGHT" then
					SetClampedTextureRotation(flyoutArrowTexture, isFlyoutShown and 270 or 90)
					flyoutArrowTexture:SetPoint("RIGHT", self, "RIGHT", arrowDistance, 0)
				elseif direction == "DOWN" then
					SetClampedTextureRotation(flyoutArrowTexture, isFlyoutShown and 0 or 180)
					flyoutArrowTexture:SetPoint("BOTTOM", self, "BOTTOM", 0, -arrowDistance)
				else
					SetClampedTextureRotation(flyoutArrowTexture, isFlyoutShown and 180 or 0)
					flyoutArrowTexture:SetPoint("TOP", self, "TOP", 0, arrowDistance)
				end

				-- return here, otherwise flyout is hidden
				return
			end
		end
		self.FlyoutArrowContainer:Hide()
	end
end
Generic.UpdateFlyout = UpdateFlyout
Generic.UpdateCooldown = UpdateCooldown

function Generic:UpdateUsable()
	UpdateUsable(self, true)
end

function UpdateRangeTimer()
	rangeTimer = -1
	-- Also sample immediately so target changes paint without waiting for OnUpdate.
	if SampleAllRangeButtons then
		SampleAllRangeButtons()
	end
	if lib.FluxLABSyncOnUpdateArm then lib.FluxLABSyncOnUpdateArm() end
end

lib.UpdateRangeTimer = UpdateRangeTimer

--- Trailing coalesce for UPDATE_MOUSEOVER_UNIT storms (~70ms, aligned with FluxMouseoverRefresh).
local rangeMouseoverScheduled = false
local rangeMouseoverAt = nil
function lib.UpdateRangeTimerCoalesced()
	rangeTimer = -1
	local interval = 0.07
	local MR = _G.FluxMouseoverRefresh
	if MR and MR.GetInterval then
		local n = MR.GetInterval()
		if type(n) == "number" and n > 0 then
			interval = n
		end
	end
	local now = GetTime and GetTime() or 0
	rangeMouseoverAt = now + interval
	if rangeMouseoverScheduled then
		return
	end
	rangeMouseoverScheduled = true
	local function fire()
		rangeMouseoverScheduled = false
		if not rangeMouseoverAt then return end
		local t = GetTime and GetTime() or 0
		if t < rangeMouseoverAt then
			rangeMouseoverScheduled = true
			if C_Timer and C_Timer.After then
				C_Timer.After(rangeMouseoverAt - t, fire)
				return
			end
		end
		rangeMouseoverAt = nil
		if SampleAllRangeButtons then
			SampleAllRangeButtons()
		end
		if lib.FluxLABSyncOnUpdateArm then lib.FluxLABSyncOnUpdateArm() end
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(interval, fire)
	else
		fire()
	end
end

-----------------------------------------------------------
--- WoW API mapping
--- Generic Button
Generic.HasAction                = function(self) return nil end
Generic.GetActionText            = function(self) return "" end
Generic.GetTexture               = function(self) return nil end
Generic.GetCount                 = function(self) return 0 end
Generic.GetChargeInfo            = function(self) return nil end
Generic.GetChargeDuration        = function(self) return nil end
Generic.GetCooldownInfo          = function(self) return nil end
Generic.GetCooldownDuration      = function(self) return nil end
Generic.GetLoCCooldownInfo       = function(self) return nil end
Generic.GetLoCCooldownDuration   = function(self) return nil end
Generic.IsAttack                 = function(self) return nil end
Generic.IsEquipped               = function(self) return nil end
Generic.IsCurrentlyActive        = function(self) return nil end
Generic.IsAutoRepeat             = function(self) return nil end
Generic.IsUsable                 = function(self) return nil end
Generic.IsConsumableOrStackable  = function(self) return nil end
Generic.IsUnitInRange            = function(self, unit) return nil end
Generic.IsInRange                = function(self)
	local unit
	local FR = _G.FluxRange
	if FR and FR.ResolveUnit then
		unit = FR.ResolveUnit(self)
	else
		unit = self:GetAttribute("unit")
		if unit == "player" then
			unit = nil
		end
	end
	local val = self:IsUnitInRange(unit)
	if FR and FR.Normalize then
		return FR.Normalize(val)
	end
	-- map 1/0 to true false, since the return values are inconsistent between actions and spells
	if val == 1 then val = true elseif val == 0 then val = false end
	return val
end
Generic.SetTooltip               = function(self) return nil end
Generic.GetSpellId               = function(self) return nil end
Generic.GetPassiveCooldownSpellID = function(self) return nil end

Generic.GetDisplayCount = function(self)
	if self:IsConsumableOrStackable() then
		local count = self:GetCount()
		if count > (self.maxDisplayCount or 9999) then
			return "*"
		else
			return count
		end
	else
		local charges, maxCharges, _chargeStart, _chargeDuration = self:GetCharges()
		if charges and maxCharges and maxCharges > 1 then
			return charges
		end
	end

	return ""
end

-- legacy cooldown functions
Generic.GetCharges = function(self)
	local charge = self:GetChargeInfo()
	if charge then
		return charge.currentCharges, charge.maxCharges, charge.cooldownStartTime, charge.cooldownDuration, charge.chargeModRate
	end
end

Generic.GetCooldown = function(self)
	local cd = self:GetCooldownInfo()
	if cd then
		return cd.startTime, cd.duration, cd.isEnabled, cd.modRate
	end
end

Generic.GetLossOfControlCooldown = function(self)
	local cd = self:GetLoCCooldownInfo()
	if cd then
		return cd.startTime, cd.duration
	end
end

-----------------------------------------------------------
--- Action Button

-- fallback for pre-12.0

local GetActionCount = GetActionCount

-- the remaining uses of GetActionCount can't deal with secrets, so disable on Midnight
if Midnight then
	GetActionCount = function() return 0 end
end

local GetActionChargeInfoFallback
if GetActionCharges then
	GetActionChargeInfoFallback = function(action)
		local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetActionCharges(action)
		return {
			currentCharges = currentCharges,
			maxCharges = maxCharges,
			cooldownStartTime = cooldownStart,
			cooldownDuration = cooldownDuration,
			chargeModRate = chargeModRate
		}
	end
else
	GetActionChargeInfoFallback = function() end
end

local GetActionCooldownInfoFallback
if GetActionCooldown then
	GetActionCooldownInfoFallback = function(action)
		local start, duration, enable, modRate = GetActionCooldown(action)
		return {
			startTime = start,
			duration = duration,
			isEnabled = enable,
			modRate = modRate
		}
	end
else
	GetActionCooldownInfoFallback = function() end
end

local GetActionLoCCooldownInfoFallback
if GetActionLossOfControlCooldown then
	GetActionLoCCooldownInfoFallback = function(action)
		local start, duration = GetActionLossOfControlCooldown(action)
		return {
			startTime = start,
			duration = duration,
			isEnabled = true,
			modRate = 1.0
		}
	end
else
	GetActionLoCCooldownInfoFallback = function() end
end

local GetActionCooldownInfo = C_ActionBar and C_ActionBar.GetActionCooldown or GetActionCooldownInfoFallback
local GetActionChargeInfo = C_ActionBar and C_ActionBar.GetActionCharges or GetActionChargeInfoFallback
local GetActionLoCCooldownInfo = C_ActionBar and C_ActionBar.GetActionLossOfControlCooldownInfo or GetActionLoCCooldownInfoFallback

--- Spell ID for item/toy on-bar actions and macro /use item (SpellVFX / UpdateSpellVFX).
local function GetSpellIdFromItemId(itemIdOrLink)
	local id = itemIdOrLink
	if type(itemIdOrLink) == "string" then
		local n = itemIdOrLink:match("^item:(%d+)")
		if n then id = tonumber(n) end
	end
	if type(id) ~= "number" or id < 1 then return nil end
	if C_Item and C_Item.GetItemSpell then
		local _, spellID = C_Item.GetItemSpell(id)
		if spellID and spellID > 0 then return spellID end
	end
	if GetItemSpell then
		local _, _, spellID = GetItemSpell(id)
		if spellID and spellID > 0 then return spellID end
	end
	return nil
end

--- Mount / companion action → summon spell id.
local function GetSpellIdFromMountOrCompanion(id, subType)
	if type(id) ~= "number" or id < 1 then return nil end
	local st = type(subType) == "string" and subType:upper() or subType
	if C_MountJournal and C_MountJournal.GetMountInfoByID then
		-- Retail: companion MOUNT id is often a mountID; also try when type is "mount".
		if not st or st == "MOUNT" or st == "mount" then
			local ok, _, spellID = pcall(C_MountJournal.GetMountInfoByID, id)
			if ok and type(spellID) == "number" and spellID > 0 then
				return spellID
			end
		end
	end
	-- Classic companion: GetCompanionInfo(type, index) → spellID.
	if GetCompanionInfo and st then
		local ok, _, spellID = pcall(GetCompanionInfo, st, id)
		if ok and type(spellID) == "number" and spellID > 0 then
			return spellID
		end
	end
	return nil
end

--- Soft-retry via Blizzard action→spell binding (items/toys/mounts before cache fills).
local function GetSpellIdFromActionSlot(action)
	if type(action) ~= "number" or action < 1 then return nil end
	if C_ActionBar and C_ActionBar.GetSpell then
		local ok, sid = pcall(C_ActionBar.GetSpell, action)
		if ok and type(sid) == "number" and sid > 0 then
			return sid
		end
	end
	return nil
end

Action.HasAction                = function(self) return HasAction(self._state_action) end
Action.GetActionText            = function(self) return GetActionText(self._state_action) end
Action.GetTexture               = function(self) return GetActionTexture(self._state_action) end
Action.GetCount                 = function(self) return GetActionCount(self._state_action) end
Action.GetChargeInfo            = function(self) return GetActionChargeInfo(self._state_action) end
Action.GetCooldownInfo          = function(self) return GetActionCooldownInfo(self._state_action) end
Action.GetLoCCooldownInfo       = function(self) return GetActionLoCCooldownInfo(self._state_action) end
Action.GetLossOfControlCooldown = function(self) return GetActionLossOfControlCooldown(self._state_action) end
Action.IsAttack                 = function(self) return IsAttackAction(self._state_action) end
Action.IsEquipped               = function(self) return IsEquippedAction(self._state_action) end
Action.IsCurrentlyActive        = function(self)
	-- Dual-split Exclusive owns checked. Never IsCurrentAction(slot) — that stays
	-- true for Summon while the icon shows Freeze after [pet] swap.
	if self._fluxExclusiveCheckedManaged then
		return nil
	end
	return IsCurrentAction(self._state_action)
end
Action.IsAutoRepeat             = function(self) return IsAutoRepeatAction(self._state_action) end
Action.IsUsable                 = function(self) return IsUsableAction(self._state_action) end
Action.IsConsumableOrStackable  = function(self) return IsConsumableAction(self._state_action) or IsStackableAction(self._state_action) or (not IsItemAction(self._state_action) and GetActionCount(self._state_action) > 0) end
Action.IsUnitInRange            = function(self, unit)
	local FR = _G.FluxRange
	if FR and FR.CheckAction then
		return FR.CheckAction(self._state_action, unit)
	end
	local val = IsActionInRange(self._state_action, unit)
	if FR and FR.Normalize then return FR.Normalize(val) end
	if val == 1 then return true elseif val == 0 then return false end
	return val
end
Action.SetTooltip               = function(self) return GameTooltip:SetAction(self._state_action) end
Action.GetSpellId               = function(self)
	local action = self._state_action
	local actionType, id, subType = GetActionInfo(action)
	if actionType == "spell" then
		return id
	elseif actionType == "macro" then
		if subType == "spell" then
			return id
		else
			local spellId = GetMacroSpell and GetMacroSpell(id)
			if spellId and spellId > 0 then return spellId end
			if GetMacroItem then
				local itemName, itemLink = GetMacroItem(id)
				if itemLink then
					local sid = GetSpellIdFromItemId(itemLink)
					if sid then return sid end
				end
				if itemName and C_Item and C_Item.GetItemInfoInstant then
					local iid = C_Item.GetItemInfoInstant(itemName)
					if iid then
						local sid = GetSpellIdFromItemId(iid)
						if sid then return sid end
					end
				end
			end
			-- Soft-retry: macro item spell not cached yet.
			return GetSpellIdFromActionSlot(action)
		end
	elseif actionType == "item" or actionType == "toy" then
		local sid = GetSpellIdFromItemId(id)
		if sid then return sid end
		return GetSpellIdFromActionSlot(action)
	elseif actionType == "companion" or actionType == "mount" then
		local sid = GetSpellIdFromMountOrCompanion(id, subType or actionType)
		if sid then return sid end
		return GetSpellIdFromActionSlot(action)
	elseif actionType and id then
		-- Summon / misc: Blizzard C_ActionBar.GetSpell covers item→spell and similar.
		return GetSpellIdFromActionSlot(action)
	end
end

-- legacy cooldown functions, avoiding table creation on game versions that still have the old API
-- LAB does not call these, but external things might
Action.GetCharges = function(self)
	if  GetActionCharges then
		return GetActionCharges(self._state_action)
	else
		local charge = self:GetChargeInfo()
		if charge then
			return charge.currentCharges, charge.maxCharges, charge.cooldownStartTime, charge.cooldownDuration, charge.chargeModRate
		end
	end
end

Action.GetCooldown = function(self)
	if GetActionCooldown then
		return GetActionCooldown(self._state_action)
	else
		local cd = self:GetCooldownInfo()
		if cd then
			return cd.startTime, cd.duration, cd.isEnabled, cd.modRate
		end
	end
end

if C_ActionBar and C_ActionBar.GetActionDisplayCount then
	Action.GetDisplayCount = function(self) return C_ActionBar.GetActionDisplayCount(self._state_action) end
end

if C_ActionBar and C_ActionBar.GetActionChargeDuration then
	Action.GetChargeDuration = function(self) return C_ActionBar.GetActionChargeDuration(self._state_action) end
end
if C_ActionBar and C_ActionBar.GetActionCooldownDuration then
	Action.GetCooldownDuration = function(self) return C_ActionBar.GetActionCooldownDuration(self._state_action) end
end
if C_ActionBar and C_ActionBar.GetActionLossOfControlCooldownDuration then
	Action.GetLoCCooldownDuration = function(self) return C_ActionBar.GetActionLossOfControlCooldownDuration(self._state_action) end
end

if C_UnitAuras and C_UnitAuras.GetCooldownAuraBySpellID and C_ActionBar and C_ActionBar.GetItemActionOnEquipSpellID then
	Action.GetPassiveCooldownSpellID = function(self)
		local _actionType, actionID = GetActionInfo(self._state_action)
		local onEquipPassiveSpellID
		if actionID then
			onEquipPassiveSpellID = C_ActionBar.GetItemActionOnEquipSpellID(self._state_action)
		end
		if onEquipPassiveSpellID then
			return C_UnitAuras.GetCooldownAuraBySpellID(onEquipPassiveSpellID)
		else
			local spellID = self:GetSpellId()
			if spellID then
				return C_UnitAuras.GetCooldownAuraBySpellID(spellID)
			end
		end
	end
end

-- Classic overrides for item count breakage
-- Apply to all pre-Dragonflight clients
if not WoWRetail then
	-- if the library is present, simply use it to override action counts
	local LibClassicSpellActionCount = LibStub("LibClassicSpellActionCount-1.0", true)
	if LibClassicSpellActionCount then
		Action.GetCount = function(self) return LibClassicSpellActionCount:GetActionCount(self._state_action) end
		-- Also override IsConsumableOrStackable to detect spells with reagent counts
		local originalIsConsumableOrStackable = Action.IsConsumableOrStackable
		Action.IsConsumableOrStackable = function(self)
			-- First check the original logic
			local result = originalIsConsumableOrStackable(self)
			if result then return result end

			-- For spells, check if LibClassicSpellActionCount returns a count > 0
			local actionType = GetActionInfo(self._state_action)
			if actionType == "spell" then
				local count = LibClassicSpellActionCount:GetActionCount(self._state_action)
				return count and count > 0
			elseif actionType == "macro" then
				local spellId = GetMacroSpell(self._state_action)
				if spellId then
					local count = LibClassicSpellActionCount:GetSpellReagentCount(spellId)
					return count and count > 0
				end
			end

			return false
		end
	else
		-- if we don't have the library, only show count for items, like the default UI
		Action.IsConsumableOrStackable = function(self) return IsItemAction(self._state_action) and (IsConsumableAction(self._state_action) or IsStackableAction(self._state_action)) end
	end
end

if not WoWRetail then
	-- disable loss of control cooldown on classic
	Action.GetLossOfControlCooldown = function(self) return 0, 0 end
	Action.GetLoCCooldownInfo = function(self) return nil end
end

local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
local GetSpellCastCount = C_Spell and C_Spell.GetSpellCastCount or GetSpellCount
local IsAttackSpell = C_SpellBook and C_SpellBook.IsAutoAttackSpellBookItem or IsAttackSpell
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell or IsCurrentSpell
local IsAutoRepeatSpell = C_Spell and C_Spell.IsAutoRepeatSpell or IsAutoRepeatSpell
local IsSpellUsable = C_Spell and C_Spell.IsSpellUsable or IsUsableSpell
local IsConsumableSpell = C_Spell and C_Spell.IsConsumableSpell or IsConsumableSpell
local IsSpellInRange = C_Spell and C_Spell.IsSpellInRange or IsSpellInRange
local GetSpellLossOfControlCooldown = C_Spell and C_Spell.GetSpellLossOfControlCooldown or GetSpellLossOfControlCooldown

local GetSpellLoCCooldownInfoFallback
if GetSpellLossOfControlCooldown then
	GetSpellLoCCooldownInfoFallback = function(action)
		local start, duration = GetSpellLossOfControlCooldown(action)
		return {
			startTime = start,
			duration = duration,
			isEnabled = true,
			modRate = 1.0
		}
	end
else
	GetSpellLoCCooldownInfoFallback = function() end
end
local GetSpellLossOfControlCooldownInfo = C_Spell and C_Spell.GetSpellLossOfControlCooldownInfo or GetSpellLoCCooldownInfoFallback

local BOOKTYPE_SPELL = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or "spell"
-----------------------------------------------------------
--- Spell Button
Spell.HasAction                = function(self) return true end
Spell.GetActionText            = function(self) return "" end
Spell.GetTexture               = function(self) return GetSpellTexture(self._state_action) end
Spell.GetCount                 = function(self) return GetSpellCastCount(self._state_action) end
Spell.GetChargeInfo            = function(self) return C_Spell.GetSpellCharges(self._state_action) end
Spell.GetCooldownInfo          = function(self) return C_Spell.GetSpellCooldown(self._state_action) end
Spell.GetLoCCooldownInfo       = function(self) return GetSpellLossOfControlCooldownInfo(self._state_action) end
Spell.GetLossOfControlCooldown = function(self) return GetSpellLossOfControlCooldown(self._state_action) end
Spell.IsAttack                 = function(self) local slot = FindSpellBookSlotBySpellID(self._state_action) return slot and IsAttackSpell(slot, BOOKTYPE_SPELL) or nil end
Spell.IsEquipped               = function(self) return nil end
Spell.IsCurrentlyActive        = function(self) return IsCurrentSpell(self._state_action) end
Spell.IsAutoRepeat             = function(self) local slot = FindSpellBookSlotBySpellID(self._state_action) return slot and IsAutoRepeatSpell(slot, BOOKTYPE_SPELL) or nil end
Spell.IsUsable                 = function(self)
	local API = FluxAPICompat and FluxAPICompat.API
	if API and API.IsSpellUsable then
		return API.IsSpellUsable(self._state_action)
	end
	return IsSpellUsable(self._state_action)
end
Spell.IsConsumableOrStackable  = function(self) return IsConsumableSpell(self._state_action) end
Spell.IsUnitInRange            = function(self, unit)
	local FR = _G.FluxRange
	local spellId = self._state_action
	if FR and FR.ResolveSpellIdentifier then
		spellId = FR.ResolveSpellIdentifier(self, spellId)
	end
	if FR and FR.CheckSpell then
		return FR.CheckSpell(spellId, unit)
	end
	local slot = FindSpellBookSlotBySpellID(spellId)
	return slot and IsSpellInRange(slot, BOOKTYPE_SPELL, unit) or nil
end
Spell.SetTooltip               = function(self) return GameTooltip:SetSpellByID(self._state_action) end
Spell.GetSpellId               = function(self) return self._state_action end

if C_Spell and C_Spell.GetSpellDisplayCount then
	Spell.GetDisplayCount = function(self) return C_Spell.GetSpellDisplayCount(self._state_action) end
end

if C_Spell and C_Spell.GetSpellChargeDuration then
	Spell.GetChargeDuration = function(self) return C_Spell.GetSpellChargeDuration(self._state_action) end
end
if C_Spell and C_Spell.GetSpellCooldownDuration then
	Spell.GetCooldownDuration = function(self) return C_Spell.GetSpellCooldownDuration(self._state_action) end
end
if C_Spell and C_Spell.GetSpellLossOfControlCooldownDuration then
	Spell.GetLoCCooldownDuration = function(self) return C_Spell.GetSpellLossOfControlCooldownDuration(self._state_action) end
end

if C_UnitAuras then
	Spell.GetPassiveCooldownSpellID = function(self)
		if self._state_action then
			return C_UnitAuras.GetCooldownAuraBySpellID(self._state_action)
		end
	end
end

-----------------------------------------------------------
--- Item Button
local function getItemId(input)
	return input:match("^item:(%d+)")
end

Item.HasAction               = function(self) return true end
Item.GetActionText           = function(self) return "" end
Item.GetTexture              = function(self) return C_Item.GetItemIconByID(self._state_action) end
Item.GetCount                = function(self) return C_Item.GetItemCount(self._state_action, nil, true) end
Item.GetChargeInfo           = function(self) return nil end
Item.GetCooldownInfo         = function(self) local start, duration, enable = C_Container.GetItemCooldown(getItemId(self._state_action)) return { startTime = start, duration = duration, isEnabled = enable, modRate = 1.0, isActive = (enable and start and start > 0 and duration and duration > 0) } end
Item.IsAttack                = function(self) return nil end
Item.IsEquipped              = function(self) return C_Item.IsEquippedItem(self._state_action) end
Item.IsCurrentlyActive       = function(self) return C_Item.IsCurrentItem(self._state_action) end
Item.IsAutoRepeat            = function(self) return nil end
Item.IsUsable                = function(self) return C_Item.IsUsableItem(self._state_action) end
Item.IsConsumableOrStackable = function(self) return C_Item.IsConsumableItem(self._state_action) end
Item.IsUnitInRange           = function(self, unit)
	local FR = _G.FluxRange
	if FR and FR.CheckItem then
		return FR.CheckItem(self._state_action, unit)
	end
	-- IsItemInRange is combat-restricted for non-attackable units; never call raw.
	local API = FluxAPICompat and FluxAPICompat.API
	if API and API.IsItemInRange then
		return API.IsItemInRange(self._state_action, unit)
	end
	if API and API.CanCheckItemInRange and not API.CanCheckItemInRange(unit) then
		return nil
	end
	if IsItemInRange then
		return IsItemInRange(self._state_action, unit)
	end
	return nil
end
Item.SetTooltip              = function(self) return GameTooltip:SetHyperlink(self._state_action) end
Item.GetSpellId              = function(self) return GetSpellIdFromItemId(self._state_action) end
Item.GetPassiveCooldownSpellID = function(self) return nil end

if C_DurationUtil and C_DurationUtil.CreateDuration then
	Item.GetCooldownDuration = function(self)
		local duration = C_DurationUtil.CreateDuration()
		if not duration then return nil end

		local info = self:GetCooldownInfo()
		if info and info.isActive then
			duration:SetTimeFromStart(info.startTime, info.duration, info.modRate)
		end

		return duration
	end
end

-----------------------------------------------------------
--- Macro Button
-- TODO: map results of GetMacroSpell/GetMacroItem to proper results
Macro.HasAction               = function(self) return true end
Macro.GetActionText           = function(self) return (GetMacroInfo(self._state_action)) end
Macro.GetTexture              = function(self) return (select(2, GetMacroInfo(self._state_action))) end
Macro.GetCount                = function(self) return 0 end
Macro.GetChargeInfo           = function(self) return nil end
Macro.GetCooldownInfo         = function(self) return nil end
Macro.IsAttack                = function(self) return nil end
Macro.IsEquipped              = function(self) return nil end
Macro.IsCurrentlyActive       = function(self) return nil end
Macro.IsAutoRepeat            = function(self) return nil end
Macro.IsUsable                = function(self) return nil end
Macro.IsConsumableOrStackable = function(self) return nil end
Macro.IsUnitInRange           = function(self, unit) return nil end
Macro.SetTooltip              = function(self) return nil end
Macro.GetSpellId              = function(self)
	local macroId = self._state_action
	if type(macroId) ~= "number" then return nil end
	if GetMacroSpell then
		local spellId = GetMacroSpell(macroId)
		if spellId and spellId > 0 then return spellId end
	end
	if GetMacroItem then
		local itemName, itemLink = GetMacroItem(macroId)
		if itemLink then
			local sid = GetSpellIdFromItemId(itemLink)
			if sid then return sid end
		end
		if itemName and C_Item and C_Item.GetItemInfoInstant then
			local iid = C_Item.GetItemInfoInstant(itemName)
			if iid then
				return GetSpellIdFromItemId(iid)
			end
		end
	end
	return nil
end
Macro.GetPassiveCooldownSpellID = function(self) return nil end

-----------------------------------------------------------
--- Macrotext Button (Flux Binding generated macro text)
-- Display resolves the ACTIVE clause of the macro body with SecureCmdOptionParse
-- each refresh (memoized per frame), then delegates to spell/item display APIs so
-- icon / cooldown / count / usability always match what a keypress would cast.
-- Wrapped in do..end: no extra chunk-level locals (Lua 5.1 200-local limit).

do

local ResolveDisplaySpellId
if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
	ResolveDisplaySpellId = function(v) return C_Spell.GetSpellIDForSpellIdentifier(v) end
elseif C_Spell and C_Spell.GetSpellInfo then
	ResolveDisplaySpellId = function(v)
		local si = C_Spell.GetSpellInfo(v)
		return si and si.spellID
	end
else
	ResolveDisplaySpellId = function(v)
		local _, _, _, _, _, _, sid = GetSpellInfo(v)
		return sid
	end
end

local GetItemInfoInstantCompat = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

local macrotextParseCache = {}
local macrotextParseCacheSize = 0

local MACRO_CAST_COMMANDS = {
	["/cast"] = true, ["/use"] = true, ["/spell"] = true,
	["/castrandom"] = true, ["/userandom"] = true,
}

local function ResolveMacroDisplayValue(value, entry)
	if type(value) ~= "string" or value == "" then return end
	-- explicit item:ID form (MacroFactory emits this for item bindings)
	local itemId = value:match("^item:(%d+)")
	if itemId then
		entry.itemID = tonumber(itemId)
		return
	end
	-- bare inventory slot number (/use 13)
	local slotNum = tonumber(value)
	if slotNum and slotNum >= 1 and slotNum <= 19 then
		local invItem = GetInventoryItemID and GetInventoryItemID("player", slotNum)
		if invItem then
			entry.itemID = invItem
			return
		end
	end
	local sid = ResolveDisplaySpellId(value)
	if sid then
		entry.spellID = sid
		return
	end
	if GetItemInfoInstantCompat then
		local iid = GetItemInfoInstantCompat(value)
		if iid then
			entry.itemID = iid
			return
		end
	end
end

local function ParseMacrotextForDisplay(body)
	local entry = { t = GetTime() }
	-- #showtooltip with an explicit (possibly conditional) argument wins
	local ttArg = body:match("#showtooltip%s+([^\r\n]+)")
	if ttArg and ttArg ~= "" then
		local value, target = SecureCmdOptionParse(ttArg)
		if value and value ~= "" then
			entry.unit = target
			ResolveMacroDisplayValue(value, entry)
			if entry.spellID or entry.itemID then
				return entry
			end
		end
	end
	for line in body:gmatch("[^\r\n]+") do
		local cmd, rest = line:match("^%s*(/%a+)%s*(.-)%s*$")
		if cmd then
			cmd = cmd:lower()
			if MACRO_CAST_COMMANDS[cmd] and rest and rest ~= "" then
				local value, target = SecureCmdOptionParse(rest)
				if value and value ~= "" then
					entry.unit = target
					ResolveMacroDisplayValue(value, entry)
					if entry.spellID or entry.itemID then
						return entry
					end
				end
			elseif cmd == "/castsequence" and rest and rest ~= "" then
				local value = SecureCmdOptionParse(rest)
				if value and value ~= "" then
					local _, item, spell = QueryCastSequence and QueryCastSequence(value)
					if item then
						ResolveMacroDisplayValue(tostring(item), entry)
					elseif spell then
						ResolveMacroDisplayValue(tostring(spell), entry)
					else
						value = value:gsub("reset=[^%s,]+%s*", "")
						local first = value:match("^%s*([^,]+)")
						if first then
							ResolveMacroDisplayValue(first:match("^%s*(.-)%s*$"), entry)
						end
					end
					if entry.spellID or entry.itemID then
						return entry
					end
				end
			end
		end
	end
	return entry
end

local function ResolveMacrotext(self)
	-- Display-only body (UF hover peek): cast attributes stay on keyboard emission;
	-- icons/CD/usable follow the hover body while the cursor is over a unit frame.
	local body = self._fluxMacrotextDisplayBody
	if type(body) ~= "string" or body == "" then
		body = self._state_action
	end
	if type(body) ~= "string" or body == "" then return nil end
	local e = macrotextParseCache[body]
	local now = GetTime()
	if e and e.t == now then
		return e
	end
	if macrotextParseCacheSize > 256 then
		wipe(macrotextParseCache)
		macrotextParseCacheSize = 0
	end
	e = ParseMacrotextForDisplay(body)
	if not macrotextParseCache[body] then
		macrotextParseCacheSize = macrotextParseCacheSize + 1
	end
	macrotextParseCache[body] = e
	return e
end

local MACROTEXT_FALLBACK_ICON = 134400 -- INV_Misc_QuestionMark

Macrotext.HasAction               = function(self) return true end
Macrotext.GetActionText           = function(self) return "" end
Macrotext.GetTexture              = function(self)
	local e = ResolveMacrotext(self)
	if e then
		if e.spellID then
			local tex = GetSpellTexture(e.spellID)
			if tex then return tex end
		elseif e.itemID and C_Item and C_Item.GetItemIconByID then
			local tex = C_Item.GetItemIconByID(e.itemID)
			if tex then return tex end
		end
	end
	return MACROTEXT_FALLBACK_ICON
end
Macrotext.GetCount                = function(self)
	local e = ResolveMacrotext(self)
	if not e then return 0 end
	if e.itemID then
		return C_Item and C_Item.GetItemCount and C_Item.GetItemCount(e.itemID, nil, true) or 0
	elseif e.spellID then
		return GetSpellCastCount(e.spellID) or 0
	end
	return 0
end
Macrotext.GetChargeInfo           = function(self)
	local e = ResolveMacrotext(self)
	if e and e.spellID and C_Spell and C_Spell.GetSpellCharges then
		return C_Spell.GetSpellCharges(e.spellID)
	end
	return nil
end
Macrotext.GetCooldownInfo         = function(self)
	local e = ResolveMacrotext(self)
	if not e then return nil end
	if e.spellID and C_Spell and C_Spell.GetSpellCooldown then
		return C_Spell.GetSpellCooldown(e.spellID)
	elseif e.itemID and C_Container and C_Container.GetItemCooldown then
		local start, duration, enable = C_Container.GetItemCooldown(e.itemID)
		return { startTime = start, duration = duration, isEnabled = enable, modRate = 1.0, isActive = (enable and start and start > 0 and duration and duration > 0) }
	end
	return nil
end
Macrotext.GetLoCCooldownInfo      = function(self)
	local e = ResolveMacrotext(self)
	if e and e.spellID then
		return GetSpellLossOfControlCooldownInfo(e.spellID)
	end
	return nil
end
Macrotext.GetLossOfControlCooldown = function(self)
	local e = ResolveMacrotext(self)
	if e and e.spellID and GetSpellLossOfControlCooldown then
		return GetSpellLossOfControlCooldown(e.spellID)
	end
	return 0, 0
end
Macrotext.IsAttack                = function(self)
	local e = ResolveMacrotext(self)
	if e and e.spellID then
		local slot = FindSpellBookSlotBySpellID(e.spellID)
		return slot and IsAttackSpell(slot, BOOKTYPE_SPELL) or nil
	end
	return nil
end
Macrotext.IsEquipped              = function(self)
	local e = ResolveMacrotext(self)
	if e and e.itemID and C_Item and C_Item.IsEquippedItem then
		return C_Item.IsEquippedItem(e.itemID)
	end
	return nil
end
Macrotext.IsCurrentlyActive       = function(self)
	-- Dual-split: Exclusive paints checked on LAB or badge. Stock path must not
	-- light LAB from a resolved line while IsCurrentAction semantics leak in.
	if self._fluxExclusiveCheckedManaged then
		return nil
	end
	local e = ResolveMacrotext(self)
	if not e then return nil end
	if e.spellID then
		return IsCurrentSpell(e.spellID)
	elseif e.itemID and C_Item and C_Item.IsCurrentItem then
		return C_Item.IsCurrentItem(e.itemID)
	end
	return nil
end
Macrotext.IsAutoRepeat            = function(self)
	local e = ResolveMacrotext(self)
	if e and e.spellID then
		local slot = FindSpellBookSlotBySpellID(e.spellID)
		return slot and IsAutoRepeatSpell(slot, BOOKTYPE_SPELL) or nil
	end
	return nil
end
Macrotext.IsUsable                = function(self)
	-- Returns isUsable, notEnoughMana. nil,nil = secret/inaccessible (keep last paint).
	-- Must forward BOTH returns — capturing only the first drops mana-blue.
	local secretSeen = false
	local function usableFromSpell(spellID)
		if not spellID then return nil end
		local API = FluxAPICompat and FluxAPICompat.API
		local u, m
		if API and API.IsSpellUsable then
			u, m = API.IsSpellUsable(spellID)
		else
			u, m = IsSpellUsable(spellID)
		end
		if u == nil and m == nil then
			secretSeen = true
			return nil
		end
		return u, m
	end
	local function usableFromEntry(e)
		if not e then return nil end
		if e.spellID then
			return usableFromSpell(e.spellID)
		elseif e.itemID and C_Item and C_Item.IsUsableItem then
			return C_Item.IsUsableItem(e.itemID)
		end
		return nil
	end
	local e = ResolveMacrotext(self)
	local u, m = usableFromEntry(e)
	if u ~= nil then return u, m end
	-- Identity / bindingWins stamp: usable follows the painted spell.
	local aspect = tonumber(self._fluxAspectDisplaySpellId)
	if aspect and aspect > 0 then
		u, m = usableFromSpell(aspect)
		if u ~= nil then return u, m end
	end
	-- UF display peek may leave hover body unresolved — try keyboard cast body.
	if self._fluxMacrotextDisplayBody then
		local kbBody = self._state_action
		if type(kbBody) == "string" and kbBody ~= "" and kbBody ~= self._fluxMacrotextDisplayBody then
			local kb = ParseMacrotextForDisplay(kbBody)
			u, m = usableFromEntry(kb)
			if u ~= nil then return u, m end
		end
	end
	if secretSeen then
		return nil, nil
	end
	-- True unknown empty: white (ButtonForge), never false-gray.
	return true, false
end
Macrotext.IsConsumableOrStackable = function(self)
	local e = ResolveMacrotext(self)
	if not e then return nil end
	local API = FluxAPICompat and FluxAPICompat.API
	local function SafeNum(v)
		if API and API.SafeGetNumber then
			return API.SafeGetNumber(v, nil)
		end
		if issecretvalue and issecretvalue(v) then
			return nil
		end
		if canaccessvalue and not canaccessvalue(v) then
			return nil
		end
		local n = tonumber(v)
		return n
	end
	if e.spellID then
		local sid = SafeNum(e.spellID) or e.spellID
		if IsConsumableSpell then
			local ok, isCons = pcall(IsConsumableSpell, sid)
			if ok and isCons then
				return true
			end
		end
		local castCount = GetSpellCastCount and GetSpellCastCount(sid)
		local n = SafeNum(castCount)
		if n == nil then
			-- Secret / inaccessible cast count: do not compare; treat as non-stackable label.
			return false
		end
		return n > 0
	elseif e.itemID then
		local iid = SafeNum(e.itemID) or e.itemID
		if C_Item and C_Item.IsConsumableItem then
			local ok, isCons = pcall(C_Item.IsConsumableItem, iid)
			if ok and isCons then
				return true
			end
		end
		if IsConsumableItem then
			local ok, isCons = pcall(IsConsumableItem, iid)
			if ok and isCons then
				return true
			end
		end
		local maxStack = (C_Item and C_Item.GetItemMaxStackSizeByID and C_Item.GetItemMaxStackSizeByID(iid))
			or (GetItemInfo and select(8, GetItemInfo(iid)))
		local isStackable = (SafeNum(maxStack) or 1) > 1
		local count = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(iid, nil, true) or 0
		local nCount = SafeNum(count) or 0
		-- FluxButton parity: consumable, count > 1, or stackable with at least one.
		if nCount > 1 or (isStackable and nCount >= 1) then
			return true
		end
		return false
	end
	return nil
end
Macrotext.IsUnitInRange           = function(self, unit)
	local e = ResolveMacrotext(self)
	if not e then return nil end
	local FR = _G.FluxRange
	local rangeUnit = (e.unit and e.unit ~= "player" and e.unit ~= "cursor") and e.unit or unit
	if e.spellID then
		local spellId = e.spellID
		if FR and FR.ResolveSpellIdentifier then
			spellId = FR.ResolveSpellIdentifier(self, spellId)
		end
		if FR and FR.CheckSpell then
			return FR.CheckSpell(spellId, rangeUnit)
		end
		local slot = FindSpellBookSlotBySpellID(spellId)
		return slot and IsSpellInRange(slot, BOOKTYPE_SPELL, rangeUnit) or nil
		elseif e.itemID then
		if FR and FR.CheckItem then
			return FR.CheckItem(e.itemID, rangeUnit)
		end
		local API = FluxAPICompat and FluxAPICompat.API
		if API and API.IsItemInRange then
			return API.IsItemInRange(e.itemID, rangeUnit)
		end
		if API and API.CanCheckItemInRange and not API.CanCheckItemInRange(rangeUnit) then
			return nil
		end
		if IsItemInRange then
			return IsItemInRange(e.itemID, rangeUnit)
		end
	end
	return nil
end
Macrotext.SetTooltip              = function(self)
	local e = ResolveMacrotext(self)
	if e then
		if e.spellID then
			return GameTooltip:SetSpellByID(e.spellID)
		elseif e.itemID then
			if GameTooltip.SetItemByID then
				return GameTooltip:SetItemByID(e.itemID)
			end
			return GameTooltip:SetHyperlink("item:" .. e.itemID)
		end
	end
	return nil
end
Macrotext.GetSpellId              = function(self)
	local e = ResolveMacrotext(self)
	if not e then return nil end
	if e.spellID then
		return e.spellID
	elseif e.itemID then
		return GetSpellIdFromItemId(e.itemID)
	end
	return nil
end
Macrotext.GetPassiveCooldownSpellID = function(self)
	if C_UnitAuras and C_UnitAuras.GetCooldownAuraBySpellID then
		local e = ResolveMacrotext(self)
		if e and e.spellID then
			return C_UnitAuras.GetCooldownAuraBySpellID(e.spellID)
		end
	end
	return nil
end

if C_Spell and C_Spell.GetSpellDisplayCount then
	Macrotext.GetDisplayCount = function(self)
		local e = ResolveMacrotext(self)
		if e and e.spellID then
			return C_Spell.GetSpellDisplayCount(e.spellID)
		end
		return nil
	end
end
if C_Spell and C_Spell.GetSpellChargeDuration then
	Macrotext.GetChargeDuration = function(self)
		local e = ResolveMacrotext(self)
		if e and e.spellID then
			return C_Spell.GetSpellChargeDuration(e.spellID)
		end
		return nil
	end
end
if C_Spell and C_Spell.GetSpellCooldownDuration then
	Macrotext.GetCooldownDuration = function(self)
		local e = ResolveMacrotext(self)
		if e then
			if e.spellID then
				return C_Spell.GetSpellCooldownDuration(e.spellID)
			elseif e.itemID and C_DurationUtil and C_DurationUtil.CreateDuration then
				local duration = C_DurationUtil.CreateDuration()
				if duration then
					local info = self:GetCooldownInfo()
					if info and info.isActive then
						duration:SetTimeFromStart(info.startTime, info.duration, info.modRate)
					end
					return duration
				end
			end
		end
		return nil
	end
end
if C_Spell and C_Spell.GetSpellLossOfControlCooldownDuration then
	Macrotext.GetLoCCooldownDuration = function(self)
		local e = ResolveMacrotext(self)
		if e and e.spellID then
			return C_Spell.GetSpellLossOfControlCooldownDuration(e.spellID)
		end
		return nil
	end
end

--- Flux Binding: current display resolution for a macrotext button ({ spellID | itemID, unit }).
function Generic:GetMacrotextDisplay()
	if self._state_type ~= "macrotext" then return nil end
	return ResolveMacrotext(self)
end

--- Flux Binding: wipe per-frame macrotext parse cache so same-tick mod/condition
--- flips re-evaluate SecureCmdOptionParse instead of returning a stale entry.
function lib.FluxInvalidateMacrotextParseCache()
	wipe(macrotextParseCache)
	macrotextParseCacheSize = 0
end

--- Flux Binding: re-evaluate all buttons currently showing macrotext overrides
--- (mouseover / modifier / target context flips — insecure display only).
function lib.FluxRefreshMacrotextDisplays()
	for button in next, lib.fluxMacrotextButtons do
		Update(button)
	end
end

local FLUX_ROW_PREFIXES = { "FluxActionButton", "FluxSecondaryButton", "FluxTertiaryButton" }

--- Column-scoped macrotext refresh for paging / condition overlay.
--- `cols` is a set of column numbers (1-19). Nil/empty → full refresh.
--- Touches every row in dirty columns (main + parked minis share the program).
function lib.FluxRefreshMacrotextDisplaysForColumns(cols)
	if not cols or not next(cols) then
		lib.FluxRefreshMacrotextDisplays()
		return
	end
	local seen = {}
	if lib.fluxMacrotextButtons then
		for button in next, lib.fluxMacrotextButtons do
			local col = button and button._fluxBarSlotIndex
			if col and cols[col] then
				seen[button] = true
				Update(button)
			end
		end
	end
	for col in pairs(cols) do
		if type(col) == "number" then
			for i = 1, #FLUX_ROW_PREFIXES do
				local button = _G[FLUX_ROW_PREFIXES[i] .. col]
				if button and not seen[button] and button._state_type == "macrotext" then
					seen[button] = true
					Update(button)
				end
			end
		end
	end
end

--- Mouseover-only refresh: prefer mouseover-indexed action macros + all macrotext
--- (Binding macros are typically mouseover-sensitive). Avoids full ActiveButtons walks.
function lib.FluxRefreshMacrotextDisplaysMouseover()
	if lib.fluxMacrotextButtons then
		for button in next, lib.fluxMacrotextButtons do
			Update(button)
		end
	end
	if lib.fluxMouseoverMacroButtons then
		for button in next, lib.fluxMouseoverMacroButtons do
			if not (lib.fluxMacrotextButtons and lib.fluxMacrotextButtons[button]) then
				Update(button)
			end
		end
	end
end

function lib.FluxHasMacrotextButtons()
	return next(lib.fluxMacrotextButtons) ~= nil
end

end -- do (Macrotext class scope)

-----------------------------------------------------------
--- Custom Button
Custom.HasAction               = function(self) return true end
Custom.GetActionText           = function(self) return "" end
Custom.GetTexture              = function(self) return self._state_action.texture end
Custom.GetCount                = function(self) return 0 end
Custom.GetChargeInfo           = function(self) return nil end
Custom.GetCooldownInfo         = function(self) return nil end
Custom.IsAttack                = function(self) return nil end
Custom.IsEquipped              = function(self) return nil end
Custom.IsCurrentlyActive       = function(self) return nil end
Custom.IsAutoRepeat            = function(self) return nil end
Custom.IsUsable                = function(self) return true end
Custom.IsConsumableOrStackable = function(self) return nil end
Custom.IsUnitInRange           = function(self, unit) return nil end
Custom.SetTooltip              = function(self) return GameTooltip:SetText(self._state_action.tooltip) end
Custom.GetSpellId              = function(self) return nil end
Custom.RunCustom               = function(self, unit, button) return self._state_action.func(self, unit, button) end
Custom.GetPassiveCooldownSpellID = function(self) return nil end

--- WoW Classic overrides
if DisableOverlayGlow then
	UpdateOverlayGlow = function() end
end

-----------------------------------------------------------
--- Update old Buttons
if oldversion and next(lib.buttonRegistry) then
	InitializeEventHandler()
	for button in next, lib.buttonRegistry do
		-- this refreshes the metatable on the button
		Generic.UpdateAction(button, true)
		SetupSecureSnippets(button)
		if oldversion < 12 then
			WrapOnClick(button)
		end
		if oldversion < 23 then
			if button.overlay then
				button.overlay:Hide()
				ActionButton_HideOverlayGlow(button)
				button.overlay = nil
				UpdateOverlayGlow(button)
			end
		end
	end
end

if oldversion and lib.flyoutHandler then
	UpdateFlyoutHandlerScripts()
end

--- Flux: /run LibStub("LibActionButton-1.0"):FluxLABDumpUsableDebug() after /run _G.FluxLABUsableEventDebug=true
function lib:FluxLABDumpUsableDebug()
	print("|cff00ff00FluxUI LAB|r m" .. MINOR_VERSION,
		"ACTION_USABLE_CHANGED registered=", tostring(lib._fluxActionUsableChangedRegistered),
		"granularEv=", tostring(lib._fluxDbgGranularUsableEv),
		"broadcastFlush=", tostring(lib._fluxDbgBroadcastUsable),
		"skippedBroadcastFullSkip=", tostring(lib._fluxDbgSkippedBroadcast),
		"UpdateUsableCalls(dbg)=", tostring(lib._fluxDbgUpdateUsableCalls))
end

