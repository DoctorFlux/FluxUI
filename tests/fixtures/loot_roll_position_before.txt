-- FluxLootRollPosition.lua
-- Repositions the Blizzard group loot roll window (green/blue/epic in group) above the player unit frame's outer border.

local addonName, ns = ...

local GAP = 6 -- Vertical gap above the outer border

-- Resolve Blizzard frame (GroupLootFrame is the main roll window; fallback for other clients)
local function GetLootRollFrame()
    return _G.GroupLootFrame or _G.GroupLootContainer
end

local function UpdatePosition()
    local lootFrame = GetLootRollFrame()
    if not lootFrame then return end

    local playerFrame = ns.PlayerFrame
    if not playerFrame or not playerFrame.outerBorderFrame then
        return
    end

    if InCombatLockdown() then
        if not lootFrame._fluxLootRollNeedsPosition then
            lootFrame._fluxLootRollNeedsPosition = true
            local defer = CreateFrame("Frame")
            defer:RegisterEvent("PLAYER_REGEN_ENABLED")
            defer:SetScript("OnEvent", function(self, event)
                if event == "PLAYER_REGEN_ENABLED" and lootFrame._fluxLootRollNeedsPosition then
                    lootFrame._fluxLootRollNeedsPosition = nil
                    self:UnregisterAllEvents()
                    UpdatePosition()
                end
            end)
            lootFrame._fluxLootRollDefer = defer
        end
        return
    end

    lootFrame:ClearAllPoints()
    lootFrame:SetPoint("BOTTOM", playerFrame.outerBorderFrame, "TOP", 0, GAP)
end

local function Initialize()
    local lootFrame = GetLootRollFrame()
    if not lootFrame then return end

    if not lootFrame._fluxLootRollShowHooked then
        lootFrame._fluxLootRollShowHooked = true
        if lootFrame.HookScript then
            lootFrame:HookScript("OnShow", UpdatePosition)
        end
    end

    UpdatePosition()

    if not ns.PlayerFrame or not ns.PlayerFrame.outerBorderFrame then
        local watcher = CreateFrame("Frame")
        local checkCount = 0
        local MAX_CHECKS = 50
        watcher:SetScript("OnUpdate", function(self, elapsed)
            checkCount = checkCount + 1
            if ns.PlayerFrame and ns.PlayerFrame.outerBorderFrame then
                self:SetScript("OnUpdate", nil)
                UpdatePosition()
            elseif checkCount >= MAX_CHECKS then
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

local startup = CreateFrame("Frame")
startup:RegisterEvent("PLAYER_LOGIN")
startup:RegisterEvent("PLAYER_ENTERING_WORLD")
startup:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        Initialize()
    end
end)

