--[[ Section heading with master toggle checkbox. ]]

local Type, Version = "FluxSectionHeading", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local function Control_OnEnter(frame) frame.obj:Fire("OnEnter") end
local function Control_OnLeave(frame) frame.obj:Fire("OnLeave") end
local function CheckBox_OnMouseDown() AceGUI:ClearFocus() end

local function CheckBox_OnMouseUp(frame)
    local self = frame.obj
    if self.disabled then return end
    self:ToggleChecked()
    if self.checked and PlaySound then pcall(PlaySound, 856) elseif PlaySound then pcall(PlaySound, 857) end
    self:Fire("OnValueChanged", self.checked)
end

local Methods = {}

function Methods:OnAcquire()
    self:SetHeight(24)
    self:SetText("")
    self:SetValue(false)
    self:SetDisabled(false)
    self:SetLabelColor(NORMAL_FONT_COLOR)
end

function Methods:SetText(text)
    self.label:SetText(text)
    if text and text ~= "" then self.right:Show() else self.right:Hide() end
end

function Methods:SetLabel(text)
    self:SetText(text)
end

function Methods:SetDisabled(disabled)
    self.disabled = disabled
    if disabled then
        self.frame:Disable()
        self.label:SetTextColor(0.5, 0.5, 0.5)
        self.check:SetDesaturated(true)
    else
        self.frame:Enable()
        self.label:SetTextColor(1, 1, 1)
        self.check:SetDesaturated(false)
    end
end

function Methods:SetValue(value)
    self.checked = value and true or false
    if self.checked then self.check:Show() else self.check:Hide() end
    self:SetDisabled(self.disabled)
end

function Methods:SetLabelColor(color)
    self.label:SetTextColor(color:GetRGBA())
end

function Methods:GetValue()
    return self.checked
end

function Methods:ToggleChecked()
    self:SetValue(not self:GetValue())
end

local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:Hide()
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", Control_OnEnter)
    frame:SetScript("OnLeave", Control_OnLeave)
    frame:SetScript("OnMouseDown", CheckBox_OnMouseDown)
    frame:SetScript("OnMouseUp", CheckBox_OnMouseUp)
    local checkbg = frame:CreateTexture(nil, "ARTWORK")
    checkbg:SetWidth(24)
    checkbg:SetHeight(24)
    checkbg:SetPoint("LEFT", 14, -1)
    checkbg:SetTexture(130755)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOP")
    label:SetPoint("BOTTOM")
    label:SetJustifyH("CENTER")
    label:SetHeight(18)
    local check = frame:CreateTexture(nil, "OVERLAY")
    check:SetAllPoints(checkbg)
    check:SetTexture(130751)
    local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture(130753)
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(checkbg)
    local left = frame:CreateTexture(nil, "BACKGROUND")
    left:SetHeight(8)
    left:SetPoint("LEFT", 3, 0)
    left:SetPoint("RIGHT", checkbg, "LEFT", -3, 0)
    left:SetTexture(137057)
    left:SetTexCoord(0.81, 0.94, 0.5, 1)
    local right = frame:CreateTexture(nil, "BACKGROUND")
    right:SetHeight(8)
    right:SetPoint("RIGHT", -3, 0)
    right:SetPoint("LEFT", label, "RIGHT", 5, 0)
    right:SetTexture(137057)
    right:SetTexCoord(0.81, 0.94, 0.5, 1)
    local center = frame:CreateTexture(nil, "BACKGROUND")
    center:SetHeight(8)
    center:SetPoint("LEFT", checkbg, "RIGHT", 3, 1)
    center:SetPoint("RIGHT", label, "LEFT", -5, 1)
    center:SetTexture(137057)
    center:SetTexCoord(0.81, 0.94, 0.5, 1)
    local widget = {
        frame = frame, label = label, checkbg = checkbg, check = check,
        highlight = highlight, left = left, right = right, center = center, type = Type,
    }
    for method, func in pairs(Methods) do widget[method] = func end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
