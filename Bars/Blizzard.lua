-- Bars/Blizzard.lua — hide bars Flux does not use, strip MainActionBar art,
-- and suppress stock ActionButton1-12 (Flux hosts own the clicks).
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Blizzard = {}
Bars.Blizzard = Blizzard

local MULTI_BARS = {
	"MultiBarBottomLeft",
	"MultiBarBottomRight",
	"MultiBarLeft",
	"MultiBarRight",
	"MultiBar5",
	"MultiBar6",
	"MultiBar7",
	"MultiCastActionBarFrame",
	"MainMenuBarArtFrame",
	"ActionBarParent",
	"PetActionBar",
	"PetActionBarFrame",
	"StanceBar",
	"StanceBarFrame",
	"PossessBarFrame",
	"PossessActionBar",
}

local MAIN_BAR_ART = {
	"EndCaps",
	"ActionBarPageNumber",
	"BorderArt",
	"Border",
	"Background",
	"Selection",
	"QuickKeybindBottomShadow",
	"QuickKeybindRightShadow",
	"QuickKeybindGlowLarge",
	"QuickKeybindGlowSmall",
}

-- Never Hide() MainActionBar: Hide taints shown-state. Post-DF leftover chrome
-- at alpha 0 still ate clicks (enableMouse, frameLevel 50 above Flux level 5).
-- Collapse that hit rect / propagate clicks; never EnableMouse the pager.
-- Never SetParent unused Blizzard action bars onto an addon frame. That taints
-- their shown-state; StanceBar:Update then hits ADDON_ACTION_BLOCKED on
-- StanceButton1:SetShown() in combat (same for pet / multi / possess buttons).
-- Classic/anniversary StanceBar is the exception: ParkStockStanceBar parents
-- it to FluxStanceHider so ActionBarController Show cannot flash the stock bar.
-- Never EnableMouse unused-bar SecureFrame buttons (StanceButton1, pet, possess,
-- MultiBar). KillMouse out of combat taints shown-state; combat
-- UpdateShownButtons then blocks StanceButton1:SetShown().
-- Never ClearAllPoints/SetPoint unused EditMode bars: that also taints
-- StanceButton1, and UPDATE_SHAPESHIFT_COOLDOWN then spam-blocks SetShown.
-- Never EnableMouse leftover ActionButton1-12 before dropping them off
-- ActionBarButtonEventsFrame: EnableMouse taints the secure button; combat
-- Update() then hits ADDON_ACTION_BLOCKED on ActionButton8:SetAttribute()
-- (pressAndHoldAction). SilenceStockButton runs first everywhere.
-- Never replace Show/Hide/SetShown/UpdateState/UpdateShownButtons on
-- StanceBar or PossessActionBar: ActionBarController_UpdateAll calls their
-- Update() before MainActionBar:SetAttribute("actionpage"). A Flux Noop
-- there taints the rest of UpdateAll (combat form ADDON_ACTION_BLOCKED).
-- Never insecurely SetAlpha those bars either: object taint survives to the next
-- UpdateAll → StanceBar:SetShown → EditMode RightManagedFrameContainer:SetSize.
local MAIN_BARS = {
	"MainActionBar",
	"MainMenuBar",
}

local hider
local skinRecords = setmetatable({}, { __mode = "k" })

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function CanReplaceBar(name)
	if Bars.secureReady == false then return false end
	if name == "PetActionBar" or name == "PetActionBarFrame" or name == "ActionBarParent" then
		if Bars.Pet and Bars.Pet.secureReady == false then return false end
	end
	if name == "StanceBar" or name == "StanceBarFrame" or name == "MultiCastActionBarFrame" or name == "ActionBarParent" then
		if Bars.Stance and Bars.Stance.secureReady == false then return false end
	end
	return true
end

local STOCK_GRID_EVENTS = {
	ACTIONBAR_SHOWGRID = true,
	ACTIONBAR_HIDEGRID = true,
	PET_BAR_SHOWGRID = true,
	PET_BAR_HIDEGRID = true,
}
local STOCK_GRID_EVENT_FIELDS = { "showGridEventName", "hideGridEventName" }

local function SilenceStockGridEvents(bar)
	if type(bar) ~= "table" or type(bar.UnregisterEvent) ~= "function" then
		return
	end
	for i = 1, #STOCK_GRID_EVENT_FIELDS do
		local event = bar[STOCK_GRID_EVENT_FIELDS[i]]
		if STOCK_GRID_EVENTS[event] and (not bar.IsEventRegistered or bar:IsEventRegistered(event)) then
			bar:UnregisterEvent(event)
		end
	end
end

-- Alpha-hidden bars still receive bag-pickup grid events: SetShowGrid calls
-- UpdateVisibility -> Edit Mode -> RightManagedFrameContainer:SetSize in combat.
-- Flux has its own grid listeners. Detach only the stock bars' configured grid
-- pair before neutralizing them; retain all native controller/paging events.
-- This is independent of SilenceUnusedBar's one-time visibility-event flag so
-- MainActionBar, aliases, late frames and re-registered events are covered too.
local function SuppressStockGridEvents()
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.stockgrid", SuppressStockGridEvents)
		end
		return
	end
	for i = 1, #MAIN_BARS do
		SilenceStockGridEvents(_G[MAIN_BARS[i]])
	end
	for i = 1, #MULTI_BARS do
		if CanReplaceBar(MULTI_BARS[i]) then SilenceStockGridEvents(_G[MULTI_BARS[i]]) end
	end
end

function Blizzard.GetHider()
	if hider then
		return hider
	end
	hider = CreateFrame("Frame", "FluxBarsHider", UIParent)
	hider:Hide()
	hider:SetSize(1, 1)
	hider:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -9000, -9000)
	return hider
end

function Blizzard.GetActionButton(index)
	return _G["ActionButton" .. index]
end

local function HideTexture(obj)
	if type(obj) ~= "table" or not obj.Hide then
		return
	end
	pcall(obj.Hide, obj)
end

local function KillMouse(frame)
	-- EnableMouse on MainActionBar/MainMenuBar taints the pager. Combat form
	-- then ADDON_ACTION_BLOCKED ActionBarController_ResetToDefault →
	-- MainActionBar:SetAttribute(). Alpha-hide those bars; never EnableMouse.
	if InLockdown() then
		return
	end
	if frame == _G.MainActionBar or frame == _G.MainMenuBar then
		return
	end
	if type(frame) ~= "table" or type(frame.EnableMouse) ~= "function" then
		return
	end
	if frame.IsProtected and frame:IsProtected() then
		-- Leave stock protected state native: its next SetShown/SetAttribute
		-- runs inside ActionBarController_UpdateAll during possession changes.
		if frame.SetPropagateMouseClicks then frame:SetPropagateMouseClicks(true) end
		if frame.SetPropagateMouseMotion then frame:SetPropagateMouseMotion(true) end
		if frame.SetHitRectInsets then frame:SetHitRectInsets(10000, 10000, 10000, 10000) end
		return
	end
	frame:EnableMouse(false)
	if frame.EnableMouseClicks then
		frame:EnableMouseClicks(false)
	end
	if frame.EnableMouseMotion then
		frame:EnableMouseMotion(false)
	end
end

local function KillPagerMouse(bar)
	local pager = bar and bar.ActionBarPageNumber
	if not pager then
		return
	end
	KillMouse(pager)
	KillMouse(pager.UpButton)
	KillMouse(pager.DownButton)
	if type(pager.GetNumChildren) == "function" then
		local n = pager:GetNumChildren() or 0
		for i = 1, n do
			KillMouse(select(i, pager:GetChildren()))
		end
	end
end

local function IsRetailPostDF()
	local C = Flux.Client
	return C and C.isRetail and C.isPostDF and true or false
end

-- Post-DF MainActionBar is enableMouse=true at frameLevel 50. EnableMouse on
-- that frame taints ActionBarController_ResetToDefault → SetAttribute. Empty the
-- hit rect and pass clicks through instead so Flux (MEDIUM level 5) receives them.
local function PassThroughClicks(frame)
	if not IsRetailPostDF() or InLockdown() then
		return
	end
	if type(frame) ~= "table" then
		return
	end
	if frame.SetPropagateMouseClicks then
		pcall(frame.SetPropagateMouseClicks, frame, true)
	end
	if frame.SetPropagateMouseMotion then
		pcall(frame.SetPropagateMouseMotion, frame, true)
	end
	if frame.SetHitRectInsets then
		pcall(frame.SetHitRectInsets, frame, 10000, 10000, 10000, 10000)
	end
end

-- EditMode Selection is ignoreParentAlpha + enableMouse at frameLevel 1000, so
-- SetAlpha(0) on MainActionBar does not hide it and it still eats clicks.
local function NeutralizeEditModeSelection(bar)
	local sel = bar and bar.Selection
	if type(sel) ~= "table" then
		return
	end
	HideTexture(sel)
	if sel.SetIgnoreParentAlpha then
		pcall(sel.SetIgnoreParentAlpha, sel, false)
	end
	if sel.SetAlpha then
		sel:SetAlpha(0)
	end
	KillMouse(sel)
end

local function NeutralizeDividerPool(pool)
	if type(pool) ~= "table" or type(pool.EnumerateActive) ~= "function" then
		return
	end
	local ok, iter, state, first = pcall(pool.EnumerateActive, pool)
	if not ok or type(iter) ~= "function" then
		return
	end
	for divider in iter, state, first do
		HideTexture(divider)
		KillMouse(divider)
	end
end

-- Post-DF SpellFX / assisted overlay / leave button live on leftover chrome.
-- Containers are regular Frames, not unused-bar SecureActionButtons.
local STOCK_FX = {
	"InterruptDisplay",
	"SpellCastAnimFrame",
	"TargetReticleAnimFrame",
	"CooldownFlash",
	"SpellActivationAlert",
	"AssistedCombatRotationFrame",
}

local function NeutralizeStockFx(btn)
	if type(btn) ~= "table" then
		return
	end
	for i = 1, #STOCK_FX do
		HideTexture(btn[STOCK_FX[i]])
	end
end

local function NeutralizeIconIntro()
	if not IsRetailPostDF() then
		return
	end
	local tracker = _G.IconIntroTracker
	if type(tracker) ~= "table" then
		return
	end
	if tracker.UnregisterEvent then
		pcall(tracker.UnregisterEvent, tracker, "SPELL_PUSHED_TO_ACTIONBAR")
		pcall(tracker.UnregisterEvent, tracker, "SPELL_PUSHED_TO_FLYOUT_ON_ACTIONBAR")
	end
	if tracker.ResetAll then
		pcall(tracker.ResetAll, tracker)
	end
	HideTexture(tracker)
	KillMouse(tracker)
end

local function AlphaHide(frame)
	if type(frame) ~= "table" then
		return
	end
	if frame.SetAlpha then
		frame:SetAlpha(0)
	end
	KillMouse(frame)
end

local function StripMainBarArt()
	for b = 1, #MAIN_BARS do
		local bar = _G[MAIN_BARS[b]]
		if bar then
			for i = 1, #MAIN_BAR_ART do
				HideTexture(bar[MAIN_BAR_ART[i]])
			end
		end
	end
	HideTexture(_G.MainMenuBarLeftEndCap)
	HideTexture(_G.MainMenuBarRightEndCap)
end

local function UnusedHider()
	return hider or _G.FluxBarsHider
end

-- UpdateAll: PossessActionBar:Update() then StanceBar:Update() then
-- MainActionBar:SetAttribute. Do not insecurely SetAlpha those bars: object taint
-- survives to StanceBar:SetShown → EditMode RightManagedFrameContainer:SetSize.
-- Leave every mixin method stock. Replaced stance buttons use restricted
-- handlers; legacy clients retain their capability-gated hidden parent.
local function IsControllerUpdateBar(bar)
	return bar == _G.StanceBar
		or bar == _G.PossessActionBar
		or bar == _G.StanceBarFrame
		or bar == _G.PossessBarFrame
end

-- Out of combat only. Restores bars parked by older Flux builds so Blizzard
-- owns shown-state again. This session may still need /reload if taint stuck.
-- Never unpark StanceBar / PossessActionBar: HideUnusedBars would put them
-- back on UIParent and the stock stance bar would flash on every leftover.
local function UnparkIfNeeded(frame)
	if InLockdown() then
		return
	end
	if IsControllerUpdateBar(frame) then
		return
	end
	local parked = UnusedHider()
	if type(frame) ~= "table" or not parked or not frame.GetParent then
		return
	end
	if frame:GetParent() ~= parked then
		return
	end
	if frame.SetParent then
		pcall(frame.SetParent, frame, UIParent)
	end
end

-- Do not KillMouse / EnableMouse / SetPoint / SetParent unused bars.
-- Do not Hide leftover Multi/Pet bars (PetActionBar:SetShownBase taint).
-- Do not replace UpdateVisibility / HideOverride / Hide / Show / SetShown:
-- UpdateActionBarLayout invokes those on leftover Multi/Pet bars during
-- StanceBar:Update → RightManagedFrameContainer:SetSize. SetAlpha only.

local UNUSED_VISIBILITY_EVENTS = {
	"UPDATE_SHAPESHIFT_COOLDOWN",
	"PLAYER_REGEN_ENABLED",
	"PLAYER_REGEN_DISABLED",
	"PET_BAR_UPDATE",
	"PET_BAR_UPDATE_USABLE",
	"PET_UI_UPDATE",
	"UNIT_PET",
	"UNIT_FLAGS",
	"UNIT_AURA",
	"PLAYER_CONTROL_LOST",
	"PLAYER_CONTROL_GAINED",
	"PLAYER_FARSIGHT_FOCUS_CHANGED",
	"PLAYER_TARGET_CHANGED",
	"PLAYER_MOUNT_DISPLAY_CHANGED",
	"UPDATE_VEHICLE_ACTIONBAR",
	"UPDATE_SHAPESHIFT_FORM",
	"UPDATE_SHAPESHIFT_FORMS",
	"UPDATE_SHAPESHIFT_USABLE",
	"UPDATE_POSSESS_BAR",
}

local function SilenceUnusedBar(bar)
	if type(bar) ~= "table" or bar._fluxUnusedSilenced then
		return
	end
	if IsControllerUpdateBar(bar) then
		return
	end
	bar._fluxUnusedSilenced = true
	if bar.UnregisterEvent then
		for i = 1, #UNUSED_VISIBILITY_EVENTS do
			pcall(bar.UnregisterEvent, bar, UNUSED_VISIBILITY_EVENTS[i])
		end
	end
end

local function ParkUnusedBar(bar)
	if type(bar) ~= "table" then
		return
	end
	if IsControllerUpdateBar(bar) then
		return
	end
	SilenceUnusedBar(bar)
	if bar.SetAlpha then
		bar:SetAlpha(0)
	end
end

local function AlphaUnusedBars()
	for i = 1, #MULTI_BARS do
		if CanReplaceBar(MULTI_BARS[i]) then ParkUnusedBar(_G[MULTI_BARS[i]]) end
	end
end

-- Flux owns stance/form. A native "visibility" driver calls bar:Hide() every
-- 0.2s, including while already hidden. On Retail that is HideOverride, which
-- enters Edit Mode layout and the protected RightManagedFrameContainer:SetSize.
-- Use restricted frame-handle methods instead: they call the captured C widget
-- methods, bypassing HideOverride. Protected stance buttons
-- notify us when their parent becomes visible; the parent's own OnShow cannot
-- be used because the Edit Mode bar is not explicitly protected.
-- Hide each replaced stance button itself. Native Update() can show the bar again after
-- UpdateShownButtons(), with no second child OnShow when that child was left
-- shown. Suppressing only the parent therefore permits form-change flicker.
-- Do not hide that parent inside its button OnShow: Update's trailing SetShown
-- can reenter the parent's OnShow/Update. Securely mute its art/input instead.
-- Classic/early Forever retain hidden parenting. Repaired Forever builds use
-- the same secure hide, preserving the native Edit Mode bar's parent.
local STOCK_STANCE_BARS = {
	"StanceBar",
	"StanceBarFrame",
}

local STOCK_STANCE_ART = {
	"BackgroundArtLeft",
	"BackgroundArtMiddle",
	"BackgroundArtRight",
}

local stanceHider
local retailStanceRecords = setmetatable({}, { __mode = "k" })
local STANCE_SHOW_PRE = [[ return nil, true ]]
local STANCE_SHOW_POST = [[
    local bar = control:GetFrameRef("bar")
    if bar then
        if not control:GetAttribute("preserve-possess") then
            self:Hide(true)
            bar:SetAlpha(0)
            bar:EnableMouse(false)
        elseif not SecureCmdOptionParse("[possessbar] 1") then
            bar:Hide(true)
        end
    end
]]
local STANCE_INITIAL_HIDE = [[
    local bar = self:GetFrameRef("bar")
    if bar and not (self:GetAttribute("preserve-possess") and SecureCmdOptionParse("[possessbar] 1")) then
        if not self:GetAttribute("preserve-possess") then
            bar:SetAlpha(0)
            bar:EnableMouse(false)
        end
        bar:Hide(true)
    end
]]

local function SecureHideRetailStanceBar(bar, preservePossess)
	if InLockdown() then return "pending" end
	local record = retailStanceRecords[bar]
	if not record then
		local ok, header = pcall(CreateFrame, "Frame", nil, UIParent, "SecureHandlerBaseTemplate")
		if not ok or not header then return "failed" end
		-- All methods here belong to the Flux-owned header, never the stock bar.
		header:Hide()
		if not header.SetFrameRef or not header.WrapScript or not header.Execute then return "failed" end
		if not pcall(header.SetFrameRef, header, "bar", bar) then return "failed" end
		header:SetAttribute("preserve-possess", preservePossess and true or nil)
		record = { header = header, buttons = setmetatable({}, { __mode = "k" }) }
		retailStanceRecords[bar] = record
	end
	local found, failed = false, false
	local buttons = bar.actionButtons
	if not buttons and bar == _G.PossessBarFrame then
		buttons = { _G.PossessButton1, _G.PossessButton2 }
	end
	for _, button in ipairs(buttons or {}) do
		-- SecureHandlers needs an explicitly protected self handle. Blizzard's
		-- StanceButtonTemplate inherits SecureFrameTemplate; its parent does not.
		local explicit = button.IsProtected and select(2, button:IsProtected())
		if explicit and not (button.IsForbidden and button:IsForbidden()) then
			found = true
			if not record.buttons[button] then
				local ok = pcall(record.header.WrapScript, record.header, button, "OnShow", STANCE_SHOW_PRE, STANCE_SHOW_POST)
				if ok then record.buttons[button] = true else failed = true end
			end
		end
	end
	if not pcall(record.header.Execute, record.header, STANCE_INITIAL_HIDE) then return "failed" end
	if failed then return "failed" end
	return found and "secured" or "pending"
end

local function IsClassicFamily()
	local C = Flux.Client
	return C and C.isAnyClassic and true or false
end

-- Forever cannot RegisterStateDriver without tainting SecureStateDriverManager.
local function UseStanceHider()
	if IsClassicFamily() then
		return true
	end
	local C = Flux.Client
	if C and (C.isCamelot or C.isForever) then
		local R = Flux.Restricted
		return not (R and R.PagingWorks and R.PagingWorks())
	end
	local Restricted = Flux.Restricted
	if Restricted and Restricted.Works and not Restricted.Works() then
		return true
	end
	return false
end

local function GetStanceHider()
	if stanceHider then
		return stanceHider
	end
	stanceHider = CreateFrame("Frame", "FluxStanceHider", UIParent)
	stanceHider:Hide()
	stanceHider:SetSize(1, 1)
	stanceHider:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -9000, -9000)
	return stanceHider
end

-- SetParent only. No Hide / SetAlpha / SetPoint on the bar.
local function ParkStockStanceBar(bar)
	if not UseStanceHider() or InLockdown() then
		return
	end
	if type(bar) ~= "table" or type(bar.SetParent) ~= "function" then
		return
	end
	local parent = GetStanceHider()
	if bar.GetParent and bar:GetParent() == parent then
		return
	end
	pcall(bar.SetParent, bar, parent)
end

-- Texture Hide is undone by classic SetBackgroundArtShown on ManageFramePositions.
-- SetAlpha(0) survives SetShown(true), so the wood bar cannot flash.
local function HideClassicStanceArt(bar)
	if type(bar) ~= "table" then
		return
	end
	for i = 1, #STOCK_STANCE_ART do
		local tex = bar[STOCK_STANCE_ART[i]]
		if type(tex) == "table" then
			if tex.SetAlpha then
				pcall(tex.SetAlpha, tex, 0)
			end
			if tex.SetIgnoreParentAlpha then
				pcall(tex.SetIgnoreParentAlpha, tex, false)
			end
			if tex.Hide then
				pcall(tex.Hide, tex)
			end
		end
	end
end

local function HideStockStanceBars()
	if not CanReplaceBar("StanceBar") then return end
	local locked = InLockdown()
	for i = 1, #STOCK_STANCE_BARS do
		local bar = _G[STOCK_STANCE_BARS[i]]
		if type(bar) == "table" then
			-- Never install secure handlers in combat (SecureHandlersUpdateFrame:SetAttribute).
			if not locked and not UseStanceHider() then
				SecureHideRetailStanceBar(bar)
			end
			ParkStockStanceBar(bar)
			HideClassicStanceArt(bar)
		end
	end
	if locked and Flux.Combat and Flux.Combat.Defer then
		Flux.Combat.Defer("bars.stance.hide", HideStockStanceBars)
	end
end

local function HideStockPossessBars()
	if not CanReplaceBar("PossessActionBar") then return end
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.possess.hide", HideStockPossessBars)
		end
		return
	end
	local restricted = Flux.Restricted
	if restricted and restricted.PagingWorks and not restricted.PagingWorks() then return end
	-- Never retire the real cancel-possession/taxi controls. Only the empty
	-- Edit Mode presentation is suppressed; native Update/OnClick stay intact.
	for _, name in ipairs({ "PossessActionBar", "PossessBarFrame" }) do
		local bar = _G[name]
		if type(bar) == "table" then SecureHideRetailStanceBar(bar, true) end
	end
end

local function NeutralizePostDFBarChrome(bar)
	if not IsRetailPostDF() or type(bar) ~= "table" then
		return
	end
	NeutralizeEditModeSelection(bar)
	if IsControllerUpdateBar(bar) then
		return
	end
	KillMouse(bar.EndCaps)
	KillMouse(bar.VehicleLeaveButton)
	NeutralizeDividerPool(bar.HorizontalDividersPool)
	NeutralizeDividerPool(bar.VerticalDividersPool)
	local buttons = bar.actionButtons
	if type(buttons) ~= "table" then
		return
	end
	for i = 1, #buttons do
		local btn = buttons[i]
		if btn then
			KillMouse(btn.container)
			NeutralizeStockFx(btn)
		end
	end
end

-- A post-hook on leftover MainActionBar Show runs in the middle of
-- ActionBarController_UpdateAll. Anything we call there taints the rest of
-- ValidateActionBarTransition (EnableMouse, later SetShownBase). Re-kill mouse
-- only after UpdateAll returns, on a deferred tick.
-- Never hooksecurefunc ActionBarController_UpdateAll: the hook taints the
-- caller, and vehicle enter then hits RightManagedFrameContainer:SetSize in
-- UIParent_ManageFramePositions. Queue leftover from our own frame on PEW,
-- regen, shapeshift, possess, bonus/vehicle/override, page, pet-battle close.
-- Leftover pass is alpha / collector vacuum + secure stance suppression:
-- no native Lua Show/Hide or SetPoint; no objective-tracker calls.
local leftoverQueued = false

local function ApplyLeftoverNow()
	leftoverQueued = false
	if Bars.secureReady == false then return end
	if FluxEditModeBusy and FluxEditModeBusy() then
		FluxAfterEditMode(ApplyLeftoverNow, "bars.leftover")
		return
	end
	SuppressStockGridEvents()
	for i = 1, #MAIN_BARS do
		local bar = _G[MAIN_BARS[i]]
		if type(bar) == "table" and bar.SetAlpha then
			bar:SetAlpha(0)
		end
	end
	AlphaUnusedBars()
	HideStockStanceBars()
	HideStockPossessBars()
	if InLockdown() then
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.leftover", Blizzard.KillLeftoverMouse)
		end
		return
	end
	Blizzard.KillLeftoverMouse()
end

function Blizzard.QueueLeftoverMouse()
	if leftoverQueued then
		return
	end
	leftoverQueued = true
	if Flux.Timer and Flux.Timer.Defer then
		Flux.Timer.Defer(ApplyLeftoverNow)
	elseif C_Timer and C_Timer.After then
		C_Timer.After(0, ApplyLeftoverNow)
	else
		ApplyLeftoverNow()
	end
end

local leftoverWatch

-- Same events ActionBarController uses to StanceBar:Update / Show. Our frame
-- only queues leftover (next tick), so we never run inside UpdateAll.
local STOCK_STANCE_LEFTOVER_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"PLAYER_REGEN_ENABLED",
	"UPDATE_SHAPESHIFT_FORM",
	"UPDATE_SHAPESHIFT_FORMS",
	"UPDATE_SHAPESHIFT_USABLE",
	"UPDATE_POSSESS_BAR",
	"UPDATE_BONUS_ACTIONBAR",
	"UPDATE_VEHICLE_ACTIONBAR",
	"UPDATE_OVERRIDE_ACTIONBAR",
	"ACTIONBAR_PAGE_CHANGED",
	"PET_BATTLE_CLOSE",
}

local function WatchLeftoverEvents()
	if leftoverWatch then
		return
	end
	leftoverWatch = CreateFrame("Frame")
	for i = 1, #STOCK_STANCE_LEFTOVER_EVENTS do
		leftoverWatch:RegisterEvent(STOCK_STANCE_LEFTOVER_EVENTS[i])
	end
	leftoverWatch:RegisterEvent("ADDON_LOADED")
	if IsRetailPostDF() then
		pcall(leftoverWatch.RegisterEvent, leftoverWatch, "ACTIONBAR_SHOW_BOTTOMLEFT")
		if EventRegistry and EventRegistry.RegisterCallback then
			EventRegistry:RegisterCallback("EditMode.Exit", Blizzard.QueueLeftoverMouse)
		end
	end
	leftoverWatch:SetScript("OnEvent", function(_, event, name)
		if event == "ADDON_LOADED" and name ~= "Blizzard_ActionBar" then return end
		Blizzard.QueueLeftoverMouse()
	end)
end

local function NeutralizeMainBar(bar)
	if type(bar) ~= "table" then
		return
	end
	if bar.SetAlpha then
		bar:SetAlpha(0)
	end
	PassThroughClicks(bar)
	KillPagerMouse(bar)
	NeutralizeEditModeSelection(bar)
	NeutralizePostDFBarChrome(bar)
end

-- Flux hosts own the clicks; leftover ActionButton1-12 only need to stop
-- updating. Never assign Noop over their Update / UpdateAction /
-- UpdatePressAndHoldAction: those buttons stay on Blizzard's shared
-- ActionBarButtonEventsFrame, whose OnEvent walks pairs(self.frames) and calls
-- frame:OnEvent on each. A Flux function reached from that loop taints the rest
-- of it, so the next protected button — OverrideActionBarButton2 — blocks on
-- Update → UpdatePressAndHoldAction → SetAttribute in combat.
--
-- Drop the entry instead and leave every mixin method stock. Only
-- ActionBarButtonEventsFrame: RegisterFrame there runs once from OnLoad, so the
-- detach sticks. ActionBarActionEventsFrame / ActionBarButtonUpdateFrame keep
-- Blizzard's own eventsRegistered bookkeeping — pulling those desyncs it, and
-- pure Blizzard code on an alpha-0 button cannot taint anything.
local function SharesGamepadCollector()
	local C = Flux.Client
	return C and (C.isCamelot or C.isForever) and true or false
end

local function SilenceStockButton(btn)
	if type(btn) ~= "table" then
		return
	end
	-- Gamepad buttons share ActionBarButtonEventsFrame. Niling stock buttons
	-- taints that list and blocks UseAction on mouse and gamepad clicks.
	if SharesGamepadCollector() then
		return
	end
	local collector = _G.ActionBarButtonEventsFrame
	if not collector or type(collector.frames) ~= "table" then
		return -- retry on the next leftover pass
	end
	-- Always nil. ActionBarController_UpdateAll can tinsert leftover
	-- ActionButton1-12 again; skipping after _fluxStockSilenced leaves them
	-- on the collector so EnableMouse taint reaches OverrideActionBar SetAttribute.
	if Flux.Action and Flux.Action.NilFromCollector then
		Flux.Action.NilFromCollector(collector, btn)
	end
	btn._fluxStockSilenced = true
end

-- Possess / MultiBar leftovers leave the collector. OverrideActionBarButtonN
-- stay registered: Blizzard's vehicle UI needs them, and Vehicle.lua combat-gates
-- ACTIONBAR_SLOT_CHANGED so their Update → SetAttribute does not run tainted.
-- Mixin methods stay stock. Never EnableMouse these buttons.
local MULTIBAR_BUTTON_PREFIXES = {
	"MultiBarBottomLeftButton",
	"MultiBarBottomRightButton",
	"MultiBarRightButton",
	"MultiBarLeftButton",
	"MultiBar5Button",
	"MultiBar6Button",
	"MultiBar7Button",
}

local function SilenceProtectedLeftovers()
	for i = 1, 2 do
		SilenceStockButton(_G["PossessButton" .. i])
	end
	for p = 1, #MULTIBAR_BUTTON_PREFIXES do
		local prefix = MULTIBAR_BUTTON_PREFIXES[p]
		for i = 1, Bars.NUM_NATIVE do
			SilenceStockButton(_G[prefix .. i])
		end
	end
end

-- Alpha and mouse only. Do not Hide leftover stock buttons or strip their events.
local function NeutralizeStockButton(btn)
	if type(btn) ~= "table" then
		return
	end
	AlphaHide(btn)
	AlphaHide(btn.container)
	NeutralizeStockFx(btn)
end

local function NeutralizeUnusedBar(bar)
	ParkUnusedBar(bar)
end

function Blizzard.HideStockButtons()
	if Bars.secureReady == false then return end
	if FluxEditModeBusy and FluxEditModeBusy() then
		FluxAfterEditMode(Blizzard.HideStockButtons)
		return
	end
	for i = 1, Bars.NUM_NATIVE do
		SilenceStockButton(Blizzard.GetActionButton(i))
		NeutralizeStockButton(Blizzard.GetActionButton(i))
		AlphaHide(_G["MainActionBarButtonContainer" .. i])
	end
	SilenceProtectedLeftovers()
end

function Blizzard.KillLeftoverMouse()
	if Bars.secureReady == false then return end
	if FluxEditModeBusy and FluxEditModeBusy() then
		FluxAfterEditMode(Blizzard.KillLeftoverMouse)
		return
	end
	SuppressStockGridEvents()
	for i = 1, #MAIN_BARS do
		NeutralizeMainBar(_G[MAIN_BARS[i]])
	end
	KillPagerMouse(_G.MainActionBar)
	KillPagerMouse(_G.MainMenuBar)
	-- Drop leftover ActionButton1-12, Possess/MultiBar, AND Flux hosts off
	-- the collector before any EnableMouse. OverrideActionBarButtonN stay on
	-- it (Blizzard vehicle UI). EnableMouse on a button still in frames taints
	-- the pairs(OnEvent) loop. Sweep writes frames: OOC only.
	for i = 1, Bars.NUM_NATIVE do
		SilenceStockButton(Blizzard.GetActionButton(i))
	end
	SilenceProtectedLeftovers()
	if not SharesGamepadCollector() and not InLockdown() and Flux.Action and Flux.Action.SweepFluxFromCollectors then
		Flux.Action.SweepFluxFromCollectors()
	end
	for i = 1, Bars.NUM_NATIVE do
		-- EnableMouse on a button that stays in frames taints the collector OnEvent.
		if not SharesGamepadCollector() then
			KillMouse(Blizzard.GetActionButton(i))
		end
		KillMouse(_G["MainActionBarButtonContainer" .. i])
	end
	for i = 1, #MULTI_BARS do
		if CanReplaceBar(MULTI_BARS[i]) then
			NeutralizeUnusedBar(_G[MULTI_BARS[i]])
			NeutralizePostDFBarChrome(_G[MULTI_BARS[i]])
		end
	end
	KillMouse(_G.MainMenuBarVehicleLeaveButton)
	NeutralizeIconIntro()
	HideStockStanceBars()
	HideStockPossessBars()
end

function Blizzard.HideUnusedBars()
	-- Do not take native input away until all replacement surfaces and their
	-- paging/input setup completed. Failed or combat-blocked startup keeps it.
	if Bars.secureReady == false then return end
	if FluxEditModeBusy and FluxEditModeBusy() then
		FluxAfterEditMode(Blizzard.HideUnusedBars)
		return
	end
	SuppressStockGridEvents()
	if not InLockdown() then
		for i = 1, #MULTI_BARS do
			if CanReplaceBar(MULTI_BARS[i]) then UnparkIfNeeded(_G[MULTI_BARS[i]]) end
		end
	end
	Blizzard.KillLeftoverMouse()
	if InLockdown() then
		return
	end
	StripMainBarArt()
	Blizzard.HideStockButtons()
end

-- ---------------------------------------------------------------------------
-- Skin: empty backpack slot. Ring size is Style.SizeRing (SizeRing owns client scale).
-- Do not enlarge the ring after SizeRing — that oversizes the chrome.
-- ---------------------------------------------------------------------------

local EMPTY_SLOT = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"

local function ThemedRGB()
	if FluxBorder and FluxBorder.GetThemedVertexRGB then
		return FluxBorder:GetThemedVertexRGB()
	end
	local _, classFilename = UnitClass("player")
	local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename]
	if c then
		return c.r, c.g, c.b
	end
	return 0.6, 0.6, 0.6
end

local function EnsureEmptySlot(widget)
	local bg = widget.BackgroundTexture
	if not bg then
		bg = widget:CreateTexture(nil, "BACKGROUND", nil, -2)
		widget.BackgroundTexture = bg
		bg:SetTexture(EMPTY_SLOT)
		bg:SetTexCoord(0, 1, 0, 1)
	end
	local w = widget.GetWidth and widget:GetWidth() or 0
	local h = widget.GetHeight and widget:GetHeight() or 0
	if type(w) ~= "number" or w < 1 then
		w = Bars.CONFIG.buttonSize
	end
	if type(h) ~= "number" or h < 1 then
		h = Bars.CONFIG.buttonSize
	end
	bg:ClearAllPoints()
	bg:SetPoint("CENTER", widget, "CENTER", 0, 0)
	bg:SetSize(w, h)
	local r, g, b = ThemedRGB()
	bg:SetVertexColor(r, g, b, 1)
	bg:Show()
	return bg
end

local function ApplyChrome(widget)
	local EBS = Flux.EBS
	local record = skinRecords[widget]
	if not record then
		record = { Widget = widget, categoryScope = "character" }
		skinRecords[widget] = record
	end
	if widget.SlotArt then
		widget.SlotArt:Hide()
	end
	if widget.SlotBackground then
		widget.SlotBackground:Hide()
	end
	EnsureEmptySlot(widget)
	if EBS and EBS.Style and EBS.Style.SizeRing then
		EBS.Style.SizeRing(record)
	end
	local r, g, b = ThemedRGB()
	local tex = widget.NormalTexture
		or (widget.GetNormalTexture and widget:GetNormalTexture())
	if tex then
		tex:SetVertexColor(r, g, b, 1)
		tex:SetAlpha(1)
		tex:Show()
	end
	-- SizeRing hides the overlay when the C++ NormalTexture is the ring.
	-- Do not Show it again here (double chrome).
	local overlay = widget._fluxQuickslotRing
	if overlay and overlay.IsShown and overlay:IsShown() then
		overlay:SetVertexColor(r, g, b, 1)
	end
	if widget.BackgroundTexture then
		widget.BackgroundTexture:SetVertexColor(r, g, b, 1)
	end
end

local function HookButtonArt(widget)
	if widget._fluxArtHooked or not widget.UpdateButtonArt then
		return
	end
	widget._fluxArtHooked = true
	-- Instance wrap only. hooksecurefunc on a mixin method can wrap the shared
	-- function every stock button calls from Update().
	local orig = widget.UpdateButtonArt
	widget.UpdateButtonArt = function(self, ...)
		orig(self, ...)
		if self._fluxSkinning then
			return
		end
		self._fluxSkinning = true
		ApplyChrome(self)
		self._fluxSkinning = nil
	end
end

function Blizzard.SkinButton(widget)
	if not widget then
		return
	end
	if widget.SlotArt then
		widget.SlotArt:Hide()
	end
	if widget.SlotBackground then
		widget.SlotBackground:Hide()
	end
	HookButtonArt(widget)
	ApplyChrome(widget)
end

function Blizzard.Prepare()
	WatchLeftoverEvents()
	Blizzard.QueueLeftoverMouse()
	Blizzard.HideUnusedBars()
end

function Blizzard.Reassert()
	Blizzard.HideUnusedBars()
end

--- Drag grid only re-shows stock buttons. Hide them again without the collector
--- sweep, secure stance suppression, and art pass used by a real layout.
function Blizzard.QuietGrid()
	if Bars.secureReady == false then return end
	if FluxEditModeBusy and FluxEditModeBusy() then
		FluxAfterEditMode(Blizzard.QuietGrid)
		return
	end
	local function Dim(frame)
		if type(frame) == "table" and frame.GetAlpha and frame.SetAlpha and frame:GetAlpha() > 0 then
			frame:SetAlpha(0)
		end
	end
	for i = 1, Bars.NUM_NATIVE do
		Dim(Blizzard.GetActionButton(i))
		Dim(_G["MainActionBarButtonContainer" .. i])
	end
	for i = 1, #MULTI_BARS do
		local bar = _G[MULTI_BARS[i]]
		if CanReplaceBar(MULTI_BARS[i]) and bar ~= _G.StanceBar and bar ~= _G.PossessActionBar
			and bar ~= _G.StanceBarFrame and bar ~= _G.PossessBarFrame then
			Dim(bar)
		end
	end
end
