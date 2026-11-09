-- AceGUI widget: Embedded MicroMenu layout editor (used as AceConfig dialogControl for FluxUI MicroMenu tab).
-- Loads after FluxMicroMenuConfigUI.lua

local Type, Version = "FluxMicroMenuConfigEmbed", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local methods = {
    ["OnAcquire"] = function(self)
        self:SetWidth(600)
        -- Height updated by FluxMicroMenuConfigUI:RefreshRows (embed uses dynamic height, no inner scroll).
        self:SetHeight(96)
        self.width = "fill"
        if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.AttachToAceWidget then
            FluxMicroMenuConfigUI:AttachToAceWidget(self)
        end
    end,

    ["OnRelease"] = function(self)
        if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.DetachFromAceWidget then
            FluxMicroMenuConfigUI:DetachFromAceWidget(self)
        end
    end,

    -- AceConfig feeds these for type = "description"
    ["SetText"] = function(self, text)
        self._aceTitle = text
    end,

    ["SetFontObject"] = function(self, font)
        -- no-op; AceConfig sets label font on normal Label
    end,

    ["SetImage"] = function(self, path, a, b, c, d)
        -- no-op
    end,

    ["SetImageSize"] = function(self, w, h)
        -- no-op
    end,
}

local function Constructor()
    local name = "AceGUI30FluxMicroMenuEmbed" .. AceGUI:GetNextWidgetNum(Type)
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
