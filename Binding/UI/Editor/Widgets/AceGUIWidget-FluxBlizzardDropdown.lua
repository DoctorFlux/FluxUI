-- AceGUI dropdown that uses Blizzard's WowStyle1 settings menu.
local Type, Version = "FluxBlizzardDropdown", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local function LoadMenu()
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_Menu")
    elseif LoadAddOn then
        pcall(LoadAddOn, "Blizzard_Menu")
    end
end

local function SetButtonText(dropdown, text)
    text = text or ""
    if dropdown.OverrideText then
        dropdown:OverrideText(text)
    elseif dropdown.SetDefaultText then
        dropdown:SetDefaultText(text)
    elseif dropdown.Text and dropdown.Text.SetText then
        dropdown.Text:SetText(text)
    elseif UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(dropdown, text)
    end
end

local methods = {}

function methods:OnAcquire()
    self.list = {}
    self.order = {}
    self.value = nil
    self:SetLabel("")
    self:SetDisabled(false)
    self:SetWidth(180)
end

function methods:OnRelease()
    self.list = nil
    self.order = nil
    self.value = nil
end

function methods:SetDisabled(disabled)
    self.disabled = disabled and true or false
    if self.dropdown and self.dropdown.SetEnabled then
        self.dropdown:SetEnabled(not self.disabled)
    elseif self.dropdown and UIDropDownMenu_DisableDropDown and UIDropDownMenu_EnableDropDown then
        if self.disabled then
            UIDropDownMenu_DisableDropDown(self.dropdown)
        else
            UIDropDownMenu_EnableDropDown(self.dropdown)
        end
    end
    if self.label then
        self.label:SetAlpha(self.disabled and 0.4 or 1)
    end
end

function methods:SetLabel(text)
    text = text or ""
    self.labelText = text
    if text ~= "" then
        self.label:SetText(text)
        self.label:Show()
        self.dropdown:ClearAllPoints()
        self.dropdown:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -16)
        self.dropdown:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -16)
        self:SetHeight(42)
    else
        self.label:SetText("")
        self.label:Hide()
        self.dropdown:ClearAllPoints()
        self.dropdown:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -2)
        self.dropdown:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -2)
        self:SetHeight(26)
    end
end

function methods:SetText(text)
    SetButtonText(self.dropdown, text)
end

function methods:SetList(list, order)
    self.list = list or {}
    self.order = {}
    if type(order) == "table" then
        for i = 1, #order do
            self.order[i] = order[i]
        end
    else
        for key in pairs(self.list) do
            self.order[#self.order + 1] = key
        end
    end
    if self.value ~= nil then
        self:SetValue(self.value)
    end
end

function methods:SetValue(value)
    self.value = value
    local text = self.list and self.list[value]
    self:SetText(text ~= nil and tostring(text) or "")
end

function methods:GetValue()
    return self.value
end

local function Constructor()
    LoadMenu()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetHeight(42)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:Hide()

    local DD = _G.FluxBlizzardDropdown
    local classic = DD and DD.UseClassicMenu and DD.UseClassicMenu()
    local dropdown
    if not classic then
        local ok, created = pcall(CreateFrame, "DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
        if ok and created and created.SetupMenu then
            dropdown = created
        end
    end
    if not dropdown then
        if not UIDropDownMenu_Initialize then
            return
        end
        dropdown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
        classic = true
        if UIDropDownMenu_SetWidth then
            UIDropDownMenu_SetWidth(dropdown, 160)
        end
    else
        dropdown:SetHeight(22)
    end

    local widget = {
        frame = frame,
        label = label,
        dropdown = dropdown,
        type = Type,
        list = {},
        order = {},
    }
    for name, method in pairs(methods) do
        widget[name] = method
    end
    frame.obj = widget

    if classic then
        UIDropDownMenu_Initialize(dropdown, function()
            local order = widget.order or {}
            local list = widget.list or {}
            for i = 1, #order do
                local key = order[i]
                local text = list[key]
                if text ~= nil then
                    local info = UIDropDownMenu_CreateInfo()
                    local captured = key
                    info.text = tostring(text)
                    info.checked = widget.value == captured
                    info.disabled = widget.disabled and true or false
                    info.func = function()
                        if widget.disabled then
                            return
                        end
                        widget:SetValue(captured)
                        widget:Fire("OnValueChanged", captured)
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end
        end)
    else
        if DD and DD.InstallGamepadClick then
            DD.InstallGamepadClick(dropdown)
        end
        dropdown:SetupMenu(function(_, root)
            local menuRoot = root
            if menuRoot and menuRoot.SetScrollMode then
                menuRoot:SetScrollMode(240)
            end
            if not menuRoot or not menuRoot.CreateRadio then
                return
            end
            local order = widget.order or {}
            local list = widget.list or {}
            for i = 1, #order do
                local key = order[i]
                local text = list[key]
                if text ~= nil then
                    local captured = key
                    local caption = tostring(text)
                    menuRoot:CreateRadio(caption, function()
                        return widget.value == captured
                    end, function()
                        if widget.disabled then
                            return
                        end
                        widget:SetValue(captured)
                        widget:Fire("OnValueChanged", captured)
                    end)
                end
            end
        end)
    end

    frame:SetScript("OnSizeChanged", function(self)
        local width = self:GetWidth() or 0
        if width <= 40 then
            return
        end
        if classic and UIDropDownMenu_SetWidth then
            UIDropDownMenu_SetWidth(dropdown, math.max(80, width - 20))
        elseif dropdown.SetWidth then
            dropdown:SetWidth(width)
        end
    end)

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
