--[[ Target row with move up/down controls. ]]

local Type, Version = "FluxTargetRow", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local ARROW_TEXTURES = {
    ui_arrow_up = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Up]],
    ui_arrow_down = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Up]],
}

local function CreateButton(parent, texture, callback)
    texture = ARROW_TEXTURES[texture]
        or ([[Interface\AddOns\_FluxUI\Binding\UI\Media\]] .. texture .. ".tga")
    local frame = CreateFrame("Button", nil, parent)
    frame:SetScript("OnClick", callback)
    frame:SetSize(16, 16)
    local image = frame:CreateTexture(nil, "BACKGROUND")
    image:SetSize(16, 16)
    image:SetPoint("CENTER")
    image:SetTexture(texture)
    return frame
end

local function MoveDown_OnClick(frame)
    frame.obj:Fire("OnMoveDown")
    AceGUI:ClearFocus()
end

local function MoveUp_OnClick(frame)
    frame.obj:Fire("OnMoveUp")
    AceGUI:ClearFocus()
end

local Methods = {}

function Methods:OnAcquire()
    self:SetWidth(300)
    self:SetHeight(100)
    self:SetMoveUpButton(false)
    self:SetMoveDownButton(false)
end

function Methods:SetMoveUpButton(enabled)
    if enabled then self.moveUp:Show() else self.moveUp:Hide() end
end

function Methods:SetMoveDownButton(enabled)
    if enabled then self.moveDown:Show() else self.moveDown:Hide() end
end

function Methods:LayoutFinished(_, height)
    self:SetHeight(height or 0)
end

function Methods:OnWidthSet(width)
    self.content:SetWidth(width)
    self.content.width = width
end

function Methods:OnHeightSet(height)
    self.content:SetHeight(height)
    self.content.height = height
end

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    local moveUp = CreateButton(frame, "ui_arrow_up", MoveUp_OnClick)
    moveUp:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, 0)
    local moveDown = CreateButton(frame, "ui_arrow_down", MoveDown_OnClick)
    moveDown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 0, 0)
    content:SetPoint("BOTTOMRIGHT")
    local widget = {
        frame = frame, content = content,
        moveUp = moveUp, moveDown = moveDown, type = Type,
    }
    moveDown.obj, moveUp.obj = widget, widget
    for method, func in pairs(Methods) do widget[method] = func end
    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
