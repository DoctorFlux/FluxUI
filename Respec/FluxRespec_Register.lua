-- FluxRespec_Register.lua
-- Registers the "Respec" tab on FluxWindowFrame. Called from FluxWindowFrame's
-- InitializeWindowFrame after Map/Meter and before the Buttons tab (fallback: PLAYER_LOGIN if needed).

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.Register = R.Register or {}
local Register = R.Register

--- Add the Respec tab to the FluxWindowFrame. Idempotent.
function Register.AddTab()
    if not _G.FluxWindowFrame or not _G.FluxWindowFrame.AddTab then return end
    if _G.FluxWindowFrame.GetTabContent and _G.FluxWindowFrame:GetTabContent("Respec") then
        return  -- Already registered.
    end

    _G.FluxWindowFrame:AddTab("Respec", function(tab)
        if R.UI and R.UI.Show then
            R.UI.Show(tab)
        else
            -- Fallback text.
            local text = tab.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("CENTER", tab.content, "CENTER")
            text:SetText("Respec\n(Not Initialized)")
            text:SetTextColor(1, 0.5, 0.2, 1)
        end
    end, function(tab)
        if R.UI and R.UI.Hide then
            R.UI.Hide(tab)
        end
    end,
    "Respec Profiles\nSave & load gear, talents, action bars, runes, consumables per character.\nCheckboxes choose what Load changes; unchecked parts stay as they are.")
end

-- Defer registration slightly so FluxWindowFrame (which initializes on
-- ADDON_LOADED) has time to build its tab container.
local deferFrame = CreateFrame("Frame")
deferFrame:RegisterEvent("PLAYER_LOGIN")
deferFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
deferFrame:SetScript("OnEvent", function(self, event)
    -- Try a few times — FluxWindowFrame's initializer runs during ADDON_LOADED
    -- but may retry on a watcher. We defer by one frame then attempt.
    local tries = 0
    local function attempt()
        tries = tries + 1
        if _G.FluxWindowFrame and _G.FluxWindowFrame.AddTab then
            Register.AddTab()
            return
        end
        if tries < 20 and _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0.2, attempt)
        end
    end
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0.1, attempt)
    else
        attempt()
    end
end)

R.Register = Register

