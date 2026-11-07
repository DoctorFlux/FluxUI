local addonName, ns = ...

-- Optional Forever estimate, deliberately separate from native incoming heals.
-- Estimates follow readable successful player casts and learned descriptions.
-- They assume three-second ticks; haste, early removal and death cannot be
-- inferred from restricted aura/combat data. Nothing here reads the combat log.
FluxRaidHoTs = {}
local H = FluxRaidHoTs
local ceil, floor, max = math.ceil, math.floor, math.max
local frames = setmetatable({}, { __mode = "k" })
local workFrames = {}
local learned, pending, active = {}, {}, {}
local driver, ticker, driverEvents, auraEvent
local elapsed = 0
local TICK_SECONDS = 3
local Families = {}
for _, group in ipairs({
    { "renew", 139,6074,6075,6076,6077,6078,10927,10928,10929,25315,25221,25222,48067,48068 },
    { "rejuvenation", 774,1058,1430,2090,2091,3627,8910,9839,9840,9841,25299,26981,26982,48440,48441 },
    { "regrowth", 8936,8938,8939,8940,8941,9750,9856,9857,9858,26980,48442,48443 },
}) do
    for i = 2, #group do Families[group[i]] = group[1] end
end

local function Secret(value)
    if issecretvalue then return issecretvalue(value) end
    return FluxRaidCompat and FluxRaidCompat.IsSecret and FluxRaidCompat.IsSecret(value) or false
end

local function Plain(value, kind)
    return not Secret(value) and type(value) == kind
end

local function Read(fn, ...)
    if not fn then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
end

local function Now()
    return GetTime and GetTime() or 0
end

local function Locked()
    return InCombatLockdown and InCombatLockdown()
end

function H.IsSupported()
    local client = ns.Flux and ns.Flux.Client
    if not (client and (client.isForever or client.isCamelot)) then return false, "Forever only" end
    if not (C_Spell and C_Spell.GetSpellDescription) then return false, "spell descriptions unavailable" end
    local locale = GetLocale and GetLocale() or ""
    if locale ~= "enUS" and locale ~= "enGB" then return false, "description language unavailable" end
    return true
end

local function Enabled()
    if not H.IsSupported() then return false end
    local db = FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    return db and db.showEstimatedHoTs == true or false
end

local function ParseDescription(description)
    if not Plain(description, "string") then return nil end
    local text = description:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
    if not text:find("heal", 1, true) then return nil end
    -- Restrict to the supported English total-over-duration grammar. Multiple
    -- numeric effects, per-tick descriptions and other languages are unavailable.
    local amount, duration = text:match("([%d][%d,]*)%s+over%s+([%d%.]+)%s+sec")
    if not amount then
        amount, duration = text:match("([%d][%d,]*)%s+health%s+over%s+([%d%.]+)%s+sec")
    end
    if not amount then return nil end
    amount, duration = tonumber((amount:gsub(",", ""))), tonumber(duration)
    if not amount or not duration or amount <= 0 or duration < TICK_SECONDS or duration > 60 then return nil end
    local ticks = duration / TICK_SECONDS
    if ticks ~= floor(ticks) then return nil end
    return { total = amount, duration = duration, ticks = ticks }
end

function H.Learn()
    if not Enabled() or Locked() then return false end
    for spellID in pairs(Families) do
        local description = Read(C_Spell.GetSpellDescription, spellID)
        learned[spellID] = ParseDescription(description)
    end
    return next(learned) ~= nil
end

local function UnitIdentity(unit)
    if not Plain(unit, "string") or unit == "" then return nil end
    local guid = Read(UnitGUID, unit)
    if not Plain(guid, "string") or guid == "" then return nil end
    return guid
end

local function Name(unit)
    local name, realm
    if UnitFullName then
        local ok, n, r = pcall(UnitFullName, unit)
        if ok then name, realm = n, r end
    elseif UnitName then
        name = Read(UnitName, unit)
    end
    if not Plain(name, "string") or name == "" then return nil end
    if not Plain(realm, "string") or realm == "" then realm = nil end
    return name, realm and (name .. "-" .. realm):gsub("%s", "") or name
end

local function TargetIdentity(target)
    if not Plain(target, "string") or target == "" then return nil end
    local wanted, found = target:gsub("%s", ""), nil
    for frame in pairs(frames) do
        local unit = frame.displayedUnit or frame.unit
        local short, full = Name(unit)
        if short and (wanted == short or wanted == full) then
            local guid = UnitIdentity(unit)
            if guid then
                if found and found ~= guid then return nil end -- ambiguous cross-realm name
                found = guid
            end
        end
    end
    return found
end

local function Visible(frame)
    local method = frame.IsVisible or frame.IsShown
    if not method then return true end
    local value = Read(method, frame)
    return not Secret(value) and value == true
end

local function Remaining(effects, now)
    local amount = 0
    for family, effect in pairs(effects) do
        local left = effect.expires - now
        if left <= 0 then effects[family] = nil
        else amount = amount + effect.total / effect.ticks * ceil(left / TICK_SECONDS - 0.000001) end
    end
    return amount
end

local function Purge(now)
    for cast, record in pairs(pending) do if record.expires <= now then pending[cast] = nil end end
    for guid, effects in pairs(active) do
        Remaining(effects, now)
        if not next(effects) then active[guid] = nil end
    end
end

local function StopTicker()
    if ticker then ticker:Cancel(); ticker = nil end
    if driver and driver.GetScript and driver:GetScript("OnUpdate") then driver:SetScript("OnUpdate", nil) end
end

local function Paint(frame)
    local state = frame._fluxHoTs
    if not state then return false end
    if state.suspended or not Enabled() or not Visible(frame) or frame.unitExists == false then
        state.bar:Hide()
        state.status = "inactive"
        return false
    end
    local unit = frame.displayedUnit or frame.unit
    local guid = UnitIdentity(unit)
    if not guid then state.bar:Hide(); state.status = "unit identity unavailable"; return false end
    local effects = active[guid]
    if not effects then state.bar:Hide(); state.status = "no tracked player HoT"; return false end
    local dead = Read(UnitIsDeadOrGhost, unit)
    if not Secret(dead) and dead == true then
        active[guid] = nil
        state.bar:Hide(); state.status = "dead"; return false
    end
    local amount = Remaining(effects, Now())
    if amount <= 0 then state.bar:Hide(); state.status = "expired"; return false end
    local maximum = Read(UnitHealthMax, unit)
    if not Secret(maximum) and (type(maximum) ~= "number" or maximum <= 0) then
        state.bar:Hide(); state.status = "maximum health unavailable"; return false
    end
    state.bar:SetMinMaxValues(0, maximum)
    state.bar:SetValue(amount)
    state.bar:Show()
    state.status, state.amount = "estimated", amount
    return true
end

local function RefreshTicker()
    local work = false
    for frame in pairs(workFrames) do
        if Visible(frame) then work = true; break end
    end
    if driver then
        if work and not auraEvent then driver:RegisterEvent("UNIT_AURA"); auraEvent = true
        elseif not work and auraEvent then
            if driver.UnregisterEvent then driver:UnregisterEvent("UNIT_AURA") end
            auraEvent = nil
        end
        local visibleOwner = false
        for frame in pairs(frames) do
            if not frame._fluxHoTs.suspended and Visible(frame) then visibleOwner = true; break end
        end
        if not visibleOwner and driver.UnregisterAllEvents then
            driver:UnregisterAllEvents()
            driverEvents, auraEvent = nil, nil
        end
    end
    if not work then StopTicker(); return end
    if ticker or (driver and driver.GetScript and driver:GetScript("OnUpdate")) then return end
    local function update()
        Purge(Now())
        local visibleWork = false
        for frame in pairs(workFrames) do
            if Paint(frame) then visibleWork = true else workFrames[frame] = nil end
        end
        if not visibleWork then
            if driver and auraEvent and driver.UnregisterEvent then driver:UnregisterEvent("UNIT_AURA") end
            auraEvent = nil
            StopTicker()
        end
    end
    if C_Timer and C_Timer.NewTicker then ticker = C_Timer.NewTicker(0.2, update)
    elseif driver then
        elapsed = 0
        driver:SetScript("OnUpdate", function(_, delta)
            elapsed = elapsed + delta
            if elapsed >= 0.2 then elapsed = 0; update() end
        end)
    end
end

local function ObserveReadableAuras(unit)
    -- An absent/restricted combat aura is not evidence that an estimate ended.
    if Locked() or not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
    local secrets = ns.Flux and ns.Flux.Secrets
    if secrets and secrets.AurasRestricted and secrets.AurasRestricted() then return end
    local guid = UnitIdentity(unit)
    local effects = guid and active[guid]
    if not effects then return end
    local present = {}
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL|PLAYER")
        if not ok or Secret(aura) then return end
        if aura == nil then break end
        if type(aura) ~= "table" or (canaccesstable and not canaccesstable(aura)) then return end
        local spellID = aura.spellId
        if Secret(spellID) then return end
        if Families[spellID] then present[Families[spellID]] = true end
    end
    local now = Now()
    for family, effect in pairs(effects) do
        if not present[family] and now - effect.started > 0.5 then effects[family] = nil end
    end
end

function H.OnEvent(event, unit, targetOrCast, castOrSpell, spellID)
    if not Enabled() then
        pending, active = {}, {}
        workFrames = {}
        StopTicker()
        if driver and driver.UnregisterAllEvents then driver:UnregisterAllEvents(); driverEvents, auraEvent = nil, nil end
        for frame in pairs(frames) do if frame._fluxHoTs then frame._fluxHoTs.bar:Hide() end end
        return
    end
    local now = Now()
    Purge(now)
    if event == "UNIT_SPELLCAST_SENT" then
        if Secret(unit) or unit ~= "player" or not Plain(castOrSpell, "string")
            or not Plain(spellID, "number") then return end
        local metadata = learned[spellID]
        local guid = metadata and TargetIdentity(targetOrCast)
        if guid then
            local count, oldest, oldestTime = 0, nil, math.huge
            for cast, record in pairs(pending) do
                count = count + 1
                if record.expires < oldestTime then oldest, oldestTime = cast, record.expires end
            end
            if count >= 16 and oldest then pending[oldest] = nil end
            pending[castOrSpell] = { guid = guid, spellID = spellID, expires = now + 10 }
        end
        return
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if Secret(unit) or unit ~= "player" or not Plain(targetOrCast, "string")
            or not Plain(castOrSpell, "number") then return end
        local cast = pending[targetOrCast]
        pending[targetOrCast] = nil
        local metadata = cast and learned[castOrSpell]
        if cast and metadata and cast.spellID == castOrSpell then
            local effects = active[cast.guid] or {}; active[cast.guid] = effects
            effects[Families[castOrSpell]] = { total = metadata.total, ticks = metadata.ticks,
                started = now, expires = now + metadata.duration }
        end
    elseif event == "UNIT_AURA" then
        if not Plain(unit, "string") or not active[UnitIdentity(unit)] then return end
        ObserveReadableAuras(unit)
    elseif event == "PLAYER_ENTERING_WORLD" then
        pending, active = {}, {}
        H.Learn()
    elseif event == "SPELLS_CHANGED" or event == "SPELL_TEXT_UPDATE"
        or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        H.Learn()
    end
    for frame in pairs(frames) do workFrames[frame] = Paint(frame) or nil end
    RefreshTicker()
end

local function EnsureDriver()
    if driverEvents then return end
    if not driver then
        driver = CreateFrame("Frame")
        driver:SetScript("OnEvent", function(_, event, ...) H.OnEvent(event, ...) end)
    end
    if driver.RegisterUnitEvent then
        driver:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
        driver:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    end
    for _, event in ipairs({ "SPELLS_CHANGED", "SPELL_TEXT_UPDATE",
        "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED" }) do
        driver:RegisterEvent(event)
    end
    driverEvents = true
    H.Learn()
end

function H.Setup(frame)
    if not frame or not frame.healthBar or frame._fluxRaidMini then return false end
    if not Enabled() then return false end
    if frame._fluxHoTs then
        if not Locked() then frame._fluxHoTs.bar:SetWidth(max(1, frame.healthBar:GetWidth())) end
        if Visible(frame) then EnsureDriver() end
        return true
    end
    if Locked() then return false end
    local health = frame.healthBar
    local host = CreateFrame("Frame", nil, health)
    host:SetAllPoints(health)
    if host.SetClipsChildren then host:SetClipsChildren(true) end
    if host.EnableMouse then host:EnableMouse(false) end
    if host.SetFrameLevel and health.GetFrameLevel then host:SetFrameLevel(health:GetFrameLevel() + 4) end
    local bar = CreateFrame("StatusBar", nil, host)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(0.2, 0.85, 0.5, 0.65)
    bar:SetPoint("TOPLEFT", health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    bar:SetWidth(max(1, health:GetWidth()))
    bar:SetHeight(3)
    if bar.EnableMouse then bar:EnableMouse(false) end
    bar:Hide()
    frame._fluxHoTs = { bar = bar, host = host, status = "no tracked player HoT" }
    frames[frame] = true
    if frame.HookScript then
        frame:HookScript("OnShow", function() H.Update(frame) end)
        frame:HookScript("OnHide", function() H.Clear(frame) end)
    end
    if Visible(frame) then EnsureDriver() end
    return true
end

function H.Update(frame)
    if not frame then return end
    if not frame._fluxHoTs and not H.Setup(frame) then return end
    if not Enabled() then
        if driverEvents or ticker or next(active) or next(pending) then H.OnEvent("OPTIONS_CHANGED")
        else frame._fluxHoTs.bar:Hide(); frame._fluxHoTs.status = "inactive" end
        return
    end
    frame._fluxHoTs.suspended = nil
    if Visible(frame) then EnsureDriver() end
    workFrames[frame] = Paint(frame) or nil
    RefreshTicker()
end

function H.Clear(frame)
    if frame and frame._fluxHoTs then
        frame._fluxHoTs.bar:Hide()
        frame._fluxHoTs.status = "inactive"
        frame._fluxHoTs.suspended = true
    end
    workFrames[frame] = nil
    RefreshTicker()
end

function H.GetStatus(frame)
    if frame and frame._fluxHoTs then return frame._fluxHoTs.status end
    local ok, reason = H.IsSupported()
    if not ok then return reason end
    return Enabled() and "description or cast unavailable" or "disabled"
end
