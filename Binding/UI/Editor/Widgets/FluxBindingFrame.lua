--[[ Flux-branded resizable dialog frame (AceGUI). ]]

local Type, Version = "FluxBindingFrame", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local function Frame_OnKeyDown(frame, key)
    if InCombatLockdown() then return end
    if key == "ESCAPE" then
        frame:SetPropagateKeyboardInput(false)
        frame:Hide()
    else
        frame:SetPropagateKeyboardInput(true)
    end
end

local Methods = {}

function Methods:OnAcquire()
    self:BaseOnAcquire()
    self:SetMinWidth()
    self:SetMinHeight()
    self.frame:SetFrameStrata("HIGH")
end

function Methods:MoveToFront()
    self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
end

function Methods:SetMinWidth(width)
    local status = self.status or self.localstatus
    status.minWidth = width
end

function Methods:SetMinHeight(height)
    local status = self.status or self.localstatus
    status.minHeight = height
end

function Methods:OnWidthSet(width)
    local status = self.status or self.localstatus
    if status.minWidth ~= nil then width = math.max(width, status.minWidth) end
    self:BaseOnWidthSet(width)
end

function Methods:OnHeightSet(height)
    local status = self.status or self.localstatus
    if status.minHeight ~= nil then height = math.max(height, status.minHeight) end
    self:BaseOnHeightSet(height)
end

local function Constructor()
    local widget = AceGUI:Create("Frame")
    widget.type = Type
    local frame = widget.frame
    frame:SetScript("OnKeyDown", Frame_OnKeyDown)
    widget.BaseOnAcquire = widget.OnAcquire
    widget.BaseOnWidthSet = widget.OnWidthSet
    widget.BaseOnHeightSet = widget.OnHeightSet
    for method, func in pairs(Methods) do widget[method] = func end
    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
