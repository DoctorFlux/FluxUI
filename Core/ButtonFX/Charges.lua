-- ButtonFX/Charges.lua — dual cooldown: GCD/spell swipe + charge recharge edge.
-- Paint the instance (SetCooldown / Clear). Never wrap or replace
-- CooldownFrame_Set — nameplate SetAura calls that helper, and a shared
-- Cooldown hook taints RefreshList → Layout → GetScaledRect.
-- chargeCooldown is created only while recharging and hidden otherwise so it
-- cannot cover Extra Button GCD swipes.
local addonName, ns = ...
local Flux = ns.Flux

local ButtonFX = Flux.ButtonFX or {}
Flux.ButtonFX = ButtonFX

local Charges = {}
ButtonFX.Charges = Charges

local ICON_INSET = 2

--- ActionButtonTemplate.xml: Classic uses a=0.8, Retail uses a=0.64.
--- Match Blizzard's default cooldown transparency per client.
local ACTION_BUTTON_SWIPE_A
if Flux.Client and Flux.Client.isAnyClassic then
	ACTION_BUTTON_SWIPE_A = 0.8
else
	ACTION_BUTTON_SWIPE_A = 0.64
end

-- pcall the function with arguments, never a fresh closure: this runs several
-- times per button per paint and the closures were pure garbage.
local function IsSecretRaw(value)
	local S = Flux.Secrets
	return S and S.IsSecretValue and S.IsSecretValue(value)
end

local function IsSecret(value)
	local ok, secret = pcall(IsSecretRaw, value)
	return ok and secret or false
end

local function SafeNum(value, default)
	local S = Flux.Secrets
	if S and S.SafeGetNumber then
		return S.SafeGetNumber(value, default or 0)
	end
	local ok, n = pcall(tonumber, value)
	if ok and n then
		return n
	end
	return default or 0
end

local function AsDurationObject(value)
	if value == nil then
		return nil
	end
	local t = type(value)
	if t == "table" or t == "userdata" then
		return value
	end
	return nil
end

-- 0 / false = off. Secret / 1 / true / nil = on. Never Lua-compare secrets.
local function CooldownOn(enable)
	if enable == false or enable == 0 then
		return false
	end
	return true
end

local function ClearCD(cd)
	if not cd then
		return
	end
	if cd.Clear then
		cd:Clear()
	elseif cd.SetCooldown then
		cd:SetCooldown(0, 0)
	end
end

local function SetTimer(cd, start, duration, modRate)
	if not cd then
		return
	end
	if cd.SetCooldown then
		if modRate ~= nil then
			pcall(cd.SetCooldown, cd, start, duration, modRate)
		else
			pcall(cd.SetCooldown, cd, start, duration)
		end
		return
	end
	-- Classic-era Cooldown widgets without SetCooldown still use the helper.
	if CooldownFrame_Set then
		pcall(CooldownFrame_Set, cd, start, duration, true, false, modRate)
	end
end

local function HideChargeFrame(cd)
	if not cd then
		return
	end
	if cd.SetDrawBling then
		cd:SetDrawBling(false)
	end
	ClearCD(cd)
	if cd.Hide then
		cd:Hide()
	end
end

local function ShowFrame(cd)
	if cd and cd.Show then
		cd:Show()
	end
end

-- ButtonForge: SetDrawBling only while a real timer is running. Clearing a
-- ready cooldown with bling on plays a 1-frame sparkle on every button.
local function SetBling(cd, on)
	if not cd or not cd.SetDrawBling then
		return
	end
	if not on then
		cd:SetDrawBling(false)
		return
	end
	local alpha = 1
	if cd.GetEffectiveAlpha then
		local a = cd:GetEffectiveAlpha()
		if type(a) == "number" then
			alpha = a
		end
	end
	cd:SetDrawBling(alpha > 0.4)
end

-- ButtonForge Classic: keep the cooldown frame shown when idle. Hide() drops
-- the sibling fill/VFX sit on (main↔mini transfer) and makes drag feel dead.
-- Clear with bling off; do not Hide and do not Show (Show of a cleared swipe
-- was the 1-frame sparkle on every button).
local function IdleHide(cd)
	if not cd then
		return
	end
	SetBling(cd, false)
	ClearCD(cd)
end

-- Midnight duration object only when the numeric timer is unreadable.
-- Ready spells (0, 0) must not pick up a GCD duration object.
local function NeedDurationObject(start, duration)
	if IsSecret(start) or IsSecret(duration) then
		return true
	end
	return AsDurationObject(start) ~= nil or AsDurationObject(duration) ~= nil
end

-- true = cooldown is showing. false = idle/hidden. nil = unknown, keep last.
local function SetCD(cd, start, duration, enable, drawEdge, durationObject, modRate, expirationTime)
	if not cd then
		return false
	end
	if cd.SetDrawEdge then
		cd:SetDrawEdge(drawEdge and true or false)
	end
	if cd.SetDrawSwipe then
		cd:SetDrawSwipe(not drawEdge)
	end
	-- Constant tint; installing it once per frame is enough.
	if not cd._fxSwipeTinted and cd.SetSwipeColor then
		cd._fxSwipeTinted = true
		cd:SetSwipeColor(0, 0, 0, ACTION_BUTTON_SWIPE_A)
	end
	local obj = AsDurationObject(durationObject) or AsDurationObject(duration)
	if obj and cd.SetCooldownFromDurationObject then
		SetBling(cd, true)
		pcall(cd.SetCooldownFromDurationObject, cd, obj)
		ShowFrame(cd)
		return true
	end
	if not CooldownOn(enable) then
		IdleHide(cd)
		return false
	end
	-- Secret start/duration without a duration object. Numeric SetCooldown
	-- blanks. Keep a running charge-edge animation mid-combat.
	if IsSecret(start) or IsSecret(duration) then
		if drawEdge and cd.IsShown and cd:IsShown() then
			return true
		end
		IdleHide(cd)
		return false
	end
	local d = SafeNum(duration, 0)
	local exp = expirationTime and SafeNum(expirationTime, 0) or 0
	if exp > 0 and d > 0 and cd.SetCooldownFromExpirationTime then
		SetBling(cd, true)
		local ok = pcall(cd.SetCooldownFromExpirationTime, cd, exp, d, modRate or 1)
		if ok then
			ShowFrame(cd)
			return true
		end
	end
	local s = SafeNum(start, 0)
	-- Same gate as CooldownFrame_Set: only paint when start > 0 and duration > 0.
	if d <= 0 or s <= 0 then
		IdleHide(cd)
		return false
	end
	SetBling(cd, true)
	SetTimer(cd, s, d, modRate)
	ShowFrame(cd)
	return true
end

-- Only a value we can safely == compare may drive the skip cache. type() never
-- errors on a secret, so gate on it before touching IsSecret.
local function PlainScalar(value)
	local t = type(value)
	if t == "nil" or t == "boolean" then
		return true
	end
	if t ~= "number" then
		return false
	end
	return not IsSecret(value)
end

local function ClearSig(cd)
	if cd then
		cd._fxSigSet = nil
	end
end

-- A running swipe animates in C, so re-sending an identical start/duration is
-- pure waste. Every GCD used to push SetDrawEdge/SetDrawSwipe/SetSwipeColor/
-- SetCooldown through all 57 strip hosts plus every Extra face.
-- Returns: showing, painted.
local function CachedSetCD(cd, start, duration, enable, drawEdge, durationObject, modRate, expirationTime)
	if not cd then
		return false, false
	end
	local cacheable = durationObject == nil
		and PlainScalar(start)
		and PlainScalar(duration)
		and PlainScalar(enable)
		and PlainScalar(modRate)
		and PlainScalar(expirationTime)
	if cacheable and cd._fxSigSet
		and cd._fxSigStart == start
		and cd._fxSigDur == duration
		and cd._fxSigEn == enable
		and cd._fxSigEdge == drawEdge
		and cd._fxSigRate == modRate
		and cd._fxSigExp == expirationTime
	then
		return cd._fxSigShown, false
	end
	local shown = SetCD(cd, start, duration, enable, drawEdge, durationObject, modRate, expirationTime)
	if cacheable then
		cd._fxSigSet = true
		cd._fxSigStart = start
		cd._fxSigDur = duration
		cd._fxSigEn = enable
		cd._fxSigEdge = drawEdge
		cd._fxSigRate = modRate
		cd._fxSigExp = expirationTime
		cd._fxSigShown = shown
	else
		cd._fxSigSet = nil
	end
	return shown, true
end

function Charges.Ensure(widget)
	if not widget then
		return nil
	end
	if widget.chargeCooldown then
		return widget.chargeCooldown
	end
	local ok, cd = pcall(CreateFrame, "Cooldown", nil, widget, "CooldownFrameTemplate")
	if not ok or not cd then
		return nil
	end
	if cd.SetHideCountdownNumbers then
		pcall(cd.SetHideCountdownNumbers, cd, true)
	end
	if cd.SetDrawSwipe then
		pcall(cd.SetDrawSwipe, cd, false)
	end
	if cd.SetDrawEdge then
		pcall(cd.SetDrawEdge, cd, true)
	end
	local icon = widget.icon or widget.Icon
	cd:ClearAllPoints()
	if icon then
		cd:SetPoint("TOPLEFT", icon, "TOPLEFT", ICON_INSET, -ICON_INSET)
		cd:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
	else
		cd:SetPoint("TOPLEFT", widget, "TOPLEFT", ICON_INSET, -ICON_INSET)
		cd:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
	end
	local main = widget.cooldown
	local level = widget.GetFrameLevel and widget:GetFrameLevel() or 0
	if main and main.GetFrameLevel then
		level = main:GetFrameLevel() + 1
	end
	cd:SetFrameLevel(level)
	cd:Hide()
	widget.chargeCooldown = cd
	return cd
end

local function HasChargeTime(start, duration, durationObject)
	if durationObject ~= nil then
		return true
	end
	if AsDurationObject(duration) or AsDurationObject(start) then
		return true
	end
	if IsSecret(start) or IsSecret(duration) then
		return true
	end
	return SafeNum(start, 0) > 0 and SafeNum(duration, 0) > 0
end

-- true = show recharge edge. false = hide. Never Lua-compare secrets.
local function ChargingBody(current, maxCharges, chargeStart, chargeDuration, durationObject)
	if current == nil and maxCharges == nil then
		return HasChargeTime(chargeStart, chargeDuration, durationObject)
	end
	if IsSecret(maxCharges) or IsSecret(current) then
		return HasChargeTime(chargeStart, chargeDuration, durationObject)
	end
	local maxN = SafeNum(maxCharges, 0)
	local curN = SafeNum(current, 0)
	if maxN <= 1 or curN >= maxN then
		return false
	end
	return HasChargeTime(chargeStart, chargeDuration, durationObject)
end

local function IsCharging(current, maxCharges, chargeStart, chargeDuration, durationObject)
	local ok, charging = pcall(ChargingBody, current, maxCharges, chargeStart, chargeDuration, durationObject)
	return ok and charging or false
end

function Charges.Apply(widget, opts)
	opts = opts or {}
	if not widget then
		return
	end
	local main = opts.cooldown or widget.cooldown
	if not main then
		return
	end
	-- Strip hosts pass host.WCooldown, so the widget alone cannot find the
	-- frame again. Remember it for ClearCache.
	widget._fxLastMainCD = main

	local durationObject = AsDurationObject(opts.durationObject)
	if opts.skipDurationObject then
		durationObject = nil
	elseif not durationObject and not opts.itemCooldown and opts.spellId and Flux.Spell and Flux.Spell.GetCooldownDuration then
		if opts.isActive then
			durationObject = Flux.Spell.GetCooldownDuration(opts.spellId)
		elseif NeedDurationObject(opts.start, opts.duration) then
			-- Classic / callers that did not pass isActive: unreadable numbers only.
			durationObject = Flux.Spell.GetCooldownDuration(opts.spellId)
		end
	end

	local chargeDurationObject = AsDurationObject(opts.chargeDurationObject)
	if not chargeDurationObject then
		chargeDurationObject = AsDurationObject(opts.chargeDuration)
	end
	if not chargeDurationObject and opts.chargeIsActive ~= false and opts.spellId
		and Flux.Spell and Flux.Spell.GetChargeDuration then
		chargeDurationObject = Flux.Spell.GetChargeDuration(opts.spellId)
	end

	local charging
	if opts.chargeIsActive == false or opts.chargeIsActive == 0 then
		charging = false
	elseif opts.chargeIsActive then
		-- NeverSecret true: the recharge is running even when counts are secret.
		charging = true
	else
		charging = IsCharging(opts.current, opts.maxCharges, opts.chargeStart, opts.chargeDuration, chargeDurationObject)
	end
	if charging and not chargeDurationObject and not IsSecret(opts.chargeDuration) then
		local chargeDur = SafeNum(opts.chargeDuration, 0)
		if chargeDur > 0 and chargeDur <= 2 then
			charging = false
		end
	end

	local ov = ButtonFX.Overlay
	if ov and ov.HideCooldownCover then
		ov.HideCooldownCover(widget, false)
	end
	widget.hideCooldownFrame = nil
	-- Interrupt chrome sits above the swipe. Always paint so CD and kick
	-- can show together (ShouldHideCooldown must not skip this).
	local showing, painted = CachedSetCD(main, opts.start, opts.duration, opts.enable, false, durationObject, opts.modRate, opts.expirationTime)
	if painted then
		if showing then
			if main.SetDrawSwipe then
				main:SetDrawSwipe(true)
			end
			if main.SetDrawEdge then
				main:SetDrawEdge(false)
			end
		elseif opts.hideWhenIdle and main.Hide then
			main:Hide()
		end
	end

	if charging then
		local chargeCD = Charges.Ensure(widget)
		if chargeCD then
			chargeCD._fxHidden = nil
			local edgeShowing, edgePainted = CachedSetCD(chargeCD, opts.chargeStart, opts.chargeDuration, true, true, chargeDurationObject, opts.chargeModRate)
			if edgePainted and edgeShowing then
				if chargeCD.SetDrawSwipe then
					chargeCD:SetDrawSwipe(false)
				end
				if chargeCD.SetDrawEdge then
					chargeCD:SetDrawEdge(true)
				end
			end
		end
	elseif widget.chargeCooldown and not widget.chargeCooldown._fxHidden then
		-- Unknown (secret counts, no isActive): keep the last recharge edge.
		local knownIdle = opts.chargeIsActive == false or opts.chargeIsActive == 0
		if not knownIdle and (IsSecret(opts.current) or IsSecret(opts.maxCharges)
			or IsSecret(opts.chargeStart) or IsSecret(opts.chargeDuration)) then
			return
		end
		widget.chargeCooldown._fxHidden = true
		ClearSig(widget.chargeCooldown)
		HideChargeFrame(widget.chargeCooldown)
	end
end

function Charges.ClearCache(widget)
	if not widget then
		return
	end
	widget._fxCdStart = nil
	widget._fxCdDur = nil
	widget._fxCdEn = nil
	widget._fxChargeStart = nil
	widget._fxChargeDur = nil
	widget._fxCharging = nil
	ClearSig(widget._fxLastMainCD)
	ClearSig(widget.cooldown)
	ClearSig(widget.chargeCooldown)
	if widget.chargeCooldown then
		widget.chargeCooldown._fxHidden = nil
	end
end
