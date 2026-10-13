-- Helmet / Cloak toggles beside the character model rotation buttons; synced with Interface > Display.
local _, ns = ...
local module = ns.CharacterStats
if not (module and module.useClassicPaperDollChrome) then return end

local function HasVisibilityAPI()
    return type(ShowHelm) == "function"
        and type(ShowCloak) == "function"
        and type(ShowingHelm) == "function"
        and type(ShowingCloak) == "function"
end

-- Retail mainline dropped the Display settings entries; classic era / anniversary / progression still have them.
local function IsVisibilityOptionClient()
    if module.isRetail or not module.useClassicPaperDollChrome then
        return false
    end
    return HasVisibilityAPI()
end

local HELM_LABEL = "Helmet"
local CLOAK_LABEL = "Cloak"

local visibilityRow
local helmCheck
local cloakCheck
local syncingFromGame = false

local function SetCheckboxChecked(checkbox, checked)
    if not checkbox then
        return
    end
    syncingFromGame = true
    checkbox:SetChecked(checked and true or false)
    syncingFromGame = false
end

local function SyncHelmCheckbox(checked)
    if type(checked) ~= "boolean" then
        checked = ShowingHelm()
    end
    SetCheckboxChecked(helmCheck, checked)
end

local function SyncCloakCheckbox(checked)
    if type(checked) ~= "boolean" then
        checked = ShowingCloak()
    end
    SetCheckboxChecked(cloakCheck, checked)
end

local function SyncFromGame()
    SyncHelmCheckbox()
    SyncCloakCheckbox()
end

local function QueueDeferredSync(getShowing, checkbox)
    if not (C_Timer and C_Timer.After and checkbox) then
        return
    end
    C_Timer.After(0, function()
        if checkbox:IsShown() then
            SetCheckboxChecked(checkbox, getShowing())
        end
    end)
end

local function CreateVisibilityCheckbox(parent, label, tooltip, getShowing, apply)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(18, 18)
    checkbox:EnableMouse(true)
    checkbox:RegisterForClicks("LeftButtonUp")

    local labelText = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelText:SetPoint("LEFT", checkbox, "RIGHT", 1, 0)
    labelText:SetText(label or "")
    labelText:SetTextColor(1, 1, 1, 0.9)
    checkbox.text = labelText

    -- Replacing OnClick disables the template's built-in toggle; drive state ourselves.
    checkbox:SetScript("OnClick", function(self)
        if syncingFromGame then
            return
        end
        local newValue = not getShowing()
        apply(newValue)
        SetCheckboxChecked(self, newValue)
        QueueDeferredSync(getShowing, self)
    end)

    if tooltip and tooltip ~= "" then
        checkbox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(checkbox, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return checkbox
end

local function GetRotationAnchorFrame()
    -- Era / TBC / Wrath: rightmost of the two rotation buttons.
    local classicRotateLeft = _G.CharacterModelFrameRotateLeftButton
    if classicRotateLeft then
        return classicRotateLeft
    end

    -- Cata+ model scene: rotateRight is laid out after rotateLeft.
    local modelScene = _G.CharacterModelScene
    local controlFrame = modelScene and modelScene.ControlFrame
    if controlFrame then
        if controlFrame.rotateRightButton then
            return controlFrame.rotateRightButton
        end
        if controlFrame.rotateLeftButton then
            return controlFrame.rotateLeftButton
        end
        return controlFrame
    end

    return _G.CharacterModelFrameRotateRightButton or _G.PaperDollFrame
end

local function AnchorVisibilityToggles()
    if not visibilityRow then
        return
    end

    local anchor = GetRotationAnchorFrame()
    if not anchor then
        return
    end

    visibilityRow:ClearAllPoints()
    visibilityRow:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
    visibilityRow:SetPoint("TOP", anchor, "TOP", 0, 4)
end

local function TryHookControlFrameLayout()
    local modelScene = _G.CharacterModelScene
    local controlFrame = modelScene and modelScene.ControlFrame
    if not controlFrame or controlFrame._fluxVisibilityLayoutHooked then
        return
    end
    if type(hooksecurefunc) ~= "function" or type(controlFrame.UpdateLayout) ~= "function" then
        return
    end

    controlFrame._fluxVisibilityLayoutHooked = true
    hooksecurefunc(controlFrame, "UpdateLayout", AnchorVisibilityToggles)
end

local function EnsureVisibilityToggles()
    if visibilityRow then
        AnchorVisibilityToggles()
        SyncFromGame()
        return
    end

    local parent = _G.PaperDollFrame
    if not parent then
        return
    end

    visibilityRow = CreateFrame("Frame", "FluxPaperDollVisibilityRow", parent)
    visibilityRow:SetSize(82, 34)
    visibilityRow:SetFrameStrata(parent:GetFrameStrata())
    visibilityRow:SetFrameLevel(parent:GetFrameLevel() + 20)

    local helmTooltip = _G.OPTION_TOOLTIP_SHOW_HELM
    local cloakTooltip = _G.OPTION_TOOLTIP_SHOW_CLOAK

    helmCheck = CreateVisibilityCheckbox(visibilityRow, HELM_LABEL, helmTooltip, ShowingHelm, ShowHelm)
    helmCheck:SetPoint("TOPLEFT", visibilityRow, "TOPLEFT", 0, 0)

    cloakCheck = CreateVisibilityCheckbox(visibilityRow, CLOAK_LABEL, cloakTooltip, ShowingCloak, ShowCloak)
    cloakCheck:SetPoint("TOPLEFT", helmCheck, "BOTTOMLEFT", 0, 3)

    TryHookControlFrameLayout()
    AnchorVisibilityToggles()
    SyncFromGame()
end

if type(hooksecurefunc) == "function" and HasVisibilityAPI() then
    hooksecurefunc("ShowHelm", function(show)
        SyncHelmCheckbox(show)
        QueueDeferredSync(ShowingHelm, helmCheck)
    end)
    hooksecurefunc("ShowCloak", function(show)
        SyncCloakCheckbox(show)
        QueueDeferredSync(ShowingCloak, cloakCheck)
    end)
end

local syncFrame = CreateFrame("Frame")
syncFrame:RegisterEvent("PLAYER_LOGIN")
syncFrame:RegisterEvent("VARIABLES_LOADED")
syncFrame:RegisterEvent("UNIT_MODEL_CHANGED")
syncFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_MODEL_CHANGED" and unit ~= "player" then
        return
    end
    if event == "PLAYER_LOGIN" then
        EnsureVisibilityToggles()
        return
    end
    SyncFromGame()
end)

function module.InstallVisibility()
    if not IsVisibilityOptionClient() then
        return false
    end
    local paperDollFrame = _G.PaperDollFrame
    if paperDollFrame and paperDollFrame.HookScript and not paperDollFrame._fluxVisibilityOnShow then
        paperDollFrame._fluxVisibilityOnShow = true
        paperDollFrame:HookScript("OnShow", function()
            EnsureVisibilityToggles()
            SyncFromGame()
        end)
    end
    EnsureVisibilityToggles()
    return visibilityRow ~= nil
end

