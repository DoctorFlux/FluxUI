-- NamePlates/Countdown.lua — nameplate aura countdown digits at a pinned size.
-- Size: FLUX_NAMEPLATE_AURA_COUNTDOWN_SCALE of a 16px base (0.75 = 12px on every client).
-- A Flux text host sits over each aura cooldown. Blizzard digits are faded with
-- SetTextColor alpha only after Flux has a label; never SetFont / SetScale /
-- SetCountdownFont on Blizzard aura text.
-- Type decorations share the aura traversal and add artwork on a Flux host.
-- The Settings preview plate is skipped (it is not a world plate).
local addonName, ns = ...
local Flux = ns.Flux
local NP = Flux.NamePlates
local Aura = Flux.Aura

local Countdown = NP.RegisterModule("countdown", { interval = 0.1 })

local FLUX_NAMEPLATE_AURA_COUNTDOWN_SCALE = 0.75
local FLUX_NAMEPLATE_AURA_COUNTDOWN_BASE_PX = 16
local MAX_DURATION_SEC = 60

local hosts = setmetatable({}, { __mode = "k" })
local visited = setmetatable({}, { __mode = "k" })
local muted
local visit = 0
local dispelTypes = setmetatable({}, { __mode = "k" })
local typeHosts = setmetatable({}, { __mode = "k" })
local auraSources = setmetatable({}, { __mode = "k" })
local visibleLists = setmetatable({}, { __mode = "k" })
local listOwners = setmetatable({}, { __mode = "k" })
local RETRY_TYPE_AFTER = .3
local PLAYER_DEBUFF_FILTER = "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY"
local observedAuraIDs, ownership, filteredItems
local hookedSetAura
local hookedRefreshList

local function Readable(value)
	-- Some branches omit auraInstanceID, dispelName, and the lane source flag.
	if value == nil then return true end
	return not NP.IsSecret(value) and (not canaccessvalue or canaccessvalue(value))
end

local function ReadableAura(data)
	if not Readable(data) or type(data) ~= "table" then return false end
	local secrets = Flux.Secrets
	return not secrets or not secrets.CanAccessTable or secrets.CanAccessTable(data)
end

local function ReadDispelType(data)
	if not ReadableAura(data) then return end
	if NP.BoolTest(data.isHelpful, false) or (Readable(data.isHarmful) and data.isHarmful == false) then
		return false
	end
	local kind = data.dispelName
	if not Readable(kind) then return end
	if kind == nil or kind == "" or kind == "None" then return "None" end
	return Aura.NormalizeDispelType(kind)
end

local function ObserveAura(item, data)
	if not Readable(item) or not item then return end
	-- Parenthood is established after SetAura. Validate the native lane when
	-- painting, since this observer also sees helpful and preview items.
	dispelTypes[item] = ReadDispelType(data)
	local source = auraSources[item]
	if source then source.unit, source.id, source.kind = nil, nil, nil end
	if observedAuraIDs then
		local id = ReadableAura(data) and data.auraInstanceID
		observedAuraIDs[item] = type(id) == "number" and NP.IsUsable(id) and id or nil
	end
	if ownership then ownership[item] = nil end
end

local function ObserveList(_, listFrame)
	if Readable(listFrame) and listFrame then visibleLists[listFrame] = nil end
end

-- Forever's native item doesn't retain the aura instance ID. Observe its
-- existing assignment with a secure post-hook and cache only the public type.
if Aura and hooksecurefunc and NamePlateAuraItemMixin and NamePlateAuraItemMixin.SetAura then
	if pcall(hooksecurefunc, NamePlateAuraItemMixin, "SetAura", ObserveAura) then
		hookedSetAura = NamePlateAuraItemMixin.SetAura
	end
end
if Aura and hooksecurefunc and NamePlateAurasMixin and NamePlateAurasMixin.RefreshList then
	if pcall(hooksecurefunc, NamePlateAurasMixin, "RefreshList", ObserveList) then
		hookedRefreshList = NamePlateAurasMixin.RefreshList
	end
end

local function GetCountdownSettings()
	local saved = FluxUI_DB
	local appearance = type(saved) == "table" and saved.nameplateAppearance
	local placement = type(appearance) == "table" and rawget(appearance, "auraCountdown")
	if placement ~= "bottom" and placement ~= "below" and placement ~= "none" then
		placement = "middle"
	end
	local pixels = type(appearance) == "table" and tonumber(rawget(appearance, "countdownSize"))
	if type(pixels) ~= "number" or pixels ~= pixels then
		pixels = FLUX_NAMEPLATE_AURA_COUNTDOWN_BASE_PX * FLUX_NAMEPLATE_AURA_COUNTDOWN_SCALE
	end
	local onlyMine = type(appearance) == "table" and rawget(appearance, "onlyMyDebuffs") == true
	if onlyMine then
		observedAuraIDs = observedAuraIDs or setmetatable({}, { __mode = "k" })
	else
		observedAuraIDs, ownership = nil, nil
	end
	return placement, math.max(8, math.min(24, math.floor(pixels + 0.5))), onlyMine
end

local function CanUseObject(obj)
	if not obj then
		return false
	end
	if obj.CanBeAccessedInContext then
		local ok, allowed = pcall(obj.CanBeAccessedInContext, obj)
		if not ok or not NP.BoolTest(allowed, false) then
			return false
		end
	end
	return true
end

local function IsShownSafe(frame)
	if not frame or not frame.IsShown then
		return false
	end
	local ok, shown = pcall(frame.IsShown, frame)
	return ok and NP.BoolTest(shown, false) or false
end

local function IsAuraVisible(frame)
	if not frame.IsVisible then return IsShownSafe(frame) end
	local ok, shown = pcall(frame.IsVisible, frame)
	return ok and NP.BoolTest(shown, false)
end

local function GetBlizzardDigits(cooldown)
	if cooldown.GetCountdownFontString then
		local ok, fs = pcall(cooldown.GetCountdownFontString, cooldown)
		if ok and fs then
			return fs
		end
	end
	if cooldown.GetRegions then
		local regions = { pcall(cooldown.GetRegions, cooldown) }
		for i = 2, #regions do
			local r = regions[i]
			if r and r.GetObjectType and r:GetObjectType() == "FontString" then
				return r
			end
		end
	end
	return nil
end

local function SetBlizzardDigitsAlpha(cooldown, alpha, fs)
	fs = fs or (cooldown and GetBlizzardDigits(cooldown))
	if fs and fs.SetTextColor then
		pcall(fs.SetTextColor, fs, 1, 1, 1, alpha)
	end
end

local function DigitColor(digits)
	if not CanUseObject(digits) or not digits.GetTextColor or not digits.SetTextColor then return end
	local ok, r, g, b, a = pcall(digits.GetTextColor, digits)
	if ok and NP.IsUsable(r) and NP.IsUsable(g) and NP.IsUsable(b) and NP.IsUsable(a) then
		return r, g, b, a
	end
end

local function RestoreMuted(auraItem, held)
	local r, g, b, a = DigitColor(held.digits)
	if r == nil then return false end
	-- A native update or another addon may already own the current presentation.
	if r == held.r and g == held.g and b == held.b and a == 0
		and not pcall(held.digits.SetTextColor, held.digits, r, g, b, held.alpha) then return false end
	muted[auraItem] = nil
	return true
end

local function MuteDigits(auraItem, unit, digits, replacesFluxText)
	local held = muted and muted[auraItem]
	if held and (held.unit ~= unit or held.digits ~= digits) then
		if not RestoreMuted(auraItem, held) then return end
		held = nil
	end
	local r, g, b, a = DigitColor(digits)
	if r == nil then return end
	if a == 0 then
		if held and r == held.r and g == held.g and b == held.b then return end
		if held then muted[auraItem] = nil end
		-- The published Flux overlay already sets white digits to alpha zero while its label is visible.
		if not replacesFluxText or r ~= 1 or g ~= 1 or b ~= 1 then return end
		a = 1
	elseif not pcall(digits.SetTextColor, digits, r, g, b, 0) then
		return
	end
	muted = muted or setmetatable({}, { __mode = "k" })
	held = held or {}
	held.unit, held.digits = unit, digits
	held.r, held.g, held.b, held.alpha = r, g, b, a
	muted[auraItem] = held
end

local function FormatRemaining(remain)
	if remain >= 10 then
		return string.format("%d", math.floor(remain))
	end
	return string.format("%.1f", remain)
end

--- Blizzard's own countdown text (may be a secret string; SetText accepts it),
--- else a label from GetCooldownTimes when those numbers are readable.
local function ReadLabel(cooldown, fs)
	if fs and fs.GetText then
		local ok, txt = pcall(fs.GetText, fs)
		if ok then
			if NP.IsSecret(txt) then
				return txt
			end
			if type(txt) == "string" and txt ~= "" then
				return txt
			end
		end
	end
	if not cooldown.GetCooldownTimes then
		return nil
	end
	local ok, start, duration = pcall(cooldown.GetCooldownTimes, cooldown)
	if not ok or not NP.IsUsable(start) or not NP.IsUsable(duration) then
		return nil
	end
	start, duration = tonumber(start), tonumber(duration)
	if not start or not duration or duration <= 0 then
		return nil
	end
	if duration > 1000 or start > 100000 then
		start, duration = start / 1000, duration / 1000
	end
	if duration > MAX_DURATION_SEC then
		return nil
	end
	local remain = start + duration - GetTime()
	if remain <= 0 then
		return nil
	end
	return FormatRemaining(remain)
end

local function EnsureHost(auraItem, fontSize)
	local host = hosts[auraItem]
	if host then
		return host
	end
	host = NP.CreateHost(28, 18)
	local text = host:CreateFontString(nil, "OVERLAY")
	text:SetFont(NP.FONT, fontSize, "OUTLINE")
	host._fluxFontSize = fontSize
	text:SetPoint("CENTER", host, "CENTER", 0, 0)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	text:SetTextColor(1, 1, 1, 1)
	host.text = text
	hosts[auraItem] = host
	return host
end

local function HideHost(auraItem, cooldown, digits)
	local host = hosts[auraItem]
	if host then
		host:Hide()
	end
	local held = muted and muted[auraItem]
	if held then RestoreMuted(auraItem, held)
	else SetBlizzardDigitsAlpha(cooldown, 1, digits) end
end

local function HostLevel(plate, auraItem, cooldown)
	local level, parentLevel = 0, nil
	local ok, n = pcall(plate.GetFrameLevel, plate)
	if ok and type(n) == "number" and not NP.IsSecret(n) then
		parentLevel = n
		if n > level then level = n end
	end
	ok, n = pcall(auraItem.GetFrameLevel, auraItem)
	if ok and type(n) == "number" and not NP.IsSecret(n) and n > level then
		level = n
	end
	if cooldown then
		ok, n = pcall(cooldown.GetFrameLevel, cooldown)
		if ok and type(n) == "number" and not NP.IsSecret(n) and n > level then
			level = n
		end
	end
	return level + NP.FRAME_LEVEL_OFFSET, parentLevel
end

-- Forever assigns layoutIndex from a sorted native lane and doesn't retain
-- the auraInstanceID on the icon. Recover the exact displayed slot using
-- the same source gate that Blizzard's RefreshList uses for that lane.
local function CollectVisibleTypes(priority, lane)
	local localOnly, limit = lane.requireSourceIsLocalPlayer, lane.maxAuraItemsDisplayed
	if not Readable(localOnly) or not Readable(limit) or type(limit) ~= "number" or limit < 1 then return end
	local types, valid = {}, true
	local ok = pcall(priority.Iterate, priority, function(_, data)
		local readable = ReadableAura(data)
		if localOnly == true then
			if not readable or not Readable(data.sourceUnit) then valid = false; return true end
			local caster = data.sourceUnit
			if not caster then return false end
			local own, pet = UnitIsUnit("player", caster), UnitIsUnit("pet", caster)
			if not (NP.BoolTest(own, false) or NP.BoolTest(pet, false)) then
				if not (Readable(own) and Readable(pet)) then valid = false; return true end
				return false
			end
		end
		local spell = readable and data.spellId
		local kind
		if readable then kind = ReadDispelType(data) end
		types[#types + 1] = {
			spell = Readable(spell) and spell or nil,
			kind = kind,
		}
		return #types >= limit
	end)
	if ok and valid then return types end
end

local function GetVisibleType(item, unit, auras, lane, priority, now)
	local slot, spell, owner = item.layoutIndex, item.spellID, auras.unitToken
	if not (priority and priority.Iterate and Readable(slot) and type(slot) == "number"
		and Readable(spell) and type(spell) == "number" and Readable(owner) and owner == unit) then return end
	local observesRefresh = listOwners[auras]
	if observesRefresh == nil then
		local method = auras.RefreshList
		observesRefresh = hookedRefreshList and method == hookedRefreshList or false
		if not observesRefresh and hooksecurefunc and method then
			observesRefresh = pcall(hooksecurefunc, auras, "RefreshList", ObserveList)
		end
		listOwners[auras] = observesRefresh
	end
	local cached = visibleLists[lane]
	local combat = InCombatLockdown and InCombatLockdown()
	if not cached or cached.unit ~= unit or cached.priority ~= priority or cached.combat ~= combat
		or ((not cached.types or not observesRefresh) and now >= cached.retryAt) then
		cached = { unit = unit, priority = priority, combat = combat, retryAt = now + RETRY_TYPE_AFTER,
			types = CollectVisibleTypes(priority, lane) }
		visibleLists[lane] = cached
	end
	local entry = cached.types and cached.types[slot]
	if entry and entry.spell == spell then return entry.kind end
end

local function GetDispelType(item, unit, auras, lane)
	local seen = dispelTypes[item]
	if seen ~= nil then return seen end
	local id = item.auraInstanceID
	local source = auraSources[item]
	if not source then
		local setAura = item.SetAura
		local observes = hookedSetAura and setAura == hookedSetAura
		if not observes and hooksecurefunc and setAura then
			observes = pcall(hooksecurefunc, item, "SetAura", ObserveAura)
		end
		source = { observes = observes }
		auraSources[item] = source
	end
	local now = GetTime()
	local getByID = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
	if getByID and Readable(id) and type(id) == "number" then
		local combat = InCombatLockdown and InCombatLockdown()
		if source.unit ~= unit or source.id ~= id or source.combat ~= combat
			or (source.kind == nil and now >= source.retryAt) then
			-- Public IDs remain queryable on some restricted units. Guard the
			-- returned aura rather than gating all reads on secret access.
			local ok, data = pcall(getByID, unit, id)
			source.unit, source.id, source.combat = unit, id, combat
			source.retryAt = now + RETRY_TYPE_AFTER
			source.kind = nil
			if ok then source.kind = ReadDispelType(data) end
		end
		return source.kind
	end
	if lane == auras.LossOfControlFrame then
		local owner, spell = auras.unitToken, item.spellID
		if not (Readable(owner) and owner == unit and Readable(spell) and type(spell) == "number"
			and auras.GetLossOfControlAura) then return end
		local combat = InCombatLockdown and InCombatLockdown()
		if source.unit ~= unit or source.spell ~= spell or source.combat ~= combat
			or ((source.kind == nil or not source.observes) and now >= source.retryAt) then
			local ok, data = pcall(auras.GetLossOfControlAura, auras)
			source.unit, source.id, source.combat, source.spell = unit, nil, combat, spell
			source.retryAt = now + RETRY_TYPE_AFTER
			source.kind = nil
			if ok and ReadableAura(data) and Readable(data.spellId) and data.spellId == spell then
				source.kind = ReadDispelType(data)
			end
		end
		return source.kind
	end
	local priority
	if lane == auras.DebuffListFrame then priority = auras.debuffList
	else priority = auras.crowdControlList end
	if ReadableAura(priority) then return GetVisibleType(item, unit, auras, lane, priority, now) end
end

local function AnchorTypeHost(host, anchor)
	host:ClearAllPoints()
	return pcall(host.SetPoint, host, "TOPLEFT", anchor, "TOPLEFT", 0, 0)
		and pcall(host.SetPoint, host, "BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
end

local function CanUseTooltip(tip)
	if not tip then return false end
	if not tip.IsForbidden then return true end
	local ok, forbidden = pcall(tip.IsForbidden, tip)
	return ok and not NP.BoolTest(forbidden, true)
end

local function CloseAuraTooltip(host)
	local tip = GameTooltip
	if CanUseTooltip(tip) and tip.IsOwned then
		local ok, owned = pcall(tip.IsOwned, tip, host)
		if ok and NP.BoolTest(owned, false) then pcall(tip.Hide, tip) end
	end
end

local function IsPlayerDebuff(item, unit)
	local id = item.auraInstanceID
	if type(id) ~= "number" or not NP.IsUsable(id) then id = observedAuraIDs and observedAuraIDs[item] end
	local filter = C_UnitAuras and C_UnitAuras.IsAuraFilteredOutByInstanceID
	if not (id and filter) then return false end
	local combat = InCombatLockdown and InCombatLockdown()
	local now = GetTime()
	local cached = ownership and ownership[item]
	if not cached or cached.unit ~= unit or cached.id ~= id or cached.combat ~= combat
		or (cached.matches == nil and now >= cached.retryAt) then
		local ok, excluded = pcall(filter, unit, id, PLAYER_DEBUFF_FILTER)
		local matches
		if ok and type(excluded) == "boolean" and NP.IsUsable(excluded) then matches = not excluded end
		ownership = ownership or setmetatable({}, { __mode = "k" })
		cached = { unit = unit, id = id, combat = combat, matches = matches, retryAt = now + RETRY_TYPE_AFTER }
		ownership[item] = cached
	end
	return cached.matches == true
end

local function RestoreFilteredItem(item)
	local held = filteredItems and filteredItems[item]
	if not held or not CanUseObject(item) then return end
	local ok, alpha = pcall(item.GetAlpha, item)
	if not ok or not NP.IsUsable(alpha) then return end
	if alpha == 0 and not pcall(item.SetAlpha, item, held.alpha) then return end
	if held.motion then
		local read, moving = pcall(item.IsMouseMotionEnabled, item)
		if not read or not NP.IsUsable(moving) then return end
		if moving == false and not pcall(item.SetMouseMotionEnabled, item, true) then return end
	end
	filteredItems[item] = nil
end

local function ConcealFilteredItem(item, unit)
	local held = filteredItems and filteredItems[item]
	local ok, alpha = pcall(item.GetAlpha, item)
	if not ok or type(alpha) ~= "number" or not NP.IsUsable(alpha) then return end
	if alpha > 0 then
		if not pcall(item.SetAlpha, item, 0) then return end
		if held then held.alpha = alpha end
	end
	held = held or { alpha = alpha }
	held.unit = unit
	if item.IsMouseMotionEnabled and item.SetMouseMotionEnabled then
		local read, moving = pcall(item.IsMouseMotionEnabled, item)
		if read and NP.BoolTest(moving, false) and pcall(item.SetMouseMotionEnabled, item, false) then
			held.motion = true
			CloseAuraTooltip(item)
		end
	end
	filteredItems = filteredItems or setmetatable({}, { __mode = "k" })
	filteredItems[item] = held
end

local function SetupStockHover(view, item)
	local client = Flux.Client
	local host = view.host
	local motion = host.SetMouseMotionEnabled or host.EnableMouseMotion
	if not (client and (client.isForever or client.isCamelot) and motion and host.SetMouseClickEnabled) then return end
	-- Forever's plain nameplate aura frame has no intrinsic tooltip handler.
	-- Stock frames on the other supported clients already own their hover.
	motion(host, true)
	host:SetMouseClickEnabled(false)
	host:SetScript("OnEnter", function(self)
		local tip, spell = GameTooltip, item.spellID
		if not (CanUseTooltip(tip) and tip.SetSpellByID and view.unit and NP.activeUnits[view.unit]
			and IsAuraVisible(item) and type(spell) == "number" and NP.IsUsable(spell) and spell > 0) then return end
		if not pcall(tip.SetOwner, tip, self, "ANCHOR_BOTTOMLEFT") then return end
		local ok, shown = pcall(tip.SetSpellByID, tip, spell)
		if not ok or shown == false or not pcall(tip.Show, tip) then CloseAuraTooltip(self) end
	end)
	host:SetScript("OnLeave", CloseAuraTooltip)
	host:SetScript("OnHide", CloseAuraTooltip)
	view.hasHover = true
end

local function RestoreTexture(view, key)
	local held = view[key]
	if not held then return true end
	local region = held.region
	local ok, alpha = pcall(region.GetAlpha, region)
	if not ok or not NP.IsUsable(alpha) then return false end
	if alpha == 0 and not pcall(region.SetAlpha, region, held.alpha) then return false end
	view[key] = nil
	return true
end

local function MuteTexture(view, key, region)
	if not region or not region.GetAlpha or not region.SetAlpha then return false end
	local held = view[key]
	if held and held.region ~= region and not RestoreTexture(view, key) then return false end
	local ok, alpha = pcall(region.GetAlpha, region)
	if not ok or not NP.IsUsable(alpha) then return false end
	if alpha == 0 then return view[key] ~= nil end
	if not pcall(region.SetAlpha, region, 0) then return false end
	view[key] = { region = region, alpha = alpha }
	return true
end

local function GetStockRim(item)
	local regions = { pcall(item.GetRegions, item) }
	if not regions[1] then return end
	for i = 2, #regions do
		local region = regions[i]
		if region and region.GetAtlas then
			local ok, atlas = pcall(region.GetAtlas, region)
			if ok and type(atlas) == "string" and NP.IsUsable(atlas)
				and atlas:lower() == "ui-hud-cooldownmanager-iconoverlay" then return region end
		end
	end
end

local function HideAuraStyle(view)
	if not view then return end
	if view.host:IsShown() then view.host:Hide() end
	if view.artHost and view.artHost:IsShown() then view.artHost:Hide() end
	RestoreTexture(view, "mutedIcon")
	RestoreTexture(view, "mutedRim")
end

local function UpdateStockArtwork(view, item, plate, width, level)
	if view.stockRim == nil then view.stockRim = GetStockRim(item) or false end
	MuteTexture(view, "mutedRim", view.stockRim)
	local icon = item.Icon
	local ok, texture
	if icon and icon.GetTexture then ok, texture = pcall(icon.GetTexture, icon) end
	if icon and icon.GetTextureFileID and (not ok or not NP.IsUsable(texture)) then
		ok, texture = pcall(icon.GetTextureFileID, icon)
	end
	if not ok or not NP.IsUsable(texture) or (type(texture) ~= "number" and type(texture) ~= "string") then
		if view.artHost and view.artHost:IsShown() then view.artHost:Hide() end
		RestoreTexture(view, "mutedIcon")
		return
	end
	if not view.artHost then
		view.artHost = NP.CreateHost(1, 1)
		view.image = Aura.CreateNameplateAuraArt(view.artHost)
	end
	local host = view.artHost
	if view.artUnit ~= view.unit then
		if not pcall(host.SetParent, host, plate) or not AnchorTypeHost(host, item) then return end
		view.artUnit, view.artLevel = view.unit, nil
	end
	if view.artWidth ~= width then
		Aura.LayoutNameplateAuraArt(view.image, host, width)
		view.artWidth = width
	end
	if view.texture ~= texture then
		view.image:SetTexture(texture)
		view.texture = texture
	end
	if view.artLevel ~= level then
		if not pcall(host.SetFrameLevel, host, level) then
			host:Hide()
			RestoreTexture(view, "mutedIcon")
			return
		end
		view.artLevel = level
	end
	if MuteTexture(view, "mutedIcon", icon) then host:Show() else host:Hide() end
end

local function UpdateDispelType(item, cooldown, plate, unit, auras, lane)
	local view = typeHosts[item]
	if not lane then
		local ok, parent = pcall(item.GetParent, item)
		if ok and Readable(parent) then lane = parent end
	end
	local lossOfControl = auras.LossOfControlFrame
	local isDebuff = lane
		and (lane == auras.DebuffListFrame or lane == auras.CrowdControlListFrame
			or (lane == lossOfControl and lossOfControl.AuraItemFrame == item))
	local isBuff = lane and lane == auras.BuffListFrame
	if not (isDebuff or isBuff) or not IsAuraVisible(item) then
		HideAuraStyle(view)
		return
	end
	local kind = "Buff"
	if isDebuff then kind = GetDispelType(item, unit, auras, lane) end
	if kind == false then
		HideAuraStyle(view)
		return
	end
	-- A visible harmful lane is enough for the general border. Only an exact,
	-- readable type is enough to paint a type-specific color and corner icon.
	kind = kind or "None"
	if not view then
		local host = NP.CreateHost(1, 1)
		view = { host = host, border = Aura.CreateNameplateAuraBorder(host), glyph = Aura.CreateDispelTypeIcon(host) }
		SetupStockHover(view, item)
		typeHosts[item] = view
	end
	local host = view.host
	if view.unit ~= unit or host:GetParent() ~= plate then
		HideAuraStyle(view)
		if not pcall(host.SetParent, host, plate) or (not AnchorTypeHost(host, item)
			and not (cooldown and AnchorTypeHost(host, cooldown))) then
			return
		end
		view.unit, view.level, view.artUnit = unit, nil, nil
	end
	if view.kind ~= kind then
		local r, g, b = Aura.GetNameplateAuraColor(kind)
		view.border:SetVertexColor(r, g, b, 1)
		Aura.SetDispelTypeIcon(view.glyph, kind)
		view.kind = kind
	end
	local ok, width = pcall(item.GetWidth, item)
	width = ok and not NP.IsSecret(width) and type(width) == "number" and width > 0 and width or 18
	if view.width ~= width then
		Aura.LayoutDispelTypeIcon(view.glyph, host, width)
		view.width = width
	end
	local level, parentLevel = HostLevel(plate, item, cooldown)
	UpdateStockArtwork(view, item, plate, width, math.max(0, level - NP.FRAME_LEVEL_OFFSET - (cooldown and 1 or 0)))
	if view.hasHover then
		local spell = item.spellID
		if type(spell) ~= "number" or not NP.IsUsable(spell) then spell = nil end
		if view.spell ~= spell then CloseAuraTooltip(host); view.spell = spell end
	end
	if view.level ~= level and pcall(host.SetFrameLevel, host, level) then view.level = level end
	host:Show()
	return level, parentLevel
end

local function UpdateAuraItem(auraItem, plate, unit, placement, fontSize, auras, lane, covered, onlyMine)
	if not auraItem or visited[auraItem] == visit then return end
	visited[auraItem] = visit
	local cooldown = auraItem.Cooldown
	local shown = not covered and CanUseObject(auraItem) and IsShownSafe(auraItem)
	local filtered = onlyMine and shown and not IsPlayerDebuff(auraItem, unit)
	if filtered then ConcealFilteredItem(auraItem, unit)
	elseif filteredItems then RestoreFilteredItem(auraItem) end
	if covered or filtered then
		local view, host = typeHosts[auraItem], hosts[auraItem]
		HideAuraStyle(view)
		if (host and host:IsShown()) or (muted and muted[auraItem]) then HideHost(auraItem, cooldown) end
		return
	end
	local canUseCooldown = cooldown and CanUseObject(cooldown)
	local level, parentLevel
	if Aura and shown then
		level, parentLevel = UpdateDispelType(auraItem, canUseCooldown and cooldown, plate, unit, auras, lane)
	else
		HideAuraStyle(typeHosts[auraItem])
	end
	if not canUseCooldown or not shown then
		if placement == "none" and not (muted and muted[auraItem]) then
			local host = hosts[auraItem]
			if host then host:Hide() end
		else HideHost(auraItem, cooldown) end
		return
	end
	-- Use the current region for the overlay. Off tracks only the digits it muted for later restoration.
	local digits = GetBlizzardDigits(cooldown)
	if placement == "none" then
		local host = hosts[auraItem]
		local replacesFluxText = host and host:IsShown()
		if host then host:Hide() end
		MuteDigits(auraItem, unit, digits, replacesFluxText)
		return
	end
	local label = ReadLabel(cooldown, digits)
	if label == nil then
		HideHost(auraItem, cooldown, digits)
		return
	end
	local held = muted and muted[auraItem]
	if held and not RestoreMuted(auraItem, held) then return end

	local host = EnsureHost(auraItem, fontSize)
	if host._fluxFontSize ~= fontSize and pcall(host.text.SetFont, host.text, NP.FONT, fontSize, "OUTLINE") then
		host._fluxFontSize = fontSize
	end
	-- Only Flux-owned output is cached. Native text/regions and frame levels
	-- are still read at every original deadline, including replacement/reuse.
	local secret = NP.IsSecret(label)
	if secret or host._fluxLabel ~= label then
		local ok = pcall(host.text.SetText, host.text, label)
		host._fluxLabel = ok and not secret and label or nil
		if not ok then
			HideHost(auraItem, cooldown, digits)
			return
		end
	end
	if host:GetParent() ~= plate then
		host._fluxAnchor = nil
		host._fluxLevel, host._fluxParentLevel = nil, nil
		if not pcall(host.SetParent, host, plate) then
			HideHost(auraItem, cooldown, digits)
			return
		end
	end
	local y = placement == "bottom" and math.floor(host._fluxFontSize / 2) + 1 or placement == "below" and -1 or 0
	if host._fluxAnchor ~= cooldown or host._fluxPlacement ~= placement or host._fluxOffset ~= y then
		host:ClearAllPoints()
		local point = placement == "below" and "TOP" or "CENTER"
		local anchor = placement == "middle" and "CENTER" or "BOTTOM"
		if not pcall(host.SetPoint, host, point, cooldown, anchor, 0, y) then
			HideHost(auraItem, cooldown, digits)
			return
		end
		host._fluxAnchor, host._fluxPlacement, host._fluxOffset = cooldown, placement, y
	end
	if not level then level, parentLevel = HostLevel(plate, auraItem, cooldown) end
	if not parentLevel or host._fluxLevel ~= level or host._fluxParentLevel ~= parentLevel then
		if pcall(host.SetFrameLevel, host, level) then
			host._fluxLevel, host._fluxParentLevel = level, parentLevel
		end
	end
	host:Show()
	SetBlizzardDigitsAlpha(cooldown, 0, digits)
end

local function IsAuraItem(frame)
	return type(frame) == "table" and (frame.Cooldown or (Aura and frame.Icon))
end

local function UpdateList(listFrame, plate, unit, placement, fontSize, auras, covered, onlyMine)
	if not listFrame or not listFrame.GetChildren then
		return
	end
	local children = { pcall(listFrame.GetChildren, listFrame) }
	for i = 2, #children do
		local child = children[i]
		if IsAuraItem(child) then
			UpdateAuraItem(child, plate, unit, placement, fontSize, auras, listFrame, covered, onlyMine)
		end
	end
end

local function UpdatePool(pool, plate, unit, placement, fontSize, auras, coveredDebuff, coveredCC, onlyMine)
	if not pool or not pool.EnumerateActive then
		return
	end
	for a, b in pool:EnumerateActive() do
		local frame = IsAuraItem(a) and a or IsAuraItem(b) and b
		if frame and visited[frame] ~= visit then
			local lane
			if coveredDebuff or coveredCC or onlyMine then
				local ok, parent = pcall(frame.GetParent, frame)
				if ok and Readable(parent) then lane = parent end
			end
			local covered = lane and (lane == coveredDebuff or lane == coveredCC)
			local harmful = onlyMine and lane and (lane == auras.DebuffListFrame
				or lane == auras.CrowdControlListFrame or lane == auras.LossOfControlFrame)
			UpdateAuraItem(frame, plate, unit, placement, fontSize, auras, lane, covered, harmful)
		end
	end
end

local function UpdatePlate(unit, placement, fontSize, onlyMine)
	visit = visit + 1
	local uf, plate = NP.GetParts(unit)
	local auras = uf and uf.AurasFrame
	local secure = NP.SecureAuras
	if not auras then
		if secure then secure.Release(unit) end
		return
	end
	if not placement then placement, fontSize, onlyMine = GetCountdownSettings() end
	local ownsDebuff, ccLane
	if secure then ownsDebuff, ccLane = secure.Update(plate, unit, auras, placement, fontSize, onlyMine) end
	UpdateList(auras.DebuffListFrame, plate, unit, placement, fontSize, auras, ownsDebuff, onlyMine)
	UpdateList(auras.BuffListFrame, plate, unit, placement, fontSize, auras)
	UpdateList(auras.CrowdControlListFrame, plate, unit, placement, fontSize, auras,
		ccLane ~= nil and ccLane == auras.CrowdControlListFrame, onlyMine)
	local lossOfControl = auras.LossOfControlFrame
	UpdateAuraItem(lossOfControl and lossOfControl.AuraItemFrame, plate, unit, placement, fontSize, auras,
		lossOfControl, ccLane ~= nil and ccLane == lossOfControl, onlyMine)
	UpdatePool(auras.auraItemFramePool, plate, unit, placement, fontSize, auras,
		ownsDebuff and auras.DebuffListFrame, ccLane, onlyMine)
end

local function HideStale(unit)
	if filteredItems then
		for item, held in pairs(filteredItems) do
			if held.unit == unit or not NP.activeUnits[held.unit] or not IsAuraVisible(item) then
				RestoreFilteredItem(item)
			end
		end
		if not next(filteredItems) then filteredItems = nil end
	end
	for auraItem, host in pairs(hosts) do
		if host:IsShown() and not IsShownSafe(auraItem) then
			host:Hide()
		end
	end
	for auraItem, view in pairs(typeHosts) do
		if view.unit and (view.unit == unit or not NP.activeUnits[view.unit] or not IsAuraVisible(auraItem)) then
			HideAuraStyle(view)
			view.unit = nil
			dispelTypes[auraItem] = nil
			local source = auraSources[auraItem]
			if source then source.unit = nil end
		elseif not view.host:IsShown() and (view.mutedIcon or view.mutedRim) then
			HideAuraStyle(view)
		end
	end
	if not muted then return end
	for auraItem, held in pairs(muted) do
		if held.unit == unit or not NP.activeUnits[held.unit] or not IsShownSafe(auraItem) then
			RestoreMuted(auraItem, held)
		end
	end
	if not next(muted) then muted = nil end
end

function Countdown.Added(unit)
	UpdatePlate(unit)
end

function Countdown.Removed(unit)
	if NP.SecureAuras then NP.SecureAuras.Release(unit) end
	HideStale(unit)
end

function Countdown.Refresh(unit)
	UpdatePlate(unit)
end

function Countdown.RefreshAll()
	if muted or filteredItems then HideStale() end
end

function Countdown.Poll()
	local placement, fontSize, onlyMine = GetCountdownSettings()
	for unit in pairs(NP.activeUnits) do
		pcall(UpdatePlate, unit, placement, fontSize, onlyMine)
	end
	HideStale()
end
