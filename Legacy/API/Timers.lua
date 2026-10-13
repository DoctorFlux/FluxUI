-- Timers.lua — After / ticker helpers (modern clients only)
-- Never assign into global C_Timer on clients that already have it — replacing
-- C_Timer.After would run Blizzard Settings deferred work under _FluxUI.
local addonName, ns = ...
local H = ns._FluxAPICompat

local _CTimerAfter = C_Timer and C_Timer.After
local _CTimerNewTicker = C_Timer and C_Timer.NewTicker

-- Classic-only polyfill when C_Timer is missing entirely (never overwrite retail).
if not C_Timer then
    C_Timer = {}
end
if not _CTimerAfter then
    _CTimerAfter = function(duration, callback)
        local frame = CreateFrame("Frame")
        local elapsed = 0
        frame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= duration then
                callback()
                self:SetScript("OnUpdate", nil)
                self:Hide()
            end
        end)
        return frame
    end
    if not C_Timer.After then
        C_Timer.After = _CTimerAfter
    end
end
if not _CTimerNewTicker then
    _CTimerNewTicker = function(duration, callback, iterations)
        local frame = CreateFrame("Frame")
        local elapsed = 0
        local count = 0
        frame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= duration then
                callback()
                elapsed = 0
                count = count + 1
                if iterations and count >= iterations then
                    self:SetScript("OnUpdate", nil)
                    self:Hide()
                end
            end
        end)
        frame.Cancel = function(self)
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
        return frame
    end
    if not C_Timer.NewTicker then
        C_Timer.NewTicker = _CTimerNewTicker
    end
end

function ns.API.TimerAfter(duration, callback)
    return _CTimerAfter(duration, callback)
end

function ns.API.NewTicker(duration, callback, iterations)
    return _CTimerNewTicker(duration, callback, iterations)
end

function FluxTimerAfter(duration, callback)
    return _CTimerAfter(duration, callback)
end

function FluxNewTicker(duration, callback, iterations)
    return _CTimerNewTicker(duration, callback, iterations)
end

function FluxSafeDefer(delay, callback)
    if type(callback) ~= "function" then return end
    if not _CTimerAfter then return end
    local d = tonumber(delay) or 0
    if d < 0 then d = 0 end
    _CTimerAfter(d, function()
        local ok, err = pcall(callback)
        if not ok then
            local geh = _G.geterrorhandler
            if geh then
                geh()(tostring(err))
            end
        end
    end)
end

function FluxAPICompat.After(delay, fn)
    if type(fn) ~= "function" then return end
    if _CTimerAfter then
        _CTimerAfter(delay, fn)
        return
    end
    local f = CreateFrame("Frame")
    local t = 0
    f:SetScript("OnUpdate", function(_, el)
        t = t + (el or 0)
        if t >= (tonumber(delay) or 0) then
            f:SetScript("OnUpdate", nil)
            fn()
        end
    end)
end

H._CTimerAfter = _CTimerAfter
