-- ExtraButtonSystem/Init.lua — FluxBtn facade. Old Engine/*.lua stay unused.
local addonName, ns = ...
local Flux = ns.Flux

local EBS = Flux.EBS or {}
Flux.EBS = EBS

EBS.buttons = EBS.buttons or {}
EBS.badges = EBS.badges or {}
EBS.byWidget = EBS.byWidget or {}
EBS.started = false

local FluxBtn = _G.FluxBtn or {}
_G.FluxBtn = FluxBtn
EBS.Btn = FluxBtn

local FluxButton = _G.FluxButton or {}
FluxButton.__index = FluxButton
_G.FluxButton = FluxButton
EBS.Button = FluxButton
FluxBtn.Button = FluxButton

function EBS.RegisterButton(btn)
	if not btn then
		return
	end
	local list = EBS.buttons
	for i = 1, #list do
		if list[i] == btn then
			return
		end
	end
	list[#list + 1] = btn
	if btn.Widget then
		EBS.byWidget[btn.Widget] = btn
	end
	if EBS.Range and EBS.Range.Sync then
		EBS.Range.Sync()
	end
end

function EBS.UnregisterButton(btn)
	if not btn then
		return
	end
	local list = EBS.buttons
	for i = #list, 1, -1 do
		if list[i] == btn then
			table.remove(list, i)
		end
	end
	if btn.Widget then
		EBS.byWidget[btn.Widget] = nil
	end
	if EBS.Range and EBS.Range.Sync then
		EBS.Range.Sync()
	end
end

function EBS.RegisterBadge(btn)
	if not btn then
		return
	end
	local list = EBS.badges
	for i = 1, #list do
		if list[i] == btn then
			return
		end
	end
	list[#list + 1] = btn
	if btn.Widget then
		EBS.byWidget[btn.Widget] = btn
	end
	if EBS.Range and EBS.Range.Sync then
		EBS.Range.Sync()
	end
end

function EBS.UnregisterBadge(btn)
	if not btn then
		return
	end
	local list = EBS.badges
	for i = #list, 1, -1 do
		if list[i] == btn then
			table.remove(list, i)
		end
	end
	if btn.Widget then
		EBS.byWidget[btn.Widget] = nil
	end
	if EBS.Range and EBS.Range.Sync then
		EBS.Range.Sync()
	end
end

function EBS.ActiveCount()
	return #EBS.buttons
end

function EBS.OccupiedCount()
	local n = 0
	for i = 1, #EBS.buttons do
		local b = EBS.buttons[i]
		if b and b.ActionType and b.ActionValue ~= nil then
			n = n + 1
		end
	end
	return n
end

function FluxBtn.Create(parent, config)
	if EBS.Widget and EBS.Widget.Create then
		return EBS.Widget.Create(parent, config)
	end
	return nil
end

function FluxBtn.Attach(widget, config)
	if EBS.Widget and EBS.Widget.Attach then
		return EBS.Widget.Attach(widget, config)
	end
	return nil
end

FluxBtn.New = FluxBtn.Create

function FluxButton.New(parent, config)
	return FluxBtn.Create(parent, config)
end

function FluxBtn.ApplyStyle(button, scope)
	if EBS.Style and EBS.Style.Apply then
		EBS.Style.Apply(button, scope)
	end
end

function FluxBtn.Register(button)
	EBS.RegisterButton(button)
end

function FluxBtn.Unregister(button)
	EBS.UnregisterButton(button)
end

function FluxBtn.SafeGetItemCount(itemID, includeBank, includeCharges)
	local Inv = Flux.Inventory
	if includeCharges then
		if Inv and Inv.GetLiveCount then
			return Inv.GetLiveCount(itemID, {
				includeBank = includeBank and true or false,
				charges = true,
				bank = includeBank and true or false,
				warband = includeBank and true or false,
			})
		end
		if Flux.Item and Flux.Item.GetCount then
			return Flux.Item.GetCount(itemID, includeBank, true)
		end
		return 0
	end
	if Inv and Inv.GetCount then
		return Inv.GetCount(itemID, {
			bags = true,
			bank = includeBank and true or false,
			warband = includeBank and true or false,
			equipped = false,
			includeBank = includeBank and true or false,
		})
	end
	if Flux.Item and Flux.Item.GetCount then
		return Flux.Item.GetCount(itemID, includeBank, false)
	end
	return 0
end

FluxBtn.Compat = FluxBtn.Compat or {}
function FluxBtn.Compat.After(delay, fn)
	if Flux.Timer and Flux.Timer.After then
		return Flux.Timer.After(delay, fn)
	end
	if C_Timer and C_Timer.After then
		return C_Timer.After(delay, fn)
	end
end

local function HasEbsToken(tokens)
	if not tokens then
		return false
	end
	for key in pairs(tokens) do
		if key == "ebs" or (type(key) == "string" and string.sub(key, 1, 4) == "ebs.") then
			return true
		end
	end
	return false
end

local function HookScheduler()
	if EBS._schedulerHooked then
		return
	end
	EBS._schedulerHooked = true
	Flux.Scheduler.Register("eval", function(tokens)
		if not tokens or not HasEbsToken(tokens) then
			return
		end
		if EBS.Paint and EBS.Paint.FlushEval then
			EBS.Paint.FlushEval(tokens)
		end
	end)
end

function EBS.Start()
	if EBS.started then
		return
	end
	EBS.started = true
	HookScheduler()
	if EBS.Watch and EBS.Watch.Start then
		EBS.Watch.Start()
	end
	if Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.Start then
		Flux.ButtonFX.Cast.Start()
	end
	if EBS.Range and EBS.Range.Start then
		EBS.Range.Start()
	end
	-- Inventory client only: paint counts from Notify. Never Request inventory
	-- from inside Notify (that re-armed the inventory tier every frame).
	if Flux.Inventory and Flux.Inventory.Register then
		-- Count paint: must stay in the same frame as the refresh, but only for
		-- item regions. It used to repaint on currency / guild / mail pulses too.
		Flux.Inventory.Register("ebs", function(ctx)
			if EBS.Paint and EBS.Paint.FlushCounts then
				EBS.Paint.FlushCounts(ctx)
			end
		end, {
			tier = "instant",
			regions = { "bags", "bank", "warband", "equip" },
			sync = true,
		})
	end
	if EBS.Paint and EBS.Paint.FlushEval then
		EBS.Paint.FlushEval({ ebs = true })
	end
	if EBS.Paint and EBS.Paint.UpdateAllCooldowns then
		EBS.Paint.UpdateAllCooldowns()
	end
	if EBS.Range and EBS.Range.Sync then
		EBS.Range.Sync()
	end
end

Flux.Module.Register("ExtraButtons", {
	clients = { era = true, anniversary = true, classic = true, midnight = true },
	OnEnable = function()
		EBS.Start()
	end,
})

local function yn(v)
	return v and "yes" or "no"
end

SLASH_FLUXEBS1 = "/fluxebs"
SlashCmdList["FLUXEBS"] = function()
	local rangeOn = EBS.Range and EBS.Range.IsArmed and EBS.Range.IsArmed()
	local src = Flux.Inventory and Flux.Inventory.GetSource and Flux.Inventory.GetSource() or "none"
	Flux.Print("ExtraButtons")
	print("  enabled=" .. yn(Flux.Module and Flux.Module.IsEnabled and Flux.Module.IsEnabled("ExtraButtons"))
		.. " buttons=" .. tostring(EBS.ActiveCount())
		.. " occupied=" .. tostring(EBS.OccupiedCount()))
	print("  rangeTicker=" .. yn(rangeOn)
		.. " inventory=" .. tostring(src))
	local fx = Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.Debug and Flux.ButtonFX.Cast.Debug()
	if fx then
		print("  vfx started=" .. yn(fx.started)
			.. " armed=" .. yn(fx.armed)
			.. " entries=" .. tostring(fx.entries)
			.. " last=" .. tostring(fx.lastEvent)
			.. " spell=" .. tostring(fx.lastSpell))
	end
end
