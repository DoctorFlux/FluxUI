-- Paint Flux school themes on Blizzard's own nameplate casting bar. The
-- status bar, cast lifecycle, text, shield, and interrupt state remain native.
local _, ns = ...
local NP = ns.Flux.NamePlates
local FX = ns.CastBarThemes
local Schools = ns.CastBarSchools
local module = NP.RegisterModule("castBarSchools", {interval = 0.1})

local byBar = setmetatable({}, {__mode = "k"})
local byUnit = {}
local hookedBars = setmetatable({}, {__mode = "k"})

local function reset(state)
    if not state then return end
    state.proxy.casting = false
    FX.Reset(state.proxy, true)
end

local function castInfo(unit, channel)
    local fn = channel and UnitChannelInfo or UnitCastingInfo
    if type(fn) ~= "function" then return end
    local ok, name, _, _, _, _, trade, _, channelSpellID, castingSpellID = pcall(fn, unit)
    if not ok then return end
    -- UnitChannelInfo and UnitCastingInfo put spellID at positions 8 and 9.
    local id = channel and channelSpellID or castingSpellID
    return Schools.Plain(id), Schools.Plain(name), Schools.Plain(trade)
end

local function begin(state, event)
    if not state or not state.unit or not state.bar:IsShown() then return end
    local channel = event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START"
    local id, name, trade = castInfo(state.unit, channel)
    if not id and not name then
        reset(state)
        return
    end
    state.proxy.casting = true
    -- A secret ID/name must never be used as a lookup key. Begin and the
    -- shared visual resolver accept only the accessible fields above.
    local ok, err = pcall(FX.Begin, state.proxy, state.unit, id, name, trade, nil, true)
    if not ok then
        reset(state)
        if geterrorhandler then geterrorhandler()(err) end
    end
end

local function syncExisting(state)
    if not state or not state.bar:IsShown() then return end
    local channel = Schools.Plain(state.bar.channeling) == true
        or Schools.Plain(state.bar.reverseChanneling) == true
    local casting = Schools.Plain(state.bar.casting) == true
    if channel or casting then
        begin(state, channel and "UNIT_SPELLCAST_CHANNEL_START" or "UNIT_SPELLCAST_START")
    end
end

local function installHooks(bar)
    if hookedBars[bar] or type(hooksecurefunc) ~= "function"
        or type(bar.HandleCastStart) ~= "function" then return end
    -- XML mixin methods may be copied to each frame. Secure-hook the actual
    -- Blizzard bar once, without replacing its method or storing Flux fields.
    local ok = pcall(hooksecurefunc, bar, "HandleCastStart", function(self, event)
        begin(byBar[self], event)
    end)
    if not ok then return end
    pcall(hooksecurefunc, bar, "FinishSpell", function(self)
        local state = byBar[self]
        if state and state.unit then
            state.proxy.casting = false
            FX.Finish(state.proxy)
        end
    end)
    pcall(hooksecurefunc, bar, "HandleInterruptOrSpellFailed", function(self)
        reset(byBar[self])
    end)
    hookedBars[bar] = true
end

function module.Added(unit)
    local uf, plate = NP.GetParts(unit)
    local bar = uf and uf.CastBarsContainer and uf.CastBarsContainer.castBar
    if not (plate and bar and bar.GetStatusBarTexture) then return end
    installHooks(bar)
    local state = byBar[bar]
    if not state then
        -- This is a Flux visual host, not a second cast bar. Blizzard's
        -- StatusBar remains the sole progress and event owner.
        local proxy = CreateFrame("Frame", nil, plate)
        proxy:SetAllPoints(bar)
        proxy:SetFrameLevel(bar:GetFrameLevel() + 1)
        proxy:EnableMouse(false)
        proxy.TimerBar = bar
        proxy._fluxNativeCast = bar
        proxy._fluxSchoolNameplate = true
        FX.Attach(proxy)
        state = {bar = bar, proxy = proxy}
        byBar[bar] = state
    else
        if state.unit and state.unit ~= unit then
            byUnit[state.unit] = nil
            reset(state)
        end
        state.proxy:SetParent(plate)
        state.proxy:ClearAllPoints()
        state.proxy:SetAllPoints(bar)
        state.proxy:SetFrameLevel(bar:GetFrameLevel() + 1)
    end
    state.unit = unit
    byUnit[unit] = state
    state.proxy:Show()
    syncExisting(state)
end

function module.Removed(unit)
    local state = byUnit[unit]
    if not state then return end
    reset(state)
    state.unit = nil
    state.proxy:Hide()
    byUnit[unit] = nil
end

function module.Refresh(unit)
    local state = byUnit[unit]
    if state and not hookedBars[state.bar] then installHooks(state.bar) end
    if state and state.bar:IsShown() then
        if not state.proxy._fluxSchoolCast then syncExisting(state) end
    else
        reset(state)
    end
end

function module.Poll()
    for _, state in pairs(byUnit) do
        if not state.bar:IsShown() and state.proxy._fluxSchoolCast then
            reset(state)
        end
    end
end
