local Type, Version = "FluxLayoutPreview", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local methods = {
    ["OnAcquire"] = function(self)
        self.width = "fill"
        -- Compact default row height (canvas fills space above label + slider); increase in-game if needed.
        self:SetHeight(340)
        pcall(function()
            self:SetFullWidth(true)
        end)
        if FluxLayoutPreviewUI and FluxLayoutPreviewUI.AttachToAceWidget then
            FluxLayoutPreviewUI:AttachToAceWidget(self)
        end
    end,

    ["OnRelease"] = function(self)
        if FluxLayoutPreviewUI and FluxLayoutPreviewUI.DetachFromAceWidget then
            FluxLayoutPreviewUI:DetachFromAceWidget(self)
        end
    end,

    ["SetText"] = function(self, text)
        self._aceTitle = text
    end,

    ["SetFontObject"] = function() end,
    ["SetImage"] = function() end,
    ["SetImageSize"] = function() end,
}

local function Constructor()
    local name = "AceGUI30FluxLayoutPreview" .. AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:EnableMouse(true)
    frame:Hide()

    local widget = {
        frame = frame,
        type  = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
