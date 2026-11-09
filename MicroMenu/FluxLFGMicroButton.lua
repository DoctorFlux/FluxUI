-- FluxLFGMicroButton.lua
if not FluxMicroMenu or not FluxMicroMenu.CreateMicroButton then return end

local function IsForeverClient()
    return (FLUX_API and (FLUX_API.isCamelot or FLUX_API.isForever)) == true
end

local function ForeverGamepadUI()
    local Flux = _G.Flux
    local cap = Flux and (Flux.Cap or Flux.Capabilities)
    return cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() == true
end

-- Forever Camelot: LFDMicroButton stays in Flux's bar, but Blizzard's OnClick calls
-- ToggleGroupFinderFrame which no-ops when Blizzard_GroupFinder_VanillaStyle is still
-- LoD-unloaded, and PVEFrame_ToggleFrame does not exist (GroupFinder is camelot-excluded).
-- Open the Forever Vanilla LFGParentFrame instead. Live / Classic never enter this path.
local VANILLA_LFG_ADDON = "Blizzard_GroupFinder_VanillaStyle"

local function ForeverVanillaLFGReady()
    return _G.LFGParentFrame ~= nil or _G.LFGVanilla_ShowFrame ~= nil or _G.LFGVanilla_ToggleFrame ~= nil
end

-- WhoList InitRaceFilters can throw while this addon loads. Do not replace
-- the shared dropdown SetupMenu method to hide that: writing that method, even
-- to put the original back, leaves every dropdown click tainted.
local function LoadForeverVanillaLFG()
    if ForeverVanillaLFGReady() then
        return true
    end
    local function load()
        if _G.GroupFinderVanillaStyle_LoadUI then
            pcall(_G.GroupFinderVanillaStyle_LoadUI)
        end
        if not ForeverVanillaLFGReady() then
            local loadAddOn = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
            if loadAddOn then
                pcall(loadAddOn, VANILLA_LFG_ADDON)
            end
        end
    end
    pcall(load)
    return ForeverVanillaLFGReady()
end

local function ToggleForeverGroupFinder()
    if not LoadForeverVanillaLFG() then
        return
    end
    local frame = _G.LFGParentFrame
    if not frame then
        return
    end
    if frame:IsShown() then
        HideUIPanel(frame)
        return
    end
    -- wow-ui-source-forever Blizzard_LFGVanilla_ParentFrame.lua
    if _G.LFGVanilla_ShowFrame then
        local ok = pcall(_G.LFGVanilla_ShowFrame)
        if ok and frame:IsShown() then
            return
        end
    end
    ShowUIPanel(frame)
end

local function SyncForeverLFDMicroButton(btn)
    if not btn then
        return
    end
    if Kiosk and Kiosk.IsEnabled and Kiosk.IsEnabled() then
        return
    end
    if btn.Enable then
        pcall(btn.Enable, btn)
    end
    if btn.EnableMouse then
        pcall(btn.EnableMouse, btn, true)
    end
    if btn.SetAlpha then
        pcall(btn.SetAlpha, btn, 1)
    end
    local frame = _G.LFGParentFrame
    if frame and frame.IsShown and frame:IsShown() then
        if btn.SetPushed then
            pcall(btn.SetPushed, btn)
        end
    elseif btn.SetNormal then
        pcall(btn.SetNormal, btn)
    end
end

local foreverClickWired = false
local foreverToggleWrapped = false

local function WireForeverLFDMicroButton()
    local btn = _G.LFDMicroButton
    if not btn then
        return
    end
    SyncForeverLFDMicroButton(btn)
    if ForeverGamepadUI() then
        return
    end
    if btn.RegisterForClicks then
        pcall(btn.RegisterForClicks, btn, "AnyUp")
    end
    if foreverClickWired then
        return
    end
    foreverClickWired = true
    btn:SetScript("OnClick", function(self, mouseButton)
        if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then
            if self.QuickKeybindButtonOnClick then
                self:QuickKeybindButtonOnClick(mouseButton)
            end
            return
        end
        ToggleForeverGroupFinder()
    end)
end

local function WrapForeverToggleGroupFinderFrame()
    if ForeverGamepadUI() then
        return
    end
    if foreverToggleWrapped then
        return
    end
    foreverToggleWrapped = true
    local blizzardToggle = _G.ToggleGroupFinderFrame
    _G.ToggleGroupFinderFrame = function(sidePanelName, selection)
        if LoadForeverVanillaLFG() and _G.LFGParentFrame then
            ToggleForeverGroupFinder()
            return
        end
        if blizzardToggle then
            return blizzardToggle(sidePanelName, selection)
        end
    end
end

if IsForeverClient() then
    -- Gamepad never calls LoadForeverVanillaLFG. Blizzard loads the Group Finder on
    -- entering the world. Loading it here would open its menus from Flux code.
    if not ForeverGamepadUI() then
        WrapForeverToggleGroupFinderFrame()
    end
    WireForeverLFDMicroButton()

    local foreverLFGFrame = CreateFrame("Frame")
    foreverLFGFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    foreverLFGFrame:RegisterEvent("ADDON_LOADED")
    foreverLFGFrame:SetScript("OnEvent", function(_, event, name)
        if event == "ADDON_LOADED" and name ~= "_FluxUI" then
            return
        end
        -- Load only when the player clicks the LFG button.
        WireForeverLFDMicroButton()
    end)

    -- Do not hook UpdateMicroButtons. GameMenuFrame:OnShow calls it, then the
    -- gamepad footer calls protected SetPreferredGamepadInteractTarget().
    if hooksecurefunc and FluxMicroMenu.Rebuild then
        hooksecurefunc(FluxMicroMenu, "Rebuild", function()
            WireForeverLFDMicroButton()
        end)
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, WireForeverLFDMicroButton)
        C_Timer.After(0.5, WireForeverLFDMicroButton)
    end
    return
end

local function CreateFluxLFGButton()
    if _G["FluxLFGMicroButton"] then return end -- Already created

    if FLUX_API and FLUX_API.ClientHasBlizzardMicroGroupFinder and FLUX_API.ClientHasBlizzardMicroGroupFinder() then
        return
    end
    if FluxClientHasBlizzardMicroGroupFinder and FluxClientHasBlizzardMicroGroupFinder() then
        return
    end

    -- Compatibility / Availability Check
    -- Only create this button if the LFG Minimap Button exists (indicating LFG is active)
    -- Use minimap button visibility as the availability indicator.
    local lfgMinimapButton = _G["LFGMinimapFrame"] or _G["LFGMinimapFrameIcon"] or _G["QueueStatusMinimapButton"] or _G["LFG_MinimapEye"]

    if not lfgMinimapButton then
        -- No LFG minimap button detected yet.
        return
    end

    -- Ported from ArtAndMicroMenu.lua

    local clickHandler = {
        OnClick = function(self, button, down)
                -- Right-click: open LFGBulletinBoard when loaded
                if button == "RightButton" then
                    local GBB = _G["GroupBulletinBoard_Addon"]
                    if GBB and GBB.ToggleWindow then
                        GBB.ToggleWindow()
                        return
                    end
                end
                -- Left-click (default): toggle WoW LFG window
                -- Check if any LFG frame is currently shown
                local lfgOpen = false

                -- Check if any LFG frame is currently shown
                if LFDParentFrame and LFDParentFrame:IsShown() then
                    lfgOpen = true
                elseif PVEFrame and PVEFrame:IsShown() then
                    lfgOpen = true
                elseif GroupFinderFrame and GroupFinderFrame:IsShown() then
                    lfgOpen = true
                elseif _G["LFGParentFrame"] and _G["LFGParentFrame"]:IsShown() then
                    lfgOpen = true
                elseif _G["LFDFrame"] and _G["LFDFrame"]:IsShown() then
                    lfgOpen = true
                elseif _G["LFGFrame"] and _G["LFGFrame"]:IsShown() then
                    lfgOpen = true
                end

                if lfgOpen then
                    -- Close LFG window
                    if LFDParentFrame then
                        HideUIPanel(LFDParentFrame)
                    elseif PVEFrame and PVEFrame:IsShown() then
                        HideUIPanel(PVEFrame)
                    elseif GroupFinderFrame then
                        HideUIPanel(GroupFinderFrame)
                    elseif _G["LFGParentFrame"] then
                        HideUIPanel(_G["LFGParentFrame"])
                    elseif _G["LFDFrame"] then
                        HideUIPanel(_G["LFDFrame"])
                    elseif _G["LFGFrame"] then
                        HideUIPanel(_G["LFGFrame"])
                    end
                else
                    -- Open LFG window
                    if ToggleLFDParentFrame then
                        ToggleLFDParentFrame()
                    elseif LFDParentFrame then
                        ShowUIPanel(LFDParentFrame)
                    elseif PVEFrame_ShowFrame then
                        PVEFrame_ShowFrame()
                    elseif GroupFinderFrame then
                        ShowUIPanel(GroupFinderFrame)
                    else
                        -- Fallback: try to show any LFG-related frame
                        local lfgFrame = _G["LFGParentFrame"] or _G["LFDFrame"] or _G["LFGFrame"]
                        if lfgFrame then
                            ShowUIPanel(lfgFrame)
                        end
                    end
                end
        end,
        OnTooltip = function(tooltip)
            tooltip:AddLine(" ")
            tooltip:AddLine("Looking For Group", 1, 1, 1)
            tooltip:AddLine("<Left Click> Toggle LFG Window", 0.6, 0.6, 0.6)
            if _G["GroupBulletinBoard_Addon"] and _G["GroupBulletinBoard_Addon"].ToggleWindow then
                tooltip:AddLine("<Right Click> LFG Bulletin Board", 0.6, 0.6, 0.6)
            end

            -- Add queue status if available
            local hasActiveEntry = C_LFGList and C_LFGList.HasActiveEntryInfo and C_LFGList.HasActiveEntryInfo()
            if hasActiveEntry then
                tooltip:AddLine("Group Listed", 0, 1, 0)
            else
                local apps = C_LFGList and C_LFGList.GetApplications and C_LFGList.GetApplications()
                if apps and #apps > 0 then
                    tooltip:AddLine("Application Pending", 1, 1, 0)
                end
            end
        end
    }

    local btn = FluxMicroMenu:CreateMicroButton(
        "FluxLFGMicroButton", 
        nil, -- No static texture, we manage it manually
        "LFG", -- Tooltip title (overridden by OnTooltip)
        "FLUXTOGGLELFG", 
        clickHandler
    )

    if btn then
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        -- Add animated eye texture like the original minimap button
        local eyeTexture = btn:CreateTexture(nil, "ARTWORK")
        
        if btn.icon then
            eyeTexture = btn.icon
        else
            eyeTexture:SetPoint("CENTER", btn, "CENTER", 0, 0)
        end
        
        eyeTexture:SetTexture("Interface\\LFGFrame\\LFG-Eye")
        eyeTexture:SetTexCoord(0, 64/512, 0, 64/256) -- First frame
        
        -- Animation Logic
        btn.currentFrame = 0
        btn.isAnimating = false
        
        local function UpdateLFGStatus()
            local shouldAnimate = false

            -- Check if player has active LFG applications
            if C_LFGList and C_LFGList.GetApplications then
                local apps = C_LFGList.GetApplications()
                for i = 1, #apps do
                    local _, appStatus = C_LFGList.GetApplicationInfo(apps[i])
                    if appStatus == "applied" or appStatus == "invited" then
                        shouldAnimate = true
                        break
                    end
                end
            end
            
            -- Check if player has active LFG list entry
            if C_LFGList and C_LFGList.HasActiveEntryInfo then
                if C_LFGList.HasActiveEntryInfo() then
                    shouldAnimate = true
                end
            end

            -- Check if player is in LFD queue
            if GetLFGQueueStats then
                local inParty, queued, noPartialClear, achievements, lfgComment, slotCount, category, leader, tank, healer, dps
                -- LE_LFG_CATEGORY_LFD is 1
                if LE_LFG_CATEGORY_LFD then
                    inParty, queued, noPartialClear, achievements, lfgComment, slotCount, category, leader, tank, healer, dps = GetLFGQueueStats(LE_LFG_CATEGORY_LFD)
                else
                    inParty, queued, noPartialClear, achievements, lfgComment, slotCount, category, leader, tank, healer, dps = GetLFGQueueStats()
                end
                if queued and slotCount and slotCount > 0 then
                    shouldAnimate = true
                end
            end

            -- Update animation state
            if shouldAnimate and not btn.isAnimating then
                btn.isAnimating = true
                btn.currentFrame = 0
                btn:SetScript("OnUpdate", function(self, elapsed)
                    if not self.isAnimating then return end

                    self.totalElapsed = (self.totalElapsed or 0) + elapsed
                    if self.totalElapsed >= 0.1 then -- 0.1 second delay between frames
                        self.totalElapsed = 0
                        self.currentFrame = (self.currentFrame + 1) % 29 -- 29 frames total

                        -- Calculate texture coordinates for current frame
                        local frameX = (self.currentFrame % 8) * 64 -- 8 frames per row
                        local frameY = math.floor(self.currentFrame / 8) * 64
                        
                        if eyeTexture then
                            eyeTexture:SetTexCoord(frameX/512, (frameX+64)/512, frameY/256, (frameY+64)/256)
                        end
                    end
                end)
            elseif not shouldAnimate and btn.isAnimating then
                btn.isAnimating = false
                btn.currentFrame = 0
                btn:SetScript("OnUpdate", nil)
                if eyeTexture then
                    -- Reset to first frame
                    eyeTexture:SetTexCoord(0, 64/512, 0, 64/256)
                end
            end
        end
        
        -- Hook events
        local lfgEventFrame = CreateFrame("Frame")
        lfgEventFrame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
        lfgEventFrame:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
        lfgEventFrame:RegisterEvent("LFG_UPDATE")
        lfgEventFrame:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")
        lfgEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        lfgEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

        lfgEventFrame:SetScript("OnEvent", function(self, event, ...)
            if C_Timer and C_Timer.After then
                C_Timer.After(0.1, UpdateLFGStatus)
            else
                UpdateLFGStatus()
            end
        end)
        
        UpdateLFGStatus()

        -- Classic LFG minimap button stays parked; retail DF+ QueueStatusButton uses minimap corners.
        if FluxMinimap and FluxMinimap.PositionQueueStatusEye then
            FluxMinimap:PositionQueueStatusEye()
        end

        -- Force FluxMicroMenu to rebuild immediately so the button appears instantly
        if FluxMicroMenu and FluxMicroMenu.Rebuild then
            FluxMicroMenu:Rebuild()
        end
    end
end

-- Try Synchronously (INSTANT if frame exists locally)
CreateFluxLFGButton()

-- Initialization Listener (Backup)
local lfgInitFrame = CreateFrame("Frame")
lfgInitFrame:RegisterEvent("PLAYER_LOGIN")
lfgInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD") 

lfgInitFrame:SetScript("OnEvent", function(self, event)
    -- Try to create the button again (idempotent)
    CreateFluxLFGButton()
end)

-- Fallback refresh timers
if C_Timer and C_Timer.After then
    C_Timer.After(0, CreateFluxLFGButton)
    C_Timer.After(0.1, CreateFluxLFGButton)
end
