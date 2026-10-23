-- Other/FluxDurationBars.lua
local addonName, ns = ...
local API = ns.API or {}
local hookedShows = setmetatable({}, { __mode = "k" })
local hookedFrames = setmetatable({}, { __mode = "k" })

local function IsPlayerTargetPlacement2()
    local o = _G.FluxOptions
    if o and o.GetPlayerTargetPlacement then
        return o:GetPlayerTargetPlacement() == 2
    end
    if _G.FluxUnitFrames_GetPlayerTargetPlacement then
        return _G.FluxUnitFrames_GetPlayerTargetPlacement() == 2
    end
    return false
end

-- Function to reposition a specific MirrorTimer frame down by 50px
local function RepositionMirrorTimer(frame, index)
    if not frame then return end
    --- Layout: player/target side-by-side at bottom — keep Blizzard default MirrorTimer placement.
    if IsPlayerTargetPlacement2() then
        return
    end

    frame:ClearAllPoints()
    if index == 1 then
        -- First timer: move from y=-96 to y=-146 (50px down)
        frame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    else
        -- Subsequent timers: position relative to the previous timer
        local prevFrame = _G["MirrorTimer" .. (index - 1)]
        if prevFrame then
            frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, 0)
        end
    end

    -- Ensure edit mode doesn't affect MirrorTimer frames
    if API and API.FluxRemoveFrameFromEditMode then
        API.FluxRemoveFrameFromEditMode(frame)
    end
end

-- Hook into MirrorTimer events to reposition when they become visible
local function HookMirrorTimerEvents()
    -- Hook the MirrorTimer_Show function to reposition when a timer is shown
    if MirrorTimer_Show and not hookedShows[MirrorTimer_Show] then
        local originalMirrorTimerShow = MirrorTimer_Show
        local function WrappedMirrorTimerShow(timer, value, maxvalue, scale, paused, label)
            local dialog = originalMirrorTimerShow(timer, value, maxvalue, scale, paused, label)
            if dialog then
                -- Find which MirrorTimer frame this is
                for i = 1, 3 do
                    if _G["MirrorTimer" .. i] == dialog then
                        RepositionMirrorTimer(dialog, i)
                        break
                    end
                end
            end
            return dialog
        end
        hookedShows[originalMirrorTimerShow] = true
        hookedShows[WrappedMirrorTimerShow] = true
        MirrorTimer_Show = WrappedMirrorTimerShow
    end

    -- Hook into MirrorTimerFrame_OnEvent to reposition when timers start
    for i = 1, 3 do
        local frame = _G["MirrorTimer" .. i]
        if frame and frame:GetScript("OnEvent") and not hookedFrames[frame] then
            frame:HookScript("OnEvent", function(self)
                -- Reposition after the event is handled
                for j = 1, 3 do
                    if _G["MirrorTimer" .. j] == self then
                        RepositionMirrorTimer(self, j)
                        break
                    end
                end
            end)
            hookedFrames[frame] = true
        end
    end
end

-- Initialize on addon load
local function InitializeDurationBars()
    -- Try to reposition existing frames immediately
    for i = 1, 3 do
        local frame = _G["MirrorTimer" .. i]
        if frame then
            RepositionMirrorTimer(frame, i)
        end
    end

    -- Hook into events
    HookMirrorTimerEvents()
end

-- Initialize on player login
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name ~= addonName and name ~= "Blizzard_MirrorTimer" then return end
    InitializeDurationBars()
end)

