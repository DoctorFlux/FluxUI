-- Binding/UI/KeyVisualizer/AceGUIContainer-FluxKeyVisualizerTreeGroup.lua
-- TreeGroup wrapper that exposes content width/height for frame sizing.

local Type, Version = "FluxKeyVisualizerTreeGroup", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
    return
end

local Methods = {}

function Methods:GetContentWidth()
    local status = self.status or self.localstatus
    return status.contentWidth or 0
end

function Methods:GetContentHeight()
    local status = self.status or self.localstatus
    return status.contentHeight or 0
end

function Methods:LayoutFinished(width, height)
    self:OriginalLayoutFinished(width, height)
    local status = self.status or self.localstatus
    status.contentWidth = width
    status.contentHeight = height
end

local function Constructor()
    local widget = AceGUI:Create("TreeGroup")
    widget.type = Type
    widget.OriginalLayoutFinished = widget.LayoutFinished

    for method, func in pairs(Methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
