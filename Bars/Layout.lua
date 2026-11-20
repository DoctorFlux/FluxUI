-- Bars/Layout.lua — pack-left, promotion, mini anchors. Combat-deferred Show/Hide/SetPoint.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Layout = {}
Bars.Layout = Layout

-- Temporary contents must not erase the ordinary mini promotion on exit.
local MAIN_PAGES = { 7, 8, 9, 10 }

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

local function ReadSlot(slot, snapshot)
	if not snapshot or type(slot) ~= "number" or (issecretvalue and issecretvalue(slot)) or slot ~= slot then
		return SlotHasAction(slot)
	end
	local occupied = snapshot[slot]
	if occupied == nil then
		occupied = SlotHasAction(slot)
		snapshot[slot] = occupied
	end
	return occupied
end

function Layout.HasContentInAnyState(column, snapshot)
	if column > Bars.NUM_NATIVE then
		return ReadSlot(column, snapshot)
	end
	if ReadSlot(column, snapshot) then
		return true
	end
	for i = 1, #MAIN_PAGES do
		local page = MAIN_PAGES[i]
		if ReadSlot((page - 1) * 12 + column, snapshot) then
			return true
		end
	end
	return false
end

--- True when the currently visible main face has an action (this page only).
-- Expand placeholders use this so you can drop onto an empty form face.
-- Promotion does not: GetPromotedMode uses HasContentInAnyState.
function Layout.HasContentOnMain(column, snapshot)
	local State = Bars.State
	if not State or not State.GetMainSlot then
		return Layout.HasContentInAnyState(column, snapshot)
	end
	if column > Bars.NUM_NATIVE then
		return ReadSlot(column, snapshot)
	end
	local page = snapshot and snapshot.page
	if not page then
		page = State.GetCurrentPage and State.GetCurrentPage() or 1
		if snapshot then snapshot.page = page end
	end
	return ReadSlot(State.GetMainSlot(column, page), snapshot)
end

function Layout.IsColumnEmpty(column, snapshot)
	-- A control spell can populate any of these twelve slots after lockdown.
	-- Reserve their shown, clickable surfaces before the fight starts.
	if column <= Bars.NUM_NATIVE then return false end
	local State = Bars.State
	if Layout.HasContentInAnyState(column, snapshot) then
		return false
	end
	if State and (ReadSlot(State.GetSecondarySlot(column), snapshot) or ReadSlot(State.GetTertiarySlot(column), snapshot)) then
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
function Layout.GetPromotedMode(column, snapshot)
	local State = Bars.State
	if not State then
		return nil
	end
	local hasSec = ReadSlot(State.GetSecondarySlot(column), snapshot)
	local hasTert = ReadSlot(State.GetTertiarySlot(column), snapshot)
	if not (hasSec or hasTert) or Layout.HasContentInAnyState(column, snapshot) then
		return nil
	end
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

function Layout.InvalidateMappings(column)
	if column then
		stampedP[column], stampedS[column], stampedT[column] = nil, nil, nil
		return
	end
	for i = 1, Bars.NUM_COLUMNS do
		stampedP[i], stampedS[i], stampedT[i] = nil, nil, nil
	end
end

local function NativeValueMatches(widget, getter, expected, ...)
	if not getter then return false end
	local ok, value = pcall(getter, widget, ...)
	return ok and not (issecretvalue and issecretvalue(value)) and value == expected
end

local function StampFlags(widget, promoted, hasSec, hasTert, oldPromoted, oldSec, oldTert)
	if not widget then
		return
	end
	-- A changed column can keep one or two of its flags. Check the live
	-- values so a drifted attribute still takes the usual repair path.
	local getter = widget.GetAttribute
	if oldPromoted ~= promoted or not NativeValueMatches(widget, getter, promoted, "flux-promoted") then
		widget:SetAttribute("flux-promoted", promoted)
	end
	if oldSec ~= hasSec or not NativeValueMatches(widget, getter, hasSec, "flux-has-sec") then
		widget:SetAttribute("flux-has-sec", hasSec)
	end
	if oldTert ~= hasTert or not NativeValueMatches(widget, getter, hasTert, "flux-has-tert") then
		widget:SetAttribute("flux-has-tert", hasTert)
	end
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
function Layout.ApplyMappings(hoverOnly)
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
		-- The expanded mapping exposes both drop faces for every column.
		-- Only the collapsed mapping depends on the action slots.
		local p, s, t = 0, 1, 1
		if not expanding then
			local hasSec = SlotHasAction(State.GetSecondarySlot(column))
			local hasTert = SlotHasAction(State.GetTertiarySlot(column))
			s, t = hasSec and 1 or 0, hasTert and 1 or 0
			-- Empty minis cannot promote. Only scan the other main pages
			-- when collapse can actually move a mini onto the main face.
			if (hasSec or hasTert) and not Layout.HasContentInAnyState(column) then
				if hasSec and hasTert then
					p = 3
				elseif hasSec then
					p = 1
				else
					p = 2
				end
			end
		end
		local oldP, oldS, oldT = stampedP[column], stampedS[column], stampedT[column]
		if oldP ~= p or oldS ~= s or oldT ~= t then
			stampedP[column], stampedS[column], stampedT[column] = p, s, t
			local col = Bars.hosts[column]
			if col then
				if col.main then
					col.main._fluxPromoted = (p ~= 0) and p or nil
				end
				StampFlags(col.main and col.main.widget, p, s, t, oldP, oldS, oldT)
				StampFlags(col.sec and col.sec.widget, p, s, t, oldP, oldS, oldT)
				StampFlags(col.tert and col.tert.widget, p, s, t, oldP, oldS, oldT)
			end
			-- New flags move the slot pick, so the guards that would skip the
			-- restamp have to go with them.
			if Bars.Watch and Bars.Watch.InvalidateColumnStamps then
				Bars.Watch.InvalidateColumnStamps(column)
			end
			changed = true
		end
	end

	local applied
	if changed then
		if Flux.Perf then
			Flux.Perf.Count("bars.mapping.restamp")
		end
		if State.ForceApply then
			applied = State.ForceApply(hoverOnly == true)
		end
	end
	-- Early Forever builds without secure paging still need the OOC fallback,
	-- even when occupancy flags (and ForceApply) did not move.
	if applied ~= true and State.ApplySlotsInsecure then
		if not (State.UsesSecurePaging and State.UsesSecurePaging()) then
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

local function FacePointMatches(widget, point, relative, relativePoint, x, y)
	local n = widget:GetNumPoints()
	if (issecretvalue and issecretvalue(n)) or n ~= 1 then return false end
	local p, frame, rp, ox, oy = widget:GetPoint(1)
	if issecretvalue and (issecretvalue(p) or issecretvalue(frame) or issecretvalue(rp)
		or issecretvalue(ox) or issecretvalue(oy)) then return false end
	return p == point and frame == relative and rp == relativePoint and ox == x and oy == y
end

local function PlaceFace(widget, changedFaces, point, relative, relativePoint, x, y)
	if relative and changedFaces and widget.GetPoint and widget.GetNumPoints then
		local ok, matches = pcall(FacePointMatches, widget, point, relative, relativePoint, x, y)
		if ok and matches then return end
	end
	if changedFaces then changedFaces[widget] = true end
	widget:ClearAllPoints()
	if relative then widget:SetPoint(point, relative, relativePoint, x, y) end
end

local function ApplyFaceShown(widget, shown, changedFaces)
	if changedFaces then
		if NativeValueMatches(widget, widget.IsShown, shown) then return end
		changedFaces[widget] = true
	end
	if shown then widget:Show() else widget:Hide() end
end

local function ApplyMiniScale(widget, changedFaces)
	if changedFaces then
		if NativeValueMatches(widget, widget.GetScale, 0.5) then return end
		changedFaces[widget] = true
	end
	widget:SetScale(0.5)
end

--- Park unused minis off-screen and keep them Shown. Hiding them drops
-- anchors and makes drag/pickup feel dead. Combat still must not
-- Show/Hide/SetPoint protected frames (ApplyVisual returns in lockdown).
local function ParkMini(widget, changedFaces)
	if not widget then
		return
	end
	local parent = widget.GetParent and widget:GetParent()
	PlaceFace(widget, changedFaces, "TOPLEFT", parent, "TOPLEFT", -9999, 9999)
	if changedFaces and not widget._fluxParked then changedFaces[widget] = true end
	widget._fluxParked = true
	if widget.Show then
		ApplyFaceShown(widget, true, changedFaces)
	end
end

local function AnchorPair(secBtn, tertBtn, mainBtn, centerSec, centerTert, miniAtBottom, changedFaces)
	local edge, relativeEdge = "BOTTOM", "TOP"
	if miniAtBottom then edge, relativeEdge = "TOP", "BOTTOM" end
	if secBtn then
		local side = centerSec and "" or "LEFT"
		if changedFaces and secBtn._fluxParked then changedFaces[secBtn] = true end
		secBtn._fluxParked = nil
		PlaceFace(secBtn, changedFaces, edge .. side, mainBtn, relativeEdge .. side, 0, 0)
	end
	if tertBtn then
		local side = centerTert and "" or "RIGHT"
		if changedFaces and tertBtn._fluxParked then changedFaces[tertBtn] = true end
		tertBtn._fluxParked = nil
		PlaceFace(tertBtn, changedFaces, edge .. side, mainBtn, relativeEdge .. side, 0, 0)
	end
end

local function AnyContent(snapshot)
	for i = 1, Bars.NUM_COLUMNS do
		if not Layout.IsColumnEmpty(i, snapshot) then
			return true
		end
	end
	return false
end

local function MiniShownForColumn(column, expanding, hasAny, snapshot)
	local show = expanding or (column == 1 and not hasAny) or not Layout.IsColumnEmpty(column, snapshot)
	if not show then
		return false, false
	end
	local promoted = (not expanding) and Layout.GetPromotedMode(column, snapshot)
	if promoted == "sec" or promoted == "tert" then
		return false, false
	end
	local State = Bars.State
	local hasSec = State and ReadSlot(State.GetSecondarySlot(column), snapshot)
	local hasTert = State and ReadSlot(State.GetTertiarySlot(column), snapshot)
	local secShow = hasSec
	local tertShow = hasTert
	if expanding then
		if Layout.HasContentOnMain(column, snapshot) then
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

function Layout.AnyMiniVisible(expanding, hasAny, snapshot)
	for i = 1, Bars.NUM_COLUMNS do
		local secShow, tertShow = MiniShownForColumn(i, expanding, hasAny, snapshot)
		if secShow or tertShow then
			return true
		end
	end
	return false
end

function Layout.VisibleCount(expanding, hasAny, snapshot)
	if expanding then
		return math.max(1, Bars.NUM_COLUMNS)
	end
	local n = 0
	for i = 1, Bars.NUM_COLUMNS do
		if (i == 1 and not hasAny) or not Layout.IsColumnEmpty(i, snapshot) then
			n = n + 1
		end
	end
	if n < 1 then
		n = 1
	end
	return n
end

local function OccupancyHash(expanding, hasAny, bottom, minis, extraScale, xFactor, yOffset, snapshot)
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
		-- Expanded columns are always visible. Only their current main face
		-- and mini occupancy can move drop targets.
		if expanding then
			parts[#parts + 1] = Layout.HasContentOnMain(i, snapshot) and "m" or "-"
		else
			parts[#parts + 1] = Layout.IsColumnEmpty(i, snapshot) and "0" or "1"
			local promoted = Layout.GetPromotedMode(i, snapshot)
			parts[#parts + 1] = promoted and promoted:sub(1, 1) or "-"
		end
		local State = Bars.State
		if State then
			parts[#parts + 1] = ReadSlot(State.GetSecondarySlot(i), snapshot) and "S" or "-"
			parts[#parts + 1] = ReadSlot(State.GetTertiarySlot(i), snapshot) and "T" or "-"
		end
	end
	return table.concat(parts)
end

local function FaceSizeMatches(widget, width, height)
	local w, h
	if widget.GetSize then w, h = widget:GetSize()
	else w, h = widget:GetWidth(), widget:GetHeight() end
	if issecretvalue and (issecretvalue(w) or issecretvalue(h)) then return false end
	return w == width and h == height
end

local function ApplyFaceSize(widget, width, height, changedFaces)
	if changedFaces then
		if widget._fluxLayoutW == width and widget._fluxLayoutH == height then
			local ok, matches = pcall(FaceSizeMatches, widget, width, height)
			if ok and matches then return end
		end
		changedFaces[widget] = true
	end
	-- The chrome can update before GetWidth/GetHeight settle on this frame.
	widget._fluxLayoutW, widget._fluxLayoutH = width, height
	widget:SetSize(width, height)
end

function Layout.ApplyVisual(deferDragUnitAnchors, slotLayout)
	if InLockdown() then
		Bars.RequestLayout("lockdown")
		return
	end
	local inner = Bars.Strip and Bars.Strip.inner
	if not inner then
		return false
	end
	local expanding = Layout.IsExpanding()
	local deferUnitAnchors = deferDragUnitAnchors and (appliedExpanding ~= expanding or slotLayout)
	local changedFaces = deferUnitAnchors and lastHash ~= nil and {} or nil
	appliedExpanding = expanding
	-- The visual pass runs after secure mapping updates. Reuse its own slot
	-- and page reads across measurement, the layout key, and placement.
	local snapshot = {}
	local hasAny = expanding or AnyContent(snapshot)
	local bottom = Layout.MiniAtBottom()
	local anyMini = Layout.AnyMiniVisible(expanding, hasAny, snapshot)
	local visibleCols = Layout.VisibleCount(expanding, hasAny, snapshot)
	local extraScale, xFactor = 1, 1
	if Bars.Strip and Bars.Strip.ComputeLook then
		extraScale, xFactor = Bars.Strip.ComputeLook(visibleCols, anyMini or expanding, expanding)
	end
	local C = Bars.CONFIG
	local yOffset = (Bars.Strip and Bars.Strip.GetBottomScreenOffset and Bars.Strip.GetBottomScreenOffset()) or C.yOffset
	local hash = OccupancyHash(expanding, hasAny, bottom, anyMini, extraScale, xFactor, yOffset, snapshot)
	if hash == lastHash then
		local stripChanged
		if Bars.Strip and Bars.Strip.Layout then
			stripChanged = Bars.Strip.Layout(visibleCols, anyMini or expanding, expanding, extraScale, xFactor, true, deferUnitAnchors)
		end
		return false, stripChanged
	end
	local checkExistingStrip = lastHash ~= nil
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
		local show = expanding or (column == 1 and not hasAny) or not Layout.IsColumnEmpty(column, snapshot)
		if not mainBtn then
			-- skip
		elseif show then
			local xOffset = (visual - 1) * (buttonW + pad)
			ApplyFaceSize(mainBtn, buttonW, size, changedFaces)
			local mainPoint = mainAnchorTop and "TOPLEFT" or "BOTTOMLEFT"
			PlaceFace(mainBtn, changedFaces, mainPoint, inner, mainPoint, xOffset, 0)
			ApplyFaceShown(mainBtn, true, changedFaces)
			visual = visual + 1

			if secBtn and tertBtn then
				local State = Bars.State
				local hasSec = State and ReadSlot(State.GetSecondarySlot(column), snapshot)
				local hasTert = State and ReadSlot(State.GetTertiarySlot(column), snapshot)
				local promoted = (not expanding) and Layout.GetPromotedMode(column, snapshot)
				ApplyFaceSize(secBtn, buttonW, size, changedFaces)
				ApplyFaceSize(tertBtn, buttonW, size, changedFaces)
				if promoted == "sec" or promoted == "tert" then
					ParkMini(secBtn, changedFaces)
					ParkMini(tertBtn, changedFaces)
				elseif promoted == "both" then
					-- Topleft (sec) is on main; leftover face is the tert widget, centered.
					AnchorPair(nil, tertBtn, mainBtn, false, true, bottom, changedFaces)
					ApplyMiniScale(tertBtn, changedFaces)
					ApplyFaceShown(tertBtn, true, changedFaces)
					ParkMini(secBtn, changedFaces)
				else
					local secShow = hasSec
					local tertShow = hasTert
					if expanding then
						if Layout.HasContentOnMain(column, snapshot) then
							secShow = true
							if hasSec then
								tertShow = true
							end
						end
						if hasTert then
							secShow = true
						end
					end
					ApplyMiniScale(secBtn, changedFaces)
					ApplyMiniScale(tertBtn, changedFaces)
					-- Choose the final placement before touching either mini.
					-- Hidden drop targets go directly to their parking point.
					local centerSec = not hasTert and (not expanding or not hasSec)
					local centerTert = not expanding and not hasSec
					AnchorPair(secShow and secBtn, tertShow and tertBtn, mainBtn, centerSec, centerTert, bottom, changedFaces)
					if secShow then
						ApplyFaceShown(secBtn, true, changedFaces)
					else
						ParkMini(secBtn, changedFaces)
					end
					if tertShow then
						ApplyFaceShown(tertBtn, true, changedFaces)
					else
						ParkMini(tertBtn, changedFaces)
					end
				end
			end
		else
			ApplyFaceShown(mainBtn, false, changedFaces)
			if secBtn then
				ApplyFaceShown(secBtn, false, changedFaces)
			end
			if tertBtn then
				ApplyFaceShown(tertBtn, false, changedFaces)
			end
		end
	end

	if Bars.Strip and Bars.Strip.Layout then
		-- A slot can move between visible cells without changing the strip shell.
		Bars.Strip.Layout(visibleCols, anyMini or expanding, expanding, extraScale, xFactor, checkExistingStrip, deferUnitAnchors)
	end
	return true, nil, changedFaces
end

function Layout.Invalidate()
	lastHash = nil
	Layout.InvalidateMappings()
end

function Layout.Apply(hoverOnly, slotLayout)
	if InLockdown() then
		Bars.RequestLayout("lockdown")
		return
	end
	Layout.ApplyMappings(hoverOnly)
	local wasExpanding = appliedExpanding
	-- Slot changes can grow or repack the row inside the same hover pose.
	-- Their prepared peers can use the same guarded settlement as a crossing.
	slotLayout = slotLayout == true and lastHash ~= nil
	local moved, stripChanged, changedFaces = Layout.ApplyVisual(true, slotLayout)
	if not moved and not stripChanged then
		return false
	end
	local changedDragPose = wasExpanding ~= appliedExpanding
	local settleStrip = changedDragPose or slotLayout
	if moved and Bars.Hosts and Bars.Hosts.ApplyChrome then
		Bars.Hosts.ApplyChrome(settleStrip)
	end
	local junctions = FluxBorder and FluxBorder.Junctions
	local settleChat = hoverOnly and changedDragPose and _G.FluxChatFrame_UpdateAfterStripLayout
	-- Update any attached bars and panels after packing or native shell repair.
	if FluxUILayoutSqueeze and FluxUILayoutSqueeze.NotifyLayoutDependents then
		pcall(FluxUILayoutSqueeze.NotifyLayoutDependents, junctions ~= nil, settleStrip, not not settleChat)
	end
	-- The side panels can change the envelope anchors during the notification.
	-- Settle them before taking the final border geometry.
	if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
		if FluxUnifiedBorder.UpdateAfterGridLayout then
			pcall(FluxUnifiedBorder.UpdateAfterGridLayout, settleStrip)
		else
			pcall(FluxUnifiedBorder.UpdateBorder)
		end
	end
	if settleChat then pcall(settleChat) end
	-- Unit roots use the final strip/envelope top. The anchor-only path also
	-- checks whether target chrome needs repair for a different placement.
	if settleStrip and _G.FluxUnitFrames_ApplyPlayerStatusBarLayout then
		pcall(_G.FluxUnitFrames_ApplyPlayerStatusBarLayout, true)
	end
	-- A real pack/drag change can move dependent chrome while the strip's
	-- outer rectangle stays fixed. Check the finished layout once; unchanged
	-- occupancy returns above and never requests a border pass.
	if junctions then
		-- A placement can resize the settled strip without crossing its
		-- hover edge. Let the builder verify a prepared layout in either case.
		junctions:CommitLayout(appliedExpanding)
	end
	return moved or stripChanged, changedFaces
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
	local gamepad = Cap and Cap.IsGamepadUIEnabled and Cap.IsGamepadUIEnabled()
	local shown = not not (not gamepad and GetCursorInfo and GetCursorInfo())
	if NativeValueMatches(sensing, sensing.IsShown, shown) then return end
	if shown then
		sensing:Show()
	else
		sensing:Hide()
	end
end

--- Cursor, grid and drag-tick edges only move the strip when the hover expand
--- state flips. Dragging inside bags or the bank must not relayout 57 hosts.
function Layout.HasPendingDragPose()
	return Layout.IsExpanding() ~= appliedExpanding
end

local function RequestIfExpandFlipped(reason)
	if not Layout.HasPendingDragPose() then
		return false
	end
	Layout.Request(reason)
	return true
end

function Layout.OnDragHover()
	RequestIfExpandFlipped("drag")
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
	Layout.OnDragHover()
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
		RequestIfExpandFlipped("showgrid")
		if Bars.RequestStockSweep then Bars.RequestStockSweep() end
	end)
	Ev.Register("ACTIONBAR_HIDEGRID", function()
		RequestIfExpandFlipped("hidegrid")
		if Bars.RequestStockSweep then Bars.RequestStockSweep() end
	end)
end
