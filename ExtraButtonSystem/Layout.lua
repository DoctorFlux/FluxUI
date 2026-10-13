-- ExtraButtonSystem/Layout.lua — strip Y, squeeze, 2-row pack, host show/hide.
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS

local Layout = {}
EBS.Layout = Layout

local SLOT_MULT = 1.2
local GRID_SCALE = 1 / 1.265

function Layout.GetActionStripBottomY()
	local y
	if _G.FluxActionBar_GetBottomScreenOffset then
		y = _G.FluxActionBar_GetBottomScreenOffset()
	end
	if type(y) ~= "number" or y ~= y then
		if _G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome then
			y = _G.FluxStatusBar_GetBottomOverlayHeightForAlignedChrome()
		end
	end
	if type(y) ~= "number" or y ~= y then
		if _G.FluxStatusBar_GetBottomOverlayHeight then
			y = _G.FluxStatusBar_GetBottomOverlayHeight()
		end
	end
	if type(y) ~= "number" or y ~= y then
		y = 4
	end
	-- Whole grid row (and the border hung on it) sits above the gamepad bar
	-- and above the status bar. Returned in UIParent points.
	local Cap = Flux.Cap
	local gamepad = Cap and Cap.GamepadHudActive and Cap.GamepadHudActive()
	if not gamepad then
		return y
	end
	local floor = Cap.GetGamepadActionBarFloor and Cap.GetGamepadActionBarFloor()
	if type(floor) ~= "number" or floor ~= floor or floor < 80 then
		floor = 280
	end
	if floor > y then
		y = floor
	end
	local sb = _G.FluxStatusBarContainer
	local statusTop
	if sb and sb.IsShown and sb:IsShown() and sb.GetTop and UIParent and UIParent.GetBottom then
		local top = sb:GetTop()
		local bottom = UIParent:GetBottom() or 0
		if type(top) == "number" and top == top then
			local fes = sb.GetEffectiveScale and sb:GetEffectiveScale() or 1
			local ues = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
			if type(fes) == "number" and fes > 0 and type(ues) == "number" and ues > 0 then
				top = top * fes / ues
			end
			statusTop = top - bottom
		end
	end
	if type(statusTop) == "number" and statusTop == statusTop and statusTop + 8 > y then
		return statusTop + 8
	end
	local h = sb and sb.GetHeight and sb:GetHeight()
	if type(h) ~= "number" or h ~= h or h < 8 then
		h = 26
	end
	return y + h + 8
end

_G.FluxExtraButtonSystem_GetActionStripBottomOffset = Layout.GetActionStripBottomY

local function ActionStripFrame()
	local bar = _G.FluxActionStrip or _G.FluxMainActionBar
	if bar and bar.IsShown and bar:IsShown() then
		return bar
	end
	return nil
end

function Layout.SqueezeX()
	if FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactor then
		local f = FluxUILayoutSqueeze.GetDependentsHorizontalSqueezeFactor()
		if type(f) == "number" and f > 0 then
			return f
		end
	end
	return 1
end

local function SlotShown(slot)
	if slot.forceHidden then
		return false
	end
	if slot.roleId and EBS.Visibility then
		local smart = slot.smart
		if type(slot.smartFn) == "function" then
			smart = slot.smartFn()
		end
		if slot.roleId == "nc_consumables" then
			return EBS.Visibility.ApplyConsumables()
		end
		return EBS.Visibility.ShouldShow(slot.roleId, smart)
	end
	return slot.smart and true or (slot.btn and slot.btn.spec ~= nil)
end

function Layout.Pack(host)
	if not host or not host.Frame then
		return
	end
	if Flux.Combat.InLockdown() then
		Flux.Combat.Defer("ebs.pack." .. (host.name or "host"), function()
			Layout.Pack(host)
		end)
		return
	end
	local slots = host.slots or {}
	local groups = {}
	local order = {}
	for i = 1, #slots do
		local slot = slots[i]
		local btn = slot.btn
		if btn and btn.SlotFrame then
			local show = SlotShown(slot)
			if show then
				btn.SlotFrame:Show()
				if btn.Widget then
					btn.Widget:Show()
				end
				local key = slot.columnGroup or ("col" .. i)
				if not groups[key] then
					groups[key] = { pri = slot.columnPriority or i, buttons = {}, order = slot.columnPriority or i }
					order[#order + 1] = key
				end
				groups[key].buttons[#groups[key].buttons + 1] = slot
			else
				btn.SlotFrame:Hide()
			end
		end
	end
	table.sort(order, function(a, b)
		return (groups[a].pri or 0) < (groups[b].pri or 0)
	end)
	if host.rightToLeft then
		local rev = {}
		for i = #order, 1, -1 do
			rev[#rev + 1] = order[i]
		end
		order = rev
	end

	local size = host.buttonSize or 44
	local spacing = host.spacing or 2
	local slotSize = size * (host.slotMult or SLOT_MULT)
	local xS = Layout.SqueezeX()
	local spacingX = spacing * xS
	local slotSizeX = slotSize * xS
	local sizeStepX = slotSizeX + spacingX
	local sizeStepY = slotSize + spacing

	local maxRows = 0
	local hasSingle = false
	for i = 1, #order do
		local n = #groups[order[i]].buttons
		maxRows = math.max(maxRows, n)
		if n == 1 then
			hasSingle = true
		end
	end
	local effectiveRows = maxRows
	if hasSingle and maxRows <= 1 then
		effectiveRows = 2
	end
	if effectiveRows < 1 then
		effectiveRows = host.rows or 2
	end

	if #order == 0 then
		host.Frame:Hide()
		if EBS.Range and EBS.Range.SyncDemand then
			EBS.Range.SyncDemand()
		end
		if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
			Flux.Timer.After(0, FluxUnifiedBorder.UpdateBorder)
		end
		if FluxInfoFrame and FluxInfoFrame.UpdatePosition then
			Flux.Timer.After(0, FluxInfoFrame.UpdatePosition)
		end
		return
	end

	table.sort(order) -- already sorted by pri; keep
	local totalH = slotSize + math.max(effectiveRows - 1, 0) * sizeStepY
	local totalW = slotSizeX + math.max(#order - 1, 0) * sizeStepX
	host.Frame:SetSize(math.max(totalW, 8), math.max(totalH, 8))
	host.Frame:Show()

	for colIdx, key in ipairs(order) do
		local list = groups[key].buttons
		table.sort(list, function(a, b)
			return (a.order or 0) < (b.order or 0)
		end)
		local centerOffset = 0
		if #list == 1 then
			centerOffset = (totalH - slotSize) / 2
		end
		for rowIdx, slot in ipairs(list) do
			local x = (colIdx - 1) * sizeStepX
			local y = centerOffset + (rowIdx - 1) * sizeStepY
			slot.btn.SlotFrame:ClearAllPoints()
			slot.btn.SlotFrame:SetPoint("BOTTOMLEFT", host.Frame, "BOTTOMLEFT", x, y)
			slot.btn.SlotFrame:SetSize(slotSizeX, slotSize)
		end
	end

	if EBS.Range and EBS.Range.SyncDemand then
		EBS.Range.SyncDemand()
	end
	if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then
		Flux.Timer.After(0, FluxUnifiedBorder.UpdateBorder)
	end
	if FluxInfoFrame and FluxInfoFrame.UpdatePosition then
		Flux.Timer.After(0, FluxInfoFrame.UpdatePosition)
	end
end

function Layout.AnchorCombat(host)
	if not host or not host.Frame or Flux.Combat.InLockdown() then
		return
	end
	local frame = host.Frame
	frame:ClearAllPoints()
	local bar = ActionStripFrame()
	if bar then
		frame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", -4, 0)
		return
	end
	local nc = _G.FluxNonCombatAPI and FluxNonCombatAPI.DefaultGrid and FluxNonCombatAPI.DefaultGrid.Frame
	if not (nc and nc.IsShown and nc:IsShown()) then
		nc = EBS.hosts.nc and EBS.hosts.nc.Frame
	end
	if nc and nc.IsShown and nc:IsShown() then
		frame:SetPoint("BOTTOMLEFT", nc, "BOTTOMRIGHT", 8, 0)
		return
	end
	frame:SetPoint("BOTTOM", UIParent, "BOTTOM", -196, Layout.GetActionStripBottomY())
end

function Layout.AnchorNC(host)
	if not host or not host.Frame or Flux.Combat.InLockdown() then
		return
	end
	local frame = host.Frame
	frame:ClearAllPoints()
	local bar = ActionStripFrame()
	if bar then
		frame:SetPoint("LEFT", UIParent, "LEFT", 4, 0)
		frame:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
	else
		frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, Layout.GetActionStripBottomY())
	end
end

function Layout.AnchorTrinket(host)
	if not host or not host.Frame or Flux.Combat.InLockdown() then
		return
	end
	local frame = host.ScaleHost or host.Frame
	frame:ClearAllPoints()
	local bar = ActionStripFrame()
	if bar then
		frame:SetPoint("BOTTOMLEFT", bar, "BOTTOMRIGHT", -2, 0)
	elseif EBS.hosts.combat and EBS.hosts.combat.Frame and EBS.hosts.combat.Frame:IsShown() then
		frame:SetPoint("BOTTOMLEFT", EBS.hosts.combat.Frame, "BOTTOMRIGHT", 8, 0)
	elseif EBS.hosts.nc and EBS.hosts.nc.Frame and EBS.hosts.nc.Frame:IsShown() then
		frame:SetPoint("BOTTOMLEFT", EBS.hosts.nc.Frame, "BOTTOMRIGHT", 8, 0)
	else
		frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 200, Layout.GetActionStripBottomY())
	end
end

function Layout.NewHost(opts)
	opts = opts or {}
	local name = opts.name or "FluxEBSHost"
	local frame = CreateFrame("Frame", name, UIParent)
	frame:SetClampedToScreen(true)
	frame:SetScale(opts.scale or GRID_SCALE)
	local host = {
		name = name,
		Frame = frame,
		slots = {},
		buttonSize = opts.size or 44,
		spacing = opts.spacing or 2,
		slotMult = opts.slotMult or SLOT_MULT,
		rows = opts.rows or 2,
		rightToLeft = opts.rightToLeft,
		kind = opts.kind,
	}
	if FluxBorder and FluxBorder.ApplyTo then
		pcall(FluxBorder.ApplyTo, FluxBorder, frame, -4, -4, -5, -4)
		if FluxBorder.SetClassColor then
			pcall(FluxBorder.SetClassColor, FluxBorder, frame, 1, true)
		end
	end
	function host:AddSlot(slot)
		self.slots[#self.slots + 1] = slot
		return slot
	end
	function host:Relayout()
		Layout.Pack(self)
	end
	function host:Show()
		self.Frame:Show()
	end
	function host:Hide()
		self.Frame:Hide()
	end
	return host
end

function Layout.AttachButton(host, btn, extra)
	extra = extra or {}
	local slotSize = (host.buttonSize or 44) * (host.slotMult or SLOT_MULT)
	local slotFrame = CreateFrame("Frame", nil, host.Frame)
	slotFrame:SetSize(slotSize, slotSize)
	btn.SlotFrame = slotFrame
	btn.Widget:SetParent(slotFrame)
	btn.Widget:SetScale(host.slotMult or SLOT_MULT)
	btn.Widget:ClearAllPoints()
	btn.Widget:SetPoint("CENTER", slotFrame, "CENTER", 0, 0)
	local slot = {
		btn = btn,
		roleId = extra.roleId or btn.roleId,
		kind = extra.kind or btn.kind,
		columnGroup = extra.columnGroup,
		columnPriority = extra.columnPriority,
		order = extra.order or 1,
		smartFn = extra.smartFn,
		smart = extra.smart,
	}
	host:AddSlot(slot)
	return slot
end

function Layout.Request(reason)
	Flux.Scheduler.Request("layout", "ebs", Layout.Flush, reason or "ebs.layout")
end

function Layout.Flush()
	if EBS.Combat and EBS.Combat.Refresh then
		EBS.Combat.Refresh()
	end
	if EBS.NonCombat and EBS.NonCombat.Refresh then
		EBS.NonCombat.Refresh()
	end
	if EBS.Trinket and EBS.Trinket.Refresh then
		EBS.Trinket.Refresh()
	end
	if EBS.Utility and EBS.Utility.Refresh then
		EBS.Utility.Refresh()
	end
	if EBS.hosts.combat then
		Layout.AnchorCombat(EBS.hosts.combat)
		Layout.Pack(EBS.hosts.combat)
	end
	if EBS.hosts.nc then
		Layout.AnchorNC(EBS.hosts.nc)
		Layout.Pack(EBS.hosts.nc)
	end
	if EBS.hosts.trinket then
		Layout.AnchorTrinket(EBS.hosts.trinket)
		Layout.Pack(EBS.hosts.trinket)
	end
	EBS.stats.combat = EBS.hosts.combat and EBS.hosts.combat.Frame and EBS.hosts.combat.Frame:IsShown() or false
	EBS.stats.nc = EBS.hosts.nc and EBS.hosts.nc.Frame and EBS.hosts.nc.Frame:IsShown() or false
	EBS.stats.trinket = EBS.hosts.trinket and EBS.hosts.trinket.Frame and EBS.hosts.trinket.Frame:IsShown() or false
	if EBS.Range and EBS.Range.SyncDemand then
		EBS.Range.SyncDemand()
	end
end

function Layout.Start()
	if Flux.Events then
		Flux.Events.Register("UI_SCALE_CHANGED", function()
			Layout.Request("uiscale")
		end)
		Flux.Events.Register("DISPLAY_SIZE_CHANGED", function()
			Layout.Request("display")
		end)
	end
end
