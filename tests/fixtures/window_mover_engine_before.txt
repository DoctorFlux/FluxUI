-- Engine.lua — secret-safe window move/scale. Overlay proxy; never StartMoving Blizzard frames.
local addonName, ns = ...
local Flux = ns.Flux

local WindowMover = Flux.WindowMover or {}
Flux.WindowMover = WindowMover

local attached = {} -- name -> { frame = frame, spec = spec, dynamicSize = bool }
local applying = {} -- name -> true
local suppressed = {} -- name -> true (Baganator took bags later, etc.)
local hookedLayout = {} -- frame -> { SetPoint = true, SetScale = true }
local hookedMouse = {}
local hookedShow = {}
local session = {} -- name -> { x, y, scale } live layout even when save is off
local started = false
local panelWatch
local panelFrames={}

local function ObserveNativePanel(name,frame)
	panelFrames[name]={frame=frame,shown=false}
	if panelWatch then return end
	panelWatch=CreateFrame("Frame")
	local elapsed=0
	panelWatch:SetScript("OnUpdate",function(_,dt)
		elapsed=elapsed+dt
		if elapsed<0.1 then return end
		elapsed=0
		for key,record in pairs(panelFrames) do
			local shown=record.frame:IsShown() and true or false
			if shown~=record.shown then
				record.shown=shown
				if shown then WindowMover.Apply(key,record.frame) end
			end
		end
	end)
end

local function ResolveDynamicSize(entry)
	if not entry then
		return false
	end
	local ds = entry.dynamicSize
	if ds == true then
		return true
	end
	if type(ds) == "function" then
		local ok, res = pcall(ds)
		return ok and res and true or false
	end
	return false
end

local function NameIsDynamicSize(name)
	local info = attached[name]
	return info and info.dynamicSize and true or false
end

-- Forever's gamepad bag and bank are Blizzard's alone. Covers a switch to the
-- gamepad UI after these windows were attached.
local function ForeverGamepadBag(name)
	local info = attached[name]
	if not (info and info.spec and info.spec.bag) then
		return false
	end
	local cap = Flux.Cap
	return cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() or false
end

local SCALE_MIN = 0.5
local SCALE_MAX = 2.5
local SCALE_SENSITIVITY = 0.0024

local active -- { name, frame, mode = "move"|"scale", startCX, startCY, originX, originY, startScale }

local proxy
local driver

local function Secrets()
	return Flux.Secrets
end

local function PlainNumber(value)
	if value == nil then
		return nil
	end
	local S = Secrets()
	if S and S.IsSecretValue and S.IsSecretValue(value) then
		return nil
	end
	if S and S.CanAccessValue and not S.CanAccessValue(value) then
		return nil
	end
	local ok, num = pcall(tonumber, value)
	if not ok or num == nil then
		return nil
	end
	if type(num) ~= "number" or num ~= num or num == math.huge or num == -math.huge then
		return nil
	end
	if S and S.IsSecretValue and S.IsSecretValue(num) then
		return nil
	end
	return num
end

local function GetDB()
	local FO = _G.FluxOptions
	if FO and FO.GetWindowMoverDB then
		local db = FO:GetWindowMoverDB()
		if db then
			if not db.frames then
				db.frames = {}
			end
			return db
		end
	end
	return nil
end

local function Defaults()
	return {
		enabled = true,
		scaleEnabled = true,
		savePosition = true,
		saveScale = true,
		requireModifier = false,
		modifier = "SHIFT",
		clampToScreen = true,
		snap = 0,
		lock = false,
		frames = {},
	}
end

function WindowMover.Settings()
	local db = GetDB()
	if db then
		return db
	end
	return Defaults()
end

local function Snap(v, snap)
	if not snap or snap <= 0 then
		return v
	end
	return math.floor(v / snap + 0.5) * snap
end

local function CursorUIParent()
	local cx, cy = GetCursorPosition()
	cx = PlainNumber(cx)
	cy = PlainNumber(cy)
	local scale = UIParent and UIParent.GetEffectiveScale and PlainNumber(UIParent:GetEffectiveScale())
	if not cx or not cy or not scale or scale == 0 then
		return nil
	end
	return cx / scale, cy / scale
end

local function TryFrameBottomLeft(frame)
	if not frame then
		return nil
	end
	local left = frame.GetLeft and PlainNumber(frame:GetLeft())
	local bottom = frame.GetBottom and PlainNumber(frame:GetBottom())
	if left and bottom then
		return left, bottom
	end
	return nil
end

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function CanLayout(frame)
	if not WindowMover.IsFrame(frame) then
		return false
	end
	if InLockdown() then
		if frame.IsProtected and frame:IsProtected() then
			return false
		end
	end
	if frame.CanChangeProtectedState then
		local ok, can = pcall(function()
			return frame:CanChangeProtectedState()
		end)
		if ok and can == false then
			return false
		end
	end
	if C_RestrictedActions and C_RestrictedActions.CheckAllowProtectedFunctions then
		local ok, allowed = pcall(C_RestrictedActions.CheckAllowProtectedFunctions, frame, true)
		if ok and allowed == false then
			return false
		end
	end
	return true
end

local function ClampPoint(frame, x, y)
	local sw = PlainNumber(GetScreenWidth and GetScreenWidth())
	local sh = PlainNumber(GetScreenHeight and GetScreenHeight())
	if (not sw or not sh) and UIParent then
		sw = PlainNumber(UIParent:GetWidth())
		sh = PlainNumber(UIParent:GetHeight())
	end
	if not sw or not sh then
		return x, y
	end
	local w = (frame.GetWidth and PlainNumber(frame:GetWidth())) or 0
	local h = (frame.GetHeight and PlainNumber(frame:GetHeight())) or 0
	local scale = (frame.GetScale and PlainNumber(frame:GetScale())) or 1
	w = w * scale
	h = h * scale
	if x < 0 then
		x = 0
	end
	if y < 0 then
		y = 0
	end
	if w > 0 and x > sw - w then
		x = sw - w
	end
	if h > 0 and y > sh - h then
		y = sh - h
	end
	return x, y
end

local function EnsureDriver()
	if driver then
		return driver
	end
	driver = CreateFrame("Frame", "FluxWindowMoverDriver", UIParent)
	driver:Hide()
	driver:SetScript("OnUpdate", function()
		WindowMover._OnProxyUpdate()
	end)
	return driver
end

local function EnsureProxy()
	EnsureDriver()
	if proxy then
		return proxy
	end
	proxy = CreateFrame("Frame", "FluxWindowMoverProxy", UIParent)
	proxy:SetFrameStrata("TOOLTIP")
	proxy:SetFrameLevel(10000)
	proxy:Hide()
	proxy:SetMovable(true)
	proxy:EnableMouse(false)
	proxy:SetClampedToScreen(true)
	return proxy
end

local function SetActive(job)
	active = job
	local d = EnsureDriver()
	if job then
		d:Show()
	else
		d:Hide()
	end
end

local function MergeRec(name)
	local db = WindowMover.Settings()
	local live = session[name]
	local saved = db and db.frames and db.frames[name]
	if not live then
		return saved
	end
	if not saved then
		return live
	end
	return {
		x = live.x or saved.x,
		y = live.y or saved.y,
		scale = live.scale or saved.scale,
	}
end

local function DeferApply(name)
	if Flux.Combat and Flux.Combat.Defer then
		Flux.Combat.Defer("windowmover.apply." .. name, function()
			WindowMover.Apply(name)
		end)
	end
end

function WindowMover.Apply(name, frame)
	if suppressed[name] or ForeverGamepadBag(name) then
		return
	end
	frame = frame or WindowMover.Resolve(name)
	if not WindowMover.IsFrame(frame) then
		return
	end
	local db = WindowMover.Settings()
	if not db.enabled then
		return
	end
	local rec = MergeRec(name)
	if not rec then
		return
	end
	if not CanLayout(frame) then
		DeferApply(name)
		return
	end
	-- Edit Mode shows some of these (loot frame preview) inside its pass.
	if FluxEditModeBusy and FluxEditModeBusy() then
		FluxAfterEditMode(function()
			WindowMover.Apply(name)
		end, "WindowMover.Apply." .. name)
		return
	end

	local x = PlainNumber(rec.x)
	local y = PlainNumber(rec.y)
	local scale = PlainNumber(rec.scale)
	local dynamicSize = NameIsDynamicSize(name)

	applying[name] = true
	if not dynamicSize and db.scaleEnabled and scale and scale > 0.001 then
		if frame.isMaximized and scale > 1 then
			scale = 1
		end
		pcall(frame.SetScale, frame, scale)
	end
	if x and y then
		local snap = PlainNumber(db.snap) or 0
		x = Snap(x, snap)
		y = Snap(y, snap)
		if db.clampToScreen then
			x, y = ClampPoint(frame, x, y)
		end
		-- Camelot BankFrame grows with page rows. Only leave UIPanel after a
		-- user-saved drag point; never SetSize.
		frame.ignoreFramePositionManager = true
		pcall(function()
			frame:ClearAllPoints()
			frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
		end)
		if db.clampToScreen and frame.SetClampedToScreen then
			pcall(frame.SetClampedToScreen, frame, true)
		end
	end
	applying[name] = nil
end

local function SavePoint(name, x, y)
	x = PlainNumber(x)
	y = PlainNumber(y)
	if not x or not y then
		return
	end
	session[name] = session[name] or {}
	session[name].x = x
	session[name].y = y
	local db = GetDB()
	if not db or not db.savePosition then
		return
	end
	db.frames = db.frames or {}
	local rec = db.frames[name] or {}
	rec.x = x
	rec.y = y
	db.frames[name] = rec
end

local function SaveScale(name, scale)
	scale = PlainNumber(scale)
	if not scale or scale <= 0.001 then
		return
	end
	if scale < SCALE_MIN then
		scale = SCALE_MIN
	end
	if scale > SCALE_MAX then
		scale = SCALE_MAX
	end
	scale = tonumber(string.format("%.3f", scale)) or scale
	session[name] = session[name] or {}
	session[name].scale = scale
	local db = GetDB()
	if not db or not db.saveScale or not db.scaleEnabled then
		return
	end
	db.frames = db.frames or {}
	local rec = db.frames[name] or {}
	rec.scale = scale
	db.frames[name] = rec
end

local function ModifierDown(mod)
	if mod == "CTRL" then
		return IsControlKeyDown and IsControlKeyDown()
	end
	if mod == "ALT" then
		return IsAltKeyDown and IsAltKeyDown()
	end
	return IsShiftKeyDown and IsShiftKeyDown()
end

local CLICKABLE = {
	Button = true,
	CheckButton = true,
	EditBox = true,
	Slider = true,
	ScrollFrame = true,
}

local function IsClickableWidget(obj)
	if not obj or obj == proxy then
		return false
	end
	if obj.GetObjectType then
		local ok, objType = pcall(obj.GetObjectType, obj)
		if ok and CLICKABLE[objType] then
			return true
		end
	end
	if obj.IsObjectType then
		local ok, yes = pcall(obj.IsObjectType, obj, "Button")
		if ok and yes then
			return true
		end
	end
	return false
end

local function MouseIsOnClickable()
	if GetMouseFoci then
		local ok, foci = pcall(GetMouseFoci)
		if ok and type(foci) == "table" then
			for i = 1, #foci do
				if IsClickableWidget(foci[i]) then
					return true
				end
			end
		end
	end
	if GetMouseFocus then
		local ok, focus = pcall(GetMouseFocus)
		if ok and IsClickableWidget(focus) then
			return true
		end
	end
	return false
end

local function StopActive()
	if proxy then
		if proxy.StopMovingOrSizing then
			pcall(proxy.StopMovingOrSizing, proxy)
		end
		if proxy.EnableMouse then
			pcall(proxy.EnableMouse, proxy, false)
		end
		proxy:Hide()
	end
	if GameTooltip and GameTooltip.Hide then
		GameTooltip:Hide()
	end
	SetActive(nil)
end

function WindowMover._OnProxyUpdate()
	local job = active
	if not job then
		return
	end
	local db = WindowMover.Settings()
	local frame = job.frame
	if not WindowMover.IsFrame(frame) or (frame.IsShown and not frame:IsShown()) then
		StopActive()
		return
	end

	if job.mode == "move" then
		local x, y
		if proxy and proxy:IsShown() then
			x = PlainNumber(proxy:GetLeft())
			y = PlainNumber(proxy:GetBottom())
		end
		if not x or not y then
			local cx, cy = CursorUIParent()
			if cx and cy and job.startCX and job.originX then
				x = job.originX + (cx - job.startCX)
				y = job.originY + (cy - job.startCY)
			end
		end
		if not x or not y then
			return
		end
		local snap = PlainNumber(db.snap) or 0
		x = Snap(x, snap)
		y = Snap(y, snap)
		if db.clampToScreen then
			x, y = ClampPoint(frame, x, y)
		end
		SavePoint(job.name, x, y)
		WindowMover.Apply(job.name, frame)
	elseif job.mode == "scale" then
		if not db.scaleEnabled then
			return
		end
		local cx, cy = CursorUIParent()
		if not cx or not cy or not job.startCX then
			return
		end
		local dx = cx - job.startCX
		local dy = cy - job.startCY
		local delta = math.abs(dx) > math.abs(dy) and dx or dy
		local newScale = job.startScale + (delta * SCALE_SENSITIVITY)
		if newScale < SCALE_MIN then
			newScale = SCALE_MIN
		end
		if newScale > SCALE_MAX then
			newScale = SCALE_MAX
		end
		if frame.isMaximized and newScale > 1 then
			newScale = 1
		end
		SaveScale(job.name, newScale)
		WindowMover.Apply(job.name, frame)
		if GameTooltip then
			GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
			GameTooltip:SetText(string.format("%d%%", math.floor(newScale * 100 + 0.5)))
		end
	end
end

local function BeginMove(name, frame)
	if not CanLayout(frame) then
		return
	end
	local db = WindowMover.Settings()
	local rec = MergeRec(name)
	local x, y
	if rec then
		x, y = PlainNumber(rec.x), PlainNumber(rec.y)
	end
	if not x or not y then
		x, y = TryFrameBottomLeft(frame)
	end
	local cx, cy = CursorUIParent()
	if not x or not y then
		x, y = cx, cy
	end
	if not x or not y or not cx then
		return
	end

	local p = EnsureProxy()
	local w = (frame.GetWidth and PlainNumber(frame:GetWidth())) or 200
	local h = (frame.GetHeight and PlainNumber(frame:GetHeight())) or 200
	p:ClearAllPoints()
	p:SetSize(w, h)
	p:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
	if db.clampToScreen then
		p:SetClampedToScreen(true)
	end
	p:EnableMouse(true)
	p:Show()
	pcall(p.StartMoving, p)

	SetActive({
		name = name,
		frame = frame,
		mode = "move",
		startCX = cx,
		startCY = cy,
		originX = x,
		originY = y,
	})
end

local function BeginScale(name, frame)
	if NameIsDynamicSize(name) then
		return
	end
	if not CanLayout(frame) then
		return
	end
	local db = WindowMover.Settings()
	if not db.scaleEnabled then
		return
	end
	local cx, cy = CursorUIParent()
	if not cx then
		return
	end
	local rec = MergeRec(name)
	local startScale = rec and PlainNumber(rec.scale)
	if not startScale then
		startScale = frame.GetScale and PlainNumber(frame:GetScale()) or 1
	end
	if not startScale or startScale <= 0 then
		startScale = 1
	end
	EnsureProxy()
	SetActive({
		name = name,
		frame = frame,
		mode = "scale",
		startCX = cx,
		startCY = cy,
		startScale = startScale,
	})
end

function WindowMover.ResetFrame(name)
	session[name] = nil
	local db = GetDB()
	if db and db.frames then
		db.frames[name] = nil
	end
	local frame = WindowMover.Resolve(name)
	if WindowMover.IsFrame(frame) and CanLayout(frame) then
		applying[name] = true
		pcall(frame.SetScale, frame, 1)
		applying[name] = nil
	end
	if Flux.Print then
		Flux.Print("[" .. name .. "] reset. Reopen the window to restore Blizzard's position.")
	end
end

function WindowMover.ResetAll()
	wipe(session)
	local db = GetDB()
	if db then
		db.frames = {}
	end
	StopActive()
	if Flux.Print then
		Flux.Print("Window positions reset. Reopen windows to restore Blizzard layout.")
	end
end

function WindowMover.SetLocked(lock)
	local db = GetDB()
	if db then
		db.lock = lock and true or false
	end
end

function WindowMover.IsLocked()
	return WindowMover.Settings().lock and true or false
end

local function OnMouseDown(name, frame, btn)
	if suppressed[name] or ForeverGamepadBag(name) then
		return
	end
	local db = WindowMover.Settings()
	if not db.enabled then
		return
	end
	if db.lock then
		return
	end
	if db.requireModifier and not ModifierDown(db.modifier or "SHIFT") then
		return
	end
	if InLockdown() and frame.IsProtected and frame:IsProtected() then
		return
	end
	if MouseIsOnClickable() then
		return
	end
	if btn == "LeftButton" then
		BeginMove(name, frame)
	elseif btn == "RightButton" then
		BeginScale(name, frame)
	elseif btn == "MiddleButton" then
		WindowMover.ResetFrame(name)
	end
end

local function OnMouseUp()
	StopActive()
end

-- Post-hook the instance only. Assigning frame.SetPoint / frame.SetScale a Flux
-- closure makes every Blizzard layout call on that panel run addon code; on
-- Forever's gamepad UI that reaches the protected SetPreferredGamepadInteractTarget().
-- Edit Mode systems are skipped: OnSystemLoad saves SetPoint as SetPointBase.
local POINT_METHODS = {
	SetPoint = true,
	SetPointBase = true,
	ClearAllPoints = true,
	ClearAllPointsBase = true,
}

local function IsEditModeSystem(frame)
	return frame and (frame.SetPointBase ~= nil or frame.system ~= nil)
end

local function ShouldReapplyAfterLayout(name, sel, method)
	if applying[name] or suppressed[name] then
		return false
	end
	if NameIsDynamicSize(name) then
		return false
	end
	local db = WindowMover.Settings()
	if not db.enabled then
		return false
	end
	if not MergeRec(name) then
		return false
	end
	if method == "SetScale" then
		local current = sel.GetScale and PlainNumber(sel:GetScale())
		if current and current <= 0.001 then
			return false
		end
	end
	return true
end

local function HookLayout(frame, name, method)
    -- UIPanel positioning precedes PlayerSpells OnShow -> native protected
    -- grids. Restore saved placement from our post-open observer instead.
    if name=="PlayerSpellsFrame" then return end
    -- CharacterFrame opens from the native binding too. Its SetPoint/SetScale
    -- callbacks must stay native before OnShow compares secret health, in both
    -- mouse/keyboard and gamepad UI. Reapply the saved layout after it opens.
    if name == "CharacterFrame" and Flux.Client and Flux.Client.isCamelot then
        return
    end
	if not frame[method] then
		return
	end
	local flags = hookedLayout[frame]
	if flags and flags[method] then
		return
	end
	if not (POINT_METHODS[method] or method == "SetScale") then
		return
	end
	if IsEditModeSystem(frame) then
		return
	end
	local cap = Flux.Cap
	if cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() then
		return
	end
	hookedLayout[frame] = flags or {}
	hookedLayout[frame][method] = true
	pcall(hooksecurefunc, frame, method, function(sel)
		if sel == frame and ShouldReapplyAfterLayout(name, sel, method) then
			WindowMover.Apply(name, sel)
		end
	end)
end

local dragStrips = {}

local function EnsureDragStrip(frame)
	local strip = dragStrips[frame]
	if strip then
		return strip
	end
	strip = CreateFrame("Frame", nil, frame)
	strip:SetPoint("TOPLEFT", 48, 0)
	strip:SetPoint("TOPRIGHT", -44, 0)
	strip:SetHeight(22)
	strip:EnableMouse(true)
	local lvl = 1
	if frame.GetFrameLevel then
		local ok, n = pcall(frame.GetFrameLevel, frame)
		if ok and type(n) == "number" then
			lvl = n
		end
	end
	strip:SetFrameLevel(lvl + 1)
	dragStrips[frame] = strip
	return strip
end

local function HookHandle(handle, name, frame, enableMouse)
	if not WindowMover.IsFrame(handle) then
		return
	end
	if hookedMouse[handle] then
		return
	end
	hookedMouse[handle] = true
	-- Never EnableMouse on Blizzard chrome. That is what ate window buttons
	-- (NineSlice / full-frame backgrounds covering Close and tab buttons).
	if enableMouse and handle.EnableMouse then
		pcall(handle.EnableMouse, handle, true)
	end
	if handle.HookScript then
		pcall(function()
			handle:HookScript("OnMouseDown", function(_, btn)
				OnMouseDown(name, frame, btn)
			end)
		end)
		pcall(function()
			handle:HookScript("OnMouseUp", function()
				OnMouseUp()
			end)
		end)
	end
end

function WindowMover.Attach(entry)
	if not entry or not entry.name then
		return false
	end
	local name = entry.name
	if suppressed[name] or attached[name] then
		return attached[name] and true or false
	end
	if WindowMover.ShouldSkip(entry) then
		suppressed[name] = true
		return false
	end
	local frame = WindowMover.Resolve(name)
	if not WindowMover.IsFrame(frame) then
		return false
	end
	if WindowMover.IsBlacklisted(frame.GetName and frame:GetName()) then
		return false
	end

	if entry.setup then
		pcall(entry.setup, frame)
	end

	-- Undo full-window hit targets if a previous build enabled them.
	local passThrough = { "NineSlice", "Bg", "Background" }
	for i = 1, #passThrough do
		local child = frame[passThrough[i]]
		if child and child.EnableMouse then
			pcall(child.EnableMouse, child, false)
		end
	end

	local handles = WindowMover.FindDragHandles(frame, entry) or {}
	if entry.drag ~= "frame" then
		local canDrag = false
		for i = 1, #handles do
			local h = handles[i]
			if h.IsMouseEnabled then
				local ok, on = pcall(h.IsMouseEnabled, h)
				if ok and on then
					canDrag = true
					break
				end
			end
		end
		if not canDrag then
			handles[#handles + 1] = EnsureDragStrip(frame)
		end
	end
	for i = 1, #handles do
		HookHandle(handles[i], name, frame, dragStrips[frame] == handles[i])
	end

	-- Do not HookScript OnHide. HideUIPanel hides the panel inside
	-- FramePositionDelegate:SetUIPanel, then BroadcastForcePanelHide reaches
	-- SetPreferredGamepadInteractTarget. An OnHide hook taints that call.
	-- The drag driver already StopActive when the frame is no longer shown.
	-- Forever CharacterFrame:OnShow compares secret health in TextStatusBar.
	-- Reapply saved position from the independent post-open watcher instead.
	local camelotCharacter = name == "CharacterFrame" and Flux.Client and Flux.Client.isCamelot
	if camelotCharacter then
		hookedShow[frame] = true
		local info = rawget(_G, "FluxInfoFrame")
		if info and info.AfterCharacterShown then
			info.AfterCharacterShown(function()
				WindowMover.Apply(name, frame)
			end)
		end
	elseif name=="PlayerSpellsFrame" then
		hookedShow[frame]=true
		ObserveNativePanel(name,frame)
	elseif frame.HookScript and not hookedShow[frame] then
		hookedShow[frame] = true
		pcall(function()
			frame:HookScript("OnShow", function()
				WindowMover.Apply(name, frame)
			end)
		end)
	end

	local dynamicSize = ResolveDynamicSize(entry)
	attached[name] = { frame = frame, spec = entry, dynamicSize = dynamicSize }
	if not dynamicSize then
		if not IsEditModeSystem(frame) then
			HookLayout(frame, name, "SetPoint")
		end
		HookLayout(frame, name, "SetScale")
	end

	if name~="PlayerSpellsFrame" then WindowMover.Apply(name, frame) end
	return true
end

function WindowMover.Scan()
	local catalog = WindowMover.Catalog and WindowMover.Catalog()
	if not catalog then
		return 0
	end
	local n = 0
	for i = 1, #catalog do
		local entry = catalog[i]
		if entry then
			if WindowMover.ShouldSkip(entry) then
				if attached[entry.name] then
					suppressed[entry.name] = true
				end
			else
				suppressed[entry.name] = nil
				if WindowMover.Attach(entry) then
					n = n + 1
				end
			end
		end
	end
	return n
end

function WindowMover.Refresh()
	StopActive()
	local db = WindowMover.Settings()
	if not db.enabled then
		return
	end
	for name, info in pairs(attached) do
		if not suppressed[name] then
			WindowMover.Apply(name, info.frame)
		end
	end
	WindowMover.Scan()
end

function WindowMover.Start()
	if started then
		WindowMover.Scan()
		return
	end
	started = true
	EnsureProxy()
	WindowMover.Scan()

	local events = CreateFrame("Frame")
	events:RegisterEvent("ADDON_LOADED")
	events:RegisterEvent("PLAYER_ENTERING_WORLD")
	events:SetScript("OnEvent", function(_, event, loaded)
		if event == "ADDON_LOADED" and loaded == addonName then
			return
		end
		WindowMover.Scan()
	end)

	if C_Timer and C_Timer.After then
		C_Timer.After(1, function()
			WindowMover.Scan()
		end)
		C_Timer.After(5, function()
			WindowMover.Scan()
		end)
	end
end

function WindowMover.AttachedCount()
	local n = 0
	for name in pairs(attached) do
		if not suppressed[name] then
			n = n + 1
		end
	end
	return n
end

function WindowMover.Smoke()
	local failures = {}
	local catalog = WindowMover.Catalog and WindowMover.Catalog()
	if not catalog or #catalog == 0 then
		failures[#failures + 1] = "catalog empty"
	else
		local foundCharacter
		for i = 1, #catalog do
			if catalog[i].name == "CharacterFrame" then
				foundCharacter = true
				break
			end
		end
		if not foundCharacter then
			failures[#failures + 1] = "CharacterFrame missing from catalog"
		end
		local foundBank
		for i = 1, #catalog do
			if catalog[i].name == "BankFrame" then
				foundBank = catalog[i]
				break
			end
		end
		if not foundBank then
			failures[#failures + 1] = "BankFrame missing from catalog"
		elseif type(foundBank.dynamicSize) ~= "function" then
			failures[#failures + 1] = "BankFrame catalog must probe UsesPlayerBagsInBank via dynamicSize"
		end
	end
	if WindowMover.IsBlacklisted("CharacterFrame") then
		failures[#failures + 1] = "CharacterFrame blacklisted"
	end
	if not WindowMover.IsBlacklisted("PlayerFrame") then
		failures[#failures + 1] = "PlayerFrame not blacklisted"
	end
	if not WindowMover.IsBlacklisted("FluxVendorRestockPanelFrame") then
		failures[#failures + 1] = "FluxVendorRestockPanelFrame not blacklisted"
	end
	-- Game menu frames taint GameMenuFrameMixin:OnShow (SetPreferredGamepadInteractTarget).
	-- GamepadMainActionBarFrame must stay unattached so trigger-bar SetScale stays Blizzard's.
	local escPathFrames = { "GameMenuFrame", "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4", "GamepadMainActionBarFrame" }
	for i = 1, #escPathFrames do
		local name = escPathFrames[i]
		if not WindowMover.IsBlacklisted(name) then
			failures[#failures + 1] = name .. " not blacklisted"
		end
		if catalog then
			for j = 1, #catalog do
				if catalog[j].name == name then
					failures[#failures + 1] = name .. " must not be in catalog"
					break
				end
			end
		end
	end
	if PlainNumber(12.5) ~= 12.5 then
		failures[#failures + 1] = "PlainNumber failed"
	end
	if not WindowMover.IsFrame(UIParent) then
		failures[#failures + 1] = "UIParent not a frame"
	end
	if WindowMover.Resolve("UIParent") ~= UIParent then
		failures[#failures + 1] = "Resolve UIParent"
	end
	return failures
end
