-- MouseoverCast.lua — click-time unit for plain type=action slots.
--
-- Overlay models Binding installs (this file does not walk hosts):
--   surface — visible host type=macro + macrotext; Blizzard parses hops
--   hidden  — type=click onto FluxSlotClick_<slot> (sequences / petattack / ...)
--   display — type=action click + ephemeral face (native tails / hover_only)
--
-- This file owns click-time unit for plain type=action / spell / item only.
-- Wrap clients (live / classic): a secure PreClick wrap writes unit=mouseover
-- when that unit exists, else target when that unit exists, else nil.
-- Forever has no WrapScript (hasRestrictedClosures=false) but ships Blizzard's
-- enableMouseoverCast CVar; the Action Bars toggle drives that CVar plus
-- checkmouseovercast on plain action/spell/item widgets.
-- Stamping a missing unit makes SecureActionButton_OnClick return before the
-- action (all flavours). Overlay hosts (macro / click / macrotext) clear
-- leftover unit and skip the pick — targeting lives in the body. A static
-- unit="mouseover" is resolved on every cursor hop (usable/range) and is the
-- world-sweep hitch on every flavour. Native-only factory tails stay
-- type=action + this wrap (or native CVar on Forever). Live [@mouseover]
-- RegisterStateDriver is parked leftover only.
local addonName, ns = ...
local Flux = ns.Flux

local MouseoverCast = {}
Flux.MouseoverCast = MouseoverCast
Flux.Engine = Flux.Engine or {}
Flux.Engine.MouseoverCast = MouseoverCast
_G.FluxMouseoverCast = MouseoverCast

local PARK_GRACE = 0.75
local CLASSIFY_DEBOUNCE = 0.15

-- Click-time unit pick for plain type=action (native / display-mode tails).
-- Surface macrotext and hidden clicker overlays skip this wrap.
local UNIT_PRECLICK = [[
	if button == "RightButton" or button == "ConjureBind" or button == "MiddleButton" then
		self:SetAttribute("unit", nil)
		return
	end
	local t = self:GetAttribute("type")
	if t == "click" or t == "macro" or t == "macrotext" then
		self:SetAttribute("unit", nil)
		return
	end
	if not self:GetAttribute("smarttarget") and not self:GetAttribute("flux-smart") then
		return
	end
	if UnitExists("mouseover") then
		self:SetAttribute("unit", "mouseover")
	elseif UnitExists("target") then
		self:SetAttribute("unit", "target")
	else
		self:SetAttribute("unit", nil)
	end
]]

-- Drop the click-time unit so hops after a press cannot keep resolving
-- leftover unit=mouseover. Overlay clickers keep their parked body.
local UNIT_POSTCLICK = [[
	local t = self:GetAttribute("type")
	if t == "click" or t == "macro" or t == "macrotext" then
		self:SetAttribute("unit", nil)
		return
	end
	if not self:GetAttribute("smarttarget") and not self:GetAttribute("flux-smart") then
		self:SetAttribute("unit", nil)
		return
	end
	self:SetAttribute("unit", nil)
]]

local hub = nil
local headers = {}
local hosts = {}
local buttons = {}
local smartKeys = {}

local driversLive = false
local driverSyncQueued = false
local classifyQueued = false
local lastNeedAt = 0
local started = false

local function InLockdown()
	if Flux.Combat and Flux.Combat.InLockdown then
		return Flux.Combat.InLockdown()
	end
	return InCombatLockdown and InCombatLockdown() or false
end

local function After(delay, fn)
	local after = (Flux.Timer and Flux.Timer.After) or (C_Timer and C_Timer.After)
	if after then
		after(delay, fn)
		return true
	end
	return false
end

local function UnitThere(unit)
	if not UnitExists then
		return false
	end
	local ok, exists = pcall(UnitExists, unit)
	return ok and exists and true or false
end

-- ---------------------------------------------------------------------------
-- Setting
-- ---------------------------------------------------------------------------

local function OptionsTable()
	local fo = _G.FluxOptions
	if fo and fo.GetActionbarsDB then
		local ok, t = pcall(fo.GetActionbarsDB, fo)
		if ok then
			return t
		end
	end
	return nil
end

function MouseoverCast.IsEnabled()
	local t = OptionsTable()
	if t and t.mouseoverCast ~= nil then
		return t.mouseoverCast == true
	end
	if _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.mouseoverCast ~= nil then
		return _FluxUI_CharSavedVars.mouseoverCast == true
	end
	return true
end

--- Forever: CVar exists and WrapScript does not. Live/classic keep PreClick
--- and leave the CVar off so world hops do not retarget slots.
function MouseoverCast.UsesNativeCVar()
	local Cap = Flux.Cap
	if not (Cap and Cap.hasRestrictedClosures == false) then
		return false
	end
	return C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("enableMouseoverCast") ~= nil
end

local NATIVE_CHECK_TYPES = {
	action = true,
	spell = true,
	item = true,
}

--- Forever native path: checkmouseovercast on plain action/spell/item only.
--- Overlay macro/click/macrotext keep it off (targeting is in the body).
function MouseoverCast.ApplyNativeCheck(widget)
	if not widget or not widget.SetAttribute then
		return
	end
	local t = widget.GetAttribute and widget:GetAttribute("type")
	if MouseoverCast.UsesNativeCVar() and MouseoverCast.IsEnabled()
		and t and NATIVE_CHECK_TYPES[t] then
		widget:SetAttribute("checkmouseovercast", true)
	else
		widget:SetAttribute("checkmouseovercast", false)
	end
end

local syncingCVar = false

--- Wrap clients: CVar stays off (PreClick covers click). Forever must not
--- SetCVar either: gamepad buttons set checkmouseovercast and read
--- enableMouseoverCast inside SecureActionButton_OnClick. An addon write
--- taints that read and UseAction() is forbidden. The Blizzard checkbox owns
--- the CVar; ApplyNativeCheck still stamps Flux widgets.
local function SyncCVar()
	if not SetCVar then
		return
	end
	if MouseoverCast.UsesNativeCVar() then
		return
	end
	syncingCVar = true
	pcall(SetCVar, "enableMouseoverCast", "0")
	syncingCVar = false
end

local function CVarIsOn()
	if GetCVarBool then
		return GetCVarBool("enableMouseoverCast") and true or false
	end
	local v = GetCVar and GetCVar("enableMouseoverCast")
	return v == "1" or v == 1 or v == true
end

--- Blizzard Combat checkbox writes the same CVar. Keep AceDB in lockstep.
local function OnCVarUpdate(_, name)
	if syncingCVar then
		return
	end
	if name ~= "enableMouseoverCast" and name ~= "ENABLE_MOUSEOVER_CAST" then
		return
	end
	if not MouseoverCast.UsesNativeCVar() then
		return
	end
	local on = CVarIsOn()
	if on == MouseoverCast.IsEnabled() then
		return
	end
	MouseoverCast.SetEnabled(on)
end

-- ---------------------------------------------------------------------------
-- Secure snippets
-- ---------------------------------------------------------------------------

-- Runs on the host itself. Never stamp a live unit token: the client
-- re-targets usable/range on every hop while unit=mouseover sits on the widget.
local HOST_APPLY = [[
	self:SetAttribute("targettype", nil)
	if not self:GetAttribute("smarttarget") then
		self:SetAttribute("unit", nil)
		return
	end
	-- Overlay click (type=click) owns targeting on a hidden SAB. Never put a
	-- unit attribute on it. A compiled leftover type=macro is the same.
	if self:GetAttribute("type") ~= "action" then
		self:SetAttribute("unit", nil)
		return
	end
	-- Click wrap writes mouseover/target only when that unit exists. A static
	-- unit token is resolved on every cursor hop (usable/range) — the hitch.
	self:SetAttribute("unit", nil)
]]

local HOST_RECOMPUTE = [[
	if self:GetAttribute("flux-mo-apply") then
		self:RunAttribute("flux-mo-apply")
	end
]]

-- ChildUpdate has to be issued by the header itself, so a recompute is bounced
-- through a counter attribute the way FluxActionStripModHub already drives the
-- paging headers, rather than called on a frame reference from the hub.
local HEADER_RECOMPUTE = [[
	control:ChildUpdate("fluxmo", 1)
]]

local HUB_RECOMPUTE = [[
	local n = tonumber(self:GetAttribute("flux-mo-headers")) or 0
	local tick = (tonumber(self:GetAttribute("flux-mo-tick")) or 0) + 1
	self:SetAttribute("flux-mo-tick", tick)
	for i = 1, n do
		local h = self:GetFrameRef("hdr" .. i)
		if h then
			h:SetAttribute("state-fluxmo", tick)
		end
	end
]]

-- ---------------------------------------------------------------------------
-- Hub
-- ---------------------------------------------------------------------------

local function EnsureHub()
	if hub then
		return hub
	end
	if not CreateFrame then
		return nil
	end
	hub = CreateFrame("Frame", "FluxActionStripMouseoverHub", nil, "SecureHandlerStateTemplate")
	-- Leftover sessions stamped _onstate-target-* here. Nothing drives those
	-- attributes anymore; keep them nil so a stray ChildUpdate cannot rewrite unit.
	hub:SetAttribute("_onstate-target-help", nil)
	hub:SetAttribute("_onstate-target-harm", nil)
	hub:SetAttribute("_onstate-target-all", nil)
	local Restricted = Flux.Restricted
	if Restricted and Restricted.SetSnippet then
		Restricted.SetSnippet(hub, "flux-mo-recompute", HUB_RECOMPUTE)
	elseif not (Restricted and Restricted.Works and not Restricted.Works()) then
		hub:SetAttribute("flux-mo-recompute", HUB_RECOMPUTE)
	end
	return hub
end

local function Recompute()
	if not hub or InLockdown() then
		return
	end
	local Restricted = Flux.Restricted
	if Restricted and Restricted.Execute then
		Restricted.Execute(hub, [[ self:RunAttribute("flux-mo-recompute") ]])
		return
	end
	if Restricted and Restricted.Works and not Restricted.Works() then
		return
	end
	pcall(hub.Execute, hub, [[ self:RunAttribute("flux-mo-recompute") ]])
end

-- ---------------------------------------------------------------------------
-- Classification
-- ---------------------------------------------------------------------------

--- 1 helpful, 2 harmful, 3 both or neither. nil when the client will not say.
local function ClassifySpell(index, bookType, spellId)
	local helpful, harmful
	if spellId and C_Spell and C_Spell.IsSpellHelpful and C_Spell.IsSpellHarmful then
		local okH, h = pcall(C_Spell.IsSpellHelpful, spellId)
		local okM, m = pcall(C_Spell.IsSpellHarmful, spellId)
		if okH then
			helpful = h
		end
		if okM then
			harmful = m
		end
	end
	if helpful == nil and harmful == nil and index and IsHelpfulSpell and IsHarmfulSpell then
		local okH, h = pcall(IsHelpfulSpell, index, bookType)
		local okM, m = pcall(IsHarmfulSpell, index, bookType)
		if okH then
			helpful = h
		end
		if okM then
			harmful = m
		end
	end
	if helpful == nil and harmful == nil then
		return nil
	end
	helpful = helpful and true or false
	harmful = harmful and true or false
	if helpful == harmful then
		return 3
	end
	return helpful and 1 or 2
end

--- 1 helpful, 2 harmful, 3 both/neither/unknown. Unknown items still use the
--- all-driver so a bandage or trinket on the bar mouseover-casts.
local function ClassifyItem(itemId)
	if not itemId then
		return 3
	end
	local helpful, harmful
	if C_Item and C_Item.IsHelpfulItem and C_Item.IsHarmfulItem then
		local okH, h = pcall(C_Item.IsHelpfulItem, itemId)
		local okM, m = pcall(C_Item.IsHarmfulItem, itemId)
		if okH then
			helpful = h
		end
		if okM then
			harmful = m
		end
	end
	if helpful == nil and harmful == nil then
		if IsHelpfulItem then
			local okH, h = pcall(IsHelpfulItem, itemId)
			if okH then
				helpful = h
			end
		end
		if IsHarmfulItem then
			local okM, m = pcall(IsHarmfulItem, itemId)
			if okM then
				harmful = m
			end
		end
	end
	if helpful == nil and harmful == nil then
		return 3
	end
	helpful = helpful and true or false
	harmful = harmful and true or false
	if helpful == harmful then
		return 3
	end
	return helpful and 1 or 2
end

local function ClearSmartAttrs()
	if not hub then
		return
	end
	for key in pairs(smartKeys) do
		hub:SetAttribute(key, nil)
		smartKeys[key] = nil
	end
end

local function Classify()
	classifyQueued = false
	if InLockdown() or not EnsureHub() then
		return
	end
	ClearSmartAttrs()
	if not MouseoverCast.IsEnabled() then
		return
	end

	local function Put(key, value)
		hub:SetAttribute(key, value)
		smartKeys[key] = true
	end

	local function Record(index, bookType, actionId, spellId)
		local tt = ClassifySpell(index, bookType, spellId)
		if tt then
			if spellId then
				Put("flux-mo-tt-" .. tostring(spellId), tt)
			end
			if actionId and actionId ~= spellId then
				Put("flux-mo-tt-" .. tostring(actionId), tt)
			end
		end
		-- Higher ranks and form variants resolve back onto the base action id.
		if spellId and actionId and spellId ~= actionId then
			Put("flux-mo-ov-" .. tostring(spellId), actionId)
		end
	end

	local SB = C_SpellBook
	if SB and SB.GetSpellBookItemType and Enum and Enum.SpellBookSpellBank and Enum.SpellBookItemType then
		local bank = Enum.SpellBookSpellBank.Player
		local i = 1
		while true do
			local ok, itemType, actionId, spellId = pcall(SB.GetSpellBookItemType, i, bank)
			if not ok or not itemType then
				break
			end
			if itemType == Enum.SpellBookItemType.Spell then
				Record(i, "spell", actionId, spellId)
			end
			i = i + 1
		end
	elseif GetSpellBookItemInfo then
		local i = 1
		while true do
			local ok, subType, actionId = pcall(GetSpellBookItemInfo, i, "spell")
			if not ok or not subType then
				break
			end
			if subType == "SPELL" then
				local spellId
				if GetSpellInfo then
					local okI, _, _, _, _, _, _, sid = pcall(GetSpellInfo, i, "spell")
					if okI then
						spellId = sid
					end
				end
				Record(i, "spell", actionId, spellId)
			end
			i = i + 1
		end
	end

	-- Bar items are not in the spellbook walk. Publish them so HOST_APPLY can
	-- pick help/harm/all the same way a spell does.
	if GetActionInfo then
		for slot = 1, 180 do
			local ok, aType, id = pcall(GetActionInfo, slot)
			if ok and aType == "item" and id then
				Put("flux-mo-item-" .. tostring(id), ClassifyItem(id))
			end
		end
	end

	Recompute()
end

local function QueueClassify()
	if classifyQueued then
		return
	end
	classifyQueued = true
	if not After(CLASSIFY_DEBOUNCE, Classify) then
		classifyQueued = false
		Classify()
	end
end

MouseoverCast.Refresh = QueueClassify

-- ---------------------------------------------------------------------------
-- Drivers (legacy leftover only)
-- ---------------------------------------------------------------------------

-- Older sessions registered [@mouseover] state drivers on this hub. Those
-- macros are evaluated by the client on every hover hop and are the sweep
-- hitch on Classic and Retail. Never re-arm them.
local function ParkLegacyDrivers()
	if not hub or not UnregisterStateDriver then
		return
	end
	pcall(UnregisterStateDriver, hub, "target-help")
	pcall(UnregisterStateDriver, hub, "target-harm")
	pcall(UnregisterStateDriver, hub, "target-all")
end

local function WrapUnitPick(widget)
	if not widget or not hub or InLockdown() then
		return
	end
	local Restricted = Flux.Restricted
	if Restricted then
		Restricted.UnwrapScript(hub, widget, "PreClick")
		Restricted.UnwrapScript(hub, widget, "PostClick")
		Restricted.WrapScript(hub, widget, "PreClick", UNIT_PRECLICK)
		Restricted.WrapScript(hub, widget, "PostClick", UNIT_POSTCLICK)
		return
	end
	if Flux.Cap and Flux.Cap.hasRestrictedClosures == false then
		return
	end
	if hub.UnwrapScript then
		pcall(hub.UnwrapScript, hub, widget, "PreClick")
		pcall(hub.UnwrapScript, hub, widget, "PostClick")
	end
	if hub.WrapScript then
		pcall(hub.WrapScript, hub, widget, "PreClick", UNIT_PRECLICK)
		pcall(hub.WrapScript, hub, widget, "PostClick", UNIT_POSTCLICK)
	end
end

function MouseoverCast.SyncDrivers()
	if InLockdown() then
		return
	end
	ParkLegacyDrivers()
	driversLive = false
	if MouseoverCast.IsEnabled() then
		Recompute()
	end
end

-- ---------------------------------------------------------------------------
-- Registration
-- ---------------------------------------------------------------------------

local function RefreshHeaderRefs()
	if not hub or InLockdown() then
		return
	end
	for i = 1, #headers do
		hub:SetFrameRef("hdr" .. i, headers[i])
	end
	hub:SetAttribute("flux-mo-headers", #headers)
end

--- Strip headers own the ChildUpdate fan-out to their host children.
function MouseoverCast.RegisterHeader(header)
	if not header or not header.SetAttribute or InLockdown() then
		return
	end
	if not EnsureHub() then
		return
	end
	for i = 1, #headers do
		if headers[i] == header then
			return
		end
	end
	headers[#headers + 1] = header
	header:SetAttribute("_onstate-target-help", nil)
	header:SetAttribute("_onstate-target-harm", nil)
	header:SetAttribute("_onstate-target-all", nil)
	local Restricted = Flux.Restricted
	if Restricted and Restricted.SetSnippet then
		Restricted.SetSnippet(header, "_onstate-fluxmo", HEADER_RECOMPUTE)
	elseif not (Restricted and Restricted.Works and not Restricted.Works()) then
		header:SetAttribute("_onstate-fluxmo", HEADER_RECOMPUTE)
	end
	header:SetFrameRef("fluxmohub", hub)
	RefreshHeaderRefs()
end

--- Strip hosts: paged action slots that resolve their spell from `action`.
function MouseoverCast.AttachHost(widget)
	if not widget or not widget.SetAttribute or InLockdown() then
		return
	end
	if not EnsureHub() then
		return
	end
	for i = 1, #hosts do
		if hosts[i] == widget then
			return
		end
	end
	hosts[#hosts + 1] = widget
	local Restricted = Flux.Restricted
	if Restricted and Restricted.SetSnippet then
		Restricted.SetSnippet(widget, "flux-mo-apply", HOST_APPLY)
		Restricted.SetSnippet(widget, "_childupdate-fluxmo", HOST_RECOMPUTE)
	elseif not (Restricted and Restricted.Works and not Restricted.Works()) then
		widget:SetAttribute("flux-mo-apply", HOST_APPLY)
		widget:SetAttribute("_childupdate-fluxmo", HOST_RECOMPUTE)
	end
	widget:SetAttribute("_childupdate-target-help", nil)
	widget:SetAttribute("_childupdate-target-harm", nil)
	widget:SetAttribute("_childupdate-target-all", nil)
	widget:SetAttribute("smarttarget", MouseoverCast.IsEnabled() or nil)
	WrapUnitPick(widget)
	MouseoverCast.ApplyNativeCheck(widget)
	if MouseoverCast.IsEnabled() then
		Recompute()
	end
end

--- Extra buttons: PreClick wrap only. Classification lives on flux-smart so
--- the wrap knows the slot mouseover-casts; unit stays nil between clicks.
function MouseoverCast.RegisterButton(widget)
	if not widget or not widget.SetAttribute or InLockdown() then
		return
	end
	if not EnsureHub() then
		return
	end
	for i = 1, #buttons do
		if buttons[i] == widget then
			return
		end
	end
	buttons[#buttons + 1] = widget
	WrapUnitPick(widget)
	MouseoverCast.ApplyNativeCheck(widget)
end

local function ApplyButtonTargetType(widget, tt)
	if widget:GetAttribute("flux-smart") ~= tt then
		widget:SetAttribute("flux-smart", tt)
		-- Click wrap writes mouseover/target only when that unit exists.
		widget:SetAttribute("unit", nil)
	end
	MouseoverCast.ApplyNativeCheck(widget)
end

--- Called from Action.SetAction with the button's live spell id (or nil).
function MouseoverCast.SetButtonSpell(widget, spellId)
	if not widget or not widget.SetAttribute or InLockdown() then
		return
	end
	local tt
	if spellId and MouseoverCast.IsEnabled() then
		-- Prefer the spellbook walk: on clients without C_Spell.IsSpellHelpful
		-- the per-id query cannot answer, but the book pass already did.
		if hub then
			tt = hub:GetAttribute("flux-mo-tt-" .. tostring(spellId))
		end
		if not tt then
			tt = ClassifySpell(nil, nil, spellId)
		end
		-- Same default as HOST_APPLY: unclassified still uses the all-driver.
		if not tt then
			tt = 3
		end
	end
	ApplyButtonTargetType(widget, tt)
end

function MouseoverCast.SetButtonItem(widget, itemId)
	if not widget or not widget.SetAttribute or InLockdown() then
		return
	end
	local tt
	if itemId and MouseoverCast.IsEnabled() then
		tt = ClassifyItem(itemId)
	end
	ApplyButtonTargetType(widget, tt)
end

-- ---------------------------------------------------------------------------
-- Enable / disable
-- ---------------------------------------------------------------------------

local function ClearAll()
	local function strip(frame)
		if not frame or not frame.SetAttribute then
			return
		end
		frame:SetAttribute("smarttarget", nil)
		frame:SetAttribute("targettype", nil)
		frame:SetAttribute("target_help", nil)
		frame:SetAttribute("target_harm", nil)
		frame:SetAttribute("target_all", nil)
		frame:SetAttribute("flux-smart", nil)
		frame:SetAttribute("unit", nil)
		frame:SetAttribute("checkmouseovercast", false)
	end
	for i = 1, #hosts do
		strip(hosts[i])
	end
	for i = 1, #buttons do
		strip(buttons[i])
	end
end

function MouseoverCast.Apply()
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("mouseovercast.apply", MouseoverCast.Apply)
		end
		return
	end
	if not EnsureHub() then
		return
	end
	SyncCVar()
	if not MouseoverCast.IsEnabled() then
		ParkLegacyDrivers()
		driversLive = false
		ClearSmartAttrs()
		ClearAll()
		return
	end
	ParkLegacyDrivers()
	for i = 1, #hosts do
		local h = hosts[i]
		if h and h.SetAttribute then
			h:SetAttribute("smarttarget", true)
			WrapUnitPick(h)
			MouseoverCast.ApplyNativeCheck(h)
		end
	end
	for i = 1, #buttons do
		WrapUnitPick(buttons[i])
		MouseoverCast.ApplyNativeCheck(buttons[i])
	end
	Classify()
	MouseoverCast.SyncDrivers()
end

function MouseoverCast.SetEnabled(on)
	on = on == true
	local t = OptionsTable()
	if t then
		t.mouseoverCast = on
	end
	if _FluxUI_CharSavedVars then
		_FluxUI_CharSavedVars.mouseoverCast = on
	end
	MouseoverCast.Apply()
	-- Slot macros bake their own [@mouseover] tail, so the Binding plan has to
	-- be recompiled or the two layers disagree about what the key does.
	local FB = _G.FluxBinding
	if FB and FB.NotifySettingsChanged then
		pcall(FB.NotifySettingsChanged, "mouseover_cast")
	end
	-- Toggle off must drop leftover mouseover OOR on the same frame, not wait
	-- for the 0.2s range ticker. Toggle on must start ranging mouseover now.
	local R = Flux.Range
	if R and R.Invalidate then
		R.Invalidate()
	end
	local Bars = Flux.Bars
	if Bars and Bars.Watch and Bars.Watch.SyncRangeSlots then
		Bars.Watch.SyncRangeSlots()
	end
	if Bars and Bars.RequestPaint then
		Bars.RequestPaint("bars.range")
		Bars.RequestPaint("bars.usable")
	end
	local PF = Bars and Bars.ProgramFace
	if PF and PF.RequestConditionalRefresh then
		PF.RequestConditionalRefresh()
	end
	if MouseoverCast.RefreshSpellBookCheckbox then
		MouseoverCast.RefreshSpellBookCheckbox()
	end
	local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
	if ACR and ACR.NotifyChange then
		pcall(ACR.NotifyChange, ACR, "FluxUI")
	end
end

function MouseoverCast.GetStats()
	return {
		enabled = MouseoverCast.IsEnabled(),
		live = driversLive,
		headers = #headers,
		hosts = #hosts,
		buttons = #buttons,
	}
end

--- In-game: /fluxbars mo — what is still armed on a world mouseover hop.
function MouseoverCast.DebugDump()
	local printFn = print
	local cvar = GetCVar and GetCVar("enableMouseoverCast") or "?"
	local PF = Flux.Bars and Flux.Bars.ProgramFace
	local flags = PF and PF.ProbeFlags and PF.ProbeFlags() or {}
	local needMo = PF and PF.Needs and PF.Needs("mouseover")
	local liveMo, clickN, hiddenMo, checkN = 0, 0, 0, 0
	local Bars = Flux.Bars
	if Bars and Bars.ForEachHost then
		Bars.ForEachHost(function(host)
			local w = host and host.widget
			if not (w and w.GetAttribute) then
				return
			end
			if w:GetAttribute("checkmouseovercast") then
				checkN = checkN + 1
			end
			local mt = w:GetAttribute("macrotext")
			if type(mt) == "string" and string.upper(mt):find("MOUSEOVER", 1, true) then
				liveMo = liveMo + 1
			end
			if w:GetAttribute("type") == "click" then
				clickN = clickN + 1
			end
			local slot = w:GetAttribute("action")
			if slot then
				local clicker = w:GetAttribute("flux-click-" .. slot)
				local hiddenText = clicker and clicker.GetAttribute and clicker:GetAttribute("macrotext")
				if type(hiddenText) == "string" and string.upper(hiddenText):find("MOUSEOVER", 1, true) then
					hiddenMo = hiddenMo + 1
				end
			end
		end)
	end
	printFn("Flux mouseover debug (world hops should keep liveMo=0 unless you wrote [@mouseover] on a shown widget)")
	printFn("  toggle=" .. tostring(MouseoverCast.IsEnabled()) .. "  CVar enableMouseoverCast=" .. tostring(cvar))
	printFn("  Lua cond mouseover need=" .. tostring(needMo) .. "  probeFlags.mouseover=" .. tostring(flags.mouseover))
	printFn("  hosts with live macrotext MOUSEOVER=" .. tostring(liveMo)
		.. "  type=click hosts=" .. tostring(clickN)
		.. "  hidden clickers with MOUSEOVER=" .. tostring(hiddenMo))
	local native = MouseoverCast.UsesNativeCVar()
	printFn("  nativeCVar=" .. tostring(native)
		.. "  checkmouseovercast true=" .. tostring(checkN)
		.. (native and " (expected on Forever type=action hosts)" or " (should be 0 on wrap clients)"))
	printFn("  Sweep a pack through empty space; liveMo must stay 0. Click a hovered mob still mouseover-casts.")
end

MouseoverCast.GetEnabled = MouseoverCast.IsEnabled

-- ---------------------------------------------------------------------------
-- Spellbook checkbox (pre-rewrite FluxMouseoverCastCheckbox)
-- ---------------------------------------------------------------------------

local spellBookCheckbox
local spellBookHooked = false
local PositionSpellBookCheckbox

function MouseoverCast.RefreshSpellBookCheckbox()
	if spellBookCheckbox then
		spellBookCheckbox:SetChecked(MouseoverCast.IsEnabled())
		PositionSpellBookCheckbox()
	end
end

local function CreateSpellBookCheckbox()
	if spellBookCheckbox then
		return
	end
	local checkbox = CreateFrame("CheckButton", "FluxMouseoverCastCheckbox", UIParent, "UICheckButtonTemplate")
	checkbox:SetSize(20, 20)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
	label:SetText("Mouseover Cast")
	label:SetTextColor(1.0, 0.82, 0.0, 1)
	checkbox.label = label
	local bg = checkbox:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(checkbox)
	bg:SetColorTexture(0, 0, 0, 0.4)
	bg:SetBlendMode("BLEND")
	checkbox.bg = bg
	checkbox:SetHitRectInsets(-5, -label:GetStringWidth() - 10, -5, -5)
	checkbox:SetChecked(MouseoverCast.IsEnabled())
	checkbox:SetScript("OnClick", function(self)
		MouseoverCast.SetEnabled(self:GetChecked() and true or false)
	end)
	checkbox:SetScript("OnEnter", function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Enable Mouseover Casting", nil, nil, nil, nil, true)
		GameTooltip:AddLine("Cast on the unit under the cursor without writing [@mouseover] macros. Same setting as Options → Action Bars.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	checkbox:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	spellBookCheckbox = checkbox
	checkbox:Hide()
end

function PositionSpellBookCheckbox()
	if not spellBookCheckbox then
		return
	end
	local Chrome = Flux.SpellBookChrome
	if Chrome and Chrome.Layout then
		Chrome.Layout({ mouseover = spellBookCheckbox })
		if spellBookCheckbox.SetChecked then
			spellBookCheckbox:SetChecked(MouseoverCast.IsEnabled())
		end
		return
	end
	spellBookCheckbox:Hide()
end

local function OnSpellbookShow()
	CreateSpellBookCheckbox()
	PositionSpellBookCheckbox()
end

local function OnSpellbookHide()
	if spellBookCheckbox then
		spellBookCheckbox:Hide()
	end
end

local function BindSpellBookUI()
	if spellBookHooked then
		return
	end
	spellBookHooked = true
	local client = Flux.Client
	if client and (client.isCamelot or client.isForever) then
		local was = (SpellBookFrame and SpellBookFrame.IsShown and SpellBookFrame:IsShown()) and true or false
		local modern = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
		if modern and modern.IsShown and modern:IsShown() then
			was = true
		end
		if was then
			OnSpellbookShow()
		end
		local watch = CreateFrame("Frame")
		watch:SetScript("OnUpdate", function()
			local page = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
			local shown = (SpellBookFrame and SpellBookFrame.IsShown and SpellBookFrame:IsShown())
				or (page and page.IsShown and page:IsShown())
			shown = shown and true or false
			if shown == was then
				return
			end
			was = shown
			if shown then
				OnSpellbookShow()
			else
				OnSpellbookHide()
			end
		end)
		return
	end
	if EventRegistry and EventRegistry.RegisterCallback then
		pcall(EventRegistry.RegisterCallback, EventRegistry, "PlayerSpellsFrame.SpellBookFrame.Show", OnSpellbookShow)
		pcall(EventRegistry.RegisterCallback, EventRegistry, "PlayerSpellsFrame.SpellBookFrame.Hide", OnSpellbookHide)
	end
	if SpellBookFrame then
		if SpellBookFrame.HookScript then
			SpellBookFrame:HookScript("OnShow", OnSpellbookShow)
			SpellBookFrame:HookScript("OnHide", OnSpellbookHide)
		end
		if SpellBookFrame.IsShown and SpellBookFrame:IsShown() then
			OnSpellbookShow()
		end
	end
	local modern = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
	if modern and modern.IsShown and modern:IsShown() then
		OnSpellbookShow()
	end
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

function MouseoverCast.Start()
	if started then
		return
	end
	started = true
	EnsureHub()
	ParkLegacyDrivers()
	local Ev = Flux.Events
	if Ev and Ev.Register then
		Ev.Register("PLAYER_REGEN_ENABLED", function()
			if classifyQueued then
				Classify()
			end
		end)
		Ev.Register("PLAYER_ENTERING_WORLD", MouseoverCast.Apply)
		Ev.Register("CVAR_UPDATE", OnCVarUpdate)
		if Ev.RegisterLearnedSpell then
			Ev.RegisterLearnedSpell(QueueClassify)
		else
			Ev.Register("SPELLS_CHANGED", QueueClassify)
		end
		Ev.Register("PLAYER_SPECIALIZATION_CHANGED", QueueClassify)
		Ev.Register("ACTIVE_TALENT_GROUP_CHANGED", QueueClassify)
		-- Paging is secure, but a slot that changed contents OOC needs its
		-- classification re-read.
		-- A form or page storm emits one ACTIONBAR_SLOT_CHANGED per slot, and
		-- Recompute runs a restricted hub Execute. Coalesce to one per frame.
		local recomputeQueued = false
		local hopRecomputeHeld = false
		local hopRecomputeArmed = false
		local function FlushHopRecompute()
			hopRecomputeArmed = false
			if not hopRecomputeHeld or InLockdown() then
				hopRecomputeHeld = false
				return
			end
			hopRecomputeHeld = false
			if not InLockdown() then
				Recompute()
			end
		end
		local function QueueRecompute()
			if recomputeQueued or InLockdown() then
				return
			end
			local R = Flux.Range
			if R and R.IsHopBurst and R.IsHopBurst() then
				hopRecomputeHeld = true
				if hopRecomputeArmed then
					return
				end
				hopRecomputeArmed = true
				local function fire()
					if R.IsHopBurst and R.IsHopBurst() then
						After(0.2, fire)
						return
					end
					FlushHopRecompute()
				end
				After(0.2, fire)
				return
			end
			recomputeQueued = true
			After(0, function()
				recomputeQueued = false
				if not InLockdown() then
					Recompute()
				end
			end)
		end
		Ev.Register("ACTIONBAR_SLOT_CHANGED", QueueRecompute)
		Ev.Register("UPDATE_MACROS", function()
			if not InLockdown() then
				Recompute()
			end
		end)
		Ev.Register("ADDON_LOADED", function(_, name)
			if name == "Blizzard_PlayerSpells" then
				After(0, BindSpellBookUI)
			end
		end)
	end
	MouseoverCast.Apply()
	BindSpellBookUI()
end
