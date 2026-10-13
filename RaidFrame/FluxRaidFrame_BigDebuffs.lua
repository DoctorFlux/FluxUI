-- RaidFrame/FluxRaidFrame_BigDebuffs.lua
-- BigDebuffs integration for Flux raid buttons.
-- Private-aura containers do not get invented debuffFrames — Blizzard_PrivateAurasUI owns that layout.
-- The classic icon row exposes debuffFrames[1] for BigDebuffs to anchor to.

local addonName, ns = ...

local max = math.max
local nameCounter = 0

local function noop() end
_G.FluxRaidFrame_BigDebuffs_TryUpdate = noop

local function EnsureFrameName(frame)
    if frame:GetName() then return end
    nameCounter = nameCounter + 1
    pcall(function()
        frame:SetName("FluxRaidBD" .. nameCounter)
    end)
end

local function IsPrivateAuraContainer(frame)
    if not frame then return false end
    if frame.IsContainer then
        local ok, isC = pcall(frame.IsContainer, frame)
        if ok and isC then return true end
    end
    if frame.TriggerPrivateAuraSettingsUpdate and not (frame.buffFrames and frame.buffFrames[1]) then
        return true
    end
    return false
end

--- Prefer real Blizzard CUF debuffFrames[1]. Never invent slots on PrivateAuras containers.
local function EnsureDebuffAnchorFrame(frame)
    if IsPrivateAuraContainer(frame) then
        return false
    end
    local d1 = frame.debuffFrames and frame.debuffFrames[1]
    if d1 then
        frame._fluxBDDebuffAnchor = nil
        return true
    end
    -- Retail CUF without debuff child yet: no proxy — wait for Blizzard layout.
    return false
end

local function ApplyFluxBigDebuffSizing(frame)
    if not frame.BigDebuffs then return end
    local d1 = frame.debuffFrames and frame.debuffFrames[1]
    local w = (d1 and d1:GetWidth()) or (FluxRaidVisuals and FluxRaidVisuals.AURA_ICON_WIDTH) or 11
    local h = (d1 and d1:GetHeight()) or (FluxRaidVisuals and FluxRaidVisuals.AURA_ICON_HEIGHT) or 11
    if not w or w < 1 or not h or h < 1 then return end
    local base = max(w, h)
    for i = 1, #frame.BigDebuffs do
        local b = frame.BigDebuffs[i]
        if b and b:IsShown() then
            b:SetSize(w, h)
            b.baseSize = base
        end
    end
end

local function SyncOptionTable(frame)
    -- Keep Flux shared option table in sync with CVars (do not invent a bare table that
    -- loses DefaultCompactUnitFrameOptions inheritance).
    if FluxRaidVisuals and FluxRaidVisuals.SyncAuraDisplayOptions and frame.optionTable then
        FluxRaidVisuals.SyncAuraDisplayOptions(frame.optionTable)
    elseif FluxRaid_GetCVarBool then
        frame.optionTable = frame.optionTable or {}
        frame.optionTable.displayOnlyDispellableDebuffs =
            FluxRaid_GetCVarBool("raidFramesDisplayOnlyDispellableDebuffs", false)
    end
end

local function TryUpdate(frame)
    if not BigDebuffs or not BigDebuffs.db or not BigDebuffs.db.profile.raidFrames then return end
    if not BigDebuffs.db.profile.raidFrames.enabled then return end
    if not BigDebuffs.ShowInRaids or not BigDebuffs:ShowInRaids() then return end
    if not frame or not frame._fluxRaidUnit then return end
    local unit = frame.unit or frame.displayedUnit
    if not (FluxRaidCompat and FluxRaidCompat.UnitTokenValid and FluxRaidCompat.UnitTokenValid(unit)) then
        return
    end

    -- Classic PA: BigDebuffs cannot safely replace Blizzard aura tables.
    if IsPrivateAuraContainer(frame) then
        return
    end

    frame.displayedUnit = frame.displayedUnit or frame.unit
    if not UnitIsPlayer(frame.displayedUnit) then return end

    EnsureFrameName(frame)
    frame.maxBuffs = frame.maxBuffs or 6
    SyncOptionTable(frame)
    if not EnsureDebuffAnchorFrame(frame) then
        return
    end
    frame._fluxRaidBigDebuffsHost = true

    local ok = pcall(function()
        BigDebuffs:AddBigDebuffs(frame)
        BigDebuffs:ShowBigDebuffs(frame)
    end)
    if not ok then return end

    ApplyFluxBigDebuffSizing(frame)
end

local refreshHooked = false

local function HookBigDebuffsRefresh()
    if refreshHooked or not BigDebuffs or not BigDebuffs.Refresh then return end
    refreshHooked = true
    local orig = BigDebuffs.Refresh
    function BigDebuffs:Refresh(...)
        local removed = {}
        for fr, _ in pairs(self.frames) do
            if fr._fluxRaidBigDebuffsHost then
                removed[#removed + 1] = fr
                self.frames[fr] = nil
            end
        end
        orig(self, ...)
        for i = 1, #removed do
            local fr = removed[i]
            self.frames[fr] = true
            if fr:IsVisible() and _G.FluxRaidFrame_BigDebuffs_TryUpdate then
                _G.FluxRaidFrame_BigDebuffs_TryUpdate(fr)
            end
        end
    end
end

local function Setup()
    if not BigDebuffs or not BigDebuffs.AddBigDebuffs then return end
    _G.FluxRaidFrame_BigDebuffs_TryUpdate = TryUpdate
    HookBigDebuffsRefresh()
    if BigDebuffs.Refresh then
        C_Timer.After(0, function()
            if BigDebuffs and BigDebuffs.Refresh then
                BigDebuffs:Refresh()
            end
        end)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, name)
    if name == "BigDebuffs" then
        Setup()
    end
end)
if BigDebuffs and BigDebuffs.AddBigDebuffs then
    Setup()
end

