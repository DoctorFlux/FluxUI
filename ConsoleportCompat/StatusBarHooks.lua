-- StatusBarHooks.lua
-- Suppresses ConsolePort EXP/REP style bars so FluxStatusBar remains authoritative.

local addonName, ns = ...

ns.ConsolePortCompat = ns.ConsolePortCompat or {}
local Compat = ns.ConsolePortCompat

local watchedStatusNames = {
    "ConsolePortStatusBar",
    "ConsolePortXPBar",
    "ConsolePortExpBar",
    "ConsolePortReputationBar",
    "ConsolePortRepBar",
    "ConsolePort_Bar",
    "ConsolePortPowerLevel",
}

local function IsFrameObject(obj)
    if not obj then
        return false
    end
    local ok, objectType = pcall(function()
        if not obj.GetObjectType then
            return nil
        end
        return obj:GetObjectType()
    end)
    if not ok then
        return false
    end
    return objectType == "Frame" or objectType == "StatusBar" or objectType == "Button"
end

local function IsFluxFrame(frame)
    if not frame or not frame.GetName then
        return false
    end
    local name = frame:GetName()
    return type(name) == "string" and name:match("^Flux")
end

local function GetSafeName(frame)
    if not frame or not frame.GetName then
        return ""
    end
    return frame:GetName() or ""
end

local function NameLooksConsolePortStatus(name)
    if type(name) ~= "string" or name == "" then
        return false
    end
    local lower = string.lower(name)
    if not lower:find("consoleport", 1, true) then
        if not lower:match("^cp") then
            return false
        end
    end
    return lower:find("status", 1, true)
        or lower:find("watchbar", 1, true)
        or lower:find("xp", 1, true)
        or lower:find("exp", 1, true)
        or lower:find("rep", 1, true)
        or lower:find("reputation", 1, true)
        or lower:find("honor", 1, true)
        or lower:find("powerlevel", 1, true)
end

local function EnsureHiddenParent()
    if Compat.hiddenParent and Compat.hiddenParent.GetObjectType then
        return Compat.hiddenParent
    end
    local f = CreateFrame("Frame", "FluxConsolePortCompatHiddenParent", UIParent)
    f:Hide()
    f:SetSize(1, 1)
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -9000, -9000)
    Compat.hiddenParent = f
    return f
end

local function SuppressFrame(frame)
    if not frame or frame._fluxCPStatusSuppressed or IsFluxFrame(frame) then
        return
    end

    local hiddenParent = EnsureHiddenParent()

    frame._fluxCPStatusSuppressed = true

    if frame.UnregisterAllEvents then
        pcall(frame.UnregisterAllEvents, frame)
    end
    if frame.EnableMouse then
        pcall(frame.EnableMouse, frame, false)
    end
    pcall(frame.SetParent, frame, hiddenParent)
    pcall(frame.Hide, frame)

    if frame.HookScript and not frame._fluxCPShowHooked then
        frame._fluxCPShowHooked = true
        frame:HookScript("OnShow", function(self)
            if InCombatLockdown and InCombatLockdown() then
                return
            end
            if self:GetParent() ~= hiddenParent then
                self:SetParent(hiddenParent)
            end
            self:Hide()
        end)
    end
end

local function SuppressToolbarBars()
    local toolbar = _G.ConsolePortToolbar
    if not toolbar then
        return
    end

    -- Keep ConsolePort button systems, only remove bar-like surfaces from toolbar.
    if toolbar.XPBar then
        SuppressFrame(toolbar.XPBar)
    end
    if toolbar.PerformanceBar then
        SuppressFrame(toolbar.PerformanceBar)
    end
end

local function CollectByNames(out)
    for i = 1, #watchedStatusNames do
        local frame = _G[watchedStatusNames[i]]
        if IsFrameObject(frame) then
            out[frame] = true
        end
    end
end

local function CollectByHeuristic(out)
    if not EnumerateFrames then
        return
    end
    local frame = EnumerateFrames()
    while frame do
        local name = frame.GetName and frame:GetName() or ""
        if NameLooksConsolePortStatus(name) then
            out[frame] = true
        end
        frame = EnumerateFrames(frame)
    end
end

function Compat.ApplyStatusBarSuppression()
    local targets = {}
    CollectByNames(targets)
    CollectByHeuristic(targets)
    SuppressToolbarBars()

    for frame in pairs(targets) do
        local name = GetSafeName(frame)
        if NameLooksConsolePortStatus(name)
            or frame == _G.ConsolePort_Bar
            or frame == _G.ConsolePortPowerLevel then
            SuppressFrame(frame)
        end
    end
end
