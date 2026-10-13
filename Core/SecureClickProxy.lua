-- SecureClickProxy.lua — secure Click() of a Blizzard button over a FluxUI frame.
-- A FluxUI click handler that opens a Blizzard panel runs it as addon code. On
-- Forever's gamepad UI that ends in the protected SetPreferredGamepadInteractTarget(),
-- and CharacterFrame:OnShow throws on secret health. A hardware click on a
-- SecureActionButton runs the Blizzard button's own OnClick untainted.
-- Parented to UIParent and placed only while the owner is hovered: a protected
-- child or anchor would make the FluxUI frame protected in combat.
-- Do not SetScript or HookScript the secure button. On this client that taints
-- its OnClick, so Click() opens CharacterFrame tainted and the secret health
-- compare in TextStatusBar throws. Hover is polled from a separate frame.
local addonName, ns = ...
local Flux = ns.Flux

local type = type
local pairs = pairs
local issecretvalue = issecretvalue
local InCombatLockdown = InCombatLockdown

local Proxy = {}
Flux.SecureClickProxy = Proxy

local entries = {}
local pending = {}
local EnsurePoll

local function Plain(value)
	if type(value) ~= "number" or (issecretvalue and issecretvalue(value)) then
		return nil
	end
	return value
end

local function HideProxy(entry)
	local button = entry.button
	if button and button:IsShown() and not InCombatLockdown() then
		button:Hide()
	end
end

local function Arm(entry)
	local owner, button = entry.owner, entry.button
	if not button or InCombatLockdown() or not owner:IsVisible() or not entry.enabled() then
		return
	end
	local target
	if not entry.macrotext then
		target = entry.target and entry.target()
		if not target then
			return
		end
	end
	local scale = Plain(owner:GetEffectiveScale())
	local parentScale = Plain(UIParent:GetEffectiveScale())
	local left, bottom, width, height = owner:GetRect()
	left, bottom, width, height = Plain(left), Plain(bottom), Plain(width), Plain(height)
	local originX, originY = Plain(UIParent:GetLeft()), Plain(UIParent:GetBottom())
	if not (scale and parentScale and left and bottom and width and height and originX and originY) then
		return
	end
	if parentScale <= 0 then
		return
	end
	local k = scale / parentScale
	if entry.macrotext then
		button:SetAttribute("macrotext", entry.macrotext)
	else
		button:SetAttribute("clickbutton", target)
	end
	button:SetFrameStrata(owner:GetFrameStrata())
	button:SetFrameLevel(math.min(owner:GetFrameLevel() + 20, 10000))
	button:ClearAllPoints()
	button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * k - originX, bottom * k - originY)
	button:SetSize(width * k, height * k)
	button:Show()
	EnsurePoll()
end

local watcher
local polling = false

local function MouseOver(frame)
	return frame and frame.IsMouseOver and frame:IsMouseOver()
end

local function SetInside(entry, inside)
	if entry.inside == inside then
		return
	end
	entry.inside = inside
	local owner = entry.owner
	if inside then
		if owner.LockHighlight then
			owner:LockHighlight()
		end
		entry.onEnter(owner)
		return
	end
	if owner.UnlockHighlight then
		owner:UnlockHighlight()
	end
	entry.onLeave(owner)
	entry.seenOver = nil
	HideProxy(entry)
end

local function Poll()
	local any = false
	for _, entry in pairs(entries) do
		local button = entry.button
		if button and button:IsShown() then
			any = true
			local over = MouseOver(button) or MouseOver(entry.owner)
			if over then
				entry.seenOver = true
				SetInside(entry, true)
			elseif entry.seenOver then
				SetInside(entry, false)
			end
		elseif entry.inside then
			SetInside(entry, false)
		end
	end
	if not any and watcher then
		watcher:SetScript("OnUpdate", nil)
		polling = false
	end
end

function EnsurePoll()
	if polling then
		return
	end
	if not watcher then
		watcher = CreateFrame("Frame")
	end
	polling = true
	watcher:SetScript("OnUpdate", Poll)
end

local function Build(entry)
	local ok, button = pcall(CreateFrame, "Button", nil, UIParent, "SecureActionButtonTemplate")
	if not ok or not button then
		return
	end
	entry.button = button
	button:Hide()
	button:RegisterForClicks(entry.clicks)
	button:SetAttribute("useOnKeyDown", false)
	if entry.macrotext then
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", entry.macrotext)
	else
		button:SetAttribute("type", "click")
	end
end

local function OwnerScript(owner, scriptName)
	return function()
		local handler = owner:GetScript(scriptName)
		if handler then
			handler(owner)
		end
	end
end

--- opts.target(): Blizzard button to Click(). opts.macrotext: secure /slash instead.
--- opts.enabled(): checked on every hover.
--- opts.clicks: RegisterForClicks value, default "AnyUp".
--- opts.onEnter / opts.onLeave: tooltip handlers, default the owner's own scripts.
function Proxy.Attach(owner, opts)
	if not owner or not owner.HookScript or not opts or entries[owner] then
		return
	end
	if not opts.target and type(opts.macrotext) ~= "string" then
		return
	end
	local entry = {
		owner = owner,
		target = opts.target,
		macrotext = opts.macrotext,
		enabled = opts.enabled,
		clicks = opts.clicks or "AnyUp",
		onEnter = opts.onEnter or OwnerScript(owner, "OnEnter"),
		onLeave = opts.onLeave or OwnerScript(owner, "OnLeave"),
	}
	entries[owner] = entry
	owner:HookScript("OnEnter", function()
		Arm(entry)
	end)
	-- The proxy covers the owner, so the owner leaves as soon as it shows.
	owner:HookScript("OnLeave", function()
		C_Timer.After(0, function()
			local button = entry.button
			if button and not button:IsMouseOver() and not owner:IsMouseOver() then
				HideProxy(entry)
			end
		end)
	end)
	if InCombatLockdown() then
		pending[#pending + 1] = entry
	else
		Build(entry)
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
	for i = #pending, 1, -1 do
		Build(pending[i])
		pending[i] = nil
	end
	for _, entry in pairs(entries) do
		local button = entry.button
		if button and not button:IsMouseOver() then
			HideProxy(entry)
		end
	end
end)
