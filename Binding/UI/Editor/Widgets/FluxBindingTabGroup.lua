--[[ Flux-branded tab group (AceGUI). ]]

local Type, Version = "FluxBindingTabGroup", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local Methods = {}

function Methods:SetTabs(tabs)
    self:BaseSetTabs(tabs)
    local status = self.status or self.localstatus
    for _, v in ipairs(self.tabs) do
        if v.SetSelected then
            v:SetSelected(v.value == status.selected)
        end
    end
end

local function Constructor()
    local widget = AceGUI:Create("TabGroup")
    widget.type = Type
    widget.BaseSetTabs = widget.SetTabs
    for method, func in pairs(Methods) do widget[method] = func end
    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
