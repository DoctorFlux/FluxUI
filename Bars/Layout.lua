-- Bars/Layout.lua — pack-left, promotion, mini anchors. Combat-deferred Show/Hide/SetPoint.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Layout = {}
Bars.Layout = Layout

local MAIN_PAGES = { 7, 8, 9, 10, 11, 12, 13, 14 }

local lastHash
local appliedExpanding = false
local dragWatching = false
local dragAccum = 0
local started = false

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function SlotHasAction(slot)
	if not slot then
		return false
	end
	local occupied
	local A = Flux.Action
	if A and A.HasAction then
		occupied = A.HasAction(slot)
	elseif HasAction then
		occupied = HasAction(slot)
	end
	local S = Flux.Secrets
	if S and S.SafeBooleanTest then
		occupied = S.SafeBooleanTest(occupied, false)
	else
		occupied = occupied and true or false
	end
	if occupied then
		return true
	end
	-- Backup counted Binding overlay bodies as occupancy so SHIFT still swaps.
	local SP = Bars.SlotProgram
	if SP then
		local body = SP.Get and SP.Get(slot)
		if type(body) == "string" and body ~= "" then
			return true
		end
		if SP.GetIdle then
			local idle = SP.GetIdle(slot)
			if type(idle) == "string" and idle ~= "" then
				return true
			end
		end
	end
	return false
end

-- State.HostResolveOpts needs the same secret-safe, overlay-aware answer the
-- occupancy flags are stamped from, or the two slot picks disagree.
Layout.SlotHasAction = SlotHasAction

function Layout.HasContentInAnyState(column)
	if column > Bars.NUM_NATIVE then
		return SlotHasAction(column)
	end
	if SlotHasAction(column) then
		return true
	end
	for i = 1, #MAIN_PAGES do
		local page = MAIN_PAGES[i]
		if SlotHasAction((page - 1) * 12 + column) then
			return true
		end
	end
	return false
end

--- True when the currently visible main face has an action (this page only).
-- Expand placeholders use this so you can drop onto an empty form face.
-- Promotion does not: GetPromotedMode uses HasContentInAnyState.
function Layout.HasContentOnMain(column)
	local State = Bars.State
	if not State or not State.GetMainSlot then
		return Layout.HasContentInAnyState(column)
	end
	if column > Bars.NUM_NATIVE then
		return SlotHasAction(column)
	end
	local page = State.GetCurrentPage and State.GetCurrentPage() or 1
	return SlotHasAction(State.GetMainSlot(column, page))
end

function Layout.IsColumnEmpty(column)
	local State = Bars.State
	if Layout.HasContentInAnyState(column) then
		return false
	end
	if State and (SlotHasAction(State.GetSecondarySlot(column)) or SlotHasAction(State.GetTertiarySlot(column))) then
		return false
	end
	return true
end

--- nil | "sec" | "tert" | "both"
-- Promote only when this column has no main-row action on any stance/form/page
-- (same as backup HasContentInAnyState). An empty cat/bear face still does not
-- lift minis if caster or another form has a spell on that column. Pack-left
-- also uses any-state occupancy, so the column stays visible either way.
-- topleft → main, topright → centered leftover.
function Layout.GetPromotedMode(column)
	if Layout.HasContentInAnyState(column) then
		return nil
	end
	local State = Bars.State
	if not State then
		return nil
	end
	local hasSec = SlotHasAction(State.GetSecondarySlot(column))
	local hasTert = SlotHasAction(State.GetTertiarySlot(column))
	if hasSec and hasTert then
		return "both"
	end
	if hasSec then
		return "sec"
	end
	if hasTert then
		return "tert"
	end
	return nil
end

function Layout.IsExpanding()
	if Layout.bindingMode then
		return true
	end
	if not GetCursorInfo then
		return false
	end
	if not GetCursorInfo() then
		return false
	end
	local sensing = Bars.Strip and Bars.Strip.sensing
	if sensing and sensing.IsMouseOver and sensing:IsMouseOver() then
		return true
	end
	local frame = Bars.Strip and Bars.Strip.frame
	if frame and frame.IsMouseOver and frame:IsMouseOver() then
		return true
	end
	return false
end

function Layout.SetBindingMode(active)
	active = not not active
	if Layout.bindingMode == active then
		return
	end
	Layout.bindingMode = active
	if Bars.RequestLayout then
		Bars.RequestLayout("bindmode")
	end
end

function Layout.MiniAtBottom()
	return Bars.State and Bars.State.GetMinirowPosition and Bars.State.GetMinirowPosition() == "bottom"
end

-- ---------------------------------------------------------------------------
-- Promotion flags (OOC). Restricted ChildUpdate reads these to pick the slot.
-- ---------------------------------------------------------------------------

local stampedP, stampedS, stampedT = {}, {}, {}

function Layout.InvalidateMappings()
	for i = 1, Bars.NUM_COLUMNS do
		stampedP[i], stampedS[i], stampedT[i] = nil, nil, nil
	end
end

local function StampFlags(widget, promoted, hasSec, hasTert)
	if not widget then
		return
	end
	widget:SetAttribute("flux-promoted", promoted)
	widget:SetAttribute("flux-has-sec", hasSec)
	widget:SetAttribute("flux-has-tert", hasTert)
end

--- Stamp promotion flags, per column, only where they actually changed.
--
-- Occupancy is any-state, so shapeshift does not restamp 171 attributes or
-- ForceApply — the native driver already paged the hosts. Expand still
-- clears promotion so empty faces can take a drop.
--- OOC only: these are SetAttribute writes on protected frames, which insecure
--- Lua cannot do in combat. A fight entered before the first stamp would leave
--- flux-has-sec at 0, so CHILDUPDATE reads live minirow occupancy itself rather
--- than trusting these flags to be fresh.
function Layout.ApplyMappings()
	if InLockdown() then
		return
	end
	local State = Bars.State
	if not State then
		return
	end
	local expanding = Layout.IsExpanding()
	local changed = false

	for column = 1, Bars.NUM_COLUMNS do
		local hasSec = SlotHasAction(State.GetSecondarySlot(column))
		local hasTert = SlotHasAction(State.GetTertiarySlot(column))
		local p = 0
		if not expanding and not Layout.HasContentInAnyState(column) then
			if hasSec and hasTert then
				p = 3
			elseif hasSec then
				p = 1
			elseif hasTert then
				p = 2
			end
		end
		local s = (expanding or hasSec) and 1 or 0
		local t = (expanding or hasTert) and 1 or 0
		if stampedP[column] ~= p or stampedS[column] ~= s or stampedT[column] ~= t then
			stampedP[column], stampedS[column], stampedT[column] = p, s, t
			local col = Bars.hosts[column]
			if col then
				if col.main then
					col.main._fluxPromoted = (p ~= 0) and p or nil
				end
				StampFlags(col.main and col.main.widget, p, s, t)
				StampFlags(col.sec and col.sec.widget, p, s, t)
				StampFlags(col.tert and col.tert.widget, p, s, t)
			end
			-- New flags move the slot pick, so the guards that would skip the
			-- restamp have to go with them.
			if Bars.Watch and Bars.Watch.InvalidateColumnStamps then
				Bars.Watch.InvalidateColumnStamps(column)
			end
			changed = true
		end
	end

	if changed then
		if Flux.Perf then
			Flux.Perf.Count("bars.mapping.restamp")
		end
		if State.ForceApply then
			State.ForceApply()
		end
	end
	-- Forever: snippets never restamp action / shift-action*. Do this even when
	-- occupancy flags (and ForceApply) did not move.
	if State.ApplySlotsInsecure then
		local Restricted = Flux.Restricted
		if not (Restricted and Restricted.Works and Restricted.Works()) then
			State.ApplySlotsInsecure()
		end
	end
end

--- Combat-legal: alpha on already-shown hosts. Never unpack packed columns.
function Layout.RevealEmptyInCombat()
	if not InLockdown() then
		return
	end
	Bars.ForEachHost(function(host)
		local widget = host.widget
		if widget and widget.IsShown and widget:IsShown() then
			widget:SetAlpha(1)
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Mini anchors
-- ---------------------------------------------------------------------------

--- Park unused minis off-screen and keep them Shown. Hiding them drops
-- anchors and makes drag/pickup feel dead. Combat still must not
-- Show/Hide/SetPoint protected frames (ApplyVisual returns in lockdown).
local function ParkMini(widget)
	if not widget then
		return
	end
	widget:ClearAllPoints()
	local parent = widget.GetParent and widget:GetParent()
	if parent then
		widget:SetPoint("TOPLEFT", parent, "TOPLEFT", -9999, 9999)
	end
	widget._fluxParked = true
	if widget.Show then
		widget:Show()
	end
end

local function AnchorPair(secBtn, tertBtn, mainBtn, kind, miniAtBottom)
	if not secBtn or not tertBtn or not mainBtn then
		return
	end
	local function point(btn, ...)
		btn._fluxParked = nil
		btn:ClearAllPoints()
		btn:SetPoint(...)
	end
	if miniAtBottom then
		if kind == "promoted_both" then
			ParkMini(secBtn)
			point(tertBtn, "TOP", mainBtn, "BOTTOM", 0, 0)
		elseif kind == "expand_empty" then
			point(secBtn, "TOP", mainBtn, "BOTTOM", 0, 0)
			point(tertBtn, "TOPRIGHT", mainBtn, "BOTTOMRIGHT", 0, 0)
		elseif kind == "expand_corners" then
			point(secBtn, "TOPLEFT", mainBtn, "BOTTOMLEFT", 0, 0)
			point(tertBtn, "TOPRIGHT", mainBtn, "BOTTOMRIGHT", 0, 0)
		elseif kind == "only_sec" then
			point(secBtn, "TOP", mainBtn, "BOTTOM", 0, 0)
			ParkMini(tertBtn)
		elseif kind == "only_tert" then
			ParkMini(secBtn)
			point(tertBtn, "TOP", mainBtn, "BOTTOM", 0, 0)
		else
			point(secBtn, "TOPLEFT", mainBtn, "BOTTOMLEFT", 0, 0)
			point(tertBtn, "TOPRIGHT", mainBtn, "BOTTOMRIGHT", 0, 0)
		end
	else
		if kind == "promoted_both" then
			ParkMini(secBtn)
			point(tertBtn, "BOTTOM", mainBtn, "TOP", 0, 0)
		elseif kind == "expand_empty" then
			point(secBtn, "BOTTOM", mainBtn, "TOP", 0, 0)
			point(tertBtn, "BOTTOMRIGHT", mainBtn, "TOPRIGHT", 0, 0)
		elseif kind == "expand_corners" then
			point(secBtn, "BOTTOMLEFT", mainBtn, "TOPLEFT", 0, 0)
			point(tertBtn, "BOTTOMRIGHT", mainBtn, "TOPRIGHT", 0, 0)
		elseif kind == "only_sec" then
			point(secBtn, "BOTTOM", mainBtn, "TOP", 0, 0)
			ParkMini(tertBtn)
		elseif kind == "only_tert" then
			ParkMini(secBtn)
			point(tertBtn, "BOTTOM", mainBtn, "TOP", 0, 0)
		else
			point(secBtn, "BOTTOMLEFT", mainBtn, "TOPLEFT", 0, 0)
			point(tertBtn, "BOTTOMRIGHT", mainBtn, "TOPRIGHT", 0, 0)
		end
	end
end

local function AnyContent()
	for i = 1, Bars.NUM_COLUMNS do
		if not Layout.IsColumnEmpty(i) then
			return true
		end
	end
	return false
end

local function MiniShownForColumn(column, expanding, hasAny)
	local show = not Layout.IsColumnEmpty(column)
	if column == 1 and not hasAny then
		show = true
	end
	if expanding then
		show = true
	end
	if not show then
		return false, false
	end
	local promoted = (not expanding) and Layout.GetPromotedMode(column)
	if promoted == "sec" or promoted == "tert" then
		return false, false
	end
	local State = Bars.State
	local hasSec = State and SlotHasAction(State.GetSecondarySlot(column))
	local hasTert = State and SlotHasAction(State.GetTertiarySlot(column))
	local hasMain = Layout.HasContentOnMain(column)
	local secShow = hasSec
	local tertShow = hasTert
	if expanding then
		if hasMain then
			secShow = true
			if hasSec then
				tertShow = true
			end
		end
		if hasTert then
			secShow = true
		end
	end
	if promoted == "both" then
		return false, true
	end
	return secShow, tertShow
end

function Layout.AnyMiniVisible(expanding, hasAny)
	for i = 1, Bars.NUM_COLUMNS do
		local secShow, tertShow = MiniShownForColumn(i, expanding, hasAny)
		if secShow or tertShow then
			return true
		end
	end
	return false
end

function Layout.VisibleCount(expanding, hasAny)
	local n = 0
	for i = 1, Bars.NUM_COLUMNS do
		local show = not Layout.IsColumnEmpty(i)
		if i == 1 and not hasAny then
			show = true
		end
		if expanding then
			show = true
		end
		if show then
			n = n + 1
		end
	end
	if n < 1 then
		n = 1
	end
	return n
end

local function OccupancyHash(expanding, hasAny, bottom, minis, extraScale, xFactor, yOffset)
	local parts = {
		expanding and "E" or "-",
		hasAny and "C" or "e",
		bottom and "b" or "t",
		minis and "m" or "-",
		string.format("s%.3f", extraScale or 1),
		string.format("x%.3f", xFactor or 1),
		string.format("y%.1f", yOffset or 0),
	}
	for i = 1, Bars.NUM_COLUMNS do
		parts[#parts + 1] = Layout.IsColumnEmpty(i) and "0" or "1"
		-- Current-page main occupancy only changes expand placeholders. Including
		-- it at rest would reflow the strip on every shapeshift even when packing
		-- and promotion (any-state) did not move.
		if expanding then
			parts[#parts + 1] = Layout.HasContentOnMain(i) and "m" or "-"
		end
		local promoted = (not expanding) and Layout.GetPromotedMode(i)
		parts[#parts + 1] = promoted and promoted:sub(1, 1) or "-"
		local State = Bars.State
		if State then
			parts[#parts + 1] = SlotHasAction(State.GetSecondarySlot(i)) and "S" or "-"
			parts[#parts + 1] = SlotHasAction(State.GetTertiarySlot(i)) and "T" or "-"
		end
	end
	return table.concat(parts)
end

function Layout.ApplyVisual()
	if InLockdown() then
		Bars.RequestLayout("lockdown")
		return
	end
	local inner = Bars.Strip and Bars.Strip.inner
	if not inner then
		return false
	end
	local expanding = Layout.IsExpanding()
	appliedExpanding = expanding
	local hasAny = AnyContent()
	local bottom = Layout.MiniAtBottom()
	local anyMini = Layout.AnyMiniVisible(expanding, hasAny)
	local visibleCols = Layout.VisibleCount(expanding, hasAny)
	local extraScale, xFactor = 1, 1
	if Bars.Strip and Bars.Strip.ComputeLook then
		extraScale, xFactor = Bars.Strip.ComputeLook(visibleCols, anyMini or expanding, expanding)
	end
	local C = Bars.CONFIG
	local yOffset = (Bars.Strip and Bars.Strip.GetBottomScreenOffset and Bars.Strip.GetBottomScreenOffset()) or C.yOffset
	local hash = OccupancyHash(expanding, hasAny, bottom, anyMini, extraScale, xFactor, yOffset)
	if hash == lastHash then
		if Bars.Strip and Bars.Strip.Layout then
			Bars.Strip.Layout(visibleCols, anyMini or expanding, expanding, extraScale, xFactor)
		end
		return false
	end
	lastHash = hash

	local size = C.buttonSize
	local pad = C.padding
	local buttonW = size * (xFactor or 1)
	local visual = 1
	local mainAnchorTop = bottom and anyMini

	for column = 1, Bars.NUM_COLUMNS do
		local col = Bars.hosts[column]
		local mainHost = col and col.main
		local secHost = col and col.sec
		local tertHost = col and col.tert
		local mainBtn = mainHost and mainHost.widget
		local secBtn = secHost and secHost.widget
		local tertBtn = tertHost and tertHost.widget
		local show = not Layout.IsColumnEmpty(column)
		if column == 1 and not hasAny then
			show = true
		end
		if expanding then
			show = true
		end
		if not mainBtn then
			-- skip
		elseif show then
			local xOffset = (visual - 1) * (buttonW + pad)
			mainBtn:SetSize(buttonW, size)
			mainBtn:ClearAllPoints()
			if mainAnchorTop then
				mainBtn:SetPoint("TOPLEFT", inner, "TOPLEFT", xOffset, 0)
			else
				mainBtn:SetPoint("BOTTOMLEFT", inner, "BOTTOMLEFT", xOffset, 0)
			end
			mainBtn:Show()
			visual = visual + 1

			if secBtn and tertBtn then
				local State = Bars.State
				local hasSec = State and SlotHasAction(State.GetSecondarySlot(column))
				local hasTert = State and SlotHasAction(State.GetTertiarySlot(column))
				local hasMain = Layout.HasContentOnMain(column)
				local promoted = (not expanding) and Layout.GetPromotedMode(column)
				secBtn:SetSize(buttonW, size)
				tertBtn:SetSize(buttonW, size)
				if promoted == "sec" or promoted == "tert" then
					ParkMini(secBtn)
					ParkMini(tertBtn)
				elseif promoted == "both" then
					-- Topleft (sec) is on main; leftover face is the tert widget, centered.
					AnchorPair(secBtn, tertBtn, mainBtn, "promoted_both", bottom)
					tertBtn:SetScale(0.5)
					tertBtn:Show()
					ParkMini(secBtn)
				else
					local secShow = hasSec
					local tertShow = hasTert
					if expanding then
						if hasMain then
							secShow = true
							if hasSec then
								tertShow = true
							end
						end
						if hasTert then
							secShow = true
						end
					end
					secBtn:SetScale(0.5)
					tertBtn:SetScale(0.5)
					if expanding then
						if not hasSec and not hasTert then
							AnchorPair(secBtn, tertBtn, mainBtn, "expand_empty", bottom)
						else
							AnchorPair(secBtn, tertBtn, mainBtn, "expand_corners", bottom)
						end
					elseif hasSec and not hasTert then
						AnchorPair(secBtn, tertBtn, mainBtn, "only_sec", bottom)
					elseif hasTert and not hasSec then
						AnchorPair(secBtn, tertBtn, mainBtn, "only_tert", bottom)
					else
						AnchorPair(secBtn, tertBtn, mainBtn, "default_corners", bottom)
					end
					if secShow then
						secBtn:Show()
					else
						ParkMini(secBtn)
					end
					if tertShow then
						tertBtn:Show()
					else
						ParkMini(tertBtn)
					end
				end
			end
		else
			mainBtn:Hide()
			if secBtn then
				secBtn:Hide()
			end
			if tertBtn then
				tertBtn:Hide()
			end
		end
	end

	if Bars.Strip and Bars.Strip.Layout then
		Bars.Strip.Layout(visibleCols, anyMini or expanding, expanding, extraScale, xFactor)
	end
	return true
end

function Layout.Invalidate()
	lastHash = nil
	Layout.InvalidateMappings()
end

function Layout.Apply()
	if InLockdown() then
		Bars.RequestLayout("lockdown")
		return
	end
	Layout.ApplyMappings()
	-- Re-skinning 57 widgets is only worth it when the visual pass actually moved
	-- something; unchanged occupancy must cost nothing.
	local moved = Layout.ApplyVisual()
	if not moved then
		return
	end
	if Bars.Hosts and Bars.Hosts.ApplyChrome then
		Bars.Hosts.ApplyChrome()
	end
	if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
		pcall(FluxUnifiedBorder.UpdateBorder)
	end
	-- Restacks the pet bar and rebuilds the whole stance bar. Only the strip
	-- actually moving can change what they anchor to, so a page flip that left
	-- geometry alone must not drag them along.
	if FluxUILayoutSqueeze and FluxUILayoutSqueeze.NotifyLayoutDependents then
		pcall(FluxUILayoutSqueeze.NotifyLayoutDependents)
	end
end

function Layout.Request(reason)
	Bars.RequestLayout(reason or "smart")
end

-- ---------------------------------------------------------------------------
-- Drag expand watcher
-- ---------------------------------------------------------------------------

local function SyncSensing()
	local sensing = Bars.Strip and Bars.Strip.sensing
	if not sensing then
		return
	end
	local Cap = Flux.Cap
	if Cap and Cap.IsGamepadUIEnabled and Cap.IsGamepadUIEnabled() then
		sensing:Hide()
		return
	end
	if GetCursorInfo and GetCursorInfo() then
		sensing:Show()
	else
		sensing:Hide()
	end
end

--- Cursor, grid and drag-tick edges only move the strip when the hover expand
--- state flips. Dragging inside bags or the bank must not relayout 57 hosts.
local function RequestIfExpandFlipped(reason)
	if Layout.IsExpanding() == appliedExpanding then
		return false
	end
	Layout.Request(reason)
	return true
end

--- Only the hover edge matters here, and that cannot change faster than the
-- player moves the mouse, so poll at the shared interval instead of per frame.
local function OnDragTick(elapsed)
	if not GetCursorInfo or not GetCursorInfo() then
		dragWatching = false
		dragAccum = 0
		if Flux.Ticker and Flux.Ticker.Remove then
			Flux.Ticker.Remove("bars.layout.drag")
		end
		SyncSensing()
		RequestIfExpandFlipped("drag_end")
		return
	end
	dragAccum = dragAccum + (elapsed or 0)
	if dragAccum < Bars.CONFIG.rangeInterval then
		return
	end
	dragAccum = 0
	SyncSensing()
	RequestIfExpandFlipped("drag")
end

function Layout.OnCursor()
	SyncSensing()
	local dragging = GetCursorInfo and GetCursorInfo()
	if dragging and not dragWatching then
		dragWatching = true
		dragAccum = 0
		if Flux.Ticker and Flux.Ticker.Add then
			Flux.Ticker.Add("bars.layout.drag", OnDragTick)
		end
	elseif not dragging and dragWatching then
		dragWatching = false
		dragAccum = 0
		if Flux.Ticker and Flux.Ticker.Remove then
			Flux.Ticker.Remove("bars.layout.drag")
		end
	end
	RequestIfExpandFlipped("cursor")
end

function Layout.Start()
	if started then
		return
	end
	local Ev = Flux.Events
	if not Ev or not Ev.Register then
		return
	end
	started = true
	Ev.Register("CURSOR_CHANGED", function()
		Layout.OnCursor()
	end)
	Ev.Register("ACTIONBAR_SHOWGRID", function()
		if InLockdown() then
			Layout.RevealEmptyInCombat()
			return
		end
		if not RequestIfExpandFlipped("showgrid") and Bars.RequestStockSweep then
			Bars.RequestStockSweep()
		end
	end)
	Ev.Register("ACTIONBAR_HIDEGRID", function()
		if not RequestIfExpandFlipped("hidegrid") and Bars.RequestStockSweep then
			Bars.RequestStockSweep()
		end
	end)
end
